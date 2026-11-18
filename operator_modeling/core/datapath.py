'''A datapath: the template for an operator built from heaps, products, tables
and corrections, modelled once and generated from the same description.

Why this exists
---------------
A modular multiplier is not one primitive. Barrett is a product, a constant
multiplication by `mu` kept above some bit, another by `q` kept below some bit,
a subtraction and a correction; Montgomery, word-level Montgomery, a Solinas
fold, a table-lookup reduction and Shoup's precomputed multiplication are other
arrangements of the same few pieces. Writing each one as its own scheme with its
own bound path, value path, cost, timing and generator is how two paths drift.
So the pieces are written once, here, and an operator is a *description*: a list
of named wires, each produced by one node.

    dp = Datapath('barrett')
    a  = dp.input('A', IntType.unsigned(64))
    b  = dp.input('B', IntType.unsigned(64))
    t  = dp.mult('t', a, b, backend='dsp', dspBudget=8)
    ...
    dp.output('P', r)

The description answers every question the project asks of an operator, from
one source of truth:

  bound      each wire's `IntType`: interval arithmetic over the node, or an
             algebraic bound the node's author proved (Barrett's quotient error,
             Shoup's [0, 2q)) — which the value path then asserts on every
             sample, and which the gate checks exhaustively at small moduli;
  values     bit-exact: a heap is its terms' sum modulo 2^W, exactly what the
             compressor computes; a correction picks the candidate the RTL
             picks;
  timing     each node's `lut_timing` units, so `pipelineStages` /
             `targetFmaxMhz` give per-node registers, a schedule with balancing
             delays, a latency and a predicted critical path;
  cost       each node's LUT / DSP estimate from the cost oracles the rest of
             the project uses (`lut_cost`, the DSP search);
  spec       `DatapathSpec` (`versal_arith/datapath_spec.py`), which
             `rtl_gen.datapath.Datapath_RTL_gen` builds node for node.

`DatapathScheme` wraps a description as an `OperatorScheme`: a subclass writes
`_build(dp)` and `reference(...)` and inherits the rest. That is the extension
point for a new modular reduction (see `modmult/`).
'''
from __future__ import annotations

import os as _os
import sys as _sys
from dataclasses import dataclass, field

from .IntType import IntType
from .OperatorScheme import OperatorScheme
from .Resources import Resources
from .terms import sumTermsBound, sumTermsValue
from .utils import nafTerms
from .relbound import Rel

_versalArithDir = _os.path.normpath(
    _os.path.join(_os.path.dirname(__file__), '..', '..', 'versal_arith'))
if _versalArithDir not in _sys.path:
    _sys.path.append(_versalArithDir)
from butterfly_spec import SliceTerm                                   # noqa: E402
from datapath_spec import DatapathSpec, DpDelay, DpNode, DpWire          # noqa: E402

KINDS = ('heap', 'mult', 'table', 'nonzero', 'correct', 'qcorrect', 'select')
MULT_BACKENDS = ('dsp', 'booth', 'behavioural')

#: Delay of one LUT level in a table or OR-reduction (a LUT6 plus local
#: routing). Not calibrated on hardware yet; the same order as LOGIC_GPC.
TABLE_LUT_NS = 0.30
#: Delay of the priority select after a correction's subtractors, per LUT level.
SELECT_LUT_NS = 0.20
#: Registers given a behavioural `*` under a frequency target (A/B, M and P
#: registers of an inferred DSP58). An assumption, not a measurement.
BEHAVIOURAL_MULT_STAGES = 3


class _ArrivalTooLate(Exception):
    def __init__(self, producers: set, cause: Exception):
        super().__init__(str(cause))
        self.producers, self.cause = set(producers), cause


class ModelError(AssertionError):
    '''A value outside the bound its node declared: the model is wrong, not the
    data. Raised by the value path, never silenced.'''


def wireRange(bitWidth: int, signed: bool) -> IntType:
    return IntType.signed(bitWidth) if signed else IntType.unsigned(bitWidth)


def wrapValue(v: int, bitWidth: int, signed: bool) -> int:
    '''`v` reduced to `bitWidth` bits, read back as two's complement when signed.'''
    raw = v & ((1 << bitWidth) - 1)
    if signed and bitWidth > 0 and (raw >> (bitWidth - 1)) & 1:
        return raw - (1 << bitWidth)
    return raw


@dataclass
class Node:
    kind: str
    name: str
    inputs: tuple[str, ...]
    bound: IntType
    bitWidth: int
    isSigned: bool
    terms: tuple = ()
    wrap: bool = False
    partial: bool = False
    a: str = ''
    b: str = ''
    bConst: int | None = None
    backend: str = ''
    dspBudget: int = 0
    src: str = ''
    lo: int = 0
    hi: int = 0
    table: tuple = ()
    modulus: int = 0
    kLow: int = 0
    kHigh: int = 0
    step: int = 1
    qwire: str = ''                      # qcorrect: the wire carrying q at run time
    qMults: tuple = ()                   # qcorrect: per candidate k, the wire k*q ('' for k = 0)
    qMin: int = 0                        # qcorrect: the smallest and largest q it is built for
    qMax: int = 0
    relBound: object = None              # a declared bound relative to the run-time q (`Rel`)
    fold: str = ''                       # correct/qcorrect: '' (select), 'sign' or 'compare' (see `_foldOf`)
    note: str = ''
    stagesOverride: int | None = None   # a node's own fixed register count, if any


@dataclass
class Schedule:
    stages: dict
    flags: dict
    start: dict
    ready: dict
    delays: list          # (name, src, cycles)
    renamed: dict         # node -> tuple of input names after delays
    latency: int
    criticalPathNs: float
    segments: dict        # node -> worst segment ns
    targetFmaxMhz: float | None
    request: object


