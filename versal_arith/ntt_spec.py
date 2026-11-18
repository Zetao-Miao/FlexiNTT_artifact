"""Cross-subproject contract for the NTT/INTT pipeline RTL generator.

`InterStageWire` and `NTTOperatorSpec` are pure-data dataclasses defined
once and shared between two consumers:

  - `operator_modeling.ntt.pipelined.FullyPipelinedNTT.FullyPipelinedNTT.getOperatorInterface` populates an
    `NTTOperatorSpec` from a populated NTT instance (every butterfly's
    inputs and outputs have bounds set by `compute()`).

  - `versal_arith.rtl_gen.ntt.NTT_RTL_gen` consumes the spec and emits the
    top-level wrapper SystemVerilog, the self-checking testbench, one
    XDC per butterfly compressor in `xdc_generated/`, and hex testvectors.
    It also recursively calls
    `versal_arith.rtl_gen.butterfly.Butterfly_RTL_gen` for each butterfly
    in the grid.

The file lives at the top level of `versal_arith/` (NOT inside `rtl_gen/`)
so importing it from `operator_modeling` does not trigger `rtl_gen/__init__.py`'s
import chain. Same convention as `butterfly_spec.py`.

The wiring tables in `NTTOperatorSpec` are precomputed at extraction time
so the consumer never needs to import any `operator_modeling` helpers
(`butterflyToMems`, `memToButterfly`, `bitReverse`).
"""
from __future__ import annotations
from dataclasses import dataclass, asdict
from typing import Any

from butterfly_spec import ButterflyOperatorSpec


@dataclass(frozen=True)
class InterStageWire:
    """One input port's upstream binding within the butterfly grid.

    Carried by `NTTOperatorSpec.interStageWiring[s-1][p]` to describe where
    the layer-`s` butterfly at position `p` pulls its `aIn` (or `bIn`) from
    in layer `s-1`.
    """
    src_p: int        # producing butterfly position in the previous layer
    src_port: str     # 'A' | 'B'

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    @staticmethod
    def from_dict(d: dict[str, Any]) -> InterStageWire:
        return InterStageWire(**d)


@dataclass(frozen=True)
class NTTOperatorSpec:
    """All RTL-relevant data extracted from a populated `FullyPipelinedNTT`.

    Per-butterfly bit widths, signedness, and twiddle NAFs are inside each
    `ButterflyOperatorSpec` in `butterflySpecs`. The wiring tables describe
    how to connect natural-order x[i] ports to the stage-0 butterflies, how
    to connect each layer's outputs into the next layer, and how to extract
    natural-order y[i] from the final-stage butterflies.
    """
    name: str                                       # top module name, e.g. 'NTT_n128_GS'
    n: int
    butterflyType: str                              # 'CT' | 'GS'
    negacyclic: bool
    q: int

    butterflySpecs: list[list[ButterflyOperatorSpec]]   # shape log2(n) x n/2

    inputBitWidthsNatural: list[int]                # length n; per-natural input width
    inputIsSignedNatural: list[bool]                # length n
    outputBitWidthsNatural: list[int]               # length n
    outputIsSignedNatural: list[bool]               # length n

    inputWiring: list[tuple[int, int]]
    outputWiring: list[tuple[int, int]]

    interStageWiring: list[list[tuple[InterStageWire, InterStageWire]]]

    def to_dict(self) -> dict[str, Any]:
        return {
            'name': self.name,
            'n': self.n,
            'butterflyType': self.butterflyType,
            'negacyclic': self.negacyclic,
            'q': self.q,
            'butterflySpecs': [[b.to_dict() for b in layer] for layer in self.butterflySpecs],
            'inputBitWidthsNatural': list(self.inputBitWidthsNatural),
            'inputIsSignedNatural': list(self.inputIsSignedNatural),
            'outputBitWidthsNatural': list(self.outputBitWidthsNatural),
            'outputIsSignedNatural': list(self.outputIsSignedNatural),
            'inputWiring': [list(w) for w in self.inputWiring],
            'outputWiring': [list(w) for w in self.outputWiring],
            'interStageWiring': [
                [[a.to_dict(), b.to_dict()] for (a, b) in layer]
                for layer in self.interStageWiring
            ],
        }

    @staticmethod
    def from_dict(d: dict[str, Any]) -> NTTOperatorSpec:
        return NTTOperatorSpec(
            name=d['name'],
            n=d['n'],
            butterflyType=d['butterflyType'],
            negacyclic=d['negacyclic'],
            q=d['q'],
            butterflySpecs=[[_butterflyFromDict(b) for b in layer]
                            for layer in d['butterflySpecs']],
            inputBitWidthsNatural=list(d['inputBitWidthsNatural']),
            inputIsSignedNatural=list(d['inputIsSignedNatural']),
            outputBitWidthsNatural=list(d['outputBitWidthsNatural']),
            outputIsSignedNatural=list(d['outputIsSignedNatural']),
            inputWiring=[tuple(w) for w in d['inputWiring']],
            outputWiring=[tuple(w) for w in d['outputWiring']],
            interStageWiring=[
                [(InterStageWire.from_dict(a), InterStageWire.from_dict(b)) for (a, b) in layer]
                for layer in d['interStageWiring']
            ],
        )


