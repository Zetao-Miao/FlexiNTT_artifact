'''The moduli of Kim et al., "Hardware Architecture of a Number Theoretic Transform
for a Bootstrappable RNS-based Homomorphic Encryption Scheme" (FCCM 2020), Table II:
the base modulus q0 and the rescale moduli q1..q41 of their parameter Set-B
(N = 2^17, l + 1 = 42; the moduli their INTT uses), transcribed term by term.

Each modulus is written as signed powers of two plus 1, as in the paper
(`(51, +1), (29, -1), (19, -1)` is 2^51 - 2^29 - 2^19 + 1). `check()` verifies
what the paper relies on: every q is prime and q = 1 (mod 2^18) (a negacyclic
NTT of N = 2^17 points needs a primitive 2N-th root), all 42 are distinct.

Widths, measured: q0 = 2^61 - 2^26 + 1 has 61 bits, q1..q41 have 51 bits (2^51 - ...)
or 52 bits (2^51 + ...). The paper's Table I gives log q0 = 62 and log qi = 52,
rounded up; the hardware here sizes itself from the values.

Table III's modup moduli p1..p16 (61-62 bits) are used by the paper's NTT, not
its INTT; they are listed in `KIM_P_TERMS` for completeness.
'''
from __future__ import annotations

from .primes import isPrime

#: Table II: q_i as [(exponent, sign), ...] + 1
KIM_Q_TERMS = [
    [(61, 1), (26, -1)],
    [(51, 1), (29, -1), (19, -1)],
    [(51, 1), (28, -1), (23, -1), (19, 1)],
    [(51, 1), (28, -1), (22, -1)],
    [(51, 1), (28, -1), (26, 1), (20, 1)],
    [(51, 1), (27, -1), (24, -1), (22, 1)],
    [(51, 1), (27, -1), (19, -1)],
    [(51, 1), (27, -1), (24, 1)],
    [(51, 1), (26, -1), (22, -1), (19, -1)],
    [(51, 1), (26, -1), (23, 1), (20, 1)],
    [(51, 1), (26, -1), (24, 1), (18, -1)],
    [(51, 1), (25, -1), (23, -1), (19, 1)],
    [(51, 1), (25, -1), (22, -1), (20, -1)],
    [(51, 1), (25, -1), (22, -1), (18, 1)],
    [(51, 1), (25, -1), (21, -1), (18, -1)],
    [(51, 1), (25, -1), (20, 1), (18, -1)],
    [(51, 1), (25, -1), (23, 1), (19, -1)],
    [(51, 1), (25, -1), (23, 1), (20, 1)],
    [(51, 1), (24, -1), (19, 1)],
    [(51, 1), (30, -1), (20, -1)],
    [(51, 1), (29, -1), (22, -1), (18, 1)],
    [(51, 1), (24, -1), (21, 1), (18, 1)],
    [(51, 1), (23, -1), (20, 1)],
    [(51, 1), (23, -1), (21, 1), (18, -1)],
    [(51, 1), (21, 1), (18, -1)],
    [(51, 1), (22, 1), (20, -1), (18, -1)],
    [(51, 1), (22, 1), (20, 1)],
    [(51, 1), (23, 1), (20, 1), (18, 1)],
    [(51, 1), (25, 1), (23, -1), (21, -1)],
    [(51, 1), (25, 1), (22, -1), (20, 1)],
    [(51, 1), (25, 1)],
    [(51, 1), (25, 1), (19, 1)],
    [(51, 1), (25, 1), (21, 1)],
    [(51, 1), (25, 1), (22, 1), (19, 1)],
    [(51, 1), (26, 1), (20, -1), (18, -1)],
    [(51, 1), (26, 1), (21, 1), (18, 1)],
    [(51, 1), (27, 1), (24, -1), (21, -1)],
    [(51, 1), (28, 1), (18, 1)],
    [(51, 1), (28, 1), (20, 1)],
    [(51, 1), (29, 1)],
    [(51, 1), (30, -1), (19, 1)],
    [(51, 1), (29, 1), (21, 1), (18, 1)],
]

#: Table III: the modup moduli p1..p16
KIM_P_TERMS = [
    [(61, 1), (24, -1)], [(61, 1), (21, -1)], [(61, 1), (23, 1), (18, -1)], [(61, 1), (24, 1), (19, -1)],
    [(61, 1), (27, 1), (21, 1)], [(61, 1), (29, 1), (22, -1)], [(61, 1), (30, 1), (18, 1)],
    [(61, 1), (30, 1), (26, 1)], [(61, 1), (22, -1), (19, 1)], [(61, 1), (22, 1), (20, 1)],
    [(61, 1), (23, 1), (21, 1)], [(61, 1), (25, 1), (23, 1)], [(61, 1), (28, 1), (25, -1)],
    [(61, 1), (29, 1), (19, 1)], [(61, 1), (30, 1), (20, 1)], [(61, 1), (30, 1), (28, 1)],
]


def value(terms) -> int:
    return sum(s * (1 << e) for e, s in terms) + 1


#: q0..q41 in the paper's order (index i is q_i)
KIM_Q = [value(t) for t in KIM_Q_TERMS]
KIM_P = [value(t) for t in KIM_P_TERMS]
#: what the moduli support: N = 2^17 points, negacyclic (2N | q - 1)
KIM_N = 1 << 17


def check(moduli=None, order: int = 2 * KIM_N) -> list[str]:
    '''Problems with a modulus list (empty: all prime, q = 1 mod `order`, distinct).'''
    ms = KIM_Q if moduli is None else moduli
    bad = []
    for i, q in enumerate(ms):
        if not isPrime(q):
            bad.append(f'q{i} = {q} is not prime')
        if (q - 1) % order:
            bad.append(f'q{i} = {q}: {order} does not divide q - 1')
    if len(set(ms)) != len(ms):
        bad.append('moduli repeat')
    return bad


if __name__ == '__main__':
    probs = check() + check(KIM_P, 1)
    for i, q in enumerate(KIM_Q):
        print(f'q{i:<2} = {q:>20}  {q.bit_length()} bits  v2(q-1) = {((q - 1) & -(q - 1)).bit_length() - 1}')
    print('OK: 42 primes, all = 1 mod 2^18' if not probs else '\n'.join(probs))
