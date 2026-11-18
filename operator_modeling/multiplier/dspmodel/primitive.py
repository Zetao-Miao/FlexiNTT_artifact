'''`DSP58Block` as a pipelined netlist.

Mirrors `versal_arith/rtl/dsp_multiplier/DSP58Block.sv`: the same parameters,
the same port widths, the same seven pipeline-register counts, and the ALU
behaviour derived the same way that file derives it — from
`NEG_C / NEG_PCIN / NEG_M` through the `ALUMODE`, `NEGATE` and `CARRYIN`
localparams, then the DSP58 ALU table. Reading that file next to this one
should feel like reading the same thing twice.

What the block computes, in INT24 mode with `USE_MULT = MULTIPLY`:

    AD = D ± A[26:0]        if PREADD, else A[26:0]        (27-bit)
    M  = AD * B             27 x 24 signed                  (51-bit)
    W  = C  if USEC else 0
    Z  = 0 | PCIN | PCIN >>> 23                             (58-bit)
    P  = ALU(Z, W, ±M, CIN)                                 (58-bit)

and the ALU, per ALUMODE:

    0000   Z + (W + X + Y + CIN)
    0001  -Z + (W + X + Y + CIN) - 1
    0010  -(Z + W + X + Y + CIN) - 1
    0011   Z - (W + X + Y + CIN)

where X + Y is the multiplier output, negated when NEGATE[0] is set. Folding
the localparams through that table gives one closed form,

    P = (-1)^NEG_M * M  +  (-1)^NEG_C * W  +  (-1)^NEG_PCIN * Z  -  [NEG_C and NEG_PCIN]

and the last term is real hardware: the Toom-2.5 generator's own comment on
the DSP it configures that way reads *"This encoding yields S-1; the
interpolation below adds the missing +1 back."* `closedForm` is that
formula, written out so the two can be compared by hand. Nothing calls it:
there is no self-test holding it against the localparam derivation.

Where the registers are — the primitive's datapath, fixed by the silicon:

    A ──AREG──┐
    D ──DREG──┴─ pre-adder ──ADREG──┐
    B ──BREG────────────────────────┴─ multiplier ──MREG──┐
    C ──CREG───────────────────────────────────────────────┤
    PCIN ──────────────────────────────────────────────────┴─ ALU ──PREG── P, PCOUT

`AREG = A_PIPE`, `DREG = D_PIPE`, `ADREG = PREADD_PIPE`, `BREG = B_PIPE`,
`CREG = C_PIPE`, `MREG = MULT_PIPE`, `PREG = P_PIPE`. Nothing here chooses
a count; every tile passes the numbers its generator wrote into the
instantiation, which the generator took from the backend's chosen latency.
The netlist engine then refuses the multiplier, the pre-adder or the ALU if
their operands sit at different depths — which is the DSP58's own timing
contract (`BREG = AREG + ADREG`, C and PCIN meeting M at the ALU) checked
from the numbers rather than assumed.

Every register the block owns is asserted: the pre-adder result fits 27
bits, the product fits 51, and P fits 58. The last one is the check the
whole DSP layer exists for — a cascade accumulating past 58 bits is exactly
the kind of thing the backend's timing and cost models never look at.
'''
from __future__ import annotations

from dataclasses import dataclass

from . import signalops as so
from .net import Net, Wire

#: DSP58 port and register widths, INT24 mode.
A_PORT_WIDTH = 34          # the port; the multiplier and pre-adder read A[26:0]
A_MULT_WIDTH = 27
B_WIDTH = 24
C_WIDTH = 58
D_WIDTH = 27
P_WIDTH = 58
M_WIDTH = A_MULT_WIDTH + B_WIDTH      # 51
PCIN_SHIFT = 23            # the only cascade shift the block exposes


@dataclass(frozen=True)
class Dsp58Config:
    '''The parameters `DSP58Block.sv` takes: mode, then the seven pipeline counts.'''
    preadd: bool = False       # AMULTSEL = "AD": multiply the pre-adder output
    preaddSub: bool = False    # AD = D - A when set, D + A otherwise
    useC: bool = False         # W = C
    usePcin: str = 'ZERO'      # 'ZERO' | 'PCIN' | 'PCIN_SHIFT23'
    negC: bool = False
    negPcin: bool = False
    negM: bool = False
    aPipe: int = 0             # AREG      (A_PIPE)
    preaddPipe: int = 0        # ADREG     (PREADD_PIPE)
    bPipe: int = 0             # BREG      (B_PIPE)
    cPipe: int = 0             # CREG      (C_PIPE)
    dPipe: int = 0             # DREG      (D_PIPE)
    multPipe: int = 0          # MREG      (MULT_PIPE)
    pPipe: int = 0             # PREG      (P_PIPE)

    def __post_init__(self):
        if self.usePcin not in ('ZERO', 'PCIN', 'PCIN_SHIFT23'):
            raise ValueError(f'usePcin must be ZERO, PCIN or PCIN_SHIFT23, got {self.usePcin!r}')
        for k in ('aPipe', 'preaddPipe', 'bPipe', 'cPipe', 'dPipe', 'multPipe', 'pPipe'):
            if getattr(self, k) < 0:
                raise ValueError(f'{k} must be >= 0')
        if self.aPipe > 2 or self.bPipe > 2:
            raise ValueError('DSP58 has at most two AREG / BREG stages')
        if not self.preadd and self.preaddPipe:
            raise ValueError('ADREG only exists on the pre-adder path (PREADD)')

    # -- the localparams, exactly as DSP58Block.sv derives them -------------

    @property
    def alumode(self) -> int:
        if self.negC:
            return 0b0010 if self.negPcin else 0b0011
        return 0b0001 if self.negPcin else 0b0000

    @property
    def negate0(self) -> bool:
        m, c, z = self.negM, self.negC, self.negPcin
        return ((m and not c and not z) or (not m and c and not z)
                or (m and not c and z) or (not m and c and z))

    @property
    def carryin(self) -> int:
        return 1 if (self.negPcin and not self.negC) else 0

    @property
    def latency(self) -> int:
        '''`PIPE_STAGE` in the .sv: registers on the A-to-P path.'''
        return self.aPipe + self.preaddPipe + self.multPipe + self.pPipe


