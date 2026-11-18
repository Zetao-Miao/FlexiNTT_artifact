'''A total DSP budget for a design, split top-down to every multiplier.

The rule (one design, one budget):

  * The budget is a fraction of the design's pure-DSP count (`fraction=0.6`) or
    an absolute number (`total=`). The pure-DSP count of a multiplier is what the
    search (`DspMultiplierScheme`) picks with no budget of ours: the builder's own
    `dspBudget` (the DSP58 tiling count), as the model prices it today.
  * Layer by layer, a parent's budget is shared among its children in proportion
    to their weights (`WEIGHTS`, by default each child's pure-DSP count), rounded
    with the largest-remainder method so the children sum exactly to the parent
    (less only where a child is capped at its own pure-DSP count: more DSPs than
    that buy nothing).
  * Identical blocks get identical budgets: at a layer with repeated blocks the
    split is by block type (weight = count x per-instance weight), each instance
    of a type gets floor(share / count), and the pooled remainders go, one more
    DSP per instance, to whole types (largest remainder first) while the pool
    covers a whole type; what is left stays unused, so the total never exceeds
    the parent's budget.
  * A leaf is one 'dsp' multiplier node of a `Datapath` (`dp.mult`): the
    butterfly's product B*W, each word-level Montgomery step's m*QH separately,
    any other product. A leaf on budget 0 is built on LUTs (Booth).

`planDatapath` does one datapath scheme (a modular multiplier, a butterfly);
`StreamingNTTScheme.setDspBudget` uses `planBlocks` for the NTT layer
{butterfly types x count, output twist x P, OTF generators x classes}.
'''
from __future__ import annotations

from dataclasses import dataclass, field
from fractions import Fraction


# --- the weight of a child: the one pluggable place ------------------------------

def _wDsp(leaf: 'Leaf') -> int:
    return leaf.pureDsp


def _wArea(leaf: 'Leaf') -> int:
    return leaf.wa * leaf.wb


#: weight of one multiplier (a leaf); a block's weight is the sum over its leaves
WEIGHTS = {'dsp': _wDsp, 'area': _wArea}
DEFAULT_WEIGHT = 'dsp'


def weightFn(weight=None):
    if weight is None:
        weight = DEFAULT_WEIGHT
    return WEIGHTS[weight] if isinstance(weight, str) else weight


# --- the tree ------------------------------------------------------------------------

@dataclass
class Leaf:
    '''One 'dsp' multiplier node.'''
    name: str
    wa: int
    wb: int
    pureDsp: int
    note: str = ''


@dataclass
class Budget:
    '''One node of the budget tree: `count` identical instances, each with `budget`
    DSPs (a leaf: the multiplier's own; a block: the sum of its children's).'''
    name: str
    count: int
    pureDsp: int                 # per instance
    weight: int                  # per instance
    budget: int = 0              # per instance
    children: list = field(default_factory=list)
    dsp: int | None = None       # per instance, the model's count after the split
    lut: int | None = None

    def total(self) -> int:
        return self.count * self.budget

    def lines(self, indent: int = 0) -> list[str]:
        mid = f'x{self.count:<3d}' if self.count != 1 else '    '
        got = '' if self.dsp is None else f'  model DSP {self.dsp}' + ('' if self.lut is None else f' LUT {self.lut}')
        out = [f"{'  ' * indent}{self.name:<{max(1, 34 - 2 * indent)}} {mid} pure {self.pureDsp:4d}  "
               f"weight {self.weight:5d}  budget {self.budget:4d}{got}"]
        for c in self.children:
            out += c.lines(indent + 1)
        return out

    def __str__(self) -> str:
        return '\n'.join(self.lines())


# --- apportionment ----------------------------------------------------------------------

def apportion(total: int, weights: list[int], caps: list[int] | None = None) -> list[int]:
    '''Largest remainder: shares of `total` in proportion to `weights`, summing to
    `total` unless the caps stop it (then less). Ties go to the lower index.'''
    n = len(weights)
    caps = list(caps) if caps is not None else [None] * n
    W = sum(weights)
    if total < 0:
        raise ValueError(f'apportion: negative total {total}')
    if n == 0:
        return []
    if W == 0:
        return [0] * n
    quota = [Fraction(total * w, W) for w in weights]
    share = [int(q) for q in quota]
    share = [min(s, c) if c is not None else s for s, c in zip(share, caps)]
    order = sorted(range(n), key=lambda i: (-(quota[i] - int(quota[i])), i))
    left = total - sum(share)
    while left > 0:
        moved = False
        for i in order:
            if left == 0:
                break
            if weights[i] and (caps[i] is None or share[i] < caps[i]):
                share[i] += 1
                left -= 1
                moved = True
        if not moved:
            break
    return share


