"""Butterfly RTL generator.

Consumes a `ButterflyOperatorSpec` (produced by
`operator_modeling.ntt.butterfly.ButterflyScheme.GoldilocksSlice64.getOperatorInterface`) and emits SystemVerilog
for one Goldilocks-NTT butterfly module: two compressor instances (one per
output, aOut and bOut) sharing the input registers `aIn` and `bIn`, with the
per-position twiddle baked in via limb-shifted slices of the inputs.

Output strategy: two independent bit-heaps with shared input wires. The two
compressors are `<spec.name>_aOut_cmp` and `<spec.name>_bOut_cmp`; the wrapper
routes the same `aIn`/`bIn` registers into both via fan-out (Bit metadata is
emitted with the same signal_name across both heaps).

When `gen_testbench=True`, the caller supplies the four `aIn` / `bIn` /
`aOut` / `bOut` testvector arrays as data; the generator just writes the hex
files and emits the self-checking testbench. The caller (typically
`operator_modeling.ntt.butterfly.ButterflyScheme.GoldilocksSlice64.emitRtl`) is responsible for sampling
inputs and computing goldens via `propagateValue`.
"""

from __future__ import annotations
import os

from butterfly_spec import ButterflyOperatorSpec, SliceTerm
from bitheap import BitHeap
from heuristic import compressAll, formGPCChain, merge_last_stage
from rtl_gen.compressor import compressor_RTL_gen
from rtl_gen.bit_polarity import PLAIN, INVERTED, ZERO, ONE
from rtl_gen.utils import tb_settle_delay
from dataclasses import dataclass
from rtl_gen.utils import width_expr, to_twos_complement_hex, merge_bit_assigns


# ---------------------------------------------------------------------------
# Step 2a — bit-heap descriptor builder
# ---------------------------------------------------------------------------

def _emit_term_bits(term: SliceTerm, raw_cols: list[list], N: int) -> int:
    """Place one SliceTerm's bits into raw_cols (mutated) and return its
    contribution to the integer `sign_ext` constant accumulator.

    Each non-const term is one of four cases:
      A. Unsigned slice (or signed slice truncated by N), sign=+1:
         straight placement of slice bits at columns k..k+W'-1.
      B. Unsigned slice (or truncated), sign=-1: Baugh-Wooley negation —
         complement bits, +1 at column k, sign-ext 1's at [k+W..N-1].
      C. Full signed slice (k+W-1 < N), sign=+1: A[0..W-2] normally;
         ~A[W-1] at column k+W-1; +1 at column k+W-1; 1's at [k+W..N-1].
      D. Full signed slice, sign=-1: ~A[0..W-2]; A[W-1] (no complement);
         +1 at column k; +1 at column k+W-1; 1's at [k+W..N-1].

    Const terms are folded directly into sign_ext as `sign * constValue * 2^k
    mod 2^N` — there is no per-bit emission since every bit of the constant
    is known at generation time, and lumping them all into one constant is
    cheaper than emitting individual `1'b1` bits per set bit of the constant.
    """
    k = term.limbShift
    if term.source == 'const':
        return term.sign * term.constValue * (1 << k)

    W = term.sliceEnd - term.sliceStart + 1
    if k >= N:
        return 0    # term shifts entirely past the heap MSB
    W_eff = min(W, N - k)
    truncated = W_eff < W

    def slice_bit(i: int):
        """Source bit feeding slice position i (i in 0..W_eff-1).

        Returns (signal_name, signal_index) for an actual register bit, or
        None if this position is a guaranteed-zero LSB: introduced by the input
        shift, or a low bit the source's own bound says is zero.
        """
        p = term.sliceStart + i
        src_bit_pos = p - term.inputShift
        if src_bit_pos < term.sourceZeroLsbs:
            return None
        return (term.source, src_bit_pos)

    sign_ext_delta = 0

    if truncated or not term.isSigned:
        # Cases A / B (unsigned, or truncated-signed which collapses to unsigned)
        if term.sign == 1:
            for i in range(W_eff):
                src = slice_bit(i)
                if src is None:
                    continue
                raw_cols[k + i].append((src[0], src[1], False, False))
        else:
            for i in range(W_eff):
                src = slice_bit(i)
                if src is None:
                    # ~0 = constant 1
                    sign_ext_delta += 1 << (k + i)
                else:
                    raw_cols[k + i].append((src[0], src[1], True, False))
            sign_ext_delta += (1 << k)
            if not truncated:
                for col in range(k + W, N):
                    sign_ext_delta += (1 << col)
    else:
        # Cases C / D (full-width signed slice)
        msb = W - 1
        if term.sign == 1:
            for i in range(msb):
                src = slice_bit(i)
                if src is None:
                    continue
                raw_cols[k + i].append((src[0], src[1], False, False))
            src = slice_bit(msb)
            if src is None:
                sign_ext_delta += 1 << (k + msb)
            else:
                raw_cols[k + msb].append((src[0], src[1], True, False))
            sign_ext_delta += (1 << (k + msb))
            for col in range(k + W, N):
                sign_ext_delta += (1 << col)
        else:
            for i in range(msb):
                src = slice_bit(i)
                if src is None:
                    sign_ext_delta += 1 << (k + i)
                else:
                    raw_cols[k + i].append((src[0], src[1], True, False))
            src = slice_bit(msb)
            if src is not None:
                raw_cols[k + msb].append((src[0], src[1], False, False))
            sign_ext_delta += (1 << k)
            sign_ext_delta += (1 << (k + msb))
            for col in range(k + W, N):
                sign_ext_delta += (1 << col)

    return sign_ext_delta


