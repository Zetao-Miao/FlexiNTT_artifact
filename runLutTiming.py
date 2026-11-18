'''Verify the LUT-side timing model against the generators that place registers with it.

Five gates, one script, no test framework -- the LUT counterpart to
`runDspMultiplier.py`. Run from the project root:

    python runLutTiming.py            # everything (~2 min)
    python runLutTiming.py --quick    # gate 3 on fewer shapes and stage counts

Gate 1 -- placement (`lut_timing.place_registers`), on every unit table in the
          exercise set and every stage count:
  count      exactly min(stages, units) registers; the output always registered
             when stages >= 1; none at all when stages == 0
  never worse  the slowest segment is never longer than the equal-count split's
  ties       the equal-count split is kept whenever it is optimal, so every
             one-stage design is built byte-for-byte as before
  monotone   more stages never make the slowest segment longer

Gate 2 -- frequency in, cycles out (`lut_timing.stages_for_fmax`):
  fewest     the count returned is the smallest one on the curve that reaches
             the target, and never 0
  floor      a target above the curve's best point is refused, naming the unit
             that sets the floor; a stage cap that binds is refused naming the cap

Gate 3 -- the generators build what the model placed. Every Booth multiplier,
          compressor tree, constant multiplier and butterfly in the set is
          generated at several stage counts (0 included), the emitted RTL is
          read back (a heap nowhere taller than two bits is refused by both the
          unit table and the generator: it is a plain add, and the compressor
          computed it wrong) -- an OUTREG("TRUE") or always_ff per compression layer,
          the terminal adder's output register, the Booth partial-product
          register, the butterfly wrapper's balancing registers -- and must be
          exactly `place_registers`' flags; the testbench must wait exactly the
          latency built, sampling at #2 when that is zero.

Gate 4 -- the model reports what the generator builds. The schemes'
          `latency()` under a request and under `targetFmaxMhz`, the bank's
          per-entry and uniform latency, a butterfly on both RTL backends, and
          an n=8 NTT's total latency on both backends must equal what the
          generators return.

Gate 5 -- the clocked NTT. `FullyPipelinedNTT.reset()` / `step()` under a
          uniform request, a per-layer request with a combinational layer, and
          a frequency target: the output stream must be the untimed outputs of
          every batch delayed by exactly `latency()` edges, None before that,
          for GS and CT; the pipeline the model built (`pipelineReport`: each
          compressor's own registers, then balancing) must match the hardware
          manifest butterfly by butterfly; and the sim RTL pinned to that
          hardware run (`hw_manifest`) must reproduce its latencies.
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
from operator_modeling.multiplier.LutMultiplierScheme import BoothMult
from operator_modeling.multiplier.ConstMultScheme import NafConstMult
from operator_modeling.multiplier.BankScheme import ConstMultBankScheme
from operator_modeling.multiplier.ConstMult import ConstMult
from operator_modeling.multiplier.ConstMultBank import ConstMultBank
from operator_modeling.ntt.butterfly.ButterflyScheme import GoldilocksSlice64
from operator_modeling.ntt.pipelined.FullyPipelinedNTT import FullyPipelinedNTT
from operator_modeling.ntt.twiddles import calculateNttTwiddles

import lut_timing as T                                            # noqa: E402
from rtl_gen.booth_mult import Bmult_RTL_gen                      # noqa: E402
from rtl_gen.compressor import compressor_RTL_gen, reg_flag_list_gen  # noqa: E402

Q = 2**64 - 2**32 + 1

#: Booth operand widths (signed x signed, the generator's own view).
BOOTH = [(16, 16), (32, 32), (64, 64), (66, 64), (24, 70)]
#: Compressor column-height shapes.
HEAPS = {
    '3 op x 64 b': [3] * 64,
    '8 op x 64 b': [8] * 64,
    '16 op x 32 b': [16] * 32,
    'ragged': [1, 3, 5, 7, 9, 11, 9, 7, 5, 3, 1] * 4,
    # reached the terminal adder with a five-bit first column while
    # `check_last_layer` allowed one; strict, it takes one more layer
    'five-bit start': [10, 0, 15, 0, 16, 10, 7, 7, 8, 8, 8, 0, 16, 7, 15, 3, 11, 10, 6, 7, 8, 12, 12, 9, 13, 2],
    # a column of exactly 17 bits, consumed whole by a floating (5, 17 : 4, 5, 1):
    # its one-bit output is the whole next-layer column, a scalar, and the
    # emitter indexed it (Sept 2026)
    'exact 17 column': [20, 0, 12, 3, 12, 15, 8, 12, 16, 20, 17, 13, 0, 17, 6, 6, 19, 13, 19, 6, 18, 5, 6, 4, 17, 8, 17, 13],
}
#: Terminal inputs (heights of at most four reach the terminal adder as they
#: are) on either side of `terminal_add.quaternary_supported`'s three layout
#: conditions, from the boundary probes simulated in Sept 2026: (shape, whether
#: the row-counter adder takes it). The refused ones computed the wrong sum or
#: failed to elaborate on the row-counter adder; the behavioural adder takes
#: them now.
TERMINAL_SHAPES = [
    ([3, 1, 4], False),                    # first chain of no LUTs: top bits undriven
    ([3, 1, 1, 4], False),
    ([3, 1, 4, 2], True),                  # first chain of one LUT
    ([3, 1, 4, 2, 1], True),
    ([2, 0, 2, 3, 3, 3], False),           # zero inside the tail
    ([2, 2, 0, 4, 4, 4, 4], False),        # ... with a cascading tail
    ([2, 2, 2, 0, 2, 2, 3, 3, 3, 3], False),
    ([3, 3, 3, 3, 1, 0, 1], False),        # zero inside the head: undeclared column
    ([1, 0, 2, 3, 3], True),               # zero before the start
    ([3, 3, 3, 3, 2, 0, 2], True),         # zero in the two-operand region
    ([2, 2, 4, 4], True),                  # cascading tail
    ([3, 1, 4, 4], True),
    ([2, 4, 2, 4], True),                  # a two-bit column inside the body
    ([2, 4, 1, 4], True),
    ([3] + [1, 1, 1, 2, 2, 1, 2, 2, 2, 1, 1, 2, 2, 2, 1, 2, 2, 2, 1, 2, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 1, 2, 1, 1, 1, 1] + [4], False),  # termq8
]
#: Heaps whose last-stage merge `merge_last_stage` approved but the merged
#: layer could not honour (two counters on one column's budget, or a dropped
#: column-(c+1) input whose bit stays in the heap), so the generator either
#: raised in the terminal adder or read past a column's declared width; the
#: merge is refused by construction now (`rtl_gen.layer.simulate_layers`).
#: The last two merge and stay merged. From the compressor mechanism
#: campaign, Sept 2026.
MERGE_HEAPS = [[10, 10, 10], [19], [15], [31, 19], [11, 11], [7, 10, 7, 11, 9], [1] * 7 + [16],
               [11, 12, 14, 12, 12, 11, 12, 16, 14, 12, 13, 14, 14, 14, 14, 15], [20, 20], [12, 5]]
#: Heaps the loose `check_last_layer` handed to the terminal adder with a
#: five-bit column (the second simulation campaign's scan, Sept 2026).
FIVE_BIT_HEAPS = [
    HEAPS['five-bit start'],
    [2, 10, 0, 7, 10, 9, 11, 2, 4, 6, 7, 1, 11, 8, 5, 4, 7, 8, 4, 6, 10, 10, 2, 0, 2, 12, 0, 1, 12, 10, 10, 7, 6, 6],
]
#: Constant multipliers on a 64-bit unsigned input: two 3-term compressor
#: shapes and a 2-term adder shape.
CONSTS = [(1 << 63) + (1 << 31) - 1, (1 << 40) + 1, (1 << 50) - (1 << 20) + 1]
STAGES = (0, 1, 2, 3, 4, 10)


def quiet(fn):
    with contextlib.redirect_stdout(io.StringIO()):
        return fn()


def inDir(path, fn):
    os.makedirs(path, exist_ok=True)
    saved = os.getcwd()
    os.chdir(path)
    try:
        return quiet(fn)
    finally:
        os.chdir(saved)


# ---------------------------------------------------------------- reading registers back out of RTL
from rtl_gen.utils import rtl_static_issues  # noqa: E402


def compressorFlags(sv: str) -> list[bool]:
    '''The register flags a generated compressor was built with: one per
    compression layer (an OUTREG("TRUE") on a GPC or an always_ff on the
    pass-through bits) plus the terminal adder's output register. The layer
    markers appear twice, once in the declaration section and once in the
    instantiation section; only the latter carries instances.'''
    markers = list(re.finditer(r'// -+ LAYER (\d+) -+', sv))
    if markers:
        assert len(markers) % 2 == 0, 'layer markers should appear in two sections'
        inst = sv[markers[len(markers) // 2].start():]
    else:
        inst = sv
    flags = []
    for body in re.split(r'// -+ LAYER \d+ -+', inst)[1:]:
        if 'TERMINAL ADDITION' in body:
            body = body.split('TERMINAL ADDITION', 1)[0]
        flags.append('OUTREG("TRUE"' in body or 'always_ff' in body)
    terminal = inst.rsplit('TERMINAL ADDITION', 1)[-1]
    flags.append('always_ff' in terminal)
    return flags


def testbenchWait(tb: str) -> tuple[int, int]:
    '''(cycles waited, settle delay) from a generated testbench's checker.'''
    m = re.search(r'#\(`CLK_P\*(\d+)\);\n\s+#(\d)', tb)
    assert m, 'checker delay not found'
    return int(m.group(1)), int(m.group(2))


