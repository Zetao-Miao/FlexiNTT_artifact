'''The dataflow (streaming) NTT for the design-space search: `StreamingNTTScheme` (P lanes, a frame of n / P
cycles) and, at P = n, the fully unrolled `UnrolledNTTScheme` (one transform per cycle).

    enumerate(req)        every legal option combination (plain values)
    evaluate(req, params) CoreRecord from the build-free models (StreamArea inventory, the scheme's own latency),
                          the ports from the generator's own spec (`portList`, the same rules as the emitter)
    build(record, outdir) RTL and the self-checking testbench of a record
    quick(req, params)    (interval, butterflies) from the lane count

Options (DEFAULTS gives the values `enumerate` tries; `req.options['dataflow']` replaces any list):
    kind            'stream' (P < n) | 'unrolled' (P = n, only when n <= req.maxLanes)
    lanes           powers of two, 2 .. min(n / 2, req.maxLanes); n for 'unrolled'
    modulus         'slots' (run-time moduli with a change per polynomial: the modulus constants come with each
                    polynomial, the twiddle tables are RAMs of req.M slots filled through the load port while
                    other polynomials run, or the twiddles come on the stream) |
                    'fixed' (one q built in) | 'table' (moduli=[...], MIDX per polynomial) |
                    'runtime' (a modulus family, q on ports, tables reloaded on a change)
    source          twiddles: 'rom' | 'ram' (load port) | 'otf' (generated on chip) | 'rec' | 'stream' (from outside);
                    unrolled: 'rom' | 'ram' | 'port' (every butterfly's twiddle is an input every cycle)
    otfMinBits      with 'otf': classes with fewer significant cycle bits keep a table (0: every class generated).
                    This is the axis the BRAM budget (`setBramBudget`) moves, so the budget is not a second option.
    reduction       barrett | mont | shoup | wlm | wlm-generic | kred | gold | mersenne | solinas | fold | table | shiftadd
    butterflyType   'CT' | 'GS'
    inverseScale    'output' | 'stage'
    unified         the unified CT/GS butterfly (both directions, per polynomial)
    twistSource     'tab' | 'otf' (the output twist of a negacyclic inverse)
    outputOrder     'stream' | 'natural'
    outReady        output backpressure wrapper;  outDepth: its buffer in polynomials (None: the smallest full-rate one)
    inputRegister   a register in front of every butterfly
    constBackend    'lut' | 'dsp' (constant multiplications, fixed modulus)
    differenceRange None | 1 (GS)
    dspFraction     None | share of the pure-DSP count (`setDspBudget`)
'''
from __future__ import annotations

import contextlib
import io
import itertools
import os
import random

from ..record import CoreRecord, Port

ARCH = 'dataflow'
REDUCTIONS = ('barrett', 'mont', 'shoup', 'wlm', 'wlm-generic', 'kred', 'gold', 'mersenne', 'solinas', 'fold',
              'table', 'shiftadd')
UNROLLED_REDUCTIONS = ('barrett', 'mont', 'shoup', 'wlm')
#: reductions for one built-in modulus only (no run-time or table form)
FIXED_ONLY = ('gold', 'mersenne', 'fold', 'table', 'shiftadd')
#: every value of every option (lanes and modulus mode follow the requirements)
FULL = {
    'kind': ['stream', 'unrolled'],
    'modulus': ['fixed', 'table', 'runtime', 'slots'],
    'slotMode': ['resident', 'rotate'],                 # modulus 'slots' with tables inside (dse/slots.py)
    'loadLanes': ['auto'],                              # load words per cycle, slotMode 'rotate'. 'auto': the fewest
                                                        # with which a load fits one polynomial time; or numbers
    'source': ['rom', 'ram', 'otf', 'rec', 'stream', 'port'],
    'otfMinBits': [0, 5, 8, 11, 14],
    'reduction': list(REDUCTIONS),
    'butterflyType': ['CT', 'GS'],
    'inverseScale': ['output', 'stage'],
    'unified': [False, True],
    'twistSource': ['tab', 'otf'],
    'outputOrder': ['stream', 'natural'],
    'outReady': [False, True],
    'outDepth': [None],
    'inputRegister': [False, True],
    'constBackend': ['lut', 'dsp'],
    'differenceRange': [None, 1],
    'dspFraction': [None, 0.6, 0.3],
}
#: what `enumerate` tries by default: FULL with one value for the four options that only trade a few per cent
#: (the full grid is 7,056 points per lane count at n = 4096, 2 to 40 s each). `req.options['dataflow']` replaces
#: any list; {'grid': ['full']} takes FULL.
# Routed at 450 MHz on 2026-11-15 (N = 4096, 32 bit): 6 of 6 cores without the input register missed (393 to
# 449 MHz, a memory output drives a multiplier input), 2 of 4 with it met and the other two reached 425 and 442.
# At 350 MHz every routed core met without it, so the option is listed only above this clock.
IREG_FROM_MHZ = 380
IREG_FLAG_OFF = 'no input register: 0 of 6 such routed cores met 450 MHz (393 to 449 MHz reached)'
IREG_FLAG_ON = 'input register: 2 of 4 such routed cores met 450 MHz (425 MHz the lowest)'
DEFAULTS = dict(FULL, otfMinBits=[0, 8], inputRegister=[False], constBackend=['lut'], differenceRange=[None],
                dspFraction=[None])       # the user's DSP limit is the budget (dsplimit.py)
