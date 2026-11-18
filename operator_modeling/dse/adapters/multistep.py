'''The multi-step (four-step and deeper) NTT for the design-space search: `MultiStepScheme` (P lanes, a frame of
N / P cycles, d >= 2 passes of unrolled sub-NTTs with lane-time transposes between them).

    enumerate(req)        every legal option combination (plain values)
    evaluate(req, params) CoreRecord from the build-free models (`MultiStepArea` through `scheme.area()`, the
                          scheme's own schedule for latency and interval); the ports are read from the module
                          header the RTL generator itself writes for the point (generated in memory, no file)
    build(record, outdir) RTL and the self-checking testbench of a record
    quick(req, params)    (interval, butterflies) from the lane count and the pass sizes
    count(req, full)      size of the option product without listing it (full=True: every value of FULL)

Options. DEFAULTS gives the values `enumerate` tries, FULL every value the generator takes (numeric options: a
sample); `req.options['multistep']` replaces any list. The structural options are complete in DEFAULTS; the
options marked (*) stay at the generator's default there, because the full product is far too large to price
in a night (see `count(req, full=True)`).

    lanes           P: powers of two, 4 .. min(N, req.maxLanes)
    sizes           the sub-NTT sizes in pass order: every ordered split of N into d >= 2 powers of two, each
                    4 .. P (allowed values: lists such as [64, 64]); maxPasses limits d (None: no limit)
    form            'twist' (multipliers between the passes) | 'folded' (TP-NTT: the factors in the stage twiddles
                    of every pass after the first, one output stage for the inverse) | 'folded_gs' (TP-NTT's
                    inverse too: unified CT/GS passes, no stage between or after). The generator's 'auto' is a
                    rule that picks one of these; both are listed instead. All three have RTL.
    twists          'merged' | 'bank' (negacyclic, form 'twist': the twist in the first/last stage or its own bank)
    twiddleSource   factors between the passes: 'rom' (a table per lane class) | 'otf' (product of two tables) |
                    'tree' (multiplier tree from two stored values). One value for every stage; a list (one per
                    stage, d - 1 entries) may be given through the options. 'auto' is a rule, not listed.
                    Not listed for 'folded_gs' (it has no such stage).
    tableSupply     'core' (tables inside) | 'stream' (every table of the top outside, ports tw_addr_k / tw_data_k)
    loadable        every table a RAM written through ld_wdata, one modulus at a time (not with 'stream')
    modulus         'fixed' (q built in, one modulus, form 'twist') | 'table' (constants of the listed moduli
                    resident, MIDX per polynomial) | 'odd' (datapath for any odd modulus of the width) |
                    'friendly' (datapath for q = qH 2^v + 1). Without `loadable` the tables of every listed
                    modulus are resident and the modulus and direction may change per polynomial.
    reduction       'barrett' | 'mont' | 'wlm' | 'shoup' (Shoup multipliers in the butterflies)
    unified         the unified CT/GS butterfly in the sub-NTTs (direction 'both', not 'fixed')
    direction       the core's directions: the request's, or 'both' when one direction is asked
    inverseScale    'stage' | 'output' ('none' leaves N^-1 to the user: FULL only)
    outputOrder (*) 'pass' | 'block' | 'natural'            inputLayout (*) 'block' | 'pass'
    outReady (*)    output backpressure (in_ready / out_ready, an output FIFO); outFifoDepth (*) None
    dspFraction (*) None | share of the full DSP count (`setDspBudget`); dspTotal (*) None | a DSP count.
                    budgetRule only matters with form 'auto' and is not an option here.
    memStyle (*)    'auto' | 'bram' | 'uram'                swapPolicy (*) 'recent' | 'low'
    portAlign (*)   folded forms: 'data' | 'address'        ramLatency (*) 2, 3, ..
    crossRegs (*)   register stages between blocks, crossAt (*) 'all' | 'mid'
    tableShare (*), romStyleMaxDepth (*)  generator tuning (8, 64)
    transpose       'bmb' only: 'mbm' is a model without RTL (accepted through the options, flagged, `build` refuses)

Cycles. interval = F = N / P (exact). latency = pipeline latency + F - 1 (first input beat to last output
beat; exact, the testbench checks every beat at its cycle). A loadable core holds one modulus and one
direction per job: a modulus change costs drain (pipeline latency) + 1 (ld_rst) + load words + 4 (settle), a
direction change alone drain + 4 (the rule of `MultiStepNTT._testData`, as simulated).
'''
from __future__ import annotations

import contextlib
import copy
import hashlib
import io
import itertools
import json
import os
import re
import sys

from ..record import CoreRecord, Port

_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
for _p in (_ROOT, os.path.join(_ROOT, 'versal_arith')):          # the run scripts and `rtl_gen`
    if _p not in sys.path:
        sys.path.append(_p)

ARCH = 'multistep'
#: xsim 2026-11-15, three sizes, resident and loadable: every output beat is X (dse_2026-11-15/multistep/check/fo_rom_shoup)
FOLDED_SHOUP = ("RTL fails: form 'folded' with Shoup butterflies gives X on every output in xsim (the generator's "
                "gate covers Shoup in the twist form only); model numbers only, build() refuses it")
REDUCTIONS = ('barrett', 'mont', 'wlm', 'shoup')
#: modulus modes that a stated modulus form opens (Requirements.modulusForm), and the reduction of each
FORM_MODES = {'kred': 'kred', 'pseudomersenne': 'solinas'}
from .. import slots
from ..dsplimit import binds, totalOf       # noqa: E402
_FORM_OF = {'kred': 'kred', 'pseudomersenne': 'pseudo_mersenne'}      # mode -> Requirements.modulusForm
LOAD_SETTLE = 4

