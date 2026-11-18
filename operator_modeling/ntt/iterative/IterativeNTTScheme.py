'''The iterative NTT scheme: B butterflies walk the log2(n) stages over banked memory.

    IterativeNTTScheme   the model: memory organisation, twiddle supply, bit-exact values, cycles, resources

The operator is in `IterativeNTT.py`, and the routability model across SLRs in `slrmodel.py`.
'''
from __future__ import annotations

import contextlib
import math
import random

from ...core.IntType import IntType
from ...core.OperatorScheme import OperatorScheme
from ..dataflow.StreamingNTTScheme import StreamingNTTScheme
from ..memory import MEM_STYLES, lutramGroupLuts, ramCost

#: twiddle buffering of the iterative NTT (IterativeNTTScheme twiddleBuffer=)
TWIDDLE_BUFFERS = ('single', 'recycle', 'double')
#: memory organisations of the iterative NTT (IterativeNTTScheme memOrg=)
MEM_ORGS = ('auto', 'inplace', 'constgeo')


def _par(x: int) -> int:
    return bin(x).count('1') & 1


def _ins(x: int, pos: int, bit: int) -> int:
    '''Insert `bit` at bit position `pos` of x (the bits from pos up move one place up).'''
    return ((x >> pos) << (pos + 1)) | (bit << pos) | (x & ((1 << pos) - 1))


def _rem(x: int, pos: int) -> int:
    '''Remove bit `pos` of x (the inverse of `_ins`).'''
    return ((x >> (pos + 1)) << pos) | (x & ((1 << pos) - 1))


def _rotr(x: int, k: int, w: int) -> int:
    '''x rotated right by k places in w bits.'''
    if w <= 0:
        return x
    k %= w
    return ((x >> k) | (x << (w - k))) & ((1 << w) - 1) if k else x


def _rotl(x: int, k: int, w: int) -> int:
    return _rotr(x, w - (k % w), w) if w > 0 else x


