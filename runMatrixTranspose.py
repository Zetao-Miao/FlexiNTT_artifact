'''Verify the matrix transpose model against the RTL's own bookkeeping.

Six gates, one script, no test framework -- the transpose counterpart to
`runLutTiming.py`. Run from the project root:

    python runMatrixTranspose.py            # everything (~1 min)
    python runMatrixTranspose.py --quick    # fewer sizes

Gate 1 -- the barrel shifter twin (`transpose_model.BarrelShifter`): every
          shift at N = 2..128 under five register placements (every stage,
          none, the two alternating ones, first-only) rotates by the formula
          `out[b] = in[(b - shift) mod N]`, `latency()` register(s) later;
          the LUT6_2 / LUT3 INIT constants written in `barrel_shift.sv`
          re-derived from the mux truth tables.

Gate 2 -- the transposes stream what compute() batches. Each hardware
          scheme's `reset()` / `step()` under T = 1, 2, 3 matrices, gaps of
          0, 1, 2, N-1, N, N+1, N+2 cycles between bursts, K trials per step,
          off-frame starts, at stage counts 0, 1 and every-stage: output lane
          c at the predicted step equals `compute()`'s slot, `outputValid` is
          high exactly there and low elsewhere, `None` before anything
          arrives; the twin's own count equals `latency()` (plus the alignment
          wait for mbm).

Gate 3 -- the generator builds what the model placed: the emitted REG_FLAGS
          equal the plan's (every stage by default; `place_registers` for a
          count, `transpose_flags_for_fmax` for a target, an unreachable
          target refused naming the floor), the testbench's expected cycles
          are the twin's, and `getOperatorInterface` carries the same latency.

Gate 4 -- resources and timing. The shifter LUTs by construction plus the
          measured control logic per lane, the BRAM tiles by the rule, and
          the priced critical path, against the twelve implemented
          transposes and the shifter at every register count (DEBUG.md
          section 8c): LUTs within 5 %, tiles exact, the path within -0.05
          and +0.25 ns of the measured one; and the placements a target
          picks at N = 128, W = 64.

Gate 5 -- the four-step with a hardware corner turn: `verifyFourStepNtt` at
          n = 8 passes for both schemes, `latency()` and `resources()` sum.

Gate 6 -- emitRtl: files present, `rtl_static_issues` clean on the generated
          top and testbench, the local sanity check passes, and the emitted
          cycle table has one entry per output row of each of the two bursts.
          (That the table is the twin's is gate 3's check, against
          `y_cycle.txt`.)
'''
from __future__ import annotations

import contextlib
import io
import os
import random
import re
import sys
import tempfile
import time

from operator_modeling.core.IntType import IntType
from operator_modeling.core.Resources import Resources
from operator_modeling.core.Signal import Signal
from operator_modeling.transpose.MatrixTranspose import MatrixTranspose
from operator_modeling.transpose.MatrixTransposeScheme import (
    BarrelMemoryBarrelTranspose, BehaviouralMatrixTranspose, MemoryBarrelMemoryTranspose, bramTiles)

import lut_timing as T                                            # noqa: E402
import transpose_model as M                                       # noqa: E402
from rtl_gen.utils import rtl_static_issues                       # noqa: E402

QUICK = '--quick' in sys.argv
SCHEMES = {'bmb': BarrelMemoryBarrelTranspose, 'mbm': MemoryBarrelMemoryTranspose}
HERE = os.path.dirname(os.path.abspath(__file__))


def check(cond: bool, msg: str) -> None:
    if not cond:
        raise AssertionError(msg)


def placements(n: int) -> list[tuple[bool, ...]]:
    s = M.barrel_stages(n)
    out = {tuple([True] * s), tuple([False] * s)}
    if s > 1:
        out.add(tuple(bool(i % 2) for i in range(s)))
        out.add(tuple(bool((i + 1) % 2) for i in range(s)))
        out.add((True,) + (False,) * (s - 1))
    return sorted(out)


