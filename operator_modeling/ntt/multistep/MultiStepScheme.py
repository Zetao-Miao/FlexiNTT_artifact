'''The multi-step NTT: N = s_1 x s_2 x ... x s_d (d >= 2, powers of two) on P lanes, FHE-ready.

Four-step is d = 2; "seven-step" / "ten-step" style designs are d = 3, 4 (TP-NTT calls them 3-D, 4-D).

    pass 1 -> [transpose] -> twiddle -> pass 2 -> [transpose] -> twiddle -> ... -> pass d

Every pass runs P / s_t copies of one fully pipelined s_t-point sub-NTT (`UnrolledNTTScheme`, one transform
per cycle) side by side, so one polynomial is a frame of F = N / P beats of P coefficients, and polynomials
follow each other back to back (any gap between two polynomials, none inside one).

The index algebra (exact, proven in `runMultiStep.py` gate 1 against the O(N^2) definition):
  input  j = sum_t j_t R_t,  R_t = s_{t+1} ... s_d   (pass 1's digit is the TOP digit of j)
  output k = sum_t k_t C_t,  C_t = s_1 ... s_{t-1}   (pass 1's output digit is the BOTTOM digit of k)
  kernel  x[j] -> sum_j x[j] r^(cA*j + cB*j*k + cG*k)
     negacyclic forward  r = psi (order 2N)   (cA, cB, cG) = ( 1,  2,  0)
     negacyclic inverse  r = psi              (cA, cB, cG) = ( 0, -2, -1)   x N^-1
     cyclic forward      r = w   (order N)    (cA, cB, cG) = ( 0,  1,  0)
     cyclic inverse      r = w                (cA, cB, cG) = ( 0, -1,  0)   x N^-1
  r^(cB j k) splits into the sub-NTTs (r^(cB N/s_t j_t k_t), a cyclic s_t-point NTT with w_t = r^(cB N / s_t))
  and the inter-pass twiddle in front of pass t (t >= 2):
     T_t = r^( R_t j_t (cA + cB K_t) + cG C_{t-1} k_{t-1} ),   K_t = sum_{u<t} k_u C_u,
  plus r^(cA R_1 j_1) in front of pass 1 (the forward negacyclic pre-twist) and r^(cG C_d k_d) behind
  pass d (the inverse negacyclic post-twist). Both ends are folded into the end sub-NTTs by default
  (`twists='merged'`: pass 1 is negacyclic for the forward only, merged psi, no multiplier; pass d is
  negacyclic for the inverse only, CT with its output twist psi^-k), or built as explicit lane banks
  (`twists='bank'`). N^-1 is the product of the sub-NTTs' own n^-1 (per-stage halving by default).
  Forward and inverse share one pipeline and one stream layout: natural index in, natural index out,
  the direction (and the modulus) per polynomial.

Stream layout. A position is (cycle tau of the frame, lane l); every index bit sits on a lane bit or a
cycle bit. Input ('block'): lane = the top log2 P bits of j, cycle = the low bits. A pass needs its
digit on lane bits; the transposes in between are LANE-TIME BIT SWAPS: s lane bits <-> cycle bits
[j0, j0+s) (a generalised barrel-memory-barrel: P/S groups of S = 2^s lanes, one memory of S 2^j0
words per lane, latency S 2^j0 + 2 BL + 1). Only the swapped field moves, so every pending digit stays
contiguous. The output layout follows (`outputIndex`); it equals the input layout for d = 2 and
s_1 = P.

Twiddles. With digit t on the lanes, T_t's exponent on lane l is c_l + sum_b g_{l,b} tau_b (affine in
the cycle bits). Supplies (`twiddleSource`):
  'rom'   per lane a ROM over the significant cycle bits, one block per {modulus, direction};
  'otf'   two-level: two ROMs (low / high significant bits) and one generator multiplier per lane;
  'auto'  per stage the cheaper of the two by the cost model (LUT + 100 DSP + 300 BRAM36).
Lanes whose factor is 1 for every modulus and direction take no multiplier. Identical tables are shared.
Multipliers: `ModularMultiplierScheme` (versal_arith datapath; Barrett over the modulus table, per-beat
modulus), the same family and backend as the sub-NTTs' butterflies; one DSP budget over all of them
(`setDspBudget`).
'''
from __future__ import annotations

from functools import reduce

from ...core.IntType import IntType
from ...core.utils import bitReverse


def _log2(x: int) -> int:
    b = x.bit_length() - 1
    if x < 1 or (1 << b) != x:
        raise ValueError(f'{x} is not a power of two')
    return b


def _prod(xs) -> int:
    return reduce(lambda a, b: a * b, xs, 1)


#: URAM288 weight in BRAM36 tiles, the area metric we report (and TP-NTT's): 1 URAM = 8 BRAM
URAM_BRAM_EQ = 8
#: the depth rule of `memStyle='uram'` (an explicit option): memories of at least this many words go to URAM
URAM_MIN_DEPTH = 512


def memoryStyle(depth: int, style: str = 'auto', uramMinDepth: int | None = None) -> str:
    ''''uram', 'bram' or 'cheaper' (decided by tiles) for a block memory of `depth` words under `memStyle`:
    'auto' the cheaper of BRAM36 tiles and 8 x URAM tiles (tie: BRAM), unless a fit check lowered
    `uramMinDepth` (then depth >= it: URAM); 'uram' depth >= 512 words: URAM; 'bram' always BRAM.'''
    if style == 'bram':
        return 'bram'
    if style == 'uram':
        return 'uram' if depth >= URAM_MIN_DEPTH else 'bram'
    if uramMinDepth is not None and depth >= uramMinDepth:
        return 'uram'
    return 'cheaper'


def memoryTiles(depth: int, width: int, style: str = 'auto', uramMinDepth: int | None = None) -> dict:
    '''Block memory for one depth x width memory: BRAM36 tiles (aspect 512x72 .. 32768x1, cascaded in
    depth; a BRAM18 counts 0.5) or URAM288 tiles (4096x72 cascaded), by `memoryStyle`; 'cheaper' compares
    BRAM tiles with URAM_BRAM_EQ x URAM tiles (tie: BRAM).'''
    import math
    best = None
    for wc, dc in ((72, 512), (36, 1024), (18, 2048), (9, 4096), (4, 8192), (2, 16384), (1, 32768)):
        t = math.ceil(width / wc) * math.ceil(depth / dc)
        best = t if best is None else min(best, t)
    if depth <= 512 and width <= 36:
        best = 0.5
    ur = math.ceil(width / 72) * math.ceil(depth / 4096)
    st = memoryStyle(depth, style, uramMinDepth)
    if st == 'cheaper':
        st = 'uram' if URAM_BRAM_EQ * ur < math.ceil(best) else 'bram'
    if st == 'uram':
        return {'bram36': 0, 'uram': ur}
    return {'bram36': best, 'uram': 0}


KERNELS = {  # (negacyclic, direction) -> (cA, cB, cG)
    (True, 'fwd'): (1, 2, 0), (True, 'inv'): (0, -2, -1),
    (False, 'fwd'): (0, 1, 0), (False, 'inv'): (0, -1, 0),
}


# ---------------------------------------------------------------------------------------------------
# The index plan: layouts, transposes, wiring (no arithmetic)
# ---------------------------------------------------------------------------------------------------

class MultiStepPlan:
    '''Where every index bit is at every point of the pipeline.

    A logical bit is (t, b): bit b of pass t's digit (j_t before pass t, k_t after it). `lane[l]` /
    `time[u]` say which logical bit lane bit l / cycle bit u carries.'''

    def __init__(self, N: int, sizes, lanes: int, swapPolicy: str = 'recent', inputLayout: str = 'block',
                 outputOrder: str = 'pass'):
        self.N, self.P = N, lanes
        self.m, self.p = _log2(N), _log2(lanes)
        self.f = self.m - self.p
        self.F = N // lanes
        self.sizes = [int(s) for s in sizes]
        self.d = len(self.sizes)
        self.a = [_log2(s) for s in self.sizes]
        if self.d < 2:
            raise ValueError('a multi-step NTT has at least two passes')
        if sum(self.a) != self.m:
            raise ValueError(f'the sizes {self.sizes} multiply to {_prod(self.sizes)}, not N = {N}')
        if any(a > self.p for a in self.a):
            raise ValueError(f'every sub-NTT size must be <= P = {lanes} (a sub-NTT takes all its points '
                             f'in one cycle), got {self.sizes}')
        if any(a < 2 for a in self.a):
            raise ValueError('sub-NTT sizes are >= 4 (UnrolledNTTScheme)')
        if self.f < 0:
            raise ValueError('P > N')
        d = self.d
        self.R = [_prod(self.sizes[t + 1:]) for t in range(d)]
        self.C = [_prod(self.sizes[:t]) for t in range(d)]
        self.jo = [_log2(r) for r in self.R]           # input bit offset of digit t
        self.ko = [_log2(c) for c in self.C]           # output bit offset of digit t
        lane = [self._jbit(self.f + l) for l in range(self.p)]
        if inputLayout == 'block':
            time = [self._jbit(u) for u in range(self.f)]
        elif inputLayout == 'pass':
            # the cycle bits hold the pending digits in pass order (the next pass's digit lowest): every
            # transpose then puts the finished digit where the output's natural (block) layout wants it
            time = [(t, b) for t in range(d) for b in range(self.a[t]) if (t, b) not in lane]
        else:
            raise ValueError("inputLayout 'block' or 'pass'")
        self.inputLayout = inputLayout
        self.inLane, self.inTime = list(lane), list(time)
        self.steps = []          # dicts: kind 'transpose' | 'pass'
        for t in range(d):
            if t > 0:
                tpos = [u for u in range(self.f) if time[u][0] == t]
                if tpos:
                    j0, s = tpos[0], len(tpos)
                    if tpos != list(range(j0, j0 + s)):
                        raise AssertionError(f'digit {t} is not contiguous on the cycle bits: {tpos}')
                    cand = [l for l in range(self.p) if lane[l][0] < t]
                    if len(cand) < s:
                        raise AssertionError('not enough finished lane bits to swap out')
                    if swapPolicy == 'recent':
                        cand.sort(key=lambda l: (-lane[l][0], l))
                    elif swapPolicy == 'low':
                        cand.sort()
                    else:
                        raise ValueError("swapPolicy 'recent' or 'low'")
                    out = sorted(cand[:s])
                    for i, l in enumerate(out):
                        lane[l], time[j0 + i] = time[j0 + i], lane[l]
                    self.steps.append({'kind': 'transpose', 'before': t, 'laneBits': out, 'timeLo': j0, 's': s,
                                       'lane': list(lane), 'time': list(time)})
            pos = [None] * self.a[t]
            for l in range(self.p):
                if lane[l][0] == t:
                    pos[lane[l][1]] = l
            if any(x is None for x in pos):
                raise AssertionError(f'pass {t}: digit not on the lanes')
            self.steps.append({'kind': 'pass', 't': t, 'digitLanes': pos, 'lane': list(lane), 'time': list(time)})
        self.outLane, self.outTime = list(lane), list(time)
        self._outputPlan(outputOrder, list(lane), list(time))

    def _kbit(self, i: int) -> tuple[int, int]:
        for t in range(self.d):
            if self.ko[t] <= i < self.ko[t] + self.a[t]:
                return (t, i - self.ko[t])
        raise AssertionError(i)

    def _outputPlan(self, outputOrder: str, lane, time) -> None:
        '''The output order. 'pass' (default): as the last pass leaves it (`outputIndex`). 'block': the input's
        block layout (index = cycle + F x lane); 'natural': index = cycle x P + lane. For the last two, lane-time
        transposes behind the last pass (`outSteps`, 'before' = d + 1, d + 2, ...) put every output bit that belongs
        on the cycle bits there (each swaps a contiguous run of wrong cycle bits with the lane bits that hold the
        bits wanted there), then a lane permutation (wiring, kind 'wire') finishes. `finLane` / `finTime`: the
        final layout; `outLane` / `outTime` stay the layout behind the last pass (the output twiddle stage's).'''
        if outputOrder not in ('pass', 'block', 'natural'):
            raise ValueError("outputOrder 'pass' (as the last pass leaves it), 'block' (index = cycle + F x lane, "
                             "the input's layout) or 'natural' (index = cycle x P + lane)")
        self.outputOrder = outputOrder
        self.outSteps = []
        self.finLane, self.finTime = list(lane), list(time)
        if outputOrder == 'pass':
            return
        f, p = self.f, self.p
        if outputOrder == 'block':
            tgtTime = [self._kbit(u) for u in range(f)]
            tgtLane = [self._kbit(f + l) for l in range(p)]
        else:
            tgtLane = [self._kbit(l) for l in range(p)]
            tgtTime = [self._kbit(p + u) for u in range(f)]
        nxt = self.d + 1
        guard = 0
        while time != tgtTime:
            guard += 1
            if guard > 4 * (f + 1):
                raise AssertionError('output order: the transposes do not converge')
            good = [u for u in range(f) if time[u] != tgtTime[u] and tgtTime[u] in lane]
            runs = []
            for u in good:
                if runs and runs[-1][-1] == u - 1:
                    runs[-1].append(u)
                else:
                    runs.append([u])
            if runs:
                run = max(runs, key=lambda r: (len(r), -r[0]))
                out = [lane.index(tgtTime[u]) for u in run]
            else:
                # only a permutation among cycle bits is left: park one wrong cycle bit on a lane bit
                u = next(u for u in range(f) if time[u] != tgtTime[u])
                run, out = [u], [0]
            j0, s = run[0], len(run)
            for i, l in enumerate(out):
                lane[l], time[j0 + i] = time[j0 + i], lane[l]
            self.outSteps.append({'kind': 'transpose', 'before': nxt, 'laneBits': out, 'timeLo': j0, 's': s,
                                  'lane': list(lane), 'time': list(time), 'output': True})
            nxt += 1
        if lane != tgtLane:
            # new lane bit b <- the lane bit that holds the wanted bit
            self.outSteps.append({'kind': 'wire', 'src': [lane.index(tgtLane[b]) for b in range(p)],
                                  'lane': list(tgtLane), 'time': list(time)})
        self.finLane, self.finTime = list(tgtLane), list(tgtTime)

    def _jbit(self, i: int) -> tuple[int, int]:
        for t in range(self.d):
            if self.jo[t] <= i < self.jo[t] + self.a[t]:
                return (t, i - self.jo[t])
        raise AssertionError(i)

    # --- positions <-> indices -------------------------------------------------------------------

    def digits(self, lane, time, tau: int, l: int) -> list[int]:
        v = [0] * self.d
        for b, (t, i) in enumerate(lane):
            v[t] |= ((l >> b) & 1) << i
        for b, (t, i) in enumerate(time):
            v[t] |= ((tau >> b) & 1) << i
        return v

    def inputIndex(self, tau: int, l: int) -> int:
        v = self.digits(self.inLane, self.inTime, tau, l)
        return sum(v[t] * self.R[t] for t in range(self.d))

    def outputIndex(self, tau: int, l: int) -> int:
        v = self.digits(self.finLane, self.finTime, tau, l)
        return sum(v[t] * self.C[t] for t in range(self.d))

    def outputIsBlock(self) -> bool:
        '''Whether the output stream has the input's layout (lane = top bits, cycle = low bits).'''
        return all(self.outputIndex(tau, l) == tau + self.F * l for tau in range(self.F) for l in range(self.P))

    def inputIsBlock(self) -> bool:
        return all(self.inputIndex(tau, l) == tau + self.F * l for tau in range(self.F) for l in range(self.P))

    def transposes(self) -> list[dict]:
        return [s for s in self.steps + self.outSteps if s['kind'] == 'transpose']

    def describe(self) -> str:
        def lay(lane, time):
            return ('lanes ' + ' '.join(f'{t}.{b}' for t, b in reversed(lane)) + ' | cycle '
                    + ' '.join(f'{t}.{b}' for t, b in reversed(time)))
        out = [f'N={self.N} P={self.P} F={self.F} sizes={self.sizes} (pass order)',
               '  in      ' + lay(self.inLane, self.inTime)]
        for s in self.steps + self.outSteps:
            if s['kind'] == 'wire':
                out.append(f"  wire    new lane bit b <- lane bit {s['src']}[b]")
            elif s['kind'] == 'transpose':
                out.append(f"  T{s['before']}      swap lane bits {s['laneBits']} <-> cycle bits "
                           f"[{s['timeLo']},{s['timeLo'] + s['s']}): S={1 << s['s']} lanes, "
                           f"{1 << (s['s'] + s['timeLo'])} words/lane;  " + lay(s['lane'], s['time']))
            else:
                out.append(f"  pass {s['t']}  {self.sizes[s['t']]}-point x {self.P // self.sizes[s['t']]} on lanes "
                           f"{s['digitLanes']}")
        out.append(f'  input block layout: {self.inputIsBlock()}, output block layout: {self.outputIsBlock()}')
        return '\n'.join(out)


