'''Register and LUT counts of the back end's bit heap compressor, taken from the same layer walk
the RTL generator does (`rtl_gen.compressor.compressor_gen`), without emitting RTL.

The compressor of a heap with column heights `heights` has `L` compression layers and one terminal
adder. Its register flags are a list of `L + 1` booleans (`lut_timing.heap_reg_flags`). A set flag
on layer `i` registers every bit of the heap after that layer (all columns, not only the output
width); the last flag registers the sum (`comp_out`).

    heapLayerBits(heights)        -> (bits after layer 0, ..., bits after layer L-1, width of the sum)
    heapLayerCols(heights)        -> the same per column
    heapLiveFlipFlops(heights, flags, lo, hi) -> registers left when only bits lo..hi are read
    heapFlipFlops(heights, flags) -> registers the compressor holds with these flags
    heapLuts(heights)             -> (compression LUTs, terminal adder LUTs)

Read-only on the back end: nothing here changes what the generator emits.
'''
from __future__ import annotations

import contextlib
import io
import re
from functools import lru_cache


def _paths():
    from ..multiplier import DspMultiplierScheme  # noqa: F401  (puts versal_arith on sys.path)


@lru_cache(maxsize=1024)
def _walk(heights: tuple) -> tuple:
    '''(per-layer column sizes, per-layer origins). origins[i][c][k] is the heap input (column, index)
    that bit k of column c after layer i still is (it passed every layer so far untouched), or None
    when a counter made it.'''
    _paths()
    import contextlib
    import io
    from dsp_multiplier.common.lut_cost import (BitHeap, compressAll, formGPCChain,
                                                 merge_last_stage)
    from rtl_gen.layer import layer_admin, simulate_layers
    sumMax = sum(h << c for c, h in enumerate(heights))
    width = sumMax.bit_length()
    if max(heights, default=0) <= 2:
        return ((1,) * width,), ()           # a plain adder: only the sum can be registered
    with contextlib.redirect_stdout(io.StringIO()):
        bh = BitHeap(width, 0)
        for c, h in enumerate(heights):
            bh.add_bits(c, h)
        last, raw = compressAll(bh, 0, width - 1, False, False)
        counters = formGPCChain(raw)
        first = [heights[c] if c < len(heights) else 0 for c in range(width)]
        merged, reduced = False, [[[0]]]
        if len(counters) >= 2:
            merged, reduced = merge_last_stage(last_compression_layer_counter_list=counters[-1],
                                               last_compression_layer_bitheap=last)
            if merged:
                widths, over = simulate_layers(counters, first, True, reduced)
                if over or max(widths, default=0) > 4:
                    merged = False
        layers = len(counters) - (1 if merged else 0)
        cols, origins = [], []
        inputs = list(first)
        origin = [[(c, k) for k in range(n)] for c, n in enumerate(first)]
        for no in range(layers):
            merging = merged and no == layers - 1
            chains = [list(c) for c in counters[no]]
            mchains = [list(c) for c in counters[-1]] if merging else []
            outputs, _, _, assign = layer_admin(inputs, chains, merging, mchains, reduced)
            nxt = [[None] * int(n) for n in outputs]
            for c, pairs in enumerate(assign):
                for old, new in pairs:
                    if old < len(origin[c]) and new < len(nxt[c]):
                        nxt[c][new] = origin[c][old]
            origin = nxt
            cols.append(tuple(int(v) for v in outputs))
            origins.append(tuple(tuple(col) for col in origin))
            inputs = outputs
    return tuple(cols) + ((1,) * width,), tuple(origins)


def heapLayerCols(heights: tuple) -> tuple:
    '''Per compression layer, the bits each column holds after it; last entry: one bit per column
    of the sum. `((1,) * width,)` for a plain adder (max height <= 2).'''
    return _walk(tuple(int(h) for h in heights))[0]


