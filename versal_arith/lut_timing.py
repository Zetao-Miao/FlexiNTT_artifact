"""Versal LUT-fabric timing: what a compressor tree or Booth multiplier costs
per pipeline stage, where its registers should go, and how many cycles a
target frequency needs.

One model for every LUT-side block in the project. The DSP multiplier's
backend (`dsp_multiplier/backend/delay_model.py`) prices its `BitHeap` and
`LutMult` blocks through these functions, and the generators
(`rtl_gen/compressor.py`, `booth_mult.py`, `const_mult*.py`, `butterfly.py`)
place their registers through `place_registers`, so the nanoseconds a design
is reported at and the registers it is built with come from one table. The
streaming matrix transposes price and place the same way:
`operator_modeling.transpose.MatrixTransposeScheme` takes its shifter
register flags from `barrel_reg_flags` and its critical path from
`transpose_critical_ns`, which `rtl_gen/transpose.py` then emits as
REG_FLAGS.

Units
-----
A block is a chain of *units*, each one a possible register boundary:

    Booth multiplier   ppgen | gpc layer 1 | ... | gpc layer k | terminal adder
    compressor tree            gpc layer 1 | ... | gpc layer k | terminal adder
    plain adder                                                  adder
    barrel shifter             mux stage 1 | ... | mux stage k

A transpose is not one chain: only its shifter is a chain of units
(`barrel_units`); the BRAM read and the per-lane address arithmetic are
separate paths, and `transpose_paths` returns all of them (THEORY.md §11d).

The register-flag convention of `reg_flag_list_gen` is kept: flag `i` is True
when a register sits at the END of unit `i`. A segment is a run of units with
no register between them. Its delay is the units' logic, plus one ROUTE_INTER
hop per unit boundary crossed inside it, plus ENTRY (the driving flop's clk->Q
and the first routing hop) and EXIT (the last hop into the capturing flop).

Placement
---------
`place_registers(weights, stages)` puts `stages` registers where the slowest
segment is shortest. The rule it replaces split the units into equal-COUNT
groups, which is blind to the terminal adder weighing three or four GPC
layers: on a 64x64 Booth at three stages that rule leaves 2.98 ns where
2.36 ns is available. The equal-count split is kept as the tie-break, so any
design for which it was already optimal, every one-stage design included, is
built byte-for-byte as before.

`stages = 0` is a purely combinational block: no register anywhere and the
output unregistered. It prices the same as one stage (one segment); only the
capturing flop moves, into the consumer.

Frequency in, cycles out
------------------------
`stages_for_fmax(units, target)` returns the fewest stages whose slowest
segment meets the target, the counterpart of `select_fmax_point` on the DSP
side. It never returns 0: a combinational block is a deliberate manual choice,
not something a frequency target should silently produce. When no stage count
reaches the target the error names the unit that sets the floor, which is the
terminal adder for every shape wide enough to matter; splitting that adder is
the only way past it and is not available yet.

Calibration
-----------
The constants are measured post-implementation numbers for xcv80 -2MHP,
moved here verbatim from `delay_model.py` where they were calibrated. MHz
figures include CLK_UNCERTAINTY, the same convention as the DSP frontier's
`fmax_mhz`. DEBUG.md §2 records the validation sweep against implemented
designs; THEORY.md §8e points at it.
"""
from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
from itertools import combinations
from typing import Sequence

