'''Exhaustive search: every legal option combination of every architecture, priced by the build-free models,
filtered by the requirements, reduced to a Pareto front.

Each adapter module in `adapters/` gives
    enumerate(req)        -> iterable of params dicts (plain values; legal by construction or rejected in evaluate)
    evaluate(req, params) -> CoreRecord, or None when the combination is not legal
    quick(req, params)    -> optional: (interval, butterflies) from a cheap formula, to drop a point early
    sizing(req, params)   -> optional: (family, size[, inner]), the knob that sets the butterfly count, and
                             inner = (option combination, a second size) for a knob sized per combination
                             (see `search`)
    sideKinds(req, params) -> optional: the kinds of side traffic the point surely has, from its options
    quickLatency(req, params) -> optional: a lower bound of the latency from a formula
    evaluate may raise an exception named `TooLarge` (the tables alone exceed a memory limit; counted 'tooLarge')
    twinBase(req, params) -> optional: the base point of a variant that only adds registers and latency, else None
    quickService(req, params) -> optional: the requested services the point surely lacks, from its options
                             (the same words as `Requirements.check` gives for the estimated core)
    innerNeeded(req, params, record, run) -> optional: the inner size a combination needs, computed from one
                             priced core, or None when no inner size can help
    build(record, outdir) -> optional: generate the RTL and testbench of a record (validation)
'''
from __future__ import annotations

import hashlib
from .timing import annotate, hasInputRegister, ROUTE
import importlib
import json
import os
import time
import traceback
from dataclasses import dataclass, field

from .record import CoreRecord

#: fields of the default front: smaller is better for all of them
#: 'share' is the largest share of a resource limit the core uses (Requirements.share)
#: 'sideAvg' is the average bits per cycle of the traffic besides the polynomial (CoreRecord.sideAvg)
OBJECTIVES = ('share', 'interval', 'latency', 'sideAvg')


def adapter(arch: str):
    return importlib.import_module(f'{__package__}.adapters.{arch}')


def _key(arch: str, req, params: dict) -> str:
    spec = {k: v for k, v in req.toJson().items() if k in
            ('n', 'moduli', 'qBits', 'numModuli', 'transform', 'direction', 'clockMhz')}   # params hold the options
    if req.modulusForm != 'ntt':            # keys of the plain form stay as they were
        spec['form'] = req.form
    return hashlib.sha1(json.dumps([arch, spec, params], sort_keys=True, default=str).encode()).hexdigest()


def _pkey(arch: str, params: dict) -> str:
    return arch + json.dumps(params, sort_keys=True, default=str)


def _one(job):
    arch, req, params = job
    t = time.time()
    try:
        r = adapter(arch).evaluate(req, params)
        return arch, params, (r.toJson() if r is not None else None), None, time.time() - t
    except Exception as e:                                   # a model error is a result: it must be listed
        return arch, params, None, f'{type(e).__name__}: {e}\n{traceback.format_exc(limit=3)}', time.time() - t


def objectives(r: CoreRecord, run: float, names=OBJECTIVES, req=None) -> tuple:
    row = None
    out = []
    for n in names:
        if n == 'share':
            out.append(req.share(r)[0] if req is not None else r.lut)
        elif n == 'sideAvg':
            out.append(r.sideAvg(run))
        elif n == 'interval':
            out.append(r.effectiveInterval(run))
        elif n in ('area', 'latency', 'lut', 'ff', 'dsp', 'bram36', 'uram'):
            out.append(getattr(r, n))
        else:
            row = row or r.row(run)
            out.append(row[n])
    return tuple(out)