#: the values `enumerate` tries (lanes, sizes, direction follow the requirements)
DEFAULTS = {
    'maxPasses': [None],
    'form': ['twist', 'folded', 'folded_gs'],
    'twists': ['merged', 'bank'],
    'twiddleSource': ['rom', 'otf', 'tree'],
    'tableSupply': ['core', 'stream'],
    'loadable': [False, True],
    'subInputRegister': [False],                    # a register in front of every butterfly of the small NTTs
                                                    # (operands and twiddle): [False, True] to search both
    'slotMode': ['resident', 'rotate'],             # run-time moduli with tables inside (dse/slots.py)
    'loadLanes': ['auto'],                          # load words per cycle, slotMode 'rotate'. 'auto': the fewest
                                                    # with which a load fits one polynomial time; or numbers
    'modulus': ['fixed', 'table', 'odd', 'friendly'],
    'reduction': list(REDUCTIONS),
    'unified': [False, True],
    'inverseScale': ['stage', 'output'],
    'outputOrder': ['pass'],
    'inputLayout': ['block'],
    'outReady': [False],
    'outFifoDepth': [None],
    'dspFraction': [None],
    'dspTotal': [None],
    'memStyle': ['auto'],
    'swapPolicy': ['recent'],
    'portAlign': ['data'],
    'ramLatency': [2],
    'crossRegs': [0],
    'crossAt': ['all'],
    'tableShare': [8],
    'romStyleMaxDepth': [64],
    'transpose': ['bmb'],
}
#: every value the generator takes (numeric options: a sample of values)
FULL = dict(DEFAULTS, **{
    'inverseScale': ['stage', 'output', 'none'],
    'outputOrder': ['pass', 'block', 'natural'],
    'inputLayout': ['block', 'pass'],
    'outReady': [False, True],
    'dspFraction': [None, 0.75, 0.5, 0.25],
    'memStyle': ['auto', 'bram', 'uram'],
    'swapPolicy': ['recent', 'low'],
    'portAlign': ['data', 'address'],
    'ramLatency': [2, 3],
    'crossRegs': [0, 1, 2],
    'crossAt': ['all', 'mid'],
})
PARAM_ORDER = ('lanes', 'sizes', 'form', 'twists', 'twiddleSource', 'tableSupply', 'loadable', 'modulus',
               'reduction', 'unified', 'direction', 'inverseScale', 'outputOrder', 'inputLayout', 'outReady',
               'outFifoDepth', 'dspFraction', 'dspTotal', 'memStyle', 'swapPolicy', 'portAlign', 'ramLatency',
               'crossRegs', 'crossAt', 'tableShare', 'romStyleMaxDepth', 'transpose', 'loadMod', 'slotMode',
               'loadLanes', 'loadByDir', 'subInputRegister')
#: ports that carry no polynomial data: clock, reset, handshakes, the strobes of the load port
CONTROL = ('clk', 'rst', 'in_valid', 'in_ready', 'out_valid', 'out_ready', 'ld_rst', 'ld_wen', 'ld_slot', 'ld_dir')

NOTE = ('MultiStepArea, build-free. Against 51 routed cores at 350 MHz (overnight_2026-11-14/fourstep): full-DSP '
        'rows LUT within 4.3 %, FF within 2.9 %, area units within 0.8 %; DSP and URAM exact, BRAM36 exact on 48 '
        'of 51. Interval and pipeline latency are exact (xsim checks every beat at its cycle).')


def _quiet(fn):
    with contextlib.redirect_stdout(io.StringIO()):
        return fn()


_HEAP = {}
_MULT = {}
_COUNTS = {}
#: identical butterflies of a small transform are estimated once and reused by every core that holds that
#: transform with the same DSP split (the models only; the RTL is generated by `build`, outside `_memo`).
#: Checked 2026-11-17 on 40 points of the Allam search: every record field equal (ntt_hw/experiments/dse_speed_2026-11-17).
SHARE_BU = True


@contextlib.contextmanager
def _memo():
    '''While the models run, `Datapath._heapPlan` (a pure function of a node's terms, width and name) and
    `Datapath.schedule` (asked again by every latency() call of a butterfly) are answered from tables. Both are
    restored on exit; the results are the same (checked with `model(..., memo=False)`), a point of N = 2^16
    takes a fraction of the time.'''
    from ...core.datapath import Datapath
    orig = Datapath._heapPlan
    # 2026-11-16: equal multipliers are designed once (across butterflies and points of this process), and large
    # tables get no values (a point of N = 2^16 spent 75 of 118 s on 16.8 M modular powers for table words and
    # 31 s on 1,450 designs of a handful of multipliers)
    from ...multiplier.DspMultiplierScheme import DspMultiplierScheme
    from ...ntt.multistep.MultiStepScheme import MultiStepScheme
    oldShared, oldMax = DspMultiplierScheme.SHARED, MultiStepScheme.PRICE_VALUES_MAX
    DspMultiplierScheme.SHARED = _MULT
    from ...ntt.dataflow import StreamingNTTScheme as _S
    oldBu = _S.SHARE_IDENTICAL_BU
    _S.SHARE_IDENTICAL_BU = 'global' if SHARE_BU else oldBu
    MultiStepScheme.PRICE_VALUES_MAX = 1024

    def plan(self, node):
        try:
            key = (tuple(node.terms), node.bitWidth, node.name)
            hash(key)
        except TypeError:
            return orig(self, node)
        if key not in _HEAP:
            _HEAP[key] = orig(self, node)
        return _HEAP[key]
    origS = Datapath.schedule

    def sched(self, pipelineStages=1, targetFmaxMhz=None, absorbSmall=True):
        # the same datapath object is scheduled again by every latency() call of its butterfly
        if isinstance(pipelineStages, dict):
            return origS(self, pipelineStages, targetFmaxMhz, absorbSmall)
        memo = self.__dict__.setdefault('_dseSchedules', {})
        key = (pipelineStages, targetFmaxMhz, absorbSmall, len(self.nodes))
        if key not in memo:
            memo[key] = origS(self, pipelineStages, targetFmaxMhz, absorbSmall)
        return memo[key]
    origR = Datapath.resources

    def res(self, schedule=None, *a, **k):
        # the resources of one datapath under one schedule are asked again by every pass that holds the butterfly
        if a or k or schedule is None or not SHARE_BU:
            return origR(self, schedule, *a, **k)
        memo = self.__dict__.setdefault('_dseResources', {})
        key = (id(schedule), len(self.nodes))
        if key not in memo:
            memo[key] = (schedule, origR(self, schedule))      # the schedule is kept, so its id is not reused
        return copy.deepcopy(memo[key][1])
    from ...multiplier import dspcount as _DC
    origC = _DC.dspMultiplierCounts

    def counts(scheme, lo=0, hi=None):
        # the cells of one DSP multiplier depend on the multiplier alone: every plain attribute of its scheme
        # (widths, signs, budget, clock, name, ...) and the bits that are read
        if not SHARE_BU:
            return origC(scheme, lo, hi)
        try:
            key = (type(scheme).__name__, scheme._searchKey(), lo, hi,
                   tuple(sorted((k, v) for k, v in scheme.__dict__.items()
                                if isinstance(v, (int, float, str, bool, type(None))))))
            hash(key)
        except Exception:
            return origC(scheme, lo, hi)
        if key not in _COUNTS:
            _COUNTS[key] = origC(scheme, lo, hi)
        return copy.deepcopy(_COUNTS[key])
    _DC.dspMultiplierCounts = counts
    Datapath._heapPlan = plan
    Datapath.schedule = sched
    Datapath.resources = res
    try:
        yield
    finally:
        Datapath._heapPlan = orig
        Datapath.schedule = origS
        Datapath.resources = origR
        _DC.dspMultiplierCounts = origC
        DspMultiplierScheme.SHARED, MultiStepScheme.PRICE_VALUES_MAX = oldShared, oldMax
        _S.SHARE_IDENTICAL_BU = oldBu


