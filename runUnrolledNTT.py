#!/usr/bin/env python3
'''Gates for the fully pipelined (unrolled) NTT type (`operator_modeling/ntt/dataflow/UnrolledNTT.py`):
one whole n-point transform per cycle, a modulus (MIDX) and a direction (DIR) per transform.

Gate U1  model: `transformNatural` against the O(n^2) reference, transform by transform with a
         random modulus and direction each, over n = 4..128, Barrett / Montgomery / word-level
         Montgomery (run-time family) / Shoup, per-frame moduli of mixed widths and Kim et al.'s
         42, fixed q (constant multipliers), GS at a fixed q, negacyclic False / True / 'forward' /
         'inverse', inverseScale 'output' / 'stage' / 'none', natural and bit-reversed orders, and
         given roots per modulus (`roots=`: powers of one psi_N, as a multi-step NTT needs).
Gate U2  clocked twin: `step()` stream (a new transform every cycle, modulus and direction
         changing every cycle, invalid slots) against `transformNatural`, outputs exactly
         `latency()` steps later.
Gate U3  cost and budget: `resources()` (tables priced, copies counted), `dspBlocks` /
         `applyDspPlan` give the same design as `setDspBudget`, a 60 % budget lowers the DSP count
         and never exceeds it; the type refuses 'otf' / 'rec'.
Gate U4  `--rtl DIR [--sim]`: RTL with testbenches (frames back to back, MIDX/DIR random per
         cycle, invalid cycles in between, every output and out_valid/midx_out/dir_out checked at
         its exact cycle, so a lower rate fails); xsim over `--slots` slots in parallel.

    source ../ntt_hw/env.sh
    python3 runUnrolledNTT.py                       # U1-U3
    python3 runUnrolledNTT.py --rtl DIR --sim       # and U4
'''
from __future__ import annotations

import argparse
import concurrent.futures as cf
import contextlib
import io
import os
import random
import subprocess
import sys
import time

from operator_modeling.core.IntType import IntType
from operator_modeling.core.utils import bitReverse
from operator_modeling.modmult.ModulusFamily import ModulusFamily as MF
from operator_modeling.modmult.ReductionScheme import BarrettReduction, MontgomeryReduction, WordLevelMontgomery
from operator_modeling.modmult.primes import nttFriendlyPrime
from operator_modeling.modmult import kim_moduli
from operator_modeling.ntt.dataflow.UnrolledNTT import UnrolledNTT, UnrolledNTTScheme
from operator_modeling.ntt.verification import referenceNtt

RED = {'barrett': BarrettReduction, 'mont': MontgomeryReduction, 'wlm': WordLevelMontgomery}
Q30 = nttFriendlyPrime(30, 12)
Q52 = nttFriendlyPrime(52, 16)
Q62 = nttFriendlyPrime(62, 17)


def friendlyPrimes(v, qhBits, order, k, first=None):
    from runModularNTT import friendlyPrimes as f
    return f(v, qhBits, order, k, first)


MIX = [nttFriendlyPrime(30, 12), nttFriendlyPrime(41, 14), nttFriendlyPrime(52, 16), nttFriendlyPrime(36, 13)]
ODD62 = [2305843009218281473, 2305843009220116481, nttFriendlyPrime(62, 18)]
MODULI = {'MIX': MIX, 'KIM': kim_moduli.KIM_Q, 'ODD62': ODD62,
          'FR32': friendlyPrimes(32, 32, 256, 3, 9223372195768565761),
          'FR16': friendlyPrimes(16, 16, 256, 3, 2148728833)}
SLOT_ROOT = 'work/framework'


def quiet(fn):
    with contextlib.redirect_stdout(io.StringIO()):
        return fn()


def make(name, n, q, red='barrett', nwc=False, direction='both', **kw):
    '''q: an int (fixed), a list or a MODULI key (per-frame moduli).'''
    behav = kw.pop('behav', True)
    fam = kw.pop('family', None)
    frac = kw.pop('dspFraction', None)
    total = kw.pop('dspTotal', None)
    bu = dict(kw.pop('butterfly', {}))
    if red == 'shoup':
        bu.update(multiplierKind='shoup', reduction=BarrettReduction)
    else:
        bu.setdefault('reduction', RED[red])
    if behav:
        bu.update(multiplier='behavioural', qBackend='behavioural')
    if isinstance(q, str):
        q = MODULI[q]
    args = dict(moduli=list(q)) if isinstance(q, (list, tuple)) else dict(q=q)
    s = UnrolledNTTScheme(name, n, family=fam, negacyclic=nwc, direction=direction, butterfly=bu, **args, **kw)
    s.setInputBound(IntType(0, s.qMax() - 1))
    if frac is not None or total is not None:
        s.setDspBudget(fraction=frac, total=total)
    return s


