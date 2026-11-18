"""Generate the streaming NTTs for AutoNTT's dataflow parameter sets (both
directions on one pipeline, 350 MHz target), with a testbench each."""
import os, sys, time, random, contextlib, io, json
GEN = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, GEN)
import runModularNTT as r
from operator_modeling.ntt.NTT import StreamingNTT
from operator_modeling.modmult.ModulusFamily import ModulusFamily as MF
OUT = os.environ.get('PAPER_OUT', os.path.join(GEN, 'work', 'dataflow'))
q28 = 2**28 - 2**16 + 1
# AutoNTT's own moduli for its 2^17 / 62-bit dataflow design: the first and third primes k*2^17+1 above 2^61
# (its generator's search; its C simulation and RTL vectors use these two, one per job). Only 2^17 | q-1.
AUTONTT_Q17 = [2305843009218281473, 2305843009220116481]
ROWS = {
    'A1024_q28_P16': (1024, 16, dict(q=q28, red='fold'), 'rom'),
    'A4096_q32wlm_P2': (4096, 2, dict(family=MF.friendly(17, 15), red='wlm'), 'ram'),
    'A4096_q64wlm_P2': (4096, 2, dict(family=MF.friendly(17, 47), red='wlm'), 'ram'),
    'A4096_q64wlm_P16': (4096, 16, dict(family=MF.friendly(17, 47), red='wlm'), 'ram'),
    'A4096_q64wlm_P32': (4096, 32, dict(family=MF.friendly(17, 47), red='wlm'), 'ram'),
    # AutoNTT's U50 rows at n=4096 have 12 butterflies (P2 above); 4 lanes = 24, one NTT per 1024 cycles
    'A4096_q32wlm_P4': (4096, 4, dict(family=MF.friendly(17, 15), red='wlm'), 'ram'),
    'A4096_q64wlm_P4': (4096, 4, dict(family=MF.friendly(17, 47), red='wlm'), 'ram'),
    # the same with the reduction's products by QH on LUT (Booth) multipliers: fewer DSPs
    'A4096_q32wlm_P4b': (4096, 4, dict(family=MF.friendly(17, 15), red='wlm', qBackend='booth'), 'ram'),
    'A4096_q64wlm_P4b': (4096, 4, dict(family=MF.friendly(17, 47), red='wlm', qBackend='booth'), 'ram'),
    # with a register in front of every butterfly (memories end in a register, not in the DSP)
    # 32-bit rows with AutoNTT (b)'s modulus set: q = qH*2^16 + 1, qH exactly 16 bits (its WLM word is 16)
    'A4096_q32w16_P2': (4096, 2, dict(family=MF.friendly(16, 16), red='wlm'), 'ram'),
    'A4096_q32w16_P4': (4096, 4, dict(family=MF.friendly(16, 16), red='wlm'), 'ram'),
    'A4096_q32w16_P4b': (4096, 4, dict(family=MF.friendly(16, 16), red='wlm', qBackend='booth'), 'ram'),
    # 64-bit rows with AutoNTT (c)/(d)'s modulus set: q = qH*2^32 + 1, qH exactly 32 bits (generator picks 2 x 32-bit WLM steps)
    'A4096_q64w32_P2': (4096, 2, dict(family=MF.friendly(32, 32), red='wlm'), 'ram'),
    'A4096_q64w32_P4': (4096, 4, dict(family=MF.friendly(32, 32), red='wlm'), 'ram'),
    'A4096_q64w32_P4b': (4096, 4, dict(family=MF.friendly(32, 32), red='wlm', qBackend='booth'), 'ram'),
    'A4096_q64w32_P16i': (4096, 16, dict(family=MF.friendly(32, 32), red='wlm', inputRegister=True), 'ram'),
    'A4096_q64w32_P32i': (4096, 32, dict(family=MF.friendly(32, 32), red='wlm', inputRegister=True), 'ram'),
    # cyclic rows like AutoNTT's (root of order n, no psi), the inverse's n^-1 as x2^-1 per stage (no output multiplier)
    'A1024_q28_P16c': (1024, 16, dict(q=q28, red='fold', nwc=False, inverseScale='stage'), 'rom'),
    'A4096_q32w16_P2c': (4096, 2, dict(family=MF.friendly(16, 16), red='wlm', nwc=False, inverseScale='stage'), 'ram'),
    'A4096_q32w16_P4c': (4096, 4, dict(family=MF.friendly(16, 16), red='wlm', nwc=False, inverseScale='stage'), 'ram'),
    'A4096_q32w16_P4bc': (4096, 4, dict(family=MF.friendly(16, 16), red='wlm', qBackend='booth', nwc=False,
                                        inverseScale='stage'), 'ram'),
    'A4096_q64w32_P2c': (4096, 2, dict(family=MF.friendly(32, 32), red='wlm', nwc=False, inverseScale='stage'), 'ram'),
    'A4096_q64w32_P4c': (4096, 4, dict(family=MF.friendly(32, 32), red='wlm', nwc=False, inverseScale='stage'), 'ram'),
    'A4096_q64w32_P4bc': (4096, 4, dict(family=MF.friendly(32, 32), red='wlm', qBackend='booth', nwc=False,
                                        inverseScale='stage'), 'ram'),
    'A4096_q64w32_P16ic': (4096, 16, dict(family=MF.friendly(32, 32), red='wlm', inputRegister=True, nwc=False,
                                          inverseScale='stage'), 'ram'),
    'A4096_q64w32_P32ic': (4096, 32, dict(family=MF.friendly(32, 32), red='wlm', inputRegister=True, nwc=False,
                                          inverseScale='stage'), 'ram'),
    # (a) cyclic with its twiddles loaded from HBM like AutoNTT's port (instead of ROM): board comparison
    'A1024_q28_P16cr': (1024, 16, dict(q=q28, red='fold', nwc=False, inverseScale='stage'), 'ram'),
    # 32 points per cycle = AutoNTT's 16 butterflies per stage (N/32 cycles per polynomial), added 2026-11-17
    'A1024_q28_P32cr': (1024, 32, dict(q=q28, red='fold', nwc=False, inverseScale='stage'), 'ram'),
    # the fair board rows with Gentleman-Sande butterflies (both directions on one pipeline)
    'A1024_q28_P16cr_gs': (1024, 16, dict(q=q28, red='fold', nwc=False, inverseScale='stage', butterflyType='GS'), 'ram'),
    'A4096_q32w16_P2c_gs': (4096, 2, dict(family=MF.friendly(16, 16), red='wlm', nwc=False, inverseScale='stage',
                                          butterflyType='GS'), 'ram'),
    'A4096_q64w32_P2c_gs': (4096, 2, dict(family=MF.friendly(32, 32), red='wlm', nwc=False, inverseScale='stage',
                                          butterflyType='GS'), 'ram'),
    'A4096_q64w32_P32ic_gs': (4096, 32, dict(family=MF.friendly(32, 32), red='wlm', inputRegister=True, nwc=False,
                                             inverseScale='stage', butterflyType='GS'), 'ram'),
    # AutoNTT's fifth dataflow row: n = 2^17, 62-bit modulus, Barrett (paper: U280, 2,176 DSP); cyclic like theirs,
    # run-time q from the odd 62-bit family, twiddles loaded per job; P to match their butterflies per stage
    'A131072_q62b_P8c': (131072, 8, dict(family=MF.odd(62), red='barrett', nwc=False, inverseScale='stage',
                                         jobQ=AUTONTT_Q17), 'ram'),
    'A131072_q62b_P16c': (131072, 16, dict(family=MF.odd(62), red='barrett', nwc=False, inverseScale='stage',
                                          jobQ=AUTONTT_Q17), 'ram'),
    # with a register in front of every butterfly: the delay-line RAM -> swap -> DSP path limited P8c to 304 MHz
    'A131072_q62b_P8ci': (131072, 8, dict(family=MF.odd(62), red='barrett', nwc=False, inverseScale='stage',
                                          inputRegister=True, jobQ=AUTONTT_Q17), 'ram'),
    # 60% DSP budget (of the pure-DSP count, split top-down by pure-DSP weights, largest remainder)
    'A1024_q28_P16_d60': (1024, 16, dict(q=q28, red='fold', dspFraction=0.6), 'rom'),
    'A1024_q28_P16c_d60': (1024, 16, dict(q=q28, red='fold', nwc=False, inverseScale='stage', dspFraction=0.6), 'rom'),
    'A4096_q32w16_P2_d60': (4096, 2, dict(family=MF.friendly(16, 16), red='wlm', dspFraction=0.6), 'ram'),
    'A4096_q32w16_P2c_d60': (4096, 2, dict(family=MF.friendly(16, 16), red='wlm', nwc=False, inverseScale='stage',
                                           dspFraction=0.6), 'ram'),
    'A4096_q64w32_P2_d60': (4096, 2, dict(family=MF.friendly(32, 32), red='wlm', dspFraction=0.6), 'ram'),
    'A4096_q64w32_P2c_d60': (4096, 2, dict(family=MF.friendly(32, 32), red='wlm', nwc=False, inverseScale='stage',
                                           dspFraction=0.6), 'ram'),
    'A4096_q64w32_P32i_d60': (4096, 32, dict(family=MF.friendly(32, 32), red='wlm', inputRegister=True,
                                             dspFraction=0.6), 'ram'),
    'A4096_q64w32_P32ic_d60': (4096, 32, dict(family=MF.friendly(32, 32), red='wlm', inputRegister=True, nwc=False,
                                              inverseScale='stage', dspFraction=0.6), 'ram'),
    'A4096_q64wlm_P16i': (4096, 16, dict(family=MF.friendly(17, 47), red='wlm', inputRegister=True), 'ram'),
    'A4096_q64wlm_P32i': (4096, 32, dict(family=MF.friendly(17, 47), red='wlm', inputRegister=True), 'ram'),
    # small rows for testing the project flow
    'T64_P8_rt': (64, 8, dict(family=MF.friendly(17, 15), red='wlm'), 'ram'),
    'T64_P8_fx': (64, 8, dict(q=2**28 - 2**16 + 1, red='fold'), 'rom'),
}
def build(name, nframes=2, direction='inv', tgt=350.0):
    n, P, mod, src = ROWS[name]
    extra = {k: v for k, v in mod.items() if k not in ('q', 'family', 'red', 'nwc', 'jobQ')}
    s = r.stream(name, n, P, mod.get('q', 0), mod['red'], mod.get('nwc', True), 'both', family=mod.get('family'), source=src,
                 targetFmaxMhz=tgt, **extra)
    rng = random.Random(11)
    # rows with jobQ (the comparison target's own moduli): PAPER_JOBQ picks which one the testbench uses
    q = mod['jobQ'][int(os.environ.get('PAPER_JOBQ', '0'))] if mod.get('jobQ') else r._jobQ(s, rng)
    frames = [[rng.randrange(q) for _ in range(n)] for _ in range(nframes)]
    t0 = time.time()
    with contextlib.redirect_stdout(io.StringIO()):
        m = StreamingNTT(s).emitRtl(name, f'{OUT}/{name}', frames=frames, direction=direction, q=q)
        lut, dsp = s.areaCost()
    m.update(model_lut=lut, model_dsp=dsp, q=q, twiddle_words=s.twiddleWords(), exchange_words=s.exchangeWords(),
             critical_path_ns=s.criticalPathNs(1), gen_seconds=round(time.time() - t0))
    json.dump(m, open(f'{OUT}/{name}/model.json', 'w'), indent=1)
    return m
if __name__ == '__main__':
    for nm in sys.argv[1:]:
        m = build(nm)
        print(nm, {k: m[k] for k in ('latency', 'model_lut', 'model_dsp', 'load_words', 'gen_seconds')})
