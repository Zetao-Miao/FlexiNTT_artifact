'''Routability across SLRs for the iterative NTT's memory organisations (IterativeNTTScheme.memOrgReport).

The V80 (xcv80-lsva4737-2MHP-e-S) has three SLRs. Their resources, read from Vivado 2025.1
(`get_sites -of_objects [get_slrs]`, ntt_hw/experiments/iterative/constgeo/partdata/):

    SLR0  DSP58 3,984  LUT 900,224  RAMB36 1,341  URAM 677
    SLR1  DSP58 3,456  LUT 820,224  RAMB36 1,200  URAM 624
    SLR2  DSP58 3,408  LUT 853,760  RAMB36 1,200  URAM 624

Super long lines (SLLs) between two neighbouring SLRs: 18,870 (place_design's own count, row Ib, 2026-11-08:
"39052 SLLs required between SLR0 and SLR1, but there are only 18870"); route_design gave up on row Ic at
17,688 needed crossings against a threshold of 16,983 ("global congestion level 7"). We take 16,983 as the
usable limit.

The estimate. A design that needs k SLRs (its resources at `UTIL` of each, the smallest contiguous set) is
cut at k - 1 boundaries; the worst one separates a fraction a = 1/k of it from the rest. The memory <->
butterfly network is a hypergraph: nodes are the butterflies, the bank groups (bank k of every set) and the
I/O lanes; nets are the W-bit buses (a bank's read data, a butterfly output, an input lane), each with its
sinks. Its minimum a-balanced cut (Fiduccia-Mattheyses from several starts, in buses) times W is what any
placement must at least carry across that boundary; Vivado's placement does worse. The factor between the two
(`CAL`, per organisation) is fitted on the four OOC runs at I2 / I3 (`OBSERVED`): crossing estimate =
CAL[org] x W x mincut, compared with Vivado's "Estimated SLL Demand" per cut. A design fits when the estimate is
at most 0.9 x SLL_LIMIT (18,000); between 0.7 x and 1.1 x the limit the estimate is called unsure (the
caller's fallback rule applies). Vivado placed both I2 / I3 organisations over all three SLRs although the
resources need two; the span is a lower bound.
'''
from __future__ import annotations

import heapq
import random

V80_SLRS = (dict(name='SLR0', dsp=3984, lut=900224, bram=1341, uram=677),
            dict(name='SLR1', dsp=3456, lut=820224, bram=1200, uram=624),
            dict(name='SLR2', dsp=3408, lut=853760, bram=1200, uram=624))
SLL_AVAILABLE = 18870
#: routable SLL demand per SLR cut (Vivado's "Estimated SLL Demand", north + south, at SLL assignment), from four
#: runs: constant geometry routed at 17,549 (I2) and 16,423 (I3); in place failed routing at 18,593 (I3,
#: congestion 7) and placement at 39,052 (I2). The limit sits between 17.5k and 18.6k; 18,000 is taken.
SLL_LIMIT = 18000
UTIL = 0.85
#: placement / min-cut, fitted on the in-place rows Ib (39,052 required) and Ic (17,688): see CALIBRATION
CAL = None
CALIBRATION = {}


def slrSpan(res: dict) -> int:
    '''The fewest contiguous SLRs that hold the resources at UTIL.'''
    for k in (1, 2, 3):
        best = False
        for i in range(0, 4 - k):
            grp = V80_SLRS[i:i + k]
            if all(res.get(r, 0) <= UTIL * sum(s[r] for s in grp) for r in ('dsp', 'lut', 'bram', 'uram')):
                best = True
        if best:
            return k
    return 4                                    # does not fit the device