class Datapath:
    '''Builder, evaluator, scheduler and spec writer for one datapath.'''

    def __init__(self, name: str):
        self.name = name
        self.inputs: list[str] = []
        self.bounds: dict[str, IntType] = {}
        self.widths: dict[str, tuple[int, bool]] = {}
        self.nodes: list[Node] = []
        self.outputs: list[tuple[str, str]] = []
        self._dsp: dict = {}
        # Bounds relative to a run-time modulus (`core/relbound.py`): set by
        # `setRelative`, one `Rel` per wire, used by `qcorrect` and checked per
        # trial by `evaluate`.
        self.rel: dict[str, Rel] = {}
        self.relq = None
        # Quasi-static wires: inputs that hold one value for a whole job (a
        # limb's modulus constants, written once with a clock enable) and every
        # node computed from them alone. They are not delay-balanced: the
        # schedule lets a consumer read them at any cycle.
        self.static: set[str] = set()
        # Shared inputs: ports that carry the same value in every instance of this datapath (a
        # per-frame modulus constant, `staticModulus=False`). Their delay chains are identical across
        # instances, so synthesis may merge them into one chain feeding every instance; the RTL keeps
        # the last register of each such chain per instance (rtl_gen/datapath.py `_reg_chain`).
        self.shared: set[str] = set()
        # Two-candidate corrections without a select (`_foldOf`): 'auto' folds
        # the sign-decided ones, 'always' also the compared ones, 'never' none.
        self.foldCorrections = 'auto'
        # Per-node DSP budgets from a top-down split (`core/dspbudget.py`): {mult node
        # name: budget}, overriding the `dspBudget` the builder passes for that node.
        # Only 'dsp'-backend nodes; a budget of 0 builds the product on LUTs ('booth').
        self.dspBudgets: dict[str, int] = {}

    def setRelative(self, qMin: int, qMax: int, qOf) -> None:
        '''Track bounds relative to a run-time q in [qMin, qMax]; `qOf(env, i)`
        is trial i's q from the input ports' values.'''
        if self.relq is None:
            self.relq = (qMin, qMax, qOf)
            for w in self.inputs:
                self.rel.setdefault(w, Rel.const(self.bounds[w].minValue, self.bounds[w].maxValue))

    # =====================================================================
    # Building
    # =====================================================================

    def _new(self, name: str) -> None:
        if not name.isidentifier():
            raise ValueError(f'{self.name}: wire name {name!r} is not an identifier')
        if name in self.bounds:
            raise ValueError(f'{self.name}: wire {name!r} defined twice')

    def _addNode(self, node: Node) -> str:
        self._new(node.name)
        for i in node.inputs:
            if i not in self.bounds:
                raise KeyError(f'{self.name}: node {node.name} reads undefined wire {i!r}')
        self.nodes.append(node)
        self.bounds[node.name] = node.bound
        self.widths[node.name] = (node.bitWidth, node.isSigned)
        if node.inputs and all(i in self.static for i in node.inputs):
            self.static.add(node.name)
        if self.relq is not None:
            r = node.relBound if node.relBound is not None else self._relOf(node)
            self.rel[node.name] = r if r is not None else Rel.const(node.bound.minValue, node.bound.maxValue)
        return node.name

    # --- relative bounds -----------------------------------------------------

    def relOf(self, wire: str) -> Rel | None:
        return self.rel.get(wire) if self.relq is not None else None

    def _termRel(self, t: SliceTerm) -> Rel:
        if t.source == 'const':
            v = t.constValue << t.limbShift
            r = Rel.const(v, v)
            return -r if t.sign < 0 else r
        b = self.bounds[t.source]
        w, _ = self.widths[t.source]
        src = self.rel.get(t.source)
        if t.sliceEnd == w - 1 and src is not None and (t.isSigned or b.minValue >= 0) and t.inputShift == 0:
            r = src.floordiv(t.sliceStart)
        else:
            tb = sumTermsBound([SliceTerm(**{**t.__dict__, 'limbShift': 0, 'sign': 1})], {t.source: b})
            r = Rel.const(tb.minValue, tb.maxValue)
        r = r.shift(t.limbShift) if t.limbShift >= 0 else Rel.const(*self._constSpan(r, t.limbShift))
        return -r if t.sign < 0 else r

    def _constSpan(self, r: Rel, shift: int):
        lo, hi = r.span(self.relq[0], self.relq[1])
        f = 2 ** shift
        from math import floor, ceil
        return floor(lo * f), ceil(hi * f)

    def _relOf(self, node: Node) -> Rel | None:
        qMin, qMax, _ = self.relq
        if node.kind == 'heap':
            if node.wrap or node.partial:
                return None
            r = Rel.const(0, 0)
            for t in node.terms:
                r = r + self._termRel(t)
            return r
        if node.kind == 'mult':
            ra = self.rel.get(node.a)
            if ra is None:
                return None
            if node.b:
                rb = self.rel.get(node.b)
                return ra.mul(rb, qMin, qMax) if rb is not None else None
            return ra.mul(Rel.const(node.bConst, node.bConst), qMin, qMax)
        return None                 # tables, ORs, corrections: their interval (or qcorrect's own)

    def _relCheck(self, env, n: int, names) -> None:
        '''Every value inside its relative bound for its trial's q.'''
        if self.relq is None:
            return
        qMin, qMax, qOf = self.relq
        qs = [qOf(env, i) for i in range(n)]
        cache: dict = {}
        for w in names:
            r = self.rel.get(w)
            if r is None or (r.L.isConst() and r.U.isConst()):
                continue
            for i, v in enumerate(env[w]):
                key = (w, qs[i])
                if key not in cache:
                    cache[key] = r.atInt(qs[i])
                lo, hi = cache[key]
                if not lo <= v <= hi:
                    raise ModelError(f'{self.name}: wire {w} = {v} outside its bound relative to q = {qs[i]}: '
                                     f'[{lo}, {hi}] ({r})')

    def input(self, name: str, bound: IntType, rel: Rel | None = None, static: bool = False,
              shared: bool = False) -> str:
        '''A port. `rel`: its bound relative to the run-time q (operands below
        q of their own trial, a modulus constant's relation to q). `static`:
        the port holds one value for a whole job, so it needs no delay lines.'''
        self._new(name)
        if static:
            self.static.add(name)
        elif shared:
            self.shared.add(name)
        if bound.isZero:
            raise ValueError(f'{self.name}: input {name} has a zero bound')
        self.inputs.append(name)
        self.bounds[name] = bound
        self.widths[name] = (bound.bitWidth, bound.isSigned)
        if rel is not None or self.relq is not None:
            self.rel[name] = rel if rel is not None else Rel.const(bound.minValue, bound.maxValue)
        return name

    def output(self, port: str, wire: str) -> None:
        if wire not in self.bounds:
            raise KeyError(f'{self.name}: output {port} names undefined wire {wire!r}')
        self.outputs.append((port, wire))

    def width(self, wire: str) -> int:
        return self.widths[wire][0]

    def bound(self, wire: str) -> IntType:
        return self.bounds[wire]

    # --- terms -------------------------------------------------------------

    def slice(self, src: str, lo: int, hi: int | None = None, shift: int = 0,
              sign: int = 1) -> SliceTerm | None:
        '''Bits `lo..hi` of `src` weighted `sign * 2**shift`. `hi` past the top
        of the register means "to the top" — that slice carries the sign of a
        signed wire, as `IntType.slice` says; a slice entirely above an
        unsigned wire is zero (`None`); one above a signed wire is its sign.'''
        w, signed = self.widths[src]
        if hi is None or hi > w - 1:
            hi = w - 1
        if lo > w - 1:
            if not signed:
                return None
            lo = hi = w - 1
        if lo < 0 or hi < lo:
            raise ValueError(f'{self.name}: bad slice {src}[{hi}:{lo}]')
        b = self.bounds[src]
        isSigned = signed and hi == w - 1 and b.slice(lo, hi).isSigned
        return SliceTerm(source=src, inputShift=0, sliceStart=lo, sliceEnd=hi,
                         isSigned=isSigned, limbShift=shift, sign=sign,
                         sourceZeroLsbs=b.zeroLsbs)

    def whole(self, src: str, shift: int = 0, sign: int = 1) -> SliceTerm:
        return self.slice(src, 0, None, shift, sign)

    @staticmethod
    def const(value: int, shift: int = 0) -> SliceTerm:
        sign = 1 if value >= 0 else -1
        return SliceTerm(source='const', inputShift=0, sliceStart=0, sliceEnd=0,
                         isSigned=False, limbShift=shift, sign=sign, constValue=abs(value))

    def nafTermsOf(self, src: str, constant: int, shift: int = 0, sign: int = 1,
                   lo: int = 0, hi: int | None = None, naf=None) -> list[SliceTerm]:
        '''`sign * constant * src[hi:lo] * 2^(shift+lo)`, one term per NAF digit.
        `naf` overrides the decomposition (a modulus-lifted one, say).'''
        digits = naf if naf is not None else nafTerms(constant)
        out = []
        for s, e in digits:
            t = self.slice(src, lo, hi, shift + lo + e, sign * s)
            if t is not None:
                out.append(t)
        return out

    # --- nodes ---------------------------------------------------------------

    def heap(self, name: str, terms, bound: IntType | None = None,
             wrapBits: int | None = None, partial: bool = False, note: str = '',
             relBound: Rel | None = None) -> str:
        '''A sum of slice terms.

        `wrapBits=W`: the result is the sum modulo 2^W, unsigned — Montgomery's
        `mod R`, word-level Montgomery's `-T mod 2^w`. Otherwise the wire is
        sized by `bound` (an algebraic bound the caller proved) or by the terms'
        interval sum, and every value must lie inside it. `partial=True` marks
        a heap whose terms' full sum is NOT the value, only its low W bits are
        (the low half of a product minus a full product): its values are the
        sum modulo 2^W, checked against the bound after wrapping.'''
        terms = tuple(t for t in terms if t is not None)
        if not terms:
            raise ValueError(f'{self.name}: heap {name} has no terms')
        env = {t.source: self.bounds[t.source] for t in terms if t.source != 'const'}
        for t in terms:
            if t.source != 'const' and t.source not in self.bounds:
                raise KeyError(f'{self.name}: heap {name} reads undefined wire {t.source!r}')
        inputs = tuple(sorted({t.source for t in terms if t.source != 'const'}))
        if wrapBits is not None:
            b = IntType.unsigned(wrapBits)
            return self._addNode(Node('heap', name, inputs, b, wrapBits, False, terms=terms,
                                      wrap=True, note=note))
        termBound = sumTermsBound(list(terms), env)
        b = bound if bound is not None else termBound
        if b.isZero:
            raise ValueError(f'{self.name}: heap {name} is identically zero')
        return self._addNode(Node('heap', name, inputs, b, b.bitWidth, b.isSigned, terms=terms,
                                  partial=partial, note=note, relBound=relBound))

    def constMult(self, name: str, src: str, constant: int, naf=None, note: str = '') -> str:
        '''`src * constant` as a NAF heap, bounded by the exact product (the NAF
        terms are correlated copies of one input; their interval sum is loose).'''
        if constant == 0:
            raise ValueError(f'{self.name}: constMult {name} by zero')
        terms = self.nafTermsOf(src, constant, naf=naf)
        return self.heap(name, terms, bound=self.bounds[src] * constant, note=note)

    def mult(self, name: str, a: str, b: str | None = None, bConst: int | None = None,
             backend: str = 'dsp', dspBudget: int | None = None, note: str = '') -> str:
        '''`a * b`, or `a * bConst`, on a multiplier block.'''
        if backend not in MULT_BACKENDS:
            raise ValueError(f'{self.name}: mult backend {backend!r} not in {MULT_BACKENDS}')
        if (b is None) == (bConst is None):
            raise ValueError(f'{self.name}: mult {name} needs exactly one of b, bConst')
        ba = self.bounds[a]
        bb = self.bounds[b] if b is not None else IntType.fromConst(bConst)
        if bConst is not None and bConst <= 0:
            raise ValueError(f'{self.name}: mult {name}: constant operand must be positive')
        bound = ba * bb
        if backend == 'dsp' and name in self.dspBudgets:
            dspBudget = int(self.dspBudgets[name])
            if dspBudget == 0:
                backend = 'booth'
        if dspBudget is None:
            wa, wb = ba.bitWidth, bb.bitWidth
            dspBudget = max(1, -(-wa // 26) * -(-wb // 23))
        inputs = (a,) if b is None else (a, b)
        return self._addNode(Node('mult', name, inputs, bound, bound.bitWidth, bound.isSigned,
                                  a=a, b=b or '', bConst=bConst, backend=backend,
                                  dspBudget=dspBudget, note=note))

    def table(self, name: str, src: str, lo: int, hi: int, values, note: str = '') -> str:
        '''`values[src[hi:lo]]`, one LUT ROM.'''
        values = tuple(int(v) for v in values)
        if len(values) != 1 << (hi - lo + 1):
            raise ValueError(f'{self.name}: table {name} needs {1 << (hi - lo + 1)} entries')
        if hi > self.width(src) - 1:
            raise ValueError(f'{self.name}: table {name} indexes past {src}')
        bound = IntType(min(values), max(values), 0)
        if bound.isZero:
            bound = IntType(0, 1, 0)
        return self._addNode(Node('table', name, (src,), bound, bound.bitWidth, bound.isSigned,
                                  src=src, lo=lo, hi=hi, table=values, note=note))

    def nonzero(self, name: str, src: str, lo: int, hi: int, note: str = '') -> str:
        '''One bit: is `src[hi:lo]` nonzero?'''
        return self._addNode(Node('nonzero', name, (src,), IntType(0, 1, 0), 1, False,
                                  src=src, lo=lo, hi=hi, note=note))

    def select(self, name: str, sel: str, a: str, b: str, note: str = '', stages: int | None = None) -> str:
        '''`a` if bit 0 of `sel` is 1, else `b`: a 2:1 mux (one LUT per bit). Added for the unified CT/GS
        butterfly (operator_modeling/ntt/butterfly/UnifiedButterfly.py); no existing scheme uses it.
        `a` or `b` None (2026-11-16): the constant 0 on that side, so the node is a gate on the other operand
        (`b` when sel is 0, or `a` when sel is 1); the operand must be nonnegative.'''
        if a is None or b is None:
            src_ = b if a is None else a
            bs = self.bounds[src_]
            if bs.minValue < 0:
                raise ValueError(f'{self.name}: select {name}: a gated operand must be nonnegative')
            bound = IntType(0, max(1, bs.maxValue), 0)
            rel = self.rel.get(src_) if self.relq is not None else None      # 0 <= gated <= operand
            return self._addNode(Node('select', name, (sel, src_), bound, bound.bitWidth, False,
                                      src=sel, a=a or '', b=b or '', relBound=rel, note=note, stagesOverride=stages))
        ba, bb = self.bounds[a], self.bounds[b]
        bound = IntType(min(ba.minValue, bb.minValue), max(ba.maxValue, bb.maxValue), 0)
        if bound.isZero:
            bound = IntType(0, 1, 0)
        rel = None
        if self.relq is not None:
            ra, rb = self.rel.get(a), self.rel.get(b)
            if ra is not None and rb is not None and repr(ra) == repr(rb):
                rel = ra
        return self._addNode(Node('select', name, (sel, a, b), bound, bound.bitWidth, bound.isSigned,
                                  src=sel, a=a, b=b, relBound=rel, note=note, stagesOverride=stages))

    def correct(self, name: str, src: str, modulus: int, step: int = 1, note: str = '') -> str:
        '''`src - k*q` for the largest candidate `k` that leaves it nonnegative:
        into [0, q) when `step == 1`, lazily into [0, step*q) otherwise.'''
        b = self.bounds[src]
        kLow, kHigh = b.minValue // modulus, b.maxValue // modulus
        if step < 1:
            raise ValueError('correct: step must be >= 1')
        top = kLow + ((kHigh - kLow) // step) * step
        if top == kLow:     # one candidate: a fixed offset, the range just moves
            bound = IntType(b.minValue - kLow * modulus, b.maxValue - kLow * modulus, 0)
        else:
            bound = IntType(0, min(step * modulus - 1, b.maxValue - kLow * modulus), 0)
        if bound.isZero:
            bound = IntType(0, 1, 0)
        return self._addNode(Node('correct', name, (src,), bound, bound.bitWidth, False,
                                  src=src, modulus=modulus, kLow=kLow, kHigh=top, step=step,
                                  note=note, fold=self._foldOf(kLow, top, step)))

    def qmultiple(self, name: str, qwire: str, k: int, note: str = '') -> str:
        '''`k * q` (k > 0) for a run-time modulus on wire `qwire`: q itself for
        k = 1, a wire for a power of two, a small adder otherwise; one wire per
        (q, k), shared by every consumer. It depends on q alone, so the
        schedule computes it early, off the data's path. `name` is used only
        for a lift (`nonnegative`); the shared multiples are `<q>_x<k>`.'''
        if k <= 0:
            raise ValueError(f'{self.name}: qmultiple {name}: k must be positive, got {k}')
        if k == 1:
            return qwire
        shared = f'{qwire}_x{k}'
        if shared in self.bounds:
            return shared
        return self.heap(shared, self.nafTermsOf(qwire, k), bound=self.bounds[qwire] * k,
                         note=note or f'{k}*q')

    def qcorrect(self, name: str, src: str, qwire: str, step: int = 1, note: str = '') -> str:
        '''`correct` for a modulus that arrives on a wire: `src - k*q` for the
        largest candidate `k` that leaves it nonnegative, `q` the trial's own
        value. The candidates cover every `floor(src/q)` over the source's bound
        and every q in the wire's bound, so the result is in [0, q) (or
        [0, step*q)) of the trial's q; the wire's bound is only `step*qMax`.'''
        if step < 1:
            raise ValueError('qcorrect: step must be >= 1')
        b, qb = self.bounds[src], self.bounds[qwire]
        qMin, qMax = qb.minValue, qb.maxValue
        if qMin < 2:
            raise ValueError(f'{self.name}: qcorrect {name}: the modulus wire {qwire} may be below 2 ({qb})')
        kLow = b.minValue // qMin if b.minValue < 0 else b.minValue // qMax
        kHigh = b.maxValue // qMin if b.maxValue >= 0 else b.maxValue // qMax
        rsrc = self.relOf(src)
        if rsrc is not None:        # the bound relative to the trial's q: fewer candidates
            rl, rh = rsrc.kRange(qMin, qMax)
            kLow, kHigh = max(kLow, rl), min(kHigh, rh)
            if kHigh < kLow:
                kHigh = kLow
        top = kLow + ((kHigh - kLow) // step) * step
        lo = b.minValue - max(kLow * qMin, kLow * qMax)
        if top == kLow:     # one candidate: a fixed multiple, the range just moves
            bound = IntType(lo, b.maxValue - min(kLow * qMin, kLow * qMax), 0)
            relOut = None
            if rsrc is not None and qwire in self.rel:      # v - kLow*q, kLow of either sign
                qL, qU = self.rel[qwire].L, self.rel[qwire].U
                relOut = rsrc + (Rel(-qU.scale(kLow), -qL.scale(kLow)) if kLow >= 0
                                 else Rel(-qL.scale(kLow), -qU.scale(kLow)))
        else:
            bound = IntType(0, min(step * qMax - 1, b.maxValue - min(kLow * qMin, kLow * qMax)), 0)
            relOut = None
            if self.relq is not None and qwire in self.rel:
                from .relbound import Poly
                relOut = Rel(Poly.const(0), self.rel[qwire].U.scale(step) - Poly.const(1))
        if relOut is not None:
            # the absolute bound pairs the extremes of src and of q independently; the
            # relation to the trial's q is exact, so its span over the q range is a bound too
            import math
            sl, sh = relOut.span(qMin, qMax)
            lo2, hi2 = max(bound.minValue, math.ceil(sl)), min(bound.maxValue, math.floor(sh))
            if lo2 <= hi2:
                bound = IntType(lo2, hi2, 0)
        if bound.isZero:
            bound = IntType(0, 1, 0)
        mults = []                  # per candidate: the wire |k|*q (subtracted for k > 0, added for k < 0)
        for k in range(kLow, top + 1, step):
            mults.append('' if k == 0 else self.qmultiple(name, qwire, abs(k)))
        # q itself is not an input: the RTL subtracts the k*q wires (k = 1 is a wire heap of q).
        inputs = (src,) + tuple(m for m in mults if m)
        return self._addNode(Node('qcorrect', name, tuple(dict.fromkeys(inputs)), bound, bound.bitWidth,
                                  bound.isSigned, src=src, kLow=kLow, kHigh=top, step=step,
                                  qwire=qwire, qMults=tuple(mults), qMin=qMin, qMax=qMax, note=note,
                                  relBound=relOut, fold=self._foldOf(kLow, top, step)))

    def candidates(self, node: Node) -> list[int]:
        return list(range(node.kLow, node.kHigh + 1, node.step))

    def _foldOf(self, kLow: int, kHigh: int, step: int) -> str:
        '''A two-candidate correction needs no select:
        - candidates {-s, 0} (x in [-s*q, s*q)): y = x + [x < 0]*s*q, the sign
          bit gates s*q into one adder ('sign': no comparator, no extra cycle);
        - candidates {0, s} (x in [0, 2s*q)): s_ = [x >= s*q], then
          y = x - s_*s*q: a comparator, then the gated subtractor ('compare':
          one more cycle when registered between them, and x held there).'''
        if kHigh - kLow != step or self.foldCorrections == 'never':
            return ''
        if kLow == -step:
            return 'sign'
        if kLow == 0 and self.foldCorrections == 'always':
            return 'compare'
        return ''

    # =====================================================================
    # Values
    # =====================================================================

    def evaluate(self, inputs: dict[str, list[int]], check: bool = True) -> dict[str, list[int]]:
        '''Every wire's values for a batch of inputs, bit-exact with the RTL.
        With `check`, every value is tested against its wire's bound.'''
        env: dict[str, list[int]] = {}
        sizes = set()
        for name in self.inputs:
            if name not in inputs:
                raise KeyError(f'{self.name}.evaluate: no values for input {name}')
            vals = list(inputs[name])
            b = self.bounds[name]
            if check:
                for v in vals:
                    if not b.minValue <= v <= b.maxValue:
                        raise ValueError(f'{self.name}: input {name}={v} outside {b}')
            env[name] = vals
            sizes.add(len(vals))
        if len(sizes) > 1:
            raise ValueError(f'{self.name}.evaluate: input batches differ in length')
        n = sizes.pop() if sizes else 0
        if check:
            self._relCheck(env, n, self.inputs)
        for node in self.nodes:
            env[node.name] = self._evalNode(node, env, n)
            if check:
                b = node.bound
                for i, v in enumerate(env[node.name]):
                    if not b.minValue <= v <= b.maxValue:
                        ins = {k: env[k][i] for k in self.inputs}
                        raise ModelError(
                            f'{self.name}: wire {node.name} ({node.kind}) = {v} lies outside its '
                            f'declared bound [{b.minValue}, {b.maxValue}] for inputs {ins}')
        if check:
            self._relCheck(env, n, [nd.name for nd in self.nodes])
        return env

    def _evalNode(self, node: Node, env, n: int) -> list[int]:
        if node.kind == 'heap':
            # The compressor computes the terms' sum modulo 2^W. A heap whose
            # terms are complete must have its full sum inside the bound (so
            # the low W bits ARE the value): checked on the unwrapped sum, which
            # is what catches an unsound declared bound. A `partial` heap sums
            # terms whose total lies outside W bits on purpose (the low half
            # of a product minus a full qhat*q); it keeps the low W bits.
            raw = sumTermsValue(list(node.terms), env, n)
            if node.wrap or node.partial:
                return [wrapValue(v, node.bitWidth, node.isSigned) for v in raw]
            return raw          # exact: the bound check below must hold for the full sum
        if node.kind == 'mult':
            av = env[node.a]
            bv = env[node.b] if node.b else [node.bConst] * n
            return [x * y for x, y in zip(av, bv)]
        if node.kind == 'table':
            mask = (1 << (node.hi - node.lo + 1)) - 1
            return [node.table[(x >> node.lo) & mask] for x in env[node.src]]
        if node.kind == 'nonzero':
            mask = (1 << (node.hi - node.lo + 1)) - 1
            return [1 if (x >> node.lo) & mask else 0 for x in env[node.src]]
        if node.kind == 'select':
            n_ = len(env[node.src])
            xa = env[node.a] if node.a else [0] * n_        # an empty side is the constant 0 (a gate)
            xb = env[node.b] if node.b else [0] * n_
            return [x if s & 1 else y for s, x, y in zip(env[node.src], xa, xb)]
        if node.kind == 'correct':
            q, s, k0, kt = node.modulus, node.step, node.kLow, node.kHigh
            out = []
            for x in env[node.src]:
                k = k0 + ((x // q - k0) // s) * s
                k = min(k, kt)
                out.append(x - k * q)
            return out
        if node.kind == 'qcorrect':
            # The RTL's choice: the largest candidate whose difference is nonnegative.
            s, k0, kt = node.step, node.kLow, node.kHigh
            out = []
            for x, q in zip(env[node.src], env[node.qwire]):
                k = min(max(k0 + ((x // q - k0) // s) * s, k0), kt)
                out.append(x - k * q)
            return out
        raise ValueError(node.kind)

    def run(self, inputs: dict[str, list[int]]) -> dict[str, list[int]]:
        '''Output ports' values only.'''
        env = self.evaluate(inputs)
        return {port: env[w] for port, w in self.outputs}

    # =====================================================================
    # Timing, schedule, cost
    # =====================================================================

    def _heapPlan(self, node: Node):
        from rtl_gen.heap_terms import buildHeapDescriptors
        cdesc, adesc, heights, wbh = buildHeapDescriptors(list(node.terms), node.bitWidth, f'{node.name}_')
        return cdesc, adesc, heights, wbh

    def heapStrategy(self, node: Node) -> str:
        _, adesc, heights, _ = self._heapPlan(node)
        h = max((len(e) - 1 for e in adesc), default=0)
        if h <= 1:
            return 'wire'
        if h == 2:
            return 'adder'
        return 'compressor'

    def dspScheme(self, node: Node, targetFmaxMhz: float | None):
        key = (node.name, targetFmaxMhz)
        if key not in self._dsp:
            from ..multiplier.DspMultiplierScheme import DspMultiplierScheme
            bb = self.bounds[node.b] if node.b else IntType.fromConst(node.bConst)
            self._dsp[key] = DspMultiplierScheme(name=f'{self.name}_{node.name}',
                                                 aIn=self.bounds[node.a], bIn=bb,
                                                 dspBudget=node.dspBudget,
                                                 targetFmaxMhz=targetFmaxMhz)
        return self._dsp[key]

    def boothWidths(self, node: Node) -> tuple[int, int]:
        from ..multiplier.MultiplierScheme import physicalWidthFor
        bb = self.bounds[node.b] if node.b else IntType.fromConst(node.bConst)
        return (max(physicalWidthFor(self.bounds[node.a], True), 6),
                max(physicalWidthFor(bb, True), 6))

    def units(self, node: Node) -> tuple:
        '''The register boundaries of one node, as `lut_timing.Unit`s.'''
        import lut_timing as LT
        if node.kind == 'heap':
            strat = self.heapStrategy(node)
            if strat == 'wire':
                return ()
            if strat == 'adder':
                return LT.adder_units(node.bitWidth)
            _, _, heights, _ = self._heapPlan(node)
            return LT.heap_units(heights)
        if node.kind == 'mult':
            if node.backend == 'booth':
                return LT.bmult_units(*self.boothWidths(node))
            return ()        # dsp: the backend times itself; behavioural: unknown
        if node.kind == 'select':
            if not node.a or not node.b:
                # a gate (one side is 0) in front of an adder or subtracter: one more input of the same LUT that
                # forms the sum bit, so no logic level of its own (2026-11-16, the unified butterfly)
                return ()
            return (LT.Unit('table', TABLE_LUT_NS, f'2:1 select of {node.bitWidth} bits'),)
        if node.kind in ('table', 'nonzero'):
            return (LT.Unit('table' if node.kind == 'table' else 'or',
                            TABLE_LUT_NS * self.lutLevels(node), f'{node.kind} {node.hi - node.lo + 1}-bit'),)
        if node.kind in ('correct', 'qcorrect') and node.fold:
            cw = self.correctWidth(node)
            add = LT.Unit('correct', LT.terminal_ns(cw, True), f'gated add/subtract of {cw} bits (folded)')
            if node.fold == 'sign':
                return (add,)
            return (LT.Unit('correct', LT.terminal_ns(-(-cw // 2), True), f'compare {cw} bits'), add)
        if node.kind in ('correct', 'qcorrect'):
            n = len(self.candidates(node))
            cw = self.correctWidth(node)
            sel = 0 if n == 1 else SELECT_LUT_NS * max(1, -(-(n - 1) // 3))
            return (LT.Unit('correct', LT.terminal_ns(cw, True) + sel,
                            f'{n}-candidate correction, {cw} bits'),)
        raise ValueError(node.kind)

    def correctWidth(self, node: Node) -> int:
        '''Bits of a correction's candidate subtractors: the source and every
        candidate `src - k*q` fit, signed (every q of the range, for qcorrect).'''
        b = self.bounds[node.src]
        qs = (node.qMin, node.qMax) if node.kind == 'qcorrect' else (node.modulus,)
        lo = min([b.minValue] + [b.minValue - node.kHigh * q for q in qs] + [b.minValue - node.kLow * q for q in qs])
        hi = max([b.maxValue] + [b.maxValue - node.kLow * q for q in qs] + [b.maxValue - node.kHigh * q for q in qs])
        return IntType(lo, hi).bitWidth + (0 if lo < 0 else 1)

    @staticmethod
    def lutLevels(node: Node) -> int:
        '''LUT6 levels of a table (a k-input function per output bit: one LUT6,
        then a 2:1 mux level per extra input pair) or an OR-reduction (a tree
        of six-input ORs).'''
        k = node.hi - node.lo + 1
        if node.kind == 'nonzero':
            levels, width = 1, 6
            while width < k:
                levels, width = levels + 1, width * 6
            return levels
        return 1 if k <= 6 else 1 + -(-(k - 6) // 2)

    def isSmall(self, node: Node) -> bool:
        '''Nodes kept combinational by default and absorbed into their consumer:
        at most two LUT levels (a table of six index bits, an OR of up to 36),
        or plain wiring.'''
        if node.kind in ('table', 'nonzero'):
            return self.lutLevels(node) <= (1 if node.kind == 'table' else 2)
        if node.kind == 'select':
            return True
        if node.kind == 'heap':
            return self.heapStrategy(node) == 'wire'
        return False

    def schedule(self, pipelineStages=1, targetFmaxMhz: float | None = None,
                 absorbSmall: bool = True) -> Schedule:
        '''See `_schedule`. Under a frequency target, a small node absorbed into
        its consumer can make the consumer's first segment miss the target; it
        is then given its own register and the schedule is made again.'''
        forced: set = set()
        for _ in range(len(self.nodes) + 1):
            try:
                return self._schedule(pipelineStages, targetFmaxMhz, absorbSmall, forced)
            except _ArrivalTooLate as e:
                if not e.producers - forced:
                    raise e.cause
                forced |= e.producers
        raise RuntimeError(f'{self.name}: schedule did not converge')

    def _combProducers(self, node: Node, arrival: dict) -> set:
        out = set()
        for i in node.inputs:
            if arrival.get(i, 0.0) > 0 and i not in self.inputs:
                out.add(i)
        return out

    def _schedule(self, pipelineStages=1, targetFmaxMhz: float | None = None,
                  absorbSmall: bool = True, forced: frozenset | set = frozenset()) -> Schedule:
        '''Registers per node, start cycles, balancing delays, latency, and the
        predicted critical path.

        `pipelineStages` is an int (each node takes as many as its units absorb,
        never more) or a dict `{node: stages}` overriding single nodes (the
        rest take `'*'`, default 1). `targetFmaxMhz` instead gives each node the
        fewest stages that reach the target, counting the combinational logic
        that arrives at its first unit. Small nodes stay combinational unless a
        dict names them.'''
        import lut_timing as LT
        if isinstance(pipelineStages, dict):
            req = dict(pipelineStages)
            default = req.pop('*', 1)
        else:
            req, default = {}, pipelineStages
        if default is None or default < 0:
            raise ValueError(f'{self.name}: pipelineStages must be >= 0')
        stages, flags, start, ready, arrival, segs = {}, {}, {}, {}, {}, {}
        renamed: dict = {}
        delays: dict = {}
        for name in self.inputs:
            ready[name] = 0
            arrival[name] = 0.0
        worst = 0.0
        for node in self.nodes:
            units = self.units(node)
            inArr = max((arrival[i] for i in node.inputs), default=0.0)
            if node.name in req:
                s = req[node.name]
            elif node.stagesOverride is not None:
                s = node.stagesOverride
            elif absorbSmall and self.isSmall(node) and node.name not in forced:
                s = 0
            elif node.kind == 'mult' and node.backend == 'dsp':
                s = None
            elif node.kind == 'mult' and node.backend == 'behavioural':
                # `*` left to synthesis to map onto DSP58s: assume their three
                # internal registers (A/B, M, P) under a target. Not calibrated.
                s = BEHAVIOURAL_MULT_STAGES if targetFmaxMhz is not None else default
            elif targetFmaxMhz is not None:
                if units:
                    u = list(units)
                    u[0] = LT.Unit(u[0].kind, u[0].ns + inArr + (LT.ROUTE_INTER if inArr else 0),
                                   u[0].note)
                    try:
                        s = LT.stages_for_fmax(tuple(u), targetFmaxMhz, label=f'{self.name}.{node.name}')
                    except ValueError as e:
                        if inArr > 0:
                            raise _ArrivalTooLate(self._combProducers(node, arrival), e)
                        raise
                else:
                    s = 0
            else:
                s = default
            if node.kind == 'mult' and node.backend == 'dsp':
                sch = self.dspScheme(node, targetFmaxMhz)
                if s is not None and node.name in req:
                    raise ValueError(f'{self.name}: a DSP multiplier ({node.name}) picks its own '
                                     f'depth; give targetFmaxMhz instead of a stage count')
                lat = sch.latency()
                stages[node.name] = lat
                flags[node.name] = ()
                ns = sch.criticalPathNs()
                segs[node.name] = ns + inArr
                worst = max(worst, segs[node.name])
                arrival[node.name] = 0.0 if lat > 0 else inArr + ns
            elif node.kind == 'mult' and node.backend == 'behavioural':
                stages[node.name] = s
                flags[node.name] = ()
                segs[node.name] = 0.0
                arrival[node.name] = 0.0 if s > 0 else inArr
            else:
                if not units:
                    stages[node.name], flags[node.name] = 0, ()
                    arrival[node.name] = inArr
                else:
                    s = min(s, len(units))
                    f = list(LT.place_registers(LT.weights(units), s)) if s > 0 else [False] * len(units)
                    stages[node.name], flags[node.name] = sum(f), tuple(f)
                    seg, first, nsW = [], True, 0.0
                    for un, fl in zip(units, f):
                        seg.append(un.ns + (inArr + (LT.ROUTE_INTER if inArr else 0) if first else 0))
                        first = False
                        if fl:
                            nsW = max(nsW, LT.ENTRY + LT.EXIT + sum(seg) + LT.ROUTE_INTER * (len(seg) - 1))
                            seg = []
                    if seg:   # unregistered tail: closes in the consumer
                        arrival[node.name] = sum(seg) + LT.ROUTE_INTER * len(seg)
                    else:
                        arrival[node.name] = 0.0
                    segs[node.name] = nsW
                    worst = max(worst, nsW)
            dyn = [i for i in node.inputs if i not in self.static] if node.name not in self.static \
                else list(node.inputs)
            st = max((ready[i] for i in dyn), default=0)
            start[node.name] = st
            ready[node.name] = st + stages[node.name]
            names = []
            for i in node.inputs:
                gap = st - ready[i] if i in dyn else 0       # a static wire is read as it is
                if gap > 0:
                    dn = f'{i}_d{gap}'
                    delays[dn] = (dn, i, gap)
                    names.append(dn)
                else:
                    names.append(i)
            renamed[node.name] = tuple(names)
        # A gate (a select against 0) read by one node is placed at that node, not where its inputs are ready: its
        # inputs are delayed instead of its output. The delayed operand is usually there already (A for the other
        # adder of the unified butterfly), and the gate then sits in the adder's own LUTs (2026-11-16).
        outNames = {w for _, w in self.outputs}
        for node in self.nodes:
            if node.kind != 'select' or (node.a and node.b) or stages[node.name] or node.name in outNames:
                continue
            rd = [m for m in self.nodes if node.name in m.inputs]
            if len(rd) != 1:
                continue
            r = rd[0]
            gap = start[r.name] - ready[node.name]
            dn = f'{node.name}_d{gap}'
            if gap <= 0 or dn not in delays:
                continue
            start[node.name] += gap
            ready[node.name] += gap
            names = []
            for i in node.inputs:
                g = start[node.name] - ready[i] if i not in self.static else 0
                if g > 0:
                    di = f'{i}_d{g}'
                    delays[di] = (di, i, g)
                    names.append(di)
                else:
                    names.append(i)
            renamed[node.name] = tuple(names)
            renamed[r.name] = tuple(node.name if x == dn else x for x in renamed[r.name])
            del delays[dn]
        outReady = max((ready[w] for _, w in self.outputs), default=0)
        outRename = {}
        for port, w in self.outputs:
            gap = outReady - ready[w]
            if gap > 0:
                dn = f'{w}_d{gap}'
                delays[dn] = (dn, w, gap)
                outRename[port] = dn
            else:
                outRename[port] = w
            if arrival[w] > 0:
                worst = max(worst, LT.ENTRY + LT.EXIT + arrival[w])
        renamed['__outputs__'] = outRename
        if worst == 0.0:
            worst = LT.ENTRY + LT.EXIT
        return Schedule(stages, flags, start, ready, list(delays.values()), renamed, outReady,
                        worst, segs, targetFmaxMhz, pipelineStages)

    def nodeResources(self, node: Node, sched: Schedule | None = None) -> Resources:
        if node.kind == 'heap':
            strat = self.heapStrategy(node)
            if strat == 'wire':
                return Resources()
            if strat == 'adder':
                return Resources(lut=node.bitWidth)
            from dsp_multiplier.common.lut_cost import estimate_cmp_luts
            _, _, heights, _ = self._heapPlan(node)
            return Resources(lut=int(estimate_cmp_luts(heights).total))
        if node.kind == 'mult':
            if node.backend == 'dsp':
                lut, dsp = self.dspScheme(node, sched.targetFmaxMhz if sched else None).areaCost()
                return Resources(lut=lut, dsp=dsp)
            if node.backend == 'booth':
                from dsp_multiplier.common.lut_cost import estimate_bmult_luts
                wa, wb = self.boothWidths(node)
                return Resources(lut=int(estimate_bmult_luts(wa, wb, a_signed=True, b_signed=True).total))
            ba = self.bounds[node.a]
            bb = self.bounds[node.b] if node.b else IntType.fromConst(node.bConst)
            return Resources(dsp=-(-ba.bitWidth // 26) * -(-bb.bitWidth // 23))
        if node.kind == 'table':
            k = node.hi - node.lo + 1
            return Resources(lut=node.bitWidth * max(1, 1 << max(0, k - 6)))
        if node.kind == 'nonzero':
            k = node.hi - node.lo + 1
            return Resources(lut=max(1, -(-(k - 1) // 5)))
        if node.kind == 'select':
            return Resources(lut=node.bitWidth)
        if node.kind in ('correct', 'qcorrect') and node.fold:
            cw = self.correctWidth(node)      # measured: 62 bits, compare-folded 94 LUTs, selected 126
            return Resources(lut=cw + (-(-cw // 2) if node.fold == 'compare' else 0))
        if node.kind in ('correct', 'qcorrect'):
            cands = self.candidates(node)
            cw = self.correctWidth(node)
            subs = sum(1 for k in cands if k != 0)
            n = len(cands)
            mux = node.bitWidth * max(0, -(-(2 * n - 1) // 6)) if n > 1 else 0
            return Resources(lut=subs * cw + mux)
        raise ValueError(node.kind)

    def counts(self, sched: Schedule):
        '''`emitcount.Counts` (LUT cells, SRL16 cells, flip-flops, DSP) of the scheduled datapath,
        counted from what the back end emits and what synthesis keeps of it (`core.emitcount`).'''
        from .emitcount import totals
        key = (tuple(sorted(sched.stages.items())),
               tuple(sorted((k, tuple(v or ())) for k, v in sched.flags.items())),
               tuple(sched.delays), sched.targetFmaxMhz)
        cache = self.__dict__.setdefault('_countsCache', {})
        if key not in cache:
            import contextlib
            import io
            with contextlib.redirect_stdout(io.StringIO()):
                cache[key] = totals(self, sched)
        return cache[key]

    def resourcesEstimate(self, sched: Schedule | None = None) -> Resources:
        '''The per-node estimate (`nodeResources` + `delayCost`) that the searches rank with.
        `resources(sched)` reports the emitted counts instead.'''
        total = Resources()
        for node in self.nodes:
            total = total + self.nodeResources(node, sched)
        if sched is not None:
            total = total + Resources(lut=self.delayCost(sched)[0])
        return total

    def resources(self, sched: Schedule | None = None) -> Resources:
        '''With a schedule: LUT sites as a utilisation report counts them (`emitcount.lutSites`:
        LUT cells of `counts` x LUT_PACK + one site per two SRL16), and the DSPs.
        Without a schedule: the per-node estimate.'''
        if sched is None:
            return self.resourcesEstimate(None)
        from .emitcount import lutSites
        c = self.counts(sched)
        return Resources(lut=lutSites(c), dsp=c.dsp)

    def delayCost(self, sched: Schedule) -> tuple[int, int]:
        '''(shift-register LUTs, FFs) of the balancing delays, as Vivado maps
        register chains (calibrated on the V80 part, 2025.1 synthesis): the
        delays of one wire are one tapped chain; each segment between taps of
        s >= 2 cycles is ceil((s-1)/32) SRL LUTs plus one FF per bit, s = 1 is
        one FF; a chain from a module input keeps one more FF, and one of at
        most three cycles stays flip-flops. Bits the synthesiser trims
        (constant or unused) are counted, so this reads a little high.'''
        bySrc: dict[str, list[int]] = {}
        for _, src, cyc in sched.delays:
            bySrc.setdefault(src, []).append(cyc)
        lut = ff = 0
        for src, cycles in bySrc.items():
            w = self.width(src)
            taps = sorted(set(cycles))
            prev = 0
            for i, t in enumerate(taps):
                seg = t - prev
                prev = t
                if i == 0 and src in self.inputs:
                    if seg <= 3:
                        ff += seg * w
                    else:
                        lut += w * -(-(seg - 2) // 32)
                        ff += 2 * w
                elif seg == 1:
                    ff += w
                else:
                    lut += w * -(-(seg - 1) // 32)
                    ff += w
        return lut, ff

    def flipFlopsEstimate(self, sched: Schedule) -> int:
        '''Old estimate: every register stage of a node holds its output width, the delays what
        `delayCost` says, no DSP-multiplier fabric registers. Kept for comparison.'''
        ff = 0
        for node in self.nodes:
            if node.kind == 'mult' and node.backend == 'dsp':
                continue
            ff += sched.stages[node.name] * node.bitWidth
            if node.fold == 'compare' and sched.flags[node.name] and sched.flags[node.name][0]:
                cw = self.correctWidth(node)
                m = [w for w in node.qMults if w]
                held = 0 if (node.kind == 'correct' or (m and m[0] in self.static)) else cw
                ff += cw + held + 1 - node.bitWidth      # x, k*q and the flag replace the plain output width
        return ff + self.delayCost(sched)[1]

    def flipFlops(self, sched: Schedule) -> int:
        '''Fabric flip-flops after synthesis (`counts`): every register the back end emits,
        the DSP multipliers' fabric registers included, less the bits nobody reads, merged copies
        and the chains that become SRL16s (those are in `resources().lut`). Registers inside the
        DSP58s are not fabric.'''
        return self.counts(sched).ff

    # =====================================================================
    # Spec
    # =====================================================================

    def _wire(self, name: str) -> DpWire:
        b = self.bounds[name]
        w, s = self.widths[name]
        return DpWire(name, w, s, b.minValue, b.maxValue, b.zeroLsbs)

    def spec(self, name: str, sched: Schedule, params: dict | None = None) -> DatapathSpec:
        nodes = []
        for node in self.nodes:
            ren = dict(zip(node.inputs, sched.renamed[node.name]))
            terms = tuple(SliceTerm(**{**t.__dict__, 'source': ren.get(t.source, t.source)})
                          if t.source != 'const' else t for t in node.terms)
            nodes.append(DpNode(
                kind=node.kind, out=self._wire(node.name), inputs=sched.renamed[node.name],
                terms=terms, a=ren.get(node.a, node.a), b=ren.get(node.b, node.b),
                bConst=node.bConst, backend=node.backend, dspBudget=node.dspBudget,
                src=ren.get(node.src, node.src), lo=node.lo, hi=node.hi, table=node.table,
                modulus=node.modulus, kLow=node.kLow, kHigh=node.kHigh, step=node.step,
                qwire=ren.get(node.qwire, node.qwire), qMults=tuple(ren.get(m, m) for m in node.qMults),
                qMin=node.qMin, qMax=node.qMax, fold=node.fold,
                stages=sched.stages[node.name], regFlags=tuple(sched.flags[node.name]),
                start=sched.start[node.name], note=node.note))
        delays = tuple(DpDelay(dn, src, cyc, self.width(src)) for dn, src, cyc in sched.delays)
        wires = [self._wire(w) for w in self.inputs] + [self._wire(n.name) for n in self.nodes]
        for dn, src, _ in sched.delays:
            w = self._wire(src)
            wires.append(DpWire(dn, w.bitWidth, w.isSigned, w.minValue, w.maxValue, w.zeroLsbs))
        outs = tuple((port, sched.renamed['__outputs__'][port]) for port, _ in self.outputs)
        return DatapathSpec(name=name, inputs=tuple(self._wire(w) for w in self.inputs),
                            nodes=tuple(nodes), delays=delays, outputs=outs, wires=tuple(wires),
                            latency=sched.latency, targetFmaxMhz=sched.targetFmaxMhz,
                            params=dict(params or {}), static=tuple(sorted(self.static)),
                            shared=tuple(sorted(self.shared)))

    def describe(self, sched: Schedule | None = None) -> str:
        lines = [f'datapath {self.name}: inputs ' +
                 ', '.join(f'{i} {self.bounds[i]}' for i in self.inputs)]
        for node in self.nodes:
            extra = ''
            if sched is not None:
                extra = f'  @{sched.start[node.name]} +{sched.stages[node.name]}'
            what = node.kind
            if node.kind == 'heap':
                what = f'heap/{self.heapStrategy(node)} {len(node.terms)} terms'
            elif node.kind == 'mult':
                what = f'mult/{node.backend}'
            elif node.kind == 'correct':
                what = f'correct k={self.candidates(node)}'
            elif node.kind == 'qcorrect':
                what = f'qcorrect k={self.candidates(node)} q={node.qwire}'
            lines.append(f'  {node.name:<14} {what:<28} {node.bound}{extra}  {node.note}')
        for port, w in self.outputs:
            lines.append(f'  -> {port} = {w}')
        if sched is not None:
            lines.append(f'  latency {sched.latency}, predicted critical path {sched.criticalPathNs:.3f} ns')
        return '\n'.join(lines)


# =========================================================================
# DatapathScheme: an OperatorScheme described by a datapath
# =========================================================================

class DatapathScheme(OperatorScheme):
    '''An `OperatorScheme` whose arithmetic is a `Datapath`.

    A subclass declares its ports and writes two methods:

        inputNames  = ('A', 'B')        # bound attrs  aIn, bIn  /  values aInValues, ...
        outputNames = ('P',)
        def _build(self, dp): ...        # add nodes; dp.output('P', wire)
        def reference(self, **inputs): ...   # plain big-integer golden, per trial

    Everything else is here: the bound and value paths, the schedule under
    `pipelineStages` or `targetFmaxMhz`, latency, critical path, resources, the
    spec, the clocked twin and the reference check. The datapath is rebuilt only
    when an input bound changes.

    Bound attributes are named `<lowercase port>In` (`aIn`, `tIn`), value
    batches `<lowercase port>InValues`, as in the multiplier family.
    '''

    inputNames: tuple[str, ...] = ()
    outputNames: tuple[str, ...] = ()

    def __init__(self, name: str = 'Undefined DatapathScheme', targetFmaxMhz: float | None = None,
                 absorbSmall: bool = True, **bounds):
        super().__init__(name)
        self.targetFmaxMhz = targetFmaxMhz
        self.absorbSmall = absorbSmall
        for p in self.inputNames:
            setattr(self, self._boundAttr(p), bounds.pop(self._boundAttr(p), IntType(0, 0, 0)))
            setattr(self, self._valueAttr(p), bounds.pop(self._valueAttr(p), None))
        if bounds:
            raise TypeError(f'{type(self).__name__}: unexpected arguments {sorted(bounds)}')
        self._dpCache = None
        self._pipe = None

    @staticmethod
    def _boundAttr(port: str) -> str:
        return f'{port[0].lower()}{port[1:]}In'

    @staticmethod
    def _valueAttr(port: str) -> str:
        return f'{port[0].lower()}{port[1:]}InValues'

    @property
    def _BOUND_ATTRS(self):                       # noqa: N802 — the base reads it
        return tuple(self._boundAttr(p) for p in self.inputNames)

    @property
    def _VALUE_ATTRS(self):                       # noqa: N802
        return tuple(self._valueAttr(p) for p in self.inputNames)

    # --- the extension points ------------------------------------------

    def _build(self, dp: Datapath) -> None:
        raise NotImplementedError(f'{type(self).__name__} must implement _build(dp)')

    def reference(self, **inputs) -> dict:
        '''Plain big-integer golden for ONE trial: `{port: value}` for every
        output, from `{port: value}` for every input. Independent of the
        datapath by construction — it is what the datapath is checked against.'''
        raise NotImplementedError(f'{type(self).__name__} must implement reference()')

    def acceptsOutput(self, port: str, got: int, want: int) -> bool:
        '''How a datapath output is compared with `reference`. Equality by
        default; a modular operator accepts any representative inside its
        declared output range.'''
        return got == want

    def acceptsTrial(self, port: str, got: int, want: int, trial: dict) -> bool:
        '''`acceptsOutput` with the trial's inputs at hand: a scheme whose
        modulus arrives on a port reads it from `trial`.'''
        return self.acceptsOutput(port, got, want)

    def params(self) -> dict:
        '''Design-time parameters, recorded in the spec and the manifest.'''
        return {}

    def inputCorners(self, port: str) -> list[int]:
        '''Values of interest for one input: the bound's ends, 0, 1 and their
        neighbours. A modular scheme adds q-1, q, 2q-1 and the like.'''
        b = getattr(self, self._boundAttr(port))
        cand = [b.minValue, b.maxValue, 0, 1, b.maxValue - 1, b.minValue + 1, -1]
        return self._legal(b, cand)

    @staticmethod
    def _legal(b: IntType, cand) -> list[int]:
        step = 1 << b.zeroLsbs
        out = []
        for v in cand:
            if b.minValue <= v <= b.maxValue and v % step == 0 and v not in out:
                out.append(v)
        return out

    def sampleInputs(self, n: int, rng, corners: bool = True) -> dict[str, list[int]]:
        '''`n` trials: every combination of the inputs' corners first (up to
        half the trials), then uniform samples from the bounds.'''
        from itertools import product as _product
        from .OperatorScheme import sampleBound
        ports = list(self.inputNames)
        rows: list[tuple] = []
        if corners:
            lists = [self.inputCorners(p) for p in ports]
            for combo in _product(*lists):
                rows.append(combo)
                if len(rows) >= max(1, n // 2):
                    break
        rest = n - len(rows)
        cols = [sampleBound(getattr(self, self._boundAttr(p)), rest, rng) for p in ports]
        rows += list(zip(*cols)) if ports else []
        return {p: [r[i] for r in rows[:n]] for i, p in enumerate(ports)}

    # --- the datapath ---------------------------------------------------

    #: two-candidate corrections without a select: 'auto' (sign-decided ones), 'always', 'never'
    foldCorrections = 'auto'
    #: per mult node DSP budgets, {node name: budget} (`core/dspbudget.py`); None: the builders' own
    dspBudgets = None

    def _key(self):
        k = tuple((b.minValue, b.maxValue, b.zeroLsbs)
                  for b in (getattr(self, a) for a in self._BOUND_ATTRS)) + (self.foldCorrections,)
        return k + (tuple(sorted(self.dspBudgets.items())),) if self.dspBudgets else k

    def datapath(self) -> Datapath:
        key = self._key()
        if self._dpCache is None or self._dpCache[0] != key:
            for a in self._BOUND_ATTRS:
                if not isinstance(getattr(self, a), IntType) or getattr(self, a).isZero:
                    raise ValueError(f'{self.name}: set {a} before building the datapath')
            dp = Datapath(self.name)
            dp.foldCorrections = self.foldCorrections
            dp.dspBudgets = dict(self.dspBudgets or {})
            self._build(dp)
            if [p for p, _ in dp.outputs] != list(self.outputNames):
                raise ValueError(f'{self.name}: _build produced outputs '
                                 f'{[p for p, _ in dp.outputs]}, declared {self.outputNames}')
            self._dpCache = (key, dp)
        return self._dpCache[1]

    # --- bound and value paths ------------------------------------------

    def propagateBound(self):
        OperatorScheme.propagateBound(self)
        dp = self.datapath()
        out = [dp.bound(w) for _, w in dp.outputs]
        return out[0] if len(out) == 1 else tuple(out)

    def propagateValue(self):
        OperatorScheme.propagateValue(self)
        dp = self.datapath()
        ins = {p: getattr(self, self._valueAttr(p)) for p in self.inputNames}
        res = dp.run(ins)
        out = [res[p] for p in self.outputNames]
        return out[0] if len(out) == 1 else tuple(out)

    def checkReference(self, inputs: dict[str, list[int]]) -> list[str]:
        '''The datapath's outputs against `reference`, trial by trial.'''
        res = self.datapath().run(inputs)
        n = len(next(iter(inputs.values())))
        errors = []
        for t in range(n):
            one = {p: inputs[p][t] for p in self.inputNames}
            want = self.reference(**one)
            for p in self.outputNames:
                if not self.acceptsTrial(p, res[p][t], want[p], one):
                    errors.append(f'{self.name}: {one} -> {p}={res[p][t]}, reference {want[p]}')
                    if len(errors) > 10:
                        return errors
        return errors

    # --- timing and cost ------------------------------------------------

    def schedule(self, pipelineStages=1) -> Schedule:
        return self.datapath().schedule(pipelineStages, self.targetFmaxMhz, self.absorbSmall)

    def latency(self, pipelineStages=1) -> int:
        return self.schedule(pipelineStages).latency

    def criticalPathNs(self, pipelineStages=1) -> float:
        return self.schedule(pipelineStages).criticalPathNs

    def achievedFmaxMhz(self, pipelineStages=1) -> float:
        from lut_timing import fmax_of
        return fmax_of(self.criticalPathNs(pipelineStages))

    def resources(self, pipelineStages=1) -> Resources:
        return self.datapath().resources(self.schedule(pipelineStages))

    def areaCost(self) -> tuple[int, int]:
        r = self.resources()
        return r.lut, r.dsp

    def flipFlops(self, pipelineStages=1) -> int:
        return self.datapath().flipFlops(self.schedule(pipelineStages))

    # --- spec -------------------------------------------------------------

    def getOperatorInterface(self, name: str, pipelineStages=1) -> DatapathSpec:
        sched = self.schedule(pipelineStages)
        dp = self.datapath()
        params = dict(self.params())
        params.update(
            estimate={'lut': dp.resources(sched).lut, 'dsp': dp.resources(sched).dsp,
                      'ff': dp.flipFlops(sched), 'criticalPathNs': sched.criticalPathNs,
                      'latency': sched.latency})
        return dp.spec(name, sched, params)

    # --- the clocked twin -------------------------------------------------

    def reset(self, pipelineStages=1) -> None:
        '''Empty the pipeline. The block is fully pipelined (one batch in per
        edge), so its twin is the schedule's latency in registers.'''
        self._pipe = [None] * self.latency(pipelineStages)

    def step(self, inputs: dict[str, list[int]]):
        '''One clock edge: this cycle's input batch in, the batch `latency`
        edges old out (`None` while filling). Zero latency is combinational.'''
        if self._pipe is None:
            raise RuntimeError(f'{self.name}: call reset() before step()')
        now = self.datapath().run(inputs)
        if not self._pipe:
            return now
        out = self._pipe.pop(0)
        self._pipe.append(now)
        return out
