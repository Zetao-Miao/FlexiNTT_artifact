'''The NTT family as the framework sheet draws it, with the code behind each box.

The design sheet (Generator Framework) has a frontend of crypto-primitive
classes and a backend of Versal generators. This module is that picture as
data: one `Role` per box, each listing the implementations that fill it — the
scheme (arithmetic), the operator (ports), the spec (the contract), the
generator(s) (the backend), the gate that verifies it, and a status:

    'hardware'  RTL generated, simulated and implemented or run on the card
    'rtl'       RTL generated and simulated against the model
    'model'     modelled (bounds, values, cost), no generator yet
    'planned'   a box on the sheet with nothing behind it yet

Nothing here is imported eagerly: names are dotted paths, resolved by
`resolve()` only when asked, so importing the registry costs nothing.
`check()` imports every registered name and verifies that schemes are
`OperatorScheme`s (or, for the two families that predate it, carry its
methods) and operators honour the RTL generation contract.

Extending the family
--------------------
A new implementation of an existing box is one `register(...)` call (or the
`@implements(...)` decorator on the class). A new box is a `Role(...)` added
under its parent. `describe()` prints the tree; `docs/USAGE.md` §8 walks
through adding an operator end to end.
'''
from __future__ import annotations

import importlib
from dataclasses import dataclass, field

STATUSES = ('hardware', 'rtl', 'model', 'planned')


@dataclass(frozen=True)
class Implementation:
    name: str
    scheme: str = ''                 # dotted path of the scheme class
    operator: str = ''               # dotted path of the operator class
    spec: str = ''                   # 'module.Class' of the spec dataclass (versal_arith)
    generators: tuple[str, ...] = ()  # 'module.function' (versal_arith)
    backend: tuple[str, ...] = ()    # backend boxes of the sheet it uses
    gate: str = ''                   # the script that verifies it
    status: str = 'model'
    note: str = ''


@dataclass
class Role:
    name: str
    description: str
    parent: str | None = None
    implementations: list[Implementation] = field(default_factory=list)


#: Backend boxes of the sheet, with the versal_arith code behind each.
BACKEND = {
    'Bit Heap Compressors': ('heuristic.py', 'rtl_gen/compressor.py', 'rtl_gen/heap_terms.py'),
    'Compressor with Integrated Table Look-up': ('rtl_gen/datapath.py (table nodes into a heap)',),
    'Efficient Special Adders': ('rtl_gen/terminal_add.py', 'rtl_gen/datapath.py (correct nodes)'),
    'LUT-Based Multipliers': ('rtl_gen/booth_mult.py',),
    'Multiplier using DSPs': ('dsp_multiplier/', 'rtl_gen/dsp_multiplier/'),
    'Montgomery Variants': ('rtl_gen/datapath.py',),
    'Barrett Variants': ('rtl_gen/datapath.py',),
    'LUT-Based Variants': ('rtl_gen/datapath.py',),
    'Special Modulus': ('rtl_gen/datapath.py', 'rtl_gen/butterfly.py (Goldilocks limbs)'),
    'Constant Multiplier': ('rtl_gen/const_mult_op.py', 'rtl_gen/const_mult.py'),
    'Barrel Shifter': ('rtl/matrix_transpose/barrel_shift.sv', 'rtl_gen/transpose.py'),
}

_ROLES: dict[str, Role] = {}


def _role(name, description, parent=None):
    _ROLES[name] = Role(name, description, parent)
    return _ROLES[name]


_role('NTT', 'Number theoretic transform: n-point pipelines, inverse, four-step')
_role('Butterfly', 'CT / GS butterfly: a + w*b, a - w*b (or the difference form)', 'NTT')
_role('ModularMultiplier', 'a*b mod q, or a*w mod q with a design-time twiddle', 'NTT')
_role('Multiplier', 'integer a*b', 'ModularMultiplier')
_role('ConstMult', 'a*c for a design-time constant', 'ModularMultiplier')
_role('PartialMult', 'only the low or high half of a product (Montgomery m, Barrett qhat, Shoup)', 'ModularMultiplier')
_role('ModularReduction', 't mod q (times a factor): Barrett, Montgomery, WLM, special moduli, tables, custom', 'ModularMultiplier')
_role('ModularAdder', '(a +/- b) mod q, exact or lazy', 'NTT')
_role('Adder', 'two-operand and terminal adders', 'ModularAdder')
_role('Compressor', 'bit-heap compressor trees', 'ModularAdder')
_role('MatrixTranspose', 'the four-step corner turn', 'NTT')
_role('BarrelShifter', 'rotate a row by a run-time amount', 'MatrixTranspose')
_role('Crossbar', 'any-to-any lane permutation', 'MatrixTranspose')


