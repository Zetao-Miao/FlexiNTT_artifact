'''The matrix-transpose operator: step four of a four-step NTT.

    scheme = BarrelMemoryBarrelTranspose(name='t', rows=128, cols=128)
    op     = MatrixTranspose(name='corner_turn', scheme=scheme)

    op.drive([Signal(bound[r], values[r]) for r in range(128)])
    op.compute()
    out = op.read()

A batch of `T * rows` is read as `T` stacked matrices, slot `b = t*rows + r`
being row `r` of matrix `t`:

    out[c].values[t*rows + r] == in[r].values[t*rows + c]

At `T = 1` that is the plain matrix transpose. Keeping it batch-at-once is what
lets it connect to the rest of the project through ports: `push()` overwrites
rather than accumulates, so an operator that consumed one row per `compute()`
could never be wired to one that reads a whole batch — every row but the last
would be thrown away, silently. Reading whole matrices out of the batch removes
that mismatch instead of guarding against it.

The price is the one constraint in the project on batch length: it must be a
multiple of `rows`, because the batch axis now carries the row index as well as
the trial index. `MatrixTransposeScheme.matrixCount` is where that is enforced.

Bounds cannot stay per element under that arrangement. A port carries one bound
for its whole batch, and output lane `c` draws from every input lane as `r`
sweeps, so every output bound is `IntType.union` of every input bound. In a
four-step this costs nothing — the inter-stage bounds are identical — but it is
a real widening when the input lanes differ.

**The clock.** With a hardware scheme, `reset()` builds the scheme's twin of
its RTL and `step()` is one clock edge: the input ports carry this cycle's row
(one value per lane, or a batch of independent trials per lane), `None` on
every lane being a cycle with data_valid low; the output ports then carry what
the RTL's data_out shows during that cycle, `None` while nothing has reached
them, and `outputValid` its data_out_valid. The batch axis of `compute()` is
the time axis of `step()`: the row `compute()` reads from slot `t*rows + r` is
the row presented at the step of that index, and `runMatrixTranspose.py`
checks the stream against the batch.
'''
from __future__ import annotations

from pathlib import Path

from ..core.Operator import Operator
from ..core.OperatorScheme import decodeTwosComplement, sampleBound
from ..core.Port import SimpleInputPort, SimpleOutputPort
from ..core.Signal import Signal
from .MatrixTransposeScheme import MatrixTransposeScheme


