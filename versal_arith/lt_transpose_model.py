"""The lane-time transpose (`rtl/matrix_transpose/lt_bmb_transpose.sv`): its twin, latency, cost and
register placement.

A lane-time swap exchanges the s = log2 S lane bits of a group of S lanes with the cycle bits
[LO, LO + s) of the stream: the input at (cycle (hi, r, lo), lane u) leaves at (cycle (hi, u, lo),
lane r). LO = 0 is the square S x S transpose of `bmb_matrix_transpose.sv`; LO > 0 is 2^LO such
transposes interleaved, a window of WIN = S * 2^LO cycles. Built the same way: rotate row (r, lo) by r,
store it in lane i at {r, lo} (even windows) or {i - r, lo} (odd windows), drain at step (c, lo)
reading {i - c, lo} (even) or {c, lo} (odd), rotate back by -c. The next window's write of a cell
happens in the same cycle as, or after, the drain's read of it (read-first), so windows follow back to
back in one memory of WIN words per lane (no ping-pong copy). Latency WIN + 2 BL + 1.
"""
from __future__ import annotations

from typing import Sequence

from transpose_model import (BarrelShifter, DelayLine, Memory, barrel_latency, barrel_luts, check_flags,
                             default_flags)


def lt_bmb_latency(S: int, lo: int, flags: Sequence[bool]) -> int:
    return S * (1 << lo) + 2 * barrel_latency(check_flags(S, flags)) + 1


class LtBmbTranspose:
    """lt_bmb_transpose.sv, one group of S lanes."""

    def __init__(self, S: int, lo: int, flags: Sequence[bool] | None = None):
        self.S, self.lo = S, lo
        self.win = S << lo
        self.flags = check_flags(S, default_flags(S) if flags is None else flags)
        bl = barrel_latency(self.flags)
        self.shift0 = BarrelShifter(S, self.flags)
        self.shift1 = BarrelShifter(S, self.flags)
        self.bank = [Memory(self.win) for _ in range(S)]
        self.wr_cnt, self.wr_phase = 0, 0
        self.wr_sideband = DelayLine(bl, (0, 0, 0))
        self.rd_active, self.rd_phase, self.rd_cnt = 0, 0, 0
        self.rd_sideband = DelayLine(1, (0, 0))
        self.out_valid = DelayLine(bl, 0)

    @property
    def latency(self) -> int:
        return lt_bmb_latency(self.S, self.lo, self.flags)

    def tick(self, row):
        S, lo, win = self.S, self.lo, self.win
        m = (1 << lo) - 1
        valid_in = row is not None
        data_in = list(row) if valid_in else [None] * S
        bs0 = self.shift0.tick(data_in, (self.wr_cnt >> lo) % S)
        v_d, ph_d, cnt_d = self.wr_sideband.tick((int(valid_in), self.wr_phase, self.wr_cnt))
        r_d, lo_d = cnt_d >> lo, cnt_d & m
        rc, rlo = self.rd_cnt >> lo, self.rd_cnt & m
        out = []
        for i in range(S):
            wa = ((((i - r_d) % S) << lo) | lo_d) if ph_d else cnt_d
            ra = ((rc << lo) | rlo) if self.rd_phase else ((((i - rc) % S) << lo) | rlo)
            out.append(self.bank[i].tick(bool(v_d), wa, ra, bs0[i]))
        act_d, col_d = self.rd_sideband.tick((self.rd_active, rc))
        data_out = self.shift1.tick(out, (-col_d) % S)
        ov = self.out_valid.tick(act_d)
        if v_d and cnt_d == win - 1:
            self.rd_active, self.rd_phase, self.rd_cnt = 1, ph_d, 0
        elif self.rd_active:
            if self.rd_cnt == win - 1:
                self.rd_active = 0
            self.rd_cnt = (self.rd_cnt + 1) % win
        if valid_in:
            if self.wr_cnt == win - 1:
                self.wr_phase ^= 1
            self.wr_cnt = (self.wr_cnt + 1) % win
        else:
            self.wr_cnt = 0
        return data_out, int(ov)


def lt_flags_for_fmax(S: int, P: int, w: int, lo: int, fmax: float | None) -> tuple[bool, ...]:
    """Register placement of the two shifters (S lanes; the select nets are replicated per group, so
    the fan-out is S * w): the fewest registers reaching `fmax` by the calibrated transpose table,
    priced at the group's size; None: a register after every mux stage."""
    if S < 2:
        return ()
    if fmax is None:
        return default_flags(S)
    from lut_timing import transpose_flags_for_fmax
    return tuple(transpose_flags_for_fmax('bmb', S, w, fmax, label=f'lt transpose S={S}'))


def lt_cost(kind: str, S: int, P: int, w: int, lo: int, flags, memStyle: str = 'auto',
            uramMinDepth: int | None = None) -> dict:
    """LUT / BRAM36 / LUTRAM of a lane-time transpose over P lanes (P / S groups). Memory per lane:
    WIN = S 2^lo words (bmb). Depth <= 64: LUTRAM (one LUT per bit per 64 words, as distributed RAM
    in SDP mode: ceil(w / 1)... priced at w * ceil(depth/64) LUTs); otherwise BRAM tiles by the
    `bramTiles` rule. 'mbm' (model only): one shifter, banks of 2 WIN + WIN words."""
    import math
    win = S << lo
    G = P // S
    shifters = 2 if kind == 'bmb' else 1
    depths = [win] if kind == 'bmb' else [2 * win, win]
    lut = G * shifters * barrel_luts(S, w) + 8 * P
    bram = 0.0
    uram = 0
    lutram = 0
    for dep in depths:
        if dep <= 64:
            # SDP distributed RAM: a LUT6 holds 64x1 (RAM64M8 7 bits per 8 LUTs at 64 deep): ~8/7 LUT per bit
            lutram += P * math.ceil(w * 8 / 7) * math.ceil(dep / 64)
        else:
            from operator_modeling.ntt.multistep.MultiStepScheme import memoryTiles
            r = memoryTiles(dep, w, memStyle, uramMinDepth)
            bram += P * r['bram36']
            uram += P * r['uram']
    return {'lut': lut + lutram, 'lutram': lutram, 'dsp': 0, 'bram36': bram, 'uram': uram, 'words': P * sum(depths),
            'latency': lt_bmb_latency(S, lo, flags) if kind == 'bmb' else None, 'S': S, 'lo': lo}
