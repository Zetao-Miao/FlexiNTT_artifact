'''Gates of the multi-step NTT (operator_modeling/ntt/multistep/MultiStepScheme.py, MultiStepNTT.py).

    python runMultiStep.py [--gate 1,2,3,...] [--rtl DIR] [--sim] [--quick]

gate 1  model vs reference: every factorisation (d = 2, 3, 4), cyclic / negacyclic, forward / inverse /
        both (direction and modulus per polynomial, mixed), twists merged / bank, twiddles rom / otf;
        the O(N log N) reference itself against the O(N^2) definition at small N
gate 2  the lane-time transpose twin (lt_transpose_model.LtBmbTranspose) against the permutation the
        model applies, for every transpose of every plan, with gaps between polynomials, at its latency
gate 3  RTL (with --rtl DIR): generate and (with --sim) xsim at small N with modulus per polynomial and
        NTT / INTT mixed, every output beat checked for its value at its exact cycle (rate check)
'''
from __future__ import annotations

import argparse
import contextlib
import io
import os
import random
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from operator_modeling.ntt.multistep.MultiStepScheme import (MultiStepPlan, MultiStepScheme, referenceDirect,
                                                         referenceFast, rootFor)
from operator_modeling.modmult.primes import nttFriendlyPrime


def quiet(fn):
    with contextlib.redirect_stdout(io.StringIO()):
        return fn()


def primes(bits, logOrder, k, seed0=0):
    out, s = [], seed0
    while len(out) < k:
        q = nttFriendlyPrime(bits, logOrder + 1, seed=s)
        if q not in out:
            out.append(q)
        s += 1
    return out