def heapLayerOrigins(heights: tuple) -> tuple:
    '''Per compression layer and column, for each bit the heap input (column, index) it still is,
    or None when a counter made it. A registered bit that is still a heap input is a plain copy of
    that input: synthesis merges copies of one signal bit into one register.'''
    return _walk(tuple(int(h) for h in heights))[1]


def heapLayerBits(heights: tuple) -> tuple:
    '''Bits a register after each compression layer would hold, then the width of the sum.'''
    return tuple(sum(c) for c in heapLayerCols(tuple(int(h) for h in heights)))


def firstCarryColumn(heights) -> int:
    '''Lowest column that can send a carry up (height >= 2); the heap width if there is none.
    Columns below it are wires: a consumer that does not read them leaves them unused.'''
    for c, h in enumerate(heights):
        if h >= 2:
            return c
    return len(heights)


def heapLiveFlipFlops(heights, flags, lo: int, hi: int, reach: int | None = None) -> int:
    '''Registers of the compressor that survive synthesis when the consumers read only bits
    lo..hi of the sum (measured, V80 part, Vivado 2025.1): columns above `hi` are removed, columns
    below the first carry column are removed unless read, columns between that one and `lo` keep
    their layer registers (they make the carry) but lose the register of the sum. `reach`: end of
    the carry cell of `hi`; columns above `hi` that pass a layer uncompressed keep that layer's
    registers up to there, because they feed the terminal chain directly (routed 32 x 32 read
    0..32, three rows: 109 registers in the heap, 104 here, 83 without; routed 44-bit Montgomery
    read 0..43, four rows: 400 for 398). Compressed columns above `hi` are removed with their
    counters (routed 32-bit Barrett: 196 for 188).'''
    heights = tuple(int(h) for h in heights)
    cols = heapLayerCols(heights)
    flags = tuple(bool(f) for f in flags)
    if len(flags) != len(cols):
        raise ValueError(f'heap has {len(cols) - 1} layer(s) plus the adder; got {len(flags)} flags')
    need = min(lo, firstCarryColumn(heights))
    total = 0
    for i, (col, f) in enumerate(zip(cols, flags)):
        if not f:
            continue
        last = i == len(cols) - 1
        first = lo if last else need
        total += sum(v for c, v in enumerate(col) if first <= c <= hi)
        if not last and reach is not None:
            src = heights if i == 0 else cols[i - 1]
            for c in range(hi + 1, min(reach, len(col) - 1) + 1):
                if c >= len(src) or col[c] != src[c]:
                    break
                total += col[c]
    return total


def heapFlipFlops(heights, flags, outWidth: int | None = None) -> int:
    '''Registers of the compressor with the given flags (`len(flags)` = layers + 1).
    `outWidth` trims the registered sum to the bits the consumer reads.'''
    bits = heapLayerBits(tuple(heights))
    flags = tuple(bool(f) for f in flags)
    if len(flags) != len(bits):
        raise ValueError(f'heap has {len(bits) - 1} layer(s) plus the adder; got {len(flags)} flags')
    total = 0
    for i, (b, f) in enumerate(zip(bits, flags)):
        if not f:
            continue
        if i == len(bits) - 1 and outWidth is not None:
            b = min(b, outWidth)
        total += b
    return total


def heapLuts(heights) -> tuple:
    '''(compression LUTs, terminal adder LUTs) of the compressor, as `lut_cost` counts them.'''
    _paths()
    from dsp_multiplier.common.lut_cost import estimate_cmp_luts
    r = estimate_cmp_luts(tuple(int(h) for h in heights))
    return r.compression, r.terminal_adder


