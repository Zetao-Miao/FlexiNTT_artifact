'''One generated core, described the same way for every architecture.

Every number is a model number (no build) unless `measured` is filled. Bandwidth is counted at the boundary of the
NTT core: every port that carries data in or out, with its width and how many beats one polynomial needs.
'''
from __future__ import annotations

from dataclasses import dataclass, field, asdict

#: kinds of boundary port. `data_in` / `data_out`: the polynomial. `twiddle_stream`: twiddles supplied from
#: outside in step with the data. `table_load`: words written into the core's tables when the modulus (or the
#: direction) changes. `record_stream`: other per-polynomial side data (seeds, records of a generator).
PORT_KINDS = ('data_in', 'data_out', 'twiddle_stream', 'table_load', 'record_stream')
#: traffic besides the polynomial: the kinds a user may forbid or limit
SIDE_KINDS = ('twiddle_stream', 'table_load', 'record_stream')
#: control inputs of a few bits per polynomial (direction, modulus index and their copies at the output). The
#: adapters book them as table_load or record_stream ports. They are not side traffic.
CONTROL_NAMES = ('DIR', 'MIDX', 'dir_out', 'midx_out')


def areaUnits(lut, ff, dsp, bram36, uram) -> float:
    '''The comparison's formula: (kLUT + kFF + DSP x 4/3 + BRAM36 + 8 URAM) / 5.'''
    return (lut / 1000 + ff / 1000 + dsp * 4 / 3 + bram36 + 8 * uram) / 5


@dataclass
class Port:
    '''One boundary port (or a group of equal ports, `count`).

    widthBits        bits of one beat of one port
    count            equal ports in the group
    beatsPerNtt      beats one port carries for one polynomial in steady state. For `table_load`: beats of one
                     load (a load happens once per run of polynomials of one modulus, see CoreRecord.bandwidth)
    perLoad          True for a port that is used once per modulus run, not once per polynomial
    name             the RTL port name (or its prefix), so the count can be checked against the generated module
    '''
    kind: str
    widthBits: int
    count: int = 1
    beatsPerNtt: float = 0.0
    perLoad: bool = False
    name: str = ''

    def __post_init__(self):
        if self.kind not in PORT_KINDS:
            raise ValueError(f'port kind {self.kind!r} not in {PORT_KINDS}')

    @property
    def peakBitsPerCycle(self) -> int:
        '''Bits in a cycle in which every port of the group is valid.'''
        return self.widthBits * self.count

    @property
    def bitsPerUse(self) -> float:
        '''Bits per polynomial (or per load, `perLoad`).'''
        return self.widthBits * self.count * self.beatsPerNtt


