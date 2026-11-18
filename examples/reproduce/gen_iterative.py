#!/usr/bin/env python3
"""gen_io.py ROW IO OUT [--polys 3] [--tgt 350]: one iterative NTT row of helpers/iter_gen.py ROWS with the data
port overridden to IO lanes , RTL plus the testbench of iter_gen.build
(distinct polynomials back to back, AutoNTT-I's two primes alternating per polynomial on RNS rows, every output beat's
value and cycle checked against the model). Adds to a copy of nothing: the testbench in OUT gets $display lines
(MEAS ...) for the first / last input and output beat of every polynomial. Writes OUT/model.json."""
import argparse, contextlib, io as _io, json, os, random, re, sys, time
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'helpers'))
cwd0 = os.getcwd()
import iter_gen                                     # changes into the repository root
from operator_modeling.ntt.NTT import IterativeNTT
r = iter_gen.r

class mip:
    @staticmethod
    def scheme(row, io, tgt):
        n, B, mod, red, extra = iter_gen.ROWS[row]
        extra = dict(extra)
        nwc = extra.pop('nwc', True)
        fam = mod if not isinstance(mod, int) else None
        q = 0 if fam else mod
        if io:
            extra['ioLanes'] = io
        src = extra.pop('twiddleSource', 'ram' if fam else None)
        with contextlib.redirect_stdout(_io.StringIO()):
            return r.iterative(row, n, B, q, red, nwc, 'both', family=fam, source=src, targetFmaxMhz=tgt, **extra)

ap = argparse.ArgumentParser()
ap.add_argument('row'); ap.add_argument('io', type=int); ap.add_argument('out')
ap.add_argument('--polys', type=int, default=3); ap.add_argument('--tgt', type=float, default=350.0)
ap.add_argument('--model', action='store_true')
a = ap.parse_args()
out = a.out if os.path.isabs(a.out) else os.path.join(cwd0, a.out)
row, P = a.row, a.polys
s = mip.scheme(row, a.io, a.tgt)
assert s.io == a.io, (s.io, a.io)
with contextlib.redirect_stdout(_io.StringIO()):
    job = s.simulateJob(P); job1 = s.simulateJob(1); res = s.resources()
md = dict(row=row, io=s.io, n=s.n, B=s.B, beats=s.beats, polys=P, tgt=a.tgt, computeCycles=s.computeCycles(),
          interval=job['interval'], latency_one_poly=job1['latency'], latency_first_of_job=job['latency'],
          lut=res['lut'], ff=res['ff'], dsp=res['dsp'], bram=res['bram'], uram=res['uram'],
          rns=bool(s.rns), memOrg=s.memOrg, bubble=(s.rnsBubble() if s.rns else None))
for k in ('acc', 'in', 'out'):
    if k in job:
        md[k + '_first_last'] = [[x[0], x[-1]] for x in job[k]]
        md[k + '1_first_last'] = [[x[0], x[-1]] for x in job1[k]]
print(json.dumps(md), flush=True)
if a.model:
    sys.exit(0)
rng = random.Random(11)
q = iter_gen.r._jobQ(s, rng)
extra = {}
if s.rns:
    qa, qb = iter_gen.pairOf(row)
    q = [qa if k % 2 == 0 else qb for k in range(P)]
    extra = dict(twValidPattern=None)
frames = [[rng.randrange(qq) for _ in range(s.n)] for qq in (q if isinstance(q, list) else [q] * P)]
t0 = time.time()
os.makedirs(out, exist_ok=True)
with contextlib.redirect_stdout(_io.StringIO()):
    m = IterativeNTT(s).emitRtl(row, out, frames=frames, direction='inv', q=q, validPattern=None, **extra)
md.update(q=q, gen_seconds=round(time.time() - t0), io_lanes_manifest=m.get('io_lanes'))
json.dump(md, open(out + '/model.json', 'w'), indent=1, default=str)
# measurement lines in the testbench
tb = f'{out}/RTL_generated/{row}_tb.sv'
t = open(tb).read()
NB = s.beats
a1 = 'if (in_valid && in_ready) xb++;'
a2 = 'if (out_valid) begin'
assert t.count(a1) == 1 and t.count(a2) == 1, (t.count(a1), t.count(a2))
t = t.replace(a2, f'if (out_valid && ob < {P * NB} && (ob % {NB} == 0 || ob % {NB} == {NB - 1})) '
              f'$display("MEAS out %s poly %0d cycle %0d", (ob % {NB} == 0) ? "first" : "last", ob / {NB}, c);\n'
              f'            {a2}')
t = t.replace(a1, f'if (in_valid && in_ready && (xb % {NB} == 0 || xb % {NB} == {NB - 1})) '
              f'$display("MEAS in %s poly %0d cycle %0d", (xb % {NB} == 0) ? "first" : "last", xb / {NB}, c);\n'
              f'            {a1}')
open(tb, 'w').write(t)
print('generated', out, md['gen_seconds'], 's', flush=True)
