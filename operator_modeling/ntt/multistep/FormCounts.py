'''Closed-form counts of the multi-step NTT forms (derivations: ntt_hw/experiments/fourstep/FORM_ANALYSIS.md).

    formCounts(N, sizes, P, M, dirs, negacyclic, form, sources, W) -> dict

Everything is a function of N, the pass sizes s_1..s_d (pass order), P, M, the direction set, cyclic or
negacyclic, the form and the twiddle source per inter-pass stage, through the layout integers of the default
input layout ('block') and swap policy ('recent'), each itself in closed form:

    a_t = log2 s_t, A_t = a_1 + .. + a_t, C_t = 2^(A_{t-1}), m = log2 N, p = log2 P, f = m - p
    l0_t  = clamp(p - A_{t-1}, 0, a_t)       digit-t bits on the lanes in the input layout
    pi_t  = max(0, p - A_t)                  lane bits of pending digits (> t) at pass t
    lam_t = p - a_t - pi_t                   lane bits of finished digits (< t) at pass t
    tau_t = A_{t-1} - lam_t                  cycle bits of finished digits at pass t
    n_t   = a_t - l0_t                       bits the transpose in front of pass t swaps (0: no transpose)
    kap_t = min(n_t, a_{t-1})                cycle bits of digit t-1 at pass t ('recent' swaps it out first)

No enumeration of lanes, tables or butterflies is used; `runFormCounts.py` checks every count against
`MultiStepScheme` (which enumerates), over the TP-NTT rows and a sweep.

Forms: 'twist' (default: merged end twists, inter-pass multipliers), 'folded' (TP-NTT: stage twiddles in every
butterfly of passes 2..d, the inverse twist r^-k as one P-lane output stage), 'folded_gs' (TP-NTT's inverse too,
built since 2026-11-11: every pass, the first included, is a unified CT/GS sub-NTT with twiddle ports; the
forward runs CT with the input twist of the finished digits merged, the inverse GS on the same passes in the same
order with the output twist of the pending digits merged. No inter-pass multiplier, no output stage, every
butterfly general; a port table per direction: the forward's over the tau_t cycle bits of the finished digits,
the inverse's over the sig_t = m - A_t - pi_t cycle bits of the pending ones. Any pass sizes; both directions).
'''
from __future__ import annotations


def _lg(x: int) -> int:
    b = x.bit_length() - 1
    assert (1 << b) == x, x
    return b


KERNELS = {(True, 'fwd'): (1, 2, 0), (True, 'inv'): (0, -2, -1), (False, 'fwd'): (0, 1, 0), (False, 'inv'): (0, -1, 0)}


def _constStage(N, L, t, dirs, negacyclic):
    '''A stage with tau_t = 0 (the first t digits fit the lanes, A_t <= p): every lane's factor is a constant
    r^e(j, K), j < s_t the lane's digit, K < C_t the finished digits (all on lanes). The number of distinct
    exponent tuples is a multiplication-table count (no closed form; Erdos' problem), so it is evaluated as the
    size of that arithmetic set: returns (#lanes with e = 0 in every direction, [users per distinct nonzero
    tuple]) per (j, K) pair (multiply by 2^pi_t for the lanes).'''
    x = L[t]
    s, C = x['s'], x['C']
    Cp = L[t - 1]['C']
    R = N // (C * s)
    order = 2 * N if negacyclic else N
    cnt = {}
    for j in range(s):
        for K in range(C):
            kp = K // Cp
            tup = tuple((R * j * (KERNELS[(negacyclic, dd)][0] + KERNELS[(negacyclic, dd)][1] * K)
                         + KERNELS[(negacyclic, dd)][2] * Cp * kp) % order for dd in sorted(dirs))
            cnt[tup] = cnt.get(tup, 0) + 1
    zero = tuple(0 for _ in dirs)
    one = cnt.pop(zero, 0)
    return one, list(cnt.values())


