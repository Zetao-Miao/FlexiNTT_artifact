'''The four-step NTT operator: N natural-order ports over an n-lane pipeline.

    scheme = FourStepScheme(name='fs', n=128, q=Q, preTwistConstants=...,
                            subTwiddles=..., interTwiddles=...,
                            inputBound=IntType.unsigned(24))
    op     = FourStepNTT(name='ntt16384', scheme=scheme)

    op.getInputsNatural(bounds)     # length N = n*n
    op.getInputsNatural(batches)    # length N, each a batch of T trials
    op.compute()

    widths = op.getOutputsNatural()                    # bounds
    Y      = [p.testVector for p in op.outputPorts]    # values

Read values off the ports, not from `getOutputsNatural()`. That method prefers
the bound whenever one is set, and after `compute()` one always is -- so it
returns widths, never numbers. That is `FullyPipelinedNTT.getOutputsNatural`'s
behaviour too, and `verification._verifyImpl` reads `testVector` directly for
exactly this reason; the parity is deliberate, the sharp edge is inherited.

`inputPorts[i]` is `x[i]` and `outputPorts[k]` is `Y[k]`, both in natural order,
and a batch is `T` independent trials -- the same reading every other operator in
the project gives its batch axis. That makes this a drop-in comparable to
`FullyPipelinedNTT` at size `N`, and `connectOutputsTo` works against anything N
wide.

**These ports are real ports, not views.** `FullyPipelinedNTT`'s `inputPorts`
are the boundary butterflies' own port objects, so an upstream `push()` lands
exactly where `compute()` reads and no copy step follows. That is not possible
here: the natural index maps to a *lane* and an *offset on the batch axis*, and a
port cannot be a view of half of one axis of another port's batch. So
`compute()` repacks -- scatter on the way in, gather on the way out. The cost is
one copy of the data per call; the benefit is the natural-order interface.

    scatter   lane[t2].values[t*n + t1] = inputPorts[t1 + n*t2].values[t]
    gather    outputPorts[k2 + n*k1].values[t] = nttB.outputPorts[k1].values[t*n + k2]

The internal slot `t*n + t1` is exactly the `b = t*rows + r` that
`MatrixTransposeScheme` requires, so the trial axis and the corner turn's matrix
stacking are one axis read two ways.

**Input bounds union per lane.** Bank lane `t2` is one wire carrying the n
natural indices `t1 + n*t2` as `t1` sweeps the batch, so its bound is
`IntType.union` of all n of them. Free when the inputs agree, which is the usual
case, and a real widening when they do not -- the same situation, for the same
reason, as `MatrixTranspose`'s output bounds.
'''
from __future__ import annotations

from pathlib import Path

from ...core.IntType import IntType
from ...core.Operator import Operator
from ...core.Port import SimpleInputPort, SimpleOutputPort
from ...core.Signal import Signal
from ...core.utils import MEM_GRID_ORDERS as STAGE_ORDERS, saveMemFile
from .FourStepScheme import FourStepScheme


