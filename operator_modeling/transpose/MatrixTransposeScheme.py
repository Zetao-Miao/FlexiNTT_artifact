'''Matrix-transpose schemes: the observable behaviour of a corner turn.

A transpose has no arithmetic. Nothing is added, nothing is multiplied, and no
value ever changes — the same values arrive at different ports. So what a scheme
of this family varies is not a decomposition or a network shape, as it is for
multipliers and NTTs, but the **port contract** and the **storage
architecture**: how long before the first output, how much has to be in flight
at once, and what the hardware that holds it costs.

Three schemes:

    BehaviouralMatrixTranspose      the contract only: values move, no hardware,
                                    a latency the caller declares (the four-step's
                                    default while its datapath is being sized)
    BarrelMemoryBarrelTranspose     rtl/matrix_transpose/bmb_matrix_transpose.sv:
                                    barrel shifter, one BRAM bank, barrel shifter
    MemoryBarrelMemoryTranspose     rtl/matrix_transpose/mbm_matrix_transpose.sv:
                                    BRAM bank, barrel shifter, BRAM bank

The two hardware schemes report what their RTL is built from: the shifters'
LUTs by construction, the BRAM tiles from the banks' depth and width, the
latency from the registers placed in the shifters, and a cycle-accurate twin
(`versal_arith/transpose_model.py`, one Python class per module) that the
operator steps as its clock. Where the registers go is the timing model's
decision (`lut_timing`): by default one after every mux stage, the structure
the module has as written; a stage count or a frequency target places them
from the calibrated table instead.

**A batch carries whole matrices.** A batch of `B = T * rows` is read as `T`
stacked matrices, with slot `b = t*rows + r` holding row `r` of matrix `t`. That
keeps this operator batch-at-once like every other one in the project, so it
connects to them through ports without an accumulator in between. The price is
that `B` must be a multiple of `rows`, which is the one place in the project a
batch length is constrained. Under the clocked `step()` the same batch axis is
time: the row presented at step `t*rows + r` is that slot.
'''
from __future__ import annotations

import os as _os
import sys as _sys
from abc import abstractmethod

from ..core.IntType import IntType
from ..core.OperatorScheme import OperatorScheme
from ..core.Resources import Resources

# The hardware twin and the timing table live beside the RTL in versal_arith/,
# imported unqualified the way every versal_arith module is.
_versalArithDir = _os.path.normpath(_os.path.join(_os.path.dirname(__file__), '..', '..', 'versal_arith'))
if _versalArithDir not in _sys.path:
    _sys.path.append(_versalArithDir)


