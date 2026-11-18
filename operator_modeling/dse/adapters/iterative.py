'''DSE adapter of the iterative (memory-based) NTT (`operator_modeling/ntt/iterative`).

enumerate(req)          every legal option combination over the grid below (plain dicts)
evaluate(req, params)   a CoreRecord from the build-free models (`resources()`, `simulateJob`), or None
build(record, outdir)   RTL and the self-checking testbench (`runModularNTT.iterative`, `IterativeNTT.emitRtl`)
quick(req, params)      (interval lower bound, butterflies) from a formula

Options (the keys of a params dict; `req.options['iterative'] = {option: [allowed values]}` restricts any of them,
`{'grid': ['full']}` opens every knob to its full list):

  B                 butterflies, every power of two with 4B <= n
  ioLanes           coefficients per data beat. Not a free option: 2B (the full width) when the core has no
                    multiplier on its output, else every power of two up to min(2B, req.maxLanes), of which the
                    search keeps the narrowest that meets the requirements (`sizing`). Options may name widths.
  memOrg            'inplace' | 'constgeo'   ('auto' of the generator only picks one of these two)
  crossRegs         0 .. 4, constant geometry only (die-crossing registers)
  supply            where the twiddles come from:
                      'rom'     ROM, one fixed modulus (needs req.moduli with one modulus)
                      'mrom'    ROMs of every modulus, port MIDX (needs req.moduli, two or more)
                      'load'    run-time modulus, tables written through the load port before a job
                      'stream'  run-time modulus, a record of every table entry per polynomial on tw_data
                      'gen'     run-time modulus, tables generated on chip from a short record (seeds, factors)
  twiddleBuffer     'single' (rom, mrom, load) | 'recycle' | 'double' (stream) | 'recycle' (gen)
  twiddleLanes      stream: table entries per record beat, every power of two up to B
  qSwitch           'bubble' | 'inline' (mrom, stream, gen)
  dirPerPoly        stream with both directions: the direction in the record header instead of the DIR port
  recGroup          gen: butterflies per generator, powers of two up to B (in place) or B/2 (constant geometry)
  recSeeds          gen in place: 0, 'auto', or K = 1 .. 32 seeds per group and stage on the record stream
  recMultiplier     gen: None (as the butterflies) | 'booth' (generators on LUTs)
  direction         of the core: req.direction, and 'both' when one direction is asked
  inverseScale      'output' | 'stage' (stage: cyclic with an inverse)
  shareInverseTwiddles   cyclic, both directions, in place: True | False
  reduction         barrett, mont, wlm, wlm-generic, shoup; with a fixed modulus also table, shiftadd and the
                    special-form ones the modulus fits (kred, solinas, mersenne, gold, fold)
  multiplier        'dsp' | 'booth'
  constBackend      fixed modulus: 'lut' | 'dsp' | 'booth'
  qBackend          run-time modulus (also mrom): 'dsp' | 'booth'
  dspTotal          the user's DSP limit as the total DSP budget (dsplimit.py), on multiplier 'dsp'
  dspFraction       only when the options name it: 0.75 | 0.5 | 0.25 of the pure-DSP count (`setDspBudget`)
  memStyle, twiddleStyle   'auto' (base) | 'atp' | 'distributed' | 'block' | 'ultra'
  ramLatency        2 (base) | 1 | 3 | 4
  fanout            None (base) | 64 | 32, constant geometry, not with mrom / stream
  fanoutKeepSinks   True (base) | False;   fanoutLoads  'register' (base) | 'pins'   (with a fanout)

"base" marks the knobs that are held at the generator's default unless the caller widens them: their full product
(5 x 5 x 4 memory variants, 3 x 2 x 2 fan-out variants) multiplies the point count by about 100 to 300.
'''
from __future__ import annotations

import contextlib
import hashlib
import io as _io
import itertools
import json
import os
import sys

from ..record import CoreRecord, Port

ARCH = 'iterative'
_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))

#: option -> (base list, full list). The base list is used unless req.options widens it.
MEM_STYLES_ALL = ['auto', 'atp', 'distributed', 'block', 'ultra']
KNOBS = {
    'memStyle': (['auto'], MEM_STYLES_ALL),
    'twiddleStyle': (['auto'], MEM_STYLES_ALL),
    'ramLatency': ([2], [1, 2, 3, 4]),
    'fanout': ([None], [None, 64, 32]),
    'fanoutKeepSinks': ([True], [True, False]),
    'fanoutLoads': (['register'], ['register', 'pins']),
}
CROSS_REGS = [0, 1, 2, 3, 4]
DSP_FRACTIONS = [None, 0.75, 0.5, 0.25]
SUPPLIES = ['rom', 'mrom', 'load', 'stream', 'gen']
RUNTIME_REDS = ['barrett', 'mont', 'wlm', 'wlm-generic', 'shoup']
#: run-time reductions that a stated modulus form opens (Requirements.modulusForm)
FORM_REDS = {'kred': 'kred', 'solinas': 'pseudo_mersenne'}
from ..dsplimit import binds, totalOf       # noqa: E402
FIXED_REDS = ['barrett', 'mont', 'wlm', 'shoup', 'table', 'shiftadd', 'kred', 'solinas', 'mersenne', 'gold', 'fold']
REC_SEEDS = [0, 'auto', 1, 2, 4, 8, 16, 32]

