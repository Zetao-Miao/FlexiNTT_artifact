#!/usr/bin/env python3
'''Gates for NTTs built from the modular butterfly (`ModularBU` in `operator_modeling/ntt/butterfly/ButterflyScheme.py`).

The butterfly is `ModularButterflyScheme`: a `ModularMultiplierScheme` (any
reduction) and two `ModularAdderScheme`s, composed into one datapath. Here it
fills a whole `FullyPipelinedNTT` / `FullyPipelinedINTT` grid, for any q.

Gate 0  the butterfly unit: every modular multiplier kind (Barrett,
        Montgomery, word-level Montgomery and its generic form, K-RED,
        Mersenne, Solinas, fold, table, shift-add, Shoup) with its moduli,
        fixed and at run time, the twiddle as a constant or as inputs, CT and
        GS, exact and lazy ranges, against the reference; and through the
        `Butterfly` operator's ports.
Gate 1  model: `verifyNtt` / `verifyIntt` (every output against the O(n^2)
        reference mod q, every value inside its predicted bound) over moduli
        of 30-64 bits (NTT-friendly k*2^w+1 and Goldilocks), n = 8..32, NTT
        and INTT, CT and GS, cyclic and negacyclic, Barrett / Montgomery /
        word-level Montgomery / Goldilocks fold, constants on LUTs or DSPs,
        lazy products and lazy outputs.
Gate 2  the composition: a trivial twiddle costs no multiplier; each
        butterfly's datapath is the multiplier child and the two adder
        children (nodes named after them); the model's resources are the
        datapath's.
Gate 3  clocked: `reset()` / `step()` stream against `compute()`, outputs on
        step LAT-1+j, nothing before.
Gate 4  `--rtl DIR`: RTL for single butterflies (`ModularBU.emitRtl`, own
        testbench) and a set of NTTs (layer latencies asserted against
        the model by `emitRtl`, test vectors checked locally); `--sim` runs
        each in xsim (`scripts/run_remote_sim.py`, slot `$V80_REMOTE_ROOT`).
Gate 5  the streaming NTT's model; gate 6 (`--rtl`) its RTL.
Gate 7  the iterative NTT's model (`IterativeNTTScheme`): bank map and schedule
        (conflict-free banks and I/O beats, every point read after its
        write-back), forward vs the reference and inverse == x over n 16..32768,
        B 1..256, every reduction, fixed and run-time q, cyclic / negacyclic,
        forward / inverse / both, x2^-1 per stage or output scaling, I/O widths,
        DSP budgets; the controller twin's back-to-back interval.
Gate 8  (`--rtl`) the iterative NTT's RTL (`IterativeNTT.emitRtl`): distinct
        polynomials back to back, random input valid on some, every output
        beat's value and cycle checked; xsim over six slots in parallel.
        Gates 7 and 8 run today's points with twiddleBuffer='single' (one q per
        job); `gate7rns` / `gate8rns` the modulus per polynomial ('recycle',
        'double'): alternating primes, kept runs, record-stream stalls.
        `gate7cgRec` / `gate8rns(points=ITER_CG_REC_POINTS)`: the twiddles
        generated on chip (twiddleSource 'rec', constant geometry).
        `gate7ipRec` / `gate8rns(points=ITER_IP_REC_POINTS)`: the same in place
        (the record is its header alone; the testbench also checks the rate).

Gate 5  the streaming (dataflow) NTT's model (`StreamingNTTScheme.transform`): fixed and
        run-time q, twiddles 'rom' / 'ram' / 'otf' / 'rec' (root recurrence), and the
        per-polynomial modulus mode (`moduli=[...]`: frames with different moduli of a
        mixed-width table, and Kim et al.'s q0..q41, back to back), against the reference.
Gate 6  `--rtl DIR`: streaming NTT RTL with testbenches; `--sim` runs them in xsim
        (the per-frame points drive MIDX per frame).

    source ../ntt_hw/env.sh
    python3 runModularNTT.py                    # gates 1-3 (about a minute)
    python3 runModularNTT.py --rtl DIR --sim    # and gate 4
'''
from __future__ import annotations

import argparse
import contextlib
import io
import os
import random
import subprocess
import sys
import time

from operator_modeling.core.IntType import IntType
from operator_modeling.modmult.ModulusFamily import ModulusFamily as MF
from operator_modeling.modmult.ReductionScheme import (
    GOLDILOCKS, BarrettReduction, FoldReduction, GoldilocksReduction, KRedReduction, MersenneReduction,
    MontgomeryReduction, ShiftAddReduction, SolinasReduction, TableLookupReduction, WordLevelMontgomery)
from operator_modeling.modmult.primes import isPrime, nttFriendlyPrime, pseudoMersennePrime, randomPrime, solinasPrime
from operator_modeling.modmult import kim_moduli
from operator_modeling.ntt.butterfly.Butterfly import Butterfly
from operator_modeling.ntt.butterfly.ButterflyScheme import ModularBU
from operator_modeling.ntt.pipelined.FullyPipelinedNTT import FullyPipelinedINTT, FullyPipelinedNTT
from operator_modeling.ntt.iterative.IterativeNTT import IterativeNTT
from operator_modeling.ntt.dataflow.StreamingNTT import StreamingNTT
from operator_modeling.ntt.iterative.IterativeNTTScheme import IterativeNTTScheme
from operator_modeling.ntt.dataflow.StreamingNTTScheme import StreamingNTTScheme
from operator_modeling.core.utils import bitReverse
from operator_modeling.ntt.verification import referenceNtt
from operator_modeling.ntt.twiddles import calculateInttTwiddles, calculateNttTwiddles
from operator_modeling.ntt.verification import verifyIntt, verifyNtt

Q30 = nttFriendlyPrime(30, 12)
Q52 = nttFriendlyPrime(52, 16)
Q62 = nttFriendlyPrime(62, 17)
REDUCTIONS = {'barrett': BarrettReduction, 'mont': MontgomeryReduction,
              'wlm': WordLevelMontgomery, 'gold': GoldilocksReduction, 'kred': KRedReduction,
              'mersenne': MersenneReduction, 'solinas': SolinasReduction, 'fold': FoldReduction,
              'table': TableLookupReduction, 'shiftadd': ShiftAddReduction}
QP52 = randomPrime(52, 3)
KRED_Q = next(k * 2 ** 23 + 1 for k in range(127, 63, -1) if isPrime(k * 2 ** 23 + 1))   # a prime K-RED modulus
#: per reduction: (arguments, fixed moduli of its kind, run-time families it supports)
UNITS = {
    'barrett': ({}, [Q30, QP52, Q62], [('odd30', MF.odd(30)), ('odd62', MF.odd(62)), ('fr17x45', MF.friendly(17, 45)),
                                      ('pm61x12', MF.pseudoMersenne(61, 12))]),
    'mont': ({}, [Q30, QP52, Q62], [('odd30', MF.odd(30)), ('odd52', MF.odd(52)), ('fr16x14', MF.friendly(16, 14))]),
    'wlm': ({}, [Q30, Q52, Q62], [('fr17x45', MF.friendly(17, 45)), ('fr16x14', MF.friendly(16, 14))]),
    'wlm-generic': ({'w': 26, 'variant': 'generic'}, [], [('odd52', MF.odd(52)), ('odd62', MF.odd(62))]),
    'kred': ({}, [KRED_Q], [('kr23x7', MF.kred(23, 7)), ('kr26x4', MF.kred(26, 4))]),
    'mersenne': ({}, [2 ** 31 - 1, 2 ** 61 - 1], []),
    'solinas': ({}, [pseudoMersennePrime(61), pseudoMersennePrime(32)], [('pm61x12', MF.pseudoMersenne(61, 12)),
                                                                         ('pm32x8', MF.pseudoMersenne(32, 8))]),
    'fold': ({}, [solinasPrime(62), solinasPrime(40)], []),
    'table': ({'chunkBits': 4}, [Q30, randomPrime(40, 5)], []),
    'shiftadd': ({}, [Q30, Q62], []),
    'shoup': (None, [Q30, QP52, Q62], [('odd30', MF.odd(30)), ('odd52', MF.odd(52)), ('fr17x45', MF.friendly(17, 45))]),
}


def quiet(fn):
    with contextlib.redirect_stdout(io.StringIO()):
        return fn()