def _log2(x: int) -> int:
    return x.bit_length() - 1


def _val2(x: int) -> int:
    return (x & -x).bit_length() - 1


def _info(req) -> dict:
    '''The part of the requirements a record must carry to be built again.'''
    return {'n': req.n, 'moduli': list(req.moduli), 'qBits': req.width, 'M': req.M, 'form': req.form,
            'negacyclic': req.transform == 'negacyclic', 'direction': req.direction, 'clockMhz': req.clockMhz}


_PRIMES = {}


def moduliOf(info: dict) -> list[int]:
    '''The request's moduli, or (only the width given: run-time moduli) test primes of that width.'''
    if info['moduli']:
        return list(info['moduli'])
    form = info.get('form') or {'kind': 'ntt'}
    M = info.get('slotsK') or max(2, info['M'])         # slots that rotate: one stand-in per slot
    key = (info['qBits'], info['n'], info['negacyclic'], M, tuple(sorted(form.items())))
    order = info['n'] * (2 if info['negacyclic'] else 1)
    if key not in _PRIMES and form['kind'] != 'ntt':        # stand-ins must have the form the user states
        from .. import modform
        _PRIMES[key] = modform.samplePrimes(form, info['qBits'], order, M)
    if key not in _PRIMES:
        import runMultiStep as R
        _PRIMES[key] = R.primes(info['qBits'], _log2(order) - 1, M, seed0=info['qBits'])
    return _PRIMES[key]


def butterflyOf(red: str) -> dict:
    import runModularNTT as rm
    if red == 'shoup':
        return dict(multiplierKind='shoup')
    return dict(multiplierKind='reduction', reduction=rm.REDUCTIONS[red.split('-')[0]],
                reductionArgs=(rm.UNITS.get(red, ({},))[0] or {}))


def familyOf(mode: str, moduli, width: int, loadable: bool = False, form: dict | None = None,
             order: int | None = None):
    '''None ('fixed', 'table': the scheme's own choice), or the run-time family of 'odd' / 'friendly' / 'kred' /
    'pseudomersenne'. `form` and `order` are given when the moduli are not listed (`moduli` are then stand-ins):
    the family follows the stated modulus form. Raises ValueError when the moduli are not of the family.'''
    from ...modmult.ModulusFamily import ModulusFamily as MF
    from .. import modform
    if mode in FORM_MODES:
        fam = modform.family(form or {'kind': 'ntt'}, FORM_MODES[mode], width, order) if order else None
        if fam is None:
            raise ValueError(f'{mode}: the moduli are not stated to have this form')
        return fam
    if mode == 'friendly' and order:
        v = modform.friendlyV(form or {'kind': 'ntt'}, width, order)
        return MF.friendly(v, width - v)
    if mode == 'fixed' or (mode == 'table' and not loadable):
        return None
    if mode == 'table':
        return MF.table(list(moduli))               # loadable: the scheme wants the family named
    if mode == 'odd':
        return MF.odd(width)
    if mode == 'friendly':
        if any(q.bit_length() != width for q in moduli):
            raise ValueError('friendly: the moduli differ in width')
        v = min(_val2(q - 1) for q in moduli)
        if width - v < 1:
            raise ValueError('friendly: no high part')
        return MF.friendly(v, width - v)
    raise ValueError(f'modulus {mode!r}')


def splits(n: int, maxLanes: int, maxPasses=None) -> list[tuple]:
    '''Every (P, sizes): P a power of two 4 .. min(n, maxLanes), sizes an ordered split of n into d >= 2 powers of
    two, each 4 .. P.'''
    m = _log2(n)
    out = []
    p = 2
    while (1 << p) <= min(n, maxLanes):
        comps = []

        def rec(rest, acc):
            if rest == 0:
                if len(acc) >= 2:
                    comps.append([1 << a for a in acc])
                return
            if maxPasses and len(acc) >= maxPasses:
                return
            for a in range(2, min(p, rest) + 1):
                if rest - a == 0 or rest - a >= 2:
                    rec(rest - a, acc + [a])
        rec(m, [])
        out += [(1 << p, c) for c in comps]
        p += 1
    return out


