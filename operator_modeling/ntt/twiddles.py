'''Twiddle factors: computing them, and moving them to and from a spreadsheet.

Split out of the operator module (then `NTT.py`) for a concrete reason. That module did
`from sage.all import GF` unconditionally, so *any* import of it paid for Sage —
including `scripts/build_butterfly.py`, which only ever wanted
`loadTwiddlesFromXlsx`. The xlsx half needs openpyxl and no Sage; the
computation half needs Sage and no openpyxl. Separating them lets each caller
pay only for what it uses.

That separation is only half-done here, because this module still imports Sage
at the top for `calculateNttTwiddles`, so `loadTwiddlesFromXlsx` pays for it
too. The spreadsheet *machinery* therefore lives in `core.utils`, which imports
neither Sage nor (eagerly) openpyxl: anything that wants a NAF grid off a sheet
can call `loadXlsxNafGrid` and skip this module entirely. What stays here is
only the part that is genuinely about twiddles — the "Layer" header prefix and
the one-column-per-stage orientation.
'''
from __future__ import annotations

from math import log2

from sage.all import GF

from .roots import fixedRoot

from ..core.utils import (MEM_GRID_ORDERS, bitReverse, loadMemFile,
                          loadXlsxHeaders,
                          loadXlsxNafGrid, nafTermsModulusLift,
                          saveXlsxNafGrid)

def calculateNttTwiddles(modulus: int,
                         n: int,
                         butterflyType: str,
                         primitiveRoot: int | None = None,
                         negacyclic: bool = False,
                         useModulusLiftingNaf: bool = False,
                         maxPower: int = 95,
                         maxMultipleOfModulus: int = 2**32,
                         maxSearchDepth: int = 3,
                         beamWidth: int = 200,
                         maxNumberOfTerms: int = 96) -> list[list[int | list[tuple[int, int]]]]:
    '''Use sage to calculate the twiddle factors of the target NTT. Returns list[list[int | list[tuple[int, int]]]] of shape log2(n) x n/2: outer list indexes pipeline stages, inner list indexes butterflies within a stage in physical top-to-bottom order. If useModulusLiftingNaf is True, each twiddle is replaced by its NAF lift (a list of (sign, exponent) tuples). CT assumes bit-reversed input -> natural output (stride doubles each stage). GS assumes natural input -> bit-reversed output (stride halves each stage). Cyclic uses w = F.zeta(n) with linear exponent progression j * stepExp. Negacyclic uses psi = F.zeta(2n) with odd exponent progression (2j+1) * stepExp — only valid for forward NTT in CT direction (the GS butterfly equation does not admit a clean pre-twist absorption for forward NWC). The lift parameters bound the *search*, not the hardware: GoldilocksSlice64 accepts at most 3 NAF terms per twiddle (ButterflyScheme.py, `_liftTwiddle`) and lifts integer twiddles itself with maxPower=95, maxMultipleOfModulus=2**32, maxSearchDepth=3, beamWidth=200, maxNumberOfTerms=3. So a grid computed with useModulusLiftingNaf=True at the 96-term default can contain twiddles that butterfly then refuses; pass maxNumberOfTerms=3 to match it, or leave useModulusLiftingNaf=False and let the scheme do the lift.'''
    if n < 2 or (n & (n - 1)) != 0:
        raise ValueError(f'n must be a power of 2 and at least 2, got {n}')
    if butterflyType not in ('CT', 'GS'):
        raise ValueError(f"butterflyType must be 'CT' or 'GS', got {butterflyType!r}")
    if negacyclic and butterflyType != 'CT':
        raise ValueError(
            f"negacyclic forward NTT requires butterflyType == 'CT'; "
            f"got {butterflyType!r}. The GS butterfly equation puts the twiddle "
            f"on the subtract branch's bOut, which prevents clean pre-twist absorption "
            f"into per-butterfly twiddles. Use CT for forward NWC and GS for inverse NWC."
        )

    F = GF(modulus)
    if primitiveRoot is None:
        base = fixedRoot(F, 2 * n) if negacyclic else fixedRoot(F, n)
    else:
        # Coerce into GF(modulus): a raw Python int is raised to the stage
        # exponent unreduced below, and `calculateInttTwiddles`'s cyclic path
        # always arrives here, because it passes `int(forwardBase ** -1)`.
        # That function already coerces the same way.
        base = F(primitiveRoot)
    L = int(log2(n))

    twiddles: list[list[int | list[tuple[int, int]]]] = []
    for s in range(L):
        if butterflyType == 'CT':
            stride = 1 << s              # butterflies per group; doubles each stage
            groupSize = stride << 1      # 2^(s+1)
        else:                            # 'GS'
            groupSize = 1 << (L - s)     # halves each stage
            stride = groupSize >> 1
        repeats = n // groupSize         # group pattern repetition count to fill n/2 butterflies
        stepExp = n // groupSize         # exponent step (= n/groupSize)

        if negacyclic:
            # NWC merged twiddle in physical butterfly order: ψ^((2j+1) * stepExp).
            # Derived from path-product analysis: cyclic ω-exponent is j*stepExp; in ψ
            # that's 2j*stepExp; absorbing the per-stage pre-twist factor ψ^(2^(L-1-s)) =
            # ψ^stepExp adds +stepExp, giving (2j+1)*stepExp. Always odd, ranges over
            # the n distinct primitive 2n-th roots that aren't n-th roots.
            baseExps = [(2 * j + 1) * stepExp for j in range(stride)]
        else:
            baseExps = [j * stepExp for j in range(stride)]
        stageExps = baseExps * repeats

        stageTwiddles: list[int | list[tuple[int, int]]] = [int(base ** e) for e in stageExps]
        if useModulusLiftingNaf:
            stageTwiddles = [
                nafTermsModulusLift(t, modulus, maxPower, maxMultipleOfModulus,
                                    maxSearchDepth, beamWidth, maxNumberOfTerms)[1]
                for t in stageTwiddles
            ]
        twiddles.append(stageTwiddles)

    return twiddles


