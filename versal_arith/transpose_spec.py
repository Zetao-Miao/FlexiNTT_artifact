"""The data contract between a matrix-transpose scheme and its RTL generator.

Pure data, like `butterfly_spec.py`: `operator_modeling.transpose` builds it
from a populated scheme, `rtl_gen.transpose.Transpose_RTL_gen` consumes it.
"""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class TransposeOperatorSpec:
    """One square streaming transpose.

    name          the top module's name
    rows, cols    the matrix dimension (equal; a power of two)
    elementWidth  bits per element on every lane, in and out
    isSigned      how the testvectors are encoded (two's complement when True);
                  the hardware moves bits and never interprets them
    architecture  'bmb' (shifter, one BRAM bank, shifter) or
                  'mbm' (BRAM bank, shifter, BRAM bank)
    regFlags      the barrel shifter's register placement, one flag per mux
                  stage (the same placement for both of bmb's shifters)
    latency       cycles from a row on data_in to the same-numbered column on
                  data_out (for mbm: a burst starting on the frame)
    """

    name: str
    rows: int
    cols: int
    elementWidth: int
    isSigned: bool
    architecture: str
    regFlags: tuple[bool, ...]
    latency: int

    def __post_init__(self):
        if self.rows != self.cols:
            raise ValueError(f'{self.name}: only square transposes, got {self.rows} x {self.cols}')
        if self.rows < 2 or self.rows & (self.rows - 1):
            raise ValueError(f'{self.name}: the dimension must be a power of two >= 2, got {self.rows}')
        if self.elementWidth < 1:
            raise ValueError(f'{self.name}: elementWidth must be >= 1, got {self.elementWidth}')
        if self.architecture not in ('bmb', 'mbm'):
            raise ValueError(f"{self.name}: architecture must be 'bmb' or 'mbm', got {self.architecture!r}")
