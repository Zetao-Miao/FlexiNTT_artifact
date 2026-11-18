'''The general-multiplier operator: two input ports, one output port, a scheme.

    scheme = BoothMult(name='b', aIn=IntType.signed(24), bIn=IntType.signed(24))
    op     = Multiplier(name='Bmult24x24', scheme=scheme)

    op.drive([Signal(aBound, aValues), Signal(bBound, bValues)])
    op.compute()

Whatever the scheme is built from — a LUT decomposition the model chose, or a
DSP58 tiling the `dspmult` search chose — the operator around it is this one. A
new family changes what happens inside `compute()` and where `emitRtl` dispatches
to, never the shape of the thing you connect.
'''
from __future__ import annotations

import random as _random

from ..core.Operator import Operator
from ..core.OperatorScheme import sampleBound
from ..core.Port import SimpleInputPort, SimpleOutputPort
from ..core.Signal import Signal
from .MultiplierScheme import MultiplierScheme


class Multiplier(Operator):
    '''`P = A * B` as a connectable operator.'''

    def __init__(self, name: str = 'Undefined Multiplier',
                 scheme: MultiplierScheme | None = None):
        super().__init__(name)
        if scheme is None:
            raise ValueError(f'{name}: Multiplier requires a scheme')
        self.scheme = scheme
        self.inputPortA = SimpleInputPort(f'{name} Input Port A')
        self.inputPortB = SimpleInputPort(f'{name} Input Port B')
        self.outputPortP = SimpleOutputPort(f'{name} Output Port P')

    @property
    def inputPorts(self) -> list:
        return [self.inputPortA, self.inputPortB]

    @property
    def outputPorts(self) -> list:
        return [self.outputPortP]

    def compute(self) -> None:
        sa, sb = self.inputPortA.signal, self.inputPortB.signal
        if sa is None or sb is None:
            raise ValueError(f'{self.name}.compute: an input port has no signal')

        self.scheme.aIn, self.scheme.bIn = sa.bound, sb.bound
        outBound = self.scheme.propagateBound()

        outValues = None
        if sa.values is not None and sb.values is not None:
            self.scheme.aInValues, self.scheme.bInValues = sa.values, sb.values
            outValues = self.scheme.propagateValue()

        self.outputPortP.signal = Signal(outBound, outValues)
        if self.outputPortP.isConnected:
            self.outputPortP.push()

    def getOperatorInterface(self, name: str, pipelineStages: int = 1):
        return self.scheme.getOperatorInterface(name, pipelineStages=pipelineStages)

    def areaCost(self) -> tuple[int, int]:
        return self.scheme.areaCost()

    def latency(self, pipelineStages: int = 1) -> int:
        return self.scheme.latency(pipelineStages)

    def selfCheck(self, testSize: int = 256, seed: int | None = None) -> None:
        '''Assert the scheme's structure really computes A * B.

        Only a scheme that walks a structure can answer this — a decomposed
        LUT node, or a DSP scheme walking the backend's IR with its tile
        netlists inside. A leaf refuses rather than pass vacuously. See
        `MultiplierScheme.selfCheck`.
        '''
        self.scheme.selfCheck(testSize=testSize, seed=seed)

    def reset(self) -> None:
        '''Empty the pipeline (beat mode). Untimed `compute()` is unaffected.'''
        fn = getattr(self.scheme, 'reset', None)
        if fn is None:
            raise NotImplementedError(f'{self.name}: {type(self.scheme).__name__} has no clocked model')
        fn()

    def step(self) -> None:
        '''One clock edge. Reads this cycle's batch off each input port, moves
        every register in the scheme's model one stage, and writes what is on
        the boundary register to the output port — `Signal(bound, None)` while
        the pipeline is still filling. The untimed `compute()` is untouched;
        a design is driven by one or the other, never both.'''
        fn = getattr(self.scheme, 'step', None)
        if fn is None:
            raise NotImplementedError(f'{self.name}: {type(self.scheme).__name__} has no clocked model')
        sa, sb = self.inputPortA.signal, self.inputPortB.signal
        if sa is None or sb is None or sa.values is None or sb.values is None:
            raise ValueError(f'{self.name}.step: an input port carries no values this cycle')
        self.scheme.aIn, self.scheme.bIn = sa.bound, sb.bound
        out = fn(sa.values, sb.values)
        self.outputPortP.signal = Signal(self.scheme.propagateBound(), out)
        if self.outputPortP.isConnected:
            self.outputPortP.push()

    def internalSignals(self) -> dict:
        '''Every internal wire of the last `compute()`, as `Signal`s, for a
        scheme that models its hardware (`DspMultiplierScheme`). A leaf has
        no interior to show and raises.'''
        fn = getattr(self.scheme, 'internalSignals', None)
        if fn is None:
            raise NotImplementedError(
                f'{self.name}: {type(self.scheme).__name__} has no modelled '
                f'interior — it is a leaf handed whole to its generator.')
        return fn()

    # --- emitRtl hooks --------------------------------------------------

    def _generatorTarget(self) -> tuple[str, str, str]:
        raise NotImplementedError(
            f'{self.name}: a general multiplier has no single generator — the '
            f'LUT family emits through rtl_gen.booth_mult (leaves) or the '
            f'unwritten rtl_gen/mult.py (decomposed nodes), and the DSP family '
            f'through rtl_gen.dsp_multiplier.pipeline. `emitRtl` dispatches to '
            f'the scheme instead of running the Operator template.'
        )

    def _prepareTestData(self, spec, test_size: int, seed: int | None,
                         **kwargs) -> dict:
        rng = _random.Random(seed) if seed is not None else _random
        aIn = sampleBound(self.scheme.aIn, test_size, rng)
        bIn = sampleBound(self.scheme.bIn, test_size, rng)
        saved = (self.scheme.aInValues, self.scheme.bInValues)
        try:
            self.scheme.aInValues, self.scheme.bInValues = aIn, bIn
            pOut = self.scheme.propagateValue()
        finally:
            self.scheme.aInValues, self.scheme.bInValues = saved
        return {'A': aIn, 'B': bIn, 'P': pOut}

    def _generatorKwargs(self, data: dict) -> dict:
        return {'A': data.get('A'), 'B': data.get('B'), 'P': data.get('P')}

    def emitRtl(self, name: str, run_dir, **kwargs) -> dict:
        '''Hand off to the scheme, which knows which backend it belongs to.

        Deliberately not the `Operator.emitRtl` template: that template picks
        one generator by name and passes one `pipeline_stages` int, and the two
        families disagree on both. A Booth leaf goes to `Bmult_RTL_gen`; a DSP
        scheme lowers through `rtl_gen.dsp_multiplier.pipeline` under a
        `latencyBudget`; a decomposed LUT node raises, because `rtl_gen/mult.py`
        does not exist yet. The scheme states which of those it is.
        '''
        return self.scheme.emitRtl(name=name, run_dir=run_dir, **kwargs)