def calculateInttTwiddles(modulus: int,
                          n: int,
                          butterflyType: str,
                          primitiveRoot: int | None = None,
                          negacyclic: bool = False,
                          useModulusLiftingNaf: bool = False,
                          maxPower: int = 95,
                          maxMultipleOfModulus: int = 2**32,
                          maxSearchDepth: int = 3,
                          beamWidth: int = 200,
                          maxNumberOfTerms: int = 96) -> list[list[int | list[tuple[int, int]]]]:
    '''Inverse-NTT twiddle factors. Same shape and conventions as calculateNttTwiddles, but uses w^(-1) (cyclic) or psi^(-1) (negacyclic) as the base so the resulting pipeline computes the inverse transform — modulo the 1/n scaling, which is intentionally omitted; apply externally if needed. For negacyclic, only GS is valid (forward NWC uses CT, inverse NWC uses GS — the standard NWC pairing). The lift parameters bound the *search*, not the hardware: GoldilocksSlice64 accepts at most 3 NAF terms per twiddle (ButterflyScheme.py, `_liftTwiddle`) and lifts integer twiddles itself with maxPower=95, maxMultipleOfModulus=2**32, maxSearchDepth=3, beamWidth=200, maxNumberOfTerms=3. So a grid computed with useModulusLiftingNaf=True at the 96-term default can contain twiddles that butterfly then refuses; pass maxNumberOfTerms=3 to match it, or leave useModulusLiftingNaf=False and let the scheme do the lift.'''
    if negacyclic and butterflyType != 'GS':
        raise ValueError(
            f"negacyclic inverse NTT requires butterflyType == 'GS'; "
            f"got {butterflyType!r}. Standard NWC pairing: forward = CT, inverse = GS. "
            f"The CT butterfly equation does not admit a clean post-twist absorption for inverse NWC."
        )
    F = GF(modulus)
    forwardBase = F(primitiveRoot) if primitiveRoot is not None else (fixedRoot(F, 2 * n) if negacyclic else fixedRoot(F, n))
    inverseBase = int(forwardBase ** (-1))
    # For negacyclic, calculateNttTwiddles guards against GS — temporarily route through
    # cyclic semantics so we can build the inverse twiddles using the same (2j+1)*stepExp
    # progression but in GS direction. This is symmetric to the CT-forward case.
    if negacyclic:
        # Inverse NWC GS twiddle in physical order: ψ^(-(2j+1) * stepExp) where stepExp uses
        # GS group structure. Build directly here rather than calling calculateNttTwiddles.
        if n < 2 or (n & (n - 1)) != 0:
            raise ValueError(f'n must be a power of 2 and at least 2, got {n}')
        L = int(log2(n))
        psi = F(forwardBase)
        twiddles: list[list[int | list[tuple[int, int]]]] = []
        for s in range(L):
            groupSize = 1 << (L - s)
            stride = groupSize >> 1
            repeats = n // groupSize
            stepExp = n // groupSize
            baseExps = [(2 * j + 1) * stepExp for j in range(stride)]
            stageExps = baseExps * repeats
            stageTwiddles: list[int | list[tuple[int, int]]] = [int(psi ** (-e)) for e in stageExps]
            if useModulusLiftingNaf:
                stageTwiddles = [
                    nafTermsModulusLift(t, modulus, maxPower, maxMultipleOfModulus,
                                        maxSearchDepth, beamWidth, maxNumberOfTerms)[1]
                    for t in stageTwiddles
                ]
            twiddles.append(stageTwiddles)
        return twiddles
    return calculateNttTwiddles(modulus=modulus, n=n, butterflyType=butterflyType,
                                primitiveRoot=inverseBase, negacyclic=False,
                                useModulusLiftingNaf=useModulusLiftingNaf,
                                maxPower=maxPower, maxMultipleOfModulus=maxMultipleOfModulus,
                                maxSearchDepth=maxSearchDepth, beamWidth=beamWidth,
                                maxNumberOfTerms=maxNumberOfTerms)


