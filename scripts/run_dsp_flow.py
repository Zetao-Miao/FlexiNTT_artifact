#!/usr/bin/env python3
"""run_dsp_flow.py -- take one DSP multiplier through the whole flow on this machine.

    generate   search, RTL, testbench, evaluation harness
    sim        the testbench on the RTL
    impl       synthesis and implementation of the harness out of context, with the
               GPC and partial-product packing rules, writing both netlists
    netsim     the testbench on the synthesis netlist and on the routed netlist

Everything lands in <work>/<name>/, and the last line of <work>/<name>/result.json
holds the numbers. Set DSP_MERGE_PARTIAL_PRODUCTS=0 to build Booth rectangles as
whole multipliers.

    python scripts/run_dsp_flow.py --work <folder> --width-a 64 --width-b 64 --signs ss \\
        --budget 4 --target-fmax 300 --test-size 1000
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path[:0] = [str(ROOT), str(ROOT / "versal_arith")]
PART = "xcv80-lsva4737-2MHP-e-S"
SOURCE = Path(os.environ.get("V80_REMOTE_ROOT", ".")) / "source"      # the Vivado settings, as in run_remote_*.py
GPC_RULES = ("c9_41.xdc", "scoped_gpc_xdc.tcl", "write_dut_netlist.tcl")


def generate(args, out: Path) -> dict:
    from dsp_multiplier.frontend.datamodel import Signedness
    from dsp_multiplier.frontend.reports import build_lut_report
    from dsp_multiplier.frontend.solver.solve import solve_grid_top
    from dsp_multiplier.frontend.solution_tree import dsp_count
    from dsp_multiplier.backend.schedule import module_latency
    import dsp_multiplier.backend.ir as IR
    from rtl_gen.dsp_multiplier.pipeline import build_final_module, generate_rtl, generate_evaluation

    sign = {"s": Signedness.SIGNED, "u": Signedness.UNSIGNED}
    result = solve_grid_top(args.width_a, args.width_b, sign[args.signs[0]], sign[args.signs[1]], args.budget)
    if result is None:
        raise SystemExit("no feasible solution")
    cost, node = result
    module, worst = build_final_module(node, build_lut_report(node),
                                       target_fmax_mhz=args.target_fmax,
                                       latency_budget=args.latency_budget)
    generate_rtl(module, out)
    generate_evaluation(module, out, test_size=args.test_size, seed=args.seed,
                        clock_period_ns=args.clock_ns or round(worst * 1.25, 3))
    rtl = ROOT / "versal_arith" / "rtl"
    for name in GPC_RULES:
        shutil.copy(rtl / name, out / name)
    (out / "filelist.f").write_text((out / "filelist.f").read_text())
    return {
        "module": module.name, "est_luts": cost, "dsps": dsp_count(node), "latency": module_latency(module),
        "model_worst_ns": worst, "tree": type(node).__name__,
        "booth_words": sum(type(op) is IR.LutMult and min(op.a.width, op.b.width) > 5 for op in module.ops),
        "small_mults": sum(type(op) is IR.LutMult and min(op.a.width, op.b.width) <= 5 for op in module.ops),
        "partial_product_rects": sum(isinstance(op, IR.LutPP) for op in module.ops),
        "heaps": sum(isinstance(op, IR.BitHeap) for op in module.ops),
    }


def sh(cmd: str, log: Path, cwd: Path) -> int:
    with log.open("w") as f:
        return subprocess.run(["bash", "-c", f"source {SOURCE} >/dev/null 2>&1; {cmd}"],
                              cwd=cwd, stdout=f, stderr=subprocess.STDOUT).returncode


def verdict(log: Path) -> str:
    text = log.read_text(errors="replace")
    m = re.search(r"^(PASS all \d+|FAIL \d+/\d+)", text, re.M)
    return m[1] if m else "NO VERDICT, see " + log.name


def simulate(out: Path, sources: str, name: str) -> str:
    run = out / f"sim_{name}"
    shutil.rmtree(run, ignore_errors=True)
    run.mkdir()
    top = (out / "top.txt").read_text().strip()
    cmd = (f"xvlog -sv {sources} {out}/{top}_tb.sv $XILINX_VIVADO/data/verilog/src/glbl.v -work work && "
           f"xelab -L unisims_ver -L secureip work.{top}_tb work.glbl -s tb -log elab.log && "
           "printf 'run all\\nquit\\n' > sim.tcl && xsim tb -t sim.tcl")
    sh(cmd, out / f"sim_{name}.log", run)
    return verdict(out / f"sim_{name}.log")


def implement(out: Path, top: str, clock_ns: float) -> dict:
    files = [line for line in (out / "filelist.f").read_text().split() if line]
    reads = "\n".join(f"read_verilog -sv {out}/{f}" for f in files)
    (out / f"{top}_hweval_ooc.xdc").write_text(f"create_clock -period {clock_ns} -name clk [get_ports clk]\n")
    tcl = f"""
{reads}
read_verilog -sv {out}/{top}_hweval.sv
read_xdc {out}/{top}_hweval_ooc.xdc
synth_design -top {top}_hweval -part {PART} -mode out_of_context -global_retiming off
write_verilog -force -mode funcsim -cell dut {out}/{top}_synth_funcsim.v
report_utilization -cells [get_cells dut] -file {out}/util_synth.rpt
set gpc_xdc_extra_dirs [list {out}/xdc]
source {out}/scoped_gpc_xdc.tcl
opt_design
place_design
phys_opt_design
route_design
source {out}/write_dut_netlist.tcl
write_dut_netlist {out}/{top}_impl_funcsim.v
report_utilization -cells [get_cells dut] -file {out}/util_impl.rpt
report_timing_summary -file {out}/timing_impl.rpt
set dut_regs [get_cells -hier -quiet -filter {{NAME =~ "dut/*" && IS_SEQUENTIAL == 1}}]
report_timing -nworst 1 -to $dut_regs -file {out}/timing_dut.rpt
puts "WNS_ALL [get_property SLACK [get_timing_paths -max_paths 1]]"
puts "WNS_DUT [get_property SLACK [get_timing_paths -max_paths 1 -to $dut_regs]]"
# did the LUTNM groups end up in one physical LUT?
set groups [dict create]
foreach c [get_cells -quiet -hier -filter {{LUTNM != ""}}] {{
    dict lappend groups "[get_property PARENT $c]/[get_property LUTNM $c]" $c
}}
set packed 0
dict for {{key cells}} $groups {{
    set where {{}}
    foreach c $cells {{ lappend where "[get_property LOC $c]/[string index [get_property BEL $c] end-4]" }}
    if {{[llength [lsort -unique $where]] == 1}} {{ incr packed }}
}}
puts "LUTNM_GROUPS [dict size $groups] PACKED $packed"
exit
"""
    (out / "impl.tcl").write_text(tcl)
    rc = sh(f"vivado -mode batch -source {out}/impl.tcl -nojournal -log {out}/impl.log", out / "impl.out", out)
    log = (out / "impl.log").read_text(errors="replace") if (out / "impl.log").exists() else ""
    res = {"impl_rc": rc}
    for key, pat in (("wns_all", r"^WNS_ALL (\S+)"), ("wns_dut", r"^WNS_DUT (\S+)")):
        m = re.search(pat, log, re.M)
        res[key] = float(m[1]) if m else None
    m = re.search(r"^LUTNM_GROUPS (\d+) PACKED (\d+)", log, re.M)
    res["lutnm_groups"], res["lutnm_packed"] = (int(m[1]), int(m[2])) if m else (None, None)
    util = (out / "util_impl.rpt").read_text() if (out / "util_impl.rpt").exists() else ""
    for key, pat in (("luts", r"CLB LUTs\s*\|\s*(\d+)"), ("ffs", r"CLB Registers\s*\|\s*(\d+)"),
                     ("dsp58", r"DSP58\S*\s*\|\s*(\d+)"), ("slices", r"\| SLICE\s*\|\s*(\d+)")):
        m = re.search(pat, util)
        res[key] = int(m[1]) if m else None
    return res


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--work", required=True, type=Path)
    p.add_argument("--width-a", type=int, required=True)
    p.add_argument("--width-b", type=int, required=True)
    p.add_argument("--signs", default="ss")
    p.add_argument("--budget", type=int, required=True)
    p.add_argument("--target-fmax", type=float, default=None)
    p.add_argument("--latency-budget", type=int, default=None)
    p.add_argument("--clock-ns", type=float, default=None)
    p.add_argument("--test-size", type=int, default=1000)
    p.add_argument("--seed", type=int, default=1)
    p.add_argument("--name", default=None)
    p.add_argument("--no-impl", action="store_true")
    args = p.parse_args()

    name = args.name or (f"m{args.width_a}x{args.width_b}{args.signs}_b{args.budget}"
                         + (f"_t{args.target_fmax:g}" if args.target_fmax else ""))
    out = (args.work / name).resolve()
    shutil.rmtree(out, ignore_errors=True)
    out.mkdir(parents=True)
    result = {"name": name, **generate(args, out)}
    top = result["module"]
    (out / "top.txt").write_text(top + "\n")
    files = [line for line in (out / "filelist.f").read_text().split() if line]
    design = " ".join(str(out / f) for f in files if not f.endswith("LFSR.sv"))
    result["sim"] = simulate(out, design, "rtl")
    if not args.no_impl:
        clock = float(re.search(r"-period (\S+)", (out / f"{top}_hweval_ooc.xdc").read_text())[1])
        result["clock_ns"] = clock
        result.update(implement(out, top, clock))
        result["netsim_synth"] = simulate(out, str(out / f"{top}_synth_funcsim.v"), "synth")
        result["netsim_impl"] = simulate(out, str(out / f"{top}_impl_funcsim.v"), "impl")
    (out / "result.json").write_text(json.dumps(result) + "\n")
    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())
