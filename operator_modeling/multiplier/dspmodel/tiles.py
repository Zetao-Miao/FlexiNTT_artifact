'''The five DSP tile netlists, each mirroring its RTL generator — registers included.

    single   rtl/dsp_multiplier/SingleDSP.sv
    chain    rtl_gen/dsp_multiplier/dsp/dsp_rtl_gen.py
    k2       rtl_gen/dsp_multiplier/dsp/k2_rtl_gen.py
    k3       rtl_gen/dsp_multiplier/dsp/k3_rtl_gen.py
    t25      rtl_gen/dsp_multiplier/dsp/t25_rtl_gen.py

Every width that defines a netlist is imported from the generator that
emits it, and **every register count is read from the generator's own plan**
— `chain_plan`, `k2_plan`, `k3_plan`, `t25_plan` — computed from the
configuration `exact_dsp_config` returns for the latency the backend chose.
That is the same call the emitter makes before writing the `.sv`, so the
model and the RTL take their register placement from one source. Untimed,
the same descriptions are built with every count at zero; the structure
does not change, only the registers vanish.

Three rules, applied in every netlist:

**True values on every wire, and patterns where the RTL has patterns.** A
DSP's `P` is its integer value. Where the RTL concatenates two's-complement
patterns and adds them modulo a field width — K2's 71-bit
`{P_hi[48:0], P_lo[43:22]} + sext(P_mid)` — the model does the same: it
takes the pattern bits, adds them through the same segmented adder with the
same carries, and reads the result back through the port declaration
(`signalops.reinterpret`). Where the RTL truncates a register, the model
asserts the value fits, because that is the condition under which the
truncation preserves it.

**Every register is asserted, and every merge is depth-checked.** Each
`DSP58Block` asserts its own A, B, D, pre-adder, product and 58-bit
accumulator; each fabric adder and output slice asserts the width the
generator declared for it. The netlist engine refuses any merge whose
operands sit at different pipeline depths, so a plan the model read wrongly
does not build.

**Correlated sums are tightened by their identity.** A cross-term DSP's ALU
computes `C + (D-A)*B + PCIN`; the generator's comment says what that
equals algebraically. The identity is computed at build time, the values are
asserted equal, and the two intervals are intersected (`Net.tighten`).

`runTile` is the walker's single entry point. It applies the IR->tile
wrapper rule (`_emit_mult_wrapper`): pad each operand to the tile's physical
width — sign-extend signed, zero-pad unsigned — swap operands when the
placement is transposed, run the netlist, and return the tile's `P` plus a
dict of every internal wire. Each netlist ends by asserting `P == X * Y`
elementwise and adopting that product's interval.
'''
from __future__ import annotations

from ...core.Signal import Signal
from . import signalops as so
from .net import Net, Wire
from .primitive import Dsp58Config, dsp58

from rtl_gen.dsp_multiplier.dsp import dsp_rtl_gen as _chain              # noqa: E402
from rtl_gen.dsp_multiplier.dsp import k2_rtl_gen as _k2                  # noqa: E402
from rtl_gen.dsp_multiplier.dsp import k3_rtl_gen as _k3                  # noqa: E402
from rtl_gen.dsp_multiplier.dsp import t25_rtl_gen as _t25                # noqa: E402

Wires = dict[str, Wire]


# ---------------------------------------------------------------------------
# plans: where the registers are, from the backend's chosen latency
# ---------------------------------------------------------------------------

class Plan:
    '''Register counts for one tile at one latency — or all zero, untimed.

    `p['key']` / `p['key', k]` read the generator's plan; untimed, every
    read is 0 and `segs` is one full-width segment. `cfg` is the raw
    configuration for the few string-valued knobs (`PREADD`).
    '''

    def __init__(self, family: str, blocks: int, latency: int | None):
        self.family, self.blocks, self.latency = family, blocks, latency
        self.timed = latency is not None
        self.raw: dict = {}
        self.cfg: dict = {}
        if not self.timed:
            return
        from dsp_multiplier.backend.delay_model import exact_dsp_config
        self.cfg = exact_dsp_config(family, blocks, latency)['config']
        if family == 'single':
            self.raw = _singlePlan(self.cfg, latency)
        elif family == 'chain':
            self.raw = _chain.chain_plan(self.cfg, blocks)
            _chain.verify_chain_plan(self.raw)
        elif family == 'k2':
            self.raw = _k2.k2_plan(self.cfg)
            _k2.verify_k2_plan(self.raw)
        elif family == 'k3':
            self.raw = _k3.k3_plan(self.cfg)
            _k3.verify_k3_plan(self.raw)
        elif family == 't25':
            self.raw = _t25.t25_plan(self.cfg)
            _t25.verify_t25_plan(self.raw)
        else:
            raise ValueError(f'unknown DSP tile family {family!r}')
        if self.raw['latency'] != latency:
            raise ValueError(
                f'{family}: the generator plan says latency {self.raw["latency"]}, '
                f'the backend chose {latency}')

    def __getitem__(self, key) -> int:
        '''A plan entry (`hi_dly`, `ext_dly`) or, failing that, a config
        entry (`mid_A`, `lo_M`) — the generators read both from the same
        two dicts.'''
        if not self.timed:
            return 0
        if isinstance(key, tuple):
            k, i = key
            return int(self.raw[k][i])
        if key in self.raw:
            return int(self.raw[key])
        return int(self.cfg[key])

    def segs(self, totalWidth: int) -> list[dict]:
        if not self.timed:
            return [{'i': 0, 'lsb': 0, 'w': totalWidth, 'in_dly': 0, 'out_dly': 0}]
        return self.raw['seg']

    def flag(self, key: str) -> bool:
        '''A string-valued config knob, e.g. PREADD.'''
        return self.timed and str(self.cfg.get(key, 'FALSE')) == 'TRUE'


