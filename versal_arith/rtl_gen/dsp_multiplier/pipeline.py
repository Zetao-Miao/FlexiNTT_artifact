"""The backend pipeline: turn an already-solved (SolutionNode, LutReportNode)
pair into RTL and/or evaluation output files.

Everything after the search lives here, so the two entry points that need it --
`versal_arith/cli.py -operator dspmult` (via `dsp_multiplier_runner.py`) and
`operator_modeling.multiplier.DspMultiplierScheme.emitRtl` -- share one
implementation instead of each keeping a copy.
"""
from __future__ import annotations

import re
from pathlib import Path

import dsp_multiplier.backend.ir as IR
from dsp_multiplier.backend.delay_model import (
    fmax_of,
    ns_floor_report,
    ns_pareto_frontier,
    print_ns_pareto_report,
    select_fmax_point,
    select_ns_point,
    true_worst_ns,
)
from dsp_multiplier.backend.schedule import align_latency, module_latency
from dsp_multiplier.frontend.cost import describe_with_cost, sign_mode_map
from dsp_multiplier.frontend.seed_tiles import build_static_seed_library
from dsp_multiplier.backend.reports import print_latency_report
from dsp_multiplier.backend.lowering import build_ir
from rtl_gen.dsp_multiplier.emit_hweval import write_hweval
from rtl_gen.dsp_multiplier.emit_scoped_xdc import write_scoped_xdc_tcl
from rtl_gen.dsp_multiplier.emit_synth_settings import write_synth_settings_tcl
from rtl_gen.dsp_multiplier.emit_tb import write_testbench
from rtl_gen.dsp_multiplier.interface import emit_systemverilog
from rtl_gen.dsp_multiplier.project import write_rtl_project

# Default hardware-evaluation clock margin over the selected Pareto-frontier
# point's critical path (worst_ns), used when the caller omits an explicit
# clock period.
CLOCK_PERIOD_MARGIN = 1.25


def output_name_component(value: str) -> str:
    """Return a readable path component with separators/metacharacters removed."""
    component = re.sub(r"[^A-Za-z0-9_-]+", "_", value).strip("_-")
    return component or "unnamed"


def default_out_dir(output_root: Path, bundle_stem: str, module: IR.IRModule) -> Path:
    """Choose a deterministic per-bundle/per-module output directory."""
    bundle_name = output_name_component(bundle_stem)
    module_name = output_name_component(module.name)
    return output_root / f"rtl_out_{bundle_name}_{module_name}"


def build_final_module(
    node, report, *,
    latency_budget: int | None = None,
    target_fmax_mhz: float | None = None,
) -> tuple[IR.IRModule, float]:
    """Build and latency-optimize an already-solved (node, report) pair,
    once, for every requested output.

    Returns (aligned_module, worst_ns) -- worst_ns is the design's worst
    register-to-register stage, in ns, so callers can derive a
    hardware-evaluation clock constraint from the design actually picked
    instead of a flat guess.

    Two ways to choose the pipelining, both reading one Pareto frontier:

      latency_budget   cycles in, frequency out. Cap total latency and take
                       the highest-fmax point within the cap; ``None`` is
                       no cap (max fmax, whatever it costs in cycles).
      target_fmax_mhz  frequency in, cycles out. Take the FEWEST cycles that
                       reach the target. With both given, both must hold.

    ``worst_ns`` is the honest number, not the frontier's. The frontier only
    prices blocks it can stretch; a flat adder, a Karatsuba subtractor or a
    SmallMult has nothing to stretch and is skipped, yet its one stage still
    bounds the clock. `true_worst_ns` folds those back in, so a design whose
    slowest stage is such a block reports that stage rather than a faster
    one it happens to be able to tune. For every design where no such block
    dominates, this is exactly the frontier's number as before.

    A frequency target is then judged against that honest figure: if an
    unpriced block alone caps the design below the target, no latency choice
    can help, and this raises naming the block.

    Mode0 (FIXED, i.e. skip the optimizer and keep whatever latencies
    SeedTiles assigned) is kept in dsp_multiplier.backend.delay_model /
    dsp_multiplier.backend.lowering for debugging but isn't wired up here.
    """
    description, _ = describe_with_cost(node)
    print(description)

    library = build_static_seed_library()

    trace = []
    module = build_ir(
        node,
        report,
        library=library,
        latency=IR.LatencyConfig(),
        trace=trace,
        sign_modes=sign_mode_map(node),
    )

    print()
    print(ns_floor_report(module))
    print()
    points = ns_pareto_frontier(module)
    print_ns_pareto_report(points)

    if target_fmax_mhz is not None:
        best = select_fmax_point(points, target_fmax_mhz, latency_budget)
    else:
        best = select_ns_point(points, latency_budget)
    # print(IR.dump(best.module))

    aligned = align_latency(best.module)
    print_latency_report(trace[0], aligned)

    worst, culprit = true_worst_ns(aligned, best.worst_ns)
    if culprit is not None:
        print(
            f"\nNOTE: the frontier's worst stage is {best.worst_ns:.3f} ns "
            f"({best.fmax_mhz:.1f} MHz), but {culprit.name} -- a {culprit.width}-bit "
            f"{culprit.kind} the frontier never prices -- costs {culprit.ns:.3f} ns "
            f"({fmax_of(culprit.ns):.1f} MHz) by this model's own constants "
            f"[{culprit.basis}]. Reporting {worst:.3f} ns."
        )
        if target_fmax_mhz is not None and fmax_of(worst) < target_fmax_mhz - 1e-9:
            raise ValueError(
                f"{target_fmax_mhz:.1f} MHz is unreachable: {culprit.name} "
                f"({culprit.width}-bit {culprit.kind}) is a single stage of "
                f"{culprit.ns:.3f} ns and cannot be pipelined, capping the design "
                f"at {fmax_of(worst):.1f} MHz at ANY latency. The frontier alone "
                f"would have promised {best.fmax_mhz:.1f} MHz at T={best.latency}; "
                f"that promise was the bug this check exists for."
            )
    return aligned, worst