def register(role: str, impl: Implementation) -> Implementation:
    if role not in _ROLES:
        raise KeyError(f'no role {role!r}; roles are {sorted(_ROLES)}')
    if impl.status not in STATUSES:
        raise ValueError(f'status must be one of {STATUSES}')
    _ROLES[role].implementations = [i for i in _ROLES[role].implementations if i.name != impl.name]
    _ROLES[role].implementations.append(impl)
    return impl


def implements(role: str, **meta):
    '''Class decorator: register the decorated scheme under `role`.'''
    def deco(cls):
        register(role, Implementation(name=meta.pop('name', cls.__name__),
                                      scheme=f'{cls.__module__}.{cls.__qualname__}', **meta))
        return cls
    return deco


def role(name: str) -> Role:
    return _ROLES[name]


def roles() -> list[Role]:
    return list(_ROLES.values())


def children(name: str) -> list[Role]:
    return [r for r in _ROLES.values() if r.parent == name]


def resolve(dotted: str):
    '''Import `package.module.Name` (operator_modeling) or `module.Name`
    (versal_arith, which needs versal_arith/ on sys.path — any scheme module
    puts it there).'''
    mod, _, attr = dotted.rpartition('.')
    return getattr(importlib.import_module(mod), attr)


def describe() -> str:
    lines = []

    def walk(name, depth):
        r = _ROLES[name]
        lines.append(f'{"  " * depth}{r.name}: {r.description}')
        for i in r.implementations:
            what = i.scheme.rpartition('.')[2] or i.name
            gen = ', '.join(g.rpartition('.')[2] for g in i.generators) or '-'
            lines.append(f'{"  " * depth}  - {i.name} [{i.status}] scheme {what}; generator {gen}'
                         + (f'; gate {i.gate}' if i.gate else ''))
        for c in children(name):
            walk(c.name, depth + 1)

    for r in _ROLES.values():
        if r.parent is None:
            walk(r.name, 0)
    return '\n'.join(lines)


def check() -> list[str]:
    '''Import every registered name; list what fails.'''
    from .core.OperatorScheme import OperatorScheme
    from .core.contracts import contractGaps
    from .core import datapath as _dp          # noqa: F401 -- puts versal_arith/ on sys.path
    problems = []
    for r in _ROLES.values():
        for i in r.implementations:
            for path in [i.scheme, i.operator]:
                if not path:
                    continue
                try:
                    obj = resolve(path)
                except Exception as e:                      # noqa: BLE001
                    problems.append(f'{r.name}/{i.name}: cannot import {path}: {e}')
                    continue
                if path == i.scheme and isinstance(obj, type):
                    ok = issubclass(obj, OperatorScheme) or all(
                        callable(getattr(obj, m, None)) for m in ('propagateBound', 'propagateValue', 'latency'))
                    if not ok:
                        problems.append(f'{r.name}/{i.name}: {path} is not a scheme')
                if path == i.operator and isinstance(obj, type):
                    gaps = [g for g in contractGaps(obj)]
                    if gaps:
                        problems.append(f'{r.name}/{i.name}: operator {path} lacks {gaps}')
            for path in ([i.spec] if i.spec else []) + list(i.generators):
                try:
                    resolve(path)
                except Exception as e:                      # noqa: BLE001
                    problems.append(f'{r.name}/{i.name}: cannot import {path}: {e}')
    return problems


# =============================================================================
# What the code base has, fitted into the boxes
# =============================================================================

_OM = 'operator_modeling'
_DP = dict(spec='datapath_spec.DatapathSpec',
           generators=('rtl_gen.datapath.Datapath_RTL_gen', 'sim_rtl_gen.datapath.Datapath_SimRTL_gen'),
           gate='runModMult.py', status='rtl')

