"""Generate the iterative NTT cores for the AutoNTT-I comparison and the design-space points
(both directions on one core, 350 MHz target), with a testbench each (distinct polynomials back
to back, every output beat's value and cycle checked).

    python3 iter_gen.py --model ROW ...       # model estimates only
    python3 iter_gen.py ROW ...               # RTL + testbench into ./ooc/<row>/
"""
import argparse, contextlib, io, json, os, random, sys, time

GEN = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, GEN)
os.chdir(GEN)
import runModularNTT as r                                          # noqa: E402
from operator_modeling.ntt.NTT import IterativeNTT                 # noqa: E402
from operator_modeling.modmult.ModulusFamily import ModulusFamily as MF   # noqa: E402

OUT = os.environ.get('ITER_OUT', os.path.join(GEN, 'work', 'iterative'))
CYC = dict(nwc=False, inverseScale='stage', twiddleBuffer='single')   # cyclic, x2^-1 per stage (as AutoNTT, no output
#   multiplier); the rows of 2026-11-07/08: one modulus per job (q ports + twiddle load port)
#: the RNS rows (2026-11-08): the generator's default twiddleBuffer ('recycle'), a modulus per polynomial
RNS = dict(nwc=False, inverseScale='stage')
#: two AutoNTT-I primes per comparison row (../autontt_iter/RESULTS.md), alternated per polynomial in the RNS tests
PRIME_PAIRS = {'Ia': (576460796326838273, 576460798474321921), 'Id': (2251800350556161, 2251801155862529),
               'Ie': (9223372036855103489, 9223372036855300097), 'If': (9223372036855300097, 9223372036859625473),
               'Ib': (34359754753, 34359771137), 'Ic': (9007199255019521, 9007199255347201),
               'Sx': (34359754753, 34359771137)}      # the short-stage study rows below (36-bit, as 'Ib')
