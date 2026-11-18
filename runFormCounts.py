'''The closed forms of FormCounts.py against MultiStepScheme's enumeration (multipliers, twiddle words, transpose
words, BRAM36 / URAM tiles), over the TP-NTT rows of ntt_hw/experiments/fourstep/ms/rows.py and a sweep.

    python runFormCounts.py [--rows] [--sweep] [--quick]
'''
from __future__ import annotations

import argparse
import contextlib
import io
import itertools
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from operator_modeling.ntt.multistep.FormCounts import formCounts
from operator_modeling.ntt.multistep.MultiStepScheme import MultiStepScheme, memoryTiles


def quiet(fn):
    with contextlib.redirect_stdout(io.StringIO()):
        return fn()


def modelCounts(s: MultiStepScheme, share: bool = False) -> dict:
    '''The same quantities, enumerated by the scheme (and UNR's sub-NTT schemes).'''
    d = s.d
    gen_bu = 0
    classes = []
    for t, sub in enumerate(s.subs):
        sub.slotClasses()
        cnt = sum(1 for st in range(sub.L) for k in range(len(sub.slots[st])) if sub.slotConstant(st, k) != 1)
        gen_bu += cnt * s.subCopies(t)
        classes.append(len({sub.classOf[x] for x in sub.classOf}) if not s.folded(t) else None)
    inter = gens = invst = 0
    words = 0
    bram = uram = lutrom = 0
    M, D = len(s.moduli), len(s.dirs)
    for t, st in s.stages.items():
        c = s.stageCost(st, st['source'])
        if t == d:
            invst += c['mults']
        else:
            inter += c['mults']
        gens += c['gens']
        if st['source'] == 'tree':
            tabs = s.treeTables(t, values=False)
            users = lambda tb: len(tb['groups'])
        else:
            tabs = s.tablesOf(st, st['source'], values=False)
            users = lambda tb: len(tb['lanes'])
        for tb in tabs:
            words += tb['depth'] // (M * D)
            copies = -(-users(tb) // s.tableShare) if share else 1
            if tb['depth'] <= 4 * s.romStyleMaxDepth:
                lutrom += copies
                continue
            r = memoryTiles(tb['depth'], s.W, s.memStyle, s._uramMinDepth)
            bram += copies * r['bram36']
            uram += copies * r['uram']
    for t, pt in getattr(s, 'portTables', {}).items():
        for tb in pt['tables']:
            words += tb['depth'] // (M * (1 if tb.get('dir') else D))     # folded_gs: a table per direction
            if tb['depth'] <= 4 * s.romStyleMaxDepth:
                lutrom += 1
                continue
            r = memoryTiles(tb['depth'], s.W, s.memStyle, s._uramMinDepth)
            bram += r['bram36']
            uram += r['uram']
    tw = 0
    for st in s.plan.transposes():
        c = s.transposeCost(st)
        tw += c['words'] // (2 if s.transposeKind == 'mbm' else 1)
        bram += c['bram36']
        uram += c['uram']
    twist = sum(sub.lanes * s.subCopies(t) for t, sub in enumerate(s.subs)
                if getattr(sub, 'twistMultiplier', None) is not None)
    return dict(butterflies=gen_bu, interPass=inter, invTwist=twist + invst, generators=gens,
                total=gen_bu + inter + twist + invst + gens, words=words, transposeWords=tw,
                bram36=bram, uram=uram, lutRomTables=lutrom, subClasses=classes)


def compare(s: MultiStepScheme, form: str) -> list[str]:
    srcs = [s.stages[t]['source'] for t in range(1, s.d)] if form == 'twist' else None
    cf = formCounts(s.N, s.sizes, s.P, len(s.moduli), s.dirs, s.negacyclic, form, srcs, s.W)
    mc = quiet(lambda: modelCounts(s))
    bad = []
    for k in ('butterflies', 'interPass', 'invTwist', 'generators', 'total'):
        if cf['multipliers'][k] != mc[k]:
            bad.append(f'{k} closed {cf["multipliers"][k]} model {mc[k]}')
    if cf['twiddleWordsPerPrimePerDir'] != mc['words']:
        bad.append(f'twiddle words closed {cf["twiddleWordsPerPrimePerDir"]} model {mc["words"]}')
    if cf['transposeWords'] != mc['transposeWords']:
        bad.append(f'transpose words closed {cf["transposeWords"]} model {mc["transposeWords"]}')
    for k in ('bram36', 'uram', 'lutRomTables'):
        if cf['tiles'][k] != mc[k]:
            bad.append(f'{k} closed {cf["tiles"][k]} model {mc[k]}')
    for t, (pc, cl) in enumerate(zip(cf['passes'], mc['subClasses'])):
        if cl is not None and pc['subClasses'] != cl:
            bad.append(f'pass {t} sub-NTT twiddle classes closed {pc["subClasses"]} model {cl}')
    return bad, cf, mc


def primes(bits, logOrder, k, seed0=0):
    from operator_modeling.modmult.primes import nttFriendlyPrime
    out, sd = [], seed0
    while len(out) < k:
        q = nttFriendlyPrime(bits, logOrder + 1, seed=sd)
        if q not in out:
            out.append(q)
        sd += 1
    return out


def rows() -> int:
    sys.path.insert(0, 'work/fourstep/ms')
    from rows import row_scheme
    fails = 0
    for row in ('MS_N10_q32_P32', 'MS_N12_q32_P64', 'MS_N12_q60_P32', 'MS_N14_q60_P32', 'MS_N16_q60_P32'):
        for form in ('twist', 'folded', 'folded_gs'):
            s = quiet(lambda: row_scheme(row, form=form))
            bad, cf, mc = compare(s, form)
            fails += bool(bad)
            m = cf['multipliers']
            print(f"  {row:<16} {form:<9} multipliers {m['total']:5d} (bu {m['butterflies']}, inter {m['interPass']}, "
                  f"inv {m['invTwist']}, gen {m['generators']}), twiddle words/prime/dir {cf['twiddleWordsPerPrimePerDir']}, "
                  f"transpose words {cf['transposeWords']}, BRAM {cf['tiles']['bram36']} URAM {cf['tiles']['uram']}: "
                  f"{'MATCH' if not bad else 'MISMATCH ' + '; '.join(bad)}", flush=True)
    return fails


def sweep(quick=False) -> int:
    rng = random.Random(3)
    cfgs = []
    for N in (64, 256, 1024, 4096):
        m = N.bit_length() - 1
        for P in (4, 8, 16, 32, 64):
            p = P.bit_length() - 1
            if P > N:
                continue
            for d in (2, 3, 4):
                for a in itertools.product(range(2, p + 1), repeat=d):
                    if sum(a) == m:
                        cfgs.append((N, [1 << x for x in a], P))
    rng.shuffle(cfgs)
    cfgs = cfgs[:40 if quick else 160]
    fails = n = 0
    dirsets = ['forward', 'inverse', 'both']
    for i, (N, sizes, P) in enumerate(cfgs):
        nwc = i % 4 != 3
        dset = dirsets[i % 3]
        M = 1 + (i * 5) % 8
        form = 'folded' if i % 5 == 4 else 'twist'
        if i % 5 == 2:                  # folded_gs: the unified CT/GS design, both directions only
            form, dset = 'folded_gs', 'both'
        src = ['rom', 'otf', 'tree'][i % 3]
        order = 2 * N if nwc else N
        qs = primes(30, order.bit_length() - 1, M, seed0=i)
        try:
            s = quiet(lambda: MultiStepScheme(f's{i}', N, sizes, P, moduli=qs, negacyclic=nwc, direction=dset,
                                              twiddleSource=src, form=form))
        except Exception as e:      # noqa: BLE001
            print(f'  skip {N} {sizes} P{P}: {type(e).__name__}: {e}')
            continue
        bad, cf, mc = compare(s, form)
        n += 1
        fails += bool(bad)
        if bad:
            print(f"  N={N} {sizes} P={P} M={M} {dset} {'nega' if nwc else 'cyc'} {form} {src}: MISMATCH {'; '.join(bad)}",
                  flush=True)
    print(f'  sweep: {n - fails} of {n} configurations match exactly')
    return fails


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--rows', action='store_true')
    ap.add_argument('--sweep', action='store_true')
    ap.add_argument('--quick', action='store_true')
    a = ap.parse_args()
    f = 0
    if a.rows or not a.sweep:
        f += rows()
    if a.sweep or not a.rows:
        f += sweep(a.quick)
    print('ALL MATCH' if not f else f'{f} MISMATCH')
    sys.exit(1 if f else 0)
