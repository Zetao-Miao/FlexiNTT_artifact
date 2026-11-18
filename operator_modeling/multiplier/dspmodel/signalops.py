'''Arithmetic on `Signal`s: bound and values in lockstep.

Every function here does one thing to a wire the way the hardware does it,
on both flows at once: the `IntType` through interval arithmetic, the batch
through the matching `vector*` helper. Values are optional — when any input
lacks them the result lacks them too, which is how a bound-only pass runs
through exactly the same code as a value pass.

Values are unreduced Python ints throughout, per the project convention. A
wire that overflows its register is caught by `requireFits`, not hidden by a
mask; the mask is what the RTL applies, and applying it in the model would
turn a design bug into a wrong-but-plausible number.
'''
from __future__ import annotations

from ...core.IntType import IntType
from ...core.OperatorScheme import decodeTwosComplement
from ...core.Signal import Signal
from ...core.utils import vectorAdd, vectorLshift, vectorRshift, vectorSlice, vectorSub


def _values(*signals: Signal) -> list[list[int]] | None:
    '''The value batches of `signals`, or None when any is absent.'''
    batches = [s.values for s in signals]
    if any(v is None for v in batches):
        return None
    sizes = {len(v) for v in batches}
    if len(sizes) > 1:
        raise ValueError(f'signalops: batch sizes differ: {sorted(sizes)}')
    return batches


def const(value: int, like: Signal | None = None) -> Signal:
    '''A constant wire. With `like`, it carries a batch of that length.'''
    values = None
    if like is not None and like.values is not None:
        values = [value] * len(like.values)
    return Signal(IntType.fromConst(value), values)


def add(a: Signal, b: Signal) -> Signal:
    v = _values(a, b)
    return Signal(a.bound + b.bound, vectorAdd(*v) if v else None)


def sub(a: Signal, b: Signal) -> Signal:
    v = _values(a, b)
    return Signal(a.bound - b.bound, vectorSub(*v) if v else None)


def neg(a: Signal) -> Signal:
    return Signal(-a.bound, [-x for x in a.values] if a.values is not None else None)


def mul(a: Signal, b: Signal) -> Signal:
    '''Elementwise product — the multiplier array itself.'''
    v = _values(a, b)
    return Signal(a.bound * b.bound,
                  [x * y for x, y in zip(*v)] if v else None)


def lshift(a: Signal, n: int) -> Signal:
    return Signal(a.bound << n,
                  vectorLshift(a.values, n) if a.values is not None else None)


def rshift(a: Signal, n: int) -> Signal:
    '''Arithmetic right shift — what `>>>` does to a signed register.'''
    return Signal(a.bound >> n,
                  vectorRshift(a.values, n) if a.values is not None else None)


def sliceBits(a: Signal, lo: int, hi: int, signed: bool) -> Signal:
    '''Bits `lo..hi` inclusive of the register carrying `a`, reinterpreted as
    the hardware declares them.

    The values follow the bit pattern exactly (`vectorSlice`, with the
    declared signedness). The bound follows `IntType.slice`, whose own
    signedness rule agrees with the hardware whenever the wire's bound is
    as wide as its register — true of every input and every slice of one.

    The one case where they disagree is an **unsigned** slice that reaches
    past the top of a **narrower signed** bound: a Sub result declared 24
    bits but bounded to 20, re-sliced by a nested Karatsuba as `[0:23]`
    unsigned. The hardware zero-extends the pattern, so a negative value
    comes out large and positive; `IntType.slice` would keep the signed
    interval. That slice is bounded here as the full unsigned range, which
    is what the pattern can actually hold.
    '''
    width = hi - lo + 1
    bound = a.bound.slice(lo, hi)
    if not signed and a.bound.isSigned and hi >= a.bound.bitWidth - 1:
        zl = max(0, a.bound.zeroLsbs - lo)
        bound = IntType.unsigned(width - zl) << zl if width > zl else IntType(0, 0, 0)
    elif signed and not bound.isSigned and not bound.isZero \
            and width < (a.bound >> lo).bitWidth:
        raise ValueError(
            f'sliceBits[{lo}:{hi}]: declared signed, but the slice is strictly '
            f'interior to bound {a.bound} — the hardware would sign-extend from '
            f'bit {hi}, which no interval here can express'
        )
    values = (vectorSlice(a.values, lo, hi, signed=signed)
              if a.values is not None else None)
    return Signal(bound, values)


