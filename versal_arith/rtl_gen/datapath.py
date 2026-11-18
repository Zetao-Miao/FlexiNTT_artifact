"""Spec-driven datapath generator: one `DatapathSpec` -> SystemVerilog, XDC,
testbench, test vectors and a manifest.

The spec (`datapath_spec.py`) is a netlist of heaps, multipliers, tables,
OR-reductions and corrections with the registers already decided by the model
(`operator_modeling.core.datapath`). This generator decides nothing: it builds
each node as described, inserts the balancing delays the schedule lists, and
checks that what it built has the latency the spec promises.

Per node kind:

  heap      wires (no column taller than one bit), a two-operand `+` (no
            column taller than two; `compressor_RTL_gen` refuses those), or a
            compressor tree with the register flags in the spec. The heap is
            built by the same `buildHeapDescriptors` the butterfly and the
            constant multipliers use, so a heap computes its terms' sum modulo
            2^W exactly as the model's value path does.
  mult      a sub-module the operator generated beforehand (`submodules`):
            a `dspmult` design or a Booth multiplier, whose module names are
            prefixed with the top's name so two of them never collide; or, in
            the behavioural backend and for `backend='behavioural'`, `*`.
  table     `always_comb case` over the index bits (one LUT6 per output bit
            for six index bits or fewer).
  nonzero   `|src[hi:lo]`.
  correct   one subtractor per candidate, in parallel, and a priority select
            on their sign bits.
  qcorrect  the same with the modulus at run time: each candidate subtracts the
            k*q wire the model built from the q port.

`behavioural=True` (the `sim_rtl_gen.datapath` backend) writes every heap as a
`+`/`-` expression and every multiplier as `*`, with the same registers, for
fast functional simulation; test vectors are identical.

Files (relative to the cwd, like every generator here):
  RTL_generated/<name>.sv, <name>_<node>_cmp.sv, prefixed sub-modules, <name>_tb.sv
  xdc_generated/<name>_<node>_cmp.xdc (compressors), <name>_clock.xdc
  testvectors/<port>.txt
  manifest.json
"""
from __future__ import annotations

import glob
import json
import os
import re
import shutil

from datapath_spec import DatapathSpec, DpNode, DpWire
from rtl_gen.utils import merge_bit_assigns, rtl_static_issues, tb_settle_delay, to_twos_complement_hex

_RTL_DIR = "RTL_generated"
_XDC_DIR = "xdc_generated"
_TV_DIR = "testvectors"
_GPC_NAMES = {"c3_2", "c6_3", "c9_41", "c15_3", "c39_231", "c223_4", "c413_341", "c517_451"}


def _decl(w: DpWire | int, name: str) -> str:
    width = w if isinstance(w, int) else w.bitWidth
    return f"    logic [{width - 1}:0] {name};\n"


def _bit_expr(sig, idx, neg: bool, cnst: bool) -> str:
    if cnst:
        return "1'b1"
    if sig is None:
        return "1'b0"
    e = f"{sig}[{idx}]" if idx is not None and idx != -1 else sig
    return f"~{e}" if neg else e


def _ext(expr: str, w: int, signed: bool, to: int) -> str:
    """`expr` (w bits) sign- or zero-extended to `to` bits."""
    if to == w:
        return expr
    if to < w:
        return f"{expr}[{to - 1}:0]"
    m = re.fullmatch(r"(\w+)\[(\d+):(\d+)\]", expr)
    msb = f"{m.group(1)}[{m.group(2)}]" if m else f"{expr}[{w - 1}]"   # a part-select takes no second index
    fill = msb if signed else "1'b0"
    return f"{{{{{to - w}{{{fill}}}}}, {expr}}}"


