'''The dataflow NTT operator: the RTL spec and the emitted pipeline of a `StreamingNTTScheme`.'''
from __future__ import annotations

from ..butterfly.ButterflyScheme import ButterflyScheme  # noqa: F401  (puts versal_arith on sys.path)
from ...core.IntType import IntType


class StreamingNTT:
    '''The operator over a `StreamingNTTScheme`: builds the RTL spec and emits
    the pipeline (`rtl_gen.ntt.StreamNTT_RTL_gen`).

    RTL ports: `clk`, `rst` (clears the frame counter: the first frame enters
    the cycle after it falls), [`DIR`: 0 forward, 1 inverse, when built for both],
    [the modulus inputs `qPorts()` at run-time q: quasi-static, one q per job],
    [`tw_rst`, `tw_wen`, `tw_wdata`: the twiddle load port, when any table is
    loaded: `tw_rst` restarts the write index, then one word per `tw_wen` in
    the order of `loadImage(q)`], `x_in_<lane>`, `y_out_<lane>`. Points enter where
    `scheme.inputLocation(m)` says (CT: lane = m mod P, cycle = m // P of the frame;
    GS: where CT leaves its output) and leave where `scheme.outputLocation(m)` says.'''

    def __init__(self, scheme):
        self.scheme = scheme
        self.name = scheme.name

    # --- tables ------------------------------------------------------------------

    def _tables(self, pipelineStages: int):
        '''Every twiddle table, in load order: list of dicts {id, use, depth, cols
        (widths), mode 'rom' | 'ram', values (rom: per column), base (ram: first
        word of the load image), lanes / key}.'''
        sch = self.scheme
        q0 = sch.refQ()
        W = max(1, (sch.qMax() - 1).bit_length())
        mode = 'ram' if sch.runtime or sch.twiddleSource == 'ram' else 'rom'
        # per-frame moduli: every table is a ROM holding one block per modulus (address {MIDX, DIR, bits})
        qs = sch.moduli if sch.perFrame else None
        if qs:
            # loadableModuli: a RAM with one block per slot, filled through the load port (one slot per load)
            mode = 'ram' if getattr(sch, 'loadMod', False) else 'rom'
        blk = len(qs) if (qs and mode == 'ram') else 1      # blocks of a table: the load image holds one
        if getattr(sch, 'loadDir', False):                  # ... and of that block one direction (its half)
            blk *= 2

        def cat(fn):
            '''fn(q) -> list of columns; per-frame: each column concatenated over the moduli.'''
            if not qs:
                return fn(q0)
            if mode == 'ram':
                # a RAM table keeps no values here (the load image is built by `loadRows`): only the lengths are
                # read, and they are the same for every modulus. One modulus instead of all of them (2026-11-16:
                # 64 stand-in moduli cost 28 of 52 s of a point of N = 2^16)
                p0 = fn(qs[0])
                per = [p0] * len(qs)
            else:
                per = [fn(q) for q in qs]
            return [sum((p[c] for p in per), []) for c in range(len(per[0]))]
        tabs, base = [], 0

        def add(t):
            nonlocal base
            t['id'] = len(tabs)
            if t['mode'] == 'ram':
                t['base'] = base
                base += (t['depth'] // blk) * len(t['cols'])
            tabs.append(t)
            return t['id']

        classes = sch.slotClasses()
        self.classTable = {}
        for key in classes:
            if sch.classSource(key) == 'rec':
                if sch.shoup():
                    raise NotImplementedError(f'{sch.name}: the root recurrence does not produce Shoup companions')
                bw, ups = cat(lambda q: list(sch.recTables(key, q)))
                tb = add({'use': 'base', 'key': key, 'depth': len(bw), 'cols': [W], 'mode': mode,
                          'values': [bw] if mode == 'rom' else None, 'bits': list(range(sch.recBaseBits()))})
                tu = add({'use': 'upd', 'key': key, 'depth': len(ups), 'cols': [W], 'mode': mode,
                          'values': [ups] if mode == 'rom' else None, 'bits': []})
                self.classTable[key] = ('rec', tb, tu)
            elif sch.classSource(key) == 'stream':
                # no table: port tw_s<i> carries the class's twiddle with the frame, delayed to the stage
                self.classTable[key] = ('stream', len([v for v in self.classTable.values() if v[0] == 'stream']))
            elif sch.classSource(key) == 'otf':
                if sch.shoup():
                    raise NotImplementedError(f'{sch.name}: on-the-fly twiddles do not produce Shoup companions')
                lo, hi = cat(lambda q: list(sch.otfTables(key, q)))
                bl, bh = sch.otfBits(key)
                ti = add({'use': 'lo', 'key': key, 'depth': len(lo), 'cols': [W], 'mode': mode,
                          'values': [lo] if mode == 'rom' else None, 'bits': bl})
                th = add({'use': 'hi', 'key': key, 'depth': len(hi), 'cols': [W], 'mode': mode,
                          'values': [hi] if mode == 'rom' else None, 'bits': bh})
                self.classTable[key] = ('otf', ti, th)
            else:
                if qs:
                    cols_ = cat(lambda q: [c for c in sch.slotTable(key, q) if c is not None])
                    w, wp = cols_[0], (cols_[1] if len(cols_) > 1 else None)
                else:
                    w, wp = sch.slotTable(key, q0)
                # the companion column as wide as the butterflies' WP port
                cols = [W] + ([self._wpWidth()] if wp else [])
                ti = add({'use': 'slot', 'key': key, 'depth': len(w), 'cols': cols, 'mode': mode,
                          'values': ([w] + ([wp] if wp else [])) if mode == 'rom' else None,
                          'bits': sch.significantBits(key)})
                self.classTable[key] = ('tab', ti)
        self.twistTables = []
        if sch.twistMultiplier is not None and sch.twistOtf():
            # on-the-fly twist: per lane a low and a high table (one block per modulus) and a generator
            for l in range(sch.lanes):
                lo, hi = cat(lambda q, l=l: list(sch.twistOtfTables(l, q)))
                bl, bh = sch.twistOtfBits(l)
                ti = add({'use': 'twlo', 'lane': l, 'depth': len(lo), 'cols': [W], 'mode': mode,
                          'values': [lo] if mode == 'rom' else None, 'bits': bl})
                th = add({'use': 'twhi', 'lane': l, 'depth': len(hi), 'cols': [W], 'mode': mode,
                          'values': [hi] if mode == 'rom' else None, 'bits': bh})
                self.twistTables.append((ti, th))
        elif sch.twistMultiplier is not None:
            tt = cat(sch.twistTables)
            tmode = 'ram' if sch.runtime and (not qs or mode == 'ram') else 'rom'
            for l in range(sch.lanes):
                self.twistTables.append(add({'use': 'twist', 'lane': l, 'depth': len(tt[l]), 'cols': [W],
                                             'mode': tmode, 'values': [tt[l]] if tmode == 'rom' else None,
                                             'bits': list(range(sch.fb))}))
        self.loadWords = base
        self.loadLanes = 1
        R = getattr(sch, 'loadLanes', 1)
        if R > 1:
            # several words per cycle: each table goes to the lane that is shortest so far, so every lane stays
            # in the order of the stages and the lanes end at about the same cycle
            fill = [0] * R
            for t in tabs:
                if t['mode'] == 'ram':
                    l = min(range(R), key=lambda i: fill[i])
                    t['ldl'], t['base'] = l, fill[l]
                    fill[l] += (t['depth'] // blk) * len(t['cols'])
            self.loadWords, self.loadLanes = max(fill), R
        if qs:
            for t in tabs:
                t['mods'] = len(qs)         # blocks of depth // mods words, one per modulus
        return tabs

    def loadRows(self, q: int, d: str | None = None) -> list:
        '''The load of modulus q (direction d with loadByDirection) as the load port takes it: one row per cycle,
        one word per load lane.'''
        if not hasattr(self, 'tables'):
            self.tables = self._tables(1)
        flat = self.loadImage(q, d)         # table after table, in table order
        rows = [[0] * self.loadLanes for _ in range(self.loadWords)]
        at = 0
        for t in self.tables:
            if t['mode'] != 'ram':
                continue
            n = (t['depth'] // (t.get('mods') or 1) if getattr(self.scheme, 'loadMod', False) else t['depth']) * len(t['cols'])
            n //= 2 if getattr(self.scheme, 'loadDir', False) else 1
            for i in range(n):
                rows[(t['base'] if self.loadLanes > 1 else at) + i][t.get('ldl', 0)] = flat[at + i]
            at += n
        return rows

    def _wpWidth(self) -> int:
        '''Shoup companion width at run time: floor(w * 2^beta / q) < 2^beta.'''
        bu = next(b for st in self.scheme.butterflies for b in st if 'WP' in b.portNames())
        return bu.defaultPortBound('WP').bitWidth

    def loadImage(self, q: int, d: str | None = None) -> list[int]:
        '''The words to write through the twiddle load port for modulus q, in order. `d` ('fwd' | 'inv', designs
        with loadByDirection): the words of that direction only (every table holds forward then inverse).'''
        sch = self.scheme
        if not hasattr(self, 'tables'):
            self.tables = self._tables(1)
        half = None
        if getattr(sch, 'loadDir', False):
            half = sch.dirs.index(d)
        out = []
        for t in self.tables:
            if t['mode'] != 'ram':
                continue
            if t['use'] == 'slot':
                w, wp = sch.slotTable(t['key'], q)
                cols = [w] + ([wp] if wp else [])
            elif t['use'] in ('lo', 'hi'):
                lo, hi = sch.otfTables(t['key'], q)
                cols = [lo if t['use'] == 'lo' else hi]
            elif t['use'] in ('base', 'upd'):
                bw, ups = sch.recTables(t['key'], q)
                cols = [bw if t['use'] == 'base' else ups]
            elif t['use'] in ('twlo', 'twhi'):
                lo, hi = sch.twistOtfTables(t['lane'], q)
                cols = [lo if t['use'] == 'twlo' else hi]
            else:
                cols = [sch.twistTables(q)[t['lane']]]
            for c in cols:
                if half is not None:
                    if len(c) % 2:
                        raise AssertionError(f'{sch.name}: table {t["id"]} has no two halves to load by direction')
                    c = c[half * len(c) // 2:(half + 1) * len(c) // 2]
                out += c
        return out

    # --- the spec ----------------------------------------------------------------

    def rnsRecord(self, q: int, keep: bool = False) -> list[int]:
        '''One polynomial's record on the record stream (twiddleBuffer 'recycle' / 'double'):
        beats of TL entries (entry l of a beat in bits [l*E, (l+1)*E), E = the entry width,
        a Shoup entry = twiddle | companion << its width). Header (headerBeats beats, beat 0
        in the low bits): bit 0 keep, then the modulus ports (headerLayout). Then, unless
        keep, per stage s: per stored direction, per entry e of the stage's region, per group
        g of TL butterflies, the beat of butterflies g*TL .. g*TL+TL-1.'''
        sch = self.scheme
        if not sch.rns:
            raise ValueError(f'{self.name}: rnsRecord is for twiddleBuffer recycle / double')
        TL, cols = sch.twiddleLanes(), sch.twEntryCols()
        E = sum(cols)
        bw = TL * E
        hv = 1 if keep else 0
        for qp, off, w in sch.headerLayout():
            hv |= (sch.qPortValues(q)[qp] & ((1 << w) - 1)) << off
        HB = sch.headerBeats()
        out = [(hv >> (bw * k)) & ((1 << bw) - 1) for k in range(HB)]
        if keep:
            return out
        B, b, G = sch.B, sch.b, sch.B // TL
        tabs = {kind: [sch.twiddleTable(j, q, kind) for j in range(B)] for kind in ('t', 'c')}

        def entry(j, kind, i):
            w, wp = tabs[kind][j]
            return w[i] | ((wp[i] << cols[0]) if wp is not None else 0)
        for s in range(sch.L):
            for di in range(len(sch.tdirs)):
                if s <= b:
                    idxs, kind = [s + di * sch.cdepth], 'c'
                else:
                    p = s - b - 1
                    idxs, kind = [(1 << (p + 1)) - 2 + e + di * sch.tdepth for e in range(1 << (p + 1))], 't'
                for i in idxs:
                    for g in range(G):
                        v = 0
                        for l in range(TL):
                            v |= entry(g * TL + l, kind, i) << (l * E)
                        out.append(v)
        assert len(out) == sch.recordBeats(False), 'record length'
        return out

    def getOperatorInterface(self, name: str, pipelineStages: int = 1, subRoot=None):
        import dataclasses
        from ntt_spec import StreamNTTSpec
        from ...core.DatapathOperator import datapathSubmodules
        sch = self.scheme
        self.tables = self._tables(pipelineStages)
        modules, stages = {}, []
        # input delay: GS's lead-in (no table read during reset) or, per-frame moduli, the frame lead
        # (the scheme refuses GS with per-frame moduli, so at most one of the two is non-zero)
        leadIn = sch.leadIn(pipelineStages)
        lead = leadIn + sch.frameLead(pipelineStages)
        off = lead
        bound = sch.inputBound
        genLat = sch.generatorLatency(pipelineStages)
        gens = {}
        twist = None

        def twistSpec(at: int) -> dict:
            tm = sch.twistMultiplier
            dps = tm.getOperatorInterface(f'{name}_twist', pipelineStages)
            subs = datapathSubmodules(tm, dps, subRoot / f'{name}_twist') if subRoot is not None else {}
            t = {'datapath': dps, 'submodules': subs, 'tables': self.twistTables, 'otf': sch.twistOtf(),
                 'latency': tm.latency(pipelineStages), 'off': at}
            if sch.twistSide == 'input':
                t['side'] = 'input'
            return t
        if sch.twistMultiplier is not None and sch.twistSide == 'input':
            # GS: the twist (forward psi^k, inverse n^-1) in front of the first stage
            twist = twistSpec(off)
            off += twist['latency']
            bound = sch.twistMultiplier.propagateBound()
        for s, p in enumerate(sch.stagePlan):
            ex = p['exchange']
            exOff = off
            if ex:
                off += ex[2]
            buOff = off
            lat = max(bu.latency(pipelineStages) for bu in sch.butterflies[s])
            slots, constMod, outs = [], {}, []
            for k, (la, lb, _) in enumerate(sch.slots[s]):
                bu = sch.butterflies[s][k]
                c = sch.slotConstant(s, k)
                if c is None:
                    mod = f'{name}_s{s}_bu'
                else:
                    if c not in constMod:
                        constMod[c] = f'{name}_s{s}_c{len(constMod)}'
                    mod = constMod[c]
                if mod not in modules:
                    spec = bu.getOperatorInterface(mod, pipelineStages)
                    if subRoot is not None:
                        spec = dataclasses.replace(spec, submodules=bu.submodules(spec, subRoot / mod))
                    modules[mod] = spec
                src = None
                if c is None:
                    key = sch.classOf[(s, k)]
                    src = self.classTable[key]
                    if src[0] in ('otf', 'rec') and key not in gens:
                        gens[key] = len(gens)
                slots.append({'laneA': la, 'laneB': lb, 'module': mod, 'twiddle': src,
                              'gen': gens.get(sch.classOf.get((s, k))) if c is None and src[0] in ('otf', 'rec') else None,
                              'latency': bu.latency(pipelineStages)})
                outs.append(bu.propagateBound())
            ob = max(max(x.bitWidth, y.bitWidth) for x, y in outs)
            stages.append({'exchange': ex, 'exOff': exOff, 'buOff': buOff, 'buLatency': lat,
                           'inReg': sch.inputRegister, 'halve': sch.stageHalve,
                           'inWidth': bound.bitWidth, 'outWidth': ob, 'slots': slots,
                           'pairLaneBit': p['pairLaneBit']})
            off += lat + sch.inputRegister + sch.stageHalve
            lo = min(min(x.minValue, y.minValue) for x, y in outs)
            hi = max(max(x.maxValue, y.maxValue) for x, y in outs)
            bound = IntType(lo, hi)
        genSpec = None
        if gens or sch.twistOtf():
            g = sch._multiplier(f'{name}_gen', IntType(0, sch.qMax() - 1))
            dps = g.getOperatorInterface(f'{name}_gen', pipelineStages)
            genSpec = {'datapath': dps, 'latency': g.latency(pipelineStages),
                       'submodules': datapathSubmodules(g, dps, subRoot / f'{name}_gen') if subRoot else {}}
        if sch.twistMultiplier is not None and sch.twistSide == 'output':
            twist = twistSpec(off)
            off += twist['latency']
            bound = sch.twistMultiplier.propagateBound()
        reorder = sch.reorderPlan() if hasattr(sch, 'reorderPlan') else None
        if reorder is not None:                 # outputOrder='natural': the reorder stage behind everything
            reorder = dict(reorder, base=off)
            off += reorder['latency']
        if off != sch.latency(pipelineStages):
            raise AssertionError(f'{name}: spec latency {off} != model {sch.latency(pipelineStages)}')
        qports = []
        for qp in sch.qPorts():
            widths = [w for m in modules.values() for (pn, w) in m.extraPorts if pn == qp]
            for d in ([genSpec['datapath']] if genSpec else []) + ([twist['datapath']] if twist else []):
                widths += [w.bitWidth for w in d.inputs if w.name == qp]
            if qp == 'QHALF':                   # (q+1)/2 of the stage halvers (inverseScale='stage')
                widths.append(sch.qMax().bit_length())
            qports.append((qp, max(widths)))
        roms = {'tables': self.tables, 'generator': genSpec, 'generatorLatency': genLat,
                'loadWords': self.loadWords, 'qPorts': qports, 'loadLanes': getattr(self, 'loadLanes', 1),
                'loadByDir': bool(getattr(sch, 'loadDir', False))}
        if sch.twiddleSource == 'rec':
            roms['rec'] = {'D': sch.recDistance(pipelineStages),
                           'k': {g: len(sch.significantBits(k)) for k, g in gens.items()}}
        if sch.twiddleSource == 'stream':
            roms['stream'] = {'classes': sch.streamWordsPerCycle(), 'width': max(1, (sch.qMax() - 1).bit_length())}
        if sch.perFrame:
            roms['perFrame'] = {'moduli': list(sch.moduli), 'indexBits': sch.modulusIndexBits(),
                                'table': sch.modulusTable(), 'lead': lead,
                                'loadable': bool(getattr(sch, 'loadMod', False))}
        if reorder is not None:
            roms['reorder'] = reorder
        return StreamNTTSpec(name=name, n=sch.n, lanes=sch.lanes, frameCycles=sch.F, q=sch.q,
                             direction=sch.direction, dirPort=sch.direction == 'both',
                             inWidth=sch.inputBound.bitWidth, outWidth=bound.bitWidth, latency=off,
                             stages=stages, modules=modules, roms=roms,
                             twist=twist, outputLocation=[sch.outputLocation(m) for m in range(sch.n)],
                             leadIn=leadIn)

    def slotTiming(self, topName: str, run_dir, pipelineStages: int = 1) -> dict:
        '''loadableModuli: the timing of a slot load (StreamingNTTScheme.slotTiming), from the read offset of
        every table. The offsets come from the RTL generator, so the design is generated once without a
        testbench into `run_dir`/_timing.'''
        import os as _os
        from pathlib import Path as _Path
        from rtl_gen.ntt import StreamNTT_RTL_gen
        if getattr(self, '_slotTiming', None) is not None:
            return self._slotTiming
        d = _Path(run_dir).resolve() / '_timing'
        d.mkdir(parents=True, exist_ok=True)
        spec = self.getOperatorInterface(topName, pipelineStages, subRoot=d / '_sub')
        saved = _os.getcwd()
        _os.chdir(str(d))
        try:
            meta = StreamNTT_RTL_gen(spec)
        finally:
            _os.chdir(saved)
        self._slotTiming = self.scheme.slotTiming(meta.get('slot_tables', []), spec.latency, spec.roms['loadWords'])
        return self._slotTiming

    def managedPlan(self, topName: str, run_dir, pipelineStages: int = 1, respond: int = 4) -> dict:
        '''slotManager: the numbers of the design. timing (slotTiming of the core), `lead` (cycles a polynomial
        is announced ahead), `slots` (the least number for any sequence of moduli), `fits` (a load is no longer
        than a frame, so one load per polynomial keeps up).'''
        from rtl_gen.slot_manager import lead_cycles, slots_needed
        tim = self.slotTiming(topName + '_k', run_dir, pipelineStages)
        lead = lead_cycles(tim['before'], tim['words'], respond)
        F = self.scheme.F
        # one load per polynomial keeps up only if a load, with its request and the answer, is shorter than a frame
        return {'timing': tim, 'lead': lead, 'slots': slots_needed(tim['after'], lead, F),
                'fits': tim['words'] <= F, 'frame': F}

    def _emitManaged(self, topName, run_dir, frames, direction, q, pipelineStages) -> dict:
        '''The managed design: core `<topName>_k`, manager `<topName>_slotmgr`, top `<topName>`, and with `frames` a
        testbench that announces every frame's modulus `lead` cycles ahead and answers the load requests.'''
        import os as _os
        from rtl_gen.ntt import StreamNTT_RTL_gen
        from rtl_gen import slot_manager as SM
        sch = self.scheme
        core = topName + '_k'
        plan = self.managedPlan(topName, run_dir, pipelineStages)
        tim, lead, F = plan['timing'], plan['lead'], sch.F
        K = len(sch.moduli)
        if K < plan['slots']:
            raise ValueError(f'{sch.name}: {K} slots, but any sequence of moduli needs {plan["slots"]} '
                             f'(after {tim["after"]}, lead {lead}, frame {F})')
        if not plan['fits']:
            raise ValueError(f'{sch.name}: a load of {tim["words"]} cycles plus its request does not fit a frame of '
                             f'{F}: more load lanes are needed for one load per polynomial')
        spec = self.getOperatorInterface(core, pipelineStages, subRoot=run_dir / '_sub')
        xin = yout = tb = None
        KW = 8
        if frames is not None:
            d = direction or ('inv' if sch.direction == 'inverse' else 'fwd')
            qs = list(q)
            ds = list(d) if isinstance(d, (list, tuple)) else [d] * len(frames)
            pre = -(-(lead + 8) // F) + 1                   # idle frames in front: room for the first announcements
            outs = sch.transform(frames, ds, qs)
            NF = pre + len(frames)
            xin = [[0] * (NF * F) for _ in range(sch.lanes)]
            yout = [[0] * (NF * F) for _ in range(sch.lanes)]
            for f, (fi, fo) in enumerate(zip(frames, outs)):
                for m in range(sch.n):
                    t, l = sch.inputLocation(m)
                    xin[l][(pre + f) * F + t] = fi[m]
                    t, l = sch.portLocation(m) if hasattr(sch, 'portLocation') else sch.outputLocation(m)
                    yout[l][(pre + f) * F + t] = fo[m]
            bd = getattr(sch, 'loadDir', False)
            keyOf, qid = {}, {}
            for x, dd in zip(qs, ds):                       # the outside's own identifiers; by direction: the
                qid.setdefault(x, len(qid) + 1)             # direction is the lowest bit of the key
                keyOf.setdefault((x, dd) if bd else x, ((qid[x] << 1) | sch.dirs.index(dd)) if bd else qid[x])
            tww = max([max(t_['cols']) for t_ in spec.roms['tables'] if t_['mode'] == 'ram'] or [1])
            imgs = list(keyOf)
            zero = {p_: 0 for p_, _ in spec.roms['qPorts']}
            tb = {'dir': 0, 'q': {}, 'midx': [0] * NF, 'dirs': [0] * pre + [1 if x == 'inv' else 0 for x in ds],
                  'mq': [zero] * pre + [sch.qPortValues(x) for x in qs], 'images': imgs, 'loads': [],
                  'load': [sum(w_ << (l_ * tww) for l_, w_ in enumerate(row)) for x in imgs
                           for row in (self.loadRows(*x) if bd else self.loadRows(x))],
                  'pre': pre, 'keys': [-1] * pre + [keyOf[(x, dd) if bd else x] for x, dd in zip(qs, ds)], 'lead': lead,
                  'imageOf': {keyOf[x]: i for i, x in enumerate(imgs)}}
            self.slotRun = {'timing': tim, 'plan': plan, 'keys': tb['keys'], 'distinct': len(keyOf)}
        saved = _os.getcwd()
        _os.chdir(str(run_dir))
        try:
            meta = StreamNTT_RTL_gen(spec, x_in=xin, y_out=yout, tb=tb)
            rtl = 'RTL_generated'
            if tb is not None:
                _os.remove(_os.path.join(rtl, f'{core}_tb.sv'))     # the core's own testbench drives the slots itself
            with open(_os.path.join(rtl, f'{core}.sv')) as f:
                core_sv = f.read()
            mgr = f'{topName}_slotmgr'
            with open(_os.path.join(rtl, f'{mgr}.sv'), 'w') as f:
                f.write(SM.emit_slot_manager(mgr, K, KW, tim['after'], tim['before'], tim['words'], strict=False,
                                                ahead=-(-lead // F)))
            with open(_os.path.join(rtl, f'{topName}.sv'), 'w') as f:
                f.write(SM.emit_managed_stream_top(topName, core, core_sv, mgr, F, KW))
            if tb is not None:
                with open(_os.path.join(rtl, f'{topName}_tb.sv'), 'w') as f:
                    f.write(SM.emit_managed_stream_tb(topName, spec, tb, meta['tw_width'], KW))
            import json as _json
            meta.update(top_name=topName, slots=K, slot_manager=True, lead=lead, slot_after=tim['after'],
                        slot_before=tim['before'], load_cycles=tim['words'])
            with open('manifest.json', 'w') as f:
                _json.dump(meta, f, indent=2)
        finally:
            _os.chdir(saved)
        meta['loadWords'] = spec.roms['loadWords']
        return meta

    def emitRtl(self, topName: str, run_dir, frames=None, direction: str | None = None,
                pipelineStages: int = 1, q: int | None = None) -> dict:
        '''RTL into `run_dir`; with `frames` (memory-order input frames) also a
        testbench and its vectors (goldens from `scheme.transform`), for modulus
        `q` (run time; its twiddles go through the load port first). Per-frame
        moduli: `q` is a list, one modulus of the table per frame (the testbench
        drives each frame's MIDX).'''
        import os as _os
        from pathlib import Path as _Path
        sch = self.scheme
        run_dir = _Path(run_dir).resolve()        # sub-module paths must survive the chdir below
        run_dir.mkdir(parents=True, exist_ok=True)
        ready = bool(getattr(sch, 'outReady', False))      # wrapper <topName> around the core <topName>_k
        if getattr(sch, 'slotMgr', False):                 # the core <topName>_k with its slot manager
            return self._emitManaged(topName, run_dir, frames, direction, q, pipelineStages)
        spec = self.getOperatorInterface(topName + '_k' if ready else topName, pipelineStages, subRoot=run_dir / '_sub')
        xin = yout = None
        if not isinstance(q, (list, tuple)):
            q = q or sch.refQ()
        d = direction or ('inv' if sch.direction == 'inverse' else 'fwd')
        if isinstance(d, (list, tuple)) and not sch.perFrame:
            raise ValueError(f'{sch.name}: a direction per frame needs per-frame moduli')
        if ready:
            return self._emitReady(topName, run_dir, spec, frames, d, q, pipelineStages)
        tb = None
        if frames is not None:
            outs = sch.transform(frames, d, q)
            xin = [[0] * (len(frames) * sch.F) for _ in range(sch.lanes)]
            yout = [[0] * (len(frames) * sch.F) for _ in range(sch.lanes)]
            for f, (fi, fo) in enumerate(zip(frames, outs)):
                for m in range(sch.n):
                    t, l = sch.inputLocation(m)
                    xin[l][f * sch.F + t] = fi[m]
                    t, l = sch.portLocation(m) if hasattr(sch, 'portLocation') else sch.outputLocation(m)
                    yout[l][f * sch.F + t] = fo[m]
            if sch.perFrame:
                qs = q if isinstance(q, (list, tuple)) else [q] * len(frames)
                ds = list(d) if isinstance(d, (list, tuple)) else [d] * len(frames)
                lm = getattr(sch, 'loadMod', False)
                tb = {'dir': 1 if ds[0] == 'inv' else 0, 'q': {}, 'load': [],
                      'midx': [] if lm else [sch.moduli.index(x) for x in qs],
                      'dirs': [1 if x == 'inv' else 0 for x in ds]}
                if lm:
                    # the constants of each frame's modulus come with the frame. The table slots start empty:
                    # every modulus reaches them through the load port, a slot is filled while frames of other
                    # slots run, and the load follows the data (StreamingNTTScheme.slotTiming, slotPlan)
                    tim = self.slotTiming(topName, run_dir, pipelineStages)
                    bd = getattr(sch, 'loadDir', False)
                    keys = [(x, dd) for x, dd in zip(qs, ds)] if bd else list(qs)   # what a slot holds
                    slots, loads = sch.slotPlan(keys, tim)
                    imgs = []
                    for _, _, x in loads:
                        if x not in imgs:
                            imgs.append(x)
                    tb['midx'] = slots
                    tb['mq'] = [sch.qPortValues(x) for x in qs]
                    tb['images'] = imgs
                    tww = max([max(t_['cols']) for t_ in spec.roms['tables'] if t_['mode'] == 'ram'] or [1])
                    tb['load'] = [sum(w_ << (l_ * tww) for l_, w_ in enumerate(row))    # one wide word per cycle
                                  for x in imgs for row in (self.loadRows(*x) if bd else self.loadRows(x))]
                    tb['loads'] = [(c, k, imgs.index(x)) + ((sch.dirs.index(x[1]),) if bd else ())
                                   for c, k, x in loads]
                    self.slotRun = {'timing': tim, 'slots': slots, 'loads': loads}
                if sch.twiddleSource == 'stream':
                    tb['stream'] = [c for fr in sch.streamImage(qs, d) for c in fr]    # per cycle, per class
            else:
                tb = {'dir': 1 if d == 'inv' else 0, 'q': sch.qPortValues(q) if sch.runtime else {},
                      'load': self.loadImage(q) if spec.roms['loadWords'] else []}
        from rtl_gen.ntt import StreamNTT_RTL_gen
        saved = _os.getcwd()
        _os.chdir(str(run_dir))
        try:
            meta = StreamNTT_RTL_gen(spec, x_in=xin, y_out=yout, tb=tb)
        finally:
            _os.chdir(saved)
        meta['loadWords'] = spec.roms['loadWords']
        return meta

    def _emitReady(self, topName, run_dir, spec, frames, d, q, pipelineStages) -> dict:
        '''outReady=True: the core `<topName>_k`, the wrapper `<topName>` and (with `frames`) a testbench
        driven cycle by cycle from the twin `scheme.readyRun`: in_valid and out_ready follow a fixed pattern
        (free flow, output stalled until the credit runs out, both random, free flow), the slots that carry
        no polynomial carry random data and tags; in_ready, out_valid and every valid beat are checked on
        every cycle. With the default depth the free-flow part must take one polynomial per slot.'''
        import os as _os
        import random as _random
        sch = self.scheme
        P, F = sch.lanes, sch.F
        plan = sch.readyPlan(pipelineStages)
        stim = None
        if frames is not None:
            nf = len(frames)
            outs = sch.transform(frames, d, q)
            beats = [[0] * P for _ in range(nf * F)]
            for f, fo in enumerate(outs):
                for m in range(sch.n):
                    t, l = sch.portLocation(m)
                    beats[f * F + t][l] = fo[m]
            D, LAT = plan['depth'], plan['latency']
            rng = _random.Random(5)
            T1 = max(1, nf // 3) * F + F // 2
            T2 = T1 + (min(D, nf) + 2) * F
            T3 = T2 + 2 * nf * F
            # below the default depth the core takes D polynomials per round trip, not one per slot
            N = T3 + (nf * sch.readyMinDepth(pipelineStages) + D + 4) * F + LAT + 8
            iv = [1 if (c < T2 or c >= T3) else int(rng.random() < 0.7) for c in range(N)]
            ordy = [1 if (c < T1 or c >= T3) else (0 if c < T2 else int(rng.random() < 0.5)) for c in range(N)]
            st = sch.readyRun(beats, iv, ordy, pipelineStages, polys=nf)
            pops = [c for c in range(N) if st['outValid'][c] and ordy[c]]
            assert st['accepted'] == nf and len(pops) == nf * F, f'{sch.name}: the test pattern does not drain'
            assert [st['out'][c] for c in pops] == beats, f'{sch.name}: twin output order'
            first = next(c for c in range(N) if st['outValid'][c])
            assert first == plan['outLatency'], f'{sch.name}: free-flow latency {first} != {plan["outLatency"]}'
            if D >= sch.readyMinDepth(pipelineStages):       # rate: one polynomial per slot while free
                k = min(nf, T1 // F)
                assert all(st['accept'][j * F] for j in range(k)), f'{sch.name}: a free-flow slot was not taken'
            N = (pops[-1] // F + 2) * F
            slots = N // F
            accSlot, a = [], 0
            for k in range(slots):
                if st['accept'][k * F]:
                    accSlot.append(a); a += 1
                else:
                    accSlot.append(None)
            xs = [[0] * N for _ in range(P)]
            for k, a in enumerate(accSlot):
                if a is None:
                    for l in range(P):
                        for t in range(F):
                            xs[l][k * F + t] = rng.getrandbits(spec.inWidth)
                else:
                    for m in range(sch.n):
                        t, l = sch.inputLocation(m)
                        xs[l][k * F + t] = frames[a][m]
            ys = [[(st['out'][c][l] if st['outValid'][c] else 0) for c in range(N)] for l in range(P)]
            stim = {'cycles': N, 'x': xs, 'y': ys, 'iv': st['inValid'][:N], 'ordy': ordy[:N],
                    'ir': st['inReady'][:N], 'ov': st['outValid'][:N], 'static': {}, 'perCycle': {}}
            if sch.perFrame:
                qs = q if isinstance(q, (list, tuple)) else [q] * nf
                ds = list(d) if isinstance(d, (list, tuple)) else [d] * nf
                sq = [qs[a] if a is not None else rng.choice(sch.moduli) for a in accSlot]
                sd = [ds[a] if a is not None else (rng.choice(('fwd', 'inv')) if sch.direction == 'both' else ds[0])
                      for a in accSlot]
                stim['perCycle']['MIDX'] = [sch.moduli.index(sq[c // F]) for c in range(N)]
                if spec.dirPort:
                    stim['perCycle']['DIR'] = [1 if sd[c // F] == 'inv' else 0 for c in range(N)]
                if sch.twiddleSource == 'stream':
                    rows = [c for fr in sch.streamImage(sq, sd) for c in fr]
                    for cls in range(sch.streamWordsPerCycle()):
                        stim['perCycle'][f'tw_s{cls}'] = [rows[c][cls] for c in range(N)]
            else:
                if spec.dirPort:
                    stim['static']['DIR'] = 1 if d == 'inv' else 0
                if sch.runtime:
                    stim['static'].update(sch.qPortValues(q))
                if spec.roms['loadWords']:
                    stim['load'] = self.loadImage(q)
        from rtl_gen.ntt import StreamNTT_RTL_gen, StreamReady_RTL_gen
        saved = _os.getcwd()
        _os.chdir(str(run_dir))
        try:
            StreamNTT_RTL_gen(spec)
            meta = StreamReady_RTL_gen(topName, spec, plan, stim)
        finally:
            _os.chdir(saved)
        meta['loadWords'] = spec.roms['loadWords']
        return meta
