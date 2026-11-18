# FlexiNTT

FlexiNTT is a framework that explores the design space of number theoretic transform (NTT) cores for AMD Versal
FPGAs and generates the RTL of the selected core. It covers four architectures (iterative, hybrid, dataflow and
multi-step), run-time moduli, a change of modulus and direction per polynomial, and the mapping of the modular
arithmetic to DSPs and LUTs.

This repository contains the complete framework and generator, the source files of every FlexiNTT design evaluated
in the paper, and the scripts that regenerate them.

## Contents

1. Project structure
2. Requirements
3. Quick start
4. Using the framework (design-space exploration)
5. Using the generator
6. Design examples of the paper
7. Reproducing the design examples
8. Simulation and implementation

## 1. Project structure

    README.md                  this file
    LICENSE
    environment.yml            conda environment (Python 3.12, SageMath)
    quickstart.sh              explore one request and generate one core
    userNTTinput.toml          request file for the exploration, with comments on every field
    runDse.py                  design-space exploration (the framework entry point)
    generate_core.py           RTL and testbench of one core found by the exploration
    runFramework.py            checks of the building blocks (multipliers, reductions, butterflies)
    runModularNTT.py           iterative and dataflow NTT generators (direct use)
    runUnrolledNTT.py          dataflow NTT generator, further options
    runHybridNTT.py            hybrid NTT generator (direct use)
    runMultiStep*.py           multi-step NTT generator (direct use), options and resource model
    runModMult.py              modular multipliers (Barrett, Montgomery, word-level Montgomery, Shoup, ...)
    runDspMultiplier.py        integer multipliers on DSPs and LUTs (tiling, Karatsuba)
    runButterfly.py            butterfly units
    runLutTiming.py            delay model of the LUT arithmetic
    runMatrixTranspose.py      transpose unit of the multi-step NTT
    runFormCounts.py           counts of moduli of a special form

    operator_modeling/         models: performance, resources, exploration
        dse/                   exploration: request, enumeration, pruning, Pareto front, adapters per architecture
        ntt/                   the four NTT architectures (iterative, hybrid, dataflow, multistep) and twiddles
        modmult/               modular reduction methods and modulus families
        multiplier/            integer multiplier models
        transpose/             transpose unit
        core/                  shared parts: DSP budget, datapath, pipeline stages

    versal_arith/              arithmetic and RTL back end
        rtl_gen/               RTL emitters (NTT cores, butterflies, memories, modulus slots)
        dsp_multiplier/        DSP58 tiling and Karatsuba multiplier design
        rtl/                   hand-written SystemVerilog primitives used by the generated cores
        sim_rtl_gen/           testbench emitters
        *.py                   compressor trees, LUT timing, specifications

    scripts/                   stand-alone builders of single components, simulation and synthesis launchers

    examples/
        case_study_request.toml    request of the case study in the paper
        paper_designs/             source files of the twenty FlexiNTT designs in the paper
        reproduce/                 scripts that regenerate these source files

## 2. Requirements

- Linux, Python 3.12 with SageMath and sympy. The file `environment.yml` creates such an environment.

      conda env create -f environment.yml
      conda activate flexintt
      pip install sympy

- Exploration and RTL generation need no FPGA tools.
- Simulation and implementation of the generated RTL need AMD Vivado 2025.1. The designs in the paper target the
  Alveo V80 (part xcv80-lsva4737-2MHP-e-S).

All commands below are run from the root of the repository.

## 3. Quick start

    bash quickstart.sh

The script explores the request in `userNTTinput.toml` (a 4096-point NTT with a 32-bit run-time modulus at 350 MHz)
and generates the RTL of the first core of the Pareto front. It takes about one minute. The results are in
`work/quickstart`.

    front.txt        the Pareto front
    feasible.txt     every core that meets the request
    result.json      all evaluated cores, machine readable
    <core name>/RTL_generated    RTL and testbench of the generated core