def _reg_chain(out: str, comb: str, width: int, stages: int, keepLast: bool = False, keepFirst: bool = False) -> str:
    """`out` = `comb` delayed by `stages` registers (0: a wire). `keepLast`: the chain's source
    has the same value in every instance (a per-frame modulus constant), so synthesis would merge
    the chains of all instances into one whose last register then drives every instance across
    the die; the last register is kept per instance as a flip-flop (no equivalent-register removal,
    no SRL), so it sits next to its own consumer."""
    if stages == 0:
        return f"    assign {out} = {comb};\n"
    s = ""
    for i in range(stages):
        # keepFirst: the first register too, so the shared source reaches a flip-flop of this instance and the
        # shift register in the middle is fed from next to it (2026-11-16: without it the first registers of
        # all instances merged into one, which then drove every instance's shift register across the die)
        keep = '(* equivalent_register_removal = "no", shreg_extract = "no" *) ' \
            if (keepLast and i == stages - 1) or (keepFirst and i == 0) else ""
        s += f"    {keep}logic [{width - 1}:0] {out}_r{i};\n"
    s += "    always_ff @(posedge clk) begin\n"
    s += f"        {out}_r0 <= {comb};\n"
    for i in range(1, stages):
        s += f"        {out}_r{i} <= {out}_r{i - 1};\n"
    s += "    end\n"
    s += f"    assign {out} = {out}_r{stages - 1};\n"
    return s


# ---------------------------------------------------------------------------
# heap
# ---------------------------------------------------------------------------

def _heap_rows(adesc: list, width: int) -> list[list[str]]:
    """Columns -> rows of bit expressions (row r takes each column's r-th bit)."""
    col_map = {e[0]: e[1:] for e in adesc}
    height = max((len(v) for v in col_map.values()), default=0)
    rows = []
    for r in range(height):
        bits = []
        for col in range(width - 1, -1, -1):
            cbits = col_map.get(col, [])
            if len(cbits) > r:
                sig, idx, neg, cnst = cbits[r]
                bits.append(_bit_expr(sig, idx, neg, cnst))
            else:
                bits.append("1'b0")
        rows.append(bits)
    return rows


def _emit_heap(spec: DatapathSpec, node: DpNode, behavioural: bool, visualization: bool,
               write_xdc: bool) -> tuple[str, list[str], int]:
    from rtl_gen.heap_terms import bitAssign, buildHeapDescriptors, countCompressionLayers, inputKinds
    from rtl_gen.compressor import compressor_RTL_gen

    out, W = node.out.name, node.out.bitWidth
    cdesc, adesc, heights, wbh = buildHeapDescriptors(list(node.terms), W, "")
    if not heights:
        return f"    assign {out} = '0;\n", [], 0
    height = max(len(e) - 1 for e in adesc)
    body = f"    // heap {out}: {len(node.terms)} terms, max column height {height}{'  ' + node.note if node.note else ''}\n"
    if behavioural:
        body += f"    logic [{W - 1}:0] {out}_sum;\n"
        body += f"    assign {out}_sum = {_behavioural_sum(spec, node)};\n"
        body += _reg_chain(out, f"{out}_sum", W, node.stages)
        return body, [], node.stages
    if height <= 2:
        rows = _heap_rows(adesc, W)
        expr = []
        for r, bits in enumerate(rows):
            body += f"    logic [{W - 1}:0] {out}_op{r};\n"
            body += f"    assign {out}_op{r} = {{{', '.join(bits)}}};\n"
            expr.append(f"{out}_op{r}")
        want = 0 if height <= 1 else node.stages
        if height <= 1 and node.stages:
            raise ValueError(f"{spec.name}.{out}: a wiring heap has no unit to register")
        if len(node.regFlags) not in (0, 1) or (height == 2 and len(node.regFlags) != 1):
            raise AssertionError(f"{spec.name}.{out}: adder heap with {len(node.regFlags)} flags")
        body += _reg_chain(out, " + ".join(expr), W, want)
        return body, [], want
    # compressor tree
    n_layers, _, _ = countCompressionLayers(heights, wbh)
    flags = list(node.regFlags)
    if len(flags) != n_layers:
        raise AssertionError(f"{spec.name}.{out}: the model placed {len(flags)} units, the "
                             f"generator builds {n_layers}; the heap analyses disagree")
    mod = f"{spec.name}_{out}_cmp"
    txt = f"{mod}_bitheap.txt"
    with open(txt, "w", encoding="utf-8") as f:
        f.write("".join(f"{v}\n" for v in heights))
    compressor_RTL_gen(txt_file_name=txt, sv_file_name=mod, compressor_module_name=mod,
                       tb_out_width=W, reg_flag_list=flags, visualization=visualization,
                       gen_testbench=False, test_size=0, bitheap_desc=cdesc,
                       input_kinds=inputKinds(adesc), write_xdc=write_xdc)
    os.remove(txt)
    for e in cdesc:
        n = len(e) - 1
        body += (f"    logic [{n - 1}:0] {out}_col{e[0]};\n" if n > 1
                 else f"    logic {out}_col{e[0]};\n")
    for e in adesc:
        bits = e[1:]
        for bi, (sig, idx, neg, cnst) in enumerate(bits):
            lhs = f"{out}_col{e[0]}" if len(bits) == 1 else f"{out}_col{e[0]}[{bi}]"
            body += bitAssign(lhs, sig, idx, neg, cnst, pushed=True)
    body += f"    logic [{wbh - 1}:0] {out}_cmp_out;\n"
    body += f"    {mod} u_{out}_cmp (\n        .clk(clk)"
    for e in cdesc:
        body += f",\n        .col{e[0]}({out}_col{e[0]})"
    body += f",\n        .comp_out({out}_cmp_out));\n"
    if wbh >= W:
        body += f"    assign {out} = {out}_cmp_out[{W - 1}:0];\n"
    else:
        body += f"    assign {out} = {{{W - wbh}'b0, {out}_cmp_out}};\n"
    return body, [mod], sum(flags)


