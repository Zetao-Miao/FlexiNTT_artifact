'''Verify the modular multipliers and reductions (`operator_modeling.modmult`).

The modular-arithmetic counterpart to `runDspMultiplier.py` and
`runLutTiming.py`: one script, no test framework, run from the project root.

    python runModMult.py                 # model gates (a few minutes)
    python runModMult.py --quick         # fewer vectors and points
    python runModMult.py --rtl DIR       # + generate a sample of designs into DIR
    python runModMult.py --rtl DIR --sim # + simulate them (scripts/run_remote_sim.py)

Gate 1 -- sweep. Every family over many moduli from 28 to 64 bits (and a few
          beyond), each as a stand-alone reduction and inside a modular
          multiplier with two variable operands and with a constant twiddle,
          at exact, lazy-[0,2q) and uncorrected outputs, fully reduced and lazy
          inputs, and the families' own parameters (Barrett shifts and
          truncation, Montgomery R, word size and variant, chunk size, ...).
          Inputs: every combination of corners (0, 1, q-1, q, 2q-1, the
          bound's ends, ...) then random. Every output is compared with a plain
          big-integer reference: congruent to `T*factor` (or `A*B*factor`) and
          inside the declared output range. Every intermediate wire is checked
          against its declared bound on the way (`Datapath.evaluate`).
Gate 2 -- exhaustive. At small moduli every input of the declared range is
          run, so an algebraic bound a family declares (Barrett's quotient
          error, Shoup's [0, 2q), a fold's range) is checked on every value it
          covers, not on a sample.
Gate 3 -- clocked. `reset()` / `step()` streams the untimed outputs delayed by
          exactly `latency()` edges, at several stage requests and targets.
Gate 5 -- random generation. Random designs across reductions x multipliers
          (DSP, Booth, behavioural, constant) x timing (stage counts 0..3,
          targets 250..350 MHz) are generated: every heap's layer count, every
          node's start and the latency must agree between model and generator.
          An unreachable target is a refusal, not a failure.
Gate 4 -- RTL (with --rtl). A sample of designs across families, multiplier
          backends, pipeline requests and frequency targets is generated; the
          generator asserts that it built the model's latency, the contract is
          checked, and with --sim each testbench is run on xsim.
'''
from __future__ import annotations

import argparse
import contextlib
import io
import json
import random
import subprocess
import sys
import time
from pathlib import Path

from operator_modeling.core.IntType import IntType
from operator_modeling.core.datapath import ModelError
from operator_modeling.modmult.ModAddScheme import ModularAdderScheme
from operator_modeling.modmult.ModButterfly import ModularButterflyScheme
from operator_modeling.modmult.ModMult import ModularMultiplier, ModularReduction
from operator_modeling.modmult.ModMultScheme import ModularMultiplierScheme, ShoupModMult
from operator_modeling.modmult.ModulusFamily import ModulusFamily as MF
from operator_modeling.modmult.kim_moduli import KIM_Q
from operator_modeling.modmult.ReductionScheme import (
    GOLDILOCKS, BarrettReduction, FoldReduction, GoldilocksReduction, KRedReduction, MersenneReduction,
    MontgomeryReduction, ShiftAddReduction, SolinasReduction, TableLookupReduction,
    WordLevelMontgomery)
from operator_modeling.modmult.primes import (
    nttFriendlyPrime, pseudoMersennePrime, randomPrime, solinasPrime)

ROOT = Path(__file__).resolve().parent


# =============================================================================
# The moduli
# =============================================================================

GENERIC_BITS = (28, 30, 32, 36, 40, 44, 48, 52, 56, 60, 62, 64)
BEYOND_BITS = (80, 96, 128)


def generic(bits, seed=0):
    return randomPrime(bits, seed)


def friendly(bits, w, seed=0):
    return nttFriendlyPrime(bits, w, seed)


def moduli(quick: bool) -> dict[str, list[int]]:
    gb = GENERIC_BITS[::3] if quick else GENERIC_BITS
    out = {
        'generic': [generic(b) for b in gb] + ([] if quick else [generic(b) for b in BEYOND_BITS]),
        'friendly': [], 'mersenne': [(1 << 31) - 1, (1 << 61) - 1] + ([] if quick else [(1 << 89) - 1, (1 << 127) - 1]),
        'pseudo': [pseudoMersennePrime(b) for b in ((32, 64) if quick else (28, 32, 40, 48, 56, 61, 64))],
        'solinas': [solinasPrime(b) for b in ((32, 64) if quick else (30, 32, 40, 48, 56, 62, 64))],
    }
    pairs = [(32, 16), (64, 32)] if quick else [(28, 12), (30, 16), (32, 16), (36, 20), (40, 24), (48, 24),
                                               (52, 26), (56, 28), (60, 30), (62, 32), (64, 32), (64, 20)]
    out['friendly'] = [friendly(b, w) for b, w in pairs] + [998244353, 2013265921, GOLDILOCKS]
    return out


def wordFor(q: int) -> int:
    '''The largest w with q = 1 (mod 2^w), capped at 32 and below log q.'''
    w = ((q - 1) & -(q - 1)).bit_length() - 1
    return min(w, 32, q.bit_length() - 2)


# =============================================================================
# Sweep points: (label, factory) with factory() -> a fresh scheme
# =============================================================================