def build(name, n, q, kind, inverse=False, negacyclic=False, red='barrett', **bu):
    '''A populated-ready NTT / INTT whose every butterfly is a `ModularBU`.'''
    twf = calculateInttTwiddles if inverse else calculateNttTwiddles
    tw = twf(modulus=q, n=n, butterflyType=kind, negacyclic=negacyclic)
    cls = FullyPipelinedINTT if inverse else FullyPipelinedNTT
    # a frequency target belongs to the NTT: emitRtl writes it through to every butterfly
    inst = cls(name=name, n=n, q=q, butterflyType=kind, twiddles=tw, negacyclic=negacyclic,
               targetFmaxMhz=bu.get('targetFmaxMhz'))
    layers = n.bit_length() - 1
    inst.setScheme([[ModularBU(name=f'{name}_L{s}_p{p}', butterflyType=kind, q=q,
                               reduction=REDUCTIONS[red], **bu)
                     for p in range(n // 2)] for s in range(layers)])
    return inst


def inputBound(q, k=1):
    return IntType(0, k * q - 1)


def verify(inst, q, batch=40, seed=1, inverse=False):
    fn = verifyIntt if inverse else verifyNtt
    b = inputBound(q)
    return quiet(lambda: fn(inst, batchSize=batch, seed=seed, inputBound=b, valueRange=(0, q - 1), verbose=True))


# --- gate 0: the butterfly unit -------------------------------------------------

def unit(name, kind, red, q=0, family=None, twiddle=None, k=1, **kw):
    '''A `ModularBU` with input bounds [0, k*qMax): `red` a reduction key or 'shoup'.'''
    args = UNITS[red][0]
    mk = 'shoup' if red == 'shoup' else 'reduction'
    cls = REDUCTIONS.get(red.split('-')[0], BarrettReduction)
    bu = ModularBU(name=name, butterflyType=kind, q=q, family=family, multiplierKind=mk, reduction=cls,
                   reductionArgs=args or {}, twiddleInput=twiddle is None, **kw)
    qmax = family.qMax if family is not None else q
    bu.aIn = bu.bIn = IntType(0, k * qmax - 1)
    if twiddle is not None:
        bu.twiddle = twiddle
    return bu


def gate0(quick: bool) -> int:
    '''Every modular multiplier kind x its moduli (fixed, and run-time where it has
    one) x constant / input twiddle x CT / GS x exact / lazy ranges, each over
    400 trials against the big-integer reference; a subset through the Butterfly
    operator's ports.'''
    beh = dict(multiplier='behavioural', qBackend='behavioural')
    cases = []
    for red, (args, qs, fams) in UNITS.items():
        for q in qs:
            for kind in ('CT', 'GS'):
                for tw in ('const', 'port'):
                    for rg in (('exact', 'exact', 1), (2, 2, 2)):
                        if red == 'shoup' and rg[0] != 'exact':
                            rg = (2, 'exact', 1)
                        cases.append((f'{red} q{q.bit_length()} {kind} {tw} out={rg[1]}',
                                      dict(red=red, kind=kind, q=q, k=rg[2], productRange=rg[0], outputRange=rg[1],
                                           twiddle=random.Random(q).randrange(2, q) if tw == 'const' else None)))
        for lab, fam in fams:
            for kind in ('CT', 'GS'):
                cases.append((f'{red} {lab} (run time) {kind} port', dict(red=red, kind=kind, family=fam, inRange=1)))
                cases.append((f'{red} {lab} (run time) {kind} port static', dict(red=red, kind=kind, family=fam,
                                                                                 inRange=1, staticModulus=True)))
    if quick:
        cases = cases[::3]
    t0, fails, kinds = time.time(), 0, set()
    for tag, kw in cases:
        try:
            bu = unit('g0', **kw, **beh)
            ins = bu.inner().sampleInputs(400, random.Random(1))
            err = bu.inner().checkReference(ins)
            ok = not err
            kinds.add(kw['red'])
        except Exception as e:                       # noqa: BLE001
            ok, err = False, [f'{type(e).__name__}: {e}']
        if not ok:
            fails += 1
            print(f'  FAIL {tag}: {err[0][:160]}')
    print(f'gate 0 butterfly units: {len(cases) - fails} of {len(cases)} pass over {len(kinds)} multiplier kinds '
          f'(400 trials each, {time.time() - t0:.0f}s)')
    # through the operator: ports, bounds and values on Butterfly
    for red, fam, kind in (('shoup', MF.odd(52), 'CT'), ('wlm', MF.friendly(17, 45), 'GS'),
                           ('kred', MF.kred(23, 7), 'CT'), ('solinas', MF.pseudoMersenne(61, 12), 'GS'),
                           ('barrett', MF.odd(62), 'GS'), ('mont', MF.odd(30), 'CT')):
        bu = unit('g0op', kind, red, family=fam, inRange=1, **beh)
        bf = Butterfly(name='bf', butterflyType=kind, scheme=bu)
        ins = bu.inner().sampleInputs(200, random.Random(2), corners=False)
        bnd = IntType(0, fam.qMax - 1)
        bf.initializeInputs(bnd, bnd)
        for p in bf.portNames():
            bf.initializePort(p, bu.defaultPortBound(p))
        bf.compute()
        bf.initializeInputs(ins['A'], ins['B'])
        for p in bf.portNames():
            bf.initializePort(p, ins[p])
        bf.compute()
        want = bu.inner().datapath().run(ins)
        ok = (bf.outputPortA.testVector == want['X'] and bf.outputPortB.testVector == want['Y']
              and not bu.checkReference())
        fails += not ok
        print(f"  operator {red} {fam.kind} {kind}: ports {['A', 'B', *bf.portNames()]} {'ok' if ok else 'FAIL'}")
    return fails


# --- gate 1 ------------------------------------------------------------------

def gate1(quick: bool) -> int:
    cases = []
    for q, qn in ((Q30, 'q30'), (Q52, 'q52'), (Q62, 'q62'), (GOLDILOCKS, 'gold')):
        reds = ['barrett', 'mont', 'wlm'] + (['gold'] if q == GOLDILOCKS else [])
        for red in reds:
            for kind in ('CT', 'GS'):
                cases.append((qn, q, 8, kind, False, False, red, {}))
                cases.append((qn, q, 16, kind, True, False, red, {}))
        cases.append((qn, q, 16, 'CT', False, True, 'barrett', {}))          # forward negacyclic
        cases.append((qn, q, 16, 'GS', True, True, 'mont', {}))              # inverse negacyclic
        cases.append((qn, q, 8, 'CT', False, False, 'barrett', {'constBackend': 'dsp'}))
        cases.append((qn, q, 8, 'GS', False, False, 'mont', {'productRange': 'lazy'}))
        cases.append((qn, q, 8, 'CT', False, False, 'barrett', {'productRange': 'lazy', 'outputRange': 2}))
    cases.append(('q62', Q62, 32, 'CT', False, False, 'barrett', {}))
    cases.append(('q62', Q62, 32, 'GS', True, True, 'wlm', {}))
    if quick:
        cases = cases[::3]
    t0 = time.time()
    fails = 0
    print(f'gate 1 model: {len(cases)} NTT/INTT designs, every output vs the reference mod q, every value in its bound')
    for qn, q, n, kind, inv, nwc, red, bu in cases:
        tag = f"{'intt' if inv else 'ntt'}{n} {kind}{' nwc' if nwc else ''} {qn} {red}" + \
              ''.join(f' {k}={v}' for k, v in bu.items())
        try:
            inst = build('g1', n, q, kind, inv, nwc, red, **bu)
            ok = verify(inst, q, inverse=inv)
            lut, dsp = quiet(inst.areaCost)
            lat = quiet(lambda: inst.latency(1))
        except Exception as e:                       # noqa: BLE001 — a failing case is reported, not fatal
            ok, lut, dsp, lat = False, 0, 0, 0
            print(f'  {tag}: {type(e).__name__}: {e}')
        if not ok:
            fails += 1
        print(f"  {tag:<52} {'ok  ' if ok else 'FAIL'} latency {lat:3d}  LUT~{lut:7d}  DSP {dsp:4d}")
    print(f'gate 1: {len(cases) - fails} of {len(cases)} pass ({time.time() - t0:.0f}s)')
    return fails


# --- gate 2 ------------------------------------------------------------------

def gate2() -> int:
    fails = 0
    n, q = 8, Q52
    inst = build('g2', n, q, 'CT')
    quiet(lambda: verify(inst, q))
    first = inst.butterflies[0][0].scheme            # CT layer 0: every twiddle is 1
    later = inst.butterflies[-1][1].scheme
    def kinds(bu):
        return [nd.kind for nd in bu.inner().datapath().nodes]
    def names(bu):
        return {nd.name for nd in bu.inner().datapath().nodes}
    for red in ('barrett', 'mont', 'wlm'):           # whatever the reduction's factor
        one = build('g2' + red, n, q, 'CT', red=red)
        quiet(lambda: verify(one, q))
        bu = one.butterflies[0][0].scheme
        if 'mp' in names(bu) or bu.inner().reduction is not None:
            fails += 1
            print(f'  {red}: a twiddle of 1 built a product or a reduction')
    if 'mp' not in names(later) or later.inner().reduction is None:
        fails += 1
        print('  a non-trivial twiddle built no product / reduction')
    inner = later.inner()
    if inner.multiplierChild is None or len(inner.adderChildren) != 2:
        fails += 1
        print('  the butterfly is not one multiplier child and two adder children')
    names = {nd.name for nd in inner.datapath().nodes}
    for need in ('mp', 'x', 'y'):
        if need not in names:
            fails += 1
            print(f'  node {need} (multiplier / adder child) missing from the datapath')
    r = later.resources(1)
    d = inner.datapath().resources(inner.schedule(1))
    if (r.lut, r.dsp) != (d.lut, d.dsp):
        fails += 1
        print('  the butterfly does not report its datapath\'s resources')
    # the NTT's cost is the sum over its butterflies
    lut = sum(b.scheme.areaCost()[0] for layer in inst.butterflies for b in layer)
    if inst.areaCost()[0] != lut:
        fails += 1
        print('  the NTT does not sum its butterflies')
    print(f'gate 2 composition: {"pass" if not fails else f"{fails} FAILING"} '
          f'(layer-0 butterfly {kinds(first)}, layer-2 nodes {len(kinds(later))}, '
          f'{lut} LUTs over {n // 2 * 3} butterflies)')
    return fails


# --- gate 3 ------------------------------------------------------------------

def gate3() -> int:
    fails = 0
    n, K, trials = 8, 5, 4
    for q, kind, red, req in ((Q30, 'CT', 'barrett', 1), (Q62, 'GS', 'mont', [0, 2, 1]), (Q52, 'CT', 'wlm', 3)):
        inst = build('g3', n, q, kind, red=red)
        random.seed(5)
        batches = [[[random.randint(0, q - 1) for _ in range(trials)] for _ in range(n)] for _ in range(K)]
        b = [inputBound(q)] * n
        inst.getInputsNatural(b)
        quiet(inst.compute)
        expected = []
        for bt in batches:
            inst.getInputsNatural(b)
            inst.getInputsNatural(bt)
            quiet(inst.compute)
            expected.append([list(p.signal.values) for p in inst.outputPorts])
        LAT = inst.latency(req)
        quiet(lambda: inst.reset(req))
        checked = 0
        for t in range(K + LAT):
            inst.getInputsNatural(batches[min(t, K - 1)])
            inst.step()
            got = [p.signal.values for p in inst.outputPorts]
            if t < LAT - 1:
                if not all(v is None for v in got):
                    fails += 1
            else:
                j = t - max(LAT - 1, 0)
                if j < K:
                    if got != expected[j]:
                        fails += 1
                    checked += 1
        ok = checked == K and not fails
        print(f"  n={n} {kind} {red} request {req}: layers {inst.scheme.layerLatencies(req)} LAT {LAT}, "
              f"{checked} batches {'ok' if ok else 'FAIL'}")
    print(f'gate 3 clocked: {"pass" if not fails else f"{fails} FAILING"}')
    return fails


# --- gate 4 ------------------------------------------------------------------

RTL_POINTS = [
    # name, n, q, kind, inverse, negacyclic, reduction, stages, ModularBU kwargs
    ('mntt8_ct_barrett_q30', 8, Q30, 'CT', False, False, 'barrett', 1, {}),
    ('mntt8_gs_mont_q52_dspc', 8, Q52, 'GS', False, False, 'mont', 1, {'constBackend': 'dsp'}),
    ('mintt8_gs_wlm_q62_s2', 8, Q62, 'GS', True, False, 'wlm', 2, {}),
    ('mntt8_ct_gold', 8, GOLDILOCKS, 'CT', False, False, 'gold', 1, {}),
    ('mntt16_ct_nwc_barrett_q62_lazy', 16, Q62, 'CT', False, True, 'barrett', 1,
     {'productRange': 'lazy', 'outputRange': 2}),
    ('mintt16_gs_nwc_mont_q62_f400', 16, Q62, 'GS', True, True, 'mont', 1, {'targetFmaxMhz': 400.0}),
]


BU_POINTS = [
    # one butterfly through ModularBU.emitRtl: name, unit() arguments, stages
    ('mbu_ct_barrett_q62', dict(kind='CT', red='barrett', q=Q62, twiddle=3), 1),
    ('mbu_gs_mont_q52_lazyin', dict(kind='GS', red='mont', q=Q52, twiddle=12345, k=2), 2),
    ('mbu_ct_wlm_q62_dspc', dict(kind='CT', red='wlm', q=Q62, twiddle=98765, constBackend='dsp'), 1),
    ('mbu_ct_one_q30', dict(kind='CT', red='mont', q=Q30, twiddle=1), 1),
    ('mbu_ct_shoup_q62_port', dict(kind='CT', red='shoup', q=Q62), 1),
    ('mbu_gs_shoup_q52_const', dict(kind='GS', red='shoup', q=QP52, twiddle=777), 1),
    ('mbu_gs_mersenne61_port', dict(kind='GS', red='mersenne', q=2 ** 61 - 1), 1),
    ('mbu_ct_fold62_const', dict(kind='CT', red='fold', q=solinasPrime(62), twiddle=4242), 1),
    ('mbu_ct_table40_port', dict(kind='CT', red='table', q=randomPrime(40, 5)), 1),
    ('mbu_gs_shiftadd_q62_port', dict(kind='GS', red='shiftadd', q=Q62), 1),
    ('mbu_ct_rt_barrett_odd62', dict(kind='CT', red='barrett', family=MF.odd(62), inRange=1), 1),
    ('mbu_gs_rt_mont_odd52', dict(kind='GS', red='mont', family=MF.odd(52), inRange=1), 1),
    ('mbu_ct_rt_wlm_fr17x45', dict(kind='CT', red='wlm', family=MF.friendly(17, 45), inRange=1), 1),
    ('mbu_gs_rt_wlmgen_odd62', dict(kind='GS', red='wlm-generic', family=MF.odd(62), inRange=1), 1),
    ('mbu_ct_rt_kred_kr23x7', dict(kind='CT', red='kred', family=MF.kred(23, 7), inRange=1), 1),
    ('mbu_gs_rt_solinas_pm61', dict(kind='GS', red='solinas', family=MF.pseudoMersenne(61, 12), inRange=1), 1),
    ('mbu_ct_rt_shoup_odd52', dict(kind='CT', red='shoup', family=MF.odd(52), inRange=1), 1),
    ('mbu_gs_rt_shoup_fr17x45_static', dict(kind='GS', red='shoup', family=MF.friendly(17, 45), inRange=1,
                                            staticModulus=True), 1),
]


def _sim(run: str) -> str:
    r = subprocess.run([sys.executable, 'scripts/run_remote_sim.py', '--run-dir', run], capture_output=True, text=True)
    with open(os.path.join(run, 'sim.log'), 'w', encoding='utf-8') as f:
        f.write(r.stdout + r.stderr)
    return next((ln.split(': ', 1)[1] for ln in r.stdout.splitlines()
                 if ln.startswith('[run_remote_sim]') and (': PASS' in ln or ': FAIL' in ln)), 'NO VERDICT')


def gate4b(root: str, only, sim: bool, test_size: int) -> int:
    fails = 0
    points = [p for p in BU_POINTS if not only or p[0] in only]
    for name, kw, stages in points:
        t0 = time.time()
        sch = unit(name, **kw)
        run = os.path.join(root, name)
        meta = quiet(lambda: sch.emitRtl(name, run, pipeline_stages=stages, test_size=test_size, seed=4))
        lut, dsp = quiet(sch.areaCost)
        line = (f"  {name:<34} ports {','.join(['A', 'B', *sch.portNames()]):<16} latency {meta['pipeline_latency']:3d}"
                f"  LUT~{lut:6d} DSP {dsp:3d}")
        if sim:
            v = _sim(run)
            fails += not v.startswith('PASS')
            line += f'  xsim {v}'
        print(line + f'  ({time.time() - t0:.0f}s)')
    print(f'gate 4b butterflies: {len(points) - fails} of {len(points)} '
          f"{'simulated and passing' if sim else 'generated'}")
    return fails


def gate4(root: str, only, sim: bool, test_size: int) -> int:
    fails = 0
    points = [p for p in RTL_POINTS if not only or p[0] in only]
    for name, n, q, kind, inv, nwc, red, stages, bu in points:
        t0 = time.time()
        inst = build(name, n, q, kind, inv, nwc, red, **bu)
        random.seed(7)
        b = inputBound(q)
        inst.getInputsNatural([b] * n)
        quiet(inst.compute)
        inst.getInputsNatural([[random.randint(0, q - 1) for _ in range(test_size)] for _ in range(n)])
        quiet(inst.compute)
        run = os.path.join(root, name)
        man = quiet(lambda: inst.emitRtl(name, run, pipeline_stages_per_layer=stages))
        lut, dsp = inst.areaCost()
        line = (f"  {name:<34} layers {str(man['layer_latency']):<16} latency {man['total_latency']:3d}  "
                f"LUT~{lut:6d} DSP {dsp:3d}")
        if sim:
            verdict = _sim(run)
            if not verdict.startswith('PASS'):
                fails += 1
            line += f'  xsim {verdict}'
        print(line + f'  ({time.time() - t0:.0f}s)')
    print(f'gate 4 rtl: {len(points) - fails} of {len(points)} '
          f"{'simulated and passing' if sim else 'generated'}")
    return fails


# --- gates 5 and 6: the streaming (dataflow) NTT ------------------------------------

#: constructor options `stream()` passes through to `StreamingNTTScheme`
STREAM_OPTIONS = ('unified', 'outputOrder', 'outReady', 'outDepth', 'loadableModuli', 'loadLanes', 'slotManager',
                  'loadByDirection')


def stream(name, n, P, q=0, red='barrett', nwc=False, direction='forward', family=None, source=None, **bu):
    '''q: a fixed modulus, or a list = one modulus per polynomial from a table (moduli=).'''
    mk = 'shoup' if red == 'shoup' else 'reduction'
    cls = REDUCTIONS.get(red.split('-')[0], BarrettReduction)
    tgt = bu.pop('targetFmaxMhz', None)
    ireg = bu.pop('inputRegister', False)
    iscale = bu.pop('inverseScale', 'output')
    frac, total = bu.pop('dspFraction', None), bu.pop('dspTotal', None)
    bfrac, btotal = bu.pop('bramFraction', None), bu.pop('bramTotal', None)   # setBramBudget (2026-11-14)
    bt = bu.pop('butterflyType', 'CT')
    omb = bu.pop('otfMinBits', 0)
    tws = bu.pop('twistSource', None)
    opts = {k: bu.pop(k) for k in STREAM_OPTIONS if k in bu}   # the dataflow options of 2026-11-14 (off by default)
    args = dict(multiplierKind=mk, reduction=cls, reductionArgs=(UNITS.get(red, ({},))[0] or {}), **bu)
    extra = dict(otfMinBits=omb) if omb else {}
    extra.update(opts)
    if tws:
        extra['twistSource'] = tws
    if isinstance(q, (list, tuple)):
        extra['moduli'], q = list(q), 0
    s = StreamingNTTScheme(name, n, P, q=q, family=family, negacyclic=nwc, direction=direction, butterflyType=bt,
                           scaleInverse=direction != 'forward', butterfly=args, twiddleSource=source,
                           targetFmaxMhz=tgt, inputRegister=ireg, inverseScale=iscale, **extra)
    s.setInputBound(IntType(0, s.qMax() - 1))
    if bfrac is not None or btotal is not None:
        s.setBramBudget(fraction=bfrac, total=btotal)
    if frac is not None or total is not None:
        s.setDspBudget(fraction=frac, total=total)
    return s


def friendlyPrimes(v, qhBits, order, k, first=None):
    '''k primes q = qH*2^v + 1 with qH of exactly qhBits bits and order | q - 1, the largest qH first
    (`first`, e.g. AutoNTT's prime, leads the list).'''
    out = [first] if first else []
    qh = (1 << qhBits) - 1
    while len(out) < k and qh >= 1 << (qhBits - 1):
        q = qh * (1 << v) + 1
        if q not in out and (q - 1) % order == 0 and isPrime(q):
            out.append(q)
        qh -= 1
    if len(out) < k:
        raise ValueError(f'only {len(out)} primes qH*2^{v}+1 with {qhBits}-bit qH and {order} | q-1')
    return out


def _jobQ(s, rng):
    if not s.runtime:
        return s.q
    if s.perFrame:
        return rng.choice(s.moduli)
    q = s.family.samplePrimeCongruent(rng, s.rootOrder())
    if q is None:
        raise ValueError(f'{s.name}: no prime of {s.family.describe()} with {s.rootOrder()} | q-1')
    return q


def _memFrame(x, n):
    L = n.bit_length() - 1
    return [x[bitReverse(m, L)] for m in range(n)]


def gate5(quick: bool) -> int:
    """The streaming NTT's model against the O(n^2) reference: forward (cyclic and
    negacyclic) and the inverse of the same pipeline in the shared mode, over n, P,
    moduli and multiplier kinds."""
    cases = []
    for red, q in (('barrett', Q30), ('mont', Q52), ('wlm', Q62), ('shoup', Q52), ('kred', KRED_Q)):
        for n, P in ((16, 2), (64, 8), (256, 4), (256, 32), (1024, 16)):
            for nwc in (False, True):
                if (q - 1) % (2 * n):
                    continue
                cases.append((red, q, n, P, nwc))
    cases = [(r, q, n, P, nwc, None, None) for r, q, n, P, nwc in cases]
    for red, fam in (('wlm', MF.friendly(17, 45)), ('barrett', MF.odd(52)), ('mont', MF.odd(30)),
                     ('shoup', MF.odd(52)), ('wlm-generic', MF.odd(62)), ('kred', MF.kred(23, 7))):
        for src in ('ram', 'otf'):
            for n, P, nwc in ((64, 8, True), (256, 4, False), (1024, 32, True), (128, 8, False)):
                cases.append((red, 0, n, P, nwc, fam, src))
    if quick:
        cases = cases[::3]
    t0, fails = time.time(), 0
    for red, q, n, P, nwc, fam, src in cases:
        tag = f"{red} {fam.describe() if fam else f'q{q.bit_length()}'} {src or 'rom'} n={n} P={P} nwc={nwc}"
        try:
            s = stream('g5', n, P, q, red, nwc, direction='both', family=fam, source=src,
                       multiplier='behavioural', qBackend='behavioural')
            rng = random.Random(n + P)
            ok = True
            for _ in range(2 if fam else 1):
                qq = _jobQ(s, rng)
                xs = [[rng.randrange(qq) for _ in range(n)] for _ in range(2)]
                Y = s.transform([_memFrame(x, n) for x in xs], 'fwd', qq)
                ok = ok and all(Y[f] == referenceNtt(xs[f], qq, negacyclic=nwc) for f in range(2))
                X = s.transform([_memFrame(y, n) for y in Y], 'inv', qq)
                ok = ok and X == xs
                if src == 'otf':
                    for key in s.slotClasses():
                        s.otfTables(key, qq)
        except Exception as e:                       # noqa: BLE001
            ok = False
            print(f'  {tag}: {type(e).__name__}: {e}')
        fails += not ok
        if not ok:
            print(f'  FAIL {tag}')
    # the inverse scaled by x2^-1 per stage (cyclic): same checks, no output multiplier
    for red, q, fam, src in (('wlm', 0, MF.friendly(32, 32), 'ram'), ('barrett', Q30, None, None),
                             ('mont', 0, MF.odd(30), 'otf'), ('shoup', Q52, None, 'rom')):
        for n, P in ((64, 4), (256, 8)):
            if q and (q - 1) % n:
                continue
            tag = f"stage-scaled {red} {fam.describe() if fam else f'q{q.bit_length()}'} n={n} P={P}"
            try:
                s = stream('g5s', n, P, q, red, False, direction='both', family=fam, source=src,
                           multiplier='behavioural', qBackend='behavioural', inverseScale='stage')
                rng = random.Random(n + P + 1)
                ok = s.twistMultiplier is None
                qq = _jobQ(s, rng)
                xs = [[rng.randrange(qq) for _ in range(n)] for _ in range(2)]
                Y = s.transform([_memFrame(x, n) for x in xs], 'fwd', qq)
                ok = ok and all(Y[f] == referenceNtt(xs[f], qq, negacyclic=False) for f in range(2))
                ok = ok and s.transform([_memFrame(y, n) for y in Y], 'inv', qq) == xs
            except Exception as e:                       # noqa: BLE001
                ok = False
                print(f'  {tag}: {type(e).__name__}: {e}')
            cases.append(None)
            fails += not ok
            if not ok:
                print(f'  FAIL {tag}')
    # the root recurrence ('rec', Kim et al.) for one q per job: fixed q (ROM) and run-time q (loaded tables)
    for red, q, fam in (('barrett', Q30, None), ('mont', Q52, None), ('barrett', 0, MF.odd(52)), ('wlm', 0, MF.friendly(17, 45))):
        for n, P, nwc in ((256, 4, True), (1024, 8, True), (512, 16, False)):
            if q and (q - 1) % (2 * n):
                continue
            tag = f"rec {red} {fam.describe() if fam else f'q{q.bit_length()}'} n={n} P={P} nwc={nwc}"
            cases.append(None)
            fails += _g5case(tag, lambda: stream('g5r', n, P, q, red, nwc, direction='both', family=fam, source='rec',
                                                 multiplier='behavioural', qBackend='behavioural'), n, nwc, perFrame=False)
    # per-polynomial moduli (moduli=): consecutive frames with different moduli of a mixed-width table
    mix = [nttFriendlyPrime(30, 12), nttFriendlyPrime(41, 14), nttFriendlyPrime(52, 16), nttFriendlyPrime(36, 13)]
    for red in ('barrett', 'mont'):
        for src, omb in (('otf', 0), ('otf', 3), ('rec', 0), ('rom', 0)):
            for n, P, nwc in ((64, 8, True), (256, 4, False), (1024, 16, True)):
                tag = f'per-frame {red} {src} otfMinBits={omb} n={n} P={P} nwc={nwc}'
                cases.append(None)
                fails += _g5case(tag, lambda: stream('g5p', n, P, mix, red, nwc, direction='both', source=src,
                                                     otfMinBits=omb, multiplier='behavioural',
                                                     qBackend='behavioural'), n, nwc, perFrame=True)
    # per-polynomial moduli over a run-time family (word-level Montgomery has no table form: family=friendly),
    # cyclic with the inverse's n^-1 as x2^-1 per stage ((q+1)/2 per frame), and the 'stream' supply; k = 1
    # (the modulus changes on every frame). Also Barrett over a table with the stage halver and 'stream'.
    fr16 = friendlyPrimes(16, 16, 1024, 3)
    fr32 = friendlyPrimes(32, 32, 1024, 2)
    odd62 = [q for q in (2305843009218281473, 2305843009220116481)] + [nttFriendlyPrime(62, 18)]
    for red, mods, fam in (('wlm', fr16, MF.friendly(16, 16)), ('wlm', fr32, MF.friendly(32, 32)),
                           ('barrett', odd62, None)):
        for src in ('otf', 'rec', 'rom', 'stream'):
            for n, P, ireg in ((64, 4, False), (256, 8, True), (1024, 2, False)):
                tag = f'per-frame {red} {len(mods)} moduli stage-scaled {src} n={n} P={P} ireg={ireg}'
                cases.append(None)
                fails += _g5case(tag, lambda: stream('g5f', n, P, mods, red, False, direction='both', family=fam,
                                                     source=src, inverseScale='stage', inputRegister=ireg,
                                                     multiplier='behavioural', qBackend='behavioural'),
                                 n, False, perFrame=True, frames=5)
    for red in ('barrett', 'mont'):              # negacyclic inverse with the output twist on the fly
        for src in ('otf', 'rec', 'rom', 'stream'):
            for n, P in ((64, 8), (256, 4), (1024, 16)):
                tag = f'per-frame {red} {src} twistSource=otf n={n} P={P} nwc=True'
                cases.append(None)
                fails += _g5case(tag, lambda: stream('g5t', n, P, mix, red, True, direction='both', source=src,
                                                     twistSource='otf', multiplier='behavioural',
                                                     qBackend='behavioural'), n, True, perFrame=True)
    for red in ('barrett', 'mont'):
        for n, P, nwc in ((64, 8, True), (256, 4, False)):
            tag = f'per-frame {red} stream n={n} P={P} nwc={nwc}'
            cases.append(None)
            fails += _g5case(tag, lambda: stream('g5q', n, P, mix, red, nwc, direction='both', source='stream',
                                                 multiplier='behavioural', qBackend='behavioural'), n, nwc, perFrame=True)
    # Kim et al.'s moduli: Table II as transcribed (prime, 1 mod 2^18), and the Barrett / Montgomery
    # butterflies over them at n = 2^10 (the table supports up to 2^17)
    probs = kim_moduli.check()
    cases.append(None)
    if probs or len(kim_moduli.KIM_Q) != 42:
        fails += 1
        print(f'  FAIL Kim moduli: {probs[:3]}')
    for red in ('barrett', 'mont'):
        tag = f'per-frame Kim q0..q41 {red} rec n=1024 P=8'
        cases.append(None)
        fails += _g5case(tag, lambda: stream('g5k', 1024, 8, kim_moduli.KIM_Q, red, True, direction='both',
                                             source='rec', multiplier='behavioural', qBackend='behavioural'),
                         1024, True, perFrame=True, frames=6)
    fails += gate5gs(quick, cases)
    print(f'gate 5 streaming model: {len(cases) - fails} of {len(cases)} pass (fixed q with ROM twiddles; run-time q '
          f'with loaded, on-the-fly and recurrence twiddles, two q each; per-frame moduli (otf, otf+tables, rec, rom), '
          f'frames with different moduli back to back; forward vs reference, inverse(forward(x)) == x on the same '
          f'pipeline; {time.time() - t0:.0f}s)')
    return fails


def gate5gs(quick: bool, cases: list) -> int:
    """Gentleman-Sande on the same cases (appends one entry per check to `cases`): GS 'both' with the inverse
    scaled per stage and at the input twist, forward vs the bit-reversed reference, inverse of the natural
    spectrum back to the bit-reversed input; and the pairings with no reorder between two pipelines:
    CT forward -> GS inverse and GS forward -> CT inverse (stream locations equal, values round trip)."""
    fails = 0
    base = [c for c in cases if c is not None]
    # the fold reduction (q = 2^28 - 2^16 + 1, AutoNTT's (a) prime) and Solinas, fixed q, both types
    q28 = 2 ** 28 - 2 ** 16 + 1
    base += [('fold', q28, 64, 4, True, None, None), ('fold', q28, 1024, 16, False, None, None),
             ('fold', q28, 256, 8, True, None, 'otf'), ('solinas', q28, 128, 8, True, None, None)]
    for i, (red, q, n, P, nwc, fam, src) in enumerate(base):
        for iscale in (('stage', 'output') if i % 2 == 0 else ('stage',)) + (('stage-exact',) if i % 3 == 0 else ()):
            if quick and (i + len(iscale)) % 3:
                continue
            dr = {}
            if iscale == 'stage-exact':          # A - B reduced exactly before the multiplier
                iscale, dr = 'stage', {'differenceRange': 1}
            tag = (f"GS {iscale}{' exact-diff' if dr else ''} {red} {fam.describe() if fam else f'q{q.bit_length()}'} {src or 'rom'} n={n} P={P} "
                   f"nwc={nwc}")
            try:
                s = stream('g5g', n, P, q, red, nwc, direction='both', family=fam, source=src, butterflyType='GS',
                           inverseScale=iscale, multiplier='behavioural', qBackend='behavioural', **dr)
                rng = random.Random(n + P + 2)
                ok = (s.twistMultiplier is None) == (iscale == 'stage' and not nwc)
                for _ in range(2 if fam else 1):
                    qq = _jobQ(s, rng)
                    xs = [[rng.randrange(qq) for _ in range(n)] for _ in range(2)]
                    Y = s.transform(xs, 'fwd', qq)
                    ref = [referenceNtt(x, qq, negacyclic=nwc) for x in xs]
                    ok = ok and Y == [_memFrame(y, n) for y in ref]
                    ok = ok and s.transform(ref, 'inv', qq) == [_memFrame(x, n) for x in xs]
                    if src == 'otf':
                        for key in s.slotClasses():
                            s.otfTables(key, qq)
            except Exception as e:                       # noqa: BLE001
                ok = False
                print(f'  {tag}: {type(e).__name__}: {e}')
            cases.append(None)
            fails += not ok
            if not ok:
                print(f'  FAIL {tag}')
    # the pairings: one forward pipeline and one inverse pipeline, the forward's output stream fed
    # straight into the inverse (no reorder); the inverse's output in the forward's input order
    pairs = [('barrett', Q30, None, None, 64, 4), ('mont', Q52, None, None, 256, 8), ('wlm', Q62, None, None, 1024, 16),
             ('wlm', 0, MF.friendly(32, 32), 'ram', 4096, 2), ('mont', 0, MF.odd(30), 'otf', 128, 4),
             ('shoup', Q52, None, None, 256, 2)]
    for red, q, fam, src, n, P in (pairs[::2] if quick else pairs):
        for nwc in (True, False):
            for fbt, ibt in (('CT', 'GS'), ('GS', 'CT')):
                tag = f"pair {fbt} fwd -> {ibt} inv {red} n={n} P={P} nwc={nwc}"
                try:
                    kw = dict(family=fam, source=src, multiplier='behavioural', qBackend='behavioural')
                    f = stream('g5f', n, P, q, red, nwc, direction='forward', butterflyType=fbt, **kw)
                    iv = stream('g5i', n, P, q, red, nwc, direction='inverse', butterflyType=ibt,
                                inverseScale='stage' if ibt == 'GS' or not nwc else 'output', **kw)
                    ok = all(f.outputLocation(m) == iv.inputLocation(m) and iv.outputLocation(m) == f.inputLocation(m)
                             for m in range(n))
                    ok = ok and (iv.twistMultiplier is None) == (ibt == 'GS' or not nwc)
                    rng = random.Random(n + 3)
                    qq = _jobQ(f, rng)
                    xs = [[rng.randrange(qq) for _ in range(n)] for _ in range(2)]
                    mem = [_memFrame(x, n) for x in xs] if fbt == 'CT' else xs
                    Y = f.transform(mem, 'fwd', qq)
                    ok = ok and iv.transform(Y, 'inv', qq) == mem
                except Exception as e:                       # noqa: BLE001
                    ok = False
                    print(f'  {tag}: {type(e).__name__}: {e}')
                cases.append(None)
                fails += not ok
                if not ok:
                    print(f'  FAIL {tag}')
    return fails


def _g5case(tag, make, n, nwc, perFrame, frames=4) -> int:
    '''One gate-5 case: forward vs the O(n^2) reference and inverse(forward) == x, per frame with its own q
    (per-frame moduli: the frames cycle through the table); 'rec' classes run the recurrence bit-exactly.'''
    try:
        s = make()
        rng = random.Random(n + 5)
        if perFrame:
            qs = [s.moduli[(3 * f + 1) % len(s.moduli)] for f in range(frames)]
        else:
            qs = [_jobQ(s, rng)] * 2
        xs = [[rng.randrange(q) for _ in range(n)] for q in qs]
        Y = s.transform([_memFrame(x, n) for x in xs], 'fwd', qs)
        ok = all(Y[f] == referenceNtt(xs[f], qs[f], negacyclic=nwc) for f in range(len(qs)))
        ok = ok and s.transform([_memFrame(y, n) for y in Y], 'inv', qs) == xs
        for key in s.slotClasses():
            if s.classSource(key) == 'rec':
                ok = ok and all(s.recCheck(key, q) for q in set(qs))
            elif s.classSource(key) == 'otf':
                for q in set(qs):
                    s.otfTables(key, q)
        if s.twiddleSource == 'stream':
            # the stream image (port tw_s<i> per cycle) equals the stored twiddle each slot of the class uses
            cls = s.streamClasses()
            for d in s.dirs:
                img = s.streamImage(qs, d)
                for f, q in enumerate(qs):
                    for i, key in enumerate(cls):
                        w, _ = s.slotTable(key, q)
                        sig = s.significantBits(key)
                        half = (1 << len(sig)) * s.dirs.index(d)
                        for tt in range(s.F):
                            a = sum(((tt >> b) & 1) << j for j, b in enumerate(sig))
                            ok = ok and img[f][tt][i] == w[half + a]
    except Exception as e:                       # noqa: BLE001
        ok = False
        print(f'  {tag}: {type(e).__name__}: {e}')
    if not ok:
        print(f'  FAIL {tag}')
    return 0 if ok else 1


STREAM_POINTS = [
    # name, n, P, q (or a run-time family), reduction, negacyclic, direction, butterfly args, frames
    #   (butterfly args may carry 'source': the twiddle source)
    ('sntt64_p8_barrett_q30', 64, 8, Q30, 'barrett', False, 'forward', {}, 6),
    ('sntt256_p4_mont_q52_nwc', 256, 4, Q52, 'mont', True, 'forward', {}, 3),
    ('sntt1024_p8_wlm_q62_ram', 1024, 8, Q62, 'wlm', False, 'forward', {}, 3),
    ('sntt256_p16_shoup_q52', 256, 16, Q52, 'shoup', True, 'forward', {}, 3),
    ('sntt64_p4_both_inv', 64, 4, Q30, 'barrett', True, 'both', {}, 4),
    ('sntt128_p8_inverse_dspc', 128, 8, Q52, 'mont', True, 'inverse', {'constBackend': 'dsp'}, 3),
    ('sntt32_p32_unrolled', 32, 32, Q30, 'barrett', True, 'forward', {}, 4),
    ('rtntt64_p8_barrett_odd52_ram', 64, 8, MF.odd(52), 'barrett', True, 'forward', {'source': 'ram'}, 4),
    ('rtntt256_p8_wlm_fr17x45_otf', 256, 8, MF.friendly(17, 45), 'wlm', True, 'forward', {'source': 'otf'}, 3),
    ('rtntt128_p4_mont_odd30_both_otf', 128, 4, MF.odd(30), 'mont', True, 'both', {'source': 'otf'}, 3),
    ('rtntt64_p4_shoup_odd52_both_ram', 64, 4, MF.odd(52), 'shoup', False, 'both', {'source': 'ram'}, 4),
    ('rtntt1024_p16_barrett_odd62_ram', 1024, 16, MF.odd(62), 'barrett', True, 'forward', {'source': 'ram'}, 2),
    ('fxntt256_p8_barrett_q62_otf', 256, 8, Q62, 'barrett', True, 'forward', {'source': 'otf'}, 3),
    ('rtntt64_p4_wlm_fr17x47_both_ram_ireg', 64, 4, MF.friendly(17, 47), 'wlm', True, 'both',
     {'source': 'ram', 'inputRegister': True}, 4),
    ('rtntt128_p8_mont_odd30_otf_ireg', 128, 8, MF.odd(30), 'mont', True, 'forward',
     {'source': 'otf', 'inputRegister': True}, 3),
    ('sntt256_p4_shoup_q52_ireg', 256, 4, Q52, 'shoup', True, 'forward', {'inputRegister': True}, 3),
    # cyclic, the inverse's n^-1 as x2^-1 after every butterfly (no output multipliers)
    ('cyntt64_p4_wlm_fr32x32_both_ram_stage', 64, 4, MF.friendly(32, 32), 'wlm', False, 'both',
     {'source': 'ram', 'inverseScale': 'stage'}, 4),
    ('cyntt128_p8_barrett_q30_both_stage', 128, 8, Q30, 'barrett', False, 'both', {'inverseScale': 'stage'}, 3),
    # Gentleman-Sande: natural in (where CT leaves its output), bit-reversed out; negacyclic forward with the
    # input twist psi^k, negacyclic inverse with psi^-1 merged; 'stage' = x2^-1 per stage (no multipliers)
    ('gsntt64_p8_barrett_q30', 64, 8, Q30, 'barrett', False, 'forward', {'butterflyType': 'GS'}, 6),
    ('gsntt256_p4_mont_q52_nwc', 256, 4, Q52, 'mont', True, 'forward', {'butterflyType': 'GS'}, 3),
    ('gsntt256_p16_shoup_q52_nwc', 256, 16, Q52, 'shoup', True, 'forward', {'butterflyType': 'GS'}, 3),
    ('gsintt256_p4_wlm_q62_nwc_stage', 256, 4, Q62, 'wlm', True, 'inverse',
     {'butterflyType': 'GS', 'inverseScale': 'stage'}, 3),
    ('gsintt128_p8_mont_q52_nwc_out', 128, 8, Q52, 'mont', True, 'inverse', {'butterflyType': 'GS'}, 3),
    ('gsntt64_p4_barrett_q30_both_nwc_stage', 64, 4, Q30, 'barrett', True, 'both',
     {'butterflyType': 'GS', 'inverseScale': 'stage'}, 4),
    ('gsntt64_p4_barrett_q30_both_nwc_stage_fwd', 64, 4, Q30, 'barrett', True, 'both',
     {'butterflyType': 'GS', 'inverseScale': 'stage', 'testDir': 'fwd'}, 4),
    ('gsfxntt256_p8_barrett_q62_otf', 256, 8, Q62, 'barrett', True, 'forward', {'butterflyType': 'GS', 'source': 'otf'}, 3),
    ('gsrtntt128_p4_mont_odd30_both_otf', 128, 4, MF.odd(30), 'mont', True, 'both',
     {'butterflyType': 'GS', 'source': 'otf', 'inverseScale': 'stage'}, 3),
    ('gsrtntt64_p4_shoup_odd52_both_ram', 64, 4, MF.odd(52), 'shoup', False, 'both',
     {'butterflyType': 'GS', 'source': 'ram'}, 4),
    ('gsrtntt64_p4_wlm_fr17x47_both_ram_ireg', 64, 4, MF.friendly(17, 47), 'wlm', True, 'both',
     {'butterflyType': 'GS', 'source': 'ram', 'inputRegister': True, 'inverseScale': 'stage'}, 4),
    ('gscyntt64_p4_wlm_fr32x32_both_ram_stage', 64, 4, MF.friendly(32, 32), 'wlm', False, 'both',
     {'butterflyType': 'GS', 'source': 'ram', 'inverseScale': 'stage'}, 4),
    ('gsrtntt64_p8_barrett_odd52_ram_fwd', 64, 8, MF.odd(52), 'barrett', True, 'forward',
     {'butterflyType': 'GS', 'source': 'ram'}, 4),
    ('gsintt128_p8_mont_q52_nwc_d60', 128, 8, Q52, 'mont', True, 'inverse',
     {'butterflyType': 'GS', 'inverseScale': 'stage', 'dspFraction': 0.6}, 3),
    ('gsrtintt1024_p16_barrett_odd62_ram_stage', 1024, 16, MF.odd(62), 'barrett', True, 'inverse',
     {'butterflyType': 'GS', 'source': 'ram', 'inverseScale': 'stage'}, 2),
    ('gsrtintt4096_p4_wlm_fr32x32_ram_stage', 4096, 4, MF.friendly(32, 32), 'wlm', True, 'inverse',
     {'butterflyType': 'GS', 'source': 'ram', 'inverseScale': 'stage'}, 2),
    ('gsrtntt64_p4_wlm_fr32x32_both_ram_d60_fwd', 64, 4, MF.friendly(32, 32), 'wlm', True, 'both',
     {'butterflyType': 'GS', 'source': 'ram', 'dspFraction': 0.6, 'testDir': 'fwd'}, 4),
    ('gsfold1024_p16_q28_both_nwc_fwd', 1024, 16, 2 ** 28 - 2 ** 16 + 1, 'fold', True, 'both',
     {'butterflyType': 'GS', 'inverseScale': 'stage', 'testDir': 'fwd'}, 2),
    ('gsrtintt128_p8_barrett_odd52_ram_exact', 128, 8, MF.odd(52), 'barrett', True, 'inverse',
     {'butterflyType': 'GS', 'source': 'ram', 'inverseScale': 'stage', 'differenceRange': 1}, 3),
    # the root recurrence ('rec'), one q per job
    ('fxntt256_p8_barrett_q52_rec', 256, 8, Q52, 'barrett', True, 'forward', {'source': 'rec', 'inputRegister': True}, 3),
    ('rtntt256_p4_barrett_odd52_both_rec', 256, 4, MF.odd(52), 'barrett', True, 'both', {'source': 'rec'}, 3),
    # per-polynomial moduli (a list: the modulus table; frames cycle through it, see PF_SEQ)
    ('pfntt64_p8_barrett_mix_both_otf3', 64, 8, 'MIX', 'barrett', True, 'both', {'source': 'otf', 'otfMinBits': 3}, 7),
    ('pfntt256_p4_barrett_mix_both_rec', 256, 4, 'MIX', 'barrett', True, 'both', {'source': 'rec', 'inputRegister': True}, 7),
    ('pfntt1024_p8_mont_mix_rec', 1024, 8, 'MIX', 'mont', True, 'forward', {'source': 'rec'}, 4),
    ('pfntt128_p8_barrett_mix_rom', 128, 8, 'MIX', 'barrett', True, 'forward', {'source': 'rom'}, 5),
    # experiment 2026-11-16 (needs NTT_GS_PERFRAME=1): a modulus per polynomial with Gentleman-Sande butterflies
    ('pfgs128_p8_barrett_mix_rom', 128, 8, 'MIX', 'barrett', False, 'forward', {'source': 'rom', 'butterflyType': 'GS'}, 5),
    ('pfgs128_p8_barrett_mix_otf_nwc', 128, 8, 'MIX', 'barrett', True, 'forward', {'source': 'otf', 'butterflyType': 'GS'}, 5),
    ('pfgs128_p8_barrett_mix_rom_nwc', 128, 8, 'MIX', 'barrett', True, 'forward', {'source': 'rom', 'butterflyType': 'GS'}, 5),
    ('pfgs128_p8_barrett_mix_otf', 128, 8, 'MIX', 'barrett', False, 'forward', {'source': 'otf', 'butterflyType': 'GS'}, 5),
    ('pfgs128_p8_barrett_mix_rec_nwc', 128, 8, 'MIX', 'barrett', True, 'forward', {'source': 'rec', 'butterflyType': 'GS'}, 5),
    ('pfgs128_p8_barrett_mix_otf8_nwc', 128, 8, 'MIX', 'barrett', True, 'forward', {'source': 'otf', 'otfMinBits': 8, 'butterflyType': 'GS'}, 5),
    ('pfgs64_p4_wlm_fr16_both_stage_rom', 64, 4, 'FR16', 'wlm', True, 'both',
     {'source': 'rom', 'butterflyType': 'GS', 'inverseScale': 'stage', 'family': MF.friendly(16, 16), 'tbdir': 'mix'}, 7),
    # Gentleman-Sande, inverse only, negacyclic, scaled per stage: psi^-1 and N^-1 are in the butterflies and the
    # halvers, so the core has no twist multiplier (2026-11-16, twist survey); a modulus per polynomial
    ('pfgsi64_p4_wlm_fr16_stage_rom', 64, 4, 'FR16', 'wlm', True, 'inverse',
     {'source': 'rom', 'butterflyType': 'GS', 'inverseScale': 'stage', 'family': MF.friendly(16, 16)}, 6),
    ('pfgsi128_p8_barrett_mix_stage_rom', 128, 8, 'MIX', 'barrett', True, 'inverse',
     {'source': 'rom', 'butterflyType': 'GS', 'inverseScale': 'stage'}, 5),
    ('pfgsi128_p8_barrett_mix_stage_otf', 128, 8, 'MIX', 'barrett', True, 'inverse',
     {'source': 'otf', 'butterflyType': 'GS', 'inverseScale': 'stage'}, 5),
    ('pfgsi256_p8_barrett_mix_stage_rec', 256, 8, 'MIX', 'barrett', True, 'inverse',
     {'source': 'rec', 'butterflyType': 'GS', 'inverseScale': 'stage'}, 5),
    ('lmgsi64_p4_wlm_fr16_stage_rom', 64, 4, 'FR16', 'wlm', True, 'inverse',
     {'source': 'rom', 'butterflyType': 'GS', 'inverseScale': 'stage', 'family': MF.friendly(16, 16), 'loadableModuli': True,
      'slots': 2, 'slotPattern': [0, 1, 0, 1, 'g0', 2, 0, 2, 0, 'g2', 1, 2, 1, 2]}, 0),
    ('mggsi128_p2_wlm_fr16_stage_rom', 128, 2, 'FR16', 'wlm', True, 'inverse',
     {'source': 'rom', 'butterflyType': 'GS', 'inverseScale': 'stage', 'family': MF.friendly(16, 16), 'loadableModuli': True,
      'loadLanes': 32, 'slotManager': True, 'mgPrimes': (16, 16, 256, 9),
      'mgKeys': [0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 2, 2, 3, 8, 7, 6, 5, 4, 4, 0, 1, 8]}, 0),
    ('pfntt256_p8_barrett_mix_otf', 256, 8, 'MIX', 'barrett', False, 'forward', {'source': 'otf'}, 5),
    ('pfntt1024_p8_barrett_kim_rec', 1024, 8, 'KIM', 'barrett', True, 'forward', {'source': 'rec', 'inputRegister': True}, 6),
    # k = 1 over a run-time family (WLM, friendly primes as AutoNTT's), cyclic, inverse scaled per stage, every
    # twiddle supply, frames of different moduli back to back; inverse ('both' designs) and forward test runs
    ('pfcy64_p4_wlm_fr16_stage_otf', 64, 4, 'FR16', 'wlm', False, 'both',
     {'source': 'otf', 'inverseScale': 'stage', 'family': MF.friendly(16, 16)}, 7),
    ('pfcy64_p4_wlm_fr16_stage_rec_fwd', 64, 4, 'FR16', 'wlm', False, 'both',
     {'source': 'rec', 'inverseScale': 'stage', 'family': MF.friendly(16, 16), 'tbdir': 'fwd'}, 7),
    ('pfcy64_p4_wlm_fr16_stage_rom', 64, 4, 'FR16', 'wlm', False, 'both',
     {'source': 'rom', 'inverseScale': 'stage', 'family': MF.friendly(16, 16)}, 7),
    ('pfcy64_p4_wlm_fr16_stage_stream', 64, 4, 'FR16', 'wlm', False, 'both',
     {'source': 'stream', 'inverseScale': 'stage', 'family': MF.friendly(16, 16)}, 7),
    ('pfcy128_p8_wlm_fr32_stage_stream_ireg_fwd', 128, 8, 'FR32', 'wlm', False, 'both',
     {'source': 'stream', 'inverseScale': 'stage', 'family': MF.friendly(32, 32), 'inputRegister': True,
      'tbdir': 'fwd'}, 5),
    ('pfcy256_p2_wlm_fr32_stage_rom_ireg', 256, 2, 'FR32', 'wlm', False, 'both',
     {'source': 'rom', 'inverseScale': 'stage', 'family': MF.friendly(32, 32), 'inputRegister': True}, 5),
    ('pfcy128_p8_barrett_odd62_stage_rec_ireg', 128, 8, 'ODD62', 'barrett', False, 'both',
     {'source': 'rec', 'inverseScale': 'stage', 'inputRegister': True}, 5),
    ('pfcy128_p8_barrett_odd62_stage_otf_ireg_fwd', 128, 8, 'ODD62', 'barrett', False, 'both',
     {'source': 'otf', 'inverseScale': 'stage', 'inputRegister': True, 'tbdir': 'fwd'}, 5),
    ('pfntt128_p4_barrett_mix_both_stream', 128, 4, 'MIX', 'barrett', True, 'both', {'source': 'stream'}, 5),
    # a direction per frame too (DIR sampled with MIDX on each frame's first cycle): NTT and INTT frames mixed
    ('pfcy64_p4_wlm_fr16_stage_stream_mixdir', 64, 4, 'FR16', 'wlm', False, 'both',
     {'source': 'stream', 'inverseScale': 'stage', 'family': MF.friendly(16, 16), 'tbdir': 'mix'}, 7),
    ('pfcy256_p2_wlm_fr32_stage_rom_ireg_mixdir', 256, 2, 'FR32', 'wlm', False, 'both',
     {'source': 'rom', 'inverseScale': 'stage', 'family': MF.friendly(32, 32), 'inputRegister': True, 'tbdir': 'mix'}, 6),
    ('pfcy128_p8_barrett_odd62_stage_rec_ireg_mixdir', 128, 8, 'ODD62', 'barrett', False, 'both',
     {'source': 'rec', 'inverseScale': 'stage', 'inputRegister': True, 'tbdir': 'mix'}, 6),
    ('pfcy64_p8_wlm_fr16_stage_otf_mixdir', 64, 8, 'FR16', 'wlm', False, 'both',
     {'source': 'otf', 'inverseScale': 'stage', 'family': MF.friendly(16, 16), 'tbdir': 'mix'}, 7),
    ('pfntt128_p4_barrett_mix_both_rom_mixdir', 128, 4, 'MIX', 'barrett', True, 'both', {'source': 'rom', 'tbdir': 'mix'}, 6),
    # negacyclic inverse with the output twist on the fly (twistSource='otf': two small tables and a generator per
    # lane instead of F words per lane per modulus), NTT and INTT frames mixed
    ('pfntt128_p4_barrett_mix_both_rom_twotf_mixdir', 128, 4, 'MIX', 'barrett', True, 'both',
     {'source': 'rom', 'twistSource': 'otf', 'tbdir': 'mix'}, 6),
    ('pfntt256_p8_barrett_kim_both_rec_twotf_ireg_mixdir', 256, 8, 'KIM', 'barrett', True, 'both',
     {'source': 'rec', 'twistSource': 'otf', 'inputRegister': True, 'tbdir': 'mix'}, 6),
    ('pfntt64_p4_mont_mix_both_otf_twotf_inv', 64, 4, 'MIX', 'mont', True, 'both',
     {'source': 'otf', 'twistSource': 'otf'}, 7),
    # --- the dataflow options of 2026-11-14 (each off by default) ---
    # unified=True: CT forward and GS inverse on one set of unified butterflies, both twists merged, x2^-1 per
    # stage (no twist multipliers on a negacyclic design); modulus and direction per polynomial
    ('ufntt64_p4_barrett_mix_rom_mixdir', 64, 4, 'MIX', 'barrett', True, 'both',
     {'source': 'rom', 'inverseScale': 'stage', 'unified': True, 'tbdir': 'mix'}, 7),
    ('ufntt256_p8_barrett_mix_otf_mixdir', 256, 8, 'MIX', 'barrett', True, 'both',
     {'source': 'otf', 'inverseScale': 'stage', 'unified': True, 'tbdir': 'mix'}, 6),
    ('ufntt128_p16_mont_mix_otf_ireg_mixdir', 128, 16, 'MIX', 'mont', True, 'both',
     {'source': 'otf', 'inverseScale': 'stage', 'unified': True, 'inputRegister': True, 'tbdir': 'mix'}, 6),
    ('ufcy128_p2_wlm_fr16_stream_mixdir', 128, 2, 'FR16', 'wlm', False, 'both',
     {'source': 'stream', 'inverseScale': 'stage', 'unified': True, 'family': MF.friendly(16, 16), 'tbdir': 'mix'}, 6),
    # run-time moduli with a change per polynomial (loadableModuli, 2026-11-15). The constants of a polynomial come
    # with it. Every table is a RAM with one block per slot, empty at the start: every modulus reaches the core
    # through the load port. slotPattern: the modulus of each frame (index into PF_MODULI[q]); 'gK' stands for as
    # many frames of modulus K as the slot timing asks before another slot may take a new modulus. 2 slots, 3
    # moduli: the third is loaded into a slot while frames of another run, and the load follows the data.
    ('lmcy128_p2_wlm_fr16_stream_mixdir', 128, 2, 'FR16', 'wlm', False, 'both',
     {'source': 'stream', 'inverseScale': 'stage', 'unified': True, 'family': MF.friendly(16, 16), 'tbdir': 'mix',
      'loadableModuli': True, 'slots': 1, 'slotPattern': [0, 1, 2, 0, 2, 1, 1, 0, 2, 2, 1, 0]}, 0),
    ('lmcy128_p8_barrett_odd62_stream_fwd', 128, 8, 'ODD62', 'barrett', False, 'forward',
     {'source': 'stream', 'loadableModuli': True, 'slots': 1, 'slotPattern': [0, 1, 2, 0, 2, 1, 1, 0, 2, 2, 1, 0]}, 0),
    ('lmcy64_p4_wlm_fr16_stage_rom', 64, 4, 'FR16', 'wlm', False, 'both',
     {'source': 'rom', 'inverseScale': 'stage', 'family': MF.friendly(16, 16), 'tbdir': 'mix', 'loadableModuli': True,
      'slots': 2, 'slotPattern': [0, 1, 0, 1, 'g0', 2, 0, 2, 0, 'g2', 1, 2, 1, 2]}, 0),
    # slots that rotate (slotManager): the testbench announces the modulus of every frame and answers the load
    # requests. 'mgKeys': the moduli of the frames as indices into a list of 'mgPrimes' friendly primes. The
    # design gets as many slots as any sequence needs, and the pattern brings a new modulus on almost every frame.
    ('mgcy128_p2_wlm_fr16_otf', 128, 2, 'FR16', 'wlm', False, 'both',
     {'source': 'otf', 'inverseScale': 'stage', 'unified': True, 'family': MF.friendly(16, 16), 'tbdir': 'mix',
      'loadableModuli': True, 'loadLanes': 8, 'slotManager': True, 'mgPrimes': (16, 16, 256, 9),
      'mgKeys': [0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 2, 2, 3, 8, 7, 6, 5, 4, 4, 0, 1, 8]}, 0),
    ('mgcy128_p2_wlm_fr16_otf_bydir', 128, 2, 'FR16', 'wlm', False, 'both',       # managed, a load per direction
     {'source': 'otf', 'inverseScale': 'stage', 'unified': True, 'family': MF.friendly(16, 16), 'tbdir': 'mix',
      'loadableModuli': True, 'loadLanes': 4, 'slotManager': True, 'loadByDirection': True, 'mgPrimes': (16, 16, 256, 9),
      'mgKeys': [0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 2, 2, 3, 8, 7, 6, 5, 4, 4, 0, 1, 8]}, 0),
    # negacyclic, the output twist generated too (twistSource 'otf'), slots that rotate, a load per direction
    ('mgntt128_p4_wlm_fr16_both_otf_twotf', 128, 4, 'FR16', 'wlm', True, 'both',
     {'source': 'otf', 'twistSource': 'otf', 'family': MF.friendly(16, 16), 'tbdir': 'mix', 'loadableModuli': True,
      'loadLanes': 8, 'slotManager': True, 'loadByDirection': True, 'mgPrimes': (16, 16, 256, 9),
      'mgKeys': [0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 2, 2, 3, 8, 7, 6, 5, 4, 4, 0, 1, 8]}, 0),
    # stored twiddles: the largest table is as long as a frame, so the loads run back to back with no idle cycle
    ('mgcy128_p2_wlm_fr16_rom_bydir', 128, 2, 'FR16', 'wlm', False, 'both',
     {'source': 'rom', 'inverseScale': 'stage', 'family': MF.friendly(16, 16), 'tbdir': 'mix', 'loadableModuli': True,
      'loadLanes': 32, 'slotManager': True, 'loadByDirection': True, 'mgPrimes': (16, 16, 256, 9),
      'mgKeys': [0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 2, 2, 3, 8, 7, 6, 5, 4, 4, 0, 1, 8, 3, 5, 7]}, 0),
    ('mgcy128_p2_wlm_fr16_rom', 128, 2, 'FR16', 'wlm', False, 'forward',
     {'source': 'rom', 'family': MF.friendly(16, 16), 'loadableModuli': True,
      'loadLanes': 32, 'slotManager': True, 'mgPrimes': (16, 16, 256, 9),
      'mgKeys': [0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 2, 2, 3, 8, 7, 6, 5, 4, 4, 0, 1, 8, 3, 5, 7]}, 0),
    ('lmcy64_p4_wlm_fr16_stage_rom_bydir', 64, 4, 'FR16', 'wlm', False, 'both',    # a load per direction, no manager
     # one direction in the test: with three slots and a key per (modulus, direction), a pattern that mixes
     # directions needs more slots than this unmanaged test has (the managed rows mix directions)
     {'source': 'rom', 'inverseScale': 'stage', 'family': MF.friendly(16, 16), 'loadableModuli': True,
      'loadByDirection': True, 'slots': 3, 'slotPattern': [0, 1, 0, 1, 'g0', 2, 0, 2, 0, 'g2', 1, 2, 1, 2]}, 0),
    ('lmcy64_p4_wlm_fr16_stage_rom_l4', 64, 4, 'FR16', 'wlm', False, 'both',       # 4 load words per cycle
     {'source': 'rom', 'inverseScale': 'stage', 'family': MF.friendly(16, 16), 'tbdir': 'mix', 'loadableModuli': True,
      'loadLanes': 4, 'slots': 2, 'slotPattern': [0, 1, 0, 1, 'g0', 2, 0, 2, 0, 'g2', 1, 2, 1, 2]}, 0),
    ('lmntt128_p4_wlm_fr16_both_otf_twist_l2', 128, 4, 'FR16', 'wlm', True, 'both',  # 2 load words per cycle
     {'source': 'otf', 'family': MF.friendly(16, 16), 'tbdir': 'mix', 'loadableModuli': True, 'loadLanes': 2,
      'slots': 2, 'slotPattern': [0, 1, 0, 1, 'g0', 2, 0, 2, 0, 'g2', 1, 2, 1, 2]}, 0),
    # Gentleman-Sande butterflies with loadable slots (2026-11-16)
    ('lmgs64_p4_wlm_fr16_stage_otf', 64, 4, 'FR16', 'wlm', False, 'both',
     {'source': 'otf', 'butterflyType': 'GS', 'inverseScale': 'stage', 'family': MF.friendly(16, 16), 'tbdir': 'mix',
      'loadableModuli': True, 'slots': 2, 'slotPattern': [0, 1, 0, 1, 'g0', 2, 0, 2, 0, 'g2', 1, 2, 1, 2]}, 0),
    ('mggs128_p2_wlm_fr16_rom', 128, 2, 'FR16', 'wlm', False, 'forward',
     {'source': 'rom', 'butterflyType': 'GS', 'family': MF.friendly(16, 16), 'loadableModuli': True,
      'loadLanes': 32, 'slotManager': True, 'mgPrimes': (16, 16, 256, 9),
      'mgKeys': [0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 2, 2, 3, 8, 7, 6, 5, 4, 4, 0, 1, 8]}, 0),
    ('lmcy64_p4_wlm_fr16_stage_otf', 64, 4, 'FR16', 'wlm', False, 'both',
     {'source': 'otf', 'inverseScale': 'stage', 'family': MF.friendly(16, 16), 'tbdir': 'mix', 'loadableModuli': True,
      'slots': 2, 'slotPattern': [0, 1, 0, 1, 'g0', 2, 0, 2, 0, 'g2', 1, 2, 1, 2]}, 0),
    ('lmcy128_p8_barrett_odd62_stage_rec_ireg', 128, 8, 'ODD62', 'barrett', False, 'both',
     {'source': 'rec', 'inverseScale': 'stage', 'inputRegister': True, 'tbdir': 'mix', 'loadableModuli': True,
      'slots': 2, 'slotPattern': [0, 1, 0, 1, 'g0', 2, 0, 2, 0, 'g2', 1, 2, 1, 2]}, 0),
    ('lmntt128_p4_wlm_fr16_both_otf_twist', 128, 4, 'FR16', 'wlm', True, 'both',
     {'source': 'otf', 'family': MF.friendly(16, 16), 'tbdir': 'mix', 'loadableModuli': True,
      'slots': 2, 'slotPattern': [0, 1, 0, 1, 'g0', 2, 0, 2, 0, 'g2', 1, 2, 1, 2]}, 0),
    ('lmuf128_p2_wlm_fr16_otf_mixdir', 128, 2, 'FR16', 'wlm', False, 'both',
     {'source': 'otf', 'inverseScale': 'stage', 'unified': True, 'family': MF.friendly(16, 16), 'tbdir': 'mix',
      'loadableModuli': True, 'slots': 3, 'slotPattern': [0, 1, 2, 0, 1, 2, 2, 1, 0]}, 0),
    ('ufntt64_p8_shoup_mix_rom_mixdir', 64, 8, 'MIX', 'shoup', True, 'both',
     {'source': 'rom', 'inverseScale': 'stage', 'unified': True, 'tbdir': 'mix'}, 6),
    # outputOrder='natural': a reorder stage (one RAM bank per lane, two frames deep) puts coefficient c*P + l
    # on lane l in cycle c; latency + F + 3, interval unchanged (frames back to back in the testbench)
    ('natntt64_p4_barrett_mix_rom_mixdir', 64, 4, 'MIX', 'barrett', True, 'both',
     {'source': 'rom', 'outputOrder': 'natural', 'tbdir': 'mix'}, 8),
    ('natntt256_p16_mont_mix_otf_uf_mixdir', 256, 16, 'MIX', 'mont', True, 'both',
     {'source': 'otf', 'inverseScale': 'stage', 'unified': True, 'outputOrder': 'natural', 'tbdir': 'mix'}, 8),
    ('natntt256_p64_barrett_mix_otf_mixdir', 256, 64, 'MIX', 'barrett', True, 'both',
     {'source': 'otf', 'outputOrder': 'natural', 'tbdir': 'mix'}, 8),
    ('natcy1024_p8_gs_barrett_q30', 1024, 8, Q30, 'barrett', False, 'forward',
     {'butterflyType': 'GS', 'outputOrder': 'natural'}, 6),
    ('natcy512_p2_wlm_q62', 512, 2, Q62, 'wlm', False, 'forward', {'outputOrder': 'natural'}, 6),
    # outReady=True (2026-11-14): in_valid/in_ready per polynomial, out_valid/out_ready per beat; the testbench
    # stalls the output until in_ready falls, then drives both sides at random (every cycle checked)
    ('rdyntt64_p4_barrett_mix_rom_mixdir', 64, 4, 'MIX', 'barrett', True, 'both',
     {'source': 'rom', 'outReady': True, 'outDepth': 2, 'tbdir': 'mix'}, 12),
    ('rdyntt256_p16_mont_mix_otf_uf_mixdir', 256, 16, 'MIX', 'mont', True, 'both',
     {'source': 'otf', 'inverseScale': 'stage', 'unified': True, 'outputOrder': 'natural', 'outReady': True,
      'tbdir': 'mix'}, 24),
    ('rdyntt256_p8_barrett_mix_stream_mixdir', 256, 8, 'MIX', 'barrett', True, 'both',
     {'source': 'stream', 'outReady': True, 'outDepth': 3, 'tbdir': 'mix'}, 10),
    ('rdyntt1024_p16_barrett_odd62_ram', 1024, 16, MF.odd(62), 'barrett', True, 'forward',
     {'source': 'ram', 'outReady': True}, 8),
    ('rdycy512_p2_wlm_q62', 512, 2, Q62, 'wlm', False, 'forward', {'outReady': True, 'outDepth': 1}, 5),
    # setBramBudget (2026-11-14): the deepest twiddle tables go to on-the-fly generation until the block RAMs fit
    ('bbntt1024_p4_barrett_mix_mixdir_b80', 1024, 4, 'MIX', 'barrett', True, 'both',
     {'source': 'rom', 'bramFraction': 0.8, 'tbdir': 'mix'}, 6),
    ('bbcy4096_p8_wlm_q62_b75', 4096, 8, Q62, 'wlm', False, 'forward', {'source': 'rom', 'bramFraction': 0.75}, 3),
]
#: the per-frame moduli of gate 6: a mixed-width table and Kim et al.'s q0..q41
PF_MODULI = {'MIX': [nttFriendlyPrime(30, 12), nttFriendlyPrime(41, 14), nttFriendlyPrime(52, 16), nttFriendlyPrime(36, 13)],
             'KIM': kim_moduli.KIM_Q,
             'FR16': friendlyPrimes(16, 16, 256, 3, 2148728833),            # AutoNTT (b)'s prime first
             'FR32': friendlyPrimes(32, 32, 256, 2, 9223372195768565761),   # AutoNTT (c)/(d)'s prime first
             'ODD62': [2305843009218281473, 2305843009220116481, nttFriendlyPrime(62, 18)]}


def _pfSeq(moduli, nf):
    '''Frame f's modulus: a pattern that changes the modulus on every frame and revisits some.'''
    return [moduli[(5 * f + (f // 3)) % len(moduli)] for f in range(nf)]


def gate6(root: str, only, sim: bool) -> int:
    fails = 0
    pts = [p for p in STREAM_POINTS if not only or p[0] in only]
    for name, n, P, q, red, nwc, d, bu, nf in pts:
        t0 = time.time()
        bu = dict(bu)
        src = bu.pop('source', None)
        tdir = bu.pop('testDir', None)
        tbdir = bu.pop('tbdir', None)
        mgk, mgp = bu.pop('mgKeys', None), bu.pop('mgPrimes', None)
        if mgk is not None:                             # slotManager: slots sized by the design, a reactive load
            run = os.path.join(root, name)
            plist = friendlyPrimes(*mgp)
            rng = random.Random(9)
            s0 = stream(name, n, P, plist[:2], red, nwc, direction=d, source=src, **bu)
            plan = quiet(lambda: StreamingNTT(s0).managedPlan(name, os.path.join(run, '_plan')))
            s = stream(name, n, P, plist[:plan['slots']], red, nwc, direction=d, source=src, **bu)
            qq = [plist[i] for i in mgk]
            frames = [[rng.randrange(x) for _ in range(n)] for x in qq]
            dirn = ['inv' if (f + f // 2) & 1 else 'fwd' for f in range(len(qq))] if d == 'both' else ('inv' if d == 'inverse' else 'fwd')
            op_ = StreamingNTT(s)
            m = quiet(lambda: op_.emitRtl(name, run, frames=frames, direction=dirn, q=qq))
            t_ = plan['timing']
            line = (f"  {name:<32} n={n:5d} P={P:3d} latency {m['latency']:4d} frame {s.F}: {plan['slots']} slots "
                    f"(load {t_['words']} cycles on {s.loadLanes} lanes, after {t_['after']}, before {t_['before']}, "
                    f"lead {plan['lead']}); {len(qq)} frames, {len(set(qq))} moduli\n     ")
            if sim:
                v = _sim(run)
                fails += not v.startswith('PASS')
                line += f'  xsim {v}'
            print(line + f'  ({time.time() - t0:.0f}s)')
            continue
        seq = bu.pop('slotPattern', None)               # loadableModuli: the modulus of each frame (index into
        K = bu.pop('slots', None)                       # PF_MODULI[q]) and the number of slots of the design
        run = os.path.join(root, name)
        if isinstance(q, str) and seq is not None:
            s = stream(name, n, P, PF_MODULI[q][:K], red, nwc, direction=d, source=src, **bu)
            rng = random.Random(9)
            op_ = StreamingNTT(s)
            tim = quiet(lambda: op_.slotTiming(name, run))
            g = -(-tim['together'] // s.F) + 1          # frames another slot must wait for a new modulus
            seq = [x for e in seq for x in ([int(e[1:])] * g if isinstance(e, str) else [e])]
            qq = [PF_MODULI[q][i] for i in seq]
            nf = len(qq)
            frames = [[rng.randrange(x) for _ in range(n)] for x in qq]
        elif isinstance(q, str):                        # per-frame moduli
            s = stream(name, n, P, PF_MODULI[q], red, nwc, direction=d, source=src, **bu)
            rng = random.Random(9)
            qq = _pfSeq(s.moduli, nf)
            frames = [[rng.randrange(x) for _ in range(n)] for x in qq]
        else:
            fam = q if not isinstance(q, int) else None
            s = stream(name, n, P, 0 if fam else q, red, nwc, direction=d, family=fam, source=src, **bu)
            rng = random.Random(9)
            qq = _jobQ(s, rng)
            frames = [[rng.randrange(qq) for _ in range(n)] for _ in range(nf)]
        dirn = tdir or tbdir or ('inv' if d in ('inverse', 'both') else 'fwd')
        if dirn == 'mix':                                # frame f: inverse when bit 0 of (f + f // 2) is set
            dirn = ['inv' if (f + f // 2) & 1 else 'fwd' for f in range(nf)]
        run = os.path.join(root, name)
        op_ = op_ if seq is not None else StreamingNTT(s)
        m = quiet(lambda: op_.emitRtl(name, run, frames=frames, direction=dirn, q=qq))
        lut, dsp = quiet(s.areaCost)
        line = (f"  {name:<32} n={n:5d} P={P:3d} latency {m['latency']:4d} exch words {s.exchangeWords():5d} "
                f"tables {m['tables']:3d} load {m['load_words']:5d}  LUT~{lut:7d} DSP {dsp:4d}")
        if seq is not None:
            t_ = op_.slotRun['timing']
            line += (f"\n      {nf} frames, {len(set(qq))} moduli on {len(s.moduli)} slot(s), {len(op_.slotRun['loads'])} loads of "
                     f"{t_['words']} words; next use of a slot {t_['together']} cycles after its last (all tables at once: "
                     f"{t_['allAtOnce']}); frame {s.F}\n     ")
        if sim:
            v = _sim(run)
            fails += not v.startswith('PASS')
            line += f'  xsim {v}'
        print(line + f'  ({time.time() - t0:.0f}s)')
    print(f"gate 6 streaming rtl: {len(pts) - fails} of {len(pts)} {'simulated and passing' if sim else 'generated'}")
    return fails



# --- gates 7 and 8: the iterative (memory-based) NTT --------------------------------------

def iterative(name, n, B, q=0, red='barrett', nwc=False, direction='forward', family=None, source=None, **bu):
    """An `IterativeNTTScheme` built like `stream()` builds the streaming one."""
    mk = 'shoup' if red == 'shoup' else 'reduction'
    cls = REDUCTIONS.get(red.split('-')[0], BarrettReduction)
    tgt = bu.pop('targetFmaxMhz', None)
    iscale = bu.pop('inverseScale', 'output')
    frac, total = bu.pop('dspFraction', None), bu.pop('dspTotal', None)
    extra = {k: bu.pop(k) for k in ('ioLanes', 'memStyle', 'twiddleStyle', 'ramLatency', 'shareInverseTwiddles',
                                    'twiddleBuffer', 'twiddleLanes', 'memOrg', 'crossRegs', 'dirPerPoly', 'recGroup',
                                    'fanout', 'recMultiplier', 'fanoutKeepSinks', 'fanoutLoads', 'recSeeds', 'qSwitch',
                                    'moduli')
             if k in bu}
    args = dict(multiplierKind=mk, reduction=cls, reductionArgs=(UNITS.get(red, ({},))[0] or {}), **bu)
    s = IterativeNTTScheme(name, n, B, q=q, family=family, negacyclic=nwc, direction=direction,
                           scaleInverse=direction != 'forward', butterfly=args, twiddleSource=source,
                           targetFmaxMhz=tgt, inverseScale=iscale, **extra)
    s.setInputBound(IntType(0, (family.qMax if family is not None else q or max(s.moduli)) - 1))
    if frac is not None or total is not None:
        s.setDspBudget(fraction=frac, total=total)
    return s


def _gate7cases(quick: bool) -> list:
    """(tag, builder kwargs, polys) over n, B, reductions, moduli, directions, scalings, I/O widths."""
    C = []
    fixed = (('barrett', Q30), ('mont', Q52), ('wlm', Q62), ('shoup', Q52), ('kred', KRED_Q),
             ('solinas', pseudoMersennePrime(61)))
    shapes = ((16, 1), (16, 4), (64, 2), (64, 16), (256, 8), (1024, 1), (1024, 32), (4096, 8), (4096, 256))
    for i, (red, q) in enumerate(fixed):
        for k, (n, B) in enumerate(shapes):
            if (k + i) % 2:
                continue
            for nwc in (False, True):
                if (q - 1) % (2 * n if nwc else n):
                    continue
                C.append((f'{red} q{q.bit_length()} n={n} B={B} nwc={nwc} both/output',
                          dict(n=n, B=B, q=q, red=red, nwc=nwc, direction='both'), 2))
    # run-time moduli, twiddles in RAM
    for red, fam in (('wlm', MF.friendly(17, 45)), ('barrett', MF.odd(52)), ('mont', MF.odd(30)),
                     ('shoup', MF.odd(52)), ('wlm-generic', MF.odd(62)), ('kred', MF.kred(23, 7)),
                     ('wlm', MF.friendly(32, 32)), ('wlm', MF.friendly(16, 16))):
        for n, B, nwc in ((64, 4, True), (256, 2, False), (1024, 16, True), (2048, 8, False)):
            C.append((f'{red} {fam.describe()} n={n} B={B} nwc={nwc} ram', dict(n=n, B=B, family=fam, red=red,
                                                                                  nwc=nwc, direction='both', source='ram'), 2))
    # the inverse scaled by x2^-1 per stage (cyclic), single directions, narrow I/O, a DSP budget
    for n, B, io in ((64, 4, 1), (256, 8, 4), (1024, 4, 2), (4096, 16, 32)):
        C.append((f'stage-scaled wlm fr32x32 n={n} B={B} io={io}',
                  dict(n=n, B=B, family=MF.friendly(32, 32), red='wlm', nwc=False, direction='both', source='ram',
                       inverseScale='stage', ioLanes=io), 2))
        C.append((f'stage-scaled barrett q30 n={n} B={B} io={io}',
                  dict(n=n, B=B, q=Q30, red='barrett', nwc=False, direction='both', inverseScale='stage', ioLanes=io), 2))
        C.append((f'unshared inverse twiddles shoup q52 n={n} B={B} io={io}',
                  dict(n=n, B=B, q=Q52, red='shoup', nwc=False, direction='both', inverseScale='stage', ioLanes=io,
                       shareInverseTwiddles=False), 2))
    for d in ('forward', 'inverse'):
        for nwc in (False, True):
            C.append((f'{d} only mont q52 n=512 B=8 nwc={nwc}', dict(n=512, B=8, q=Q52, red='mont', nwc=nwc, direction=d), 2))
    C.append(('large n=16384 B=16 wlm fr17x47 nwc both ram', dict(n=16384, B=16, family=MF.friendly(17, 47), red='wlm',
                                                                 nwc=True, direction='both', source='ram'), 1))
    C.append(('large n=32768 B=64 barrett q62 cyclic stage', dict(n=32768, B=64, q=Q62, red='barrett', nwc=False,
                                                                  direction='both', inverseScale='stage'), 1))
    return C[::3] if quick else C


def _nttRef(x, q, nwc):
    """The reference transform: O(n^2) up to n = 1024; above, the flat O(n log n) reference
    (`referenceNttFast`) and 8 coefficients by the definition, as a cross-check."""
    n = len(x)
    if n <= 1024:
        return referenceNtt(x, q, negacyclic=nwc)
    from operator_modeling.ntt.verification import referenceNttFast
    from sage.all import GF
    y = referenceNttFast(x, q, negacyclic=nwc)
    F = GF(q)
    from operator_modeling.ntt.roots import fixedRoot
    base = int(fixedRoot(F, 2 * n) if nwc else fixedRoot(F, n))
    rng = random.Random(n)
    for k in [0, n - 1] + [rng.randrange(n) for _ in range(6)]:
        e = (2 * k + 1) if nwc else k
        step, acc, pw = pow(base, e, q), 0, 1
        for v in x:
            acc = (acc + v * pw) % q
            pw = pw * step % q
        if acc != y[k]:
            raise AssertionError(f'referenceNttFast disagrees with the definition at k={k}')
    return y


def _gate7cgCases(quick: bool) -> list:
    """Constant geometry (memOrg 'constgeo'): n, B (up to 512 at small n), every board reduction, fixed and
    run-time q, cyclic / negacyclic, the three directions, both inverse scalings, I/O widths, ramLatency."""
    C = []
    shapes = ((16, 1), (16, 4), (32, 2), (64, 8), (128, 32), (256, 4), (512, 64), (1024, 256), (2048, 512),
              (1024, 8), (4096, 16), (8192, 64))
    fixed = (('barrett', Q30), ('mont', Q52), ('wlm', Q62), ('shoup', Q52))
    for k, (n, B) in enumerate(shapes):
        red, q = fixed[k % len(fixed)]
        d = ('both', 'forward', 'inverse')[k % 3]
        nwc = k % 2 == 1 and d != 'inverse' or (d == 'inverse' and k % 4 == 2)
        if (q - 1) % (2 * n if nwc else n):
            nwc = False
        iscale = 'stage' if (not nwc and d != 'forward' and k % 2 == 0) else 'output'
        extra = dict(memOrg='constgeo', inverseScale=iscale, ioLanes=max(1, 2 * B >> (k % 4)))
        if k % 5 == 3:
            extra['ramLatency'] = (1, 3)[k % 2]
        if k % 3 == 1:
            extra['crossRegs'] = 1 + k % 3
        C.append((f'cg {red} q{q.bit_length()} n={n} B={B} {d} nwc={nwc} {iscale} x{extra.get("crossRegs", 0)}',
                  dict(n=n, B=B, q=q, red=red, nwc=nwc, direction=d, **extra), 2))
    for k, (red, fam) in enumerate((('wlm', MF.friendly(17, 45)), ('barrett', MF.odd(52)), ('mont', MF.odd(30)),
                                    ('wlm', MF.friendly(32, 32)), ('barrett', MF.odd(64)), ('wlm-generic', MF.odd(62)))):
        n, B = ((64, 4), (256, 16), (1024, 256), (2048, 512), (512, 8), (128, 2))[k]
        nwc = k % 2 == 1
        C.append((f'cg {red} {fam.describe()} n={n} B={B} nwc={nwc} ram', dict(
            n=n, B=B, family=fam, red=red, nwc=nwc, direction='both', source='ram', memOrg='constgeo',
            inverseScale='output' if nwc else 'stage'), 2))
    return C[::3] if quick else C


def gate7cg(quick: bool) -> int:
    """Constant geometry's model, as gate 7 (geometry with the fixed wiring and the write muxes, hazards incl.
    write-after-read in the ping-pong, bit-exact forward / inverse, the twin's interval); the 'auto' choice
    (in place at every gate-7 point; constant geometry at the two failing comparison shapes); a 60 % DSP budget."""
    from operator_modeling.core import dspbudget as DB
    fails = gate7(quick, cases=_gate7cgCases(quick), label='gate 7 cg (constant geometry) model', budgets=False)
    t0 = time.time()
    # auto: in place wherever gate 7 runs; constant geometry at I2 / I3 (n 2^13 B 512, n 2^14 B 256)
    bad = []
    for tag, kw, _ in _gate7cases(True):
        kw = dict(kw)
        n = kw.pop('n'); B = kw.pop('B')
        s = quiet(lambda: iterative('g7a', n, B, kw.pop('q', 0), kw.pop('red'), kw.pop('nwc'), kw.pop('direction'),
                                    family=kw.pop('family', None), source=kw.pop('source', None),
                                    multiplier='behavioural', qBackend='behavioural', twiddleBuffer='single', **kw))
        if s.memOrg != 'inplace':
            bad.append(tag)
    for n, B, fam, w in ((8192, 512, MF.odd(36), 36), (16384, 256, MF.odd(54), 54)):
        s = quiet(lambda: iterative('g7a', n, B, 0, 'barrett', False, 'both', family=fam, source='ram',
                                    inverseScale='stage', ioLanes=64, twiddleBuffer='single', targetFmaxMhz=350.0))
        rep = s.memOrgReport()
        print(f'    auto n={n} B={B}: {rep["choice"]} ({rep["reason"]})')
        if s.memOrg != 'constgeo':
            bad.append(f'auto n={n} B={B}')
    if bad:
        print(f'  FAIL auto choice: {bad[:4]}')
    fails += bool(bad)
    # a 60 % DSP budget under constant geometry, real DSP multipliers, both board reductions
    for red, fam in (('wlm', MF.friendly(30, 30)), ('barrett', MF.odd(64))):
        tag = f'cg dsp budget 0.6 {red} n=1024 B=16'
        try:
            s = iterative('g7cb', 1024, 16, 0, red, False, 'both', family=fam, source='ram', inverseScale='stage',
                          dspFraction=0.6, twiddleBuffer='single', memOrg='constgeo')
            rng = random.Random(6)
            qq = _jobQ(s, rng)
            x = [rng.randrange(qq) for _ in range(1024)]
            y = referenceNtt(x, qq)
            ok = s.transform([_memFrame(x, 1024)], 'fwd', qq)[0] == y
            ok = ok and s.transform([_memFrame(y, 1024)], 'inv', qq)[0] == x
            ok = ok and not DB.check(s.dspTree) and s.dspTree.dsp <= s.dspTree.budget and not s.checkHazards()
        except Exception as e:                       # noqa: BLE001
            ok = False
            print(f'  {tag}: {type(e).__name__}: {e}')
        fails += not ok
        if not ok:
            print(f'  FAIL {tag}')
    print(f'gate 7 cg auto + budgets: {"pass" if not fails else f"{fails} FAILING"} ({time.time() - t0:.0f}s)')
    return fails


def gate7(quick: bool, cases=None, label: str = 'gate 7 iterative model', budgets: bool = True) -> int:
    """The iterative NTT's model: the bank map and schedule (2B distinct banks per cycle,
    every pair once, conflict-free I/O beats, every point read after its write-back),
    forward against the O(n^2) reference, inverse(forward(x)) == x on the same core, the
    controller twin's back-to-back interval, and DSP budgets within budget."""
    from operator_modeling.core import dspbudget as DB
    cases = cases if cases is not None else _gate7cases(quick)
    t0, fails = time.time(), 0
    for tag, kw, nf in cases:
        kw = dict(kw)
        try:
            n = kw.pop('n'); B = kw.pop('B')
            kw.setdefault('twiddleBuffer', 'single')         # today's core: one q per job (gate7rns: per polynomial)
            s = iterative('g7', n, B, kw.pop('q', 0), kw.pop('red'), kw.pop('nwc'), kw.pop('direction'),
                          family=kw.pop('family', None), source=kw.pop('source', None),
                          multiplier='behavioural', qBackend='behavioural', **kw)
            if kw.get('memOrg') == 'constgeo' and s.memOrg != 'constgeo':
                raise AssertionError('memOrg not applied')
            errs = (s.checkGeometry() if n <= 4096 or s.memOrg == 'constgeo' else []) + s.checkHazards()
            ok = not errs
            if errs:
                print(f'  {tag}: {errs[:2]}')
            rng = random.Random(n + B)
            for _ in range(2 if s.runtime else 1):
                qq = _jobQ(s, rng)
                xs = [[rng.randrange(qq) for _ in range(n)] for _ in range(nf)]
                if 'fwd' in s.dirs:
                    Y = s.transform([_memFrame(x, n) for x in xs], 'fwd', qq)
                    Yr = [_nttRef(x, qq, s.negacyclic) for x in xs]
                    ok = ok and all(Y[f] == Yr[f] for f in range(nf))
                if 'inv' in s.dirs:
                    if 'fwd' not in s.dirs:
                        Yr = [_nttRef(x, qq, s.negacyclic) for x in xs]
                    X = s.transform([_memFrame(y, n) for y in Yr], 'inv', qq)
                    ok = ok and X == xs
            job = s.simulateJob(3)
            C_ = s.computeCycles()
            ok = ok and job['interval'] is not None and max(C_, s.beats) <= job['interval'] <= max(C_, 2 * s.beats) + 8
        except Exception as e:                       # noqa: BLE001
            ok = False
            print(f'  {tag}: {type(e).__name__}: {e}')
        fails += not ok
        if not ok:
            print(f'  FAIL {tag}')
    # a DSP budget split over the butterflies (and the output twist), real DSP multipliers
    for frac in ((0.5, 0.8) if budgets else ()):
        tag = f'dsp budget {frac} wlm fr32x32 n=1024 B=8 nwc'
        try:
            s = iterative('g7b', 1024, 8, 0, 'wlm', True, 'both', family=MF.friendly(32, 32), source='ram',
                          dspFraction=frac, twiddleBuffer='single')
            ok = not DB.check(s.dspTree) and s.dspTree.dsp <= s.dspTree.budget
            rng = random.Random(4)
            qq = _jobQ(s, rng)
            x = [rng.randrange(qq) for _ in range(1024)]
            ok = ok and s.transform([_memFrame(x, 1024)], 'fwd', qq)[0] == referenceNtt(x, qq, negacyclic=True)
        except Exception as e:                       # noqa: BLE001
            ok = False
            print(f'  {tag}: {type(e).__name__}: {e}')
        cases.append(None)
        fails += not ok
        if not ok:
            print(f'  FAIL {tag}')
    print(f'{label}: {len(cases) - fails} of {len(cases)} pass (geometry and hazards, forward vs '
          f'reference, inverse of the reference == x, controller interval; {time.time() - t0:.0f}s)')
    return fails


def _gate7rnsCases(quick: bool) -> list:
    """(tag, builder kwargs, moduli count, record pattern) for the modulus per polynomial."""
    C = []
    fams = (('wlm', MF.friendly(30, 30)), ('barrett', MF.odd(64)), ('wlm', MF.friendly(26, 26)),
            ('barrett', MF.odd(52)), ('mont', MF.odd(30)), ('shoup', MF.odd(52)))
    shapes = ((16, 1), (64, 4), (256, 2), (256, 8), (1024, 4), (1024, 32), (4096, 8), (2048, 16))
    k = 0
    for tb in ('recycle', 'double'):
        for i, (red, fam) in enumerate(fams):
            for j, (n, B) in enumerate(shapes):
                if (i + j) % 3:
                    continue
                k += 1
                d = ('both', 'forward', 'inverse')[k % 3]
                nwc = d == 'forward' and k % 2 == 0          # negacyclic: forward only (the inverse needs the twist)
                iscale = 'stage' if d != 'forward' else 'output'   # an output twist would make the inverse q-bound
                extra = dict(inverseScale=iscale, ioLanes=max(1, 2 * B >> (k % 3)), twiddleBuffer=tb)
                if k % 4 == 1 and d == 'both':
                    extra['shareInverseTwiddles'] = False
                if k % 5 == 2:
                    extra['ramLatency'] = 3
                rec = ('alt', 'keep', 'alt3')[k % 3]
                C.append((f'{tb} {red} {fam.describe()} n={n} B={B} {d} nwc={nwc} {iscale} {rec}',
                          dict(n=n, B=B, family=fam, red=red, nwc=nwc, direction=d, source='ram', **extra),
                          3 if rec == 'alt3' else 2, rec))
    # the twiddle stream narrower than the default (compute waits for the loader), and B = 1, both variants
    for tb in ('recycle', 'double'):
        C.append((f'{tb} narrow stream wlm fr30x30 n=1024 B=8 TL=1', dict(n=1024, B=8, family=MF.friendly(30, 30),
                  red='wlm', nwc=False, direction='both', source='ram', inverseScale='stage', twiddleBuffer=tb,
                  twiddleLanes=1), 2, 'alt'))
        C.append((f'{tb} B=1 barrett odd52 n=128', dict(n=128, B=1, family=MF.odd(52), red='barrett', nwc=False,
                  direction='both', source='ram', inverseScale='stage', twiddleBuffer=tb), 3, 'alt3'))
    return C[::3] if quick else C


def _gate7cgRnsCases(quick: bool) -> list:
    """Constant geometry with a modulus per polynomial: recycle / double, the job's direction in the record."""
    C = []
    pts = ((16, 1), (64, 4), (256, 8), (1024, 256), (2048, 512), (1024, 16), (512, 2))
    fams = (('wlm', MF.friendly(30, 30)), ('barrett', MF.odd(64)), ('barrett', MF.odd(36)), ('mont', MF.odd(30)),
            ('wlm', MF.friendly(26, 26)), ('shoup', MF.odd(52)))
    k = 0
    for tb in ('recycle', 'double'):
        for j, (n, B) in enumerate(pts):
            k += 1
            red, fam = fams[k % len(fams)]
            d = ('both', 'forward', 'inverse')[k % 3]
            nwc = d == 'forward' and k % 2 == 0
            iscale = 'stage' if d != 'forward' else 'output'
            extra = dict(inverseScale=iscale, ioLanes=max(1, 2 * B >> (k % 3)), twiddleBuffer=tb, memOrg='constgeo')
            if k % 4 == 2:
                extra['ramLatency'] = 3
            if k % 3 == 2:
                extra['crossRegs'] = 2
            rec = ('alt', 'keep', 'alt3')[k % 3]
            C.append((f'cg {tb} {red} {fam.describe()} n={n} B={B} {d} nwc={nwc} {iscale} {rec}',
                      dict(n=n, B=B, family=fam, red=red, nwc=nwc, direction=d, source='ram', **extra),
                      3 if rec == 'alt3' else 2, rec))
    C.append(('cg recycle narrow stream wlm fr30x30 n=1024 B=8 TL=1', dict(n=1024, B=8, family=MF.friendly(30, 30),
              red='wlm', nwc=False, direction='both', source='ram', inverseScale='stage', twiddleBuffer='recycle',
              twiddleLanes=1, memOrg='constgeo'), 2, 'alt'))
    return C[::3] if quick else C


def _gate7rnsTwistCases(quick: bool) -> list:
    """RNS with the output twist (negacyclic inverse, inverseScale 'output'), in place: recycle / double, alternating
    and kept moduli, both directions and inverse only, I/O widths (the twist region TT = min(TL, io) a beat)."""
    C = []
    pts = ((16, 1, 2), (64, 4, 8), (256, 8, 4), (512, 2, 1), (1024, 16, 32), (2048, 8, 16))
    fams = (('barrett', MF.odd(52)), ('wlm', MF.friendly(30, 30)), ('mont', MF.odd(30)), ('barrett', MF.odd(64)),
            ('wlm', MF.friendly(17, 45)), ('shoup', MF.odd(52)))
    k = 0
    for tb in ('recycle', 'double'):
        for j, (n, B, io) in enumerate(pts):
            k += 1
            red, fam = fams[(k + j) % len(fams)]
            d = ('both', 'inverse')[k % 2]
            rec = ('alt', 'keep', 'alt3')[k % 3]
            extra = dict(inverseScale='output', ioLanes=io, twiddleBuffer=tb)
            if k % 4 == 3:
                extra['ramLatency'] = 3
            C.append((f'twist {tb} {red} {fam.describe()} n={n} B={B} io={io} {d} nwc {rec}',
                      dict(n=n, B=B, family=fam, red=red, nwc=True, direction=d, source='ram', **extra),
                      3 if rec == 'alt3' else 2, rec))
    return C[::3] if quick else C


def gate7twistRns(quick: bool) -> int:
    return gate7rns(quick, cases=_gate7rnsTwistCases(quick), label='gate 7 twist rns (negacyclic inverse, output '
                    'twist, modulus per polynomial)', budgets=False)


def gate7dirRns(quick: bool) -> int:
    """A direction per polynomial (dirPerPoly, RNS, direction 'both'): mixed forward / inverse polynomials under
    alternating and kept moduli, cyclic (shared inverse twiddles, stage scaling) and negacyclic (output twist),
    recycle / double; every polynomial bit-exact (forward vs the reference, inverse of the reference == x), the
    twin's windows and sets, and a direction switch costing the bubble (a kept modulus and direction: none)."""
    cases = [(n, B, io, tb, red, fam, nwc, None) for (n, B, io) in ((64, 4, 8), (256, 8, 4), (1024, 16, 32), (128, 1, 2))
             for tb in ('recycle', 'double') for (red, fam, nwc) in (('wlm', MF.friendly(30, 30), False),
                                                                     ('barrett', MF.odd(52), True))]
    # constant geometry (cyclic, stage scaling): the direction selects only the halvers
    cases += [(n, B, io, tb, red, fam, False, 'constgeo') for (n, B, io) in ((64, 4, 8), (256, 8, 4), (1024, 16, 32),
                                                                             (128, 1, 2), (1024, 256, 64))
              for tb in ('recycle', 'double') for (red, fam) in (('wlm', MF.friendly(30, 30)), ('barrett', MF.odd(52)))]
    cases = cases[::3] if quick else cases
    t0, fails = time.time(), 0
    for n, B, io, tb, red, fam, nwc, org in cases:
        tag = f"dir per poly {org or 'in place'} {tb} {red} n={n} B={B} io={io} nwc={nwc}"
        try:
            s = iterative('g7d', n, B, 0, red, nwc, 'both', family=fam, source='ram', multiplier='behavioural',
                          qBackend='behavioural', twiddleBuffer=tb, inverseScale='output' if nwc else 'stage',
                          ioLanes=io, dirPerPoly=True, **({'memOrg': org} if org else {}))
            rng = random.Random(n + B + io)
            qa, qb = _jobQ(s, rng), _jobQ(s, rng)
            while qb == qa:
                qb = _jobQ(s, rng)
            pq = [qa, qa, qb, qb, qa, qa]
            ds = ['fwd', 'inv', 'inv', 'fwd', 'fwd', 'inv']
            keeps = [k > 0 and pq[k] == pq[k - 1] and ds[k] == ds[k - 1] for k in range(6)]
            xs = [[rng.randrange(q) for _ in range(n)] for q in pq]
            ins = [x if d == 'fwd' else _nttRef(x, q, nwc) for x, q, d in zip(xs, pq, ds)]
            outs = s.transform([_memFrame(v, n) for v in ins], ds, pq)
            errs = [] if all((outs[k] == _nttRef(xs[k], pq[k], nwc)) if ds[k] == 'fwd' else (outs[k] == xs[k])
                             for k in range(6)) else ['values']
            errs += s.checkHazards()
            pv = [rng.random() < 0.7 for _ in range(4099)]
            tv = [rng.random() < 0.6 for _ in range(4091)]
            for va, twv in ((None, None), (lambda c: pv[c % 4099], lambda c: tv[c % 4091])):
                job = s.simulateJob(6, va, records=keeps, twValid=twv)
                errs += s.checkTwiddleWindows(job) + s.checkSets(job)
            op = IterativeNTT(s)
            for d in ('fwd', 'inv'):
                hb = op.rnsRecord(qa, keep=True, direction=d)
                hv = sum(v << (k * s.twiddleLanes() * s.twEntryWidth()) for k, v in enumerate(hb))
                if (hv >> 1) & 1 != (1 if d == 'inv' else 0):
                    errs.append('header DIR bit')
            ok = not errs
            if errs:
                print(f'  {tag}: {errs[:3]}')
        except Exception as e:                       # noqa: BLE001
            ok = False
            import traceback
            traceback.print_exc()
            print(f'  {tag}: {type(e).__name__}: {e}')
        fails += not ok
        if not ok:
            print(f'  FAIL {tag}')
    print(f'gate 7 dir rns (a direction per polynomial): {len(cases) - fails} of {len(cases)} pass '
          f'({time.time() - t0:.0f}s)')
    return fails


def gate7cgRns(quick: bool) -> int:
    fails = gate7rns(quick, cases=_gate7cgRnsCases(quick), label='gate 7 cg rns (constant geometry, modulus per '
                     'polynomial)', budgets=False)
    for tb, red, fam in (('recycle', 'wlm', MF.friendly(30, 30)), ('double', 'barrett', MF.odd(64))):
        tag = f'cg dsp budget 0.6 {tb} {red} n=1024 B=8'
        try:
            s = iterative('g7cr', 1024, 8, 0, red, False, 'both', family=fam, source='ram', inverseScale='stage',
                          dspFraction=0.6, twiddleBuffer=tb, memOrg='constgeo')
            rng = random.Random(5)
            qa, qb = _jobQ(s, rng), _jobQ(s, rng)
            xs = [[rng.randrange(q_) for _ in range(1024)] for q_ in (qa, qb, qa)]
            Y = s.transform([_memFrame(x, 1024) for x in xs], 'fwd', [qa, qb, qa])
            ok = all(Y[f] == referenceNtt(xs[f], q_) for f, q_ in enumerate((qa, qb, qa)))
            ok = ok and s.transform([_memFrame(y, 1024) for y in Y], 'inv', [qa, qb, qa]) == xs
            ok = ok and s.dspTree.dsp <= s.dspTree.budget and not s.checkHazards()
        except Exception as e:                       # noqa: BLE001
            ok = False
            print(f'  {tag}: {type(e).__name__}: {e}')
        fails += not ok
        if not ok:
            print(f'  FAIL {tag}')
    # negative test: the reservation at the compute start (the first version) must fail checkSets when a late
    # record stream holds the starts back (n 2048, B 512, L odd, 'double')
    s = quiet(lambda: iterative('g7cn', 2048, 512, 0, 'barrett', False, 'both', family=MF.odd(36), source='ram',
                                inverseScale='stage', twiddleBuffer='double', ioLanes=64, memOrg='constgeo',
                                multiplier='behavioural', qBackend='behavioural'))
    s._cgReserveAtStart = True
    bad = s.checkSets(s.simulateJob(3, records=[False] * 3))
    s._cgReserveAtStart = False
    good = s.checkSets(s.simulateJob(3, records=[False] * 3))
    if not bad or good:
        print(f'  FAIL negative set test: old rule {bad[:1]}, fixed rule {good[:1]}')
        fails += 1
    else:
        print(f'    negative set test: the first rule fails as it should ({bad[0]})')
    print(f'gate 7 cg rns budgets + negative set test: {"pass" if not fails else f"{fails} FAILING"}')
    return fails


def _gate7cgRecCases(quick: bool) -> list:
    """twiddleSource 'rec' (constant geometry, recycle): (tag, builder kwargs, moduli count, record pattern)."""
    C = []
    pts = ((64, 4), (256, 8), (1024, 32), (2048, 512), (512, 2), (1024, 16), (4096, 64), (8192, 512), (16384, 256))
    fams = (('barrett', MF.odd(36)), ('barrett', MF.odd(54)), ('wlm', MF.friendly(30, 30)), ('mont', MF.odd(30)),
            ('barrett', MF.odd(64)), ('wlm', MF.friendly(26, 26)))
    for k, (n, B) in enumerate(pts):
        red, fam = fams[k % len(fams)]
        d = ('both', 'forward', 'inverse')[k % 3]
        nwc = d == 'forward' and k % 2 == 0
        iscale = 'stage' if d != 'forward' else 'output'
        extra = dict(inverseScale=iscale, ioLanes=min(64, max(1, 2 * B >> (k % 3))), twiddleBuffer='recycle',
                     memOrg='constgeo', twiddleSource='rec')
        if k % 4 == 2:
            extra['ramLatency'] = 3
        if k % 3 == 2:
            extra['crossRegs'] = 2
        if k % 5 == 3:
            extra['recGroup'] = 1
        if k % 3 == 1:
            extra['fanout'] = (4, 8, 32)[k % 3 + (k // 3) % 2]
        if k % 4 == 3:
            extra['dspFraction'] = (0.6, 0.8)[k % 2]
        if k % 5 == 1:
            extra['recMultiplier'] = {'multiplier': 'booth', 'qBackend': 'booth'}
        rec = ('alt', 'keep', 'alt3')[k % 3]
        C.append((f'cg rec {red} {fam.describe()} n={n} B={B} {d} nwc={nwc} {iscale} {rec}'
                  + (f" G={extra['recGroup']}" if 'recGroup' in extra else '')
                  + (f" F={extra['fanout']}" if 'fanout' in extra else '')
                  + (f" dsp={extra['dspFraction']}" if 'dspFraction' in extra else '')
                  + (' lutgen' if 'recMultiplier' in extra else ''),
                  dict(n=n, B=B, family=fam, red=red, nwc=nwc, direction=d, **extra), 3 if rec == 'alt3' else 2, rec))
    return C[::2] if quick else C


def _decodeRecRecord(s, beats) -> tuple:
    """An independent reading of a 'rec' record: (header value, {(lane, stage, entry): word})."""
    TL, E = 2, s.twEntryWidth()
    HB = s.headerBeats()
    hv = sum(v << (k * TL * E) for k, v in enumerate(beats[:HB]))
    out, k = {}, HB
    for st in range(min(s.L, s.H + 2)):
        for e in range(s.cgDepths[st]):
            for lane in (0, 1):
                out[(lane, st, e)] = (beats[k] >> (lane * E)) & ((1 << E) - 1)
            k += 1
    assert k == len(beats)
    return hv, out


def gate7cgRec(quick: bool) -> int:
    """twiddleSource 'rec': geometry, hazards and the twiddle windows on twin jobs (new q every polynomial,
    kept runs, record-stream stalls, a late stream), every butterfly's on-chip table bit-exact through the
    generator datapath == the streamed table (`recTables`, every direction, three primes), the transform
    against the reference with a modulus per polynomial, the record read back independently (header: keep,
    modulus constants, factors F = ratio / rf; lanes: butterfly 0 and B/2), the intervals (new q: compute +
    bubble, as 'ram'; kept: compute), the unsafe twin caught, and a wrong factor caught."""
    t0, fails = time.time(), 0
    cases = _gate7cgRecCases(quick)
    for tag, kw, nq, pat in cases:
        kw = dict(kw)
        try:
            n = kw.pop('n'); B = kw.pop('B')
            src = kw.pop('twiddleSource')
            s = quiet(lambda: iterative('g7cg_rec', n, B, 0, kw.pop('red'), kw.pop('nwc'), kw.pop('direction'),
                                        family=kw.pop('family'), source=src, targetFmaxMhz=350.0, **kw))
            if s.dspTree is not None and s.dspTree.dsp > s.dspTree.budget:
                errs_b = [f'DSP {s.dspTree.dsp} over the budget {s.dspTree.budget}']
            else:
                errs_b = []
            errs = (s.checkGeometry() if n <= 32768 else []) + s.checkHazards() + errs_b
            rng = random.Random(n * 5 + B)
            qs = []
            while len(qs) < max(3, nq):
                qq = _jobQ(s, rng)
                if qq not in qs:
                    qs.append(qq)
            for qq in qs:
                for dd in s.dirs:
                    s.recTables(qq, dd)                  # raises on a difference
            P = 6 if pat == 'keep' else 2 * nq
            idx, keeps = _records(pat, nq, P, rng)
            pq = [qs[i] for i in idx]
            if n <= 4096:
                xs = [[rng.randrange(qq) for _ in range(n)] for qq in pq]
                if 'fwd' in s.dirs:
                    Y = s.transform([_memFrame(x, n) for x in xs], 'fwd', pq)
                    if any(Y[f] != _nttRef(xs[f], pq[f], s.negacyclic) for f in range(P)):
                        errs.append('forward differs from the reference')
                if 'inv' in s.dirs:
                    Yr = [_nttRef(x, qq, s.negacyclic) for x, qq in zip(xs, pq)]
                    if s.transform([_memFrame(y, n) for y in Yr], 'inv', pq) != xs:
                        errs.append('inverse(reference) != x')
            pv = [rng.random() < 0.7 for _ in range(4099)]
            tv = [rng.random() < 0.6 for _ in range(4091)]
            for va, twv in ((None, None), (lambda c: pv[c % 4099], lambda c: tv[c % 4091]),
                            (None, lambda c: c > 300 and c % 7 == 0)):
                job = s.simulateJob(P, va, records=keeps, twValid=twv)
                errs += s.checkTwiddleWindows(job) + s.checkSets(job)
            C_, bub = s.computeCycles(), s.rnsBubble()
            ia = s.simulateJob(4)['interval']
            ik = s.simulateJob(4, records=[False, True, True, True])['interval']
            if not (max(C_, s.beats) <= ik <= max(C_, 2 * s.beats) + 8):
                errs.append(f'kept-modulus interval {ik}, compute {C_}')
            if not C_ + bub <= ia <= max(C_ + bub, 2 * s.beats + 8):
                errs.append(f'new-q interval {ia}, compute {C_} + bubble {bub}')
            op = IterativeNTT(s)
            E = s.twEntryWidth()
            for qq in qs[:2]:
                for dd in s.dirs:
                    beats = op.rnsRecord(qq, direction=dd)
                    if len(beats) != s.recordBeats():
                        errs.append('record length')
                    hv, ent = _decodeRecRecord(s, beats)
                    if hv & 1 or any(((hv >> o) & ((1 << w_) - 1)) != (s.qPortValues(qq)[p_] & ((1 << w_) - 1))
                                     for p_, o, w_ in s.headerLayout()):
                        errs.append('record header: modulus constants')
                    tabs = [s.twiddleTable(k, qq, 't', dd)[0] for k in range(B)]
                    rf = s.genMultiplier.reductionFactor(qq)
                    for j, beta, o, w_ in s.recFactorLayout():
                        F = (hv >> o) & ((1 << w_) - 1)
                        kk = beta << (s.b - j)
                        cur, prv = s.cgBases[s.H + j], s.cgBases[s.H + j - 1]
                        if tabs[kk][prv] * F * rf % qq != tabs[kk][cur]:
                            errs.append(f'record header: factor F{j}_{beta}')
                    for (lane, st, e), v in ent.items():
                        if v != tabs[lane * (B // 2)][s.cgBases[st] + e]:
                            errs.append(f'record entry lane {lane} stage {st} entry {e}')
                            break
                kb = op.rnsRecord(qq, keep=True)
                if len(kb) != s.headerBeats() or not kb[0] & 1:
                    errs.append('kept record')
            if not s.checkTwiddleWindows(s._simulateJobRns(4, unsafe=True)):
                errs.append('negative test: the unsafe twin passed the window check')
            if s.L > s.H + 2:                            # negative: a wrong factor must break the table check
                key = ('rf', qs[0], s.dirs[0])
                saved = dict(s._qCache[key])
                k0 = next(iter(saved))
                s._qCache[key][k0] = (saved[k0] + 1) % qs[0]
                try:
                    s.recTables(qs[0], s.dirs[0])
                    errs.append('negative test: a wrong factor passed recTables')
                except AssertionError:
                    pass
                s._qCache[key] = saved
            r_ = s.resources()
            tg = r_['breakdown']['twiddle generators']
            print(f'    {tag}: G {s.recGroup()} ({B // s.recGroup()} generators, PG {tg["genLatency"]}) units '
                  f'{len(s.recUnits())} record {s.recordBeats()} beats ({s.headerBeats()} header) compute {C_} new-q '
                  f'{ia} (bubble {bub}) kept {ik} gen LUT {tg["lut"]} DSP {tg["dsp"]}', flush=True)
            if errs:
                print(f'  {tag}: {errs[:3]}')
            ok = not errs
        except Exception as e:                       # noqa: BLE001
            ok = False
            import traceback
            traceback.print_exc()
            print(f'  {tag}: {type(e).__name__}: {e}')
        fails += not ok
        if not ok:
            print(f'  FAIL {tag}')
    # refused combinations
    # (in place, recycle is built since 2026-11-12: gate 7 ip rec; refused there with two stored directions)
    for bad in (dict(twiddleBuffer='double', memOrg='constgeo'), dict(twiddleBuffer='double', memOrg='inplace'),
                dict(twiddleBuffer='recycle', memOrg='inplace', nwcBoth=True),
                dict(twiddleBuffer='recycle', memOrg='auto')):
        try:
            bad = dict(bad)
            nb = bad.pop('nwcBoth', False)
            iterative('g7cg_bad', 256, 8, 0, 'barrett', nb, 'both', family=MF.odd(36), source='rec',
                      inverseScale='output' if nb else 'stage', **bad)
            print(f'  FAIL refused combination accepted: {bad}')
            fails += 1
        except ValueError:
            pass
    print(f"gate 7 cg rec (twiddles on chip): {len(cases) - fails} of {len(cases)} pass ({time.time() - t0:.0f}s)")
    return fails


def _gate7ipRecCases(quick: bool) -> list:
    """twiddleSource 'rec' in place (recycle): (tag, builder kwargs, moduli count, record pattern, full), `full`:
    the stages are long enough (T >= 256) for a new modulus every polynomial at compute + bubble."""
    W60, W52 = MF.friendly(30, 30), MF.friendly(26, 26)
    pts = [
        # the I1 row (AutoNTT-I's size, 60-bit run-time family), cyclic with the shared inverse, and negacyclic
        (4096, 8, 'wlm', W60, False, 'both', 'alt', True, {}),
        (4096, 8, 'wlm', W60, True, 'forward', 'keep', True, {}),
        # larger B
        (65536, 64, 'wlm', W60, False, 'both', 'alt', True, {}),
        (16384, 32, 'barrett', MF.odd(54), True, 'forward', 'alt3', True, dict(ramLatency=3)),
        (8192, 16, 'mont', MF.odd(30), False, 'inverse', 'keep', True, dict(ioLanes=8)),
        (4096, 8, 'barrett', MF.odd(64), False, 'forward', 'alt3', False, dict(recGroup=8)),   # one generator: slower
        (4096, 4, 'wlm', W52, True, 'forward', 'alt', True, dict(recMultiplier={'multiplier': 'booth',
                                                                                 'qBackend': 'booth'})),
        (2048, 2, 'barrett', MF.odd(36), False, 'both', 'alt', True, dict(dspFraction=0.6)),
        # short stages: correct, but the generators set the period (the interval is checked against the units)
        (256, 4, 'wlm', W60, False, 'both', 'alt', False, {}),
        (1024, 8, 'barrett', MF.odd(36), False, 'both', 'keep', False, {}),
        (256, 8, 'mont', MF.odd(30), True, 'forward', 'alt3', False, {}),
        (1024, 32, 'barrett', MF.odd(36), True, 'forward', 'alt', False, dict(recGroup=4)),
        (16, 4, 'barrett', MF.odd(36), False, 'forward', 'alt', False, {}),
        (64, 2, 'barrett', MF.odd(52), False, 'inverse', 'keep', False, dict(recGroup=1)),
        (128, 8, 'wlm', W52, False, 'both', 'alt3', False, dict(recGroup=8)),
    ]
    C = []
    for n, B, red, fam, nwc, d, rec, full, extra in pts:
        iscale = 'stage' if d != 'forward' and not nwc else 'output'
        kw = dict(n=n, B=B, family=fam, red=red, nwc=nwc, direction=d, inverseScale=iscale, twiddleBuffer='recycle',
                  memOrg='inplace', twiddleSource='rec', **extra)
        C.append((f'ip rec {red} {fam.describe()} n={n} B={B} {d} nwc={nwc} {rec}'
                  + (f" G={extra['recGroup']}" if 'recGroup' in extra else '')
                  + (' lutgen' if 'recMultiplier' in extra else ''), kw, 3 if rec == 'alt3' else 2, rec, full))
    return [c for i, c in enumerate(C) if i in (0, 1, 3, 8, 10, 12)] if quick else C


def gate7ipRec(quick: bool) -> int:
    """twiddleSource 'rec' in place: geometry, hazards and the twiddle windows on twin jobs (new q every
    polynomial, kept runs, input stalls), every butterfly's 't' and 'c' table bit-exact through the generator
    datapath == `twiddleTable` (`recTables`, default group and G = 1, B; three primes), the transform against
    the reference with a modulus per polynomial, the record (its header alone) read back independently (keep,
    modulus constants, the stage seeds and the factor of every index bit against the tables), the intervals
    (long stages: new q every polynomial == compute + bubble exactly, as 'ram'; short stages: bounded by the
    generator units; kept: compute), the unsafe twin caught, and a wrong factor caught."""
    t0, fails = time.time(), 0
    cases = _gate7ipRecCases(quick)
    for tag, kw, nq, pat, full in cases:
        kw = dict(kw)
        try:
            n = kw.pop('n'); B = kw.pop('B')
            src = kw.pop('twiddleSource')
            s = quiet(lambda: iterative('g7ip_rec', n, B, 0, kw.pop('red'), kw.pop('nwc'), kw.pop('direction'),
                                        family=kw.pop('family'), source=src, targetFmaxMhz=350.0, **kw))
            errs = []
            if s.dspTree is not None and s.dspTree.dsp > s.dspTree.budget:
                errs.append(f'DSP {s.dspTree.dsp} over the budget {s.dspTree.budget}')
            errs += (s.checkGeometry() if n <= 32768 else []) + s.checkHazards()
            rng = random.Random(n * 7 + B)
            qs = []
            while len(qs) < 3:
                qq = _jobQ(s, rng)
                if qq not in qs:
                    qs.append(qq)
            G = s.recGroup()
            dd = s.tdirs[0]
            for qq in qs if n <= 16384 else qs[:1]:
                for g_ in sorted({G, 1, B}) if n <= 4096 else (G,):
                    s.recTables(qq, dd, g_)              # raises on a difference
            P = 6 if pat == 'keep' else 2 * nq
            idx, keeps = _records(pat, nq, P, rng)
            pq = [qs[i] for i in idx]
            if n <= 4096:
                xs = [[rng.randrange(qq) for _ in range(n)] for qq in pq]
                if 'fwd' in s.dirs:
                    Y = s.transform([_memFrame(x, n) for x in xs], 'fwd', pq)
                    if any(Y[f] != _nttRef(xs[f], pq[f], s.negacyclic) for f in range(P)):
                        errs.append('forward differs from the reference')
                if 'inv' in s.dirs:
                    Yr = [_nttRef(x, qq, s.negacyclic) for x, qq in zip(xs, pq)]
                    if s.transform([_memFrame(y, n) for y in Yr], 'inv', pq) != xs:
                        errs.append('inverse(reference) != x')
            pv = [rng.random() < 0.7 for _ in range(4099)]
            tv = [rng.random() < 0.6 for _ in range(4091)]
            for va, twv in ((None, None), (lambda c: pv[c % 4099], lambda c: tv[c % 4091]),
                            (None, lambda c: c > 300 and c % 7 == 0)):
                job = s.simulateJob(P, va, records=keeps, twValid=twv)
                errs += s.checkTwiddleWindows(job) + s.checkSets(job)
            C_, bub = s.computeCycles(), s.rnsBubble()
            NU, PG = len(s.recUnits()), s.genLatency()
            ia = s.simulateJob(4)['interval']
            ik = s.simulateJob(4, records=[False, True, True, True])['interval']
            if not (max(C_, s.beats) <= ik <= max(C_, 2 * s.beats) + 8):
                errs.append(f'kept-modulus interval {ik}, compute {C_}')
            if full and ia != C_ + bub:
                errs.append(f'new-q interval {ia}, compute {C_} + bubble {bub}')
            if not full and not C_ + bub <= ia <= max(C_ + bub, NU + PG + bub + s.headerBeats() + 8):
                errs.append(f'new-q interval {ia} (short stages), compute {C_} + bubble {bub}, units {NU}')
            if s.twiddleLanes() != 2 or s.recordBeats() != s.headerBeats():
                errs.append('record: the header alone, 2 entries a beat')
            op = IterativeNTT(s)
            E = s.twEntryWidth()
            pl = s.recIpPlan()
            for qq in qs[:2]:
                beats = op.rnsRecord(qq, direction=dd)
                if len(beats) != s.recordBeats():
                    errs.append('record length')
                hv = sum(v << (k * 2 * E) for k, v in enumerate(beats))
                if hv & 1 or any(((hv >> o) & ((1 << w_) - 1)) != (s.qPortValues(qq)[p_] & ((1 << w_) - 1))
                                 for p_, o, w_ in s.headerLayout()):
                    errs.append('record header: modulus constants')
                rf = s.genMultiplier.reductionFactor(qq)
                fld = {(tg, i): (hv >> o) & ((1 << w_) - 1) for tg, i, o, w_ in s.recFactorLayout()}
                tc = [s.twiddleTable(j, qq, 'c')[0] for j in range(B)]
                tt = [s.twiddleTable(j, qq, 't')[0] for j in range(B)]
                ent = lambda st, j, v: tc[j][st] if st <= s.b else tt[j][(1 << (st - s.b)) - 2 + v]   # noqa: E731
                if fld[('F', 0)] * rf % qq != 1:
                    errs.append('record header: the identity factor')
                for st in range(s.L):
                    if fld[('S', pl['sid'][st])] != ent(st, 0, 0):
                        errs.append(f'record header: seed of stage {st}')
                    for si, (kind, k) in enumerate(pl['slots']):
                        if kind == 'v' and k >= st - s.b:
                            continue                     # the stage has no such index bit
                        hi = ent(st, 1 << k, 0) if kind == 'j' else ent(st, 0, 1 << k)
                        if ent(st, 0, 0) * fld[('F', pl['fid'][st][si])] * rf % qq != hi:
                            errs.append(f'record header: factor of stage {st} bit {kind}{k}')
                kb = op.rnsRecord(qq, keep=True)
                if len(kb) != s.headerBeats() or not kb[0] & 1:
                    errs.append('kept record')
            if not s.checkTwiddleWindows(s._simulateJobRns(4, unsafe=True)):
                errs.append('negative test: the unsafe twin passed the window check')
            s.recTables(qs[0], dd)
            key = ('rfi', qs[0])                         # negative: a wrong factor must break the table check
            saved = dict(s._qCache[key])
            s._qCache[key][('F', 1)] = (saved[('F', 1)] + 1) % qs[0]
            try:
                s.recTables(qs[0], dd)
                errs.append('negative test: a wrong factor passed recTables')
            except AssertionError:
                pass
            s._qCache[key] = saved
            r_ = s.resources()
            tg = r_['breakdown']['twiddle generators']
            print(f'    {tag}: G {G} ({B // G} generators, PG {PG}, store {pl["SD"]}) units {NU} record '
                  f'{s.recordBeats()} beats x {2 * E} bits ({len(pl["fexp"])} factors, {len(pl["sexp"])} seeds) '
                  f'compute {C_} new-q {ia} (bubble {bub}{"" if full else ", short stages"}) kept {ik} gen LUT '
                  f'{tg["lut"]} DSP {tg["dsp"]}', flush=True)
            if errs:
                print(f'  {tag}: {errs[:3]}')
            ok = not errs
        except Exception as e:                       # noqa: BLE001
            ok = False
            import traceback
            traceback.print_exc()
            print(f'  {tag}: {type(e).__name__}: {e}')
        fails += not ok
        if not ok:
            print(f'  FAIL {tag}')
    # seeds on the record stream (recSeeds, 2026-11-12)
    seeded = _gate7ipSeedCases(quick)
    sf = sum(not _gate7ipSeedOne(c) for c in seeded) + (not _gate7ipSeedRefusals())
    print(f"gate 7 ip rec seeds (recSeeds): {len(seeded) + 1 - sf} of {len(seeded) + 1} pass")
    fails += sf
    total = len(cases) + len(seeded) + 1
    print(f"gate 7 ip rec (twiddles on chip, in place): {total - fails} of {total} pass "
          f"({time.time() - t0:.0f}s)")
    return fails


def _gate7ipSeedCases(quick: bool) -> list:
    """'rec' in place with seeds on the record stream (`recSeeds`): (tag, builder kwargs, moduli count, record
    pattern, expect, choice). expect: 'full' = a new modulus every polynomial runs at compute + bubble exactly;
    'short' = it does not (but faster than without seeds); 'same' = long stages, 'auto' keeps the header-only
    design (K 0, the same group). choice: the (G, K) that must come out (None: not pinned)."""
    W60, W52 = MF.friendly(30, 30), MF.friendly(26, 26)
    pts = [
        # short stages that reach compute + bubble
        (256, 4, 'wlm', W60, False, 'both', 'alt', 'full', (2, 4), dict(recSeeds=4, recGroup=2)),
        (256, 4, 'wlm', W60, False, 'both', 'alt', 'full', (1, 2), dict(recSeeds=2)),
        (256, 4, 'wlm', W60, False, 'both', 'alt', 'full', (4, 32), dict(recSeeds='auto')),   # one generator, K = SD
        (128, 8, 'wlm', W52, False, 'both', 'alt3', 'full', (8, 16), dict(recSeeds='auto')),
        (256, 8, 'mont', MF.odd(30), True, 'forward', 'alt3', 'full', (4, 16), dict(recSeeds='auto')),
        (128, 8, 'wlm', W52, False, 'both', 'alt3', 'full', (4, 4), dict(recSeeds=4, recGroup=4)),
        (64, 2, 'barrett', MF.odd(52), False, 'inverse', 'keep', 'full', (2, 4), dict(recSeeds=4)),
        (1024, 8, 'barrett', MF.odd(36), False, 'both', 'keep', 'full', (4, 4), dict(recSeeds='auto')),
        (16, 4, 'barrett', MF.odd(36), False, 'forward', 'alt', 'full', (4, 4), dict(recSeeds='auto')),
        (512, 4, 'barrett', MF.odd(64), False, 'forward', 'alt', 'full', None,
         dict(recSeeds=2, recMultiplier={'multiplier': 'booth', 'qBackend': 'booth'})),
        # short stages that do not: B 32, 16-cycle stages (the record port, 2 entries a beat, and PG bound it)
        (1024, 32, 'barrett', MF.odd(36), True, 'forward', 'alt', 'short', (1, 1), dict(recSeeds=1)),
        (1024, 32, 'barrett', MF.odd(36), True, 'forward', 'alt', 'short', None, dict(recSeeds='auto', recGroup=4)),
        # long stages: seeds change nothing ('auto' keeps the header-only design; an explicit K the same rate)
        (4096, 8, 'wlm', W60, False, 'both', 'alt', 'same', (4, 0), dict(recSeeds='auto')),
        (4096, 8, 'wlm', W60, True, 'forward', 'keep', 'full', (4, 4), dict(recSeeds=4)),
        (2048, 2, 'barrett', MF.odd(36), False, 'both', 'alt', 'full', (2, 16), dict(recSeeds=16, dspFraction=0.6)),
        (16384, 32, 'barrett', MF.odd(54), True, 'forward', 'alt3', 'full', (4, 2), dict(recSeeds=2, ramLatency=3)),
    ]
    C = []
    for n, B, red, fam, nwc, d, rec, expect, choice, extra in pts:
        iscale = 'stage' if d != 'forward' and not nwc else 'output'
        kw = dict(n=n, B=B, family=fam, red=red, nwc=nwc, direction=d, inverseScale=iscale, twiddleBuffer='recycle',
                  memOrg='inplace', twiddleSource='rec', **extra)
        C.append((f'ip rec seeds {red} {fam.describe()} n={n} B={B} {d} nwc={nwc} {rec} recSeeds={extra["recSeeds"]}'
                  + (f" G={extra['recGroup']}" if 'recGroup' in extra else '')
                  + (' lutgen' if 'recMultiplier' in extra else ''), kw, 3 if rec == 'alt3' else 2, rec, expect, choice))
    return [c for i, c in enumerate(C) if i in (0, 4, 6, 10, 12)] if quick else C


def _gate7ipSeedOne(case) -> bool:
    """One seeded case: geometry, hazards, twiddle windows and sets on twin jobs (free, random stalls, a record
    stream that starts late and stalls hard), every table bit-exact through the generator datapath including
    the seeded entries (`recTables`: the choice, and other (G, K)), the transform against the reference, the
    record read back independently (header: keep, modulus constants, factors, no stage seeds; seed beats: lane,
    group, entry against `twiddleTable`), the interval (expect; a 12-polynomial job the same), the choice of
    (G, K), the cost breakdown, and the negative tests (unsafe twin, a wrong factor, a wrong seed)."""
    tag, kw, nq, pat, expect, choice = case
    kw = dict(kw)
    try:
        n = kw.pop('n'); B = kw.pop('B')
        src = kw.pop('twiddleSource')
        red, nwc, d, fam = kw.pop('red'), kw.pop('nwc'), kw.pop('direction'), kw.pop('family')
        s = quiet(lambda: iterative('g7ip_seed', n, B, 0, red, nwc, d, family=fam, source=src, targetFmaxMhz=350.0,
                                    **kw))
        kw0 = {k: v for k, v in kw.items() if k not in ('recSeeds', 'recGroup')}
        s0 = quiet(lambda: iterative('g7ip_seed0', n, B, 0, red, nwc, d, family=fam, source=src,
                                     targetFmaxMhz=350.0, **kw0))          # the header-only design, default group
        errs = []
        if s.dspTree is not None and s.dspTree.dsp > s.dspTree.budget:
            errs.append(f'DSP {s.dspTree.dsp} over the budget {s.dspTree.budget}')
        errs += (s.checkGeometry() if n <= 32768 else []) + s.checkHazards()
        rng = random.Random(n * 11 + B)
        qs = []
        while len(qs) < 3:
            qq = _jobQ(s, rng)
            if qq not in qs:
                qs.append(qq)
        G, K = s.recGroup(), s.recSeedCount()
        pl = s.recIpPlan()
        g, NG, SD = pl['g'], B // G, pl['SD']
        if choice is not None and (G, K) != choice:
            errs.append(f'choice (G, K) = {(G, K)}, expected {choice}')
        dd = s.tdirs[0]
        for qq in qs if n <= 4096 else qs[:1]:
            s.recTables(qq, dd)                          # raises on a difference
            if n <= 4096:
                for g_ in sorted({G, 1, B}):
                    sd_ = s._recIpStore(1, g_)[2]
                    for k_ in sorted({1, 2, sd_}):
                        s.recTables(qq, dd, g_, k_)
        P = 6 if pat == 'keep' else 2 * nq
        idx, keeps = _records(pat, nq, P, rng)
        pq = [qs[i] for i in idx]
        if n <= 4096:
            xs = [[rng.randrange(qq) for _ in range(n)] for qq in pq]
            if 'fwd' in s.dirs:
                Y = s.transform([_memFrame(x, n) for x in xs], 'fwd', pq)
                if any(Y[f] != _nttRef(xs[f], pq[f], s.negacyclic) for f in range(P)):
                    errs.append('forward differs from the reference')
            if 'inv' in s.dirs:
                Yr = [_nttRef(x, qq, s.negacyclic) for x, qq in zip(xs, pq)]
                if s.transform([_memFrame(y, n) for y in Yr], 'inv', pq) != xs:
                    errs.append('inverse(reference) != x')
        pv = [rng.random() < 0.7 for _ in range(4099)]
        tv = [rng.random() < 0.6 for _ in range(4091)]
        for va, twv in ((None, None), (lambda c: pv[c % 4099], lambda c: tv[c % 4091]),
                        (None, lambda c: c > 300 and c % 7 == 0), (None, lambda c: c % 3 != 1)):
            job = s.simulateJob(P, va, records=keeps, twValid=twv)
            errs += s.checkTwiddleWindows(job) + s.checkSets(job)
            if job['twBeats'] != sum(s.recordBeats(k) for k in keeps):
                errs.append('twin: record beats taken')
        C_, bub = s.computeCycles(), s.rnsBubble()
        NU, PG, HB = len(s.recUnits()), s.genLatency(), s.headerBeats()
        ia = s.simulateJob(4)['interval']
        ia12 = s.simulateJob(12)['interval']
        ik = s.simulateJob(4, records=[False, True, True, True])['interval']
        i0 = s0.simulateJob(4)['interval']
        if not (max(C_, s.beats) <= ik <= max(C_, 2 * s.beats) + 8):
            errs.append(f'kept-modulus interval {ik}, compute {C_}')
        if ia12 != ia:
            errs.append(f'new-q interval {ia} over 4 polynomials, {ia12} over 12')
        if expect in ('full', 'same') and ia != C_ + bub:
            errs.append(f'new-q interval {ia}, compute {C_} + bubble {bub}')
        if expect == 'short' and not (C_ + bub < ia < i0 and ia <= HB + NU + PG + bub + 8):
            errs.append(f'new-q interval {ia} (short stages), compute {C_} + bubble {bub}, without seeds {i0}')
        if expect == 'full' and K == 0:
            errs.append('no seeds in a seeded case')
        op = IterativeNTT(s)
        E = s.twEntryWidth()
        if expect == 'same':
            # 'auto' on long stages: no seeds, and everything as the header-only design
            if K or G != s0.recGroup() or s.recUnits() != s0.recUnits() or s.recordBeats() != s0.recordBeats() \
                    or op.rnsRecord(qs[0], direction=dd) != IterativeNTT(s0).rnsRecord(qs[0], direction=dd):
                errs.append("'auto' on long stages differs from the header-only design")
        else:
            words = NG * sum(min(K, x) for x in pl['N'])
            if s.twiddleLanes() != 2 or s.recordBeats() != HB + s.recStreamBeats() or pl['seedWords'] != words \
                    or s.recStreamBeats() != max(1, NG // 2) * sum(min(K, x) for x in pl['N']):
                errs.append('record: header + seed beats, 2 entries a beat')
            if any(t_ == 'S' for t_, *_ in s.recFactorLayout()):
                errs.append('record header: stage seeds present with recSeeds')
            for qq in qs[:2]:
                beats = op.rnsRecord(qq, direction=dd)
                if len(beats) != s.recordBeats():
                    errs.append('record length')
                hv = sum(v << (k * 2 * E) for k, v in enumerate(beats[:HB]))
                if hv & 1 or any(((hv >> o) & ((1 << w_) - 1)) != (s.qPortValues(qq)[p_] & ((1 << w_) - 1))
                                 for p_, o, w_ in s.headerLayout()):
                    errs.append('record header: modulus constants')
                rf = s.genMultiplier.reductionFactor(qq)
                fld = {(tg, i): (hv >> o) & ((1 << w_) - 1) for tg, i, o, w_ in s.recFactorLayout()}
                tc = [s.twiddleTable(j, qq, 'c')[0] for j in range(B)]
                tt = [s.twiddleTable(j, qq, 't')[0] for j in range(B)]
                ent = lambda st, j, v: tc[j][st] if st <= s.b else tt[j][(1 << (st - s.b)) - 2 + v]   # noqa: E731
                if fld[('F', 0)] * rf % qq != 1:
                    errs.append('record header: the identity factor')
                for st in range(s.L):
                    for si, (kind, k) in enumerate(pl['slots']):
                        if kind == 'v' and k >= st - s.b:
                            continue
                        hi = ent(st, 1 << k, 0) if kind == 'j' else ent(st, 0, 1 << k)
                        if ent(st, 0, 0) * fld[('F', pl['fid'][st][si])] * rf % qq != hi:
                            errs.append(f'record header: factor of stage {st} bit {kind}{k}')
                # the seed beats, read back independently: stage, entry y, group pair m, lanes
                k, seen = HB, 0
                for st in range(s.L):
                    for y in range(min(K, G << max(0, st - s.b))):
                        for m in range(max(1, NG // 2)):
                            for ln in range(2 if NG > 1 else 1):
                                gi = 2 * m + ln
                                if (beats[k] >> (ln * E)) & ((1 << E) - 1) != ent(st, gi * G + (y & (G - 1)), y >> g):
                                    errs.append(f'seed beat {k}: stage {st} entry {y} group {gi}')
                                seen += 1
                            if NG == 1 and beats[k] >> E:
                                errs.append(f'seed beat {k}: lane 1 not zero with one generator')
                            k += 1
                if k != len(beats) or seen != words:
                    errs.append('seed beats: count')
                kb = op.rnsRecord(qq, keep=True)
                if len(kb) != HB or not kb[0] & 1:
                    errs.append('kept record')
            # negative: a wrong seed must break the table check
            s.recTables(qs[0], dd)
            sw = s.recSeedWords(qs[0])
            st_ = s.L - 1
            old = sw[st_][0][NG - 1]
            sw[st_][0][NG - 1] = (old + 1) % qs[0]
            try:
                s.recTables(qs[0], dd)
                errs.append('negative test: a wrong seed passed recTables')
            except AssertionError:
                pass
            sw[st_][0][NG - 1] = old
            if any(u[1] == 'G' for u in s.recUnits()):   # a wrong factor, where an operation uses one
                key = ('rfi', qs[0])
                saved = dict(s._qCache[key])
                bad = 0
                for fi in range(1, len(pl['fexp'])):
                    s._qCache[key] = dict(saved)
                    s._qCache[key][('F', fi)] = (saved[('F', fi)] + 1) % qs[0]
                    try:
                        s.recTables(qs[0], dd)
                    except AssertionError:
                        bad += 1
                s._qCache[key] = saved
                if not bad:
                    errs.append('negative test: no wrong factor breaks recTables')
            s.recTables(qs[0], dd)
        if not s.checkTwiddleWindows(s._simulateJobRns(4, unsafe=True)):
            errs.append('negative test: the unsafe twin passed the window check')
        r_ = s.resources()
        tg = r_['breakdown']['twiddle generators']
        if tg['groups'] != NG or tg['store'] != SD or tg['recordBeats'] != s.recordBeats() or \
                (K and (tg.get('recSeeds') != K or tg.get('seedWords') != pl['seedWords'])):
            errs.append('resources: the generator breakdown')
        print(f'    {tag}: G {G} ({NG} generators, PG {PG}, store {SD}) K {K} units {NU} record {s.recordBeats()} '
              f'beats x {2 * E} bits ({HB} header, {s.recStreamBeats()} seed beats, {pl.get("seedWords", 0)} '
              f'entries) compute {C_} new-q {ia} (bubble {bub}; {expect}) without seeds {i0} at '
              f'{B // s0.recGroup()} generators, kept {ik} gen LUT {tg["lut"]} DSP {tg["dsp"]}', flush=True)
        if errs:
            print(f'  {tag}: {errs[:3]}')
        ok = not errs
    except Exception as e:                       # noqa: BLE001
        ok = False
        import traceback
        traceback.print_exc()
        print(f'  {tag}: {type(e).__name__}: {e}')
    if not ok:
        print(f'  FAIL {tag}')
    return ok


def _gate7ipSeedRefusals() -> bool:
    """`recSeeds` is refused for anything but in-place 'rec', and for a K that is not a power of two in
    [1, the store depth]."""
    bads = [
        dict(memOrg='constgeo', twiddleBuffer='recycle', source='rec', recSeeds=2),          # constant geometry
        dict(memOrg='inplace', twiddleBuffer='recycle', source='ram', recSeeds=2),           # streamed record
        dict(memOrg='inplace', twiddleBuffer='single', source='ram', recSeeds='auto'),       # one modulus per job
        dict(memOrg='inplace', twiddleBuffer='recycle', source='rec', recSeeds=3),           # not a power of two
        dict(memOrg='inplace', twiddleBuffer='recycle', source='rec', recSeeds=-2),
        dict(memOrg='inplace', twiddleBuffer='recycle', source='rec', recSeeds='all'),
        dict(memOrg='inplace', twiddleBuffer='recycle', source='rec', recSeeds=True),
        dict(memOrg='inplace', twiddleBuffer='recycle', source='rec', recSeeds=64, recGroup=2),   # K > SD
        dict(memOrg='inplace', twiddleBuffer='recycle', source='rec', recSeeds=4096),             # K > SD, any group
    ]
    ok = True
    for bad in bads:
        try:
            s = quiet(lambda: iterative('g7ip_seed_bad', 256, 8, 0, 'barrett', False, 'forward', family=MF.odd(36),
                                        **bad))
            quiet(lambda: (s.recGroup(), s.recSeedCount(), s.recIpPlan()))
            print(f'  FAIL refused combination accepted: {bad}')
            ok = False
        except ValueError:
            pass
    try:                                                 # and the default is accepted and is the header alone
        s = quiet(lambda: iterative('g7ip_seed_ok', 256, 8, 0, 'barrett', False, 'forward', family=MF.odd(36),
                                    memOrg='inplace', twiddleBuffer='recycle', source='rec', recSeeds=0))
        if s.recSeedCount() or s.recordBeats() != s.headerBeats():
            raise ValueError('recSeeds=0 is not the header-only design')
    except ValueError as e:
        print(f'  FAIL recSeeds=0: {e}')
        ok = False
    return ok


def _records(pattern: str, nq: int, P: int, rng) -> tuple:
    """(moduli index per polynomial, keep flags): 'alt' a new q every polynomial (2 primes), 'alt3' over 3
    primes, 'keep' runs of a kept modulus."""
    if pattern == 'keep':
        idx = [0, 0, 1, 1, 1, 0][:P] + [0] * max(0, P - 6)
    else:
        idx = [k % nq for k in range(P)]
    return idx, [k > 0 and idx[k] == idx[k - 1] for k in range(P)]


def _decodeRecord(s, beats) -> dict:
    """An independent reading of one record's data beats (rnsRecord order): {(j, kind, entry): word}."""
    TL, E = s.twiddleLanes(), s.twEntryWidth()
    G, b, nd = s.B // TL, s.b, len(s.tdirs)
    out, k = {}, s.headerBeats()
    if s.twistOn:                                  # the twist region (output twist): not decoded here
        beats = beats[:len(beats) - s.twistBeats()]
    if s.memOrg == 'constgeo':                     # per stage, per entry of its region, per group
        for st in range(s.L):
            for e in range(s.cgDepths[st]):
                for g in range(G):
                    v = beats[k]
                    k += 1
                    for l in range(TL):
                        out[(g * TL + l, 't', s.cgBases[st] + e)] = (v >> (l * E)) & ((1 << E) - 1)
        assert k == len(beats)
        return out
    for st in range(s.L):
        ent = 1 if st <= b else 1 << (st - b)
        for di in range(nd):
            for e in range(ent):
                for g in range(G):
                    v = beats[k]
                    k += 1
                    for l in range(TL):
                        if st <= b:
                            key = (g * TL + l, 'c', st + di * s.cdepth)
                        else:
                            key = (g * TL + l, 't', (1 << (st - b)) - 2 + e + di * s.tdepth)
                        out[key] = (v >> (l * E)) & ((1 << E) - 1)
    assert k == len(beats)
    return out


def gate7rns(quick: bool, cases=None, label: str = 'gate 7 rns (modulus per polynomial)', budgets: bool = True) -> int:
    """The modulus per polynomial (twiddleBuffer 'recycle' / 'double'): geometry and data hazards, the twiddle
    windows and the modulus switch on twin jobs (a new q every polynomial, kept runs, random stalls on the
    record stream and the input), every polynomial bit-exact against the reference with its own q (forward)
    and inverse == x, the steady-state interval (compute + the bubble with a new q every polynomial, compute
    with a kept one), the record image read back independently, and the negative test (no permissions:
    the window check must fail)."""
    cases = cases if cases is not None else _gate7rnsCases(quick)
    t0, fails = time.time(), 0
    for tag, kw, nq, pat in cases:
        kw = dict(kw)
        try:
            n = kw.pop('n'); B = kw.pop('B')
            s = iterative('g7r', n, B, 0, kw.pop('red'), kw.pop('nwc'), kw.pop('direction'),
                          family=kw.pop('family'), source=kw.pop('source'),
                          multiplier='behavioural', qBackend='behavioural', **kw)
            if kw.get('memOrg') == 'constgeo' and s.memOrg != 'constgeo':
                raise AssertionError('memOrg not applied')
            errs = (s.checkGeometry() if n <= 4096 or s.memOrg == 'constgeo' else []) + s.checkHazards()
            rng = random.Random(n * 7 + B)
            qs = []
            while len(qs) < nq:
                qq = _jobQ(s, rng)
                if qq not in qs:
                    qs.append(qq)
            P = 6 if pat == 'keep' else 2 * nq
            idx, keeps = _records(pat, nq, P, rng)
            pq = [qs[i] for i in idx]
            xs = [[rng.randrange(qq) for _ in range(n)] for qq in pq]
            if 'fwd' in s.dirs:
                Y = s.transform([_memFrame(x, n) for x in xs], 'fwd', pq)
                if any(Y[f] != _nttRef(xs[f], pq[f], s.negacyclic) for f in range(P)):
                    errs.append('forward differs from the reference')
            if 'inv' in s.dirs:
                Yr = [_nttRef(x, qq, s.negacyclic) for x, qq in zip(xs, pq)]
                if s.transform([_memFrame(y, n) for y in Yr], 'inv', pq) != xs:
                    errs.append('inverse(reference) != x')
            pv = [rng.random() < 0.7 for _ in range(4099)]
            tv = [rng.random() < 0.6 for _ in range(4091)]
            for va, twv in ((None, None), (lambda c: pv[c % 4099], lambda c: tv[c % 4091])):
                job = s.simulateJob(P, va, records=keeps, twValid=twv)
                errs += s.checkTwiddleWindows(job)
            C_, bub = s.computeCycles(), s.rnsBubble()
            ia = s.simulateJob(4)['interval']
            ik = s.simulateJob(4, records=[False, True, True, True])['interval']
            if not (max(C_, s.beats) <= ik <= max(C_, 2 * s.beats) + 8):
                errs.append(f'kept-modulus interval {ik}, compute {C_}')
            narrow = kw.get('twiddleLanes') is not None
            if not narrow and not ia <= max(C_ + bub, 2 * s.beats + 8):
                errs.append(f'new-q interval {ia}, compute {C_} + bubble {bub}')
            if not ia >= C_ + bub:
                errs.append(f'new-q interval {ia} below compute + bubble {C_ + bub}')
            op = IterativeNTT(s)
            for qq in qs[:2]:
                dec = _decodeRecord(s, op.rnsRecord(qq))
                for j in range(B):
                    for kind in (('t', 'c') if s.memOrg != 'constgeo' else ('t',)):
                        w, wp = s.twiddleTable(j, qq, kind)
                        for i, x in enumerate(w):
                            want = x | ((wp[i] << s.twEntryCols()[0]) if wp is not None else 0)
                            if dec.get((j, kind, i)) != want:
                                errs.append(f'record entry {j} {kind} {i}')
                                break
                hb = op.rnsRecord(qq, keep=True)
                hv = sum(v << (k * s.twiddleLanes() * s.twEntryWidth()) for k, v in enumerate(hb))
                if hv & 1 != 1 or any(((hv >> o) & ((1 << w_) - 1)) != (s.qPortValues(qq)[p_] & ((1 << w_) - 1))
                                       for p_, o, w_ in s.headerLayout() if p_ != 'DIR'):
                    errs.append('record header')
            if s.twiddleBuffer == 'recycle' and not s.checkTwiddleWindows(s._simulateJobRns(4, unsafe=True)):
                errs.append('negative test: the unsafe twin passed the window check')
            ok = not errs
            if errs:
                print(f'  {tag}: {errs[:3]}')
            print(f'    {tag}: TL {s.twiddleLanes()} HB {s.headerBeats()} compute {C_} new-q {ia} (bubble {bub}) '
                  f'kept {ik}', flush=True)
        except Exception as e:                       # noqa: BLE001
            ok = False
            import traceback
            traceback.print_exc()
            print(f'  {tag}: {type(e).__name__}: {e}')
        fails += not ok
        if not ok:
            print(f'  FAIL {tag}')
    # the real DSP multipliers with a 60 % budget, both reductions of the boards, both variants
    for tb, red, fam in ((('recycle', 'wlm', MF.friendly(30, 30)), ('double', 'barrett', MF.odd(64))) if budgets else ()):
        tag = f'dsp budget 0.6 {tb} {red} n=1024 B=8'
        try:
            s = iterative('g7rb', 1024, 8, 0, red, False, 'both', family=fam, source='ram', inverseScale='stage',
                          dspFraction=0.6, twiddleBuffer=tb)
            rng = random.Random(5)
            qa, qb = _jobQ(s, rng), _jobQ(s, rng)
            xs = [[rng.randrange(q_) for _ in range(1024)] for q_ in (qa, qb, qa)]
            Y = s.transform([_memFrame(x, 1024) for x in xs], 'fwd', [qa, qb, qa])
            ok = all(Y[f] == referenceNtt(xs[f], q_) for f, q_ in enumerate((qa, qb, qa)))
            ok = ok and s.dspTree.dsp <= s.dspTree.budget and not s.checkHazards()
        except Exception as e:                       # noqa: BLE001
            ok = False
            print(f'  {tag}: {type(e).__name__}: {e}')
        cases.append(None)
        fails += not ok
        if not ok:
            print(f'  FAIL {tag}')
    print(f'{label}: {len(cases) - fails} of {len(cases)} pass ({time.time() - t0:.0f}s)')
    return fails


ITER_POINTS = [
    # name, n, B, q (or a run-time family), reduction, negacyclic, direction built, direction simulated,
    #   extra arguments (source, inverseScale, ioLanes, memStyle, twiddleStyle, ramLatency), polynomials, input valid
    ('itntt64_b4_barrett_q30_both', 64, 4, Q30, 'barrett', True, 'both', 'inv', {}, 3, None),
    ('itntt256_b2_mont_q52_fwd', 256, 2, Q52, 'mont', True, 'forward', 'fwd', {}, 3, 'random'),
    ('itntt1024_b8_wlm_q62_stage', 1024, 8, Q62, 'wlm', False, 'both', 'inv', {'inverseScale': 'stage'}, 2, None),
    ('itntt128_b1_shoup_q52', 128, 1, Q52, 'shoup', True, 'both', 'fwd', {}, 3, 'random'),
    ('itntt512_b16_kred_inv', 512, 16, KRED_Q, 'kred', False, 'inverse', 'inv', {}, 2, None),
    ('itntt64_b16_barrett_q30', 64, 16, Q30, 'barrett', True, 'both', 'fwd', {}, 4, None),
    ('itntt256_b8_barrett_q30_io1_r1', 256, 8, Q30, 'barrett', False, 'both', 'inv',
     {'ramLatency': 1, 'ioLanes': 1, 'inverseScale': 'stage'}, 3, None),
    ('rtitntt256_b4_wlm_fr17x45_ram', 256, 4, MF.friendly(17, 45), 'wlm', True, 'both', 'inv', {'source': 'ram'}, 3,
     'random'),
    ('rtitntt1024_b8_barrett_odd52_io4', 1024, 8, MF.odd(52), 'barrett', True, 'both', 'fwd',
     {'source': 'ram', 'ioLanes': 4}, 3, 'random'),
    ('rtitntt64_b2_shoup_odd52_ram', 64, 2, MF.odd(52), 'shoup', False, 'both', 'inv', {'source': 'ram'}, 4, None),
    ('rtitntt4096_b8_wlm_fr32x32_stage', 4096, 8, MF.friendly(32, 32), 'wlm', False, 'both', 'inv',
     {'source': 'ram', 'inverseScale': 'stage'}, 2, None),
    ('rtitntt2048_b32_mont_odd30_block', 2048, 32, MF.odd(30), 'mont', True, 'both', 'fwd',
     {'source': 'ram', 'memStyle': 'block', 'twiddleStyle': 'block'}, 2, 'random'),
    ('rtitntt512_b4_wlmgen_odd62_ultra', 512, 4, MF.odd(62), 'wlm-generic', True, 'both', 'inv',
     {'source': 'ram', 'memStyle': 'ultra'}, 2, None),
    ('rtitntt8192_b16_kred_kr23x7_stage', 8192, 16, MF.kred(23, 7), 'kred', False, 'both', 'fwd',
     {'source': 'ram', 'inverseScale': 'stage', 'ioLanes': 8}, 2, None),
    # cyclic with both directions shares the inverse twiddles by default; the unshared tables, and B = 1
    ('itntt256_b4_mont_q52_noshare', 256, 4, Q52, 'mont', False, 'both', 'inv',
     {'inverseScale': 'stage', 'shareInverseTwiddles': False}, 3, 'random'),
    ('rtitntt128_b1_wlm_fr32x32_share', 128, 1, MF.friendly(32, 32), 'wlm', False, 'both', 'inv',
     {'source': 'ram', 'inverseScale': 'stage'}, 3, None),
    ('rtitntt512_b8_barrett_odd52_r3', 512, 8, MF.odd(52), 'barrett', True, 'both', 'inv',
     {'source': 'ram', 'ramLatency': 3}, 3, 'random'),
    # the DSP-lean variants of the comparison rows: the modulus products on Booth LUT multipliers, a DSP budget
    ('rtitntt1024_b8_barrett_odd64_qbooth', 1024, 8, MF.odd(64), 'barrett', False, 'both', 'inv',
     {'source': 'ram', 'inverseScale': 'stage', 'qBackend': 'booth'}, 2, None),
    ('rtitntt1024_b8_wlm_fr30x30_d60', 1024, 8, MF.friendly(30, 30), 'wlm', False, 'both', 'inv',
     {'source': 'ram', 'inverseScale': 'stage', 'dspFraction': 0.6}, 2, 'random'),
]

#: constant geometry (memOrg 'constgeo'): as ITER_POINTS
ITER_CG_POINTS = [
    ('cgntt64_b4_barrett_q30_both', 64, 4, Q30, 'barrett', True, 'both', 'inv', {'memOrg': 'constgeo'}, 3, 'random'),
    ('cgntt256_b2_mont_q52_fwd', 256, 2, Q52, 'mont', True, 'forward', 'fwd', {'memOrg': 'constgeo'}, 3, None),
    ('cgntt1024_b8_wlm_q62_stage', 1024, 8, Q62, 'wlm', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'inverseScale': 'stage'}, 2, 'random'),
    ('cgntt128_b1_shoup_q52', 128, 1, Q52, 'shoup', True, 'both', 'fwd', {'memOrg': 'constgeo'}, 3, 'random'),
    ('cgntt512_b16_kred_inv', 512, 16, KRED_Q, 'kred', False, 'inverse', 'inv', {'memOrg': 'constgeo'}, 2, None),
    ('cgntt1024_b256_barrett_q30_stage', 1024, 256, Q30, 'barrett', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'ioLanes': 64}, 3, 'random'),
    ('cgntt256_b8_barrett_q30_io1_r1', 256, 8, Q30, 'barrett', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'ramLatency': 1, 'ioLanes': 1, 'inverseScale': 'stage'}, 3, None),
    ('rtcgntt256_b4_wlm_fr17x45_ram', 256, 4, MF.friendly(17, 45), 'wlm', True, 'both', 'inv',
     {'memOrg': 'constgeo', 'source': 'ram'}, 3, 'random'),
    ('rtcgntt2048_b512_barrett_odd36_stage', 2048, 512, MF.odd(36), 'barrett', False, 'both', 'fwd',
     {'memOrg': 'constgeo', 'source': 'ram', 'inverseScale': 'stage', 'ioLanes': 64}, 3, 'random'),
    ('rtcgntt1024_b256_barrett_odd54_stage', 1024, 256, MF.odd(54), 'barrett', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'source': 'ram', 'inverseScale': 'stage', 'ioLanes': 32}, 2, None),
    ('rtcgntt4096_b16_wlm_fr30x30_d60', 4096, 16, MF.friendly(30, 30), 'wlm', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'source': 'ram', 'inverseScale': 'stage', 'dspFraction': 0.6}, 2, 'random'),
    ('rtcgntt512_b8_mont_odd30_r3_block', 512, 8, MF.odd(30), 'mont', True, 'both', 'fwd',
     {'memOrg': 'constgeo', 'source': 'ram', 'ramLatency': 3, 'memStyle': 'block', 'twiddleStyle': 'block'}, 3, None),
    # crossRegs (register stages around the butterflies for SLR crossings), and the B = 1 operand swap with them
    ('rtcgntt1024_b256_barrett_odd54_x2', 1024, 256, MF.odd(54), 'barrett', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'source': 'ram', 'inverseScale': 'stage', 'ioLanes': 32, 'crossRegs': 2}, 3, 'random'),
    ('cgntt128_b1_shoup_q52_x1', 128, 1, Q52, 'shoup', True, 'both', 'inv', {'memOrg': 'constgeo', 'crossRegs': 1},
     3, 'random'),
    ('rtcgntt512_b8_wlm_fr30x30_x3_out', 512, 8, MF.friendly(30, 30), 'wlm', True, 'both', 'inv',
     {'memOrg': 'constgeo', 'source': 'ram', 'crossRegs': 3}, 3, None),
]
ITER_CG_RNS_POINTS = [
    ('cgrn256_b4_wlm_fr17x45_rec', 256, 4, MF.friendly(17, 45), 'wlm', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle'}, 4, 2, 'alt', 'random', 'random'),
    ('cgrn256_b4_wlm_fr17x45_dbl', 256, 4, MF.friendly(17, 45), 'wlm', False, 'both', 'fwd',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'double'}, 4, 2, 'alt', 'random', 'random'),
    ('cgrn1024_b256_barrett_odd54_rec', 1024, 256, MF.odd(54), 'barrett', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'ioLanes': 64}, 4, 2, 'alt',
     'random', 'random'),
    ('cgrn2048_b512_barrett_odd36_dbl', 2048, 512, MF.odd(36), 'barrett', False, 'both', 'fwd',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'double', 'ioLanes': 64}, 3, 3, 'alt3',
     'random', 'random'),
    ('cgrn512_b8_barrett_odd64_r3_rec', 512, 8, MF.odd(64), 'barrett', False, 'both', 'fwd',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'ramLatency': 3, 'twiddleBuffer': 'recycle'}, 5, 2, 'keep',
     None, 'random'),
    ('cgrn128_b1_shoup_odd52_rec', 128, 1, MF.odd(52), 'shoup', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle'}, 4, 3, 'alt3', 'random', 'random'),
    ('cgrn256_b8_mont_odd30_nwc_fwd_dbl', 256, 8, MF.odd(30), 'mont', True, 'forward', 'fwd',
     {'memOrg': 'constgeo', 'twiddleBuffer': 'double'}, 4, 2, 'alt', None, 'random'),
    ('cgrn1024_b8_wlm_fr30x30_tl1_rec', 1024, 8, MF.friendly(30, 30), 'wlm', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'twiddleLanes': 1}, 3, 2, 'alt',
     None, 'random'),
    ('cgrn2048_b16_wlm_fr26x26_d60_rec', 2048, 16, MF.friendly(26, 26), 'wlm', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'dspFraction': 0.6}, 4, 2, 'keep',
     'random', 'random'),
    ('cgrn1024_b256_barrett_odd54_x2_rec', 1024, 256, MF.odd(54), 'barrett', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'ioLanes': 64, 'crossRegs': 2}, 4, 2,
     'alt', 'random', 'random'),
    ('cgrn2048_b512_barrett_odd36_x2_dbl', 2048, 512, MF.odd(36), 'barrett', False, 'both', 'fwd',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'double', 'ioLanes': 64, 'crossRegs': 2}, 3, 3,
     'alt3', 'random', 'random'),
]
#: twiddleSource 'rec' (the tables written on chip): as ITER_CG_RNS_POINTS, with the AutoNTT-I primes of I2 / I3
ITER_CG_REC_POINTS = [
    ('cgrc256_b8_barrett_odd36_i2p_inv', 256, 8, MF.odd(36), 'barrett', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'twiddleSource': 'rec',
      'moduli': [34359754753, 34359771137]}, 4, 2, 'alt', 'random', 'random'),
    ('cgrc256_b8_barrett_odd36_i2p_fwd', 256, 8, MF.odd(36), 'barrett', False, 'both', 'fwd',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'twiddleSource': 'rec',
      'moduli': [34359754753, 34359771137]}, 4, 2, 'alt', None, 'random'),
    ('cgrc1024_b32_barrett_odd54_i3p_inv', 1024, 32, MF.odd(54), 'barrett', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'twiddleSource': 'rec',
      'ioLanes': 16, 'moduli': [9007199255019521, 9007199255347201]}, 4, 2, 'alt', 'random', 'random'),
    ('cgrc1024_b32_barrett_odd54_i3p_fwd_g1', 1024, 32, MF.odd(54), 'barrett', False, 'both', 'fwd',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'twiddleSource': 'rec',
      'ioLanes': 16, 'recGroup': 1, 'moduli': [9007199255019521, 9007199255347201]}, 3, 2, 'alt', None, None),
    ('cgrc2048_b512_barrett_odd36_i2p_keep', 2048, 512, MF.odd(36), 'barrett', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'twiddleSource': 'rec',
      'ioLanes': 64, 'moduli': [34359754753, 34359771137]}, 5, 2, 'keep', 'random', 'random'),
    ('cgrc512_b4_wlm_fr30x30_alt3_fwd', 512, 4, MF.friendly(30, 30), 'wlm', False, 'both', 'fwd',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'twiddleSource': 'rec',
      'ramLatency': 3}, 4, 3, 'alt3', 'random', 'random'),
    ('cgrc256_b8_mont_odd30_nwc_fwd_x2', 256, 8, MF.odd(30), 'mont', True, 'forward', 'fwd',
     {'memOrg': 'constgeo', 'twiddleBuffer': 'recycle', 'twiddleSource': 'rec', 'crossRegs': 2}, 4, 2, 'alt',
     'random', 'random'),
    ('cgrc128_b2_barrett_odd52_nogen_inv', 128, 2, MF.odd(52), 'barrett', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'twiddleSource': 'rec'}, 4, 2,
     'alt', 'random', 'random'),
    # fan-out trees (small limits, so every tree is several levels deep at these sizes) and DSP budgets over the
    # butterflies and the generators together; the generators on LUTs
    ('cgrc256_b8_barrett_odd36_i2p_f4_inv', 256, 8, MF.odd(36), 'barrett', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'twiddleSource': 'rec', 'fanout': 4,
      'moduli': [34359754753, 34359771137]}, 4, 2, 'alt', 'random', 'random'),
    ('cgrc1024_b32_barrett_odd54_i3p_f8_fwd', 1024, 32, MF.odd(54), 'barrett', False, 'both', 'fwd',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'twiddleSource': 'rec', 'fanout': 8,
      'ioLanes': 16, 'moduli': [9007199255019521, 9007199255347201]}, 4, 2, 'alt', 'random', 'random'),
    ('cgrc1024_b32_barrett_odd54_i3p_f4_d60_inv', 1024, 32, MF.odd(54), 'barrett', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'twiddleSource': 'rec', 'fanout': 4,
      'ioLanes': 16, 'dspFraction': 0.6, 'moduli': [9007199255019521, 9007199255347201]}, 4, 2, 'keep', 'random',
     'random'),
    ('cgrc512_b16_barrett_odd36_i2p_d80_x2_fwd', 512, 16, MF.odd(36), 'barrett', False, 'both', 'fwd',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'twiddleSource': 'rec',
      'dspFraction': 0.8, 'crossRegs': 2, 'moduli': [34359754753, 34359771137]}, 4, 2, 'alt', None, 'random'),
    ('cgrc256_b8_wlm_fr30x30_lutgen_f4_inv', 256, 8, MF.friendly(30, 30), 'wlm', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'twiddleSource': 'rec', 'fanout': 4,
      'recMultiplier': {'multiplier': 'booth', 'qBackend': 'booth'}}, 4, 3, 'alt3', 'random', 'random'),
    ('cgrc128_b2_barrett_odd52_nogen_f2_x1', 128, 2, MF.odd(52), 'barrett', False, 'both', 'fwd',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'twiddleSource': 'rec', 'fanout': 2,
      'crossRegs': 1}, 4, 2, 'alt', 'random', 'random'),
]
#: fan-out trees with one modulus per job (constant geometry, twiddleBuffer 'single'), as ITER_CG_POINTS
#: twiddleSource 'rec' in place (recycle; 2026-11-12): the tables generated on chip from the header alone. The
#: testbench also fails when a polynomial starts more than the twin's interval after the one before (the rate
#: check); 'fullRate': the generated design's interval must be compute + bubble (free run, a new q every polynomial)
_IPR = {'memOrg': 'inplace', 'twiddleBuffer': 'recycle', 'twiddleSource': 'rec'}
ITER_IP_REC_POINTS = [
    # the I1 row (n 4096, B 8, 60-bit run-time family): cyclic with the shared inverse (both directions of the one
    # core, AutoNTT-I's two primes), and negacyclic forward
    ('iprc4096_b8_wlm_fr30x30_i1_inv', 4096, 8, MF.friendly(30, 30), 'wlm', False, 'both', 'inv',
     dict(_IPR, inverseScale='stage', moduli=[576460796326838273, 576460798474321921], fullRate=True), 4, 2, 'alt',
     None, None),
    ('iprc4096_b8_wlm_fr30x30_i1_fwd_keep', 4096, 8, MF.friendly(30, 30), 'wlm', False, 'both', 'fwd',
     dict(_IPR, inverseScale='stage', moduli=[576460796326838273, 576460798474321921]), 6, 2, 'keep', 'random',
     'random'),
    ('iprc4096_b8_wlm_fr30x30_nwc_fwd', 4096, 8, MF.friendly(30, 30), 'wlm', True, 'forward', 'fwd',
     dict(_IPR, fullRate=True), 4, 2, 'alt', None, None),
    ('iprc4096_b8_wlm_fr30x30_nwc_fwd_keep', 4096, 8, MF.friendly(30, 30), 'wlm', True, 'forward', 'fwd',
     dict(_IPR), 6, 2, 'keep', 'random', 'random'),
    # larger B
    ('iprc65536_b64_wlm_fr30x30_fwd', 65536, 64, MF.friendly(30, 30), 'wlm', False, 'both', 'fwd',
     dict(_IPR, inverseScale='stage', fullRate=True), 3, 2, 'alt', None, None),
    ('iprc16384_b32_barrett_odd54_nwc_fwd', 16384, 32, MF.odd(54), 'barrett', True, 'forward', 'fwd',
     dict(_IPR, ramLatency=3, fullRate=True), 4, 3, 'alt3', None, None),
    ('iprc8192_b16_mont_odd30_inv_keep', 8192, 16, MF.odd(30), 'mont', False, 'inverse', 'inv',
     dict(_IPR, inverseScale='stage', ioLanes=8), 6, 2, 'keep', 'random', 'random'),
    # short stages (the generators set the period), every group size, a LUT generator
    ('iprc256_b4_wlm_fr30x30_inv', 256, 4, MF.friendly(30, 30), 'wlm', False, 'both', 'inv',
     dict(_IPR, inverseScale='stage'), 4, 2, 'alt', 'random', 'random'),
    ('iprc256_b8_mont_odd30_nwc_fwd', 256, 8, MF.odd(30), 'mont', True, 'forward', 'fwd', dict(_IPR), 4, 3, 'alt3',
     None, None),
    ('iprc1024_b32_barrett_odd36_nwc_fwd_g4', 1024, 32, MF.odd(36), 'barrett', True, 'forward', 'fwd',
     dict(_IPR, recGroup=4, ioLanes=16), 5, 2, 'keep', 'random', 'random'),
    ('iprc128_b8_wlm_fr26x26_fwd_g8', 128, 8, MF.friendly(26, 26), 'wlm', False, 'both', 'fwd',
     dict(_IPR, inverseScale='stage', recGroup=8), 4, 2, 'alt', 'random', 'random'),
    ('iprc64_b2_barrett_odd52_inv_g1', 64, 2, MF.odd(52), 'barrett', False, 'inverse', 'inv',
     dict(_IPR, inverseScale='stage', recGroup=1), 6, 2, 'keep', 'random', 'random'),
    ('iprc16_b4_barrett_odd36_fwd', 16, 4, MF.odd(36), 'barrett', False, 'forward', 'fwd', dict(_IPR), 4, 2, 'alt',
     None, 'random'),
    ('iprc512_b4_barrett_odd64_lutgen_fwd', 512, 4, MF.odd(64), 'barrett', False, 'forward', 'fwd',
     dict(_IPR, recMultiplier={'multiplier': 'booth', 'qBackend': 'booth'}), 4, 2, 'alt', 'random', 'random'),
]
IP_REC_SLOTS = [f'work/iterative/rns/iprec/slots/slotIP{i}' for i in range(1, 5)]