def _behavioural_sum(spec: DatapathSpec, node: DpNode) -> str:
    """The heap's terms as one `+`/`-` expression of W-bit operands."""
    W = node.out.bitWidth
    parts = []
    for t in node.terms:
        if t.source == "const":
            v = (t.sign * t.constValue << t.limbShift) % (1 << W)
            parts.append(("+", f"{W}'d{v}"))
            continue
        src = spec.wire(t.source)
        hi = min(t.sliceEnd, src.bitWidth - 1)
        sl = f"{t.source}[{hi}:{t.sliceStart}]"
        sw = hi - t.sliceStart + 1
        ext = _ext(sl, sw, t.isSigned, max(W, sw))
        if t.limbShift >= W:
            continue
        shifted = f"({ext} << {t.limbShift})" if t.limbShift else ext
        parts.append(("+" if t.sign == 1 else "-", f"{W}'({shifted})"))
    if not parts:
        return f"{W}'d0"
    s = ("" if parts[0][0] == "+" else "-") + parts[0][1]
    for op, p in parts[1:]:
        s += f" {op} {p}"
    return s


# ---------------------------------------------------------------------------
# mult, table, nonzero, correct
# ---------------------------------------------------------------------------

def _operand(spec: DatapathSpec, name: str | None, const: int | None, width: int,
             signed_target: bool) -> str:
    if name:
        w = spec.wire(name)
        return _ext(name, w.bitWidth, w.isSigned, width)
    return f"{width}'d{const}"


def _emit_mult(spec: DatapathSpec, node: DpNode, sub: dict | None, behavioural: bool) -> str:
    out, W = node.out.name, node.out.bitWidth
    a = spec.wire(node.a)
    if behavioural or node.backend == "behavioural":
        # Both operands extended to the product's width W: the product of the
        # extended operands, modulo 2^W, is the true product (two's complement).
        # Extending first matters: a `*` is only as wide as its widest operand.
        bw = spec.wire(node.b) if node.b else None
        ea = _ext(node.a, a.bitWidth, a.isSigned, W)
        eb = _ext(node.b, bw.bitWidth, bw.isSigned, W) if bw is not None else f"{W}'d{node.bConst}"
        stages = node.stages
        body = f"    logic [{W - 1}:0] {out}_prod;\n"
        body += f"    assign {out}_prod = {ea} * {eb};\n"
        body += _reg_chain(out, f"{out}_prod", W, stages)
        return body
    if sub is None:
        raise ValueError(f"{spec.name}.{out}: no generated sub-module for a {node.backend} multiplier")
    if sub["latency"] != node.stages:
        raise AssertionError(f"{spec.name}.{out}: the {node.backend} sub-module has latency "
                             f"{sub['latency']}, the schedule says {node.stages}")
    wa, wb, wp = sub["widthA"], sub["widthB"], sub["widthP"]
    body = f"    logic [{wp - 1}:0] {out}_p;\n"
    ea = _operand(spec, node.a, None, wa, True)
    eb = _operand(spec, node.b or None, node.bConst, wb, True)
    ports = f".clk(clk), .A({ea}), .B({eb}), .P({out}_p)"
    if sub.get("reset"):
        ports = ".reset(1'b0), " + ports
    body += f"    {sub['module']} u_{out} ({ports});\n"
    body += f"    assign {out} = {_ext(out + '_p', wp, node.out.isSigned, W)};\n"
    return body