#: ports that carry no polynomial data: clock, reset, handshakes, the strobes of the load port
from ..dsplimit import binds, totalOf       # noqa: E402
from .. import slots                        # noqa: E402
CONTROL = ('clk', 'rst', 'in_valid', 'in_ready', 'out_valid', 'out_ready', 'tw_rst', 'tw_wen')
PARAM_ORDER = ('kind', 'lanes', 'modulus', 'source', 'otfMinBits', 'reduction', 'butterflyType', 'inverseScale',
               'unified', 'twistSource', 'outputOrder', 'outReady', 'outDepth', 'inputRegister', 'constBackend',
               'differenceRange', 'dspFraction', 'dspTotal', 'slotMode', 'loadLanes', 'loadByDir')


def _quiet(fn):
    with contextlib.redirect_stdout(io.StringIO()):
        return fn()


def _val2(x: int) -> int:
    return (x & -x).bit_length() - 1


def _family(red: str, moduli, width: int, mode: str, form: dict | None = None, order: int | None = None):
    '''The run-time modulus family the datapath is built over (None: the scheme's default). With no modulus list
    the family follows the NTT (q = 1 mod `order`) and the stated modulus `form`.'''
    from ...modmult.ModulusFamily import ModulusFamily as MF
    if mode == 'fixed':
        return None
    if not moduli and order:
        from .. import modform
        return modform.family(form or {'kind': 'ntt'}, red, width, order)
    if red == 'wlm' and moduli:
        v = min(_val2(q - 1) for q in moduli)
        return MF.friendly(v, width - v) if width - v >= 1 else None
    if red == 'kred' and moduli:
        v = min(_val2(q - 1) for q in moduli)
        kb = max(((q - 1) >> v).bit_length() for q in moduli)
        if kb > 8:
            raise ValueError('not K-RED moduli (k of more than 8 bits)')
        return MF.kred(v, kb)
    if red == 'solinas' and moduli:
        cb = max(((1 << width) - q).bit_length() for q in moduli)
        if cb > 16:
            raise ValueError('not pseudo-Mersenne moduli (c of more than 16 bits)')
        return MF.pseudoMersenne(width, cb)
    return MF.odd(width) if mode == 'runtime' else None


def _info(req) -> dict:
    '''The part of the requirements a record must carry to be built again.'''
    return {'n': req.n, 'moduli': list(req.moduli), 'qBits': req.width, 'negacyclic': req.transform == 'negacyclic',
            'form': req.form, 'M': req.M,
            'direction': req.direction, 'clockMhz': req.clockMhz}


