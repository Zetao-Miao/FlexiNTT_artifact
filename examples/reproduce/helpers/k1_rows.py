"""The k = 1 (a modulus per polynomial) versions of the dataflow rows compared against AutoNTT (b)-(e).

Each keeps its base row's transform (cyclic), reduction, butterflies, inputRegister and inverseScale='stage'
(paper_gen.ROWS); only the modulus mode changes: moduli=[...] (per frame, MIDX) over the row's own run-time
family (WLM: friendly qH*2^v + 1; Barrett: odd 62-bit), so the datapath is the one-q-per-job row's.

L (moduli held by the design) = max(2, floor(logQ_max / q_bits)), logQ_max from the HomomorphicEncryption.org
standard, 128-bit classical security, ternary secret: n = 4096 -> 109; n = 2^17 is beyond the table (it ends
at 32768 -> 881), extrapolated by doubling per doubling of n: 65536 -> 1762, 131072 -> 3524 (EXTRAPOLATED).
"""
import os
import sys

GEN = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, GEN)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from operator_modeling.modmult.ModulusFamily import ModulusFamily as MF  # noqa: E402

LOGQ = {4096: (109, 'HE standard, 128-bit classical'), 65536: (1762, 'extrapolated: 881 at 2^15, doubled once'),
        131072: (3524, 'extrapolated: 881 at 2^15, doubled twice')}

# AutoNTT's primes of each row (ntt_hw/experiments/stream/reprime/*.log, paper_gen.AUTONTT_Q17)
AUTONTT_Q = {'q32': 2148728833, 'q64': 9223372195768565761,
             'q62': [2305843009218281473, 2305843009220116481]}

K1ROWS = {
    # (b) n = 4096, 32-bit q = qH*2^16 + 1, P = 2
    'K1_A4096_q32w16_P2c': dict(base='A4096_q32w16_P2c', design='(b)', qbits=32, source='rom'),
    # (c) n = 4096, 64-bit q = qH*2^32 + 1, P = 2
    'K1_A4096_q64w32_P2c': dict(base='A4096_q64w32_P2c', design='(c)', qbits=64, source='rom'),
    # (d) n = 4096, 64-bit, P = 32 (192 butterflies), inputRegister
    'K1_A4096_q64w32_P32ic': dict(base='A4096_q64w32_P32ic', design='(d)', qbits=64, source='rom'),
    # (e) n = 2^17, 62-bit odd q (2^17 | q - 1), Barrett, P = 8, inputRegister
    # moduli (RESUME_NOTES item 7): AutoNTT's prime, then Kim et al.'s Set-B primes (q0..q41, p1..p16; 51-62 bits,
    # all = 1 mod 2^18): 59 moduli. Mixed widths are outside the row's odd(62) family, so the datapath is Barrett
    # over ModulusFamily.table (a substitution of the family, not of the reduction: recorded in RESULTS.md)
    'K1_A131072_q62b_P8ci': dict(base='A131072_q62b_P8ci', design='(e)', qbits=62, source='rec', moduliSet='kim',
                                 family='table'),
    # the same with the row's own family and L = 56 primes k*2^17+1 above 2^61 (one-to-one with the fixed row)
    'K1_A131072_q62b_P8ci_odd': dict(base='A131072_q62b_P8ci', design='(e)', qbits=62, source='rec'),
    # real-FHE size (RESUME_NOTES item 8): Kim et al. FCCM 2020 Set-B, N = 2^17, its 42 moduli q0..q41 (51-61 bit),
    # forward negacyclic NTT (Kim's INTT runs on the same circuit; our negacyclic inverse would need the output
    # twist, item 6, not done), Barrett over the table, P = 8 (Kim's c = 4 butterflies a stage), 'rec' (Kim's
    # root recurrence), inputRegister; the kim/ experiment's kim_p8 core (OOC 350.9 MHz) as a board image
    'K1_KIM_N17_P8_fwd': dict(base=None, n=1 << 17, P=8, design='Kim Set-B', qbits=61, source='rec', moduliSet='kimq',
                              family='table', direction='forward',
                              mod=dict(red='barrett', nwc=True, inputRegister=True)),
    # real-FHE size at N = 2^16, ~60-bit (item 8): forward negacyclic, WLM over friendly q = qH*2^32 + 1 (qH 28 bits:
    # 60-bit q, 2^32 | q - 1), P = 32 (16 butterflies a stage, Allam et al.'s count), inputRegister;
    # L = floor(1762 / 60) = 29 (logQ at 2^16 extrapolated from the standard's 881 at 2^15)
    'K1_N16_q60w32_P32i_fwd': dict(base=None, n=1 << 16, P=32, design='2^16 60-bit', qbits=60, source='rec',
                                   direction='forward', friendlyFirst=None,
                                   mod=dict(family=MF.friendly(32, 28), red='wlm', nwc=True, inputRegister=True)),
    # the same with both directions (direction per polynomial): the negacyclic inverse's output twist on the fly
    'K1_KIM_N17_P8_both': dict(base=None, n=1 << 17, P=8, design='Kim Set-B', qbits=61, source='rec', moduliSet='kimq',
                               family='table', direction='both',
                               mod=dict(red='barrett', nwc=True, inputRegister=True, twistSource='otf')),
    # small rows for the adapter and its testbench (same adapter code, short system sims): row (b)'s and (e)'s
    # settings at n = 256, three moduli
    'K1T_A256_q32w16_P4c': dict(base='A4096_q32w16_P2c', n=256, P=4, L=3, design='test', qbits=32, source='rom'),
    'K1T_A256_q62b_P8ci': dict(base='A131072_q62b_P8ci', n=256, P=8, L=3, design='test', qbits=62, source='rec'),
}