def _emit_table(node: DpNode) -> str:
    out, W = node.out.name, node.out.bitWidth
    k = node.hi - node.lo + 1
    body = f"    logic [{W - 1}:0] {out}_lut;\n"
    body += "    always_comb begin\n"
    body += f"        case ({node.src}[{node.hi}:{node.lo}])\n"
    for i, v in enumerate(node.table):
        body += f"            {k}'d{i}: {out}_lut = {W}'d{v & ((1 << W) - 1)};\n"
    body += f"            default: {out}_lut = '0;\n        endcase\n    end\n"
    body += _reg_chain(out, f"{out}_lut", W, node.stages)
    return body


def _emit_select(spec: DatapathSpec, node: DpNode) -> str:
    out, W = node.out.name, node.out.bitWidth
    def side(nm):                       # an empty side is the constant 0 (the node is a gate)
        if not nm:
            return f"{W}'d0"
        w_ = spec.wire(nm)
        return _ext(nm, w_.bitWidth, w_.isSigned, W)
    comb = f"{node.src}[0] ? {side(node.a)} : {side(node.b)}"
    return _reg_chain(out, f"({comb})", W, node.stages)


def _emit_nonzero(node: DpNode) -> str:
    return _reg_chain(node.out.name, f"|{node.src}[{node.hi}:{node.lo}]", 1, node.stages)


def correct_width(spec: DatapathSpec, node: DpNode) -> int:
    src = spec.wire(node.src)
    qs = (node.qMin, node.qMax) if node.kind == "qcorrect" else (node.modulus,)
    lo = min([src.minValue] + [src.minValue - k * q for q in qs for k in (node.kLow, node.kHigh)])
    hi = max([src.maxValue] + [src.maxValue - k * q for q in qs for k in (node.kLow, node.kHigh)])
    neg = (-lo - 1).bit_length() if lo < 0 else 0
    pos = hi.bit_length() if hi > 0 else 0
    return max(neg, pos) + 1


def _emit_fold(spec: DatapathSpec, node: DpNode, m: str, mStatic: bool) -> str:
    """A two-candidate correction without a select. `m` is the expression of
    step*q at the correction's width (a constant or the |k|*q wire)."""
    out, W = node.out.name, node.out.bitWidth
    src = spec.wire(node.src)
    cw = correct_width(spec, node)
    x = _ext(node.src, src.bitWidth, src.isSigned, cw)
    body = f"    // {out}: folded correction ({node.fold}) of {node.src}, no select\n"
    body += f"    logic [{cw - 1}:0] {out}_x, {out}_m;\n    assign {out}_x = {x};\n    assign {out}_m = {m};\n"
    if node.fold == "sign":
        comb = f"{out}_x + ({out}_m & {{{cw}{{{out}_x[{cw - 1}]}}}})"
        body += f"    logic [{cw - 1}:0] {out}_y;\n    assign {out}_y = {comb};\n"
        body += _reg_chain(out, f"{out}_y[{W - 1}:0]", W, node.stages)
        return body
    flags = list(node.regFlags) if node.regFlags else [False, node.stages > 0]
    mid = bool(flags[0])
    body += f"    logic {out}_f;\n    assign {out}_f = ($signed({out}_x) >= $signed({out}_m));\n"
    xs, ms, fs = f"{out}_x", f"{out}_m", f"{out}_f"
    if mid:                     # the register between the compare and the subtraction
        body += f"    logic [{cw - 1}:0] {out}_xr;\n    logic {out}_fr;\n"
        regs = f"        {out}_xr <= {out}_x;\n        {out}_fr <= {out}_f;\n"
        xs, fs = f"{out}_xr", f"{out}_fr"
        if not mStatic:
            body += f"    logic [{cw - 1}:0] {out}_mr;\n"
            regs += f"        {out}_mr <= {out}_m;\n"
            ms = f"{out}_mr"
        body += "    always_ff @(posedge clk) begin\n" + regs + "    end\n"
    body += f"    logic [{cw - 1}:0] {out}_y;\n    assign {out}_y = {xs} - ({ms} & {{{cw}{{{fs}}}}});\n"
    body += _reg_chain(out, f"{out}_y[{W - 1}:0]", W, node.stages - (1 if mid else 0))
    return body


