'''What a scheme spends on the FPGA, as one value that sums.

`areaCost()` returns `(LUT, DSP)`, which is the pair every LUT and DSP scheme
trades between and the pair the paper reports. A matrix transpose spends
neither: it is block RAM, plus the LUTs of its barrel shifters. Rather than
widen every `areaCost()` in the project, `resources()` reports this dataclass;
the base class derives it from `areaCost()` so nothing else has to change, and
the transpose schemes override it with their memories.

Flip-flops are deliberately absent. Nothing in the project counts them -- the
generators place registers by delay and never report them -- and a field that
one scheme filled and the rest left at zero would sum to a lie.
'''
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Resources:
    '''LUTs, DSP58s, BRAM36 and BRAM18 tiles. `+` sums fieldwise.'''

    lut: int = 0
    dsp: int = 0
    bram36: int = 0
    bram18: int = 0

    def __add__(self, other: 'Resources') -> 'Resources':
        if not isinstance(other, Resources):
            return NotImplemented
        return Resources(self.lut + other.lut, self.dsp + other.dsp,
                         self.bram36 + other.bram36, self.bram18 + other.bram18)

    __radd__ = __add__

    @property
    def bram36Equivalent(self) -> float:
        '''Block RAM as BRAM36 tiles, a BRAM18 counting as half of one.'''
        return self.bram36 + self.bram18 / 2

    def __str__(self) -> str:
        return (f'LUT {self.lut}, DSP {self.dsp}, BRAM36 {self.bram36}, '
                f'BRAM18 {self.bram18}')
