'''Ground truth for an NTT pipeline: O(n^2) references and the verify harness.

`referenceNtt` / `referenceIntt` are deliberately the naive transforms, computed
in Sage — they exist to be obviously correct, not fast. `verifyNtt` /
`verifyIntt` drive random vectors through a populated pipeline and check two
separate things: that every output matches the reference modulo q, and that
every intermediate value lands inside the interval the bound path predicted for
its port.

**The mod-q half is weaker than it looks.** It compares `output % q`, so a
result that has drifted by a whole multiple of q still passes. That is not
hypothetical — slicing at the wrong register width produces exactly such a
drift, which is why `shiftAndSliceGoldilocks64Value` now refuses to guess a
width, and why the refactor gate is a byte-identical diff of the emitted
testvectors rather than this harness alone.
'''
from __future__ import annotations

import random
from typing import TYPE_CHECKING

from sage.all import GF

from .roots import fixedRoot

from ..core.IntType import IntType
from ..core.OperatorScheme import sampleBound
from ..core.utils import MEM_GRID_ORDERS as STAGE_ORDERS, bitReverse

if TYPE_CHECKING:                      # avoids a circular import at runtime
    from .pipelined.FullyPipelinedNTT import FullyPipelinedINTT, FullyPipelinedNTT
    # multistep imports the pipelined NTT, so this one must stay type-only in both
    # directions or the package will not import.
    from .multistep.FourStepNTT import FourStepNTT

def referenceNtt(x: list[int], modulus: int,
                 primitiveRoot: int | None = None,
                 negacyclic: bool = False) -> list[int]:
    '''Slow O(n^2) reference NTT for verification. Computes Y[k] for k in [0, n):
        cyclic:     Y[k] = sum_i x[i] * w^(i*k)         mod modulus
        negacyclic: Y[k] = sum_i x[i] * psi^(i*(2k+1))  mod modulus
    where w = fixedRoot(F, n) and psi = fixedRoot(F, 2n) by default (matching calculateNttTwiddles; roots.py).
    Output is a Python list[int] in [0, modulus), in natural order Y[0], Y[1], ..., Y[n-1].
    To compare against a pipeline whose output is in bit-reversed memory order
    (FullyPipelinedNTT with butterflyType='GS'), apply bitReverse to one side.'''
    if not isinstance(x, list) or not all(isinstance(v, int) for v in x):
        raise TypeError('x must be a list[int]')
    n = len(x)
    if n < 1:
        raise ValueError('x must be non-empty')
    F = GF(modulus)
    base = F(primitiveRoot) if primitiveRoot is not None else (fixedRoot(F, 2 * n) if negacyclic else fixedRoot(F, n))
    if negacyclic:
        return [int(sum(F(x[i]) * base ** (i * (2 * k + 1)) for i in range(n))) for k in range(n)]
    return [int(sum(F(x[i]) * base ** (i * k) for i in range(n))) for k in range(n)]


def referenceIntt(y: list[int], modulus: int,
                  primitiveRoot: int | None = None,
                  negacyclic: bool = False,
                  divideByN: bool = True) -> list[int]:
    '''Slow O(n^2) reference inverse NTT for verification. Inverts referenceNtt by raising to w^(-1) (cyclic) or psi^(-1) (negacyclic). With divideByN=True (default), returns the canonical mathematical inverse so referenceIntt(referenceNtt(x)) == x. With divideByN=False, omits the 1/n factor so the result equals n*x mod modulus — useful for verifying FullyPipelinedINTT, which intentionally drops the 1/n scaling. Output is in natural order x[0], x[1], ..., x[n-1].'''
    if not isinstance(y, list) or not all(isinstance(v, int) for v in y):
        raise TypeError('y must be a list[int]')
    n = len(y)
    if n < 1:
        raise ValueError('y must be non-empty')
    F = GF(modulus)
    fwdBase = F(primitiveRoot) if primitiveRoot is not None else (fixedRoot(F, 2 * n) if negacyclic else fixedRoot(F, n))
    invBase = fwdBase ** (-1)
    if negacyclic:
        x = [sum(F(y[k]) * invBase ** (i * (2 * k + 1)) for k in range(n)) for i in range(n)]
    else:
        x = [sum(F(y[k]) * invBase ** (i * k) for k in range(n)) for i in range(n)]
    if divideByN:
        nInv = F(n) ** (-1)
        x = [v * nInv for v in x]
    return [int(v) for v in x]


