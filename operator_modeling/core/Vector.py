'''What a multi-lane port carries: an ordered bundle of `Signal`s, plus how the
lanes pack into one hardware word.

The design sheet's common classes are `IntType`, `Signal`, `Ports` and `Vector`.
The first three already existed; `Vector` names the thing the code was already
passing around as loose lists. An NTT's input is `n` lanes, each with its own
bound (`inputBitWidthsNatural[i]` in the spec), and the testbench reads them as
one packed word per cycle with lane 0 in the least significant bits
(`rtl_gen.ntt._pack_per_slot`). A matrix transpose's row, a constant-multiplier
bank's outputs and a four-step's lane groups are the same shape.

Two axes, kept apart
--------------------
A `Signal`'s `values` are a batch of independent trials. A `Vector` adds the
lane axis on top, so its data is `lanes x trials`:

    vec.lanes[i].values[t]    lane i of trial t

`trial(t)` reads across the lanes (what one beat of the hardware sees);
`lane(i)` is one `Signal`. `packBatch()` turns `lanes x trials` into one packed
integer per trial, exactly the word a `$readmemh` testvector line holds, and
`fromPacked` reverses it. Neither ever measures a width from the data: every
lane's width is its bound's, as everywhere else in the project.

Packing order
-------------
`order='lane0Lsb'` (the default, and what every generator here writes) puts
lane 0 in bits `[w0-1:0]`, lane 1 above it, and so on — the SV concatenation
`{lane[n-1], ..., lane[0]}`. `'lane0Msb'` is the reverse, for an interface
that wants it. Each lane is written as `bitWidth` bits of two's complement,
so a signed lane round-trips through `unpack`.

A `Vector` is frozen like a `Signal`: replace it, never mutate it.
'''
from __future__ import annotations

from dataclasses import dataclass, field

from .IntType import IntType
from .Signal import Signal

LANE0_LSB = 'lane0Lsb'
LANE0_MSB = 'lane0Msb'
_ORDERS = (LANE0_LSB, LANE0_MSB)


def _encode(value: int, width: int) -> int:
    '''`width` bits of two's complement; a zero-width lane holds nothing.'''
    if width <= 0:
        return 0
    return value & ((1 << width) - 1)


def _decode(raw: int, width: int, signed: bool) -> int:
    if width <= 0:
        return 0
    raw &= (1 << width) - 1
    if signed and (raw >> (width - 1)) & 1:
        return raw - (1 << width)
    return raw


