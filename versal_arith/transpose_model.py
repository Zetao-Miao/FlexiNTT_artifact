"""Cycle-accurate twins of the matrix transpose modules in `rtl/matrix_transpose/`.

One Python class per SystemVerilog module, with the same registers, memories,
counters and sidebands, ticked one clock edge at a time:

    BarrelShifter   barrel_shift.sv     radix-4 rotate, registers where REG_FLAGS say
    Memory          BRAM.sv             read-first, one-cycle read, write enable
    BmbTranspose    bmb_matrix_transpose.sv
    MbmTranspose    mbm_matrix_transpose.sv

A value on a lane is whatever the caller puts there -- an int, or a batch of
independent trials as a list -- or `None` where the hardware holds nothing
meaningful yet (a register never written, a memory word never stored, a cycle
with data_valid low). Nothing here does arithmetic: a transpose moves values,
so `None` moves like any other value and the fill of the pipeline shows up as
`None` on the outputs.

The convention every `tick` follows: it is called once per clock cycle with
the inputs presented during that cycle and returns the outputs visible during
that same cycle (register contents, plus whatever combinational logic derives
from this cycle's inputs), then moves every register to its next state for
the edge that ends the cycle. A parent module calls its children in dataflow
order inside its own `tick`, so a combinational path -- an unregistered
shifter tail feeding a BRAM write -- is honoured within the cycle exactly as
in the RTL.

The generator (`rtl_gen/transpose.py`) runs these twins over the testbench's
stimulus to know at which cycle every output row must appear, and the model
(`operator_modeling.transpose`) steps them as its clocked `step()`. Both
therefore read the transposes' latency off the same bookkeeping the RTL is
built from; `bmb_latency` / `mbm_latency` are the closed forms, asserted
against the twins by `runMatrixTranspose.py`.
"""
from __future__ import annotations

from collections import deque
from typing import Sequence


# ---------------------------------------------------------------- geometry
def barrel_depth(n: int) -> int:
    """log2(n) for a power-of-two n >= 2, the shift's width in bits."""
    if n < 2 or n & (n - 1):
        raise ValueError(f"the stream size must be a power of two >= 2, got {n}")
    return n.bit_length() - 1


def barrel_stages(n: int) -> int:
    """Mux stages of the radix-4 shifter: ceil(log2(n) / 2)."""
    return (barrel_depth(n) + 1) // 2


def default_flags(n: int) -> tuple[bool, ...]:
    """A register after every mux stage: the structure the module has by default."""
    return (True,) * barrel_stages(n)


def check_flags(n: int, flags: Sequence[bool]) -> tuple[bool, ...]:
    f = tuple(bool(x) for x in flags)
    if len(f) != barrel_stages(n):
        raise ValueError(
            f"a barrel shifter over {n} elements has {barrel_stages(n)} mux stages, "
            f"got {len(f)} register flags"
        )
    return f


def barrel_latency(flags: Sequence[bool]) -> int:
    """Registers in the shifter: $countones(REG_FLAGS)."""
    return sum(1 for x in flags if x)


def flags_to_reg_flags(flags: Sequence[bool]) -> int:
    """The REG_FLAGS parameter value: bit s set when stage s is registered."""
    return sum(1 << s for s, x in enumerate(flags) if x)


def bmb_latency(n: int, flags: Sequence[bool]) -> int:
    """Cycles from a row on data_in to the same-numbered column on data_out."""
    return n + 2 * barrel_latency(check_flags(n, flags)) + 1


def mbm_latency(n: int, flags: Sequence[bool]) -> int:
    """Cycles from a row on data_in to the same-numbered column on data_out for
    a burst whose first row arrives with tau == 0; a burst arriving off the
    frame waits (-tau) mod n cycles more."""
    return n + barrel_latency(check_flags(n, flags)) + 3


