'''A generic-modulus NTT butterfly composed from the modular pieces.

`ModularButterflyScheme` is the butterfly unit (BU) of the AutoNTT paper's
Table VII: one modular multiplication and a modular add and subtract, for any
`q` and any reduction family, with the twiddle a runtime input `W` or a
design-time constant.

    CT:  X = A + W*B,   Y = A - W*B        (mod q)
    GS:  X = A + B,     Y = (A - B) * W    (mod q)

It is built from the modular operators, as the framework's hierarchy has it
(butterfly -> modular multiplier + modular adder/subtractor -> multiplier,
reduction, compressor): one `ModularMultiplierScheme` and two
`ModularAdderScheme` children, each built inside `_build` for the bounds its
inputs actually have and added into this operator's datapath with `buildInto`.
So a lazy product feeds the adders as it is, the adders' corrections see the
real bounds (in GS the difference stays signed and the reduction lifts it), and
the run-time q wire is shared. Contrast with `GoldilocksSlice64`, which folds
the multiplication by a <= 3-term twiddle and the Goldilocks reduction into the
same two heaps as the additions.
'''
from __future__ import annotations

from ..core.IntType import IntType
from ..core.datapath import Datapath, DatapathScheme
from .ModAddScheme import ModularAdderScheme
from .ModMultScheme import ModularMultiplierScheme, ShoupModMult
from .ReductionScheme import BarrettReduction, ModularReductionScheme
from .runtimeq import RuntimeComposite


#: the modular multipliers a butterfly can hold: `multiplierKind` -> scheme
MULTIPLIER_KINDS = {'reduction': ModularMultiplierScheme, 'shoup': ShoupModMult}


