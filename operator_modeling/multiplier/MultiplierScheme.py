'''What every modelled general multiplier answers, regardless of what it is
built from.

Two implementation families sit under this class, and they differ in a way that
goes deeper than their hardware: **who decides the structure**.

  `LutMultiplierScheme`   the model decides. `_buildDecomposition` names the
                          operand wires, the sub-multiplications and the
                          recombination; a frozen `MultOperatorSpec` carries
                          that down to a generator that builds exactly what it
                          was told.

  `DspMultiplierScheme`   the backend decides. `dspmult`'s frontend is itself a
                          decomposition search — Karatsuba-2/3, grid split,
                          geometric DSP58 tiling, beam search over all of it,
                          priced through a calibrated LUT engine. The model
                          states the problem (widths, signs, DSP budget) and
                          reads the answer back.

That inversion is why this base is thin. An earlier version of this file was the
decomposition framework *and* the base class, which would force a DSP scheme to
implement `_buildDecomposition` — and the only thing it could honestly return is
`([], [], [])`, which declares it a leaf and routes `areaCost` and `latency`
through the leaf hooks, quietly discarding everything the search found. Same
trap as making a four-step NTT an `NTTScheme`: abstract methods that can only
return lies. So the framework lives in `LutMultiplierScheme`, and what is shared
here is only what genuinely is shared:

  - two operand bounds and two operand value batches;
  - `propagateBound` — the exact product interval, for any correct multiplier;
  - `propagateValue` — the exact elementwise product, likewise;
  - the operand-width helper both families size their generator calls with.

`Multiplier`, the operator, types against this class, so one operator hosts
either family.
'''
from __future__ import annotations

import os as _os
import sys as _sys

from ..core.IntType import IntType
from ..core.OperatorScheme import OperatorScheme

_versalArithDir = _os.path.normpath(
    _os.path.join(_os.path.dirname(__file__), '..', '..', 'versal_arith'))
if _versalArithDir not in _sys.path:
    _sys.path.append(_versalArithDir)


def physicalWidthFor(bound: IntType, requireSigned: bool = False) -> int:
    '''Width of the wire that carries `bound`.

    `requireSigned` adds a bit to an unsigned bound so it can be fed to a
    generator that only handles two's-complement operands — the Booth
    multiplier, for instance, treats both operands as signed unconditionally.
    The DSP58 search does **not** need it; see
    `DspMultiplierScheme.operandWidths`.
    '''
    width = bound.bitWidth
    if requireSigned and not bound.isSigned:
        width += 1
    return max(width, 1)


class MultiplierScheme(OperatorScheme):
    '''`P = A * B`: the arithmetic, with no claim about the implementation.'''

    _BOUND_ATTRS = ('aIn', 'bIn')
    _VALUE_ATTRS = ('aInValues', 'bInValues')

    #: Implementation family, for error messages and spec fields.
    #: 'lut' | 'dsp' | 'behavioural'.
    family: str = 'undefined'

    def __init__(self,
                 name: str = 'Undefined MultiplierScheme',
                 aIn: IntType = IntType(0, 0, 0),
                 bIn: IntType = IntType(0, 0, 0),
                 aInValues: list[int] | None = None,
                 bInValues: list[int] | None = None,
                 aPortName: str = 'A',
                 bPortName: str = 'B',
                 outPortName: str = 'P',
                 verbose: bool = False):
        super().__init__(name)
        self.aIn = aIn
        self.bIn = bIn
        self.aInValues = aInValues
        self.bInValues = bInValues
        self.aPortName = aPortName
        self.bPortName = bPortName
        self.outPortName = outPortName
        self.verbose = verbose

    # ------------------------------------------------------------------
    # The two paths, exact for any correct multiplier
    # ------------------------------------------------------------------

    def propagateBound(self) -> IntType:
        '''Exact interval of `A * B`.

        This is the product bound rather than the sum of any recombination's
        terms: a decomposition's sub-products are correlated (Karatsuba's
        `k_hi` appears twice, with opposite signs), so interval arithmetic over
        them over-approximates. The identity guarantees the true value fits the
        product bound, and truncating the heap to it is exact.
        '''
        super().propagateBound()
        return self.aIn * self.bIn

    def propagateValue(self) -> list[int]:
        '''Elementwise `A * B`.

        A correct multiplier computes the product, so this is right for every
        family. `LutMultiplierScheme` overrides it to route the batch through
        the model's own decomposition instead — not because the answer differs,
        but because walking the decomposition is what makes `selfCheck` test
        anything.
        '''
        super().propagateValue()
        return [a * b for a, b in zip(self.aInValues, self.bInValues)]

    # ------------------------------------------------------------------
    # Verification
    # ------------------------------------------------------------------

    def selfCheck(self, testSize: int = 256, seed: int | None = None) -> None:
        '''Refused by default, and that default is the honest one.

        A self-check is only worth running where `propagateValue` walks a
        structure the model built — then a sign or shift mistake in a
        recombination shows up here, before a spec is extracted or a line of
        RTL is emitted. Against the inherited exact product it would compare
        `a * b` with `a * b` and pass while checking nothing, which is worse
        than not offering it: a green check is read as evidence.

        `LutMultiplierScheme` overrides this for a decomposed node and
        `DspMultiplierScheme` for its walked IR; a leaf keeps this refusal and
        points at the generator's testbench.
        '''
        raise NotImplementedError(
            f'{self.name}: selfCheck has nothing to exercise — '
            f'{type(self).__name__}.propagateValue is the exact product, so '
            f'this would compare a*b against a*b and pass without checking '
            f'anything.'
        )