def scheme(info: dict, params: dict, name: str = 'ms'):
    '''The MultiStepScheme of a point. ValueError: the combination is not legal.'''
    from ...ntt.multistep.MultiStepScheme import MultiStepScheme
    mods = moduliOf(info)
    W = max(q.bit_length() for q in mods)
    mode = params['modulus']
    kw = dict(N=info['n'], sizes=list(params['sizes']), lanes=params['lanes'], negacyclic=info['negacyclic'],
              direction=params['direction'], twists=params['twists'], twiddleSource=params['twiddleSource'],
              butterfly=butterflyOf(params['reduction']), targetFmaxMhz=info['clockMhz'],
              inverseScale=params['inverseScale'], swapPolicy=params['swapPolicy'],
              subArgs=(dict(**({'unified': True} if params['unified'] else {}),
                            **({'inputRegister': True} if params.get('subInputRegister') else {})) or None),
              tableShare=params['tableShare'],
              romStyleMaxDepth=params['romStyleMaxDepth'], inputLayout=params['inputLayout'], form=params['form'],
              memStyle=params['memStyle'], dspFraction=params['dspFraction'], dspTotal=params['dspTotal'],
              loadable=params['loadable'], portAlign=params['portAlign'], ramLatency=params['ramLatency'],
              crossRegs=params['crossRegs'], crossAt=params['crossAt'], tableSupply=params['tableSupply'],
              outReady=params['outReady'], outFifoDepth=params['outFifoDepth'], outputOrder=params['outputOrder'],
              transpose=params['transpose'])
    if params.get('loadMod'):
        kw['loadableModuli'] = True
        if params.get('slotMode') == 'rotate':
            kw.update(slotManager=True, loadLanes=params.get('loadLanes', 1),
                      loadByDirection=bool(params.get('loadByDir')))
    if mode == 'fixed':
        if len(mods) != 1 or info['M'] != 1:
            raise ValueError('fixed: one modulus only')
        kw['q'] = mods[0]
    else:
        kw['moduli'] = mods
        known = bool(info['moduli'])
        kw['family'] = familyOf(mode, mods, W, params['loadable'], None if known else info.get('form'),
                                None if known else info['n'] * (2 if info['negacyclic'] else 1))
    return _quiet(lambda: MultiStepScheme(name, **kw))


# --- the generator's own port list -------------------------------------------------------------------

class _Os:
    '''`os` for the generator while it writes into memory.'''
    path = os.path

    @staticmethod
    def makedirs(*a, **k):
        pass


class _Mem(io.StringIO):
    def __init__(self, store, path):
        super().__init__()
        self._store, self._path = store, path

    def __exit__(self, *a):
        self._store[os.path.basename(self._path)] = self.getvalue()
        return super().__exit__(*a)


def generateTop(spec: dict) -> dict:
    '''Runs `rtl_gen.multistep.MultiStep_RTL_gen` on the spec with its files kept in memory: {file name: text}.
    The generator also completes the spec (table address widths, `_ext`: the outside tables of 'stream').'''
    import rtl_gen.multistep as G
    store = {}
    G.open = lambda p, m='r': _Mem(store, p)
    G.os = _Os
    try:
        _quiet(lambda: G.MultiStep_RTL_gen(spec, None))
    finally:
        del G.open
        G.os = os
    return store


_PORT = re.compile(r'^\s*(input|output)\s+logic\s*(?:\[(\d+):0\])?\s*(\w+)\s*,?\s*$')
_CNT = re.compile(r'_cn(?:t|\d+)\[(\d+)\]')


def headerPorts(text: str, module: str) -> list[tuple]:
    '''[(direction, name, width)] of `module` in SystemVerilog text (the generator's one-port-per-line header).'''
    i = text.index(f'module {module} (')
    out = []
    for line in text[i:text.index(');', i)].split('\n')[1:]:
        m = _PORT.match(line)
        if m:
            out.append((m.group(1), m.group(3), int(m.group(2)) + 1 if m.group(2) else 1))
        elif line.strip():
            raise ValueError(f'port line not understood: {line!r}')
    return out


def portList(s, spec: dict, store: dict, name: str, rot: bool = False) -> list[dict]:
    '''Every declared port of the top module with its kind and beats per polynomial (kind None: control).
    {'name', 'dir', 'width', 'kind', 'beats', 'perLoad'}'''
    F = s.F
    top = store[f'{name}.sv']
    LD = spec.get('load')
    words = LD['words'] if LD else 0
    qports = {p for p, _ in LD['qports']} if LD else set()
    core = store.get(f'{name}_core.sv', top)
    addr = {}
    for line in core.split('\n'):
        if 'assign tw_addr_' in line:
            k = int(line.split('assign tw_addr_')[1].split(' ')[0])
            bits = [int(x) for x in _CNT.findall(line.split(';')[0])]
            # the address follows the frame counter: it changes every 2^(lowest counter bit) beats; with no
            # counter bit it holds for the polynomial (one word per polynomial, when the modulus or DIR changes)
            addr[k] = max(1, F >> min(bits)) if bits else 1
    out = []
    for d, nm, w in headerPorts(top, name):
        kind, beats, per = None, 0, False
        if nm in CONTROL:
            pass
        elif rot and nm == 'MIDX':          # the manager names the slot; the outside announces a key per polynomial
            out.append({'name': 'ann_valid', 'dir': d, 'width': 1, 'kind': None, 'beats': 0, 'perLoad': False})
            nm, w, kind, beats = 'ann_key', slots.KEY_BITS, 'record_stream', 1
        elif rot and nm == 'ld_wdata':      # a load for every polynomial that brings a new modulus
            kind, beats = 'table_load', words
        elif nm.startswith('x_in_'):
            kind, beats = 'data_in', F
        elif nm.startswith('y_out_'):
            kind, beats = 'data_out', F
        elif nm in ('MIDX', 'midx_out', 'dir_out') or (nm == 'DIR' and (not LD or LD.get('slots'))):
            kind, beats = 'record_stream', F           # the tag travels with every beat
        elif nm == 'DIR':
            kind, beats, per = 'table_load', 1, True   # loadable: set once per job
        elif nm == 'ld_wdata':
            kind, beats, per = 'table_load', words, True
        elif nm in qports:
            kind, beats, per = 'table_load', 1, True   # the modulus constants, set once per load
        elif nm.startswith('mq_'):
            kind, beats = 'record_stream', F           # the modulus constants travel with every beat
        elif nm.startswith('tw_addr_') or nm.startswith('tw_data_'):
            kind, beats = 'twiddle_stream', addr[int(nm.rsplit('_', 1)[1])]
        else:
            raise ValueError(f'{name}: port {nm} of the generated module has no rule in the adapter')
        out.append({'name': nm, 'dir': d, 'width': w, 'kind': kind, 'beats': beats, 'perLoad': per})
    return out


def _prefix(nm: str) -> str:
    m = re.match(r'^(x_in_|y_out_|tw_addr_|tw_data_)\d+$', nm)
    return m.group(1) if m else nm


def _group(plist: list[dict]) -> list[Port]:
    g = {}
    for p in plist:
        if p['kind'] is None:
            continue
        k = (p['kind'], _prefix(p['name']), p['width'], p['beats'], p['perLoad'])
        g[k] = g.get(k, 0) + 1
    return [Port(kind=k[0], widthBits=k[2], count=c, beatsPerNtt=float(k[3]), perLoad=k[4], name=k[1])
            for k, c in g.items()]