#: what the area model was fitted on (ntt_hw/experiments/overnight_2026-11-14/iterative and gap): its error there
MODEL_BASE = ('area: IterativeNTTScheme.resources() (fit 2026-11-14, 62 routed rows: LUT 13 % max / 3.6 % mean, '
              'FF 21 % max / 2.6 % mean, area units 4.4 % max; 6 held-out rows: area units 0.8 % max); '
              'cycles: simulateJob (equal to xsim on 28 of 28 points), interval = steady gap between output starts, '
              'latency = first accepted beat to last output beat, both cycles counted')


# --- the generator, loaded lazily (runModularNTT sits at the worktree root) -----------------------------------

_RUN = None


def _run():
    global _RUN
    if _RUN is None:
        if _ROOT not in sys.path:
            sys.path.insert(0, _ROOT)
        with contextlib.redirect_stdout(_io.StringIO()):
            import runModularNTT as R
        _RUN = R
    return _RUN


def _quiet(fn):
    with contextlib.redirect_stdout(_io.StringIO()):
        return fn()


# --- a faster twin of two pure-Python O(n) loops of the scheme (same numbers; checked in the adapter's tests) ---

_LATE = {}
_FAST = None


def _cyc(np, m, n, b, L, H, org, rot, s):
    if org == 'constgeo':
        k = s % L if L > 0 else 0
        pos = (((m >> k) | (m << (L - k))) & (n - 1)) if k else m
        x = pos >> (b + 1)
        if H <= 0:
            return x
        sh = (s + rot) % H
        kk = (H - (sh % H)) % H                      # rotl by sh = rotr by H - sh
        return (((x >> kk) | (x << (H - kk))) & ((1 << H) - 1)) if kk else x
    h = m >> (b + 1)
    if s <= b:
        return h
    p = s - b - 1
    return ((((h >> (p + 1)) << p) | (h & ((1 << p) - 1))) << 1) | ((m >> b) & 1)


def _late(n, b, L, H, org, rot, s):
    key = (n, b, org, rot if org == 'constgeo' else 0, s)
    if key not in _LATE:
        import numpy as np
        m = np.arange(n, dtype=np.int64)
        _LATE[key] = int((_cyc(np, m, n, b, L, H, org, rot, s) - _cyc(np, m, n, b, L, H, org, rot, s + 1)).max())
    return _LATE[key]


def _fastClass():
    '''IterativeNTTScheme with `stageLate` computed by numpy and kept per process (the original walks all n points
    in Python for every stage and, under constant geometry, for every read rotation).'''
    global _FAST
    if _FAST is None:
        from ...ntt.iterative.IterativeNTTScheme import IterativeNTTScheme

        class FastIterativeNTTScheme(IterativeNTTScheme):
            def stageLate(self, s):
                return _late(self.n, self.b, self.L, self.H, self.memOrg, self.cgRot, s)
        _FAST = FastIterativeNTTScheme
    return _FAST


# --- requirement -> moduli, families ----------------------------------------------------------------------------

def _nwc(req) -> bool | None:
    '''The core's negacyclic flag. The flag is fixed at build time, so no iterative core serves 'both'.'''
    return {'cyclic': False, 'negacyclic': True}.get(req.transform)


def _rootOrder(req) -> int:
    return 2 * req.n if req.transform != 'cyclic' else req.n


def _family(req, red):
    '''The run-time family of a reduction: any odd modulus of the width, or the NTT-friendly ones for word-level
    Montgomery (q = qH 2^v + 1; v from the moduli when they are known, else from the root order).'''
    from .. import modform
    MF = _run().MF
    w = req.width
    if red == 'wlm':                    # v also from the stated modulus form (friendly, or K-RED's k 2^m + 1)
        v = min(modform.friendlyV(req.form, w, _rootOrder(req), req.moduli), w - 2)
        return MF.friendly(v, w - v, 1)
    if red in modform.OPENS:            # K-RED, Solinas: only over the form the user states
        fam = None if req.moduli else modform.family(req.form, red, w, _rootOrder(req))
        if fam is None:
            raise ValueError(f'{red}: no run-time form for these moduli')
        return fam
    return MF.odd(w)


def _testModuli(req, s, count: int) -> list:
    '''Moduli for a testbench: the requirement's, else primes of the family with the root order.'''
    import random
    if req.moduli:
        ms = list(req.moduli)
        return [ms[i % len(ms)] for i in range(count)] if len(ms) >= count or s.multiRom or not s.runtime else ms
    rng = random.Random(13)
    qs = []
    while len(qs) < count:
        q = _run()._jobQ(s, rng)
        if q not in qs:
            qs.append(q)
    return qs