class MatrixTransposeScheme(OperatorScheme):
    '''Base for a matrix-transpose architecture. Owns the transpose and the
    declared port contract; the operator owns the ports.

    `_BOUND_ATTRS` / `_VALUE_ATTRS` are empty for the reason `FullyPipelinedGrid`
    leaves them empty: the base class's checks assume one scalar `IntType` per
    named slot, and this scheme holds one per lane. The shape checks below take
    their place.
    '''

    _BOUND_ATTRS = ()
    _VALUE_ATTRS = ()

    def __init__(self, name: str = 'Undefined MatrixTransposeScheme',
                 rows: int = 0, cols: int = 0):
        super().__init__(name)
        if rows <= 0 or cols <= 0:
            raise ValueError(
                f'{name}: rows and cols must be positive, got {rows} x {cols}'
            )
        self.rows = rows
        self.cols = cols
        #: One bound per input lane, length `rows`.
        self.aIn: list[IntType] | None = None
        #: One value batch per input lane, length `rows`; each batch is `T*rows`.
        self.aInValues: list[list[int]] | None = None

    # ------------------------------------------------------------------
    # The declared port contract — what a sibling scheme varies
    # ------------------------------------------------------------------

    @abstractmethod
    def primingBeats(self) -> int:
        '''Beats before the first output row can appear.'''

    @abstractmethod
    def throughputRowsPerBeat(self) -> int:
        '''Rows emitted per beat once primed.'''

    @abstractmethod
    def minimumStorageElements(self) -> int:
        '''Lower bound on elements in flight. A floor, not a cost — it says what
        no implementation can go below, not what any particular one spends.'''

    # ------------------------------------------------------------------
    # Shape checks, standing in for the base class's scalar checks
    # ------------------------------------------------------------------

    def matrixCount(self, batchSize: int) -> int:
        '''How many stacked matrices a batch of `batchSize` carries.

        The one place the batch-length rule is enforced. Everywhere else in this
        project a batch may be any length; here it must be whole matrices,
        because the batch axis carries the row index as well as the trial index.
        '''
        if batchSize <= 0 or batchSize % self.rows:
            raise ValueError(
                f'{self.name}: batch length {batchSize} is not a positive '
                f'multiple of rows={self.rows}. A batch here carries whole '
                f'matrices — slot b = t*{self.rows} + r is row r of matrix t — '
                f'so use {self.rows}, {2 * self.rows}, {3 * self.rows}, ...'
            )
        return batchSize // self.rows

    def _checkLanes(self, lanes, attr: str, expected: int) -> None:
        if not isinstance(lanes, list):
            raise TypeError(
                f'{type(self).__name__}.{attr} must be a list of {expected} '
                f'lanes, got {type(lanes).__name__}'
            )
        if len(lanes) != expected:
            raise ValueError(
                f'{type(self).__name__}.{attr} must have {expected} lanes, '
                f'got {len(lanes)}'
            )

    # ------------------------------------------------------------------
    # The transpose itself — identical for every architecture
    # ------------------------------------------------------------------

    def transposeBatches(self, lanes: list[list[int]]) -> list[list[int]]:
        '''Transpose each stacked matrix within a per-lane batch.

            out[c][t*rows + r] == in[r][t*rows + c]

        The single place the index swap is written; `propagateValue` and the
        operator both route through it, so a row/column mistake cannot exist in
        one and not the other. At `T = 1` this is the plain matrix transpose.
        '''
        self._checkLanes(lanes, 'lanes', self.rows)
        batchSize = len(lanes[0])
        if any(len(v) != batchSize for v in lanes):
            raise ValueError(
                f'{self.name}: lanes carry batches of differing lengths '
                f'{sorted({len(v) for v in lanes})}'
            )
        matrices = self.matrixCount(batchSize)
        rows = self.rows
        return [[lanes[r][t * rows + c]
                 for t in range(matrices) for r in range(rows)]
                for c in range(self.cols)]

    def propagateBound(self) -> list[IntType]:
        '''One bound per output lane.

        Output lane `c` takes slot `t*rows + r` from input lane `r`, so as `r`
        sweeps it draws from **every** input lane. One bound per port for a whole
        batch therefore means every output bound is the union of every input
        bound — and all output lanes end up with the same one.
        '''
        super().propagateBound()
        self._checkLanes(self.aIn, 'aIn', self.rows)
        for c, bound in enumerate(self.aIn):
            if not isinstance(bound, IntType):
                raise TypeError(
                    f'{type(self).__name__}.aIn[{c}] must be an IntType, got '
                    f'{type(bound).__name__}'
                )
        return [IntType.union(self.aIn)] * self.cols

    def propagateValue(self) -> list[list[int]]:
        '''One value batch per output lane, each stacked matrix transposed.'''
        super().propagateValue()
        self._checkLanes(self.aInValues, 'aInValues', self.rows)
        for c, batch in enumerate(self.aInValues):
            if not isinstance(batch, list):
                raise TypeError(
                    f'{type(self).__name__}.aInValues[{c}] must be a list[int], '
                    f'got {type(batch).__name__}'
                )
        return self.transposeBatches(self.aInValues)

    # ------------------------------------------------------------------
    # The hardware, where there is one
    # ------------------------------------------------------------------

    def buildHardware(self):
        '''The cycle-accurate twin of this scheme's RTL, for `MatrixTranspose.
        step()`. A scheme with no hardware raises.'''
        raise NotImplementedError(
            f'{self.name}: {type(self).__name__} has no hardware to step -- it '
            f'models the port contract only. Use BarrelMemoryBarrelTranspose or '
            f'MemoryBarrelMemoryTranspose for a clocked model.'
        )