def _build_heap_descriptors(terms: list[SliceTerm], output_width: int, col_prefix: str):
    """Build bit-heap descriptors for one output's term list.

    Returns (compressor_desc, assign_desc, bitheap_list, width_bh) where:

    - compressor_desc: list of [col_idx, (port_name, bit_idx_or_None), ...]
      passed to compressor_RTL_gen for column-port-name derivation. Each
      column gets one prefixed port name, e.g. "aOut_col5".

    - assign_desc: same shape as compressor_desc but each tuple is
      (signal_name, signal_index, complemented, is_constant) describing the
      actual register bit (or constant) that drives this column position.
      Used by the wrapper to emit `assign aOut_col5[2] = aIn[37];` style.

    - bitheap_list: per-column heights — input to the compressor pipeline.

    - width_bh: bit-width of the worst-case heap sum = compressor's output
      width. The wrapper truncates `comp_out[output_width-1:0]` to recover
      the predicted N-bit value.
    """
    N = output_width
    raw_cols: list[list] = [[] for _ in range(N)]
    sign_ext = 0

    for term in terms:
        sign_ext += _emit_term_bits(term, raw_cols, N)

    # Fold all accumulated constants (sign-extension corrections + Baugh-Wooley
    # +1's + the const-term mod-q value) into the heap as 1'b1 bits at each
    # set position of (sign_ext mod 2^N). Anything above 2^N is discarded —
    # the wrapper's `assign aOut = comp_out[N-1:0]` truncation makes those
    # high-order constants irrelevant.
    sign_ext = sign_ext % (1 << N)
    for i in range(N):
        if (sign_ext >> i) & 1:
            raw_cols[i].append((None, None, False, True))

    compressor_desc: list = []
    assign_desc: list = []
    for col_idx in range(N):
        bits = raw_cols[col_idx]
        if not bits:
            continue
        n_bits = len(bits)
        col_port = f"{col_prefix}col{col_idx}"
        comp_entry = [col_idx]
        for bit_idx in range(n_bits):
            comp_entry.append((col_port, bit_idx if n_bits > 1 else None))
        compressor_desc.append(comp_entry)
        assign_desc.append([col_idx] + bits)

    if not compressor_desc:
        return [], [], [], 0

    # The compressor pipeline's two-operand and terminal-adder loops assume
    # >=1 bit per column in the [first..last] range. Pad empty middle columns
    # with a 1'b0 filler so they exist (mirrors the same pad in const_mult.py).
    populated = {entry[0] for entry in compressor_desc}
    first_col = min(populated)
    last_col = max(populated)
    bitheap_list = [0] * (last_col + 1)
    for entry in compressor_desc:
        bitheap_list[entry[0]] = len(entry) - 1

    for col_idx in range(first_col, last_col + 1):
        if col_idx in populated:
            continue
        col_port = f"{col_prefix}col{col_idx}"
        compressor_desc.append([col_idx, (col_port, None)])
        assign_desc.append([col_idx, (None, None, False, False)])
        bitheap_list[col_idx] = 1

    compressor_desc.sort(key=lambda e: e[0])
    assign_desc.sort(key=lambda e: e[0])

    sum_max = sum(bitheap_list[col] * (2 ** col) for col in range(len(bitheap_list)))
    width_bh = sum_max.bit_length()

    return compressor_desc, assign_desc, bitheap_list, width_bh


# ---------------------------------------------------------------------------
# Step 2b — per-output compressor generation
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class OutputStagePlan:
    """One butterfly output's compressor: its heap, its units, and where the
    registers go for the stage count chosen."""
    label: str
    compressor_desc: list
    assign_desc: list
    bitheap_list: list
    width_bh: int
    units: tuple
    stages: int                 # registers actually placed (<= units)
    flags: tuple                # register after unit i
    worst_ns: float             # slowest register-to-register segment
    fmax_mhz: float


@dataclass(frozen=True)
class ButterflyStagePlan:
    aOut: OutputStagePlan
    bOut: OutputStagePlan
    latency: int                # the wrapper's latency: the deeper output
    target_fmax_mhz: float | None


def _keep_compressible(compressor_desc: list, assign_desc: list, bitheap_list: list,
                       col_prefix: str) -> None:
    """Keep a heap tall enough for the compressor, in place.

    Folding the constants can leave a butterfly's heap no taller than two bits,
    which the compressor refuses as a plain add. A butterfly has one pipeline
    built on the compressor, so its tallest column is padded to three with tied
    zeros instead of growing a second adder path.
    """
    tallest = max(bitheap_list)
    if tallest >= 3:
        return
    col = bitheap_list.index(tallest)
    pad = 3 - tallest
    bitheap_list[col] = 3
    for entry in compressor_desc:
        if entry[0] == col:
            entry[1:] = [(f"{col_prefix}col{col}", i) for i in range(3)]
    for entry in assign_desc:
        if entry[0] == col:
            entry.extend([(None, None, False, False)] * pad)


