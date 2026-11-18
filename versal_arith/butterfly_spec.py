"""Cross-subproject contract for the butterfly RTL generator.

`SliceTerm` and `ButterflyOperatorSpec` are pure-data dataclasses defined
once and shared between two consumers:

  - `operator_modeling.ntt.butterfly.ButterflyScheme.GoldilocksSlice64.getOperatorInterface`
    populates a `ButterflyOperatorSpec` from a butterfly scheme that has
    already had its input bounds set (so input bit widths and signedness
    are known).

  - `versal_arith.rtl_gen.butterfly.Butterfly_RTL_gen` consumes the spec
    and emits SystemVerilog plus XDC plus a self-checking testbench;
    `versal_arith.sim_rtl_gen.butterfly.Butterfly_SimRTL_gen` is the
    behavioural stand-in with the same signature.

The file lives at the top level of `versal_arith/` so importing it does
NOT trigger `rtl_gen/__init__.py`'s import chain (which pulls in every
operator generator). Both subprojects can load this module cheaply.

A `SliceTerm` records one signed-shifted-slice contribution to one of
the butterfly's two outputs. The mathematical interpretation is:

    contribution = sign * ( ((source << inputShift)[sliceEnd:sliceStart])
                            << limbShift )

where `source` is one of the input registers (`'aIn'`, `'bIn'`) or a
baked-in constant (the `-q` lazy-reduction term). `isSigned` records
whether the slice came from `IntType.slice`'s signed (third) branch, in
which case the bit-heap construction in step 2 must sign-extend the
slice's MSB up to the output width.

`SliceTerm` is reused outside the butterfly: `ConstMultScheme._buildTerms`
emits one term per NAF digit (`inputShift=0`, `limbShift` = the exponent,
`source` = the input port name) and `LutMultiplierScheme.sliceTerm` builds
the DSP/LUT multiplier's partial products. The field comments name the
butterfly's use first and the general meaning second.
"""
from __future__ import annotations
from dataclasses import dataclass, asdict, field
from typing import Any


@dataclass(frozen=True)
class SliceTerm:
    source: str          # 'aIn' | 'bIn' | 'const' in a butterfly; the input
                         # port's own name in the constant- and LUT-multiplier
                         # reuses described above
    inputShift: int      # left-shift applied to the source before slicing (NAF exponent for shifted inputs; 0 otherwise)
    sliceStart: int      # inclusive bit position in the shifted-source value where the slice starts
    sliceEnd: int        # inclusive bit position where the slice ends
    isSigned: bool       # True iff the slice covers the source's full bitWidth (IntType.slice 3rd branch)
    limbShift: int       # the term's weight exponent: 0 or 32 from the limbs64
                         # table in a butterfly, the NAF exponent in a constant
                         # multiplier, any shift in a LUT multiplier
    sign: int            # +1 or -1 — combined outer sign (limb-factor sign times any per-term NAF sign)
    sourceZeroLsbs: int = 0  # low bits of `source` its bound guarantees are zero
    constValue: int = 0  # only meaningful when source == 'const' (e.g. q for the -q lazy-reduction term)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    @staticmethod
    def from_dict(d: dict[str, Any]) -> SliceTerm:
        return SliceTerm(**d)