def _butterflyFromDict(d: dict[str, Any]):
    """A butterfly spec read back from `to_dict`. A datapath butterfly's spec is
    recorded for traceability only: its scheduled datapath is not rebuilt."""
    if d.get('kind') == 'datapath':
        raise ValueError(f"{d['name']}: a datapath butterfly spec is not read back; regenerate it from the operator")
    return ButterflyOperatorSpec.from_dict(d)


@dataclass(frozen=True)
class StreamNTTSpec:
    """A streaming (stage-pipelined) NTT: `lanes` points per cycle through
    log2(n) stages, for `rtl_gen.ntt.StreamNTT_RTL_gen`. Built by
    `operator_modeling.ntt.dataflow.StreamingNTT.StreamingNTT.getOperatorInterface`.

    Cycle bookkeeping: a free-running frame counter `cnt` (cleared by `rst`)
    counts the cycle a point enters; anything `off` cycles further down the
    pipeline sees frame cycle (cnt - off) mod frameCycles.

    stages[s]: exchange (laneBit, cycleBit, D) or None and its offset `exOff`;
    `buOff` (when the butterflies' inputs arrive), `buLatency` (the stage's
    slowest butterfly; the others are balanced to it), `inWidth` / `outWidth`,
    and `slots`: per lane pair {laneA, laneB, module, rom (a key of `roms`
    or None for a constant twiddle), latency}.
    modules: butterfly name -> DatapathButterflySpec (ports aIn, bIn, [W, [WP]]).
    roms: key -> {'w': [...], 'wp': [...] or None, 'width', 'wpWidth'}; a table
    holds frameCycles entries, or 2*frameCycles (forward then inverse) with `dirPort`.
    twist: None or {'datapath': DatapathSpec (A, B -> P), 'submodules',
    'roms': [per lane table], 'width', 'latency', 'off', ['side': 'input']}: the output twist (CT),
    or with side 'input' the input twist in front of the first stage (GS).
    """
    name: str
    n: int
    lanes: int
    frameCycles: int
    q: int
    direction: str
    dirPort: bool
    inWidth: int
    outWidth: int
    latency: int
    stages: list
    modules: dict
    roms: dict
    twist: Any = None
    outputLocation: list = None          # memory index m -> (cycle, lane) on the output
    leadIn: int = 0                      # input delay so that no table is read during reset (GS)

    def to_dict(self) -> dict[str, Any]:
        return {'name': self.name, 'n': self.n, 'lanes': self.lanes, 'frameCycles': self.frameCycles,
                'q': self.q, 'direction': self.direction, 'dirPort': self.dirPort,
                'inWidth': self.inWidth, 'outWidth': self.outWidth, 'latency': self.latency,
                'stages': [{k: v for k, v in st.items()} for st in self.stages],
                'modules': {k: v.to_dict() for k, v in self.modules.items()},
                'roms': {str(k): {'entries': len(v['w']), 'width': v['width'], 'shoup': v['wp'] is not None}
                         for k, v in self.roms.items()}}