@dataclass
class CoreRecord:
    arch: str                       # 'iterative' | 'hybrid' | 'dataflow' | 'multistep'
    name: str
    params: dict                    # everything the adapter needs to build this core again (plain values only)
    clockMhz: float                 # the clock the core was generated for (pipelining follows it)
    lut: float = 0
    ff: float = 0
    dsp: float = 0
    bram36: float = 0
    uram: float = 0
    interval: float = 0             # cycles between the starts of two polynomials, steady state, same modulus
    latency: float = 0              # cycles, first input beat to last output beat of one polynomial
    reloadCycles: float = 0         # cycles lost when the modulus (or direction) changes; 0 = no idle cycle
    ports: list = field(default_factory=list)       # list[Port]
    twiddleWordsInside: int = 0     # twiddle (and factor) words stored in the core
    twiddleWordsOutside: int = 0    # words that must be kept outside the core per modulus and direction
    perPolyModulus: bool = False    # consecutive polynomials may differ in modulus with no idle cycle
    perPolyDirection: bool = False  # same for the direction
    lanes: int = 0                  # coefficients per cycle at the data ports
    butterflies: int = 0
    flags: list = field(default_factory=list)       # timing and model risks, plain words
    timingMet: float | None = None                   # share of routed cores of similar size that reached the clock
    modelNote: str = ''             # which model priced it and its known error
    measured: dict = field(default_factory=dict)    # routed numbers, when a build exists

    # --- derived -------------------------------------------------------------------------------------

    @property
    def area(self) -> float:
        return areaUnits(self.lut, self.ff, self.dsp, self.bram36, self.uram)

    def effectiveInterval(self, run: float = float('inf')) -> float:
        '''Cycles per polynomial when the modulus changes after every `run` polynomials.'''
        if run == float('inf') or not self.reloadCycles:
            return self.interval
        return self.interval + self.reloadCycles / run

    def nttPerS(self, run: float = float('inf')) -> float:
        return self.clockMhz * 1e6 / self.effectiveInterval(run)

    def latencyUs(self) -> float:
        return self.latency / self.clockMhz

    def side(self, run: float = float('inf')) -> dict:
        '''The traffic besides the polynomial, by kind, without the control inputs (CONTROL_NAMES):
        {kind: {'avgBitsPerCycle', 'peakBitsPerCycle', 'bitsPerLoad'}}. A kind with no port is absent.
        bitsPerLoad: bits of one load of the per-load ports (once per run of polynomials of one modulus).'''
        iv = self.effectiveInterval(run)
        out = {}
        for p in self.ports:
            if p.kind not in SIDE_KINDS or p.name in CONTROL_NAMES:
                continue
            d = out.setdefault(p.kind, {'avgBitsPerCycle': 0.0, 'peakBitsPerCycle': 0, 'bitsPerLoad': 0.0})
            d['peakBitsPerCycle'] += p.peakBitsPerCycle
            if p.perLoad:
                d['bitsPerLoad'] += p.bitsPerUse
                if run != float('inf'):
                    d['avgBitsPerCycle'] += p.bitsPerUse / run / iv
            else:
                d['avgBitsPerCycle'] += p.bitsPerUse / iv
        return out

    def sideAvg(self, run: float = float('inf')) -> float:
        '''Average bits per cycle of all the traffic besides the polynomial.'''
        return sum(v['avgBitsPerCycle'] for v in self.side(run).values())

    def dataPeak(self) -> tuple:
        '''(bits of one input beat over all data input ports, the same for the output).'''
        return (sum(p.peakBitsPerCycle for p in self.ports if p.kind == 'data_in'),
                sum(p.peakBitsPerCycle for p in self.ports if p.kind == 'data_out'))

    def bandwidth(self, run: float = float('inf'), kinds=None) -> dict:
        '''Boundary bandwidth, all ports split by kind and the total.

        {'byKind': {kind: {'bitsPerNtt', 'avgBitsPerCycle', 'peakBitsPerCycle'}}, 'total': {the same three}}
        bitsPerNtt        bits one polynomial moves over the boundary; a per-load port spreads over `run`
                          polynomials (run = inf: the load is not counted)
        avgBitsPerCycle   bitsPerNtt / cycles per polynomial (with the reload cycles)
        peakBitsPerCycle  bits in a cycle in which every port of the kind is valid (total: all kinds at once,
                          an upper bound: the adapter may give a tighter figure in `params['peakBits']`)
        `kinds`: restrict the total to these kinds (default all).
        '''
        iv = self.effectiveInterval(run)
        by = {}
        for p in self.ports:
            use = p.bitsPerUse / run if p.perLoad else p.bitsPerUse
            if p.perLoad and run == float('inf'):
                use = 0.0
            d = by.setdefault(p.kind, {'bitsPerNtt': 0.0, 'avgBitsPerCycle': 0.0, 'peakBitsPerCycle': 0})
            d['bitsPerNtt'] += use
            d['avgBitsPerCycle'] += use / iv
            d['peakBitsPerCycle'] += p.peakBitsPerCycle
        sel = [k for k in by if kinds is None or k in kinds]
        tot = {f: sum(by[k][f] for k in sel) for f in ('bitsPerNtt', 'avgBitsPerCycle', 'peakBitsPerCycle')}
        if kinds is None and 'peakBits' in self.params:
            tot['peakBitsPerCycle'] = self.params['peakBits']
        return {'byKind': by, 'total': tot}

    def row(self, run: float = float('inf')) -> dict:
        '''A flat dict for tables and JSON.'''
        bw = self.bandwidth(run)
        d = {'arch': self.arch, 'name': self.name, 'clockMhz': self.clockMhz, 'lanes': self.lanes,
             'butterflies': self.butterflies, 'lut': round(self.lut), 'ff': round(self.ff), 'dsp': round(self.dsp),
             'bram36': round(self.bram36, 1), 'uram': round(self.uram), 'area': round(self.area, 2),
             'interval': self.interval, 'latency': self.latency, 'reloadCycles': self.reloadCycles,
             'nttPerS': round(self.nttPerS(run), 1), 'latencyUs': round(self.latencyUs(), 3),
             'bwBitsPerNtt': round(bw['total']['bitsPerNtt']), 'bwAvgBitsPerCycle': round(bw['total']['avgBitsPerCycle'], 2),
             'bwPeakBitsPerCycle': bw['total']['peakBitsPerCycle'],
             'twiddleWordsInside': self.twiddleWordsInside, 'twiddleWordsOutside': self.twiddleWordsOutside,
             'perPolyModulus': self.perPolyModulus, 'perPolyDirection': self.perPolyDirection,
             'timingMet': self.timingMet, 'flags': '; '.join(self.flags)}
        for k, v in bw['byKind'].items():
            d[f'bw_{k}_avg'] = round(v['avgBitsPerCycle'], 2)
        return d

    def toJson(self) -> dict:
        d = asdict(self)
        return d

    @staticmethod
    def fromJson(d: dict) -> 'CoreRecord':
        d = dict(d)
        d['ports'] = [Port(**p) for p in d.get('ports', [])]
        return CoreRecord(**d)