# --- words ---------------------------------------------------------------------------------------------

def _tables(spec: dict) -> list[dict]:
    out = []
    for b in spec['blocks']:
        if b['kind'] == 'twiddle':
            out += list(b.get('tables') or [])
        elif b['kind'] == 'pass' and b.get('ports'):
            out += list(b['ports'].get('tables') or [])
    return out


def twiddleWords(s, spec: dict, params: dict) -> dict:
    '''{'top': words of the top's tables as built (every modulus and direction), 'perModDir': the same tables'
    words one modulus and one direction need, 'sub': constants of the sub-NTTs' own stages (formula, except
    loadable: the load image), 'load': words of one load}'''
    tabs = _tables(spec)
    top = sum(int(t.get('depth') or (1 << t.get('abits', 0))) for t in tabs)
    per = 0
    for d in s.dirs:
        per = max(per, sum(1 << len(t.get('bits') or []) for t in tabs if t.get('dir') in (None, d, False)))
    LD = spec.get('load')
    if LD and LD.get('slots'):          # run-time moduli: one block per slot in every table, one slot per load
        return {'top': LD['words'] * len(s.moduli), 'perModDir': per, 'sub': 0, 'load': LD['words']}
    if LD:
        sub = sum(g.get('len', 0) for g in LD['segments'])
        return {'top': LD['words'] - sub, 'perModDir': per, 'sub': sub, 'load': LD['words']}
    resident = len(s.moduli) if s.perFrame else 1
    sub = 0
    for b in spec['blocks']:
        if b['kind'] == 'pass' and not b.get('ports'):
            sub += resident * len(s.dirs) * (b['n'] - 1) * (2 if params['reduction'] == 'shoup' else 1)
    return {'top': top, 'perModDir': per, 'sub': sub, 'load': 0}


# --- the search ----------------------------------------------------------------------------------------

def _lists(req) -> dict:
    opt = dict(DEFAULTS)
    for k, v in (req.options.get(ARCH, {}) or {}).items():
        opt[k] = list(v)
    return opt


def _directions(req, opt) -> list[str]:
    ds = [req.direction] if req.direction == 'both' else [req.direction, 'both']
    return [d for d in ds if d in opt.get('direction', ds)]


def _splits(req, opt) -> list[tuple]:
    out = []
    for mp in opt['maxPasses']:
        for sp in splits(req.n, req.maxLanes, mp):
            if sp not in out:
                out.append(sp)
    if 'lanes' in opt:
        out = [x for x in out if x[0] in opt['lanes']]
    if 'sizes' in opt:
        allowed = [list(z) for z in opt['sizes']]
        out = [x for x in out if x[1] in allowed]
    return out


def _variants(req, opt, direction: str, d: int = 2):
    '''The option combinations that do not depend on (P, sizes), known-illegal ones left out (the rules of the
    scheme's constructor; `evaluate` still decides).'''
    nega = req.transform == 'negacyclic'
    known = bool(req.moduli)
    inv = direction != 'forward'
    for form in opt['form']:
        if form == 'folded_gs' and direction == 'forward':
            continue                              # both: the unified unit; inverse: its GS half alone (2026-11-16)
        twl = opt['twists'] if (form == 'twist' and nega) else ['merged']
        if form == 'folded_gs':
            srcl = ['rom']                        # no stage between or after the passes: the source has no effect
        else:
            srcl = [x for x in opt['twiddleSource'] if isinstance(x, str) or len(x) == d - 1]
        iscl = [x for x in opt['inverseScale'] if not (form == 'folded_gs' and x == 'output')] if inv else ['stage']
        pal = opt['portAlign'] if form != 'twist' else ['data']
        for supply, loadable in itertools.product(opt['tableSupply'], opt['loadable']):
            if loadable and supply == 'stream':
                continue
            # moduli not listed: a loadable core takes one at a time (drain and load on a change). Every form also
            # changes the modulus per polynomial with no idle cycle (loadMod, MultiStepScheme loadableModuli): the
            # constants come with each polynomial, and the tables are RAMs with one block per slot, filled through
            # the load port while other polynomials run (with supply 'stream' the top's tables are outside)
            lm = not known and not loadable
            if not known and not loadable and not lm:
                continue
            given = req.options.get(ARCH, {}) or {}
            formModes = [m for m in FORM_MODES if _FORM_OF[m] == req.modulusForm and not known
                         and ('modulus' not in given or m in given['modulus'])]
            for mode in list(opt['modulus']) + formModes:
                if mode == 'fixed' and (req.M != 1 or form != 'twist' or loadable or not known):
                    continue
                if not known and mode == 'table':
                    continue
                if lm and mode == 'fixed':
                    continue
                reds = [r for r in opt['reduction'] if not (r == 'wlm' and mode == 'table')]   # no run-time form
                if mode in FORM_MODES:
                    reds = [FORM_MODES[mode]]     # the reduction that uses the form (the others gain nothing)
                for uni in opt['unified']:
                    if uni and (direction != 'both' or mode == 'fixed' or loadable):
                        continue
                    redl = [r for r in reds if not (r == 'shoup' and (uni or form == 'folded_gs'))]
                    rest = [twl, srcl, redl, iscl, opt['outputOrder'], opt['inputLayout'],
                            opt['outReady'], opt['dspFraction'], opt['dspTotal'], opt['memStyle'],
                            opt['swapPolicy'], pal, opt['ramLatency'], opt['crossRegs'], opt['crossAt'],
                            opt['tableShare'], opt['romStyleMaxDepth'], opt['transpose']]
                    for (tw, src, red, isc, oo, il, rdy, df, dt, ms, sw, pa, rl, cr, ca, ts, rs, tr) in \
                            itertools.product(*rest):
                        if df is not None and dt is not None:
                            continue
                        if dt is None:
                            dt = totalOf(req, df)       # the user's DSP limit is the budget (dsplimit.py)
                        if uni and isc == 'output':
                            continue              # the unified butterfly scales per stage or not at all
                        if cr == 0 and ca != opt['crossAt'][0]:
                            continue              # no register stage: where to put it has no effect
                        for fd in (opt['outFifoDepth'] if rdy else [None]):
                            yield {'form': form, 'twists': tw, 'twiddleSource': src, 'tableSupply': supply,
                                   'loadable': loadable, 'modulus': mode, 'reduction': red, 'unified': uni,
                                   'direction': direction, 'inverseScale': isc, 'outputOrder': oo,
                                   'inputLayout': il, 'outReady': rdy, 'outFifoDepth': fd, 'dspFraction': df,
                                   'dspTotal': dt, 'memStyle': ms, 'swapPolicy': sw, 'portAlign': pa,
                                   'ramLatency': rl, 'crossRegs': cr, 'crossAt': ca, 'tableShare': ts,
                                   'romStyleMaxDepth': rs, 'transpose': tr, 'loadMod': lm}