@dataclass(frozen=True)
class ButterflyOperatorSpec:
    name: str                                 # e.g. 'Butterfly_n128_GS_L2_p5'
    butterflyType: str                        # 'CT' | 'GS'
    q: int
    aInBitWidth: int
    aInIsSigned: bool
    bInBitWidth: int
    bInIsSigned: bool
    aOutBitWidth: int
    aOutIsSigned: bool
    bOutBitWidth: int
    bOutIsSigned: bool
    liftedTwiddleNaf: list[tuple[int, int]]   # [(sign, exponent), ...]; ≤ 3 terms for GoldilocksSlice64
    aOutTerms: list[SliceTerm]
    bOutTerms: list[SliceTerm]

    def to_dict(self) -> dict[str, Any]:
        return {
            'name': self.name,
            'butterflyType': self.butterflyType,
            'q': self.q,
            'aInBitWidth': self.aInBitWidth,
            'aInIsSigned': self.aInIsSigned,
            'bInBitWidth': self.bInBitWidth,
            'bInIsSigned': self.bInIsSigned,
            'aOutBitWidth': self.aOutBitWidth,
            'aOutIsSigned': self.aOutIsSigned,
            'bOutBitWidth': self.bOutBitWidth,
            'bOutIsSigned': self.bOutIsSigned,
            'liftedTwiddleNaf': [list(t) for t in self.liftedTwiddleNaf],
            'aOutTerms': [t.to_dict() for t in self.aOutTerms],
            'bOutTerms': [t.to_dict() for t in self.bOutTerms],
        }

    @staticmethod
    def from_dict(d: dict[str, Any]) -> ButterflyOperatorSpec:
        return ButterflyOperatorSpec(
            name=d['name'],
            butterflyType=d['butterflyType'],
            q=d['q'],
            aInBitWidth=d['aInBitWidth'],
            aInIsSigned=d['aInIsSigned'],
            bInBitWidth=d['bInBitWidth'],
            bInIsSigned=d['bInIsSigned'],
            aOutBitWidth=d['aOutBitWidth'],
            aOutIsSigned=d['aOutIsSigned'],
            bOutBitWidth=d['bOutBitWidth'],
            bOutIsSigned=d['bOutIsSigned'],
            liftedTwiddleNaf=[tuple(t) for t in d['liftedTwiddleNaf']],
            aOutTerms=[SliceTerm.from_dict(t) for t in d['aOutTerms']],
            bOutTerms=[SliceTerm.from_dict(t) for t in d['bOutTerms']],
        )


@dataclass(frozen=True)
class DatapathButterflySpec:
    """An NTT butterfly built as a general datapath (`ModularBU` on the operator
    side: a modular multiplier and a modular adder/subtractor, any q and any
    reduction), for `rtl_gen.ntt.NTT_RTL_gen` next to the Goldilocks
    `ButterflyOperatorSpec`, and by `rtl_gen.butterfly.Butterfly_RTL_gen` for one
    butterfly with a testbench. The generator emits `datapath` as `<name>_dp` and a
    wrapper `<name>` with the NTT's butterfly ports (`clk`, `aIn`, `bIn`, `aOut`,
    `bOut`). `datapath` is scheduled already: its latency is the butterfly's.
    `submodules`: the dsp / booth multiplier modules its mult nodes need, as
    `Datapath_RTL_gen` takes them (generated by the operator side)."""
    name: str
    butterflyType: str                        # 'CT' | 'GS'
    q: int
    aInBitWidth: int
    aInIsSigned: bool
    bInBitWidth: int
    bInIsSigned: bool
    aOutBitWidth: int
    aOutIsSigned: bool
    bOutBitWidth: int
    bOutIsSigned: bool
    datapath: "DatapathSpec"                  # datapath_spec.DatapathSpec, already scheduled
    submodules: dict = field(default_factory=dict)
    #: the inputs beyond aIn / bIn, in port order, as (name, bitWidth): the twiddle
    #: (W, and WP for Shoup) and the run-time modulus ports (Q, MU, QP, QH, K, C).
    #: Empty for a constant twiddle and a fixed q. q is 0 for a run-time modulus.
    extraPorts: tuple = ()

    kind = 'datapath'

    def to_dict(self) -> dict[str, Any]:
        d = {k: getattr(self, k) for k in (
            'name', 'butterflyType', 'q', 'aInBitWidth', 'aInIsSigned', 'bInBitWidth', 'bInIsSigned',
            'aOutBitWidth', 'aOutIsSigned', 'bOutBitWidth', 'bOutIsSigned')}
        d['kind'] = self.kind
        d['extraPorts'] = [list(p) for p in self.extraPorts]
        d['datapath'] = self.datapath.to_dict()
        return d
