'''Area of a streaming (dataflow) NTT without a build: LUT, FF, DSP, BRAM36, URAM.

`inventory(scheme)` walks the operator spec the RTL generator reads (`StreamingNTT.getOperatorInterface`) in the
generator's own order (`rtl_gen.ntt.StreamNTT_RTL_gen`) and lists every part it emits: butterflies, balance delays,
exchange delay lines and muxes, twiddle tables, generators, the twist, modulus-table copies, tag registers, halvers,
input registers, port registers and the counter. Butterflies and multipliers are priced by the shared component models
(`resources()`, `flipFlops()`); everything else by the mapping rules below, each one a rule of Vivado 2025.1 on Versal
seen in the routed rows of `ntt_hw/experiments/overnight_2026-11-14/dataflow` (MODEL_ACCURACY.md lists the evidence).

    inventory(scheme, pipelineStages=1) -> [ {cls, what, n, lut, ff, dsp, bram36, uram, srl, lutram}, ... ]  (totals of n units)
    totals(parts)                       -> {lut, ff, dsp, bram36, uram, au, byClass}
    structure(scheme, pipelineStages=1) -> {'delays': [(W, D), ...], 'tables': n, 'mtabs': n, 'butterflies': n, ...}
                                           (what `structureOfRtl(top.sv)` counts in the emitted RTL: must be equal)

Nothing here changes what the generator emits.
'''
from __future__ import annotations

import re

# --- mapping rules (R1..R9) --------------------------------------------------------------------------------------
#: R1  a shift register shorter than this stays in flip-flops (Vivado -shreg_min_size 3)
SRL_MIN = 3
#: R2  two SRL16 share one LUT site (O5/O6), an SRLC32E takes a whole one
SRL16_PER_LUT = 2
#: R13 on/off (the gate prints the model with and without it)
TRIM = True
#: R13e for the compressor registers: off. Scaling them by a heap of the remaining bits removes too many (routed
#: `bq` registers, model without / with it: 36 bit 196 for 217 / 153, 44 bit 231 for 262 / 169, 60 bit 544 for
#: 525 / 362; 52 bit 380 for 439 / 375), so only tile and delay registers are trimmed
HEAP_CONST_TRIM = False
#: R3  the two 2:1 muxes of an exchange pair are LUT3s on the same select; part of them pack two per LUT site
MUX_PACK = 0.80
#: R4  delay lines of 64 cycles and more are block RAM (ram_style = "block" in the RTL): D - 1 words
RAM_DELAY = 64
#: R5  distributed RAM: RAM32M16 holds 14 bits in 8 LUTs up to 32 words, RAM64M8 7 bits in 8 LUTs per 64 words
#: R6  tables: deepest table Vivado keeps in LUTs (RAM: LUT RAM; ROM: LUT ROM), block RAM above; and the number of
#:     RAMB36 from which it takes URAM288 instead (see `memory`)
LUT_RAM_DEPTH = 64
#: a RAM (a table with a write port) stays in LUT RAM below this many bits: routed loadable rows of 2026-11-16 have
#: 128 x 62 (7,936 bits) and 160 x 32 in LUT RAM, and 128 x 64 (8,192 bits), 256 x 32 and 160 x 62 in block RAM
LUT_RAM_BITS_RAM = 8192
LUT_ROM_BITS = 0            # set below by rule R6 (`romInLuts`)
URAM_FROM_BRAMS = 4
BRAM36_SHAPES = ((32768, 1), (16384, 2), (8192, 4), (4096, 9), (2048, 18), (1024, 36), (512, 72))
BRAM18_SHAPES = ((16384, 1), (8192, 2), (4096, 4), (2048, 9), (1024, 18), (512, 36))
URAM_SHAPE = (4096, 72)
#: R7  loads one register bit of a modulus constant drives per butterfly (max_fanout 16 replicates above 16 loads)
Q_LOADS_PER_USER = 2.0
#: R8  a halver is one LUT per bit on a carry chain; R9 a compare against a constant takes ceil(bits / 6) LUTs


def _z(**kw) -> dict:
    d = dict(lut=0.0, ff=0.0, dsp=0.0, bram36=0.0, uram=0.0, srl=0.0, lutram=0.0)
    d.update(kw)
    return d


