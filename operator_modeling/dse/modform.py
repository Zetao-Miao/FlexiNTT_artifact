'''A special form of the moduli that a reduction can use.

The moduli of an NTT always satisfy q = 1 (mod order), order = 2N (negacyclic) or N (cyclic). The user may know more
about moduli that arrive at run time, and states it as a form (`Requirements.form`, a plain dict):

    {'kind': 'ntt'}                          nothing more
    {'kind': 'friendly', 'v': v}             q = h 2^v + 1, v above log2(order)        (word-level Montgomery)
    {'kind': 'kred', 'kBits': b}             q = k 2^m + 1, k of exactly b bits, m = width - b   (K-RED)
    {'kind': 'pseudo_mersenne', 'cBits': b}  q = 2^width - c, c < 2^b                   (Solinas)

The functions take plain values (form, width, order), so an adapter can call them from a record's info dict.
'''
from __future__ import annotations

KINDS = ('ntt', 'friendly', 'kred', 'pseudo_mersenne')
#: reduction -> the form kind that opens it for run-time moduli
OPENS = {'kred': 'kred', 'solinas': 'pseudo_mersenne'}


def val2(x: int) -> int:
    return (x & -x).bit_length() - 1


def problem(form: dict, width: int, order: int) -> str | None:
    '''None when the form is possible for NTT moduli of `width` bits, else the reason in plain words.'''
    k, lo = form['kind'], order.bit_length() - 1
    if k not in KINDS:
        return f'modulus form "{k}" is not one of {", ".join(KINDS)}'
    if k == 'friendly':
        v = form.get('v')
        if v is None:
            return 'the form "friendly" needs v (every q = h 2^v + 1)'
        if v < lo:
            return f'v = {v} is below {lo}, which the NTT itself guarantees. Leave the form at "ntt"'
        if v > width - 1:
            return f'v = {v} leaves no high part in a modulus of {width} bits'
    if k == 'kred':
        b = form.get('kBits')
        if b is None:
            return 'the form "kred" needs kBits (every q = k 2^m + 1 with k of kBits bits)'
        if b < 1 or width - b < lo:
            return (f'kBits = {b} gives q = k 2^{width - b} + 1, but the NTT needs a factor 2^{lo}. '
                    f'kBits can be 1 to {width - lo}')
    if k == 'pseudo_mersenne':
        b = form.get('cBits')
        if b is None:
            return 'the form "pseudo_mersenne" needs cBits (every q = 2^width - c with c below 2^cBits)'
        if b <= lo or b >= width:
            return (f'cBits = {b} is not possible. An NTT modulus 2^{width} - c has c = j 2^{lo} - 1, so cBits '
                    f'must be {lo + 1} to {width - 1}')
    return None


def fits(form: dict, q: int, width: int) -> bool:
    k = form['kind']
    if k == 'friendly':
        return (q - 1) % (1 << form['v']) == 0
    if k == 'kred':
        m = width - form['kBits']
        return q.bit_length() == width and (q - 1) % (1 << m) == 0
    if k == 'pseudo_mersenne':
        return q.bit_length() == width and (1 << width) - q < (1 << form['cBits'])
    return True


def friendlyV(form: dict, width: int, order: int, moduli=()) -> int:
    '''The largest v with q = 1 (mod 2^v) for every modulus: from the list when it is given, else from the NTT and
    the stated form (a K-RED modulus k 2^m + 1 is friendly with v = m).'''
    if moduli:
        return min(val2(int(q) - 1) for q in moduli)
    v = order.bit_length() - 1
    if form['kind'] == 'friendly':
        v = max(v, form['v'])
    if form['kind'] == 'kred':
        v = max(v, width - form['kBits'])
    return v


def family(form: dict, red: str, width: int, order: int):
    '''The run-time ModulusFamily a reduction is built over when only the width and the form are known.
    None: this reduction has no run-time form under this modulus form.'''
    from ..modmult.ModulusFamily import ModulusFamily as MF
    k = form['kind']
    base = red.split('-')[0]
    if red == 'wlm':
        v = min(friendlyV(form, width, order), width - 1)
        return MF.friendly(v, width - v)
    if base == 'kred':
        return MF.kred(width - form['kBits'], form['kBits']) if k == 'kred' else None
    if base == 'solinas':
        return MF.pseudoMersenne(width, form['cBits']) if k == 'pseudo_mersenne' else None
    return MF.odd(width)


_SAMPLES = {}


def samplePrimes(form: dict, width: int, order: int, count: int, skip=()) -> list:
    '''`count` primes of `width` bits with q = 1 (mod order) that have the form, none of `skip`. They stand in for
    run-time moduli in models and testbenches. Raises ValueError when the form has fewer members.'''
    from ..modmult.primes import isPrime
    key = (tuple(sorted(form.items())), width, order, count, tuple(skip))
    if key in _SAMPLES:
        return list(_SAMPLES[key])
    k, out = form['kind'], []
    if k == 'pseudo_mersenne':
        c = order - 1                                   # c = j order - 1
        while len(out) < count and c < (1 << form['cBits']):
            q = (1 << width) - c
            if q not in skip and isPrime(q):
                out.append(q)
            c += order
    else:
        step = 1 << max(order.bit_length() - 1, friendlyV(form, width, order))
        hi = 1 << width
        q = ((1 << (width - 1)) // step + 1) * step + 1
        while len(out) < count and q < hi:
            if q not in skip and isPrime(q):
                out.append(q)
            q += step
    if len(out) < count:
        raise ValueError(f'fewer than {count} NTT primes of {width} bits have the form {form}')
    _SAMPLES[key] = tuple(out)
    return out