register('NTT', Implementation(
    'FullyPipelinedNTT', f'{_OM}.ntt.pipelined.FullyPipelinedScheme.FullyPipelinedGrid', f'{_OM}.ntt.pipelined.FullyPipelinedNTT.FullyPipelinedNTT',
    'ntt_spec.NTTOperatorSpec', ('rtl_gen.ntt.NTT_RTL_gen', 'sim_rtl_gen.ntt.NTT_SimRTL_gen'),
    ('Bit Heap Compressors', 'Special Modulus'), 'runButterfly.py, scripts/build_ntt.py', 'hardware',
    'n-point CT/GS, cyclic or negacyclic; 128-point designs pass on the V80; any q with ModularBU butterflies'))
register('NTT', Implementation(
    'FullyPipelinedINTT', f'{_OM}.ntt.pipelined.FullyPipelinedScheme.FullyPipelinedGrid', f'{_OM}.ntt.pipelined.FullyPipelinedNTT.FullyPipelinedINTT',
    'ntt_spec.NTTOperatorSpec', ('rtl_gen.ntt.NTT_RTL_gen',), ('Bit Heap Compressors',),
    'runButterfly.py', 'hardware', 'inverse twiddles, 1/n left out'))
register('NTT', Implementation(
    'UnrolledNTT', f'{_OM}.ntt.dataflow.UnrolledNTT.UnrolledNTTScheme', f'{_OM}.ntt.dataflow.UnrolledNTT.UnrolledNTT',
    'ntt_spec.StreamNTTSpec', ('rtl_gen.ntt.StreamNTT_RTL_gen', 'rtl_gen.unrolled_ntt.UnrolledNTT_wrapper_gen'),
    ('Special Modulus',), 'runUnrolledNTT.py', 'rtl',
    'fully pipelined, one n-point transform per cycle, any q; modulus index and direction per transform '
    '(per-modulus {MIDX, DIR} twiddle ROMs), given twiddles (ROM or ports) for folded multi-step NTTs'))
register('NTT', Implementation(
    'MultiStepNTT', f'{_OM}.ntt.multistep.MultiStepScheme.MultiStepScheme', f'{_OM}.ntt.multistep.MultiStepNTT.MultiStepNTT',
    None, ('rtl_gen.multistep.MultiStep_RTL_gen',), ('Special Modulus',), 'runMultiStep.py, runMultiStepRtl.py', 'rtl',
    'k-step (d >= 2 passes of fully pipelined sub-NTTs on P lanes, lane-time transposes), any q, modulus index and '
    'direction per polynomial; twist form (inter-pass multipliers: rom / otf / power tree) or folded (TP-NTT)'))
register('NTT', Implementation(
    'FourStepNTT', f'{_OM}.ntt.multistep.FourStepScheme.FourStepScheme', f'{_OM}.ntt.multistep.FourStepNTT.FourStepNTT',
    gate='runFourStep16384.py, runFourStep64*.py', status='model',
    note='N = n*n from five children; RTL per child'))
register('NTT', Implementation(
    'HybridNTT', f'{_OM}.ntt.hybrid.HybridNTTScheme.HybridNTTScheme', f'{_OM}.ntt.hybrid.HybridNTT.HybridNTT',
    '', ('rtl_gen.hybrid_ntt.HybridNTT_RTL_gen',), ('Barrel Shifter',), 'runHybridNTT.py', 'rtl',
    'a block of U unrolled stages in a loop (rounds), constant geometry, S polynomials in the loop, modulus and '
    'direction per polynomial; spec is a dict (HybridNTT.getOperatorInterface)'))
register('Butterfly', Implementation(
    'GoldilocksSlice64', f'{_OM}.ntt.butterfly.ButterflyScheme.GoldilocksSlice64', '',
    'butterfly_spec.ButterflyOperatorSpec',
    ('rtl_gen.butterfly.Butterfly_RTL_gen', 'sim_rtl_gen.butterfly.Butterfly_SimRTL_gen'),
    ('Bit Heap Compressors', 'Special Modulus', 'Constant Multiplier'), 'runLutTiming.py', 'hardware',
    'twiddle as <= 3 NAF terms, Goldilocks limb folding, lazy -q'))
register('Butterfly', Implementation(
    'ModularButterflyScheme', f'{_OM}.modmult.ModButterfly.ModularButterflyScheme',
    f'{_OM}.core.DatapathOperator.DatapathOperator',
    backend=('Multiplier using DSPs', 'Constant Multiplier', 'Efficient Special Adders'),
    note='one modular multiplier + two modular adders composed into one datapath (buildInto); any q, any '
         'reduction family, runtime or constant twiddle; CT and GS; fixed q or a run-time ModulusFamily', **_DP))
