#!/usr/bin/env python3
"""check_heap_values.py -- every butterfly's heap against the value path, no simulator.

For each NTT built here, each butterfly's two heap descriptors are evaluated on
the values its input ports actually carry and compared with `propagateValue`
modulo 2^width. The RTL implements the heap and the testbench's goldens come
from the value path, so a disagreement is a failing simulation found in seconds.

    python scripts/check_heap_values.py
"""
from __future__ import annotations

import contextlib
import io
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "versal_arith"))
from operator_modeling.core.IntType import IntType  # noqa: E402
from operator_modeling.ntt.pipelined.FullyPipelinedNTT import FullyPipelinedINTT, FullyPipelinedNTT  # noqa: E402
from operator_modeling.ntt.twiddles import calculateInttTwiddles, calculateNttTwiddles  # noqa: E402
from rtl_gen.butterfly import _build_heap_descriptors  # noqa: E402

Q = 2**64 - 2**32 + 1
BOUNDS = [IntType.unsigned(w) for w in (1, 8, 16, 24, 30, 32, 40, 63, 64, 65, 66)] + \
         [IntType.signed(w) for w in (8, 24, 64, 65, 66, 96, 128, 130, 132)]
TRIALS = 64


def heap_value(assign_desc: list, env: dict, trial: int) -> int:
    total = 0
    for entry in assign_desc:
        for sig, idx, neg, cnst in entry[1:]:
            if cnst:
                bit = 1
            elif sig is None:
                bit = 0
            else:
                bit = (env[sig][trial] >> idx) & 1
                bit ^= 1 if neg else 0
            total += bit << entry[0]
    return total


def main() -> int:
    rng = random.Random(1)
    designs = checked = 0
    for n in (8, 16):
        for name, klass, twiddles, kinds in (("ntt", FullyPipelinedNTT, calculateNttTwiddles, ("GS", "CT")),
                                             ("intt", FullyPipelinedINTT, calculateInttTwiddles, ("GS", "CT"))):
            for bt in kinds:
                tw = twiddles(Q, n, bt, useModulusLiftingNaf=True)
                for bound in BOUNDS:
                    with contextlib.redirect_stdout(io.StringIO()):
                        ntt = klass(name="m", n=n, q=Q, butterflyType=bt, twiddles=tw)
                        ntt.getInputsNatural([bound] * n)
                        ntt.getInputsNatural([[rng.randint(bound.minValue, bound.maxValue)
                                               for _ in range(TRIALS)] for _ in range(n)])
                        ntt.compute()
                    designs += 1
                    for s, layer in enumerate(ntt.butterflies):
                        for p, b in enumerate(layer):
                            spec = b.scheme.getOperatorInterface("x")
                            env = {"aIn": b.inputPortA.testVector, "bIn": b.inputPortB.testVector}
                            for label, terms, width, out in (
                                    ("aOut", spec.aOutTerms, spec.aOutBitWidth, b.outputPortA.testVector),
                                    ("bOut", spec.bOutTerms, spec.bOutBitWidth, b.outputPortB.testVector)):
                                _, assign, _, _ = _build_heap_descriptors(terms, width, f"{label}_")
                                for t in range(TRIALS):
                                    checked += 1
                                    got = heap_value(assign, env, t)
                                    if (got - out[t]) % (1 << width) != 0:
                                        print(f"MISMATCH {name}{n} {bt} bound "
                                              f"[{bound.minValue},{bound.maxValue}] L{s} p{p} {label} "
                                              f"trial {t}: heap {got % (1 << width):x} value "
                                              f"{out[t] % (1 << width):x}")
                                        return 1
    print(f"PASS {designs} NTTs, {checked} heap evaluations")
    return 0


if __name__ == "__main__":
    sys.exit(main())
