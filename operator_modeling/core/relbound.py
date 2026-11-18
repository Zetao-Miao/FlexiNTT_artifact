'''Bounds relative to a run-time modulus: a wire's value between two
polynomials in q, for every q of a family.

An interval over a whole family forgets which q a value belongs to: a value
below 2q of its own q is only known to be below 2*qMax, and divided by qMin
that is up to 4 when qMax is about 2*qMin. A relative bound keeps the q:

    L(q) <= value <= U(q)     for every member q in [qMin, qMax]

with L and U Laurent polynomials in q (exponents -1, 0, 1, 2, ...) with
rational coefficients: `Q` is [q, q], `QH` of q = QH*2^v + 1 is
[(q-1)/2^v, (q-1)/2^v], `MU = floor(2^e/q)` is [2^e/q - 1, 2^e/q], an operand
declared below q is [0, q - 1], a product of two is [0, (q-1)^2].

Every operation here is sound for every q in the range: sums add, a shift
scales, a right shift (a slice from bit lo upwards) divides and allows the
floor's loss in the lower bound, a product of nonnegative bounds multiplies.
Where soundness would need more care (a product of signed bounds, a slice
with an upper end) the bound is dropped and the absolute interval applies.

`span(p, qMin, qMax)` bounds a polynomial over the range term by term: each
term `a*q^k` is monotone in q, so its extremes are at the ends; the sum of
the per-term extremes contains the polynomial's range (looser than exact,
never wrong). `kRange` uses it on `L(q)/q` and `U(q)/q` to give the multiples
of q a correction must consider.
'''
from __future__ import annotations

from fractions import Fraction
from math import floor


class Poly:
    '''sum of coeff * q^exp, exponents are integers (negative allowed).'''

    __slots__ = ('c',)

    def __init__(self, coeffs=None):
        self.c = {}
        for e, a in (coeffs or {}).items():
            a = Fraction(a)
            if a:
                self.c[int(e)] = a

    @staticmethod
    def const(v) -> 'Poly':
        return Poly({0: v})

    @staticmethod
    def q(power: int = 1, coeff=1) -> 'Poly':
        return Poly({power: coeff})

    def __add__(self, o: 'Poly') -> 'Poly':
        d = dict(self.c)
        for e, a in o.c.items():
            d[e] = d.get(e, 0) + a
        return Poly(d)

    def __neg__(self) -> 'Poly':
        return Poly({e: -a for e, a in self.c.items()})

    def __sub__(self, o: 'Poly') -> 'Poly':
        return self + (-o)

    def scale(self, s) -> 'Poly':
        s = Fraction(s)
        return Poly({e: a * s for e, a in self.c.items()})

    def __mul__(self, o: 'Poly') -> 'Poly':
        d: dict = {}
        for e1, a1 in self.c.items():
            for e2, a2 in o.c.items():
                d[e1 + e2] = d.get(e1 + e2, 0) + a1 * a2
        return Poly(d)

    def divq(self) -> 'Poly':
        return Poly({e - 1: a for e, a in self.c.items()})

    def at(self, q: int) -> Fraction:
        return sum((a * Fraction(q) ** e for e, a in self.c.items()), Fraction(0))

    def isConst(self) -> bool:
        return all(e == 0 for e in self.c)

    def __repr__(self) -> str:
        if not self.c:
            return '0'
        return ' + '.join(f'{a}*q^{e}' for e, a in sorted(self.c.items(), reverse=True))


def span(p: Poly, qMin: int, qMax: int) -> tuple[Fraction, Fraction]:
    '''(lo, hi) containing p(q) for every q in [qMin, qMax] (term by term).'''
    lo = hi = Fraction(0)
    for e, a in p.c.items():
        x, y = a * Fraction(qMin) ** e, a * Fraction(qMax) ** e
        lo += min(x, y)
        hi += max(x, y)
    return lo, hi


class Rel:
    '''L(q) <= v <= U(q) for every q of the family.'''

    __slots__ = ('L', 'U')

    def __init__(self, L: Poly, U: Poly):
        self.L, self.U = L, U

    @staticmethod
    def const(lo, hi) -> 'Rel':
        return Rel(Poly.const(lo), Poly.const(hi))

    def __add__(self, o: 'Rel') -> 'Rel':
        return Rel(self.L + o.L, self.U + o.U)

    def __neg__(self) -> 'Rel':
        return Rel(-self.U, -self.L)

    def shift(self, s: int) -> 'Rel':
        '''times 2^s (s >= 0).'''
        f = Fraction(2) ** s
        return Rel(self.L.scale(f), self.U.scale(f))

    def floordiv(self, s: int) -> 'Rel':
        '''floor(v / 2^s), s >= 0: the floor costs at most 1 - 2^-s below.'''
        if s == 0:
            return self
        f = Fraction(1, 2 ** s)
        return Rel(self.L.scale(f) - Poly.const(1 - f), self.U.scale(f))

    def mul(self, o: 'Rel', qMin: int, qMax: int) -> 'Rel | None':
        '''Product. Exact rules when one factor is nonnegative over the range
        and each end of the other has one sign there; None otherwise (the
        interval applies).'''
        def sign(p):
            lo, hi = span(p, qMin, qMax)
            return 1 if lo >= 0 else (-1 if hi <= 0 else 0)
        for a, b in ((self, o), (o, self)):
            if sign(b.L) < 1:
                continue                     # b must be nonnegative: b in [b.L, b.U], b.L >= 0
            sl, su = sign(a.L), sign(a.U)
            if sl == 0 or su == 0:
                continue
            lower = a.L * (b.L if sl > 0 else b.U)
            upper = a.U * (b.U if su > 0 else b.L)
            return Rel(lower, upper)
        return None

    def span(self, qMin: int, qMax: int) -> tuple[Fraction, Fraction]:
        return span(self.L, qMin, qMax)[0], span(self.U, qMin, qMax)[1]

    def kRange(self, qMin: int, qMax: int) -> tuple[int, int]:
        '''(kLow, kHigh) with kLow <= floor(v/q) <= kHigh for every q and v.'''
        lo = span(self.L.divq(), qMin, qMax)[0]
        hi = span(self.U.divq(), qMin, qMax)[1]
        return floor(lo), floor(hi)

    def atInt(self, q: int) -> tuple[int, int]:
        '''Integer bounds for one q: ceil(L(q)), floor(U(q)).'''
        lo, hi = self.L.at(q), self.U.at(q)
        return -floor(-lo), floor(hi)

    def __repr__(self) -> str:
        return f'[{self.L}, {self.U}]'
