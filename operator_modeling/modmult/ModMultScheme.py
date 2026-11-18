'''Modular multipliers: a product, then a reduction — the composite owns both.

`ModularMultiplierScheme` is `P ≡ A * B * factor (mod q)` built as a datapath:

    product    A * B on a multiplier block   multiplier='dsp' | 'booth' | 'behavioural'
               A * w for a design-time       constant=w (a twiddle): a NAF constant
               constant                      multiplier on LUTs, or constBackend='dsp'
    reduction  any ModularReductionScheme    reduction=BarrettReduction (a class)
               family, built for the         reductionArgs={...} its parameters
               product's bound

Like `FullyPipelinedGrid` and `FourStepScheme`, the composite builds its
child: the reduction is constructed inside `_build` for whatever bound the
product has, so a lazy input range or a lifted constant changes the reduction's
parameters automatically. `self.reduction` is the child last built.

With a constant operand and a reduction whose factor is not 1 (Montgomery,
word-level Montgomery), `absorbFactor=True` (the default) pre-scales the
constant by the factor's inverse — the twiddle stored in Montgomery form — so
the output is `a*w mod q`. With two variable operands the factor stays in the
output and `reference` includes it.

`ShoupModMult` is the other shape: Harvey's precomputed-quotient multiplication
(`w' = floor(w * 2^beta / q)`), which needs no reduction child at all, with the
twiddle a design-time constant (three constant multipliers, no DSP) or a runtime
operand with its companion `B'` supplied on its own port.
'''
from __future__ import annotations

from ..core.IntType import IntType
from ..core.datapath import Datapath, DatapathScheme
from ..core.utils import nafTerms
from .ReductionScheme import BarrettReduction, ModularReductionScheme
from .runtimeq import RuntimeComposite

MULTIPLIERS = ('dsp', 'booth', 'behavioural')