def butterfly_stage_plan(spec: ButterflyOperatorSpec, pipeline_stages: int = 1,
                         target_fmax_mhz: float | None = None) -> ButterflyStagePlan:
    """Decide the pipelining of both compressors of one butterfly, from the
    spec alone. This is the single place the decision is made: the hardware
    generator builds it, the sim backend copies its latency, and the model's
    `GoldilocksSlice64.latency` reports it.

    Each output's heap is a chain of units (`lut_timing.heap_units`) and takes
    `pipeline_stages` registers placed by delay, capped at its unit count. With
    `target_fmax_mhz` each output instead takes the fewest stages that reach
    the target. The wrapper's latency is the deeper of the two; the shallower
    output gets balancing registers in the wrapper.
    """
    from lut_timing import (heap_units, place_registers, weights, segment_ns,
                            fmax_of, stages_for_fmax)
    outs = []
    for label, terms, width in (("aOut", spec.aOutTerms, spec.aOutBitWidth),
                                ("bOut", spec.bOutTerms, spec.bOutBitWidth)):
        compressor_desc, assign_desc, bitheap_list, width_bh = _build_heap_descriptors(
            terms, width, f"{label}_"
        )
        if not bitheap_list:
            raise ValueError(
                f"{spec.name} {label} bit-heap is empty — every term was truncated. "
                f"Check that {label}BitWidth in the spec is non-zero."
            )
        _keep_compressible(compressor_desc, assign_desc, bitheap_list, f"{label}_")
        width_bh = sum(h << col for col, h in enumerate(bitheap_list)).bit_length()
        units = heap_units(bitheap_list)
        stages = pipeline_stages
        if target_fmax_mhz is not None:
            stages = stages_for_fmax(units, target_fmax_mhz, label=f"{spec.name} {label}")
        flags = place_registers(weights(units), stages)
        ns = segment_ns(weights(units), flags)
        outs.append(OutputStagePlan(label, compressor_desc, assign_desc, bitheap_list,
                                    width_bh, units, sum(flags), tuple(flags), ns,
                                    fmax_of(ns)))
    a, b = outs
    return ButterflyStagePlan(a, b, max(a.stages, b.stages), target_fmax_mhz)


def _input_kinds(assign_desc: list) -> dict[int, list[str]]:
    """Each heap bit's kind, for `rtl_gen.bit_polarity.push_polarity`."""
    def kind(bit) -> str:
        sig_name, _, neg, cnst = bit
        if cnst:
            return ONE
        if sig_name is None:
            return ZERO
        return INVERTED if neg else PLAIN
    return {entry[0]: [kind(bit) for bit in entry[1:]] for entry in assign_desc}


def _gen_butterfly_compressor(spec: ButterflyOperatorSpec,
                              plan: OutputStagePlan,
                              visualization: bool):
    """Generate one output's compressor module via compressor_RTL_gen, at the
    register placement `butterfly_stage_plan` decided for it.

    Returns a tuple (compressor_module_name, compressor_desc, assign_desc,
    bitheap_list, width_bh, comp_pipeline_stages) used by the wrapper.
    """
    output_label = plan.label
    compressor_desc, assign_desc = plan.compressor_desc, plan.assign_desc
    bitheap_list, width_bh = plan.bitheap_list, plan.width_bh

    compressor_module_name = f"{spec.name}_{output_label}_cmp"

    # Cross-check: the unit count lut_timing placed registers over must be the
    # layer count this generator will emit. Both run the same heuristic on the
    # same heights; a disagreement is a bug, not something to paper over.
    bh_layer_cal = BitHeap(width_bh, 0)
    for col in range(len(bitheap_list)):
        bh_layer_cal.add_bits(col, bitheap_list[col])
    last_bh, raw_cl = compressAll(bh_layer_cal, 0, width_bh - 1, False, False)
    cl_formed = formGPCChain(raw_cl)
    n_layers = len(cl_formed)
    if n_layers >= 2:
        mf, _ = merge_last_stage(
            last_compression_layer_counter_list=cl_formed[-1],
            last_compression_layer_bitheap=last_bh,
        )
    else:
        mf = False
    if mf:
        n_layers -= 1
    n_layers += 1   # +1 for the terminal-addition layer
    reg_flag_list = list(plan.flags)
    if len(reg_flag_list) != n_layers:
        raise AssertionError(
            f"{compressor_module_name}: lut_timing sees {len(reg_flag_list)} units but the "
            f"generator will emit {n_layers}; the two heap analyses disagree"
        )

    # The compressor expects the column heights as a text file; write per-output
    # distinct paths so the two compressors don't clobber each other's input.
    heap_txt = f"{spec.name}_{output_label}_bitheap.txt"
    with open(heap_txt, "w", encoding="utf-8") as f:
        for v in bitheap_list:
            f.write(f"{v}\n")

    # If visualization is on, both compressor calls would write to the same
    # bitheap_visualization/{original_bitheap, after_layer_*}.png paths. Snapshot
    # the PNGs that exist BEFORE this call so we can rename only the new ones
    # (i.e. the ones produced by THIS compressor) afterwards. Pre-existing PNGs
    # from prior runs or the other output's call are left alone.
    viz_dir = "bitheap_visualization"
    pre_run_pngs: set[str] = set()
    if visualization and os.path.isdir(viz_dir):
        pre_run_pngs = {f for f in os.listdir(viz_dir) if f.endswith(".png")}

    compressor_RTL_gen(
        txt_file_name=heap_txt,
        sv_file_name=compressor_module_name,
        compressor_module_name=compressor_module_name,
        tb_out_width=spec.aOutBitWidth if output_label == "aOut" else spec.bOutBitWidth,
        reg_flag_list=reg_flag_list,
        visualization=visualization,
        gen_testbench=False,
        test_size=0,
        bitheap_desc=compressor_desc,
        input_kinds=_input_kinds(assign_desc),
    )

    if visualization and os.path.isdir(viz_dir):
        for fname in os.listdir(viz_dir):
            if not fname.endswith(".png") or fname in pre_run_pngs:
                continue
            if fname.startswith(f"{output_label}_"):
                continue   # already-prefixed, idempotent on re-runs
            os.replace(os.path.join(viz_dir, fname),
                       os.path.join(viz_dir, f"{output_label}_{fname}"))

    comp_pipeline_stages = sum(1 for v in reg_flag_list if v)
    return (compressor_module_name, compressor_desc, assign_desc,
            bitheap_list, width_bh, comp_pipeline_stages)


