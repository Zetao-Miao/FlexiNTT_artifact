'''The fully pipelined (unrolled) NTT as its own NTT type: one whole n-point
transform per cycle, every point on its own lane, a modulus and a direction per
transform.

    UnrolledNTTScheme   the model (a `StreamingNTTScheme` with lanes = n)
    UnrolledNTT         the operator: RTL (core + wrapper + testbench)

Why it is a streaming NTT with P = n. The dataflow scheme already has every
piece a fully pipelined NTT needs: log2(n) stages of `ModularBU` butterflies over
any reduction and multiplier backend, the DSP budget, the LUT timing model, and
the per-frame tag machinery of the k=1 work (`moduli=[...]`: a modulus index
MIDX and a direction DIR per frame, carried in frame-boundary registers, every
consumer reading its constants from its own modulus-table copy). At P = n a
frame is one cycle: no lane exchanges, no frame counter, every stage pairs two
lanes by wiring, and a twiddle slot sees one exponent per direction, so its
table is addressed by {MIDX, DIR} alone (M x dirs words). Nothing of the
dataflow's RTL changes unless this type asks for it (`roms['unrolled']` hooks:
table copies shared by up to `tableShare` butterflies, a modulus-table copy per
`modShare` butterflies, fan-out limits on the tag registers).

What this type adds:
  * natural-order ports (`inputOrder` / `outputOrder`: 'natural' or 'bitrev'):
    in a spatial design the bit reversal is wiring, so the wrapper does it;
  * `in_valid` -> `out_valid` and MIDX/DIR -> `midx_out`/`dir_out` aligned with
    the outputs (a composition needs the tag with the data);
  * `transformNatural`, a clocked twin (`reset` / `step`), `resources()` with the
    twiddle tables and tag registers priced, and `dspBlocks` / `applyDspPlan` so a
    composition (the four-step) can split one DSP budget over all its multipliers.

Fixed q (`q=`) stays the constant-multiplier design: with one direction every
twiddle is a design-time constant. (`FullyPipelinedNTT` in ntt/pipelined, the original
fixed-q unrolled NTT with its own generator, is unchanged.)
'''
from __future__ import annotations

from ...core.IntType import IntType
from ...core.utils import bitReverse
from .StreamingNTTScheme import StreamingNTTScheme
from .StreamingNTT import StreamingNTT


