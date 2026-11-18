#!/usr/bin/env python3
"""build_modmult.py — generate a modular multiplier or reduction's RTL from the model.

One run directory per design: top module, compressors and multiplier
sub-modules, XDC (compressor placement and, with a target, the clock), a
self-checking testbench, hex test vectors whose goldens come from the model and
are checked against plain big-integer arithmetic before they are written,
`manifest.json` (schedule, estimate) and `rtl_contract.json`.

    work/<scenario>/<name>/
      RTL_generated/  <name>.sv  <name>_<node>_cmp.sv  <name>_<node>_*.sv  <name>_tb.sv
      xdc_generated/  <name>_<node>_cmp.xdc  [<name>_clock.xdc]
      testvectors/    A.txt B.txt P.txt   (or T.txt R.txt for a reduction)
      manifest.json  rtl_contract.json  spec.json

Examples (run from the project root)::

    # 52-bit NTT-friendly prime, A*B on DSPs, word-level Montgomery with w=26
    python scripts/build_modmult.py --scenario mm --q ntt:52:26 --reduction wlm --w 26 \\
        --multiplier dsp --remote-sim

    # Goldilocks twiddle multiplication by a constant, Shoup, LUTs only
    python scripts/build_modmult.py --scenario mm --q goldilocks --shoup --constant 12345 \\
        --output-range 2

    # Barrett reduction of a 128-bit value alone, at a 400 MHz target
    python scripts/build_modmult.py --scenario red --q prime:64 --reduction barrett \\
        --reduce-only --t-bound u128 --target-fmax 400

Modulus spellings: an integer; `prime:<bits>[:seed]` (a generic prime);
`ntt:<bits>:<w>[:seed]` (k*2^w+1); `mersenne:<n>`; `pseudo:<bits>` (2^n - c);
`solinas:<bits>` (2^n - 2^k +/- 1); `goldilocks`.
Bound spellings as in build_cmult.py: `u24`, `s66`, `[lo,hi]`; and `q` / `2q`
for [0, q-1] / [0, 2q-1].
"""
from __future__ import annotations

import argparse
import contextlib
import io
import json
import re
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from operator_modeling.core.IntType import IntType  # noqa: E402
from operator_modeling.core.DatapathOperator import DatapathOperator  # noqa: E402
from operator_modeling.modmult import primes  # noqa: E402
from operator_modeling.modmult.ModAddScheme import ModularAdderScheme  # noqa: E402
from operator_modeling.modmult.ModMult import ModularMultiplier, ModularReduction  # noqa: E402
from operator_modeling.modmult.ModMultScheme import ModularMultiplierScheme, ShoupModMult  # noqa: E402
from operator_modeling.modmult import ReductionScheme as RS  # noqa: E402

REDUCTIONS = {
    'barrett': RS.BarrettReduction, 'montgomery': RS.MontgomeryReduction,
    'wlm': RS.WordLevelMontgomery, 'fold': RS.FoldReduction, 'mersenne': RS.MersenneReduction,
    'solinas': RS.SolinasReduction, 'goldilocks': RS.GoldilocksReduction,
    'table': RS.TableLookupReduction, 'shiftadd': RS.ShiftAddReduction,
}


def parse_q(text: str) -> int:
    t = text.strip().lower()
    if t == 'goldilocks':
        return RS.GOLDILOCKS
    parts = t.split(':')
    if parts[0] == 'prime':
        return primes.randomPrime(int(parts[1]), int(parts[2]) if len(parts) > 2 else 0)
    if parts[0] == 'ntt':
        return primes.nttFriendlyPrime(int(parts[1]), int(parts[2]), int(parts[3]) if len(parts) > 3 else 0)
    if parts[0] == 'mersenne':
        return (1 << int(parts[1])) - 1
    if parts[0] == 'pseudo':
        return primes.pseudoMersennePrime(int(parts[1]))
    if parts[0] == 'solinas':
        return primes.solinasPrime(int(parts[1]))
    return int(t, 0)


