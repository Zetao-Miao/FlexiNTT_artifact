'''Registers, shift registers and LUTs of a scheduled `Datapath`, counted from what the back end
emits and from which of those bits a consumer reads.

    liveBits(dp, sched)    -> {wire: bit mask of the bits some consumer reads}
    nodeRows(dp, sched)    -> [Row]: one per node and per balancing delay
    totals(dp, sched)      -> Counts(lutCells, srlBits, ff, dsp) summed over the rows

The counts are in emitted cells: LUT cells, SRL16 bits and flip-flops. `datapath.Datapath`
turns them into the LUT sites a utilisation report shows (`LUT_PACK`, `SRL_PER_LUT`).

Rules measured on routed OOC netlists (V80 part, Vivado 2025.1, 350 MHz; see
`ntt_hw/experiments/overnight_2026-11-14/iterative/COMPONENTS.md`):

  * A register bit nobody reads is removed, and so is the logic that only feeds it. For a sum
    this means: columns above the highest bit read are gone; columns below the lowest bit read
    stay only from the first column that can make a carry.
  * Registers that hold a plain copy of the same signal bit at the same cycle are merged into
    one: the pass-through bits of a registered compressor layer (a constant multiplier's heap
    holds each input bit many times), the first stages of a delay chain of that wire, the
    operand register of a compare-folded correction.
  * A balancing delay of an internal wire of 3 cycles or more becomes one SRL16 per bit per
    16 cycles and no flip-flop (the wire's own register is the SRL input); the chain from a
    module input keeps its last stage as a flip-flop. Shorter delays stay flip-flops.

Read-only on the back end.
'''
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class Row:
    name: str
    kind: str            # node kind, or 'delay'
    lut: int = 0         # LUT cells (logic)
    srl: int = 0         # SRL16 cells
    ff: int = 0
    dsp: int = 0
    sel: int = 0         # of `lut`: 2:1 select cells with a shared select (they pack two per site, SEL_PACK)
    buf: int = 0         # of `lut`: LUT1 buffers of pinned compressor inputs (BUF_PACK)
    note: str = ''
    parts: dict = field(default_factory=dict)   # register name -> flip-flops, for the comparison tools
    keys: set = field(default_factory=set)      # plain copies (wire, bit, cycles later): one register each,
                                                # shared by every row that holds the same copy


@dataclass
class Counts:
    lut: int = 0
    srl: int = 0
    ff: int = 0
    dsp: int = 0
    sel: int = 0         # of `lut`: 2:1 select cells (see `SEL_PACK`)
    buf: int = 0         # of `lut`: LUT1 buffers of pinned compressor inputs (see `BUF_PACK`)


def _mask(lo: int, hi: int) -> int:
    return 0 if hi < lo else ((1 << (hi - lo + 1)) - 1) << lo


def _span(m: int) -> tuple[int, int]:
    '''(lowest, highest) set bit of a mask; (0, -1) when empty.'''
    if not m:
        return 0, -1
    return (m & -m).bit_length() - 1, m.bit_length() - 1


def _pop(m: int) -> int:
    return bin(m).count('1')


def _heapNeed(dp, node, live: int):
    '''(adesc, heights, lowest needed column, highest needed column) of a heap whose consumers
    read the bits in `live`.'''
    from .heapcount import firstCarryColumn
    _, adesc, heights, _ = dp._heapPlan(node)
    lo, hi = _span(live)
    colH = {e[0]: len(e) - 1 for e in adesc}
    hs = [colH.get(c, 0) for c in range(max(colH, default=-1) + 1)]
    need = min(lo, firstCarryColumn(hs))
    return adesc, heights, need, hi


