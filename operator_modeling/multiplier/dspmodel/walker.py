'''Interpret the backend's IR op by op, as a netlist — untimed or clocked.

`build_ir` turns a solved tree into a flat list — `Input`, `Slice`, `Sub`,
`DspTile`, `LutMult`, `BitHeap`, `Delay` — that is the multiplication exactly
as the RTL will build it. `buildNet` turns that list into a `Net`: one node
per op, the tile netlists inside the `DspTile`s, and — when timed — a
register block per op of exactly the depth the backend chose:

    Sub / LutMult / BitHeap                op.latency registers at the output
    DspTile                                op.latency registers placed *inside*
                                           the tile netlist by `runTile`; only
                                           tileModel='opaque' puts them at the
                                           output instead
    Delay                                  cycles registers, nothing else
    Input / Slice                          none (the top level is `assign`s)

Where `op.latency` comes from is the whole point: the module handed to the
timed build is the one `build_final_module` returns — the Pareto point for
the caller's frequency or latency target, with `align_latency`'s `Delay`
ops already in place. A tile's interior registers come from
`exact_dsp_config` for that same `op.latency`. Nothing here decides depth.

Two things happen at every wire beyond computing it.

**Declared width is checked, never trusted.** The IR dictates each signal's
width and signedness. The model derives its own interval and records
whether it fits, and by how much.

**Seals are tightened to the product.** At each signal `build_ir`'s trace
marks as a subtree's product, the walked bound must contain the operand
product interval — exact for a box, so failing to contain it means the
arithmetic is wrong — the walked values are asserted equal to the operand
product elementwise, and the product interval is adopted. That is the DSP
family's `selfCheck` at every node.

And when timed, one more: the netlist engine's depth bookkeeping is
compared wire for wire against the backend's own `compute_ready`, and any
merge of wires from different cycles refuses to build.

`walk()` is the untimed entry point the scheme's `propagateBound` and
`propagateValue` use. `BeatModel` is the clocked one: `reset()`, then one
`step()` per clock edge.
'''
from __future__ import annotations

from dataclasses import dataclass, field

from ...core.IntType import IntType
from ...core.Signal import Signal
from . import signalops as so
from .net import Net, Wire

import dsp_multiplier.backend.ir as IR                                # noqa: E402
from dsp_multiplier.backend.delay_model import dsp_family             # noqa: E402
from dsp_multiplier.backend.schedule import compute_ready             # noqa: E402


@dataclass(frozen=True)
class WireCheck:
    '''One IR signal: what the backend declared, what the model derived.'''
    name: str
    kind: str                 # IR op class name
    declaredWidth: int
    declaredSigned: bool
    bound: IntType
    fits: bool
    slackBits: int            # declaredWidth - bound.bitWidth; negative is a violation
    isSeal: bool = False
    depth: int | None = None  # pipeline depth when timed


@dataclass
class Built:
    '''A netlist built from an IR module, with everything the scheme reads.'''
    net: Net
    output: Wire
    wires: dict[str, Wire]                       # IR signal name -> wire
    checks: list[WireCheck]
    tileInternals: dict[str, dict[str, Wire]]    # tile result name -> its interior
    timed: bool

    @property
    def violations(self) -> list[WireCheck]:
        return [c for c in self.checks if not c.fits]

    def signals(self) -> dict[str, Signal]:
        '''Every wire as a `Signal`, tile interiors keyed `<tile>/<wire>`.'''
        out = {k: w.signal for k, w in self.wires.items()}
        for tile, inner in self.tileInternals.items():
            for k, w in inner.items():
                out[f'{tile}/{k}'] = w.signal
        return out


@dataclass
class WalkResult:
    '''The untimed view the scheme has always consumed.'''
    signals: dict[str, Signal]
    checks: list[WireCheck]
    output: Signal
    tileInternals: dict[str, dict[str, Signal]] = field(default_factory=dict)

    @property
    def violations(self) -> list[WireCheck]:
        return [c for c in self.checks if not c.fits]


def sealMap(traceRoot) -> dict[str, tuple[str, str]]:
    '''`{product signal name: (a_in name, b_in name)}` for every subtree the
    trace recorded a product for.'''
    out: dict[str, tuple[str, str]] = {}

    def visit(tr):
        if tr is None:
            return
        if tr.signal is not None and tr.a_in is not None and tr.b_in is not None:
            out[tr.signal.name] = (tr.a_in.name, tr.b_in.name)
        for _, child in tr.children:
            visit(child)

    visit(traceRoot)
    return out