def parse_bound(text: str, q: int) -> IntType:
    t = text.strip()
    if t == 'q':
        return IntType(0, q - 1)
    if t == '2q':
        return IntType(0, 2 * q - 1)
    if t in ('qq', 'q^2'):
        return IntType(0, (q - 1) ** 2)
    m = re.match(r'^([su])(\d+)$', t)
    if m:
        w = int(m.group(2))
        return IntType.signed(w) if m.group(1) == 's' else IntType.unsigned(w)
    m = re.match(r'^\[\s*(-?\d+)\s*,\s*(-?\d+)\s*\]$', t)
    if m:
        return IntType(int(m.group(1)), int(m.group(2)))
    raise SystemExit(f'cannot parse bound {text!r}')


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--scenario', required=True)
    p.add_argument('--name', default=None, help='top module name (default from the options)')
    p.add_argument('--work-dir', default=str(PROJECT_ROOT / 'work'))
    p.add_argument('--q', required=True, help='modulus (see the spellings above)')
    p.add_argument('--reduction', default='barrett', choices=sorted(REDUCTIONS))
    p.add_argument('--reduce-only', action='store_true', help='a reduction T -> R, no multiplier')
    p.add_argument('--t-bound', default='qq', help='reduction input bound (default [0,(q-1)^2])')
    p.add_argument('--shoup', action='store_true', help='Shoup/Harvey precomputed multiplication')
    p.add_argument('--adder', choices=('add', 'sub'), default=None, help='a modular adder instead')
    p.add_argument('--a-bound', default='q')
    p.add_argument('--b-bound', default='q')
    p.add_argument('--constant', type=lambda s: int(s, 0), default=None, help='design-time twiddle')
    p.add_argument('--multiplier', default='dsp', choices=('dsp', 'booth', 'behavioural'))
    p.add_argument('--const-backend', default='lut', choices=('lut', 'dsp', 'booth', 'behavioural'))
    p.add_argument('--dsp-budget', type=int, default=None)
    p.add_argument('--output-range', default='exact', help="'exact', 'lazy' or an integer r for [0, r*q)")
    p.add_argument('--no-absorb', action='store_true', help='keep the Montgomery factor with a constant')
    p.add_argument('--w', type=int, default=None, help='word size (wlm)')
    p.add_argument('--variant', default=None, help='wlm variant: flag | negate | generic')
    p.add_argument('--r-bits', type=int, default=None, help='Montgomery R = 2^r')
    p.add_argument('--s1', type=int, default=None)
    p.add_argument('--s2', type=int, default=None)
    p.add_argument('--truncate', type=int, default=0, help='Barrett: drop quotient columns below this')
    p.add_argument('--chunk-bits', type=int, default=None, help='table: index bits per table')
    p.add_argument('--pipeline-stages', type=int, default=1)
    p.add_argument('--target-fmax', type=float, default=None)
    p.add_argument('--test-size', type=int, default=300)
    p.add_argument('--seed', type=int, default=1)
    p.add_argument('--backend', default='hw', choices=('hw', 'sim'))
    p.add_argument('--remote-sim', action='store_true')
    p.add_argument('--remote-synth', action='store_true')
    p.add_argument('--clock-ns', type=float, default=None, help='synthesis clock (default from the target)')
    p.add_argument('--verbose', action='store_true')
    a = p.parse_args()

    q = parse_q(a.q)
    out = a.output_range if a.output_range in ('exact', 'lazy') else int(a.output_range)
    redArgs = {k: v for k, v in dict(w=a.w, variant=a.variant, rBits=a.r_bits, s1=a.s1, s2=a.s2,
                                     chunkBits=a.chunk_bits).items() if v is not None}
    if a.truncate:
        redArgs['truncate'] = a.truncate
    if a.reduction != 'wlm':
        redArgs.pop('w', None), redArgs.pop('variant', None)
    common = dict(targetFmaxMhz=a.target_fmax)
    if a.adder:
        name = a.name or f'modadd_{a.adder}_q{q.bit_length()}'
        sch = ModularAdderScheme(name=name, q=q, aIn=parse_bound(a.a_bound, q), bIn=parse_bound(a.b_bound, q),
                                 subtract=a.adder == 'sub', outputRange=out, **common)
        op = DatapathOperator(name, sch)
    elif a.reduce_only:
        name = a.name or f'red_{a.reduction}_q{q.bit_length()}'
        kw = {} if a.reduction == 'goldilocks' else {'q': q}
        sch = REDUCTIONS[a.reduction](name=name, tIn=parse_bound(a.t_bound, q), outputRange=out,
                                      constBackend=a.const_backend, **kw, **redArgs, **common)
        op = ModularReduction(name, sch)
    elif a.shoup:
        name = a.name or f'shoup_q{q.bit_length()}{"_c" if a.constant else ""}'
        sch = ShoupModMult(name=name, q=q, aIn=parse_bound(a.a_bound, q), constant=a.constant,
                           multiplier=a.multiplier, dspBudget=a.dsp_budget, constBackend=a.const_backend,
                           outputRange=out, **common)
        op = ModularMultiplier(name, sch)
    else:
        name = a.name or f'mm_{a.reduction}_{a.multiplier if a.constant is None else "c"}_q{q.bit_length()}'
        kw = dict(bIn=parse_bound(a.b_bound, q)) if a.constant is None else dict(constant=a.constant)
        sch = ModularMultiplierScheme(name=name, q=q, aIn=parse_bound(a.a_bound, q), multiplier=a.multiplier,
                                      dspBudget=a.dsp_budget, constBackend=a.const_backend,
                                      reduction=REDUCTIONS[a.reduction], reductionArgs=redArgs,
                                      outputRange=out, absorbFactor=not a.no_absorb, **common, **kw)
        op = ModularMultiplier(name, sch)

    run = Path(a.work_dir) / a.scenario / (name if a.backend == 'hw' else f'{name}_sim')
    top = name if a.backend == 'hw' else f'{name}_sim'
    sink = contextlib.nullcontext() if a.verbose else contextlib.redirect_stdout(io.StringIO())
    with sink:
        meta = op.emitRtl(top, run, pipeline_stages=a.pipeline_stages, test_size=a.test_size,
                          seed=a.seed, backend=a.backend, clock_ns=a.clock_ns)
    spec = op.getOperatorInterface(top, a.pipeline_stages)
    (run / 'spec.json').write_text(json.dumps(spec.to_dict(), indent=2, default=str))
    print(op.scheme.datapath().describe(op.scheme.schedule(a.pipeline_stages)))
    r = op.resources()
    print(f'[build_modmult] {top}: q = {q} ({q.bit_length()} bits), latency {meta["pipeline_latency"]}, '
          f'LUT~{r.lut} DSP {r.dsp}, predicted path {op.criticalPathNs(a.pipeline_stages):.3f} ns')
    print(f'[build_modmult] outputs at {run}')
    rc = 0
    if a.remote_sim:
        rc = subprocess.run([sys.executable, str(PROJECT_ROOT / 'scripts' / 'run_remote_sim.py'),
                             '--run-dir', str(run)]).returncode
    if a.remote_synth and rc == 0:
        cmd = [sys.executable, str(PROJECT_ROOT / 'scripts' / 'run_remote_synth.py'), '--run-dir', str(run)]
        ns = a.clock_ns or (1000.0 / a.target_fmax if a.target_fmax else None)
        if ns:
            cmd += ['--clock-ns', f'{ns:.3f}']
        rc = subprocess.run(cmd).returncode
    return rc


if __name__ == '__main__':
    sys.exit(main())