# (name, N, sizes, P, bits, M moduli, negacyclic, direction, twists, twiddleSource)
MODEL_POINTS = [
    ('n64_8x8_p8', 64, [8, 8], 8, 30, 2, True, 'both', 'merged', 'rom'),
    ('n64_8x8_p8_cyc', 64, [8, 8], 8, 30, 2, False, 'both', 'merged', 'rom'),
    ('n64_4x4x4_p4', 64, [4, 4, 4], 4, 30, 2, True, 'both', 'merged', 'otf'),
    ('n64_4x4x4_p8_bank', 64, [4, 4, 4], 8, 30, 3, True, 'both', 'bank', 'rom'),
    ('n256_16x16_p16', 256, [16, 16], 16, 30, 2, True, 'both', 'merged', 'auto'),
    ('n256_16x16_p16_bank', 256, [16, 16], 16, 30, 2, True, 'both', 'bank', 'otf'),
    ('n256_4x16x4_p16', 256, [4, 16, 4], 16, 30, 2, True, 'both', 'merged', 'otf'),
    ('n256_8x4x8_p8_fwd', 256, [8, 4, 8], 8, 30, 1, True, 'forward', 'merged', 'rom'),
    ('n256_8x4x8_p8_inv', 256, [8, 4, 8], 8, 30, 1, True, 'inverse', 'merged', 'otf'),
    ('n256_4x4x4x4_p4', 256, [4, 4, 4, 4], 4, 30, 2, True, 'both', 'merged', 'otf'),
    ('n256_4x4x4x4_p16_cyc', 256, [4, 4, 4, 4], 16, 30, 2, False, 'both', 'merged', 'rom'),
    ('n1024_32x32_p32', 1024, [32, 32], 32, 30, 2, True, 'both', 'merged', 'auto'),
    ('n1024_8x8x16_p16', 1024, [8, 8, 16], 16, 30, 2, True, 'both', 'merged', 'otf'),
    ('n1024_16x4x16_p16', 1024, [16, 4, 16], 16, 62, 2, True, 'both', 'merged', 'otf'),
    ('n4096_16x16x16_p16', 4096, [16, 16, 16], 16, 60, 2, True, 'both', 'merged', 'auto'),
    ('n4096_64x64_p64', 4096, [64, 64], 64, 60, 2, True, 'both', 'merged', 'auto'),
    ('n4096_8x8x8x8_p8_bank', 4096, [8, 8, 8, 8], 8, 32, 2, True, 'both', 'bank', 'otf'),
    # word-level Montgomery over friendly primes (Montgomery domain tables), TP-NTT's kind of restricted prime
    ('n256_16x16_p16_wlm', 256, [16, 16], 16, 62, 2, True, 'both', 'merged', 'otf',
     dict(red='wlm', family=(17, 45))),
    ('n1024_32x32_p32_wlm60', 1024, [32, 32], 32, 60, 3, True, 'both', 'merged', 'auto',
     dict(red='wlm', family=(32, 28))),
    ('n1024_8x16x8_p16_wlm60', 1024, [8, 16, 8], 16, 60, 2, True, 'both', 'merged', 'otf',
     dict(red='wlm', family=(32, 28))),
    # input layout in pass order (output in block layout for equal sizes)
    ('n4096_16x16x16_p16_pass', 4096, [16, 16, 16], 16, 30, 2, True, 'both', 'merged', 'auto', dict(layout='pass')),
    ('n1024_4x16x16_p16_pass', 1024, [4, 16, 16], 16, 30, 2, False, 'both', 'merged', 'otf', dict(layout='pass')),
    # one DSP budget over every multiplier (60 %: LUT multipliers where the split puts budget 0)
    ('n256_16x16_p16_d60', 256, [16, 16], 16, 30, 2, True, 'both', 'merged', 'otf', dict(dsp=0.6)),
    ('n1024_8x16x8_p16_wlm60_d60', 1024, [8, 16, 8], 16, 60, 2, True, 'both', 'merged', 'otf',
     dict(red='wlm', family=(32, 28), dsp=0.6)),
    # TP-NTT's folded form: stage twiddles per beat from tables, no inter-pass multiplier
    ('n256_16x16_p16_fold', 256, [16, 16], 16, 30, 2, True, 'both', 'merged', 'rom', dict(form='folded')),
    ('n1024_8x8x16_p16_fold', 1024, [8, 8, 16], 16, 30, 2, True, 'both', 'merged', 'otf', dict(form='folded')),
    ('n256_8x4x8_p8_fold_fwd', 256, [8, 4, 8], 8, 30, 2, True, 'forward', 'merged', 'rom', dict(form='folded')),
    ('n256_16x16_p16_fold_cyc', 256, [16, 16], 16, 30, 2, False, 'both', 'merged', 'rom', dict(form='folded')),
    ('n256_16x16_p16_fold_wlm', 256, [16, 16], 16, 62, 2, True, 'both', 'merged', 'otf',
     dict(red='wlm', family=(17, 45), form='folded')),
    # LIT's power tree: per lane group Y * Z^j, Z two-level, log2(s) multiplier levels
    ('n256_16x16_p16_tree', 256, [16, 16], 16, 30, 2, True, 'both', 'merged', 'tree'),
    ('n1024_8x8x16_p16_tree', 1024, [8, 8, 16], 16, 30, 2, True, 'both', 'merged', 'tree'),
    ('n256_8x4x8_p8_fwd_tree', 256, [8, 4, 8], 8, 30, 1, True, 'forward', 'merged', 'tree'),
    ('n1024_32x32_p32_wlm60_tree', 1024, [32, 32], 32, 60, 2, True, 'both', 'merged', 'tree',
     dict(red='wlm', family=(32, 28))),
    # DSP split with the folded form and the tree supply (the paths form='auto' + dspFraction builds)
    ('n256_16x16_p16_fold_d60', 256, [16, 16], 16, 30, 2, True, 'both', 'merged', 'rom', dict(form='folded', dsp=0.6)),
    ('n256_16x16_p16_tree_d80', 256, [16, 16], 16, 30, 2, True, 'both', 'merged', 'tree', dict(dsp=0.8)),
    ('n1024_32x32_p32_wlm60_tree_d60', 1024, [32, 32], 32, 60, 2, True, 'both', 'merged', 'tree',
     dict(red='wlm', family=(32, 28), dsp=0.6)),
    ('n256_16x16_p16_fold_wlm_d80', 256, [16, 16], 16, 62, 2, True, 'both', 'merged', 'otf',
     dict(red='wlm', family=(17, 45), form='folded', dsp=0.8)),
    # loadable (TP-NTT-matched): one run-time modulus per job, every twiddle table a RAM loaded per job
    ('n256_16x16_p16_load', 256, [16, 16], 16, 62, 2, True, 'both', 'merged', 'otf',
     dict(red='wlm', family=(17, 45), loadable=True)),
    ('n1024_8x16x8_p16_load60', 1024, [8, 16, 8], 16, 60, 2, True, 'both', 'merged', 'tree',
     dict(red='wlm', family=(32, 28), loadable=True)),
    # loadable folded form (TP-NTT's arrangement): port tables and the inverse output stage as RAMs
    ('n256_16x16_p16_foldload', 256, [16, 16], 16, 62, 2, True, 'both', 'merged', 'rom',
     dict(red='wlm', family=(17, 45), loadable=True, form='folded')),
    ('n1024_32x32_p32_foldload60', 1024, [32, 32], 32, 60, 2, True, 'both', 'merged', 'rom',
     dict(red='wlm', family=(32, 28), loadable=True, form='folded')),
    # folded_gs (TP-NTT's inverse too): unified CT/GS sub-NTTs with port twiddles in every pass, the inverse GS on
    # the same passes with the output twists merged: no inter-pass multiplier, no output stage; any sizes
    ('n256_16x16_p16_gs', 256, [16, 16], 16, 30, 2, True, 'both', 'merged', 'rom', dict(form='folded_gs')),
    ('n1024_8x8x16_p16_gs', 1024, [8, 8, 16], 16, 30, 2, True, 'both', 'merged', 'rom', dict(form='folded_gs')),
    ('n256_4x16x4_p16_gs_cyc', 256, [4, 16, 4], 16, 30, 2, False, 'both', 'merged', 'rom', dict(form='folded_gs')),
    ('n256_4x4x4x4_p4_gs', 256, [4, 4, 4, 4], 4, 30, 2, True, 'both', 'merged', 'rom', dict(form='folded_gs')),
    ('n1024_32x4x8_p32_gs_pass', 1024, [32, 4, 8], 32, 30, 2, True, 'both', 'merged', 'rom',
     dict(form='folded_gs', layout='pass')),
    ('n256_16x16_p16_gsload', 256, [16, 16], 16, 62, 2, True, 'both', 'merged', 'rom',
     dict(red='wlm', family=(17, 45), loadable=True, form='folded_gs')),
    ('n1024_8x16x8_p16_gsload60_d60', 1024, [8, 16, 8], 16, 60, 2, True, 'both', 'merged', 'rom',
     dict(red='wlm', family=(32, 28), loadable=True, form='folded_gs', dsp=0.6)),
    ('n4096_32x4x32_p32_gsload60', 4096, [32, 4, 32], 32, 60, 2, True, 'both', 'merged', 'rom',
     dict(red='wlm', family=(32, 28), loadable=True, form='folded_gs')),
    # folded_gs, inverse only (2026-11-16): the Gentleman-Sande half alone, plain GS sub-NTTs with port twiddles, psi^-k
    # in the butterflies and N^-1 in the halvers: no twist multiplier anywhere
    ('n64_8x8_p8_gsi', 64, [8, 8], 8, 30, 3, True, 'inverse', 'merged', 'rom', dict(form='folded_gs')),
    ('n256_16x16_p16_gsi', 256, [16, 16], 16, 30, 3, True, 'inverse', 'merged', 'rom', dict(form='folded_gs')),
    ('n1024_8x8x16_p16_gsi', 1024, [8, 8, 16], 16, 30, 3, True, 'inverse', 'merged', 'rom', dict(form='folded_gs')),
    ('n256_4x4x4x4_p4_gsi', 256, [4, 4, 4, 4], 4, 30, 3, True, 'inverse', 'merged', 'rom', dict(form='folded_gs')),
    ('n1024_32x4x8_p32_gsi_pass', 1024, [32, 4, 8], 32, 30, 3, True, 'inverse', 'merged', 'rom',
     dict(form='folded_gs', layout='pass')),
    ('n256_16x16_p16_gsi_wlm', 256, [16, 16], 16, 62, 3, True, 'inverse', 'merged', 'rom',
     dict(red='wlm', family=(17, 45), form='folded_gs')),
    ('n256_4x16x4_p16_gsi_cyc', 256, [4, 16, 4], 16, 30, 3, False, 'inverse', 'merged', 'rom', dict(form='folded_gs')),
    ('n256_16x16_p16_gsiload', 256, [16, 16], 16, 62, 2, True, 'inverse', 'merged', 'rom',
     dict(red='wlm', family=(17, 45), loadable=True, form='folded_gs')),
]