# ---------------------------------------------------------------------------
# Step 2c — wrapper SystemVerilog
# ---------------------------------------------------------------------------

def _bit_assign(lhs: str, sig_name, sig_index, neg: bool, cnst: bool,
                pushed: bool = False) -> str:
    """One-line assign for a column bit. Mirrors the per-bit RHS expression
    helper inlined in const_mult.py's wrapper generator. With `pushed`, the
    compressor's LUTs apply the inversion: the wire carries the plain source
    bit, or a tied 0 for a constant one."""
    if pushed:
        neg = False
        if cnst:
            sig_name, cnst = None, False
    if cnst:
        return f"    assign {lhs} = 1'b1;\n"
    if sig_name is None:
        return f"    assign {lhs} = 1'b0;\n"
    idx = "" if (sig_index is None or sig_index == -1) else f"[{sig_index}]"
    if neg:
        return f"    assign {lhs} = ~{sig_name}{idx};\n"
    return f"    assign {lhs} = {sig_name}{idx};\n"


def _gen_butterfly_wrapper(spec: ButterflyOperatorSpec,
                           aOut_info, bOut_info, latency: int | None = None) -> str:
    """Build the wrapper SV string. Two compressors are instantiated and the
    same `aIn` and `bIn` registers feed both via fan-out at the column-wire
    level. When one compressor is shallower than `latency` (the deeper one's
    depth, by default), its output gets balancing registers so both outputs
    leave together."""
    a_in_w = spec.aInBitWidth
    b_in_w = spec.bInBitWidth
    a_out_w = spec.aOutBitWidth
    b_out_w = spec.bOutBitWidth

    aOut_module, aOut_compressor_desc, aOut_assign_desc, _, aOut_width_bh, aOut_stages = aOut_info
    bOut_module, bOut_compressor_desc, bOut_assign_desc, _, bOut_width_bh, bOut_stages = bOut_info

    # Uniform left-padding width so port declarations line up like in Cmult/Bmult.
    bracket_widths = [a_in_w - 1, b_in_w - 1, a_out_w - 1, b_out_w - 1,
                      aOut_width_bh - 1, bOut_width_bh - 1]
    left_w = max(len(str(v)) for v in bracket_widths if v >= 0)

    rtl = f"""`timescale 1ns / 1ps

// Goldilocks butterfly: type={spec.butterflyType}, twiddle NAF = {spec.liftedTwiddleNaf}
// aIn:  {'signed' if spec.aInIsSigned else 'unsigned'} {a_in_w}-bit
// bIn:  {'signed' if spec.bInIsSigned else 'unsigned'} {b_in_w}-bit
// aOut: {'signed' if spec.aOutIsSigned else 'unsigned'} {a_out_w}-bit  (compressor pipeline stages: {aOut_stages})
// bOut: {'signed' if spec.bOutIsSigned else 'unsigned'} {b_out_w}-bit  (compressor pipeline stages: {bOut_stages})
module {spec.name} (
    input  logic {width_expr(0, left_w):<{left_w+6}} clk,
    input  logic {width_expr(a_in_w - 1, left_w):<{left_w+6}} aIn,
    input  logic {width_expr(b_in_w - 1, left_w):<{left_w+6}} bIn,
    output logic {width_expr(a_out_w - 1, left_w):<{left_w+6}} aOut,
    output logic {width_expr(b_out_w - 1, left_w):<{left_w+6}} bOut
    );

    logic {width_expr(aOut_width_bh - 1, left_w):<{left_w+6}} aOut_comp_out;
    logic {width_expr(bOut_width_bh - 1, left_w):<{left_w+6}} bOut_comp_out;
"""

    # Per-output column wires (one wire per populated column, with the
    # appropriate width if more than one bit accumulates at that column).
    for label, comp_desc in (('aOut', aOut_compressor_desc), ('bOut', bOut_compressor_desc)):
        rtl += f"\n    // ---- {label} bit-heap column wires ----\n"
        for entry in comp_desc:
            col_idx = entry[0]
            n_bits = len(entry) - 1
            cname = f"{label}_col{col_idx}"
            if n_bits == 1:
                rtl += f"    logic {' ' * (left_w + 6)} {cname};\n"
            else:
                rtl += f"    logic {width_expr(n_bits - 1, left_w):<{left_w+6}} {cname};\n"

    # Per-bit assigns from aIn/bIn (and constants).
    for label, assign_desc in (('aOut', aOut_assign_desc), ('bOut', bOut_assign_desc)):
        rtl += f"\n    // ---- {label} bit-heap input assignments ----\n"
        for entry in assign_desc:
            col_idx = entry[0]
            cname = f"{label}_col{col_idx}"
            bits = entry[1:]
            for bit_idx, (sig_name, sig_index, neg, cnst) in enumerate(bits):
                lhs = cname if len(bits) == 1 else f"{cname}[{bit_idx}]"
                rtl += _bit_assign(lhs, sig_name, sig_index, neg, cnst, pushed=True)

    # Compressor instances. The compressor's port names match the column wire
    # names (set via bitheap_desc's signal_name field when generating it), so
    # the connect list is just .col<i>(col<i>) per populated column.
    for label, comp_desc, comp_module_name in (
        ('aOut', aOut_compressor_desc, aOut_module),
        ('bOut', bOut_compressor_desc, bOut_module),
    ):
        rtl += f"\n    // ---- {label} compressor ----\n"
        rtl += f"    {comp_module_name} {comp_module_name}_inst (\n"
        rtl += f"        .clk(clk)"
        for entry in comp_desc:
            col_idx = entry[0]
            cname = f"{label}_col{col_idx}"
            rtl += f",\n        .{cname}({cname})"
        rtl += f",\n        .comp_out({label}_comp_out));\n"

    if latency is None:
        latency = max(aOut_stages, bOut_stages)
    sources = {}
    for label, stages, width_bh in (('aOut', aOut_stages, aOut_width_bh),
                                    ('bOut', bOut_stages, bOut_width_bh)):
        extra = latency - stages
        if extra < 0:
            raise ValueError(f"{spec.name}: {label} has {stages} stages, above the wrapper latency {latency}")
        src = f"{label}_comp_out"
        if extra > 0:
            rtl += f"\n    // ---- {label} balancing: {extra} extra register stage(s) to match the deeper output ----\n"
            for k in range(1, extra + 1):
                rtl += f"    logic {width_expr(width_bh - 1, left_w):<{left_w+6}} {label}_bal_d{k};\n"
            rtl += "    always_ff @(posedge clk) begin\n"
            prev = src
            for k in range(1, extra + 1):
                rtl += f"        {label}_bal_d{k} <= {prev};\n"
                prev = f"{label}_bal_d{k}"
            rtl += "    end\n"
            src = prev
        sources[label] = src

    rtl += f"""
    // ---- Output truncation to bound bit-width ----
    assign aOut = {sources['aOut']}[{a_out_w - 1}:0];
    assign bOut = {sources['bOut']}[{b_out_w - 1}:0];

endmodule
"""
    return merge_bit_assigns(rtl)