# --- building a scheme from a params dict -----------------------------------------------------------------------

def _kwargs(req, p) -> dict:
    '''The arguments of `runModularNTT.iterative` for one point.'''
    red, sup = p['reduction'], p['supply']
    kw = dict(n=req.n, B=p['B'], red=red, nwc=bool(p['negacyclic']), direction=p['direction'],
              targetFmaxMhz=float(req.clockMhz), inverseScale=p['inverseScale'], ioLanes=p['ioLanes'],
              memStyle=p['memStyle'], twiddleStyle=p['twiddleStyle'], ramLatency=p['ramLatency'],
              memOrg=p['memOrg'], twiddleBuffer=p['twiddleBuffer'], multiplier=p['multiplier'])
    if p['memOrg'] == 'constgeo':
        kw['crossRegs'] = p['crossRegs']
    if p.get('shareInverseTwiddles') is not None:
        kw['shareInverseTwiddles'] = p['shareInverseTwiddles']
    if sup == 'rom':
        kw.update(q=req.moduli[0], source='rom', constBackend=p['constBackend'])
    elif sup == 'mrom':
        kw.update(moduli=list(req.moduli), qBackend=p['qBackend'], qSwitch=p['qSwitch'])
        kw.pop('twiddleBuffer')
        if red == 'wlm':
            kw['family'] = _family(req, red)
    else:
        kw.update(family=_family(req, red), source='rec' if sup == 'gen' else 'ram', qBackend=p['qBackend'])
        if sup != 'load':
            kw['qSwitch'] = p['qSwitch']
        if sup == 'stream':
            kw['twiddleLanes'] = p['twiddleLanes']
            if p.get('dirPerPoly'):
                kw['dirPerPoly'] = True
        if sup == 'gen':
            kw['recGroup'] = p['recGroup']
            if p.get('recSeeds'):
                kw['recSeeds'] = p['recSeeds']
            if p.get('recMultiplier') == 'booth':
                kw['recMultiplier'] = {'multiplier': 'booth', 'qBackend': 'booth'}
    if p.get('fanout') is not None:
        kw.update(fanout=p['fanout'], fanoutKeepSinks=p['fanoutKeepSinks'], fanoutLoads=p['fanoutLoads'])
    if p.get('dspFraction') is not None:
        kw['dspFraction'] = p['dspFraction']
    elif p.get('dspTotal') is not None:
        kw['dspTotal'] = p['dspTotal']
    return kw


def _make(cls, name, n, B, q=0, red='barrett', nwc=False, direction='forward', family=None, source=None, **bu):
    '''`runModularNTT.iterative`, line for line, with the scheme class as an argument.'''
    R = _run()
    from ...core.IntType import IntType
    mk = 'shoup' if red == 'shoup' else 'reduction'
    rcls = R.REDUCTIONS.get(red.split('-')[0], R.BarrettReduction)
    tgt = bu.pop('targetFmaxMhz', None)
    iscale = bu.pop('inverseScale', 'output')
    frac, total = bu.pop('dspFraction', None), bu.pop('dspTotal', None)
    extra = {k: bu.pop(k) for k in ('ioLanes', 'memStyle', 'twiddleStyle', 'ramLatency', 'shareInverseTwiddles',
                                    'twiddleBuffer', 'twiddleLanes', 'memOrg', 'crossRegs', 'dirPerPoly', 'recGroup',
                                    'fanout', 'recMultiplier', 'fanoutKeepSinks', 'fanoutLoads', 'recSeeds', 'qSwitch',
                                    'moduli')
             if k in bu}
    args = dict(multiplierKind=mk, reduction=rcls, reductionArgs=(R.UNITS.get(red, ({},))[0] or {}), **bu)
    s = cls(name, n, B, q=q, family=family, negacyclic=nwc, direction=direction,
            scaleInverse=direction != 'forward', butterfly=args, twiddleSource=source,
            targetFmaxMhz=tgt, inverseScale=iscale, **extra)
    s.setInputBound(IntType(0, (family.qMax if family is not None else q or max(s.moduli)) - 1))
    if frac is not None or total is not None:
        s.setDspBudget(fraction=frac, total=total)
    return s


def scheme(req, p, fast: bool = True, name: str = 'it'):
    '''The IterativeNTTScheme of a point. `fast=False`: through `runModularNTT.iterative` itself (the build path).'''
    kw = _kwargs(req, p)
    if fast:
        return _quiet(lambda: _make(_fastClass(), name, **kw))
    return _quiet(lambda: _run().iterative(name, **kw))


def pointName(req, p) -> str:
    form = [req.form] if req.modulusForm != 'ntt' else []       # names of the plain form stay as they were
    h = hashlib.sha1(json.dumps([req.n, list(req.moduli), req.qBits, req.clockMhz, p] + form, sort_keys=True,
                                default=str).encode()).hexdigest()[:8]
    return f"it_n{req.n}_b{p['B']}_io{p['ioLanes']}_{p['supply']}_{h}"


# --- enumerate ---------------------------------------------------------------------------------------------------

