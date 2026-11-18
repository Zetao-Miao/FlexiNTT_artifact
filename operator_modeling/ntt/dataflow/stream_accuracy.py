"""Accuracy gate of the dataflow (streaming) NTT area model (2026-11-14).

    python3 -m operator_modeling.ntt.dataflow.stream_accuracy            reprint the table from the stored measurements
    python3 -m operator_modeling.ntt.dataflow.stream_accuracy --md       the same as a Markdown table

Measurements: `stream_measured.json` next to this file (routed out of context, Vivado 2025.1, V80 part, 350 MHz,
NTT core alone), written by `ntt_hw/experiments/overnight_2026-11-14/dataflow/tools/accuracy.py --collect`.
Each row stores the arguments of `runModularNTT.stream`, so the gate rebuilds the scheme and needs no build.
Columns: before = `StreamingNTTScheme.areaCost()` (the model before this night: LUT and DSP only);
structure = the instance inventory priced with the component model, in-core rules off (`StreamArea.TRIM = False`);
after = `StreamingNTTScheme.resources()`.
The gate FAILS (exit 1) when DSP differs, or area units are off by more than 3 % on any row. LUT and FF above 5 %
and block RAM differences are marked with '!' and listed; they do not fail the gate (see MODEL_ACCURACY.md)."""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
STORE = os.path.join(HERE, 'stream_measured.json')
K = ('lut', 'ff', 'dsp', 'bram36', 'uram')


def au(d):
    return (d['lut'] / 1000 + d['ff'] / 1000 + d['dsp'] * 4 / 3 + d['bram36'] + 8 * d['uram']) / 5


def moduli(mod, n):
    from operator_modeling.modmult.primes import nttFriendlyPrime
    from operator_modeling.modmult.ModulusFamily import ModulusFamily as MF
    w = (2 * n).bit_length() - 1
    if isinstance(mod, int):
        return dict(q=mod)
    if mod[0] == 'q':
        return dict(q=nttFriendlyPrime(mod[1], w))
    if mod[0] == 'm':
        return dict(q=[nttFriendlyPrime(mod[1], w, seed=i) for i in range(mod[2])])
    if mod[0] == 'fam':
        return dict(q=0, family=MF.friendly(mod[1], mod[2]))
    if mod[0] == 'odd':
        return dict(q=0, family=MF.odd(mod[1]))
    raise ValueError(mod)


def scheme(name, r, tgt=350.0):
    import runModularNTT as R
    kw = dict(r['kw'])
    src = kw.pop('source', None)
    mod = r['mod'] if isinstance(r['mod'], int) else tuple(r['mod'])
    m = moduli(mod, r['n'])
    return R.stream(name, r['n'], r['P'], m['q'], r['red'], r['nwc'], direction=r['dir'], family=m.get('family'),
                    source=src, targetFmaxMhz=tgt, **kw)


def predict(name, r):
    """{'before': {...}, 'structure': {...}, 'after': {...}, 'latency', 'frame'} of one row."""
    import runModularNTT as R
    from . import StreamArea as SA
    s = R.quiet(lambda: scheme(name, r))
    lut, dsp = R.quiet(lambda: s.areaCost())
    out = {'before': {'lut': lut, 'dsp': dsp}}
    old = SA.TRIM
    try:
        SA.TRIM = False
        out['structure'] = R.quiet(lambda: s.resources())
    finally:
        SA.TRIM = old
    out['after'] = R.quiet(lambda: s.resources())
    out['latency'] = s.readyLatency() if getattr(s, 'outReady', False) else s.latency()
    out['frame'] = s.F
    return out


def err(p, m, k):
    if not m[k]:
        return None if not p.get(k) else float('inf')
    return 100.0 * (p[k] - m[k]) / m[k]


def main(argv) -> int:
    md = '--md' in argv
    only = [a for a in argv if not a.startswith('--')]
    store = json.load(open(STORE))
    bad, marks, stats = [], [], {}
    sep = ' | ' if md else '  '
    head = ['row', 'set', 'LUT', 'FF', 'DSP', 'BRAM', 'URAM', 'au', 'before LUT %', 'struct LUT %', 'struct FF %',
            'LUT %', 'FF %', 'DSP', 'BRAM', 'URAM', 'au %', 'latency', 'WNS ns']
    wid = [22, 4, 7, 7, 5, 5, 4, 8, 12, 12, 11, 7, 7, 5, 6, 5, 6, 7, 7]
    line = lambda c: ('| ' if md else '') + sep.join(str(x).rjust(w) if i else str(x).ljust(w) for i, (x, w) in enumerate(zip(c, wid))) + (' |' if md else '')
    print(line(head))
    if md:
        print('|' + '|'.join('---' for _ in head) + '|')
    for name, r in store['rows'].items():
        if only and name not in only:
            continue
        m = r['measured']
        import contextlib, io
        with contextlib.redirect_stdout(io.StringIO()):
            p = predict(name, r)
        a, st, b = p['after'], p['structure'], p['before']
        ea = {k: err(a, m, k) for k in K}
        eu = 100.0 * (au(a) - au(m)) / au(m)
        f = lambda v: '.' if v is None else f'{v:+.1f}'
        d = lambda k: '=' if round(a[k] * 2) == round(m[k] * 2) else f'{a[k] - m[k]:+g}!'
        mk = lambda v: f(v) + ('!' if v is not None and abs(v) > 5 else '')
        print(line([name, r['set'], f'{m["lut"]:.0f}', f'{m["ff"]:.0f}', f'{m["dsp"]:g}', f'{m["bram36"]:g}', f'{m["uram"]:g}',
                    f'{au(m):.2f}', f(err(b, m, 'lut')), f(err(st, m, 'lut')), f(err(st, m, 'ff')), mk(ea['lut']), mk(ea['ff']),
                    d('dsp'), d('bram36'), d('uram'), f'{eu:+.1f}', p['latency'], r.get('wns', '.')]))
        if round(a['dsp']) != round(m['dsp']) or abs(eu) > 3:
            bad.append(name)
        for k in ('lut', 'ff'):
            if abs(ea[k]) > 5:
                marks.append(f'{name} {k.upper()} {ea[k]:+.1f} %')
        for k in ('bram36', 'uram'):
            if round(a[k] * 2) != round(m[k] * 2):
                marks.append(f'{name} {k} model {a[k]:g} measured {m[k]:g}')
        for grp in ('all', r['set']):
            g = stats.setdefault(grp, {'lut': [], 'ff': [], 'au': [], 'blut': [], 'slut': [], 'sff': []})
            g['lut'].append(abs(ea['lut'])); g['ff'].append(abs(ea['ff'])); g['au'].append(abs(eu))
            g['blut'].append(abs(err(b, m, 'lut'))); g['slut'].append(abs(err(st, m, 'lut'))); g['sff'].append(abs(err(st, m, 'ff')))
    print()
    for grp, g in stats.items():
        s = lambda v: f'max {max(v):.1f} mean {sum(v) / len(v):.1f}'
        print(f'{grp:5s} {len(g["lut"]):2d} rows: before LUT {s(g["blut"])} | structure LUT {s(g["slut"])} FF {s(g["sff"])} '
              f'| after LUT {s(g["lut"])}  FF {s(g["ff"])}  area units {s(g["au"])}  (absolute %)')
    print('\nmarked (LUT or FF above 5 %, memory blocks that differ):')
    for x in marks:
        print('  ' + x)
    print(f'\nstream accuracy gate: {"FAIL " + ", ".join(bad) if bad else "PASS"} (DSP exact and area units within 3 % on every row)')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(HERE))))
    sys.exit(main(sys.argv[1:]))
