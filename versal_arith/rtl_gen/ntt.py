"""NTT/INTT pipeline RTL generator.

Composes per-butterfly RTL units (via Butterfly_RTL_gen) into a complete
fully-pipelined NTT/INTT datapath: a top wrapper that wires butterflies per
the in-place memory layout, an end-to-end self-checking testbench with
natural-order input/output testvectors, one XDC per butterfly compressor in
`xdc_generated/`, and a JSON manifest summarizing pipeline latency.

Consumes an `NTTOperatorSpec` (produced by
`operator_modeling.ntt.pipelined.FullyPipelinedNTT.FullyPipelinedNTT.getOperatorInterface`) and the
per-layer pipeline-stage configuration. The user is responsible for
providing precomputed natural-order goldens (typically by running batches
through the populated FullyPipelinedNTT instance — same approach as
`operator_modeling.ntt.verification._verifyImpl`).
"""

from __future__ import annotations
import glob
import json
import os

from ntt_spec import NTTOperatorSpec, InterStageWire
from rtl_gen.utils import tb_settle_delay
from rtl_gen.butterfly import Butterfly_RTL_gen, is_datapath_butterfly



# ---------------------------------------------------------------------------
# Hex packing for the natural-order x_in / y_out testvector files
# ---------------------------------------------------------------------------

def _remove_bitheap_descriptors(butterfly_module_names: list[list[str]]) -> None:
    """Delete the bit-heap descriptor .txt files (one per compressor), which
    live in cwd (= run-dir root) and are useless once the compressors exist."""
    for layer in butterfly_module_names:
        for mod in layer:
            for suffix in ("_aOut_bitheap.txt", "_bOut_bitheap.txt"):
                p = f"{mod}{suffix}"
                if os.path.isfile(p):
                    os.remove(p)


def _remove_compressor_xdcs(butterfly_module_names: list[list[str]]) -> None:
    """Delete the per-compressor XDC files. Their `get_cells -hier` patterns name
    a c9_41 by its instance name, which every butterfly reuses, so across an NTT
    they group LUTs of unrelated instances. `rtl/scoped_gpc_xdc.tcl` is the rule
    for a whole design."""
    for layer in butterfly_module_names:
        for mod in layer:
            for label in ("aOut", "bOut"):
                p = os.path.join("xdc_generated", f"{mod}_{label}_cmp.xdc")
                if os.path.isfile(p):
                    os.remove(p)
    if os.path.isdir("xdc_generated") and not os.listdir("xdc_generated"):
        os.rmdir("xdc_generated")


def _share_identical_compressors(rtl_dir: str, top: str,
                                 butterfly_module_names: list[list[str]]) -> int:
    """Keep one module per distinct compressor, named <top>_cmp_<k>, and point
    every butterfly wrapper at it. Compressors take only heap columns as inputs,
    so most differ in name alone. Returns how many modules remain."""
    shared: dict[str, str] = {}
    for layer in butterfly_module_names:
        for mod in layer:
            path = os.path.join(rtl_dir, f"{mod}.sv")
            with open(path, encoding="utf-8") as f:
                wrapper = f.read()
            for label in ("aOut", "bOut"):
                name = f"{mod}_{label}_cmp"
                cmp_path = os.path.join(rtl_dir, f"{name}.sv")
                with open(cmp_path, encoding="utf-8") as f:
                    text = f.read()
                key = text.replace(name, "__COMPRESSOR__")
                if key not in shared:
                    shared[key] = f"{top}_cmp_{len(shared)}"
                    with open(os.path.join(rtl_dir, f"{shared[key]}.sv"), "w", encoding="utf-8") as f:
                        f.write(key.replace("__COMPRESSOR__", shared[key]))
                os.remove(cmp_path)
                wrapper = wrapper.replace(f"    {name} {name}_inst (", f"    {shared[key]} {name}_inst (")
            with open(path, "w", encoding="utf-8") as f:
                f.write(wrapper)
    return len(shared)


def _pack_per_slot(values: list[int], widths: list[int]) -> str:
    """Pack a list of n values (per-slot widths) into a single hex string.
    `values[0]` occupies the LSBs, `values[n-1]` the MSBs — matching the SV
    concatenation `{values[n-1], ..., values[0]}` so a $readmemh into a wide
    logic vector aligns with the TB's slot slicing."""
    total = 0
    offset = 0
    for v, w in zip(values, widths):
        if v < 0:
            v = (1 << w) + v
        v &= (1 << w) - 1
        total |= v << offset
        offset += w
    total_bits = sum(widths)
    hex_width = (total_bits + 3) // 4
    return f"{total:0{hex_width}X}"


def _write_packed_hex(path: str, batches: list[list[int]], widths: list[int]) -> None:
    """One packed hex per cycle; `batches` is shape test_size x n."""
    with open(path, "w", encoding="utf-8") as f:
        for batch in batches:
            f.write(_pack_per_slot(batch, widths) + "\n")


# ---------------------------------------------------------------------------
# Top wrapper SystemVerilog
# ---------------------------------------------------------------------------