def reinterpret(a: Signal, width: int, signed: bool) -> Signal:
    '''Read the low `width` bits of `a`'s pattern as a `width`-bit register.

    What a port declaration does to a concatenated pattern: `assign P =
    {field, low}` with `P` declared `signed [W-1:0]`. The values decode the
    two's complement; the bound is `a`'s own when it already fits the
    register (the pattern of a value that fits reads back as itself), and
    the full register otherwise.
    '''
    mask = (1 << width) - 1
    values = None
    if a.values is not None:
        values = [decodeTwosComplement(x & mask, width, signed) for x in a.values]
    reg = register(width, signed)
    b = a.bound
    bound = b if (reg.minValue <= b.minValue and b.maxValue <= reg.maxValue) else reg
    return Signal(bound, values)


def register(width: int, signed: bool) -> IntType:
    '''Everything a `width`-bit register can hold.'''
    return IntType.signed(width) if signed else IntType.unsigned(width)


def fits(a: Signal, width: int, signed: bool) -> bool:
    '''Whether every value `a`'s bound admits fits the register.'''
    reg = register(width, signed)
    return reg.minValue <= a.bound.minValue and a.bound.maxValue <= reg.maxValue


def requireFits(a: Signal, width: int, signed: bool, what: str) -> None:
    '''Raise, naming the wire, when the bound does not fit its register.

    This is the model catching what the RTL would silently wrap.
    '''
    if not fits(a, width, signed):
        kind = 's' if signed else 'u'
        raise ValueError(
            f'{what}: bound {a.bound} does not fit its {kind}{width} register '
            f'[{register(width, signed).minValue}, {register(width, signed).maxValue}]'
        )


def tighten(walked: Signal, identity: Signal, what: str) -> Signal:
    '''One value, two expressions: keep the walked values, intersect the bounds.

    A DSP whose ALU sums correlated terms — `P11 + (X_mid-X_lo)(Y_lo-Y_mid) +
    P00` — has a walked interval far wider than its true one. The generator
    states what it equals algebraically; that identity is computed alongside
    and the walked values are asserted equal to it.

    Neither interval need contain the other. Both are over-approximations of
    the same true range — the identity reuses operands too — so each is
    sound and so is their intersection, which is the tightest thing that can
    be claimed here. An *empty* intersection means the two expressions
    cannot describe one value, and that is a netlist error.

    `zeroLsbs` takes the larger claim: each is a proven lower bound on
    trailing zeros, so the stronger one holds.
    '''
    wb, ib = walked.bound, identity.bound
    lo, hi = max(wb.minValue, ib.minValue), min(wb.maxValue, ib.maxValue)
    if lo > hi:
        raise ValueError(
            f'{what}: walked bound {wb} and the identity\'s {ib} do not overlap — '
            f'the netlist arithmetic is wrong')
    v = _values(walked, identity)
    if v is not None:
        for i, (g, w) in enumerate(zip(*v)):
            if g != w:
                raise ValueError(
                    f'{what}: netlist gives {g}, identity gives {w} (sample {i})')
    return Signal(IntType(lo, hi, max(wb.zeroLsbs, ib.zeroLsbs)), walked.values)


def contained(a: Signal) -> bool:
    '''Whether every value on the wire lies inside its own bound.'''
    if a.values is None:
        return True
    lo, hi = a.bound.minValue, a.bound.maxValue
    return all(lo <= v <= hi for v in a.values)
