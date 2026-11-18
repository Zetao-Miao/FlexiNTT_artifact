'''General multipliers built only from LUTs — the family where the *model*
chooses the structure.

Several implementations are planned — tiling, Karatsuba, schoolbook, plus the
existing radix-4 Booth multiplier as an opaque primitive. They differ in exactly
one way: how the multiplication is broken into smaller multiplications. So that
is the only thing a subclass writes.

    class MyStrategy(LutMultiplierScheme):
        def _buildDecomposition(self):
            ...
            return operandWires, subMults, recombinationTerms

Everything else — value propagation, spec extraction, area, latency, `emitRtl` —
is concrete here. A *decomposition* overrides nothing beyond
`_buildDecomposition`; a **leaf** with its own scalar generator does, and
`BoothMult` overrides `_leafAreaCost` and `emitRtl` for exactly that reason. A
new decomposition strategy is one method, in the region of 40 to 70 lines.

`_buildDecomposition` returns three things:

  `operandWires`    `list[WireDef]`, topologically ordered: the operands of the
                    sub-multiplications, each a signed sum of shifted slices of
                    the inputs or of earlier wires.
  `subMults`        `list[(productName, opAWireName, opBWireName, childScheme)]`.
  `recombination`   `list[SliceTerm]` over the product names, giving the output.

A leaf — a multiplier with no internal structure, such as `BoothMult` — returns
`([], [], [])` and is handed to a primitive generator whole.

Why operands are expressions rather than bit ranges
---------------------------------------------------
Karatsuba's middle product is `(A1 + A0) * (B1 + B0)`, so an operand cannot be
just "a slice of A". Representing it as a `SliceTerm` list handles that, and
gets the width right where a hand-written formula does not: splitting a signed
24-bit `A` at bit 12 yields a *signed* 12-bit high half and an *unsigned* 12-bit
low half, so `A1 + A0` spans `[-2048, 6142]` and needs 14 bits rather than the
13 one might expect. `IntType` produces that with no special-casing, which is
what makes the framework able to absorb strategies it was not designed around.

Where this family stops
-----------------------
`rtl_gen/mult.py` — the consumer for a `MultOperatorSpec` describing anything
above a flat leaf — **does not exist**. `BoothMult` emits, because it has its own
scalar generator. A decomposed node models, costs and self-checks, and raises on
`emitRtl`. That is the honest state, not a placeholder to be filled in silently.

The DSP58 family is deliberately *not* under this class. See
`MultiplierScheme`'s docstring for why the two cannot share a base wider than
bounds and values.
'''
from __future__ import annotations

import random as _random
from abc import abstractmethod
from typing import Callable

from ..core.IntType import IntType
from ..core.OperatorScheme import OperatorScheme, runInDir, sampleBound
from ..core.terms import sumTermsBound, sumTermsValue
from .MultiplierScheme import MultiplierScheme, physicalWidthFor

from butterfly_spec import SliceTerm                              # noqa: E402
from mult_spec import MultOperatorSpec, SubMultRef, WireDef       # noqa: E402

#: Smallest operand the radix-4 Booth generator accepts (`booth_mult.py`).
BOOTH_MIN_WIDTH = 6


def wireFromTerms(name: str, terms: list[SliceTerm],
                  env: dict[str, IntType],
                  requireSigned: bool = False) -> tuple[WireDef, IntType]:
    '''Build a `WireDef` from its terms, sizing it by propagating the bound.

    Returns the definition and the `IntType` it carries, so the caller can put
    the latter straight into the environment for wires defined after it.
    '''
    bound = sumTermsBound(terms, env)
    return WireDef(
        name=name,
        terms=terms,
        bitWidth=physicalWidthFor(bound, requireSigned),
        isSigned=bound.isSigned or requireSigned,
        minValue=bound.minValue,
        maxValue=bound.maxValue,
        zeroLsbs=bound.zeroLsbs,
    ), bound


def sliceTerm(source: str, bound: IntType, start: int, end: int,
              shift: int = 0, sign: int = 1) -> SliceTerm:
    '''Term taking bits `start..end` of `source`, weighted `sign * 2**shift`.

    `isSigned` is **derived** from `bound.slice(start, end)` rather than passed
    in, because getting it wrong is both easy and silent. Splitting a signed
    value in half is the trap: the high slice reaches the top of the value so
    `IntType.slice` keeps its sign, while the low slice is an interior window
    and comes back unsigned. A strategy author should not have to remember that,
    and with this helper they do not.
    '''
    return SliceTerm(source=source, inputShift=0, sliceStart=start,
                     sliceEnd=end, isSigned=bound.slice(start, end).isSigned,
                     limbShift=shift, sign=sign, constValue=0)