def _emit_correct(spec: DatapathSpec, node: DpNode) -> str:
    out, W = node.out.name, node.out.bitWidth
    src = spec.wire(node.src)
    cw = correct_width(spec, node)
    if node.fold:
        return _emit_fold(spec, node, f"{cw}'d{node.step * node.modulus}", True)
    ext = _ext(node.src, src.bitWidth, src.isSigned, cw)
    ks = list(range(node.kLow, node.kHigh + 1, node.step))
    body = f"    // correct {out}: {node.src} - k*q, k in {ks}, q = {node.modulus}\n"
    body += f"    logic [{cw - 1}:0] {out}_x;\n    assign {out}_x = {ext};\n"
    names = []
    for k in ks:
        c = f"{out}_c{'m' if k < 0 else ''}{abs(k)}"
        kq = k * node.modulus
        if kq == 0:
            rhs = f"{out}_x"
        elif kq > 0:
            rhs = f"{out}_x - {cw}'d{kq}"
        else:
            rhs = f"{out}_x + {cw}'d{-kq}"
        body += f"    logic [{cw - 1}:0] {c};\n    assign {c} = {rhs};\n"
        names.append(c)
    sel = f"{names[0]}[{W - 1}:0]"
    for c in names[1:]:
        sel = f"(!{c}[{cw - 1}]) ? {c}[{W - 1}:0] : ({sel})"
    body += _reg_chain(out, sel, W, node.stages)
    return body


def _emit_qcorrect(spec: DatapathSpec, node: DpNode) -> str:
    """`src - k*q` with q a run-time value: the candidates subtract the k*q
    wires the model built, the same priority select as `correct`."""
    out, W = node.out.name, node.out.bitWidth
    src = spec.wire(node.src)
    cw = correct_width(spec, node)
    ks = list(range(node.kLow, node.kHigh + 1, node.step))
    if len(ks) != len(node.qMults):
        raise ValueError(f"{spec.name}.{out}: {len(ks)} candidates, {len(node.qMults)} k*q wires")
    if node.fold:
        m = [w for w in node.qMults if w][0]
        mw = spec.wire(m)
        return _emit_fold(spec, node, _ext(m, mw.bitWidth, mw.isSigned, cw), m in set(spec.static))
    body = f"    // qcorrect {out}: {node.src} - k*q, k in {ks}, q from {node.qwire} in [{node.qMin}, {node.qMax}]\n"
    body += f"    logic [{cw - 1}:0] {out}_x;\n    assign {out}_x = {_ext(node.src, src.bitWidth, src.isSigned, cw)};\n"
    names = []
    for k, m in zip(ks, node.qMults):
        c = f"{out}_c{'m' if k < 0 else ''}{abs(k)}"
        if not m:
            rhs = f"{out}_x"
        else:                       # m is |k|*q: subtracted for k > 0, added for k < 0
            mw = spec.wire(m)
            rhs = f"{out}_x {'-' if k > 0 else '+'} {_ext(m, mw.bitWidth, mw.isSigned, cw)}"
        body += f"    logic [{cw - 1}:0] {c};\n    assign {c} = {rhs};\n"
        names.append(c)
    sel = f"{names[0]}[{W - 1}:0]"
    for c in names[1:]:
        sel = f"(!{c}[{cw - 1}]) ? {c}[{W - 1}:0] : ({sel})"
    body += _reg_chain(out, sel, W, node.stages)
    return body


# ---------------------------------------------------------------------------
# sub-modules: prefix every module a generated design defines
# ---------------------------------------------------------------------------

_MODULE_RE = re.compile(r"^\s*module\s+(\w+)", re.MULTILINE)


