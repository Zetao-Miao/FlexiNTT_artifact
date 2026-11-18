"""A register-wrapped evaluation harness for any generated LUT module, so a
design can be implemented (not just synthesized out of context) and its
register-to-register timing read off a real placed-and-routed netlist.

The shape is the one the DSP flow's `emit_hweval` uses in its LFSR form, made
generic over the port list:

    LFSR  ->  input registers  ->  DUT  ->  output registers  ->  XOR-reduce  ->  out

Only clk, resetn, a 16-bit LFSR seed and one output bit leave the chip, so a
wide multiplier or a whole compressor tree needs no pin budget and no I/O
constraints. The input registers put a real flop in front of the DUT's first
stage (ENTRY in the timing model is a flop's clk->Q plus one hop), the output
registers close its last stage the same way, and the XOR reduction sits in a
stage of its own so it never lands on the path being measured.

Ports are read straight off the generated module's header, which every
generator in `rtl_gen` writes in the same shape:

    input  logic [63 : 0] A,
    input  logic          clk,
    output logic [127:0]  P

so the same harness fits a Booth multiplier (A, B -> P), a compressor tree
(in_col<k> -> comp_out), a constant multiplier (A -> P), a butterfly (aIn, bIn
-> aOut, bOut) or a bank (A_<i> -> P_<i>).
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

_PORT_RE = re.compile(
    r'^\s*(input|output)\s+logic\s+(signed\s+)?'
    r'(?:\[\s*(\d+)\s*:\s*0\s*\]\s*)?(\w+)\s*[,)]?\s*$',
    re.M,
)


@dataclass(frozen=True)
class Port:
    direction: str      # 'input' | 'output'
    name: str
    width: int
    signed: bool = False


def parse_module_ports(sv: str, module: str) -> list[Port]:
    """The ports of `module` in `sv`, in declaration order, from its header."""
    m = re.search(rf'\bmodule\s+{re.escape(module)}\s*\((.*?)\)\s*;', sv, re.S)
    if not m:
        raise ValueError(f"module {module} not found")
    ports = []
    for line in m.group(1).splitlines():
        pm = _PORT_RE.match(line + ('' if line.rstrip().endswith((',', ')')) else ','))
        if pm:
            direction, signed, hi, name = pm.groups()
            ports.append(Port(direction, name, int(hi) + 1 if hi else 1, bool(signed)))
    if not ports:
        raise ValueError(f"no ports parsed for module {module}")
    return ports


def emit_lfsr_harness(top: str, ports: list[Port], *, clock: str = 'clk') -> str:
    """The harness module `<top>_hweval` around `top`."""
    ins = [p for p in ports if p.direction == 'input' and p.name != clock]
    outs = [p for p in ports if p.direction == 'output']
    if not ins or not outs:
        raise ValueError(f"{top}: need at least one data input and one output")
    if not any(p.name == clock for p in ports):
        raise ValueError(f"{top}: no clock port named {clock!r}")
    in_w = sum(p.width for p in ins)
    out_w = sum(p.width for p in outs)
    lfsr_w = max(in_w, 32)   # the LFSR's taps reach bit 15

    def decl(p: Port, suffix: str) -> str:
        rng = f"[{p.width - 1}:0] " if p.width > 1 else ""
        return f"    logic {rng}{p.name}{suffix};"

    lines = ["`timescale 1ns / 1ps", "",
             f"// Evaluation harness for {top}: LFSR stimulus -> input registers -> DUT",
             f"// -> output registers -> XOR reduction. {in_w} input bits, {out_w} output bits.",
             f"module {top}_hweval (",
             "    input  logic        clk,",
             "    input  logic        resetn,",
             "    input  logic [15:0] in_init,",
             "    output logic        out",
             ");", "",
             f"    logic [{lfsr_w - 1}:0] stim;",
             f"    LFSR #(.OUT_WIDTH({lfsr_w})) u_lfsr (",
             "        .clk(clk), .resetn(resetn), .in_init(in_init), .out(stim)",
             "    );", "",
             "    // ---- input registers ----"]
    lines += [decl(p, "_reg") for p in ins]
    lines += ["    always_ff @(posedge clk) begin"]
    lo = 0
    for p in ins:
        hi = lo + p.width - 1
        lines.append(f"        {p.name}_reg <= stim[{hi}:{lo}];")
        lo = hi + 1
    lines += ["    end", "", "    // ---- DUT ----"]
    lines += [decl(p, "_dut") for p in outs]
    conns = [f".{clock}(clk)"] + [f".{p.name}({p.name}_reg)" for p in ins] + \
            [f".{p.name}({p.name}_dut)" for p in outs]
    lines += [f'    (* keep_hierarchy = "yes" *) {top} dut (',
              "        " + ",\n        ".join(conns),
              "    );", "",
              "    // ---- output registers, then the reduction in its own stage ----"]
    lines += [decl(p, "_reg") for p in outs]
    lines += ["    always_ff @(posedge clk) begin"]
    lines += [f"        {p.name}_reg <= {p.name}_dut;" for p in outs]
    lines += ["    end",
              "    always_ff @(posedge clk) out <= ^{" + ", ".join(f"{p.name}_reg" for p in outs) + "};",
              "", "endmodule", ""]
    return "\n".join(lines)


def write_hweval(run_dir: str | Path, top: str, clock_period_ns: float, *,
                 sv_name: str | None = None) -> dict[str, Path]:
    """Write `<run_dir>/hweval/<top>_hweval.sv` and its clock constraint,
    reading the DUT's ports from `<run_dir>/RTL_generated/<sv_name or top>.sv`.
    Returns the paths."""
    run_dir = Path(run_dir)
    src = run_dir / "RTL_generated" / f"{sv_name or top}.sv"
    ports = parse_module_ports(src.read_text(encoding="utf-8"), top)
    out = run_dir / "hweval"
    out.mkdir(parents=True, exist_ok=True)
    sv = out / f"{top}_hweval.sv"
    sv.write_text(emit_lfsr_harness(top, ports), encoding="utf-8")
    xdc = out / f"{top}_hweval.xdc"
    xdc.write_text(f"create_clock -period {clock_period_ns:.3f} -name clk [get_ports clk]\n",
                   encoding="utf-8")
    return {"sv": sv, "xdc": xdc, "ports": ports}