class ModularButterflyScheme(RuntimeComposite, DatapathScheme):
    """CT `X = A + W*B, Y = A - W*B` or GS `X = A + B, Y = (A - B)*W` (mod q).

    `multiplierKind` picks the modular multiplier: `'reduction'` (a product,
    then any `reduction=` class: Barrett, Montgomery, word-level Montgomery,
    K-RED, Mersenne/Solinas/fold, table, custom) or `'shoup'` (Shoup's
    precomputed quotient). The twiddle is a design-time `constant=` (fixed q)
    or ports: `W` (and `WP = floor(W * 2^beta / q)` for Shoup). q is fixed
    (`q=`) or a run-time `family=`; the multiplier's modulus ports (Q, MU, QP,
    QH, K, C ... whatever it needs) then follow the data ports, and the
    adders' corrections use the multiplier's q wire. Ports in order:
    `A, B, [W, [WP]], [modulus ports]`; outputs `X, Y`."""

    outputNames = ('X', 'Y')
    family = 'modbutterfly'

    def __init__(self, name: str = 'Undefined ModularButterflyScheme', q: int = 0,
                 butterflyType: str = 'CT', aIn: IntType = IntType(0, 0, 0),
                 bIn: IntType = IntType(0, 0, 0), wIn: IntType | None = None,
                 constant: int | None = None, multiplierKind: str = 'reduction',
                 multiplier: str = 'dsp', dspBudget: int | None = None, constBackend: str = 'lut',
                 reduction=BarrettReduction, reductionArgs: dict | None = None, beta: int | None = None,
                 productRange='exact', outputRange='exact', absorbFactor: bool = True,
                 targetFmaxMhz: float | None = None, absorbSmall: bool = True,
                 aInValues=None, bInValues=None, wInValues=None, wpInValues=None, family=None,
                 qBackend: str | None = None, qDspBudget: int | None = None, inRange=None,
                 staticModulus: bool = False, differenceRange=None):
        if multiplierKind not in MULTIPLIER_KINDS:
            raise ValueError(f'{name}: multiplierKind must be one of {sorted(MULTIPLIER_KINDS)}')
        if butterflyType not in ('CT', 'GS'):
            raise ValueError(f'{name}: butterflyType must be CT or GS')
        self.multiplierKind = multiplierKind
        self.butterflyType = butterflyType
        # GS: the range of A - B before the multiplier: None = 'lazy' (signed; Shoup: [0, 2q)),
        # or k = [0, k*q) (1: exact, the multiplier's operand as narrow as CT's B)
        if differenceRange not in (None, 'lazy', 1, 2, 'exact'):
            raise ValueError(f"{name}: differenceRange must be None, 'lazy', 'exact', 1 or 2")
        self.differenceRange = 1 if differenceRange == 'exact' else differenceRange
        if multiplierKind == 'shoup' and self.differenceRange == 'lazy':
            raise ValueError(f'{name}: Shoup needs a nonnegative operand (differenceRange 1 or 2)')
        self.constant = constant
        self.inRange = inRange
        self.staticModulus = staticModulus
        shoup = multiplierKind == 'shoup'
        if constant is not None:
            self.inputNames = self.dataInputNames = ('A', 'B')
        else:
            self.dataInputNames = ('A', 'B', 'W')
            self.inputNames = ('A', 'B', 'W', 'WP') if shoup else ('A', 'B', 'W')
        self._setFamily(name, q, family)
        if self.runtime and constant not in (None, 1):
            raise ValueError(f'{name}: a constant twiddle is a value of one q (except 1); a run-time family needs W')
        kw = dict(aIn=aIn, bIn=bIn, aInValues=aInValues, bInValues=bInValues)
        if constant is None:
            kw.update(wIn=wIn if wIn is not None else IntType(0, self.qMinMax()[1] - 1), wInValues=wInValues)
            if shoup:
                kw.update({self._boundAttr('WP'): IntType(0, 1),       # set from the child below
                           self._valueAttr('WP'): wpInValues})
        super().__init__(name, targetFmaxMhz=targetFmaxMhz, absorbSmall=absorbSmall, **kw)
        self._setFamily(name, q, family)
        if not (isinstance(reduction, type) and issubclass(reduction, ModularReductionScheme)):
            raise TypeError(f'{name}: reduction must be a ModularReductionScheme subclass')
        self.multiplier = multiplier
        self.dspBudget = dspBudget
        self.constBackend = constBackend
        self.reductionClass = reduction
        self.reductionArgs = dict(reductionArgs or {})
        self.beta = beta
        self.qBackend, self.qDspBudget = qBackend, qDspBudget
        if not shoup:
            if qBackend is not None:
                self.reductionArgs.setdefault('qBackend', qBackend)
            if qDspBudget is not None:
                self.reductionArgs.setdefault('qDspBudget', qDspBudget)
        self.productRange = productRange
        self.outputRange = 1 if outputRange == 'exact' else outputRange
        self.absorbFactor = absorbFactor
        self.reduction = None
        self.multiplierChild = None
        self.adderChildren: tuple = ()
        # the multiplier for the operand's full range: its ports and companions
        self._portChild = self._multiplierChild(self._operandBound())
        if shoup and self.beta is None:
            self.beta = self._portChild.beta     # every Shoup child shares it: WP is computed with it
        if shoup and constant is None:
            setattr(self, self._boundAttr('WP'), self._portChild.bpIn)
        if self.runtime:
            self._qSource = self._portChild
            self._installPorts(self.dataInputNames, self._portChild._qspecs)
            if shoup and constant is None:
                self.inputNames = ('A', 'B', 'W', 'WP') + tuple(self._qspecs)
                setattr(self, self._boundAttr('WP'), self._portChild.bpIn)
                setattr(self, self._valueAttr('WP'), wpInValues)

    # --- the children -----------------------------------------------------------

    def _mod(self) -> dict:
        return (dict(family=self.modulusFamily, staticModulus=self.staticModulus) if self.runtime
                else dict(q=self.q))

    def _operandBound(self) -> IntType:
        """The multiplier's data operand: B (CT), or A - B (GS; for Shoup moved
        into [0, 2q) first, since Shoup needs a nonnegative operand)."""
        if self.butterflyType == 'CT':
            return self.bIn
        k = self._differenceRange()
        if k != 'lazy':
            return IntType(0, k * self.qMinMax()[1] - 1)
        return self.aIn - self.bIn

    def _differenceRange(self):
        if self.differenceRange is not None:
            return self.differenceRange
        return 2 if self.multiplierKind == 'shoup' else 'lazy'

    def _multiplierChild(self, xIn: IntType):
        """`x * W` (or `x * constant`) reduced, for an operand bounded by `xIn`."""
        if self.multiplierKind == 'shoup':
            return ShoupModMult(
                name=f'{self.name}_mul', aIn=xIn, constant=self.constant,
                bIn=None if self.constant is not None else self.wIn, multiplier=self.multiplier,
                dspBudget=self.dspBudget, constBackend=self.constBackend,
                outputRange=self.productRange, beta=self.beta, targetFmaxMhz=self.targetFmaxMhz,
                qBackend=self.qBackend, qDspBudget=self.qDspBudget, **self._mod())
        return ModularMultiplierScheme(
            name=f'{self.name}_mul', aIn=xIn, bIn=None if self.constant is not None else self.wIn,
            constant=self.constant, multiplier=self.multiplier, dspBudget=self.dspBudget,
            constBackend=self.constBackend, reduction=self.reductionClass,
            reductionArgs=self.reductionArgs, outputRange=self.productRange,
            absorbFactor=self.absorbFactor, targetFmaxMhz=self.targetFmaxMhz, **self._mod())

    def _adderChild(self, aIn: IntType, bIn: IntType, subtract: bool, outputRange) -> ModularAdderScheme:
        return ModularAdderScheme(
            name=f'{self.name}_{"sub" if subtract else "add"}', aIn=aIn, bIn=bIn, subtract=subtract,
            outputRange='exact' if outputRange == 1 else outputRange,
            targetFmaxMhz=self.targetFmaxMhz, **self._mod())

    def factor(self, q: int | None = None) -> int:
        """The multiplier's factor: W*B is computed as W*B*factor (1 for Barrett
        and Shoup, R^-1 for the Montgomery family)."""
        return (self.multiplierChild or self._portChild).reductionFactor(q)

    def _twiddleFactor(self, q: int | None = None) -> int:
        """`W*B` is computed as `W*B*twiddleFactor`."""
        return 1 if (self.constant is not None and self.absorbFactor) else self.factor(q)

    def _qwire(self):
        return self._portChild.qWireOf if self.runtime else None

    def _modmul(self, dp: Datapath, x: str) -> str:
        m = self._multiplierChild(dp.bound(x))
        if self.constant is not None:
            r = m.buildInto(dp, x, name='mp', note=f'x*{m.effectiveConstant()}') if self.multiplierKind != 'shoup' \
                else m.buildInto(dp, x)
        elif self.multiplierKind == 'shoup':
            r = m.buildInto(dp, x, 'W', 'WP')
        else:
            r = m.buildInto(dp, x, 'W', name='mp', note='x*W')
        self.multiplierChild, self.reduction = m, m.reduction
        return r

    def _addsub(self, dp: Datapath, a: str, b: str, subtract: bool, name: str, note: str, outputRange) -> str:
        c = self._adderChild(dp.bound(a), dp.bound(b), subtract, outputRange)
        self.adderChildren += (c,)
        return c.buildInto(dp, a, b, name=name, note=note, qwireOf=self._qwire())

    def _build(self, dp: Datapath) -> None:
        a = self.relInput(dp, 'A')
        b = self.relInput(dp, 'B')
        if self.constant is None:
            self.relInput(dp, 'W')
            if self.multiplierKind == 'shoup':
                dp.input('WP', getattr(self, self._boundAttr('WP')))
        self.declareQPorts(dp)
        self.adderChildren = ()
        out = self.outputRange
        if self.butterflyType == 'CT':
            t = self._modmul(dp, b)
            dp.output('X', self._addsub(dp, a, t, False, 'x', 'A + Wb', out))
            dp.output('Y', self._addsub(dp, a, t, True, 'y', 'A - Wb', out))
        else:
            dp.output('X', self._addsub(dp, a, b, False, 'x', 'A + B', out))
            # Shoup needs its operand in [0, 2q); the others take the signed difference
            d = self._addsub(dp, a, b, True, 'd', 'A - B', self._differenceRange())
            dp.output('Y', self._modmul(dp, d))

    # --- trials -----------------------------------------------------------------

    def _companion(self, trial: dict, q: int) -> None:
        if self.multiplierKind == 'shoup' and self.constant is None:
            trial['W'] %= q
            trial['WP'] = self._portChild.companion(trial['W'], q)

    def _perTrial(self, trial: dict, q: int, rng) -> None:
        self._companion(trial, q)

    def sampleInputs(self, n: int, rng, corners: bool = True) -> dict:
        ins = super().sampleInputs(n, rng, corners)
        if not self.runtime and self.multiplierKind == 'shoup' and self.constant is None:
            for i in range(n):
                t = {'W': ins['W'][i]}
                self._companion(t, self.q)
                ins['W'][i], ins['WP'][i] = t['W'], t['WP']
        return ins

    def reference(self, A: int, B: int, W: int | None = None, WP: int | None = None, **ports) -> dict:
        q = self.qOfTrial(ports)
        w = (self.constant if self.constant is not None else W) * self._twiddleFactor(q)
        if self.butterflyType == 'CT':
            return {'X': (A + w * B) % q, 'Y': (A - w * B) % q}
        return {'X': (A + B) % q, 'Y': ((A - B) * w) % q}

    def acceptsFor(self, port: str, got: int, want: int, q: int) -> bool:
        if (got - want) % q:
            return False
        rng = self.outputRange
        if port == 'Y' and self.butterflyType == 'GS':
            rng = self.multiplierChild.resultRange()
        return rng == 'lazy' or 0 <= got < rng * q

    def cornersFor(self, port: str, q: int) -> list[int]:
        b = getattr(self, self._boundAttr(port))
        return self._legal(b, [0, 1, q - 1, q, 2 * q - 1, b.maxValue, b.minValue, (q - 1) // 2])

    def params(self) -> dict:
        m = self.multiplierChild
        return {'family': self.family, 'modulus': self.modulusFamily.params(), 'q': self.q,
                'logq': self.modulusFamily.n, 'multiplierKind': self.multiplierKind,
                'butterflyType': self.butterflyType, 'constant': self.constant,
                'multiplier': self.multiplier, 'reduction': self.reduction.params() if self.reduction else None,
                'qPorts': list(self.qPorts()),
                'outputRange': 'exact' if self.outputRange == 1 else self.outputRange,
                'targetFmaxMhz': self.targetFmaxMhz}
