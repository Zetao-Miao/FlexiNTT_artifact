'''Verify the DSP multiplier model against the backend that builds it.

Three gates, one script, no test framework — the same shape as the other
top-level harnesses. Run from the project root:

    python runDspMultiplier.py            # everything (~1 min)
    python runDspMultiplier.py --quick    # a third of the designs

Gate 1 — untimed, every design in the exercise set:
  selfCheck        the walked netlist computes A*B at every sealed node
  checkWidths      the model's interval fits every width the backend declared
  crossCheck       every wire agrees with emit_tb.evaluate, the interpreter
                   that writes the RTL testbench's goldens

Gate 2 — clocked, the same designs at up to three frequency targets:
  latency          output depth == module_latency == scheme.latency()
  stream           the clocked output at tick LAT+k is the untimed product of batch k
  testbench        emit_testbench's vectors, one per edge, reproduced at the
                   edges the testbench samples them on

Gate 3 — negative: a lowered module with one alignment Delay shortened must
refuse to build.

The exercise set covers every tree node kind (Tiling, Karatsuba-2/3, Grid),
all five tile families as the search itself selects them, every sign mode,
transposed and overhanging placements, and the four-step's inter-stage shape.
'''
from __future__ import annotations

import contextlib
import dataclasses
import io
import random
import sys
import time

from operator_modeling.core.IntType import IntType
from operator_modeling.core.OperatorScheme import decodeTwosComplement, sampleBound
from operator_modeling.core.Signal import Signal
from operator_modeling.multiplier.DspMultiplierScheme import DspMultiplierScheme
from operator_modeling.multiplier.Multiplier import Multiplier
from operator_modeling.multiplier.dspmodel.net import MisalignedError
from operator_modeling.multiplier.dspmodel.walker import buildNet

import dsp_multiplier.backend.ir as IR                                # noqa: E402
from dsp_multiplier.backend.schedule import module_latency            # noqa: E402
from rtl_gen.dsp_multiplier.emit_tb import emit_testbench             # noqa: E402

#: (wa, wb, signs, dspBudget, what it exercises)
DESIGNS = [
    (8, 8, 'ss', 1, 'single tile, overhang'),
    (16, 16, 'ss', 2, 'small LUT residual'),
    (26, 26, 'ss', 2, 'flat two-term heap'),
    (32, 32, 'ss', 3, 'transposed placement'),
    (32, 64, 'ss', 2, 'Grid'),
    (45, 45, 'ss', 1, 'algebraic Karatsuba-2 + Sub'),
    (47, 47, 'ss', 4, 'chain of 2'),
    (70, 70, 'ss', 8, 'chain of 3'),
    (40, 40, 'ss', 3, 'Karatsuba-2 macro tile'),
    (64, 64, 'ss', 4, 'algebraic Karatsuba-3'),
    (64, 64, 'ss', 6, 'Karatsuba-3 macro tile'),
    (64, 64, 'uu', 4, 'unsigned x unsigned'),
    (64, 64, 'su', 4, 'signed x unsigned'),
    (64, 64, 'us', 4, 'unsigned x signed'),
    (64, 128, 'uu', 8, 'rectangular Grid'),
    (24, 70, 'ss', 4, 'tall rectangle'),
    (70, 24, 'ss', 4, 'wide rectangle'),
    (66, 64, 'su', 8, "the four-step's inter-stage shape"),
    (66, 64, 'su', 4, 'same, tighter budget'),
    (128, 128, 'ss', 12, 'large'),
    (60, 60, 'ss', 4, 'Toom-2.5 macro tile'),
    (60, 60, 'ss', 5, 'Toom-2.5 + a single'),
    (104, 60, 'ss', 8, 'Toom-2.5, Karatsuba-2 and a single in one design'),
    (108, 60, 'uu', 8, 'Toom-2.5 beside a chain'),
]
TARGETS = (None, 300, 500)


def bound(width: int, sign: str) -> IntType:
    return IntType.signed(width) if sign == 's' else IntType.unsigned(width)


def quiet(fn):
    with contextlib.redirect_stdout(io.StringIO()):
        return fn()


def gate1(designs) -> None:
    print('Gate 1 — untimed')
    print(f"  {'design':<16} {'what':<48} {'ops':>4} {'dsp wires':>9} {'viol':>4}")
    for wa, wb, signs, b, what in designs:
        sch = DspMultiplierScheme(name=f'm{wa}x{wb}{signs}', aIn=bound(wa, signs[0]),
                                  bIn=bound(wb, signs[1]), dspBudget=b)
        quiet(lambda: sch.selfCheck(testSize=48, seed=1))
        checks = sch.checkWidths(strict=True)
        rng = random.Random(7)
        av, bv = sampleBound(sch.aIn, 12, rng), sampleBound(sch.bIn, 12, rng)
        op = Multiplier(name='op', scheme=sch)
        op.inputPortA.signal, op.inputPortB.signal = Signal(sch.aIn, av), Signal(sch.bIn, bv)
        quiet(op.compute)
        assert op.outputPortP.signal.values == [x * y for x, y in zip(av, bv)]
        quiet(lambda: sch.crossCheckEvaluate(samples=6))
        dspw = sum(len(w) for w in sch._lastWalk.tileInternals.values())
        print(f"  {f'{wa}x{wb} {signs} b={b}':<16} {what:<48} {len(checks):>4} {dspw:>9} "
              f"{len([c for c in checks if not c.fits]):>4}")


