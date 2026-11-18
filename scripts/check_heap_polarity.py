#!/usr/bin/env python3
"""check_heap_polarity.py -- random heaps with random inverted and constant bits.

Each design is a compressor tree generated with `input_kinds` set at random. Its
testbench drives the wires the way a butterfly wrapper does (the plain source
bit, or a tied 0 for a constant) and checks comp_out against the arithmetic sum
of the bits' true values, at the latency built. Shapes come from the compressor
campaign's data when present, plus random heaps tall enough to reach the large
GPCs, each at 0, 1 and 2 stages.

    python scripts/check_heap_polarity.py --work <folder> [--designs 90]
"""
from __future__ import annotations

import argparse
import contextlib
import io
import json
import os
import random
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "versal_arith"))
import lut_timing as T  # noqa: E402
from rtl_gen.compressor import compressor_RTL_gen  # noqa: E402
from rtl_gen.utils import rtl_static_issues  # noqa: E402

VECTORS = 400


def shapes(rng: random.Random, count: int) -> list[list[int]]:
    out: list[list[int]] = []
    data = ROOT / "scripts" / "lut_timing_sets" / "compressor.json"
    if data.is_file():
        raw = json.loads(data.read_text())
        items = raw if isinstance(raw, list) else raw.get("shapes", raw.get("designs", []))
        for item in items:
            h = item.get("heights") if isinstance(item, dict) else item
            if isinstance(h, list) and all(isinstance(x, int) for x in h):
                out.append(h)
    rng.shuffle(out)
    out = out[:count // 2]
    while len(out) < count:
        width = rng.randint(3, 70)
        tall = rng.choice((3, 5, 8, 12, 18, 26))
        out.append([rng.randint(0 if rng.random() < .15 else 1, tall) for _ in range(width)])
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--work", required=True, type=Path)
    ap.add_argument("--designs", type=int, default=90)
    ap.add_argument("--seed", type=int, default=1)
    args = ap.parse_args()
    rng = random.Random(args.seed)
    args.work.mkdir(parents=True, exist_ok=True)
    gen_dir = args.work.resolve()
    os.chdir(gen_dir)
    Path("RTL_generated").mkdir(exist_ok=True)

    tb_mods, inst, n, totals = [], [], 0, {"masked_inputs": 0, "spelled_out": 0,
                                           "registers_dropped": 0, "i4_swaps": 0}
    for i, heights in enumerate(shapes(rng, args.designs)):
        stages = rng.choice((0, 1, 2))
        name = f"h{i}_cmp"
        try:
            flags = T.heap_reg_flags(heights, stages)
        except ValueError:
            continue
        kinds = {c: [rng.choice("wwnn01") for _ in range(h)] for c, h in enumerate(heights) if h}
        Path("bitheap.txt").write_text("".join(f"{h}\n" for h in heights))
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            try:
                compressor_RTL_gen("bitheap.txt", name, name, tb_out_width=T.heap_width(heights),
                                   reg_flag_list=flags, gen_testbench=False, visualization=False,
                                   input_kinds=kinds)
            except ValueError as e:
                # A shape the generators refuse is out of scope; the pass refusing a
                # wire it should handle is a failure, and must not read as a skip.
                if "see through" in str(e) or "pushed bit" in str(e):
                    print(f"{name}: {e}")
                    return 1
                print(f"skip {name}: {e}", file=sys.stderr)
                continue
        for line in buf.getvalue().splitlines():
            if "pushed into LUTs:" in line:
                for k, v in eval(line.split("pushed into LUTs:")[1]).items():
                    totals[k] += v
        sv = Path(f"RTL_generated/{name}.sv").read_text()
        issues = rtl_static_issues(sv)
        if issues:
            print(f"{name}: static issues {issues[:3]}")
            return 1
        width = T.heap_width(heights)
        total_bits = sum(heights)
        latency = sum(flags)
        # One random source bit per heap bit; the true sum is built from kinds.
        conns, terms, pos = [], [], 0
        for c, h in enumerate(heights):
            if not h:
                continue
            drive = []
            for j in range(h):
                k = kinds[c][j]
                src = f"src[{pos}]"
                if k == "w":
                    drive.append(src)
                    terms.append(f"({width + 8}'({src}) << {c})")
                elif k == "n":
                    drive.append(src)
                    terms.append(f"({width + 8}'(~{src} & 1'b1) << {c})")
                elif k == "1":
                    drive.append("1'b0")
                    terms.append(f"({width + 8}'(1'b1) << {c})")
                else:
                    drive.append("1'b0")
                pos += 1
            wires = "{" + ", ".join(reversed(drive)) + "}" if h > 1 else drive[0]
            conns.append(f".in_col{c}({wires})")
        expect = " + ".join(terms) if terms else "0"
        delay = f"logic [{width+7}:0] pipe [0:{latency}];" 
        tb_mods.append(f"""module {name}_chk(input logic clk, input logic [{max(total_bits,1)-1}:0] src, input logic check, output int errors);
    logic [{width-1}:0] out;
    {delay}
    assign pipe[0] = {expect};
    {name} dut (.clk(clk), {', '.join(conns)}, .comp_out(out));
    generate for (genvar g = 1; g <= {latency}; g++) always_ff @(posedge clk) pipe[g] <= pipe[g-1]; endgenerate
    logic [{width-1}:0] want;
    assign want = pipe[{latency}][{width-1}:0];
    initial errors = 0;
    always @(negedge clk) if (check && out !== want) begin
        errors++;
        if (errors < 3) $display("MISMATCH {name} got %h want %h", out, want);
    end
endmodule
""")
        inst.append(f"    logic [{max(total_bits,1)-1}:0] s{n}; int e{n};\n"
                    f"    always_ff @(posedge clk) begin for (int b = 0; b < {max(total_bits,1)}; b++) s{n}[b] <= $urandom_range(1); end\n"
                    f"    {name}_chk u{n}(.clk(clk), .src(s{n}), .check(check), .errors(e{n}));")
        n += 1
    errs = " + ".join(f"e{i}" for i in range(n))
    Path("heap_polarity_tb.sv").write_text(
        "`timescale 1ns / 1ps\n" + "\n".join(tb_mods) +
        f"""
module heap_polarity_tb;
    logic clk = 0; logic check = 0;
    always #5 clk = ~clk;
{chr(10).join(inst)}
    initial begin
        repeat (8) @(posedge clk);
        check = 1;
        repeat ({VECTORS}) @(posedge clk);
        if (({errs}) == 0) $display("PASS All {n} designs, {VECTORS} vectors");
        else $display("FAILED: %0d mismatches", {errs});
        $finish;
    end
endmodule
""")
    print(f"{n} designs; pushed {totals}")
    glbl = subprocess.run("echo $XILINX_VIVADO/data/verilog/src/glbl.v", shell=True,
                          capture_output=True, text=True).stdout.strip()
    rtl = [str(p) for p in sorted((ROOT / "versal_arith" / "rtl").glob("*.sv"))]
    gen = [str(p) for p in sorted(Path("RTL_generated").glob("*.sv"))]
    for cmd in (["xvlog", "-sv", *rtl, *gen, "heap_polarity_tb.sv", glbl],
                ["xelab", "-L", "unisims_ver", "-L", "unimacro_ver", "-L", "secureip",
                 "work.heap_polarity_tb", "work.glbl", "-s", "t", "--mt", "4"],
                ["xsim", "t", "-R"]):
        out = subprocess.run(cmd, capture_output=True, text=True)
        Path(f"{cmd[0]}.out").write_text(out.stdout + out.stderr)
        if out.returncode != 0:
            print(f"{cmd[0]} failed; see {gen_dir}/{cmd[0]}.out")
            return 2
    lines = [l for l in out.stdout.splitlines() if ("PASS All" in l or "FAILED" in l or "MISMATCH" in l)]
    print("\n".join(lines[:10]))
    return 0 if any("PASS All" in l for l in lines) else 1


if __name__ == "__main__":
    sys.exit(main())