def _singlePlan(cfg: dict, latency: int) -> dict:
    '''`SingleDSP.sv`'s LATENCY -> register table, cross-checked against the
    configuration the backend picked for the same latency.'''
    outReg = int(bool(cfg['P_PIPE']))
    usePreadd = latency == 4
    aP = 1 if latency >= 2 else 0
    adP = 1 if latency == 4 else 0
    mP = 1 if latency >= 3 else (0 if outReg else 1)
    pP = 1 if latency >= 3 else (1 if outReg else 0)
    want = {'A_PIPE': aP, 'PREADD_PIPE': adP, 'MULT_PIPE': mP, 'P_PIPE': pP}
    got = {k: int(cfg[k]) for k in want}
    if want != got:
        raise ValueError(f'SingleDSP latency {latency}: .sv table {want} vs backend config {got}')
    return {'latency': latency, 'preadd': usePreadd, 'A_PIPE': aP, 'PREADD_PIPE': adP,
            'B_PIPE': aP + adP, 'D_PIPE': aP if usePreadd else 0, 'MULT_PIPE': mP, 'P_PIPE': pP}


# ---------------------------------------------------------------------------
# entry point
# ---------------------------------------------------------------------------

def _pad(w: Wire, physicalWidth: int, what: str) -> Wire:
    '''`_to_signed_expr`: the value is unchanged, the register is wider.'''
    if w.bound.isSigned:
        so.requireFits(w.signal, physicalWidth, True, what)
    else:
        so.requireFits(w.signal, physicalWidth - 1, False, f'{what} (unsigned, needs a zero pad bit)')
    return w


def runTile(net: Net, family: str, blocks: int, a: Wire, b: Wire, *,
            physicalA: int, physicalB: int, orientation: str,
            name: str, latency: int | None = None) -> tuple[Wire, Wires]:
    '''Run one tile in `net`. `a`, `b` are the IR operands in board order.
    `latency=None` builds it untimed; otherwise registers are placed per the
    backend's configuration for that latency.'''
    if orientation == 'transposed':
        x, y = _pad(b, physicalA, f'{name}.X(<-B)'), _pad(a, physicalB, f'{name}.Y(<-A)')
    else:
        x, y = _pad(a, physicalA, f'{name}.X'), _pad(b, physicalB, f'{name}.Y')
    plan = Plan(family, blocks, latency)
    fn = {'single': singleDsp, 'chain': dspChain, 'k2': karatsuba2,
          'k3': karatsuba3, 't25': toomCook25}.get(family)
    if fn is None:
        raise ValueError(f'{name}: unknown DSP tile family {family!r}')
    return fn(net, x, y, plan, name=name)


def _finish(net: Net, p: Wire, x: Wire, y: Wire, width: int, name: str,
            wires: Wires) -> tuple[Wire, Wires]:
    '''Every netlist ends here: P must be X*Y, and must fit the tile's port.'''
    net.tighten(p, so.mul(x.signal, y.signal), f'{name}.P == X*Y')
    so.requireFits(p.signal, width, True, f'{name}.P port')
    wires['P'] = p
    return p, wires


def _slice(net: Net, w: Wire, lo: int, hi: int, signed: bool, name: str) -> Wire:
    return net.op(so.sliceBits, w, lo, hi, signed, name=name)


def _plain(plan: Plan, aKey: str, mKey: str, pKey: str) -> Dsp58Config:
    '''`_plain_dsp` / K2's lo and hi: A*B with B tracking A.'''
    a = plan[aKey]
    return Dsp58Config(aPipe=a, bPipe=a, multPipe=plan[mKey], pPipe=plan[pKey])