class BehaviouralMatrixTranspose(MatrixTransposeScheme):
    '''A corner turn that never pauses reception, modelled and not implemented.

    The hardware contract: one row in every beat, forever; nothing out for the
    first `rows` beats; one transposed row out every beat after that, belonging
    to the matrix received during the previous `rows` beats.

    Only the priming figure is derived, and from the algorithm rather than from
    any hardware: transposed row 0 contains `X[rows-1][0]`, which does not
    arrive until the final beat of the first matrix, so nothing can be emitted
    sooner. Note this is now a *declared* number — the model is batch-at-once and
    untimed like the rest of the project, so nothing here demonstrates it.

    Deliberately **unlike** a real scheme, and for the same reason
    `BehaviouralMult` is:

      - no storage architecture, so no area;
      - no latency of its own, only one the caller declares.

    `areaCost`, `resources` and `emitRtl` therefore raise rather than returning
    something plausible. A corner turn at n = 128 holds at least 16384 elements
    in flight, which at the 66 bits a four-step carries there — the transpose
    runs ahead of the inter-stage multipliers, see `FourStepScheme`'s docstring —
    is 132 KiB, the largest single block in a four-step NTT. A placeholder
    reporting zero would make every design containing one look free, which is
    precisely the comparison a placeholder must not corrupt.
    '''

    def __init__(self, name: str = 'Undefined BehaviouralMatrixTranspose',
                 rows: int = 0, cols: int = 0,
                 assumedLatency: int | None = None):
        super().__init__(name, rows, cols)
        if rows != cols:
            raise ValueError(
                f'{name}: only square transposes are supported for now, got '
                f'{rows} x {cols}. The transpose itself already generalises; '
                f'lifting this means relaxing the lane-count and batch-length '
                f'checks together.'
            )
        #: Latency to report. Assumed, not derived — there is no hardware to
        #: derive it from. `primingBeats()` is the separate, provable number.
        self.assumedLatency = assumedLatency

    # --- the declared contract -------------------------------------------

    def primingBeats(self) -> int:
        return self.rows

    def throughputRowsPerBeat(self) -> int:
        return 1

    def minimumStorageElements(self) -> int:
        return self.rows * self.cols

    # --- latency ----------------------------------------------------------

    def latency(self, pipelineStages: int = 1) -> int:
        '''Assumed, not derived. For the number that *is* forced by the
        algorithm, see `primingBeats()`.'''
        if pipelineStages < 1:
            raise ValueError(
                f'{self.name}: pipelineStages must be >= 1, got {pipelineStages}. '
                f'A corner turn cannot be combinational -- it cannot emit a '
                f'column before it has read the last row of the matrix -- so '
                f'0 has no meaning here, unlike every other block in the '
                f'project. The hardware corner turns derive their latency from '
                f'their register plan and ignore this argument entirely; if the '
                f'0 came from a `FourStepScheme.latency(0)` call, that is where '
                f'it was passed down from.'
            )
        return (self.assumedLatency if self.assumedLatency is not None
                else pipelineStages)

    # --- refusals ---------------------------------------------------------

    def areaCost(self) -> tuple[int, int]:
        raise NotImplementedError(
            f'{self.name}: BehaviouralMatrixTranspose has no area — it models '
            f'the port behaviour and picks no storage architecture, and a '
            f'(LUT, DSP) pair could not express a memory in any case. '
            f'Returning 0 would make the largest block in a four-step NTT look '
            f'free, which is exactly the comparison a placeholder must not '
            f'corrupt. See minimumStorageElements() for the floor '
            f'({self.minimumStorageElements()} elements), or pick '
            f'BarrelMemoryBarrelTranspose / MemoryBarrelMemoryTranspose.'
        )

    def resources(self) -> Resources:
        raise NotImplementedError(
            f'{self.name}: BehaviouralMatrixTranspose spends nothing because it '
            f'builds nothing; a real scheme reports its LUTs and BRAM tiles.'
        )

    def getOperatorInterface(self, name: str, pipelineStages: int = 1):
        raise NotImplementedError(
            f'{self.name}: BehaviouralMatrixTranspose describes no hardware, so '
            f'there is no spec to build. This scheme exists to propagate bounds '
            f'and values through a corner turn, not to describe one to a '
            f'generator; BarrelMemoryBarrelTranspose and '
            f'MemoryBarrelMemoryTranspose do.'
        )


# ----------------------------------------------------------------------
# The two implemented architectures
# ----------------------------------------------------------------------

