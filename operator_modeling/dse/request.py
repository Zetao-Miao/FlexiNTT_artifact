'''The request file: the user's inputs in a text file that is easy to read and fill in.

    reqFields, run = loadRequest('my_request.toml')
    req = Requirements(**reqFields)

The file is TOML with the sections [ntt], [performance], [resources], [bandwidth], [search] and [run].
`userNTTinput.toml` in the repository root is the commented template (`writeTemplate` copies it).
A key that is absent does not constrain. A key or section the reader does not know is an error, so a typing
mistake cannot silently drop a limit.
'''
from __future__ import annotations

import difflib
import os
import shutil
import tomllib

from .record import PORT_KINDS

TEMPLATE = os.path.join(os.path.dirname(__file__), '..', '..', 'userNTTinput.toml')    # the repository root
ARCHS = ('iterative', 'hybrid', 'dataflow', 'multistep')

NUM, INT, BOOL, STR, LIST = 'a number', 'a whole number', 'true or false', 'text in quotes', 'a list [...]'

#: section -> {key in the file: (Requirements field, kind of value)}
FIELDS = {
    'ntt': {
        'points': ('n', INT),
        'moduli': ('moduli', LIST),
        'modulus_bits': ('qBits', INT),
        'num_moduli': ('numModuli', INT),
        'modulus_form': ('modulusForm', STR),
        'modulus_slots': ('modulusSlots', STR),
        'form_v': ('formV', INT),
        'form_k_bits': ('formKBits', INT),
        'form_c_bits': ('formCBits', INT),
        'transform': ('transform', STR),
        'direction': ('direction', STR),
        'modulus_per_polynomial': ('perPolyModulus', BOOL),
        'direction_per_polynomial': ('perPolyDirection', BOOL),
        'run_length': ('run', NUM),
        'output_order': ('outputOrder', STR),
        'output_backpressure': ('outputBackpressure', BOOL),
    },
    'performance': {
        'clock_mhz': ('clockMhz', NUM),
        'min_ntt_per_second': ('minNttPerS', NUM),
        'max_cycles_per_ntt': ('maxIntervalCycles', NUM),
        'max_latency_cycles': ('maxLatencyCycles', NUM),
        'max_latency_us': ('maxLatencyUs', NUM),
    },
    'resources': {
        'max_lut': ('maxLut', NUM),
        'max_ff': ('maxFf', NUM),
        'max_dsp': ('maxDsp', NUM),
        'max_bram36': ('maxBram36', NUM),
        'max_uram': ('maxUram', NUM),
    },
    'bandwidth': {
        'data_in_bits_per_cycle': ('maxDataInBits', NUM),
        'data_out_bits_per_cycle': ('maxDataOutBits', NUM),
        'allow_twiddle_stream': ('allowTwiddleStream', BOOL),
        'max_twiddle_stream_bits_per_cycle': ('maxTwiddleStreamBits', NUM),
        'allow_table_load': ('allowTableLoad', BOOL),
        'max_table_load_bits': ('maxTableLoadBits', NUM),
        'allow_record_stream': ('allowRecordStream', BOOL),
        'max_record_stream_bits_per_cycle': ('maxRecordStreamBits', NUM),
        'max_outside_table_bits': ('maxOutsideTableBits', NUM),
    },
    'search': {
        'allow_timing_risk': ('allowRiskFlags', BOOL),
        'sizing': ('sizing', STR),
    },
}
#: keys handled by hand (not a plain copy into one Requirements field)
SPECIAL = {
    'ntt': {'pick_moduli': BOOL},
    'search': {'architectures': LIST, 'options': 'a table'},
}
#: [run] keys -> (name used by runDse, kind)
RUN = {
    'output_folder': ('out', STR), 'show': ('show', STR), 'jobs': ('jobs', INT), 'cache': ('cache', STR),
    'records': ('records', LIST), 'limit': ('limit', INT), 'sample': ('sample', INT), 'seed': ('seed', INT),
}
#: measure of one kind of port in the file -> name in Requirements.maxByKind
MEASURES = {'max_bits_per_ntt': 'bitsPerNtt', 'max_avg_bits_per_cycle': 'avgBitsPerCycle',
            'max_peak_bits_per_cycle': 'peakBitsPerCycle'}


class RequestError(ValueError):
    '''A mistake in the request file, worded for the person who filled it in.'''


def _unknown(what: str, name: str, valid, where: str) -> RequestError:
    near = difflib.get_close_matches(name, list(valid), n=1)
    hint = f' Did you mean "{near[0]}"?' if near else ''
    return RequestError(f'{where}: {what} "{name}" is not known.{hint} Known: {", ".join(sorted(valid))}.')


def _typed(val, kind: str, where: str):
    ok = {
        NUM: isinstance(val, (int, float)) and not isinstance(val, bool),
        INT: isinstance(val, int) and not isinstance(val, bool),
        BOOL: isinstance(val, bool),
        STR: isinstance(val, str),
        LIST: isinstance(val, list),
    }[kind]
    if not ok:
        raise RequestError(f'{where} must be {kind}, got {val!r}.')
    return val


def _oneOf(val, valid, where: str):
    if val not in valid:
        raise _unknown('value', str(val), valid, where)
    return val


