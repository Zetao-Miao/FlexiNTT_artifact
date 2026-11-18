#!/usr/bin/env python3
"""
Design-space exploration over the four NTT architectures.

Give the NTT, the clock, the performance targets and the limits. The script prices every legal core of every
architecture with the build-free models, lists the cores that meet the requirements and marks their Pareto
front (share of the limits, cycles per polynomial, latency, traffic besides the polynomial).

The inputs go in a request file, which is the easy way. `--template` writes a commented one to fill in.
  ./runDse.py userNTTinput.toml
  ./runDse.py --template other_name.toml          (a fresh copy under another name)
  ./runDse.py userNTTinput.toml --max-dsp 400        (an option overrides the file)

The same inputs as options
  ./runDse.py --n 4096 --qbits 32 --clock 350 --max-interval 512 --out /tmp/dse1
  ./runDse.py --n 65536 --moduli-bits 60 --num-moduli 4 --per-poly-modulus --min-ntt-per-s 2e5 --max-dsp 4000
  ./runDse.py --spec req.json --out results/
  ./runDse.py --n 4096 --qbits 32 --max-dsp 100 --records a/result.json b/result.json.gz
A JSON spec holds the fields of operator_modeling.dse.Requirements. Options on the command line override it.
"""
import argparse
import json
import os
import sys

from operator_modeling.dse import Requirements, requery, search
from operator_modeling.dse.record import PORT_KINDS
from operator_modeling.dse.request import RequestError, loadRequest, pickModuli, writeTemplate


def args():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('request', nargs='?', help='request file (.toml) with all the inputs')
    p.add_argument('--template', metavar='FILE', help='write a commented request file to fill in, and stop')
    g = p.add_argument_group('NTT')
    g.add_argument('--spec', help='JSON file with Requirements fields')
    g.add_argument('--n', type=int)
    g.add_argument('--moduli', help='comma-separated moduli (needed for tables fixed at build time)')
    g.add_argument('--qbits', type=int, help='modulus width when the moduli are not listed')
    g.add_argument('--moduli-bits', type=int, help='pick --num-moduli NTT-friendly primes of this width')
    g.add_argument('--num-moduli', type=int)
    g.add_argument('--modulus-form', choices=('ntt', 'friendly', 'kred', 'pseudo_mersenne'), dest='modulusForm',
                   help='a special form of every modulus (with --form-v, --form-k-bits or --form-c-bits)')
    g.add_argument('--form-v', type=int, dest='formV', help='friendly: every q = h 2^v + 1')
    g.add_argument('--form-k-bits', type=int, dest='formKBits', help='kred: q = k 2^m + 1, k of this many bits')
    g.add_argument('--form-c-bits', type=int, dest='formCBits', help='pseudo_mersenne: q = 2^bits - c, c below 2^this')
    g.add_argument('--transform', choices=('cyclic', 'negacyclic', 'both'))
    g.add_argument('--direction', choices=('forward', 'inverse', 'both'))
    g.add_argument('--per-poly-modulus', action='store_true', default=None)
    g.add_argument('--per-poly-direction', action='store_true', default=None)
    g.add_argument('--natural-order', action='store_true', help='output coefficients in index order')
    g.add_argument('--out-ready', action='store_true', help='the core must accept a stalled output')
    g.add_argument('--run', type=float, help='polynomials of one modulus back to back')
    g = p.add_argument_group('performance')
    g.add_argument('--clock', type=float, dest='clockMhz', help='MHz')
    g.add_argument('--min-ntt-per-s', type=float, dest='minNttPerS')
    g.add_argument('--max-interval', type=float, dest='maxIntervalCycles')
    g.add_argument('--max-latency', type=float, dest='maxLatencyCycles')
    g.add_argument('--max-latency-us', type=float, dest='maxLatencyUs')
    g = p.add_argument_group('limits')
    for k in ('lut', 'ff', 'dsp', 'bram36', 'uram'):
        g.add_argument(f'--max-{k}', type=float, dest='max' + k.capitalize())
    g.add_argument('--data-in-bits', type=float, dest='maxDataInBits', help='widest data input, bits per cycle')
    g.add_argument('--data-out-bits', type=float, dest='maxDataOutBits', help='widest data output, bits per cycle')
    g.add_argument('--no-twiddle-stream', action='store_true', help='no core that takes twiddles from a stream')
    g.add_argument('--no-table-load', action='store_true', help='no core whose tables are written from outside')
    g.add_argument('--no-record-stream', action='store_true', help='no core that takes a record per polynomial')
    g.add_argument('--max-outside-table-bits', type=float, dest='maxOutsideTableBits')
    g.add_argument('--no-risk', action='store_true', help='reject cores with a timing risk flag')
    g = p.add_argument_group('search')
    g.add_argument('--archs', help='comma-separated, of iterative,hybrid,dataflow,multistep')
    g.add_argument('--sizing', choices=('minimal', 'all'),
                   help='minimal (default): only the smallest core size that meets the requirements; all: every size')
    g.add_argument('--jobs', type=int)
    g.add_argument('--limit', type=int, help='at most this many points per architecture')
    g.add_argument('--sample', type=int, help='at most this many points per architecture, drawn at random')
    g.add_argument('--seed', type=int)
    g.add_argument('--cache', help='folder for priced points')
    g.add_argument('--records', nargs='+', metavar='RESULT.json',
                   help='filter the records of saved searches of the same NTT and clock, price nothing')
    g.add_argument('--out', help='folder for result.json, front.txt and feasible.txt')
    g.add_argument('--show', choices=('front', 'feasible', 'records'))
    return p.parse_args()


