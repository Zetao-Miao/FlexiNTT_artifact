'''The dataflow NTT scheme: P points per cycle stream through log2(n) stages of P/2 butterflies.

    StreamingNTTScheme   the model: order, twiddles, bit-exact values, cycles, resources

The operator is in `StreamingNTT.py`, the form with one lane per point in `UnrolledNTT.py`, and the area
count without a build in `StreamArea.py`. The iterative and the hybrid schemes borrow the root, exponent
and butterfly helpers of this class.
'''
from __future__ import annotations

from ..roots import fixedRoot
from ...core.IntType import IntType
from ...core.OperatorScheme import OperatorScheme
from ...core.utils import bitReverse

#: True (the search's models only, never an RTL run): butterflies built from the same constant, input bound and DSP
#: budget are ONE object, and its schedule, latency, area and bound are computed once. They are identical, so
#: the numbers are the same. Without this a core of 256 butterflies schedules the same multipliers 256 times.
SHARE_IDENTICAL_BU = False
#: 'global' (the search of the multi-step NTT): as True, and the butterflies are shared by every scheme of the
#: process, so two small transforms of different sizes and two cores with the same DSP split reuse them.
_BU_GLOBAL: dict = {}


def _memoBu(bu):
    '''Compute areaCost, propagateBound, latency and resources of this butterfly once per argument list.'''
    import copy
    for nm in ('areaCost', 'propagateBound', 'latency', 'resources'):
        fn = getattr(bu, nm, None)
        if fn is None:
            continue

        def wrap(*a, _fn=fn, _c={}, **k):
            key = (a, tuple(sorted(k.items())))
            if key not in _c:
                _c[key] = _fn(*a, **k)
            return copy.deepcopy(_c[key])
        setattr(bu, nm, wrap)
    return bu


