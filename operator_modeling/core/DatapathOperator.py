'''The operator around a `DatapathScheme`: one port per scheme input and output,
and RTL emission through `rtl_gen.datapath`.

    scheme = BarrettReduction(q=q, tIn=IntType.unsigned(128))
    op = DatapathOperator('barrett', scheme)
    op.drive([Signal(scheme.tIn, values)])
    op.compute()
    meta = op.emitRtl('barrett128', 'work/x/barrett128', test_size=300)

`emitRtl` runs the same steps as the `Operator` template — spec, test data,
backend, run directory, generate, re-check — with one step the template has no
hook for: the multiplier nodes that name a `dsp` or `booth` backend are
generated first, each into `<run_dir>/_sub/<node>/` by the scheme that owns that
generator (`DspMultiplierScheme`, `BoothMult`), and handed to the datapath
generator to import. The test vectors are checked against the scheme's plain
big-integer `reference` before they are written, so a golden is never just the
model agreeing with itself. The run directory is read back as an
`RtlArtifacts` (`core/contracts.py`), checked, and stored as
`rtl_contract.json`.
'''
from __future__ import annotations

import contextlib
import io
import random as _random
import re
import shutil
from pathlib import Path

from .IntType import IntType
from .Operator import Operator
from .OperatorScheme import readHexBatch, resolveBackend, runInDir, sampleBound
from .Port import SimpleInputPort, SimpleOutputPort
from .Signal import Signal
from .contracts import RtlArtifacts, TestVectorSet, PortStream, modelEstimate
from .datapath import DatapathScheme


_PORT_RE = r'(input|output)\s+logic\s*(?:signed\s*)?\[(\d+)\s*:\s*0\]\s*{name}\b'


def _portWidth(text: str, name: str) -> int:
    m = re.search(_PORT_RE.format(name=name), text)
    if not m:
        raise ValueError(f'port {name} not found')
    return int(m.group(2)) + 1


def datapathSubmodules(scheme, spec, subDir: Path) -> dict:
    '''Generate every dsp / booth multiplier node of `spec` (scheduled from
    `scheme`) with its own generator, each in `subDir/<node>`; returns what
    `Datapath_RTL_gen` takes as `submodules`. Also used by the NTT generator
    for its datapath butterflies.'''
    from ..multiplier.LutMultiplierScheme import BoothMult
    dp = scheme.datapath()
    subs = {}
    for node in spec.nodes:
        if node.kind != 'mult' or node.backend not in ('dsp', 'booth'):
            continue
        d = Path(subDir) / node.out.name
        if d.exists():
            shutil.rmtree(d)
        d.mkdir(parents=True)
        model = next(n for n in dp.nodes if n.name == node.out.name)
        if node.backend == 'dsp':
            sch = dp.dspScheme(model, scheme.targetFmaxMhz)
            with contextlib.redirect_stdout(io.StringIO()):
                meta = sch.emitRtl(f'{spec.name}_{node.out.name}', d)
            files = [str(d / l.strip()) for l in (d / 'filelist.f').read_text().splitlines()
                     if l.strip() and not l.strip().startswith('gpc/')]
            top = meta['module']
            lat = meta['pipeline_latency']
            reset = True
        else:
            wa, wb = dp.boothWidths(model)
            sch = BoothMult(name=node.out.name, aIn=IntType.signed(wa), bIn=IntType.signed(wb))
            with contextlib.redirect_stdout(io.StringIO()):
                meta = sch.emitRtl(node.out.name, d, pipeline_stages=node.stages)
            files = sorted(str(p) for p in (d / 'RTL_generated').glob('*.sv')
                           if not p.name.endswith('_tb.sv'))
            top = meta['module']
            lat = meta['pipeline_latency']
            reset = False
        topText = next(Path(f).read_text() for f in files if re.search(rf'module\s+{top}\b', Path(f).read_text()))
        subs[node.out.name] = dict(files=files, top=top, latency=lat, reset=reset,
                                   widthA=_portWidth(topText, 'A'), widthB=_portWidth(topText, 'B'),
                                   widthP=_portWidth(topText, 'P'))
    return subs