@dataclass(frozen=True)
class Dsp58Wires:
    '''Every wire inside one block, so a caller can inspect, check or dump them.'''
    p: Wire
    pcout: Wire
    ad: Wire        # what the multiplier actually saw on its A side
    m: Wire         # the raw product, before NEGATE
    w: Wire
    z: Wire


def dsp58(net: Net, cfg: Dsp58Config, a: Wire, b: Wire,
          c: Wire | None = None, d: Wire | None = None,
          pcin: Wire | None = None, *, name: str = 'dsp') -> Dsp58Wires:
    '''One `DSP58Block` in `net`. Unused ports may be omitted; they read as zero.

    `a` is asserted against the 27 bits the multiplier reads, not the 34-bit
    port: a value that needs more than A[26:0] would be silently truncated by
    the hardware, and that is a wiring error in the tile, not a number.
    '''
    zero = net.const(0, like=a, name=f'{name}.zero')
    so.requireFits(a.signal, A_MULT_WIDTH, True, f'{name}.A[26:0]')
    so.requireFits(b.signal, B_WIDTH, True, f'{name}.B')

    aR = net.reg(a, cfg.aPipe, name=f'{name}.AREG')
    if cfg.preadd:
        d = zero if d is None else d
        so.requireFits(d.signal, D_WIDTH, True, f'{name}.D')
        dR = net.reg(d, cfg.dPipe, name=f'{name}.DREG')
        adC = net.op(so.sub if cfg.preaddSub else so.add, dR, aR, name=f'{name}.AD')
        so.requireFits(adC.signal, A_MULT_WIDTH, True, f'{name}.AD (pre-adder)')
        ad = net.reg(adC, cfg.preaddPipe, name=f'{name}.ADREG')
    else:
        ad = aR

    bR = net.reg(b, cfg.bPipe, name=f'{name}.BREG')
    mC = net.op(so.mul, ad, bR, name=f'{name}.M')
    so.requireFits(mC.signal, M_WIDTH, True, f'{name}.M (multiplier)')
    m = net.reg(mC, cfg.multPipe, name=f'{name}.MREG')
    xy = net.op(so.neg, m, name=f'{name}.negM') if cfg.negate0 else m

    if cfg.useC:
        if c is None:
            raise ValueError(f'{name}: USEC without a C operand')
        so.requireFits(c.signal, C_WIDTH, True, f'{name}.C')
        w = net.reg(c, cfg.cPipe, name=f'{name}.CREG')
    else:
        w = zero

    if cfg.usePcin == 'ZERO':
        z = zero
    else:
        if pcin is None:
            raise ValueError(f'{name}: USEPCIN without a PCIN operand')
        so.requireFits(pcin.signal, P_WIDTH, True, f'{name}.PCIN')
        z = pcin if cfg.usePcin == 'PCIN' else net.op(so.rshift, pcin, PCIN_SHIFT,
                                                     name=f'{name}.PCIN>>>23')

    cin = net.const(cfg.carryin, like=a, name=f'{name}.CARRYIN')
    one = net.const(1, like=a, name=f'{name}.one')
    inner = net.op(so.add, net.op(so.add, w, xy, name=f'{name}.W+XY'), cin,
                   name=f'{name}.W+XY+CIN')
    if cfg.alumode == 0b0000:
        pC = net.op(so.add, z, inner, name=f'{name}.ALU')
    elif cfg.alumode == 0b0001:
        pC = net.op(so.sub, net.op(so.sub, inner, z), one, name=f'{name}.ALU')
    elif cfg.alumode == 0b0010:
        pC = net.op(so.sub, net.op(so.neg, net.op(so.add, z, inner)), one, name=f'{name}.ALU')
    else:  # 0b0011
        pC = net.op(so.sub, z, inner, name=f'{name}.ALU')

    so.requireFits(pC.signal, P_WIDTH, True, f'{name}.P (58-bit accumulator)')
    p = net.reg(pC, cfg.pPipe, name=f'{name}.PREG')
    return Dsp58Wires(p=p, pcout=p, ad=ad, m=mC, w=w, z=z)


def closedForm(cfg: Dsp58Config, m: int, c: int, z: int) -> int:
    '''What P must equal, from the docstring's derivation. For the self-test.'''
    return ((-m if cfg.negM else m)
            + ((-c if cfg.negC else c) if cfg.useC else 0)
            + ((-z if cfg.negPcin else z) if cfg.usePcin != 'ZERO' else 0)
            - (1 if (cfg.negC and cfg.negPcin) else 0))