def generate_rtl(module: IR.IRModule, out_dir: Path) -> None:
    """Write the complete RTL project for an already-finalized module."""
    interface = emit_systemverilog(module)
    emitted = write_rtl_project(
        interface,
        out_dir,
        # GPC counter/compressor primitives (c15_3.sv, LFSR.sv, ...) are
        # instantiated by name straight out of versal_arith/rtl/ whenever the
        # design uses a LUT-packed bitheap -- without copying them in,
        # synthesis fails to resolve those modules. Always include them;
        # write_rtl_project() only copies the ones actually referenced.
        include_gpc_primitives=True,
    )
    print(f"\n=== RTL written to {out_dir.resolve()}/ ===")
    print(f"  top:      {emitted.top}")
    print(f"  wrappers: {len(emitted.wrappers)}")
    print(f"  inners:   {len(emitted.inners)}")
    print(f"  gpc:      {len(emitted.gpc)}")

    settings_tcl = write_synth_settings_tcl(out_dir)
    print(f"  synth settings tcl: {settings_tcl}")


def generate_evaluation(
    module: IR.IRModule,
    out_dir: Path,
    *,
    test_size: int,
    seed: int,
    clock_period_ns: float,
) -> None:
    """Write the former main_evaluate.py output bundle."""
    out_dir.mkdir(parents=True, exist_ok=True)

    tb_path = out_dir / f"{module.name}_tb.sv"
    intermediates_path = out_dir / "intermediates.txt"
    write_testbench(
        module,
        tb_path,
        test_size=test_size,
        seed=seed,
        dump_intermediates_path=intermediates_path,
    )
    print(f"\n=== Evaluation files written to {out_dir.resolve()}/ ===")
    print(f"  testbench:    {tb_path.resolve()}")
    print(f"  intermediates: {intermediates_path.resolve()}")
    print(f"  latency:      {module_latency(module)}")

    paths = write_hweval(
        module,
        out_dir,
        style="auto",
        clock_period_ns=clock_period_ns,
    )
    print("  hweval:       ", *(str(path) for path in paths.values()))

    if "lfsr" in paths:
        # filelist.f is the single source of truth every downstream
        # consumer (GUI add_files, the non-project batch flow) reads
        # design sources from -- written earlier by write_rtl_project(),
        # before this (--evaluate-only) function knew whether the lfsr
        # hweval style, and hence LFSR.sv, would be needed at all.
        filelist_path = out_dir / "filelist.f"
        if filelist_path.is_file():
            rel = paths["lfsr"].relative_to(out_dir.resolve()).as_posix()
            existing = filelist_path.read_text(encoding="utf-8").splitlines()
            if rel not in existing:
                with filelist_path.open("a", encoding="utf-8") as f:
                    f.write(rel + "\n")
                print(f"  filelist.f:    appended {rel}")

    scoped_tcl = write_scoped_xdc_tcl(out_dir, mode="project")
    print(f"  scoped tcl:   {scoped_tcl}")
