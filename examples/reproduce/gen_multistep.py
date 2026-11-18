"""gen_row.py <row> <out dir> [polys] [--nosim]: generate a row's core (+ testbench with `polys` polynomials,
mixed moduli and directions, gaps), write model.json; with sim, run xsim and append the verdict."""
import sys, json, time, random, contextlib, io
import os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'helpers'))
from rows import row_scheme, ROWS
from operator_modeling.fourstep.MultiStepNTT import MultiStepNTT, simulate
row, out = sys.argv[1], sys.argv[2]
polys = int(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[3].isdigit() else 4
nosim = '--nosim' in sys.argv
t0 = time.time()
with contextlib.redirect_stdout(io.StringIO()):
    s = row_scheme(row)
rng = random.Random(11)
dirs = [rng.choice(s.dirs) for _ in range(polys)]
qq = [rng.choice(s.moduli) for _ in range(polys)]
xs = [[rng.randrange(q) for _ in range(s.N)] for q in qq]
gaps = [rng.choice([0, 0, 3]) for _ in range(polys)]
if getattr(s, 'loadable', False):
    # jobs: q0 forward, q1 inverse, then q1 forward (a reload and a direction change)
    h = max(1, polys // 2)
    qq = [s.moduli[0]] * h + [s.moduli[1]] * (polys - h)
    dirs = ['fwd'] * h + ['inv'] * max(0, polys - h - 1) + ['fwd'] * (1 if polys - h >= 1 else 0)
    xs = [[rng.randrange(q) for _ in range(s.N)] for q in qq]
op = MultiStepNTT(s)
with contextlib.redirect_stdout(io.StringIO()):
    m = op.emitRtl(row, out, xs, dirs, qq, gaps)
    res = s.resources()
model = {'row': row, 'tpntt': ROWS[row][4], 'N': s.N, 'sizes': s.sizes, 'P': s.P, 'M': len(s.moduli),
         'latency': m['latency'], 'interval': s.F, 'total': res['total'],
         'parts': {k: {a: v.get(a) for a in ('lut', 'dsp', 'bram36', 'uram', 'source', 'latency')} for k, v in res['parts'].items()},
         'multipliers': s.multiplierCount(), 'sources': {t: st['source'] for t, st in s.stages.items()},
         'gen_s': round(time.time() - t0), 'dirs': dirs, 'gaps': gaps,
         'form': s.form, 'formDecision': (None if s.formDecision is None else
                                         {k: s.formDecision.get(k) for k in ('pick', 'pickBuildable', 'reason', 'reasonBuildable', 'rule', 'budget', 'leanDsp', 'table')}),
         'dspSplit': (s.formDecision or {}).get('dspSplit'), 'reloads': getattr(op, 'reloads', [])}
json.dump(model, open(f'{out}/model.json', 'w'), indent=1)
print('generated', json.dumps({k: model[k] for k in ('latency', 'total', 'sources', 'gen_s')}), flush=True)
if not nosim:
    t1 = time.time()
    v, txt = simulate(out, row, timeout=6 * 3600)
    print('xsim', v, round(time.time() - t1), 's |', txt.replace('\n', ' | '), flush=True)
