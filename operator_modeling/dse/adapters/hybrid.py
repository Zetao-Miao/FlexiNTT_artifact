'''The hybrid NTT (`HybridNTTScheme`: a block of U stages x g groups, W = g 2^U lanes, R = ceil(log2 n / U)
rounds over a pool of S + 1 buffers) for the design-space search.

    enumerate(req)        every legal option combination (plain values)
    evaluate(req, params) CoreRecord from the build-free models (HybridArea inventory, the scheme's cycle twins),
                          the ports by the emitter's rules (`rtl_gen/hybrid_ntt.py`, `rtl_gen/hybrid_ports.py`)
    build(record, outdir) RTL and the self-checking testbench of a record
    quick(req, params)    (interval lower bound, butterflies) from the geometry

Options. DEFAULTS gives the values `enumerate` tries, `req.options['hybrid']` replaces any list, and
`req.options['hybrid'] = {'grid': ['full']}` takes FULL for every option not named.

    U, g            block shape: stages per round and groups; every pair with g a power of two, n >= g 4^U
                    U = 1 is not listed unless the options name it: it is the iterative NTT
    slots           polynomials in flight, 1 .. 8 (every value, 'auto' is not used)
    ioLanes         'W' (the core's lanes) | '/2' '/4' 'x2' 'x4' (relative) | a power of two | 'all'
    modulus         how the modulus and the twiddles reach the core:
                      'fixed'        one q built in
                      'rom'          moduli=[...], MIDX per polynomial, tables of every modulus inside
                      'load'         run-time modulus family, `loadSlots` table sets written through the load port
                      'record'       as 'load', the tables of each polynomial come on a valid/ready stream
                                     (twiddleBuffer='record', S + 1 table sets)
                      'stream'       the twiddle tables are outside (tw_addr_<i> / tw_data_<i>), constants built in
                      'stream_load'  as 'stream' with the modulus constants loadable
    loadSlots       table sets of 'load' / 'stream_load': 'M' (one per modulus of the workload), 1, or a count
    twiddleSource   how the tables inside are made: 'rom' | 'rec' | 'otf' | 'tree' | 'auto' (per table by area)
    twistSource     the output twist of a negacyclic inverse: 'tab' | 'rec'
    unified         the unified CT/GS butterfly (no output twist; tables stay stored)
    inverseScale    'output' | 'stage' (cyclic with an inverse)
    shareInverseTwiddles   inverse tables read from the forward ones (cyclic, both directions, 'rom')
    reduction       'barrett' | 'mont' | 'wlm' | 'shoup'
    multiplier      'dsp' | 'booth'
    dspFraction     None | share of the pure-DSP count (`setDspBudget`), multiplier 'dsp' only
    bramFraction    None | share of the design's own BRAM36 count without a budget (`setBramBudget(total=)`),
                    twiddleSource 'auto' only
    outReady        output backpressure;  outDepth: its buffer in polynomials (None: the smallest full-rate one)
    outputOrder     'core' | 'natural'
    fanout          None | most loads per register of the control trees;  fanoutLoads 'register' | 'pins'
    crossRegs       0 .. 4 extra register stages between memories and block
    ramLatency      1 .. 4;  memStyle, twiddleStyle: 'auto' | 'atp' | 'distributed' | 'block' | 'ultra'
    genMinBits      generated tables: classes with fewer significant bits keep a table
'''
from __future__ import annotations

import builtins
import collections
import contextlib
import hashlib
import io
import itertools
import json
import os
import random
import sys
from functools import lru_cache

from ..record import CoreRecord, Port

ARCH = 'hybrid'
REDUCTIONS = ('barrett', 'mont', 'wlm', 'shoup')
#: run-time reductions that a stated modulus form opens (Requirements.modulusForm)
FORM_REDS = {'kred': 'kred', 'solinas': 'pseudo_mersenne'}
from ..dsplimit import binds, totalOf       # noqa: E402
MODES = ('fixed', 'rom', 'load', 'record', 'stream', 'stream_load')
STYLES = ('auto', 'atp', 'distributed', 'block', 'ultra')

#: the values `enumerate` tries. Options that only add cost and that `Requirements` cannot ask for (backpressure,
#: natural order, fan-out trees, crossing registers, read latency, memory styles) stay at the generator's default.
DEFAULTS = {
    'slots': [1, 2, 3, 4, 5, 6, 7, 8],
    'ioLanes': ['W'],
    'modulus': list(MODES),
    'loadSlots': ['M', 1],
    'twiddleSource': ['rom', 'rec', 'otf', 'tree', 'auto'],
    'twistSource': ['tab', 'rec'],
    'unified': [False, True],
    'inverseScale': ['output', 'stage'],
    'shareInverseTwiddles': [False, True],
    'reduction': list(REDUCTIONS),
    'multiplier': ['dsp'],              # 'booth' (the butterfly product on LUTs) only when the options name it:
                                        # the DSP limit shares the DSPs among the multipliers (dsplimit.py)
    'dspFraction': [None],              # the user's DSP limit is the budget (dsplimit.py)
    'bramFraction': [None, 0.5],
    'outReady': [False],
    'outDepth': [None],
    'outputOrder': ['core'],
    'fanout': [None],
    'fanoutLoads': ['register'],
    'crossRegs': [0],
    'ramLatency': [2],
    'memStyle': ['auto'],
    'twiddleStyle': ['auto'],
    'genMinBits': [3],
}
#: the finite ranges behind `grid: full` (fanout, outDepth and genMinBits are unbounded integers: a sample)
FULL = dict(DEFAULTS, **{
    'ioLanes': ['all'],
    'dspFraction': [None, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0],
    'bramFraction': [None, 0.75, 0.5, 0.25, 0.0],
    'outReady': [False, True],
    'outDepth': [None, 1, 2, 4],
    'outputOrder': ['core', 'natural'],
    'fanout': [None, 8, 16, 32, 64],
    'fanoutLoads': ['register', 'pins'],
    'crossRegs': [0, 1, 2, 3, 4],
    'ramLatency': [1, 2, 3, 4],
    'memStyle': list(STYLES),
    'twiddleStyle': list(STYLES),
    'genMinBits': [0, 3, 5, 8],
})

