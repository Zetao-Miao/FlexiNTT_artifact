"""gen_load.py <row> <source> <slot1|rot> <name> <out dir>: an AutoNTT comparison row of the dataflow NTT in the
loadable-table mode with a self-checking testbench, and model.json (area model) next to it.
slot1: one slot, 3 polynomials of one modulus (the load, then both directions). The change of modulus (drain and
       reload) is NOT simulated here.
rot:   rotating slots under the manager; more moduli than slots, so slots are reused and reloaded."""
import sys, json, io, contextlib, random, time, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'helpers'))
import k1_rows as K
import runModularNTT as rm
from sympy import isprime
from operator_modeling.ntt.dataflow import StreamArea
from operator_modeling.ntt.dataflow.StreamingNTT import StreamingNTT
from operator_modeling.dse import slots
row, src, mode, name, out = sys.argv[1:6]
t0 = time.time()
n, P, mod = K.rowParams(row)
extra = {k: v for k, v in mod.items() if k not in ('q', 'family', 'red', 'nwc', 'jobQ')}
d = K.K1ROWS[row].get('direction', 'both')
def primes(k):
    qs = list(K.moduli(row)); q0 = qs[0]; tz = (q0 - 1) & -(q0 - 1); j = 1
    while len(qs) < k:
        for c in (q0 - j * tz, q0 + j * tz):
            if c.bit_length() == q0.bit_length() and c not in qs and isprime(c) and len(qs) < k:
                qs.append(c)
        j += 1
    return qs[:k]
def build(nslots, **kw):
    return rm.stream(name, n, P, primes(nslots), mod['red'], mod.get('nwc', True), d, family=mod.get('family'),
                     source=src, targetFmaxMhz=350.0, loadableModuli=True, **{**extra, **kw})
def area(s):
    w = StreamArea._Walk(s, 1, name)
    return w, StreamArea.totals(w.parts)
rng = random.Random(9)
quiet = contextlib.redirect_stdout(io.StringIO())
with quiet:
    s = build(1); w, tot = area(s)
    if mode == 'slot1':
        op = StreamingNTT(s)
        op.slotTiming(name, out)
        qq = [s.moduli[0]] * 3
        info = dict(slots=1, loadLanes=1, loadWords=sum(t['words'] for t in w.slotTables()))
    else:
        words = [t['words'] for t in w.slotTables()]
        R = slots.lanesFor(words, s.F); bd = {}
        if R is None and len(s.dirs) > 1:
            bd = dict(loadByDirection=True)
            s = build(1, **bd); w, tot = area(s)
            R = slots.lanesFor([t['words'] for t in w.slotTables()], s.F)
        s0 = build(2, slotManager=True, loadLanes=R, **bd)
        plan = StreamingNTT(s0).managedPlan(name, os.path.join(out, '_plan'))
        s = build(plan['slots'], slotManager=True, loadLanes=R, **bd); w, tot = area(s)
        tim = s.slotTiming(w.slotTables(), w.spec.latency, w.spec.roms['loadWords'])
        ma = slots.managerArea(len(s.moduli), tim)
        tot = dict(tot, lut=tot['lut'] + ma['lut'], ff=tot['ff'] + ma['ff'])
        op = StreamingNTT(s)
        if n >= 65536:
            pl = primes(3); keys = [0, 1, 0, 2]
        else:
            nm = plan['slots'] + 2; pl = primes(nm); keys = list(range(nm)) + [0, 1]
        qq = [pl[i] for i in keys]
        info = dict(slots=plan['slots'], loadLanes=R, byDirection=bool(bd), lead=plan['lead'], fits=plan['fits'],
                    loadWords=sum(t['words'] for t in w.slotTables()), timing={k: v for k, v in plan['timing'].items() if isinstance(v, (int, float))})
    frames = [[rng.randrange(x) for _ in range(n)] for x in qq]
    dirn = ['inv' if (f + f // 2) & 1 else 'fwd' for f in range(len(qq))] if d == 'both' else ('inv' if d == 'inverse' else 'fwd')
    m = op.emitRtl(name, out, frames=frames, direction=dirn, q=qq)
model = dict(row=row, source=src, mode=mode, name=name, latency=m['latency'], F=s.F, frames=len(qq), moduli=len(set(qq)),
             model={k: tot.get(k) for k in ('lut', 'ff', 'dsp', 'bram36', 'uram')}, gen_s=round(time.time() - t0), **info)
json.dump(model, open(f'{out}/model.json', 'w'), indent=1, default=str)
print(json.dumps({k: model[k] for k in ('latency', 'slots', 'loadLanes', 'loadWords', 'frames', 'model')}))