def _seal(net: Net, name: str, walked: Wire, a: Wire, b: Wire) -> None:
    '''Tighten a sealed signal to its operand product; assert the walk agrees.'''
    product = a.bound * b.bound
    wb = walked.bound
    if not (wb.minValue <= product.minValue and product.maxValue <= wb.maxValue):
        raise ValueError(
            f'{name}: walked bound {wb} does not contain the operand product '
            f'{product} — the model\'s arithmetic for this node is wrong, not '
            f'merely conservative')
    if walked.values is not None:
        va = so._values(a.signal, b.signal)
        if va is None:
            raise ValueError(f'{name}: sealed values present but an operand has none')
        for i, (x, y, got) in enumerate(zip(va[0], va[1], walked.values)):
            if got != x * y:
                raise ValueError(
                    f'{name}: netlist computed {got} for {x} * {y} = {x * y} '
                    f'(sample {i}) — the walk does not compute this node\'s product')
    net.tighten(walked, Signal(product, walked.values), f'{name} (seal)')


def _check(op, w: Wire, isSeal: bool) -> WireCheck:
    r = op.result
    return WireCheck(name=r.name, kind=type(op).__name__,
                     declaredWidth=r.width, declaredSigned=r.signed,
                     bound=w.bound, fits=so.fits(w.signal, r.width, r.signed),
                     slackBits=r.width - w.bound.bitWidth, isSeal=isSeal, depth=w.depth)


def buildNet(module: IR.IRModule, traceRoot, aIn: Signal, bIn: Signal,
             *, tileModel: str = 'netlist', timed: bool = False) -> Built:
    '''Build the netlist for `module`, fed by `aIn` / `bIn` on its ports.'''
    if tileModel not in ('netlist', 'opaque'):
        raise ValueError(f"tileModel must be 'netlist' or 'opaque', got {tileModel!r}")
    net = Net()
    seals = sealMap(traceRoot)
    ports = {'A': aIn, 'B': bIn}
    wires: dict[str, Wire] = {}
    checks: list[WireCheck] = []
    internals: dict[str, dict[str, Wire]] = {}

    def lat(op) -> int:
        return int(op.latency) if timed else 0

    for op in module.ops:
        r = op.result
        if isinstance(op, IR.Input):
            so.requireFits(ports[op.port_name], r.width, r.signed, f'{r.name} (input {op.port_name})')
            w = net.input(op.port_name, ports[op.port_name])

        elif isinstance(op, IR.Slice):
            w = net.op(so.sliceBits, wires[op.source.name], op.lo, op.lo + r.width - 1, r.signed,
                       name=r.name)

        elif isinstance(op, IR.Sub):
            w = net.reg(net.op(so.sub, wires[op.minuend.name], wires[op.subtrahend.name],
                               name=f'{r.name}_comb'), lat(op), name=r.name)

        elif isinstance(op, IR.DspTile):
            a, b = wires[op.a.name], wires[op.b.name]
            if tileModel == 'opaque':
                w = net.reg(net.op(so.mul, a, b, name=f'{r.name}_comb'), lat(op), name=r.name)
            else:
                from .tiles import runTile
                fam, blocks = dsp_family(op.params, op.impl_id)
                p = dict(op.params)
                w, inner = runTile(net, fam, blocks, a, b,
                                   physicalA=int(p['physical_a_width']),
                                   physicalB=int(p['physical_b_width']),
                                   orientation=op.orientation, name=r.name,
                                   latency=int(op.latency) if timed else None)
                internals[r.name] = inner
            so.requireFits(w.signal, r.width, r.signed, f'{r.name} (tile output truncation)')

        elif isinstance(op, IR.LutMult):
            w = net.reg(net.op(so.mul, wires[op.a.name], wires[op.b.name], name=f'{r.name}_comb'),
                        lat(op), name=r.name)
            so.requireFits(w.signal, r.width, r.signed, f'{r.name} (LUT product truncation)')

        elif isinstance(op, IR.BitHeap):
            acc = None
            for t in op.terms:
                piece = net.op(so.lshift, wires[t.signal.name], t.weight)
                if acc is None:
                    acc = net.op(so.neg, piece) if t.negate else piece
                else:
                    acc = net.op(so.sub if t.negate else so.add, acc, piece)
            w = net.reg(acc, lat(op), name=r.name)

        elif isinstance(op, IR.Delay):
            w = net.reg(wires[op.source.name], int(op.cycles) if timed else 0, name=r.name)

        else:
            raise TypeError(f'buildNet: unknown op {type(op).__name__}')

        isSeal = r.name in seals
        if isSeal:
            an, bn = seals[r.name]
            _seal(net, r.name, w, wires[an], wires[bn])
        wires[r.name] = w
        checks.append(_check(op, w, isSeal))

    built = Built(net=net, output=wires[module.output.name], wires=wires, checks=checks,
                  tileInternals=internals, timed=timed)
    if timed:
        ready = compute_ready(module)
        for name, w in wires.items():
            if w.depth != ready[name]:
                raise ValueError(
                    f'{name}: the netlist puts this wire at depth {w.depth}, the backend\'s '
                    f'compute_ready says cycle {ready[name]} — the register placement the '
                    f'model read does not match the schedule the RTL is built to')
    return built