def pareto(records: list, run: float = float('inf'), names=OBJECTIVES, req=None) -> list:
    '''The records no other record beats: not worse in every objective and better in one. `req` gives the limits
    of the 'share' objective (without it the LUT count stands in).'''
    # The input register option (timing.hasInputRegister) counts as one more objective: a core without it never
    # pushes its twin with it off the front. The register costs flip-flops and a few cycles and buys timing margin
    # on the long routes of a large core, which the area and cycle objectives do not see, so both twins are kept
    # and the user chooses (user, 2026-11-17). The route flag of timing.routeFlag is a note only.
    pts = [(objectives(r, run, names, req) + (0 if hasInputRegister(r) else 1,), r) for r in records]
    pts.sort(key=lambda t: t[0])
    front = []
    for o, r in pts:
        if not any(all(a <= b for a, b in zip(fo, o)) and fo != o for fo, _ in front):
            front.append((o, r))
    return [r for _, r in front]


@dataclass
class SearchResult:
    req: object
    records: list = field(default_factory=list)      # every legal core
    feasible: list = field(default_factory=list)     # those that meet the requirements
    front: list = field(default_factory=list)        # Pareto front of the feasible ones
    rejected: list = field(default_factory=list)     # (record, reasons)
    illegal: int = 0
    errors: list = field(default_factory=list)       # (arch, params, text)
    seconds: float = 0.0
    counts: dict = field(default_factory=dict)       # per arch: enumerated, legal, feasible, front

    def table(self, which='front', cols=None) -> str:
        rows = []
        for r in getattr(self, which):
            row = r.row(self.req.effRun)
            sh, what = self.req.share(r)
            row['share'] = f'{100 * sh:.0f} % {what}' if what else ''
            row['dataBits'] = '/'.join(f'{x:.0f}' for x in r.dataPeak())            # one beat in / out
            row['sideAvg'] = round(r.sideAvg(self.req.effRun), 2)
            row['side'] = '+'.join(sorted(k.split('_')[0] for k in r.side())) or '-'
            row['outsideBits'] = round(self.req.outsideBits(r))
            rows.append(row)
        cols = cols or ['arch', 'name', 'share', 'lut', 'ff', 'dsp', 'bram36', 'uram', 'interval', 'latency',
                        'nttPerS', 'dataBits', 'side', 'sideAvg', 'outsideBits', 'flags']
        if not rows:
            return '(none)'
        w = [max(len(c), *(len(str(r.get(c, ''))) for r in rows)) for c in cols]
        out = ['  '.join(c.ljust(x) for c, x in zip(cols, w))]
        out += ['  '.join(str(r.get(c, '')).ljust(x) for c, x in zip(cols, w)) for r in rows]
        return '\n'.join(out)

    def whyNone(self) -> dict:
        '''For every architecture with no feasible core: the reason most of its cores were rejected for, and
        how many. With saved searches a reason like 'output not in natural order' on every core means the
        saved search never listed the option, not that the architecture lacks it.'''
        out = {}
        for arch, c in self.counts.items():
            if c['feasible'] or not c['legal']:
                continue
            n = {}
            for r, why in self.rejected:
                if r.arch == arch:
                    for w in why:
                        k = ' '.join(x for x in w.split() if not x.replace('.', '').isdigit())
                        n[k] = n.get(k, 0) + 1
            k = max(n, key=n.get)
            out[arch] = (k, n[k], c['legal'])
        return out

    def save(self, path: str, compact: bool = False):
        '''`compact`: no indentation, and gzip when the path ends in .gz (large grids).'''
        run = self.req.effRun
        import gzip
        with (gzip.open(path, 'wt') if path.endswith('.gz') else open(path, 'w')) as f:
            json.dump({'req': self.req.toJson(), 'counts': self.counts, 'seconds': self.seconds,
                       'illegal': self.illegal, 'errors': [(a, p, t) for a, p, t in self.errors],
                       'front': [r.name for r in self.front], 'feasible': [r.name for r in self.feasible],
                       'records': [dict(r.toJson(), row=r.row(run)) for r in self.records],
                       'rejected': [(r.name, why) for r, why in self.rejected]}, f,
                      indent=None if compact or path.endswith('.gz') else 1, default=str)


def _PERF(reason: str) -> bool:
    """Is a rejection reason of `Requirements.check` about throughput or latency?"""
    return reason.startswith(('throughput ', 'interval ', 'latency '))


