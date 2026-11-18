'''Verify the framework template: Vector, the three contracts, the datapath
template and the NTT-family registry.

One script, no test framework, like the other gates. Run from the project
root (Sage env not needed beyond what the NTT import pulls in):

    python runFramework.py

Gate 1 -- Vector: pack/unpack round trips at every width and sign, both
          packing orders, the NTT generator's own packing reproduced line for
          line, and Vectors read off and driven onto a real NTT's ports.
Gate 2 -- contracts: the testbench hex format against the generators' own
          `to_twos_complement_hex`; a TestVectorSet written, read back, and
          checked against a reference (and a planted wrong golden caught); a
          constant multiplier's run directory collected as RtlArtifacts and
          checked (and a deleted test vector caught); Vivado report parsing
          into a HardwareRecord, compared with the model, stored and queried.
Gate 3 -- datapath template: a scheme written in a dozen lines inherits bounds,
          values, schedule, cost, spec and RTL; heap wrapping, corrections
          with negative and lazy candidates, and an unsound declared bound
          refused by the value path.
Gate 4 -- registry: every box of the sheet's NTT tree is present, every
          registered name imports, every operator honours the contract.
'''
from __future__ import annotations

import contextlib
import io
import json
import random
import shutil
import sys
import tempfile
from pathlib import Path

from operator_modeling.core.IntType import IntType
from operator_modeling.core.Signal import Signal
from operator_modeling.core.Vector import LANE0_MSB, Vector
from operator_modeling.core import contracts as C
from operator_modeling.core.datapath import Datapath, DatapathScheme, ModelError
from operator_modeling.core.DatapathOperator import DatapathOperator

FAILS: list[str] = []


def expect(cond, what):
    if not cond:
        FAILS.append(what)
        print(f'  FAIL {what}')


def raises(fn, exc, what):
    try:
        fn()
    except exc:
        return
    except Exception as e:                                          # noqa: BLE001
        FAILS.append(f'{what}: raised {type(e).__name__} instead of {exc.__name__}')
        return
    FAILS.append(f'{what}: did not raise')