# ---------------------------------------------------------------- gate 1
def gate1() -> None:
    print('Gate 1 -- the barrel shifter twin and the LUT INIT constants')
    sizes = [2, 4, 8, 16, 32, 64, 128] if not QUICK else [2, 4, 8, 32]
    runs = 0
    for n in sizes:
        for flags in placements(n):
            bs = M.BarrelShifter(n, flags)
            L = bs.latency
            check(L == sum(flags), f'N={n}: latency {L} for flags {flags}')
            for shift in range(n):
                data = [(shift, b) for b in range(n)]
                outs = [bs.tick(data, shift)]
                for _ in range(L):
                    outs.append(bs.tick([None] * n, 0))
                want = [data[(b - shift) % n] for b in range(n)]
                check(outs[L] == want, f'N={n} flags={flags} shift={shift}: {outs[L][:4]} != {want[:4]}')
                runs += 1
    print(f'  rotation: {runs} (size, placement, shift) cases match the formula')

    # the INIT constants in the RTL, re-derived from the truth tables
    sv = open(os.path.join(HERE, 'versal_arith', 'rtl', 'matrix_transpose', 'barrel_shift.sv'),
              encoding='utf-8').read()
    m = re.search(r"MUX_INIT\s*=\s*64'h([0-9A-Fa-f_]+)", sv)
    check(m is not None, 'MUX_INIT not found in barrel_shift.sv')
    init = int(m.group(1).replace('_', ''), 16)
    want4 = 0
    for a in range(64):
        d = [(a >> k) & 1 for k in range(4)]
        sel = ((a >> 4) & 1) | (((a >> 5) & 1) << 1)
        want4 |= d[sel] << a
    check(init == want4, f'MUX_INIT {init:016X} is not the 4:1 mux table {want4:016X}')
    want2 = 0
    for a in range(32):
        a0, b0, a1, b1, s = [(a >> k) & 1 for k in range(5)]
        want2 |= (b0 if s else a0) << a
        want2 |= (b1 if s else a1) << (32 + a)
    check(init == want2, f'MUX_INIT {init:016X} is not the paired 2:1 mux table {want2:016X}')
    m3 = re.search(r"LUT3\s*#\(\.INIT\(8'h([0-9A-Fa-f]+)\)\)", sv)
    check(m3 is not None, 'the LUT3 INIT not found in barrel_shift.sv')
    init3 = int(m3.group(1), 16)
    want3 = sum(((a >> 1) & 1 if (a >> 2) & 1 else a & 1) << a for a in range(8))
    check(init3 == want3, f'LUT3 INIT {init3:02X} is not the 2:1 mux table {want3:02X}')
    print(f'  INIT constants: LUT6_2 {init:016X} (4:1 and paired 2:1), LUT3 {init3:02X} match the truth tables')


# ---------------------------------------------------------------- gate 2
def make(kind: str, n: int, flags, width: int = 16, k: int = 2):
    scheme = SCHEMES[kind](name=f'{kind}{n}', rows=n, cols=n)
    scheme.stagePlan = lambda flags=flags: tuple(flags)      # pin the placement for the gate
    op = MatrixTranspose(name=f'{kind}{n}_op', scheme=scheme)
    return scheme, op