def reductionPoints(mods: dict, quick: bool) -> list:
    pts = []
    full = lambda q: IntType(0, (q - 1) ** 2)                          # noqa: E731
    lazy4 = lambda q: IntType(0, (4 * q - 1) * (4 * q - 1))            # noqa: E731
    signed = lambda q: IntType(-(q - 1) ** 2, (q - 1) ** 2)            # noqa: E731
    for q in mods['generic']:
        n = q.bit_length()
        for rng_, tb in (('exact', full), (2, full), ('lazy', full), ('exact', lazy4), ('exact', signed)):
            pts.append((f'barrett q{n} out={rng_} t={tb.__name__ if hasattr(tb, "__name__") else ""}',
                        lambda q=q, r=rng_, tb=tb: BarrettReduction(name='b', q=q, tIn=tb(q), outputRange=r)))
        pts.append((f'barrett q{n} classic', lambda q=q, n=n: BarrettReduction(
            name='b', q=q, tIn=full(q), s1=n - 1, s2=n + 1)))
        pts.append((f'barrett q{n} truncate', lambda q=q, n=n: BarrettReduction(
            name='b', q=q, tIn=full(q), truncate=n // 2)))
        pts.append((f'barrett q{n} dsp-const', lambda q=q: BarrettReduction(
            name='b', q=q, tIn=full(q), constBackend='dsp')))
        for rb in (n, n + 2):
            pts.append((f'montgomery q{n} R=2^{rb}', lambda q=q, rb=rb: MontgomeryReduction(
                name='m', q=q, tIn=full(q), rBits=rb)))
        pts.append((f'montgomery q{n} lazy', lambda q=q: MontgomeryReduction(
            name='m', q=q, tIn=full(q), outputRange='lazy')))
        pts.append((f'montgomery q{n} signed-in', lambda q=q: MontgomeryReduction(
            name='m', q=q, tIn=signed(q))))
        pts.append((f'montgomery q{n} dsp-const', lambda q=q: MontgomeryReduction(
            name='m', q=q, tIn=full(q), constBackend='dsp')))
        for w in (16, 32):
            if w < n:
                pts.append((f'wlm-generic q{n} w{w}', lambda q=q, w=w: WordLevelMontgomery(
                    name='w', q=q, tIn=full(q), w=w, variant='generic')))
        if n <= 64:
            for c in ((4, 6) if not quick else (6,)):
                pts.append((f'table q{n} c{c}', lambda q=q, c=c: TableLookupReduction(
                    name='t', q=q, tIn=full(q), chunkBits=c)))
    for q in mods['friendly']:
        n, w = q.bit_length(), wordFor(q)
        for variant in ('flag', 'negate'):
            for ww in sorted({w, max(4, w // 2)}):
                pts.append((f'wlm-{variant} q{n} w{ww}', lambda q=q, ww=ww, v=variant: WordLevelMontgomery(
                    name='w', q=q, tIn=full(q), w=ww, variant=v)))
        pts.append((f'wlm-flag q{n} lazy signed-in', lambda q=q, w=w: WordLevelMontgomery(
            name='w', q=q, tIn=signed(q), w=w, variant='flag', outputRange='lazy')))
        pts.append((f'wlm-flag q{n} out=2', lambda q=q, w=w: WordLevelMontgomery(
            name='w', q=q, tIn=full(q), w=w, variant='flag', outputRange=2)))
    for q in [3329, 7681, 12289, 998244353, 2013265921, 469762049, 167772161]:
        for st in (1, 2):
            for tb in (full, signed):
                pts.append((f'kred q{q.bit_length()} k={(q - 1) >> (((q - 1) & -(q - 1)).bit_length() - 1)} '
                            f'steps={st} {tb.__name__}', lambda q=q, st=st, tb=tb: KRedReduction(
                                name='k', q=q, tIn=tb(q), steps=st)))
    for q in mods['mersenne']:
        n = q.bit_length()
        pts.append((f'mersenne q{n}', lambda q=q: MersenneReduction(name='f', q=q, tIn=full(q))))
        pts.append((f'mersenne q{n} signed-in', lambda q=q: MersenneReduction(name='f', q=q, tIn=signed(q))))
    for q in mods['pseudo']:
        n = q.bit_length()
        pts.append((f'solinas q{n} (2^n-{(1 << n) - q})', lambda q=q: SolinasReduction(name='f', q=q, tIn=full(q))))
        pts.append((f'custom-shiftadd q{n}', lambda q=q: ShiftAddReduction(name='c', q=q, tIn=full(q))))
    for q in mods['solinas']:
        n = q.bit_length()
        pts.append((f'fold q{n} (2^n-2^k+1)', lambda q=q: FoldReduction(name='f', q=q, tIn=full(q))))
        pts.append((f'fold q{n} lazy4 in', lambda q=q: FoldReduction(name='f', q=q, tIn=lazy4(q))))
    pts.append(('goldilocks limbs u128', lambda: GoldilocksReduction(name='g', tIn=IntType(0, (GOLDILOCKS - 1) ** 2))))
    pts.append(('goldilocks limbs s130', lambda: GoldilocksReduction(name='g', tIn=IntType.signed(130))))
    pts.append(('goldilocks limbs u192', lambda: GoldilocksReduction(name='g', tIn=IntType.unsigned(192))))
    pts.append(('goldilocks fold generic', lambda: FoldReduction(name='g', q=GOLDILOCKS, tIn=IntType(0, (GOLDILOCKS - 1) ** 2))))
    return pts


def multiplierPoints(mods: dict, quick: bool) -> list:
    pts = []
    rng = random.Random(7)
    exact = lambda q: IntType(0, q - 1)                                # noqa: E731
    lazy = lambda q: IntType(0, 2 * q - 1)                             # noqa: E731
    fams = [
        ('barrett', BarrettReduction, {}, 'generic'),
        ('montgomery', MontgomeryReduction, {}, 'generic'),
        ('wlm', WordLevelMontgomery, None, 'friendly'),
        ('table', TableLookupReduction, {}, 'generic'),
        ('solinas', SolinasReduction, {}, 'pseudo'),
        ('fold', FoldReduction, {}, 'solinas'),
    ]
    for label, cls, args, pool in fams:
        qs = mods[pool] if not quick else mods[pool][:2]
        for q in qs:
            n = q.bit_length()
            if label == 'table' and n > 64:
                continue
            a = dict(args) if args is not None else {'w': wordFor(q)}
            for inR in (exact, lazy):
                for outR in ('exact', 2):
                    pts.append((f'mm-{label} q{n} in={inR.__name__} out={outR}',
                                lambda q=q, cls=cls, a=a, inR=inR, outR=outR: ModularMultiplierScheme(
                                    name='mm', q=q, aIn=inR(q), bIn=inR(q), multiplier='behavioural',
                                    reduction=cls, reductionArgs=a, outputRange=outR)))
            w = rng.randrange(1, q)
            pts.append((f'mm-{label} q{n} const', lambda q=q, cls=cls, a=a, w=w: ModularMultiplierScheme(
                name='mm', q=q, aIn=exact(q), constant=w, reduction=cls, reductionArgs=a)))
            if label in ('montgomery', 'wlm'):
                pts.append((f'mm-{label} q{n} const no-absorb', lambda q=q, cls=cls, a=a, w=w: ModularMultiplierScheme(
                    name='mm', q=q, aIn=exact(q), constant=w, reduction=cls, reductionArgs=a,
                    absorbFactor=False)))
    for q in mods['friendly']:
        n = q.bit_length()
        for bt in ('CT', 'GS'):
            for cls, a in ((BarrettReduction, {}), (MontgomeryReduction, {}),
                           (WordLevelMontgomery, {'w': wordFor(q)})):
                for const in (None, rng.randrange(1, q)):
                    pts.append((f'butterfly-{bt} {cls.family} q{n} {"const" if const else "var"}',
                                lambda q=q, bt=bt, cls=cls, a=a, c=const: ModularButterflyScheme(
                                    name='bu', q=q, butterflyType=bt, aIn=IntType(0, q - 1),
                                    bIn=IntType(0, q - 1), constant=c, multiplier='behavioural',
                                    reduction=cls, reductionArgs=a)))
            pts.append((f'butterfly-{bt} lazy q{n}', lambda q=q, bt=bt: ModularButterflyScheme(
                name='bu', q=q, butterflyType=bt, aIn=IntType(0, 2 * q - 1), bIn=IntType(0, 2 * q - 1),
                multiplier='behavioural', reduction=MontgomeryReduction, productRange=2, outputRange=2)))
    for q in mods['generic'] + mods['friendly']:
        n = q.bit_length()
        w = rng.randrange(1, q)
        for outR in ('exact', 2):
            pts.append((f'shoup-const q{n} out={outR}', lambda q=q, w=w, o=outR: ShoupModMult(
                name='s', q=q, aIn=IntType(0, q - 1), constant=w, outputRange=o)))
            pts.append((f'shoup-var q{n} out={outR}', lambda q=q, o=outR: ShoupModMult(
                name='s', q=q, aIn=IntType(0, q - 1), multiplier='behavioural', outputRange=o)))
        pts.append((f'shoup-const q{n} lazy-in', lambda q=q, w=w: ShoupModMult(
            name='s', q=q, aIn=IntType(0, 2 * q - 1), constant=w)))
        for sub in (False, True):
            pts.append((f'modadd q{n} {"sub" if sub else "add"}', lambda q=q, s=sub: ModularAdderScheme(
                name='a', q=q, aIn=IntType(0, q - 1), bIn=IntType(0, q - 1), subtract=s)))
        pts.append((f'modadd q{n} lazy in/out', lambda q=q: ModularAdderScheme(
            name='a', q=q, aIn=IntType(0, 2 * q - 1), bIn=IntType(0, 2 * q - 1), outputRange=2)))
    return pts


def runPoints(points, vectors: int, seed: int) -> tuple[int, int, list]:
    done = checked = 0
    failures = []
    for i, (label, make) in enumerate(points):
        try:
            sch = make()
            ins = sch.sampleInputs(vectors, random.Random(seed + i))
            errs = sch.checkReference(ins)
            checked += len(next(iter(ins.values())))
            if errs:
                failures.append((label, errs[:2]))
        except (ModelError, AssertionError, ValueError, KeyError) as e:
            failures.append((label, [f'{type(e).__name__}: {e}']))
        done += 1
    return done, checked, failures


# =============================================================================
# Gate 2: exhaustive at small moduli
# =============================================================================

def exhaustivePoints() -> list:
    '''(label, scheme, inputs) with inputs covering every value of the bound.'''
    out = []

    def allT(sch):
        b = sch.tIn
        return {'T': list(range(b.minValue, b.maxValue + 1))}

    def allAB(sch):
        qa, qb = sch.aIn, sch.bIn
        A, B = [], []
        for a in range(qa.minValue, qa.maxValue + 1):
            for b in range(qb.minValue, qb.maxValue + 1):
                A.append(a)
                B.append(b)
        return {'A': A, 'B': B}

    for q in (509, 769, 1021):
        n = q.bit_length()
        T = IntType(0, (q - 1) ** 2)
        for kw in ({}, {'s1': n - 1, 's2': n + 1}, {'truncate': n // 2}, {'truncate': n},
                   {'s1': n - 3, 's2': n + 4}, {'outputRange': 2}, {'constBackend': 'dsp'}):
            sch = BarrettReduction(name='b', q=q, tIn=T, **kw)
            out.append((f'barrett q={q} {kw}', sch, allT))
        sch = BarrettReduction(name='b', q=q, tIn=IntType(-(q - 1) ** 2 // 4, (q - 1) ** 2 // 4))
        out.append((f'barrett q={q} signed', sch, allT))
        for rb in (n, n + 1):
            out.append((f'montgomery q={q} R=2^{rb}', MontgomeryReduction(name='m', q=q, tIn=T, rBits=rb), allT))
        out.append((f'table q={q} c3', TableLookupReduction(name='t', q=q, tIn=T, chunkBits=3), allT))
        out.append((f'wlm-generic q={q} w4', WordLevelMontgomery(name='w', q=q, tIn=T, w=4, variant='generic'), allT))
    for q, w in ((97, 4), (193, 6), (577, 6), (769, 8), (257, 8)):
        T = IntType(0, (q - 1) ** 2)
        for v in ('flag', 'negate'):
            out.append((f'wlm-{v} q={q} w{w}', WordLevelMontgomery(name='w', q=q, tIn=T, w=w, variant=v), allT))
            out.append((f'wlm-{v} q={q} w{w} signed', WordLevelMontgomery(
                name='w', q=q, tIn=IntType(-(q - 1) ** 2, (q - 1) ** 2), w=w, variant=v), allT))
    for q in (127, 509, 1021):
        T = IntType(0, (q - 1) ** 2)
        if q == 127:
            out.append(('mersenne q=127', MersenneReduction(name='f', q=q, tIn=T), allT))
            out.append(('mersenne q=127 signed', MersenneReduction(name='f', q=q, tIn=IntType(-(q - 1) ** 2, (q - 1) ** 2)), allT))
        else:
            out.append((f'solinas q={q}', SolinasReduction(name='f', q=q, tIn=T), allT))
            out.append((f'custom-shiftadd q={q}', ShiftAddReduction(name='c', q=q, tIn=T), allT))
    for q in (3329,):
        for st in (1, 2):
            out.append((f'kred q={q} steps={st}', KRedReduction(name='k', q=q, tIn=IntType(0, (q - 1) ** 2), steps=st), allT))
    for bt in ('CT', 'GS'):
        for cls, a in ((BarrettReduction, {}), (MontgomeryReduction, {}), (WordLevelMontgomery, {'w': 8})):
            out.append((f'butterfly-{bt} {cls.family} q=257 all a,b', ModularButterflyScheme(
                name='bu', q=257, butterflyType=bt, aIn=IntType(0, 256), bIn=IntType(0, 256), constant=3,
                reduction=cls, reductionArgs=a), allAB))
    out.append(('fold q=241 (2^8-2^4+1)', FoldReduction(name='f', q=241, tIn=IntType(0, 240 ** 2)), allT))
    for q in (257, 509):
        for cls, args in ((BarrettReduction, {}), (MontgomeryReduction, {}), (TableLookupReduction, {'chunkBits': 3})):
            sch = ModularMultiplierScheme(name='mm', q=q, aIn=IntType(0, q - 1), bIn=IntType(0, q - 1),
                                          multiplier='behavioural', reduction=cls, reductionArgs=args)
            out.append((f'mm-{cls.__name__} q={q} all a,b', sch, allAB))
        sch = ShoupModMult(name='s', q=q, aIn=IntType(0, q - 1), multiplier='behavioural')
        out.append((f'shoup-var q={q} all a,b', sch,
                    lambda s: dict(allAB_(s), Bp=[s.companion(b) for b in allAB_(s)['B']])))
    out.append(('mm-wlm q=257 w8 all a,b', ModularMultiplierScheme(
        name='mm', q=257, aIn=IntType(0, 256), bIn=IntType(0, 256), multiplier='behavioural',
        reduction=WordLevelMontgomery, reductionArgs={'w': 8}), allAB))
    out.append(('modadd q=509 sub all', ModularAdderScheme(name='a', q=509, aIn=IntType(0, 1017),
                                                           bIn=IntType(0, 1017), subtract=True), allAB))
    return out


def allAB_(sch):
    A, B = [], []
    for a in range(sch.aIn.minValue, sch.aIn.maxValue + 1):
        for b in range(sch.bIn.minValue, sch.bIn.maxValue + 1):
            A.append(a)
            B.append(b)
    return {'A': A, 'B': B}


def shoupConstExhaustive(q: int, constants: int = 24) -> tuple[int, list]:
    rng = random.Random(q)
    errs, n = [], 0
    for w in [1, q - 1] + [rng.randrange(1, q) for _ in range(constants)]:
        for lazyIn in (False, True):
            aIn = IntType(0, (2 * q - 1) if lazyIn else q - 1)
            sch = ShoupModMult(name='s', q=q, aIn=aIn, constant=w)
            ins = {'A': list(range(aIn.minValue, aIn.maxValue + 1))}
            e = sch.checkReference(ins)
            n += len(ins['A'])
            if e:
                errs.append((f'shoup-const q={q} w={w}', e[:1]))
        for cls, args in ((MontgomeryReduction, {}), (BarrettReduction, {})):
            sch = ModularMultiplierScheme(name='mm', q=q, aIn=IntType(0, q - 1), constant=w,
                                          reduction=cls, reductionArgs=args)
            ins = {'A': list(range(q))}
            e = sch.checkReference(ins)
            n += q
            if e:
                errs.append((f'mm-const-{cls.__name__} q={q} w={w}', e[:1]))
    return n, errs


# =============================================================================
# Run-time modulus: families instead of one q (gates 1r and 2r)
# =============================================================================

def withFold(sch, mode: str):
    '''The scheme with its corrections folded as `mode` says ('never', 'auto', 'always').'''
    sch.foldCorrections = mode
    return sch


def runtimeFamilies(quick: bool) -> dict[str, list]:
    """(label, family) per kind: the widths the paper and the RNS designs use."""
    out = {
        'odd': [('odd30', MF.odd(30)), ('odd52', MF.odd(52)), ('odd62', MF.odd(62)), ('odd64', MF.odd(64))],
        'friendly': [('fr17x45', MF.friendly(17, 45)), ('fr16x14', MF.friendly(16, 14)),
                     ('fr26x26', MF.friendly(26, 26)), ('fr32x32', MF.friendly(32, 32)),
                     ('fr12x50', MF.friendly(12, 50))],
        'kred': [('kr23x7', MF.kred(23, 7)), ('kr8x5', MF.kred(8, 5)), ('kr26x4', MF.kred(26, 4))],
        'pm': [('pm61x12', MF.pseudoMersenne(61, 12)), ('pm32x8', MF.pseudoMersenne(32, 8)),
               ('pm64x16', MF.pseudoMersenne(64, 16))],
    }
    # modulus tables (one member per polynomial at run time): Kim et al.'s 42 (61 and 51-52 bits) and a
    # small mixed-width set
    out['table'] = [('kim42', MF.table(KIM_Q)), ('tbl-mixed', MF.table([1000003, 2147483647, 4294967291, 65537]))]
    if quick:
        out = {k: v[:2] for k, v in out.items()}
    return out


def runtimeReductionPoints(quick: bool) -> list:
    pts = []
    F = runtimeFamilies(quick)
    full = lambda f: IntType(0, (f.qMax - 1) ** 2)                     # noqa: E731
    signed = lambda f: IntType(-(f.qMax - 1) ** 2, (f.qMax - 1) ** 2)   # noqa: E731
    beh = dict(qBackend='behavioural')
    for lab, fam in F['odd'] + F['friendly'] + F['pm']:
        for r in ('exact', 2, 'lazy'):
            pts.append((f'rt-barrett {lab} out={r}', lambda f=fam, r=r: BarrettReduction(
                name='b', family=f, tIn=full(f), outputRange=r, **beh)))
        pts.append((f'rt-barrett {lab} signed-in', lambda f=fam: BarrettReduction(
            name='b', family=f, tIn=signed(f), **beh)))
        pts.append((f'rt-barrett {lab} classic shifts', lambda f=fam: BarrettReduction(
            name='b', family=f, tIn=full(f), s1=f.n - 1, s2=f.n + 1, **beh)))
        for rb in (fam.n, fam.n + 2):
            pts.append((f'rt-montgomery {lab} R=2^{rb}', lambda f=fam, rb=rb: MontgomeryReduction(
                name='m', family=f, tIn=full(f), rBits=rb, **beh)))
        pts.append((f'rt-montgomery {lab} signed-in', lambda f=fam: MontgomeryReduction(
            name='m', family=f, tIn=signed(f), **beh)))
    for lab, fam in F['odd']:
        for w in (16, 26, 32):
            if w < fam.n:
                for arr in (None, 'balanced'):
                    pts.append((f'rt-wlm-generic {lab} w{w} {arr or "equal"}', lambda f=fam, w=w, a=arr: WordLevelMontgomery(
                        name='w', family=f, tIn=full(f), w=w, variant='generic', arrangement=a, **beh)))
    for lab, fam in F['friendly']:
        v = fam.p['v']
        for arr in ('greedy', 'balanced', 'equal'):
            pts.append((f'rt-wlm {lab} {arr}', lambda f=fam, a=arr: WordLevelMontgomery(
                name='w', family=f, tIn=full(f), arrangement=a, **beh)))
        pts.append((f'rt-wlm {lab} narrow steps', lambda f=fam, v=v: WordLevelMontgomery(
            name='w', family=f, tIn=full(f), stepWidths=[max(1, v // 2)] * -(-f.n // max(1, v // 2)), **beh)))
        pts.append((f'rt-wlm {lab} signed-in lazy', lambda f=fam: WordLevelMontgomery(
            name='w', family=f, tIn=signed(f), outputRange='lazy', **beh)))
        pts.append((f'rt-wlm {lab} out=2', lambda f=fam: WordLevelMontgomery(
            name='w', family=f, tIn=full(f), outputRange=2, **beh)))
    for lab, fam in F['kred']:
        for st in (1, 2):
            for tb in (full, signed):
                pts.append((f'rt-kred {lab} steps={st} {tb.__name__ if hasattr(tb, "__name__") else ""}',
                            lambda f=fam, st=st, tb=tb: KRedReduction(name='k', family=f, tIn=tb(f), steps=st, **beh)))
    for lab, fam in F['pm']:
        pts.append((f'rt-solinas {lab}', lambda f=fam: SolinasReduction(name='s', family=f, tIn=full(f), **beh)))
        pts.append((f'rt-solinas {lab} signed-in', lambda f=fam: SolinasReduction(name='s', family=f, tIn=signed(f), **beh)))
    for lab, fam in F['table']:
        for r in ('exact', 2, 'lazy'):
            pts.append((f'rt-barrett {lab} out={r}', lambda f=fam, r=r: BarrettReduction(
                name='b', family=f, tIn=full(f), outputRange=r, **beh)))
        pts.append((f'rt-barrett {lab} signed-in', lambda f=fam: BarrettReduction(
            name='b', family=f, tIn=signed(f), **beh)))
        pts.append((f'rt-montgomery {lab} R=2^{fam.n}', lambda f=fam: MontgomeryReduction(
            name='m', family=f, tIn=full(f), **beh)))
    # the backends themselves: products by run-time constants on DSPs and Booth
    for qb, budget in (('dsp', None), ('dsp', 1), ('booth', None)):
        fam = MF.friendly(17, 45)
        pts.append((f'rt-wlm fr17x45 {qb} budget={budget}', lambda f=fam, qb=qb, b=budget: WordLevelMontgomery(
            name='w', family=f, tIn=full(f), qBackend=qb, qDspBudget=b)))
        fam = MF.odd(52)
        pts.append((f'rt-barrett odd52 {qb} budget={budget}', lambda f=fam, qb=qb, b=budget: BarrettReduction(
            name='b', family=f, tIn=full(f), qBackend=qb, qDspBudget=b)))
    return pts


def runtimeMultiplierPoints(quick: bool) -> list:
    pts = []
    F = runtimeFamilies(quick)
    exact = lambda f: IntType(0, f.qMax - 1)                           # noqa: E731
    lazy = lambda f: IntType(0, 2 * f.qMax - 1)                        # noqa: E731
    beh = dict(multiplier='behavioural', qBackend='behavioural')
    combos = [(cls, a, F[pool]) for cls, a, pool in (
        (BarrettReduction, {}, 'odd'), (MontgomeryReduction, {}, 'odd'), (BarrettReduction, {}, 'friendly'),
        (WordLevelMontgomery, {}, 'friendly'), (WordLevelMontgomery, {'arrangement': 'balanced'}, 'friendly'),
        (WordLevelMontgomery, {'w': 26, 'variant': 'generic'}, 'odd'), (KRedReduction, {}, 'kred'),
        (SolinasReduction, {}, 'pm'))]
    for cls, a, fams in combos:
        for lab, fam in fams:
            for inR in (exact, lazy):
                for outR in ('exact', 2):
                    pts.append((f'rt-mm-{cls.family} {lab} {a} in={inR.__name__} out={outR}',
                                lambda f=fam, cls=cls, a=a, inR=inR, o=outR: ModularMultiplierScheme(
                                    name='mm', family=f, aIn=inR(f), bIn=inR(f), reduction=cls, reductionArgs=a,
                                    outputRange=o, **beh)))
    for lab, fam in F['table']:
        for cls in (BarrettReduction, MontgomeryReduction):
            for inR in (exact, lazy):
                pts.append((f'rt-mm-{cls.family} {lab} in={inR.__name__}', lambda f=fam, cls=cls, inR=inR:
                            ModularMultiplierScheme(name='mm', family=f, aIn=inR(f), bIn=inR(f), reduction=cls, **beh)))
    for lab, fam in F['friendly'] + F['odd'] + F['table']:
        red, a = (WordLevelMontgomery, {}) if fam.kind == 'friendly' else (BarrettReduction, {})
        for bt in ('CT', 'GS'):
            pts.append((f'rt-butterfly-{bt} {red.family} {lab}', lambda f=fam, bt=bt, red=red, a=a: ModularButterflyScheme(
                name='bu', family=f, butterflyType=bt, aIn=exact(f), bIn=exact(f), reduction=red, reductionArgs=a,
                **beh)))
            pts.append((f'rt-butterfly-{bt} {red.family} {lab} lazy', lambda f=fam, bt=bt, red=red, a=a: ModularButterflyScheme(
                name='bu', family=f, butterflyType=bt, aIn=lazy(f), bIn=lazy(f), reduction=red, reductionArgs=a,
                productRange=2, outputRange=2, **beh)))
    for lab, fam in F['friendly'] + F['odd']:
        red = WordLevelMontgomery if fam.kind == 'friendly' else BarrettReduction
        for mode in ('never', 'always'):
            for st in (False, True):
                for bt in ('CT', 'GS'):
                    pts.append((f'rt-butterfly-{bt} {red.family} {lab} fold={mode} static={st}',
                                lambda f=fam, bt=bt, red=red, m=mode, st=st: withFold(ModularButterflyScheme(
                                    name='bu', family=f, butterflyType=bt, aIn=exact(f), bIn=exact(f), reduction=red,
                                    staticModulus=st, **beh), m)))
                pts.append((f'rt-mm-{red.family} {lab} fold={mode} static={st}',
                            lambda f=fam, red=red, m=mode, st=st: withFold(ModularMultiplierScheme(
                                name='mm', family=f, aIn=exact(f), bIn=exact(f), reduction=red, staticModulus=st,
                                **beh), m)))
                pts.append((f'rt-modadd {lab} sub lazy fold={mode} static={st}', lambda f=fam, m=mode, st=st: withFold(
                    ModularAdderScheme(name='a', family=f, aIn=lazy(f), bIn=lazy(f), subtract=True, outputRange=2,
                                       staticModulus=st), m)))
    for lab, fam in F['odd'] + F['friendly']:
        for o in ('exact', 2):
            pts.append((f'rt-shoup {lab} out={o}', lambda f=fam, o=o: ShoupModMult(
                name='s', family=f, aIn=exact(f), multiplier='behavioural', outputRange=o)))
        for sub in (False, True):
            pts.append((f'rt-modadd {lab} {"sub" if sub else "add"}', lambda f=fam, s=sub: ModularAdderScheme(
                name='a', family=f, aIn=exact(f), bIn=exact(f), subtract=s)))
        pts.append((f'rt-modadd {lab} lazy in/out', lambda f=fam: ModularAdderScheme(
            name='a', family=f, aIn=lazy(f), bIn=lazy(f), outputRange=2)))
    return pts


def wlmArrangementPoints(mods: dict) -> list:
    """Fixed q: the step arrangements and q_H widths over the friendly moduli
    (and every fixed-q family with its two-candidate corrections compare-folded)."""
    pts = []
    for q in mods['generic'] + mods['friendly']:
        n = q.bit_length()
        for cls in (BarrettReduction, MontgomeryReduction):
            pts.append((f'{cls.family} q{n} fold=always', lambda q=q, cls=cls: withFold(cls(
                name='r', q=q, tIn=IntType(0, (q - 1) ** 2)), 'always')))
            for bt in ('CT', 'GS'):
                pts.append((f'butterfly-{bt} {cls.family} q{n} fold=always', lambda q=q, cls=cls, bt=bt: withFold(
                    ModularButterflyScheme(name='bu', q=q, butterflyType=bt, aIn=IntType(0, q - 1), bIn=IntType(0, q - 1),
                                           multiplier='behavioural', reduction=cls), 'always')))
        for m in ('never', 'always'):
            pts.append((f'modadd q{n} sub fold={m}', lambda q=q, m=m: withFold(ModularAdderScheme(
                name='a', q=q, aIn=IntType(0, q - 1), bIn=IntType(0, q - 1), subtract=True), m)))
    full = lambda q: IntType(0, (q - 1) ** 2)                          # noqa: E731
    for q in mods['friendly']:
        n = q.bit_length()
        val = ((q - 1) & -(q - 1)).bit_length() - 1
        for variant in ('flag', 'negate'):
            for arr in ('greedy', 'balanced', 'equal'):
                pts.append((f'wlm-{variant} q{n} {arr}', lambda q=q, v=variant, a=arr: WordLevelMontgomery(
                    name='w', q=q, tIn=full(q), variant=v, arrangement=a)))
            for h in sorted({n - val, n - val + 3, n - max(2, val // 2)}):
                if 0 < n - h <= val:
                    pts.append((f'wlm-{variant} q{n} qhBits={h}', lambda q=q, v=variant, h=h: WordLevelMontgomery(
                        name='w', q=q, tIn=full(q), variant=v, qhBits=h, arrangement='balanced')))
    return pts


def _rangeFor(sch, port: str, q: int) -> range:
    """The values of one input for member q: its relative range, or the static bound."""
    b = getattr(sch, sch._boundAttr(port))
    rel = sch.tRel() if port == 'T' and hasattr(sch, 'tRel') else (
        sch.dataRel(port) if hasattr(sch, 'dataRel') else None)
    lo, hi = b.minValue, b.maxValue
    if rel is not None:
        rl, rh = rel.atInt(q)
        lo, hi = max(lo, rl), min(hi, rh)
    return range(lo, hi + 1)


def _membersInputs(sch, data):
    """Every family member times `data(q)` (a dict of equal-length lists)."""
    out: dict[str, list] = {}
    for q in sch.modulusFamily.members():
        pv = sch.qPortValues(q)
        d = data(q)
        k = len(next(iter(d.values())))
        for p, vals in d.items():
            out.setdefault(p, []).extend(vals)
        for p, v in pv.items():
            out.setdefault(p, []).extend([v] * k)
    return out


def runtimeExhaustivePoints() -> list:
    """(label, scheme, inputs) with every member of a small family and every
    input of the static bound (or every pair)."""
    out = []
    small = {'odd7': MF.odd(7), 'fr4x4': MF.friendly(4, 4), 'fr3x5': MF.friendly(3, 5),
             'kr5x3': MF.kred(5, 3), 'pm8x4': MF.pseudoMersenne(8, 4)}
    T = lambda f: IntType(0, (f.qMax - 1) ** 2)                        # noqa: E731

    def allT(sch):
        return _membersInputs(sch, lambda q: {'T': list(_rangeFor(sch, 'T', q))})

    def pairs(sch, q):
        A, B = [], []
        for a in _rangeFor(sch, 'A', q):
            for b in _rangeFor(sch, 'B', q):
                A.append(a)
                B.append(b)
        return A, B

    def allAB(sch):
        def d(q):
            A, B = pairs(sch, q)
            return {'A': A, 'B': B}
        return _membersInputs(sch, d)

    def allABW(ws):
        def gen(sch):
            def d(q):
                A, B = pairs(sch, q)
                return {'A': A * len(ws(q)), 'B': B * len(ws(q)), 'W': [w for w in ws(q) for _ in A]}
            return _membersInputs(sch, d)
        return gen

    def shoupAll(sch):
        def d(q):
            A, B, Bp = [], [], []
            for a in _rangeFor(sch, 'A', q):
                for b in range(q):
                    A.append(a)
                    B.append(b)
                    Bp.append(sch.companion(b, q))
            return {'A': A, 'B': B, 'Bp': Bp}
        return _membersInputs(sch, d)

    for lab in ('odd7', 'fr4x4', 'pm8x4'):
        f = small[lab]
        for kw in ({}, {'outputRange': 2}, {'s1': f.n - 1, 's2': f.n + 1}):
            out.append((f'rt-barrett {lab} {kw}', BarrettReduction(name='b', family=f, tIn=T(f), **kw), allT))
        out.append((f'rt-barrett {lab} signed', BarrettReduction(
            name='b', family=f, tIn=IntType(-(f.qMax - 1) ** 2 // 4, (f.qMax - 1) ** 2 // 4)), allT))
        for rb in (f.n, f.n + 1):
            out.append((f'rt-montgomery {lab} R=2^{rb}', MontgomeryReduction(name='m', family=f, tIn=T(f), rBits=rb), allT))
    for lab in ('fr4x4', 'fr3x5'):
        f = small[lab]
        for kw in ({'arrangement': 'greedy'}, {'arrangement': 'balanced'}, {'arrangement': 'equal'},
                   {'stepWidths': [2] * -(-f.n // 2)}, {'outputRange': 2}):
            out.append((f'rt-wlm {lab} {kw}', WordLevelMontgomery(name='w', family=f, tIn=T(f), **kw), allT))
        out.append((f'rt-wlm {lab} signed', WordLevelMontgomery(
            name='w', family=f, tIn=IntType(-(f.qMax - 1) ** 2, (f.qMax - 1) ** 2)), allT))
    f = small['odd7']
    for w in (3, 4):
        for arr in (None, 'balanced'):
            out.append((f'rt-wlm-generic odd7 w{w} {arr}', WordLevelMontgomery(
                name='w', family=f, tIn=T(f), w=w, variant='generic', arrangement=arr), allT))
    for st in (1, 2):
        f = small['kr5x3']
        out.append((f'rt-kred kr5x3 steps={st}', KRedReduction(name='k', family=f, tIn=T(f), steps=st), allT))
        out.append((f'rt-kred kr5x3 steps={st} signed', KRedReduction(
            name='k', family=f, tIn=IntType(-(f.qMax - 1) ** 2, (f.qMax - 1) ** 2), steps=st), allT))
    out.append(('rt-solinas pm8x4', SolinasReduction(name='s', family=small['pm8x4'], tIn=T(small['pm8x4'])), allT))
    # without relative bounds: every value of the static bound for every member (the interval-only path)
    for lab, cls, kw in (('odd7', BarrettReduction, {}), ('odd7', MontgomeryReduction, {}),
                         ('fr4x4', WordLevelMontgomery, {}), ('pm8x4', SolinasReduction, {})):
        f = small[lab]
        out.append((f'rt-{cls.family} {lab} static only', cls(name='x', family=f, tIn=T(f), tRel=False, **kw), allT))
    ex = lambda f: IntType(0, f.qMax - 1)                              # noqa: E731
    for lab, cls, a in (('odd7', BarrettReduction, {}), ('odd7', MontgomeryReduction, {}),
                        ('fr4x4', WordLevelMontgomery, {}), ('fr4x4', WordLevelMontgomery, {'arrangement': 'balanced'}),
                        ('kr5x3', KRedReduction, {}), ('pm8x4', SolinasReduction, {})):
        f = small[lab]
        out.append((f'rt-mm-{cls.family} {lab} {a} all a,b', ModularMultiplierScheme(
            name='mm', family=f, aIn=ex(f), bIn=ex(f), multiplier='behavioural', qBackend='behavioural',
            reduction=cls, reductionArgs=a), allAB))
    out.append(('rt-shoup odd7 all a, all b<q', ShoupModMult(name='s', family=small['odd7'], aIn=ex(small['odd7']),
                                                             multiplier='behavioural'), shoupAll))
    out.append(('rt-mm-wlm fr4x4 static only all a,b', ModularMultiplierScheme(
        name='mm', family=small['fr4x4'], aIn=ex(small['fr4x4']), bIn=ex(small['fr4x4']), multiplier='behavioural',
        qBackend='behavioural', reduction=WordLevelMontgomery, inRange=False), allAB))
    out.append(('rt-modadd odd7 sub lazy all', ModularAdderScheme(
        name='a', family=small['odd7'], aIn=IntType(0, 2 * 127 - 1), bIn=IntType(0, 2 * 127 - 1), subtract=True), allAB))
    for bt in ('CT', 'GS'):
        f = small['fr4x4']
        out.append((f'rt-butterfly-{bt} wlm fr4x4 all a,b, W in {{1, 2, q-1}}', ModularButterflyScheme(
            name='bu', family=f, butterflyType=bt, aIn=ex(f), bIn=ex(f), wIn=ex(f), multiplier='behavioural',
            qBackend='behavioural', reduction=WordLevelMontgomery), allABW(lambda q: [1, 2, q - 1])))
    # folded corrections, every input: fixed q and every member of a family
    for mode in ('never', 'always'):
        for q in (257, 509):
            out.append((f'mm-barrett q={q} fold={mode} all a,b', withFold(ModularMultiplierScheme(
                name='mm', q=q, aIn=IntType(0, q - 1), bIn=IntType(0, q - 1), multiplier='behavioural',
                reduction=BarrettReduction), mode), lambda s: allAB_(s)))
            out.append((f'modadd q={q} sub fold={mode} all', withFold(ModularAdderScheme(
                name='a', q=q, aIn=IntType(0, q - 1), bIn=IntType(0, q - 1), subtract=True), mode), lambda s: allAB_(s)))
        f = small['fr4x4']
        for bt in ('CT', 'GS'):
            out.append((f'rt-butterfly-{bt} wlm fr4x4 fold={mode} static, all a,b, W in {{1, q-1}}', withFold(
                ModularButterflyScheme(name='bu', family=f, butterflyType=bt, aIn=ex(f), bIn=ex(f), wIn=ex(f),
                                       multiplier='behavioural', qBackend='behavioural', reduction=WordLevelMontgomery,
                                       staticModulus=True), mode), allABW(lambda q: [1, q - 1])))
        out.append((f'rt-modadd odd7 sub fold={mode} all', withFold(ModularAdderScheme(
            name='a', family=small['odd7'], aIn=ex(small['odd7']), bIn=ex(small['odd7']), subtract=True), mode), allAB))
    # fixed q, every arrangement of the steps
    for q in (97, 193, 257, 769):
        n = q.bit_length()
        val = ((q - 1) & -(q - 1)).bit_length() - 1
        Tq = IntType(0, (q - 1) ** 2)
        allTq = lambda sch: {'T': list(range(sch.tIn.minValue, sch.tIn.maxValue + 1))}  # noqa: E731
        cfgs = [{'arrangement': 'greedy'}, {'arrangement': 'balanced'}, {'arrangement': 'equal'},
                {'stepWidths': [val, n - val]}, {'stepWidths': [1] * n}, {'qhBits': n - val + 1, 'arrangement': 'balanced'}]
        for v in ('flag', 'negate'):
            for kw in cfgs:
                out.append((f'wlm-{v} q={q} {kw}', WordLevelMontgomery(name='w', q=q, tIn=Tq, variant=v, **kw), allTq))
    return out


def delayCalibrationGate() -> list:
    """`Datapath.delayCost` against Vivado 2025.1 synthesis on the V80 part:
    22 chains of 8 bits from module inputs, 1..66 cycles, measured 200 SRL
    LUTs and 352 FFs; and the internal chains of a synthesised run-time WLM
    butterfly (`ntt_hw/experiments/condsub`): a 2- or 3-cycle internal delay is
    one SRL and one FF per bit, q delayed to three depths one tapped chain."""
    from operator_modeling.core.datapath import Datapath, Schedule
    fails = []
    lens = [1, 2, 3, 4, 5, 6, 8, 12, 16, 17, 18, 20, 24, 32, 33, 34, 35, 40, 48, 64, 65, 66]
    dp = Datapath('chains')
    for n in lens:
        dp.input(f'd{n}', IntType.unsigned(8))
    sch = Schedule({}, {}, {}, {}, [(f'd{n}_d{n}', f'd{n}', n) for n in lens], {}, 0, 0.0, {}, None, 1)
    if dp.delayCost(sch) != (200, 352):
        fails.append(('input chains', f'model {dp.delayCost(sch)}, measured (200, 352)'))
    dp = Datapath('internal')
    a = dp.input('a', IntType.unsigned(8))
    dp.heap('x', [dp.whole(a), dp.whole(a, shift=1)])
    sch = Schedule({}, {}, {}, {}, [('x_d2', 'x', 2), ('x_d3', 'x', 3), ('x_d20', 'x', 20)], {}, 0, 0.0, {}, None, 1)
    w = dp.width('x')
    # taps 2, 3, 20: segments of 2 (SRL + FF), 1 (FF) and 17 (SRL + FF) cycles
    if dp.delayCost(sch) != (w * 2, w * 3):
        fails.append(('internal tapped chain', f'model {dp.delayCost(sch)}, expected {(w * 2, w * 3)}'))
    return [2, fails]


def relativeCorrectionGate() -> list:
    """Run-time corrections need no more candidates than a fixed q would: the
    bounds relative to the trial's q, not the family's interval, choose them.
    (label, scheme, {correction wire: most candidates allowed})."""
    fr, od = MF.friendly(17, 45), MF.odd(52)
    a, o = IntType(0, fr.qMax - 1), IntType(0, od.qMax - 1)
    cases = [
        ('butterfly CT wlm fr17x45', ModularButterflyScheme(name='b', family=fr, aIn=a, bIn=a, reduction=WordLevelMontgomery),
         {'w3t_c': 2, 'x_c': 2, 'y_c': 2}),
        ('butterfly GS wlm fr17x45', ModularButterflyScheme(name='b', family=fr, butterflyType='GS', aIn=a, bIn=a,
                                                             reduction=WordLevelMontgomery), {'x_c': 2, 'w3t_c': 3}),
        ('butterfly CT barrett odd52', ModularButterflyScheme(name='b', family=od, aIn=o, bIn=o, reduction=BarrettReduction),
         {'br_c': 2, 'x_c': 2, 'y_c': 2}),
        ('mm montgomery odd52', ModularMultiplierScheme(name='m', family=od, aIn=o, bIn=o, reduction=MontgomeryReduction),
         {'mt_c': 2}),
        ('shoup odd52', ShoupModMult(name='s', family=od, aIn=o), {'sr_c': 2}),
        ('adder odd52', ModularAdderScheme(name='a', family=od, aIn=o, bIn=o), {'s_c': 2}),
    ]
    fails = []
    for label, sch, want in cases:
        with contextlib.redirect_stdout(io.StringIO()):
            dp = sch.datapath()
        got = {nd.name: len(dp.candidates(nd)) for nd in dp.nodes if nd.kind == 'qcorrect'}
        for w, k in want.items():
            if got.get(w, 0) > k:
                fails.append((label, f'{w}: {got.get(w)} candidates, at most {k} expected'))
    return [len(cases), fails]


# =============================================================================
# Gate 3: clocked
# =============================================================================

def clockedGate() -> int:
    cases = [
        BarrettReduction(name='b', q=generic(48), tIn=IntType(0, (generic(48) - 1) ** 2)),
        WordLevelMontgomery(name='w', q=GOLDILOCKS, tIn=IntType(0, (GOLDILOCKS - 1) ** 2), w=32),
        ModularMultiplierScheme(name='mm', q=generic(40), aIn=IntType(0, generic(40) - 1),
                                bIn=IntType(0, generic(40) - 1), multiplier='booth',
                                reduction=MontgomeryReduction),
        # run-time modulus: every trial its own q, so the modulus ports are pipelined with the data
        BarrettReduction(name='rb', family=MF.odd(48), tIn=IntType(0, (MF.odd(48).qMax - 1) ** 2)),
        ModularMultiplierScheme(name='rmm', family=MF.friendly(17, 45), aIn=IntType(0, MF.friendly(17, 45).qMax - 1),
                                bIn=IntType(0, MF.friendly(17, 45).qMax - 1), multiplier='booth', qBackend='booth',
                                reduction=WordLevelMontgomery),
        ModularButterflyScheme(name='rbu', family=MF.odd(30), aIn=IntType(0, MF.odd(30).qMax - 1),
                               bIn=IntType(0, MF.odd(30).qMax - 1), multiplier='behavioural',
                               qBackend='behavioural', reduction=BarrettReduction),
    ]
    count = 0
    for sch in cases:
        for req in (0, 1, 2, 3):
            lat = sch.latency(req)
            rng = random.Random(req)
            batches = [sch.sampleInputs(4, rng, corners=False) for _ in range(lat + 6)]
            sch.reset(req)
            outs = [sch.step(b) for b in batches]
            for k, o in enumerate(outs):
                if k < lat:
                    assert o is None, f'{sch.name}: output before the pipeline filled'
                else:
                    want = sch.datapath().run(batches[k - lat])
                    assert o == want, f'{sch.name}: clocked output {k} differs'
            count += 1
    return count


# =============================================================================
# Gate 4: RTL sample
# =============================================================================

def rtlPoints() -> list:
    '''(name, operator factory, emit kwargs) — a spread over families,
    multiplier backends, stage requests and frequency targets.'''
    q30, q52 = friendly(30, 16), friendly(52, 26)
    g28, g32, g48, g64 = generic(28), generic(32), generic(48), generic(64)
    p64, m61 = pseudoMersennePrime(64), (1 << 61) - 1
    s62 = solinasPrime(62)
    fq = lambda q: IntType(0, q - 1)                                    # noqa: E731
    T = lambda q: IntType(0, (q - 1) ** 2)                              # noqa: E731
    MM = lambda nm, q, **k: (lambda: ModularMultiplier(nm, ModularMultiplierScheme(name=nm, q=q, aIn=fq(q), bIn=k.pop('bIn', fq(q)), **k)))  # noqa: E731
    MC = lambda nm, q, w, **k: (lambda: ModularMultiplier(nm, ModularMultiplierScheme(name=nm, q=q, aIn=fq(q), constant=w, **k)))  # noqa: E731
    RD = lambda nm, cls, q, **k: (lambda: ModularReduction(nm, cls(name=nm, q=q, tIn=T(q), **k)))  # noqa: E731
    pts = [
        # reductions on their own
        ('rd_barrett_g64', RD('rd_barrett_g64', BarrettReduction, g64), {}),
        ('rd_barrett_g32_trunc', RD('rd_barrett_g32_trunc', BarrettReduction, g32, truncate=16), {}),
        ('rd_barrett_g48_lazy2', RD('rd_barrett_g48_lazy2', BarrettReduction, g48, outputRange=2), {}),
        ('rd_mont_g64', RD('rd_mont_g64', MontgomeryReduction, g64), {}),
        ('rd_mont_g28_p0', RD('rd_mont_g28_p0', MontgomeryReduction, g28), {'pipeline_stages': 0}),
        ('rd_wlm_flag_gold', RD('rd_wlm_flag_gold', WordLevelMontgomery, GOLDILOCKS, w=32), {}),
        ('rd_wlm_neg_q52', RD('rd_wlm_neg_q52', WordLevelMontgomery, q52, w=26, variant='negate'), {}),
        ('rd_wlm_gen_g48', RD('rd_wlm_gen_g48', WordLevelMontgomery, g48, w=16, variant='generic'), {}),
        ('rd_gold_limbs', lambda: ModularReduction('rd_gold_limbs', GoldilocksReduction(
            name='rd_gold_limbs', tIn=IntType(0, (GOLDILOCKS - 1) ** 2))), {}),
        ('rd_gold_s130', lambda: ModularReduction('rd_gold_s130', GoldilocksReduction(
            name='rd_gold_s130', tIn=IntType.signed(130), outputRange='exact')), {}),
        ('rd_mersenne61', RD('rd_mersenne61', MersenneReduction, m61), {}),
        ('rd_solinas_p64', RD('rd_solinas_p64', SolinasReduction, p64), {}),
        ('rd_fold_s62', RD('rd_fold_s62', FoldReduction, s62), {}),
        ('rd_table_g48', RD('rd_table_g48', TableLookupReduction, g48), {}),
        ('rd_custom_p64', RD('rd_custom_p64', ShiftAddReduction, p64), {}),
        # modular multipliers, variable operands, the paper's widths 30 and 52
        ('mm_barrett_dsp_q30', MM('mm_barrett_dsp_q30', q30, multiplier='dsp', reduction=BarrettReduction), {}),
        ('mm_mont_dsp_q30', MM('mm_mont_dsp_q30', q30, multiplier='dsp', reduction=MontgomeryReduction), {}),
        ('mm_wlm_dsp_q30', MM('mm_wlm_dsp_q30', q30, multiplier='dsp', reduction=WordLevelMontgomery,
                              reductionArgs={'w': 16}), {}),
        ('mm_barrett_dsp_q52', MM('mm_barrett_dsp_q52', q52, multiplier='dsp', reduction=BarrettReduction), {}),
        ('mm_mont_dsp_q52', MM('mm_mont_dsp_q52', q52, multiplier='dsp', reduction=MontgomeryReduction), {}),
        ('mm_wlm_dsp_q52', MM('mm_wlm_dsp_q52', q52, multiplier='dsp', reduction=WordLevelMontgomery,
                              reductionArgs={'w': 26}), {}),
        ('mm_barrett_dspall_q52', MM('mm_barrett_dspall_q52', q52, multiplier='dsp', reduction=BarrettReduction,
                                     constBackend='dsp'), {}),
        ('mm_mont_dspall_q30', MM('mm_mont_dspall_q30', q30, multiplier='dsp', reduction=MontgomeryReduction,
                                  constBackend='dsp'), {}),
        ('mm_wlm_gold_dsp', MM('mm_wlm_gold_dsp', GOLDILOCKS, multiplier='dsp', reduction=WordLevelMontgomery,
                               reductionArgs={'w': 32}), {}),
        ('mm_gold_limbs_dsp', MM('mm_gold_limbs_dsp', GOLDILOCKS, multiplier='dsp', reduction=GoldilocksReduction), {}),
        ('mm_barrett_booth_g32', MM('mm_barrett_booth_g32', g32, multiplier='booth', reduction=BarrettReduction), {}),
        ('mm_mont_booth_g28_p2', MM('mm_mont_booth_g28_p2', g28, multiplier='booth', reduction=MontgomeryReduction),
         {'pipeline_stages': 2}),
        ('mm_table_behav_g48', MM('mm_table_behav_g48', g48, multiplier='behavioural', reduction=TableLookupReduction), {}),
        ('mm_barrett_lazyin_g48', (lambda: ModularMultiplier('mm_barrett_lazyin_g48', ModularMultiplierScheme(
             name='mm_barrett_lazyin_g48', q=g48, aIn=IntType(0, 2 * g48 - 1), bIn=IntType(0, 2 * g48 - 1),
             multiplier='dsp', reduction=BarrettReduction, outputRange=2))), {}),
        # frequency in, cycles out
        ('mm_mont_dsp_q52_f400', MM('mm_mont_dsp_q52_f400', q52, multiplier='dsp', reduction=MontgomeryReduction,
                                    targetFmaxMhz=400), {}),
        ('mm_wlm_gold_f400', MM('mm_wlm_gold_f400', GOLDILOCKS, multiplier='dsp', reduction=WordLevelMontgomery,
                                reductionArgs={'w': 32}, targetFmaxMhz=400), {}),
        ('rd_barrett_g64_f400', (lambda: ModularReduction('rd_barrett_g64_f400', BarrettReduction(
            name='rd_barrett_g64_f400', q=g64, tIn=T(g64), targetFmaxMhz=400))), {}),
        ('mm_barrett_dsp_q30_f300', MM('mm_barrett_dsp_q30_f300', q30, multiplier='dsp',
                                       reduction=BarrettReduction, targetFmaxMhz=300), {}),
        # constant twiddles
        ('mc_shoup_g64', (lambda: ModularMultiplier('mc_shoup_g64', ShoupModMult(
            name='mc_shoup_g64', q=g64, aIn=fq(g64), constant=g64 // 3))), {}),
        ('mc_shoup_g64_f350', (lambda: ModularMultiplier('mc_shoup_g64_f350', ShoupModMult(
            name='mc_shoup_g64_f350', q=g64, aIn=fq(g64), constant=g64 // 3, targetFmaxMhz=350))), {}),
        ('mc_shoup_q30_lazy', (lambda: ModularMultiplier('mc_shoup_q30_lazy', ShoupModMult(
            name='mc_shoup_q30_lazy', q=q30, aIn=fq(q30), constant=q30 // 5, outputRange=2))), {}),
        ('mc_mont_q52', MC('mc_mont_q52', q52, q52 // 7, reduction=MontgomeryReduction), {}),
        ('mc_barrett_g40', MC('mc_barrett_g40', generic(40), generic(40) // 9, reduction=BarrettReduction), {}),
        ('mc_wlm_gold', MC('mc_wlm_gold', GOLDILOCKS, 12345678910111213, reduction=WordLevelMontgomery,
                           reductionArgs={'w': 32}), {}),
        ('mc_gold_limbs', MC('mc_gold_limbs', GOLDILOCKS, 2 ** 48 + 7, reduction=GoldilocksReduction), {}),
        ('mv_shoup_dsp_q52', (lambda: ModularMultiplier('mv_shoup_dsp_q52', ShoupModMult(
            name='mv_shoup_dsp_q52', q=q52, aIn=fq(q52), multiplier='dsp'))), {}),
        ('rd_kred_q30', RD('rd_kred_q30', KRedReduction, 998244353), {}),
        # butterfly units (Table VII's BU): one modular multiplication, an add, a subtract
        ('bu_ct_barrett_q30', (lambda: _bu('bu_ct_barrett_q30', q30, 'CT', BarrettReduction, {})), {}),
        ('bu_ct_mont_q30', (lambda: _bu('bu_ct_mont_q30', q30, 'CT', MontgomeryReduction, {})), {}),
        ('bu_ct_wlm_q30', (lambda: _bu('bu_ct_wlm_q30', q30, 'CT', WordLevelMontgomery, {'w': 16})), {}),
        ('bu_ct_barrett_q52', (lambda: _bu('bu_ct_barrett_q52', q52, 'CT', BarrettReduction, {})), {}),
        ('bu_ct_mont_q52', (lambda: _bu('bu_ct_mont_q52', q52, 'CT', MontgomeryReduction, {})), {}),
        ('bu_ct_wlm_q52', (lambda: _bu('bu_ct_wlm_q52', q52, 'CT', WordLevelMontgomery, {'w': 26})), {}),
        ('bu_gs_wlm_gold', (lambda: _bu('bu_gs_wlm_gold', GOLDILOCKS, 'GS', WordLevelMontgomery, {'w': 32})), {}),
        ('bu_ct_shoupless_const_q52', (lambda: _bu('bu_ct_shoupless_const_q52', q52, 'CT', MontgomeryReduction,
                                                   {}, constant=q52 // 11)), {}),
        # modular adders
        ('ma_add_g64', (lambda: _adder('ma_add_g64', g64, False)), {}),
        ('ma_sub_lazy_q52', (lambda: _adder('ma_sub_lazy_q52', q52, True, lazy=True)), {}),
        # the modulus at run time (RNS limbs): ports carry q's constants, every vector its own q
        ('rt_bu_ct_wlm_fr17x45', (lambda: _rtbu('rt_bu_ct_wlm_fr17x45', MF.friendly(17, 45), 'CT',
                                                WordLevelMontgomery, {})), {}),
        ('rt_bu_gs_wlm_fr17x45', (lambda: _rtbu('rt_bu_gs_wlm_fr17x45', MF.friendly(17, 45), 'GS',
                                                WordLevelMontgomery, {})), {}),
        ('rt_bu_ct_wlm_fr17x45_d10', (lambda: _rtbu('rt_bu_ct_wlm_fr17x45_d10', MF.friendly(17, 45), 'CT',
                                                    WordLevelMontgomery, {}, dspBudget=6, qDspBudget=1)), {}),
        ('rt_bu_ct_wlm_fr17x45_bal_f400', (lambda: _rtbu('rt_bu_ct_wlm_fr17x45_bal_f400', MF.friendly(17, 45), 'CT',
                                                         WordLevelMontgomery, {'arrangement': 'balanced'},
                                                         targetFmaxMhz=400)), {}),
        ('rt_bu_ct_barrett_odd52', (lambda: _rtbu('rt_bu_ct_barrett_odd52', MF.odd(52), 'CT', BarrettReduction, {})), {}),
        ('rt_mm_wlm_booth_fr17x45', (lambda: ModularMultiplier('rt_mm_wlm_booth_fr17x45', ModularMultiplierScheme(
            name='rt_mm_wlm_booth_fr17x45', family=MF.friendly(17, 45), aIn=IntType(0, MF.friendly(17, 45).qMax - 1),
            bIn=IntType(0, MF.friendly(17, 45).qMax - 1), multiplier='booth', qBackend='booth',
            reduction=WordLevelMontgomery))), {}),
        ('rt_mm_barrett_dsp_odd52', (lambda: ModularMultiplier('rt_mm_barrett_dsp_odd52', ModularMultiplierScheme(
            name='rt_mm_barrett_dsp_odd52', family=MF.odd(52), aIn=IntType(0, MF.odd(52).qMax - 1),
            bIn=IntType(0, MF.odd(52).qMax - 1), reduction=BarrettReduction))), {}),
        ('rt_mm_mont_dsp_odd30', (lambda: ModularMultiplier('rt_mm_mont_dsp_odd30', ModularMultiplierScheme(
            name='rt_mm_mont_dsp_odd30', family=MF.odd(30), aIn=IntType(0, MF.odd(30).qMax - 1),
            bIn=IntType(0, MF.odd(30).qMax - 1), reduction=MontgomeryReduction))), {}),
        ('rt_rd_wlm_gen_odd48', (lambda: ModularReduction('rt_rd_wlm_gen_odd48', WordLevelMontgomery(
            name='rt_rd_wlm_gen_odd48', family=MF.odd(48), tIn=IntType(0, (MF.odd(48).qMax - 1) ** 2), w=16,
            variant='generic'))), {}),
        ('rt_rd_kred_kr23x7', (lambda: ModularReduction('rt_rd_kred_kr23x7', KRedReduction(
            name='rt_rd_kred_kr23x7', family=MF.kred(23, 7), tIn=IntType(0, (MF.kred(23, 7).qMax - 1) ** 2),
            outputRange='exact'))), {}),
        ('rt_rd_solinas_pm61x12', (lambda: ModularReduction('rt_rd_solinas_pm61x12', SolinasReduction(
            name='rt_rd_solinas_pm61x12', family=MF.pseudoMersenne(61, 12),
            tIn=IntType(0, (MF.pseudoMersenne(61, 12).qMax - 1) ** 2)))), {}),
        ('rt_mv_shoup_odd52', (lambda: ModularMultiplier('rt_mv_shoup_odd52', ShoupModMult(
            name='rt_mv_shoup_odd52', family=MF.odd(52), aIn=IntType(0, MF.odd(52).qMax - 1)))), {}),
        ('rt_ma_sub_lazy_odd64', (lambda: _rtadder('rt_ma_sub_lazy_odd64', MF.odd(64))), {}),
        # a limb's modulus held for the whole job (no q delay lines), and folded corrections
        ('rt_bu_ct_wlm_fr17x45_st', (lambda: _rtbu('rt_bu_ct_wlm_fr17x45_st', MF.friendly(17, 45), 'CT',
                                                   WordLevelMontgomery, {'arrangement': 'balanced'},
                                                   targetFmaxMhz=400, staticModulus=True)), {}),
        ('rt_bu_ct_wlm_fr17x45_st_fold', (lambda: _fold(_rtbu('rt_bu_ct_wlm_fr17x45_st_fold', MF.friendly(17, 45), 'CT',
                                                              WordLevelMontgomery, {'arrangement': 'balanced'},
                                                              targetFmaxMhz=400, staticModulus=True))), {}),
        ('rt_bu_gs_wlm_fr17x45_st_fold', (lambda: _fold(_rtbu('rt_bu_gs_wlm_fr17x45_st_fold', MF.friendly(17, 45), 'GS',
                                                              WordLevelMontgomery, {}, staticModulus=True))), {}),
        ('rt_mm_barrett_odd52_fold', (lambda: _fold(ModularMultiplier('rt_mm_barrett_odd52_fold', ModularMultiplierScheme(
            name='rt_mm_barrett_odd52_fold', family=MF.odd(52), aIn=IntType(0, MF.odd(52).qMax - 1),
            bIn=IntType(0, MF.odd(52).qMax - 1), reduction=BarrettReduction)))), {}),
        ('mm_barrett_dsp_q52_fold', (lambda: _fold(MM('mm_barrett_dsp_q52_fold', q52, multiplier='dsp',
                                                      reduction=BarrettReduction)())), {}),
        ('bu_ct_mont_q30_fold', (lambda: _fold(_bu('bu_ct_mont_q30_fold', q30, 'CT', MontgomeryReduction, {}))), {}),
        # fixed q, step arrangements and q_H width
        ('rd_wlm_q62_balanced', RD('rd_wlm_q62_balanced', WordLevelMontgomery, friendly(62, 17),
                                   arrangement='balanced', variant='negate'), {}),
        ('rd_wlm_q62_qh50', RD('rd_wlm_q62_qh50', WordLevelMontgomery, friendly(62, 17), qhBits=50,
                               arrangement='greedy'), {}),
    ]
    return pts


def _fold(op):
    op.scheme.foldCorrections = 'always'
    return op


def _rtbu(name, fam, bt, cls, args, **kw):
    from operator_modeling.core.DatapathOperator import DatapathOperator
    r = IntType(0, fam.qMax - 1)
    return DatapathOperator(name, ModularButterflyScheme(
        name=name, family=fam, butterflyType=bt, aIn=r, bIn=r, multiplier='dsp', reduction=cls,
        reductionArgs=args, **kw))


def _rtadder(name, fam):
    from operator_modeling.core.DatapathOperator import DatapathOperator
    r = IntType(0, 2 * fam.qMax - 1)
    return DatapathOperator(name, ModularAdderScheme(name=name, family=fam, aIn=r, bIn=r, subtract=True,
                                                     outputRange=2))


def _bu(name, q, bt, cls, args, constant=None):
    from operator_modeling.core.DatapathOperator import DatapathOperator
    return DatapathOperator(name, ModularButterflyScheme(
        name=name, q=q, butterflyType=bt, aIn=IntType(0, q - 1), bIn=IntType(0, q - 1),
        constant=constant, multiplier='dsp', reduction=cls, reductionArgs=args))


def _adder(name, q, sub, lazy=False):
    from operator_modeling.core.DatapathOperator import DatapathOperator
    r = IntType(0, 2 * q - 1) if lazy else IntType(0, q - 1)
    return DatapathOperator(name, ModularAdderScheme(name=name, q=q, aIn=r, bIn=r, subtract=sub,
                                                     outputRange=2 if lazy else 'exact'))


def rtlGate(outDir: Path, testSize: int, only: list[str] | None, sim: bool, slots: list[str],
            backend: str, infoOnly: bool = False) -> dict:
    outDir.mkdir(parents=True, exist_ok=True)
    js = outDir / 'rtl_points.json'
    results = json.loads(js.read_text()) if js.is_file() else {}
    for name, make, kw in rtlPoints():
        if only and name not in only:
            continue
        t0 = time.time()
        op = make()
        try:
            if infoOnly:
                with contextlib.redirect_stdout(io.StringIO()):
                    st = kw.get('pipeline_stages', 1)
                    meta = {'pipeline_latency': op.latency(st)}
                    op.getOperatorInterface(name, st)
            else:
                with contextlib.redirect_stdout(io.StringIO()):
                    meta = op.emitRtl(name if backend == 'hw' else f'{name}_sim',
                                      outDir / (name if backend == 'hw' else f'{name}_sim'),
                                      test_size=testSize, seed=1, backend=backend, **kw)
            stages = kw.get('pipeline_stages', 1)
            results[name] = dict(status='generated', latency=meta['pipeline_latency'],
                                 lut=op.resources().lut, dsp=op.resources().dsp,
                                 ff=op.scheme.flipFlops(stages),
                                 criticalPathNs=round(op.criticalPathNs(stages), 3),
                                 seconds=round(time.time() - t0, 1),
                                 params=op.scheme.params(), stages=stages)
            print(f'  generated {name:<26} latency {meta["pipeline_latency"]:>2}  '
                  f'LUT~{results[name]["lut"]:>5} DSP {results[name]["dsp"]:>2}  '
                  f'path~{results[name]["criticalPathNs"]:.2f} ns')
        except Exception as e:                                      # noqa: BLE001
            results[name] = dict(status=f'generation failed: {type(e).__name__}: {e}')
            print(f'  FAILED   {name}: {e}')
    (outDir / 'rtl_points.json').write_text(json.dumps(results, indent=2, default=str))
    return results


# =============================================================================
# Report: RTL sample, simulations, synthesis -> HardwareRecords and a table
# =============================================================================

#: AutoNTT (Kumarathunga et al.), Table VII: BU = one modular multiplication,
#: an add and a subtract, Vitis HLS on Alveo U50/U280 at 250 MHz (the
#: comparison designs are NTTGen and OpenNTT, RTL).
AUTONTT_TABLE_VII = [
    (30, 'B', 'NTTGen', 1081, 920, 12, 14), (30, 'B', 'AutoNTT', 766, 403, 11, 10),
    (30, 'WLM', 'OpenNTT', 380, 449, 7, 14), (30, 'WLM', 'AutoNTT', 635, 429, 6, 10),
    (30, 'M', 'AutoNTT', 813, 434, 11, 10),
    (52, 'B', 'NTTGen', 1837, 1682, 17, 19), (52, 'B', 'AutoNTT', 1319, 1121, 17, 12),
    (52, 'WLM', 'OpenNTT', 1476, 1787, 14, 20), (52, 'WLM', 'AutoNTT', 1168, 891, 9, 11),
    (52, 'M', 'AutoNTT', 1491, 1075, 17, 12),
]


def report(runDir: Path, out: Path, db: Path) -> None:
    from operator_modeling.core.contracts import HardwareDatabase, HardwareRecord
    pts = json.loads((runDir / 'rtl_points.json').read_text())
    rows, recs = [], []
    if db.exists():
        db.unlink()
    hdb = HardwareDatabase(db)
    for name in sorted(pts):
        p = pts[name]
        d = runDir / name
        sim = d / 'sim_remote' / 'sim_stdout.log'
        verdict = '-'
        if sim.is_file():
            t = sim.read_text(errors='replace')
            import re as _re
            m = _re.search(r'PASS All\s+(\d+)', t)
            f = _re.search(r'FAILED:\s*(\d+) out of\s*(\d+)', t)
            verdict = f'PASS {m.group(1)}' if m else (f'FAIL {f.group(1)}/{f.group(2)}' if f else '?')
        rec = None
        if (d / 'synth_remote' / 'utilization.rpt').is_file():
            prm = p.get('params', {})
            rec = HardwareRecord.fromVivadoReports(
                d / 'synth_remote', name, stage='synth+opt (OOC)', operator=prm.get('family', ''),
                params={k: prm.get(k) for k in ('q', 'logq', 'multiplier', 'targetFmaxMhz')},
                latency=p.get('latency'),
                model={'lut': p.get('lut'), 'dsp': p.get('dsp'), 'ff': p.get('ff'),
                       'criticalPathNs': p.get('criticalPathNs'), 'latency': p.get('latency')})
            hdb.append(rec)
            recs.append(rec)
        rows.append((name, p, verdict, rec))
    L = ['# Modular multipliers: results', '',
         'Generated by `python runModMult.py --report <rtl dir>` from the RTL sample',
         '(`runModMult.py --rtl`), its xsim runs (`scripts/run_remote_sim.py`) and',
         'out-of-context synthesis + opt_design (`scripts/run_remote_synth.py --clock-ns`),',
         'Vivado 2025.1, xcv80-lsva4737-2MHP-e-S. Model columns are the',
         'framework\'s own prediction (`resources()`, `flipFlops()`, `criticalPathNs()`);',
         'measured ones come from the reports through `contracts.HardwareRecord`',
         '(records in `docs/data/modmult_hw.jsonl`).', '',
         '## Model gates (`python runModMult.py`)', '',
         MODEL_SUMMARY, '',
         '## RTL sample: generation and simulation', '',
         '| design | family | log q | multiplier | latency | LUT (model) | DSP (model) | FF (model) | path ns (model) | xsim |',
         '|---|---|---:|---|---:|---:|---:|---:|---:|---|']
    for name, p, verdict, _ in rows:
        prm = p.get('params', {})
        fam = prm.get('family', '')
        if prm.get('reduction'):
            fam += '/' + str(prm['reduction'].get('family'))
        L.append(f"| {name} | {fam} | {prm.get('logq', '')} | {prm.get('multiplier', '-')} | "
                 f"{p.get('latency')} | {p.get('lut')} | {p.get('dsp')} | {p.get('ff')} | "
                 f"{p.get('criticalPathNs')} | {verdict} |")
    L += ['', '## Synthesis (OOC, after opt_design)', '',
          '| design | clock ns | LUT | FF | DSP | LUT model/meas. | WNS ns | achieved MHz | path ns model vs meas. |',
          '|---|---:|---:|---:|---:|---:|---:|---:|---|']
    for rec in recs:
        c = rec.compare()
        L.append(f"| {rec.design} | {rec.clockNs} | {rec.lut} | {rec.ff} | {rec.dsp} | "
                 f"{(rec.model.get('lut') or 0) / rec.lut if rec.lut else 0:.2f} | {rec.wnsNs} | "
                 f"{rec.achievedFmaxMhz:.0f} | {rec.model.get('criticalPathNs')} vs {rec.achievedNs:.3f} |")
    L += ['', '## Context: AutoNTT Table VII (butterfly unit, HLS, 250 MHz)', '',
          '| width | reduction | design | LUT | FF | DSP | latency |', '|---:|---|---|---:|---:|---:|---:|']
    for w, r, dsg, lut, ff, dsp, lat in AUTONTT_TABLE_VII:
        L.append(f'| {w} | {r} | {dsg} | {lut} | {ff} | {dsp} | {lat} |')
    L += ['', 'The `bu_ct_*` rows above are the same unit built here (one modular multiplication on',
          'DSPs + modular add + subtract, exact outputs) on a Versal V80 instead of an UltraScale+',
          'U50/U280, so LUT and DSP counts are comparable in kind, not one to one (DSP58 vs DSP48E2).',
          'Their prime is an NTT-friendly prime of the same width (`k*2^16+1` for 30 bits,',
          '`k*2^26+1` for 52); the paper does not state its primes.', '']
    if NOTES:
        L += ['## Reading the numbers', '', NOTES, '']
    out.write_text('\n'.join(L) + '\n')
    print(f'wrote {out} and {db} ({len(recs)} hardware records)')


MODEL_SUMMARY = '(filled in by hand from the last full run; see the gate output)'
NOTES = ''


# =============================================================================
# Gate 5: randomized generation
# =============================================================================

def randomDesign(rng: random.Random, i: int):
    """One random (operator, emit kwargs, label) across reductions x multipliers
    x timing settings -- the space a spot check samples."""
    from operator_modeling.core.DatapathOperator import DatapathOperator
    bits = rng.randint(28, 64)
    fam = rng.choice(['barrett', 'montgomery', 'wlm', 'table', 'kred', 'fold', 'shoup', 'butterfly'])
    if fam in ('wlm', 'kred', 'butterfly'):
        w = rng.randint(max(8, bits // 3), bits - 12)
        q = None
        while q is None:
            try:
                q = friendly(bits, w, rng.randint(0, 3))
            except ValueError:
                w -= 1
    elif fam == 'fold':
        q = solinasPrime(bits)
    else:
        q = generic(bits, rng.randint(0, 50))
    red = {'barrett': BarrettReduction, 'montgomery': MontgomeryReduction, 'wlm': WordLevelMontgomery,
           'table': TableLookupReduction, 'kred': KRedReduction, 'fold': FoldReduction,
           'shoup': BarrettReduction, 'butterfly': MontgomeryReduction}[fam]
    args = {'w': wordFor(q)} if fam == 'wlm' else {}
    mult = rng.choice(['dsp', 'booth', 'behavioural', 'const'])
    timing = rng.choice([('stages', 0), ('stages', 1), ('stages', 2), ('stages', 3),
                         ('target', 250), ('target', 300), ('target', 350)])
    target = timing[1] if timing[0] == 'target' else None
    kw = {'pipeline_stages': timing[1]} if timing[0] == 'stages' else {}
    if mult == 'dsp' and timing[0] == 'stages' and timing[1] != 1:
        kw = {}     # a DSP block picks its own depth; only the LUT nodes take a count
    outR = rng.choice(['exact', 'exact', 2])
    name = f'rnd{i}_{fam}_{mult}_q{bits}'
    fq = IntType(0, q - 1)
    if fam == 'shoup':
        sch = ShoupModMult(name=name, q=q, aIn=fq, constant=rng.randrange(1, q) if mult == 'const' else None,
                           multiplier='dsp' if mult == 'const' else mult, outputRange=outR,
                           targetFmaxMhz=target)
        op = ModularMultiplier(name, sch)
    elif fam == 'butterfly':
        sch = ModularButterflyScheme(name=name, q=q, butterflyType=rng.choice(['CT', 'GS']), aIn=fq, bIn=fq,
                                     constant=rng.randrange(1, q) if mult == 'const' else None,
                                     multiplier='dsp' if mult == 'const' else mult, reduction=red,
                                     outputRange=outR, targetFmaxMhz=target)
        op = DatapathOperator(name, sch)
    else:
        c = dict(constant=rng.randrange(1, q)) if mult == 'const' else dict(bIn=fq)
        sch = ModularMultiplierScheme(name=name, q=q, aIn=fq, multiplier='dsp' if mult == 'const' else mult,
                                      reduction=red, reductionArgs=args, outputRange=outR,
                                      targetFmaxMhz=target, **c)
        op = ModularMultiplier(name, sch)
    return op, kw, f'{name} {timing}'


def randomRuntimeDesign(rng: random.Random, i: int):
    """One random design whose modulus arrives at run time: family kind x
    reduction x multiplier and q backends x DSP budgets x timing."""
    from operator_modeling.core.DatapathOperator import DatapathOperator
    kind = rng.choice(['odd', 'friendly', 'kred', 'pm'])
    if kind == 'odd':
        fam = MF.odd(rng.randint(28, 64))
        red, args = rng.choice([(BarrettReduction, {}), (MontgomeryReduction, {}),
                                (WordLevelMontgomery, {'w': rng.choice([16, 24, 32]), 'variant': 'generic'})])
    elif kind == 'friendly':
        v = rng.randint(10, 32)
        fam = MF.friendly(v, rng.randint(12, 64 - v))
        red, args = rng.choice([(WordLevelMontgomery, {'arrangement': rng.choice(['greedy', 'balanced', 'equal'])}),
                                (BarrettReduction, {}), (MontgomeryReduction, {})])
    elif kind == 'kred':
        fam = MF.kred(rng.randint(8, 26), rng.randint(3, 8))
        red, args = KRedReduction, {}
    else:
        n = rng.randint(28, 64)
        fam = MF.pseudoMersenne(n, rng.randint(4, n // 3))
        red, args = SolinasReduction, {}
    mult = rng.choice(['dsp', 'booth', 'behavioural'])
    qb = rng.choice(['dsp', 'booth', 'behavioural'])
    budget = rng.choice([None, None, 1, 2, 4])
    timing = rng.choice([('stages', 0), ('stages', 1), ('stages', 2), ('stages', 3),
                         ('target', 250), ('target', 300), ('target', 350)])
    target = timing[1] if timing[0] == 'target' else None
    kw = {'pipeline_stages': timing[1]} if timing[0] == 'stages' else {}
    if 'dsp' in (mult, qb) and timing[0] == 'stages' and timing[1] != 1:
        kw = {}
    outR = rng.choice(['exact', 'exact', 2])
    shape = rng.choice(['mm', 'mm', 'butterfly', 'reduction', 'shoup', 'adder'])
    name = f'rrt{i}_{shape}_{red.family}_{fam.kind}{fam.n}_{mult}_{qb}'
    fq = IntType(0, fam.qMax - 1)
    common = dict(family=fam, targetFmaxMhz=target, staticModulus=rng.random() < 0.5)
    fold = rng.choice(['never', 'auto', 'always'])
    if shape == 'reduction':
        sch = red(name=name, tIn=IntType(0, (fam.qMax - 1) ** 2), outputRange=outR, qBackend=qb, qDspBudget=budget,
                  **common, **args)
        op = ModularReduction(name, sch)
    elif shape == 'shoup':
        op = ModularMultiplier(name, ShoupModMult(name=name, aIn=fq, multiplier=mult, qBackend=qb,
                                                  qDspBudget=budget, outputRange=outR, **common))
    elif shape == 'adder':
        r = IntType(0, 2 * fam.qMax - 1)
        op = DatapathOperator(name, ModularAdderScheme(name=name, aIn=r, bIn=r, subtract=rng.random() < 0.5,
                                                       outputRange=outR, **common))
    elif shape == 'butterfly':
        op = DatapathOperator(name, ModularButterflyScheme(
            name=name, butterflyType=rng.choice(['CT', 'GS']), aIn=fq, bIn=fq, multiplier=mult, reduction=red,
            reductionArgs=args, outputRange=outR, qBackend=qb, qDspBudget=budget, **common))
    else:
        op = ModularMultiplier(name, ModularMultiplierScheme(
            name=name, aIn=fq, bIn=fq, multiplier=mult, reduction=red, reductionArgs=args, outputRange=outR,
            qBackend=qb, qDspBudget=budget, **common))
    op.scheme.foldCorrections = fold
    return op, kw, f'{name} {timing} budget={budget} fold={fold} static={common["staticModulus"]}'


def randomRuntimeGate(n: int, nStruct: int, seed: int) -> tuple[int, int, int, list]:
    """Model structure on many random run-time designs, and RTL generation
    (model latency and units asserted by the generator) on some of them."""
    import tempfile
    import shutil
    rng = random.Random(seed)
    fails, heaps = [], 0
    for i in range(nStruct):
        try:
            op, _, label = randomRuntimeDesign(rng, i)
            with contextlib.redirect_stdout(io.StringIO()):
                dp = op.scheme.datapath()
                ins = op.scheme.sampleInputs(64, random.Random(i))
                errs = op.scheme.checkReference(ins)
            heaps += sum(1 for nd in dp.nodes if nd.kind == 'heap')
            bad = heapDisagreements(dp) + errs
            if bad:
                fails.append((label, '; '.join(map(str, bad[:3]))))
        except ValueError as e:
            if 'unreachable' not in str(e) and 'does not shrink' not in str(e):
                fails.append((label if 'label' in dir() else f'#{i}', f'{type(e).__name__}: {e}'))
    ok = refused = 0
    tmp = Path(tempfile.mkdtemp(prefix='runModMult_rrt_'))
    try:
        for i in range(n):
            op, kw, label = randomRuntimeDesign(rng, nStruct + i)
            try:
                with contextlib.redirect_stdout(io.StringIO()):
                    op.emitRtl(op.name, tmp / op.name, test_size=8, seed=i, **kw)
                ok += 1
            except ValueError as e:
                if 'unreachable' in str(e) or 'does not shrink' in str(e):
                    refused += 1
                else:
                    fails.append((label, f'{type(e).__name__}: {e}'))
            except Exception as e:                              # noqa: BLE001
                fails.append((label, f'{type(e).__name__}: {e}'))
            shutil.rmtree(tmp / op.name, ignore_errors=True)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    return ok, refused, heaps, fails


def heapDisagreements(dp) -> list[str]:
    """Every compressor heap whose model unit count differs from the layer count
    the generator will build (`countCompressionLayers`): the check
    `Datapath_RTL_gen` makes, without generating."""
    from rtl_gen.heap_terms import countCompressionLayers
    bad = []
    for node in dp.nodes:
        if node.kind == 'heap' and dp.heapStrategy(node) == 'compressor':
            _, _, heights, wbh = dp._heapPlan(node)
            n, _, _ = countCompressionLayers(heights, wbh)
            if n != len(dp.units(node)):
                bad.append(f'{node.name}: model {len(dp.units(node))} units, generator {n} layers')
    return bad


def randomStructureGate(n: int, seed: int) -> tuple[int, int, list]:
    """Many random designs, model only: heap analyses must agree everywhere."""
    rng = random.Random(seed)
    heaps, fails = 0, []
    for i in range(n):
        op, _, label = randomDesign(rng, i)
        try:
            dp = op.scheme.datapath()
        except ValueError as e:
            fails.append((label, f'{e}'))
            continue
        heaps += sum(1 for nd in dp.nodes if nd.kind == 'heap')
        bad = heapDisagreements(dp)
        if bad:
            fails.append((label, '; '.join(bad)))
    return n, heaps, fails


def randomGate(n: int, seed: int) -> tuple[int, int, list]:
    import tempfile
    import shutil
    rng = random.Random(seed)
    ok = refused = 0
    fails = []
    tmp = Path(tempfile.mkdtemp(prefix='runModMult_rnd_'))
    try:
        for i in range(n):
            op, kw, label = randomDesign(rng, i)
            try:
                with contextlib.redirect_stdout(io.StringIO()):
                    op.emitRtl(op.name, tmp / op.name, test_size=8, seed=i, **kw)
                ok += 1
            except ValueError as e:
                if 'unreachable' in str(e):
                    refused += 1          # a target the hardware cannot reach is refused by design
                else:
                    fails.append((label, f'{type(e).__name__}: {e}'))
            except Exception as e:                              # noqa: BLE001
                fails.append((label, f'{type(e).__name__}: {e}'))
            shutil.rmtree(tmp / op.name, ignore_errors=True)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    return ok, refused, fails


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--quick', action='store_true')
    ap.add_argument('--vectors', type=int, default=None, help='vectors per sweep point')
    ap.add_argument('--skip-model', action='store_true', help='only the RTL gate')
    ap.add_argument('--rtl', default=None, help='generate the RTL sample into this directory')
    ap.add_argument('--only', default=None, help='comma list of RTL point names')
    ap.add_argument('--test-size', type=int, default=300)
    ap.add_argument('--backend', default='hw', choices=('hw', 'sim'))
    ap.add_argument('--list', action='store_true', help='list the RTL points and exit')
    ap.add_argument('--random', type=int, default=None, help='gate 5: random designs to generate (default 40, quick 8)')
    ap.add_argument('--random-seed', type=int, default=11)
    ap.add_argument('--info-only', action='store_true', help='with --rtl: record the model numbers, emit nothing')
    ap.add_argument('--report', default=None, help='write docs/MODMULT_RESULTS.md from this RTL directory')
    ap.add_argument('--model-summary', default=None, help='text for the model-gate section of the report')
    ap.add_argument('--notes', default=None, help='text for the closing section of the report')
    args = ap.parse_args()
    if args.report:
        global MODEL_SUMMARY, NOTES
        if args.notes:
            NOTES = Path(args.notes).read_text().strip()
        if args.model_summary:
            MODEL_SUMMARY = Path(args.model_summary).read_text().strip()
        report(Path(args.report), ROOT / 'docs' / 'MODMULT_RESULTS.md', ROOT / 'docs' / 'data' / 'modmult_hw.jsonl')
        return 0
    if args.list:
        for name, _, kw in rtlPoints():
            print(name, kw)
        return 0
    vectors = args.vectors or (300 if args.quick else 2000)
    ok = True
    if not args.skip_model:
        t0 = time.time()
        mods = moduli(args.quick)
        nq = sum(len(v) for v in mods.values())
        red = reductionPoints(mods, args.quick)
        mul = multiplierPoints(mods, args.quick)
        d1, c1, f1 = runPoints(red, vectors, 1)
        d2, c2, f2 = runPoints(mul, vectors, 2)
        print(f'gate 1 sweep: {nq} moduli, {d1} reduction points + {d2} multiplier/adder points, '
              f'{c1 + c2} vectors against the big-integer reference, {len(f1) + len(f2)} failing '
              f'({time.time() - t0:.0f}s)')
        for label, e in f1 + f2:
            print(f'  FAIL {label}: {e}')
        ok &= not (f1 or f2)
        t0 = time.time()
        fams = runtimeFamilies(args.quick)
        rred = runtimeReductionPoints(args.quick) + wlmArrangementPoints(mods)
        rmul = runtimeMultiplierPoints(args.quick)
        d3, c3, f3 = runPoints(rred, vectors, 3)
        d4, c4, f4 = runPoints(rmul, vectors, 4)
        print(f'gate 1r sweep, run-time modulus: {sum(len(v) for v in fams.values())} families, {d3} reduction '
              f'points (WLM arrangements included) + {d4} multiplier/adder/butterfly/Shoup points, {c3 + c4} '
              f'vectors, each its own q, {len(f3) + len(f4)} failing ({time.time() - t0:.0f}s)')
        for label, e in f3 + f4:
            print(f'  FAIL {label}: {e}')
        ok &= not (f3 or f4)
        t0 = time.time()
        total, fails = 0, []
        for label, sch, gen in exhaustivePoints():
            try:
                ins = gen(sch)
                e = sch.checkReference(ins)
                total += len(next(iter(ins.values())))
                if e:
                    fails.append((label, e[:2]))
            except (ModelError, AssertionError, ValueError) as e:
                fails.append((label, [f'{type(e).__name__}: {e}']))
        for q in (257, 509):
            n, e = shoupConstExhaustive(q, 8 if args.quick else 24)
            total += n
            fails += e
        print(f'gate 2 exhaustive: {len(exhaustivePoints())} schemes + constant sweeps, {total} inputs, '
              f'{len(fails)} failing ({time.time() - t0:.0f}s)')
        for label, e in fails:
            print(f'  FAIL {label}: {e}')
        ok &= not fails
        t0 = time.time()
        total, fails = 0, []
        rex = runtimeExhaustivePoints()
        for label, sch, gen in rex:
            try:
                ins = gen(sch)
                e = sch.checkReference(ins)
                total += len(next(iter(ins.values())))
                if e:
                    fails.append((label, e[:2]))
            except (ModelError, AssertionError, ValueError) as e:
                fails.append((label, [f'{type(e).__name__}: {e}']))
        print(f'gate 2r exhaustive, run-time modulus: {len(rex)} schemes, every member of small families x every '
              f'input (and WLM step arrangements at fixed q), {total} inputs, {len(fails)} failing '
              f'({time.time() - t0:.0f}s)')
        for label, e in fails:
            print(f'  FAIL {label}: {e}')
        ok &= not fails
        ndel, delFails = delayCalibrationGate()
        print(f'gate 2d delay lines: {ndel} calibration sets (SRL LUTs and FFs as synthesis maps register chains), '
              f'{len(delFails)} failing')
        for label, e in delFails:
            print(f'  FAIL {label}: {e}')
        ok &= not delFails
        nrel, relFails = relativeCorrectionGate()
        print(f'gate 2q relative corrections: {nrel} run-time designs need no more correction candidates than a '
              f'fixed q, {len(relFails)} failing')
        for label, e in relFails:
            print(f'  FAIL {label}: {e}')
        ok &= not relFails
        t0 = time.time()
        with contextlib.redirect_stdout(io.StringIO()):
            n = clockedGate()
        print(f'gate 3 clocked: {n} (scheme, stage request) pairs stream compute() delayed by latency() '
              f'({time.time() - t0:.0f}s)')
        t0 = time.time()
        ns = 100 if args.quick else 600
        nn, nh, sfails = randomStructureGate(ns, args.random_seed + 1)
        print(f'gate 5a random structure: {nn} random designs, {nh} heaps, model units == generator '
              f'layers on all but {len(sfails)} ({time.time() - t0:.0f}s)')
        for label, e in sfails[:10]:
            print(f'  FAIL {label}: {e}')
        ok &= not sfails
        t0 = time.time()
        nr = args.random if args.random is not None else (8 if args.quick else 40)
        if nr:
            good, refused, rfails = randomGate(nr, args.random_seed)
            print(f'gate 5b random generation: {nr} random designs (reduction x multiplier x timing), '
                  f'{good} generated with the model\'s latency and units, {refused} unreachable targets '
                  f'refused, {len(rfails)} failing ({time.time() - t0:.0f}s)')
            for label, e in rfails:
                print(f'  FAIL {label}: {e}')
            ok &= not rfails
        t0 = time.time()
        nrr = 6 if args.quick else 30
        good, refused, nh, rfails = randomRuntimeGate(nrr, 60 if args.quick else 300, args.random_seed + 2)
        print(f'gate 5c random run-time designs: {60 if args.quick else 300} checked (structure + 64 vectors '
              f'each, {nh} heaps), {nrr} generated: {good} with the model\'s latency and units, {refused} '
              f'refused, {len(rfails)} failing ({time.time() - t0:.0f}s)')
        for label, e in rfails[:12]:
            print(f'  FAIL {label}: {e}')
        ok &= not rfails
    if args.rtl:
        only = args.only.split(',') if args.only else None
        res = rtlGate(Path(args.rtl), args.test_size, only, False, [], args.backend, args.info_only)
        if only:
            res = {k: v for k, v in res.items() if k in only}
        bad = [k for k, v in res.items() if v['status'] != 'generated']
        print(f'gate 4 rtl: {len(res) - len(bad)} of {len(res)} designs generated, latency asserted, '
              f'contract checked; simulate with scripts/run_remote_sim.py --run-dir {args.rtl}/<name>')
        ok &= not bad
    print('all gates passed' if ok else 'SOME GATES FAILED')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