def loadTwiddlesFromXlsx(path: str, sheetName: str = 'NTT_TWIDDLES') -> list[list[list[tuple[int, int]]]]:
    '''Load twiddles from an xlsx file matching the project's layout. Row 1 holds "Layer 1".."Layer L" headers (an optional trailing label cell like "GS BUTTERFLIES!!!" is ignored). Rows 2..n/2+1 hold per-butterfly twiddles in physical top-to-bottom order, columns are stages. Each cell is either a plain integer or a NAF expression like "-2^91 + 2^43". Returns list[list[list[tuple[int, int]]]] of shape L x (n/2): every twiddle is materialized as a NAF list (matching calculateNttTwiddles output with useModulusLiftingNaf=True). Integer cells are converted via nafTerms.

    The layout rules themselves live in `core.utils` — this function only supplies
    the two things that are specific to a twiddle grid: that the header prefix is
    "Layer", and that the sheet is stored one column per stage.'''
    if not loadXlsxHeaders(path, sheetName, prefix='layer'):
        raise ValueError(f'no "Layer N" headers found in row 1 of sheet {sheetName!r}')
    return loadXlsxNafGrid(path, sheetName, headerPrefix='layer', transpose=True)


def saveTwiddlesToXlsx(twiddles: list[list[int | list[tuple[int, int]]]], path: str, butterflyType: str, sheetName: str = 'NTT_TWIDDLES') -> None:
    '''Save twiddles in the calculated format (output of calculateNttTwiddles) to an xlsx file in the project's layout. Row 1 is "Layer 1".."Layer L" plus a trailing "<TYPE> BUTTERFLIES!!!" label. Rows 2..n/2+1 hold per-butterfly twiddles, written as NAF expression strings (e.g. "2^43 - 2^91" or "1"). Integer inputs are converted to NAF via nafTerms before writing. If the target file exists the named sheet is replaced and other sheets are preserved; otherwise a new workbook is created.

    Terms are written in the ascending-exponent order that `loadTwiddlesFromXlsx`
    canonicalises to, so load -> save -> load is stable. Re-saving a hand-written
    sheet whose terms run in another order (as `twiddles.xlsx` does, descending)
    rewrites those cells into ascending order: the same value, different text.'''
    L = len(twiddles)
    if L == 0:
        raise ValueError('twiddles must have at least one stage')
    halfN = len(twiddles[0])
    if any(len(layer) != halfN for layer in twiddles):
        raise ValueError('all stages of twiddles must have the same length')
    # Checked here rather than in the writer so the error names the offending
    # stage and butterfly; `nafToCell` only sees a lone value.
    for layerIdx, layer in enumerate(twiddles):
        for r, v in enumerate(layer):
            if isinstance(v, bool) or not isinstance(v, (int, list)):
                raise TypeError(f'unexpected twiddle value at stage {layerIdx}, butterfly {r}: {v!r}')

    saveXlsxNafGrid(twiddles, path, sheetName,
                    headers=[f'Layer {i + 1}' for i in range(L)],
                    label=f'{butterflyType} BUTTERFLIES!!!',
                    transpose=True)