class MatrixTranspose(Operator):
    '''A corner turn as a connectable operator: `rows` lanes in, `cols` out.'''

    def __init__(self, name: str = 'Undefined MatrixTranspose',
                 scheme: MatrixTransposeScheme | None = None):
        super().__init__(name)
        if scheme is None:
            raise ValueError(f'{name}: MatrixTranspose requires a scheme')
        self.scheme = scheme
        # Input lanes are indexed by row, output lanes by column — see the
        # formula above. Equal while the transpose is square.
        self._inputPorts = [SimpleInputPort(f'{name} Input Port r{r}')
                            for r in range(scheme.rows)]
        self._outputPorts = [SimpleOutputPort(f'{name} Output Port c{c}')
                             for c in range(scheme.cols)]
        self._hardware = None
        #: data_out_valid of the last `step()`.
        self.outputValid: int | None = None

    @property
    def inputPorts(self) -> list:
        return self._inputPorts

    @property
    def outputPorts(self) -> list:
        return self._outputPorts

    # ------------------------------------------------------------------

    def compute(self) -> None:
        '''Transpose every matrix the loaded batch carries.

        Bounds always; values too when every lane has them, so a sizing-only
        pass works exactly as in `ConstMultBank.compute()`.
        '''
        signals = [p.signal for p in self._inputPorts]
        missing = [i for i, s in enumerate(signals) if s is None]
        if missing:
            raise ValueError(
                f'{self.name}.compute: input lanes {missing[:8]}'
                f'{"..." if len(missing) > 8 else ""} have no signal. A transpose '
                f'consumes whole matrices, so every lane must be driven.'
            )

        self.scheme.aIn = [s.bound for s in signals]
        outBounds = self.scheme.propagateBound()

        outValues = None
        if all(s.values is not None for s in signals):
            self.scheme.aInValues = [s.values for s in signals]
            outValues = self.scheme.propagateValue()

        for c, port in enumerate(self._outputPorts):
            port.signal = Signal(outBounds[c],
                                 outValues[c] if outValues is not None else None)
            if port.isConnected:
                port.push()

    # ------------------------------------------------------------------
    # The clock
    # ------------------------------------------------------------------

    def reset(self) -> None:
        '''Empty the pipeline and build it: the scheme's twin of its RTL.
        Needs the bound path computed first (`compute()` with bounds loaded),
        since the output ports carry those bounds while the pipeline fills.'''
        if self.scheme.aIn is None or any(p.bound is None for p in self._outputPorts):
            raise ValueError(
                f'{self.name}.reset: run compute() with bounds loaded first -- the '
                f'output ports carry the bounds while the pipeline fills'
            )
        self._hardware = self.scheme.buildHardware()
        self.outputValid = None

    def step(self) -> None:
        '''One clock edge. Reads this cycle's row off the input ports (every
        lane `None` = data_valid low; a mix raises), moves the twin one edge,
        and writes what data_out shows during this cycle to the output ports,
        `Signal(bound, None)` where nothing has reached them, pushing to
        connected ports. `compute()` is untouched; a design is driven by one
        or the other.'''
        if self._hardware is None:
            raise ValueError(f'{self.name}.step: call reset() first')
        values = [p.signal.values if p.signal is not None else None
                  for p in self._inputPorts]
        present = [v is not None for v in values]
        if any(present) and not all(present):
            missing = [i for i, ok in enumerate(present) if not ok]
            raise ValueError(
                f'{self.name}.step: lanes {missing[:8]} carry no values this cycle '
                f'while others do -- a row is all lanes or none (data_valid low)'
            )
        row = values if all(present) else None
        out, valid = self._hardware.tick(row)
        self.outputValid = valid
        for port, v in zip(self._outputPorts, out):
            port.signal = Signal(port.bound, v)
            if port.isConnected:
                port.push()

    # ------------------------------------------------------------------

    def getOperatorInterface(self, name: str, pipelineStages: int = 1):
        return self.scheme.getOperatorInterface(name, pipelineStages=pipelineStages)

    def areaCost(self) -> tuple[int, int]:
        return self.scheme.areaCost()

    def resources(self):
        return self.scheme.resources()

    def latency(self, pipelineStages: int = 1) -> int:
        return self.scheme.latency(pipelineStages)

    def primingBeats(self) -> int:
        '''Beats of hardware latency before the first output row. Declared for
        the behavioural scheme; the hardware schemes' is their latency.'''
        return self.scheme.primingBeats()

    def minimumStorageElements(self) -> int:
        return self.scheme.minimumStorageElements()

    # --- emitRtl: the Operator template with the transpose's hooks ------------

    def emitRtl(self, name: str, run_dir, test_size: int = 4, **kwargs) -> dict:
        '''`Operator.emitRtl` with `test_size` counting matrices (four by
        default: the testbench streams them twice, back-to-back and after a
        gap, so a run at n=128 is 1024 rows). `pipeline_stages` is ignored --
        the placement is the scheme's (`MatrixTransposeScheme`).'''
        return super().emitRtl(name, run_dir, test_size=test_size, **kwargs)

    def _effectivePipelineStages(self, pipeline_stages: int) -> int:
        '''The registers in each shifter under the scheme's plan, whatever the
        request: the scheme decides its own placement.'''
        return self.scheme.barrelLatency()

    def _generatorTarget(self) -> tuple[str, str, str]:
        return ('transpose', 'Transpose_RTL_gen', 'Transpose_SimRTL_gen')

    def _prepareTestData(self, spec, test_size: int, seed: int | None,
                         **kwargs) -> dict:
        '''`test_size` matrices per lane sampled inside each lane's bound, the
        goldens through `transposeBatches`, both handed over as rows (one per
        cycle) the way the testbench streams them.'''
        import random
        rng = random.Random(seed)
        n = self.scheme.rows
        lanes = [sampleBound(bound, test_size * n, rng) for bound in self.scheme.aIn]
        outLanes = self.scheme.transposeBatches(lanes)
        rowsIn = [[lanes[r][k] for r in range(n)] for k in range(test_size * n)]
        rowsOut = [[outLanes[c][k] for c in range(n)] for k in range(test_size * n)]
        return {'x_in': rowsIn, 'y_out': rowsOut,
                'gap_cycles': kwargs.get('gap_cycles', 1)}

    def _generatorKwargs(self, data: dict) -> dict:
        return dict(data)

    def _sanityCheck(self, run_dir, spec, sampleSize: int) -> None:
        '''Decode the first matrix of `x_in.txt` and the first rows of
        `y_out.txt` and confirm the on-disk goldens are the on-disk inputs
        transposed, at the element width and signedness the spec declares.'''
        n, w, signed = spec.rows, spec.elementWidth, spec.isSigned
        tv = Path(run_dir) / 'testvectors'

        def rows(path, count):
            out = []
            with open(path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    packed = int(line, 16)
                    out.append([decodeTwosComplement((packed >> (w * lane)) & ((1 << w) - 1), w, signed)
                                for lane in range(n)])
                    if len(out) >= count:
                        break
            return out

        xin = rows(tv / 'x_in.txt', n)
        yout = rows(tv / 'y_out.txt', min(sampleSize, n))
        if len(xin) < n:
            raise ValueError(f'{self.name}: x_in.txt holds {len(xin)} rows, fewer than one matrix')
        for c, yrow in enumerate(yout):
            expect = [xin[r][c] for r in range(n)]
            if yrow != expect:
                raise ValueError(
                    f'{self.name}: sanity check failed on output row {c}: the file '
                    f'holds {yrow[:4]}... but the inputs transpose to {expect[:4]}...'
                )