def _w(s, q):
    '''The cyclic n-th root the scheme uses for modulus q.'''
    r = s.root(q)
    return r * r % q if s.negacyclicDirs() else r


def refFwd(s, x, q):
    nw = 'fwd' in s.negacyclicDirs()
    return referenceNtt(x, q, primitiveRoot=s.root(q) if nw else _w(s, q), negacyclic=nw)


def refForInverse(s, x, q):
    '''A transform the inverse must take back to x: the forward of the inverse's own kind.'''
    nw = 'inv' in s.negacyclicDirs()
    return referenceNtt(x, q, primitiveRoot=s.root(q) if nw else _w(s, q), negacyclic=nw)


def _perm(v, order, L):
    return v if order == 'natural' else [v[bitReverse(i, L)] for i in range(len(v))]


def checkModel(s, T=6, seed=1) -> bool:
    '''Forward vs the reference and inverse(reference) == x, a random modulus per transform; in
    'both' mode the directions interleave (one call, a direction per transform).'''
    rng = random.Random(seed)
    L = s.n.bit_length() - 1
    qs = [rng.choice(s.moduli) for _ in range(T)] if s.perFrame else [s.refQ()] * T
    xs = [[rng.randrange(q) for _ in range(s.n)] for q in qs]
    ds = [rng.choice(s.dirs) for _ in range(T)]
    ins, want = [], []
    for x, q, d in zip(xs, qs, ds):
        if d == 'fwd':
            ins.append(_perm(x, s.inputOrder, L))
            want.append(_perm(refFwd(s, x, q), s.outputOrder, L))
        else:
            ins.append(_perm(refForInverse(s, x, q), s.inputOrder, L))
            sc = 1 if s.scaleInverse else s.n
            want.append(_perm([v * sc % q for v in x], s.outputOrder, L))
    got = s.transformNatural(ins, ds if s.perFrame else ds[0] if len(set(ds)) == 1 else ds, qs) \
        if s.perFrame else [s.transformNatural([i], d, q)[0] for i, d, q in zip(ins, ds, qs)]
    return got == want