#: Kept as a name of its own because callers import it; the definition lives
#: in core.utils, shared with the stage dumps that use the same flattening.
INTER_STAGE_ORDERS = MEM_GRID_ORDERS
INTER_STAGE_LANE_INDICES = ('bitReversed', 'natural')


def loadInterStageTwiddles(path: str,
                           m: int,
                           order: str = 'beatMajor',
                           laneIndex: str = 'bitReversed',
                           psi: int | None = None,
                           modulus: int | None = None) -> list[list[int]]:
    '''Load four-step inter-stage twiddles as one value-batch per lane.

    Returns a list of `2**m` batches, each `2**m` long: `result[j][b]` is the
    twiddle lane `j` consumes on beat `b`. That is the shape the model wants,
    because a lane's batch is exactly what `Signal.values` carries.

    The file itself is a flat `2**(2m)` image, and only its *order* says which
    of the two indices moves fastest:

        'beatMajor'  mem[beat * 2**m + lane]   128 consecutive words are one
                     beat across every lane, so a lane reads at stride 2**m
        'laneMajor'  mem[lane * 2**m + beat]   128 consecutive words are one
                     lane's whole batch

    Both are in use, they are transposes of each other, and nothing about the
    file's size or contents distinguishes them -- so this is a parameter rather
    than something to detect. Reading a beat-major image as lane-major yields a
    full-length, plausible batch of genuine twiddles that are simply the wrong
    ones, which no downstream shape check can catch.

    `laneIndex` says what the *caller's* index means, which is not the same
    question as `order`:

        'bitReversed'  indices are the file's own. A raw GS (DIF) datapath
                       carries frequency bitReverse(i, m) on internal wire i --
                       the `s{L-1}_p{p}_{a,b}Out` nets in `rtl_gen/ntt.py` --
                       and the file is written for those. This is *not* the
                       emitted NTT top's port order: `NTT_RTL_gen` un-permutes
                       on the way out through `spec.outputWiring`, so
                       `y_out_<k>` is natural frequency k, exactly like
                       `FullyPipelinedNTT.outputPorts`.
        'natural'      the frequency axis is un-permuted, so index k means
                       frequency k. This is the *model's* view:
                       `FullyPipelinedNTT.outputPorts` are in natural order.
                       Which axis gets corrected follows `order` -- the lane
                       under 'beatMajor', the slot under 'laneMajor' -- because
                       that is where the file's wire index lands.

    The defaults ('beatMajor', 'bitReversed') are the file-native pair. The only
    in-repo caller passes neither: `runFourStep16384.py` uses order='laneMajor',
    laneIndex='natural', because its corner turn runs ahead of the multipliers
    (so lane = t1, slot = k2) and it reads the sub-NTT's natural-order
    `outputPorts`. Neither pair is more correct than the other -- state both
    explicitly at every call site.

    Getting this wrong is silent -- both views are full-length batches of real
    twiddles -- so it is a parameter.

    **`psi`/`modulus` do NOT check that choice, and cannot.** They check the
    *file*: that it is a well-formed negacyclic twiddle image at this psi and
    modulus, in the odd-exponent form, with no corrupt or truncated word. They
    say nothing about which reading of it you asked for. The slice at `order`
    and the `(beat, wire)` re-derivation below key off the same `order`, and the
    `laneIndex` permutation is undone by the same `laneIndex` -- both compose to
    the identity, so `expected` reduces to one fixed predicate on raw flat
    indices no matter what pair is passed. On this project's own
    `inter_twiddles_ntt.mem`, all four combinations pass and all four return
    *different* tables.

    That is not a fixable check. Both readings of a well-formed file are
    themselves well-formed tables -- they are what the multiply-first and
    transpose-first pipelines respectively need -- so the file cannot know which
    one its consumer wants. The only thing that catches a wrong choice is
    end-to-end comparison against a reference that does not decompose; see
    `verification.referenceNttFast`, whose docstring records catching exactly
    this, a beat-major file read as lane-major, during bring-up. It was caught
    there and not here.

    The expected entry is

        psi ** (beat * (2*k + 1))    with   k = bitReverse(lane, m)

    the odd exponent carrying the negacyclic twist that the pre-twist bank left
    for the second dimension, and the bit reversal being there because a GS
    (DIF) sub-NTT emits lane `j` holding frequency `bitReverse(j, m)`.
    '''
    if laneIndex not in INTER_STAGE_LANE_INDICES:
        raise ValueError(
            f'loadInterStageTwiddles: laneIndex must be one of '
            f'{INTER_STAGE_LANE_INDICES}, got {laneIndex!r}'
        )
    if order not in INTER_STAGE_ORDERS:
        raise ValueError(
            f'loadInterStageTwiddles: order must be one of {INTER_STAGE_ORDERS}, '
            f'got {order!r}'
        )
    n = 2 ** m
    flat = loadMemFile(path)
    if len(flat) != n * n:
        raise ValueError(
            f'loadInterStageTwiddles: {path} holds {len(flat)} words, expected '
            f'{n * n} for m={m}'
        )

    if order == 'beatMajor':
        lanes = [flat[lane::n] for lane in range(n)]
    else:
        lanes = [flat[lane * n:(lane + 1) * n] for lane in range(n)]

    # The bit-reversal correction belongs to whichever axis carries the file's
    # *wire* index, and `order` decides which that is: under 'beatMajor' the
    # lane is the wire, under 'laneMajor' the slot is. Permuting the lane in
    # both cases would silently mis-order a laneMajor read.
    if laneIndex == 'natural':
        if order == 'beatMajor':
            lanes = [lanes[bitReverse(k, m)] for k in range(n)]
        else:
            lanes = [[batch[bitReverse(k, m)] for k in range(n)]
                     for batch in lanes]

    if (psi is None) != (modulus is None):
        raise ValueError(
            'loadInterStageTwiddles: pass both psi and modulus to verify, or '
            'neither to skip verification'
        )
    if psi is not None:
        for lane, batch in enumerate(lanes):
            for slot, value in enumerate(batch):
                # 'beatMajor' puts the beat on the slot axis and the wire on the
                # lane; 'laneMajor' swaps them.
                beat, wire = (slot, lane) if order == 'beatMajor' else (lane, slot)
                k = wire if laneIndex == 'natural' else bitReverse(wire, m)
                expected = pow(psi, beat * (2 * k + 1), modulus)
                if value != expected:
                    raise ValueError(
                        f'loadInterStageTwiddles: {path} lane {lane} slot '
                        f'{slot} is {value:#x}, expected {expected:#x}. This '
                        f'means the FILE is not a well-formed negacyclic twiddle '
                        f'image at psi={psi:#x}, modulus={modulus:#x} -- a wrong '
                        f'psi, a wrong m, or a corrupt word. It does NOT mean '
                        f'order/laneIndex are wrong: this check gives the same '
                        f'verdict for all four combinations, so switching them '
                        f'will not help.'
                    )
    return lanes
