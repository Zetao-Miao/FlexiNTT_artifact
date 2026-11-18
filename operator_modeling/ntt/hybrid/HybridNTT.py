'''The hybrid NTT operator: the RTL spec, the testbench data, emission
(`rtl_gen.hybrid_ntt.HybridNTT_RTL_gen`). The model is `HybridNTTScheme`.

RTL ports: `clk`, `rst`, `in_valid`, `in_ready`, [`MIDX` (moduli > 1), `DIR` (direction 'both')]:
sampled with the first beat of each polynomial, `x_in_<l>` (l < W), `out_valid`, [`midx_out`,
`dir_out`: the tags of the output beat], `y_out_<l>`. A polynomial enters as T = n/W beats (beat c
lane l = the memory index at position c W + l: `scheme.inputLocation`), leaves as T consecutive
out_valid beats (`scheme.outputLocation`); no backpressure on the output.
'''
from __future__ import annotations

import os
import random
from pathlib import Path


class HybridNTT:
    def __init__(self, scheme):
        self.scheme = scheme
        self.name = scheme.name

    def latency(self, pipelineStages: int = 1) -> int:
        '''One polynomial alone: first input beat to last output beat (the controller twin).'''
        return self.scheme.latency(pipelineStages)

    def resources(self, pipelineStages: int = 1) -> dict:
        return self.scheme.resources(pipelineStages)

    def getOperatorInterface(self, name: str, pipelineStages: int = 1, subRoot=None) -> dict:
        import dataclasses
        from ...core.DatapathOperator import datapathSubmodules
        sch = self.scheme
        top = name
        if sch.io != sch.W or sch.portsOn():
            name = f'{name}_k'                  # the core inside the port adapters (module `top`)
        bu = sch.butterflyUnit()
        mod = f'{name}_bu'
        bs = bu.getOperatorInterface(mod, pipelineStages)
        if subRoot is not None:
            bs = dataclasses.replace(bs, submodules=bu.submodules(bs, Path(subRoot) / mod))
        assert bu.latency(pipelineStages) == sch.buLatency(pipelineStages)
        twist = None
        if sch.twistMultiplier is not None:
            tm = sch.twistMultiplier
            dps = tm.getOperatorInterface(f'{name}_twist', pipelineStages)
            subs = datapathSubmodules(tm, dps, Path(subRoot) / f'{name}_twist') if subRoot is not None else {}
            vals = []
            for l in range(sch.W):
                v = []
                for q in sch.moduliList():
                    v += sch.twistTable(l, q)
                vals.append(v)
            if sch.twistSrc == 'rec':
                recb = [sch.twistRecTables(l, pipelineStages)[0] for l in range(sch.W)]
                recu = sch.twistRecTables(0, pipelineStages)[1]
                trec = {'D': sch.twistRecD(pipelineStages), 'base': recb, 'upd': recu}
            else:
                trec = None
            twist = {'datapath': dps, 'submodules': subs, 'latency': tm.latency(pipelineStages), 'tables': vals,
                     'src': sch.twistSrc, 'rec': trec,
                     'depth': sch.T * len(sch.dirs) * len(sch.moduliList())}
        # modulus ports per consumer ('bu', 'twist', 'gen', 'half') and their values per MIDX
        gen = None
        if sch.generator() is not None:
            gm = sch.generator()
            gds = gm.getOperatorInterface(f'{name}_gen', pipelineStages)
            gsubs = datapathSubmodules(gm, gds, Path(subRoot) / f'{name}_gen') if subRoot is not None else {}
            gen = {'datapath': gds, 'submodules': gsubs, 'latency': gm.latency(pipelineStages)}
        qports, mtab = {}, {}
        if sch.runtime:
            qs = sch.moduliList()
            cons = {'bu': ([(pn, w) for (pn, w) in bs.extraPorts if pn not in ('W', 'WP', 'DIR')],
                           lambda q: bu.qPortValues(q))}
            if twist:
                cons['twist'] = ([(x.name, x.bitWidth) for x in twist['datapath'].inputs if x.name not in ('A', 'B')],
                                 lambda q: sch.twistMultiplier.qPortValues(q))
            if gen:
                cons['gen'] = ([(x.name, x.bitWidth) for x in gen['datapath'].inputs if x.name not in ('A', 'B')],
                               lambda q: sch.generator().qPortValues(q))
            if sch.stageHalve:
                cons['half'] = ([('QHALF', sch.qMax().bit_length())], lambda q: {'QHALF': (q + 1) // 2})
            for c, (ports, fn) in cons.items():
                qports[c] = ports
                mtab[c] = {pn: [fn(q)[pn] for q in qs] for pn, _ in ports}
        tabs, use = sch.roundTables()
        tw = max(1, (sch.qMax() - 1).bit_length())
        wpw = sch.wpWidth()
        tables = []
        for ti, t in enumerate(tabs):
            vals = sch.roundTable(ti)
            if wpw:
                # Shoup: the word is {WP, W}
                vals = [w | (c << tw) for w, c in zip(vals, sch.roundTableWP(ti))]
            st = None
            for m in sch.memories():
                pass
            from ..memory import ramCost
            style = ramCost(len(vals), tw + wpw, sch.twiddleStyle)['style'] if len(vals) > 1 else 'const'
            src = sch.tableSource(ti)
            ent = {'r': t['r'], 'sb': sch.sigBits(t['r']), 'values': vals, 'style': style, 'users': t['users'],
                   'src': src}
            if sch.unified:
                # per direction the beat bits of the entry, and the block size (the larger direction's)
                ent['sel'] = [sch.entryBits(t['r'], d) for d in sch.dirs]
                ent['E'] = sch.entryCount(t['r'])
            if src == 'rec':
                base, upd = sch.recTables(ti, pipelineStages)
                k = sch.recK(ti, pipelineStages)
                ent.update(k=k, D=k << (sch.CB - sch.sigBits(t['r'])), base=base, upd=upd)
            elif src == 'tree':
                ent.update(base=sch._treeBase[ti], cst=sch.treeTable(ti))
            elif src == 'otf':
                lo, hi = sch.otfTables(ti)
                ent.update(h=sch.otfBits(ti), lo=lo, hi=hi)
            tables.append(ent)
        mems = {m['what'].split(' (')[0]: m['style'] for m in sch.memories()}
        return dict(name=name, n=sch.n, L=sch.L, U=sch.U, g=sch.g, W=sch.W, T=sch.T, CB=sch.CB, R=sch.R, e=sch.e,
                    S=sch.S, RL=sch.RL, Lbu=sch.buLatency(pipelineStages), Ls=sch.stageLatency(pipelineStages),
                    rotLat=sch.rotLatency(), Tin=sch.inOffset(), BO=sch.blockOutOffset(pipelineStages),
                    WO=sch.writeOffset(pipelineStages), OO=sch.outOffset(pipelineStages),
                    slot=sch.slotLength(sch.S, pipelineStages), offsets=sch.roundOffsets(), inDepth=sch.inDepth(),
                    width=sch.memBound.bitWidth, outWidth=sch.outputBound.bitWidth, MB=sch.midxBits(),
                    M=len(sch.moduliList()), dirPort=sch.direction == 'both', dirs=list(sch.dirs),
                    bu=bs, qports=qports, mtab=mtab, tables=tables,
                    use={k: v for k, v in use.items()}, pairs=sch.pairs(), halve=sch.stageHalve, twist=twist,
                    twWidth=tw, wpWidth=wpw, poolStyle=mems['data bank'], fifoStyle=mems['input FIFO bank'],
                    q=sch.q, moduli=sch.moduliList(), negacyclic=sch.negacyclic, direction=sch.direction,
                    gen=gen, lead=sch.lead(), source=sch.twiddleSource, unified=sch.unified, loadable=sch.loadable,
                    external=sch.twiddleSource == 'stream', io=sch.io, XR=sch.XR,
                    fan=sch.fanoutPlan(pipelineStages), fanShift=sch.fanShift(pipelineStages), fanout=sch.fanout,
                    share={ti: list(v) for ti, v in sch.inverseShare().items()},
                    shareMap={ti: sch.inverseAddressMap(ti) for ti in sch.inverseShare()},
                    ioTop=top if sch.io != sch.W and not sch.portsOn() else None, outBufPolys=sch.OUT_BUFFER_POLYS,
                    **(self._portsSpec(top, pipelineStages) if sch.portsOn() else {}))

    def _portsSpec(self, top: str, pipelineStages: int = 1) -> dict:
        '''The spec of the port wrapper (rtl_gen.hybrid_ports; the model is HybridPorts).'''
        sch = self.scheme
        geo = sch.portsGeometry(pipelineStages)
        direct, record = sch.portsDirect(), sch.twiddleBuffer == 'record'
        from .HybridPorts import LDL
        return dict(portTop=top, ports=dict(
            outReady=bool(sch.outReady), natural=geo['natural'], record=record, direct=direct,
            DP=None if direct else sch.outDepth(pipelineStages), K=geo['K'], PP=geo['PP'], RT=geo['RT'],
            rho=geo['rho'], bufStyle=None if direct else sch._portsMemories(pipelineStages)[0]['style'],
            LDL=LDL, recordWords=sch.recordWords(pipelineStages) if record else None,
            twLanes=sch.twiddleLanes, fault=None))

    def testData(self, frames, dirs, qs, validPattern=None, seed: int = 5, pipelineStages: int = 1) -> dict:
        '''Beats, tags, goldens and the model's output cycle of every beat for frames (memory order).'''
        sch = self.scheme
        P = len(frames)
        if validPattern == 'random':
            rng = random.Random(seed)
            bits = [rng.random() < 0.7 for _ in range(1 << 16)]
            valid = lambda c: bits[c % len(bits)]
        elif validPattern is None:
            valid = lambda c: True
        else:
            valid = validPattern
        io = sch.io
        job = sch.simulateJob(P, valid, pipelineStages) if io == sch.W else sch.simulateIoJob(P, valid, pipelineStages)
        errs = sch.checkHazards(job.get('core', job), pipelineStages)
        if errs:
            raise AssertionError(f'{self.name}: hazards: {errs[:3]}')
        outs = sch.transform(frames, dirs, qs)
        W, T = sch.W, sch.T
        x, y, tags = [], [], []
        TB = sch.n // io                         # port beats per polynomial, io words each
        for f in range(P):
            for c in range(TB):
                x.append([frames[f][sch.index(0, c * io + l)] for l in range(io)])
                tags.append((sch.midx(qs[f]), 1 if dirs[f] == 'inv' else 0))
        import math
        from .HybridNTTScheme import _rotr
        for f in range(P):
            for c in range(TB):
                y.append([outs[f][_rotr(c * io + l, sch.U, sch.L)] for l in range(io)])
        ncyc = job['out'][-1][-1] + 20
        return {'x': x, 'y': y, 'tags': tags, 'ytags': [tags[f * TB] for f in range(P) for _ in range(TB)],
                'ycycle': [c for o in job['out'] for c in o], 'valid': [1 if valid(c) else 0 for c in range(ncyc)],
                'cycles': ncyc, 'job': job}

    def emitRtl(self, topName: str, run_dir, frames=None, direction=None, q=None, validPattern=None,
                pipelineStages: int = 1, seed: int = 5, ports: dict | None = None) -> dict:
        '''RTL into run_dir; with frames (memory order) also the testbench: frames back to back, each with
        its direction (list or one) and modulus (list or one), every output beat checked for its value,
        its tags and its cycle (the controller twin), so a slower interval FAILS.'''
        sch = self.scheme
        run_dir = Path(run_dir).resolve()
        run_dir.mkdir(parents=True, exist_ok=True)
        spec = self.getOperatorInterface(topName, pipelineStages, subRoot=run_dir / '_sub')
        if sch.portsOn() and ports and ports.get('fault'):
            spec['ports']['fault'] = ports['fault']       # a wrong design on purpose (negative tests)
        tb = None
        if frames is not None:
            P = len(frames)
            d0 = 'inv' if sch.direction == 'inverse' else 'fwd'
            ds = list(direction) if isinstance(direction, (list, tuple)) else [direction or d0] * P
            qs = list(q) if isinstance(q, (list, tuple)) else [q or sch.refQ()] * P
            if sch.portsOn():
                # ports: {'outReady': pattern, 'twValid': pattern, 'alt': scheme, 'altRegions': its load image}
                from .HybridPorts import portsTestData
                tb = portsTestData(self, frames, ds, qs, validPattern, seed, pipelineStages, **(ports or {}))
                tb['altRegions'] = (ports or {}).get('altRegions')
            else:
                tb = self.testData(frames, ds, qs, validPattern, seed, pipelineStages)
        from rtl_gen.hybrid_ntt import HybridNTT_RTL_gen
        saved = os.getcwd()
        os.chdir(str(run_dir))
        try:
            meta = HybridNTT_RTL_gen(spec, tb=tb)
        finally:
            os.chdir(saved)
        if tb is not None:
            j = tb['job']
            meta.update(latency=j['latency'], interval=j['interval'], jobCycles=j['jobCycles'])
        return meta