def _emit_top_wrapper(
    spec: NTTOperatorSpec,
    layer_latency: list[int],
    butterfly_latencies: list[list[int]],
) -> str:
    n = spec.n
    L = len(spec.butterflySpecs)
    in_widths = spec.inputBitWidthsNatural
    out_widths = spec.outputBitWidthsNatural

    lines: list[str] = []
    lines.append("`timescale 1ns / 1ps")
    lines.append("")
    kind = "Goldilocks" if not any(is_datapath_butterfly(b) for layer in spec.butterflySpecs for b in layer) else f"mod q = {spec.q}"
    lines.append(f"// {kind} NTT/INTT pipeline: butterflyType={spec.butterflyType}, n={n}, negacyclic={spec.negacyclic}")
    lines.append(f"// Per-layer pipeline latency: {layer_latency}")
    lines.append(f"// Total pipeline latency: {sum(layer_latency)} cycle(s)")
    lines.append(f"// Natural-order I/O via per-index named ports x_in_<i> / y_out_<i> (i = 0..{n-1}).")
    lines.append(f"// x_in_<i>  per-index widths range {min(in_widths)}..{max(in_widths)} bit (per stage-0 butterfly port bound).")
    lines.append(f"// y_out_<i> per-index widths range {min(out_widths)}..{max(out_widths)} bit (per final-stage butterfly port bound).")
    lines.append(f"module {spec.name} (")
    lines.append("    input  logic clk,")
    for i in range(n):
        lines.append(f"    input  logic [{in_widths[i] - 1}:0] x_in_{i},")
    for i in range(n):
        suffix = "," if i < n - 1 else ""
        lines.append(f"    output logic [{out_widths[i] - 1}:0] y_out_{i}{suffix}")
    lines.append("    );")
    lines.append("")

    lines.append("    // ---- Per-butterfly raw output wires (DUT outputs before within-layer balancing) ----")
    for s in range(L):
        for p in range(n // 2):
            bs = spec.butterflySpecs[s][p]
            lines.append(f"    logic [{bs.aOutBitWidth - 1}:0] s{s}_p{p}_aOut_raw;")
            lines.append(f"    logic [{bs.bOutBitWidth - 1}:0] s{s}_p{p}_bOut_raw;")
    lines.append("")

    lines.append("    // ---- Per-butterfly post-balancing output wires (feeds next layer / final outputs) ----")
    for s in range(L):
        for p in range(n // 2):
            bs = spec.butterflySpecs[s][p]
            lines.append(f"    logic [{bs.aOutBitWidth - 1}:0] s{s}_p{p}_aOut;")
            lines.append(f"    logic [{bs.bOutBitWidth - 1}:0] s{s}_p{p}_bOut;")
    lines.append("")

    lines.append("    // ---- Butterfly instances ----")
    for s in range(L):
        for p in range(n // 2):
            bs = spec.butterflySpecs[s][p]
            mod = bs.name
            inst = f"{mod}_inst"
            if s == 0:
                ax, bx = spec.inputWiring[p]
                a_in = f"x_in_{ax}"
                b_in = f"x_in_{bx}"
            else:
                wA, wB = spec.interStageWiring[s - 1][p]
                a_in = f"s{s-1}_p{wA.src_p}_{'aOut' if wA.src_port == 'A' else 'bOut'}"
                b_in = f"s{s-1}_p{wB.src_p}_{'aOut' if wB.src_port == 'A' else 'bOut'}"
            lines.append(f"    {mod} {inst} (")
            lines.append(f"        .clk (clk),")
            lines.append(f"        .aIn ({a_in}),")
            lines.append(f"        .bIn ({b_in}),")
            lines.append(f"        .aOut(s{s}_p{p}_aOut_raw),")
            lines.append(f"        .bOut(s{s}_p{p}_bOut_raw)")
            lines.append(f"    );")
    lines.append("")

    lines.append("    // ---- Within-layer balancing shift registers ----")
    has_any_extra = any(layer_latency[s] - butterfly_latencies[s][p] > 0
                        for s in range(L) for p in range(n // 2))
    for s in range(L):
        for p in range(n // 2):
            extra = layer_latency[s] - butterfly_latencies[s][p]
            if extra == 0:
                lines.append(f"    assign s{s}_p{p}_aOut = s{s}_p{p}_aOut_raw;")
                lines.append(f"    assign s{s}_p{p}_bOut = s{s}_p{p}_bOut_raw;")
            else:
                bs = spec.butterflySpecs[s][p]
                aw = bs.aOutBitWidth
                bw = bs.bOutBitWidth
                # Intermediate shift register stages d1..d{extra-1}; the final stage
                # drives s{s}_p{p}_aOut/_bOut (no _d suffix).
                for d in range(1, extra):
                    lines.append(f"    logic [{aw - 1}:0] s{s}_p{p}_aOut_d{d};")
                    lines.append(f"    logic [{bw - 1}:0] s{s}_p{p}_bOut_d{d};")
                lines.append(f"    always_ff @(posedge clk) begin")
                if extra == 1:
                    lines.append(f"        s{s}_p{p}_aOut <= s{s}_p{p}_aOut_raw;")
                    lines.append(f"        s{s}_p{p}_bOut <= s{s}_p{p}_bOut_raw;")
                else:
                    lines.append(f"        s{s}_p{p}_aOut_d1 <= s{s}_p{p}_aOut_raw;")
                    lines.append(f"        s{s}_p{p}_bOut_d1 <= s{s}_p{p}_bOut_raw;")
                    for d in range(2, extra):
                        lines.append(f"        s{s}_p{p}_aOut_d{d} <= s{s}_p{p}_aOut_d{d-1};")
                        lines.append(f"        s{s}_p{p}_bOut_d{d} <= s{s}_p{p}_bOut_d{d-1};")
                    lines.append(f"        s{s}_p{p}_aOut <= s{s}_p{p}_aOut_d{extra-1};")
                    lines.append(f"        s{s}_p{p}_bOut <= s{s}_p{p}_bOut_d{extra-1};")
                lines.append(f"    end")
    if not has_any_extra:
        lines.append("    // (all butterflies in every layer have matching latency; no shift registers needed)")
    lines.append("")

    lines.append("    // ---- Final-stage to natural-order outputs ----")
    lines.append("    // Each y_out_<i> port width matches the producing butterfly port's bound exactly.")
    for p in range(n // 2):
        natA, natB = spec.outputWiring[p]
        lines.append(f"    assign y_out_{natA} = s{L-1}_p{p}_aOut;")
        lines.append(f"    assign y_out_{natB} = s{L-1}_p{p}_bOut;")
    lines.append("")
    lines.append("endmodule")

    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# Top testbench SystemVerilog
# ---------------------------------------------------------------------------

def _emit_top_testbench(spec: NTTOperatorSpec, total_latency: int, test_size: int) -> str:
    n = spec.n
    in_widths = spec.inputBitWidthsNatural
    out_widths = spec.outputBitWidthsNatural
    total_in_bits = sum(in_widths)
    total_out_bits = sum(out_widths)

    in_offsets = [0]
    for w in in_widths:
        in_offsets.append(in_offsets[-1] + w)
    out_offsets = [0]
    for w in out_widths:
        out_offsets.append(out_offsets[-1] + w)

    lines: list[str] = []
    lines.append("`timescale 1ns / 1ps")
    lines.append("")
    lines.append(f"// Self-checking testbench for {spec.name}.")
    lines.append(f"// Drives natural-order x_in_<i> vectors and compares y_out_<i> against precomputed goldens.")
    lines.append(f"// Total pipeline latency: {total_latency} cycle(s).")
    lines.append(f"// PASS/FAIL strings match scripts/run_remote_sim.py grep patterns (SUCCESS!, PASS All, FAILED:).")
    lines.append(f"module {spec.name}_tb ();")
    lines.append("    `define CLK_P         10")
    lines.append("    `define CLK_HP        5")
    lines.append(f"    `define TS_SIZE       {test_size}")
    lines.append("    `define INIT_RESET    200")
    lines.append("")
    lines.append("    logic clk;")
    lines.append("    initial clk = 1'b0;")
    lines.append("    always #`CLK_HP clk = ~clk;")
    lines.append("")

    for i in range(n):
        lines.append(f"    logic [{in_widths[i] - 1}:0] x_in_{i};")
    for i in range(n):
        lines.append(f"    logic [{out_widths[i] - 1}:0] y_out_{i};")
    lines.append("")

    lines.append(f"    logic [{total_in_bits - 1}:0]  x_in_ts  [`TS_SIZE-1:0];")
    lines.append(f"    logic [{total_out_bits - 1}:0] y_out_ts [`TS_SIZE-1:0];")
    lines.append("")

    lines.append("    initial begin")
    lines.append("        $readmemh(\"../../../../../testvectors/x_in.txt\",  x_in_ts );")
    lines.append("        $readmemh(\"../../../../../testvectors/y_out.txt\", y_out_ts);")
    lines.append("    end")
    lines.append("")

    lines.append(f"    {spec.name} DUT (")
    lines.append("        .clk(clk),")
    for i in range(n):
        lines.append(f"        .x_in_{i}(x_in_{i}),")
    for i in range(n):
        suffix = "," if i < n - 1 else ""
        lines.append(f"        .y_out_{i}(y_out_{i}){suffix}")
    lines.append("    );")
    lines.append("")

    # Concatenation that matches the per-slot packed hex: SV `{a, b, c}` puts `a`
    # at the MSBs, so `{y_out_{n-1}, ..., y_out_0}` aligns with values[0] in the
    # LSBs. Per-port widths line up natively — no truncation needed.
    concat_actual = ", ".join(f"y_out_{i}" for i in range(n - 1, -1, -1))
    lines.append(f"    logic [{total_out_bits - 1}:0] y_out_packed;")
    lines.append(f"    assign y_out_packed = {{{concat_actual}}};")
    lines.append("")

    # Driver block: per-slot constant-offset assigns from the packed x_in_ts row.
    # Per-natural widths can differ, so we unroll instead of using a `+:` loop
    # (which would require constant width).
    lines.append("    int i;")
    lines.append("    initial begin")
    lines.append("        #`INIT_RESET;")
    lines.append("        #`CLK_HP;")
    lines.append("        #1;")
    lines.append("        for (i = 0; i < `TS_SIZE; i = i + 1) begin")
    for k in range(n):
        hi = in_offsets[k + 1] - 1
        lo = in_offsets[k]
        lines.append(f"            x_in_{k} = x_in_ts[i][{hi}:{lo}];")
    lines.append("            #`CLK_P;")
    lines.append("        end")
    lines.append("    end")
    lines.append("")

    # Checker block.
    lines.append("    int j;")
    lines.append("    int correct_cnt;")
    lines.append("    initial begin")
    lines.append("        correct_cnt = 0;")
    lines.append("        #`INIT_RESET;")
    lines.append("        #`CLK_HP;")
    lines.append(f"        #(`CLK_P*{total_latency});")
    lines.append(f"        #{tb_settle_delay(total_latency)};")
    lines.append("        for (j = 0; j < `TS_SIZE; j = j + 1) begin")
    lines.append("            // `===` alone is NOT X-safe: X === X is true, so a run whose")
    lines.append("            // $readmemh silently failed (all-X inputs, all-X goldens, all-X")
    lines.append("            // DUT outputs) would score a full PASS having checked nothing.")
    lines.append("            // Guard on $isunknown so any X anywhere is a failure.")
    lines.append("            if (!$isunknown(y_out_packed) && !$isunknown(y_out_ts[j])")
    lines.append("                && y_out_packed === y_out_ts[j]) begin")
    lines.append("                $display(\"Testvector-%d CORRECT!\", j);")
    lines.append("                correct_cnt = correct_cnt + 1;")
    lines.append("            end else begin")
    lines.append("                $display(\"=================================================================================\");")
    lines.append("                $display(\"Testvector-%d WRONG\", j);")
    lines.append("                if ($isunknown(y_out_ts[j]))")
    lines.append("                    $display(\"  golden is X — testvectors not loaded (check the $readmemh path)\");")
    lines.append("                if ($isunknown(y_out_packed))")
    lines.append("                    $display(\"  DUT output is X — undriven logic or X-valued inputs\");")
    for i in range(n):
        hi = out_offsets[i + 1] - 1
        lo = out_offsets[i]
        lines.append(f"                if (y_out_{i} !== y_out_ts[j][{hi}:{lo}]) begin")
        lines.append(f"                    $display(\"  y_out_{i} module    output: %h\", y_out_{i});")
        lines.append(f"                    $display(\"  y_out_{i} reference output: %h\", y_out_ts[j][{hi}:{lo}]);")
        lines.append(f"                end")
    lines.append("                $display(\"=================================================================================\");")
    lines.append("            end")
    lines.append("            #`CLK_P;")
    lines.append("        end")
    lines.append("        if (correct_cnt == `TS_SIZE) begin")
    lines.append("            $display(\"SUCCESS!\");")
    lines.append("            $display(\"PASS All %d Testvectors!\", `TS_SIZE);")
    lines.append("        end else begin")
    lines.append("            $display(\"TO BE DEBUGGED...\");")
    lines.append("            $display(\"FAILED: %d out of %d testvectors failed\", (`TS_SIZE-correct_cnt), `TS_SIZE);")
    lines.append("        end")
    lines.append("        $finish();")
    lines.append("    end")
    lines.append("")
    lines.append("endmodule")

    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def NTT_RTL_gen(
    spec: NTTOperatorSpec,
    pipeline_stages_per_layer: list[int],
    gen_testbench: bool = True,
    test_size: int = 1000,
    visualization: bool = False,
    golden_x_natural: list[list[int]] | None = None,
    golden_y_natural: list[list[int]] | None = None,
    target_fmax_mhz: float | None = None,
    share_compressors: bool = True,
) -> dict:
    """Emit SystemVerilog for a Goldilocks NTT/INTT pipeline.

    `share_compressors` (the default) writes each distinct compressor once and
    points every butterfly using it at that module, which shortens compilation
    and leaves the logic as it was.

    `target_fmax_mhz`, when given, lets every butterfly pick the fewest
    compressor stages that reach the target (`butterfly_stage_plan`); the
    per-layer entries of `pipeline_stages_per_layer` are then not used, and
    the within-layer balancing registers reconcile whatever depths the
    butterflies chose.

    Files written (relative to cwd):
        RTL_generated/<spec.name>.sv                top wrapper
        RTL_generated/<spec.name>_tb.sv             top TB (when gen_testbench)
        RTL_generated/<spec.name>_btf_L<s>_p<p>.sv  one per butterfly wrapper
        RTL_generated/<spec.name>_btf_L<s>_p<p>_{aOut,bOut}_cmp.sv  one per compressor
        testvectors/x_in.txt, testvectors/y_out.txt   (when gen_testbench)
        manifest.json                                  pipeline latency / module list

    `Butterfly_RTL_gen` also writes one bit-heap .txt per output, which
    `_remove_bitheap_descriptors` deletes once the compressors exist.

    `pipeline_stages_per_layer` controls per-layer butterfly latency. Length
    must equal log2(n); every butterfly in layer s gets `pipeline_stages_per_layer[s]`
    forwarded to Butterfly_RTL_gen. Within-layer balancing shift registers are
    inserted automatically when butterflies in the same layer report different
    actual latencies.

    `golden_x_natural` and `golden_y_natural` (required when gen_testbench=True)
    are shape `test_size x n`, each row being one cycle's natural-order inputs
    or expected outputs. Caller is responsible for generating these (typically
    via `propagateValue` end-to-end through the populated FullyPipelinedNTT;
    see scripts/build_ntt.py).
    """
    # A previous run of this top may have left modules this one no longer writes;
    # the flows compile every .sv here, so they would be elaborated with the new.
    for stale in glob.glob(os.path.join("RTL_generated", f"{spec.name}*.sv")):
        os.remove(stale)

    n = spec.n
    L = len(spec.butterflySpecs)
    if len(pipeline_stages_per_layer) != L:
        raise ValueError(
            f"pipeline_stages_per_layer must have length log2(n)={L}, "
            f"got {len(pipeline_stages_per_layer)}"
        )
    if gen_testbench:
        if golden_x_natural is None or golden_y_natural is None:
            raise ValueError(
                "NTT_RTL_gen: golden_x_natural and golden_y_natural are required when gen_testbench=True"
            )
        if len(golden_x_natural) != test_size or len(golden_y_natural) != test_size:
            raise ValueError(
                f"golden batches must have length test_size={test_size}; "
                f"got x={len(golden_x_natural)}, y={len(golden_y_natural)}"
            )
        for r, row in enumerate(golden_x_natural):
            if len(row) != n:
                raise ValueError(f"golden_x_natural[{r}] has {len(row)} entries, expected n={n}")
        for r, row in enumerate(golden_y_natural):
            if len(row) != n:
                raise ValueError(f"golden_y_natural[{r}] has {len(row)} entries, expected n={n}")

    # Per-butterfly emission. cwd is already set to the NTT run dir by the caller.
    butterfly_latencies: list[list[int]] = []
    butterfly_module_names: list[list[str]] = []     # Goldilocks butterflies (compressor bookkeeping)
    datapath_modules: list[str] = []
    for s in range(L):
        layer_latencies: list[int] = []
        layer_module_names: list[str] = []
        for p in range(n // 2):
            bs = spec.butterflySpecs[s][p]
            if is_datapath_butterfly(bs):
                if bs.extraPorts:
                    raise NotImplementedError(
                        f"{bs.name}: twiddle / modulus inputs {[p for p, _ in bs.extraPorts]} would need "
                        f"ports on the NTT top; an NTT takes constant twiddles at a fixed q for now")
                # scheduled on the operator side for this layer's request / target
                info = Butterfly_RTL_gen(spec=bs, gen_testbench=False)
                layer_latencies.append(info["pipeline_latency"])
                datapath_modules.append(bs.name)
                continue
            info = Butterfly_RTL_gen(
                spec=bs,
                pipeline_stages=pipeline_stages_per_layer[s],
                gen_testbench=False,
                visualization=visualization,
                target_fmax_mhz=target_fmax_mhz,
            )
            layer_latencies.append(info["pipeline_latency"])
            layer_module_names.append(bs.name)
        butterfly_latencies.append(layer_latencies)
        butterfly_module_names.append(layer_module_names)

    layer_latency = [max(layer_latencies) for layer_latencies in butterfly_latencies]
    total_latency = sum(layer_latency)

    # Each `Butterfly_RTL_gen` call wrote three SV files (wrapper + aOut
    # compressor + bOut compressor) into `RTL_generated/`; they stay split, one
    # module per file.
    rtl_dir = "RTL_generated"
    _remove_bitheap_descriptors(butterfly_module_names)
    _remove_compressor_xdcs(butterfly_module_names)
    shared_modules = None
    if share_compressors:
        shared_modules = _share_identical_compressors(rtl_dir, spec.name, butterfly_module_names)

    # Top wrapper.
    os.makedirs(rtl_dir, exist_ok=True)
    wrapper_sv = _emit_top_wrapper(spec, layer_latency, butterfly_latencies)
    with open(os.path.join(rtl_dir, f"{spec.name}.sv"), "w", encoding="utf-8") as f:
        f.write(wrapper_sv)

    # Top testbench + testvectors.
    if gen_testbench:
        tv_dir = "testvectors"
        os.makedirs(tv_dir, exist_ok=True)
        _write_packed_hex(os.path.join(tv_dir, "x_in.txt"), golden_x_natural,
                          list(spec.inputBitWidthsNatural))
        _write_packed_hex(os.path.join(tv_dir, "y_out.txt"), golden_y_natural,
                          spec.outputBitWidthsNatural)
        tb_sv = _emit_top_testbench(spec, total_latency, test_size)
        with open(os.path.join(rtl_dir, f"{spec.name}_tb.sv"), "w", encoding="utf-8") as f:
            f.write(tb_sv)

    # Manifest.
    manifest = {
        "top_name": spec.name,
        "n": n,
        "butterflyType": spec.butterflyType,
        "negacyclic": spec.negacyclic,
        "pipeline_stages_per_layer": list(pipeline_stages_per_layer),
        "target_fmax_mhz": target_fmax_mhz,
        "shared_compressor_modules": shared_modules,
        "butterfly_latencies": butterfly_latencies,
        "layer_latency": layer_latency,
        "total_latency": total_latency,
        "test_size": test_size if gen_testbench else 0,
        "butterfly_module_names": butterfly_module_names,
        "datapath_butterfly_modules": datapath_modules,
    }
    with open("manifest.json", "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    return manifest


# ---------------------------------------------------------------------------
# Streaming (stage-pipelined) NTT
# ---------------------------------------------------------------------------

def _sv_const(v: int, w: int) -> str:
    return f"{w}'h{v:x}"


def _emit_reorder_ram(name: str) -> str:
    """`<name> #(W, A)`: simple dual-port RAM of 2^A words, written every cycle, registered read (the output
    reorder of the streaming NTT, outputOrder='natural'). The two addresses never meet (other frame half)."""
    return f"""`timescale 1ns / 1ps
module {name} #(parameter int W = 8, parameter int A = 4) (
    input  logic clk,
    input  logic [A-1:0] wa,
    input  logic [W-1:0] wd,
    input  logic [A-1:0] ra,
    output logic [W-1:0] rd
    );
    logic [W-1:0] mem [1 << A];
    always_ff @(posedge clk) begin
        mem[wa] <= wd;
        rd <= mem[ra];
    end
endmodule
"""


def _emit_delay_module(name: str) -> str:
    """`<name> #(W, D)`: a D-cycle delay line (D >= 1): registers / SRLs below
    64, a RAM circular buffer (registered read) from 64 up."""
    return f"""`timescale 1ns / 1ps
module {name} #(parameter int W = 8, parameter int D = 1) (
    input  logic clk,
    input  logic [W-1:0] din,
    output logic [W-1:0] dout
    );
    generate
    if (D < 64) begin : g_sr
        logic [W-1:0] sr [D];
        always_ff @(posedge clk) begin
            sr[0] <= din;
            for (int i = 1; i < D; i++) sr[i] <= sr[i-1];
        end
        assign dout = sr[D-1];
    end else begin : g_ram
        // 2026-11-16: D - 2 words and two read registers (the second is the block RAM's output register), so the
        // word leaves a register: a block RAM read without it took half the cycle before the multiplier it feeds
        localparam int A = $clog2(D - 2);
        (* ram_style = "block" *) logic [W-1:0] mem [D-2];
        logic [A-1:0] ptr = '0;
        logic [W-1:0] rd;
        always_ff @(posedge clk) begin
            rd <= mem[ptr];
            dout <= rd;
            mem[ptr] <= din;
            ptr <= (ptr == A'(D - 3)) ? '0 : ptr + 1'b1;
        end
    end
    endgenerate
endmodule

// {name}_c: the same delay with a flip-flop at both ends (modulus constants and tags, 2026-11-16): the value
// leaves a register next to its source and arrives in a register next to its consumers (replicated beyond 8
// loads), with the shift register or RAM in between. A shift register alone sits in one place, so the hop to
// the next point of use was one long wire.
module {name}_c #(parameter int W = 8, parameter int D = 1) (
    input  logic clk,
    input  logic [W-1:0] din,
    output logic [W-1:0] dout
    );
    (* shreg_extract = "no", max_fanout = 8 *) logic [W-1:0] s_out;
    generate
    if (D == 1) begin : g_one
        always_ff @(posedge clk) s_out <= din;
    end else begin : g_ends
        (* shreg_extract = "no" *) logic [W-1:0] s_in;
        logic [W-1:0] mid;
        always_ff @(posedge clk) s_in <= din;
        if (D == 2) begin : g_two
            assign mid = s_in;
        end else begin : g_mid
            {name} #(.W(W), .D(D - 2)) m_i (.clk(clk), .din(s_in), .dout(mid));
        end
        always_ff @(posedge clk) s_out <= mid;
    end
    endgenerate
    assign dout = s_out;
endmodule
"""


def _emit_rom_module(name: str, tables: list[list[int]], width: int, addrBits: int) -> str:
    """One ROM per table column set: `tables` is a list of equal-length lists
    (W, and WP for Shoup), read together; registered read."""
    depth = len(tables[0])
    ws = [width] + [max(1, max(t).bit_length()) for t in tables[1:]]
    outs = ",\n".join(f"    output logic [{w - 1}:0] q{i}" for i, w in enumerate(ws))
    lines = [f"`timescale 1ns / 1ps", f"module {name} (", "    input  logic clk,",
             f"    input  logic [{max(addrBits, 1) - 1}:0] addr,", outs, "    );"]
    for i, (t, w) in enumerate(zip(tables, ws)):
        lines.append(f"    logic [{w - 1}:0] m{i} [{depth}];")
        lines.append("    initial begin")
        for a, v in enumerate(t):
            lines.append(f"        m{i}[{a}] = {_sv_const(v, w)};")
        lines.append("    end")
        a = "addr" if addrBits > 0 else "1'b0"
        lines.append(f"    always_ff @(posedge clk) q{i} <= m{i}[{a}];")
    lines.append("endmodule")
    return "\n".join(lines) + "\n"


def _emit_table_module(name: str, t: dict, addrBits: int) -> str:
    """A twiddle table: a ROM (values known) or a RAM written through the load
    port (`we`, `wa`, `wd` per column); one registered read port."""
    depth, cols = t["depth"], t["cols"]
    ab = max(1, (depth - 1).bit_length())
    L = ["`timescale 1ns / 1ps", f"module {name} (", "    input  logic clk,",
         f"    input  logic [{max(addrBits, 1) - 1}:0] addr,"]
    if t["mode"] == "ram":
        L.append("    input  logic we,")
        L.append(f"    input  logic [{ab - 1}:0] wa,")
        L.append(f"    input  logic [{max(1, len(cols)) - 1}:0] wcol,")
        L.append(f"    input  logic [{max(cols) - 1}:0] wd,")
    L.append(",\n".join(f"    output logic [{w - 1}:0] q{i}" for i, w in enumerate(cols)))
    L.append("    );")
    # the address is registered first (the counter arithmetic stays off the read path): latency 2
    L.append(f"    logic [{max(addrBits, 1) - 1}:0] addr_q;")
    L.append("    always_ff @(posedge clk) addr_q <= addr;")
    for i, w in enumerate(cols):
        # `romStyle` (the unrolled type only): the mapping its cost model priced, instead of Vivado's own choice
        st = t.get("romStyle")
        attr = ("rom_style" if t["mode"] == "rom" else "ram_style") if st else ""
        L.append((f'    (* {attr} = "{st}" *) ' if st else "    ") + f"logic [{w - 1}:0] m{i} [{depth}];")
        if t["mode"] == "rom":
            L.append("    initial begin")
            for a_, v in enumerate(t["values"][i]):
                L.append(f"        m{i}[{a_}] = {_sv_const(v, w)};")
            L.append("    end")
        else:
            L.append(f"    always_ff @(posedge clk) if (we && wcol == {i}) m{i}[wa] <= wd[{w - 1}:0];")
        rd = "addr_q" if addrBits > 0 else "1'b0"
        L.append(f"    always_ff @(posedge clk) q{i} <= m{i}[{rd}];")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def _emit_modtab_module(name: str, table: dict, widths: dict, iw: int, loadable: bool = False) -> str:
    """`<name>`: the modulus table (per-frame moduli): one registered LUT ROM per
    constant (Q, MU, ...), indexed by the frame's modulus index.
    `loadable`: a LUT RAM per constant instead, empty at power-up and written through `we`, `widx`, `wd_<P>`
    (run-time moduli: a slot is written while frames of other slots run)."""
    M = len(next(iter(table.values())))
    L = ["`timescale 1ns / 1ps", f"module {name} (", "    input  logic clk,", f"    input  logic [{iw - 1}:0] idx,"]
    if loadable:
        L += ["    input  logic we,", f"    input  logic [{iw - 1}:0] widx,"]
        L += [f"    input  logic [{widths[p] - 1}:0] wd_{p}," for p in table]
    L.append(",\n".join(f"    output logic [{widths[p] - 1}:0] {p}" for p in table))
    L.append("    );")
    for p, vals in table.items():
        w = widths[p]
        if loadable:
            L.append(f'    (* ram_style = "distributed" *) logic [{w - 1}:0] m_{p} [{1 << iw}];')
            L.append(f"    initial for (int a = 0; a < {1 << iw}; a++) m_{p}[a] = '0;")
            L.append(f"    always_ff @(posedge clk) if (we) m_{p}[widx] <= wd_{p};")
        else:
            L.append(f'    (* rom_style = "distributed" *) logic [{w - 1}:0] m_{p} [{1 << iw}];')
            L.append("    initial begin")
            for a in range(1 << iw):
                L.append(f"        m_{p}[{a}] = {_sv_const(vals[a] if a < M else 0, w)};")
            L.append("    end")
        L.append(f"    (* max_fanout = 16 *) logic [{w - 1}:0] r_{p};")
        L.append(f"    always_ff @(posedge clk) r_{p} <= m_{p}[idx];")
        L.append(f"    assign {p} = r_{p};")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def gen_a(gd, sig: str, w: int) -> str:
    """Operand A of a generator multiplier: a table value (unsigned, `w` bits), widened to the port.
    The port is wider when the multiplier is sized for the signed A - B of Gentleman-Sande butterflies."""
    pw = next(x.bitWidth for x in gd.inputs if x.name == "A")
    return sig if pw == w else f"{{{pw - w}'d0, {sig}}}" if pw > w else f"{sig}[{pw - 1}:0]"


def StreamNTT_RTL_gen(spec, x_in=None, y_out=None, tb=None) -> dict:
    """Emit a streaming NTT (`ntt_spec.StreamNTTSpec`) into the cwd: the top
    RTL_generated/<name>.sv, delay lines, twiddle tables (ROMs, or RAMs on the
    load port), on-the-fly generators, butterflies, output twist; with
    `x_in` / `y_out` (per lane, per cycle) and `tb` ({dir, q: port values,
    load: words}) a testbench and testvectors/{x,y}_<l>.txt, tw_load.txt."""
    from rtl_gen.butterfly import Butterfly_RTL_gen
    from rtl_gen.datapath import Datapath_RTL_gen
    from rtl_gen.utils import to_twos_complement_hex
    name, P, F = spec.name, spec.lanes, spec.frameCycles
    FB = (F - 1).bit_length() if F > 1 else 0
    info = spec.roms
    tables, gen, qports = info["tables"], info["generator"], info["qPorts"]
    loadW = info["loadWords"]
    pf = info.get("perFrame")             # per-frame moduli: MIDX in, the constants from a table
    # the fully pipelined type (operator_modeling.ntt.dataflow.UnrolledNTT, lanes = n) may ask for: twiddle-table copies
    # shared by up to `tableShare` butterflies of a stage, a modulus-table copy per `modShare` butterflies, and
    # max_fanout on the tag registers. Absent (every other design): nothing changes.
    unr = info.get("unrolled") or {}
    tshare, mshare, tfan = unr.get("tableShare"), unr.get("modShare"), unr.get("tagFanout")
    IW = pf["indexBits"] if pf else 0
    # per-frame moduli with both directions: DIR is per frame too, sampled with MIDX on the frame's first cycle
    # and carried in the same frame-boundary registers as the low bit of the tag {MIDX, DIR}
    PD = 1 if (pf and spec.dirPort) else 0
    # the unrolled type without per-frame moduli (one q per job) may still carry DIR per frame in the tag
    # registers (`frameDir`, one frame = one cycle), so the direction can change on any transform
    FD = 1 if (not pf and spec.dirPort and (info.get("unrolled") or {}).get("frameDir") and F == 1) else 0
    TGW = IW + PD + FD
    rtl = "RTL_generated"
    os.makedirs(rtl, exist_ok=True)
    for stale in glob.glob(os.path.join(rtl, f"{name}*.sv")):
        os.remove(stale)
    dly = f"{name}_dly"
    with open(os.path.join(rtl, f"{dly}.sv"), "w", encoding="utf-8") as f:
        f.write(_emit_delay_module(dly))
    for mod, bs in spec.modules.items():
        Butterfly_RTL_gen(spec=bs, gen_testbench=False)
    tw = spec.twist
    if tw is not None:
        Datapath_RTL_gen(spec=tw["datapath"], gen_testbench=False, submodules=tw["submodules"], write_xdc=False)
    if gen is not None:
        Datapath_RTL_gen(spec=gen["datapath"], gen_testbench=False, submodules=gen["submodules"], write_xdc=False)
    if os.path.isfile("manifest.json"):
        os.remove("manifest.json")
    dirBit = 1 if spec.dirPort else 0

    # table modules (address: DIR on top when both directions live in one table; per-frame moduli: MIDX above)
    def taddr_bits(t):
        return len(t["bits"]) + dirBit + IW
    for t in tables:
        with open(os.path.join(rtl, f"{name}_tab{t['id']}.sv"), "w", encoding="utf-8") as f:
            f.write(_emit_table_module(f"{name}_tab{t['id']}", t, taddr_bits(t)))

    L = ["`timescale 1ns / 1ps",
         f"// {name}: streaming NTT, n={spec.n}, {P} lanes, frame {F} cycles, "
         f"{'q=' + str(spec.q) if spec.q else 'run-time q'}, direction {spec.direction}, latency {spec.latency}"]
    ports = ["    input  logic clk", "    input  logic rst"]
    if spec.dirPort:
        ports.append("    input  logic DIR")
    # run-time moduli with a change per polynomial (loadableModuli): the modulus constants of a polynomial come
    # with it on mq_<P>, sampled with MIDX on its first cycle, and travel in the tag registers beside the data.
    # MIDX names the slot of the twiddle tables, which are RAMs written through the load port (tw_slot).
    MTL = bool(pf and pf.get("loadable"))
    CW = sum(w for _, w in qports) if MTL else 0
    cslice, _o = {}, TGW
    for qp, w in (qports if MTL else []):
        cslice[qp] = (_o + w - 1, _o)
        _o += w
    # one transform per cycle (the unrolled type, FB = 0): the tag has a register on every cycle, which is far
    # too many for the wide constants. They run beside it through shift-register delay lines from one point
    # of use to the next (CQS). With frames (FB > 0) the tag has one register per site per frame: they stay in it.
    CQS = bool(MTL and not FB)
    TW = TGW + (0 if CQS else CW)            # the whole tag: {constants, MIDX, DIR}
    if pf:
        ports.append(f"    input  logic [{IW - 1}:0] MIDX")
        if MTL:
            ports += [f"    input  logic [{w - 1}:0] mq_{qp}" for qp, w in qports]
    else:
        ports += [f"    input  logic [{w - 1}:0] {qp}" for qp, w in qports]
    if loadW:
        LW = loadW.bit_length()          # holds loadW itself (the end of the last table)
        TWL = max(max(t["cols"]) for t in tables if t["mode"] == "ram")     # one load word
        LR = info.get("loadLanes", 1)                                       # words per cycle on the load port
        TWW = TWL * LR
        ports += ["    input  logic tw_rst", "    input  logic tw_wen", f"    input  logic [{TWW - 1}:0] tw_wdata"]
        if MTL:
            ports.append(f"    input  logic [{IW - 1}:0] tw_slot")     # the slot this load fills, sampled with tw_rst
        if MTL and info.get("loadByDir"):   # a load fills one direction: the half tw_dir of the slot's block
            ports.append("    input  logic tw_dir")
    strm = info.get("stream")             # 'stream' twiddles: one input per class, in step with the frame
    if strm:
        ports += [f"    input  logic [{strm['width'] - 1}:0] tw_s{c}" for c in range(strm["classes"])]
    ports += [f"    input  logic [{spec.inWidth - 1}:0] x_in_{l}" for l in range(P)]
    ports += [f"    output logic [{spec.outWidth - 1}:0] y_out_{l}" for l in range(P)]
    L.append(f"module {name} (\n" + ",\n".join(ports) + "\n    );")
    if FB:
        L.append(f"    logic [{FB - 1}:0] cnt;")
        L.append("    always_ff @(posedge clk) cnt <= rst ? '0 : cnt + 1'b1;")
    if loadW:
        # the load port is registered once more at every table (hit, address, column) and the data
        # word is registered with a fanout limit, so the decode does not span the die; writes land one
        # cycle later, long before the first frame reads them
        # 2026-11-16: the load port is registered once more (tw_*_p), and every table takes its write enable,
        # address and data from registers of its own (LOAD_PIPE cycles later in all): the load is a broadcast to
        # every table of the core, and one register per signal could not reach them in a cycle
        L.append(f"    (* max_fanout = 32 *) logic tw_rst_p, tw_wen_p; (* max_fanout = 32 *) logic [{TWW - 1}:0] tw_wdata_p;")
        L.append("    always_ff @(posedge clk) begin tw_rst_p <= tw_rst; tw_wen_p <= tw_wen; tw_wdata_p <= tw_wdata; end")
        L.append(f"    (* max_fanout = 32 *) logic [{LW - 1}:0] tw_wi;")
        L.append("    always_ff @(posedge clk) tw_wi <= tw_rst_p ? '0 : (tw_wen_p ? tw_wi + 1'b1 : tw_wi);")
        L.append(f"    (* max_fanout = 32 *) logic [{TWW - 1}:0] tw_wd_q;")
        L.append("    always_ff @(posedge clk) tw_wd_q <= tw_wdata_p;")
        if MTL:
            L.append(f"    logic [{IW - 1}:0] tw_slot_p; always_ff @(posedge clk) tw_slot_p <= tw_slot;")
            L.append(f"    (* max_fanout = 32 *) logic [{IW - 1}:0] tw_sl;")
            L.append("    always_ff @(posedge clk) if (tw_rst_p) tw_sl <= tw_slot_p;")
        if MTL and info.get("loadByDir"):
            L.append("    logic tw_dir_p; always_ff @(posedge clk) tw_dir_p <= tw_dir;")
            L.append("    (* max_fanout = 32 *) logic tw_dr;")
            L.append("    always_ff @(posedge clk) if (tw_rst_p) tw_dr <= tw_dir_p;")

    # per-frame moduli: the frame's index in frame-boundary registers. tag_at(o) holds frame m's index during
    # offsets [o + mF, o + (m+1)F): loaded on the edge closing cycle o - 1 from a register at a lower offset
    # a with 1 <= o - a <= F (chained every F cycles); the base one takes MIDX on the frame's first cycle.
    tags = {}
    msites = {}
    if pf:
        with open(os.path.join(rtl, f"{name}_mtab.sv"), "w", encoding="utf-8") as f:
            if not MTL:
                f.write(_emit_modtab_module(f"{name}_mtab", pf["table"], dict(qports), IW))
        if MTL:
            os.remove(os.path.join(rtl, f"{name}_mtab.sv"))
        cin = ", ".join(f"mq_{qp}" for qp, _ in reversed(qports))
        tin = (cin + ", " if (MTL and not CQS) else "") + ("MIDX, DIR" if PD else "MIDX")
        if CQS:
            L.append(f"    logic [{CW - 1}:0] cq_1;")
            L.append(f"    always_ff @(posedge clk) cq_1 <= {{{cin}}};")
        L.append(f"    logic [{TW - 1}:0] mx_1;")
        L.append(f"    always_ff @(posedge clk) if ({'cnt == ' + str(FB) + chr(39) + 'd0' if FB else '1' + chr(39) + 'b1'}) mx_1 <= {{{tin}}};")
        tags[1] = "mx_1"
    if FD:
        L.append("    logic [0:0] mx_1;")
        L.append("    always_ff @(posedge clk) mx_1 <= DIR;")
        tags[1] = "mx_1"

    def tag_at(o: int) -> str:
        if o < 1:
            raise AssertionError(f"{name}: modulus index needed at offset {o} (lead too small)")
        if o in tags:
            return tags[o]
        a = max(x for x in tags if x < o)
        if o - a > F:
            a = o - F
            tag_at(a)
        nm = f"mx_{o}"
        if FB:
            hit = f"mxh_{o}"
            L.append(f"    logic {hit}; logic [{TW - 1}:0] {nm};")
            L.append(f"    always_ff @(posedge clk) {hit} <= (cnt == {FB}'d{(o - 2) % F});")
            L.append(f"    always_ff @(posedge clk) if ({hit}) {nm} <= {tags[a]};")
        else:
            L.append((f"    (* max_fanout = {tfan} *) " if tfan else "    ") + f"logic [{TW - 1}:0] {nm};")
            L.append(f"    always_ff @(posedge clk) {nm} <= {tags[a]};")
        tags[o] = nm
        return nm

    cqs = {1: "cq_1"}

    def cq_at(o: int) -> str:
        """The constants of the transform at offset o (CQS): a delay line from the nearest earlier point."""
        if o < 1:
            raise AssertionError(f"{name}: modulus constants needed at offset {o} (lead too small)")
        if o not in cqs:
            a = max(x for x in cqs if x < o)
            nm = f"cq_{o}"
            L.append(f"    logic [{CW - 1}:0] {nm};")
            L.append(f"    {dly}_c #(.W({CW}), .D({o - a})) {nm}_i (.clk(clk), .din({cqs[a]}), .dout({nm}));")
            cqs[o] = nm
        return cqs[o]

    def msig(site: str, off: int, qp: str) -> str:
        """The constant `qp` of the frame at offset `off` (its consumer's input): a table copy read from
        the index at off - 1."""
        if site not in msites and MTL:
            # the constants ride in the tag: one register per site (as the table's output register was)
            src = cq_at(off - 1) if CQS else tag_at(off - 1)
            for p, w_ in qports:
                hi, lo = cslice[p]
                if CQS:
                    hi, lo = hi - TGW, lo - TGW
                L.append(f"    (* max_fanout = 16 *) logic [{w_ - 1}:0] {site}_{p};")
                L.append(f"    always_ff @(posedge clk) {site}_{p} <= {src}[{hi}:{lo}];")
            msites[site] = True
        if site not in msites:
            idx = tag_at(off - 1) + (f"[{TGW - 1}:1]" if PD else "")
            outs = ", ".join(f".{p}({site}_{p})" for p, _ in qports)
            for p, w_ in qports:
                L.append(f"    logic [{w_ - 1}:0] {site}_{p};")
            L.append(f"    {name}_mtab {site}_mt (.clk(clk), .idx({idx}), {outs});")
            msites[site] = True
        return f"{site}_{qp}"

    cntk = {}

    def tsig(off: int, plus: int = 0) -> str:
        # 2026-11-16: every phase of the frame counter is a counter of its own (the same value as cnt + k), kept
        # next to its users. One counter for the whole pipeline drove the table addresses and selects of every
        # stage across the die.
        if not FB:
            return ""
        k = (plus - off) % F
        if k not in cntk:
            nm = f"cnt_p{k}"
            L.append(f"    (* max_fanout = 16 *) logic [{FB - 1}:0] {nm};")
            L.append(f"    always_ff @(posedge clk) {nm} <= rst ? {FB}'d{k} : {nm} + 1'b1;")
            cntk[k] = nm
        return cntk[k]

    def table_inst(t, inst, addr_expr, outs):
        conn = [".clk(clk)", f".addr({addr_expr})"]
        if t["mode"] == "ram":
            ab = max(1, (t["depth"] - 1).bit_length())
            base, nc = t["base"], len(t["cols"])
            # per-frame moduli in loadable slots: the load image is one slot's block of the table
            bd = t["depth"] // t["mods"] if (MTL and t.get("mods")) else t["depth"]
            byd = bool(MTL and t.get("mods") and info.get("loadByDir"))
            if byd:
                bd //= 2                    # one direction of the block: the address is {slot, direction, word}
            bab = max(1, (bd - 1).bit_length()) if bd > 1 else 0
            if MTL and t.get("mods") and bd & (bd - 1):
                raise AssertionError(f"{name}: table {t['id']} block of {bd} words in {t['depth']}: not slot-addressable")
            hit = f"{inst}_hit"
            L.append(f"    logic {hit}_c, {hit}; logic [{LW - 1}:0] {inst}_rel;")
            L.append(f"    assign {inst}_rel = tw_wi - {LW}'d{base};")
            L.append(f"    assign {hit}_c = tw_wen_p && (tw_wi >= {LW}'d{base}) && (tw_wi < {LW}'d{base + bd * nc});")
            # column-major in the load image: column c holds words [c*depth, (c+1)*depth)
            L.append(f"    logic [{max(1, nc) - 1}:0] {inst}_col_c, {inst}_col; logic [{ab - 1}:0] {inst}_wa_c, {inst}_wa;")
            if MTL and t.get("mods"):
                rel = f"{inst}_rel" if nc == 1 else f"({inst}_col_c ? {LW}'({inst}_rel - {LW}'d{bd}) : {inst}_rel)"
                L.append(f"    assign {inst}_col_c = " + ("'0;" if nc == 1 else f"({inst}_rel >= {LW}'d{bd}) ? 1'b1 : 1'b0;"))
                lowb = f"{bab}'({rel})" if bab else ""
                sb = ab - bab - (1 if byd else 0)
                top = f"tw_sl[{sb - 1}:0]" if sb > 0 else ""
                L.append(f"    assign {inst}_wa_c = {{{', '.join(x for x in (top, 'tw_dr' if byd else '', lowb) if x)}}};")
            elif nc == 1:
                L.append(f"    assign {inst}_col_c = '0; assign {inst}_wa_c = {inst}_rel[{ab - 1}:0];")
            else:
                L.append(f"    assign {inst}_col_c = ({inst}_rel >= {LW}'d{t['depth']}) ? 1'b1 : 1'b0;")
                L.append(f"    assign {inst}_wa_c = {inst}_col_c ? {ab}'({inst}_rel - {LW}'d{t['depth']}) : {inst}_rel[{ab - 1}:0];")
            L.append(f"    always_ff @(posedge clk) begin {hit} <= {hit}_c; {inst}_col <= {inst}_col_c; {inst}_wa <= {inst}_wa_c; end")
            wsl = f"tw_wd_q[{t.get('ldl', 0) * TWL + max(t['cols']) - 1}:{t.get('ldl', 0) * TWL}]"
            # the table's own write registers (the data word too: kept, or all tables of a lane would share one)
            L.append(f"    logic {hit}_q; logic [{max(1, nc) - 1}:0] {inst}_col_q; logic [{ab - 1}:0] {inst}_wa_q;")
            L.append(f"    (* equivalent_register_removal = \"no\" *) logic [{max(t['cols']) - 1}:0] {inst}_wd_q;")
            L.append(f"    always_ff @(posedge clk) begin {hit}_q <= {hit}; {inst}_col_q <= {inst}_col; "
                     f"{inst}_wa_q <= {inst}_wa; {inst}_wd_q <= {wsl}; end")
            conn += [f".we({hit}_q)", f".wa({inst}_wa_q)", f".wcol({inst}_col_q)", f".wd({inst}_wd_q)"]
        conn += [f".q{i}({o})" for i, o in enumerate(outs)]
        L.append(f"    {name}_tab{t['id']} {inst} ({', '.join(conn)});")

    nwire = [0]
    tabOff = {}

    def addr_of(t, frame_expr, lo=None, part=None, aoff=None):
        """Address of table t for frame cycle `frame_expr`: the table's
        significant cycle bits (highest first), DIR on top (per-frame moduli: the
        index of the frame at offset `aoff` above it)."""
        bits = t["bits"]
        body = ""
        if FB and bits:
            nwire[0] += 1
            fw = f"fa{nwire[0]}"
            L.append(f"    logic [{FB - 1}:0] {fw}; assign {fw} = {frame_expr};")
            body = ", ".join(f"{fw}[{b}]" for b in reversed(bits))
        if aoff is not None:                # when the table is read, for the load timing (manifest)
            tabOff.setdefault(t["id"], []).append(aoff)
        parts = ([tag_at(aoff) + (f"[{TGW - 1}:0]" if MTL else "")] if (pf or FD) else []) + \
            (["DIR_r"] if spec.dirPort and not (PD or FD) else []) + ([body] if body else [])
        return f"{{{', '.join(parts)}}}" if parts else "1'b0"

    cur = [f"x_in_{l}" for l in range(P)]
    w = spec.inWidth
    flead = pf["lead"] if pf else ((info.get("unrolled") or {}).get("lead", 0) if FD else 0)
    if flead:
        # the data waits `lead` cycles so the first stage's read-ahead tables already know the frame's modulus
        L.append(f"    // per-frame {'moduli' if pf else 'direction'}: input lead of {flead} cycles")
        for l in range(P):
            L.append(f"    logic [{w - 1}:0] xl_{l};")
            L.append(f"    {dly} #(.W({w}), .D({flead})) xl{l}_dly (.clk(clk), .din(x_in_{l}), .dout(xl_{l}));")
        cur = [f"xl_{l}" for l in range(P)]
    genLat = info["generatorLatency"]
    genDone, gw_of = {}, {}
    # the run-time modulus ports are constant during a job: register them once, then once more per
    # stage (and for the twist), so no single register drives every butterfly across the die
    qw = dict(qports)
    if spec.dirPort and not (PD or FD):
        L.append("    (* max_fanout = 32 *) logic DIR_r;")
        L.append("    always_ff @(posedge clk) DIR_r <= DIR;")
    for qp, w_ in ([] if pf else qports):
        L.append(f"    (* max_fanout = 16 *) logic [{w_ - 1}:0] {qp}_r;")
        L.append(f"    always_ff @(posedge clk) {qp}_r <= {qp};")
    qcopies = set()

    def qsig(tag: str, qp: str) -> str:
        if qp not in qw:
            return qp
        nm = f"{tag}_{qp}"
        if nm not in qcopies:
            qcopies.add(nm)
            L.append(f"    (* max_fanout = 16 *) logic [{qw[qp] - 1}:0] {nm};")
            L.append(f"    always_ff @(posedge clk) {nm} <= {qp}_r;")
        return nm

    def emit_twist(cur, w, comment):
        dp = tw["datapath"]
        pw = dp.wire(dict(dp.outputs)["P"]).bitWidth
        ain = {x.name: x.bitWidth for x in dp.inputs}
        if pf:
            tq = "".join(f", .{x.name}({msig('tw', tw['off'], x.name)})" for x in dp.inputs if x.name not in ("A", "B"))
        else:
            tq = "".join(f", .{x.name}({qsig('twq', x.name)})" for x in dp.inputs if x.name not in ("A", "B"))
        L.append(f"    // {comment}, latency {tw['latency']}")
        for l in range(P):
            if pf and mshare and l >= mshare and l % mshare == 0:
                # the unrolled type: a modulus-table copy per `mshare` lanes of the twist
                tq = "".join(f", .{x.name}({msig(f'twm{l // mshare}', tw['off'], x.name)})"
                             for x in dp.inputs if x.name not in ("A", "B"))
            if tw.get("otf"):
                # on the fly: the lane's two tables read ahead by the generator's latency, one multiplier
                tl, th = tables[tw["tables"][l][0]], tables[tw["tables"][l][1]]
                gw = max(tl["cols"])
                L.append(f"    logic [{gw - 1}:0] tw{l}_lo, tw{l}_hi, tw{l}_w; logic [{pw - 1}:0] tw{l}_p;")
                fe = f"tw{l}_t"
                L.append(f"    logic [{max(FB, 1) - 1}:0] {fe}; assign {fe} = {tsig(tw['off'], 2 + genLat) or chr(48)};")
                ga = tw["off"] - 2 - genLat
                table_inst(tl, f"tw{l}_tl", addr_of(tl, fe, aoff=ga), [f"tw{l}_lo"])
                table_inst(th, f"tw{l}_th", addr_of(th, fe, aoff=ga), [f"tw{l}_hi"])
                gd = gen["datapath"]
                if pf:
                    gq = "".join(f", .{x.name}({msig('twg', tw['off'] - genLat, x.name)})"
                                 for x in gd.inputs if x.name not in ("A", "B"))
                else:
                    gq = "".join(f", .{x.name}({qsig('twq', x.name)})" for x in gd.inputs if x.name not in ("A", "B"))
                L.append(f"    {gd.name} tw{l}_gen (.clk(clk), .A({gen_a(gd, f'tw{l}_lo', gw)}), .B(tw{l}_hi){gq}, .P(tw{l}_w));")
            else:
                t = tables[tw["tables"][l]]
                L.append(f"    logic [{t['cols'][0] - 1}:0] tw{l}_w; logic [{pw - 1}:0] tw{l}_p;")
                table_inst(t, f"tw{l}_tab", addr_of(t, tsig(tw["off"], 2), aoff=tw["off"] - 2), [f"tw{l}_w"])
            a = cur[l] if ain["A"] == w else f"{ain['A']}'({cur[l]})"
            L.append(f"    {dp.name} tw{l}_mul (.clk(clk), .A({a}), .B(tw{l}_w){tq}, .P(tw{l}_p));")
            cur[l] = f"tw{l}_p"
        return cur, pw

    twistIn = tw is not None and tw.get("side") == "input"
    lead = getattr(spec, "leadIn", 0)
    if lead:
        # the lead-in: the tables of the first users are read `lead` cycles before the data arrive
        L.append(f"    // lead-in: inputs delayed {lead} cycles (no table read during reset)")
        for l in range(P):
            L.append(f"    logic [{w - 1}:0] li{l};")
            L.append(f"    {dly} #(.W({w}), .D({lead})) li{l}_dly (.clk(clk), .din({cur[l]}), .dout(li{l}));")
        cur = [f"li{l}" for l in range(P)]
    if twistIn:
        # GS: the input twist (forward psi^k, inverse n^-1) per lane in front of the first stage
        cur, w = emit_twist(cur, w, "input twist: psi^k (forward) / n^-1 (inverse) per lane")
    stchain = {}
    tuse, tcopy = {}, {}
    for s, st in enumerate(spec.stages):
        ex = st["exchange"]
        if ex:
            i, j, D = ex
            nxt = [f"s{s}_e{l}" for l in range(P)]
            L.append(f"    // stage {s}: exchange lane bit {i} with cycle bit {j} (D = {D})")
            L.append(f"    logic [{FB - 1}:0] s{s}_t; assign s{s}_t = {tsig(st['exOff'])};")
            for l0 in range(P):
                if (l0 >> i) & 1:
                    continue
                l1 = l0 | (1 << i)
                b = f"s{s}_p{l0}"
                L.append(f"    logic [{w - 1}:0] {b}_l1d, {b}_s0, {b}_s1, {nxt[l0]}, {nxt[l1]};")
                L.append(f"    {dly} #(.W({w}), .D({D})) {b}_dly1 (.clk(clk), .din({cur[l1]}), .dout({b}_l1d));")
                L.append(f"    assign {b}_s0 = s{s}_t[{j}] ? {b}_l1d : {cur[l0]};")
                L.append(f"    assign {b}_s1 = s{s}_t[{j}] ? {cur[l0]} : {b}_l1d;")
                L.append(f"    {dly} #(.W({w}), .D({D})) {b}_dly0 (.clk(clk), .din({b}_s0), .dout({nxt[l0]}));")
                L.append(f"    assign {nxt[l1]} = {b}_s1;")
            cur = nxt
        ow = st["outWidth"]
        out = [None] * P
        L.append(f"    // stage {s}: {len(st['slots'])} butterflies on lane pairs (bit {st['pairLaneBit']}), "
                 f"latency {st['buLatency']}")
        for k, sl in enumerate(st["slots"]):
            la, lb, mod = sl["laneA"], sl["laneB"], sl["module"]
            bs = spec.modules[mod]
            u = f"s{s}_k{k}"
            ireg = st.get("inReg", 0)

            def reg_in(sig: str, width: int, tag: str, deep: bool = False) -> str:
                # the optional input register of the butterfly (`inputRegister`)
                # deep (2026-11-16): the source is a table of more than one URAM. Vivado then pulls this register
                # into the memory, and the cascade of URAMs drives the multiplier directly (N = 2^17, 5 slots:
                # 4 URAMs + the DSP in one cycle, 314 MHz). dont_touch keeps it a flip-flop behind the cascade.
                if not ireg:
                    return sig
                # kept per butterfly (2026-11-16): butterflies that share a twiddle have the same register input,
                # and merged into one the register sat at one butterfly and drove the multipliers of the others
                L.append(f'    (* equivalent_register_removal = "no", shreg_extract = "no"'
                         f'{", dont_touch = " + chr(34) + "true" + chr(34) if deep else ""} *) logic [{width - 1}:0] {u}_{tag}_q;')
                L.append(f"    always_ff @(posedge clk) {u}_{tag}_q <= {sig};")
                return f"{u}_{tag}_q"
            conn = [".clk(clk)", f".aIn({reg_in(cur[la], w, 'a')})", f".bIn({reg_in(cur[lb], w, 'b')})"]
            src = sl["twiddle"]
            if src is not None and src[0] == "stream":
                # the class's twiddle for frame cycle t is on tw_s<c> at offset t; it is needed at buOff + t
                # (where a table's output would be): one delay chain per class, extended stage by stage
                c = src[1]
                o_need = st["buOff"]
                o_have, sig = stchain.get(c, (0, f"tw_s{c}"))
                if strm.get("aligned"):
                    # the supplier delivers the class's word at this stage's own offset (one stage per class)
                    assert c not in stchain, f"{name}: aligned twiddle port tw_s{c} used by two stages"
                    o_have = o_need
                if o_need > o_have:
                    nsig = f"tws{c}_o{o_need}"
                    L.append(f"    logic [{strm['width'] - 1}:0] {nsig};")
                    L.append(f"    {dly} #(.W({strm['width']}), .D({o_need - o_have})) {nsig}_dly (.clk(clk), .din({sig}), .dout({nsig}));")
                    o_have, sig = o_need, nsig
                stchain[c] = (o_have, sig)
                conn.append(f".W({reg_in(sig, strm['width'], 'w')})")
            elif src is not None and src[0] == "tab":
                t = tables[src[1]]
                if tshare:
                    # one copy per `tshare` users of this table in this stage (same offset, same address)
                    gk = (s, src[1])
                    ti = tuse.get(gk, 0)
                    tuse[gk] = ti + 1
                    tn = f"s{s}_t{src[1]}_c{ti // tshare}"
                    if tn not in tcopy:
                        outs = [f"{tn}_w"] + ([f"{tn}_wp"] if len(t["cols"]) > 1 else [])
                        for o, cw in zip(outs, t["cols"]):
                            L.append(f"    logic [{cw - 1}:0] {o};")
                        table_inst(t, f"{tn}_tab", addr_of(t, tsig(st["buOff"], 2), aoff=st["buOff"] - 2), outs)
                        tcopy[tn] = outs
                    outs = tcopy[tn]
                else:
                    outs = [f"{u}_w"] + ([f"{u}_wp"] if len(t["cols"]) > 1 else [])
                    for o, cw in zip(outs, t["cols"]):
                        L.append(f"    logic [{cw - 1}:0] {o};")
                    table_inst(t, f"{u}_tab", addr_of(t, tsig(st["buOff"], 2), aoff=st["buOff"] - 2), outs)
                conn.append(f".W({reg_in(outs[0], t['cols'][0], 'w', deep=t['depth'] * max(t['cols']) > 4096 * 72)})")
                if len(outs) > 1:
                    conn.append(f".WP({reg_in(outs[1], t['cols'][1], 'wp')})")
            elif src is not None and src[0] == "rec":
                # root recurrence (Kim et al.): y(t) = t mod 2^k < D ? base[t mod 2^k] : y(t-D) * u, where the
                # loop is the multiplier (latency D-1) and the register y; the output is at buOff like a table's
                key = (s, sl["gen"])
                g = f"s{s}g{sl['gen']}"
                if key not in genDone:
                    tb_, tu_ = tables[src[1]], tables[src[2]]
                    D, kk = info["rec"]["D"], info["rec"]["k"][sl["gen"]]
                    o = st["buOff"]
                    gw = max(tb_["cols"])
                    L.append(f"    // stage {s} twiddle class {sl['gen']}: recurrence over 2^{kk} cycles, D = {D}")
                    L.append(f"    logic [{gw - 1}:0] {g}_b, {g}_u, {g}_p, {g}_y; logic {g}_sel;")
                    table_inst(tb_, f"{g}_tb", addr_of(tb_, tsig(o, 3), aoff=o - 3), [f"{g}_b"])
                    table_inst(tu_, f"{g}_tu", addr_of(tu_, "", aoff=o - 2), [f"{g}_u"])
                    L.append(f"    logic [{FB - 1}:0] {g}_j; assign {g}_j = {tsig(o, 2)};")
                    L.append(f"    always_ff @(posedge clk) {g}_sel <= ({g}_j[{kk - 1}:0] < {kk}'d{D});")
                    L.append(f"    always_ff @(posedge clk) {g}_y <= {g}_sel ? {g}_b : {g}_p;")
                    gd = gen["datapath"]
                    if pf:
                        gq = "".join(f", .{x.name}({msig(f's{s}r', o, x.name)})" for x in gd.inputs if x.name not in ("A", "B"))
                    else:
                        gq = "".join(f", .{x.name}({qsig(f's{s}q', x.name)})" for x in gd.inputs if x.name not in ("A", "B"))
                    L.append(f"    {gd.name} {g}_mul (.clk(clk), .A({gen_a(gd, f'{g}_y', gw)}), .B({g}_u){gq}, .P({g}_p));")
                    genDone[key] = f"{g}_y"
                    gw_of[key] = gw
                conn.append(f".W({reg_in(genDone[key], gw_of[key], 'w')})")
            elif src is not None:
                # on the fly: two tables read ahead by the generator's latency, one multiplier
                key = (s, sl["gen"])
                g = f"s{s}_g{sl['gen']}"
                if key not in genDone:
                    tl, th = tables[src[1]], tables[src[2]]
                    lo = None
                    gw = max(tl["cols"])
                    L.append(f"    logic [{gw - 1}:0] {g}_lo, {g}_hi, {g}_w;")
                    fe = f"{g}_t"
                    L.append(f"    logic [{max(FB, 1) - 1}:0] {fe}; assign {fe} = {tsig(st['buOff'], 2 + genLat) or chr(48)};")
                    ga = st["buOff"] - 2 - genLat
                    table_inst(tl, f"{g}_tl", addr_of(tl, fe, lo, "lo", aoff=ga), [f"{g}_lo"])
                    table_inst(th, f"{g}_th", addr_of(th, fe, lo, "hi", aoff=ga), [f"{g}_hi"])
                    gd = gen["datapath"]
                    if pf:
                        gq = "".join(f", .{x.name}({msig(f's{s}g', st['buOff'] - genLat, x.name)})"
                                     for x in gd.inputs if x.name not in ("A", "B"))
                    else:
                        gq = "".join(f", .{x.name}({qsig(f's{s}q', x.name)})" for x in gd.inputs if x.name not in ("A", "B"))
                    L.append(f"    {gd.name} {g}_mul (.clk(clk), .A({gen_a(gd, f'{g}_lo', gw)}), .B({g}_hi){gq}, .P({g}_w));")
                    genDone[key] = f"{g}_w"
                    gw_of[key] = gw
                conn.append(f".W({reg_in(genDone[key], gw_of[key], 'w')})")
            msite = f"s{s}" + (f"m{k // mshare}" if (pf and mshare and k >= mshare) else "")
            for pn, _ in bs.extraPorts:
                if pn == "DIR" and (PD or FD):
                    # the unified CT/GS butterfly (UnrolledNTTScheme(unified=True)): its frame's direction
                    conn.append(f".DIR({tag_at(st['buOff'] + ireg)}[0])")
                elif pn == "DIR":
                    raise AssertionError(f"{name}: the unified butterfly takes DIR per transform (frameDir)")
                elif pn not in ("W", "WP"):
                    conn.append(f".{pn}({msig(msite, st['buOff'] + ireg, pn) if pf else qsig(f's{s}q', pn)})")
            xa, xb = f"{u}_x", f"{u}_y"
            L.append(f"    logic [{bs.aOutBitWidth - 1}:0] {xa}r; logic [{bs.bOutBitWidth - 1}:0] {xb}r;")
            conn += [f".aOut({xa}r)", f".bOut({xb}r)"]
            L.append(f"    {mod} {u} ({', '.join(conn)});")
            extra_lat = st["buLatency"] - sl["latency"]
            halve = st.get("halve", 0)
            for src_, dst, bw in ((f"{xa}r", f"s{s}_o{la}", bs.aOutBitWidth), (f"{xb}r", f"s{s}_o{lb}", bs.bOutBitWidth)):
                L.append(f"    logic [{ow - 1}:0] {dst};")
                v = src_ if bw == ow else f"{{{ow - bw}'d0, {src_}}}"
                if halve:
                    # inverseScale='stage': x2^-1 mod q in inverse mode, h = (x >> 1) + x[0]*(q+1)/2, registered
                    # (the register is there in both directions, so the latency does not depend on DIR)
                    if pf:          # the frame's (q+1)/2, from the modulus table at the halver's offset
                        qh = msig(f"s{s}h{sl['latency']}" + (f"m{k // mshare}" if (mshare and k >= mshare) else ""),
                                  st["buOff"] + ireg + sl["latency"], "QHALF")
                    else:
                        qh = qsig(f"s{s}q", "QHALF") if "QHALF" in qw else f"{ow}'d{(spec.q + 1) // 2}"
                    hv = f"{dst}_h"
                    L.append(f"    logic [{ow - 1}:0] {hv}_x, {hv};")
                    L.append(f"    assign {hv}_x = {v};")
                    if PD or FD:    # the direction of the frame at the halver
                        on = f"{tag_at(st['buOff'] + ireg + sl['latency'])}[0]"
                    else:
                        on = "DIR_r" if spec.dirPort else "1'b1"
                    L.append(f"    always_ff @(posedge clk) {hv} <= {on} ? ({ow}'({hv}_x >> 1) + ({hv}_x[0] ? {ow}'({qh}) : {ow}'d0)) : {hv}_x;")
                    v = hv
                if extra_lat:
                    L.append(f"    {dly} #(.W({ow}), .D({extra_lat})) {dst}_bal (.clk(clk), .din({v}), .dout({dst}));")
                else:
                    L.append(f"    assign {dst} = {v};")
            out[la], out[lb] = f"s{s}_o{la}", f"s{s}_o{lb}"
        cur, w = out, ow
    if tw is not None and not twistIn:
        cur, w = emit_twist(cur, w, "output twist: n^-1 (psi^-k) per lane")
    ro = info.get("reorder")              # outputOrder='natural' (StreamingNTTScheme.reorderPlan); absent: nothing
    if ro is not None and not ro["ram"]:
        L.append("    // natural-order output: lane wiring")
        nat = [None] * P
        for l in range(P):
            nat[sum(((l >> i) & 1) << d for i, d in ro["stayLane"])] = cur[l]
        cur = nat
    elif ro is not None:
        with open(os.path.join(rtl, f"{name}_oram.sv"), "w", encoding="utf-8") as f:
            f.write(_emit_reorder_ram(f"{name}_oram"))
        L.append(f"    // natural-order output: {P} banks of {2 * F} words (two frames), read one frame behind the write")
        L.append(f"    (* max_fanout = 64 *) logic [{FB - 1}:0] ro_t, ro_wt, ro_rt;")
        L.append("    (* max_fanout = 64 *) logic ro_par;")
        L.append(f"    always_ff @(posedge clk) begin ro_t <= {tsig(ro['base'], 1)}; ro_wt <= ro_t; ro_rt <= ro_wt; end")
        L.append(f"    always_ff @(posedge clk) if (rst) ro_par <= 1'b0; else if (ro_t == {FB}'d0) ro_par <= ~ro_par;")
        src = list(cur)
        for k, (a, b, da, db) in enumerate(ro["pairs"]):     # write side: swap on lane bit a when cycle bit b is set
            nxt = []
            for l in range(P):
                sg = f"ro_ws{k}_{l}"
                L.append(f"    logic [{w - 1}:0] {sg};")
                L.append(f"    assign {sg} = ro_t[{b}] ? {src[l ^ (1 << a)]} : {src[l]};")
                nxt.append(sg)
            src = nxt
        for p in range(P):
            L.append(f"    logic [{w - 1}:0] ro_w_{p}, ro_r_{p};")
            L.append(f"    always_ff @(posedge clk) ro_w_{p} <= {src[p]};")
            bits = {j: f"ro_wt[{d}]" for j, d in ro["stayCyc"]}
            for a, b, da, db in ro["pairs"]:
                bits[b] = f"{'~' if (p >> a) & 1 else ''}ro_wt[{da}]"
            ra = ", ".join(["~ro_par"] + [bits[j] for j in reversed(range(FB))])
            L.append(f"    {name}_oram #(.W({w}), .A({FB + 1})) ro_m{p} (.clk(clk), .wa({{ro_par, ro_wt}}), .wd(ro_w_{p}), "
                     f".ra({{{ra}}}), .rd(ro_r_{p}));")
        src = [f"ro_r_{p}" for p in range(P)]
        for k, (a, b, da, db) in enumerate(ro["pairs"]):     # read side: swap on bank bit a when out-cycle bit da is set
            nxt = []
            for p in range(P):
                sg = f"ro_rs{k}_{p}"
                L.append(f"    logic [{w - 1}:0] {sg};")
                L.append(f"    assign {sg} = ro_rt[{da}] ? {src[p ^ (1 << a)]} : {src[p]};")
                nxt.append(sg)
            src = nxt
        nat = [None] * P
        for p in range(P):
            l2 = sum(((p >> i) & 1) << d for i, d in ro["stayLane"]) + sum(((p >> a) & 1) << db for a, b, da, db in ro["pairs"])
            L.append(f"    logic [{w - 1}:0] ro_y_{l2};")
            L.append(f"    always_ff @(posedge clk) ro_y_{l2} <= {src[p]};")
            nat[l2] = f"ro_y_{l2}"
        cur = nat
    for l in range(P):
        L.append(f"    assign y_out_{l} = {cur[l]};")
    L.append("endmodule")
    with open(os.path.join(rtl, f"{name}.sv"), "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")

    test = 0
    if x_in is not None:
        test = len(x_in[0])
        tv = "testvectors"
        os.makedirs(tv, exist_ok=True)
        for l in range(P):
            with open(os.path.join(tv, f"x_{l}.txt"), "w") as f:
                f.write("".join(to_twos_complement_hex(v, spec.inWidth) + "\n" for v in x_in[l]))
            with open(os.path.join(tv, f"y_{l}.txt"), "w") as f:
                f.write("".join(to_twos_complement_hex(v, spec.outWidth) + "\n" for v in y_out[l]))
        if loadW:
            with open(os.path.join(tv, "tw_load.txt"), "w") as f:
                f.write("".join(to_twos_complement_hex(v, TWW) + "\n" for v in tb["load"]))
        if pf:
            with open(os.path.join(tv, "midx.txt"), "w") as f:
                f.write("".join(f"{v:x}\n" for v in tb["midx"]))
            if spec.dirPort:
                with open(os.path.join(tv, "dir.txt"), "w") as f:
                    f.write("".join(f"{v:x}\n" for v in tb["dirs"]))
        if strm:
            for c in range(strm["classes"]):
                with open(os.path.join(tv, f"ts_{c}.txt"), "w") as f:
                    f.write("".join(f"{row[c]:x}\n" for row in tb["stream"]))
        with open(os.path.join(rtl, f"{name}_tb.sv"), "w", encoding="utf-8") as f:
            f.write(_emit_stream_tb(spec, test, tb, TWW if loadW else 0))
    manifest = {"top_name": name, "n": spec.n, "lanes": P, "frame_cycles": F, "latency": spec.latency,
                "modules": sorted(spec.modules), "tables": len(tables), "load_words": loadW,
                "q_ports": [p for p, _ in qports], "q_port_widths": [w for _, w in qports],
                "in_width": spec.inWidth, "out_width": spec.outWidth, "dir_port": spec.dirPort,
                "tw_width": TWW if loadW else 0, "test_cycles": test,
                "load_lanes": info.get("loadLanes", 1), "load_by_dir": bool(info.get("loadByDir")),
                "stream_classes": strm["classes"] if strm else 0, "stream_width": strm["width"] if strm else 0,
                "stages": [{"exchange": st["exchange"], "buLatency": st["buLatency"]} for st in spec.stages]}
    if pf:
        manifest.update(moduli=len(pf["moduli"]), modulus_index_bits=IW, lead=pf["lead"], per_frame_dir=bool(PD),
                        loadable_moduli=MTL)
    if MTL:
        # per RAM table: where its block sits in the load image and at which offsets (cycles after the first beat
        # of a polynomial) it is read, for the timing of a load that follows the data
        manifest["slot_tables"] = [{"id": t["id"], "base": t["base"],
                                    "words": (t["depth"] // t["mods"] // (2 if info.get("loadByDir") else 1)) * len(t["cols"]),
                                    "offsets": sorted(set(tabOff.get(t["id"], [])))}
                                   for t in tables if t["mode"] == "ram"]
    if FD:
        manifest.update(frame_dir=True, lead=flead)
    with open("manifest.json", "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    return manifest


def _emit_stream_tb(spec, test: int, tb: dict, TWW: int) -> str:
    P, LAT = spec.lanes, spec.latency
    qports = spec.roms["qPorts"]
    loadW = spec.roms["loadWords"]
    pf = spec.roms.get("perFrame")
    L = ["`timescale 1ns / 1ps", f"module {spec.name}_tb ();", "    logic clk = 1'b0;", "    always #5 clk = ~clk;",
         "    logic rst;"]
    PDt = 1 if (pf and spec.dirPort) else 0
    if spec.dirPort and PDt:
        L.append(f"    logic DIR; logic di_ts [{len(tb['midx'])}];")
    elif spec.dirPort:
        L.append(f"    logic DIR = 1'b{tb['dir']};")
    MTL = bool(pf and pf.get("loadable"))
    if pf:
        IW, NF = pf["indexBits"], len(tb["midx"])
        L.append(f"    logic [{IW - 1}:0] MIDX; logic [{IW - 1}:0] mi_ts [{NF}];")
    if MTL:                                 # the constants of each frame's modulus, given with the frame
        for qp, w in qports:
            L.append(f"    logic [{w - 1}:0] mq_{qp}; logic [{w - 1}:0] mq_{qp}_ts [{NF}];")
        L.append("    initial begin")
        for f_, vals in enumerate(tb["mq"]):
            L.append("        " + " ".join(f"mq_{qp}_ts[{f_}] = {_sv_const(vals[qp], w)};" for qp, w in qports))
        L.append("    end")
    for qp, w in ([] if pf else qports):
        L.append(f"    logic [{w - 1}:0] {qp} = {_sv_const(tb['q'][qp], w)};")
    NIMG = len(tb.get("images", [])) if MTL else 1
    if loadW:
        L.append(f"    logic tw_rst, tw_wen; logic [{TWW - 1}:0] tw_wdata; logic [{TWW - 1}:0] tw_ts [{loadW * max(1, NIMG)}];")
        if MTL:
            L.append(f"    logic [{IW - 1}:0] tw_slot;")
        if MTL and spec.roms.get("loadByDir"):
            L.append("    logic tw_dir = 1'b0;")
    strm = spec.roms.get("stream")
    NS = strm["classes"] if strm else 0
    for c in range(NS):
        L.append(f"    logic [{strm['width'] - 1}:0] tw_s{c}; logic [{strm['width'] - 1}:0] ts_ts_{c} [{test}];")
    for l in range(P):
        L.append(f"    logic [{spec.inWidth - 1}:0] x_in_{l}; logic [{spec.inWidth - 1}:0] x_ts_{l} [{test}];")
        L.append(f"    logic [{spec.outWidth - 1}:0] y_out_{l}; logic [{spec.outWidth - 1}:0] y_ts_{l} [{test}];")
    L.append("    initial begin")
    for l in range(P):
        L.append(f'        $readmemh("../../../../../testvectors/x_{l}.txt", x_ts_{l});')
        L.append(f'        $readmemh("../../../../../testvectors/y_{l}.txt", y_ts_{l});')
    if loadW:
        L.append('        $readmemh("../../../../../testvectors/tw_load.txt", tw_ts);')
    if pf:
        L.append('        $readmemh("../../../../../testvectors/midx.txt", mi_ts);')
    if PDt:
        L.append('        $readmemh("../../../../../testvectors/dir.txt", di_ts);')
    for c in range(NS):
        L.append(f'        $readmemh("../../../../../testvectors/ts_{c}.txt", ts_ts_{c});')
    L.append("    end")
    conn = [".clk(clk)", ".rst(rst)"] + ([".DIR(DIR)"] if spec.dirPort else [])
    conn += [".MIDX(MIDX)"] if pf else [f".{qp}({qp})" for qp, _ in qports]
    if MTL:
        conn += [f".mq_{qp}(mq_{qp})" for qp, _ in qports]
    if loadW:
        conn += [".tw_rst(tw_rst)", ".tw_wen(tw_wen)", ".tw_wdata(tw_wdata)"] + ([".tw_slot(tw_slot)"] if MTL else [])
        conn += [".tw_dir(tw_dir)"] if (MTL and spec.roms.get("loadByDir")) else []
    conn += [f".tw_s{c}(tw_s{c})" for c in range(NS)]
    conn += [f".x_in_{l}(x_in_{l})" for l in range(P)] + [f".y_out_{l}(y_out_{l})" for l in range(P)]
    L.append(f"    {spec.name} DUT ({', '.join(conn)});")
    L.append("    int c, bad, checked;")
    L.append("    initial begin")
    L.append("        bad = 0; checked = 0; rst = 1'b1;")
    for l in range(P):
        L.append(f"        x_in_{l} = '0;")
    for c in range(NS):
        L.append(f"        tw_s{c} = '0;")
    if pf:
        L.append("        MIDX = mi_ts[0];")
    if PDt:
        L.append("        DIR = di_ts[0];")
    if MTL:
        L += [f"        mq_{qp} = mq_{qp}_ts[0];" for qp, _ in qports]
    if loadW and MTL:
        # the slots the first frames need, filled before frame 0 (one load after the other)
        L.append("        tw_rst = 1'b0; tw_wen = 1'b0; tw_wdata = '0; tw_slot = '0;")
        L.append("        repeat (2) @(posedge clk);")
        for cw, k, img, *dd in tb["loads"]:
            if cw < 0:
                L.append(f"        #1 tw_rst = 1'b1; tw_slot = {IW}'d{k};" + (f" tw_dir = 1'b{dd[0]};" if dd else "")
                         + " @(posedge clk); #1 tw_rst = 1'b0;")
                L.append(f"        for (c = 0; c < {loadW}; c++) begin tw_wen = 1'b1; tw_wdata = tw_ts[{img * loadW} + c]; @(posedge clk); #1; end")
                L.append("        tw_wen = 1'b0;")
    elif loadW:
        L.append("        tw_rst = 1'b1; tw_wen = 1'b0; tw_wdata = '0;")
        L.append("        repeat (2) @(posedge clk);")
        L.append("        #1 tw_rst = 1'b0;")
        L.append(f"        for (c = 0; c < {loadW}; c++) begin tw_wen = 1'b1; tw_wdata = tw_ts[c]; @(posedge clk); #1; end")
        L.append("        tw_wen = 1'b0;")
    # past the global set/reset pulse (100 ns), during which the DSP58 models hold their registers
    L.append("        repeat (30) @(posedge clk);")
    L.append(f"        for (c = 0; c < {test + LAT}; c++) begin")
    L.append("            #1;")
    L.append("            rst = 1'b0;")
    if loadW and MTL:                       # a slot filled while the frames of other slots run
        L.append("            tw_rst = 1'b0; tw_wen = 1'b0;")
        for cw, k, img, *dd in tb["loads"]:
            if cw >= 0:
                L.append(f"            if (c == {cw - 1}) begin tw_rst = 1'b1; tw_slot = {IW}'d{k};"
                         + (f" tw_dir = 1'b{dd[0]};" if dd else "") + " end")
                L.append(f"            if (c >= {cw} && c < {cw + loadW}) begin tw_wen = 1'b1; tw_wdata = tw_ts[{img * loadW} + c - {cw}]; end")
    L.append(f"            if (c < {test}) begin")
    for l in range(P):
        L.append(f"                x_in_{l} = x_ts_{l}[c];")
    if pf:
        L.append(f"                MIDX = mi_ts[c / {spec.frameCycles}];")
    if MTL:
        L += [f"                mq_{qp} = mq_{qp}_ts[c / {spec.frameCycles}];" for qp, _ in qports]
    if PDt:
        L.append(f"                DIR = di_ts[c / {spec.frameCycles}];")
    for c in range(NS):
        L.append(f"                tw_s{c} = ts_ts_{c}[c];")
    L.append("            end")
    L.append(f"            if (c >= {LAT}) begin")
    L.append("                #2;")
    for l in range(P):
        L.append(f"                if (y_out_{l} !== y_ts_{l}[c - {LAT}]) begin bad++; "
                 f"if (bad < 10) $display(\"WRONG cycle %0d lane {l}: got %h want %h\", c - {LAT}, y_out_{l}, y_ts_{l}[c - {LAT}]); end")
    L.append("                checked++;")
    L.append("            end")
    L.append("            @(posedge clk);")
    L.append("        end")
    L.append("        if (bad == 0) begin $display(\"SUCCESS!\"); $display(\"PASS All %0d Testvectors!\", checked); end")
    L.append("        else begin $display(\"TO BE DEBUGGED...\"); $display(\"FAILED: %0d lane values wrong\", bad); end")
    L.append("        $finish();")
    L.append("    end")
    L.append("endmodule")
    return "\n".join(L) + "\n"


# ---------------------------------------------------------------------------------------------------------
# outReady (2026-11-14): the streaming NTT behind in_valid/in_ready and out_valid/out_ready
# ---------------------------------------------------------------------------------------------------------

def _emit_obuf_ram(name: str) -> str:
    """`<name> #(W, A)`: simple dual-port RAM of 2^A words with a write enable and a read enable (registered
    read): one lane of the output buffer of the streaming NTT with outReady."""
    return f"""`timescale 1ns / 1ps
module {name} #(parameter int W = 8, parameter int A = 4) (
    input  logic clk,
    input  logic we,
    input  logic [A-1:0] wa,
    input  logic [W-1:0] wd,
    input  logic re,
    input  logic [A-1:0] ra,
    output logic [W-1:0] rd
    );
    logic [W-1:0] mem [1 << A];
    always_ff @(posedge clk) begin
        if (we) mem[wa] <= wd;
        if (re) rd <= mem[ra];
    end
endmodule
"""


def StreamReady_RTL_gen(name: str, spec, plan: dict, stim: dict | None = None) -> dict:
    """The wrapper `<name>` around the streaming core `spec.name` (= `<name>_k`, already emitted into
    RTL_generated/ of the cwd by StreamNTT_RTL_gen): every core port passes through, plus `in_valid`,
    `in_ready` (one handshake per polynomial slot) and `out_valid`, `out_ready` (per beat). `plan` is
    StreamingNTTScheme.readyPlan(). With `stim` (per-cycle stimulus and expectation from
    StreamingNTTScheme.readyRun) a testbench that checks in_ready, out_valid and every valid beat on every
    cycle."""
    from rtl_gen.hweval import parse_module_ports
    from rtl_gen.utils import to_twos_complement_hex
    rtl = "RTL_generated"
    core = spec.name
    P, F, W = spec.lanes, spec.frameCycles, spec.outWidth
    D, AB, CB, J, AT = plan["depth"], plan["addrBits"], plan["creditBits"], plan["tap"], plan["at"]
    FB = max(1, (F - 1).bit_length())
    with open(os.path.join(rtl, f"{core}.sv"), encoding="utf-8") as f:
        cports = parse_module_ports(f.read(), core)
    for stale in [os.path.join(rtl, f"{name}.sv"), os.path.join(rtl, f"{name}_tb.sv")]:
        if os.path.isfile(stale):
            os.remove(stale)
    obuf = f"{name}_obuf"
    with open(os.path.join(rtl, f"{obuf}.sv"), "w", encoding="utf-8") as f:
        f.write(_emit_obuf_ram(obuf))

    def decl(p):
        return f"    {p.direction:<6} logic {'[%d:0] ' % (p.width - 1) if p.width > 1 else ''}{p.name}"
    ins = [p for p in cports if p.direction == "input"]
    L = ["`timescale 1ns / 1ps",
         f"// {name}: {core} (streaming NTT, latency {plan['latency']}) with output backpressure: a buffer of {D} "
         f"polynomials ({D * F} beats) and a credit count; a polynomial enters on the first cycle of a frame slot "
         f"when in_valid and in_ready; first beat out {plan['outLatency']} cycles later when out_ready is high",
         f"module {name} ("]
    ports = [decl(p) for p in ins]
    ports += ["    input  logic in_valid", "    output logic in_ready", "    output logic out_valid",
              "    input  logic out_ready"]
    ports += [f"    output logic [{W - 1}:0] y_out_{l}" for l in range(P)]
    L.append(",\n".join(ports))
    L.append("    );")
    for l in range(P):
        L.append(f"    logic [{W - 1}:0] k_y_{l};")
    conn = [f".{p.name}({p.name})" for p in ins] + [f".y_out_{l}(k_y_{l})" for l in range(P)]
    L.append(f"    {core} u_core ({', '.join(conn)});")
    L.append(f"    logic [{FB - 1}:0] rb_cnt;                 // frame cycle, in step with the core's counter")
    L.append(f"    logic [{CB - 1}:0] rb_infl;                // polynomials accepted and not yet fully read")
    L.append(f"    logic [{J}:0] rb_vsh;                      // accepted flag of the last slots")
    L.append("    (* max_fanout = 64 *) logic rb_vy;        // the core's output is a beat of an accepted polynomial")
    L.append(f"    (* max_fanout = 64 *) logic [{AB - 1}:0] rb_wp, rb_rp;")
    L.append(f"    logic [{FB - 1}:0] rb_rcnt;")
    L.append("    logic rb_rv, rb_ov;")
    L.append("    wire rb_acc = in_valid && in_ready && (rb_cnt == '0);")
    L.append("    wire rb_pop = rb_ov && out_ready;")
    L.append(f"    wire rb_dec = rb_pop && (rb_rcnt == {FB}'d{F - 1});")
    L.append("    wire rb_oload = rb_rv && (!rb_ov || out_ready);")
    L.append("    (* max_fanout = 64 *) wire rb_ren = (rb_wp != rb_rp) && (!rb_rv || rb_oload);")
    L.append("    always_ff @(posedge clk) begin")
    L.append("        if (rst) begin")
    L.append("            rb_cnt <= '0; in_ready <= 1'b1; rb_infl <= '0; rb_vsh <= '0; rb_vy <= 1'b0;")
    L.append("            rb_wp <= '0; rb_rp <= '0; rb_rcnt <= '0; rb_rv <= 1'b0; rb_ov <= 1'b0;")
    L.append("        end else begin")
    L.append(f"            rb_cnt <= (rb_cnt == {FB}'d{F - 1}) ? '0 : rb_cnt + 1'b1;")
    L.append(f"            if (rb_cnt == {FB}'d{F - 1}) in_ready <= (rb_infl < {CB}'d{D});")
    L.append("            else if (rb_cnt == '0) in_ready <= rb_acc;")
    L.append("            rb_infl <= rb_infl + rb_acc - rb_dec;")
    if J:
        L.append(f"            if (rb_cnt == '0) rb_vsh <= {{rb_vsh[{J - 1}:0], rb_acc}};")
    else:
        L.append("            if (rb_cnt == '0) rb_vsh <= rb_acc;")
    L.append(f"            if (rb_cnt == {FB}'d{AT}) rb_vy <= rb_vsh[{J}];")
    L.append("            if (rb_vy) rb_wp <= rb_wp + 1'b1;")
    L.append("            if (rb_ren) begin rb_rp <= rb_rp + 1'b1; rb_rv <= 1'b1; end")
    L.append("            else if (rb_oload) rb_rv <= 1'b0;")
    L.append("            if (rb_oload) rb_ov <= 1'b1;")
    L.append("            else if (out_ready) rb_ov <= 1'b0;")
    L.append(f"            if (rb_pop) rb_rcnt <= (rb_rcnt == {FB}'d{F - 1}) ? '0 : rb_rcnt + 1'b1;")
    L.append("        end")
    L.append("    end")
    L.append("    assign out_valid = rb_ov;")
    for l in range(P):
        L.append(f"    logic [{W - 1}:0] rb_rd_{l};")
        L.append(f"    {obuf} #(.W({W}), .A({AB})) rb_m{l} (.clk(clk), .we(rb_vy), .wa(rb_wp), .wd(k_y_{l}), "
                 f".re(rb_ren), .ra(rb_rp), .rd(rb_rd_{l}));")
        L.append(f"    always_ff @(posedge clk) if (rb_oload) y_out_{l} <= rb_rd_{l};")
    L.append("endmodule")
    with open(os.path.join(rtl, f"{name}.sv"), "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")

    with open("manifest.json", encoding="utf-8") as f:
        manifest = json.load(f)
    manifest.update(top_name=name, core=core, out_ready=True, out_depth=D, core_latency=plan["latency"],
                    latency=plan["outLatency"])
    if stim is not None:
        N = stim["cycles"]
        tv = "testvectors"
        os.makedirs(tv, exist_ok=True)

        def put(fn, vals, w=None):
            with open(os.path.join(tv, fn), "w") as f:
                f.write("".join((to_twos_complement_hex(v, w) if w else f"{v:x}") + "\n" for v in vals))
        for l in range(P):
            put(f"x_{l}.txt", stim["x"][l], spec.inWidth)
            put(f"y_{l}.txt", stim["y"][l], W)
        for k in ("iv", "ordy", "ir", "ov"):
            put(f"{k}.txt", stim[k])
        widths = {p.name: p.width for p in ins}
        static = dict(stim.get("static", {}))          # port -> value held for the whole run
        percyc = dict(stim.get("perCycle", {}))        # port -> value per cycle
        for pn, vals in percyc.items():
            put(f"p_{pn}.txt", vals)
        load = stim.get("load") or []
        if load:
            put("tw_load.txt", load, widths["tw_wdata"])
        T = ["`timescale 1ns / 1ps", f"module {name}_tb ();", "    logic clk = 1'b0;", "    always #5 clk = ~clk;",
             "    logic rst, in_valid, in_ready, out_valid, out_ready;",
             f"    logic iv_ts [{N}]; logic or_ts [{N}]; logic ir_ts [{N}]; logic ov_ts [{N}];"]
        for p in ins:
            if p.name in ("clk", "rst") or p.name.startswith("x_in_"):
                continue
            T.append(f"    logic {'[%d:0] ' % (p.width - 1) if p.width > 1 else ''}{p.name};")
            if p.name in percyc:
                T.append(f"    logic [{p.width - 1}:0] pc_{p.name} [{N}];")
        if load:
            T.append(f"    logic [{widths['tw_wdata'] - 1}:0] tw_ts [{len(load)}];")
        for l in range(P):
            T.append(f"    logic [{spec.inWidth - 1}:0] x_in_{l}; logic [{spec.inWidth - 1}:0] x_ts_{l} [{N}];")
            T.append(f"    logic [{W - 1}:0] y_out_{l}; logic [{W - 1}:0] y_ts_{l} [{N}];")
        T.append("    initial begin")
        rd = '        $readmemh("../../../../../testvectors/%s.txt", %s);'
        for l in range(P):
            T.append(rd % (f"x_{l}", f"x_ts_{l}"))
            T.append(rd % (f"y_{l}", f"y_ts_{l}"))
        for k, a in (("iv", "iv_ts"), ("ordy", "or_ts"), ("ir", "ir_ts"), ("ov", "ov_ts")):
            T.append(rd % (k, a))
        for pn in percyc:
            T.append(rd % (f"p_{pn}", f"pc_{pn}"))
        if load:
            T.append(rd % ("tw_load", "tw_ts"))
        T.append("    end")
        conn = [f".{p.name}({p.name})" for p in ins]
        conn += [".in_valid(in_valid)", ".in_ready(in_ready)", ".out_valid(out_valid)", ".out_ready(out_ready)"]
        conn += [f".y_out_{l}(y_out_{l})" for l in range(P)]
        T.append(f"    {name} DUT ({', '.join(conn)});")
        T.append("    int c, bad, checked;")
        T.append("    initial begin")
        T.append("        bad = 0; checked = 0; rst = 1'b1; in_valid = 1'b0; out_ready = 1'b0;")
        for l in range(P):
            T.append(f"        x_in_{l} = '0;")
        for p in ins:
            if p.name in ("clk", "rst") or p.name.startswith("x_in_") or p.name in ("tw_rst", "tw_wen", "tw_wdata"):
                continue
            if p.name in percyc:
                T.append(f"        {p.name} = pc_{p.name}[0];")
            else:
                T.append(f"        {p.name} = {_sv_const(static.get(p.name, 0), p.width)};")
        if "tw_wdata" in widths:
            T.append("        tw_rst = 1'b1; tw_wen = 1'b0; tw_wdata = '0;")
            T.append("        repeat (2) @(posedge clk);")
            T.append("        #1 tw_rst = 1'b0;")
            T.append(f"        for (c = 0; c < {len(load)}; c++) begin tw_wen = 1'b1; tw_wdata = tw_ts[c]; "
                     "@(posedge clk); #1; end")
            T.append("        tw_wen = 1'b0;")
        T.append("        repeat (30) @(posedge clk);")
        T.append(f"        for (c = 0; c < {N}; c++) begin")
        T.append("            #1;")
        T.append("            rst = 1'b0; in_valid = iv_ts[c]; out_ready = or_ts[c];")
        for l in range(P):
            T.append(f"            x_in_{l} = x_ts_{l}[c];")
        for pn in percyc:
            T.append(f"            {pn} = pc_{pn}[c];")
        T.append("            #2;")
        T.append("            if (in_ready !== ir_ts[c]) begin bad++; if (bad < 10) "
                 "$display(\"WRONG cycle %0d in_ready: got %b want %b\", c, in_ready, ir_ts[c]); end")
        T.append("            if (out_valid !== ov_ts[c]) begin bad++; if (bad < 10) "
                 "$display(\"WRONG cycle %0d out_valid: got %b want %b\", c, out_valid, ov_ts[c]); end")
        T.append("            if (ov_ts[c]) begin")
        for l in range(P):
            T.append(f"                if (y_out_{l} !== y_ts_{l}[c]) begin bad++; if (bad < 10) "
                     f"$display(\"WRONG cycle %0d lane {l}: got %h want %h\", c, y_out_{l}, y_ts_{l}[c]); end")
        T.append("                checked++;")
        T.append("            end")
        T.append("            @(posedge clk);")
        T.append("        end")
        T.append("        if (bad == 0) begin $display(\"SUCCESS!\"); $display(\"PASS All %0d Testvectors!\", checked); end")
        T.append("        else begin $display(\"TO BE DEBUGGED...\"); $display(\"FAILED: %0d lane values wrong\", bad); end")
        T.append("        $finish();")
        T.append("    end")
        T.append("endmodule")
        with open(os.path.join(rtl, f"{name}_tb.sv"), "w", encoding="utf-8") as f:
            f.write("\n".join(T) + "\n")
        manifest["test_cycles"] = N
    with open("manifest.json", "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    return manifest