@dataclass(frozen=True)
class Vector:
    '''An ordered bundle of lanes. Each lane is a `Signal`; all lanes that carry
    values carry batches of the same length.'''

    lanes: tuple[Signal, ...]
    order: str = LANE0_LSB
    name: str = ''

    def __post_init__(self):
        object.__setattr__(self, 'lanes', tuple(self.lanes))
        if self.order not in _ORDERS:
            raise ValueError(f'Vector.order must be one of {_ORDERS}, got {self.order!r}')
        for i, s in enumerate(self.lanes):
            if not isinstance(s, Signal):
                raise TypeError(f'Vector lane {i} is {type(s).__name__}, not Signal')
        sizes = {s.batchSize for s in self.lanes if s.hasValues}
        if len(sizes) > 1:
            raise ValueError(f'Vector {self.name!r}: lanes carry batches of different '
                             f'lengths {sorted(sizes)}')

    # --- construction -------------------------------------------------------

    @staticmethod
    def uniform(bound: IntType, n: int, order: str = LANE0_LSB, name: str = '') -> 'Vector':
        '''`n` lanes sharing one bound, no values.'''
        return Vector(tuple(Signal(bound) for _ in range(n)), order, name)

    @staticmethod
    def fromBounds(bounds, order: str = LANE0_LSB, name: str = '') -> 'Vector':
        return Vector(tuple(Signal(b) for b in bounds), order, name)

    @staticmethod
    def fromLaneBatches(bounds, batches, order: str = LANE0_LSB, name: str = '') -> 'Vector':
        '''Lanes from per-lane bounds and per-lane batches (`batches[i][t]`).'''
        bounds, batches = list(bounds), list(batches)
        if len(bounds) != len(batches):
            raise ValueError(f'{len(bounds)} bounds for {len(batches)} lane batches')
        return Vector(tuple(Signal(b, list(v)) for b, v in zip(bounds, batches)), order, name)

    @staticmethod
    def fromTrials(bounds, trials, order: str = LANE0_LSB, name: str = '') -> 'Vector':
        '''Lanes from per-trial rows (`trials[t][i]`), the testbench's view.'''
        bounds, trials = list(bounds), [list(r) for r in trials]
        for t, row in enumerate(trials):
            if len(row) != len(bounds):
                raise ValueError(f'trial {t} has {len(row)} lanes, expected {len(bounds)}')
        cols = [[row[i] for row in trials] for i in range(len(bounds))]
        return Vector.fromLaneBatches(bounds, cols, order, name)

    @staticmethod
    def fromPorts(ports, order: str = LANE0_LSB, name: str = '') -> 'Vector':
        '''Snapshot of the signals on a list of ports. A port with no signal is
        refused: a lane with no bound has no width.'''
        lanes = []
        for i, p in enumerate(ports):
            if p.signal is None:
                raise ValueError(f'Vector.fromPorts: port {i} ({p.name}) carries no signal')
            lanes.append(p.signal)
        return Vector(tuple(lanes), order, name)

    @staticmethod
    def fromPacked(bounds, words, order: str = LANE0_LSB, name: str = '') -> 'Vector':
        '''Inverse of `packBatch`: decode one packed word per trial.'''
        proto = Vector.fromBounds(bounds, order, name)
        return Vector.fromTrials(bounds, [proto.unpack(w) for w in words], order, name)

    # --- shape ---------------------------------------------------------------

    def __len__(self) -> int:
        return len(self.lanes)

    def lane(self, i: int) -> Signal:
        return self.lanes[i]

    @property
    def bounds(self) -> list[IntType]:
        return [s.bound for s in self.lanes]

    @property
    def widths(self) -> list[int]:
        return [s.bitWidth for s in self.lanes]

    @property
    def signedness(self) -> list[bool]:
        return [s.isSigned for s in self.lanes]

    @property
    def totalWidth(self) -> int:
        return sum(self.widths)

    @property
    def isUniform(self) -> bool:
        b = self.bounds
        return all((x.minValue, x.maxValue, x.zeroLsbs) == (b[0].minValue, b[0].maxValue, b[0].zeroLsbs)
                   for x in b)

    def union(self) -> IntType:
        '''One bound covering every lane — what a lane-mixing operator's output
        (a transpose's) has to assume.'''
        return IntType.union(self.bounds)

    @property
    def hasValues(self) -> bool:
        return bool(self.lanes) and all(s.hasValues for s in self.lanes)

    @property
    def batchSize(self) -> int:
        return self.lanes[0].batchSize if self.hasValues else 0

    def offsets(self) -> list[int]:
        '''Bit offset of each lane's LSB inside the packed word.'''
        widths = self.widths
        order = range(len(widths)) if self.order == LANE0_LSB else reversed(range(len(widths)))
        out = [0] * len(widths)
        pos = 0
        for i in order:
            out[i] = pos
            pos += widths[i]
        return out

    # --- data ----------------------------------------------------------------

    def trial(self, t: int) -> list[int]:
        if not self.hasValues:
            raise ValueError(f'Vector {self.name!r} carries no values')
        return [s.values[t] for s in self.lanes]

    def trials(self) -> list[list[int]]:
        return [self.trial(t) for t in range(self.batchSize)]

    def laneBatches(self) -> list[list[int]]:
        if not self.hasValues:
            raise ValueError(f'Vector {self.name!r} carries no values')
        return [list(s.values) for s in self.lanes]

    def pack(self, values) -> int:
        '''One trial's lane values -> one packed word.'''
        values = list(values)
        if len(values) != len(self.lanes):
            raise ValueError(f'pack: {len(values)} values for {len(self.lanes)} lanes')
        word = 0
        for v, w, off in zip(values, self.widths, self.offsets()):
            word |= _encode(v, w) << off
        return word

    def unpack(self, word: int) -> list[int]:
        '''One packed word -> the lane values, each decoded at its own width and
        signedness.'''
        return [_decode(word >> off, w, s)
                for w, s, off in zip(self.widths, self.signedness, self.offsets())]

    def packBatch(self) -> list[int]:
        return [self.pack(self.trial(t)) for t in range(self.batchSize)]

    def withLaneBatches(self, batches) -> 'Vector':
        return Vector.fromLaneBatches(self.bounds, batches, self.order, self.name)

    def withoutValues(self) -> 'Vector':
        return Vector.fromBounds(self.bounds, self.order, self.name)

    def reordered(self, permutation) -> 'Vector':
        '''Lane `i` of the result is lane `permutation[i]` of this one — the
        natural-to-memory maps of an NTT, a bit reversal.'''
        permutation = list(permutation)
        if sorted(permutation) != list(range(len(self.lanes))):
            raise ValueError('reordered: not a permutation of the lanes')
        return Vector(tuple(self.lanes[p] for p in permutation), self.order, self.name)

    def validate(self) -> None:
        '''Every lane's values inside its bound (`Signal.validate`).'''
        for s in self.lanes:
            s.validate()

    # --- ports -----------------------------------------------------------------

    def drive(self, ports) -> None:
        '''Load these lanes onto a list of input ports, positionally.'''
        ports = list(ports)
        if len(ports) != len(self.lanes):
            raise ValueError(f'Vector.drive: {len(self.lanes)} lanes for {len(ports)} ports')
        for p, s in zip(ports, self.lanes):
            p.signal = s

    def __repr__(self) -> str:
        w = self.widths
        shape = f'{len(w)} lanes x {w[0]} bits' if w and len(set(w)) == 1 else f'{len(w)} lanes, {sum(w)} bits'
        vals = f', {self.batchSize} trials' if self.hasValues else ', no values'
        return f'Vector({self.name or "?"}: {shape}{vals}, {self.order})'