def scheme(info: dict, params: dict, name: str = 'df', n: int | None = None, lanes: int | None = None):
    '''The scheme of one point. `n` / `lanes` override the size (the legality probe uses a small one).'''
    n = n or info['n']
    P = lanes or params['lanes']
    red, mode, src = params['reduction'], params['modulus'], params['source']
    moduli, width = info['moduli'], info['qBits']
    fam = _family(red, moduli, width, mode, info.get('form'), info['n'] * (2 if info['negacyclic'] else 1))
    if mode == 'slots':
        # run-time moduli in loadable slots: stand-in primes size the table, the datapath takes the run-time family
        from .. import modform
        form = info.get('form') or {'kind': 'ntt'}
        order = info['n'] * (2 if info['negacyclic'] else 1)
        q = modform.samplePrimes(form, width, order, info.get('slotsK') or max(1, info.get('M', 1)))
        fam = modform.family(form, red, width, order)
        if fam is None:
            raise ValueError('no run-time family')
    elif mode == 'fixed':
        q = moduli[0]
    elif mode == 'table':
        q = list(moduli)
    else:
        q = 0
        if fam is None:
            raise ValueError('no run-time family')
    d = info['direction']
    if params.get('kind', 'stream') == 'unrolled':
        import runUnrolledNTT as U
        kw = dict(twiddleSource=src, targetFmaxMhz=info['clockMhz'], inputRegister=params['inputRegister'],
                  inverseScale=params['inverseScale'] if d != 'forward' else 'output', behav=False,
                  butterflyType=params['butterflyType'])
        if params.get('unified'):
            kw['unified'] = True
        if params.get('dspFraction') is not None:
            kw['dspFraction'] = params['dspFraction']
        elif params.get('dspTotal') is not None:
            kw['dspTotal'] = params['dspTotal']
        if mode != 'fixed' and fam is not None:
            kw['family'] = fam
        return _quiet(lambda: U.make(name, n, q, red, info['negacyclic'], d, **kw))
    import runModularNTT as R
    kw = dict(targetFmaxMhz=info['clockMhz'], inputRegister=params['inputRegister'], butterflyType=params['butterflyType'],
              outputOrder=params['outputOrder'], outReady=params['outReady'])
    if d != 'forward':
        kw['inverseScale'] = params['inverseScale']
    if params.get('unified'):
        kw['unified'] = True
    if params.get('outDepth') is not None:
        kw['outDepth'] = params['outDepth']
    if params.get('otfMinBits'):
        kw['otfMinBits'] = params['otfMinBits']
    if params.get('twistSource', 'tab') != 'tab':
        kw['twistSource'] = params['twistSource']
    if params.get('constBackend', 'lut') != 'lut':
        kw['constBackend'] = params['constBackend']
    if params.get('differenceRange') is not None:
        kw['differenceRange'] = params['differenceRange']
    if params.get('dspFraction') is not None:
        kw['dspFraction'] = params['dspFraction']
    elif params.get('dspTotal') is not None:
        kw['dspTotal'] = params['dspTotal']
    if mode == 'slots':
        kw['loadableModuli'] = True
        if params.get('slotMode') == 'rotate':
            kw.update(slotManager=True, loadLanes=params.get('loadLanes', 1), loadByDirection=bool(params.get('loadByDir')))
    return _quiet(lambda: R.stream(name, n, P, q, red, info['negacyclic'], d, family=fam if mode != 'fixed' else None,
                                   source=src, **kw))


# --- the boundary: the same rules as the emitters ---------------------------------------------------------