def wholeTerm(source: str, bound: IntType, shift: int = 0,
              sign: int = 1) -> SliceTerm:
    '''Term taking all of `source` — used to recombine sub-products.'''
    return sliceTerm(source, bound, 0, max(bound.bitWidth - 1, 0), shift, sign)


class LutMultiplierScheme(MultiplierScheme):
    '''`P = A * B` in LUTs. Subclasses implement `_buildDecomposition` and nothing else.'''

    family = 'lut'

    #: 'leaf' | 'tiling' | 'karatsuba' | 'schoolbook'
    decomposition: str = 'leaf'
    #: Non-empty only for leaves; names the primitive generator.
    leafKind: str = ''

    def __init__(self, *args,
                 leafFactory: Callable[..., 'LutMultiplierScheme'] | None = None,
                 maxDepth: int = 8,
                 targetFmaxMhz: float | None = None,
                 **kwargs):
        super().__init__(*args, **kwargs)
        # Reserved for the decomposition strategies. Nothing reads either yet:
        # `BoothMult` is the only subclass and it is a leaf, so there is no
        # recursion to bound and no leaf to manufacture. `_buildDecomposition`
        # is where they come into use.
        # Reserved for the decomposition strategies. Nothing reads either yet:
        # `BoothMult` is the only subclass and it is a leaf, so there is no
        # recursion to bound and no leaf to manufacture.
        self.leafFactory = leafFactory or defaultLeafFactory
        self.maxDepth = maxDepth
        #: Frequency in, cycles out. When set, `pipelineStages()` returns the
        #: fewest stages of this node's own hardware that reach it, and
        #: `latency()` / `emitRtl()` use that instead of the count they were
        #: handed. A decomposition passes it to the leaves it makes
        #: (`leafFactory(..., targetFmaxMhz=self.targetFmaxMhz)`).
        self.targetFmaxMhz = targetFmaxMhz

    # ------------------------------------------------------------------
    # The single extension point
    # ------------------------------------------------------------------

    @abstractmethod
    def _buildDecomposition(self) -> tuple[
            list[WireDef],
            list[tuple[str, str, str, 'LutMultiplierScheme']],
            list[SliceTerm]]:
        '''`(operandWires, subMults, recombinationTerms)`; `([], [], [])` for a leaf.'''

    def isLeaf(self) -> bool:
        _, subMults, _ = self._buildDecomposition()
        return not subMults

    # ------------------------------------------------------------------
    # Concrete: the value path walks the decomposition
    # ------------------------------------------------------------------

    def propagateValue(self) -> list[int]:
        '''Output batch, evaluated **through the decomposition**.

        The base class multiplies directly, which is exact but proves nothing.
        Routing the batch through the operand wires and the children instead is
        what gives `selfCheck` something to check: a sign or shift mistake in a
        recombination shows up as a wrong product, recursively, so a Karatsuba
        over Booth leaves exercises every level.
        '''
        wires, subMults, recombination = self._buildDecomposition()
        if not subMults:
            return super().propagateValue()

        # The leaf path above validates inside `MultiplierScheme.propagateValue`.
        # The decomposed path never reaches it, so run the same check directly —
        # skipping it is how an `IntType` gets into the value path silently.
        OperatorScheme.propagateValue(self)
        batch = len(self.aInValues)
        env: dict[str, list[int]] = {
            self.aPortName: self.aInValues,
            self.bPortName: self.bInValues,
        }
        for wire in wires:
            env[wire.name] = sumTermsValue(wire.terms, env, batch)
        for productName, opA, opB, child in subMults:
            child.aInValues = env[opA]
            child.bInValues = env[opB]
            env[productName] = child.propagateValue()
        return sumTermsValue(recombination, env, batch)

    def selfCheck(self, testSize: int = 256, seed: int | None = None) -> None:
        """Assert the decomposition actually computes `A * B`.

        Free validation for any new strategy: sign and shift mistakes in a
        recombination show up here, before a spec is extracted or a line of RTL
        is emitted.

        A **leaf** is refused rather than checked. Its `propagateValue` is the
        inherited exact product, so the comparison would be `a * b` against
        `a * b` — a pass that establishes nothing. What checks a leaf is the
        generator's own testbench.
        """
        if self.isLeaf():
            super().selfCheck(testSize=testSize, seed=seed)   # raises, with why

        rng = _random.Random(seed) if seed is not None else _random
        savedA, savedB = self.aInValues, self.bInValues
        try:
            self.aInValues = sampleBound(self.aIn, testSize, rng)
            self.bInValues = sampleBound(self.bIn, testSize, rng)
            got = self.propagateValue()
            want = [a * b for a, b in zip(self.aInValues, self.bInValues)]
            for i, (g, w) in enumerate(zip(got, want)):
                if g != w:
                    raise AssertionError(
                        f'{self.name} ({self.decomposition}): decomposition '
                        f'computes {g} for A={self.aInValues[i]}, '
                        f'B={self.bInValues[i]}, expected {w}'
                    )
        finally:
            self.aInValues, self.bInValues = savedA, savedB

    # ------------------------------------------------------------------
    # Concrete: pipelining, latency and area
    # ------------------------------------------------------------------

    def units(self) -> tuple:
        '''The register boundaries of this node's own hardware, as
        `lut_timing.Unit`s: a leaf's whole datapath, or a decomposed node's
        recombination heap (the children have their own). Every stage count
        and every predicted delay below comes from this table, which is the
        one the generators place registers with.'''
        _, subMults, recombination = self._buildDecomposition()
        if not subMults:
            return self._leafUnits()
        if not recombination:
            return ()
        from rtl_gen.heap_terms import buildHeapDescriptors
        from lut_timing import heap_units

        outWidth = self.propagateBound().bitWidth
        _, _, bitheapList, _ = buildHeapDescriptors(recombination, outWidth, '')
        return heap_units(bitheapList) if bitheapList else ()

    def _leafUnits(self) -> tuple:
        raise NotImplementedError(
            f'{type(self).__name__} is a leaf but does not implement _leafUnits'
        )

    def pipelineStages(self, requested: int = 1) -> int:
        '''Stages this node's own hardware takes: `requested`, or with
        `targetFmaxMhz` the fewest that reach the target. Raises when no stage
        count does, naming the unit that sets the floor.'''
        if requested < 0:
            raise ValueError(f'{self.name}: pipelineStages must be >= 0, got {requested}')
        units = self.units()
        if not units:
            return 0
        if self.targetFmaxMhz is None:
            return requested
        from lut_timing import stages_for_fmax
        return stages_for_fmax(units, self.targetFmaxMhz, label=self.name)

    def registerFlags(self, pipelineStages: int = 1) -> list[bool]:
        '''Where this node's own registers sit, one flag per unit -- the
        placement the generator builds.'''
        from lut_timing import place_registers, weights
        units = self.units()
        if not units:
            return []
        return place_registers(weights(units), self.pipelineStages(pipelineStages))

    def latency(self, pipelineStages: int = 1) -> int:
        '''Children run in parallel, so a node costs its deepest child plus its
        own registers -- as many as its units absorb of the request, never
        more, which is what the generator builds.'''
        own = sum(self.registerFlags(pipelineStages))
        _, subMults, _ = self._buildDecomposition()
        if not subMults:
            return own
        return own + max(child.latency(pipelineStages) for _, _, _, child in subMults)

    def criticalPathNs(self, pipelineStages: int = 1) -> float:
        '''Predicted slowest register-to-register segment, this node and its
        children, clock uncertainty excluded.'''
        from lut_timing import segment_ns, weights
        units = self.units()
        own = segment_ns(weights(units), self.registerFlags(pipelineStages)) if units else 0.0
        _, subMults, _ = self._buildDecomposition()
        return max([own] + [child.criticalPathNs(pipelineStages) for _, _, _, child in subMults])

    def achievedFmaxMhz(self, pipelineStages: int = 1) -> float:
        '''MHz of `criticalPathNs`, clock uncertainty included -- the scale a
        `targetFmaxMhz` is judged on.'''
        from lut_timing import fmax_of
        return fmax_of(self.criticalPathNs(pipelineStages))

    def areaCost(self) -> tuple[int, int]:
        '''Own recombination heap plus the children, de-duplicated. `(LUT, 0)`.

        Children are keyed by operand width pair, matching how the generator
        emits one module per distinct `(wa, wb)` and instantiates it repeatedly —
        counting a shared `Bmult16x16` four times would badly overstate a
        four-tile design.

        The heap is priced by `dsp_multiplier.common.lut_cost`, the same engine
        the DSP58 search prices its own merge heaps with. Two cost models for
        one piece of hardware is how a LUT-vs-DSP comparison goes quietly wrong,
        so this family and that one share an oracle.
        '''
        _, subMults, recombination = self._buildDecomposition()
        if not subMults:
            return self._leafAreaCost()

        seen: dict[tuple[int, int], tuple[int, int]] = {}
        for _, _, _, child in subMults:
            key = (child.aIn.bitWidth, child.bIn.bitWidth)
            if key not in seen:
                seen[key] = child.areaCost()
        lut = sum(c[0] for c in seen.values())
        dsp = sum(c[1] for c in seen.values())

        if recombination:
            from rtl_gen.heap_terms import buildHeapDescriptors
            from dsp_multiplier.common.lut_cost import estimate_cmp_luts

            outWidth = self.propagateBound().bitWidth
            _, _, bitheapList, _ = buildHeapDescriptors(
                recombination, outWidth, '')
            if bitheapList:
                lut += estimate_cmp_luts(bitheapList).total
        return lut, dsp

    def _leafAreaCost(self) -> tuple[int, int]:
        raise NotImplementedError(
            f'{type(self).__name__} is a leaf but does not implement '
            f'_leafAreaCost'
        )

    # ------------------------------------------------------------------
    # Concrete: spec extraction
    # ------------------------------------------------------------------

    def getOperatorInterface(self, name: str,
                             pipelineStages: int = 1) -> MultOperatorSpec:
        wires, subMults, recombination = self._buildDecomposition()
        outBound = self.propagateBound()

        refs: list[SubMultRef] = []
        childLatencies: list[int] = []
        for productName, opA, opB, child in subMults:
            childLeaf = child.isLeaf()
            childLatencies.append(child.latency(pipelineStages))
            refs.append(SubMultRef(
                name=productName,
                opAWire=opA,
                opBWire=opB,
                leafKind=child.leafKind if childLeaf else '',
                childSpec=(None if childLeaf
                           else child.getOperatorInterface(
                               f'{name}_{productName}', pipelineStages)),
                outBitWidth=child.propagateBound().bitWidth,
                outIsSigned=child.propagateBound().isSigned,
                latency=childLatencies[-1],
            ))

        return MultOperatorSpec(
            name=name,
            decomposition=self.decomposition,
            leafKind=self.leafKind if not subMults else '',
            aPortName=self.aPortName,
            bPortName=self.bPortName,
            outPortName=self.outPortName,
            aInBitWidth=self.aIn.bitWidth,
            aInIsSigned=self.aIn.isSigned,
            bInBitWidth=self.bIn.bitWidth,
            bInIsSigned=self.bIn.isSigned,
            pOutBitWidth=outBound.bitWidth,
            pOutIsSigned=outBound.isSigned,
            pOutMinValue=outBound.minValue,
            pOutMaxValue=outBound.maxValue,
            pOutZeroLsbs=outBound.zeroLsbs,
            operandWires=wires,
            subMults=refs,
            pOutTerms=recombination,
            uniformChildLatency=max(childLatencies) if childLatencies else 0,
            latency=self.latency(pipelineStages),
        )

    def emitRtl(self, name: str, run_dir, **kwargs) -> dict:
        raise NotImplementedError(
            f'{type(self).__name__}.emitRtl: the general-multiplier generator '
            f'(rtl_gen/mult.py) is not implemented yet. Only the modelling '
            f'framework and the BoothMult leaf have landed; see this module\'s '
            f'docstring for where the family stops.'
        )


