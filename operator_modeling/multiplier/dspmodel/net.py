'''A pipelined netlist on `Signal`s: one engine for both the untimed walk and
the cycle-by-cycle beat model.

A netlist is built once, as a DAG of three kinds of node:

    input    a port; its value arrives from outside
    op       a combinational function of other nodes — one of the
             `signalops` functions, called on `Signal`s
    reg      `cycles` registers on a wire; the only thing that costs time

and it is evaluated two ways from the same description:

  **Eagerly, at build time.** Every op runs on the full batch as soon as it
  is added, exactly as the untimed model always has. Registers are
  transparent. This is what `propagateBound` / `propagateValue`, every
  `requireFits`, every seal and every identity check run on.

  **Ticked, afterwards.** `reset()` empties every register; each `step()` is
  one clock edge: read the ports, evaluate every op from the register
  outputs *as they stand at the start of the edge*, then shift every
  register by one. Two-phase, so no stage ever sees its predecessor's new
  value in the same cycle. A register that has not been written yet holds
  `None`, and `None` propagates through ops — the pipeline fill.

The arithmetic exists once: an op node stores the `signalops` function and
calls it again on each tick with `Signal(bound, batch)` in place of each
input, so the beat model cannot compute anything the untimed one would not.

**Depth is bookkeeping the engine does for free, and it is a check.** Every
node knows how many registers lie between it and the inputs. An op whose
inputs sit at different depths would be adding this cycle's value of one
wire to last cycle's value of another — the RTL's alignment registers exist
precisely to prevent that — so the engine refuses to build it, naming the
wires and the depths. Every merge in every tile and every heap in the IR is
therefore checked against the register placement the backend chose, from
the netlist itself, with no separate schedule to keep in step.

Nothing in this module decides where a register goes. Callers pass
`cycles`; the counts come from the backend's lowered module and the
generators' own plan functions.
'''
from __future__ import annotations

from collections import deque
from dataclasses import dataclass, field

from ...core.IntType import IntType
from ...core.Signal import Signal
from . import signalops as so


class MisalignedError(ValueError):
    '''An op would merge wires from different pipeline cycles.'''


@dataclass
class _Node:
    kind: str                           # 'input' | 'const' | 'op' | 'reg'
    name: str
    signal: Signal                      # eager result (registers transparent)
    inputs: list[int] = field(default_factory=list)
    depth: int | None = None            # registers from the inputs; None = depth-agnostic
    fn: object = None                   # op: the signalops function
    args: tuple = ()                    # op: args with Wires replaced by _Ref(index)
    kwargs: dict = field(default_factory=dict)
    cycles: int = 0                     # reg
    value: int = 0                      # const


@dataclass(frozen=True)
class _Ref:
    index: int


class Wire:
    '''A handle to one node of a `Net`.'''
    __slots__ = ('net', 'index')

    def __init__(self, net: Net, index: int):
        self.net, self.index = net, index

    @property
    def _node(self) -> _Node:
        return self.net._nodes[self.index]

    @property
    def signal(self) -> Signal:
        return self._node.signal

    @property
    def bound(self) -> IntType:
        return self._node.signal.bound

    @property
    def values(self) -> list[int] | None:
        return self._node.signal.values

    @property
    def depth(self) -> int | None:
        return self._node.depth

    @property
    def name(self) -> str:
        return self._node.name

    def __repr__(self) -> str:
        return f'Wire({self.name!r}, depth={self.depth}, {self.signal})'