def import_submodule(src_files: list[str], prefix: str, top: str) -> tuple[str, list[str]]:
    """Copy `src_files` into RTL_generated/ with every module they define
    renamed `<prefix><name>` (GPC primitives excepted: those are shared from
    versal_arith/rtl/). Returns the renamed top and the written file names."""
    texts = {}
    defined = []
    for p in src_files:
        t = open(p, encoding="utf-8").read()
        texts[p] = t
        defined += [m for m in _MODULE_RE.findall(t) if m not in _GPC_NAMES]
    pat = re.compile(r"\b(" + "|".join(sorted(map(re.escape, set(defined)), key=len, reverse=True)) + r")\b") if defined else None
    written = []
    os.makedirs(_RTL_DIR, exist_ok=True)
    for p, t in texts.items():
        if pat is not None:
            t = pat.sub(lambda m: prefix + m.group(1), t)
        name = prefix + os.path.basename(p)
        with open(os.path.join(_RTL_DIR, name), "w", encoding="utf-8") as f:
            f.write(t)
        written.append(name)
    return prefix + top, written


# ---------------------------------------------------------------------------
# testbench
# ---------------------------------------------------------------------------

def _gen_testbench(spec: DatapathSpec, test_size: int) -> str:
    lat = spec.latency
    ins = [(w.name, w.bitWidth) for w in spec.inputs]
    outs = [(p, spec.wire(w).bitWidth) for p, w in spec.outputs]
    tb = f"""`timescale 1ns / 1ps

module {spec.name}_tb ();
    `define CLK_P         10
    `define CLK_HP        5
    `define TS_SIZE       {test_size}
    `define INIT_RESET    200

    logic clk;
    initial clk = 1'b0;
    always #`CLK_HP clk = ~clk;

"""
    for n, w in ins + outs:
        tb += f"    logic [{w - 1}:0] {n};\n    logic [{w - 1}:0] {n}_ts [`TS_SIZE-1:0];\n"
    tb += "\n    initial begin\n"
    for n, _ in ins + outs:
        tb += f'        $readmemh("../../../../../{_TV_DIR}/{n}.txt", {n}_ts);\n'
    tb += "    end\n\n"
    tb += f"    {spec.name} DUT (\n        .clk(clk)"
    for n, _ in ins + outs:
        tb += f",\n        .{n}({n})"
    tb += ");\n\n"
    tb += "    int i;\n    initial begin\n        #`INIT_RESET;\n        #`CLK_HP;\n        #1;\n"
    tb += "        for (i = 0; i < `TS_SIZE; i = i + 1) begin\n"
    for n, _ in ins:
        tb += f"            {n} = {n}_ts[i];\n"
    tb += "            #`CLK_P;\n        end\n    end\n\n"
    tb += "    int j;\n    int correct_cnt;\n    logic ok;\n    initial begin\n        correct_cnt = 0;\n"
    tb += f"        #`INIT_RESET;\n        #`CLK_HP;\n        #(`CLK_P*{lat});\n        #{tb_settle_delay(lat)};\n"
    tb += "        for (j = 0; j < `TS_SIZE; j = j + 1) begin\n            ok = 1'b1;\n"
    for n, _ in outs:
        tb += (f"            if ($isunknown({n}) || $isunknown({n}_ts[j]) || {n} !== {n}_ts[j]) begin\n"
               f"                ok = 1'b0;\n"
               f"                $display(\"Testvector-%0d WRONG on {n}: module %h reference %h\", j, {n}, {n}_ts[j]);\n"
               f"            end\n")
    tb += "            if (ok) correct_cnt = correct_cnt + 1;\n            #`CLK_P;\n        end\n"
    tb += """        if (correct_cnt == `TS_SIZE) begin
            $display("SUCCESS!");
            $display("PASS All %0d Testvectors!", `TS_SIZE);
        end else begin
            $display("TO BE DEBUGGED...");
            $display("FAILED: %0d out of %0d testvectors failed", (`TS_SIZE-correct_cnt), `TS_SIZE);
        end
        $finish();
    end

endmodule
"""
    return tb


# ---------------------------------------------------------------------------
# entry point
# ---------------------------------------------------------------------------