def balancingDepth(wrapper: str, label: str) -> int:
    '''How many balancing register stages the butterfly wrapper put on `label`:
    the highest `<label>_bal_d<k>` declared, 0 when there is none.'''
    ks = [int(k) for k in re.findall(rf'logic [^;]*\b{label}_bal_d(\d+);', wrapper)]
    return max(ks, default=0)


def read(path: str) -> str:
    with open(path, encoding='utf-8') as f:
        return f.read()


# ---------------------------------------------------------------- gates
def gate1(unitTables: dict) -> None:
    print('Gate 1 -- placement')
    print(f"  {'table':<28} {'units':>5} {'stages: even -> balanced (ns)':<60}")
    for name, units in unitTables.items():
        w = T.weights(units)
        n = len(w)
        prev = float('inf')
        cells = []
        for L in range(0, n + 2):
            flags = T.place_registers(w, L)
            assert len(flags) == n
            assert sum(flags) == min(max(L, 0), n), (name, L, flags)
            if L >= 1:
                assert flags[-1], (name, L, 'output not registered')
            if L == 0:
                assert not any(flags)
            even = T.even_split(L, n)
            ns, evenNs = T.segment_ns(w, flags), T.segment_ns(w, even)
            assert ns <= evenNs + 1e-9, (name, L, ns, evenNs)
            if evenNs <= ns + 1e-9:
                assert flags == even, (name, L, 'tie must keep the equal-count split')
            if L == 1:
                assert flags == reg_flag_list_gen(1, n), (name, 'one stage must be unchanged')
            assert ns <= prev + 1e-9, (name, L, 'more stages made it slower')
            prev = ns if L >= 1 else prev
            if L == 0:
                assert abs(ns - T.segment_ns(w, T.place_registers(w, 1))) < 1e-9
            if 1 <= L <= n:
                cells.append(f"{L}:{evenNs:.2f}->{ns:.2f}" if abs(ns - evenNs) > 1e-9 else f"{L}:{ns:.2f}")
        print(f"  {name:<28} {n:>5} {' '.join(cells):<60}")


