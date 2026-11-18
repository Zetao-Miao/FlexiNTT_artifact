'''A small design-space search for the hybrid NTT: which block (stages U, groups g) and how many polynomials in
the loop (slots S, chosen by the scheme's own 'auto') meet a rate target at the least area.

    from operator_modeling.ntt.hybrid.explore import explore
    best, table = explore('hy', 4096, q=536903681, maxInterval=1100, butterfly=dict(reduction=BarrettReduction))

Rule (as the multi-step type's form='auto' rule, with the rate as the constraint):
  candidates = every U in 1 .. log2 n and power-of-two g with n >= g 2^U 2^U (the round transpose's condition),
  whose model interval (R x slot, cycles per NTT) is at most `maxInterval` (None: no limit) and whose DSPs are
  at most `maxDsp` (None: no limit); among them the least area units ((kLUT + kFF + 4/3 DSP + BRAM36 + 8 URAM)/5,
  the comparison's formula); area within 2 % counts as equal -> the lower core latency, then fewer butterflies.
The numbers are the model's (since 2026-11-14 the inventory of HybridArea.py, checked against 40 routed cores by
`runHybridNTT.py --accuracy`: area units within 1 % on most rows, up to -8 % under a DSP budget), so the pick is a
model decision; report both the pick and the table.
'''
from __future__ import annotations

import contextlib
import io

from ...core.IntType import IntType
from .HybridNTTScheme import HybridNTTScheme


def explore(name: str, n: int, maxInterval: int | None = None, maxDsp: int | None = None, mhz: float = 350.0,
            maxLanes: int = 256, verbose: bool = False, **kw):
    L = n.bit_length() - 1
    rows = []
    for U in range(1, L + 1):
        g = 1
        while (g << U) <= maxLanes:
            W = g << U
            if n >= W << U:
                try:
                    with contextlib.redirect_stdout(io.StringIO()):
                        s = HybridNTTScheme(f'{name}_u{U}g{g}', n, U, g, **kw)
                        qm = max(s.moduliList())
                        s.setInputBound(IntType(0, qm - 1))
                        r = s.report(mhz=mhz)
                    r['scheme'] = s
                    rows.append(r)
                    if verbose:
                        print(f"  U={U} g={g} W={W} S={r['S']} interval={r['interval']} latency={r['latency']} "
                              f"DSP={r['dsp']} area={r['area']:.1f}")
                except (ValueError, NotImplementedError) as e:
                    if verbose:
                        print(f'  U={U} g={g}: {e}')
            g *= 2
    ok = [r for r in rows if (maxInterval is None or r['interval'] <= maxInterval)
          and (maxDsp is None or r['dsp'] <= maxDsp)]
    if not ok:
        return None, rows
    amin = min(r['area'] for r in ok)
    near = [r for r in ok if r['area'] <= 1.02 * amin]
    best = min(near, key=lambda r: (r['latency'], r['butterflies']))
    return best, rows