def _slowTw(c):
    """A record stream that starts late and stalls hard (one beat in seven cycles)."""
    return c > 300 and c % 7 == 0


#: 'rec' in place with seeds on the record stream (recSeeds; 2026-11-12): the first K entries of every generator
#: group's stage region arrive as stream beats after the header. Same testbench as ITER_IP_REC_POINTS (values,
#: every beat's cycle against the twin, the rate check); 'fullRate' points must run at compute + bubble
_W60 = MF.friendly(30, 30)
ITER_IP_SEED_POINTS = [
    # short stages that reach compute + bubble
    ('ipsd256_b4_wlm_fr30x30_k4_g2_inv', 256, 4, _W60, 'wlm', False, 'both', 'inv',
     dict(_IPR, inverseScale='stage', recSeeds=4, recGroup=2, fullRate=True), 4, 2, 'alt', None, None),
    ('ipsd256_b4_wlm_fr30x30_k2_fwd_keep', 256, 4, _W60, 'wlm', False, 'both', 'fwd',
     dict(_IPR, inverseScale='stage', recSeeds=2), 6, 2, 'keep', 'random', 'random'),
    ('ipsd256_b4_wlm_fr30x30_k4_g2_slowtw', 256, 4, _W60, 'wlm', False, 'both', 'inv',
     dict(_IPR, inverseScale='stage', recSeeds=4, recGroup=2), 4, 2, 'alt', None, _slowTw),
    ('ipsd256_b4_wlm_fr30x30_auto_inv', 256, 4, _W60, 'wlm', False, 'both', 'inv',
     dict(_IPR, inverseScale='stage', recSeeds='auto', fullRate=True), 5, 2, 'alt', None, None),
    ('ipsd256_b8_mont_odd30_nwc_auto_fwd', 256, 8, MF.odd(30), 'mont', True, 'forward', 'fwd',
     dict(_IPR, recSeeds='auto', fullRate=True), 6, 3, 'alt3', None, None),
    ('ipsd256_b8_mont_odd30_nwc_auto_fwd_stall', 256, 8, MF.odd(30), 'mont', True, 'forward', 'fwd',
     dict(_IPR, recSeeds='auto'), 6, 3, 'alt3', 'random', 'random'),
    ('ipsd128_b8_wlm_fr26x26_k4_g4_fwd', 128, 8, MF.friendly(26, 26), 'wlm', False, 'both', 'fwd',
     dict(_IPR, inverseScale='stage', recSeeds=4, recGroup=4, fullRate=True), 4, 2, 'alt', None, None),
    ('ipsd64_b2_barrett_odd52_k4_inv_keep', 64, 2, MF.odd(52), 'barrett', False, 'inverse', 'inv',
     dict(_IPR, inverseScale='stage', recSeeds=4), 6, 2, 'keep', 'random', 'random'),
    ('ipsd1024_b8_barrett_odd36_auto_inv', 1024, 8, MF.odd(36), 'barrett', False, 'both', 'inv',
     dict(_IPR, inverseScale='stage', recSeeds='auto', fullRate=True), 4, 2, 'alt', None, None),
    ('ipsd1024_b8_barrett_odd36_auto_fwd_keep', 1024, 8, MF.odd(36), 'barrett', False, 'both', 'fwd',
     dict(_IPR, inverseScale='stage', recSeeds='auto'), 6, 2, 'keep', 'random', 'random'),
    ('ipsd16_b4_barrett_odd36_auto_fwd', 16, 4, MF.odd(36), 'barrett', False, 'forward', 'fwd',
     dict(_IPR, recSeeds='auto', fullRate=True), 5, 2, 'alt', None, None),
    ('ipsd512_b4_barrett_odd64_lutgen_k2_fwd', 512, 4, MF.odd(64), 'barrett', False, 'forward', 'fwd',
     dict(_IPR, recSeeds=2, recMultiplier={'multiplier': 'booth', 'qBackend': 'booth'}, fullRate=True), 4, 2, 'alt',
     None, None),
    # short stages that do not reach it (B 32, 16-cycle stages): correct, faster than without seeds
    ('ipsd1024_b32_barrett_odd36_nwc_k1_fwd', 1024, 32, MF.odd(36), 'barrett', True, 'forward', 'fwd',
     dict(_IPR, recSeeds=1, ioLanes=16), 5, 2, 'keep', 'random', 'random'),
    ('ipsd1024_b32_barrett_odd36_nwc_auto_g4_fwd', 1024, 32, MF.odd(36), 'barrett', True, 'forward', 'fwd',
     dict(_IPR, recSeeds='auto', recGroup=4), 4, 2, 'alt', None, 'random'),
    # long stages with seeds given (the same rate as without), K = the store depth with one generator
    ('ipsd4096_b8_wlm_fr30x30_nwc_k4_fwd', 4096, 8, _W60, 'wlm', True, 'forward', 'fwd',
     dict(_IPR, recSeeds=4, fullRate=True), 4, 2, 'alt', None, None),
    ('ipsd2048_b2_barrett_odd36_k16_d60_inv', 2048, 2, MF.odd(36), 'barrett', False, 'both', 'inv',
     dict(_IPR, inverseScale='stage', recSeeds=16, dspFraction=0.6), 4, 2, 'alt', 'random', 'random'),
]
IP_SEED_SLOTS = [f'work/iterative/rns/iprec_seeds/slots/slotSD{i}'
                 for i in range(1, 5)]