def _cross(plan: Plan, *, cPipeKey: str | None, preaddSub: bool = True,
           negC: bool = False, negPcin: bool = False) -> Dsp58Config:
    '''`_cross_dsp` / `u_dsp_mid` / `_eval_dsp`: pre-adder, C and PCIN.

    MREG is always on in the generators ("mid MREG is always on"); untimed
    it is zero like everything else. DREG tracks AREG ("D enters the
    pre-adder with A").
    '''
    return Dsp58Config(preadd=True, preaddSub=preaddSub, useC=True, usePcin='PCIN',
                       negC=negC, negPcin=negPcin,
                       preaddPipe=plan['mid_AD'], aPipe=plan['mid_A'], bPipe=plan['mid_B'],
                       cPipe=plan[cPipeKey] if cPipeKey else 0, dPipe=plan['mid_D'],
                       multPipe=1 if plan.timed else 0, pPipe=plan['mid_P'])


# ---------------------------------------------------------------------------
# the segmented adder every macro tile recombines with
# ---------------------------------------------------------------------------

def segmentedAdd(net: Net, operands: list[Wire], totalWidth: int, plan: Plan,
                 carryBits: int, name: str) -> Wire:
    '''`_seg_widths` cuts a wide add into `split` segments; segment `i`'s
    operand slices wait `in_dly = i` cycles, its sum is registered once, and
    the result waits `out_dly = split-1-i` so every segment lands together.
    The carry between segments is the top `carryBits` of the previous
    segment's *registered* result — one bit for two operands, two for four.

    Operands are patterns (non-negative, `totalWidth` bits); the result is
    the pattern of their sum modulo `2^totalWidth`.
    '''
    segs = plan.segs(totalWidth)
    prevQ, prevW = None, 0
    field = None
    for s in segs:
        i, lsb, w, dIn, dOut = s['i'], s['lsb'], s['w'], s['in_dly'], s['out_dly']
        ops = [net.reg(_slice(net, o, lsb, lsb + w - 1, False, f'{name}.s{i}_o{n}_raw'),
                       dIn, name=f'{name}.s{i}_o{n}') for n, o in enumerate(operands)]
        if i == 0:
            carry = net.const(0, like=operands[0], name=f'{name}.s0_carry')
        else:
            carry = _slice(net, prevQ, prevW, prevW + carryBits - 1, False, f'{name}.s{i}_carry')
        res = ops[0]
        for o in ops[1:]:
            res = net.op(so.add, res, o)
        res = net.op(so.add, res, carry, name=f'{name}.s{i}_res')
        so.requireFits(res.signal, w + carryBits, False, f'{name}.s{i}_res')
        q = net.reg(res, 1 if plan.timed else 0, name=f'{name}.s{i}_q')
        summ = net.reg(_slice(net, q, 0, w - 1, False, f'{name}.s{i}_sum_raw'),
                       dOut, name=f'{name}.s{i}_sum')
        piece = net.op(so.lshift, summ, lsb)
        field = piece if field is None else net.op(so.add, field, piece)
        prevQ, prevW = q, w
    return field


# ---------------------------------------------------------------------------
# SingleDSP: P = X * Y, one block, 27 x 24 -> 51
# ---------------------------------------------------------------------------

def singleDsp(net: Net, x: Wire, y: Wire, plan: Plan, *, name: str) -> tuple[Wire, Wires]:
    cfg = Dsp58Config(preadd=bool(plan['preadd']),
                      aPipe=plan['A_PIPE'], preaddPipe=plan['PREADD_PIPE'],
                      bPipe=plan['B_PIPE'], dPipe=plan['D_PIPE'],
                      multPipe=plan['MULT_PIPE'], pPipe=plan['P_PIPE'])
    r = dsp58(net, cfg, x, y, name=f'{name}.u_dsp')
    so.requireFits(r.p.signal, _chain.TOP_WIDTH, True, f'{name}.dsp_p[50:0]')
    p = _slice(net, r.p, 0, _chain.TOP_WIDTH - 1, True, f'{name}.P_raw')
    return _finish(net, p, x, y, _chain.TOP_WIDTH, name, {'u_dsp.M': r.m, 'u_dsp.P': r.p})


# ---------------------------------------------------------------------------
# DSPChain: L blocks cascaded head-to-tail via PCIN >>> 23
# ---------------------------------------------------------------------------