def _fm(nw: list, nets: list, a: float, tol: float, init: list, passes: int = 8) -> tuple[int, list]:
    '''Fiduccia-Mattheyses bipartition: side 0 holds about a of the node weight (within tol). nets: (weight,
    pins). Returns (cut weight, sides).'''
    n = len(nw)
    tot = sum(nw)
    lo, hi = (a - tol) * tot, (a + tol) * tot
    side = list(init)
    nn = [[] for _ in range(n)]
    for e, (_, pins) in enumerate(nets):
        for v in pins:
            nn[v].append(e)
    w0 = sum(nw[v] for v in range(n) if side[v] == 0)

    def counts():
        c = [[0, 0] for _ in nets]
        for e, (_, pins) in enumerate(nets):
            for v in pins:
                c[e][side[v]] += 1
        return c
    cut = lambda c: sum(nets[e][0] for e in range(len(nets)) if c[e][0] and c[e][1])
    cnt = counts()
    cur = cut(cnt)
    for _ in range(passes):
        gain = [0] * n
        for v in range(n):
            g = 0
            sv = side[v]
            for e in nn[v]:
                if cnt[e][sv] == 1:
                    g += nets[e][0]
                if cnt[e][1 - sv] == 0:
                    g -= nets[e][0]
            gain[v] = g
        locked = [False] * n
        moves, best, bestAt, c0, ww = [], cur, 0, cur, w0
        heap = [(-gain[v], v) for v in range(n)]
        heapq.heapify(heap)
        for step in range(n):
            cand, held = None, []
            while heap:
                g, v = heapq.heappop(heap)
                if locked[v] or -g != gain[v]:
                    continue
                nw0 = ww - nw[v] if side[v] == 0 else ww + nw[v]
                if lo <= nw0 <= hi:
                    cand = v
                    break
                held.append((g, v))
                if len(held) > 64:
                    break
            for x in held:
                heapq.heappush(heap, x)
            if cand is None:
                break
            v = cand
            locked[v] = True
            sv = side[v]
            c0 -= gain[v]
            ww = ww - nw[v] if sv == 0 else ww + nw[v]
            # gain updates (standard FM, before and after the move)
            for e in nn[v]:
                we, pins = nets[e]
                F, T_ = cnt[e][sv], cnt[e][1 - sv]
                if T_ == 0:
                    for u in pins:
                        if not locked[u]:
                            gain[u] += we
                            heapq.heappush(heap, (-gain[u], u))
                elif T_ == 1:
                    for u in pins:
                        if not locked[u] and side[u] == 1 - sv:
                            gain[u] -= we
                            heapq.heappush(heap, (-gain[u], u))
                cnt[e][sv] -= 1
                cnt[e][1 - sv] += 1
                F -= 1
                T_ += 1
                if F == 0:
                    for u in pins:
                        if not locked[u]:
                            gain[u] -= we
                            heapq.heappush(heap, (-gain[u], u))
                elif F == 1:
                    for u in pins:
                        if not locked[u] and side[u] == sv:
                            gain[u] += we
                            heapq.heappush(heap, (-gain[u], u))
            side[v] = 1 - sv
            moves.append(v)
            if c0 < best:
                best, bestAt = c0, len(moves)
        for v in moves[bestAt:]:
            side[v] = 1 - side[v]
        cnt = counts()
        w0 = sum(nw[v] for v in range(n) if side[v] == 0)
        nc = cut(cnt)
        if nc >= cur:
            cur = nc
            break
        cur = nc
    return cur, side


_CACHE = {}


def minCut(key, nw: list, nets: list, a: float, starts: list, seeds: int = 3) -> int:
    '''The smallest FM cut over the structured starts and `seeds` random ones (cached under key).'''
    if key in _CACHE:
        return _CACHE[key]
    best = None
    n = len(nw)
    inits = list(starts)
    tot = sum(nw)
    for sd in range(seeds):
        rng = random.Random(sd)
        order = list(range(n))
        rng.shuffle(order)
        side, acc = [1] * n, 0
        for v in order:
            if acc + nw[v] <= a * tot:
                side[v] = 0
                acc += nw[v]
        inits.append(side)
    for init in inits:
        c, _ = _fm(nw, nets, a, 0.04, init)
        best = c if best is None else min(best, c)
    _CACHE[key] = best
    return best