def gate2(unitTables: dict) -> None:
    print('\nGate 2 -- frequency in, cycles out')
    for name, units in unitTables.items():
        pts = T.curve(units)
        for p in pts:
            for target in (p.fmax_mhz - 1e-6, p.fmax_mhz - 5.0):
                L = T.stages_for_fmax(units, target)
                assert L >= 1
                assert pts[L - 1].fmax_mhz >= target - 1e-9, (name, target, L)
                assert all(q.fmax_mhz < target - 1e-9 for q in pts[:L - 1]), (name, target, L, 'not the fewest')
        best = max(pts, key=lambda p: p.fmax_mhz)
        try:
            T.stages_for_fmax(units, best.fmax_mhz + 1.0, label=name)
            raise AssertionError(f'{name}: unreachable target accepted')
        except ValueError as e:
            floor = T.floor_unit(units)
            assert 'unreachable' in str(e) and (floor.note or floor.kind) in str(e), str(e)
        # a stage cap that binds is refused naming the cap
        if len(pts) >= 2 and pts[-1].fmax_mhz > pts[-2].fmax_mhz + 1e-9:
            try:
                T.stages_for_fmax(units, pts[-1].fmax_mhz - 1e-6, max_stages=pts[-1].stages - 1, label=name)
                raise AssertionError(f'{name}: a binding stage cap was accepted')
            except ValueError as e:
                assert 'binding' in str(e), str(e)
        print(f"  {name:<28} floor {best.fmax_mhz:6.1f} MHz at {best.stages} stage(s), set by {T.floor_unit(units).note}")