def _opts(req) -> dict:
    return dict(req.options.get(ARCH, {}) or {})


def _pick(opts, name, values, base=None):
    '''The values of an option: restricted by req.options; a knob (`base` given) stays at its base list unless
    the option is named or the full grid is asked.'''
    if name in opts:
        allow = opts[name]
        return [v for v in values if v in allow]
    if base is not None and 'full' not in (opts.get('grid') or []):
        return list(base)
    return list(values)


_REDOK = {}


def _reductionWorks(req, mode, red) -> bool:
    '''Does the generator build a butterfly with this reduction for the requirement's moduli? Tried once on a
    16-point core (the reductions refuse a modulus of the wrong shape with an exception).'''
    key = (mode, red, tuple(req.moduli), req.qBits, req.transform, req.clockMhz, tuple(sorted(req.form.items())))
    if key not in _REDOK:
        import copy
        r2 = copy.copy(req)
        r2.n = 16 if all((q - 1) % 32 == 0 for q in (req.moduli or [33])) else req.n
        p = dict(B=1, ioLanes=2, memOrg='inplace', crossRegs=0, supply=mode, twiddleBuffer='single',
                 direction='forward', negacyclic=_nwc(req), inverseScale='output', reduction=red, multiplier='dsp',
                 constBackend='lut', qBackend='dsp', dspFraction=None, memStyle='auto', twiddleStyle='auto',
                 ramLatency=2, qSwitch='bubble')
        try:
            s = scheme(r2, p)
            _quiet(s.resources)
            _REDOK[key] = True
        except Exception:
            _REDOK[key] = False
    return _REDOK[key]


def _pow2(lo, hi):
    out, v = [], lo
    while v <= hi:
        out.append(v)
        v *= 2
    return out


def supplies(req) -> list:
    '''The twiddle supplies that can serve the requirement.'''
    known = bool(req.moduli)
    ro = _rootOrder(req)
    if known and any((q - 1) % ro for q in req.moduli):
        return []
    needQ = req.perPolyModulus and req.M > 1
    needD = req.perPolyDirection and req.direction == 'both'
    out = []
    if known and req.M == 1 and len(req.moduli) == 1 and not needD:
        out.append('rom')
    if known and len(req.moduli) >= 2 and len(req.moduli) >= req.M:
        out.append('mrom')
    if not needQ and not needD:
        out.append('load')
    out += ['stream', 'gen']
    return out


