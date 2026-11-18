'''The three contracts between the generator's frontend and its backend.

The design sheet joins the frontend (the Python models) to the backend (the
Versal generators) with three arrows. The code already honoured them by
convention; this module writes each one down as a class, so a new operator
knows exactly what it owes and a tool can check it.

1. RTL (generation) contract — `RtlArtifacts`
   A spec goes in (a frozen dataclass in `versal_arith/*_spec.py`); a run
   directory comes out with a fixed layout:

       <run_dir>/RTL_generated/   design *.sv, plus <top>_tb.sv
                 xdc_generated/   placement / clock constraints (optional)
                 testvectors/     one hex file per port, read by the testbench
                 manifest.json    the generator's own record (NTT, modmult)

   plus the numbers the model promised: the latency the testbench waits, and
   the resource / timing estimate. `RtlArtifacts.collect` reads a run
   directory back into one record, `check()` lists what is missing or
   inconsistent, and `write()` stores it as `rtl_contract.json` beside the
   generator's own files (never over them).

2. Emulated test vectors — `TestVectorSet`
   Inputs sampled from the bounds and goldens computed by the model's value
   path, in the format the testbenches `$readmemh`: one line per trial, each a
   port's value as zero-padded upper-case hex of exactly its width's two's
   complement (`rtl_gen.utils.to_twos_complement_hex`), or a multi-lane port
   packed with lane 0 in the low bits (`rtl_gen.ntt._pack_per_slot`, i.e.
   `Vector.pack`). `TestVectorSet.check` compares the vectors against an
   independent reference (plain big-integer arithmetic), which is what makes
   them golden rather than merely self-consistent.

3. Accurate hardware data — `HardwareRecord`, `HardwareDatabase`
   What implementation actually gave: LUT, FF, DSP, BRAM, URAM, the clock
   asked for, WNS and so the achieved frequency, the latency in cycles, the
   tool and the stage (synth / impl / board). Parsed from Vivado's
   `utilization.rpt` and `timing_summary.rpt`, kept in a JSON-lines file, and
   compared with the model's own estimate (`compare`), so the cost and timing
   tables (`lut_timing`, `lut_cost`) can be checked and recalibrated against
   real numbers, and a higher-level performance model can read them.

No host names or absolute server paths are stored: a record keeps the design
name and the run directory relative to the caller's root.
'''
from __future__ import annotations

import json
import os
import re
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Callable, Iterable, Protocol, runtime_checkable

from .IntType import IntType
from .Vector import Vector

RTL_DIR = 'RTL_generated'
XDC_DIR = 'xdc_generated'
TV_DIR = 'testvectors'
CONTRACT_FILE = 'rtl_contract.json'


# =============================================================================
# 1. The RTL generation contract
# =============================================================================

@runtime_checkable
class RtlGenerationContract(Protocol):
    '''What an operator (or a scheme that emits) promises the backend side.

    `getOperatorInterface` returns the frozen spec the generator consumes;
    `latency` the cycles from inputs to outputs the generated RTL has;
    `resources` the model's cost estimate; `emitRtl` writes a run directory in
    the layout above and returns the generator's metadata dict.
    '''

    def getOperatorInterface(self, name: str, *args, **kwargs): ...

    def latency(self, *args, **kwargs) -> int: ...

    def resources(self): ...

    def emitRtl(self, name: str, run_dir, *args, **kwargs) -> dict: ...


def contractGaps(obj) -> list[str]:
    '''Names of the contract methods `obj` lacks (empty when it honours it).'''
    return [m for m in ('getOperatorInterface', 'latency', 'resources', 'emitRtl')
            if not callable(getattr(obj, m, None))]


_MODULE_RE = re.compile(r'^\s*module\s+(\w+)', re.MULTILINE)
_READMEM_RE = re.compile(r'\$readmemh\(\s*"([^"]+)"')


def _specDict(spec) -> dict | None:
    if spec is None:
        return None
    if hasattr(spec, 'to_dict'):
        try:
            return spec.to_dict()
        except Exception:                                   # noqa: BLE001
            return None
    return None