def portList(s, spec, params: dict) -> list[dict]:
    '''Every port of the top module, in the emitter's order: {name, width, dir, kind, beats, perLoad}. kind None:
    clock, reset, handshake or strobe. Rules: `rtl_gen.ntt.StreamNTT_RTL_gen` (the core), `StreamReady_RTL_gen`
    (outReady: the core's inputs, four handshake ports, the outputs) and `rtl_gen.unrolled_ntt` (P = n).
    beats: per polynomial in steady state; perLoad: once per modulus (or direction) run.'''
    info = spec.roms
    P, F = spec.lanes, spec.frameCycles
    pf = info.get('perFrame')
    unrolled = params.get('kind', 'stream') == 'unrolled'
    rot = params.get('slotMode') == 'rotate'
    out = []

    def add(name, width, d='input', kind=None, beats=0.0, perLoad=False):
        out.append({'name': name, 'width': int(width), 'dir': d, 'kind': kind, 'beats': float(beats), 'perLoad': perLoad})
    add('clk', 1)
    add('rst', 1)
    frameDir = bool(unrolled and s.frameDir())
    perPolyDir = bool(spec.dirPort and (pf or frameDir))
    dirArgs = dict(kind='record_stream', beats=1) if perPolyDir else dict(kind='table_load', beats=1, perLoad=True)
    if unrolled:
        add('in_valid', 1)
        if pf:
            add('MIDX', s.modulusIndexBits(), kind='record_stream', beats=1)
        if spec.dirPort:
            add('DIR', 1, **dirArgs)
    else:
        if spec.dirPort:
            add('DIR', 1, **dirArgs)
        if pf and rot:                      # the manager names the slot; the outside announces a key per polynomial
            add('ann_valid', 1)
            add('ann_key', slots.KEY_BITS, kind='record_stream', beats=1)
        elif pf:
            add('MIDX', pf['indexBits'], kind='record_stream', beats=1)
    if not pf:
        for qp, w in info['qPorts']:
            add(qp, w, kind='table_load', beats=1, perLoad=True)
    elif pf.get('loadable'):                # run-time moduli: the constants come with each polynomial
        for qp, w in info['qPorts']:
            add(f'mq_{qp}', w, kind='record_stream', beats=1)
    if info['loadWords']:
        tww = max(max(t['cols']) for t in info['tables'] if t['mode'] == 'ram')
        add('tw_wen', 1)
        if rot:                             # a load for every polynomial that brings a new modulus: counted per polynomial
            add('tw_wdata', tww * info.get('loadLanes', 1), kind='table_load', beats=info['loadWords'])
        else:
            add('tw_rst', 1)
            add('tw_wdata', tww, kind='table_load', beats=info['loadWords'], perLoad=True)
            if pf and pf.get('loadable'):
                add('tw_slot', pf['indexBits'])     # which slot the load fills (with tw_rst)
    strm = info.get('stream')
    if unrolled and getattr(s, '_twPort', False):
        for st, k in s.portSlots():
            add(f'tw_{st}_{k}', strm['width'] if strm else (s.qMax() - 1).bit_length(), kind='twiddle_stream', beats=F)
    elif strm:
        for c in range(strm['classes']):
            add(f'tw_s{c}', strm['width'], kind='twiddle_stream', beats=F)
    for l in range(P):
        add(f'x_in_{l}', spec.inWidth, kind='data_in', beats=F)
    if unrolled:
        add('out_valid', 1, 'output')
        if pf:
            add('midx_out', s.modulusIndexBits(), 'output', kind='record_stream', beats=1)
        if perPolyDir:
            add('dir_out', 1, 'output', kind='record_stream', beats=1)
    elif params.get('outReady'):
        add('in_valid', 1)
        add('in_ready', 1, 'output')
        add('out_valid', 1, 'output')
        add('out_ready', 1)
    for l in range(P):
        add(f'y_out_{l}', spec.outWidth, 'output', kind='data_out', beats=F)
    return out


def _group(plist: list[dict]) -> list[Port]:
    '''Equal neighbouring ports (same kind, width, beats; names x_3 after x_2) as one Port with a count.'''
    ports = []
    for p in plist:
        if p['kind'] is None:
            continue
        stem = p['name'].rstrip('0123456789')
        last = ports[-1] if ports else None
        if last is not None and stem != p['name'] and last.name == stem and last.kind == p['kind'] and \
                last.widthBits == p['width'] and last.beatsPerNtt == p['beats'] and last.perLoad == p['perLoad']:
            last.count += 1
        else:
            ports.append(Port(p['kind'], p['width'], 1, p['beats'], p['perLoad'], stem if stem != p['name'] else p['name']))
    return ports


def model(info: dict, params: dict, name: str = 'df'):
    '''(scheme, generator spec, area totals) of one point; no file is written.'''
    from ...ntt.dataflow import StreamArea
    from ...ntt.dataflow import StreamingNTTScheme as S
    old = S.SHARE_IDENTICAL_BU
    S.SHARE_IDENTICAL_BU = True         # identical butterflies are priced once (the model only, no RTL from here)
    try:
        s = scheme(info, params, name)
        w = _quiet(lambda: StreamArea._Walk(s, 1, name))
    finally:
        S.SHARE_IDENTICAL_BU = old
    s._walk = w
    return s, w.spec, StreamArea.totals(w.parts)


# --- the search interface --------------------------------------------------------------------------------

_PROBE: dict = {}


