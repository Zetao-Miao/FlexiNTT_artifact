"""
Timing risk of a core at the requested clock, from routed out-of-context results.

There is no build-free timing model. The generators pipeline for the requested clock, and whether place and
route then meets it depends mostly on the size of the core. This module looks up routed cores of the same
architecture and a similar LUT count in `timing_data.json` and reports how many of them reached the clock.

A routed core reached a clock f when its measured period (constraint minus WNS) is at most 1/f. Nearly all
routed cores were generated for 350 MHz, so the answer for a higher clock is pessimistic (the generator would
add pipeline stages) and for a lower clock optimistic in area (it would remove some). The flag says so.
"""
import json
import os

_DATA = None
MIN_NEIGHBOURS = 6


def _rows():
    global _DATA
    if _DATA is None:
        with open(os.path.join(os.path.dirname(__file__), 'timing_data.json')) as f:
            d = json.load(f)
            _DATA = d['rows'] + d.get('rows_validation', [])
    return _DATA


def neighbours(arch, lut, factor=1.6):
    """Routed cores of this architecture within `factor` of the LUT count (any architecture if too few)."""
    lo, hi = lut / factor, lut * factor
    near = [r for r in _rows() if lo <= r[1] <= hi]
    same = [r for r in near if r[0] == arch]
    return (same, True) if len(same) >= MIN_NEIGHBOURS else (near, False)


def timingRisk(arch, lut, clockMhz):
    """Returns (metFraction or None, number of neighbours, flag or None)."""
    near, sameArch = neighbours(arch, lut)
    # routed cores generated for about this clock say most: when the bulk of the data (350 MHz) is not near
    # the asked clock, use them alone, also when they are few (the flag then gives the count)
    own = [r for r in near if abs(1e3 / r[3] / clockMhz - 1) <= 0.15]
    if own and len(own) < MIN_NEIGHBOURS:
        met = sum(1 for r in own if r[4] >= 0)
        who = 'this architecture' if sameArch else 'any architecture'
        return met / len(own), len(own), (f'timing: {met} of only {len(own)} routed cores of similar size '
                                          f'({who}) generated for about {clockMhz:g} MHz met it')
    if len(near) < MIN_NEIGHBOURS:
        biggest = max(r[1] for r in _rows())
        if lut > biggest:
            return 0.0, 0, f'timing: larger than every routed core ({biggest} LUT), none of the largest met 350 MHz'
        return None, len(near), 'timing: no routed core of similar size'
    period = 1e3 / clockMhz
    genClocks = {round(1e3 / r[3]) for r in near}
    who = 'this architecture' if sameArch else 'any architecture'
    if clockMhz > 1.15 * max(genClocks):
        # the neighbours were pipelined for a slower clock, so their period says nothing about this one
        return None, len(near), f'timing: no routed core of similar size was generated for {clockMhz:g} MHz'
    met = sum(1 for r in near if r[3] - r[4] <= period + 1e-9)
    frac = met / len(near)
    flag = None
    if frac < 0.8:
        flag = f'timing: {met} of {len(near)} routed cores of similar size ({who}) reached {clockMhz:g} MHz'
    return frac, len(near), flag


ROUTE = 'route: '              # prefix of the flag below; a core that carries it may not push another off the front


def hasInputRegister(record) -> bool:
    """The option that shortens the long routes of a large core: a register in front of every butterfly of the
    small NTTs (multi-step `subInputRegister`) or of the stages (dataflow `inputRegister`)."""
    p = record.params or {}
    return bool(p.get('subInputRegister') or p.get('inputRegister'))


def wirePeriod(arch, lut, reg):
    """Reachable clock period (ns) of a core from the wire model, and its uncertainty, or None.

    Logic delay is modelled per operator and each core is pipelined for the requested clock, so what is left is
    the longest register-to-register route. A placed design of area A spans about sqrt(A), and so does its
    longest route: period = t0 + k sqrt(LUT). The two constants belong to the platform and the architecture
    (timing_data.json wire_model, fitted once on routed cores, like the logic delays). The input register
    option puts a register on that route and shortens its wire term by `regFactor`."""
    global _ROUTE
    if _ROUTE is None:
        with open(os.path.join(os.path.dirname(__file__), 'timing_data.json')) as f:
            _ROUTE = json.load(f).get('wire_model', {})
    m = _ROUTE.get(arch)
    if not isinstance(m, dict):
        return None
    return m['t0'] + m['k'] * (m['regFactor'] if reg else 1.0) * lut ** 0.5, m['sigma']


def routeFlag(arch, lut, clockMhz, reg):
    """The mark of a core whose longest route is expected to miss the requested clock, or None. Build-free:
    it depends on the modelled size of the core and on its register option only (`wirePeriod`). The core is
    marked when the modelled period, less its uncertainty, still exceeds the requested period."""
    w = wirePeriod(arch, lut, reg)
    if w is None or w[0] - w[1] <= 1e3 / clockMhz:
        return None
    return (f'{ROUTE}the wire model gives {1e3 / w[0]:.0f} MHz for a core of this size '
            f'{"with" if reg else "without"} the input register (requested {clockMhz:g} MHz)')


_ROUTE = None


def annotate(record):
    """Adds the timing flag and the route flag to a record (once) and stores the fraction in `timingMet`."""
    frac, n, flag = timingRisk(record.arch, record.lut, record.clockMhz)
    record.timingMet = None if frac is None else round(frac, 2)
    if flag and flag not in record.flags:
        record.flags.append(flag)
    rf = routeFlag(record.arch, record.lut, record.clockMhz, hasInputRegister(record))
    if rf and rf not in record.flags:
        record.flags.append(rf)
    return record
