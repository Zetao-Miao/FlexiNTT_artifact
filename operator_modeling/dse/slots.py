'''The rotating slot mode of a core with run-time moduli (rtl_gen/slot_manager.py), for the adapters.

`plan(timing, frame)`: the lead time, the least number of slots for any sequence of moduli, and whether one load
per polynomial keeps up. `managerArea(K)`: the manager, by a formula (not synthesized).
'''
from __future__ import annotations

KEY_BITS = 8
RESPOND = 4
DECIDE = 8          # cycles the slot manager takes to decide on an announcement (rtl_gen/slot_manager.py)
#: the load widths (words per cycle) the search tries in the rotating mode
LOAD_LANES = (1, 2, 4, 8, 16, 32, 64)


def plan(timing: dict, frame: int) -> dict:
    lead = timing['before'] + RESPOND + 8 + DECIDE
    return {'lead': lead, 'slots': -(-timing['after'] // frame) + -(-lead // frame) + 1,
            'fits': timing['words'] <= frame}


def managerArea(K: int, timing: dict) -> dict:
    '''Registers and LUTs of the slot manager: per slot a key, three counters, an age and a few flags; a compare
    of the key per slot and a pick of the oldest free slot.'''
    cb = max(timing['after'], timing['before'], timing['words']).bit_length() + 1
    kb = max(1, (K - 1).bit_length())
    # per slot: key, three counters, age, flags, the latched score; the comparison tree (K - 1 registered entries);
    # the queues and the loader
    ff = K * (KEY_BITS + 2 * cb + 20 + 8 + 23) + (K - 1) * (22 + kb) + 4 * KEY_BITS + 140
    lut = K * (KEY_BITS // 2 + 2 * cb + 20 + 10 + 8) + (K - 1) * (12 + kb) + 160
    return {'lut': lut, 'ff': ff}


def modes(req) -> list:
    '''The slot modes the request allows: 'resident' and / or 'rotate'.'''
    return {'resident': ['resident'], 'rotating': ['rotate'], 'either': ['resident', 'rotate']}[req.modulusSlots]


def lanesFor(words: list, frame: int, most: int = 4096) -> int | None:
    """The fewest load lanes (a power of two) with which the load of one slot fits one frame. `words`: the words
    of every table of the slot, in load order. The generators give each table to the lane that is shortest so
    far, so the load takes as many cycles as the longest lane. None: no lane count up to `most` fits (a table is
    longer than a frame)."""
    if not words or max(words) > frame:
        return None
    R = 1
    while R <= most:
        fill = [0] * R
        for w in words:
            i = min(range(R), key=fill.__getitem__)
            fill[i] += w
        if max(fill) <= frame:
            return R
        R *= 2
    return None
