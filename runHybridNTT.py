'''Gates of the hybrid NTT (operator_modeling/ntt/hybrid, rtl_gen/hybrid_ntt.py).

Gate H1  the model: geometry (conflict-free banks, closed forms, every stage once), bit-exact
         forward against the O(n^2) / O(n log n) reference and inverse(forward(x)) == x, cyclic and
         negacyclic, several moduli (incl. AutoNTT's hybrid primes), a modulus and a direction per
         polynomial in one batch, the controller twin's interval (R x slot) and hazards, DSP budget.
Gate H2  (--rtl DIR) the RTL: distinct polynomials back to back (random valid on some), MIDX and DIR
         changing every polynomial; every output beat is checked for its value, its tags and its
         cycle (the twin), so a slower interval fails; xsim in parallel slots.

    source env.sh
    python runHybridNTT.py                 # gate H1
    python runHybridNTT.py --rtl work/hy   # gates H1 + H2 (simulates; --no-sim to only generate)
'''
from __future__ import annotations

import argparse
import concurrent.futures as cf
import contextlib
import io
import os
import queue
import re
import random
import subprocess
import sys
import time

from operator_modeling.core.IntType import IntType
from operator_modeling.core.utils import bitReverse
from operator_modeling.ntt.hybrid.HybridNTTScheme import HybridNTTScheme
from operator_modeling.ntt.hybrid.HybridNTT import HybridNTT
from operator_modeling.modmult.ReductionScheme import (BarrettReduction, MontgomeryReduction,
                                                       WordLevelMontgomery)
from operator_modeling.modmult.primes import nttFriendlyPrime
from operator_modeling.ntt.verification import referenceNtt

REDS = {'barrett': BarrettReduction, 'mont': MontgomeryReduction, 'wlm': WordLevelMontgomery}
# simulation folders; HY_SLOTS=a:b picks slotHYa .. slotHYb (two gates at once must not share folders)
_SL = [int(x) for x in os.environ.get('HY_SLOTS', '1:16').split(':')]
SLOTS = [f'work/hybrid/slots/slotHY{i}' for i in range(_SL[0], _SL[1] + 1)]

# AutoNTT's hybrid primes (their host rule: smallest kN+1 >= 2^(w-1)+1), and others
Q30_12 = 536903681            # 30-bit, N = 2^12 (AutoNTT-H row H1)
Q32_16 = 2148728833           # 32-bit, N = 2^16 (row H3)
Q52M = (1 << 52) - (1 << 20) + 1   # row H2's prime (their custom reduction)


def quiet(fn):
    with contextlib.redirect_stdout(io.StringIO()):
        return fn()