def gate3(work: str, booth, heaps, consts, stages) -> None:
    print('\nGate 3 -- generators build what the model placed')
    print(f"  {'design':<32} {'stages tried':<26} {'latency built':<22} {'tb':>4}")
    for wa, wb in booth:
        units = T.bmult_units(wa, wb)
        built, checked = [], 0
        for L in stages:
            d = os.path.join(work, f'bmult{wa}x{wb}_L{L}')
            meta = inDir(d, lambda: Bmult_RTL_gen(wa, wb, pipeline_stages=L, gen_testbenches=True, test_size=4))
            want = T.place_registers(T.weights(units), L)
            assert meta['reg_flag_list'] == want, (wa, wb, L)
            rtl = os.path.join(d, 'RTL_generated')
            got = ['always_ff' in read(os.path.join(rtl, f'Bmult{wa}x{wb}_bitheap_gen.sv'))] + \
                  compressorFlags(read(os.path.join(rtl, f'Bmult{wa}x{wb}_bitheap_cmp.sv')))
            assert got == want, (wa, wb, L, got, want)
            wait = testbenchWait(read(os.path.join(rtl, f'Bmult{wa}x{wb}_tb.sv')))
            assert wait == (meta['pipeline_latency'], 1 if meta['pipeline_latency'] else 2), (wa, wb, L, wait)
            assert meta['pipeline_latency'] == sum(want)
            built.append(meta['pipeline_latency'])
            checked += 1
        print(f"  {f'Booth {wa}x{wb}':<32} {str(list(stages)):<26} {str(built):<22} {checked:>4}")

    # a heap nowhere taller than two bits is a plain add: refused, not built wrong
    for fn in (lambda: T.heap_units([2] * 40),
               lambda: inDir(os.path.join(work, 'flat'), lambda: (
                   open('bitheap.txt', 'w').write('2\n' * 40),
                   compressor_RTL_gen('bitheap.txt', 'flat', 'flat', tb_out_width=41,
                                      reg_flag_list=[False, True], gen_testbench=False)))):
        try:
            fn()
            raise AssertionError('a flat heap was accepted by the compressor path')
        except ValueError as e:
            assert 'two-operand add' in str(e), str(e)
    print(f"  {'compressor flat 2 op x 40 b':<32} {'refused (a plain add)':<26}")

    # the heuristic hands the terminal adder at most four bits per column
    from dsp_multiplier.common.lut_cost import _analyse_bitheap
    for heights in FIVE_BIT_HEAPS:
        a = _analyse_bitheap(heights)
        assert max(a.terminal_inputs) <= 4, (heights, a.terminal_inputs)
    print(f"  {'five-bit terminal columns':<32} {'none scheduled':<26} {len(FIVE_BIT_HEAPS)} heaps")

    # the row-counter terminal adder takes exactly the shapes it computes right;
    # the others get the behavioural adder, and both build and count
    from rtl_gen.terminal_add import quaternary_supported
    for i, (heights, quaternary) in enumerate(TERMINAL_SHAPES):
        ti = _analyse_bitheap(heights).terminal_inputs
        assert quaternary_supported(ti) == quaternary, (heights, ti)
        d = os.path.join(work, f'terminal_shape_{i}')

        def gen():
            with open('bitheap.txt', 'w') as f:
                f.write(''.join(f'{h}\n' for h in heights))
            compressor_RTL_gen('bitheap.txt', 'cmp', 'cmp', tb_out_width=T.heap_width(heights),
                               reg_flag_list=T.heap_reg_flags(heights, 1), gen_testbench=True, test_size=4)
        inDir(d, gen)
        sv = read(os.path.join(d, 'RTL_generated', 'cmp.sv'))
        assert ('assign terminal_sum =' in sv) == (not quaternary), (heights, quaternary)
        assert not rtl_static_issues(sv), (heights, rtl_static_issues(sv)[:3])
    print(f"  {'terminal adder shapes':<32} {'row-counter / behavioural':<26} {sum(1 for _, q in TERMINAL_SHAPES if q)} / {sum(1 for _, q in TERMINAL_SHAPES if not q)}")

    # a last-stage merge is kept only when the merged layer fits: the model
    # and the generator take the same decision, the RTL's layer count and
    # terminal widths are the model's, and nothing reads past a column
    merged = 0
    for i, heights in enumerate(MERGE_HEAPS):
        a = _analyse_bitheap(heights)
        merged += a.merged_last_stage
        for L in (0, 1):
            d = os.path.join(work, f'merge_heap_{i}_L{L}')

            def gen():
                with open('bitheap.txt', 'w') as f:
                    f.write(''.join(f'{h}\n' for h in heights))
                compressor_RTL_gen('bitheap.txt', 'cmp', 'cmp', tb_out_width=T.heap_width(heights),
                                   reg_flag_list=T.heap_reg_flags(heights, L), gen_testbench=True, test_size=4)
            inDir(d, gen)
            sv = read(os.path.join(d, 'RTL_generated', 'cmp.sv'))
            assert not rtl_static_issues(sv), (heights, L, rtl_static_issues(sv)[:3])
            rtl_layers = len(set(re.findall(r'layer(\d+)_col', sv))) - 1
            assert rtl_layers == a.compression_layers - (1 if a.merged_last_stage else 0), (heights, L, rtl_layers, a)
            decl = {int(c): (int(w) + 1 if w else 1)
                    for w, c in re.findall(rf'logic\s*(?:\[(\d+)\s*:\s*0\])?\s*layer{rtl_layers}_col(\d+);', sv)}
            assert tuple(decl.get(c, 0) for c in range(len(a.terminal_inputs))) == tuple(a.terminal_inputs), (heights, L)
    print(f"  {'last-stage merges':<32} {'kept / refused':<26} {merged} / {len(MERGE_HEAPS) - merged}")

    for name, heights in heaps.items():
        units = T.heap_units(heights)
        built, checked = [], 0
        width = T.heap_width(heights)
        for L in stages:
            flags = T.heap_reg_flags(heights, L)
            d = os.path.join(work, f"cmp_{name.replace(' ', '_')}_L{L}")

            def gen():
                with open('bitheap.txt', 'w') as f:
                    f.write(''.join(f'{h}\n' for h in heights))
                compressor_RTL_gen('bitheap.txt', 'cmp', 'cmp', tb_out_width=width,
                                   reg_flag_list=flags, gen_testbench=True, test_size=4)
            inDir(d, gen)
            rtl = os.path.join(d, 'RTL_generated')
            got = compressorFlags(read(os.path.join(rtl, 'cmp.sv')))
            assert got == flags, (name, L, got, flags)
            assert not rtl_static_issues(read(os.path.join(rtl, 'cmp.sv'))), (name, L, rtl_static_issues(read(os.path.join(rtl, 'cmp.sv')))[:3])
            wait = testbenchWait(read(os.path.join(rtl, 'cmp_tb.sv')))
            assert wait == (sum(flags), 1 if sum(flags) else 2), (name, L, wait)
            built.append(sum(flags))
            checked += 1
        print(f"  {f'compressor {name}':<32} {str(list(stages)):<26} {str(built):<22} {checked:>4}")

    for c in consts:
        built, checked = [], 0
        for L in stages:
            sch = NafConstMult(name='Cmult', constant=c, aIn=IntType.unsigned(64))
            op = ConstMult(name='cm', scheme=sch)
            d = os.path.join(work, f'cmult_{c}_L{L}')
            meta = inDir(d, lambda: op.emitRtl('Cmult', d, pipeline_stages=L, gen_testbench=True, test_size=4))
            rtl = os.path.join(d, 'RTL_generated')
            want = sch.registerFlags(L)
            if sch.strategy() == 'compressor':
                got = compressorFlags(read(os.path.join(rtl, 'Cmult_cmp.sv')))
                assert got == want, (c, L, got, want)
            else:
                assert not os.path.exists(os.path.join(rtl, 'Cmult_cmp.sv')) and want == []
            assert meta['pipeline_latency'] == sch.latency(L) == sum(want), (c, L, meta['pipeline_latency'], sch.latency(L))
            wait = testbenchWait(read(os.path.join(rtl, 'Cmult_tb.sv')))
            assert wait == (sum(want), 1 if sum(want) else 2), (c, L, wait)
            built.append(sum(want))
            checked += 1
        print(f"  {f'cmult x{c % 10**6}.. ({sch.strategy()})':<32} {str(list(stages)):<26} {str(built):<22} {checked:>4}")

    tw = (2**43 - 2**91) % Q
    for aw, bw in ((96, 96), (66, 32)):
        built, checked = [], 0
        for L in stages:
            sch = GoldilocksSlice64(name='bf', butterflyType='GS', aIn=IntType.signed(aw),
                                    bIn=IntType.signed(bw), twiddle=tw)
            plan = quiet(lambda: sch.stagePlan(L))
            d = os.path.join(work, f'bf{aw}x{bw}_L{L}')
            meta = inDir(d, lambda: sch.emitRtl('bf', d, pipeline_stages=L, gen_testbench=True, test_size=4))
            rtl = os.path.join(d, 'RTL_generated')
            for out in (plan.aOut, plan.bOut):
                got = compressorFlags(read(os.path.join(rtl, f'bf_{out.label}_cmp.sv')))
                assert got == list(out.flags), (aw, bw, L, out.label, got, out.flags)
            wrapper = read(os.path.join(rtl, 'bf.sv'))
            for out in (plan.aOut, plan.bOut):
                extra = plan.latency - out.stages
                assert balancingDepth(wrapper, out.label) == extra, (aw, bw, L, out.label, extra)
            wait = testbenchWait(read(os.path.join(rtl, 'bf_tb.sv')))
            assert wait == (plan.latency, 1 if plan.latency else 2), (aw, bw, L, wait)
            assert meta['pipeline_latency'] == plan.latency == sch.latency(L)
            built.append(plan.latency)
            checked += 1
        print(f"  {f'butterfly s{aw} x s{bw}':<32} {str(list(stages)):<26} {str(built):<22} {checked:>4}")


