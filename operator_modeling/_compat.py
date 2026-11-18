'''The module names of the layout before 2026-11-14, kept importable.

The NTT architectures moved into `operator_modeling/ntt/<architecture>/`. Scripts outside the repository
(`ntt_hw/experiments`) still import the earlier names, so `install()` puts one finder in front of the
import system that answers an earlier name with the module that holds the code now:

    operator_modeling.hybrid[.X]       -> operator_modeling.ntt.hybrid[.X]
    operator_modeling.fourstep[.X]     -> operator_modeling.ntt.multistep[.X]
    operator_modeling.ntt.<moved file> -> its new place (MOVED)
    operator_modeling.ntt.NTTScheme, operator_modeling.ntt.NTT
                                       -> a module holding the names of the files they were split into (SPLIT)

A moved module is the same module object under both names. Code in the repository uses the new names;
delete this file and its call in `__init__.py` once nothing outside needs the earlier ones.
'''
import importlib
import importlib.abc
import importlib.util
import sys

_P = 'operator_modeling'

#: earlier package -> package now
PACKAGES = {
    f'{_P}.hybrid': f'{_P}.ntt.hybrid',
    f'{_P}.fourstep': f'{_P}.ntt.multistep',
}
#: earlier module -> module now
MOVED = {
    f'{_P}.ntt.Butterfly': f'{_P}.ntt.butterfly.Butterfly',
    f'{_P}.ntt.ButterflyScheme': f'{_P}.ntt.butterfly.ButterflyScheme',
    f'{_P}.ntt.UnifiedButterfly': f'{_P}.ntt.butterfly.UnifiedButterfly',
    f'{_P}.ntt.UnrolledNTT': f'{_P}.ntt.dataflow.UnrolledNTT',
    f'{_P}.ntt.StreamArea': f'{_P}.ntt.dataflow.StreamArea',
    f'{_P}.ntt.stream_accuracy': f'{_P}.ntt.dataflow.stream_accuracy',
    f'{_P}.ntt.slrmodel': f'{_P}.ntt.iterative.slrmodel',
}
#: earlier module -> the modules its contents were split into
SPLIT = {
    f'{_P}.ntt.NTTScheme': (f'{_P}.ntt.pipelined.FullyPipelinedScheme', f'{_P}.ntt.dataflow.StreamingNTTScheme',
                            f'{_P}.ntt.memory', f'{_P}.ntt.iterative.IterativeNTTScheme'),
    f'{_P}.ntt.NTT': (f'{_P}.ntt.pipelined.FullyPipelinedNTT', f'{_P}.ntt.dataflow.StreamingNTT',
                      f'{_P}.ntt.iterative.IterativeNTT'),
}


def target(name: str):
    '''The module that now holds the earlier module `name`, or None.'''
    if name in MOVED:
        return MOVED[name]
    for old, new in PACKAGES.items():
        if name == old or name.startswith(old + '.'):
            return new + name[len(old):]
    return None


class _Alias(importlib.abc.Loader):
    '''Loads an earlier name as the module that holds the code now (the same object).'''

    def __init__(self, new):
        self.new = new

    def create_module(self, spec):
        module = importlib.import_module(self.new)
        self._spec = module.__spec__
        return module

    def exec_module(self, module):
        module.__spec__ = self._spec          # the import system put the alias spec there

    def get_code(self, name):                 # python3 -m <earlier name>
        return importlib.util.find_spec(self.new).loader.get_code(self.new)


class _Merged(importlib.abc.Loader):
    '''Loads an earlier module that was split: the names of all its parts in one module.'''

    def __init__(self, parts):
        self.parts = parts

    def create_module(self, spec):
        return None

    def exec_module(self, module):
        for part in self.parts:
            for key, value in vars(importlib.import_module(part)).items():
                if not key.startswith('__'):
                    module.__dict__.setdefault(key, value)


class _Finder(importlib.abc.MetaPathFinder):
    def find_spec(self, name, path=None, target_module=None):
        if not name.startswith(_P + '.'):
            return None
        if name in SPLIT:
            return importlib.util.spec_from_loader(name, _Merged(SPLIT[name]))
        new = target(name)
        if new is None:
            return None
        real = importlib.util.find_spec(new)
        if real is None:
            return None
        spec = importlib.util.spec_from_loader(name, _Alias(new), origin=real.origin,
                                               is_package=real.submodule_search_locations is not None)
        spec.has_location = real.has_location
        return spec


def install():
    if not any(isinstance(f, _Finder) for f in sys.meta_path):
        sys.meta_path.insert(0, _Finder())
