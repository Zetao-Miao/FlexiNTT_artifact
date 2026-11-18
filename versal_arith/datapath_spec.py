"""Cross-subproject contract for the datapath generator (`rtl_gen/datapath.py`).

A *datapath* is a small acyclic netlist of named wires, each produced by one
node. It is what a modular multiplier, a modular reduction or a modular adder is
made of, and it is built by `operator_modeling.core.datapath.Datapath` — the
model that also computes every wire's bound and values — and consumed here by
the generator, which builds exactly the nodes it is told, with exactly the
registers the model scheduled. Pure data, like `butterfly_spec.py` and
`ntt_spec.py`, so importing it pulls in nothing.

Node kinds
----------
`heap`     out = (sum of `terms`) mod 2^W, two's complement when the wire is
           signed. A `SliceTerm` list, the primitive the butterfly and the
           constant multipliers use: a constant multiplication is the NAF terms
           of its input, a Solinas fold is slices with signed weights, a
           Montgomery `mod R` is a heap truncated at R. Built as wires (every
           column one bit), a two-operand adder (no column taller than two), or
           a compressor tree (`compressor_RTL_gen`) placed by `lut_timing`.
`mult`     out = a * b. `backend` is `dsp` (the `dspmult` generator), `booth`
           (`Bmult_RTL_gen`) or `behavioural` (`*`, for synthesis to infer).
           `bConst` set makes `b` a design-time constant tied at the port.
`table`    out = table[src[hi:lo]], a LUT ROM — the table half of a
           LUT-based reduction (`hi - lo + 1 <= 6` is one LUT6 per output bit).
`nonzero`  out = |src[hi:lo]   (one bit), the carry of word-level Montgomery.
`correct`  out = src - k*q for the largest k in {kLow, kLow+step, ...,
           kHigh} with a nonnegative result: exact reduction into [0, q) when
           step = 1, a lazy one into [0, step*q) otherwise. One subtractor per
           candidate, in parallel, and a priority select on their signs.
`fold`     a two-candidate correct/qcorrect without a select: 'sign' (x in
           [-s*q, s*q): y = x + [x < 0]*s*q, one gated adder) or 'compare' (x in
           [0, 2s*q): flag = x >= s*q, then y = x - flag*s*q; `regFlags`
           places a register after the compare (holding x, s*q and the flag)
           and after the subtraction).
`qcorrect` the same for a modulus that arrives at run time: `qMults` names, per
           candidate k, the wire holding |k|*q ('' for k = 0; subtracted for k > 0, added for k < 0), built by heaps
           from the q wire `qwire` and scheduled off the data path; `qMin` and
           `qMax` are the range of q the candidates were chosen for.

Every node carries `stages` (registers inside it), `regFlags` (where, for the
kinds with several units) and `start` (the cycle its inputs are aligned to).
`delays` lists the balancing shift registers the schedule needs: wire `src`
delayed by `cycles` is named `name`. The model asserts the latency; the
generator builds it; the testbench waits it.
"""
from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any

from butterfly_spec import SliceTerm


@dataclass(frozen=True)
class DpWire:
    name: str
    bitWidth: int
    isSigned: bool
    minValue: int
    maxValue: int
    zeroLsbs: int = 0


@dataclass(frozen=True)
class DpNode:
    kind: str                         # 'heap' | 'mult' | 'table' | 'nonzero' | 'correct' | 'qcorrect'
    out: DpWire
    inputs: tuple[str, ...]           # wire names this node reads (after delay renaming)
    terms: tuple[SliceTerm, ...] = ()           # heap
    a: str = ''                                 # mult
    b: str = ''
    bConst: int | None = None
    backend: str = ''                           # mult: 'dsp' | 'booth' | 'behavioural'
    dspBudget: int = 0
    src: str = ''                               # table, nonzero, correct
    lo: int = 0
    hi: int = 0
    table: tuple[int, ...] = ()
    modulus: int = 0                            # correct
    kLow: int = 0
    kHigh: int = 0
    step: int = 1
    qwire: str = ''                             # qcorrect
    qMults: tuple[str, ...] = ()
    qMin: int = 0
    qMax: int = 0
    fold: str = ''                              # correct/qcorrect: '' (select), 'sign', 'compare'
    stages: int = 0
    regFlags: tuple[bool, ...] = ()
    start: int = 0
    note: str = ''

    def to_dict(self) -> dict[str, Any]:
        d = asdict(self)
        d['terms'] = [asdict(t) for t in self.terms]
        return d


@dataclass(frozen=True)
class DpDelay:
    name: str
    src: str
    cycles: int
    bitWidth: int


@dataclass(frozen=True)
class DatapathSpec:
    name: str
    inputs: tuple[DpWire, ...]
    nodes: tuple[DpNode, ...]
    delays: tuple[DpDelay, ...]
    outputs: tuple[tuple[str, str], ...]     # (port name, wire name)
    wires: tuple[DpWire, ...]                # every wire, inputs and delays included
    latency: int
    targetFmaxMhz: float | None = None
    params: dict = field(default_factory=dict)
    #: quasi-static wires (one value per job, e.g. a limb's modulus constants):
    #: not delay-balanced, read by their consumers at any cycle
    static: tuple[str, ...] = ()
    #: inputs with the same value in every instance (per-frame modulus constants): the last
    #: register of each of their delay chains is kept per instance (no cross-instance merging)
    shared: tuple[str, ...] = ()

    def wire(self, name: str) -> DpWire:
        for w in self.wires:
            if w.name == name:
                return w
        raise KeyError(name)

    def to_dict(self) -> dict[str, Any]:
        return {
            'name': self.name,
            'inputs': [asdict(w) for w in self.inputs],
            'nodes': [n.to_dict() for n in self.nodes],
            'delays': [asdict(d) for d in self.delays],
            'outputs': [list(o) for o in self.outputs],
            'wires': [asdict(w) for w in self.wires],
            'latency': self.latency,
            'targetFmaxMhz': self.targetFmaxMhz,
            'params': dict(self.params),
            'static': list(self.static),
            **({'shared': list(self.shared)} if self.shared else {}),
        }