def _legal(info: dict, params: dict) -> bool:
    '''The reduction, modulus mode, source and butterfly of `params` on a small transform (n = 64, 2 lanes, or
    n = 16 unrolled): the constructors and the bound propagation refuse what cannot be built.'''
    key = (tuple(info['moduli']), info['qBits'], info['negacyclic'], info['direction'],
           tuple(sorted((info.get('form') or {}).items())),
           tuple(params[k] for k in ('kind', 'modulus', 'source', 'reduction', 'butterflyType', 'constBackend')))
    if key not in _PROBE:
        small = min(info['n'], 16 if params['kind'] == 'unrolled' else 64)
        _PROBE[key] = False
        for isc in ('output', 'stage'):
            try:
                p = dict(params, outReady=False, outDepth=None, outputOrder='stream', otfMinBits=0,
                         unified=False, slotMode='resident', loadLanes=1, loadByDir=False,
                         twistSource='tab', differenceRange=None, dspFraction=None, dspTotal=None, inputRegister=False,
                         inverseScale=isc)
                s = scheme(info, p, 'probe', n=small, lanes=small if params['kind'] == 'unrolled' else 2)
                _quiet(s.areaCost)
                _PROBE[key] = True
                break
            except (ValueError, NotImplementedError, AssertionError, KeyError, ZeroDivisionError, TypeError):
                pass
    return _PROBE[key]


def _modes(req) -> list[str]:
    '''Modulus modes that can serve the requirement. No modulus list: only run-time moduli. More than one
    modulus: not 'fixed'. A change per polynomial (modulus, or direction): only the table form has no idle cycle.'''
    if not req.moduli:
        # run-time moduli: one table set loaded per run ('runtime'), or loadable slots with a modulus index per
        # polynomial ('slots'), the only form with no idle cycle on a change
        if (req.perPolyModulus and req.M > 1) or (req.perPolyDirection and req.direction == 'both'):
            return ['slots']
        return ['runtime', 'slots']
    if (req.perPolyModulus and req.M > 1) or (req.perPolyDirection and req.direction == 'both'):
        return ['table']
    return ['table', 'runtime'] if req.M > 1 else ['fixed', 'table', 'runtime']


def enumerate(req):
    if req.transform == 'both':
        return []                       # one core is cyclic or negacyclic; the choice is built in
    given = dict(req.options.get(ARCH, {}))
    opt = dict(FULL if 'full' in given.pop('grid', []) else DEFAULTS)
    if req.clockMhz > IREG_FROM_MHZ:
        opt['inputRegister'] = [False, True]
    opt.update(given)
    info = _info(req)
    n, d, nwc = req.n, req.direction, info['negacyclic']
    lanes = [1 << k for k in range(1, n.bit_length()) if (1 << k) <= req.maxLanes]
    if 'lanes' in opt:
        lanes = [p for p in lanes if p in opt['lanes']]
    modes = [m for m in _modes(req) if m in opt['modulus']]
    out = []
    for kind in opt['kind']:
        unr = kind == 'unrolled'
        for P in lanes:
            if unr != (P == n):
                continue
            F = n // P
            for mode in modes:
                srcs = {'fixed': ('rom',), 'table': ('rom', 'otf', 'rec', 'stream'), 'runtime': ('ram', 'otf', 'rec'),
                        'slots': ('rom', 'otf', 'rec', 'stream')}[mode]
                tab = mode in ('table', 'slots')            # a modulus index per polynomial
                if unr:
                    srcs = {'fixed': ('rom',), 'table': ('rom', 'port'), 'runtime': ('ram', 'port'), 'slots': ()}[mode]      # 'port' with moduli = the per-frame stream supply
                for src in srcs:
                    if src not in opt['source']:
                        continue
                    grid = {
                        'otfMinBits': [k for k in opt['otfMinBits'] if k == 0 or (src == 'otf' and not unr and k < F.bit_length())]
                        or [0],
                        'reduction': [r for r in opt['reduction'] if r in (UNROLLED_REDUCTIONS if unr else REDUCTIONS)],
                        # Gentleman-Sande with a modulus per polynomial too (2026-11-16: gate 6 rows pfgs*, pfgsi*,
                        # lmgs*, mggs*); before, the per-polynomial modes took Cooley-Tukey only
                        'butterflyType': list(opt['butterflyType']),
                        'inverseScale': opt['inverseScale'] if d != 'forward' else ['output'],
                        'unified': [u for u in opt['unified'] if not u or (d == 'both' and tab and src != 'rec')],
                        'twistSource': [t for t in opt['twistSource'] if t == 'tab' or (mode in ('table', 'slots') and nwc and not unr
                                                                                       and d != 'forward')],
                        'outputOrder': opt['outputOrder'] if not unr else ['stream'],
                        'outReady': [r for r in opt['outReady'] if not r or not unr],
                        'outDepth': opt['outDepth'],
                        'inputRegister': opt['inputRegister'],
                        'constBackend': [c for c in opt['constBackend'] if c == 'lut' or (mode == 'fixed' and not unr)],
                        'differenceRange': opt['differenceRange'],
                        'dspFraction': opt['dspFraction'],
                    }
                    names = list(grid)
                    for vals in itertools.product(*(grid[k] for k in names)):
                        p = dict(zip(names, vals))
                        p.update(kind=kind, lanes=P, modulus=mode, source=src)
                        p['dspTotal'] = totalOf(req, p['dspFraction'])
                        bt = p['butterflyType']
                        if p['unified'] and (bt != 'CT' or p['inverseScale'] != 'stage'):
                            continue
                        if p['inverseScale'] == 'stage' and nwc and bt == 'CT' and not p['unified']:
                            continue
                        if p['differenceRange'] is not None and bt != 'GS':
                            continue
                        if p['twistSource'] == 'otf' and (p['unified'] or bt == 'GS'):
                            continue                # no output twist left to generate
                        if p['outDepth'] is not None and not p['outReady']:
                            continue
                        if p['reduction'] == 'shoup' and src in ('otf', 'rec'):
                            continue
                        if p['reduction'] in FIXED_ONLY and mode != 'fixed':
                            continue
                        p.update(slotMode='resident', loadLanes=1, loadByDir=False)
                        if not _legal(info, p):
                            continue
                        out.append({k: p[k] for k in PARAM_ORDER})
                        if mode == 'slots' and src != 'stream' and 'rotate' in opt['slotMode'] \
                                and 'rotate' in slots.modes(req):
                            # the slots rotate: one point per load width; the number of slots follows from the
                            # pipeline and the load (evaluate). With both directions a load fills one direction.
                            for R in opt['loadLanes']:
                                out.append(dict({k: p[k] for k in PARAM_ORDER}, slotMode='rotate', loadLanes=R,
                                                loadByDir=d == 'both'))
                            if 'resident' not in opt['slotMode'] or 'resident' not in slots.modes(req):
                                out.remove({k: p[k] for k in PARAM_ORDER})
    return out


