'''Fabric register count of a DSP multiplier, read from the lowered IR the RTL is written from.

`DspMultiplierScheme.lower()` gives the IR module; each op is one emitted block:

    DspTile   single DSP58: no fabric register (AREG/BREG/MREG/PREG are inside the DSP).
              PCIN chain of L blocks: the generated `DSPChain_L<L>_lat<l>` keeps the low 23-bit
              slice of every block but the last in fabric registers until the tail is ready, and
              skews operands that the DSP's own A/B registers cannot absorb (`chain_plan`).
              Karatsuba 2x2: `k2_rtl_gen.k2_cost_bits`, final adder trimmed to the product width.
              Karatsuba 3 / Toom-Cook blocks: not counted (see `unknown`).
    Delay     `delay_line #(WIDTH, CYCLES)`: WIDTH x CYCLES registers.
    BitHeap   max column height <= 2: a `+` with `latency` output registers of the result width;
              otherwise the compressor, registers from `core.heapcount.heapFlipFlops` with the
              flags `lut_timing.heap_reg_flags(heights, latency)`.
    LutMult   small behavioural multiplier (`SmallMult`): latency x (wa + wb) registers.
              Booth partial products for a heap (`LutPP`): latency x bits of the flat bus.
              Booth core with its own sum: not counted (see `unknown`).
    Sub       `sub_signed`: latency x result width.

`dspMultiplierRegisters(scheme)` returns {'ff': total, 'rows': [(op name, kind, ff, note)],
'unknown': [op names whose registers are not counted]}.
'''
from __future__ import annotations

import contextlib
import io



def _smallMultMax() -> int:
    """The emitter's own limit: a LUT multiplier with a side of at most this many bits is written as plain partial
    products, a larger one as a Booth core (rtl_gen/dsp_multiplier/interface.py reads the same constant)."""
    from dsp_multiplier.frontend.solver.tuning import SMALL_MULT_MAX
    return SMALL_MULT_MAX


def chainFabricFlipFlops(cfg: dict, blocks: int, aBits: int, bBits: int) -> int:
    '''Fabric registers inside one generated DSP chain (`dsp_rtl_gen.gen_dsp_chain`).
    `aBits`, `bBits`: the operand bits that are not constant (synthesis removes the rest).'''
    from rtl_gen.dsp_multiplier.dsp.dsp_rtl_gen import chain_plan, PITCH, B_PORT
    p = chain_plan(cfg, blocks)
    ff = 0
    extMax = max(p['ext_dly']) if blocks else 0
    ff += extMax * aBits                                   # a_ext_d<i>
    for k in range(blocks):                                # b<k>_d<i>
        if k == blocks - 1:
            w = min(B_PORT, max(0, bBits - PITCH * k))
        else:
            w = min(PITCH, max(0, bBits - PITCH * k))
        ff += p['ext_dly'][k] * w
    for k in range(blocks - 1):                            # low<k>_d<i>
        ff += p['out_dly'][k] * PITCH
    return ff


def boothCore(op) -> tuple:
    '''(width A, width B, register flags) of the Booth core the back end writes for a `LutMult`
    (`inner_backends._write_bmult_inner`): signed operands (an unsigned one gets a zero bit),
    `Bmult_RTL_gen(pa, pb, pipeline_stages=latency)`, flags from `lut_timing.place_registers`.'''
    import lut_timing as LT
    pa = op.a.width + (0 if op.a.signed else 1)
    pb = op.b.width + (0 if op.b.signed else 1)
    flags = LT.place_registers(LT.weights(LT.bmult_units(pa, pb)), op.latency)
    return pa, pb, tuple(bool(f) for f in flags)


