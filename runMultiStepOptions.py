"""runMultiStepOptions.py: gate of the multi-step NTT options added on 2026-11-14.

  ramLatency (3, 4)          cycles from a table address to its word (default 2)
  crossRegs / crossAt        register stages between the blocks of the pipeline (SLR crossings)
  outputOrder                'natural' (beat c, lane l = coefficient c x P + l) or 'block' (c + F x l)
  tableSupply='stream'       the twiddle tables outside the core, fixed latency (ports tw_addr_<k> / tw_data_<k>)
  outReady                   in_ready / out_ready, whole polynomials buffered behind the pipeline
  Shoup multiplier and the unified butterfly in the twist forms (present before, never in a gate)

Each point: generate, xsim with real multipliers, random polynomials with the modulus and the direction changing per
polynomial, every output beat checked for value and cycle (a slower design fails).  Negative tests (must FAIL):
  late    the expectation one cycle early (the design one cycle slower than the model)
  src     stream supply: the outside tables one cycle late (testbench parameter SRC_EXTRA=1)
  depth   outReady: the RTL built with half the FIFO depth of the twin (in_ready differs)
Rate: outReady with out_ready high and polynomials back to back must take one polynomial every F cycles.

    python runMultiStepOptions.py DIR [--only a,b] [--jobs 8] [--model]     (--model: no xsim, model checks only)
"""
from __future__ import annotations
import argparse, concurrent.futures as cf, os, random, sys, time

SHOUP = dict(butterfly=dict(multiplierKind='shoup'))
UNI = dict(subArgs=dict(unified=True))
# (name, base point of runMultiStep.MODEL_POINTS, options, test mode, negative test)
POINTS = [
    ('ram3_n256', 'n256_16x16_p16', dict(ramLatency=3), 'std', 'late'),
    ('ram4_n1024_fold', 'n1024_8x8x16_p16_fold', dict(ramLatency=4), 'std', None),
    ('ram3_n256_gs', 'n256_16x16_p16_gs', dict(ramLatency=3), 'std', None),
    ('ram3_n256_load', 'n256_16x16_p16_load', dict(ramLatency=3), 'std', None),
    ('ram3_n256_tree', 'n256_16x16_p16_tree', dict(ramLatency=3), 'std', None),
    ('ram4_n256_bank', 'n256_16x16_p16_bank', dict(ramLatency=4), 'std', None),
    ('cross2_n256', 'n256_4x16x4_p16', dict(crossRegs=2), 'std', 'late'),
    ('crossmid_n1024', 'n1024_8x8x16_p16', dict(crossRegs=1, crossAt='mid'), 'std', None),
    ('cross1_n256_fold', 'n256_16x16_p16_fold', dict(crossRegs=1), 'std', None),
    ('nat_n256', 'n256_16x16_p16', dict(outputOrder='natural'), 'std', 'late'),
    ('nat_n1024', 'n1024_8x8x16_p16', dict(outputOrder='natural'), 'std', None),
    ('nat_n1024_fold', 'n1024_8x8x16_p16_fold', dict(outputOrder='natural'), 'std', None),
    ('nat_n256_4x', 'n256_4x4x4x4_p4', dict(outputOrder='natural'), 'std', None),
    ('blk_n64_cyc', 'n64_8x8_p8_cyc', dict(outputOrder='block'), 'std', None),
    ('blk_n256_bank', 'n256_16x16_p16_bank', dict(outputOrder='block'), 'std', None),
    ('strm_n256', 'n256_16x16_p16', dict(tableSupply='stream'), 'std', 'src'),
    ('strm_n1024_fold', 'n1024_8x8x16_p16_fold', dict(tableSupply='stream'), 'std', 'src'),
    ('strm_n256_gs', 'n256_16x16_p16_gs', dict(tableSupply='stream', ramLatency=3), 'std', 'src'),
    ('strm_n256_fwd', 'n256_8x4x8_p8_fwd', dict(tableSupply='stream'), 'std', None),
    ('rdy_n256', 'n256_16x16_p16', dict(outReady=True), 'rate', None),
    ('rdy_n256_stall', 'n256_16x16_p16', dict(outReady=True), 'stall', 'depth'),
    ('rdy_n1024_stall', 'n1024_8x8x16_p16', dict(outReady=True), 'stall', None),
    ('rdy_n256_small', 'n256_16x16_p16_fold', dict(outReady=True, outFifoDepth=32), 'rand', None),
    ('rdy_n1024_rate', 'n1024_8x8x16_p16_fold', dict(outReady=True), 'rate', None),
    ('shoup_n256', 'n256_16x16_p16', SHOUP, 'std', None),
    ('shoup_n1024', 'n1024_8x8x16_p16', SHOUP, 'std', None),
    ('shoup_n256_bank', 'n256_16x16_p16_bank', SHOUP, 'std', None),
    ('uni_n256', 'n256_16x16_p16', UNI, 'std', None),
    ('uni_n1024', 'n1024_8x8x16_p16', UNI, 'std', None),
    ('all_n256_fold', 'n256_16x16_p16_fold', dict(ramLatency=3, crossRegs=1, outputOrder='natural',
                                                   tableSupply='stream', outReady=True), 'stall', 'src'),
    ('all_n1024', 'n1024_8x8x16_p16', dict(ramLatency=3, crossRegs=1, crossAt='mid', outputOrder='natural',
                                            tableSupply='stream', outReady=True), 'rand', None),
]


