'''Area of a multi-step NTT without a build: LUT, FF, DSP, BRAM36, URAM.

`inventory(scheme)` walks the spec the RTL generator reads (`MultiStepNTT.spec`) in the generator's own order
(`rtl_gen.multistep.MultiStep_RTL_gen`) and lists every part it emits:

    transposes   per group: two radix-4 barrel shifters (hand-placed LUT6_2), their stage registers, one memory per
                 lane (LUT RAM up to 64 words, block / ultra RAM above), the read register, the control; tag delay
    passes       the sub-NTT copies, priced by the streaming-NTT inventory (`operator_modeling.ntt.dataflow.StreamArea`,
                 helper "dataflow"), which prices butterflies and multipliers by the shared component models
    twiddle      tables (address register, memory, extra read registers of `ramLatency`), frame counter, data
    blocks       delays, generators, multipliers, modulus-table copies, valid shift register, tag delay; the tree
    folded form  port tables per stage offset, address delays, DIR registers and muxes, data / valid / tag delays
    cross        plain registers (crossRegs)
    load port    counter, data and flag registers (max_fanout 32)
    output FIFO  memory, two data registers, pointers and counters (outReady)

The mapping rules are those of `StreamArea` (R1 to R9: SRL from 3 stages, two SRL16 per LUT site, RAM delay
from 64 cycles, RAM32M16 / RAM64M8, LUT ROM by distinct columns, ...) plus the transpose rules T1 to T4 below.
Every rule is a count of what the RTL holds; none is fitted per design. `fourstep/MODEL_ACCURACY.md` of
`ntt_hw/experiments/overnight_2026-11-14` lists the evidence (routed, core alone, 350 MHz, Vivado 2025.1).

    inventory(scheme, pipelineStages=1) -> [ {block, cls, what, n, lut, ff, dsp, bram36, uram, srl, lutram}, ... ]
    totals(parts)                       -> {lut, ff, dsp, bram36, uram, au, byClass, byBlock}
    area(scheme)                        -> totals(inventory(scheme))

Nothing here changes what the generator emits.
'''
from __future__ import annotations

import contextlib
import io

KEYS = ('lut', 'ff', 'dsp', 'bram36', 'uram', 'srl', 'lutram')

# --- transpose rules -------------------------------------------------------------------------------------------
#: T1  barrel shifter: S * W LUT6_2 per radix-4 stage, S * ceil(W / 2) for a last 2:1 stage (hand placed: exact)
#: T2  shifter stage registers: S * W flip-flops per registered stage (REG_FLAGS), both shifters
#: T3  memory per lane: LUT RAM (R5) + a read register of W flip-flops up to 64 words; block / ultra RAM above
#:     (its read register is the memory's own)
#: T4  control per group: address subtract and phase mux per lane, counters, sidebands
T_CTRL_LUT_PER_LANE = 6.0
T_CTRL_FF_PER_LANE = 2.0
T_CTRL_FF = 26
#: a register whose only load is a delay line of 2 and more cycles joins that line (R1): the registered last
#: stage of a transpose's second shifter in front of a twiddle block or a folded pass
#: DIR choice of the folded_gs form: a registered 2:1 mux; synthesis moves part of it to the set/reset pins and
#: the placer's control-set merge puts a LUT2 back in front of about a third of the bits (`ps_ctrlset_*`).
#: Counted on routed MS_N10_q32_P32_tpgda (5120 such registers): 3968 LUT2 in 1984 sites inside the table
#: modules + 1805 `ps_ctrlset` LUT2 sites, less the 992 sites of the one-word tables = 0.55 site per bit
#: (0.3 before, set when the unified butterfly was priced 7 % too high)
DIRMUX_LUT_PER_BIT = 0.55
#: max_fanout of the load-port registers and of the DIR registers
LOAD_FANOUT = 32


def _z(**kw) -> dict:
    d = dict.fromkeys(KEYS, 0.0)
    d.update(kw)
    return d


def _sa():
    from ..dataflow import StreamArea
    return StreamArea