def gate2() -> None:
    print('\nGate 2 -- the transposes stream what compute() batches')
    sizes = [4, 8, 32, 128] if not QUICK else [4, 8]
    rng = random.Random(7)
    runs = 0
    for kind in SCHEMES:
        for n in sizes:
            pl = placements(n)
            if QUICK:
                pl = pl[:2]
            for flags in pl:
                for Tm in ([1, 2, 3] if n <= 8 else [1, 2]):
                    gaps = [0, 1, 2, n - 1, n, n + 1, n + 2] if n <= 8 else [0, 1, n + 1]
                    for gap in gaps:
                        for pre in ([0, 1, n - 1, n + 3] if n <= 8 else [0, 5]):
                            scheme, op = make(kind, n, flags)
                            K = 2
                            bound = IntType.signed(16)
                            # K independent trials of T matrices each, computed as one
                            # batch of K*T matrices: trial j's row k is slot j*T*n + k
                            lanes = [[rng.randint(-2**15, 2**15 - 1) for _ in range(K * Tm * n)] for _ in range(n)]
                            op.drive([Signal(bound, lanes[r]) for r in range(n)])
                            op.compute()
                            batch_out = [p.signal.values for p in op.outputPorts]
                            op.reset()
                            L = scheme.latency()
                            # stream: pre idle, burst, gap idle, burst again; at step k every
                            # lane carries the K trials' row k
                            def row_at(k):
                                return [[lanes[r][j * Tm * n + k] for j in range(K)] for r in range(n)]
                            sched = [None] * pre + [row_at(k) for k in range(Tm * n)] + [None] * gap + [row_at(k) for k in range(Tm * n)]
                            total = len(sched) + 3 * n + L + 8
                            got = []          # (cycle, lanes) where outputValid
                            for c in range(total):
                                row = sched[c] if c < len(sched) else None
                                op.drive([Signal(bound, row[r] if row is not None else None) for r in range(n)])
                                op.step()
                                outs = [p.signal.values for p in op.outputPorts]
                                if op.outputValid:
                                    got.append((c, outs))
                            check(len(got) == 2 * Tm * n, f'{kind} N={n} flags={flags} T={Tm} gap={gap} pre={pre}: {len(got)} valid rows, expected {2 * Tm * n}')
                            for b in range(2):
                                for k in range(Tm * n):
                                    c, outs = got[b * Tm * n + k]
                                    for cc in range(n):
                                        want = [batch_out[cc][j * Tm * n + k] for j in range(K)]
                                        check(outs[cc] == want, f'{kind} N={n} flags={flags} T={Tm} gap={gap} pre={pre}: burst {b} row {k} lane {cc}: {outs[cc]} != {want}')
                            # timing of the first row
                            first = got[0][0]
                            wait = ((-pre) % n) if kind == 'mbm' else 0
                            check(first == pre + L + wait, f'{kind} N={n} flags={flags} pre={pre}: first row at step {first}, expected {pre + L + wait}')
                            check(all(got[k][0] == first + k for k in range(Tm * n)), f'{kind}: rows of a burst not consecutive')
                            runs += 1
    print(f'  {runs} (scheme, size, placement, T, gap, start) streams match compute() with the twin\'s timing')

    # the closed forms against the twins' own counts
    for kind in SCHEMES:
        for n in [2, 4, 8, 32, 128]:
            for flags in placements(n):
                m = (M.BmbTranspose if kind == 'bmb' else M.MbmTranspose)(n, flags)
                trace = M.run_schedule(m, [[b for b in range(n)] for _ in range(n)], extra_cycles=2 * n + 20)
                vr = M.valid_rows(trace)
                check(vr and vr[0][0] == m.latency, f'{kind} N={n} flags={flags}: twin first row at {vr[0][0] if vr else None}, formula {m.latency}')
    print('  latency closed forms equal the twins\' counts at N = 2..128, every placement')

    # the protocol: a short gap garbles nothing (the defect the original control logic had)
    print('  bmb and mbm accept any gap between bursts, one cycle included (checked above)')