@dataclass
class RtlArtifacts:
    '''One generated run directory, as a record. Paths are relative to `runDir`.'''

    top: str
    runDir: str
    rtl: list[str] = field(default_factory=list)
    testbench: str | None = None
    constraints: list[str] = field(default_factory=list)
    testvectors: list[str] = field(default_factory=list)
    modules: list[str] = field(default_factory=list)
    latency: int | None = None
    estimate: dict = field(default_factory=dict)
    generator: str = ''
    spec: dict | None = None
    meta: dict = field(default_factory=dict)

    @staticmethod
    def collect(runDir, top: str | None = None, latency: int | None = None,
                estimate: dict | None = None, generator: str = '', spec=None,
                meta: dict | None = None) -> 'RtlArtifacts':
        '''Read a run directory back. `top` defaults to the one testbench's
        name without `_tb` (the rule `run_remote_sim.detect_top` applies).'''
        root = Path(runDir)
        rtlDir = root / RTL_DIR
        sv = sorted(p for p in rtlDir.glob('*.sv')) if rtlDir.is_dir() else []
        tbs = [p for p in sv if p.name.endswith('_tb.sv')]
        if top is None:
            if len(tbs) == 1:
                top = tbs[0].name[:-len('_tb.sv')]
            else:
                raise ValueError(f'RtlArtifacts.collect({runDir}): cannot infer the top '
                                 f'from {len(tbs)} testbenches; pass top=')
        design = [p for p in sv if not p.name.endswith('_tb.sv')]
        modules: list[str] = []
        for p in design:
            modules += _MODULE_RE.findall(p.read_text(errors='replace'))
        tb = rtlDir / f'{top}_tb.sv'
        xdc = sorted((root / XDC_DIR).glob('*.xdc')) if (root / XDC_DIR).is_dir() else []
        tv = sorted((root / TV_DIR).glob('*')) if (root / TV_DIR).is_dir() else []
        rel = lambda p: str(p.relative_to(root))                # noqa: E731
        if meta is None and (root / 'manifest.json').is_file():
            try:
                meta = json.loads((root / 'manifest.json').read_text())
            except json.JSONDecodeError:
                meta = None
        return RtlArtifacts(
            top=top, runDir=str(root), rtl=[rel(p) for p in design],
            testbench=rel(tb) if tb.is_file() else None,
            constraints=[rel(p) for p in xdc], testvectors=[rel(p) for p in tv if p.is_file()],
            modules=modules, latency=latency, estimate=dict(estimate or {}),
            generator=generator, spec=_specDict(spec), meta=dict(meta or {}))

    def check(self) -> list[str]:
        '''Problems with this run directory, empty when it honours the contract:
        the top module is defined, every module is defined once, the testbench
        exists and every file it `$readmemh`s was written.'''
        problems: list[str] = []
        if self.top not in self.modules:
            problems.append(f'top module {self.top!r} is not defined in {RTL_DIR}/')
        dup = sorted({m for m in self.modules if self.modules.count(m) > 1})
        if dup:
            problems.append(f'modules defined more than once: {dup}')
        if self.testbench is None:
            problems.append(f'no testbench {RTL_DIR}/{self.top}_tb.sv')
        else:
            text = (Path(self.runDir) / self.testbench).read_text(errors='replace')
            names = {Path(p).name for p in self.testvectors}
            for path in _READMEM_RE.findall(text):
                if Path(path).name not in names:
                    problems.append(f'testbench reads {path!r} but {TV_DIR}/ has no such file')
        return problems

    def write(self) -> Path:
        path = Path(self.runDir) / CONTRACT_FILE
        d = asdict(self)
        d['runDir'] = '.'
        path.write_text(json.dumps(d, indent=2, default=str))
        return path

    @staticmethod
    def load(runDir) -> 'RtlArtifacts':
        d = json.loads((Path(runDir) / CONTRACT_FILE).read_text())
        d['runDir'] = str(runDir)
        return RtlArtifacts(**d)


def modelEstimate(obj, *args) -> dict:
    '''The model's promises about `obj`'s hardware, as plain numbers: what
    `resources()`, `criticalPathNs()` and `achievedFmaxMhz()` answer, each left
    out when the object cannot answer it.'''
    out: dict = {}
    try:
        r = obj.resources()
        out.update(lut=r.lut, dsp=r.dsp, bram36=r.bram36, bram18=r.bram18)
    except Exception:                                       # noqa: BLE001
        pass
    for key, meth in (('criticalPathNs', 'criticalPathNs'), ('fmaxMhz', 'achievedFmaxMhz')):
        fn = getattr(obj, meth, None)
        if fn is None and hasattr(obj, 'scheme'):
            fn = getattr(obj.scheme, meth, None)
        if callable(fn):
            try:
                out[key] = float(fn(*args))
            except Exception:                               # noqa: BLE001
                pass
    return out