class DatapathOperator(Operator):
    '''Ports in, a `DatapathScheme` in the middle, ports out.'''

    def __init__(self, name: str, scheme: DatapathScheme):
        super().__init__(name)
        if not isinstance(scheme, DatapathScheme):
            raise TypeError(f'{name}: scheme must be a DatapathScheme')
        self.scheme = scheme
        self._in = [SimpleInputPort(f'{name} Input Port {p}') for p in scheme.inputNames]
        self._out = [SimpleOutputPort(f'{name} Output Port {p}') for p in scheme.outputNames]

    @property
    def inputPorts(self) -> list:
        return list(self._in)

    @property
    def outputPorts(self) -> list:
        return list(self._out)

    def port(self, name: str):
        names = list(self.scheme.inputNames) + list(self.scheme.outputNames)
        return (self._in + self._out)[names.index(name)]

    # --- behaviour -----------------------------------------------------------

    def _loadScheme(self) -> bool:
        haveValues = True
        for p, port in zip(self.scheme.inputNames, self._in):
            if port.signal is None:
                raise ValueError(f'{self.name}.compute: input {p} carries no signal')
            setattr(self.scheme, self.scheme._boundAttr(p), port.signal.bound)
            setattr(self.scheme, self.scheme._valueAttr(p), port.signal.values)
            haveValues = haveValues and port.signal.values is not None
        return haveValues

    def compute(self) -> None:
        haveValues = self._loadScheme()
        bounds = self.scheme.propagateBound()
        values = self.scheme.propagateValue() if haveValues else None
        if len(self._out) == 1:
            bounds, values = (bounds,), (values,)
        for port, b, v in zip(self._out, bounds, values if values is not None else [None] * len(self._out)):
            port.signal = Signal(b, v)
            if port.isConnected:
                port.push()

    def reset(self, pipelineStages=1) -> None:
        self.scheme.reset(pipelineStages)

    def step(self) -> None:
        '''One clock edge (`DatapathScheme.step`). Outputs carry `None` while the
        pipeline fills.'''
        self._loadScheme()
        ins = {p: port.signal.values for p, port in zip(self.scheme.inputNames, self._in)}
        out = self.scheme.step(ins)
        bounds = self.scheme.propagateBound()
        if len(self._out) == 1:
            bounds = (bounds,)
        for port, b, p in zip(self._out, bounds, self.scheme.outputNames):
            port.signal = Signal(b, None if out is None else out[p])
            if port.isConnected:
                port.push()

    def getOperatorInterface(self, name: str, pipelineStages=1):
        return self.scheme.getOperatorInterface(name, pipelineStages)

    def areaCost(self) -> tuple[int, int]:
        return self.scheme.areaCost()

    def resources(self):
        return self.scheme.resources()

    def latency(self, pipelineStages=1) -> int:
        return self.scheme.latency(pipelineStages)

    def criticalPathNs(self, pipelineStages=1) -> float:
        return self.scheme.criticalPathNs(pipelineStages)

    def achievedFmaxMhz(self, pipelineStages=1) -> float:
        return self.scheme.achievedFmaxMhz(pipelineStages)

    # --- test data ---------------------------------------------------------

    def testVectors(self, test_size: int, seed: int | None = None, corners: bool = True) -> TestVectorSet:
        '''Inputs (corners first, then random within the bounds, or the
        scheme's own `sampleInputs`), goldens from the value path, checked
        against `reference`.'''
        rng = _random.Random(seed) if seed is not None else _random.Random()
        sch = self.scheme
        ins = sch.sampleInputs(test_size, rng, corners=corners)
        errors = sch.checkReference(ins)
        if errors:
            raise AssertionError(f'{self.name}: model disagrees with the reference: {errors[:3]}')
        outs = sch.datapath().run(ins)
        dp = sch.datapath()
        inStreams = [PortStream.scalar(p, dp.bound(p), ins[p]) for p in sch.inputNames]
        outStreams = [PortStream.scalar(p, dp.bound(w), outs[p]) for p, w in dp.outputs]
        return TestVectorSet(inStreams, outStreams, source=f'{type(sch).__name__}.datapath')

    # --- RTL ------------------------------------------------------------------

    def _generatorTarget(self) -> tuple[str, str, str]:
        return 'datapath', 'Datapath_RTL_gen', 'Datapath_SimRTL_gen'

    def _prepareTestData(self, spec, test_size: int, seed: int | None, **kwargs) -> dict:
        return {'tv': self.testVectors(test_size, seed, kwargs.get('corners', True))}

    def _generatorKwargs(self, data: dict) -> dict:
        tv = data.get('tv')
        if tv is None:
            return {'vectors': None}
        return {'vectors': {p.name: p.values for p in tv.inputs + tv.outputs}}

    def _submodules(self, spec, run_dir: Path, pipelineStages) -> dict:
        '''Generate every dsp / booth multiplier node with its own generator.'''
        return datapathSubmodules(self.scheme, spec, run_dir / '_sub')

    def emitRtl(self, name: str, run_dir, pipeline_stages=1, gen_testbench: bool = True,
                test_size: int = 1000, seed: int | None = None, visualization: bool = False,
                sanity_check_size: int = 8, backend: str = 'hw', corners: bool = True,
                clock_ns: float | None = None, write_xdc: bool = True, **kwargs) -> dict:
        run_dir = Path(run_dir)
        run_dir.mkdir(parents=True, exist_ok=True)
        spec = self.getOperatorInterface(name, pipeline_stages)
        data = self._prepareTestData(spec, test_size, seed, corners=corners) if gen_testbench else {}
        moduleStem, hwEntry, simEntry = self._generatorTarget()
        generate = resolveBackend(backend, moduleStem, hwEntry, simEntry)
        subs = self._submodules(spec, run_dir, pipeline_stages) if backend == 'hw' else {}
        if clock_ns is None and self.scheme.targetFmaxMhz:
            clock_ns = 1000.0 / self.scheme.targetFmaxMhz
        meta = runInDir(run_dir, generate, spec=spec, pipeline_stages=pipeline_stages,
                        gen_testbench=gen_testbench, visualization=visualization,
                        submodules=subs, write_xdc=write_xdc, clock_ns=clock_ns,
                        **self._generatorKwargs(data))
        if gen_testbench and sanity_check_size > 0:
            self._sanityCheck(run_dir, data['tv'], sanity_check_size)
        art = RtlArtifacts.collect(run_dir, top=spec.name, latency=spec.latency,
                                   estimate=dict(spec.params.get('estimate', {})),
                                   generator=f'rtl_gen.datapath ({backend})', spec=spec,
                                   meta=meta.get('manifest'))
        problems = art.check() if gen_testbench else []
        if problems:
            raise AssertionError(f'{name}: run directory breaks the RTL contract: {problems}')
        art.write()
        meta['contract'] = str(run_dir / 'rtl_contract.json')
        return meta

    def _sanityCheck(self, run_dir, tv: TestVectorSet, sampleSize: int) -> None:
        '''Decode the first vectors from disk and re-run the value path on them.'''
        bad = tv.matchesFiles(run_dir)
        if bad:
            raise AssertionError(f'{self.name}: testvector files differ from the model for {bad}')
        dp = self.scheme.datapath()
        ins = {}
        for p in self.scheme.inputNames:
            b = dp.bound(p)
            ins[p] = readHexBatch(Path(run_dir) / 'testvectors' / f'{p}.txt', sampleSize,
                                  b.bitWidth, b.isSigned)
        outs = dp.run(ins)
        for p, w in dp.outputs:
            b = dp.bound(w)
            disk = readHexBatch(Path(run_dir) / 'testvectors' / f'{p}.txt', sampleSize,
                                b.bitWidth, b.isSigned)
            if disk != outs[p][:len(disk)]:
                raise AssertionError(f'{self.name}: {p}.txt does not re-derive from the inputs on disk')