def enumerate(req):
    '''Every option combination of the lists (DEFAULTS, or `req.options['multistep']`). One core cannot do the
    cyclic and the negacyclic transform: nothing for transform 'both'.'''
    if req.transform == 'both' or req.n < 16:
        return
    opt = _lists(req)
    sp = _splits(req, opt)
    perStage = any(not isinstance(x, str) for x in opt['twiddleSource'])
    for direction in _directions(req, opt):
        cache = {}
        for P, sizes in sp:
            d = len(sizes) if perStage else 2
            if d not in cache:
                cache[d] = list(_variants(req, opt, direction, d))
            for v0 in cache[d]:
                # both twins are priced unless the request fixes the option: the search keeps both on the front
                # (dse/search.py pareto), since the register buys timing margin that the objectives do not see
                for sir in ([False, True] if opt['subInputRegister'] == [False] else opt['subInputRegister']):
                    v = dict(v0, lanes=P, sizes=list(sizes), slotMode='resident', loadLanes=1, loadByDir=False,
                             subInputRegister=bool(sir))
                    inside = v['loadMod'] and v['tableSupply'] == 'core'
                    modes = [m for m in slots.modes(req) if m in opt['slotMode']] if inside else ['resident']
                    if 'resident' in modes:
                        yield v
                    if 'rotate' in modes:
                        # the slots rotate: one point per load width; the number of slots follows from the
                        # pipeline and the load (evaluate). With both directions a load fills one direction.
                        for R in opt['loadLanes']:
                            yield dict(v, slotMode='rotate', loadLanes=R, loadByDir=direction == 'both')


def count(req, full: bool = False) -> int:
    '''Points `enumerate` lists (full=True: with every value of FULL, the product that is not listed).'''
    if req.transform == 'both' or req.n < 16:
        return 0
    opt = dict(FULL) if full else _lists(req)
    if full:
        for k in ('lanes', 'sizes'):
            if k in (req.options.get(ARCH, {}) or {}):
                opt[k] = req.options[ARCH][k]
    n = len(_splits(req, opt))
    return sum(n * sum(1 for _ in _variants(req, opt, d)) for d in _directions(req, opt))


def sizing(req, params):
    """(family, size): the size is the lane count (butterflies = log2(n) lanes / 2 for every split). A family is a
    form with a modulus mode."""
    return (params['form'], params['modulus']), params['lanes']


def quickLatency(req, params):
    """A lower bound of the latency (first input beat to last output beat): n / lanes input beats, then as many
    output beats, which cannot start before the last input beat."""
    return 2 * (req.n // params['lanes']) - 1


def sideKinds(req, params) -> set:
    """Kinds of side traffic this point surely has, from its table supply (never more than the model lists)."""
    return ({'twiddle_stream'} if params['tableSupply'] == 'stream' else set()) \
        | ({'table_load'} if (params['loadable'] or (params.get('loadMod') and params['tableSupply'] == 'core')) else set()) \
        | ({'record_stream'} if params.get('loadMod') else set())


def twinBase(req, params):
    """The point without the register in front of every butterfly, for a point that has it. The register adds
    flip-flops and latency and removes nothing (60 + 40 pairs of the Allam search, 2026-11-17: never smaller in LUT,
    FF, DSP, BRAM, URAM, latency or the cost of a modulus change; same interval), so the variant meets a request
    only if its base does."""
    if params.get('subInputRegister'):
        return dict(params, subInputRegister=False)
    return None


def quickService(req, params) -> list:
    """The services of the request that this point lacks, known from its options: `evaluate` sets
    perPolyModulus = (modulus mode is not 'fixed' and the core is not loadable) and
    perPolyDirection = (direction 'both' and not loadable); output order and backpressure are options.
    A point named here is rejected by `Requirements.check` after it is estimated, so it is not estimated."""
    p = _complete(params)
    why = []
    if req.perPolyModulus and req.M > 1 and not (p['modulus'] != 'fixed' and not p['loadable']):
        why.append('cannot change the modulus per polynomial')
    if req.perPolyDirection and req.direction == 'both' and not (p['direction'] == 'both' and not p['loadable']):
        why.append('cannot change the direction per polynomial')
    if req.outputOrder == 'natural' and p.get('outputOrder') != 'natural':
        why.append('output not in natural order')
    if req.outputBackpressure and not p.get('outReady'):
        why.append('no output backpressure')
    return why


def quick(req, params):
    return req.n // params['lanes'], sum((req.n // z) * (z // 2) * _log2(z) // (req.n // params['lanes'])
                                         for z in params['sizes'])