def dspChain(net: Net, x: Wire, y: Wire, plan: Plan, *, name: str) -> tuple[Wire, Wires]:
    '''`gen_dsp_chain`: X (27, signed) times Y (23L+1, signed).

    Y is cut at the 23-bit pitch: slices 0..L-2 are 23-bit unsigned, the top
    slice is 24-bit signed. DSP k computes `X * b_k + (PCOUT_{k-1} >>> 23)`.
    Fabric skew: DSP k's X and B slice wait `ext_dly[k]` cycles (the part of
    its group's skew its own AREG/BREG could not absorb); its low 23 output
    bits wait `out_dly[k]` so every slice lands with the tail.
    '''
    L, pitch, bport = plan.blocks, _chain.PITCH, _chain.B_PORT
    wires: Wires = {}
    pcout = None
    lows = []
    preadd = plan.flag('PREADD')
    for k in range(L):
        if k == L - 1:
            bRaw = _slice(net, y, pitch * k, pitch * k + bport - 1, True, f'{name}.b_raw{k:02d}')
        else:
            bRaw = _slice(net, y, pitch * k, pitch * k + pitch - 1, False, f'{name}.b_raw{k:02d}')
        ext = plan['ext_dly', k]
        xk = net.reg(x, ext, name=f'{name}.a_ext_d{ext}_{k:02d}')
        bk = net.reg(bRaw, ext, name=f'{name}.b{k:02d}_d{ext}')
        cfg = Dsp58Config(preadd=preadd, usePcin='ZERO' if k == 0 else 'PCIN_SHIFT23',
                          aPipe=plan['a_pipe', k], preaddPipe=plan['ad'], bPipe=plan['b_pipe', k],
                          dPipe=plan['d'], multPipe=plan['m'], pPipe=plan['preg', k])
        r = dsp58(net, cfg, xk, bk, pcin=pcout, name=f'{name}.u_dsp{k:02d}')
        wires[f'b_raw{k:02d}'] = bRaw
        wires[f'u_dsp{k:02d}.P'] = r.p
        pcout = r.pcout
        if k < L - 1:
            low = _slice(net, r.p, 0, pitch - 1, False, f'{name}.low{k:02d}_raw')
            lows.append(net.reg(low, plan['out_dly', k], name=f'{name}.low{k:02d}'))
        else:
            if plan['out_dly', k] != 0:
                raise ValueError(f'{name}: tail DSP must land last (out_dly != 0)')
            so.requireFits(r.p.signal, _chain.TOP_WIDTH, True, f'{name}.u_dsp{k:02d}.P[50:0]')
            top = _slice(net, r.p, 0, _chain.TOP_WIDTH - 1, False, f'{name}.top_raw')
    pattern = net.op(so.lshift, top, pitch * (L - 1))
    for k, low in enumerate(lows):
        pattern = net.op(so.add, pattern, net.op(so.lshift, low, pitch * k))
    width = pitch * L + 1 + _chain.A_WIDTH
    p = net.op(so.reinterpret, pattern, width, True, name=f'{name}.P_raw')
    return _finish(net, p, x, y, width, name, wires)


# ---------------------------------------------------------------------------
# Karatsuba2x2: 48 x 45 -> 93, three blocks
# ---------------------------------------------------------------------------

