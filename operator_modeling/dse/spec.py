'''What the user of the framework asks for.

Three groups: the NTT itself, the performance targets, and the limits (resources and boundary bandwidth).
A limit left at None does not constrain.
'''
from __future__ import annotations

from dataclasses import dataclass, field, asdict


@dataclass
class Requirements:
    # --- the NTT ------------------------------------------------------------------------------------
    n: int                                  # points, a power of two
    moduli: list = field(default_factory=list)   # every RNS modulus, when they are known (needed for ROM tables)
    qBits: int | None = None                # modulus width when `moduli` is not given (run-time moduli)
    numModuli: int | None = None            # how many moduli the workload uses (default len(moduli) or 1)
    modulusSlots: str = 'either'            # run-time moduli that change per polynomial: 'resident' (every modulus
    #                                         of the workload is loaded once and stays: num_moduli slots) |
    #                                         'rotating' (any sequence of moduli: the slots follow from the pipeline,
    #                                         a manager in the core reloads them) | 'either' (both are searched)
    modulusForm: str = 'ntt'                # 'ntt' | 'friendly' | 'kred' | 'pseudo_mersenne': a special form of
    #                                         every modulus that a reduction can use (see modform.py)
    formV: int | None = None                # friendly: every q = h 2^v + 1
    formKBits: int | None = None            # kred: every q = k 2^m + 1 with k of this many bits
    formCBits: int | None = None            # pseudo_mersenne: every q = 2^width - c with c below 2^formCBits
    transform: str = 'negacyclic'           # 'cyclic' | 'negacyclic' | 'both'
    direction: str = 'both'                 # 'forward' | 'inverse' | 'both'
    perPolyModulus: bool = False            # consecutive polynomials may differ in modulus, no idle cycle
    perPolyDirection: bool = False          # consecutive polynomials may differ in direction, no idle cycle
    run: float = float('inf')               # polynomials of one modulus back to back when not per polynomial
    #                                         (inf: one modulus for ever; the cost of a change is not counted)
    outputOrder: str = 'any'                # 'any' | 'natural': the output coefficients must come in index order
    outputBackpressure: bool = False        # True: the core must accept a stalled output (out_ready)
    # --- performance targets ------------------------------------------------------------------------
    clockMhz: float = 350.0                 # the clock the core must run at (cores are generated for it)
    minNttPerS: float | None = None
    maxIntervalCycles: float | None = None  # the same target in cycles per polynomial
    maxLatencyCycles: float | None = None
    maxLatencyUs: float | None = None
    # --- resource limits ----------------------------------------------------------------------------
    maxLut: float | None = None
    maxFf: float | None = None
    maxDsp: float | None = None
    maxBram36: float | None = None
    maxUram: float | None = None
    maxArea: float | None = None            # not an input any more (area units are a paper metric); kept so that
    #                                         saved requests load
    # --- boundary bandwidth limits ------------------------------------------------------------------
    maxBitsPerNtt: float | None = None      # total bits over the boundary for one polynomial
    maxAvgBitsPerCycle: float | None = None
    maxPeakBitsPerCycle: float | None = None
    bandwidthKinds: tuple | None = None     # kinds counted in the three totals above (None: all ports)
    maxByKind: dict = field(default_factory=dict)   # {kind: {'bitsPerNtt' | 'avgBitsPerCycle' | 'peakBitsPerCycle': limit}}
    # the five lines above are the first form of the bandwidth limits. The request file uses the ones below.
    maxDataInBits: float | None = None      # widest data input the environment drives, bits per cycle
    maxDataOutBits: float | None = None     # widest data output it accepts, bits per cycle
    allowTwiddleStream: bool = True         # may a core take its twiddles from a stream outside?
    maxTwiddleStreamBits: float | None = None     # the widest such stream, bits per cycle
    allowTableLoad: bool = True             # may a core have its tables written from outside?
    maxTableLoadBits: float | None = None   # bits of one load
    allowRecordStream: bool = True          # may a core take a record (seeds or tables) per polynomial?
    maxRecordStreamBits: float | None = None      # the widest such stream, bits per cycle
    maxOutsideTableBits: float | None = None      # storage outside the core for its tables, bits
    # --- search --------------------------------------------------------------------------------------
    archs: tuple = ('iterative', 'hybrid', 'dataflow', 'multistep')
    maxLanes: int = 256                     # widest data port, in coefficients per cycle
    allowRiskFlags: bool = True             # False: a core with a timing risk flag is not feasible
    sizing: str = 'minimal'                 # 'minimal': of each family only the smallest size that meets the
    #                                         requirements is priced (needs a throughput target) | 'all': every size
    options: dict = field(default_factory=dict)     # per-architecture restrictions, {arch: {option: [values]}}

    def __post_init__(self):
        if self.n & (self.n - 1) or self.n < 4:
            raise ValueError('n must be a power of two')
        if not self.moduli and not self.qBits:
            raise ValueError('give moduli=[...] or qBits=')
        if self.transform not in ('cyclic', 'negacyclic', 'both'):
            raise ValueError(self.transform)
        if self.direction not in ('forward', 'inverse', 'both'):
            raise ValueError(self.direction)
        if self.outputOrder not in ('any', 'natural'):
            raise ValueError(self.outputOrder)
        if self.modulusSlots not in ('resident', 'rotating', 'either'):
            raise ValueError(f'modulus_slots {self.modulusSlots!r} is not "resident", "rotating" or "either"')
        if self.sizing not in ('minimal', 'all'):
            raise ValueError(f'sizing {self.sizing!r} is not "minimal" or "all"')
        ports = [x for x in (self.maxDataInBits, self.maxDataOutBits) if x is not None]
        if ports:                           # the data ports bound the coefficients per cycle of every core
            cap = int(min(ports) // self.width)
            if cap < 1:
                raise ValueError(f'a data port of {min(ports):.0f} bits per cycle is narrower than one '
                                 f'coefficient of {self.width} bits')
            self.maxLanes = min(self.maxLanes, 1 << (cap.bit_length() - 1))
        from . import modform
        why = modform.problem(self.form, self.width, self.rootOrder)
        if why:
            raise ValueError(why)
        bad = [q for q in self.moduli if not modform.fits(self.form, q, self.width)]
        if bad:
            raise ValueError(f'modulus {bad[0]} does not have the form "{self.modulusForm}" that is stated')
        # these two cost area and latency, so the adapters leave them off unless asked: open them here
        self.options = {k: dict(v) for k, v in (self.options or {}).items()}
        for arch in self.archs:
            o = self.options.setdefault(arch, {})
            if self.outputOrder == 'natural':
                o.setdefault('outputOrder', ['natural'])
            if self.outputBackpressure:
                o.setdefault('outReady', [True])

    @property
    def width(self) -> int:
        return max(q.bit_length() for q in self.moduli) if self.moduli else self.qBits

    @property
    def targetInterval(self) -> float | None:
        '''The throughput target in cycles per polynomial (None: no target given).'''
        ivs = [x for x in (self.maxIntervalCycles,
                           self.clockMhz * 1e6 / self.minNttPerS if self.minNttPerS else None) if x is not None]
        return min(ivs) if ivs else None

    @property
    def latencyLimit(self) -> float | None:
        '''The latency limit in cycles (None: no limit given).'''
        ls = [x for x in (self.maxLatencyCycles,
                          self.maxLatencyUs * self.clockMhz if self.maxLatencyUs is not None else None) if x is not None]
        return min(ls) if ls else None

    @property
    def rootOrder(self) -> int:
        '''q = 1 (mod rootOrder) holds for every modulus of this NTT.'''
        return self.n if self.transform == 'cyclic' else 2 * self.n

    @property
    def form(self) -> dict:
        '''The stated modulus form as the plain dict of modform.py.'''
        d = {'kind': self.modulusForm}
        for k, v in (('v', self.formV), ('kBits', self.formKBits), ('cBits', self.formCBits)):
            if v is not None and {'v': 'friendly', 'kBits': 'kred', 'cBits': 'pseudo_mersenne'}[k] == self.modulusForm:
                d[k] = v
        return d

    @property
    def M(self) -> int:
        return self.numModuli or len(self.moduli) or 1

    @property
    def effRun(self) -> float:
        '''Polynomials between two modulus changes as the workload has them.'''
        if self.M == 1 and self.direction != 'both':
            return float('inf')
        return 1.0 if (self.perPolyModulus or self.perPolyDirection) else self.run

    #: resources that are thresholds. The DSP limit is the DSP budget of every core (dsplimit.py), not a threshold.
    THRESHOLDS = (('lut', 'maxLut', 'LUT'), ('ff', 'maxFf', 'FF'), ('bram36', 'maxBram36', 'BRAM36'),
                  ('uram', 'maxUram', 'URAM'))
    #: how far the routed count was above the model in the validation runs, by architecture and resource
    MODEL_LOW = {('iterative', 'ff'): 0.23, ('hybrid', 'ff'): 0.10}

    def share(self, r) -> tuple:
        '''(the largest share of a limit core `r` uses, the name of that resource). DSP is left out: its limit is
        a budget that the cores are meant to use. A limit that is not given does not count.'''
        best = (0.0, '')
        for attr, lim, name in self.THRESHOLDS:
            limit, used = getattr(self, lim), getattr(r, attr)
            if limit is None:
                continue
            s = used / limit if limit else (0.0 if not used else float('inf'))
            if s > best[0]:
                best = (s, name)
        return best

    def limitFlags(self, r) -> list:
        '''Flags for a core that meets a limit only inside the known error of the model.'''
        out = []
        for attr, lim, name in self.THRESHOLDS:
            limit, used = getattr(self, lim), getattr(r, attr)
            low = self.MODEL_LOW.get((r.arch, attr))
            if limit is not None and low and used <= limit < used * (1 + low):
                out.append(f'limit: {name} {used:.0f} of {limit:.0f} is inside the model error (routed {r.arch} '
                           f'cores had up to {100 * low:.0f} % more {name} than the model)')
        return out

    def check(self, r) -> list:
        '''[] when core `r` meets every requirement, else the reasons (plain words).'''
        why = []
        run = self.effRun
        if abs(r.clockMhz - self.clockMhz) > 1e-6:
            why.append(f'generated for {r.clockMhz} MHz, not {self.clockMhz}')
        if self.perPolyModulus and self.M > 1 and not r.perPolyModulus:
            why.append('cannot change the modulus per polynomial')
        if self.perPolyDirection and self.direction == 'both' and not r.perPolyDirection:
            why.append('cannot change the direction per polynomial')
        if self.outputOrder == 'natural' and r.params.get('outputOrder') != 'natural':
            why.append('output not in natural order')
        if self.outputBackpressure and not r.params.get('outReady'):
            why.append('no output backpressure')
        iv = r.effectiveInterval(run)
        if self.minNttPerS is not None and r.clockMhz * 1e6 / iv < self.minNttPerS:
            why.append(f'throughput {r.clockMhz * 1e6 / iv:.0f} NTT/s below {self.minNttPerS:.0f}')
        if self.maxIntervalCycles is not None and iv > self.maxIntervalCycles:
            why.append(f'interval {iv:.0f} cycles above {self.maxIntervalCycles:.0f}')
        if self.maxLatencyCycles is not None and r.latency > self.maxLatencyCycles:
            why.append(f'latency {r.latency:.0f} cycles above {self.maxLatencyCycles:.0f}')
        if self.maxLatencyUs is not None and r.latencyUs() > self.maxLatencyUs:
            why.append(f'latency {r.latencyUs():.1f} us above {self.maxLatencyUs}')
        for lim, val, nm in ((self.maxLut, r.lut, 'LUT'), (self.maxFf, r.ff, 'FF'), (self.maxDsp, r.dsp, 'DSP'),
                             (self.maxBram36, r.bram36, 'BRAM36'), (self.maxUram, r.uram, 'URAM'),
                             (self.maxArea, r.area, 'area units')):
            if lim is not None and val > lim:
                why.append(f'{nm} {val:.0f} above {lim:.0f}')
        bw = r.bandwidth(run, self.bandwidthKinds)
        for lim, key in ((self.maxBitsPerNtt, 'bitsPerNtt'), (self.maxAvgBitsPerCycle, 'avgBitsPerCycle'),
                         (self.maxPeakBitsPerCycle, 'peakBitsPerCycle')):
            if lim is not None and bw['total'][key] > lim:
                why.append(f'boundary {key} {bw["total"][key]:.0f} above {lim:.0f}')
        for kind, lims in self.maxByKind.items():
            got = bw['byKind'].get(kind)
            for key, lim in lims.items():
                if got and got[key] > lim:
                    why.append(f'{kind} {key} {got[key]:.0f} above {lim:.0f}')
        din, dout = r.dataPeak()
        for lim, got, nm in ((self.maxDataInBits, din, 'input'), (self.maxDataOutBits, dout, 'output')):
            if lim is not None and got > lim:
                why.append(f'data {nm} of {got:.0f} bits per cycle above {lim:.0f}')
        side = r.side(run)
        for kind, ok, lim, nm in (('twiddle_stream', self.allowTwiddleStream, self.maxTwiddleStreamBits, 'twiddle stream'),
                                  ('record_stream', self.allowRecordStream, self.maxRecordStreamBits, 'record stream'),
                                  ('table_load', self.allowTableLoad, None, 'table load')):
            if kind not in side:
                continue
            if not ok:
                why.append(f'needs a {nm}, which is not allowed')
            elif lim is not None and side[kind]['peakBitsPerCycle'] > lim:
                why.append(f'{nm} of {side[kind]["peakBitsPerCycle"]:.0f} bits per cycle above {lim:.0f}')
        if self.allowTableLoad and self.maxTableLoadBits is not None and 'table_load' in side \
                and side['table_load']['bitsPerLoad'] > self.maxTableLoadBits:
            why.append(f'table load of {side["table_load"]["bitsPerLoad"]:.0f} bits above {self.maxTableLoadBits:.0f}')
        if self.maxOutsideTableBits is not None and self.outsideBits(r) > self.maxOutsideTableBits:
            why.append(f'tables outside the core of {self.outsideBits(r):.0f} bits above {self.maxOutsideTableBits:.0f}')
        if not self.allowRiskFlags and r.flags:
            why.append('risk: ' + '; '.join(r.flags))
        return why

    def outsideBits(self, r) -> float:
        '''Storage the environment must hold for the tables of core `r`: the words kept outside per modulus,
        times the word width, times the number of moduli.'''
        return r.twiddleWordsOutside * self.width * self.M

    def forbiddenKinds(self) -> set:
        '''The kinds of side traffic the user does not allow.'''
        return {k for k, ok in (('twiddle_stream', self.allowTwiddleStream), ('table_load', self.allowTableLoad),
                                ('record_stream', self.allowRecordStream)) if not ok}

    def dataRate(self) -> float | None:
        '''Bits per cycle the polynomial itself needs in each direction at the throughput target: n coefficients
        of `width` bits every targetInterval cycles. The same for every core.'''
        return self.n * self.width / self.targetInterval if self.targetInterval else None

    def toJson(self) -> dict:
        d = asdict(self)
        d['run'] = None if self.run == float('inf') else self.run
        return d