register('Butterfly', Implementation(
    'ModularBU', f'{_OM}.ntt.butterfly.ButterflyScheme.ModularBU', '',
    'butterfly_spec.DatapathButterflySpec', ('rtl_gen.butterfly.Butterfly_RTL_gen', 'rtl_gen.ntt.NTT_RTL_gen'),
    ('Multiplier using DSPs', 'Constant Multiplier', 'Efficient Special Adders', 'Bit Heap Compressors'),
    'runModularNTT.py', 'rtl',
    'any q (fixed or run-time) and any modular multiplier (every reduction, Shoup); twiddle constant '
    '(1 costs no multiplier) or inputs W/WP; ports from the scheme on the Butterfly operator; '
    'in an NTT: constant twiddles, fixed q; hw backend only'))
register('ModularMultiplier', Implementation(
    'ModularMultiplierScheme', f'{_OM}.modmult.ModMultScheme.ModularMultiplierScheme',
    f'{_OM}.modmult.ModMult.ModularMultiplier',
    backend=('Multiplier using DSPs', 'LUT-Based Multipliers', 'Constant Multiplier', 'Bit Heap Compressors'),
    note='product (DSP/Booth/behavioural/constant) then any reduction child; fixed q or a run-time ModulusFamily', **_DP))
register('ModularMultiplier', Implementation(
    'ShoupModMult', f'{_OM}.modmult.ModMultScheme.ShoupModMult', f'{_OM}.modmult.ModMult.ModularMultiplier',
    backend=('Constant Multiplier', 'Multiplier using DSPs'),
    note='Harvey/Shoup precomputed quotient; constant or runtime twiddle', **_DP))
register('Multiplier', Implementation(
    'BoothMult', f'{_OM}.multiplier.LutMultiplierScheme.BoothMult', f'{_OM}.multiplier.Multiplier.Multiplier',
    'mult_spec.MultOperatorSpec', ('rtl_gen.booth_mult.Bmult_RTL_gen',), ('LUT-Based Multipliers',),
    'runLutTiming.py', 'rtl'))
register('Multiplier', Implementation(
    'DspMultiplierScheme', f'{_OM}.multiplier.DspMultiplierScheme.DspMultiplierScheme',
    f'{_OM}.multiplier.Multiplier.Multiplier', 'dsp_mult_spec.DspMultOperatorSpec',
    ('rtl_gen.dsp_multiplier.pipeline.generate_rtl',), ('Multiplier using DSPs',), 'runDspMultiplier.py',
    'hardware', 'four DSP multipliers pass on the V80'))
register('Multiplier', Implementation(
    'LutMultiplierScheme', f'{_OM}.multiplier.LutMultiplierScheme.LutMultiplierScheme',
    f'{_OM}.multiplier.Multiplier.Multiplier', 'mult_spec.MultOperatorSpec', status='model',
    note='decompositions (Karatsuba, tiling) model and cost; rtl_gen/mult.py not written'))
register('Multiplier', Implementation(
    'BehaviouralMult', f'{_OM}.multiplier.MultiplierScheme.BehaviouralMult',
    f'{_OM}.multiplier.Multiplier.Multiplier', status='model', note='exact, no implementation'))
register('ConstMult', Implementation(
    'NafConstMult', f'{_OM}.multiplier.ConstMultScheme.NafConstMult', f'{_OM}.multiplier.ConstMult.ConstMult',
    'const_mult_spec.ConstMultOperatorSpec', ('rtl_gen.const_mult_op.ConstMult_RTL_gen',),
    ('Constant Multiplier', 'Bit Heap Compressors'), 'runLutTiming.py, scripts/build_cmult.py', 'rtl',
    'NAF, optional modulus lifting'))
register('ConstMult', Implementation(
    'ConstMultBankScheme', f'{_OM}.multiplier.BankScheme.ConstMultBankScheme',
    f'{_OM}.multiplier.ConstMultBank.ConstMultBank', 'const_mult_spec.ConstMultBankSpec',
    ('rtl_gen.const_mult_op.ConstMultBank_RTL_gen',), ('Constant Multiplier',), 'scripts/build_bank.py',
    'rtl', 'pre/post-twist banks (inside the four-step NTT64 card projects; not re-checked here)'))