class IterativeNTTScheme(OperatorScheme):
    '''An iterative (memory-based) radix-2 NTT: B butterflies walk the log2(n)
    stages of one polynomial in place, over 2B single-port-pair memory banks, while
    a second set of banks streams the previous result out and the next polynomial
    in (`ioLanes` points per cycle each way). REVIEW: ntt_hw/experiments/iterative.

    Memory. Point m (memory order: CT takes the bit-reversed natural input, and
    leaves the natural output, as the streaming NTT) lives in bank
    `(m mod 2B) xor (parity(m >> (b+1)) << b)` at address `m >> (b+1)`
    (b = log2 B): the low b bits of the bank are m's own, the top one is m's bit b
    flipped by the parity of the row. Every stage reads 2B points in 2B different
    banks per cycle and writes them back where they came from (in place), and a
    row of 2B consecutive points is one address in every bank (the I/O beats).

    Order. A stage takes T = n/2B cycles. Stages s <= b pair inside a row (cycle
    = row); stages s = b+1+p pair rows differing in row bit p, the B butterflies
    on the low b bits, the cycle index being the row without bit p, shifted up,
    with m's bit b below it. Consecutive stages then see each point at most
    2^p cycles apart, so the next stage starts T cycles after the previous one
    as long as T >= 2^p + Pw (Pw: read to write-back latency); otherwise the
    model inserts the cycles it needs (`stageOffsets`). Twiddles: per butterfly
    one table, addressed by the stage and the cycle's low p+1 bits
    (`twiddleIndex`; every entry distinct, n words over all butterflies per
    direction); 'rom' (fixed q) or 'ram' (written through the load port); with a modulus per
    polynomial (twiddleBuffer 'recycle', constant geometry) also 'rec': the tables written on chip
    from a short record (`recUnits`, `recTables`).

    The rest as `StreamingNTTScheme` (it shares its roots, exponents, stored
    domain and butterflies): `q=` or a run-time `family=`, `direction`
    'forward' / 'inverse' / 'both' (DIR, inverse = CT with the inverse cyclic
    twiddles), `inverseScale` 'stage' (x2^-1 after every butterfly, cyclic) or
    'output' (n^-1 psi^-k by `ioLanes` multipliers on the output stream),
    `butterfly=` (ModularBU arguments: any multiplier kind and reduction),
    `targetFmaxMhz`, a DSP budget (`setDspBudget`).
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
    _exponent = StreamingNTTScheme._exponent
    _probe = StreamingNTTScheme._probe
    storedFactor = StreamingNTTScheme.storedFactor
    stored = StreamingNTTScheme.stored
    companion = StreamingNTTScheme.companion
    shoup = StreamingNTTScheme.shoup
    _buArgs = StreamingNTTScheme._buArgs
    _mulArgs = StreamingNTTScheme._mulArgs
    _multiplier = StreamingNTTScheme._multiplier
    halve = staticmethod(StreamingNTTScheme.halve)
    # merge glue: the borrowed helpers above now also serve GS (gs_dataflow: mergedTwist, stageBit) and
    # per-frame moduli (kim_multimod: perFrame, moduli). The iterative NTT is CT only with one modulus per
    # polynomial job, for which these reduce exactly to the helpers it was built with.
    mergedTwist = StreamingNTTScheme.mergedTwist
    stageBit = StreamingNTTScheme.stageBit
    perFrame = False
    moduli = None
    multiRom = False               # moduli= (IterativeNTTScheme): every table a ROM holding all the moduli

    dspTree = None
    _dspPlan = None
    _cgReserveAtStart = False      # gate 7 cg rns's negative test only: the first, unsound set reservation

    def __init__(self, name: str, n: int, butterflies: int, q: int = 0, family=None,
                 butterflyType: str = 'CT', negacyclic: bool = False, direction: str = 'forward',
                 scaleInverse: bool = False, butterfly: dict | None = None, twiddleSource: str | None = None,
                 targetFmaxMhz: float | None = None, primitiveRoot: int | None = None,
                 inverseScale: str = 'output', ioLanes: int | None = None, memStyle: str = 'auto',
                 twiddleStyle: str = 'auto', ramLatency: int = 2, shareInverseTwiddles: bool | None = None,
                 twiddleBuffer: str | None = None, twiddleLanes: int | None = None, memOrg: str = 'auto',
                 crossRegs: int | None = None, dirPerPoly: bool = False, recGroup: int | None = None,
                 fanout: int | None = None, recMultiplier: dict | None = None, fanoutKeepSinks: bool = True,
                 fanoutLoads: str = 'register', recSeeds: int | str = 0, qSwitch: str = 'bubble',
                 moduli=None):
        super().__init__(name)
        # moduli=[q0, q1, ...] (twiddleSource 'rom'): a build-time list of moduli, every table a ROM holding all
        # of them (address {MIDX, the one-modulus address}), the modulus constants small ROMs indexed by MIDX;
        # the modulus (port MIDX) and with direction 'both' the direction (port DIR) are taken with the first
        # input beat of each polynomial. No load port, no record stream.
        self.multiRom = moduli is not None
        if self.multiRom:
            from ...modmult.ModulusFamily import ModulusFamily as _MF
            ms = [int(x) for x in moduli]
            if q:
                raise ValueError(f'{name}: moduli= replaces q=')
            if len(ms) < 1 or len(set(ms)) != len(ms):
                raise ValueError(f'{name}: moduli must be a non-empty list of distinct moduli')
            if twiddleSource not in (None, 'rom'):
                raise ValueError(f"{name}: moduli= is the multi-modulus ROM option: twiddleSource 'rom' (got "
                                 f"{twiddleSource!r}; 'ram' / 'rec' take a run-time family= instead)")
            if twiddleBuffer not in (None, 'single'):
                raise ValueError(f"{name}: moduli= has no record stream: twiddleBuffer {twiddleBuffer!r} is not "
                                 f"built with it (the tables are ROMs)")
            if dirPerPoly:
                raise ValueError(f"{name}: dirPerPoly is the record stream's direction bit; with moduli= and "
                                 f"direction 'both' the DIR port is already taken per polynomial")
            if fanout is not None:
                raise ValueError(f'{name}: fanout trees are not built with moduli=')
            rootOrd = 2 * n if negacyclic else n
            bad = [m for m in ms if m < 3 or (m - 1) % rootOrd]
            if bad:
                raise ValueError(f'{name}: moduli {bad[:4]}: q - 1 must be a multiple of {rootOrd}')
            if family is not None:
                if not family.runtime or any(not family.contains(m) for m in ms):
                    raise ValueError(f'{name}: family= with moduli= must be a run-time family containing them')
            else:
                family = _MF.table(ms)
            self.moduli = ms
            self._refQ = ms[0]
            twiddleSource, twiddleBuffer = 'rom', 'single'
        if qSwitch not in ('bubble', 'inline'):
            raise ValueError(f"{name}: qSwitch must be 'bubble' or 'inline'")
        L = n.bit_length() - 1
        if n != 1 << L or n < 4:
            raise ValueError(f'{name}: n must be a power of two >= 4')
        B = butterflies
        b = B.bit_length() - 1
        if B != 1 << b or B < 1 or 4 * B > n:
            raise ValueError(f'{name}: butterflies must be a power of two with 4*B <= n (two cycles per stage)')
        if butterflyType != 'CT':
            raise ValueError(f'{name}: the iterative NTT runs Cooley-Tukey butterflies (inverse: CT with the inverse '
                             f'cyclic twiddles)')
        if direction not in ('forward', 'inverse', 'both'):
            raise ValueError(f"{name}: direction must be 'forward', 'inverse' or 'both'")
        if inverseScale not in ('output', 'stage'):
            raise ValueError(f"{name}: inverseScale must be 'output' or 'stage'")
        if inverseScale == 'stage' and (negacyclic or direction == 'forward'):
            raise ValueError(f"{name}: inverseScale='stage' needs a cyclic transform with an inverse")
        self.runtime = family is not None and family.runtime
        if (q >= 3) == self.runtime:
            raise ValueError(f'{name}: give a fixed q or a run-time family=, one of them')
        self.family = family if self.runtime else None
        self.q = q if not self.runtime else 0
        src = twiddleSource or ('ram' if self.runtime else 'rom')
        if src not in ('rom', 'ram', 'rec') or (src == 'rom' and self.runtime and not self.multiRom):
            raise ValueError(f"{name}: twiddleSource 'rom' (fixed q), 'ram' or 'rec' (generated on chip from a "
                             f"per-polynomial record: twiddleBuffer 'recycle', memOrg 'constgeo')")
        io = ioLanes or 2 * B
        if io != 1 << (io.bit_length() - 1) or not 1 <= io <= 2 * B:
            raise ValueError(f'{name}: ioLanes must be a power of two in [1, 2B]')
        for st in (memStyle, twiddleStyle):
            if st not in MEM_STYLES:
                raise ValueError(f'{name}: memory style {st!r}: one of {MEM_STYLES}')
        if ramLatency not in (1, 2, 3, 4):
            raise ValueError(f'{name}: ramLatency 1 (registered read), 2 (and an output register) or 3, 4 '
                             f'(more read registers: memories far from the butterflies)')
        self.n, self.L, self.B, self.b = n, L, B, b
        self.H = L - b - 1                      # row bits
        self.T = 1 << self.H                    # cycles per stage = rows
        self.io = io
        self.lio = io.bit_length() - 1
        self.beats = n // io                    # I/O beats per polynomial
        self.butterflyType = butterflyType
        self.negacyclic = negacyclic
        self.direction = direction
        self.inverseScale = inverseScale
        self.stageHalve = 1 if inverseScale == 'stage' else 0
        self.scaleInverse = scaleInverse or (negacyclic and direction != 'forward')
        self.twistOn = bool(self.scaleInverse and not self.stageHalve)
        self.butterflyArgs = dict(butterfly or {})
        self.twiddleSource = src
        self.targetFmaxMhz = targetFmaxMhz
        self.primitiveRoot = primitiveRoot
        self.memStyle, self.twiddleStyle = memStyle, twiddleStyle
        self.R = ramLatency
        self.dirs = (['fwd'] if direction in ('forward', 'both') else []) + \
                    (['inv'] if direction in ('inverse', 'both') else [])
        # cyclic with both directions: the inverse twiddle w^-u = -w^(2^s - u) is a forward entry of
        # butterfly -j, the sign an output swap of the CT butterfly (twiddleRef): forward tables only
        can = direction == 'both' and not negacyclic
        self.shareInv = can if shareInverseTwiddles is None else bool(shareInverseTwiddles)
        if self.shareInv and not can:
            raise ValueError(f'{name}: shared inverse twiddles need a cyclic transform with both directions')
        self._shareReq = shareInverseTwiddles
        self.tdirs = ['fwd'] if self.shareInv else list(self.dirs)
        self._qCache = {}
        self.tdepth = (1 << (self.H + 1)) - 2      # one butterfly's twiddle table, one direction (stages > b)
        self.cdepth = b + 1                         # its stage-constant table (stages <= b), one direction
        # the memory organisation: 'inplace' (the parity banks above), 'constgeo' (constant geometry: ping-pong
        # over two bank sets with fixed wiring, a third set for the I/O), 'auto' (memOrgReport decides once the
        # butterfly is known, in propagateBound)
        if memOrg not in MEM_ORGS:
            raise ValueError(f'{name}: memOrg must be one of {MEM_ORGS}')
        if memOrg == 'constgeo' and shareInverseTwiddles:
            raise ValueError(f'{name}: shared inverse twiddles are not built under constant geometry (the partner '
                             f'butterfly changes with the stage: THEORY.md 15i)')
        self.memOrgRequest = memOrg
        self.memOrg = 'inplace'
        # constant geometry: extra register stages on the operand path (before the butterflies, with the
        # twiddles) and on the write path (after them), so the bank <-> butterfly nets that cross SLRs run
        # register to register; None: 2 when the design needs more than one SLR (slrmodel.slrSpan), else 0
        if crossRegs is not None and (crossRegs < 0 or crossRegs > 4):
            raise ValueError(f'{name}: crossRegs 0 .. 4')
        if crossRegs and memOrg == 'inplace':
            raise ValueError(f'{name}: crossRegs is for constant geometry')
        self._xrReq = crossRegs
        self.xr = 0
        self._memOrgReport = None
        self.cgRot = 0
        if memOrg == 'constgeo':
            self._applyMemOrg('constgeo')
        # the modulus per polynomial (RNS): 'single' one q per job (load port, today's core), 'recycle' one
        # twiddle copy whose stage regions are rewritten for the next q as the current polynomial frees
        # them, 'double' a second copy; both take a per-polynomial record (header + twiddles) on a stream
        tb = twiddleBuffer
        if tb is None:
            tb = 'recycle' if (self.runtime and not self.twistOn) else 'single'
        if tb not in TWIDDLE_BUFFERS:
            raise ValueError(f'{name}: twiddleBuffer must be one of {TWIDDLE_BUFFERS}')
        if tb != 'single':
            if not self.runtime:
                raise ValueError(f"{name}: twiddleBuffer {tb!r} switches the modulus per polynomial: it needs a "
                                 f"run-time family=")
            if self.twistOn and memOrg == 'constgeo':
                raise ValueError(f"{name}: twiddleBuffer {tb!r} with the output twist (negacyclic inverse) is built "
                                 f"for the in-place organisation only")
        self.twiddleBuffer = tb
        self.rns = tb != 'single'
        if twiddleLanes is not None:
            if not self.rns:
                raise ValueError(f"{name}: twiddleLanes is for twiddleBuffer 'recycle' / 'double'")
            if twiddleLanes != 1 << (twiddleLanes.bit_length() - 1) or not 1 <= twiddleLanes <= B:
                raise ValueError(f'{name}: twiddleLanes must be a power of two in [1, B]')
        self._twLanes = twiddleLanes
        # the direction per polynomial (RNS, direction 'both'): a header bit instead of the DIR port; a record whose
        # direction differs from the polynomial before's carries its modulus again (keep False), so the switch
        # waits for the bubble like a modulus change
        if dirPerPoly and not (self.rns and direction == 'both'):
            raise ValueError(f"{name}: dirPerPoly needs a record stream (twiddleBuffer 'recycle' / 'double') and "
                             f"direction 'both'")
        self.dirPerPoly = bool(dirPerPoly)
        # the modulus switch at a polynomial boundary: 'bubble' waits until the butterflies are empty (`rnsBubble`),
        # then switches one set of constants; 'inline' starts the next polynomial at once: the butterflies take
        # the constants delay-balanced with the data (staticModulus False) and every consumer's copy switches
        # as that polynomial's first operation reaches it
        if qSwitch == 'inline':
            if not (self.rns or self.multiRom):
                raise ValueError(f"{name}: qSwitch 'inline' needs a record stream (twiddleBuffer 'recycle' / "
                                 f"'double')")
            # with dirPerPoly the header's direction bit travels with the constants (rtl_gen: DIR on the same delay
            # line), so a direction change needs no wait either (2026-11-17)
        self.qInline = qSwitch == 'inline'
        # twiddleSource 'rec' (a modulus per polynomial): the tables are written on chip. The record carries the
        # modulus constants, two factors per late stage and the entries of the first H+2 stage regions (shared
        # by all butterflies, two variants); groups of `recGroup` butterflies each run one modular multiplier
        # that derives the later regions stage by stage (`recUnits`; THEORY: IterativeNTTScheme.recUnits)
        self.rec = src == 'rec'
        self.recIp = self.rec and memOrg == 'inplace'      # in place: every region generated (`recIpPlan`)
        self.genMultiplier = None
        self._recReq = recGroup
        if self.rec:
            if tb != 'recycle':
                raise ValueError(f"{name}: twiddleSource 'rec' is built with twiddleBuffer 'recycle' (a modulus "
                                 f"per polynomial, one table copy)")
            # merge of iter_fixes (output twist and dirPerPoly with a record stream) and iterative_ntt ('rec'):
            # neither built these with 'rec' (the on-chip loader has no twist region and no direction bit)
            if self.twistOn:
                raise ValueError(f"{name}: twiddleSource 'rec' with the output twist (negacyclic inverse, "
                                 f"inverseScale 'output') is not built: the record has no twist region (use "
                                 f"twiddleSource 'ram')")
            if self.dirPerPoly:
                raise ValueError(f"{name}: twiddleSource 'rec' with dirPerPoly is not built: the direction stays "
                                 f"the DIR port, per job (use twiddleSource 'ram')")
            if memOrg not in ('constgeo', 'inplace'):
                raise ValueError(f"{name}: twiddleSource 'rec' needs the memory organisation given explicitly "
                                 f"(memOrg 'constgeo' or 'inplace')")
            if memOrg == 'inplace' and len(self.tdirs) != 1:
                raise ValueError(f"{name}: twiddleSource 'rec' in place generates one stored direction (one "
                                 f"direction, or a cyclic transform with shared inverse twiddles)")
            if self.shoup():
                raise ValueError(f"{name}: twiddleSource 'rec' does not build Shoup companions on chip")
            if B < 2:
                raise ValueError(f"{name}: twiddleSource 'rec' needs B >= 2")
            if twiddleLanes is not None:
                raise ValueError(f"{name}: twiddleLanes is for the streamed record ('ram'); 'rec' carries 2 a beat")
            gmax = B if memOrg == 'inplace' else B // 2
            if recGroup is not None and (recGroup != 1 << (recGroup.bit_length() - 1) or not 1 <= recGroup <= gmax):
                raise ValueError(f'{name}: recGroup must be a power of two in [1, {"B" if gmax == B else "B/2"}]')
        elif recGroup is not None:
            raise ValueError(f"{name}: recGroup is for twiddleSource 'rec'")
        # recSeeds ('rec' in place): the first K entries of every generator group's stage region arrive on the
        # record stream at the start of that stage's units instead of being computed (no chain, fewer doubling
        # rounds: short stages). 0: none (the record is its header alone); 'auto': `_recChoice`
        self._seedReq = recSeeds or 0
        if self._seedReq:
            if not self.recIp:
                raise ValueError(f"{name}: recSeeds is for twiddleSource 'rec' in place (memOrg 'inplace', "
                                 f"twiddleBuffer 'recycle')")
            if recSeeds != 'auto' and (isinstance(recSeeds, bool) or not isinstance(recSeeds, int) or recSeeds < 1
                                       or recSeeds & (recSeeds - 1)):
                raise ValueError(f"{name}: recSeeds must be 0, 'auto' or a power of two K with 1 <= K <= the "
                                 f"generators' store depth (recIpPlan()['SD'])")
        # recMultiplier: arguments for the generators' modular multipliers over the butterflies' (e.g.
        # {'multiplier': 'booth', 'qBackend': 'booth'}: on LUTs)
        if recMultiplier is not None and not self.rec:
            raise ValueError(f"{name}: recMultiplier is for twiddleSource 'rec'")
        self.recMulArgs = dict(recMultiplier or {})
        # fanout: register trees for the wide broadcasts (bank and table addresses, enables, set selects, the
        # fill, the drain selects, the modulus constants, the generators' operands), each register driving at
        # most `fanout` loads; depths from the fan-out alone (`fanoutPlan`). None: off (the core as before)
        if fanout is not None:
            if fanout < 2:
                raise ValueError(f'{name}: fanout >= 2')
            if memOrg != 'constgeo':
                raise ValueError(f"{name}: fanout trees are built for memOrg 'constgeo' (give it explicitly)")
            if tb == 'double' or (tb == 'recycle' and not self.rec):
                raise ValueError(f"{name}: fanout trees with twiddleBuffer {tb!r} are not built ('single', or "
                                 f"'recycle' with twiddleSource 'rec')")
        self.fanout = fanout
        # fanoutKeepSinks: also keep (no merging of) the per-bank / per-port / per-butterfly registers the trees
        # feed. False: only the tree registers are kept (Vivado may merge equal sinks under one leaf; at I2's size,
        # n 8192 B 512, keeping every sink made synthesis's technology mapping run for hours)
        self.fanoutKeep = bool(fanoutKeepSinks)
        # fanoutLoads: what a bank sink costs a tree register. 'register' (one load: the sink's own register),
        # 'pins' (the pins the signal reaches in a bank: the write data register's W enables, the address, the
        # write enable), so the leaves serve fewer banks
        if fanoutLoads not in ('register', 'pins'):
            raise ValueError(f"{name}: fanoutLoads 'register' or 'pins'")
        self.fanoutLoads = fanoutLoads

    # --- geometry: banks, rows, the order of a stage -----------------------------------

    def bank(self, m: int) -> int:
        return (m & (2 * self.B - 1)) ^ (_par(m >> (self.b + 1)) << self.b)

    def addr(self, m: int) -> int:
        return m >> (self.b + 1)

    def pair(self, s: int, t: int, j: int) -> tuple[int, int]:
        '''Memory indices (A, B) of butterfly j at cycle t of stage s.'''
        if self.memOrg == 'constgeo':
            return self.cgPair(s, t, j)
        b = self.b
        if s <= b:
            mA = (t << (b + 1)) | _ins(j, s, 0)
        else:
            p = s - b - 1
            mA = (_ins(t >> 1, p, 0) << (b + 1)) | ((t & 1) << b) | j
        return mA, mA | (1 << s)

    def cycleOf(self, s: int, m: int) -> int:
        '''The cycle of stage s that reads point m.'''
        if self.memOrg == 'constgeo':
            return _rotl(self.cgPos(s, m) >> (self.b + 1), self.cgShift(s), self.H)
        b = self.b
        h = m >> (b + 1)
        if s <= b:
            return h
        return (_rem(h, s - b - 1) << 1) | ((m >> b) & 1)

    def flip(self, s: int, t: int) -> int:
        '''The bank top bit of butterfly operands A in cycle t of stage s (the RTL's `flip`).'''
        b = self.b
        if s <= b:
            return _par(t)
        return (t & 1) ^ _par(_ins(t >> 1, s - b - 1, 0))

    def rowAddrs(self, s: int, t: int) -> tuple[int, int]:
        '''(hA, hB): the rows of A and B (equal for stages s <= b).'''
        b = self.b
        if s <= b:
            return t, t
        hA = _ins(t >> 1, s - b - 1, 0)
        return hA, hA | (1 << (s - b - 1))

    def readBanks(self, s: int, t: int, j: int) -> tuple[int, int]:
        '''Banks of A and B of butterfly j, as the RTL selects them from (s, flip).'''
        b, B, f = self.b, self.B, self.flip(s, t)
        if s <= b:
            return _ins(j, s, 0) ^ (f << b), _ins(j, s, 1) ^ (f << b)
        return j + B * f, j + B * (1 - f)

    def bankAddr(self, s: int, t: int, k: int) -> int:
        '''Read (= write-back) address of bank k in cycle t of stage s.'''
        hA, hB = self.rowAddrs(s, t)
        top = k >> self.b
        return hB if (top ^ self.flip(s, t)) else hA

    def twiddleIndex(self, s: int, t: int) -> tuple[str, int]:
        '''Where every butterfly's twiddle is in cycle t of stage s (one direction):
        ('c', s) in the stage-constant table for s <= b (the twiddle does not change
        over the stage), ('t', 2^(p+1) - 2 + (t mod 2^(p+1))) in the table for
        s = b+1+p. Every entry is used once: 2^(H+1) - 2 + b + 1 per direction.'''
        b = self.b
        if s <= b:
            return 'c', s
        p = s - b - 1
        return 't', (1 << (p + 1)) - 2 + (t & ((2 << p) - 1))

    def ioBank(self, beat: int, lane: int) -> tuple[int, int]:
        '''(bank, address) of lane `lane` of I/O beat `beat` (memory index beat*io + lane).'''
        m = beat * self.io + lane
        return self.bank(m), self.addr(m)

    # --- constant geometry (memOrg 'constgeo') --------------------------------------------

    def _applyMemOrg(self, org: str) -> None:
        '''Set the organisation and what follows from it (tables, shared inverse twiddles, caches).'''
        self.memOrg = org
        self._qCache = {}
        if org == 'constgeo':
            self.shareInv = False
            self.tdirs = list(self.dirs)
            H, T = self.H, self.T
            self.cgDepths = [(1 << s) if s <= H else T for s in range(self.L)]
            self.cgBases = [sum(self.cgDepths[:s]) for s in range(self.L)]
            self.tdepth = sum(self.cgDepths)
            self.cdepth = 0
        else:
            self.xr = 0
            can = self.direction == 'both' and not self.negacyclic
            self.shareInv = can if self._shareReq is None else bool(self._shareReq)
            self.tdirs = ['fwd'] if self.shareInv else list(self.dirs)
            self.tdepth = (1 << (self.H + 1)) - 2
            self.cdepth = self.b + 1

    # --- 'auto': the cost model that picks the organisation ------------------------------

    _ORG_ATTRS = ('memOrg', 'shareInv', 'tdirs', 'tdepth', 'cdepth', 'cgRot', '_qCache', 'cgDepths', 'cgBases', 'xr')

    @contextlib.contextmanager
    def asMemOrg(self, org: str):
        """Evaluate the scheme as organisation `org` (geometry, tables, resources), then restore."""
        saved = {k: getattr(self, k, None) for k in self._ORG_ATTRS}
        try:
            self._applyMemOrg(org)
            if org == 'constgeo' and getattr(self, '_bu', None) is not None:
                self._setCrossRegs()
                self._bestRot()
            yield self
        finally:
            for k, v in saved.items():
                setattr(self, k, v)

    def meshHypergraph(self) -> tuple[list, list, list, float]:
        """The bank <-> butterfly network as a hypergraph for slrmodel.minCut, in buses (a W-bit bus per net,
        weight = the bank sets it stands for): (node weights, nets, structured starts for a = 1/2, a).
        Nodes: butterflies 0..B-1, bank groups B..3B-1 (bank k of every set), input lanes, output lanes."""
        B, b, io = self.B, self.b, self.io
        nb, nI = B, 3 * B
        nO = nI + io
        nw = [1.0] * B + [0.05] * (2 * B) + [0.0] * (2 * io)
        nets = []
        outLanes = lambda k: sorted({k % io, (k ^ B) % io})
        if self.memOrg == 'constgeo':
            for k in range(2 * B):
                nets.append((3, [nb + k, k >> 1] + [nO + l for l in outLanes(k)]))
            for kk in range(B):
                for e in (0, 1):
                    if b:
                        sinks = [kk + B * e, (kk ^ (B >> 1)) + B * (1 - e)]
                    else:
                        sinks = [0, 1]
                    nets.append((1, [kk] + [nb + x for x in sorted(set(sinks))]))
            home = lambda k: k >> 1
        else:
            rs, ws = self.readSources()
            readers = [set() for _ in range(2 * B)]
            for p_, ks in enumerate(rs):
                for k in ks:
                    readers[k].add(p_ // 2)
            for k in range(2 * B):
                nets.append((2, [nb + k] + sorted(readers[k]) + [nO + l for l in outLanes(k)]))
            srcs = {}
            for k, js in enumerate(ws):
                for jo in js:
                    srcs.setdefault(jo, []).append(nb + k)
            for (j, o), ks in sorted(srcs.items()):
                nets.append((1, [j] + ks))
            home = lambda k: k % B
        for l in range(io):
            nets.append((1, [nI + l] + [nb + k for k in range(2 * B) if (k % io) == l or ((k ^ B) % io) == l]))
        return nw, nets, home, 0.5

    def meshStarts(self, home, a: float) -> list:
        '''Structured starts for the min cut: the butterflies ordered by their index with bit i on top (every
        i), by the index and by its bit reversal; the first a x B go to side 0, each bank with its home
        butterfly, the lanes alternating.'''
        B, b, io = self.B, self.b, self.io
        keys = [lambda j: j, lambda j: int(format(j, f'0{max(1, b)}b')[::-1], 2)]
        keys += [(lambda i: (lambda j: (((j >> i) & 1) << b) | j))(i) for i in range(b)]
        out = []
        for key in keys:
            order = sorted(range(B), key=key)
            sideB = [1] * B
            for j in order[:max(1, round(a * B))]:
                sideB[j] = 0
            out.append(sideB + [sideB[home(k)] for k in range(2 * B)] + [l & 1 for l in range(io)] * 2)
        return out

    def slrCrossings(self, span: int) -> dict:
        """The estimated SLL use at the worst SLR boundary (slrmodel): min cut in buses x W x CAL."""
        from . import slrmodel as SM
        if span <= 1:
            return {'cutBuses': 0, 'crossings': 0}
        nw, nets, home, _ = self.meshHypergraph()
        a = 1.0 / min(span, 3)
        starts = self.meshStarts(home, a)
        key = (self.memOrg, self.n, self.B, self.io, round(a, 3))
        cut = SM.minCut(key, nw, nets, a, starts)
        W = self.memBound.bitWidth
        return {'cutBuses': cut, 'crossings': round(SM.calibration(self.memOrg) * W * cut)}

    def muxLevels(self) -> dict:
        """LUT6 levels on the operand path (RAM -> register) and the write path (butterfly register -> bank write
        register): a 4:1 per LUT6 level."""
        lv = lambda k: 0 if k <= 1 else math.ceil(math.log(k, 4) - 1e-9)
        if self.memOrg == 'constgeo':
            return {'operand': lv(3) + (1 if self.b == 0 else 0), 'write': lv(3)}
        rs, ws = self.readSources()
        return {'operand': lv(2 * max(len(x) for x in rs)), 'write': lv(max(len(x) for x in ws) + 1)}

    def memOrgReport(self, pipelineStages=1) -> dict:
        """'auto': both organisations estimated and the choice, with its reasons.

        Per organisation: resources (`resources`, the mux terms from the measured N:1 x W mux table when
        ntt_hw/experiments/iterative/muxcost/results.csv exists, else the LUT6 formula), cycles per polynomial
        (max(compute (+ the RNS bubble), n / io)), the ATP-style score (AutoNTT's area units kLUT + kFF + DSP +
        BRAM36 + 8 URAM, times the cycles: the clock cancels at an equal target), the mux levels, the SLRs the
        resources need (slrmodel.slrSpan) and the SLL use at the worst boundary (slrmodel: calibrated min cut).
        Rule: in place, unless it does not fit (crossings > 0.9 x the router's limit) and constant geometry does,
        or constant geometry is clearly cheaper (score < 0.9 x in place's); when the in-place estimate is unsure
        (0.7 .. 1.1 x the limit) the fallback is constant geometry for B >= 256."""
        if self._memOrgReport is not None:
            return self._memOrgReport
        from . import slrmodel as SM
        muxLut, muxSrc = SM.muxModel()
        rep = {'orgs': {}, 'muxSource': muxSrc}
        rtw = self.rns and self.twistOn            # built for in place only: constant geometry is not evaluated
        for org in (('inplace',) if rtw else ('inplace', 'constgeo')):
            with self.asMemOrg(org):
                r = self.resources(pipelineStages, muxLut=muxLut)
                cc = self.computeCycles(pipelineStages) + (self.rnsBubble(pipelineStages) if (self.rns or self.multiRom) else 0)
                cyc = max(cc, self.beats)
                area = (r['lut'] / 1000 + r['ff'] / 1000 + r['dsp'] + r['bram'] + 8 * r['uram']) / 5
                span = SM.slrSpan(r)
                x = self.slrCrossings(span)
                rep['orgs'][org] = dict(lut=r['lut'], ff=r['ff'], dsp=r['dsp'], bram=r['bram'], uram=r['uram'],
                                        mux=r['breakdown']['read mux'] + r['breakdown']['write mux'] +
                                        r['breakdown']['output mux'], cycles=cyc, area=round(area, 1),
                                        score=round(area * cyc), levels=self.muxLevels(), span=span, **x,
                                        twiddleWords=self.twiddleWords(),
                                        recordBits=(self.twiddleLanes(pipelineStages) * self.twEntryWidth()
                                                    if self.rns else 0))
        if rtw:
            rep.update(choice='inplace', reason='output twist with a record stream (built for in place only)')
            self._memOrgReport = rep
            return rep
        ip, cg = rep['orgs']['inplace'], rep['orgs']['constgeo']
        lim = SM.SLL_LIMIT
        fits = lambda o: o['span'] <= 3 and o['crossings'] <= 0.9 * lim
        unsure = 0.7 * lim <= ip['crossings'] <= 1.1 * lim
        if self._shareReq:
            choice, why = 'inplace', 'shared inverse twiddles requested (in place only)'
        elif unsure:
            choice, why = ('constgeo' if self.B >= 256 else 'inplace'), (
                f"in-place SLL estimate {ip['crossings']} within 0.7-1.1 x the limit {lim}: fallback "
                f"(constant geometry for B >= 256)")
        elif not fits(ip) and cg['crossings'] < ip['crossings'] and cg['span'] <= 3:
            choice, why = 'constgeo', (f"in place does not fit: {ip['crossings']} SLLs (limit {lim}) over "
                                       f"{ip['span']} SLRs; constant geometry {cg['crossings']}"
                                       + ('' if fits(cg) else ' (above the limit too: the better of two risks)'))
        elif cg['score'] < 0.9 * ip['score'] and fits(cg):
            choice, why = 'constgeo', f"constant geometry cheaper: score {cg['score']} vs {ip['score']}"
        else:
            choice, why = 'inplace', (f"in place fits ({ip['crossings']} SLLs, {ip['span']} SLR) and is not "
                                      f"clearly costlier (score {ip['score']} vs constant geometry {cg['score']})")
        rep.update(choice=choice, reason=why)
        self._memOrgReport = rep
        return rep

    def numSets(self) -> int:
        '''Data bank sets: in place 2 (compute + I/O); constant geometry 3 (ping-pong + I/O).'''
        return 3 if self.memOrg == 'constgeo' else 2

    def nextSet(self, x: int) -> int:
        '''The set the next polynomial is filled into (and computed from), after set x. In place: the
        other one. Constant geometry, L even: sets 0 and 2 alternate, set 1 is every polynomial's
        scratch; L odd: the roles rotate (x -> x + 2 mod 3; scratch x + 1, which holds the result).'''
        if self.memOrg != 'constgeo':
            return x ^ 1
        return x ^ 2 if self.L % 2 == 0 else (x + 2) % 3

    def scratchSet(self, x: int) -> int:
        '''Constant geometry: the ping-pong partner of input set x (stages s odd read it).'''
        return 1 if self.L % 2 == 0 else (x + 1) % 3

    def resultSet(self, x: int) -> int:
        '''The set that holds the result of the polynomial computed from set x (drained from).'''
        if self.memOrg != 'constgeo':
            return x
        return x if self.L % 2 == 0 else self.scratchSet(x)

    def cgShift(self, s: int) -> int:
        '''Stage s reads row rotr_H(c, cgShift(s)) in cycle c (rotate right by (s + cgRot) mod H).'''
        return (s + self.cgRot) % self.H if self.H else 0

    def cgRow(self, s: int, c: int) -> int:
        return _rotr(c, self.cgShift(s), self.H)

    def cgPos(self, s: int, m: int) -> int:
        '''Position (bank map input) of memory index m before stage s: rotr_L(m, s); stage s pairs
        positions (p, p+1), p even, and writes them to rotr(p) = p >> 1 and (p >> 1) + n/2.'''
        return _rotr(m, s, self.L)

    def cgPair(self, s: int, c: int, k: int) -> tuple[int, int]:
        '''Memory indices (A, B) of butterfly k in cycle c of stage s. Row r = cgRow(s, c), pi its
        parity: butterfly k reads banks 2k, 2k+1 (B = 1: banks pi, 1 - pi) at address r, i.e. the
        positions 2B r + 2i, +1 with i = k xor pi B/2.'''
        b = self.b
        r = self.cgRow(s, c)
        pi = _par(r)
        i = k ^ (pi << (b - 1)) if b else 0
        pA = (r << (b + 1)) | (2 * i)
        return _rotl(pA, s, self.L), _rotl(pA | 1, s, self.L)

    def cgWrite(self, s: int, c: int, k: int) -> tuple[tuple[int, int], tuple[int, int]]:
        '''((bank, address) of output X, of output Y) of butterfly k in cycle c of stage s, as the RTL
        forms them: bank i + B (pi xor e), address (r >> 1) + e T/2 (e = 0 for X = a + wb, 1 for Y).'''
        B, b = self.B, self.b
        r = self.cgRow(s, c)
        pi = _par(r)
        i = k ^ (pi << (b - 1)) if b else 0
        return ((i + B * pi, r >> 1), (i + B * (1 - pi), (r >> 1) + self.T // 2))

    def cgReadBanks(self, s: int, c: int, k: int) -> tuple[int, int]:
        if self.b:
            return 2 * k, 2 * k + 1
        pi = _par(self.cgRow(s, c))
        return pi, 1 - pi

    def cgWriteSource(self, bank: int, pi: int) -> tuple[int, int]:
        '''(butterfly, output) that writes bank `bank` in a cycle of row parity pi (the 2:1 write mux).'''
        B, b = self.B, self.b
        k = (bank % B) ^ ((pi << (b - 1)) if b else 0)
        return k, (bank >> b) ^ pi

    def cgTwiddleIndex(self, s: int, c: int) -> int:
        '''Entry (one direction) of every butterfly's twiddle in cycle c of stage s: stage s owns the region
        [cgBases[s], + cgDepths[s]); stages s <= H: the top s bits of the row (the twiddle depends only
        on them), s > H: the row (it then also depends on the butterfly: one table per butterfly).'''
        r = self.cgRow(s, c)
        return self.cgBases[s] + (r >> (self.H - s) if s <= self.H else r)

    def _setCrossRegs(self) -> None:
        '''crossRegs for constant geometry: as asked, else 0 (off by default). 2 (one register per SLR boundary;
        Vivado placed the 2-SLR estimate of I3 over all three) is the value of the ablation rows.'''
        # off by default (user decision 2026-11-09: no V80-specific die-crossing tuning on the comparison images);
        # crossRegs=k turns it on (the ablation 'die-crossing registers')
        self.xr = self._xrReq if self._xrReq is not None else 0
        self._qCache = {}

    def _bestRot(self, pipelineStages=1) -> int:
        '''The read-order rotation with the fewest compute cycles (ties: 0).'''
        if not self.H:
            return 0
        best = None
        for k in range(self.H):
            self.cgRot = k
            self._qCache = {}
            cc = self.computeCycles(pipelineStages)
            if best is None or cc < best[0]:
                best = (cc, k)
        self.cgRot = best[1]
        self._qCache = {}
        return best[1]

    def _checkGeometryCg(self) -> list[str]:
        errs = []
        n, B, b, T, L = self.n, self.B, self.b, self.T, self.L
        loc = {(self.bank(m), self.addr(m)) for m in range(n)}
        if len(loc) != n:
            errs.append('bank/address is not a bijection')
        for s in range(L):
            seen = set()
            for c in range(T):
                r = self.cgRow(s, c)
                pi = _par(r)
                rb, wb = [], []
                for k in range(B):
                    mA, mB = self.cgPair(s, c, k)
                    if mB != mA | (1 << s) or (mA >> s) & 1:
                        errs.append(f'stage {s} cycle {c} bu {k}: not a stage-{s} pair')
                    for m in (mA, mB):
                        if self.cycleOf(s, m) != c:
                            errs.append(f'stage {s} cycle {c}: cycleOf disagrees')
                    ka, kb = self.cgReadBanks(s, c, k)
                    pA, pB = self.cgPos(s, mA), self.cgPos(s, mB)
                    if (ka, kb) != (self.bank(pA), self.bank(pB)) or self.addr(pA) != r or self.addr(pB) != r:
                        errs.append(f'stage {s} cycle {c} bu {k}: read banks / address')
                    (bx, ax), (by, ay) = self.cgWrite(s, c, k)
                    if s + 1 <= L:
                        qx, qy = self.cgPos(s + 1, mA), self.cgPos(s + 1, mB)
                        if (bx, ax) != (self.bank(qx), self.addr(qx)) or (by, ay) != (self.bank(qy), self.addr(qy)):
                            errs.append(f'stage {s} cycle {c} bu {k}: write bank / address')
                    if self.cgWriteSource(bx, pi) != (k, 0) or self.cgWriteSource(by, pi) != (k, 1):
                        errs.append(f'stage {s} cycle {c} bu {k}: write mux source')
                    rb += [ka, kb]
                    wb += [bx, by]
                    seen |= {mA, mB}
                if len(set(rb)) != 2 * B or len(set(wb)) != 2 * B:
                    errs.append(f'stage {s} cycle {c}: bank conflict')
            if len(seen) != n:
                errs.append(f'stage {s}: does not cover every point')
            if len(errs) > 20:
                return errs
        if any(self.cgPos(L, m) != m for m in range(n)):
            errs.append('the last stage does not leave memory order')
        for beat in range(self.beats):
            ks = [self.ioBank(beat, l)[0] for l in range(self.io)]
            if len(set(ks)) != self.io or len({self.ioBank(beat, l)[1] for l in range(self.io)}) != 1:
                errs.append(f'I/O beat {beat}: conflict')
        return errs

    def checkGeometry(self) -> list[str]:
        '''Every stage reads 2B distinct banks per cycle at the addresses the RTL forms,
        covers every pair once, and the I/O beats are conflict-free; (bank, address)
        is a bijection.'''
        if self.memOrg == 'constgeo':
            return self._checkGeometryCg()
        errs = []
        n, B = self.n, self.B
        loc = {(self.bank(m), self.addr(m)) for m in range(n)}
        if len(loc) != n:
            errs.append('bank/address is not a bijection')
        for s in range(self.L):
            seen = set()
            for t in range(self.T):
                banks = []
                for j in range(B):
                    mA, mB = self.pair(s, t, j)
                    if self.cycleOf(s, mA) != t or self.cycleOf(s, mB) != t:
                        errs.append(f'stage {s} cycle {t}: cycleOf disagrees')
                    ba, bb = self.readBanks(s, t, j)
                    if (ba, bb) != (self.bank(mA), self.bank(mB)):
                        errs.append(f'stage {s} cycle {t} bu {j}: banks {ba},{bb} != {self.bank(mA)},{self.bank(mB)}')
                    for m, k in ((mA, ba), (mB, bb)):
                        if self.bankAddr(s, t, k) != self.addr(m):
                            errs.append(f'stage {s} cycle {t} bank {k}: address')
                    banks += [ba, bb]
                    seen |= {mA, mB}
                if len(set(banks)) != 2 * B:
                    errs.append(f'stage {s} cycle {t}: bank conflict')
            if len(seen) != n:
                errs.append(f'stage {s}: does not cover every point')
            if len(errs) > 20:
                return errs
        for beat in range(self.beats):
            ks = [self.ioBank(beat, l)[0] for l in range(self.io)]
            if len(set(ks)) != self.io or len({self.ioBank(beat, l)[1] for l in range(self.io)}) != 1:
                errs.append(f'I/O beat {beat}: conflict')
        return errs

    # --- the schedule: when each stage starts ------------------------------------------

    def buLatency(self, pipelineStages=1) -> int:
        return self.butterflyUnit().latency(pipelineStages)

    def writeLatency(self, pipelineStages=1) -> int:
        '''Pw: cycles from a read's issue to its write-back edge: address register, R
        RAM cycles, operand mux register, the butterfly, its output (halver) register,
        the write mux register.'''
        return self.Rx() + self.buLatency(pipelineStages) + 4 + 2 * self.xr

    def Rx(self) -> int:
        '''Read latency as the schedule sees it: the RAMs' R plus the read-side fan-out tree (`readTree`).'''
        return self.R + self.readTree()

    # --- fan-out trees (fanout=) ----------------------------------------------------------

    def treeLevels(self, N: int, load: int = 1) -> list[int]:
        '''Registers per level (source side first) of a tree feeding N sinks of `load` loads each, every
        register driving at most `fanout` loads; [] when the source can drive them all.'''
        F = self.fanout
        if not F or N * load <= F:
            return []
        lv = [min(N, -(-N * load // F))]
        while lv[0] > F:
            lv.insert(0, -(-lv[0] // F))
        return lv

    def fanoutPlan(self, pipelineStages=1) -> dict:
        '''The trees (fanout=): {name: dict(N, load, width, levels, kind)}. kind 'read' (its depth delays the
        reads: `readTree` = the deepest, the others padded to it), 'tap' (taken earlier from a delay chain that
        exists: no cycle changes), 'static' (quasi-static values), 'group' (the generators' operands: adds to
        `genLatency`). Depths from the counts alone, no device data.'''
        if not self.fanout:
            return {}
        key = ('fan', pipelineStages, id(getattr(self, '_bu', None)))
        if key in self._qCache:
            return self._qCache[key]
        P = dict(self._fanBase())
        if self.rec and self.L > self.H + 2:
            G = self.recGroup(pipelineStages)
            NG = self.B // G
            E = self.twEntryWidth()
            SA = 1 + max(0, G.bit_length() - 2) + self.H
            TA = max(1, (self.tdepth * self.twDirs() - 1).bit_length())
            Bw = self.genPortWidths()['B']
            for nm, N, width, kind in (('generator operands', NG, SA + 2 + 2 * Bw, 'group'),
                                       ('generator writes', NG, 2 + 2 * E + 1 + SA, 'tap'),
                                       ('table writes', self.B, TA + 3 + G, 'tap'),
                                       ('generator constants', NG, sum(w for _, w in self.qPortWidths()), 'static')):
                P[nm] = dict(N=N, load=1, width=width, levels=self.treeLevels(N), kind=kind)
        self._qCache[key] = P
        return P

    def _fanBase(self) -> dict:
        '''The trees that do not depend on the twiddle generators (`fanoutPlan`).'''
        key = ('fanb', id(getattr(self, '_bu', None)))
        if key in self._qCache:
            return self._qCache[key]
        B, H, io = self.B, self.H, self.io
        W = self.memBound.bitWidth if hasattr(self, 'memBound') else 1
        lsub = (2 * B // io).bit_length() - 1
        TA = max(1, (self.tdepth * self.twDirs() - 1).bit_length())
        P = {}

        def add(nm, N, width, kind, load=1):
            P[nm] = dict(N=N, load=load, width=width, levels=self.treeLevels(N, load), kind=kind)
        pins = self.fanoutLoads == 'pins'
        add('bank read', 6 * B, 2 + H + 1 + 2 + H + 1, 'read', load=(H + 1) if pins else 1)
        add('twiddle address', B, TA, 'read')
        add('fill', 6 * B, 1 + 2 + H + 1 + max(1, lsub), 'read', load=(W + H + 2) if pins else 1)
        nl = len({(k % io) for k in range(2 * B)})
        per = 3 * sum(1 for k in range(2 * B) if (k % io) == 0 or ((k ^ B) % io) == 0)
        add('fill data', per, W, 'read')
        P['fill data']['copies'] = nl
        add('bank write', 6 * B, 1 + 2 + 1 + H, 'tap', load=(W + H + 2) if pins else 1)
        add('write select', 2 * B, 1, 'tap', load=3 * W)
        add('read select', 2 * B, 2, 'tap', load=W)
        add('drain select', 2 * B, 2, 'tap', load=W)
        add('output select', io, max(1, lsub) + 1, 'tap', load=W)
        if self.runtime:
            add('modulus constants', B, sum(w for _, w in self.qPortWidths()) if self.rns else
                sum(self.rnsExtWidths().get(p, self.qMax().bit_length()) for p in self.qPorts()), 'static')
        if self.stageHalve and self.direction == 'both':
            add('direction', 2 * B, 1, 'static', load=W)
        self._qCache[key] = P
        return P

    def readTree(self) -> int:
        '''Extra read latency of the fan-out trees: the deepest 'read' tree (0 without fanout).'''
        if not self.fanout:
            return 0
        return max([len(t['levels']) for t in self._fanBase().values() if t['kind'] == 'read'] or [0])

    def genTree(self, G: int | None = None) -> int:
        '''Levels of the generator-operand tree (B / G groups).'''
        if not self.fanout or not self.rec:
            return 0
        return len(self.treeLevels(self.B // (G or self.recGroup())))

    def fanoutRegisters(self, pipelineStages=1) -> int:
        '''Flip-flops of the trees (read trees padded to `readTree`).'''
        ff = 0
        dr = self.readTree()
        for t in self.fanoutPlan(pipelineStages).values():
            lv = list(t['levels'])
            if t['kind'] == 'read':
                lv = [1] * (dr - len(lv)) + lv
            ff += t['width'] * sum(lv) * t.get('copies', 1)
        return ff

    def stageLate(self, s: int) -> int:
        '''max over points of (cycle in stage s) - (cycle in stage s+1).'''
        key = ('late', s)
        if key not in self._qCache:
            self._qCache[key] = max(self.cycleOf(s, m) - self.cycleOf(s + 1, m) for m in range(self.n))
        return self._qCache[key]

    def stageOffsets(self, pipelineStages=1) -> list[int]:
        '''d_s: cycles from stage s's first issue to stage s+1's (s < L-1): the T cycles
        of the stage, or more where a point would be read before its write-back.'''
        pw = self.writeLatency(pipelineStages)
        return [max(self.T, pw + self.stageLate(s)) for s in range(self.L - 1)]

    def computeCycles(self, pipelineStages=1) -> int:
        '''Butterfly cycles of one polynomial, first issue to last issue + 1.'''
        return sum(self.stageOffsets(pipelineStages)) + self.T

    def checkHazards(self, pipelineStages=1) -> list[str]:
        '''Every point is read by stage s+1 at least Pw cycles after stage s read it
        (so after its write-back edge), and no bank is read and written at one
        address on the same edge.'''
        pw = self.writeLatency(pipelineStages)
        d = self.stageOffsets(pipelineStages)
        S = [0]
        for x in d:
            S.append(S[-1] + x)
        errs = []
        for s in range(self.L - 1):
            for m in range(self.n):
                gap = S[s + 1] + self.cycleOf(s + 1, m) - S[s] - self.cycleOf(s, m)
                if gap < pw:
                    errs.append(f'stage {s}->{s + 1} point {m}: read {gap} cycles after, needs {pw}')
                    break
        if self.memOrg == 'constgeo':
            # ping-pong: stage s writes the set stage s-1 read; every position is written (edge issue + Pw)
            # at least two edges after its read there (address register, RAM read edge), so a write never
            # lands before the read it replaces. (Across polynomials: the next one starts after the last
            # issue, its first writes come Pw later, after every read of the set it reuses.)
            for s in range(1, self.L):
                for p in range(self.n):
                    mOld = _rotl(p, s - 1, self.L)          # the point stage s-1 read at position p
                    mNew = _rotl(p, s + 1, self.L)          # the point stage s writes there
                    rd = S[s - 1] + self.cycleOf(s - 1, mOld)
                    wr = S[s] + self.cycleOf(s, mNew) + pw
                    if wr < rd + 2 + self.readTree():
                        errs.append(f'stage {s} position {p}: written at {wr}, read by stage {s - 1} at {rd}')
                        break
        if self.rns:
            # the twiddle regions and the modulus switch, on twin jobs: a new q every polynomial, and kept
            # moduli in between, with the record stream stalling
            rnd = random.Random(self.n + self.B)
            pat = [rnd.random() < 0.6 for _ in range(4093)]
            for recs, tv in (([False] * 4, None), ([False, True, False, True, False], lambda c: pat[c % 4093])):
                job = self.simulateJob(len(recs), pipelineStages=pipelineStages, records=recs, twValid=tv)
                errs += self.checkTwiddleWindows(job, pipelineStages)
                errs += self.checkSets(job, pipelineStages)
            # a record stream that starts late and stalls hard: compute starts are held back while the
            # input keeps filling (the case that needs the constgeo set reservation at the fill's end)
            slow = lambda c: c > 300 and c % 7 == 0
            job = self.simulateJob(5, pipelineStages=pipelineStages, records=[False] * 5, twValid=slow)
            errs += self.checkTwiddleWindows(job, pipelineStages) + self.checkSets(job, pipelineStages)
        else:
            errs += self.checkSets(self.simulateJob(4, pipelineStages=pipelineStages), pipelineStages)
            rnd = random.Random(self.n + 3 * self.B)
            pat = [rnd.random() < 0.5 for _ in range(4093)]
            errs += self.checkSets(self.simulateJob(4, lambda c: pat[c % 4093], pipelineStages), pipelineStages)
        return errs

    # --- butterflies, twist -------------------------------------------------------------

    def butterflyUnit(self):
        '''The one butterfly module (twiddle input), built for the memory's bound.'''
        if getattr(self, '_bu', None) is None:
            raise ValueError(f'{self.name}: set the input bound first (setInputBound)')
        return self._bu

    def _makeBu(self, bound: IntType):
        from ..butterfly.ButterflyScheme import ModularBU
        fam = dict(family=self.family) if self.runtime else dict(q=self.q)
        bu = ModularBU(name=f'{self.name}_bu', butterflyType='CT', twiddleInput=True,
                       targetFmaxMhz=self.targetFmaxMhz, **fam,
                       **{**self._buArgs(), **(dict(staticModulus=False) if self.qInline else {})})
        bu.aIn = bu.bIn = bound
        if self._dspPlan:
            bu.dspBudgets = self._dspPlan.get('bu')
        return bu

    def propagateBound(self):
        '''The memory word's bound: the input bound widened until the butterfly maps
        it into itself (in place, every stage reads what the previous one wrote).'''
        b = self.inputBound
        for _ in range(6):
            bu = self._makeBu(b)
            x, y = bu.propagateBound()
            nb = IntType(min(b.minValue, x.minValue, y.minValue), max(b.maxValue, x.maxValue, y.maxValue))
            if nb.minValue == b.minValue and nb.maxValue == b.maxValue:
                break
            b = nb
        else:
            raise ValueError(f'{self.name}: the butterfly output bound does not settle (lazy ranges diverge)')
        self.memBound = b
        self._bu = bu
        self.twistMultiplier = None
        if self.twistOn:
            # (moduli=: the drained polynomial's constants travel with its data, so drains stay back to back)
            self.twistMultiplier = self._multiplier(f'{self.name}_twist', b,
                                                    **(dict(staticModulus=False) if self.multiRom else {}))
            self.outputBound = self.twistMultiplier.propagateBound()
        else:
            self.outputBound = b
        if self.rec:
            self.genMultiplier = self._multiplier(f'{self.name}_gen', IntType(0, self.qMax() - 1), **self.recMulArgs)
            self._genPorts = None
        if self.memOrgRequest == 'auto':
            self._memOrgReport = None
            self._applyMemOrg(self.memOrgReport()['choice'])
        elif self.memOrg == 'constgeo':
            self._qCache = {}
        if self.memOrg == 'constgeo':
            self._setCrossRegs()
            self._bestRot()
        return self.outputBound

    def setInputBound(self, b: IntType) -> None:
        self.inputBound = b
        self.propagateBound()

    def qPorts(self) -> tuple[str, ...]:
        if not self.runtime:
            return ()
        names = [p for p in self.butterflyUnit().portNames() if p not in ('W', 'WP')]
        if self.twistMultiplier is not None:
            names += [p for p in self.twistMultiplier.qPorts() if p not in names]
        if self.stageHalve:
            names.append('QHALF')
        if self.genMultiplier is not None:
            names += [p for p in self.genMultiplier.qPorts() if p not in names]
        return tuple(names)

    def qPortValues(self, q: int) -> dict:
        vals = dict(self.butterflyUnit().qPortValues(q))
        if self.twistMultiplier is not None:
            vals.update(self.twistMultiplier.qPortValues(q))
        if self.genMultiplier is not None:
            for k, v in self.genMultiplier.qPortValues(q).items():
                if k in vals and vals[k] != v:
                    raise AssertionError(f'{self.name}: the generator and the butterflies disagree on {k}')
                vals[k] = v
        if self.stageHalve:
            vals['QHALF'] = (q + 1) // 2
        return {p: vals[p] for p in self.qPorts()}

    # --- tables ------------------------------------------------------------------------

    def twiddleTable(self, j: int, q: int, which: str = 't', direction: str | None = None) -> tuple[list[int], list[int] | None]:
        '''Butterfly j's twiddle table (`which` 't') or stage-constant table ('c'):
        stored twiddles by `twiddleIndex` (forward then inverse with both
        directions), and Shoup's companions.'''
        key = ('tw', j, q) if not (self.memOrg == 'constgeo' and self.rns) else ('tw', j, q, direction)
        if key not in self._qCache and self.memOrg == 'constgeo':
            # one table per butterfly, every stage's region (cgTwiddleIndex); no stage-constant table; with a
            # record stream (RNS) only the job's direction
            out = []
            for d in (self.tdirs if not self.rns else [direction or ('inv' if self.direction == 'inverse' else 'fwd')]):
                tab = [None] * self.tdepth
                for s in range(self.L):
                    for t in range(self.T):
                        i = self.cgTwiddleIndex(s, t)
                        mA, _ = self.cgPair(s, t, j)
                        w = self.stored(self.value(d, self._exponent(d, s, mA), q), q)
                        if tab[i] is not None and tab[i] != w:
                            raise AssertionError(f'{self.name}: twiddle {i} of butterfly {j} holds two values')
                        tab[i] = w
                if any(x is None for x in tab):
                    raise AssertionError(f'{self.name}: twiddle table of butterfly {j} has unused entries')
                out += tab
            self._qCache[key] = {'t': (out, [self.companion(x, q) for x in out] if self.shoup() else None),
                                 'c': ([], [] if self.shoup() else None)}
        if key not in self._qCache:
            res = {}
            for kind, depth in (('t', self.tdepth), ('c', self.cdepth)):
                out = []
                for d in self.tdirs:
                    tab = [None] * depth
                    for s in range(self.L):
                        for t in range(self.T):
                            k, i = self.twiddleIndex(s, t)
                            if k != kind:
                                continue
                            mA, _ = self.pair(s, t, j)
                            w = self.stored(self.value(d, self._exponent(d, s, mA), q), q)
                            if tab[i] is not None and tab[i] != w:
                                raise AssertionError(f'{self.name}: twiddle {kind}{i} of butterfly {j} holds two values')
                            tab[i] = w
                    if any(x is None for x in tab):
                        raise AssertionError(f'{self.name}: twiddle table {kind} of butterfly {j} has unused entries')
                    out += tab
                res[kind] = (out, [self.companion(x, q) for x in out] if self.shoup() else None)
            self._qCache[key] = res
        return self._qCache[key][which]

    def twiddleRef(self, s: int, t: int, j: int, d: str) -> tuple[int, str, int, bool]:
        '''Where butterfly j finds its twiddle in cycle t of stage s, direction d:
        (table's butterfly, 't' | 'c', entry, swap the outputs). Without shared inverse
        twiddles: its own table, the direction's half. With them, in the inverse
        (u = mA mod 2^s, the exponent -u*n/2^(s+1)): w^-u = -w^(2^s - u), the forward
        entry of butterfly -j mod B at the complemented cycle bits (butterfly 0: their
        negation), and the CT butterfly with -w is the one with w, outputs swapped
        (a - wb, a + wb); u = 0 is the twiddle 1, unswapped.'''
        if self.memOrg == 'constgeo':
            return j, 't', self.cgTwiddleIndex(s, t) + (0 if self.rns else self.tdirs.index(d) * self.tdepth), False
        kind, i = self.twiddleIndex(s, t)
        if not (self.shareInv and d == 'inv'):
            return j, kind, i + self.tdirs.index(d) * (self.tdepth if kind == 't' else self.cdepth), False
        B = self.B
        jj = (B - j) % B
        if kind == 'c':
            return jj, 'c', i, (j % (1 << s)) != 0
        p = s - self.b - 1
        mask = (2 << p) - 1
        base = (1 << (p + 1)) - 2
        v = t & mask
        if j:
            return jj, 't', base + (~v & mask), True
        return 0, 't', base + (-v & mask), v != 0

    def twistTableRns(self, lane: int, q: int, d: str) -> list[int]:
        '''RNS with the output twist: lane `lane`'s twist operands of direction d (one per beat), as a record carries
        them into copy (polynomial index mod 2).'''
        t = self.twistTable(lane, q)
        i = self.dirs.index(d) * self.beats
        return t[i:i + self.beats]

    def twistTable(self, lane: int, q: int) -> list[int]:
        '''Output lane `lane`'s twist operand per beat (stored in the multiplier's
        domain): forward 1, inverse n^-1 psi^-m (m = the beat's memory index);
        forward then inverse with both.'''
        tm = self.twistMultiplier
        fi = pow(tm.reductionFactor(q if self.runtime else None), -1, q)
        nInv = pow(self.n, -1, q)
        out = []
        for d in self.dirs:
            for beat in range(self.beats):
                m = beat * self.io + lane
                if d == 'inv':
                    e = m % (2 * self.n) if self.negacyclic else 0
                    out.append(nInv * self.value('twist', e, q) * fi % q)
                else:
                    out.append(fi % q)
        return out

    def twiddleWords(self) -> int:
        words = self.B * (self.tdepth + self.cdepth) * self.twDirs() * (2 if self.shoup() else 1)   # cdepth 0 (CG)
        if self.twistOn:
            words += self.n * len(self.dirs)
        return words * (len(self.moduli) if self.multiRom else 1)      # moduli=: every modulus in the ROMs

    # --- the value path ----------------------------------------------------------------

    def transform(self, frames: list[list[int]], direction: str | None = None, q: int | None = None) -> list[list[int]]:
        '''Bit-exact outputs for `frames` (n points each, memory order), in memory order:
        the polynomial is placed in the banks, every stage reads its pairs from the
        banks and addresses the RTL forms, its twiddles from the tables by
        `twiddleIndex`, and writes the butterfly outputs back in place.'''
        if isinstance(direction, (list, tuple)):   # a direction per polynomial (dirPerPoly)
            if len(direction) != len(frames):
                raise ValueError(f'{self.name}: one direction per frame')
            qs = q if isinstance(q, (list, tuple)) else [q] * len(frames)
            return [self.transform([f], dd, qq)[0] for f, dd, qq in zip(frames, direction, qs)]
        d = direction or ('inv' if self.direction == 'inverse' else 'fwd')
        if d not in self.dirs:
            raise ValueError(f'{self.name}: direction {d!r} not built')
        if isinstance(q, (list, tuple)):           # a modulus per polynomial (RNS)
            if len(q) != len(frames):
                raise ValueError(f'{self.name}: one modulus per frame')
            return [self.transform([f], d, qq)[0] for f, qq in zip(frames, q)]
        q = q or self.refQ()
        if not self.runtime and q != self.q:
            raise ValueError(f'{self.name}: q is fixed at {self.q}')
        qv = self.qPortValues(q) if self.runtime else {}
        bu = self.butterflyUnit()
        if self.memOrg == 'constgeo':
            return self._applyTwist(self._cgValues(frames, d, q, qv, bu), d, q, qv)
        B, T, F = self.B, self.T, len(frames)
        tabs = {kind: [self.twiddleTable(j, q, kind) for j in range(B)] for kind in ('t', 'c')}
        mems = []
        for fr in frames:
            mem = [[0] * T for _ in range(2 * B)]
            for m, v in enumerate(fr):
                mem[self.bank(m)][self.addr(m)] = v
            mems.append(mem)
        hq = (q + 1) // 2
        for s in range(self.L):
            A, Bv, W, WP, where = [], [], [], [], []
            for t in range(T):
                for j in range(B):
                    tj, kind, ti, sw = self.twiddleRef(s, t, j, d)
                    ka, kb = self.readBanks(s, t, j)
                    aa, ab = self.bankAddr(s, t, ka), self.bankAddr(s, t, kb)
                    tw, twp = tabs[kind][tj]
                    for f in range(F):
                        A.append(mems[f][ka][aa]); Bv.append(mems[f][kb][ab])
                        W.append(tw[ti])
                        if twp is not None:
                            WP.append(twp[ti])
                        where.append((f, ka, aa, kb, ab, sw))
            bu.aInValues, bu.bInValues = A, Bv
            pv = {'W': W}
            if 'WP' in bu.portNames():
                pv['WP'] = WP
            for pn in bu.portNames():
                if pn not in ('W', 'WP'):
                    pv[pn] = [qv[pn]] * len(A)
            bu.portValues = pv
            X, Y = bu.propagateValue()
            for (f, ka, aa, kb, ab, sw), x, y in zip(where, X, Y):
                if sw:
                    x, y = y, x
                if self.stageHalve and d == 'inv':
                    x, y = self.halve(x, hq), self.halve(y, hq)
                mems[f][ka][aa], mems[f][kb][ab] = x, y
        out = [[mem[self.bank(m)][self.addr(m)] for m in range(self.n)] for mem in mems]
        if self.twistMultiplier is not None:
            tm = self.twistMultiplier
            ti = self.dirs.index(d) * self.beats
            tw = [0] * self.n
            for l in range(self.io):
                tl = self.twistTable(l, q)
                for beat in range(self.beats):
                    tw[beat * self.io + l] = tl[ti + beat]
            res = []
            for f in range(F):
                ins = {'A': out[f], 'B': tw}
                ins.update({pn: [qv[pn]] * self.n for pn in tm.qPorts()})
                res.append(tm.datapath().run(ins)['P'])
            out = res
        return out

    def _cgValues(self, frames, d, q, qv, bu) -> list[list[int]]:
        '''Constant geometry, as the RTL moves the data: the polynomial in the input set (memory order, the
        parity bank map); stage s reads set s mod 2 (input / scratch) in row order cgRow, butterfly k from
        banks 2k, 2k+1 (B = 1: pi, 1-pi) at the row, its twiddle from its own table at cgTwiddleIndex, and
        writes X and Y to cgWrite's banks and addresses in the other set; the result is in set L mod 2.'''
        B, T, F, L = self.B, self.T, len(frames), self.L
        tabs = [self.twiddleTable(j, q, 't', d) for j in range(B)]
        doff = 0 if self.rns else self.tdirs.index(d) * self.tdepth
        mems = []
        for fr in frames:
            mem = [[[0] * T for _ in range(2 * B)] for _ in range(2)]
            for m, v in enumerate(fr):
                mem[0][self.bank(m)][self.addr(m)] = v
            mems.append(mem)
        hq = (q + 1) // 2
        for s in range(L):
            rd, wr = s % 2, 1 - s % 2
            A, Bv, W, WP, where = [], [], [], [], []
            for t in range(T):
                r = self.cgRow(s, t)
                ti = self.cgTwiddleIndex(s, t) + doff
                for k in range(B):
                    ka, kb = self.cgReadBanks(s, t, k)
                    (bx, ax), (by, ay) = self.cgWrite(s, t, k)
                    tw, twp = tabs[k]
                    for f in range(F):
                        A.append(mems[f][rd][ka][r]); Bv.append(mems[f][rd][kb][r])
                        W.append(tw[ti])
                        if twp is not None:
                            WP.append(twp[ti])
                        where.append((f, bx, ax, by, ay))
            bu.aInValues, bu.bInValues = A, Bv
            pv = {'W': W}
            if 'WP' in bu.portNames():
                pv['WP'] = WP
            for pn in bu.portNames():
                if pn not in ('W', 'WP'):
                    pv[pn] = [qv[pn]] * len(A)
            bu.portValues = pv
            X, Y = bu.propagateValue()
            for (f, bx, ax, by, ay), x, y in zip(where, X, Y):
                if self.stageHalve and d == 'inv':
                    x, y = self.halve(x, hq), self.halve(y, hq)
                mems[f][wr][bx][ax], mems[f][wr][by][ay] = x, y
        fin = L % 2
        return [[mem[fin][self.bank(m)][self.addr(m)] for m in range(self.n)] for mem in mems]

    def _applyTwist(self, out, d, q, qv):
        '''The output twist (negacyclic inverse, inverseScale 'output'), as in `transform`.'''
        if self.twistMultiplier is None:
            return out
        tm = self.twistMultiplier
        ti = self.dirs.index(d) * self.beats
        tw = [0] * self.n
        for l in range(self.io):
            tl = self.twistTable(l, q)
            for beat in range(self.beats):
                tw[beat * self.io + l] = tl[ti + beat]
        res = []
        for f in range(len(out)):
            ins = {'A': out[f], 'B': tw}
            ins.update({pn: [qv[pn]] * self.n for pn in tm.qPorts()})
            res.append(tm.datapath().run(ins)['P'])
        return res

    # --- the clock: the controller's twin -----------------------------------------------

    def twistLatency(self, pipelineStages=1) -> int:
        return self.twistMultiplier.latency(pipelineStages) if self.twistMultiplier is not None else 0

    def outLatency(self, pipelineStages=1) -> int:
        '''Cycles from a drain issue to its beat on the output.'''
        return 2 + self.Rx() + self.twistLatency(pipelineStages)

    def simulateJob(self, polys: int, valid=None, pipelineStages=1, maxCycles: int | None = None,
                    records=None, twValid=None, tags=None) -> dict:
        '''The controller, cycle by cycle, as the RTL builds it (`IterNTT_RTL_gen`):
        `valid(c)` is the input's valid in cycle c (default: always). Returns the
        cycle of every accepted input beat and every output beat (per polynomial),
        the compute starts, and the cycles of the job. With twiddleBuffer 'recycle' /
        'double' (`rns`): `records` (per polynomial: True = keep the previous
        modulus, no twiddles; default all False, a new q every polynomial) and
        `twValid(c)` (the record stream's valid) as in `_simulateJobRns`.
        moduli= with qSwitch 'bubble': `tags` per polynomial its (modulus, direction); a polynomial whose tag
        differs from the one before starts only `rnsBubble` cycles after that one's last issue (default: every
        polynomial differs). qSwitch 'inline': no wait, the tags do not matter.'''
        if self.rns:
            return self._simulateJobRns(polys, valid, pipelineStages, maxCycles, records, twValid)
        bub = self.multiRom and not self.qInline
        QB = self.rnsBubble(pipelineStages) - 1 if bub else 0
        qwc, cpoly = 0, 0
        if bub and tags is None:
            tags = list(range(polys))
        valid = valid or (lambda c: True)
        L, T, NB = self.L, self.T, self.beats
        pw = self.writeLatency(pipelineStages)
        gaps = [x - T for x in self.stageOffsets(pipelineStages)] + [0]
        olat = self.outLatency(pipelineStages)
        fset = fptr = 0
        ns, nx, rs = self.numSets(), self.nextSet, self.resultSet
        cg = self.memOrg == 'constgeo'
        full, busy, res = [0] * ns, [0] * ns, [0] * ns
        cact = cset = cnext = s = tau = gap = 0
        dsr = [(0, 0)] * pw
        dact = dset = dnext = dptr = 0
        dnext = rs(0)
        acc_c, out_c, starts = [], [], []
        fpoly = 0
        dpoly = 0
        c = 0
        limit = maxCycles or (polys + 4) * (max(self.computeCycles(pipelineStages), 2 * NB) + 4 * pw + 64) + 200
        while (len(out_c) < polys or (out_c and len(out_c[-1]) < NB)) and c < limit:
            iv = valid(c) and fpoly < polys
            fill_ok = (not full[fset]) and (not busy[fset]) and \
                      ((not res[fset]) or (dact and dset == fset and fptr < dptr))
            acc = iv and fill_ok
            flast = fptr == NB - 1
            issue = cact and gap == 0
            tlast = tau == T - 1
            clast = issue and tlast and s == L - 1
            startc = full[cnext] and ((not cact) or clast)
            if bub and cpoly < len(tags) and not (cpoly > 0 and tags[cpoly] == tags[cpoly - 1]):
                startc = full[cnext] and (not cact) and qwc == 0      # a new modulus or direction: the bubble
            dlastb = dact and dptr == NB - 1
            startd = res[dnext] and ((not dact) or dlastb)
            done, dn_set = dsr[pw - 1]
            if acc:
                if fptr == 0:
                    acc_c.append([])
                acc_c[-1].append(c)
            if dact:
                if dptr == 0:
                    out_c.append([])
                out_c[-1].append(c + olat)
            # next state
            if acc:
                fptr = 0 if flast else fptr + 1
                if flast:
                    full[fset] = 1
                    if cg and not self._cgReserveAtStart:
                        busy[rs(fset)] = 1        # constgeo: reserve the result set (the scratch for L odd) now
                    fset = nx(fset)
                    fpoly += 1
            dsr = [(1 if clast else 0, rs(cset))] + dsr[:-1]
            qwc = QB if clast else max(0, qwc - 1)
            if startc:
                cpoly += 1
                starts.append(c + 1)
                full[cnext] = 0
                if not cg or self._cgReserveAtStart:
                    busy[rs(cnext)] = 1
                cact, cset, cnext, s, tau, gap = 1, cnext, nx(cnext), 0, 0, 0
            elif clast:
                cact = 0
            elif issue:
                if tlast:
                    gap = gaps[s]
                    s, tau = s + 1, 0
                else:
                    tau += 1
            elif cact:
                gap -= 1
            if done:
                busy[dn_set] = 0
                res[dn_set] = 1
            if dlastb:
                res[dset] = 0
            if startd:
                dact, dset, dnext, dptr = 1, dnext, nx(dnext), 0
                dpoly += 1
            elif dlastb:
                dact = 0
            elif dact:
                dptr += 1
            c += 1
        if c >= limit:
            raise AssertionError(f'{self.name}: the job did not finish in {limit} cycles')
        first_in = acc_c[0][0]
        last_out = out_c[-1][-1]
        iv = [out_c[k + 1][0] - out_c[k][0] for k in range(len(out_c) - 1)]
        return {'accept': acc_c, 'out': out_c, 'starts': starts,
                'latency': out_c[0][-1] - acc_c[0][0] + 1,
                'jobCycles': last_out - first_in + 1,
                'interval': max(iv) if iv else None}

    # --- RNS: a modulus per polynomial (twiddleBuffer 'recycle' / 'double') ---------------

    def rnsExtWidths(self) -> dict:
        """The butterfly's extra port widths (W, WP, the modulus ports)."""
        bu = self.butterflyUnit()
        c = getattr(self, '_extCache', None)
        if c is None or c[0] is not bu:
            c = (bu, dict(bu.getOperatorInterface('probe', 1).extraPorts))
            self._extCache = c
        return c[1]

    def qPortWidths(self) -> list[tuple[str, int]]:
        """(port, width) of every modulus input (`qPorts`), as the RTL declares them."""
        ext = self.rnsExtWidths()
        tws = {}
        if self.twistMultiplier is not None:
            dp_ = self.twistMultiplier.datapath()
            tws = {x: dp_.widths[x][0] for x in dp_.inputs}
        gen = self.genPortWidths() if self.genMultiplier is not None else {}
        out = []
        for qp in self.qPorts():
            ws = ([ext[qp]] if qp in ext else []) + ([tws[qp]] if qp in tws else [])
            if qp == 'QHALF':
                ws.append(self.qMax().bit_length())
            if qp in gen:
                ws.append(gen[qp])
            out.append((qp, max(ws)))
        return out

    def genPortWidths(self) -> dict:
        '''twiddleSource 'rec': the generator multiplier's input widths {port: bits} (A, B, its modulus ports).'''
        if self._genPorts is None:
            dps = self.genMultiplier.getOperatorInterface(f'{self.name}_gen', 1)
            self._genPorts = {w.name: w.bitWidth for w in dps.inputs}
        return self._genPorts

    def twEntryCols(self) -> list[int]:
        """Widths of one table entry's columns (the twiddle, and Shoup's companion)."""
        ext = self.rnsExtWidths()
        return [ext['W']] + ([ext['WP']] if self.shoup() else [])

    def twEntryWidth(self) -> int:
        return sum(self.twEntryCols())

    def headerLayout(self) -> list[tuple[str, int, int]]:
        """The record header: bit 0 = keep (the previous modulus, no twiddles follow), then
        every modulus port packed from bit 1 in `qPorts` order: [(port, offset, width)]."""
        out, off = [], 1
        if self.dirPerPoly:                 # bit 1: the polynomial's direction (1 = inverse)
            out.append(('DIR', 1, 1))
            off = 2
        for qp, w in self.qPortWidths():
            out.append((qp, off, w))
            off += w
        return out

    def headerBits(self, K: int | None = None) -> int:
        return (1 + (1 if self.dirPerPoly else 0) + sum(w for _, w in self.qPortWidths())
                + (sum(x[3] for x in self.recFactorLayout(K)) if self.rec else 0))

    def rnsBubble(self, pipelineStages=1) -> int:
        """Idle issue cycles at a polynomial boundary where the modulus changes: the new
        constants are switched in only once the previous polynomial's last butterfly
        operation has used the old ones (QB = R + Pbu cycles after its issue, then the
        start), so no butterfly pipeline ever holds two moduli. qSwitch 'inline': none."""
        if self.qInline:
            return 0
        return self.Rx() + self.xr + self.buLatency(pipelineStages) + 1

    def stageBeats(self, TL: int | None = None) -> list[int]:
        """Record data beats per stage region: stage s <= b one stage-constant entry per
        butterfly, stage s = b+1+p the 2^(p+1) entries of every table; per direction
        stored (`tdirs`); TL entries a beat."""
        if self.rec:                     # loader units per region: stream beats, then generator slots
            out = [0] * self.L
            for u in self.recUnits():
                out[u[0]] += 1
            return out
        TL = TL or self.twiddleLanes()
        G, nd = self.B // TL, len(self.tdirs)
        if self.memOrg == 'constgeo':
            return [G * self.twDirs() * self.cgDepths[s] for s in range(self.L)]
        return [G * nd * (1 if s <= self.b else 1 << (s - self.b)) for s in range(self.L)]

    def headerBeats(self, TL: int | None = None, K: int | None = None) -> int:
        TL = TL or self.twiddleLanes()
        return -(-self.headerBits(K) // (TL * self.twEntryWidth()))

    def twistGap(self, pipelineStages=1) -> int:
        '''RNS with the output twist: idle cycles after a drain before the next (R + 2 + the twist latency): the
        twist multipliers' constants switch only once the last beat of the polynomial before has left them.'''
        return self.R + 2 + self.twistLatency(pipelineStages) if (self.rns and self.twistOn) else 0

    def twistBeats(self, TL: int | None = None) -> int:
        '''With the output twist in an RNS mode (negacyclic inverse, inverseScale 'output'): the record's twist
        region, every polynomial's (keep or not): its n twist factors in memory order (factor m = n^-1 psi^-m in
        the inverse, the stored 1 forward), min(TL, io) a beat (one write per twist table and cycle).'''
        if not (self.rns and self.twistOn):
            return 0
        TL = TL or self.twiddleLanes()
        return self.n // min(TL, self.io)

    def recordBeats(self, keep: bool = False, TL: int | None = None, G: int | None = None,
                    K: int | None = None) -> int:
        if self.rec:                     # the stream carries the header and the first H+2 regions
            if self.recIp and self._seedReq:     # in place with seeds (recSeeds): the header and the seed beats
                return self.headerBeats(K=K) + (0 if keep else self.recStreamBeats(G=G, K=K))
            return self.headerBeats() + (0 if keep else self.recStreamBeats())
        return self.headerBeats(TL) + (0 if keep else sum(self.stageBeats(TL))) + self.twistBeats(TL)

    def twiddleLanes(self, pipelineStages=1) -> int:
        """Entries per record-stream beat (TL; the table write ports take one entry a cycle
        each, TL tables a beat). Default: the fewest for which (1) a record fits in the
        polynomial period with a new modulus every polynomial (recordBeats <= compute +
        bubble: the steady-state bound; a short twin job alone can hide a deficit that the
        slack of the first polynomials absorbs) and (2) the twin's 6-polynomial job runs as
        fast as with the widest stream (TL = B)."""
        if not self.rns:
            raise ValueError(f'{self.name}: twiddleLanes is for twiddleBuffer recycle / double')
        if self.rec:
            return 2                     # 'rec': a beat = lane 0 (butterflies k < B/2) and lane 1 (k >= B/2)
        if self._twLanes:
            return self._twLanes
        key = ('tl', pipelineStages, id(self.butterflyUnit()))
        if key not in self._qCache:
            period = self.computeCycles(pipelineStages) + self.rnsBubble(pipelineStages)
            run = lambda TL: self._simulateJobRns(6, None, pipelineStages, None, None, None, TL=TL)['interval']
            ref = run(self.B)
            TL = 1
            while TL < self.B and (self.recordBeats(False, TL) > period or run(TL) > ref):
                TL *= 2
            self._qCache[key] = TL
        return self._qCache[key]

    # --- twiddleSource 'rec': the twiddle tables written on chip (constant geometry, recycle) ------------
    #
    # Butterfly k's table (cgTwiddleIndex) holds, in stage region s, entry e = w^E (stored domain). Region
    # s <= H: E depends on e only (the same for every butterfly). s = H + j, j >= 1: E = r 2^b + (kt ^ par(r))
    # 2^(b-1) + (k mod 2^(b-1) with its low b-j bits cleared) (cyclic; the negacyclic forward adds 2^(b-j)), so
    # region H+1 depends on k only by its top bit kt, and region H+j = region H+j-1 times F[j][bit b-j of k],
    # entry by entry, for every j >= 2 (one factor per stage and bit; checked by `recTables`). The record:
    # header (keep, the modulus constants, the factors F[j][0/1], j = 2..b), then the regions 0 .. H+1 on the
    # stream, a beat per entry = (lane 0: the entry of butterflies kt = 0, lane 1: kt = 1). The rest on chip:
    # butterflies in groups of G = recGroup (k = g G .. g G + G - 1), each group one modular multiplier and a
    # small store of the previous region; region H+j of a group holds recClasses(j) distinct sequences
    # (members that differ in a bit >= b-j), each derived from its parent class of region H+j-1.

    def recStreamRegions(self) -> int:
        """Stage regions carried on the record stream ('rec'): 0 .. H+1 (in place: none)."""
        return 0 if self.recIp else min(self.L, self.H + 2)

    def recStreamBeats(self, pipelineStages=1, G: int | None = None, K: int | None = None) -> int:
        if self.recIp:                   # in place: the seed beats (recSeeds), else none
            return sum(self.recIpPlan(pipelineStages, G, K).get('seedBeats', ())) if self._seedReq else 0
        return sum(self.cgDepths[s] for s in range(self.recStreamRegions()))

    def recGen(self) -> bool:
        """'rec' with generator multipliers (in place always; constant geometry when a region is derived)."""
        return self.rec and (self.recIp or self.L > self.H + 2)

    def recClasses(self, j: int, G: int | None = None) -> int:
        """Distinct sequences in a group's region H+j (j >= 2): members differ there in their bits >= b-j."""
        g = (G or self.recGroup()).bit_length() - 1
        return 1 << max(0, g - (self.b - j))

    def genLatency(self, pipelineStages=1, G: int | None = None) -> int:
        """PG: a record unit issued in cycle c is written into its tables (and the group's store) on edge
        c + PG: unit register, store read register, the multiplier, the write register."""
        return 3 + self.genMultiplier.latency(pipelineStages) + self.genTree(G)

    def recWriteLatency(self, pipelineStages=1, G: int | None = None) -> int:
        '''Issue to table write of a record unit: genLatency, or with no generator (every region on the
        stream) max(1, readTree): a region is rewritten only after the last read of it (issue + 1 + readTree).'''
        if self.recGen():
            return self.genLatency(pipelineStages, G or self.recGroup(pipelineStages))
        return max(1, self.readTree())

    def recFactorLayout(self, K: int | None = None) -> list[tuple[int, int, int, int]]:
        """The factors in the header after the modulus ports: [(j, bit, offset, width)], j = 2 .. b."""
        if self.recIp:
            return self._recIpLayout(K)
        off = 1 + sum(w for _, w in self.qPortWidths())
        w = self.genPortWidths()['B']
        out = []
        for j in range(2, self.b + 1):
            for beta in (0, 1):
                out.append((j, beta, off, w))
                off += w
        return out

    def recUnits(self, pipelineStages=1, G: int | None = None, K: int | None = None) -> list[tuple]:
        """The loader's units of one record (DATA, in order): (stage s, kind, index, class, regionLast,
        recordLast). kind 'S' a stream beat (index = entry of region s), 'G' a generator operation (index =
        row r, class c: entry r of class c's sequence in region s), 'B' a bubble. Units issue at most one a
        cycle; an operation is at least PG units after the one that wrote its parent (class c >> 1 of the
        region before, entry r) into the store, so it reads it after its write whatever the stalls."""
        G = G or self.recGroup(pipelineStages)
        if self.recIp and self._seedReq:        # in place with seeds: K entries of each region on the stream
            K = self.recSeedCount(pipelineStages) if K is None else K
            if K:
                key = ('ruk', pipelineStages, G, K, id(self.butterflyUnit()))
                if key not in self._qCache:
                    self._qCache[key] = self._recIpUnits(pipelineStages, G, K)
                return self._qCache[key]
        key = ('ru', pipelineStages, G, id(self.butterflyUnit()))
        if key in self._qCache:
            return self._qCache[key]
        if self.recIp:
            self._qCache[key] = self._recIpUnits(pipelineStages, G)
            return self._qCache[key]
        H, T, L = self.H, self.T, self.L
        PG = self.genLatency(pipelineStages, G) if L > H + 2 else 0
        units, pos = [], {}
        for s in range(self.recStreamRegions()):
            for e in range(self.cgDepths[s]):
                if s == H + 1:
                    pos[(1, 0, e)] = len(units)
                units.append([s, 'S', e, 0])
        for s in range(H + 2, L):
            j = s - H
            for c in range(self.recClasses(j, G)):
                for r in range(T):
                    dep = pos[(j - 1, c >> 1, r)]
                    while len(units) < dep + PG:
                        units.append([s, 'B', 0, 0])
                    pos[(j, c, r)] = len(units)
                    units.append([s, 'G', r, c])
        out = []
        for i, u in enumerate(units):
            rl = i == len(units) - 1 or units[i + 1][0] != u[0]
            out.append((u[0], u[1], u[2], u[3], rl, i == len(units) - 1))
        self._qCache[key] = out
        return out

    def recGroup(self, pipelineStages=1) -> int:
        """Butterflies per generator (G). Default: the largest (fewest multipliers) for which a record's
        units fit in the polynomial period with a new modulus every polynomial and the twin's
        6-polynomial job runs as fast as with one generator per butterfly (G = 1)."""
        if not self.rec:
            raise ValueError(f"{self.name}: recGroup is for twiddleSource 'rec'")
        if self._recReq:
            return self._recReq
        if self.recIp and self._seedReq:        # with seeds the group and K are chosen together (`_recChoice`)
            return self._recChoice(pipelineStages)[0]
        key = ('rg', pipelineStages, id(self.butterflyUnit()))
        if key not in self._qCache:
            period = self.computeCycles(pipelineStages) + self.rnsBubble(pipelineStages)
            run = lambda G: self._simulateJobRec(6, None, pipelineStages, None, None, None, G=G)['interval']
            ref = run(1)
            G = self.B if self.recIp else self.B // 2
            if self.recIp:           # in place: also when no group size reaches the period (short stages)
                period = max(period, len(self.recUnits(pipelineStages, 1)))
            while G > 1 and (len(self.recUnits(pipelineStages, G)) > period or run(G) > ref):
                G //= 2
            self._qCache[key] = G
        return self._qCache[key]

    def recFactors(self, q: int, direction: str) -> dict:
        """{(j, bit): F}: region H+j = region H+j-1 x F (stored entries; F in the generator's domain:
        P = A B rf for its multiplier, so F = ratio / rf)."""
        if self.recIp:
            return self._recIpFactors(q)
        key = ('rf', q, direction)
        if key not in self._qCache:
            H, b = self.H, self.b
            rf = self.genMultiplier.reductionFactor(q)
            tabs = [self.twiddleTable(k, q, 't', direction)[0] for k in range(self.B)]
            out = {}
            for j in range(2, b + 1):
                cur, prev = self.cgBases[H + j], self.cgBases[H + j - 1]
                for beta in (0, 1):
                    k = beta << (b - j)
                    out[(j, beta)] = tabs[k][cur] * pow(tabs[k][prev], -1, q) * pow(rf, -1, q) % q
            self._qCache[key] = out
        return self._qCache[key]

    def recTables(self, q: int, direction: str, G: int | None = None, K: int | None = None) -> list[list[int]]:
        """Every butterfly's table as the 'rec' hardware writes it: regions 0 .. H+1 from the record (lane
        kt), then per group and class the generator multiplier's outputs, bit-exact through its datapath;
        checked against `twiddleTable` (raises on a difference)."""
        if self.recIp:
            return self._recIpTables(q, G, K)
        H, b, T, B, L = self.H, self.b, self.T, self.B, self.L
        G = G or self.recGroup()
        g = G.bit_length() - 1
        ref = [self.twiddleTable(k, q, 't', direction)[0] for k in range(B)]
        F = self.recFactors(q, direction)
        tabs = [[None] * self.tdepth for _ in range(B)]
        for s in range(self.recStreamRegions()):
            for e in range(self.cgDepths[s]):
                for k in range(B):
                    kt = (k >> (b - 1)) & 1
                    tabs[k][self.cgBases[s] + e] = ref[kt << (b - 1)][self.cgBases[s] + e]
        qv = self.genMultiplier.qPortValues(q)
        dp = self.genMultiplier.datapath()
        # per group: the store holds class c's sequence of the region before (entry r)
        store = {(gi, 0, r): tabs[gi * G][self.cgBases[H + 1] + r] for gi in range(B // G) for r in range(T)} \
            if L > H + 2 else {}
        for s in range(H + 2, L):
            j = s - H
            nc = self.recClasses(j, G)
            A, Bv, where = [], [], []
            for gi in range(B // G):
                for c in range(nc):
                    if b - j < g:
                        beta = c & 1
                    else:
                        beta = ((gi * G) >> (b - j)) & 1
                    for r in range(T):
                        A.append(store[(gi, c >> 1, r)])
                        Bv.append(F[(j, beta)])
                        where.append((gi, c, r))
            ins = {'A': A, 'B': Bv}
            ins.update({pn: [qv[pn]] * len(A) for pn in self.genMultiplier.qPorts()})
            P = dp.run(ins)['P']
            store = {}
            for (gi, c, r), v in zip(where, P):
                store[(gi, c, r)] = v
                for l in range(G):
                    if (l >> (b - j) if b - j < g else 0) == c:
                        tabs[gi * G + l][self.cgBases[s] + r] = v
        for k in range(B):
            if tabs[k] != ref[k]:
                bad = next(i for i in range(self.tdepth) if tabs[k][i] != ref[k][i])
                raise AssertionError(f"{self.name}: 'rec' table of butterfly {k} differs at entry {bad} "
                                     f"(q {q}, {direction})")
        return tabs

    # --- twiddleSource 'rec' in place (recycle): every table entry generated on chip -------------------
    #
    # In place, butterfly j's entry v of stage s is w^E, E = E0(s) + (j + 2^b v) e(s) (stage s <= b: the
    # stage constant, v = 0, only the low s bits of j count; s = b+1+p: v = 0 .. 2^(p+1) - 1), so in the
    # stored domain setting one bit of j or of v multiplies the entry by a factor that depends on the stage
    # and the bit only, and the factors of all stages are the powers w^(n/2^m) (cyclic; `recIpPlan` finds
    # them by their exponents, whatever the transform). The record is its header alone: keep, the modulus
    # constants, the distinct factors (generator domain) and the distinct stage seeds (entry j = 0, v = 0;
    # cyclic: one, the stored 1). Butterflies in groups of G = recGroup (j = gi G + l), each group one
    # modular multiplier and a store of SD = 2^d >= max(G, PG) entries (LUTRAM). A stage region of a group,
    # N = G 2^(v bits) entries indexed y = v G + l, is written in the order of y:
    #   chain    max(1, b - g) operations: the stage seed times the factor of every set bit of gi G (the
    #            identity for a clear bit); the last is entry y = 0;
    #   doubling y = 1 .. min(N, SD) - 1: entry y - msb(y) (from the store) times the factor of that bit;
    #   stride   y = SD .. N - 1: entry y - SD (store address y mod SD) times the factor of v's bit d - g,
    #            one a cycle.
    # An operation is issued at least PG units after the one that wrote its operand (bubbles between).

    def recIpPlan(self, pipelineStages=1, G: int | None = None, K: int | None = None) -> dict:
        """The in-place 'rec' plan for groups of G: {g, d, SD (store depth), PG, nA (chain length), prefix
        (the chain and doubling steps of a full region: ('B',) or ('G', y, seed operand, store read address,
        factor slot, chain index (the factor applies if bit g + index of the group's first butterfly is set;
        -1: always), table write)), slots ((kind 'j' | 'v', bit) per factor slot), slotC
        (the stride's slot), N[s] (entries of a group's region), plast[s] (the region's last prefix step),
        fexp (the distinct factor exponents, 0 first), sexp (the distinct seed exponents), fid[s][slot],
        sid[s]}. With seeds (`recSeeds`, K >= 1) see `_recIpPlanSeeded`."""
        G = G or self.recGroup(pipelineStages)
        if self._seedReq:
            K = self.recSeedCount(pipelineStages) if K is None else K
            if K:
                return self._recIpPlanSeeded(pipelineStages, G, K)
        key = ('rip', pipelineStages, G, id(self.butterflyUnit()))
        if key in self._qCache:
            return self._qCache[key]
        b, L, H = self.b, self.L, self.H
        g = G.bit_length() - 1
        PG = self.genLatency(pipelineStages, G)
        d = max(g, (PG - 1).bit_length())
        SD = 1 << d
        nA = max(1, b - g)
        prefix, pos = [], {}
        for i in range(nA):
            while i and len(prefix) < pos[('a', i - 1)] + PG:
                prefix.append(('B',))
            pos[('a', i)] = len(prefix)
            prefix.append(('G', 0, int(i == 0), 0, g + i if b > g else 0, i, int(i == nA - 1)))
        pos[0] = pos[('a', nA - 1)]
        for y in range(1, SD):
            k = y.bit_length() - 1
            while len(prefix) < pos[y - (1 << k)] + PG:
                prefix.append(('B',))
            pos[y] = len(prefix)
            prefix.append(('G', y, 0, y - (1 << k), k if k < g else b + k - g, -1, 1))
        slots = [('j', k) for k in range(b)] + [('v', k) for k in range(d - g + 1)]
        slotC = b + d - g
        N = [G << (0 if s <= b else s - b) for s in range(L)]
        plast = [pos[min(N[s], SD) - 1] for s in range(L)]
        ex = self._recIpExps()
        fid = [[ex['bit'].get((s, kind, k), 0) for kind, k in slots] for s in range(L)]
        fexp, sexp, sid = ex['fexp'], ex['sexp'], ex['sid']
        plan = dict(G=G, g=g, d=d, SD=SD, PG=PG, nA=nA, prefix=prefix, slots=slots, slotC=slotC, N=N,
                    plast=plast, fexp=fexp, sexp=sexp, fid=fid, sid=sid)
        self._qCache[key] = plan
        return plan

    # --- seeds on the record stream (`recSeeds`) -------------------------------------------------------
    #
    # With K >= 1 (a power of two, K <= SD) the entries y < kk = min(K, N) of every group's stage region are
    # not computed: they arrive on the record stream (stored domain) at the start of that stage's units and
    # pass the group's multiplier with the identity factor (so table and store take them on the same edge
    # c + PG as a generated entry, and no second write path exists). A stage's units, in order:
    #   seeds    for y = 0 .. kk-1, for m = 0 .. NGP-1 (NGP = max(1, NG/2) beats an entry): one beat = the
    #            entry y of groups 2m (lane 0, bits [0, E)) and 2m+1 (lane 1, bits [E, 2E)); one generator
    #            (NG = 1): lane 0 only, lane 1 is ignored;
    #   doubling y = K .. min(N, SD) - 1 as before (entry y - msb(y) times the factor of that bit), at least
    #            PG units after the last beat of its operand (bubbles between); none when N <= K;
    #   stride   y = SD .. N - 1 as before.
    # There is no chain (entry 0 is a seed for every group), so the header carries no stage seeds.

    def _recIpStore(self, pipelineStages=1, G: int = 1) -> tuple[int, int, int]:
        """(PG, d, SD) of the in-place 'rec' generators for groups of G."""
        PG = self.genLatency(pipelineStages, G)
        d = max(G.bit_length() - 1, (PG - 1).bit_length())
        return PG, d, 1 << d

    def recSeedCount(self, pipelineStages=1) -> int:
        """K of `recSeeds` as built: 0 (none), the number given, or 'auto''s choice (`_recChoice`)."""
        if not self._seedReq:
            return 0
        return self._recChoice(pipelineStages)[1]

    def recSeedCandidates(self, pipelineStages=1) -> list[dict]:
        """Every (G, K) `_recChoice` considers, measured: {G, K, interval (the twin's 6-polynomial job, a new
        modulus every polynomial), record (HB + units + PG - 1: the cycles one record occupies the loader, the
        steady-state bound of the interval), words (table entries on the stream a record: 2 x header beats +
        the seeds), full (interval == compute + bubble and record <= compute + bubble)}. G: `recGroup=` if
        given, else every power of two in [1, B]; K: `recSeeds` if a number (only G with SD >= K), else 0 and
        every power of two up to the group's store depth."""
        key = ('rsc', pipelineStages, id(self.butterflyUnit()))
        if key in self._qCache:
            return self._qCache[key]
        period = self.computeCycles(pipelineStages) + self.rnsBubble(pipelineStages)
        req = self._seedReq
        out = []
        for G in ([self._recReq] if self._recReq else [self.B >> i for i in range(self.b + 1)]):
            PG, _, SD = self._recIpStore(pipelineStages, G)
            Ks = ([0] + [1 << i for i in range(SD.bit_length())]) if req == 'auto' else ([req] if req <= SD else [])
            for K in Ks:
                iv = self._simulateJobRec(6, None, pipelineStages, None, None, None, G=G, K=K)['interval']
                HB = self.headerBeats(K=K)
                rec = HB + len(self.recUnits(pipelineStages, G, K)) + PG - 1
                words = 2 * HB + (self.recIpPlan(pipelineStages, G, K)['seedWords'] if K else 0)
                out.append(dict(G=G, K=K, interval=iv, record=rec, words=words,
                                full=iv == period and rec <= period))
        if not out:
            raise ValueError(f"{self.name}: recSeeds {req} is more than the generators' store depth "
                             f"(SD = {self._recIpStore(pipelineStages, self._recReq or self.B)[2]}"
                             f"{' at recGroup ' + str(self._recReq) if self._recReq else ' at the largest group'})")
        self._qCache[key] = out
        return out

    def _recChoice(self, pipelineStages=1) -> tuple[int, int]:
        """(G, K) with `recSeeds` set. Among `recSeedCandidates`: if any is full (the twin's 6-polynomial job
        with a new modulus every polynomial runs at compute + bubble, and a record fits in that period), the
        fewest generators (largest G), then the smallest K. If none is full: the smallest steady interval
        max(interval, record), then the fewest record words, then the fewest generators. With `recSeeds` a
        number the candidates have that K only; with `recGroup=` that G only (both: one candidate)."""
        key = ('rgk', pipelineStages, id(self.butterflyUnit()))
        if key not in self._qCache:
            cand = self.recSeedCandidates(pipelineStages)
            full = [c for c in cand if c['full']]
            if full:
                c = min(full, key=lambda c: (-c['G'], c['K']))
            else:
                c = min(cand, key=lambda c: (max(c['interval'], c['record']), c['words'], -c['G']))
            self._qCache[key] = (c['G'], c['K'])
        return self._qCache[key]

    def _recIpPlanSeeded(self, pipelineStages, G, K) -> dict:
        """The in-place 'rec' plan with K seeds a group and stage: the plan of `recIpPlan` (K = 0) with
        prefix = the doubling steps y = K .. SD-1 and their bubbles (the steps after a full stage's K NGP seed
        beats), plast[s] = the stage's last prefix step (-1: none), and K, NGP (beats per seeded entry), kk[s]
        (seeded entries of a group's region), seedBeats[s], seedWords (entries a record), nA = 0."""
        key = ('ripk', pipelineStages, G, K, id(self.butterflyUnit()))
        if key in self._qCache:
            return self._qCache[key]
        pl = dict(self.recIpPlan(pipelineStages, G, 0))  # the plan without seeds
        SD, PG, g, b, N = pl['SD'], pl['PG'], pl['g'], self.b, pl['N']
        if K < 1 or K & (K - 1) or K > SD:
            raise ValueError(f"{self.name}: recSeeds {K}: a power of two in [1, {SD}] (the store depth at "
                             f"recGroup {G})")
        NG = self.B // G
        NGP = max(1, NG // 2)
        base = K * NGP
        pos = {y: y * NGP + NGP - 1 for y in range(K)}   # the last beat that carries entry y
        prefix = []
        for y in range(K, SD):
            k = y.bit_length() - 1
            while base + len(prefix) < pos[y - (1 << k)] + PG:
                prefix.append(('B',))
            pos[y] = base + len(prefix)
            prefix.append(('G', y, 0, y - (1 << k), k if k < g else b + k - g, -1, 1))
        kk = [min(K, n_) for n_ in N]
        pl.update(K=K, NGP=NGP, kk=kk, nA=0, prefix=prefix,
                  plast=[(pos[min(n_, SD) - 1] - base) if n_ > K and K < SD else -1 for n_ in N],
                  seedBeats=[k_ * NGP for k_ in kk], seedWords=NG * sum(kk))
        self._qCache[key] = pl
        return pl

    def _recIpE(self, s: int, j: int, v: int) -> int:
        """The exponent of butterfly j's entry v of stage s (the one stored direction)."""
        dr = self.tdirs[0]
        return self._exponent(dr, s, self.pair(s, v if s > self.b else 0, j)[0]) % self.order(dr)

    def recSeedWords(self, q: int, G: int | None = None, K: int | None = None) -> list[list[list[int]]]:
        """The seed entries of one record (`recSeeds`), [stage][y][group]: entry y = v G + l of group gi's
        region, i.e. butterfly gi G + l's entry v of the stage, stored domain (from the exponents, not from
        `twiddleTable`)."""
        G = G or self.recGroup()
        pl = self.recIpPlan(1, G, K)
        key = ('rsw', q, G, pl.get('K', 0))
        if key not in self._qCache:
            dr, g = self.tdirs[0], pl['g']
            self._qCache[key] = [[[self.stored(self.value(dr, self._recIpE(s, gi * G + (y & (G - 1)), y >> g), q), q)
                                   for gi in range(self.B // G)] for y in range(kk)]
                                 for s, kk in enumerate(pl.get('kk', [0] * self.L))]
        return self._qCache[key]

    def _recIpExps(self) -> dict:
        """The header's content, whatever the group size: fexp (the distinct factor exponents, 0 = the
        identity first), sexp (the distinct seed exponents), sid[s], bit[(s, 'j' | 'v', k)] = the factor
        index of that bit in stage s (absent: the stage has no such bit)."""
        key = ('rix',)
        if key in self._qCache:
            return self._qCache[key]
        b, L = self.b, self.L
        dr = self.tdirs[0]
        order = self.order(dr)

        def E(s, j, v):
            return self._exponent(dr, s, self.pair(s, v if s > b else 0, j)[0]) % order
        fexp, sexp, sid, bit = [0], [], [], {}
        for s in range(L):
            e0 = E(s, 0, 0)
            if e0 not in sexp:
                sexp.append(e0)
            sid.append(sexp.index(e0))
            for kind, k in [('j', k) for k in range(b)] + [('v', k) for k in range(max(0, s - b))]:
                e = ((E(s, 1 << k, 0) if kind == 'j' else E(s, 0, 1 << k)) - e0) % order
                if e not in fexp:
                    fexp.append(e)
                bit[(s, kind, k)] = fexp.index(e)
        self._qCache[key] = dict(fexp=fexp, sexp=sexp, sid=sid, bit=bit)
        return self._qCache[key]

    def _recIpUnits(self, pipelineStages, G, K: int = 0) -> list[tuple]:
        """In place: (stage, 'G' | 'B', y, (seed operand, store read address, factor slot, chain index or
        -1, table write), regionLast, recordLast); no stream beats. With seeds (K >= 1) each stage starts with
        its seed beats (stage, 'S', y, m: entry y of groups 2m and 2m+1)."""
        pl = self.recIpPlan(pipelineStages, G, K)
        out = []
        for s in range(self.L):
            if K:
                out += [[s, 'S', y, m] for y in range(pl['kk'][s]) for m in range(pl['NGP'])]
            for st in pl['prefix'][:pl['plast'][s] + 1]:
                out.append([s, 'B', 0, None] if st[0] == 'B' else [s, 'G', st[1], tuple(st[2:])])
            for y in range(pl['SD'], pl['N'][s]):
                out.append([s, 'G', y, (0, y % pl['SD'], pl['slotC'], -1, 1)])
        res = []
        for i, u in enumerate(out):
            rl = i == len(out) - 1 or out[i + 1][0] != u[0]
            res.append((u[0], u[1], u[2], u[3], rl, i == len(out) - 1))
        return res

    def _recIpLayout(self, K: int | None = None) -> list[tuple]:
        """The header after the modulus ports: [('F', i, offset, width)] the factors, then [('S', i, offset,
        width)] the stage seeds (table entries; none with `recSeeds`, K >= 1: the stream carries entry 0)."""
        pl = self._recIpExps()
        off = 1 + sum(w for _, w in self.qPortWidths())
        out = []
        if self._seedReq and (self.recSeedCount() if K is None else K):
            pl = dict(pl, sexp=[])
        for tag, cnt, w in (('F', len(pl['fexp']), self.genPortWidths()['B']), ('S', len(pl['sexp']), self.twEntryWidth())):
            for i in range(cnt):
                out.append((tag, i, off, w))
                off += w
        return out

    def _recIpFactors(self, q: int) -> dict:
        """{('F', i): factor i in the generator's domain (P = A B rf: value / rf), ('S', i): seed i (stored)}."""
        key = ('rfi', q)
        if key not in self._qCache:
            pl = self._recIpExps()
            dr = self.tdirs[0]
            ri = pow(self.genMultiplier.reductionFactor(q), -1, q)
            out = {('F', i): self.value(dr, e, q) * ri % q for i, e in enumerate(pl['fexp'])}
            out.update({('S', i): self.stored(self.value(dr, e, q), q) for i, e in enumerate(pl['sexp'])})
            self._qCache[key] = out
        return self._qCache[key]

    def _recIpTables(self, q: int, G: int | None = None, K: int | None = None) -> dict:
        """Every butterfly's tables as the in-place 'rec' hardware writes them ({'t': [...], 'c': [...]}),
        unit by unit through the generator multiplier's datapath (bit-exact) and the group stores; checked
        against `twiddleTable` (raises on a difference or an entry never written). A seed beat (`recSeeds`)
        passes the multipliers of its two groups with the identity factor. Also checked: every operation is
        issued at least PG units after the unit that wrote its operand into the group's store."""
        B, b = self.B, self.b
        G = G or self.recGroup()
        pl = self.recIpPlan(1, G, K)
        g, SD, NG, PG = pl['g'], pl['SD'], B // G, pl['PG']
        F = self._recIpFactors(q)
        SW = self.recSeedWords(q, G, pl['K']) if pl.get('K') else None
        tabs = {'t': [[None] * self.tdepth for _ in range(B)], 'c': [[None] * self.cdepth for _ in range(B)]}
        qv = self.genMultiplier.qPortValues(q)
        dp = self.genMultiplier.datapath()
        store = [[None] * SD for _ in range(NG)]
        wpos = [[None] * SD for _ in range(NG)]          # the unit that last wrote a store entry
        pend, busy = [], set()

        def flush():
            if not pend:
                return
            A, Bv = [], []
            for s, y, args, gis in pend:
                for gi in gis:
                    if args is None:                     # a seed beat: the stream's entry times the identity
                        A.append(SW[s][y][gi])
                        Bv.append(F[('F', 0)])
                        continue
                    asrc, ra, slot, ch, wt = args
                    A.append(F[('S', pl['sid'][s])] if asrc else store[gi][ra])
                    on = ((gi * G) >> (g + ch)) & 1 if ch >= 0 else 1
                    Bv.append(F[('F', pl['fid'][s][slot] if on else 0)])
            if any(x is None for x in A):
                raise AssertionError(f"{self.name}: 'rec' reads a store entry never written")
            ins = {'A': A, 'B': Bv}
            ins.update({pn: [qv[pn]] * len(A) for pn in self.genMultiplier.qPorts()})
            P = dp.run(ins)['P']
            i = 0
            for s, y, args, gis in pend:
                for gi in gis:
                    store[gi][y % SD] = P[i]
                    if args is None or args[4]:
                        j = gi * G + (y & (G - 1))
                        if s <= b:
                            tabs['c'][j][s] = P[i]
                        else:
                            tabs['t'][j][(1 << (s - b)) - 2 + (y >> g)] = P[i]
                    i += 1
            pend.clear()
            busy.clear()
        allg = list(range(NG))
        for ui, u in enumerate(self.recUnits(1, G, pl.get('K', 0))):
            if u[1] == 'B':
                continue
            if u[1] == 'S':
                args, gis = None, ([2 * u[3], 2 * u[3] + 1] if NG > 1 else [0])
            else:
                args, gis = u[3], allg
                if not args[0]:
                    for gi in gis:
                        w = wpos[gi][args[1]]
                        if w is not None and ui - w < PG:
                            raise AssertionError(f"{self.name}: 'rec' unit {ui} (stage {u[0]}, entry {u[2]}) reads "
                                                 f"store entry {args[1]} only {ui - w} units after its write "
                                                 f"(PG {PG})")
            if (args is not None and not args[0] and args[1] in busy) or (u[2] % SD) in busy:
                flush()
            pend.append((u[0], u[2], args, gis))
            busy.add(u[2] % SD)
            for gi in gis:
                wpos[gi][u[2] % SD] = ui
        flush()
        for kind in ('t', 'c'):
            for j in range(B):
                ref = self.twiddleTable(j, q, kind)[0]
                if tabs[kind][j] != ref:
                    bad = next(i for i in range(len(ref)) if tabs[kind][j][i] != ref[i])
                    raise AssertionError(f"{self.name}: 'rec' table {kind} of butterfly {j} differs at entry {bad} "
                                         f"(q {q})")
        return tabs

    def _simulateJobRec(self, polys: int, valid=None, pipelineStages=1, maxCycles: int | None = None,
                        records=None, twValid=None, G: int | None = None, unsafe: bool = False,
                        K: int | None = None) -> dict:
        """The controller of twiddleSource 'rec' (recycle), cycle by cycle, as `IterNTT_RTL_gen` builds it.
        As `_simulateJobRns`, except the DATA phase: the loader issues the record's units (`recUnits`) in
        order, at most one a cycle: a stream beat when tw_valid, a generator operation or bubble any cycle,
        each only when its region is free (recycle permission, by the unit's own region). A unit issued in
        cycle c writes on edge c + PG; the loader's region count (the stage hold), DATA's end and the next
        header follow the writes (PG - 1 cycles after the issue), so the header register that holds the
        generators' modulus constants changes only after the record's last operation."""
        valid = valid or (lambda c: True)
        twValid = twValid or (lambda c: True)
        L, T, NB = self.L, self.T, self.beats
        if self.recIp and self._seedReq:        # in place with seeds: the group and K as chosen, or as given
            G = G or self.recGroup(pipelineStages)
            K = self.recSeedCount(pipelineStages) if K is None else K
        units = self.recUnits(pipelineStages, G, K)
        NU = len(units)
        PG = self.recWriteLatency(pipelineStages, G)
        pw = self.writeLatency(pipelineStages)
        QB = self.Rx() + self.xr + self.buLatency(pipelineStages)
        gaps = [x - T for x in self.stageOffsets(pipelineStages)] + [0]
        olat = self.outLatency(pipelineStages)
        if self.recIp and self._seedReq:
            HB, NS = self.headerBeats(K=K), self.recStreamBeats(pipelineStages, G, K)
        else:
            HB, NS = self.headerBeats(), self.recStreamBeats()
        keeps = [bool(x) for x in (records if records is not None else [False] * polys)]
        if len(keeps) != polys or keeps[0]:
            raise ValueError(f'{self.name}: records: one per polynomial, the first with a modulus (keep False)')
        total = sum(HB + (0 if k else NS) for k in keeps)
        HDR, DATA, WAIT = 0, 1, 2
        smask = (1 << max(1, (L - 1).bit_length())) - 1
        fset = fptr = 0
        ns, nx, rs = self.numSets(), self.nextSet, self.resultSet
        full, busy, res = [0] * ns, [0] * ns, [0] * ns
        cact = cset = cnext = s = tau = gap = 0
        dsr = [(0, 0)] * pw
        dact = dset = dnext = dptr = 0
        dnext = rs(0)
        lst, lahead, ws, hptr, nkeep, qw, relst, twok = HDR, 1, 0, 0, 0, 0, L, 0
        iu, ifin = 0, 0
        pipe = [None] * max(0, PG - 1)          # the units issued 1 .. PG-1 cycles ago (write side lags)
        lrec = tsent = nstart = 0
        cur = -1
        acc_c, out_c, starts = [], [], []
        issues, writes, hdr, switch = {}, {}, {}, {}
        fpoly = 0
        c = 0
        limit = maxCycles or (polys + 4) * 4 * (max(self.computeCycles(pipelineStages), 2 * NB, HB + NU)
                                                + 4 * pw + 64) + 400
        while (len(out_c) < polys or (out_c and len(out_c[-1]) < NB)) and c < limit:
            iv = valid(c) and fpoly < polys
            fill_ok = (not full[fset]) and (not busy[fset]) and \
                      ((not res[fset]) or (dact and dset == fset and fptr < dptr))
            acc = iv and fill_ok
            flast = fptr == NB - 1
            issue = cact and gap == 0 and (twok if not unsafe else True)
            tlast = tau == T - 1
            clast = issue and tlast and s == L - 1
            hdr_ok = (lst == WAIT or (lst == DATA and lahead))
            if unsafe:
                hdr_ok = lst in (WAIT, DATA)
            startc = full[cnext] and hdr_ok and (((not cact) or clast) if (nkeep or unsafe or self.qInline) else
                                                 ((not cact) and qw == 0))
            dlastb = dact and dptr == NB - 1
            startd = res[dnext] and ((not dact) or dlastb)
            done, dn_set = dsr[pw - 1]
            u = units[iu] if lst == DATA and not ifin else None
            perm = ((not lahead) or relst > u[0]) if (u is not None and not unsafe) else True
            more = twValid(c) and tsent < total
            hacc = lst == HDR and more
            iss = u is not None and perm and (more if u[1] == 'S' else True)
            wev = pipe[-1] if pipe else (u if iss else None)       # the unit whose write is on the next edge
            # records
            if acc:
                if fptr == 0:
                    acc_c.append([])
                acc_c[-1].append(c)
            if dact:
                if dptr == 0:
                    out_c.append([])
                out_c[-1].append(c + olat)
            if issue:
                w = issues.setdefault((cur, s), [c, c])
                w[1] = c
            if hacc or (iss and u[1] == 'S'):
                tsent += 1
            if iss and u[1] != 'B':
                w = writes.setdefault((lrec, u[0]), [c + PG, c + PG])     # the table write edge
                w[1] = c + PG
            # the loader's next state: header (stream), issue side, write side
            lst_n, lahead_n, ws_n, hptr_n, nkeep_n, lrec_n, iu_n, ifin_n = lst, lahead, ws, hptr, nkeep, lrec, iu, ifin
            if lst == HDR:
                if hacc:
                    if hptr == HB - 1:
                        hptr_n = 0
                        nkeep_n = int(keeps[lrec])
                        hdr[lrec] = c
                        if keeps[lrec]:
                            lst_n = WAIT
                        else:
                            lst_n, ws_n, lahead_n, iu_n, ifin_n = DATA, 0, 1, 0, 0
                    else:
                        hptr_n = hptr + 1
            elif lst == DATA:
                if startc:
                    lahead_n = 0
                if iss:
                    iu_n, ifin_n = (iu + 1, 0) if not u[5] else (0, 1)
                if wev is not None:
                    if wev[4]:
                        ws_n = ws + 1
                    if wev[5]:
                        ws_n = 0
                        if lahead and not startc:
                            lst_n = WAIT
                        else:
                            lst_n, lrec_n = HDR, lrec + 1
            elif lst == WAIT and startc:
                lst_n, lrec_n = HDR, lrec + 1
            if pipe:
                pipe = [u if iss else None] + pipe[:-1]
            # the controller's next state (as simulateJob)
            s_n = 0 if startc else ((s + 1) & smask if (issue and tlast) else s)
            tau_n = 0 if startc else ((0 if tlast else tau + 1) if issue else tau)
            if acc:
                fptr = 0 if flast else fptr + 1
                if flast:
                    full[fset] = 1
                    if not self.recIp and not self._cgReserveAtStart:
                        busy[rs(fset)] = 1
                    fset = nx(fset)
                    fpoly += 1
            dsr = [(1 if clast else 0, rs(cset))] + dsr[:-1]
            qw = QB if clast else (qw - 1 if qw else 0)
            relst = 0 if startc else (L if clast else (s if (issue and tau == 0) else relst))
            twok = tau_n != 0 or not (lst_n == DATA and not lahead_n) or ws_n > s_n
            if startc:
                starts.append(c + 1)
                cur = nstart
                nstart += 1
                if not nkeep:
                    switch[cur] = c
                full[cnext] = 0
                if self.recIp or self._cgReserveAtStart:
                    busy[rs(cnext)] = 1
                cact, cset, cnext, s, tau, gap = 1, cnext, nx(cnext), 0, 0, 0
            elif clast:
                cact = 0
            elif issue:
                if tlast:
                    gap = gaps[s]
                    s, tau = s + 1, 0
                else:
                    tau += 1
            elif cact and gap:
                gap -= 1
            if done:
                busy[dn_set] = 0
                res[dn_set] = 1
            if dlastb:
                res[dset] = 0
            if startd:
                dact, dset, dnext, dptr = 1, dnext, nx(dnext), 0
            elif dlastb:
                dact = 0
            elif dact:
                dptr += 1
            lst, lahead, ws, hptr, nkeep, lrec, iu, ifin = lst_n, lahead_n, ws_n, hptr_n, nkeep_n, lrec_n, iu_n, ifin_n
            c += 1
        if c >= limit:
            raise AssertionError(f'{self.name}: the job did not finish in {limit} cycles')
        first_in = acc_c[0][0]
        last_out = out_c[-1][-1]
        ivs = [out_c[k + 1][0] - out_c[k][0] for k in range(len(out_c) - 1)]
        return {'accept': acc_c, 'out': out_c, 'starts': starts,
                'latency': out_c[0][-1] - acc_c[0][0] + 1,
                'jobCycles': last_out - first_in + 1,
                'interval': max(ivs) if ivs else None,
                'records': keeps, 'issues': issues, 'writes': writes, 'headers': hdr, 'switch': switch,
                'twLanes': 2, 'twBeats': total, 'recUnits': NU, 'genLatency': PG}

    def _simulateJobRns(self, polys: int, valid=None, pipelineStages=1, maxCycles: int | None = None,
                        records=None, twValid=None, TL: int | None = None, unsafe: bool = False) -> dict:
        """The controller of the RNS modes, cycle by cycle, as `IterNTT_RTL_gen` builds it.

        The record stream (tw_valid / tw_ready / tw_data, TL entries a beat) carries one
        record per polynomial, in order: `headerBeats` beats (keep bit, the modulus
        constants), then, unless keep, the twiddles in stage-major order (`stageBeats`;
        in a stage: direction, entry, then groups of TL butterflies). The loader:
        HDR (takes the header; the previous record's polynomial has started, so its
        constants were taken) -> DATA (the twiddles) -> WAIT (record done, its
        polynomial not started) -> HDR. 'recycle': a beat of stage s is taken only when
        the polynomial before has released stage s (issued its first cycle of a later
        stage, or finished), and a stage of a polynomial starts only when its region is
        written; a polynomial may start once its header is in. 'double': the record goes
        into the other copy, always free; a polynomial starts once its record is in.
        A polynomial with a new modulus starts only when the one before has drained its
        butterflies (`rnsBubble`); the constants and the copy switch at its start.
        `unsafe` (gate 7's negative test only): no region permission, no stage hold, no
        bubble, so `checkTwiddleWindows` must find the overwrites."""
        if self.rec:
            return self._simulateJobRec(polys, valid, pipelineStages, maxCycles, records, twValid, unsafe=unsafe)
        valid = valid or (lambda c: True)
        twValid = twValid or (lambda c: True)
        recyc = self.twiddleBuffer == 'recycle'
        L, T, NB = self.L, self.T, self.beats
        TL = TL or self.twiddleLanes(pipelineStages)
        pw = self.writeLatency(pipelineStages)
        QB = self.Rx() + self.xr + self.buLatency(pipelineStages)
        gaps = [x - T for x in self.stageOffsets(pipelineStages)] + [0]
        olat = self.outLatency(pipelineStages)
        HB, NBs = self.headerBeats(TL), self.stageBeats(TL)
        keeps = [bool(x) for x in (records if records is not None else [False] * polys)]
        if len(keeps) != polys or keeps[0]:
            raise ValueError(f'{self.name}: records: one per polynomial, the first with a modulus (keep False)')
        # the output twist (rtw): a last region L in every record, into twist copy = the polynomial's result set; the
        # copy is free once the polynomial two before has drained it (twfull), and a drain waits for its copy
        rtw = self.twistOn
        TWB = self.twistBeats(TL) if rtw else 0
        if rtw:
            NBs = list(NBs) + [TWB]
        total = sum(HB + (0 if k else sum(NBs[:L])) + TWB for k in keeps)
        twfull, lcopyT = [0, 0], 0
        # the twist multipliers' modulus constants are quasi-static: a drain starts only when the one before has
        # left them (TQ = R + 2 + twist latency cycles after its last issue), so the constants switch between
        TQ = self.R + 2 + self.twistLatency(pipelineStages) if rtw else 0
        dgw = 0
        HDR, DATA, WAIT = 0, 1, 2
        smask = (1 << max(1, (L - 1).bit_length())) - 1
        fset = fptr = 0
        ns, nx, rs = self.numSets(), self.nextSet, self.resultSet
        cg = self.memOrg == 'constgeo'
        full, busy, res = [0] * ns, [0] * ns, [0] * ns
        cact = cset = cnext = s = tau = gap = 0
        dsr = [(0, 0)] * pw
        dact = dset = dnext = dptr = 0
        dnext = rs(0)
        lst, lahead, ls, lk, hptr, nkeep, qw, relst, twok = HDR, 1, 0, 0, 0, 0, 0, L, 0
        lrec = tsent = nstart = 0
        cur = -1
        acc_c, out_c, starts = [], [], []
        issues, writes, hdr, switch = {}, {}, {}, {}
        fpoly = 0
        c = 0
        limit = maxCycles or (polys + 4) * 4 * (max(self.computeCycles(pipelineStages), 2 * NB,
                                                     HB + sum(NBs)) + 4 * pw + 64) + 400
        while (len(out_c) < polys or (out_c and len(out_c[-1]) < NB)) and c < limit:
            iv = valid(c) and fpoly < polys
            fill_ok = (not full[fset]) and (not busy[fset]) and \
                      ((not res[fset]) or (dact and dset == fset and fptr < dptr))
            acc = iv and fill_ok
            flast = fptr == NB - 1
            issue = cact and gap == 0 and (twok if recyc and not unsafe else True)
            tlast = tau == T - 1
            clast = issue and tlast and s == L - 1
            hdr_ok = (lst == WAIT or (lst == DATA and lahead)) if recyc else lst == WAIT
            if rtw and not recyc:              # double: the twist region does not hold the start (only the drain)
                hdr_ok = hdr_ok or (lst == DATA and lahead and ls == L)
            if unsafe:
                hdr_ok = lst in (WAIT, DATA)
            startc = full[cnext] and hdr_ok and (((not cact) or clast) if (nkeep or unsafe or self.qInline) else
                                                 ((not cact) and qw == 0))
            dlastb = dact and dptr == NB - 1
            if rtw:
                startd = res[dnext] and twfull[dnext] and (not dact) and dgw == 0
            else:
                startd = res[dnext] and ((not dact) or dlastb)
            done, dn_set = dsr[pw - 1]
            perm = ((not lahead) or relst > ls) if recyc and not unsafe else True
            if rtw and ls == L:
                perm = not twfull[lcopyT]
            tready = lst == HDR or (lst == DATA and perm)
            tacc = twValid(c) and tsent < total and tready
            # records
            if acc:
                if fptr == 0:
                    acc_c.append([])
                acc_c[-1].append(c)
            if dact:
                if dptr == 0:
                    out_c.append([])
                out_c[-1].append(c + olat)
            if issue:
                w = issues.setdefault((cur, s), [c, c])
                w[1] = c
            if tacc:
                tsent += 1
                if lst == DATA:
                    w = writes.setdefault((lrec, ls), [c + 1, c + 1])     # the table write edge
                    w[1] = c + 1
            # the loader's next state
            lst_n, lahead_n, ls_n, lk_n, hptr_n, nkeep_n, lrec_n = lst, lahead, ls, lk, hptr, nkeep, lrec
            if lst == HDR:
                if tacc:
                    if hptr == HB - 1:
                        hptr_n = 0
                        nkeep_n = int(keeps[lrec])
                        hdr[lrec] = c
                        if keeps[lrec] and rtw:
                            lst_n, ls_n, lk_n, lahead_n = DATA, L, 0, 1          # the twist region only
                        elif keeps[lrec]:
                            lst_n = WAIT
                        else:
                            lst_n, ls_n, lk_n, lahead_n = DATA, 0, 0, 1
                    else:
                        hptr_n = hptr + 1
            elif lst == DATA:
                if startc:
                    lahead_n = 0
                if tacc:
                    if lk == NBs[ls] - 1:
                        lk_n, ls_n = 0, ls + 1
                        if rtw and ls == L:
                            twfull[lcopyT] = 1
                            lcopyT ^= 1
                        if ls == (L if rtw else L - 1):
                            ls_n = 0
                            if lahead and not startc:
                                lst_n = WAIT
                            else:
                                lst_n, lrec_n = HDR, lrec + 1
                    else:
                        lk_n = lk + 1
            elif lst == WAIT and startc:
                lst_n, lrec_n = HDR, lrec + 1
            # the controller's next state (as simulateJob)
            s_n = 0 if startc else ((s + 1) & smask if (issue and tlast) else s)      # the RTL's s counter width
            tau_n = 0 if startc else ((0 if tlast else tau + 1) if issue else tau)
            if acc:
                fptr = 0 if flast else fptr + 1
                if flast:
                    full[fset] = 1
                    if cg and not self._cgReserveAtStart:
                        busy[rs(fset)] = 1        # constgeo: reserve the result set (the scratch for L odd) now
                    fset = nx(fset)
                    fpoly += 1
            dsr = [(1 if clast else 0, rs(cset))] + dsr[:-1]
            qw = QB if clast else (qw - 1 if qw else 0)
            if recyc:
                relst = 0 if startc else (L if clast else (s if (issue and tau == 0) else relst))
                twok = tau_n != 0 or not (lst_n == DATA and not lahead_n) or ls_n > s_n
            if startc:
                starts.append(c + 1)
                cur = nstart
                nstart += 1
                if not nkeep:
                    switch[cur] = c
                full[cnext] = 0
                if not cg or self._cgReserveAtStart:
                    busy[rs(cnext)] = 1
                cact, cset, cnext, s, tau, gap = 1, cnext, nx(cnext), 0, 0, 0
            elif clast:
                cact = 0
            elif issue:
                if tlast:
                    gap = gaps[s]
                    s, tau = s + 1, 0
                else:
                    tau += 1
            elif cact and gap:                         # a stage held for its twiddles keeps gap 0
                gap -= 1
            if done:
                busy[dn_set] = 0
                res[dn_set] = 1
            if rtw:
                dgw = TQ if dlastb else (dgw - 1 if dgw else 0)
            if dlastb:
                res[dset] = 0
                if rtw:
                    twfull[dset] = 0
            if startd:
                dact, dset, dnext, dptr = 1, dnext, nx(dnext), 0
            elif dlastb:
                dact = 0
            elif dact:
                dptr += 1
            lst, lahead, ls, lk, hptr, nkeep, lrec = lst_n, lahead_n, ls_n, lk_n, hptr_n, nkeep_n, lrec_n
            c += 1
        if c >= limit:
            raise AssertionError(f'{self.name}: the job did not finish in {limit} cycles')
        first_in = acc_c[0][0]
        last_out = out_c[-1][-1]
        ivs = [out_c[k + 1][0] - out_c[k][0] for k in range(len(out_c) - 1)]
        return {'accept': acc_c, 'out': out_c, 'starts': starts,
                'latency': out_c[0][-1] - acc_c[0][0] + 1,
                'jobCycles': last_out - first_in + 1,
                'interval': max(ivs) if ivs else None,
                'records': keeps, 'issues': issues, 'writes': writes, 'headers': hdr, 'switch': switch,
                'twLanes': TL, 'twBeats': total}

    def checkSets(self, job: dict, pipelineStages=1) -> list[str]:
        '''On a twin job: no bank set is used by two polynomials at once, except the drain of one and the
        lock-step fill of the next into the same set. Uses: fill of p on its set X_p (first to last accepted
        beat), compute of p (start to the drain start: its write-backs end before) on X_p and, constant
        geometry, its scratch, drain of p on its result set.'''
        olat = self.outLatency(pipelineStages)
        P = len(job['starts'])
        x, X = 0, []
        for _ in range(P):
            X.append(x)
            x = self.nextSet(x)
        use = []
        for p in range(P):
            d0, d1 = job['out'][p][0] - olat, job['out'][p][-1] - olat
            # the input is held from its first beat until its compute starts
            use.append((X[p], 'fill', p, job['accept'][p][0], max(job['accept'][p][-1], job['starts'][p] - 1)))
            sets = {X[p]} | ({self.scratchSet(X[p])} if self.memOrg == 'constgeo' else set())
            for st in sets:
                end = d0 - 1
                if st != self.resultSet(X[p]) and p + 1 < P:
                    # the set the last stage reads: handed to the next polynomial at the last issue (it starts
                    # there at the earliest and writes Pw later: checkHazards)
                    end = min(end, job['starts'][p + 1] - 1)
                use.append((st, 'compute', p, job['starts'][p], end))
            use.append((self.resultSet(X[p]), 'drain', p, d0, d1))
        errs = []
        for i, a in enumerate(use):
            for b_ in use[i + 1:]:
                if a[0] != b_[0] or a[2] == b_[2] or a[4] < b_[3] or b_[4] < a[3]:
                    continue
                pair = {a[1], b_[1]}
                if pair == {'fill', 'drain'}:
                    continue                 # lock-step (fill_ok: fptr < dptr)
                errs.append(f'set {a[0]}: {a[1]} of poly {a[2]} [{a[3]}, {a[4]}] overlaps {b_[1]} of poly '
                            f'{b_[2]} [{b_[3]}, {b_[4]}]')
        return errs

    def checkTwiddleWindows(self, job: dict, pipelineStages=1) -> list[str]:
        """On a twin job of an RNS mode: every polynomial reads each stage's twiddles
        (read edge = issue + 1) strictly after the last write of its modulus's record
        into that region and strictly before the first write of the record that next
        overwrites it (recycle: the next modulus; double: the one after, same copy);
        every modulus switch comes after the polynomial before has used its constants
        (start >= its last issue + R + Pbu + 1); every header is taken after the start
        of the polynomial before (so the constants it replaces were taken)."""
        errs = []
        keeps = job['records']
        P = len(keeps)
        recOf, ep = [], -1
        for p, k in enumerate(keeps):
            if not k:
                ep += 1
            recOf.append(max(r for r in range(p + 1) if not keeps[r]))
        epochRec = [r for r in range(P) if not keeps[r]]
        epoch = {r: i for i, r in enumerate(epochRec)}
        step = 1 if self.twiddleBuffer == 'recycle' else 2
        QB = self.Rx() + self.xr + self.buLatency(pipelineStages)
        W, I = job['writes'], job['issues']
        for p in range(P):
            r = recOf[p]
            e = epoch[r]
            nxt = epochRec[e + step] if e + step < len(epochRec) else None
            for s in range(self.L):
                if (p, s) not in I:
                    errs.append(f'poly {p} stage {s}: never issued')
                    continue
                r0, r1 = I[(p, s)][0] + 1 + self.readTree(), I[(p, s)][1] + 1 + self.readTree()
                w = W.get((r, s))
                if w is None or not w[1] < r0:
                    errs.append(f'poly {p} stage {s}: read from edge {r0}, its twiddles written until {w}')
                if nxt is not None and (nxt, s) in W and not W[(nxt, s)][0] > r1:
                    errs.append(f'poly {p} stage {s}: read until edge {r1}, overwritten from {W[(nxt, s)][0]}')
            if p and p in job['switch'] and not self.qInline:
                last = I[(p - 1, self.L - 1)][1]
                if job['switch'][p] < last + QB + 1:
                    errs.append(f'poly {p}: modulus switched at {job["switch"][p]}, poly {p - 1} issued until {last}')
            if p and job['headers'].get(p) is not None and job['headers'][p] < job['starts'][p - 1]:
                errs.append(f'record {p}: header taken before poly {p - 1} started')
            if self.twistOn:
                # the twist region (copy p mod 2): written after poly p-2 drained that copy, before poly p's drain
                olat = self.outLatency(pipelineStages)
                tw = W.get((p, self.L))
                d0 = job['out'][p][0] - olat
                if tw is None or not tw[1] < d0 + 1:
                    errs.append(f'poly {p}: twist written until {tw}, drained from issue {d0}')
                if p >= 1 and job['out'][p][0] - job['out'][p - 1][-1] < self.twistGap(pipelineStages) + 1:
                    errs.append(f'poly {p}: drained {job["out"][p][0] - job["out"][p - 1][-1]} cycles after poly '
                                f'{p - 1}, the twist constants need {self.twistGap(pipelineStages) + 1}')
                if p >= 2 and tw is not None and not tw[0] > job['out'][p - 2][-1] - olat + 1:
                    errs.append(f'poly {p}: twist copy written from {tw[0]}, poly {p - 2} drained it until '
                                f'{job["out"][p - 2][-1] - olat}')
        return errs

    # --- timing and cost ----------------------------------------------------------------

    def latency(self, pipelineStages=1) -> int:
        '''One polynomial alone, first input beat to last output beat (always-valid input).'''
        return self.simulateJob(1, pipelineStages=pipelineStages)['latency']

    def cyclesPerPolynomial(self, pipelineStages=1) -> int:
        '''Steady state, distinct polynomials back to back: output start to output start.'''
        return self.simulateJob(4, pipelineStages=pipelineStages)['interval']

    def criticalPathNs(self, pipelineStages=1) -> float:
        ns = [self.butterflyUnit().criticalPathNs(pipelineStages)]
        if self.twistMultiplier is not None:
            ns.append(self.twistMultiplier.criticalPathNs(pipelineStages))
        return max(ns)

    def readSources(self) -> tuple[list[list[int]], list[list[tuple[int, int]]]]:
        '''Per butterfly operand port (A_j at 2j, B_j at 2j+1): the banks it reads over
        all stages; per bank: the (butterfly, output) pairs it is written from.'''
        B = self.B
        rs = [set() for _ in range(2 * B)]
        ws = [set() for _ in range(2 * B)]
        for s in range(self.L):
            for f in (0, 1):
                t = next((t for t in range(self.T) if self.flip(s, t) == f), None)
                if t is None:
                    continue
                for j in range(B):
                    ka, kb = self.readBanks(s, t, j)
                    rs[2 * j].add(ka); rs[2 * j + 1].add(kb)
                    ws[ka].add((j, 0)); ws[kb].add((j, 1))
        return [sorted(x) for x in rs], [sorted(x) for x in ws]

    def decodeTables(self) -> tuple[list[dict], list[dict]]:
        '''For the RTL's select decoders: per operand port {(stage, flip): index into
        its `readSources` list}; per bank {(stage, flip): index into its write sources}.'''
        rs, ws = self.readSources()
        rdec = [dict() for _ in rs]
        wdec = [dict() for _ in ws]
        for s in range(self.L):
            for f in (0, 1):
                t = next((t for t in range(self.T) if self.flip(s, t) == f), None)
                if t is None:
                    continue
                for j in range(self.B):
                    ka, kb = self.readBanks(s, t, j)
                    rdec[2 * j][(s, f)] = rs[2 * j].index(ka)
                    rdec[2 * j + 1][(s, f)] = rs[2 * j + 1].index(kb)
                    wdec[ka][(s, f)] = ws[ka].index((j, 0))
                    wdec[kb][(s, f)] = ws[kb].index((j, 1))
        return rdec, wdec

    def memories(self) -> list[dict]:
        '''Every RAM: {what, count, depth, width, style, cost}.'''
        W = self.memBound.bitWidth
        tw = max(1, (self.qMax() - 1).bit_length())
        cols = 2 if self.shoup() else 1
        cp = lambda d: d if self.twiddleBuffer != 'double' else 2 << (d - 1).bit_length()   # two copies
        if self.multiRom:              # moduli=: a block of 2^ceil(log2 d) entries per modulus
            cp = self.mromDepth
        if self.memOrg == 'constgeo':
            # 3 sets of 2B banks; one twiddle table per butterfly (every stage's region), no stage constants
            out = [dict(what='data bank', count=3 * 2 * self.B, depth=self.T, width=W, style=self.memStyle),
                   dict(what='twiddle table', count=self.B * cols, depth=cp(self.tdepth * self.twDirs()),
                        width=tw if cols == 1 else max(tw, self._wpWidth()), style=self.twiddleStyle)]
            if self.twistOn:
                out.append(dict(what='twist table', count=self.io, depth=self.mromDepth(self.beats * (2 if self.rns else len(self.dirs))), width=tw,
                                style=self.twiddleStyle))
            for x in out:
                x['cost'] = ramCost(x['depth'], x['width'], x['style'])
                x['style'] = x['cost']['style']
            return out
        out = [dict(what='data bank', count=4 * self.B, depth=self.T, width=W, style=self.memStyle)]
        out.append(dict(what='twiddle table', count=self.B * cols, depth=cp(self.tdepth * len(self.tdirs)),
                        width=tw if cols == 1 else max(tw, self._wpWidth()), style=self.twiddleStyle))
        out.append(dict(what='stage-constant table', count=self.B * cols, depth=cp(self.cdepth * len(self.tdirs)),
                        width=tw if cols == 1 else max(tw, self._wpWidth()), style='distributed'))
        if self.twistOn:
            out.append(dict(what='twist table', count=self.io, depth=self.mromDepth(self.beats * (2 if self.rns else len(self.dirs))), width=tw,
                            style=self.twiddleStyle))
        for x in out:
            x['cost'] = ramCost(x['depth'], x['width'], x['style'])
            x['style'] = x['cost']['style']
        return out

    # --- moduli= (multi-modulus ROM) ------------------------------------------------------

    def mromDepth(self, d: int) -> int:
        '''A table's depth with moduli=: one block of 2^ceil(log2 d) entries per modulus (address {MIDX, the
        one-modulus address}); without moduli=: d.'''
        if not self.multiRom:
            return d
        return len(self.moduli) << max(1, (d - 1).bit_length())

    def modulusIndexBits(self) -> int:
        '''Width of MIDX / midx_out (moduli=), 0 without.'''
        return max(1, (len(self.moduli) - 1).bit_length()) if self.multiRom else 0

    def modulusTable(self) -> dict:
        '''moduli=: per modulus constant (Q, MU, ..., QHALF) its value for each modulus, in `moduli` order.'''
        rows = [self.qPortValues(q) for q in self.moduli]
        return {p: [r[p] for r in rows] for p in self.qPorts()}

    def modulusColumns(self) -> dict:
        '''moduli=: the ROM words seen per bit. {port: bits that differ between the moduli}, and under
        'distinct' the number of different non-constant bit columns over all ports. A bit that is the same for
        every modulus is a constant in the emitted ROM function (its default is the first modulus), so it has no
        ROM logic and no register anywhere; equal columns are one register.'''
        tab = self.modulusTable()
        wd = dict(self.qPortWidths())
        out, seen = {}, set()
        for p_, vals in tab.items():
            cols = [tuple((v >> b_) & 1 for v in vals) for b_ in range(wd[p_])]
            var = [c for c in cols if len(set(c)) > 1]
            out[p_] = len(var)
            seen |= set(var)
        out['distinct'] = len(seen)
        return out

    def modulusTableLuts(self) -> tuple[int, int]:
        '''moduli=: (LUTs, registers) of the constants' ROMs and tags. Per bank set a ROM of len(moduli) words
        with its output register (the set's constants, ready before its compute starts); the twist multipliers'
        ROM at the drain; the per-set / compute / drain tags and the output tag's delay. Only the different
        non-constant bit columns of the ROM words count (modulusColumns; routed, 3 moduli of 36 bit: 6 columns,
        22 LUTs and 22 registers).'''
        if not self.multiRom:
            return 0, 0
        w = self.modulusColumns()['distinct']
        M = len(self.moduli)
        sets = self.numSets()
        tagw = self.modulusIndexBits() + (1 if self.direction == 'both' else 0)
        tw = 0
        if self.twistMultiplier is not None:
            tw = min(w, sum(wd for p, wd in self.qPortWidths() if p in self.twistMultiplier.qPorts()))
        rom = -(-M // 64) * (w * sets + tw)
        ff = w * sets + tw + tagw * (sets + 2 + (sets if self.memOrg == 'constgeo' else 0) + 4)
        return rom + w * (1 if sets <= 2 else 2), ff      # + the start's set select (2:1 / 3:1 per bit)

    def twDirs(self) -> int:
        '''Directions a twiddle table holds: those stored (`tdirs`); constant geometry with a record stream
        (RNS): one, the job's direction (DIR), carried by each polynomial's record.'''
        if self.memOrg == 'constgeo' and self.rns:
            return 1
        return len(self.tdirs)

    def _wpWidth(self) -> int:
        return self.butterflyUnit().defaultPortBound('WP').bitWidth

    def resources(self, pipelineStages=1, muxLut=None) -> dict:
        '''The model's estimate: {'lut', 'ff', 'dsp', 'bram', 'uram'} and a breakdown.'''
        bu = self.butterflyUnit()
        B, W = self.B, self.memBound.bitWidth
        lb, db = bu.areaCost()
        ffb = bu.flipFlops(pipelineStages)
        mux = lambda k: 0 if k <= 1 else -(-(k - 1) // 3)            # LUT6 levels of a k:1 mux, per bit
        if muxLut is not None:
            mux = lambda k: muxLut(k, W) / W
        # Top-level terms, settled on the routed netlists of 2026-11-14 (iterative/MODEL_ACCURACY.md). `rho`: share of
        # the in-place select LUTs left after synthesis merges selects that few stages use (small B: few sources).
        tw = max(1, (self.qMax() - 1).bit_length())
        sets = 3 if self.memOrg == 'constgeo' else 2
        rho = min(1.0, 0.55 + 0.09 * math.log2(max(1, B)))
        if self.memOrg == 'constgeo':
            # fixed wiring: per operand port the read set (3:1; B = 1 also the A/B swap); per bank and set the
            # write data (2 butterflies, or the fill) into the set's write register (measured 4.9 to 6.0 LUT per
            # bit of 2B banks: 5.5); drain: per bank the set select, per lane the mux over its 2B / io banks
            rmux = 2 * B * W * (mux(3) + (1 if self.b == 0 else 0))
            wmux = int(round(5.5 * B * W * mux(3)))
            omux = 2 * B * W + self.io * W * mux(2 * B // self.io)
            twsel = 0
            ctll = 300 + B * W // 10
            ctlf = 150 + int(round(0.72 * B * W))
        else:
            rs, ws = self.readSources()
            rmux = int(round(rho * sum(W * (mux(len(x)) + 1) for x in rs)))                 # +1: the set (2:1) select
            wmux = int(round(rho * (sets * 2 * B * W + sum(W * (mux(len(x) + 1)) for x in ws))))   # +1: the fill data; per set the enable
            omux = self.io * W * mux(2 * 2 * B // self.io)
            twsel = int(round(rho * B * tw))                                # table or stage-constant entry
            ctll = 240 + 30 * B + B * B // 5
            ctlf = 290 + B * W // 2 + 2 * B * B // 5
        if not self.stageHalve:
            halve = 0
        elif self.direction != 'both':
            halve = 2 * B * W
        else:                             # the halver's select packs with the swap mux in the fixed wiring
            halve = 2 * B * W * 2 if self.memOrg != 'constgeo' else 3 * B * W
        if not self.qPorts() and self.memOrg != 'constgeo':
            # fixed modulus, in place (the only routed evidence: Da_n1024_q28f_B8, 3985 / 298 / 254): QHALF is a
            # constant (halver 1.5 LUT per bit), no modulus control
            halve = halve * 3 // 4 if self.direction == 'both' else halve
            ctll, ctlf = ctll - 190, ctlf - 170
        brk = {'butterflies': (B * lb, B * db), 'read mux': rmux, 'write mux': wmux, 'output mux': omux,
               'halvers': halve, 'twiddle select': twsel, 'control': (ctll, ctlf)}
        lut = B * lb + rmux + wmux + omux + halve + twsel + ctll
        # registers: write data per set and bank, drain lanes, operand B (operand A waits in the butterfly's own
        # delay), twiddle, both butterfly outputs; the modulus: per butterfly a copy of each port it reads (and
        # QHALF for the stage halver), at the top one copy per 16 butterflies (max_fanout 16), the next modulus
        # ('rns') and the delayed one (qSwitch 'inline')
        qw = dict(self.qPortWidths()) if self.qPorts() else {}
        buIn = set(bu.inner().datapath().inputs) if qw else set()
        qsum = sum(qw.values())
        # a copy that feeds a LUT (Booth) multiplier is replicated on its loads (max_fanout 16:
        # `emitcount.portCopies`)
        from ...core.emitcount import portCopies
        bdp = bu.inner().datapath() if qw else None
        if self.multiRom:                 # moduli=: only the bits that differ between the moduli keep a register
            mc = self.modulusColumns()
            qw = {p_: mc[p_] for p_ in qw}
            qsum = mc['distinct']
        bq = B * sum(portCopies(bdp, p_, w) if p_ in buIn else w
                     for p_, w in qw.items() if p_ in buIn or (p_ == 'QHALF' and self.stageHalve))
        qtop = (qsum * (max(1, -(-B // 16)) + (1 if self.rns else 0) + (1 if getattr(self, 'qSwitch', None) == 'inline' else 0)) + 1) if qw else 0
        parts = {'write data': sets * 2 * B * W, 'drain': self.io * W, 'operand': B * W, 'twiddle': B * tw,
                 'butterfly outputs': 2 * B * W, 'butterfly modulus copies': bq, 'top modulus copies': qtop, 'control': ctlf}
        ff = B * ffb + sum(parts.values())
        if self.multiRom and bdp is not None:
            # moduli=: a bit column of a modulus port that is 0 in every modulus is a constant, so the butterfly's
            # delay lines of that port have no cell there (routed W_Mx_n2048_q44_B4_m5_ip_qi: Q 33 of 44 columns,
            # MU 45; the same rule as HybridArea R8 and StreamArea R13 b)
            try:
                from ...core import emitcount as _EC
                import contextlib as _cl, io as _io
                with _cl.redirect_stdout(_io.StringIO()):
                    _rows = _EC.nodeRows(bdp, bu.inner().schedule(pipelineStages))
                _tab, _df, _ds = self.modulusTable(), 0.0, 0.0
                for _r in _rows:
                    _b = _r.name.rsplit('_d', 1)[0]
                    if _r.kind != 'delay' or '_d' not in _r.name or _b not in _tab or ' bit x ' not in _r.note:
                        continue
                    _w = int(_r.note.split(' bit x ')[0].split()[-1])
                    _one = 0
                    for _v in _tab[_b]:
                        _one |= _v
                    _dead = max(0.0, 1 - bin(_one & ((1 << _w) - 1)).count('1') / max(1, _w))
                    _df += _r.ff * _dead
                    _ds += _r.srl * _dead
                parts['butterfly modulus delay, constant columns'] = -round(B * _df)
                ff -= round(B * _df)
                lut -= round(B * _ds / 2)
            except Exception:
                pass
        if self.xr:                       # crossRegs: per stage the operand and twiddle registers that stay flip-flops
            # (routed, 2 stages: 4.3 B W; the other stages go into the butterflies' delay chains and the registers
            # already there); per bank the read and write address registers (the address fan-out is no longer shared)
            xa = sets * 2 * B * (2 * max(1, (self.T - 1).bit_length()) + 1)
            xf = self.xr * (B * W + B * tw) + xa
            ff += xf
            lut += sets * 2 * B * max(1, (self.T - 1).bit_length())
            brk['cross registers'] = self.xr
            parts['cross registers'] = xf
        brk['parts'] = parts
        dsp = B * db
        if self.rns:
            # the record loader: per butterfly an entry register and two table write ports (we, address),
            # the header (next constants) register, counters and decode
            TA = max(1, (self.tdepth * self.twDirs() - 1).bit_length()) + (self.twiddleBuffer == 'double')
            CA = max(1, (max(1, self.cdepth) * self.twDirs() - 1).bit_length()) + (self.twiddleBuffer == 'double')
            ldf = B * (self.twEntryWidth() + TA + CA + 2) + self.headerBits() + 64
            if not self.rec:
                # counted from the emitted loader (iter_ntt.py): lw_wd<j> takes stream lane j % TL, so only TL
                # entry registers differ (equal registers are merged); the write enables differ per beat phase
                # (B / TL of each kind); the two write addresses are shared, one copy per 16 RAM primitives
                # (max_fanout 16). Routed (B 64, 64 bit, TL 16): 1024 entry registers, 88 + 60 address registers.
                # The control term was fitted on rows with the plain loader (tw_wen), which a record design
                # does not have: its registers come off (the entry counter, the data register per 32 block RAMs,
                # a hit per table, the per-table write addresses: bit i of (counter - k x span) has
                # min(B, 2^(i+1) / lowest set bit of the span) different values over the tables k)
                TL = self.twiddleLanes(pipelineStages)
                prim = {m_['what']: m_['count'] * (-(-m_['cost']['lut'] // 8) + int(-(-m_['cost']['bram'] // 1)) + m_['cost']['uram'])
                        for m_ in self.memories() if m_['what'] in ('twiddle table', 'stage-constant table')}
                pt, pc_ = prim.get('twiddle table', B), prim.get('stage-constant table', B)
                ldf = (TL * self.twEntryWidth() + 2 * -(-B // TL) + TA * -(-pt // 16) + CA * -(-pc_ // 16)
                       + self.headerBits() + 64)
                span = self.tdepth * self.twDirs() + max(1, self.cdepth) * self.twDirs()
                low = span & -span
                diff = lambda bits, off=1: sum(min(B, max(1, (2 << i) // low)) for i in range(bits))
                nblk = sum(m_['count'] * int(-(-m_['cost']['bram'] // 1)) for m_ in self.memories()
                           if m_['what'] in ('twiddle table', 'stage-constant table'))
                plain = ((B * span - 1).bit_length() + self.twEntryWidth() * max(1, -(-nblk // 32)) + 2 * B
                         + diff(TA) + diff(CA))
                ldf -= plain
            ldl = 2 * B + 16 * (TA + CA) + 64
            brk['record loader'] = (ldl, ldf)
            lut += ldl
            ff += ldf
        if self.multiRom:                 # moduli=: the constants' ROMs, the tags (the M-fold tables: memories())
            ml, mf = self.modulusTableLuts()
            brk['modulus table'] = (ml, mf)
            lut += ml
            ff += mf
        if self.rec:
            # on-chip twiddles: per group a modular multiplier, its store (two regions of the parent classes,
            # LUTRAM), operand and factor registers, the factor select and the group's write-data mux (stream
            # lane or multiplier); shared: the factor registers of the header, the unit ROM and the unit pipeline
            G = self.recGroup(pipelineStages)
            NG = B // G
            E = self.twEntryWidth()
            gl = gd = gf = 0
            if self.recIp:
                # in place: per group a multiplier, its store (SD entries, LUTRAM), operand and factor
                # registers and the write-data register; shared: the header's factor and seed registers and
                # their selects, the loader's counters and prefix decode, the unit pipeline
                pl = self.recIpPlan(pipelineStages, G)
                gm = self.genMultiplier
                ga, gdsp = gm.areaCost()
                gl, gd, gf = ga * NG, gdsp * NG, gm.flipFlops(pipelineStages) * NG
                WF = self.genPortWidths()['B']
                NF, NSd, PG = len(pl['fexp']), len(pl['sexp']), pl['PG']
                st = ramCost(pl['SD'], E, 'distributed')
                ul = NG * (st['lut'] + E + WF) + (WF * mux(NF) + E * mux(NSd)) + len(pl['prefix']) // 2 + 96
                uf = NG * (st['ff'] + 2 * E + WF) + WF + E + PG * (24 + G) + 96
                brk['twiddle generators'] = dict(groups=NG, group=G, units=len(self.recUnits(pipelineStages)),
                                                 genLatency=PG, store=pl['SD'], factors=NF, seeds=NSd,
                                                 lut=gl + ul, ff=gf + uf, dsp=gd)
                if pl.get('K'):
                    # seeds on the stream (recSeeds): no stage seeds in the header (NSd above still counts
                    # their select: taken off), the beat's two lanes registered once, a group mask on the
                    # store and table write enables
                    NSd = 0
                    ul = NG * (st['lut'] + E + WF) + WF * mux(NF) + len(pl['prefix']) // 2 + NG + 96
                    uf = NG * (st['ff'] + 2 * E + WF) + WF + 2 * E + PG * (24 + G + NG.bit_length()) + 96
                    brk['twiddle generators'].update(seeds=0, lut=gl + ul, ff=gf + uf, recSeeds=pl['K'],
                                                     seedWords=pl['seedWords'], seedBeats=sum(pl['seedBeats']))
                brk['twiddle generators'].update(recordBeats=self.recordBeats(), headerBeats=self.headerBeats(),
                                                 recordBits=self.headerBits() + E * pl.get('seedWords', 0))
                lut += gl + ul
                ff += gf + uf
                dsp += gd
            elif self.L > self.H + 2:
                gm = self.genMultiplier
                ga, gdsp = gm.areaCost()
                gl, gd, gf = ga * NG, gdsp * NG, gm.flipFlops(pipelineStages) * NG
            if not self.recIp:
                cs = max(1, G >> 1)
                st = ramCost(2 * cs * self.T, E, 'distributed') if self.L > self.H + 2 else {'lut': 0, 'ff': 0}
                PG = self.genLatency(pipelineStages) if self.L > self.H + 2 else 1
                NU = len(self.recUnits(pipelineStages))
                # the unit pipeline (PG - 1 stages, no reset, read at its end only): the stream data of the groups
                # (NG E bits) and the unit's fields (kind 2, two flags, the table and store write addresses, the
                # group mask G, the store write enable) are shift registers: one SRL and one end register per bit
                # (routed, PG 14: 72 SRL and 72 registers for 72 bits); the valid chain (reset) stays PG registers.
                # A pipeline of fewer than 3 stages stays registers.
                SA = max(1, (2 * cs * self.T - 1).bit_length())
                TAg = max(1, (self.tdepth * self.twDirs() - 1).bit_length()) + (self.twiddleBuffer == 'double')
                cbits = NG * E + 2 + 2 + TAg + SA + G + 1
                chl, chf = (cbits, cbits) if PG - 1 >= 3 else (0, cbits * max(0, PG - 1))
                ul = NG * (st['lut'] + 2 * E) + -(-NU // 64) * 24 + 2 * E * max(1, self.b - 1) // 3 + 64 + chl
                # the store is read through one register (`gx <= st[q_ra]`), so it has E flip-flops a group
                # whatever its depth: the slice-output registers of `ramCost` belong to a memory with two read
                # registers (routed: 512 x 44 store, 44 'gx' registers a group; 256 x 28, 28)
                stf = min(st['ff'], E)
                uf = NG * (stf + 3 * E) + 2 * E * max(1, self.b - 1) + chf + PG + 64
                brk['twiddle generators'] = dict(groups=NG, group=G, units=NU, genLatency=PG, lut=gl + ul, ff=gf + uf,
                                                 dsp=gd)
                lut += gl + ul
                ff += gf + uf
                dsp += gd
        if self.twistMultiplier is not None:
            a, d_ = self.twistMultiplier.areaCost()
            lut += a * self.io
            dsp += d_ * self.io
            ff += self.io * self.twistMultiplier.flipFlops(pipelineStages)
            brk['twist'] = (a * self.io, d_ * self.io)
        if self.fanout:
            # the trees' registers; the read delay (readTree) also lengthens the issue / drain delay chains
            fr = self.fanoutRegisters(pipelineStages)
            dr = self.readTree()
            fr += dr * (2 + 2 + 2 * self.H + 4)
            ff += fr
            brk['fan-out trees'] = dict(ff=fr, readTree=dr, genTree=self.genTree(),
                                        depths={k: len(v['levels']) for k, v in self.fanoutPlan(pipelineStages).items()})
        bram = uram = 0
        for mm in self.memories():
            c = mm['cost']
            cl = c['lut']
            if c['style'] == 'distributed' and mm['depth'] <= 32:
                cl = -(-mm['width'] // 14) * 8        # RAM32M16: 14 bits per 8 LUTs up to 32 deep (routed: Ib 24, Ic 32)
            lg = None
            if c['style'] == 'distributed' and 32 < mm['depth'] <= 64 and mm['what'] == 'data bank':
                # the emitter gives the B banks of one half of a set the same write and read address, so the tool
                # merges the bits left after the full 7-bit primitives across those banks (see lutramGroupLuts)
                lg = mm['count'] // B * lutramGroupLuts(mm['width'], B) + mm['count'] % B * cl
            cf = c['ff']
            if mm['what'] == 'stage-constant table' and not qw:
                cf = 0                                # fixed modulus: a ROM of constants, its registers merge (routed: 20 of 448)
            if c['style'] in ('block', 'ultra') and self.R > 2:
                # read latency above 2: the block holds its read register and its output register, every further
                # stage is `width` flip-flops behind it (`ram_block`: rr[R-1], rr[0] is the block's output
                # register). Routed, read latency 3: 2048 points, 40 bit, 4 butterflies: 16 banks x 40 'g_rr.rr'
                # and 4 twiddle ROMs x 40 'q0'; 131072 points, 64 bit, 64 butterflies (three rows): 256 banks
                # x 64 and 64 twiddle ROMs x 64, exactly.
                cf += (self.R - 2) * mm['width']
                brk['parts']['read registers behind block memories'] = \
                    brk['parts'].get('read registers behind block memories', 0) + (self.R - 2) * mm['width'] * mm['count']
            elif c['style'] == 'distributed' and self.R > 2 and mm['depth'] <= 64 and cf:
                # a LUT memory of one slice read through R >= 3 registers: the chain is one SRL and one end
                # register per bit (routed, read latency 3: the stage-constant tables, 64 x 64 bit: 64 registers
                # and 32 SRL sites each, 128 registers at latency 2; 4 x 40 bit: 40 each). Deeper LUT memories
                # at read latency 3 or 4 have not been measured and keep the latency 2 count.
                cf = mm['width']
                cl += -(-mm['width'] * -(-(self.R - 1) // 16) // 2)
            lut += cl * mm['count'] if lg is None else lg
            ff += cf * mm['count']
            bram += c['bram'] * mm['count']
            uram += c['uram'] * mm['count']
            brk[mm['what']] = (mm['count'], mm['depth'], mm['width'], mm['style'])
            if mm['what'] == 'data bank' and c['style'] == 'block' and B >= 16 and self.R <= 2:
                # (at read latency above 2 a fabric register follows the block already and none is pulled: routed,
                # three rows of 64 butterflies, exactly `width` registers a bank)
                # physical optimisation pulls block-RAM output registers into the fabric on wide cores (measured
                # 0 at B <= 8; 0.46 to 1.0 of count x W at B >= 16, not the same on every run): 0.8
                pulled = int(round(0.8 * mm['count'] * mm['width']))
                ff += pulled
                brk['parts']['bank output registers in fabric'] = pulled
        return {'lut': lut, 'ff': ff, 'dsp': dsp, 'bram': bram, 'uram': uram, 'breakdown': brk}

    def areaCost(self) -> tuple[int, int]:
        r = self.resources()
        return r['lut'], r['dsp']

    # --- a total DSP budget, split top-down (core/dspbudget.py) ---------------------

    def setDspBudget(self, fraction: float | None = None, total: int | None = None, weight=None):
        '''As `StreamingNTTScheme.setDspBudget`: one budget over every multiplier of the core, split top-down
        (core/dspbudget.py): blocks {butterfly x B, output twist x ioLanes, twiddle generator x B/recGroup}
        share the total in proportion to their pure-DSP counts (largest remainder, identical instances
        identical), then each block's share goes to its multipliers' DSP nodes the same way; a node left
        with 0 is built on LUTs (Booth). 'rec': the generator count depends on the multiplier's latency
        (recGroup), so the split is redone until the count is stable.'''
        from ...core import dspbudget as DB
        self.clearDspBudget()
        ng = None
        for _ in range(4):
            blocks = []
            b = DB.blockOf('butterfly', self.butterflyUnit().inner(), self.B, weight)
            b.key = 'bu'
            blocks.append(b)
            if self.twistMultiplier is not None:
                b = DB.blockOf('output twist multiplier', self.twistMultiplier, self.io, weight)
                b.key = 'twist'
                blocks.append(b)
            if self.recGen():
                ng = self.B // self.recGroup()
                b = DB.blockOf('twiddle generator multiplier', self.genMultiplier, ng, weight)
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
            if ng is None or self.B // self.recGroup() == ng:
                break
        else:
            raise AssertionError(f'{self.name}: the generator count does not settle under the DSP budget')
        for b in blocks:
            DB.measure(b, {'twist': self.twistMultiplier, 'gen': self.genMultiplier}.get(b.key,
                                                                                     self.butterflyUnit().inner()))
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
        raise NotImplementedError(f'{self.name}: the iterative spec comes from IterativeNTT.getOperatorInterface')
