'''Modular adder / subtractor: `S = (A + B) mod q` or `(A - B) mod q`.

One heap (`A ± B`, two operands, so a plain adder) and one correction: the
correction's candidates follow from the inputs' bounds, so lazy inputs
(`[0, 2q)`, signed butterfly outputs) need no special casing, and
`outputRange=2` leaves a lazy [0, 2q). A butterfly built from these is the
textbook alternative to `GoldilocksSlice64`, which folds its additions into
its heaps instead.'''
from __future__ import annotations

from ..core.IntType import IntType
from ..core.datapath import Datapath, DatapathScheme
from .runtimeq import RuntimeComposite


class ModularAdderScheme(RuntimeComposite, DatapathScheme):
    """`S = (A ± B) mod q`; with `family=` (run time) q arrives on port `Q`
    and the correction subtracts multiples of the trial's q."""

    inputNames = ('A', 'B')
    dataInputNames = ('A', 'B')
    outputNames = ('S',)
    family = 'modadd'

    def __init__(self, name: str = 'Undefined ModularAdderScheme', q: int = 0,
                 aIn: IntType = IntType(0, 0, 0), bIn: IntType = IntType(0, 0, 0),
                 subtract: bool = False, outputRange='exact', targetFmaxMhz=None,
                 absorbSmall: bool = True, aInValues=None, bInValues=None, family=None, inRange=None,
                 staticModulus: bool = False):
        self.inRange = inRange
        self.staticModulus = staticModulus
        super().__init__(name, targetFmaxMhz=targetFmaxMhz, absorbSmall=absorbSmall,
                         aIn=aIn, bIn=bIn, aInValues=aInValues, bInValues=bInValues)
        self._setFamily(name, q, family)
        if self.modulusFamily.qMax < 3:
            raise ValueError(f'{name}: modulus must be >= 3')
        self.subtract = subtract
        self.outputRange = 1 if outputRange == 'exact' else outputRange
        if self.runtime:
            qmin, qmax = self.qMinMax()
            self._installPorts(self.dataInputNames, {'Q': (IntType(qmin, qmax), lambda q: q)})

    def qOfTrial(self, trial: dict) -> int:
        return trial['Q'] if self.runtime else self.q

    def _build(self, dp: Datapath) -> None:
        a = self.relInput(dp, 'A')
        b = self.relInput(dp, 'B')
        self.declareQPorts(dp)
        dp.output('S', self.buildInto(dp, a, b))

    def buildInto(self, dp: Datapath, a: str, b: str, name: str = 's', note: str | None = None,
                  qwireOf=None) -> str:
        """`a ± b` and its correction, added to `dp` (a parent's datapath, or
        this operator's own); returns the result wire. The bound comes from the
        wires' bounds in `dp`. `qwireOf(dp)`: the run-time q wire (default the
        port `Q`; a parent passes its own, e.g. q rebuilt from `QH`)."""
        sign = -1 if self.subtract else 1
        bound = dp.bound(a) - dp.bound(b) if self.subtract else dp.bound(a) + dp.bound(b)
        s = dp.heap(name, [dp.whole(a), dp.whole(b, sign=sign)], bound=bound,
                    note=note or ('A - B' if self.subtract else 'A + B'))
        if self.outputRange != 'lazy':
            s = self._correct(dp, f'{name}_c', s, self.outputRange, qwireOf or (lambda dp: 'Q'))
        return s

    def reference(self, A: int, B: int, **ports) -> dict:
        return {'S': ((A - B) if self.subtract else (A + B)) % self.qOfTrial(ports)}

    def acceptsFor(self, port: str, got: int, want: int, q: int) -> bool:
        if (got - want) % q:
            return False
        return self.outputRange == 'lazy' or 0 <= got < self.outputRange * q

    def cornersFor(self, port: str, q: int) -> list[int]:
        b = getattr(self, self._boundAttr(port))
        return self._legal(b, [0, 1, q - 1, q, 2 * q - 1, b.maxValue, b.minValue, -1, -q])

    def params(self) -> dict:
        return {'family': self.family, 'modulus': self.modulusFamily.params(), 'q': self.q,
                'logq': self.modulusFamily.n, 'subtract': self.subtract, 'qPorts': list(self.qPorts()),
                'outputRange': 'exact' if self.outputRange == 1 else self.outputRange}
