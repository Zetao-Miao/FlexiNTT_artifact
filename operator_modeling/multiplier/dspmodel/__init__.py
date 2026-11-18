'''The DSP58 multiplier, modelled as the hardware the backend will build.

Four layers, bottom up:

  net.py         a pipelined netlist on `Signal`s — nodes, registers, depth
                 bookkeeping — evaluated eagerly (untimed) or clocked, one
                 `step()` per edge, from one description.
  primitive.py   `DSP58Block` on that netlist, registers included. Mirrors
                 `versal_arith/rtl/dsp_multiplier/DSP58Block.sv`.
  tiles.py       the five tile netlists (SingleDSP, DSPChain, Karatsuba2x2,
                 Karatsuba3x3, ToomCook25), each mirroring its RTL generator,
                 every register read from that generator's own plan for the
                 latency the backend chose.
  walker.py      the backend IR (`build_ir`'s op list) built into a netlist,
                 with the tiles above inside it; `walk()` untimed, `BeatModel`
                 clocked from the lowered module.

The rule every layer follows: **a `Signal` goes through the operations the
hardware performs, and a register sits wherever the backend put one.** A wire
carries its mathematically true value and its `IntType` bound, computed in
lockstep; every place the RTL truncates or reinterprets bits deliberately
becomes an assertion here; every merge is refused unless its inputs sit at
the same pipeline depth. Nothing is short-circuited to `a * b`, and nothing
decides a register count — those come from `lower()`'s module and from
`exact_dsp_config` through the generators' `*_plan` functions.
'''