def emitWithContract(operator, name: str, run_dir, latencyArgs: tuple = (),
                     **emitKwargs) -> tuple[dict, RtlArtifacts]:
    '''`operator.emitRtl(name, run_dir, **emitKwargs)`, then the run directory
    read back as an `RtlArtifacts` carrying the model's latency and estimate,
    checked and written to `rtl_contract.json`. Raises when `check()` finds a
    problem, so a broken run never reaches a simulator.'''
    meta = operator.emitRtl(name, run_dir, **emitKwargs)
    latency = None
    if isinstance(meta, dict):
        latency = meta.get('pipeline_latency', meta.get('latency', meta.get('total_latency')))
    if latency is None:
        try:
            latency = operator.latency(*latencyArgs)
        except Exception:                                   # noqa: BLE001
            latency = None
    top = meta.get('module') if isinstance(meta, dict) else None
    spec = None
    try:
        spec = operator.getOperatorInterface(name)
    except Exception:                                       # noqa: BLE001
        spec = None
    art = RtlArtifacts.collect(run_dir, top=top if top and Path(run_dir, RTL_DIR, f'{top}_tb.sv').is_file() else None,
                               latency=latency, estimate=modelEstimate(operator, *latencyArgs),
                               generator=type(operator).__name__, spec=spec,
                               meta=meta if isinstance(meta, dict) else None)
    problems = art.check()
    if problems:
        raise AssertionError(f'{name}: run directory breaks the RTL contract: {problems}')
    art.write()
    return meta, art


# =============================================================================
# 2. Emulated test vectors
# =============================================================================

def hexLine(value: int, bitWidth: int) -> str:
    '''`bitWidth` bits of two's complement as zero-padded upper-case hex — the
    line format of every generated testbench (`to_twos_complement_hex`).'''
    if bitWidth <= 0:
        raise ValueError('hexLine: bitWidth must be > 0')
    raw = value & ((1 << bitWidth) - 1)
    return f'{raw:0{(bitWidth + 3) // 4}X}'


def decodeHex(line: str, bitWidth: int, isSigned: bool) -> int:
    raw = int(line, 16) & ((1 << bitWidth) - 1)
    if isSigned and (raw >> (bitWidth - 1)) & 1:
        return raw - (1 << bitWidth)
    return raw


@dataclass
class PortStream:
    '''One port's values over the trials. A multi-lane port carries its lane
    widths (`laneWidths`, lane 0 lowest) and its trials as lane lists; on disk
    it is one packed word per line.'''

    name: str
    bitWidth: int
    isSigned: bool
    values: list = field(default_factory=list)          # int per trial, or list[int] per trial (lanes)
    laneWidths: list[int] | None = None
    laneSigned: list[bool] | None = None

    @staticmethod
    def scalar(name: str, bound: IntType, values: Iterable[int]) -> 'PortStream':
        return PortStream(name, max(bound.bitWidth, 1), bound.isSigned, list(values))

    @staticmethod
    def fromVector(name: str, vec: Vector) -> 'PortStream':
        return PortStream(name, vec.totalWidth, False, vec.trials(),
                          laneWidths=vec.widths, laneSigned=vec.signedness)

    @property
    def isVector(self) -> bool:
        return self.laneWidths is not None

    def vector(self) -> Vector:
        bounds = [IntType.signed(w) if s else IntType.unsigned(w)
                  for w, s in zip(self.laneWidths, self.laneSigned)]
        return Vector.fromBounds(bounds)

    def lines(self) -> list[str]:
        if self.isVector:
            proto = self.vector()
            return [hexLine(proto.pack(v), self.bitWidth) for v in self.values]
        return [hexLine(v, self.bitWidth) for v in self.values]

    def parse(self, lines: Iterable[str]) -> list:
        out = []
        proto = self.vector() if self.isVector else None
        for line in lines:
            line = line.strip()
            if not line:
                continue
            if proto is not None:
                out.append(proto.unpack(int(line, 16)))
            else:
                out.append(decodeHex(line, self.bitWidth, self.isSigned))
        return out


