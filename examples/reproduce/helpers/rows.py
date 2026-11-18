"""Multi-step NTT rows matched to TP-NTT's Table 2 (BASELINE.md): same n, lanes tau (= P), log q; ours with a
modulus and a direction per polynomial (k = 1, every modulus resident, no reload), negacyclic, merged twists.

Prime families: 60-bit = TP-NTT's own restricted form q = qH*2^43 + 1 (17-bit qH; word-level Montgomery),
'_f32' = our k1 rows' q = qH*2^32 + 1 (28-bit qH); 32-bit: q = qH*2^v + 1 with 2N | q - 1.
M (moduli held) = max(2, floor(logQ / log q)), logQ from the HE standard (128-bit classical) as in
stream/k1/k1_rows.py: 2^10: 27, 2^11: 54, 2^12: 109, 2^13: 218, 2^14: 438, 2^15: 881, 2^16: 1762 (extrapolated).
"""
import os
import sys

GEN = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, GEN)

LOGQ = {1 << 10: 27, 1 << 11: 54, 1 << 12: 109, 1 << 13: 218, 1 << 14: 438, 1 << 15: 881, 1 << 16: 1762}

# name: (N, sizes, P, (v, qhBits), TP-NTT row). Sizes: the model's cheapest factorisation (ms/dse/*.jsonl,
# chooseFactorization) where it was swept (N12_q60_P32 keeps [32, 4, 32]: 2 % from the best, its OOC started first)
ROWS = {
    'MS_N10_q32_P32': (1 << 10, [32, 32], 32, (16, 16), '32 / 2^10 / 32: 94k LUT, 800 DSP, 0 RAM, 250 MHz, 0.14 us'),
    'MS_N12_q32_P64': (1 << 12, [64, 64], 64, (16, 16), '32 / 2^12 / 64: 242k LUT, 1920 DSP, 0 RAM, 250 MHz, 0.27 us'),
    'MS_N12_q60_P32': (1 << 12, [32, 4, 32], 32, (43, 17), '60 / 2^12 / 32: 250k LUT, 2112 DSP, 32 RAM, 250 MHz, 0.52 us'),
    'MS_N12_q60_P64': (1 << 12, [64, 64], 64, (43, 17), '60 / 2^12 / 64: 532k LUT, 4224 DSP, 0 RAM, 200 MHz, 0.33 us'),
    'MS_N14_q60_P32': (1 << 14, [16, 32, 32], 32, (43, 17), '60 / 2^14 / 32: 311k LUT, 2464 DSP, 69 RAM, 250 MHz, 2.06 us'),
    'MS_N16_q60_P32': (1 << 16, [4, 32, 16, 32], 32, (43, 17), '60 / 2^16 / 32: 361k LUT, 2816 DSP, 1128 RAM, 250 MHz, 8.28 us'),
    'MS_N16_q60_P32_f32': (1 << 16, [4, 32, 16, 32], 32, (32, 28), 'as MS_N16_q60_P32, our k1 rows\' prime family'),
    # TP-NTT's own (folded) form on the same passes, for the measured trade-off
    'MS_N12_q60_P32_fold': (1 << 12, [32, 4, 32], 32, (43, 17), 'as MS_N12_q60_P32, folded form', dict(form='folded')),
    'MS_N10_q32_P32_fold': (1 << 10, [32, 32], 32, (16, 16), 'as MS_N10_q32_P32, folded form', dict(form='folded')),
}
# DSP-budget rows (2026-11-10 20:45): form='auto' (memory first), then the top-down DSP split at 60 / 80 %
for _r in ('MS_N10_q32_P32', 'MS_N12_q60_P32', 'MS_N12_q32_P64', 'MS_N14_q60_P32', 'MS_N16_q60_P32'):
    for _f in (60, 80):
        ROWS[f'{_r}_auto{_f}'] = ROWS[_r][:4] + (ROWS[_r][4] + f', form auto, DSP {_f} %',
                                                 dict(form='auto', dspFraction=_f / 100, budgetRule='memory'))


