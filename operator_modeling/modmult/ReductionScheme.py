'''Modular reductions, each a `DatapathScheme`: `R ≡ T * factor (mod q)`.

Every reduction here takes an input `T` with any `IntType` bound (a product, a
lazy sum, a signed butterfly output) and a design-time modulus `q`, and is
described once as a datapath, so its bound path, bit-exact value path, timing,
cost and RTL come from the same nodes (`core/datapath.py`).

    family                 needs                       factor        native output
    BarrettReduction       any q                       1             [0, (E+1)q)
    MontgomeryReduction    odd q, R = 2^r > q          R^-1          [0, 2q) if T < qR
    WordLevelMontgomery    q = qH*2^w + 1 (or generic)  2^(-wL)       about [0, 2q)
    FoldReduction          sparse 2^k mod q             1             signed, ~2^(n+1)
      MersenneReduction    q = 2^n - 1
      SolinasReduction     q = 2^n - c, c sparse
      GoldilocksReduction  q = 2^64 - 2^32 + 1, the butterfly's limb table
    TableLookupReduction   any q                       1             [0, ~(J+1)q)
    CustomReduction        your `reduceInto`           your factor   yours

`outputRange` picks how far to correct the native result: `'exact'` (one
correction into [0, q)), an integer `r >= 2` (lazily into [0, r*q), fewer
candidates), or `'lazy'` (no correction: whatever the reduction leaves, which a
following butterfly or adder may accept).

Constant products (by `mu`, `q`, `q'`, `qH`, a fold constant) are constant
multipliers: NAF heaps on LUTs by default (`constBackend='lut'`), so a design-time
modulus becomes shifts and adds the compressor sums; `'dsp'` or `'booth'` puts
them on a multiplier block instead, as the paper's HLS designs do.

The golden reference of every family is `reference()`: `(T * factor) mod q`, in
plain Python integers, and an output is accepted when it is congruent to it and
lies in the declared range. `inputCorners` adds the modular corners (q-1, q,
2q-1, (q-1)^2, ...) to the bound's ends.
'''
from __future__ import annotations

from fractions import Fraction

from ..core.IntType import IntType
from ..core.datapath import Datapath, DatapathScheme
from ..core.utils import nafTerms, nafTermsModulusLift
from .ModulusFamily import ModulusFamily
from ..core.relbound import Poly, Rel
from .runtimeq import sampleTrials

OUTPUT_RANGES = ('exact', 'lazy')


def relativeForm(b: IntType, qmax: int):
    '''The relative bound a static bound stands for, when it is the family-wide
    form of one: [0, k*qMax - 1] -> [0, k*q - 1]; [0, (qMax-1)^2] -> [0, (q-1)^2];
    [-(qMax-1)^2, (qMax-1)^2] -> the signed square. Otherwise None.'''
    q1 = Poly.q() - Poly.const(1)
    sq = q1 * q1
    if b.minValue == 0 and (b.maxValue + 1) % qmax == 0:
        k = (b.maxValue + 1) // qmax
        return Rel(Poly.const(0), Poly.q(1, k) - Poly.const(1))
    if b.minValue == 0 and b.maxValue == (qmax - 1) ** 2:
        return Rel(Poly.const(0), sq)
    if b.minValue == -(qmax - 1) ** 2 and b.maxValue == (qmax - 1) ** 2:
        return Rel(-sq, sq)
    return None


def _bitsOf(b: IntType) -> int:
    return max(b.maxValue, 0).bit_length()