def u1cases(quick: bool) -> list:
    C = []
    for n in (4, 8, 16, 32):
        for nwc in (False, True, 'forward', 'inverse'):
            for isc in ('output', 'stage', 'none'):
                C.append((f'n{n} barrett MIX nwc={nwc} {isc}', dict(n=n, q='MIX', nwc=nwc, inverseScale=isc)))
    for red, q, fam in (('mont', 'MIX', None), ('wlm', 'FR32', MF.friendly(32, 32)), ('wlm', 'FR16', MF.friendly(16, 16)),
                        ('barrett', 'ODD62', None), ('shoup', 'MIX', None)):
        for n, nwc, isc in ((16, False, 'stage'), (32, True, 'output'), (64, 'forward', 'none'), (16, 'inverse', 'stage')):
            C.append((f'n{n} {red} {q} nwc={nwc} {isc}', dict(n=n, q=q, red=red, nwc=nwc, inverseScale=isc, family=fam)))
    for d in ('forward', 'inverse'):
        C.append((f'n32 barrett MIX {d} only', dict(n=32, q='MIX', nwc=True, direction=d)))
    for io_ in (('bitrev', 'natural'), ('natural', 'bitrev'), ('bitrev', 'bitrev')):
        C.append((f'n16 orders {io_}', dict(n=16, q='MIX', nwc='forward', inverseScale='stage',
                                            inputOrder=io_[0], outputOrder=io_[1])))
    # fixed q: one direction = constant multipliers; both = DIR per job (tables of 2 words)
    for q in (Q30, Q52, Q62):
        for nwc in (False, True):
            C.append((f'fixed q{q.bit_length()} n32 forward nwc={nwc}', dict(n=32, q=q, nwc=nwc, direction='forward')))
            C.append((f'fixed q{q.bit_length()} n16 both nwc={nwc}', dict(n=16, q=q, nwc=nwc, direction='both')))
    for nwc, isc in ((False, 'output'), (True, 'output'), (True, 'stage')):
        C.append((f'GS fixed q52 n16 both nwc={nwc} {isc}', dict(n=16, q=Q52, nwc=nwc, butterflyType='GS',
                                                                 inverseScale=isc)))
    # given roots: the n-th / 2n-th roots of one psi_N (N = 1024), per modulus (R1)
    for nwc in (False, 'forward', True):
        C.append((f'roots of psi_1024 n16 nwc={nwc}', dict(n=16, q='MIX', nwc=nwc, inverseScale='stage', roots='psiN')))
    # the unified CT/GS butterfly (R7): forward CT, inverse GS, no twist multipliers, every negacyclic choice
    for n in (8, 16, 32):
        for nwc in (True, False, 'forward', 'inverse'):
            for isc in ('stage', 'none'):
                C.append((f'unified n{n} barrett MIX nwc={nwc} {isc}', dict(n=n, q='MIX', nwc=nwc, inverseScale=isc,
                                                                            unified=True)))
    for red, q, fam in (('mont', 'MIX', None), ('wlm', 'FR32', MF.friendly(32, 32)), ('barrett', 'KIM', None)):
        C.append((f'unified n32 {red} {q} nwc', dict(n=32, q=q, red=red, family=fam, nwc=True, inverseScale='stage',
                                                     unified=True)))
    C.append(('unified exact n16 wlm FR32 nwc', dict(n=16, q='FR32', red='wlm', family=MF.friendly(32, 32), nwc=True,
                                                    inverseScale='stage', unified=True, behav=False, targetFmaxMhz=350.0)))
    C.append(('unified roots psiN n16 nwc', dict(n=16, q='MIX', nwc=True, inverseScale='stage', unified=True, roots='psiN')))
    for red, fam, nwc in (('wlm', MF.friendly(17, 45), False), ('barrett', MF.odd(52), True), ('mont', MF.odd(30), 'forward')):
        C.append((f'ram one q per job n16 {red} {fam.describe()} nwc={nwc}', dict(n=16, q=0, red=red, family=fam, nwc=nwc,
                                                                                 twiddleSource='ram')))
    C.append(('n128 barrett MIX cyclic stage', dict(n=128, q='MIX', inverseScale='stage')))
    C.append(('n64 barrett KIM nwc', dict(n=64, q='KIM', nwc=True)))
    # bit-exact datapaths (DSP58 / LUT multipliers as built), smaller set
    for red, q, fam, nwc in (('barrett', 'MIX', None, 'forward'), ('mont', 'MIX', None, True),
                             ('wlm', 'FR32', MF.friendly(32, 32), False), ('shoup', 'MIX', None, False)):
        C.append((f'exact n16 {red} {q} nwc={nwc}', dict(n=16, q=q, red=red, nwc=nwc, inverseScale='stage' if nwc is not True else 'output',
                                                         family=fam, behav=False, targetFmaxMhz=350.0)))
    if quick:
        C = C[::3]
    return C