@dataclass
class TestVectorSet:
    '''Inputs and goldens for one generated design, in the testbench format.'''

    inputs: list[PortStream]
    outputs: list[PortStream]
    latency: int | None = None
    source: str = ''

    def __post_init__(self):
        sizes = {len(p.values) for p in self.inputs + self.outputs}
        if len(sizes) > 1:
            raise ValueError(f'TestVectorSet: ports carry different trial counts {sorted(sizes)}')

    @property
    def size(self) -> int:
        ports = self.inputs + self.outputs
        return len(ports[0].values) if ports else 0

    def port(self, name: str) -> PortStream:
        for p in self.inputs + self.outputs:
            if p.name == name:
                return p
        raise KeyError(name)

    def write(self, runDir) -> list[Path]:
        '''`<runDir>/testvectors/<port>.txt` for every port.'''
        d = Path(runDir) / TV_DIR
        d.mkdir(parents=True, exist_ok=True)
        out = []
        for p in self.inputs + self.outputs:
            path = d / f'{p.name}.txt'
            path.write_text(''.join(line + '\n' for line in p.lines()))
            out.append(path)
        return out

    def matchesFiles(self, runDir) -> list[str]:
        '''Ports whose file on disk differs from these values (empty when all agree).'''
        bad = []
        for p in self.inputs + self.outputs:
            path = Path(runDir) / TV_DIR / f'{p.name}.txt'
            if not path.is_file() or p.parse(path.read_text().splitlines()) != p.values:
                bad.append(p.name)
        return bad

    @staticmethod
    def read(runDir, template: 'TestVectorSet') -> 'TestVectorSet':
        '''Read files back using `template`'s port names and widths.'''
        def load(p: PortStream) -> PortStream:
            path = Path(runDir) / TV_DIR / f'{p.name}.txt'
            return PortStream(p.name, p.bitWidth, p.isSigned,
                              p.parse(path.read_text().splitlines()), p.laneWidths, p.laneSigned)
        return TestVectorSet([load(p) for p in template.inputs],
                             [load(p) for p in template.outputs], template.latency, template.source)

    def check(self, reference: Callable[[dict], dict],
              compare: Callable[[str, Any, Any], bool] | None = None) -> list[str]:
        '''Run `reference(inputs) -> outputs` trial by trial and list every
        disagreement. `inputs` maps each input port's name to that trial's
        value (or lane list); the reference returns the same for outputs.
        `compare(port, golden, ref)` defaults to equality; a modular check can
        pass e.g. congruence plus a range test.'''
        compare = compare or (lambda _n, a, b: a == b)
        errors: list[str] = []
        for t in range(self.size):
            ins = {p.name: p.values[t] for p in self.inputs}
            want = reference(ins)
            for p in self.outputs:
                if not compare(p.name, p.values[t], want[p.name]):
                    errors.append(f'trial {t} port {p.name}: golden {p.values[t]} vs reference '
                                  f'{want[p.name]} for inputs {ins}')
                    if len(errors) >= 20:
                        return errors
        return errors


# =============================================================================
# 3. Accurate hardware data
# =============================================================================

_UTIL_ROWS = {
    'lut': (r'CLB LUTs\*?', r'Slice LUTs\*?'),
    'ff': (r'Registers',),
    'lookahead8': (r'LOOKAHEAD8',),
    'dsp': (r'DSP Slices', r'DSPs'),
    'bram36': (r'Block RAM Tile',),
    'uram': (r'URAM',),
}
_WNS_RE = re.compile(r'^\s*WNS\(ns\).*?\n\s*[-\s]+\n\s*(-?\d+\.?\d*)\s+(-?\d+\.?\d*)', re.MULTILINE)
_CLOCK_RE = re.compile(r'^\s*(\w+)\s+\{[\d.\s]+\}\s+(\d+\.?\d*)\s+(\d+\.?\d*)\s*$', re.MULTILINE)


def _utilRow(text: str, label: str) -> float | None:
    m = re.search(r'^\|\s*' + label + r'\s*\|\s*(\d+\.?\d*)\s*\|', text, re.MULTILINE)
    return float(m.group(1)) if m else None