class BoothMult(LutMultiplierScheme):
    '''Radix-4 Booth multiplier — an opaque leaf around `Bmult_RTL_gen`.

    The generator treats both operands as two's complement unconditionally and
    requires at least 6 bits each, so a parent that feeds it an unsigned operand
    must widen by one bit — `physicalWidthFor(bound, requireSigned=True)`.
    '''

    decomposition = 'leaf'
    leafKind = 'booth'

    def _buildDecomposition(self):
        return [], [], []

    def physicalWidths(self) -> tuple[int, int]:
        '''`(widthA, widthB)` as the Booth generator will see them.'''
        return (physicalWidthFor(self.aIn, requireSigned=True),
                physicalWidthFor(self.bIn, requireSigned=True))

    def checkGeneratorLimits(self) -> None:
        wa, wb = self.physicalWidths()
        if wa < BOOTH_MIN_WIDTH or wb < BOOTH_MIN_WIDTH:
            raise ValueError(
                f'{self.name}: Bmult_RTL_gen needs both operands at least '
                f'{BOOTH_MIN_WIDTH} bits, got {wa}x{wb}. Use a schoolbook leaf '
                f'for operands this small.'
            )

    def _leafUnits(self) -> tuple:
        '''Partial-product generation, each compression layer, the terminal
        adder -- `lut_timing.bmult_units` at the widths the generator sees.'''
        from lut_timing import bmult_units
        return bmult_units(*self.physicalWidths())

    def _leafAreaCost(self) -> tuple[int, int]:
        '''Partial-product generation plus the compressor tree that sums it.

        Priced by `lut_cost.estimate_bmult_luts` — the backend's own model, and
        the one `dspmult` uses for every LUT rectangle it leaves uncovered. This
        class used to carry a second, hand-rolled estimate of the same hardware;
        the two agreed to about 1% across 8..64 bits (the hand-rolled one read
        low), so the unification barely moves a number and removes the way a
        LUT-vs-DSP comparison could have been quietly meaningless.

        Both operands are already widened to two's complement by
        `physicalWidths()`, so `a_signed` / `b_signed` are `True` here by
        construction — `estimate_bmult_luts` must not be asked to widen them a
        second time.
        '''
        from dsp_multiplier.common.lut_cost import estimate_bmult_luts

        wa, wb = self.physicalWidths()
        return estimate_bmult_luts(wa, wb, a_signed=True, b_signed=True).total, 0

    def emitRtl(self, name: str, run_dir,
                pipeline_stages: int = 1,
                gen_testbench: bool = False,
                **kwargs) -> dict:
        '''Emit the Booth multiplier via the existing scalar generator.

        `gen_testbench` defaults to **False**: the generator writes
        `testvectors/{A,B,P}.txt`, which would overwrite a parent multiplier's
        shared testvector directory when this is instantiated as a leaf.
        '''
        self.checkGeneratorLimits()
        wa, wb = self.physicalWidths()
        stages = self.pipelineStages(pipeline_stages)

        def _call():
            from rtl_gen.booth_mult import Bmult_RTL_gen
            return Bmult_RTL_gen(width_a=wa, width_b=wb,
                                 pipeline_stages=stages,
                                 gen_testbenches=gen_testbench,
                                 test_size=kwargs.get('test_size', 1000))

        meta = runInDir(run_dir, _call)
        if meta['pipeline_latency'] != self.latency(pipeline_stages):
            raise AssertionError(
                f'{self.name}: the generator built {meta["pipeline_latency"]} stage(s) '
                f'but the model reports {self.latency(pipeline_stages)}'
            )
        return {
            'module': f'Bmult{wa}x{wb}',
            'leafKind': self.leafKind,
            'aIn_bit_width': wa,
            'bIn_bit_width': wb,
            'pOut_bit_width': wa + wb,
            'pipeline_latency': meta['pipeline_latency'],
            'requested_pipeline_stages': pipeline_stages,
            'target_fmax_mhz': self.targetFmaxMhz,
            'reg_flag_list': meta['reg_flag_list'],
            'predicted_worst_ns': meta['predicted_worst_ns'],
            'predicted_fmax_mhz': meta['predicted_fmax_mhz'],
        }


def defaultLeafFactory(name: str, aIn: IntType, bIn: IntType,
                       **kwargs) -> LutMultiplierScheme:
    '''Pick a leaf for a pair of operand bounds.

    Booth whenever both operands reach its minimum width. Smaller operands have
    no leaf yet — `SchoolbookMult` lands with the decomposition strategies.
    '''
    wa = physicalWidthFor(aIn, requireSigned=True)
    wb = physicalWidthFor(bIn, requireSigned=True)
    if wa >= BOOTH_MIN_WIDTH and wb >= BOOTH_MIN_WIDTH:
        return BoothMult(name=name, aIn=aIn, bIn=bIn, **kwargs)
    raise NotImplementedError(
        f'{name}: operands {wa}x{wb} are below the Booth minimum of '
        f'{BOOTH_MIN_WIDTH} and SchoolbookMult is not implemented yet'
    )