def gate2(designs) -> int:
    print('\nGate 2 — clocked')
    print(f"  {'design':<16} {'target':>6} {'LAT':>4} {'regs':>5} {'delays':>6} {'tb':>4}")
    total = 0
    for wa, wb, signs, b, _ in designs:
        for tgt in TARGETS:
            sch = DspMultiplierScheme(name=f'm{wa}x{wb}{signs}', aIn=bound(wa, signs[0]),
                                      bIn=bound(wb, signs[1]), dspBudget=b, targetFmaxMhz=tgt)
            try:
                beat = quiet(sch.beat)
            except ValueError as e:
                if 'unreachable' in str(e):
                    continue
                raise
            module, _ = sch.lower()
            LAT = beat.latency
            assert LAT == module_latency(module) == quiet(sch.latency)

            # stream identity, four trials per edge
            rng = random.Random(11)
            K = 5
            aB = [sampleBound(sch.aIn, 4, rng) for _ in range(K)]
            bB = [sampleBound(sch.bIn, 4, rng) for _ in range(K)]
            beat.reset()
            for k in range(K + LAT):
                i = min(k, K - 1)
                out = beat.step(aB[i], bB[i])
                if k < LAT - 1:
                    assert out is None
                elif k - (LAT - 1) < K:
                    j = k - (LAT - 1)
                    assert out == [x * y for x, y in zip(aB[j], bB[j])], (wa, wb, tgt, k)

            # the testbench's own vectors, sampled the way the testbench samples them
            _, vectors, expected = emit_testbench(module, test_size=24, seed=3)
            A_port, B_port, out_sig = module.inputs[0], module.inputs[1], module.output
            mask = (1 << out_sig.width) - 1
            beat.reset()
            checked = 0
            for ci in range(len(vectors) + LAT):
                v = vectors[min(ci, len(vectors) - 1)]
                got = beat.step([decodeTwosComplement(v['A'], A_port.width, A_port.signed)],
                                [decodeTwosComplement(v['B'], B_port.width, B_port.signed)])
                j = ci - (LAT - 1)
                if 0 <= j < len(expected):
                    assert (got[0] & mask) == expected[j], (wa, wb, tgt, ci)
                    checked += 1
            assert checked == len(vectors)
            nregs = sum(n.cycles for n in beat.net._nodes if n.kind == 'reg')
            ndelay = sum(1 for op in module.ops if isinstance(op, IR.Delay))
            total += 1
            print(f"  {f'{wa}x{wb} {signs} b={b}':<16} {str(tgt):>6} {LAT:>4} {nregs:>5} {ndelay:>6} {checked:>4}")
    return total


def gate3() -> None:
    print('\nGate 3 — negative')
    sch = DspMultiplierScheme(name='neg', aIn=IntType.signed(64), bIn=IntType.signed(64), dspBudget=4)
    module, _ = quiet(sch.lower)
    _, trace = sch.ir()
    d = next(op for op in module.ops if isinstance(op, IR.Delay))
    if d.cycles > 1:
        ops = tuple(IR.Delay(result=d.result, source=d.source, cycles=d.cycles - 1)
                    if op is d else op for op in module.ops)
    else:
        ops = []
        for op in module.ops:
            if op is d:
                continue
            if isinstance(op, IR.BitHeap) and any(t.signal.name == d.result.name for t in op.terms):
                terms = tuple(dataclasses.replace(t, signal=d.source) if t.signal.name == d.result.name
                              else t for t in op.terms)
                op = IR.BitHeap(result=op.result, terms=terms, latency=op.latency,
                                sign_mode=op.sign_mode)
            if isinstance(op, IR.LutMult):
                if op.a.name == d.result.name:
                    op = dataclasses.replace(op, a=d.source)
                if op.b.name == d.result.name:
                    op = dataclasses.replace(op, b=d.source)
            ops.append(op)
        ops = tuple(ops)
    broken = IR.IRModule(name=module.name, inputs=module.inputs, ops=ops, output=module.output)
    try:
        buildNet(broken, trace, Signal(sch.aIn), Signal(sch.bIn), timed=True)
    except MisalignedError as e:
        print('  a shortened alignment Delay is refused:', str(e)[:90], '...')
        return
    raise AssertionError('a shortened alignment Delay was accepted')


if __name__ == '__main__':
    designs = DESIGNS[::3] if '--quick' in sys.argv else DESIGNS
    t0 = time.time()
    gate1(designs)
    n = gate2(designs)
    gate3()
    print(f'\nall gates passed: {len(designs)} designs untimed, {n} clocked, in {time.time() - t0:.0f}s')