def karatsuba2(net: Net, x: Wire, y: Wire, plan: Plan, *, name: str) -> tuple[Wire, Wires]:
    '''`gen_karatsuba2`.

        X = X_hi*2^22 + X_lo      X_hi signed 26, X_lo unsigned 22
        Y = Y_hi*2^22 + Y_lo      Y_hi signed 23, Y_lo unsigned 22
        Y0Y1  = Y_lo - Y_hi                          (fabric, 24; y0y1_ff)
        P_lo  = X_lo * Y_lo                          (u_dsp_lo)
        P_hi  = X_hi * Y_hi                          (u_dsp_hi)
        P_mid = P_hi + (X_hi - X_lo) * Y0Y1 + P_lo   (u_dsp_mid: C, PCIN)
              = X_lo*Y_hi + X_hi*Y_lo
        P[92:22] = {P_hi[48:0], P_lo[43:22]} + sext(P_mid)    segmented, mod 2^71
        P[21:0]  = P_lo[21:0]
    '''
    K = _k2
    X_lo = _slice(net, x, 0, K.X_LO_W - 1, False, f'{name}.X_lo')
    X_hi = _slice(net, x, K.X_LO_W, K.X_W - 1, True, f'{name}.X_hi')
    Y_lo = _slice(net, y, 0, K.Y_LO_W - 1, False, f'{name}.Y_lo')
    Y_hi = _slice(net, y, K.Y_LO_W, K.Y_W - 1, True, f'{name}.Y_hi')

    Y0Y1 = net.op(so.sub, Y_lo, Y_hi, name=f'{name}.Y0Y1')
    so.requireFits(Y0Y1.signal, K.Y0Y1_W, True, f'{name}.Y0Y1')
    bMid = net.reg(Y0Y1, int(plan.cfg['y0y1_ff']) if plan.timed else 0, name=f'{name}.Y0Y1_q')

    lo = dsp58(net, _plain(plan, 'lo_A', 'lo_M', 'lo_P') if plan.timed else Dsp58Config(),
               X_lo, Y_lo, name=f'{name}.u_dsp_lo')
    hi = dsp58(net, _plain(plan, 'hi_A', 'hi_M', 'hi_P') if plan.timed else Dsp58Config(),
               X_hi, Y_hi, name=f'{name}.u_dsp_hi')
    mid = dsp58(net, _cross(plan, cPipeKey='mid_C'), X_lo, bMid, c=hi.p, d=X_hi, pcin=lo.pcout,
                name=f'{name}.u_dsp_mid')
    net.tighten(mid.p, so.add(so.mul(X_lo.signal, Y_hi.signal), so.mul(X_hi.signal, Y_lo.signal)),
                f'{name}.u_dsp_mid.P == X_lo*Y_hi + X_hi*Y_lo')

    so.requireFits(lo.p.signal, K.P_LO_W, False, f'{name}.P_lo[43:0]')
    so.requireFits(hi.p.signal, K.P_HI_W, True, f'{name}.P_hi[48:0]')
    hiAl = net.reg(hi.p, plan['hi_dly'], name=f'{name}.P_hi_al')
    loAl = net.reg(lo.p, plan['lo_dly'], name=f'{name}.P_lo_al')

    addOp1 = net.op(so.add,
                    net.op(so.lshift, _slice(net, hiAl, 0, K.P_HI_W - 1, False, f'{name}.P_hi_pat'),
                           K.P_LO_W - K.LOW_W),
                    _slice(net, loAl, K.LOW_W, K.P_LO_W - 1, False, f'{name}.P_lo_hi_pat'),
                    name=f'{name}.add_op1')
    addOp2 = _slice(net, mid.p, 0, K.ADD_W - 1, False, f'{name}.add_op2')
    field = segmentedAdd(net, [addOp1, addOp2], K.ADD_W, plan, 1, f'{name}.add')

    low = net.reg(_slice(net, lo.p, 0, K.LOW_W - 1, False, f'{name}.P_low_raw'),
                  plan['low_dly'], name=f'{name}.P_low_al')
    pattern = net.op(so.add, net.op(so.lshift, field, K.LOW_W), low, name=f'{name}.P_pat')
    p = net.op(so.reinterpret, pattern, K.P_W, True, name=f'{name}.P_raw')

    wires = {'X_hi': X_hi, 'X_lo': X_lo, 'Y_hi': Y_hi, 'Y_lo': Y_lo, 'Y0Y1': Y0Y1,
             'u_dsp_lo.P': lo.p, 'u_dsp_hi.P': hi.p,
             'u_dsp_mid.AD': mid.ad, 'u_dsp_mid.P': mid.p, 'P_92_22': field}
    return _finish(net, p, x, y, K.P_W, name, wires)


# ---------------------------------------------------------------------------
# Karatsuba3x3: 70 x 67 -> 137, six blocks
# ---------------------------------------------------------------------------

