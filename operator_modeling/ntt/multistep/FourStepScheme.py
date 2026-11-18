'''The four-step NTT scheme: five operators, one fixed order, one index split.

A transform of size `N = n*n` decomposed the Bailey way. With `t = t1 + n*t2`
on the input side and `k = k2 + n*k1` on the output side, the pipeline is

    bank -> nttA -> transpose -> interMults -> nttB

and every stage's meaning follows from where `t1` and `t2` sit at that moment:

    stage            lane axis    batch axis     what just happened
    ------------------------------------------------------------------
    bank in          t2           t1             x[t1 + n*t2] arrives
    nttA out         k2           t1             one dimension transformed
    transpose out    t1           k2             the corner turn
    interMults out   t1           k2             psi**(t1*(2*k2+1)) applied
    nttB out         k1           k2             the other dimension

**Only one corner turn, not the usual two.** The second dimension rides the
batch axis: `nttA` reaches `t2` on the lanes, the transpose moves `t1` there, and
`nttB` reaches it too. Nothing has to be turned back.

**The transpose is ahead of the multipliers, structurally.** Both positions are
legal -- a corner turn may cross an elementwise multiply, just not an NTT -- and
they are not equally priced. Ahead of the multipliers it stores `nttA`'s output
at 66 bits; behind them it stores the product at 130. The corner turn holds a
whole matrix either way, so the placement halves the largest single block in the
design. There is no flag for the other order because there is no reason to build
it; a variant that wanted it would be a sibling scheme, the way
`MatrixTransposeScheme` describes.

**The inter-stage twiddle is `psi**(t1*(2*k2+1))`, not `omega_N**(t1*k2)`.**
Expanded that is `psi**t1 * omega_N**(t1*k2)`: the pre-twist bank removes the
negacyclic twist along `t2` only -- its constants are `psi_2n**t2` -- and
`psi**t1` is the other dimension's share, which has nowhere else to go.
Substituting the textbook twiddle breaks the transform outright. It is also why
both sub-NTTs are plain **cyclic** and can share one `omega_n` twiddle grid.

Why one concrete class and no ABC
---------------------------------
`MatrixTransposeScheme` is an ABC because its subclasses vary an observable port
contract. Nothing here varies that way yet: the radix split, the multiplier
strategy and the sub-NTT twiddles are all constructor arguments, and the stage
order is fixed on purpose. An ABC with one subclass and no varying axis would be
speculative. When a second four-step architecture actually exists -- a radix that
is not square, or a design that folds the pre-twist into the first butterfly
layer -- that is when the base class is worth extracting.
'''
from __future__ import annotations

from ...core.IntType import IntType
from ...core.OperatorScheme import OperatorScheme
from ...multiplier.BankScheme import ConstMultBankScheme
from ...multiplier.ConstMultBank import ConstMultBank
from ...multiplier.Multiplier import Multiplier
from ...multiplier.MultiplierScheme import BehaviouralMult
from ..pipelined.FullyPipelinedNTT import FullyPipelinedNTT
from ...transpose.MatrixTranspose import MatrixTranspose
from ...transpose.MatrixTransposeScheme import BehaviouralMatrixTranspose


def defaultMultSchemeFactory(name: str, aIn: IntType, bIn: IntType):
    '''The inter-stage multiplier when the caller names none.

    `BehaviouralMult` models the arithmetic exactly and claims no
    implementation, which is what a four-step needs while its datapath is being
    sized. Pass your own factory to swap in a real one.
    '''
    return BehaviouralMult(name=name, aIn=aIn, bIn=bIn)


def defaultTransposeSchemeFactory(name: str, n: int, transposeLatency: int | None = None):
    '''The corner turn when the caller names none: the behavioural one, with
    the latency the caller declares. A factory returning
    `BarrelMemoryBarrelTranspose(name, n, n)` or
    `MemoryBarrelMemoryTranspose(name, n, n)` swaps in the hardware.
    '''
    return BehaviouralMatrixTranspose(name=name, rows=n, cols=n,
                                      assumedLatency=transposeLatency)


