'''The front end: operators and their schemes (values, bounds, cycles, resources) and the RTL they emit.

    core/         operators, ports, signals, schemes, the shared component models
    multiplier/   integer and constant multipliers
    modmult/      modular reduction, multiplication, addition, the modular butterfly
    ntt/          the NTT: butterfly, shared parts, one folder per architecture
    transpose/    the matrix transpose
    registry.py   the family tree of roles and implementations
'''
from . import _compat

_compat.install()          # module names of the earlier layout (operator_modeling.hybrid, .fourstep, ntt.NTT, ...)
