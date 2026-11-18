'''The operators: `ModularMultiplier` (ports A[, B[, Bp]] -> P) and
`ModularReduction` (T -> R), each a `DatapathOperator` around its scheme.

    scheme = ModularMultiplierScheme(q=q, aIn=IntType(0, q - 1), bIn=IntType(0, q - 1),
                                     multiplier='dsp', reduction=MontgomeryReduction)
    op = ModularMultiplier('mm', scheme)
    op.drive([Signal(scheme.aIn, a), Signal(scheme.bIn, b)])
    op.compute()                                   # untimed: bounds and values
    op.emitRtl('mm64', 'work/mm/mm64', test_size=300)   # RTL, XDC, TB, vectors
'''
from __future__ import annotations

from ..core.DatapathOperator import DatapathOperator
from .ModMultScheme import ModularMultiplierScheme, ShoupModMult
from .ReductionScheme import ModularReductionScheme


class ModularMultiplier(DatapathOperator):
    def __init__(self, name: str = 'Undefined ModularMultiplier', scheme=None):
        if not isinstance(scheme, (ModularMultiplierScheme, ShoupModMult)):
            raise TypeError(f'{name}: scheme must be a ModularMultiplierScheme or ShoupModMult')
        super().__init__(name, scheme)


class ModularReduction(DatapathOperator):
    def __init__(self, name: str = 'Undefined ModularReduction', scheme=None):
        if not isinstance(scheme, ModularReductionScheme):
            raise TypeError(f'{name}: scheme must be a ModularReductionScheme')
        super().__init__(name, scheme)