def butterflyOf(red: str) -> dict:
    import runModularNTT as rm
    if red == 'shoup':                      # Shoup: no reduction class (2026-11-14: reduction=None was refused)
        return dict(multiplierKind='shoup')
    cls = rm.REDUCTIONS.get(red.split('-')[0])
    return dict(multiplierKind='shoup' if red == 'shoup' else 'reduction', reduction=cls,
                reductionArgs=(rm.UNITS.get(red, ({},))[0] or {}))


def build(pt, **kw):
    name, N, sizes, P, bits, M, nwc, d, tw, src = pt[:10]
    ex = dict(pt[10]) if len(pt) > 10 else {}
    order = 2 * N if nwc else N
    if 'family' in ex:
        import runModularNTT as rm
        from operator_modeling.modmult.ModulusFamily import ModulusFamily as MF
        v, h = ex['family']
        qs = rm.friendlyPrimes(v, h, order, M)
        kw.setdefault('family', MF.friendly(v, h))
    else:
        qs = primes(bits, order.bit_length() - 1, M, seed0=bits)
    if 'red' in ex:
        kw.setdefault('butterfly', butterflyOf(ex['red']))
    if 'layout' in ex:
        kw.setdefault('inputLayout', ex['layout'])
    if 'form' in ex:
        kw.setdefault('form', ex['form'])
    if ex.get('loadable'):
        kw.setdefault('loadable', True)
    s = quiet(lambda: MultiStepScheme(name, N, sizes, P, moduli=qs, negacyclic=nwc, direction=d, twists=tw,
                                      twiddleSource=src, **kw))
    if 'dsp' in ex:
        quiet(lambda: s.setDspBudget(fraction=ex['dsp']))
    return s, qs


