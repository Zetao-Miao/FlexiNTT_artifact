'''Port options of the hybrid NTT (methods of `HybridNTTScheme`, installed by `install`): the model and the
cycle twin of the wrapper `rtl_gen.hybrid_ports` writes around the core.

  outReady=True            an `out_ready` input: the output beats wait in a buffer of `outDepth` polynomials
  outputOrder='natural'    the ports give coefficient c x ioLanes + l in beat c, lane l (the core gives
                           rotr(c W + l, U, log2 n)); the reorder is done in the output buffer
  twiddleBuffer='record'   (with loadable=True) the modulus of every polynomial comes on a valid/ready stream
                           (tw_valid, tw_ready, tw_data): one record per polynomial, loaded into a table set
                           no polynomial in flight reads; the wrapper drives MIDX

The wrapper (module <top>; the core is <top>_k):

  input adapter (ioLanes != W) -> admission gate -> core -> output buffer (W RAMs of outDepth x T beats)
     -> reader (RAM read, read rotator, serialise / collect) -> landing FIFO (LUT RAM) -> out_valid / out_ready

No clock enable anywhere: the core is never stalled. Every handshake output comes from registers through at
most one LUT (in_ready = !full | (core ready & gate); out_valid is a register; out_ready feeds the read pointer,
three small counters and one flag).

Admission (the credit rule). `cr` counts the polynomials admitted (first beat taken by the core) and not yet
released (last buffer beat issued by the reader, seen one cycle later). The first beat of a polynomial passes
the gate only while cr < outDepth.

  No overflow, for every in_valid and out_ready pattern. Let a = polynomials admitted, f = polynomials
  released; the release is counted late only, so a - f <= cr <= outDepth at all times. The core emits every
  polynomial once, in admission order, T consecutive beats each, and nothing stalls it. Polynomial number i is
  written to buffer slot i mod outDepth and read from the same slot. The polynomials with unread beats have
  numbers in [f, a), at most outDepth consecutive numbers, hence distinct slots: a write never lands on a slot
  with unread beats. A released slot is next written by a polynomial admitted after the release: its first
  output beat comes more than T + the core's output offset cycles later, the released read needs ramLatency + 1.
  The landing FIFO holds at most `resv` beats (reserved at the read issue, returned at the pop) and a read is
  issued only while resv + its beats <= the FIFO depth.
  No deadlock: with cr = outDepth every admitted polynomial still leaves the core and is read as soon as
  out_ready allows; then cr falls.

Any outDepth >= 1 is safe; a smaller one is slower. The default is the most polynomials the twin sees admitted
and not released with always-valid input and always-ready output, plus one. With out_ready always high the
period is the period without the option (gate H1 checks it, the testbench checks every beat's cycle).

Natural order. Core beat c lane (h, j) (lane = h 2^U + j) is coefficient k = j n/2^U + c g + h, that is
natural beat A = {j, c >> U} lane (i, h) with i = c mod 2^U (natural lane = i g + h). The buffer keeps natural
beat A lane (i, h) in bank (h, (i + j) mod 2^U) at address A: one core beat writes 2^U g different banks (a
rotation by c mod 2^U in front of the RAMs, each bank with its own address), one natural beat reads them (a
rotation by the top U bits of A behind the RAMs). A polynomial is read once it is complete.

Record stream (twiddleBuffer='record'). The core is the loadable one; moduli= names its table sets (at least
S + 1). A record is one header entry (bit 0 = keep: the polynomial uses the set of the one before, no data
follows; ignored on the first record) and then one entry per table word of that modulus: every load region's
chunk in the load map's order (the tables of both directions, then the modulus constants); `twiddleLanes`
entries per beat (the RTL is built for 1). The loader writes the record into the next set (round robin) once
no polynomial in flight uses it (a use counter per set: +1 at admission, -1 at the polynomial's last core
output beat), and the polynomial is admitted `LDL` cycles after its last entry. DIR stays a port.
'''
from __future__ import annotations

import random

LDL = 4            # cycles between the last record entry and rec_ok (loader 2 registers, core 1, the write)
ST_HDR, ST_WAITF, ST_DATA, ST_SETTLE, ST_OK = range(5)


def _pow2ceil(x: int) -> int:
    return 1 << max(0, (x - 1).bit_length())


