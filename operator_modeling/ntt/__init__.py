'''The NTT of the front end: the butterfly, the parts every architecture shares, and one folder per architecture.

    roots.py, twiddles.py     roots of unity and twiddle tables
    verification.py           reference transforms and checks
    memory.py                 resources of the generated RAMs

    butterfly/    the CT / GS butterfly and its schemes, and the unified butterfly
    pipelined/    one butterfly per position per layer, a fixed modulus (`FullyPipelinedNTT`)
    dataflow/     P points per cycle through log2(n) stages (`StreamingNTT`, `UnrolledNTT`)
    iterative/    B butterflies over banked memory (`IterativeNTT`)
    hybrid/       a block of unrolled stages used in a loop (`HybridNTT`)
    multistep/    N = s_1 x ... x s_d from sub-NTTs, transposes and twiddles (`MultiStepNTT`, `FourStepNTT`)

Every architecture has a scheme (the model: values, cycles, resources) and an operator (the RTL spec and
the emitted code). `operator_modeling/_compat.py` keeps the module names of the earlier layout importable.
'''