def walk(module: IR.IRModule, traceRoot, aIn: Signal, bIn: Signal,
         *, tileModel: str = 'netlist') -> WalkResult:
    '''The untimed walk: `aIn`, `bIn` through every op, registers transparent.'''
    b = buildNet(module, traceRoot, aIn, bIn, tileModel=tileModel, timed=False)
    return WalkResult(signals={k: w.signal for k, w in b.wires.items()},
                      checks=b.checks, output=b.output.signal,
                      tileInternals={t: {k: w.signal for k, w in inner.items()}
                                     for t, inner in b.tileInternals.items()})


class BeatModel:
    '''The clocked multiplier: one `step()` per edge, the backend's schedule.

        beat = BeatModel(alignedModule, trace, aBound, bBound)
        beat.reset()
        for t in range(T):
            out = beat.step(aBatch[t], bBatch[t])   # None until the pipeline fills
        beat.observe('dsp0/u_dsp_mid.P')            # any wire, this cycle

    `latency` is the depth of the output wire — asserted at build against
    `module_latency`, so the first non-None `step()` result is the product
    of the batches fed `latency` edges earlier.
    '''

    def __init__(self, module: IR.IRModule, traceRoot, aBound: IntType, bBound: IntType,
                 *, tileModel: str = 'netlist'):
        self.module = module
        self.built = buildNet(module, traceRoot, Signal(aBound), Signal(bBound),
                              tileModel=tileModel, timed=True)
        self.net = self.built.net
        from dsp_multiplier.backend.schedule import module_latency
        self.latency = self.built.output.depth
        if self.latency != module_latency(module):
            raise ValueError(
                f'output depth {self.latency} != module_latency {module_latency(module)}')
        self.reset()

    def reset(self) -> None:
        self.net.reset()

    @property
    def tick(self) -> int:
        return self.net.tick

    def step(self, aBatch: list[int], bBatch: list[int]) -> list[int] | None:
        self.net.step({'A': aBatch, 'B': bBatch})
        return self.net.observe(self.built.output)

    def observe(self, name: str) -> list[int] | None:
        '''A wire by IR name, or `<tile>/<wire>` for a tile interior.'''
        if '/' in name:
            tile, inner = name.split('/', 1)
            return self.net.observe(self.built.tileInternals[tile][inner])
        return self.net.observe(self.built.wires[name])

    def wireNames(self) -> list[str]:
        out = list(self.built.wires)
        for tile, inner in self.built.tileInternals.items():
            out += [f'{tile}/{k}' for k in inner]
        return out


def crossCheckEvaluate(result: WalkResult, module: IR.IRModule,
                       aIn: Signal, bIn: Signal, samples: int = 8) -> int:
    '''Compare the walk against the backend testbench's own interpreter.'''
    from rtl_gen.dsp_multiplier.emit_tb import evaluate
    if aIn.values is None or bIn.values is None:
        return 0
    n = min(samples, len(aIn.values))
    widths = {o.result.name: o.result.width for o in module.ops}
    for i in range(n):
        ref = evaluate(module, {'A': aIn.values[i], 'B': bIn.values[i]})
        for name, s in result.signals.items():
            mask = (1 << widths[name]) - 1
            if (s.values[i] & mask) != (ref[name] & mask):
                raise AssertionError(
                    f'{name}: walk gives {s.values[i]}, emit_tb.evaluate gives '
                    f'{ref[name]} (sample {i}, masked to {widths[name]} bits)')
    return n