def Datapath_RTL_gen(spec: DatapathSpec, pipeline_stages=1, gen_testbench: bool = True,
                     visualization: bool = False, vectors: dict | None = None,
                     submodules: dict | None = None, behavioural: bool = False,
                     write_xdc: bool = True, clock_ns: float | None = None) -> dict:
    """Emit RTL for `spec` into the cwd. `vectors` maps every input and output
    port to its values (required with `gen_testbench`); `submodules` maps a
    `dsp` / `booth` multiplier node to `{files, top, latency, widthA, widthB,
    widthP, reset}` generated by the operator beforehand."""
    submodules = dict(submodules or {})
    os.makedirs(_RTL_DIR, exist_ok=True)
    for stale in glob.glob(os.path.join(_RTL_DIR, f"{spec.name}*.sv")):
        os.remove(stale)
    for stale in glob.glob(os.path.join(_XDC_DIR, f"{spec.name}*.xdc")):
        os.remove(stale)

    # sub-modules first: their renamed tops are what the wrapper instantiates
    subinfo = {}
    files_written = []
    for node in spec.nodes:
        if node.kind == "mult" and node.backend in ("dsp", "booth") and not behavioural:
            s = submodules.get(node.out.name)
            if s is None:
                raise ValueError(f"{spec.name}: node {node.out.name} needs a generated {node.backend} sub-module")
            top, written = import_submodule(s["files"], f"{spec.name}_{node.out.name}_", s["top"])
            files_written += written
            subinfo[node.out.name] = dict(s, module=top)

    body = ""
    compressors = []
    built = {}
    for node in spec.nodes:
        body += _decl(node.out, node.out.name)
    for d in spec.delays:
        body += _decl(d.bitWidth, d.name)
    body += "\n"
    for node in spec.nodes:
        if node.kind == "heap":
            text, mods, lat = _emit_heap(spec, node, behavioural, visualization, write_xdc)
            compressors += mods
        elif node.kind == "mult":
            text, lat = _emit_mult(spec, node, subinfo.get(node.out.name), behavioural), node.stages
        elif node.kind == "table":
            text, lat = _emit_table(node), node.stages
        elif node.kind == "nonzero":
            text, lat = _emit_nonzero(node), node.stages
        elif node.kind == "select":
            text, lat = _emit_select(spec, node), node.stages
        elif node.kind == "correct":
            text, lat = _emit_correct(spec, node), node.stages
        elif node.kind == "qcorrect":
            text, lat = _emit_qcorrect(spec, node), node.stages
        else:
            raise ValueError(f"{spec.name}: unknown node kind {node.kind!r}")
        if lat != node.stages:
            raise AssertionError(f"{spec.name}.{node.out.name}: built {lat} stages, spec says {node.stages}")
        built[node.out.name] = lat
        body += text + "\n"
    shared = set(spec.shared)
    # delays of a shared source (a per-polynomial modulus constant) are taps of ONE local delay line: the first
    # tap comes from the source through a kept first register, every later tap continues from the tap before
    taps: dict = {}
    for d in spec.delays:
        if d.src in shared and d.cycles > 0:
            taps.setdefault(d.src, []).append(d)
    prev_of = {}
    for src, ds in taps.items():
        ds = sorted(ds, key=lambda d: d.cycles)
        for i, d in enumerate(ds):
            prev_of[d.name] = (ds[i - 1].name, ds[i - 1].cycles) if i else None
    for d in spec.delays:
        if d.name in prev_of and prev_of[d.name] is not None:
            pn, pc = prev_of[d.name]
            body += _reg_chain(d.name, pn, d.bitWidth, d.cycles - pc, keepLast=True)
        elif d.name in prev_of:
            body += _reg_chain(d.name, d.src, d.bitWidth, d.cycles, keepLast=True, keepFirst=True)
        else:
            body += _reg_chain(d.name, d.src, d.bitWidth, d.cycles, keepLast=d.src in shared)

    # latency check: walk the schedule as built
    ready = {w.name: 0 for w in spec.inputs}
    delay_of = {d.name: d for d in spec.delays}

    def arrive(name):
        if name in ready:
            return ready[name]
        d = delay_of[name]
        return arrive(d.src) + d.cycles

    static = set(spec.static)
    for node in spec.nodes:
        starts = {arrive(i) for i in node.inputs if i not in static or node.out.name in static}
        if len(starts) > 1:
            raise AssertionError(f"{spec.name}.{node.out.name}: inputs arrive at cycles {sorted(starts)}")
        st = starts.pop() if starts else 0
        if st != node.start:
            raise AssertionError(f"{spec.name}.{node.out.name}: starts at {st}, spec says {node.start}")
        ready[node.out.name] = st + built[node.out.name]
    lats = {arrive(w) for _, w in spec.outputs}
    if lats != {spec.latency}:
        raise AssertionError(f"{spec.name}: outputs arrive at {sorted(lats)}, spec latency {spec.latency}")

    ports = ["    input  logic clk"]
    for w in spec.inputs:
        ports.append(f"    input  logic [{w.bitWidth - 1}:0] {w.name}")
    for p, w in spec.outputs:
        ports.append(f"    output logic [{spec.wire(w).bitWidth - 1}:0] {p}")
    rtl = f"`timescale 1ns / 1ps\n\n// {spec.name}: generated by rtl_gen.datapath; latency {spec.latency}\n"
    rtl += f"module {spec.name} (\n" + ",\n".join(ports) + "\n    );\n\n" + body
    for p, w in spec.outputs:
        rtl += f"    assign {p} = {w};\n"
    rtl += "\nendmodule\n"
    rtl = merge_bit_assigns(rtl)
    issues = rtl_static_issues(rtl)
    if issues:
        raise AssertionError(f"{spec.name}: static RTL issues: {issues[:5]}")
    with open(os.path.join(_RTL_DIR, f"{spec.name}.sv"), "w", encoding="utf-8") as f:
        f.write(rtl)

    if clock_ns is not None:
        os.makedirs(_XDC_DIR, exist_ok=True)
        with open(os.path.join(_XDC_DIR, f"{spec.name}_clock.xdc"), "w", encoding="utf-8") as f:
            f.write(f"create_clock -period {clock_ns:.3f} -name clk_main [get_ports clk]\n")

    test_size = 0
    if gen_testbench:
        if not vectors:
            raise ValueError(f"{spec.name}: gen_testbench needs vectors")
        names = [w.name for w in spec.inputs] + [p for p, _ in spec.outputs]
        sizes = {len(vectors[n]) for n in names}
        if len(sizes) != 1:
            raise ValueError(f"{spec.name}: vector lengths differ {sizes}")
        test_size = sizes.pop()
        os.makedirs(_TV_DIR, exist_ok=True)
        widths = {w.name: w.bitWidth for w in spec.inputs}
        widths.update({p: spec.wire(w).bitWidth for p, w in spec.outputs})
        for n in names:
            with open(os.path.join(_TV_DIR, f"{n}.txt"), "w", encoding="utf-8") as f:
                for v in vectors[n]:
                    f.write(to_twos_complement_hex(v & ((1 << widths[n]) - 1), widths[n]) + "\n")
        with open(os.path.join(_RTL_DIR, f"{spec.name}_tb.sv"), "w", encoding="utf-8") as f:
            f.write(_gen_testbench(spec, test_size))

    manifest = {
        "top": spec.name,
        "generator": "rtl_gen.datapath.Datapath_RTL_gen" + (" (behavioural)" if behavioural else ""),
        "pipeline_latency": spec.latency,
        "target_fmax_mhz": spec.targetFmaxMhz,
        "nodes": [{"name": n.out.name, "kind": n.kind, "backend": n.backend, "stages": n.stages,
                   "start": n.start, "bitWidth": n.out.bitWidth, "note": n.note} for n in spec.nodes],
        "delays": [{"name": d.name, "src": d.src, "cycles": d.cycles} for d in spec.delays],
        "compressors": compressors,
        "submodules": {k: {"module": v["module"], "latency": v["latency"]} for k, v in subinfo.items()},
        "submodule_files": files_written,
        "params": spec.params,
        "test_size": test_size,
    }
    with open("manifest.json", "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, default=str)
    return {"module": spec.name, "pipeline_latency": spec.latency, "test_size": test_size,
            "compressors": compressors, "manifest": manifest}