def _quiet(fn, *a, **kw):
    with contextlib.redirect_stdout(io.StringIO()):
        return fn(*a, **kw)


def barrelStages(S: int) -> tuple[int, int]:
    '''(radix-4 stages, 1 if a last 2:1 stage) of `barrel_shift.sv` for S lanes.'''
    s = S.bit_length() - 1
    return s // 2, s % 2


def transposeGroup(S: int, lo: int, W: int, flags: int, ramStyle: str, tiles: dict | None = None,
                   absorbed: bool = False) -> dict:
    '''One `lt_bmb_transpose` (S lanes of W bits, window S << lo words per lane). `flags`: REG_FLAGS (bit s: a
    register after shifter stage s). `tiles`: {'bram36', 'uram'} of one lane's memory when it is not LUT RAM.
    `absorbed`: the last stage register of the second shifter feeds only a delay line and joins it.'''
    SA = _sa()
    win = S << lo
    r4, r2 = barrelStages(S)
    stages = r4 + r2
    shifter = S * W * r4 + S * -(-W // 2) * r2
    nreg = sum(1 for i in range(stages) if (flags >> i) & 1)
    r = _z(lut=2 * shifter + T_CTRL_LUT_PER_LANE * S, ff=T_CTRL_FF_PER_LANE * S + T_CTRL_FF)
    regs = 2 * nreg
    if absorbed and stages and (flags >> (stages - 1)) & 1:
        regs -= 1
    r['ff'] += regs * S * W
    if ramStyle == 'distributed':
        n = S * SA.lutRam(win, W)
        r['lut'] += n
        r['lutram'] += n
        r['ff'] += S * W
    else:
        r['bram36'] += S * (tiles or {}).get('bram36', 0)
        r['uram'] += S * (tiles or {}).get('uram', 0)
    return r


def romSupportLut(k: int) -> float:
    """LUT sites of one ROM column that depends on `k` address bits (rule T5; measured on routed tables of 32, 64 and
    128 words): up to 5 bits two columns share a site; 6 bits one LUT6; 7 bits two LUT6 and a mux that shares a
    site with another column's (Versal has no MUXF7), 8 bits twice that; larger about 1.25 LUT per 64 words."""
    if k <= 1:
        return 0.0
    if k <= 5:
        return 0.5
    if k == 6:
        return 1.0
    return 1.25 * (1 << (k - 6))


_LO = {}


def _loMask(k: int, j: int) -> int:
    if (k, j) not in _LO:
        _LO[(k, j)] = sum(1 << a for a in range(1 << k) if not (a >> j) & 1)
    return _LO[(k, j)]


def romCost(values: list[int], W: int) -> dict:
    """A distributed ROM by its distinct non-constant columns, each priced by the address bits it really depends on
    (a column that is one address bit or its inverse costs no LUT); one read register bit per distinct column."""
    n = len(values)
    k = max(1, (n - 1).bit_length())
    vals = list(values) + [values[-1]] * ((1 << k) - n)
    cols = {}
    for b in range(W):
        m = 0
        for a, v in enumerate(vals):
            m |= ((v >> b) & 1) << a
        if m == 0 or m == (1 << (1 << k)) - 1 or m in cols:
            continue
        sup = 0
        for j in range(k):
            lo = _loMask(k, j)
            if (m & lo) != ((m >> (1 << j)) & lo):
                sup += 1
        cols[m] = sup
    return _z(lut=sum(romSupportLut(c) for c in cols.values()), ff=len(cols))


def renamedPortShare(x, ps: int = 1) -> dict:
    """R-MS7, read cell by cell from routed OB_base, OB_unified and HO_N10_q60_P32 (`fourstep/logs/cmp_cells_*.txt`):
    a component node that only renames modulus-port bits (word-level Montgomery `q_rt` = {QH, 0...01}) has delay
    lines that are equal in every instance fed by the same modulus register. Synthesis keeps one copy: an instance
    that is not the first of its group has none of them (butterfly 787 -> 691 flip-flops in the model, 60-bit
    1666 -> 1486, routed 1484), the first keeps the port's own bit columns (`q_rt_d11`: 16 FF + 16 SRL of 32 + 32).
    Returns {'ff', 'srl'} to ADD to every instance and {'shFf', 'shSrl'} once per modulus register."""
    out = dict(ff=0.0, srl=0.0, shFf=0.0, shSrl=0.0)
    try:
        from ...core import emitcount as EC
        inner = x.inner() if hasattr(x, 'inner') else x
        dp, sched = inner.datapath(), inner.schedule(ps)
        rows = _quiet(EC.nodeRows, dp, sched)
    except Exception:
        return out
    ports = {getattr(i, 'name', i) for i in dp.inputs} - {'A', 'B', 'W', 'WP', 'DIR'}
    node = {n.name: n for n in dp.nodes}
    pbits = {}
    for r in rows:
        if r.kind == 'delay' and 'from an input' in r.note and r.name.rsplit('_d', 1)[0] in ports:
            try:
                pbits[r.name.rsplit('_d', 1)[0]] = int(r.note.split(' bit')[0])
            except ValueError:
                pass
    wires = {}
    for r in rows:
        n = node.get(r.name)
        if r.kind == 'delay' or r.note != 'wire' or n is None or not n.inputs:
            continue
        ins = [getattr(i, 'name', i) for i in n.inputs]
        if all(i in ports for i in ins):
            wires[r.name] = min(1.0, sum(pbits.get(i, n.bitWidth) for i in ins) / max(1, n.bitWidth))
    for r in rows:
        if r.kind != 'delay' or '_d' not in r.name:
            continue
        base = r.name.rsplit('_d', 1)[0]
        if base in wires:
            out['ff'] -= r.ff
            out['srl'] -= r.srl
            out['shFf'] += r.ff * wires[base]
            out['shSrl'] += r.srl * wires[base]
    return out


def _renamedShare(SA, x, ps) -> dict:
    """`renamedPortShare`, or zeros when StreamArea's own `componentTrim` already takes these delay lines off
    (asked in SHARED_REQUESTS 2026-11-14 06:50; `StreamArea.RENAMED_PORT_SHARED` or a trim of that size)."""
    t = renamedPortShare(x, ps)
    if t['ff'] and getattr(SA, 'RENAMED_PORT_SHARED', False):
        return dict(ff=0.0, srl=0.0, shFf=0.0, shSrl=0.0)
    return t


def _passInventory(SA, sub, ps):
    """StreamArea's inventory of a sub-NTT (on the spec of the sub-NTT's own operator), with rule R-MS7 added at
    every component whose modulus comes from a register of the core (StreamArea's `trim` sites)."""
    w = SA._Walk(sub, ps)
    if not getattr(SA, 'TRIM', False) or not hasattr(w, 'trim'):
        return w.parts
    runtime = bool(getattr(w, 'pf', None)) or bool(w.spec.roms.get('qPorts'))
    if not runtime:
        return w.parts
    orig, seen, cache = w.trim, set(), {}

    def trim(cls, what, key, obj, site):
        orig(cls, what, key, obj, site)
        if key not in cache:
            cache[key] = _renamedShare(SA, obj, ps)
        t = cache[key]
        if t['ff'] or t['srl']:
            w.add(cls, f'{what}: delay lines of a renamed modulus port, kept once (R-MS7)', 1,
                  _z(ff=t['ff'], srl=t['srl'], lut=t['srl'] / SA.SRL16_PER_LUT))
            if (cls, site) not in seen:
                seen.add((cls, site))
                w.add(cls, f'{what}: the one copy of the renamed modulus port delay lines (R-MS7)', 1,
                      _z(ff=t['shFf'], srl=t['shSrl'], lut=t['shSrl'] / SA.SRL16_PER_LUT))
    w.trim = trim
    w.parts = []
    w.struct = {k: ([] if isinstance(v, list) else 0) for k, v in w.struct.items()}
    w.run()
    return w.parts


def _placedTiles(mt: dict, depth: int, width: int) -> dict:
    '''`memoryTiles` decides BRAM or URAM with whole tiles (the generator's rule, kept). For the count of a BRAM
    memory Vivado packs the last bit column into a RAMB18 when it fits one (measured: 2048 x 60 = 3 RAMB36 +
    1 RAMB18 per lane in the transposes of the 2^16 rows), as `StreamArea.bramTiles` counts, but it does not
    stack RAMB18 in depth (measured: a 1536 x 32 table is 2 RAMB36, not 3 RAMB18, in every lane of
    HO_N13_q32_P32, `fourstep/hier/HO_N13_q32_P32.rams.txt`).'''
    if mt['uram'] or not mt['bram36']:
        return mt
    SA = _sa()
    best = mt['bram36']
    for d, w in SA.BRAM36_SHAPES:
        rows = -(-depth // d)
        full, rest = divmod(width, w)
        t = rows * full
        if rest:
            half = rows == 1 and any(d18 >= depth and w18 >= rest for d18, w18 in SA.BRAM18_SHAPES)
            t += rows * (0.5 if half else 1.0)
        best = min(best, t)
    return dict(mt, bram36=best)


class _Walk:
    def __init__(self, s, ps: int = 1, name: str = 'm'):
        from .MultiStepNTT import MultiStepNTT
        self.s, self.ps = s, ps
        self.spec = _quiet(MultiStepNTT(s).spec, name, None)
        self.parts: list[dict] = []
        self._comp = {}
        self._pass = {}
        self.run()

    def add(self, block, cls: str, what: str, n: float, r: dict) -> None:
        if n and any(r.get(k) for k in KEYS):
            p = {k: r.get(k, 0) * n for k in KEYS}
            p.update(block=block, cls=cls, what=what, n=n)
            self.parts.append(p)

    def dly(self, block, cls, what, W, D, n=1, tail=True):
        if W and D:
            r = _sa().delay(W, D, tail)
            if what == 'MIDX delay' and r.get('bram36'):
                # MIDX delays of one block all start at the block's tag: two of the same depth are the same RAM
                # and synthesis keeps one (routed 2^14 and 2^16 rows: one RAMB18 where the RTL has two)
                seen = self.__dict__.setdefault('_midxRam', set())
                if (block, W, D) in seen:
                    return
                seen.add((block, W, D))
            self.add(block, cls, f'{what} (W {W}, D {D})', n, r)

    def comp(self, key, obj) -> dict:
        if key not in self._comp:
            r = _quiet(obj.resources, self.ps)
            self._comp[key] = _z(lut=r.lut, ff=_quiet(obj.flipFlops, self.ps), dsp=r.dsp,
                                 bram36=getattr(r, 'bram36', 0) + getattr(r, 'bram18', 0) / 2)
        return self._comp[key]

    def shareQ(self, block, cls, key, users) -> None:
        '''The multipliers of one modulus register (a `<name>_mtab` copy): StreamArea's R13 c (the first stages of
        a modulus port's delay line once per register) and R-MS7 (`renamedPortShare`).'''
        SA = _sa()
        if not getattr(SA, 'TRIM', False):
            return
        k = ('share', key)
        if k not in self._comp:
            x = self.s.multiplier(key)
            table = {p: self.spec['qtable'][p] for p, _ in self.spec['qwidths']}
            c = _quiet(SA.componentTrim, x, self.ps, table, shared=True)
            r = _renamedShare(SA, x, self.ps)
            self._comp[k] = (_z(ff=c['ff'] + r['ff'], srl=c['srl'] + r['srl'], lut=c['lut'] + r['srl'] / SA.SRL16_PER_LUT),
                             _z(ff=c['shFf'] + r['shFf'], srl=c['shSrl'] + r['shSrl'],
                                lut=c['shLut'] + r['shSrl'] / SA.SRL16_PER_LUT))
        each, once = self._comp[k]
        self.add(block, cls, 'multiplier in the core: modulus delay lines shared (R13, R-MS7)', users, each)
        self.add(block, cls, 'modulus delay lines, one copy per modulus register (R13, R-MS7)', 1, once)

    def passCost(self, sub) -> dict:
        '''One copy of a sub-NTT: the streaming inventory at P = n (all classes summed).'''
        if id(sub) not in self._pass:
            SA = _sa()
            inv = _quiet(_passInventory, SA, sub, self.ps)
            t = SA.totals(inv)
            self._pass[id(sub)] = (_z(**{k: t.get(k, 0) for k in KEYS}), t.get('byClass', {}))
        return self._pass[id(sub)]

    def mem(self, depth, W, style, mode='rom', values=None) -> dict:
        '''A table of the multi-step top (registered address is counted by the caller): `style` is the
        attribute the RTL carries (distributed | block | ultra).'''
        SA = _sa()
        from .MultiStepScheme import memoryTiles
        s = self.s
        if style == 'distributed' or style is None:
            return SA.memory(depth, W, mode, 'distributed', values)
        mt = _placedTiles(memoryTiles(depth, W, s.memStyle, s._uramMinDepth), depth, W)
        return _z(bram36=mt['bram36'], uram=mt['uram'])

    def table(self, block, cls, tbl, abits, n=1, absorbed=False):
        TL, W = self.TL, self.W
        if self.stream:
            return
        mode = 'ram' if tbl.get('ram') else 'rom'
        if mode == 'rom' and tbl.get('romStyle') in ('distributed', None) and tbl.get('values') is not None:
            r = romCost(tbl['values'], W)
            if absorbed:
                r['ff'] = 0                                 # the read register merges with the user's input register
        elif mode == 'ram' and tbl['depth'] == 1:
            # one loadable word: W registers with a write enable and the read register; the enable is folded into
            # the D input (control-set remap, two LUT2 per site) and the write compare is shared with the load port
            self.add(block, cls, f"table of one loadable word x {W}", n, _z(lut=W / 2, ff=2 * W))
            return
        else:
            r = dict(self.mem(tbl['depth'], W, tbl.get('romStyle'), mode, tbl.get('values') if mode == 'rom' else None))
        r['ff'] += abits                                    # the registered address
        if TL > 2:
            r['ff'] += W * (TL - 2)                         # extra read registers, shreg_extract = "no"
        if mode == 'ram':
            r['lut'] += 3 + self.GB / 3                     # the write-enable window compare
            # 2026-11-16: the table's own write registers (enable, address, data word)
            r['ff'] += 1 + max(1, (tbl['depth'] - 1).bit_length()) + W
        self.add(block, cls, f"table depth {tbl['depth']} x {W} ({mode}, {tbl.get('romStyle')})", n, r)

    def mtab(self, block, at, users, ports=None):
        '''A copy of `<name>_mtab` (one LUT ROM column set and register per constant) and its MIDX delay.'''
        SA = _sa()
        sp = self.spec
        if sp.get('mtLoad'):
            # run-time moduli: no table copy. Every constant of this site is the polynomial's own, taken from the
            # tag and delayed `at` cycles (a RAM from 64 cycles on: these were the block RAMs the model missed)
            for p, w in (ports or sp['mtLoad']['ports']):
                if at >= 2:
                    # one delay line per group, one cycle short, and a register per four lanes of the group
                    self.dly(block, 'mtab', f'{p} delay', w, at - 1)
                    self.add(block, 'mtab', f'{p} register per four lanes', -(-users // 4), _z(ff=w))
                elif at >= 1:
                    self.dly(block, 'mtab', f'{p} delay', w, at)
            return
        r = _z()
        for p, w in sp['qwidths']:
            m = SA.memory(len(sp['moduli']), w, 'rom', 'distributed', sp['qtable'][p])
            for k in KEYS:
                r[k] += m[k]
        self.add(block, 'mtab', f'modulus table copy ({users} users)', 1, r)
        if at >= 2:
            self.dly(block, 'mtab', 'MIDX delay', self.IW, at - 1)

    def run(self) -> None:
        SA = _sa()
        s, sp = self.s, self.spec
        P, F, W = sp['P'], sp['F'], sp['W']
        IW, DP = sp['IW'], sp['dirPort']
        self.W, self.IW = W, IW
        FB = max(1, (F - 1).bit_length())
        TGW = IW + (1 if DP else 0)
        if sp.get('mtLoad'):
            # run-time moduli: the tag carries the modulus constants of the polynomial as well (multistep.py GW)
            TGW += sum(w_ for _, w_ in sp['mtLoad']['ports'])
        TL = self.TL = sp.get('tabLat', 2)
        self.stream = bool(sp.get('stream'))
        LD = sp.get('load')
        self.GB = 0
        blocks = sp['blocks']
        if LD:
            LDW = max([W] + [b.get('subTWW', 1) for b in blocks if b['kind'] == 'pass'])
            GB = self.GB = max(1, LD['words'].bit_length())
            users = sum(len(b['groups']) for b in blocks if b['kind'] == 'pass')
            users += sum(len(b.get('tables', ())) for b in blocks if b['kind'] == 'twiddle')
            users += sum(len(b['ports']['tables']) for b in blocks if b['kind'] == 'pass' and b.get('ports'))
            rep = max(1, -(-users // LOAD_FANOUT))
            self.add(-1, 'load', 'load port: word counter, data and flag registers', 1,
                     _z(ff=2 * GB + LDW * rep + 2, lut=GB + 2))
        cnt = _z(ff=FB, lut=FB) if F > 1 else _z()
        for bi, b in enumerate(blocks):
            k = b['kind']
            nxt = blocks[bi + 1] if bi + 1 < len(blocks) else None
            if k == 'transpose':
                S, lo = b['S'], b['lo']
                tiles = None
                if b['ramStyle'] != 'distributed':
                    from .MultiStepScheme import memoryTiles
                    tiles = _placedTiles(memoryTiles(S << lo, W, s.memStyle, s._uramMinDepth), S << lo, W)
                absorbed = bool(nxt) and (nxt['kind'] == 'twiddle' or (nxt['kind'] == 'pass' and nxt.get('ports')))
                self.add(bi, 'transpose', f"lt_bmb_transpose S {S}, LO {lo}, W {W}, flags {b['flags']:#x}, {b['ramStyle']}",
                         P // S, transposeGroup(S, lo, W, b['flags'], b['ramStyle'], tiles, absorbed))
                self.dly(bi, 'tag', 'tag delay', TGW, b['latency'])
            elif k == 'pass':
                pt = b.get('ports')
                if pt:
                    self.add(bi, 'ctl', 'frame counter', 1, cnt)
                    offs = pt.get('offs')
                    tuse = {}
                    if offs:
                        for row in pt['use']:
                            for u_, o_ in zip(row, offs):
                                for x_ in (u_ if isinstance(u_, (tuple, list)) else [u_]):
                                    tuse.setdefault(x_, set()).add(o_)
                        BW = FB + TGW
                        po = 0
                        for o_ in sorted(set(offs)):
                            if o_ > po:
                                self.dly(bi, 'ctl', 'address delay', BW, o_ - po)
                                po = o_
                    pairs = {(tuple(u_), o_) for row in pt['use'] for u_, o_ in zip(row, offs or [None] * len(row))
                             if isinstance(u_, (tuple, list))}
                    paired = {x_ for pr in pairs for x_ in pr[0]}
                    for tbl in pt['tables']:
                        td = DP and not tbl.get('dir')
                        abits = len(tbl['bits']) + (1 if td else 0) + IW
                        n = len(tuse.get(tbl['id'], ())) if offs else 1
                        # a word that goes straight to the pass's port register loses its read register (merged)
                        self.table(bi, 'porttab', tbl, abits, n, absorbed=(TL == 2 and tbl['id'] not in paired))
                    if pairs:
                        for o_ in {x[1] for x in pairs}:
                            n = sum(1 for x in pairs if x[1] == o_)
                            rep = max(1, -(-n * W // LOAD_FANOUT))
                            self.add(bi, 'dirmux', 'DIR registers (max_fanout 32)', 1, _z(ff=1 + rep))
                            if TL > 2:
                                self.dly(bi, 'dirmux', 'DIR delay', 1, TL - 2)
                        self.add(bi, 'dirmux', 'registered DIR choice of a table pair', len(pairs),
                                 _z(ff=W, lut=W * DIRMUX_LUT_PER_BIT))
                    self.dly(bi, 'dly', 'data delay of the table read', W, pt['lat'], P)
                    self.add(bi, 'ctl', 'valid shift register', 1, _z(ff=pt['lat']))
                    self.dly(bi, 'tag', 'tag delay', TGW, pt['lat'])
                c, by = self.passCost(b['sub'])
                self.add(bi, 'pass', f"sub-NTT {b['n']}-point x {len(b['groups'])}", len(b['groups']), c)
                if TGW and not IW:
                    self.dly(bi, 'tag', 'tag delay', TGW, b['latency'] - (pt['lat'] if pt else 0))
            elif k == 'twiddle':
                tl, ml, glat = b['latency'], b['mulLat'], b['genLat']
                pre_lat = tl - ml
                mul = self.comp('mul', s.multiplier('m_twmul'))
                if nxt and nxt['kind'] == 'pass':
                    # R-MS8: the multiplier's output register is the first stage of what the pass does with the lane
                    # (the A-side delay line or the DSP input register of the first butterfly): no flip-flops of its
                    # own (routed OB_base, OB_unified, HO_N10_q60_P32: `w1t_c` 0 of W in every twiddle multiplier)
                    mul = dict(mul, ff=mul['ff'] - W)
                gen = self.comp('gen', s.multiplier('m_twgen')) if b['gen'] else None
                MTq = bool(sp.get('mtLoad')) and bool(b['qports'])      # run-time moduli: constants from the tag
                qp = (b['qports'] and not LD) or MTq
                for tbl in b['tables']:
                    self.table(bi, 'tab', tbl, len(tbl['bits']) + (1 if DP else 0) + IW, absorbed=(TL == 2))
                self.add(bi, 'ctl', 'frame counter', 1, cnt)
                mts = {}

                def qsig(at, lane, kind):
                    if not qp:
                        return
                    key = (at, lane // b['modShare'], kind)
                    mts[key] = mts.get(key, 0) + 1
                tr = b.get('tree')
                if tr:
                    G = glat + tr.get('inreg', 0)
                    if tr.get('inreg'):
                        # the input registers of the tree multipliers (two operands each)
                        ngen = sum((1 if tr['two'] else 0) + (tr['depth'] - 1) + (len(gr['lanes']) - 1)
                                   for gr in tr['groups'])
                        self.add(bi, 'gen', 'tree: multiplier input registers', ngen, _z(ff=2 * W * tr['inreg']))
                    S0 = TL + (G if tr['two'] else 0)
                    for gr in tr['groups']:
                        gt = gr['tab']
                        l0 = gr['lanes'][0]
                        if tr['two']:
                            self.add(bi, 'gen', 'tree: Z generator', 1, gen)
                            qsig(TL, l0, 'gq')
                        hasY = 'y' in gt
                        if hasY:
                            self.dly(bi, 'dly', 'tree: Y delay', W, S0 - TL)
                        for lv in range(1, tr['depth']):
                            self.add(bi, 'gen', 'tree: square', 1, gen)
                            qsig(S0 + (lv - 1) * G, l0, 'gq')
                        wv = {0: (hasY, S0)}
                        for lv in range(tr['depth']):
                            for j in range(1 << lv, 1 << (lv + 1)):
                                src, at = wv[j - (1 << lv)]
                                t0 = S0 + lv * G
                                if not src:
                                    wv[j] = (True, S0 + lv * G)
                                    continue
                                self.dly(bi, 'dly', 'tree: level input delay', W, t0 - at)
                                self.add(bi, 'gen', 'tree: w(j) multiplier', 1, gen)
                                qsig(t0, l0, 'gq')
                                wv[j] = (True, t0 + G)
                        TT = S0 + tr['depth'] * G
                        for j, ln in enumerate(gr['lanes']):
                            src, at = wv[j]
                            self.dly(bi, 'dly', 'data delay', W, TT)
                            if not src:
                                self.dly(bi, 'dly', 'bypass delay', W, ml)
                                continue
                            self.dly(bi, 'dly', 'tree: word delay', W, TT - at)
                            self.add(bi, 'mul', 'twiddle multiplier', 1, mul)
                            qsig(TT, ln, 'mq')
                else:
                    for l, ln in enumerate(b['lanes']):
                        if ln is None:
                            self.dly(bi, 'dly', 'bypass delay', W, tl)
                            continue
                        if 'rom' not in ln:
                            self.add(bi, 'gen', 'twiddle generator', 1, gen)
                            qsig(TL, l, 'gq')
                        lat_here = TL + (glat if 'lo' in ln else 0)
                        # the multiplier's own A-side input register chain continues this line: no tail register
                        self.dly(bi, 'dly', 'data delay', W, lat_here)
                        if 'rom' in ln and pre_lat > TL:
                            self.dly(bi, 'dly', 'word delay', W, pre_lat - TL)
                            self.dly(bi, 'dly', 'data delay 2', W, pre_lat - TL)
                        self.add(bi, 'mul', 'twiddle multiplier', 1, mul)
                        qsig(pre_lat, l, 'mq')
                for (at, grp, kind), users in sorted(mts.items()):
                    if MTq:
                        self.mtab(bi, at, users, b['qports'])
                        continue
                    self.mtab(bi, at, users)
                    self.shareQ(bi, 'mul' if kind == 'mq' else 'gen', 'm_twmul' if kind == 'mq' else 'm_twgen', users)
                self.add(bi, 'ctl', 'valid shift register', 1, _z(ff=tl))
                self.dly(bi, 'tag', 'tag delay', TGW, tl)
            elif k == 'cross':
                n = b['n']
                self.add(bi, 'cross', f'{n} register stage(s), never shift registers', 1,
                         _z(ff=n * (P * W + 1 + TGW)))
            elif k == 'wire':
                pass
            else:
                raise ValueError(k)
        if sp.get('ready'):
            D = sp['ready']['depth']
            AW = D.bit_length() - 1
            DW = P * W + TGW
            from .MultiStepScheme import memoryTiles
            mt = _placedTiles(memoryTiles(D, DW, s.memStyle, s._uramMinDepth), D, DW)
            # memory; read register q (the memory's own) and output register o; in gate (fc, occ, in_ready),
            # pointers wp, rp, cnt, q_v, o_v; q_take / rd replicated by max_fanout 64
            rep = max(1, -(-DW // 64))
            self.add(len(blocks), 'ofifo', f'output FIFO {D} x {DW}', 1,
                     _z(bram36=mt['bram36'], uram=mt['uram'], ff=DW + FB + (AW + 1) + 1 + 2 * AW + (AW + 1) + 2 + 2 * rep,
                        lut=FB + 2 * (AW + 1) + SA._cmpLut(AW + 1) + 2 * AW + (AW + 1) + 8))


def inventory(scheme, pipelineStages: int = 1) -> list[dict]:
    return _Walk(scheme, pipelineStages).parts


def totals(parts: list[dict]) -> dict:
    t = dict.fromkeys(KEYS, 0.0)
    byC, byB = {}, {}
    for p in parts:
        for k in KEYS:
            t[k] += p[k]
        for d, key in ((byC, p['cls']), (byB, p['block'])):
            c = d.setdefault(key, dict.fromkeys(KEYS, 0.0))
            for k in KEYS:
                c[k] += p[k]
    t['au'] = (t['lut'] / 1000 + t['ff'] / 1000 + t['dsp'] * 4 / 3 + t['bram36'] + 8 * t['uram']) / 5
    t['byClass'], t['byBlock'] = byC, byB
    return t


def area(scheme, pipelineStages: int = 1) -> dict:
    '''{'lut', 'ff', 'dsp', 'bram36', 'uram', 'au', 'byClass', 'byBlock'} of the core.'''
    return totals(inventory(scheme, pipelineStages))