# ---------------------------------------------------------------------------
# Step 3 — testvectors + self-checking testbench
# ---------------------------------------------------------------------------

def _write_hex_file(path: str, values: list[int], bit_width: int) -> None:
    """One hex value per line, two's-complement-encoded at `bit_width`. Negative
    Python ints turn into the corresponding bit pattern; matches what the RTL
    output port `[bit_width-1:0]` produces after `assign aOut = comp_out[N-1:0]`
    truncation, so $readmemh into a `logic [N-1:0]` array compares equal."""
    with open(path, "w", encoding="utf-8") as f:
        for v in values:
            f.write(f"{to_twos_complement_hex(v, bit_width)}\n")


def _write_butterfly_testvectors(
    spec: ButterflyOperatorSpec,
    aIn: list[int], bIn: list[int],
    aOut: list[int], bOut: list[int],
) -> None:
    """Write the four hex testvector files. Caller is responsible for both inputs
    and goldens — the generator does not sample. Lengths must agree."""
    sizes = (len(aIn), len(bIn), len(aOut), len(bOut))
    if len(set(sizes)) != 1:
        raise ValueError(
            f"aIn/bIn/aOut/bOut must all have the same length, got {sizes}"
        )

    folder = "testvectors"
    os.makedirs(folder, exist_ok=True)
    _write_hex_file(os.path.join(folder, "aIn.txt"),  aIn,  spec.aInBitWidth)
    _write_hex_file(os.path.join(folder, "bIn.txt"),  bIn,  spec.bInBitWidth)
    _write_hex_file(os.path.join(folder, "aOut.txt"), aOut, spec.aOutBitWidth)
    _write_hex_file(os.path.join(folder, "bOut.txt"), bOut, spec.bOutBitWidth)