def _verifyImpl(instance: FullyPipelinedNTT, isInverse: bool, primitiveRoot: int | None,
                batchSize: int, seed: int | None,
                inputBound: 'IntType | list[IntType] | None',
                valueRange: tuple[int, int] | None, verbose: bool) -> bool:
    if instance.negacyclic:
        # NWC requires the standard pairing: forward = CT, inverse = GS.
        if not isInverse and instance.butterflyType != 'CT':
            raise ValueError(
                f"verifyNtt for negacyclic instance requires butterflyType == 'CT'; "
                f"got {instance.butterflyType!r}. The GS butterfly equation does not "
                f"compute a forward NWC NTT under cyclic-CT-style wiring."
            )
        if isInverse and instance.butterflyType != 'GS':
            raise ValueError(
                f"verifyIntt for negacyclic instance requires butterflyType == 'GS'; "
                f"got {instance.butterflyType!r}. The CT butterfly equation does not "
                f"compute an inverse NWC NTT under cyclic-CT-style wiring."
            )
    if seed is not None:
        random.seed(seed)
    n = instance.n
    q = instance.q
    negacyclic = instance.negacyclic

    # inputBound accepts three forms:
    #   - None         : default IntType.signed(66) broadcast to every natural index
    #   - IntType      : broadcast to every natural index (current behavior)
    #   - list[IntType]: per-natural-index list of length n; each x[i]'s value
    #                    range is derived from its own bound's [minValue, maxValue]
    #                    and `valueRange` is ignored (a single global range cannot
    #                    represent per-port mixed signed/unsigned widths)
    if inputBound is None:
        inputBound = IntType.signed(66)
    if isinstance(inputBound, list):
        if len(inputBound) != n:
            raise ValueError(
                f'inputBound list must have length n={n}, got {len(inputBound)}'
            )
        bounds_per_natural = inputBound
        # Must go through sampleBound, not a bare randint over [min, max]: a
        # bound carries known-zero LSBs, and the emitted hardware has no bits in
        # those positions at all. A sample with nonzero bits down there is a
        # value the datapath cannot represent, so propagating it lands outside
        # the predicted interval and the containment check fails on correct
        # hardware. Primary NTT inputs have zeroLsbs == 0 and never noticed;
        # inputs driven from a constant-multiplier bank routinely do not.
        natural = [sampleBound(b, batchSize, random) for b in bounds_per_natural]
    else:
        if valueRange is None:
            valueRange = (-(2 ** 65), 2 ** 65 - 1)
        bounds_per_natural = [inputBound] * n
        # `valueRange` overrides the bound's interval, but it cannot override the
        # bound's known-zero LSBs — same unrepresentability argument as above, so
        # snap the range onto that lattice. A no-op when zeroLsbs == 0, which
        # keeps every existing caller sampling exactly the values it did before.
        step = 1 << inputBound.zeroLsbs
        lo = (-((-valueRange[0]) // step) if valueRange[0] < 0
              else valueRange[0] // step)
        hi = valueRange[1] // step
        natural = [[random.randint(lo, hi) * step for _ in range(batchSize)]
                   for _ in range(n)]

    instance.getInputsNatural(bounds_per_natural)
    instance.getInputsNatural(natural)
    instance.compute()

    # Read testVector straight off the natural-order output ports. Not
    # getOutputsNatural(), which prefers `bound` when both are set — and both are
    # set above. The ports themselves are already in natural order, so there is
    # no permutation to redo here.
    pipelineOutNatural = [p.testVector for p in instance.outputPorts]

    modQFails = 0
    for b in range(batchSize):
        x = [natural[m][b] for m in range(n)]
        if isInverse:
            ref = referenceIntt(x, q, primitiveRoot=primitiveRoot, negacyclic=negacyclic, divideByN=False)
        else:
            ref = referenceNtt(x, q, primitiveRoot=primitiveRoot, negacyclic=negacyclic)
        for m in range(n):
            actual = pipelineOutNatural[m][b] % q
            if actual != ref[m]:
                modQFails += 1
                if verbose and modQFails <= 5:
                    print(f'  mod-q mismatch batch {b} pos {m}: actual={actual}, ref={ref[m]}')

    boundFails = 0
    portCount = 0
    for layer in instance.butterflies:
        for bfly in layer:
            for outPort in (bfly.outputPortA, bfly.outputPortB):
                bnd = outPort.bound
                vec = outPort.testVector
                if bnd is None or vec is None:
                    continue
                portCount += len(vec)
                for v in vec:
                    if v < bnd.minValue or v > bnd.maxValue:
                        boundFails += 1

    totalModQ = batchSize * n
    if verbose:
        label = 'verifyIntt' if isInverse else 'verifyNtt'
        print(f'{label} {instance.name}: '
              f'mod-q {totalModQ - modQFails}/{totalModQ}, '
              f'bound containment {portCount - boundFails}/{portCount}')
    return modQFails == 0 and boundFails == 0


def verifyNtt(instance: FullyPipelinedNTT,
              primitiveRoot: int | None = None,
              batchSize: int = 4,
              seed: int | None = None,
              inputBound: 'IntType | list[IntType] | None' = None,
              valueRange: tuple[int, int] | None = None,
              verbose: bool = True) -> bool:
    '''Generate `batchSize` random natural-order test vectors, run them through `instance` (loading both bounds and values so propagateValue uses the same hardware-register slicing as propagateBound), compute the reference via referenceNtt, and check (a) pipeline_output[m] mod q == referenceNtt(x)[m] for every m and every batch element, and (b) every actual test value at every output port lies inside that port's bound interval. Returns True iff both pass everywhere; False otherwise. With verbose=True (default) prints the first 5 mod-q failure lines and a summary. `primitiveRoot` should match what was used to build the twiddles; if None, defaults to F.zeta(n) (cyclic) or F.zeta(2n) (negacyclic), matching calculateNttTwiddles. `inputBound` accepts three forms: None (default IntType.signed(66) broadcast), a single IntType (broadcast to every natural index), or a list[IntType] of length n (per-natural-index bounds — values sampled within each bound's [minValue, maxValue], `valueRange` is ignored in this case). `valueRange` defaults to (-(2**65), 2**65 - 1) when broadcasting; override both consistently if changing either.'''
    return _verifyImpl(instance=instance, isInverse=False, primitiveRoot=primitiveRoot,
                       batchSize=batchSize, seed=seed, inputBound=inputBound,
                       valueRange=valueRange, verbose=verbose)


def verifyIntt(instance: FullyPipelinedINTT,
               primitiveRoot: int | None = None,
               batchSize: int = 4,
               seed: int | None = None,
               inputBound: 'IntType | list[IntType] | None' = None,
               valueRange: tuple[int, int] | None = None,
               verbose: bool = True) -> bool:
    '''Same as verifyNtt but compares against referenceIntt(..., divideByN=False), since FullyPipelinedINTT intentionally drops the 1/n scaling. Pass the FORWARD `primitiveRoot` (referenceIntt inverts it internally to get the inverse base). `inputBound` accepts the same three forms as verifyNtt: None, a single IntType, or a list[IntType] of length n.'''
    return _verifyImpl(instance=instance, isInverse=True, primitiveRoot=primitiveRoot,
                       batchSize=batchSize, seed=seed, inputBound=inputBound,
                       valueRange=valueRange, verbose=verbose)


# ---------------------------------------------------------------------------
# Four-step NTT
# ---------------------------------------------------------------------------

def referenceNttFast(x: list[int], modulus: int,
                     primitiveRoot: int | None = None,
                     negacyclic: bool = False) -> list[int]:
    '''O(n log n) reference transform. Same contract as `referenceNtt`, and
    deliberately a different algorithm.

    Speed is the lesser reason it exists. At n = 16384 the Sage O(n^2)
    `referenceNtt` costs around 152 s per vector against 0.06 s here, so it is
    what makes checking a 2^14 transform practical at all. But the reason it is
    the right reference for a *four-step* is that it is a flat radix-2 transform
    sharing no structure with one -- no index split, no corner turn, no
    lane-versus-beat distinction. Only a reference that never decomposes can
    catch a mistaken decomposition convention; a four-step checked against a
    four-step applies the same error on both sides and passes.

    That independence earned itself twice during bring-up, catching a beat-major
    twiddle file read as lane-major and, separately, natural-order output ports
    being read as the RTL's bit-reversed wires. Both produced plausible
    full-length data that no shape check could reject.

    Pinned against `referenceNtt` at n = 2..256, cyclic and negacyclic, which is
    what licenses using it where the slow one cannot run.
    '''
    if not isinstance(x, list) or not all(isinstance(v, int) for v in x):
        raise TypeError('x must be a list[int]')
    n = len(x)
    if n < 1:
        raise ValueError('x must be non-empty')
    if n & (n - 1):
        raise ValueError(f'referenceNttFast needs a power-of-two length, got {n}')
    q = modulus
    if primitiveRoot is not None:
        base = primitiveRoot % q
    else:
        F = GF(q)
        base = int(fixedRoot(F, 2 * n) if negacyclic else fixedRoot(F, n))

    if negacyclic:
        # Y[k] = sum_i x[i] * psi^(i(2k+1)) = cyclic NTT of (x[i] * psi^i) at w = psi^2
        a = [x[i] * pow(base, i, q) % q for i in range(n)]
        w = base * base % q
    else:
        a = [v % q for v in x]
        w = base

    # decimation-in-time: permute into bit-reversed order, then butterfly upward
    j = 0
    for i in range(1, n):
        bit = n >> 1
        while j & bit:
            j ^= bit
            bit >>= 1
        j |= bit
        if i < j:
            a[i], a[j] = a[j], a[i]
    length = 2
    while length <= n:
        step = pow(w, n // length, q)
        half = length // 2
        for start in range(0, n, length):
            twiddle = 1
            for k in range(start, start + half):
                u = a[k]
                v = a[k + half] * twiddle % q
                a[k] = (u + v) % q
                a[k + half] = (u - v) % q
                twiddle = twiddle * step % q
        length <<= 1
    return a


def _fourStepInputs(instance, inputBound, x, trials, rng) -> list[list[int]]:
    '''Resolve `x` / `trials` into a list of natural-order transforms.'''
    N = instance.N
    if x is None:
        if trials < 1:
            raise ValueError(f'verifyFourStepNtt: trials must be >= 1, got {trials}')
        return [sampleBound(inputBound, N, rng) for _ in range(trials)]

    if not isinstance(x, list) or not x:
        raise TypeError('verifyFourStepNtt: x must be a non-empty list')
    vectors = x if isinstance(x[0], list) else [x]
    for t, vector in enumerate(vectors):
        if not isinstance(vector, list) or not all(isinstance(v, int) for v in vector):
            raise TypeError(
                f'verifyFourStepNtt: x[{t}] must be a list[int]; pass one '
                f'natural-order transform, or a list of them'
            )
        if len(vector) != N:
            raise ValueError(
                f'verifyFourStepNtt: x[{t}] has length {len(vector)}, expected '
                f'exactly N={N} -- each entry is one whole transform in natural order'
            )
        step = 1 << inputBound.zeroLsbs
        for i, value in enumerate(vector):
            if value < inputBound.minValue or value > inputBound.maxValue:
                raise ValueError(
                    f'verifyFourStepNtt: x[{t}][{i}]={value} lies outside '
                    f'inputBound {inputBound}'
                )
            if value % step:
                raise ValueError(
                    f'verifyFourStepNtt: x[{t}][{i}]={value} has bits below the '
                    f'{inputBound.zeroLsbs} known-zero LSBs of inputBound; the '
                    f'datapath has no wires there'
                )
    return vectors


def verifyFourStepNtt(instance: 'FourStepNTT',
                      psi: int,
                      inputBound: IntType | None = None,
                      x=None,
                      trials: int = 1,
                      seed: int | None = None,
                      saveDir=None,
                      saveOrder: str = 'beatMajor',
                      saveRadix: str = 'hex',
                      savePrefix: str = '',
                      verbose: bool = True) -> bool:
    '''Drive whole negacyclic transforms through a `FourStepNTT` and check them.

    Checks two separate things, as `verifyNtt` does: every output matches
    `referenceNttFast` modulo q, and every value on every interior port lies
    inside the bound that port predicted.

    `x` is either one natural-order `list[int]` of length N, or a list of them
    for several trials; `trials` samples that many at random instead. `psi` is
    the 2N-th root the transform is built on -- the same one the pre-twist
    constants and the inter-stage twiddles were generated from.

    `saveDir` dumps every stage before comparing, so a failing run still leaves
    its stage files. That is exactly when they are wanted.

    **The mod-q half is weaker than it looks**, for the reason written at the top
    of this file: it compares `output % q`, so a result that has drifted by a
    whole multiple of q still passes. Byte-comparing the stage dumps against a
    known-good run is the stronger check.
    '''
    q = instance.q
    N = instance.N
    if inputBound is None:
        inputBound = instance.scheme.inputBound
    if saveDir is not None:
        # Validate the dump arguments before computing, not inside the dumper: a
        # typo here would otherwise only surface once the whole pipeline has
        # already run, which at N = 16384 is the entire point of the call.
        if saveOrder not in STAGE_ORDERS:
            raise ValueError(
                f'verifyFourStepNtt: saveOrder must be one of {STAGE_ORDERS}, '
                f'got {saveOrder!r}'
            )
        if saveRadix not in ('hex', 'bin'):
            raise ValueError(
                f"verifyFourStepNtt: saveRadix must be 'hex' or 'bin', got "
                f'{saveRadix!r}'
            )
    rng = random
    if seed is not None:
        random.seed(seed)

    vectors = _fourStepInputs(instance, inputBound, x, trials, rng)
    T = len(vectors)

    instance.getInputsNatural([inputBound] * N)
    instance.getInputsNatural([[vectors[t][i] for t in range(T)] for i in range(N)])
    instance.compute()

    if saveDir is not None:
        written = instance.saveStageOutputs(saveDir, order=saveOrder,
                                            radix=saveRadix, prefix=savePrefix)
        if verbose:
            print(f'  saved {len(written)} stage dumps to {saveDir} '
                  f'({saveOrder}, {saveRadix})')

    actual = [p.testVector for p in instance.outputPorts]
    modQFails = 0
    for t in range(T):
        ref = referenceNttFast(vectors[t], q, primitiveRoot=psi, negacyclic=True)
        for k in range(N):
            if actual[k][t] % q != ref[k]:
                modQFails += 1
                if verbose and modQFails <= 5:
                    print(f'  mod-q mismatch trial {t} Y[{k}]: '
                          f'actual={actual[k][t] % q}, ref={ref[k]}')

    boundFails = 0
    portCount = 0

    def _containment(ports) -> None:
        nonlocal boundFails, portCount
        for port in ports:
            signal = port.signal
            if signal is None or signal.values is None:
                continue
            portCount += len(signal.values)
            for value in signal.values:
                if value < signal.bound.minValue or value > signal.bound.maxValue:
                    boundFails += 1

    s = instance.scheme
    _containment(s.bank.outputPorts)
    _containment(s.transpose.outputPorts)
    for mult in s.mults:
        _containment(mult.outputPorts)
    for stage in (s.nttA, s.nttB):
        for layer in stage.butterflies:
            for butterfly in layer:
                _containment([butterfly.outputPortA, butterfly.outputPortB])
    # The operator's own output ports are deliberately not counted: they are a
    # repack of nttB's, inheriting the very same bound, so they would inflate the
    # total without testing anything the nttB walk above has not already tested.

    total = T * N
    if verbose:
        print(f'verifyFourStepNtt N={N} x {T} trial(s): '
              f'mod-q {total - modQFails}/{total}, '
              f'bound containment {portCount - boundFails}/{portCount}')
    return modQFails == 0 and boundFails == 0
