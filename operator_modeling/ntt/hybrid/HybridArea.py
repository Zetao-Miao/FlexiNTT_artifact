"""Area model of the hybrid NTT (2026-11-14): a structural inventory of what `rtl_gen.hybrid_ntt` and
`rtl_gen.hybrid_ports` emit, plus a short list of synthesis rules measured on routed designs.

The inventory is analytic (no RTL is emitted, no table value is computed), so the explorer can call it.
Each part is one dictionary {'part', 'where', 'ff', 'lut', 'srl', ...}:
  where = 'comp'  butterflies, twist multipliers, twiddle generators (the shared component models),
          'mem'   RAMs and ROMs (block, ultra, LUT),
          'top'   registers and muxes of the core's top module,
          'wrap'  the port wrapper (HybridPorts).
'lut' counts physical LUTs (logic + SRL + LUT RAM) after the rules below.

Synthesis rules (Vivado 2025.1, V80, 350 MHz, out of context; measured, see
ntt_hw/experiments/overnight_2026-11-14/hybrid/MODEL_ACCURACY.md):
  R1  a 4:1 mux bit is one LUT6; a 2:1 mux bit is a LUT3 and two of them share one physical LUT (PAIR = 0.5).
  R2  a register that only feeds the A input of a butterfly with a plain A delay line (not the unified
      butterfly) joins that delay line's SRL: no flip-flop. This takes the A half of the block input chain
      and of every stage register but the last.
  R3  a chain of three or more plain registers becomes one SRL and one flip-flop per bit, unless the emitter
      forbids it (`shreg_extract = "no"` with crossing registers); a chain of two stays two flip-flops.
  R4  equal registers merge: one round-mux register per distinct (stage, tables over the rounds), one modulus
      constant register per distinct non-constant bit column over the moduli.
  R5  a ROM of 9 to 64 words is one LUT6 per bit, and its read registers become one SRL per bit (they form a chain
      with the fan-out register). A ROM of up to 8 words is a few LUT3 (SMALL_ROM per bit) and keeps registers.
      A loadable table of up to 64 words is LUT RAM (RAM32M16: 14 bits per 8 LUTs; RAM64M8: 7 bits per 8 LUTs).
      An inferred memory wider than one block is packed as one memory (72 bits per RAMB36 at 512 words).
  R6  replicated control (max_fanout) is counted from the fan-out limits of the emitter.
  R7  two shift registers of the same depth share one LUT.
  R8  a component's delay lines of the modulus ports keep only the bit columns that differ over the moduli
      (`contextTrim`); the shared component model counts them at full width because it prices the component alone.
  R10 the head of a modulus port's delay line (flip-flop + shift register) exists once per stage of butterflies and
      once per bank of twist multipliers or generators: the instances receive the same modulus register.
  R9  a shift register inside a component keeps one flip-flop per bit behind it (stopgap in `contextTrim` until the
      shared component model books it; self-cancelling).
  R11 a block RAM is built at the next power of two of its depth (1536 x 32: 2 blocks, not 1.5).
"""
from __future__ import annotations

import re as _re
from operator_modeling.ntt.memory import ramCost

PAIR = 0.5            # R1: physical LUTs per 2:1 mux bit
SMALL_ROM = 0.3       # R5: LUTs per bit of a ROM of up to 8 words (equal and constant columns merge)
SMALL_ROM_FF = 0.5    # R5: flip-flops per bit of such a ROM in front of a fan-out register (0.7 per read register
                      #     when it feeds a generator)
LUTRAM_SRL = 0.5      # R5: SRLs per bit on the read side of a loadable LUT RAM table
FIFO_LUT = 0.5        # LUTs per bit of an input FIFO bank beside its block RAM (measured, 15.5 per 30-bit bank)
HALVE_ABSORB = 0.3    # R2 with stage scaling: share of the A-side stage registers still absorbed (measured 0.25, 0.375)
SRL_PAIR = 0.5        # R7: two shift registers of the same depth share one LUT (SRL16 pairs)
FAN = 32              # R6: loads per copy of a rotate amount or select (max_fanout of the emitter)
SRL_MIN = 3           # R3


def _bits(n: int) -> int:
    return max(1, (max(1, n) - 1).bit_length())