def liveRanges(module, top, lo: int, hi: int) -> dict:
    '''{signal name: (lowest, highest) live bit} for everything that feeds the heap `top` when
    only its columns lo..hi stay: a term of weight w of a heap keeps its bits lo-w..hi-w, a delay
    passes the range on, an inner heap also keeps what makes its carries (from its first carry
    column). Terms given as partial-product columns are left out.'''
    import dsp_multiplier.backend.ir as IR
    import dsp_multiplier.backend.delay_model as DM
    from ..core.heapcount import firstCarryColumn
    live = {top.result.name: (lo, hi)}

    def merge(name, a, b, width):
        a, b = max(0, a), min(width - 1, b)
        if a > b:
            return
        if name in live:
            a, b = min(a, live[name][0]), max(b, live[name][1])
        live[name] = (a, b)
    for op in reversed(module.ops):
        nm = op.result.name if hasattr(op, 'result') else None
        if nm not in live:
            continue
        a, b = live[nm]
        if isinstance(op, IR.BitHeap):
            if op is not top:
                a = min(a, firstCarryColumn(tuple(DM._bitheap_heights(op))))
            for t in op.terms:
                if t.pp_columns is None:
                    merge(t.signal.name, a - t.weight, b - t.weight, t.signal.width)
        elif isinstance(op, IR.Delay):
            merge(op.source.name, a, b, op.source.width)
    return live


def dspMultiplierRegisters(scheme) -> dict:
    import dsp_multiplier.backend.ir as IR
    import dsp_multiplier.backend.delay_model as DM
    from lut_timing import heap_reg_flags
    from ..core.heapcount import heapFlipFlops, boothCounts
    with contextlib.redirect_stdout(io.StringIO()):
        module, _ = scheme.lower()
    rows, unknown, total = [], [], 0
    for op in module.ops:
        kind = type(op).__name__
        ff, note = 0, ''
        if isinstance(op, IR.DspTile):
            fam, blocks = DM.dsp_family(op.params, op.impl_id)
            if fam == 'single':
                note = 'single DSP58'
            elif fam == 'chain':
                cfg = DM.exact_dsp_config(fam, blocks, op.latency, label=op.impl_id)['config']
                srcs = [getattr(op, n, None) for n in ('a', 'b')]
                wa = srcs[0].width if srcs[0] is not None else 26
                wb = srcs[1].width if srcs[1] is not None else 23 * blocks
                if getattr(op, 'transposed', False):
                    wa, wb = wb, wa
                if wa > wb:
                    wa, wb = wb, wa
                ff = chainFabricFlipFlops(cfg, blocks, wa, wb)
                note = f'chain of {blocks}'
            elif fam == 'k2':
                # Karatsuba 2x2 tile: alignment registers of P_hi / P_lo / P[21:0] and the final
                # adder (`k2_rtl_gen.k2_cost_bits`); adder result bits above the product are unread.
                from rtl_gen.dsp_multiplier.dsp import k2_rtl_gen as K2
                cfg = DM.exact_dsp_config(fam, blocks, op.latency, label=op.impl_id)['config']
                ff = K2.k2_cost_bits(K2.k2_plan(cfg))['total']
                ff -= max(0, K2.LOW_W + K2.ADD_W + 1 - op.result.width)
                note = 'Karatsuba 2x2'
            elif fam in ('k3', 't25'):
                # Karatsuba 3x3 / Toom-Cook 2.5 tile: the alignment registers and the segmented
                # final adder as the emitter's own plan counts them (`k3_cost_bits`,
                # `t25_cost_bits`); result bits above the product are unread.
                from rtl_gen.dsp_multiplier.dsp import k3_rtl_gen as K3, t25_rtl_gen as T25
                cfg = DM.exact_dsp_config(fam, blocks, op.latency, label=op.impl_id)['config']
                if fam == 'k3':
                    ff = K3.k3_cost_bits(K3.k3_plan(cfg))['total']
                    full = K3.LOW_W + K3.ADD_W
                else:
                    ff = T25.t25_cost_bits(T25.t25_plan(cfg))['total']
                    full = T25.LOW_W + T25.ADD_W
                ff -= max(0, full - op.result.width) if cfg.get('split', 1) > 0 else 0
                note = 'Karatsuba 3x3' if fam == 'k3' else 'Toom-Cook 2.5'
            else:
                unknown.append(str(op.result))
                note = f'{fam}: registers not counted'
        elif isinstance(op, IR.Delay):
            ff = op.result.width * op.cycles
            note = f'{op.result.width} x {op.cycles}'
        elif isinstance(op, IR.BitHeap):
            if op.latency > 0:
                heights = tuple(DM._bitheap_heights(op))
                if max(heights, default=0) <= 2:
                    ff = op.latency * op.result.width
                    note = 'plain add'
                else:
                    flags = heap_reg_flags(heights, op.latency)
                    ff = heapFlipFlops(heights, flags, outWidth=op.result.width)
                    note = f'compressor flags {"".join("1" if f else "0" for f in flags)}'
        elif isinstance(op, IR.LutMult):
            small = min(op.a.width, op.b.width) <= 5 and not isinstance(op, IR.LutPP)
            if small:
                ff = op.latency * (op.a.width + op.b.width)
                note = 'small multiplier'
            elif op.latency > 0 and isinstance(op, IR.LutPP):
                # the flat bus of Booth partial product bits is registered once per stage
                # (measured, 32-bit word-level Montgomery `mp`: 33 of the 36 bits, 3 are constants)
                ff = op.latency * op.result.width
                note = 'Booth partial products'
            elif op.latency > 0:
                pa, pb, flags = boothCore(op)
                ff = boothCounts(pa, pb, flags, 0, op.result.width - 1)['ff']
                note = f'Booth core {pa}x{pb} flags {"".join("1" if f else "0" for f in flags)}'
        elif isinstance(op, IR.Sub):
            ff = op.latency * op.result.width
            note = 'subtractor'
        else:
            continue
        rows.append((str(op.result), kind, ff, note))
        total += ff
    return {'ff': total, 'rows': rows, 'unknown': unknown}