def gate1(quick=False) -> int:
    fails = 0
    # the reference itself
    for N, nwc in ((16, True), (32, False), (64, True)):
        q = primes(30, (2 * N if nwc else N).bit_length() - 1, 1)[0]
        r = rootFor(q, 2 * N if nwc else N)
        rng = random.Random(N)
        for d in ('fwd', 'inv'):
            x = [rng.randrange(q) for _ in range(N)]
            ok = referenceFast(x, q, r, nwc, d) == referenceDirect(x, q, r, nwc, d)
            y = referenceFast(referenceFast(x, q, r, nwc, 'fwd'), q, r, nwc, 'inv')
            ok = ok and y == x
            fails += not ok
            print(f"  reference N={N} {'nega' if nwc else 'cyc'} {d}: fast == direct, inverse(forward) == x: {ok}")
    pts = MODEL_POINTS[:8] if quick else MODEL_POINTS
    for pt in pts:
        t0 = time.time()
        s, qs = build(pt)
        rng = random.Random(len(pt[0]))
        T = 6
        dirs = [rng.choice(s.dirs) for _ in range(T)]
        qq = [rng.choice(qs) for _ in range(T)]
        xs = [[rng.randrange(q) for _ in range(s.N)] for q in qq]
        ys = quiet(lambda: s.transformNatural(xs, dirs, qq))
        bad = sum(y != s.reference(x, d, q) for x, y, d, q in zip(xs, ys, dirs, qq))
        if s.N <= 256:
            bad += sum(y != s.reference(x, d, q, fast=False) for x, y, d, q in zip(xs[:2], ys[:2], dirs[:2], qq[:2]))
        fails += bad > 0
        lat = quiet(s.latency)
        srcs = ','.join(st['source'] for t, st in sorted(s.stages.items()))
        print(f"  {pt[0]:<26} d={s.d} out=in layout {str(s.plan.outputIsBlock()):<5} twiddles [{srcs}] latency "
              f"{lat:4d}  {T} polys {''.join(d[0] for d in dirs)} over {len(qs)} moduli: "
              f"{'PASS' if not bad else f'FAIL ({bad})'}  ({time.time() - t0:.1f}s)")
    print(f'gate 1 model: {"PASS" if not fails else f"{fails} FAIL"}')
    return fails


