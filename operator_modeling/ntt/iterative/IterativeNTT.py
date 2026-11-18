'''The iterative NTT operator: the RTL spec and the emitted core of an `IterativeNTTScheme`.'''
from __future__ import annotations

from ..butterfly.ButterflyScheme import ButterflyScheme  # noqa: F401  (puts versal_arith on sys.path)


class IterativeNTT:
    '''The operator over an `IterativeNTTScheme`: builds the RTL spec and emits the
    core (`rtl_gen.iter_ntt.IterNTT_RTL_gen`).

    RTL ports (versal_arith/docs/USAGE.md, "Iterative NTT"): `clk`, `rst`, [`DIR`],
    [the run-time modulus inputs `qPorts()`, quasi-static], [`tw_rst`, `tw_wen`,
    `tw_wdata`: the twiddle load port, as the streaming NTT's, words in the order of
    `loadImage(q)`], `in_valid`, `in_ready`, `x_in_<l>` (l < ioLanes), `out_valid`,
    `y_out_<l>`. A polynomial enters as n/ioLanes beats in memory order (beat k lane l
    = memory index k*ioLanes + l; a beat moves when in_valid and in_ready), and leaves
    as n/ioLanes consecutive out_valid beats in memory order (CT: natural order); no
    backpressure on the output.'''

    def __init__(self, scheme):
        self.scheme = scheme
        self.name = scheme.name

    def _tables(self):
        sch = self.scheme
        q0 = sch.refQ()
        bu = sch.butterflyUnit()
        ext = dict(bu.getOperatorInterface('probe', 1).extraPorts)
        mode = 'ram' if (sch.runtime and not sch.multiRom) or sch.twiddleSource == 'ram' else 'rom'
        tabs, base = [], 0
        mr = sch.multiRom

        def romValues(d1, fn):
            '''A ROM's columns: fn(q) -> (w, wp or None). moduli=: per modulus a block of 2^ceil(log2 d1)
            entries (address {MIDX, the one-modulus address}).'''
            if not mr:
                w, wp = fn(q0)
                return [w] + ([wp] if wp is not None else [])
            blk = 1 << max(1, (d1 - 1).bit_length())
            cols = None
            for qq in sch.moduli:
                w, wp = fn(qq)
                cs = [w] + ([wp] if wp is not None else [])
                assert all(len(c) == d1 for c in cs), 'table depth'
                cols = cols or [[] for _ in cs]
                for c, v in zip(cols, cs):
                    c += list(v) + [0] * (blk - d1)
            return cols
        if sch.rns:
            mode = 'rns'                 # written from the record stream (rnsRecord), any time
        if sch.memOrg == 'constgeo':     # one table per butterfly, every stage's region (cgTwiddleIndex)
            for j in range(sch.B):
                depth = sch.tdepth * sch.twDirs()
                w, wp = sch.twiddleTable(j, q0, 't', 'fwd' if sch.direction != 'inverse' else 'inv')
                cols = [ext['W']] + ([ext['WP']] if wp is not None else [])
                t = {'use': 'bu', 'kind': 't', 'j': j, 'depth': depth, 'cols': cols, 'mode': mode,
                     'values': ([w] + ([wp] if wp is not None else [])) if mode == 'rom' else None}
                if mr:
                    cgd = 'fwd' if sch.direction != 'inverse' else 'inv'
                    t.update(depth1=depth, depth=sch.mromDepth(depth),
                             values=romValues(depth, lambda qq, j=j: sch.twiddleTable(j, qq, 't', cgd)))
                if mode == 'ram':
                    t['base'] = base
                    base += depth * len(cols)
                tabs.append(t)
        for j in range(sch.B if sch.memOrg != 'constgeo' else 0):
            for kind, d1 in (('t', sch.tdepth), ('c', sch.cdepth)):
                depth = d1 * len(sch.tdirs)
                w, wp = sch.twiddleTable(j, q0, kind)
                cols = [ext['W']] + ([ext['WP']] if wp is not None else [])
                t = {'use': 'bu', 'kind': kind, 'j': j, 'depth': depth, 'cols': cols, 'mode': mode,
                     'values': ([w] + ([wp] if wp is not None else [])) if mode == 'rom' else None}
                if mr:
                    t.update(depth1=depth, depth=sch.mromDepth(depth),
                             values=romValues(depth, lambda qq, j=j, kind=kind: sch.twiddleTable(j, qq, kind)))
                if mode == 'ram':
                    t['base'] = base
                    base += depth * len(cols)
                tabs.append(t)
        twist = []
        if sch.twistMultiplier is not None:
            tmode = 'ram' if (sch.runtime and not mr) else 'rom'
            if sch.rns:
                tmode = 'rns'            # two copies of one direction, written from each polynomial's record
            W = max(1, (sch.qMax() - 1).bit_length())
            for l in range(sch.io):
                t = {'use': 'twist', 'lane': l, 'depth': sch.beats * (2 if sch.rns else len(sch.dirs)), 'cols': [W],
                     'mode': tmode, 'values': [sch.twistTable(l, q0)] if tmode == 'rom' else None}
                if mr:
                    t.update(depth1=t['depth'], depth=sch.mromDepth(t['depth']),
                             values=romValues(t['depth'], lambda qq, l=l: (sch.twistTable(l, qq), None)))
                if tmode == 'ram':
                    t['base'] = base
                    base += t['depth']
                twist.append(t)
        self.loadWords = base
        return tabs, twist

    def loadImage(self, q: int) -> list[int]:
        '''The words to write through the twiddle load port for modulus q, in order.'''
        sch = self.scheme
        tabs, twist = self._tables()
        out = []
        for t in tabs:
            if t['mode'] == 'ram':
                w, wp = sch.twiddleTable(t['j'], q, t['kind'])
                out += w + (wp if wp is not None else [])
        for t in twist:
            if t['mode'] == 'ram':
                out += sch.twistTable(t['lane'], q)
        return out

    def _rnsRecordCg(self, q: int, keep: bool, direction: str | None) -> list[int]:
        '''Constant geometry: the header as in place, then per stage s, per entry e of its region
        (cgDepths[s] entries from cgBases[s]), per group g of TL butterflies, the beat; only the job's
        direction (the tables hold one).'''
        sch = self.scheme
        d = direction or ('inv' if sch.direction == 'inverse' else 'fwd')
        TL, cols = sch.twiddleLanes(), sch.twEntryCols()
        E = sum(cols)
        bw = TL * E
        hv = 1 if keep else 0
        for qp, off, w in sch.headerLayout():
            if qp == 'DIR':                 # dirPerPoly: the polynomial's direction
                hv |= (1 if d == 'inv' else 0) << off
                continue
            hv |= (sch.qPortValues(q)[qp] & ((1 << w) - 1)) << off
        if sch.rec:                  # 'rec': the factors of the late regions follow the modulus constants
            F = sch.recFactors(q, d)
            for j, beta, off, w in sch.recFactorLayout():
                hv |= (F[(j, beta)] & ((1 << w) - 1)) << off
        out = [(hv >> (bw * k)) & ((1 << bw) - 1) for k in range(sch.headerBeats())]
        if keep:
            return out
        tabs = [sch.twiddleTable(j, q, 't', d) for j in range(sch.B)]
        if sch.rec:                  # regions 0 .. H+1, a beat per entry: lane 0 butterfly 0, lane 1 butterfly B/2
            for s in range(sch.recStreamRegions()):
                for e in range(sch.cgDepths[s]):
                    i = sch.cgBases[s] + e
                    out.append(tabs[0][0][i] | (tabs[sch.B // 2][0][i] << E))
            assert len(out) == sch.recordBeats(False), 'record length'
            return out
        for s in range(sch.L):
            for e in range(sch.cgDepths[s]):
                i = sch.cgBases[s] + e
                for g in range(sch.B // TL):
                    v = 0
                    for l in range(TL):
                        w, wp = tabs[g * TL + l]
                        v |= (w[i] | ((wp[i] << cols[0]) if wp is not None else 0)) << (l * E)
                    out.append(v)
        assert len(out) == sch.recordBeats(False), 'record length'
        return out

    def rnsRecord(self, q: int, keep: bool = False, direction: str | None = None) -> list[int]:
        '''One polynomial's record on the record stream (twiddleBuffer 'recycle' / 'double'):
        beats of TL entries (entry l of a beat in bits [l*E, (l+1)*E), E = the entry width,
        a Shoup entry = twiddle | companion << its width). Header (headerBeats beats, beat 0
        in the low bits): bit 0 keep, then the modulus ports (headerLayout). Then, unless
        keep, per stage s: per stored direction, per entry e of the stage's region, per group
        g of TL butterflies, the beat of butterflies g*TL .. g*TL+TL-1.'''
        sch = self.scheme
        if not sch.rns:
            raise ValueError(f'{self.name}: rnsRecord is for twiddleBuffer recycle / double')
        if sch.memOrg == 'constgeo':
            return self._rnsRecordCg(q, keep, direction)
        TL, cols = sch.twiddleLanes(), sch.twEntryCols()
        E = sum(cols)
        bw = TL * E
        hv = 1 if keep else 0
        for qp, off, w in sch.headerLayout():
            if qp == 'DIR':                 # dirPerPoly: the polynomial's direction
                hv |= (1 if (direction or ('inv' if sch.direction == 'inverse' else 'fwd')) == 'inv' else 0) << off
                continue
            hv |= (sch.qPortValues(q)[qp] & ((1 << w) - 1)) << off
        if sch.rec:                  # 'rec' in place: the factors and the stage seeds; no data beats
            F = sch.recFactors(q, direction or sch.tdirs[0])
            for tag, i, off, w in sch.recFactorLayout():
                hv |= (F[(tag, i)] & ((1 << w) - 1)) << off
        HB = sch.headerBeats()
        out = [(hv >> (bw * k)) & ((1 << bw) - 1) for k in range(HB)]
        if sch.rec and not keep and sch.recSeedCount():
            # 'rec' in place with seeds (recSeeds): per stage, per seeded entry y of a group's region, per pair
            # m of groups one beat: lane 0 = group 2m's entry, lane 1 = group 2m+1's (one group: lane 0 only)
            pl = sch.recIpPlan()
            SW = sch.recSeedWords(q)
            NG = sch.B // pl['G']
            for s in range(sch.L):
                for y in range(pl['kk'][s]):
                    for m in range(pl['NGP']):
                        out.append(SW[s][y][2 * m] | ((SW[s][y][2 * m + 1] << E) if NG > 1 else 0))
            assert len(out) == sch.recordBeats(False), 'record length'
        if sch.rec:                  # ('rec' with the output twist is refused: no twist region)
            return out
        if keep:
            return out + self._rnsTwist(q, direction)
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
        out += self._rnsTwist(q, direction)
        assert len(out) == sch.recordBeats(False), 'record length'
        return out

    def _rnsTwist(self, q: int, direction: str | None) -> list[int]:
        '''The record's twist region (output twist in an RNS mode; empty otherwise): the n twist factors of the
        job's direction in memory order (m = k io + l: beat k of output lane l), TT = min(TL, io) a beat, entry t
        of a beat in bits [t E, t E + E).'''
        sch = self.scheme
        if not (sch.rns and sch.twistOn):
            return []
        d = direction or ('inv' if sch.direction == 'inverse' else 'fwd')
        TL, E, io = sch.twiddleLanes(), sch.twEntryWidth(), sch.io
        TT = min(TL, io)
        lanes = [sch.twistTableRns(l, q, d) for l in range(io)]
        out = []
        for j in range(sch.n // TT):
            v = 0
            for t in range(TT):
                g = j * TT + t
                v |= lanes[g % io][g // io] << (t * E)
            out.append(v)
        return out

    def getOperatorInterface(self, name: str, pipelineStages: int = 1, subRoot=None):
        import dataclasses
        from ntt_spec import IterNTTSpec
        from ...core.DatapathOperator import datapathSubmodules
        sch = self.scheme
        self._subRoot, self._topName = subRoot, name
        errs = sch.checkGeometry() if (sch.n <= 4096 or sch.memOrg == 'constgeo' and sch.n <= 32768) else []
        errs += sch.checkHazards(pipelineStages)
        if errs:
            raise AssertionError(f'{name}: schedule check failed: {errs[:3]}')
        bu = sch.butterflyUnit()
        mod = f'{name}_bu'
        bs = bu.getOperatorInterface(mod, pipelineStages)
        if subRoot is not None:
            bs = dataclasses.replace(bs, submodules=bu.submodules(bs, subRoot / mod))
        tabs, twistTabs = self._tables()
        twist = None
        if sch.twistMultiplier is not None:
            tm = sch.twistMultiplier
            dps = tm.getOperatorInterface(f'{name}_twist', pipelineStages)
            subs = datapathSubmodules(tm, dps, subRoot / f'{name}_twist') if subRoot is not None else {}
            twist = {'datapath': dps, 'submodules': subs, 'latency': tm.latency(pipelineStages), 'tables': twistTabs}
        qports = []
        for qp in sch.qPorts():
            widths = [w for (pn, w) in bs.extraPorts if pn == qp]
            if twist:
                widths += [w.bitWidth for w in twist['datapath'].inputs if w.name == qp]
            if qp == 'QHALF':
                widths.append(sch.qMax().bit_length())
            if sch.genMultiplier is not None and qp in sch.genPortWidths():
                widths.append(sch.genPortWidths()[qp])
            qports.append((qp, max(widths)))
        if sch.memOrg == 'constgeo':
            rs, ws, rdec, wdec = (), (), (), ()
        else:
            rs, ws = sch.readSources()
            rdec, wdec = sch.decodeTables()
        mems = {m['what']: m['style'] for m in sch.memories()}
        T = sch.T
        return IterNTTSpec(name=name, n=sch.n, B=sch.B, L=sch.L, b=sch.b, H=sch.H, io=sch.io, beats=sch.beats,
                           q=sch.q, direction=sch.direction, dirPort=sch.direction == 'both' and not sch.dirPerPoly,
                           width=sch.memBound.bitWidth, outWidth=sch.outputBound.bitWidth, R=sch.R,
                           buLatency=sch.buLatency(pipelineStages), writeLatency=sch.writeLatency(pipelineStages),
                           outLatency=sch.outLatency(pipelineStages),
                           gaps=tuple(x - T for x in sch.stageOffsets(pipelineStages)) + (0,),
                           halve=sch.stageHalve, bu=bs, readSources=tuple(tuple(x) for x in rs),
                           writeSources=tuple(tuple(x) for x in ws), readDecode=tuple(rdec),
                           writeDecode=tuple(wdec), tables=tuple(tabs), tdepth=sch.tdepth,
                           cdepth=sch.cdepth, shareInv=sch.shareInv, loadWords=self.loadWords, qPorts=tuple(qports), memStyle=mems['data bank'],
                           twiddleStyle=mems['twiddle table'], twist=twist, **self._rnsSpec(qports, pipelineStages),
                           **self._cgSpec(), **self._mromSpec(pipelineStages))

    def _mromSpec(self, pipelineStages) -> dict:
        '''moduli= (multi-modulus ROM): the index width, the constants per modulus, the switch.'''
        sch = self.scheme
        if not sch.multiRom:
            return {}
        return dict(qInline=sch.qInline,
                    mrom=dict(moduli=tuple(sch.moduli), bits=sch.modulusIndexBits(),
                              table={p: tuple(v) for p, v in sch.modulusTable().items()},
                              bubble=sch.Rx() + sch.xr + sch.buLatency(pipelineStages)))

    def _cgSpec(self) -> dict:
        sch = self.scheme
        if sch.memOrg != 'constgeo':
            return {}
        ft = {}
        if sch.fanout:               # the fan-out trees (IterativeNTTScheme.fanoutPlan)
            ft = dict(fanout=dict(F=sch.fanout, readTree=sch.readTree(), genTree=sch.genTree(), keepSinks=sch.fanoutKeep,
                                  levels={k: tuple(v['levels']) for k, v in sch.fanoutPlan().items()}))
        return dict(**ft, memOrg='constgeo', crossRegs=sch.xr, cgShifts=tuple(sch.cgShift(s) for s in range(sch.L)),
                    twBases=tuple(sch.cgBases), twDepths=tuple(sch.cgDepths),
                    memOrgReport=sch._memOrgReport and {k: sch._memOrgReport[k] for k in ('choice', 'reason')})

    def _rnsSpec(self, qports, pipelineStages) -> dict:
        sch = self.scheme
        if not sch.rns:
            return {}
        if list(qports) != list(sch.qPortWidths()):
            raise AssertionError(f'{self.name}: the header layout disagrees with the modulus ports')
        out = dict(twiddleBuffer=sch.twiddleBuffer, twLanes=sch.twiddleLanes(pipelineStages),
                   twEntryCols=tuple(sch.twEntryCols()), headerBeats=sch.headerBeats(),
                   headerLayout=tuple(sch.headerLayout()), stageBeats=tuple(sch.stageBeats()),
                   qBubble=sch.Rx() + sch.xr + sch.buLatency(pipelineStages),
                   dirPerPoly=sch.dirPerPoly, qInline=sch.qInline,
                   **(dict(twistBeats=sch.twistBeats(), twistLanes=min(sch.twiddleLanes(pipelineStages), sch.io))
                      if sch.twistOn else {}))
        if sch.rec:
            out['rec'] = self._recSpec(pipelineStages)
        return out

    def _recSpec(self, pipelineStages) -> dict:
        '''twiddleSource 'rec': what IterNTT_CG_RTL_gen builds the on-chip twiddle supply from.'''
        from ...core.DatapathOperator import datapathSubmodules
        sch = self.scheme
        G = sch.recGroup(pipelineStages)
        if sch.recIp:                # in place: every region generated (IterativeNTTScheme.recIpPlan)
            gm = sch.genMultiplier
            dps = gm.getOperatorInterface(f'{self._topName}_gen', pipelineStages)
            subs = datapathSubmodules(gm, dps, self._subRoot / f'{self._topName}_gen') if self._subRoot is not None else {}
            return dict(inplace=True, group=G, units=len(sch.recUnits(pipelineStages, G)),
                        genLatency=sch.recWriteLatency(pipelineStages), streamBeats=sch.recStreamBeats(pipelineStages),
                        factorLayout=tuple(sch.recFactorLayout()), plan=sch.recIpPlan(pipelineStages, G),
                        gen={'datapath': dps, 'submodules': subs, 'latency': gm.latency(pipelineStages)})
        gen = None
        if sch.L > sch.H + 2:
            gm = sch.genMultiplier
            dps = gm.getOperatorInterface(f'{self._topName}_gen', pipelineStages)
            subs = datapathSubmodules(gm, dps, self._subRoot / f'{self._topName}_gen') if self._subRoot is not None else {}
            gen = {'datapath': dps, 'submodules': subs, 'latency': gm.latency(pipelineStages)}
        units = sch.recUnits(pipelineStages)
        return dict(group=G, units=tuple(units), genLatency=sch.recWriteLatency(pipelineStages),
                    streamRegions=sch.recStreamRegions(), streamBeats=sch.recStreamBeats(),
                    factorLayout=tuple(sch.recFactorLayout()), classes=tuple(sch.recClasses(j, G) if j >= 2 else 1
                                                                                for j in range(sch.b + 1)),
                    gen=gen)

    def emitRtl(self, topName: str, run_dir, frames=None, direction: str | None = None,
                pipelineStages: int = 1, q=None, validPattern=None, seed: int = 5, records=None,
                twValidPattern=None) -> dict:
        '''RTL into `run_dir`; with `frames` (memory-order polynomials) also a testbench
        that streams them back to back (`validPattern`: None = always valid, 'random'
        = a seeded random valid, or a function of the cycle), checks every output beat's
        value (goldens from `scheme.transform`) and its cycle (from `scheme.simulateJob`).
        RNS modes: `q` one modulus or one per frame, `records` per frame True = keep the
        previous modulus (default: a record with its modulus wherever q changes), and
        `twValidPattern` (None, 'random' or a function) the record stream's valid.'''
        import os as _os
        import random as _random
        from pathlib import Path as _Path
        sch = self.scheme
        run_dir = _Path(run_dir).resolve()
        run_dir.mkdir(parents=True, exist_ok=True)
        spec = self.getOperatorInterface(topName, pipelineStages, subRoot=run_dir / '_sub')
        q = q or sch.refQ()
        d = direction or ('inv' if sch.direction == 'inverse' else 'fwd')
        # (merge fix: k1_dataflow's guard refused every list here, also iter_fixes' dirPerPoly jobs; with a record
        # stream `_emitRns` checks the list itself: one direction unless dirPerPoly)
        if isinstance(d, (list, tuple)) and not (sch.perFrame or sch.rns or sch.multiRom):
            raise ValueError(f'{sch.name}: a direction per frame needs per-frame moduli')
        tb = None
        if frames is not None and sch.rns:
            return self._emitRns(spec, run_dir, frames, d, pipelineStages, q, validPattern, seed, records,
                                 twValidPattern)
        if frames is not None and sch.multiRom:
            return self._emitMrom(spec, run_dir, frames, d, pipelineStages, q, validPattern, seed)
        if frames is not None:
            if validPattern == 'random':
                rng = _random.Random(seed)
                bits = [rng.random() < 0.7 for _ in range(1 << 20)]
                valid = lambda c: bits[c % len(bits)]
            elif validPattern is None:
                valid = lambda c: True
            else:
                valid = validPattern
            job = sch.simulateJob(len(frames), valid, pipelineStages)
            outs = sch.transform(frames, d, q)
            ncyc = job['out'][-1][-1] + 16
            tb = {'dir': 1 if d == 'inv' else 0, 'q': sch.qPortValues(q) if sch.runtime else {},
                  'load': self.loadImage(q) if spec.loadWords else [],
                  'x': [[fr[k * sch.io + l] for l in range(sch.io)] for fr in frames for k in range(sch.beats)],
                  'y': [[fo[k * sch.io + l] for l in range(sch.io)] for fo in outs for k in range(sch.beats)],
                  'ycycle': [c for p in job['out'] for c in p], 'valid': [1 if valid(c) else 0 for c in range(ncyc)],
                  'cycles': ncyc}
            self.job = job
        from rtl_gen.iter_ntt import IterNTT_RTL_gen
        saved = _os.getcwd()
        _os.chdir(str(run_dir))
        try:
            meta = IterNTT_RTL_gen(spec, tb=tb)
        finally:
            _os.chdir(saved)
        if frames is not None:
            meta.update(latency=self.job['latency'], interval=self.job['interval'], jobCycles=self.job['jobCycles'])
        return meta

    def _emitMrom(self, spec, run_dir, frames, d, pipelineStages, q, validPattern, seed):
        '''moduli=: the testbench drives MIDX (and DIR with direction 'both') with each polynomial's first
        beat (don't-care values on the other beats), checks every output beat's value, cycle (the twin) and
        tag (midx_out, dir_out), and the cycles between the first output beats of successive polynomials
        against the twin's largest interval.'''
        import os as _os
        import random as _random
        sch = self.scheme
        P = len(frames)
        qs = list(q) if isinstance(q, (list, tuple)) else [q] * P
        ds = list(d) if isinstance(d, (list, tuple)) else [d] * P
        if len(qs) != P or len(ds) != P:
            raise ValueError(f'{self.name}: one modulus and one direction per frame')
        for qq in qs:
            if qq not in sch.moduli:
                raise ValueError(f'{self.name}: {qq} is not one of moduli=')
        for dd in ds:
            if dd not in sch.dirs:
                raise ValueError(f'{self.name}: direction {dd!r} not built')
        if validPattern == 'random':
            rng = _random.Random(seed)
            bits = [rng.random() < 0.7 for _ in range(1 << 20)]
            valid = lambda c: bits[c % len(bits)]
        elif validPattern is None:
            valid = lambda c: True
        else:
            valid = validPattern
        job = sch.simulateJob(P, valid, pipelineStages, tags=list(zip(qs, ds)))
        outs = sch.transform(frames, ds, qs)
        ncyc = job['out'][-1][-1] + 16
        tb = {'dir': 1 if ds[0] == 'inv' else 0, 'q': {}, 'load': [],
              'midx': [sch.moduli.index(qq) for qq in qs], 'dirs': [1 if dd == 'inv' else 0 for dd in ds],
              'x': [[fr[k * sch.io + l] for l in range(sch.io)] for fr in frames for k in range(sch.beats)],
              'y': [[fo[k * sch.io + l] for l in range(sch.io)] for fo in outs for k in range(sch.beats)],
              'ycycle': [c for p in job['out'] for c in p], 'valid': [1 if valid(c) else 0 for c in range(ncyc)],
              'cycles': ncyc}
        if job['interval'] is not None:
            tb['interval'] = job['interval']
        self.job = job
        from rtl_gen.iter_ntt import IterNTT_RTL_gen
        saved = _os.getcwd()
        _os.chdir(str(run_dir))
        try:
            meta = IterNTT_RTL_gen(spec, tb=tb)
        finally:
            _os.chdir(saved)
        meta.update(latency=job['latency'], interval=job['interval'], jobCycles=job['jobCycles'],
                    starts=job['starts'], firstOut=[p[0] for p in job["out"]], frameModuli=qs, directions=ds)
        return meta

    def _emitRns(self, spec, run_dir, frames, d, pipelineStages, q, validPattern, seed, records, twValidPattern):
        import os as _os
        import random as _random
        sch = self.scheme
        P = len(frames)
        qs = list(q) if isinstance(q, (list, tuple)) else [q] * P
        ds = list(d) if isinstance(d, (list, tuple)) else [d] * P
        if len(ds) != P:
            raise ValueError(f'{self.name}: one direction per frame')
        if len(set(ds)) > 1 and not sch.dirPerPoly:
            raise ValueError(f'{self.name}: a direction per polynomial needs dirPerPoly=True')
        if records is None:
            records = [k > 0 and qs[k] == qs[k - 1] and ds[k] == ds[k - 1] for k in range(P)]
        records = [bool(x) for x in records]
        for k in range(1, P):
            if records[k] and (qs[k] != qs[k - 1] or ds[k] != ds[k - 1]):
                raise ValueError(f'{self.name}: polynomial {k} keeps the record but has another q or direction')

        def pattern(pat, sd):
            if pat == 'random':
                rng = _random.Random(sd)
                bits = [rng.random() < 0.7 for _ in range(1 << 20)]
                return lambda c: bits[c % len(bits)]
            return pat if pat is not None else (lambda c: True)
        valid, twv = pattern(validPattern, seed), pattern(twValidPattern, seed + 1)
        job = sch.simulateJob(P, valid, pipelineStages, records=records, twValid=twv)
        errs = sch.checkTwiddleWindows(job, pipelineStages)
        if errs:
            raise AssertionError(f'{self.name}: twiddle windows: {errs[:3]}')
        outs = sch.transform(frames, ds, qs)
        if sch.rec:                  # the on-chip tables, bit-exact through the generator datapath == the model's
            for qq in sorted(set(qs)):       # ('rec' has no dirPerPoly: one direction for the job, ds[0])
                sch.recTables(qq, ds[0])
        stream = []
        for k in range(P):
            stream += self.rnsRecord(qs[k], records[k], ds[k])
        assert len(stream) == job['twBeats']
        ncyc = job['out'][-1][-1] + 16
        tb = {'dir': 1 if ds[0] == 'inv' else 0, 'q': {}, 'load': [], 'tw': stream,
              'twvalid': [1 if twv(c) else 0 for c in range(ncyc)],
              'x': [[fr[k * sch.io + l] for l in range(sch.io)] for fr in frames for k in range(sch.beats)],
              'y': [[fo[k * sch.io + l] for l in range(sch.io)] for fo in outs for k in range(sch.beats)],
              'ycycle': [c for p in job['out'] for c in p], 'valid': [1 if valid(c) else 0 for c in range(ncyc)],
              'cycles': ncyc}
        if sch.recIp and job['interval'] is not None:      # the rate check: cycles from one polynomial's first
            tb['interval'] = job['interval']                # output beat to the next one's, at most the twin's
        self.job = job
        from rtl_gen.iter_ntt import IterNTT_RTL_gen
        saved = _os.getcwd()
        _os.chdir(str(run_dir))
        try:
            meta = IterNTT_RTL_gen(spec, tb=tb)
        finally:
            _os.chdir(saved)
        meta.update(latency=job['latency'], interval=job['interval'], jobCycles=job['jobCycles'],
                    records=records, moduli=qs)
        return meta
