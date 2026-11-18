'''Gate 3 of the multi-step NTT: RTL generated and simulated (xsim) at small N, polynomials back to back and
with gaps, modulus (MIDX) and direction (DIR) per polynomial, every output beat checked at its exact
cycle (a slower pipeline fails).

    python runMultiStepRtl.py DIR [--only a,b] [--jobs 8] [--polys 6]
'''
from __future__ import annotations

import argparse
import concurrent.futures as cf
import os
import random
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

RTL_POINTS = ['n64_8x8_p8', 'n64_8x8_p8_cyc', 'n64_4x4x4_p4', 'n64_4x4x4_p8_bank', 'n256_16x16_p16',
              'n256_16x16_p16_bank', 'n256_4x16x4_p16', 'n256_8x4x8_p8_fwd', 'n256_8x4x8_p8_inv',
              'n256_4x4x4x4_p4', 'n1024_8x8x16_p16', 'n1024_32x32_p32', 'n1024_16x4x16_p16',
              'n4096_16x16x16_p16', 'n4096_8x8x8x8_p8_bank',
              'n256_16x16_p16_wlm', 'n1024_32x32_p32_wlm60', 'n1024_8x16x8_p16_wlm60',
              'n4096_16x16x16_p16_pass', 'n1024_4x16x16_p16_pass', 'n256_16x16_p16_d60',
              'n1024_8x16x8_p16_wlm60_d60', 'n256_16x16_p16_fold', 'n1024_8x8x16_p16_fold',
              'n256_8x4x8_p8_fold_fwd', 'n256_16x16_p16_fold_cyc', 'n256_16x16_p16_fold_wlm',
              'n256_16x16_p16_tree', 'n1024_8x8x16_p16_tree', 'n256_8x4x8_p8_fwd_tree', 'n1024_32x32_p32_wlm60_tree',
              'n256_16x16_p16_fold_d60', 'n256_16x16_p16_tree_d80', 'n1024_32x32_p32_wlm60_tree_d60',
              'n256_16x16_p16_fold_wlm_d80', 'n256_16x16_p16_load', 'n1024_8x16x8_p16_load60',
              'n256_16x16_p16_foldload', 'n1024_32x32_p32_foldload60',
              'n256_16x16_p16_gs', 'n256_4x16x4_p16_gs_cyc', 'n1024_32x4x8_p32_gs_pass', 'n256_16x16_p16_gsload',
              'n1024_8x16x8_p16_gsload60_d60',
              # folded_gs inverse only (the GS half alone, no twist multiplier), 2026-11-16
              'n64_8x8_p8_gsi', 'n256_16x16_p16_gsi', 'n1024_8x8x16_p16_gsi', 'n256_4x4x4x4_p4_gsi',
              'n1024_32x4x8_p32_gsi_pass', 'n256_16x16_p16_gsi_wlm', 'n256_4x16x4_p16_gsi_cyc',
              'n256_16x16_p16_gsiload']


def one(name: str, root: str, polys: int) -> str:
    from runMultiStep import build, MODEL_POINTS, quiet
    from operator_modeling.ntt.multistep.MultiStepNTT import MultiStepNTT, simulate
    t0 = time.time()
    pt = next(p for p in MODEL_POINTS if p[0] == name)
    s, qs = build(pt)
    rng = random.Random(len(name))
    dirs = [rng.choice(s.dirs) for _ in range(polys)]
    qq = [rng.choice(qs) for _ in range(polys)]
    if '_gsi' in name:                          # the new rows: another modulus on every polynomial
        qq = [qs[i % len(qs)] for i in range(polys)]
    if getattr(s, 'loadable', False):           # jobs of one modulus: half the polynomials on each prime, reload between
        qq = [qs[0]] * (polys // 2) + [qs[1]] * (polys - polys // 2)
        # direction per job: job 1 q0 forward, then q1 inverse, then (same q1) forward: a reload and a DIR change
        h = polys // 2
        dirs = (['fwd'] * h + ['inv'] * (polys - h - 1) + ['fwd']) if 'inv' in s.dirs and 'fwd' in s.dirs else dirs
    xs = [[rng.randrange(q) for _ in range(s.N)] for q in qq]
    gaps = [rng.choice([0, 0, 0, 1, 5]) for _ in range(polys)]
    run = os.path.join(root, name)
    op = MultiStepNTT(s)
    m = quiet(lambda: op.emitRtl(f'ms_{name}', run, xs, dirs, qq, gaps))
    tg = time.time() - t0
    v, out = simulate(run, f'ms_{name}')
    rate = next((l for l in out.splitlines() if 'fed' in l), '')
    if getattr(s, 'loadable', False):
        rate += '  job switches (words loaded, drain, total cycles): ' + ', '.join(
            f"{r['words']}/{r['drain']}/{r['cycles']}" for r in op.reloads)
    return (f"  {name:<24} latency {m['latency']:5d}  {polys} polys {''.join(d[0] for d in dirs)} gaps {gaps} "
            f"moduli {[qs.index(q) for q in qq]}: xsim {v}  (gen {tg:.0f}s, sim {time.time() - t0 - tg:.0f}s)\n"
            f"      {rate.strip()}")


def gate3(root, sim=True, only=None, jobs=8, polys=6) -> int:
    root = root or 'work/fourstep/ms/gate3'
    os.makedirs(root, exist_ok=True)
    pts = [p for p in RTL_POINTS if not only or p in only.split(',')]
    fails = 0
    with cf.ProcessPoolExecutor(jobs) as ex:
        futs = {ex.submit(one, p, root, polys): p for p in pts}
        for f in cf.as_completed(futs):
            try:
                line = f.result()
            except Exception as e:  # noqa: BLE001
                line = f'  {futs[f]:<24} ERROR {type(e).__name__}: {e}'
            fails += 'xsim PASS' not in line
            print(line, flush=True)
    print(f'gate 3 rtl: {len(pts) - fails} of {len(pts)} pass')
    return fails


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('root', nargs='?', default=None)
    ap.add_argument('--only', default=None)
    ap.add_argument('--jobs', type=int, default=8)
    ap.add_argument('--polys', type=int, default=6)
    a = ap.parse_args()
    sys.exit(1 if gate3(a.root, True, a.only, a.jobs, a.polys) else 0)
