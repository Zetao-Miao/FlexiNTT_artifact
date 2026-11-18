"""Cross-subproject contract for the DSP58+LUT multiplier generator (`dspmult`).

Describes `P = A * B` built from DSP58 tiles plus a LUT remainder — and differs
from every other spec in this project in one structural way that is worth being
explicit about.

Who chose the structure
-----------------------
`butterfly_spec`, `ntt_spec` and `mult_spec` all carry a decomposition **the
model chose**: the model decides, freezes a spec, and the generator builds
exactly what it was told. `dspmult` inverts that. Its frontend is itself a
decomposition search — Karatsuba-2/3, grid split, geometric DSP58 tiling, beam
search over all of it, priced through the same compressor/Booth engine the LUT
family uses. The model states the *problem* and reads the answer back.

So this spec is not a set of build instructions. It is a **problem statement plus
the search's answer**, and the answer half is exactly the pair the backend
already consumes:

    build_final_module(spec.solutionNode, spec.lutReport,
                       latency_budget=spec.latencyBudget)

Why `solutionNode` / `lutReport` are typed `Any`
------------------------------------------------
They are `dsp_multiplier.frontend.solution_tree.SolutionNode` and
`dsp_multiplier.frontend.reports.LutReportNode` — frozen dataclass trees, and the
right payload. Annotating them concretely would make merely importing this module
pull in `dsp_multiplier.frontend`, which is the thing the other three spec modules
live at the top level of `versal_arith/` specifically to avoid. `Any` plus this
paragraph buys the isolation back; `TYPE_CHECKING` imports can tighten it later
without changing the runtime import graph.

No `to_dict` / `from_dict`
--------------------------
Deliberate, unlike the sibling specs. `dsp_multiplier/frontend/storage.py`
already round-trips a `(SolutionNode, LutReportNode)` pair through JSON — that is
what a solution bundle is — and a second serializer for the same trees is how two
codecs drift apart. Use `save_bundle` / `load_bundle` for the solution half; the
problem and cost halves are plain scalars that need no codec.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class DspMultOperatorSpec:
    """One solved DSP58+LUT multiplier: what was asked, what came back, what it costs."""

    name: str

    # -- problem: what the model asked the search for ----------------------
    aPortName: str
    bPortName: str
    outPortName: str
    aInBitWidth: int
    aInIsSigned: bool
    bInBitWidth: int
    bInIsSigned: bool
    #: DSP58 ceiling handed to the search. Every returned solution satisfies
    #: `dspCount <= dspBudget`; the search never exceeds it.
    dspBudget: int
    #: Cap on total pipeline latency, in cycles, for the backend's Pareto
    #: selection. `None` asks for the shortest critical path at any latency.
    latencyBudget: int | None
    #: Target clock, in MHz. The backend then picks the FEWEST cycles that
    #: reach it -- the inverse direction to `latencyBudget`. `None` leaves the
    #: choice to `latencyBudget` alone. With both set, both must hold.
    targetFmaxMhz: float | None

    # -- output bound, from the model's own interval arithmetic -------------
    pOutBitWidth: int
    pOutIsSigned: bool
    pOutMinValue: int
    pOutMaxValue: int
    pOutZeroLsbs: int

    # -- solution: precisely what build_final_module consumes ---------------
    solutionNode: Any          # dsp_multiplier.frontend.solution_tree.SolutionNode
    lutReport: Any             # dsp_multiplier.frontend.reports.LutReportNode

    # -- cost, as the search priced it -------------------------------------
    #: LUTs for everything the DSP tiles did not cover, plus every merge heap.
    #: The search reports a float; this is that number rounded up, because a
    #: fractional LUT is not a thing you can place.
    lutTotal: int
    dspCount: int
    #: Total pipeline latency of the lowered module, in cycles. `None` until
    #: the backend has actually lowered it — the Pareto selection that decides
    #: this number is not free, so the spec does not force it.
    selectedLatency: int | None = None
    #: Worst register-to-register stage of the lowered module, in ns, including
    #: the blocks the frontier itself never prices. `None` until lowered.
    criticalPathNs: float | None = None