def bramTiles(depth: int, width: int) -> Resources:
    '''Block RAM tiles one `BRAM.sv` instance of `depth` words of `width` bits
    takes on Versal, as `xpm_memory_sdpram` with `MEMORY_PRIMITIVE = "block"`
    maps it: the widest simple-dual-port shape a tile offers at that depth
    (a BRAM36 is 72 wide up to 512 deep, halving as the depth doubles; a
    BRAM18 is 36 wide up to 512 deep), one BRAM18 when the word fits in one,
    otherwise as many BRAM36 as the word needs side by side.

    A rule, confirmed against the implemented banks (DEBUG.md section 8).
    '''
    if depth < 1 or width < 1:
        raise ValueError(f'a memory needs positive depth and width, got {depth} x {width}')
    widest36 = min(72, (36 * 1024) // max(depth, 1))
    widest18 = min(36, (18 * 1024) // max(depth, 1))
    if widest18 >= 1 and -(-width // widest18) == 1:
        return Resources(bram18=1)
    if widest36 < 1:
        raise ValueError(f'a {depth}-deep memory does not fit one tile column at any width')
    return Resources(bram36=-(-width // widest36))


class _HardwareMatrixTranspose(MatrixTransposeScheme):
    '''What the two implemented transposes share: square, a power of two, one
    barrel-shifter placement chosen by the timing model, the twin, the spec.

    Configuration is the constructor's, not `latency()`'s argument: the
    transposes take no per-call request, exactly as `DspMultiplierScheme`
    ignores `pipelineStages`, because the placement belongs to the scheme
    that will emit the RTL. Precedence: `targetFmaxMhz` (fewest registers
    reaching it, `lut_timing.transpose_flags_for_fmax`), then
    `pipelineStages` (that many, `lut_timing.barrel_reg_flags`; 0 is a
    combinational shifter), then the default, a register after every mux
    stage -- the module as written. A target needs the element width, so
    the bounds must be loaded first.
    '''

    #: 'bmb' | 'mbm', the module and the twin.
    architecture = ''
    #: Shifter instances in the datapath.
    shifterCount = 0
    #: LUTs of everything in the transpose that is neither a shifter nor a
    #: bank -- the counters, the sidebands and the replicas Vivado makes of
    #: them, the per-lane address arithmetic -- per lane, from the twelve
    #: implemented transposes (DEBUG.md section 8c; within 1.7 % of every
    #: total at N = 32..128, W = 32, 64 -- worst case mbm at N = 64, W = 64:
    #: 12288 + 256 = 12544 modelled against 12761 measured, -1.70 %. Gate 4
    #: in runMatrixTranspose.py pins it at 5 %).
    controlLutsPerLane = 0

    def __init__(self, name: str = 'Undefined hardware transpose',
                 rows: int = 0, cols: int = 0,
                 pipelineStages: int | None = None,
                 targetFmaxMhz: float | None = None):
        super().__init__(name, rows, cols)
        if rows != cols:
            raise ValueError(
                f'{name}: only square transposes are supported, got {rows} x {cols}'
            )
        if rows < 2 or rows & (rows - 1):
            raise ValueError(
                f'{name}: the dimension must be a power of two >= 2, got {rows} '
                f'(the barrel shifter rotates on the bits of the row index)'
            )
        if pipelineStages is not None and pipelineStages < 0:
            raise ValueError(f'{name}: pipelineStages must be >= 0, got {pipelineStages}')
        if targetFmaxMhz is not None and targetFmaxMhz <= 0:
            raise ValueError(f'{name}: targetFmaxMhz must be > 0, got {targetFmaxMhz}')
        self.pipelineStages = pipelineStages
        self.targetFmaxMhz = targetFmaxMhz

    # --- placement --------------------------------------------------------

    def stagePlan(self) -> tuple[bool, ...]:
        '''The shifter's register flags, one per mux stage (`REG_FLAGS`).'''
        from transpose_model import default_flags
        n = self.rows
        if self.targetFmaxMhz is not None:
            from lut_timing import transpose_flags_for_fmax
            return tuple(transpose_flags_for_fmax(self.architecture, n, self.elementWidth(),
                                                  self.targetFmaxMhz, label=self.name))
        if self.pipelineStages is not None:
            from lut_timing import barrel_reg_flags
            return tuple(barrel_reg_flags(n, self.pipelineStages))
        return default_flags(n)

    def barrelLatency(self) -> int:
        '''Registers in each shifter under the plan.'''
        from transpose_model import barrel_latency
        return barrel_latency(self.stagePlan())

    # --- the contract -------------------------------------------------------

    def latency(self, pipelineStages: int | None = None) -> int:
        '''Cycles from a row on data_in to the same-numbered column on
        data_out, from the registers the plan places (the twin counts the
        same number; `runMatrixTranspose.py` asserts it). The argument is
        ignored: see the class docstring.'''
        return self._latencyFormula(self.rows, self.stagePlan())

    @staticmethod
    def _latencyFormula(n: int, flags) -> int:
        raise NotImplementedError

    def primingBeats(self) -> int:
        return self.latency()

    def throughputRowsPerBeat(self) -> int:
        return 1

    def minimumStorageElements(self) -> int:
        return self.rows * self.cols

    # --- what it costs -------------------------------------------------------

    def elementWidth(self) -> int:
        '''Bits per element: the union input bound's width, once `compute()`
        has loaded the bounds.'''
        if self.aIn is None:
            raise ValueError(
                f'{self.name}: the element width is the input bound\'s and no '
                f'bounds are loaded -- drive the operator and compute() first'
            )
        self._checkLanes(self.aIn, 'aIn', self.rows)
        return IntType.union(self.aIn).bitWidth

    def isSigned(self) -> bool:
        if self.aIn is None:
            raise ValueError(f'{self.name}: no bounds loaded')
        return IntType.union(self.aIn).isSigned

    def bankDepths(self) -> tuple[int, ...]:
        '''Depth of each BRAM bank, one entry per bank.'''
        raise NotImplementedError

    def resources(self) -> Resources:
        '''LUTs by construction (the shifters' mux stages, from
        `transpose_model.barrel_luts`) plus the measured control logic per
        lane, and BRAM tiles by the `bramTiles` rule for every bank lane.'''
        from transpose_model import barrel_luts
        n, w = self.rows, self.elementWidth()
        luts = self.shifterCount * barrel_luts(n, w) + self.controlLutsPerLane * n
        tiles = Resources()
        for depth in self.bankDepths():
            per_lane = bramTiles(depth, w)
            tiles = tiles + Resources(bram36=per_lane.bram36 * n, bram18=per_lane.bram18 * n)
        return Resources(lut=luts) + tiles

    def areaCost(self) -> tuple[int, int]:
        return (self.resources().lut, 0)

    def criticalPathNs(self) -> float:
        '''The slowest register-to-register path under the plan, from the
        calibrated table (`lut_timing.transpose_critical_ns`).'''
        from lut_timing import transpose_critical_ns
        return transpose_critical_ns(self.architecture, self.rows, self.elementWidth(),
                                     self.stagePlan())[0]

    def achievedFmaxMhz(self) -> float:
        from lut_timing import fmax_of
        return fmax_of(self.criticalPathNs())

    # --- the hardware ----------------------------------------------------------

    def buildHardware(self):
        raise NotImplementedError

    def getOperatorInterface(self, name: str, pipelineStages: int | None = None):
        '''The frozen spec for `rtl_gen.transpose.Transpose_RTL_gen`; needs the
        bounds loaded for the element width. `pipelineStages` is ignored (see
        the class docstring).'''
        from transpose_spec import TransposeOperatorSpec
        flags = self.stagePlan()
        return TransposeOperatorSpec(name=name, rows=self.rows, cols=self.cols,
                                     elementWidth=self.elementWidth(),
                                     isSigned=self.isSigned(),
                                     architecture=self.architecture,
                                     regFlags=flags,
                                     latency=self._latencyFormula(self.rows, flags))


class BarrelMemoryBarrelTranspose(_HardwareMatrixTranspose):
    '''`bmb_matrix_transpose.sv`: barrel shifter, one BRAM bank, barrel
    shifter. Row r is rotated by r into the bank, the whole matrix is stored,
    then drained column by column on the diagonal and rotated back. Any gap
    between bursts; latency `n + 2*s + 1` for `s` registers per shifter.'''

    architecture = 'bmb'
    shifterCount = 2
    controlLutsPerLane = 6

    @staticmethod
    def _latencyFormula(n: int, flags) -> int:
        from transpose_model import bmb_latency
        return bmb_latency(n, flags)

    def bankDepths(self) -> tuple[int, ...]:
        return (self.rows,)

    def buildHardware(self):
        from transpose_model import BmbTranspose
        return BmbTranspose(self.rows, self.stagePlan())


class MemoryBarrelMemoryTranspose(_HardwareMatrixTranspose):
    '''`mbm_matrix_transpose.sv`: BRAM bank, barrel shifter, BRAM bank. Lane i
    of the input bank delays by i+1 rows, the shifter rotates each
    anti-diagonal, lane j of the output bank delays by n-j. Every matrix is
    re-aligned to the module's free-running n-cycle frame through an input
    bank two matrices deep, so any gap between bursts works; latency
    `n + s + 3` for `s` shifter registers when a burst starts on the frame,
    plus the wait for the frame otherwise (the twin reproduces it).'''

    architecture = 'mbm'
    shifterCount = 1
    controlLutsPerLane = 4

    @staticmethod
    def _latencyFormula(n: int, flags) -> int:
        from transpose_model import mbm_latency
        return mbm_latency(n, flags)

    def bankDepths(self) -> tuple[int, ...]:
        return (2 * self.rows, self.rows)

    def buildHardware(self):
        from transpose_model import MbmTranspose
        return MbmTranspose(self.rows, self.stagePlan())