def pointName(info: dict, params: dict) -> str:
    p = params
    bits = [f"ms_n{info['n']}_p{p['lanes']}", 'x'.join(str(z) for z in p['sizes']),
            {'twist': 'tw', 'folded': 'fo', 'folded_gs': 'gs'}[p['form']],
            p['twiddleSource'] if isinstance(p['twiddleSource'], str) else '-'.join(p['twiddleSource']),
            p['modulus'][:3], p['reduction']]
    bits += [t for c, t in ((p['twists'] == 'bank', 'bank'), (p['tableSupply'] == 'stream', 'str'),
                            (p['loadable'], 'ld'), (p.get('loadMod'), 'slots'),
                            (p.get('slotMode') == 'rotate', f"rot{p.get('loadLanes')}"),
                            (p.get('subInputRegister'), 'sir'), (p['unified'], 'uni'),
                            (p['direction'] != 'both', p['direction'][:3]),
                            (p['inverseScale'] != 'stage', 'is' + p['inverseScale'][:3]),
                            (p['outputOrder'] != 'pass', p['outputOrder'][:3]),
                            (p['inputLayout'] != 'block', 'inpass'), (p['outReady'], 'rdy'),
                            (p['dspFraction'] is not None, f"dsp{int(100 * (p['dspFraction'] or 0))}"),
                            (p['dspTotal'] is not None, f"dspt{p['dspTotal']}")) if c]
    rest = {k: p[k] for k in ('outFifoDepth', 'memStyle', 'swapPolicy', 'portAlign', 'ramLatency', 'crossRegs',
                              'crossAt', 'tableShare', 'romStyleMaxDepth', 'transpose') if p[k] != DEFAULTS[k][0]}
    if rest:
        bits.append('o' + hashlib.sha1(json.dumps(rest, sort_keys=True).encode()).hexdigest()[:6])
    return '_'.join(bits)


def _complete(params: dict) -> dict:
    p = {k: DEFAULTS[k][0] for k in DEFAULTS if k != 'maxPasses'}
    p.update(params)
    p.setdefault('direction', 'both')
    return p


def model(info: dict, params: dict, name: str = 'ms', memo: bool = True):
    '''(scheme, spec completed by the generator, generated files in memory, area totals)'''
    from ...ntt.multistep.MultiStepNTT import MultiStepNTT
    with (_memo() if memo else contextlib.nullcontext()):
        s = scheme(info, params, name)
        spec = _quiet(lambda: MultiStepNTT(s).spec(name, None))
        store = generateTop(spec)
        tot = _quiet(lambda: s.area())
        lat = s.latency()
    return s, spec, store, tot, lat


def explain(req, params):
    '''Why `evaluate` gives None for a point (the generator's message), or None when the point is legal.'''
    try:
        model(_info(req), _complete(params))
    except (ValueError, NotImplementedError) as e:
        return f'{type(e).__name__}: {e}'
    return None


class TooLarge(Exception):
    """The tables of a core alone exceed a memory limit of the request (`tableMemory`)."""


#: the table count is made before the estimate for cores that keep the tables of every modulus (not for rotating
#: slots: there the count with one slot is a weak bound and seldom rejects, measured 7 of 58 against 81 of 91)
EARLY_TABLES = True


def tableMemory(info: dict, params: dict) -> tuple:
    """(BRAM36, URAM) of the tables of a point alone, from the core built WITHOUT the DSP split and the area walk
    with the arithmetic left out: 0.18 s against about 1 s for the estimate. The tables do not depend on the DSP
    split, so the full estimate counts at least this (checked on 201 points of the Allam search: never above the
    record). Rotating slots are counted with one slot, a lower bound."""
    from ...ntt.multistep import MultiStepArea as MSA
    zero = MSA._z()

    class Tables(MSA._Walk):
        def passCost(self, sub):
            return dict(zero), {}

        def comp(self, key, obj):
            return dict(zero)
    p = dict(params, dspTotal=None, dspFraction=None)
    if p.get('slotMode') == 'rotate':
        info = dict(info, slotsK=1)
        if p.get('loadLanes') == 'auto':
            p['loadLanes'] = 1
    with _memo():
        s = scheme(info, p, 'ms')
        w = _quiet(lambda: Tables(s, 1, 'ms'))
    tabs = [x for x in w.parts if x['what'].startswith('table depth')]
    return sum(x['n'] * x.get('bram36', 0) for x in tabs), sum(x['n'] * x.get('uram', 0) for x in tabs)