def scheme(name):
    from runMultiStep import build, MODEL_POINTS
    _, base, kw, mode, neg = next(p for p in POINTS if p[0] == name)
    pt = next(p for p in MODEL_POINTS if p[0] == base)
    s, qs = build(pt, **kw)
    return s, qs, kw, mode, neg


def modelCheck(s, qs, kw) -> list[str]:
    """Model checks without a simulator: transform against the reference, the output layout, latency arithmetic."""
    from runMultiStep import quiet
    bad = []
    rng = random.Random(7)
    for d in s.dirs:
        q = rng.choice(qs)
        x = [rng.randrange(q) for _ in range(s.N)]
        if quiet(lambda: s.transformNatural([x], [d], [q]))[0] != quiet(lambda: s.reference(x, d, q)):
            bad.append(f'transform {d}')
    oo = kw.get('outputOrder', 'pass')
    if oo == 'natural' and any(s.plan.outputIndex(t, l) != t * s.P + l for t in range(s.F) for l in range(s.P)):
        bad.append('natural layout')
    if oo == 'block' and any(s.plan.outputIndex(t, l) != t + s.F * l for t in range(s.F) for l in range(s.P)):
        bad.append('block layout')
    blocks = quiet(lambda: s.schedule())
    if sum(b['latency'] for b in blocks) != s.coreLatency():
        bad.append('latency sum')
    if s.latency() != s.coreLatency() + (s.OFIFO_LAT if s.outReady else 0):
        bad.append('latency fifo')
    return bad


