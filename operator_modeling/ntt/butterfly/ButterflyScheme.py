from __future__ import annotations
import dataclasses as _dataclasses
import os as _os
from types import SimpleNamespace
import sys as _sys
from ...core.IntType import IntType
from abc import ABC, abstractmethod
from ...core.utils import (
    nafTermsCount, nafTermsModulusLift,
    vectorAdd, vectorSub, vectorLshift, vectorSlice, vectorConst,
)

# versal_arith is a sibling project, not a Python package (no top-level __init__.py),
# so we add its directory to sys.path on demand. Both the shared spec dataclasses
# and the rtl_gen butterfly generator are imported through that path.
_versalArithDir = _os.path.normpath(_os.path.join(_os.path.dirname(__file__), '..', '..', '..', 'versal_arith'))
if _versalArithDir not in _sys.path:
    _sys.path.append(_versalArithDir)
from butterfly_spec import ButterflyOperatorSpec, DatapathButterflySpec, SliceTerm
from ...modmult.ModButterfly import ModularButterflyScheme
from ...modmult.ReductionScheme import BarrettReduction


class ButterflyScheme(ABC):
    def __init__(self, name: str = 'Undefined Butterfly Scheme',
                 aIn: IntType | list[int] = IntType(0, 0, 0),
                 bIn: IntType | list[int] = IntType(0, 0, 0),
                 twiddle: IntType | int | list[tuple[int, int]] = IntType(0, 0, 0),
                 aInValues: list[int] | None = None,
                 bInValues: list[int] | None = None):
        self.name: str = name
        # Bounds and value batches live in SEPARATE slots. They used to share
        # `aIn`/`bIn`, which forced two things: the paths had to run in a fixed
        # order (bound first, then value, overwriting the slot), and the register
        # width had to be smuggled across in `aInBitWidth` because once the slot
        # held a list the bound was gone. With the slots split, the value path
        # simply reads `self.aIn.bitWidth` — the same number the bound path used,
        # by construction rather than by assignment.
        self.aIn: IntType | list[int] = aIn
        self.bIn: IntType | list[int] = bIn
        self.aInValues: list[int] | None = aInValues
        self.bInValues: list[int] | None = bInValues
        self.twiddle: IntType | int | list[tuple[int, int]] = twiddle
        self.q: int = 0
        # Deprecated: kept for one phase as a cross-check. When set, it MUST agree
        # with `aIn.bitWidth`; `_inputBitWidths()` asserts that rather than
        # trusting either source blindly. Remove once nothing assigns it.
        self.aInBitWidth: int | None = None
        self.bInBitWidth: int | None = None

    def _inputBitWidths(self) -> tuple[int, int]:
        '''Register widths the value path must slice at, taken from the bounds.

        A width measured from the value batch would be wrong whenever the batch
        does not exercise the top bits, and wrong here means the Goldilocks limb
        boundary lands in the wrong place and the unreduced result is off by a
        multiple of q. So the bound is the only source, and the deprecated
        `aInBitWidth` is checked against it rather than used.
        '''
        if not isinstance(self.aIn, IntType) or not isinstance(self.bIn, IntType):
            raise TypeError(
                f'{self.name}: aIn/bIn must hold IntType bounds when the value '
                f'path runs (value batches belong in aInValues/bInValues); got '
                f'{type(self.aIn).__name__} and {type(self.bIn).__name__}'
            )
        aw, bw = self.aIn.bitWidth, self.bIn.bitWidth
        for legacy, derived, which in ((self.aInBitWidth, aw, 'aIn'),
                                       (self.bInBitWidth, bw, 'bIn')):
            if legacy is not None and legacy != derived:
                raise ValueError(
                    f'{self.name}: {which}BitWidth={legacy} disagrees with '
                    f'{which}.bitWidth={derived}. These must be the same number; '
                    f'slicing at the wrong width shifts the Goldilocks limb '
                    f'boundary and corrupts the result by a multiple of q.'
                )
        return aw, bw

    @abstractmethod
    def propagateBound(self) -> tuple[IntType, IntType]:
        '''Given input bounds, return (aOutBound, bOutBound)'''
        # common checks
        if not isinstance(self.aIn, IntType):
            raise TypeError(f'Expected aIn to be of type IntType, got {type(self.aIn)}')
        if not isinstance(self.bIn, IntType):
            raise TypeError(f'Expected bIn to be of type IntType, got {type(self.bIn)}')
        if not isinstance(self.twiddle, (IntType, int, list)):
            raise TypeError(f'Expected twiddle to be of type IntType, int or list[tuple[int, int]] (NAF), got {type(self.twiddle)}')
        return IntType(0, 0, 0), IntType(0, 0, 0)

    @abstractmethod
    def propagateValue(self) -> tuple[list[int], list[int]]:
        '''Given test vectors of inputs, return (aOutTestVec, bOutTestVec)'''
        # common checks — values come from aInValues/bInValues, widths from the
        # bounds still sitting in aIn/bIn.
        if not isinstance(self.aInValues, list):
            raise TypeError(f'Expected aInValues to be of type list[int], got {type(self.aInValues)}')
        if not isinstance(self.bInValues, list):
            raise TypeError(f'Expected bInValues to be of type list[int], got {type(self.bInValues)}')
        if not isinstance(self.twiddle, (int, list)):
            raise TypeError(f'Expected twiddle to be of type int or list[tuple[int, int]] (NAF), got {type(self.twiddle)}')
        if not all(isinstance(x, int) for x in self.aInValues):
            raise TypeError('Expected all elements of aInValues to be of type int')
        if not all(isinstance(x, int) for x in self.bInValues):
            raise TypeError('Expected all elements of bInValues to be of type int')

    @abstractmethod
    def areaCost(self) -> tuple[int, int]:
        '''Return (LUT cost, DSP cost) for FPGAs, or (real area cost, 0) for ASICs'''
        ...

    def resources(self):
        '''`Resources` (LUT, DSP, BRAM36, BRAM18) from `areaCost()`, as
        `OperatorScheme.resources` derives it; this ABC is not reparented onto
        that base (docs/REFACTOR_BACKLOG.md item 9).'''
        from ...core.Resources import Resources
        lut, dsp = self.areaCost()
        return Resources(lut=lut, dsp=dsp)

    def latency(self, pipelineStages: int = 1) -> int:
        '''Pipeline registers between this butterfly's inputs and outputs.'''
        raise NotImplementedError(f'{type(self).__name__} does not report a latency')