def karatsuba3(net: Net, x: Wire, y: Wire, plan: Plan, *, name: str) -> tuple[Wire, Wires]:
    '''`gen_karatsuba3`.

        X = X_hi*2^44 + X_mid*2^22 + X_lo     (26 signed, 22, 22 unsigned)
        Y = Y_hi*2^44 + Y_mid*2^22 + Y_lo     (23 signed, 22, 22 unsigned)
        diagonals  P00 = X_lo*Y_lo   P11 = X_mid*Y_mid   P22 = X_hi*Y_hi
        cross      P01 = P11 + (X_mid-X_lo)(Y_lo-Y_mid) + P00 = X_lo*Y_mid + X_mid*Y_lo
                   P12 = P22 + (X_hi-X_mid)(Y_mid-Y_hi) + P11 = X_mid*Y_hi + X_hi*Y_mid
                   P02 = P11 + (X_hi-X_lo)(Y_lo-Y_hi)  + P22 = X_lo*Y_hi + X_hi*Y_lo + P11 - P00
        fabric     P02_add_P00 = P02[49:0] + P00[43:0]                       (50)
        tree       P[136:22] = P01 + {P02_add_P00, P00[43:22]} + P12<<44 + P22<<66   mod 2^115
        P[21:0]    = P00[21:0]
    '''
    K = _k3
    k = K.X_LO_W
    X_lo = _slice(net, x, 0, k - 1, False, f'{name}.X_lo')
    X_mid = _slice(net, x, k, 2 * k - 1, False, f'{name}.X_mid')
    X_hi = _slice(net, x, 2 * k, K.X_W - 1, True, f'{name}.X_hi')
    Y_lo = _slice(net, y, 0, k - 1, False, f'{name}.Y_lo')
    Y_mid = _slice(net, y, k, 2 * k - 1, False, f'{name}.Y_mid')
    Y_hi = _slice(net, y, 2 * k, K.Y_W - 1, True, f'{name}.Y_hi')

    Y0Y1 = net.op(so.sub, Y_lo, Y_mid, name=f'{name}.Y0Y1')
    Y0Y2 = net.op(so.sub, Y_lo, Y_hi, name=f'{name}.Y0Y2')
    Y1Y2 = net.op(so.sub, Y_mid, Y_hi, name=f'{name}.Y1Y2')
    so.requireFits(Y0Y1.signal, 23, True, f'{name}.Y0Y1')
    so.requireFits(Y0Y2.signal, 24, True, f'{name}.Y0Y2')
    so.requireFits(Y1Y2.signal, 24, True, f'{name}.Y1Y2')
    yff = int(plan.cfg['y0y1_ff']) if plan.timed else 0
    y01 = net.reg(Y0Y1, yff, name=f'{name}.Y0Y1_q')
    y02 = net.reg(Y0Y2, yff, name=f'{name}.Y0Y2_q')
    y12 = net.reg(Y1Y2, yff, name=f'{name}.Y1Y2_q')

    diag = _plain(plan, 'diag_A', 'diag_M', 'diag_P') if plan.timed else Dsp58Config()
    d00 = dsp58(net, diag, X_lo, Y_lo, name=f'{name}.u_dsp_00')
    d11 = dsp58(net, diag, X_mid, Y_mid, name=f'{name}.u_dsp_11')
    d22 = dsp58(net, diag, X_hi, Y_hi, name=f'{name}.u_dsp_22')

    cross = _cross(plan, cPipeKey=None)          # CREG blocked by the loop: C_PIPE = 0
    c01 = dsp58(net, cross, X_lo, y01, c=d11.p, d=X_mid, pcin=d00.pcout, name=f'{name}.u_dsp_01')
    c12 = dsp58(net, cross, X_mid, y12, c=d22.p, d=X_hi, pcin=d11.pcout, name=f'{name}.u_dsp_12')
    c02 = dsp58(net, cross, X_lo, y02, c=d11.p, d=X_hi, pcin=d22.pcout, name=f'{name}.u_dsp_02')

    sX, sY = (X_lo.signal, X_mid.signal, X_hi.signal), (Y_lo.signal, Y_mid.signal, Y_hi.signal)
    net.tighten(c01.p, so.add(so.mul(sX[0], sY[1]), so.mul(sX[1], sY[0])),
                f'{name}.u_dsp_01.P == X_lo*Y_mid + X_mid*Y_lo')
    net.tighten(c12.p, so.add(so.mul(sX[1], sY[2]), so.mul(sX[2], sY[1])),
                f'{name}.u_dsp_12.P == X_mid*Y_hi + X_hi*Y_mid')
    net.tighten(c02.p, so.sub(so.add(so.add(so.mul(sX[0], sY[2]), so.mul(sX[2], sY[0])),
                                     d11.p.signal), d00.p.signal),
                f'{name}.u_dsp_02.P == X_lo*Y_hi + X_hi*Y_lo + P11 - P00')

    # P02 + P00 (50-bit fabric adder), then the four tree operands
    so.requireFits(d00.p.signal, K.P00_W, False, f'{name}.P00[43:0]')
    so.requireFits(c02.p.signal, K.P02ADD_W, True, f'{name}.P02[49:0]')
    p00a = net.reg(d00.p, plan['p00_to_cpa50'], name=f'{name}.P00_a')
    p02add = net.op(so.add, _slice(net, c02.p, 0, K.P02ADD_W - 1, True, f'{name}.P02_pat'),
                    _slice(net, p00a, 0, K.P00_W - 1, False, f'{name}.P00_a_pat'),
                    name=f'{name}.P02_add_P00')
    so.requireFits(p02add.signal, K.P02ADD_W, True, f'{name}.P02_add_P00')
    p02q = net.reg(p02add, int(plan.cfg['p02_d1']) if plan.timed else 0, name=f'{name}.P02_add_P00_q')

    extra00 = plan['p00_to_tree'] - plan['p00_to_cpa50']
    p00t = net.reg(p00a, extra00, name=f'{name}.P00_t')
    p22t = net.reg(d22.p, plan['p22_to_tree'], name=f'{name}.P22_t')
    p01t = net.reg(c01.p, plan['p01_to_tree'], name=f'{name}.P01_t')
    p12t = net.reg(c12.p, plan['p12_to_tree'], name=f'{name}.P12_t')
    so.requireFits(c01.p.signal, K.P01_W, False, f'{name}.P01[44:0]')
    so.requireFits(c12.p.signal, K.P12_W, True, f'{name}.P12[48:0]')
    so.requireFits(d22.p.signal, K.P22_W, True, f'{name}.P22[48:0]')

    top = K.ADD_W - 1
    op1 = _slice(net, p01t, 0, K.P01_W - 1, False, f'{name}.tree_op1')
    op2 = _slice(net, net.op(so.add, net.op(so.lshift, p02q, K.LOW_W),
                             _slice(net, p00t, K.LOW_W, K.P00_W - 1, False, f'{name}.P00_t_hi')),
                 0, top, False, f'{name}.tree_op2')
    op3 = _slice(net, net.op(so.lshift, p12t, 2 * k), 0, top, False, f'{name}.tree_op3')
    op4 = _slice(net, net.op(so.lshift, p22t, 3 * k), 0, top, False, f'{name}.tree_op4')
    field = segmentedAdd(net, [op1, op2, op3, op4], K.ADD_W, plan, 2, f'{name}.tree')

    low = net.reg(_slice(net, d00.p, 0, K.LOW_W - 1, False, f'{name}.P_low_raw'),
                  plan['low_dly'], name=f'{name}.P_low')
    pattern = net.op(so.add, net.op(so.lshift, field, K.LOW_W), low, name=f'{name}.P_pat')
    p = net.op(so.reinterpret, pattern, K.P_W, True, name=f'{name}.P_raw')

    wires = {'X_hi': X_hi, 'X_mid': X_mid, 'X_lo': X_lo,
             'Y_hi': Y_hi, 'Y_mid': Y_mid, 'Y_lo': Y_lo,
             'Y0Y1': Y0Y1, 'Y0Y2': Y0Y2, 'Y1Y2': Y1Y2,
             'u_dsp_00.P': d00.p, 'u_dsp_11.P': d11.p, 'u_dsp_22.P': d22.p,
             'u_dsp_01.P': c01.p, 'u_dsp_12.P': c12.p, 'u_dsp_02.P': c02.p,
             'u_dsp_01.AD': c01.ad, 'u_dsp_12.AD': c12.ad, 'u_dsp_02.AD': c02.ad,
             'P02_add_P00': p02add, 'P_136_22': field}
    return _finish(net, p, x, y, K.P_W, name, wires)