def requirements(a) -> Requirements:
    d, pick = {}, False
    if a.request and a.spec:
        raise RequestError('give a request file or --spec, not both')
    if a.request and a.request.endswith('.json'):
        a.spec, a.request = a.request, None
    if a.request:
        d, run = loadRequest(a.request)
        pick = run.pop('pickModuli', False)
        for k, v in run.items():            # [run] of the file, unless the option is given
            if getattr(a, k) is None:
                setattr(a, k, v)
    if a.spec:
        with open(a.spec) as f:
            d = json.load(f)
    if a.moduli:
        d['moduli'] = [int(x, 0) for x in a.moduli.split(',')]
    for src, dst in (('n', 'n'), ('qbits', 'qBits'), ('num_moduli', 'numModuli'), ('transform', 'transform'),
                     ('direction', 'direction'), ('per_poly_modulus', 'perPolyModulus'),
                     ('per_poly_direction', 'perPolyDirection'), ('run', 'run')):
        if getattr(a, src) is not None:
            d[dst] = getattr(a, src)
    for k in ('modulusForm', 'formV', 'formKBits', 'formCBits', 'clockMhz', 'minNttPerS', 'maxIntervalCycles', 'maxLatencyCycles', 'maxLatencyUs', 'maxLut', 'maxFf',
              'maxDsp', 'maxBram36', 'maxUram', 'maxDataInBits', 'maxDataOutBits',
              'maxOutsideTableBits', 'sizing'):
        if getattr(a, k) is not None:
            d[k] = getattr(a, k)
    if a.natural_order:
        d['outputOrder'] = 'natural'
    if a.out_ready:
        d['outputBackpressure'] = True
    for flag, field in (('no_twiddle_stream', 'allowTwiddleStream'), ('no_table_load', 'allowTableLoad'),
                        ('no_record_stream', 'allowRecordStream')):
        if getattr(a, flag):
            d[field] = False
    if a.archs:
        d['archs'] = tuple(a.archs.split(','))
    if a.no_risk:
        d['allowRiskFlags'] = False
    for k in ('archs', 'bandwidthKinds'):
        if isinstance(d.get(k), list):
            d[k] = tuple(d[k])
    if a.moduli_bits or (pick and not a.moduli):
        d['moduli'] = pickModuli(d, a.moduli_bits)
    a.seed = 1 if a.seed is None else a.seed
    a.show = a.show or 'front'
    try:
        req = Requirements(**d)
    except TypeError as e:
        raise RequestError(f'the inputs are not complete: {e}') from None
    if req.targetInterval is None:
        raise RequestError('a throughput target is needed: set min_ntt_per_second or max_cycles_per_ntt in '
                           '[performance] (--min-ntt-per-s or --max-interval)')
    if req.latencyLimit is None:
        raise RequestError('a latency limit is needed: set max_latency_cycles or max_latency_us in [performance] '
                           '(--max-latency or --max-latency-us). Give a huge number if the latency does not matter')
    missing = [k for k, v in (('max_lut', req.maxLut), ('max_ff', req.maxFf), ('max_dsp', req.maxDsp),
                              ('max_bram36', req.maxBram36), ('max_uram', req.maxUram)) if v is None]
    if missing:
        raise RequestError('every resource limit is needed. Missing in [resources]: ' + ', '.join(missing))
    missing = [k for k, v in (('data_in_bits_per_cycle', req.maxDataInBits), ('data_out_bits_per_cycle', req.maxDataOutBits),
                              ('max_outside_table_bits', req.maxOutsideTableBits)) if v is None]
    if missing:
        raise RequestError('the boundary is not complete. Missing in [bandwidth]: ' + ', '.join(missing))
    rate = req.dataRate()
    for lim, nm in ((req.maxDataInBits, 'input'), (req.maxDataOutBits, 'output')):
        if rate > lim:
            raise RequestError(f'the throughput target needs {rate:.1f} bits per cycle on the data {nm} '
                               f'({req.n} coefficients of {req.width} bits every {req.targetInterval:.0f} cycles), '
                               f'but the data {nm} carries at most {lim:.0f}. No core can meet this.')
    return req