register('PartialMult', Implementation(
    'Datapath.lowProduct / truncated heaps', '',
    backend=('Bit Heap Compressors', 'Constant Multiplier'), status='rtl',
    note='a heap truncated at W columns is the low half; a heap sliced above s, '
         'optionally with columns dropped below d (Barrett truncate=), is the high half',
    gate='runModMult.py'))
for _name, _cls, _box in (
        ('BarrettReduction', 'BarrettReduction', 'Barrett Variants'),
        ('MontgomeryReduction', 'MontgomeryReduction', 'Montgomery Variants'),
        ('WordLevelMontgomery', 'WordLevelMontgomery', 'Montgomery Variants'),
        ('KRedReduction', 'KRedReduction', 'Special Modulus'),
        ('FoldReduction', 'FoldReduction', 'Special Modulus'),
        ('MersenneReduction', 'MersenneReduction', 'Special Modulus'),
        ('SolinasReduction', 'SolinasReduction', 'Special Modulus'),
        ('GoldilocksReduction', 'GoldilocksReduction', 'Special Modulus'),
        ('TableLookupReduction', 'TableLookupReduction', 'LUT-Based Variants'),
        ('CustomReduction', 'CustomReduction', 'Barrett Variants'),
        ('ShiftAddReduction', 'ShiftAddReduction', 'Special Modulus')):
    register('ModularReduction', Implementation(
        _name, f'{_OM}.modmult.ReductionScheme.{_cls}', f'{_OM}.modmult.ModMult.ModularReduction',
        backend=(_box, 'Bit Heap Compressors', 'Efficient Special Adders'), **_DP))
register('ModularAdder', Implementation(
    'ModularAdderScheme', f'{_OM}.modmult.ModAddScheme.ModularAdderScheme',
    f'{_OM}.core.DatapathOperator.DatapathOperator',
    backend=('Efficient Special Adders', 'Bit Heap Compressors'),
    note='(a +/- b) mod q into [0, q) or lazily; the butterfly folds its adds into its heaps instead',
    **_DP))
register('Adder', Implementation(
    'terminal adders', generators=('rtl_gen.terminal_add.terminalAdd_gen',),
    backend=('Efficient Special Adders',), status='hardware', gate='runLutTiming.py',
    note='quaternary row-counter terminal adder; behavioural where unsupported'))
register('Compressor', Implementation(
    'compressor_RTL_gen', generators=('rtl_gen.compressor.compressor_RTL_gen',),
    backend=('Bit Heap Compressors',), status='hardware', gate='runLutTiming.py',
    note='GPC heuristic of the ePrint 2026/344 paper'))
register('MatrixTranspose', Implementation(
    'BarrelMemoryBarrelTranspose', f'{_OM}.transpose.MatrixTransposeScheme.BarrelMemoryBarrelTranspose',
    f'{_OM}.transpose.MatrixTranspose.MatrixTranspose', 'transpose_spec.TransposeOperatorSpec',
    ('rtl_gen.transpose.Transpose_RTL_gen',), ('Barrel Shifter',), 'runMatrixTranspose.py', 'hardware'))
register('MatrixTranspose', Implementation(
    'MemoryBarrelMemoryTranspose', f'{_OM}.transpose.MatrixTransposeScheme.MemoryBarrelMemoryTranspose',
    f'{_OM}.transpose.MatrixTranspose.MatrixTranspose', 'transpose_spec.TransposeOperatorSpec',
    ('rtl_gen.transpose.Transpose_RTL_gen',), ('Barrel Shifter',), 'runMatrixTranspose.py', 'hardware'))
register('MatrixTranspose', Implementation(
    'BehaviouralMatrixTranspose', f'{_OM}.transpose.MatrixTransposeScheme.BehaviouralMatrixTranspose',
    f'{_OM}.transpose.MatrixTranspose.MatrixTranspose', status='model'))
register('BarrelShifter', Implementation(
    'barrel_shift.sv', '', '', '',
    ('rtl_gen.transpose.BarrelShift_RTL_gen',), ('Barrel Shifter',), 'runMatrixTranspose.py', 'hardware',
    'radix-4 LUT6_2 shifter, hand-written RTL; its twin is transpose_model.BarrelShifter'))
register('Crossbar', Implementation('Crossbar', status='planned',
                                    note='AutoNTT-style split shuffler; not started'))