# ---- Vivado calibration constants (xcv80 -2MHP) ----
#
# Calibrated against measured post-implementation timing, not derived
# analytically. Two things an earlier model missed:
#   1. The terminal adder is already segmented (two chains, not one long carry
#      chain to the end), so its per-8-bit slope (TERM_PER_CARRY8) is shallower
#      than a naive ripple/lookahead estimate.
#   2. Routing between compression stages (PPGEN->GPC->...->terminal) is a real,
#      significant cost -- ROUTE_INTER accounts for it.
LOGIC_PPGEN     = 0.13    # measured 0.127, one stage of Booth re-encoding
LOGIC_GPC       = 0.42    # measured 0.353~0.482 (logic + same-layer internal routing combined)
ROUTE_INTER     = 0.36    # the routing hop between adjacent units within a segment
ENTRY           = 0.62    # FF clk->Q + the first routing hop
EXIT            = 0.05    # the last routing hop up to the next stage's FF setup time
TERM_FIXED      = 0.92    # re-calibrated from measurement (includes the chain1->chain2 routing hop)
TERM_FIXED_2OP  = 0.55    # 2-operand (sub_signed), no new measurement, kept as-is
TERM_PER_CARRY8 = 0.038   # matches sub_signed (0.041) and the 2-op path (0.037)
TERM_PER_CARRY8_2OP = 0.037   # no data for the 2-operand path, reuses the old slope

#: Clock uncertainty plus realistic skew, added when a delay becomes a
#: frequency. The DSP timing library reads its copy from here.
CLK_UNCERTAINTY = 0.150