class StreamingNTTScheme(OperatorScheme):
    '''A radix-2 NTT that streams P points per cycle through log2(n) stages of
    P/2 butterflies (AutoNTT's dataflow architecture; Allam et al.'s pipeline).

    Order. Point m of the in-place memory order (CT: bit-reversed natural input,
    GS: natural input) enters on lane `m mod P` at cycle `m // P` of its frame
    (a frame is F = n/P cycles; frames follow back to back). Each index bit of m
    sits on a lane bit or a cycle bit. A stage pairs the points that differ in
    its bit (CT: bit s, GS: bit L-1-s); while that bit is on a lane bit the
    pairs meet on two lanes in the same cycle and only the wiring changes. A
    stage whose bit is on cycle bit j first exchanges it with a lane bit whose
    index bit no later stage needs: delay one lane by D = 2^j, swap the pair on
    cycle bit j, delay the other by D (latency D, 2D words per lane pair). For
    CT this costs about n words over all stages, and the output leaves lane-major:
    `outputLocation(m)` says where each memory index ends.

    The modulus: `q=` fixed, or `family=` a run-time `ModulusFamily`: then the
    butterflies' modulus ports (Q, MU, QP, QH, K, C as the multiplier needs) are
    inputs of the whole pipeline, quasi-static (one q per job), and the twiddles
    depend on q (the root is `roots.fixedRoot(GF(q), n)`, psi = fixedRoot(2n) when negacyclic with w = psi^2, as
    `calculateNttTwiddles` picks it).

    Twiddles. Every butterfly slot (stage, lane pair) sees a fixed sequence of
    exponents over a frame (`seqs`). A slot whose twiddle never changes takes it
    as a design-time constant (fixed q; at run-time q only the twiddle 1). The
    others are supplied by `twiddleSource`:
      'rom'  per distinct sequence a table of F twiddles (fixed q);
      'ram'  the same tables, written through the twiddle load port for each q
             (AutoNTT's per-limb reload);
      'otf'  on the fly: a slot's exponent is linear in the frame-cycle bits, so
             w^e = w^(e_lo) * w^(e_hi) from two tables of ~sqrt(F) entries and
             one modular multiplier per distinct sequence (Allam et al.'s
             two-level roots); tables are ROMs at a fixed q, loaded at run time.
      'rec'  root recurrence (Kim et al.'s root-of-unity generator): a class whose
             exponent is c + g0*(t mod 2^k) takes w(t) = w(t-D) * w^(g0*D) from one
             modular multiplier (D = its latency + 1), the first D values of every
             period from a base table of D words, the update constant from a word;
             a class with 2^k <= D is a plain table (no multiplier).
    Stored values are in the multiplier's domain (times R for the Montgomery
    family) and carry Shoup's companion when the butterflies use Shoup.

    Directions: 'forward', 'inverse' or 'both' (one pipeline, `DIR` input). CT: the
    inverse runs the CT flow with the inverse cyclic twiddles, then each output
    lane is multiplied by n^-1, times psi^-k for negacyclic: the output twist,
    supplied the same way as the twiddles.

    GS (`butterflyType='GS'`: X = A + B, Y = (A - B) W) is the transpose of CT: the
    CT plan run backwards (stage s pairs bit L-1-s), so it takes its input where CT
    leaves its output (natural memory order, lane-major stream) and leaves its
    output where CT takes its input (bit-reversed memory order, lane m mod P): a CT
    forward feeds a GS inverse with no reorder and gets its own input order back.
    The twiddle of a pair on bit b is w^(j n/2^(b+1)), j = m mod 2^b, for both; CT
    forward and GS inverse merge the negacyclic twist (psi^((2j+1) n/2^(b+1)), psi^-1
    for the inverse). GS's other twist sits on the input (`twistSide`): forward
    psi^k when negacyclic, inverse n^-1 unless `inverseScale='stage'` (which GS
    allows negacyclic: the inverse then has no multiplier outside the butterflies).
    `leadIn()` delays the input when a counter-addressed table (GS stage 0, the
    input twist) would otherwise be read during reset.

    Per-polynomial modulus (`moduli=[q0, q1, ...]`, a parallel mode; without it
    nothing changes): the design holds a modulus table (each q's reduction
    constants, e.g. Barrett Q and MU) and every frame brings its own index
    (`MIDX`, sampled on the frame's first cycle), which travels with the frame in
    frame-boundary registers; each stage (and generator, twist) reads its
    constants from its own copy of the table, so consecutive frames may use
    different moduli with no gap. The butterflies and multipliers are built with
    `staticModulus=False` (their modulus inputs are delay-balanced with the data
    inside the datapath), over `ModulusFamily.table(moduli)`. Twiddles: 'otf'
    (default) or 'rom', every table holding each modulus's entries, indexed by
    {MIDX, DIR, cycle bits}; `otfMinBits=k` gives a class with fewer than k
    significant cycle bits a direct table instead of a generator (any mode). The
    data enters `frameLead()` cycles of delay first, so that table reads ahead of
    the first stage already know the frame's modulus.
    Per-frame moduli are built for CT butterflies only (GS with `moduli` is refused).
    '''

    _BOUND_ATTRS = ()
    _VALUE_ATTRS = ()

    def __init__(self, name: str, n: int, lanes: int, q: int = 0, family=None, butterflyType: str = 'CT',
                 negacyclic: bool = False, direction: str = 'forward', scaleInverse: bool = False,
                 butterfly: dict | None = None, twiddleSource: str | None = None,
                 targetFmaxMhz: float | None = None, primitiveRoot: int | None = None,
                 inputRegister: bool = False, inverseScale: str = 'output', moduli=None,
                 otfMinBits: int = 0, twistSource: str = 'tab', unified: bool = False,
                 outputOrder: str = 'stream', outReady: bool = False, outDepth: int | None = None,
                 loadableModuli: bool = False, loadLanes: int = 1, slotManager: bool = False,
                 loadByDirection: bool = False):
        super().__init__(name)
        # outReady=True (2026-11-14): a wrapper around the core with in_valid/in_ready (one handshake per
        # polynomial slot) and out_valid/out_ready (per beat): an output buffer of `outDepth` polynomials and a
        # credit count, so the feed-forward core never has to stop (see readyDepth, readyRun).
        self.outReady = bool(outReady)
        self.outDepth = outDepth
        if self.outReady and lanes >= n:
            raise ValueError(f'{name}: outReady needs a frame of at least 2 cycles (lanes < n)')
        if outDepth is not None and (not self.outReady or outDepth < 1):
            raise ValueError(f'{name}: outDepth (>= 1 polynomials) goes with outReady=True')
        # outputOrder='natural' (2026-11-14): a reorder stage behind the last stage puts coefficient
        # c*lanes + l on lane l in cycle c of the frame (see reorderPlan). 'stream' (default): no stage,
        # the output leaves where outputLocation says.
        if outputOrder not in ('stream', 'natural'):
            raise ValueError(f"{name}: outputOrder is 'stream' or 'natural'")
        self.outOrder = outputOrder
        # moduli=[...]: one modulus per polynomial, from a table in the design (see the class notes)
        self.moduli = list(moduli) if moduli is not None else None
        self.perFrame = self.moduli is not None
        # loadableModuli (2026-11-15): run-time moduli with a change per polynomial.
        #  * The modulus constants of a polynomial come with it (ports mq_<constant>, sampled with MIDX on its
        #    first cycle) and travel in the tag registers beside the data: no table, no slot, no rule for them.
        #  * Every twiddle table (stored, on-the-fly generator tables, recurrence seeds, output twist) is a RAM
        #    with one block per slot. MIDX names the slot of each frame. A slot is filled through the load port
        #    (tw_rst with tw_slot, then one word per tw_wen), in the order of the stages, so the load follows the
        #    data: it may start right behind the last polynomial of the slot and the next polynomial of the slot
        #    may enter before the load has reached the late stages (slotTiming, slotPlan).
        # `moduli` are stand-ins: they size the tables (one slot each) and feed the testbench.
        self.loadMod = bool(loadableModuli)
        # loadLanes: words the load port takes per cycle. The tables are split over that many lanes, each lane
        # filled table after table in the order of the stages, so a load takes about 1 / loadLanes of the cycles.
        self.loadLanes = int(loadLanes)
        if self.loadLanes < 1 or (self.loadLanes > 1 and not self.loadMod):
            raise ValueError(f'{name}: loadLanes >= 1, and more than one only with loadableModuli')
        # slotManager: the slots rotate. The outside announces the modulus of each coming polynomial; a manager in
        # the design reuses the slot that holds it, or loads the free slot unused the longest, and flags a broken
        # timing (versal_arith/rtl_gen/slot_manager.py). Without it the outside names the slots and loads them
        # itself: every modulus of the workload is loaded once and stays.
        self.slotMgr = bool(slotManager)
        # loadByDirection (both directions in one design): a load fills the tables of one direction of one modulus
        # (`tw_dir` with tw_rst), half the words. A slot then belongs to a modulus and a direction.
        self.loadDir = bool(loadByDirection) and direction == 'both'
        if loadByDirection and not self.loadMod:
            raise ValueError(f'{name}: loadByDirection goes with loadableModuli')
        if self.slotMgr and (not self.loadMod or self.outReady):
            raise ValueError(f'{name}: slotManager goes with loadableModuli and without outReady')
        if self.loadMod:
            if not self.perFrame:
                raise ValueError(f'{name}: loadableModuli goes with moduli=[...] (one stand-in per slot)')
        # unified=True (dataflow, P < n too): every multiplying butterfly is the unified CT/GS unit
        # (UnifiedButterfly.py). The forward runs CT (psi merged when negacyclic); the inverse runs GS on the
        # same stage order and wiring (stream position m holds GS memory index brv(m): hardware stage s pairs
        # memory bit L-1-s), psi^-1 merged, x2^-1 per stage. So a negacyclic design for both directions has no
        # twist multipliers and both directions take bit-reversed input and give natural output. The
        # direction comes per polynomial in the frame tag ({MIDX, DIR}), so it needs moduli= (one q: [q]).
        self._uni = bool(unified)
        if self._uni:
            if direction != 'both' or butterflyType != 'CT' or moduli is None or inverseScale != 'stage':
                raise ValueError(f"{name}: unified=True is for direction='both', CT, moduli=[...] (one q: [q]) "
                                 f"and inverseScale='stage'")
            if twiddleSource == 'rec':
                raise NotImplementedError(f"{name}: unified=True takes 'otf', 'rom' or 'stream' twiddles (the "
                                          f"GS direction's exponents are not c + g0*(t mod 2^k))")
        if self.perFrame:
            from ...modmult.ModulusFamily import ModulusFamily as _MF
            if q:
                raise ValueError(f'{name}: moduli= replaces q=')
            # Gentleman-Sande butterflies take a modulus per polynomial too (2026-11-16): gate 6 rows pfgs* (tables
            # of every modulus on the chip), lmgs64_* (loadable slots) and mggs128_* (slot manager)
            if len(set(self.moduli)) != len(self.moduli) or len(self.moduli) < 1:
                raise ValueError(f'{name}: moduli must be distinct')
            if twiddleSource == 'ram':
                raise ValueError(f"{name}: per-frame moduli take 'otf', 'rec', 'rom' or 'stream' twiddles "
                                 f"(tables hold every q)")
            # family= with moduli=: the datapath is built over that run-time family (e.g. friendly primes
            # for word-level Montgomery, which has no table form); every modulus must belong to it.
            # Without family=: ModulusFamily.table(moduli) (Barrett, Montgomery)
            if family is not None:
                if not family.runtime or any(not family.contains(m) for m in self.moduli):
                    raise ValueError(f'{name}: every modulus must belong to the run-time family {family.describe()}')
            elif self.loadMod:
                # run-time moduli: the datapath takes any odd modulus of the stand-ins' width (one width: a
                # family over a range of widths needs family=, and its bound analysis is slow)
                bits = {m.bit_length() for m in self.moduli}
                if len(bits) != 1:
                    raise ValueError(f'{name}: loadableModuli without family= needs stand-ins of one width, got '
                                     f'{sorted(bits)} bits')
                family = _MF.odd(bits.pop())
            else:
                family = _MF.table(self.moduli)
            twiddleSource = twiddleSource or 'otf'
        self.otfMinBits = int(otfMinBits)
        # twistSource: how the output twist (negacyclic inverse: n^-1 psi^-k per lane) gets its factors. 'tab' a
        # table of F words per lane (and per modulus: too large at n = 2^17 with many moduli); 'otf' (per-frame
        # moduli only) two tables of ~sqrt(F) per lane and one generator multiplier per lane, like the twiddles
        if twistSource not in ('tab', 'otf'):
            raise ValueError(f"{name}: twistSource 'tab' or 'otf'")
        if twistSource == 'otf' and moduli is None:
            raise NotImplementedError(f"{name}: twistSource='otf' is built for per-frame moduli only")
        self.twistSource = twistSource
        L = n.bit_length() - 1
        if n != 1 << L or n < 4:
            raise ValueError(f'{name}: n must be a power of two >= 4')
        # inputRegister: one register in front of every butterfly (operands and twiddle), so the
        # delay-line and table memories end in a register, not in the first DSP58 (+1 cycle per stage)
        self.inputRegister = 1 if inputRegister else 0
        # inverseScale: where the inverse's n^-1 goes. 'output': one modular multiplier per output lane
        # (merged with psi^-k when negacyclic). 'stage': x2^-1 after every butterfly in inverse mode,
        # h = (x >> 1) + x[0]*(q+1)/2 (one adder, +1 cycle per stage, no multiplier); cyclic only,
        # since a negacyclic CT inverse needs the psi^-k output multipliers anyway
        if inverseScale not in ('output', 'stage'):
            raise ValueError(f"{name}: inverseScale must be 'output' or 'stage'")
        if inverseScale == 'stage' and (direction == 'forward' or (negacyclic and butterflyType == 'CT'
                                                                   and not self._uni)):
            raise ValueError(f"{name}: inverseScale='stage' needs an inverse, and with CT a cyclic transform "
                             f"(a negacyclic CT inverse still needs the psi^-k output multipliers; GS merges psi^-1)")
        self.inverseScale = inverseScale
        self.stageHalve = 1 if inverseScale == 'stage' else 0
        lp = lanes.bit_length() - 1
        if lanes != 1 << lp or not 2 <= lanes <= n:
            raise ValueError(f'{name}: lanes must be a power of two in [2, n]')
        if butterflyType not in ('CT', 'GS'):
            raise ValueError(f'{name}: butterflyType must be CT or GS')
        if direction not in ('forward', 'inverse', 'both'):
            raise ValueError(f"{name}: direction must be 'forward', 'inverse' or 'both'")
        self.runtime = family is not None and family.runtime
        if (q >= 3) == self.runtime:
            raise ValueError(f'{name}: give a fixed q or a run-time family=, one of them')
        self.family = family if self.runtime else None
        self.q = q if not self.runtime else 0
        src = twiddleSource or ('ram' if self.runtime else 'rom')
        if src not in ('rom', 'ram', 'otf', 'rec', 'stream') or (src == 'rom' and self.runtime and not self.perFrame) \
                or (src == 'stream' and not self.perFrame):
            raise ValueError(f"{name}: twiddleSource 'rom' (fixed q), 'ram', 'otf', 'rec' or 'stream' (per-frame moduli)")
        self.n, self.L, self.lanes, self.lp = n, L, lanes, lp
        self.F, self.fb = n // lanes, L - lp
        self.butterflyType = butterflyType
        self.negacyclic = negacyclic
        self.direction = direction
        self.scaleInverse = scaleInverse or (negacyclic and direction != 'forward')
        # the twist multipliers sit behind the last stage for CT (inverse: n^-1 psi^-k) and in front of
        # the first stage for GS (forward: psi^k when negacyclic; inverse: n^-1 unless scaled per stage)
        self.twistSide = 'output' if butterflyType == 'CT' else 'input'
        self.butterflyArgs = dict(butterfly or {})
        self.twiddleSource = src
        self.targetFmaxMhz = targetFmaxMhz
        self.primitiveRoot = primitiveRoot
        self.dirs = (['fwd'] if direction in ('forward', 'both') else []) + \
                    (['inv'] if direction in ('inverse', 'both') else [])
        self._plan()
        self._slots()
        self._qCache = {}
        if self.perFrame:
            bad = [q for q in self.moduli if (q - 1) % self.rootOrder()]
            if bad:
                raise ValueError(f'{name}: {self.rootOrder()} does not divide q - 1 for {bad[:3]}')

    # --- roots and exponents --------------------------------------------------------

    def qMax(self) -> int:
        return self.family.qMax if self.runtime else self.q

    def rootOrder(self) -> int:
        '''What q - 1 must be a multiple of: 2n negacyclic (psi), n cyclic (w).'''
        return 2 * self.n if self.negacyclic else self.n

    def refQ(self) -> int:
        '''A modulus to build with: the fixed q, or a prime of the family with rootOrder() | q - 1.'''
        if not self.runtime:
            return self.q
        if self.perFrame:
            return self.moduli[0]
        if not hasattr(self, '_refQ'):
            import random as _r
            rng = _r.Random(7)
            c = self.family.samplePrimeCongruent(rng, self.rootOrder())
            if c is None:
                raise ValueError(f'{self.name}: no prime of {self.family.describe()} with {self.rootOrder()} | q-1 found')
            self._refQ = c
        return self._refQ

    def base(self, d: str, q: int) -> int:
        '''The root a direction's exponents are powers of, for modulus q.'''
        key = ('base', d, q)
        if key not in self._qCache:
            from sage.all import GF
            F = GF(q)
            if self.primitiveRoot is not None and q == self.q:
                psi = F(self.primitiveRoot)
                w = psi * psi if self.negacyclic else psi
            else:
                # one fixed root per q, independent of earlier Sage calls (F.zeta(m) switches algorithm once the
                # field's multiplicative generator is cached, so its answer depended on the call history):
                # negacyclic psi = fixedRoot(2n), w = psi^2; cyclic w = fixedRoot(n) (cyclic needs only n | q - 1)
                psi = fixedRoot(F, 2 * self.n) if self.negacyclic else None
                w = psi * psi if self.negacyclic else fixedRoot(F, self.n)
            if d == 'fwd':
                b = psi if self.mergedTwist(d) else w
            elif d == 'inv':
                b = psi ** -1 if self.mergedTwist(d) else w ** -1   # CT: the cyclic inverse, twist after
            elif self.butterflyType == 'CT':    # 'twist': psi^-1 (negacyclic) or 1, on the output (inverse)
                b = psi ** -1 if self.negacyclic else F(1)
            else:                               # GS: psi (negacyclic) or 1, on the input (forward)
                b = psi if self.negacyclic else F(1)
            self._qCache[key] = int(b)
        return self._qCache[key]

    def mergedTwist(self, d: str) -> bool:
        '''Whether direction d's twiddles carry psi^(+-1) (negacyclic): CT forward and GS inverse.'''
        if getattr(self, '_uni', False):
            return self.negacyclic                # unified: CT forward merges psi, GS inverse psi^-1
        return self.negacyclic and ((self.butterflyType == 'CT') == (d == 'fwd'))

    def order(self, d: str) -> int:
        return 2 * self.n if (d in ('fwd', 'inv') and self.mergedTwist(d)) or (d == 'twist' and self.negacyclic) \
            else self.n

    def value(self, d: str, e: int, q: int) -> int:
        return pow(self.base(d, q), e % self.order(d), q)

    def stageBit(self, s: int) -> int:
        return s if self.butterflyType == 'CT' else self.L - 1 - s

    def _exponent(self, d: str, s: int, mA: int) -> int:
        '''The exponent of stage s's twiddle for the pair starting at memory index mA.'''
        # stage bit b pairs m and m + 2^b; the twiddle is w^(j n/2^(b+1)), j = m mod 2^b, the same for
        # CT (bit-reversed in, natural out, bits 0..L-1) and GS (its transpose: natural in, bit-reversed
        # out, bits L-1..0); with the twist merged (CT forward, GS inverse) psi^((2j+1) n/2^(b+1))
        b = self.stageBit(s)
        if getattr(self, '_uni', False) and d == 'inv':
            # unified: GS on the CT stream. Position mA holds GS memory index brv(mA); stage s pairs bit L-1-s
            mA = bitReverse(mA, self.L)
            b = self.L - 1 - s
        stepExp = self.n >> (b + 1)
        j = mA % (1 << b)
        if self.mergedTwist(d):
            return (2 * j + 1) * stepExp
        return j * stepExp

    # --- the order plan ----------------------------------------------------------

    def _plan(self) -> None:
        lp, fb, L = self.lp, self.fb, self.L
        lane = list(range(lp))
        cyc = [lp + j for j in range(fb)]
        self.inLane, self.inCyc = list(lane), list(cyc)
        used = []
        self.stagePlan = []
        for s in range(L):
            b = s                               # the CT plan; GS runs it backwards (below)
            ex = None
            if b not in lane:
                j = cyc.index(b)
                remaining = set(range(s, L))
                cand = [i for i in range(lp) if lane[i] not in remaining]
                if not cand:
                    raise AssertionError(f'{self.name}: no free lane bit at stage {s}')
                i = min(cand, key=lambda i: used.index(lane[i]) if lane[i] in used else -1)
                lane[i], cyc[j] = cyc[j], lane[i]
                ex = (i, j, 1 << j)
            pair = lane.index(b)
            self.stagePlan.append({'stage': s, 'bit': b, 'exchange': ex, 'pairLaneBit': pair,
                                   'lane': list(lane), 'cyc': list(cyc)})
            used.append(b)
        self.outLane, self.outCyc = list(lane), list(cyc)
        if self.butterflyType == 'GS':
            # GS is the transpose of CT: the same stages in reverse order. Stage s pairs bit L-1-s in CT
            # stage L-1-s's layout; reaching it from GS stage s-1 (CT stage L-s) undoes CT stage L-s's
            # exchange, which is the same swap (lane bit i <-> cycle bit j, D = 2^j). So GS takes its input
            # where CT leaves its output and leaves its output where CT takes its input.
            ct = self.stagePlan
            self.stagePlan = []
            for s in range(L):
                c = ct[L - 1 - s]
                ex = ct[L - s]['exchange'] if s else None
                self.stagePlan.append({'stage': s, 'bit': L - 1 - s, 'exchange': ex,
                                       'pairLaneBit': c['pairLaneBit'], 'lane': c['lane'], 'cyc': c['cyc']})
            self.inLane, self.inCyc, self.outLane, self.outCyc = self.outLane, self.outCyc, self.inLane, self.inCyc

    @staticmethod
    def _place(m: int, lane: list, cyc: list) -> tuple[int, int]:
        l = sum(((m >> b) & 1) << i for i, b in enumerate(lane))
        t = sum(((m >> b) & 1) << j for j, b in enumerate(cyc))
        return t, l

    @staticmethod
    def _index(t: int, l: int, lane: list, cyc: list) -> int:
        m = 0
        for i, b in enumerate(lane):
            m |= ((l >> i) & 1) << b
        for j, b in enumerate(cyc):
            m |= ((t >> j) & 1) << b
        return m

    def inputLocation(self, m: int) -> tuple[int, int]:
        '''(cycle, lane) where memory index m enters: CT lane m mod P, cycle m // P; GS where
        CT of the same n, P puts its output (lane-major), so a CT forward feeds a GS inverse.'''
        return self._place(m, self.inLane, self.inCyc)

    def outputLocation(self, m: int) -> tuple[int, int]:
        return self._place(m, self.outLane, self.outCyc)

    # --- natural-order output (outputOrder='natural') --------------------------------

    def naturalIndex(self, m: int) -> int:
        '''Coefficient index held by memory index m of the output (CT: m, GS: bit-reversed m).'''
        return m if self.butterflyType == 'CT' else bitReverse(m, self.L)

    def portLocation(self, m: int) -> tuple[int, int]:
        '''(cycle, lane) where memory index m leaves the core: `outputLocation`, or with
        outputOrder='natural' cycle k // lanes, lane k mod lanes for its coefficient index k.'''
        if getattr(self, 'outOrder', 'stream') != 'natural':
            return self.outputLocation(m)
        k = self.naturalIndex(m)
        return k >> self.lp, k & (self.lanes - 1)

    def reorderPlan(self) -> dict | None:
        '''The output reorder stage of outputOrder='natural', or None.

        The stream position (cycle t, lane l) -> natural position (t', l') map is a permutation of the
        index bits. Lane bits that become cycle bits (A) are paired with cycle bits that become lane bits
        (B). One RAM bank per lane, 2F words (two frames, ping-pong): the data of (t, l) goes to bank p,
        p[a] = l[a] xor t[b] for a pair (a, b), p[i] = l[i] otherwise, at address {parity, t}. Each cycle
        writes every bank once, and the lanes of one output cycle sit in different banks. A frame is read
        while the next is written, on the same counter: bank p is read at the address with t[c] = t'[d(c)]
        for a cycle bit that stays a cycle bit and t[b] = p[a] xor t'[d(a)] for a pair; the word of bank p
        leaves on lane l' with l'[d(i)] = p[i] (lane bit that stays) and l'[d(b)] = p[a] xor t'[d(a)].
        Both sides are log2-many layers of two-input swaps. Latency F + 3 (swap register, RAM write,
        RAM read register, output register). No cycle bit involved: wiring only, latency 0.'''
        if getattr(self, 'outOrder', 'stream') != 'natural':
            return None
        lp, fb = self.lp, self.fb

        def dest(b):
            k = b if self.butterflyType == 'CT' else self.L - 1 - b
            return ('L', k) if k < lp else ('T', k - lp)
        laneTo, cycTo = [dest(b) for b in self.outLane], [dest(b) for b in self.outCyc]
        A = [i for i in range(lp) if laneTo[i][0] == 'T']
        B = [j for j in range(fb) if cycTo[j][0] == 'L']
        pairs = [(a, b, laneTo[a][1], cycTo[b][1]) for a, b in zip(A, B)]
        stayLane = [(i, laneTo[i][1]) for i in range(lp) if i not in A]
        stayCyc = [(j, cycTo[j][1]) for j in range(fb) if j not in B]
        ram = bool(pairs) or any(j != d for j, d in stayCyc)
        if not ram and all(i == d for i, d in stayLane):
            return None                                  # the stream order is the natural order already
        return {'pairs': pairs, 'stayLane': stayLane, 'stayCyc': stayCyc, 'ram': ram,
                'latency': self.F + 3 if ram else 0, 'words': 2 * self.F if ram else 0}

    def reorderLatency(self) -> int:
        p = self.reorderPlan()
        return p['latency'] if p else 0

    # ---- outReady: the wrapper with output backpressure ----
    READY_OUT_STAGES = 3          # buffer write, registered buffer read, output register

    def readyMinDepth(self, pipelineStages=1) -> int:
        '''Fewest buffered polynomials that keep one polynomial per frame slot with out_ready high: the credit
        of a polynomial comes back one cycle after its last beat leaves (slot start + latency + 3 + F), and
        the grant for a slot is taken on the cycle before it.'''
        return -(-(self.latency(pipelineStages) + self.READY_OUT_STAGES + 1) // self.F) + 1

    def readyDepth(self, pipelineStages=1) -> int:
        return self.outDepth if self.outDepth is not None else self.readyMinDepth(pipelineStages)

    def readyLatency(self, pipelineStages=1) -> int:
        '''First input beat (accepted) to first output beat with out_ready high.'''
        return self.latency(pipelineStages) + self.READY_OUT_STAGES

    def readyInterval(self, pipelineStages=1) -> int:
        '''Cycles per polynomial with in_valid and out_ready held high: F when the buffer holds readyMinDepth
        polynomials or more; with fewer, the credit comes back too late and slots are skipped.'''
        D, F = self.readyDepth(pipelineStages), self.F
        if D >= self.readyMinDepth(pipelineStages):
            return F
        st = self.readyRun([[0] * self.lanes] * (F * (4 * D + 8)), [1] * (F * (8 * D + 24) * 2),
                           [1] * (F * (8 * D + 24) * 2), pipelineStages)
        acc = [c for c, a in enumerate(st['accept']) if a]
        return acc[-1] - acc[-2]

    def readyPlan(self, pipelineStages=1) -> dict:
        '''Constants of the wrapper: depth (polynomials), address bits of the buffer, credit bits, and the tap
        of the accepted-slot shift register (`tap`) with the frame cycle (`at`) on which the write enable of
        the next output frame is loaded.'''
        LAT, F, D = self.latency(pipelineStages), self.F, self.readyDepth(pipelineStages)
        assert LAT >= 2 and F >= 2
        J = (LAT - 2) // F
        sft = LAT - 1 - J * F                 # 1..F
        return {'depth': D, 'addrBits': max(1, (D * F - 1).bit_length()), 'creditBits': D.bit_length(), 'tap': J,
                'at': sft % F, 'latency': LAT, 'outLatency': LAT + self.READY_OUT_STAGES, 'frame': F}

    def readyRun(self, beats: list, inValid: list[int], outReady: list[int], pipelineStages=1,
                 polys: int | None = None) -> dict:
        '''Cycle-exact twin of the wrapper. Cycle 0 is the first cycle after reset; slot k is cycles kF ..
        kF+F-1. `inValid[c]`, `outReady[c]`: the two inputs per cycle. `beats`: the core's output beats of the
        accepted polynomials in order (F per polynomial, port order). Returns per cycle: 'inReady',
        'outValid', 'out' (the beat, None when not valid), 'accept' (a polynomial enters: slot starts here),
        'inValid' (the in_valid really driven: low once the source has sent `polys` polynomials).
        A polynomial enters on the first cycle of a slot when in_valid and in_ready; the source then sends
        its F beats in the F cycles of that slot.'''
        pl = self.readyPlan(pipelineStages)
        F, D, LAT, J, AT = self.F, pl['depth'], pl['latency'], pl['tap'], pl['at']
        N = len(inValid)
        core = {}                              # cycle -> beat on the core's output
        nacc = 0
        inReady, infl, vsh, vy = 1, 0, [0] * (J + 1), 0
        fifo, r_v, r_d, o_v, o_d, rcnt = [], 0, None, 0, None, 0
        res = {'inReady': [], 'outValid': [], 'out': [], 'accept': [], 'inValid': []}
        src = 1
        for c in range(N):
            cnt = c % F
            iv, ordy = inValid[c], outReady[c]
            if polys is not None and nacc >= polys and cnt == 0:
                src = 0                        # the source has no polynomial left
            if not src:
                iv = 0
            acc = int(bool(iv) and inReady and cnt == 0)
            res['inValid'].append(int(bool(iv)))
            res['inReady'].append(inReady); res['outValid'].append(o_v)
            res['out'].append(o_d if o_v else None); res['accept'].append(acc)
            if acc:
                if (nacc + 1) * F <= len(beats):
                    for t in range(F):
                        core[c + LAT + t] = beats[nacc * F + t]
                nacc += 1
            pop = o_v and ordy
            dec = int(pop and rcnt == F - 1)
            o_load = r_v and ((not o_v) or ordy)
            r_en = bool(fifo) and ((not r_v) or o_load)
            # next state
            n_o_v, n_o_d = (1, r_d) if o_load else ((0, o_d) if ordy else (o_v, o_d))
            if r_en:
                n_r_v, n_r_d = 1, fifo[0]
            else:
                n_r_v, n_r_d = (0 if o_load else r_v), r_d
            if vy:
                assert c in core, f'{self.name}: write enable on a cycle without an accepted beat ({c})'
            else:
                assert c not in core, f'{self.name}: an accepted beat is not written ({c})'
            n_fifo = fifo[1:] if r_en else fifo
            if vy:
                n_fifo = n_fifo + [core[c]]
            assert len(n_fifo) < D * F, f'{self.name}: output buffer overflow'   # RAM holds at most D*F - 1
            n_vy = vsh[J] if cnt == AT else vy
            n_vsh = [acc] + vsh[:-1] if cnt == 0 else vsh
            if cnt == F - 1:
                n_ir = int(infl < D)
            elif cnt == 0:
                n_ir = acc
            else:
                n_ir = inReady
            infl = infl + acc - dec
            rcnt = (rcnt + 1) % F if pop else rcnt
            inReady, vsh, vy, fifo, r_v, r_d, o_v, o_d = n_ir, n_vsh, n_vy, n_fifo, n_r_v, n_r_d, n_o_v, n_o_d
        res['accepted'] = nacc
        return res

    def reorderStream(self, cycles: list[list]) -> list[list]:
        '''Cycle-exact twin of the reorder stage: `cycles[c][l]` is the stream-order output of cycle c
        (frame cycle c mod F); returns the port values per cycle, `reorderLatency()` more cycles than
        given (None before the first frame arrives).'''
        ro = self.reorderPlan()
        if ro is None:
            return [list(c) for c in cycles]
        P, F, lp = self.lanes, self.F, self.lp
        if not ro['ram']:
            out = []
            for c in cycles:
                y = [None] * P
                for l in range(P):
                    y[sum(((l >> i) & 1) << d for i, d in ro['stayLane'])] = c[l]
                out.append(y)
            return out
        mem = [[None] * (2 * F) for _ in range(P)]
        par, w, wt, rd, rt, yreg, out = 0, None, None, None, None, None, []
        for c, row in enumerate(list(cycles) + [[None] * P] * ro['latency']):
            t = c % F
            out.append(yreg)                            # the output register, as seen in this cycle
            y = None
            if rd is not None:
                y = [None] * P
                for p in range(P):
                    l2 = sum(((p >> i) & 1) << d for i, d in ro['stayLane'])
                    for a, b, da, db in ro['pairs']:
                        l2 |= (((p >> a) & 1) ^ ((rt >> da) & 1)) << db
                    y[l2] = rd[p]
            nrd = nrt = None
            if wt is not None:
                nrd = []
                for p in range(P):
                    ta = sum(((wt >> d) & 1) << j for j, d in ro['stayCyc'])
                    for a, b, da, db in ro['pairs']:
                        ta |= (((p >> a) & 1) ^ ((wt >> da) & 1)) << b
                    nrd.append(mem[p][(1 - par) * F + ta])
                nrt = wt
                for p in range(P):
                    mem[p][par * F + wt] = w[p]
            nw = [None] * P
            for l in range(P):
                p = l
                for a, b, da, db in ro['pairs']:
                    p ^= ((t >> b) & 1) << a
                nw[p] = row[l]
            if t == 0 and c:
                par ^= 1
            w, wt, rd, rt, yreg = nw, t, nrd, nrt, y
        return out

    def exchangeWords(self) -> int:
        return sum(self.lanes * p['exchange'][2] for p in self.stagePlan if p['exchange'])

    # --- sequences: butterfly slots and the output twist ----------------------------

    def _slots(self) -> None:
        P, F = self.lanes, self.F
        self.slots = []                              # per stage: [(laneA, laneB, {dir: [exponent per cycle]})]
        for p in self.stagePlan:
            s, bit = p['stage'], p['pairLaneBit']
            stage = []
            for la in range(P):
                if (la >> bit) & 1:
                    continue
                lb = la | (1 << bit)
                seqs = {d: [self._exponent(d, s, self._index(t, la, p['lane'], p['cyc'])) % self.order(d)
                            for t in range(F)] for d in self.dirs}
                stage.append((la, lb, seqs))
            self.slots.append(stage)
        # the output twist per lane: exponent of psi^-1 (or 0) of the natural index there
        self.twistSeqs = None
        if self.twistSide == 'output':
            need = self.scaleInverse and not self.stageHalve
        else:
            need = (self.negacyclic and 'fwd' in self.dirs) or ('inv' in self.dirs and self.scaleInverse
                                                                 and not self.stageHalve)
        if need:
            loc = self.outputLocation if self.twistSide == 'output' else self.inputLocation
            per = [[0] * F for _ in range(P)]
            for m in range(self.n):
                t, l = loc(m)
                per[l][t] = m % self.order('twist') if self.negacyclic else 0
            self.twistSeqs = per

    def slotConstant(self, s: int, k: int):
        '''(exponents per direction) if the slot's twiddle never changes and can be
        a design-time constant (fixed q: any; run-time q: only the twiddle 1), else None.'''
        seqs = self.slots[s][k][2]
        ex = {d: set(v) for d, v in seqs.items()}
        if any(len(v) != 1 for v in ex.values()):
            return None
        vals = {self.value(d, next(iter(v)), self.refQ()) for d, v in ex.items()}
        if len(vals) != 1:
            return None
        if self.runtime and vals != {1}:
            return None
        return vals.pop() if not self.runtime else 1

    def slotClasses(self) -> dict:
        '''Distinct twiddle sequences among the non-constant slots: {key: (s, k) of
        its first slot}; `classOf[(s, k)]` maps every slot to its key.'''
        memo = self.__dict__.get('_classesMemo')
        if memo is not None and memo[0] is self.slots:      # the slots are built once; asked hundreds of times
            self.classOf = memo[1]
            return memo[2]
        classes = self._slotClassesNow()
        self.__dict__['_classesMemo'] = (self.slots, self.classOf, classes)
        return classes

    def _slotClassesNow(self) -> dict:
        self.classOf, classes = {}, {}
        for s, stage in enumerate(self.slots):
            for k, (_, _, seqs) in enumerate(stage):
                if self.slotConstant(s, k) is not None:
                    continue
                key = tuple((d, tuple(seqs[d])) for d in self.dirs)
                classes.setdefault(key, (s, k))
                self.classOf[(s, k)] = key
        return classes

    # --- stored values ----------------------------------------------------------------

    def _probe(self, q: int):
        from ..butterfly.ButterflyScheme import ModularBU
        key = ('probe', q)
        if key not in self._qCache:
            fam = dict(family=self.family) if self.runtime else dict(q=self.q)
            # the butterflies' own type: GS multiplies A - B (Shoup: lifted to [0, 2q)), whose range sets
            # Shoup's companion width
            probe = ModularBU(name='probe', butterflyType=self.butterflyType, twiddleInput=True, **fam,
                              **self._buArgs())
            probe.aIn = probe.bIn = IntType(0, self.qMax() - 1)
            self._qCache[key] = probe
        return self._qCache[key]

    def storedFactor(self, q: int | None = None) -> int:
        '''Stored twiddles are w times this: the inverse of the butterfly
        multiplier's factor (R for the Montgomery family, 1 for Barrett / Shoup).'''
        q = q or self.refQ()
        key = ('sf', q)
        if key not in self._qCache:
            self._qCache[key] = pow(self._probe(q).inner().factor(q if self.runtime else None), -1, q)
        return self._qCache[key]

    def stored(self, w: int, q: int | None = None) -> int:
        q = q or self.refQ()
        return w * self.storedFactor(q) % q

    def companion(self, w: int, q: int) -> int:
        return self._probe(q).companion(w, q)

    def shoup(self) -> bool:
        return self.butterflyArgs.get('multiplierKind') == 'shoup'

    # --- butterflies, generators, twist ------------------------------------------------

    def _buArgs(self) -> dict:
        a = dict(self.butterflyArgs)
        if self.perFrame:
            a['staticModulus'] = False          # the frame's q is delay-balanced with its data
            a.setdefault('inRange', 1)
        elif self.runtime:
            a.setdefault('staticModulus', True)
            a.setdefault('inRange', 1)
        return a

    def _bu(self, s: int, k: int, bound: IntType):
        from ..butterfly.ButterflyScheme import ModularBU
        c = self.slotConstant(s, k)
        fam = dict(family=self.family) if self.runtime else dict(q=self.q)
        uni = getattr(self, '_uni', False) and c is None
        if SHARE_IDENTICAL_BU:
            plan = self._dspPlan.get(('bu', self._buType(None if uni else c, bound))) if self._dspPlan else None
            skey = (uni, self._buType(c, bound), repr(plan), repr(sorted(self._buArgs().items(), key=str)))
            if SHARE_IDENTICAL_BU == 'global':
                skey += (self.butterflyType, self.runtime, repr(self.family) if self.runtime else self.q, self.targetFmaxMhz)
                share = _BU_GLOBAL
            else:
                share = self.__dict__.setdefault('_buShare', {})
            if skey in share:
                return share[skey]
        if getattr(self, '_uni', False) and c is None:
            from ..butterfly.UnifiedButterfly import UnifiedBU
            bu = UnifiedBU(name=f'{self.name}_s{s}_k{k}', butterflyType='CT', twiddleInput=True,
                           targetFmaxMhz=self.targetFmaxMhz, **fam, **self._buArgs())
            bu.aIn = bu.bIn = bound
            if self._dspPlan:
                bu.dspBudgets = self._dspPlan.get(('bu', self._buType(None, bound)))
            if SHARE_IDENTICAL_BU:
                share[skey] = _memoBu(bu)
            return bu
        bu = ModularBU(name=f'{self.name}_s{s}_k{k}', butterflyType=self.butterflyType,
                       twiddleInput=c is None, targetFmaxMhz=self.targetFmaxMhz, **fam, **self._buArgs())
        bu.aIn = bu.bIn = bound
        if c is not None:
            bu.twiddle = c
        if self._dspPlan:
            bu.dspBudgets = self._dspPlan.get(('bu', self._buType(c, bound)))
        if SHARE_IDENTICAL_BU:
            share[skey] = _memoBu(bu)
        return bu

    def _mulArgs(self) -> dict:
        '''A plain modular multiplier like the butterflies' (Shoup butterflies: Barrett).'''
        from ...modmult.ReductionScheme import BarrettReduction
        a = self.butterflyArgs
        shoup = self.shoup()
        args = dict(multiplier=a.get('multiplier', 'dsp'), reduction=BarrettReduction if shoup else
                    a.get('reduction', BarrettReduction), reductionArgs=None if shoup else a.get('reductionArgs'),
                    targetFmaxMhz=self.targetFmaxMhz)
        if a.get('qBackend'):
            args['qBackend'] = a['qBackend']
        if self.runtime:
            args.update(family=self.family, staticModulus=not self.perFrame, inRange=1)
        else:
            args['q'] = self.q
        return args

    def _multiplier(self, name: str, aIn: IntType, **over):
        from ...modmult.ModMultScheme import ModularMultiplierScheme
        args = dict(self._mulArgs())
        args.update(over)                # e.g. the iterative 'rec' generators on LUTs (recMultiplier)
        m = ModularMultiplierScheme(name=name, aIn=aIn, bIn=IntType(0, self.qMax() - 1),
                                    outputRange='exact', **args)
        if self.butterflyType == 'GS' and self.runtime and m.qPorts() and not self.shoup():
            # GS butterflies multiply the signed A - B; a run-time reduction constant that depends on the
            # operand range (Barrett's MU) would then differ from the butterflies' on the same port:
            # size the helper for that operand too
            qm = IntType(0, self.qMax() - 1)
            d = qm - qm
            wide = IntType(min(aIn.minValue, d.minValue), max(aIn.maxValue, d.maxValue))
            q0 = self.refQ()
            bv = self._probe(q0).qPortValues(q0)
            if any(bv.get(p, v) != v for p, v in m.qPortValues(q0).items()):
                m = ModularMultiplierScheme(name=name, aIn=wide, bIn=IntType(0, self.qMax() - 1),
                                            outputRange='exact', **args)
        if self._dspPlan:          # the output twist, or an on-the-fly generator
            m.dspBudgets = self._dspPlan.get('twist' if name.endswith('_twist') else 'gen')
        return m

    # --- a total DSP budget, split top-down (core/dspbudget.py) ---------------------

    #: the budget tree of the last `setDspBudget` (None: the builders' own budgets)
    dspTree = None
    _dspPlan = None

    @staticmethod
    def _buType(c, bound: IntType) -> tuple:
        '''Butterflies built from the same constant and input bound are identical.'''
        return (c, bound.minValue, bound.maxValue, bound.zeroLsbs)

    def setDspBudget(self, fraction: float | None = None, total: int | None = None, weight=None):
        '''Give the whole pipeline `fraction` of its pure-DSP count, or `total` DSPs,
        split top-down: {butterfly type x count, output twist x P, on-the-fly
        generators x classes} -> each block's multipliers (the product, each WLM
        step's m*QH, ...), in proportion to `weight` (`dspbudget.WEIGHTS`, default
        the pure-DSP count). Identical blocks get identical budgets. Returns the
        budget tree (`self.dspTree`) with the model's counts; `clearDspBudget()`
        restores the builders' own budgets. Needs the input bound set.'''
        from ...core import dspbudget as DB
        self.clearDspBudget()
        types: dict = {}
        for s, stage in enumerate(self.butterflies):
            for k, bu in enumerate(stage):
                types.setdefault(self._buType(self.slotConstant(s, k), bu.aIn), []).append(bu)
        blocks = []
        for i, (key, bus) in enumerate(types.items()):
            what = 'twiddle input' if key[0] is None else f'constant {key[0]}'
            b = DB.blockOf(f'butterfly type {i} ({what})', bus[0].inner(), len(bus), weight)
            b.key = ('bu', key)
            blocks.append(b)
        if self.twistMultiplier is not None:
            b = DB.blockOf(f'{self.twistSide} twist multiplier', self.twistMultiplier, self.lanes, weight)
            b.key = 'twist'
            blocks.append(b)
        if self.hasGenerators():
            g = self._multiplier('g', IntType(0, self.qMax() - 1))
            # the generators of a generated output twist (one per lane) are the same block and take from the budget
            b = DB.blockOf('on-the-fly twiddle generator', g,
                           self.generatorCount() + (self.lanes if self.twistOtf() else 0), weight)
            b.key = 'gen'
            blocks.append(b)
        pure = sum(b.count * b.pureDsp for b in blocks)
        root = DB.Budget(self.name, 1, pure, sum(b.count * b.weight for b in blocks), children=blocks)
        root.budget = DB.resolveTotal(pure, fraction, total)
        DB.splitTypes(root.budget, blocks)
        for b in blocks:
            DB.splitLeaves(b)
        self._dspPlan = {b.key: DB.budgetsOf(b) for b in blocks}
        self._clearGenerators()
        self.propagateBound()
        for b in blocks:
            if b.key == 'twist':
                inst = self.twistMultiplier
            elif b.key == 'gen':
                inst = self._multiplier('g', IntType(0, self.qMax() - 1))
            else:
                inst = next(bu for s, st in enumerate(self.butterflies) for k, bu in enumerate(st)
                            if self._buType(self.slotConstant(s, k), bu.aIn) == b.key[1]).inner()
            DB.measure(b, inst)
        root.lut, root.dsp = self.areaCost()
        self.dspTree = root
        return root

    def clearDspBudget(self) -> None:
        self._dspPlan = None
        self.dspTree = None
        self._clearGenerators()
        self.propagateBound()

    def setBramBudget(self, total: int | None = None, fraction: float | None = None, pipelineStages: int = 1) -> dict:
        '''Keep the block RAMs (BRAM36, model count of StreamArea) at or below `total`, or `fraction` of the
        count with every twiddle in a table. The only block RAMs that can move are the twiddle tables: the
        deepest classes go to on-the-fly generation first (`otfMinBits`: a class with that many significant
        cycle bits or more gets two small tables and one generator multiplier). The delay lines and the
        output reorder / output buffer cannot move; if they alone exceed the budget the result says so
        ('met': False) and every table that can go has gone. Needs twiddleSource 'rom' or 'otf' (the source
        becomes 'otf'), and the input bound set. Returns {'budget', 'allTables', 'bram36', 'otfMinBits',
        'generators', 'met', 'floor'}; also kept in `self.bramPlan`. Call it before setDspBudget (the
        generators take part in the DSP split).'''
        from . import StreamArea
        if self.twiddleSource not in ('rom', 'otf'):
            raise ValueError(f"{self.name}: setBramBudget needs twiddleSource 'rom' or 'otf' (on-the-fly generation "
                             f"is what replaces a table); this design has '{self.twiddleSource}'")
        if (total is None) == (fraction is None):
            raise ValueError(f'{self.name}: setBramBudget takes total= or fraction=')
        self.twiddleSource = 'otf'

        def count(k):
            self.otfMinBits = k
            self._clearGenerators()
            self.propagateBound()
            return StreamArea.totals(StreamArea.inventory(self, pipelineStages))['bram36']
        top = self.fb + 1                                  # no class has this many bits: every twiddle in a table
        allTab = count(top)
        budget = total if total is not None else int(fraction * allTab)
        pick, got = None, None
        for k in range(top, 0, -1):                        # most tables first
            got = count(k)
            if got <= budget:
                pick = k
                break
        met = pick is not None
        if not met:
            pick, got = 1, count(1)
        else:
            got = count(pick)
        self.bramPlan = {'budget': budget, 'allTables': allTab, 'bram36': got, 'otfMinBits': pick,
                         'generators': self.generatorCount(), 'met': met, 'floor': count(1)}
        count(pick)
        return self.bramPlan

    def _clearGenerators(self) -> None:
        for k in [k for k in self._qCache if isinstance(k, tuple) and k and k[0] == 'gen']:
            del self._qCache[k]

    def classSource(self, key) -> str:
        '''How a sequence class gets its twiddle: 'otf' (two tables and a generator) or 'tab' (one table:
        twiddleSource 'rom' / 'ram', or an 'otf' class with fewer than `otfMinBits` significant bits).'''
        if self.twiddleSource == 'stream':
            return 'stream'
        if self.twiddleSource == 'rec':
            return 'rec' if (1 << len(self.significantBits(key))) > self.recDistance() else 'tab'
        if self.twiddleSource != 'otf':
            return 'tab'
        return 'otf' if len(self.significantBits(key)) >= self.otfMinBits else 'tab'

    def generatorCount(self) -> int:
        return sum(1 for k in self.slotClasses() if self.classSource(k) in ('otf', 'rec'))

    def twistOtf(self) -> bool:
        return getattr(self, 'twistSource', 'tab') == 'otf' and self.twistSeqs is not None

    def hasGenerators(self) -> bool:
        '''Whether the generator multiplier exists (its modulus ports are pipeline inputs). With
        otfMinBits = 0 this is twiddleSource == 'otf', as before.'''
        if self.twistOtf():
            return True
        if self.twiddleSource == 'rec':
            return self.generatorCount() > 0
        if self.twiddleSource != 'otf':
            return False
        return not self.otfMinBits or self.generatorCount() > 0

    # --- 'rec': the root recurrence ------------------------------------------------------

    def recDistance(self, pipelineStages=1) -> int:
        '''D: the recurrence's loop, the generator multiplier's latency plus the output register.'''
        k = ('gen', 'recD', pipelineStages)
        if k not in self._qCache:
            g = self._multiplier(f'{self.name}_gen', IntType(0, self.qMax() - 1))
            self._qCache[k] = g.latency(pipelineStages) + 1
        return self._qCache[k]

    def recParams(self, key) -> list[tuple[str, int, int]]:
        '''Per direction of a class: (d, c, g0) with exponent(t) = c + g0*(t mod 2^k), k its significant
        bits (checked: they are the low cycle bits, gains doubling).'''
        k = len(self.significantBits(key))
        out = []
        for d, seq in key:
            order = self.order(d)
            c, gl, gh, _ = self._split(list(seq), order)
            g = gl + gh
            g0 = g[0] if k else 0
            for b in range(self.fb):
                want = (g0 << b) % order if b < k else 0
                if g[b] % order != want:
                    raise NotImplementedError(f'{self.name}: a twiddle sequence is not c + g0*(t mod 2^k); '
                                              f"use 'otf'")
            out.append((d, c, g0))
        return out

    def recBaseBits(self) -> int:
        return max(1, (self.recDistance() - 1).bit_length())

    def recTables(self, key, q: int) -> tuple[list[int], list[int]]:
        '''For one 'rec' class: the base table (per direction 2^recBaseBits words, w(j) for j < D in the
        stored domain, padded) and the update constants (one per direction: w^(g0*D) / the multiplier's
        factor, so stored values stay stored).'''
        D = self.recDistance()
        gen = self.generator(key)
        fi = pow(gen.reductionFactor(q if self.runtime else None), -1, q)
        nb = 1 << self.recBaseBits()
        base, ups = [], []
        for d, c, g0 in self.recParams(key):
            base += [self.stored(self.value(d, c + g0 * j, q), q) if j < D else 0 for j in range(nb)]
            ups.append(self.value(d, g0 * D, q) * fi % q)
        return base, ups

    def recCheck(self, key, q) -> bool:
        '''Run the recurrence bit-exactly through the generator's datapath over one period and compare
        every value with the stored twiddle (`key`: one class or a list, `q`: one modulus or a list).
        Batched in waves of D steps over every (class, q, direction) chain.'''
        D = self.recDistance()
        keys = key if isinstance(key, list) else [key]
        qs = q if isinstance(q, (list, tuple)) else [q]
        g = self._multiplier('g', IntType(0, self.qMax() - 1))
        dp = g.datapath()
        nb = 1 << self.recBaseBits()
        chains = []                                  # (period, base[:D], u, port values, expected)
        for kk in keys:
            k = len(self.significantBits(kk))
            for qq in qs:
                base, ups = self.recTables(kk, qq)
                pv = g.qPortValues(qq) if self.runtime else {}
                for i, (d, c, g0) in enumerate(self.recParams(kk)):
                    want = [self.stored(self.value(d, c + g0 * j, qq), qq) for j in range(1 << k)]
                    chains.append((1 << k, base[i * nb:i * nb + D], ups[i], pv, want))
        ys = [list(ch[1][:min(D, ch[0])]) for ch in chains]
        m = 1
        while any(m * D < ch[0] for ch in chains):
            ins, idx = {'A': [], 'B': []}, []
            for i, (per, _, u, pv, _) in enumerate(chains):
                for j in range(m * D, min((m + 1) * D, per)):
                    ins['A'].append(ys[i][j - D])
                    ins['B'].append(u)
                    for p_, v in pv.items():
                        ins.setdefault(p_, []).append(v)
                    idx.append(i)
            for i, v in zip(idx, dp.run(ins)['P']):
                ys[i].append(v)
            m += 1
        return all(ys[i] == ch[4] for i, ch in enumerate(chains))

    def otfSplit(self, seq: list[int]):
        '''Exponent sequence over the frame cycles -> (c, gLo, gHi, loBits): e(t) =
        c + sum of bit_b(t) * g_b (mod order), checked; the cycle bits split into a
        low and a high half, each indexing one table.'''
        return self._split(seq, self.order(self._dirOf(seq)))

    def _split(self, seq: list[int], order: int):
        # the same sequence is split again for every modulus and by every caller: answered from a table
        memo = self.__dict__.setdefault('_splitMemo', {})
        mk = (seq if isinstance(seq, tuple) else tuple(seq), order)
        if mk in memo:
            return memo[mk]
        memo[mk] = r = self._splitNow(seq, order)
        return r

    def _splitNow(self, seq: list[int], order: int):
        fb = self.fb
        c = seq[0]
        g = [(seq[1 << b] - c) % order for b in range(fb)]
        # the check, one addition per cycle: lin[t] = lin[t without its lowest set bit] + g[that bit]
        # (the sum over all set bits for every cycle took most of the model's time at large N)
        lin = [c] * len(seq)
        for t in range(1, len(seq)):
            lin[t] = lin[t & (t - 1)] + g[(t & -t).bit_length() - 1]
            if (lin[t] - seq[t]) % order:
                raise AssertionError(f'{self.name}: an exponent sequence is not linear in the cycle bits')
        lo = fb // 2
        return c, g[:lo], g[lo:], lo

    def otfBits(self, key) -> tuple[list[int], list[int]]:
        '''The significant cycle bits of a class split into the low table's and the high table's.'''
        sig = self.significantBits(key)
        return sig[:len(sig) // 2], sig[len(sig) // 2:]

    def otfTables(self, key, q: int) -> tuple[list[int], list[int]]:
        '''For one sequence class: the low table (stored domain, generator factor
        folded in, the constant term in it) and the high table, each indexed by
        its share of the significant cycle bits; with both directions the tables
        hold the forward entries then the inverse ones (DIR on top).'''
        gen = self.generator(key)
        fi = pow(gen.reductionFactor(q if self.runtime else None), -1, q)
        bl, bh = self.otfBits(key)
        los, his = [], []
        for d, seq in key:
            c, gl, gh, _ = self._split(list(seq), self.order(d))
            g = gl + gh
            for a in range(1 << len(bl)):
                e = c + sum(g[b] for i, b in enumerate(bl) if (a >> i) & 1)
                los.append(self.stored(self.value(d, e, q), q) * fi % q)
            for h in range(1 << len(bh)):
                e = sum(g[b] for i, b in enumerate(bh) if (h >> i) & 1)
                his.append(self.value(d, e, q))
        return los, his

    def generator(self, key):
        '''The modular multiplier of one on-the-fly twiddle stream.'''
        k = ('gen', key)
        if k not in self._qCache:
            self._qCache[k] = self._multiplier(f'{self.name}_gen', IntType(0, self.qMax() - 1))
        return self._qCache[k]

    def generatorLatency(self, pipelineStages=1) -> int:
        if not self.hasGenerators():
            return 0
        g = self._multiplier(f'{self.name}_gen', IntType(0, self.qMax() - 1))
        return g.latency(pipelineStages)

    def propagateBound(self):
        b = self.inputBound
        self.twistMultiplier = None
        if self.twistSeqs is not None and self.twistSide == 'input':
            self.twistMultiplier = self._multiplier(f'{self.name}_twist', b)
            b = self.twistMultiplier.propagateBound()
        self.butterflies = []
        for s, stage in enumerate(self.slots):
            bus = [self._bu(s, k, b) for k in range(len(stage))]
            outs = [bu.propagateBound() for bu in bus]
            lo = min(min(x.minValue, y.minValue) for x, y in outs)
            hi = max(max(x.maxValue, y.maxValue) for x, y in outs)
            b = IntType(lo, hi)
            self.butterflies.append(bus)
        if self.twistSeqs is not None and self.twistSide == 'output':
            self.twistMultiplier = self._multiplier(f'{self.name}_twist', b)
            b = self.twistMultiplier.propagateBound()
        self.outputBound = b
        return b

    def setInputBound(self, b: IntType) -> None:
        self.inputBound = b
        self.propagateBound()

    def qPorts(self) -> tuple[str, ...]:
        '''The pipeline's modulus inputs (run-time q), in a fixed order.'''
        if not self.runtime:
            return ()
        names = []
        for st in self.butterflies:
            for bu in st:
                for p in bu.portNames():
                    if p not in ('W', 'WP') and p not in names and not (p == 'DIR' and getattr(self, '_uni', False)):
                        names.append(p)
        others = ([self.twistMultiplier] if self.twistMultiplier is not None else []) + \
                 ([self._multiplier('g', IntType(0, self.qMax() - 1))] if self.hasGenerators() else [])
        for m in others:
            for p in m.qPorts():
                if p not in names:
                    names.append(p)
        if self.stageHalve:
            names.append('QHALF')               # (q+1)/2 for the per-stage x2^-1
        return tuple(names)

    def qPortValues(self, q: int) -> dict:
        vals = {}
        seen = set()
        for st in self.butterflies:
            for bu in st:
                if id(bu) in seen:              # a shared butterfly (SHARE_IDENTICAL_BU): the same values again
                    continue
                seen.add(id(bu))
                if bu.portNames():
                    vals.update({p: v for p, v in bu.qPortValues(q).items()})
        for m in ([self.twistMultiplier] if self.twistMultiplier is not None else []) + \
                 ([self._multiplier('g', IntType(0, self.qMax() - 1))] if self.hasGenerators() else []):
            vals.update(m.qPortValues(q))
        if self.stageHalve:
            vals['QHALF'] = (q + 1) // 2
        return {p: vals[p] for p in self.qPorts()}

    @staticmethod
    def halve(x: int, qhalf: int) -> int:
        '''x * 2^-1 mod q as the stage halver computes it: (x >> 1) + x[0]*(q+1)/2 (any x >= 0;
        the result stays below max(x, q) + 1, so the stage's output width holds it).'''
        return (x >> 1) + (qhalf if x & 1 else 0)

    # --- the value path ---------------------------------------------------------------

    def transform(self, frames: list[list[int]], direction: str | None = None, q: int | None = None) -> list[list[int]]:
        '''Bit-exact hardware outputs for `frames` (n points each, memory order),
        in memory order (CT: in bit-reversed, out natural; GS: in natural, out
        bit-reversed), through the butterflies and twist the RTL instantiates. `q`: the job's modulus (run time; default the
        fixed q).'''
        if isinstance(direction, (list, tuple)):  # one direction per frame (per-frame moduli, 'both')
            if len(direction) != len(frames):
                raise ValueError(f'{self.name}: {len(direction)} directions for {len(frames)} frames')
            qq = q if isinstance(q, (list, tuple)) else [q] * len(frames)
            return [self.transform([f], dd, x)[0] for f, dd, x in zip(frames, direction, qq)]
        d = direction or ('inv' if self.direction == 'inverse' else 'fwd')
        if d not in self.dirs:
            raise ValueError(f'{self.name}: direction {d!r} not built')
        if isinstance(q, (list, tuple)):          # one modulus per frame (per-frame moduli)
            if len(q) != len(frames):
                raise ValueError(f'{self.name}: {len(q)} moduli for {len(frames)} frames')
            return [self.transform([f], d, qq)[0] for f, qq in zip(frames, q)]
        q = q or self.refQ()
        if self.perFrame and q not in self.moduli and not self.loadMod:
            raise ValueError(f'{self.name}: {q} is not in the modulus table')
        if not self.runtime and q != self.q:
            raise ValueError(f'{self.name}: q is fixed at {self.q}')
        qv = self.qPortValues(q) if self.runtime else {}
        if getattr(self, '_uni', False):
            qv = dict(qv, DIR=1 if d == 'inv' else 0)     # the unified butterflies' own port
        cur = [list(f) for f in frames]
        T = len(frames)
        if self.twistMultiplier is not None and self.twistSide == 'input':
            cur = self._twist(cur, d, q, qv)
        for s, stage in enumerate(self.slots):
            p = self.stagePlan[s]
            for k, (la, lb, seqs) in enumerate(stage):
                bu = self.butterflies[s][k]
                A, B, W, idx = [], [], [], []
                for t in range(self.F):
                    mA = self._index(t, la, p['lane'], p['cyc'])
                    mB = self._index(t, lb, p['lane'], p['cyc'])
                    idx.append((mA, mB))
                    w = self.stored(self.value(d, seqs[d][t], q), q)
                    for f in range(T):
                        A.append(cur[f][mA]); B.append(cur[f][mB]); W.append(w)
                bu.aInValues, bu.bInValues = A, B
                pv = {}
                if bu.twiddleInput:
                    pv['W'] = W
                    if 'WP' in bu.portNames():
                        pv['WP'] = [self.companion(w, q) for w in W]
                for pn in bu.portNames():
                    if pn not in ('W', 'WP'):
                        pv[pn] = [qv[pn]] * len(A)
                bu.portValues = pv
                X, Y = bu.propagateValue()
                i = 0
                for mA, mB in idx:
                    for f in range(T):
                        if self.stageHalve and d == 'inv':
                            h = (q + 1) // 2
                            cur[f][mA], cur[f][mB] = self.halve(X[i], h), self.halve(Y[i], h)
                        else:
                            cur[f][mA], cur[f][mB] = X[i], Y[i]
                        i += 1
        if self.twistMultiplier is not None and self.twistSide == 'output':
            cur = self._twist(cur, d, q, qv)
        return cur

    def twistOtfBits(self, l: int) -> tuple[list[int], list[int]]:
        '''Lane l's twist: the cycle bits its exponent depends on (any direction), split low / high.'''
        sig = set()
        for d in self.dirs:
            c, gl, gh, _ = self._split(list(self.twistSeqs[l]), self.order('twist'))
            sig |= {b for b, g in enumerate(gl + gh) if g}
        sig = sorted(sig)
        return sig[:len(sig) // 2], sig[len(sig) // 2:]

    def twistOtfTables(self, l: int, q: int) -> tuple[list[int], list[int]]:
        '''twistSource='otf': lane l's low and high tables (forward entries, then inverse with both). The
        generator's output lo * hi (its factor folded into lo) is the twist multiplier's operand in its domain,
        twistValue(d, e) * fi: twistValue = K_d * b_d^e, so lo holds K_d b_d^(c + e_lo) * fi and hi b_d^e_hi.'''
        tm = self.twistMultiplier
        fi = pow(tm.reductionFactor(q if self.runtime else None), -1, q)
        gen = self._multiplier(f'{self.name}_gen', IntType(0, self.qMax() - 1))
        gfi = pow(gen.reductionFactor(q if self.runtime else None), -1, q)
        bl, bh = self.twistOtfBits(l)
        c, gl, gh, _ = self._split(list(self.twistSeqs[l]), self.order('twist'))
        g = gl + gh
        los, his = [], []
        for d in self.dirs:
            k0 = self.twistValue(d, 0, q)
            for a in range(1 << len(bl)):
                e = c + sum(g[b] for i, b in enumerate(bl) if (a >> i) & 1)
                los.append(self.twistValue(d, e, q) * fi % q * gfi % q)
            for h in range(1 << len(bh)):
                e = sum(g[b] for i, b in enumerate(bh) if (h >> i) & 1)
                his.append(self.twistValue(d, e, q) * pow(k0, -1, q) % q)
        return los, his

    def twistValue(self, d: str, e: int, q: int) -> int:
        '''The twist multiplier's factor (plain, not in its domain) for direction d and twist exponent e.
        CT (output): forward 1, inverse n^-1 psi^-e. GS (input): forward psi^e (1 cyclic), inverse n^-1
        (1 with the per-stage x2^-1).'''
        if self.twistSide == 'output':
            return pow(self.n, -1, q) * self.value('twist', e, q) % q if d == 'inv' else 1
        if d == 'fwd':
            return self.value('twist', e, q)
        return 1 if self.stageHalve else pow(self.n, -1, q)

    def _twist(self, cur, d, q, qv):
        tm = self.twistMultiplier
        fi = pow(tm.reductionFactor(q if self.runtime else None), -1, q)
        loc = self.outputLocation if self.twistSide == 'output' else self.inputLocation
        tw = [0] * self.n
        for m in range(self.n):
            t, l = loc(m)
            tw[m] = self.twistValue(d, self.twistSeqs[l][t], q) * fi % q
        out = []
        for f in range(len(cur)):
            ins = {'A': cur[f], 'B': tw}
            ins.update({pn: [qv[pn]] * self.n for pn in tm.qPorts()})
            out.append(tm.datapath().run(ins)['P'])
        return out

    def twistTables(self, q: int) -> list[list[int]]:
        '''Per lane: the twist multiplier's operand per cycle at the twist (`twistValue`),
        stored in its domain; forward then inverse with both.'''
        tm = self.twistMultiplier
        fi = pow(tm.reductionFactor(q if self.runtime else None), -1, q)
        out = []
        for l in range(self.lanes):
            per = {d: [self.twistValue(d, e, q) * fi % q for e in self.twistSeqs[l]] for d in self.dirs}
            out.append([v for d in self.dirs for v in per[d]])
        return out

    def significantBits(self, key) -> list[int]:
        '''The frame-cycle bits a sequence class's exponent depends on (in any
        direction): its table is addressed by these alone, so it holds each
        distinct twiddle once (compact storage).'''
        cache = self.__dict__.setdefault('_sigCache', {})
        if key in cache:
            return list(cache[key])
        sig = set()
        for d, seq in key:
            c, gl, gh, lo = self._split(list(seq), self.order(d))
            sig |= {b for b, g in enumerate(gl + gh) if g}
        cache[key] = sorted(sig)
        return sorted(sig)

    def _cycleOf(self, a: int, sig: list[int]) -> int:
        return sum(((a >> i) & 1) << b for i, b in enumerate(sig))

    def slotTable(self, key, q: int) -> tuple[list[int], list[int] | None]:
        '''A ROM / RAM sequence class: the stored twiddle for every combination of
        its significant cycle bits (forward then inverse with both), and Shoup's
        companions.'''
        sig = self.significantBits(key)
        w = [self.stored(self.value(d, seq[self._cycleOf(a, sig)], q), q)
             for d, seq in key for a in range(1 << len(sig))]
        return w, ([self.companion(x, q) for x in w] if self.shoup() else None)

    # --- timing and cost --------------------------------------------------------------

    def stageLatencies(self, pipelineStages=1) -> list[int]:
        out = []
        for s, p in enumerate(self.stagePlan):
            d = p['exchange'][2] if p['exchange'] else 0
            out.append(d + self.inputRegister + self.stageHalve +
                       max(bu.latency(pipelineStages) for bu in self.butterflies[s]))
        return out

    def twistLatency(self, pipelineStages=1) -> int:
        return self.twistMultiplier.latency(pipelineStages) if self.twistMultiplier is not None else 0

    def leadIn(self, pipelineStages=1) -> int:
        '''Cycles the input is delayed before anything else. A table is read 2 cycles ahead of its
        user (an on-the-fly generator 2 + its latency), from the frame counter, which `rst` holds
        until the first frame enters; a user closer to the input than that would read frame 0's
        first entries during reset. CT never has one (its first stages' twiddles are constants);
        GS's first stage, and its input twist, do. Per-frame moduli: the frame lead already puts
        every table read at offset >= 1 (the unified butterfly's first stage reads a table).'''
        if self.perFrame:
            return 0
        need, off = [], 0
        if self.twistMultiplier is not None and self.twistSide == 'input':
            if self.fb:
                need.append(2 - off)
            off += self.twistLatency(pipelineStages)
        gl = self.generatorLatency(pipelineStages)
        for s, p in enumerate(self.stagePlan):
            if p['exchange']:
                off += p['exchange'][2]
            # only a table addressed by the counter (a class with significant cycle bits) matters
            if any(self.slotConstant(s, k) is None and self.significantBits(
                    tuple((d, tuple(self.slots[s][k][2][d])) for d in self.dirs))
                   for k in range(len(self.slots[s]))):
                need.append((2 + gl if self.twiddleSource == 'otf' else 2) - off)
            off += self.inputRegister + self.stageHalve + max(bu.latency(pipelineStages) for bu in self.butterflies[s])
        if self.twistMultiplier is not None and self.twistSide == 'output' and self.fb:
            need.append(2 - off)
        return max([0] + need)

    def latency(self, pipelineStages=1) -> int:
        return self.leadIn(pipelineStages) + self.frameLead(pipelineStages) + sum(self.stageLatencies(pipelineStages)) + \
            self.twistLatency(pipelineStages) + self.reorderLatency()

    # --- per-frame moduli: the modulus table, the index, the input lead ------------------

    def modulusIndexBits(self) -> int:
        return max(1, (len(self.moduli) - 1).bit_length()) if self.perFrame else 0

    #: loadableModuli: cycles of margin on each side of a slot load
    SLOT_MARGIN = 6          # 2026-11-16: the writes land two cycles later (registered port, registers at each table)

    def slotTiming(self, slotTables: list, latency: int, loadWords: int) -> dict:
        """loadableModuli: when a slot may be filled. `slotTables`: per RAM table {base, words, offsets} from the
        RTL manifest (`slot_tables`): where its block sits in the load image and at which cycles after the first
        beat of a polynomial it is read (it is read for F cycles from there).
          after   the load may start (first tw_wen) this many cycles after the first beat of the LAST polynomial
                  that used the slot: each table is written only after that polynomial has passed it
          before  the first beat of the NEXT polynomial of the slot comes at least this many cycles after the
                  start of the load: each table is complete before that polynomial reaches it
          words   the length of the load
          together  after + before: the least distance between the two polynomials
          allAtOnce the same distance if every table were written at once behind the whole pipeline
                  (latency + frame + words), for comparison"""
        F, m = self.F, self.SLOT_MARGIN
        aft = max([max(t['offsets']) + F + 2 - t['base'] for t in slotTables if t['offsets']] + [1]) + m
        bef = max([t['base'] + t['words'] + 2 - min(t['offsets']) for t in slotTables if t['offsets']] + [1]) + m
        return {'after': aft, 'before': bef, 'words': loadWords, 'together': aft + bef,
                'allAtOnce': latency + F + loadWords + 2 * m}

    def slotPlan(self, qs, timing: dict) -> tuple:
        """loadableModuli: run the frames of moduli `qs` on the len(moduli) slots (`planSlots`)."""
        return planSlots(self.name, len(self.moduli), self.F, qs, timing)

    def modulusTable(self) -> dict:
        '''Per modulus port (Q, MU, ...): its value for each modulus, in `moduli` order.'''
        rows = [self.qPortValues(q) for q in self.moduli]
        return {p: [r[p] for r in rows] for p in self.qPorts()}

    def _offsets(self, pipelineStages=1) -> tuple[list[int], int]:
        '''Without the lead: each stage's butterfly-input offset (after its exchange), and the twist's.'''
        off, bu = 0, []
        for s, p in enumerate(self.stagePlan):
            if p['exchange']:
                off += p['exchange'][2]
            bu.append(off)
            off += max(b.latency(pipelineStages) for b in self.butterflies[s]) + self.inputRegister + self.stageHalve
        return bu, off

    def modulusSites(self, pipelineStages=1, lead: int = 0) -> list[tuple[str, int]]:
        '''(what, offset) of every point that needs a frame's modulus index valid at that offset: the
        constants' registers (one cycle before their consumer) and the table addresses (read ahead).'''
        bu, tw = self._offsets(pipelineStages)
        gl = self.generatorLatency(pipelineStages)
        classes = self.slotClasses()
        out = []
        for s, b in enumerate(bu):
            b += lead
            out.append((f's{s}', b + self.inputRegister - 1))
            if self.stageHalve:                        # the halvers' (q+1)/2, after each butterfly latency
                for lat in sorted({x.latency(pipelineStages) for x in self.butterflies[s]}):
                    out.append((f's{s}h{lat}', b + self.inputRegister + lat - 1))
            srcs = {self.classSource(self.classOf[(s, k)]) for k in range(len(self.slots[s])) if (s, k) in self.classOf}
            if 'otf' in srcs:
                out.append((f's{s}g', b - gl - 1))
                out.append((f's{s}ga', b - gl - 2))
            if 'tab' in srcs:
                out.append((f's{s}ta', b - 2))
            if 'rec' in srcs:
                out.append((f's{s}r', b - 1))          # the multiplier's constants
                out.append((f's{s}ra', b - 3))         # base table address (the update word's is b - 2)
        if self.twistMultiplier is not None:
            out.append(('tw', tw + lead - 1))
            if self.twistOtf():
                out.append(('twg', tw + lead - gl - 1))       # the twist generators' constants
                out.append(('twga', tw + lead - gl - 2))      # their tables' address
            else:
                out.append(('twa', tw + lead - 2))
        return out

    def frameLead(self, pipelineStages=1) -> int:
        '''Cycles the data waits at the input (per-frame moduli only) so that every site's offset is >= 1:
        the index is registered on the frame's first cycle (offset 0), valid from offset 1.'''
        if not self.perFrame:
            return 0
        lo = min(o for _, o in self.modulusSites(pipelineStages, 0))
        lead = max(0, 1 - lo)
        return lead

    def criticalPathNs(self, pipelineStages=1) -> float:
        ns = [bu.criticalPathNs(pipelineStages) for st in self.butterflies for bu in st]
        if self.twistMultiplier is not None:
            ns.append(self.twistMultiplier.criticalPathNs(pipelineStages))
        return max(ns)

    def resources(self, pipelineStages=1) -> dict:
        '''Predicted area of the core without a build (2026-11-14): {'lut', 'ff', 'dsp', 'bram36', 'uram', 'au',
        'byClass'} from the instance inventory of `StreamArea` (the emitted structure priced with the shared
        component model). au = (kLUT + kFF + DSP x 4/3 + BRAM36 + 8 x URAM) / 5.'''
        from . import StreamArea
        return StreamArea.totals(StreamArea.inventory(self, pipelineStages))

    def areaCost(self) -> tuple[int, int]:
        lut = dsp = 0
        for st in self.butterflies:
            for bu in st:
                a, d = bu.areaCost()
                lut += a
                dsp += d
        if self.stageHalve:
            # two halvers per butterfly: an adder of the output width (one LUT per bit; the mux on x[0]
            # folds into it) and, with a DIR port, the bypass mux (one more LUT per bit)
            per = 2 if self.direction == 'both' else 1
            for st in self.butterflies:
                for bu in st:
                    ow = max(b.bitWidth for b in bu.propagateBound())
                    lut += 2 * per * ow
        extra = (self.lanes if self.twistMultiplier is not None else 0)
        if extra:
            a, d = self.twistMultiplier.areaCost()
            lut += a * extra
            dsp += d * extra
        if self.hasGenerators():
            g = self._multiplier('g', IntType(0, self.qMax() - 1))
            a, d = g.areaCost()
            nGen = self.generatorCount() + (self.lanes if self.twistOtf() else 0)
            lut += a * nGen
            dsp += d * nGen
        if self.perFrame:
            lut += self.modulusTableLuts()
        return lut, dsp

    def modulusTableLuts(self) -> int:
        '''Per-frame moduli: each constants site is a ROM of len(moduli) words (one LUT6 per output bit
        per 64 entries) and registers; the lead delay is SRLs (one LUT per bit per 32 cycles).'''
        w = sum(max(v).bit_length() for v in self.modulusTable().values())
        sites = sum(1 for nm, _ in self.modulusSites() if not nm.endswith('a'))
        rom = -(-len(self.moduli) // 64) * w * sites
        lead = self.frameLead()
        return rom + (self.lanes * self.inputBound.bitWidth * -(-lead // 32) if lead else 0)

    def twiddleWords(self) -> int:
        '''Words of twiddle storage (tables, both directions, Shoup companions counted).'''
        cls = self.slotClasses()
        per = 2 if self.shoup() else 1
        if self.twiddleSource == 'stream':
            words = 0                                  # no tables: the twiddles arrive with the data
        elif self.twiddleSource == 'rec':
            nb = 1 << self.recBaseBits()
            words = sum((nb + 1) if self.classSource(k) == 'rec' else (1 << len(self.significantBits(k)))
                        for k in cls) * len(self.dirs)
        elif self.twiddleSource == 'otf' and not self.otfMinBits:
            words = sum((1 << len(self.otfBits(k)[0])) + (1 << len(self.otfBits(k)[1])) for k in cls) * len(self.dirs)
        elif self.twiddleSource == 'otf':
            words = sum(((1 << len(self.otfBits(k)[0])) + (1 << len(self.otfBits(k)[1]))) if self.classSource(k) == 'otf'
                        else (1 << len(self.significantBits(k))) for k in cls) * len(self.dirs)
        else:
            words = sum(1 << len(self.significantBits(k)) for k in cls) * len(self.dirs) * per
        if self.twistOtf():
            words += sum(len(self.twistOtfTables(l, self.refQ())[0]) + len(self.twistOtfTables(l, self.refQ())[1])
                         for l in range(self.lanes))
        elif self.twistSeqs is not None:
            words += self.lanes * self.F * (2 if self.direction == 'both' else 1)
        return words * (len(self.moduli) if self.perFrame else 1)

    # --- 'stream': the twiddles arrive with the frames (AutoNTT's way, from HBM) ------------

    def streamClasses(self) -> list:
        '''The classes fed through the twiddle stream, in port order (tw_s<i>): every non-constant class.'''
        return [k for k in self.slotClasses() if self.classSource(k) == 'stream']

    def streamWordsPerCycle(self) -> int:
        '''Twiddle words a cycle the stream carries (one per class, the job's direction only).'''
        return len(self.streamClasses()) if self.twiddleSource == 'stream' else 0

    def streamImage(self, qs, d) -> list:
        '''Per frame (modulus qs[f]), per frame cycle t: the stored twiddle of every stream class at
        cycle t, direction d (one, or a list: one per frame). Port tw_s<i> carries entry i in step with
        the frame's data (x_in at cycle t).'''
        cls = self.streamClasses()
        out = []
        ds = list(d) if isinstance(d, (list, tuple)) else [d] * len(qs)
        for q, d in zip(qs, ds):
            fr = []
            for t in range(self.F):
                fr.append([self.stored(self.value(d, dict(key)[d][t], q), q) for key in cls])
            out.append(fr)
        return out

    def streamDelayWords(self, pipelineStages=1) -> int:
        '''Words of on-chip delay the stream needs: each class is delayed (in a chain) to its last use.'''
        if self.twiddleSource != 'stream':
            return 0
        bu, _ = self._offsets(pipelineStages)
        lead = self.frameLead(pipelineStages)
        last = {}
        for (s, k), key in self.classOf.items():
            last[key] = max(last.get(key, 0), bu[s] + lead)
        return sum(last.values())

    def propagateValue(self):
        raise NotImplementedError(f'{self.name}: use transform(frames)')

    def getOperatorInterface(self, name: str, pipelineStages: int = 1):
        raise NotImplementedError(f'{self.name}: the streaming spec comes from StreamingNTT.getOperatorInterface')


def planSlots(name: str, K: int, F: int, qs, timing: dict) -> tuple:
    """Run polynomials of moduli `qs` (one every F cycles, back to back; any moduli, not only the stand-ins) on K
    table slots. Returns (slot of each polynomial, loads), a load being (cycle of its first word, slot, modulus)
    with the cycle counted from the first cycle of polynomial 0 (-1: before it, those loads run one after the
    other). `timing`: slotTiming(). A modulus that sits in no slot takes the slot unused the longest whose last
    polynomial is far enough back, and its load is placed as late as possible.
    Raises ValueError when no slot is free or the loader is busy: the sequence needs more slots."""
    if not timing['words']:                 # no table in the core: the constants travel, nothing to load
        return [0] * len(qs), []
    held, last, slots, loads = [None] * K, [None] * K, [], []
    busy = None                             # the cycle the loader is free again
    for f, q in enumerate(qs):
        if q in held:
            k = held.index(q)
        else:
            tL = f * F - timing['before']
            free = [i for i in range(K) if last[i] is None or tL >= last[i] * F + timing['after']]
            if not free:
                raise ValueError(f'{name}: polynomial {f} needs a slot, but every one of the {K} slots held a '
                                 f'polynomial in the last {timing["together"]} cycles')
            k = min(free, key=lambda i: -1 if last[i] is None else last[i])
            pre = tL < 0 or last[k] is None     # a slot never used is filled before polynomial 0
            if not pre and busy is not None and tL < busy:
                raise ValueError(f'{name}: polynomial {f} needs a load from cycle {tL}, but the loader is busy '
                                 f'until cycle {busy}')
            held[k] = q
            loads.append((-1 if pre else tL, k, q))
            if not pre:
                busy = tL + timing['words'] + 2
        last[k] = f
        slots.append(k)
    return slots, loads


def slotTimingOf(F: int, slotTables: list, latency: int, loadWords: int, margin: int = 6) -> dict:
    """See StreamingNTTScheme.slotTiming: `slotTables` = [{base, words, offsets}], offsets = cycles after the first
    beat of a polynomial at which the table starts to be read (it is read for F cycles from each)."""
    aft = max([max(t['offsets']) + F + 2 - t['base'] for t in slotTables if t['offsets']] + [1]) + margin
    bef = max([t['base'] + t['words'] + 2 - min(t['offsets']) for t in slotTables if t['offsets']] + [1]) + margin
    return {'after': aft, 'before': bef, 'words': loadWords, 'together': aft + bef,
            'allAtOnce': latency + F + loadWords + 2 * margin}