#: row -> (n, B, modulus, reduction, extra). AutoNTT-I rows of Table IV (letters I-a .. I-f, see REVIEW.md);
#: the moduli are run-time families (q and twiddles loaded per job, as AutoNTT's kernels take q at run time).
ROWS = {
    # I-a: N=2^12, 60-bit WLM, 8 BUs (U50: 26/24/152/64/0, 13.21 us)
    'Ia_n4096_q60w_B8': (4096, 8, MF.friendly(30, 30), 'wlm', dict(CYC)),
    # the same with the data banks in LUTRAM (256 deep: cheaper than BRAM by AutoNTT's ATP weights)
    'Ia_n4096_q60w_B8_lr': (4096, 8, MF.friendly(30, 30), 'wlm', dict(CYC, memStyle='distributed')),
    # I-d: N=2^16, 52-bit WLM, 32 BUs (U50: 80/60/288/498/0, 66.54 us)
    'Id_n65536_q52w_B32': (65536, 32, MF.friendly(26, 26), 'wlm', dict(CYC)),
    # I-e: N=2^16, 64-bit Barrett, 64 BUs (U200: 206/160/2048/718/0, 39.14 us)
    'Ie_n65536_q64b_B64': (65536, 64, MF.odd(64), 'barrett', dict(CYC)),
    # I-f: N=2^17, 64-bit Barrett, 64 BUs (U200: 218/166/2048/1343/0, 77.11 us)
    'If_n131072_q64b_B64': (131072, 64, MF.odd(64), 'barrett', dict(CYC)),
    # I-b: N=2^13, 36-bit Barrett, 512 BUs (their DSE; U280: 699/504/5888/1024/384, 1.80 us)
    'Ib_n8192_q36b_B512': (8192, 512, MF.odd(36), 'barrett', dict(CYC, ioLanes=64)),
    # I-c: N=2^14, 54-bit Barrett, 256 BUs (U280: 663/608/5632/1152/256, 3.11 us)
    'Ic_n16384_q54b_B256': (16384, 256, MF.odd(54), 'barrett', dict(CYC, ioLanes=64)),
    # the products by the run-time modulus constants (Barrett MU, Q; WLM QH) on Booth LUT multipliers: fewer DSPs
    'Id_n65536_q52w_B32_qb': (65536, 32, MF.friendly(26, 26), 'wlm', dict(CYC, qBackend='booth')),
    'Ie_n65536_q64b_B64_qb': (65536, 64, MF.odd(64), 'barrett', dict(CYC, qBackend='booth')),
    'If_n131072_q64b_B64_qb': (131072, 64, MF.odd(64), 'barrett', dict(CYC, qBackend='booth')),
    # one more read register (ramLatency 3): the 2^17 row's worst path was a data-bank BRAM -> mux -> butterfly
    'If_n131072_q64b_B64_r3': (131072, 64, MF.odd(64), 'barrett', dict(CYC, ramLatency=3)),
    # a 60 % DSP budget (of the pure-DSP count), split top-down (core/dspbudget.py)
    'Ia_n4096_q60w_B8_d60': (4096, 8, MF.friendly(30, 30), 'wlm', dict(CYC, dspFraction=0.6)),
    'Ie_n65536_q64b_B64_d60': (65536, 64, MF.odd(64), 'barrett', dict(CYC, dspFraction=0.6)),
    # design space around I-a
    'Da_n4096_q60w_B2': (4096, 2, MF.friendly(30, 30), 'wlm', dict(CYC)),
    'Da_n4096_q60w_B4': (4096, 4, MF.friendly(30, 30), 'wlm', dict(CYC)),
    'Da_n4096_q60w_B16': (4096, 16, MF.friendly(30, 30), 'wlm', dict(CYC)),
    'Da_n4096_q60w_B32': (4096, 32, MF.friendly(30, 30), 'wlm', dict(CYC)),
    'Da_n4096_q60w_B8_booth': (4096, 8, MF.friendly(30, 30), 'wlm', dict(CYC, qBackend='booth')),
    'Da_n4096_q64w32_B8': (4096, 8, MF.friendly(32, 32), 'wlm', dict(CYC)),
    'Da_n4096_q60w_B8_nwc': (4096, 8, MF.friendly(30, 30), 'wlm', dict(nwc=True, ioLanes=2)),
    'Da_n1024_q28f_B8': (1024, 8, 2 ** 28 - 2 ** 16 + 1, 'fold', dict(CYC)),
    # RNS mode (a modulus per polynomial, twiddleBuffer 'recycle' = the default), the four board rows; with a
    # 60 % DSP budget; and 'double' (a second twiddle copy) for the cost comparison
    'Ia_n4096_q60w_B8_rns': (4096, 8, MF.friendly(30, 30), 'wlm', dict(RNS)),
    'Id_n65536_q52w_B32_rns': (65536, 32, MF.friendly(26, 26), 'wlm', dict(RNS)),
    'Ie_n65536_q64b_B64_rns': (65536, 64, MF.odd(64), 'barrett', dict(RNS)),
    'If_n131072_q64b_B64_r3_rns': (131072, 64, MF.odd(64), 'barrett', dict(RNS, ramLatency=3)),
    'Ia_n4096_q60w_B8_rns60': (4096, 8, MF.friendly(30, 30), 'wlm', dict(RNS, dspFraction=0.6)),
    'Id_n65536_q52w_B32_rns60': (65536, 32, MF.friendly(26, 26), 'wlm', dict(RNS, dspFraction=0.6)),
    'Ie_n65536_q64b_B64_rns60': (65536, 64, MF.odd(64), 'barrett', dict(RNS, dspFraction=0.6)),
    'If_n131072_q64b_B64_r3_rns60': (131072, 64, MF.odd(64), 'barrett', dict(RNS, ramLatency=3, dspFraction=0.6)),
    'Ia_n4096_q60w_B8_dbl': (4096, 8, MF.friendly(30, 30), 'wlm', dict(RNS, twiddleBuffer='double')),
    # 2026-11-08 evening: the two rows that failed place / route in place, with memOrg 'auto' (the generator's
    # default; the cost model picks constant geometry there), one modulus per job (the fair match to AutoNTT-I)
    # and a modulus per polynomial (RNS, recycle)
    # negacyclic with a modulus per polynomial (real FHE): the inverse's output twist per polynomial in the record
    # both directions on one core, AutoNTT-I I1's size and moduli
    'Ia_n4096_q60w_B8_nwc_rns': (4096, 8, MF.friendly(30, 30), 'wlm', dict(nwc=True, inverseScale='output',
                                                                          twiddleBuffer='recycle')),
    # first run (OOC 2026-11-08 evening): no SLR crossing registers (crossRegs 0, the generator's default then)
    'Ib_n8192_q36b_B512_auto': (8192, 512, MF.odd(36), 'barrett', dict(CYC, ioLanes=64, memOrg='auto', crossRegs=0)),
    'Ic_n16384_q54b_B256_auto': (16384, 256, MF.odd(54), 'barrett', dict(CYC, ioLanes=64, memOrg='auto', crossRegs=0)),
    # 2026-11-12: I1's RNS row with the twiddle tables generated on chip, in place (twiddleSource 'rec',
    # memOrg 'inplace'; the record is its header alone). Results: rns/iprec/RESULTS_iprec.md
    'Ia_n4096_q60w_B8_rns_rec': (4096, 8, MF.friendly(30, 30), 'wlm', dict(RNS, memOrg='inplace', twiddleSource='rec')),
    # ---- 2026-11-12, recSeeds study (rns/iprec_seeds/RESULTS_iprec_seeds.md): one short-stage design (n 1024,
    # B 8, 36-bit Barrett, 64-cycle stages; NOT an AutoNTT row, prefix 'Sx') three ways: the streamed record
    # ('ram', recycle), 'rec' in place as built before (header alone: 8 generators), 'rec' with seeds on the
    # record stream (recSeeds='auto': 2 generators, 4 seeds a group and stage)
    'Sx_n1024_q36b_B8_rns': (1024, 8, MF.odd(36), 'barrett', dict(RNS)),
    'Sx_n1024_q36b_B8_rns_rec': (1024, 8, MF.odd(36), 'barrett', dict(RNS, memOrg='inplace', twiddleSource='rec')),
    'Sx_n1024_q36b_B8_rns_recseeds': (1024, 8, MF.odd(36), 'barrett',
                                      dict(RNS, memOrg='inplace', twiddleSource='rec', recSeeds='auto')),
    # ---- end of the recSeeds study rows
    'Ib_n8192_q36b_B512_auto_rns': (8192, 512, MF.odd(36), 'barrett', dict(RNS, ioLanes=64, memOrg='auto', crossRegs=0)),
    'Ic_n16384_q54b_B256_auto_rns': (16384, 256, MF.odd(54), 'barrett', dict(RNS, ioLanes=64, memOrg='auto', crossRegs=0)),
    # second run (ablation 'die-crossing registers'): crossRegs 2 and the hardened control fan-out (explicit: the
    # generator's default is off since 2026-11-09)
    'Ib_n8192_q36b_B512_x2': (8192, 512, MF.odd(36), 'barrett', dict(CYC, ioLanes=64, memOrg='auto', crossRegs=2)),
    'Ic_n16384_q54b_B256_x2': (16384, 256, MF.odd(54), 'barrett', dict(CYC, ioLanes=64, memOrg='auto', crossRegs=2)),
    'Ib_n8192_q36b_B512_x2_rns': (8192, 512, MF.odd(36), 'barrett', dict(RNS, ioLanes=64, memOrg='auto', crossRegs=2)),
    'Ic_n16384_q54b_B256_x2_rns': (16384, 256, MF.odd(54), 'barrett', dict(RNS, ioLanes=64, memOrg='auto', crossRegs=2)),
    'Id_n65536_q52w_B32_dbl': (65536, 32, MF.friendly(26, 26), 'wlm', dict(RNS, twiddleBuffer='double')),
    # 2026-11-09: the RNS I2 / I3 rows with the twiddles generated on chip (twiddleSource 'rec': the record is the
    # modulus constants, two factors per late stage and the first H+2 stage regions, two entries a beat; groups
    # of recGroup butterflies derive the other regions with one modular multiplier each). Constant geometry given
    # explicitly (what 'auto' picks for the _auto_rns rows; 'rec' is built for constant geometry only)
    'Ib_n8192_q36b_B512_auto_rns_rec': (8192, 512, MF.odd(36), 'barrett', dict(RNS, ioLanes=64, memOrg='constgeo',
                                                                              crossRegs=0, twiddleSource='rec')),
    'Ic_n16384_q54b_B256_auto_rns_rec': (16384, 256, MF.odd(54), 'barrett', dict(RNS, ioLanes=64, memOrg='constgeo',
                                                                               crossRegs=0, twiddleSource='rec')),
}
# 2026-11-09 evening: the 'rec' rows with fan-out trees on the broadcasts (fanout = loads per register; f64 the
# default of these rows, f32 deeper trees) and a DSP budget over every multiplier (butterflies and twiddle
# generators, one top-down split: d100 / d80 / d60 of the pure-DSP count), or the generators on LUTs (lutgen)
for _r in ('Ib_n8192_q36b_B512_auto_rns_rec', 'Ic_n16384_q54b_B256_auto_rns_rec'):
    _n, _B, _m, _red, _x = ROWS[_r]
    ROWS[_r + '2'] = (_n, _B, _m, _red, dict(_x, fanout=64))
    ROWS[_r + '2f32'] = (_n, _B, _m, _red, dict(_x, fanout=32))
    for _f in (100, 80, 60):
        ROWS[_r + f'2_d{_f}'] = (_n, _B, _m, _red, dict(_x, fanout=64, dspFraction=_f / 100))
    ROWS[_r + '2_lutgen'] = (_n, _B, _m, _red, dict(_x, fanout=64, recMultiplier={'multiplier': 'booth',
                                                                                 'qBackend': 'booth'}))
    # 2026-11-10: the trees with only their own registers kept (fanoutKeepSinks False): the I2 rec2 synthesis with
    # every sink kept never left technology mapping (7.8 h)
    ROWS[_r + '2nk'] = (_n, _B, _m, _red, dict(_x, fanout=64, fanoutKeepSinks=False))
    # and the bank trees sized by the pins they reach (rec2nk reached 174 MHz: one fill leaf drove 64 banks' enables)
    ROWS[_r + '2p'] = (_n, _B, _m, _red, dict(_x, fanout=64, fanoutKeepSinks=False, fanoutLoads='pins'))