class _CoreTwin:
    '''`HybridNTTScheme.simulateJob` as a stepper (the same statements, one cycle per call).'''

    def __init__(self, sch, polys: int, pipelineStages=1):
        self.T, self.R, self.S = sch.T, sch.R, sch.S
        self.Dl = sch.slotLength(sch.S, pipelineStages)
        self.OO = sch.outOffset(pipelineStages)
        self.off = sch.roundOffsets()
        self.ID = sch.inDepth()
        self.polys = polys
        self.acc, self.count = [], 0
        self.running, self.k, self.cc, self.x_, self.kd = False, 0, 0, 0, 0
        self.active = [None] * self.S
        self.nextPoly = 0
        self.issue = [[None] * self.R for _ in range(polys)]
        self.out = [[None] * self.T for _ in range(polys)]
        self.ctx, self.slotk = [None] * polys, [None] * polys
        self.pendingDec = 0
        self.outAt = {}
        self.FRd = sch.fanShift(pipelineStages)
        self.freed = []

    def ready(self, c: int) -> bool:
        '''First call of a cycle: the count register, in_ready.'''
        self.count += self.pendingDec
        self.pendingDec = 0
        if self.FRd:
            self.freed = [x for x in self.freed if x >= c - self.FRd]
            return self.count + sum(1 for x in self.freed if x < c) < self.ID
        return self.count < self.ID

    def step(self, c: int, accept: bool) -> None:
        T, R, S = self.T, self.R, self.S
        count = self.count
        if not self.running and count >= T:
            self.running, self.k, self.cc, self.x_, self.kd = True, 0, 0, 0, 0
        r_ = (self.kd + self.off[self.x_]) % R
        if self.running and self.cc == 0:
            if r_ == 0:
                if count >= T and self.nextPoly < self.polys:
                    self.active[self.x_] = self.nextPoly
                    self.ctx[self.nextPoly], self.slotk[self.nextPoly] = self.x_, self.k
                    self.nextPoly += 1
                else:
                    self.active[self.x_] = None
                if all(a is None for a in self.active):
                    self.running = False
        if self.running:
            p = self.active[self.x_]
            if p is not None and self.cc < T:
                if self.cc == 0:
                    self.issue[p][r_] = c
                if r_ == R - 1:
                    self.out[p][self.cc] = c + self.OO
                    self.outAt[c + self.OO] = (p, self.cc)
                if r_ == 0:
                    self.pendingDec -= 1
                    if self.FRd:
                        self.freed.append(c)
            self.cc += 1
            if self.cc == self.Dl:
                self.cc = 0
                self.k += 1
                self.x_ += 1
                if self.x_ == S:
                    self.x_ = 0
                    self.kd += 1
        if accept:
            self.acc.append(c)
            self.pendingDec += 1

    def job(self) -> dict:
        return {'accept': self.acc, 'issue': self.issue, 'out': self.out, 'ctx': self.ctx, 'slotk': self.slotk,
                'slot': self.Dl}


def _initPorts(self, outReady, outDepth, outputOrder, twiddleBuffer, twiddleLanes) -> None:
    name = self.name
    self.outReady = bool(outReady)
    if outputOrder not in ('core', 'natural'):
        raise ValueError(f"{name}: outputOrder 'core' or 'natural'")
    self.outputOrder = outputOrder
    if twiddleBuffer not in (None, 'record'):
        raise ValueError(f"{name}: twiddleBuffer None or 'record'")
    self.twiddleBuffer = twiddleBuffer
    if outDepth is not None and (not isinstance(outDepth, int) or outDepth < 1):
        raise ValueError(f'{name}: outDepth (polynomials the output buffer holds) must be >= 1')
    self._outDepthReq = outDepth
    if twiddleLanes < 1 or twiddleLanes != 1 << (twiddleLanes.bit_length() - 1):
        raise ValueError(f'{name}: twiddleLanes must be a power of two')
    self.twiddleLanes = twiddleLanes
    if twiddleBuffer == 'record':
        if not self.loadable:
            raise ValueError(f"{name}: twiddleBuffer='record' needs loadable=True (moduli= names the table sets)")
        if self.twiddleSource == 'stream':
            raise ValueError(f"{name}: twiddleBuffer='record' loads the tables inside the core; twiddleSource "
                             f"'stream' keeps them outside")
    elif twiddleLanes != 1:
        raise ValueError(f"{name}: twiddleLanes is for twiddleBuffer='record'")
    if outDepth is not None and not (self.outReady or outputOrder == 'natural' or
                                     (twiddleBuffer == 'record' and self.io != self.W)):
        raise ValueError(f'{name}: outDepth is for a design with the output buffer (outReady, natural order, or '
                         f'a record stream with ioLanes)')
    self._portsCache = {}