def main():
    a = args()
    try:
        if a.template:
            print(f'template written to {writeTemplate(a.template)}')
            return 0
        req = requirements(a)
    except (RequestError, ValueError) as e:
        print(f'error: {e}', file=sys.stderr)
        return 2
    print(f'the polynomial needs {req.dataRate():.1f} bits per cycle in and the same out at the throughput target '
          f'(data ports: {req.maxDataInBits:.0f} in, {req.maxDataOutBits:.0f} out, at most {req.maxLanes} '
          f'coefficients per cycle)', flush=True)
    if a.records:
        res = requery(req, a.records)
    else:
        res = search(req, jobs=a.jobs, cache=a.cache, limit=a.limit, sample=a.sample, seed=a.seed, verbose=True)
    print(f'\n{len(res.records)} legal cores, {len(res.feasible)} meet the requirements, {len(res.front)} on the '
          f'front, {res.illegal} not legal, {len(res.errors)} model errors, {res.seconds:.0f} s')
    for arch, c in res.counts.items():
        print(f'  {arch:10s} ' + '  '.join(f'{k} {v}' for k, v in c.items()))
    for arch, (why, n, legal) in res.whyNone().items():
        print(f'  {arch}: no core, {n} of {legal} rejected for "{why}"'
              + (' (the saved searches may not list this option)' if a.records and n == legal else ''))
    print()
    print(res.table(a.show))
    if res.errors:
        print(f'\nfirst model error: {res.errors[0][0]} {res.errors[0][1]}\n{res.errors[0][2]}')
    if a.out:
        os.makedirs(a.out, exist_ok=True)
        res.save(os.path.join(a.out, 'result.json'), compact=len(res.records) > 5000)
        for which in ('front', 'feasible'):
            with open(os.path.join(a.out, which + '.txt'), 'w') as f:
                f.write(res.table(which) + '\n')
        print(f'\nwritten to {a.out}')
    return 0 if res.feasible else 1


if __name__ == '__main__':
    sys.exit(main())
