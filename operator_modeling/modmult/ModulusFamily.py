'''The moduli a modular operator accepts: one design-time `q`, or a family whose
members arrive at run time on ports.

    ModulusFamily.fixed(q)                 one q, built into the hardware (no ports)
    ModulusFamily.odd(bits, minBits)       any odd q with minBits..bits bits
    ModulusFamily.friendly(v, qhBits)      q = qH*2^v + 1, qH < 2^qhBits (NTT-friendly)
    ModulusFamily.kred(m, kBits)           q = k*2^m + 1, k < 2^kBits (K-RED's shape)
    ModulusFamily.pseudoMersenne(n, cBits) q = 2^n - c, c < 2^cBits odd
    ModulusFamily.table(moduli)            exactly these odd moduli (an RNS limb set, e.g. Kim et
                                           al.'s q0..q41); a per-polynomial modulus table selects one

A run-time family is what an RNS design needs: every limb has its own prime,
so the hardware is built for the family and the limb's constants (q, mu, q',
qH, k or c, whichever the reduction needs) are inputs. A reduction declares
which constants it needs (`ModularReductionScheme.qPorts`); the family only
says which q are legal, how to sample and enumerate them, and how to recover q
from the constants on a trial. Every structural property a reduction relies on
holds for every member: `friendly` guarantees q = 1 (mod 2^v), `kred` the
shape k*2^m + 1, `pseudoMersenne` 2^n = c (mod q).

Members need not be prime: the reductions' algebra needs only an odd q (and
the family's shape). The gates draw primes and composite members alike;
`sample(rng, prime=True)` prefers primes, as a real limb would be.
'''
from __future__ import annotations

from .primes import isPrime

KINDS = ('fixed', 'odd', 'friendly', 'kred', 'pseudomersenne', 'table')