@dataclass(frozen=True)
class IterNTTSpec:
    """An iterative (memory-based) NTT, for `rtl_gen.iter_ntt.IterNTT_RTL_gen`.
    Built by `operator_modeling.ntt.iterative.IterativeNTT.IterativeNTT.getOperatorInterface`.

    Geometry (see `IterativeNTTScheme`): n = 2^L points, B = 2^b butterflies,
    2 sets x 2B banks of T = 2^H rows (H = L-b-1), `io` lanes per I/O beat,
    `beats` = n/io beats per polynomial. `gaps[s]`: idle cycles after stage s
    (d_s - T). `R`: RAM read latency; `buLatency`; `writeLatency` = R + buLatency + 4.
    `bu`: the butterfly's DatapathButterflySpec (one module, every butterfly).
    `readSources[p]`: the banks butterfly operand port p (A_j = 2j, B_j = 2j+1)
    reads; `writeSources[k]`: (butterfly, output) pairs bank k is written from.
    `tables`: per butterfly the twiddle table {depth, cols (widths), mode,
    values (rom, per column) or base (ram)}; `tdepth` one direction's depth.
    `twist`: None or {datapath, submodules, latency, tables (per lane)}.
    RNS modes (`twiddleBuffer` 'recycle' / 'double', a modulus per polynomial):
    the record stream tw_valid / tw_ready / tw_data of `twLanes` entries of
    sum(`twEntryCols`) bits a beat; `headerBeats` header beats (`headerLayout`:
    (port, bit offset, width), bit 0 the keep flag), then `stageBeats[s]` data beats
    per stage; `qBubble` = R + buLatency (cycles from a polynomial's last issue
    before a new modulus may start); the q ports are not core inputs then.
    """
    name: str
    n: int
    B: int
    L: int
    b: int
    H: int
    io: int
    beats: int
    q: int
    direction: str
    dirPort: bool
    width: int
    outWidth: int
    R: int
    buLatency: int
    writeLatency: int
    outLatency: int
    gaps: tuple
    halve: int
    bu: Any
    readSources: tuple
    writeSources: tuple
    readDecode: tuple
    writeDecode: tuple
    tables: tuple
    tdepth: int
    cdepth: int
    shareInv: bool
    loadWords: int
    qPorts: tuple
    memStyle: str
    twiddleStyle: str
    twist: Any = None
    twiddleBuffer: str = 'single'
    twLanes: int = 0
    twEntryCols: tuple = ()
    headerBeats: int = 0
    headerLayout: tuple = ()
    stageBeats: tuple = ()
    qBubble: int = 0
    # constant geometry (memOrg 'constgeo'; IterativeNTTScheme.cg*): per stage the read-order rotation, and the
    # twiddle table's stage regions (base, depth); readSources / writeSources / decodes are empty then
    # RNS with the output twist: the record's twist region (beats, entries a beat)
    dirPerPoly: bool = False
    qInline: bool = False         # qSwitch 'inline': no bubble, the constants switch with the data
    twistBeats: int = 0
    twistLanes: int = 0
    memOrg: str = 'inplace'
    crossRegs: int = 0
    cgShifts: tuple = ()
    twBases: tuple = ()
    twDepths: tuple = ()
    memOrgReport: Any = None
    # twiddleSource 'rec' (IterativeNTT._recSpec): the generator groups, the record's units, the multiplier
    rec: Any = None
    # fan-out trees (IterativeNTTScheme fanout=): {F, readTree, genTree, levels: {tree: registers per level}}
    fanout: Any = None
    # moduli= (multi-modulus ROM): {'moduli', 'bits' (MIDX width), 'table': {constant: value per modulus},
    # 'bubble' (qSwitch 'bubble': cycles after the last issue before a new modulus or direction starts)};
    # every table's 'depth1' is its one-modulus depth, its values hold a 2^ceil(log2 depth1) block per modulus
    mrom: Any = None

    def to_dict(self) -> dict[str, Any]:
        return {k: getattr(self, k) for k in ('name', 'n', 'B', 'L', 'io', 'beats', 'q', 'direction', 'dirPort',
                                               'width', 'outWidth', 'R', 'buLatency', 'writeLatency', 'outLatency',
                                               'gaps', 'halve', 'tdepth', 'loadWords', 'memStyle', 'twiddleStyle',
                                               'twiddleBuffer', 'twLanes', 'headerBeats', 'stageBeats', 'qBubble')}