# ---------------------------------------------------------------------------------------------
# Radix-4 Booth multiplier on LUTs (`rtl_gen.booth_mult.Bmult_RTL_gen`): the cells the generator
# writes, counted with its own loops and without emitting RTL.
# ---------------------------------------------------------------------------------------------
def boothShape(widthA: int, widthB: int) -> tuple:
    '''(OPA width, OPB width, OPB sign-extended, heap heights with the constant ones) of
    `Bmult_RTL_gen(widthA, widthB)`: odd widths go to even, the wider operand is recoded.'''
    opa = widthA + (widthA & 1)
    opb = widthB + (widthB & 1)
    ext = bool(widthB & 1)
    if opb < opa:
        opb, ext, opa = opa, bool(widthA & 1), widthB
    else:
        opa = widthA
    heights = [0] * (opa + opb)
    for i in range(opb // 2):
        for j in range(opa + 2):
            heights[2 * i + j] += 1
        heights[2 * i] += 1
    heights[opa] += 1
    return opa, opb, ext, tuple(heights)


def boothPpLayout(opa: int, opb: int, ext: bool) -> tuple:
    """The partial-product cells of `Bmult_bitheap_RTL_gen`, in the order it writes them:
    (kind, heap bits it drives as (column, index in the column)). kind 'LUT5' | 'LUT6_2' | 'wire'
    (the sign bit of a row, a plain copy of an OPB bit). Row 0 pairs its bits in LUT6_2 cells; the
    other rows use one LUT5 per bit except the two ends (one LUT6_2 each) and, when OPB was
    sign-extended, the last row (pairs in LUT6_2 cells)."""
    rows = opb // 2
    ptr = [0] * (opa + opb)
    cells = []

    def take(*cols):
        out = tuple((c, ptr[c]) for c in cols)
        for c in cols:
            ptr[c] += 1
        return out
    for j in range(0, opa, 2):
        cells.append(('LUT6_2', take(j, j + 1)))
    if opa % 2 == 0:
        cells.append(('LUT5', take(opa)))
    for i in range(1, rows):
        reduced = ext and i == rows - 1
        for j in range(opa + 2):
            if j == 0 or j == opa - 1:
                cells.append(('LUT6_2', take(2 * i + j, 2 * i + j + 1)))
            elif j in (1, opa, opa + 1):
                continue
            elif reduced and j % 2 == 0 and j + 1 <= opa - 2:
                cells.append(('LUT6_2', take(2 * i + j, 2 * i + j + 1)))
            elif reduced and j % 2 == 1 and j <= opa - 2:
                continue
            else:
                cells.append(('LUT5', take(2 * i + j)))
    for i in range(rows):
        cells.append(('wire', take(2 * i)))
    return tuple(cells)


def boothOperandLoads(widthA: int, widthB: int) -> tuple:
    """(loads of every bit of port A, loads of every bit of port B) in the partial-product cells
    of `Bmult_RTL_gen(widthA, widthB)`. A bit of the recoded operand (OPB) is read by every cell
    of its row, and an odd bit also by the row above; a bit of the other operand by two cells
    per row. A driver with `max_fanout` is replicated on these loads at synthesis, before the
    cells of unread product bits are removed (measured, 64-bit Barrett `bq`, 66 x 66: odd bits
    9 or 10 copies, even bits 5, for 134 and 67 loads at max_fanout 16)."""
    opa, opb, ext, _ = boothShape(widthA, widthB)
    swapped = (widthB + (widthB & 1)) < (widthA + (widthA & 1))
    rows = opb // 2
    cellsOf = [(opa + 1) // 2 + (1 if opa % 2 == 0 else 0)]
    for i in range(1, rows):
        reduced = ext and i == rows - 1
        cellsOf.append(2 + (opa - 2) // 2 if reduced else opa - 1)
    recoded = []
    for k in range(opb):
        own = [k // 2] + ([(k + 1) // 2] if k % 2 else [])
        recoded.append(sum(cellsOf[r] for r in own if r < rows))
    other = [2 * rows] * opa
    la, lb = (recoded, other) if swapped else (other, recoded)
    return tuple(la[:widthA]) + (0,) * max(0, widthA - len(la)), tuple(lb[:widthB]) + (0,) * max(0, widthB - len(lb))


def boothPpCells(opa: int, opb: int, ext: bool) -> tuple:
    """(LUT5 cells, LUT6_2 cells, partial-product bits) of `Bmult_bitheap_RTL_gen`. The LUT5
    cells sit one per site: the flow reads no LUTNM for them and the tool does not pair them
    (measured: 452 cells on 451 sites, Booth 31 x 31)."""
    cells = boothPpLayout(opa, opb, ext)
    return (sum(1 for k, _ in cells if k == 'LUT5'), sum(1 for k, _ in cells if k == 'LUT6_2'),
            sum(len(b) for _, b in cells))


# ---------------------------------------------------------------------------------------------
# Which part of a compressor survives when the consumers read only bits lo..hi of the sum.
# ---------------------------------------------------------------------------------------------
@lru_cache(maxsize=512)
def _structure(heights: tuple) -> tuple:
    """(layers, terminal widths). layers[i] = (chains, assigns): chains is a tuple of chains, a
    chain a tuple of counters (LUTs, input bits, output bits) with bits as (column, index); assigns
    are the bits that pass the layer untouched as ((column, old index), (column, new index)).
    The same bookkeeping as `rtl_gen.layer.layer_admin`."""
    _paths()
    import contextlib
    import io
    from dsp_multiplier.common.lut_cost import BitHeap, compressAll, formGPCChain, merge_last_stage
    from rtl_gen.layer import simulate_layers
    width = sum(h << c for c, h in enumerate(heights)).bit_length()
    first = [heights[c] if c < len(heights) else 0 for c in range(width)]
    if max(heights, default=0) <= 2:
        return (), tuple(first)
    with contextlib.redirect_stdout(io.StringIO()):
        bh = BitHeap(width, 0)
        for c, h in enumerate(heights):
            bh.add_bits(c, h)
        last, raw = compressAll(bh, 0, width - 1, False, False)
        counters = formGPCChain(raw)
        merged, reduced = False, [[[0]]]
        if len(counters) >= 2:
            merged, reduced = merge_last_stage(last_compression_layer_counter_list=counters[-1],
                                               last_compression_layer_bitheap=last)
            if merged:
                widths, over = simulate_layers(counters, first, True, reduced)
                if over or max(widths, default=0) > 4:
                    merged = False
    nlay = len(counters) - (1 if merged else 0)
    layers, inputs = [], list(first)
    for no in range(nlay):
        merging = merged and no == nlay - 1
        chains = [list(c) for c in counters[no]]
        norig = len(chains)
        if merging:
            chains += [list(c) for c in counters[-1]]
        ip, op = [0] * width, [0] * width
        out = []
        for k, chain in enumerate(chains):
            cs = []
            for i, cnt in enumerate(chain):
                ci = list(cnt.inputs)
                ci[-1] -= 1 if i else 0
                ins = []
                for j in range(len(ci)):
                    col = cnt.applied_column + j
                    n = ci[len(ci) - 1 - j]
                    red = reduced[k - norig][i][len(ci) - 1 - j] if k >= norig else 0
                    ins += [(col, b) for b in range(ip[col], ip[col] + n - max(0, red))]
                    ip[col] += n - red
                co = list(cnt.outputs)
                co[0] -= 1 if i != len(chain) - 1 else 0
                outs = []
                for j in range(len(co)):
                    col = cnt.applied_column + j
                    n = co[len(co) - 1 - j]
                    outs += [(col, b) for b in range(op[col], op[col] + n)]
                    op[col] += n
                cs.append((int(cnt.LUT_cost), tuple(ins), tuple(outs)))
            out.append(tuple(cs))
        assign = []
        for c in range(width):
            for j in range(max(0, inputs[c] - ip[c])):
                assign.append(((c, ip[c] + j), (c, op[c] + j)))
            op[c] += max(0, inputs[c] - ip[c])
        layers.append((tuple(out), tuple(assign)))
        inputs = list(op)
    return tuple(layers), tuple(inputs)


CARRY_BLOCK = 8        # a carry runs through LOOKAHEAD8 cells; the tool keeps or drops a whole cell


@lru_cache(maxsize=2048)
def heapLive(heights: tuple, lo: int, hi: int) -> dict:
    """The compressor of `heights` after synthesis when only bits lo..hi of the sum are read
    (measured on routed netlists, V80 part, Vivado 2025.1; Booth 66 x 65 read up to bit 64:
    compression 794 LUT sites against 775 here, adder 136 against 135, registers 651 against 662).

    A counter stays when one of its outputs is read by something that stays. Counters of one chain
    share LOOKAHEAD8 carry cells of `CARRY_BLOCK` LUT positions: the chain stays up to the end of
    the carry cell of its highest live counter. The terminal adder stays up to the end of the carry
    cell of bit `hi`; with a column of four bits it is two adders in a row, and the first one runs a
    carry cell further. Columns below the first column that can carry are wires.

    {'comp': compression LUTs, 'term': adder LUTs, 'inputs': frozenset of live heap inputs
     (column, index), 'layer': live bits after each compression layer, 'top': highest column of the
     terminal adder that stays, 'top2': the same of its second adder, 'start': its first column}"""
    _paths()
    from dsp_multiplier.common.lut_cost import _terminal_adder_lut_count_from_terminal_inputs as termLuts
    layers, term = _structure(tuple(int(h) for h in heights))
    c0 = next((c for c, v in enumerate(term) if v >= 2), len(term))
    need = min(lo, c0)
    hi = min(hi, len(term) - 1)
    top1 = top2 = hi
    tl = 0
    if hi >= c0:
        two = max(term) >= 4
        s2 = c0 + 1 if two else c0
        top2 = min(len(term) - 1, s2 + CARRY_BLOCK * -(-(hi - s2 + 1) // CARRY_BLOCK) - 1)
        top1 = min(len(term) - 1, c0 + CARRY_BLOCK * -(-(top2 - c0 + 1) // CARRY_BLOCK) - 1) if two else top2
        tl = termLuts(tuple(v if c <= top1 else 0 for c, v in enumerate(term))) - (top1 - top2)
    live = {(c, k) for c in range(need, top1 + 1) for k in range(term[c])}
    comp, layerBits = 0, []
    for chains, assign in reversed(layers):
        layerBits.append(len(live))
        prev = set()
        for chain in chains:
            hit = [i for i, cnt in enumerate(chain) if any(o in live for o in cnt[2])]
            if not hit:
                continue
            pos, end, top = 0, None, hit[-1] + 1
            for i, cnt in enumerate(chain):
                pos += cnt[0]
                if i == hit[-1]:
                    end = CARRY_BLOCK * -(-pos // CARRY_BLOCK)
                if end is not None and pos <= end:
                    top = i + 1
            for cnt in chain[:top]:
                comp += cnt[0]
                prev.update(cnt[1])
        for old, new in assign:
            if new in live:
                prev.add(old)
        live = prev
    return {'comp': comp, 'term': tl, 'inputs': frozenset(live), 'layer': tuple(reversed(layerBits)),
            'top': top1, 'top2': top2, 'start': c0}


def boothCounts(widthA: int, widthB: int, flags, lo: int, hi: int) -> dict:
    """Cells of one Booth multiplier whose consumers read bits lo..hi of the product, with the
    register flags `flags` (partial products, each compression layer, the sum).
    {'pp': LUT sites of the partial products, 'comp': compression LUTs, 'term': adder LUTs,
     'ff': registers}. The partial-product cells and the counters are primitives: one site each."""
    opa, opb, ext, heights = boothShape(widthA, widthB)
    hi = min(hi, len(heights) - 1)
    lv = heapLive(heights, lo, hi)
    cells = boothPpLayout(opa, opb, ext)
    alive = [(k, [b for b in bits if b in lv['inputs']]) for k, bits in cells]
    pp = sum(1 for k, bits in alive if bits and k != 'wire')
    flags = tuple(bool(f) for f in flags)
    ff = sum(len(bits) for _, bits in alive) if flags and flags[0] else 0
    if len(flags) > 1:
        if len(flags) - 2 != len(lv['layer']):
            raise ValueError(f'Booth {widthA}x{widthB}: {len(lv["layer"])} layer(s), got {len(flags)} flags')
        ff += sum(b for b, f in zip(lv['layer'], flags[1:-1]) if f)
        ff += (hi - lo + 1) if flags[-1] else 0
    return {'pp': pp, 'comp': lv['comp'], 'term': lv['term'], 'ff': ff}


# ---------------------------------------------------------------------------------------------
# Liveness of the compressor from the text the generator writes (gap work step 4).
#
# `heapNetLive` builds the compressor body in memory with the generator's own functions (the calls
# of `rtl_gen.compressor.compressor_RTL_gen`, no file written), reads it as a bit-level netlist and
# returns what stays when only bits lo..hi of `comp_out` are read. Three rules, all seen on routed
# netlists (gap/RESULTS.md, step 4):
#   1. a counter stays when one of its outputs reaches a read bit;
#   2. a LOOKAHEAD8 carry cell stays whole: when an output of a counter on it is used, the cell
#      and every counter on it stay (with their inputs). A counter that stays only as a member of
#      a cell does not keep the next cell it reaches into (routed: a counter over two cells);
#   3. a vector the generator marks `dont_touch` (`rtl_gen.utils.pin_chain_cin_nets`: the input of
#      the first counter of a first-layer chain with a carry cell) keeps its loads: that counter
#      and the carry cell its carry-in feeds.
# Nothing here depends on a width or a design: the netlist is the emitted one.
_NL_DECL = re.compile(r'^\s*(?:\(\*[^)]*\*\)\s*)?(?:input|output)?\s*logic\s*(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*(\w+)\s*[;,]?\s*$')
_NL_REF = re.compile(r"(\d+'[bdh][0-9a-fA-F_]+)|(\w+)\s*(?:\[\s*(\d+)\s*(?::\s*(\d+)\s*)?\])?")
_NL_OUT = re.compile(r'^(O|CY|PROP|COUT\w*)$')
_NL_INST = re.compile(r'(\w+)\s*(?:#\s*\((?:[^()]|\([^()]*\))*\)\s*)?(\w+)\s*\(((?:\s*\.\w+\s*\([^()]*\)\s*,?)+)\s*\)\s*;')
_NL_ASSIGN = re.compile(r'(assign\s+)?(\w+(?:\s*\[[^\]]+\])?)\s*(<?=)\s*([^;]+);')


def _nlSplit(s: str) -> list:
    out, depth, cur = [], 0, ''
    for ch in s:
        depth += (ch == '{') - (ch == '}')
        if ch == ',' and depth == 0:
            out.append(cur)
            cur = ''
        else:
            cur += ch
    if cur.strip():
        out.append(cur)
    return out


def _nlBits(expr: str, widths: dict) -> list:
    '''Bits of a reference or concatenation, most significant first; None for a constant bit.'''
    expr = expr.strip()
    if expr.startswith('{') and expr.endswith('}'):
        return [b for part in _nlSplit(expr[1:-1]) for b in _nlBits(part, widths)]
    m = _NL_REF.fullmatch(expr)
    if not m:
        raise ValueError(f'heapNetLive: expression not understood: {expr[:80]}')
    if m.group(1):
        return [None] * int(m.group(1).split("'")[0])
    name, a, b = m.group(2), m.group(3), m.group(4)
    if a is None:
        if name not in widths:
            raise ValueError(f'heapNetLive: signal without declaration: {name}')
        hi, lo = widths[name]
        return [(name, i) for i in range(hi, lo - 1, -1)]
    if b is None:
        return [(name, int(a))]
    return [(name, i) for i in range(int(a), int(b) - 1, -1)]


@lru_cache(maxsize=512)
def _heapNetlist(heights: tuple, flags: tuple) -> tuple:
    '''The compressor of `heights` with register flags `flags` as (widths, pinned bits, dep, insts,
    feeds, drv, width): `dep` maps a bit to the bits it copies or adds, `insts` are the primitive
    instances (name, module, input bits, output bits), `feeds` maps a counter to its carry cells.'''
    _paths()
    from dsp_multiplier.common.lut_cost import BitHeap, compressAll, formGPCChain
    from rtl_gen.compressor import compressor_gen
    from rtl_gen.utils import merge_bit_assigns, pin_chain_cin_nets
    width = sum(h << c for c, h in enumerate(heights)).bit_length()
    with contextlib.redirect_stdout(io.StringIO()):
        bh = BitHeap(width, 0)
        for c, h in enumerate(heights):
            bh.add_bits(c, h)
        last, raw = compressAll(bh, 0, width - 1, False, True)
        counters = formGPCChain(raw)
        first = [heights[c] if c < len(heights) else 0 for c in range(width)]
        rtl, _ = compressor_gen(counter_list_rearranged=counters, first_layer_inputs=first,
                                comp_output_name='comp_out', comp_output_width=width,
                                last_compression_layer_bitheap=last, reg_flag_list=list(flags))
        rtl = pin_chain_cin_nets(merge_bit_assigns(rtl))
    widths, pinned = {'comp_out': (width - 1, 0)}, set()
    for line in rtl.split('\n'):
        m = _NL_DECL.match(line)
        if m:
            widths[m.group(3)] = (int(m.group(1) or 0), int(m.group(2) or 0))
            if 'dont_touch' in line:
                pinned.add(m.group(3))
    text = re.sub(r'//[^\n]*', '', rtl)
    insts, dep = [], {}
    for m in _NL_INST.finditer(text):
        ins, outs = [], []
        for port, sig in re.findall(r'\.(\w+)\s*\(([^()]*)\)', m.group(3)):
            if not sig.strip() or port == 'clk':
                continue
            bits = [x for x in _nlBits(sig, widths) if x]
            (outs if _NL_OUT.match(port) else ins).extend(bits)
        insts.append((m.group(2), m.group(1), tuple(ins), tuple(outs)))
    for m in _NL_ASSIGN.finditer(text):
        if m.group(3) == '=' and not m.group(1):
            continue                                   # a port connection or parameter, not an assign
        lhs = _nlBits(m.group(2), widths)
        if '+' in m.group(4):
            # the behavioural terminal adder: bit k of the sum needs bits 0..k of the operands
            ops = [list(reversed(_nlBits(t, widths))) for t in m.group(4).split('+')]
            for k, lb in enumerate(reversed(lhs)):
                dep[lb] = [b for o in ops for b in o[:k + 1] if b]
            continue
        rhs = _nlBits(m.group(4), widths)
        if len(rhs) != len(lhs):
            raise ValueError(f'heapNetLive: width mismatch in {m.group(0)[:100]}')
        for lb, rb in zip(lhs, rhs):
            if rb:
                dep[lb] = [rb]
    drv = {b: i for i, (_, _, _, outs) in enumerate(insts) for b in outs}
    feeds, members, carryIn = {}, {}, {}
    for i, (_, mod, ins, _) in enumerate(insts):
        if mod != 'LOOKAHEAD8':
            continue
        todo, seen = list(ins), set()
        members[i], carryIn[i] = set(), []
        while todo:
            b = todo.pop()
            if b in seen:
                continue
            seen.add(b)
            if b in dep:
                todo += dep[b]
            elif b in drv and insts[drv[b]][1] != 'LOOKAHEAD8':
                feeds.setdefault(drv[b], set()).add(i)       # a counter on this carry cell
                members[i].add(drv[b])
            else:
                carryIn[i].append(b)                         # the carry into the cell
    pin = {(n, i) for n in pinned for i in range(widths[n][1], widths[n][0] + 1)}
    grew = True
    while grew:                                        # plain copies of a pinned bit are that net
        grew = False
        for b, src in dep.items():
            if b not in pin and len(src) == 1 and src[0] in pin:
                pin.add(b)
                grew = True
    return widths, frozenset(pin), dep, tuple(insts), (feeds, members, carryIn), drv, width


@lru_cache(maxsize=4096)
def heapNetLive(heights: tuple, flags: tuple, lo: int, hi: int) -> dict:
    '''What stays of the compressor of `heights` (register flags `flags`, one per layer plus the
    terminal adder) when only bits lo..hi of its sum are read:
    {'inputs': frozenset of (column, index in the column) heap input bits that stay,
     'counters': {instance name: module} of the counters that stay, 'cells': carry cells,
     'bits': the live (signal, bit) set}.'''
    widths, pin, dep, insts, (feeds, members, carryIn), drv, width = _heapNetlist(tuple(heights), tuple(flags))
    todo = [('comp_out', i) for i in range(max(lo, 0), min(hi, width - 1) + 1)]
    kept, needed, cells = set(), set(), set()

    def keep(j):                       # the counter stays (its inputs with it)
        if j not in kept:
            kept.add(j)
            todo.extend(insts[j][2])

    def need(j):                       # an output of the counter is used: its carry cells stay whole
        if j in needed:
            return
        needed.add(j)
        keep(j)
        for c in feeds.get(j, ()):
            cell(c)

    def cell(c):
        if c in cells:
            return
        cells.add(c)
        todo.extend(carryIn[c])
        for j in members[c]:
            keep(j)

    for i, (_, mod, ins, _) in enumerate(insts):
        if any(b in pin for b in ins):
            cell(i) if mod == 'LOOKAHEAD8' else need(i)
    seen = set()
    while todo:
        b = todo.pop()
        if b in seen:
            continue
        seen.add(b)
        if b in dep:
            todo += dep[b]
        elif b in drv:
            j = drv[b]
            cell(j) if insts[j][1] == 'LOOKAHEAD8' else need(j)
    inputs = set()
    for name, i in seen:
        m = re.fullmatch(r'layer0_col(\d+)', name)
        if m:
            inputs.add((int(m.group(1)), i))
    return {'inputs': frozenset(inputs),
            'counters': {insts[i][0]: insts[i][1] for i in kept},
            'cells': len(cells),
            'bits': frozenset(seen)}


@lru_cache(maxsize=4096)
def heapPinnedInputs(heights: tuple, flags: tuple) -> tuple:
    '''The heap input bits (column, index in the column) that sit on a vector the generator marks
    `dont_touch` (`rtl_gen.utils.pin_chain_cin_nets`), one entry per pinned bit, from the compressor
    text. Constants tied inside the compressor are left out.'''
    widths, pin, dep, insts, _, drv, width = _heapNetlist(tuple(heights), tuple(flags))
    out = []
    for name, i in sorted(pin):
        if name.startswith('layer0_col') or (name, i) in drv:
            continue
        if len(dep.get((name, i), ())) == 1 and dep[(name, i)][0] in pin:
            continue                                   # a plain copy of a pinned bit: the same net
        b = (name, i)
        while b in dep and len(dep[b]) == 1:
            b = dep[b][0]
        m = re.fullmatch(r'layer0_col(\d+)', b[0])
        if m:
            out.append((int(m.group(1)), b[1]))
    return tuple(out)


def heapPinBuffers(heights, flags, sources) -> int:
    '''LUT1 buffers on the pinned vectors of a compressor (gap work step 5). A `dont_touch` net cannot be
    merged with another one, so when one signal bit feeds several pinned heap inputs (a constant
    multiplier: one operand bit per non-zero digit of the constant) only one of those nets is the
    signal itself and every other one is driven through a LUT1 (routed df_n256_shoup52, constant
    Shoup butterfly: quotient heap 207 counted, 214 routed; remainder heap 96 counted, 96 routed).
    `sources[column][index]` names the signal bit of a heap input (None for a constant); buffers =
    pinned bits with a signal - distinct signal bits among them. Zero for a heap whose inputs are
    all different signals (a variable multiplier).'''
    n, seen = 0, set()
    for c, i in heapPinnedInputs(tuple(heights), tuple(flags)):
        col = sources.get(c, ())
        if i >= len(col) or col[i] is None:
            continue
        n += 1
        seen.add(col[i])
    return n - len(seen)
