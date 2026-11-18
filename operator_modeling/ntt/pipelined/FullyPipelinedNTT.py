'''The fully pipelined NTT operator: one butterfly per position per layer, a fixed modulus.

    FullyPipelinedNTT    the operator over a `FullyPipelinedGrid` (ports, bounds, values, RTL)
    FullyPipelinedINTT   the same wiring with inverse twiddles
'''
from __future__ import annotations
import collections
from math import log2
from ..butterfly.Butterfly import Butterfly
from ..butterfly.ButterflyScheme import ButterflyScheme
from .FullyPipelinedScheme import (FullyPipelinedGrid, NTTScheme, butterflyToMems,
                        memToButterfly)
from ...core.Operator import Operator
from ...core.IntType import IntType
from ...core.Signal import Signal

# versal_arith path was added to sys.path by the .ButterflyScheme import above
# (see ButterflyScheme.py for the on-demand append). Both the
# pipeline spec dataclass and the rtl_gen ntt generator are imported through it.
from ntt_spec import NTTOperatorSpec, InterStageWire


class FullyPipelinedNTT(Operator):
    '''An NTT pipeline: natural-order inputs and outputs over a butterfly network.

    The network itself belongs to the **scheme** (`FullyPipelinedGrid`), which
    builds it, wires it, and owns the stride and bit-reversal rules. This class
    is the operator around it: natural-order I/O, the spec, and RTL emission.

    That split is what lets a second architecture exist. An *iterative* NTT --
    a grid walked repeatedly -- would be a different `NTTScheme`, not a
    different class here. A four-step would not: it is a composition of five
    operators with no grid and no stride, so it is its own family in
    `operator_modeling/ntt/multistep/`, where `FourStepScheme` subclasses
    `OperatorScheme` directly.

    The constructor is unchanged, and so is `setScheme` — but `setScheme` is now
    for *overriding* the butterfly schemes, not for supplying them. The grid
    builds its own, which removes the identical `log2(n) x n/2` comprehension
    that every caller used to write out by hand.
    '''

    def __init__(self, name: str, n: int, q: int, butterflyType: str, twiddles: list[list[int | list[tuple[int, int]]]], negacyclic: bool = False,
                 scheme: 'NTTScheme | None' = None,
                 targetFmaxMhz: float | None = None):
        super().__init__(name)
        # When `scheme` is given, `n`, `q`, `butterflyType`, `twiddles`,
        # `negacyclic` and `targetFmaxMhz` are ignored outright and never
        # cross-checked against it. The properties below read the scheme, which
        # is the single source of truth by construction; `targetFmaxMhz` reaches
        # only the grid this branch would otherwise have built.
        self.scheme = scheme if scheme is not None else FullyPipelinedGrid(
            name=name, n=n, q=q, butterflyType=butterflyType,
            twiddles=twiddles, negacyclic=negacyclic,
            targetFmaxMhz=targetFmaxMhz)
        # Validation now lives in NTTScheme.__init__, which raises on a bad n,
        # q, butterflyType or twiddles shape before any grid is built.
        self._buildPortTables()

    # ------------------------------------------------------------------
    # Natural-order port tables
    # ------------------------------------------------------------------

    def _buildPortTables(self) -> None:
        '''Work out, once, which butterfly port each natural index reaches.

        Two steps, both of which the scheme already knows how to answer:
        turn the natural index into a memory slot (`inputNaturalToMemory` —
        bit-reversed for CT, identity for GS), then turn the memory slot into a
        butterfly and a port letter (`memToButterfly` at the scheme's boundary
        stride). For n = 8:

            GS                                  CT
            x[0] -> mem 0 -> butterfly 0 A      x[0] -> mem 0 -> butterfly 0 A
            x[1] -> mem 1 -> butterfly 1 A      x[1] -> mem 4 -> butterfly 2 A
            x[4] -> mem 4 -> butterfly 0 B      x[4] -> mem 1 -> butterfly 0 B

        That answer used to be re-derived from scratch in five places here and
        one in `verification`, each re-deriving the stride and re-applying the
        bit reversal. Now it is a list, and those places read the list. The
        scheme's four topology methods, which nothing called, are what build it.
        '''
        n = self.n
        L = len(self.butterflies)
        scheme = self.scheme

        self._inputPortsNatural: list = [None] * n
        self._outputPortsNatural: list = [None] * n
        # Per stage-0 / final-stage butterfly, the natural index on each port.
        # This is exactly what the RTL spec's inputWiring / outputWiring are.
        self._inputWiring: list[list[int | None]] = [[None, None] for _ in range(n // 2)]
        self._outputWiring: list[list[int | None]] = [[None, None] for _ in range(n // 2)]

        # Memory order too, because `getInputs` / `getOutputs` are indexed that
        # way. Same ports, different index; both tables are views on the grid.
        self._inputPortsMemory: list = [None] * n
        self._outputPortsMemory: list = [None] * n

        inStride = scheme.inputStride()
        for i in range(n):
            m = scheme.inputNaturalToMemory(i)
            p, side = memToButterfly(m, inStride)
            bfly = self.butterflies[0][p]
            port = bfly.inputPortA if side == 'A' else bfly.inputPortB
            self._inputPortsNatural[i] = port
            self._inputPortsMemory[m] = port
            self._inputWiring[p][0 if side == 'A' else 1] = i

        # The scheme gives memory -> natural on the output side; invert it
        # explicitly rather than leaning on bitReverse being its own inverse.
        naturalOfMemory = [scheme.outputMemoryToNatural(m) for m in range(n)]
        if sorted(naturalOfMemory) != list(range(n)):
            raise ValueError(
                f'{self.name}: scheme.outputMemoryToNatural is not a permutation'
            )
        memoryOfNatural = [0] * n
        for m, k in enumerate(naturalOfMemory):
            memoryOfNatural[k] = m

        outStride = scheme.outputStride()
        for k in range(n):
            m = memoryOfNatural[k]
            p, side = memToButterfly(m, outStride)
            bfly = self.butterflies[L - 1][p]
            port = bfly.outputPortA if side == 'A' else bfly.outputPortB
            self._outputPortsNatural[k] = port
            self._outputPortsMemory[m] = port
            self._outputWiring[p][0 if side == 'A' else 1] = k

        for i, port in enumerate(self._inputPortsNatural):
            if port is None:
                raise ValueError(f'{self.name}: natural input {i} reaches no port')
        for k, port in enumerate(self._outputPortsNatural):
            if port is None:
                raise ValueError(f'{self.name}: natural output {k} reaches no port')

    @property
    def inputPorts(self) -> list:
        '''The stage-0 butterfly input ports, in natural order x[0]..x[n-1].

        These are the butterflies' own ports, not copies — so connecting an
        upstream operator here and calling its `compute()` drives the pipeline
        directly, with nothing to copy across afterwards.
        '''
        return list(self._inputPortsNatural)

    @property
    def outputPorts(self) -> list:
        '''The final-stage butterfly output ports, in natural order.'''
        return list(self._outputPortsNatural)

    # The scheme is the single source of truth for topology; these read through
    # to it so existing callers — including three that index `inst.butterflies`
    # directly — keep working unchanged.
    @property
    def butterflies(self) -> list[list[Butterfly]]:
        return self.scheme.butterflies

    @property
    def n(self) -> int:
        return self.scheme.n

    @property
    def q(self) -> int:
        return self.scheme.q

    @property
    def butterflyType(self) -> str:
        return self.scheme.butterflyType

    @property
    def twiddles(self):
        return self.scheme.twiddles

    @property
    def negacyclic(self) -> bool:
        return self.scheme.negacyclic

    def _drivePorts(self, ports: list, values, label: str) -> None:
        '''Write a list of bounds or of value batches onto `ports`, positionally.

        The single place either index order lands on the grid; `getInputs` hands
        it the memory-order table and `getInputsNatural` the natural-order one.
        '''
        if not isinstance(values, list):
            raise TypeError(f'{label} must be a list, got {type(values)}')
        if len(values) != self.n:
            raise ValueError(f'{label} must have length n={self.n}, got {len(values)}')

        if all(isinstance(v, list) for v in values):
            batchSize = len(values[0]) if values else 0
            if any(len(v) != batchSize for v in values):
                raise ValueError('all test-vector batches must have the same length; got mixed lengths in inputs')
            for v in values:
                if not all(isinstance(e, int) for e in v):
                    raise TypeError('all elements of a test-vector batch must be int')
            for port, v in zip(ports, values):
                port.testVector = v
        elif all(isinstance(v, IntType) for v in values):
            for port, v in zip(ports, values):
                port.bound = v
        else:
            raise TypeError('inputs must be either list[IntType] or list[list[int]]')

    def getInputs(self, inputs: list[IntType] | list[list[int]]) -> None:
        '''Drive the first-stage butterfly input ports from `inputs`. The list is indexed by NTT memory position, in the layout the chosen scheme expects: bit-reversed natural order for CT (e.g. n=8: [x[0], x[4], x[2], x[6], x[1], x[5], x[3], x[7]]) and natural order for GS (e.g. n=8: [x[0], x[1], ..., x[7]]). Each first-stage butterfly's two memory slots are looked up via butterflyToMems and pulled from `inputs`.'''
        self._drivePorts(self._inputPortsMemory, inputs, 'inputs')

    def getInputsNatural(self, x: list[IntType] | list[list[int]]) -> None:
        '''Drive the first-stage inputs from a list given in NATURAL order x[0], x[1], ..., x[n-1]. Auto-permutes into the pipeline's memory layout: bit-reverses for CT (which expects bit-reversed memory at input) or passes through for GS (already natural at input).'''
        self._drivePorts(self._inputPortsNatural, x, 'x')

    def getOutputsNatural(self) -> list[IntType] | list[list[int]]:
        '''Return the final-stage outputs in NATURAL order Y[0], Y[1], ..., Y[n-1] (or x[0], ..., x[n-1] for INTT). Auto-permutes from the pipeline's memory layout: pass-through for CT (output is already natural) or bit-reverses for GS (output is bit-reversed in memory).'''
        return [p.bound if p.bound is not None else p.testVector
                for p in self._outputPortsNatural]

    def setScheme(self, schemes: list[list[ButterflyScheme]]) -> None:
        '''Attach a ButterflyScheme to every butterfly. `schemes` is shaped log2(n) x n/2, mirroring the butterfly grid: schemes[layerIndex][butterflyIndex] is assigned to self.butterflies[layerIndex][butterflyIndex].scheme.'''
        if not isinstance(schemes, list):
            raise TypeError(f'schemes must be a list of layer lists, got {type(schemes)}')
        L = len(self.butterflies)
        if len(schemes) != L:
            raise ValueError(f'schemes must have {L} layers (log2(n)), got {len(schemes)}')
        halfN = self.n // 2
        for layerIndex, layer in enumerate(schemes):
            if not isinstance(layer, list):
                raise TypeError(f'schemes[{layerIndex}] must be a list, got {type(layer)}')
            if len(layer) != halfN:
                raise ValueError(f'schemes[{layerIndex}] must have n/2={halfN} entries, got {len(layer)}')
            for butterflyIndex, scheme in enumerate(layer):
                if not isinstance(scheme, ButterflyScheme):
                    raise TypeError(f'schemes[{layerIndex}][{butterflyIndex}] must be a ButterflyScheme, got {type(scheme)}')
                self.butterflies[layerIndex][butterflyIndex].scheme = scheme

    def compute(self) -> None:
        '''Walk the pipeline stage by stage, calling each butterfly's compute(). Each butterfly pulls input bounds from its input ports (driven by getInputs() for stage 0, or by upstream butterflies' compute() pushes for later stages), runs its scheme, and pushes its output bounds onto downstream input ports. By the time stage s runs, stage s-1 has already populated all stage-s input ports.'''
        for layer in self.butterflies:
            for bfly in layer:
                bfly.compute()

    def getOutputs(self) -> list[IntType] | list[list[int]]:
        '''Return the final-layer outputs in NTT memory-position order. Mirror of getInputs: outputs[m] is the value at memory slot m. Auto-dispatches per-port: if outputPort.bound is set it's used; otherwise outputPort.testVector. Result is None for any slot whose owning butterfly has not had compute() run yet. Return type is list[IntType] in bound mode and list[list[int]] in value-batch mode (mixed populations follow per-port).'''
        return [p.bound if p.bound is not None else p.testVector
                for p in self._outputPortsMemory]

    def showBounds(self) -> None:
        '''Print a per-stage summary of output bounds: max bitWidth across the stage's butterflies, plus a representative IntType (the widest one). Quick at-a-glance view of how bounds evolve through the pipeline. Run after compute().'''
        print(f'=== Bounds for {self.name} (n={self.n}, {self.butterflyType}) ===')
        for s, layer in enumerate(self.butterflies):
            widest: IntType | None = None
            maxWidth = -1
            for bfly in layer:
                for bound in (bfly.outputPortA.bound, bfly.outputPortB.bound):
                    if bound is None:
                        continue
                    if bound.bitWidth > maxWidth:
                        maxWidth = bound.bitWidth
                        widest = bound
            if widest is None:
                print(f'Layer {s}: <no bounds — has compute() been run?>')
            else:
                print(f'Layer {s}: max bitWidth = {maxWidth}, e.g. {widest}')

    def saveBoundsToXlsx(self, path: str = 'NTT_bounds.xlsx', sheetName: str | None = None) -> None:
        '''Record the full per-butterfly per-stage output bound table to xlsx. Layout: row 1 holds "Layer 1".."Layer L" headers plus a trailing "<TYPE> BOUNDS" label; rows 2..n+1 hold per-port bounds in physical order (butterfly p port A on row 2+2p, port B on row 3+2p). Each cell contains str(bound) using IntType.__str__. Sheet name defaults to self.name so multiple NTT instances can record to the same workbook without colliding. If the file exists, the named sheet is replaced and other sheets are preserved; otherwise a new workbook is created.'''
        from ...core.utils import saveXlsxSheet
        if sheetName is None:
            sheetName = self.name
        L = len(self.butterflies)

        headers = [f'Layer {i + 1}' for i in range(L)] + [f'{self.butterflyType} BOUNDS']
        rows: list[list[str]] = []
        for p in range(self.n // 2):
            aRow, bRow = [], []
            for layerIdx in range(L):
                bfly = self.butterflies[layerIdx][p]
                aBound = bfly.outputPortA.bound
                bBound = bfly.outputPortB.bound
                aRow.append(str(aBound) if aBound is not None else '')
                bRow.append(str(bBound) if bBound is not None else '')
            rows.append(aRow)
            rows.append(bRow)

        saveXlsxSheet(path, sheetName, rows, headers=headers)

    def getOperatorInterface(self, name: str, pipelineStagesPerLayer=None) -> NTTOperatorSpec:
        '''Build an NTTOperatorSpec describing the entire pipeline at RTL granularity.

        Walks the populated grid (compute() must already have been run with input
        bounds loaded so every input/output port has a bound), invokes each
        butterfly's scheme.getOperatorInterface to get its ButterflyOperatorSpec,
        and precomputes the wiring tables that map natural-order x[i] inputs to
        first-stage butterfly ports (inputWiring), inter-layer connections
        (interStageWiring via butterflyToMems + memToButterfly), and final-stage
        butterfly ports back to natural-order y[i] outputs (outputWiring).

        Per-butterfly module names are namespaced by the NTT's top name as
        <name>_btf_L<s>_p<p>, so two NTT instances with the same n /
        butterflyType but different `name` produce non-colliding butterfly
        modules — required when integrating multiple NTTs into one Vivado
        project. The short `btf` abbreviation (vs full `Butterfly`) keeps
        the resulting module + instance identifiers short enough to dodge a
        Vivado xelab false-positive multi-driver bug that fires on full
        449-butterfly elaboration when individual identifiers grow past
        ~50 characters. Standalone build_butterfly.py keeps its own
        Butterfly_n<N>_<TYPE>_L<s>_p<p> shape — single-module compiles do
        not trigger that pathology.

        Consumed by versal_arith.rtl_gen.ntt.NTT_RTL_gen, which composes the
        per-butterfly RTL into a full pipeline wrapper.

        A butterfly whose scheme is scheduled on the operator side (`ModularBU`:
        a datapath, any q) returns a `DatapathButterflySpec` built for its
        layer's entry of `pipelineStagesPerLayer` (an int for every layer or one
        per layer; default 1); a Goldilocks butterfly's stages are chosen by
        the generator from the same list.
        '''
        n = self.n
        L = len(self.butterflies)
        if L != int(log2(n)):
            raise ValueError(f'butterfly grid layer count {L} does not match log2(n)={int(log2(n))}')
        for s in range(L):
            if len(self.butterflies[s]) != n // 2:
                raise ValueError(f'butterflies[{s}] has {len(self.butterflies[s])} entries, expected {n // 2}')

        # Per-natural-input widths come from each stage-0 butterfly port's bound. Filled
        # below after `inputWiring` is computed. Each stage-0 butterfly's two input ports
        # must have a bound set (by getInputsNatural + compute()).
        for p in range(n // 2):
            for portName, port in (('A', self.butterflies[0][p].inputPortA),
                                   ('B', self.butterflies[0][p].inputPortB)):
                if port.bound is None:
                    raise ValueError(f'butterflies[0][{p}].inputPort{portName}.bound is None — call compute() with bounds first')

        # Per-butterfly ButterflyOperatorSpec collection.
        stageReqs = self.scheme.perLayerRequest(1 if pipelineStagesPerLayer is None else pipelineStagesPerLayer)
        butterflySpecs: list[list] = []
        for s in range(L):
            layerSpecs = []
            for p in range(n // 2):
                bfly = self.butterflies[s][p]
                if bfly.scheme is None:
                    raise ValueError(f'butterflies[{s}][{p}].scheme is None — call setScheme() before getOperatorInterface()')
                if bfly.inputPortA.bound is None or bfly.inputPortB.bound is None:
                    raise ValueError(f'butterflies[{s}][{p}].inputPort{{A,B}}.bound is None — call compute() with bounds first')
                # Re-seat the bounds from the ports. `Butterfly.compute` already
                # leaves them there — a value pass writes aInValues/bInValues and
                # keeps the bounds in aIn/bIn — so this is a restatement, not a
                # repair. It still earns its place for a scheme attached by hand
                # since the last compute().
                bfly.scheme.aIn = bfly.inputPortA.bound
                bfly.scheme.bIn = bfly.inputPortB.bound
                if bfly.twiddle is not None:
                    bfly.scheme.twiddle = bfly.twiddle
                elif bfly.twiddlePort is not None:
                    bfly.scheme.twiddle = bfly.twiddlePort.bound
                else:
                    raise ValueError(f'butterflies[{s}][{p}] has no twiddle assigned')
                butterflyName = f'{name}_btf_L{s}_p{p}'
                if _schedulesItself(bfly.scheme):
                    layerSpecs.append(bfly.scheme.getOperatorInterface(name=butterflyName,
                                                                       pipelineStages=stageReqs[s]))
                else:
                    layerSpecs.append(bfly.scheme.getOperatorInterface(name=butterflyName))
            butterflySpecs.append(layerSpecs)

        # Stage-0 and final-stage routing in natural-order space, straight off
        # the tables built in `_buildPortTables` — the same tables `inputPorts` /
        # `outputPorts` expose, so the spec and the port view can never disagree
        # about which natural index sits on which butterfly port. Widths are read
        # per natural index from that index's own port, assuming no uniformity.
        inputWiring: list[tuple[int, int]] = [tuple(w) for w in self._inputWiring]
        inputBitWidthsNatural: list[int] = [0] * n
        inputIsSignedNatural: list[bool] = [False] * n
        for i, port in enumerate(self._inputPortsNatural):
            inputBitWidthsNatural[i] = port.bound.bitWidth
            inputIsSignedNatural[i] = port.bound.isSigned

        outputWiring: list[tuple[int, int]] = [tuple(w) for w in self._outputWiring]
        outputBitWidthsNatural: list[int] = [0] * n
        outputIsSignedNatural: list[bool] = [False] * n
        for k, port in enumerate(self._outputPortsNatural):
            if port.bound is None:
                raise ValueError(
                    f'natural output {k} has no bound — call compute() with bounds first'
                )
            outputBitWidthsNatural[k] = port.bound.bitWidth
            outputIsSignedNatural[k] = port.bound.isSigned

        # Inter-stage wiring for layers 1..L-1. Replicates the connection logic from
        # FullyPipelinedNTT.__init__: use this layer's stride
        # to find the butterfly's memory positions, then the previous layer's
        # stride to find which upstream butterfly+port produced each position.
        interStageWiring: list[list[tuple[InterStageWire, InterStageWire]]] = []
        for s in range(1, L):
            if self.butterflyType == 'CT':
                strideThis = 1 << s
                stridePrev = strideThis >> 1
            else:
                strideThis = 1 << (L - s - 1)
                stridePrev = strideThis << 1
            layerWiring: list[tuple[InterStageWire, InterStageWire]] = []
            for p in range(n // 2):
                mA, mB = butterflyToMems(p, strideThis)
                pA, portA = memToButterfly(mA, stridePrev)
                pB, portB = memToButterfly(mB, stridePrev)
                layerWiring.append((InterStageWire(src_p=pA, src_port=portA),
                                    InterStageWire(src_p=pB, src_port=portB)))
            interStageWiring.append(layerWiring)

        return NTTOperatorSpec(
            name=name,
            n=n,
            butterflyType=self.butterflyType,
            negacyclic=self.negacyclic,
            q=self.q,
            butterflySpecs=butterflySpecs,
            inputBitWidthsNatural=inputBitWidthsNatural,
            inputIsSignedNatural=inputIsSignedNatural,
            outputBitWidthsNatural=outputBitWidthsNatural,
            outputIsSignedNatural=outputIsSignedNatural,
            inputWiring=inputWiring,
            outputWiring=outputWiring,
            interStageWiring=interStageWiring,
        )

    def _extractGoldensNatural(self) -> tuple[list[list[int]], list[list[int]]]:
        '''Walk the populated grid and return (goldenXNatural, goldenYNatural),
        each shape (testSize x n). Inputs come from stage-0 input ports'
        testVector (set by getInputsNatural([batches])); outputs come from
        final-layer output ports' testVector (set by compute()). The
        natural ↔ memory permutation reuses the same mapping that
        getInputsNatural / getOutputsNatural use. Precondition: every relevant
        port has a testVector populated (call getInputsNatural([list[int]]*n)
        and compute() before invoking this).'''
        n = self.n
        inputByNatural = [p.testVector for p in self._inputPortsNatural]
        outputByNatural = [p.testVector for p in self._outputPortsNatural]

        for i in range(n):
            if inputByNatural[i] is None:
                raise ValueError(
                    f'natural-input index {i}: stage-0 butterfly port has no testVector. '
                    f'Call getInputsNatural([list[int]]*n) + compute() before emitRtl.'
                )
            if outputByNatural[i] is None:
                raise ValueError(
                    f'natural-output index {i}: final-layer butterfly port has no testVector. '
                    f'Call compute() with values loaded before emitRtl.'
                )

        testSize = len(inputByNatural[0])
        for i in range(n):
            if len(inputByNatural[i]) != testSize:
                raise ValueError(
                    f'inconsistent batch length on natural-input index {i}: '
                    f'len={len(inputByNatural[i])}, expected {testSize}'
                )
            if len(outputByNatural[i]) != testSize:
                raise ValueError(
                    f'inconsistent batch length on natural-output index {i}: '
                    f'len={len(outputByNatural[i])}, expected {testSize}'
                )

        goldenXNatural = [[inputByNatural[i][b] for i in range(n)] for b in range(testSize)]
        goldenYNatural = [[outputByNatural[i][b] for i in range(n)] for b in range(testSize)]
        return goldenXNatural, goldenYNatural

    # --- the clock: reset() / step() ---------------------------------------
    #
    # The clocked counterpart of `compute()`, the way `Multiplier.step()` is
    # for the DSP multiplier, built the way `NTT_RTL_gen` builds the RTL. Each
    # butterfly's two compressors carry their own registers, inside their
    # logic, at the stage count `butterfly_stage_plan` placed for the request
    # or under the target frequency; only once a compressor is pipelined to
    # its end do registers that merely synchronise follow -- the wrapper's,
    # balancing the shallower output up to the butterfly's deeper one, and the
    # NTT wrapper's, balancing the butterfly up to the deepest in its layer.
    # A compressor's registers do not change the value they carry (every
    # compression layer preserves the heap's sum), so each is one step of
    # delay on the sum; `pipelineReport()` lists which are logic and which
    # are synchronisation. The port stream is what the RTL testbench sees:
    # vector 0's outputs appear after exactly `latency()` edges, i.e. on the
    # step of index `latency() - 1`.

    def reset(self, pipeline_stages_per_layer=1) -> None:
        '''Empty the pipeline and build it: per butterfly and output, the
        registers inside that compressor's logic (its stage plan for the
        request -- an int for every layer or one entry per layer, unused under
        the scheme's `targetFmaxMhz` -- capped at its units) and, after them,
        the synchronising registers up to the layer's latency. Needs the bound
        path computed first -- `getInputsNatural([bounds])` and `compute()` --
        since a compressor's depth follows from its heap, and the output ports
        carry those bounds while the pipeline fills.'''
        reqs = self.scheme.perLayerRequest(pipeline_stages_per_layer)
        plans = [[bfly.scheme.stagePlan(r) for bfly in layer]
                 for layer, r in zip(self.butterflies, reqs)]
        self._plans = plans
        self._layerLatencies = [max(pl.latency for pl in layer) for layer in plans]
        self._logic: dict = {}
        self._sync: dict = {}
        # An input present during a step is captured at the edge that ends it
        # and is visible on that same step's index, so the first register a
        # value meets costs no step; every later one costs one. All paths
        # through a layer cross the same number, so one flag per layer does.
        pre = True
        for s, layer in enumerate(plans):
            Ls = self._layerLatencies[s]
            for p, plan in enumerate(layer):
                for label, out in (('A', plan.aOut), ('B', plan.bOut)):
                    k = out.stages
                    self._logic[(s, p, label)] = self._line(k, pre)
                    self._sync[(s, p, label)] = self._line(Ls - k, pre and k == 0)
            if Ls >= 1:
                pre = False
        self._sources = self._interStageSources()

    @staticmethod
    def _line(registers: int, first: bool):
        '''A chain of `registers` flops as a delay line, one step each, one
        fewer when it holds the first register a value meets; None when empty.'''
        if registers <= 0:
            return None
        return collections.deque([None] * (registers - 1 if first else registers))

    @staticmethod
    def _shift(line, value):
        '''Move a delay line one step: in with `value`, out with the oldest.'''
        if line is None:
            return value
        line.append(value)
        return line.popleft()

    def pipelineReport(self) -> list[list[dict]]:
        '''Per layer, per butterfly: the registers inside each compressor's
        logic (`aOut_stages`, `bOut_stages`), the wrapper's balancing of the
        shallower output, the layer's balancing of the butterfly, and the
        butterfly's and the layer's latency -- the pipeline `reset()` built,
        which is the one `NTT_RTL_gen` builds.'''
        if getattr(self, '_plans', None) is None:
            raise ValueError(f'{self.name}.pipelineReport: call reset() first')
        rows = []
        for s, layer in enumerate(self._plans):
            Ls = self._layerLatencies[s]
            rows.append([{
                'position': p,
                'aOut_stages': pl.aOut.stages,
                'bOut_stages': pl.bOut.stages,
                'wrapper_balancing': {'aOut': pl.latency - pl.aOut.stages,
                                      'bOut': pl.latency - pl.bOut.stages},
                'butterfly_latency': pl.latency,
                'layer_balancing': Ls - pl.latency,
                'layer_latency': Ls,
            } for p, pl in enumerate(layer)])
        return rows

    def _interStageSources(self) -> list[list[tuple[tuple[int, str], tuple[int, str]]]]:
        '''For every layer s >= 1 and position p: which (position, port) of
        layer s-1 feeds its A and its B -- the rule `buildGrid` wired the
        ports with, and `getOperatorInterface` records as `interStageWiring`.'''
        out = []
        for s in range(1, self.scheme.layers):
            strideThis, stridePrev = self.scheme.strideForLayer(s)
            layer = []
            for p in range(self.n // 2):
                mA, mB = butterflyToMems(p, strideThis)
                layer.append((memToButterfly(mA, stridePrev), memToButterfly(mB, stridePrev)))
            out.append(layer)
        return out

    def _evalButterfly(self, bfly, aValues, bValues):
        '''One butterfly's value path on the batches given, at the bounds the
        untimed pass left on its ports; None while either input is still
        filling.'''
        if aValues is None or bValues is None:
            return None
        sch = bfly.scheme
        if bfly.twiddle is not None:
            sch.twiddle = bfly.twiddle
        elif bfly.twiddlePort is not None:
            sch.twiddle = bfly.twiddlePort.bound
        aBound, bBound = bfly.inputPortA.bound, bfly.inputPortB.bound
        if not isinstance(aBound, IntType) or not isinstance(bBound, IntType):
            raise ValueError(
                f'{self.name}.step: {bfly.name} has no input bounds -- run compute() '
                f'with bounds loaded before stepping')
        sch.aIn, sch.bIn = aBound, bBound
        sch.aInValues, sch.bInValues = aValues, bValues
        return sch.propagateValue()

    def step(self) -> None:
        '''One clock edge. Reads this cycle's batch off every stage-0 input
        port, runs every butterfly on what reaches it, moves every register
        one step, and writes the final layer's outputs to the output ports --
        `Signal(bound, None)` while the pipeline is still filling -- pushing
        to connected ports. `compute()` is untouched; a design is driven by
        one or the other.'''
        if getattr(self, '_logic', None) is None:
            raise ValueError(f'{self.name}.step: call reset() first')
        values = []
        for bfly in self.butterflies[0]:
            sa, sb = bfly.inputPortA.signal, bfly.inputPortB.signal
            if sa is None or sb is None or sa.values is None or sb.values is None:
                raise ValueError(f'{self.name}.step: a stage-0 input port carries no values this cycle')
            values.append((sa.values, sb.values))
        outs = None
        for s, layer in enumerate(self.butterflies):
            if s > 0:
                values = [(outs[pA][0 if portA == 'A' else 1], outs[pB][0 if portB == 'A' else 1])
                          for (pA, portA), (pB, portB) in self._sources[s - 1]]
            outs = []
            for p, bfly in enumerate(layer):
                computed = self._evalButterfly(bfly, *values[p])
                pair = []
                for i, label in enumerate('AB'):
                    v = None if computed is None else computed[i]
                    v = self._shift(self._logic[(s, p, label)], v)
                    v = self._shift(self._sync[(s, p, label)], v)
                    pair.append(v)
                outs.append(tuple(pair))
        for bfly, (a, b) in zip(self.butterflies[-1], outs):
            for port, v in ((bfly.outputPortA, a), (bfly.outputPortB, b)):
                if port.bound is None:
                    raise ValueError(
                        f'{self.name}.step: {bfly.name} has no output bound -- run compute() '
                        f'with bounds loaded before stepping')
                port.signal = Signal(port.bound, v)
                if port.isConnected:
                    port.push()

    # --- Operator contract ------------------------------------------------

    def areaCost(self) -> tuple[int, int]:
        '''`(LUT, DSP)` summed over the grid, via the scheme.'''
        return self.scheme.areaCost()

    def latency(self, pipelineStages=1) -> int:
        '''Pipeline registers between the natural inputs and outputs: the
        scheme's layer latencies summed. `pipelineStages` is an int for every
        layer or one entry per layer.'''
        return self.scheme.latency(pipelineStages)

    # `Operator.emitRtl`'s template does not fit this operator: it passes a
    # single `pipeline_stages` int where an NTT needs one per layer, and it
    # samples its own test data where an NTT takes goldens from the already
    # populated grid. `emitRtl` below overrides it, so these three hooks exist
    # only to satisfy the ABC and should never be reached.

    def _generatorTarget(self) -> tuple[str, str, str]:
        raise NotImplementedError(
            f'{self.name}: the NTT emits through its own emitRtl, which takes '
            f'pipeline_stages_per_layer; the Operator template does not apply.'
        )

    def _prepareTestData(self, spec, test_size: int, seed: int | None,
                         **kwargs) -> dict:
        raise NotImplementedError(
            f'{self.name}: NTT goldens come from the populated grid via '
            f'_extractGoldensNatural, not from sampling here.'
        )

    def _generatorKwargs(self, data: dict) -> dict:
        raise NotImplementedError(
            f'{self.name}: the NTT emits through its own emitRtl.'
        )

    def emitRtl(self,
                topName: str,
                run_dir,
                pipeline_stages_per_layer = 1,
                gen_testbench: bool = True,
                visualization: bool = False,
                sanity_check_size: int = 8,
                backend: str = 'hw',
                target_fmax_mhz: float | None = None,
                hw_manifest=None,
                share_compressors: bool = True) -> dict:
        '''Emit RTL for the entire NTT/INTT pipeline. Precondition: setScheme
        was called, getInputsNatural([bounds]) + compute() populated the bound
        path. When gen_testbench=True, also requires getInputsNatural([batches])
        + compute() so every input/output port has a testVector — the goldens
        come from the populated instance, not internal sampling.

        `pipeline_stages_per_layer` is either an int (broadcast to every layer)
        or a list of length log2(n). `target_fmax_mhz` (default: the scheme's
        `targetFmaxMhz`) lets every butterfly take the fewest compressor stages
        that reach the target instead; the per-layer counts are then unused
        and the generator balances within each layer. The target used is
        written through to every butterfly scheme, so `latency()` and
        `reset()` afterwards report the depth built, which is also asserted
        against the manifest. `hw_manifest` (sim
        backend only) is the path of a hardware run's `manifest.json`: the sim
        RTL then takes its request and target from that run and must come out
        at the same per-butterfly and per-layer latencies, or it raises.

        `backend` selects the RTL flavor:
          - 'hw'  (default): optimized Versal compressor-tree generator
            (`rtl_gen.ntt.NTT_RTL_gen`). One file per butterfly wrapper and per
            compressor; LUT packing comes from `rtl/scoped_gpc_xdc.tcl`, not per-run XDC;
            the bit-heap intermediate `.txt` files are deleted once the
            compressors have been written.
          - 'sim': behavioral simulation-only generator
            (`sim_rtl_gen.ntt.NTT_SimRTL_gen`). All butterfly modules
            concatenated into a single `<topName>_butterflies.sv`; no
            compressors, no `xdc_generated/`, no bit-heap files. Testvectors
            are byte-identical to the hw backend.

        Files land in `<run_dir>/RTL_generated/`
        (hw only), `<run_dir>/testvectors/` (when gen_testbench),
        `<run_dir>/manifest.json`.

        A local sanity check (off when sanity_check_size <= 0) round-trips the
        first `sanity_check_size` testvector lines to confirm the on-disk hex
        matches what propagateValue produces. **It re-drives this instance to
        do so**: `_sanityCheckNttTestvectors` calls `getInputsNatural` twice
        and `compute()`, so afterwards every port's `testVector` holds only
        those `sanity_check_size` rows, not the batch you loaded. Re-run
        `getInputsNatural(bounds)` / `getInputsNatural(batches)` / `compute()`
        before using the instance again — `runNTT128_GS_s130.py` does exactly
        that between its two emits — or pass `sanity_check_size=0` to leave the
        instance untouched.'''
        import dataclasses as _dataclasses
        import os as _os
        from pathlib import Path as _Path

        L = len(self.butterflies)
        if hw_manifest is not None:
            # a sim run pinned to a hardware run takes that run's request and
            # target, so the model's expectation below is formed from them too
            import json as _json
            with open(hw_manifest, encoding='utf-8') as f:
                hw = _json.load(f)
            pipeline_stages_per_layer = list(hw['pipeline_stages_per_layer'])
            target_fmax_mhz = hw.get('target_fmax_mhz')
        if target_fmax_mhz is None:
            target_fmax_mhz = getattr(self.scheme, 'targetFmaxMhz', None)
        # One source of truth for the target: the butterfly schemes, which are
        # what `latency()`, `layerLatencies()` and `reset()` read. An explicit
        # target here is written through to them, so the model cannot report
        # a depth other than the one built (found by review, Sept 2026).
        for layer in self.butterflies:
            for bfly in layer:
                bfly.scheme.targetFmaxMhz = target_fmax_mhz
        if hasattr(self.scheme, 'targetFmaxMhz'):
            self.scheme.targetFmaxMhz = target_fmax_mhz
        if isinstance(pipeline_stages_per_layer, int):
            pipeline_stages_per_layer = [pipeline_stages_per_layer] * L
        if len(pipeline_stages_per_layer) != L:
            raise ValueError(
                f'pipeline_stages_per_layer must have length log2(n)={L}, '
                f'got {len(pipeline_stages_per_layer)}'
            )

        run_dir = _Path(run_dir)
        run_dir.mkdir(parents=True, exist_ok=True)

        spec = self.getOperatorInterface(name=topName, pipelineStagesPerLayer=list(pipeline_stages_per_layer))
        datapathButterflies = [(s, p) for s, layer in enumerate(self.butterflies)
                               for p, bfly in enumerate(layer) if _schedulesItself(bfly.scheme)]
        if datapathButterflies and backend != 'hw':
            raise ValueError(f'{self.name}.emitRtl: datapath butterflies (ModularBU) have the hw backend only')
        for s, p in datapathButterflies:
            # their dsp / booth multipliers are generated first, as a datapath operator's are
            bs = spec.butterflySpecs[s][p]
            subs = self.butterflies[s][p].scheme.submodules(bs, run_dir / '_sub' / bs.name)
            spec.butterflySpecs[s][p] = _dataclasses.replace(bs, submodules=subs)

        goldenXNatural = None
        goldenYNatural = None
        testSize = 0
        if gen_testbench:
            goldenXNatural, goldenYNatural = self._extractGoldensNatural()
            testSize = len(goldenXNatural)

        extra = {}
        if backend == 'sim':
            from sim_rtl_gen.ntt import NTT_SimRTL_gen as _gen
            extra['hw_manifest'] = hw_manifest
        elif backend == 'hw':
            from rtl_gen.ntt import NTT_RTL_gen as _gen
            extra['share_compressors'] = share_compressors
            if hw_manifest is not None:
                raise ValueError('hw_manifest pins the sim backend to a hardware run; the hw backend is that run')
        else:
            raise ValueError(f"backend must be 'hw' or 'sim', got {backend!r}")

        saved = _os.getcwd()
        _os.chdir(str(run_dir))
        try:
            manifest = _gen(
                spec=spec,
                pipeline_stages_per_layer=list(pipeline_stages_per_layer),
                gen_testbench=gen_testbench,
                test_size=testSize,
                visualization=visualization,
                golden_x_natural=goldenXNatural,
                golden_y_natural=goldenYNatural,
                target_fmax_mhz=target_fmax_mhz,
                **extra,
            )
        finally:
            _os.chdir(saved)

        expected = self.scheme.layerLatencies(list(pipeline_stages_per_layer))
        if manifest['layer_latency'] != expected:
            raise AssertionError(
                f'{self.name}.emitRtl: the generator built layer latencies '
                f'{manifest["layer_latency"]} but the model reports {expected}'
            )

        if gen_testbench and sanity_check_size > 0:
            _sanityCheckNttTestvectors(self, run_dir, spec, sanity_check_size)

        return manifest


def _schedulesItself(scheme) -> bool:
    """A butterfly scheme built on the datapath template (`ModularBU`), whose spec
    is scheduled on the operator side, as opposed to the generator-scheduled
    Goldilocks butterfly."""
    return hasattr(scheme, 'submodules') and hasattr(scheme, 'inner')


def _sanityCheckNttTestvectors(inst: 'FullyPipelinedNTT', run_dir, spec, sample_size: int = 8) -> None:
    '''Decode the first `sample_size` lines of x_in.txt and y_out.txt, drive
    the decoded x batch through the populated instance, and confirm each
    natural-output slot matches mod 2^slot_width. Catches twos-complement
    encoding bugs locally before any remote sim. Mirrors
    `scripts/build_ntt.py::sanity_check_ntt`.

    **Destructive to `inst`.** It re-drives the instance with `sample_size`
    rows, so every port's `testVector` is that short afterwards. The caller
    must re-drive before reusing it; see `FullyPipelinedNTT.emitRtl`.'''
    from pathlib import Path as _Path
    n = inst.n
    L = len(inst.butterflies)
    inWidths = list(spec.inputBitWidthsNatural)
    inSigned = list(spec.inputIsSignedNatural)
    outWidths = list(spec.outputBitWidthsNatural)
    tv = _Path(run_dir) / 'testvectors'

    def _readHex(path, nLines):
        with path.open() as f:
            return [int(line.strip(), 16) for _, line in zip(range(nLines), f) if line.strip()]

    xPacked = _readHex(tv / 'x_in.txt', sample_size)
    yPacked = _readHex(tv / 'y_out.txt', sample_size)
    nLines = min(len(xPacked), len(yPacked))
    if nLines == 0:
        raise RuntimeError('emitRtl sanity-check: no testvectors loaded from disk')

    def _decodePerSlotSigned(packed):
        out = []
        offset = 0
        for w, signed in zip(inWidths, inSigned):
            v = (packed >> offset) & ((1 << w) - 1)
            if signed and (v >> (w - 1)):
                v -= (1 << w)
            out.append(v)
            offset += w
        return out

    def _decodePerSlotUnsigned(packed):
        out = []
        offset = 0
        for w in outWidths:
            v = (packed >> offset) & ((1 << w) - 1)
            out.append(v)
            offset += w
        return out

    xDecoded = [_decodePerSlotSigned(p) for p in xPacked[:nLines]]
    yDecoded = [_decodePerSlotUnsigned(p) for p in yPacked[:nLines]]

    inputBoundsByNatural = [p.bound for p in inst.inputPorts]

    nInputs = [[xDecoded[b][i] for b in range(nLines)] for i in range(n)]
    inst.getInputsNatural(inputBoundsByNatural)
    inst.getInputsNatural(nInputs)
    inst.compute()

    pipelineOutNatural = [p.testVector for p in inst.outputPorts]

    mismatches = 0
    for b in range(nLines):
        for i in range(n):
            expected = pipelineOutNatural[i][b] & ((1 << outWidths[i]) - 1)
            actual = yDecoded[b][i]
            if expected != actual:
                mismatches += 1
                if mismatches <= 5:
                    print(f'[emitRtl] sanity-check mismatch batch={b} idx={i}: '
                          f'expected {expected:x}, got {actual:x}')
    if mismatches > 0:
        raise RuntimeError(
            f'emitRtl sanity-check FAILED: {mismatches} mismatches out of '
            f'{nLines * n} slots — twos-complement encoding bug?'
        )
    print(f'[emitRtl] sanity-check OK: {nLines} batches × {n} slots = {nLines * n} OK')


class FullyPipelinedINTT(FullyPipelinedNTT):
    '''Inverse fully-pipelined NTT. Identical to FullyPipelinedNTT in wiring, scheme attachment, compute pipeline, and output reporting; the inverse-ness lives entirely in the twiddles passed in (use calculateInttTwiddles to generate them with w^(-1) or psi^(-1) as the base). The 1/n scaling factor at the end of the inverse transform is intentionally omitted here; apply it externally if needed.'''
    pass