def primesFor(bits: int, n: int, count: int, nwc: bool) -> list[int]:
    '''count NTT-friendly primes of `bits` bits for n points (2n | q-1 when negacyclic).'''
    from sage.all import is_prime
    step = 2 * n if nwc else n
    out, k = [], ((1 << (bits - 1)) // step) + 1
    while len(out) < count:
        q = k * step + 1
        if q.bit_length() == bits and is_prime(q):
            out.append(q)
        k += 1
    return out


def hybrid(name, n, U, g=1, q=0, moduli=None, red='barrett', nwc=False, direction='both', iscale=None,
           behavioural=True, slots='auto', dspFraction=None, target=None, bramBudget=None, **kw):
    args = dict(multiplierKind='shoup') if red == 'shoup' else dict(reduction=REDS[red])
    if behavioural:
        args.update(multiplier='behavioural', qBackend='behavioural')
    iscale = iscale or ('output' if nwc else 'stage')
    s = HybridNTTScheme(name, n, U, g, q=q, moduli=moduli, negacyclic=nwc, direction=direction,
                        inverseScale=iscale, butterfly=args, slots=slots, targetFmaxMhz=target, **kw)
    qm = kw['family'].qMax if kw.get('loadable') else max(moduli) if moduli else q
    s.setInputBound(IntType(0, qm - 1))
    if dspFraction is not None:
        s.setDspBudget(fraction=dspFraction)
    if bramBudget is not None:
        s.setBramBudget(total=bramBudget)
    return s


def nttRef(x, q, nwc):
    n = len(x)
    if n <= 1024:
        return referenceNtt(x, q, negacyclic=nwc)
    from operator_modeling.ntt.verification import referenceNttFast
    return referenceNttFast(x, q, negacyclic=nwc)


def memFrame(x):
    L = len(x).bit_length() - 1
    return [x[bitReverse(m, L)] for m in range(len(x))]


H1_CASES = [
    # (tag, n, U, g, modulus spec, reduction, nwc, iscale, slots)
    ('n64 U2 cyc stage', 64, 2, 1, ('q', 'q30'), 'barrett', False, 'stage', 'auto'),
    ('n256 U2 g2 cyc', 256, 2, 2, ('q', 'q30'), 'barrett', False, 'output', 'auto'),
    ('n256 U4 g1 nwc', 256, 4, 1, ('q', 'q30'), 'mont', True, 'output', 1),
    ('n512 U3 g2 e1 nwc', 512, 3, 2, ('q', 'q30'), 'barrett', True, 'output', 2),
    ('n1024 U3 g2 e2 nwc', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto'),
    ('n1024 U5 g1 nwc 4q', 1024, 5, 1, ('m', 32, 4), 'barrett', True, 'output', 'auto'),
    ('n2048 U4 g2 e1 cyc 3q', 2048, 4, 2, ('m', 40, 3), 'mont', False, 'stage', 'auto'),
    ('n4096 U2 g1 cyc AutoNTT-H1 q', 4096, 2, 1, ('q', Q30_12), 'barrett', False, 'stage', 'auto'),
    ('n8192 U5 g1 e2 cyc AutoNTT-H2 q', 8192, 5, 1, ('q', Q52M), 'barrett', False, 'stage', 'auto'),
    ('n4096 U3 g4 nwc 62b 2q', 4096, 3, 4, ('m', 62, 2), 'barrett', True, 'output', 'auto'),
    ('n2048 U3 g4 cyc 3q', 2048, 3, 4, ('m', 45, 3), 'barrett', False, 'output', 'auto'),
]


def friendlyPrimes(bits, n, count, nwc):
    '''count primes q = qH 2^v + 1 of `bits` bits, v = log2(2n) (negacyclic) or log2(n); the WLM family.'''
    from sage.all import is_prime
    from operator_modeling.modmult.ModulusFamily import ModulusFamily as MF
    v = (2 * n if nwc else n).bit_length() - 1
    out, qh = [], (1 << (bits - v - 1)) + 1
    while len(out) < count:
        q = qh * (1 << v) + 1
        if q.bit_length() == bits and is_prime(q):
            out.append(q)
        qh += 1
    return out, MF.friendly(v, bits - v)


def _modspec(spec, n, nwc):
    if spec[0] == 'f':
        return 0, friendlyPrimes(spec[1], n, spec[2], nwc)[0]
    if spec[0] == 'q':
        q = spec[1] if isinstance(spec[1], int) else nttFriendlyPrime(30, 12)
        return q, None
    return 0, primesFor(spec[1], n, spec[2], nwc)


SOURCES = ('rom', 'rec', 'otf', 'rec+twist', 'unified', 'tree', 'shoup', 'uni+shoup')


def gate1(quick: bool) -> int:
    fails = 0
    t0 = time.time()
    cases = [c + (src,) for c in H1_CASES for src in SOURCES if (src == 'rom' or c[1] <= 4096) and
             (src != 'rec+twist' or c[7] == 'output') and (src != 'unified' or c[5] in REDS)]
    for (tag, n, U, g, ms, red, nwc, iscale, slots, src) in cases:
        tag = f'{tag} [{src}]'
        if quick and n > 2048:
            continue
        t1 = time.time()
        try:
            q, moduli = _modspec(ms, n, nwc)
            s = hybrid('h1', n, U, g, q=q, moduli=moduli, red='shoup' if src in ('shoup', 'uni+shoup') else red,
                       nwc=nwc, iscale=iscale, slots=slots,
                       twiddleSource='rom' if src in ('unified', 'shoup', 'uni+shoup') else src.split('+')[0],
                       twistSource='rec' if '+twist' in src else 'tab', unified=src in ('unified', 'uni+shoup'))
            errs = s.checkGeometry() + s.checkGenerators()
            if src not in ('rom', 'unified', 'shoup', 'tree', 'uni+shoup') and not s.generatorCount():
                errs.append('no generator built')
            rng = random.Random(n + U + g)
            qs = s.moduliList()
            P = 2 * len(qs) if len(qs) > 1 else 2
            fq = [qs[f % len(qs)] for f in range(P)]
            ds = ['fwd' if f % 2 == 0 else 'inv' for f in range(P)]
            xs = [[rng.randrange(fq[f]) for _ in range(n)] for f in range(P)]
            # forward frames: x in memory order; inverse frames: NTT(x) in memory order
            ins, want = [], []
            for f in range(P):
                Y = nttRef(xs[f], fq[f], nwc)
                if ds[f] == 'fwd':
                    ins.append(memFrame(xs[f])); want.append(Y)
                else:
                    ins.append(memFrame(Y)); want.append(xs[f])
            got = s.transform(ins, ds, fq)
            ok = got == want and not errs
            job = s.simulateJob(6 * s.S + 4)
            hz = s.checkHazards(job)
            ivm = s.cyclesPerPolynomial()
            # steady state: every window of S consecutive polynomials (after the first S) takes at most S x the
            # model's interval (R x slot), distinct polynomials back to back, always-valid input
            o = [x[0] for x in job['out']]
            ivs = max((o[k + s.S] - o[k]) / s.S for k in range(s.S, len(o) - s.S))
            okr = ivs <= ivm and not hz
            ok = ok and okr
            r = s.report()
            print(f"  {'ok ' if ok else 'BAD'} {tag:<34} R={s.R} e={s.e} S={s.S} slot={s.slotLength()} T={s.T} "
                  f"interval {ivs:.0f} (model {ivm}) latency {job['latency']} tables {len(s.roundTables()[0])} "
                  f"tw words {s.twiddleWords()} stored {s.storedTwiddleWords()} gens {s.generatorCount()}  {'' if not errs else errs[:1]}{'' if not hz else hz[:1]}"
                  f" ({time.time() - t1:.0f}s)")
        except Exception as ex:          # noqa: BLE001
            import traceback
            traceback.print_exc()
            ok = False
            print(f'  BAD {tag}: {type(ex).__name__}: {ex}')
        fails += not ok
    # a DSP budget over the butterflies and the twist (real DSP multipliers)
    for frac in (0.6,):
        try:
            qs = primesFor(32, 1024, 2, True)
            s = hybrid('h1b', 1024, 5, 1, moduli=qs, nwc=True, behavioural=False, dspFraction=frac)
            from operator_modeling.core import dspbudget as DB
            ok = not DB.check(s.dspTree) and s.dspTree.dsp <= s.dspTree.budget
            rng = random.Random(3)
            x = [rng.randrange(qs[1]) for _ in range(1024)]
            ok = ok and s.transform([memFrame(x)], 'fwd', qs[1])[0] == nttRef(x, qs[1], True)
            print(f"  {'ok ' if ok else 'BAD'} dsp budget {frac}: {s.dspTree.dsp} of {s.dspTree.budget} DSP")
        except Exception as ex:          # noqa: BLE001
            ok = False
            print(f'  BAD dsp budget: {type(ex).__name__}: {ex}')
        fails += not ok
    fails += gate1Bram(quick)
    fails += gate1Fan(quick)
    fails += gate1Share(quick)
    fails += gate1Ports(quick)
    print(f'gate H1 hybrid model: {fails} failing ({time.time() - t0:.0f}s)')
    return fails


def _roundTrip(s, n, nwc, seed=5):
    '''Forward and inverse of one random polynomial per modulus through the model, against the reference.'''
    rng = random.Random(seed)
    for q in s.moduliList():
        x = [rng.randrange(q) for _ in range(n)]
        Y = nttRef(x, q, nwc)
        if s.transform([memFrame(x), memFrame(Y)], ['fwd', 'inv'], [q, q]) != [Y, x]:
            return False
    return True


def gate1Fan(quick: bool) -> int:
    '''fanout=: the register trees keep the schedule but for the read shift (twin, hazards, registers).'''
    fails = 0
    cases = [(1024, 3, 2, {}), (1024, 3, 2, {'crossRegs': 2}), (1024, 3, 2, {'twiddleSource': 'rec', 'twistSource': 'rec'}),
             (1024, 3, 2, {'fanoutLoads': 'pins'}), (512, 3, 2, {'unified': True, 'nwc': False, 'iscale': 'stage'})]
    if not quick:
        cases += [(4096, 4, 4, {}), (4096, 4, 4, {'twiddleSource': 'tree', 'crossRegs': 1})]
    for (n, U, g, kw) in cases:
        kw = dict(kw)
        nwc = kw.pop('nwc', True)
        qs = primesFor(30, n, 3, nwc)
        ref = hybrid('h1f', n, U, g, moduli=qs, nwc=nwc, **kw)
        j0 = ref.simulateJob(6 * ref.S + 4)
        for F in (32, 8, 4, 2):
            t1 = time.time()
            try:
                s = hybrid('h1f', n, U, g, moduli=qs, nwc=nwc, fanout=F, **kw)
                job, plan, sh = s.simulateJob(6 * s.S + 4), s.fanoutPlan(), s.fanShift()
                lv = [v['levels'] for v in plan.values()] + [x for v in plan.values() for x in v.get('tables', {}).values()]
                rule = all(not l or (l[0] <= F and all(b <= F * a for a, b in zip(l, l[1:]))) for l in lv)
                ok = (rule and not s.checkHazards(job) and not s.checkGenerators() and _roundTrip(s, n, nwc)
                      and s.inOffset() == ref.inOffset() + sh and job['latency'] == j0['latency'] + sh
                      and s.S == ref.S and s.slotLength() == ref.slotLength()
                      and s.cyclesPerPolynomial() == ref.cyclesPerPolynomial()
                      and s.resources()['ff'] == ref.resources()['ff'] + s.fanoutRegisters()
                      and s.resources()['dsp'] == ref.resources()['dsp'])
                note = (f"shift {sh}, latency {j0['latency']} -> {job['latency']}, tree registers "
                        f"{s.fanoutRegisters()} (ff {ref.resources()['ff']} -> {s.resources()['ff']}), deepest "
                        f"{max([len(l) for l in lv] or [0])}")
            except Exception as ex:          # noqa: BLE001
                import traceback
                traceback.print_exc()
                ok, note = False, f'{type(ex).__name__}: {ex}'
            fails += not ok
            print(f"  {'ok ' if ok else 'BAD'} fanout {F}: n{n} U{U} g{g} {kw or ''}: {note} ({time.time() - t1:.0f}s)")
    try:
        hybrid('h1f', 1024, 3, 2, moduli=primesFor(30, 1024, 3, True), nwc=True, fanout=1)
        ok = False
    except ValueError:
        ok = True
    fails += not ok
    print(f"  {'ok ' if ok else 'BAD'} fanout 1 is refused")
    return fails


def gate1Share(quick: bool) -> int:
    '''shareInverseTwiddles: the inverse reads the forward tables where a whole table allows it (cyclic, CT).'''
    fails = 0
    cases = [(256, 2, 1, 1, {}), (512, 3, 2, 1, {}), (1024, 3, 2, 3, {}), (1024, 3, 4, 1, {}), (1024, 3, 2, 2, {'red': 'shoup'}),
             (1024, 3, 2, 1, {'crossRegs': 2}), (1024, 3, 1, 1, {}), (1024, 4, 2, 1, {'red': 'mont'})]
    if not quick:
        cases += [(2048, 4, 2, 1, {}), (4096, 2, 1, 1, {}), (4096, 3, 2, 1, {}), (4096, 4, 4, 1, {}), (4096, 5, 2, 1, {})]
    for (n, U, g, M, kw) in cases:
        t1 = time.time()
        try:
            qs = primesFor(30, n, M, False)
            ref = hybrid('h1s', n, U, g, moduli=qs, nwc=False, twiddleSource='rom', **kw)
            s = hybrid('h1s', n, U, g, moduli=qs, nwc=False, twiddleSource='rom', shareInverseTwiddles=True, **kw)
            j0, job = ref.simulateJob(6 * ref.S + 4), s.simulateJob(6 * s.S + 4)
            rp, w0, w1 = s.inverseShareReport(), ref.storedTwiddleWords(), s.storedTwiddleWords()
            sh = s.inverseShare()
            src = all(tj in sh and s.inverseAddressMap(tj) == am for (tj, am, _) in sh.values())
            ok = (not s.checkHazards(job) and not s.checkGenerators() and _roundTrip(s, n, False) and src
                  and s.inOffset() == ref.inOffset() and job['latency'] == j0['latency'] and s.S == ref.S
                  and s.cyclesPerPolynomial() == ref.cyclesPerPolynomial() and w1 < w0
                  and s.resources()['dsp'] == ref.resources()['dsp'])
            note = (f"stored words {w0} -> {w1} (-{100 * (w0 - w1) / w0:.1f} %), tables shared {rp['shared']} of {rp['tables']}, "
                    f"butterflies with a swap {rp['swapButterflies']}, with a second source {rp['secondSources']} of "
                    f"{rp['butterflies']}, latency {job['latency']}; model LUT {ref.resources()['lut']} -> {s.resources()['lut']}, "
                    f"FF {ref.resources()['ff']} -> {s.resources()['ff']}, BRAM36 {ref.resources()['bram']} -> {s.resources()['bram']}")
        except Exception as ex:          # noqa: BLE001
            import traceback
            traceback.print_exc()
            ok, note = False, f'{type(ex).__name__}: {ex}'
        fails += not ok
        print(f"  {'ok ' if ok else 'BAD'} shared inverse: n{n} U{U} g{g} {M} moduli {kw or ''}: {note} ({time.time() - t1:.0f}s)")
    for tag, nwc, kw in (('negacyclic', True, {}), ('unified', False, {'unified': True}), ('one direction', False, {'direction': 'forward'}),
                         ('tree twiddles', False, {'twiddleSource': 'tree'}), ('generated twiddles', False, {'twiddleSource': 'rec'}),
                         ('fanout', False, {'fanout': 4})):
        try:
            hybrid('h1s', 1024, 3, 2, moduli=primesFor(30, 1024, 1, nwc), nwc=nwc,
                   **{'twiddleSource': 'rom', **kw}, shareInverseTwiddles=True)
            ok = False
        except ValueError:
            ok = True
        fails += not ok
        print(f"  {'ok ' if ok else 'BAD'} shared inverse with {tag} is refused")
    return fails


def gate1Bram(quick: bool) -> int:
    '''setBramBudget: twiddleSource='auto' under a BRAM36 budget (the tables move to generated supplies).'''
    fails = 0

    def case(tag, fn):
        nonlocal fails
        t1 = time.time()
        try:
            ok, note = fn()
        except Exception as ex:          # noqa: BLE001
            import traceback
            traceback.print_exc()
            ok, note = False, f'{type(ex).__name__}: {ex}'
        fails += not ok
        print(f"  {'ok ' if ok else 'BAD'} bram budget: {tag}: {note} ({time.time() - t1:.0f}s)")

    def small(budget, expectMove):
        def fn():
            qs = primesFor(30, 1024, 8, True)
            ref = hybrid('h1m', 1024, 3, 2, moduli=qs, nwc=True, twiddleSource='auto', twiddleStyle='block')
            b0, src0 = ref.bramCount(), list(ref._srcOf)
            s = hybrid('h1m', 1024, 3, 2, moduli=qs, nwc=True, twiddleSource='auto', twiddleStyle='block',
                       bramBudget=budget)
            p = s.bramPlan
            moved = bool(p['moved'] or p['twist'])
            ok = p['fits'] and s.bramCount() <= budget and moved == expectMove and not s.checkGenerators()
            if not expectMove:
                ok = ok and s._srcOf == src0 and s.bramCount() == b0
            ok = ok and _roundTrip(s, 1024, True) and not s.checkHazards(s.simulateJob(6 * s.S + 4))
            return ok, (f"{b0:g} -> {p['after']:g} of {budget:g} BRAM36, sources {p['sources']}, twist "
                        f"{p['twistSource']}, stored words {ref.storedTwiddleWords()} -> {s.storedTwiddleWords()}, "
                        f"DSP {ref.resources()['dsp']} -> {s.resources()['dsp']}")
        return fn
    case('n1024 U3 g2 8q nwc, budget 60 (fits already)', small(60, False))
    case('n1024 U3 g2 8q nwc, budget 42 (tables move)', small(42, True))
    case('n1024 U3 g2 8q nwc, budget 32 (tables and twist move)', small(32, True))

    def refuse(budget, **kw):
        def fn():
            qs = primesFor(30, 1024, 8, True)
            try:
                hybrid('h1m', 1024, 3, 2, moduli=qs, nwc=True, twiddleStyle='block', bramBudget=budget, **kw)
            except ValueError as ex:
                return 'no twiddle supply fits' in str(ex), 'refused: ' + str(ex)[:150] + ' ...'
            return False, 'no error'
        return fn
    case('budget 20 is below the data memories (error expected)', refuse(20, twiddleSource='auto'))
    case('Shoup tables cannot move (error expected)', refuse(40, twiddleSource='auto', red='shoup'))
    case("twiddleSource 'rom' is fixed (error expected)", refuse(40, twiddleSource='rom'))
    if not quick:
        def big(budget=None, fraction=None, expectMove=True):
            def fn():
                qs = primesFor(32, 65536, 8, True)
                ref = hybrid('h1M', 65536, 4, 8, moduli=qs, nwc=True, twiddleSource='auto')
                s = hybrid('h1M', 65536, 4, 8, moduli=qs, nwc=True, twiddleSource='auto')
                p = s.setBramBudget(total=budget, fraction=fraction)
                moved = bool(p['moved'] or p['twist'])
                ok = p['fits'] and s.bramCount() <= p['budget'] and moved == expectMove and not s.checkGenerators()
                if not expectMove:
                    ok = ok and s._srcOf == ref._srcOf
                ok = ok and not s.checkHazards(s.simulateJob(6 * s.S + 4))
                return ok, (f"{p['before']:g} -> {p['after']:g} of {p['budget']:g} BRAM36, sources {p['sources']}, "
                            f"twist {p['twistSource']}, stored words {ref.storedTwiddleWords()} -> "
                            f"{s.storedTwiddleWords()}, DSP {ref.resources()['dsp']} -> {s.resources()['dsp']}, "
                            f"area units {ref.areaUnits():.0f} -> {s.areaUnits():.0f}")
            return fn
        case('n65536 U4 g8 8q 32b nwc, 0.8 of the V80 (fits already)', big(fraction=0.8, expectMove=False))
        case('n65536 U4 g8 8q 32b nwc, budget 1500', big(budget=1500))
        case('n65536 U4 g8 8q 32b nwc, budget 800', big(budget=800))
        case('n65536 U4 g8 8q 32b nwc, budget 300', big(budget=300))
    return fails


# (name, n, U, g, modulus spec, reduction, nwc, iscale, slots, polys, valid, direction pattern)
H2_POINTS = [
    ('hy64_u2_cyc', 64, 2, 1, ('q', 'q30'), 'barrett', False, 'stage', 'auto', 6, None, 'mix'),
    ('hy256_u2g2_cyc', 256, 2, 2, ('q', 'q30'), 'barrett', False, 'output', 'auto', 6, 'random', 'mix'),
    ('hy512_u3g2_e1_nwc', 512, 3, 2, ('q', 'q30'), 'barrett', True, 'output', 2, 6, None, 'mix'),
    ('hy1024_u3g2_e2_nwc3q', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, 'random', 'mix'),
    ('hy1024_u5_nwc4q', 1024, 5, 1, ('m', 32, 4), 'barrett', True, 'output', 'auto', 8, None, 'mix'),
    ('hy2048_u4g2_e1_cyc3q', 2048, 4, 2, ('m', 40, 3), 'mont', False, 'stage', 1, 6, None, 'mix'),
    ('hy4096_u3g4_nwc62_2q', 4096, 3, 4, ('m', 62, 2), 'barrett', True, 'output', 'auto', 5, 'random', 'mix'),
    ('hy8192_u5g2_e2_q52', 8192, 5, 2, ('q', Q52M), 'barrett', False, 'stage', 'auto', 6, None, 'mix'),
    # generated twiddles: Kim's recurrence and the two-table product, modulus and direction every polynomial
    ('hy1024_u3g2_e2_nwc3q_rec', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, 'random', 'mix',
     {'twiddleSource': 'rec'}),
    ('hy1024_u3g2_e2_nwc3q_otf', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, None, 'mix',
     {'twiddleSource': 'otf'}),
    ('hy512_u2g2_cyc_rec', 512, 2, 2, ('q', 'q30'), 'barrett', False, 'stage', 1, 5, None, 'mix',
     {'twiddleSource': 'rec', 'genMinBits': 1}),
    ('hy4096_u3g4_nwc4q_rec', 4096, 3, 4, ('m', 40, 4), 'mont', True, 'output', 'auto', 5, 'random', 'mix',
     {'twiddleSource': 'rec'}),
    # word-level Montgomery over friendly primes (q = qH 2^v + 1) with a modulus per polynomial
    ('hy1024_u3g2_e2_nwc4q_wlm', 1024, 3, 2, ('f', 32, 4), 'wlm', True, 'output', 'auto', 6, 'random', 'mix',
     {'twiddleSource': 'rec', 'twistSource': 'rec'}),
    # unified CT/GS butterflies: the negacyclic inverse as GS with psi^-1 merged and x2^-1 per stage (no twist)
    ('hy1024_u3g2_e2_nwc3q_uni', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, 'random', 'mix',
     {'unified': True}),
    ('hy512_u3g2_cyc_uni', 512, 3, 2, ('q', 'q30'), 'barrett', False, 'stage', 'auto', 6, None, 'mix',
     {'unified': True}),
    ('hy2048_u4g2_e1_nwc_uni_wlm', 2048, 4, 2, ('f', 32, 2), 'wlm', True, 'output', 'auto', 5, None, 'mix',
     {'unified': True}),
    # the output twist by the recurrence as well (no table grows with the moduli)
    ('hy1024_u3g2_e2_nwc3q_allrec', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, 'random', 'mix',
     {'twiddleSource': 'rec', 'twistSource': 'rec'}),
    ('hy512_u2g2_cyc_out_trec', 512, 2, 2, ('q', 'q30'), 'barrett', False, 'output', 2, 6, None, 'mix',
     {'twiddleSource': 'rom', 'twistSource': 'rec'}),
    # a modulus unknown at build time: tables and constants loaded through the load port (see gate2)
    ('hy1024_u3g2_nwc3q_ld', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, 'random', 'mix',
     {'loadable': True}),
    ('hy1024_u3g2_nwc3q_ld_rec', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, None, 'mix',
     {'loadable': True, 'twiddleSource': 'rec', 'twistSource': 'rec'}),
    ('hy1024_u3g2_nwc3q_ld_otf', 1024, 3, 2, ('m', 30, 3), 'mont', True, 'output', 'auto', 6, None, 'mix',
     {'loadable': True, 'twiddleSource': 'otf'}),
    # Shoup butterflies ({WP, W} twiddle words), read latency 4
    ('hy1024_u3g2_nwc3q_shoup', 1024, 3, 2, ('m', 30, 3), 'shoup', True, 'output', 'auto', 6, 'random', 'mix'),
    ('hy512_u2g2_cyc_shoup', 512, 2, 2, ('q', 'q30'), 'shoup', False, 'stage', 'auto', 6, None, 'mix'),
    ('hy1024_u3g2_nwc2q_ld_shoup', 1024, 3, 2, ('m', 30, 2), 'shoup', True, 'output', 'auto', 6, None, 'mix',
     {'loadable': True}),
    ('hy1024_u3g2_nwc3q_rl4', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, 'random', 'mix',
     {'ramLatency': 4, 'twiddleSource': 'rec', 'twistSource': 'rec'}),
    # 'tree': one table per round and stage, the others that table times a constant; 'stream': tables outside
    ('hy1024_u3g2_nwc3q_tree', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, 'random', 'mix',
     {'twiddleSource': 'tree'}),
    ('hy4096_u3g4_cyc_tree', 4096, 3, 4, ('q', 'q30'), 'mont', False, 'stage', 'auto', 5, None, 'mix',
     {'twiddleSource': 'tree', 'genMinBits': 1}),
    # ioLanes: ports narrower (gathered input, buffered output) and wider (held input, collected output) than W
    ('hy1024_u3g2_nwc3q_io4', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, 'random', 'mix',
     {'ioLanes': 4}),
    ('hy1024_u3g2_nwc3q_io8', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, None, 'mix',
     {'ioLanes': 8}),
    ('hy1024_u3g2_nwc3q_s2_io8', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 2, 8, None, 'mix',
     {'ioLanes': 8}),
    ('hy1024_u3g2_nwc3q_io64', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, 'random', 'mix',
     {'ioLanes': 64}),
    ('hy512_u2g2_cyc_io32', 512, 2, 2, ('q', 'q30'), 'mont', False, 'stage', 'auto', 6, None, 'mix',
     {'ioLanes': 32}),
    # crossRegs: register stages on the operand and write paths (SLR crossings)
    ('hy1024_u3g2_nwc3q_xr2', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, 'random', 'mix',
     {'crossRegs': 2}),
    ('hy1024_u3g2_nwc3q_s1_xr1_tree', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 1, 5, None, 'mix',
     {'crossRegs': 1, 'twiddleSource': 'tree'}),
    ('hy512_u2g2_cyc_xr2_io2', 512, 2, 2, ('q', 'q30'), 'mont', False, 'stage', 'auto', 6, None, 'mix',
     {'crossRegs': 2, 'ioLanes': 2}),
    ('hy1024_u3g2_nwc2q_ld_io4', 1024, 3, 2, ('m', 30, 2), 'barrett', True, 'output', 'auto', 6, 'random', 'mix',
     {'loadable': True, 'twiddleSource': 'stream', 'ioLanes': 4}),
    ('hy1024_u3g2_nwc2q_ld_tree', 1024, 3, 2, ('m', 30, 2), 'barrett', True, 'output', 'auto', 6, None, 'mix',
     {'loadable': True, 'twiddleSource': 'tree', 'twistSource': 'rec'}),
    ('hy1024_u3g2_nwc3q_stream', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, 'random', 'mix',
     {'twiddleSource': 'stream'}),
    ('hy1024_u3g2_nwc2q_ld_stream', 1024, 3, 2, ('m', 30, 2), 'shoup', True, 'output', 'auto', 6, None, 'mix',
     {'loadable': True, 'twiddleSource': 'stream', 'twistSource': 'rec'}),
    ('hy512_u3g2_cyc_uni_stream', 512, 3, 2, ('q', 'q30'), 'barrett', False, 'stage', 'auto', 6, None, 'mix',
     {'unified': True, 'twiddleSource': 'stream'}),
    ('hy512_u3g2_cyc1q_ld', 512, 3, 2, ('m', 30, 1), 'barrett', False, 'stage', 'auto', 6, None, 'mix',
     {'loadable': True}),
    ('hy2048_u4g2_nwc2q_ld_wlm', 2048, 4, 2, ('f', 32, 2), 'wlm', True, 'output', 'auto', 5, 'random', 'mix',
     {'loadable': True, 'twiddleSource': 'rec', 'twistSource': 'rec'}),
    ('hy1024_u3g2_nwc2q_ld_uni', 1024, 3, 2, ('m', 30, 2), 'barrett', True, 'output', 'auto', 6, None, 'mix',
     {'loadable': True, 'unified': True}),
    # setBramBudget: 'auto' under a BRAM36 budget: ROM, tree, rec tables side by side and the twist recurrence
    ('hy1024_u3g2_nwc8q_bram32', 1024, 3, 2, ('m', 30, 8), 'barrett', True, 'output', 'auto', 8, 'random', 'mix',
     {'twiddleSource': 'auto', 'twiddleStyle': 'block', 'bramBudget': 32}),
    ('hy1024_u3g2_nwc3q_bram23', 1024, 3, 2, ('m', 30, 3), 'mont', True, 'output', 'auto', 6, None, 'mix',
     {'twiddleSource': 'auto', 'twiddleStyle': 'block', 'bramBudget': 23}),
    # Shoup with the unified CT/GS butterfly: {WP, W} words for both directions (rom, stream, loadable)
    ('hy1024_u3g2_nwc3q_uni_shoup', 1024, 3, 2, ('m', 30, 3), 'shoup', True, 'output', 'auto', 6, 'random', 'mix',
     {'unified': True}),
    ('hy512_u3g2_cyc_uni_shoup_stream', 512, 3, 2, ('q', 'q30'), 'shoup', False, 'stage', 'auto', 6, None, 'mix',
     {'unified': True, 'twiddleSource': 'stream'}),
    ('hy1024_u3g2_nwc2q_ld_uni_shoup', 1024, 3, 2, ('m', 30, 2), 'shoup', True, 'output', 'auto', 6, 'random', 'mix',
     {'loadable': True, 'unified': True}),
    # fanout: register trees behind the wide control nets (the read trees shift the reads; the twin follows)
    ('hy1024_u3g2_nwc3q_fan4', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, 'random', 'mix',
     {'fanout': 4}),
    ('hy1024_u3g2_nwc3q_fan4_xr2', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, None, 'mix',
     {'fanout': 4, 'crossRegs': 2}),
    ('hy512_u3g2_cyc_uni_fan2', 512, 3, 2, ('q', 'q30'), 'barrett', False, 'stage', 'auto', 6, 'random', 'mix',
     {'unified': True, 'fanout': 2}),
    ('hy1024_u3g2_nwc3q_fan4_allrec', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, 'random', 'mix',
     {'fanout': 4, 'twiddleSource': 'rec', 'twistSource': 'rec'}),
    ('hy1024_u3g2_nwc2q_ld_fan3_tree', 1024, 3, 2, ('m', 30, 2), 'barrett', True, 'output', 'auto', 6, None, 'mix',
     {'loadable': True, 'twiddleSource': 'tree', 'fanout': 3}),
    ('hy1024_u3g2_nwc3q_fan4_io4', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, 'random', 'mix',
     {'fanout': 4, 'ioLanes': 4}),
    ('hy64_u2_cyc_fan8_pins', 64, 2, 1, ('q', 'q30'), 'barrett', False, 'stage', 'auto', 6, 'random', 'mix',
     {'fanout': 8, 'fanoutLoads': 'pins'}),
    # shareInverseTwiddles: the inverse reads the forward tables (address map, output swap, second source)
    ('hy256_u2_cyc_share', 256, 2, 1, ('q', 'q30'), 'barrett', False, 'stage', 'auto', 8, 'random', 'mix',
     {'shareInverseTwiddles': True}),
    ('hy512_u3g2_cyc_share', 512, 3, 2, ('q', 'q30'), 'barrett', False, 'stage', 'auto', 8, 'random', 'mix',
     {'shareInverseTwiddles': True}),
    ('hy1024_u3g4_cyc3q_share', 1024, 3, 4, ('m', 30, 3), 'barrett', False, 'stage', 'auto', 8, 'random', 'mix',
     {'shareInverseTwiddles': True}),
    ('hy1024_u3g2_cyc3q_share_shoup', 1024, 3, 2, ('m', 30, 3), 'shoup', False, 'stage', 'auto', 8, 'random', 'mix',
     {'shareInverseTwiddles': True}),
    ('hy1024_u3g2_cyc3q_share_xr2', 1024, 3, 2, ('m', 30, 3), 'barrett', False, 'stage', 'auto', 8, None, 'mix',
     {'shareInverseTwiddles': True, 'crossRegs': 2}),
    ('hy1024_u3g2_cyc3q_share_io4', 1024, 3, 2, ('m', 30, 3), 'barrett', False, 'stage', 'auto', 8, 'random', 'mix',
     {'shareInverseTwiddles': True, 'ioLanes': 4}),
    ('hy2048_u4g2_cyc2q_share_mont', 2048, 4, 2, ('m', 30, 2), 'mont', False, 'stage', 'auto', 6, 'random', 'mix',
     {'shareInverseTwiddles': True}),
    ('hy1024_u3g2_cyc2q_ld_share', 1024, 3, 2, ('m', 30, 2), 'barrett', False, 'stage', 'auto', 8, 'random', 'mix',
     {'shareInverseTwiddles': True, 'loadable': True}),
    # outReady: out_ready on the output (output buffer + credit on admission); '_oready' is the testbench's
    # out_ready pattern (none: always high, and then the period must be the core's)
    ('hy1024_u3g2_nwc3q_or', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, None, 'mix', {'outReady': True}),
    ('hy1024_u3g2_nwc3q_or_rnd', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 8, 'random', 'mix', {'outReady': True, '_oready': 'random'}),
    ('hy1024_u3g2_nwc3q_or_stall', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 12, None, 'mix', {'outReady': True, '_oready': 'stall'}),
    ('hy1024_u3g2_nwc3q_or_io4', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, None, 'mix', {'outReady': True, 'ioLanes': 4}),
    ('hy1024_u3g2_nwc3q_or_io4_stall', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 12, 'random', 'mix',
     {'outReady': True, 'ioLanes': 4, '_oready': 'stall'}),
    ('hy1024_u3g2_nwc3q_or_io64_rnd', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 8, 'random', 'mix',
     {'outReady': True, 'ioLanes': 64, '_oready': 'random'}),
    ('hy1024_u3g2_nwc3q_or_long', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 12, None, 'mix',
     {'outReady': True, '_oready': 'longstall'}),
    ('hy512_u2g2_cyc_s2_or_d8_stall', 512, 2, 2, ('q', 'q30'), 'mont', False, 'stage', 2, 14, None, 'mix',
     {'outReady': True, 'outDepth': 8, '_oready': 'stall'}),
    # outputOrder='natural': the output buffer reorders the polynomial to natural order
    ('hy1024_u3g2_nwc3q_nat', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, None, 'mix', {'outputOrder': 'natural'}),
    ('hy1024_u3g2_nwc3q_nat_rnd', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 8, 'random', 'mix', {'outputOrder': 'natural'}),
    ('hy1024_u3g2_nwc3q_nat_or_stall', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 12, None, 'mix',
     {'outputOrder': 'natural', 'outReady': True, '_oready': 'stall'}),
    ('hy1024_u3g2_nwc3q_nat_io4_or_rnd', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 8, 'random', 'mix',
     {'outputOrder': 'natural', 'outReady': True, 'ioLanes': 4, '_oready': 'random'}),
    ('hy512_u2g2_cyc_nat_io32', 512, 2, 2, ('q', 'q30'), 'mont', False, 'stage', 'auto', 6, None, 'mix',
     {'outputOrder': 'natural', 'ioLanes': 32}),
    ('hy2048_u4g2_nwc2q_nat_or_rnd', 2048, 4, 2, ('m', 30, 2), 'barrett', True, 'output', 'auto', 6, 'random', 'mix',
     {'outputOrder': 'natural', 'outReady': True, '_oready': 'random'}),
    ('hy64_u2_cyc_nat', 64, 2, 1, ('q', 'q30'), 'barrett', False, 'stage', 'auto', 8, 'random', 'mix',
     {'outputOrder': 'natural'}),
    # twiddleBuffer='record': the modulus of every polynomial arrives as a record on tw_valid/tw_ready/tw_data
    # ('_twvalid': the testbench's tw_valid pattern); the moduli come from both builds' sets
    ('hy1024_u3g2_nwc3q_rec', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 8, None, 'mix', {'loadable': True, 'twiddleBuffer': 'record'}),
    ('hy1024_u3g2_nwc3q_rec_rnd', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 8, 'random', 'mix',
     {'loadable': True, 'twiddleBuffer': 'record', '_twvalid': 'random'}),
    ('hy1024_u3g2_nwc4q_rec_tree', 1024, 3, 2, ('m', 30, 4), 'barrett', True, 'output', 'auto', 8, None, 'mix',
     {'loadable': True, 'twiddleBuffer': 'record', 'twiddleSource': 'tree', 'twistSource': 'rec',
       '_twvalid': 'random'}),
    ('hy1024_u3g2_nwc3q_rec_rectw', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 8, 'random', 'mix',
     {'loadable': True, 'twiddleBuffer': 'record', 'twiddleSource': 'rec', 'twistSource': 'rec'}),
    ('hy512_u3g2_cyc4q_rec_uni', 512, 3, 2, ('m', 30, 4), 'barrett', False, 'stage', 'auto', 8, None, 'mix',
     {'loadable': True, 'twiddleBuffer': 'record', 'unified': True, '_twvalid': 'random'}),
    ('hy1024_u3g2_nwc3q_rec_or_stall', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 12, None, 'mix',
     {'loadable': True, 'twiddleBuffer': 'record', 'outReady': True, '_oready': 'stall'}),
    # all three with narrow ports: record stream + out_ready + ioLanes 4 + natural order
    ('hy1024_u3g2_nwc3q_rec_or_io4_nat', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 8, 'random', 'mix',
     {'loadable': True, 'twiddleBuffer': 'record', 'outReady': True, 'ioLanes': 4, 'outputOrder': 'natural',
       '_oready': 'random', '_twvalid': 'random'}),
    ('hy1024_u3g2_nwc3q_rec_or_io4_nat_stall', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 12, None, 'mix',
     {'loadable': True, 'twiddleBuffer': 'record', 'twiddleSource': 'tree', 'outReady': True, 'ioLanes': 4,
       'outputOrder': 'natural', '_oready': 'stall', '_twvalid': 'random'}),
]

# the port options' negative tests (--neg): a wrong wrapper built on purpose; the simulation must FAIL
H2_PORT_NEG = [
    ('hyneg_or_slots', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 12, None, 'mix',
     {'outReady': True, '_oready': 'longstall', '_fault': 'slots'}),
    ('hyneg_nat_norot', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 6, None, 'mix', {'outputOrder': 'natural', '_fault': 'norot'}),
    ('hyneg_rec_norok', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 8, None, 'mix',
     {'loadable': True, 'twiddleBuffer': 'record', '_twvalid': 'random', '_fault': 'norok'}),
    ('hyneg_or_credit', 1024, 3, 2, ('m', 30, 3), 'barrett', True, 'output', 'auto', 12, None, 'mix', {'outReady': True, '_oready': 'stall', '_fault': 'credit'}),
]


def gate1Ports(quick: bool) -> int:
    """outReady / outputOrder='natural' / twiddleBuffer='record' (operator_modeling.ntt.hybrid.HybridPorts): the
    wrapper's twin. Always valid and always ready: the polynomials start in the cycles of the design without the
    options (same period). Random and stalling patterns: the credits never exceed the buffer, the landing FIFO
    never overflows, the core sees no hazard. The record stream: period = max(core, record beats). Refusals."""
    from operator_modeling.ntt.hybrid.HybridPorts import coreHazards
    fails = 0

    def case(tag, fn):
        nonlocal fails
        t1 = time.time()
        try:
            ok, note = fn()
        except Exception as ex:          # noqa: BLE001
            import traceback
            traceback.print_exc()
            ok, note = False, f'{type(ex).__name__}: {ex}'
        fails += not ok
        print(f"  {'ok ' if ok else 'BAD'} ports: {tag}: {note} ({time.time() - t1:.0f}s)")

    def pat(seed, prob):
        rng = random.Random(seed)
        bits = [rng.random() < prob for _ in range(1 << 16)]
        return lambda c: bits[c % len(bits)]

    def stall(seed, per, lo, hi):
        rng = random.Random(seed)
        bits = []
        while len(bits) < (1 << 17):
            bits += [False] * rng.randrange(lo * per, hi * per) + [True] * rng.randrange(per // 2, 3 * per)
        return lambda c: bits[c % len(bits)]

    geos = [(1024, 3, 2, 'auto'), (256, 2, 1, 'auto'), (1024, 3, 2, 3)]
    if not quick:
        geos += [(1024, 5, 1, 'auto'), (4096, 4, 4, 'auto')]
    opts = [{'outReady': True}, {'outputOrder': 'natural'}, {'outReady': True, 'outputOrder': 'natural'},
            {'outReady': True, 'ioLanes': 4}, {'outReady': True, 'ioLanes': 4, 'outputOrder': 'natural'},
            {'outReady': True, 'ioLanes': 64, 'outputOrder': 'natural'}]
    for (n, U, g, sl) in geos:
        qs = primesFor(30, n, 3, True)
        for kw in opts:
            if kw.get('ioLanes') and (n // kw['ioLanes']) * kw['ioLanes'] != n:
                continue

            def fn(n=n, U=U, g=g, sl=sl, kw=kw, qs=qs):
                base = hybrid('h1p', n, U, g, moduli=qs, nwc=True, slots=sl, **{k: v for k, v in kw.items() if k == 'ioLanes'})
                s = hybrid('h1p', n, U, g, moduli=qs, nwc=True, slots=sl, **kw)
                P = 6 * s.S + 6
                jb = base.simulateJob(P) if base.io == base.W else base.simulateIoJob(P)
                j = s.simulatePortsJob(P)
                DP, K = s.outDepth(), s.portsGeometry()['K']
                ok = j['accept'] == jb['accept'] and s.portsSteadyInterval() == s.cyclesPerPolynomial() == base.cyclesPerPolynomial()
                ok = ok and not coreHazards(s, j['core']) and j['peakCredits'] <= DP and j['peakLanding'] <= K
                ok = ok and DP >= j['peakCredits'] + (0 if s._outDepthReq else 1)
                per = s.cyclesPerPolynomial()
                worst = 0
                for sd, (v, r) in enumerate([(pat(1, 0.7), pat(2, 0.6)), (None, stall(3, per, 1, 4)),
                                             (pat(4, 0.5), stall(5, per, DP + s.S + 4, DP + s.S + 6)),
                                             (pat(6, 0.9), pat(7, 0.2))]):
                    jr = s.simulatePortsJob(P, v, r if s.outReady else None)
                    ok = ok and not coreHazards(s, jr['core']) and jr['peakCredits'] <= DP and jr['peakLanding'] <= K
                    worst = max(worst, jr['peakCredits'])
                mem = [m for m in s.memories() if m['what'].startswith(('output buffer', 'landing'))]
                ok = ok and len(mem) == 2 and mem[0]['depth'] == DP * s.T and mem[1]['depth'] == K
                ok = ok and s.latency() > base.latency()
                return ok, (f"period {s.portsSteadyInterval():g} = {base.cyclesPerPolynomial()}, buffer {DP} polynomial(s) "
                            f"(most credits {worst}), landing FIFO {K}, latency {base.latency()} -> {s.latency()}")
            case(f'n{n} U{U} g{g} slots {sl} {kw}', fn)

    def record():
        from operator_modeling.modmult.ModulusFamily import ModulusFamily as MF
        out = []
        ok = True
        for src in ('rom', 'rec', 'tree'):
            qs = primesFor(30, 1024, 4, True)
            s = hybrid('h1p', 1024, 3, 2, moduli=qs, nwc=True, loadable=True, family=MF.odd(30), twiddleSource=src,
                       twiddleBuffer='record')
            P = 6 * s.S + 6
            words, core = s.recordWords(), s.cyclesPerPolynomial()
            new = s.portsSteadyInterval(P, keep=[False] * P)
            kept = s.portsSteadyInterval(P, keep=[False] + [True] * (P - 1))
            ok = ok and kept == core and max(core, words + 1) <= new <= max(core, words + 1) + 8
            ok = ok and words == sum(c for _, c in s.recordRegions())
            for sd in (1, 2):
                jr = s.simulatePortsJob(P, pat(sd, 0.7), None, pat(sd + 9, 0.6), [f % 3 == 2 for f in range(P)])
                ok = ok and not coreHazards(s, jr['core']) and jr['peakUse'] <= 31
            out.append(f'{src}: {words} entries, period {new:g} (core {core})')
        return ok, '; '.join(out)
    case('record stream n1024 U3 g2', record)

    def refusals():
        from operator_modeling.modmult.ModulusFamily import ModulusFamily as MF
        qs = primesFor(30, 1024, 4, True)
        bad = [dict(outReady=True, outDepth=0), dict(outDepth=4), dict(outputOrder='bitrev'),
               dict(twiddleBuffer='record'), dict(twiddleLanes=2),
               dict(twiddleBuffer='record', loadable=True, family=MF.odd(30), twiddleLanes=3),
               dict(twiddleBuffer='record', loadable=True, family=MF.odd(30), twiddleSource='stream'),
               dict(twiddleBuffer='record', loadable=True, family=MF.odd(30), moduli=qs[:2])]
        got = 0
        for kw in bad:
            kw = dict(kw)
            try:
                hybrid('h1p', 1024, 3, 2, moduli=kw.pop('moduli', qs), nwc=True, **kw)
            except ValueError:
                got += 1
        return got == len(bad), f'{got} of {len(bad)} wrong option sets refused'
    case('refusals', refusals)
    return fails


EXPECT_FAIL = set()        # points with a fault built on purpose (H2_PORT_NEG): the simulation must FAIL


def _sim(run: str, slot: str) -> str:
    env = dict(os.environ, V80_REMOTE_ROOT=slot)
    r = subprocess.run([sys.executable, 'scripts/run_remote_sim.py', '--run-dir', run], capture_output=True,
                       text=True, env=env)
    with open(os.path.join(run, 'sim.log'), 'w', encoding='utf-8') as f:
        f.write(r.stdout + r.stderr)
    rate = next((ln for ln in r.stdout.splitlines() if '[tb] rate' in ln), '')
    v = next((ln.split(': ', 1)[1] for ln in r.stdout.splitlines()
              if ln.startswith('[run_remote_sim]') and (': PASS' in ln or ': FAIL' in ln)), 'NO VERDICT')
    return v, rate


def gate2(root: str, sim: bool, only=None, points=None, behavioural=False) -> int:
    pts = [p for p in (points or H2_POINTS) if not only or p[0] in only]
    runs = []
    for pt in pts:
        (name, n, U, g, ms, red, nwc, iscale, slots, P, valid, dpat), xk = pt[:12], (pt[12] if len(pt) > 12 else {})
        t0 = time.time()
        q, moduli = _modspec(ms, n, nwc)
        xk = dict(xk)
        # test-only keys of the port options: out_ready and record-valid patterns, a fault built on purpose
        tp = {k: xk.pop(k) for k in ('_oready', '_twvalid', '_fault') if k in xk}
        xk.setdefault('twiddleSource', 'rom')
        if ms[0] == 'f':
            xk['family'] = friendlyPrimes(ms[1], n, ms[2], nwc)[1]
        alt = None
        if xk.get('loadable'):
            # a modulus unknown at build time: the RTL is generated twice, from two disjoint sets of moduli of
            # the family, and must be byte-identical; the simulation loads the second set's image
            from operator_modeling.modmult.ModulusFamily import ModulusFamily as MF
            k = len(moduli)
            both = friendlyPrimes(ms[1], n, 2 * k, nwc)[0] if ms[0] == 'f' else primesFor(ms[1], n, 2 * k, nwc)
            alt, moduli = both[:k], both[k:]
            xk.setdefault('family', MF.odd(ms[1]))
        s = hybrid(name, n, U, g, q=q, moduli=moduli, red=red, nwc=nwc, iscale=iscale, slots=slots,
                   behavioural=behavioural, target=350.0, **xk)
        qs = s.moduliList()
        rng = random.Random(9)
        fq = [qs[(f * 7 + f // 3) % len(qs)] for f in range(P)]
        ds = ['inv' if (f + f // 2) & 1 else 'fwd' for f in range(P)] if dpat == 'mix' else [dpat] * P
        frames = [[rng.randrange(fq[f]) for _ in range(n)] for f in range(P)]
        run = os.path.join(root, name)
        pk = None
        if s.portsOn():
            pk = {'outReady': tp.get('_oready'), 'twValid': tp.get('_twvalid'), 'fault': tp.get('_fault')}
            if tp.get('_fault'):
                EXPECT_FAIL.add(name)
            if s.twiddleBuffer == 'record':
                # the record stream: no modulus is known at build time, so the polynomials take their moduli
                # from both sets (the design's own and the other build's), every fourth one keeps the last
                sa0 = hybrid(name, n, U, g, q=q, moduli=alt, red=red, nwc=nwc, iscale=iscale, slots=slots,
                             behavioural=behavioural, target=350.0, **xk)
                quiet(lambda: HybridNTT(sa0).emitRtl(name, run + '_alt', ports={'fault': tp.get('_fault')}))
                import json as _js
                with open(os.path.join(run + '_alt', 'load_image.json'), encoding='utf-8') as fh:
                    pk.update(alt=sa0, altRegions=_js.load(fh)['regions'])
                allq = list(alt) + list(qs)
                fq = [allq[(f * 7 + f // 3) % len(allq)] for f in range(P)]
                fq = [fq[f - 1] if f % 4 == 3 else fq[f] for f in range(P)]
                frames = [[rng.randrange(fq[f]) for _ in range(n)] for f in range(P)]
        m = quiet(lambda: HybridNTT(s).emitRtl(name, run, frames=frames, direction=ds, q=fq, validPattern=valid,
                                               ports=pk))
        if pk and valid is None and not tp.get('_oready') and s.twiddleBuffer != 'record':
            # input always valid, out_ready always high: the port options must not cost a cycle of period
            # (the same job on the core's twin without the wrapper: the polynomials start in the same cycles)
            base = (s.simulateJob(P) if s.io == s.W else s.simulateIoJob(P))['interval']
            if m['interval'] != base or s.portsSteadyInterval() != s.cyclesPerPolynomial():
                raise SystemExit(f"{name}: period {m['interval']} with the port options, {base} without")
        if alt:
            sa = hybrid(name, n, U, g, q=q, moduli=alt, red=red, nwc=nwc, iscale=iscale, slots=slots,
                        behavioural=behavioural, target=350.0, **xk)
            quiet(lambda: HybridNTT(sa).emitRtl(name, run + '_alt', ports=pk and {'fault': pk.get('fault')}))
            import filecmp, glob as _g
            fa = sorted(os.path.basename(x) for x in _g.glob(os.path.join(run + '_alt', 'RTL_generated', '*.sv'))
                        if not x.endswith('_tb.sv') and not re.search(r'_twx\d+\.sv$', x))
            fb = sorted(os.path.basename(x) for x in _g.glob(os.path.join(run, 'RTL_generated', '*.sv'))
                        if not x.endswith('_tb.sv') and not re.search(r'_twx\d+\.sv$', x))
            same = fa == fb and all(filecmp.cmp(os.path.join(run + '_alt', 'RTL_generated', x),
                                                os.path.join(run, 'RTL_generated', x), shallow=False) for x in fa)
            print(f"  {name:<26} RTL from moduli {alt} and from {moduli}: "
                  f"{'identical (' + str(len(fa)) + ' files)' if same else 'DIFFERENT'}; loaded: {moduli}")
            if not same:
                raise SystemExit(f'{name}: the loadable RTL depends on the moduli')
        lut, dsp = s.areaCost()
        print(f"  {name:<26} W={s.W} R={s.R} e={s.e} S={s.S} slot {m['slot']} interval {m['interval']} "
              f"latency {m['latency']} LUT~{lut} DSP {dsp} ({time.time() - t0:.0f}s)")
        runs.append((name, run, s.cyclesPerPolynomial()))
    if not sim:
        return 0
    fails = 0
    with cf.ThreadPoolExecutor(max_workers=min(len(SLOTS), len(runs))) as ex:
        free = queue.Queue()                    # more points than slots: a worker borrows a free slot
        for sl in SLOTS:
            free.put(sl)

        def one(run):
            sl = free.get()
            try:
                return _sim(run, sl)
            finally:
                free.put(sl)
        futs = {ex.submit(one, run): (name, iv) for (name, run, iv) in runs}
        for fu in cf.as_completed(futs):
            name, iv = futs[fu]
            v, rate = fu.result()
            if name in EXPECT_FAIL:
                # a wrong design built on purpose: the testbench must catch it
                caught = v.startswith('FAIL')
                fails += not caught
                v = f"{'caught as expected' if caught else 'NOT CAUGHT'} ({v})"
            else:
                fails += not v.startswith('PASS')
            print(f'  xsim {name:<26} {v}  {rate.strip()}')
    print(f'gate H2 hybrid rtl: {len(runs) - fails} of {len(runs)} pass')
    return fails


ACCURACY_ROWS = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'operator_modeling', 'ntt', 'hybrid',
                             'measured_rows.json')
ACC_LIMIT = {'lut': 5.0, 'ff': 5.0, 'area': 3.0}     # per cent; DSP exact, BRAM36 and URAM within one block


def _accScheme(row: dict):
    """The scheme of a stored row of measured_rows.json (no RTL), built as the row's generator run built it."""
    sp = row['spec']
    if row['kind'] == 'point':                   # a gate2 point tuple
        name, n, U, g, ms, red, nwc, iscale, slots = sp[:9]
        xk = dict(sp[12]) if len(sp) > 12 else {}
        ms = tuple(ms)
        q, moduli = _modspec(ms, n, nwc)
        for k in ('_oready', '_twvalid', '_fault'):
            xk.pop(k, None)
        xk.setdefault('twiddleSource', 'rom')
        if ms[0] == 'f':
            xk['family'] = friendlyPrimes(ms[1], n, ms[2], nwc)[1]
        if xk.get('loadable'):
            from operator_modeling.modmult.ModulusFamily import ModulusFamily as MF
            k = len(moduli)
            both = friendlyPrimes(ms[1], n, 2 * k, nwc)[0] if ms[0] == 'f' else primesFor(ms[1], n, 2 * k, nwc)
            moduli = both[k:]
            xk.setdefault('family', MF.odd(ms[1]))
        return hybrid(name, n, U, g, q=q, moduli=moduli, red=red, nwc=nwc, iscale=iscale, slots=slots,
                      behavioural=False, target=350.0, **xk)
    xk = dict(sp.get('extra') or {})             # an explicit row (the rows of ntt_hw/experiments/hybrid/rows.py)
    if sp.get('family'):
        from operator_modeling.modmult.ModulusFamily import ModulusFamily as MF
        xk['family'] = MF.friendly(*sp['family'])
    xk.setdefault('twiddleSource', 'rom')
    kw = dict(q=sp['q']) if sp.get('q') else dict(moduli=list(sp['moduli']))
    return hybrid(row['name'], sp['n'], sp['U'], sp['g'], red=sp['red'], nwc=sp['nwc'], behavioural=False,
                  target=350.0, slots=sp.get('slots', 'auto'), dspFraction=sp.get('dspFraction'), **kw, **xk)


def _au(r: dict) -> float:
    return (r['lut'] / 1000 + r['ff'] / 1000 + 4 / 3 * r['dsp'] + r['bram'] + 8 * r.get('uram', 0)) / 5


def accuracy(path=None, only=None, parts=False) -> int:
    """Gate H3: the area and timing model against the stored place-and-route and simulation results
    (operator_modeling/ntt/hybrid/measured_rows.json: NTT core alone, out of context, V80, 350 MHz).
    One line per row: measured, the model, the error; the old estimate (resourcesRough) for comparison.
    Fails on a DSP mismatch, a block RAM / UltraRAM difference above one block, a cycle count that differs from
    the simulated one, or a LUT / FF / area-unit error above ACC_LIMIT."""
    import json
    with open(path or ACCURACY_ROWS, encoding='utf-8') as fh:
        rows = json.load(fh)['rows']
    t0 = time.time()
    print('gate H3 hybrid model accuracy (measured: routed core alone, 350 MHz; errors: model / measured - 1)')
    print(f"  {'row':<30} {'set':<4} {'LUT meas':>8} {'model':>7} {'err%':>6} {'old%':>6} | {'FF meas':>8} {'model':>7} "
          f"{'err%':>6} {'old%':>6} | {'DSP':>9} {'BRAM36':>11} {'URAM':>5} | {'area':>6} {'model':>6} {'err%':>6} "
          f"{'old%':>6} | {'interval':>8} {'latency':>7}")
    stat = {}
    fails = 0
    for row in rows:
        if only and row['name'] not in only:
            continue
        m = row['measured']
        s = quiet(lambda: _accScheme(row))
        r = quiet(lambda: s.resources())
        o = quiet(lambda: s.resourcesRough())
        e = {k: 100 * (r[k] / m[k] - 1) for k in ('lut', 'ff')}
        eo = {k: 100 * (o[k] / m[k] - 1) for k in ('lut', 'ff')}
        e['area'], eo['area'] = 100 * (_au(r) / _au(m) - 1), 100 * (_au(o) / _au(m) - 1)
        iv, lat = s.cyclesPerPolynomial(), s.latency()
        sim = row.get('sim') or {}
        tok = all(sim.get(k) in (None, v) for k, v in (('interval', iv), ('latency', lat)))
        if sim.get('last_out') is not None and not sim.get('record'):
            # the testbench's last output cycle: (polynomials - 1) intervals, then one latency
            eq = sim['first_in'] + (sim['polys'] - 1) * iv + lat - 1 == sim['last_out']
            if not eq:
                # outputs not evenly spaced (narrow ports with S >= 2 alternate two gaps whose mean is the interval):
                # compare the cycle-accurate job model of the same number of polynomials instead
                job = s.simulatePortsJob if s.portsOn() else s.simulateIoJob if s.io != s.W else s.simulateJob
                j = quiet(lambda: job(sim['polys']))
                eq = sim['first_in'] + max(max(o) for o in j['out']) == sim['last_out']
            tok = tok and eq and sim.get('pass', True)
        bad = [k for k in ('lut', 'ff', 'area') if abs(e[k]) > ACC_LIMIT[k]]
        if r['dsp'] != m['dsp']:
            bad.append('dsp')
        if abs(r['bram'] - m['bram']) > 1:
            bad.append('bram')
        if abs(r['uram'] - m.get('uram', 0)) > 1:
            bad.append('uram')
        if not tok:
            bad.append('cycles')
        fails += bool(bad)
        grp = 'held' if row.get('heldout') else 'fit'
        for k in ('lut', 'ff', 'area'):
            stat.setdefault((grp, k), []).append((abs(e[k]), abs(eo[k])))
        simtxt = (f"{iv:>8} {lat:>7}" + ('' if sim.get('interval') is None else ' =sim' if tok else
                                         f" SIM {sim.get('interval')} {sim.get('latency')} {sim.get('last_out')}"))
        print(f"  {row['name'][:30]:<30} {grp:<4} {m['lut']:>8} {r['lut']:>7} {e['lut']:>+6.1f} {eo['lut']:>+6.1f} | "
              f"{m['ff']:>8} {r['ff']:>7} {e['ff']:>+6.1f} {eo['ff']:>+6.1f} | {m['dsp']:>4}/{r['dsp']:<4} "
              f"{m['bram']:>5}/{r['bram']:<5} {m.get('uram', 0)}/{r['uram']} | {_au(m):>6.1f} {_au(r):>6.1f} "
              f"{e['area']:>+6.1f} {eo['area']:>+6.1f} | {simtxt}" + (f"   <-- {', '.join(bad)}" if bad else ''))
        if parts:
            for k, v in r['breakdown'].items():
                if k != 'sums':
                    print(f"      {k:<56} LUT {v[0]:>7} FF {v[1]:>7} DSP {v[2]:>4} BRAM {v[3]:>5} URAM {v[4]}")
    for grp in ('fit', 'held'):
        if (grp, 'lut') in stat:
            n_ = len(stat[(grp, 'lut')])
            print(f"  {grp} rows ({n_}): " + '; '.join(
                f"{k} max {max(x[0] for x in stat[(grp, k)]):.1f} % mean {sum(x[0] for x in stat[(grp, k)]) / n_:.1f} % "
                f"(old max {max(x[1] for x in stat[(grp, k)]):.1f} % mean {sum(x[1] for x in stat[(grp, k)]) / n_:.1f} %)"
                for k in ('lut', 'ff', 'area')))
    print(f'gate H3 hybrid model accuracy: {fails} row(s) outside the limits '
          f"(LUT {ACC_LIMIT['lut']} %, FF {ACC_LIMIT['ff']} %, area {ACC_LIMIT['area']} %, DSP exact, RAM blocks within 1) "
          f'({time.time() - t0:.0f}s)')
    return fails


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rtl', default=None)
    ap.add_argument('--no-sim', action='store_true')
    ap.add_argument('--only', nargs='*')
    ap.add_argument('--quick', action='store_true')
    ap.add_argument('--skip-model', action='store_true')
    ap.add_argument('--behavioural', action='store_true', help='behavioural multipliers in the RTL gate')
    ap.add_argument('--neg', action='store_true', help='the negative tests of the port options (H2_PORT_NEG)')
    ap.add_argument('--accuracy', action='store_true',
                    help='gate H3 only: the area / timing model against the stored place-and-route results')
    ap.add_argument('--parts', action='store_true', help='with --accuracy: the model line by line')
    a = ap.parse_args()
    if a.accuracy:
        sys.exit(1 if accuracy(only=a.only, parts=a.parts) else 0)
    f = 0
    if not a.skip_model:
        f += gate1(a.quick)
    if a.rtl:
        f += gate2(a.rtl, not a.no_sim, a.only, behavioural=a.behavioural, points=H2_PORT_NEG if a.neg else None)
    sys.exit(1 if f else 0)


if __name__ == '__main__':
    main()