def pairOf(row):
    """The row's two AutoNTT-I primes (RNS tests), by its letter."""
    return PRIME_PAIRS.get(row.split('_')[0])


def scheme(row, tgt=350.0):
    n, B, mod, red, extra = ROWS[row]
    extra = dict(extra)
    nwc = extra.pop('nwc', True)
    fam = mod if not isinstance(mod, int) else None
    q = 0 if fam else mod
    src = extra.pop('twiddleSource', 'ram' if fam else None)
    return r.iterative(row, n, B, q, red, nwc, 'both', family=fam, source=src, targetFmaxMhz=tgt, **extra)


def model(row):
    t0 = time.time()
    with contextlib.redirect_stdout(io.StringIO()):
        s = scheme(row)
        res = s.resources()
        job = s.simulateJob(3)
    md = dict(row=row, n=s.n, B=s.B, io=s.io, width=s.memBound.bitWidth, buLatency=s.buLatency(),
              writeLatency=s.writeLatency(), computeCycles=s.computeCycles(), latency=job['latency'],
              interval=job['interval'], lut=res['lut'], ff=res['ff'], dsp=res['dsp'], bram=res['bram'],
              uram=res['uram'], twiddleWords=s.twiddleWords(), criticalPathNs=s.criticalPathNs(),
              breakdown={k: v for k, v in res['breakdown'].items()}, twiddleBuffer=s.twiddleBuffer,
              memOrg=s.memOrg, memOrgReport=s.memOrgReport())
    if s.rns:
        with contextlib.redirect_stdout(io.StringIO()):
            jk = s.simulateJob(3, records=[False, True, True])
        md.update(twLanes=s.twiddleLanes(), twBeatBits=s.twiddleLanes() * s.twEntryWidth(),
                  headerBeats=s.headerBeats(), recordBeats=s.recordBeats(), bubble=s.rnsBubble(),
                  intervalKept=jk['interval'], latencyKept=jk['latency'])
        if s.rec:
            md.update(twiddleSource='rec', recGroup=s.recGroup(), recGenerators=s.B // s.recGroup(),
                      recUnits=len(s.recUnits()), genLatency=s.genLatency(), headerBits=s.headerBits(),
                      recordBits=s.recordBeats() * s.twiddleLanes() * s.twEntryWidth())
            if getattr(s, 'recIp', False) and s.recSeedCount():       # seeds on the record stream (recSeeds)
                md.update(recSeeds=s.recSeedCount(), recSeedWords=s.recIpPlan()['seedWords'],
                          recSeedBeats=s.recStreamBeats())
    md['seconds'] = round(time.time() - t0)
    return md