class BehaviouralMult(MultiplierScheme):
    '''`P = A * B`, modelled exactly and implemented not at all.

    A placeholder for a general multiplier whose implementation has not been
    chosen yet. Bounds and values are exact, so it can be dropped into a
    pipeline to size the datapath and produce goldens — which is what the
    four-step NTT does for its 128 inter-stage multiplies.

    Almost nothing is implemented here, which is the point. The base class
    already does the arithmetic: `propagateBound` is `self.aIn * self.bIn`,
    exact for interval times interval including intervals that straddle zero,
    and `propagateValue` is the elementwise product. Declaring what it refuses
    is all that is required.

    Deliberately **unlike** `BoothMult`:

      - no minimum operand width, so any widths work;
      - no forced two's-complement operands, so an unsigned input stays unsigned
        and its bound stays tight;
      - no area model, because there is no implementation to have an area.

    `areaCost`, `getOperatorInterface` and `emitRtl` therefore raise rather than
    returning something plausible. A placeholder that reported zero area would
    silently make any design containing it look cheaper than it is, and the
    whole reason to build with one is to compare designs later.
    '''

    family = 'behavioural'

    def __init__(self, *args, assumedLatency: int | None = None, **kwargs):
        super().__init__(*args, **kwargs)
        #: Latency to report. Assumed, not derived — there is no hardware to
        #: derive it from. Defaults to whatever the caller asks for.
        self.assumedLatency = assumedLatency

    def latency(self, pipelineStages: int = 1) -> int:
        return (self.assumedLatency if self.assumedLatency is not None
                else pipelineStages)

    def areaCost(self) -> tuple[int, int]:
        raise NotImplementedError(
            f'{self.name}: BehaviouralMult has no area — it models the '
            f'arithmetic and claims no implementation. Returning 0 would make '
            f'any design containing it look free, which is exactly the '
            f'comparison a placeholder must not corrupt. Swap in BoothMult, a '
            f'DspMultiplierScheme, or a decomposition before costing this '
            f'design.'
        )

    def getOperatorInterface(self, name: str, pipelineStages: int = 1):
        raise NotImplementedError(
            f'{self.name}: BehaviouralMult has no spec — a spec describes what '
            f'a generator should build, and there is nothing to build. Choose '
            f'a real family first.'
        )

    def emitRtl(self, name: str, run_dir, **kwargs) -> dict:
        raise NotImplementedError(
            f'{self.name}: BehaviouralMult emits no RTL — there is no '
            f'implementation behind it. Use it to propagate bounds and produce '
            f'goldens; choose a real scheme when you need hardware.'
        )
