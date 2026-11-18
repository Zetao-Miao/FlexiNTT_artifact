'''The user's DSP limit as the DSP budget of a core.

The limit (`Requirements.maxDsp`) is not a threshold that a finished core is compared with. It is handed to the
generator as the total DSP budget (`setDspBudget(total=)`, core/dspbudget.py), which shares it among the
multipliers by weight. A core whose pure-DSP count is below the limit keeps all its DSPs, so a large limit means
no restriction. A multiplier left with no DSP is built on LUTs. The adapters put the limit into the params of
every point as `dspTotal`, so the cache key, the core name and a rebuild carry it.
'''
from __future__ import annotations


def binds(s) -> bool:
    '''Did the budget take DSPs away from scheme `s` (budget below the pure-DSP count)?'''
    t = getattr(s, 'dspTree', None)
    return t is not None and t.budget < t.pureDsp


def totalOf(req, fraction) -> int | None:
    '''The `dspTotal` of a point: the user's limit, unless the options ask for a fraction or no limit is given.'''
    if fraction is not None or req.maxDsp is None:
        return None
    return int(req.maxDsp)