def barrel_luts(n: int, w: int, flags: Sequence[bool] | None = None) -> int:
    """LUTs of the shifter by construction: n*w per 4:1 stage, n*ceil(w/2) for
    the 2:1 stage an odd depth ends with. Independent of the register flags."""
    d = barrel_depth(n)
    full = d // 2
    odd = d % 2
    return full * n * w + odd * n * ((w + 1) // 2)


# ---------------------------------------------------------------- helpers
class DelayLine:
    """delay_line.sv: a value delayed `depth` cycles; depth 0 is a wire."""

    def __init__(self, depth: int, init=0):
        if depth < 0:
            raise ValueError(f"depth must be >= 0, got {depth}")
        self.depth = depth
        self.pipe = deque([init] * depth, maxlen=depth) if depth else None

    def tick(self, d):
        if self.depth == 0:
            return d
        q = self.pipe[-1]
        self.pipe.appendleft(d)
        return q


def _rotate_source(n: int, b: int, amount: int) -> int:
    """The lane a rotation by `amount` reads for output lane b."""
    return (b - amount) % n


# ---------------------------------------------------------------- modules
class BarrelShifter:
    """barrel_shift.sv. `data_out[b] = data_in[(b - shift) mod n]`, computed
    in ceil(log2 n / 2) mux stages on the shift's bit pairs, most significant
    first, a register after stage s where `flags[s]`."""

    def __init__(self, n: int, flags: Sequence[bool] | None = None):
        self.n = n
        self.d = barrel_depth(n)
        self.stages = barrel_stages(n)
        self.flags = check_flags(n, default_flags(n) if flags is None else flags)
        # data_q / shift_q of every registered stage, keyed by stage index
        self.data_q = {s: [None] * n for s, f in enumerate(self.flags) if f}
        self.shift_q = {s: 0 for s, f in enumerate(self.flags) if f}

    @property
    def latency(self) -> int:
        return barrel_latency(self.flags)

    def stage_amounts(self, s: int) -> tuple[bool, int]:
        """(4:1 stage?, rotation per select step) of mux stage s."""
        full = 2 * s + 1 < self.d
        unit = (self.n >> (2 * s + 2)) if full else 1
        return full, unit

    def tick(self, data_in: Sequence, shift: int) -> list:
        n, d = self.n, self.d
        cur = list(data_in)
        cur_shift = shift % n
        updates = {}
        for s in range(self.stages):
            full, unit = self.stage_amounts(s)
            if full:
                sel = (cur_shift >> (d - 2)) & 0b11
            else:
                sel = (cur_shift >> (d - 1)) & 0b1
            amount = sel * unit
            mux = [cur[_rotate_source(n, b, amount)] for b in range(n)]
            nxt_shift = (cur_shift << 2) & ((1 << d) - 1)
            if self.flags[s]:
                updates[s] = (mux, nxt_shift)
                cur, cur_shift = self.data_q[s], self.shift_q[s]
            else:
                cur, cur_shift = mux, nxt_shift
        for s, (mux, nxt_shift) in updates.items():
            self.data_q[s] = mux
            self.shift_q[s] = nxt_shift
        return cur


class Memory:
    """BRAM.sv: `depth` words, written when `wr_en`, read with a one-cycle
    latency, read-first on a collision (the read returns the word stored
    before this cycle's write)."""

    def __init__(self, depth: int):
        self.depth = depth
        self.words = [None] * depth
        self.q = None

    def tick(self, wr_en: bool, wr_addr: int, rd_addr: int, data_in):
        out = self.q
        self.q = self.words[rd_addr % self.depth]
        if wr_en:
            self.words[wr_addr % self.depth] = data_in
        return out


class BmbTranspose:
    """bmb_matrix_transpose.sv: shifter, one bank, shifter, with a write
    counter per burst and a drain counter per matrix."""

    kind = 'bmb'

    def __init__(self, n: int, flags: Sequence[bool] | None = None):
        self.n = n
        self.d = barrel_depth(n)
        self.flags = check_flags(n, default_flags(n) if flags is None else flags)
        bl = barrel_latency(self.flags)
        self.barrel_latency = bl
        self.shift0 = BarrelShifter(n, self.flags)
        self.shift1 = BarrelShifter(n, self.flags)
        self.bank = [Memory(n) for _ in range(n)]
        self.wr_row = 0
        self.wr_phase = 0
        self.wr_sideband = DelayLine(bl, (0, 0, 0))
        self.rd_active = 0
        self.rd_phase = 0
        self.rd_col = 0
        self.rd_sideband = DelayLine(1, (0, 0))
        self.out_valid = DelayLine(bl, 0)

    @property
    def latency(self) -> int:
        return bmb_latency(self.n, self.flags)

    def tick(self, row: Sequence | None) -> tuple[list, int]:
        """One clock cycle: `row` is this cycle's data_in (None = data_valid
        low). Returns (data_out, data_out_valid) as visible this cycle."""
        n = self.n
        valid_in = row is not None
        data_in = list(row) if valid_in else [None] * n
        if valid_in and len(data_in) != n:
            raise ValueError(f"a row has {n} elements, got {len(data_in)}")

        # first shifter and its sideband
        bs0_out = self.shift0.tick(data_in, self.wr_row)
        v_d, ph_d, row_d = self.wr_sideband.tick((int(valid_in), self.wr_phase, self.wr_row))

        # the bank
        bank_out = []
        for i in range(n):
            wr_addr = (i - row_d) % n if ph_d else row_d
            rd_addr = self.rd_col if self.rd_phase else (i - self.rd_col) % n
            bank_out.append(self.bank[i].tick(bool(v_d), wr_addr, rd_addr, bs0_out[i]))

        # second shifter and the output valid
        rd_active_d, rd_col_d = self.rd_sideband.tick((self.rd_active, self.rd_col))
        data_out = self.shift1.tick(bank_out, (-rd_col_d) % n)
        out_valid = self.out_valid.tick(rd_active_d)

        # register updates for the edge that ends this cycle
        last_row_written = v_d and row_d == n - 1
        if last_row_written:
            self.rd_active, self.rd_phase, self.rd_col = 1, ph_d, 0
        elif self.rd_active:
            if self.rd_col == n - 1:
                self.rd_active = 0
            self.rd_col = (self.rd_col + 1) % n
        if valid_in:
            if self.wr_row == n - 1:
                self.wr_phase ^= 1
            self.wr_row = (self.wr_row + 1) % n
        else:
            self.wr_row = 0
        return data_out, int(out_valid)


class MbmTranspose:
    """mbm_matrix_transpose.sv: two banks around one shifter, addressed from a
    free-running frame counter; every matrix is re-aligned to the frame
    through a two-matrix-deep input bank."""

    kind = 'mbm'

    def __init__(self, n: int, flags: Sequence[bool] | None = None):
        self.n = n
        self.d = barrel_depth(n)
        self.flags = check_flags(n, default_flags(n) if flags is None else flags)
        bl = barrel_latency(self.flags)
        self.barrel_latency = bl
        self.tau_taps = bl + 2
        self.tau = 0
        self.tau_dly = [0] * self.tau_taps          # tau_dly[k] = tau delayed k+1
        self.wr_row = 0
        self.wr_half = 0
        self.pending = 0
        self.pending_half = 0
        self.cur_win = (0, 0)                        # (valid, half)
        self.win_dly = [(0, 0)] * n                  # win_dly[i] = cur_win delayed i (index 0 unused)
        self.in_bank = [Memory(2 * n) for _ in range(n)]
        self.shift = BarrelShifter(n, self.flags)
        self.out_bank = [Memory(n) for _ in range(n)]
        self.out_valid = DelayLine(n + bl + 2, 0)

    @property
    def latency(self) -> int:
        return mbm_latency(self.n, self.flags)

    def tick(self, row: Sequence | None) -> tuple[list, int]:
        """One clock cycle: `row` is this cycle's data_in (None = data_valid
        low). Returns (data_out, data_out_valid) as visible this cycle."""
        n = self.n
        valid_in = row is not None
        data_in = list(row) if valid_in else [None] * n
        if valid_in and len(data_in) != n:
            raise ValueError(f"a row has {n} elements, got {len(data_in)}")
        first_row = valid_in and self.wr_row == 0
        cur_win = self.cur_win                       # the value visible this cycle

        # input bank: written as rows arrive, read on the skew in the window's half
        in_out = []
        for i in range(n):
            lane_win = cur_win if i == 0 else self.win_dly[i]
            wr_addr = self.wr_half * n + self.wr_row
            rd_addr = lane_win[1] * n + (self.tau_dly[0] - i) % n
            in_out.append(self.in_bank[i].tick(valid_in, wr_addr, rd_addr, data_in[i]))

        # the shifter, then the output bank
        bs_out = self.shift.tick(in_out, (-self.tau_dly[1]) % n)
        v = self.tau_dly[self.tau_taps - 1]
        data_out = []
        for j in range(n):
            data_out.append(self.out_bank[j].tick(True, v, (v + j) % n, bs_out[(n - j) % n]))
        out_valid = self.out_valid.tick(cur_win[0])

        # register updates for the edge that ends this cycle (every right-hand
        # side is a value visible during the cycle, as in the always_ff)
        if self.tau == 0:
            self.cur_win = (int(self.pending or first_row),
                            self.pending_half if self.pending else self.wr_half)
            self.pending = 0
        elif first_row:
            self.pending, self.pending_half = 1, self.wr_half
        self.win_dly = [None, cur_win] + self.win_dly[1:n - 1]   # win_dly[i] <= win_dly[i-1], win_dly[1] <= cur_win
        self.tau_dly = [self.tau] + self.tau_dly[:-1]
        self.tau = (self.tau + 1) % n
        if valid_in:
            if self.wr_row == n - 1:
                self.wr_half ^= 1
            self.wr_row = (self.wr_row + 1) % n
        else:
            self.wr_row = 0
        return data_out, int(out_valid)


# ---------------------------------------------------------------- driving
def run_schedule(model, schedule: Sequence, extra_cycles: int = 0) -> list[tuple[int, list, int]]:
    """Tick `model` once per entry of `schedule` (a row per cycle, None for a
    cycle with data_valid low), then `extra_cycles` idle cycles. Returns
    (cycle, data_out, data_out_valid) per cycle."""
    out = []
    for cycle, row in enumerate(schedule):
        data_out, valid = model.tick(row)
        out.append((cycle, data_out, valid))
    base = len(schedule)
    for k in range(extra_cycles):
        data_out, valid = model.tick(None)
        out.append((base + k, data_out, valid))
    return out


def valid_rows(trace) -> list[tuple[int, list]]:
    """The (cycle, row) pairs at which data_out_valid was high."""
    return [(c, r) for c, r, v in trace if v]


def transpose_rows(rows: Sequence[Sequence]) -> list[list]:
    """The plain transpose of one n x n matrix given as n rows."""
    return [list(col) for col in zip(*rows)]