class UnrolledNTTScheme(StreamingNTTScheme):
    '''n points per cycle, one transform per cycle (see the module notes).

    Arguments as `StreamingNTTScheme` (without `lanes`), plus
      inputOrder / outputOrder  'natural' (port i is x[i] / X[i]) or 'bitrev' (port i is x[brv(i)]);
      tableShare   butterflies per twiddle-table copy (fan-out; 1 = a table per butterfly);
      modShare     butterflies per modulus-table copy within a stage (None: one per stage);
      tagFanout    max_fanout on the per-frame tag registers.
    Twiddle sources: 'rom' (default: per class a ROM of every {modulus, direction}; fixed q: a
    table only where the two directions differ), 'ram' (one run-time q per job, loaded), 'stream'
    (per-frame moduli: one input per class). 'otf' / 'rec' need frame-cycle bits and are refused.'''

    def __init__(self, name: str, n: int, q: int = 0, family=None, moduli=None, butterflyType: str = 'CT',
                 negacyclic=False, direction: str = 'forward', inverseScale: str = 'output',
                 butterfly: dict | None = None, twiddleSource: str | None = None,
                 targetFmaxMhz: float | None = None, primitiveRoot: int | None = None,
                 inputRegister: bool = False, inputOrder: str = 'natural', outputOrder: str = 'natural',
                 tableShare: int = 4, modShare: int | None = 16, tagFanout: int = 16,
                 twistSource: str = 'tab', roots=None, twiddles=None, unified: bool = False,
                 romStyle: str = 'auto', frameDir: bool | None = None, portAlign: str = 'data',
                 loadableModuli: bool = False, loadByDirection: bool = False):
        # portAlign (twiddleSource='port'): 'data' (every port word arrives with its transform; the core delays it
        # to its stage), 'address' (the supplier delivers each port's word at its stage's own time, `portOffsets`:
        # it delays the table address instead of the word; the core has no twiddle delay lines)
        if portAlign not in ('data', 'address'):
            raise ValueError(f"{name}: portAlign 'data' or 'address'")
        if portAlign == 'address' and twiddleSource != 'port':
            raise ValueError(f"{name}: portAlign='address' is for twiddleSource='port'")
        self.portAlign = portAlign
        # frameDir (one q per job or a fixed q, direction 'both'): DIR travels with each transform in the tag
        # registers, so it may change on any transform (default on); the data then waits frameLead() cycles,
        # which also lets the quasi-static modulus ports change with the first transform of a job
        self._frameDir = (direction == 'both' and moduli is None) if frameDir is None else \
            bool(frameDir and direction == 'both' and moduli is None)
        # romStyle: how the RTL maps every twiddle table, written as rom_style on it and priced the same way
        # by resources(): 'distributed' (LUT ROM), 'block' (BRAM36), 'ultra' (URAM, priced 8 BRAM36 each) or
        # 'auto' (distributed up to ROM_LUT_DEPTH words, else block). Without it Vivado picked BRAM for some
        # identical small tables and not others (MS_N16_q60_P32: 76 BRAM36 of 58 x 60-bit tables).
        if romStyle not in ('auto', 'distributed', 'block', 'ultra'):
            raise ValueError(f"{name}: romStyle 'auto', 'distributed', 'block' or 'ultra'")
        self.romStyle = romStyle
        # unified=True: every multiplying butterfly is the unified CT/GS unit (UnifiedButterfly.py): the forward
        # runs CT (psi merged when negacyclic), the inverse GS (psi^-1 merged, x2^-1 per stage), on the same
        # stage wiring (GS reads lane l as memory index brv(l)), so no twist multiplier in either direction
        self._unified = bool(unified)
        self._curDir = None
        if self._unified:
            # one q per job (moduli=None, a run-time family): with the twiddles on ports (a multi-step NTT's
            # folded_gs form supplies both directions' twiddles from its own tables)
            if direction != 'both' or butterflyType != 'CT' or (moduli is None and twiddleSource != 'port'):
                raise ValueError(f"{name}: unified=True is for direction='both', CT, per-frame moduli "
                                 f"(moduli=[q] for one q), or one q per job with twiddleSource='port'")
            if moduli is None and not self._frameDir:
                raise ValueError(f"{name}: unified=True with one q per job carries DIR per transform (frameDir)")
            if inverseScale not in ('stage', 'none'):
                raise ValueError(f"{name}: unified=True scales the inverse per stage ('stage') or not ('none')")
            if (butterfly or {}).get('multiplierKind') == 'shoup':
                raise NotImplementedError(f'{name}: unified=True takes a reduction multiplier, not Shoup')
        # externally given butterfly twiddles (a multi-step NTT's folded form, TP-NTT: a block runs stages of the
        # big NTT with the big NTT's twiddles): twiddles=f(q, d, s, k) -> w (plain, constant per modulus and
        # direction: a {MIDX, DIR} ROM per butterfly), or twiddleSource='port': every butterfly's twiddle is an
        # input on every cycle (tw_<s>_<k>, stored domain, in step with x_in; the model takes them per transform)
        if twiddles is not None and twiddleSource == 'port':
            raise ValueError(f"{name}: twiddles= (ROM of a given set) or twiddleSource='port' (inputs), not both")
        self._twFn = twiddles
        self._twPort = twiddleSource == 'port'
        self._ext = None
        self._portPerJob = False
        if self._twPort:
            if moduli is None and (family is None or not family.runtime):
                raise ValueError(f"{name}: twiddleSource='port' takes per-frame moduli (moduli=) or a run-time "
                                 f"family= (one q per job, modulus ports)")
            # per-frame moduli: the base's 'stream' supply. One q per job: built as 'ram' (the base allows
            # 'stream' only per frame), then switched to 'stream' below: no table, no load port
            self._portPerJob = moduli is None
            twiddleSource = 'stream' if moduli is not None else 'ram'
        # negacyclic: False, True (both directions), 'forward' (forward negacyclic, inverse cyclic) or
        # 'inverse' (forward cyclic, inverse negacyclic): a multi-pass NTT twists only at its ends
        if negacyclic is True:
            nwc = {'fwd', 'inv'}
        elif not negacyclic:
            nwc = set()
        elif negacyclic in ('forward', 'inverse'):
            nwc = {'fwd'} if negacyclic == 'forward' else {'inv'}
        else:
            raise ValueError(f"{name}: negacyclic is False, True, 'forward' or 'inverse'")
        if inverseScale not in ('output', 'stage', 'none'):
            raise ValueError(f"{name}: inverseScale 'output', 'stage' or 'none'")
        self._nwc = nwc
        # roots: {q: r} or a callable r(q, order): a primitive rootOrder()-th root per modulus (psi when any
        # direction is negacyclic, w = psi^2; else w). None: roots.fixedRoot (as the dataflow; primitiveRoot= at a
        # fixed q). Every table and constant of a modulus is a power of its r.
        self._roots = roots
        # the base refuses the per-stage halver with a negacyclic CT inverse (its output twist was n^-1 psi^-k);
        # here the twist then carries psi^-k alone: build with 'output' and switch after
        stage = inverseScale == 'stage'
        if twiddleSource in ('otf', 'rec'):
            raise ValueError(f"{name}: at one transform per cycle a twiddle never changes within a frame: "
                             f"'otf' / 'rec' have nothing to generate; use 'rom'")
        if twistSource != 'tab':
            raise ValueError(f"{name}: the output twist at one frame per cycle is a {'{'}MIDX, DIR{'}'} table "
                             f"per lane ('tab')")
        for o in (inputOrder, outputOrder):
            if o not in ('natural', 'bitrev'):
                raise ValueError(f"{name}: orders are 'natural' or 'bitrev'")
        if moduli is not None and twiddleSource is None:
            twiddleSource = 'rom'
        if stage and direction == 'forward':
            raise ValueError(f"{name}: inverseScale='stage' needs an inverse")
        self._stageReq = stage
        super().__init__(name, n, n, q=q, family=family, butterflyType=butterflyType, negacyclic=bool(nwc),
                         direction=direction, scaleInverse=direction != 'forward' and inverseScale != 'none',
                         butterfly=butterfly, twiddleSource=twiddleSource, targetFmaxMhz=targetFmaxMhz,
                         primitiveRoot=primitiveRoot, inputRegister=inputRegister,
                         inverseScale='output' if (stage and bool(nwc) and butterflyType == 'CT') else
                         ('output' if inverseScale == 'none' else inverseScale),
                         moduli=moduli, otfMinBits=0, twistSource='tab', loadableModuli=loadableModuli,
                         loadByDirection=loadByDirection)
        self.inverseScale = inverseScale
        self.stageHalve = 1 if stage else 0
        self.scaleInverse = direction != 'forward' and inverseScale != 'none'
        if self._portPerJob:
            self.twiddleSource = 'stream'
        self._qCache = {}
        self._slots()                           # the twist with the final scaling and negacyclic directions
        self.inputOrder, self.outputOrder = inputOrder, outputOrder
        self.tableShare = max(1, int(tableShare))
        self.modShare = int(modShare) if modShare else None
        self.tagFanout = int(tagFanout) if tagFanout else None

    # --- roots, negacyclic per direction, the twist ------------------------------------

    def negacyclicDirs(self) -> set:
        return set(self._nwc)

    def root(self, q: int) -> int:
        '''The primitive rootOrder()-th root every twiddle of modulus q is a power of (psi when a
        direction is negacyclic, else w).'''
        key = ('root', q)
        if key not in self._qCache:
            m = self.rootOrder()
            if self._roots is not None:
                r = self._roots(q, m) if callable(self._roots) else self._roots[q]
                r = int(r) % q
                if pow(r, m, q) != 1 or pow(r, m // 2, q) == 1:
                    raise ValueError(f'{self.name}: the root given for q={q} is not a primitive {m}-th root')
            elif self.primitiveRoot is not None and q == self.q:
                r = self.primitiveRoot % q
            else:
                from sage.all import GF
                from ..roots import fixedRoot
                r = int(fixedRoot(GF(q), m))
            self._qCache[key] = r
        return self._qCache[key]

    def _twistPsi(self) -> bool:
        '''Whether the twist carries powers of psi: CT's output twist on a negacyclic inverse, GS's
        input twist on a negacyclic forward.'''
        return ('inv' if self.butterflyType == 'CT' else 'fwd') in self._nwc

    def mergedTwist(self, d: str) -> bool:
        if getattr(self, '_unified', False):
            return d in self._nwc                 # CT forward merges psi, GS inverse psi^-1
        return d in self._nwc and ((self.butterflyType == 'CT') == (d == 'fwd'))

    def _exponent(self, d: str, s: int, mA: int) -> int:
        if not (getattr(self, '_unified', False) and d == 'inv'):
            return super()._exponent(d, s, mA)
        # GS on the CT wiring: lane l is memory index brv(l); hardware stage s pairs memory bit L-1-s
        m = bitReverse(mA, self.L)
        b = self.L - 1 - s
        stepExp = self.n >> (b + 1)
        j = m % (1 << b)
        return (2 * j + 1) * stepExp if self.mergedTwist(d) else j * stepExp

    def _bu(self, s: int, k: int, bound: IntType):
        if not getattr(self, '_unified', False) or self.slotConstant(s, k) is not None:
            return super()._bu(s, k, bound)
        from ..butterfly.UnifiedButterfly import UnifiedBU
        fam = dict(family=self.family) if self.runtime else dict(q=self.q)
        bu = UnifiedBU(name=f'{self.name}_s{s}_k{k}', butterflyType='CT', twiddleInput=True,
                       targetFmaxMhz=self.targetFmaxMhz, **fam, **self._buArgs())
        bu.aIn = bu.bIn = bound
        if self._dspPlan:
            bu.dspBudgets = self._dspPlan.get(('bu', self._buType(None, bound)))
        return bu

    def qPorts(self) -> tuple[str, ...]:
        return tuple(p for p in super().qPorts() if p != 'DIR')

    def frameDir(self) -> bool:
        return bool(getattr(self, '_frameDir', False))

    def frameLead(self, pipelineStages=1) -> int:
        if self.perFrame or not self.frameDir():
            return super().frameLead(pipelineStages)
        # the same rule as per-frame moduli: every tag read (table addresses 2 ahead, halvers) at offset >= 1,
        # and the modulus ports' two registers (port -> per-stage copy) settled before the first butterfly
        lo = min(o for _, o in self.modulusSites(pipelineStages, 0))
        return max(0, 1 - lo)

    def qPortValues(self, q: int) -> dict:
        v = super().qPortValues(q)
        if getattr(self, '_curDir', None) is not None:
            v['DIR'] = self._curDir
        return v

    def transform(self, frames, direction=None, q=None):
        if not getattr(self, '_unified', False) or isinstance(direction, (list, tuple)):
            return super().transform(frames, direction, q)
        d = direction or 'fwd'
        self._curDir = 1 if d == 'inv' else 0
        try:
            return super().transform(frames, direction, q)
        finally:
            self._curDir = None

    def order(self, d: str) -> int:
        if d in ('fwd', 'inv'):
            return 2 * self.n if self.mergedTwist(d) else self.n
        return 2 * self.n if self._twistPsi() else self.n

    def value(self, d: str, e: int, q: int) -> int:
        if d in ('fwd', 'inv') and e >= self._IDB:
            s, k = divmod(e - self._IDB, self.n)
            if self._twFn is not None:
                return int(self._twFn(q, d, s, k)) % q
            if self._ext is None:
                raise ValueError(f"{self.name}: twiddleSource='port': give the twiddles (transformPort)")
            return self._ext[(s, k)] % q
        return super().value(d, e, q)

    def slotConstant(self, s: int, k: int):
        if self.givenTwiddles():
            return None
        return super().slotConstant(s, k)

    def ownTwiddle(self, q: int, d: str, s: int, k: int) -> int:
        '''The twiddle butterfly (s, k) has in this n-point transform (plain): what a given set replaces.'''
        la = self.slots[s][k][0]
        p = self.stagePlan[s]
        mA = self._index(0, la, p['lane'], p['cyc'])
        return super().value(d, self._exponent(d, s, mA) % self.order(d), q)

    def slotPairs(self) -> list[list[tuple[int, int]]]:
        '''Per stage s, per butterfly k: the memory indices (mA, mB) it combines (CT: X = A + W B, Y = A - W B;
        mB = mA + 2^s; memory index m holds natural input `bitReverse(m)` at the input, natural output m at the
        output). The (s, k) of `twiddles=` and of the twiddle ports.'''
        out = []
        for s, stage in enumerate(self.slots):
            p = self.stagePlan[s]
            out.append([(self._index(0, la, p['lane'], p['cyc']), self._index(0, lb, p['lane'], p['cyc']))
                        for la, lb, _ in stage])
        return out

    def portSlots(self) -> list[tuple[int, int]]:
        '''twiddleSource='port': the (s, k) of each core twiddle input tw_s<c>, in port order.'''
        return [divmod(dict(key)[self.dirs[0]][0] - self._IDB, self.n) for key in self.streamClasses()]

    def portWord(self, w: int, q: int) -> int:
        '''The word to drive on a twiddle port for plain twiddle w of modulus q (the multiplier's domain).'''
        return self.stored(w % q, q)

    def transformPort(self, xs, tws, direction=None, q=None) -> list[list[int]]:
        '''twiddleSource='port': like transformNatural, with tws[f] = {(s, k): plain twiddle} per transform.'''
        T = len(xs)
        ds = list(direction) if isinstance(direction, (list, tuple)) else [direction] * T
        qs = list(q) if isinstance(q, (list, tuple)) else [q] * T
        out = []
        try:
            for x, tw, d, qq in zip(xs, tws, ds, qs):
                self._ext = tw
                out.append(self.transformNatural([x], d, qq)[0])
        finally:
            self._ext = None
        return out

    def base(self, d: str, q: int) -> int:
        key = ('base', d, q)
        if key not in self._qCache:
            r = self.root(q)
            nw = bool(self._nwc)
            psi = r if nw else None
            w = r * r % q if nw else r
            if d == 'fwd':
                b = psi if self.mergedTwist(d) else w
            elif d == 'inv':
                b = pow(psi, -1, q) if self.mergedTwist(d) else pow(w, -1, q)
            elif self.butterflyType == 'CT':
                b = pow(psi, -1, q) if self._twistPsi() else 1
            else:
                b = psi if self._twistPsi() else 1
            self._qCache[key] = b
        return self._qCache[key]

    def rootUsed(self, q: int, d: str) -> dict:
        '''{'w': the cyclic n-th root of direction d (inverse: w^-1), 'psi': the 2n-th root merged or
        twisted in that direction (or None)}.'''
        w = self.root(q) if not self._nwc else self.root(q) ** 2 % q
        psi = self.root(q) if d in self._nwc else None
        if d == 'inv':
            return {'w': pow(w, -1, q), 'psi': pow(psi, -1, q) if psi else None}
        return {'w': w, 'psi': psi}

    _IDB = 1 << 48                  # exponents from here on name a butterfly (given twiddles), not a power

    def givenTwiddles(self) -> bool:
        return getattr(self, '_twFn', None) is not None or getattr(self, '_twPort', False)

    def _slots(self) -> None:
        super()._slots()
        if not hasattr(self, '_nwc'):
            return
        if self.givenTwiddles():
            # every butterfly its own class: its 'exponent' is an id that value() resolves to the given twiddle
            for s, stage in enumerate(self.slots):
                for k, (la, lb, seqs) in enumerate(stage):
                    stage[k] = (la, lb, {d: [self._IDB + s * self.n + k] * self.F for d in self.dirs})
        if getattr(self, '_unified', False):
            need = False                          # both twists merged, n^-1 per stage (or none)
        elif self.twistSide == 'output':
            need = 'inv' in self.dirs and ((('inv' in self._nwc)) or (self.scaleInverse and not self.stageHalve))
        else:
            need = ('fwd' in self._nwc and 'fwd' in self.dirs) or ('inv' in self.dirs and self.scaleInverse
                                                                   and not self.stageHalve)
        self.twistSeqs = None
        if need:
            loc = self.outputLocation if self.twistSide == 'output' else self.inputLocation
            per = [[0] * self.F for _ in range(self.lanes)]
            for m in range(self.n):
                t, l = loc(m)
                per[l][t] = m % self.order('twist') if self._twistPsi() else 0
            self.twistSeqs = per

    def twistValue(self, d: str, e: int, q: int) -> int:
        ninv = pow(self.n, -1, q) if (self.scaleInverse and not self.stageHalve) else 1
        if self.twistSide == 'output':
            return ninv * self.value('twist', e, q) % q if d == 'inv' else 1
        if d == 'fwd':
            return self.value('twist', e, q)
        return ninv

    # --- orders --------------------------------------------------------------------

    def _memToNatIn(self, m: int) -> int:
        '''The natural input index held by memory index m (CT: bit-reversed in; GS: natural in).'''
        return bitReverse(m, self.L) if self.butterflyType == 'CT' else m

    def _memToNatOut(self, m: int) -> int:
        return m if self.butterflyType == 'CT' else bitReverse(m, self.L)

    def _port(self, natural: int, order: str) -> int:
        return natural if order == 'natural' else bitReverse(natural, self.L)

    def inputWiring(self) -> list[int]:
        '''Per core lane l: the wrapper port x_in_<p> that drives it.'''
        out = [None] * self.n
        for m in range(self.n):
            _, l = self.inputLocation(m)
            out[l] = self._port(self._memToNatIn(m), self.inputOrder)
        return out

    def outputWiring(self) -> list[int]:
        '''Per wrapper port y_out_<p>: the core lane that drives it.'''
        out = [None] * self.n
        for m in range(self.n):
            _, l = self.outputLocation(m)
            out[self._port(self._memToNatOut(m), self.outputOrder)] = l
        return out

    def transformNatural(self, xs: list[list[int]], direction=None, q=None) -> list[list[int]]:
        '''xs: transforms in port order (`inputOrder`); direction / q: one, or one per transform.
        Returns the outputs in port order (`outputOrder`), bit-exact as the RTL computes them.'''
        n = self.n
        mem = []
        for x in xs:
            if len(x) != n:
                raise ValueError(f'{self.name}: a transform has {n} points')
            mem.append([x[self._port(self._memToNatIn(m), self.inputOrder)] for m in range(n)])
        ys = self.transform(mem, direction, q)
        out = []
        for y in ys:
            o = [0] * n
            for m in range(n):
                o[self._port(self._memToNatOut(m), self.outputOrder)] = y[m]
            out.append(o)
        return out

    # --- the clock: a pure pipeline (no state across transforms but the registers) ---

    def reset(self) -> None:
        self._pipe = [None] * self.latency()

    def step(self, x=None, direction=None, q=None, valid: bool = True):
        '''One clock edge: transform x (port order) enters this cycle; returns what leaves on
        this cycle's outputs: None while filling or for an invalid slot, else (y, direction, q).
        Interval 1: a new transform every cycle, any modulus and direction.'''
        if not hasattr(self, '_pipe'):
            self.reset()
        item = None
        if valid and x is not None:
            d = direction or ('inv' if self.direction == 'inverse' else 'fwd')
            item = (self.transformNatural([x], d, q)[0], d, q)
        if not self._pipe:                       # a combinational design (latency 0)
            return item
        out = self._pipe.pop(0)
        self._pipe.append(item)
        return out

    def interval(self) -> int:
        return 1

    # --- cost -----------------------------------------------------------------------

    def tableInstances(self) -> list[dict]:
        '''Every twiddle-table copy the RTL builds: {stage, key, users, depth, cols}.'''
        self.slotClasses()               # sets classOf
        if self.twiddleSource == 'stream':
            return []
        W = max(1, (self.qMax() - 1).bit_length())
        M = len(self.moduli) if self.perFrame else 1
        out = []
        for s in range(self.L):
            users: dict = {}
            for k in range(len(self.slots[s])):
                if (s, k) in self.classOf:
                    users.setdefault(self.classOf[(s, k)], []).append(k)
            for key, ks in users.items():
                depth = (1 << len(self.significantBits(key))) * len(self.dirs) * M
                cols = [W] + ([self._wpBits()] if self.shoup() else [])
                G = self.tableShare
                for g in range(0, len(ks), G):
                    out.append({'stage': s, 'key': key, 'users': len(ks[g:g + G]), 'depth': depth, 'cols': cols})
        return out

    def _wpBits(self) -> int:
        bu = next(b for st in self.butterflies for b in st if 'WP' in b.portNames())
        return bu.defaultPortBound('WP').bitWidth

    @staticmethod
    def romLuts(depth: int, width: int) -> int:
        '''A distributed ROM: one LUT6 per output bit per 64 words (MUXF7/F8 free up to 256).'''
        return -(-depth // 64) * width

    #: 'auto': tables up to this depth are LUT ROMs (at 256 words 4 LUT6 per bit), deeper ones block RAM
    ROM_LUT_DEPTH = 256
    #: BRAM36 aspect ratios (depth, width) and URAM288's
    BRAM36_SHAPES = ((32768, 1), (16384, 2), (8192, 4), (4096, 9), (2048, 18), (1024, 36), (512, 72))
    URAM_SHAPE = (4096, 72)

    def tableStyle(self, depth: int) -> str:
        if self.romStyle != 'auto':
            return self.romStyle
        return 'distributed' if depth <= self.ROM_LUT_DEPTH else 'block'

    @classmethod
    def bramTiles(cls, depth: int, width: int) -> int:
        return min(-(-depth // d) * -(-width // w) for d, w in cls.BRAM36_SHAPES)

    @classmethod
    def uramTiles(cls, depth: int, width: int) -> int:
        d, w = cls.URAM_SHAPE
        return -(-depth // d) * -(-width // w)

    def _memCost(self, depth: int, width: int, style: str) -> dict:
        if style == 'distributed':
            return {'lut': self.romLuts(depth, width), 'bram36': 0, 'uram': 0}
        if style == 'ultra':
            return {'lut': 0, 'bram36': 0, 'uram': self.uramTiles(depth, width)}
        return {'lut': 0, 'bram36': self.bramTiles(depth, width), 'uram': 0}

    def delayLines(self, pipelineStages: int = 1) -> list[tuple[int, int, int]]:
        '''(count, cycles, width) of the core's long delay lines: the input lead (one per lane) and, with
        twiddle ports, each class's chain to its stage (`rtl_gen.ntt._emit_delay_module`: a RAM circular
        buffer of D-1 words from 64 cycles up, registers / SRLs below).'''
        out = []
        lead = self.leadIn(pipelineStages) + self.frameLead(pipelineStages)
        if lead:
            out.append((self.lanes, lead, self.inputBound.bitWidth))
        if self.twiddleSource == 'stream' and self.portAlign != 'address':
            bu, _ = self._offsets(pipelineStages)
            W = max(1, (self.qMax() - 1).bit_length())
            have = {}
            for (s, k), key in sorted(self.classOf.items()):
                need = bu[s] + lead
                h = have.get(key, 0)
                if need > h:
                    out.append((1, need - h, W))
                    have[key] = need
        return out

    def resources(self, pipelineStages: int = 1) -> dict:
        '''{'lut', 'dsp', 'bram36', 'ff_tables'}: the butterflies, halvers, output twist and the
        modulus tables (`areaCost`), plus the twiddle-table copies (distributed ROMs, registered
        address and data), the output-twist tables and the tag registers. FFs of the datapaths
        are not modelled here.'''
        lut, dsp = self.areaCost()
        tl = tf = bram = uram = 0
        mems = [(t['depth'], t['cols']) for t in self.tableInstances()]
        if self.twistMultiplier is not None:
            W = max(1, (self.qMax() - 1).bit_length())
            depth = len(self.dirs) * (len(self.moduli) if self.perFrame else 1)
            mems += [(depth, [W])] * self.lanes
        for depth, cols in mems:
            st = self.tableStyle(depth)
            for w in cols:
                c = self._memCost(depth, w, st)
                tl += c['lut']
                bram += c['bram36']
                uram += c['uram']
                tf += w
            tf += max(1, (depth - 1).bit_length())
        for cnt, cyc, w in self.delayLines(pipelineStages):
            if cyc >= 64:                    # RAM circular buffer of cyc - 1 words (ram_style block)
                bram += cnt * self.bramTiles(cyc - 1, w)
            else:                            # SRLs: one LUT per bit per 32 cycles (the lead is in areaCost)
                pass
        if self.perFrame and self.modShare:
            # extra modulus-table copies: one per modShare butterflies instead of one per stage
            w = sum(max(v).bit_length() for v in self.modulusTable().values())
            extra = sum(max(0, -(-len(st) // self.modShare) - 1) for st in self.slots)
            lut += extra * -(-len(self.moduli) // 64) * w
        return {'lut': lut + tl, 'dsp': dsp, 'bram36': bram, 'uram': uram, 'bram36_equiv': bram + 8 * uram,
                'lut_tables': tl, 'ff_tables': tf}

    def twiddleWordsStored(self) -> int:
        '''Words in all twiddle-table copies (what the ROMs hold, copies counted).'''
        return sum(t['depth'] * len(t['cols']) for t in self.tableInstances())

    # --- one DSP budget over a composition --------------------------------------------

    def dspBlocks(self, count: int = 1, weight=None, prefix: str | None = None) -> list:
        '''The budget blocks of this NTT ({butterfly type x count, output twist x n}), each with
        `.key`, counts multiplied by `count` (identical instances of this NTT). Put them under one
        root with the rest of a design, split (`dspbudget.splitTypes` / `splitLeaves`), then
        `applyDspPlan({b.key: dspbudget.budgetsOf(b)})`.'''
        from ...core import dspbudget as DB
        self.clearDspBudget()
        pre = prefix or self.name
        types: dict = {}
        for s, stage in enumerate(self.butterflies):
            for k, bu in enumerate(stage):
                types.setdefault(self._buType(self.slotConstant(s, k), bu.aIn), []).append(bu)
        blocks = []
        for i, (key, bus) in enumerate(types.items()):
            what = 'twiddle input' if key[0] is None else f'constant {key[0]}'
            b = DB.blockOf(f'{pre} butterfly type {i} ({what})', bus[0].inner(), len(bus) * count, weight)
            b.key = ('bu', key)
            b.owner = self
            blocks.append(b)
        if self.twistMultiplier is not None:
            b = DB.blockOf(f'{pre} {self.twistSide} twist multiplier', self.twistMultiplier, self.lanes * count, weight)
            b.key = 'twist'
            b.owner = self
            blocks.append(b)
        return blocks

    def applyDspPlan(self, plan: dict) -> None:
        '''Build every multiplier with the budgets of `plan` ({block key: {node: budget}}).'''
        self._dspPlan = dict(plan)
        self._clearGenerators()
        self.propagateBound()


class UnrolledNTT(StreamingNTT):
    '''The operator: `emitRtl` writes the core (`<top>_core`, the streaming generator at P = n with
    the unrolled hooks) and the wrapper `<top>` with natural-order ports, valid and tag outputs,
    and with test data a testbench that drives a new transform every cycle (MIDX and DIR changing
    every cycle, invalid cycles in between) and checks every output on its exact cycle.'''

    def latency(self, pipelineStages: int = 1) -> int:
        return self.scheme.latency(pipelineStages)

    def resources(self, pipelineStages: int = 1) -> dict:
        return self.scheme.resources(pipelineStages)

    def getOperatorInterface(self, name: str, pipelineStages: int = 1, subRoot=None):
        spec = super().getOperatorInterface(name, pipelineStages, subRoot)
        sch = self.scheme
        spec.roms['unrolled'] = {'tableShare': sch.tableShare, 'modShare': sch.modShare, 'tagFanout': sch.tagFanout,
                                 'frameDir': sch.frameDir(), 'lead': sch.frameLead(pipelineStages) if sch.frameDir() else 0}
        for t in spec.roms['tables']:            # the mapping resources() priced, written on every table
            t['romStyle'] = sch.tableStyle(t['depth'])
        if sch.portAlign == 'address':           # every port word arrives at its stage's buOff: no delay in the core
            spec.roms['stream']['aligned'] = True
        return spec

    def _jobSchedule(self, cyc: list, spec, rng) -> list:
        '''One run-time q per job ('ram' tables or twiddle ports): split the cycles into jobs at every change of
        q (and, without frameDir, of DIR: then quasi-static too). Before each job the pipeline drains (latency + 2
        idle cycles, the old q and DIR held), the tables are reloaded ('ram': tw_rst, then one word per tw_wen,
        `loadImage(q)`), and the new q is driven on the modulus ports from the job's first valid cycle on (the
        worst case: q changes with the data). Without frameDir the new DIR is set 4 cycles ahead of the job (it
        is read up to 3 cycles ahead of the data) and held on every cycle of the job, idle ones included.
        Idle cycles carry random data, random twiddle words and (with frameDir) a random DIR.'''
        sch = self.scheme
        LAT = spec.latency
        loadW = spec.roms['loadWords']
        fd = sch.frameDir()
        out, cur, curD = [], None, None

        def idle(q, d=None, ld=(0, 0, 0)):
            return {'v': 0, 'x': [rng.randrange(1 << sch.inputBound.bitWidth) for _ in range(sch.n)], 'y': None,
                    'd': rng.choice(sch.dirs) if (fd or d is None) else d, 'q': q,
                    'tw': [rng.randrange(q) for _ in sch.portSlots()] if sch._twPort else None,
                    'qv': sch.qPortValues(q), 'ld': ld}

        def fix(h, q, d):
            h = dict(h, q=q, qv=sch.qPortValues(q), ld=(0, 0, 0))
            if not h['v'] and not fd:
                h['d'] = d
            if not h['v'] and sch._twPort and h.get('tw') is None:
                h['tw'] = [rng.randrange(q) for _ in sch.portSlots()]
            return h
        pending = []
        for c in cyc:
            pending.append(c)
            if not c['v']:
                continue
            q, d = c['q'], c['d']
            if q != cur or (not fd and d != curD):
                held = pending[:-1]
                pending = [c]
                oq = cur if cur is not None else q
                od = curD if curD is not None else d
                out += [fix(h, oq, od) for h in held]
                if cur is not None:
                    out += [idle(oq, od) for _ in range(LAT + 2)]
                if loadW and q != cur:
                    out.append(idle(oq, d, (1, 0, 0)))
                    out += [idle(oq, d, (0, 1, w)) for w in self.loadImage(q)]
                out += [idle(oq, d) for _ in range(2 if fd else 4)]
                cur, curD = q, d
            out += [fix(h, cur, curD) for h in pending]
            pending = []
        out += [fix(h, cur, curD) for h in pending]
        return out

    def emitRtl(self, topName: str, run_dir, xs=None, dirs=None, qs=None, valid=None,
                pipelineStages: int = 1, seed: int = 1, tws=None) -> dict:
        '''RTL into `run_dir`. With `xs` (transforms in port order; one per valid cycle) a testbench:
        `dirs` / `qs` one per transform (default forward / the reference modulus), `valid` a 0/1
        list per cycle (default all 1; its ones must number len(xs)); invalid cycles get random
        data, a random MIDX and DIR, which must not disturb anything.'''
        import os as _os
        import random as _r
        from pathlib import Path as _Path
        sch = self.scheme
        run_dir = _Path(run_dir).resolve()
        run_dir.mkdir(parents=True, exist_ok=True)
        core = f'{topName}_core'
        spec = self.getOperatorInterface(core, pipelineStages, subRoot=run_dir / '_sub')
        tb = None
        if xs is not None:
            T = len(xs)
            d0 = 'inv' if sch.direction == 'inverse' else 'fwd'
            dirs = list(dirs) if isinstance(dirs, (list, tuple)) else [dirs or d0] * T
            qs = list(qs) if isinstance(qs, (list, tuple)) else [qs or sch.refQ()] * T
            if sch.portAlign == 'address':
                raise ValueError(f"{topName}: portAlign='address' has no standalone testbench (the supplier, e.g. "
                                 f"the multi-step top, times the ports)")
            if sch._twPort:
                if tws is None:
                    raise ValueError(f"{topName}: twiddleSource='port' needs tws= (one dict per transform)")
                ys = sch.transformPort(xs, tws, dirs, qs)
                slots = sch.portSlots()
            else:
                ys = sch.transformNatural(xs, dirs, qs)
            if not sch.perFrame and not sch.frameDir() and not sch.runtime:
                # (one q per job: the testbench's job schedule drains and sets DIR ahead on every DIR change)
                if len(set(dirs)) > 1:
                    raise ValueError(f'{topName}: built with frameDir=False: DIR is per job (quasi-static)')
            valid = list(valid) if valid is not None else [1] * T
            if sum(valid) != T:
                raise ValueError(f'{topName}: {sum(valid)} valid cycles for {T} transforms')
            rng = _r.Random(seed)
            cyc, it = [], 0
            for v in valid:
                if v:
                    cyc.append({'v': 1, 'x': xs[it], 'y': ys[it], 'd': dirs[it], 'q': qs[it],
                                'tw': [sch.portWord(tws[it][sk], qs[it]) for sk in slots] if sch._twPort else None})
                    it += 1
                else:
                    qq = rng.choice(sch.moduli) if sch.perFrame else qs[0]
                    cyc.append({'v': 0, 'x': [rng.randrange(1 << sch.inputBound.bitWidth) for _ in range(sch.n)],
                                'y': None, 'd': rng.choice(sch.dirs) if sch.perFrame else dirs[0], 'q': qq,
                                'tw': [rng.randrange(qq) for _ in sch.portSlots()] if sch._twPort else None})
            if sch.runtime and not sch.perFrame:
                cyc = self._jobSchedule(cyc, spec, rng)
            tb = {'cycles': cyc}
        from rtl_gen.ntt import StreamNTT_RTL_gen
        from rtl_gen.unrolled_ntt import UnrolledNTT_wrapper_gen
        saved = _os.getcwd()
        _os.chdir(str(run_dir))
        try:
            meta = StreamNTT_RTL_gen(spec)
            wrap = {'top': topName, 'core': core, 'n': sch.n, 'inWidth': spec.inWidth, 'outWidth': spec.outWidth,
                    'latency': spec.latency, 'inWiring': sch.inputWiring(), 'outWiring': sch.outputWiring(),
                    'midxBits': sch.modulusIndexBits() if sch.perFrame else 0,
                    'moduli': list(sch.moduli) if sch.perFrame else None,
                    'dirPort': spec.dirPort, 'dirs': sch.dirs,
                    'inputOrder': sch.inputOrder, 'outputOrder': sch.outputOrder,
                    'twPorts': sch.portSlots() if sch._twPort else None, 'frameDir': sch.frameDir()}
            meta = UnrolledNTT_wrapper_gen(wrap, meta, tb)
        finally:
            _os.chdir(saved)
        meta['model'] = sch.resources(pipelineStages)
        return meta