def enumerate(req):
    '''Every legal option combination that can serve `req` (a generator of plain dicts).'''
    nwc = _nwc(req)
    if nwc is None:
        return                          # 'both' transforms: the negacyclic flag is fixed at build time
    o = _opts(req)
    n, L = req.n, req.n.bit_length() - 1
    needD = req.perPolyDirection and req.direction == 'both'
    sups = _pick(o, 'supply', supplies(req))
    dirs = _pick(o, 'direction', [req.direction] + (['both'] if req.direction != 'both' else []))
    knob = {k: _pick(o, k, full, base) for k, (base, full) in KNOBS.items()}
    # the user's DSP limit is the budget (dsplimit.py). Fractions are tried only when the options name them.
    fracs = _pick(o, 'dspFraction', DSP_FRACTIONS) if 'dspFraction' in o else [None]
    # Booth (LUT) multipliers are what a DSP limit of zero gives (checked: the same core), so with a DSP limit
    # they are listed only when the options name them
    lim = req.maxDsp is not None
    mults = _pick(o, 'multiplier', ['dsp', 'booth'] if not lim or 'multiplier' in o else ['dsp'])
    cbs = _pick(o, 'constBackend', ['lut', 'dsp', 'booth'] if not lim or 'constBackend' in o else ['lut', 'dsp'])
    qbs = _pick(o, 'qBackend', ['dsp', 'booth'] if not lim or 'qBackend' in o else ['dsp'])
    reds = {}
    for sup in sups:
        mode = sup if sup in ('rom', 'mrom') else 'load'
        cand = FIXED_REDS if sup == 'rom' else RUNTIME_REDS + [r for r, k in FORM_REDS.items() if k == req.modulusForm]
        reds[sup] = [r for r in _pick(o, 'reduction', cand) if _reductionWorks(req, mode, r)]
    # the butterfly's arithmetic: explicit back ends without a budget, and the DSP budget steps on the all-DSP one
    def arith(sup):
        out = []
        for m in mults:
            for be in (cbs if sup == 'rom' else qbs):
                for f in fracs:
                    if f is not None and (m != 'dsp' or be != 'dsp'):
                        continue
                    out.append((m, be, f))
        return out
    for B in _pick(o, 'B', _pow2(1, n // 4)):
        b = B.bit_length() - 1
        for io in _pick(o, 'ioLanes', _pow2(1, min(2 * B, req.maxLanes))):
            for org in _pick(o, 'memOrg', ['inplace', 'constgeo']):
                xrs = _pick(o, 'crossRegs', CROSS_REGS) if org == 'constgeo' else [0]
                for d in dirs:
                    inv = d != 'forward'
                    scales = ['output'] + (['stage'] if (inv and not nwc) else [])
                    for scale in _pick(o, 'inverseScale', scales):
                        twist = inv and scale == 'output'
                        if not twist and 'ioLanes' not in o and io != min(2 * B, req.maxLanes):
                            continue        # no multiplier on the output: the port costs nothing, so it is 2B wide
                        shares = [None]
                        if d == 'both' and not nwc and org == 'inplace':
                            shares = _pick(o, 'shareInverseTwiddles', [True, False])
                        for share in shares:
                            stored = 1 if (d != 'both' or (share is True)) else 2
                            for sup in sups:
                                if sup in ('rom', 'load') and needD:
                                    continue
                                # the supply's own options
                                subs = []
                                if sup in ('rom', 'load'):
                                    subs = [dict(twiddleBuffer='single', qSwitch='bubble')]
                                elif sup == 'mrom':
                                    subs = [dict(twiddleBuffer='single', qSwitch=q_)
                                            for q_ in _pick(o, 'qSwitch', ['bubble', 'inline'])]
                                elif sup == 'stream':
                                    if twist and org == 'constgeo':
                                        continue
                                    for tb in _pick(o, 'twiddleBuffer', ['recycle', 'double']):
                                        for tl in _pick(o, 'twiddleLanes', _pow2(1, B)):
                                            for q_ in _pick(o, 'qSwitch', ['bubble', 'inline']):
                                                for dp in _pick(o, 'dirPerPoly', [False, True]):
                                                    if dp and (d != 'both' or q_ == 'inline'):
                                                        continue
                                                    if needD and not dp:
                                                        continue
                                                    subs.append(dict(twiddleBuffer=tb, twiddleLanes=tl, qSwitch=q_,
                                                                     dirPerPoly=dp))
                                else:                     # gen
                                    if twist or B < 2 or needD or (org == 'inplace' and stored != 1):
                                        continue
                                    gmax = B if org == 'inplace' else B // 2
                                    for g in _pick(o, 'recGroup', _pow2(1, gmax)):
                                        for k in (_pick(o, 'recSeeds', REC_SEEDS) if org == 'inplace' else [0]):
                                            for rm in _pick(o, 'recMultiplier', [None, 'booth']):
                                                for q_ in _pick(o, 'qSwitch', ['bubble', 'inline']):
                                                    subs.append(dict(twiddleBuffer='recycle', recGroup=g, recSeeds=k,
                                                                     recMultiplier=rm, qSwitch=q_))
                                fans = [(None, True, 'register')]
                                if org == 'constgeo' and sup in ('rom', 'load', 'gen'):
                                    fans = []
                                    for f in knob['fanout']:
                                        if f is None:
                                            fans.append((None, True, 'register'))
                                        else:
                                            fans += [(f, ks, ld) for ks in knob['fanoutKeepSinks']
                                                     for ld in knob['fanoutLoads']]
                                elif None not in knob['fanout']:
                                    continue
                                for sub in subs:
                                    for red in reds[sup]:
                                        if sup == 'gen' and red == 'shoup':
                                            continue
                                        for (m, be, f) in arith(sup):
                                            for fan in fans:
                                                for ms, ts, rl in itertools.product(knob['memStyle'],
                                                                                    knob['twiddleStyle'],
                                                                                    knob['ramLatency']):
                                                    p = dict(B=B, ioLanes=io, memOrg=org, crossRegs=0, supply=sup,
                                                             direction=d, negacyclic=nwc, inverseScale=scale,
                                                             shareInverseTwiddles=share, reduction=red, multiplier=m,
                                                             constBackend=be if sup == 'rom' else None,
                                                             qBackend=be if sup != 'rom' else None, dspFraction=f,
                                                             memStyle=ms, twiddleStyle=ts, ramLatency=rl,
                                                             fanout=fan[0], fanoutKeepSinks=fan[1],
                                                             fanoutLoads=fan[2])
                                                    p.update(sub)
                                                    p['dspTotal'] = totalOf(req, f) if m == 'dsp' else None
                                                    for xr in xrs:
                                                        yield dict(p, crossRegs=xr)


def count(req) -> int:
    '''Points `enumerate(req)` lists, without keeping them.'''
    return sum(1 for _ in enumerate(req))


# --- the cycle twin, with a small per-process memo ---------------------------------------------------------------

def _steady(job) -> tuple:
    '''(interval, settled, first polynomial's latency) of a twin job that `job(polys)` runs: the interval is the
    larger of the last two gaps between output starts (the first gaps hold the start-up: the first record is a
    whole one, the input backlog builds up). Not settled after 5 polynomials: 9 are tried.'''
    for polys in (5, 9):
        j = job(polys)
        st = j['starts']
        g = [st[k] - st[k - 1] for k in range(1, len(st))]
        if g[-1] == g[-2]:
            break
    return max(g[-2:]), g[-1] == g[-2], j['latency']


def _jobs(s, p) -> dict:
    '''{'same': a run of one modulus, 'new': a new modulus (and direction) every polynomial, or None when the
    core cannot take one in band}, each (interval, settled, latency) from the cycle twin.'''
    sup = p['supply']
    if sup in ('rom', 'load'):
        return {'same': _steady(lambda P: s.simulateJob(P)), 'new': None}
    if sup == 'mrom':
        new = _steady(lambda P: s.simulateJob(P))
        if s.qInline:
            return {'same': new, 'new': new}
        return {'same': _steady(lambda P: s.simulateJob(P, tags=[0] * P)), 'new': new}
    return {'same': _steady(lambda P: s.simulateJob(P, records=[False] + [True] * (P - 1))),
            'new': _steady(lambda P: s.simulateJob(P))}


# --- ports -------------------------------------------------------------------------------------------------------

CONTROL_PORTS = ('clk', 'rst', 'in_valid', 'in_ready', 'out_valid', 'tw_valid', 'tw_ready', 'tw_rst', 'tw_wen')


def loadPort(s) -> tuple:
    '''(words, word width) of the load port tw_wdata, 0 words when the core has none. As
    `IterativeNTT._tables` counts them: every RAM table column of every butterfly, then the twist tables.'''
    if not (s.runtime and not s.multiRom and not s.rns):
        return 0, 0
    cols = s.twEntryCols()
    words = s.B * (s.tdepth + s.cdepth) * s.twDirs() * len(cols) if s.memOrg == 'constgeo' else \
        s.B * (s.tdepth + s.cdepth) * len(s.tdirs) * len(cols)
    width = max(cols)
    if s.twistMultiplier is not None:
        words += s.io * s.beats * len(s.dirs)
        width = max(width, max(1, (s.qMax() - 1).bit_length()))
    return words, width


def ports(s, run: float = float('inf')) -> list:
    '''The data-carrying ports of the generated top module, from the same scheme methods the generator's spec
    is built from (`IterativeNTT.getOperatorInterface`). `run`: polynomials per modulus (the record stream
    carries a whole record when the modulus changes and the header alone when it is kept).'''
    P = [Port('data_in', s.memBound.bitWidth, s.io, s.beats, name='x_in_'),
         Port('data_out', s.outputBound.bitWidth, s.io, s.beats, name='y_out_')]
    if s.multiRom:
        mb = s.modulusIndexBits()
        P.append(Port('record_stream', mb, 1, 1, name='MIDX'))
        P.append(Port('record_stream', mb, 1, 1, name='midx_out'))
        if s.direction == 'both':
            P.append(Port('record_stream', 1, 1, 1, name='DIR'))
            P.append(Port('record_stream', 1, 1, 1, name='dir_out'))
        return P
    if s.direction == 'both' and not s.dirPerPoly:
        P.append(Port('table_load', 1, 1, 1, perLoad=True, name='DIR'))
    if s.rns:
        width = s.twiddleLanes() * s.twEntryWidth()
        full, keep = s.recordBeats(False), s.recordBeats(True)
        kind = 'record_stream' if s.rec else 'twiddle_stream'
        if run == float('inf'):
            P.append(Port(kind, width, 1, keep, name='tw_data'))
        elif run <= 1:
            P.append(Port(kind, width, 1, full, name='tw_data'))
        else:                              # one full record and run - 1 kept headers per run of one modulus
            P.append(Port(kind, width, 1, full + (run - 1) * keep, perLoad=True, name='tw_data'))
        return P
    if s.runtime:
        for qp, w in s.qPortWidths():
            P.append(Port('table_load', w, 1, 1, perLoad=True, name=qp))
        words, width = loadPort(s)
        if words:
            P.append(Port('table_load', width, 1, words, perLoad=True, name='tw_wdata'))
    return P


# --- evaluate ----------------------------------------------------------------------------------------------------

def _note(s, p) -> str:
    '''Which model priced the point and where it is known to be off or not calibrated.'''
    weak = []
    if p['multiplier'] == 'booth' or p.get('qBackend') == 'booth' or p.get('constBackend') == 'booth' \
            or p.get('dspFraction') is not None or binds(s):
        weak.append('Booth multipliers or a DSP budget: LUT up to 14 % low on routed rows, registers further off')
    mem = {m['what']: m['style'] for m in s.memories()}
    if mem.get('data bank') == 'distributed':
        weak.append('data banks in LUTRAM: registers 21 % low on the one routed row')
    if 'ultra' in mem.values():
        weak.append('URAM: no routed row, not measured')
    if p['supply'] == 'mrom':
        weak.append('multi-modulus ROM: block RAM 24 against 32 routed on the constant-geometry rows, 30/36-bit '
                    'Barrett LUT 5 to 13 % high')
    if p['supply'] == 'gen':
        weak.append("generated twiddles: fitted on few rows; generators on LUTs (recMultiplier 'booth') LUT 14 % low")
        if p.get('recSeeds'):
            weak.append('recSeeds: one routed row (n 1024, B 8)')
    if p['supply'] == 'stream' and p['twiddleBuffer'] == 'double':
        weak.append("twiddleBuffer 'double': no routed row found, not measured")
    if p.get('qSwitch') == 'inline':
        weak.append("qSwitch 'inline': routed cores were +1.5 to 2.1 % area against 'bubble'; model rows few")
    if p['reduction'] not in ('barrett', 'mont', 'wlm', 'shoup'):
        weak.append(f"reduction {p['reduction']}: no routed iterative row, the butterfly comes from the "
                    f"modular-multiplier model alone")
    if s.runtime and p['reduction'] == 'barrett' and s.qMax().bit_length() >= 50:
        weak.append('wide run-time Barrett: DSP 1 per butterfly low, area units about 3.5 % low')
    if p.get('fanout') is not None:
        weak.append('fan-out trees: registers from the tree counts, two routed rows')
    if p['memOrg'] == 'constgeo' and p.get('crossRegs'):
        weak.append('crossRegs: ablation rows only')
    if p['ramLatency'] != 2:
        weak.append('ramLatency other than 2: no routed row, not measured')
    if p['B'] >= 256:
        weak.append('256 butterflies or more: drain mux under-counted on the routed rows')
    return MODEL_BASE + ('. Weak here: ' + '; '.join(weak) if weak else '')


def evaluate(req, params):
    '''The CoreRecord of one point from the build-free models, None when the generator refuses it.'''
    p = dict(params)
    if _nwc(req) is None or p.get('negacyclic') != _nwc(req):
        return None
    try:
        s = scheme(req, p)
        if s.rec:                          # the seed count is checked against the generators' store on first use
            _quiet(s.recSeedCount)
    except ValueError:
        return None
    res = _quiet(lambda: s.resources(pipelineStages=1))
    jobs = _quiet(lambda: _jobs(s, p))
    same, new = jobs['same'], jobs['new']
    interval, settled, latency = same
    sup = p['supply']
    run = req.effRun
    note = []
    if new is not None:                    # the modulus (and direction) taken in band, per polynomial
        reload_ = max(0, new[0] - interval)
        settled = settled and new[1]
        ppm = True
        ppd = bool(s.direction == 'both' and (s.multiRom or s.dirPerPoly))
        note.append(f'a modulus change costs {reload_} cycles in band')
    elif sup == 'load':                    # drain, then the tables through the load port, one word a cycle
        words, _w = loadPort(s)
        reload_ = words + max(0, latency - interval)
        ppm = ppd = False
        note.append('reloadCycles = load words + drain, a formula, not simulated')
    else:                                  # rom: only the direction can change (DIR, per job): drain first
        reload_ = max(0, latency - interval) if s.direction == 'both' else 0
        ppm = ppd = False
        if reload_:
            note.append('reloadCycles = drain before DIR changes, a formula, not simulated')
    P = ports(s, run)
    mems = s.memories()
    inside = sum(m['count'] * m['depth'] for m in mems if m['what'] != 'data bank')
    if sup == 'load':
        outside = loadPort(s)[0]
    elif sup == 'stream':
        tl = s.twiddleLanes()
        outside = sum(s.stageBeats(tl)) * tl * len(s.twEntryCols()) + (s.n if s.twistOn else 0)
    elif sup == 'gen':
        outside = 2 * s.recordBeats(False)
    else:
        outside = 0
    if not settled:
        note.append('the twin\'s output gaps were still changing after 9 polynomials: the interval is the larger of '
                    'the last two and may be a few cycles low')
    flags = []
    cp = s.criticalPathNs(1)
    if cp > 1000.0 / req.clockMhz + 1e-9:
        flags.append(f'model critical path {cp:.2f} ns above the period {1000.0 / req.clockMhz:.2f} ns')
    p.update(n=req.n, clockMhz=req.clockMhz, moduli=list(req.moduli), qBits=req.width, transform=req.transform,
             computeCycles=s.computeCycles(1), switchIdleCycles=reload_ if new is not None else None,
             intervalSettled=bool(settled))
    if s.rns:
        p['recordBeatsNew'], p['recordBeatsKept'] = s.recordBeats(False), s.recordBeats(True)
    if sup == 'gen':
        p['recGroupUsed'], p['recSeedsUsed'] = s.recGroup(), s.recSeedCount()
    return CoreRecord(arch=ARCH, name=pointName(req, params), params=p, clockMhz=float(req.clockMhz),
                      lut=res['lut'], ff=res['ff'], dsp=res['dsp'], bram36=res['bram'], uram=res['uram'],
                      interval=interval, latency=latency, reloadCycles=reload_, ports=P,
                      twiddleWordsInside=int(inside), twiddleWordsOutside=int(outside),
                      perPolyModulus=ppm, perPolyDirection=ppd, lanes=s.io, butterflies=s.B, flags=flags,
                      modelNote=_note(s, p) + ('. ' + '; '.join(note) if note else ''))


def sizing(req, params):
    """(family, size[, inner]): the size is the butterfly count B. A family is a memory organisation with a twiddle
    supply: within one, more butterflies only add area for the same boundary and options.
    inner = (the other options, ioLanes) for a core that scales an inverse on its output. That scaling takes one
    modular multiplier per coefficient of an output beat, so of each option combination only the narrowest data
    port that meets the requirements is kept. Every other core has no multiplier on the output, its port costs
    nothing and `enumerate` lists it at the full width 2B only."""
    fam = (params['memOrg'], params['supply'])
    if params['direction'] != 'forward' and params['inverseScale'] == 'output':
        rest = tuple(sorted((k, str(v)) for k, v in params.items() if k != 'ioLanes'))
        return fam, params['B'], (rest, params['ioLanes'])
    return fam, params['B']


def quickLatency(req, params):
    """A lower bound of the latency (first input beat to last output beat): every stage must run, and the output
    beats cannot start before the last input beat."""
    L = req.n.bit_length() - 1
    return max(L * req.n // (2 * params['B']), 2 * (req.n // params['ioLanes']) - 1)


def sideKinds(req, params) -> set:
    """Kinds of side traffic this point surely has, from its twiddle supply (never more than the model lists)."""
    return {'load': {'table_load'}, 'stream': {'twiddle_stream'}}.get(params['supply'], set())


def quick(req, params):
    '''(a lower bound of the interval, butterflies): the stages' cycles or the I/O beats, whichever is larger.'''
    B, io = params['B'], params['ioLanes']
    L = req.n.bit_length() - 1
    return max(L * req.n // (2 * B), req.n // io), B


# --- build -------------------------------------------------------------------------------------------------------

def _reqOf(record):
    from ..spec import Requirements
    p = record.params
    return Requirements(n=p['n'], moduli=list(p.get('moduli') or []), qBits=p.get('qBits'),
                        transform=p['transform'], clockMhz=p['clockMhz'])


def build(record, outdir, polys: int = 3, validPattern=None, twValidPattern=None, pattern: str = 'alt',
          keeps=None):
    '''RTL and a self-checking testbench of a record's core in `outdir`, by the run script's own functions
    (`runModularNTT.iterative`, `IterativeNTT.emitRtl`). Returns (top module name, [files]).
    The testbench sends `polys` distinct polynomials back to back and checks every output beat's value and cycle
    against the model; `pattern` 'alt' changes the modulus every polynomial where the core can, 'keep' has runs.
    `keeps` (one flag per polynomial) sets the kept records directly.
    The model's job is left in `build.last` (latency, interval, the frames' moduli).'''
    import random
    from ...ntt.iterative.IterativeNTT import IterativeNTT
    R = _run()
    req = _reqOf(record)
    p = record.params
    s = scheme(req, p, fast=False, name=record.name)
    rng = random.Random(13)
    top = record.name
    dsim = 'inv' if s.direction == 'inverse' else 'fwd'
    if s.rns or s.multiRom:
        nq = 2 if (s.rns or len(s.moduli) > 1) else 1
        qs = _testModuli(req, s, nq)
        if keeps is not None:              # explicit keep flags: a new modulus wherever the flag is False
            idx, k = [], 0
            for kp in keeps:
                k += 0 if kp else 1
                idx.append((k - 1) % len(qs))
            keeps = [bool(keeps[j]) and j > 0 for j in range(len(keeps))]   # `enumerate` is this module's own
        else:
            idx, keeps = R._records(pattern, len(qs), polys, rng)
        pq = [qs[i] for i in idx]
        frames = [[rng.randrange(q) for _ in range(s.n)] for q in pq]
        if s.rns:
            d = dsim
            if s.dirPerPoly:
                d = [('fwd', 'inv')[k % 2] for k in range(polys)]
                keeps = None
            meta = _quiet(lambda: IterativeNTT(s).emitRtl(top, outdir, frames=frames, direction=d, q=pq,
                                                           validPattern=validPattern, records=keeps,
                                                           twValidPattern=twValidPattern))
        else:
            d = [('fwd', 'inv')[i % 2] for i in idx] if s.direction == 'both' else dsim   # changes with the modulus
            meta = _quiet(lambda: IterativeNTT(s).emitRtl(top, outdir, frames=frames, direction=d, q=pq,
                                                           validPattern=validPattern))
        build.last = dict(meta, moduli=pq, keeps=keeps)
    else:
        q = _testModuli(req, s, 1)[0] if s.runtime else s.q
        frames = [[rng.randrange(q) for _ in range(s.n)] for _ in range(polys)]
        meta = _quiet(lambda: IterativeNTT(s).emitRtl(top, outdir, frames=frames, direction=dsim, q=q,
                                                       validPattern=validPattern))
        build.last = dict(meta, moduli=[q] * polys, keeps=None)
    files = []
    for sub in ('RTL_generated', 'testvectors'):          # `_sub` holds the generators' intermediate copies
        d = os.path.join(outdir, sub)
        if os.path.isdir(d):
            files += [os.path.join(d, f) for f in sorted(os.listdir(d))]
    return top, files


build.last = None
