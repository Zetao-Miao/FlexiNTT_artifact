#!/usr/bin/env python3
"""check_gpc_polarity.py -- prove the GPCs' inversion masks in xsim.

Every GPC in versal_arith/rtl/ is instantiated under each of its parameter
combinations and several input masks, beside a reference copy with no mask and
the same inputs inverted in the testbench. Every output must match the
reference on random vectors, including PROP and CY, which feed the carry chain.

    python scripts/check_gpc_polarity.py --work <folder>

Needs Vivado's xvlog, xelab and xsim on PATH.
"""
from __future__ import annotations

import argparse
import itertools
import random
import re
import subprocess
import sys
from pathlib import Path

RTL = Path(__file__).resolve().parent.parent / "versal_arith" / "rtl"
sys.path.insert(0, str(RTL.parent))
from rtl_gen.bit_polarity import lut6cy_i4_pins  # noqa: E402
MASKS_PER_COMBO = 6
VECTORS = 4000


def read_module(path: Path) -> dict:
    text = path.read_text()
    params = [p for p in re.findall(r'parameter\s+(\w+)\s*=\s*"FALSE"', text)]
    head = text[:text.index(");", text.index(")("))]
    ports = re.findall(r'(input|output)\s+logic\s*(?:\[(\d+)\s*:\s*0\])?\s*(\w+)', head)
    return {"params": params,
            "inputs": [(n, int(w or 0) + 1) for d, w, n in ports if d == "input" and n != "clk"],
            "outputs": [(n, int(w or 0) + 1) for d, w, n in ports if d == "output"]}


def legal(name: str, combo: dict) -> bool:
    # FIRSTS and LASTS select a chain position only on odd positions.
    return not (combo.get("FIRSTS") == "TRUE" and combo.get("LASTS") == "TRUE")


def emit_tb(rng: random.Random) -> tuple[str, int]:
    body, checks, n = [], [], 0
    for path in sorted(RTL.glob("c*.sv")):
        name = path.stem
        mod = read_module(path)
        data_ports = [(p, w) for p, w in mod["inputs"] if re.fullmatch(r"C\d", p)]
        other = [(p, w) for p, w in mod["inputs"] if not re.fullmatch(r"C\d", p)]
        for values in itertools.product(("FALSE", "TRUE"), repeat=len(mod["params"])):
            combo = dict(zip(mod["params"], values))
            if not legal(name, combo):
                continue
            for _ in range(MASKS_PER_COMBO):
                # A LUT6CY's I4 cannot be inverted through INIT; the generator
                # never asks for it (rtl_gen.bit_polarity).
                masks = {p: sum(1 << i for i in range(w) if rng.random() < 0.5
                                and (p, i if w > 1 else None) not in lut6cy_i4_pins()[name])
                         for p, w in data_ports}
                tag = f"u{n}"
                n += 1
                total = sum(w for _, w in mod["inputs"])
                body.append(f"    logic [{total-1}:0] {tag}_in;")
                base = [f'.{k}("{v}")' for k, v in combo.items()]
                mask_params = [f".{p}_INV({w}'h{masks[p]:x})" for p, w in data_ports]
                conn_d, conn_r, pos = [], [], 0
                for p, w in mod["inputs"]:
                    sel = f"{tag}_in[{pos+w-1}:{pos}]"
                    conn_d.append(f".{p}({sel})")
                    conn_r.append(f".{p}({sel} ^ {w}'h{masks.get(p, 0):x})")
                    pos += w
                outs_d, outs_r = [], []
                for p, w in mod["outputs"]:
                    body.append(f"    logic [{w-1}:0] {tag}_{p}_d, {tag}_{p}_r;")
                    outs_d.append(f".{p}({tag}_{p}_d)")
                    outs_r.append(f".{p}({tag}_{p}_r)")
                    checks.append(f'if ({tag}_{p}_d !== {tag}_{p}_r) begin errors++; '
                                  f'$display("MISMATCH {name} {combo} {masks} {p}"); end')
                body.append(f"    {name} #({', '.join(base + mask_params)}) {tag}_d "
                            f"(.clk(clk), {', '.join(conn_d + outs_d)});")
                body.append(f"    {name} #({', '.join(base)}) {tag}_r "
                            f"(.clk(clk), {', '.join(conn_r + outs_r)});")
                checks.append(f"{tag}_in = {{$urandom, $urandom}};")
    # The drive statements are mixed in with the checks: split them.
    drives = [c for c in checks if c.startswith("u")]
    compares = [c for c in checks if c.startswith("if")]
    tb = ["`timescale 1ns / 1ps", "module gpc_polarity_tb;", "    logic clk = 0;",
          "    always #5 clk = ~clk;", "    int errors = 0;", *body, "    initial begin",
          f"        repeat ({VECTORS}) begin", "            @(negedge clk);",
          *[f"            {d}" for d in drives], "            @(posedge clk); #1;", "            @(negedge clk);",
          *[f"            {c}" for c in compares], "        end",
          f'        if (errors == 0) $display("PASS All {n} instances, {VECTORS} vectors");',
          '        else $display("FAILED: %0d mismatches", errors);', "        $finish;", "    end",
          "endmodule", ""]
    return "\n".join(tb), n


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--work", required=True, type=Path)
    ap.add_argument("--seed", type=int, default=1)
    args = ap.parse_args()
    args.work.mkdir(parents=True, exist_ok=True)
    tb, n = emit_tb(random.Random(args.seed))
    (args.work / "gpc_polarity_tb.sv").write_text(tb)
    glbl = subprocess.run("echo $XILINX_VIVADO/data/verilog/src/glbl.v", shell=True,
                          capture_output=True, text=True).stdout.strip()
    srcs = [str(p) for p in sorted(RTL.glob("c*.sv"))] + ["gpc_polarity_tb.sv", glbl]
    for cmd in (["xvlog", "-sv", *srcs],
                ["xelab", "-L", "unisims_ver", "-L", "unimacro_ver", "-L", "secureip",
                 "work.gpc_polarity_tb", "work.glbl", "-s", "t"],
                ["xsim", "t", "-R"]):
        out = subprocess.run(cmd, cwd=args.work, capture_output=True, text=True)
        (args.work / f"{cmd[0]}.out").write_text(out.stdout + out.stderr)
        if out.returncode != 0:
            print(f"{cmd[0]} failed; see {args.work}/{cmd[0]}.out")
            return 2
    lines = [l for l in out.stdout.splitlines() if re.search(r"PASS All|FAILED|MISMATCH", l)]
    print("\n".join(lines[:12]))
    return 0 if lines and lines[-1].startswith("PASS All") and len(lines) == 1 else 1


if __name__ == "__main__":
    sys.exit(main())