def portsOn(self) -> bool:
    return bool(self.outReady or self.outputOrder == 'natural' or self.twiddleBuffer == 'record')


def portsDirect(self) -> bool:
    '''The record stream alone at the core's width: no output buffer, the core's output is the port.'''
    return not self.outReady and self.outputOrder != 'natural' and self.io == self.W


def _checkPorts(self) -> None:
    '''After the slots are known (propagateBound).'''
    if self.twiddleBuffer == 'record' and len(self.moduliList()) < self.S + 1:
        raise ValueError(f'{self.name}: the record stream needs at least S + 1 = {self.S + 1} table sets '
                         f'(moduli= names {len(self.moduliList())})')
    self._portsCache = {}


def portsGeometry(self, pipelineStages=1) -> dict:
    '''rho (port beats per core beat, or core beats per port beat), the read pipeline, the landing FIFO.'''
    W, io = self.W, self.io
    natural = self.outputOrder == 'natural'
    RT = self.rotLatency() if natural else 0
    PP = 2 + self.RL + RT                       # read issue -> the cycle the landing FIFO's write enable is up
    narrow, wide = io < W, io > W
    rho = W // io if narrow else io // W
    K = max(4, _pow2ceil(PP + 2 + (2 * rho if narrow else 0)))
    return {'rho': rho, 'narrow': narrow, 'wide': wide, 'RT': RT, 'PP': PP, 'K': K, 'natural': natural}


def outDepth(self, pipelineStages=1) -> int:
    '''Polynomials the output buffer holds: the argument, or the most the twin sees admitted and not released
    (always-valid input, always-ready output, no credit limit) plus one.'''
    if self._outDepthReq is not None:
        return self._outDepthReq
    key = ('dp', pipelineStages, self.S, self.slotLength(self.S, pipelineStages), self.inDepth(),
           self.outOffset(pipelineStages))
    if key not in self._portsCache:
        P = 4 * self.S + 6
        j = self.simulatePortsJob(P, keep=[True] * P, pipelineStages=pipelineStages, unlimited=True)
        self._portsCache[key] = j['peakCredits'] + 1
    return self._portsCache[key]