def numModuli(N, qbits):
    return max(2, LOGQ[N] // qbits)


def row_scheme(row, twiddleSource='auto', **kw):
    import runModularNTT as rm
    from runMultiStep import butterflyOf
    from operator_modeling.modmult.ModulusFamily import ModulusFamily as MF
    from operator_modeling.fourstep.MultiStepScheme import MultiStepScheme
    N, sizes, P, (v, h), _ = ROWS[row][:5]
    if len(ROWS[row]) > 5:
        kw = {**ROWS[row][5], **kw}
    bits = v + h
    M = numModuli(N, bits)
    qs = rm.friendlyPrimes(v, h, 2 * N, M)
    return MultiStepScheme(row, N, sizes, P, moduli=qs, family=MF.friendly(v, h), butterfly=butterflyOf('wlm'),
                           negacyclic=True, direction='both', twists='merged', twiddleSource=twiddleSource,
                           targetFmaxMhz=float(__import__('os').environ.get('MS_ROW_FMAX', 350.0)), **kw)   # MS_ROW_FMAX: 400 MHz runs of 2026-11-17

# TP-NTT-matched (2026-11-10 20:45): one modulus resident and reloadable (q ports + twiddle RAMs with a load port),
# direction per job, form 'auto' (memory first; folded is not loadable), 100 % DSP
for _r in ('MS_N10_q32_P32', 'MS_N12_q60_P32', 'MS_N12_q32_P64', 'MS_N14_q60_P32', 'MS_N16_q60_P32'):
    ROWS[f'{_r}_tpm'] = ROWS[_r][:4] + (ROWS[_r][4] + ', one reloadable modulus (TP-NTT-matched)',
                                        dict(form='auto', loadable=True))
# TP-NTT's own arrangement, reloadable (2026-11-10 21:10): folded, one modulus, port tables and the inverse output
# stage as RAMs on the load port, direction per job, 100 % DSP
for _r in ('MS_N10_q32_P32', 'MS_N12_q60_P32', 'MS_N12_q32_P64', 'MS_N14_q60_P32', 'MS_N16_q60_P32'):
    ROWS[f'{_r}_tpmf'] = ROWS[_r][:4] + (ROWS[_r][4] + ', folded, one reloadable modulus (TP-NTT arrangement)',
                                         dict(form='folded', loadable=True))
# TP-NTT-matched with our DSP budget (2026-11-11, user): one modulus resident and reloadable, direction per job,
# form 'auto' over the loadable forms, then the top-down DSP split at 60 / 80 % (the arithmetic generator's DSP/LUT
# trade), so the like-for-like row also gets our arithmetic optimizations
for _r in ('MS_N10_q32_P32', 'MS_N12_q60_P32', 'MS_N12_q32_P64', 'MS_N14_q60_P32', 'MS_N16_q60_P32'):
    for _f in (60, 80):
        ROWS[f'{_r}_tpm{_f}'] = ROWS[_r][:4] + (ROWS[_r][4] + f', one reloadable modulus (TP-NTT-matched), DSP {_f} %',
                                                dict(form='auto', loadable=True, dspFraction=_f / 100, budgetRule='memory'))

# budget-aware form choice (2026-11-11): every candidate form gets the same DSP count, the pick is the least model
# area (MultiStepScheme.chooseFormBudget). The _auto / _tpm budget rows above keep the earlier rule (memory first,
# then the split), so their built results stay reproducible.
#   _tpm60a / _tpm80a: one reloadable modulus, 60 / 80 % of the leanest form's full DSP count
#   _tpmda: one reloadable modulus, TP-NTT's own DSP count on the V80 (tpntt_v80/results_table.md, variant A)
TPNTT_DSP = {'MS_N10_q32_P32': 800, 'MS_N12_q60_P32': 2112, 'MS_N12_q32_P64': 1920, 'MS_N14_q60_P32': 2464,
             'MS_N16_q60_P32': 2816}
for _r in TPNTT_DSP:
    for _f in (60, 80):
        ROWS[f'{_r}_tpm{_f}a'] = ROWS[_r][:4] + (ROWS[_r][4] + f', one reloadable modulus, DSP {_f} %, least-area form',
                                                 dict(form='auto', loadable=True, dspFraction=_f / 100))
    ROWS[f'{_r}_tpmda'] = ROWS[_r][:4] + (ROWS[_r][4] + f", one reloadable modulus, TP-NTT's DSP count "
                                          f'({TPNTT_DSP[_r]}), least-area form',
                                          dict(form='auto', loadable=True, dspTotal=TPNTT_DSP[_r]))

# 80 % of TP-NTT's own DSP count as our budget (2026-11-17, user)
for _r in TPNTT_DSP:
    ROWS[f'{_r}_tpmd80'] = ROWS[_r][:4] + (ROWS[_r][4] + f", one reloadable modulus, 80 % of TP-NTT's DSP count "
                                           f'({int(0.8 * TPNTT_DSP[_r])}), least-area form',
                                           dict(form='auto', loadable=True, dspTotal=int(0.8 * TPNTT_DSP[_r])))

# folded_gs (2026-11-11): TP-NTT's inverse too (unified CT/GS butterflies, port twiddles in every pass, GS inverse:
# no inter-pass multiplier, no output stage). form='auto' lets it compete from now on; the 'auto' rows above were
# defined (and some built) before it existed, so they keep their candidate set (their definitions are untouched).
for _r in list(ROWS):
    if len(ROWS[_r]) > 5 and ROWS[_r][5].get('form') == 'auto':
        ROWS[_r][5].setdefault('autoForms', ('twist', 'folded'))
#   _tpg: one reloadable modulus, direction per job, full DSP; _tpg60a / _tpg80a: 60 / 80 % of its full DSP count;
#   _tpgda: TP-NTT's own DSP count (TPNTT_DSP). Sizes: any are allowed (no palindrome rule in the built design);
#   2^14 and 2^16 take the wide first and last pass of TP-NTT's own choice ([32, 16, 32], [32, 8, 8, 32]; its
#   32 x 2 x 32 x 32 needs a size-2 pass, which the plan does not take).
TPG_SIZES = {'MS_N14_q60_P32': [32, 16, 32], 'MS_N16_q60_P32': [32, 8, 8, 32]}
for _r in TPNTT_DSP:
    _b = (ROWS[_r][0], TPG_SIZES.get(_r, ROWS[_r][1])) + ROWS[_r][2:4]
    _n = ROWS[_r][4] + ', folded_gs, one reloadable modulus'
    ROWS[f'{_r}_tpg'] = _b + (_n, dict(form='folded_gs', loadable=True))
    for _f in (60, 80):
        ROWS[f'{_r}_tpg{_f}a'] = _b + (_n + f', DSP {_f} %', dict(form='folded_gs', loadable=True, dspFraction=_f / 100))
    ROWS[f'{_r}_tpgda'] = _b + (_n + f", TP-NTT's DSP count ({TPNTT_DSP[_r]})",
                                dict(form='folded_gs', loadable=True, dspTotal=TPNTT_DSP[_r]))
    # _ad (2026-11-12): the table address delayed per stage instead of the twiddle words (portAlign='address')
    ROWS[f'{_r}_tpgda_ad'] = _b + (_n + f", TP-NTT's DSP count ({TPNTT_DSP[_r]}), address-aligned twiddles",
                                   dict(form='folded_gs', loadable=True, dspTotal=TPNTT_DSP[_r], portAlign='address'))
    ROWS[f'{_r}_tpg80a_ad'] = _b + (_n + ', DSP 80 %, address-aligned twiddles',
                                    dict(form='folded_gs', loadable=True, dspFraction=0.8, portAlign='address'))