def _muxLut(k: int) -> float:
    '''Physical LUTs per bit of a k:1 mux in front of a register (R1).'''
    if k <= 1:
        return 0.0
    if k == 2:
        return PAIR
    if k <= 4:
        return 1.0
    return float(-(-(k - 1) // 3))


def _chain(bits: int, length: int, srl: bool = True) -> tuple[float, float]:
    '''(ff, srl) of `bits` chains of `length` plain registers (R3).'''
    if length <= 0:
        return 0.0, 0.0
    if not srl or length < SRL_MIN:
        return float(bits * length), 0.0
    return float(bits), float(bits * (-(-(length - 1) // 32)))


def _columns(values: list[int], width: int) -> int:
    '''Distinct non-constant bit columns of a list of constants (R4).'''
    cols = set()
    for b in range(width):
        c = tuple((v >> b) & 1 for v in values)
        if len(set(c)) > 1:
            cols.add(c)
    return len(cols)


def _liveColumns(values: list[int]) -> int:
    """Bit columns that differ over a list of constants (no merging of equal columns)."""
    return sum(1 for b in range(max(values).bit_length()) if len({(v >> b) & 1 for v in values}) > 1)


def _onesColumns(values: list[int]) -> int:
    """Bit columns that are 1 for at least one of the constants.  The register that holds the selected modulus
    constant starts at zero, so a column of ones is not a constant for synthesis; only a column of zeros is removed
    (routed: 4 moduli of 30 bit keep Q 7 and MU 24 columns, 2 moduli of 28 bit keep Q 6 and MU 17)."""
    acc = 0
    for v in values:
        acc |= v
    return bin(acc).count('1')


def _inner(x):
    return x.inner() if hasattr(x, 'inner') else x


def contextTrim(s, x, pipelineStages=1) -> tuple[float, float, float, tuple[float, float]]:
    """R8: (lut, ff, x_c flip-flops, shared (lut, ff)) the hybrid core removes from one component instance.

    The shared component model counts a component alone, with every input bit live.  In the hybrid core the modulus
    ports (Q, MU, QH) are driven by constants selected by the frame's modulus index, so synthesis keeps the
    component's internal delay lines of those ports only for the bit columns that differ over the moduli
    (measured, 4 moduli of 30 bit: Q 7 of 30 columns, MU 24 of 31, QH 6 of 15).  The rows are read from the component
    model's own list (`emitcount.nodeRows`: delay rows named <port>_d<k>, and q_rt_d<k>, the modulus rebuilt
    inside a word-level Montgomery multiplier) and scaled by live columns / width.  A loadable core has every
    column live: nothing is removed.  The third number is the butterfly's x output register (row x_c), which
    R2 removes in every stage but the last (it feeds only the next butterfly's A delay line).
    The fourth is R10: the part of a modulus port's delay line that starts at the port as flip-flop + shift register
    (4 cycles or more) is the same in every instance fed by one modulus register; synthesis keeps one copy
    (measured: loadable core, one butterfly per stage and one twist multiplier carry 62 FF + 30 SRL more than the others)."""
    try:
        from operator_modeling.core import emitcount
        inner = _inner(x)
        rows = emitcount.nodeRows(inner.datapath(), inner.schedule(pipelineStages))
    except Exception:
        return 0.0, 0.0, 0.0, (0.0, 0.0, 0.0, 0.0)
    xc = float(sum(r.ff for r in rows if r.name == 'x_c'))
    live = {}
    if s.runtime:
        vals = [s.qPortValues(q) for q in s.moduliList()]
        live = {p: (_onesColumns([v[p] for v in vals]), max(v[p] for v in vals).bit_length()) for p in vals[0]}
        if 'Q' not in live:
            qs = s.moduliList()
            live['Q'] = (_onesColumns(qs), max(qs).bit_length())
    dff = dsrl = shf = shs = hof = hos = 0.0
    for r in rows:
        if r.kind != 'delay' or '_d' not in r.name:
            continue
        ff, srl = float(r.ff), float(r.srl)
        # R9 (stopgap, reported to the owner of the component model in SHARED_REQUESTS.md 2026-11-14 01:55; each clause
        # tests the component model's own row, so it stops acting when that model books the cells itself):
        if srl and not ff:
            ff = srl                 # a shift register keeps one flip-flop per bit behind it (mp_d4, B_d11, Q_d7: n SRL + n FF)
        elif not srl and ' x 3 cycle(s) from an input' in r.note and r.name.rsplit('_d', 1)[0] not in live:
            ff = srl = ff / 3        # three registers from a port are one SRL + one flip-flop per bit (W_d3: 30 + 30)
        base = r.name.rsplit('_d', 1)[0]
        port = base in live
        base = 'Q' if base == 'q_rt' else base
        keep = 1.0
        if base in live and not s.loadable:
            c, w = live[base]
            keep = min(1.0, c / w)   # R8
        m = _re.match(r'(\d+) bit x (\d+) cycle', r.note) if port and 'from an input' in r.note else None
        if m and int(m.group(2)) >= 2:                                     # R10
            # every instance keeps the last register of the line; the N-1 stages before it exist once per group
            # (the component model's row is the instance that holds the head: N-1 stages + the kept last register)
            wd = int(m.group(1))
            shf += (ff - wd) * keep
            shs += srl * keep
        dff += r.ff - ff * keep
        dsrl += r.srl - srl * keep
    return dsrl * SRL_PAIR, dff, xc, (shs * SRL_PAIR, shf, hos * SRL_PAIR, hof)


def componentCosts(s, pipelineStages=1) -> dict:
    '''{'bu': (lut, ff, dsp), 'twist': ..., 'gen': ...} of one instance: the shared component models (the same
    numbers as in the other NTT types) minus what the hybrid core trims (R8).  'bu_xc': flip-flops of the
    butterfly's x output register (see R2).'''
    out = {}
    bu = s.butterflyUnit()
    lb, db = bu.areaCost()
    tl, tf, xc, sh = contextTrim(s, bu, pipelineStages)
    out['bu'] = (lb - tl, bu.flipFlops(pipelineStages) - tf, db)
    out['bu_xc'] = xc
    out['shared'] = {'bu': sh}
    if s.twistMultiplier is not None:
        a, d = s.twistMultiplier.areaCost()
        tl, tf, _, out['shared']['twist'] = contextTrim(s, s.twistMultiplier, pipelineStages)
        out['twist'] = (a - tl, s.twistMultiplier.flipFlops(pipelineStages) - tf, d)
    g = s.generator() if s.generatorCount() else None
    if g is not None:
        a, d = g.areaCost()
        tl, tf, _, out['shared']['gen'] = contextTrim(s, g, pipelineStages)
        out['gen'] = (a - tl, g.flipFlops(pipelineStages) - tf, d)
    return out


def lutRam(depth: int, width: int) -> int:
    """LUTs of a distributed RAM (R5)."""
    if depth <= 32:
        return -(-width // 14) * 8
    return -(-depth // 64) * -(-width // 7) * 8


def _storedColumns(words: list[int], width: int) -> int:
    """Bit columns a block ROM stores: equal columns of the word are stored once (routed, Shoup w and w' in one
    80-bit word, 1024 deep: 66 to 73 different columns, 2 blocks up to 72 and 2.5 at 73; the dataflow rule R12b)."""
    return len({sum(((v >> b) & 1) << a for a, v in enumerate(words)) for b in range(width)})


def _rom(P, what, depth, width, style, RL, loadable=False, count=1, use='tf', words=None):
    """A table of the twiddle path: block / ultra RAM, LUT ROM or loadable LUT RAM."""
    c = ramCost(depth, width, style)
    cols = width
    if c['bram'] and words is not None and not loadable:
        cols = _storedColumns(words, width)
        c = ramCost(depth, cols, style)
    if c['bram'] or c['uram']:
        # extra read stages of a block ROM: one stage is one register, which cannot be a shift register: a flip-flop
        # per stored column (routed, read latency 3: twist ROM 32 x 40 = 1280 FF, 35 tables 2541 FF); two or more
        # stages are SRLs (measured 0.4-0.5 per bit at read latency 4)
        x = count * width * 0.5 if RL > 3 else 0
        f = count * cols if RL == 3 else 0
        P.append(dict(part=what, where='mem', group='mem', ff=f, lut=x, srl=x, bram=c['bram'] * count,
                      uram=c['uram'] * count))
    elif loadable:
        P.append(dict(part=what + ' (LUT RAM)', where='mem', group='mem', ff=0,
                      lut=count * (lutRam(depth, width) + width * LUTRAM_SRL), srl=count * width * LUTRAM_SRL))
    elif use == 'const':
        # one word per modulus and direction: few distinct columns, the read registers stay flip-flops
        P.append(dict(part=what + ' (LUT ROM)', where='mem', group='mem', ff=count * width * 0.75 * RL,
                      lut=count * width * 0.4, srl=0))
    elif use == 'gen':
        # a base table in front of a generator: its read registers feed a mux and stay flip-flops
        P.append(dict(part=what + ' (LUT ROM)', where='mem', group='mem', ff=count * width * RL,
                      lut=count * width * -(-depth // 16), srl=0))
    elif depth <= 8:
        P.append(dict(part=what + ' (LUT ROM)', where='mem', group='mem', ff=count * width * SMALL_ROM_FF,
                      lut=count * width * SMALL_ROM, srl=0))
    elif depth <= 16:
        P.append(dict(part=what + ' (LUT ROM)', where='mem', group='mem', ff=0, lut=count * width, srl=count * width * 0.5))
    else:
        k = float(-(-depth // 64))
        P.append(dict(part=what + ' (LUT ROM)', where='mem', group='mem', ff=0,
                      lut=count * width * (k + 1), srl=count * width))


def _ram(P, what, count, depth, width, style, RL=2, lutPerBit=0.0):
    c = ramCost(depth, width, style)
    blk = c['bram'] or c['uram']
    if c['bram'] and depth & (depth - 1):
        # R11: a block RAM is built at the next power of two of its depth (measured: 1536 x 32 takes 2 blocks,
        # the 2048-deep shape, not the 1.5 of three 512 x 36 halves)
        c = dict(c, bram=max(c['bram'], ramCost(1 << (depth - 1).bit_length(), width, 'block')['bram']))
    # read latency above 2: the extra stages are fabric registers behind the block's own output register
    ff = c['ff'] + (width * max(0, RL - 2) if blk else 0)
    P.append(dict(part=what, where='mem', group='mem', ff=ff * count, lut=(c['lut'] + width * lutPerBit) * count, srl=0,
                  bram=c['bram'] * count, uram=c['uram'] * count))


def _constRegs(values: list[dict], port: str) -> int:
    """Registers of one modulus-constant port (R4): distinct non-constant bit columns, a column and its
    complement count once."""
    vs = [v[port] for v in values]
    width = max(vs).bit_length()
    cols = set()
    for b in range(width):
        c = tuple((v >> b) & 1 for v in vs)
        if len(set(c)) > 1:
            cols.add(min(c, tuple(1 - x for x in c)))
    return len(cols)


def _tableParts(s, P, pipelineStages=1):
    """Twiddle tables, generators' tables and registers, the fan-out registers."""
    tw = max(1, (s.qMax() - 1).bit_length())
    TWW = tw + s.wpWidth()
    M, D = len(s.moduliList()), len(s.dirs)
    tabs, use = s.roundTables()
    LD = bool(s.loadable)
    RL = s.RL
    LG = s.genLatency(pipelineStages) if s.generatorCount() else 0
    ntf = 0
    gsrl = 0.0
    gff = 0.0
    ngt = 0                                     # generators with their own modulus constants
    seen = set()                                # equal constant tables read at the same address merge
    for ti, t in enumerate(tabs):
        src = s.tableSource(ti)
        if src in ('rom', 'tbase'):
            dep = 0 if s.twiddleSource == 'stream' else s.entryCount(t['r']) * s.tableDirs(ti) * M
            if dep > 1 or (LD and dep):
                words = None
                if src == 'rom' and not LD:
                    words = s.roundTable(ti)
                    if s.wpWidth():
                        words = [v | (p_ << tw) for v, p_ in zip(words, s.roundTableWP(ti))]
                _rom(P, f'twiddle table {dep} deep', dep, TWW if src == 'rom' else tw,
                     s.twiddleStyle if src == 'rom' else 'auto', RL, LD, words=words)
            if dep > 1 or LD or s.twiddleSource == 'stream':
                ntf += 1
            if src == 'tbase':
                gsrl += tw                      # td: the word waits LG + 1 cycles for the derived tables
        elif src == 'tree':
            ntf += 1
            ngt += 1
            key = ('th', tuple(s.treeTable(ti)))
            if (D * M > 1 or LD) and (LD or key not in seen):
                seen.add(key)
                _rom(P, 'tree constant table', D * M, tw, 'auto', RL, LD, use='const')
            gsrl += tw                          # gv -> fan-out register behind the multiplier's output register
        elif src == 'rec':
            ntf += 1
            ngt += 1
            k = s.recK(ti, pipelineStages)
            base, upd = s.recTables(ti, pipelineStages)
            _rom(P, 'rec base table', k * D * M, tw, 'auto', RL, LD, use='gen')
            key = ('tu', tuple(upd))
            if (D * M > 1 or LD) and (LD or key not in seen):
                seen.add(key)
                _rom(P, 'rec update table', D * M, tw, 'auto', RL, LD, use='const')
            gff += tw                           # gv (a mux: base word or product)
            dA = k * (1 << (s.CB - s.sigBits(t['r']))) - LG - 1
            f2, s2 = _chain(tw, dA)             # gd: the delayed operand
            gff += f2
            gsrl += s2
        else:
            ntf += 1
            ngt += 1
            h = s.otfBits(ti)
            sb = s.sigBits(t['r'])
            _rom(P, 'otf low table', (1 << h) * D * M, tw, 'auto', RL, LD, use='gen')
            _rom(P, 'otf high table', (1 << (sb - h)) * D * M, tw, 'auto', RL, LD, use='gen')
            gsrl += tw
    P.append(dict(part=f'table fan-out registers (tf) x{ntf}', where='top', group='tf', ff=ntf * TWW, lut=0, srl=0))
    if gsrl or gff:
        P.append(dict(part='generator operand / result delays', where='top', group='gen regs', ff=gff, lut=gsrl * SRL_PAIR + tw * PAIR * (gff > 0),
                      srl=gsrl))
    return tabs, use, TWW, tw, ngt


def inventory(s, pipelineStages=1) -> list[dict]:
    """Every part of the core with its registers, LUTs, SRLs and memory blocks (the port wrapper: portParts)."""
    P = []
    W, U, MU, g = s.W, s.U, 1 << s.U, s.g
    Wd, OW = s.memBound.bitWidth, s.outputBound.bitWidth
    RT, LEAD, XR, RL = s.rotLatency(), s.lead(pipelineStages), s.XR, s.RL
    R, e, S, T = s.R, s.e, s.S, s.T
    Lbu = s.buLatency(pipelineStages)
    qs = s.moduliList()
    M, D = len(qs), len(s.dirs)
    MB = s.midxBits()
    DP = 1 if D == 2 else 0
    LD = bool(s.loadable)
    uni = bool(s.unified)
    half = bool(s.stageHalve)
    bits = W * Wd
    NB = s.butterflyCount()
    cc = componentCosts(s, pipelineStages)

    # ---- components (the shared component models)
    lb, fb, db = cc['bu']
    P.append(dict(part=f'butterflies x{NB}', where='comp', group='u_bu_', ff=NB * fb, lut=NB * lb, srl=0, dsp=NB * db))
    if not uni and not half and U > 1 and cc.get('bu_xc'):
        # R2: the x output register of a butterfly whose x feeds only the next stage's A delay line joins that SRL
        # (half the butterflies of a stage: the x lane is an A input of the next stage for one lane bit value;
        # measured per instance: 397 against 427 flip-flops on exactly those butterflies)
        P.append(dict(part='butterfly x output registers of stages before the last (R2)', where='comp', group='u_bu_',
                      ff=-((NB // U) // 2) * (U - 1) * cc['bu_xc'], lut=0, srl=0))
    if half:
        # the halver sits between a butterfly's outputs and the stage register; synthesis keeps it with the
        # butterfly: one carry LUT per bit and output holds the shift, the add of (q+1)/2 and the direction select
        # (placed sites named after the stage registers: 60 per butterfly at 30 bit, 101 at 52 bit).  Its flag hv
        # carries max_fanout 32 over W*Wd loads per stage (measured replicas: 52 at W 16 / 30 bit / 3 stages).
        P.append(dict(part='halvers (stage scaling)', where='comp', group='u_bu_',
                      ff=U * -(-(W * Wd) // 32), lut=NB * 2 * Wd, srl=0))
    if 'twist' in cc:
        a, f, d = cc['twist']
        P.append(dict(part=f'twist multipliers x{W}', where='comp', group='u_twist', ff=W * f, lut=W * a, srl=0, dsp=W * d))
    ng = s.generatorCount()
    if ng:
        a, f, d = cc['gen']
        P.append(dict(part=f'twiddle generators x{ng}', where='comp', group='u_gen', ff=ng * f, lut=ng * a, srl=0, dsp=ng * d))
    # R10: one copy of the modulus delay line head per stage of butterflies, per twist bank, per generator bank
    sh = cc.get('shared', {})
    dup = [(NB - U, sh.get('bu')), (W - 1, sh.get('twist')), (ng - 1, sh.get('gen'))]
    shl = sum(k * v[0] for k, v in dup if v and k > 0)
    shf = sum(k * v[1] for k, v in dup if v and k > 0)
    # the instance that holds the head has it as a line of N-1 stages (a 2-stage head is two flip-flops, no SRL)
    hold = [(U, sh.get('bu')), (1, sh.get('twist')), (1 if ng else 0, sh.get('gen'))]
    shl -= sum(k * v[2] for (k, v), (d, _) in zip(hold, dup) if v and len(v) > 2 and d > 0)
    shf -= sum(k * v[3] for (k, v), (d, _) in zip(hold, dup) if v and len(v) > 2 and d > 0)
    if shl or shf:
        P.append(dict(part='modulus delay line heads shared between instances (R10)', where='comp', group='u_bu_',
                      ff=-shf, lut=-shl, srl=0))

    # ---- memories
    _ram(P, 'data banks', W, (S + 1) * T, Wd, s.memStyle, RL)
    _ram(P, 'input FIFO banks', W, s.inDepth(), Wd, s.memStyle, RL, FIFO_LUT)

    # ---- read path
    # the select between FIFO and pool word costs no LUT when both are block RAM outputs (measured: 0)
    blk = ramCost((S + 1) * T, Wd, s.memStyle)
    P.append(dict(part='source mux register (src)', where='top', group='src', ff=bits,
                  lut=0 if (blk['bram'] or blk['uram']) else bits * PAIR, srl=0))
    absorbA = not uni                                   # R2
    for i in range(RT):
        nb = min(2, U - 2 * i)
        lastA = absorbA and i == RT - 1           # the A half of the last level's mux is kept with the butterfly
        m = bits * _muxLut(1 << nb)
        P.append(dict(part=f'read rotator level {i}', where='top', group='rr', ff=bits if i < RT - 1 else 0,
                      lut=m / 2 if lastA else m, srl=0))
        if lastA:
            P.append(dict(part='read rotator last level, A half (in the butterflies)', where='comp', group='u_bu_', ff=0,
                          lut=m / 2, srl=0))
    # the chain in front of the block: last rotator register, s0, the lead registers
    Lc = 2 + LEAD
    nosr = XR > 0
    fB, sB = _chain(bits // 2, Lc, not nosr)
    if absorbA:
        fA, sA = (0.0, 0.0) if not nosr else (float(bits // 2 * (Lc - 1)), 0.0)
    else:
        fA, sA = fB, sB
    P.append(dict(part=f'block input chain ({Lc} registers)', where='top', group='rr+s0+sl', ff=fA + fB,
                  lut=(sA + sB) * SRL_PAIR, srl=sA + sB))

    # ---- stages
    for j in range(U):
        last = j == U - 1
        ff = bits if (last or not absorbA) else bits // 2 + (int(bits // 2 * (1 - HALVE_ABSORB)) if half else 0)
        lut = srl = 0.0
        if j < e:
            f2, s2 = _chain(bits, Lbu)
            ff += f2
            srl += s2
            lut += s2 * SRL_PAIR + bits * PAIR
        P.append(dict(part=f'stage {j} output register', where='top', group='s', ff=ff, lut=lut, srl=srl))

    # ---- write path
    for i in range(RT):
        nb = min(2, U - 2 * i)
        P.append(dict(part=f'write rotator level {i}', where='top', group='wr', ff=bits, lut=bits * _muxLut(1 << nb), srl=0))
    if XR:
        P.append(dict(part='write crossing registers (pwx)', where='top', group='pwx', ff=XR * bits, lut=0, srl=0))
    P.append(dict(part='pool write register (pw_d)', where='top', group='pw_d', ff=bits, lut=0, srl=0))
    P.append(dict(part='FIFO write register (fw_d)', where='top', group='fw_d', ff=bits, lut=0, srl=0))

    # ---- twiddles
    tabs, use, TWW, tw, ngt = _tableParts(s, P, pipelineStages)
    sigs = {}
    for (j, h, a_, la, lb_) in s.pairs():
        sg = (j,) + tuple(use[(j, la, r)] for r in range(R))
        sigs[sg] = len({x for x in sg[1:] if x is not None})
    # a w register with one source is a copy of the fan-out register: it joins the butterfly's twiddle delay
    wff = sum(1 for k in sigs.values() if k > 1) * TWW
    wlut = sum(_muxLut(k) for k in sigs.values() if k > 1) * TWW
    if s.shareInv:
        sw, xs = s.inverseShareCost()
        wlut += tw * xs
        # the output swap of a shared-inverse butterfly is synthesised with the butterfly (measured 48 LUT at 30 bits)
        P.append(dict(part=f'output swaps x{sw}', where='comp', group='u_bu_', ff=0, lut=sw * 2 * Wd * 0.8, srl=0))
    if uni:
        # unified butterfly: it delays W itself, so the w register joins that delay line; the mux stays
        P.append(dict(part='round mux (w), register in the butterflies', where='comp', group='u_bu_', ff=0, lut=wlut, srl=0))
    else:
        P.append(dict(part=f'round-mux registers (w), {len(sigs)} distinct', where='top', group='w', ff=wff, lut=wlut, srl=0))

    # ---- output
    if s.twistMultiplier is not None:
        if s.twistSrc == 'rec':
            _rom(P, 'twist rec base table', s.twistRecD(pipelineStages) * D * M, tw, 'auto', RL, LD, count=W, use='gen')
            if D * M > 1 or LD:
                _rom(P, 'twist rec update table', D * M, tw, 'auto', RL, LD, use='const')
            P.append(dict(part='twist recurrence registers', where='top', group='ttr', ff=W * tw, lut=0, srl=0))
        else:
            _rom(P, 'twist ROM', T * D * M, tw, s.twiddleStyle, RL, LD, count=W)
        P.append(dict(part='twist operand register (ttb)', where='top', group='ttb', ff=W * tw, lut=0, srl=0))
    P.append(dict(part='output register (y_out)', where='top', group='y_out', ff=W * OW, lut=0, srl=0))

    # ---- modulus constants (R4)
    if s.runtime:
        vals = [s.qPortValues(q) for q in qs]
        buPorts = [p for p in s.butterflyUnit().portNames() if p not in ('W', 'WP', 'DIR')]
        twPorts = list(s.twistMultiplier.qPorts()) if s.twistMultiplier is not None else []
        gen = s.generator() if ng else None
        gPorts = list(gen.qPorts()) if gen is not None and hasattr(gen, 'qPorts') else []
        n = 0
        nl = 0
        for p in vals[0]:
            sets = (U if p in buPorts else 0) + (U if p == 'QHALF' else 0) + (1 if p in twPorts else 0)
            gsets = ngt if p in gPorts else 0
            if LD:
                wdt = max(v[p] for v in vals).bit_length()
                n += wdt * (sets + gsets)
            else:
                c = _constRegs(vals, p)
                # a generator keeps a register per distinct column (no complement sharing: measured 16-18 per generator)
                n += c * sets + _columns([v[p] for v in vals], max(v[p] for v in vals).bit_length()) * gsets
                nl += c * (sets + (1 if gsets else 0))      # the generators share one tag tap: one LUT set
        P.append(dict(part='modulus constant registers', where='top', group='const', ff=n,
                      lut=0 if LD else nl * _muxLut(min(4, len(qs))), srl=0))

    # ---- control (R6): rotate amounts and selects replicated per FAN loads, addresses, counters, tag pipeline
    TGW = 2 + _bits(R) + s.CB + _bits(S + 1) + MB + DP
    depth = s.outOffset(pipelineStages) - (s.fanShift(pipelineStages) if s.fanout else 0)   # the trees' own registers: 'fan'
    rep = -(-bits // FAN)
    ctl = 2 * U * rep + rep                               # rra, wra, src select
    if s.twistMultiplier is not None and s.twistSrc != 'rec':
        ctl += _bits(T * D * M) * -(-W // 4)              # twist table address copies
    ctl += depth                                          # valid chain
    ctl += 4 * TGW                                        # tag registers at the taps (the rest are SRLs)
    ctl += 4 * _bits(s.inDepth()) + 4 * _bits((S + 1) * T) + _bits(s.slotLength() + 1) + 12
    if half:
        ctl += U * (W // 2 + 8) + U * TGW                 # hv per stage (max_fanout), the tag taps in front
    if LD:
        ctl += 4 * (tw + 2) + len(tabs) + 2 * W + 40 + 6 * TGW   # the load bus registers and enables
    if s.shareInv:
        ctl += 4 * TGW + 2 * len(s.inverseShare())
    if any(s.tableSource(i) in ('rec', 'otf') for i in range(len(tabs))) or (s.twistMultiplier is not None and s.twistSrc == 'rec'):
        ctl += 4 * TGW + 2 * ng
    P.append(dict(part='control and tag pipeline', where='top', group='ctl', ff=ctl, lut=ctl * 0.45 + TGW * 4, srl=TGW * 4))
    if s.fanout:
        P.append(dict(part='fan-out trees', where='top', group='fan', ff=s.fanoutRegisters(pipelineStages), lut=0, srl=0))
    return P


def portParts(s, pipelineStages=1) -> list[dict]:
    """The port wrapper (HybridPorts) or the plain port adapters (ioLanes != W without port options)."""
    P = []
    W, io = s.W, s.io
    Wd, OW = s.memBound.bitWidth, s.outputBound.bitWidth
    TGW = s.midxBits() + (1 if len(s.dirs) == 2 else 0)
    if not s.portsOn():
        if io < W:
            rho = W // io
            P.append(dict(part='input gathering register', where='wrap', group='k_x', ff=W * Wd, lut=0, srl=0))
            P.append(dict(part='output register and lane mux', where='wrap', group='y_out', ff=io * OW,
                          lut=io * OW * _muxLut(rho), srl=0))
            c = ramCost(s.OUT_BUFFER_POLYS * s.T, W * OW, s.memStyle)     # one memory W x OW wide (R5)
            P.append(dict(part='output buffer', where='mem', group='mem', ff=0, lut=c['lut'], srl=0, bram=c['bram'],
                          uram=c['uram']))
            P.append(dict(part='adapter counters', where='wrap', group='ctl', ff=4 * _bits(s.OUT_BUFFER_POLYS * s.T) - 10 + 2 * _bits(rho),
                          lut=30, srl=0))
        elif io > W:
            P.append(dict(part='input holding register and lane mux', where='wrap', group='h', ff=io * Wd,
                          lut=W * Wd * _muxLut(io // W), srl=0))
            P.append(dict(part='output gathering register', where='wrap', group='y_out', ff=io * OW, lut=0, srl=0))
            P.append(dict(part='adapter counters', where='wrap', group='ctl', ff=4, lut=2, srl=0))
        return P
    geo = s.portsGeometry(pipelineStages)
    lut, ff = 0.0, 0.0
    if io != W:
        P.append(dict(part='input gathering / holding register', where='wrap', group='k_x', ff=max(io, W) * Wd,
                      lut=(W * Wd * _muxLut(geo['rho']) if io > W else 0), srl=0))
    if not s.portsDirect():
        P.append(dict(part='push register (pd)', where='wrap', group='pd', ff=io * OW,
                      lut=(io * OW * _muxLut(geo['rho']) if geo['narrow'] else 0), srl=0))
        if geo['wide']:
            P.append(dict(part='wide output gathering', where='wrap', group='pd', ff=io * OW, lut=0, srl=0))
        if geo['natural']:
            for nm in ('write', 'read'):
                for i in range(geo['RT']):
                    nb = min(2, s.U - 2 * i)
                    P.append(dict(part=f'natural-order {nm} rotator level {i}', where='wrap', group='nat', ff=W * OW,
                                  lut=W * OW * _muxLut(1 << nb), srl=0))
            P.append(dict(part='natural-order counters', where='wrap', group='ctl', ff=50, lut=40, srl=0))
        _ram(P, 'output buffer', W, s.outDepth(pipelineStages) * s.T, OW, s.memStyle, s.RL)   # emitted with .R(RL)
        P.append(dict(part='landing FIFO (LUT RAM)', where='wrap', group='lmem', ff=0,
                      lut=lutRam(geo['K'], io * OW + TGW), srl=0))
        P.append(dict(part='admission, credit and reader counters', where='wrap', group='ctl',
                      ff=40 + 4 * _bits(s.outDepth(pipelineStages) * s.T), lut=50, srl=3))
    if s.twiddleBuffer == 'record':
        P.append(dict(part='record loader', where='wrap', group='rec', ff=110, lut=75, srl=16))
    return P


def allParts(s, pipelineStages=1) -> list[dict]:
    P = inventory(s, pipelineStages)
    if s.portsOn() or s.io != s.W:
        P += portParts(s, pipelineStages)
    return P


def totals(parts: list[dict]) -> dict:
    t = {'lut': 0.0, 'ff': 0.0, 'dsp': 0, 'bram': 0, 'uram': 0}
    for p in parts:
        for k in t:
            t[k] += p.get(k, 0)
    t['lut'], t['ff'] = int(round(t['lut'])), int(round(t['ff']))
    return t


def breakdown(parts: list[dict]) -> dict:
    """{part: (LUT, FF, DSP, BRAM36, URAM)} of the non-zero lines, and the partition sums under 'sums'."""
    out, sums = {}, {}
    for p in parts:
        v = (round(p.get('lut', 0)), round(p.get('ff', 0)), p.get('dsp', 0), p.get('bram', 0), p.get('uram', 0))
        if any(v):
            o = out.get(p['part'], (0, 0, 0, 0, 0))
            out[p['part']] = tuple(x + y for x, y in zip(o, v))
        s_ = sums.setdefault(p['where'], [0, 0])
        s_[0] += p.get('lut', 0)
        s_[1] += p.get('ff', 0)
    out['sums'] = {k: (round(v[0]), round(v[1])) for k, v in sums.items()}
    return out