def splitTypes(total: int, types: list[Budget]) -> None:
    '''Set `budget` (per instance) of every type: weight count x weight, floor per
    instance, then pooled remainders to whole types; capped at pureDsp.'''
    for t in types:
        if not t.count:                      # a type with no instance takes nothing
            t.budget = 0
    types = [t for t in types if t.count]
    shares = apportion(total, [t.count * t.weight for t in types], [t.count * t.pureDsp for t in types])
    quota = [Fraction(total * t.count * t.weight, max(1, sum(u.count * u.weight for u in types))) for t in types]
    pool = total
    for t, s in zip(types, shares):
        t.budget = min(s // t.count, t.pureDsp)
        pool -= t.budget * t.count
    order = sorted(range(len(types)), key=lambda i: (-(quota[i] / types[i].count - types[i].budget), i))
    moved = True
    while moved:
        moved = False
        for i in order:
            t = types[i]
            if t.weight and t.budget < t.pureDsp and t.count <= pool:
                t.budget += 1
                pool -= t.count
                moved = True


def splitLeaves(block: Budget) -> None:
    '''A block's per-instance budget over its leaves (each its own type, count 1).'''
    shares = apportion(block.budget, [c.weight for c in block.children], [c.pureDsp for c in block.children])
    for c, s in zip(block.children, shares):
        c.budget = s


# --- one datapath ---------------------------------------------------------------------

def leavesOf(scheme) -> list[Leaf]:
    '''The 'dsp' multiplier nodes of a datapath scheme, priced as the model prices them now.'''
    dp = scheme.datapath()
    sched = scheme.schedule()
    out = []
    for n in dp.nodes:
        if n.kind != 'mult' or n.backend != 'dsp':
            continue
        bb = dp.bounds[n.b].bitWidth if n.b else max(1, n.bConst.bit_length())
        out.append(Leaf(n.name, dp.bounds[n.a].bitWidth, bb, dp.nodeResources(n, sched).dsp, n.note))
    return out


def blockOf(name: str, scheme, count: int, weight=None) -> Budget:
    '''A block of `count` identical instances of `scheme` (budgets cleared first).'''
    wf = weightFn(weight)
    leaves = leavesOf(scheme)
    kids = [Budget(l.name + (f' ({l.note})' if l.note else ''), 1, l.pureDsp, int(wf(l))) for l in leaves]
    for k, l in zip(kids, leaves):
        k.node = l.name
    return Budget(name, count, sum(k.pureDsp for k in kids), sum(k.weight for k in kids), children=kids)


def budgetsOf(block: Budget) -> dict:
    '''{node name: budget} of a block, what `DatapathScheme.dspBudgets` takes.'''
    return {k.node: k.budget for k in block.children}


def resolveTotal(pure: int, fraction=None, total=None) -> int:
    if (fraction is None) == (total is None):
        raise ValueError('give a DSP fraction or a total, one of them')
    if fraction is not None:
        if not 0 <= fraction:
            raise ValueError(f'dsp fraction {fraction} must be >= 0')
        b = int(Fraction(str(fraction)) * pure)          # floor: never above the fraction
    else:
        b = int(total)
        if b < 0:
            raise ValueError(f'dsp total {total} must be >= 0')
    return min(b, pure)


def planDatapath(scheme, fraction=None, total=None, weight=None) -> Budget:
    '''One datapath scheme (a modular multiplier, a butterfly): its leaves share the
    budget; sets `scheme.dspBudgets` and returns the tree, with the model's counts.'''
    scheme.dspBudgets = None
    root = blockOf(scheme.name, scheme, 1, weight)
    root.budget = resolveTotal(root.pureDsp, fraction, total)
    splitLeaves(root)
    scheme.dspBudgets = budgetsOf(root)
    measure(root, scheme)
    return root


def measure(block: Budget, scheme) -> None:
    '''Read the model's DSP count per leaf and for the block back into the tree.'''
    got = {l.name: l.pureDsp for l in leavesOf(scheme)}       # after the split: the budgeted counts
    for k in block.children:
        k.dsp = got.get(k.node, 0)                             # a leaf on budget 0 is a Booth node now
    block.lut, block.dsp = scheme.areaCost()


def check(root: Budget) -> list[str]:
    '''Every leaf's DSP count within its budget; every block's within its budget; the
    root's total within its budget.'''
    errs = []

    def walk(b: Budget):
        if b.dsp is not None and b.dsp > b.budget:
            errs.append(f'{b.name}: DSP {b.dsp} > budget {b.budget}')
        if b.children:
            s = sum(c.total() for c in b.children)
            if s > b.budget:
                errs.append(f'{b.name}: children budgets {s} > budget {b.budget}')
        for c in b.children:
            walk(c)
    walk(root)
    return errs
