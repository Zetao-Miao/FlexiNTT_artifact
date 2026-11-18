'''Trials for an operator whose modulus arrives on ports.

A trial is one modulus and one set of data values. The modulus comes first —
the family's extreme members during the corner half, then random members, most
of them prime — and the data corners are taken relative to that trial's q
(0, 1, q-1, q, 2q-1, ... clipped to the static bound), because "q - 1" means
nothing for a family. The static bounds still bound every value: the hardware
is built for the whole family, so any value inside them is a legal input for
any member.
'''
from __future__ import annotations


def sampleTrials(scheme, n: int, rng, corners: bool, family, portValues, dataPorts,
                 cornersFor, perTrial=None, relData=None, staticQ: bool = False) -> dict[str, list[int]]:
    '''`n` trials for `scheme`: `{port: [values]}` for the data ports and the
    modulus ports `portValues(q)` names. `cornersFor(port, q)` lists one data
    port's corners for modulus q; `perTrial(trial, q, rng)` may adjust a trial
    in place (a value that must be below the trial's q, a companion value).'''
    from ..core.IntType import IntType
    from ..core.OperatorScheme import sampleBound
    relData = relData or {}
    fc = family.corners()
    nc = max(1, n // 2) if corners else 0
    out: dict[str, list[int]] = {}
    # A quasi-static modulus holds one value for a whole job (a limb): one q per batch.
    qJob = (rng.choice(fc) if rng.random() < 0.5 else family.sample(rng, prime=True)) if staticQ else None
    for i in range(n):
        if qJob is not None:
            q = qJob
        elif i < nc and i < 4 * len(fc):
            q = fc[i % len(fc)]
        else:
            q = family.sample(rng, prime=rng.random() < 0.7)
        trial = dict(portValues(q))
        for p in dataPorts:
            b = getattr(scheme, scheme._boundAttr(p))
            r = relData.get(p)
            if r is not None:          # the operand's range for this trial's q
                lo, hi = r.atInt(q)
                lo, hi = max(lo, b.minValue), min(hi, b.maxValue)
                b = IntType(lo, hi, b.zeroLsbs) if lo < hi else IntType(lo, lo + 1)
            if i < nc:
                cand = [v for v in cornersFor(p, q) if b.minValue <= v <= b.maxValue]
                trial[p] = rng.choice(cand) if cand else sampleBound(b, 1, rng)[0]
            else:
                trial[p] = sampleBound(b, 1, rng)[0]
        if perTrial is not None:
            perTrial(trial, q, rng)
        for k, v in trial.items():
            out.setdefault(k, []).append(v)
    return out


class RuntimeComposite:
    '''Mixin for a modular operator that owns a reduction child (a modular
    multiplier, a butterfly) or a correction (an adder, Shoup): it gets its
    modulus ports from a probe child built for the same bounds, so the ports,
    their bounds and the per-trial modulus are the child's own.'''

    def _setFamily(self, name: str, q: int, family) -> None:
        from .ModulusFamily import ModulusFamily
        if family is None:
            family = ModulusFamily.fixed(q)
        elif q and not (family.kind == 'fixed' and family.qMax == q):
            raise ValueError(f'{name}: give q= or family=, not both')
        self.modulusFamily = family
        self.runtime = family.runtime
        self.q = None if self.runtime else family.qMax
        self._qspecs: dict = {}

    def _installPorts(self, dataNames: tuple, specs: dict) -> None:
        '''`specs`: {port: (bound, value(q))}. Data ports first, then the modulus ports.'''
        self._qspecs = dict(specs)
        self.inputNames = tuple(dataNames) + tuple(self._qspecs)
        for n, (b, _) in self._qspecs.items():
            setattr(self, self._boundAttr(n), b)
            setattr(self, self._valueAttr(n), None)

    def qPorts(self) -> tuple:
        return tuple(self._qspecs)

    def qPortValues(self, q: int) -> dict:
        if not self.modulusFamily.contains(q):
            raise ValueError(f'{self.name}: {q} is not in {self.modulusFamily.describe()}')
        return {n: fn(q) for n, (_, fn) in self._qspecs.items()}

    def qOfTrial(self, trial: dict) -> int:
        if not self.runtime:
            return self.q
        return self._qSource.qOfTrial(trial)

    def declareQPorts(self, dp) -> None:
        self.trackRelative(dp)
        src = getattr(self, '_qSource', None)
        for n, (b, _) in self._qspecs.items():
            if n not in dp.bounds:
                rel = src.qPortRel(n) if hasattr(src, 'qPortRel') else self._qPortRel(n)
                dp.input(n, b, rel=rel, static=getattr(self, 'staticModulus', False), shared=True)

    def _qPortRel(self, port: str):
        from ..core.relbound import Poly, Rel
        return Rel(Poly.q(), Poly.q()) if port == 'Q' else None

    def qMinMax(self) -> tuple:
        return self.modulusFamily.qMin, self.modulusFamily.qMax

    # --- bounds relative to the trial's q -------------------------------------

    def dataRel(self, port: str):
        '''An operand's bound relative to its trial's q: `inRange=` (k, or a
        {port: k} dict: [0, k*q - 1]; False: none), or read off a static bound
        [0, k*qMax - 1].'''
        if not self.runtime:
            return None
        from ..core.relbound import Poly, Rel
        from .ReductionScheme import relativeForm
        spec = getattr(self, 'inRange', None)
        if spec is False:
            return None
        k = spec.get(port) if isinstance(spec, dict) else spec
        if k is not None:
            return Rel(Poly.const(0), Poly.q(1, k) - Poly.const(1))
        return relativeForm(getattr(self, self._boundAttr(port)), self.qMinMax()[1])

    def trackRelative(self, dp) -> None:
        if self.runtime and dp.relq is None:
            qmin, qmax = self.qMinMax()
            ports = self.qPorts()
            dp.setRelative(qmin, qmax, lambda env, i: self.qOfTrial({p: env[p][i] for p in ports}))

    def relInput(self, dp, port: str) -> str:
        '''Declare a data port with its relative bound.'''
        self.trackRelative(dp)
        return dp.input(port, getattr(self, self._boundAttr(port)), rel=self.dataRel(port))

    def _correct(self, dp, name: str, src: str, step: int, qwireOf) -> str:
        '''A correction into [0, step*q): fixed q or the trial's q.'''
        b = dp.bound(src)
        if self.runtime:
            if b.minValue >= 0 and b.maxValue < step * self.qMinMax()[0]:
                return src
            return dp.qcorrect(name, src, qwireOf(dp), step=step)
        if b.minValue >= 0 and b.maxValue < step * self.q:
            return src
        return dp.correct(name, src, self.q, step=step)

    def sampleInputs(self, n: int, rng, corners: bool = True) -> dict:
        if not self.runtime:
            return super().sampleInputs(n, rng, corners)
        return sampleTrials(self, n, rng, corners, self.modulusFamily, self.qPortValues,
                            self.dataInputNames, self.cornersFor, getattr(self, '_perTrial', None),
                            relData={p: self.dataRel(p) for p in self.dataInputNames},
                            staticQ=getattr(self, 'staticModulus', False))

    def inputCorners(self, port: str) -> list:
        return self.cornersFor(port, self.q)

    def acceptsTrial(self, port: str, got: int, want: int, trial: dict) -> bool:
        return self.acceptsFor(port, got, want, self.qOfTrial(trial))

    def acceptsOutput(self, port: str, got: int, want: int) -> bool:
        return self.acceptsFor(port, got, want, self.q)
