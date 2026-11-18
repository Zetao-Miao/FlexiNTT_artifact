'''The hybrid NTT: a block of U unrolled butterfly stages, used again and again in a loop.

    HybridNTTScheme   the model: geometry, bit-exact values, the cycle model (controller
                      twin), resources, a DSP budget, the 'auto' choices
    (the operator, RTL spec and testbench are in HybridNTT.py; the RTL in
    versal_arith/rtl_gen/hybrid_ntt.py; notes ntt_hw/experiments/hybrid/DESIGN.md)

Structure. W = g x 2^U lanes: g groups ("blocks", AutoNTT's BUGs) of 2^U lanes, each with U stages of
2^(U-1) CT butterflies; stage j pairs the lanes that differ in lane bit j (fixed wiring, no bit reversal).
A polynomial passes the block R = ceil(L / U) times ("rounds"), T = n / W cycles per round. With
e = R U - L > 0 the first e stages of the block are bypassed in round 0 (the short round first).

Order (constant geometry). Position p = beat * W + lane. In round r index bit i sits at position
(i + e - r U) mod L, so stage j of round r runs CT stage s = r U - e + j on lane bit j. Between rounds
the positions rotate by U bits: position p' of round r+1 holds position rotl(p', U) of round r. The
input takes memory index m (CT memory order: the bit-reversed natural input) at position rotl(m, e)
(e = 0: beat m // W, lane m mod W); the output leaves memory index k (natural order) at rotl(k, U).

Memory between rounds. Bank of position (c, l), l = lo + 2^U hi: hi * 2^U + ((lo + c) mod 2^U), at
address c (plus the buffer's base): a round's write rotates each group by c mod 2^U; the next round
reads every bank at its own address and rotates back by the top U beat bits, then wires group h,
entry j to lane h + g j. Conflict-free in both directions when n >= W 2^U (`checkGeometry`). A pool
of S + 1 buffers of n words (slot k writes buffer k mod (S+1)); the input is an n-word FIFO (round 0
reads it in beat order); the last round goes to the output lanes (out_valid, no backpressure).

Schedule. Slots of Delta cycles: slot k belongs to polynomial slot (context) k mod S and to round
(k div S) mod R. Round r+1 of a context reads what its round r wrote S slots earlier, so
S Delta >= Dw + T - T/2^U (`slotLength`). A round-0 slot starts a context only when the FIFO holds
a whole polynomial; when no context is busy the controller stops and restarts at slot 0 as soon as a
polynomial is complete. Interval R Delta, latency (one polynomial alone) about T + (R-1) S Delta + T + Dout.

Per polynomial: MIDX (with `moduli=[...]`, more than one) and DIR (direction 'both') enter with the
polynomial's first beat and travel with its context, so every polynomial may use another modulus and
direction with no gap. Twiddles: per class (distinct sequence over the rounds and beats) a ROM with
every modulus and direction, address {MIDX, DIR, base_r + top beat bits}.

Arithmetic as the iterative NTT (it borrows the streaming NTT's helpers): CT, the inverse is CT with
the inverse cyclic twiddles, scaled by x2^-1 after every butterfly ('stage', cyclic) or by n^-1 psi^-k
multipliers on the W output lanes ('output'); negacyclic forward merges psi into the twiddles.
'''
from __future__ import annotations


from ...core.IntType import IntType
from ...core.OperatorScheme import OperatorScheme
from ..dataflow.StreamingNTTScheme import StreamingNTTScheme
from ..memory import ramCost, MEM_STYLES


def _rotl(x: int, k: int, w: int) -> int:
    k %= w
    m = (1 << w) - 1
    return ((x << k) | (x >> (w - k))) & m if k else x


def _rotr(x: int, k: int, w: int) -> int:
    return _rotl(x, -k % w, w)


def _ins(x: int, pos: int, bit: int) -> int:
    lo = x & ((1 << pos) - 1)
    return ((x >> pos) << (pos + 1)) | (bit << pos) | lo


def _bits(x: int) -> int:
    return max(1, (x - 1).bit_length())