def loadRequest(path: str) -> tuple:
    '''Read a request file. Returns (fields for Requirements(**fields), run settings for runDse).

    `pick_moduli = true` comes back as run['pickModuli']: the caller picks the primes with `pickModuli` once
    the options that override the file are applied.'''
    with open(path, 'rb') as f:
        try:
            doc = tomllib.load(f)
        except tomllib.TOMLDecodeError as e:
            raise RequestError(f'{path}: not valid TOML. {e}. Text values need quotes, and each key may '
                               f'appear once.') from None
    sections = set(FIELDS) | {'run'}
    for sec in doc:
        if sec not in sections:
            raise _unknown('section', f'[{sec}]', [f'[{s}]' for s in sections], path)
        if not isinstance(doc[sec], dict):
            raise RequestError(f'{path}: "{sec}" must be a section header, written [{sec}].')
    if 'ntt' not in doc:
        raise RequestError(f'{path}: the [ntt] section is missing.')

    d = {}
    for sec, keys in FIELDS.items():
        body = doc.get(sec, {})
        known = set(keys) | set(SPECIAL.get(sec, {}))
        for key, val in body.items():
            where = f'{path} [{sec}] {key}'
            if key not in known:
                raise _unknown('key', key, known, f'{path} [{sec}]')
            if key in keys:
                field, kind = keys[key]
                d[field] = _typed(val, kind, where)

    # --- [ntt] --------------------------------------------------------------------------------------------
    ntt = doc['ntt']
    if 'points' not in ntt:
        raise RequestError(f'{path} [ntt]: "points" is missing.')
    if d['n'] < 4 or d['n'] & (d['n'] - 1):
        raise RequestError(f'{path} [ntt]: "points" must be a power of two, got {d["n"]}.')
    for key, valid in (('transform', ('cyclic', 'negacyclic', 'both')), ('direction', ('forward', 'inverse', 'both')),
                       ('output_order', ('any', 'natural')),
                       ('modulus_form', ('ntt', 'friendly', 'kred', 'pseudo_mersenne')),
                       ('modulus_slots', ('resident', 'rotating', 'either'))):
        if key in ntt:
            _oneOf(ntt[key], valid, f'{path} [ntt] {key}')
    if 'moduli' in d:
        d['moduli'] = [_typed(q, INT, f'{path} [ntt] moduli entry') for q in d['moduli']]
    pick = _typed(ntt.get('pick_moduli', False), BOOL, f'{path} [ntt] pick_moduli')
    if pick and d.get('moduli'):
        raise RequestError(f'{path} [ntt]: give "moduli" or "pick_moduli = true", not both.')
    if pick:
        if 'qBits' not in d:
            raise RequestError(f'{path} [ntt]: "pick_moduli = true" needs "modulus_bits".')
    if not d.get('moduli') and 'qBits' not in d and not pick:
        raise RequestError(f'{path} [ntt]: give "moduli = [...]" or "modulus_bits".')
    if d.get('moduli') and 'numModuli' in d and d['numModuli'] != len(d['moduli']) and not pick:
        raise RequestError(f'{path} [ntt]: "num_moduli" is {d["numModuli"]} but "moduli" lists '
                           f'{len(d["moduli"])}.')

    # --- [bandwidth] --------------------------------------------------------------------------------------
    need = ('data_in_bits_per_cycle', 'data_out_bits_per_cycle', 'allow_twiddle_stream', 'allow_table_load',
            'allow_record_stream', 'max_outside_table_bits')
    missing = [k for k in need if k not in doc.get('bandwidth', {})]
    if missing:
        raise RequestError(f'{path} [bandwidth]: these lines are needed: ' + ', '.join(missing) + '.')

    # --- [search] -----------------------------------------------------------------------------------------
    se = doc.get('search', {})
    if 'architectures' in se:
        archs = _typed(se['architectures'], LIST, f'{path} [search] architectures')
        if not archs:
            raise RequestError(f'{path} [search]: "architectures" is empty.')
        d['archs'] = tuple(_oneOf(a, ARCHS, f'{path} [search] architectures') for a in archs)
    for arch, opts in (se.get('options') or {}).items():
        where = f'{path} [search.options.{arch}]'
        _oneOf(arch, ARCHS, f'{path} [search.options]')
        if not isinstance(opts, dict):
            raise RequestError(f'{where} must be a section with one line per option.')
        for opt, vals in opts.items():
            _typed(vals, LIST, f'{where} {opt}')
        # TOML has no empty value: "none" in a list stands for it (an option that is switched off)
        d.setdefault('options', {})[arch] = {o: [None if v == 'none' else v for v in vals] for o, vals in opts.items()}

    # --- [run] --------------------------------------------------------------------------------------------
    run = {'pickModuli': True} if pick else {}
    for key, val in doc.get('run', {}).items():
        if key not in RUN:
            raise _unknown('key', key, RUN, f'{path} [run]')
        name, kind = RUN[key]
        run[name] = _typed(val, kind, f'{path} [run] {key}')
    if 'show' in run:
        _oneOf(run['show'], ('front', 'feasible', 'records'), f'{path} [run] show')
    return d, run


def pickModuli(d: dict, bits: int | None = None) -> list:
    '''NTT primes of `bits` bits (default d['qBits']) with the modulus form stated in the Requirements fields `d`,
    as many as d['numModuli'].'''
    from . import modform
    from .spec import Requirements
    probe = Requirements(**{**d, 'moduli': [], 'qBits': bits or d['qBits']})    # checks the form against the width
    try:
        return modform.samplePrimes(probe.form, probe.width, probe.rootOrder, probe.M)
    except ValueError as e:
        raise RequestError(str(e)) from None


def writeTemplate(path: str) -> str:
    '''Copy the commented template to `path`. An existing file is never overwritten.'''
    if os.path.exists(path):
        raise RequestError(f'{path} exists already. Give another name.')
    shutil.copyfile(TEMPLATE, path)
    return path