def recordRegions(self, pipelineStages=1) -> list[tuple[str, int]]:
    '''The entries of one modulus in a record, per kind: (what, entries), from the tables the generator writes
    (the generator checks the sum against its load map).'''
    M = len(self.moduliList())
    out = []
    for ti, t in enumerate(self.roundTables()[0]):
        src = self.tableSource(ti)
        if src == 'rec':
            base, upd = self.recTables(ti, pipelineStages)
            out += [(f'table {ti} (rec base)', len(base) // M), (f'table {ti} (rec update)', len(upd) // M)]
        elif src == 'otf':
            lo, hi = self.otfTables(ti)
            out += [(f'table {ti} (otf low)', len(lo) // M), (f'table {ti} (otf high)', len(hi) // M)]
        elif src == 'tree':
            out.append((f'table {ti} (tree constant)', len(self.treeTable(ti)) // M))
        else:
            out.append((f'table {ti} ({src})', len(self.roundTable(ti)) // M))
    if self.twistOn and self.twistSrc == 'rec':
        out.append(('twist rec base', sum(len(self.twistRecTables(l, pipelineStages)[0]) for l in range(self.W)) // M))
        out.append(('twist rec update', len(self.twistRecTables(0, pipelineStages)[1]) // M))
    elif self.twistOn:
        out.append(('twist table', self.W * len(self.twistTable(0, self.moduliList()[0]))))
    out.append(('modulus constants', self._recordConstants()))
    return out


def _recordConstants(self) -> int:
    '''Modulus constants of the core (one register file each): the q ports of the butterfly, the twist
    multiplier, the generator and the halver the core reads.'''
    q = self.moduliList()[0]
    nc = len(self.butterflyUnit().qPortValues(q))
    if self.twistMultiplier is not None:
        nc += len(self.twistMultiplier.qPortValues(q))
    if self.generator() is not None:
        nc += len(self.generator().qPortValues(q))
    return nc + (1 if self.stageHalve else 0)


def recordWords(self, pipelineStages=1) -> int:
    key = ('rw', pipelineStages, self.S, tuple(getattr(self, '_srcOf', ())), getattr(self, 'twistSrc', None))
    if key not in self._portsCache:
        self._portsCache[key] = sum(w for _, w in self.recordRegions(pipelineStages))
    return self._portsCache[key]


def recordBeats(self, pipelineStages=1, lanes: int | None = None) -> int:
    '''Stream beats of a record with data: the header and the entries, `lanes` per beat.'''
    lanes = lanes or self.twiddleLanes
    return 1 + -(-self.recordWords(pipelineStages) // lanes)


def simulatePortsJob(self, polys: int, valid=None, outReady=None, twValid=None, keep=None, pipelineStages=1,
                     depth: int | None = None, landing: int | None = None, unlimited: bool = False,
                     lanes: int | None = None, sets: int | None = None, maxCycles: int | None = None) -> dict:
    '''Cycle twin of the wrapper (rtl_gen.hybrid_ports) around the core's controller, register for register.
    valid(c), outReady(c), twValid(c): the patterns at the ports; keep[p]: polynomial p's record is a keep
    header. Returns 'accept' (port beats in), 'out' (per polynomial the cycle of each port beat taken),
    'latency', 'interval', 'jobCycles', 'core' (the core's job, for checkHazards), 'peakCredits', 'peakLanding',
    'peakUse', 'twAccept' (cycles of the record beats).'''
    always = lambda c: True                                                   # noqa: E731
    valid = valid or always
    outReady = (outReady or always) if self.outReady else always
    twValid = twValid or always
    geo = self.portsGeometry(pipelineStages)
    W, T, io, n = self.W, self.T, self.io, self.n
    NB = n // io
    total = polys * NB
    rho, narrow, wide, natural, PP, RT = (geo[k] for k in ('rho', 'narrow', 'wide', 'natural', 'PP', 'RT'))
    direct = self.portsDirect()
    DP = 1 << 30 if (unlimited or direct) else (depth or self.outDepth(pipelineStages))
    K = landing or geo['K']
    record = self.twiddleBuffer == 'record'
    NS = sets or len(self.moduliList())
    lanes = lanes or self.twiddleLanes
    dataBeats = -(-self.recordWords(pipelineStages) // lanes) if record else 0
    keep = list(keep) if keep is not None else [False] * polys
    core = _CoreTwin(self, polys, pipelineStages)
    maxCycles = maxCycles or (polys + 4) * (T + self.R * self.S * core.Dl + n // min(io, W) + dataBeats + 16) * 8 + 5000
    # registers
    full, cnt = False, 0                          # input adapter
    mid, bc, cr, cok, done_r = False, 0, 0, True, False
    wb, wpoly = 0, 0                              # the core's output beat counter
    ac, rb, rs, rmid, resv, ec, rc = 0, 0, 0, False, 0, 0, 0
    fc = 0
    incAt, pushAt = {}, {}
    st, cur, tgt, have, rok, sc, dcnt = ST_HDR, 0, 0, False, not record, 0, 0
    use = [0] * NS
    setOf = []                                    # per admitted polynomial its set
    recNo = 0                                     # records begun
    oacc, outs, twacc = [], [], []
    peakCr = peakFc = peakUse = 0
    nadm = 0
    c = 0
    while c < maxCycles:
        kr = core.ready(c)
        gate = mid or (cok and rok)
        grdy = kr and gate
        more = len(oacc) < total
        iv = more and valid(c)
        # ---- input adapter (the statements of simulateIoJob's step with ready = grdy)
        if narrow:
            kv = full
            kacc = kv and grdy
            acc = iv and (not full or grdy)
            if kacc:
                full = False
            if acc:
                oacc.append(c)
                cnt += 1
                if cnt == rho:
                    cnt, full = 0, True
        elif wide:
            kv = full
            kacc = kv and grdy
            last = cnt == rho - 1
            acc = iv and (not full or (kacc and last))
            if kacc:
                cnt = (cnt + 1) % rho
                if last:
                    full = False
            if acc:
                oacc.append(c)
                full = True
        else:
            kacc = iv and grdy
            if kacc:
                oacc.append(c)
        first = kacc and not mid
        core.step(c, kacc)
        # ---- the core's output beat of this cycle
        ev = core.outAt.pop(c, None)
        inc = 0
        plast = False
        if ev is not None:
            plast = wb == T - 1
            if direct:
                outs.append(c)
            elif natural:
                if plast:
                    incAt[c + RT] = 1
            else:
                inc = 1
            wb = (wb + 1) % T
        if natural:
            inc = incAt.pop(c, 0)
        # ---- reader
        issue = False
        add = 0
        if not direct:
            iok = (rmid or ac != 0) if natural else ac != 0
            if narrow:
                can = resv + rho <= K and ec == 0
            elif wide:
                can = rc != 0 or resv + 1 <= K
            else:
                can = resv + 1 <= K
            issue = iok and can
        pop = fc != 0 and outReady(c)
        if pop:
            outs.append(c)
        n_done = False
        dec = 0
        if issue:
            dec = (0 if rmid else 1) if natural else 1
            if narrow:
                add = rho
                for s in range(rho):
                    pushAt[c + PP + s] = 1
            elif wide:
                add = 1 if rc == 0 else 0
                if rc == rho - 1:
                    pushAt[c + PP] = 1
                rc = (rc + 1) % rho
            else:
                add = 1
                pushAt[c + PP] = 1
            n_done = rb == T - 1
            rmid = rb != T - 1
            rb = (rb + 1) % T
        if narrow and (issue or ec != 0):
            ec = (ec + 1) % rho
        push = pushAt.pop(c, 0)
        # ---- record loader
        if record:
            tr = st in (ST_HDR, ST_DATA) and recNo < polys + (1 if st == ST_DATA else 0)
            tacc = st in (ST_HDR, ST_DATA) and (recNo < polys or st == ST_DATA) and twValid(c)
            n_st, n_rok = st, rok
            if st == ST_HDR:
                if tacc:
                    twacc.append(c)
                    if keep[recNo] and have:
                        n_st, n_rok = ST_OK, True
                    else:
                        tgt = (cur + 1) % NS if have else 0
                        n_st = ST_WAITF
                        dcnt = 0
                    recNo += 1
            elif st == ST_WAITF:
                if use[tgt] == 0:
                    n_st = ST_DATA
            elif st == ST_DATA:
                if tacc:
                    twacc.append(c)
                    dcnt += 1
                    if dcnt == dataBeats:
                        n_st, sc = ST_SETTLE, LDL - 1
            elif st == ST_SETTLE:
                if sc == 0:
                    n_st, n_rok, cur, have = ST_OK, True, tgt, True
                else:
                    sc -= 1
            else:
                if first:
                    n_st, n_rok = ST_HDR, False
            if first:
                use[cur] += 1
                setOf.append(cur)
            if plast:
                use[setOf[wpoly]] -= 1
            st, rok = n_st, n_rok
            peakUse = max(peakUse, max(use))
        if plast:
            wpoly += 1
        # ---- registers
        if kacc:
            mid = bc != T - 1
            bc = (bc + 1) % T
        if first:
            nadm += 1
        cr = cr + (1 if first else 0) - (1 if done_r else 0)
        cok = cr < DP
        done_r = n_done
        ac += inc - dec
        resv += add - (1 if pop else 0)
        fc += push - (1 if pop else 0)
        assert 0 <= fc <= K and resv <= K and ac >= 0, (fc, resv, ac)
        peakCr, peakFc = max(peakCr, cr), max(peakFc, fc)
        if len(outs) == total:
            break
        c += 1
    else:
        raise AssertionError(f'{self.name}: the ports job did not finish in {maxCycles} cycles '
                             f'({len(outs)} of {total} beats out)')
    out = [outs[p * NB:(p + 1) * NB] for p in range(polys)]
    starts = [o[0] for o in out]
    return {'accept': oacc, 'out': out, 'latency': out[0][-1] - oacc[0] + 1,
            'interval': (starts[-1] - starts[0]) / (polys - 1) if polys >= 2 else None,
            'jobCycles': out[-1][-1] - oacc[0] + 1, 'core': core.job(), 'peakCredits': peakCr,
            'peakLanding': peakFc, 'peakUse': peakUse, 'twAccept': twacc, 'depth': DP, 'landing': K}


def portsSteadyInterval(self, polys: int | None = None, pipelineStages=1, **kw) -> float:
    '''The mean spacing of the polynomials' first output beats after the start-up (windows of S).'''
    S = self.S
    P = polys or 6 * S + 6
    kw.setdefault('keep', [True] * P)
    o = [x[0] for x in self.simulatePortsJob(P, pipelineStages=pipelineStages, **kw)['out']]
    return max((o[k + S] - o[k]) / S for k in range(S + 2, len(o) - S))


def recordReport(self, pipelineStages=1, lanes=(1, 2, 4, 8, 16, 32, 64)) -> dict:
    '''The record stream's cost (model): entries per record, the period with a new modulus every polynomial per
    `twiddleLanes` (always-valid streams) and the lanes that keep the core's period.'''
    base = self.portsSteadyInterval(pipelineStages=pipelineStages)
    P = 6 * self.S + 6
    per = {}
    for tl in lanes:
        per[tl] = self.portsSteadyInterval(P, pipelineStages, keep=[False] * P, lanes=tl)
    need = next((tl for tl in lanes if per[tl] <= base), None)
    return {'words': self.recordWords(pipelineStages), 'regions': self.recordRegions(pipelineStages),
            'sets': len(self.moduliList()), 'core period': base, 'period per lanes': per, 'lanes to keep the period': need}


def _portsMemories(self, pipelineStages=1) -> list[dict]:
    if self.portsDirect():
        return []
    geo = self.portsGeometry(pipelineStages)
    OW = self.outputBound.bitWidth
    return [dict(what='output buffer (credit admission)', count=self.W, depth=self.outDepth(pipelineStages) * self.T,
                 width=OW, style=self.memStyle),
            dict(what='landing FIFO', count=1, depth=geo['K'], width=self.io * OW, style='distributed')]


def _portsResources(self, pipelineStages=1) -> dict:
    '''LUTs and registers of the wrapper without its memories: {'lut', 'ff', 'what'}.'''
    W, io = self.W, self.io
    Wd, OW = self.memBound.bitWidth, self.outputBound.bitWidth
    geo = self.portsGeometry(pipelineStages)
    lut, ff = 60, 60                               # gate, credit, counters
    if io != W:
        ff += max(io, W) * Wd                      # the gathering / holding register
        if io > W:
            lut += W * Wd * (-(-(geo['rho'] - 1) // 3))
    if not self.portsDirect():
        ff += io * OW                              # the push register
        if geo['narrow']:
            lut += io * OW * (-(-(geo['rho'] - 1) // 3))
        if geo['wide']:
            ff += io * OW
        if geo['natural']:
            lut += 2 * W * OW * geo['RT']          # the write and the read rotator
            ff += 2 * W * OW * geo['RT']
        lut += 80
        ff += 80 + 2 * (2 + self.RL + geo['RT'])
    if self.twiddleBuffer == 'record':
        nr = len(self.recordRegions(pipelineStages))
        lut += 150 + 3 * nr
        ff += 120 + 2 * max(1, (self.qMax() - 1).bit_length())
    return {'lut': lut, 'ff': ff,
            'what': (io, geo['rho'], 'natural' if geo['natural'] else 'core order',
                     'record' if self.twiddleBuffer == 'record' else 'no record')}


def coreHazards(sch, job: dict, pipelineStages=1) -> list[str]:
    '''checkHazards on the core's job, run by run. A long stall of the admission empties the core; its controller
    then stops and starts again at slot 0, and checkHazards' buffer rule compares slot numbers, so it must not
    mix two runs (it would report a rewrite across the restart, where every buffer is free).'''
    T, sk = sch.T, job['slotk']
    cuts = [0] + [p for p in range(1, len(sk)) if sk[p] <= sk[p - 1]] + [len(sk)]
    errs = []
    for a, b in zip(cuts, cuts[1:]):
        errs += sch.checkHazards({'issue': job['issue'][a:b], 'slotk': sk[a:b], 'accept': job['accept'][a * T:]},
                                 pipelineStages)
    return errs


def portsTestData(op, frames, dirs, qs, validPattern=None, seed: int = 5, pipelineStages: int = 1,
                  outReady=None, twValid=None, alt=None, **_) -> dict:
    '''As HybridNTT.testData for a design with the port options: the port beats, the goldens in the ports'
    order, the cycle the twin takes every output beat, the out_ready and record-valid patterns. alt: a second
    scheme (same structure, other moduli) for polynomials whose modulus is not one of the scheme's.'''
    from .HybridNTTScheme import _rotr
    sch = op.scheme
    P = len(frames)

    def pattern(p, sd, prob):
        if p == 'random':
            rng = random.Random(sd)
            bits = [rng.random() < prob for _ in range(1 << 16)]
            return lambda c: bits[c % len(bits)]
        if p in ('stall', 'longstall'):
            # stalls of several polynomials between bursts; 'longstall': long enough for every credit to be a
            # whole polynomial waiting in the output buffer (all its slots in use)
            rng = random.Random(sd)
            per = sch.cyclesPerPolynomial(pipelineStages)
            lo, hi = (1, 4) if p == 'stall' else (sch.outDepth(pipelineStages) + sch.S + 4, sch.outDepth(pipelineStages) + sch.S + 6)
            bits = []
            while len(bits) < (1 << 17):
                bits += [False] * rng.randrange(lo * per, hi * per) + [True] * rng.randrange(per // 2, 3 * per)
            return lambda c: bits[c % len(bits)]
        if p is None:
            return lambda c: True
        return p
    valid = pattern(validPattern, seed, 0.7)
    oready = pattern(outReady, seed + 1, 0.6)
    twv = pattern(twValid, seed + 2, 0.75)
    record = sch.twiddleBuffer == 'record'
    keep = [f > 0 and qs[f] == qs[f - 1] for f in range(P)] if record else None
    job = sch.simulatePortsJob(P, valid, oready, twv, keep, pipelineStages)
    errs = coreHazards(sch, job['core'], pipelineStages)
    if errs:
        raise AssertionError(f'{op.name}: hazards: {errs[:3]}')
    own = set(sch.moduliList())
    src = [sch if q in own else alt for q in qs]
    if any(s is None for s in src):
        raise ValueError(f'{op.name}: a modulus is not in the design (and no alt scheme)')
    outs = [src[f].transform([frames[f]], [dirs[f]], [qs[f]])[0] for f in range(P)]
    io, natural = sch.io, sch.outputOrder == 'natural'
    TB = sch.n // io
    x, y, tags = [], [], []
    for f in range(P):
        for c in range(TB):
            x.append([frames[f][sch.index(0, c * io + l)] for l in range(io)])
            tags.append((0 if record else sch.midx(qs[f]), 1 if dirs[f] == 'inv' else 0))
            y.append([outs[f][c * io + l if natural else _rotr(c * io + l, sch.U, sch.L)] for l in range(io)])
    ncyc = job['out'][-1][-1] + 20
    tb = {'x': x, 'y': y, 'tags': tags, 'ytags': [tags[f * TB] for f in range(P) for _ in range(TB)],
          'ycycle': [c for o in job['out'] for c in o], 'valid': [1 if valid(c) else 0 for c in range(ncyc)],
          'oready': [1 if oready(c) else 0 for c in range(ncyc)], 'cycles': ncyc, 'job': job}
    if record:
        tb['twvalid'] = [1 if twv(c) else 0 for c in range(ncyc)]
        # per polynomial: keep, which scheme's load image holds its modulus ('main' / 'alt'), the index there
        tb['records'] = [(keep[f], 'main' if src[f] is sch else 'alt', src[f].midx(qs[f])) for f in range(P)]
    return tb


def install(cls) -> None:
    for fn in (_initPorts, portsOn, portsDirect, _checkPorts, portsGeometry, outDepth, recordRegions, recordWords,
               _recordConstants,
               recordBeats, simulatePortsJob, portsSteadyInterval, recordReport, _portsMemories, _portsResources):
        setattr(cls, fn.__name__, fn)