# ---------------------------------------------------------------- gate 3
def gate3() -> None:
    print('\nGate 3 -- the generator builds what the model placed')
    from rtl_gen.transpose import Transpose_RTL_gen
    for kind in SCHEMES:
        for n in ([4, 8, 32] if not QUICK else [4, 8]):
            scheme = SCHEMES[kind](name=f'{kind}{n}', rows=n, cols=n)
            scheme.aIn = [IntType.signed(12)] * n
            spec = scheme.getOperatorInterface(f'{kind}{n}')
            check(spec.regFlags == M.default_flags(n), f'{kind} N={n}: default placement is not every stage')
            check(spec.latency == scheme.latency(), f'{kind} N={n}: spec latency {spec.latency} != {scheme.latency()}')
            with tempfile.TemporaryDirectory() as d:
                cwd = os.getcwd()
                os.chdir(d)
                try:
                    meta = Transpose_RTL_gen(spec, test_size=2, seed=1)
                finally:
                    os.chdir(cwd)
                sv = open(os.path.join(d, 'RTL_generated', f'{spec.name}.sv'), encoding='utf-8').read()
                m = re.search(r"\.REG_FLAGS\s*\(32'h([0-9A-F]+)\)", sv)
                check(m is not None and int(m.group(1), 16) == M.flags_to_reg_flags(spec.regFlags),
                      f'{kind} N={n}: the emitted REG_FLAGS are not the plan\'s')
                check(meta['latency'] == spec.latency, f'{kind} N={n}: meta latency {meta["latency"]}')
                # the twin's cycles are what the testbench reads
                cyc = [int(x, 16) for x in open(os.path.join(d, 'testvectors', 'y_cycle.txt')).read().split()]
                check(cyc == meta['output_cycles'], f'{kind} N={n}: y_cycle.txt differs from the twin')
                check(cyc[0] == meta['burst_starts'][0] + spec.latency + (0 if kind == 'bmb' else (-meta['burst_starts'][0]) % n),
                      f'{kind} N={n}: first expected cycle {cyc[0]}')
    # a count and a target go through lut_timing
    for kind in SCHEMES:
        s = SCHEMES[kind](name='t', rows=8, cols=8, pipelineStages=1)
        flags = s.stagePlan()
        check(sum(flags) == 1 and list(flags) == T.barrel_reg_flags(8, 1), f'{kind}: pipelineStages=1 placement {flags}')
        s2 = SCHEMES[kind](name='t', rows=128, cols=128, targetFmaxMhz=350.0)
        s2.aIn = [IntType.unsigned(64)] * 128
        check(sum(s2.stagePlan()) == 2, f'{kind}: 350 MHz at N=128, W=64 should take two registers, got {s2.stagePlan()}')
        s3 = SCHEMES[kind](name='t', rows=128, cols=128, targetFmaxMhz=400.0)
        s3.aIn = [IntType.unsigned(64)] * 128
        check(sum(s3.stagePlan()) == 4 and s3.latency() == (128 + 2 * 4 + 1 if kind == 'bmb' else 128 + 4 + 3),
              f'{kind}: 400 MHz at N=128, W=64 should take every stage')
        s4 = SCHEMES[kind](name='t', rows=128, cols=128, targetFmaxMhz=1000.0)
        s4.aIn = [IntType.unsigned(64)] * 128
        try:
            s4.stagePlan()
            check(False, 'a 1 GHz target should be refused')
        except ValueError as e:
            check('unreachable' in str(e), f'unexpected refusal: {e}')
    print('  emitted REG_FLAGS, spec latency and y_cycle.txt are the plan\'s and the twin\'s; a count and a '
          'target place through the calibrated table, an unreachable target is refused naming the floor')


# ---------------------------------------------------------------- gate 4
#: Implemented numbers to pin the model to (DEBUG.md section 8c): the DUT's
#: LUTs and BRAM tiles, and the worst register-to-register path inside it,
#: from the V80 run of 15 Sept 2026 at the default placement.
MEASURED: dict[tuple[str, int, int], dict] = {
    ('bmb', 32, 32):  dict(lut=5257,  bram36=0,   bram18=32,  ns=1.655),
    ('bmb', 32, 64):  dict(lut=10438, bram36=32,  bram18=0,   ns=1.745),
    ('bmb', 64, 32):  dict(lut=12603, bram36=0,   bram18=64,  ns=1.663),
    ('bmb', 64, 64):  dict(lut=25078, bram36=64,  bram18=0,   ns=1.824),
    ('bmb', 128, 32): dict(lut=29470, bram36=0,   bram18=128, ns=1.831),
    ('bmb', 128, 64): dict(lut=58210, bram36=128, bram18=0,   ns=2.102),
    ('mbm', 32, 32):  dict(lut=2692,  bram36=0,   bram18=64,  ns=1.682),
    ('mbm', 32, 64):  dict(lut=5318,  bram36=64,  bram18=0,   ns=1.705),
    ('mbm', 64, 32):  dict(lut=6461,  bram36=0,   bram18=128, ns=1.742),
    ('mbm', 64, 64):  dict(lut=12761, bram36=128, bram18=0,   ns=1.739),
    ('mbm', 128, 32): dict(lut=15068, bram36=0,   bram18=256, ns=1.880),
    ('mbm', 128, 64): dict(lut=29397, bram36=256, bram18=0,   ns=2.065),
}
#: The standalone shifter at N = 128, W = 64: LUTs at every register count
#: (by construction, exactly), and the worst path inside it.
MEASURED_SHIFTER = {4: dict(lut=28673, ns=1.604), 3: dict(lut=28672, ns=1.911),
                    2: dict(lut=28672, ns=1.916), 1: dict(lut=28672, ns=2.520)}