def liveBits(dp, sched) -> dict:
    '''Bit mask per wire (node outputs, inputs and delay names) of the bits a consumer reads.'''
    live: dict[str, int] = {}

    def mark(w, m):
        if w and m:
            live[w] = live.get(w, 0) | m

    for port, w in dp.outputs:
        mark(sched.renamed['__outputs__'].get(port, w), _mask(0, dp.width(w) - 1))
        mark(w, 0)
    delaysOf: dict[str, list[str]] = {}
    for dn, src, _ in sched.delays:
        delaysOf.setdefault(src, []).append(dn)
    for node in reversed(dp.nodes):
        for dn in delaysOf.get(node.name, ()):
            mark(node.name, live.get(dn, 0))
        m = live.get(node.name, 0)
        if not m:
            continue
        ren = dict(zip(node.inputs, sched.renamed[node.name]))
        r = lambda w: ren.get(w, w)
        if node.kind == 'heap':
            adesc, _, need, hi = _heapNeed(dp, node, m)
            for e in adesc:
                if need <= e[0] <= hi:
                    for sig, idx, neg, cnst in e[1:]:
                        if not cnst and sig is not None:
                            mark(r(sig), 1 << (idx or 0))
        elif node.kind == 'mult':
            _, hi = _span(m)
            for w in (node.a, node.b):
                if w:
                    mark(r(w), _mask(0, min(dp.width(w) - 1, hi)))
        elif node.kind in ('table', 'nonzero'):
            mark(r(node.src), _mask(node.lo, node.hi))
        elif node.kind == 'select':
            mark(r(node.src), 1)
            for w in (node.a, node.b):
                if w:                           # an empty side is the constant 0
                    mark(r(w), _mask(0, dp.width(w) - 1))
        else:                                   # correct, qcorrect: the compare reads every bit
            mark(r(node.src), _mask(0, dp.width(node.src) - 1))
            for w in node.qMults or ():
                if w:
                    mark(r(w), _mask(0, dp.width(w) - 1))
            if node.qwire:
                mark(r(node.qwire), _mask(0, dp.width(node.qwire) - 1))
    for src, dns in delaysOf.items():           # delays of module inputs
        for dn in dns:
            mark(src, live.get(dn, 0))
    return live


def _multRow(dp, node, sched, live: int) -> Row:
    lo, hi = _span(live)
    if node.backend == 'dsp':
        from ..multiplier.dspcount import dspMultiplierCounts
        sch = dp.dspScheme(node, sched.targetFmaxMhz)
        c = dspMultiplierCounts(sch, lo, hi)
        return Row(node.name, 'mult', lut=c['lut'], ff=c['ff'], dsp=c['dsp'], srl=c.get('srl', 0),
                   sel=c.get('pair', 0), note='dsp ' + c['note'], parts=c['parts'])
    st = sched.stages[node.name]
    fl = tuple(sched.flags.get(node.name, ()) or ())
    if node.backend == 'booth' and fl:
        # the cells `Bmult_RTL_gen` writes: partial-product LUT5 / LUT6_2 cells, the counters and the
        # adder of its compressor (all primitives, one site each: no packing), and the registers
        # after the flagged units, each cut to what the consumers of bits lo..hi keep alive
        from .heapcount import boothCounts
        wa, wb = dp.boothWidths(node)
        c = boothCounts(wa, wb, fl, lo, hi)
        sites = c['pp'] + c['comp'] + c['term']
        return Row(node.name, 'mult', lut=round(sites / LUT_PACK), ff=c['ff'],
                   note=f'booth {wa}x{wb}: pp {c["pp"]} + counters {c["comp"]} + adder {c["term"]} sites',
                   parts={f'{node.name}_r': c['ff']})
    r = dp.nodeResources(node, sched)
    return Row(node.name, 'mult', lut=r.lut, dsp=r.dsp, ff=st * _pop(live),
               note=f'{node.backend or "behavioural"}: registers as output width')


def portLoads(dp, port: str) -> list:
    """Loads of every bit of the datapath input `port`: per reader one load, and for a Booth
    multiplier the partial-product cells that read the bit (`heapcount.boothOperandLoads`)."""
    from .heapcount import boothOperandLoads
    loads = None
    for node in dp.nodes:
        names = set(node.inputs) | {node.a, node.b, node.qwire}
        if port not in names:
            continue
        if node.kind == 'mult' and node.backend == 'booth' and port in (node.a, node.b):
            la, lb = boothOperandLoads(*dp.boothWidths(node))
            per = la if node.a == port else lb
        else:
            per = ()
        n = max(1, len(per))
        if loads is None:
            loads = [0] * n
        elif len(loads) < n:
            loads += [0] * (n - len(loads))
        for b in range(len(loads)):
            loads[b] += per[b] if b < len(per) else 1
    return loads or []