class GoldilocksSlice64(ButterflyScheme):
    def __init__(self, name: str = 'Undefined GoldilocksSlice64 Butterfly Scheme', butterflyType: str = None, aIn: IntType | list[int] = IntType(0, 0, 0), bIn: IntType | list[int] = IntType(0, 0, 0), twiddle: IntType | int | list[tuple[int, int]] = IntType(0, 0, 0), verbose: bool = False, targetFmaxMhz: float | None = None):
        super().__init__(name, aIn, bIn, twiddle)
        self.q = 2**64 - 2**32 + 1
        self.butterflyType: str = butterflyType
        self.verbose: bool = verbose
        #: Frequency in, cycles out: each output's compressor takes the fewest
        #: stages that reach it (see `stagePlan`); forwarded to the generator
        #: by `emitRtl`.
        self.targetFmaxMhz: float | None = targetFmaxMhz

    # ------------------------------------------------------------------
    # Pipelining: the generator's own decision, read back
    # ------------------------------------------------------------------

    def stagePlan(self, pipelineStages: int = 1):
        '''`rtl_gen.butterfly.butterfly_stage_plan` on this scheme's spec: the
        register placement of both compressors and the wrapper latency. It is
        the single place the decision is made -- the hardware generator builds
        it, the sim backend copies its latency -- so `latency` below can only
        report what will be built. Requires `aIn`, `bIn` and `twiddle` set, as
        `getOperatorInterface` does.'''
        from rtl_gen.butterfly import butterfly_stage_plan
        return butterfly_stage_plan(self.getOperatorInterface(self.name),
                                    pipelineStages, self.targetFmaxMhz)

    def latency(self, pipelineStages: int = 1) -> int:
        '''Registers between the inputs and outputs: the deeper compressor,
        each capped at its own unit count; the wrapper balances the other. `0`
        is a combinational butterfly.'''
        if pipelineStages < 0:
            raise ValueError(f'{self.name}: pipelineStages must be >= 0, got {pipelineStages}')
        return self.stagePlan(pipelineStages).latency

    def criticalPathNs(self, pipelineStages: int = 1) -> float:
        '''Predicted slowest segment of either compressor, clock uncertainty excluded.'''
        plan = self.stagePlan(pipelineStages)
        return max(plan.aOut.worst_ns, plan.bOut.worst_ns)

    def achievedFmaxMhz(self, pipelineStages: int = 1) -> float:
        from lut_timing import fmax_of
        return fmax_of(self.criticalPathNs(pipelineStages))

    # Goldilocks limb-factor table — encodes the modular identities
    #   2^64  ≡ 2^32 - 1   (mod q)        ->  bits [64:95]  contribute as (shift=0, sign=-1) + (shift=32, sign=+1)
    #   2^96  ≡ -1         (mod q)        ->  bits [96:159] contribute as (shift=0, sign=-1)
    #   2^128 ≡ -2^32      (mod q)        ->  (folded into the bits [96:159] limb via its own shift, no separate entry)
    #   2^160 ≡ -2^32 + 1  (mod q)        ->  bits [160:191] contribute as (shift=0, sign=+1) + (shift=32, sign=-1)
    #   2^192 ≡ 1          (mod q)        ->  the cycle restarts (handled by % 192 in _buildSliceTerms)
    _LIMBS64 = (
        ((0, 63),    ((0, +1),)),
        ((64, 95),   ((0, -1), (32, +1))),
        ((96, 159),  ((0, -1),)),
        ((160, 191), ((0, +1), (32, -1))),
    )
    _SUB_BOUNDARIES = (64, 96, 160)

    def _liftTwiddle(self) -> list[tuple[int, int]]:
        '''Resolve self.twiddle to a NAF list. Modulus-lifts an integer twiddle (≤ 3 NAF terms with maxPower=95); passes a pre-lifted NAF list through unchanged. Verbose-prints the lift summary if self.verbose is set, exactly as the original propagateBound did.'''
        if isinstance(self.twiddle, IntType):
            raise TypeError(f'Expected twiddle to be of type int or list[tuple[int, int]] (NAF) for GoldilocksSlice64 scheme, got IntType')
        if isinstance(self.twiddle, int):
            liftedTwiddle, liftedTwiddleNaf, _, _ = nafTermsModulusLift(
                x=self.twiddle, modulus=self.q, maxPower=95,
                maxMultipleOfModulus=2**32, maxSearchDepth=3, beamWidth=200,
                maxNumberOfTerms=3,
            )
            if self.verbose:
                print(f'Original twiddle: {self.twiddle}, lifted twiddle: {liftedTwiddle}')
                print(f'NAF term count of original twiddle: {nafTermsCount(self.twiddle)}, NAF term count of lifted twiddle: {len(liftedTwiddleNaf)}')
        else:
            liftedTwiddleNaf = list(self.twiddle)
            if self.verbose:
                print(f'Pre-lifted NAF twiddle: {liftedTwiddleNaf} ({len(liftedTwiddleNaf)} terms)')
        if len(liftedTwiddleNaf) > 3:
            raise ValueError(f'GoldilocksSlice64 supports up to 3 NAF terms per twiddle (Goldilocks slice64 hardware constraint), got {len(liftedTwiddleNaf)}: {liftedTwiddleNaf}')
        return list(liftedTwiddleNaf)

    def _shiftAndSliceTerms(self, source: str, input_: IntType, inputShift: int, outerSign: int) -> list[SliceTerm]:
        '''Slice `input_ << inputShift` at the Goldilocks 192-block sub-boundaries (64, 96, 160). For each non-zero limb slice, look up its `_LIMBS64` factors and emit one SliceTerm per factor. Mirrors the inner shiftAndSlice + processGoldilocks64Slices loop from the previous propagateBound.'''
        out: list[SliceTerm] = []
        if inputShift < 0:
            raise ValueError(f'Invalid shift amount {inputShift}, must be non-negative')
        inputShifted = input_ << inputShift
        if inputShifted.isZero:
            return out
        end = inputShifted.bitWidth - 1
        pos = 0
        while pos <= end:
            blockStart = (pos // 192) * 192
            relPos = pos - blockStart
            nextBoundary = blockStart + 192
            for b in self._SUB_BOUNDARIES:
                if b > relPos:
                    nextBoundary = blockStart + b
                    break
            sliceEnd = min(nextBoundary - 1, end)
            sliceIntType = inputShifted.slice(pos, sliceEnd)
            # Skip exactly-zero slices (the IntType.slice first branch, width <= zeroLsbs).
            # Including them would just add IntType(0,0,0) terms that contribute nothing
            # to the bound and would make the bit-heap construction in step 2 wider for no
            # reason.
            if sliceIntType.isZero:
                pos = sliceEnd + 1
                continue
            startMod = pos % 192
            endMod = sliceEnd % 192
            for (limbStart, limbEnd), factors in self._LIMBS64:
                if startMod >= limbStart and endMod <= limbEnd:
                    for limbShift, limbSign in factors:
                        out.append(SliceTerm(
                            source=source,
                            inputShift=inputShift,
                            sliceStart=pos,
                            sliceEnd=sliceEnd,
                            isSigned=sliceIntType.isSigned,
                            limbShift=limbShift,
                            sign=limbSign * outerSign,
                            sourceZeroLsbs=input_.zeroLsbs,
                            constValue=0,
                        ))
                    break
            else:
                raise ValueError(f'Slice ({pos}, {sliceEnd}) does not fit any limb range')
            pos = sliceEnd + 1
        return out

    def _buildSliceTerms(self) -> tuple[list[SliceTerm], list[SliceTerm], list[tuple[int, int]]]:
        '''Build the per-output bit-level provenance — every signed-shifted-slice summand that contributes to aOut and bOut, plus the lifted-NAF twiddle list. Both propagateBound (via _sumSliceTerms) and getOperatorInterface call this helper, so the IntType bound and the RTL spec stay derived from a single source of truth. Caller is responsible for the IntType type checks (super().propagateBound() does them in propagateBound; getOperatorInterface re-checks inline).'''
        liftedTwiddleNaf = self._liftTwiddle()

        aOutTerms: list[SliceTerm] = []
        bOutTerms: list[SliceTerm] = []
        # The -q "lazy reduction" constant goes only on aOut for both CT and GS, matching
        # the original propagateBound. q has 65 bits (2^64 - 2^32 + 1 has bits [0:31] and bit 64).
        qConst = SliceTerm(
            source='const', inputShift=0,
            sliceStart=0, sliceEnd=self.q.bit_length() - 1,
            isSigned=False, limbShift=0, sign=-1, constValue=self.q,
        )

        if self.butterflyType == 'CT':
            # Cooley-Tukey (Decimation-in-Time):
            #   aOut = aIn + bIn * twiddle  - q
            #   bOut = aIn - bIn * twiddle
            aOutTerms.append(qConst)
            aInTerms = self._shiftAndSliceTerms('aIn', self.aIn, inputShift=0, outerSign=1)
            aOutTerms.extend(aInTerms)
            bOutTerms.extend(aInTerms)
            for nafSign, nafShift in liftedTwiddleNaf:
                aOutTerms.extend(self._shiftAndSliceTerms('bIn', self.bIn, inputShift=nafShift, outerSign=nafSign))
                bOutTerms.extend(self._shiftAndSliceTerms('bIn', self.bIn, inputShift=nafShift, outerSign=-nafSign))
        elif self.butterflyType == 'GS':
            # Gentleman-Sande (Decimation-in-Frequency):
            #   aOut = aIn + bIn  - q
            #   bOut = (aIn - bIn) * twiddle
            aOutTerms.append(qConst)
            aOutTerms.extend(self._shiftAndSliceTerms('aIn', self.aIn, inputShift=0, outerSign=1))
            aOutTerms.extend(self._shiftAndSliceTerms('bIn', self.bIn, inputShift=0, outerSign=1))
            for nafSign, nafShift in liftedTwiddleNaf:
                bOutTerms.extend(self._shiftAndSliceTerms('aIn', self.aIn, inputShift=nafShift, outerSign=nafSign))
                bOutTerms.extend(self._shiftAndSliceTerms('bIn', self.bIn, inputShift=nafShift, outerSign=-nafSign))
        else:
            raise ValueError(f'Unsupported butterfly type {self.butterflyType} for GoldilocksSlice64 scheme')

        return aOutTerms, bOutTerms, liftedTwiddleNaf

    def _sumSliceTerms(self, terms: list[SliceTerm]) -> IntType:
        '''Sum a SliceTerm list back into an IntType bound, mirroring how the previous propagateBound summed its (slice, sign) accumulator. Each term contributes ±((source << inputShift)[sliceEnd:sliceStart] << limbShift); const terms contribute ±(IntType(constValue, constValue, 0) << limbShift).'''
        out = IntType(0, 0, 0)
        for t in terms:
            if t.source == 'const':
                piece = IntType(t.constValue, t.constValue, 0) << t.limbShift
            else:
                inp = self.aIn if t.source == 'aIn' else self.bIn
                shifted = inp << t.inputShift
                sliced = shifted.slice(t.sliceStart, t.sliceEnd)
                piece = sliced << t.limbShift
            out = out + piece if t.sign == 1 else out - piece
        return out

    def propagateBound(self) -> tuple[IntType, IntType]:
        # perform common checks
        super().propagateBound()
        aOutTerms, bOutTerms, _ = self._buildSliceTerms()
        return self._sumSliceTerms(aOutTerms), self._sumSliceTerms(bOutTerms)

    def getOperatorInterface(self, name: str) -> ButterflyOperatorSpec:
        '''Return a ButterflyOperatorSpec describing this butterfly at RTL granularity: the per-output list of signed-shifted-slice summands, the lifted-NAF twiddle, and the input/output bit-widths and signedness. Consumed by versal_arith's butterfly RTL generator. Requires self.aIn and self.bIn to already be set as IntType bounds; caller is typically Butterfly.compute() or a generator script that has already wired the input bounds.'''
        # Same type checks as super().propagateBound() — replicated inline so we don't
        # invoke the abstract base method just to throw away its return value.
        if not isinstance(self.aIn, IntType):
            raise TypeError(f'Expected aIn to be of type IntType, got {type(self.aIn)}')
        if not isinstance(self.bIn, IntType):
            raise TypeError(f'Expected bIn to be of type IntType, got {type(self.bIn)}')
        if not isinstance(self.twiddle, (int, list)):
            raise TypeError(f'Expected twiddle to be of type int or list[tuple[int, int]] (NAF) for GoldilocksSlice64 scheme, got {type(self.twiddle)}')

        aOutTerms, bOutTerms, liftedNaf = self._buildSliceTerms()
        aOutBound = self._sumSliceTerms(aOutTerms)
        bOutBound = self._sumSliceTerms(bOutTerms)

        return ButterflyOperatorSpec(
            name=name,
            butterflyType=self.butterflyType,
            q=self.q,
            aInBitWidth=self.aIn.bitWidth,
            aInIsSigned=self.aIn.isSigned,
            bInBitWidth=self.bIn.bitWidth,
            bInIsSigned=self.bIn.isSigned,
            aOutBitWidth=aOutBound.bitWidth,
            aOutIsSigned=aOutBound.isSigned,
            bOutBitWidth=bOutBound.bitWidth,
            bOutIsSigned=bOutBound.isSigned,
            liftedTwiddleNaf=list(liftedNaf),
            aOutTerms=aOutTerms,
            bOutTerms=bOutTerms,
        )


    def propagateValue(self) -> tuple[list[int], list[int]]:
        # perform common checks
        super().propagateValue()
        aBitWidth, bBitWidth = self._inputBitWidths()
        batchSize = len(self.aInValues)
        if len(self.bInValues) != batchSize:
            raise ValueError(f'aInValues and bInValues must have the same batch length, got {batchSize} and {len(self.bInValues)}')

        if isinstance(self.twiddle, int):
            liftedTwiddle, liftedTwiddleNaf, _, _ = nafTermsModulusLift(x=self.twiddle, modulus=self.q, maxPower=95, maxMultipleOfModulus=2**32, maxSearchDepth=3, beamWidth=200, maxNumberOfTerms=3)
            if self.verbose:
                print(f'Original twiddle: {self.twiddle}, lifted twiddle: {liftedTwiddle}')
                print(f'NAF term count of original twiddle: {nafTermsCount(self.twiddle)}, NAF term count of lifted twiddle: {len(liftedTwiddleNaf)}')
        elif isinstance(self.twiddle, list):
            liftedTwiddleNaf = self.twiddle
            if self.verbose:
                print(f'Pre-lifted NAF twiddle: {liftedTwiddleNaf} ({len(liftedTwiddleNaf)} terms)')
        else:
            raise TypeError(f'Expected twiddle to be of type int or list[tuple[int, int]] (NAF) for GoldilocksSlice64 scheme, got {type(self.twiddle)}')

        if len(liftedTwiddleNaf) > 3:
            raise ValueError(f'GoldilocksSlice64 supports up to 3 NAF terms per twiddle (Goldilocks slice64 hardware constraint), got {len(liftedTwiddleNaf)}: {liftedTwiddleNaf}')

        # Identical limb-factor table to propagateBound (see comments there for the math).
        limbs64 = (
            ((0, 63), ((0, +1),)),
            ((64, 95), ((0, -1), (32, +1))),
            ((96, 159), ((0, -1),)),
            ((160, 191), ((0, +1), (32, -1))),
        )

        def shiftAndSliceGoldilocks64Value(input: list[int], shift: int, inputBitWidth: int | None, start: int = 0, end: int | None = None) -> dict[tuple[int, int], list[int]]:
            '''Value-batch parallel of shiftAndSliceGoldilocks64. Slices `input << shift` into Goldilocks-aligned limbs. The last (boundary) limb is taken as a Python-signed slice so that negative inputs reconstruct correctly via the Goldilocks identities — mirroring IntType.slice's signed branch. `inputBitWidth` MUST be the input bound's bitWidth (mirroring propagateBound's `inputShifted.bitWidth - 1` end), so the value path uses the same slicing pattern as the bound; `None` is a hard error (see the raise below), because a width measured from the batch moves the Goldilocks limb boundary and leaves the result wrong by a multiple of q -- invisible to any mod-q check, including verifyNtt.'''
            if shift < 0:
                raise ValueError(f'Invalid shift amount {shift}, must be non-negative')
            inputShifted = vectorLshift(input, shift)
            if all(x == 0 for x in inputShifted):
                return {}
            if end is None:
                if inputBitWidth is None:
                    # Deliberately fatal. Measuring the width from the batch
                    # instead of the bound puts the limb boundary in the wrong
                    # place whenever the sample does not reach the top bits,
                    # and the result is then wrong by a multiple of q --
                    # invisible to any mod-q check, including verifyNtt.
                    raise ValueError(
                        'shiftAndSliceGoldilocks64Value: inputBitWidth is '
                        'required; it must come from the input bound, never '
                        'from measuring the value batch')
                end = inputBitWidth + shift - 1
            if end < start:
                raise ValueError(f'Invalid limb range ({start}, {end})')

            SUB_BOUNDARIES = (64, 96, 160)
            outSlices: dict[tuple[int, int], list[int]] = {}
            pos = start
            while pos <= end:
                blockStart = (pos // 192) * 192
                relPos = pos - blockStart
                nextBoundary = blockStart + 192
                for b in SUB_BOUNDARIES:
                    if b > relPos:
                        nextBoundary = blockStart + b
                        break
                sliceEnd = min(nextBoundary - 1, end)
                isBoundary = (sliceEnd == end)
                outSlices[(pos, sliceEnd)] = vectorSlice(inputShifted, pos, sliceEnd, signed=isBoundary)
                pos = sliceEnd + 1
            return outSlices

        def processGoldilocks64SlicesValue(slices: dict[tuple[int, int], list[int]], limbFactors: tuple[tuple[tuple[int, int], tuple[tuple[int, int], ...]], ...], outerSign: int) -> list[tuple[list[int], int]]:
            '''Value-batch parallel of processGoldilocks64Slices. Returns list of (vec, sign) per limb factor.'''
            out: list[tuple[list[int], int]] = []
            for (start, end), slc in slices.items():
                startMod = start % 192
                endMod = end % 192
                for (limbStart, limbEnd), factors in limbFactors:
                    if startMod >= limbStart and endMod <= limbEnd:
                        for shift, sign in factors:
                            shiftedSlice = vectorLshift(slc, shift)
                            out.append((shiftedSlice, sign * outerSign))
                        break
                else:
                    raise ValueError(f'Slice ({start}, {end}) does not fit any limb range')
            return out

        if self.butterflyType == 'CT':
            # Cooley-Tukey: aOut = aIn + bIn * twiddle ; bOut = aIn - bIn * twiddle
            aOutSlices: list[tuple[list[int], int]] = [(vectorConst(self.q, batchSize), -1)]
            bOutSlices: list[tuple[list[int], int]] = []
            aInSlices = shiftAndSliceGoldilocks64Value(input=self.aInValues, shift=0, inputBitWidth=aBitWidth)
            aOutSlices.extend(processGoldilocks64SlicesValue(slices=aInSlices, limbFactors=limbs64, outerSign=1))
            bOutSlices.extend(processGoldilocks64SlicesValue(slices=aInSlices, limbFactors=limbs64, outerSign=1))
            for sign, shift in liftedTwiddleNaf:
                bShiftedSlices = shiftAndSliceGoldilocks64Value(input=self.bInValues, shift=shift, inputBitWidth=bBitWidth)
                aOutSlices.extend(processGoldilocks64SlicesValue(slices=bShiftedSlices, limbFactors=limbs64, outerSign=sign))
                bOutSlices.extend(processGoldilocks64SlicesValue(slices=bShiftedSlices, limbFactors=limbs64, outerSign=-sign))
            aOut = vectorConst(0, batchSize)
            bOut = vectorConst(0, batchSize)
            for slc, sign in aOutSlices:
                aOut = vectorAdd(aOut, slc) if sign == 1 else vectorSub(aOut, slc)
            for slc, sign in bOutSlices:
                bOut = vectorAdd(bOut, slc) if sign == 1 else vectorSub(bOut, slc)
            return aOut, bOut

        elif self.butterflyType == 'GS':
            # Gentleman-Sande: aOut = aIn + bIn ; bOut = (aIn - bIn) * twiddle
            aOutSlices = [(vectorConst(self.q, batchSize), -1)]
            bOutSlices = []
            aInSlices = shiftAndSliceGoldilocks64Value(input=self.aInValues, shift=0, inputBitWidth=aBitWidth)
            bInSlices = shiftAndSliceGoldilocks64Value(input=self.bInValues, shift=0, inputBitWidth=bBitWidth)
            aOutSlices.extend(processGoldilocks64SlicesValue(slices=aInSlices, limbFactors=limbs64, outerSign=1))
            aOutSlices.extend(processGoldilocks64SlicesValue(slices=bInSlices, limbFactors=limbs64, outerSign=1))
            for sign, shift in liftedTwiddleNaf:
                aShiftedSlices = shiftAndSliceGoldilocks64Value(input=self.aInValues, shift=shift, inputBitWidth=aBitWidth)
                bOutSlices.extend(processGoldilocks64SlicesValue(slices=aShiftedSlices, limbFactors=limbs64, outerSign=sign))
                bShiftedSlices = shiftAndSliceGoldilocks64Value(input=self.bInValues, shift=shift, inputBitWidth=bBitWidth)
                bOutSlices.extend(processGoldilocks64SlicesValue(slices=bShiftedSlices, limbFactors=limbs64, outerSign=-sign))
            aOut = vectorConst(0, batchSize)
            bOut = vectorConst(0, batchSize)
            for slc, sign in aOutSlices:
                aOut = vectorAdd(aOut, slc) if sign == 1 else vectorSub(aOut, slc)
            for slc, sign in bOutSlices:
                bOut = vectorAdd(bOut, slc) if sign == 1 else vectorSub(bOut, slc)
            return aOut, bOut

        else:
            raise ValueError(f'Unsupported butterfly type {self.butterflyType} for GoldilocksSlice64 scheme')


    def areaCost(self) -> tuple[int, int]:
        pass


    def emitRtl(self,
                name: str,
                run_dir,
                pipeline_stages: int = 1,
                gen_testbench: bool = True,
                test_size: int = 1000,
                seed: int | None = None,
                visualization: bool = False,
                sanity_check_size: int = 8,
                backend: str = 'hw') -> dict:
        '''Emit RTL for this butterfly scheme. Precondition: self.aIn / self.bIn
        are IntType bounds and self.twiddle is set (i.e., the scheme is fully
        populated for spec extraction).

        When gen_testbench=True, the method samples `test_size` random inputs
        over the whole register each input port declares -- not the modelled
        interval; the spec carries only widths and signedness, and this is
        deliberate (see `OperatorScheme.sampleRegisterRange`) -- runs
        propagateValue end-to-end via a fresh clone of this scheme to compute
        goldens, then dispatches to the chosen backend generator with cwd
        inside `run_dir`. A local sanity
        check round-trips the first `sanity_check_size` testvector lines
        through propagateValue to catch twos-complement encoding bugs before
        any remote sim. Returns the metadata dict from the generator.

        `backend` selects the RTL flavor:
          - 'hw'  (default): the optimized Versal compressor-tree generator
            (`rtl_gen.butterfly.Butterfly_RTL_gen`). Files land in
            `<run_dir>/RTL_generated/`, `<run_dir>/xdc_generated/`,
            `<run_dir>/testvectors/` (when gen_testbench),
            `<run_dir>/bitheap_visualization/` (when visualization).
          - 'sim': the behavioral simulation-only generator
            (`sim_rtl_gen.butterfly.Butterfly_SimRTL_gen`). Same testvectors,
            same testbench convention; the SV body is a `+/-` sum of
            signed-shifted-sliced terms instead of a compressor tree. No
            `xdc_generated/` and no bit-heap artifacts are written.'''
        import os as _os
        import random as _random
        from pathlib import Path as _Path

        run_dir = _Path(run_dir)
        run_dir.mkdir(parents=True, exist_ok=True)

        spec = self.getOperatorInterface(name=name)

        a_in: list[int] | None = None
        b_in: list[int] | None = None
        a_out: list[int] | None = None
        b_out: list[int] | None = None
        if gen_testbench:
            if seed is not None:
                _random.seed(seed)
            if spec.aInIsSigned:
                a_lo, a_hi = -(1 << (spec.aInBitWidth - 1)), (1 << (spec.aInBitWidth - 1)) - 1
            else:
                a_lo, a_hi = 0, (1 << spec.aInBitWidth) - 1
            if spec.bInIsSigned:
                b_lo, b_hi = -(1 << (spec.bInBitWidth - 1)), (1 << (spec.bInBitWidth - 1)) - 1
            else:
                b_lo, b_hi = 0, (1 << spec.bInBitWidth) - 1
            a_in = [_random.randint(a_lo, a_hi) for _ in range(test_size)]
            b_in = [_random.randint(b_lo, b_hi) for _ in range(test_size)]

            golden = GoldilocksSlice64(name=f'{name}_golden', butterflyType=self.butterflyType)
            golden.aIn = (IntType.signed(spec.aInBitWidth) if spec.aInIsSigned
                          else IntType.unsigned(spec.aInBitWidth))
            golden.bIn = (IntType.signed(spec.bInBitWidth) if spec.bInIsSigned
                          else IntType.unsigned(spec.bInBitWidth))
            golden.aInValues = a_in
            golden.bInValues = b_in
            golden.twiddle = spec.liftedTwiddleNaf
            a_out, b_out = golden.propagateValue()

        if backend == 'sim':
            from sim_rtl_gen.butterfly import Butterfly_SimRTL_gen as _gen
        elif backend == 'hw':
            from rtl_gen.butterfly import Butterfly_RTL_gen as _gen
        else:
            raise ValueError(f"backend must be 'hw' or 'sim', got {backend!r}")

        saved = _os.getcwd()
        _os.chdir(str(run_dir))
        try:
            meta = _gen(
                spec=spec,
                pipeline_stages=pipeline_stages,
                gen_testbench=gen_testbench,
                visualization=visualization,
                aIn=a_in, bIn=b_in, aOut=a_out, bOut=b_out,
                target_fmax_mhz=self.targetFmaxMhz,
            )
        finally:
            _os.chdir(saved)
        if meta['pipeline_latency'] != self.latency(pipeline_stages):
            raise AssertionError(
                f'{self.name}: the generator built {meta["pipeline_latency"]} stage(s) '
                f'but the model reports {self.latency(pipeline_stages)}'
            )

        if gen_testbench and sanity_check_size > 0:
            _sanityCheckButterflyTestvectors(run_dir, spec, sanity_check_size)

        return meta


def _sanityCheckButterflyTestvectors(run_dir, spec, sample_size: int = 8) -> None:
    '''Read the first `sample_size` lines of each testvector file, decode
    aIn/bIn back to signed Python ints, re-run propagateValue, and confirm the
    aOut/bOut hex bytes match what's on disk. Catches twos-complement encoding
    bugs locally before any remote sim. Mirrors the original
    `scripts/build_butterfly.py::sanity_check_testvectors`.'''
    from pathlib import Path as _Path
    tv = _Path(run_dir) / 'testvectors'

    def _readHex(path, n):
        with path.open() as f:
            return [int(line.strip(), 16) for _, line in zip(range(n), f) if line.strip()]

    aInHex  = _readHex(tv / 'aIn.txt',  sample_size)
    bInHex  = _readHex(tv / 'bIn.txt',  sample_size)
    aOutHex = _readHex(tv / 'aOut.txt', sample_size)
    bOutHex = _readHex(tv / 'bOut.txt', sample_size)
    n = min(len(aInHex), len(bInHex), len(aOutHex), len(bOutHex))
    if n == 0:
        raise RuntimeError('emitRtl sanity-check: no testvectors loaded from disk')

    aBw, bBw = spec.aInBitWidth, spec.bInBitWidth
    aSign, bSign = spec.aInIsSigned, spec.bInIsSigned
    aInDec = [(x - (1 << aBw)) if aSign and (x >> (aBw - 1)) else x for x in aInHex[:n]]
    bInDec = [(x - (1 << bBw)) if bSign and (x >> (bBw - 1)) else x for x in bInHex[:n]]

    sv = GoldilocksSlice64(name='sanity', butterflyType=spec.butterflyType)
    sv.aIn = (IntType.signed(spec.aInBitWidth) if spec.aInIsSigned
              else IntType.unsigned(spec.aInBitWidth))
    sv.bIn = (IntType.signed(spec.bInBitWidth) if spec.bInIsSigned
              else IntType.unsigned(spec.bInBitWidth))
    sv.aInValues = aInDec
    sv.bInValues = bInDec
    sv.twiddle = spec.liftedTwiddleNaf
    # Redundant on purpose. `_inputBitWidths()` derives the slicing width from
    # sv.aIn/sv.bIn and raises if a legacy *BitWidth disagrees, so setting both
    # here turns every emitRtl into a live cross-check that the two sources of
    # the register width still agree.
    sv.aInBitWidth = spec.aInBitWidth
    sv.bInBitWidth = spec.bInBitWidth
    aOutPv, bOutPv = sv.propagateValue()
    aOutExpected = [v & ((1 << spec.aOutBitWidth) - 1) for v in aOutPv]
    bOutExpected = [v & ((1 << spec.bOutBitWidth) - 1) for v in bOutPv]

    aMatch = sum(x == y for x, y in zip(aOutHex[:n], aOutExpected))
    bMatch = sum(x == y for x, y in zip(bOutHex[:n], bOutExpected))
    if aMatch != n or bMatch != n:
        raise RuntimeError(
            f'emitRtl sanity-check FAILED: aOut {aMatch}/{n}, bOut {bMatch}/{n}. '
            f'On-disk hex does not match propagateValue — likely a twos-complement '
            f'encoding bug.'
        )
    print(f'[emitRtl] sanity-check OK: aOut {aMatch}/{n}, bOut {bMatch}/{n}')


# =============================================================================
# ModularBU: the butterfly for any modulus, from the modular operators
# =============================================================================

class ModularBU(ButterflyScheme):
    '''The butterfly unit for any modulus and any modular multiplier.

    A `ModularButterflyScheme` (one modular multiplier and a modular adder and
    subtractor in one datapath) behind the butterfly's ports, for:

      multiplierKind  'reduction' (a product, then `reduction=`: Barrett,
                      Montgomery, word-level Montgomery, K-RED, Mersenne /
                      Solinas / fold, table, custom) or 'shoup'
      the modulus     `q=` (fixed) or `family=` (a run-time `ModulusFamily`:
                      the multiplier's modulus ports Q / MU / QP / QH / K / C
                      become this butterfly's inputs)
      the twiddle     a design-time constant (`twiddle=` an int, fixed q) or
                      inputs (`twiddleInput=True`, always with a run-time q):
                      `W`, plus `WP = floor(W * 2^beta / q)` for Shoup
      butterflyType   'CT' or 'GS'

    Ports: `A`, `B` (`aIn` / `bIn` bounds), then `portNames()` -- the twiddle
    and modulus inputs -- whose bounds default to the multiplier's and may be
    set in `portBounds`, with value batches in `portValues`; outputs `X`, `Y`.
    The `Butterfly` operator gives each of them a port. A twiddle of 1 costs no
    multiplier. Goldilocks has its own butterfly, `GoldilocksSlice64`.

        grid = FullyPipelinedGrid(name, n, q, 'CT', twiddles,
                                  butterflySchemeFactory=ModularBU.factory(q, 'CT', reduction=...))
    '''

    def __init__(self, name: str = 'Undefined ModularBU', butterflyType: str = 'CT', q: int = 0,
                 family=None, multiplierKind: str = 'reduction',
                 reduction=BarrettReduction, reductionArgs: dict | None = None,
                 multiplier: str = 'dsp', dspBudget: int | None = None, constBackend: str = 'lut',
                 qBackend: str | None = None, qDspBudget: int | None = None, beta: int | None = None,
                 productRange='exact', outputRange='exact', absorbFactor: bool = True,
                 twiddleInput: bool | None = None, staticModulus: bool = False, inRange=None,
                 targetFmaxMhz: float | None = None, differenceRange=None,
                 aIn: IntType = IntType(0, 0, 0), bIn: IntType = IntType(0, 0, 0), twiddle=IntType(0, 0, 0)):
        super().__init__(name, aIn, bIn, twiddle)
        if butterflyType not in ('CT', 'GS'):
            raise ValueError(f'{name}: butterflyType must be CT or GS')
        runtime = family is not None and family.runtime
        if (q >= 3) == runtime:
            raise ValueError(f'{name}: give a fixed q >= 3 or a run-time family=, one of them')
        self.q = q if not runtime else 0
        self.family = family if runtime else None
        # a run-time q takes the twiddle as an input, except a constant 1 (the same for every q)
        self.twiddleInput = runtime if twiddleInput is None else bool(twiddleInput)
        self.butterflyType = butterflyType
        self.multiplierKind = multiplierKind
        self.reduction = reduction
        self.reductionArgs = dict(reductionArgs or {})
        self.multiplier = multiplier
        self.dspBudget = dspBudget
        self.constBackend = constBackend
        self.qBackend, self.qDspBudget, self.beta = qBackend, qDspBudget, beta
        self.productRange = productRange
        self.outputRange = outputRange
        self.absorbFactor = absorbFactor
        self.staticModulus = staticModulus
        self.inRange = inRange
        self.targetFmaxMhz = targetFmaxMhz
        self.differenceRange = differenceRange       # GS: range of A - B before the multiplier
        #: bounds and value batches of the inputs beyond A and B (W, WP, Q, MU, ...)
        self.portBounds: dict = {}
        self.portValues: dict = {}
        self._cache = None

    @classmethod
    def factory(cls, q: int, butterflyType: str, prefix: str = 'bu', **kwargs):
        '''A `butterflySchemeFactory(layer, position)` building one per butterfly.'''
        return lambda s, p: cls(name=f'{prefix}_L{s}_p{p}', butterflyType=butterflyType, q=q, **kwargs)

    # --- the modular butterfly for the current bounds and twiddle --------------

    def qMax(self) -> int:
        return self.family.qMax if self.family is not None else self.q

    def _twiddleInt(self) -> int | None:
        if self.twiddleInput:
            return None
        w = self.twiddle
        if self.family is not None:
            if w != 1:
                raise ValueError(f'{self.name}: at run-time q the only constant twiddle is 1 (twiddleInput=True otherwise)')
            return 1
        if not isinstance(w, int) or isinstance(w, bool):
            raise TypeError(f'{self.name}: a constant twiddle must be an int in [1, q), got {type(w).__name__} '
                            f'(a NAF lift is the Goldilocks butterfly\'s form; twiddleInput=True for a W port)')
        w %= self.q
        if w == 0:
            raise ValueError(f'{self.name}: a twiddle of 0 is not a root of unity')
        return w

    def _build(self, aIn: IntType, bIn: IntType) -> ModularButterflyScheme:
        mod = dict(family=self.family, staticModulus=self.staticModulus) if self.family is not None else dict(q=self.q)
        return ModularButterflyScheme(
            name=self.name, butterflyType=self.butterflyType, aIn=aIn, bIn=bIn,
            wIn=self.portBounds.get('W'), constant=self._twiddleInt(),
            multiplierKind=self.multiplierKind, multiplier=self.multiplier, dspBudget=self.dspBudget,
            constBackend=self.constBackend, reduction=self.reduction, reductionArgs=self.reductionArgs,
            beta=self.beta, productRange=self.productRange, outputRange=self.outputRange,
            absorbFactor=self.absorbFactor, targetFmaxMhz=self.targetFmaxMhz, qBackend=self.qBackend,
            qDspBudget=self.qDspBudget, inRange=self.inRange, differenceRange=self.differenceRange, **mod)

    #: per mult node DSP budgets of the datapath, {node name: budget} (`core/dspbudget.py`)
    dspBudgets = None

    def inner(self) -> ModularButterflyScheme:
        '''The `ModularButterflyScheme` for the bounds on the ports now (cached).'''
        for label, b in (('aIn', self.aIn), ('bIn', self.bIn)):
            if not isinstance(b, IntType) or b.isZero:
                raise ValueError(f'{self.name}: set {label} (a bound) before using the butterfly')
        key = (self.aIn.minValue, self.aIn.maxValue, self.aIn.zeroLsbs,
               self.bIn.minValue, self.bIn.maxValue, self.bIn.zeroLsbs, self._twiddleInt(),
               self.targetFmaxMhz, tuple(sorted((k, v.minValue, v.maxValue) for k, v in self.portBounds.items())),
               tuple(sorted((self.dspBudgets or {}).items())))
        if self._cache is None or self._cache[0] != key:
            sch = self._build(self.aIn, self.bIn)
            sch.dspBudgets = dict(self.dspBudgets) if self.dspBudgets else None
            for p, bnd in self.portBounds.items():
                if p not in sch.inputNames:
                    raise ValueError(f'{self.name}: no input {p}; the inputs are {list(sch.inputNames)}')
                if p != 'W':
                    setattr(sch, sch._boundAttr(p), bnd)
            self._cache = (key, sch)
        return self._cache[1]

    def portNames(self) -> tuple[str, ...]:
        '''The inputs beyond A and B, in port order: the twiddle (W, WP) and the
        modulus ports. Known before any bound is set.'''
        try:
            names = self.inner().inputNames
        except ValueError:
            full = IntType(0, self.qMax() - 1)
            names = self._build(full, full).inputNames
        return tuple(p for p in names if p not in ('A', 'B'))

    def defaultPortBound(self, port: str) -> IntType:
        '''What the multiplier declares for `port` (W in [0, q), WP its companion's range, Q the family's ...).'''
        full = IntType(0, self.qMax() - 1)
        sch = self._build(full, full)
        return getattr(sch, sch._boundAttr(port))

    def companion(self, w: int, q: int | None = None) -> int:
        '''Shoup's `WP` for twiddle `w`.'''
        sch = self.inner() if isinstance(self.aIn, IntType) and not self.aIn.isZero else \
            self._build(IntType(0, self.qMax() - 1), IntType(0, self.qMax() - 1))
        return sch._portChild.companion(w, q if q is not None else self.q)

    def qPortValues(self, q: int) -> dict:
        '''The modulus inputs for one q of the family (Q, MU, QP, QH, K, C as the multiplier needs).'''
        return self.inner().qPortValues(q)

    # --- bound and value paths -------------------------------------------------

    def propagateBound(self) -> tuple[IntType, IntType]:
        super().propagateBound()
        return self.inner().propagateBound()

    def _inputs(self) -> dict:
        if self.aInValues is None or self.bInValues is None:
            raise ValueError(f'{self.name}: aInValues / bInValues are not set')
        ins = {'A': list(self.aInValues), 'B': list(self.bInValues)}
        for p in self.portNames():
            if p not in self.portValues:
                raise ValueError(f'{self.name}: no values for input {p} (portValues)')
            ins[p] = list(self.portValues[p])
        return ins

    def propagateValue(self) -> tuple[list[int], list[int]]:
        res = self.inner().datapath().run(self._inputs())
        return res['X'], res['Y']

    def checkReference(self) -> list[str]:
        '''The value path against the big-integer reference, trial by trial.'''
        return self.inner().checkReference(self._inputs())

    # --- timing and cost -------------------------------------------------------

    def latency(self, pipelineStages: int = 1) -> int:
        if pipelineStages < 0:
            raise ValueError(f'{self.name}: pipelineStages must be >= 0, got {pipelineStages}')
        return self.inner().latency(pipelineStages)

    def stagePlan(self, pipelineStages: int = 1):
        '''What `FullyPipelinedNTT.reset` reads: both outputs leave the datapath
        at its latency (the datapath balances them itself).'''
        lat = self.latency(pipelineStages)
        ns = self.criticalPathNs(pipelineStages)
        out = SimpleNamespace(stages=lat, worst_ns=ns)
        return SimpleNamespace(latency=lat, aOut=out, bOut=out)

    def criticalPathNs(self, pipelineStages: int = 1) -> float:
        return self.inner().criticalPathNs(pipelineStages)

    def achievedFmaxMhz(self, pipelineStages: int = 1) -> float:
        return self.inner().achievedFmaxMhz(pipelineStages)

    def areaCost(self) -> tuple[int, int]:
        return self.inner().areaCost()

    def resources(self, pipelineStages: int = 1):
        return self.inner().resources(pipelineStages)

    def flipFlops(self, pipelineStages: int = 1) -> int:
        return self.inner().flipFlops(pipelineStages)

    # --- RTL -------------------------------------------------------------------

    def getOperatorInterface(self, name: str, pipelineStages: int = 1):
        '''A `DatapathButterflySpec`: the datapath scheduled for `pipelineStages`
        (or the target), emitted as `<name>_dp` under the NTT's butterfly ports.'''
        inner = self.inner()
        dpSpec = inner.getOperatorInterface(f'{name}_dp', pipelineStages)
        x, y = inner.propagateBound()
        extra = tuple((w.name, w.bitWidth) for w in dpSpec.inputs if w.name not in ('A', 'B'))
        return DatapathButterflySpec(
            name=name, butterflyType=self.butterflyType, q=self.q,
            aInBitWidth=self.aIn.bitWidth, aInIsSigned=self.aIn.isSigned,
            bInBitWidth=self.bIn.bitWidth, bInIsSigned=self.bIn.isSigned,
            aOutBitWidth=x.bitWidth, aOutIsSigned=x.isSigned,
            bOutBitWidth=y.bitWidth, bOutIsSigned=y.isSigned,
            datapath=dpSpec, extraPorts=extra)

    def submodules(self, spec, subDir) -> dict:
        '''Generate the dsp / booth multiplier modules `spec.datapath` needs.'''
        from ...core.DatapathOperator import datapathSubmodules
        return datapathSubmodules(self.inner(), spec.datapath, subDir)

    def emitRtl(self, name: str, run_dir, pipeline_stages: int = 1, gen_testbench: bool = True,
                test_size: int = 1000, seed: int | None = None, sanity_check_size: int = 8,
                backend: str = 'hw', **_unused) -> dict:
        '''Emit RTL for this one butterfly, as `GoldilocksSlice64.emitRtl` does:
        `<run_dir>/RTL_generated/<name>.sv` (ports `aIn`, `bIn`, then the twiddle
        and modulus inputs under their own names, `aOut`, `bOut`), `<name>_dp.sv`
        and its parts, a self-checking `<name>_tb.sv` and one test-vector file
        per port. Trials are drawn as the scheme samples them: inside the
        bounds, corners first, with a run-time q one modulus per trial (or per
        batch with `staticModulus`) and its port values, the twiddle below that
        q and Shoup's companion from it. Goldens from `propagateValue`, checked
        against the reference mod q. Precondition: `aIn`, `bIn` set, and
        `twiddle` for a constant twiddle.'''
        import os as _os
        import random as _random
        from pathlib import Path as _Path
        if backend != 'hw':
            raise ValueError(f"{self.name}: a datapath butterfly has the hw backend only, got {backend!r}")
        run_dir = _Path(run_dir)
        run_dir.mkdir(parents=True, exist_ok=True)
        spec = self.getOperatorInterface(name, pipeline_stages)
        spec = _dataclasses.replace(spec, submodules=self.submodules(spec, run_dir / '_sub'))
        a_in = b_in = a_out = b_out = None
        ports = None
        if gen_testbench:
            rng = _random.Random(seed)
            ins = self.inner().sampleInputs(test_size, rng)
            a_in, b_in = ins['A'], ins['B']
            ports = {p: ins[p] for p in self.portNames()}
            errors = self.inner().checkReference(ins)
            if errors:
                raise AssertionError(f'{self.name}: model disagrees with the reference: {errors[:3]}')
            self.aInValues, self.bInValues, self.portValues = a_in, b_in, dict(ports)
            a_out, b_out = self.propagateValue()
        from rtl_gen.butterfly import Butterfly_RTL_gen
        saved = _os.getcwd()
        _os.chdir(str(run_dir))
        try:
            meta = Butterfly_RTL_gen(spec=spec, gen_testbench=gen_testbench,
                                     aIn=a_in, bIn=b_in, aOut=a_out, bOut=b_out, ports=ports)
        finally:
            _os.chdir(saved)
        if meta['pipeline_latency'] != self.latency(pipeline_stages):
            raise AssertionError(f'{self.name}: the generator built {meta["pipeline_latency"]} stage(s) '
                                 f'but the model reports {self.latency(pipeline_stages)}')
        if gen_testbench and sanity_check_size > 0:
            _sanityCheckDatapathButterfly(self, run_dir, spec, sanity_check_size)
        return meta


def _sanityCheckDatapathButterfly(bu: 'ModularBU', run_dir, spec, sample_size: int = 8) -> None:
    '''Decode the first test vectors from disk, rerun them through the
    butterfly's value path and compare: catches an encoding slip before any
    simulator. (The datapath's inputs are within their bounds, so unsigned.)'''
    from pathlib import Path as _Path
    tv = _Path(run_dir) / 'testvectors'
    read = lambda f: [int(l, 16) for l in (tv / f).read_text().split()[:sample_size]]
    a, b, x, y = read('aIn.txt'), read('bIn.txt'), read('aOut.txt'), read('bOut.txt')
    ins = {'A': a, 'B': b}
    ins.update({p: read(f'{p}.txt') for p, _ in spec.extraPorts})
    res = bu.inner().datapath().run(ins)
    mx = [v & ((1 << spec.aOutBitWidth) - 1) for v in res['X']]
    my = [v & ((1 << spec.bOutBitWidth) - 1) for v in res['Y']]
    if mx != x or my != y:
        raise RuntimeError(f'{bu.name}: emitRtl sanity check FAILED: on-disk vectors differ from the value path')
    print(f'[emitRtl] sanity-check OK: aOut {len(x)}/{len(x)}, bOut {len(y)}/{len(y)}')