def _gen_butterfly_testbench(spec: ButterflyOperatorSpec,
                             pipeline_latency: int,
                             test_size: int) -> str:
    """Build the self-checking testbench string. Path convention matches Cmult:
    `$readmemh("../../../../../testvectors/<file>.txt", ...)` (5 levels up from
    `RTL_generated/`). `scripts/run_remote_sim.py` rewrites these paths to
    `../testvectors/` for the server build directory.

    The pass/fail markers mirror Cmult exactly (`SUCCESS!`, `PASS All`,
    `TO BE DEBUGGED...`, `FAILED:`) so the existing remote-sim verdict grep
    picks them up unchanged."""
    a_in_w  = spec.aInBitWidth
    b_in_w  = spec.bInBitWidth
    a_out_w = spec.aOutBitWidth
    b_out_w = spec.bOutBitWidth

    tb = f"""`timescale 1ns / 1ps

// Self-checking testbench for {spec.name}.
// Drives random aIn/bIn vectors and compares aOut/bOut against the unreduced
// goldens computed by GoldilocksSlice64.propagateValue (mod 2^N truncation
// happens at the wrapper's `assign aOut = comp_out[N-1:0]`).
// Pipeline latency: {pipeline_latency} cycle(s).
module {spec.name}_tb ();
    `define CLK_P         10
    `define CLK_HP        5
    `define TS_SIZE       {test_size}
    `define INIT_RESET    200

    logic clk;
    initial clk = 1'b0;
    always #`CLK_HP clk = ~clk;

    logic [{a_in_w - 1}:0] aIn;
    logic [{b_in_w - 1}:0] bIn;
    logic [{a_out_w - 1}:0] aOut;
    logic [{b_out_w - 1}:0] bOut;
    logic [{a_in_w - 1}:0]  aIn_ts  [`TS_SIZE-1:0];
    logic [{b_in_w - 1}:0]  bIn_ts  [`TS_SIZE-1:0];
    logic [{a_out_w - 1}:0] aOut_ts [`TS_SIZE-1:0];
    logic [{b_out_w - 1}:0] bOut_ts [`TS_SIZE-1:0];

    initial begin
        $readmemh("../../../../../testvectors/aIn.txt",  aIn_ts );
        $readmemh("../../../../../testvectors/bIn.txt",  bIn_ts );
        $readmemh("../../../../../testvectors/aOut.txt", aOut_ts);
        $readmemh("../../../../../testvectors/bOut.txt", bOut_ts);
    end

    {spec.name} DUT (
        .clk (clk ),
        .aIn (aIn ),
        .bIn (bIn ),
        .aOut(aOut),
        .bOut(bOut));

    int i;
    initial begin
        #`INIT_RESET;
        #`CLK_HP;
        #1;
        for (i = 0; i < `TS_SIZE; i = i + 1) begin
            aIn = aIn_ts[i];
            bIn = bIn_ts[i];
            #`CLK_P;
        end
    end

    int j;
    int correct_cnt;
    initial begin
        correct_cnt = 0;
        #`INIT_RESET;
        #`CLK_HP;
        #(`CLK_P*{pipeline_latency});
        #{tb_settle_delay(pipeline_latency)};
        for (j = 0; j < `TS_SIZE; j = j + 1) begin
            if (aOut == aOut_ts[j] && bOut == bOut_ts[j]) begin
                $display("Testvector-%d CORRECT!", j);
                correct_cnt = correct_cnt + 1;
            end else begin
                $display("=================================================================================");
                $display("Testvector-%d WRONG", j);
                if (aOut !== aOut_ts[j]) begin
                    $display("aOut module    output: %h", aOut);
                    $display("aOut reference output: %h", aOut_ts[j]);
                end
                if (bOut !== bOut_ts[j]) begin
                    $display("bOut module    output: %h", bOut);
                    $display("bOut reference output: %h", bOut_ts[j]);
                end
                $display("=================================================================================");
            end
            #`CLK_P;
        end
        if (correct_cnt == `TS_SIZE) begin
            $display("SUCCESS!");
            $display("PASS All %d Testvectors!", `TS_SIZE);
        end else begin
            $display("TO BE DEBUGGED...");
            $display("FAILED: %d out of %d testvectors failed", (`TS_SIZE-correct_cnt), `TS_SIZE);
        end
        $finish();
    end

endmodule
"""
    return tb


# ---------------------------------------------------------------------------
# Step 2d — public API
# ---------------------------------------------------------------------------

def is_datapath_butterfly(spec) -> bool:
    """A `DatapathButterflySpec` (any-q butterfly from the modular operators)
    rather than a Goldilocks `ButterflyOperatorSpec`."""
    return getattr(spec, "kind", None) == "datapath"