def terminal_ns(width: int, two_operand: bool = False) -> float:
    """The final adder's logic+routing delay: TERM_FIXED plus TERM_PER_CARRY8
       per LOOKAHEAD8 block of the width. The 392-bit (sum33) calibration
       point measured 3.487 ns for ENTRY+GPC+ROUTE_INTER+terminal+EXIT; with
       the constants as they now stand that same path prices at 4.232 ns, i.e.
       on the conservative side -- the margin DEBUG.md §2 reports across the
       whole sweep. The 2-operand path (two_operand=True) has no new
       measurement data; the slope is reused from the old calibration."""
    if two_operand:
        return TERM_FIXED_2OP + TERM_PER_CARRY8_2OP * -(-width // 8)
    return TERM_FIXED + TERM_PER_CARRY8 * -(-width // 8)


def fmax_of(ns: float) -> float:
    """MHz for a worst stage of `ns`, clock uncertainty included."""
    return 1000.0 / (ns + CLK_UNCERTAINTY) if ns > 0 else float("inf")


# ---------------------------------------------------------------- units
@dataclass(frozen=True)
class Unit:
    """One register boundary's worth of logic."""
    kind: str      # 'ppgen' | 'gpc' | 'terminal' | 'adder'
    ns: float
    note: str = ''

    def __str__(self) -> str:
        return f"{self.note or self.kind} {self.ns:.2f} ns"


def weights(units: Sequence[Unit]) -> tuple[float, ...]:
    return tuple(u.ns for u in units)


def heap_width(heights: Sequence[int]) -> int:
    """Bits in the sum of a heap with these column heights."""
    return sum(1 << c for c, n in enumerate(heights) for _ in range(n)).bit_length()


@lru_cache(maxsize=None)
def _heap_layers(heights: tuple[int, ...]) -> tuple[int, bool]:
    """(compression layers after `merge_last_stage`, terminal adder is a plain
       two-operand add). The same count the generators derive by hand from
       `compressAll` + `formGPCChain` + `merge_last_stage`."""
    from dsp_multiplier.common.lut_cost import _analyse_bitheap
    from rtl_gen.terminal_add import quaternary_supported
    a = _analyse_bitheap(list(heights))
    layers = a.compression_layers - (1 if a.merged_last_stage else 0)
    # A terminal adder of two rows is a plain add; so is the behavioural one
    # `terminalAdd_gen` emits when the row-counter layout does not apply
    # (fewer than two columns of three or more bits): Vivado builds it as a
    # ternary add on carry chains, and on the V80 it measured 1.19-1.50 ns
    # where the quaternary price said 2.67-2.75 (THEORY.md section 8f).
    two = max(a.terminal_inputs, default=0) <= 2 or not quaternary_supported(a.terminal_inputs)
    return layers, two


def heap_layers(heights: Sequence[int]) -> tuple[int, bool]:
    return _heap_layers(tuple(int(v) for v in heights))


def heap_units(heights: Sequence[int]) -> tuple[Unit, ...]:
    """A compressor tree's units for these column heights, exactly as
       `compressor_RTL_gen` builds it: one GPC layer per compression layer the
       heuristic schedules (`merge_last_stage` already folded), then the
       terminal adder, priced as a plain two-operand add when no column
       reaching it is taller than two bits or when the generator's
       behavioural adder takes it (`terminal_add.quaternary_supported`).

       A heap no column of which is taller than two bits is refused, as the
       generator refuses it: it is a plain two-operand add (a constant
       multiplier's adder strategy, a DSP wrapper's flat merge), priced by
       `adder_units`."""
    h = tuple(int(v) for v in heights)
    if max(h, default=0) <= 2:
        raise ValueError(
            f"a heap no column of which is taller than two bits (max {max(h, default=0)}) "
            f"is a plain two-operand add, not a compressor tree: price it with adder_units()"
        )
    w = heap_width(h)
    layers, two = heap_layers(h)
    return (*(Unit('gpc', LOGIC_GPC, f'GPC layer {i}') for i in range(layers)),
            Unit('terminal', terminal_ns(w, two), f'terminal adder, {w} bits'))


def bmult_units(width_a: int, width_b: int) -> tuple[Unit, ...]:
    """A radix-4 Booth multiplier's units: partial-product generation, the
       compression layers of its heap, the terminal adder at the product width.
       Takes the widths the generator takes; the even-width normalisation and
       the operand swap are mirrored by `build_bmult_bitheap`."""
    from dsp_multiplier.common.lut_cost import build_bmult_bitheap
    pa, pb, heights = build_bmult_bitheap(width_a, width_b)
    layers, two = heap_layers(heights)
    return (Unit('ppgen', LOGIC_PPGEN, 'Booth partial products'),
            *(Unit('gpc', LOGIC_GPC, f'GPC layer {i}') for i in range(layers)),
            Unit('terminal', terminal_ns(pa + pb, two), f'terminal adder, {pa + pb} bits'))


def adder_units(width: int) -> tuple[Unit, ...]:
    """A plain two-operand adder (a constant multiplier's `adder` strategy)."""
    return (Unit('adder', terminal_ns(width, True), f'two-operand adder, {width} bits'),)


# ---------------------------------------------------------------- matrix transpose
#
# The streaming transposes in rtl/matrix_transpose/ (THEORY.md section 11):
# a radix-4 barrel shifter of LUT6 mux stages, BRAM banks, and per-lane
# address arithmetic. Calibrated on the V80 on 15 Sept 2026 from twelve
# implemented transposes and twenty shifters (DEBUG.md section 8c). Three of
# the paths grow with the design's size -- the select net of a mux stage
# fans out to every element bit, a BRAM read and an address travel further
# in a wider design -- so they are functions of the lane bits `n * w`, fitted
# on log2 of it over 1024..8192 and read as measured, not derived.
LOGIC_MUX4 = 0.10   # one LUT6 level of the shifter (measured 0.09-0.12 ns per level)
LOGIC_MUX2 = 0.10   # the 2:1 stage an odd depth ends with, the same LUT
_SIZE_MIN = 256     # the fits are over 1024..8192; below 256 they are clamped here, 256..1023 is an extrapolation taken as-is


def _log_size(n: int, w: int) -> float:
    from math import log2
    return log2(max(n * w, _SIZE_MIN))


def mux_select_route_ns(n: int, w: int) -> float:
    """The select net of a mux stage into its n*w LUTs: paid once per
       register-to-register segment of the shifter, on top of ENTRY. In
       context (inside a transpose) a single-level stage measured 1.65 ns at
       n*w = 1024 and 2.01 ns at 8192; this is that excess over
       ENTRY + LOGIC_MUX4 + EXIT."""
    return max(0.0, 0.12 * _log_size(n, w) - 0.32)


def bram_read_ns(n: int, w: int) -> float:
    """Replaces ENTRY on a segment a BRAM drives: its clock-to-out and the
       hop into the first LUT or flop (measured 1.53 ns at n*w = 1024 and
       1.91 at 8192; this fit gives 1.55 and 1.91)."""
    return 0.35 + 0.12 * _log_size(n, w)


def bram_addr_ns(n: int, w: int) -> float:
    """A whole segment: the counter's flop, the per-lane address arithmetic
       (one or two LUTs) and the BRAM's address setup (measured 1.16 ns at n*w = 1024
       and 1.67 at 8192; this fit gives 1.18 and 1.66)."""
    return max(0.0, 0.16 * _log_size(n, w) - 0.42)


def barrel_units(n: int, w: int | None = None) -> tuple[Unit, ...]:
    """The barrel shifter's mux stages, one unit each: ceil(log2 n / 2) of
       them, the last a 2:1 stage when log2 n is odd (`transpose_model`
       holds the geometry the RTL is built from). The units carry the LUT
       delay only; the select fan-out is a per-segment cost
       (`mux_select_route_ns`) added where a segment is priced."""
    from transpose_model import barrel_depth, barrel_stages
    d, stages = barrel_depth(n), barrel_stages(n)
    return tuple(Unit('mux4', LOGIC_MUX4, f'4:1 mux stage {s}') if 2 * s + 1 < d
                 else Unit('mux2', LOGIC_MUX2, f'2:1 mux stage {s}')
                 for s in range(stages))


def barrel_reg_flags(n: int, stages: int, w: int | None = None) -> list[bool]:
    """Register flags for the shifter, one per mux stage (`REG_FLAGS`). The
       units weigh the same, so this is the equal-count split."""
    return place_registers(weights(barrel_units(n)), stages)


def barrel_segments_ns(n: int, w: int, flags: Sequence[bool], *,
                       bram_driven: bool = False) -> float:
    """The slowest segment of a shifter over n elements of w bits with
       registers after the stages `flags` name: every segment pays the
       select fan-out once; the first segment of a shifter a BRAM feeds is
       also priced on its data path (BRAM_READ replacing ENTRY), and the
       worse of the two counts."""
    ws = weights(barrel_units(n))
    if len(ws) != len(flags):
        raise ValueError(f"{len(ws)} mux stages but {len(flags)} register flags")
    fan = mux_select_route_ns(n, w)
    worst = 0.0
    seg: list[float] = []
    first = True
    for i, (x, f) in enumerate(zip(ws, flags)):
        seg.append(x)
        if f or i == len(ws) - 1:
            body = sum(seg) + ROUTE_INTER * (len(seg) - 1)
            ns = ENTRY + fan + body + EXIT
            if first and bram_driven:
                ns = max(ns, bram_read_ns(n, w) + body + EXIT)
            worst = max(worst, ns)
            seg, first = [], False
    return worst


def transpose_paths(kind: str, n: int, w: int, flags: Sequence[bool]) -> list[tuple[str, float]]:
    """Every register-to-register path family of a transpose and its delay:
       the shifter(s) under their placement (the one a BRAM feeds priced
       with BRAM_READ as its entry), the per-lane address arithmetic, and,
       in mbm, the output bank's read into the consumer's flop."""
    from transpose_model import check_flags
    f = check_flags(n, flags)
    paths = []
    if kind == 'bmb':
        paths.append(('shifter 0 (flop-driven)', barrel_segments_ns(n, w, f)))
        paths.append(('shifter 1 (BRAM-driven)', barrel_segments_ns(n, w, f, bram_driven=True)))
    elif kind == 'mbm':
        paths.append(('shifter (BRAM-driven)', barrel_segments_ns(n, w, f, bram_driven=True)))
        paths.append(('output bank read', bram_read_ns(n, w) + EXIT))
    else:
        raise ValueError(f"kind must be 'bmb' or 'mbm', got {kind!r}")
    paths.append(('address arithmetic', bram_addr_ns(n, w)))
    return paths


def transpose_critical_ns(kind: str, n: int, w: int, flags: Sequence[bool]) -> tuple[float, str]:
    """The slowest path of a transpose and its name."""
    ns, name = max((ns, name) for name, ns in transpose_paths(kind, n, w, flags))
    return ns, name


def transpose_flags_for_fmax(kind: str, n: int, w: int, target_fmax_mhz: float, *,
                             label: str = '') -> tuple[bool, ...]:
    """The fewest shifter registers whose slowest path reaches the target,
       placed by `place_registers`; refused, naming the path, when a path no
       register can split sets the floor below the target."""
    if target_fmax_mhz <= 0:
        raise ValueError(f"{label or kind}: target_fmax_mhz must be > 0, got {target_fmax_mhz}")
    ws = weights(barrel_units(n))
    for stages in range(1, len(ws) + 1):
        flags = tuple(place_registers(ws, stages))
        ns, _ = transpose_critical_ns(kind, n, w, flags)
        if fmax_of(ns) >= target_fmax_mhz - 1e-9:
            return flags
    flags = tuple([True] * len(ws))
    ns, name = transpose_critical_ns(kind, n, w, flags)
    raise ValueError(
        f"{label or kind}: {target_fmax_mhz:.1f} MHz is unreachable: with a register "
        f"after every mux stage the floor is {fmax_of(ns):.1f} MHz ({ns:.3f} ns), set "
        f"by the {name}, which no register placement can split."
    )


# ---------------------------------------------------------------- placement
def segment_ns(weights: Sequence[float], flags: Sequence[bool]) -> float:
    """The slowest register-to-register segment of a block whose units carry
       `weights`, with a register after unit `i` wherever `flags[i]` is True.
       Trailing unregistered units end at the block's output; that segment is
       closed by the consumer's flop and priced with the same EXIT."""
    if len(weights) != len(flags):
        raise ValueError(f"{len(weights)} units but {len(flags)} register flags")
    worst = 0.0
    seg: list[float] = []
    for w, f in zip(weights, flags):
        seg.append(w)
        if f:
            worst = max(worst, sum(seg) + ROUTE_INTER * (len(seg) - 1))
            seg = []
    if seg:
        worst = max(worst, sum(seg) + ROUTE_INTER * (len(seg) - 1))
    return ENTRY + EXIT + worst


def even_split(stages: int, n: int) -> list[bool]:
    """`reg_flag_list_gen`'s rule: `n` units into `stages` equal-count groups,
       the remainder going to the first groups, a register at the end of each.
       `stages <= 0` is combinational (no register); `stages >= n` registers
       every unit."""
    flags = [False] * n
    if stages <= 0 or n == 0:
        return flags
    base, rem = divmod(n, stages)
    idx = 0
    for s in range(stages):
        idx += base + (1 if s < rem else 0)
        if idx:
            flags[idx - 1] = True
    return flags


def place_registers(weights: Sequence[float], stages: int) -> list[bool]:
    """Where `stages` registers go so that the slowest segment is shortest.

    Exhaustive over the C(n-1, stages-1) cut sets; `n` is the handful of units
    a block has, so this is instant. The equal-count split wins every tie, so a
    design it already served optimally is unchanged; otherwise the first
    strictly better cut set in lexicographic order is taken, which keeps the
    choice deterministic.
    """
    n = len(weights)
    if stages <= 0:
        return [False] * n
    if stages >= n:
        return [True] * n
    best = even_split(stages, n)
    best_ns = segment_ns(weights, best)
    for cuts in combinations(range(1, n), stages - 1):
        flags = [False] * n
        for c in cuts:
            flags[c - 1] = True
        flags[-1] = True
        ns = segment_ns(weights, flags)
        if ns < best_ns - 1e-9:
            best, best_ns = flags, ns
    return best


def segment_cost(weights: Sequence[float], stages: int) -> float:
    """The slowest segment (ns) with `stages` registers placed by
       `place_registers`."""
    return segment_ns(weights, place_registers(weights, stages))


def heap_reg_flags(heights: Sequence[int], stages: int) -> list[bool]:
    """Register flags for a compressor tree, one per unit (layers + terminal)."""
    return place_registers(weights(heap_units(heights)), stages)


def bmult_reg_flags(width_a: int, width_b: int, stages: int) -> list[bool]:
    """Register flags for a Booth multiplier, one per unit (ppgen + layers + terminal)."""
    return place_registers(weights(bmult_units(width_a, width_b)), stages)


# ---------------------------------------------------------------- frequency in, cycles out
@dataclass(frozen=True)
class CurvePoint:
    stages: int
    flags: tuple[bool, ...]
    ns: float
    fmax_mhz: float


def curve(units: Sequence[Unit]) -> list[CurvePoint]:
    """(stages, placement, slowest segment, MHz) for every stage count 1..n."""
    w = weights(units)
    out = []
    for L in range(1, len(w) + 1):
        flags = place_registers(w, L)
        ns = segment_ns(w, flags)
        out.append(CurvePoint(L, tuple(flags), ns, fmax_of(ns)))
    return out


def floor_unit(units: Sequence[Unit]) -> Unit:
    """The unit that bounds the block's frequency once every boundary is
       registered: the heaviest one."""
    return max(units, key=lambda u: u.ns)


def stages_for_fmax(units: Sequence[Unit], target_fmax_mhz: float, *,
                    max_stages: int | None = None, label: str = '') -> int:
    """The fewest pipeline stages that reach `target_fmax_mhz`.

    Raises when no stage count reaches it, naming the floor and the unit that
    sets it, and when `max_stages` is the binding constraint.
    """
    if target_fmax_mhz <= 0:
        raise ValueError(f"{label or 'block'}: target_fmax_mhz must be > 0, got {target_fmax_mhz}")
    if not units:
        raise ValueError(f"{label or 'block'}: no units to pipeline")
    pts = curve(units)
    for p in pts:
        if p.fmax_mhz >= target_fmax_mhz - 1e-9:
            if max_stages is not None and p.stages > max_stages:
                raise ValueError(
                    f"{label or 'block'}: {target_fmax_mhz:.1f} MHz needs {p.stages} "
                    f"stages ({p.fmax_mhz:.1f} MHz there), but at most {max_stages} "
                    f"were allowed. The stage cap is the binding constraint."
                )
            return p.stages
    best = min(pts, key=lambda p: p.ns)
    fu = floor_unit(units)
    raise ValueError(
        f"{label or 'block'}: {target_fmax_mhz:.1f} MHz is unreachable at any stage "
        f"count: the floor is {best.fmax_mhz:.1f} MHz ({best.ns:.3f} ns) at "
        f"{best.stages} stages, set by the {fu.note or fu.kind} ({fu.ns:.2f} ns) which "
        f"is one register boundary and cannot be split. Lower the target, or "
        f"narrow the block."
    )


def describe(units: Sequence[Unit], chosen: int | None = None) -> str:
    """A short report: the units, then one line per stage count with its
       placement and MHz, the chosen one marked."""
    lines = ["units: " + " | ".join(str(u) for u in units),
             f"{'stages':>6} {'ns':>7} {'MHz':>7}   registers after unit"]
    for p in curve(units):
        after = ",".join(str(i) for i, f in enumerate(p.flags) if f)
        mark = "  <- chosen" if chosen == p.stages else ""
        lines.append(f"{p.stages:>6} {p.ns:>7.3f} {p.fmax_mhz:>7.1f}   [{after}]{mark}")
    return "\n".join(lines)