class HybridNTTScheme(OperatorScheme):
    '''A hybrid (partly unrolled, looped) radix-2 NTT; see the module notes.

    Arguments
      n            points (a power of two)
      stages       U, unrolled stages in the block
      groups       g, blocks side by side (W = g 2^U lanes)
      q / moduli   a fixed q, or moduli=[q0, q1, ...]: a modulus per polynomial (MIDX); one entry = fixed q;
                   with moduli, family= a run-time ModulusFamily holding them (default ModulusFamily.table(moduli))
      negacyclic   negacyclic (psi merged into the forward twiddles; the inverse needs inverseScale='output')
      direction    'forward', 'inverse' or 'both' (DIR per polynomial)
      inverseScale 'stage' (x2^-1 per butterfly, cyclic) or 'output' (n^-1 psi^-k, W multipliers)
      butterfly    ModularBU arguments (reduction, multiplier, ...)
      slots        S polynomials in the loop: 1, 2, ... or 'auto' (`slotReport`)
      twiddleSource 'rom' (tables of every modulus and direction), 'rec' (Kim's root recurrence per table: one
                   modular multiplier, a base table of k words and one update word per modulus and direction),
                   'otf' (two tables of ~sqrt entries and one multiplier per table), or 'auto' (per table the
                   cheaper of 'rom' and 'rec' in area units); tables with fewer than `genMinBits` beat bits stay ROM;
                   'tree' (per round and stage one table; every other table of that stage is that table times
                   one constant per modulus and direction: one multiplier per derived table, `treeGroups`);
                   'stream' (no twiddle table in the core: per table the core gives the address on
                   tw_addr_<i> and takes the word on tw_data_<i> `ramLatency` cycles later; with `loadable`
                   the modulus constants are still loaded)
      genMinBits   see twiddleSource (default 3)
      twistSource  the output twist's operands (negacyclic / scaled inverse): 'tab' (a table of T words per lane,
                   modulus and direction), 'rec' (per lane a recurrence: one multiplier, Lgen + 1 base words per
                   modulus and direction, one shared update word), 'auto' (the cheaper)
      loadable     True: a modulus unknown at build time. Nothing in the RTL depends on the moduli: every table
                   and every modulus constant is a RAM / register written through the load port (ld_we, ld_sel,
                   ld_addr, ld_data; the map is in manifest.json). family= is the run-time family the datapath is
                   built for; moduli= then names the slots (MIDX picks one per polynomial) and the values the
                   model and the testbench load. A slot may be reloaded while no polynomial uses it.
      ramLatency   read registers of the data RAMs and ROMs (2: registered read + output register)
      outReady     True: an out_ready input; the output beats wait in a buffer of outDepth polynomials and a
                   polynomial is admitted only while the buffer has room for it (HybridPorts: the proof)
      outDepth     polynomials the output buffer holds (default: the most in flight, plus one; any >= 1 is safe)
      outputOrder  'core' (beat c lane l = coefficient rotr(c W + l, U, log2 n)) or 'natural'
      twiddleBuffer  'record' (with loadable=True): the modulus of every polynomial comes as a record on a
                   valid/ready stream (tw_valid, tw_ready, tw_data), loaded into a free table set
      memStyle, twiddleStyle  'auto', 'atp', 'distributed', 'block', 'ultra' (NTTScheme.ramCost)
    '''

    _BOUND_ATTRS = ()
    _VALUE_ATTRS = ()

    # the roots, exponents, stored domain and butterfly helpers of the streaming NTT
    qMax = StreamingNTTScheme.qMax
    rootOrder = StreamingNTTScheme.rootOrder
    refQ = StreamingNTTScheme.refQ
    base = StreamingNTTScheme.base
    order = StreamingNTTScheme.order
    value = StreamingNTTScheme.value
    _exponentCT = StreamingNTTScheme._exponent
    _probe = StreamingNTTScheme._probe
    storedFactor = StreamingNTTScheme.storedFactor
    stored = StreamingNTTScheme.stored
    shoup = StreamingNTTScheme.shoup
    companion = StreamingNTTScheme.companion
    _buArgs = StreamingNTTScheme._buArgs
    _mulArgs = StreamingNTTScheme._mulArgs
    _multiplier = StreamingNTTScheme._multiplier

    def mergedTwist(self, d: str) -> bool:
        '''Whether direction d's twiddles carry psi^(+-1): the CT forward, and with unified butterflies the GS inverse.'''
        return self.negacyclic and (d == 'fwd' or (d == 'inv' and getattr(self, 'unified', False)))

    def _exponent(self, d: str, s: int, mA: int) -> int:
        '''Stage s's twiddle exponent for the pair at memory index mA. CT: StreamingNTTScheme's. Unified inverse: the
        GS butterfly over the bit-reversed labelling m' = brv(m) (GS pairs m' bit L-1-s = m bit s, so the block keeps its
        CT wiring): w^-(j n/2^(c+1)) or psi^-((2j+1) n/2^(c+1)), c = L-1-s, j = m'_A mod 2^c.'''
        if d != 'inv' or not getattr(self, 'unified', False):
            return self._exponentCT(d, s, mA)
        from ...core.utils import bitReverse
        c = self.L - 1 - s
        j = bitReverse(mA, self.L) % (1 << c)
        step = self.n >> (c + 1)
        return (2 * j + 1) * step if self.negacyclic else j * step
    stageBit = StreamingNTTScheme.stageBit
    halve = staticmethod(StreamingNTTScheme.halve)

    dspTree = None
    _dspPlan = None

    def __init__(self, name: str, n: int, stages: int, groups: int = 1, q: int = 0, moduli=None,
                 negacyclic: bool = False, direction: str = 'both', inverseScale: str = 'output',
                 butterfly: dict | None = None, twiddleSource: str = 'auto', slots='auto', genMinBits: int = 3,
                 twistSource: str = 'auto', family=None, unified: bool = False,
                 targetFmaxMhz: float | None = None, primitiveRoot: int | None = None, ramLatency: int = 2,
                 memStyle: str = 'auto', twiddleStyle: str = 'auto', loadable: bool = False, ioLanes: int | None = None,
                 crossRegs: int = 0,
                 fanout: int | None = None, fanoutLoads: str = 'register',
                 outReady: bool = False, outDepth: int | None = None, outputOrder: str = 'core',
                 twiddleBuffer: str | None = None, twiddleLanes: int = 1,
                 shareInverseTwiddles: bool = False):
        super().__init__(name)
        from ...modmult.ModulusFamily import ModulusFamily as MF
        L = n.bit_length() - 1
        if n != 1 << L or n < 8:
            raise ValueError(f'{name}: n must be a power of two >= 8')
        U, g = stages, groups
        if U < 1 or U > L:
            raise ValueError(f'{name}: stages must be in [1, log2 n]')
        if g < 1 or g != 1 << (g.bit_length() - 1):
            raise ValueError(f'{name}: groups must be a power of two')
        lp = U + g.bit_length() - 1
        if L - lp < U:
            raise ValueError(f'{name}: n must be >= lanes x 2^stages (the round-to-round transpose); '
                             f'n={n}, lanes={1 << lp}, stages={U}')
        if direction not in ('forward', 'inverse', 'both'):
            raise ValueError(f"{name}: direction 'forward', 'inverse' or 'both'")
        if inverseScale not in ('output', 'stage'):
            raise ValueError(f"{name}: inverseScale 'output' or 'stage'")
        # unified=True: the unified CT/GS butterfly (ntt/butterfly/UnifiedButterfly.py): forward CT with psi merged, inverse GS
        # with psi^-1 merged and x2^-1 per stage, so even the negacyclic inverse needs no output twist multipliers
        self.unified = bool(unified)
        if self.unified:
            if direction == 'forward':
                raise ValueError(f'{name}: unified=True is for an inverse (direction both or inverse)')
            if ((butterfly or {}).get('multiplierKind') == 'shoup'
                    and (butterfly or {}).get('productRange', 'exact') not in ('exact', 1)):
                raise ValueError(f"{name}: unified Shoup butterflies take productRange 'exact' (the GS output is the "
                                 f"product itself; a lazy one would widen the operand past the companion's beta)")
            inverseScale = 'stage'
        if inverseScale == 'stage' and ((negacyclic and not self.unified) or direction == 'forward'):
            raise ValueError(f"{name}: inverseScale='stage' needs a cyclic transform with an inverse "
                             f"(a negacyclic CT inverse needs the psi^-k output multipliers)")
        if twiddleSource not in ('rom', 'rec', 'otf', 'auto', 'tree', 'stream'):
            raise ValueError(f"{name}: twiddleSource {twiddleSource!r}: 'rom', 'rec', 'otf', 'tree', 'stream' "
                             f"or 'auto'")
        self.genMinBits = int(genMinBits)
        if twistSource not in ('auto', 'tab', 'rec'):
            raise ValueError(f"{name}: twistSource 'auto', 'tab' or 'rec'")
        self.twistSourceReq = twistSource
        self.twistSrc = 'tab'
        if (butterfly or {}).get('multiplierKind') == 'shoup':
            # Shoup butterflies: every twiddle word carries its companion WP = floor(w 2^k / q), which a
            # generator multiplier cannot produce, so the twiddles are tables ('rom', or loaded)
            if twiddleSource not in ('rom', 'auto', 'stream'):
                raise ValueError(f"{name}: Shoup butterflies need twiddleSource 'rom', 'stream' (or 'auto'): a "
                                 f"generated twiddle has no companion")
            if twiddleSource == 'auto':
                twiddleSource = 'rom'
        for st in (memStyle, twiddleStyle):
            if st not in MEM_STYLES:
                raise ValueError(f'{name}: memory style {st!r}: one of {MEM_STYLES}')
        if ramLatency not in (1, 2, 3, 4):
            raise ValueError(f'{name}: ramLatency 1 .. 4')
        # the modulus: one fixed q (moduli=[q] is the same), or a table of moduli with MIDX per polynomial
        if moduli is not None:
            moduli = list(moduli)
            if q:
                raise ValueError(f'{name}: moduli= replaces q=')
            if len(set(moduli)) != len(moduli) or not moduli:
                raise ValueError(f'{name}: moduli must be distinct and not empty')
            if len(moduli) == 1 and not loadable:
                q, moduli = moduli[0], None
        self.loadable = bool(loadable)
        if self.loadable and (moduli is None or family is None or not family.runtime or family.kind == 'table'):
            raise ValueError(f'{name}: loadable=True needs family= (a run-time family, not a table) and moduli= '
                             f'(the slots: the moduli the model and the testbench load)')
        self.moduli = moduli
        self.perFrame = moduli is not None
        if self.perFrame:
            # family= (with moduli=): build the datapath over that run-time family (e.g. friendly primes for
            # word-level Montgomery, which has no table form); every modulus must belong to it
            if family is not None:
                if not family.runtime or any(not family.contains(m) for m in moduli):
                    raise ValueError(f'{name}: every modulus must belong to the run-time family {family.describe()}')
                self.family = family
            else:
                self.family = MF.table(moduli)
            self.runtime = True
            self.q = 0
        else:
            if q < 3:
                raise ValueError(f'{name}: give q= or moduli=')
            self.family, self.runtime, self.q = None, False, q
        self.n, self.L, self.U, self.g, self.lp = n, L, U, g, lp
        self.W = 1 << lp
        self.T = n // self.W
        self.CB = L - lp                        # beat bits
        # ioLanes: the words per beat at the ports (default W). Narrower: the input beats are gathered into
        # core beats, the output beats leave a buffer of two polynomials; wider: the input beat is fed in
        # io/W core beats, the output beats are collected. The order of the words is the same (position
        # beat x ioLanes + lane). The period is max(core, n / ioLanes) (`simulateIoJob`).
        io = ioLanes or self.W
        if io < 1 or io > n or io != 1 << (io.bit_length() - 1):
            raise ValueError(f'{name}: ioLanes must be a power of two in [1, n]')
        self.io = io
        # crossRegs: extra register stages between the memories and the block, on the operand path (in front of
        # the block) and on the write path (after the write rotator), for nets that cross SLRs; each costs one
        # cycle of the write offset twice (the slot bubble grows by 2 crossRegs / S)
        if crossRegs < 0 or crossRegs > 4:
            raise ValueError(f'{name}: crossRegs in [0, 4]')
        self.XR = crossRegs
        # fanout: register trees behind the wide control nets (RAM addresses and write enables, mux selects,
        # per-stage tags, modulus constants, twiddle words), every register driving at most `fanout` loads
        # (`fanoutPlan`). None: off (the core as before). fanoutLoads: what a RAM bank costs a tree register:
        # 'register' (one load) or 'pins' (the bank's RAM primitives)
        if fanout is not None and (not isinstance(fanout, int) or fanout < 2):
            raise ValueError(f'{name}: fanout >= 2')
        if fanoutLoads not in ('register', 'pins'):
            raise ValueError(f"{name}: fanoutLoads 'register' or 'pins'")
        self.fanout, self.fanoutLoads = fanout, fanoutLoads
        # shareInverseTwiddles: an inverse table that is +- a forward table of its round and stage (read at a
        # mapped address) is not stored; the sign is a swap of the butterfly's outputs (`inverseShare`)
        if shareInverseTwiddles:
            bad = ('a negacyclic transform' if negacyclic else 'one direction only' if direction != 'both' else
                   'unified butterflies (the inverse is GS: its tables are indexed by other beat bits)' if unified
                   else f"twiddleSource {twiddleSource!r} (stored tables only: twiddleSource='rom')"
                   if twiddleSource != 'rom' else 'a record stream (twiddleBuffer)' if twiddleBuffer else
                   'fanout= (the trees of the borrowed tables are not built)' if fanout else None)
            if bad:
                raise ValueError(f'{name}: shareInverseTwiddles is built for a cyclic transform with both '
                                 f'directions, CT butterflies and stored tables; not with {bad}')
        self.shareInv = bool(shareInverseTwiddles)
        self.R = -(-L // U)                     # rounds
        self.e = self.R * U - L                 # stages bypassed in round 0
        self.butterflyType = 'CT'
        self.negacyclic = negacyclic
        self.direction = direction
        self.dirs = (['fwd'] if direction in ('forward', 'both') else []) + \
                    (['inv'] if direction in ('inverse', 'both') else [])
        self.inverseScale = inverseScale
        self.stageHalve = 1 if inverseScale == 'stage' else 0
        self.twistOn = direction != 'forward' and inverseScale == 'output'
        self.butterflyArgs = dict(butterfly or {})
        self.twiddleSource = twiddleSource
        self.targetFmaxMhz = targetFmaxMhz
        self.primitiveRoot = primitiveRoot
        self.RL = ramLatency
        self.memStyle, self.twiddleStyle = memStyle, twiddleStyle
        self._slotsReq = slots
        if slots != 'auto' and (not isinstance(slots, int) or slots < 1 or slots > 8):
            raise ValueError(f"{name}: slots 1 .. 8 or 'auto'")
        self.S = slots if slots != 'auto' else 1
        self._qCache = {}
        bad = [x for x in (self.moduli or [self.q]) if (x - 1) % self.rootOrder()]
        if bad:
            raise ValueError(f'{name}: {self.rootOrder()} does not divide q - 1 for {bad[:3]}')
        self._initPorts(outReady, outDepth, outputOrder, twiddleBuffer, twiddleLanes)

    # --- modulus table ------------------------------------------------------------------

    def moduliList(self) -> list[int]:
        return list(self.moduli) if self.perFrame else [self.q]

    def midxBits(self) -> int:
        return (len(self.moduli) - 1).bit_length() if self.perFrame else 0

    def midx(self, q: int) -> int:
        return self.moduliList().index(q)

    # --- geometry -----------------------------------------------------------------------

    def index(self, r: int, p: int) -> int:
        '''The memory index at position p in round r's layout (index bit i at (i + e - rU) mod L).'''
        return _rotl(p, (r * self.U - self.e) % self.L, self.L)

    def inputPosition(self, m: int) -> int:
        return _rotl(m, self.e, self.L)

    def outputPosition(self, k: int) -> int:
        return _rotl(k, self.U, self.L)

    def inputLocation(self, m: int) -> tuple[int, int]:
        p = self.inputPosition(m)
        return p >> self.lp, p & (self.W - 1)

    def outputLocation(self, k: int) -> tuple[int, int]:
        p = self.outputPosition(k)
        return p >> self.lp, p & (self.W - 1)

    def stageOf(self, r: int, j: int) -> int | None:
        s = r * self.U - self.e + j
        return s if s >= 0 else None

    def pairs(self):
        '''Every butterfly of the block: (stage j, group h, pair a, lane A, lane B).'''
        U = self.U
        out = []
        for j in range(U):
            for h in range(self.g):
                for a in range(1 << (U - 1)):
                    la = h * (1 << U) + _ins(a, j, 0)
                    out.append((j, h, a, la, la + (1 << j)))
        return out

    def bank(self, c: int, l: int) -> int:
        U = self.U
        m = (1 << U) - 1
        return (l >> U) * (1 << U) + (((l & m) + c) & m)

    def readSource(self, c: int, l: int) -> tuple[int, int]:
        '''(beat, lane) of the previous round's position read at beat c, lane l (rotl by U).'''
        p = _rotl(c * self.W + l, self.U, self.L)
        return p >> self.lp, p & (self.W - 1)

    def readBank(self, c: int, l: int) -> tuple[int, int]:
        oc, ol = self.readSource(c, l)
        return self.bank(oc, ol), oc

    def checkGeometry(self) -> list[str]:
        '''Every beat writes W distinct banks; every read beat reads W distinct banks; the RTL's
        closed forms (bank address, lane wiring) agree with the definition; the rounds run every
        CT stage once.'''
        errs = []
        U, W, g, T = self.U, self.W, self.g, self.T
        M = (1 << U) - 1
        for c in range(T):
            if len({self.bank(c, l) for l in range(W)}) != W:
                errs.append(f'write beat {c}: bank conflict')
                break
        tsh = self.CB - U
        for c in range(T):
            rb = [self.readBank(c, l) for l in range(W)]
            if len({b for b, _ in rb}) != W:
                errs.append(f'read beat {c}: bank conflict')
                break
            t, cm = c >> tsh, c & ((1 << tsh) - 1)
            for l in range(W):
                b, a = rb[l]
                h, k = b >> U, b & M
                if a != (cm << U) | ((k - t) & M) or l != h + g * ((k - t) & M):
                    errs.append(f'read beat {c} lane {l}: closed form disagrees')
                    break
        st = [self.stageOf(r, j) for r in range(self.R) for j in range(U)]
        if sorted(s for s in st if s is not None) != list(range(self.L)):
            errs.append('stages do not cover 0 .. L-1 once')
        for r in range(self.R):
            for j in range(U):
                s = self.stageOf(r, j)
                if s is None:
                    continue
                for p in (0, 5 % self.n, self.n - 1):
                    if ((self.index(r, p) ^ self.index(r, p ^ (1 << j))) != (1 << s)):
                        errs.append(f'round {r} stage {j}: lane bit {j} is not index bit {s}')
                        break
        return errs

    # --- butterfly, bounds, modulus ports ------------------------------------------------

    def butterflyUnit(self):
        if getattr(self, '_bu', None) is None:
            raise ValueError(f'{self.name}: set the input bound first (setInputBound)')
        return self._bu

    def _makeBu(self, bound: IntType):
        from ..butterfly.ButterflyScheme import ModularBU
        fam = dict(family=self.family) if self.runtime else dict(q=self.q)
        cls = ModularBU
        if self.unified:
            from ..butterfly.UnifiedButterfly import UnifiedBU as cls
        bu = cls(name=f'{self.name}_bu', butterflyType='CT', twiddleInput=True,
                 targetFmaxMhz=self.targetFmaxMhz, **fam, **self._buArgs())
        bu.aIn = bu.bIn = bound
        if self._dspPlan:
            bu.dspBudgets = self._dspPlan.get('bu')
        return bu

    def propagateBound(self):
        '''The data word's bound: the input bound widened until the butterfly (and the halver) maps it
        into itself (every round reads what the previous one wrote).'''
        b = self.inputBound
        for _ in range(6):
            bu = self._makeBu(b)
            x, y = bu.propagateBound()
            hi = max(b.maxValue, x.maxValue, y.maxValue)
            nb = IntType(min(b.minValue, x.minValue, y.minValue), hi)
            if nb.minValue == b.minValue and nb.maxValue == b.maxValue:
                break
            b = nb
        else:
            raise ValueError(f'{self.name}: the butterfly output bound does not settle')
        if b.minValue < 0:
            raise ValueError(f'{self.name}: signed butterfly outputs are not supported (choose an exact output range)')
        self.memBound = b
        self._bu = bu
        self.twistMultiplier = None
        if self.twistOn:
            self.twistMultiplier = self._multiplier(f'{self.name}_twist', b)
            self.outputBound = self.twistMultiplier.propagateBound()
        else:
            self.outputBound = b
        self._gen = None
        if self.twiddleSource not in ('rom', 'stream') or (self.twistOn and self.twistSourceReq != 'tab'):
            self._gen = self._multiplier(f'{self.name}_gen', IntType(0, self.qMax() - 1))
            self._gen.propagateBound()
        self._chooseSources()
        self._chooseTwist()
        if not any(x != 'rom' for x in self._srcOf) and self.twistSrc != 'rec':
            self._gen = None
        if self._slotsReq == 'auto':
            self.S = self.slotReport()['choice']
        self._chooseInDepth()
        self._fitBramBudget()
        self._checkPorts()
        return self.outputBound

    def setInputBound(self, b: IntType) -> None:
        self.inputBound = b
        self.propagateBound()

    def qPorts(self) -> tuple[str, ...]:
        if not self.runtime:
            return ()
        names = [p for p in self.butterflyUnit().portNames() if p not in ('W', 'WP', 'DIR')]
        if self.twistMultiplier is not None:
            names += [p for p in self.twistMultiplier.qPorts() if p not in names]
        if self.stageHalve:
            names.append('QHALF')
        return tuple(names)

    def qPortValues(self, q: int) -> dict:
        if not self.runtime:
            return {}
        vals = dict(self.butterflyUnit().qPortValues(q))
        if self.twistMultiplier is not None:
            vals.update(self.twistMultiplier.qPortValues(q))
        if self.stageHalve:
            vals['QHALF'] = (q + 1) // 2
        return {p: vals[p] for p in self.qPorts()}

    # --- twiddles ------------------------------------------------------------------------

    def sigBits(self, r: int) -> int:
        '''Beat bits a round's twiddles depend on (the top ones): the index bits below rU - e.'''
        return min(self.CB, max(0, r * self.U - self.e))

    def entryBits(self, r: int, d: str) -> tuple[int, int]:
        """(lo, nb): the beat bits [lo, lo + nb) a round's twiddles depend on in direction d. CT: the top sigBits(r)
        (the index bits below rU - e); the unified inverse (GS over brv(m)): the low CB - sigBits(r) (the index bits
        not yet processed)."""
        sb = self.sigBits(r)
        if d == 'inv' and self.unified:
            return 0, self.CB - sb
        return self.CB - sb, sb

    def entryCount(self, r: int) -> int:
        """Entries of one (modulus, direction) block of a round-r table: the larger direction's."""
        return 1 << max(self.entryBits(r, d)[1] for d in self.dirs)

    def entryOf(self, r: int, d: str, c: int) -> int:
        lo, nb = self.entryBits(r, d)
        return (c >> lo) & ((1 << nb) - 1)

    def roundExponents(self, r: int, j: int, la: int, d: str) -> list[int] | None:
        """Butterfly (stage j, lane A)'s exponents in round r per entry (entryBits); None when the stage is
        bypassed. Checks that an entry holds one value."""
        s = self.stageOf(r, j)
        if s is None:
            return None
        lo, nb = self.entryBits(r, d)
        tab = [None] * (1 << nb)
        for c in range(self.T):
            ex = self._exponent(d, s, self.index(r, c * self.W + la)) % self.order(d)
            i = (c >> lo) & ((1 << nb) - 1)
            if tab[i] is None:
                tab[i] = ex
            elif tab[i] != ex:
                raise AssertionError(f'{self.name}: twiddle of stage {j} lane {la} round {r} direction {d} depends '
                                     f'on more than beat bits {lo}..{lo + nb - 1}')
        return tab

    def roundTables(self) -> tuple[list, dict]:
        """The twiddle tables: per round, one table per distinct sequence among the butterflies
        ([{'r', 'exps': {d: [...]}, 'users'}], {(j, laneA, r): table index}). A butterfly's twiddle in
        round r comes from its round-r table (a round mux in front of the W port)."""
        if 'rtabs' not in self._qCache:
            tabs, use = [], {}
            for r in range(self.R):
                found = {}                       # per (round, stage): a table serves one stage (one timing)
                for (j, h, a, la, lb) in self.pairs():
                    if self.stageOf(r, j) is None:
                        use[(j, la, r)] = None
                        continue
                    ex = {d: self.roundExponents(r, j, la, d) for d in self.dirs}
                    sig = (j,) + tuple(tuple(ex[d]) for d in self.dirs)
                    if sig not in found:
                        found[sig] = len(tabs)
                        tabs.append({'r': r, 'j': j, 'exps': ex, 'users': 0})
                    use[(j, la, r)] = found[sig]
                    tabs[found[sig]]['users'] += 1
            self._qCache['rtabs'] = (tabs, use)
        return self._qCache['rtabs']

    def roundTable(self, ti: int) -> list[int]:
        """Table ti's stored twiddles, address {MIDX, DIR, entry}: per modulus, per direction, 2^sigBits."""
        key = ('rtab', ti)
        if key not in self._qCache:
            t = self.roundTables()[0][ti]
            ex = t['exps']
            E = self.entryCount(t['r'])
            out = []
            for q in self.moduliList():
                for d in self.tableDirList(ti):
                    blk = [self.stored(self.value(d, e_, q), q) for e_ in ex[d]]
                    out += blk + [blk[0]] * (E - len(blk))       # the shorter direction's block is padded
            self._qCache[key] = out
        return self._qCache[key]

    def wpWidth(self) -> int:
        '''Bits of the Shoup companion stored beside every twiddle (0 without Shoup butterflies).'''
        return self.butterflyUnit().defaultPortBound('WP').bitWidth if self.shoup() else 0

    def roundTableWP(self, ti: int) -> list[int]:
        '''Table ti's Shoup companions, entry for entry beside `roundTable(ti)`.'''
        key = ('rtabwp', ti)
        if key not in self._qCache:
            t = self.roundTables()[0][ti]
            E = self.entryCount(t['r'])
            out = []
            for q in self.moduliList():
                for d in self.tableDirList(ti):
                    blk = [self.companion(self.value(d, e_, q), q) for e_ in t['exps'][d]]
                    out += blk + [blk[0]] * (E - len(blk))
            self._qCache[key] = out
        return self._qCache[key]

    # --- twiddle generators ('rec', 'otf') -------------------------------------------------------

    def generator(self):
        """The one modular multiplier every generator uses (built in propagateBound)."""
        return getattr(self, '_gen', None)

    GEN_LAT_MEMO = True      # False: schedule the generator multiplier on every call (the check of the memo)

    def genLatency(self, pipelineStages=1) -> int:
        """The generator multiplier's latency. Asked thousands of times per core (once per lane and table), and
        each answer schedules the multiplier's datapath, so it is kept on the multiplier object: a new
        multiplier (propagateBound builds one) starts with no answers."""
        g = self.generator()
        if g is None:
            return 0
        if not self.GEN_LAT_MEMO:
            return g.latency(pipelineStages)
        memo = g.__dict__.setdefault('_genLatMemo', {})
        if pipelineStages not in memo:
            memo[pipelineStages] = g.latency(pipelineStages)
        return memo[pipelineStages]

    def _step(self, ti: int, d: str) -> int | None:
        """g0 if table ti's exponents are e0 + i g0 (mod order) over its entries, else None."""
        ex = self.roundTables()[0][ti]['exps'][d]
        od = self.order(d)
        if len(ex) < 2:
            return 0
        g0 = (ex[1] - ex[0]) % od
        return g0 if all((ex[i] - ex[0] - i * g0) % od == 0 for i in range(len(ex))) else None

    def recK(self, ti: int, pipelineStages=1) -> int:
        """Entries a recurrence takes from its base table: v(c) = v(c - D) x g^k, D = k 2^sh >= Lgen + 1."""
        sh = self.CB - self.sigBits(self.roundTables()[0][ti]['r'])
        return min(1 << self.sigBits(self.roundTables()[0][ti]['r']),
                   -(-(self.genLatency(pipelineStages) + 1) // (1 << sh)))

    def tableSource(self, ti: int) -> str:
        return self._srcOf[ti] if getattr(self, '_srcOf', None) else 'rom'

    def _chooseSources(self, pipelineStages=1) -> None:
        """Per table: 'rom', or the generator kind. 'auto': rec where it costs fewer area units than the ROM."""
        tabs = self.roundTables()[0]
        self._srcOf = ['rom'] * len(tabs)
        self._treeBase = {}
        if self.twiddleSource in ('rom', 'stream') or self.unified:
            return                               # unified: the inverse's entries are the low beat bits (ROM only)
        if self.twiddleSource == 'tree':
            # per (round, stage): the first table is read; a table whose exponents differ from it by one
            # constant per direction is that word times a constant
            first = {}
            for ti, t in enumerate(tabs):
                if self.sigBits(t['r']) < max(1, self.genMinBits):
                    continue
                key = (t['r'], t['j'])
                if key not in first:
                    first[key] = ti
                elif self.treeDelta(first[key], ti) is not None:
                    self._srcOf[ti] = 'tree'
                    self._srcOf[first[key]] = 'tbase'
                    self._treeBase[ti] = first[key]
            return
        M, D = len(self.moduliList()), len(self.dirs)
        tw = max(1, (self.qMax() - 1).bit_length())
        g = self.generator()
        lg, dg = g.areaCost()
        ffg = g.flipFlops(pipelineStages)
        genUnits = (lg / 1000 + ffg / 1000 + 4 / 3 * dg) / 5
        for ti, t in enumerate(tabs):
            sb = self.sigBits(t['r'])
            if sb < self.genMinBits:
                continue
            if self.twiddleSource == 'otf':
                self._srcOf[ti] = 'otf'
                continue
            if any(self._step(ti, d) is None for d in self.dirs):
                continue                         # not an arithmetic sequence: stays ROM (not expected for CT)
            if self.twiddleSource == 'rec':
                self._srcOf[ti] = 'rec'
                continue
            c = ramCost((1 << sb) * M * D, tw, self.twiddleStyle)
            romUnits = (c['lut'] / 1000 + c['ff'] / 1000 + c['bram'] + 8 * c['uram']) / 5
            k = self.recK(ti, pipelineStages)
            c2 = ramCost((k + 1) * M * D, tw, 'auto')
            recUnits = genUnits + (c2['lut'] / 1000 + c2['ff'] / 1000 + c2['bram'] + 8 * c2['uram']) / 5 \
                + tw * (self.genLatency(pipelineStages) + 2) / 5000
            if recUnits < romUnits:
                self._srcOf[ti] = 'rec'

    def treeDelta(self, tb: int, ti: int) -> dict | None:
        '''{d: a} when table ti's exponents are table tb's plus a (mod the order) at every entry, else None.'''
        A, B = self.roundTables()[0][tb]['exps'], self.roundTables()[0][ti]['exps']
        out = {}
        for d in self.dirs:
            od = self.order(d)
            if len(A[d]) != len(B[d]) or any((B[d][i] - A[d][i] - B[d][0] + A[d][0]) % od for i in range(len(A[d]))):
                return None
            out[d] = (B[d][0] - A[d][0]) % od
        return out

    def treeTable(self, ti: int) -> list[int]:
        ''''tree' table ti's constants, one per modulus and direction (the generator's B domain).'''
        dl = self.treeDelta(self._treeBase[ti], ti)
        return [self.value(d, dl[d], q) * self.genFactor(q) % q for q in self.moduliList() for d in self.dirs]

    def genFactor(self, q: int) -> int:
        """B operands are stored times this (the inverse of the multiplier's reduction factor)."""
        return pow(self.generator().reductionFactor(q if self.runtime else None), -1, q)

    def recTables(self, ti: int, pipelineStages=1) -> tuple[list[int], list[int]]:
        """'rec' table ti: base (k stored words per modulus and direction) and update (one word per modulus and
        direction, w^(k g0) in the B domain)."""
        k = self.recK(ti, pipelineStages)
        ex = self.roundTables()[0][ti]['exps']
        base, upd = [], []
        for q in self.moduliList():
            fi = self.genFactor(q)
            for d in self.dirs:
                base += [self.stored(self.value(d, e_, q), q) for e_ in ex[d][:k]]
                base += [0] * (k - len(ex[d][:k]))
                upd.append(self.value(d, k * self._step(ti, d), q) * fi % q)
        return base, upd

    def otfBits(self, ti: int) -> int:
        """Low entry bits of an 'otf' table (the rest are high)."""
        return self.sigBits(self.roundTables()[0][ti]['r']) // 2

    def otfTables(self, ti: int) -> tuple[list[int], list[int]]:
        """'otf' table ti: lo[i_lo] = stored(w^e(i_lo)), hi[i_hi] = w^(e(i_hi << h) - e(0)) in the B domain, per
        modulus and direction (e affine in the entry bits)."""
        sb = self.sigBits(self.roundTables()[0][ti]['r'])
        h = self.otfBits(ti)
        ex = self.roundTables()[0][ti]['exps']
        lo, hi = [], []
        for q in self.moduliList():
            fi = self.genFactor(q)
            for d in self.dirs:
                e = ex[d]
                od = self.order(d)
                for i in range(1 << sb):
                    if (e[i] - e[i & ((1 << h) - 1)] - e[i & ~((1 << h) - 1)] + e[0]) % od:
                        raise AssertionError(f'{self.name}: table {ti} is not affine in its entry bits')
                lo += [self.stored(self.value(d, e[i], q), q) for i in range(1 << h)]
                hi += [self.value(d, (e[i << h] - e[0]) % od, q) * fi % q for i in range(1 << (sb - h))]
        return lo, hi

    def _chooseTwist(self, pipelineStages=1) -> None:
        """'auto': the recurrence per lane when one generator plus its small tables cost fewer area units than the
        lane's table (T words per modulus and direction)."""
        self.twistSrc = 'tab'
        if not self.twistOn or self.twistSourceReq == 'tab':
            return
        if self.twistSourceReq == 'rec':
            self.twistSrc = 'rec'
            return
        M, D = len(self.moduliList()), len(self.dirs)
        tw = max(1, (self.qMax() - 1).bit_length())
        g = self.generator()
        lg, dg = g.areaCost()
        genUnits = (lg / 1000 + g.flipFlops(pipelineStages) / 1000 + 4 / 3 * dg) / 5
        c = ramCost(self.T * D * M, tw, self.twiddleStyle)
        tabUnits = (c['lut'] / 1000 + c['ff'] / 1000 + c['bram'] + 8 * c['uram']) / 5
        c2 = ramCost((self.genLatency(pipelineStages) + 1) * D * M, tw, 'auto')
        recUnits = genUnits + (c2['lut'] / 1000 + c2['ff'] / 1000 + c2['bram'] + 8 * c2['uram']) / 5
        if recUnits < tabUnits:
            self.twistSrc = 'rec'

    def twistRecD(self, pipelineStages=1) -> int:
        return min(self.T, self.genLatency(pipelineStages) + 1)

    def twistRecTables(self, lane: int, pipelineStages=1) -> tuple[list[int], list[int]]:
        """Lane `lane`'s twist recurrence: base (the first D operands per modulus and direction) and the update
        words (per modulus and direction, the same for every lane): the output's memory index grows by g per
        beat, so the operand of beat c is that of beat c - D times psi^(-g D) (inverse) or 1 (forward)."""
        Dr = self.twistRecD(pipelineStages)
        base, upd = [], []
        for q in self.moduliList():
            t = self.twistTable(lane, q)
            fi = self.genFactor(q)
            for di, d in enumerate(self.dirs):
                base += t[di * self.T: di * self.T + Dr]
                if d == 'inv':
                    upd.append(self.value('twist', (self.g * Dr) % (2 * self.n), q) * fi % q
                               if self.negacyclic else fi % q)
                else:
                    upd.append(fi % q)
        return base, upd

    def checkGenerators(self, pipelineStages=1) -> list[str]:
        """Every generated twiddle equals the table's: the recurrence and the two-table product run through the
        generator multiplier's own datapath (bit exact), per modulus and direction; the same for the twist."""
        errs = []
        g = self.generator()
        if g is None:
            return errs
        if self.twistSrc == 'rec':
            Dr = self.twistRecD(pipelineStages)
            for l in (0, self.W - 1, self.W // 2 + 1 if self.W > 2 else 0):
                base, upd = self.twistRecTables(l, pipelineStages)
                for mi, q in enumerate(self.moduliList()):
                    qv = {pn: [g.qPortValues(q)[pn]] for pn in g.qPorts()} if self.runtime else {}
                    want = self.twistTable(l, q)
                    for di in range(len(self.dirs)):
                        got = []
                        for c in range(self.T):
                            if c < Dr:
                                got.append(base[(mi * len(self.dirs) + di) * Dr + c])
                            else:
                                ins = {'A': [got[c - Dr]], 'B': [upd[mi * len(self.dirs) + di]]}
                                ins.update(qv)
                                got.append(g.datapath().run(ins)['P'][0])
                        if got != want[di * self.T:(di + 1) * self.T]:
                            errs.append(f'twist lane {l} modulus {mi} dir {di}: generated operands differ')
                            break
        M, D = len(self.moduliList()), len(self.dirs)
        for ti, t in enumerate(self.roundTables()[0]):
            src = self.tableSource(ti)
            if src in ('rom', 'tbase'):
                continue
            want = self.roundTable(ti)
            sb = self.sigBits(t['r'])
            E = 1 << sb
            for mi, q in enumerate(self.moduliList()):
                qv = {pn: [g.qPortValues(q)[pn]] for pn in g.qPorts()} if self.runtime else {}
                for di in range(D):
                    off = (mi * D + di) * E
                    if src == 'otf':
                        lo, hi = self.otfTables(ti)
                        h = self.otfBits(ti)
                        nl, nh = 1 << h, 1 << (sb - h)
                        A = [lo[(mi * D + di) * nl + (i & (nl - 1))] for i in range(E)]
                        B = [hi[(mi * D + di) * nh + (i >> h)] for i in range(E)]
                        ins = {'A': A, 'B': B}
                        ins.update({pn: v * E for pn, v in qv.items()})
                        got = g.datapath().run(ins)['P']
                    elif src == 'tree':
                        ins = {'A': self.roundTable(self._treeBase[ti])[off:off + E],
                               'B': [self.treeTable(ti)[mi * D + di]] * E}
                        ins.update({pn: v * E for pn, v in qv.items()})
                        got = g.datapath().run(ins)['P']
                    else:
                        base, upd = self.recTables(ti, pipelineStages)
                        k = self.recK(ti, pipelineStages)
                        got = []
                        for i in range(E):
                            if i < k:
                                got.append(base[(mi * D + di) * k + i])
                            else:
                                ins = {'A': [got[i - k]], 'B': [upd[mi * D + di]]}
                                ins.update(qv)
                                got.append(g.datapath().run(ins)['P'][0])
                    if got != want[off:off + E]:
                        errs.append(f'table {ti} ({src}) modulus {mi} dir {di}: generated twiddles differ')
                        break
        return errs

    def twistTable(self, lane: int, q: int) -> list[int]:
        '''Output lane `lane`'s twist operand per output beat and direction (the multiplier's domain):
        forward 1, inverse n^-1 psi^-k (k = the output's memory index).'''
        tm = self.twistMultiplier
        fi = pow(tm.reductionFactor(q if self.runtime else None), -1, q)
        nInv = pow(self.n, -1, q)
        out = []
        for d in self.dirs:
            for c in range(self.T):
                k = _rotr(c * self.W + lane, self.U, self.L)
                if d == 'inv':
                    e_ = k % (2 * self.n) if self.negacyclic else 0
                    out.append(nInv * self.value('twist', e_, q) * fi % q)
                else:
                    out.append(fi % q)
        return out

    def twiddleWords(self) -> int:
        M, D = len(self.moduliList()), len(self.dirs)
        w = sum(self.entryCount(t['r']) for t in self.roundTables()[0]) * M * D
        if self.twistOn:
            w += self.n * D * M          # the twist's operands (stored or generated)
        return w

    def storedTwiddleWords(self) -> int:
        '''Words actually stored (generators keep only their small tables).'''
        return sum(m['count'] * m['depth'] for m in self.memories() if m['what'].startswith(('twiddle', 'twist')))

    # --- the value path ------------------------------------------------------------------

    def transform(self, frames, direction=None, q=None) -> list[list[int]]:
        '''Bit-exact outputs (memory order) for frames (memory order), as the block computes them:
        round by round, stage by stage, each frame with its own direction and modulus (lists).'''
        F = len(frames)
        d0 = 'inv' if self.direction == 'inverse' else 'fwd'
        ds = list(direction) if isinstance(direction, (list, tuple)) else [direction or d0] * F
        qs = list(q) if isinstance(q, (list, tuple)) else [q or self.refQ()] * F
        for d in ds:
            if d not in self.dirs:
                raise ValueError(f'{self.name}: direction {d!r} not built')
        for x in qs:
            if x not in self.moduliList():
                raise ValueError(f'{self.name}: modulus {x} not in the design')
        n, W, T, U, L = self.n, self.W, self.T, self.U, self.L
        bu = self.butterflyUnit()
        pr = self.pairs()
        use = self.roundTables()[1]
        # each consumer's own modulus-port values (a Barrett MU depends on the operand range)
        qv = [dict(bu.qPortValues(x)) if self.runtime else {} for x in qs]
        # positions of round 0
        vals = [[fr[self.index(0, p)] for p in range(n)] for fr in frames]
        tabs = {}
        for f in range(F):
            mi, di = self.midx(qs[f]), self.dirs.index(ds[f])
            tabs[(mi, di)] = None
        D = len(self.dirs)
        for r in range(self.R):
            sb = self.sigBits(r)
            sh = self.CB - sb
            for j in range(U):
                s = self.stageOf(r, j)
                if s is None:
                    continue
                A, B, Wt, WPt, where = [], [], [], [], []
                swl = []                         # shared inverse twiddles: the pairs whose outputs swap
                shoup = 'WP' in bu.portNames()
                ports = {pn: [] for pn in bu.portNames() if pn not in ('W', 'WP')}
                for (jj, h, a, la, lb) in pr:
                    if jj != j:
                        continue
                    ct = self.roundTable(use[(j, la, r)])
                    cp = self.roundTableWP(use[(j, la, r)]) if shoup else None
                    E = self.entryCount(r)
                    for f in range(F):
                        off = (self.midx(qs[f]) * D + self.dirs.index(ds[f])) * E
                        ctf, cpf, amp, sgn = ct, cp, None, None
                        if self.shareInv:
                            ctf, cpf, off, amp, sgn = self._sharedRead(use[(j, la, r)], ds[f], self.midx(qs[f]), shoup)
                        for c in range(T):
                            pa, pb = c * W + la, c * W + lb
                            A.append(vals[f][pa]); B.append(vals[f][pb])
                            en = self.entryOf(r, ds[f], c)
                            if amp:
                                if self.shareSign(sgn, en):
                                    swl.append(len(where))
                                en = self.shareAddress(amp, en, E)
                            Wt.append(ctf[off + en])
                            if shoup:
                                WPt.append(cpf[off + en])
                            where.append((f, pa, pb))
                            for pn in ports:
                                ports[pn].append((1 if ds[f] == 'inv' else 0) if pn == 'DIR' else qv[f][pn])
                bu.aInValues, bu.bInValues = A, B
                pv = {'W': Wt}
                if shoup:
                    pv['WP'] = WPt
                pv.update(ports)
                bu.portValues = pv
                X, Y = bu.propagateValue()
                if swl:
                    X, Y = list(X), list(Y)
                    for k_ in swl:
                        X[k_], Y[k_] = Y[k_], X[k_]
                for (f, pa, pb), x, y in zip(where, X, Y):
                    if self.stageHalve and ds[f] == 'inv':
                        hq = (qs[f] + 1) // 2
                        x, y = self.halve(x, hq), self.halve(y, hq)
                    vals[f][pa], vals[f][pb] = x, y
            if r < self.R - 1:
                vals = [[v[_rotl(p, U, L)] for p in range(n)] for v in vals]
        out = [[v[self.outputPosition(k)] for k in range(n)] for v in vals]
        if self.twistMultiplier is not None:
            tm = self.twistMultiplier
            res = []
            for f in range(F):
                di = self.dirs.index(ds[f])
                tw = [0] * n
                for l in range(W):
                    tl = self.twistTable(l, qs[f])
                    for c in range(T):
                        tw[_rotr(c * W + l, U, L)] = tl[di * T + c]
                ins = {'A': out[f], 'B': tw}
                ins.update({pn: [tm.qPortValues(qs[f])[pn]] * n for pn in tm.qPorts()})
                res.append(tm.datapath().run(ins)['P'])
            out = res
        return out

    # --- timing: pipeline offsets ----------------------------------------------------------

    def buLatency(self, pipelineStages=1) -> int:
        return self.butterflyUnit().latency(pipelineStages)

    def rotLatency(self) -> int:
        '''Registers in a barrel rotator of 2^U words: one per two mux levels (a 4:1 per LUT6).'''
        return -(-self.U // 2)

    def stageLatency(self, pipelineStages=1) -> int:
        '''A block stage: the butterfly and its output register (bypass mux / halver merged into it).'''
        return self.buLatency(pipelineStages) + 1

    def inOffset(self) -> int:
        '''Issue cycle t -> block input register: address register, RL RAM cycles, source mux register,
        the read rotator, the block input register.'''
        return 3 + self.RL + self.rotLatency() + self.lead() + self.fanShift()

    def lead(self, pipelineStages=1) -> int:
        '''Extra registers in front of the block so a generated twiddle of stage 0 can be computed from the issue's
        tag (address, ROM, generator multiplier, output register, fan-out register).'''
        if self.generator() is None or not any(x != 'rom' for x in (getattr(self, '_srcOf', None) or [])):
            return self.XR
        return max(0, self.genLatency(pipelineStages) + 2 - self.rotLatency()) + self.XR

    def blockOutOffset(self, pipelineStages=1) -> int:
        return self.inOffset() + self.U * self.stageLatency(pipelineStages)

    def writeOffset(self, pipelineStages=1) -> int:
        '''Issue cycle t -> the cycle the RAM write registers (we, wa, wd) hold its words: the block,
        the write rotator, the write register. A read issued at t' >= that cycle sees them.'''
        return self.blockOutOffset(pipelineStages) + self.rotLatency() + 1 + self.XR

    def twistLatency(self, pipelineStages=1) -> int:
        return self.twistMultiplier.latency(pipelineStages) if self.twistMultiplier is not None else 0

    def outOffset(self, pipelineStages=1) -> int:
        '''Issue cycle t (last round) -> out_valid: block, (twist multiplier,) output register.'''
        return self.blockOutOffset(pipelineStages) + self.twistLatency(pipelineStages) + 1

    def slotLength(self, S: int | None = None, pipelineStages=1) -> int:
        S = S or self.S
        T, U = self.T, self.U
        need = self.writeOffset(pipelineStages) + T - (T >> U)
        return max(T, -(-need // S))

    def roundOffsets(self) -> list[int]:
        '''Context x runs round ((k div S) + offset_x) mod R in slot k: the contexts' round-0 slots are
        spread over the R S slots of a period (not bunched), so the input FIFO needs room for about one
        polynomial.'''
        return [(x * self.R) // self.S for x in range(self.S)]

    def inDepth(self) -> int:
        '''Input FIFO depth in beats: T, or 2T when two round-0 slots can come closer than a fill
        (S >= 2 with R < 3 S... decided by the twin at construction, `_inDepth`).'''
        return getattr(self, '_inDepth', None) or self.T

    def _chooseInDepth(self, pipelineStages=1) -> None:
        self._inDepth = self.T
        if self.S > 1:
            job = self.simulateJob(4 * self.S, pipelineStages=pipelineStages)
            if job['interval'] > self.R * self.slotLength(self.S, pipelineStages) * 1.02:
                self._inDepth = 2 * self.T
        if self.io < self.W and self._inDepth == self.T:
            # narrower ports fill the FIFO slowly: with room for one polynomial the input would stand still
            # while a full FIFO waits for its slot, so a second polynomial's room (double buffering)
            st = [o[0] for o in self.simulateIoJob(24, pipelineStages=pipelineStages)['out']]
            if (st[-1] - st[8]) / 15 > self.cyclesPerPolynomial(pipelineStages) * 1.02:
                self._inDepth = 2 * self.T

    def slotReport(self, pipelineStages=1) -> dict:
        '''slots='auto': S = 1 unless its bubble costs more than 5 % of the rate, then the smallest S
        that removes it (each extra slot: n words more memory, latency S x per round).'''
        rep = {}
        for S in (1, 2, 3, 4):
            D = self.slotLength(S, pipelineStages)
            rep[S] = {'slot': D, 'interval': self.R * D, 'bubble': D - self.T}
        best = 1
        if rep[1]['slot'] > 1.05 * self.T:
            best = next((S for S in (2, 3, 4) if rep[S]['slot'] == self.T), 4)
        rep['choice'] = best
        return rep

    # --- the controller twin -----------------------------------------------------------------

    def simulateJob(self, polys: int, valid=None, pipelineStages=1, maxCycles: int | None = None) -> dict:
        '''Cycle model of the RTL controller: input beats accepted (in_valid and in_ready), slots,
        issues, outputs. Returns {'accept': cycle per input beat, 'issue': per polynomial per round the
        issue start, 'out': per polynomial the out_valid cycle of each beat, 'latency', 'interval',
        'jobCycles', 'ctx': per polynomial its context, 'slotk': per polynomial the slot of round 0}.'''
        valid = valid or (lambda c: True)
        T, R, S = self.T, self.R, self.S
        Dl = self.slotLength(S, pipelineStages)
        OO = self.outOffset(pipelineStages)
        maxCycles = maxCycles or (polys + 4) * (T + R * S * Dl) * 3 + 1000
        nb = polys * T
        acc, count, rcount = [], 0, 0      # beats accepted, beats in the FIFO
        running, k, cc = False, 0, 0
        x_, kd = 0, 0
        off = self.roundOffsets()
        ID = self.inDepth()
        active = [None] * S                # polynomial index in each context
        nextPoly = 0
        issue = [[None] * R for _ in range(polys)]
        out = [[None] * T for _ in range(polys)]
        ctx, slotk = [None] * polys, [None] * polys
        pendingDec = 0
        FRd = self.fanShift(pipelineStages)
        freed = []                         # fan-out trees: cycles of the round-0 issues not yet seen by in_ready
        c = 0
        while c < maxCycles:
            # count register at cycle c: beats accepted before c, minus reads issued before c
            count += pendingDec
            pendingDec = 0
            startNow = False
            if not running and count >= T:
                running, k, cc, x_, kd = True, 0, 0, 0, 0
                startNow = True
            r_ = (kd + off[x_]) % R
            if running and cc == 0:
                if r_ == 0:
                    if count >= T and nextPoly < polys:
                        active[x_] = nextPoly
                        ctx[nextPoly], slotk[nextPoly] = x_, k
                        nextPoly += 1
                    else:
                        active[x_] = None
                    if all(a is None for a in active):
                        running = False
                        # the same cycle may restart only through the idle branch on the next cycle
            if running:
                p = active[x_]
                if p is not None and cc < T:
                    if cc == 0:
                        issue[p][r_] = c
                    if r_ == R - 1:
                        out[p][cc] = c + OO
                    if r_ == 0:
                        rcount += 1
                        pendingDec -= 1
                        if FRd:
                            freed.append(c)
                cc += 1
                if cc == Dl:
                    cc = 0
                    k += 1
                    x_ += 1
                    if x_ == S:
                        x_ = 0
                        kd += 1
            # the input: in_ready = count < the FIFO depth (count register), accept on valid
            inReady = count < ID
            if FRd:
                # countw: the count whose reads leave fanShift cycles later (the beat is read that much later)
                freed = [x for x in freed if x >= c - FRd]
                inReady = count + sum(1 for x in freed if x < c) < ID
            if len(acc) < nb and inReady and valid(c):
                acc.append(c)
                pendingDec += 1
            if all(o[-1] is not None for o in out):
                break
            c += 1
        else:
            raise AssertionError(f'{self.name}: the job did not finish in {maxCycles} cycles')
        lat = out[0][-1] - acc[0] + 1
        starts = [o[0] for o in out]
        # steady state: the mean output-start spacing (contexts leave in bunches of S)
        iv = (starts[-1] - starts[0]) / (polys - 1) if polys >= 2 else None
        return {'accept': acc, 'issue': issue, 'out': out, 'latency': lat, 'interval': iv,
                'jobCycles': out[-1][-1] - acc[0] + 1, 'ctx': ctx, 'slotk': slotk, 'slot': Dl}

    def checkHazards(self, job: dict, pipelineStages=1) -> list[str]:
        '''On a simulated job: every round's read of a position comes at or after the cycle its write
        registers hold it, and a buffer is rewritten only after its last read; the FIFO beat a round 0
        reads was written before.'''
        errs = []
        T, R, S, W = self.T, self.R, self.S, self.W
        Dw = self.writeOffset(pipelineStages)
        for p, iss in enumerate(job['issue']):
            for r in range(1, R):
                for cp in range(T):
                    for l in (0, W - 1, W // 2 + 1 if W > 2 else 0):
                        oc, _ = self.readSource(cp, l)
                        wr = iss[r - 1] + oc + Dw
                        rd = iss[r] + cp
                        if rd < wr:
                            errs.append(f'poly {p} round {r} beat {cp}: read at {rd}, written at {wr}')
                            return errs
            # FIFO: beat b accepted at a -> we at a+1; read address at issue+1
            for b in range(T):
                a = job['accept'][p * T + b]
                if iss[0] + b + 1 <= a + 1:
                    errs.append(f'poly {p} beat {b}: FIFO read before its write')
                    return errs
                # the beat that takes this FIFO word's place is written (accept + 1) after the word's read
                # (the read address is valid at issue + 1 + fanShift)
                nx = p * T + b + self.inDepth()
                if nx < len(job['accept']) and job['accept'][nx] + 1 <= iss[0] + b + 1 + self.fanShift(pipelineStages):
                    errs.append(f'poly {p} beat {b}: FIFO word overwritten before its read')
                    return errs
        # buffer reuse: slot k writes buffer k mod (S+1); the slot that next writes it starts after the
        # reader of the previous content (slot k+S) has issued its last read
        ks = sorted((job['slotk'][p] + r * S, job['issue'][p][r]) for p in range(len(job['issue'])) for r in range(R))
        last = {}
        for kk, st in ks:
            b = kk % (S + 1)
            if b in last:
                pk, pst = last[b]
                # previous writer slot pk; its reader is slot pk + S (if any), reading until its start + T
                rdEnd = next((s2 + T for k2, s2 in ks if k2 == pk + S), None)
                if rdEnd is not None and st + Dw <= rdEnd + 1 and kk > pk + S:
                    errs.append(f'slot {kk} rewrites buffer {b} at {st + Dw}, read until {rdEnd}')
                    return errs
            last[b] = (kk, st)
        return errs

    # --- ports of another width (ioLanes != W): the twin of the wrapper around the core -------------

    OUT_BUFFER_POLYS = 2

    def simulateIoJob(self, polys: int, valid=None, pipelineStages=1) -> dict:
        '''Cycle model of the port adapters around the core (rtl_gen.hybrid_ntt._io_wrapper) and the core's
        controller. Returns as simulateJob, for the port beats: 'accept', 'out' (n / ioLanes beats per
        polynomial), 'latency', 'interval', 'jobCycles'; 'core': the core's job (for checkHazards);
        'peak': the most core beats the output buffer held (narrower ports).'''
        import bisect
        valid = valid or (lambda c: True)
        W, T, io = self.W, self.T, self.io
        NB = self.n // io                      # port beats per polynomial
        total = polys * NB
        oacc = []
        st = {'c': -1, 'full': False, 'cnt': 0}

        def step(c: int, ready: bool) -> bool:
            # one cycle of the input adapter; returns the core's in_valid of this cycle
            kv = st['full']
            kacc = kv and ready
            if io < W:
                rho = W // io
                acc = len(oacc) < total and valid(c) and (not st['full'] or ready)
                if kacc:
                    st['full'] = False
                if acc:
                    oacc.append(c)
                    st['cnt'] += 1
                    if st['cnt'] == rho:
                        st['cnt'], st['full'] = 0, True
            else:
                rho = io // W
                last = st['cnt'] == rho - 1
                acc = len(oacc) < total and valid(c) and (not st['full'] or (kacc and last))
                if kacc:
                    st['cnt'] = (st['cnt'] + 1) % rho
                    if last:
                        st['full'] = False
                if acc:
                    oacc.append(c)
                    st['full'] = True
            return kv

        def kvalid(c: int) -> bool:
            # the core's twin asks only in the cycles its in_ready is high
            for cc in range(st['c'] + 1, c):
                step(cc, False)
            st['c'] = c
            return step(c, True)

        core = self.simulateJob(polys, kvalid, pipelineStages,
                                maxCycles=(polys + 4) * (T + self.R * self.S * self.slotLength(self.S, pipelineStages)
                                                         + self.n // min(io, W)) * 3 + 1000)
        flat = [c for o in core['out'] for c in o]
        outs, peak = [], 0
        if io < W:
            rho = W // io
            issue = -rho
            for i, t in enumerate(flat):
                # core beat at t: in the buffer from t + 1; read when the reader is free; port beats from +2
                issue = max(issue + rho, t + 1)
                peak = max(peak, bisect.bisect_right(flat, issue - 1) - i)
                outs += [issue + 2 + k for k in range(rho)]
            cap = self.OUT_BUFFER_POLYS * T
            if peak > cap:
                raise AssertionError(f'{self.name}: the output buffer ({cap} core beats) would hold {peak}')
        else:
            rho = io // W
            outs = [t + 1 for i, t in enumerate(flat) if i % rho == rho - 1]
        out = [outs[p * NB:(p + 1) * NB] for p in range(polys)]
        starts = [o[0] for o in out]
        return {'accept': oacc, 'out': out, 'latency': out[0][-1] - oacc[0] + 1,
                'interval': (starts[-1] - starts[0]) / (polys - 1) if polys >= 2 else None,
                'jobCycles': out[-1][-1] - oacc[0] + 1, 'core': core, 'peak': peak}

    def latency(self, pipelineStages=1) -> int:
        if self.portsOn():
            return self.simulatePortsJob(1, pipelineStages=pipelineStages)['latency']
        if self.io != self.W:
            return self.simulateIoJob(1, pipelineStages=pipelineStages)['latency']
        return self.simulateJob(1, pipelineStages=pipelineStages)['latency']

    def cyclesPerPolynomial(self, pipelineStages=1) -> int:
        return max(self.R * self.slotLength(self.S, pipelineStages), self.n // self.io)

    # --- resources -----------------------------------------------------------------------------

    def memories(self) -> list[dict]:
        Wd = self.memBound.bitWidth
        tw = max(1, (self.qMax() - 1).bit_length())
        M, D = len(self.moduliList()), len(self.dirs)
        out = [dict(what='data bank (pool of S+1 buffers)', count=self.W, depth=(self.S + 1) * self.T, width=Wd,
                    style=self.memStyle),
               dict(what='input FIFO bank', count=self.W, depth=self.inDepth(), width=Wd, style=self.memStyle)]
        if self.portsOn():
            out += self._portsMemories()
        elif self.io < self.W:
            out.append(dict(what='output buffer (ports narrower than the core)', count=self.W,
                            depth=self.OUT_BUFFER_POLYS * self.T, width=self.outputBound.bitWidth,
                            style=self.memStyle))
        shapes = {}
        for ti, t in enumerate(self.roundTables()[0]):
            sb = self.sigBits(t['r'])
            src = self.tableSource(ti)
            if src in ('rom', 'tbase'):
                deps = [] if self.twiddleSource == 'stream' else [self.entryCount(t['r']) * self.tableDirs(ti) * M]
            elif src == 'tree':
                deps = [D * M]
            elif src == 'rec':
                deps = [self.recK(ti) * D * M, D * M]
            else:
                h = self.otfBits(ti)
                deps = [(1 << h) * D * M, (1 << (sb - h)) * D * M]
            for dep in deps:
                if dep > 1:                          # depth 1: a constant
                    key = (src, dep)
                    shapes[key] = shapes.get(key, 0) + 1
        for (src, dep), cnt in sorted(shapes.items()):
            sty = self.twiddleStyle if src == 'rom' else 'auto'
            out.append(dict(what=f'twiddle {src} table {dep} deep', count=cnt, depth=dep,
                            width=tw + (self.wpWidth() if src == 'rom' else 0), style=sty))
        if self.twistOn and self.twistSrc == 'rec':
            out.append(dict(what='twist rec base table', count=self.W, depth=self.twistRecD() * D * M, width=tw,
                            style='auto'))
            if D * M > 1:
                out.append(dict(what='twist rec update table', count=1, depth=D * M, width=tw, style='auto'))
        elif self.twistOn:
            out.append(dict(what='twist ROM', count=self.W, depth=self.T * D * M, width=tw, style=self.twiddleStyle))
        for x in out:
            x['cost'] = ramCost(x['depth'], x['width'], x['style'])
            x['style'] = x['cost']['style']
        return out

    def generatorCount(self) -> int:
        '''Generator multipliers: one per generated table, plus one per output lane with the twist recurrence.'''
        return sum(1 for ti in range(len(self.roundTables()[0])) if self.tableSource(ti) not in ('rom', 'tbase')) + \
            (self.W if self.twistOn and self.twistSrc == 'rec' else 0)

    def butterflyCount(self) -> int:
        return self.g * self.U * (1 << (self.U - 1))

    def resources(self, pipelineStages=1) -> dict:
        '''The model's estimate {'lut', 'ff', 'dsp', 'bram', 'uram'} and a breakdown, from the inventory of what the
        emitter writes (HybridArea: one line per part, with the measured synthesis rules). 'parts' is that list.'''
        from operator_modeling.ntt.hybrid import HybridArea
        parts = HybridArea.allParts(self, pipelineStages)
        out = HybridArea.totals(parts)
        out['breakdown'] = HybridArea.breakdown(parts)
        out['parts'] = parts
        return out

    def resourcesRough(self, pipelineStages=1) -> dict:
        '''The estimate used until 2026-11-13 (kept for the before / after table of the accuracy gate). The
        component numbers are the component models' estimates of that date (`resourcesEstimate`,
        `flipFlopsEstimate`), so this stays the model before the night of 2026-11-14.'''
        def before(x):
            inner = x.inner() if hasattr(x, 'inner') else x
            dp, sch = inner.datapath(), inner.schedule(pipelineStages)
            r = dp.resourcesEstimate(sch)
            return r.lut, r.dsp, dp.flipFlopsEstimate(sch)
        bu = self.butterflyUnit()
        NB = self.butterflyCount()
        Wd = self.memBound.bitWidth
        W, U = self.W, self.U
        lb, db, ffb = before(bu)
        brk = {'butterflies': (NB, NB * lb, NB * db)}
        lut, ff, dsp = NB * lb, NB * ffb, NB * db
        # rotators: write and read, 2^U-word barrel per group: U mux2 levels, a LUT6 does two
        rot = 2 * W * Wd * (-(-U // 2))
        src = W * Wd                              # source mux (FIFO or pool) before the read rotator
        byp = self.e * W * Wd                      # bypass muxes of round 0's skipped stages
        halve = NB * 2 * Wd if self.stageHalve else 0
        brk.update({'rotators': rot, 'source mux': src, 'bypass': byp, 'halvers': halve})
        lut += rot + src + byp + halve
        # registers: stage outputs (counted in the butterflies' output register: +2 Wd per butterfly),
        # rotator levels, source mux, write registers, output register
        ffreg = NB * 2 * Wd + 2 * W * Wd * self.rotLatency() + W * Wd * 3
        # bypass delay lines: SRLs (LUT) of the butterfly latency per bypassed stage
        if self.e:
            lut += self.e * W * Wd // 2
        tw = max(1, (self.qMax() - 1).bit_length())
        ntab = len(self.roundTables()[0])
        rmux = NB * tw * (-(-max(0, self.R - 1) // 3)) if self.R > 1 else 0   # round mux per butterfly W port
        lut += rmux
        brk['round mux'] = rmux
        if self.shareInv:
            sw, xs = self.inverseShareCost()
            lut += 2 * Wd * sw + tw * xs
            brk['shared inverse'] = dict(tables=len(self.inverseShare()), swapButterflies=sw, secondSources=xs,
                                         lut=2 * Wd * sw + tw * xs)
        ffreg += ntab * tw * 2 + NB * tw          # ROM output / fan-out registers, the W port register
        ff += ffreg
        brk['registers'] = ffreg
        ng = self.generatorCount()
        if ng:
            g = self.generator()
            a, d_, gf = before(g)
            lut += a * ng
            dsp += d_ * ng
            ff += ng * (gf + tw * 3)
            brk['twiddle generators'] = (ng, a * ng, d_ * ng)
            # 'tree': the read table's word waits for the derived ones (generator latency + 1 registers)
            ff += sum(1 for x in self._srcOf if x == 'tbase') * tw * (g.latency(pipelineStages) + 1)
        if self.lead():
            ff += W * Wd * self.lead()               # (SRL in practice, registers for crossRegs)
        ff += self.XR * W * (Wd + 2)                 # the write path's crossing registers
        if self.fanout:
            fr = self.fanoutRegisters(pipelineStages)
            ff += fr
            brk['fan-out trees'] = dict(ff=fr, shift=self.fanShift(pipelineStages),
                                        depths={k: len(v['levels']) for k, v in self.fanoutPlan(pipelineStages).items()})
        if self.twistMultiplier is not None:
            a, d_, tf_ = before(self.twistMultiplier)
            lut += a * W
            dsp += d_ * W
            ff += W * tf_
            brk['twist'] = (a * W, d_ * W)
        lut += 400 + 60 * self.R                  # controller, counters, tag pipeline (rough)
        ff += 300
        if self.portsOn():
            pr = self._portsResources(pipelineStages)
            lut += pr['lut']
            ff += pr['ff']
            brk['port wrapper'] = pr['what']
        elif self.io != self.W:
            # port adapters: the gathering / holding register of the input, the output register and its mux
            wide, OWd = max(self.io, W), self.outputBound.bitWidth
            rho = wide // min(self.io, W)
            ff += wide * Wd + self.io * OWd
            lut += min(self.io, W) * (OWd if self.io < W else Wd) * (-(-(rho - 1) // 3))
            brk['port adapters'] = (self.io, rho)
        bram = uram = 0
        for mm in self.memories():
            c = mm['cost']
            lut += c['lut'] * mm['count']
            ff += c['ff'] * mm['count']
            bram += c['bram'] * mm['count']
            uram += c['uram'] * mm['count']
            brk[mm['what']] = (mm['count'], mm['depth'], mm['width'], mm['style'])
        return {'lut': int(lut), 'ff': int(ff), 'dsp': dsp, 'bram': bram, 'uram': uram, 'breakdown': brk}

    def areaUnits(self, pipelineStages=1) -> float:
        '''The comparison's area: (kLUT + kFF + 4/3 DSP + BRAM36 + 8 URAM) / 5 (V80 DSP58 weight 4/3).'''
        r = self.resources(pipelineStages)
        return (r['lut'] / 1000 + r['ff'] / 1000 + 4 / 3 * r['dsp'] + r['bram'] + 8 * r['uram']) / 5

    def areaCost(self) -> tuple[int, int]:
        r = self.resources()
        return r['lut'], r['dsp']

    def criticalPathNs(self, pipelineStages=1) -> float:
        ns = [self.butterflyUnit().criticalPathNs(pipelineStages)]
        if self.twistMultiplier is not None:
            ns.append(self.twistMultiplier.criticalPathNs(pipelineStages))
        return max(ns)

    def report(self, pipelineStages=1, mhz: float = 350.0) -> dict:
        r = self.resources(pipelineStages)
        lat = self.latency(pipelineStages)
        iv = self.cyclesPerPolynomial(pipelineStages)
        au = self.areaUnits(pipelineStages)
        return {'n': self.n, 'U': self.U, 'g': self.g, 'W': self.W, 'R': self.R, 'e': self.e, 'S': self.S,
                'butterflies': self.butterflyCount(), 'slot': self.slotLength(), 'interval': iv, 'latency': lat,
                'lut': r['lut'], 'ff': r['ff'], 'dsp': r['dsp'], 'bram': r['bram'], 'uram': r['uram'],
                'area': au, 'latency_us': lat / mhz, 'ntt_per_s': mhz * 1e6 / iv, 'atp': au * lat / mhz,
                'tpa': mhz * 1e6 / iv / au, 'twiddle_words': self.twiddleWords(),
                'stored_twiddle_words': self.storedTwiddleWords(), 'generators': self.generatorCount()}

    # --- fan-out trees (fanout=) ------------------------------------------------------------------

    fanout = None
    fanoutLoads = 'register'

    def treeLevels(self, N: int, load: int = 1) -> list[int]:
        """Registers per level (source side first) of a tree feeding N sinks of `load` loads each, every
        register driving at most `fanout` loads; [] when the source can drive them all (the iterative's rule)."""
        F = self.fanout
        if not F or N * load <= F:
            return []
        lv = [min(N, -(-N * load // F))]
        while lv[0] > F:
            lv.insert(0, -(-lv[0] // F))
        return lv

    def fanoutPlan(self, pipelineStages=1) -> dict:
        """The trees (fanout=): {name: dict(N, load, width, levels, kind, slack, copies)}. The levels stand behind
        the register the core has without fanout. kind 'read': the RAM read addresses, their depth delays the
        reads (`fanShift`); 'tap': the register loads from the tag pipeline that many cycles earlier, `slack` =
        the tag cycles it can move without a shift. 'twiddle fan-out' carries 'tables': {table: levels} (every
        table padded to the deepest: one timing). Depths from the counts alone, no device data."""
        if not self.fanout:
            return {}
        from ..memory import ramCost
        W, U, g, T, MU = self.W, self.U, self.g, self.T, 1 << self.U
        tw = max(1, (self.qMax() - 1).bit_length())
        Wd = self.memBound.bitWidth if hasattr(self, 'memBound') else tw
        M, D = len(self.moduliList()), len(self.dirs)
        RL, RT = self.RL, self.rotLatency()
        pins = self.fanoutLoads == 'pins'

        def prim(depth, width, style):
            if not pins:
                return 1
            c = ramCost(depth, width, style)
            return max(1, int(c['lut'] or (2 * c['bram'] + c['uram'])))
        ID, PD = self.inDepth(), (self.S + 1) * T
        FA, PA = _bits(ID), _bits(PD)
        P = {}

        def add(nm, N, width, kind, load=1, slack=0, copies=1):
            if width > 0 and N > 0:
                P[nm] = dict(N=N, load=load, width=width, levels=self.treeLevels(N, load), kind=kind,
                             slack=slack, copies=copies)
        add('fifo read', W, FA, 'read', prim(ID, Wd, self.memStyle))
        add('pool read', g, PA, 'read', prim(PD, Wd, self.memStyle), copies=MU)
        add('pool write', W, 1 + PA, 'tap', prim(PD, Wd, self.memStyle), slack=RL + RT)
        add('source select', W, 1, 'tap', Wd, slack=RL - 1)
        add('read rotate', W, U, 'tap', Wd, slack=RL - 1)
        add('write rotate', W, U, 'tap', Wd, slack=RL + RT)
        # per stage: DIR of the unified butterfly, the halver's direction, the bypass select, the round select
        tabs, use = self.roundTables()
        bits = 0
        for j in range(U):
            nsrc = max(sum(1 for r in range(self.R) if use.get((j, la, r)) is not None)
                       for (jj, h, a, la, lb) in self.pairs() if jj == j)
            bits += (1 if self.unified and D == 2 else 0) + (1 if self.stageHalve and D == 2 else 0) + \
                (1 if j < self.e else 0) + (_bits(self.R) if nsrc > 1 else 0)
        add('stage tags', W // 2, bits, 'tap', 2 * Wd, slack=RL + RT)
        if M > 1 or getattr(self, 'loadable', False):
            qw = sum(max(max(1, int(self.qPortValues(q)[p]).bit_length()) for q in self.moduliList())
                     for p in self.qPorts())
            add('modulus constants', W // 2, qw, 'tap', 1, slack=RL + RT, copies=U)
            if self.twistOn:
                add('twist constants', W, qw, 'tap', 1, slack=RL + RT)
        # the twiddle words: table -> its butterflies (constants need none)
        srcs = getattr(self, '_srcOf', None) or ['rom'] * len(tabs)
        gend = self.generator() is not None and any(x != 'rom' for x in srcs)
        per = {}
        for ti, t in enumerate(tabs):
            const = srcs[ti] == 'rom' and self.entryCount(t['r']) * D * M == 1 and not getattr(self, 'loadable', False)
            per[ti] = [] if const else self.treeLevels(t['users'])
        deep = max(per.values(), key=len) if per else []
        if deep:
            sl = RT + self.lead(pipelineStages) - 1 - ((self.genLatency(pipelineStages) + 1) if gend else 0)
            P['twiddle fan-out'] = dict(N=max(t['users'] for t in tabs), load=1, width=tw + self.wpWidth(),
                                        levels=list(deep), kind='tap', slack=max(0, sl), copies=len(tabs),
                                        tables=per)
        if self.twistOn:
            rec = getattr(self, 'twistSrc', 'tab') == 'rec'
            dep = (self.twistRecD(pipelineStages) if rec else T) * D * M
            add('twist address', W, _bits(dep), 'tap', prim(dep, tw, 'auto' if rec else self.twiddleStyle), slack=1)
        return P

    def fanShift(self, pipelineStages=1) -> int:
        """Cycles the fan-out trees add between an issue and its RAM read (0 without fanout): the deepest
        read tree, or what a tapped tree lacks in earlier tag cycles. Part of `inOffset`."""
        if not self.fanout:
            return 0
        return max([0] + [len(t['levels']) - (0 if t['kind'] == 'read' else t['slack'])
                          for t in self.fanoutPlan(pipelineStages).values()])

    def fanoutRegisters(self, pipelineStages=1) -> int:
        """Flip-flops the trees add: the tree registers (read trees padded to `fanShift`, twiddle trees to the
        deepest), the tag pipeline's `fanShift` extra stages, the second FIFO count."""
        P = self.fanoutPlan(pipelineStages)
        if not P:
            return 0
        FR = self.fanShift(pipelineStages)
        ff = 0
        for nm, t in P.items():
            if nm == 'twiddle fan-out':
                k = len(t['levels'])
                ff += t['width'] * sum(sum(lv) + k - len(lv) for lv in t['tables'].values() if lv or k)
                continue
            n = sum(t['levels'])
            if t['kind'] == 'read':
                n += FR - len(t['levels'])
            ff += t['width'] * n * t['copies']
        if FR:
            tag = 2 + _bits(self.R) + self.CB + _bits(self.S + 1) + self.midxBits() + (1 if len(self.dirs) == 2 else 0)
            ff += FR * (tag + 2) + _bits(self.inDepth() + 1)
        return ff

    # --- shared inverse twiddles (shareInverseTwiddles=) ------------------------------------------------

    shareInv = False

    @staticmethod
    def shareAddress(amap: str, en: int, E: int) -> int:
        """The forward entry read for the inverse's entry en: 'same', 'neg' (-en mod E) or 'cpl' (E-1-en)."""
        return en if amap == 'same' else (-en) % E if amap == 'neg' else E - 1 - en

    @staticmethod
    def shareSign(rule: str, en: int) -> bool:
        """Whether the inverse's entry en is minus the forward word: '+', '-', 'nz' (en != 0), 'z' (en == 0)."""
        return rule == '-' or (rule == 'nz' and en != 0) or (rule == 'z' and en == 0)

    def inverseShare(self) -> dict:
        """{table: (source table, address map, sign rule)} of the tables whose inverse block is not stored: in an
        inverse polynomial its butterflies take the source table's forward word at shareAddress(map, entry) and, where
        shareSign(rule, entry), swap their two outputs (a CT butterfly with -w gives (a - wb, a + wb)).
        The rule, in exponents (no modulus enters): the inverse word is w^-ei, the forward word w^ef, both of order n;
        equal when ei + ef = 0 mod n, opposite when ei + ef = n/2 mod n. A table is shared when one map and one sign
        rule hold for all its entries against one forward table of its round and stage, that table is shared too
        (in an inverse polynomial it reads its forward block) and every borrower of it asks the same address map."""
        if not self.shareInv:
            return {}
        if 'ishare' in self._qCache:
            return self._qCache['ishare'][0]
        tabs = self.roundTables()[0]
        n, h = self.n, self.n // 2
        cand = {}
        for ti, t in enumerate(tabs):
            ei = t['exps']['inv']
            E = len(ei)
            lst = []
            for tj in [ti] + [x for x, u in enumerate(tabs) if x != ti and (u['r'], u['j']) == (t['r'], t['j'])]:
                ef = tabs[tj]['exps']['fwd']
                if len(ef) != E:
                    continue
                for am in (('same',) if E == 1 else ('same', 'cpl') if E == 2 else ('same', 'neg', 'cpl')):
                    dl = [(ei[a_] + ef[self.shareAddress(am, a_, E)]) % n for a_ in range(E)]
                    if any(x not in (0, h) for x in dl):
                        continue
                    sg = [x == h for x in dl]
                    rule = '+' if not any(sg) else '-' if all(sg) else 'nz' if not sg[0] and all(sg[1:]) else \
                        'z' if sg[0] and not any(sg[1:]) else None
                    if rule and (E > 1 or (tj == ti and rule == '+')):   # one word is not worth a swap or a source
                        lst.append((tj, am, rule))
            if lst:
                cand[ti] = lst
        shared = set(cand)
        while True:
            imap, pick = {}, {}
            for ti in sorted(shared):
                for (tj, am, rule) in cand[ti]:
                    if tj in shared and imap.get(tj, am) == am:
                        imap[tj] = am
                        pick[ti] = (tj, am, rule)
                        break
            if len(pick) == len(shared):
                break
            shared = set(pick)
        self._qCache['ishare'] = (pick, imap)
        return pick

    def inverseAddressMap(self, ti: int) -> str | None:
        """The address map table ti's read takes in an inverse polynomial (its borrowers'), None: not borrowed."""
        self.inverseShare()
        return self._qCache['ishare'][1].get(ti) if self.shareInv else None

    def tableDirs(self, ti: int) -> int:
        """Direction blocks table ti stores (1: its inverse block is shared)."""
        return 1 if ti in self.inverseShare() else len(self.dirs)

    def tableDirList(self, ti: int) -> list:
        return ['fwd'] if ti in self.inverseShare() else list(self.dirs)

    def _sharedRead(self, ti: int, d: str, mi: int, shoup: bool):
        """(table words, companions, block offset, address map, sign rule) of table ti's read in direction d."""
        E = self.entryCount(self.roundTables()[0][ti]['r'])
        sh = self.inverseShare()
        amp = sgn = None
        if d == 'inv' and ti in sh:
            ti, amp, sgn = sh[ti]
        off = (mi * self.tableDirs(ti) + (self.dirs.index(d) if self.tableDirs(ti) > 1 else 0)) * E
        return self.roundTable(ti), (self.roundTableWP(ti) if shoup else None), off, amp, sgn

    def inverseShareCost(self) -> tuple[int, int]:
        """(butterflies with an output swap, butterflies with a second table source in some round)."""
        sh = self.inverseShare()
        use = self.roundTables()[1]
        sw = xs = 0
        for (j, h_, a_, la, lb) in self.pairs():
            tis = [use[(j, la, r)] for r in range(self.R) if use[(j, la, r)] is not None]
            sw += any(ti in sh and sh[ti][2] != '+' for ti in tis)
            xs += any(ti in sh and sh[ti][0] != ti for ti in tis)
        return sw, xs

    def inverseShareReport(self) -> dict:
        """Stored words with and without the option, and what it costs."""
        sh = self.inverseShare()
        tabs = self.roundTables()[0]
        M = len(self.moduliList())
        full = sum(self.entryCount(t['r']) * len(self.dirs) * M for t in tabs)
        now = sum(self.entryCount(t['r']) * self.tableDirs(ti) * M for ti, t in enumerate(tabs))
        rules = {}
        for ti, (tj, am, rule) in sh.items():
            k = ('own' if tj == ti else 'other') + ' ' + am + ' ' + rule
            rules[k] = rules.get(k, 0) + 1
        sw, xs = self.inverseShareCost()
        return dict(tables=len(tabs), shared=len(sh), words=full, stored=now, saved=full - now, rules=rules,
                    swapButterflies=sw, secondSources=xs, butterflies=len(self.pairs()))

    # --- DSP budget ------------------------------------------------------------------------------

    # --- BRAM budget: twiddleSource='auto' under a memory budget ----------------------------------

    V80_BRAM36 = 3741                 # BRAM36 tiles of the V80's device (xcv80)
    _bramBudget = None
    bramPlan = None

    def bramCount(self) -> float:
        """BRAM36 of every memory of the design (data banks, input FIFO, twiddle and twist tables)."""
        return sum(m['cost']['bram'] * m['count'] for m in self.memories())

    def setBramBudget(self, total: float | None = None, fraction: float | None = None, device: int | None = None):
        """A budget of BRAM36 for the whole design: `total` tiles, or `fraction` of the device (`device` tiles,
        default the V80's 3,741). With twiddleSource='auto' the tables move from ROM to a generated supply,
        largest ROM first, each to the cheapest (area units) of 'rec', 'tree' and 'otf' that needs fewer BRAM,
        until the design fits; then the output twist goes to its recurrence (twistSource='auto'), then the read
        tables of 'tree' classes. Nothing moves when the design fits already. Raises ValueError when no supply
        fits (the data memories alone are too large, or the tables are fixed: an explicit twiddleSource, Shoup,
        unified). Returns the plan (`bramPlan`, text: `bramBudgetReport()`)."""
        if (total is None) == (fraction is None):
            raise ValueError(f'{self.name}: setBramBudget takes total= (BRAM36) or fraction= (of the device)')
        bud = float(total) if total is not None else float(fraction) * (device or self.V80_BRAM36)
        if bud < 0:
            raise ValueError(f'{self.name}: the BRAM budget must not be negative')
        self._bramBudget = bud
        try:
            self.propagateBound()
        except ValueError:
            self._bramBudget, self.bramPlan = None, None
            self.propagateBound()
            raise
        if self._dspPlan:
            self.setDspBudget(total=self.dspTree.budget)     # the generators changed: split the DSP again
        return self.bramPlan

    def clearBramBudget(self) -> None:
        self._bramBudget, self.bramPlan = None, None
        if hasattr(self, 'inputBound'):
            self.propagateBound()

    def _fitBramBudget(self, pipelineStages=1) -> None:
        self.bramPlan = None
        bud = self._bramBudget
        if bud is None:
            return
        tabs = self.roundTables()[0]
        M, D = len(self.moduliList()), len(self.dirs)
        tw = max(1, (self.qMax() - 1).bit_length())
        plan = dict(budget=bud, before=self.bramCount(), moved=[], twist=None, fixed=None)

        def units(c):
            return (c['lut'] / 1000 + c['ff'] / 1000 + c['bram'] + 8 * c['uram']) / 5

        def over():
            return self.bramCount() > bud + 1e-9

        def refresh():                           # the lead changes with the first generated table: slots, FIFO
            if self._slotsReq == 'auto':
                self.S = self.slotReport(pipelineStages)['choice']
            self._chooseInDepth(pipelineStages)

        if self.twiddleSource != 'auto':
            plan['fixed'] = f"twiddleSource {self.twiddleSource!r} is fixed (only 'auto' moves tables)"
            if self.shoup():
                plan['fixed'] = 'Shoup butterflies read {WP, W} words: a generated twiddle has no companion'
        elif self.unified:
            plan['fixed'] = 'unified butterflies keep ROM tables (the inverse entries are the low beat bits)'
        if over():
            hadGen = self._gen
            if self._gen is None:
                self._gen = self._multiplier(f'{self.name}_gen', IntType(0, self.qMax() - 1))
                self._gen.propagateBound()
            g = self._gen
            lg, dg = g.areaCost()
            genUnits = (lg / 1000 + g.flipFlops(pipelineStages) / 1000 + 4 / 3 * dg) / 5
            regUnits = tw * (self.genLatency(pipelineStages) + 2) / 5000

            def small(deps):
                cs = [ramCost(d_, tw, 'auto') for d_ in deps if d_ > 1]
                return sum(units(c) for c in cs), sum(c['bram'] for c in cs)

            def romCost(ti):
                return ramCost(self.entryCount(tabs[ti]['r']) * D * M, tw + self.wpWidth(), self.twiddleStyle)

            def alternatives(ti, tree=True):
                """(area units, BRAM36, source, tree base) of every generated supply table ti can take."""
                sb = self.sigBits(tabs[ti]['r'])
                out = []
                if sb < max(1, self.genMinBits):
                    return out
                if all(self._step(ti, d) is not None for d in self.dirs):
                    u, b = small([self.recK(ti, pipelineStages) * D * M, D * M])
                    out.append((genUnits + u + regUnits, b, 'rec', None, ti))
                h = self.otfBits(ti)
                u, b = small([(1 << h) * D * M, (1 << (sb - h)) * D * M])
                out.append((genUnits + u + regUnits, b, 'otf', None, ti))
                if tree:
                    key = (tabs[ti]['r'], tabs[ti]['j'])
                    cl = [x for x in range(len(tabs)) if x != ti and (tabs[x]['r'], tabs[x]['j']) == key]
                    base = next((x for x in cl if self._srcOf[x] == 'tbase' and self.treeDelta(x, ti) is not None),
                                None)
                    if base is None:
                        base = next((x for x in cl if self._srcOf[x] == 'rom' and self.treeDelta(x, ti) is not None),
                                    None)
                    if base is not None and (base < ti or self._srcOf[base] == 'rom'):
                        # the read table is the lower index of the two (the RTL declares it first): with a ROM
                        # sibling above, that sibling is derived and this table stays the read one
                        u, b = small([D * M])
                        out.append((genUnits + u + regUnits * (1 if self._srcOf[base] == 'tbase' else 2), b,
                                    'tree', min(base, ti), max(base, ti)))
                return out

            def move(ti, src, base, saved, why):
                self._srcOf[ti] = src
                if base is not None:
                    self._srcOf[base] = 'tbase'
                    self._treeBase[ti] = base
                plan['moved'].append(dict(table=ti, round=tabs[ti]['r'], stage=tabs[ti]['j'],
                                          entries=self.entryCount(tabs[ti]['r']) * D * M, to=src, base=base,
                                          bramSaved=saved, why=why))

            if plan['fixed'] is None:
                # pass 1: the ROM tables, largest first, each to its cheapest supply that needs fewer BRAM
                for _ in range(3):
                    n0 = len(plan['moved'])
                    order = sorted((ti for ti in range(len(tabs)) if self._srcOf[ti] == 'rom'),
                                   key=lambda ti: (-romCost(ti)['bram'], ti))
                    for ti in order:
                        if not over():
                            break
                        if self._srcOf[ti] != 'rom':
                            continue                     # became the read table of a 'tree' class
                        b0 = romCost(ti)['bram']
                        cands = [x for x in alternatives(ti) if x[1] < b0]
                        if not cands:
                            continue
                        u, b, src, base, tgt = min(cands, key=lambda x: (x[0], x[1]))
                        move(tgt, src, base, b0 - b, f'ROM {b0:g} BRAM36, {src} {b:g} at {u:.2f} area units')
                    refresh()
                    if not over() or len(plan['moved']) == n0:
                        break
            # the output twist: W tables of T words per modulus and direction, or one recurrence per lane
            if over() and self.twistOn and self.twistSrc == 'tab':
                if self.twistSourceReq == 'auto':
                    b0 = self.bramCount()
                    self.twistSrc = 'rec'
                    refresh()
                    plan['twist'] = dict(to='rec', bramSaved=b0 - self.bramCount())
                else:
                    plan['twistFixed'] = "twistSource 'tab' is fixed"
            if over() and plan['fixed'] is None:
                # pass 2: the read tables of the 'tree' classes: the class goes to 'rec' / 'otf' table by table
                for tb in sorted((ti for ti in range(len(tabs)) if self._srcOf[ti] == 'tbase'),
                                 key=lambda ti: (-romCost(ti)['bram'], ti)):
                    if not over():
                        break
                    cl = [tb] + [x for x, y in self._treeBase.items() if y == tb]
                    alts = {x: [a_ for a_ in alternatives(x, tree=False)] for x in cl}
                    if any(not v for v in alts.values()):
                        continue
                    if sum(min(a_[1] for a_ in alts[x]) for x in cl) >= romCost(tb)['bram'] + small([D * M])[1] * (
                            len(cl) - 1):
                        continue                         # the generated class would not need fewer BRAM
                    for x in cl:
                        u, b, src, _b, _t = min(alts[x], key=lambda a_: (a_[1], a_[0]))
                        self._treeBase.pop(x, None)
                        b0 = romCost(x)['bram'] if x == tb else 0
                        plan['moved'] = [m_ for m_ in plan['moved'] if m_['table'] != x]
                        move(x, src, None, b0 - b, "the 'tree' class's read table did not fit: whole class generated")
                refresh()
            # give back: the twist or a whole class can save more than was missing, so the moves are undone
            # from the last one (the smallest tables) while the design still fits
            if not over() and (plan['twist'] is not None or len(plan['moved']) > 1):
                for m_ in list(reversed(plan['moved'])):
                    ti, was, wasBase = m_['table'], self._srcOf[m_['table']], self._treeBase.get(m_['table'])
                    self._srcOf[ti] = 'rom'
                    self._treeBase.pop(ti, None)
                    freed = wasBase is not None and wasBase not in self._treeBase.values()
                    if freed:
                        self._srcOf[wasBase] = 'rom'
                    if over():
                        self._srcOf[ti] = was
                        if wasBase is not None:
                            self._treeBase[ti] = wasBase
                            self._srcOf[wasBase] = 'tbase'
                    else:
                        plan['moved'].remove(m_)
                refresh()
                if over():
                    raise AssertionError(f'{self.name}: the BRAM plan does not fit after giving tables back')
            if not plan['moved'] and plan['twist'] is None:
                self._gen = hadGen
        plan['after'] = self.bramCount()
        plan['fits'] = not over()
        plan['sources'] = {k: self._srcOf.count(k) for k in sorted(set(self._srcOf))}
        plan['twistSource'] = self.twistSrc if self.twistOn else None
        plan['generators'] = self.generatorCount()
        self.bramPlan = plan
        if not plan['fits']:
            data = sum(m['cost']['bram'] * m['count'] for m in self.memories()
                       if not m['what'].startswith(('twiddle', 'twist')))
            why = '; '.join(x for x in (plan['fixed'], plan.get('twistFixed')) if x)
            raise ValueError(
                f"{self.name}: no twiddle supply fits the BRAM budget of {bud:g} BRAM36: the smallest reached needs "
                f"{plan['after']:g} ({data:g} in the data memories and the input FIFO, {plan['after'] - data:g} in "
                f"the tables; {plan['before']:g} before any move)" + (f'; {why}' if why else '')
                + ". Raise the budget, use fewer slots or moduli, or memStyle / twiddleStyle 'ultra' or 'distributed'.")

    def bramBudgetReport(self) -> str:
        """What the BRAM budget changed and why, as text."""
        p = self.bramPlan
        if p is None:
            return 'no BRAM budget set'
        ln = [f"BRAM budget {p['budget']:g} BRAM36: {p['before']:g} before, {p['after']:g} after "
              f"({'fits' if p['fits'] else 'does NOT fit'}); table sources {p['sources']}, "
              f"twist {p['twistSource']}, generators {p['generators']}"]
        if not p['moved'] and not p['twist']:
            ln.append('  nothing moved' + (f" ({p['fixed']})" if p['fixed'] and not p['fits'] else
                                           ': the design fits with the area-based choice'))
        for m in p['moved']:
            ln.append(f"  table {m['table']} (round {m['round']}, stage {m['stage']}, {m['entries']} words) -> "
                      f"{m['to']}" + (f" (read table {m['base']})" if m['base'] is not None else '')
                      + f": {m['why']}")
        if p['twist']:
            ln.append(f"  output twist -> rec: {p['twist']['bramSaved']:g} BRAM36 saved")
        return '\n'.join(ln)

    def setDspBudget(self, fraction: float | None = None, total: int | None = None, weight=None):
        '''As IterativeNTTScheme.setDspBudget: blocks {butterfly x count, output twist x W}.'''
        from ...core import dspbudget as DB
        self.clearDspBudget()
        blocks = []
        b = DB.blockOf('butterfly', self.butterflyUnit().inner(), self.butterflyCount(), weight)
        b.key = 'bu'
        blocks.append(b)
        if self.twistMultiplier is not None:
            b = DB.blockOf('output twist multiplier', self.twistMultiplier, self.W, weight)
            b.key = 'twist'
            blocks.append(b)
        if self.generatorCount():
            b = DB.blockOf('twiddle generator', self.generator(), self.generatorCount(), weight)
            b.key = 'gen'
            blocks.append(b)
        pure = sum(b.count * b.pureDsp for b in blocks)
        root = DB.Budget(self.name, 1, pure, sum(b.count * b.weight for b in blocks), children=blocks)
        root.budget = DB.resolveTotal(pure, fraction, total)
        DB.splitTypes(root.budget, blocks)
        for b in blocks:
            DB.splitLeaves(b)
        self._dspPlan = {b.key: DB.budgetsOf(b) for b in blocks}
        self.propagateBound()
        for b in blocks:
            DB.measure(b, self.twistMultiplier if b.key == 'twist' else
                       (self.generator() if b.key == 'gen' else self.butterflyUnit().inner()))
        root.lut, root.dsp = self.areaCost()
        self.dspTree = root
        return root

    def clearDspBudget(self) -> None:
        self._dspPlan = None
        self.dspTree = None
        if hasattr(self, 'inputBound'):
            self.propagateBound()

    def propagateValue(self):
        raise NotImplementedError(f'{self.name}: use transform(frames)')

    def getOperatorInterface(self, name: str, pipelineStages: int = 1):
        raise NotImplementedError(f'{self.name}: the RTL spec comes from HybridNTT.getOperatorInterface')


from . import HybridPorts as _hp  # noqa: E402  (the port options: outReady, natural order, the record stream)
_hp.install(HybridNTTScheme)