def delay(W: int, D: int, tail: bool = True) -> dict:
    '''`<name>_dly #(W, D)`. `tail`: the output drives logic, so the last stage is a flip-flop (an SRL feeding
    another register chain merges into it and keeps none).'''
    if D <= 0:
        return _z()
    if D >= RAM_DELAY:
        a = max(1, (D - 2).bit_length())
        return _z(bram36=bramTiles(D - 2, W), lut=a + 3, ff=a)     # D - 2 words and two read registers
    if D < SRL_MIN:
        return _z(ff=W * D)
    depth = D - 1 if tail else D
    per = -(-depth // 32) if depth > 16 else 1.0 / SRL16_PER_LUT
    return _z(lut=W * per, srl=W * per, ff=W if tail else 0)


def bramTiles(depth: int, width: int) -> float:
    '''RAMB36 tiles (a RAMB18 counts 0.5) of a depth x width memory: the best aspect ratio, the last column a
    RAMB18 when it fits one.'''
    best = None
    for d, w in BRAM36_SHAPES:
        rows = -(-depth // d)
        full, rest = divmod(width, w)
        t = rows * full
        if rest:
            half = any(d18 >= min(depth, d) and w18 >= rest for d18, w18 in BRAM18_SHAPES)
            t += rows * (0.5 if half else 1.0)
        if best is None or t < best:
            best = t
    return best


def uramTiles(depth: int, width: int) -> int:
    d, w = URAM_SHAPE
    return -(-depth // d) * -(-width // w)


#: a writable table goes to URAM288 from this many bits on. Routed loadable rows of 2026-11-16 (48 table shapes,
#: `ntt_hw/experiments/rerun_2026-11-16/loadable/hier/ramtab.py`): 1280 x 64 (81,920 bits) and 2560 x 32 are block
#: RAM (4 RAMB36), 1536 x 64 (98,304 bits) and 2048 x 62 are one URAM
URAM_FROM_BITS = 90_000


def uramTilesTable(depth: int, width: int) -> int:
    '''URAM288 of a writable table as Vivado builds it: the bits packed over whole URAMs (two 32-bit words share a
    72-bit word), with the depth rounded up to a power of two below 65,536 words. Exact on the routed shapes
    (4096..40960 x 32 / 62 / 64 and 163840 x 62 = 35); 81920 x 62 gives 18 where the routed design has 21.'''
    d = depth if depth >= 65536 else 1 << max(0, (depth - 1).bit_length())
    return max(1, -(-(d * width) // (URAM_SHAPE[0] * URAM_SHAPE[1])))


def lutRam(depth: int, width: int) -> int:
    '''R5: LUTs of a distributed RAM.'''
    if depth <= 32:
        return -(-width // 14) * 8
    return -(-depth // 64) * (-(-width // 7) * 8)


def lutRom(depth: int, width: int) -> float:
    '''A LUT ROM of `width` (distinct) columns: up to 32 words a column is a LUT5 at most and two of them share
    a LUT site (same address inputs); above, one LUT6 per column per 64 words.'''
    if depth <= 1:
        return 0.0
    if depth <= 32:
        return width * 0.5
    return -(-depth // 64) * width + (width if depth > 256 else 0)


def romColumns(values: list[int], width: int) -> int:
    '''Distinct non-constant bit columns of a ROM: a constant column needs neither LUT nor register, equal columns
    share both (synthesis merges equivalent registers).'''
    full = (1 << len(values)) - 1
    cols = set()
    for b in range(width):
        m = sum(((v >> b) & 1) << a for a, v in enumerate(values))
        if m not in (0, full):
            cols.add(m)
    return len(cols)


def romDepth(values: list[int]) -> int:
    '''Words a ROM really stores: halves (by the top address bits) that hold one constant are a mux, not memory
    (the forward half of an output-twist table is all ones).'''
    n = len(values)
    if n <= 64 or n & (n - 1):
        return n
    h = n // 2
    lo, hi = values[:h], values[h:]
    cl, ch = len(set(lo)) == 1, len(set(hi)) == 1
    if cl and ch:
        return 1
    if cl:
        return romDepth(hi)
    if ch:
        return romDepth(lo)
    # constant blocks deeper inside (address {modulus, direction, cycle}: one direction all ones for every modulus)
    # are NOT folded: measured, df_base twist tables 2048 x 30 with every other block of 256 constant = 2 RAMB36 each
    return n


def memory(depth: int, width: int, mode: str, style: str | None = None, values: list[int] | None = None) -> dict:
    '''A twiddle table column set of `width` bits (registered address, registered read): what Vivado maps it to.
    `style` forces it ('distributed' | 'block' | 'ultra', the option `tableStyle`). `values` (a ROM): the words,
    so a LUT ROM is priced by its distinct non-constant columns.'''
    st = style
    if mode == 'rom' and values is not None and depth > LUT_RAM_DEPTH:
        depth = romDepth(values)
    if st in (None, 'auto'):
        if (depth * width < LUT_RAM_BITS_RAM) if mode == 'ram' else (depth <= LUT_RAM_DEPTH):
            st = 'distributed'
        else:
            # URAM288 only for a RAM (a ROM never goes there), when it replaces URAM_FROM_BRAMS RAMB36 or more
            st = 'ultra' if (mode == 'ram' and depth * width >= URAM_FROM_BITS) else 'block'
    if st == 'distributed':
        if mode == 'ram':
            n = lutRam(depth, width)
            return _z(lut=n, lutram=n, ff=width)
        cols = romColumns(values, width) if values is not None else width
        if depth <= 2:
            return _z(ff=min(cols, 2))                  # a column is the address bit or its inverse
        return _z(lut=lutRom(depth, cols), ff=cols)
    if st == 'ultra':
        return _z(uram=uramTilesTable(depth, width) if mode == 'ram' else uramTiles(depth, width))
    # a writable table: Vivado builds it for the next power of two of its depth (routed 1280 x 32 = 2 RAMB36,
    # 2560 x 32 = 4, 1280 x 62 = 3.5, 1280 x 64 = 4), never as three or five shallow rows
    return _z(bram36=bramTiles(1 << max(0, (depth - 1).bit_length()) if mode == 'ram' else depth, width))


def _cmpLut(bits: int) -> int:
    return -(-bits // 6) if bits > 0 else 0


def _replicas(loads: float, limit: int) -> int:
    return max(1, -(-int(round(loads)) // limit))


def _columns(values: list[int], width: int) -> tuple[int, int]:
    '''(distinct non-constant bit columns, of those the ones that are not a copy or inverse of an index bit) of a
    ROM: constant columns need no register, equal columns share one (synthesis merges equivalent registers).'''
    n = len(values)
    ib = max(1, (n - 1).bit_length())
    full = (1 << n) - 1
    idx = set()
    for b in range(ib):
        m = sum(((a >> b) & 1) << a for a in range(n))
        idx.update((m, full ^ m))
    cols = set()
    for b in range(width):
        m = sum(((v >> b) & 1) << a for a, v in enumerate(values))
        if m not in (0, full):
            cols.add(m)
    return len(cols), len([c for c in cols if c not in idx])


def _nonZeroColumns(values: list[int], width: int) -> int:
    m = 0
    for v in values:
        m |= v
    return bin(m & ((1 << width) - 1)).count('1')


def _productMask(c: int, free: int) -> int:
    """Bits of c * a that can be one, for a constant c and any a of `free` bits (0: the constant itself). Each run
    of ones of c at bits l..h reaches bits l..h+free; runs whose ranges touch add up, one carry bit further. A
    one-bit a selects c or zero, so the bits are those of c."""
    if c <= 0:
        return 0
    if free <= 1:
        return c
    cap = (c * ((1 << free) - 1)).bit_length() - 1
    out, j, cur = 0, 0, None
    while c >> j:
        if c >> j & 1:
            l = j
            while c >> j & 1:
                j += 1
            lo_, hi_ = l, j - 1 + free
            if cur is not None and lo_ <= cur[1] + 1:
                cur = (cur[0], max(cur[1], hi_) + 1)
            else:
                if cur is not None:
                    out |= ((1 << (cur[1] + 1)) - 1) & ~((1 << cur[0]) - 1)
                cur = (lo_, hi_)
        else:
            j += 1
    if cur is not None:
        out |= ((1 << (min(cur[1], cap) + 1)) - 1) & ~((1 << cur[0]) - 1)
    return out & ((1 << (cap + 1)) - 1)


def _tileLive(dp, node, sched, mask: int, table: dict | None, parts: dict | None = None) -> dict:
    """{LUT tile name: live product bits} of a DSP multiplier node. A tile's product bit is kept when it lands in a
    column the consumers read (`mask`, as `dspcount.dspMultiplierCounts` trims the final sum) and is not a constant
    zero: with `table` ({port: values}, the per-frame modulus table) the slice of a modulus operand takes few
    values, often one (measured df_base, Barrett 30 bit: `bq` lut0 4 of 8, lut1 2 of 6; `bqq` lut0 0 of 8, lut1 1
    of 31, the tile lies above the read columns).

    With `parts` (the multiplier's own register rows) and a table operand the same constant zeros are followed
    further: the alignment delay of a tile keeps the tile's live bits only, and the compressor keeps the registers
    a heap of the remaining bits would have (its column heights without the constant-zero bits; measured
    V_C_barr52: `bq` 605 registers in the model, 380 routed, MU has 16 non-zero bits of 53)."""
    import contextlib, io
    import dsp_multiplier.backend.ir as IR
    import dsp_multiplier.backend.delay_model as DM
    from ...core.heapcount import firstCarryColumn
    sch = dp.dspScheme(node, sched.targetFmaxMhz)
    with contextlib.redirect_stdout(io.StringIO()):
        module, _ = sch.lower()
    heaps = [op for op in module.ops if isinstance(op, IR.BitHeap)]
    lutTiles = [op for op in module.ops if isinstance(op, IR.LutMult) and op.latency > 0]
    tiles = [op for op in module.ops if isinstance(op, (IR.LutMult, IR.DspTile))]
    if not heaps or not mask or not (lutTiles or (parts and table)):
        return {}
    top = heaps[-1]
    lo, hi = (mask & -mask).bit_length() - 1, mask.bit_length() - 1
    hi = min(hi, top.result.width - 1)
    need = min(lo, firstCarryColumn(tuple(DM._bitheap_heights(top))))
    weightOf = {t.signal.name: t.weight for t in top.terms if t.pp_columns is None}
    src = {}
    for op in module.ops:
        if isinstance(op, IR.Input):
            src[op.result.name] = (op.port_name, 0)
        elif isinstance(op, IR.Slice) and op.source.name in src:
            pn, o = src[op.source.name]
            src[op.result.name] = (pn, o + op.lo)
    port = {'A': node.a, 'B': node.b}
    out = {}
    liveMask = {}                                # tile / delay result name -> bits that are not constant zero
    dlySrc = {op.result.name: op for op in module.ops if isinstance(op, IR.Delay)}
    wgtVia = dict(weightOf)
    for dn, dop in dlySrc.items():
        if dn in weightOf:
            wgtVia.setdefault(dop.source.name, weightOf[dn])
    for op in tiles:
        wgt = wgtVia.get(op.result.name)
        if wgt is None or op.a.name not in src or op.b.name not in src:
            continue
        sets = []
        for x in (op.a, op.b):
            pn, o = src[x.name]
            vals = (table or {}).get(port.get(pn))
            if vals is None:
                sets.append(None)
            else:
                sets.append({(v >> o) & ((1 << x.width) - 1) for v in vals})
        if sets[0] is None and sets[1] is None:
            lm = (1 << op.result.width) - 1
        else:
            if sets[0] is None:
                free, cs = op.a.width, sets[1]
            elif sets[1] is None:
                free, cs = op.b.width, sets[0]
            else:
                free, cs = 0, {a * b for a in sets[0] for b in sets[1]}
            lm = 0
            for c in cs:
                lm |= _productMask(c, free)
        liveMask[op.result.name] = lm
        if isinstance(op, IR.LutMult) and op.latency > 0:
            out[str(op.result)] = sum(1 for j in range(op.result.width) if lm >> j & 1 and need <= wgt + j <= hi)
    if not parts or not table or all(m == (1 << w) - 1 for m, w in
                                     ((liveMask[t.result.name], t.result.width) for t in tiles
                                      if t.result.name in liveMask)):
        return out
    from ...core.heapcount import heapLiveFlipFlops
    from lut_timing import heap_reg_flags
    # alignment delays of a tile
    for dn, dop in dlySrc.items():
        lm = liveMask.get(dop.source.name)
        wgt = weightOf.get(dn)
        if lm is None or wgt is None or not parts.get(str(dop.result)):
            continue
        win = [j for j in range(dop.result.width) if need <= wgt + j <= hi]
        if win:
            keep = sum(1 for j in win if lm >> j & 1)
            out[str(dop.result)] = min(parts[str(dop.result)], round(parts[str(dop.result)] * keep / len(win)))
        liveMask[dn] = lm
    # the compressor: heights without the constant-zero bits
    full = [int(h) for h in DM._bitheap_heights(top)]
    red = list(full)
    for t in top.terms:
        lm = liveMask.get(t.signal.name)
        if t.pp_columns is not None or lm is None:
            continue
        for j in range(t.signal.width):
            if not lm >> j & 1 and 0 <= t.weight + j < len(red) and red[t.weight + j] > 0:
                red[t.weight + j] -= 1
    key = str(top.result)
    if HEAP_CONST_TRIM and red != full and top.latency > 0 and parts.get(key):
        def regs(hs):
            if max(hs, default=0) <= 2:
                return top.latency * (hi - lo + 1)
            return heapLiveFlipFlops(tuple(hs), heap_reg_flags(tuple(hs), top.latency), lo, hi)
        a, b = regs(full), regs(red)
        if a > 0 and b < a:
            out[key] = round(parts[key] * b / a)
    return out


def componentTrim(x, pipelineStages: int = 1, table: dict | None = None, shared: bool = False,
                  kept: bool = False) -> dict:
    """R13: what a dataflow core changes in one butterfly / multiplier of the shared component model
    (`x.resources`, `x.flipFlops`), from the component's own emitted rows (`core.emitcount.nodeRows`).
    Returns {'lut', 'ff', 'srl'} to ADD to one instance (LUT in report sites) and 'shLut', 'shFf', 'shSrl' to add
    once per group of instances fed by one modulus register. Every rule was read cell by cell from routed
    df_base (regs/df_base.txt): a butterfly 546 -> 449 FF, a generator multiplier 334 -> 279 FF, both exact.

    a. tail: a delay line the component model books as shift register only keeps one flip-flop per bit behind
       the SRL (`mp_d4`, `t_d4`, `Q_d7`: n SRL + n FF). Zero for a row that already has flip-flops, so it goes
       away by itself when the shared model books them (asked for in SHARED_REQUESTS.md).
    b. `table` = the per-frame modulus table {port: values}: a modulus port is a constant selected by MIDX. A bit
       column that is zero for every modulus has no register in the port's delay lines (`Q_d*`, `MU_d*`): the
       rows are scaled by non-zero columns / width (Q 18 of 30, MU 14 of 30 for the four 30-bit moduli).
    c. `shared`: the stages of a port's delay line that start at the port are equal in every instance fed by the
       same modulus register; synthesis keeps one copy (an instance keeps the last flip-flop only).
    d. a later two-cycle tap of a port's delay line is rebuilt as a shift register from the first register:
       one SRL + one flip-flop per bit instead of two flip-flops (`Q_d9`).
    e. LUT tiles of a DSP multiplier (`_tileLive`): product bits outside the read columns, or constant because the
       modulus operand slice is, have no register.
    `kept` (2026-11-16, the dataflow generator since the timing rounds of that night): the delay lines of a modulus
       port keep their first and last register in every instance (`_reg_chain` keepFirst / keepLast), so nothing is
       shared between instances (c does not apply), and what lies between them is a shift register only from three
       stages on (Vivado's least length), else flip-flops (d does not apply). Read from routed LDe_rom1, butterfly
       s16_k2: MU_d4 4 x 64 FF; Q_d8 62 + 62 FF and 62 SRL; Q_d13 62 SRL + 62 FF; Q_d15 2 x 62 FF."""
    out = dict(lut=0.0, ff=0.0, srl=0.0, shLut=0.0, shFf=0.0, shSrl=0.0)
    try:
        from ...core import emitcount as EC
        inner = x.inner() if hasattr(x, 'inner') else x
        dp, sched = inner.datapath(), inner.schedule(pipelineStages)
        import contextlib, io
        with contextlib.redirect_stdout(io.StringIO()):
            rows = EC.nodeRows(dp, sched)
            live = EC.liveBits(dp, sched)
    except Exception:
        return out
    ports = {}
    if table:
        for pn, vals in table.items():
            w = max(1, max(vals).bit_length())
            ports[pn] = (_nonZeroColumns(vals, w), w)
    names = {getattr(i, 'name', i) for i in dp.inputs} - {'A', 'B', 'W', 'WP', 'DIR'}
    dff = dsrl = 0.0
    for r in rows:
        if r.kind != 'delay' or '_d' not in r.name:
            continue
        base = r.name.rsplit('_d', 1)[0]
        isPort = base in names
        keep = 1.0
        if base in ports:
            c, w = ports[base]
            keep = min(1.0, c / w)
        ff, srl = r.ff * keep, r.srl * keep
        fromIn = 'from an input' in r.note
        if kept and isPort:
            bits = int(r.note.split(' bit x ')[0].split()[-1]) * keep
            cyc = int(r.note.split(' bit x ')[1].split()[0])
            ends = min(cyc, 2 if fromIn else 1)
            mid = cyc - ends
            ff = bits * (ends + (mid if mid < 3 else 0))
            srl = (r.srl * keep if r.srl else bits) if mid >= 3 else 0.0
            dff += ff - r.ff
            dsrl += srl - r.srl
            continue
        if r.srl and not r.ff:                               # a
            ff += srl
        elif isPort and not fromIn and not r.srl and r.ff and '2 cycle' in r.note:     # d
            ff, srl = ff / 2, ff / 2
        if isPort and fromIn and shared:                     # c
            bits = int(r.note.split(' bit x ')[0].split()[-1]) * keep     # the last register stays (emitcount rule 5)
            out['shFf'] += ff - bits
            out['shSrl'] += srl
            ff, srl = bits, 0.0
        dff += ff - r.ff
        dsrl += srl - r.srl
    node = {n.name: n for n in dp.nodes}
    for r in rows:                                           # e
        if r.kind != 'mult' or not r.parts or r.name not in node:
            continue
        try:
            tl = _tileLive(dp, node[r.name], sched, live.get(r.name, 0), table, r.parts)
        except Exception:
            continue
        for k, bits in tl.items():
            if k in r.parts:
                dff += min(0, bits - r.parts[k])
    dsrl = max(dsrl, -float(sum(r.srl for r in rows)))       # never below the component's own shift registers
    out['ff'], out['srl'] = dff, dsrl
    out['lut'] = dsrl / SRL16_PER_LUT
    out['shLut'] = out['shSrl'] / SRL16_PER_LUT
    return out


class _Walk:
    '''The generator's emission order replayed on the spec; collects parts (and the structure counts).'''

    def __init__(self, sch, ps: int = 1, name: str = 'm'):
        from .StreamingNTT import StreamingNTT
        self.sch, self.ps = sch, ps
        self.op = StreamingNTT(sch)
        if type(sch).__name__ == 'UnrolledNTTScheme':        # the scheme's own operator: it carries roms['unrolled']
            try:
                from .UnrolledNTT import UnrolledNTT
                self.op = UnrolledNTT(sch)
            except Exception:
                pass
        self.spec = self.op.getOperatorInterface(name, ps)
        self.parts: list[dict] = []
        self.struct = {'delays': [], 'tables': 0, 'mtabs': 0, 'butterflies': 0, 'tags': 0, 'halvers': 0, 'mults': 0}
        self._comp = {}
        self.run()

    # --- helpers ----------------------------------------------------------------------------------------------
    def add(self, cls: str, what: str, n: float, r: dict) -> None:
        if n:
            p = {k: v * n for k, v in r.items()}
            p.update(cls=cls, what=what, n=n)
            self.parts.append(p)

    def dly(self, cls: str, what: str, W: int, D: int, n: int = 1, tail: bool = True) -> None:
        self.struct['delays'] += [(W, D)] * n
        self.add(cls, f'{what} (W {W}, D {D})', n, delay(W, D, tail))

    def comp(self, key, obj) -> dict:
        '''(lut, ff, dsp, bram36) of a butterfly or multiplier from the shared component model.'''
        if key not in self._comp:
            r = obj.resources(self.ps)
            self._comp[key] = _z(lut=r.lut, ff=obj.flipFlops(self.ps), dsp=r.dsp, bram36=r.bram36 + r.bram18 / 2)
        return self._comp[key]

    def trim(self, cls: str, what: str, key, obj, site: str) -> None:
        '''R13 (`componentTrim`): the in-core change of one component instance; the shared first stages of the
        modulus delay lines once per modulus register (`site`).'''
        if not TRIM:
            return
        k = ('trim', key)
        if k not in self._comp:
            runtime = bool(self.pf) or bool(self.spec.roms['qPorts'])
            ptab = self.pf['table'] if (self.pf and not self.pf.get('loadable')) else None   # loadable: stand-ins only
            self._comp[k] = componentTrim(obj, self.ps, ptab, shared=runtime,
                                          kept=runtime)
        t = self._comp[k]
        if t['lut'] or t['ff']:
            self.add(cls, f'{what}: in-core trim', 1, _z(lut=t['lut'], ff=t['ff'], srl=t['lut']))
        if (t['shFf'] or t['shLut']) and (cls, site) not in self.trimSites:
            self.trimSites.add((cls, site))
            self.add(cls, f'{what}: first stages of the modulus delay lines, one per modulus register', 1,
                     _z(lut=t['shLut'], ff=t['shFf'], srl=t['shLut']))

    def tag_at(self, o: int) -> None:
        tags, F = self.tags, self.spec.frameCycles
        if o in tags:
            return
        a = max(x for x in tags if x < o)
        if o - a > F:
            self.tag_at(o - F)
        tags.add(o)
        self.struct['tags'] += 1
        FB = self.FB
        if FB:
            self.add('glue', 'tag register + hit compare', 1, _z(ff=1 + self.TGW, lut=_cmpLut(FB)))
        else:
            self.add('glue', 'tag register', 1, _z(ff=self.TGW))

    def slotTables(self) -> list:
        """Per RAM table of a design with loadableModuli: {base, words, offsets}, as the RTL manifest's
        `slot_tables` (the timing of a slot load, StreamingNTTScheme.slotTiming)."""
        info = self.spec.roms
        half = 2 if info.get('loadByDir') else 1
        return [{'base': t['base'], 'words': (t['depth'] // (t.get('mods') or 1) // half) * len(t['cols']),
                 'offsets': sorted(set(self.__dict__.get('tabOff', {}).get(t['id'], [])))}
                for t in info['tables'] if t['mode'] == 'ram']

    def msig(self, site: str, off: int, users: float = 1.0) -> None:
        '''A modulus-table copy (`<name>_mtab`): per constant one LUT ROM + register (max_fanout 16).'''
        if site in self.msites:
            self.msites[site] += users
            return
        self.msites[site] = users
        self.msiteOrder.append(site)
        self.tag_at(off - 1)
        if getattr(self, 'CQW', 0) and not self.FB:     # a delay line of the constants to this site (SRL32 per bit)
            last = max([o for o in getattr(self, '_cqOffs', [1]) if o < off] or [1])
            self._cqOffs = getattr(self, '_cqOffs', [1]) + [off - 1]
            self.add('glue', 'modulus constants delay line', 1, _z(lut=self.CQW * max(1, -(-(off - 1 - last) // 32))))
        self.struct['mtabs'] += 1

    def qsig(self, tag: str, users: float = 1.0) -> None:
        self.qcopies[tag] = self.qcopies.get(tag, 0.0) + users

    def table(self, t: dict, aoff, shareKey=None, cls: str = 'tab') -> None:
        spec = self.spec
        self.struct['tables'] += 1
        if aoff is not None:                    # where the table is read, for the timing of a slot load
            self.__dict__.setdefault('tabOff', {}).setdefault(t['id'], []).append(aoff)
        if (self.pf or self.FD) and aoff is not None:
            self.tag_at(aoff)
        ab = len(t['bits']) + self.dirBit + self.IW
        style = t.get('romStyle') or getattr(self.sch, 'tableStyle_', None)
        r = _z()
        # R12: ROMs with the same address register and the same words are one memory after synthesis (measured,
        # df_base: the 'hi' generator tables of a stage are equal; 16 tables of 128 x 30 = 2 RAMB18, one per stage,
        # and the LUT ROM ones keep registers in one instance per stage only)
        if t['mode'] == 'rom' and t.get('values') and shareKey is not None:
            dk = (shareKey, aoff, t['depth'], tuple(tuple(v) for v in t['values']))
            if dk in self.romSeen:
                self.add(cls, f"table {t.get('use', '')} depth {t['depth']} x {'+'.join(str(c) for c in t['cols'])} (rom, equal to another)", 1, _z())
                return
            self.romSeen.add(dk)
        # R12b: a bit column of one ROM array that equals a column of a later array of the same table (same address
        # register) is stored once (measured, C_shou40 and V_C_shou52: w and w' = floor(w 2^k / q) share their top
        # columns when q is close to 2^k; 96 x 40+40 = 1 + 2 RAMB18, 768 x 52+52 = 1 RAMB36 + RAMB36 + RAMB18)
        dup = [0] * len(t['cols'])
        if t['mode'] == 'rom' and t.get('values') and len(t['cols']) > 1 and t['depth'] > LUT_RAM_DEPTH:
            sig = [{sum(((v >> b) & 1) << a for a, v in enumerate(t['values'][ci])) for b in range(w)}
                   for ci, w in enumerate(t['cols'])]
            for ci in range(len(sig)):
                later = set().union(*sig[ci + 1:]) if ci + 1 < len(sig) else set()
                dup[ci] = len(sig[ci] & later)
        for ci, w in enumerate(t['cols']):
            if dup[ci]:
                m = _z(bram36=bramTiles(t['depth'], w - dup[ci])) if (style in (None, 'auto', 'block')) else \
                    memory(t['depth'], w, t['mode'], style, t['values'][ci])
            else:
                m = memory(t['depth'], w, t['mode'], style, t['values'][ci] if t.get('values') else None)
            for k in r:
                r[k] += m[k]
            if m['bram36'] or m['uram']:
                pass                              # the read register is the memory's own
        # the registered address: tables of one stage read the same counter bits, equal registers merge
        if shareKey not in self.addrSeen:
            self.addrSeen.add(shareKey)
            r['ff'] += ab if ab else 0
            if self.FB and t['bits']:
                r['lut'] += self.FB           # cnt + k
        if t['mode'] == 'ram':
            nc = len(t['cols'])
            r['lut'] += 3
            # the table's write registers, two stages. Routed (LDe_rom1, LDe_romR, LDb_romR): the enables stay per
            # table; the address and the data word of the tables on one load lane merge into one copy per lane
            # (the data word is in the load port's line)
            ab_w = max(1, (t['depth'] - 1).bit_length())
            seen = self.__dict__.setdefault('wlane', {})
            ln = t.get('ldl', 0)
            r['ff'] += 2 * (1 + (nc - 1)) + 2 * max(0, ab_w - seen.get(ln, 0))
            seen[ln] = max(seen.get(ln, 0), ab_w)
        self.add(cls, f"table {t.get('use', '')} depth {t['depth']} x {'+'.join(str(c) for c in t['cols'])} ({t['mode']})", 1, r)

    # --- the walk ---------------------------------------------------------------------------------------------
    def run(self) -> None:
        sch, spec, ps = self.sch, self.spec, self.ps
        P, F = spec.lanes, spec.frameCycles
        FB = self.FB = (F - 1).bit_length() if F > 1 else 0
        info = spec.roms
        tables, gen, qports = info['tables'], info['generator'], info['qPorts']
        loadW = info['loadWords']
        pf = self.pf = info.get('perFrame')
        unr = info.get('unrolled') or {}
        tshare, mshare = unr.get('tableShare'), unr.get('modShare')
        IW = self.IW = pf['indexBits'] if pf else 0
        PD = 1 if (pf and spec.dirPort) else 0
        FD = self.FD = 1 if (not pf and spec.dirPort and unr.get('frameDir') and F == 1) else 0
        self.TGW = IW + PD + FD
        # run-time moduli: the modulus constants travel with the data. With frames they sit in the tag registers
        # (one per site per frame). At one transform per cycle they run through shift-register delay lines from
        # one point of use to the next (`cq_at` in the RTL generator), priced per site in `msig`.
        self.CQW = sum(w_ for _, w_ in info['qPorts']) if (pf and pf.get('loadable')) else 0
        if self.CQW and self.FB:
            self.TGW += self.CQW
        self.dirBit = 1 if spec.dirPort else 0
        self.tags, self.msites, self.msiteOrder, self.qcopies, self.addrSeen = set(), {}, [], {}, set()
        self.romSeen, self.trimSites = set(), set()
        qw = dict(qports)
        QW = sum(qw.values())
        strm = info.get('stream')
        if FB:
            self.add('glue', 'frame counter', 1, _z(ff=FB, lut=FB))
        if loadW:
            LW = loadW.bit_length()
            TWW = max(max(t['cols']) for t in tables if t['mode'] == 'ram')
            nram = len([t for t in tables if t['mode'] == 'ram'])
            # the data word: port register, core register and the tables' register (one per lane after merging), and
            # one more in the managed top; per lane as wide as its widest table (routed LDe_romR: 4 x 3,658)
            lw = {}
            for t in tables:
                if t['mode'] == 'ram':
                    lw[t.get('ldl', 0)] = max(lw.get(t.get('ldl', 0), 0), max(t['cols']))
            stages = 3 + (1 if getattr(sch, 'slotMgr', False) else 0)
            self.add('glue', 'load port (index, data word)', 1,
                     _z(ff=LW * _replicas(nram, 32) + stages * sum(lw.values()), lut=LW))
        if pf:
            self.tags.add(1)
            self.add('glue', 'tag register mx_1', 1, _z(ff=self.TGW, lut=_cmpLut(FB)))
        if FD:
            self.tags.add(1)
            self.add('glue', 'tag register mx_1', 1, _z(ff=1))
        w = spec.inWidth
        flead = pf['lead'] if pf else (unr.get('lead', 0) if FD else 0)
        if flead:
            self.dly('lead', 'frame lead', w, flead, P, tail=False)
        if spec.dirPort and not (PD or FD):
            self.add('glue', 'DIR register', 1, _z(ff=1))
        genLat = info['generatorLatency']
        tw = spec.twist
        twistIn = tw is not None and tw.get('side') == 'input'

        def consts(dp):
            return [x.name for x in dp.inputs if x.name not in ('A', 'B')]

        def twist():
            dp = tw['datapath']
            cq = consts(dp)
            site = 'tw'
            for l in range(P):
                if pf and mshare and l >= mshare and l % mshare == 0:
                    site = f'twm{l // mshare}'
                if cq:
                    self.msig(site, tw['off']) if pf else self.qsig('twq')
                if tw.get('otf'):
                    tl, th = tables[tw['tables'][l][0]], tables[tw['tables'][l][1]]
                    ga = tw['off'] - 2 - genLat
                    self.table(tl, ga, ('tw', 'g'), 'twtab')
                    self.table(th, ga, ('tw', 'g'), 'twtab')
                    if consts(gen['datapath']):
                        self.msig('twg', tw['off'] - genLat) if pf else self.qsig('twq')
                    self.struct['mults'] += 1
                    self.add('twgen', 'twist generator multiplier', 1, self.comp('gen', self.genObj()))
                    self.trim('twgen', 'twist generator multiplier', 'gen', self.genObj(), 'twg' if pf else 'twq')
                else:
                    self.table(tables[tw['tables'][l]], tw['off'] - 2, ('tw',), 'twtab')
                self.struct['mults'] += 1
                self.add('twmul', 'twist multiplier', 1, self.comp('twist', sch.twistMultiplier))
                self.trim('twmul', 'twist multiplier', 'twist', sch.twistMultiplier, site if pf else 'twq')
            return dp.wire(dict(dp.outputs)['P']).bitWidth

        lead = getattr(spec, 'leadIn', 0)
        if lead:
            if lead >= SRL_MIN:
                # R15 (measured df_base): the lanes that enter a butterfly's A input join its A delay line (no
                # cells); the other half keeps a shift register and a flip-flop per bit
                self.dly('lead', 'lead-in (lanes to a multiplier input)', w, lead, P // 2, tail=True)
            else:
                self.dly('lead', 'lead-in', w, lead, P, tail=False)
        if twistIn:
            w = twist()
        stchain = {}
        tuse, tcopy, genDone = {}, set(), set()
        for s, st in enumerate(spec.stages):
            ex = st['exchange']
            if ex:
                i, j, D = ex
                pairs = P // 2
                # dly1 feeds the muxes (tail register); dly0 feeds the butterfly, whose own input chain it joins
                self.dly('exdly', f'stage {s} exchange delay to the muxes', w, D, pairs, tail=True)
                if SRL_MIN <= D <= 16:
                    # R15: this line joins the butterfly's A delay shift register (no cells of its own, measured
                    # df_base D 4, 8, 16); above 8 cycles the joined line no longer fits half a LUT per bit
                    if D > 8:
                        self.add('exdly', f'stage {s} exchange delay to the butterfly (joined, second half LUT)', pairs,
                                 _z(lut=w / SRL16_PER_LUT, srl=w / SRL16_PER_LUT))
                else:
                    self.dly('exdly', f'stage {s} exchange delay to the butterfly', w, D, pairs, tail=False)
                self.add('exdly', f'stage {s} exchange muxes (2 x {w} bits per pair)', pairs, _z(lut=2 * w * MUX_PACK))
            ow = st['outWidth']
            ireg = st.get('inReg', 0)
            for k, sl in enumerate(st['slots']):
                mod = sl['module']
                bs = spec.modules[mod]
                bu = sch.butterflies[s][k]
                src = sl['twiddle']
                wreg = 0
                if src is not None and src[0] == 'stream':
                    c = src[1]
                    o_need = st['buOff']
                    o_have = stchain.get(c, 0)
                    if strm.get('aligned'):
                        o_have = o_need
                    if o_need > o_have:
                        self.dly('strdly', f'twiddle port {c} to stage {s}', strm['width'], o_need - o_have, 1, tail=False)
                        o_have = o_need
                    stchain[c] = o_have
                    wreg = strm['width']
                elif src is not None and src[0] == 'tab':
                    t = tables[src[1]]
                    if tshare:
                        gk = (s, src[1])
                        ti = tuse.get(gk, 0)
                        tuse[gk] = ti + 1
                        tn = (s, src[1], ti // tshare)
                        if tn not in tcopy:
                            tcopy.add(tn)
                            self.table(t, st['buOff'] - 2, ('s', s))
                    else:
                        self.table(t, st['buOff'] - 2, ('s', s))
                    wreg = sum(t['cols'])
                elif src is not None and src[0] == 'rec':
                    key = (s, sl['gen'])
                    tb_ = tables[src[1]]
                    gw = max(tb_['cols'])
                    if key not in genDone:
                        genDone.add(key)
                        o = st['buOff']
                        self.table(tb_, o - 3, ('s', s, 'rb'), 'gentab')
                        self.table(tables[src[2]], o - 2, ('s', s, 'ru'), 'gentab')
                        kk = info['rec']['k'][sl['gen']]
                        self.add('glue', 'recurrence select + register y', 1, _z(ff=1 + gw, lut=gw * 0.5 + _cmpLut(kk)))
                        if consts(gen['datapath']):
                            self.msig(f's{s}r', o) if pf else self.qsig(f's{s}q')
                        self.struct['mults'] += 1
                        self.add('genmul', 'recurrence multiplier', 1, self.comp('gen', self.genObj()))
                        self.trim('genmul', 'recurrence multiplier', 'gen', self.genObj(), f's{s}r' if pf else f's{s}q')
                    wreg = gw
                elif src is not None:
                    key = (s, sl['gen'])
                    tl, th = tables[src[1]], tables[src[2]]
                    gw = max(tl['cols'])
                    if key not in genDone:
                        genDone.add(key)
                        ga = st['buOff'] - 2 - genLat
                        self.table(tl, ga, ('s', s, 'g'), 'gentab')
                        self.table(th, ga, ('s', s, 'g'), 'gentab')
                        if consts(gen['datapath']):
                            self.msig(f's{s}g', st['buOff'] - genLat) if pf else self.qsig(f's{s}q')
                        self.struct['mults'] += 1
                        self.add('genmul', 'on-the-fly generator multiplier', 1, self.comp('gen', self.genObj()))
                        self.trim('genmul', 'on-the-fly generator multiplier', 'gen', self.genObj(),
                                  f's{s}g' if pf else f's{s}q')
                    wreg = gw
                if ireg:
                    self.add('glue', 'butterfly input register', 1, _z(ff=2 * w + wreg))
                msite = f's{s}' + (f'm{k // mshare}' if (pf and mshare and k >= mshare) else '')
                for pn, _ in bs.extraPorts:
                    if pn == 'DIR' and (PD or FD):
                        self.tag_at(st['buOff'] + ireg)
                    elif pn not in ('W', 'WP', 'DIR'):
                        self.msig(msite, st['buOff'] + ireg) if pf else self.qsig(f's{s}q')
                        break
                self.struct['butterflies'] += 1
                self.add('bu', f"butterfly {'constant' if src is None else 'full'} ({mod.split('_', 1)[-1] if False else mod[len(spec.name) + 1:]})",
                         1, self.comp(mod, bu))
                self.trim('bu', 'butterfly', mod, bu, msite if pf else f's{s}q')
                nx = spec.stages[s + 1]['exchange'] if s + 1 < len(spec.stages) else 0
                if TRIM and nx != 0 and (nx is None or 2 <= nx[2] < RAM_DELAY):
                    # R14 (measured df_base, df_n1k_p8_q30: `x_c` 15 FF per butterfly on average): the sum output
                    # register joins the shift register it feeds (next butterfly's A line or an exchange delay)
                    # for the half of the butterflies whose sum goes there
                    self.add('bu', 'butterfly: sum output register joins the next delay line (half)', 1, _z(ff=-ow / 2))
                extra = st['buLatency'] - sl['latency']
                if st.get('halve', 0):
                    for _ in range(2):
                        if pf:
                            self.msig(f"s{s}h{sl['latency']}" + (f'm{k // mshare}' if (mshare and k >= mshare) else ''),
                                      st['buOff'] + ireg + sl['latency'], 0.5)
                        elif 'QHALF' in qw:
                            self.qsig(f's{s}q', 0.5)
                        if PD or FD:
                            self.tag_at(st['buOff'] + ireg + sl['latency'])
                        self.struct['halvers'] += 1
                        self.add('glue', 'halver (x 2^-1 per stage)', 1, _z(ff=ow, lut=ow))
                if extra:
                    self.dly('bal', f'stage {s} balance delay', ow, extra, 2, tail=True)
            w = ow
        if tw is not None and not twistIn:
            w = twist()
        ro = info.get('reorder')                        # outputOrder='natural'
        if ro is not None and ro['ram']:
            np_ = len(ro['pairs'])
            fbits = max(1, (F - 1).bit_length())
            sel = _replicas(P * w, 64)                  # max_fanout 64 on the swap selects
            self.add('reorder', 'frame counters (3 registers, replicated) and parity', 1,
                     _z(ff=(fbits - np_) * 3 + np_ * (1 + 2 * sel) + 1, lut=fbits + _cmpLut(fbits)))
            # two swap layers fit one LUT6 (a 4:1 mux); the write side ends in a register, the read side too
            self.add('reorder', f'write swap, {np_} layers', P, _z(lut=w * -(-np_ // 2), ff=w))
            self.add('reorder', f'read swap, {np_} layers', P, _z(lut=w * -(-np_ // 2), ff=w))
            self.add('reorder', f'bank RAM {2 * F} x {w}', P, memory(2 * F, w, 'ram'))
            self.struct['reorderBanks'] = P
        if getattr(sch, 'outReady', False):
            # outReady=True: the wrapper's output buffer, one RAM of 2^addrBits words per lane, and its pointers
            # and credit counter (measured df_ready against df_base: +16 RAMB36 for 16 lanes of 1024 x 30,
            # LUT +86, flip-flops unchanged: the read register is the RAM's own)
            pl = sch.readyPlan(self.ps)
            AB = pl['addrBits']
            # no ram_style on it: Vivado takes URAM288 from URAM_FROM_BRAMS RAMB36 on and packs words side by
            # side (routed 2026-11-15: 8192 x 32 = 1 URAM288, 4096 x 32 = 1 URAM288 per lane)
            buf = memory(1 << AB, ow, 'ram')
            if buf['uram']:
                buf = _z(uram=-(-(-(-(1 << AB) // URAM_SHAPE[0]) * ow) // URAM_SHAPE[1]))
            self.add('ready', f'output buffer {1 << AB} x {ow}', P, buf)
            self.add('ready', 'pointers, credit counter, valid', 1, _z(lut=4 * AB + 8, ff=3 * AB + pl['creditBits'] + 4))
        # the constants: modulus-table copies (per-frame moduli) or port registers with one copy per stage
        if pf:
            for site in self.msiteOrder:
                users = self.msites[site]
                ff = lut = 0
                for p, vals in pf['table'].items():
                    v = list(vals) + [0] * ((1 << IW) - len(vals))
                    reg, tab = _columns(v, qw[p])
                    if pf.get('loadable'):          # no table: the site registers the constant from the tag
                        reg, tab = qw[p], 0
                        # only what the site's consumers read stays after synthesis (routed LDe_rom1: stage sites
                        # keep Q and MU, halver sites keep QHALF)
                        import re as _re
                        if 'QHALF' in pf['table'] and (p == 'QHALF') != bool(_re.match(r's\d+h', str(site))):
                            continue
                    ff += reg * _replicas(users * Q_LOADS_PER_USER, 16)
                    lut += tab * (0.5 if IW <= 2 else 1.0)
                self.add('mtab', f'modulus table copy {site}', 1, _z(ff=ff, lut=lut))
        elif qw:
            self.add('glue', 'modulus port registers', 1, _z(ff=QW * _replicas(len(self.qcopies), 16)))
            for tag, users in self.qcopies.items():
                self.add('glue', f'modulus port copy {tag}', 1, _z(ff=QW * _replicas(users * Q_LOADS_PER_USER, 16)))

    def genObj(self):
        if '_g' not in self._comp:
            from ...core.IntType import IntType
            self._comp['_g'] = self.sch._multiplier(f'{self.spec.name}_gen', IntType(0, self.sch.qMax() - 1))
        return self._comp['_g']


def inventory(sch, pipelineStages: int = 1) -> list[dict]:
    return _Walk(sch, pipelineStages).parts


def structure(sch, pipelineStages: int = 1) -> dict:
    st = _Walk(sch, pipelineStages).struct
    st['delays'] = sorted(st['delays'])
    return st


def structureOfRtl(top_sv: str, name: str) -> dict:
    '''The same counts read from the emitted top module.'''
    txt = open(top_sv).read()
    d = sorted((int(a), int(b)) for a, b in re.findall(rf'{name}_dly #\(\.W\((\d+)\), \.D\((\d+)\)\)', txt))
    return {'delays': d,
            'tables': len(re.findall(rf'^\s+{name}_tab\d+ ', txt, re.M)),
            'mtabs': len(re.findall(rf'^\s+{name}_mtab ', txt, re.M)),
            'butterflies': len(re.findall(rf'^\s+{name}_s\d+_(bu|c\d+) s\d+_k\d+ ', txt, re.M)),
            'tags': len(re.findall(r'^\s+logic (mxh_\d+; logic )?\[\d+:0\] mx_(?!1;)\d+;', txt, re.M)),
            'halvers': len(re.findall(r'_h <= ', txt)),
            'mults': len(re.findall(r'_(mul|gen) \(\.clk', txt))}


def totals(parts: list[dict]) -> dict:
    keys = ('lut', 'ff', 'dsp', 'bram36', 'uram', 'srl', 'lutram')
    t = {k: sum(p[k] for p in parts) for k in keys}
    by: dict = {}
    for p in parts:
        b = by.setdefault(p['cls'], dict.fromkeys(keys, 0.0))
        for k in keys:
            b[k] += p[k]
    t['byClass'] = by
    t['au'] = (t['lut'] / 1000 + t['ff'] / 1000 + t['dsp'] * 4 / 3 + t['bram36'] + 8 * t['uram']) / 5
    return t
