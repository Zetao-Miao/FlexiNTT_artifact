'''Design-space exploration over the four NTT architectures (iterative, hybrid, dataflow, multi-step).

    from operator_modeling.dse import Requirements, search
    req = Requirements(n=4096, moduli=[...], clockMhz=350, minNttPerS=1e5, maxDsp=600)
    res = search(req)                 # every legal core of every architecture, priced by the build-free models
    res.feasible, res.front           # the cores that meet `req`, and their Pareto front

`spec.py`     what the user asks for (performance targets, resource and bandwidth limits, NTT parameters)
`record.py`   what one core is, in the same fields for every architecture (area, cycles, boundary ports)
`adapters/`   one module per architecture: its legal option combinations and the record of each
`search.py`   exhaustive enumeration, constraint filter, Pareto front, cache
'''
from .spec import Requirements
from .record import CoreRecord, Port, PORT_KINDS
from .search import search, requery, refilter, pareto, SearchResult

__all__ = ['Requirements', 'CoreRecord', 'Port', 'PORT_KINDS', 'search', 'requery', 'refilter', 'pareto', 'SearchResult']