class FourStepNTT(Operator):
    '''A four-step NTT of size `N = n*n` as a connectable operator.'''

    def __init__(self, name: str = 'Undefined FourStepNTT',
                 scheme: FourStepScheme | None = None):
        super().__init__(name)
        if scheme is None:
            raise ValueError(f'{name}: FourStepNTT requires a scheme')
        self.scheme = scheme
        n = scheme.n
        self._inputPorts = [SimpleInputPort(f'{name} Input Port x_{i}')
                            for i in range(n * n)]
        self._outputPorts = [SimpleOutputPort(f'{name} Output Port y_{k}')
                             for k in range(n * n)]

    # --- shape ------------------------------------------------------------

    @property
    def n(self) -> int:
        '''Sub-transform size. The transform this operator computes is `n*n`.'''
        return self.scheme.n

    @property
    def N(self) -> int:
        '''Transform size.'''
        return self.scheme.N

    @property
    def q(self) -> int:
        return self.scheme.q

    @property
    def inputPorts(self) -> list:
        return self._inputPorts

    @property
    def outputPorts(self) -> list:
        return self._outputPorts

    # --- driving, mirroring FullyPipelinedNTT -----------------------------

    def _drivePorts(self, ports: list, values, label: str) -> None:
        '''Write a list of bounds or of value batches onto `ports`, positionally.

        Same contract as `FullyPipelinedNTT._drivePorts`, so the two classes are
        driven identically; only the length differs.
        '''
        if not isinstance(values, list):
            raise TypeError(f'{label} must be a list, got {type(values)}')
        if len(values) != self.N:
            raise ValueError(
                f'{label} must have length N=n*n={self.N}, got {len(values)}'
            )

        if all(isinstance(v, list) for v in values):
            batchSize = len(values[0]) if values else 0
            if any(len(v) != batchSize for v in values):
                raise ValueError(
                    'all test-vector batches must have the same length; got '
                    'mixed lengths in inputs'
                )
            for v in values:
                if not all(isinstance(e, int) for e in v):
                    raise TypeError(
                        'all elements of a test-vector batch must be int'
                    )
            for port, v in zip(ports, values):
                port.testVector = v
        elif all(isinstance(v, IntType) for v in values):
            for port, v in zip(ports, values):
                port.bound = v
        else:
            raise TypeError('inputs must be either list[IntType] or list[list[int]]')

    def getInputsNatural(self, x) -> None:
        '''Drive the inputs from a natural-order list `x[0] .. x[N-1]`.

        Accepts a list of `IntType` bounds or a list of value batches, exactly
        as `FullyPipelinedNTT.getInputsNatural` does. Call it twice -- bounds,
        then batches -- to populate both; each setter preserves the other.
        '''
        self._drivePorts(self._inputPorts, x, 'x')

    def getOutputsNatural(self):
        '''Natural-order outputs `Y[0] .. Y[N-1]`, bound preferred over values.

        After `compute()` every output port has a bound, so in practice this
        returns **widths, not numbers**. For the transformed values read
        `[p.testVector for p in self.outputPorts]`. The preference order is
        `FullyPipelinedNTT.getOutputsNatural`'s, kept so the two classes are
        interchangeable; it is a sharp edge in both.
        '''
        return [p.bound if p.bound is not None else p.testVector
                for p in self._outputPorts]

    # --- behaviour --------------------------------------------------------

    def compute(self) -> None:
        '''Repack the N natural ports onto n lanes, run the five stages, repack back.

        Bounds always; values too when every input port carries them, so a
        sizing-only pass works exactly as in `ConstMultBank.compute()`.

        **A sizing-only pass does not erase the previous run's values from the
        interior.** `Butterfly.compute` recomputes bounds but leaves an existing
        `testVector` in place, so the sub-NTTs' and the corner turn's ports still
        show the last value pass's data. This operator inherits that from
        `FullyPipelinedNTT`, which behaves identically; it is not introduced
        here. The operator's own output ports *are* cleared, and
        `saveStageOutputs` refuses to write a half-populated pipeline, so the
        stale data cannot reach a dump. Read interior ports after a sizing pass
        with that in mind.
        '''
        signals = [p.signal for p in self._inputPorts]
        missing = [i for i, s in enumerate(signals) if s is None]
        if missing:
            raise ValueError(
                f'{self.name}.compute: input ports {missing[:8]}'
                f'{"..." if len(missing) > 8 else ""} have no signal. A four-step '
                f'consumes a whole transform, so every one of the {self.N} ports '
                f'must be driven.'
            )

        haveValues = all(s.values is not None for s in signals)
        trials = None
        if haveValues:
            lengths = {len(s.values) for s in signals}
            if len(lengths) > 1:
                raise ValueError(
                    f'{self.name}.compute: input batches have differing lengths '
                    f'{sorted(lengths)}; a batch here is a count of independent '
                    f'trials and must be the same on every port'
                )
            trials = lengths.pop()
            if trials < 1:
                raise ValueError(
                    f'{self.name}.compute: input batches are empty; a batch is '
                    f'a count of independent trials and needs at least one'
                )

        self._scatter(signals, trials)
        self._loadTwiddles(trials)
        self.scheme.runChain()
        self._gather(trials)

    def _scatter(self, signals: list, trials: int | None) -> None:
        '''Natural ports -> bank lanes. Lane `t2`, slot `internalSlot(t, t1)`.

        Routed through the scheme's `inputNaturalToLane` and `internalSlot`
        rather than re-deriving `divmod` and `t*n + offset` inline. That is not
        style: this repo has already been bitten once by index rules living in a
        scheme that nothing called while the consumer open-coded its own copy --
        `NTTScheme`'s four permutation methods sat dead for a whole refactor
        while `FullyPipelinedNTT.py` re-derived the same rule in about eleven places. One
        definition, one caller, no drift.
        '''
        n = self.n
        sources = [[None] * n for _ in range(n)]
        for i, signal in enumerate(signals):
            lane, offset = self.scheme.inputNaturalToLane(i)
            sources[lane][offset] = signal

        lanes = []
        for lane in range(n):
            bound = IntType.union([s.bound for s in sources[lane]])
            values = None
            if trials is not None:
                values = [0] * (trials * n)
                for offset, source in enumerate(sources[lane]):
                    for t in range(trials):
                        values[self.scheme.internalSlot(t, offset)] = source.values[t]
            lanes.append(Signal(bound, values))
        self.scheme.bank.drive(lanes)

    def _loadTwiddles(self, trials: int | None) -> None:
        '''Put one twiddle batch on each multiplier's B port, tiled to `trials`.

        Cleared to bound-only on a sizing pass rather than left holding a batch
        of the wrong length -- a stale batch outlives the call that set it, and
        `Multiplier.compute` would pair it with the next run's A values.
        '''
        bound = self.scheme.interTwistBound
        if trials is None:
            for mult in self.scheme.mults:
                mult.inputPortB.signal = Signal(bound, None)
            return
        tiled = self.scheme.tiledTwiddles(trials)
        for mult, batch in zip(self.scheme.mults, tiled):
            mult.inputPortB.signal = Signal(bound, batch)

    def _gather(self, trials: int | None) -> None:
        '''nttB lanes -> natural ports. Port `k2 + n*k1` from lane `k1`, slot `t*n + k2`.'''
        n = self.n
        expected = None if trials is None else trials * n
        for k, port in enumerate(self._outputPorts):
            lane, offset = self.scheme.outputNaturalToLane(k)
            source = self.scheme.nttB.outputPorts[lane]
            values = None
            if expected is not None:
                batch = source.testVector
                if batch is None or len(batch) != expected:
                    raise ValueError(
                        f'{self.name}.compute: sub-NTT lane {lane} produced '
                        f'{0 if batch is None else len(batch)} values, expected '
                        f'{expected} = {trials} trials x n={n}. The scatter and '
                        f'the twiddle tiling disagree about the trial count.'
                    )
                values = [batch[self.scheme.internalSlot(t, offset)]
                          for t in range(trials)]
            port.signal = Signal(source.bound, values)
            if port.isConnected:
                port.push()

    # --- stage dumps ------------------------------------------------------

    def saveStageOutputs(self, directory, order: str = 'beatMajor',
                         radix: str = 'hex', prefix: str = '') -> dict:
        '''Dump every stage's output ports to one `.mem` file per stage.

        Call after `compute()`, which is what leaves values on the ports.
        Returns `{stageName: path}`. This is the view the RTL bring-up wants:
        five memory images that a testbench can `$readmemh`, and the only way to
        see *where* a four-step went wrong rather than merely that it did.

        `order` picks how the `n lanes x slots` grid is flattened:

            'beatMajor'  index = slot * n + lane   n consecutive words are one
                         slot across every lane -- the order hardware emits them
            'laneMajor'  index = lane * slots + slot   n consecutive words are
                         one lane's whole batch

        `radix` is 'hex' (`$readmemh`) or 'bin' (`$readmemb`).

        Word width is taken per stage from the widest bound among that stage's
        ports, because a memory image carries no per-word length and one file
        must use one width. Signed interior values are written two's complement
        at that width, so the NTT stages and the wider multiplier stage both come
        out readable rather than as a minus sign no `$readmemh` can parse.
        '''
        if order not in STAGE_ORDERS:
            raise ValueError(
                f'{self.name}.saveStageOutputs: order must be one of '
                f'{STAGE_ORDERS}, got {order!r}'
            )
        if radix not in ('hex', 'bin'):
            raise ValueError(
                f"{self.name}.saveStageOutputs: radix must be 'hex' or 'bin', "
                f'got {radix!r}'
            )
        directory = Path(directory)
        directory.mkdir(parents=True, exist_ok=True)

        s = self.scheme
        stages = [
            ('pre_twist_bank', s.bank.outputPorts),
            ('ntt_a', s.nttA.outputPorts),
            ('transpose', s.transpose.outputPorts),
            ('inter_mult', [mult.outputPortP for mult in s.mults]),
            ('ntt_b', s.nttB.outputPorts),
        ]
        written: dict[str, str] = {}
        for stageName, ports in stages:
            signals = [port.signal for port in ports]
            if any(sig is None or sig.values is None for sig in signals):
                raise ValueError(
                    f'{self.name}.saveStageOutputs: {stageName} has a port with '
                    f'no values -- drive and compute the pipeline before saving'
                )
            lanes = [sig.values for sig in signals]
            slots = len(lanes[0])
            if any(len(batch) != slots for batch in lanes):
                raise ValueError(
                    f'{self.name}.saveStageOutputs: {stageName} lanes have '
                    f'differing batch lengths {sorted({len(b) for b in lanes})}'
                )
            wordBits = max(sig.bound.bitWidth for sig in signals)
            if order == 'beatMajor':
                flat = [lanes[lane][slot] for slot in range(slots)
                        for lane in range(len(lanes))]
            else:
                flat = [value for batch in lanes for value in batch]
            path = directory / f'{prefix}{stageName}.mem'
            saveMemFile(str(path), flat, wordBits=wordBits, radix=radix)
            written[stageName] = str(path)
        return written

    # --- costing ----------------------------------------------------------

    def latency(self, pipelineStages: int = 1) -> int:
        return self.scheme.latency(pipelineStages)

    def areaCost(self) -> tuple[int, int]:
        return self.scheme.areaCost()

    def getOperatorInterface(self, name: str, pipelineStages: int = 1):
        return self.scheme.getOperatorInterface(name, pipelineStages=pipelineStages)

    # --- emitRtl: nothing to emit ----------------------------------------

    def emitRtl(self, name: str, run_dir, **kwargs) -> dict:
        raise NotImplementedError(
            f'{self.name}: FourStepNTT emits no RTL -- there is no four-step '
            f'generator and no four_step_spec.py for one to consume. The pieces '
            f'do emit individually: scheme.nttA.emitRtl / scheme.nttB.emitRtl, '
            f'scheme.bank.emitRtl, and scheme.transpose.emitRtl once a '
            f'transposeSchemeFactory has supplied a hardware corner turn (the '
            f'default behavioural one has no storage architecture to target). '
            f'Wiring them into one top, with valid tracking through the NTTs, '
            f'is the work that has not been done.'
        )

    def _generatorTarget(self) -> tuple[str, str, str]:
        raise NotImplementedError(
            f'{self.name}: there is no four-step generator to target.'
        )

    def _prepareTestData(self, spec, test_size: int, seed: int | None,
                         **kwargs) -> dict:
        raise NotImplementedError(
            f'{self.name}: there is no four-step generator to feed.'
        )

    def _generatorKwargs(self, data: dict) -> dict:
        raise NotImplementedError(
            f'{self.name}: there is no four-step generator to feed.'
        )