class Net:
    '''See the module docstring.'''

    def __init__(self):
        self._nodes: list[_Node] = []
        self._byName: dict[str, int] = {}
        self._slots: dict[int, deque] = {}
        self._obs: dict[int, list[int] | None] = {}
        self.tick: int = 0
        self._ticking = False

    # ------------------------------------------------------------------
    # building
    # ------------------------------------------------------------------

    def _add(self, node: _Node) -> Wire:
        if node.name in self._byName:
            raise ValueError(f'Net: duplicate wire name {node.name!r}')
        self._nodes.append(node)
        self._byName[node.name] = len(self._nodes) - 1
        return Wire(self, len(self._nodes) - 1)

    def input(self, name: str, signal: Signal) -> Wire:
        '''A port. Depth 0.'''
        return self._add(_Node('input', name, signal, depth=0))

    def const(self, value: int, *, like: Wire | None = None, name: str | None = None) -> Wire:
        '''A constant. Depth-agnostic: it may join a merge at any cycle.'''
        eager = so.const(value, like=like.signal if like is not None else self._anyInputSignal())
        return self._add(_Node('const', name or f'const{len(self._nodes)}', eager,
                               depth=None, value=value))

    def _anyInputSignal(self) -> Signal | None:
        for n in self._nodes:
            if n.kind == 'input':
                return n.signal
        return None

    def op(self, fn, *args, name: str | None = None, **kwargs) -> Wire:
        '''A combinational node: `fn(*args, **kwargs)`, Wires among `args`
        being its inputs. Refuses inputs at different depths.'''
        inputs, refs, depths = [], [], []
        for a in args:
            if isinstance(a, Wire):
                if a.net is not self:
                    raise ValueError('Net.op: wire from another Net')
                inputs.append(a.index)
                refs.append(_Ref(a.index))
                if a.depth is not None:
                    depths.append((a.name, a.depth))
            else:
                refs.append(a)
        if len({d for _, d in depths}) > 1:
            where = ', '.join(f'{n}@{d}' for n, d in depths)
            raise MisalignedError(
                f'{name or fn.__name__}: inputs sit at different pipeline depths '
                f'({where}) — the RTL would merge values from different cycles')
        depth = depths[0][1] if depths else None
        eager = fn(*[self._nodes[r.index].signal if isinstance(r, _Ref) else r for r in refs],
                   **kwargs)
        return self._add(_Node('op', name or f'{fn.__name__}{len(self._nodes)}', eager,
                               inputs=inputs, depth=depth, fn=fn, args=tuple(refs),
                               kwargs=dict(kwargs)))

    def reg(self, wire: Wire, cycles: int, name: str | None = None) -> Wire:
        '''`cycles` registers on `wire`. Zero registers is the wire itself.'''
        if cycles < 0:
            raise ValueError(f'Net.reg: cycles must be >= 0, got {cycles}')
        if cycles == 0:
            return wire
        src = wire._node
        depth = None if src.depth is None else src.depth + cycles
        return self._add(_Node('reg', name or f'{src.name}_d{cycles}', src.signal,
                               inputs=[wire.index], depth=depth, cycles=cycles))

    def tighten(self, wire: Wire, identity: Signal, what: str) -> None:
        '''Build-time only: intersect the wire's bound with an identity's and
        assert the eager values agree. Not part of the netlist — an identity
        is a claim about the value, not hardware — so it costs no depth and
        is not replayed.'''
        node = wire._node
        node.signal = so.tighten(node.signal, identity, what)

    def wire(self, name: str) -> Wire:
        return Wire(self, self._byName[name])

    def names(self) -> list[str]:
        return [n.name for n in self._nodes]

    # ------------------------------------------------------------------
    # ticking
    # ------------------------------------------------------------------

    def reset(self) -> None:
        '''Empty every register: the state after a synchronous reset.'''
        self._slots = {i: deque([None] * n.cycles)
                       for i, n in enumerate(self._nodes) if n.kind == 'reg'}
        self._obs = {}
        self.tick = 0
        self._ticking = True

    def _observed(self, index: int) -> list[int] | None:
        '''What a downstream op sees on this node at the current edge.'''
        n = self._nodes[index]
        if n.kind == 'reg':
            return self._slots[index][-1]
        return self._obs[index]

    def _settle(self, inputs: dict[str, list[int]], batch: int) -> None:
        '''Evaluate every non-register node from the registers as they stand.'''
        self._obs = {}
        for i, n in enumerate(self._nodes):
            if n.kind == 'input':
                if n.name not in inputs:
                    raise KeyError(f'Net.step: no value for input {n.name!r}')
                self._obs[i] = inputs[n.name]
            elif n.kind == 'const':
                self._obs[i] = [n.value] * batch
            elif n.kind == 'op':
                ins = [self._observed(j) for j in n.inputs]
                if any(v is None for v in ins):
                    self._obs[i] = None            # pipeline fill
                    continue
                args = [Signal(self._nodes[r.index].signal.bound, self._observed(r.index))
                        if isinstance(r, _Ref) else r for r in n.args]
                self._obs[i] = n.fn(*args, **n.kwargs).values
            # 'reg': observed from its slots, nothing to compute

    def step(self, inputs: dict[str, list[int]]) -> None:
        '''One clock edge. `inputs` maps port name to the batch on the ports
        during the cycle this edge ends.

        Three phases: settle the combinational logic from the registers as
        they stand and the inputs on the ports; the edge — every register
        captures its source; settle again from the freshly captured
        registers, so that `observe()` on any registered wire, and on any
        wire downstream of one, is its value right after the edge — what a
        testbench samples `#1` after the posedge. No stage ever sees its
        predecessor's new value in the cycle it was captured.

        One precision about depth-0 wires (an input, or a slice of one):
        after `step(k)` they still show vector k, the one this edge captured.
        A testbench whose driver non-blocking-assigns the next vector in the
        same timestep as the posedge would already show vector k+1 on the
        port `#1` later. Nothing registered, and no output, is affected.
        '''
        if not self._ticking:
            self.reset()
        sizes = {len(v) for v in inputs.values()}
        if len(sizes) != 1:
            raise ValueError(f'Net.step: input batches differ in length: {sorted(sizes)}')
        (batch,) = sizes

        self._settle(inputs, batch)                    # the cycle before the edge

        pre = {i: q[-1] for i, q in self._slots.items()}
        for i, n in enumerate(self._nodes):             # the edge
            if n.kind == 'reg':
                src = n.inputs[0]
                v = pre[src] if self._nodes[src].kind == 'reg' else self._obs[src]
                q = self._slots[i]
                q.appendleft(v)
                q.pop()
        self.tick += 1

        self._settle(inputs, batch)                    # right after the edge

    def observe(self, wire: Wire | str) -> list[int] | None:
        '''The batch on a wire after the last `step()`, or None while filling.'''
        index = wire.index if isinstance(wire, Wire) else self._byName[wire]
        if not self._ticking:
            raise RuntimeError('Net.observe: call reset() and step() first')
        return self._observed(index)
