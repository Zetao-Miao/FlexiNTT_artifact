'''Area model of the multi-step NTT (operator_modeling/ntt/multistep/MultiStepArea.py) against stored routed results.
    python runMultiStepArea.py [--rows a,b] [--jobs 8] [--stored] [--parts] [--update]
Reprints the table of ntt_hw/experiments/overnight_2026-11-14/fourstep/MODEL_ACCURACY.md from
operator_modeling/ntt/multistep/measured_rows.json (out-of-context place and route, V80, Vivado 2025.1, 350 MHz, NTT
core alone): measured LUT / FF / DSP / BRAM36 / URAM, the model of today's code and its error, the earlier model
(`MultiStepScheme.resources()`: LUT, DSP and memory tiles, no FF), maximum and mean error per group (full: every
multiplier on DSP; budget: under a DSP budget; oldrtl: built with another memory style than today's RTL; option:
rows of the options of 2026-11-14; heldout: builds not used while fitting). --stored prints the model numbers kept in the file instead of recomputing them (no generator run).
The gate fails when a DSP, BRAM36 or URAM count differs from the routed one on a row without a stated reason
(`memNote`), or when an error exceeds the bounds stored in the file (`bounds`).
Latency and interval are not in this table: they are checked cycle by cycle in xsim by runMultiStepRtl.py and
runMultiStepOptions.py (a design slower than the model fails there).
--update (after a wanted change of a model, e.g. of the shared component models): store today's model numbers and
set each group's bounds to its maximum error rounded up to 0.5 %.
Area units = (kLUT + kFF + DSP x 4/3 + BRAM36 + 8 x URAM) / 5.
'''
import sys, os, io, json, contextlib, argparse
import concurrent.futures as cf

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
STORE = os.path.join(HERE, 'operator_modeling', 'ntt', 'multistep', 'measured_rows.json')
KEYS = ('lut', 'ff', 'dsp', 'bram36', 'uram')


def au(d: dict) -> float:
    return (d['lut'] / 1000 + d.get('ff', 0) / 1000 + d['dsp'] * 4 / 3 + d['bram36'] + 8 * d['uram']) / 5


def scheme(row: dict, sources: dict):
    '''The scheme of a stored row: `source` names the row list that defines it (kept beside the builds).'''
    os.environ.setdefault('V80_GENERATOR', HERE)
    d = os.path.normpath(os.path.join(HERE, sources[row['source']]))
    if d not in sys.path:
        sys.path.insert(0, d)
    with contextlib.redirect_stdout(io.StringIO()):
        if row['source'] == 'ms':
            from rows import row_scheme
            return row_scheme(row['name'])
        import opt_rows
        return opt_rows.scheme(row['name'])


def model(args) -> tuple:
    row, sources, parts = args
    from operator_modeling.ntt.multistep import MultiStepArea as A
    with contextlib.redirect_stdout(io.StringIO()):
        t = A.totals(A.inventory(scheme(row, sources)))
    out = {k: (round(t[k], 1) if k in ('bram36',) else int(round(t[k]))) for k in KEYS}
    return row['name'], out, ({c: {k: round(v[k], 1) for k in KEYS} for c, v in t['byClass'].items()} if parts else None)


def pct(a: float, b: float) -> float:
    return (a / b - 1) * 100 if b else 0.0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--rows', default='')
    ap.add_argument('--jobs', type=int, default=8)
    ap.add_argument('--stored', action='store_true')
    ap.add_argument('--parts', action='store_true')
    ap.add_argument('--update', action='store_true')
    a = ap.parse_args()
    db = json.load(open(STORE))
    rows = [r for r in db['rows'] if not a.rows or r['name'] in a.rows.split(',')]
    bounds = db['bounds']
    if a.update and (a.stored or a.rows):
        ap.error('--update recomputes every row')
    models, parts = {}, {}
    if a.stored:
        models = {r['name']: r['model'] for r in rows}
    else:
        with cf.ProcessPoolExecutor(a.jobs) as ex:
            for name, m, p in ex.map(model, [(r, db['sources'], a.parts) for r in rows]):
                models[name], parts[name] = m, p
    if a.update:
        import math
        bounds = {}
        for r in rows:
            r['model'] = models[r['name']]
            b = bounds.setdefault(r['group'], {'lut': 0.0, 'ff': 0.0, 'au': 0.0})
            m, t = r['measured'], r['model']
            for k, e in (('lut', pct(t['lut'], m['lut'])), ('ff', pct(t['ff'], m['ff'])), ('au', pct(au(t), au(m)))):
                b[k] = max(b[k], math.ceil(abs(e) * 2) / 2)
        db['bounds'] = bounds
        json.dump(db, open(STORE, 'w'), indent=1)
        print('store updated:', STORE)
    print(db['what'])
    print(f"{'row':<26} {'group':<8} | {'LUT':>7} {'model':>7} {'err %':>6} {'old %':>6} | {'FF':>7} {'model':>7} {'err %':>6} | "
          f"{'DSP':>5} {'mod':>5} | {'B36':>5} {'mod':>5} | {'U':>3} {'mod':>3} | {'AU':>6} {'model':>6} {'err %':>6}")
    bad = []
    stat = {}
    for r in rows:
        m, t, o = r['measured'], models[r['name']], r.get('before')
        e = {'lut': pct(t['lut'], m['lut']), 'ff': pct(t['ff'], m['ff']), 'au': pct(au(t), au(m))}
        old = f"{pct(o['lut'], m['lut']):+6.1f}" if o else '     -'
        flag = ''
        for k in ('dsp', 'bram36', 'uram'):
            if abs(t[k] - m[k]) > 1e-9:
                if r.get('memNote'):
                    flag = ' (*)'
                else:
                    bad.append(f"{r['name']}: {k} model {t[k]} measured {m[k]}")
        for k in ('lut', 'ff', 'au'):
            if abs(e[k]) > bounds[r['group']][k]:
                bad.append(f"{r['name']}: {k} error {e[k]:+.1f} % above the stored bound {bounds[r['group']][k]} %")
            s = stat.setdefault(r['group'], {}).setdefault(k, [])
            s.append(abs(e[k]))
        print(f"{r['name']:<26} {r['group']:<8} | {m['lut']:>7} {t['lut']:>7} {e['lut']:>+6.1f} {old} | {m['ff']:>7} {t['ff']:>7} "
              f"{e['ff']:>+6.1f} | {m['dsp']:>5} {t['dsp']:>5} | {m['bram36']:>5} {t['bram36']:>5} | {m['uram']:>3} {t['uram']:>3} | "
              f"{au(m):>6.1f} {au(t):>6.1f} {e['au']:>+6.1f}{flag}")
        if a.parts and parts.get(r['name']):
            for c, v in parts[r['name']].items():
                print(f"      {c:<10} " + ' '.join(f"{k} {v[k]:>9}" for k in KEYS))
    for g, s in stat.items():
        print(f"{g:<8} rows {len(s['lut']):>2}: " + ', '.join(
            f"{k.upper()} max {max(s[k]):.1f} % mean {sum(s[k]) / len(s[k]):.1f} %" for k in ('lut', 'ff', 'au')))
    for r in rows:
        if r.get('memNote'):
            print(f"(*) {r['name']}: {r['memNote']}")
    if bad:
        print('FAIL')
        for b in bad:
            print('  ' + b)
        return 1
    print(f"gate area: {len(rows)} of {len(rows)} rows inside the stored bounds, DSP / BRAM36 / URAM exact except (*)")
    return 0


if __name__ == '__main__':
    sys.exit(main())