def gate2() -> int:
    import operator_modeling.transpose.MatrixTransposeScheme  # noqa: F401
    from lt_transpose_model import LtBmbTranspose
    fails = 0
    plans = [MultiStepPlan(N, sz, P) for _, N, sz, P, *_ in MODEL_POINTS]
    plans.append(MultiStepPlan(2 ** 12, [4, 32, 32], 32))
    seen = set()
    for plan in plans:
        for st in plan.transposes():
            key = (plan.N, plan.P, st['s'], st['timeLo'], tuple(st['laneBits']))
            if key in seen:
                continue
            seen.add(key)
            S, lo = 1 << st['s'], st['timeLo']
            F = plan.F
            # one group: frames of F beats, S lanes; the group's lane u = lane bits laneBits
            rng = random.Random(S * 7 + lo)
            frames = [[[rng.randrange(1 << 20) for _ in range(S)] for _ in range(F)] for _ in range(4)]
            sched = []
            for i, fr in enumerate(frames):
                sched += fr
                sched += [None] * ([0, 3, 0, 1][i])
            sched += [None] * (F + 4 * S + S * (1 << lo) + 20)
            tw = LtBmbTranspose(S, lo, None)
            outs = []
            for c, row in enumerate(sched):
                o, v = tw.tick(row)
                if v:
                    outs.append((c, o))
            exp = []
            starts = []
            c = 0
            for i, fr in enumerate(frames):
                starts.append(c)
                nf = [[None] * S for _ in range(F)]
                for tau in range(F):
                    r = (tau >> lo) & (S - 1)
                    for u in range(S):
                        tau2 = (tau & ~((S - 1) << lo)) | (u << lo)
                        nf[tau2][r] = fr[tau][u]
                for tau in range(F):
                    exp.append((starts[-1] + tau + tw.latency, nf[tau]))
                c += F + [0, 3, 0, 1][i]
            ok = outs == exp
            fails += not ok
            print(f"  lt transpose S={S:3d} lo={lo:2d} window {S << lo:5d} (F={F}): latency {tw.latency}, "
                  f"4 polys with gaps, every beat at its cycle: {'PASS' if ok else 'FAIL'}")
    print(f'gate 2 transposes: {"PASS" if not fails else f"{fails} FAIL"}')
    return fails


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--gate', default='1,2')
    ap.add_argument('--quick', action='store_true')
    ap.add_argument('--rtl', default=None)
    ap.add_argument('--sim', action='store_true')
    ap.add_argument('--only', default=None)
    a = ap.parse_args()
    gates = [int(g) for g in a.gate.split(',')]
    f = 0
    if 1 in gates:
        f += gate1(a.quick)
    if 2 in gates:
        f += gate2()
    if 3 in gates:
        from runMultiStepRtl import gate3
        f += gate3(a.rtl, a.sim, a.only)
    print('ALL PASS' if not f else f'{f} FAIL')
    sys.exit(1 if f else 0)


if __name__ == '__main__':
    main()