class ModulusFamily:
    '''A set of moduli. Construct with the class methods.'''

    def __init__(self, kind: str, **p):
        if kind not in KINDS:
            raise ValueError(f'modulus family kind {kind!r} not in {KINDS}')
        self.kind = kind
        self.p = dict(p)
        if kind == 'fixed':
            q = p['q']
            if q < 3:
                raise ValueError(f'fixed modulus must be >= 3, got {q}')
            self.qMin = self.qMax = q
        elif kind == 'table':
            ms = tuple(sorted(set(int(q) for q in p['moduli'])))
            if not ms or any(q < 3 or q % 2 == 0 for q in ms):
                raise ValueError(f'table family: moduli must be odd and >= 3, got {ms[:4]}...')
            self.p['moduli'] = ms
            self.qMin, self.qMax = ms[0], ms[-1]
        elif kind == 'odd':
            bits, lo = p['bits'], p['minBits']
            if not 2 <= lo <= bits:
                raise ValueError(f'odd family: need 2 <= minBits <= bits, got {lo}, {bits}')
            self.qMin, self.qMax = max(3, (1 << (lo - 1)) | 1), (1 << bits) - 1
        elif kind == 'friendly':
            v, h, hmin = p['v'], p['qhBits'], p['qhMin']
            if v < 1 or h < 1 or not 1 <= hmin < (1 << h):
                raise ValueError(f'friendly family: v={v}, qhBits={h}, qhMin={hmin}')
            self.qMin, self.qMax = (hmin << v) + 1, (((1 << h) - 1) << v) + 1
        elif kind == 'kred':
            m, kb, kmin = p['m'], p['kBits'], p['kMin']
            if m < 1 or kb < 1 or not 1 <= kmin < (1 << kb):
                raise ValueError(f'kred family: m={m}, kBits={kb}, kMin={kmin}')
            self.qMin, self.qMax = (kmin << m) + 1, (((1 << kb) - 1) << m) + 1
        else:
            n, cb = p['n'], p['cBits']
            if not 1 <= cb < n:
                raise ValueError(f'pseudo-Mersenne family: need 1 <= cBits < n, got {cb}, {n}')
            self.qMin, self.qMax = (1 << n) - ((1 << cb) - 1), (1 << n) - 1
        self.n = self.qMax.bit_length()

    # --- constructors -----------------------------------------------------

    @classmethod
    def fixed(cls, q: int) -> 'ModulusFamily':
        return cls('fixed', q=q)

    @classmethod
    def table(cls, moduli) -> 'ModulusFamily':
        '''Exactly the given odd moduli (kept sorted; `index(q)` is a member's position).'''
        return cls('table', moduli=tuple(moduli))

    def index(self, q: int) -> int:
        '''A table member's position in increasing order.'''
        return self.p['moduli'].index(q)

    @classmethod
    def odd(cls, bits: int, minBits: int | None = None) -> 'ModulusFamily':
        '''Any odd q of `minBits`..`bits` bits (default exactly `bits`).'''
        return cls('odd', bits=bits, minBits=bits if minBits is None else minBits)

    @classmethod
    def friendly(cls, v: int, qhBits: int, qhMin: int | None = None) -> 'ModulusFamily':
        '''q = qH*2^v + 1 with qhMin <= qH < 2^qhBits (default: qH has exactly
        qhBits bits, so q has exactly v + qhBits bits).'''
        return cls('friendly', v=v, qhBits=qhBits, qhMin=(1 << (qhBits - 1)) if qhMin is None else qhMin)

    @classmethod
    def kred(cls, m: int, kBits: int, kMin: int | None = None) -> 'ModulusFamily':
        '''q = k*2^m + 1 with kMin <= k < 2^kBits (default: k has exactly kBits
        bits; a wider range of q needs more correction candidates).'''
        return cls('kred', m=m, kBits=kBits, kMin=(1 << (kBits - 1)) if kMin is None else kMin)

    @classmethod
    def pseudoMersenne(cls, n: int, cBits: int) -> 'ModulusFamily':
        return cls('pseudomersenne', n=n, cBits=cBits)

    # --- what it is ---------------------------------------------------------

    @property
    def runtime(self) -> bool:
        return self.kind != 'fixed'

    def contains(self, q: int) -> bool:
        if not self.qMin <= q <= self.qMax or q % 2 == 0:
            return False
        k = self.kind
        if k == 'fixed':
            return q == self.p['q']
        if k == 'odd':
            return True
        if k == 'table':
            return q in self.p['moduli']
        if k == 'friendly':
            return (q - 1) % (1 << self.p['v']) == 0
        if k == 'kred':
            return (q - 1) % (1 << self.p['m']) == 0
        return (1 << self.p['n']) - q < (1 << self.p['cBits'])

    def _fromIndex(self, i: int) -> int:
        '''The i-th member in increasing order (no bounds check).'''
        k = self.kind
        if k == 'fixed':
            return self.p['q']
        if k == 'table':
            return self.p['moduli'][i]
        if k == 'odd':
            return self.qMin + 2 * i
        if k == 'friendly':
            return ((self.p['qhMin'] + i) << self.p['v']) + 1
        if k == 'kred':
            return ((self.p['kMin'] + i) << self.p['m']) + 1
        return self.qMin + 2 * i if self.qMin % 2 else self.qMin + 1 + 2 * i

    def size(self) -> int:
        k = self.kind
        if k == 'fixed':
            return 1
        if k == 'table':
            return len(self.p['moduli'])
        if k == 'odd' or k == 'pseudomersenne':
            first = self._fromIndex(0)
            return (self.qMax - first) // 2 + 1
        if k == 'friendly':
            return (1 << self.p['qhBits']) - self.p['qhMin']
        return (1 << self.p['kBits']) - self.p['kMin']

    def members(self, limit: int | None = None):
        '''Every member in increasing order (the first `limit`).'''
        n = self.size() if limit is None else min(limit, self.size())
        for i in range(n):
            q = self._fromIndex(i)
            if q >= 3:
                yield q

    def sample(self, rng, prime: bool = True, tries: int = 200) -> int:
        '''A random member; with `prime`, a prime member when one turns up in
        `tries` draws (an RNS limb's modulus is prime; the algebra is not).'''
        n = self.size()
        q = None
        for _ in range(tries if prime else 1):
            q = self._fromIndex(rng.randrange(n))
            if q < 3:
                continue
            if not prime or isPrime(q):
                return q
        return q if q is not None and q >= 3 else self.qMax

    def samplePrimeCongruent(self, rng, m: int, tries: int = 5000) -> int | None:
        '''A random prime member with q = 1 (mod m) (an NTT of length m/2 negacyclic, or m cyclic, needs
        it), or None. Random draws first (structured families often satisfy it by construction), then
        q = k*m + 1 over the family's range, which also finds the rare ones (m = 2^18 for n = 2^17).'''
        if self.kind == 'table':
            ok = [q for q in self.p['moduli'] if (q - 1) % m == 0 and isPrime(q)]
            return rng.choice(ok) if ok else None
        for _ in range(min(tries, 2000)):
            q = self.sample(rng, prime=True, tries=1)
            if q >= 3 and (q - 1) % m == 0 and isPrime(q):
                return q
        kLo, kHi = -(-(self.qMin - 1) // m), (self.qMax - 1) // m
        if kHi < kLo:
            return None
        for _ in range(tries * 20):
            q = rng.randint(kLo, kHi) * m + 1
            if self.contains(q) and isPrime(q):
                return q
        return None

    def corners(self) -> list[int]:
        '''Members at the family's extremes: where the static bounds are tight.'''
        out = []
        for q in (self._fromIndex(0), self._fromIndex(1) if self.size() > 1 else None,
                  self._fromIndex(self.size() - 1), self._fromIndex(max(0, self.size() - 2))):
            if q is not None and q >= 3 and q not in out:
                out.append(q)
        return out

    def describe(self) -> str:
        k, p = self.kind, self.p
        if k == 'fixed':
            return f'q = {p["q"]}'
        if k == 'table':
            ms = p['moduli']
            return f'table of {len(ms)} moduli, {ms[0].bit_length()}..{ms[-1].bit_length()} bits'
        if k == 'odd':
            return f'odd q, {p["minBits"]}..{p["bits"]} bits'
        if k == 'friendly':
            return f'q = qH*2^{p["v"]} + 1, qH in [{p["qhMin"]}, 2^{p["qhBits"]})'
        if k == 'kred':
            return f'q = k*2^{p["m"]} + 1, k in [{p["kMin"]}, 2^{p["kBits"]})'
        return f'q = 2^{p["n"]} - c, c < 2^{p["cBits"]}'

    def params(self) -> dict:
        return {'kind': self.kind, **self.p, 'qMin': self.qMin, 'qMax': self.qMax}

    def __repr__(self) -> str:
        return f'ModulusFamily({self.describe()})'