#: (organisation, row, n, B, io, W, Vivado's SLL demand at the worst cut) of the four OOC runs at I2 / I3
OBSERVED = (('inplace', 'Ib_n8192_q36b_B512', 8192, 512, 64, 36, 39052),        # place_design: required
            ('inplace', 'Ic_n16384_q54b_B256', 16384, 256, 64, 54, 18593),      # [1-2] demand, route failed
            ('constgeo', 'Ib_n8192_q36b_B512_auto', 8192, 512, 64, 36, 17549),  # [0-1] demand, routed
            ('constgeo', 'Ic_n16384_q54b_B256_auto', 16384, 256, 64, 54, 16423))  # [1-2] demand, routed


def calibration(org: str = 'inplace') -> float:
    """CAL per organisation: the mean of observed / (W x min cut) over OBSERVED (a = 1/2; computed once). The
    placer is close to the min cut for the in-place mesh (0.80, 1.28) but far from it for constant geometry's
    shuffle (2.54, 3.80): it does not find the shuffle's low cut, so the factors differ."""
    global CAL
    if CAL is None:
        from .IterativeNTTScheme import IterativeNTTScheme
        rat = {}
        for o, row, n, B, io, W, obs in OBSERVED:
            s = IterativeNTTScheme(f'cal_{row}', n, B, q=65537, ioLanes=io, memOrg=o)
            nw, nets, home, a = s.meshHypergraph()
            cut = minCut((o, n, B, io, 0.5), nw, nets, 0.5, s.meshStarts(home, 0.5))
            CALIBRATION[row] = dict(org=o, cutBuses=cut, W=W, observed=obs, ratio=obs / (W * cut))
            rat.setdefault(o, []).append(obs / (W * cut))
        CAL = {o: sum(v) / len(v) for o, v in rat.items()}
    return CAL[org]


MUXCOST_CSV = 'work/iterative/muxcost/results.csv'


def muxModel():
    """(lut(k, W) or None, source): the measured N:1 x W multiplexer cost when MUXCOST_CSV exists (LUTs per bit
    interpolated over N, linear in W), else None (the scheme's LUT6 formula)."""
    import csv
    import os
    if not os.path.isfile(MUXCOST_CSV):
        return None, 'LUT6 formula ceil((k-1)/3) per bit (muxcost/results.csv not found)'
    rows = list(csv.DictReader(open(MUXCOST_CSV)))
    if not rows:
        return None, 'LUT6 formula (muxcost/results.csv empty)'
    keys = {k.lower().strip(): k for k in rows[0]}
    kn = next((keys[k] for k in keys if k in ('n', 'inputs', 'ways', 'k')), None)
    kw = next((keys[k] for k in keys if k in ('w', 'width', 'bits')), None)
    kl = next((keys[k] for k in keys if k.startswith('lut')), None)
    if not (kn and kw and kl):
        return None, f'LUT6 formula (muxcost/results.csv columns {list(rows[0])} not understood)'
    per = {}
    for r in rows:
        try:
            N, W, L = int(float(r[kn])), int(float(r[kw])), float(r[kl])
        except (ValueError, TypeError):
            continue
        per.setdefault(N, []).append(L / W)
    pts = sorted((N, sum(v) / len(v)) for N, v in per.items())
    if not pts:
        return None, 'LUT6 formula (muxcost/results.csv has no rows)'

    def lut(k, W):
        if k <= 1:
            return 0
        for (n0, y0), (n1, y1) in zip(pts, pts[1:]):
            if n0 <= k <= n1:
                return W * (y0 + (y1 - y0) * (k - n0) / (n1 - n0))
        if k < pts[0][0]:
            return W * pts[0][1] * (k - 1) / max(1, pts[0][0] - 1)
        n0, y0 = pts[-1]
        return W * y0 * (k - 1) / max(1, n0 - 1)
    return lut, f'measured ({MUXCOST_CSV}, {len(pts)} sizes)'