@dataclass
class HardwareRecord:
    '''Measured numbers for one implemented design.'''

    design: str
    operator: str = ''
    params: dict = field(default_factory=dict)
    stage: str = 'synth'                  # 'synth' | 'opt' | 'impl' | 'board'
    tool: str = ''
    part: str = ''
    clockNs: float | None = None
    lut: int | None = None
    ff: int | None = None
    dsp: int | None = None
    bram36: float | None = None
    uram: int | None = None
    lookahead8: int | None = None
    wnsNs: float | None = None
    latency: int | None = None
    model: dict = field(default_factory=dict)       # the model's estimate, for `compare`
    date: str = ''
    note: str = ''

    @property
    def achievedNs(self) -> float | None:
        '''Clock period the design would meet: target minus WNS.'''
        if self.clockNs is None or self.wnsNs is None:
            return None
        return self.clockNs - self.wnsNs

    @property
    def achievedFmaxMhz(self) -> float | None:
        ns = self.achievedNs
        return 1000.0 / ns if ns else None

    @property
    def met(self) -> bool | None:
        return None if self.wnsNs is None else self.wnsNs >= 0

    @staticmethod
    def fromVivadoReports(reportDir, design: str, stage: str = 'synth',
                          utilization: str = 'utilization.rpt',
                          timing: str = 'timing_summary.rpt', **kw) -> 'HardwareRecord':
        '''Parse a report directory (`run_remote_synth.py` / `run_remote_impl.py`
        pull-backs). Missing fields stay `None`.'''
        d = Path(reportDir)
        rec = HardwareRecord(design=design, stage=stage, date=time.strftime('%Y-%m-%d'), **kw)
        u = d / utilization
        if u.is_file():
            text = u.read_text(errors='replace')
            for key, labels in _UTIL_ROWS.items():
                for label in labels:
                    v = _utilRow(text, label)
                    if v is not None:
                        setattr(rec, key, v if key == 'bram36' else int(v))
                        break
            m = re.search(r'Tool Version\s*:\s*(Vivado v\.[\w.]+)', text)
            if m:
                rec.tool = m.group(1)
            m = re.search(r'Device\s*:\s*(\S+)', text)
            if m:
                rec.part = m.group(1)
        t = d / timing
        if t.is_file():
            text = t.read_text(errors='replace')
            m = _WNS_RE.search(text)
            if m:
                rec.wnsNs = float(m.group(1))
            m = _CLOCK_RE.search(text)
            if m:
                rec.clockNs = float(m.group(2))
        return rec

    def compare(self) -> dict:
        '''Measured against the model's estimate (`model`): per field the ratio
        measured / model, and the timing gap in ns.'''
        out: dict = {}
        for key in ('lut', 'dsp'):
            mv, hv = self.model.get(key), getattr(self, key)
            if mv and hv is not None:
                out[f'{key}_ratio'] = hv / mv
        if self.model.get('criticalPathNs') is not None and self.achievedNs is not None:
            out['path_gap_ns'] = self.achievedNs - self.model['criticalPathNs']
        if self.model.get('latency') is not None and self.latency is not None:
            out['latency_equal'] = self.model['latency'] == self.latency
        return out

    def to_dict(self) -> dict:
        return asdict(self)

    @staticmethod
    def from_dict(d: dict) -> 'HardwareRecord':
        return HardwareRecord(**d)


class HardwareDatabase:
    '''Records in a JSON-lines file: append, query, and the table a cost-model
    calibration or a design-space exploration reads.'''

    def __init__(self, path):
        self.path = Path(path)

    def append(self, rec: HardwareRecord) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with open(self.path, 'a', encoding='utf-8') as f:
            f.write(json.dumps(rec.to_dict(), default=str) + '\n')

    def records(self, **match) -> list[HardwareRecord]:
        if not self.path.is_file():
            return []
        out = []
        for line in self.path.read_text().splitlines():
            if not line.strip():
                continue
            r = HardwareRecord.from_dict(json.loads(line))
            if all(getattr(r, k, None) == v or r.params.get(k) == v for k, v in match.items()):
                out.append(r)
        return out

    def latest(self, design: str, stage: str | None = None) -> HardwareRecord | None:
        rs = [r for r in self.records(design=design) if stage is None or r.stage == stage]
        return rs[-1] if rs else None
