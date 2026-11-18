'''Moduli for sweeps: generic primes, NTT-friendly primes `k*2^w + 1`,
Mersenne and pseudo-Mersenne / Solinas primes, all deterministic.'''
from __future__ import annotations

import random

_SMALL = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71)


def isPrime(n: int) -> bool:
    '''Miller-Rabin, deterministic for n < 3.3e24 with these bases, and a
    strong probable-prime test beyond.'''
    if n < 2:
        return False
    for p in _SMALL:
        if n % p == 0:
            return n == p
    d, s = n - 1, 0
    while d % 2 == 0:
        d //= 2
        s += 1
    for a in (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41):
        x = pow(a, d, n)
        if x in (1, n - 1):
            continue
        for _ in range(s - 1):
            x = x * x % n
            if x == n - 1:
                break
        else:
            return False
    return True


def randomPrime(bits: int, seed: int = 0) -> int:
    rng = random.Random(seed * 1000 + bits)
    while True:
        q = rng.getrandbits(bits) | (1 << (bits - 1)) | 1
        if isPrime(q):
            return q


def nttFriendlyPrime(bits: int, w: int, seed: int = 0) -> int:
    '''A prime `q = k*2^w + 1` of exactly `bits` bits (k odd); `seed` picks
    which one, scanning k from the top of the range downwards.'''
    if w >= bits:
        raise ValueError('w must be below bits')
    kmax = ((1 << bits) - 1) >> w
    k = kmax if kmax % 2 else kmax - 1
    found = -1
    while k > (1 << (bits - w - 1)):
        q = (k << w) + 1
        if q.bit_length() == bits and isPrime(q):
            found += 1
            if found == seed:
                return q
        k -= 2
    raise ValueError(f'no {bits}-bit prime k*2^{w}+1 (seed {seed})')


def pseudoMersennePrime(bits: int) -> int:
    '''The largest prime `2^bits - c` (smallest c).'''
    c = 1
    while not isPrime((1 << bits) - c):
        c += 2
    return (1 << bits) - c


def solinasPrime(bits: int, k: int | None = None) -> int:
    """A Solinas (generalised Mersenne) prime `2^bits - 2^k + 1` or
    `2^bits - 2^k - 1`, k as close to `bits/2` (or the given k) as possible:
    two NAF terms beyond the leading power, so a fold costs two shifted adds."""
    k0 = k if k is not None else bits // 2
    order = sorted(range(2, bits - 1), key=lambda kk: (abs(kk - k0), -kk))
    for kk in order:
        for c in (1, -1):
            q = (1 << bits) - (1 << kk) + c
            if isPrime(q):
                return q
    raise ValueError(f'no 2^{bits} - 2^k +/- 1 prime')


MERSENNE_EXPONENTS = (31, 61, 89, 107, 127)