_DP_PORT = {"A": "aIn", "B": "bIn", "X": "aOut", "Y": "bOut"}


def _gen_datapath_butterfly_testbench(spec, latency: int, test_size: int) -> str:
    """The datapath generator's testbench, on the butterfly's port names:
    `aIn`, `bIn`, every extra input (W, WP, Q, ...), `aOut`, `bOut`; one
    vector file per port, same paths and verdict strings."""
    from types import SimpleNamespace
    from rtl_gen.datapath import _gen_testbench
    dp = spec.datapath
    ins = [SimpleNamespace(name=_DP_PORT.get(w.name, w.name), bitWidth=w.bitWidth) for w in dp.inputs]
    widths = {"aOut": spec.aOutBitWidth, "bOut": spec.bOutBitWidth}
    view = SimpleNamespace(name=spec.name, latency=latency, inputs=ins,
                           outputs=[("aOut", "aOut"), ("bOut", "bOut")],
                           wire=lambda w: SimpleNamespace(bitWidth=widths[w]))
    return _gen_testbench(view, test_size)


def _datapath_butterfly_RTL_gen(spec, gen_testbench, aIn, bIn, aOut, bOut, ports=None) -> dict:
    """`spec.datapath` as `<name>_dp` (rtl_gen.datapath, its dsp / booth
    multipliers imported from `spec.submodules`) and `<name>`, the butterfly
    ports (`clk`, `aIn`, `bIn`, `aOut`, `bOut`) around it; the testbench and
    test vectors are the Goldilocks butterfly's. No per-compressor XDC
    (`rtl/scoped_gpc_xdc.tcl` is the rule for a whole design)."""
    from rtl_gen.datapath import Datapath_RTL_gen
    dp = spec.datapath
    info = Datapath_RTL_gen(spec=dp, gen_testbench=False, submodules=spec.submodules, write_xdc=False)
    if os.path.isfile("manifest.json"):
        os.remove("manifest.json")      # the datapath's own; a caller writes its manifest
    ins = {w.name: w.bitWidth for w in dp.inputs}
    outs = {p: dp.wire(w).bitWidth for p, w in dp.outputs}
    want = {"A": spec.aInBitWidth, "B": spec.bInBitWidth, **dict(spec.extraPorts)}
    if ins != want or outs != {"X": spec.aOutBitWidth, "Y": spec.bOutBitWidth}:
        raise AssertionError(f"{spec.name}: datapath ports {ins} -> {outs} do not match the butterfly's {want}")
    extra_decl = [f"    input  logic [{w - 1}:0] {n}," for n, w in spec.extraPorts]
    extra_conn = "".join(f", .{n}({n})" for n, _ in spec.extraPorts)
    lines = [
        "`timescale 1ns / 1ps",
        "",
        f"// {spec.name}: {spec.butterflyType} butterfly mod q = {spec.q}, the datapath {dp.name} "
        f"(modular multiplier + modular adder/subtractor); latency {dp.latency}",
        f"module {spec.name} (",
        "    input  logic clk,",
        f"    input  logic [{spec.aInBitWidth - 1}:0] aIn,",
        f"    input  logic [{spec.bInBitWidth - 1}:0] bIn,",
        *extra_decl,
        f"    output logic [{spec.aOutBitWidth - 1}:0] aOut,",
        f"    output logic [{spec.bOutBitWidth - 1}:0] bOut",
        "    );",
        f"    {dp.name} {dp.name}_inst (.clk(clk), .A(aIn), .B(bIn){extra_conn}, .X(aOut), .Y(bOut));",
        "endmodule",
        "",
    ]
    folder = "RTL_generated"
    with open(os.path.join(folder, f"{spec.name}.sv"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    latency = info["pipeline_latency"]
    if gen_testbench:
        if aIn is None or bIn is None or aOut is None or bOut is None:
            raise ValueError("Butterfly_RTL_gen: aIn / bIn / aOut / bOut are all required when gen_testbench=True")
        _write_butterfly_testvectors(spec, aIn, bIn, aOut, bOut)
        for n, w in spec.extraPorts:
            if not ports or n not in ports or len(ports[n]) != len(aIn):
                raise ValueError(f"Butterfly_RTL_gen: values for input {n} ({len(aIn)} of them) are required")
            _write_hex_file(os.path.join("testvectors", f"{n}.txt"), ports[n], w)
        with open(os.path.join(folder, f"{spec.name}_tb.sv"), "w", encoding="utf-8") as f:
            f.write(_gen_datapath_butterfly_testbench(spec, latency, len(aIn)))
    return {
        "wrapper_module": spec.name,
        "datapath_module": dp.name,
        "pipeline_latency": latency,
        "target_fmax_mhz": dp.targetFmaxMhz,
        "predicted_worst_ns": spec.datapath.params.get("estimate", {}).get("criticalPathNs"),
    }


def Butterfly_RTL_gen(
    spec: ButterflyOperatorSpec,
    pipeline_stages: int = 1,
    gen_testbench: bool = True,
    visualization: bool = False,
    aIn: list[int] | None = None,
    bIn: list[int] | None = None,
    aOut: list[int] | None = None,
    bOut: list[int] | None = None,
    target_fmax_mhz: float | None = None,
    ports: dict | None = None,
) -> dict:
    """Emit SystemVerilog for one Goldilocks butterfly module.

    Pipelining is decided by `butterfly_stage_plan`: `pipeline_stages` registers
    per compressor, placed by delay and capped at that compressor's unit count,
    or with `target_fmax_mhz` the fewest stages per compressor that reach the
    target. `0` is combinational. The wrapper balances the shallower output to
    the deeper one, and `pipeline_latency` in the returned dict is what the
    testbench waits.

    Files written (relative to cwd, mirroring Cmult's layout):
        RTL_generated/<spec.name>.sv               wrapper
        RTL_generated/<spec.name>_aOut_cmp.sv      aOut compressor
        RTL_generated/<spec.name>_bOut_cmp.sv      bOut compressor
        RTL_generated/<spec.name>_tb.sv            self-checking testbench (when gen_testbench)
        xdc_generated/<spec.name>_aOut_cmp.xdc     aOut placement
        xdc_generated/<spec.name>_bOut_cmp.xdc     bOut placement
        testvectors/{aIn,bIn,aOut,bOut}.txt        hex testvectors (when gen_testbench)
        bitheap_visualization/{aOut,bOut}_*.png    per-output PNGs (when visualization)
        <spec.name>_{aOut,bOut}_bitheap.txt        column heights (input to compressor)

    When `gen_testbench=True`, all four `aIn` / `bIn` / `aOut` / `bOut` arrays
    are required. Caller is responsible for both inputs and goldens — typically
    `GoldilocksSlice64.emitRtl` (or a per-scenario harness) draws random
    inputs and runs `propagateValue` for the unreduced goldens. The generator
    itself does not sample.

    `test_size` is implicit — equals `len(aIn)` (= len(bIn) = len(aOut) = len(bOut)).

    Returns a metadata dict (module names, per-output pipeline stages,
    compressor output widths, pipeline latency).

    A `DatapathButterflySpec` (`is_datapath_butterfly`) is already scheduled:
    `pipeline_stages` and `target_fmax_mhz` are then unused, and the files are
    the wrapper, `<name>_dp`, its compressors and imported multipliers. Its
    extra inputs (`spec.extraPorts`: twiddle W / WP, modulus Q / MU / QP / QH /
    K / C) are wrapper ports under their own names, with values in `ports`.
    """
    if is_datapath_butterfly(spec):
        return _datapath_butterfly_RTL_gen(spec, gen_testbench, aIn, bIn, aOut, bOut, ports)
    plan = butterfly_stage_plan(spec, pipeline_stages, target_fmax_mhz)
    aOut_info = _gen_butterfly_compressor(spec, plan.aOut, visualization=visualization)
    bOut_info = _gen_butterfly_compressor(spec, plan.bOut, visualization=visualization)

    rtl = _gen_butterfly_wrapper(spec, aOut_info, bOut_info, latency=plan.latency)
    folder = "RTL_generated"
    os.makedirs(folder, exist_ok=True)
    with open(os.path.join(folder, f"{spec.name}.sv"), "w", encoding="utf-8") as f:
        f.write(rtl)

    # Pipeline latency is the deeper of the two compressors; the wrapper balanced
    # the other one up to it. Zero is a real answer: a combinational butterfly.
    pipeline_latency = plan.latency
    if pipeline_latency != max(aOut_info[5], bOut_info[5]):
        raise AssertionError(f"{spec.name}: planned latency {pipeline_latency} but built "
                             f"{aOut_info[5]}/{bOut_info[5]}")

    if gen_testbench:
        if aIn is None or bIn is None or aOut is None or bOut is None:
            raise ValueError(
                "Butterfly_RTL_gen: aIn / bIn / aOut / bOut are all required when "
                "gen_testbench=True. Sample inputs and run propagateValue in the "
                "caller (GoldilocksSlice64.emitRtl does this automatically)."
            )
        _write_butterfly_testvectors(spec, aIn, bIn, aOut, bOut)
        test_size = len(aIn)
        tb = _gen_butterfly_testbench(spec, pipeline_latency, test_size)
        with open(os.path.join(folder, f"{spec.name}_tb.sv"), "w", encoding="utf-8") as f:
            f.write(tb)

    return {
        "wrapper_module": spec.name,
        "aOut_compressor_module": aOut_info[0],
        "bOut_compressor_module": bOut_info[0],
        "aOut_pipeline_stages": aOut_info[5],
        "bOut_pipeline_stages": bOut_info[5],
        "aOut_compressor_output_width": aOut_info[4],
        "bOut_compressor_output_width": bOut_info[4],
        "pipeline_latency": pipeline_latency,
        "target_fmax_mhz": target_fmax_mhz,
        "aOut_predicted_ns": plan.aOut.worst_ns,
        "bOut_predicted_ns": plan.bOut.worst_ns,
        "predicted_worst_ns": max(plan.aOut.worst_ns, plan.bOut.worst_ns),
    }
