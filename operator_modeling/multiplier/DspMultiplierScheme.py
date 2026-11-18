'''General multipliers built from DSP58 tiles plus a LUT remainder — the family
where the *backend* chooses the structure.

    scheme = DspMultiplierScheme(name='m', aIn=IntType.signed(64),
                                 bIn=IntType.signed(64), dspBudget=8)
    scheme.areaCost()          # -> (LUT, DSP), straight off the search
    scheme.latency()           # -> cycles, off the backend's Pareto point
    scheme.propagateValue()    # -> the batch pushed through the DSP netlists
    scheme.internalSignals()   # -> every wire the RTL will have, as a Signal

You give it a DSP budget. `versal_arith/dsp_multiplier/`'s frontend searches for
the cheapest-in-LUTs way to build that multiplier within the budget — geometric
DSP58 tiling, cascaded chains, fixed Karatsuba/Toom macro tiles, recursive
Karatsuba-2/3, a grid split for rectangular boards — and prices whatever the DSP
tiles do not cover through the compressor/Booth engine. The model does not
choose any of that. It states the problem and reads the answer back.

Why this is not a `LutMultiplierScheme`
---------------------------------------
`LutMultiplierScheme`'s one extension point is `_buildDecomposition`, which asks
the model to name the operand wires, the sub-multiplications and the
recombination. A DSP scheme has no honest answer: the decomposition is the
search's output, not the model's input, and it arrives as a `SolutionNode` tree
rather than as wires and terms. The only thing it could return is `([], [], [])`,
which declares it a **leaf** — routing `areaCost` and `latency` through the leaf
hooks and quietly discarding everything the search found.

This is the same shape as the four-step NTT and `NTTScheme`: implementing
abstract methods that can only return lies. So the two families are siblings
under `MultiplierScheme`, which is thin for exactly this reason.

Two things the search does not answer
-------------------------------------
**Latency.** `solve_grid_top` returns a structure and a LUT count, not a
schedule. Cycles come from the backend's lowering — `build_final_module` builds
the IR, composes the xcv80-calibrated per-arc timing into a `(latency -> ns)`
curve per block, and picks a point off the Pareto frontier. `latency()`
therefore lowers, and `pipelineStages` is meaningless here. Two knobs replace
it, both reading the same frontier in opposite directions:

    targetFmaxMhz   frequency in, cycles out: the FEWEST cycles that reach it.
    latencyBudget   cycles in, frequency out: the fastest clock they buy.

Give one, or both (then both must hold), or neither (fastest clock at any
latency). The pipelining the backend settles on is readable afterwards via
`selectedPipelining()`.

A frequency target is judged against the design's true worst stage, not the
frontier's. The frontier prices only blocks it can stretch; a flat adder or a
Karatsuba subtractor has one fixed stage that still bounds the clock, and the
backend folds those back in before answering. Ask for more than such a block
allows and `lower()` raises naming it — the alternative was promising a
frequency the design cannot reach at any latency.

**The arithmetic itself.** The search says *what* is built; the model performs
it. `propagateBound` and `propagateValue` are one walk over the backend's own
IR (`build_ir`, no timing pass) with the DSP tile netlists inside it — see
`dspmodel/`. A `Signal` on the input port goes through the same slices,
pre-adders, 58-bit accumulators, cascades and heaps the RTL has, and what
reaches the output port is what came out of them. There is no `a * b`
shortcut: the product appears because the netlist computes it, and
`selfCheck` asserts that at every sealed node, not just the last one.

The walk also answers the question the backend cannot: at every IR signal,
does the interval the model derives fit the width the backend declared?
`checkWidths()` reports it. Inside a tile, every DSP58 register is asserted
as the walk passes through it — a cascade that would overflow 58 bits raises
in `compute()` rather than wrapping in silicon.

A `dspBudget` of 0 is legal and degenerate: branches 2 and 3 of the search are
gated on `budget >= 1`, so a zero budget collapses to one flat pure-LUT board,
which is a Booth multiplier. It is the point where this family and
`BoothMult` should agree, and they do — both go through
`lut_cost.estimate_bmult_luts`.
'''
from __future__ import annotations