class FourStepScheme(OperatorScheme):
    '''Owns the five children of a four-step and the order they run in.

    `_BOUND_ATTRS` / `_VALUE_ATTRS` are empty for the reason `FullyPipelinedGrid`
    leaves them empty: the base class's checks assume one scalar `IntType` per
    named slot, and nothing here is one scalar. The payloads live on the
    children's ports, and the operator owns the ports that reach them.
    '''

    _BOUND_ATTRS = ()
    _VALUE_ATTRS = ()

    def __init__(self, name: str = 'Undefined FourStepScheme',
                 n: int = 0,
                 q: int = 0,
                 preTwistConstants=(),
                 subTwiddles=None,
                 interTwiddles=None,
                 inputBound: IntType | None = None,
                 interTwistBound: IntType | None = None,
                 butterflyType: str = 'GS',
                 multSchemeFactory=None,
                 transposeLatency: int | None = None,
                 transposeSchemeFactory=None,
                 targetFmaxMhz: float | None = None):
        super().__init__(name)
        #: Frequency in, cycles out, handed to the bank and both sub-NTTs. The
        #: corner turn and the inter-stage multipliers take their own knobs
        #: (`transposeSchemeFactory` / `transposeLatency`, `multSchemeFactory`).
        self.targetFmaxMhz = targetFmaxMhz
        if n <= 0 or n & (n - 1):
            raise ValueError(
                f'{name}: n must be a positive power of two, got {n}. A '
                f'four-step here is square, so the transform size is n*n.'
            )
        if q <= 0:
            raise ValueError(f'{name}: q must be a positive modulus, got {q}')
        if inputBound is None:
            raise ValueError(
                f'{name}: inputBound is required -- it is the bank\'s operand '
                f'width, and the whole datapath is sized from it'
            )
        if not isinstance(inputBound, IntType):
            raise TypeError(
                f'{name}: inputBound must be an IntType, got '
                f'{type(inputBound).__name__}'
            )

        preTwistConstants = list(preTwistConstants)
        if len(preTwistConstants) != n:
            raise ValueError(
                f'{name}: expected {n} pre-twist constants (one per lane t2), '
                f'got {len(preTwistConstants)}'
            )
        if subTwiddles is None:
            raise ValueError(f'{name}: subTwiddles is required')
        if interTwiddles is None:
            raise ValueError(f'{name}: interTwiddles is required')
        interTwiddles = [list(batch) for batch in interTwiddles]
        if len(interTwiddles) != n:
            raise ValueError(
                f'{name}: expected {n} inter-stage twiddle batches (one per '
                f'lane t1), got {len(interTwiddles)}'
            )
        for lane, batch in enumerate(interTwiddles):
            if len(batch) != n:
                raise ValueError(
                    f'{name}: inter-stage twiddle lane {lane} carries '
                    f'{len(batch)} values, expected exactly n={n} -- one per '
                    f'output index k2 of a single transform. Batches for more '
                    f'than one trial are built by tiling, not supplied.'
                )

        self.n = n
        self.q = q
        self.butterflyType = butterflyType
        self.inputBound = inputBound
        self.interTwistBound = (interTwistBound if interTwistBound is not None
                                else IntType.unsigned(max(q.bit_length(), 1)))
        # The bound is what the multipliers' B port is sized from, and the
        # twiddles are what actually travels it. Nothing downstream rechecks
        # that pairing: an undersized bound produces a narrower product bound,
        # every later stage is sized from that, and a value-carrying run then
        # lands outside its own predicted interval -- while a sizing-only run,
        # which has no values to catch it, reports confident nonsense all the
        # way to the output widths.
        lowest = min(min(batch) for batch in interTwiddles)
        highest = max(max(batch) for batch in interTwiddles)
        if lowest < self.interTwistBound.minValue or highest > self.interTwistBound.maxValue:
            raise ValueError(
                f'{name}: interTwistBound {self.interTwistBound} does not cover '
                f'the inter-stage twiddles, which span [{lowest}, {highest}]. '
                f'The bound sizes the multipliers\' B port, so a bound narrower '
                f'than the data silently undersizes every stage after it.'
            )
        #: One batch of n twiddles per lane; tiled to the trial count at compute.
        self.interTwiddles = interTwiddles

        # --- the children ------------------------------------------------
        self.bank = ConstMultBank(
            name=f'{name}_pre_twist_bank',
            scheme=ConstMultBankScheme(name=f'{name}_pre_twist_bank_scheme',
                                       constants=preTwistConstants,
                                       aIn=inputBound,
                                       sharedInput=False,
                                       targetFmaxMhz=targetFmaxMhz))
        self.nttA = FullyPipelinedNTT(name=f'{name}_ntt_a', n=n, q=q,
                                      butterflyType=self.butterflyType,
                                      twiddles=subTwiddles,
                                      targetFmaxMhz=targetFmaxMhz)
        if transposeSchemeFactory is None:
            transposeScheme = defaultTransposeSchemeFactory(
                f'{name}_transpose_scheme', n, transposeLatency)
        else:
            transposeScheme = transposeSchemeFactory(f'{name}_transpose_scheme', n)
        self.transpose = MatrixTranspose(name=f'{name}_transpose',
                                         scheme=transposeScheme)
        # The multiplier's constructor bounds are placeholders: Multiplier.compute
        # overwrites scheme.aIn / scheme.bIn from the port signals every call, the
        # same way ConstMultBank.compute does. Only a caller reaching past the
        # ports into the scheme would ever observe these.
        factory = multSchemeFactory or defaultMultSchemeFactory
        self.mults = [
            Multiplier(name=f'{name}_inter_mult_{j}',
                       scheme=factory(f'{name}_inter_mult_{j}_scheme',
                                      IntType(0, 0, 0), self.interTwistBound))
            for j in range(n)
        ]
        self.nttB = FullyPipelinedNTT(name=f'{name}_ntt_b', n=n, q=q,
                                      butterflyType=self.butterflyType,
                                      twiddles=subTwiddles,
                                      targetFmaxMhz=targetFmaxMhz)

        self._wireChildren()

    def _wireChildren(self) -> None:
        '''Connect the five stages once, at construction.

        Two of the three hops are whole-operator connects; the multiplier hop is
        a loop because 128 multipliers are 128 operators, which is exactly the
        limit `Operator.connectOutputsTo` documents.
        '''
        self.bank.connectOutputsTo(self.nttA)
        self.nttA.connectOutputsTo(self.transpose)
        for j, mult in enumerate(self.mults):
            self.transpose.outputPorts[j].connect(mult.inputPortA)
            mult.outputPortP.connect(self.nttB.inputPorts[j])

    # ------------------------------------------------------------------
    # The index split
    # ------------------------------------------------------------------

    @property
    def N(self) -> int:
        '''Transform size.'''
        return self.n * self.n

    def inputNaturalToLane(self, i: int) -> tuple[int, int]:
        '''Natural input index -> `(lane, offset)`, where `i = offset + n*lane`.

        Lane `t2` is the spatial index: it selects which contiguous block of n
        coefficients this wire carries, and therefore which pre-twist constant
        applies. Offset `t1` selects the element inside that block and rides the
        batch axis.
        '''
        return divmod(i, self.n)

    def outputNaturalToLane(self, k: int) -> tuple[int, int]:
        '''Natural output index -> `(lane, offset)`, where `k = offset + n*lane`.

        Arithmetically identical to `inputNaturalToLane`, and kept separate
        because the two mean different things: here the lane is `k1`, the
        frequency `nttB` resolves, and the offset is `k2`, the frequency `nttA`
        resolved and the corner turn parked on the batch axis.
        '''
        return divmod(k, self.n)

    def internalSlot(self, trial: int, offset: int) -> int:
        '''Where trial `trial`'s element `offset` sits on the internal batch axis.

        `trial*n + offset` is exactly the `b = t*rows + r` that
        `MatrixTransposeScheme` requires, so the trial axis and the corner turn's
        matrix stacking are the same axis read two ways, with nothing left over.
        '''
        return trial * self.n + offset

    def tiledTwiddles(self, trials: int) -> list[list[int]]:
        '''The per-lane twiddle batches stretched to `trials` transforms.

        Slot `t*n + k2` needs the twiddle for `k2`, so the stored length-n batch
        repeats once per trial. **Tiled, not trimmed** -- trimming is what a
        single-transform harness can get away with, and it silently drops every
        trial after the first.
        '''
        if trials < 1:
            raise ValueError(
                f'{self.name}.tiledTwiddles: trials must be >= 1, got {trials}'
            )
        return [batch * trials for batch in self.interTwiddles]

    # ------------------------------------------------------------------
    # OperatorScheme surface
    # ------------------------------------------------------------------
    #
    # A four-step is a network, so its bound and value paths are both the same
    # network traversal -- identical bodies, exactly as on FullyPipelinedGrid.
    # A Signal carries bound and values together and every child computes both
    # in one call, so running the chain twice would be duplicated work, and
    # running the value path alone would slice at widths the bound path had not
    # yet established.

    def propagateBound(self):
        self.runChain()

    def propagateValue(self):
        self.runChain()

    def runChain(self) -> None:
        '''Drive the five stages in order. Inputs must already be on the bank.'''
        self.bank.compute()
        self.nttA.compute()
        self.transpose.compute()
        for mult in self.mults:
            mult.compute()
        self.nttB.compute()

    def latency(self, pipelineStages: int = 1) -> int:
        '''Summed child latency; how much of it is derived depends on the
        children it was built with.

        The bank and the sub-NTTs report latencies they can defend. The
        multipliers report a number a caller handed them
        (`BehaviouralMult.assumedLatency`) unless a `multSchemeFactory` supplied
        real ones. The corner turn does the same by default
        (`BehaviouralMatrixTranspose.assumedLatency`) -- but a
        `transposeSchemeFactory` that installs `BarrelMemoryBarrelTranspose` or
        `MemoryBarrelMemoryTranspose` makes it **derived**, from the register
        plan the timing model places, and `runMatrixTranspose.py` gate 5
        exercises exactly that. The sum is only as good as whatever assumptions
        remain, and it does not include the corner turn's priming fill; see
        `MatrixTransposeScheme.primingBeats`.

        `pipelineStages` reaches every child unchanged. `0` is rejected by the
        default behavioural corner turn (a corner turn cannot be combinational);
        the hardware corner turns ignore the argument entirely.
        '''
        if pipelineStages < 0:
            raise ValueError(f'{self.name}: pipelineStages must be >= 0')
        # max over the multipliers, not mults[0]: they are one parallel stage, so
        # the stage costs the deepest lane, and a caller-supplied
        # multSchemeFactory may well not hand every lane the same scheme. This
        # is how ConstMultBankScheme.latency aggregates its entries too.
        return (self.bank.latency(pipelineStages)
                + self.nttA.latency(pipelineStages)
                + self.transpose.latency(pipelineStages)
                + max(mult.latency(pipelineStages) for mult in self.mults)
                + self.nttB.latency(pipelineStages))

    def areaCost(self) -> tuple[int, int]:
        raise NotImplementedError(
            f'{self.name}: a four-step built this way has no area, for three '
            f'separate reasons and not one. The inter-stage multipliers are '
            f'BehaviouralMult and raise; the corner turn raises unless a '
            f'hardware scheme was passed as transposeSchemeFactory, and a '
            f'(LUT, DSP) pair could not express its {self.n * self.n}-element '
            f'store in any case (see resources()); and GoldilocksSlice64.areaCost '
            f'is still a stub, so the sub-NTTs would contribute zero even if the '
            f'other two answered. Only the pre-twist bank has a real model. Swap '
            f'in implemented schemes before costing this design.'
        )

    def resources(self):
        '''The five children summed. Raises while any child cannot answer, for
        the reasons `areaCost()` lists; with a hardware corner turn the
        transpose's BRAM tiles are counted where `(LUT, DSP)` could not.'''
        total = self.bank.resources()
        total = total + self.nttA.resources()
        total = total + self.transpose.resources()
        for mult in self.mults:
            total = total + mult.resources()
        return total + self.nttB.resources()

    def getOperatorInterface(self, name: str, pipelineStages: int = 1):
        raise NotImplementedError(
            f'{self.name}: there is no four_step_spec.py in versal_arith/, so '
            f'there is no spec dataclass to build. This scheme exists to '
            f'propagate bounds and values through a four-step decomposition and '
            f'to size what it holds, not to describe one to a generator. The '
            f'sub-NTTs can each still emit their own RTL individually.'
        )