#: the record twin is run when it is at most this many cycles long (about 3 us a cycle)
RECORD_SIM_CYCLES = 400_000
#: a record of at most this share of the core's period costs nothing (checked on the twin, see evaluate)
RECORD_SHORT = 0.8

MODEL_NOTE = ('HybridArea inventory (area units within about 1 % of routed cores on most rows, up to about 11 % on '
              'a Shoup 40-bit row); interval and latency from the cycle twins (equal to xsim on every simulated row)')


def _quiet(fn):
    with contextlib.redirect_stdout(io.StringIO()):
        return fn()


def _repoRoot() -> str:
    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))


def _bits(x: int) -> int:
    return max(1, (x - 1).bit_length())


def _fastStoredColumns(words, width: int) -> int:
    '''HybridArea._storedColumns (different bit columns of a table), the same count from strings: the pure-Python
    sum there takes a minute on the tables of n = 2^16.'''
    words = list(words)
    if not words or width <= 0:
        return len({0 for _ in range(width)})
    mask = (1 << width) - 1
    s = ''.join([format(v & mask, f'0{width}b') for v in words])
    return len({s[i::width] for i in range(width)})


_PATCHED = False


_RT = collections.OrderedDict()        # round tables of the last structures (this process)


def _patchRoundTables() -> None:
    '''Keep the twiddle exponent tables of the last three structures (n, U, g, transform, directions, unified
    butterflies): they do not depend on the moduli or on any other option, and building them is a third of a
    2^16 point. In this process only; the generator's file is not changed, the values are the same objects.'''
    from operator_modeling.ntt.hybrid.HybridNTTScheme import HybridNTTScheme as S
    if getattr(S, '_dseRoundTables', False) or os.environ.get('HYDSE_NOCACHE'):
        return
    orig = S.roundTables

    def roundTables(self):
        if 'rtabs' not in self._qCache:
            key = (self.n, self.U, self.g, bool(self.negacyclic), tuple(self.dirs),
                   bool(getattr(self, 'unified', False)))
            if key in _RT:
                _RT.move_to_end(key)
                self._qCache['rtabs'] = _RT[key]
            else:
                _RT[key] = orig(self)
                while len(_RT) > 3:
                    _RT.popitem(last=False)
        return self._qCache['rtabs']
    S.roundTables = roundTables
    S._dseRoundTables = True


def _patch() -> None:
    '''Use the fast column count in this process (same numbers; no file of the generator is changed).'''
    global _PATCHED
    if not _PATCHED:
        from operator_modeling.ntt.hybrid import HybridArea
        HybridArea._storedColumns = _fastStoredColumns
        _patchRoundTables()
        _PATCHED = True


# --- the requirement ----------------------------------------------------------------------------------