def gate4(work: str) -> None:
    print('\nGate 4 -- the model reports what the generator builds')
    rows = []
    # Booth under a target, through the scheme's own emitRtl (which asserts the same)
    for tgt in (300.0, 400.0):
        sch = BoothMult(name='b64', aIn=IntType.signed(64), bIn=IntType.signed(64), targetFmaxMhz=tgt)
        meta = quiet(lambda: sch.emitRtl('b64', os.path.join(work, f'g4_booth_{tgt}'), pipeline_stages=1, gen_testbench=False))
        assert meta['pipeline_latency'] == sch.latency(1) == sch.pipelineStages(1)
        assert sch.achievedFmaxMhz(1) >= tgt
        rows.append(('Booth 64x64', f'target {tgt:.0f} MHz', meta['pipeline_latency'], f"{sch.achievedFmaxMhz(1):.0f} MHz"))
    # a bank under a target: per-entry depths and the uniform latency
    bank = ConstMultBankScheme(name='bank', constants=CONSTS, aIn=IntType.unsigned(64), targetFmaxMhz=400.0)
    op = ConstMultBank(name='bank', scheme=bank)
    meta = quiet(lambda: op.emitRtl('bank', os.path.join(work, 'g4_bank'), pipeline_stages=1, gen_testbench=True, test_size=4))
    assert meta['per_entry_latency'] == bank.perEntryLatency(1)
    assert meta['uniform_latency'] == bank.latency(1)
    rows.append(('bank of 3', 'target 400 MHz', meta['uniform_latency'], f"per entry {meta['per_entry_latency']}"))
    # a butterfly under a target, both backends
    tw = (2**43 - 2**91) % Q
    for backend in ('hw', 'sim'):
        sch = GoldilocksSlice64(name='bf', butterflyType='GS', aIn=IntType.signed(96), bIn=IntType.signed(96),
                                twiddle=tw, targetFmaxMhz=450.0)
        meta = quiet(lambda: sch.emitRtl('bf', os.path.join(work, f'g4_bf_{backend}'), pipeline_stages=1,
                                         gen_testbench=True, test_size=4, backend=backend))
        assert meta['pipeline_latency'] == sch.latency(1)
        rows.append(('butterfly s96 x s96', f'target 450 MHz, {backend}', meta['pipeline_latency'], f"{sch.achievedFmaxMhz(1):.0f} MHz"))
    # a bank whose adder entry cannot reach the target is refused wherever its latency is asked
    bank = ConstMultBankScheme(name='bankT', constants=[(1 << 9) - (1 << 4) + 1, (1 << 190) + 1],
                               aIn=IntType.unsigned(200), targetFmaxMhz=340.0)
    for call in (lambda: bank.perEntryLatency(1), lambda: bank.latency(1), lambda: bank.getOperatorInterface('bankT')):
        try:
            call()
            raise AssertionError('a bank with an adder below the target was accepted')
        except ValueError as e:
            assert 'unreachable' in str(e), str(e)
    rows.append(('bank with a 201-bit adder', 'target 340 MHz', '-', 'refused, adder is the floor'))
    # an n=8 NTT, both backends, request and target; s130 inputs at request 3 give a
    # layer whose butterflies differ in depth, so the wrappers must balance it
    n = 8
    twd = quiet(lambda: calculateNttTwiddles(Q, n, 'GS', useModulusLiftingNaf=True))
    for tgt, req, width in ((None, 1, 96), (None, 3, 96), (450.0, 1, 96), (None, 3, 130), (None, 2, 130)):
        ntt = FullyPipelinedNTT(name='ntt8', n=n, q=Q, butterflyType='GS', twiddles=twd, targetFmaxMhz=tgt)
        random.seed(1)
        vals = [[random.randint(-(1 << (width - 1)), (1 << (width - 1)) - 1) for _ in range(4)] for _ in range(n)]
        ntt.getInputsNatural([IntType.signed(width)] * n)
        ntt.getInputsNatural(vals)
        quiet(ntt.compute)
        model = quiet(lambda: ntt.latency(req))
        mans = {}
        for backend in ('hw', 'sim'):
            ntt.getInputsNatural([IntType.signed(width)] * n)
            ntt.getInputsNatural(vals)
            quiet(ntt.compute)
            d = os.path.join(work, f'g4_ntt_{tgt}_{req}_{width}_{backend}')
            man = quiet(lambda: ntt.emitRtl(f'ntt8_{backend}', d, pipeline_stages_per_layer=req,
                                            gen_testbench=True, backend=backend))
            assert man['total_latency'] == model, (tgt, req, backend, man['total_latency'], model)
            mans[backend] = man
            mixed = any(len(set(l)) > 1 for l in man['butterfly_latencies'])
            wrapper = read(os.path.join(d, 'RTL_generated', f'ntt8_{backend}.sv'))
            assert ('always_ff' in wrapper) == mixed, (backend, width, req, 'balancing registers', mixed)
        assert mans['hw']['butterfly_latencies'] == mans['sim']['butterfly_latencies']
        note = 'hw == sim' + (', mixed-depth layer balanced' if mixed else '')
        rows.append((f'NTT n=8 GS s{width}', f"{'target 450 MHz' if tgt else f'request {req}'}", model, note))
    # an explicit target on emitRtl is the model's target afterwards
    ntt = FullyPipelinedNTT(name='ntt8', n=n, q=Q, butterflyType='GS', twiddles=twd)
    ntt.getInputsNatural([IntType.signed(96)] * n)
    quiet(ntt.compute)
    man = quiet(lambda: ntt.emitRtl('ntt8_t', os.path.join(work, 'g4_ntt_explicit_target'), pipeline_stages_per_layer=1,
                                    gen_testbench=False, target_fmax_mhz=450.0))
    assert man['total_latency'] == quiet(lambda: ntt.latency(1)) == 6
    rows.append(('NTT n=8 GS', 'emitRtl(target_fmax_mhz=450)', man['total_latency'], 'written through to latency()'))
    print(f"  {'design':<22} {'knob':<26} {'latency':>7}   note")
    for d, k, lat, note in rows:
        print(f"  {d:<22} {k:<26} {lat:>7}   {note}")


