'''The unified CT/GS butterfly: CT for DIR = 0, GS for DIR = 1, one multiplier.

    DIR = 0 (CT):  X = A + W*B,   Y = A - W*B
    DIR = 1 (GS):  X = A + B,     Y = (A - B)*W          (mod q)

One modular multiplier, one modular adder whose second operand is selected (W*B, or B) and two
modular subtracters that take A through a gate (2026-11-16):

    d = B - (DIR ? A : 0)      t = W*d      X = A + (DIR ? B : t)      Y = (DIR ? 0 : A) - t      (mod q)

so CT gives d = B, Y = A - W*B and GS gives d = B - A, Y = -(B - A)*W = (A - B)*W. One 2:1 select and one
modular subtracter more than a CT butterfly; the gates sit in the subtracters' own LUTs. The unit is
feed-forward (no subtracter is used at two times), so DIR may change with every beat.

Why: a fully pipelined NTT for both directions on one set of butterflies runs
the forward as CT with psi merged into the twiddles and the inverse as GS with
psi^-1 merged and x2^-1 per stage, so a negacyclic inverse needs no output
twist (n multipliers less). On the unrolled NTT the two directions use the same
stage wiring: hardware stage s pairs lanes l and l + 2^s; CT reads lane l as
memory index l, GS as memory index brv(l), so the port permutation is the same
for both directions (natural ports on both sides). See `UnrolledNTTScheme(unified=True)`.
'''
from __future__ import annotations

from ...core.IntType import IntType
from ...modmult.ModButterfly import ModularButterflyScheme
from .ButterflyScheme import ModularBU


class UnifiedButterflyScheme(ModularButterflyScheme):
    '''Ports A, B, W, DIR, [modulus ports]; outputs X, Y. Operands in [0, q) (exact outputs).'''

    def __init__(self, name: str = 'Undefined UnifiedButterflyScheme', **kw):
        # multiplierKind 'shoup': the one multiplier is Shoup's (ports W and WP = floor(W 2^beta / q)); its operand
        # is B or the exact difference A - B, both in [0, q), so beta = bits(q) as in the CT butterfly and one
        # companion serves both directions. `UnifiedBU` builds it with productRange 'exact' (Shoup's [0, 2q)
        # product, then one conditional subtraction), so X, Y and the stored words stay in [0, q).
        shoup = kw.get('multiplierKind', 'reduction') == 'shoup'
        if kw.get('constant') is not None:
            raise ValueError(f'{name}: the unified butterfly takes its twiddle as an input')
        kw['butterflyType'] = 'CT'          # the multiplier child is sized for B in [0, q)
        kw['differenceRange'] = 1
        super().__init__(name, **kw)
        self.dataInputNames = ('A', 'B', 'W', 'DIR')
        setattr(self, self._boundAttr('DIR'), IntType(0, 1))
        setattr(self, self._valueAttr('DIR'), None)
        if self.runtime:
            self._installPorts(self.dataInputNames, self._portChild._qspecs)
            if shoup:
                self.inputNames = ('A', 'B', 'W', 'WP', 'DIR') + tuple(self._qspecs)
                setattr(self, self._boundAttr('WP'), self._portChild.bpIn)
                setattr(self, self._valueAttr('WP'), kw.get('wpInValues'))
        else:
            self.inputNames = ('A', 'B', 'W', 'WP', 'DIR') if shoup else self.dataInputNames

    def _build(self, dp) -> None:
        a = self.relInput(dp, 'A')
        b = self.relInput(dp, 'B')
        self.relInput(dp, 'W')
        if self.multiplierKind == 'shoup':
            dp.input('WP', getattr(self, self._boundAttr('WP')))
        dp.input('DIR', IntType(0, 1))
        self.declareQPorts(dp)
        self.adderChildren = ()
        out = self.outputRange
        # 2026-11-16: the two subtracters take A through a gate, so no multiplexer sits in front of the multiplier
        # or behind the second subtracter (before: m = DIR ? A - B : B and Y = DIR ? W*m : A - W*B, two selects of
        # the word width that synthesis kept as separate LUTs, and delay lines around them).
        #   CT (DIR 0):  d = B - 0 = B        t = W*B          Y = A - t
        #   GS (DIR 1):  d = B - A  (mod q)   t = (B - A)*W    Y = 0 - t = (A - B)*W  (mod q)
        ga = dp.select('ga', 'DIR', a, None, note='GS: A, CT: 0')
        d = self._addsub(dp, b, ga, True, 'd', 'B - (DIR & A)', 1)
        t = self._modmul(dp, d)
        xo = dp.select('xo', 'DIR', b, t, note='GS: B, CT: W*B')
        dp.output('X', self._addsub(dp, a, xo, False, 'x', 'A + (B | W*B)', out))
        gb = dp.select('gb', 'DIR', None, a, note='GS: 0, CT: A')
        dp.output('Y', self._addsub(dp, gb, t, True, 'y', '(~DIR & A) - W*B', out))

    def reference(self, A: int, B: int, W: int | None = None, WP: int | None = None, DIR: int = 0, **ports) -> dict:
        q = self.qOfTrial(ports)
        w = W * self._twiddleFactor(q)
        if DIR & 1:
            return {'X': (A + B) % q, 'Y': ((A - B) * w) % q}
        return {'X': (A + w * B) % q, 'Y': (A - w * B) % q}

    def acceptsFor(self, port: str, got: int, want: int, q: int) -> bool:
        if (got - want) % q:
            return False
        if port == 'Y' and self.multiplierKind == 'shoup':
            # GS: Y is the multiplier's product as it is (its range); CT: the subtracter's (exact)
            return 0 <= got < max(1, self.multiplierChild.resultRange()) * q
        return 0 <= got < q

    def cornersFor(self, port: str, q: int) -> list[int]:
        if port == 'DIR':
            return [0, 1]
        return super().cornersFor(port, q)


class UnifiedBU(ModularBU):
    '''`ModularBU` with the unified CT/GS datapath; `direction` (0 CT, 1 GS) is the DIR value the
    value path drives when `portValues` has none.'''

    direction = 0

    def _build(self, aIn: IntType, bIn: IntType) -> UnifiedButterflyScheme:
        mod = dict(family=self.family, staticModulus=self.staticModulus) if self.family is not None else dict(q=self.q)
        return UnifiedButterflyScheme(
            name=self.name, aIn=aIn, bIn=bIn, wIn=self.portBounds.get('W'),
            multiplier=self.multiplier, dspBudget=self.dspBudget, constBackend=self.constBackend,
            reduction=self.reduction, reductionArgs=self.reductionArgs, multiplierKind=self.multiplierKind,
            beta=self.beta, productRange='exact',
            outputRange='exact', absorbFactor=self.absorbFactor, targetFmaxMhz=self.targetFmaxMhz,
            qBackend=self.qBackend, qDspBudget=self.qDspBudget, inRange=self.inRange, **mod)

    def _inputs(self) -> dict:
        if 'DIR' not in self.portValues and self.aInValues is not None:
            self.portValues = dict(self.portValues, DIR=[self.direction] * len(self.aInValues))
        return super()._inputs()