def _k2Trim(op, h: int) -> tuple:
    '''(flip-flops, LUTs) a Karatsuba 2x2 tile loses when only its product bits 0..h stay alive:
    the P_hi alignment keeps the bits up to 3 columns above h, the final adder and its result
    register the bits up to h; P_lo and P[21:0] stay. (0, 0) for any other tile.'''
    import dsp_multiplier.backend.delay_model as DM
    fam, blocks = DM.dsp_family(op.params, op.impl_id)
    if fam != 'k2':
        return 0, 0
    from rtl_gen.dsp_multiplier.dsp import k2_rtl_gen as K2
    cfg = DM.exact_dsp_config(fam, blocks, op.latency, label=op.impl_id)['config']
    plan = K2.k2_plan(cfg)
    res = min(K2.ADD_W + 1, op.result.width - K2.LOW_W)
    cutHi = (K2.P_HI_W - max(0, min(K2.P_HI_W, h + 4 - 2 * K2.LOW_W))) * plan['hi_dly']
    cutRes = res - max(0, min(res, h + 1 - K2.LOW_W))
    return cutHi + cutRes, cutRes


def _k2TrimLow(op, l: int) -> int:
    '''Flip-flops a Karatsuba 2x2 tile loses when only its product bits from `l` up are read: the
    straight-through bits P[21:0] below `l` with their alignment registers, and the result register
    bits of the final adder below `l` (the adder LUTs stay, their carry feeds the read bits).
    Routed, Shoup 44 bits, quotient product read from bit 44: 115 of 181 flip-flops (P[21:0]
    alignment 44 and 22 result bits gone). 0 for any other tile.'''
    import dsp_multiplier.backend.delay_model as DM
    fam, blocks = DM.dsp_family(op.params, op.impl_id)
    if fam != 'k2':
        return 0
    from rtl_gen.dsp_multiplier.dsp import k2_rtl_gen as K2
    cfg = DM.exact_dsp_config(fam, blocks, op.latency, label=op.impl_id)['config']
    plan = K2.k2_plan(cfg)
    cut = min(K2.LOW_W, l) * plan['low_dly']       # the chain `P_low_al` (its first stage is shared with `P_lo_al`)
    base = K2.LOW_W
    for seg in plan['seg']:
        cut += max(0, min(seg['w'], l - base)) * (1 + seg['out_dly'])
        base += seg['w']
    return cut


CARRY_BLOCK = 8     # columns of one LOOKAHEAD8 carry cell
PLAIN_REACH = 6     # columns the terminal chains run above the read bits when no counter sits there