def _constPorts(N, L, t, dirs, negacyclic):
    '''Folded ports of a pass with tau_t = 0: distinct exponent tuples over (K, stage, pair j).'''
    x = L[t]
    s, C, a = x['s'], x['C'], x['a']
    R = N // (C * s)
    order = 2 * N if negacyclic else N
    seen = set()
    for K in range(C):
        for st in range(a):
            E = s >> (st + 1)
            for j in range(1 << st):
                seen.add(tuple((E * R * (KERNELS[(negacyclic, dd)][0] + KERNELS[(negacyclic, dd)][1] * K)
                                + KERNELS[(negacyclic, dd)][1] * (N // s) * j * E) % order for dd in sorted(dirs)))
    return len(seen)


def _constPortsGs(N, L, t, negacyclic):
    '''folded_gs inverse ports of a pass whose pending digits are all on lanes (sig_t = 0): distinct exponents
    over (J, stage, pair j), J < R_t the pending digits, E = 2^stage, j < s_t / 2^(stage + 1).'''
    x = L[t]
    s, C, a = x['s'], x['C'], x['a']
    R = N // (C * s)
    order = 2 * N if negacyclic else N
    _, cB, cG = KERNELS[(negacyclic, 'inv')]
    seen = set()
    for J in range(R):
        for st in range(a):
            E = 1 << st
            for j in range(s >> (st + 1)):
                seen.add((E * (C * (cG + cB * J) + cB * (N // s) * j)) % order)
    return len(seen)


def layout(N: int, sizes, P: int) -> list[dict]:
    m, p = _lg(N), _lg(P)
    a = [_lg(s) for s in sizes]
    d = len(a)
    out = []
    A = 0
    for t in range(d):
        A_prev, A = A, A + a[t]
        l0 = min(max(p - A_prev, 0), a[t])
        pi = max(0, p - A)
        lam = p - a[t] - pi
        tau = A_prev - lam
        n = a[t] - l0
        kap = min(n, a[t - 1]) if t > 0 else 0
        out.append(dict(t=t, a=a[t], s=sizes[t], A_prev=A_prev, C=1 << A_prev, l0=l0, pi=pi, lam=lam, tau=tau,
                        n=n, kap=kap, lo=m - A, win=(1 << (n + m - A)) if n else 0))
    return out


def formCounts(N: int, sizes, P: int, M: int, dirs, negacyclic: bool = True, form: str = 'twist',
               sources=None, W: int = 60, tableShare: int | None = None, romLutMax: int = 256,
               transposeLutMax: int = 64) -> dict:
    '''Closed-form counts. `dirs` a subset of {'fwd', 'inv'}; `sources` one of 'rom' | 'otf' | 'tree' per
    inter-pass stage (twist form). `tableShare`: copies of a table per that many users (as the cost model
    prices it); None: one instance per distinct table (as the RTL builds it).'''
    from .MultiStepScheme import memoryTiles
    dirs = set(dirs)
    D = len(dirs)
    inv = negacyclic and 'inv' in dirs           # the inverse twist and the gamma terms exist
    L = layout(N, sizes, P)
    d = len(L)
    sources = list(sources or ['rom'] * (d - 1))
    res = {'passes': [], 'stages': [], 'transposes': [], 'form': form,
           # folded_gs is the unified CT/GS design: both directions (any pass sizes)
           'valid': form != 'folded_gs' or dirs == {'fwd', 'inv'} or dirs == {'inv'}}   # inverse alone: the GS half

    # --- butterflies --------------------------------------------------------------------------------
    for x in L:
        t, s, a = x['t'], x['s'], x['a']
        bu = (P // 2) * a
        if form == 'folded_gs' or (form == 'folded' and t > 0):
            triv = 0                              # port twiddles vary with K on every butterfly
        elif t == 0 and negacyclic and 'fwd' in dirs:
            triv = 0                              # merged psi (forward): no exponent is 0
        else:
            triv = (P // s) * (s - 1)             # cyclic CT: j = 0 pairs, s - 1 per copy
        res['passes'].append(dict(t=t, s=s, butterflies=bu, trivial=triv, general=bu - triv,
                                  subClasses=(s - 1) if (t == 0 and negacyclic and 'fwd' in dirs) else s // 2 - 1))

    # --- inter-pass stages ---------------------------------------------------------------------------
    words_total = 0
    tables_all = []                               # (count, depth, users)

    def addTables(st, n, sig, users, D=D):
        if n <= 0:
            return
        depth = M * D * (1 << sig)
        st['tables'].append(dict(n=n, sig=sig, depth=depth, users=users))
        st['words'] += n * (1 << sig)             # per prime per direction

    if form == 'twist':
        for x in L[1:]:
            t, s, lam, pi, tau, kap = x['t'], x['s'], x['lam'], x['pi'], x['tau'], x['kap']
            ap = L[t - 1]['a']
            G = P // s
            src = sources[t - 1]
            if inv:
                one = (P // (s * L[t - 1]['s'])) if kap == 0 else 0
            else:
                one = G
            st = dict(t=t, source=src, mults=P - one, one=one, gens=0, tables=[], words=0)
            if tau == 0 and src != 'tree':
                one0, users = _constStage(N, L, t, dirs, negacyclic)
                st['one'] = one0 << pi
                st['mults'] = P - st['one']
                for u in users:
                    addTables(st, 1, 0, u << pi)
                res['stages'].append(st)
                words_total += st['words']
                continue
            nj0 = (1 << (ap - kap)) - (1 if kap == 0 else 0) if inv else 0     # distinct j = 0 tables
            uj0 = (G >> (ap - kap)) if inv else 0                               # lanes per j = 0 table
            if src == 'rom' or (src == 'otf' and tau <= 1):
                addTables(st, (s - 1) << lam, tau, 1 << pi)
            elif src == 'otf':
                h = (tau + 1) // 2
                addTables(st, (s - 1) << lam, h, 1 << pi)
                addTables(st, s - 1, tau - h, 1 << (lam + pi))
                st['gens'] += P - G
            if src in ('rom', 'otf') and inv:
                if src == 'otf' and kap > 1:
                    h = (kap + 1) // 2
                    addTables(st, nj0, h, uj0)
                    addTables(st, 1, kap - h, nj0 * uj0)
                    st['gens'] += G - one
                else:
                    addTables(st, nj0, kap, uj0)
            if src == 'tree':
                lb = x['a']
                yoneG = (G >> ap) if (inv and kap == 0) else (0 if inv else G)
                two = tau > 1
                st['gens'] = G * ((s - 1) + (lb - 1) + (1 if two else 0)) - yoneG * lb
                st['mults'] = G * s - yoneG
                if two:
                    h = (tau + 1) // 2
                    addTables(st, 1 << lam, h, 1 << pi)
                    addTables(st, 1, tau - h, G)
                else:
                    addTables(st, 1 << lam, tau, 1 << pi)
                if inv:
                    addTables(st, nj0, kap, G >> (ap - kap))
            res['stages'].append(st)
            words_total += st['words']
        inv_twist = P if inv else 0               # CT output twist of the last pass (UNR: every lane)
    elif form == 'folded_gs':
        # port tables of every pass, one set per direction (so the words are per prime, both directions)
        mm = _lg(N)
        for x in L:
            t, s, lam, pi, tau = x['t'], x['s'], x['lam'], x['pi'], x['tau']
            st = dict(t=t, source='ports', mults=0, one=0, gens=0, tables=[], words=0)
            if 'fwd' in dirs:
                if tau == 0:
                    addTables(st, _constPorts(N, L, t, {'fwd'}, negacyclic), 0, 1, D=1)
                else:
                    addTables(st, (s - 1) << lam, tau, 1, D=1)
            if 'inv' in dirs:
                sg = mm - x['A_prev'] - x['a'] - pi
                if sg == 0:
                    addTables(st, _constPortsGs(N, L, t, negacyclic), 0, 1, D=1)
                else:
                    addTables(st, (s - 1) << pi, sg, 1, D=1)
            res['stages'].append(st)
            words_total += st['words']
        inv_twist = 0                              # merged into the GS passes
    else:
        # folded: port tables of passes 2..d (forward structure)
        for x in L[1:]:
            t, s, lam, pi, tau = x['t'], x['s'], x['lam'], x['pi'], x['tau']
            st = dict(t=t, source='ports', mults=0, one=0, gens=0, tables=[], words=0)
            if tau == 0:
                addTables(st, _constPorts(N, L, t, dirs, negacyclic), 0, 1)
            else:
                addTables(st, (s - 1) << lam, tau, 1)
            res['stages'].append(st)
            words_total += st['words']
        # the inverse twist r^-k: one P-lane stage at the output, a ROM over every cycle bit per lane
        f = _lg(N) - _lg(P)
        one_k = 1 if f == 0 else 0            # N = P: the lane of k = 0 has factor 1
        inv_twist = (P - one_k) if inv else 0
        if inv:
            st = dict(t=d, source='rom', mults=P - one_k, one=one_k, gens=0, tables=[], words=0)
            addTables(st, P - one_k, f, 1)
            res['stages'].append(st)
            words_total += st['words']
    res['invTwist'] = inv_twist

    # --- transposes ------------------------------------------------------------------------------------
    for x in L[1:]:
        if x['n']:
            res['transposes'].append(dict(t=x['t'], S=1 << x['n'], lo=x['lo'], depth=x['win'], words=P * x['win']))

    # --- totals and tiles --------------------------------------------------------------------------------
    gen_bu = sum(p['general'] for p in res['passes'])
    inter = sum(st['mults'] for st in res['stages'] if st['t'] < d) if form == 'twist' else 0
    gens = sum(st['gens'] for st in res['stages'])
    res['multipliers'] = dict(butterflies=gen_bu, interPass=inter, invTwist=inv_twist, generators=gens,
                              total=gen_bu + inter + inv_twist + gens)
    res['twiddleWordsPerPrimePerDir'] = words_total
    res['transposeWords'] = sum(x['words'] for x in res['transposes'])
    bram = uram = lutrom = 0
    for st in res['stages']:
        for tb in st['tables']:
            copies = 1 if tableShare is None else -(-tb['users'] // tableShare)
            if tb['depth'] <= romLutMax:
                lutrom += tb['n'] * copies
                continue
            r = memoryTiles(tb['depth'], W)
            bram += tb['n'] * copies * r['bram36']
            uram += tb['n'] * copies * r['uram']
    tb_bram, tb_uram = bram, uram
    for x in res['transposes']:
        if x['depth'] <= transposeLutMax:
            continue
        r = memoryTiles(x['depth'], W)
        bram += P * r['bram36']
        uram += P * r['uram']
    res['tiles'] = dict(bram36=bram, uram=uram, twiddleBram36=tb_bram, twiddleUram=tb_uram, lutRomTables=lutrom)
    return res