To generate another core of the result, give its name as printed in `front.txt`.

    bash quickstart.sh <core name>

## 4. Using the framework (design-space exploration)

Step 1. Write a request. Copy `userNTTinput.toml` or let the tool write a fresh template.

    python3 runDse.py --template my_request.toml

The request has five parts. Every field is explained by a comment in the file.

    [ntt]          transform size, moduli (fixed, chosen by the tool, or given at run time), cyclic or negacyclic,
                   direction, change of modulus and direction per polynomial
    [performance]  clock frequency, throughput target, latency limit
    [resources]    limits on LUTs, flip-flops, DSPs, block RAMs and UltraRAMs
    [bandwidth]    bits per cycle at the data ports, and the ways twiddles may reach the core from outside
    [search]       architectures to explore

Step 2. Run the exploration.

    python3 runDse.py my_request.toml --out work/my_run

An option on the command line overrides the file, for example `--max-dsp 400`. `python3 runDse.py --help` lists
all options. The exploration enumerates the candidate cores of the four architectures, prunes them, designs their
multipliers under the DSP limit, and evaluates each remaining candidate with the performance and resource models.
No synthesis is run.

Step 3. Read the result in `work/my_run`.

    front.txt       Pareto front of the cores that meet the request
    feasible.txt    all cores that meet the request
    result.json     all evaluated cores with their parameters and model values

Each line gives the architecture, the name of the core, its resources (LUT, FF, DSP, BRAM, UltraRAM), the cycles
per polynomial, the latency in cycles, the throughput and the bandwidth it needs for twiddles and moduli.

Step 4. Generate the selected core.

    python3 generate_core.py work/my_run/result.json <core name> work/my_core

The RTL and a self-checking testbench are written to `work/my_core/RTL_generated`. The file
`work/my_core/manifest.json` describes the ports, the latency and the interval of the core.

The case study of the paper uses the request `examples/case_study_request.toml`.

    python3 runDse.py examples/case_study_request.toml --out work/case_study

This exploration evaluates about 23,000 candidates and took about half an hour on our server.

## 5. Using the generator

The generator of each architecture can also be used without the exploration. The scripts in `examples/reproduce`
are short examples of such direct calls.

    gen_iterative.py    iterative NTT:   runModularNTT.iterative(...) and IterativeNTT(...).emitRtl(...)
    gen_dataflow.py     dataflow NTT:    runModularNTT.stream(...) and StreamingNTT(...).emitRtl(...)
    gen_hybrid.py       hybrid NTT:      runHybridNTT.gate2(...)
    gen_multistep.py    multi-step NTT:  MultiStepNTT(scheme).emitRtl(...)

The parameter sets of the designs are listed in `examples/reproduce/helpers` (`iter_gen.py` for the iterative
cores, `k1_rows.py` and `paper_gen.py` for the dataflow cores, `rows.py` for the multi-step cores). A new design
is made by adding a row there or by calling the functions above with other arguments.

Single components can be generated and checked with the top-level scripts, for example

    python3 runFramework.py               checks of the building blocks (prints "all gates passed")
    python3 runModMult.py --list          the modular multipliers that can be generated
    python3 runModMult.py --help          options of the modular multiplier generator

## 6. Design examples of the paper