def gate5(work: str) -> None:
    print('\nGate 5 -- the clocked NTT')
    n, K, trials = 8, 5, 4
    print(f"  {'grid':<14} {'request':<18} {'layers':<12} {'LAT':>4}   stream")
    for kind in ('GS', 'CT'):
        twd = quiet(lambda: calculateNttTwiddles(Q, n, kind, useModulusLiftingNaf=True))
        for tgt, req, width in ((None, 1, 96), (None, [0, 2, 1], 96), (450.0, 1, 96), (None, 3, 130)):
            ntt = FullyPipelinedNTT(name=f'ntt8{kind}', n=n, q=Q, butterflyType=kind, twiddles=twd, targetFmaxMhz=tgt)
            random.seed(3)
            batches = [[[random.randint(-(1 << (width - 1)), (1 << (width - 1)) - 1) for _ in range(trials)] for _ in range(n)]
                       for _ in range(K)]
            ntt.getInputsNatural([IntType.signed(width)] * n)
            quiet(ntt.compute)
            expected = []
            for b in batches:                       # the untimed answer, batch by batch
                ntt.getInputsNatural([IntType.signed(width)] * n)
                ntt.getInputsNatural(b)
                quiet(ntt.compute)
                expected.append([list(p.signal.values) for p in ntt.outputPorts])
            layers = quiet(lambda: ntt.scheme.layerLatencies(req))
            LAT = quiet(lambda: ntt.latency(req))
            assert LAT == sum(layers)
            hwdir = os.path.join(work, f'g5_{kind}_{tgt}_{str(req)}')
            man = quiet(lambda: ntt.emitRtl(f'ntt8{kind}', hwdir, pipeline_stages_per_layer=req, gen_testbench=False))
            assert man['layer_latency'] == layers and man['total_latency'] == LAT, (kind, req, man['layer_latency'], layers)
            # the sim RTL pinned to that hardware run must reproduce its latencies
            sim = quiet(lambda: ntt.emitRtl(f'ntt8{kind}sim', hwdir + '_sim', gen_testbench=False, backend='sim',
                                            hw_manifest=os.path.join(hwdir, 'manifest.json')))
            assert sim['butterfly_latencies'] == man['butterfly_latencies'] and sim['layer_latency'] == layers
            quiet(lambda: ntt.reset(req))
            # the pipeline the model built is the one the RTL was built with:
            # per butterfly, logic registers first, synchronisation after
            report = ntt.pipelineReport()
            assert [[r['butterfly_latency'] for r in layer] for layer in report] == man['butterfly_latencies'], (kind, req)
            for s_, layer in enumerate(report):
                for r in layer:
                    for out in ('aOut', 'bOut'):
                        assert r[f'{out}_stages'] + r['wrapper_balancing'][out] + r['layer_balancing'] == layers[s_]
                    assert r['layer_latency'] == layers[s_]
            checked = 0
            for t in range(K + LAT):
                ntt.getInputsNatural(batches[min(t, K - 1)])
                ntt.step()
                got = [p.signal.values for p in ntt.outputPorts]
                if t < LAT - 1:
                    assert all(v is None for v in got), (kind, req, t, 'output before fill')
                else:
                    j = t - max(LAT - 1, 0)
                    if j < K:
                        assert got == expected[j], (kind, req, t, j)
                        checked += 1
            assert checked == K
            sync = sum(r['layer_balancing'] + r['wrapper_balancing']['aOut'] + r['wrapper_balancing']['bOut']
                       for layer in report for r in layer)
            print(f"  {f'n=8 {kind} s{width}':<14} {('target 450 MHz' if tgt else str(req)):<18} {str(layers):<12} {LAT:>4}   "
                  f"{checked} batches at LAT-1+j, {sync} sync registers")


if __name__ == '__main__':
    quick = '--quick' in sys.argv
    booth = BOOTH[::2] if quick else BOOTH
    heaps = dict(list(HEAPS.items())[::2]) if quick else HEAPS
    stages = (0, 1, 3) if quick else STAGES
    tables = {f'Booth {wa}x{wb}': T.bmult_units(wa, wb) for wa, wb in BOOTH}
    tables.update({f'compressor {k}': T.heap_units(v) for k, v in HEAPS.items()})
    tables['adder 128 b'] = T.adder_units(128)
    t0 = time.time()
    gate1(tables)
    gate2(tables)
    with tempfile.TemporaryDirectory(prefix='runLutTiming_') as work:
        gate3(work, booth, heaps, CONSTS, stages)
        gate4(work)
        gate5(work)
    print(f'\nall gates passed in {time.time() - t0:.0f}s')