ITER_CG_FAN_POINTS = [
    ('cgfn256_b8_barrett_q30_f4_stage', 256, 8, Q30, 'barrett', False, 'both', 'inv',
     {'memOrg': 'constgeo', 'inverseScale': 'stage', 'fanout': 4}, 3, 'random'),
    ('rtcgfn1024_b32_barrett_odd54_f8_io8', 1024, 32, MF.odd(54), 'barrett', False, 'both', 'fwd',
     {'memOrg': 'constgeo', 'source': 'ram', 'inverseScale': 'stage', 'ioLanes': 8, 'fanout': 8}, 3, 'random'),
    ('cgfn128_b1_shoup_q52_f2_x1', 128, 1, Q52, 'shoup', True, 'both', 'inv',
     {'memOrg': 'constgeo', 'crossRegs': 1, 'fanout': 2}, 3, None),
    ('rtcgfn512_b4_wlm_fr30x30_f4_nwc', 512, 4, MF.friendly(30, 30), 'wlm', True, 'both', 'fwd',
     {'memOrg': 'constgeo', 'source': 'ram', 'fanout': 4}, 3, 'random'),
]
REC_SLOTS = [f'work/iterative/rns/twgen/slots/slotRC{i}' for i in range(1, 9)]
CG_SLOTS = [f'work/framework/slotCG{i}' for i in range(1, 11)]
#: a direction per polynomial (dirPerPoly): as ITER_RNS_POINTS, the simulated direction a list per polynomial
ITER_DIR_RNS_POINTS = [
    ('rndir256_b4_wlm_fr17x45_rec', 256, 4, MF.friendly(17, 45), 'wlm', False, 'both',
     ['fwd', 'inv', 'fwd', 'inv'], {'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'dirPerPoly': True}, 4, 2,
     'alt', 'random', 'random'),
    ('rndir512_b8_barrett_odd52_nwc_dbl', 512, 8, MF.odd(52), 'barrett', True, 'both',
     ['fwd', 'fwd', 'inv', 'inv', 'inv', 'fwd'], {'inverseScale': 'output', 'twiddleBuffer': 'double', 'ioLanes': 4,
                                                  'dirPerPoly': True}, 6, 2, 'keep', 'random', 'random'),
    ('rndir1024_b8_wlm_fr30x30_nwc_rec', 1024, 8, MF.friendly(30, 30), 'wlm', True, 'both',
     ['inv', 'fwd', 'inv'], {'inverseScale': 'output', 'twiddleBuffer': 'recycle', 'ioLanes': 2, 'dirPerPoly': True},
     3, 3, 'alt3', None, 'random'),
    # constant geometry: the direction selects only the x2^-1 halvers (the twiddles are the record's)
    ('cgdir256_b4_wlm_fr17x45_rec', 256, 4, MF.friendly(17, 45), 'wlm', False, 'both',
     ['fwd', 'inv', 'fwd', 'inv'], {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle',
                                    'dirPerPoly': True}, 4, 2, 'alt', 'random', 'random'),
    ('cgdir512_b8_barrett_odd52_dbl', 512, 8, MF.odd(52), 'barrett', False, 'both',
     ['fwd', 'fwd', 'inv', 'inv', 'inv', 'fwd'], {'memOrg': 'constgeo', 'inverseScale': 'stage',
                                                  'twiddleBuffer': 'double', 'ioLanes': 4, 'dirPerPoly': True},
     6, 2, 'keep', 'random', 'random'),
    ('cgdir1024_b256_barrett_odd54_rec', 1024, 256, MF.odd(54), 'barrett', False, 'both',
     ['inv', 'fwd', 'fwd', 'inv'], {'memOrg': 'constgeo', 'inverseScale': 'stage', 'twiddleBuffer': 'recycle',
                                    'ioLanes': 64, 'dirPerPoly': True}, 4, 2, 'alt', 'random', 'random'),
]
#: RNS with the output twist (negacyclic inverse, inverseScale 'output'), in place; as ITER_RNS_POINTS
ITER_TWIST_RNS_POINTS = [
    ('rntw256_b4_barrett_odd52_nwc_rec', 256, 4, MF.odd(52), 'barrett', True, 'both', 'inv',
     {'inverseScale': 'output', 'twiddleBuffer': 'recycle', 'ioLanes': 8}, 4, 2, 'alt', 'random', 'random'),
    ('rntw128_b1_wlm_fr17x45_nwc_dbl', 128, 1, MF.friendly(17, 45), 'wlm', True, 'both', 'inv',
     {'inverseScale': 'output', 'twiddleBuffer': 'double', 'ioLanes': 2}, 4, 2, 'keep', None, 'random'),
    ('rntw1024_b8_wlm_fr30x30_nwc_io2_rec', 1024, 8, MF.friendly(30, 30), 'wlm', True, 'both', 'inv',
     {'inverseScale': 'output', 'twiddleBuffer': 'recycle', 'ioLanes': 2}, 3, 3, 'alt3', 'random', 'random'),
    ('rntw512_b8_barrett_odd64_nwc_fwd_rec', 512, 8, MF.odd(64), 'barrett', True, 'both', 'fwd',
     {'inverseScale': 'output', 'twiddleBuffer': 'recycle', 'ioLanes': 16, 'ramLatency': 3}, 4, 2, 'keep', 'random',
     'random'),
    ('rntw512_b4_mont_odd30_nwc_inv_dbl', 512, 4, MF.odd(30), 'mont', True, 'inverse', 'inv',
     {'inverseScale': 'output', 'twiddleBuffer': 'double', 'ioLanes': 4}, 4, 2, 'alt', 'random', None),
    ('rntw2048_b16_wlm_fr26x26_nwc_d60_rec', 2048, 16, MF.friendly(26, 26), 'wlm', True, 'both', 'inv',
     {'inverseScale': 'output', 'twiddleBuffer': 'recycle', 'ioLanes': 8, 'dspFraction': 0.6}, 3, 2, 'alt', 'random',
     'random'),
]

ITER_SLOTS = [f'work/framework/slotIT{i}' for i in range(1, 7)]

ITER_RNS_POINTS = [
    # name, n, B, family, reduction, negacyclic, direction built, simulated, extra, polynomials, moduli, record
    #   pattern ('alt' a new q every polynomial, 'alt3' over 3 primes, 'keep' runs of a kept q), input valid,
    #   record-stream valid
    ('rnit256_b4_wlm_fr17x45_rec', 256, 4, MF.friendly(17, 45), 'wlm', False, 'both', 'inv',
     {'inverseScale': 'stage', 'twiddleBuffer': 'recycle'}, 4, 2, 'alt', 'random', 'random'),
    ('rnit256_b4_wlm_fr17x45_dbl', 256, 4, MF.friendly(17, 45), 'wlm', False, 'both', 'fwd',
     {'inverseScale': 'stage', 'twiddleBuffer': 'double'}, 4, 2, 'alt', 'random', 'random'),
    ('rnit1024_b8_barrett_odd52_io4_dbl', 1024, 8, MF.odd(52), 'barrett', False, 'both', 'inv',
     {'inverseScale': 'stage', 'ioLanes': 4, 'twiddleBuffer': 'double'}, 3, 3, 'alt3', 'random', 'random'),
    ('rnit512_b8_barrett_odd64_r3_rec', 512, 8, MF.odd(64), 'barrett', False, 'both', 'fwd',
     {'inverseScale': 'stage', 'ramLatency': 3, 'twiddleBuffer': 'recycle'}, 5, 2, 'keep', None, 'random'),
    ('rnit128_b1_shoup_odd52_rec', 128, 1, MF.odd(52), 'shoup', False, 'both', 'inv',
     {'inverseScale': 'stage', 'twiddleBuffer': 'recycle'}, 4, 3, 'alt3', 'random', 'random'),
    ('rnit256_b8_mont_odd30_nwc_fwd_dbl', 256, 8, MF.odd(30), 'mont', True, 'forward', 'fwd',
     {'twiddleBuffer': 'double'}, 4, 2, 'alt', None, 'random'),
    ('rnit512_b4_wlm_fr32x32_noshare_rec', 512, 4, MF.friendly(32, 32), 'wlm', False, 'both', 'inv',
     {'inverseScale': 'stage', 'shareInverseTwiddles': False, 'twiddleBuffer': 'recycle'}, 4, 2, 'alt', 'random',
     None),
    ('rnit1024_b8_wlm_fr30x30_tl1_rec', 1024, 8, MF.friendly(30, 30), 'wlm', False, 'both', 'inv',
     {'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'twiddleLanes': 1}, 3, 2, 'alt', None, 'random'),
    ('rnit1024_b8_wlm_fr30x30_tl1_dbl', 1024, 8, MF.friendly(30, 30), 'wlm', False, 'both', 'fwd',
     {'inverseScale': 'stage', 'twiddleBuffer': 'double', 'twiddleLanes': 1}, 3, 2, 'alt', 'random', 'random'),
    ('rnit512_b16_kred_inv_rec', 512, 16, MF.kred(23, 7), 'kred', False, 'inverse', 'inv',
     {'inverseScale': 'stage', 'twiddleBuffer': 'recycle'}, 4, 2, 'alt', None, None),
    ('rnit256_b8_barrett_odd52_io1_r1_rec', 256, 8, MF.odd(52), 'barrett', False, 'both', 'inv',
     {'ramLatency': 1, 'ioLanes': 1, 'inverseScale': 'stage', 'twiddleBuffer': 'recycle'}, 3, 2, 'alt', 'random',
     'random'),
    ('rnit4096_b8_wlm_fr30x30_rec', 4096, 8, MF.friendly(30, 30), 'wlm', False, 'both', 'inv',
     {'inverseScale': 'stage', 'twiddleBuffer': 'recycle'}, 3, 2, 'alt', 'random', 'random'),
    ('rnit2048_b16_barrett_odd64_d60_dbl', 2048, 16, MF.odd(64), 'barrett', False, 'both', 'fwd',
     {'inverseScale': 'stage', 'twiddleBuffer': 'double', 'dspFraction': 0.6}, 3, 3, 'alt3', 'random', 'random'),
    ('rnit2048_b16_wlm_fr26x26_d60_rec', 2048, 16, MF.friendly(26, 26), 'wlm', False, 'both', 'inv',
     {'inverseScale': 'stage', 'twiddleBuffer': 'recycle', 'dspFraction': 0.6}, 4, 2, 'keep', 'random', 'random'),
]
RNS_SLOTS = [f'work/framework/slotRN{i}' for i in range(1, 11)]


def gate8rns(root: str, only, sim: bool, slots=None, points=None, label: str = 'gate 8 rns rtl') -> int:
    """The modulus per polynomial in RTL: distinct polynomials back to back under alternating primes (and
    kept runs), random input and record-stream valids, every output beat checked for its value and cycle
    against the twin; xsim over `slots`."""
    import concurrent.futures as cf
    pts = [p for p in (points or ITER_RNS_POINTS) if not only or p[0] in only]
    slots = slots or RNS_SLOTS
    lines, runs, slow = {}, [], set()
    for name, n, B, fam, red, nwc, d, dsim, extra, npoly, nq, pat, valid, twv in pts:
        t0 = time.time()
        extra = dict(extra)
        src = extra.pop('twiddleSource', 'ram')          # 'rec': the tables written on chip (gate 8 cg rec)
        given = extra.pop('moduli', None)                # the test primes (else drawn from the family)
        full = extra.pop('fullRate', False)              # the interval must be compute + bubble (in place 'rec')
        s = iterative(name, n, B, 0, red, nwc, direction=d, family=fam, source=src, targetFmaxMhz=350.0,
                      **extra)
        rng = random.Random(13)
        qs = list(given or [])
        while len(qs) < nq:
            qq = _jobQ(s, rng)
            if qq not in qs:
                qs.append(qq)
        idx, keeps = _records(pat, nq, npoly, rng)
        pq = [qs[i] for i in idx]
        frames = [[rng.randrange(qq) for _ in range(n)] for qq in pq]
        run = os.path.join(root, name)
        m = quiet(lambda: IterativeNTT(s).emitRtl(name, run, frames=frames, direction=dsim, q=pq,
                                                   validPattern=valid, records=keeps, twValidPattern=twv))
        r_ = quiet(s.resources)
        lines[name] = (f"  {name:<38} n={n:5d} B={B:3d} TL={s.twiddleLanes():2d} {s.twiddleBuffer:7} lat "
                       f"{m['latency']:6d} per poly {m['interval']:6d} (compute {s.computeCycles():6d} + bubble "
                       f"{s.rnsBubble()}) records {''.join('k' if k else 'q' for k in keeps)} "
                       f"LUT~{r_['lut']:7d} DSP {r_['dsp']:4d} BRAM {r_['bram']:6.1f} ({time.time() - t0:.0f}s)")
        if full and m['interval'] != s.computeCycles() + s.rnsBubble():
            lines[name] += '  RATE: the interval is not compute + bubble'
            slow.add(name)
        runs.append((name, run))
    fails = len(slow)
    if sim:
        queues = [runs[i::len(slots)] for i in range(len(slots))]

        def drain(qi):
            return {nm: _simIn(rn, slots[qi]) for nm, rn in queues[qi]}
        res = {}
        with cf.ThreadPoolExecutor(len(slots)) as ex:
            for f in [ex.submit(drain, i) for i in range(len(slots)) if queues[i]]:
                res.update(f.result())
        for name, _ in runs:
            v = res[name]
            fails += not v.startswith('PASS') and name not in slow
            lines[name] += f'  xsim {v}'
    for name, _ in runs:
        print(lines[name])
    print(f"{label}: {len(pts) - fails} of {len(pts)} {'simulated and passing' if sim else 'generated'}")
    return fails


def _simIn(run: str, slot: str) -> str:
    env = dict(os.environ, V80_REMOTE_ROOT=slot)
    r = subprocess.run([sys.executable, 'scripts/run_remote_sim.py', '--run-dir', run], capture_output=True,
                       text=True, env=env)
    with open(os.path.join(run, 'sim.log'), 'w', encoding='utf-8') as f:
        f.write(r.stdout + r.stderr)
    return next((ln.split(': ', 1)[1] for ln in r.stdout.splitlines()
                 if ln.startswith('[run_remote_sim]') and (': PASS' in ln or ': FAIL' in ln)), 'NO VERDICT')


def gate8(root: str, only, sim: bool, slots=None, points=None, label: str = 'gate 8 iterative rtl') -> int:
    """The iterative NTT's RTL: distinct polynomials back to back (some with a random input
    valid), every output beat checked for its value and its cycle against the controller
    twin; xsim in parallel over `slots`."""
    import concurrent.futures as cf
    pts = [p for p in (points or ITER_POINTS) if not only or p[0] in only]
    slots = slots or ITER_SLOTS
    lines, runs = {}, []
    for name, n, B, q, red, nwc, d, dsim, extra, npoly, valid in pts:
        t0 = time.time()
        extra = dict(extra)
        src = extra.pop('source', None)
        fam = q if not isinstance(q, int) else None
        extra.setdefault('twiddleBuffer', 'single')
        s = iterative(name, n, B, 0 if fam else q, red, nwc, direction=d, family=fam, source=src,
                      targetFmaxMhz=350.0, **extra)
        rng = random.Random(9)
        qq = _jobQ(s, rng)
        frames = [[rng.randrange(qq) for _ in range(n)] for _ in range(npoly)]
        run = os.path.join(root, name)
        m = quiet(lambda: IterativeNTT(s).emitRtl(name, run, frames=frames, direction=dsim, q=qq, validPattern=valid))
        r_ = quiet(s.resources)
        lines[name] = (f"  {name:<36} n={n:5d} B={B:3d} io={s.io:3d} lat {m['latency']:6d} per poly "
                       f"{m['interval']:6d} (compute {s.computeCycles():6d}) Pw {m['write_latency']:3d} "
                       f"LUT~{r_['lut']:7d} DSP {r_['dsp']:4d} BRAM {r_['bram']:6.1f} URAM {r_['uram']:3d} "
                       f"({time.time() - t0:.0f}s)")
        runs.append((name, run))
    fails = 0
    if sim:
        queues = [runs[i::len(slots)] for i in range(len(slots))]

        def drain(qi):
            return {nm: _simIn(rn, slots[qi]) for nm, rn in queues[qi]}
        res = {}
        with cf.ThreadPoolExecutor(len(slots)) as ex:
            for f in [ex.submit(drain, i) for i in range(len(slots)) if queues[i]]:
                res.update(f.result())
        for name, _ in runs:
            v = res[name]
            fails += not v.startswith('PASS')
            lines[name] += f'  xsim {v}'
    for name, _ in runs:
        print(lines[name])
    print(f"{label}: {len(pts) - fails} of {len(pts)} {'simulated and passing' if sim else 'generated'}")
    return fails

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--quick', action='store_true')
    ap.add_argument('--skip-model', action='store_true', help='only gate 4')
    ap.add_argument('--rtl', default=None, help='generate the RTL set into this directory')
    ap.add_argument('--only', default=None, help='comma list of RTL point names')
    ap.add_argument('--sim', action='store_true', help='with --rtl: simulate each in xsim')
    ap.add_argument('--test-size', type=int, default=300)
    a = ap.parse_args()
    fails = 0
    if not a.skip_model:
        fails += gate0(a.quick) + gate1(a.quick) + gate2() + gate3() + gate5(a.quick) + gate7(a.quick)
        fails += gate7rns(a.quick)
        fails += gate7cg(a.quick) + gate7cgRns(a.quick) + gate7twistRns(a.quick) + gate7dirRns(a.quick)
        fails += gate7cgRec(a.quick) + gate7ipRec(a.quick)
    if a.rtl:
        only = set(a.only.split(',')) if a.only else None
        fails += gate4b(a.rtl, only, a.sim, a.test_size)
        fails += gate4(a.rtl, only, a.sim, a.test_size)
        fails += gate6(a.rtl, only, a.sim)
        fails += gate8(a.rtl, only, a.sim)
        fails += gate8rns(a.rtl, only, a.sim)
        fails += gate8(a.rtl, only, a.sim, slots=CG_SLOTS, points=ITER_CG_POINTS, label='gate 8 cg rtl')
        fails += gate8rns(a.rtl, only, a.sim, slots=CG_SLOTS, points=ITER_CG_RNS_POINTS, label='gate 8 cg rns rtl')
        fails += gate8rns(a.rtl, only, a.sim, slots=CG_SLOTS, points=ITER_TWIST_RNS_POINTS,
                          label='gate 8 twist rns rtl')
        fails += gate8rns(a.rtl, only, a.sim, slots=CG_SLOTS, points=ITER_DIR_RNS_POINTS,
                          label='gate 8 dir rns rtl')
        fails += gate8rns(a.rtl, only, a.sim, slots=REC_SLOTS, points=ITER_CG_REC_POINTS, label='gate 8 cg rec rtl')
        fails += gate8(a.rtl, only, a.sim, slots=REC_SLOTS, points=ITER_CG_FAN_POINTS, label='gate 8 cg fan-out rtl')
        fails += gate8rns(a.rtl, only, a.sim, slots=IP_REC_SLOTS, points=ITER_IP_REC_POINTS,
                          label='gate 8 ip rec rtl')
        fails += gate8rns(a.rtl, only, a.sim, slots=IP_SEED_SLOTS, points=ITER_IP_SEED_POINTS,
                          label='gate 8 ip rec seeds rtl')
    print('all gates passed' if not fails else f'{fails} FAILING')
    return 1 if fails else 0


if __name__ == '__main__':
    sys.exit(main())