def numModuli(n, qbits):
    return max(2, LOGQ[n][0] // qbits)


def _isprime(q):
    from sympy import isprime
    return bool(isprime(q))


def rowParams(row):
    '''(n, P, mod) of a k1 row: its base row's, with n and P overridden for the small test rows.'''
    from paper_gen import ROWS
    r = K1ROWS[row]
    if r.get('base') is None:
        return r['n'], r['P'], r['mod']
    n, P, mod, _ = ROWS[r['base']]
    return r.get('n', n), r.get('P', P), mod


def moduli(row):
    """The row's modulus table: AutoNTT's prime(s) first, then primes of the same form."""
    r = K1ROWS[row]
    n, P, mod = rowParams(row)
    if r.get('moduliSet') == 'kimq':
        from operator_modeling.modmult.kim_moduli import KIM_Q
        return list(KIM_Q)
    if r.get('moduliSet') == 'kim':
        from operator_modeling.modmult.kim_moduli import KIM_Q, KIM_P
        return [AUTONTT_Q['q62'][0]] + [q for q in KIM_Q + KIM_P if q != AUTONTT_Q['q62'][0]]
    L = r.get('L') or numModuli(n, r['qbits'])
    fam = mod['family']
    if fam.kind == 'friendly':
        v, h = fam.p['v'], fam.p['qhBits']
        first = r['friendlyFirst'] if 'friendlyFirst' in r else AUTONTT_Q['q32' if r['qbits'] == 32 else 'q64']
        out = [first] if first else []
        qh = (1 << h) - 1                      # then the largest qH downwards
        while len(out) < L:
            q = (qh << v) + 1
            if q != first and (q - 1) % (2 * n if mod.get('nwc') else n) == 0 and _isprime(q):
                out.append(q)
            qh -= 1
        return out
    # odd 62-bit with 2^17 | q - 1: the primes k*2^17 + 1 above 2^61 in order (AutoNTT used the first and third)
    out = list(AUTONTT_Q['q62'])[:L]
    k = (1 << 61) // n + 1
    while len(out) < L:
        q = k * n + 1
        if q not in out and _isprime(q):
            out.append(q)
        k += 1
    return out


def row_scheme(row, source, core_mhz=350, behavioural=False):
    import runModularNTT as rm
    n, P, mod = rowParams(row)
    extra = {k: v for k, v in mod.items() if k not in ('q', 'family', 'red', 'nwc', 'jobQ')}
    if behavioural:
        extra.update(multiplier='behavioural', qBackend='behavioural')
    fam = None if K1ROWS[row].get('family') == 'table' else mod.get('family')
    return rm.stream(row, n, P, moduli(row), mod['red'], mod.get('nwc', True), K1ROWS[row].get('direction', 'both'),
                     family=fam,
                     source=source, targetFmaxMhz=float(core_mhz), **extra)
