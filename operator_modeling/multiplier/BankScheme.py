'''The bank scheme: N constant multipliers sharing one input.

A composition, not a leaf — it holds N `NafConstMult` schemes and answers the
same questions they do, per entry. Its reason to exist is feeding a downstream
stage, and what that stage wants is a `list[IntType]`, so `propagateBound()`
returns exactly that and the bounds never round-trip through a JSON side-car.

Entries whose constant lands on the wiring or adder strategy are combinational,
so shorter entries receive balancing registers at their own width to match the
deepest compressor. Ports keep their own widths throughout — no widening at the
bank boundary.
'''
from __future__ import annotations

from ..core.IntType import IntType
from .ConstMultScheme import NafConstMult, defaultModuleName


class ConstMultBankScheme:
    '''N constant multipliers over one input, with uniform output latency.

    The bank is where the modelling pays off most. Its whole purpose is to feed
    a downstream stage — an NTT's `getInputsNatural`, typically — and what that
    stage needs is a `list[IntType]`, one per output port. `propagateBound()`
    returns exactly that, so the bounds never have to round-trip through a JSON
    side-car and be reconstructed.

    Ports keep their own widths: `A_<i>` at the shared input width, `P_<i>` at
    that entry's own output width. Entries whose constant lands on the wiring or
    adder strategy are combinational, so they receive balancing registers at
    their own width to match the deepest compressor — no widening at the bank
    boundary.
    '''

    def __init__(self, name: str = 'cmultbank',
                 constants=(),
                 aIn: IntType = IntType(0, 0, 0),
                 aInValues: list[int] | None = None,
                 modulus: int | None = None,
                 sharedInput: bool = True,
                 countInverters: bool = True,
                 verbose: bool = False,
                 targetFmaxMhz: float | None = None,
                 **liftKwargs):
        constants = list(constants)
        if not constants:
            raise ValueError(f'{name}: no constants given')
        self.name = name
        self.aIn = aIn
        self.aInValues = aInValues
        self.modulus = modulus
        self.sharedInput = sharedInput
        self.verbose = verbose
        #: Frequency in, cycles out, per entry: every compressor takes the
        #: fewest stages that reach it and the wrapper balances the rest.
        self.targetFmaxMhz = targetFmaxMhz
        self.schemes: list[NafConstMult] = [
            NafConstMult(name=f'{name}_P{i}', constant=c, aIn=aIn,
                         aInValues=aInValues, modulus=modulus,
                         countInverters=countInverters, verbose=verbose,
                         targetFmaxMhz=targetFmaxMhz,
                         **liftKwargs)
            for i, c in enumerate(constants)
        ]

    def __len__(self) -> int:
        return len(self.schemes)

    def setInputValues(self, values: list[int]) -> None:
        '''Drive every entry from one shared input batch.'''
        self.aInValues = values
        for scheme in self.schemes:
            scheme.aInValues = values

    def propagateBound(self) -> list[IntType]:
        '''Per-entry output bounds, in port order.

        Feed straight into `FullyPipelinedNTT.getInputsNatural(bounds)`.
        '''
        return [scheme.propagateBound() for scheme in self.schemes]

    def propagateValue(self) -> list[list[int]]:
        '''Per-entry output value batches, in port order.'''
        return [scheme.propagateValue() for scheme in self.schemes]

    def perEntryLatency(self, pipelineStages: int = 1) -> list[int]:
        '''Latency of each entry before balancing registers are added.'''
        return [s.latency(pipelineStages) for s in self.schemes]

    def latency(self, pipelineStages: int = 1) -> int:
        '''Uniform latency every output port sees.

        Mirrors the bank generator: the deepest entry, but never fewer cycles
        than were requested, and never zero. Under `targetFmaxMhz` nothing is
        requested on top of what the entries chose for themselves.
        '''
        requested = 0 if self.targetFmaxMhz is not None else pipelineStages
        return max(max(self.perEntryLatency(pipelineStages)), requested, 1)

    def criticalPathNs(self, pipelineStages: int = 1) -> float:
        '''Predicted slowest segment over the entries, clock uncertainty excluded.'''
        return max(s.criticalPathNs(pipelineStages) for s in self.schemes)

    def areaCost(self) -> tuple[int, int]:
        '''Summed `(LUT, DSP)` over the entries.

        Excludes the balancing registers, which are flip-flops rather than LUTs.
        '''
        luts = sum(s.areaCost()[0] for s in self.schemes)
        return luts, 0

    def resources(self):
        '''`Resources` (LUT, DSP, BRAM36, BRAM18) from `areaCost()`, as
        `OperatorScheme.resources` derives it; this class stands outside that
        base.'''
        from ..core.Resources import Resources
        lut, dsp = self.areaCost()
        return Resources(lut=lut, dsp=dsp)

    def getOperatorInterface(self, name: str,
                             pipelineStages: int = 1) -> 'ConstMultBankSpec':
        from const_mult_spec import ConstMultBankSpec

        # Every `A_<i>` port is declared at the bank's own width (the generator
        # reads `spec.aInBitWidth`) and `_prepareTestData` samples from the
        # bank's own bound, while `ConstMultBank.compute` writes each entry's
        # `aIn` from the signal that drove its lane. If the two disagree the
        # spec describes hardware the entries were not sized for, silently.
        mismatched = [
            i for i, s in enumerate(self.schemes)
            if (s.aIn.bitWidth, s.aIn.isSigned, s.aIn.zeroLsbs)
            != (self.aIn.bitWidth, self.aIn.isSigned, self.aIn.zeroLsbs)
        ]
        if mismatched:
            shown = ', '.join(str(i) for i in mismatched[:8])
            more = '...' if len(mismatched) > 8 else ''
            raise ValueError(
                f'{self.name}.getOperatorInterface: entries [{shown}{more}] were '
                f'driven at a bound the bank does not declare. The bank says '
                f'{self.aIn}; entry {mismatched[0]} carries '
                f'{self.schemes[mismatched[0]].aIn}. Build the bank at the bound '
                f'its lanes are driven with, or drive every lane at the bank\'s.'
            )

        entries = [
            scheme.getOperatorInterface(
                defaultModuleName(self.aIn.bitWidth, scheme._liftConstant()[0]))
            for scheme in self.schemes
        ]
        perEntry = self.perEntryLatency(pipelineStages)
        return ConstMultBankSpec(
            name=name,
            aInBitWidth=self.aIn.bitWidth,
            aInIsSigned=self.aIn.isSigned,
            aInZeroLsbs=self.aIn.zeroLsbs,
            sharedInput=self.sharedInput,
            entries=entries,
            requestedPipelineStages=pipelineStages,
            uniformLatency=self.latency(pipelineStages),
            perEntryLatency=perEntry,
        )