class ModularReductionScheme(DatapathScheme):
    """`R ≡ T * factor (mod q)`. Subclasses write `reduceInto(dp, t)` and
    `factor()`; the base adds the input, the final correction and the output.

    `q=` builds one modulus into the hardware. `family=` (a run-time
    `ModulusFamily`) builds it for every member of a family instead: the
    constants the reduction needs (`qPorts()`: q, mu, q', qH, k or c) become
    input ports, the products by them run on `qBackend` ('dsp', 'booth' or
    'behavioural', each product within `qDspBudget` DSPs if given), and the
    final correction subtracts multiples of the trial's own q (`qcorrect`).
    A family supports a run-time form only where it has one (`runtimeKinds`)."""

    dataInputNames = ('T',)
    inputNames = ('T',)
    outputNames = ('R',)
    family = 'undefined'
    #: Which run-time `ModulusFamily` kinds this reduction can be built for.
    runtimeKinds: tuple[str, ...] = ()

    def __init_subclass__(cls, **kw):
        # Run `_afterInit` once the outermost __init__ of the instance returns,
        # when every subclass parameter is set: the modulus ports' bounds need them.
        super().__init_subclass__(**kw)
        init = cls.__dict__.get('__init__')
        if init is None:
            return

        def wrapped(self, *a, _init=init, **k):
            depth = getattr(self, '_initDepth', 0)
            self._initDepth = depth + 1
            try:
                _init(self, *a, **k)
            finally:
                self._initDepth = depth
            if depth == 0:
                self._afterInit()
        wrapped.__doc__ = init.__doc__
        cls.__init__ = wrapped

    def __init__(self, name: str = 'Undefined reduction', q: int = 0,
                 tIn: IntType = IntType(0, 0, 0), outputRange='exact',
                 constBackend: str = 'lut', targetFmaxMhz: float | None = None,
                 absorbSmall: bool = True, tInValues=None, family: ModulusFamily | None = None,
                 qBackend: str = 'dsp', qDspBudget: int | None = None, tRel=None,
                 staticModulus: bool = False):
        super().__init__(name, targetFmaxMhz=targetFmaxMhz, absorbSmall=absorbSmall,
                         tIn=tIn, tInValues=tInValues)
        if family is not None and family.runtime and family.kind not in type(self).runtimeKinds:
            raise ValueError(f'{name}: {type(self).__name__} has no run-time form for '
                             f'{family.describe()} (it supports {type(self).runtimeKinds or "none"})')
        if family is None:
            family = ModulusFamily.fixed(q)
        elif q and not (family.kind == 'fixed' and family.qMax == q):
            raise ValueError(f'{name}: give q= or family=, not both')
        if not (outputRange in OUTPUT_RANGES or (isinstance(outputRange, int) and outputRange >= 1)):
            raise ValueError(f"{name}: outputRange must be 'exact', 'lazy' or an int >= 1")
        if constBackend not in ('lut', 'dsp', 'booth', 'behavioural'):
            raise ValueError(f'{name}: constBackend {constBackend!r}')
        if qBackend not in ('dsp', 'booth', 'behavioural'):
            raise ValueError(f'{name}: qBackend {qBackend!r}')
        self.modulusFamily = family
        self.runtime = family.runtime
        self.q = None if self.runtime else family.qMax
        self.n = family.n
        self.outputRange = 1 if outputRange == 'exact' else outputRange
        self.constBackend = constBackend
        self.qBackend = qBackend
        self.qDspBudget = qDspBudget
        self._qspecs: dict = {}
        self._tRel = tRel
        self.staticModulus = bool(staticModulus) and self.runtime

    def _afterInit(self) -> None:
        if not self.runtime:
            return
        if self.modulusFamily.kind not in self.runtimeKinds:
            raise ValueError(f'{self.name}: {type(self).__name__} has no run-time form for '
                             f'{self.modulusFamily.describe()} (it supports {self.runtimeKinds or "none"})')
        self._qspecs = {n: (b, fn) for n, b, fn in self._qPortSpecs()}
        self.inputNames = tuple(self.dataInputNames) + tuple(self._qspecs)
        for n, (b, _) in self._qspecs.items():
            setattr(self, self._boundAttr(n), b)
            if not hasattr(self, self._valueAttr(n)):
                setattr(self, self._valueAttr(n), None)

    # --- what a family supplies --------------------------------------------

    def factor(self, q: int | None = None) -> int:
        """`R ≡ T * factor (mod q)` (for a run-time family, of member `q`)."""
        return 1

    def reduceInto(self, dp: Datapath, t: str) -> str:
        """Add the reduction's nodes after wire `t`; return the native result."""
        raise NotImplementedError(f'{type(self).__name__} must implement reduceInto(dp, t)')

    def _qPortSpecs(self) -> list:
        """A run-time reduction's modulus ports: `(name, bound, value(q))`."""
        return []

    # --- the modulus, fixed or on ports -------------------------------------

    def qPorts(self) -> tuple[str, ...]:
        return tuple(self._qspecs)

    def qPortBound(self, port: str) -> IntType:
        return self._qspecs[port][0]

    def qPortValues(self, q: int) -> dict[str, int]:
        if not self.modulusFamily.contains(q):
            raise ValueError(f'{self.name}: {q} is not in {self.modulusFamily.describe()}')
        return {n: fn(q) for n, (_, fn) in self._qspecs.items()}

    def declareQPorts(self, dp: Datapath) -> None:
        self.trackRelative(dp)
        for n, (b, _) in self._qspecs.items():
            if n not in dp.bounds:
                dp.input(n, b, rel=self.qPortRel(n), static=self.staticModulus, shared=True)

    # --- bounds relative to the trial's q (core/relbound.py) -------------------

    def trackRelative(self, dp: Datapath) -> None:
        '''Make `dp` track bounds relative to the run-time q (once).'''
        if self.runtime and dp.relq is None:
            qmin, qmax = self.qMinMax()
            ports = self.qPorts()
            dp.setRelative(qmin, qmax, lambda env, i: self.qOfTrial({p: env[p][i] for p in ports}))

    def qPortRel(self, port: str) -> Rel | None:
        '''A modulus port's value as a function of q.'''
        p = self.modulusFamily.p
        if port == 'Q':
            return Rel(Poly.q(), Poly.q())
        if port == 'QH':
            x = (Poly.q() - Poly.const(1)).scale(Fraction(1, 2 ** p['v']))
            return Rel(x, x)
        if port == 'K':
            x = (Poly.q() - Poly.const(1)).scale(Fraction(1, 2 ** p['m']))
            return Rel(x, x)
        if port == 'C':
            x = Poly.const(2 ** p['n']) - Poly.q()
            return Rel(x, x)
        return None

    def tRel(self) -> Rel | None:
        '''T's bound relative to the trial's q: given (`tRel=`), or read off a
        static bound that is the family-wide form of one (`[0, (q-1)^2]`,
        `[-(q-1)^2, (q-1)^2]`, `[0, k*q - 1]`).'''
        if not self.runtime:
            return None
        if self._tRel is False:
            return None
        if self._tRel is not None:
            return self._tRel
        return relativeForm(self.tIn, self.qMinMax()[1])

    def qOfTrial(self, trial: dict) -> int:
        """The modulus of one trial, from its modulus ports."""
        if not self.runtime:
            return self.q
        fam, p = self.modulusFamily, self.modulusFamily.p
        if 'Q' in trial:
            return trial['Q']
        if fam.kind == 'friendly':
            return (trial['QH'] << p['v']) + 1
        if fam.kind == 'kred':
            return (trial['K'] << p['m']) + 1
        if fam.kind == 'pseudomersenne':
            return (1 << p['n']) - trial['C']
        raise KeyError(f'{self.name}: no modulus port in {sorted(trial)}')

    def qWire(self, dp: Datapath) -> str:
        """The wire carrying the trial's q: the `Q` port, or q rebuilt from the
        family's own constant (`QH << v | 1`, `K << m | 1`, `2^n - C`)."""
        self.declareQPorts(dp)
        if 'Q' in self._qspecs:
            return 'Q'
        if 'q_rt' in dp.bounds:
            return 'q_rt'
        fam, p = self.modulusFamily, self.modulusFamily.p
        qb = IntType(fam.qMin, fam.qMax)
        if fam.kind == 'friendly':
            terms = [dp.whole('QH', shift=p['v']), Datapath.const(1)]
        elif fam.kind == 'kred':
            terms = [dp.whole('K', shift=p['m']), Datapath.const(1)]
        elif fam.kind == 'pseudomersenne':
            terms = [Datapath.const(1 << p['n']), dp.whole('C', sign=-1)]
        else:
            raise KeyError(f'{self.name}: no way to rebuild q for {fam.describe()}')
        return dp.heap('q_rt', terms, bound=qb, note=f'q from {fam.describe()}')

    def qMinMax(self) -> tuple[int, int]:
        return self.modulusFamily.qMin, self.modulusFamily.qMax

    # --- shared building blocks ----------------------------------------------

    def constProduct(self, dp: Datapath, name: str, src: str, c: int, note: str = '') -> str:
        """`src * c` (c > 0) on the configured constant-multiplier backend."""
        if self.constBackend == 'lut':
            return dp.constMult(name, src, c, note=note)
        return dp.mult(name, src, bConst=c, backend=self.constBackend, note=note)

    def lowProduct(self, dp: Datapath, name: str, src: str, c: int, bits: int,
                   lo: int = 0, note: str = '') -> str:
        """`(src[..:lo] * c) mod 2^bits` — a partial product: on LUTs the heap is
        simply truncated at `bits` columns, so the upper half is never built."""
        if self.constBackend == 'lut':
            terms = dp.nafTermsOf(src, c, lo=lo, hi=lo + bits - 1, shift=-lo)
            return dp.heap(name, terms, wrapBits=bits, note=note)
        s = dp.heap(f'{name}_in', [dp.slice(src, lo, lo + bits - 1)], note='operand slice') \
            if (lo or dp.width(src) > bits) else src
        p = dp.mult(f'{name}_full', s, bConst=c, backend=self.constBackend, note=note)
        return dp.heap(name, [dp.slice(p, 0, bits - 1)], wrapBits=bits, note='low half')

    def qProduct(self, dp: Datapath, name: str, src: str, port: str, note: str = '') -> str:
        """`src * port` for a run-time constant: a multiplier on `qBackend`."""
        return dp.mult(name, src, port, backend=self.qBackend, dspBudget=self.qDspBudget, note=note)

    def lowQProduct(self, dp: Datapath, name: str, src: str, port: str, bits: int,
                    lo: int = 0, note: str = '') -> str:
        """`(src[lo+bits-1:lo] * port) mod 2^bits` with a run-time constant."""
        s = dp.heap(f'{name}_in', [dp.slice(src, lo, lo + bits - 1)], note='operand slice') \
            if (lo or dp.width(src) > bits) else src
        p = self.qProduct(dp, f'{name}_full', s, port, note=note)
        return dp.heap(name, [dp.slice(p, 0, bits - 1)], wrapBits=bits, note='low half')

    def nonnegative(self, dp: Datapath, t: str) -> str:
        """A signed input lifted by a multiple of q, for the families that need
        T >= 0 (Barrett, Montgomery, table lookup). Congruence is unchanged."""
        b = dp.bound(t)
        if b.minValue >= 0:
            return t
        if self.runtime:
            qmin, qmax = self.qMinMax()
            k = -(b.minValue // qmin)
            kq = dp.qmultiple(f'{t}_liftq', self.qWire(dp), k)
            return dp.heap(f'{t}_pos', [dp.whole(t), dp.whole(kq)],
                           bound=IntType(b.minValue + k * qmin, b.maxValue + k * qmax), note=f'+{k}q')
        k = -(b.minValue // self.q)
        return dp.heap(f'{t}_pos', [dp.whole(t), Datapath.const(k * self.q)],
                       bound=IntType(b.minValue + k * self.q, b.maxValue + k * self.q),
                       note=f'+{k}q')

    def liftedBound(self, b: IntType) -> IntType:
        """The bound `nonnegative` leaves (for parameters chosen before building)."""
        if b.minValue >= 0:
            return b
        if self.runtime:
            qmin, qmax = self.qMinMax()
            k = -(b.minValue // qmin)
            return IntType(b.minValue + k * qmin, b.maxValue + k * qmax)
        k = -(b.minValue // self.q)
        return IntType(b.minValue + k * self.q, b.maxValue + k * self.q)

    def finish(self, dp: Datapath, r: str) -> str:
        """The final correction `outputRange` asks for."""
        if self.outputRange == 'lazy':
            return r
        b = dp.bound(r)
        step = self.outputRange
        note = 'exact' if step == 1 else f'lazy [0,{step}q)'
        if self.runtime:
            if b.minValue >= 0 and b.maxValue < step * self.qMinMax()[0]:
                return r
            return dp.qcorrect(f'{r}_c', r, self.qWire(dp), step=step, note=note)
        if b.minValue >= 0 and b.maxValue < step * self.q:
            return r
        return dp.correct(f'{r}_c', r, self.q, step=step, note=note)

    # --- DatapathScheme ------------------------------------------------------

    def _build(self, dp: Datapath) -> None:
        self.trackRelative(dp)
        t = dp.input('T', self.tIn, rel=self.tRel())
        self.declareQPorts(dp)
        r = self.finish(dp, self.reduceInto(dp, t))
        dp.output('R', r)

    def factorFor(self, q: int) -> int:
        '''The factor of member `q` (fixed q: `factor()`, so a custom
        reduction written as `def factor(self)` still works).'''
        return self.factor(q) if self.runtime else self.factor()

    def reference(self, T: int, **ports) -> dict:
        q = self.qOfTrial(ports)
        return {'R': (T * self.factorFor(q)) % q}

    def acceptsOutput(self, port: str, got: int, want: int) -> bool:
        return self._accepts(got, want, self.q)

    def acceptsTrial(self, port: str, got: int, want: int, trial: dict) -> bool:
        return self._accepts(got, want, self.qOfTrial(trial))

    def _accepts(self, got: int, want: int, q: int) -> bool:
        if (got - want) % q:
            return False
        if self.outputRange == 'lazy':
            return True
        return 0 <= got < self.outputRange * q

    def cornersFor(self, port: str, q: int) -> list[int]:
        b = getattr(self, self._boundAttr(port))
        cand = [b.minValue, b.maxValue, 0, 1, q - 1, q, q + 1, 2 * q - 1, 2 * q,
                (q - 1) ** 2, (q - 1) ** 2 - 1, q * q, b.maxValue - 1, b.minValue + 1, -1, -q,
                1 << (self.n - 1), (1 << self.n) - 1, 1 << self.n]
        return self._legal(b, cand)

    def inputCorners(self, port: str) -> list[int]:
        return self.cornersFor(port, self.q)

    def sampleInputs(self, n: int, rng, corners: bool = True) -> dict:
        if not self.runtime:
            return super().sampleInputs(n, rng, corners)
        rels = {'T': self.tRel()}
        return sampleTrials(self, n, rng, corners, self.modulusFamily, self.qPortValues,
                            self.dataInputNames, self.cornersFor, relData=rels, staticQ=self.staticModulus)

    def params(self) -> dict:
        p = {'family': self.family, 'modulus': self.modulusFamily.params(),
             'q': self.q, 'logq': self.n,
             'outputRange': 'exact' if self.outputRange == 1 else self.outputRange,
             'constBackend': self.constBackend, 'tIn': [self.tIn.minValue, self.tIn.maxValue]}
        if self.runtime:
            p.update(qPorts=list(self.qPorts()), qBackend=self.qBackend, qDspBudget=self.qDspBudget,
                     staticModulus=self.staticModulus)
        else:
            p['factor'] = self.factor()
        return p


# =============================================================================
# Barrett
# =============================================================================

class BarrettReduction(ModularReductionScheme):
    '''`qhat = ((T >> s1) * mu) >> s2`, `mu = floor(2^(s1+s2) / q)`,
    `R = T - qhat*q`.

    The two shifts are the design-time parameters of the generalised Barrett
    reduction (Kim et al., the paper's [27]): classic Barrett is `s1 = n-1,
    s2 = n+1`; the default `s1 = n-2, s2 = bits(T) - n + 3` keeps the quotient
    error at most one, so the native output is [0, 2q). The error bound `E` is
    computed exactly from the parameters (`quotientError`), not assumed, and the
    value path asserts it on every sample.

    `truncate=d` drops the quotient product's columns below `d` (a truncated
    multiplier: fewer LUTs, a slightly larger error, which `quotientError`
    includes). `R` is built as a partial product: only its low bits exist.
    '''

    family = 'barrett'
    runtimeKinds = ('odd', 'friendly', 'kred', 'pseudomersenne', 'table')

    def __init__(self, *args, s1: int | None = None, s2: int | None = None,
                 truncate: int = 0, **kwargs):
        super().__init__(*args, **kwargs)
        self._s1, self._s2 = s1, s2
        self.truncate = truncate
        if self.runtime and truncate:
            raise ValueError(f'{self.name}: a truncated quotient needs mu as a constant (fixed q)')

    # Run time: ports Q and MU = floor(2^(s1+s2) / q). The shifts are fixed by
    # the family's width and the (lifted) input bound; the quotient error is
    # bounded over the whole family (`quotientError`).

    def _qPortSpecs(self) -> list:
        s1, s2 = self.shifts(self.liftedBound(self.tIn))
        qmin, qmax = self.qMinMax()
        e = s1 + s2
        self._muExp = e
        return [('Q', IntType(qmin, qmax), lambda q: q),
                ('MU', IntType((1 << e) // qmax, (1 << e) // qmin), lambda q, e=e: (1 << e) // q)]

    def qPortRel(self, port: str):
        if port == 'MU':                     # floor(2^e / q)
            x = Poly.q(-1, 2 ** self._muExp)
            return Rel(x - Poly.const(1), x)
        return super().qPortRel(port)

    def shifts(self, tBound: IntType) -> tuple[int, int]:
        if self.runtime and self.modulusFamily.kind == 'table':
            return self._tableShifts(tBound)
        tb = _bitsOf(tBound)
        s1 = self._s1 if self._s1 is not None else max(self.n - 2, 0)
        s2 = self._s2 if self._s2 is not None else max(tb - self.n + 3, 1)
        return s1, s2

    # A modulus table (`ModulusFamily.table`) may mix widths (Kim et al.: q0 of 61 bits, q1..q41 of 51-52).
    # The error has a term T mod 2^s1 / q, so s1 follows the smallest member (bits(qMin) - 2), and s2 the
    # largest T >> s1 of any member: each member's own T bound (its relative form, e.g. (q-1)^2) and its own
    # mu and rho are used, exactly, so the quotient error is the worst member's, not a family-wide estimate.

    def _memberTMax(self, q: int, tBound: IntType) -> int:
        rel = self.tRel()
        if rel is None:
            return tBound.maxValue
        lift = 0
        if self.tIn.minValue < 0:               # `nonnegative` adds k*q, k from qMin
            lift = -(self.tIn.minValue // self.qMinMax()[0]) * q
        return min(tBound.maxValue, int(rel.U.at(q)) + lift)

    def _memberError(self, q: int, s1: int, s2: int, tBound: IntType) -> int:
        mu = (1 << (s1 + s2)) // q
        rho = (1 << (s1 + s2)) - mu * q
        tmax = self._memberTMax(q, tBound)
        t1max, t0max = tmax >> s1, min((1 << s1) - 1, tmax)
        return (((1 << s2) - 1) * q + t1max * rho + t0max * (1 << s2)) // (q * (1 << s2))

    def _tableShifts(self, tBound: IntType) -> tuple[int, int]:
        key = (tBound.minValue, tBound.maxValue)
        cache = self.__dict__.setdefault('_tableShiftCache', {})
        if key not in cache:
            ms = self.modulusFamily.p['moduli']
            s1 = self._s1 if self._s1 is not None else max(ms[0].bit_length() - 2, 0)
            if self._s2 is not None:
                s2 = self._s2
            else:
                s2 = 1
                while max(self._memberError(q, s1, s2, tBound) for q in ms) > 1:
                    s2 += 1
            cache[key] = (s1, s2)
        return cache[key]

    def quotientError(self, tBound: IntType) -> tuple[int, int]:
        '''`(under, over)`: how far `qhat` can fall below `floor(T/q)` and rise
        above it, for this input bound and these parameters. For a run-time
        family, the worst member: with rho <= q - 1 the error bound is
        a + b/q for constants a, b, so one end of [qMin, qMax] is the worst.'''
        if self.runtime and self.modulusFamily.kind == 'table':
            s1, s2 = self.shifts(tBound)
            return max(self._memberError(q, s1, s2, tBound) for q in self.modulusFamily.p['moduli']), 0
        if self.runtime:
            s1, s2 = self.shifts(tBound)
            tmax = tBound.maxValue
            t1max, t0max = tmax >> s1, min((1 << s1) - 1, tmax)
            worst = 0
            for q in self.qMinMax():
                u = ((1 << s2) - 1) * q + t1max * (q - 1) + t0max * (1 << s2)
                worst = max(worst, u // (q * (1 << s2)))
            return worst, 0
        q = self.q
        s1, s2 = self.shifts(tBound)
        mu = (1 << (s1 + s2)) // q
        rho = (1 << (s1 + s2)) - mu * q
        tmax = tBound.maxValue
        t1max = tmax >> s1
        t0max = min((1 << s1) - 1, tmax)
        under = ((1 << s2) - 1) * q + t1max * rho + t0max * (1 << s2)
        under //= q * (1 << s2)
        dpos, dneg = self._truncationError(mu, t1max)
        under += -(-dpos // (1 << s2))
        over = -(-dneg // (1 << s2))
        return under, over

    def _truncationError(self, mu: int, t1max: int) -> tuple[int, int]:
        d = self.truncate
        if d <= 0:
            return 0, 0
        dpos = dneg = 0
        for s, e in nafTerms(mu):
            drop = 0 if e >= d else min((1 << (d - e)) - 1, t1max) * (1 << e)
            if s > 0:
                dpos += drop
            else:
                dneg += drop
        return dpos, dneg

    def reduceInto(self, dp: Datapath, t: str) -> str:
        if self.runtime:
            return self._reduceRuntime(dp, t)
        t = self.nonnegative(dp, t)
        tb = dp.bound(t)
        q = self.q
        s1, s2 = self.shifts(tb)
        mu = (1 << (s1 + s2)) // q
        if tb.maxValue < q:
            return t
        t1max = tb.maxValue >> s1
        t1min = tb.minValue >> s1
        dpos, dneg = self._truncationError(mu, t1max)
        if self.constBackend == 'lut':
            terms = []
            for s, e in nafTerms(mu):
                lo = s1 + max(0, self.truncate - e)
                term = dp.slice(t, lo, None, shift=max(e, self.truncate) if self.truncate else e, sign=s)
                if term is not None:
                    terms.append(term)
            x = dp.heap('bq', terms, bound=IntType(t1min * mu - dpos, t1max * mu + dneg),
                        note=f'(T>>{s1})*mu, mu={mu}' + (f', truncated below {self.truncate}' if self.truncate else ''))
        else:
            t1 = dp.heap('bt1', [dp.slice(t, s1, None)], bound=IntType(t1min, t1max), note=f'T>>{s1}')
            x = dp.mult('bq', t1, bConst=mu, backend=self.constBackend, note=f'mu={mu}')
        xb = dp.bound(x)
        qh = dp.heap('bqhat', [dp.slice(x, s2, None)],
                     bound=IntType(xb.minValue >> s2, xb.maxValue >> s2), note=f'>>{s2}')
        under, over = self.quotientError(tb)
        rlo = max(-over * q, tb.minValue - (dp.bound(qh).maxValue * q))
        rhi = min((under + 1) * q - 1, tb.maxValue)
        rb = IntType(rlo, rhi)
        if self.constBackend == 'lut':
            terms = [dp.whole(t)] + dp.nafTermsOf(qh, q, sign=-1)
            return dp.heap('br', terms, bound=rb, note='T - qhat*q, low bits only')
        p = dp.mult('bqq', qh, bConst=q, backend=self.constBackend, note='qhat*q')
        return dp.heap('br', [dp.whole(t), dp.whole(p, sign=-1)], bound=rb,
                       note='T - qhat*q, low bits only')

    def _reduceRuntime(self, dp: Datapath, t: str) -> str:
        t = self.nonnegative(dp, t)
        tb = dp.bound(t)
        qmin, qmax = self.qMinMax()
        s1, s2 = self.shifts(tb)
        if (s1, s2) != self.shifts(self.liftedBound(self.tIn)):
            raise AssertionError(f'{self.name}: MU was sized for other shifts')
        if tb.maxValue < qmin:
            return t
        t1 = dp.heap('bt1', [dp.slice(t, s1, None)], bound=tb >> s1, note=f'T>>{s1}')
        x = self.qProduct(dp, 'bq', t1, 'MU', note='(T>>s1)*mu')
        qh = dp.heap('bqhat', [dp.slice(x, s2, None)], bound=dp.bound(x) >> s2, note=f'>>{s2}')
        under, _ = self.quotientError(tb)
        p = self.qProduct(dp, 'bqq', qh, 'Q', note='qhat*q')
        rb = IntType(0, min((under + 1) * qmax - 1, tb.maxValue))
        return dp.heap('br', [dp.whole(t), dp.whole(p, sign=-1)], bound=rb, note='T - qhat*q',
                       relBound=Rel(Poly.const(0), Poly.q(1, under + 1) - Poly.const(1)))

    def params(self) -> dict:
        p = super().params()
        tb = self.liftedBound(self.tIn) if self.runtime else self.tIn
        s1, s2 = self.shifts(tb)
        p.update(s1=s1, s2=s2, truncate=self.truncate, quotientError=self.quotientError(tb))
        if not self.runtime:
            p['mu'] = (1 << (s1 + s2)) // self.q
        return p


# =============================================================================
# Montgomery
# =============================================================================

class MontgomeryReduction(ModularReductionScheme):
    '''`m = (T mod R) * q' mod R`, `R_out = (T + m*q) / R`, `q' = -q^-1 mod R`.

    `R = 2^rBits` (default the smallest power of two above q). Output
    `≡ T * R^-1`; in [0, 2q) when `T < q*R`. A modular multiplier with a
    constant operand pre-scales the constant by `R` so its output is `a*w mod q`
    (`ModularMultiplierScheme(absorbFactor=True)`).'''

    family = 'montgomery'
    runtimeKinds = ('odd', 'friendly', 'kred', 'pseudomersenne', 'table')

    def __init__(self, *args, rBits: int | None = None, **kwargs):
        super().__init__(*args, **kwargs)
        qmax = self.modulusFamily.qMax
        if not self.runtime and self.q % 2 == 0:
            raise ValueError(f'{self.name}: Montgomery needs an odd modulus')
        self.rBits = rBits if rBits is not None else self.n
        if (1 << self.rBits) <= qmax:
            raise ValueError(f'{self.name}: R = 2^{self.rBits} must exceed q')

    def factor(self, q: int | None = None) -> int:
        return pow(1 << self.rBits, -1, q if q is not None else self.q)

    # Run time: ports Q and QP = -q^-1 mod R; both products on a multiplier.

    def _qPortSpecs(self) -> list:
        qmin, qmax = self.qMinMax()
        r = self.rBits
        return [('Q', IntType(qmin, qmax), lambda q: q),
                ('QP', IntType(1, (1 << r) - 1), lambda q, r=r: (-pow(q, -1, 1 << r)) % (1 << r))]

    def reduceInto(self, dp: Datapath, t: str) -> str:
        if self.runtime:
            t = self.nonnegative(dp, t)
            r = self.rBits
            qmin, qmax = self.qMinMax()
            m = self.lowQProduct(dp, 'mm', t, 'QP', r, note="(T mod R)*q' mod R")
            mq = self.qProduct(dp, 'mmq', m, 'Q', note='m*q')
            sb = dp.bound(t) + IntType(0, (1 << r) - 1) * IntType(qmin, qmax)
            s = dp.heap('ms', [dp.whole(t), dp.whole(mq)], bound=sb, note='T + m*q')
            return dp.heap('mt', [dp.slice(s, r, None)], bound=sb >> r, note=f'/2^{r}')
        t = self.nonnegative(dp, t)
        r, q = self.rBits, self.q
        qp = (-pow(q, -1, 1 << r)) % (1 << r)
        m = self.lowProduct(dp, 'mm', t, qp, r, note=f"(T mod R)*q' mod R, q'={qp}")
        tb = dp.bound(t)
        sb = tb + IntType(0, (1 << r) - 1) * q
        if self.constBackend == 'lut':
            s = dp.heap('ms', [dp.whole(t)] + dp.nafTermsOf(m, q), bound=sb, note='T + m*q')
        else:
            mq = dp.mult('mmq', m, bConst=q, backend=self.constBackend, note='m*q')
            s = dp.heap('ms', [dp.whole(t), dp.whole(mq)], bound=sb, note='T + m*q')
        return dp.heap('mt', [dp.slice(s, r, None)], bound=sb >> r, note=f'/2^{r}')

    def params(self) -> dict:
        p = super().params()
        p.update(rBits=self.rBits)
        return p


# =============================================================================
# Word-level Montgomery (Mert et al.) for NTT-friendly primes
# =============================================================================

class WordLevelMontgomery(ModularReductionScheme):
    """Word-level Montgomery steps: `R ≡ T * 2^(-sum w_i)`.

    For an NTT-friendly prime `q = qH*2^v + 1` the Montgomery constant is
    `q' = -q^-1 ≡ -1 (mod 2^w)` for every `w <= v`, so a step of width `w_i`
    needs no multiplication by `q'`, only by `q >> w_i = qH * 2^(v - w_i)`:

      'negate'   m = -T_L mod 2^w_i,  T <- T_H + m*(q >> w_i) + [T_L != 0]   (Mert et al.)
      'flag'     T <- T_H - T_L*(q >> w_i) + [T_L != 0]*q                     (no negation:
                 the same identity, m*(q>>w) + c = [T_L != 0]*q - T_L*(q>>w))
      'generic'  any odd q: m = T_L*q' mod 2^w_i, T <- (T + m*q) >> w_i

    The arrangement of the steps is a design choice:

      w=, iterations=        L equal steps of w bits (the original form; L
                             defaults to ceil(n / w))
      qhBits=h               the width of qH, so v = n - h: the widest step
                             that keeps q' = -1 (a fixed q must satisfy
                             q = 1 mod 2^v); the steps then follow
      arrangement=           'greedy' (v, v, ..., the rest), 'balanced'
                             (L = ceil(n / v) steps as equal as possible, each
                             <= v: the narrowest m and so the smallest
                             products), or 'equal' (L steps of v)
      stepWidths=[w_0, ...]  any list, each <= v ('negate', 'flag')

    The sum of the widths is R's exponent; it should reach n (the default
    arrangements make it n or more) for the native output to stay near [0, 2q),
    and the bound path shows what any arrangement leaves.

    Run time: with `family=ModulusFamily.friendly(v, qhBits)` the only port is
    `QH` (q is rebuilt as QH << v | 1 for the corrections), each step multiplies
    `m * QH` on `qBackend` and shifts by v - w_i ('negate'); with
    `family=ModulusFamily.odd(...)` the 'generic' variant takes `Q` and
    `QP = -q^-1 mod 2^max(w_i)`."""

    family = 'wlm'
    runtimeKinds = ('friendly', 'odd')

    def __init__(self, *args, w: int | None = None, iterations: int | None = None,
                 variant: str | None = None, qhBits: int | None = None,
                 arrangement: str | None = None, stepWidths=None, **kwargs):
        super().__init__(*args, **kwargs)
        fam = self.modulusFamily
        n = self.n
        if fam.kind != 'fixed' and fam.kind != 'friendly' and variant not in (None, 'generic'):
            raise ValueError(f'{self.name}: {fam.describe()} has no q = 1 mod 2^w; use variant="generic"')
        if not self.runtime and self.q % 2 == 0:
            raise ValueError(f'{self.name}: Montgomery needs an odd modulus')
        # v: the 2-adicity the steps may use
        if fam.kind == 'friendly':
            v = fam.p['v']
            if qhBits is not None and qhBits != fam.p['qhBits']:
                raise ValueError(f'{self.name}: qhBits is the family\'s ({fam.p["qhBits"]})')
            friendly = True
        elif self.runtime:
            v, friendly = None, False
        else:
            q = self.q
            val = ((q - 1) & -(q - 1)).bit_length() - 1
            if qhBits is not None:
                v = n - qhBits
                if v < 1:
                    raise ValueError(f'{self.name}: qhBits={qhBits} leaves no step width')
            elif w is not None:
                v = w
            elif stepWidths is not None or arrangement is not None:
                v = val                          # the widest step this q allows
            else:
                v = 32
            friendly = v <= val
            if qhBits is not None and not friendly and variant != 'generic':
                raise ValueError(f'{self.name}: q - 1 = 2^{val} * odd, so qhBits >= {n - val}')
        self.variant = variant or ('flag' if friendly and not self.runtime else
                                   ('negate' if friendly else 'generic'))
        if self.variant not in ('negate', 'flag', 'generic'):
            raise ValueError(f'{self.name}: unknown variant {self.variant!r}')
        if self.variant in ('negate', 'flag') and not friendly:
            raise ValueError(f'{self.name}: variant {self.variant!r} needs q = 1 (mod 2^w); use variant="generic"')
        if self.runtime and self.variant == 'flag':
            raise ValueError(f'{self.name}: the flag variant gates q by a bit; at run time use "negate"')
        self.v = v
        # the arrangement of the steps
        if stepWidths is not None:
            widths = [int(x) for x in stepWidths]
            if arrangement is not None or iterations is not None:
                raise ValueError(f'{self.name}: give stepWidths or an arrangement, not both')
        elif qhBits is None and arrangement is None and fam.kind != 'friendly':
            ww = w if w is not None else 32
            widths = [ww] * (iterations if iterations is not None else -(-n // ww))
        else:
            cap = v if v is not None else (w if w is not None else 32)
            arr = arrangement or 'greedy'
            L = iterations if iterations is not None else -(-n // cap)
            if arr == 'greedy':
                widths = [cap] * (L - 1) + [max(1, n - cap * (L - 1))]
            elif arr == 'balanced':
                base, extra = divmod(n, L)
                widths = [base + 1] * extra + [base] * (L - extra)
            elif arr == 'equal':
                widths = [cap] * L
            else:
                raise ValueError(f'{self.name}: arrangement {arr!r} not greedy/balanced/equal')
        if not widths or min(widths) < 1:
            raise ValueError(f'{self.name}: step widths {widths}')
        if self.variant in ('negate', 'flag') and max(widths) > v:
            raise ValueError(f'{self.name}: a step of {max(widths)} bits needs q = 1 mod 2^{max(widths)}, '
                             f'but only 2^{v} is guaranteed')
        self.stepWidths = tuple(widths)
        self.w = max(widths)
        self.iterations = len(widths)
        self.qhBits = (n - v) if v is not None else None

    def factor(self, q: int | None = None) -> int:
        q = q if q is not None else self.q
        return pow(1 << sum(self.stepWidths), -1, q)

    def _qPortSpecs(self) -> list:
        fam = self.modulusFamily
        qmin, qmax = self.qMinMax()
        if fam.kind == 'friendly':
            return [('QH', IntType(fam.p['qhMin'], (1 << fam.p['qhBits']) - 1), lambda q, v=fam.p['v']: q >> v)]
        W = self.w
        return [('Q', IntType(qmin, qmax), lambda q: q),
                ('QP', IntType(1, (1 << W) - 1), lambda q, W=W: (-pow(q, -1, 1 << W)) % (1 << W))]

    def reduceInto(self, dp: Datapath, t: str) -> str:
        if self.runtime:
            return self._reduceRuntime(dp, t)
        q = self.q
        for i, w in enumerate(self.stepWidths):
            tb = dp.bound(t)
            qHi = q >> w                         # = qH * 2^(v - w) for a friendly q
            if self.variant == 'generic':
                tt = self.nonnegative(dp, t) if i == 0 else t
                qp = (-pow(q, -1, 1 << w)) % (1 << w)
                m = self.lowProduct(dp, f'w{i}m', tt, qp, w, note=f"T_L*q' mod 2^{w}")
                sb = dp.bound(tt) + IntType(0, (1 << w) - 1) * q
                s = dp.heap(f'w{i}s', [dp.whole(tt)] + dp.nafTermsOf(m, q), bound=sb, note='T + m*q')
                t = dp.heap(f'w{i}t', [dp.slice(s, w, None)], bound=sb >> w, note=f'>>{w}')
                continue
            tH = dp.slice(t, w, None)
            hb = (tb >> w) if tH is not None else IntType(0, 0)
            nz = dp.nonzero(f'w{i}nz', t, 0, w - 1, note='T_L != 0')
            low = IntType(0, (1 << w) - 1)
            if self.variant == 'negate':
                m = dp.heap(f'w{i}m', [dp.slice(t, 0, w - 1, sign=-1)], wrapBits=w, note='-T_L mod 2^w')
                terms = ([tH] if tH else []) + dp.nafTermsOf(m, qHi) + [dp.whole(nz)]
                bound = hb + low * qHi + IntType(0, 1)
            else:
                terms = ([tH] if tH else []) + dp.nafTermsOf(t, qHi, lo=0, hi=w - 1, shift=0, sign=-1) \
                    + dp.nafTermsOf(nz, q)
                bound = hb - low * qHi + IntType(0, 1) * q
            t = dp.heap(f'w{i}t', terms, bound=bound, note=f'word step {i}, {w} bits ({self.variant})')
        return t

    def _reduceRuntime(self, dp: Datapath, t: str) -> str:
        fam = self.modulusFamily
        qmin, qmax = self.qMinMax()
        if self.variant == 'generic':
            qw = self.qWire(dp)
            for i, w in enumerate(self.stepWidths):
                tt = self.nonnegative(dp, t) if i == 0 else t
                qp = dp.heap(f'w{i}qp', [dp.slice('QP', 0, w - 1)], note=f"q' mod 2^{w}") \
                    if w < self.w else 'QP'
                m = self.lowQProduct(dp, f'w{i}m', tt, qp, w, note=f"T_L*q' mod 2^{w}")
                mq = self.qProduct(dp, f'w{i}mq', m, qw, note='m*q')
                sb = dp.bound(tt) + IntType(0, (1 << w) - 1) * IntType(qmin, qmax)
                s = dp.heap(f'w{i}s', [dp.whole(tt), dp.whole(mq)], bound=sb, note='T + m*q')
                t = dp.heap(f'w{i}t', [dp.slice(s, w, None)], bound=sb >> w, note=f'>>{w}')
            return t
        self.declareQPorts(dp)
        v = fam.p['v']
        qhb = self.qPortBound('QH')
        for i, w in enumerate(self.stepWidths):
            tb = dp.bound(t)
            tH = dp.slice(t, w, None)
            hb = (tb >> w) if tH is not None else IntType(0, 0)
            nz = dp.nonzero(f'w{i}nz', t, 0, w - 1, note='T_L != 0')
            m = dp.heap(f'w{i}m', [dp.slice(t, 0, w - 1, sign=-1)], wrapBits=w, note='-T_L mod 2^w')
            mq = self.qProduct(dp, f'w{i}mq', m, 'QH', note='m*qH')
            terms = ([tH] if tH else []) + [dp.whole(mq, shift=v - w), dp.whole(nz)]
            bound = hb + IntType(0, (1 << w) - 1) * qhb * (1 << (v - w)) + IntType(0, 1)
            t = dp.heap(f'w{i}t', terms, bound=bound, note=f'word step {i}, {w} bits (negate, run-time qH)')
        return t

    def params(self) -> dict:
        p = super().params()
        p.update(w=self.w, iterations=self.iterations, stepWidths=list(self.stepWidths),
                 variant=self.variant, v=self.v, qhBits=self.qhBits)
        if not self.runtime:
            p['qH'] = self.q >> self.w
        return p


# =============================================================================
# K-RED / K2-RED (Liu et al., for q = k*2^m + 1 with small k)
# =============================================================================

class KRedReduction(ModularReductionScheme):
    '''`T = T_H*2^m + T_L  ->  k*T_L - T_H  ≡ k*T (mod q)` for `q = k*2^m + 1`.

    One step costs a constant multiplication by the small `k` and a
    subtraction; `steps` steps (K2-RED is two) give `R ≡ T * k^steps`, so the
    factor is `k^steps` (a constant twiddle absorbs it, as with Montgomery).
    Signed throughout. Fits NTT-friendly primes with a small `k` (Kyber's
    3329 = 13*2^8 + 1, 7681 = 15*2^9 + 1, 998244353 = 119*2^23 + 1).'''

    family = 'kred'
    runtimeKinds = ('kred',)

    def __init__(self, *args, m: int | None = None, steps: int = 2, **kwargs):
        super().__init__(*args, **kwargs)
        self.steps = steps
        if self.runtime:
            fm = self.modulusFamily.p['m']
            if m is not None and m != fm:
                raise ValueError(f'{self.name}: m is the family\'s ({fm})')
            self.m, self.k = fm, None
            return
        q = self.q
        self.m = m if m is not None else ((q - 1) & -(q - 1)).bit_length() - 1
        if (q - 1) % (1 << self.m):
            raise ValueError(f'{self.name}: q - 1 is not a multiple of 2^{self.m}')
        self.k = (q - 1) >> self.m

    def factor(self, q: int | None = None) -> int:
        q = q if q is not None else self.q
        return pow((q - 1) >> self.m, self.steps, q)

    # Run time: q = k*2^m + 1 with the port K; each step multiplies T_L by K.

    def _qPortSpecs(self) -> list:
        p = self.modulusFamily.p
        return [('K', IntType(p['kMin'], (1 << p['kBits']) - 1), lambda q, m=self.m: (q - 1) >> m)]

    def reduceInto(self, dp: Datapath, t: str) -> str:
        if self.runtime:
            m = self.m
            kb = self.qPortBound('K')
            for i in range(self.steps):
                b = dp.bound(t)
                hi = dp.slice(t, m, None, sign=-1)
                tl = dp.heap(f'k{i}l', [dp.slice(t, 0, m - 1)], note='T_L')
                kt = self.qProduct(dp, f'k{i}p', tl, 'K', note='k*T_L')
                bound = IntType(0, (1 << m) - 1) * kb - ((b >> m) if hi is not None else IntType(0, 0))
                t = dp.heap(f'k{i}', [dp.whole(kt)] + ([hi] if hi is not None else []), bound=bound,
                            note='k*T_L - T_H, run-time k')
            return t
        m, k = self.m, self.k
        for i in range(self.steps):
            b = dp.bound(t)
            hi = dp.slice(t, m, None, sign=-1)
            bound = IntType(0, (1 << m) - 1) * k - ((b >> m) if hi is not None else IntType(0, 0))
            terms = dp.nafTermsOf(t, k, lo=0, hi=m - 1, shift=0) + ([hi] if hi is not None else [])
            t = dp.heap(f'k{i}', terms, bound=bound, note=f'k*T_L - T_H, k={k}')
        return t

    def params(self) -> dict:
        p = super().params()
        p.update(m=self.m, k=self.k, steps=self.steps)
        return p


# =============================================================================
# Folding: special moduli, and any modulus with a sparse 2^k mod q
# =============================================================================

def sparseResidue(power: int, q: int, maxTerms: int = 3, lift: bool = True) -> tuple[int, list]:
    '''A representative `c ≡ 2^power (mod q)` with a short NAF: the residue, the
    residue minus q, or (with `lift`) a modulus-lifted one from
    `nafTermsModulusLift` (the constant multipliers' search). Returns
    `(c, naf)`; smaller magnitude wins a tie.'''
    r = pow(2, power, q)
    # Magnitude first: a fold only shrinks the value when |c| is well below
    # 2^power; among equally small candidates the shorter NAF wins.
    best = [(abs(c).bit_length(), len(nafTerms(c)), c) for c in (r, r - q) if c != 0] or [(0, 0, 0)]
    if lift:
        try:
            lifted, naf, cnt, _ = nafTermsModulusLift(r, q, maxPower=q.bit_length() + 2,
                                                      maxMultipleOfModulus=4, maxSearchDepth=2,
                                                      beamWidth=50, maxNumberOfTerms=maxTerms)
            best.append((abs(lifted).bit_length(), len(naf), lifted))
        except Exception:                                   # noqa: BLE001
            pass
    best.sort()
    c = best[0][2]
    return c, nafTerms(c)


class FoldReduction(ModularReductionScheme):
    '''`T = sum_j T[p_j : p_(j+1)-1] * 2^(p_j)  ≡  T_0 + sum_j T_j * c_j`, with
    `c_j ≡ 2^(p_j) (mod q)` chosen sparse: one heap per round, rounds repeated
    until the value is within `stopBits` (default n+1) bits or stops shrinking.

    With one fold point `p = n` this is the pseudo-Mersenne / Solinas
    reduction (`2^n ≡ c`); with several it is the limb table the Goldilocks
    butterfly uses. Signed inputs are fine: the top limb carries the sign. This
    is the codebase's "LUT-based sparsity": the constants cost what their NAF
    costs, nothing for the modulus as such.'''

    family = 'fold'

    def __init__(self, *args, foldPoints=None, limbBits: int | None = None,
                 maxTerms: int = 3, maxRounds: int = 6, stopBits: int | None = None,
                 lift: bool = False, **kwargs):
        super().__init__(*args, **kwargs)
        self.foldPoints = tuple(foldPoints) if foldPoints else None
        self.limbBits = limbBits
        self.maxTerms = maxTerms
        self.maxRounds = maxRounds
        self.stopBits = stopBits if stopBits is not None else self.n + 1
        self.lift = lift
        self._resCache: dict = {}

    def residue(self, p: int) -> tuple[int, list]:
        if p not in self._resCache:
            self._resCache[p] = sparseResidue(p, self.q, self.maxTerms, self.lift)
        return self._resCache[p]

    def points(self, width: int) -> list[int]:
        if self.foldPoints:
            return [p for p in self.foldPoints if p < width]
        step = self.limbBits or (width - self.n)
        step = max(step, 1)
        pts, p = [], self.n
        while p < width:
            pts.append(p)
            p += step
        return pts

    def reduceInto(self, dp: Datapath, t: str) -> str:
        for rnd in range(self.maxRounds):
            b = dp.bound(t)
            width = dp.width(t)
            if max(abs(b.minValue), abs(b.maxValue)).bit_length() <= self.stopBits:
                break
            pts = self.points(width)
            if not pts:
                break
            terms = [dp.slice(t, 0, pts[0] - 1)]
            bound = IntType(0, min((1 << pts[0]) - 1, max(b.maxValue, 0)))
            for j, p in enumerate(pts):
                end = pts[j + 1] - 1 if j + 1 < len(pts) else None
                c, naf = self.residue(p)
                limbBound = (b >> p) if end is None else IntType(0, (1 << (end - p + 1)) - 1)
                bound = bound + limbBound * c
                for sg, e in naf:
                    terms.append(dp.slice(t, p, end, shift=e, sign=sg))
            if bound.bitWidth >= width:
                raise ValueError(
                    f'{self.name}: folding at {pts} does not shrink a {width}-bit value '
                    f'(2^p mod q is not small enough: {[self.residue(p)[0] for p in pts]}); '
                    f'this modulus is not special enough for a fold -- use Barrett, '
                    f'Montgomery or a table-lookup reduction')
            t = dp.heap(f'f{rnd}', [x for x in terms if x is not None], bound=bound,
                        note=f'fold at {pts}: ' + ', '.join(f'2^{p}={self.residue(p)[0]}' for p in pts))
        return t

    def params(self) -> dict:
        p = super().params()
        p.update(foldPoints=self.foldPoints, limbBits=self.limbBits, maxTerms=self.maxTerms,
                 stopBits=self.stopBits)
        return p


class MersenneReduction(FoldReduction):
    '''`q = 2^n - 1`: `2^n ≡ 1`, a fold is `T_lo + T_hi`.'''

    family = 'mersenne'

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.q != (1 << self.n) - 1:
            raise ValueError(f'{self.name}: {self.q} is not 2^n - 1')
        self.foldPoints = None
        self.limbBits = self.n


class SolinasReduction(FoldReduction):
    '''`q = 2^n - c` with `c` sparse (pseudo-Mersenne, Solinas): fold at
    multiples of `n`. A one-term `c` is a pseudo-Mersenne prime.'''

    family = 'solinas'
    runtimeKinds = ('pseudomersenne',)

    def __init__(self, *args, **kwargs):
        kwargs.setdefault('lift', False)
        super().__init__(*args, **kwargs)
        if self.limbBits is None and self.foldPoints is None:
            self.limbBits = self.n

    # Run time (pseudo-Mersenne family q = 2^n - c, c < 2^cBits): 2^n = c (mod q),
    # so a round is T_lo + T_hi * C with the port C; rounds until the value is
    # within `stopBits`.

    def _qPortSpecs(self) -> list:
        p = self.modulusFamily.p
        return [('C', IntType(1, (1 << p['cBits']) - 1), lambda q, n=p['n']: (1 << n) - q)]

    def reduceInto(self, dp: Datapath, t: str) -> str:
        if not self.runtime:
            return super().reduceInto(dp, t)
        n = self.modulusFamily.p['n']
        cb = self.qPortBound('C')
        for rnd in range(self.maxRounds):
            b = dp.bound(t)
            width = dp.width(t)
            if max(abs(b.minValue), abs(b.maxValue)).bit_length() <= self.stopBits or width <= n:
                break
            hb = b >> n
            hi = dp.heap(f'f{rnd}h', [dp.slice(t, n, None)], bound=hb, note='T_hi')
            hc = self.qProduct(dp, f'f{rnd}c', hi, 'C', note='T_hi*c')
            bound = IntType(0, min((1 << n) - 1, max(b.maxValue, 0))) + hb * cb
            if bound.bitWidth >= width:
                raise ValueError(f'{self.name}: a fold by c < 2^{cb.bitWidth} does not shrink a {width}-bit value')
            t = dp.heap(f'f{rnd}', [dp.slice(t, 0, n - 1), dp.whole(hc)], bound=bound,
                        note=f'T_lo + T_hi*c (2^{n} = c)')
        return t


GOLDILOCKS = 2 ** 64 - 2 ** 32 + 1


class GoldilocksReduction(FoldReduction):
    '''The Goldilocks limb table `GoldilocksSlice64` bakes in: fold points 64,
    96, 128, 160 with `2^64 ≡ 2^32 - 1`, `2^96 ≡ -1`, `2^128 ≡ -2^32`,
    `2^160 ≡ -2^32 + 1` (and `2^192 ≡ 1`). For a 128-bit product this is the
    textbook `t0 + t1*(2^32 - 1) - t2`.'''

    family = 'goldilocks'
    TABLE = {64: 2 ** 32 - 1, 96: -1, 128: -(2 ** 32), 160: -(2 ** 32) + 1, 192: 1}

    def __init__(self, *args, **kwargs):
        kwargs.setdefault('q', GOLDILOCKS)
        kwargs['foldPoints'] = (64, 96, 128, 160, 192)
        kwargs.setdefault('stopBits', 65)
        super().__init__(*args, **kwargs)
        if self.q != GOLDILOCKS:
            raise ValueError(f'{self.name}: GoldilocksReduction is for q = 2^64 - 2^32 + 1')

    def residue(self, p: int) -> tuple[int, list]:
        c = self.TABLE[p]
        return c, nafTerms(c)


# =============================================================================
# Table lookup
# =============================================================================

class TableLookupReduction(ModularReductionScheme):
    '''`T = T_lo + sum_j chunk_j * 2^(k + j*c)  ≡  T_lo + sum_j table_j[chunk_j]`,
    `table_j[x] = (x * 2^(k + j*c)) mod q`: every `c`-bit chunk above bit `k`
    indexes a LUT ROM of residues, and the residues are summed with `T_lo` in
    one compressor — the "compressor with integrated table look-up" of the
    framework sheet. Rounds repeat until the value is within `stopBits`
    (default n+1) bits; `chunkBits <= 6` keeps every table bit one LUT6.'''

    family = 'table'

    def __init__(self, *args, chunkBits: int = 6, foldBits: int | None = None,
                 maxRounds: int = 4, stopBits: int | None = None, **kwargs):
        super().__init__(*args, **kwargs)
        self.chunkBits = chunkBits
        self.foldBits = foldBits if foldBits is not None else self.n
        self.maxRounds = maxRounds
        self.stopBits = stopBits if stopBits is not None else self.n + 1

    def reduceInto(self, dp: Datapath, t: str) -> str:
        t = self.nonnegative(dp, t)
        q, k, c = self.q, self.foldBits, self.chunkBits
        for rnd in range(self.maxRounds):
            b = dp.bound(t)
            width = dp.width(t)
            if b.maxValue.bit_length() <= self.stopBits or width <= k:
                break
            terms = [dp.slice(t, 0, k - 1)]
            bound = IntType(0, min((1 << k) - 1, b.maxValue))
            j, pos = 0, k
            while pos < width:
                hi = min(pos + c - 1, width - 1)
                vals = [(x << pos) % q for x in range(1 << (hi - pos + 1))]
                tbl = dp.table(f't{rnd}_{j}', t, pos, hi, vals, note=f'2^{pos} residues')
                terms.append(dp.whole(tbl))
                bound = bound + dp.bound(tbl)
                j += 1
                pos = hi + 1
            t = dp.heap(f't{rnd}', terms, bound=bound, note=f'{j} tables + T_lo')
        return t

    def params(self) -> dict:
        p = super().params()
        p.update(chunkBits=self.chunkBits, foldBits=self.foldBits, stopBits=self.stopBits)
        return p


# =============================================================================
# The custom-reduction template
# =============================================================================

class CustomReduction(ModularReductionScheme):
    '''The template for a user's own reduction (the paper's "code template").

    Subclass, then write two methods with the datapath primitives:

        class MyReduction(CustomReduction):
            def factor(self, q=None):    # R ≡ T * factor (mod q)
                return 1
            def reduceInto(self, dp, t):
                ...                       # dp.slice / dp.nafTermsOf / dp.heap /
                                          # dp.constMult / dp.mult / dp.table /
                                          # dp.nonzero / dp.correct
                return wire

    Bounds: pass `bound=` to a heap whenever the sum is narrower than the
    interval sum of its terms (an algebraic fact the node's author knows); the
    value path then asserts it on every sample, `runModMult.py`'s exhaustive
    small-modulus pass checks it on every input, and an unsound bound fails
    there before any RTL is written. Everything else — values, timing, cost, RTL,
    testbench, reference check — is inherited. `ShiftAddReduction` below is
    a worked example.
    '''

    family = 'custom'


class ShiftAddReduction(CustomReduction):
    '''Worked example of the template: a two-step fold written by hand for any
    `q` whose `2^n mod q` is sparse — the same idea as `FoldReduction`, spelled
    out in ten lines so the template is concrete.'''

    family = 'custom-shiftadd'

    def reduceInto(self, dp: Datapath, t: str) -> str:
        n, q = self.n, self.q
        c, naf = sparseResidue(n, q, lift=False)
        for i in range(2):
            b = dp.bound(t)
            hi = b >> n
            if hi.isZero and b.minValue >= 0:
                break
            terms = [dp.slice(t, 0, n - 1)] + [dp.slice(t, n, None, shift=e, sign=s) for s, e in naf]
            t = dp.heap(f'sa{i}', terms, bound=IntType(0, (1 << n) - 1) + hi * c, note=f'2^{n}≡{c}')
        return t