def evaluate(req, params):
    if req.transform == 'both':
        return None
    info = _info(req)
    params = _complete(params)
    if params['direction'] != 'both' and params['direction'] != req.direction:
        return None
    if EARLY_TABLES and params.get('slotMode') != 'rotate' and (req.maxBram36 is not None or req.maxUram is not None):
        try:
            b, u = tableMemory(info, params)
        except (ValueError, NotImplementedError):
            b = u = 0                           # not legal: the estimate below says so
        if (req.maxBram36 is not None and b > req.maxBram36) or (req.maxUram is not None and u > req.maxUram):
            raise TooLarge(f'tables alone need {b:.0f} BRAM36 and {u:.0f} URAM')
    rot = params.get('slotMode') == 'rotate'
    try:
        auto = rot and params.get('loadLanes') == 'auto'
        if auto:
            # the load width follows from the tables: the fewest lanes with which a load fits a frame
            s0, spec0, _, _, _ = model(info, dict(params, loadLanes=1))
            R = slots.lanesFor([u['words'] for u in spec0['load']['units']], s0.F)
            if R is None:
                return None                 # a table is longer than a frame
            params = dict(params, loadLanes=R)
        s, spec, store, tot, LAT = model(info, params)
        if rot:
            # the slots rotate: the timing of a load gives the lead time and the number of slots, and the design
            # is built again with that many
            from ...ntt.multistep.MultiStepNTT import MultiStepNTT
            pl = _quiet(lambda: MultiStepNTT(s).managedPlan(spec))
            if not pl['fits'] and auto and params['loadLanes'] < 4096:      # the estimate was one step short
                params = dict(params, loadLanes=2 * params['loadLanes'])
                s, spec, store, tot, LAT = model(info, params)
                pl = _quiet(lambda: MultiStepNTT(s).managedPlan(spec))
            if not pl['fits']:
                return None                 # a load does not fit a frame at this load width
            if pl['slots'] != len(s.moduli):
                info = dict(info, slotsK=pl['slots'])
                s, spec, store, tot, LAT = model(info, params)
                pl = _quiet(lambda: MultiStepNTT(s).managedPlan(spec))
            ma = slots.managerArea(len(s.moduli), pl['timing'])
            tot = dict(tot, lut=tot['lut'] + ma['lut'], ff=tot['ff'] + ma['ff'])
    except (ValueError, NotImplementedError):       # the scheme or a sub-model refuses the combination
        return None
    P, F = s.P, s.F
    plist = portList(s, spec, store, 'ms', rot)
    words = twiddleWords(s, spec, params)
    flags = []
    note = NOTE
    loadable, stream = params['loadable'], params['tableSupply'] == 'stream'
    reload = 0
    if loadable:
        modReload = LAT + 1 + words['load'] + LOAD_SETTLE
        dirReload = LAT + LOAD_SETTLE if params['direction'] == 'both' else 0
        reload = modReload if req.M > 1 else dirReload
        note += (f' Loadable: a modulus change costs {modReload} cycles (drain {LAT} + 1 + {words["load"]} words + '
                 f'{LOAD_SETTLE}), a direction change alone {dirReload}; reloadCycles is the '
                 + ('modulus figure.' if req.M > 1 else 'direction figure (one modulus).')
                 + ' twiddleWordsOutside is the load image of one modulus (every direction of the core).')
    if params['dspFraction'] is not None or (params['dspTotal'] is not None and binds(s)):
        flags.append('model: with a DSP budget the routed LUT count was up to 10 % and the FF count up to 28 % '
                     'above the model (area units up to 4.3 %)')
    if params['unified']:
        note += ' Unified butterfly: model LUT about 7 % high.'
    if params['transpose'] != 'bmb':
        flags.append("no RTL: transpose 'mbm' is a model only, build() refuses it")
    if params['form'] == 'folded' and params['reduction'] == 'shoup':
        flags.append(FOLDED_SHOUP)
    if params['inverseScale'] == 'none' and params['direction'] != 'forward':
        flags.append('the inverse is not scaled by 1/N (inverseScale none): the user must scale')
    if stream or params['outReady'] or params['crossRegs'] or params['ramLatency'] > 2 or \
            params['outputOrder'] != 'pass':
        note += (' Options of 2026-11-14 (stream supply, outReady, crossRegs, ramLatency, output order) are priced '
                 'by the same rules; no routed comparison was made in this step (not measured).')
    note += ' Sub-NTT twiddle constants are counted by a formula ((n - 1) per pass, direction and resident modulus).'
    if loadable:
        inside, outside = words['load'], words['load']
    elif stream:
        inside, outside = words['sub'], words['perModDir']
    else:
        inside, outside = words['top'] + words['sub'], 0
    if params.get('loadMod') and params['tableSupply'] == 'core':
        outside = words['load']                 # the outside keeps the load image of each modulus
    if rot:
        # the load image of one modulus: every unit, and both directions when a load fills one direction
        outside = sum(u['words'] for u in spec['load']['units']) * (len(s.dirs) if params.get('loadByDir') else 1)
        flags.append(f'slots rotate: {len(s.moduli)} slots for any sequence of moduli, a load of {pl["timing"]["words"]} '
                     f'cycles on {params["loadLanes"]} lane(s) per new modulus, announced {pl["lead"]} cycles ahead; '
                     f'the manager is priced by a formula')
    ports = _group(plist)
    live = sum(p.peakBitsPerCycle for p in ports if not p.perLoad)
    load = sum(p.peakBitsPerCycle for p in ports if p.perLoad)
    mc = s.multiplierCount()
    return CoreRecord(
        arch=ARCH, name=pointName(info, params),
        params=dict(params, **{'req': info, 'peakBits': max(live, load)}), clockMhz=req.clockMhz,
        lut=round(tot['lut'], 1), ff=round(tot['ff'], 1), dsp=tot['dsp'], bram36=tot['bram36'], uram=tot['uram'],
        interval=F, latency=LAT + F - 1, reloadCycles=reload, ports=ports,
        twiddleWordsInside=int(inside), twiddleWordsOutside=int(outside),
        perPolyModulus=bool(s.perFrame), perPolyDirection=bool(params['direction'] == 'both' and not loadable),
        lanes=P, butterflies=int(mc['butterflies']), flags=flags, modelNote=note)


def build(record, outdir, polys: int = 6, seed: int = 9, gaps=None, ready=None):
    '''RTL and the generated self-checking testbench (`<top>_tb`: every output beat, value and cycle) of a record
    in `outdir`. Returns {'top', 'tb', 'files', 'meta', 'ports' (the model's full port list), 'polys', 'reloads'}.
    Polynomial i has modulus i mod M and direction i mod 2 where the core takes them per polynomial; a loadable
    core runs two jobs (the second half on the next modulus, or the other direction with one modulus).'''
    import random
    from ...ntt.multistep.MultiStepNTT import MultiStepNTT
    params = dict(record.params)
    info = params.pop('req')
    params.pop('peakBits', None)
    params = _complete(params)
    if params['transpose'] != 'bmb':
        raise ValueError(f"{record.name}: transpose '{params['transpose']}' has no RTL (model only)")
    if params['form'] == 'folded' and params['reduction'] == 'shoup' and not os.environ.get('MULTISTEP_BUILD_BROKEN'):
        raise ValueError(f'{record.name}: {FOLDED_SHOUP}')
    name = record.name
    s = scheme(info, params, name)
    rng = random.Random(seed)
    T = polys
    both = params['direction'] == 'both'
    d1 = 'inv' if params['direction'] == 'inverse' else 'fwd'
    if s.loadable:
        h = T // 2
        if len(s.moduli) > 1:
            qs = [s.moduli[0]] * h + [s.moduli[1]] * (T - h)
            dirs = [d1] * T
        else:
            qs = [s.moduli[0]] * T
            dirs = ['fwd'] * h + ['inv'] * (T - h) if both else [d1] * T
    else:
        qs = [s.moduli[i % len(s.moduli)] for i in range(T)]
        dirs = [('inv' if i % 2 else 'fwd') if both else d1 for i in range(T)]
    xs = [[rng.randrange(q) for _ in range(s.N)] for q in qs]
    os.makedirs(outdir, exist_ok=True)
    op = MultiStepNTT(s)
    meta = _quiet(lambda: op.emitRtl(name, outdir, xs=xs, dirs=dirs, qs=qs, gaps=gaps or [0] * T, ready=ready))
    spec = _quiet(lambda: op.spec(name, None))
    store = generateTop(spec)
    rtl = os.path.join(outdir, 'RTL_generated')
    files = sorted(os.path.join(rtl, f) for f in os.listdir(rtl))
    return {'top': name, 'tb': f'{name}_tb', 'files': files, 'meta': meta,
            'ports': portList(s, spec, store, name), 'polys': T, 'qs': qs, 'dirs': dirs,
            'reloads': list(getattr(op, 'reloads', []) or []), 'latency': s.latency(), 'F': s.F}