# ---------------------------------------------------------------------------
# ToomCook25: 65 x 47 -> 112, four blocks
# ---------------------------------------------------------------------------

def toomCook25(net: Net, x: Wire, y: Wire, plan: Plan, *, name: str) -> tuple[Wire, Wires]:
    '''`gen_toomcook25`.

        X = X0 + X1*2^21 + X2*2^42     (21, 21 unsigned; 23 signed)
        Y = Y0 + Y1*2^21               (21 unsigned; 26 signed)
        coefficients  P0 = X0*Y0,  P1 = X0*Y1 + X1*Y0,  P2 = X1*Y1 + X2*Y0,  P3 = X2*Y1
        X(+1) = X0 + X1 + X2,  X(-1) = X0 - X1 + X2            (fabric, 24; xeval_ff)
        u_dsp_p0:  P0            u_dsp_p3:  P3   (A side Y1, B side X2)
        u_dsp_p2_plus_p1:  AD = Y0 + Y1;  P = M - C - PCIN - 1 = (P1 + P2) - 1
        u_dsp_p2_minus_p1: AD = Y0 - Y1;  P = M + C - PCIN     = P2 - P1
        twice_P1 = (S-1) - D + 1 = 2*P1 ;  twice_P2 = (S-1) + D + 1 = 2*P2   (59)
        P1 = twice_P1[58:1] ;  P2 = twice_P2[58:1]                           (interp_d1)
        Q = P0[41:21] + P1 + P2<<21 + P3<<42        segmented, mod 2^91
        P = {Q, P0[20:0]}
    '''
    T = _t25
    X0 = _slice(net, x, 0, T.X0_W - 1, False, f'{name}.X0')
    X1 = _slice(net, x, T.X0_W, T.X0_W + T.X1_W - 1, False, f'{name}.X1')
    X2 = _slice(net, x, T.X0_W + T.X1_W, T.X_W - 1, True, f'{name}.X2')
    Y0 = _slice(net, y, 0, T.Y0_W - 1, False, f'{name}.Y0')
    Y1 = _slice(net, y, T.Y0_W, T.Y_W - 1, True, f'{name}.Y1')

    xp1 = net.op(so.add, net.op(so.add, X0, X1), X2, name=f'{name}.X_at_p1')
    xm1 = net.op(so.add, net.op(so.sub, X0, X1), X2, name=f'{name}.X_at_m1')
    so.requireFits(xp1.signal, T.XEVAL_W, True, f'{name}.X_at_p1')
    so.requireFits(xm1.signal, T.XEVAL_W, True, f'{name}.X_at_m1')
    xff = int(plan.cfg['xeval_ff']) if plan.timed else 0
    bp1 = net.reg(xp1, xff, name=f'{name}.X_at_p1_q')
    bm1 = net.reg(xm1, xff, name=f'{name}.X_at_m1_q')

    diag = _plain(plan, 'diag_A', 'diag_M', 'diag_P') if plan.timed else Dsp58Config()
    p0 = dsp58(net, diag, X0, Y0, name=f'{name}.u_dsp_p0')
    p3 = dsp58(net, diag, Y1, X2, name=f'{name}.u_dsp_p3')          # A <- Y1, B <- X2

    P1 = so.add(so.mul(X0.signal, Y1.signal), so.mul(X1.signal, Y0.signal))
    P2 = so.add(so.mul(X1.signal, Y1.signal), so.mul(X2.signal, Y0.signal))
    oneS = so.const(1, like=x.signal)

    evalS = _cross(plan, cPipeKey=None, preaddSub=False, negC=True, negPcin=True)
    evalD = _cross(plan, cPipeKey=None, preaddSub=True, negC=False, negPcin=True)
    s1 = dsp58(net, evalS, Y1, bp1, c=p0.p, d=Y0, pcin=p3.pcout, name=f'{name}.u_dsp_p2_plus_p1')
    dd = dsp58(net, evalD, Y1, bm1, c=p3.p, d=Y0, pcin=p0.pcout, name=f'{name}.u_dsp_p2_minus_p1')
    net.tighten(s1.p, so.sub(so.add(P1, P2), oneS), f'{name}.u_dsp_p2_plus_p1.P == (P1 + P2) - 1')
    net.tighten(dd.p, so.sub(P2, P1), f'{name}.u_dsp_p2_minus_p1.P == P2 - P1')

    one = net.const(1, like=x, name=f'{name}.one')
    tw1 = net.op(so.add, net.op(so.sub, s1.p, dd.p), one, name=f'{name}.twice_P1')
    tw2 = net.op(so.add, net.op(so.add, s1.p, dd.p), one, name=f'{name}.twice_P2')
    net.tighten(tw1, so.lshift(P1, 1), f'{name}.twice_P1 == 2*P1')
    net.tighten(tw2, so.lshift(P2, 1), f'{name}.twice_P2 == 2*P2')
    so.requireFits(tw1.signal, T.INTERP_W, True, f'{name}.twice_P1')
    so.requireFits(tw2.signal, T.INTERP_W, True, f'{name}.twice_P2')
    for nm, tw in (('twice_P1', tw1), ('twice_P2', tw2)):
        if tw.values is not None and any(v & 1 for v in tw.values):
            raise ValueError(f'{name}.{nm}: not even — the interpolation is broken')
    p1c = _slice(net, tw1, 1, T.INTERP_W - 1, True, f'{name}.P1_comb')
    p2c = _slice(net, tw2, 1, T.INTERP_W - 1, True, f'{name}.P2_comb')
    iff = int(plan.cfg['interp_d1']) if plan.timed else 0
    p1 = net.reg(p1c, iff, name=f'{name}.P1_reg')
    p2 = net.reg(p2c, iff, name=f'{name}.P2_reg')

    so.requireFits(p0.p.signal, T.P0_TREE_W, False, f'{name}.P0[41:0]')
    p0t = net.reg(p0.p, plan['p0_to_tree'], name=f'{name}.P0_t')
    p3t = net.reg(p3.p, plan['p3_to_tree'], name=f'{name}.P3_t')

    top = T.ADD_W - 1
    q0 = _slice(net, p0t, T.LOW_W, T.P0_TREE_W - 1, False, f'{name}.Q_op0')
    q1 = _slice(net, p1, 0, top, False, f'{name}.Q_op1')
    q2 = _slice(net, net.op(so.lshift, p2, T.LIMB_W), 0, top, False, f'{name}.Q_op2')
    q3 = _slice(net, net.op(so.lshift, p3t, 2 * T.LIMB_W), 0, top, False, f'{name}.Q_op3')
    Q = segmentedAdd(net, [q0, q1, q2, q3], T.ADD_W, plan, 2, f'{name}.Q')

    low = net.reg(_slice(net, p0.p, 0, T.LOW_W - 1, False, f'{name}.P_low_raw'),
                  plan['low_dly'], name=f'{name}.P_low')
    pattern = net.op(so.add, net.op(so.lshift, Q, T.LOW_W), low, name=f'{name}.P_pat')
    p = net.op(so.reinterpret, pattern, T.P_W, True, name=f'{name}.P_raw')

    wires = {'X0': X0, 'X1': X1, 'X2': X2, 'Y0': Y0, 'Y1': Y1,
             'X_at_p1': xp1, 'X_at_m1': xm1,
             'u_dsp_p0.P': p0.p, 'u_dsp_p3.P': p3.p,
             'u_dsp_p2_plus_p1.AD': s1.ad, 'u_dsp_p2_plus_p1.P': s1.p,
             'u_dsp_p2_minus_p1.AD': dd.ad, 'u_dsp_p2_minus_p1.P': dd.p,
             'twice_P1': tw1, 'twice_P2': tw2, 'P1_comb': p1c, 'P2_comb': p2c, 'Q': Q}
    return _finish(net, p, x, y, T.P_W, name, wires)