# ---------------------------------------------------------------------------------------------------
# Reference transforms (independent of the plan)
# ---------------------------------------------------------------------------------------------------

def rootFor(q: int, order: int) -> int:
    '''The primitive `order`-th root of unity mod q the big transform uses (roots.fixedRoot).'''
    from sage.all import GF
    from ..roots import fixedRoot
    return int(fixedRoot(GF(q), order))


def referenceDirect(x, q, r, negacyclic, d):
    '''O(N^2) definition: negacyclic X[k] = sum x[j] psi^(j(2k+1)); inverse with psi^-1 and N^-1.'''
    N = len(x)
    cA, cB, cG = KERNELS[(negacyclic, d)]
    order = 2 * N if negacyclic else N
    sc = pow(N, -1, q) if d == 'inv' else 1
    out = []
    for k in range(N):
        acc = 0
        for j in range(N):
            acc += x[j] * pow(r, (cA * j + cB * j * k + cG * k) % order, q)
        out.append(acc * sc % q)
    return out


def referenceFast(x, q, r, negacyclic, d):
    '''O(N log N): twist, radix-2 cyclic NTT (natural order), twist, scale.'''
    N = len(x)
    cA, cB, cG = KERNELS[(negacyclic, d)]
    order = 2 * N if negacyclic else N
    a = [x[j] * pow(r, (cA * j) % order, q) % q for j in range(N)]
    w = pow(r, cB % order, q)              # primitive N-th root of the cyclic part
    L = _log2(N)
    # iterative CT, bit-reversed input -> natural output
    a = [a[int(format(i, f'0{L}b')[::-1], 2) if L else 0] for i in range(N)]
    m = 1
    while m < N:
        wm = pow(w, N // (2 * m), q)
        for k in range(0, N, 2 * m):
            wj = 1
            for j in range(m):
                u, v = a[k + j], a[k + j + m] * wj % q
                a[k + j], a[k + j + m] = (u + v) % q, (u - v) % q
                wj = wj * wm % q
        m *= 2
    sc = pow(N, -1, q) if d == 'inv' else 1
    return [a[k] * pow(r, (cG * k) % order, q) * sc % q for k in range(N)]


# ---------------------------------------------------------------------------------------------------
# The scheme
# ---------------------------------------------------------------------------------------------------

class MultiStepScheme:
    '''A multi-step NTT (see the module notes). Arguments:

      N, sizes        transform size and the sub-NTT sizes in pass order (product N, each <= lanes)
      lanes           P, coefficients per cycle
      moduli          the run-time moduli (MIDX per polynomial); or q= one fixed modulus
      negacyclic      True (X^N + 1) or False (cyclic)
      direction       'forward' | 'inverse' | 'both' (DIR per polynomial)
      twists          'merged' (end sub-NTTs negacyclic per direction) | 'bank' (explicit lane banks)
      twiddleSource   'auto' | 'rom' | 'otf' (per inter-pass stage, or a list, one per stage)
      butterfly       the sub-NTTs' butterfly options (reduction, multiplier, ...); the twiddle
                      multipliers use the same reduction and multiplier backend
      transpose       'bmb' (the lane-time barrel-memory-barrel) [| 'mbm': model only]
      targetFmaxMhz   the timing model's target for every block (barrel shifters, multipliers, sub-NTTs)
    '''

    def __init__(self, name: str, N: int, sizes, lanes: int, moduli=None, q: int = 0,
                 negacyclic: bool = True, direction: str = 'both', twists: str = 'merged',
                 twiddleSource='auto', butterfly: dict | None = None, transpose: str = 'bmb',
                 targetFmaxMhz: float | None = 350.0, inverseScale: str = 'stage', swapPolicy: str = 'recent',
                 subArgs: dict | None = None, tableShare: int = 8, romStyleMaxDepth: int = 64,
                 family=None, inputLayout: str = 'block', form: str = 'twist', memStyle: str = 'auto',
                 bramBudget: float | None = None, dspFraction: float | None = None, memTol=(16, 0.05),
                 loadable: bool = False, dspTotal: int | None = None, budgetRule: str = 'area',
                 areaTol: float = 0.03, autoForms=None, portAlign: str = 'data', ramLatency: int = 2,
                 crossRegs: int = 0, crossAt='all', tableSupply: str = 'core', outReady: bool = False,
                 outFifoDepth: int | None = None, outputOrder: str = 'pass', loadableModuli: bool = False,
                 loadLanes: int = 1, slotManager: bool = False, loadByDirection: bool = False):
        self.name = name
        #: options of 2026-11-14 (all off by default; docs/USAGE.md 4k2):
        #: ramLatency: cycles from a twiddle table's address to its word (2: registered address, registered read;
        #:   more: plain register stages behind every table of this design, or the time an outside table has)
        if int(ramLatency) < 2:
            raise ValueError(f'{name}: ramLatency >= 2 (registered address, registered read, then register stages)')
        self.TABLE_LAT = self._ramLatencyGiven = int(ramLatency)
        #: crossRegs: register stages (never shift registers) between blocks, for SLR crossings; crossAt: 'all'
        #:   (between every two blocks), 'mid' (one cut, nearest half the latency) or a list of block numbers of
        #:   `schedule()` without the cuts (a cut in front of each)
        if int(crossRegs) < 0:
            raise ValueError(f'{name}: crossRegs >= 0')
        self.crossRegs, self.crossAt = int(crossRegs), crossAt
        #: tableSupply: 'core' (tables inside) | 'stream' (every table of this design outside: ports tw_addr_<k> /
        #:   tw_data_<k>, the word `ramLatency` cycles after its address; the sub-NTTs' own constants stay inside)
        if tableSupply not in ('core', 'stream'):
            raise ValueError(f"{name}: tableSupply 'core' or 'stream'")
        if tableSupply == 'stream' and loadable:
            raise ValueError(f"{name}: tableSupply='stream' with loadable: the tables are outside, load them there")
        self.tableSupply = tableSupply
        #: outReady: ports in_ready / out_ready; the output waits in a FIFO of `outFifoDepth` beats (default: the
        #:   next power of two >= pipeline latency + F + 8) and a new polynomial is taken only when it fits
        self.outReady = bool(outReady)
        self._outFifoDepth = outFifoDepth
        #: folded passes: 'data' (the sub-NTT delays every port twiddle to its stage), 'address' (this design delays
        #: the table address per stage instead: a few bits per stage in place of a word per butterfly)
        if portAlign not in ('data', 'address'):
            raise ValueError(f"{name}: portAlign 'data' or 'address'")
        self.portAlign = portAlign
        self.formDecision = None
        #: the forms `form='auto'` chooses among (None: every one of `formCandidates()`); ('twist', 'folded') is
        #: the set before folded_gs was buildable (2026-11-11), for rows whose results must stay reproducible
        self.autoForms = None if autoForms is None else tuple(autoForms)
        if self.autoForms is not None and not set(self.autoForms) <= {'twist', 'folded', 'folded_gs'}:
            raise ValueError(f"{name}: autoForms {autoForms}: a subset of 'twist', 'folded', 'folded_gs'")
        if budgetRule not in ('area', 'memory'):
            raise ValueError(f"{name}: budgetRule 'area' (one DSP count for every form, least area) or 'memory' "
                             f"(memory first, then the percentage of the pick: the rule before 2026-11-11)")
        if dspFraction is not None and dspTotal is not None:
            raise ValueError(f'{name}: give dspFraction or dspTotal, one of them')
        budgeted = dspFraction is not None or dspTotal is not None
        if form == 'auto' and budgeted and budgetRule == 'area':
            # the user's rule of 2026-11-11: with a DSP budget, one DSP count for every form, then the least area
            args = dict(locals())
            for k in ('self', 'form', '__class__', 'budgeted'):
                args.pop(k, None)
            self.formDecision = MultiStepScheme.chooseFormBudget(args, dspFraction, dspTotal, areaTol)
            pick = self.formDecision['pickBuildable']
            form = pick['form']
            if pick.get('source'):
                twiddleSource = pick['source']
            dspFraction, dspTotal = None, self.formDecision['budget']
        elif form == 'auto':
            # the user's rule (FORM_ANALYSIS.md section 7): memory first on closed-form counts, then build the pick
            args = dict(locals())
            for k in ('self', 'form', '__class__', 'budgeted'):
                args.pop(k, None)
            ref = MultiStepScheme(**{**args, 'name': f'{name}_ref', 'form': 'twist', 'dspFraction': None,
                                     'dspTotal': None})
            self.formDecision = ref.chooseForm(memTol=memTol)
            pick = self.formDecision['pickBuildable']
            form = pick['form']
            if pick.get('source'):
                twiddleSource = pick['source']
        self.plan = MultiStepPlan(N, sizes, lanes, swapPolicy, inputLayout, outputOrder)
        self.outputOrder = outputOrder
        self.N, self.P, self.F, self.d = N, lanes, self.plan.F, self.plan.d
        self.sizes = self.plan.sizes
        if (moduli is None) == (not q):
            raise ValueError(f'{name}: give moduli=[...] (per polynomial) or q= (fixed), one of them')
        #: loadable (TP-NTT-matched): one run-time modulus per job (family=, the q ports static), every twiddle table a
        #: RAM written through the load port (`loadImage(q)`), holding one modulus; `moduli` are the test primes
        #: loadableModuli (2026-11-15): run-time moduli with a change per polynomial.
        #:  * The modulus constants of a polynomial come with it (ports mq_<constant>, sampled with MIDX) and travel
        #:    in the tag beside the data, through this design and into the sub-NTTs: no table, no slot for them.
        #:  * The twiddle tables are outside (tableSupply='stream'), or inside as RAMs with one block per slot
        #:    (tableSupply='core'): MIDX names the slot of each polynomial, and a slot is filled through the load
        #:    port (ld_rst with ld_slot, then one word per ld_wen) in the order of the passes, so the load follows
        #:    the data (MultiStepNTT.slotTiming).
        #: `moduli` are stand-ins (one per slot). Every form: the twiddle tables of the sub-NTTs (the forms with
        #: multipliers between the passes) and the factor tables of those multipliers (stored, the two tables of
        #: the on-the-fly product, the tree's seeds) are slots too, filled by the same load.
        self.loadMod = bool(loadableModuli)
        #: loadLanes: words the load port takes per cycle (the units of a load are split over that many lanes).
        #: slotManager: the slots rotate under a manager in the design (rtl_gen/slot_manager.py): the outside
        #: announces the modulus of each coming polynomial and answers the load requests. Without it the outside
        #: names the slots and loads them itself (every modulus of the workload loaded once).
        self.loadLanes, self.slotMgr = int(loadLanes), bool(slotManager)
        #: loadByDirection (both directions in one design): a load fills the tables of one direction of one modulus
        #: (ld_dir with ld_rst). A table of both directions takes the words of that half, a table of one direction
        #: is written only by a load of its direction. A slot then belongs to a modulus and a direction.
        self.loadDir = bool(loadByDirection) and direction == 'both'
        if (self.loadLanes > 1 or self.slotMgr) and not self.loadMod:
            raise ValueError(f'{name}: loadLanes and slotManager go with loadableModuli')
        if self.loadMod:
            if moduli is None or family is None or loadable:
                raise ValueError(f'{name}: loadableModuli needs moduli= (one stand-in per slot) and family= (the '
                                 f'run-time moduli), without loadable')
        self.loadable = bool(loadable)
        if self.loadable and (family is None or moduli is None):
            raise ValueError(f'{name}: loadable needs family= (the run-time modulus) and moduli= (test primes)')
        self.perFrame = moduli is not None and not self.loadable
        self.moduli = list(moduli) if moduli is not None else [q]
        self._loadQ = self.moduli[0]
        self.q = q
        self.negacyclic = bool(negacyclic)
        if direction not in ('forward', 'inverse', 'both'):
            raise ValueError(f"{name}: direction 'forward', 'inverse' or 'both'")
        self.direction = direction
        self.dirs = (['fwd'] if direction in ('forward', 'both') else []) + \
                    (['inv'] if direction in ('inverse', 'both') else [])
        if twists not in ('merged', 'bank'):
            raise ValueError(f"{name}: twists 'merged' or 'bank'")
        if form not in ('twist', 'folded', 'folded_gs'):
            raise ValueError(f"{name}: form 'twist' (inter-pass multipliers), 'folded' (TP-NTT: stage twiddles), "
                             f"'folded_gs' (folded with a GS inverse: no output stage) or "
                             f"'auto' (FORM_ANALYSIS.md: least memory within a DSP budget, else dominance)")
        if form == 'folded_gs' and direction == 'forward':
            raise ValueError(f"{name}: form 'folded_gs' is the unified CT/GS design (direction='both') or, for "
                             f"direction='inverse', its Gentleman-Sande half alone; the forward alone: 'folded' "
                             f"(the same hardware without the GS half)")
        if form == 'folded_gs' and inverseScale not in ('stage', 'none'):
            raise ValueError(f"{name}: form 'folded_gs' scales the inverse per stage (inverseScale 'stage') or not "
                             f"at all ('none'): the unified butterfly has no output twist to carry N^-1")
        #: 'twist': inter-pass twiddle multipliers (the default); 'folded': TP-NTT's form, every pass after the
        #: first runs its stages of the big NTT with per-beat butterfly twiddles from tables (no inter-pass
        #: multiplier); the inverse's twist r^-k then is one P-lane stage at the output (factor 1 forward).
        #: 'folded_gs': TP-NTT's inverse too: every pass (the first included) is a unified CT/GS sub-NTT with
        #: per-beat twiddles from tables; forward CT with the input twist of the finished digits merged (as
        #: 'folded'), inverse GS on the same passes in the same order with the output twist of the pending
        #: digits and r^-k merged, so no inter-pass multiplier and no output stage. Any pass sizes.
        #: 'folded_gs' with direction='inverse' (2026-11-16): the Gentleman-Sande half alone. Every pass is a
        #: plain GS sub-NTT with twiddle ports (no unified unit, no DIR choice at the ports); r^-k and the cross
        #: terms are in the port twiddles, N^-1 in the per-stage halvers: an inverse-only core with no twist
        #: multiplier at all (a butterfly absorbs a per-point factor on the side of its multiplier: GS the output)
        self.form = form
        self.gsInv = form == 'folded_gs' and direction == 'inverse'
        if memStyle not in ('auto', 'bram', 'uram'):
            raise ValueError(f"{name}: memStyle 'auto' (per memory the cheaper of BRAM36 and {URAM_BRAM_EQ} x "
                             f"URAM tiles), 'bram' or 'uram' (>= {URAM_MIN_DEPTH} words)")
        #: block-memory style of the deep transposes and the twiddle ROMs (RTL ram_style / rom_style and model)
        self.memStyle = memStyle
        #: fit check (generic, user's budget): with 'auto', when the design's BRAM36 total exceeds `bramBudget`,
        #: memories from the deepest down move to URAM until it fits (`fitMemories`); None: no check
        self.bramBudget = bramBudget
        self._uramMinDepth = None
        self.twists = twists if self.negacyclic else 'none'
        if form in ('folded', 'folded_gs'):
            self.twists = 'merged' if self.negacyclic else 'none'
        self.order = 2 * N if self.negacyclic else N
        for qq in self.moduli:
            if (qq - 1) % self.order:
                raise ValueError(f'{name}: {self.order} does not divide q - 1 for q = {qq}')
        self.butterflyArgs = dict(butterfly or {})
        #: the run-time family the datapaths are built over (None: ModulusFamily.table(moduli)); WLM needs one
        self.family = family
        self.transposeKind = transpose
        if transpose not in ('bmb', 'mbm'):
            raise ValueError(f"{name}: transpose 'bmb' or 'mbm'")
        self.targetFmaxMhz = targetFmaxMhz
        self.inverseScale = inverseScale
        self.subArgs = dict(subArgs or {})
        self.tableShare = tableShare
        self.romStyleMaxDepth = romStyleMaxDepth
        self.qMax = max(self.moduli)
        self.W = max(1, (self.qMax - 1).bit_length())
        self._roots = {}
        nstages = self.d - 1
        if isinstance(twiddleSource, (list, tuple)):
            if len(twiddleSource) != nstages:
                raise ValueError(f'{name}: one twiddle source per inter-pass stage ({nstages})')
            self.twiddleRequest = list(twiddleSource)
        else:
            self.twiddleRequest = [twiddleSource] * nstages
        for s in self.twiddleRequest:
            if s not in ('auto', 'rom', 'otf', 'tree'):
                raise ValueError(f"{name}: twiddleSource 'auto', 'rom', 'otf' or 'tree'")
        self._dspPlan = None
        self._buildSubs()
        self._buildTwiddleStages()
        if bramBudget is not None:
            self.fitInfo = self.fitMemories()
        if dspFraction is not None or dspTotal is not None:
            self.formDecision = self.formDecision or {'rule': 'given form'}
            # the top-down DSP split on the chosen design, LUT multipliers for the rest. budgetRule 'memory': the
            # percentage of this design's own DSP count; 'area': the count every candidate was given
            before = self.resources()['total']
            self.setDspBudget(fraction=dspFraction, total=dspTotal)
            after = self.resources()['total']
            self.formDecision['dspSplit'] = {'fraction': dspFraction, 'total': dspTotal,
                                             'dspBefore': before['dsp'], 'dsp': after['dsp'],
                                             'lutBefore': before['lut'], 'lut': after['lut'],
                                             'lutAdded': after['lut'] - before['lut']}
        self._settleTableLatency()

    # --- a register behind a block-RAM table that feeds fabric logic ---------------------------------

    def _tableNeedsOutputRegister(self) -> bool:
        '''A table of this design sits in block RAM or URAM and its word enters a multiplier through fabric logic
        with no register in between (`DspMultiplierScheme.fabricBeforeFirstRegister`). The read register of the
        RAM is then the launch register of that stage, and a RAM's clock to output is about 0.8 ns slower than a
        flip-flop's: MS_N14_q60_P32_tpmda reached 282 MHz for 350 on this path (2026-11-16).'''
        if self.tableSupply != 'core':
            return False                       # an outside table: its timing is the `ramLatency` the user gives
        lim = 4 * self.romStyleMaxDepth
        deep = {'tw': False, 'gen': False, 'port': False}
        for t, st in self.stages.items():
            src = st['source']
            tabs = self.treeTables(t, values=False) if src == 'tree' else self.tablesOf(st, src, values=False)
            if any(tb['depth'] > lim for tb in tabs):
                deep['tw' if src == 'rom' else 'gen'] = True
        for t in range(self.d):
            if self.folded(t) and any(tb['depth'] > lim for tb in self.portTables[t]['tables']):
                deep['port'] = True

        def fabric(m) -> bool:
            dp = m.datapath()
            return any(n.kind == 'mult' and getattr(n, 'backend', None) == 'dsp'
                       and any(i in dp.inputs for i in n.inputs)
                       and dp.dspScheme(n, m.targetFmaxMhz).fabricBeforeFirstRegister() for n in dp.nodes)
        if deep['tw'] and fabric(self.multiplier(f'{self.name}_twmul')):
            return True
        if deep['gen'] and fabric(self.multiplier(f'{self.name}_twgen')):
            return True
        if deep['port']:
            for t, sub in enumerate(self.subs):
                if self.folded(t) and any(fabric(b) for st in sub.butterflies for b in st if hasattr(b, 'datapath')):
                    return True
        return False

    def _settleTableLatency(self):
        '''`ramLatency` 2 becomes 3 (one register stage behind every table) when `_tableNeedsOutputRegister`.
        Run when the design and its DSP split are known; a later `setDspBudget` runs it again.'''
        self.TABLE_LAT = self._ramLatencyGiven
        self.tableRegAuto = False
        if self.TABLE_LAT == 2 and self._tableNeedsOutputRegister():
            self.TABLE_LAT, self.tableRegAuto = 3, True

    # --- roots ---------------------------------------------------------------------------------

    def root(self, q: int) -> int:
        '''psi (negacyclic, order 2N) or w (cyclic, order N) of modulus q; every sub-NTT root and every
        twiddle is a power of it.'''
        if q not in self._roots:
            self._roots[q] = rootFor(q, self.order)
        return self._roots[q]

    def subRoot(self, t: int, q: int) -> int:
        '''The root UnrolledNTTScheme takes for pass t: psi_t = r^(N/s_t) when that sub-NTT is negacyclic in a
        direction (merged twist), else its cyclic w_t = r^(cB N/s_t) with cB = 2 (negacyclic) or 1.'''
        r = self.root(q)
        e = self.N // self.sizes[t]
        if self._subNwc(t):
            return pow(r, e, q)
        return pow(r, (2 if self.negacyclic else 1) * e, q)

    def _subNwc(self, t: int):
        '''negacyclic= of pass t's sub-NTT.'''
        if self.twists != 'merged' or self.form == 'folded_gs':
            return False                      # folded_gs: every twist comes in through the twiddle ports
        if t == 0 and t == self.d - 1:
            return True
        if t == 0:
            return 'forward' if 'fwd' in self.dirs else False
        if t == self.d - 1:
            if self.form == 'folded':
                return False                  # folded: the whole inverse twist r^-k in the output stage
            return 'inverse' if 'inv' in self.dirs else False
        return False

    def folded(self, t: int) -> bool:
        '''Whether pass t takes its butterfly twiddles from ports (the folded form: passes after the first;
        folded_gs: every pass).'''
        return (self.form == 'folded' and t > 0) or self.form == 'folded_gs'

    def portLatency(self, t: int) -> int:
        '''Cycles the data of a folded pass waits for its port twiddles: the table read; folded_gs: and the
        registered choice between the forward and the inverse table.'''
        return self.TABLE_LAT + (1 if (self.form == 'folded_gs' and not self.gsInv) else 0)

    # --- the sub-NTTs ----------------------------------------------------------------------------

    #: sub-NTT schemes shared across MultiStepScheme instances (design-space sweeps): same N, size, mode, args
    _SUB_CACHE: dict = {}

    def _buildSubs(self) -> None:
        from ..dataflow.UnrolledNTT import UnrolledNTTScheme
        self.subs = []
        cache = {}
        for t, n in enumerate(self.sizes):
            nwc = self._subNwc(t)
            gs = self.form == 'folded_gs' and not self.gsInv      # the unified unit; gsInv: plain GS butterflies
            key = (n, nwc, self.folded(t))
            if key in cache:
                self.subs.append(cache[key])
                continue
            gkey = (self.N, n, nwc, self.folded(t), gs, tuple(self.moduli), self.q, repr(self.family), self.direction,
                    self.inverseScale, repr(sorted(self.butterflyArgs.items(), key=str)), self.targetFmaxMhz,
                    repr(sorted(self.subArgs.items())), self.negacyclic, self.portAlign, self.loadable,
                    getattr(self, 'loadMod', False), getattr(self, 'loadDir', False), self.gsInv)
            if gkey in MultiStepScheme._SUB_CACHE and not getattr(self, '_privateSubs', False):
                cache[key] = MultiStepScheme._SUB_CACHE[gkey]
                self.subs.append(cache[key])
                continue
            if self.loadable:
                fam = dict(family=self.family)
            elif self.perFrame:
                fam = dict(moduli=self.moduli, family=self.family)
            else:
                fam = dict(q=self.q)
            tt = t

            def rootOf(q, order, tt=tt):
                return self.subRoot(tt, q)
            args = dict(butterflyType='GS' if self.gsInv else 'CT', negacyclic=nwc, direction=self.direction,
                        inverseScale=self.inverseScale if 'inv' in self.dirs else 'output',
                        butterfly=dict(self.butterflyArgs), targetFmaxMhz=self.targetFmaxMhz,
                        inputOrder='natural', outputOrder='natural', roots=rootOf)
            args.update(self.subArgs)
            if self.folded(t):
                # loadable: the port twiddles come from this design's RAM tables (one modulus, loaded per job);
                # UnrolledNTT's port mode with a run-time static q (UNR request, 2026-11-10 21:10)
                args['twiddleSource'] = 'port'
                args['portAlign'] = self.portAlign
                if gs:
                    args['unified'] = True        # CT forward, GS inverse on the same wiring, DIR per transform
            elif self.loadable:
                args['twiddleSource'] = 'ram'
            if getattr(self, 'loadMod', False):
                args['loadableModuli'] = True
                if getattr(self, 'loadDir', False):
                    args['loadByDirection'] = True
            s = UnrolledNTTScheme(f'{self.name}_p{t}_n{n}', n, **fam, **args)
            if self.loadable:
                # the sub-NTT sizes itself with a sampled prime of the family that has the root of its own
                # length only; `rootOf` asks for the big transform's root of it. Where that prime lacks it, a
                # test prime of this design is used (2026-11-15; points that built before are unchanged)
                try:
                    self.subRoot(t, s.refQ())
                except ValueError:
                    s._refQ = self.moduli[0]
            s.setInputBound(IntType(0, self.qMax - 1))
            s._msPass = t
            cache[key] = s
            if not getattr(self, '_privateSubs', False):
                MultiStepScheme._SUB_CACHE[gkey] = s
            self.subs.append(s)
        # roots: two passes of one size and mode share a scheme; their roots must agree
        for t, s in enumerate(self.subs):
            for q in self.moduli:
                if not self.folded(t) and s.root(q) != self.subRoot(t, q):
                    raise AssertionError(f'pass {t}: sub-NTT root differs for q={q}')

    def subCopies(self, t: int) -> int:
        return self.P // self.sizes[t]

    @property
    def tableM(self) -> int:
        '''Moduli a twiddle table holds: every resident one, or one (loadable).'''
        return 1 if self.loadable else len(self.moduli)

    def valueModuli(self) -> list[int]:
        '''The moduli whose words the tables hold (loadable: the one being loaded, `_loadQ`).'''
        if getattr(self, '_valueQ', None) is not None:       # loadableModuli: the words of one modulus (a slot load)
            return list(self._valueQ)
        return [self._loadQ] if self.loadable else self.moduli

    # --- the twiddle stages ---------------------------------------------------------------------

    def exponent(self, t: int, v: list[int], d: str) -> int:
        '''The twiddle exponent (power of r) in front of pass t at a position with digit values v
        (t = 0: the pre-twist; t = d: the post-twist).'''
        cA, cB, cG = KERNELS[(self.negacyclic, d)]
        P = self.plan
        if t == self.d:
            if self.form == 'folded':
                return (cG * sum(v[u] * P.C[u] for u in range(self.d))) % self.order
            return (cG * P.C[t - 1] * v[t - 1]) % self.order
        if t == 0:
            return (cA * P.R[0] * v[0]) % self.order
        K = sum(v[u] * P.C[u] for u in range(t))
        return (P.R[t] * v[t] * (cA + cB * K) + cG * P.C[t - 1] * v[t - 1]) % self.order

    def portExponent(self, t: int, v: list[int], d: str, sk) -> int:
        '''Folded form: the exponent (power of r) of butterfly (s, k) of pass t's sub-NTT for the transform at a
        position with digit values v (digit t ignored). CT with an input twist a^j merged: stage s, pair j
        takes a^E w_t^(j E), E = s_t / 2^(s+1); here a = r^(R_t (cA + cB K_t)), w_t = r^(cB N / s_t).'''
        cA, cB, cG = KERNELS[(self.negacyclic, d)]
        P = self.plan
        n = self.sizes[t]
        st, k = sk
        mA = self._pairs[t][st][k][0]
        if self.form == 'folded_gs' and d == 'inv':
            # GS with an output twist b^k merged (the cross terms of the kernel taken with this pass's output
            # digit: b = r^(C_t (cG + cB J_t)), J_t the pending input digits; cG: the inverse twist r^-k). The
            # unified sub-NTT runs GS on the CT wiring: lane l is memory index brv(l), hardware stage s pairs
            # memory bit a_t - 1 - s; that stage, pair j, takes (b w_t^j)^E, E = 2^s
            La = _log2(n)
            b = La - 1 - st
            E = n >> (b + 1)
            # gsInv: plain GS sub-NTTs on their own wiring, where a lane is the memory index itself
            j = (mA if self.gsInv else bitReverse(mA, La)) % (1 << b)
            J = sum(v[u] * P.R[u] for u in range(t + 1, self.d))
            return (E * (P.C[t] * (cG + cB * J) + cB * (self.N // n) * j)) % self.order
        E = n >> (st + 1)
        j = mA % (1 << st)
        K = sum(v[u] * P.C[u] for u in range(t))
        return (E * P.R[t] * (cA + cB * K) + cB * (self.N // n) * j * E) % self.order

    def _buildPortTables(self) -> None:
        '''Folded form, per pass t >= 1, per sub-NTT copy, per butterfly port: the exponent, affine in the
        cycle bits (c, g), and the significant bits; `portTables[t]` lists the distinct tables.'''
        P = self.plan
        self._pairs = {}
        self.portTables = {}
        gs = self.form == 'folded_gs' and not self.gsInv      # a table per direction and a DIR choice
        for t in range(0 if self.form == 'folded_gs' else 1, self.d):
            sub = self.subs[t]
            self._pairs[t] = sub.slotPairs()
            ports = sub.portSlots()
            st = next(x for x in P.steps if x['kind'] == 'pass' and x['t'] == t)
            lane, time = st['lane'], st['time']
            groups = self.passGroups(st)
            tabs = {}
            use = []          # per copy, per port: table index
            for g, lanes in enumerate(groups):
                l0 = lanes[0]
                row = []
                for sk in ports:
                    per = {}
                    for dd in self.dirs:
                        c = self.portExponent(t, P.digits(lane, time, 0, l0), dd, sk)
                        gg = [(self.portExponent(t, P.digits(lane, time, 1 << b, l0), dd, sk) - c) % self.order
                              for b in range(P.f)]
                        per[dd] = (c, gg)
                    if gs:
                        # a table per direction (the forward's follow the finished digits, the inverse's the
                        # pending ones: different cycle bits), the port takes the one of the beat's DIR
                        ids = []
                        for dd in self.dirs:
                            sig = [b for b in range(P.f) if per[dd][1][b]]
                            key = (dd, tuple(sig), per[dd][0], tuple(per[dd][1][b] for b in sig))
                            if key not in tabs:
                                tabs[key] = {'id': len(tabs), 'bits': sig, 'per': {dd: per[dd]}, 'dir': dd,
                                             'depth': self.tableM * (1 << len(sig)), 'width': self.W, 'users': 0}
                            tabs[key]['users'] += 1
                            ids.append(tabs[key]['id'])
                        row.append(tuple(ids))
                        continue
                    sig = sorted({b for dd in self.dirs for b in range(P.f) if per[dd][1][b]})
                    key = (tuple(sig), tuple((per[dd][0], tuple(per[dd][1][b] for b in sig)) for dd in self.dirs))
                    if key not in tabs:
                        tabs[key] = {'id': len(tabs), 'bits': sig, 'per': per,
                                     'depth': self.tableM * len(self.dirs) * (1 << len(sig)), 'width': self.W,
                                     'users': 0}
                    tabs[key]['users'] += 1
                    row.append(tabs[key]['id'])
                use.append(row)
            self.portTables[t] = {'tables': sorted(tabs.values(), key=lambda x: x['id']), 'use': use, 'ports': ports}

    def portTableValues(self, t: int, tb: dict) -> list[int]:
        '''Stored words of one port table: {MIDX, DIR, significant bits} addressed (folded_gs: a table of one
        direction, {MIDX, significant bits}).'''
        if self._placeholder(tb['depth']):
            return [0] * tb['depth']
        sub = self.subs[t]
        out = []
        for q in self.valueModuli():
            for dd in ([tb['dir']] if tb.get('dir') else self.dirs):
                c, g = tb['per'][dd]
                for v in range(1 << len(tb['bits'])):
                    e = c + sum(g[b] for i, b in enumerate(tb['bits']) if (v >> i) & 1)
                    out.append(sub.portWord(pow(self.root(q), e % self.order, q), q))
        return out

    def portTableBlock(self, t: int, tb: dict, q: int) -> list[int]:
        '''The words of one port table for modulus q: one slot's block, in address order ({DIR, bits}).'''
        sub = self.subs[t]
        out = []
        for dd in ([tb['dir']] if tb.get('dir') else self.dirs):
            c, g = tb['per'][dd]
            for v in range(1 << len(tb['bits'])):
                e = c + sum(g[b] for i, b in enumerate(tb['bits']) if (v >> i) & 1)
                out.append(sub.portWord(pow(self.root(q), e % self.order, q), q))
        return out

    def passGroups(self, step) -> list[list[int]]:
        n = self.sizes[step['t']]
        pos = step['digitLanes']
        others = [l for l in range(self.plan.p) if l not in pos]
        groups = []
        for g in range(self.P // n):
            base = sum(((g >> i) & 1) << b for i, b in enumerate(others))
            groups.append([base | sum(((r >> i) & 1) << b for i, b in enumerate(pos)) for r in range(n)])
        return groups

    def _layoutBefore(self, t: int):
        '''(lane, time) layout at the twiddle stage in front of pass t (after its transpose).'''
        st = next(s for s in self.plan.steps if s['kind'] == 'pass' and s['t'] == t)
        return st['lane'], st['time']

    def _layoutAfterLast(self):
        return self.plan.outLane, self.plan.outTime

    def laneClasses(self, t: int) -> list[dict]:
        '''Per lane of the stage in front of pass t (or the post bank, t = d): per direction the affine
        exponent (c, g[cycle bits]), the significant cycle bits (union over directions), and whether
        the factor is 1 everywhere.'''
        lane, time = self._layoutBefore(t) if t < self.d else self._layoutAfterLast()
        P = self.plan
        out = []
        for l in range(self.P):
            per = {}
            for dd in self.dirs:
                c = self.exponent(t, P.digits(lane, time, 0, l), dd)
                g = [(self.exponent(t, P.digits(lane, time, 1 << b, l), dd) - c) % self.order for b in range(P.f)]
                per[dd] = (c, g)
            sig = sorted({b for dd in self.dirs for b in range(P.f) if per[dd][1][b]})
            one = all(per[dd][0] == 0 and not any(per[dd][1]) for dd in self.dirs)
            out.append({'lane': l, 'per': per, 'sig': sig, 'one': one})
        # affine check on random points
        import random
        rng = random.Random(t)
        for _ in range(16):
            l, tau = rng.randrange(self.P), rng.randrange(self.F)
            for dd in self.dirs:
                c, g = out[l]['per'][dd]
                e = (c + sum(g[b] for b in range(P.f) if (tau >> b) & 1)) % self.order
                if e != self.exponent(t, P.digits(lane, time, tau, l), dd):
                    raise AssertionError(f'stage {t}: the exponent is not affine in the cycle bits')
        return out

    def treeGroups(self, t: int) -> list[dict] | None:
        '''The power-tree supply of stage t (LIT's per-row power tree): per lane group (the lanes of one
        sub-NTT copy, digit t = j on them) the factor is Y * Z^j with Z = r^(R_t (cA + cB K)) and
        Y = r^(cG C_{t-1} k_{t-1}) independent of j. Returns per group {lanes (by j), z: per dir (c, g),
        y: per dir (c, g), zsig, ysig}, or None when the stage does not have that form (t = 0 or d).'''
        if t in (0, self.d):
            return None
        if not hasattr(self, '_treeCache'):
            self._treeCache = {}
        if t in self._treeCache:
            return self._treeCache[t]
        self._treeCache[t] = r = self._treeGroups(t)
        return r

    def _treeGroups(self, t: int):
        st = next(x for x in self.plan.steps if x['kind'] == 'pass' and x['t'] == t)
        cls = self.stages[t]['classes'] if t in self.stages else self.laneClasses(t)
        groups = self.passGroups(st)
        out = []
        for lanes in groups:
            z, y = {}, {}
            for dd in self.dirs:
                c0, g0 = cls[lanes[0]]['per'][dd]
                c1, g1 = cls[lanes[1]]['per'][dd]
                cz = (c1 - c0) % self.order
                gz = [(b1 - b0) % self.order for b0, b1 in zip(g0, g1)]
                for j, l in enumerate(lanes):
                    cj, gj = cls[l]['per'][dd]
                    if cj != (c0 + j * cz) % self.order or any(gj[b] != (g0[b] + j * gz[b]) % self.order
                                                                for b in range(len(gj))):
                        return None
                z[dd], y[dd] = (cz, gz), (c0, g0)
            zsig = sorted({b for dd in self.dirs for b in range(self.plan.f) if z[dd][1][b]})
            ysig = sorted({b for dd in self.dirs for b in range(self.plan.f) if y[dd][1][b]})
            yone = all(y[dd][0] == 0 for dd in self.dirs) and not ysig
            out.append({'lanes': lanes, 'z': z, 'y': y, 'zsig': zsig, 'ysig': ysig, 'yone': yone})
        return out

    def treeTables(self, t: int, values: bool = True) -> list[dict]:
        '''Tables of the tree supply: per group Z (two-level lo x hi when it has more than one significant
        bit, else one ROM) and Y (ROM; none when Y = 1 everywhere); shared on equal signatures.
        {use: 'zlo'|'zhi'|'z'|'y', bits, depth, width, groups[, values]}.'''
        M, D = self.tableM, len(self.dirs)
        tabs: dict = {}
        for gi, gr in enumerate(self.treeGroups(t)):
            parts = []
            if len(gr['zsig']) > 1:
                lo, hi = self._otfSplit(gr['zsig'])
                parts += [('zlo', lo, gr['z'], True), ('zhi', hi, gr['z'], False)]
            else:
                parts.append(('z', gr['zsig'], gr['z'], True))
            if not gr['yone']:
                parts.append(('y', gr['ysig'], gr['y'], True))
            gr['tab'] = {}
            for use, bits, aff, withC in parts:
                sig = tuple(((aff[dd][0] if withC else 0), tuple(aff[dd][1][b] for b in bits)) for dd in self.dirs)
                key = (use, tuple(bits), sig)
                if key not in tabs:
                    tabs[key] = {'use': use, 'bits': list(bits), 'aff': aff, 'withC': withC,
                                 'depth': M * D * (1 << len(bits)), 'width': self.W, 'groups': []}
                tabs[key]['groups'].append(gi)
                gr['tab'][use] = key
        out = list(tabs.values())
        for i, e in enumerate(out):
            e['id'] = i
        if values:
            for e in out:
                if self._placeholder(e['depth']):
                    e['values'] = [0] * e['depth']
                    continue
                vals = []
                for q in self.valueModuli():
                    fi = self.storedScale(q)
                    for dd in self.dirs:
                        c, g = e['aff'][dd]
                        c = c if e['withC'] else 0
                        for v in range(1 << len(e['bits'])):
                            ex = c + sum(g[b] for i, b in enumerate(e['bits']) if (v >> i) & 1)
                            vals.append(pow(self.root(q), ex % self.order, q) * fi % q)
                e['values'] = vals
        return out

    def treeDepth(self, t: int) -> int:
        return _log2(self.sizes[t])

    #: While the DSE prices points this is a word count: a table with more words gets zeros in place of its
    #: values (its cost depends on its size alone: only LUT ROMs of at most 4 x romStyleMaxDepth words are
    #: priced by their contents). None: every value is computed, as the RTL needs.
    PRICE_VALUES_MAX = None

    def _placeholder(self, words: int) -> bool:
        return MultiStepScheme.PRICE_VALUES_MAX is not None and words > MultiStepScheme.PRICE_VALUES_MAX

    def factor(self, cls: dict, dd: str, sigval: int, q: int, bits=None) -> int:
        '''The factor of a lane class for direction dd at the significant-bit value sigval (bits: which
        of the class's significant bits sigval enumerates; default all).'''
        c, g = cls['per'][dd]
        bits = cls['sig'] if bits is None else bits
        e = c + sum(g[b] for i, b in enumerate(bits) if (sigval >> i) & 1)
        return pow(self.root(q), e % self.order, q)

    def _buildTwiddleStages(self) -> None:
        self.stages = {}        # t -> dict(classes, source, ...)
        ts = list(range(1, self.d))
        if self.twists == 'bank':
            ts = [0] + ts + [self.d]
        if self.form == 'folded':
            ts = [self.d] if (self.negacyclic and 'inv' in self.dirs) else []
            self._buildPortTables()
        elif self.form == 'folded_gs':
            ts = []
            self._buildPortTables()
        for t in ts:
            cls = self.laneClasses(t)
            req = 'rom' if t in (0, self.d) else self.twiddleRequest[t - 1]
            self.stages[t] = {'t': t, 'classes': cls, 'request': req}
        for t, st in self.stages.items():
            st['source'] = self._chooseSource(st)

    # --- multipliers ------------------------------------------------------------------------------

    def _mulArgs(self) -> dict:
        from ...modmult.ReductionScheme import BarrettReduction
        from ...modmult.ModulusFamily import ModulusFamily
        a = self.butterflyArgs
        if a.get('multiplierKind') == 'shoup':
            red, rargs = BarrettReduction, None        # the dataflow's rule: Shoup butterflies, Barrett helpers
        else:
            red, rargs = a.get('reduction', BarrettReduction), a.get('reductionArgs')
        args = dict(multiplier=a.get('multiplier', 'dsp'), reduction=red, reductionArgs=rargs,
                    targetFmaxMhz=self.targetFmaxMhz)
        if a.get('qBackend'):
            args['qBackend'] = a['qBackend']
        if self.loadable:
            args.update(family=self.family, staticModulus=True, inRange=1)
        elif self.perFrame:
            args.update(family=self.family or ModulusFamily.table(self.moduli), staticModulus=False, inRange=1)
        else:
            args['q'] = self.q
        return args

    def multiplier(self, name: str):
        from ...modmult.ModMultScheme import ModularMultiplierScheme
        key = ('mul', name)
        if not hasattr(self, '_mulCache'):
            self._mulCache = {}
        if key not in self._mulCache:
            m = ModularMultiplierScheme(name=name, aIn=IntType(0, self.qMax - 1), bIn=IntType(0, self.qMax - 1),
                                        outputRange='exact', **self._mulArgs())
            if self._dspPlan is not None:
                m.dspBudgets = self._dspPlan.get('tw' if 'gen' not in name else 'gen')
            self._mulCache[key] = m
        return self._mulCache[key]

    def storedScale(self, q: int) -> int:
        '''Stored table words are the factor times this: the inverse of the multiplier's factor (R for the
        Montgomery family, 1 for Barrett). A generator multiplies two stored words, so lo and hi carry it
        once each and the generated twiddle carries it once.'''
        m = self.multiplier(f'{self.name}_twmul')
        return pow(m.reductionFactor(q if (self.perFrame or self.loadable) else None) % q, -1, q)

    def mulLatency(self) -> int:
        return self.multiplier(f'{self.name}_twmul').latency(1)

    def genLatency(self) -> int:
        return self.multiplier(f'{self.name}_twgen').latency(1)

    # --- sources and tables ---------------------------------------------------------------------

    TABLE_LAT = 2          # registered address, registered read (per design: `ramLatency`)

    def _otfSplit(self, sig: list[int]) -> tuple[list[int], list[int]]:
        h = (len(sig) + 1) // 2
        return sig[:h], sig[h:]

    def tablesOf(self, st: dict, source: str, values: bool = True) -> list[dict]:
        '''Distinct tables of a stage: {use, bits, depth, width, lanes[, values]}; depth counts every
        {modulus, dir}. Two lanes share a table when their exponents agree on its bits (then every value
        agrees); `values=False` skips computing the words (the cost model).'''
        M, D = self.tableM, len(self.dirs)
        tabs: dict = {}
        for c in st['classes']:
            if c['one']:
                continue
            if source == 'rom' or len(c['sig']) <= 1:
                parts = [('rom', c['sig'])]
            else:
                lo, hi = self._otfSplit(c['sig'])
                parts = [('lo', lo), ('hi', hi)]
            for use, bits in parts:
                sig = tuple((0 if use == 'hi' else c['per'][dd][0], tuple(c['per'][dd][1][b] for b in bits))
                            for dd in self.dirs)
                key = (use, tuple(bits), sig)
                if key not in tabs:
                    tabs[key] = {'use': use, 'bits': list(bits), 'depth': M * D * (1 << len(bits)),
                                 'width': self.W, 'lanes': [], 'cls': c}
                tabs[key]['lanes'].append(c['lane'])
        out = list(tabs.values())
        if values:
            for e in out:
                c, bits, use = e['cls'], e['bits'], e['use']
                if self._placeholder(e['depth']):
                    e['values'] = [0] * e['depth']
                    continue
                vals = []
                for q in self.valueModuli():
                    fi = self.storedScale(q)
                    for dd in self.dirs:
                        cc = {'per': {dd: (0, c['per'][dd][1])}, 'sig': bits} if use == 'hi' else c
                        for v in range(1 << len(bits)):
                            vals.append(self.factor(cc, dd, v, q, bits) * fi % q)
                e['values'] = vals
        return out

    def stageCost(self, st: dict, source: str) -> dict:
        '''Model cost of one twiddle stage with a source: multipliers, generators, table LUTs / BRAM.'''
        if source == 'tree':
            return self._treeCost(st)
        from ...transpose.MatrixTransposeScheme import bramTiles
        from ..dataflow.UnrolledNTT import UnrolledNTTScheme
        lanes = [c for c in st['classes'] if not c['one']]
        gens = sum(1 for c in lanes if source == 'otf' and len(c['sig']) > 1)
        tabs = self.tablesOf(st, source, values=False)
        lut = bram = uram = 0
        for tb in tabs:
            if self.tableSupply == 'stream':
                continue
            copies = -(-len(tb['lanes']) // self.tableShare)
            if tb['depth'] <= self.romStyleMaxDepth * 4:
                lut += copies * UnrolledNTTScheme.romLuts(tb['depth'], tb['width'])
            else:
                r = memoryTiles(tb['depth'], tb['width'], self.memStyle, self._uramMinDepth)
                bram += copies * r['bram36']
                uram += copies * r['uram']
        ml, md = self.multiplier(f'{self.name}_twmul').areaCost()
        gl, gd = self.multiplier(f'{self.name}_twgen').areaCost() if gens else (0, 0)
        # data delay registers (TABLE_LAT + generator latency) per lane: flops, not LUTs
        return {'mults': len(lanes), 'gens': gens, 'tables': len(tabs),
                'tableWords': sum(t['depth'] for t in tabs),
                'lut': len(lanes) * ml + gens * gl + lut, 'dsp': len(lanes) * md + gens * gd, 'bram36': bram,
                'uram': uram}

    def _treeCost(self, st: dict) -> dict:
        from ..dataflow.UnrolledNTT import UnrolledNTTScheme
        t = st['t']
        grs = self.treeGroups(t)
        if grs is None:
            return {'mults': 0, 'gens': 0, 'lut': float('inf'), 'dsp': 0, 'bram36': 0, 'uram': 0, 'tables': 0,
                    'tableWords': 0}
        n = self.sizes[t]
        lb = self.treeDepth(t)
        # as the RTL builds it: per group the Z generator (two-level), lb - 1 squarings, the w(j) products
        # (n - 1; with Y = 1 the lb products w(2^lv) = Z^(2^lv) are wires) and n data multipliers (with Y = 1
        # lane j = 0 is a plain delay)
        gens = mults = 0
        for gr in grs:
            gens += (n - 1) + (lb - 1) + (1 if len(gr['zsig']) > 1 else 0) - (lb if gr['yone'] else 0)
            mults += n - (1 if gr['yone'] else 0)
        tabs = self.treeTables(t, values=False)
        lut = bram = uram = 0
        for tb in tabs:
            if self.tableSupply == 'stream':
                continue
            copies = -(-len(tb['groups']) // self.tableShare)
            if tb['depth'] <= self.romStyleMaxDepth * 4:
                lut += copies * UnrolledNTTScheme.romLuts(tb['depth'], tb['width'])
            else:
                r = memoryTiles(tb['depth'], tb['width'], self.memStyle, self._uramMinDepth)
                bram += copies * r['bram36']
                uram += copies * r['uram']
        ml, md = self.multiplier(f'{self.name}_twmul').areaCost()
        gl, gd = self.multiplier(f'{self.name}_twgen').areaCost()
        # the data waits for the tree: delay lines of W bits per lane (SRL: W * ceil(D / 32) LUTs)
        dl = self.P * self.W * -(-(self.treeLatency(t) - self.mulLatency()) // 32)
        return {'mults': mults, 'gens': gens, 'tables': len(tabs), 'tableWords': sum(x['depth'] for x in tabs),
                'lut': mults * ml + gens * gl + lut + dl, 'dsp': mults * md + gens * gd, 'bram36': bram, 'uram': uram}

    #: the clock the transposes' register stages are chosen for, over the core's clock
    TRANSPOSE_MARGIN = 1.25

    #: registers in front of every multiplier of the factor tree (2026-11-16): a power Z^(2^b) goes to up to
    #: half the lanes of its group, and each multiplier takes it from a register of its own
    TREE_INREG = 1

    def treeLatency(self, t: int) -> int:
        '''Tables (2), the Z generator when two-level, log2(s_t) multiplier levels, the data multiplier. Every
        tree multiplier has TREE_INREG input register(s).'''
        grs = self.treeGroups(t)
        two = any(len(g['zsig']) > 1 for g in grs)
        G = self.genLatency() + self.TREE_INREG
        return self.TABLE_LAT + (G if two else 0) + self.treeDepth(t) * G + self.mulLatency()

    @staticmethod
    def score(c: dict) -> float:
        '''LUT + 100 DSP + 300 (BRAM36 + 8 URAM): the area metric we report (and TP-NTT's).'''
        return c['lut'] + 100 * c['dsp'] + 300 * (c['bram36'] + URAM_BRAM_EQ * c.get('uram', 0))

    def _chooseSource(self, st: dict) -> str:
        if st['request'] != 'auto':
            return st['request']
        srcs = ('rom', 'otf') + (('tree',) if self.treeGroups(st['t']) is not None else ())
        costs = {s: self.score(self.stageCost(st, s)) for s in srcs}
        st['autoCosts'] = costs
        return min(costs, key=lambda s: (costs[s], s != 'rom'))

    def stageLatency(self, t: int) -> int:
        st = self.stages[t]
        if st['source'] == 'tree':
            return self.treeLatency(t)
        gen = st['source'] == 'otf' and any(len(c['sig']) > 1 for c in st['classes'] if not c['one'])
        return self.TABLE_LAT + (self.genLatency() if gen else 0) + self.mulLatency()

    # --- transposes ------------------------------------------------------------------------------

    def transposeFlags(self, step: dict) -> tuple[bool, ...]:
        import operator_modeling.transpose.MatrixTransposeScheme  # noqa: F401 (versal_arith on the path)
        from lt_transpose_model import lt_flags_for_fmax
        # 2026-11-16: the register stages of a transpose are chosen for the clock times TRANSPOSE_MARGIN. Its paths
        # are mostly wire (barrel shifter to the banks), and at the plain clock they were among the last to fail.
        return lt_flags_for_fmax(1 << step['s'], self.P, self.W, step['timeLo'],
                                 self.targetFmaxMhz * self.TRANSPOSE_MARGIN if self.targetFmaxMhz else self.targetFmaxMhz)

    def transposeLatency(self, step: dict) -> int:
        from lt_transpose_model import lt_bmb_latency
        return lt_bmb_latency(1 << step['s'], step['timeLo'], self.transposeFlags(step))

    def transposeCost(self, step: dict) -> dict:
        from lt_transpose_model import lt_cost
        return lt_cost(self.transposeKind, 1 << step['s'], self.P, self.W, step['timeLo'],
                       self.transposeFlags(step), memStyle=self.memStyle, uramMinDepth=self._uramMinDepth)

    def rtlMemStyle(self, depth: int, lutMax: int) -> str:
        '''The RTL attribute value for a memory of `depth` words (W wide): distributed up to `lutMax`, else
        ultra / block as the model maps it.'''
        if depth <= lutMax:
            return 'distributed'
        return 'ultra' if memoryTiles(depth, self.W, self.memStyle, self._uramMinDepth)['uram'] else 'block'

    def memoryDepths(self) -> list[int]:
        '''Depths of every block memory class the design holds (transposes per lane, twiddle tables).'''
        out = [(1 << st['s']) << st['timeLo'] for st in self.plan.transposes()]
        for t, st in self.stages.items():
            tabs = self.treeTables(t, values=False) if st['source'] == 'tree' else self.tablesOf(st, st['source'], False)
            out += [tb['depth'] for tb in tabs]
        for pt in getattr(self, 'portTables', {}).values():
            out += [tb['depth'] for tb in pt['tables']]
        return sorted(set(out))

    def fitMemories(self) -> dict:
        '''The fit check: with memStyle 'auto' and a BRAM budget, move memories to URAM from the deepest down
        (the largest `uramMinDepth` that fits) until the BRAM36 total is within the budget. Returns {fits,
        uramMinDepth, bram36, uram}.'''
        self._uramMinDepth = None
        r = self.resources()['total']
        if self.bramBudget is None or self.memStyle != 'auto' or r['bram36'] <= self.bramBudget:
            return {'fits': self.bramBudget is None or r['bram36'] <= self.bramBudget, 'uramMinDepth': None,
                    'bram36': r['bram36'], 'uram': r['uram']}
        for dep in sorted(self.memoryDepths(), reverse=True):
            self._uramMinDepth = dep
            r = self.resources()['total']
            if r['bram36'] <= self.bramBudget:
                return {'fits': True, 'uramMinDepth': dep, 'bram36': r['bram36'], 'uram': r['uram']}
        return {'fits': False, 'uramMinDepth': self._uramMinDepth, 'bram36': r['bram36'], 'uram': r['uram']}

    # --- latency -------------------------------------------------------------------------------

    def schedule(self) -> list[dict]:
        '''Every block in order with its offset (cycles after the polynomial's first beat enters) and
        latency.'''
        import operator_modeling.transpose.MatrixTransposeScheme  # noqa: F401 (puts versal_arith on the path)
        out, off = [], 0
        if 0 in self.stages:
            L = self.stageLatency(0)
            out.append({'kind': 'twiddle', 't': 0, 'off': off, 'latency': L})
            off += L
        for s in self.plan.steps:
            if s['kind'] == 'transpose':
                L = self.transposeLatency(s)
                out.append({'kind': 'transpose', 'before': s['before'], 'off': off, 'latency': L, 'step': s})
                off += L
            else:
                t = s['t']
                if t > 0 and t in self.stages:
                    L = self.stageLatency(t)
                    out.append({'kind': 'twiddle', 't': t, 'off': off, 'latency': L})
                    off += L
                L = self.subs[t].latency() + (self.portLatency(t) if self.folded(t) else 0)
                out.append({'kind': 'pass', 't': t, 'off': off, 'latency': L, 'step': s})
                off += L
        if self.d in self.stages:
            L = self.stageLatency(self.d)
            out.append({'kind': 'twiddle', 't': self.d, 'off': off, 'latency': L})
            off += L
        for s in self.plan.outSteps:
            if s['kind'] == 'transpose':
                L = self.transposeLatency(s)
                out.append({'kind': 'transpose', 'before': s['before'], 'off': off, 'latency': L, 'step': s})
                off += L
            else:
                out.append({'kind': 'wire', 'off': off, 'latency': 0, 'step': s})
        if self.crossRegs:
            out = self._withCuts(out)
        return out

    def _withCuts(self, blocks: list[dict]) -> list[dict]:
        '''`crossRegs` register stages in front of the blocks `crossAt` names (block numbers of the schedule
        without cuts; 'all': every block but the first; 'mid': the block whose start is nearest half the latency).'''
        real = [i for i, b in enumerate(blocks) if i > 0 and b['kind'] != 'wire']
        if self.crossAt == 'all':
            cuts = set(real)
        elif self.crossAt == 'mid':
            half = (blocks[-1]['off'] + blocks[-1]['latency']) / 2
            cuts = {min(real, key=lambda i: (abs(blocks[i]['off'] - half), i))} if real else set()
        else:
            cuts = set(int(i) for i in self.crossAt)
            if not cuts <= set(range(1, len(blocks))):
                raise ValueError(f'{self.name}: crossAt {self.crossAt}: block numbers 1..{len(blocks) - 1}')
        out, off = [], 0
        for i, b in enumerate(blocks):
            if i in cuts:
                out.append({'kind': 'cross', 'n': self.crossRegs, 'off': off, 'latency': self.crossRegs})
                off += self.crossRegs
            out.append({**b, 'off': off})
            off += b['latency']
        return out

    #: outReady: cycles the output FIFO adds with out_ready high (write, read register, output register)
    OFIFO_LAT = 3

    def coreLatency(self) -> int:
        '''Cycles of the fixed pipeline (without the output FIFO of `outReady`).'''
        s = self.schedule()
        return s[-1]['off'] + s[-1]['latency']

    def latency(self) -> int:
        '''Cycles from a beat entering to the same-numbered output beat leaving (interval: one beat per
        cycle, F cycles per polynomial); with `outReady`: with out_ready high.'''
        return self.coreLatency() + (self.OFIFO_LAT if self.outReady else 0)

    def outFifoDepth(self) -> int:
        '''Beats the output FIFO of `outReady` holds: a power of two >= pipeline latency + F + 8 (every beat in
        flight has a place, and with out_ready high a new polynomial is always taken).'''
        need = self.coreLatency() + self.F + 8
        if self._outFifoDepth is not None:
            D = int(self._outFifoDepth)
            if D & (D - 1) or D < 2 * self.F:
                raise ValueError(f'{self.name}: outFifoDepth a power of two >= 2 F = {2 * self.F}')
            return D
        return 1 << (need - 1).bit_length()

    def tagBits(self) -> int:
        return ((max(1, (len(self.moduli) - 1).bit_length())) if self.perFrame else 0) + \
            (1 if self.direction == 'both' else 0)

    def readyTwin(self, offers, outReady, depth: int | None = None) -> list[dict]:
        '''Cycle-exact twin of the `outReady` top. `offers`: per polynomial the idle cycles the source waits
        before it offers the first beat (after the previous polynomial's last beat was taken); the source holds
        in_valid until in_ready and then sends the F beats back to back. `outReady`: list of 0/1 per cycle (1 past
        its end). Per cycle m (the state after clock edge m, as the testbench samples it):
        {in_valid, in_ready, acc: (poly, beat) | None, out_valid, out: (poly, beat) | None}.'''
        F, D, Lc = self.F, depth or self.outFifoDepth(), self.coreLatency()
        beats = [(i, tau) for i in range(len(offers)) for tau in range(F)]
        res = []
        in_ready, fc, occ = 1, 0, 0
        cnt, mem, q, q_v, o, o_v = 0, [], None, 0, None, 0
        pipe = {}                       # cycle -> beat leaving the pipeline
        nb, wait = 0, (offers[0] if offers else 0)
        m = 0
        total = len(beats)
        done = 0
        while done < total:
            orr = outReady[m] if m < len(outReady) else 1
            in_valid = 1 if (nb < total and wait == 0) else 0
            acc = in_valid and in_ready
            res.append({'in_valid': in_valid, 'in_ready': in_ready, 'acc': beats[nb] if acc else None,
                        'out_valid': o_v, 'out': o if o_v else None, 'out_ready': orr,
                        'beat': beats[nb] if in_valid else None})
            take = o_v and orr
            wr = m in pipe
            q_take = q_v and ((not o_v) or orr)
            rd = cnt != 0 and ((not q_v) or q_take)
            # next state
            if take:
                done += 1
            if q_take:
                o, o_v = q, 1
            elif orr:
                o_v = 0
            if rd:
                q, q_v = mem.pop(0), 1
            elif q_take:
                q_v = 0
            if wr:
                mem.append(pipe.pop(m))
                if cnt + 1 - (1 if rd else 0) > D:
                    raise AssertionError(f'{self.name}: output FIFO overflow in the twin')
            cnt += (1 if wr else 0) - (1 if rd else 0)
            occ += (1 if acc else 0) - (1 if take else 0)
            if acc:
                pipe[m + Lc] = beats[nb]
                last = fc == F - 1
                fc = 0 if last else fc + 1
                nb += 1
                if last and nb < total:
                    wait = offers[beats[nb][0]]
                mid = not last
            else:
                mid = fc != 0
                if in_valid == 0 and wait > 0 and nb < total:
                    wait -= 1
            in_ready = 1 if (mid or occ + F <= D) else 0
            m += 1
            if m > 10_000_000:
                raise AssertionError('readyTwin: no progress')
        res.append({'in_valid': 0, 'in_ready': in_ready, 'acc': None, 'out_valid': o_v, 'out': None,
                    'out_ready': 1, 'beat': None})
        return res

    def interval(self) -> int:
        return self.F

    # --- closed-form counts and the form choice (FORM_ANALYSIS.md) ----------------------------------------

    def multiplierDsp(self) -> dict:
        '''DSP58 per modular multiplier of each role, from the multiplier models: a general butterfly (the
        deepest of the sub-NTTs'), the inter-pass multiplier, a generator, the inverse twist.'''
        bu = 0
        for sub in self.subs:
            for st in sub.butterflies:
                for b in st:
                    c = b.areaCost()
                    if c:
                        bu = max(bu, c[1])
        mul = self.multiplier(f'{self.name}_twmul').areaCost()[1]
        gen = self.multiplier(f'{self.name}_twgen').areaCost()[1]
        tw = [s.twistMultiplier.areaCost()[1] for s in self.subs if getattr(s, 'twistMultiplier', None) is not None]
        return {'butterflies': bu, 'interPass': mul, 'generators': gen, 'invTwist': tw[0] if tw else mul}

    def formLatency(self, form: str, sources=None) -> int:
        '''Cycles of the pipeline in `form` with these sources, from this scheme's sub-NTT, multiplier and
        transpose latencies (exact for this scheme's own form and sources; for another form an estimate:
        sub-NTTs in port mode and GS passes taken at this scheme's sub-NTT latencies).'''
        own = [self.stages[t]['source'] for t in range(1, self.d) if t in self.stages]
        if form == self.form and (sources is None or (form == 'twist' and list(sources) == own)):
            return self.latency()
        lat = sum(self.subs[t].latency() for t in range(self.d))
        lat += sum(self.transposeLatency(st) for st in self.plan.transposes())
        Lm, Lg = self.mulLatency(), self.genLatency()
        from .FormCounts import layout
        lay = layout(self.N, self.sizes, self.P)
        inv = self.negacyclic and 'inv' in self.dirs
        if form == 'twist':
            for t in range(1, self.d):
                src = sources[t - 1]
                tau = lay[t]['tau']
                if src == 'rom' or (src == 'otf' and tau <= 1):
                    lat += self.TABLE_LAT + Lm
                elif src == 'otf':
                    lat += self.TABLE_LAT + Lg + Lm
                else:
                    lat += self.TABLE_LAT + (Lg if tau > 1 else 0) + lay[t]['a'] * Lg + Lm
        elif form == 'folded_gs':
            lat += self.d * (self.TABLE_LAT + (0 if 'fwd' not in self.dirs else 1))
        else:
            lat += (self.d - 1) * self.TABLE_LAT
            if inv:
                lat += self.TABLE_LAT + Lm
        return lat

    def formCounts(self, form: str | None = None, sources=None) -> dict:
        '''Closed-form counts (FormCounts.formCounts) of this design in `form` ('twist' | 'folded' | 'folded_gs';
        default this scheme's), with DSP (multipliers x DSP per multiplier, by role), memory equivalent
        BRAM36 + 8 URAM, and latency.'''
        from .FormCounts import formCounts as _fc
        form = form or self.form
        if form == 'twist' and sources is None:
            sources = [self.stages[t]['source'] for t in range(1, self.d)] if self.form == 'twist' else ['rom'] * (self.d - 1)
        c = _fc(self.N, self.sizes, self.P, self.tableM, self.dirs, self.negacyclic, form,
                sources if form == 'twist' else None, self.W)
        dpm = self.multiplierDsp()
        m = c['multipliers']
        c['dsp'] = sum(m[k] * dpm[k] for k in ('butterflies', 'interPass', 'invTwist', 'generators'))
        c['memEq'] = c['tiles']['bram36'] + URAM_BRAM_EQ * c['tiles']['uram']
        c['latency'] = self.formLatency(form, sources)
        c['sources'] = list(sources) if form == 'twist' else None
        return c

    def formCandidates(self) -> list[dict]:
        '''twist with a uniform supply (rom, otf, tree) and with this scheme's own supplies, folded, and folded_gs
        where it exists (`valid`: both directions).'''
        out = []
        seen = set()
        own = [self.stages[t]['source'] for t in range(1, self.d)] if self.form == 'twist' else None
        for srcs in ([own] if own else []) + [[x] * (self.d - 1) for x in ('rom', 'otf', 'tree')]:
            key = ('twist', tuple(srcs))
            if key in seen:
                continue
            seen.add(key)
            c = self.formCounts('twist', srcs)
            out.append(dict(form='twist', source=srcs[0] if len(set(srcs)) == 1 else list(srcs), counts=c))
        out.append(dict(form='folded', source=None, counts=self.formCounts('folded')))
        c = self.formCounts('folded_gs')
        if c['valid']:
            out.append(dict(form='folded_gs', source=None, counts=c))
        if self.autoForms is not None:
            out = [x for x in out if x['form'] in self.autoForms]
            if not out:
                raise ValueError(f'{self.name}: no candidate form in autoForms {self.autoForms}')
        return out

    def chooseForm(self, memTol=(16, 0.05)) -> dict:
        '''The user's rule (2026-11-10 20:40; FORM_ANALYSIS.md section 7), over the candidates of
        `formCandidates()`:
          1. memory first: the least BRAM36 + 8 URAM; candidates within max(memTol[0] BRAM36-eq, memTol[1] x the
             smaller memory) of the least count as equal (default 16 tiles or 5 %);
          2. among the equal ones, fewer modular multipliers, then fewer pipeline cycles.
        DSP plays no other part; a DSP percentage (`form='auto', dspFraction=`) is applied afterwards to the chosen
        design through `setDspBudget` (LUT multipliers for the rest) and does not change the pick. Something is
        always picked. Every candidate is buildable (folded_gs since 2026-11-11), so `pickBuildable` is the pick.
        Returns {pick, pickBuildable, candidates, reason, table}.'''
        cands = self.formCandidates()
        tolA, tolR = memTol

        def name(c):
            return c['form'] + (f"/{c['source']}" if c['source'] else '')

        def decide(cs):
            m0 = min(c['counts']['memEq'] for c in cs)
            tol = max(tolA, tolR * m0)
            eq = [c for c in cs if c['counts']['memEq'] - m0 <= tol]
            pick = min(eq, key=lambda c: (c['counts']['multipliers']['total'], c['counts']['latency'],
                                           c['counts']['memEq']))
            why = (f"least memory {m0} BRAM36-eq (tolerance {tol:g}): {', '.join(name(c) for c in eq)}; "
                   f"{name(pick)} has the fewest multipliers ({pick['counts']['multipliers']['total']})"
                   + (', then cycles' if sum(c['counts']['multipliers']['total'] ==
                                             pick['counts']['multipliers']['total'] for c in eq) > 1 else ''))
            return pick, why

        pick, reason = decide(cands)
        build = cands                         # every form is buildable (folded_gs since 2026-11-11)
        pickB, reasonB = decide(build) if len(build) != len(cands) else (pick, reason)
        rows = ['| candidate | multipliers (bu / inter / inv / gen) | DSP | BRAM36 | URAM | BRAM36 + 8 URAM | '
                'twiddle words/prime/dir | latency |', '|---|---|---|---|---|---|---|---|']
        for c in cands:
            k, m = c['counts'], c['counts']['multipliers']
            mark = ' **(pick)**' if c is pick else (' (buildable pick)' if c is pickB else '')
            rows.append(f"| {name(c)}{mark} | {m['total']} ({m['butterflies']} / {m['interPass']} / {m['invTwist']} / "
                        f"{m['generators']}) | {k['dsp']} | {k['tiles']['bram36']} | {k['tiles']['uram']} | {k['memEq']} | "
                        f"{k['twiddleWordsPerPrimePerDir']} | {k['latency']} |")
        return {'pick': {'form': pick['form'], 'source': pick['source']},
                'pickBuildable': {'form': pickB['form'], 'source': pickB['source']},
                'candidates': cands, 'reason': reason, 'reasonBuildable': reasonB, 'table': '\n'.join(rows),
                'memTol': memTol}

    @staticmethod
    def modelArea(tot: dict) -> float:
        '''Area units of a model total, (kLUT + DSP x 4/3 + BRAM36 + 8 URAM) / 5: the reported unit without its
        register term (the model has no register count).'''
        return (tot['lut'] / 1000 + tot['dsp'] * 4 / 3 + tot['bram36'] + URAM_BRAM_EQ * tot.get('uram', 0)) / 5

    @staticmethod
    def chooseFormBudget(args: dict, fraction=None, total=None, areaTol: float = 0.03) -> dict:
        '''The user's rule with a DSP budget (2026-11-11), over the buildable candidates of `formCandidates()`:
          1. one DSP count for all: `total`, or `fraction` of the full-DSP count of the leanest candidate (floor);
          2. every candidate is built (model) with that count, LUT multipliers for the rest (`setDspBudget`);
          3. the least model area (`modelArea`) wins; candidates within `areaTol` of it count as equal, and among
             those the least memory, then the fewest multipliers, then the fewest cycles.
        `args`: the constructor arguments of the design. Returns the keys of `chooseForm` plus budget, leanDsp.'''
        base = {k: v for k, v in args.items() if k not in ('dspFraction', 'dspTotal')}
        ref = MultiStepScheme(**{**base, 'name': f"{args['name']}_ref", 'form': 'twist'})
        cands = ref.formCandidates()

        def name(c):
            return c['form'] + (f"/{c['source']}" if c['source'] else '')

        for c in cands:
            kw = {**base, 'name': f"{args['name']}_{name(c).replace('/', '_')}", 'form': c['form']}
            if c['source']:
                kw['twiddleSource'] = c['source']
            c['scheme'] = MultiStepScheme(**kw)
            c['full'] = c['scheme'].resources()['total']
        lean = min(c['full']['dsp'] for c in cands)
        from ...core import dspbudget as DB
        budget = DB.resolveTotal(lean, fraction, total)
        for c in cands:
            c['scheme'].setDspBudget(total=budget)
            c['tot'] = c['scheme'].resources()['total']
            c['area'] = MultiStepScheme.modelArea(c['tot'])
            c['latencyBudget'] = c['scheme'].latency()
            del c['scheme']
        a0 = min(c['area'] for c in cands)
        eq = [c for c in cands if c['area'] <= a0 * (1 + areaTol)]
        pick = min(eq, key=lambda c: (c['counts']['memEq'], c['counts']['multipliers']['total'], c['latencyBudget']))
        reason = (f"DSP budget {budget} ({'given' if total is not None else f'{fraction:g} x {lean}, the leanest form'}); "
                  f"least model area {a0:.0f} au (tolerance {areaTol:g}): {', '.join(name(c) for c in eq)}"
                  + (f"; {name(pick)} has the least memory, then multipliers, then cycles" if len(eq) > 1 else ''))
        rows = ['| candidate | multipliers | full DSP | DSP at budget | LUT at budget | BRAM36 | URAM | model area (au, '
                'no FF) | latency |', '|---|---|---|---|---|---|---|---|---|']
        for c in cands:
            t = c['tot']
            rows.append(f"| {name(c)}{' **(pick)**' if c is pick else ''} | {c['counts']['multipliers']['total']} | "
                        f"{c['full']['dsp']} | {t['dsp']} | {t['lut']} | {t['bram36']} | {t.get('uram', 0)} | "
                        f"{c['area']:.0f} | {c['latencyBudget']} |")
        p = {'form': pick['form'], 'source': pick['source']}
        return {'pick': p, 'pickBuildable': p, 'candidates': cands, 'reason': reason, 'reasonBuildable': reason,
                'table': '\n'.join(rows), 'budget': budget, 'leanDsp': lean, 'areaTol': areaTol, 'rule': 'area'}

    # the scheme surface the registry asks for: bounds are [0, q) in and out (exact multipliers, exact
    # sub-NTT outputs); values through the stream model
    def propagateBound(self) -> IntType:
        return IntType(0, self.qMax - 1)

    def propagateValue(self, xs, dirs=None, qs=None):
        return self.transformNatural(xs, dirs, qs)

    # --- cost ------------------------------------------------------------------------------------

    def resources(self) -> dict:
        import operator_modeling.transpose.MatrixTransposeScheme  # noqa: F401
        parts = {}
        tot = {'lut': 0, 'dsp': 0, 'bram36': 0.0, 'uram': 0}
        for t, sub in enumerate(self.subs):
            r = sub.resources()
            k = self.subCopies(t)
            parts[f'pass{t}'] = {'lut': r['lut'] * k, 'dsp': r['dsp'] * k, 'bram36': r.get('bram36', 0) * k,
                                 'copies': k, 'n': self.sizes[t], 'latency': sub.latency()}
        for s in self.plan.transposes():
            c = self.transposeCost(s)
            parts[f"T{s['before']}"] = c
        for t, st in self.stages.items():
            c = self.stageCost(st, st['source'])
            c['source'] = st['source']
            parts[f'tw{t}'] = c
        if self.form in ('folded', 'folded_gs'):
            from ..dataflow.UnrolledNTT import UnrolledNTTScheme
            for t, pt in self.portTables.items():
                # folded_gs: per distinct (forward, inverse) table pair one registered W-bit choice by DIR
                lut = self.W * len({u for row in pt['use'] for u in row if isinstance(u, tuple)})
                bram = uram = 0
                words = 0
                for tb in pt['tables']:
                    if self.tableSupply == 'stream':
                        words += tb['depth']
                        continue
                    copies = -(-tb['users'] // self.tableShare)
                    words += tb['depth']
                    if tb['depth'] <= self.romStyleMaxDepth * 4:
                        lut += copies * UnrolledNTTScheme.romLuts(tb['depth'], tb['width'])
                    else:
                        r = memoryTiles(tb['depth'], tb['width'], self.memStyle, self._uramMinDepth)
                        bram += copies * r['bram36']
                        uram += copies * r['uram']
                parts[f'ports{t}'] = {'lut': lut, 'dsp': 0, 'bram36': bram, 'uram': uram, 'tables': len(pt['tables']),
                                      'tableWords': words}
        if self.outReady:
            D = self.outFifoDepth()
            mt = memoryTiles(D, self.P * self.W + self.tagBits(), self.memStyle, self._uramMinDepth)
            # control: two pointers, two counters (log2 D + 1 bits each), the compare and the handshake
            parts['ofifo'] = {'lut': 6 * (_log2(D) + 1) + 8, 'dsp': 0, 'bram36': mt['bram36'], 'uram': mt['uram'],
                              'depth': D, 'width': self.P * self.W + self.tagBits()}
        for v in parts.values():
            for k in tot:
                tot[k] += v.get(k, 0)
        tot['score'] = self.score(tot)
        return {'total': tot, 'parts': parts}

    def area(self, pipelineStages: int = 1) -> dict:
        '''Predicted area of the RTL without a build: `lut`, `ff`, `dsp`, `bram36`, `uram`, `au` (area units),
        `byClass`, `byBlock` (`MultiStepArea`: the generator's own part list, priced part by part). `resources()`
        above keeps its numbers (the DSP budget and the automatic form choice rank with them).'''
        from .MultiStepArea import area
        return area(self, pipelineStages)

    def foldedEstimate(self, resident: int | None = None) -> dict:
        '''Form 2, TP-NTT's "folded" multi-dimensional NTT on the same passes and transposes (estimate, no
        RTL): no inter-pass multipliers; every block after the first runs log2(s_t) consecutive stages of the
        big NTT with that block's time-varying stage twiddles, about N words per prime in all (TP-NTT eq. 10-12,
        forward and inverse unified), from RAM. `resident`: primes held on chip (default all M, i.e. k = 1 with
        no reload; TP-NTT itself holds one and streams the next prime's table from HBM per batch).
        Butterflies are priced as ours (the same BU type with a table-fed twiddle).'''
        r = self.resources()
        tot = {'lut': 0, 'dsp': 0, 'bram36': 0.0, 'uram': 0}
        for k, v in r['parts'].items():
            if k.startswith('tw'):
                continue
            for a in tot:
                tot[a] += v.get(a, 0)
        M = len(self.moduli) if resident is None else resident
        words = M * self.N
        # one RAM per block lane group: the words spread over P lanes (one read port per lane)
        mem = memoryTiles(-(-words // self.P), self.W, self.memStyle, self._uramMinDepth)
        tot['bram36'] += mem['bram36'] * self.P
        tot['uram'] += mem['uram'] * self.P
        tot['twiddleWords'] = words
        tot['score'] = self.score(tot)
        return tot

    def multiplierCount(self) -> dict:
        bu = sum(self.subCopies(t) * (self.sizes[t] // 2) * _log2(self.sizes[t]) for t in range(self.d))
        tw = sum(len([c for c in st['classes'] if not c['one']]) for st in self.stages.values())
        gen = sum(self.stageCost(st, st['source'])['gens'] for st in self.stages.values())
        twist = sum(s.lanes * self.subCopies(t) for t, s in enumerate(self.subs)
                    if getattr(s, 'twistMultiplier', None) is not None)
        return {'butterflies': bu, 'twiddle': tw, 'generators': gen, 'subTwist': twist}

    # --- one DSP budget over every multiplier -----------------------------------------------------

    def setDspBudget(self, fraction=None, total=None, weight=None):
        '''One top-down split over the sub-NTTs' blocks, the twiddle multipliers and the generators.'''
        from ...core import dspbudget as DB
        self._dspPlan = None
        self._mulCache = {}
        if not getattr(self, '_privateSubs', False):
            self._privateSubs = True         # a budget changes the sub-NTT schemes: never share them
            self._buildSubs()
        blocks = []
        owners = []
        seen = {}
        for t, sub in enumerate(self.subs):
            seen[id(sub)] = seen.get(id(sub), 0) + self.subCopies(t)
        done = set()
        for t, sub in enumerate(self.subs):
            if id(sub) in done:
                continue
            done.add(id(sub))
            bs = sub.dspBlocks(count=seen[id(sub)], weight=weight, prefix=sub.name)
            blocks += bs
            owners.append(sub)
        mc = self.multiplierCount()
        if mc['twiddle']:
            b = DB.blockOf('inter-pass twiddle multiplier', self.multiplier(f'{self.name}_twmul'), mc['twiddle'], weight)
            b.key, b.owner = 'tw', self
            blocks.append(b)
        if mc['generators']:
            b = DB.blockOf('twiddle generator', self.multiplier(f'{self.name}_twgen'), mc['generators'], weight)
            b.key, b.owner = 'gen', self
            blocks.append(b)
        pure = sum(b.count * b.pureDsp for b in blocks)
        root = DB.Budget(self.name, 1, pure, sum(b.count * b.weight for b in blocks), children=blocks)
        root.budget = DB.resolveTotal(pure, fraction, total)
        DB.splitTypes(root.budget, blocks)
        for b in blocks:
            DB.splitLeaves(b)
        for o in owners:
            o.applyDspPlan({b.key: DB.budgetsOf(b) for b in blocks if b.owner is o})
        self._dspPlan = {b.key: DB.budgetsOf(b) for b in blocks if b.owner is self}
        self._mulCache = {}
        self.dspTree = root
        if hasattr(self, '_ramLatencyGiven') and hasattr(self, 'portTables'):
            self._settleTableLatency()
        return root

    # --- the stream model (bit exact, beat by beat) ------------------------------------------------

    def _defaultDir(self) -> str:
        return 'inv' if self.direction == 'inverse' else 'fwd'

    def inputFrame(self, x: list[int]) -> list[list[int]]:
        '''Natural-order polynomial -> frame[tau][lane].'''
        P = self.plan
        return [[x[P.inputIndex(tau, l)] for l in range(self.P)] for tau in range(self.F)]

    def outputNatural(self, frame) -> list[int]:
        P = self.plan
        y = [0] * self.N
        for tau in range(self.F):
            for l in range(self.P):
                y[P.outputIndex(tau, l)] = frame[tau][l]
        return y

    def _applyTwiddle(self, t: int, frames, dirs, qs):
        st = self.stages[t]
        out = []
        for fr, dd, q in zip(frames, dirs, qs):
            nf = []
            for tau in range(self.F):
                row = []
                for l, c in enumerate(st['classes']):
                    if c['one']:
                        row.append(fr[tau][l])
                        continue
                    sv = sum(((tau >> b) & 1) << i for i, b in enumerate(c['sig']))
                    row.append(fr[tau][l] * self.factor(c, dd, sv, q) % q)
                nf.append(row)
            out.append(nf)
        return out

    def _transpose(self, step, frames):
        S, j0 = 1 << step['s'], step['timeLo']
        lb = step['laneBits']
        out = []
        for fr in frames:
            nf = [[None] * self.P for _ in range(self.F)]
            for tau in range(self.F):
                r = (tau >> j0) & (S - 1)
                for l in range(self.P):
                    u = sum(((l >> b) & 1) << i for i, b in enumerate(lb))
                    l2 = l
                    for i, b in enumerate(lb):
                        l2 = (l2 & ~(1 << b)) | (((r >> i) & 1) << b)
                    tau2 = (tau & ~((S - 1) << j0)) | (u << j0)
                    nf[tau2][l2] = fr[tau][l]
            out.append(nf)
        return out

    def _wire(self, step, frames):
        src = step['src']
        out = []
        for fr in frames:
            nf = [[None] * self.P for _ in range(self.F)]
            for tau in range(self.F):
                for l in range(self.P):
                    l2 = sum(((l >> x) & 1) << b for b, x in enumerate(src))
                    nf[tau][l2] = fr[tau][l]
            out.append(nf)
        return out

    def _pass(self, step, frames, dirs, qs):
        t = step['t']
        sub = self.subs[t]
        pos = step['digitLanes']
        n = self.sizes[t]
        others = [l for l in range(self.plan.p) if l not in pos]
        groups = []
        for g in range(self.P // n):
            base = sum(((g >> i) & 1) << b for i, b in enumerate(others))
            groups.append([base | sum(((r >> i) & 1) << b for i, b in enumerate(pos)) for r in range(n)])
        xs, ds, qq = [], [], []
        for fr, dd, q in zip(frames, dirs, qs):
            for tau in range(self.F):
                for lanes in groups:
                    xs.append([fr[tau][l] for l in lanes])
                    ds.append(dd)
                    qq.append(q)
        if self.folded(t):
            lane, time = step['lane'], step['time']
            tws = []
            for fr, dd, q in zip(frames, dirs, qs):
                for tau in range(self.F):
                    for lanes in groups:
                        v = self.plan.digits(lane, time, tau, lanes[0])
                        tws.append({sk: pow(self.root(q), self.portExponent(t, v, dd, sk), q)
                                    for sk in self.portTables[t]['ports']})
            ys = sub.transformPort(xs, tws, ds, qq)
        else:
            ys = sub.transformNatural(xs, ds, qq)
        out, i = [], 0
        for fr in frames:
            nf = []
            for tau in range(self.F):
                row = [None] * self.P
                for lanes in groups:
                    for r, l in enumerate(lanes):
                        row[l] = ys[i][r]
                    i += 1
                nf.append(row)
            out.append(nf)
        return out

    def transformFrames(self, frames, dirs=None, qs=None, stop: int | None = None):
        '''frames: polynomials as frame[tau][lane] (input layout); returns the output frames. `stop`: only the
        first `stop` blocks of `schedule()` (a debugging tap).'''
        T = len(frames)
        dirs = list(dirs) if isinstance(dirs, (list, tuple)) else [dirs or self._defaultDir()] * T
        qs = list(qs) if isinstance(qs, (list, tuple)) else [qs or self.moduli[0]] * T
        cur = [list(map(list, f)) for f in frames]
        ops = []
        if 0 in self.stages:
            ops.append(lambda c: self._applyTwiddle(0, c, dirs, qs))
        for s in self.plan.steps:
            if s['kind'] == 'transpose':
                ops.append(lambda c, s=s: self._transpose(s, c))
            else:
                if s['t'] > 0 and s['t'] in self.stages:
                    ops.append(lambda c, s=s: self._applyTwiddle(s['t'], c, dirs, qs))
                ops.append(lambda c, s=s: self._pass(s, c, dirs, qs))
        if self.d in self.stages:
            ops.append(lambda c: self._applyTwiddle(self.d, c, dirs, qs))
        for s in self.plan.outSteps:
            if s['kind'] == 'transpose':
                ops.append(lambda c, s=s: self._transpose(s, c))
            else:
                ops.append(lambda c, s=s: self._wire(s, c))
        if stop is not None and self.crossRegs:
            raise ValueError(f'{self.name}: stop= (a debugging tap) with crossRegs: not supported')
        for op in ops[:stop]:
            cur = op(cur)
        return cur

    def transformNatural(self, xs, dirs=None, qs=None):
        frames = [self.inputFrame(x) for x in xs]
        return [self.outputNatural(f) for f in self.transformFrames(frames, dirs, qs)]

    def reference(self, x, d, q, fast=True):
        fn = referenceFast if fast else referenceDirect
        return fn(x, q, self.root(q), self.negacyclic, d)


# ---------------------------------------------------------------------------------------------------
# Choosing the factorisation by the cost model
# ---------------------------------------------------------------------------------------------------

def factorizations(N: int, P: int, maxD: int = 4, minSize: int = 4) -> list[list[int]]:
    '''Every pass order of sub-NTT sizes (powers of two in [minSize, P]) multiplying to N, d = 2..maxD.'''
    import itertools
    m, p, lo = _log2(N), _log2(P), _log2(minSize)
    out = []
    for d in range(2, maxD + 1):
        for a in itertools.product(range(lo, p + 1), repeat=d):
            if sum(a) == m:
                out.append([1 << x for x in a])
    return out


def chooseFactorization(name: str, N: int, lanes: int, maxD: int = 4, key: str = 'score', **kw):
    '''Build every factorisation (model only) and return (best scheme, table of (sizes, score, latency)), the
    best by `key` ('score' = LUT + 100 DSP + 300 (BRAM36 + 8 URAM), or 'latency'); ties to fewer passes.'''
    rows = []
    best = None
    for sizes in factorizations(N, lanes, maxD):
        s = MultiStepScheme(name, N, sizes, lanes, **kw)
        sc = s.resources()['total']['score']
        lat = s.latency()
        rows.append((sizes, sc, lat))
        k = (sc if key == 'score' else lat, len(sizes))
        if best is None or k < best[0]:
            best = (k, s)
    return best[1], sorted(rows, key=lambda r: r[1])