def _reach(hi: int) -> int:
    '''The highest column of a final sum that stays when bits up to `hi` are read: the carry cell
    (8 columns) that holds bit `hi` and the cell above it. The tools remove a carry chain cell by
    cell, and the first unread cell stays (its carry outputs feed its own LUTs). Measured on five
    truncated products of 32 to 64 bits (routed sites / this rule / the earlier hi + 6):
    158 / 168 / 92, 565 / 586 / 548, 241 / 192 / 155, 839 / 768 / 698, 497 / 557 / 529.'''
    return (hi // CARRY_BLOCK + 2) * CARRY_BLOCK - 1
                    # (measured 4 to 8: run-time Barrett 28 / 44 / 64, Shoup 52)


def dspMultiplierCounts(scheme, lo: int = 0, hi: int | None = None) -> dict:
    '''Cells of a DSP multiplier whose consumers read only bits lo..hi of the product:
    {'lut', 'srl', 'ff', 'dsp', 'note', 'parts'}. With the whole product read this is
    `dspMultiplierRegisters` plus the LUT and DSP counts the search priced.

    Trimming (measured on routed netlists, see `core.emitcount`): in the final sum, columns above
    `hi` are removed and columns below the first carry column are removed unless read; an alignment
    delay keeps only the bits that land in the remaining columns. A DSP tile (single DSP or PCIN
    chain) is removed with its alignment delay when none of its product bits is a live input of
    the compressor (`core.heapcount.heapNetLive`: the cone of the read bits in the compressor text
    the generator writes, carry cells whole, `dont_touch` chain starts kept); otherwise it stays
    whole (routed: the live counters equal the routed ones on every dumped row, gap/RESULTS.md
    step 4).'''
    import dsp_multiplier.backend.ir as IR
    import dsp_multiplier.backend.delay_model as DM
    from lut_timing import heap_reg_flags
    from ..core.heapcount import heapLiveFlipFlops, firstCarryColumn, heapLuts, boothCounts
    from ..core.emitcount import delayCells
    full = dspMultiplierRegisters(scheme)
    lutTotal, dspCount = scheme.areaCost()
    with contextlib.redirect_stdout(io.StringIO()):
        module, _ = scheme.lower()
    heaps = [op for op in module.ops if isinstance(op, IR.BitHeap)]
    out = {'lut': int(lutTotal), 'srl': 0, 'ff': full['ff'], 'dsp': int(dspCount),
           'note': '', 'parts': {r[0]: r[2] for r in full['rows'] if r[2]}}
    if full['unknown']:
        out['note'] = 'not counted: ' + ','.join(full['unknown'])
    if not heaps:
        # one tile is the product. A Karatsuba 2x2 tile read only in its low bits loses the
        # registers of the unread part (measured, run-time Montgomery 44 bits, `mm_full`: 90 of 181).
        tiles = [op for op in module.ops if isinstance(op, IR.DspTile)]
        if len(tiles) == 1 and hi is not None and hi < tiles[0].result.width - 1:
            cutFf, cutLut = _k2Trim(tiles[0], hi)
            out['ff'] = max(0, out['ff'] - cutFf)
            out['lut'] = max(0, out['lut'] - cutLut)
            if cutFf:
                out['note'] = (out['note'] + f' Karatsuba tile read to bit {hi}').strip()
        if len(tiles) == 1 and lo > 0:
            cutLow = _k2TrimLow(tiles[0], lo)
            out['ff'] = max(0, out['ff'] - cutLow)
            if cutLow:
                out['note'] = (out['note'] + f' Karatsuba tile read from bit {lo}').strip()
        return out
    top = heaps[-1]
    width = top.result.width
    if hi is None or hi >= width:
        hi = width - 1
    heights = tuple(DM._bitheap_heights(top))
    need = min(lo, firstCarryColumn(heights))
    weightOf = {t.signal.name: t.weight for t in top.terms if t.pp_columns is None}
    ff = srl = 0
    parts = {}
    for name, kind, f, note in full['rows']:
        parts[name] = f
    # tiles that only feed columns out of reach of the read bits
    srcOf = {op.result.name: op.source.name for op in module.ops if isinstance(op, IR.Delay)}
    gone, dspGone, lutCut, innerCut = set(), 0, 0, 0
    # layer registers of columns that pass a layer uncompressed stay up to the end of the carry cell
    # of the highest read bit (see `heapLiveFlipFlops`)
    regReach = None
    if hi < width - 1:
        reach = min(width - 1, _reach(hi))
        # a heap without any counter (rows of DSP tiles straight into the terminal chains): the
        # chains end 5 to 6 columns above the highest read bit (routed 44-bit Montgomery low
        # product: 533 sites for 529 here, 557 with the carry-cell rule). With counters in the
        # heap, also only in high columns, the carry-cell rule holds (routed 32 x 32 read 0..32
        # with a 6 x 6 LUT product at column 52: 50 to 53 sites for 47, 29 with the short reach).
        if heapLuts(heights)[0] == 0:
            reach = min(reach, hi + PLAIN_REACH)
        regReach = min(width - 1, (hi // CARRY_BLOCK + 1) * CARRY_BLOCK - 1)
    else:
        reach = hi
    dlyOf = {op.source.name: op.result.name for op in module.ops if isinstance(op, IR.Delay)}
    # the highest heap input column that still reaches a read bit, from the compressor the generator
    # writes (`heapLive`: counters and carry cells kept whole). A DSP tile whose lowest product bit
    # lies above it drives nothing that stays, and synthesis removes it.
    # Exact since gap step 4: the live inputs come from the text of the compressor the generator
    # writes (`heapNetLive`), and a tile stays when one of its product bits is one of them.
    liveSignals = None
    if hi < width - 1:
        from ..core.heapcount import heapNetLive
        cols = IR.lower_bitheap(top.terms, width, top.sign_mode)
        if max(heights, default=0) > 2:
            liveIn = heapNetLive(heights, tuple(heap_reg_flags(heights, top.latency)), lo, hi)['inputs']
        else:
            # two rows: a plain adder, bit k of the sum needs the columns up to k
            liveIn = {(c, k) for c, bits in enumerate(cols) if c <= hi for k in range(len(bits))}
        liveSignals = {cols[c][k].signal.name for c, k in liveIn
                       if c < len(cols) and k < len(cols[c]) and cols[c][k].signal is not None}
    live = liveRanges(module, top, need, reach)
    # registers stay to the end of the carry cell of the highest read bit, the LUT chains one cell
    # further (routed, 22 x 22 Booth core of a 44-bit Karatsuba split read 0..44: 431 cells and 134
    # registers; 448 cells with the chain range, 123 registers with the register range)
    liveReg = liveRanges(module, top, need, regReach) if regReach is not None else live
    boothDelta = 0
    oneBit = set()
    for op in module.ops:
        if (isinstance(op, IR.LutMult) and not isinstance(op, IR.LutPP)
                and min(op.a.width, op.b.width) > _smallMultMax()):
            # a Booth core: the cells the generator writes (partial products one LUT5 / LUT6_2
            # each, counters, adder), trimmed to the bits that reach live columns. The search
            # priced it with paired partial products (`estimate_bmult_luts`); the routed netlist
            # has one site per primitive (measured, 22 x 22 inside a 44-bit Karatsuba split:
            # 454 sites and 174 registers for 455 and 186 here; the price was 355).
            from dsp_multiplier.common.lut_cost import estimate_bmult_luts
            from ..core.emitcount import LUT_PACK
            pa, pb, flags = boothCore(op)
            est = estimate_bmult_luts(op.a.width, op.b.width, a_signed=False, b_signed=False).total
            rng = live.get(op.result.name)
            c = boothCounts(pa, pb, flags, *rng) if rng else {'pp': 0, 'comp': 0, 'term': 0, 'ff': 0}
            boothDelta += round((c['pp'] + c['comp'] + c['term']) / LUT_PACK) - est
            rngReg = liveReg.get(op.result.name)
            parts[str(op.result)] = (boothCounts(pa, pb, flags, *rngReg)['ff'] if rngReg else 0) if rng else 0
            continue
        if isinstance(op, IR.LutPP):
            # Booth partial products for a heap (`inner_backends._write_pp_inner`): one LUT5 or
            # LUT6_2 per cell of `Bmult_bitheap_RTL_gen`, one site each, and one register per bus
            # bit and stage; a cell stays when one of its bits lands in a live column. The search
            # priced paired cells (measured, 6 x 32 and 8 x 34 beside two DSPs: 97 and 137 sites
            # for 98 and 138 cells here; the prices were 68 and 90).
            from dsp_multiplier.common.lut_cost import estimate_bmult_luts, booth_partial_products
            from ..core.heapcount import boothPpLayout
            from ..core.emitcount import LUT_PACK
            pa = op.a.width + (0 if op.a.signed else 1)
            pb = op.b.width + (0 if op.b.signed else 1)
            lay = booth_partial_products(pa, pb)
            est = estimate_bmult_luts(op.a.width, op.b.width, a_signed=False, b_signed=False).partial_products
            cells = bitsKept = 0
            for hp in heaps:
                rng = live.get(hp.result.name)
                for t in hp.terms:
                    if t.pp_columns is None or t.signal.name != op.result.name or rng is None:
                        continue
                    for kind, bits in boothPpLayout(lay.opa_width, lay.opb_width, lay.opb_extended):
                        keep = sum(1 for col, _ in bits if rng[0] <= t.weight + col <= rng[1])
                        bitsKept += keep
                        cells += 1 if keep and kind != 'wire' else 0
            boothDelta += round(cells / LUT_PACK) - est
            parts[str(op.result)] = op.latency * bitsKept
            continue
        if isinstance(op, IR.LutMult) and op.latency > 0 and hi < width - 1:
            # a LUT partial product keeps only the bits that land in live columns
            wgt = weightOf.get(op.result.name, weightOf.get(dlyOf.get(op.result.name)))
            if wgt is not None and parts.get(str(op.result), 0):
                keepBits = sum(1 for i in range(op.result.width) if need <= wgt + i <= reach)
                full = parts[str(op.result)]
                # the registers of a one-bit row (and of its alignment delay) stay for one carry
                # cell above the highest read bit (routed low products of 32 / 40 / 48 / 54 / 56
                # bits: 10, 5, 4, 8, 8 registers for 8 here; the chain range gave 16, 7, 16, 10, 16)
                regBits = keepBits
                if min(op.a.width, op.b.width) == 1 and regReach is not None:
                    oneReach = min(reach, hi + CARRY_BLOCK - 1)
                    regBits = sum(1 for i in range(op.result.width) if need <= wgt + i <= oneReach)
                    oneBit.add(op.result.name)
                parts[str(op.result)] = min(full, op.latency * regBits)
                if min(op.a.width, op.b.width) == 1:
                    lutCut += op.result.width - keepBits
                else:
                    # a small LUT multiplier out of reach of the read bits is removed with them
                    from dsp_multiplier.common.lut_cost import estimate_bmult_luts
                    tot = estimate_bmult_luts(op.a.width, op.b.width, a_signed=False, b_signed=False).total
                    lutCut += round(tot * (1 - keepBits / op.result.width))
            continue
        if not isinstance(op, IR.DspTile):
            continue
        wgts = [w for nm, w in weightOf.items() if nm == op.result.name or srcOf.get(nm) == op.result.name]
        fam, blocks = DM.dsp_family(op.params, op.impl_id)
        if fam == 'k2' and wgts and hi < width - 1:
            # Karatsuba 2x2 tile under a truncated read (measured, run-time Barrett 44 bits, low
            # product): the P_hi alignment keeps the bits up to 3 columns above the live ones, the
            # adder result register the live ones; P_lo and P[21:0] stay.
            cutFf, cutL = _k2Trim(op, _reach(hi) - min(wgts))
            parts[str(op.result)] = max(0, parts.get(str(op.result), 0) - cutFf)
            lutCut += cutL
            continue
        if fam == 'chain' and wgts and need > min(wgts):
            # the low product words of a chain leave it through fabric registers (`low<k>_d<i>`):
            # those below the first column that is read or makes a carry are removed (routed
            # 48-bit run-time Barrett, high product read 51..99, first carry column 26: 0 of 23).
            from rtl_gen.dsp_multiplier.dsp.dsp_rtl_gen import chain_plan, PITCH
            cfg = DM.exact_dsp_config(fam, blocks, op.latency, label=op.impl_id)['config']
            pl = chain_plan(cfg, blocks)
            dead = sum(pl['out_dly'][k] * sum(1 for i in range(PITCH) if min(wgts) + PITCH * k + i < need)
                       for k in range(blocks - 1))
            parts[str(op.result)] = max(0, parts.get(str(op.result), 0) - dead)
        if not wgts or liveSignals is None:
            continue
        if op.result.name in liveSignals or any(nm in liveSignals for nm, s in srcOf.items() if s == op.result.name):
            continue
        if fam not in ('single', 'chain'):
            continue
        gone.add(op.result.name)
        dspGone += blocks
        parts[str(op.result)] = 0
    for op in module.ops:
        if isinstance(op, IR.Delay) and op.source.name in gone:
            parts[str(op.result)] = 0
        elif isinstance(op, IR.Delay):
            wgt = weightOf.get(op.result.name)
            bits = op.result.width
            if wgt is not None:
                top_ = min(reach, hi + CARRY_BLOCK - 1) if op.source.name in oneBit else reach
                bits = sum(1 for i in range(op.result.width) if need <= wgt + i <= top_)
            s, f = delayCells(op.cycles, bits, False, copyReader=True)
            parts[str(op.result)] = f
            srl += s
        elif op is top and op.latency > 0:
            if max(heights, default=0) <= 2:
                parts[str(op.result)] = op.latency * (hi - lo + 1)
            else:
                flags = heap_reg_flags(heights, op.latency)
                parts[str(op.result)] = heapLiveFlipFlops(heights, flags, lo, hi, regReach)
        elif isinstance(op, IR.BitHeap) and hi < width - 1 and op.result.name in live:
            # a heap that feeds the final one: only the columns that reach live columns stay
            a, b = live[op.result.name]
            hs = tuple(DM._bitheap_heights(op))
            if b < len(hs) - 1 and max(hs, default=0) > 2:
                if op.latency > 0:
                    parts[str(op.result)] = heapLiveFlipFlops(hs, heap_reg_flags(hs, op.latency), a, b)
                c1, t1 = heapLuts(hs)
                c2, t2 = heapLuts(tuple(h if a <= i <= b else 0 for i, h in enumerate(hs)))
                innerCut += max(0, c1 + t1 - c2 - t2)
    ff = sum(parts.values())
    # LUTs of the final sum: the compressor over the columns that stay (the first carry column, or
    # the lowest read one, up to `reach`), as the back end prices it; the rest of the fabric logic
    # is kept. Measured (run-time Barrett 28 / 44 / 64 bits): high product 86 / 86 / 188 cells for
    # 83 / 86 / 188; low product 24 compressor cells at 28 bits for 25.
    comp, term = heapLuts(heights) if max(heights, default=0) > 2 else (0, sum(1 for h in heights if h >= 2))
    sumLut = min(int(lutTotal), comp + term)
    kept = sumLut
    if max(heights, default=0) > 2 and (need > 0 or reach < width - 1):
        comp2, term2 = heapLuts(tuple(h if need <= i <= reach else 0 for i, h in enumerate(heights)))
        kept = min(sumLut, comp2 + term2)
    elif max(heights, default=0) <= 2:
        kept = min(sumLut, sum(1 for i, h in enumerate(heights) if h >= 2 and need <= i <= reach))
    lut = int(lutTotal) - sumLut + kept
    lut = max(0, lut - lutCut - innerCut + boothDelta)
    # a one-bit row (operand AND one bit, `LutMult` with a 1-bit side) is one LUT2 per bit and two
    # of them share a site (routed 48-bit run-time Barrett high product: 26 and 24 cells in 13 and
    # 12 sites; 32 / 44 / 54 / 64 bits: 10, 7, 8, 7 cells in 5, 4, 4, 4 sites): counted as `pair`
    pair = 0
    for op in module.ops:
        if (isinstance(op, IR.LutMult) and not isinstance(op, IR.LutPP)
                and min(op.a.width, op.b.width) == 1):
            wgt = weightOf.get(op.result.name, weightOf.get(dlyOf.get(op.result.name)))
            if wgt is None:
                continue
            pair += sum(1 for i in range(max(op.a.width, op.b.width)) if need <= wgt + i <= reach)
    out.update(lut=lut, srl=srl, ff=ff, parts=parts, dsp=int(dspCount) - dspGone, pair=min(pair, lut))
    out['note'] = (out['note'] + f' sum cols {need}..{hi} of {width}').strip()
    return out