def gate4() -> None:
    print('\nGate 4 -- resources and timing')
    for kind in SCHEMES:
        for n in [32, 64, 128]:
            for w in [32, 64]:
                s = SCHEMES[kind](name=f'{kind}{n}', rows=n, cols=n)
                s.aIn = [IntType.unsigned(w)] * n
                r = s.resources()
                shifters = 2 if kind == 'bmb' else 1
                check(r.lut == shifters * M.barrel_luts(n, w) + s.controlLutsPerLane * n, f'{kind} N={n} W={w}: LUTs {r.lut}')
                banks = (n,) if kind == 'bmb' else (2 * n, n)
                want = Resources()
                for depth in banks:
                    t = bramTiles(depth, w)
                    want = want + Resources(bram36=t.bram36 * n, bram18=t.bram18 * n)
                check((r.bram36, r.bram18) == (want.bram36, want.bram18), f'{kind} N={n} W={w}: tiles {r}')
                check(r.dsp == 0, 'a transpose has no DSP')
                m = MEASURED.get((kind, n, w))
                if m:
                    check(abs(r.lut - m['lut']) <= 0.05 * m['lut'], f'{kind} N={n} W={w}: LUT {r.lut} vs measured {m["lut"]}')
                    check((r.bram36, r.bram18) == (m['bram36'], m['bram18']), f'{kind} N={n} W={w}: tiles vs measured')
                    # the fits sit on the conservative side, as the rest of the table does
                    ns = s.criticalPathNs()
                    check(-0.05 <= ns - m['ns'] <= 0.25, f'{kind} N={n} W={w}: path {ns:.3f} vs measured {m["ns"]}')
    # the tile rule at the shapes that matter
    check(bramTiles(128, 64) == Resources(bram36=1), '128 x 64 is one BRAM36')
    check(bramTiles(128, 32) == Resources(bram18=1), '128 x 32 is one BRAM18')
    check(bramTiles(256, 64) == Resources(bram36=1), '256 x 64 is one BRAM36')
    check(bramTiles(256, 36) == Resources(bram18=1), '256 x 36 is one BRAM18')
    check(bramTiles(128, 130) == Resources(bram36=2), '128 x 130 is two BRAM36')
    check(bramTiles(1024, 64) == Resources(bram36=2), '1024 x 64 is two BRAM36')
    # the shifter alone at every register count: LUTs by construction, and the
    # priced segment never shorter than the implemented one
    check(M.barrel_luts(128, 64) == 28672, 'shifter LUTs at N=128, W=64')
    for regs, m in MEASURED_SHIFTER.items():
        ns = T.barrel_segments_ns(128, 64, T.barrel_reg_flags(128, regs))
        check(ns >= m['ns'] - 0.05, f'shifter at {regs} registers: priced {ns:.3f} vs measured {m["ns"]}')
    # the placement the model picks for a target follows from the same table
    check(sum(T.transpose_flags_for_fmax('bmb', 128, 64, 400.0)) == 4, 'bmb128x64 at 400 MHz needs every stage')
    check(sum(T.transpose_flags_for_fmax('bmb', 128, 64, 350.0)) == 2, 'bmb128x64 at 350 MHz takes two registers')
    print(f'  LUTs by construction and BRAM tiles by the rule at N = 32..128, W = 32, 64; '
          f'{len(MEASURED)} implemented transposes pinned (LUT within 5 %, tiles exact, path within -0.05..+0.25 ns); '
          f'the shifter at {len(MEASURED_SHIFTER)} register counts')