class ModularMultiplierScheme(RuntimeComposite, DatapathScheme):
    """`P ≡ A * B * factor (mod q)` (or `A * w` with `constant=w`).

    `family=` (a run-time `ModulusFamily`) builds it for every member: the
    reduction child's modulus ports become this operator's ports after `A`,
    `B`; `qBackend` / `qDspBudget` place the child's products by them. A
    constant twiddle needs a fixed q."""

    family = 'modmult'

    def __init__(self, name: str = 'Undefined ModularMultiplierScheme', q: int = 0,
                 aIn: IntType = IntType(0, 0, 0), bIn: IntType | None = None,
                 constant: int | None = None, multiplier: str = 'dsp',
                 dspBudget: int | None = None, constBackend: str = 'lut',
                 reduction=BarrettReduction, reductionArgs: dict | None = None,
                 outputRange='exact', absorbFactor: bool = True,
                 targetFmaxMhz: float | None = None, absorbSmall: bool = True,
                 aInValues=None, bInValues=None, family=None, qBackend: str | None = None,
                 qDspBudget: int | None = None, inRange=None,
                 staticModulus: bool = False):
        self.constant = constant
        self.inRange = inRange
        self.staticModulus = staticModulus
        if constant is None:
            self.inputNames = self.dataInputNames = ('A', 'B')
            kw = dict(aIn=aIn, bIn=bIn if bIn is not None else IntType(0, 0, 0),
                      aInValues=aInValues, bInValues=bInValues)
        else:
            self.inputNames = self.dataInputNames = ('A',)
            kw = dict(aIn=aIn, aInValues=aInValues)
        self.outputNames = ('P',)
        super().__init__(name, targetFmaxMhz=targetFmaxMhz, absorbSmall=absorbSmall, **kw)
        self._setFamily(name, q, family)
        if self.modulusFamily.qMax < 3:
            raise ValueError(f'{name}: modulus must be >= 3')
        if multiplier not in MULTIPLIERS:
            raise ValueError(f'{name}: multiplier {multiplier!r} not in {MULTIPLIERS}')
        if not (isinstance(reduction, type) and issubclass(reduction, ModularReductionScheme)):
            raise TypeError(f'{name}: reduction must be a ModularReductionScheme subclass')
        if self.runtime and constant not in (None, 1):
            raise ValueError(f'{name}: a constant twiddle is a value of one q (except 1); a run-time family needs B')
        self.multiplier = multiplier
        self.dspBudget = dspBudget
        self.constBackend = constBackend
        self.reductionClass = reduction
        self.reductionArgs = dict(reductionArgs or {})
        if qBackend is not None:
            self.reductionArgs.setdefault('qBackend', qBackend)
        if qDspBudget is not None:
            self.reductionArgs.setdefault('qDspBudget', qDspBudget)
        self.outputRange = outputRange
        self.absorbFactor = absorbFactor
        self.reduction: ModularReductionScheme | None = None
        if constant is not None and not self.runtime and not 0 < constant < q:
            raise ValueError(f'{name}: constant must lie in (0, q)')
        if self.runtime:
            self._qSource = self._makeReduction(self.aIn * (self.bIn if constant is None else
                                                            IntType(0, self.modulusFamily.qMax - 1)))
            self._installPorts(self.dataInputNames, self._qSource._qspecs)

    # --- the child ------------------------------------------------------------

    def _makeReduction(self, tIn: IntType) -> ModularReductionScheme:
        args = dict(self.reductionArgs)
        args.setdefault('constBackend', self.constBackend)
        args.setdefault('outputRange', self.outputRange)
        mod = dict(family=self.modulusFamily, staticModulus=self.staticModulus) if self.runtime else dict(q=self.q)
        return self.reductionClass(name=f'{self.name}_red', tIn=tIn,
                                   targetFmaxMhz=self.targetFmaxMhz, **mod, **args)

    def reductionFactor(self, q: int | None = None) -> int:
        """The child's factor (built for the full-range product if not yet built)."""
        red = self.reduction or (self._qSource if self.runtime else
                                 self._makeReduction(IntType(0, (self.q - 1) ** 2)))
        return red.factorFor(q if q is not None else self.q)

    def effectiveConstant(self) -> int | None:
        """The constant the hardware multiplies by: the twiddle, pre-scaled
        into the reduction's domain when `absorbFactor`."""
        if self.constant is None:
            return None
        if self.runtime:
            return 1                     # only the constant 1 exists at run time
        f = self.reductionFactor()
        if self.absorbFactor and f != 1:
            return (self.constant * pow(f, -1, self.q)) % self.q
        return self.constant

    def outputFactor(self, q: int | None = None) -> int:
        """`P ≡ A * B * outputFactor (mod q)`."""
        if self.constant is not None and self.absorbFactor:
            return 1
        return self.reductionFactor(q)

    # --- DatapathScheme --------------------------------------------------------

    def _build(self, dp: Datapath) -> None:
        a = self.relInput(dp, 'A')
        b = None
        if self.constant is None:
            b = self.relInput(dp, 'B')
            self.declareQPorts(dp)
        dp.output('P', self.buildInto(dp, a, b))

    def buildInto(self, dp: Datapath, a: str, b: str | None = None, name: str = 't',
                  note: str | None = None) -> str:
        """The product and its reduction, added to `dp` (a parent's datapath,
        or this operator's own); returns the result wire. `a`, `b` are wires
        already in `dp` (`b` unused with `constant=`), and the reduction child
        is built for the product's bound there. A run-time modulus: the parent
        has declared this operator's modulus ports (`qPorts()`)."""
        if self.constant is None:
            t = dp.mult(name, a, b, backend=self.multiplier, dspBudget=self.dspBudget,
                        note=note or 'A*B')
        else:
            c = self.effectiveConstant()
            if self.constant == 1 and self.outputFactor() == 1:
                # a trivial twiddle (most of an NTT's first CT layer): P = A, so no
                # product and no reduction (whatever its factor: with the factor
                # absorbed, P = A * 1), only the correction the range still needs
                self.reduction = None
                b = dp.bound(a)
                if self.outputRange == 'lazy' and b.minValue >= 0:
                    return a
                step = 1 if self.outputRange in ('exact', 'lazy') else self.outputRange
                return self._correct(dp, f'{name}_c', a, step, self.qWireOf if self.runtime else None)
            if self.constBackend == 'lut':
                t = dp.constMult(name, a, c, note=note or f'A*{c}')
            else:
                t = dp.mult(name, a, bConst=c, backend=self.constBackend, dspBudget=self.dspBudget,
                            note=note or f'A*{c}')
        self.reduction = self._makeReduction(dp.bound(t))
        return self.reduction.finish(dp, self.reduction.reduceInto(dp, t))

    def reference(self, A: int, B: int | None = None, **ports) -> dict:
        q = self.qOfTrial(ports)
        b = self.constant if self.constant is not None else B
        return {'P': (A * b * self.outputFactor(q)) % q}

    def acceptsFor(self, port: str, got: int, want: int, q: int) -> bool:
        if (got - want) % q:
            return False
        r = self.reduction.outputRange if self.reduction else self.rangeWithoutReduction()
        return True if r == 'lazy' else 0 <= got < r * q

    def rangeWithoutReduction(self):
        '''The output range when the trivial-constant shortcut built no reduction.'''
        return 1 if self.outputRange == 'exact' else self.outputRange

    # --- the interface a composite (a butterfly) uses ------------------------
    #: the ports the second operand needs besides `A` (none with `constant=`)
    operandPorts = ('B',)

    def resultRange(self):
        '''The range `buildInto` leaves: k for [0, k*q), or 'lazy'.'''
        return self.reduction.outputRange if self.reduction is not None else self.rangeWithoutReduction()

    def qWireOf(self, dp: Datapath) -> str:
        '''The run-time q as a wire of `dp` (the reduction's: a port, or q rebuilt from QH).'''
        return self._qSource.qWire(dp)

    def qPortRel(self, port: str):
        return self._qSource.qPortRel(port)

    def cornersFor(self, port: str, q: int) -> list[int]:
        b = getattr(self, self._boundAttr(port))
        return self._legal(b, [0, 1, 2, q - 1, q - 2, q, q + 1, 2 * q - 1, b.maxValue,
                               b.maxValue - 1, b.minValue, (q - 1) // 2, (q + 1) // 2])

    def params(self) -> dict:
        red = self.reduction
        return {'family': self.family, 'modulus': self.modulusFamily.params(), 'q': self.q,
                'logq': self.modulusFamily.n,
                'aIn': [self.aIn.minValue, self.aIn.maxValue],
                'bIn': None if self.constant is not None else [self.bIn.minValue, self.bIn.maxValue],
                'constant': self.constant, 'effectiveConstant': self.effectiveConstant(),
                'multiplier': self.multiplier if self.constant is None else f'const/{self.constBackend}',
                'dspBudget': self.dspBudget, 'reduction': red.params() if red else None,
                'qPorts': list(self.qPorts()),
                'outputFactor': None if self.runtime else self.outputFactor(),
                'targetFmaxMhz': self.targetFmaxMhz}


class ShoupModMult(RuntimeComposite, DatapathScheme):
    """Harvey/Shoup: `qhat = (A * w') >> beta`, `P = A*w - qhat*q` in [0, 2q),
    `w' = floor(w * 2^beta / q)`, `beta = bits(A)` (needs `A < 2^beta`).

    With `constant=w` all three products are constant multipliers (`A*w'`
    kept above `beta`, `A*w` and `qhat*q` kept below the output width — partial
    products), so a twiddle multiplication needs no DSP. Without it, `B` and its
    precomputed companion `Bp = floor(B * 2^beta / q)` are runtime inputs and
    `A*Bp`, `A*B` go to a multiplier block. `outputRange='exact'` adds one
    conditional subtraction; `2` leaves the lazy [0, 2q).

    `family=` (run time): q arrives on port `Q` too, `qhat*Q` is a third
    product, and the correction subtracts the trial's q. `B` must be below the
    trial's q (Shoup's bound needs it), and the companion is the trial's."""

    family = 'shoup'

    def __init__(self, name: str = 'Undefined ShoupModMult', q: int = 0,
                 aIn: IntType = IntType(0, 0, 0), constant: int | None = None,
                 multiplier: str = 'dsp', dspBudget: int | None = None,
                 constBackend: str = 'lut', outputRange='exact', beta: int | None = None,
                 targetFmaxMhz: float | None = None, absorbSmall: bool = True,
                 bIn: IntType | None = None, aInValues=None, bInValues=None, bpInValues=None,
                 family=None, qBackend: str | None = None, qDspBudget: int | None = None, inRange=None,
                 staticModulus: bool = False):
        self.constant = constant
        self.inRange = inRange
        self.staticModulus = staticModulus
        if constant is None:
            self.inputNames = ('A', 'B', 'Bp')
            self.dataInputNames = ('A', 'B')
        else:
            self.inputNames = self.dataInputNames = ('A',)
        self.outputNames = ('P',)
        self._setFamily(name, q, family)
        qmin, qmax = self.qMinMax()
        if qmax < 3:
            raise ValueError(f'{name}: modulus must be >= 3')
        if self.runtime and constant not in (None, 1):
            raise ValueError(f'{name}: a constant twiddle is a value of one q (except 1); a run-time family needs B')
        self.beta = beta if beta is not None else max(aIn.maxValue, 1).bit_length()
        kw = dict(aIn=aIn, aInValues=aInValues)
        if constant is None:
            bb = bIn if bIn is not None else IntType(0, qmax - 1)
            if bb.minValue < 0 or bb.maxValue >= qmax:
                raise ValueError(f'{name}: B must lie in [0, q)')
            bpMax = (1 << self.beta) - 1 if self.runtime else ((q - 1) << self.beta) // q
            kw.update(bIn=bb, bInValues=bInValues, bpIn=IntType(0, bpMax), bpInValues=bpInValues)
        super().__init__(name, targetFmaxMhz=targetFmaxMhz, absorbSmall=absorbSmall, **kw)
        self._setFamily(name, q, family)
        if aIn.minValue < 0 or aIn.maxValue >= 1 << self.beta:
            raise ValueError(f'{name}: Shoup needs 0 <= A < 2^beta = 2^{self.beta}')
        if constant is not None and not self.runtime and not 0 < constant < q:
            raise ValueError(f'{name}: constant must lie in (0, q)')
        self.multiplier = multiplier
        self.dspBudget = dspBudget
        self.constBackend = constBackend
        self.qBackend = qBackend or multiplier
        self.qDspBudget = qDspBudget
        self.outputRange = 1 if outputRange == 'exact' else outputRange
        if self.runtime:
            data = ('A', 'B', 'Bp') if constant is None else ('A',)
            self._installPorts(data, {'Q': (IntType(qmin, qmax), lambda q: q)})
            self.dataInputNames = ('A', 'B') if constant is None else ('A',)

    def qOfTrial(self, trial: dict) -> int:
        return trial['Q'] if self.runtime else self.q

    def companion(self, b: int, q: int | None = None) -> int:
        return (b << self.beta) // (q if q is not None else self.q)

    def _perTrial(self, trial: dict, q: int, rng) -> None:
        if trial['B'] >= q:
            trial['B'] = trial['B'] % q
        trial['Bp'] = self.companion(trial['B'], q)

    # --- the interface a composite (a butterfly) uses ------------------------
    #: the ports the second operand needs besides `A`: the value and its companion
    operandPorts = ('B', 'Bp')
    reduction = None

    def outputFactor(self, q: int | None = None) -> int:
        return 1

    def reductionFactor(self, q: int | None = None) -> int:
        return 1

    def effectiveConstant(self) -> int | None:
        return self.constant

    def resultRange(self):
        return 2 if self.outputRange == 'lazy' else self.outputRange

    def qWireOf(self, dp: Datapath) -> str:
        return 'Q'

    def sampleInputs(self, n: int, rng, corners: bool = True) -> dict:
        '''As the base, then each trial's companion from its `B` (and `B` below q).'''
        ins = super().sampleInputs(n, rng, corners)
        if self.constant is None and not self.runtime:
            for i in range(n):
                t = {'B': ins['B'][i]}
                self._perTrial(t, self.q, rng)
                ins['B'][i], ins['Bp'][i] = t['B'], t['Bp']
        return ins

    def _build(self, dp: Datapath) -> None:
        a = self.relInput(dp, 'A')
        b = bp = None
        if self.constant is None:
            b = self.relInput(dp, 'B')
            bp = dp.input('Bp', self.bpIn)
            self.declareQPorts(dp)
        dp.output('P', self.buildInto(dp, a, b, bp))

    def buildInto(self, dp: Datapath, a: str, b: str | None = None, bp: str | None = None,
                  name: str = 's', note: str | None = None) -> str:
        '''`a * b mod q` (or `a * constant`) added to `dp`, a parent's datapath or
        this operator's own; returns the result wire. `b` and its companion `bp`
        are wires already in `dp`; `a` must lie in [0, 2^beta) (this operator
        built for `a`'s bound). A run-time q: the parent declared port `Q`.'''
        q, beta = self.q, self.beta
        qmax = self.qMinMax()[1]
        rb = IntType(0, 2 * qmax - 1)
        W = rb.bitWidth
        if self.constant == 1:
            # a trivial twiddle: P = A, only the correction the range needs
            if self.outputRange in ('lazy', 2) and 0 <= dp.bound(a).minValue and dp.bound(a).maxValue < 2 * qmax:
                return a
            return self._correct(dp, 'sr_c', a, 1 if self.outputRange == 'lazy' else self.outputRange, lambda dp: 'Q')
        if self.constant is not None:
            w = self.constant
            wp = self.companion(w)
            if self.constBackend == 'lut':
                x = dp.constMult('sx', a, wp, note=f"A*w', w'={wp}")
            else:
                x = dp.mult('sx', a, bConst=wp, backend=self.constBackend, note="A*w'")
            xb = dp.bound(x)
            hi = dp.slice(x, beta, None)
            qhTerms = []
            if hi is not None:
                qh = dp.heap('sqhat', [hi], bound=IntType(xb.minValue >> beta, xb.maxValue >> beta),
                             note=f'>>{beta}')
                qhTerms = dp.nafTermsOf(qh, q, sign=-1)
            terms = dp.nafTermsOf(a, w) + qhTerms
            r = dp.heap('sr', terms, bound=rb, note='A*w - qhat*q, low bits only')
        else:
            x = dp.mult('sx', a, bp, backend=self.multiplier, dspBudget=self.dspBudget, note="A*B'")
            xb = dp.bound(x)
            qh = dp.heap('sqhat', [dp.slice(x, beta, None)],
                         bound=IntType(xb.minValue >> beta, xb.maxValue >> beta), note=f'>>{beta}')
            ab = dp.mult('sab', a, b, backend=self.multiplier, dspBudget=self.dspBudget, note='A*B')
            if self.runtime:
                qq = dp.mult('sqq', qh, 'Q', backend=self.qBackend, dspBudget=self.qDspBudget, note='qhat*q')
                from ..core.relbound import Poly, Rel
                r = dp.heap('sr', [dp.slice(ab, 0, W - 1), dp.slice(qq, 0, W - 1, sign=-1)], bound=rb,
                            partial=True, note='A*B - qhat*q, low bits only',
                            relBound=Rel(Poly.const(0), Poly.q(1, 2) - Poly.const(1)))
            else:
                r = dp.heap('sr', [dp.slice(ab, 0, W - 1)] + dp.nafTermsOf(qh, q, sign=-1), bound=rb,
                            partial=True, note='A*B - qhat*q, low bits only')
        if self.outputRange != 'lazy' and self.outputRange < 2:
            if self.runtime:
                r = dp.qcorrect('sr_c', r, 'Q', step=self.outputRange)
            else:
                r = dp.correct('sr_c', r, q, step=self.outputRange)
        return r

    def reference(self, A: int, B: int | None = None, Bp: int | None = None, **ports) -> dict:
        b = self.constant if self.constant is not None else B
        return {'P': (A * b) % self.qOfTrial(ports)}

    def acceptsFor(self, port: str, got: int, want: int, q: int) -> bool:
        if (got - want) % q:
            return False
        return self.outputRange == 'lazy' or 0 <= got < self.outputRange * q

    def sampleInputs(self, n: int, rng, corners: bool = True) -> dict:
        """`Bp` is not free: it is the companion of `B`."""
        if self.runtime:
            return RuntimeComposite.sampleInputs(self, n, rng, corners)
        out = DatapathScheme.sampleInputs(self, n, rng, corners)
        if self.constant is None:
            out['Bp'] = [self.companion(b) for b in out['B']]
        return out

    def cornersFor(self, port: str, q: int) -> list[int]:
        b = getattr(self, self._boundAttr(port))
        return self._legal(b, [0, 1, q - 1, q, 2 * q - 1, b.maxValue, b.maxValue - 1, (q - 1) // 2])

    def params(self) -> dict:
        return {'family': self.family, 'modulus': self.modulusFamily.params(), 'q': self.q,
                'logq': self.modulusFamily.n, 'beta': self.beta,
                'constant': self.constant,
                'companion': self.companion(self.constant) if self.constant is not None else None,
                'multiplier': self.multiplier if self.constant is None else f'const/{self.constBackend}',
                'outputRange': 'exact' if self.outputRange == 1 else self.outputRange,
                'qPorts': list(self.qPorts()),
                'aIn': [self.aIn.minValue, self.aIn.maxValue], 'targetFmaxMhz': self.targetFmaxMhz}