import math
from pathlib import Path

from ..core.IntType import IntType
from ..core.OperatorScheme import OperatorScheme, sampleBound
from ..core.Signal import Signal
from .MultiplierScheme import MultiplierScheme, physicalWidthFor

from dsp_mult_spec import DspMultOperatorSpec                     # noqa: E402


class DspMultiplierScheme(MultiplierScheme):
    '''`P = A * B` on DSP58 tiles within a DSP budget, structure chosen by the search.'''

    family = 'dsp'

    def __init__(self, *args,
                 dspBudget: int,
                 targetFmaxMhz: float | None = None,
                 latencyBudget: int | None = None,
                 tileModel: str = 'netlist',
                 **kwargs):
        super().__init__(*args, **kwargs)
        if tileModel not in ('netlist', 'opaque'):
            raise ValueError(
                f"{self.name}: tileModel must be 'netlist' or 'opaque', got {tileModel!r}")
        if dspBudget < 0:
            raise ValueError(
                f'{self.name}: dspBudget must be >= 0, got {dspBudget}')
        if targetFmaxMhz is not None and targetFmaxMhz <= 0:
            raise ValueError(
                f'{self.name}: targetFmaxMhz must be > 0, got {targetFmaxMhz}')
        if latencyBudget is not None and latencyBudget < 1:
            raise ValueError(
                f'{self.name}: latencyBudget must be >= 1, got {latencyBudget}')
        #: Ceiling on DSP58s. Every solution the search returns satisfies
        #: `dspCount <= dspBudget`; it never exceeds it.
        self.dspBudget = dspBudget
        #: Target clock in MHz. The backend picks the fewest cycles that reach
        #: it. `None` hands the choice to `latencyBudget`.
        self.targetFmaxMhz = targetFmaxMhz
        #: Cap on total pipeline latency in cycles. `None` is no cap.
        self.latencyBudget = latencyBudget
        #: `'netlist'` runs every DSP tile as its primitive-level netlist;
        #: `'opaque'` treats a tile as an exact product. Opaque exists to prove
        #: the walker independently of any netlist, and to model a design whose
        #: tile family has no netlist yet.
        self.tileModel = tileModel

        #: `(key, lutTotal, dspCount, node, report)` — see `solve`.
        self._solution: tuple | None = None
        #: `(key, module, traceRoot)` — see `ir`.
        self._ir: tuple | None = None
        #: The most recent walk, for `internalSignals` and `checkWidths`.
        self._lastWalk = None
        #: `(key, timingKey, BeatModel)` — see `beat`.
        self._beat: tuple | None = None
        #: `(key, timingKey, module, worstNs)` — see `lower`.
        self._lowered: tuple | None = None

    # ------------------------------------------------------------------
    # The problem handed to the search
    # ------------------------------------------------------------------

    def operandWidths(self) -> tuple[int, int]:
        '''`(widthA, widthB)`: each operand's true width. Signedness travels
        separately, in `_searchKey`. What the search and the RTL do with a
        sign bit is theirs.'''
        return physicalWidthFor(self.aIn), physicalWidthFor(self.bIn)

    #: None, or a dict shared by every instance while the DSE prices points (see `solve` and `lower`)
    SHARED = None

    def _searchKey(self) -> tuple:
        '''Everything the search result depends on.

        Value batches are deliberately absent: the structure depends on the
        operand *bounds*, never on the numbers flowing through. A scheme reused
        across trials solves once.
        '''
        wa, wb = self.operandWidths()
        return (wa, self.aIn.isSigned, wb, self.bIn.isSigned, self.dspBudget)

    # ------------------------------------------------------------------
    # Step 1 — the search
    # ------------------------------------------------------------------

    def solve(self, force: bool = False) -> tuple:
        '''Run the backend search; return `(lutTotal, dspCount, node, report)`.

        Memoized on `_searchKey()`, so rebinding `aIn` / `aInValues` between
        trials does not re-search, while genuinely changing an operand width or
        the budget does.

        Imported lazily: merely importing this module must not drag in the
        solver, which pulls the whole compressor engine behind it.
        '''
        key = self._searchKey()
        if not force and self._solution is not None and self._solution[0] == key:
            return self._solution[1:]
        # SHARED (a dict while the DSE prices points, else None): equal multipliers of different butterflies and
        # of different points are searched once. The search depends on the key alone.
        sh = DspMultiplierScheme.SHARED
        if sh is not None and not force and ('solve', key) in sh:
            self._solution = sh[('solve', key)]
            return self._solution[1:]

        from dsp_multiplier.frontend.datamodel import Signedness
        from dsp_multiplier.frontend.reports import build_lut_report
        from dsp_multiplier.frontend.solution_tree import dsp_count
        from dsp_multiplier.frontend.solver.solve import solve_grid_top

        wa, aSigned, wb, bSigned, budget = key
        result = solve_grid_top(
            wa, wb,
            Signedness.SIGNED if aSigned else Signedness.UNSIGNED,
            Signedness.SIGNED if bSigned else Signedness.UNSIGNED,
            budget,
        )
        if result is None:
            raise ValueError(
                f'{self.name}: no feasible {wa}x{wb} multiplier within '
                f'{budget} DSP58s. Raise dspBudget, or use a LutMultiplierScheme '
                f'if this multiplier should not consume DSPs at all.'
            )

        lutTotal, node = result
        # The search prices in fractional LUTs; a fraction of a LUT is not a
        # thing that can be placed, so round up rather than truncate.
        packed = (key, math.ceil(lutTotal), dsp_count(node), node,
                  build_lut_report(node))
        self._solution = packed
        if sh is not None:
            sh[('solve', key)] = packed
        return packed[1:]

    # ------------------------------------------------------------------
    # The hardware model: the IR walked on Signals
    # ------------------------------------------------------------------

    def ir(self, force: bool = False) -> tuple:
        '''`(module, traceRoot)`: the backend's IR for the solved tree, untimed.

        `build_ir` alone — not `build_final_module` — so no Pareto search runs
        and nothing prints. The trace records which IR signal is which
        subtree's product, which is what lets the walker tighten each sealed
        heap to its operand product. Memoized with the search.
        '''
        key = self._searchKey()
        if not force and self._ir is not None and self._ir[0] == key:
            return self._ir[1:]

        _, _, node, report = self.solve()
        import dsp_multiplier.backend.ir as IR
        from dsp_multiplier.backend.lowering import build_ir
        from dsp_multiplier.frontend.cost import sign_mode_map
        from dsp_multiplier.frontend.seed_tiles import build_static_seed_library

        trace: list = []
        module = build_ir(node, report, library=build_static_seed_library(),
                          latency=IR.LatencyConfig(), trace=trace,
                          sign_modes=sign_mode_map(node))
        self._ir = (key, module, trace[0])
        return module, trace[0]

    def _walk(self, withValues: bool):
        '''Push the loaded operands through the IR; keep the result.'''
        from .dspmodel.walker import walk
        module, trace = self.ir()
        a = Signal(self.aIn, self.aInValues if withValues else None)
        b = Signal(self.bIn, self.bInValues if withValues else None)
        self._lastWalk = walk(module, trace, a, b, tileModel=self.tileModel)
        return self._lastWalk

    def propagateBound(self) -> IntType:
        '''The output bound, off the walk.

        Numerically it is `aIn * bIn` — the root is a sealed node, and a seal
        carries the operand product interval because the RTL truncates to
        exactly that. But it is *reached* by walking, so every intermediate
        register is asserted on the way, and `internalSignals()` is populated.
        '''
        OperatorScheme.propagateBound(self)
        return self._walk(withValues=False).output.bound

    def propagateValue(self) -> list[int]:
        '''The output batch, computed by the netlist and nothing else.'''
        OperatorScheme.propagateValue(self)
        return self._walk(withValues=True).output.values

    def internalSignals(self) -> dict[str, Signal]:
        '''Every IR wire from the most recent walk, by the backend's own name.

        Tile-internal wires — each DSP58's `P`, `AD`, `M`; a Karatsuba tile's
        fabric differences — are keyed `<tile result>/<wire>`.
        '''
        if self._lastWalk is None:
            self._walk(withValues=self.aInValues is not None and self.bInValues is not None)
        out = dict(self._lastWalk.signals)
        for tile, wires in self._lastWalk.tileInternals.items():
            for name, sig in wires.items():
                out[f'{tile}/{name}'] = sig
        return out

    def checkWidths(self, strict: bool = True) -> list:
        '''For every IR signal: does the model's interval fit what the backend
        declared, and by how many bits? The check the backend cannot make.

        Returns the list of `WireCheck`s. With `strict`, raises naming every
        wire whose declared register is too narrow for the values the model
        says it will carry — the RTL would wrap those silently.
        '''
        result = self._lastWalk or self._walk(withValues=False)
        bad = result.violations
        if strict and bad:
            lines = [f'  {c.name} ({c.kind}): declared '
                     f'{"s" if c.declaredSigned else "u"}{c.declaredWidth}, '
                     f'model needs {c.bound}' for c in bad]
            raise ValueError(
                f'{self.name}: {len(bad)} wire(s) declared narrower than the '
                f'model\'s interval:\n' + '\n'.join(lines))
        return list(result.checks)

    def crossCheckEvaluate(self, samples: int = 8) -> int:
        '''Agree with the backend testbench's own interpreter, per wire.'''
        from .dspmodel.walker import crossCheckEvaluate
        result = self._walk(withValues=True)
        module, _ = self.ir()
        return crossCheckEvaluate(result, module,
                                  Signal(self.aIn, self.aInValues),
                                  Signal(self.bIn, self.bInValues), samples)

    # ------------------------------------------------------------------
    # Step 2 — the lowering, which is what knows about cycles
    # ------------------------------------------------------------------

    def _timingKey(self) -> tuple:
        '''Everything the lowering depends on beyond the search itself.'''
        return (self.targetFmaxMhz, self.latencyBudget)

    def _isLowered(self) -> bool:
        return (self._lowered is not None
                and self._lowered[0] == self._searchKey()
                and self._lowered[1] == self._timingKey())

    def lower(self, force: bool = False) -> tuple:
        '''Build the latency-optimized IR module; return `(module, worstNs)`.

        Strictly more expensive than `solve()` — it builds the IR, walks the
        timing model, enumerates a Pareto frontier and aligns every block onto
        the selected point — and it prints its own multi-section report to
        stdout on the way. Call it when you need cycles, ns or RTL; call
        `solve()` when you only need area.

        Memoized on the search key *and* both timing knobs, because re-running
        the backend against a different target is the whole reason the backend
        is a separate step from the frontend.

        `worstNs` is the design's true worst stage, including the blocks the
        frontier never prices. Raises when `targetFmaxMhz` cannot be met, and
        says whether the frontier, an unpriced block, or `latencyBudget` is
        what stands in the way.
        '''
        if not force and self._isLowered():
            return self._lowered[2:]
        sh = DspMultiplierScheme.SHARED
        lk = ('lower', self._searchKey(), self._timingKey())
        if sh is not None and not force and lk in sh:
            self._lowered = sh[lk]
            return self._lowered[2:]

        _, _, node, report = self.solve()
        from rtl_gen.dsp_multiplier.pipeline import build_final_module

        module, worstNs = build_final_module(
            node, report,
            latency_budget=self.latencyBudget,
            target_fmax_mhz=self.targetFmaxMhz)
        self._lowered = (self._searchKey(), self._timingKey(), module, worstNs)
        if sh is not None:
            sh[lk] = self._lowered
        return module, worstNs

    # ------------------------------------------------------------------
    # The clocked model
    # ------------------------------------------------------------------

    def beat(self, force: bool = False):
        '''The cycle-accurate model of the design the backend chose.

        Built from the module `lower()` returns — the Pareto point for this
        scheme's `targetFmaxMhz` / `latencyBudget`, `align_latency`'s delay
        lines in place — with every register where the backend put it and,
        inside each tile, where its generator puts it for that latency. See
        `dspmodel.walker.BeatModel`. Memoized with the lowering.
        '''
        key, tkey = self._searchKey(), self._timingKey()
        if (not force and self._beat is not None
                and self._beat[0] == key and self._beat[1] == tkey):
            return self._beat[2]
        from .dspmodel.walker import BeatModel
        module, _ = self.lower()
        _, trace = self.ir()          # same node, same names; the seals are the same
        model = BeatModel(module, trace, self.aIn, self.bIn, tileModel=self.tileModel)
        self._beat = (key, tkey, model)
        return model

    def reset(self) -> None:
        '''Empty the pipeline.'''
        self.beat().reset()

    def step(self, aBatch: list[int], bBatch: list[int]) -> list[int] | None:
        '''One clock edge: feed this cycle's batches, return what is on the
        output port after the edge — None until the pipeline has filled.'''
        return self.beat().step(aBatch, bBatch)

    # ------------------------------------------------------------------
    # The OperatorScheme surface
    # ------------------------------------------------------------------

    def areaCost(self) -> tuple[int, int]:
        '''`(LUT, DSP)` exactly as the search priced it.'''
        lutTotal, dspCount, _, _ = self.solve()
        return lutTotal, dspCount

    def latency(self, pipelineStages: int = 1) -> int:
        '''Total pipeline latency in cycles, from the selected Pareto point.

        `pipelineStages` does not apply to this family and is rejected rather
        than ignored. Everywhere else in the project it means "registers per
        stage, you choose"; here the backend chooses the depth of every block
        from its own timing model, under `latencyBudget`. Silently accepting a
        number that changes nothing is how a caller comes to believe it did.
        '''
        if pipelineStages != 1:
            raise ValueError(
                f'{self.name}: a DSP multiplier does not take pipelineStages '
                f'(got {pipelineStages}). The backend picks each block\'s depth '
                f'off its own Pareto frontier — give it targetFmaxMhz to say '
                f'how fast, or latencyBudget to cap the total.'
            )
        from dsp_multiplier.backend.schedule import module_latency

        module, _ = self.lower()
        return module_latency(module)

    def criticalPathNs(self) -> float:
        '''The design's worst register-to-register stage, in ns.

        Includes the blocks the frontier never prices (see `lower`). It is the
        number the `dspmult` evaluation clock is derived from. No sibling has
        this, because no other scheme in the project has a timing model behind
        it.
        '''
        _, worstNs = self.lower()
        return worstNs

    def achievedFmaxMhz(self) -> float:
        '''Clock the lowered design supports, in MHz, clock uncertainty included.

        Computed the way the backend's own frontier computes it, so a target
        given as `targetFmaxMhz` and the answer read back here are on the same
        scale. (The backend's floor report prints a figure *without* the
        uncertainty; that one reads ~20% higher and is not this.)
        '''
        from dsp_multiplier.backend.delay_model import fmax_of
        return fmax_of(self.criticalPathNs())

    def fabricBeforeFirstRegister(self) -> bool:
        '''Whether an operand passes fabric logic before its first register: a Karatsuba or Toom-Cook tile forms
        an operand difference in LUTs, and the configuration the timing search picked may leave that difference
        unregistered in front of the DSP (y0y1_ff = xeval_ff = 0). Such a stage is timed for an
        operand that comes from a flip-flop. A caller whose operand comes from a block RAM (clock to output about
        0.8 ns later than a flip-flop, measured 2026-11-16) has to register it first.'''
        from dsp_multiplier.backend.timing import dsp_model as DM
        best = {'versal_static_k2': (DM.best_k2, 'y0y1_ff'), 'versal_static_k3': (DM.best_k3, 'y0y1_ff'),
                'versal_static_toom25': (DM.best_t25, 'xeval_ff')}
        module, _ = self.lower()
        for op in module.ops:
            key, lat = getattr(op, 'backend_key', None), getattr(op, 'latency', None)
            if key in best and lat is not None:
                fn, ff = best[key]
                cfg = fn(lat)['config']
                if not cfg[ff]:                 # LUT logic on the operand, in front of the DSP (B register or not)
                    return True
        return False

    def selectedPipelining(self) -> list[tuple[str, str, int]]:
        '''The pipelining the backend settled on: `(block, kind, cycles)` per
        block, in module order. This is the "optimal pipelining" a frequency
        target buys — readable, so a caller can see what it paid for.

        Alignment delay lines are included, because they are real registers
        the design carries; they are the rows whose kind is `Delay`.
        '''
        module, _ = self.lower()
        rows = []
        for op in module.ops:
            name = getattr(getattr(op, 'result', None), 'name', None)
            if name is None:
                continue
            cycles = getattr(op, 'latency', None)
            if cycles is None:
                cycles = getattr(op, 'cycles', None)
            if cycles is None:
                continue
            rows.append((name, type(op).__name__, cycles))
        return rows

    def selfCheck(self, testSize: int = 256, seed: int | None = None) -> None:
        '''Assert the walked netlist computes `A * B` — at every node.

        Samples both operands inside their bounds, walks, and checks three
        things the walker enforces as it goes: every sealed subtree's values
        equal that subtree's operand product; every DSP58 register and every
        declared width holds its value; every wire's values lie inside its
        bound. The output equalling `a * b` is the last of those, not the
        only one.
        '''
        import random as _random
        from .dspmodel import signalops as so

        rng = _random.Random(seed) if seed is not None else _random
        savedA, savedB = self.aInValues, self.bInValues
        try:
            self.aInValues = sampleBound(self.aIn, testSize, rng)
            self.bInValues = sampleBound(self.bIn, testSize, rng)
            result = self._walk(withValues=True)
            for i, (a, b, got) in enumerate(
                    zip(self.aInValues, self.bInValues, result.output.values)):
                if got != a * b:
                    raise AssertionError(
                        f'{self.name}: netlist computes {got} for A={a}, B={b}, '
                        f'expected {a * b} (sample {i})')
            for name, sig in self.internalSignals().items():
                if not so.contained(sig):
                    raise AssertionError(
                        f'{self.name}: a value on {name} lies outside its bound {sig.bound}')
            self.checkWidths(strict=True)
        finally:
            self.aInValues, self.bInValues = savedA, savedB

    def getOperatorInterface(self, name: str,
                             pipelineStages: int = 1) -> DspMultOperatorSpec:
        '''The problem, the search's answer, and what it costs.

        The answer half is exactly the `(node, report)` pair the backend's
        `build_final_module` consumes — not a re-encoding of it, so the model
        and the generator cannot hold different views of the same solution.

        `selectedLatency` is filled only when this scheme has **already** been
        lowered. Asking for a spec must not silently trigger the Pareto
        optimisation; a caller who wants the number calls `latency()`.
        '''
        if pipelineStages != 1:
            raise ValueError(
                f'{name}: a DSP multiplier does not take pipelineStages '
                f'(got {pipelineStages}); set latencyBudget instead.')

        lutTotal, dspCount, node, report = self.solve()
        wa, wb = self.operandWidths()
        outBound = self.propagateBound()

        selected, critical = None, None
        if self._isLowered():
            from dsp_multiplier.backend.schedule import module_latency
            selected = module_latency(self._lowered[2])
            critical = self._lowered[3]

        return DspMultOperatorSpec(
            name=name,
            aPortName=self.aPortName,
            bPortName=self.bPortName,
            outPortName=self.outPortName,
            aInBitWidth=wa,
            aInIsSigned=self.aIn.isSigned,
            bInBitWidth=wb,
            bInIsSigned=self.bIn.isSigned,
            dspBudget=self.dspBudget,
            latencyBudget=self.latencyBudget,
            targetFmaxMhz=self.targetFmaxMhz,
            pOutBitWidth=outBound.bitWidth,
            pOutIsSigned=outBound.isSigned,
            pOutMinValue=outBound.minValue,
            pOutMaxValue=outBound.maxValue,
            pOutZeroLsbs=outBound.zeroLsbs,
            solutionNode=node,
            lutReport=report,
            lutTotal=lutTotal,
            dspCount=dspCount,
            selectedLatency=selected,
            criticalPathNs=critical,
        )

    def emitRtl(self, name: str, run_dir,
                evaluate: bool = False,
                test_size: int = 1000,
                seed: int = 1,
                clock_period_ns: float | None = None,
                **kwargs) -> dict:
        '''Lower the solved tree and write the RTL project into `run_dir`.

        Unlike every other generator in the project, the `dspmult` backend takes
        an explicit output directory rather than writing relative to the process
        cwd, so there is no `runInDir` here — `run_dir` is passed straight
        through and the cwd is never touched.

        `name` is accepted so this matches the `emitRtl` signature every family
        shares, and is then ignored: the emitted module is named by the lowered
        IR -- `build_final_module` calls `build_ir` without a name, so the
        default `mul_<wa>x<wb>` stands
        (`dsp_multiplier/backend/lowering.py`) -- and that name is what the
        returned `meta['module']` reports. `aPortName` / `bPortName` /
        `outPortName` reach the spec only for the same reason: the emitted top's
        operand ports are hard-coded `A` and `B`.

        `evaluate=True` adds the self-checking testbench, the intermediates
        dump and the on-chip evaluation shell. Its clock defaults to the
        selected Pareto point's critical path times `CLOCK_PERIOD_MARGIN`, which
        is why it is derived here rather than guessed.
        '''
        from rtl_gen.dsp_multiplier.pipeline import (
            CLOCK_PERIOD_MARGIN, generate_evaluation, generate_rtl)
        from dsp_multiplier.backend.schedule import module_latency

        outDir = Path(run_dir)
        outDir.mkdir(parents=True, exist_ok=True)

        module, worstNs = self.lower()
        generate_rtl(module, outDir)
        if evaluate:
            generate_evaluation(
                module, outDir,
                test_size=test_size, seed=seed,
                clock_period_ns=(clock_period_ns if clock_period_ns is not None
                                 else worstNs * CLOCK_PERIOD_MARGIN),
            )

        lutTotal, dspCount, _, _ = self.solve()
        wa, wb = self.operandWidths()
        return {
            'module': module.name,
            'family': self.family,
            'out_dir': str(outDir),
            'aIn_bit_width': wa,
            'bIn_bit_width': wb,
            'pOut_bit_width': self.propagateBound().bitWidth,
            'lut_total': lutTotal,
            'dsp_count': dspCount,
            'pipeline_latency': module_latency(module),
            'critical_path_ns': worstNs,
            'achieved_fmax_mhz': self.achievedFmaxMhz(),
            'target_fmax_mhz': self.targetFmaxMhz,
        }