def _sized(req) -> bool:
    """Is the search sized to the throughput target (Requirements.sizing 'minimal' and a target given)?"""
    return req.sizing == 'minimal' and req.targetInterval is not None


def _sz(A, req, params) -> tuple:
    """(family, size, combination, inner size) of a point. Without an inner knob the last two are None."""
    out = A.sizing(req, params)
    inner = out[2] if len(out) > 2 else (None, None)
    return out[0], out[1], inner[0], inner[1]


def _price(req, work, jobs, cache, verbose, t0) -> list:
    """Price (arch, req, params) jobs: from the cache where they are there, else by the models in `jobs` processes.
    Returns (arch, params, record json or None, error text or None, seconds) per job."""
    done, todo = [], []
    if cache:
        os.makedirs(cache, exist_ok=True)
        for j in work:
            p = os.path.join(cache, _key(j[0], req, j[2]) + '.json')
            if os.path.exists(p):
                with open(p) as f:
                    d = json.load(f)
                done.append((j[0], j[2], d['record'], d['error'], 0.0))
            else:
                todo.append(j)
    else:
        todo = list(work)
    if verbose:
        print(f'dse: {len(work)} points, {len(done)} cached, {len(todo)} to price', flush=True)
    jobs = jobs or max(1, (os.cpu_count() or 2) // 2)
    if jobs > 1 and len(todo) > 1:
        import multiprocessing as mp
        with mp.get_context('fork').Pool(min(jobs, len(todo))) as pool:
            fresh = []
            for i, out in enumerate(pool.imap_unordered(_one, todo, chunksize=1)):
                fresh.append(out)
                if verbose and (i + 1) % 200 == 0:
                    print(f'dse: {i + 1}/{len(todo)} priced, {time.time() - t0:.0f} s', flush=True)
    else:
        fresh = [_one(j) for j in todo]
    if cache:
        for arch, params, rec, err, _ in fresh:
            with open(os.path.join(cache, _key(arch, req, params) + '.json'), 'w') as f:
                json.dump({'arch': arch, 'params': params, 'record': rec, 'error': err}, f, default=str)
    return done + fresh


def search(req, jobs: int | None = None, cache: str | None = None, names=OBJECTIVES, verbose: bool = False,
           limit: int | None = None, sample: int | None = None, seed: int = 1) -> SearchResult:
    """Enumerate, price, filter. `jobs`: worker processes (default: half the cores). `cache`: a folder that keeps
    one JSON per priced point (key: architecture, NTT parameters, clock, params), so a second search is fast.
    `limit`: at most this many points per architecture, the first ones (trials). `sample`: at most this many per
    architecture, drawn evenly at random over the whole list (`seed`), so a short search still sees every option.

    Sizing (`req.sizing` 'minimal' with a throughput target, the default of the request file). The throughput and
    the clock fix how many butterflies a core needs, so the search does not price every size:
      1. a point whose `quick` interval, a lower bound from a formula, misses the target is dropped unpriced,
         and so is a point whose `quickLatency`, a lower bound of the latency, is above the latency limit,
         and a point whose options need a kind of side traffic the user does not allow (`sideKinds`);
      2. the rest is grouped by the adapter's `sizing` into families and sizes, and each family is priced from its
         smallest size up. The first size with a core that meets every requirement (the latency limit too) ends the
         family: a larger size of the same family only adds area.
      3. an adapter may name an inner knob (the hybrid's slots). Within one size, every option combination is
         priced from its smallest inner size up and stops at the first one that meets the requirements.
         With `innerNeeded` the adapter computes the needed inner size from that first core, so the search
         goes there in one step (the hybrid's cycles per polynomial are R max(T, ceil(P / S))).
    counts: 'tooSlow', 'tooLate' and 'noPort' (rule 1) and 'larger' (rules 2, 3) are the points that were not priced. `req.sizing` 'all' prices
    every point, as before."""
    t0 = time.time()
    res = SearchResult(req)
    run = req.effRun

    def take(results) -> set:
        """File the priced points into `res`. Returns (arch, family) and (arch, family, combination) of the
        feasible cores."""
        hit = set()
        for arch, params, rec, err, _ in results:
            if err and err.startswith('TooLarge:'):
                # the adapter stopped before the arithmetic: the tables of the core alone exceed a memory limit
                res.counts[arch]['tooLarge'] = res.counts[arch].get('tooLarge', 0) + 1
                continue
            if err:
                if 'No space left on device' in err:        # the machine, not the model: stop, do not go on
                    raise RuntimeError('a disk is full (No space left on device). The search stops. Free space or '
                                       'set TMPDIR to a disk with room, then run again.')
                res.errors.append((arch, params, err))
                continue
            if rec is None:
                res.illegal += 1
                continue
            r = CoreRecord.fromJson(rec)
            annotate(r)
            r.flags += req.limitFlags(r)
            res.records.append(r)
            res.counts[arch]['legal'] += 1
            why = req.check(r)
            if hasattr(adapter(arch), 'sizing'):
                fam, _, combo, _ = _sz(adapter(arch), req, params)
                priced[(arch, fam, combo)] = (params, r)
                if why and all(_PERF(w) for w in why):      # only too slow or too late: a larger size may fit
                    grow.add((arch, fam))
                    grow.add((arch, fam, combo))
            if why:
                res.rejected.append((r, why))
            else:
                res.feasible.append(r)
                res.counts[arch]['feasible'] += 1
                ok.add(_pkey(arch, params))
                if hasattr(adapter(arch), 'sizing'):
                    fam, _, combo, _ = _sz(adapter(arch), req, params)
                    hit.add((arch, fam))
                    hit.add((arch, fam, combo))
        return hit

    work, ladders = [], {}
    ok = set()                          # the points whose core meets the request
    later = []                          # (arch, point, its base point): variants that only add to their base
    priced = {}                         # (arch, family, combination) -> (params, record) of its last priced core
    grow = set()                        # families and combinations with a core that fails on performance only
    sized = _sized(req)
    for arch in req.archs:
        A = adapter(arch)
        pts = list(A.enumerate(req))
        if sample and len(pts) > sample:
            import random
            pts = random.Random(seed).sample(pts, sample)
        if limit:
            pts = pts[:limit]
        if hasattr(A, 'twinBase'):
            # a variant that only adds registers and latency to its base point (same service, same interval) meets
            # the request only if the base does: it is estimated after the bases, and only then
            have = {_pkey(arch, p) for p in pts}
            keep = []
            for p in pts:
                base = A.twinBase(req, p)
                if base is None or _pkey(arch, base) not in have:       # no base in this search: an ordinary point
                    keep.append(p)
                else:
                    later.append((arch, p, base))
            nLater = len(pts) - len(keep)
            pts = keep
        else:
            nLater = 0
        c = res.counts[arch] = {'enumerated': len(pts) + nLater, 'legal': 0, 'feasible': 0, 'front': 0}
        if not (sized and hasattr(A, 'sizing') and hasattr(A, 'quick')):
            work += [(arch, req, p) for p in pts]
            continue
        c['tooSlow'] = c['tooLate'] = c['noPort'] = c['larger'] = 0
        late = req.latencyLimit if hasattr(A, 'quickLatency') else None
        banned = req.forbiddenKinds() if hasattr(A, 'sideKinds') else set()
        for p in pts:
            if banned and A.sideKinds(req, p) & banned:
                c['noPort'] += 1
                continue
            if hasattr(A, 'quickService') and A.quickService(req, p):
                c['noService'] = c.get('noService', 0) + 1     # the options alone say the core lacks a service
                continue
            if A.quick(req, p)[0] > req.targetInterval:
                c['tooSlow'] += 1
                continue
            if late is not None and A.quickLatency(req, p) > late:
                c['tooLate'] += 1
                continue
            fam, size, _, _ = _sz(A, req, p)
            ladders.setdefault((arch, fam), {}).setdefault(size, []).append(p)
    take(_price(req, work, jobs, cache, verbose, t0))
    # the ladders: every open family prices its next size in the same round
    todo = {k: sorted(v) for k, v in ladders.items()}
    rnd = 0
    while todo:
        rnd += 1
        # the points of this round, per (arch, family, combination): {inner size: [points]}
        inner = {}
        for (arch, fam), sizes in todo.items():
            for p in ladders[(arch, fam)][sizes[0]]:
                _, _, combo, isz = _sz(adapter(arch), req, p)
                inner.setdefault((arch, fam, combo), {}).setdefault(isz, []).append(p)
        steps = {k: sorted(v, key=lambda x: (x is not None, x)) for k, v in inner.items()}
        hit, sub = set(), 0
        while steps:
            sub += 1
            batch = [(k[0], req, p) for k, st in steps.items() for p in inner[k][st[0]]]
            if verbose:
                print(f'dse: sizing round {rnd}.{sub}, {len(todo)} families open, {len(batch)} points', flush=True)
            got = take(_price(req, batch, jobs, cache, verbose, t0))
            hit |= got
            for k in list(steps):
                rest = steps[k][1:]
                A = adapter(k[0])
                if k not in got and k not in grow:          # it fails on a resource or boundary limit, which a
                    res.counts[k[0]]['larger'] += sum(len(inner[k][x]) for x in rest)      # larger size never cures
                    rest = []
                grow.discard(k)
                if k not in got and rest and hasattr(A, 'innerNeeded') and k in priced:
                    need = A.innerNeeded(req, priced[k][0], priced[k][1], run)      # go straight to the needed size
                    keep = [] if need is None else [x for x in rest if x >= need]
                    res.counts[k[0]]['larger'] += sum(len(inner[k][x]) for x in rest if x not in keep)
                    rest = keep
                if k in got or not rest:
                    res.counts[k[0]]['larger'] += sum(len(inner[k][x]) for x in rest)
                    del steps[k]
                else:
                    steps[k] = rest
        for k in list(todo):
            if k in hit or len(todo[k]) == 1 or k not in grow:
                res.counts[k[0]]['larger'] += sum(len(ladders[k][x]) for x in todo[k][1:])
                del todo[k]
            else:
                todo[k] = todo[k][1:]
            grow.discard(k)
    if later:
        twins = [(arch, req, p) for arch, p, base in later if _pkey(arch, base) in ok]
        for arch, p, base in later:
            if _pkey(arch, base) not in ok:
                res.counts[arch]['baseFails'] = res.counts[arch].get('baseFails', 0) + 1
        if verbose:
            print(f'dse: {len(twins)} of {len(later)} variants have a base core that meets the request', flush=True)
        take(_price(req, twins, jobs, cache, verbose, t0))
    res.feasible.sort(key=lambda r: req.share(r)[0])
    res.front = pareto(res.feasible, run, names, req)
    for r in res.front:
        res.counts[r.arch]['front'] += 1
    res.seconds = time.time() - t0
    return res


def _sameNtt(a: dict, req) -> bool:
    '''A saved result was priced for the NTT and clock of `req` (the modulus values may differ, not their width).'''
    width = max(int(q).bit_length() for q in a['moduli']) if a.get('moduli') else a.get('qBits')
    m = a.get('numModuli') or len(a.get('moduli') or []) or 1
    return (a['n'] == req.n and width == req.width and m == req.M and a['transform'] == req.transform
            and a['direction'] == req.direction and abs(a['clockMhz'] - req.clockMhz) < 1e-6
            and (bool(a.get('moduli')) or _formOf(a) == req.form or bool(req.moduli)))


def _formOf(a: dict) -> dict:
    '''The modulus form a saved request states (files written before the form existed state none).'''
    kind = a.get('modulusForm', 'ntt')
    key = {'friendly': ('v', 'formV'), 'kred': ('kBits', 'formKBits'), 'pseudo_mersenne': ('cBits', 'formCBits')}.get(kind)
    return {'kind': kind, key[0]: a.get(key[1])} if key else {'kind': kind}


def requery(req, paths, names=OBJECTIVES) -> SearchResult:
    '''Filter the records of saved searches (`SearchResult.save` files, .json or .json.gz) by new targets and
    limits, with no pricing. The files must hold the same NTT at the same clock as `req`: same n, modulus width,
    number of moduli, transform, direction and clock. A file that differs raises. The saved searches bound what
    can be found: an option they did not enumerate is not there.'''
    import gzip
    t0 = time.time()
    res = SearchResult(req)
    seen = set()
    loaded = []
    for path in paths:
        with (gzip.open(path, 'rt') if path.endswith('.gz') else open(path)) as f:
            d = json.load(f)
        if not _sameNtt(d['req'], req):
            raise ValueError(f'{path} was priced for another NTT or clock')
        res.errors += [tuple(e) for e in d.get('errors', [])]
        res.illegal += d.get('illegal', 0)
        for rec in d['records']:
            rec = {k: v for k, v in rec.items() if k != 'row'}
            r = CoreRecord.fromJson(rec)
            if r.arch not in req.archs or (r.arch, r.name) in seen:
                continue
            seen.add((r.arch, r.name))
            loaded.append(r)
    out = refilter(req, loaded, names)
    out.errors, out.illegal = res.errors, res.illegal
    out.seconds = time.time() - t0
    return out


def refilter(req, records, names=OBJECTIVES) -> SearchResult:
    '''The records of an earlier search or re-query (same NTT and clock) against the targets and limits of
    `req`: timing flags looked up again, feasible list and front built again. Nothing is priced or read.'''
    t0 = time.time()
    res = SearchResult(req)
    for r in records:
        if r.arch not in req.archs:
            continue
        r.flags = [x for x in r.flags if not x.startswith(('timing:', 'limit:', ROUTE))]   # looked up again
        annotate(r)
        r.flags += req.limitFlags(r)
        c = res.counts.setdefault(r.arch, {'enumerated': 0, 'legal': 0, 'feasible': 0, 'front': 0})
        c['enumerated'] += 1
        c['legal'] += 1
        res.records.append(r)
        why = req.check(r)
        if why:
            res.rejected.append((r, why))
        else:
            res.feasible.append(r)
            c['feasible'] += 1
    if _sized(req):                 # of each family keep the smallest size that has a feasible core, and of
        small, smallIn = {}, {}     # each option combination at that size the smallest inner size
        sz = {}
        for r in res.feasible:
            A = adapter(r.arch)
            if hasattr(A, 'sizing'):
                sz[id(r)] = fam, size, combo, isz = _sz(A, req, r.params)
                small[(r.arch, fam)] = min(size, small.get((r.arch, fam), size))
        for r in res.feasible:
            if id(r) in sz:
                fam, size, combo, isz = sz[id(r)]
                if size == small[(r.arch, fam)] and isz is not None:
                    k = (r.arch, fam, combo)
                    smallIn[k] = min(isz, smallIn.get(k, isz))
        keep = []
        for r in res.feasible:
            why = None
            if id(r) in sz:
                fam, size, combo, isz = sz[id(r)]
                if size > small[(r.arch, fam)]:
                    why = (f'larger than needed: size {size}, size {small[(r.arch, fam)]} of the same family meets '
                           f'the requirements')
                elif isz is not None and isz > smallIn[(r.arch, fam, combo)]:
                    why = (f'larger than needed: {isz} slots, {smallIn[(r.arch, fam, combo)]} meet the requirements '
                           f'with the same options')
            if why:
                res.rejected.append((r, [why]))
                res.counts[r.arch]['feasible'] -= 1
                res.counts[r.arch]['larger'] = res.counts[r.arch].get('larger', 0) + 1
            else:
                keep.append(r)
        res.feasible = keep
    res.feasible.sort(key=lambda r: req.share(r)[0])
    res.front = pareto(res.feasible, req.effRun, names, req)
    for r in res.front:
        res.counts[r.arch]['front'] += 1
    res.seconds = time.time() - t0
    return res
