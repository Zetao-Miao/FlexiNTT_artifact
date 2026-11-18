"""Iterative (memory-based) NTT core generator.

Consumes an `ntt_spec.IterNTTSpec` (built by
`operator_modeling.ntt.iterative.IterativeNTT.IterativeNTT.getOperatorInterface`) and writes, into
the current directory:

  RTL_generated/<name>.sv          the core: controller, 2 x 2B data banks, the
                                   operand and write-back multiplexers, B
                                   butterflies (one module), twiddle tables,
                                   the output stream (and its twist multipliers)
  RTL_generated/<name>_ram_*.sv    the simple-dual-port RAM (one per memory style)
  RTL_generated/<name>_tw*.sv      twiddle tables (ROM per butterfly, or one RAM module)
  RTL_generated/<name>_bu*.sv      the butterfly (Butterfly_RTL_gen) and its parts
  RTL_generated/<name>_tb.sv       with `tb`: streams the polynomials, checks every
                                   output beat's value and cycle
  testvectors/                     x_<l>.txt, y_<l>.txt, ycycle.txt, valid.txt, tw_load.txt

The schedule, bank map and controller are the twin of
`operator_modeling.ntt.iterative.IterativeNTTScheme.IterativeNTTScheme` (`pair`, `bank`, `flip`,
`rowAddrs`, `twiddleIndex`, `simulateJob`): any change here must be made there.

Pipeline of one compute read issued in cycle t (R = RAM read latency):
  t      controller (s, tau) -> row addresses, flip, twiddle index (comb)
  t+1    bank read addresses, twiddle address, bundle cb[0] registered
  t+1+R  RAM data; operand mux (codes registered from cb[R-1])
  t+2+R  operands and twiddles registered: butterfly inputs
  +Pbu   butterfly outputs; then one register (or the x2^-1 halver)
  cO     write mux (codes registered from cb[K-1], K = R+Pbu+2), address from cb[K]
  cW     we / wa / wd registered; the RAM writes on the edge ending cW = t + Pw.
"""
from __future__ import annotations

import glob
import json
import os


def _bits(x: int) -> int:
    """Bits of a counter holding 0 .. x-1 (at least 1)."""
    return max(1, (x - 1).bit_length())


def _c(v: int, w: int) -> str:
    return f"{w}'d{v}"


def _h(v: int, w: int) -> str:
    return f"{w}'h{v:x}"


def _ram_module(name: str, style: str) -> str:
    return f"""`timescale 1ns / 1ps
// simple dual port RAM: one write port, one read port registered R times (R = 1 or 2)
module {name} #(parameter int W = 8, parameter int D = 4, parameter int A = 2, parameter int R = 2) (
    input  logic clk,
    input  logic we,
    input  logic [A-1:0] wa,
    input  logic [W-1:0] wd,
    input  logic [A-1:0] ra,
    output logic [W-1:0] rd
    );
    (* ram_style = "{style}" *) logic [W-1:0] mem [D];
    logic [W-1:0] r1;
    always_ff @(posedge clk) if (we) mem[wa] <= wd;
    always_ff @(posedge clk) r1 <= mem[ra];
    generate
    if (R >= 2) begin : g_rr
        logic [W-1:0] rr [R-1];
        always_ff @(posedge clk) begin
            rr[0] <= r1;
            for (int i = 1; i < R - 1; i++) rr[i] <= rr[i-1];
        end
        assign rd = rr[R-2];
    end else begin : g_r1
        assign rd = r1;
    end
    endgenerate
endmodule
"""


def _rom_module(name: str, cols: list[int], values: list[list[int]], depth: int, R: int, style: str) -> str:
    A = _bits(depth)
    L = ["`timescale 1ns / 1ps", f"module {name} (", "    input  logic clk,", f"    input  logic [{A - 1}:0] addr,"]
    L.append(",\n".join(f"    output logic [{w - 1}:0] q{i}" for i, w in enumerate(cols)))
    L.append("    );")
    for i, w in enumerate(cols):
        L.append(f"    (* rom_style = \"{style}\" *) logic [{w - 1}:0] m{i} [{depth}];")
        L.append("    initial begin")
        for a, v in enumerate(values[i]):
            L.append(f"        m{i}[{a}] = {_h(v, w)};")
        L.append("    end")
        L.append(f"    logic [{w - 1}:0] r{i};")
        L.append(f"    always_ff @(posedge clk) r{i} <= m{i}[addr];")
        prev = f"r{i}"
        for k in range(2, R):                       # extra read registers (R > 2)
            L.append(f"    logic [{w - 1}:0] r{i}_{k};")
            L.append(f"    always_ff @(posedge clk) r{i}_{k} <= {prev};")
            prev = f"r{i}_{k}"
        if R >= 2:
            L.append(f"    always_ff @(posedge clk) q{i} <= {prev};")
        else:
            L.append(f"    assign q{i} = r{i};")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def _twram_module(name: str, cols: list[int], depth: int, R: int, style: str) -> str:
    A = _bits(depth)
    L = ["`timescale 1ns / 1ps", f"module {name} (", "    input  logic clk,", f"    input  logic [{A - 1}:0] addr,",
         "    input  logic we,", f"    input  logic [{A - 1}:0] wa,", f"    input  logic [{max(1, len(cols)) - 1}:0] wcol,",
         f"    input  logic [{max(cols) - 1}:0] wd,"]
    L.append(",\n".join(f"    output logic [{w - 1}:0] q{i}" for i, w in enumerate(cols)))
    L.append("    );")
    for i, w in enumerate(cols):
        L.append(f"    (* ram_style = \"{style}\" *) logic [{w - 1}:0] m{i} [{depth}];")
        L.append(f"    always_ff @(posedge clk) if (we && wcol == {i}) m{i}[wa] <= wd[{w - 1}:0];")
        L.append(f"    logic [{w - 1}:0] r{i};")
        L.append(f"    always_ff @(posedge clk) r{i} <= m{i}[addr];")
        prev = f"r{i}"
        for k in range(2, R):                       # extra read registers (R > 2)
            L.append(f"    logic [{w - 1}:0] r{i}_{k};")
            L.append(f"    always_ff @(posedge clk) r{i}_{k} <= {prev};")
            prev = f"r{i}_{k}"
        if R >= 2:
            L.append(f"    always_ff @(posedge clk) q{i} <= {prev};")
        else:
            L.append(f"    assign q{i} = r{i};")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def _twrns_module(name: str, cols: list[int], depth: int, A: int, R: int, style: str) -> str:
    """An RNS-mode twiddle table: one entry (every column) written per cycle from the record
    stream's loader, any time (simple dual port; a read on the write edge sees the old entry,
    and the loader never writes an entry on the edge it is read: IterativeNTTScheme.checkTwiddleWindows)."""
    E = sum(cols)
    L = ["`timescale 1ns / 1ps", f"module {name} (", "    input  logic clk,", f"    input  logic [{A - 1}:0] addr,",
         "    input  logic we,", f"    input  logic [{A - 1}:0] wa,", f"    input  logic [{E - 1}:0] wd,"]
    L.append(",\n".join(f"    output logic [{w - 1}:0] q{i}" for i, w in enumerate(cols)))
    L.append("    );")
    off = 0
    for i, w in enumerate(cols):
        L.append(f"    (* ram_style = \"{style}\" *) logic [{w - 1}:0] m{i} [{depth}];")
        L.append(f"    always_ff @(posedge clk) if (we) m{i}[wa] <= wd[{off + w - 1}:{off}];")
        off += w
        L.append(f"    logic [{w - 1}:0] r{i};")
        L.append(f"    always_ff @(posedge clk) r{i} <= m{i}[addr];")
        prev = f"r{i}"
        for k in range(2, R):
            L.append(f"    logic [{w - 1}:0] r{i}_{k};")
            L.append(f"    always_ff @(posedge clk) r{i}_{k} <= {prev};")
            prev = f"r{i}_{k}"
        if R >= 2:
            L.append(f"    always_ff @(posedge clk) q{i} <= {prev};")
        else:
            L.append(f"    assign q{i} = r{i};")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def _mrom_otag(a, MB: int, MDIR: bool, TG: int, D: int):
    """moduli=: the output tag, the drained polynomial's {DIR, MIDX} `D` cycles behind the drain pointer
    (with out_valid)."""
    a(f"logic [{TG - 1}:0] otag [{D}];")
    a(f"always_ff @(posedge clk) begin otag[0] <= dtag; for (int i = 1; i < {D}; i++) otag[i] <= otag[i-1]; end")
    a(f"assign midx_out = otag[{D - 1}][{MB - 1}:0];")
    if MDIR:
        a(f"assign dir_out = otag[{D - 1}][{MB}];")


def _mrom_consts(a, mr, qports, sets: int, tagw: int):
    """moduli=: per constant the ROM function mt_<qp>(index) and per bank set its registered value fq_<qp>[set]
    (from the set's tag ftag[set], taken with the polynomial's first input beat; ready before its start)."""
    MB = mr["bits"]
    M = len(mr["moduli"])
    for qp, w in qports:
        a(f"function automatic logic [{w - 1}:0] mt_{qp}(input logic [{MB - 1}:0] i_);")
        a("    case (i_)")
        for i, v in enumerate(mr["table"][qp]):
            a(f"        {_c(i, MB)}: mt_{qp} = {_h(v, w)};")
        a(f"        default: mt_{qp} = {_h(mr['table'][qp][0], w)};")
        a("    endcase")
        a("endfunction")
        a(f"logic [{w - 1}:0] fq_{qp} [{sets}];")
        a(f"always_ff @(posedge clk) for (int i = 0; i < {sets}; i++) fq_{qp}[i] <= mt_{qp}(ftag[i][{MB - 1}:0]);")


