'''Template for an operator: a thing with ports that you instantiate and connect.

The split this file completes:

    scheme    the arithmetic. Given input bounds, what is the output bound;
              given input values, what are the output values; what spec
              describes it; what does it cost. No ports, no neighbours.

    operator  the thing in a design. Owns input and output Ports, holds a
              scheme, connects to other operators, and drives RTL emission.

A user script therefore reads the same way for every operator in the project:
build it, connect it, drive its inputs, compute, emit.

Six operators subclass this: `FullyPipelinedNTT` (ntt/pipelined, with
`FullyPipelinedINTT` under it), `MatrixTranspose` (MatrixTranspose.py),
`FourStepNTT` (FourStepNTT.py), `Multiplier` (Multiplier.py), `ConstMult`
(ConstMult.py) and `ConstMultBank` (ConstMultBank.py).
'''
from __future__ import annotations

from abc import ABC, abstractmethod

from .OperatorScheme import resolveBackend, runInDir
from .Signal import Signal


class Operator(ABC):
    '''Base for a modelled operator. Ports in, scheme in the middle, ports out.

    Concrete operators supply four hooks and inherit the rest:

        _generatorTarget()      which generator module and entry points to call
        _prepareTestData(spec)  how testvectors and goldens are obtained
        _generatorKwargs(data)  what those arrays are called in this generator
        _sanityCheck(...)       how to re-verify what landed on disk

    A fifth hook, `_effectivePipelineStages`, defaults to returning the request
    unchanged; `ConstMult` and `MatrixTranspose` override it because their
    schemes pick their own register count, and the template calls it first,
    before the spec is built.

    Those hooks are exactly where the hand-written `emitRtl` implementations
    genuinely differed; everything else about them is the same eight steps in
    the same order, which is what this class absorbs. Three operators do not use
    the template at all: `FullyPipelinedNTT` (a per-layer stage list and a
    hardware manifest), `Multiplier` (the scheme picks the generator) and
    `FourStepNTT` (there is nothing to emit).
    '''

    def __init__(self, name: str = 'Undefined Operator'):
        self.name: str = name

    # --- ports ------------------------------------------------------------

    @property
    @abstractmethod
    def inputPorts(self) -> list:
        '''Input ports, in this operator's own index order.'''

    @property
    @abstractmethod
    def outputPorts(self) -> list:
        '''Output ports, in this operator's own index order.'''

    def drive(self, signals: list[Signal]) -> None:
        '''Load every input port from `signals`, positionally.'''
        ports = self.inputPorts
        if len(signals) != len(ports):
            raise ValueError(
                f'{self.name}.drive: got {len(signals)} signals for '
                f'{len(ports)} input ports'
            )
        for port, signal in zip(ports, signals):
            port.signal = signal

    def read(self) -> list[Signal]:
        '''Current payload of every output port, in index order.'''
        return [port.signal for port in self.outputPorts]

    # --- the same, as Vectors (core/Vector.py) ------------------------------

    def inputVector(self, name: str = ''):
        '''The input ports' signals as one `Vector`, lane i = input port i.'''
        from .Vector import Vector
        return Vector.fromPorts(self.inputPorts, name=name or f'{self.name}.in')

    def outputVector(self, name: str = ''):
        '''The output ports' signals as one `Vector`, lane i = output port i.'''
        from .Vector import Vector
        return Vector.fromPorts(self.outputPorts, name=name or f'{self.name}.out')

    def driveVector(self, vector) -> None:
        '''Load a `Vector` onto the input ports, lane by lane.'''
        self.drive(list(vector.lanes))

    # --- wiring ------------------------------------------------------------

    def connectOutputsTo(self, other: 'Operator') -> None:
        '''Wire every output port of this operator to the matching input port
        of `other`, positionally.

        Saves writing the index loop by hand at every stage boundary, which for
        a 128-lane pipeline is the difference between one line and three. Counts
        must match exactly; a mismatch is a wiring mistake, not something to
        pad or truncate around.

        This connects one operator to one operator. Fanning an NTT out to 128
        separate multipliers is still a loop, because that is 128 operators.
        '''
        mine, theirs = self.outputPorts, other.inputPorts
        if len(mine) != len(theirs):
            raise ValueError(
                f'{self.name}.connectOutputsTo({other.name}): '
                f'{len(mine)} output ports cannot drive {len(theirs)} input ports'
            )
        for out, inp in zip(mine, theirs):
            out.connect(inp)

    def connectInputsFrom(self, other: 'Operator') -> None:
        '''Inverse of `connectOutputsTo`: wire `other`'s outputs into this
        operator's inputs.'''
        other.connectOutputsTo(self)

    # --- behaviour --------------------------------------------------------

    @abstractmethod
    def compute(self) -> None:
        '''Drive this operator's scheme from its input ports into its outputs.'''

    @abstractmethod
    def getOperatorInterface(self, name: str):
        '''Frozen spec for the RTL generator; normally delegates to the scheme.

        The `emitRtl` template calls this with `pipelineStages=` — the number
        `_effectivePipelineStages` settled on — so an operator that uses the
        template must accept that keyword, even though this declaration does
        not carry it. `FullyPipelinedNTT` declares `(self, name)` only; that is
        safe because it overrides `emitRtl`, so the template never reaches it.
        '''

    @abstractmethod
    def areaCost(self) -> tuple[int, int]:
        '''`(LUT, DSP)`. An estimate, held to roughly 5% — not a replica of the
        generator.'''

    @abstractmethod
    def latency(self, pipelineStages: int = 1) -> int:
        '''Pipeline registers between this operator's inputs and its outputs.'''

    def resources(self):
        '''`Resources` (LUT, DSP, BRAM36, BRAM18); normally the scheme's.'''
        return self.scheme.resources()

    # --- RTL emission: one template, four hooks -------------------------

    def emitRtl(self, name: str, run_dir,
                pipeline_stages: int = 1,
                gen_testbench: bool = True,
                test_size: int = 1000,
                seed: int | None = None,
                visualization: bool = False,
                sanity_check_size: int = 8,
                backend: str = 'hw',
                **kwargs) -> dict:
        '''Generate RTL into `run_dir`; return the generator's metadata.

        The same eight steps for every operator: validate, build the spec,
        obtain test data, resolve the backend, move into the run directory,
        generate, re-check what landed, return. Only the four hooks below
        differ between operators, and they are exactly where the hand-written
        implementations genuinely diverged.
        '''
        if pipeline_stages < 0:
            raise ValueError(
                f'{self.name}.emitRtl: pipeline_stages must be >= 0, got '
                f'{pipeline_stages} (0 is a combinational block)'
            )
        pipeline_stages = self._effectivePipelineStages(pipeline_stages)

        spec = self.getOperatorInterface(name, pipelineStages=pipeline_stages)

        data: dict = {}
        if gen_testbench:
            data = self._prepareTestData(spec, test_size=test_size, seed=seed,
                                         **kwargs)

        moduleStem, hwEntry, simEntry = self._generatorTarget()
        generate = resolveBackend(backend, moduleStem, hwEntry, simEntry)

        meta = runInDir(run_dir, generate,
                        spec=spec,
                        pipeline_stages=pipeline_stages,
                        gen_testbench=gen_testbench,
                        visualization=visualization,
                        **self._generatorKwargs(data))

        if gen_testbench and sanity_check_size > 0:
            self._sanityCheck(run_dir, spec, sanity_check_size)
        return meta

    def _effectivePipelineStages(self, pipeline_stages: int) -> int:
        '''The stage count actually handed to the generator.

        `pipeline_stages` is what the caller asked for. A scheme built with a
        frequency target decides its own count -- the fewest stages that reach
        the target -- and an operator over such a scheme overrides this to
        return that number, so the spec and the generator see the same figure
        the scheme's `latency()` reports. The default is the request itself.
        '''
        return pipeline_stages

    @abstractmethod
    def _generatorTarget(self) -> tuple[str, str, str]:
        '''`(moduleStem, hwEntryPoint, simEntryPoint)` for `resolveBackend`.'''

    @abstractmethod
    def _prepareTestData(self, spec, test_size: int, seed: int | None,
                         **kwargs) -> dict:
        '''Sample inputs and compute goldens. The generator never samples.'''

    @abstractmethod
    def _generatorKwargs(self, data: dict) -> dict:
        '''Map the test data onto this generator's argument names.'''

    def _sanityCheck(self, run_dir, spec, sampleSize: int) -> None:
        '''Re-derive the on-disk goldens from the on-disk inputs and compare.

        Default is to skip. Operators that can cheaply re-run their value path
        over what was actually written should override — it catches
        two's-complement encoding mistakes locally, before any simulator.
        '''
        return None