def autonttPrime(row):
    '''AutoNTT's own modulus for the row (its host's search): WLM the smallest prime k*2^(log q/2) + 1 >= 2^(log q - 1),
    Barrett the smallest prime k*N + 1 >= 2^(log q - 1) + 1.'''
    from operator_modeling.modmult.primes import isPrime
    n, B, mod, red, extra = ROWS[row]
    bits = mod.qMax.bit_length() if not isinstance(mod, int) else mod.bit_length()
    step = 1 << (bits // 2) if red == 'wlm' else n
    k = -(-(2 ** (bits - 1) + (0 if red == 'wlm' else 1) - 1) // step)
    while not isPrime(k * step + 1):
        k += 1
    q = k * step + 1
    assert mod.contains(q), (row, q)
    return q


def build(row, npoly=3, direction='inv', valid=None, theirQ=False, out=None):
    s = scheme(row)
    rng = random.Random(11)
    q = autonttPrime(row) if theirQ else r._jobQ(s, rng)
    extra = {}
    if s.rns:                     # a modulus per polynomial: AutoNTT-I's two primes alternating
        qa, qb = pairOf(row)
        q = [qa if k % 2 == 0 else qb for k in range(npoly)]
        extra = dict(twValidPattern=valid)
    frames = [[rng.randrange(qq) for _ in range(s.n)] for qq in (q if isinstance(q, list) else [q] * npoly)]
    t0 = time.time()
    with contextlib.redirect_stdout(io.StringIO()):
        m = IterativeNTT(s).emitRtl(row, out or f'{OUT}/{row}', frames=frames, direction=direction, q=q,
                                    validPattern=valid, **extra)
    md = model(row)
    md.update(q=q, manifest=m, gen_seconds=round(time.time() - t0))
    json.dump(md, open(f'{out or OUT + "/" + row}/model.json', 'w'), indent=1, default=str)
    return md


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('rows', nargs='+')
    ap.add_argument('--model', action='store_true')
    ap.add_argument('--polys', type=int, default=3)
    ap.add_argument('--their-q', action='store_true', help="testbench with AutoNTT's own prime, into ooc/<row>_tq/ "
                                                         "(also a random input valid)")
    a = ap.parse_args()
    for row in a.rows:
        if a.model:
            m = model(row)
        elif a.their_q:
            m = build(row, a.polys, theirQ=True, valid='random',
                      out=f'{OUT}/{row}_tq')
            print(row, 'q =', m['q'])
        else:
            m = build(row, a.polys)
        print(json.dumps({k: m[k] for k in ('row', 'n', 'B', 'io', 'width', 'buLatency', 'writeLatency',
                                            'computeCycles', 'latency', 'interval', 'lut', 'ff', 'dsp', 'bram',
                                            'uram', 'criticalPathNs', 'seconds')}), flush=True)