# ---------------------------------------------------------------- gate 5
def gate5() -> None:
    print('\nGate 5 -- the four-step with a hardware corner turn')
    from operator_modeling.core.utils import nafTerms
    from operator_modeling.ntt.multistep.FourStepNTT import FourStepNTT
    from operator_modeling.ntt.multistep.FourStepScheme import FourStepScheme
    from operator_modeling.ntt.twiddles import calculateNttTwiddles
    from operator_modeling.ntt.verification import verifyFourStepNtt
    Q = 2**64 - 2**32 + 1
    M, n = 3, 8                                              # N = 64 from two n = 8 parts
    PSI15 = 17776499369601055404                             # 2^15-th primitive root (runFourStep16384.py)
    psi = pow(PSI15, 2**(15 - (2 * M + 1)), Q)               # 2^(2M+1)-th root: psi^(n*n) = -1
    check(pow(psi, n * n, Q) == Q - 1, 'psi is not a primitive 2N-th root')
    psi2m = pow(psi, 2**M, Q)                                # the pre-twists' root
    omega = pow(psi, 2**(M + 1), Q)                          # the sub-NTTs' root
    pre = [nafTerms(pow(psi2m, i, Q)) for i in range(n)]
    from sage.all import GF                                  # the calculator powers a field element
    sub = calculateNttTwiddles(Q, n, 'GS', primitiveRoot=GF(Q)(omega), useModulusLiftingNaf=True)
    inter = [[pow(psi, t1 * (2 * k2 + 1), Q) for k2 in range(n)] for t1 in range(n)]

    def build(kind):
        factory = (None if kind is None
                   else (lambda name, nn, kind=kind: SCHEMES[kind](name=name, rows=nn, cols=nn)))
        scheme = FourStepScheme(name=f'fs_{kind}', n=n, q=Q, preTwistConstants=pre,
                                subTwiddles=sub, interTwiddles=inter,
                                inputBound=IntType.unsigned(24),
                                interTwistBound=IntType.unsigned(64), butterflyType='GS',
                                transposeLatency=0, transposeSchemeFactory=factory)
        return scheme, FourStepNTT(name=f'ntt_{kind}', scheme=scheme)

    base, baseNtt = build(None)
    with contextlib.redirect_stdout(io.StringIO()):
        check(verifyFourStepNtt(baseNtt, psi=psi, trials=2, seed=1),
              'the reference four-step (behavioural corner turn) fails verifyFourStepNtt')
    for kind in SCHEMES:
        scheme, ntt = build(kind)
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            ok = verifyFourStepNtt(ntt, psi=psi, trials=2, seed=1)
        check(ok, f'{kind}: verifyFourStepNtt failed:\n{buf.getvalue()}')
        tl = scheme.transpose.latency()
        check(tl == SCHEMES[kind](name='t', rows=n, cols=n).latency(),
              'the four-step\'s transpose latency is not the scheme\'s')
        check(scheme.latency() == base.latency() + tl,
              f'{kind}: four-step latency {scheme.latency()} != {base.latency()} + {tl}')
        res = scheme.transpose.resources()
        check(res.bram36 + res.bram18 > 0 and res.lut > 0, f'{kind}: transpose resources {res}')
        try:
            scheme.resources()
            check(False, 'four-step resources() should still raise (behavioural multipliers)')
        except NotImplementedError:
            pass
        print(f'  {kind}: verifyFourStepNtt passes at n={n} (N={n * n}); the four-step\'s latency '
              f'gains the transpose\'s {tl}; the corner turn spends {res}')


# ---------------------------------------------------------------- gate 6
def gate6() -> None:
    print('\nGate 6 -- emitRtl')
    for kind in SCHEMES:
        n = 8
        scheme = SCHEMES[kind](name=f'{kind}{n}', rows=n, cols=n)
        op = MatrixTranspose(name=f'{kind}{n}_op', scheme=scheme)
        op.drive([Signal(IntType.signed(20), None) for _ in range(n)])
        op.compute()
        with tempfile.TemporaryDirectory() as d:
            meta = op.emitRtl(f'{kind}{n}_top', d, test_size=3, seed=5)
            rtl = os.path.join(d, 'RTL_generated')
            for f in ('delay_line.sv', 'barrel_shift.sv', 'BRAM.sv', f'{kind}_matrix_transpose.sv',
                      f'{kind}{n}_top.sv', f'{kind}{n}_top_tb.sv'):
                check(os.path.isfile(os.path.join(rtl, f)), f'{kind}: {f} missing')
            for f in (f'{kind}{n}_top.sv', f'{kind}{n}_top_tb.sv'):
                issues = rtl_static_issues(open(os.path.join(rtl, f), encoding='utf-8').read())
                check(not issues, f'{kind}: {f}: {issues}')
            check(meta['latency'] == scheme.latency(), f'{kind}: meta latency')
            check(meta['rows'] == 3 * n, f'{kind}: rows {meta["rows"]}')
            check(len(meta['output_cycles']) == 2 * 3 * n, f'{kind}: expected rows')
        print(f'  {kind}: emitted, static-clean, sanity check passed, latency {meta["latency"]}')


if __name__ == '__main__':
    t0 = time.time()
    gate1()
    gate2()
    gate3()
    gate4()
    gate5()
    gate6()
    print(f'\nAll gates passed in {time.time() - t0:.1f} s')