def sizing(req, params):
    """(family, size): the size is the lane count (butterflies = log2(n) lanes / 2). A family is a modulus mode.
    The unrolled core is the largest size of the same family."""
    return (params['modulus'],), params['lanes']


def quickLatency(req, params):
    """A lower bound of the latency (first input beat to last output beat): n / lanes input beats, then as many
    output beats, which cannot start before the last input beat."""
    return 2 * (req.n // params['lanes']) - 1


def sideKinds(req, params) -> set:
    """Kinds of side traffic this point surely has, from its twiddle source (never more than the model lists)."""
    slots = params['modulus'] == 'slots'    # slots: the constants come with each polynomial (a record), and a
    return ({'twiddle_stream'} if params['source'] == 'stream' else set()) \
        | ({'table_load'} if (params['modulus'] == 'runtime' or (slots and params['source'] != 'stream')) else set()) \
        | ({'record_stream'} if slots else set())       # table load fills the slots unless the twiddles stream


def quick(req, params):
    F = req.n // params['lanes']
    return F, (req.n.bit_length() - 1) * params['lanes'] // 2


def pointName(info: dict, params: dict) -> str:
    bits = [f"df_n{info['n']}_p{params['lanes']}", params['modulus'][:3], params['source'], params['reduction'].replace('-', ''),
            params['butterflyType'].lower()]
    if info['direction'] != 'forward':
        bits.append({'inverse': 'inv', 'both': 'bth'}[info['direction']] + ('s' if params['inverseScale'] == 'stage' else 'o'))
    bits += [t for c, t in ((params['kind'] == 'unrolled', 'unr'), (params['unified'], 'uni'),
                            (params['twistSource'] == 'otf', 'twotf'), (params['otfMinBits'], f"mb{params['otfMinBits']}"),
                            (params['outputOrder'] == 'natural', 'nat'), (params['outReady'], 'rdy'),
                            (params['outDepth'] is not None, f"d{params['outDepth']}"), (params['inputRegister'], 'ireg'),
                            (params['constBackend'] == 'dsp', 'cdsp'), (params['differenceRange'] is not None, 'dr1'),
                            (params['dspFraction'] is not None, f"dsp{int(100 * (params['dspFraction'] or 0))}"),
                            (params.get('dspTotal') is not None, f"dspt{params.get('dspTotal')}"),
                            (params.get('slotMode') == 'rotate', f"rot{params.get('loadLanes')}")) if c]
    return '_'.join(bits)


def _outsideWords(s) -> int:
    '''Distinct twiddle words the outside must keep for one modulus and one direction (the stream repeats them).'''
    best = 0
    for d in s.dirs:
        best = max(best, sum(len(set(dict(key)[d])) for key in s.streamClasses()))
    return best


def evaluate(req, params):
    if req.transform == 'both':
        return None
    info = _info(req)
    unr = params.get('kind', 'stream') == 'unrolled'
    rot = params.get('slotMode') == 'rotate'
    try:
        if rot and params.get('loadLanes') == 'auto':
            # the load width follows from the tables: the fewest lanes with which a load fits a frame (the table
            # sizes do not depend on the lane count, so one model with one lane gives them)
            s0, _, _ = model(info, dict(params, loadLanes=1))
            R = slots.lanesFor([t['words'] for t in s0._walk.slotTables()], s0.F)
            if R is None:
                return None                 # a table is longer than a frame
            params = dict(params, loadLanes=R)
            auto = True
        else:
            auto = False
        s, spec, tot = model(info, params)
        if rot:
            # the slots rotate: the timing of a load gives the lead time and the number of slots (dse/slots.py),
            # and the design is built again with that many
            tim = s.slotTiming(s._walk.slotTables(), spec.latency, spec.roms['loadWords'])
            pl = slots.plan(tim, s.F)
            if not pl['fits'] and auto and params['loadLanes'] < 4096:      # the estimate was one step short
                params = dict(params, loadLanes=2 * params['loadLanes'])
                s, spec, tot = model(info, params)
                tim = s.slotTiming(s._walk.slotTables(), spec.latency, spec.roms['loadWords'])
                pl = slots.plan(tim, s.F)
            if not pl['fits']:
                return None                 # a load does not fit a frame at this load width
            if pl['slots'] != len(s.moduli):
                info = dict(info, slotsK=pl['slots'])
                s, spec, tot = model(info, params)
                tim = s.slotTiming(s._walk.slotTables(), spec.latency, spec.roms['loadWords'])
            ma = slots.managerArea(len(s.moduli), tim)
            tot = dict(tot, lut=tot['lut'] + ma['lut'], ff=tot['ff'] + ma['ff'])
    except (ValueError, NotImplementedError) as e:
        if 'DSP' in str(e) or 'budget' in str(e):
            raise
        return None
    P, F, n = s.lanes, s.F, s.n
    plist = portList(s, spec, params)
    flags = []
    if info['clockMhz'] > IREG_FROM_MHZ:
        flags.append(IREG_FLAG_ON if params['inputRegister'] else IREG_FLAG_OFF)
    table = params['modulus'] in ('table', 'slots')     # a modulus index per polynomial
    if unr:
        interval, lat = 1, s.latency()
        frameDir = s.frameDir()
    else:
        frameDir = False
        if params['outReady']:
            interval, first = _quiet(s.readyInterval), s.readyLatency()
            flags.append('in_valid/in_ready is one handshake per polynomial on a slot boundary (every F cycles after reset), '
                         'the F input beats then follow with no per-beat valid; out_valid/out_ready is per beat')
            if interval != F:
                flags.append(f'output buffer of {s.readyDepth()} polynomials is below the full-rate depth {s.readyMinDepth()}')
        else:
            interval, first = F, s.latency()
        lat = first + F - 1
    both = req.direction == 'both'
    perPolyDir = both and (table or frameDir)
    loadW = spec.roms['loadWords']
    reload = 0
    if params['modulus'] == 'runtime' or (both and not perPolyDir):
        # frames run back to back from reset: a change of q (or of a quasi-static DIR) waits for the last
        # polynomial to leave, writes the tables and starts the frame counter again
        reload = s.latency() + (0 if unr else F - 1) + loadW + 4
        flags.append('reload cycles are a formula (drain + load words + 4), not simulated')
    if params['modulus'] == 'fixed' and req.M > 1:
        return None
    words = _quiet(s.twiddleWords) if not unr else s.twiddleWordsStored()
    outside = 0
    if params['source'] == 'stream':
        outside = _outsideWords(s)
    elif params['source'] == 'port':
        outside = len(s.portSlots())
    elif rot:                                         # the load image of one modulus: every table, every direction
        outside = sum(t['words'] for t in s._walk.slotTables()) * (len(s.dirs) if params.get('loadByDir') else 1)
    elif loadW:
        outside = loadW                               # the load image of one modulus
    ns = None
    try:
        ns = _quiet(s.criticalPathNs)
    except Exception:
        pass
    note = 'StreamArea inventory (LUT within 12 %, FF within 18 %, area units within 1.4 % of 21 routed cores at 350 MHz)'
    if unr:
        note = 'StreamArea inventory on the unrolled scheme (not compared with routed unrolled cores here)'
    if ns is not None:
        note += f'; butterfly model path {ns:.2f} ns'
    if rot:
        flags.append(f'slots rotate: {len(s.moduli)} slots for any sequence of moduli, a load of {tim["words"]} cycles '
                     f'on {params["loadLanes"]} lane(s) per new modulus, announced {pl["lead"]} cycles ahead; the '
                     f'manager is priced by a formula')
    rec = CoreRecord(
        arch=ARCH, name=pointName(info, params), params=dict(params, **{'req': info}), clockMhz=req.clockMhz,
        lut=round(tot['lut'], 1), ff=round(tot['ff'], 1), dsp=tot['dsp'], bram36=tot['bram36'], uram=tot['uram'],
        interval=interval, latency=lat, reloadCycles=reload, ports=_group(plist),
        twiddleWordsInside=int(words), twiddleWordsOutside=int(outside),
        perPolyModulus=table, perPolyDirection=bool(perPolyDir), lanes=P,
        butterflies=sum(len(st) for st in s.butterflies), flags=flags, modelNote=note)
    return rec


def build(record, outdir, frames: int = 4, seed: int = 9):
    '''RTL and the generated self-checking testbench (`<top>_tb`: every output beat, value and cycle) of a record
    in `outdir`. Returns {'top', 'tb', 'files', 'meta', 'ports' (the model's full port list)}.'''
    params = dict(record.params)
    info = params.pop('req')
    name = record.name
    s = scheme(info, params, name)
    rng = random.Random(seed)
    n = s.n
    d = info['direction']
    os.makedirs(outdir, exist_ok=True)
    if params.get('kind', 'stream') == 'unrolled':
        import runUnrolledNTT as U
        from ...ntt.dataflow.UnrolledNTT import UnrolledNTT
        op = UnrolledNTT(s)
        T = max(frames, 6)
        if s.runtime and not s.perFrame:
            qa = s.family.samplePrimeCongruent(rng, s.rootOrder())
            qs = [qa] * T
        else:
            qs = [rng.choice(s.moduli) for _ in range(T)] if s.perFrame else [s.refQ()] * T
        ds = [rng.choice(s.dirs) for _ in range(T)] if (s.perFrame or s.frameDir()) else [s.dirs[0]] * T
        L = n.bit_length() - 1
        xs = []
        for q, dd in zip(qs, ds):
            x = [rng.randrange(q) for _ in range(n)]
            xs.append(U._perm(x if dd == 'fwd' else U.refForInverse(s, x, q), s.inputOrder, L))
        tws = None
        if s._twPort:
            tws = [{(st, k): rng.randrange(q) for st in range(s.L) for k in range(n // 2)} for q in qs]
        meta = _quiet(lambda: op.emitRtl(name, outdir, xs=xs, dirs=ds, qs=qs, tws=tws))
        spec = _quiet(lambda: op.getOperatorInterface(f'{name}_core'))
    else:
        import runModularNTT as R
        from ...ntt.dataflow.StreamingNTT import StreamingNTT
        op = StreamingNTT(s)
        if s.perFrame:
            qq = R._pfSeq(s.moduli, frames)
            fr = [[rng.randrange(x) for _ in range(n)] for x in qq]
            dirn = ['inv' if (f + f // 2) & 1 else 'fwd' for f in range(frames)] if d == 'both' else \
                ('inv' if d == 'inverse' else 'fwd')
        else:
            qq = R._jobQ(s, rng)
            fr = [[rng.randrange(qq) for _ in range(n)] for _ in range(frames)]
            dirn = 'inv' if d in ('inverse', 'both') else 'fwd'
        meta = _quiet(lambda: op.emitRtl(name, outdir, frames=fr, direction=dirn, q=qq))
        spec = _quiet(lambda: op.getOperatorInterface(name))
    rtl = os.path.join(outdir, 'RTL_generated')
    files = sorted(os.path.join(rtl, f) for f in os.listdir(rtl))
    return {'top': name, 'tb': f'{name}_tb', 'files': files, 'meta': meta, 'ports': portList(s, spec, params),
            'frames': frames}