def portCopies(dp, port: str, width: int, limit: int = 16) -> int:
    """Register bits of one copy register of `port` (width bits) that carries `max_fanout = limit`:
    one flip-flop per bit and one more per `limit` loads above the first."""
    loads = portLoads(dp, port)
    return sum(max(1, -(-(loads[b] if b < len(loads) else 1) // limit)) for b in range(width))


def nodeRows(dp, sched) -> list:
    from .heapcount import heapLayerCols, heapLayerOrigins, firstCarryColumn
    live = liveBits(dp, sched)
    rows = []
    delayOf = {dn: (src, cyc) for dn, src, cyc in sched.delays}

    def wireOf(w):
        '''(undelayed wire, cycles of delay) of a wire name as a consumer sees it.'''
        return delayOf.get(w, (w, 0))

    # readers of every wire as the consumers see it (a delayed copy is another wire)
    readers: dict[str, list] = {}
    for nd in dp.nodes:
        for w in set(sched.renamed.get(nd.name, ()) or ()):
            readers.setdefault(w, []).append(nd)
    outWires = {sched.renamed['__outputs__'].get(port, w) for port, w in dp.outputs}

    def mergedSelect(node, st):
        '''An unregistered 2:1 select read only by one behavioural adder: synthesis puts the select
        into the adder's LUTs (routed unified butterfly: `x_r0` has 44 cells for select and adder).'''
        if st or node.name in outWires:
            return False
        rd = readers.get(node.name, [])
        if len(rd) == 1 and rd[0].kind == 'heap' and (not node.a or not node.b):
            return True                         # a gate: an input of the adder's or subtracter's own LUTs
        return len(rd) == 1 and rd[0].kind == 'heap' and dp.heapStrategy(rd[0]) == 'adder'

    def copyKeys(w, mask, later=1):
        base, cyc = wireOf(w)
        return {(base, b, cyc + later) for b in range(mask.bit_length()) if mask >> b & 1}
    for node in dp.nodes:
        m = live.get(node.name, 0)
        st = sched.stages.get(node.name, 0)
        fl = tuple(sched.flags.get(node.name, ()) or ())
        lo, hi = _span(m)
        n = node.name
        ren = dict(zip(node.inputs, sched.renamed[node.name]))
        if not m:
            rows.append(Row(n, node.kind, note='unused'))
            continue
        if node.kind == 'heap':
            strat = dp.heapStrategy(node)
            if strat == 'wire':
                rows.append(Row(n, 'heap', note='wire'))
                continue
            adesc, heights, need, hi = _heapNeed(dp, node, m)
            colH = {e[0]: len(e) - 1 for e in adesc}
            sig = {e[0]: sum(1 for b in e[1:] if not b[3]) for e in adesc}
            cst = {e[0]: sum(1 for b in e[1:] if b[3]) for e in adesc}
            cols = [c for c in sorted(colH) if need <= c <= hi]
            if strat == 'adder':
                # one LUT per column that adds two bits or takes a carry
                c0 = firstCarryColumn([colH.get(c, 0) for c in range(max(colH) + 1)])
                lut = sum(1 for c in range(max(need, c0), hi + 1))
                ff = st * _pop(m)
                rows.append(Row(n, 'heap', lut=lut, ff=ff, note=f'adder cols {max(need, c0)}..{hi}',
                                parts={f'{n}_r': ff}))
                continue
            from .heapcount import heapLuts
            hs = tuple(heights)
            comp, term = heapLuts(hs)
            layerCols = heapLayerCols(hs)
            # share of the compressor that the consumer needs (columns need..hi of the heap)
            width = len(layerCols[-1])
            keep = sum(1 for c in range(width) if need <= c <= hi) / max(1, width)
            keys = set()
            if len(fl) == len(layerCols):
                ff = 0
                origins = heapLayerOrigins(hs)
                byCol = {e[0]: e[1:] for e in adesc}
                regs = 0
                for i, f in enumerate(fl):
                    if not f:
                        continue
                    regs += 1
                    if i == len(fl) - 1:
                        ff += _pop(m)
                        continue
                    for c, col in enumerate(origins[i]):
                        if not need <= c <= hi:
                            continue
                        for org in col:
                            src = None
                            if org is not None:
                                bits = byCol.get(org[0], ())
                                if len(bits) == hs[org[0]] and org[1] < len(bits):
                                    src = bits[org[1]]
                            if src is None:
                                ff += 1                      # made by a counter, or not traceable
                            elif src[3] or src[0] is None:
                                pass                         # a constant: no register
                            else:
                                base, cyc = wireOf(ren.get(src[0], src[0]))
                                keys.add((base, src[1] or 0, cyc + regs))
            else:
                ff = st * _pop(m)
            plain = max(hs, default=0) == 3 and comp == 0
            # LUT1 buffers on the pinned chain-start vectors when one signal bit feeds several of them
            # (`heapcount.heapPinBuffers`), priced with BUF_PACK
            buf = 0
            if PIN_BUFFERS and comp:
                from .heapcount import heapPinBuffers
                srcOf = {e[0]: [None if (b[3] or b[0] is None) else (ren.get(b[0], b[0]), b[1] or 0)
                                for b in e[1:]] for e in adesc}
                if all(len(srcOf.get(c, ())) == h for c, h in enumerate(hs)):
                    buf = heapPinBuffers(hs, fl if len(fl) == len(layerCols) else (False,) * len(layerCols), srcOf)
            rows.append(Row(n, 'heap', lut=round((comp + term) * keep) + buf, buf=buf, ff=ff + len(keys), keys=keys,
                            note=f'compressor {len(layerCols) - 1} layer(s), cols {need}..{hi} of {width}'
                                 f'{" plain add" if plain else ""}, comp {comp} term {term}, copies {len(keys)}'
                                 f'{f", pin buffers {buf}" if buf else ""}',
                            parts={f'u_{n}_cmp': ff}))
            continue
        if node.kind == 'mult':
            rows.append(_multRow(dp, node, sched, m))
            continue
        base = dp.nodeResources(node, sched).lut
        if node.kind in ('table', 'select'):
            per = max(1, base // max(1, node.bitWidth))
            lut = _pop(m) * per
            two = node.kind == 'select' and per == 1
            if two and mergedSelect(node, st):
                rows.append(Row(n, node.kind, note='select inside the adder that reads it'))
                continue
            rows.append(Row(n, node.kind, lut=lut, sel=lut if two else 0,
                            ff=st * _pop(m), parts={f'{n}_r': st * _pop(m)}))
            continue
        if node.kind == 'nonzero':
            rows.append(Row(n, 'nonzero', lut=base, ff=st, parts={f'{n}_r': st}))
            continue
        cw = dp.correctWidth(node)
        if node.fold == 'compare':
            mid = bool(fl and fl[0])
            mm = [w for w in node.qMults if w]
            held = 0 if (node.kind == 'correct' or (mm and mm[0] in dp.static)) else cw
            keys = set()
            ffMid = 0
            if mid:                 # x (and a run-time k*q) held one cycle: plain copies of their wires
                ffMid = 1
                sw = ren.get(node.src, node.src)
                keys |= copyKeys(sw, _mask(0, dp.width(node.src) - 1))
                if held:
                    mw = ren.get(mm[0], mm[0])
                    keys |= copyKeys(mw, _mask(0, dp.width(mm[0]) - 1))
            ffOut = (st - (1 if mid else 0)) * node.bitWidth
            rows.append(Row(n, node.kind, lut=base, ff=ffMid + ffOut + len(keys), keys=keys,
                            note=f'compare fold cw {cw}{" mid register" if mid else ""}',
                            parts={f'{n}_xr': ffMid, f'{n}_r': ffOut}))
        else:
            rows.append(Row(n, node.kind, lut=base, ff=st * node.bitWidth,
                            note=f'{node.fold or "select"} cw {cw}', parts={f'{n}_r': st * node.bitWidth}))
    # balancing delays: the delays of one wire are one tapped chain
    bySrc: dict[str, list] = {}
    for dn, src, cyc in sched.delays:
        bySrc.setdefault(src, []).append((cyc, dn))
    # a wire assembled from slices and constants (q = QH * 2^k + 1): the constant bits need no
    # delay register (measured, 32-bit word-level Montgomery: `q_rt_d11` 16 SRL + 16 FF of 32 bits)
    varying = {}
    for node in dp.nodes:
        if node.kind == 'heap' and node.name in bySrc and any(t.source == 'const' for t in node.terms) \
                and dp.heapStrategy(node) == 'wire':
            vm = 0
            for t in node.terms:
                if t.source != 'const':
                    vm |= _mask(t.limbShift, t.limbShift + t.sliceEnd - t.sliceStart)
            varying[node.name] = vm
    for src, taps in bySrc.items():
        taps.sort()
        prev = 0
        isInput = src in dp.inputs
        keepLast = src in getattr(dp, 'shared', ())
        for i, (cyc, dn) in enumerate(taps):
            seg = cyc - prev
            prev = cyc
            mask = live.get(dn, 0)
            for c, d in taps:
                if c > cyc:
                    mask |= live.get(d, 0)
            mask &= varying.get(src, -1)
            w = _pop(mask)
            first = isInput and i == 0
            srl, ff = delayCells(seg, w, first)
            nff = 1
            if keepLast and i == 0:
                # the emitter keeps the last register of a line from a shared source (a per-frame modulus
                # constant) as a flip-flop of its own (no SRL, no merging); the stages before it are an
                # ordinary chain (routed: MU_d3 three flip-flops per bit; Q_d7, Q_d6, Q_d5, Q_d4 one SRL
                # + two flip-flops per bit, at 28 to 44 bit)
                srl, ff = delayCells(seg - 1, w, first)
                nff = (ff // w if w else 0) + 1
                ff += w
            elif keepLast and seg >= 2:
                # a later tap of such a line: the stages after the previous tap are one SRL, the kept last
                # register is the flip-flop behind it (routed at 2, 3, 4 and 5 stages, 28 to 44 bit)
                srl, ff = w * -(-(seg - 1) // 16), w
            keys = set()
            if ff:                  # the flip-flop stages are plain copies of the wire
                stages = range(cyc - seg + 1, cyc + 1) if not srl else range(cyc - nff + 1, cyc + 1)
                keys = {(src, b, j) for j in stages for b in range(mask.bit_length()) if mask >> b & 1}
            rows.append(Row(dn, 'delay', srl=srl, ff=len(keys), keys=keys,
                            note=f'{w} bit x {seg} cycle(s){" from an input" if first else ""}'))
    return rows


BUF_PACK = 0.65      # LUT sites per LUT1 buffer of a pinned compressor input: about half of them share a site
                     # with another buffer (routed: constant Shoup butterfly of df_n256_shoup52 321 cells in 203
                     # sites, 0.63; W_S_shou52_n16_P16 15201 in 9552, 0.63; W_S_shou52_n64_P8 4256 in 2910, 0.68)
PIN_BUFFERS = True   # count the LUT1 buffers of pinned chain-start vectors (step 5; False = step 4 model)
SRL_MIN = 3          # Vivado's shreg_min_size: shorter register chains stay flip-flops
LUT_PACK = 0.95      # LUT sites per LUT cell of a datapath: the placer puts some pairs of small LUTs in
                     # one site (measured on 12 routed butterflies, 28 to 64 bits: 0.93 to 0.98)
SRL_PER_LUT = 2      # two SRL16 share one LUT site
SEL_PACK = 0.57      # LUT sites per cell of a 2:1 select node with a shared select (the operand and output
                     # selects of a unified butterfly): two fit one LUT6_2 (routed per module, 30 to 60 bits:
                     # m 22 of 44 and 16 of 32, ysel 25 of 44). The select half of a correction packs the
                     # same way (br_c 23 to 27 of 44, x_c 26 of 44) while the other cells of a butterfly pack
                     # 0.96 to 0.99; LUT_PACK is the average of those two over a plain butterfly, so only the
                     # select nodes are priced apart.


def lutSites(c: 'Counts') -> int:
    '''LUT sites a utilisation report counts for these cells (logic + shift registers).'''
    sel = min(c.lut, getattr(c, 'sel', 0))
    buf = min(c.lut - sel, getattr(c, 'buf', 0))
    return (round((c.lut - sel - buf) * LUT_PACK) + round(sel * SEL_PACK) + round(buf * BUF_PACK)
            + -(-c.srl // SRL_PER_LUT))


def delayCells(cycles: int, width: int, fromInput: bool, copyReader: bool = False) -> tuple[int, int]:
    '''(SRL16 cells, flip-flops) of one delay segment of `width` live bits. `copyReader`: the reader
    is known to be the registered first layer of a product sum (the alignment delays inside a DSP
    multiplier), so a delay of exactly SRL_MIN stages is an SRL with that layer as its last stage
    (routed: 60-bit word-level Montgomery `u_mp`, Shoup 44 `u_sx`, no delay flip-flop).'''
    if cycles <= 0 or width <= 0:
        return 0, 0
    if copyReader and cycles == SRL_MIN and not fromInput:
        return width, 0
    # A chain of SRL_MIN stages or more is one SRL16 per bit for all stages but the last, and the last
    # stage stays a flip-flop behind it (measured on input chains and on internal ones: run-time Barrett
    # `mp_d5` / `mp_d8` n SRL + n FF; three stages too: Shoup `sab_d3` 45 SRL2 + 45 FF, word-level
    # Montgomery `w2t_d3` 63 SRL2 + 63 FF). When the reader of a bit is a plain registered copy (the
    # first registered layer of a compressor), that copy is the flip-flop behind the SRL and the delay
    # has none of its own: `chainAbsorb` (`mp_d3`, `w0t_d3` of the 60-bit word-level Montgomery
    # butterfly 150 SRL3 and no register; `mp_d4`, `w0t_d4` of the 64-bit one 160 SRL4 and no register).
    if cycles < SRL_MIN:
        return 0, cycles * width
    return width * -(-(cycles - 1) // 16), width


def chainAbsorb(rows) -> tuple[int, set]:
    '''(extra SRL cells, register keys they replace). A delay of fewer than SRL_MIN stages stays in
    flip-flops on its own, but when the only reader of a bit is a plain registered copy (a heap bit
    that passes the first registered layer untouched) the chain is one stage longer: synthesis then
    packs the delay stages of that bit into one SRL16 and keeps the copy as the flip-flop behind it
    (measured: Barrett 64 `mp_d2` 62 SRL + 5 FF of 130 emitted; Montgomery 44 `mp_d2` 32 SRL).
    A longer delay (SRL + flip-flop) read by such a copy loses its own flip-flop the same way.'''
    copies = set()
    for r in rows:
        if r.kind != 'delay':
            copies |= r.keys
    srl, gone = 0, set()
    for r in rows:
        if r.kind != 'delay' or not r.keys:
            continue
        byBit: dict = {}
        for (w, b, j) in r.keys:
            byBit.setdefault((w, b), []).append(j)
        for (w, b), js in byBit.items():
            if (w, b, max(js) + 1) not in copies:
                continue
            if r.srl:               # SRL + flip-flop: the copy is the flip-flop, the delay's own joins the SRL
                gone.add((w, b, max(js)))
            elif len(js) + 1 >= SRL_MIN:
                srl += 1
                gone |= {(w, b, j) for j in js}
    return srl, gone


def totals(dp, sched) -> Counts:
    t = Counts()
    keys = set()
    rows = nodeRows(dp, sched)
    for r in rows:
        t.lut += r.lut
        t.sel += r.sel
        t.buf += r.buf
        t.srl += r.srl
        t.ff += r.ff - len(r.keys)
        t.dsp += r.dsp
        keys |= r.keys
    srl, gone = chainAbsorb(rows)
    t.srl += srl
    t.ff += len(keys - gone)    # copies of one signal bit merge into one register
    return t


def portChainCounts(dp, sched, ports) -> Counts:
    '''Cells of the balancing delays of the input ports `ports` that synthesis shares between
    instances fed from the same net (the modulus of a pass or a lane group): the delays of wires
    that only rename such a port (a heap emitted as a wire, `q_rt` of a word-level Montgomery
    multiplier) and the shift register of the port's own first delay; the flip-flop behind it and
    the later segments stay in every instance. `totals` counts all of it once per datapath, so a
    type-level model subtracts this from all but one instance per group. Measured, 32-bit
    word-level Montgomery butterflies of one sub-transform (multi-step row OB_base): 789 FF +
    162 SRL in the one that keeps the chains, 720 + 130 in the 15 others; model 775 with,
    775 - 48 = 727 without. Butterflies fed from their own registered copy of the port
    (iterative cores) keep theirs.'''
    ports = set(ports)
    renamed = set()
    for node in dp.nodes:
        if node.kind == 'heap' and node.inputs and all(i in ports or i in renamed for i in node.inputs) \
                and dp.heapStrategy(node) == 'wire':
            renamed.add(node.name)
    src = {dn: s for dn, s, _ in sched.delays}
    c = Counts()
    for r in nodeRows(dp, sched):
        if r.kind != 'delay':
            continue
        if src.get(r.name) in renamed:
            c.srl += r.srl
            c.ff += r.ff
        elif src.get(r.name) in ports and 'from an input' in r.note:
            c.srl += r.srl
    return c