def IterNTT_RTL_gen(spec, tb=None) -> dict:
    """Emit the iterative NTT core of `spec` (and with `tb` its testbench) into the cwd.
    `tb`: {dir, q: port values, load: words, x: per input beat the io lane values,
    y: per output beat, ycycle: per output beat its cycle, valid: per cycle, cycles}."""
    if getattr(spec, "memOrg", "inplace") == "constgeo":      # constant geometry: rtl_gen/iter_ntt_cg.py
        from rtl_gen.iter_ntt_cg import IterNTT_CG_RTL_gen
        return IterNTT_CG_RTL_gen(spec, tb)
    from rtl_gen.butterfly import Butterfly_RTL_gen
    from rtl_gen.datapath import Datapath_RTL_gen
    from rtl_gen.utils import to_twos_complement_hex
    sp = spec
    name, B, L, b, H, io = sp.name, sp.B, sp.L, sp.b, sp.H, sp.io
    P = 2 * B                      # banks per set
    T = 1 << H
    R = sp.R
    W = sp.width
    NB = sp.beats
    lsub = (P // io).bit_length() - 1          # beat bits inside a row
    FBW = _bits(NB)
    SW = _bits(L)
    Pbu = sp.buLatency
    K = R + Pbu + 2                 # bundle index valid in the write-mux cycle
    Pw = sp.writeLatency
    assert Pw == R + Pbu + 4
    gmax = max(sp.gaps)
    GW = _bits(gmax + 1)
    rtl = "RTL_generated"
    os.makedirs(rtl, exist_ok=True)
    for stale in glob.glob(os.path.join(rtl, f"{name}*.sv")):
        os.remove(stale)
    # --- sub-modules ---------------------------------------------------------------
    Butterfly_RTL_gen(spec=sp.bu, gen_testbench=False)
    tw = sp.twist
    if tw is not None:
        Datapath_RTL_gen(spec=tw["datapath"], gen_testbench=False, submodules=tw["submodules"], write_xdc=False)
    rc = getattr(sp, "rec", None)          # twiddleSource 'rec': the tables written on chip (rtl_gen/iter_ntt_rec.py)
    if rc is not None:
        Datapath_RTL_gen(spec=rc["gen"]["datapath"], gen_testbench=False, submodules=rc["gen"]["submodules"],
                         write_xdc=False)
    if os.path.isfile("manifest.json"):
        os.remove("manifest.json")
    ramMod = f"{name}_ram_{sp.memStyle}"
    with open(os.path.join(rtl, f"{ramMod}.sv"), "w", encoding="utf-8") as f:
        f.write(_ram_module(ramMod, sp.memStyle))
    tabs = list(sp.tables)
    ttabs = list(tw["tables"]) if tw is not None else []
    tstyle = sp.twiddleStyle
    loadW = sp.loadWords
    ramTabs = [t for t in tabs + ttabs if t["mode"] == "ram"]
    for j, t in enumerate(tabs):
        if t["mode"] == "rom":
            with open(os.path.join(rtl, f"{name}_tw{j}.sv"), "w", encoding="utf-8") as f:
                f.write(_rom_module(f"{name}_tw{j}", t["cols"], t["values"], t["depth"], R,
                                    tstyle if t.get("kind") != "c" else "distributed"))
    for l, t in enumerate(ttabs):
        if t["mode"] == "rom":
            with open(os.path.join(rtl, f"{name}_tt{l}.sv"), "w", encoding="utf-8") as f:
                f.write(_rom_module(f"{name}_tt{l}", t["cols"], t["values"], t["depth"], R, tstyle))
    rns = getattr(sp, "twiddleBuffer", "single") != "single"
    dbl = rns and sp.twiddleBuffer == "double"
    recyc = rns and not dbl
    rtw = rns and tw is not None          # the output twist with a record stream (two copies, a record region)
    if rtw:
        TWT = ttabs[0]
        with open(os.path.join(rtl, f"{name}_ttr.sv"), "w", encoding="utf-8") as f:
            f.write(_twrns_module(f"{name}_ttr", list(TWT["cols"]), TWT["depth"], _bits(TWT["depth"]), R, tstyle))
    rec = rns and rc is not None
    if rec and (rtw or getattr(sp, "dirPerPoly", False)):      # refused by IterativeNTTScheme; never built
        raise ValueError(f"{name}: twiddleSource 'rec' is not built with the output twist or dirPerPoly")
    rnsShapes = {}
    if rns:
        for t in tabs:
            key = (tuple(t["cols"]), t["depth"], t.get("kind"))
            if key not in rnsShapes:
                A1 = _bits(t["depth"]) + (1 if dbl else 0)
                rnsShapes[key] = (f"{name}_twr{len(rnsShapes)}", A1)
                st_ = "distributed" if t.get("kind") == "c" else tstyle
                with open(os.path.join(rtl, f"{rnsShapes[key][0]}.sv"), "w", encoding="utf-8") as f:
                    f.write(_twrns_module(rnsShapes[key][0], list(t["cols"]), (1 << A1) if dbl else t["depth"],
                                          A1, R, st_))
    ramShapes = {}
    for t in ramTabs:
        key = (tuple(t["cols"]), t["depth"], t.get("kind"))
        if key not in ramShapes:
            ramShapes[key] = f"{name}_twram{len(ramShapes)}"
            st_ = "distributed" if t.get("kind") == "c" else tstyle
            with open(os.path.join(rtl, f"{ramShapes[key]}.sv"), "w", encoding="utf-8") as f:
                f.write(_twram_module(ramShapes[key], list(t["cols"]), t["depth"], R, st_))

    bs = sp.bu
    qports = list(sp.qPorts)
    qw = dict(qports)
    O = []           # the top's body

    def a(x):
        O.append("    " + x)

    # --- ports -----------------------------------------------------------------
    # moduli= (multi-modulus ROM): MIDX (and DIR) with the first input beat of each polynomial, the tag on the
    # output (midx_out, dir_out); the constants from ROMs, no q ports
    mr = getattr(sp, "mrom", None)
    MB = mr["bits"] if mr else 0
    MDIR = bool(mr) and sp.dirPort           # the direction per polynomial
    TG = MB + (1 if MDIR else 0)             # a polynomial's tag: {DIR, MIDX}
    mbub = bool(mr) and not getattr(sp, "qInline", False)      # qSwitch 'bubble'
    ports = ["    input  logic clk", "    input  logic rst"]
    if sp.dirPort and not mr:
        ports.append("    input  logic DIR")
    if mr:
        pass
    elif not rns:
        ports += [f"    input  logic [{w - 1}:0] {qp}" for qp, w in qports]
    else:
        TL, ecols = sp.twLanes, list(sp.twEntryCols)
        TEW = sum(ecols)
        TLW = TL * TEW
        ports += ["    input  logic tw_valid", "    output logic tw_ready", f"    input  logic [{TLW - 1}:0] tw_data"]
    TWW = 0
    if loadW:
        LW = loadW.bit_length()
        TWW = max(max(t["cols"]) for t in ramTabs)
        ports += ["    input  logic tw_rst", "    input  logic tw_wen", f"    input  logic [{TWW - 1}:0] tw_wdata"]
    ports += ["    input  logic in_valid", "    output logic in_ready"]
    if mr:
        ports += [f"    input  logic [{MB - 1}:0] MIDX"] + (["    input  logic DIR"] if MDIR else [])
    ports += [f"    input  logic [{W - 1}:0] x_in_{l}" for l in range(io)]
    ports += ["    output logic out_valid"]
    if mr:
        ports += [f"    output logic [{MB - 1}:0] midx_out"] + (["    output logic dir_out"] if MDIR else [])
    ports += [f"    output logic [{sp.outWidth - 1}:0] y_out_{l}" for l in range(io)]

    # --- quasi-static inputs, registered -----------------------------------------
    dpp = getattr(sp, "dirPerPoly", False)        # the direction per polynomial: a record header bit
    if mr:
        a(f"// ---- moduli= : {len(mr['moduli'])} moduli in the ROMs; a polynomial's tag {{DIR, MIDX}} is taken with its "
          f"first input beat")
        a(f"logic [{TG - 1}:0] ftag [2]; logic [{TG - 1}:0] ctag, dtag;      // per filled set; computing; draining")
        a(f"logic [{MB - 1}:0] cmidx, dmidx; assign cmidx = ctag[{MB - 1}:0]; assign dmidx = dtag[{MB - 1}:0];")
        if MDIR:
            a(f"(* max_fanout = 32 *) logic DIR_r; logic ddir; assign ddir = dtag[{MB}];")
        _mrom_consts(a, mr, qports, 2, TG)
    elif sp.dirPort:
        a("(* max_fanout = 32 *) logic DIR_r;")
        a("always_ff @(posedge clk) DIR_r <= DIR;")
    if dpp:
        a("(* max_fanout = 32 *) logic DIR_r; logic DIR_n;      // the next polynomial's direction (record header)")
    dirs = "DIR_r" if (sp.dirPort or dpp) else ("1'b1" if sp.direction == "inverse" else "1'b0")
    for qp, w in qports:
        a(f"(* max_fanout = 16 *) logic [{w - 1}:0] {qp}_r;")
        if mr:
            pass                              # from fq_{qp}[set] at the polynomial's start (after the controller)
        elif not rns:
            a(f"always_ff @(posedge clk) {qp}_r <= {qp};")
        else:
            a(f"logic [{w - 1}:0] {qp}_n;      // the next polynomial's (record header), into {qp}_r at its start")
    # qSwitch 'inline': no bubble at a modulus change. {qp}_r switches at the start; {qp}_dl[i] is it i+1 cycles
    # later, and a consumer's copy takes the tap that switches as the new polynomial's first operation reaches it
    inl = (rns or bool(mr)) and getattr(sp, "qInline", False)
    # the direction travels like a constant (DIR_r switches at the start): with moduli=, and with a direction per
    # polynomial in the record header together with qSwitch 'inline' (2026-11-17; with the bubble the header's
    # direction keeps its one extra register below)
    DDL = MDIR or (dpp and inl)
    if DDL:
        qw["DIR"] = 1
    if inl:
        for qp, w in qports + ([("DIR", 1)] if DDL else []):
            a(f"logic [{w - 1}:0] {qp}_dl [{K}];")
            a(f"always_ff @(posedge clk) begin {qp}_dl[0] <= {qp}_r; "
              f"for (int i = 1; i < {K}; i++) {qp}_dl[i] <= {qp}_dl[i-1]; end")
    qcopies = set()

    def qsig(tag: str, qp: str, d: int | None = None) -> str:
        '''A registered copy of constant `qp`; inline with `d`: the copy `d` >= 2 cycles behind {qp}_r.'''
        nm = f"{tag}_{qp}"
        if nm not in qcopies:
            qcopies.add(nm)
            a(f"(* max_fanout = 16 *) logic [{qw[qp] - 1}:0] {nm};")
            a(f"always_ff @(posedge clk) {nm} <= " + (f"{qp}_dl[{d - 2}];" if (inl and d is not None) else f"{qp}_r;"))
        return nm

    # --- controller (twin: IterativeNTTScheme.simulateJob) --------------------------
    a("// ---- controller: fill (input), compute (butterflies), drain (output) over two bank sets")
    a(f"logic fset; logic [{FBW - 1}:0] fptr; logic [1:0] full, busy, res;")
    a(f"logic cact, cset, cnext; logic [{SW - 1}:0] s; logic [{H - 1}:0] tau; logic [{GW - 1}:0] gap;")
    a(f"logic dact, dset, dnext; logic [{FBW - 1}:0] dptr;")
    a(f"logic [{Pw - 1}:0] dsr, dsrs;")
    a("logic fill_ok, acc, flast, issue, tlast, clast, startc, dlastb, startd, done, done_set;")
    if rns:
        HB, NBs, QB = sp.headerBeats, list(sp.stageBeats), sp.qBubble
        if rtw:
            NBs.append(sp.twistBeats)          # region L: the twist factors
        G = B // TL
        GB = G.bit_length() - 1
        KW = _bits(max(NBs))
        SWL = _bits(L + 1) if rtw else SW
        HBW = _bits(HB)
        QBW = _bits(QB + 1)
        RW = _bits(L + 1)
        a(f"// ---- record stream ({sp.twiddleBuffer}): per polynomial a header (bit 0 keep, then the modulus "
          f"constants), then its twiddles, {TL} entries a beat")
        a("localparam logic [1:0] L_HDR = 2'd0, L_DATA = 2'd1, L_WAIT = 2'd2;")
        if rec:
            a("logic [1:0] lst, lst_n; logic lahead, lahead_n, nkeep, hdr_ok, perm, tacc, hlast, hkeep;")
            a(f"logic [{SW - 1}:0] ws, ws_n; logic [{HBW - 1}:0] hptr, hptr_n;")
        else:
            a(f"logic [1:0] lst, lst_n; logic lahead, lahead_n, nkeep, hdr_ok, perm, tacc, hlast, klast, hkeep;")
            a(f"logic [{SWL - 1}:0] ls, ls_n; logic [{KW - 1}:0] lk, lk_n; logic [{HBW - 1}:0] hptr, hptr_n;")
        if rtw:
            TQ = R + 2 + tw["latency"]
            TQW = _bits(TQ + 1)
            a(f"logic [1:0] twfull; logic lcopyT; logic [{TQW - 1}:0] dgw;      // twist copies; drain gap {TQ}")
        a(f"logic [{QBW - 1}:0] qw;")
        if recyc:
            a(f"logic [{RW - 1}:0] relst; logic twok;")
        if dbl:
            a("logic lcopy, ccopy;")
        if recyc:
            a("assign hdr_ok = (lst == L_WAIT) || ((lst == L_DATA) && lahead);")
        elif rtw:       # double: the twist region holds only the drain, not the start
            a(f"assign hdr_ok = (lst == L_WAIT) || ((lst == L_DATA) && lahead && (ls == {_c(L, SWL)}));")
        else:
            a("assign hdr_ok = (lst == L_WAIT);")
    if mbub:
        QB = mr["bubble"]
        QBW = _bits(QB + 1)
        a(f"logic [{QBW - 1}:0] qw; logic nkeep;      // moduli=, qSwitch 'bubble': a new modulus or direction "
          f"starts {QB} cycles after the last issue")
        a("assign nkeep = ftag[cnext] == ctag;")
    a("assign fill_ok = !full[fset] && !busy[fset] && (!res[fset] || (dact && (dset == fset) && (fptr < dptr)));")
    a("assign in_ready = fill_ok;")
    a("assign acc = in_valid && fill_ok && !rst;")
    a(f"assign flast = fptr == {_c(NB - 1, FBW)};")
    a("assign issue = cact && (gap == '0) && twok;" if recyc else "assign issue = cact && (gap == '0);")
    a(f"assign tlast = tau == {_c(T - 1, H)};")
    a(f"assign clast = issue && tlast && (s == {_c(L - 1, SW)});")
    if rns:
        if inl:     # the next polynomial follows at once, also with a new modulus
            a("assign startc = full[cnext] && hdr_ok && (!cact || clast);")
        else:
            a("assign startc = full[cnext] && hdr_ok && (nkeep ? (!cact || clast) : (!cact && (qw == '0)));")
    elif mbub:
        a("assign startc = full[cnext] && (nkeep ? (!cact || clast) : (!cact && (qw == '0)));")
    else:
        a("assign startc = full[cnext] && (!cact || clast);")
    a(f"assign dlastb = dact && (dptr == {_c(NB - 1, FBW)});")
    if rtw:
        a("assign startd = res[dnext] && twfull[dnext] && !dact && (dgw == '0);")
    else:
        a("assign startd = res[dnext] && (!dact || dlastb);")
    a(f"assign done = dsr[{Pw - 1}]; assign done_set = dsrs[{Pw - 1}];")
    a(f"logic [{GW - 1}:0] gap_of;")
    a("always_comb begin")
    a("    case (s)")
    for st, g in enumerate(sp.gaps):
        if g:
            a(f"        {_c(st, SW)}: gap_of = {_c(g, GW)};")
    a("        default: gap_of = '0;")
    a("    endcase")
    a("end")
    a("always_ff @(posedge clk) begin")
    a("    if (rst) begin")
    a("        fset <= 1'b0; fptr <= '0; full <= '0; busy <= '0; res <= '0;")
    a("        cact <= 1'b0; cset <= 1'b0; cnext <= 1'b0; s <= '0; tau <= '0; gap <= '0;")
    a("        dact <= 1'b0; dset <= 1'b0; dnext <= 1'b0; dptr <= '0; dsr <= '0; dsrs <= '0;")
    a("    end else begin")
    a("        if (acc) begin")
    a("            fptr <= flast ? '0 : fptr + 1'b1;")
    a("            if (flast) begin full[fset] <= 1'b1; fset <= ~fset; end")
    a("        end")
    a(f"        dsr <= {{dsr[{Pw - 2}:0], clast}}; dsrs <= {{dsrs[{Pw - 2}:0], cset}};")
    a("        if (startc) begin")
    a("            full[cnext] <= 1'b0; busy[cnext] <= 1'b1;")
    a("            cact <= 1'b1; cset <= cnext; cnext <= ~cnext; s <= '0; tau <= '0; gap <= '0;")
    a("        end else if (clast) cact <= 1'b0;")
    a("        else if (issue) begin")
    a("            if (tlast) begin gap <= gap_of; s <= s + 1'b1; tau <= '0; end")
    a("            else tau <= tau + 1'b1;")
    a("        end else if (cact && gap != '0) gap <= gap - 1'b1;" if rns else "        end else if (cact) gap <= gap - 1'b1;")
    a("        if (done) begin busy[done_set] <= 1'b0; res[done_set] <= 1'b1; end")
    a("        if (dlastb) res[dset] <= 1'b0;")
    a("        if (startd) begin dact <= 1'b1; dset <= dnext; dnext <= ~dnext; dptr <= '0; end")
    a("        else if (dlastb) dact <= 1'b0;")
    a("        else if (dact) dptr <= dptr + 1'b1;")
    a("    end")
    a("end")
    if mr:
        # ftag[X] holds until set X is refilled, which begins only after X's drain has started
        a("always_ff @(posedge clk) begin")
        a("    if (rst) begin ctag <= '0; dtag <= '0;" + (" qw <= '0;" if mbub else "") + " end")
        a("    else begin")
        a("        if (startc) ctag <= ftag[cnext];")
        a("        if (startd) dtag <= ftag[dnext];")
        if mbub:
            a(f"        qw <= clast ? {_c(QB, QBW)} : ((qw != '0) ? qw - 1'b1 : '0);")
        a("    end")
        a(f"    if (acc && (fptr == '0)) ftag[fset] <= {{{'DIR, ' if MDIR else ''}MIDX}};")
        a("    if (!rst && startc) begin " + " ".join(f"{qp}_r <= fq_{qp}[cnext];" for qp, _ in qports)
          + (f" DIR_r <= ftag[cnext][{MB}];" if MDIR else "") + " end")
        a("end")

    if rec:
        from rtl_gen.iter_ntt_rec import rec_ip_loader, rec_ip_writes
        rec_ip_loader(a, sp, rc, L, SW, HB, HBW, QB, QBW, RW, TLW, qports)
    if rns and not rec:
        a("// ---- the loader (twin: IterativeNTTScheme._simulateJobRns)")
        if rtw:
            a(f"assign perm = (ls == {_c(L, SWL)}) ? !twfull[lcopyT] : "
              + (f"(!lahead || (relst > {RW}'(ls)));" if recyc else "1'b1;"))
        else:
            a(f"assign perm = !lahead || (relst > {RW}'(ls));" if recyc else "assign perm = 1'b1;")
        a("assign tw_ready = (lst == L_HDR) || ((lst == L_DATA) && perm);")
        a("assign tacc = tw_valid && tw_ready && !rst;")
        a(f"assign hlast = hptr == {_c(HB - 1, HBW)};" if HB > 1 else "assign hlast = 1'b1;")
        a(f"function automatic logic [{KW - 1}:0] nbs_of(input logic [{SWL - 1}:0] s_);")
        a("    case (s_)")
        for st, nb in enumerate(NBs):
            a(f"        {_c(st, SWL)}: nbs_of = {_c(nb - 1, KW)};")
        a("        default: nbs_of = '0;")
        a("    endcase")
        a("endfunction")
        a("assign klast = lk == nbs_of(ls);")
        HW_ = HB * TLW
        if HB > 1:
            a(f"logic [{TLW - 1}:0] hb [{HB - 1}];")
            a(f"logic [{HW_ - 1}:0] hdr_w; assign hdr_w = {{tw_data, " + ", ".join(f"hb[{k}]" for k in range(HB - 2, -1, -1)) + "};")
        else:
            a(f"logic [{HW_ - 1}:0] hdr_w; assign hdr_w = tw_data;")
        a("assign hkeep = hdr_w[0];")
        a("always_comb begin")
        a("    lst_n = lst; lahead_n = lahead; ls_n = ls; lk_n = lk; hptr_n = hptr;")
        a("    case (lst)")
        a("        L_HDR: if (tacc) begin")
        a("            if (hlast) begin")
        a("                hptr_n = '0;")
        if rtw:
            a(f"                if (hkeep) begin lst_n = L_DATA; ls_n = {_c(L, SWL)}; lk_n = '0; lahead_n = 1'b1; end")
        else:
            a("                if (hkeep) lst_n = L_WAIT;")
        a("                else begin lst_n = L_DATA; ls_n = '0; lk_n = '0; lahead_n = 1'b1; end")
        a("            end else hptr_n = hptr + 1'b1;")
        a("        end")
        a("        L_DATA: begin")
        a("            if (startc) lahead_n = 1'b0;")
        a("            if (tacc) begin")
        a("                if (klast) begin")
        a("                    lk_n = '0; ls_n = ls + 1'b1;")
        a(f"                    if (ls == {_c(L if rtw else L - 1, SWL)}) begin ls_n = '0; lst_n = (lahead && !startc) ? L_WAIT : L_HDR; end")
        a("                end else lk_n = lk + 1'b1;")
        a("            end")
        a("        end")
        a("        L_WAIT: if (startc) lst_n = L_HDR;")
        a("        default: lst_n = L_HDR;")
        a("    endcase")
        a("end")
        if recyc:
            a(f"logic [{SW - 1}:0] s_nx; logic [{H - 1}:0] tau_nx;")
            a("assign s_nx = startc ? '0 : ((issue && tlast) ? s + 1'b1 : s);")
            a("assign tau_nx = startc ? '0 : (issue ? (tlast ? '0 : tau + 1'b1) : tau);")
        a("always_ff @(posedge clk) begin")
        a("    if (rst) begin")
        rs_ = "        lst <= L_HDR; lahead <= 1'b1; ls <= '0; lk <= '0; hptr <= '0; nkeep <= 1'b0; qw <= '0;"
        if recyc:
            rs_ += f" relst <= {_c(L, RW)}; twok <= 1'b0;"
        if dbl:
            rs_ += " lcopy <= 1'b1; ccopy <= 1'b1;"
        if rtw:
            rs_ += " twfull <= '0; lcopyT <= 1'b0; dgw <= '0;"
        a(rs_)
        a("    end else begin")
        a("        lst <= lst_n; lahead <= lahead_n; ls <= ls_n; lk <= lk_n; hptr <= hptr_n;")
        a("        if (lst == L_HDR && tacc && hlast) nkeep <= hkeep;")
        if dbl:
            a("        if (lst == L_HDR && tacc && hlast && !hkeep) lcopy <= ~lcopy;")
            a("        if (startc && !nkeep) ccopy <= ~ccopy;")
        a(f"        qw <= clast ? {_c(QB, QBW)} : ((qw != '0) ? qw - 1'b1 : '0);")
        if rtw:
            a(f"        if (tacc && lst == L_DATA && klast && ls == {_c(L, SWL)}) begin twfull[lcopyT] <= 1'b1; "
              f"lcopyT <= ~lcopyT; end")
            a("        if (dlastb) twfull[dset] <= 1'b0;")
            a(f"        dgw <= dlastb ? {_c(TQ, TQW)} : ((dgw != '0) ? dgw - 1'b1 : '0);")
        if recyc:
            a(f"        if (startc) relst <= '0; else if (clast) relst <= {_c(L, RW)}; "
              f"else if (issue && (tau == '0)) relst <= {RW}'(s);")
            a("        twok <= (tau_nx != '0) || !((lst_n == L_DATA) && !lahead_n) || (ls_n > s_nx);")
        a("    end")
        a("end")
        a("// the modulus constants: the header into *_n, into *_r (the butterflies' constants) at the start of "
          "a polynomial with a new modulus")
        a("always_ff @(posedge clk) begin")
        if HB > 1:
            a("    if (lst == L_HDR && tacc && !hlast) hb[hptr] <= tw_data;")
        for qp, off, w in sp.headerLayout:
            a(f"    if (lst == L_HDR && tacc && hlast && !hkeep) {qp}_n <= hdr_w[{off + w - 1}:{off}];")
        a("    if (!rst && startc && !nkeep) begin " + " ".join(f"{qp}_r <= {qp}_n;" for qp, _ in qports)
          + (" DIR_r <= DIR_n;" if dpp else "") + " end")
        a("end")

    # --- stage decode: rows, flip, twiddle index ---------------------------------------
    TA = _bits(sp.tables[0].get("depth1", sp.tables[0]["depth"]))   # the twiddle tables (both directions, or forward only when shared)
    CA = _bits(sp.tables[1].get("depth1", sp.tables[1]["depth"]))   # the stage-constant tables

    def hA_expr(p: int, t: str) -> str:
        parts = []
        if p + 1 <= H - 1:
            parts.append(f"{t}[{H - 1}:{p + 1}]")
        parts.append("1'b0")
        if p >= 1:
            parts.append(f"{t}[{p}:1]")
        return "{" + ", ".join(parts) + "}"

    a("// ---- stage decode (IterativeNTTScheme.rowAddrs / flip / twiddleIndex)")
    a(f"function automatic logic [{2 * H}:0] rows_of(input logic [{SW - 1}:0] s_, input logic [{H - 1}:0] t_);")
    a(f"    logic [{H - 1}:0] ha, hb; logic f;")
    a("    ha = t_; hb = t_; f = ^t_;")
    a("    case (s_)")
    for st in range(b + 1, L):
        p = st - b - 1
        a(f"        {_c(st, SW)}: begin ha = {hA_expr(p, 't_')}; hb = ha | {_h(1 << p, H)}; f = t_[0] ^ (^ha); end")
    a("        default: ;")
    a("    endcase")
    a("    rows_of = {f, hb, ha};")
    a("endfunction")
    a(f"function automatic logic [{TA - 1}:0] tidx_of(input logic [{SW - 1}:0] s_, input logic [{H - 1}:0] t_);")
    a("    case (s_)")
    for st in range(L):
        if st > b:
            p = st - b - 1
            base = (1 << (p + 1)) - 2
            a(f"        {_c(st, SW)}: tidx_of = {_c(base, TA)} + {TA}'(t_ & {_h((2 << p) - 1, H)});")
    a("        default: tidx_of = '0;")
    a("    endcase")
    a("endfunction")
    a(f"logic [{2 * H}:0] c_rows; assign c_rows = rows_of(s, tau);")
    a(f"logic [{H - 1}:0] c_hA, c_hB; logic c_flip;")
    a(f"assign c_hA = c_rows[{H - 1}:0]; assign c_hB = c_rows[{2 * H - 1}:{H}]; assign c_flip = c_rows[{2 * H}];")

    # bundle chain: cb[k] holds the issue of cycle t during cycle t+1+k
    a(f"// ---- issue bundle, delayed: cb_*[k] is the read issued k+1 cycles ago (k = 0 .. {K})")
    a(f"logic cb_v [{K + 1}]; logic cb_set [{K + 1}]; logic cb_f [{K + 1}];")
    a(f"logic [{SW - 1}:0] cb_s [{K + 1}]; logic [{H - 1}:0] cb_t [{K + 1}]; logic [{B - 1}:0] cb_sw [{K + 1}];")
    # shared inverse twiddles: butterfly j swaps its outputs where it uses -w (IterativeNTTScheme.twiddleRef)
    a(f"logic [{B - 1}:0] c_sw;")
    if sp.shareInv:
        a("always_comb begin")
        a("    c_sw = '0;")
        a(f"    if ({dirs}) case (s)")
        for st in range(L):
            if st <= b:
                bits = [j for j in range(B) if j % (1 << st)]
                if bits:
                    a(f"        {_c(st, SW)}: c_sw = {_h(sum(1 << j for j in bits), B)};")
            else:
                mask = (2 << (st - b - 1)) - 1
                a(f"        {_c(st, SW)}: c_sw = {{{B - 1}'h{((1 << B) - 1) >> 1:x}, |(tau & {_h(mask, H)})}};"
                  if B > 1 else f"        {_c(st, SW)}: c_sw = |(tau & {_h(mask, H)});")
        a("        default: ;")
        a("    endcase")
        a("end")
    else:
        a("assign c_sw = '0;")
    a("always_ff @(posedge clk) begin")
    a(f"    if (rst) for (int i = 0; i <= {K}; i++) cb_v[i] <= 1'b0;")
    a("    else begin")
    a("        cb_v[0] <= issue;")
    a(f"        for (int i = 1; i <= {K}; i++) cb_v[i] <= cb_v[i-1];")
    a("    end")
    a("    cb_set[0] <= cset; cb_f[0] <= c_flip; cb_s[0] <= s; cb_t[0] <= tau; cb_sw[0] <= c_sw;")
    a(f"    for (int i = 1; i <= {K}; i++) begin cb_set[i] <= cb_set[i-1]; cb_f[i] <= cb_f[i-1]; "
      f"cb_s[i] <= cb_s[i-1]; cb_t[i] <= cb_t[i-1]; cb_sw[i] <= cb_sw[i-1]; end")
    a("end")

    # --- drain decode -----------------------------------------------------------------
    a("// ---- drain: beat dptr of set dset, row dptr >> lsub")
    a(f"logic [{H - 1}:0] drow; assign drow = {H}'(dptr >> {lsub});")
    if lsub:
        a(f"logic [{lsub - 1}:0] dsub; assign dsub = dptr[{lsub - 1}:0];")
    DSUB = max(1, lsub)
    a(f"logic db_v [{R + 1}]; logic db_set [{R + 1}]; logic db_pi [{R + 1}]; logic [{DSUB - 1}:0] db_sub [{R + 1}];")
    a("always_ff @(posedge clk) begin")
    a(f"    if (rst) for (int i = 0; i <= {R}; i++) db_v[i] <= 1'b0;")
    a("    else begin")
    a("        db_v[0] <= dact;")
    a(f"        for (int i = 1; i <= {R}; i++) db_v[i] <= db_v[i-1];")
    a("    end")
    a(f"    db_set[0] <= dset; db_pi[0] <= ^drow; db_sub[0] <= {'dsub' if lsub else chr(39) + '0'};")
    a(f"    for (int i = 1; i <= {R}; i++) begin db_set[i] <= db_set[i-1]; db_pi[i] <= db_pi[i-1]; db_sub[i] <= db_sub[i-1]; end")
    a("end")

    # --- fill decode ------------------------------------------------------------------
    a("// ---- fill: beat fptr of set fset, row fptr >> lsub")
    a(f"logic [{H - 1}:0] frow; assign frow = {H}'(fptr >> {lsub});")
    a("logic fpi; assign fpi = ^frow;")
    if lsub:
        a(f"logic [{lsub - 1}:0] fsub; assign fsub = fptr[{lsub - 1}:0];")

    # --- write-mux stage decode --------------------------------------------------------
    a(f"logic [{2 * H}:0] w_rows; assign w_rows = rows_of(cb_s[{K}], cb_t[{K}]);")
    a(f"logic [{H - 1}:0] w_hA, w_hB; assign w_hA = w_rows[{H - 1}:0]; assign w_hB = w_rows[{2 * H - 1}:{H}];")
    a(f"logic w_v, w_set, w_f; assign w_v = cb_v[{K}]; assign w_set = cb_set[{K}]; assign w_f = cb_f[{K}];")

    # --- read-select codes (from cb[R-1], registered: valid with the RAM data) --------------
    rs, ws = sp.readSources, sp.writeSources
    rdec, wdec = sp.readDecode, sp.writeDecode
    rcw = [_bits(len(x)) for x in rs]
    wcw = [_bits(len(x)) for x in ws]
    for p_ in range(P):
        a(f"logic [{rcw[p_] - 1}:0] rc{p_};")
    for k in range(P):
        a(f"logic [{wcw[k] - 1}:0] wc{k};")
    combos = sorted({key for d in rdec for key in d})

    def code_block(dec, widths, reg, src):
        a("always_ff @(posedge clk) begin")
        a(f"    case ({{{src}_s, {src}_f}})")
        for (st, f_) in combos:
            body = " ".join(f"{reg}{i} <= {_c(d[(st, f_)], widths[i])};" for i, d in enumerate(dec) if (st, f_) in d)
            a(f"        {{{_c(st, SW)}, 1'b{f_}}}: begin {body} end")
        a("        default: ;")
        a("    endcase")
        a("end")
    a(f"logic [{SW - 1}:0] rk_s, wk_s; logic rk_f, wk_f;")
    a(f"assign rk_s = cb_s[{R - 1}]; assign rk_f = cb_f[{R - 1}];")
    a(f"assign wk_s = cb_s[{K - 1}]; assign wk_f = cb_f[{K - 1}];")
    code_block(rdec, rcw, "rc", "rk")
    code_block(wdec, wcw, "wc", "wk")

    # --- banks ------------------------------------------------------------------------
    a("// ---- data banks: 2 sets x 2B banks (bank of m: (m mod 2B) ^ (parity(m >> (b+1)) << b), address m >> (b+1))")
    for X in (0, 1):
        for k in range(P):
            nm = f"m{X}_{k}"
            a(f"logic {nm}_we; logic [{H - 1}:0] {nm}_wa, {nm}_ra; logic [{W - 1}:0] {nm}_wd, {nm}_rd;")
            a(f"{ramMod} #(.W({W}), .D({T}), .A({H}), .R({R})) u_{nm} (.clk(clk), .we({nm}_we), .wa({nm}_wa), "
              f".wd({nm}_wd), .ra({nm}_ra), .rd({nm}_rd));")
            top = k >> b
            caddr = f"(c_flip ? c_hA : c_hB)" if top else f"(c_flip ? c_hB : c_hA)"
            a(f"always_ff @(posedge clk) if (issue && cset == 1'b{X}) {nm}_ra <= {caddr}; "
              f"else if (dact && dset == 1'b{X}) {nm}_ra <= drow;")
    # the read-port set select
    for k in range(P):
        a(f"logic [{W - 1}:0] rdc{k}; assign rdc{k} = cb_set[{R}] ? m1_{k}_rd : m0_{k}_rd;")
    # operand mux -> registers
    a("// ---- operand mux (sources per port: IterativeNTTScheme.readSources)")
    for p_ in range(P):
        nm = f"op{p_}"
        a(f"logic [{W - 1}:0] {nm};")
        if len(rs[p_]) == 1:
            a(f"always_ff @(posedge clk) {nm} <= rdc{rs[p_][0]};")
        else:
            a(f"always_ff @(posedge clk) case (rc{p_})")
            for i, kk in enumerate(rs[p_]):
                a(f"    {_c(i, rcw[p_])}: {nm} <= rdc{kk};")
            a(f"    default: {nm} <= rdc{rs[p_][0]};")
            a("endcase")

    # --- twiddle tables ----------------------------------------------------------------
    a("// ---- twiddle tables (two per butterfly: stages > b, and the stage constants of stages <= b),")
    a("// addresses = twiddleIndex (+ the inverse half); the choice registered with the data")
    a(f"(* max_fanout = 16 *) logic [{TA - 1}:0] ta, ta0; (* max_fanout = 16 *) logic [{CA - 1}:0] tca;")
    if sp.shareInv:
        # the inverse reads the forward tables: entry ~v (butterfly 0: -v), table of butterfly -j
        a(f"always_ff @(posedge clk) ta <= tidx_of(s, {dirs} ? ~tau : tau);")
        a(f"always_ff @(posedge clk) ta0 <= tidx_of(s, {dirs} ? {H}'(-tau) : tau);")
        a(f"always_ff @(posedge clk) tca <= {CA}'(s);")
    else:
        dirOff = f" + ({dirs} ? {_c(sp.tdepth, TA)} : {_c(0, TA)})" if (sp.dirPort or dpp) else ""
        cdirOff = f" + ({dirs} ? {_c(sp.cdepth, CA)} : {_c(0, CA)})" if (sp.dirPort or dpp) else ""
        a(f"always_ff @(posedge clk) ta <= tidx_of(s, tau){dirOff};")
        a("always_ff @(posedge clk) ta0 <= ta;")
        a(f"always_ff @(posedge clk) tca <= {CA}'(s){cdirOff};")
    # tsel[i] is the choice of the read issued in cycle t, during cycle t+1+i; the tables answer in t+1+R
    a(f"logic tsel [{R + 1}]; always_ff @(posedge clk) begin tsel[0] <= s > {_c(b, SW)}; "
      f"for (int i = 1; i <= {R}; i++) tsel[i] <= tsel[i-1]; end")
    a(f"logic tsel_r; assign tsel_r = tsel[{R}];")
    MX = bool(mr) and len(mr["moduli"]) > 1      # moduli=: the tables' address is {MIDX, the one-modulus address}
    if MX:
        a(f"(* max_fanout = 16 *) logic [{MB - 1}:0] cmidx_a; always_ff @(posedge clk) cmidx_a <= cmidx;")
    if inl and dbl:     # the copy of the read's own polynomial, registered with its address
        a("logic ccopy_a; always_ff @(posedge clk) ccopy_a <= ccopy;")
    if loadW:
        a(f"(* max_fanout = 32 *) logic [{LW - 1}:0] tw_wi;")
        a("always_ff @(posedge clk) tw_wi <= tw_rst ? '0 : (tw_wen ? tw_wi + 1'b1 : tw_wi);")
        a(f"(* max_fanout = 32 *) logic [{TWW - 1}:0] tw_wd_q;")
        a("always_ff @(posedge clk) tw_wd_q <= tw_wdata;")

    if rec:
        rec_ip_writes(a, sp, rc, L, B, b, SW, TA, CA, TEW)
    if rns and not rec:
        # the loader's table write ports: a beat of stage s (direction d, entry e, group g) writes entry e of
        # the tables of butterflies g*TL .. g*TL+TL-1 (lane j mod TL), registered, so the RAM writes one edge on
        a("// ---- table write ports from the record stream (IterativeNTT.rnsRecord order)")
        nd = sp.tables[0]["depth"] // sp.tdepth
        a(f"logic [{KW - 1}:0] lw_rest; assign lw_rest = {KW}'(lk >> {GB});")
        a(f"function automatic logic [{TA - 1}:0] lwa_t_of(input logic [{SW - 1}:0] s_, input logic [{KW - 1}:0] r_);")
        a("    case (s_)")
        for st in range(b + 1, L):
            p = st - b - 1
            base = (1 << (p + 1)) - 2
            e = f"{TA}'(r_ & {_h((2 << p) - 1, KW)})"
            d = f" + (r_[{p + 1}] ? {_c(sp.tdepth, TA)} : {_c(0, TA)})" if nd > 1 else ""
            a(f"        {_c(st, SW)}: lwa_t_of = {_c(base, TA)} + {e}{d};")
        a("        default: lwa_t_of = '0;")
        a("    endcase")
        a("endfunction")
        a(f"function automatic logic [{CA - 1}:0] lwa_c_of(input logic [{SW - 1}:0] s_, input logic [{KW - 1}:0] r_);")
        a(f"    lwa_c_of = {CA}'(s_)" + (f" + (r_[0] ? {_c(sp.cdepth, CA)} : {_c(0, CA)});" if nd > 1 else ";"))
        a("endfunction")
        cpw = "lcopy, " if dbl else ""
        a(f"(* max_fanout = 16 *) logic [{TA + dbl - 1}:0] lw_wa_t; (* max_fanout = 16 *) logic [{CA + dbl - 1}:0] lw_wa_c;")
        if rtw:     # the twist region (ls == L) writes the twist tables only
            a(f"logic lw_go, lw_t; assign lw_go = tacc && (lst == L_DATA) && (ls != {_c(L, SWL)}); "
              f"assign lw_t = ls > " + _c(b, SWL) + ";")
        else:
            a("logic lw_go, lw_t; assign lw_go = tacc && (lst == L_DATA); assign lw_t = ls > " + _c(b, SW) + ";")
        a(f"always_ff @(posedge clk) begin lw_wa_t <= {{{cpw}lwa_t_of(ls, lw_rest)}}; lw_wa_c <= {{{cpw}lwa_c_of(ls, lw_rest)}}; end")
        for j in range(B):
            g = j // TL
            gm = f" && (lk[{GB - 1}:0] == {_c(g, GB)})" if GB else ""
            a(f"logic lw_wet{j}, lw_wec{j}; logic [{TEW - 1}:0] lw_wd{j};")
            a(f"always_ff @(posedge clk) begin lw_wet{j} <= !rst && lw_go && lw_t{gm}; "
              f"lw_wec{j} <= !rst && lw_go && !lw_t{gm}; lw_wd{j} <= tw_data[{(j % TL) * TEW + TEW - 1}:{(j % TL) * TEW}]; end")

    def table_inst(t, inst, mod_rom, addr, outs):
        conn = [".clk(clk)", f".addr({addr})"]
        if t["mode"] == "rns":
            j_, kd = t["j"], t.get("kind")
            if dbl:
                conn[1] = f".addr({{{'ccopy_a' if inl else 'ccopy'}, {addr}}})"
            conn += [f".we(lw_we{kd}{j_})", f".wa(lw_wa_{kd})", f".wd(lw_wd{j_})"]
            mod = rnsShapes[(tuple(t["cols"]), t["depth"], kd)][0]
        elif t["mode"] == "ram":
            ab = _bits(t["depth"])
            base, nc = t["base"], len(t["cols"])
            a(f"logic {inst}_hit_c, {inst}_hit; logic [{LW - 1}:0] {inst}_rel;")
            a(f"assign {inst}_rel = tw_wi - {_c(base, LW)};")
            a(f"assign {inst}_hit_c = tw_wen && (tw_wi >= {_c(base, LW)}) && (tw_wi < {_c(base + t['depth'] * nc, LW)});")
            a(f"logic [{max(1, nc) - 1}:0] {inst}_col_c, {inst}_col; logic [{ab - 1}:0] {inst}_wa_c, {inst}_wa;")
            if nc == 1:
                a(f"assign {inst}_col_c = '0; assign {inst}_wa_c = {inst}_rel[{ab - 1}:0];")
            else:
                a(f"assign {inst}_col_c = ({inst}_rel >= {_c(t['depth'], LW)}) ? 1'b1 : 1'b0;")
                a(f"assign {inst}_wa_c = {inst}_col_c ? {ab}'({inst}_rel - {_c(t['depth'], LW)}) : {inst}_rel[{ab - 1}:0];")
            a(f"always_ff @(posedge clk) begin {inst}_hit <= {inst}_hit_c; {inst}_col <= {inst}_col_c; "
              f"{inst}_wa <= {inst}_wa_c; end")
            conn += [f".we({inst}_hit)", f".wa({inst}_wa)", f".wcol({inst}_col)", ".wd(tw_wd_q)"]
            mod = ramShapes[(tuple(t["cols"]), t["depth"], t.get("kind"))]
        else:
            mod = mod_rom
            if MX:
                conn[1] = f".addr({{{'dmidx_a' if t.get('use') == 'twist' else 'cmidx_a'}, {addr}}})"
        conn += [f".q{i}({o})" for i, o in enumerate(outs)]
        a(f"{mod} {inst} ({', '.join(conn)});")

    for j in range(B):
        t, tc = tabs[2 * j], tabs[2 * j + 1]
        outs = [f"twr{j}"] + ([f"twpr{j}"] if len(t["cols"]) > 1 else [])
        couts = [f"tcr{j}"] + ([f"tcpr{j}"] if len(t["cols"]) > 1 else [])
        for o, co, cw in zip(outs, couts, t["cols"]):
            a(f"logic [{cw - 1}:0] {o}, {co}, {o}_q;")
        table_inst(t, f"u_tw{j}", f"{name}_tw{2 * j}", "ta0" if (sp.shareInv and j == 0) else "ta", outs)
        table_inst(tc, f"u_tc{j}", f"{name}_tw{2 * j + 1}", "tca", couts)
    for j in range(B):
        jj = (B - j) % B
        for o, co in ((f"twr", f"tcr"), (f"twpr", f"tcpr"))[:len(tabs[2 * j]["cols"])]:
            if sp.shareInv and jj != j and DDL and inl:      # the direction of the read's own polynomial
                dm = qsig("tmx", "DIR", R + 1)
                a(f"always_ff @(posedge clk) {o}{j}_q <= tsel_r ? ({dm} ? {o}{jj} : {o}{j}) : ({dm} ? {co}{jj} : {co}{j});")
            elif sp.shareInv and jj != j:
                a(f"always_ff @(posedge clk) {o}{j}_q <= tsel_r ? ({dirs} ? {o}{jj} : {o}{j}) : ({dirs} ? {co}{jj} : {co}{j});")
            else:
                a(f"always_ff @(posedge clk) {o}{j}_q <= tsel_r ? {o}{j} : {co}{j};")

    # --- butterflies --------------------------------------------------------------------
    a(f"// ---- {B} butterflies ({bs.name}, latency {Pbu}), output register / x2^-1 halver")
    for j in range(B):
        conn = [".clk(clk)", f".aIn(op{2 * j})", f".bIn(op{2 * j + 1})", f".W(twr{j}_q)"]
        if len(tabs[2 * j]["cols"]) > 1:
            conn.append(f".WP(twpr{j}_q)")
        for pn, _ in bs.extraPorts:
            if pn not in ("W", "WP"):
                conn.append(f".{pn}({qsig(f'b{j}q', pn, K - Pbu)})")
        a(f"logic [{bs.aOutBitWidth - 1}:0] xr{j}; logic [{bs.bOutBitWidth - 1}:0] yr{j};")
        conn += [f".aOut(xr{j})", f".bOut(yr{j})"]
        a(f"{bs.name} u_bu{j} ({', '.join(conn)});")
        ext = lambda sig, bw: sig if bw == W else f"{{{W - bw}'d0, {sig}}}"
        xv, yv = ext(f"xr{j}", bs.aOutBitWidth), ext(f"yr{j}", bs.bOutBitWidth)
        if sp.shareInv:
            xv, yv = f"(cb_sw[{K - 1}][{j}] ? {yv} : {xv})", f"(cb_sw[{K - 1}][{j}] ? {xv} : {yv})"
        for v, dst in ((xv, f"xo{j}"), (yv, f"yo{j}")):
            a(f"logic [{W - 1}:0] {dst}, {dst}_x; assign {dst}_x = {v};")
            if sp.halve:
                qh = qsig(f"h{j}q" if inl else f"b{j}q", "QHALF", K) if "QHALF" in qw else _c((sp.q + 1) // 2, W)
                hdir = dirs
                if DDL and inl:       # the direction of the operation's own polynomial
                    hdir = qsig(f"h{j}q", "DIR", K)
                if (dpp and not inl) or (MDIR and mbub):     # one more register, as the constants' copies: the direction switches after the bubble
                    hdir = f"b{j}q_DIR"
                    if hdir not in qcopies:
                        qcopies.add(hdir)
                        a(f"(* max_fanout = 16 *) logic {hdir}; always_ff @(posedge clk) {hdir} <= DIR_r;")
                a(f"always_ff @(posedge clk) {dst} <= {hdir} ? ({W}'({dst}_x >> 1) + ({dst}_x[0] ? {W}'({qh}) : {_c(0, W)})) : {dst}_x;")
            else:
                a(f"always_ff @(posedge clk) {dst} <= {dst}_x;")

    # --- write mux and write ports ------------------------------------------------------------
    a("// ---- write back in place (sources per bank: IterativeNTTScheme.readSources), or the fill")
    for k in range(P):
        nm = f"wdat{k}"
        a(f"logic [{W - 1}:0] {nm};")
        srcs = [f"{'xo' if o == 0 else 'yo'}{j}" for j, o in ws[k]]
        if len(srcs) == 1:
            a(f"assign {nm} = {srcs[0]};")
        else:
            a("always_comb case (wc%d)" % k)
            for i, sname in enumerate(srcs):
                a(f"    {_c(i, wcw[k])}: {nm} = {sname};")
            a(f"    default: {nm} = {srcs[0]};")
            a("endcase")
        top = k >> b
        waddr = f"(w_f ? w_hA : w_hB)" if top else f"(w_f ? w_hB : w_hA)"
        # fill: bank k takes lane (k ^ (fpi << b)) & (io-1) when that point is in this beat
        k0, k1 = k, k ^ (1 << b)
        if lsub:
            fwe = f"(fpi ? (fsub == {_c(k1 >> (io.bit_length() - 1), lsub)}) : (fsub == {_c(k0 >> (io.bit_length() - 1), lsub)}))"
        else:
            fwe = "1'b1"
        l0, l1 = k0 & (io - 1), k1 & (io - 1)
        fdat = f"x_in_{l0}" if l0 == l1 else f"(fpi ? x_in_{l1} : x_in_{l0})"
        for X in (0, 1):
            m = f"m{X}_{k}"
            a("always_ff @(posedge clk) begin")
            a(f"    if (rst) {m}_we <= 1'b0;")
            a(f"    else if (w_v && w_set == 1'b{X}) begin {m}_we <= 1'b1; {m}_wa <= {waddr}; {m}_wd <= {nm}; end")
            a(f"    else if (acc && fset == 1'b{X} && {fwe}) begin {m}_we <= 1'b1; {m}_wa <= frow; {m}_wd <= {fdat}; end")
            a(f"    else {m}_we <= 1'b0;")
            a("end")

    # --- output stream ------------------------------------------------------------------------
    a("// ---- output: lane l of beat (row, sub) is bank ((sub*io + l) ^ (parity(row) << b))")
    for k in range(P):
        a(f"logic [{W - 1}:0] drd{k}; assign drd{k} = db_set[{R}] ? m1_{k}_rd : m0_{k}_rd;")
    nsub = 1 << lsub
    for l in range(io):
        a(f"logic [{W - 1}:0] yr_{l};")
        a("always_ff @(posedge clk) case ({db_sub[%d], db_pi[%d]})" % (R, R))
        for sub in range(nsub):
            for pi in (0, 1):
                kk = (sub * io + l) ^ (pi << b)
                a(f"    {{{_c(sub, DSUB)}, 1'b{pi}}}: yr_{l} <= drd{kk};")
        a(f"    default: yr_{l} <= drd{l};")
        a("endcase")
    a("logic yv; always_ff @(posedge clk) yv <= rst ? 1'b0 : db_v[%d];" % R)
    if tw is not None:
        dp = tw["datapath"]
        pw = dp.wire(dict(dp.outputs)["P"]).bitWidth
        ain = {x.name: x.bitWidth for x in dp.inputs}
        tq = "".join(f", .{x.name}({qsig('twq', x.name)})" for x in dp.inputs if x.name not in ("A", "B"))
        TTA = _bits(ttabs[0].get("depth1", ttabs[0]["depth"]))
        a(f"(* max_fanout = 16 *) logic [{TTA - 1}:0] tta;")
        if rtw:
            # two copies of one direction (the job's), copy = the drained set; written from the record's twist
            # region: beat lk carries TT factors m = lk TT .. lk TT + TT - 1 (lane m mod io, beat m / io)
            TT = sp.twistLanes
            TTW = TT.bit_length() - 1
            IOB = (io // TT).bit_length() - 1
            TEWt = sum(sp.twEntryCols)
            a(f"always_ff @(posedge clk) tta <= {{dset, {FBW}'(dptr)}};")
            a(f"(* max_fanout = 16 *) logic [{TTA - 1}:0] tw_wa;")
            a(f"always_ff @(posedge clk) tw_wa <= {{lcopyT, {FBW}'(lk >> {IOB})}};")
            a(f"logic tw_go; assign tw_go = tacc && (lst == L_DATA) && (ls == {_c(L, SWL)});")
            for l, t in enumerate(ttabs):
                gm = f" && (lk[{IOB - 1}:0] == {_c(l // TT, IOB)})" if IOB else ""
                cw = t['cols'][0]
                a(f"logic tw_we{l}; logic [{cw - 1}:0] tw_wd{l};")
                a(f"always_ff @(posedge clk) begin tw_we{l} <= !rst && tw_go{gm}; "
                  f"tw_wd{l} <= tw_data[{(l % TT) * TEWt + cw - 1}:{(l % TT) * TEWt}]; end")
        else:
            off = f" + ({'ddir' if mr else dirs} ? {_c(NB, TTA)} : {_c(0, TTA)})" if sp.dirPort else ""
            a(f"always_ff @(posedge clk) tta <= {TTA}'(dptr){off};")
        if mr:
            # the drained polynomial's index with the address; its constants with the data at the multipliers
            a(f"logic [{MB - 1}:0] dmidx_a, dmd [{R + 1}];")
            a(f"always_ff @(posedge clk) begin dmidx_a <= dmidx; dmd[0] <= dmidx; "
              f"for (int i = 1; i <= {R}; i++) dmd[i] <= dmd[i-1]; end")
            tqn = {}
            for x in dp.inputs:
                if x.name in ("A", "B"):
                    continue
                wq = qw[x.name]
                a(f"(* max_fanout = 16 *) logic [{wq - 1}:0] tq_{x.name}; "
                  f"always_ff @(posedge clk) tq_{x.name} <= mt_{x.name}(dmd[{R}]);")
                tqn[x.name] = f"tq_{x.name}"
            tq = "".join(f", .{k}({v})" for k, v in tqn.items())
        if rtw:
            # the twist multipliers' constants per drained set: captured at the compute start, selected per drain
            tqn = {}
            for x in dp.inputs:
                if x.name in ("A", "B"):
                    continue
                wq = qw[x.name]
                a(f"logic [{wq - 1}:0] tqs0_{x.name}, tqs1_{x.name}; (* max_fanout = 16 *) logic [{wq - 1}:0] tq_{x.name};")
                a(f"always_ff @(posedge clk) begin if (!rst && startc) begin if (cnext) tqs1_{x.name} <= nkeep ? "
                  f"{x.name}_r : {x.name}_n; else tqs0_{x.name} <= nkeep ? {x.name}_r : {x.name}_n; end "
                  f"tq_{x.name} <= dset ? tqs1_{x.name} : tqs0_{x.name}; end")
                tqn[x.name] = f"tq_{x.name}"
            tq = "".join(f", .{k}({v})" for k, v in tqn.items())
        for l, t in enumerate(ttabs):
            a(f"logic [{t['cols'][0] - 1}:0] ttr{l}, ttr{l}_q; logic [{pw - 1}:0] tp{l};")
            a(f"always_ff @(posedge clk) ttr{l}_q <= ttr{l};")
            if rtw:
                a(f"{name}_ttr u_tt{l} (.clk(clk), .addr(tta), .we(tw_we{l}), .wa(tw_wa), .wd(tw_wd{l}), .q0(ttr{l}));")
            else:
                table_inst(t, f"u_tt{l}", f"{name}_tt{l}", "tta", [f"ttr{l}"])
            av = f"yr_{l}" if ain["A"] == W else f"{ain['A']}'(yr_{l})"
            a(f"{dp.name} u_twist{l} (.clk(clk), .A({av}), .B(ttr{l}_q){tq}, .P(tp{l}));")
            a(f"assign y_out_{l} = tp{l};")
        TLAT = tw["latency"]          # (not TL: that is the record stream's entries a beat, in the manifest)
        if TLAT:
            a(f"logic [{TLAT - 1}:0] ovd; always_ff @(posedge clk) ovd <= rst ? '0 : "
              + (f"{{ovd[{TLAT - 2}:0], yv}};" if TLAT > 1 else "yv;"))
            a(f"assign out_valid = ovd[{TLAT - 1}];")
        else:
            a("assign out_valid = yv;")
    else:
        for l in range(io):
            a(f"assign y_out_{l} = yr_{l};")
        a("assign out_valid = yv;")
    if mr:
        _mrom_otag(a, MB, MDIR, TG, R + 2 + (tw["latency"] if tw is not None else 0))

    hdr = (f"// {name}: iterative NTT, n={sp.n}, {B} butterflies over 2 x {P} banks of {T} x {W} bits, "
           f"{io} I/O lanes, {'q=' + str(sp.q) if sp.q else 'run-time q'}, direction {sp.direction}, "
           f"butterfly latency {Pbu}, write-back latency {Pw}, stage gaps {list(sp.gaps)}")
    if mr:
        hdr += (f"\n// moduli= {list(mr['moduli'])} in the ROMs (MIDX / DIR with a polynomial's first input beat), "
                f"qSwitch {'inline' if inl else 'bubble'}")
    top = ["`timescale 1ns / 1ps", hdr, f"module {name} (\n" + ",\n".join(ports) + "\n    );"] + O + ["endmodule"]
    with open(os.path.join(rtl, f"{name}.sv"), "w", encoding="utf-8") as f:
        f.write("\n".join(top) + "\n")

    # --- testbench -------------------------------------------------------------------------------
    if tb is not None:
        tv = "testvectors"
        os.makedirs(tv, exist_ok=True)
        NX, NY, NC = len(tb["x"]), len(tb["y"]), tb["cycles"]
        for l in range(io):
            with open(os.path.join(tv, f"x_{l}.txt"), "w") as f:
                f.write("".join(to_twos_complement_hex(bt[l], W) + "\n" for bt in tb["x"]))
            with open(os.path.join(tv, f"y_{l}.txt"), "w") as f:
                f.write("".join(to_twos_complement_hex(bt[l], sp.outWidth) + "\n" for bt in tb["y"]))
        with open(os.path.join(tv, "ycycle.txt"), "w") as f:
            f.write("".join(f"{c:08x}\n" for c in tb["ycycle"]))
        with open(os.path.join(tv, "valid.txt"), "w") as f:
            f.write("".join(f"{v}\n" for v in tb["valid"]))
        if loadW:
            with open(os.path.join(tv, "tw_load.txt"), "w") as f:
                f.write("".join(to_twos_complement_hex(v, TWW) + "\n" for v in tb["load"]))
        if rns:
            with open(os.path.join(tv, "tw_stream.txt"), "w") as f:
                f.write("".join(to_twos_complement_hex(v, TLW) + "\n" for v in tb["tw"]))
            with open(os.path.join(tv, "twvalid.txt"), "w") as f:
                f.write("".join(f"{v}\n" for v in tb["twvalid"]))
        if mr:
            _mrom_vectors(tv, tb)
        with open(os.path.join(rtl, f"{name}_tb.sv"), "w", encoding="utf-8") as f:
            f.write(_tb(sp, tb, NX, NY, NC, TWW))
    manifest = {"top_name": name, "n": sp.n, "butterflies": B, "io_lanes": io, "banks": 2 * P, "bank_depth": T,
                "width": W, "out_width": sp.outWidth, "bu_latency": Pbu, "write_latency": Pw,
                "out_latency": sp.outLatency, "gaps": list(sp.gaps), "q_ports": [p for p, _ in qports],
                "q_port_widths": [w for _, w in qports], "load_words": loadW, "tw_width": TWW,
                "dir_port": sp.dirPort, "mem_style": sp.memStyle, "twiddle_style": sp.twiddleStyle,
                "read_sources": [len(x) for x in rs], "write_sources": [len(x) for x in ws]}
    if rns:
        manifest.update(twiddle_buffer=sp.twiddleBuffer, tw_lanes=TL, tw_entry_cols=ecols, tw_beat_width=TLW,
                        header_beats=HB, header_layout=[list(x) for x in sp.headerLayout], stage_beats=NBs,
                        q_bubble=0 if inl else QB)
    if rec:
        manifest.update(twiddle_source="rec", rec_group=rc["group"], rec_generators=B // rc["group"],
                        rec_units=rc["units"], rec_gen_latency=rc["genLatency"], rec_store=rc["plan"]["SD"],
                        rec_factor_layout=[list(x) for x in rc["factorLayout"]])
        if rc["plan"].get("K"):                  # recSeeds: entries on the record stream after the header
            manifest.update(rec_seeds=rc["plan"]["K"], rec_seed_beats=rc["streamBeats"],
                            rec_seed_words=rc["plan"]["seedWords"],
                            rec_seeds_per_stage=list(rc["plan"]["kk"]))
    if mr:
        manifest.update(moduli=list(mr["moduli"]), midx_bits=MB, q_switch="inline" if inl else "bubble",
                        q_bubble=0 if inl else mr["bubble"], modulus_table={k: list(v) for k, v in mr["table"].items()})
    with open("manifest.json", "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    return manifest


def _mrom_vectors(tv: str, tb: dict):
    """moduli=: per polynomial its modulus index and direction (testvectors/midx.txt, dir.txt)."""
    with open(os.path.join(tv, "midx.txt"), "w") as f:
        f.write("".join(f"{v:x}\n" for v in tb["midx"]))
    with open(os.path.join(tv, "dir.txt"), "w") as f:
        f.write("".join(f"{v}\n" for v in tb["dirs"]))


def _tb(sp, tb, NX, NY, NC, TWW) -> str:
    io, W, OW = sp.io, sp.width, sp.outWidth
    qports, loadW = sp.qPorts, sp.loadWords
    rns = getattr(sp, "twiddleBuffer", "single") != "single"
    if rns:
        qports = ()                                 # the modulus comes in each polynomial's record
        TLW = sp.twLanes * sum(sp.twEntryCols)
        NTW = len(tb["tw"])
    L = ["`timescale 1ns / 1ps", f"module {sp.name}_tb ();", "    logic clk = 1'b0;", "    always #5 clk = ~clk;",
         "    logic rst, in_valid, in_ready, out_valid;"]
    mr = getattr(sp, "mrom", None)
    if mr:
        qports = ()                                 # the modulus is MIDX, with each polynomial's first beat
        MB, MDIR, NPOL = mr["bits"], sp.dirPort, len(tb["midx"])
        L.append(f"    logic [{MB - 1}:0] MIDX, midx_out; logic DIR, dir_out; logic [{MB - 1}:0] midx_ts [{NPOL}]; "
                 f"logic dir_ts [{NPOL}];")
    elif sp.dirPort:
        L.append(f"    logic DIR = 1'b{tb['dir']};")
    for qp, w in qports:
        L.append(f"    logic [{w - 1}:0] {qp} = {_h(tb['q'][qp], w)};")
    if loadW:
        L.append(f"    logic tw_rst, tw_wen; logic [{TWW - 1}:0] tw_wdata; logic [{TWW - 1}:0] tw_ts [{loadW}];")
    if rns:
        L.append(f"    logic tw_valid, tw_ready; logic [{TLW - 1}:0] tw_data; logic [{TLW - 1}:0] tw_ts [{NTW}]; "
                 f"logic twpat [{NC}];")
    for l in range(io):
        L.append(f"    logic [{W - 1}:0] x_in_{l}; logic [{W - 1}:0] x_ts_{l} [{NX}];")
        L.append(f"    logic [{OW - 1}:0] y_out_{l}; logic [{OW - 1}:0] y_ts_{l} [{NY}];")
    L.append(f"    logic [31:0] ycyc [{NY}]; logic vpat [{NC}];")
    L.append("    initial begin")
    for l in range(io):
        L.append(f'        $readmemh("../../../../../testvectors/x_{l}.txt", x_ts_{l});')
        L.append(f'        $readmemh("../../../../../testvectors/y_{l}.txt", y_ts_{l});')
    L.append('        $readmemh("../../../../../testvectors/ycycle.txt", ycyc);')
    L.append('        $readmemh("../../../../../testvectors/valid.txt", vpat);')
    if loadW:
        L.append('        $readmemh("../../../../../testvectors/tw_load.txt", tw_ts);')
    if rns:
        L.append('        $readmemh("../../../../../testvectors/tw_stream.txt", tw_ts);')
        L.append('        $readmemh("../../../../../testvectors/twvalid.txt", twpat);')
    if mr:
        L.append('        $readmemh("../../../../../testvectors/midx.txt", midx_ts);')
        L.append('        $readmemh("../../../../../testvectors/dir.txt", dir_ts);')
    L.append("    end")
    conn = [".clk(clk)", ".rst(rst)"] + ([".DIR(DIR)"] if sp.dirPort else []) + [f".{qp}({qp})" for qp, _ in qports]
    if mr:
        conn += [".MIDX(MIDX)", ".midx_out(midx_out)"] + ([".dir_out(dir_out)"] if MDIR else [])
    if loadW:
        conn += [".tw_rst(tw_rst)", ".tw_wen(tw_wen)", ".tw_wdata(tw_wdata)"]
    if rns:
        conn += [".tw_valid(tw_valid)", ".tw_ready(tw_ready)", ".tw_data(tw_data)"]
    conn += [".in_valid(in_valid)", ".in_ready(in_ready)"] + [f".x_in_{l}(x_in_{l})" for l in range(io)]
    conn += [".out_valid(out_valid)"] + [f".y_out_{l}(y_out_{l})" for l in range(io)]
    L.append(f"    {sp.name} DUT ({', '.join(conn)});")
    IV = tb.get("interval")                         # rate check: first beats of successive polynomials
    NBP = getattr(sp, "beats", 0)
    L.append("    int c, bad, xb, ob, late" + (", twb" if rns else "") + (", slow, pfirst" if IV else "")
             + (", tagbad" if mr else "") + ";")
    L.append("    initial begin")
    L.append("        bad = 0; xb = 0; ob = 0; late = 0; rst = 1'b1; in_valid = 1'b0;")
    if IV:
        L.append("        slow = 0; pfirst = 0;")
    if mr:
        L.append("        tagbad = 0; MIDX = '0; DIR = 1'b0;")
    if rns:
        L.append("        twb = 0; tw_valid = 1'b0; tw_data = '0;")
    for l in range(io):
        L.append(f"        x_in_{l} = '0;")
    if loadW:
        L.append("        tw_rst = 1'b1; tw_wen = 1'b0; tw_wdata = '0;")
        L.append("        repeat (2) @(posedge clk);")
        L.append("        #1 tw_rst = 1'b0;")
        L.append(f"        for (c = 0; c < {loadW}; c++) begin tw_wen = 1'b1; tw_wdata = tw_ts[c]; @(posedge clk); #1; end")
        L.append("        tw_wen = 1'b0;")
    L.append("        repeat (30) @(posedge clk);")
    L.append(f"        for (c = 0; c < {NC}; c++) begin")
    L.append("            #1;")
    L.append("            rst = 1'b0;")
    L.append(f"            in_valid = vpat[c] && (xb < {NX});")
    if rns:
        L.append(f"            tw_valid = twpat[c] && (twb < {NTW});")
        L.append(f"            tw_data = (twb < {NTW}) ? tw_ts[twb] : '0;")
    for l in range(io):
        L.append(f"            x_in_{l} = (xb < {NX}) ? x_ts_{l}[xb] : '0;")
    if mr:      # valid with a polynomial's first beat only: the complement on every other beat
        L.append(f"            if (xb < {NX} && (xb % {NBP} == 0)) begin MIDX = midx_ts[xb / {NBP}]; DIR = dir_ts[xb / {NBP}]; end")
        L.append(f"            else if (xb < {NX}) begin MIDX = ~midx_ts[xb / {NBP}]; DIR = ~dir_ts[xb / {NBP}]; end")
        L.append("            else begin MIDX = '1; DIR = 1'b1; end")
    L.append("            #2;")
    L.append("            if (out_valid) begin")
    L.append(f"                if (ob >= {NY}) begin bad++; if (bad < 10) $display(\"WRONG extra output beat at cycle %0d\", c); end")
    L.append("                else begin")
    L.append("                    if (c != ycyc[ob]) begin late++; if (late < 5) "
             "$display(\"WRONG beat %0d at cycle %0d, the model says %0d\", ob, c, ycyc[ob]); end")
    for l in range(io):
        L.append(f"                    if (y_out_{l} !== y_ts_{l}[ob]) begin bad++; if (bad < 10) "
                 f"$display(\"WRONG beat %0d lane {l}: got %h want %h\", ob, y_out_{l}, y_ts_{l}[ob]); end")
    if mr:
        L.append(f"                    if (midx_out !== midx_ts[ob / {NBP}]" + (f" || dir_out !== dir_ts[ob / {NBP}]" if MDIR else "")
                 + ") begin tagbad++; if (tagbad < 5) $display(\"WRONG tag on beat %0d: midx_out %0d\", ob, midx_out); end")
    if IV:
        L.append(f"                    if (ob % {NBP} == 0) begin")
        L.append(f"                        if (ob != 0 && c - pfirst > {IV}) begin slow++; if (slow < 5) $display(\"WRONG rate: "
                 f"polynomial %0d starts %0d cycles after the one before, the model's interval is {IV}\", "
                 f"ob / {NBP}, c - pfirst); end")
        L.append("                        pfirst = c;")
        L.append("                    end")
    L.append("                    ob++;")
    L.append("                end")
    L.append("            end")
    L.append("            if (in_valid && in_ready) xb++;")
    if rns:
        L.append("            if (tw_valid && tw_ready) twb++;")
    L.append("            @(posedge clk);")
    L.append("        end")
    L.append(f"        if (ob != {NY}) begin bad++; $display(\"WRONG: %0d of {NY} output beats\", ob); end")
    L.append(f"        if (xb != {NX}) begin bad++; $display(\"WRONG: %0d of {NX} input beats accepted\", xb); end")
    if rns:
        L.append(f"        if (twb != {NTW}) begin bad++; $display(\"WRONG: %0d of {NTW} record beats accepted\", twb); end")
    L.append("        bad = bad + late;")
    if mr:
        L.append("        bad = bad + tagbad;")
    if IV:
        L.append("        bad = bad + slow;")
    L.append("        if (bad == 0) begin $display(\"SUCCESS!\"); $display(\"PASS All %0d Testvectors!\", ob); end")
    L.append("        else begin $display(\"TO BE DEBUGGED...\"); $display(\"FAILED: %0d wrong\", bad); end")
    L.append("        $finish();")
    L.append("    end")
    L.append("endmodule")
    return "\n".join(L) + "\n"