# =============================================================================
def gateVector() -> int:
    rng = random.Random(1)
    n = 0
    for _ in range(300):
        lanes = rng.randint(1, 9)
        bounds = []
        for _ in range(lanes):
            w = rng.randint(1, 70)
            bounds.append(IntType.signed(w) if rng.random() < 0.5 else IntType.unsigned(w))
        trials = [[rng.randint(b.minValue, b.maxValue) for b in bounds] for _ in range(5)]
        for order in ('lane0Lsb', LANE0_MSB):
            v = Vector.fromTrials(bounds, trials, order)
            words = v.packBatch()
            back = Vector.fromPacked(bounds, words, order)
            expect(back.trials() == trials, f'Vector round trip ({order})')
            expect(all(w < (1 << v.totalWidth) for w in words), 'packed word fits totalWidth')
            n += 1
    # lane 0 in the LSBs is what rtl_gen.ntt writes
    from rtl_gen.ntt import _pack_per_slot
    for _ in range(100):
        bounds = [IntType.signed(rng.randint(2, 70)) for _ in range(8)]
        row = [rng.randint(b.minValue, b.maxValue) for b in bounds]
        v = Vector.fromBounds(bounds)
        expect(C.hexLine(v.pack(row), v.totalWidth) == _pack_per_slot(row, v.widths),
               'Vector.pack reproduces rtl_gen.ntt._pack_per_slot')
        n += 1
    # an NTT's ports, as Vectors
    from operator_modeling.ntt.pipelined.FullyPipelinedNTT import FullyPipelinedNTT
    from operator_modeling.ntt.butterfly.ButterflyScheme import GoldilocksSlice64
    from operator_modeling.ntt.twiddles import calculateNttTwiddles
    q, N = 2 ** 64 - 2 ** 32 + 1, 8
    root = pow(7, (q - 1) // N, q)
    tw = calculateNttTwiddles(modulus=q, n=N, butterflyType='GS', primitiveRoot=root,
                              useModulusLiftingNaf=True, maxNumberOfTerms=3)
    ntt = FullyPipelinedNTT(name='v8', n=N, q=q, butterflyType='GS', twiddles=tw)
    ntt.setScheme([[GoldilocksSlice64(name=f's{l}{p}', butterflyType='GS') for p in range(N // 2)]
                   for l in range(3)])
    b = IntType.signed(66)
    xs = [[rng.randint(b.minValue, b.maxValue) for _ in range(N)] for _ in range(4)]
    ntt.driveVector(Vector.fromTrials([b] * N, xs))
    ntt.compute()
    out = ntt.outputVector()
    ref = ntt.getOutputsNatural()
    expect(out.bounds == [p.bound for p in ntt.outputPorts], 'outputVector carries the port bounds')
    expect(len(out) == N and out.hasValues and out.batchSize == 4, 'outputVector shape')
    expect([list(l) for l in out.laneBatches()] == [p.testVector for p in ntt.outputPorts],
           'outputVector carries the port values')
    expect(ntt.inputVector().trials() == xs, 'inputVector reads back what driveVector loaded')
    raises(lambda: Vector((Signal(b, [1, 2]), Signal(b, [1]))), ValueError, 'Vector refuses ragged batches')
    return n


# =============================================================================
def gateContracts(tmp: Path) -> int:
    from rtl_gen.utils import to_twos_complement_hex
    rng = random.Random(2)
    n = 0
    for _ in range(500):
        w = rng.randint(1, 140)
        v = rng.randint(-(1 << (w - 1)), (1 << (w - 1)) - 1) if rng.random() < .5 else rng.randint(0, (1 << w) - 1)
        expect(C.hexLine(v, w) == to_twos_complement_hex(v & ((1 << w) - 1), w), 'hexLine format')
        n += 1
    # a TestVectorSet, written and read back, then checked against a reference
    a = [rng.randint(0, 1000) for _ in range(50)]
    bS = [rng.randint(-500, 500) for _ in range(50)]
    s = [x + y for x, y in zip(a, bS)]
    tv = C.TestVectorSet([C.PortStream.scalar('A', IntType(0, 1000), a),
                          C.PortStream.scalar('B', IntType(-500, 500), bS)],
                         [C.PortStream.scalar('S', IntType(-500, 1500), s)])
    d = tmp / 'tv'
    tv.write(d)
    expect(tv.matchesFiles(d) == [], 'TestVectorSet files match')
    back = C.TestVectorSet.read(d, tv)
    expect([p.values for p in back.inputs + back.outputs] == [a, bS, s], 'TestVectorSet read back')
    expect(tv.check(lambda i: {'S': i['A'] + i['B']}) == [], 'TestVectorSet agrees with the reference')
    bad = C.TestVectorSet(tv.inputs, [C.PortStream.scalar('S', IntType(-500, 1500), [s[0] + 1] + s[1:])])
    expect(len(bad.check(lambda i: {'S': i['A'] + i['B']})) == 1, 'a wrong golden is caught')
    lanes = Vector.fromTrials([IntType.signed(9), IntType.unsigned(5)], [[-3, 7], [200, 31]])
    pv = C.TestVectorSet([C.PortStream.fromVector('X', lanes)], [])
    pv.write(d)
    expect(pv.matchesFiles(d) == [], 'vector port written packed and read back')
    n += 5
    # RtlArtifacts over a real run directory (a constant multiplier)
    from operator_modeling.multiplier.ConstMultScheme import NafConstMult
    from operator_modeling.multiplier.ConstMult import ConstMult
    op = ConstMult(name='cm', scheme=NafConstMult(name='cm', constant=12345, aIn=IntType.unsigned(20)))
    run = tmp / 'cm'
    with contextlib.redirect_stdout(io.StringIO()):
        meta, art = C.emitWithContract(op, 'Cmult_20x12345', run, test_size=32, seed=1)
    expect(art.top == 'Cmult_20x12345' and art.check() == [], 'RtlArtifacts of a constant multiplier')
    expect((run / C.CONTRACT_FILE).is_file(), 'rtl_contract.json written')
    loaded = C.RtlArtifacts.load(run)
    expect(loaded.latency == art.latency and loaded.rtl == art.rtl, 'RtlArtifacts round trip')
    (run / 'testvectors' / 'P.txt').unlink()
    expect(any('P.txt' in p for p in C.RtlArtifacts.collect(run).check()), 'a missing test vector is caught')
    expect(C.contractGaps(op) == [], 'ConstMult honours the RTL contract')
    n += 5
    # HardwareRecord from report text in Vivado's format
    rep = tmp / 'rep'
    rep.mkdir()
    (rep / 'utilization.rpt').write_text(
        '| Tool Version : Vivado v.2025.1 (lin64) Build 1\n| Device       : xcv80-lsva4737-2MHP-e-S\n'
        '| Registers               | 1584 |     0 |\n| CLB LUTs*               | 3781 |     0 |\n'
        '| LOOKAHEAD8              |  557 |     0 |\n| Block RAM Tile           |    1.5 |     0 |\n'
        '| URAM                     |    0 |     0 |\n| DSP Slices         |    9 |     0 |\n')
    (rep / 'timing_summary.rpt').write_text(
        '    WNS(ns)      TNS(ns)  TNS Failing Endpoints\n    -------      -------  ---------\n'
        '     -0.250      -61.384                    364\n\n'
        'Clock     Waveform(ns)       Period(ns)      Frequency(MHz)\n-----     ------------       ----------      --------------\n'
        'clk_main  {0.000 1.250}        2.500           400.000\n')
    rec = C.HardwareRecord.fromVivadoReports(rep, 'demo', model={'lut': 3600, 'dsp': 9, 'criticalPathNs': 2.6})
    expect((rec.lut, rec.ff, rec.dsp, rec.lookahead8, rec.bram36) == (3781, 1584, 9, 557, 1.5), 'utilization parsed')
    expect(rec.clockNs == 2.5 and rec.wnsNs == -0.25 and abs(rec.achievedNs - 2.75) < 1e-9, 'timing parsed')
    expect(rec.part.startswith('xcv80') and rec.tool.startswith('Vivado v.2025.1'), 'tool and part parsed')
    cmp = rec.compare()
    expect(abs(cmp['lut_ratio'] - 3781 / 3600) < 1e-9 and abs(cmp['path_gap_ns'] - 0.15) < 1e-9, 'compare')
    db = C.HardwareDatabase(tmp / 'hw.jsonl')
    db.append(rec)
    db.append(C.HardwareRecord(design='other', lut=1))
    expect(len(db.records()) == 2 and db.latest('demo').lut == 3781, 'HardwareDatabase')
    n += 6
    return n


# =============================================================================
class _MulAdd(DatapathScheme):
    '''`Y = 3*A + B - 5`, the template in a dozen lines.'''
    inputNames = ('A', 'B')
    outputNames = ('Y',)

    def _build(self, dp):
        a, b = dp.input('A', self.aIn), dp.input('B', self.bIn)
        t = dp.constMult('t', a, 3)
        y = dp.heap('y', [dp.whole(t), dp.whole(b), Datapath.const(-5)])
        dp.output('Y', y)

    def reference(self, A, B):
        return {'Y': 3 * A + B - 5}


def gateDatapath(tmp: Path) -> int:
    n = 0
    sch = _MulAdd(name='muladd', aIn=IntType.signed(20), bIn=IntType.unsigned(16))
    b = sch.propagateBound()
    expect(b.minValue == 3 * -(1 << 19) - 5 and b.maxValue == 3 * ((1 << 19) - 1) + (1 << 16) - 1 - 5,
           'template bound')
    ins = sch.sampleInputs(500, random.Random(3))
    expect(sch.checkReference(ins) == [], 'template values against the reference')
    dpm = sch.datapath()
    for k in (0, 1, 2, 5):
        want = sum(min(k, len(dpm.units(nd))) for nd in dpm.nodes)
        expect(sch.latency(k) == want, f'template latency at {k}: {sch.latency(k)} vs {want}')
    spec = sch.getOperatorInterface('muladd', 1)
    json.dumps(spec.to_dict())
    expect(spec.latency == sch.latency(1) and spec.params['estimate']['lut'] > 0, 'template spec')
    op = DatapathOperator('muladd', sch)
    for backend in ('hw', 'sim'):
        with contextlib.redirect_stdout(io.StringIO()):
            meta = op.emitRtl(f'muladd_{backend}', tmp / f'muladd_{backend}', test_size=40, seed=4, backend=backend)
        art = C.RtlArtifacts.load(tmp / f'muladd_{backend}')
        expect(art.check() == [] and art.latency == sch.latency(1), f'template RTL ({backend})')
    n += 6
    # node semantics
    dp = Datapath('t')
    x = dp.input('X', IntType(-100, 900))
    m = dp.heap('m', [dp.slice(x, 0, 3, sign=-1)], wrapBits=4)
    c1 = dp.correct('c1', x, 97)
    c2 = dp.correct('c2', x, 97, step=2)
    dp.output('M', m)
    vals = list(range(-100, 901))
    env = dp.evaluate({'X': vals})
    expect(env['m'] == [(-(v & 15)) % 16 for v in vals], 'heap wrapBits is mod 2^W')
    expect(env['c1'] == [v % 97 for v in vals], 'exact correction with negative candidates')
    expect(all(0 <= r < 194 and (r - v) % 97 == 0 for r, v in zip(env['c2'], vals)), 'lazy correction')
    dp2 = Datapath('u')
    y = dp2.input('Y', IntType(0, 1000))
    dp2.heap('h', [dp2.whole(y)], bound=IntType(0, 500))
    raises(lambda: dp2.evaluate({'Y': [900]}), ModelError, 'an unsound declared bound is refused')
    n += 4
    return n


# =============================================================================
def gateRegistry() -> int:
    from operator_modeling import registry as R
    sheet = ['NTT', 'Butterfly', 'ModularMultiplier', 'Multiplier', 'ConstMult', 'PartialMult',
             'ModularReduction', 'ModularAdder', 'Adder', 'Compressor', 'MatrixTranspose',
             'BarrelShifter', 'Crossbar']
    names = [r.name for r in R.roles()]
    expect(all(s in names for s in sheet), 'every box of the sheet is a role')
    problems = R.check()
    expect(problems == [], f'registry imports: {problems}')
    expect(all(r.implementations for r in R.roles()), 'every role has an entry (planned counts)')
    red = [i.name for i in R.role('ModularReduction').implementations]
    for fam in ('BarrettReduction', 'MontgomeryReduction', 'WordLevelMontgomery', 'GoldilocksReduction',
                'TableLookupReduction', 'CustomReduction'):
        expect(fam in red, f'{fam} registered')
    expect('NTT' in R.describe(), 'describe')
    return len(sheet)


def main() -> int:
    tmp = Path(tempfile.mkdtemp(prefix='runFramework_'))
    try:
        print(f'gate 1 Vector: {gateVector()} checks')
        print(f'gate 2 contracts: {gateContracts(tmp)} checks')
        print(f'gate 3 datapath template: {gateDatapath(tmp)} checks')
        print(f'gate 4 registry: {gateRegistry()} roles')
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    if FAILS:
        print(f'{len(FAILS)} FAILURES')
        for f in FAILS[:20]:
            print('  ', f)
        return 1
    print('all gates passed')
    return 0


if __name__ == '__main__':
    sys.exit(main())
