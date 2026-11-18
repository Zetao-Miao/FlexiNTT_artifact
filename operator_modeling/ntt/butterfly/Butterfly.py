from __future__ import annotations
from ...core.Port import Port, SimpleInputPort, SimpleOutputPort
from .ButterflyScheme import ButterflyScheme
from ...core.IntType import IntType


class Butterfly():
    def __init__(self, name: str = "Undefined Butterfly", butterflyType: str = "CT", scheme: ButterflyScheme | None = None, twiddle: int | list[tuple[int, int]] | Port | None = None):
        self.name: str = name
        self.butterflyType: str = butterflyType
        self.inputPortA: Port | None = SimpleInputPort(name=f'{name} Input Port A')
        self.inputPortB: Port | None = SimpleInputPort(name=f'{name} Input Port B')
        self.outputPortA: Port | None = SimpleOutputPort(name=f'{name} Output Port A')
        self.outputPortB: Port | None = SimpleOutputPort(name=f'{name} Output Port B')
        if isinstance(twiddle, Port):
            self.twiddlePort = twiddle
            self.twiddle = None
        elif isinstance(twiddle, int) or isinstance(twiddle, list):
            self.twiddlePort = None
            self.twiddle = twiddle
        elif twiddle is None:
            self.twiddlePort: Port | None = None
            self.twiddle: int | list[tuple[int, int]] | None = None
        else:
            raise TypeError(f"twiddle must be int, list[tuple[int, int]] (NAF) or Port, got {type(twiddle)} instead")
        self.scheme: ButterflyScheme | None = scheme
        #: inputs beyond A and B that the scheme declares (`scheme.portNames()`:
        #: twiddle W / WP and modulus Q / MU / QP / QH / K / C), one port each
        self.extraInputPorts: dict[str, SimpleInputPort] = {}

    # --- every port by name -----------------------------------------------------

    def portNames(self) -> tuple[str, ...]:
        '''The scheme's inputs beyond A and B (none for a Goldilocks butterfly).'''
        return tuple(self.scheme.portNames()) if hasattr(self.scheme, 'portNames') else ()

    def inputPort(self, name: str) -> Port:
        '''The input port `name`: 'A', 'B', or one of `portNames()` (made on first use).'''
        if name in ('A', 'a'):
            return self.inputPortA
        if name in ('B', 'b'):
            return self.inputPortB
        if name not in self.portNames():
            raise ValueError(f'{self.name}: no input {name}; the inputs are {["A", "B", *self.portNames()]}')
        if name not in self.extraInputPorts:
            self.extraInputPorts[name] = SimpleInputPort(name=f'{self.name} Input Port {name}')
        return self.extraInputPorts[name]

    def outputPort(self, name: str) -> Port:
        '''`X` (= output A) or `Y` (= output B).'''
        if name in ('X', 'A', 'a'):
            return self.outputPortA
        if name in ('Y', 'B', 'b'):
            return self.outputPortB
        raise ValueError(f'{self.name}: no output {name}; the outputs are X (A) and Y (B)')

    def inputPorts(self) -> dict:
        return {n: self.inputPort(n) for n in ('A', 'B', *self.portNames())}

    def initializePort(self, name: str, value: IntType | list[int]) -> None:
        '''Drive one input with a bound or a batch of values (the twiddle and
        modulus inputs as `initializeInputs` drives A and B).'''
        port = self.inputPort(name)
        if isinstance(value, IntType):
            port.pull(value)
        elif isinstance(value, list) and all(isinstance(x, int) for x in value):
            port.testVector = value
        else:
            raise TypeError(f'{self.name}: input {name} takes an IntType or a list of int, got {type(value)}')


    def initializeInputs(self, inputA: IntType | list[int], inputB: IntType | list[int]) -> None:
        if isinstance(inputA, IntType) and isinstance(self.inputPortA, SimpleInputPort):
            self.inputPortA.pull(inputA)
        elif isinstance(inputA, list) and isinstance(self.inputPortA, SimpleInputPort):
            if not all(isinstance(x, int) for x in inputA):
                raise TypeError(f'all elements of inputA must be int when passing a test-vector batch')
            self.inputPortA.testVector = inputA
        else:
            raise TypeError(f'inputA must be either an IntType or a list of integers, but got {type(inputA)}')
        if isinstance(inputB, IntType) and isinstance(self.inputPortB, SimpleInputPort):
            self.inputPortB.pull(inputB)
        elif isinstance(inputB, list) and isinstance(self.inputPortB, SimpleInputPort):
            if not all(isinstance(x, int) for x in inputB):
                raise TypeError(f'all elements of inputB must be int when passing a test-vector batch')
            self.inputPortB.testVector = inputB
        else:
            raise TypeError(f'inputB must be either an IntType or a list of integers, but got {type(inputB)}')
        

    def connectInTo(self, connectATo: tuple[Butterfly, str], connectBTo: tuple[Butterfly, str]) -> None:
        if not isinstance(connectATo, tuple):
            raise TypeError(f"connectATo must be a tuple, got {type(connectATo)} instead")
        if not isinstance(connectBTo, tuple):
            raise TypeError(f"connectBTo must be a tuple, got {type(connectBTo)} instead")
        targetButterflyA, targetPortA = connectATo
        targetButterflyB, targetPortB = connectBTo
        if not isinstance(targetButterflyA, Butterfly) or not isinstance(targetPortA, str):
            raise TypeError(f"connectA shoud be (Butterfly, str), got ({type(targetButterflyA)}, {type(targetPortA)}) instead")
        if not isinstance(targetButterflyB, Butterfly) or not isinstance(targetPortB, str):
            raise TypeError(f"connectB shoud be (Butterfly, str), got ({type(targetButterflyB)}, {type(targetPortB)}) instead")
        if targetPortA == 'A' or targetPortA == 'a':
            self.inputPortA.connect(targetButterflyA.outputPortA)
        elif targetPortA == 'B' or targetPortA == 'b':
            self.inputPortA.connect(targetButterflyA.outputPortB)
        else:
            raise ValueError(f"the second element of connectATo must be either 'a', 'A', 'b' or 'B'")
        if targetPortB == 'A' or targetPortB == 'a':
            self.inputPortB.connect(targetButterflyB.outputPortA)
        elif targetPortB == 'B' or targetPortB == 'b':
            self.inputPortB.connect(targetButterflyB.outputPortB)
        else:
            raise ValueError(f"the second element of connectBTo must be either 'a', 'A', 'b' or 'B'")


    def latency(self, pipelineStages: int = 1) -> int:
        '''Registers between this butterfly's inputs and outputs, per its scheme.
        Requires the scheme to be populated (a computed grid is).'''
        if self.scheme is None:
            raise ValueError(f"{self.name}: no scheme assigned")
        return self.scheme.latency(pipelineStages)

    def compute(self) -> None:
        '''Run scheme on whichever input mode(s) are populated. If both inputPortA.bound and inputPortB.bound are set, run propagateBound() and write outputPort.bound. If both inputPortA.testVector and inputPortB.testVector are set, run propagateValue() and write outputPort.testVector. Both can run in the same call when both modes are populated.'''
        if self.scheme is None:
            raise ValueError(f"{self.name}: no scheme assigned")
        aBound = self.inputPortA.bound
        bBound = self.inputPortB.bound
        aVec = self.inputPortA.testVector
        bVec = self.inputPortB.testVector

        boundReady = aBound is not None and bBound is not None
        valueReady = aVec is not None and bVec is not None

        if not boundReady and not valueReady:
            raise ValueError(f"{self.name}: both input ports must have either bound or testVector populated before compute")

        twiddleInput = getattr(self.scheme, 'twiddleInput', False)
        if self.twiddle is not None and not twiddleInput:
            self.scheme.twiddle = self.twiddle
        elif self.twiddlePort is not None and not twiddleInput:
            self.scheme.twiddle = self.twiddlePort.bound
        elif not twiddleInput:
            raise ValueError(f"{self.name}: cannot compute scheme as it has no twiddle value or port available")
        for p in self.portNames():
            # the twiddle as an input: a port given at construction serves as W
            port = self.twiddlePort if (p == 'W' and self.twiddlePort is not None) else self.inputPort(p)
            if port.bound is not None:
                self.scheme.portBounds[p] = port.bound
            if port.testVector is not None:
                self.scheme.portValues[p] = port.testVector
            elif valueReady:
                raise ValueError(f"{self.name}: input {p} carries no values while A and B do")

        if boundReady:
            self.scheme.aIn = aBound
            self.scheme.bIn = bBound
            aOutBound, bOutBound = self.scheme.propagateBound()
            self.outputPortA.bound = aOutBound
            self.outputPortB.bound = bOutBound

        if valueReady:
            # The bounds stay in aIn/bIn; the batches go to their own slots. The
            # value path reads its slicing width straight off those bounds, so
            # there is no width to hand across and no ordering dependency between
            # the two paths beyond both needing the bounds present.
            self.scheme.aIn = aBound
            self.scheme.bIn = bBound
            self.scheme.aInValues = aVec
            self.scheme.bInValues = bVec
            aOutVec, bOutVec = self.scheme.propagateValue()
            self.outputPortA.testVector = aOutVec
            self.outputPortB.testVector = bOutVec

        if self.outputPortA.isConnected:
            self.outputPortA.push()
        if self.outputPortB.isConnected:
            self.outputPortB.push()