def psiRoots(moduli, N=1024):
    '''roots(q, order): psi_N^(N/order), psi_N a primitive N-th root (any one: here g^((q-1)/N)).'''
    from sage.all import GF
    cache = {}

    def r(q, order):
        if q not in cache:
            F = GF(q)
            cache[q] = int(F.multiplicative_generator() ** ((q - 1) // N))
        return pow(cache[q], N // order, q)
    return r


def gateU1(quick: bool) -> int:
    t0, fails, cases = time.time(), 0, u1cases(quick)
    for tag, kw in cases:
        kw = dict(kw)
        try:
            if kw.get('roots') == 'psiN':
                kw['roots'] = psiRoots(MODULI[kw['q']])
            s = quiet(lambda: make('u1', **kw))
            ok = checkModel(s, T=6 if s.n <= 32 else 3)
            if s.perFrame and kw.get('roots'):
                q = s.moduli[0]
                ok = ok and s.rootUsed(q, 'fwd')['w'] == kw['roots'](q, s.n)
        except Exception as e:                           # noqa: BLE001
            ok = False
            print(f'  {tag}: {type(e).__name__}: {e}')
        fails += not ok
        if not ok:
            print(f'  FAIL {tag}')
    print(f'gate U1 model: {len(cases) - fails} of {len(cases)} pass ({time.time() - t0:.0f}s)')
    return fails


def gateU2() -> int:
    fails = 0
    for kw in (dict(n=16, q='MIX', nwc='forward', inverseScale='stage'), dict(n=8, q='MIX', nwc=True),
               dict(n=16, q=Q52, direction='forward')):
        s = quiet(lambda: make('u2', **kw))
        rng = random.Random(5)
        LAT = s.latency()
        s.reset()
        sent, got, ok = [], [], True
        for c in range(40 + LAT):
            v = c < 40 and rng.random() < 0.8
            q = rng.choice(s.moduli) if s.perFrame else s.q
            d = rng.choice(s.dirs) if s.perFrame else s.dirs[0]
            x = [rng.randrange(q) for _ in range(s.n)]
            sent.append((v, x, d, q))
            out = s.step(x, d, q, valid=v)
            if c >= LAT and sent[c - LAT][0]:
                v0, x0, d0, q0 = sent[c - LAT]
                ok = ok and out is not None and out[0] == s.transformNatural([x0], d0, q0)[0]
            else:
                ok = ok and out is None
        fails += not ok
        print(f"  {'ok  ' if ok else 'FAIL'} step stream {kw}, latency {LAT}")
    print(f'gate U2 clocked twin: {3 - fails} of 3 pass')
    return fails


def gateU3() -> int:
    from operator_modeling.core import dspbudget as DB
    fails = 0

    def chk(tag, ok):
        nonlocal fails
        fails += not ok
        print(f"  {'ok  ' if ok else 'FAIL'} {tag}")
    s = quiet(lambda: make('u3', n=32, q='MIX', nwc=True, behav=False, targetFmaxMhz=350.0))
    r = s.resources()
    pure = r['dsp']
    chk(f"resources n32 MIX nwc: LUT {r['lut']} (tables {r['lut_tables']}), DSP {r['dsp']}, "
        f"{len(s.tableInstances())} table copies", r['lut_tables'] > 0 and r['dsp'] > 0)
    tree = quiet(lambda: s.setDspBudget(fraction=0.6))
    d60 = s.resources()['dsp']
    chk(f'setDspBudget(0.6): {d60} DSP <= budget {tree.budget} < {pure}', d60 <= tree.budget < pure)
    # the same split through dspBlocks / applyDspPlan (what a composition does)
    s2 = quiet(lambda: make('u3b', n=32, q='MIX', nwc=True, behav=False, targetFmaxMhz=350.0))
    blocks = quiet(lambda: s2.dspBlocks())
    root = DB.Budget('u3b', 1, sum(b.count * b.pureDsp for b in blocks), sum(b.count * b.weight for b in blocks),
                     children=blocks)
    root.budget = DB.resolveTotal(root.pureDsp, 0.6, None)
    DB.splitTypes(root.budget, blocks)
    for b in blocks:
        DB.splitLeaves(b)
    quiet(lambda: s2.applyDspPlan({b.key: DB.budgetsOf(b) for b in blocks}))
    chk(f"dspBlocks + applyDspPlan: {s2.resources()['dsp']} DSP == setDspBudget's {d60}", s2.resources()['dsp'] == d60)
    chk('budgeted design still exact', checkModel(s2, T=4))
    b2 = quiet(lambda: s2.dspBlocks(count=2))
    chk('dspBlocks(count=2) doubles every count', all(x.count == 2 * y.count for x, y in zip(b2, blocks)))
    for src in ('otf', 'rec'):
        try:
            make('u3c', n=16, q='MIX', twiddleSource=src)
            chk(f"refuses twiddleSource={src!r}", False)
        except ValueError:
            chk(f"refuses twiddleSource={src!r}", True)
    s3 = quiet(lambda: make('u3d', n=64, q='KIM', tableShare=1))
    s4 = quiet(lambda: make('u3e', n=64, q='KIM', tableShare=8))
    chk(f"table copies: share 1 -> {len(s3.tableInstances())}, share 8 -> {len(s4.tableInstances())} "
        f"(LUT {s3.resources()['lut_tables']} -> {s4.resources()['lut_tables']})",
        len(s4.tableInstances()) < len(s3.tableInstances()))
    print(f'gate U3 cost and budget: {fails} failing')
    return fails


# --- gate U5: twiddles given from outside (folded multi-step) ---------------------------

def refNet(s, x, tw, q, d):
    '''An independent CT network over `slotPairs()`: memory m <- x[brv(m)], stage s pairs (mA, mB) with
    twiddle tw[(s, k)]: X = A + W B, Y = A - W B; the per-stage x2^-1 on the inverse; output m = natural m.'''
    L = s.n.bit_length() - 1
    v = [x[bitReverse(m, L)] % q for m in range(s.n)]
    for st, pairs in enumerate(s.slotPairs()):
        for k, (a, b) in enumerate(pairs):
            t = tw[(st, k)] * v[b] % q
            if getattr(s, '_unified', False) and d == 'inv':       # GS on the same wiring: X = A + B, Y = (A - B) W
                v[a], v[b] = (v[a] + v[b]) % q, (v[a] - v[b]) * tw[(st, k)] % q
            else:
                v[a], v[b] = (v[a] + t) % q, (v[a] - t) % q
            if s.stageHalve and d == 'inv':
                h = pow(2, -1, q)
                v[a], v[b] = v[a] * h % q, v[b] * h % q
    return v


def gateU5() -> int:
    fails, n = 0, 0
    rng = random.Random(11)
    for red, q, fam in (('barrett', 'MIX', None), ('mont', 'MIX', None), ('wlm', 'FR32', MF.friendly(32, 32)),
                        ('wlm', 0, MF.friendly(17, 45)), ('barrett', 0, MF.odd(52))):
        for nn, isc in ((8, 'none'), (16, 'stage')):
            for mode in (('own', 'fn', 'port', 'uport') if q else ('port', 'uport')):
                tag = f'given twiddles {mode} n{nn} {red} {q} {isc}'
                n += 1
                try:
                    if mode == 'fn':
                        fn = lambda qq, d, st, k: (pow(qq - 3, 7 * st + k + (d == 'inv'), qq) + 5) % qq   # noqa: E731
                        sch = quiet(lambda: make('u5', n=nn, q=q, red=red, family=fam, inverseScale=isc, twiddles=fn))
                    elif mode in ('port', 'uport'):       # uport: the unified CT/GS butterfly, one q per job
                        sch = quiet(lambda: make('u5', n=nn, q=q, red=red, family=fam, inverseScale=isc,
                                                 twiddleSource='port', unified=mode == 'uport'))
                    else:
                        sch = quiet(lambda: make('u5', n=nn, q=q, red=red, family=fam, inverseScale=isc,
                                                 twiddles=lambda qq, d, st, k: base_.ownTwiddle(qq, d, st, k)))
                        base_ = quiet(lambda: make('u5o', n=nn, q=q, red=red, family=fam, inverseScale=isc))
                    T = 5
                    if sch.perFrame:
                        qs = [rng.choice(sch.moduli) for _ in range(T)]
                    else:                        # one q per job: two jobs of different q
                        qa = sch.family.samplePrimeCongruent(rng, sch.rootOrder())
                        qb = sch.family.samplePrimeCongruent(rng, sch.rootOrder())
                        qs = [qa] * 2 + [qb] * (T - 2)
                    ds = [rng.choice(sch.dirs) for _ in range(T)]
                    xs = [[rng.randrange(qq) for _ in range(nn)] for qq in qs]
                    if mode in ('port', 'uport'):
                        tws = [{(st, k): rng.randrange(qq) for st in range(sch.L) for k in range(nn // 2)} for qq in qs]
                        got = sch.transformPort(xs, tws, ds, qs)
                    else:
                        got = sch.transformNatural(xs, ds, qs)
                        tws = [{(st, k): sch.value(d, sch._IDB + st * nn + k, qq) for st in range(sch.L)
                                for k in range(nn // 2)} for d, qq in zip(ds, qs)]
                    ok = all(g == refNet(sch, x, tw, qq, d) for g, x, tw, qq, d in zip(got, xs, tws, qs, ds))
                    if mode == 'own':
                        ok = ok and got == base_.transformNatural(xs, ds, qs)
                except Exception as e:                   # noqa: BLE001
                    ok = False
                    print(f'  {tag}: {type(e).__name__}: {e}')
                fails += not ok
                if not ok:
                    print(f'  FAIL {tag}')
    print(f'gate U5 given twiddles: {n - fails} of {n} pass (ROM of a given set, per-cycle twiddle ports, the own '
          f'set given back = the plain design; against an independent CT network)')
    return fails


# --- gate U4: RTL --------------------------------------------------------------------

RTL_POINTS = [
    # name, make() kwargs, transforms, valid pattern ('all' | 'gaps')
    ('un8_barrett_mix_cy_stage', dict(n=8, q='MIX', inverseScale='stage'), 60, 'gaps'),
    ('un16_barrett_mix_nwc_out', dict(n=16, q='MIX', nwc=True), 50, 'gaps'),
    ('un16_barrett_mix_nwcfwd_stage', dict(n=16, q='MIX', nwc='forward', inverseScale='stage'), 50, 'gaps'),
    ('un16_barrett_mix_nwcinv_stage', dict(n=16, q='MIX', nwc='inverse', inverseScale='stage'), 50, 'all'),
    ('un8_mont_mix_nwcfwd_none', dict(n=8, q='MIX', red='mont', nwc='forward', inverseScale='none'), 50, 'gaps'),
    ('un16_wlm_fr32_cy_stage', dict(n=16, q='FR32', red='wlm', family=MF.friendly(32, 32), inverseScale='stage'), 40, 'gaps'),
    ('un32_barrett_odd62_cy_stage_ireg', dict(n=32, q='ODD62', inverseScale='stage', inputRegister=True), 40, 'gaps'),
    ('un16_shoup_mix_cy_stage', dict(n=16, q='MIX', red='shoup', inverseScale='stage'), 40, 'all'),
    ('un16_barrett_mix_bitrev_io', dict(n=16, q='MIX', nwc='forward', inverseScale='stage', inputOrder='bitrev',
                                        outputOrder='bitrev'), 40, 'gaps'),
    ('un16_fixed_q52_fwd_nwc', dict(n=16, q=Q52, nwc=True, direction='forward'), 40, 'gaps'),
    ('un16_gs_fixed_q30_fwd', dict(n=16, q=Q30, butterflyType='GS', direction='forward'), 40, 'all'),
    ('un16_barrett_mix_nwc_d60', dict(n=16, q='MIX', nwc=True, dspFraction=0.6), 40, 'gaps'),
    ('un16_barrett_mix_roots_nwcfwd', dict(n=16, q='MIX', nwc='forward', inverseScale='stage', roots='psiN'), 40, 'gaps'),
    ('un16_barrett_mix_share1', dict(n=16, q='MIX', nwc=True, tableShare=1, modShare=None), 40, 'gaps'),
    ('un64_barrett_kim_cy_stage', dict(n=64, q='KIM', inverseScale='stage'), 30, 'gaps'),
    # the unified CT/GS butterfly (R7): negacyclic forward and inverse without twist multipliers
    ('un16_barrett_mix_unified_nwc_stage', dict(n=16, q='MIX', nwc=True, inverseScale='stage', unified=True), 50, 'gaps'),
    ('un8_wlm_fr32_unified_nwc_stage', dict(n=8, q='FR32', red='wlm', family=MF.friendly(32, 32), nwc=True,
                                            inverseScale='stage', unified=True), 50, 'gaps'),
    ('un16_mont_mix_unified_nwcinv_none', dict(n=16, q='MIX', red='mont', nwc='inverse', inverseScale='none',
                                               unified=True), 40, 'gaps'),
    ('un32_barrett_kim_unified_nwc_stage_d60', dict(n=32, q='KIM', nwc=True, inverseScale='stage', unified=True,
                                                    dspFraction=0.6), 30, 'all'),
    # one run-time q per job, tables loaded ('ram'): jobs with a new q (and a table reload) in between, the q ports
    # changing with the job's first transform, DIR changing on every transform (frameDir, default)
    # twiddle ports with one run-time q per job (TP-NTT's reloadable folded form): q0 forward, then q1 inverse,
    # then q0 with the direction changing per transform (frameDir) / q1 forward (DIR per job, frameDir=False)
    ('un16_wlm_fr17x45_port_perjob', dict(n=16, q=0, red='wlm', family=MF.friendly(17, 45), inverseScale='stage',
                                          twiddleSource='port', dirPattern='fia'), 36, 'gaps'),
    ('un16_wlm_fr17x45_port_perjob_dirjob', dict(n=16, q=0, red='wlm', family=MF.friendly(17, 45),
                                                 inverseScale='stage', twiddleSource='port', frameDir=False,
                                                 dirPattern='fib'), 36, 'gaps'),
    # the same with the unified CT/GS butterfly (the multi-step folded_gs form's sub-NTT): forward CT, inverse GS
    ('un16_wlm_fr17x45_uport_perjob', dict(n=16, q=0, red='wlm', family=MF.friendly(17, 45), inverseScale='stage',
                                           twiddleSource='port', unified=True, dirPattern='fia'), 36, 'gaps'),
    ('un8_barrett_odd52_uport_perjob', dict(n=8, q=0, family=MF.odd(52), inverseScale='stage',
                                            twiddleSource='port', unified=True, dirPattern='fia'), 36, 'all'),
    ('un8_barrett_odd52_port_perjob_none', dict(n=8, q=0, family=MF.odd(52), inverseScale='none',
                                                twiddleSource='port', dirPattern='fia'), 36, 'all'),
    ('un16_wlm_fr17x45_ram_reload', dict(n=16, q=0, red='wlm', family=MF.friendly(17, 45), inverseScale='stage',
                                         twiddleSource='ram'), 36, 'gaps'),
    ('un16_barrett_odd52_ram_reload_nwc', dict(n=16, q=0, family=MF.odd(52), nwc=True, twiddleSource='ram'), 36, 'gaps'),
    ('un8_mont_odd30_ram_reload_ireg', dict(n=8, q=0, red='mont', family=MF.odd(30), inverseScale='stage',
                                            inputRegister=True, twiddleSource='ram'), 36, 'all'),
    # twiddles given from outside (folded multi-step): a ROM of a given set, and per-cycle twiddle ports
    ('un16_barrett_mix_givenfn_stage', dict(n=16, q='MIX', inverseScale='stage', twiddles='fn'), 40, 'gaps'),
    ('un16_barrett_mix_port_stage', dict(n=16, q='MIX', inverseScale='stage', twiddleSource='port'), 40, 'gaps'),
    ('un8_wlm_fr32_port_none', dict(n=8, q='FR32', red='wlm', family=MF.friendly(32, 32), inverseScale='none',
                                    twiddleSource='port'), 40, 'gaps'),
]


def emitPoint(root, name, kw, T, pat, seed=9):
    kw = dict(kw)
    kw['behav'] = False
    dpat = kw.pop('dirPattern', None)
    kw.setdefault('targetFmaxMhz', 350.0)
    if kw.get('roots') == 'psiN':
        kw['roots'] = psiRoots(MODULI[kw['q']])
    if kw.get('twiddles') == 'fn':
        kw['twiddles'] = lambda qq, d, st, k: (pow(qq - 3, 7 * st + k + (d == 'inv'), qq) + 5) % qq
    s = make(name, **kw)
    rng = random.Random(seed)
    L = s.n.bit_length() - 1
    qs = [rng.choice(s.moduli) for _ in range(T)] if s.perFrame else [s.refQ()] * T
    ds = [rng.choice(s.dirs) for _ in range(T)] if (s.perFrame or s.frameDir()) else [s.dirs[0]] * T
    if s.runtime and not s.perFrame:
        # one q per job, loaded tables ('ram'): three jobs, the q changing between them (A, B, A)
        qa = s.family.samplePrimeCongruent(rng, s.rootOrder())
        qb = next(q for q in iter(lambda: s.family.samplePrimeCongruent(rng, s.rootOrder()), None) if q != qa)
        k = T // 3
        qs = [qa] * k + [qb] * k + [qa] * (T - 2 * k)
        if not s.frameDir():                 # DIR per job: one direction per job, changing between jobs
            ds = [s.dirs[0]] * k + [s.dirs[-1]] * k + [s.dirs[0]] * (T - 2 * k)
        if dpat == 'fia':                    # q0 forward, q1 inverse, q0 with the direction per transform
            ds = ['fwd'] * k + ['inv'] * k + [rng.choice(s.dirs) for _ in range(T - 2 * k)]
        elif dpat == 'fib':                  # q0 forward, q1 inverse, q1 forward (a direction change alone)
            qs = [qa] * k + [qb] * (T - k)
            ds = ['fwd'] * k + ['inv'] * k + ['fwd'] * (T - 2 * k)
    xs = []
    for q, d in zip(qs, ds):
        x = [rng.randrange(q) for _ in range(s.n)]
        xs.append(_perm(x if d == 'fwd' else refForInverse(s, x, q), s.inputOrder, L))
    valid = [1] * T
    if pat == 'gaps':
        valid = []
        while sum(valid) < T:
            valid.append(0 if rng.random() < 0.2 else 1)
    run = os.path.join(root, name)
    tws = None
    if s._twPort:
        tws = [{(st, k): rng.randrange(q) for st in range(s.L) for k in range(s.n // 2)} for q in qs]
    m = UnrolledNTT(s).emitRtl(name, run, xs=xs, dirs=ds, qs=qs, valid=valid, tws=tws)
    return s, m, run


def simRun(run, slot):
    r = subprocess.run([sys.executable, 'scripts/run_remote_sim.py', '--run-dir', run, '--remote-root', slot],
                       capture_output=True, text=True)
    with open(os.path.join(run, 'sim.log'), 'w', encoding='utf-8') as f:
        f.write(r.stdout + r.stderr)
    rate = ''
    sd = os.path.join(run, 'sim_remote')
    for p in sorted(os.listdir(sd)) if os.path.isdir(sd) else []:
        fp = os.path.join(sd, p)
        if os.path.isfile(fp):
            rate = rate or next((ln.strip() for ln in open(fp, errors='replace') if ln.startswith('rate:')), '')
    v = next((ln.split(': ', 1)[1] for ln in r.stdout.splitlines()
              if ln.startswith('[run_remote_sim]') and (': PASS' in ln or ': FAIL' in ln)), 'NO VERDICT')
    return v, rate


def gateU4(root, only, sim, slots) -> int:
    pts = [p for p in RTL_POINTS if not only or p[0] in only]
    fails, runs = 0, []
    for name, kw, T, pat in pts:
        t0 = time.time()
        try:
            s, m, run = quiet(lambda: emitPoint(root, name, kw, T, pat))
        except Exception as e:                           # noqa: BLE001
            print(f'  {name}: generation {type(e).__name__}: {e}')
            fails += 1
            continue
        r = s.resources()
        print(f"  {name:<36} n={s.n:4d} latency {m['latency']:3d} tables {m['tables']:3d} LUT~{r['lut']:7d} "
              f"DSP {r['dsp']:5d} ({time.time() - t0:.0f}s)")
        runs.append((name, run))
    if sim and runs:
        slotDirs = [os.path.join(SLOT_ROOT, f'slotUN{i + 1}') for i in range(slots)]
        with cf.ThreadPoolExecutor(max_workers=slots) as ex:
            futs = {}
            free = list(slotDirs)
            pending = list(runs)
            results = {}
            while pending or futs:
                while pending and free:
                    name, run = pending.pop(0)
                    sl = free.pop(0)
                    futs[ex.submit(simRun, run, sl)] = (name, sl)
                done, _ = cf.wait(list(futs), return_when=cf.FIRST_COMPLETED)
                for f in done:
                    name, sl = futs.pop(f)
                    free.append(sl)
                    results[name] = f.result()
                    v, rate = results[name]
                    print(f'  xsim {name:<36} {v}  {rate}')
                    fails += not v.startswith('PASS')
    print(f"gate U4 rtl: {len(runs) - (fails if sim else 0)} of {len(pts)} "
          f"{'simulated and passing' if sim else 'generated'}")
    return fails


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--quick', action='store_true')
    ap.add_argument('--skip-model', action='store_true')
    ap.add_argument('--rtl', default=None)
    ap.add_argument('--only', default=None)
    ap.add_argument('--sim', action='store_true')
    ap.add_argument('--slots', type=int, default=6)
    a = ap.parse_args()
    fails = 0
    if not a.skip_model:
        fails += gateU1(a.quick) + gateU2() + gateU3() + gateU5()
    if a.rtl:
        fails += gateU4(a.rtl, set(a.only.split(',')) if a.only else None, a.sim, a.slots)
    print('all gates passed' if not fails else f'{fails} FAILING')
    return 1 if fails else 0


if __name__ == '__main__':
    sys.exit(main())
