'''The multi-step NTT operator: RTL (`versal_arith/rtl_gen/multistep.py`) from a `MultiStepScheme`.

    s = MultiStepScheme('ms', N, sizes, P, moduli=[...], ...)
    meta = MultiStepNTT(s).emitRtl('ms', run_dir, xs=[...], dirs=[...], qs=[...], gaps=[...])

Every sub-NTT is `UnrolledNTT` (UNR's type) emitted into `run_dir/_pass<t>/` and copied in; the twiddle
multipliers and generators are `ModularMultiplierScheme` datapaths; the transposes are
`rtl/matrix_transpose/lt_bmb_transpose.sv` (+ barrel_shift.sv, delay_line.sv). With test data the
testbench drives polynomials with the given gaps, MIDX / DIR per polynomial, and checks every output
beat at its exact cycle (input cycle + latency): a slower or faster pipeline fails.
'''
from __future__ import annotations

import contextlib
import glob
import io
import os
import shutil
from pathlib import Path

from .MultiStepScheme import MultiStepScheme

_HERE = Path(__file__).resolve().parent
_VA = _HERE.parents[2] / 'versal_arith'


class MultiStepNTT:
    def __init__(self, scheme: MultiStepScheme):
        self.scheme = scheme
        self.name = scheme.name

    def latency(self) -> int:
        return self.scheme.latency()

    def loadImage(self, q: int, spec: dict | None = None) -> list[int]:
        '''Loadable designs: the words to write through ld_wdata (one per ld_wen cycle after ld_rst) for modulus q:
        each sub-NTT module's UnrolledNTT.loadImage(q) in the spec's segment order, then every inter-pass
        table's words for q.'''
        s = self.scheme
        if not s.loadable:
            raise ValueError(f'{self.name}: loadImage is for loadable designs')
        from ..dataflow.UnrolledNTT import UnrolledNTT
        spec = spec or self.spec(self.name, None)
        old, s._loadQ = s._loadQ, q
        try:
            subs = {}
            for b in spec['blocks']:
                if b['kind'] == 'pass':
                    subs[b['module']] = b['sub'] if 'sub' in b else None
            out = []
            # the spec was built for the current _loadQ: rebuild the table values for q
            spec_q = self.spec(self.name, None)
            for seg in spec_q['load']['segments']:
                sub = next(b['sub'] for b in spec_q['blocks'] if b['kind'] == 'pass' and b['module'] == seg['module'])
                img = UnrolledNTT(sub).loadImage(q)
                assert len(img) == seg['len']
                out += img
            for b in spec_q['blocks']:
                if b['kind'] == 'pass' and b.get('ports'):
                    for tb in b['ports']['tables']:
                        assert len(out) == tb['base']
                        out += tb['values']
            for b in spec_q['blocks']:
                if b['kind'] == 'twiddle':
                    for tb in b['tables']:
                        assert len(out) == tb['base']
                        out += tb['values']
            assert len(out) == spec_q['load']['words']
            return out
        finally:
            s._loadQ = old

    def resources(self) -> dict:
        return self.scheme.resources()

    def getOperatorInterface(self, name: str, subRoot: Path | None = None) -> dict:
        '''The generator's spec (a dict; `rtl_gen.multistep.MultiStep_RTL_gen` consumes it).'''
        return self.spec(name, subRoot)

    def spec(self, name: str, subRoot: Path) -> dict:
        from ...core.DatapathOperator import datapathSubmodules
        from ..dataflow.UnrolledNTT import UnrolledNTT
        from transpose_model import flags_to_reg_flags
        s = self.scheme
        blocks = []
        sched = s.schedule()
        mul = s.multiplier(f'{name}_twmul')
        gen = s.multiplier(f'{name}_twgen')
        qports = list(mul.qPorts()) if s.perFrame else []
        mods = {}
        for b in sched:
            if b['kind'] == 'transpose':
                st = b['step']
                flags = s.transposeFlags(st)
                S = 1 << st['s']
                win = S << st['timeLo']
                blocks.append({'kind': 'transpose', 'S': S, 'lo': st['timeLo'], 'laneBits': st['laneBits'],
                               'flags': flags_to_reg_flags(flags) if flags else 0, 'latency': b['latency'],
                               'ramStyle': s.rtlMemStyle(win, s.romStyleMaxDepth)})
            elif b['kind'] == 'pass':
                t = b['t']
                st = b['step']
                n = s.sizes[t]
                pos = st['digitLanes']
                others = [l for l in range(s.plan.p) if l not in pos]
                groups = []
                for gi in range(s.P // n):
                    base = sum(((gi >> i) & 1) << x for i, x in enumerate(others))
                    groups.append([base | sum(((r >> i) & 1) << x for i, x in enumerate(pos)) for r in range(n)])
                sub = s.subs[t]
                if id(sub) not in mods:
                    mods[id(sub)] = f'{name}_p{t}'
                blk = {'kind': 'pass', 't': t, 'module': mods[id(sub)], 'n': n, 'groups': groups,
                       'latency': b['latency'], 'sub': sub, 'subQ': []}
                if s.loadable:
                    from ..dataflow.UnrolledNTT import UnrolledNTT as _U
                    _sp = _U(sub).getOperatorInterface(mods[id(sub)] + '_core', 1)
                    blk['subQ'] = list(_sp.roms['qPorts'])
                    blk['subQv'] = {q_: sub.qPortValues(q_) for q_ in s.moduli}
                    blk['subTWW'] = max([max(t_['cols']) for t_ in _sp.roms['tables'] if t_['mode'] == 'ram'] or [1])
                if getattr(s, 'loadMod', False):
                    # the sub-NTT's own modulus table is written through the same bus (mt_*)
                    from ..dataflow.UnrolledNTT import UnrolledNTT as _U
                    _sp = _U(sub).getOperatorInterface(mods[id(sub)] + '_core', 1)
                    blk['subMt'] = [(p_, w_) for p_, w_ in _sp.roms['qPorts']]
                    blk['subQv'] = {q_: sub.qPortValues(q_) for q_ in s.moduli}
                    blk['subLoad'] = _sp.roms['loadWords']       # words of one slot of the sub-NTT's own tables
                    if blk['subLoad']:
                        blk['subTWW'] = max([max(t_['cols']) for t_ in _sp.roms['tables'] if t_['mode'] == 'ram'] or [1])
                if s.folded(t):
                    pt = s.portTables[t]
                    blk['ports'] = {'names': [f'tw_{a}_{c}' for a, c in pt['ports']], 'use': pt['use'],
                                    'tables': [{'id': tb['id'], 'bits': tb['bits'], 'depth': tb['depth'],
                                                'dir': tb.get('dir'), 'values': s.portTableValues(t, tb),
                                                'romStyle': s.rtlMemStyle(tb['depth'], 4 * s.romStyleMaxDepth)}
                                               for tb in pt['tables']],
                                    'lat': s.portLatency(t)}
                    if s.portAlign == 'address':
                        # each port's word is due at its stage's butterfly offset in the sub-NTT core
                        from ..dataflow.UnrolledNTT import UnrolledNTT as _U2
                        _st = _U2(sub).getOperatorInterface(mods[id(sub)] + '_core', 1).stages
                        blk['ports']['offs'] = [_st[a]['buOff'] for a, _c in pt['ports']]
                blocks.append(blk)
            elif b['kind'] == 'cross':
                blocks.append({'kind': 'cross', 'n': b['n'], 'latency': b['latency']})
            elif b['kind'] == 'wire':
                blocks.append({'kind': 'wire', 'src': list(b['step']['src']), 'latency': 0})
            else:
                t = b['t']
                st = s.stages[t]
                src = st['source']
                if src == 'tree':
                    tabs = s.treeTables(t)
                    grs = s.treeGroups(t)
                    keyid = {(tb['use'], tuple(tb['bits']), tuple(((tb['aff'][dd][0] if tb['withC'] else 0),
                              tuple(tb['aff'][dd][1][x] for x in tb['bits'])) for dd in s.dirs)): tb['id'] for tb in tabs}
                    blocks.append({'kind': 'twiddle', 't': t, 'latency': b['latency'], 'tree': {
                        'groups': [{'lanes': gr['lanes'], 'tab': {u: keyid[k] for u, k in gr['tab'].items()}} for gr in grs],
                        'depth': s.treeDepth(t), 'two': any(len(gr['zsig']) > 1 for gr in grs),
                        'inreg': s.TREE_INREG},
                        'lanes': [None] * s.P,
                        'tables': [{'id': tb['id'], 'bits': tb['bits'], 'depth': tb['depth'], 'values': tb['values'], 'romStyle': s.rtlMemStyle(tb['depth'], 4 * s.romStyleMaxDepth)}
                                   for tb in tabs],
                        'mul': f'{name}_twmul', 'mulLat': s.mulLatency(), 'gen': f'{name}_twgen',
                        'genLat': s.genLatency(), 'qports': [], 'modShare': 16})
                    continue
                tabs = s.tablesOf(st, src)
                lanes = [None] * s.P
                for i, tb in enumerate(tabs):
                    tb['id'] = i
                    for l in tb['lanes']:
                        lanes[l] = dict(lanes[l] or {})
                        lanes[l]['rom' if tb['use'] == 'rom' else tb['use']] = i
                hasGen = any(ln and 'lo' in ln for ln in lanes)
                blocks.append({'kind': 'twiddle', 't': t, 'latency': b['latency'], 'lanes': lanes,
                               'tables': [{'id': tb['id'], 'bits': tb['bits'], 'depth': tb['depth'],
                                           'values': tb['values'],
                                           'romStyle': s.rtlMemStyle(tb['depth'], 4 * s.romStyleMaxDepth)} for tb in tabs],
                               'mul': f'{name}_twmul', 'mulLat': s.mulLatency(),
                               'gen': f'{name}_twgen' if hasGen else None,
                               'genLat': s.genLatency() if hasGen else 0,
                               'qports': [], 'modShare': 16})
        # modulus table (one for every multiplier and generator: the same scheme args)
        qtable, qwidths = None, []
        if qports:
            dps = mul.getOperatorInterface(f'{name}_twmul', 1)
            w = {x.name: x.bitWidth for x in dps.inputs}
            qwidths = [(p, w[p]) for p in qports]
            qtable = {p: [mul.qPortValues(q)[p] for q in s.moduli] for p in qports}
            gv = {p: [gen.qPortValues(q)[p] for q in s.moduli] for p in gen.qPorts()}
            if gv != qtable:
                raise AssertionError('generator and multiplier modulus constants differ')
            for b in blocks:
                if b['kind'] == 'twiddle':
                    b['qports'] = qwidths
        IW = max(1, (len(s.moduli) - 1).bit_length()) if s.perFrame else 0
        load = None
        for b in blocks:
            if b['kind'] == 'twiddle':
                for tb in b['tables']:
                    tb['ram'] = s.loadable
        if s.loadable:
            # one load stream: the sub-NTT modules' images (all copies of a module written together), then every
            # inter-pass table; a global word counter selects the segment
            segs, base = [], 0
            for b in blocks:
                if b['kind'] == 'pass' and not any(x['module'] == b['module'] for x in segs):
                    n = len(UnrolledNTT(b['sub']).loadImage(s._loadQ))
                    segs.append({'module': b['module'], 'base': base, 'len': n})
                    base += n
            for b in blocks:
                if b['kind'] == 'pass' and b.get('ports'):
                    for tb in b['ports']['tables']:
                        tb['base'] = base
                        tb['ram'] = True
                        base += tb['depth']
            for b in blocks:
                if b['kind'] == 'twiddle':
                    for tb in b['tables']:
                        tb['base'] = base
                        base += tb['depth']
            dps = mul.getOperatorInterface(f'{name}_twmul', 1)
            ww = {x.name: x.bitWidth for x in dps.inputs}
            qp = {p_: ww[p_] for p_ in mul.qPorts()}
            for b in blocks:
                if b['kind'] == 'pass':
                    for p_, w_ in b['subQ']:
                        qp[p_] = max(qp.get(p_, 0), w_)
            load = {'segments': segs, 'words': base, 'qports': sorted(qp.items()), 'width': s.W}
            for b in blocks:
                if b['kind'] == 'twiddle':
                    b['qports'] = [(p_, ww[p_]) for p_ in mul.qPorts()]
        if getattr(s, 'loadMod', False):
            # run-time moduli: every table inside is a RAM with one block per slot. One load fills one slot, unit
            # after unit in the order of the pipeline, so the load follows the data. A unit is a sub-NTT module
            # with tables of its own (all its copies are written together), a port table or a factor table.
            core = s.tableSupply == 'core'
            M = len(s.moduli)
            byDir = bool(getattr(s, 'loadDir', False))
            units, cum, seen = [], 0, {}
            for b in blocks:
                lat = b['latency']
                if b['kind'] == 'pass':
                    if b.get('subLoad'):
                        if b['module'] in seen:
                            seen[b['module']]['roff'][1] = cum + lat        # a later pass reads the same module
                        else:
                            u = {'what': 'sub', 'module': b['module'], 'len': b['subLoad'], 'roff': [cum, cum + lat]}
                            seen[b['module']] = u
                            units.append(u)
                    if core and b.get('ports'):
                        for tb in b['ports']['tables']:
                            tb['ram'], tb['sblock'] = True, tb['depth'] // M
                            u = {'what': 'table', 'tb': tb, 'len': tb['sblock'], 'roff': [cum, cum + lat]}
                            if byDir and tb.get('dir'):
                                # a table of one direction: written only by a load of that direction, so it takes
                                # a place in that direction's load only (the two directions are laid out apart)
                                tb['ldir'] = u['only'] = tb['dir']
                            elif byDir:
                                tb['ldir'] = 'half'                 # both directions: the load writes its half
                                u['len'] = tb['sblock'] // 2
                            units.append(u)
                elif b['kind'] == 'twiddle' and core:
                    for tb in b['tables']:
                        tb['ram'], tb['sblock'] = True, tb['depth'] // M
                        u = {'what': 'table', 'tb': tb, 'len': tb['sblock'], 'roff': [cum, cum + lat]}
                        if byDir:
                            tb['ldir'] = 'half'
                            u['len'] = tb['sblock'] // 2
                        units.append(u)
                cum += lat
            # each unit goes to the load lane that is shortest so far: every lane stays in pipeline order
            R = getattr(s, 'loadLanes', 1)
            # by direction there are two loads, one per direction, laid out apart: `fd[d][l]` is how far lane l is
            # filled in the load of direction d. A unit of one direction moves only its own; any other moves both.
            fd = {d_: [0] * R for d_ in (s.dirs if byDir else ['all'])}
            segs = []
            for u in units:
                ds_ = [u['only']] if u.get('only') else list(fd)
                l = min(range(R), key=lambda i: max(fd[d_][i] for d_ in ds_))
                u['base'], u['ldl'] = max(fd[d_][l] for d_ in ds_), l
                if u['what'] == 'sub':
                    segs.append({'module': u['module'], 'base': u['base'], 'len': u['len'], 'ldl': l})
                else:
                    u['tb']['base'], u['tb']['ldl'] = u['base'], l
                for d_ in ds_:
                    fd[d_][l] = u['base'] + u['len']
            fill = [max(fd[d_][i] for d_ in fd) for i in range(R)]
            if max(fill):
                load = {'segments': segs, 'words': max(fill), 'qports': [], 'width': s.W, 'slots': True, 'lanes': R,
                        'byDir': byDir,
                        'units': [{'base': u['base'], 'words': u['len'], 'offsets': list(u['roff'])} for u in units]}
        sp = {'name': name, 'N': s.N, 'sizes': s.sizes, 'P': s.P, 'F': s.F, 'W': s.W,
              'latency': s.latency(), 'IW': IW, 'dirPort': s.direction == 'both', 'moduli': s.moduli,
              'blocks': blocks, 'qtable': qtable, 'qwidths': qwidths, 'load': load}
        # options of 2026-11-14 (keys only when on)
        if s.TABLE_LAT != 2:
            sp['tabLat'] = s.TABLE_LAT
        if s.tableSupply == 'stream':
            sp['stream'] = True
        if getattr(s, 'loadMod', False):
            # run-time moduli in loadable slots: one write bus for every modulus table of the design. Its
            # constants are the union of this design's and the sub-NTTs', and the values per stand-in modulus
            ports, vals = {}, {q_: {} for q_ in s.moduli}
            for p_, w_ in qwidths:
                ports[p_] = max(ports.get(p_, 0), w_)
            for q_ in s.moduli:
                vals[q_].update({p_: v for p_, v in mul.qPortValues(q_).items() if p_ in dict(qwidths)})
            for b in blocks:
                if b['kind'] == 'pass':
                    for p_, w_ in b.get('subMt', []):
                        ports[p_] = max(ports.get(p_, 0), w_)
                    for q_, qv_ in b.get('subQv', {}).items():
                        for p_, v in qv_.items():
                            if vals[q_].setdefault(p_, v) != v:
                                raise AssertionError(f'modulus constant {p_} differs between blocks for q = {q_}')
            sp['mtLoad'] = {'ports': sorted(ports.items()), 'values': vals}
            self._mtSubs = [(mul, dict(qwidths))] + [(b_['sub'], None) for b_ in blocks if b_['kind'] == 'pass']
        if s.outReady:
            from .MultiStepScheme import memoryTiles
            D = getattr(self, '_rtlFifoDepth', None) or s.outFifoDepth()
            mt = memoryTiles(D, s.P * s.W + s.tagBits(), s.memStyle, s._uramMinDepth)
            sp['ready'] = {'depth': D, 'ramStyle': 'ultra' if mt['uram'] else 'block',
                           'coreLatency': s.coreLatency()}
        return sp

    def emitRtl(self, name: str, run_dir, xs=None, dirs=None, qs=None, gaps=None, tail: int = 8,
                stop: int | None = None, ready=None) -> dict:
        '''`ready` (outReady designs): out_ready per cycle (list of 0/1; 1 past its end).'''
        from ...core.DatapathOperator import datapathSubmodules
        from ..dataflow.UnrolledNTT import UnrolledNTT
        s = self.scheme
        run_dir = Path(run_dir).resolve()
        run_dir.mkdir(parents=True, exist_ok=True)
        rtl = run_dir / 'RTL_generated'
        if rtl.exists():
            shutil.rmtree(rtl)
        rtl.mkdir()
        top = name
        if getattr(s, 'slotMgr', False):            # the core <name>_k with its slot manager as <name>
            name = top + '_k'
        spec = self.spec(name, run_dir / '_sub')
        plan = self.managedPlan(spec) if getattr(s, 'slotMgr', False) else None
        if plan is not None:
            if len(s.moduli) < plan['slots']:
                raise ValueError(f'{s.name}: {len(s.moduli)} slots, but any sequence of moduli needs {plan["slots"]}')
            if not plan['fits']:
                raise ValueError(f'{s.name}: a load of {plan["timing"]["words"]} cycles plus its request does not fit '
                                 f'a frame of {s.F}: more load lanes are needed for one load per polynomial')
        if stop is not None:
            spec['blocks'] = spec['blocks'][:stop]
            spec['latency'] = sum(b['latency'] for b in spec['blocks'])
        self._stop = stop
        # sub-NTTs
        done = set()
        for b in spec['blocks']:
            if b['kind'] != 'pass' or b['module'] in done:
                continue
            done.add(b['module'])
            d = run_dir / f"_{b['module']}"
            with contextlib.redirect_stdout(io.StringIO()):
                m = UnrolledNTT(b['sub']).emitRtl(b['module'], d)
            if m['latency'] + 0 != b['latency'] and m.get('latency') is not None:
                # UnrolledNTT's meta 'latency' is the core's; the wrapper adds nothing
                pass
            for f in glob.glob(str(d / 'RTL_generated' / '*.sv')) + glob.glob(str(d / 'RTL_generated' / '*.v')):
                if not f.endswith('_tb.sv'):
                    shutil.copy(f, rtl)
        for b in spec['blocks']:
            b.pop('sub', None)
        # multipliers
        from rtl_gen.datapath import Datapath_RTL_gen
        saved = os.getcwd()
        os.chdir(str(run_dir))
        try:
            need = {b['mul'] for b in spec['blocks'] if b['kind'] == 'twiddle'} | \
                   {b['gen'] for b in spec['blocks'] if b['kind'] == 'twiddle' and b['gen']}
            for mn in sorted(need):
                m = s.multiplier(mn if mn.endswith('_twgen') else mn)
                dps = m.getOperatorInterface(mn, 1)
                subs = datapathSubmodules(m, dps, run_dir / '_sub' / mn)
                with contextlib.redirect_stdout(io.StringIO()):
                    Datapath_RTL_gen(spec=dps, gen_testbench=False, submodules=subs, write_xdc=False)
            for f in ('lt_bmb_transpose.sv', 'barrel_shift.sv', 'delay_line.sv'):
                shutil.copy(_VA / 'rtl' / 'matrix_transpose' / f, rtl)
            tb = None
            if xs is not None:
                if s.outReady:
                    tb = self._testDataReady(spec, xs, dirs, qs, gaps, tail, ready)
                else:
                    tb = self._testData(spec, xs, dirs, qs, gaps, tail, managed=plan)
            from rtl_gen.multistep import MultiStep_RTL_gen
            meta = MultiStep_RTL_gen(spec, tb)
            if plan is not None:
                from rtl_gen import slot_manager as SM
                tim, KW = plan['timing'], 8
                mgr = f'{top}_slotmgr'
                core_sv = (rtl / f'{name}.sv').read_text()
                (rtl / f'{mgr}.sv').write_text(SM.emit_slot_manager(mgr, len(s.moduli), KW, tim['after'], tim['before'],
                                                                    tim['words'], strict=True))
                (rtl / f'{top}.sv').write_text(SM.emit_managed_multistep_top(top, name, core_sv, mgr, s.F, KW))
                if tb is not None:
                    (rtl / f'{name}_tb.sv').unlink()        # the core's own testbench drives the slots itself
                    tv = run_dir / 'testvectors'
                    ann = {c_: k_ for c_, k_ in tb['ann']}
                    (tv / 'ann_in.txt').write_text(''.join(f"{(1 | (ann[c_] << 1)) if c_ in ann else 0:x}\n"
                                                           for c_ in range(len(tb['cycles']))))
                    (tv / 'ldimg.txt').write_text(''.join(f'{w_:x}\n' for img in tb['images'] for w_ in img))
                    (rtl / f'{top}_tb.sv').write_text(SM.emit_managed_multistep_tb(top, spec, tb, KW))
                meta.update(top=top, slots=len(s.moduli), lead=plan['lead'])
        finally:
            os.chdir(saved)
        meta['schedule'] = [{k: v for k, v in b.items() if k != 'step'} for b in s.schedule()]
        import json
        man = {'top_name': top, 'kind': 'multistep', 'N': s.N, 'sizes': s.sizes, 'lanes': s.P, 'frame_cycles': s.F,
               'latency': meta['latency'], 'moduli': len(s.moduli), 'io_lanes': s.P, 'cross_regs': s.crossRegs}
        if s.TABLE_LAT != 2 or s.tableSupply != 'core' or s.outReady or s.outputOrder != 'pass':
            man.update(ram_latency=s.TABLE_LAT, table_supply=s.tableSupply, out_ready=s.outReady,
                       output_order=s.outputOrder, stream_ports=len(spec.get('_ext') or []))
            if s.outReady:
                man['out_fifo_depth'] = spec['ready']['depth']
        (run_dir / 'manifest.json').write_text(json.dumps(man, indent=1))
        return meta

    def _testDataReady(self, spec, xs, dirs, qs, gaps, tail, ready):
        '''Test data of an `outReady` design from the cycle-exact twin (`MultiStepScheme.readyTwin`): the source
        offers polynomial i `gaps[i-1]` cycles after polynomial i-1 and holds in_valid until in_ready; out_ready per
        cycle from `ready`. Every cycle the testbench checks in_ready, out_valid and every valid beat.'''
        s = self.scheme
        T = len(xs)
        d0 = s._defaultDir()
        dirs = list(dirs) if isinstance(dirs, (list, tuple)) else [dirs or d0] * T
        qs = list(qs) if isinstance(qs, (list, tuple)) else [qs or s.moduli[0]] * T
        gaps = list(gaps) if gaps is not None else [0] * T
        with contextlib.redirect_stdout(io.StringIO()):
            frames = s.transformFrames([s.inputFrame(x) for x in xs], dirs, qs)
        ins = [s.inputFrame(x) for x in xs]
        tw = s.readyTwin([0] + gaps[:-1], list(ready or []))
        self.twin = tw
        import random
        rng = random.Random(5)
        mis = [s.moduli.index(q) if s.perFrame else 0 for q in qs]
        dis = [1 if d == 'inv' else 0 for d in dirs]
        cyc, exp = [], []
        for r in tw:
            if r['beat']:                                   # an offered beat (held until in_ready)
                i, tau = r['beat']
                cyc.append({'v': 1, 'x': ins[i][tau], 'mi': mis[i], 'di': dis[i], 'ld': (0, 0, 0), 'q': {},
                            'ordy': r['out_ready'], 'irdy': r['in_ready']})
            else:
                cyc.append({'v': 0, 'x': [rng.randrange(s.qMax) for _ in range(s.P)],
                            'mi': rng.randrange(len(s.moduli)) if s.perFrame else 0,
                            'di': rng.randrange(2) if spec['dirPort'] else 0, 'ld': (0, 0, 0), 'q': {},
                            'ordy': r['out_ready'], 'irdy': r['in_ready']})
            if r['out']:
                i, tau = r['out']
                exp.append({'y': frames[i][tau], 'mi': mis[i], 'di': dis[i]})
            else:
                exp.append(None)
        exp += [None] * tail
        return {'cycles': cyc, 'expect': exp, 'ready': True, 'beats': T * s.F}

    def managedPlan(self, spec: dict, respond: int = 4) -> dict:
        '''slotManager: timing (slotTiming), `lead` (cycles a polynomial is announced ahead), `slots` (the least
        number for any sequence of moduli), `fits` (a load with its request is shorter than a frame).'''
        from rtl_gen.slot_manager import lead_cycles, slots_needed
        tim = self.slotTiming(spec)
        lead = lead_cycles(tim['before'], tim['words'], respond)
        F = self.scheme.F
        return {'timing': tim, 'lead': lead, 'slots': slots_needed(tim['after'], lead, F),
                'fits': tim['words'] <= F, 'frame': F}

    def _testData(self, spec, xs, dirs, qs, gaps, tail, managed=None):
        s = self.scheme
        T = len(xs)
        d0 = s._defaultDir()
        dirs = list(dirs) if isinstance(dirs, (list, tuple)) else [dirs or d0] * T
        qs = list(qs) if isinstance(qs, (list, tuple)) else [qs or s.moduli[0]] * T
        gaps = list(gaps) if gaps is not None else [0] * T
        with contextlib.redirect_stdout(io.StringIO()):
            frames = s.transformFrames([s.inputFrame(x) for x in xs], dirs, qs, stop=getattr(self, '_stop', None))
        import random
        rng = random.Random(5)
        cyc, beats = [], []
        LAT = spec['latency']
        LD = spec.get('load')
        curq = None
        self.reloads = []
        self._polyStarts = []           # the cycle of every polynomial's first beat
        mqs = []                        # the moduli of the test, in order of first use (the constants given with each)
        qv = {}
        curd = None
        SL = bool(LD and LD.get('slots'))          # run-time moduli, tables inside as slots
        slotOf, loads, tim = None, [], None
        if SL and managed is not None:
            # slots that rotate: the manager in the design chooses them. The test announces every polynomial's
            # modulus `lead` cycles ahead and answers the load requests (the testbench does that on its own).
            SL, LD = False, None
            slotOf = [0] * len(xs)
        if SL:
            from ..dataflow.StreamingNTTScheme import planSlots
            if any(gaps):
                raise ValueError(f'{s.name}: the slot test runs the polynomials back to back (no gaps)')
            tim = self.slotTiming(spec)
            keys_ = [(q_, d_) for q_, d_ in zip(qs, dirs)] if LD.get('byDir') else list(qs)
            slotOf, loads = planSlots(s.name, len(s.moduli), s.F, keys_, tim)
            self.slotRun = {'timing': tim, 'slots': slotOf, 'loads': loads}
            LD = None                               # the per-job reload path below is not this mode
        if spec.get('mtLoad'):          # idle cycles first: the loads of the slots the first polynomials need
            npre = sum(1 for c_, _, _ in loads if c_ < 0)
            for _ in range(self.SLOT_WRITE_LEAD + 2 + npre * ((tim['words'] if tim else 0) + 4)
                           + (managed['lead'] + 16 if managed is not None else 0)):
                cyc.append({'v': 0, 'x': [0] * s.P, 'mi': 0, 'di': 0, 'ld': (0, 0, 0), 'q': qv})
        c0 = len(cyc)                   # the cycle of the first beat of polynomial 0
        for i, x in enumerate(xs):
            di_i = 1 if dirs[i] == 'inv' else 0
            if LD and (qs[i] != curq or di_i != curd):
                # a job boundary (the modulus or the direction changes: both are per job in a loadable design, as
                # TP-NTT's; the sub-NTT's DIR and q ports are quasi-static): drain the pipeline (LAT idle cycles)
                # with the old settings, then set DIR and, for a new modulus, reload q and the tables
                c0 = len(cyc)
                if curq is not None:
                    for _ in range(LAT):
                        cyc.append({'v': 0, 'x': [0] * s.P, 'mi': 0, 'di': curd, 'ld': (0, 0, 0), 'q': qv})
                curd = di_i
                if qs[i] == curq:
                    for _ in range(getattr(self, 'loadSettle', 4)):
                        cyc.append({'v': 0, 'x': [0] * s.P, 'mi': 0, 'di': curd, 'ld': (0, 0, 0), 'q': qv})
                    self.reloads.append({'q': curq, 'cycles': len(cyc) - c0, 'words': 0, 'drain': LAT,
                                         'dirOnly': True})
                    fr = s.inputFrame(x)
                    mi = 0
                    for tau in range(s.F):
                        cyc.append({'v': 1, 'x': fr[tau], 'mi': mi, 'di': curd, 'ld': (0, 0, 0), 'q': qv})
                        beats.append((len(cyc) - 1, frames[i][tau], mi, curd))
                    for _ in range(gaps[i]):
                        cyc.append({'v': 0, 'x': [0] * s.P, 'mi': 0, 'di': curd, 'ld': (0, 0, 0), 'q': qv})
                    continue
                curq = qs[i]
                img = self.loadImage(curq, spec)
                mul = s.multiplier(f'{s.name}_twmul')
                qv = {p_: v for p_, v in mul.qPortValues(curq).items()}
                for b in spec['blocks']:
                    if b['kind'] == 'pass':
                        qv.update(b.get('subQv', {}).get(curq, {}))
                qv = {p_: qv[p_] for p_, _ in LD['qports']}
                cyc.append({'v': 0, 'x': [0] * s.P, 'mi': 0, 'di': curd, 'ld': (1, 0, 0), 'q': qv})
                for wd in img:
                    cyc.append({'v': 0, 'x': [0] * s.P, 'mi': 0, 'di': curd, 'ld': (0, 1, wd), 'q': qv})
                for _ in range(getattr(self, 'loadSettle', 4)):
                    cyc.append({'v': 0, 'x': [0] * s.P, 'mi': 0, 'di': curd, 'ld': (0, 0, 0), 'q': qv})
                self.reloads.append({'q': curq, 'cycles': len(cyc) - c0, 'words': len(img), 'drain': LAT if c0 else 0})
            fr = s.inputFrame(x)
            mi = (slotOf[i] if slotOf is not None else s.moduli.index(qs[i])) if s.perFrame else 0
            di = 1 if dirs[i] == 'inv' else 0
            self._polyStarts.append(len(cyc))
            if qs[i] not in mqs:
                mqs.append(qs[i])
            for tau in range(s.F):
                cyc.append({'v': 1, 'x': fr[tau], 'mi': mi, 'di': di, 'ld': (0, 0, 0), 'q': qv, 'qi': mqs.index(qs[i])})
                beats.append((len(cyc) - 1, frames[i][tau], mi, di))
            for _ in range(gaps[i]):
                cyc.append({'v': 0, 'x': [rng.randrange(s.qMax) for _ in range(s.P)],
                            'mi': rng.randrange(len(s.moduli)) if s.perFrame else 0,
                            'di': (curd if LD else (rng.randrange(2) if spec['dirPort'] else 0)), 'ld': (0, 0, 0),
                            'q': qv})
        if SL:
            # the loads on top of the cycles: ld_rst with the slot one cycle before the first word
            at = 1
            byd = bool(spec['load'].get('byDir'))
            for tL, k, q_ in loads:
                st = at if tL < 0 else c0 + tL
                img = self.slotImage(spec, *q_) if byd else self.slotImage(spec, q_)
                k = k | ((s.dirs.index(q_[1]) << spec['IW']) if byd else 0)       # the direction above the slot
                if st < 1:
                    raise ValueError(f'{s.name}: a slot load at cycle {st} does not fit the test')
                while st + len(img) > len(cyc):     # a load that ends after the last polynomial has entered
                    cyc.append({'v': 0, 'x': [0] * s.P, 'mi': 0, 'di': 0, 'ld': (0, 0, 0), 'q': qv})
                cyc[st - 1] = dict(cyc[st - 1], ld=(1, 0, 0), ls=k)
                for i_, w_ in enumerate(img):
                    cyc[st + i_] = dict(cyc[st + i_], ld=(0, 1, w_), ls=k)
                if tL < 0:
                    at = st + len(img) + 3
        exp = [None] * (len(cyc) + LAT + tail)
        for c, y, mi, di in beats:
            exp[c + LAT] = {'y': y, 'mi': mi, 'di': di}
        out = {'cycles': cyc, 'expect': exp}
        if spec.get('mtLoad'):
            out['mqTable'] = [self.mtValues(q_) for q_ in mqs]
        if managed is not None:
            byd = bool(spec['load'].get('byDir'))
            qid = {q_: i_ + 1 for i_, q_ in enumerate(mqs)}         # the outside's own identifiers
            keyOf = {}                  # by direction: the direction is the lowest bit of the key
            for q_, d_ in zip(qs, dirs):
                keyOf.setdefault((q_, d_) if byd else q_, ((qid[q_] << 1) | s.dirs.index(d_)) if byd else qid[q_])
            out['ann'] = [(c_ - managed['lead'], keyOf[(q_, d_) if byd else q_])
                          for c_, q_, d_ in zip(self._polyStarts, qs, dirs)]
            out['images'] = [self.slotImage(spec, *x_) if byd else self.slotImage(spec, x_) for x_ in keyOf]
            out['imageOf'] = {k_: i_ for i_, k_ in enumerate(keyOf.values())}
            self.slotRun = {'plan': managed, 'distinct': len(mqs)}
        return out

    #: loadableModuli: idle cycles in front of the first polynomial of a test
    SLOT_WRITE_LEAD = 6

    def mtValues(self, q: int) -> dict:
        '''loadableModuli: the modulus constants (mq_*) of modulus q, any modulus of the family.'''
        out = {}
        for sch, keep in self._mtSubs:
            for p_, v in sch.qPortValues(q).items():
                if keep is None or p_ in keep:
                    out[p_] = v
        return out

    def slotTiming(self, spec: dict) -> dict:
        '''loadableModuli with tables inside: when a slot may be filled (StreamingNTTScheme.slotTiming).'''
        from ..dataflow.StreamingNTTScheme import slotTimingOf
        # margin 8: the writes land up to four cycles later than the word (registered port and local registers,
        # in the top and again in a small NTT)
        return slotTimingOf(self.scheme.F, spec['load']['units'], spec['latency'], spec['load']['words'], margin=8)

    def slotImage(self, spec: dict, q: int, d: str | None = None) -> list:
        '''loadableModuli with tables inside: the words of one slot load for modulus q (any modulus of the
        family), in load order. The table words of q come from the scheme built over q alone (`_valueQ`).'''
        from ..dataflow.UnrolledNTT import UnrolledNTT
        s = self.scheme
        R = spec['load'].get('lanes', 1)
        rows = [[0] * R for _ in range(spec['load']['words'])]     # one row per cycle, one word per load lane
        old = getattr(s, '_valueQ', None)
        s._valueQ = [q]
        try:
            with contextlib.redirect_stdout(io.StringIO()):
                sq = self.spec(spec['name'], None)
        finally:
            s._valueQ = old
        for seg in spec['load']['segments']:
            sub = next(b['sub'] for b in sq['blocks'] if b['kind'] == 'pass' and b['module'] == seg['module'])
            img = UnrolledNTT(sub).loadImage(q, d)
            assert len(img) == seg['len'], (seg, len(img))
            for i_, w_ in enumerate(img):
                rows[seg['base'] + i_][seg.get('ldl', 0)] = w_

        def tabs(b):
            return (b.get('ports') or {}).get('tables', []) if b['kind'] == 'pass' else \
                (b.get('tables', []) if b['kind'] == 'twiddle' else [])
        for b0, b1 in zip(spec['blocks'], sq['blocks']):
            for a_, c_ in zip(tabs(b0), tabs(b1)):
                if a_.get('sblock'):
                    assert len(c_['values']) == a_['sblock'], (a_['id'], len(c_['values']), a_['sblock'])
                    vals = c_['values']
                    if a_.get('ldir') == 'half':                    # forward then inverse: the half of d
                        h_ = s.dirs.index(d)
                        vals = vals[h_ * len(vals) // 2:(h_ + 1) * len(vals) // 2]
                    elif a_.get('ldir') and a_['ldir'] != d:        # a table of the other direction: not in this load
                        continue
                    for i_, w_ in enumerate(vals):
                        rows[a_['base'] + i_][a_.get('ldl', 0)] = w_
        ldl = spec['load'].get('ldw', 0) // R if spec['load'].get('ldw') else None
        self._ldRows = rows
        if R == 1:
            return [r_[0] for r_ in rows]
        # several lanes: one wide word per cycle (lane l above lane l - 1); the word width is known after the RTL
        # generator set it (`ldw`), and the test data are built after it
        wl = max([spec['W']] + [b.get('subTWW', 1) for b in spec['blocks'] if b['kind'] == 'pass'])
        return [sum(w_ << (l_ * wl) for l_, w_ in enumerate(r_)) for r_ in rows]


def simulate(run_dir, top: str, timeout: int = 7200, generics: str | None = None, tag: str = '') -> tuple[str, str]:
    '''xvlog / xelab / xsim of `<top>_tb` in run_dir/sim (Vivado 2025.1 from ntt_hw/source).
    Returns (verdict, last tb lines). `generics`: a testbench parameter override ('SRC_EXTRA=1': the outside
    tables one cycle late, a negative test); `tag`: suffix of the sim folder and log (a second run of one design).'''
    import subprocess
    run_dir = Path(run_dir).resolve()
    sim = run_dir / f'sim{tag}'
    if sim.exists():
        shutil.rmtree(sim)
    sim.mkdir()
    files = sorted(glob.glob(str(run_dir / 'RTL_generated' / '*.sv')) + glob.glob(str(run_dir / 'RTL_generated' / '*.v')))
    prims = sorted(glob.glob(str(_VA / 'rtl' / '*.sv')))
    flist = sim / 'files.f'
    flist.write_text('\n'.join(files + prims) + '\n')
    sh = sim / 'run.sh'
    gen = f' -generic_top "{generics}"' if generics else ''
    sh.write_text(f'''#!/bin/bash
[ -n "$VIVADO_SETTINGS" ] && source "$VIVADO_SETTINGS" >/dev/null 2>&1
cd {sim}
xvlog -sv -f files.f $XILINX_VIVADO/data/verilog/src/glbl.v > xvlog.out 2>&1 || {{ echo "[tb] COMPILE FAIL"; exit 2; }}
xelab -L unisims_ver -L unimacro_ver -L secureip -L xpm{gen} work.{top}_tb work.glbl -s {top}_tb --timescale 1ns/1ps > xelab.out 2>&1 || {{ echo "[tb] ELAB FAIL"; exit 2; }}
printf 'run all\\nquit\\n' > sim.tcl
xsim {top}_tb -t sim.tcl > xsim.out 2>&1
grep '\\[tb\\]' xsim.out
''')
    sh.chmod(0o755)
    r = subprocess.run(['bash', str(sh)], capture_output=True, text=True, timeout=timeout)
    out = r.stdout.strip().splitlines()
    verdict = 'PASS' if any(l.strip() == '[tb] PASS' for l in out) else ('FAIL' if out else 'NO VERDICT')
    (run_dir / f'sim{tag}.log').write_text(r.stdout + r.stderr)
    return verdict, '\n'.join(out[-12:])