@lru_cache(maxsize=None)
def _primes(bits: int, n: int, count: int, nwc: bool, skip: tuple = ()) -> tuple:
    '''count NTT primes of `bits` bits for n points (as runHybridNTT.primesFor), none of `skip`.'''
    from sage.all import is_prime
    step = 2 * n if nwc else n
    out, k = [], ((1 << (bits - 1)) // step) + 1
    while len(out) < count:
        q = k * step + 1
        if q.bit_length() != bits:
            raise ValueError(f'fewer than {count} NTT primes of {bits} bits for n = {n}')
        if q not in skip and is_prime(q):
            out.append(q)
        k += 1
    return tuple(out)


def _moduliFor(req, count: int) -> list:
    '''The moduli a model with `count` table sets is built from: the requirement's, then sample primes of the
    same width (a loadable core does not depend on them; the area model reads only their widths).'''
    nwc = req.transform == 'negacyclic'
    have = [int(q) for q in req.moduli][:count]
    if len(have) < count and req.modulusForm != 'ntt':      # stand-ins must have the form the user states
        from .. import modform
        have += modform.samplePrimes(req.form, req.width, req.rootOrder, count - len(have), tuple(have))
    elif len(have) < count:
        have += list(_primes(req.width, req.n, count - len(have), nwc, tuple(have)))
    return have


def _family(req, moduli, red):
    '''`req`: transform, n and form (the stated modulus form, valid for every modulus).'''
    from operator_modeling.modmult.ModulusFamily import ModulusFamily as MF
    from .. import modform
    nwc = req.transform == 'negacyclic'
    form = getattr(req, 'form', None) or {'kind': 'ntt'}
    order = 2 * req.n if nwc else req.n
    if red in modform.OPENS:                # K-RED, Solinas: over the stated form
        fam = modform.family(form, red, max(q.bit_length() for q in moduli), order)
        if fam is None:
            raise ValueError(f'{red}: no run-time form for these moduli')
        return fam
    if red == 'wlm':
        v = modform.friendlyV(form, max(q.bit_length() for q in moduli), order)
        qh = [(q - 1) >> v for q in moduli]
        return MF.friendly(v, max(x.bit_length() for x in qh), min(qh))
    return MF.odd(max(q.bit_length() for q in moduli), min(q.bit_length() for q in moduli))


def _modes(req) -> list:
    known = len(req.moduli) >= req.M
    out = []
    if known and req.M == 1:
        out += ['fixed', 'stream']
    if known and req.M > 1:
        out += ['rom', 'stream']
    out += ['load', 'record', 'stream_load']
    return [m for m in MODES if m in out]


def _geometries(req) -> list:
    L = req.n.bit_length() - 1
    out = []
    for U in range(1, L + 1):
        g = 1
        while (g.bit_length() - 1) + 2 * U <= L:
            out.append((U, g))
            g *= 2
    return out


def _ioValues(spec, W: int, n: int) -> list:
    out = []
    for v in spec:
        if v == 'all':
            out += [1 << k for k in range(0, n.bit_length())]
        elif v == 'W':
            out.append(W)
        elif isinstance(v, str) and v[0] == '/':
            out.append(W // int(v[1:]))
        elif isinstance(v, str) and v[0] == 'x':
            out.append(W * int(v[1:]))
        else:
            out.append(int(v))
    seen = []
    for v in out:
        if 1 <= v <= n and v == 1 << (v.bit_length() - 1) and v not in seen:
            seen.append(v)
    return seen


def enumerate(req):
    if req.transform == 'both':
        return []                       # one core is cyclic or negacyclic; the choice is built in
    o = dict(req.options.get(ARCH, {}))
    opt = dict(FULL if 'full' in o.pop('grid', []) else DEFAULTS)
    opt.update(o)
    n, d, nwc = req.n, req.direction, req.transform == 'negacyclic'
    M = req.M
    modes = [m for m in _modes(req) if m in opt['modulus']]
    out = []
    for (U, g) in _geometries(req):
        if 'U' in opt and U not in opt['U'] or 'g' in opt and g not in opt['g']:
            continue
        if U == 1 and 'U' not in opt:
            continue                    # one stage per round is the iterative NTT: left to that architecture
                                        # (options {'U': [1, ...]} lists it again)
        W = g << U
        ios = [v for v in _ioValues(opt['ioLanes'], W, n) if v <= req.maxLanes]
        if not ios and list(opt['ioLanes']) == ['W']:
            # the core is wider than the data port: the widest narrower I/O the port carries (the block still
            # works on W coefficients per cycle; without this no core wider than the port was listed)
            ios = sorted(v for v in _ioValues(['/2', '/4', '/8', '/16', '/32'], W, n) if v <= req.maxLanes)[-1:]
        for mode in modes:
            loadable = mode in ('load', 'record', 'stream_load')
            stream = mode in ('stream', 'stream_load')
            if stream:
                srcs = ['stream']
            else:
                srcs = [s for s in opt['twiddleSource']]
            ks = [None]
            if mode in ('load', 'stream_load'):
                ks = []
                for k in opt['loadSlots']:
                    k = M if k == 'M' else int(k)
                    # fewer sets than moduli cannot change the modulus per polynomial: not listed when that is asked
                    if 1 <= k <= M and k not in ks and not (req.perPolyModulus and M > 1 and k < M):
                        ks.append(k)
            for src in srcs:
                grid = {
                    'slots': opt['slots'],
                    'ioLanes': ios,
                    'loadSlots': ks,
                    'unified': [u for u in opt['unified'] if not u or (d != 'forward' and src in ('rom', 'stream'))],
                    'inverseScale': [s for s in opt['inverseScale'] if s == 'output' or (not nwc and d != 'forward')],
                    'twistSource': opt['twistSource'] if d != 'forward' else ['tab'],
                    'shareInverseTwiddles': [s for s in opt['shareInverseTwiddles']
                                             if not s or (not nwc and d == 'both' and src == 'rom' and mode != 'record')],
                    'reduction': [r for r in opt['reduction'] if r != 'shoup' or src in ('rom', 'stream')]
                    + [r for r, k in FORM_REDS.items()          # run-time moduli of a stated form
                       if k == req.modulusForm and mode in ('load', 'record', 'stream_load')
                       and ('reduction' not in o or r in o['reduction'])],
                    'multiplier': opt['multiplier'],
                    'dspFraction': opt['dspFraction'],
                    'bramFraction': [b for b in opt['bramFraction'] if b is None or src == 'auto'],
                    'outReady': opt['outReady'], 'outDepth': opt['outDepth'], 'outputOrder': opt['outputOrder'],
                    'fanout': opt['fanout'], 'fanoutLoads': opt['fanoutLoads'], 'crossRegs': opt['crossRegs'],
                    'ramLatency': opt['ramLatency'], 'memStyle': opt['memStyle'], 'twiddleStyle': opt['twiddleStyle'],
                    'genMinBits': opt['genMinBits'] if src in ('rec', 'otf', 'tree', 'auto') else opt['genMinBits'][:1],
                }
                names = list(grid)
                for vals in itertools.product(*(grid[k] for k in names)):
                    p = dict(zip(names, vals))
                    uni = p['unified']
                    if uni and p['inverseScale'] != 'output':
                        continue                    # unified sets the scale itself: listed once
                    twist = d != 'forward' and p['inverseScale'] == 'output' and not uni
                    if p['twistSource'] != 'tab' and not twist:
                        continue                    # no output twist to generate
                    if p['shareInverseTwiddles'] and (uni or p['fanout']):
                        continue
                    if p['dspFraction'] is not None and p['multiplier'] != 'dsp':
                        continue
                    p['dspTotal'] = totalOf(req, p['dspFraction']) if p['multiplier'] == 'dsp' else None
                    if p['bramFraction'] is not None and (uni or p['reduction'] == 'shoup'):
                        continue                    # the tables are fixed: nothing a budget can move
                    if p['fanoutLoads'] != 'register' and not p['fanout']:
                        continue
                    buf = p['outReady'] or p['outputOrder'] == 'natural' or (mode == 'record' and p['ioLanes'] != W)
                    if p['outDepth'] is not None and not buf:
                        continue
                    p.update(U=U, g=g, modulus=mode, twiddleSource=src)
                    out.append(p)
    return out


def sizing(req, params):
    """(family, size, inner): the size is the group count g, which sets the butterfly count g U 2^(U-1) of a block
    shape. A family is a block depth U with a modulus mode.
    inner = (the other options, slots). The slots are the polynomials in flight: more of them raise the throughput
    only while a round is shorter than the block's pipeline, and each one adds memory and latency. That pipeline
    depends on the options (reduction, twiddle source, clock), so the slots are sized per option combination: of
    each one only the smallest slot count that meets the requirements is kept."""
    rest = tuple(sorted((k, str(v)) for k, v in params.items() if k not in ('slots', 'S')))
    return (params['U'], params['modulus']), params['g'], (rest, params['slots'])


def innerNeeded(req, params, record, run: float = float('inf')):
    """The slot count this option combination needs for the throughput target, from the priced core `record` (the
    same options with params['slots'] slots), or None when no slot count can help.

    cycles per polynomial = R max(T, ceil(P / S)), with R = ceil(L / U) rounds, T = n / (g 2^U) cycles per round
    and P the pipeline latency of a round. P is read from the priced core. A core that already runs at R T, or
    one that reaches the target and fails another requirement, gains nothing from more slots: they add memory and
    latency only."""
    import math
    L = req.n.bit_length() - 1
    U, g, S0 = params['U'], params['g'], params['slots']
    R = -(-L // U)
    T = req.n // (g << U)
    extra = record.effectiveInterval(run) - record.interval          # the cost of a modulus change, per polynomial
    target = req.targetInterval - extra
    if record.interval <= target or record.interval <= R * T:
        return None
    P = S0 * record.interval / R                # ceil(P / S0) = interval / R, so P is at most this
    per = math.floor(target / R)                # cycles a round may take
    if per < T or per < 1:
        return None
    return math.ceil(P / per)


def quickLatency(req, params):
    """A lower bound of the latency (first input beat to last output beat): ceil(L / U) rounds of n / (g 2^U)
    cycles, and the output beats cannot start before the last input beat."""
    L = req.n.bit_length() - 1
    U, g = params['U'], params['g']
    return max(-(-L // U) * (req.n // (g << U)), 2 * (req.n // params['ioLanes']) - 1)


def sideKinds(req, params) -> set:
    """Kinds of side traffic this point surely has, from its modulus mode (never more than the model lists)."""
    return {'load': {'table_load'}, 'record': {'record_stream'}, 'stream': {'twiddle_stream'},
            'stream_load': {'twiddle_stream', 'table_load'}}.get(params['modulus'], set())


def quick(req, params):
    '''(a lower bound of the interval, butterflies): ceil(L / U) rounds of n / (g 2^U) cycles each, or the I/O
    beats. The interval is longer when a round is shorter than the block's pipeline and the slots do not fill it.'''
    L = req.n.bit_length() - 1
    U, g = params['U'], params['g']
    return max(-(-L // U) * (req.n // (g << U)), req.n // params['ioLanes']), g * U * (1 << (U - 1))


# --- the scheme -----------------------------------------------------------------------------------------

def _name(req, p: dict) -> str:
    h = hashlib.sha1(json.dumps([req.n, list(req.moduli), req.qBits, req.M, req.transform, req.direction,
                                 req.clockMhz, p] + ([req.form] if req.modulusForm != 'ntt' else []),
                                sort_keys=True, default=str).encode()).hexdigest()[:8]
    return (f"hy{req.n.bit_length() - 1}_U{p['U']}g{p['g']}S{p['slots']}_{p['modulus']}_{p['twiddleSource']}_"
            f"{p['reduction']}_{h}")


def _core(req, p: dict) -> dict:
    '''Everything `build` needs besides the options (plain values).'''
    mode, S = p['modulus'], p['slots']
    if mode in ('fixed', 'rom', 'stream'):
        moduli = [int(q) for q in req.moduli][:req.M]
    elif mode == 'record':
        moduli = _moduliFor(req, S + 1)
    else:
        moduli = _moduliFor(req, p['loadSlots'])
    return {'n': req.n, 'moduli': moduli, 'negacyclic': req.transform == 'negacyclic', 'direction': req.direction,
            'clockMhz': req.clockMhz, 'width': req.width, 'M': req.M, 'form': req.form}


def _scheme(name: str, p: dict, core: dict):
    '''The HybridNTTScheme of one point (as runHybridNTT.hybrid, with the multiplier choice).'''
    if _repoRoot() not in sys.path:
        sys.path.insert(0, _repoRoot())
    from operator_modeling.core.IntType import IntType
    from operator_modeling.ntt.hybrid.HybridNTTScheme import HybridNTTScheme
    from operator_modeling.modmult.ReductionScheme import (BarrettReduction, MontgomeryReduction, WordLevelMontgomery,
                                                           KRedReduction, SolinasReduction)
    _patch()
    reds = {'barrett': BarrettReduction, 'mont': MontgomeryReduction, 'wlm': WordLevelMontgomery,
            'kred': KRedReduction, 'solinas': SolinasReduction}
    red, mode = p['reduction'], p['modulus']
    args = dict(multiplierKind='shoup') if red == 'shoup' else dict(reduction=reds[red])
    if p['multiplier'] != 'dsp':
        args['multiplier'] = p['multiplier']
    nwc, moduli = core['negacyclic'], list(core['moduli'])
    loadable = mode in ('load', 'record', 'stream_load')
    kw = dict(twiddleSource=p['twiddleSource'], twistSource=p['twistSource'], unified=p['unified'],
              ramLatency=p['ramLatency'], memStyle=p['memStyle'], twiddleStyle=p['twiddleStyle'], loadable=loadable,
              ioLanes=p['ioLanes'], crossRegs=p['crossRegs'], fanout=p['fanout'], fanoutLoads=p['fanoutLoads'],
              outReady=p['outReady'], outDepth=p['outDepth'], outputOrder=p['outputOrder'],
              twiddleBuffer='record' if mode == 'record' else None,
              shareInverseTwiddles=p['shareInverseTwiddles'], genMinBits=p['genMinBits'])
    fam = None
    if loadable or (red == 'wlm' and len(moduli) > 1):
        class _R:                                   # the two fields _family reads
            transform = 'negacyclic' if nwc else 'cyclic'
            n = core['n']
            form = core.get('form')
        fam = _family(_R, moduli, red)
        kw['family'] = fam
    one = len(moduli) == 1 and not loadable
    s = HybridNTTScheme(name, core['n'], p['U'], p['g'], q=moduli[0] if one else 0, moduli=None if one else moduli,
                        negacyclic=nwc, direction=core['direction'], inverseScale=p['inverseScale'], butterfly=args,
                        slots=p['slots'], targetFmaxMhz=core['clockMhz'], **kw)
    s.setInputBound(IntType(0, (fam.qMax if loadable else max(moduli)) - 1))
    if p['dspFraction'] is not None:
        s.setDspBudget(fraction=p['dspFraction'])
    elif p.get('dspTotal') is not None:
        s.setDspBudget(total=p['dspTotal'])
    if p['bramFraction'] is not None:
        s.setBramBudget(total=p['bramFraction'] * s.bramCount())
    return s


def _spec(s, name: str) -> dict:
    from operator_modeling.ntt.hybrid.HybridNTT import HybridNTT
    return HybridNTT(s).getOperatorInterface(name, 1)


def loadRegions(sp: dict) -> list:
    '''The load regions (width, depth) of a loadable core, by the emitter's rules (`HybridNTT_RTL_gen`): every
    table inside is a RAM and every modulus constant a register file of one word per table set.'''
    TW = sp['twWidth']
    TWW = TW + sp.get('wpWidth', 0)
    ext, M = bool(sp.get('external')), sp['M']
    regs = []
    for t in sp['tables']:
        if t['src'] == 'rec':
            regs += [(TW, len(t['base'])), (TW, len(t['upd']))]
        elif t['src'] == 'otf':
            regs += [(TW, len(t['lo'])), (TW, len(t['hi']))]
        elif t['src'] == 'tree':
            regs.append((TW, len(t['cst'])))
        elif not ext:
            regs.append((TWW, len(t['values'])))
    tw = sp['twist']
    if tw is not None and tw.get('src') == 'rec':
        regs += [(TW, len(b)) for b in tw['rec']['base']] + [(TW, len(tw['rec']['upd']))]
    elif tw is not None:
        regs += [(TW, len(v)) for v in tw['tables']]
    for cons, ports in sp['qports'].items():
        regs += [(w, M) for _, w in ports]
    return regs


def regionsOf(s) -> list:
    '''The same list as `loadRegions(spec)` from the scheme's counts, without building the table values
    (the test `t_regions.py` and the port check compare the two).'''
    from operator_modeling.ntt.hybrid.HybridNTT import HybridNTT
    M, D = len(s.moduliList()), len(s.dirs)
    TW = max(1, (s.qMax() - 1).bit_length())
    TWW = TW + s.wpWidth()
    ext = s.twiddleSource == 'stream'
    regs = []
    for ti, t in builtins.enumerate(s.roundTables()[0]):
        src = s.tableSource(ti)
        if src == 'rec':
            regs += [(TW, s.recK(ti) * D * M), (TW, D * M)]
        elif src == 'otf':
            h, sb = s.otfBits(ti), s.sigBits(t['r'])
            regs += [(TW, (1 << h) * D * M), (TW, (1 << (sb - h)) * D * M)]
        elif src == 'tree':
            regs.append((TW, D * M))
        elif not ext:
            regs.append((TWW, s.entryCount(t['r']) * s.tableDirs(ti) * M))
    if s.twistMultiplier is not None and s.twistSrc == 'rec':
        regs += [(TW, s.twistRecD() * D * M)] * s.W + [(TW, D * M)]
    elif s.twistMultiplier is not None:
        regs += [(TW, s.T * D * M)] * s.W
    bu = s.butterflyUnit()
    bs = bu.getOperatorInterface(f'{s.name}_bu', 1)
    regs += [(w, M) for (pn, w) in bs.extraPorts if pn not in ('W', 'WP', 'DIR')]
    if s.twistMultiplier is not None:
        dps = s.twistMultiplier.getOperatorInterface(f'{s.name}_twist', 1)
        regs += [(x.bitWidth, M) for x in dps.inputs if x.name not in ('A', 'B')]
    if s.generator() is not None:
        gds = s.generator().getOperatorInterface(f'{s.name}_gen', 1)
        regs += [(x.bitWidth, M) for x in gds.inputs if x.name not in ('A', 'B')]
    if s.stageHalve:
        regs.append((s.qMax().bit_length(), M))
    return regs


def externalTables(s) -> list:
    '''(table index, address bits, words) of the tables a 'stream' core reads from outside (the emitter keeps a
    table of one word inside as a constant unless the core is loadable).'''
    M, out = len(s.moduliList()), []
    for ti, t in builtins.enumerate(s.roundTables()[0]):
        words = s.entryCount(t['r']) * s.tableDirs(ti) * M
        if words > 1 or s.loadable:
            out.append((ti, _bits(words), words))
    return out


def portList(s, sp: dict | None = None) -> list:
    '''The boundary ports of the generated top module: (name or prefix, direction, bits, count). The rules are the
    emitter's (`hybrid_ntt.py` core and `_io_wrapper`, `hybrid_ports.py` wrapper); `checkPorts` compares them
    with a generated module.'''
    Wd, OW, MB = s.memBound.bitWidth, s.outputBound.bitWidth, s.midxBits()
    record = s.twiddleBuffer == 'record'
    out = [('clk', 'in', 1, 1), ('rst', 'in', 1, 1), ('in_valid', 'in', 1, 1), ('in_ready', 'out', 1, 1)]
    if MB and not record:
        out.append(('MIDX', 'in', MB, 1))
    if s.direction == 'both':
        out.append(('DIR', 'in', 1, 1))
    out.append(('x_in_', 'in', Wd, s.io))
    out.append(('out_valid', 'out', 1, 1))
    if s.outReady:
        out.append(('out_ready', 'in', 1, 1))
    if MB and not record:
        out.append(('midx_out', 'out', MB, 1))
    if s.direction == 'both':
        out.append(('dir_out', 'out', 1, 1))
    out.append(('y_out_', 'out', OW, s.io))
    if s.twiddleSource == 'stream':
        tww = max(1, (s.qMax() - 1).bit_length()) + s.wpWidth()
        for ti, ab, _ in externalTables(s):
            out += [(f'tw_addr_{ti}', 'out', ab, 1), (f'tw_data_{ti}', 'in', tww, 1)]
    if s.loadable:
        regs = loadRegions(sp) if sp is not None else regionsOf(s)
        LA, LW = max(_bits(d) for _, d in regs), max(w for w, _ in regs)
        if record:
            out += [('tw_valid', 'in', 1, 1), ('tw_ready', 'out', 1, 1), ('tw_data', 'in', LW, 1)]
        else:
            out += [('ld_we', 'in', 1, 1), ('ld_sel', 'in', _bits(len(regs)), 1), ('ld_addr', 'in', LA, 1),
                    ('ld_data', 'in', LW, 1)]
    return out


def _ports(req, s, sp, p: dict) -> tuple:
    '''(Port list, peak bits, table words kept outside per modulus and direction, words of one load).'''
    n, io = s.n, s.io
    pl = {nm: (bits, cnt) for nm, _, bits, cnt in portList(s, sp)}
    ports = [Port('data_in', pl['x_in_'][0], io, n / io, name='x_in_'),
             Port('data_out', pl['y_out_'][0], io, n / io, name='y_out_')]
    peak = io * (pl['x_in_'][0] + pl['y_out_'][0])
    D, M = len(s.dirs), len(s.moduliList())
    outside, loadWords = 0, 0
    if s.twiddleSource == 'stream':
        # one read per core beat of the round that uses the table: T addresses out, T words back; no valid signal
        for ti, ab, words in externalTables(s):
            ports += [Port('twiddle_stream', pl[f'tw_data_{ti}'][0], 1, s.T, name=f'tw_data_{ti}'),
                      Port('twiddle_stream', ab, 1, s.T, name=f'tw_addr_{ti}')]
            peak += pl[f'tw_data_{ti}'][0] + ab
            outside += words // (D * M)
    if s.loadable:
        regs = loadRegions(sp) if sp is not None else regionsOf(s)
        loadWords = sum(d for _, d in regs) // M            # one table set: one word per cycle
        outside += -(-loadWords // D)
        if s.twiddleBuffer == 'record':
            LW = pl['tw_data'][0]
            # one record per polynomial: the header beat always, the table set when the modulus changes
            ports += [Port('record_stream', LW, 1, 1, name='tw_data'),
                      Port('record_stream', LW, 1, loadWords, perLoad=True, name='tw_data')]
            peak += LW
        else:
            for nm in ('ld_data', 'ld_addr', 'ld_sel'):
                ports.append(Port('table_load', pl[nm][0], 1, loadWords, perLoad=True, name=nm))
                peak += pl[nm][0]
    return ports, peak, outside, loadWords


def evaluate(req, params):
    if req.transform == 'both':
        return None
    p = dict(params)
    mode = p['modulus']
    name = _name(req, p)
    core = _core(req, p)
    try:
        s = _quiet(lambda: _scheme(name, p, core))
    except (ValueError, AssertionError, NotImplementedError):
        return None                     # the generator refuses the combination
    if s.S != p['slots']:
        return None
    loadable = s.loadable
    sp = None                           # the regions come from the scheme's counts (`regionsOf`)
    res = _quiet(lambda: s.resources())
    M = req.M
    flags = []
    interval = float(s.cyclesPerPolynomial())
    latency = float(_quiet(lambda: s.latency()))
    ports, peak, outside, loadWords = _ports(req, s, sp, p)
    reload, perPolyQ = 0.0, True
    if mode == 'record':
        P = 6 * s.S + 6
        beats = loadWords + 1
        if beats <= RECORD_SHORT * interval:
            # a record this much shorter than the core's period never held a polynomial back (t_record.py: 14 of
            # 14 twin runs at 2^10 and 2^12, ratios up to 0.86); the long records below are run or estimated
            reload = 0.0
        elif beats <= interval or P * max(interval, beats) <= RECORD_SIM_CYCLES:
            new = float(_quiet(lambda: s.portsSteadyInterval(P, keep=[False] * P)))
            reload = max(0.0, new - interval)
        else:
            # the twin is too long to run here. Estimate: the record's own length (120 twin runs at 2^10 and 2^12
            # were 2 % below to 22 % above it, the period snaps to the slot grid)
            reload = float(beats + 6 - interval)
            flags.append('record period with a new modulus per polynomial is an estimate (record length + 6, '
                         'twin runs were -2 % to +22 % of it), not simulated')
        # the modulus travels with every polynomial, so the core can change it per polynomial; what a change
        # costs is `reloadCycles` (effectiveInterval(1) = the period with a new modulus every polynomial). The same
        # reading as the iterative adapter (SHARED_REQUESTS.md, 2026-11-15).
        perPolyQ = True
        if reload:
            flags.append(f'a new modulus costs {reload:g} idle cycles (record of {beats} beats, one entry per beat)')
    elif mode in ('load', 'stream_load'):
        K = p['loadSlots']
        if K < M:
            perPolyQ = False
            run = req.effRun
            if K == 1:
                # the last polynomial of the old modulus leaves, then the set is written, one word per cycle
                reload = max(0.0, latency - interval) + loadWords
            else:
                # the next set is written behind the running one; idle only when the run is shorter than the load
                reload = 0.0 if run == float('inf') else max(0.0, loadWords + latency - run * interval)
            flags.append(f'{K} table set(s) for {M} moduli: the reload ({reload:g} cycles) is an estimate, not simulated')
    if p['dspFraction'] is not None or binds(s):
        flags.append('model: LUT 5 to 10 % low under a DSP budget')
    if p['unified']:
        flags.append('model: LUT 5 to 10 % high with unified butterflies')
    if s.twiddleSource == 'stream':
        flags.append('twiddle stream ports have no valid: an address every cycle, the word ramLatency cycles later')
    rp = dict(p)
    rp['core'] = core
    rp['peakBits'] = peak
    rp['S'] = s.S
    rp['rounds'] = s.R
    rp['slotCycles'] = s.slotLength(s.S)
    return CoreRecord(
        arch=ARCH, name=name, params=rp, clockMhz=req.clockMhz,
        lut=res['lut'], ff=res['ff'], dsp=res['dsp'], bram36=res['bram'], uram=res['uram'],
        interval=interval, latency=latency, reloadCycles=reload, ports=ports,
        twiddleWordsInside=int(s.storedTwiddleWords()), twiddleWordsOutside=int(outside),
        perPolyModulus=bool(perPolyQ), perPolyDirection=req.direction == 'both',
        lanes=s.io, butterflies=s.butterflyCount(), flags=flags, modelNote=MODEL_NOTE)


# --- build ---------------------------------------------------------------------------------------------

def build(record, outdir, polys: int | None = None, seed: int = 9):
    '''RTL and the self-checking testbench of a record into `outdir` (RTL_generated/, testvectors/): `polys`
    different polynomials back to back, the modulus and the direction changing where the core allows it; the
    testbench checks every output beat's value, tags and cycle, so a slower interval fails.
    Returns {'top', 'files', 'run_dir', 'interval', 'latency', 'ports'}.'''
    import glob
    from operator_modeling.ntt.hybrid.HybridNTT import HybridNTT
    p = {k: v for k, v in record.params.items() if k not in ('core', 'peakBits', 'S', 'rounds', 'slotCycles')}
    core = record.params['core']
    s = _quiet(lambda: _scheme(record.name, p, core))
    n = core['n']
    # 4 S + 3 polynomials: enough for the steady windows of S after the start-up (as portsSteadyInterval)
    P = polys or 4 * s.S + 3
    qs = s.moduliList()
    rng = random.Random(seed)
    fq = [qs[(f * 7 + f // 3) % len(qs)] for f in range(P)]
    if s.direction == 'both':
        ds = ['inv' if (f + f // 2) & 1 else 'fwd' for f in range(P)]
    else:
        ds = ['inv' if s.direction == 'inverse' else 'fwd'] * P
    frames = [[rng.randrange(fq[f]) for _ in range(n)] for f in range(P)]
    outdir = os.path.abspath(outdir)
    m = _quiet(lambda: HybridNTT(s).emitRtl(record.name, outdir, frames=frames, direction=ds, q=fq,
                                            ports={} if s.portsOn() else None))
    files = sorted(glob.glob(os.path.join(outdir, 'RTL_generated', '*.sv')))
    return {'top': record.name, 'tb': record.name + '_tb', 'files': files, 'run_dir': outdir,
            'interval': m.get('interval'), 'latency': m.get('latency'), 'polys': P,
            'moduli': fq, 'directions': ds, 'ports': portList(s)}


# --- checks --------------------------------------------------------------------------------------------

def declaredPorts(path: str, top: str) -> list:
    '''(name, direction, bits) of module `top` in a generated file, in order.'''
    import re
    with open(path, encoding='utf-8') as f:
        txt = f.read()
    m = re.search(r'module\s+' + re.escape(top) + r'\s*\((.*?)\);', txt, re.S)
    if not m:
        raise ValueError(f'module {top} not found in {path}')
    out = []
    for ln in m.group(1).split(','):
        ln = ln.strip()
        if not ln:
            continue
        mm = re.fullmatch(r'(input|output)\s+(?:logic|wire|reg)?\s*(?:\[(\d+):(\d+)\])?\s*(\w+)', ln)
        if not mm:
            raise ValueError(f'port line not understood: {ln!r}')
        bits = int(mm.group(2)) - int(mm.group(3)) + 1 if mm.group(2) else 1
        out.append((mm.group(4), 'in' if mm.group(1) == 'input' else 'out', bits))
    return out


def checkPorts(record, built: dict) -> list:
    '''Differences between the model's port list and the generated top module ([] when equal): names, directions,
    widths and counts, both ways. Also the Port entries of the record against the same module.'''
    import re
    top = built['top']
    path = os.path.join(built['run_dir'], 'RTL_generated', top + '.sv')
    got = declaredPorts(path, top)
    want = []
    for nm, d, bits, cnt in built['ports']:
        if nm.endswith('_') and nm in ('x_in_', 'y_out_'):
            want += [(f'{nm}{l}', d, bits) for l in range(cnt)]
        else:
            want.append((nm, d, bits))
    diffs = []
    gd, wd = {g[0]: g for g in got}, {w[0]: w for w in want}
    for nm in wd:
        if nm not in gd:
            diffs.append(f'model port {nm} is not in the module')
        elif gd[nm] != wd[nm]:
            diffs.append(f'{nm}: model {wd[nm][1:]}, module {gd[nm][1:]}')
    for nm in gd:
        if nm not in wd:
            diffs.append(f'module port {nm} is not in the model')
    for pt in record.ports:
        if pt.name.endswith('_') and pt.name in ('x_in_', 'y_out_'):
            names = [g for g in got if re.fullmatch(re.escape(pt.name) + r'\d+', g[0])]
        else:
            names = [g for g in got if g[0] == pt.name]
        if len(names) != pt.count or any(g[2] != pt.widthBits for g in names):
            diffs.append(f'record port {pt.kind} {pt.name}: {pt.count} x {pt.widthBits} bits, module has '
                         f'{[(g[0], g[2]) for g in names][:4]}')
    return diffs


def addBeatCounters(record, built: dict) -> dict:
    '''Check 2: add counters of the valid beats of every boundary port to the generated testbench (a block of
    its own before `endmodule`; the checks of the testbench stay as they are). The simulation then prints one
    line `[dse] ...`; `readBeatCounters` turns it into numbers. Stream twiddle ports have no valid signal and
    are not counted. Returns what the model expects for the testbench's job.'''
    top, run = built['top'], built['run_dir']
    tb = os.path.join(run, 'RTL_generated', top + '_tb.sv')
    with open(tb) as f:
        text = f.read()
    names = {n for (n, _, _) in declaredPorts(os.path.join(run, 'RTL_generated', top + '.sv'), top)}
    core = record.params['core']
    io = next(p.count for p in record.ports if p.kind == 'data_in')
    To, P = core['n'] // io, built['polys']
    outr = 'out_valid && out_ready' if 'out_ready' in names else 'out_valid'
    extra = ''
    if 'ld_we' in names:
        extra += '        if (ld_we) dse_ld <= dse_ld + 1;\n'
    if 'tw_valid' in names:
        extra += '        if (tw_valid && tw_ready) dse_rec <= dse_rec + 1;\n'
    blk = f'''
    // dse beat counters (check 2 of the design-space search)
    integer dse_c = 0, dse_in = 0, dse_out = 0, dse_ld = 0, dse_rec = 0;
    integer dse_fi = -1, dse_o0 = -1, dse_l0 = -1, dse_ok = -1;
    always @(posedge clk) begin
        dse_c <= dse_c + 1;
        if (in_valid && in_ready) begin dse_in <= dse_in + 1; if (dse_fi < 0) dse_fi <= dse_c; end
        if ({outr}) begin
            if (dse_out == 0) dse_o0 <= dse_c;
            if (dse_out % {To} == 0) $display("[dsep] %0d", dse_c);
            if (dse_out == {To - 1}) dse_l0 <= dse_c;
            if (dse_out == {(P - 1) * To}) dse_ok <= dse_c;
            dse_out <= dse_out + 1;
        end
{extra}    end
    final $display("[dse] in %0d out %0d load %0d record %0d first_in %0d out0 %0d last0 %0d outk %0d", dse_in, dse_out, dse_ld, dse_rec, dse_fi, dse_o0, dse_l0, dse_ok);
endmodule'''
    i = text.rindex('endmodule')
    if '[dse]' not in text:
        with open(tb, 'w') as f:
            f.write(text[:i] + blk.lstrip('\n') + text[i + len('endmodule'):])
    return {'polys': P, 'beatsPerPoly': To, 'io': io}


def readBeatCounters(log: str, record, built: dict) -> dict:
    '''The `[dse]` line of a simulation log against the model: per kind the counted beats per polynomial (or
    per load) and the model's `beatsPerNtt`, the interval and the latency. 'differences' lists what is not equal.'''
    import re
    m = re.search(r'\[dse\] in (\d+) out (\d+) load (\d+) record (\d+) first_in (-?\d+) out0 (-?\d+) last0 (-?\d+) '
                  r'outk (-?\d+)', log)
    if not m:
        return {'differences': ['no [dse] line in the log']}
    cin, cout, ld, rec, fi, o0, l0, ok = (int(x) for x in m.groups())
    P = built['polys']
    port = {(p.kind, p.perLoad): p for p in record.ports}
    out = {'in beats per polynomial': (cin / P, port[('data_in', False)].beatsPerNtt),
           'out beats per polynomial': (cout / P, port[('data_out', False)].beatsPerNtt),
           'job interval (twin)': ((ok - o0) / (P - 1), built['interval']), 'latency': (l0 - fi + 1, record.latency)}
    diff = []
    st = [int(x) for x in re.findall(r'\[dsep\] (\d+)', log)]
    S = record.params['S']
    if ('record_stream', True) not in port and len(st) == P and P >= 2 * S + 3:
        # the steady interval as the model defines it: the largest window of S polynomials after the start-up
        out['steady interval'] = (max((st[k + S] - st[k]) / S for k in range(S + 2, P - S)), record.interval)
    if ('table_load', True) in port:
        sets = len(record.params['core']['moduli'])
        lw = port[('table_load', True)].beatsPerNtt
        out['load beats per set'] = (ld / sets, lw)
    if ('record_stream', True) in port:
        lw = port[('record_stream', True)].beatsPerNtt
        k = (rec - P) / lw                 # records that carried a set (the others are the header alone)
        out['record beats'] = (rec, P + round(k) * lw)
        out['records with a set'] = (k, round(k))
        if not 0 <= round(k) <= P:
            diff.append('record count out of range')
        if round(k) == P and len(st) == P and P >= 2 * S + 3:
            # every record carried a set: the job is the case `interval + reloadCycles` prices
            out['steady interval, new modulus per polynomial'] = (
                max((st[j + S] - st[j]) / S for j in range(S + 2, P - S)), record.interval + record.reloadCycles)
    for name, (a, b) in out.items():
        if abs(a - b) > 1e-9:
            diff.append(f'{name}: simulation {a:g}, model {b:g}')
    out['differences'] = diff
    return out