The folder `examples/paper_designs` holds one folder per FlexiNTT design in the paper. The names follow the tables
of the paper.

    table3_dataflow_n4096_q32_12bu        comparison table, dataflow, 2^12 points, 32 bits, 12 butterfly units
    table3_dataflow_n4096_q64_12bu        comparison table, dataflow, 2^12 points, 64 bits, 12 butterfly units
    table3_dataflow_n4096_q64_192bu       comparison table, dataflow, 2^12 points, 64 bits, 192 butterfly units
    table3_dataflow_n131072_q62           comparison table, dataflow, 2^17 points, 62 bits
    table3_iterative_n4096_q60_8bu        comparison table, iterative, 2^12 points, 60 bits, 8 butterfly units
    table3_iterative_n8192_q36_512bu      comparison table, iterative, 2^13 points, 36 bits, 512 butterfly units
    table3_iterative_n16384_q54_256bu     comparison table, iterative, 2^14 points, 54 bits, 256 butterfly units
    table3_iterative_n65536_q52_32bu      comparison table, iterative, 2^16 points, 52 bits, 32 butterfly units
    table3_iterative_n65536_q64_64bu      comparison table, iterative, 2^16 points, 64 bits, 64 butterfly units
    table3_iterative_n131072_q64_64bu     comparison table, iterative, 2^17 points, 64 bits, 64 butterfly units
    table3_hybrid_n4096_q30_24bu          comparison table, hybrid, 2^12 points, 30 bits, 24 butterfly units
    table3_multistep_n4096_q60_32pts      comparison table, multi-step, 2^12 points, 60 bits, 32 points per cycle
    table3_multistep_n4096_q32_64pts      comparison table, multi-step, 2^12 points, 32 bits, 64 points per cycle
    table3_multistep_n16384_q60_32pts     comparison table, multi-step, 2^14 points, 60 bits, 32 points per cycle
    table3_multistep_n65536_q60_32pts     comparison table, multi-step, 2^16 points, 60 bits, 32 points per cycle
    case_study_core_A ... case_study_core_E    the five cores of the case study

Each folder contains

    rtl/             the generated SystemVerilog of the core and its self-checking testbench (<top>_tb.sv)
    manifest.json    top module, ports, latency and interval
    model.json       values of the performance and resource models (where the generation script writes them)
    record.json      case study only: the core as found by the exploration, input of generate_core.py
    reports/         utilization and timing reports of the out-of-context place and route (Vivado 2025.1)

The generated cores also instantiate the primitives in `versal_arith/rtl`. The stimulus files of the testbenches
are not stored because of their size. They are written again when a design is regenerated.

## 7. Reproducing the design examples

    bash examples/reproduce/reproduce_all.sh

The script regenerates the twenty designs into `work/reproduce/<design>` and compares the generated RTL with
`examples/paper_designs/<design>/rtl`. It prints one line per design (IDENTICAL, DIFFERENT or FAILED) and a
summary. The testbench file `<top>_tb.sv` is left out of the comparison, because its stimulus depends on the
options of the generation run.

One design is reported as DIFFERENT. In `table3_dataflow_n131072_q62` the current generator adds the attribute
`dont_touch` to 12 register declarations of the top module. This change was made after the core in the paper was
built. The files are identical otherwise, and the stored files are the ones that were placed and routed.

A part of the designs can be selected by a word in the name.

    bash examples/reproduce/reproduce_all.sh iterative
    bash examples/reproduce/reproduce_all.sh case_study_core_A

The small designs take seconds. The large ones (2^16 and 2^17 points, the multi-step cores and the case study)
take several minutes each.

The five case-study cores are regenerated from their records with `generate_core.py`. The same records are found
again by the exploration of `examples/case_study_request.toml` (Section 4).

## 8. Simulation and implementation

Every generated core comes with a self-checking testbench `<top>_tb.sv`. It sends several polynomials with
changing modulus and direction, and compares every output word and its cycle with the model. It prints a line
that starts with `[tb]` and reports PASS or FAIL. To simulate with Vivado xsim, compile the files of
`RTL_generated` together with `versal_arith/rtl/*.sv` and Vivado's `glbl.v`, with the libraries `unisims_ver`,
`unimacro_ver`, `secureip` and `xpm`.

The area and clock numbers in the paper are from out-of-context place and route of the core alone with Vivado
2025.1 for the Alveo V80. The reports of these runs are in the `reports` folder of each design.

`scripts/run_remote_sim.py` and `scripts/run_remote_synth.py` launch simulation and synthesis of a generated run
on a machine with Vivado (`--server local` for the same machine). They expect a project folder with the layout
described at the top of each script.

## License

See `LICENSE`.