def one(name: str, root: str, sim: bool = True) -> str:
    from runMultiStep import quiet
    from operator_modeling.ntt.multistep.MultiStepNTT import MultiStepNTT, simulate
    t0 = time.time()
    s, qs, kw, mode, neg = scheme(name)
    bad = modelCheck(s, qs, kw)
    rng = random.Random(len(name))
    polys = 6
    ready = None
    note = ''
    if mode != 'std':
        D, F, Lc = s.outFifoDepth(), s.F, s.coreLatency()
        if mode == 'rate':          # out_ready high, back to back: one polynomial every F cycles, never refused
            gaps = [0] * polys
            ready = []
        elif mode == 'stall':       # a stall long enough to fill the FIFO: in_ready must fall, nothing is lost
            polys = D // F + 4
            gaps = [rng.choice([0, 0, 0, 2]) for _ in range(polys)]
            ready = [1] * (Lc + 10) + [0] * (D + 3 * F) + [rng.choice([0, 1, 1]) for _ in range(40 * F)]
        else:
            polys = 10
            gaps = [rng.choice([0, 0, 0, 1, 5]) for _ in range(polys)]
            ready = [rng.choice([0, 1, 1, 1]) for _ in range(Lc + 60 * F)]
    else:
        gaps = [rng.choice([0, 0, 0, 1, 5]) for _ in range(polys)]
    dirs = [rng.choice(s.dirs) for _ in range(polys)]
    qq = [rng.choice(qs) for _ in range(polys)]
    if getattr(s, 'loadable', False):
        h = polys // 2
        qq = [qs[0]] * h + [qs[1]] * (polys - h)
        dirs = ['fwd'] * h + ['inv'] * (polys - h - 1) + ['fwd']
    xs = [[rng.randrange(q) for _ in range(s.N)] for q in qq]
    run = os.path.join(root, name)
    op = MultiStepNTT(s)
    kwr = dict(ready=ready) if mode != 'std' else {}
    m = quiet(lambda: op.emitRtl(f'mso_{name}', run, xs, dirs, qq, gaps, **kwr))
    if mode != 'std':
        tw = op.twin
        acc = [i for i, r in enumerate(tw) if r['acc']]
        refused = sum(1 for r in tw if r['in_valid'] and not r['in_ready'])
        outs = [i for i, r in enumerate(tw) if r['out'] and r['out_ready']]
        note = f' twin: {len(acc)} beats in, {len(outs)} out, refused cycles {refused}'
        if len(acc) != polys * s.F or len(outs) != polys * s.F:
            bad.append('twin beat count')
        if mode == 'rate':
            if acc != list(range(acc[0], acc[0] + polys * s.F)) or refused:
                bad.append('rate: not one polynomial every F cycles')
            if outs[0] - acc[0] != s.latency() or outs != list(range(outs[0], outs[0] + polys * s.F)):
                bad.append('rate: latency')
            note += f', interval {s.F} cycles, latency {outs[0] - acc[0]}'
        if mode == 'stall' and not refused:
            bad.append('stall: in_ready never fell')
    tg = time.time() - t0
    head = (f"  {name:<18} {s.N} {s.sizes} P{s.P} {kw if len(str(kw)) < 90 else 'all options'} latency {m['latency']} "
            f"{polys} polys {''.join(d[0] for d in dirs)[:12]}:")
    if bad:
        return head + f' MODEL FAIL {bad}'
    if not sim:
        return head + f' model ok{note}'
    v, out = simulate(run, f'mso_{name}')
    rate = next((l for l in out.splitlines() if 'fed' in l), '').strip()
    res = f' xsim {v}'
    ok = v == 'PASS'
    if neg:
        if neg == 'src':
            nv, _ = simulate(run, f'mso_{name}', generics='SRC_EXTRA=1', tag='_neg')
        else:
            nrun = run + '_neg'
            op2 = MultiStepNTT(s)
            if neg == 'depth':
                op2._rtlFifoDepth = s.outFifoDepth() // 2
            quiet(lambda: op2.emitRtl(f'mso_{name}', nrun, xs, dirs, qq, gaps, **kwr))
            if neg == 'late':
                for fn in ('y_out.txt', 'ctl_out.txt'):
                    p = os.path.join(nrun, 'testvectors', fn)
                    lines = open(p).read().splitlines(True)
                    open(p, 'w').write(''.join(lines[1:] + lines[:1]))
            nv, _ = simulate(nrun, f'mso_{name}')
        res += f', negative ({neg}) {nv}' + (' as it must' if nv == 'FAIL' else ' WRONG')
        ok = ok and nv == 'FAIL'
    return (head + res + f"{note}  (gen {tg:.0f}s, total {time.time() - t0:.0f}s) {'OK' if ok else 'NOT OK'}\n"
            f"      {rate}")


def gate(root, only=None, jobs=8, sim=True) -> int:
    root = root or 'work/overnight_2026-11-14/fourstep/gate_options'
    os.makedirs(root, exist_ok=True)
    pts = [p[0] for p in POINTS if not only or p[0] in only.split(',')]
    fails = 0
    with cf.ProcessPoolExecutor(jobs) as ex:
        futs = {ex.submit(one, p, root, sim): p for p in pts}
        for f in cf.as_completed(futs):
            try:
                line = f.result()
            except Exception as e:  # noqa: BLE001
                import traceback
                line = f'  {futs[f]:<18} ERROR {type(e).__name__}: {e}\n' + traceback.format_exc()[-1500:]
            fails += not ((' OK' in line and 'NOT OK' not in line) or (not sim and 'model ok' in line))
            print(line, flush=True)
    print(f'gate options: {len(pts) - fails} of {len(pts)} pass')
    return fails


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('root', nargs='?', default=None)
    ap.add_argument('--only', default=None)
    ap.add_argument('--jobs', type=int, default=8)
    ap.add_argument('--model', action='store_true')
    a = ap.parse_args()
    sys.exit(1 if gate(a.root, a.only, a.jobs, not a.model) else 0)
