"""The port wrapper of the hybrid NTT (outReady, outputOrder='natural', twiddleBuffer='record').

`emit_ports(sp, core_ports, regs, tb)` is called by `HybridNTT_RTL_gen` when the spec names `portTop`; it writes

  RTL_generated/<top>.sv             the wrapper around the core <top>_k: input adapter, admission gate (credit and
                                     record), output buffer, reader, landing FIFO, record loader
  RTL_generated/<top>_pram_<style>.sv  the output buffer's RAM (iter_ntt's simple dual port RAM)
  RTL_generated/<top>_tb.sv          with `tb`: as the core's testbench, with out_ready and the record stream driven
                                     from pattern files; every beat taken is checked for value, tags and cycle
  testvectors/                       x_, y_, tags, ytags, ycycle, valid, oready, twvalid, tw

The twin is `operator_modeling.ntt.hybrid.HybridPorts.simulatePortsJob` (register for register: change both together);
the proof that the buffer cannot overflow is in that module's docstring.

Read pipeline of an issue at cycle t:
  t          issue: slot rs, beat rb (and the reservation of its beats in the landing FIFO)
  t+1        RAM read address register
  t+1+RL     RAM data
  +RT        natural order: the read rotator (by the top U bits of the beat), 4:1 per level
  t+PP-1     the beat in port order (PP = 2 + RL + RT)
  t+PP       push register: landing FIFO write enable (narrow ports: chunk s at t+PP+s)
  t+PP+1     out_valid at the earliest

`sp['ports']['fault']` builds a wrong design on purpose (the gate's negative tests; never set by the model):
'slots' (the buffer has one slot less than the credit allows), 'credit' (the credit limit is one less than the
twin's), 'norok' (admission does not wait for the record), 'norot' (no read rotation).
"""
from __future__ import annotations

import os
import re

from rtl_gen.hybrid_ntt import _bits, _c

ST = {"HDR": 0, "WAITF": 1, "DATA": 2, "SETTLE": 3, "OK": 4}


def _clog(x: int) -> int:
    """Bits of a counter 0 .. x - 1 (0 for x = 1)."""
    return (x - 1).bit_length()


def _wrapper(sp: dict, core_ports: list, regs: list) -> str:
    name, top, W, io, T, U, g = sp["name"], sp["portTop"], sp["W"], sp["io"], sp["T"], sp["U"], sp["g"]
    Wd, OW, MB, DPT, RL = sp["width"], sp["outWidth"], sp["MB"], sp["dirPort"], sp["RL"]
    po = sp["ports"]
    record, natural, direct, oready = po["record"], po["natural"], po["direct"], po["outReady"]
    DP, K, PP, RT, fault = po["DP"], po["K"], po["PP"], po["RT"], po.get("fault")
    MU = 1 << U
    narrow, wide = io < W, io > W
    RHO = W // io if narrow else io // W
    RB = _bits(RHO)
    TBW = _clog(T)
    MBT = 0 if record else MB                 # MIDX at the ports
    std = {"clk", "rst", "in_valid", "in_ready", "out_valid", "MIDX", "DIR", "midx_out", "dir_out"}
    ldp = {"ld_we", "ld_sel", "ld_addr", "ld_data"}
    extra = []
    for p in core_ports:
        pn = re.split(r"\s+", p.strip())[-1]
        if pn in std or re.fullmatch(r"(x_in|y_out)_\d+", pn) or (record and pn in ldp):
            continue
        extra.append((p, pn))
    ports = ["    input  logic clk", "    input  logic rst", "    input  logic in_valid", "    output logic in_ready"]
    if MBT:
        ports.append(f"    input  logic [{MB - 1}:0] MIDX")
    if DPT:
        ports.append("    input  logic DIR")
    ports += [f"    input  logic [{Wd - 1}:0] x_in_{l}" for l in range(io)]
    ports.append("    output logic out_valid")
    if oready:
        ports.append("    input  logic out_ready")
    if MBT:
        ports.append(f"    output logic [{MB - 1}:0] midx_out")
    if DPT:
        ports.append("    output logic dir_out")
    ports += [f"    output logic [{OW - 1}:0] y_out_{l}" for l in range(io)]
    if record:
        NR = len(regs)
        NS = sp["M"]
        SB, LA, LW = _bits(NR), max(_bits(r["depth"]) for r in regs), max(r["width"] for r in regs)
        chunk = [r["depth"] // NS for r in regs]
        assert all(r["depth"] == c * NS for r, c in zip(regs, chunk)), "a load region is not one chunk per set"
        assert po.get("twLanes", 1) == 1, "the record loader is built for twiddleLanes = 1"
        ports += ["    input  logic tw_valid", "    output logic tw_ready", f"    input  logic [{LW - 1}:0] tw_data"]
    ports += [p for p, _ in extra]
    O = []
    a = O.append

    def dly(sig: str, w: int, n: int, nm: str, rst: bool = False) -> str:
        """sig delayed n cycles (registers nm_1 .. nm_n); returns the last name."""
        prev = sig
        for k in range(1, n + 1):
            a(f"    logic {f'[{w - 1}:0] ' if w > 1 else ''}{nm}_{k};")
            a(f"    always_ff @(posedge clk) {nm}_{k} <= {'rst ? 1%sb0 : ' % chr(39) if rst else ''}{prev};")
            prev = f"{nm}_{k}"
        return prev

    def rotator(tag: str, src: list, w: int, sh: str, stages: int) -> list:
        """Per group h a barrel rotator of 2^U words in `stages` registered levels (4:1 each):
        out[h][x] = src[h][(x + sh) mod 2^U], sh valid with src. Returns the output names [h][x]."""
        cur = src
        for k in range(stages):
            nb = min(2, U - 2 * k)
            step = 1 << (2 * k)
            a(f"    logic [{U - 1}:0] {tag}s{k + 1};")
            a(f"    always_ff @(posedge clk) {tag}s{k + 1} <= {sh};")
            nxt = []
            for h in range(g):
                row = []
                for x in range(MU):
                    nm = f"{tag}{k + 1}_{h}_{x}"
                    a(f"    logic [{w - 1}:0] {nm};")
                    row.append(nm)
                nxt.append(row)
                a(f"    always_ff @(posedge clk) case ({sh}[{2 * k + nb - 1}:{2 * k}])")
                for d in range(1 << nb):
                    a(f"        {_c(d, nb)}: begin " + " ".join(f"{row[x]} <= {cur[h][(x + d * step) % MU]};"
                                                               for x in range(MU)) + " end")
                a("    endcase")
            cur, sh = nxt, f"{tag}s{k + 1}"
        return cur

    # ---- the core ---------------------------------------------------------------------------------------------
    a("    logic k_valid, k_ready, k_ov;")
    for l in range(W):
        a(f"    logic [{Wd - 1}:0] k_x_{l}; logic [{OW - 1}:0] k_y_{l};")
    conn = [".clk(clk)", ".rst(rst)", ".in_valid(k_valid)", ".in_ready(k_ready)"]
    if MB:
        a(f"    logic [{MB - 1}:0] k_midx, k_mo;")
        conn += [".MIDX(k_midx)", ".midx_out(k_mo)"]
    if DPT:
        a("    logic k_dir, k_do;")
        conn += [".DIR(k_dir)", ".dir_out(k_do)"]
    conn += [f".x_in_{l}(k_x_{l})" for l in range(W)] + [".out_valid(k_ov)"]
    conn += [f".y_out_{l}(k_y_{l})" for l in range(W)] + [f".{pn}({pn})" for _, pn in extra]
    if record:
        a(f"    logic ld_we; logic [{SB - 1}:0] ld_sel; logic [{LA - 1}:0] ld_addr; logic [{LW - 1}:0] ld_data;")
        conn += [".ld_we(ld_we)", ".ld_sel(ld_sel)", ".ld_addr(ld_addr)", ".ld_data(ld_data)"]
    a(f"    {name} u_core ({', '.join(conn)});")

    # ---- admission gate ---------------------------------------------------------------------------------------
    CRB = _bits(DP + 2) if not direct else 1
    LIM = DP - 1 if fault == "credit" else DP
    a("    // ---- admission: the first beat of a polynomial passes only with a credit (room in the output buffer)"
      + (" and a complete record" if record else ""))
    a("    logic mid, cok, rok, gate, g_rdy, kacc, first, done_r;")
    a(f"    logic [{TBW - 1}:0] bc;")
    a(f"    logic [{CRB - 1}:0] cr, cr_n;")
    a("    assign gate = mid || (cok && rok);")
    a("    assign g_rdy = k_ready && gate;")
    a("    assign first = kacc && !mid;")
    a(f"    assign cr_n = cr + {CRB}'(first) - {CRB}'(done_r);")
    a("    always_ff @(posedge clk) begin")
    a("        if (rst) begin mid <= 1'b0; bc <= '0; cr <= '0; cok <= 1'b1; end")
    a("        else begin")
    a(f"            if (kacc) begin mid <= bc != {_c(T - 1, TBW)}; bc <= bc + 1'b1; end")
    if direct:
        a("            cr <= '0; cok <= 1'b1;")
    else:
        a(f"            cr <= cr_n; cok <= cr_n < {_c(LIM, CRB)};")
    a("        end")
    a("    end")
    if not record:
        a("    assign rok = 1'b1;")
    elif fault == "norok":
        a("    logic rok_r;")
        a("    assign rok = 1'b1;")

    # ---- input adapter (rtl_gen.hybrid_ntt._io_wrapper's, the core's ready behind the gate) ---------------------
    tagc = ([" k_midx <= MIDX;"] if MBT else []) + ([" k_dir <= DIR;"] if DPT else [])
    if record:
        a(f"    logic [{MB - 1}:0] cur, tgt;        // the table set of the next polynomial, the set being written")
        a("    assign k_midx = cur;")
    if not narrow and not wide:
        a("    assign k_valid = in_valid && gate;")
        a("    assign in_ready = g_rdy;")
        a("    assign kacc = in_valid && g_rdy;")
        if MBT:
            a("    assign k_midx = MIDX;")
        if DPT:
            a("    assign k_dir = DIR;")
        for l in range(W):
            a(f"    assign k_x_{l} = x_in_{l};")
    else:
        a("    logic acc, full;")
        a(f"    logic [{RB - 1}:0] ic;")
        a("    assign acc = in_valid && in_ready;")
        a("    assign kacc = full && g_rdy;")
        a("    assign k_valid = full && gate;")
    if narrow:
        a(f"    // ---- input: {RHO} port beats make one core beat; the tags are those of a core beat's first port beat")
        a("    assign in_ready = !full || g_rdy;")
        a("    always_ff @(posedge clk) begin")
        a("        if (rst) begin ic <= '0; full <= 1'b0; end")
        a("        else begin")
        a("            if (acc) ic <= ic + 1'b1;")
        a(f"            if (acc && ic == {_c(RHO - 1, RB)}) full <= 1'b1; else if (kacc) full <= 1'b0;")
        a("        end")
        a("    end")
        a("    always_ff @(posedge clk) if (acc) begin")
        if tagc:
            a(f"        if (ic == '0) begin{''.join(tagc)} end")
        a("        case (ic)")
        for i in range(RHO):
            a(f"            {_c(i, RB)}: begin " + " ".join(f"k_x_{i * io + l} <= x_in_{l};" for l in range(io)) + " end")
        a("        endcase")
        a("    end")
    elif wide:
        a(f"    // ---- input: one port beat is {RHO} core beats; the next port beat enters as the last one leaves")
        a("    logic last;")
        for l in range(io):
            a(f"    logic [{Wd - 1}:0] h_{l};")
        a(f"    assign last = ic == {_c(RHO - 1, RB)};")
        a("    assign in_ready = !full || (kacc && last);")
        a("    always_ff @(posedge clk) begin")
        a("        if (rst) begin ic <= '0; full <= 1'b0; end")
        a("        else begin")
        a("            if (kacc) begin ic <= ic + 1'b1; if (last) full <= 1'b0; end")
        a("            if (acc) full <= 1'b1;")
        a("        end")
        a("    end")
        a("    always_ff @(posedge clk) if (acc) begin")
        a("        " + " ".join(f"h_{l} <= x_in_{l};" for l in range(io)) + "".join(tagc))
        a("    end")
        a("    always_comb begin")
        a("        case (ic)")
        for i in range(RHO):
            a(f"            {_c(i, RB)}: begin " + " ".join(f"k_x_{l} = h_{i * W + l};" for l in range(W)) + " end")
        a("        endcase")
        a("    end")

    # ---- the core's output beats ------------------------------------------------------------------------------
    NSL = DP - 1 if fault == "slots" else DP
    SLB = _clog(NSL) if not direct else 0
    a("    // ---- the core's output: beat and slot counters")
    a(f"    logic [{TBW - 1}:0] wb;")
    a("    logic plast;")
    a(f"    assign plast = k_ov && wb == {_c(T - 1, TBW)};")
    if SLB:
        a(f"    logic [{SLB - 1}:0] ws, rs;")
    a("    always_ff @(posedge clk) begin")
    a("        if (rst) begin wb <= '0;" + (" ws <= '0;" if SLB else "") + " end")
    a("        else if (k_ov) begin")
    a("            wb <= wb + 1'b1;")
    if SLB:
        a(f"            if (wb == {_c(T - 1, TBW)}) ws <= (ws == {_c(NSL - 1, SLB)}) ? '0 : ws + 1'b1;")
    a("        end")
    a("    end")
    TGW = MBT + (1 if DPT else 0)
    tcat = (["k_do"] if DPT else []) + (["k_mo"] if MBT else [])
    if direct:
        a("    // ---- no output buffer: the core's output is the port")
        a("    assign out_valid = k_ov;")
        a("    assign done_r = 1'b0;")
        if MBT:
            a("    assign midx_out = k_mo;")
        if DPT:
            a("    assign dir_out = k_do;")
        for l in range(W):
            a(f"    assign y_out_{l} = k_y_{l};")
    else:
        sty = po["bufStyle"]
        DEP, AW = NSL * T, SLB + TBW
        CHB = TBW - U
        a(f"    // ---- output buffer: {W} RAMs of {NSL} polynomial(s) x {T} beats"
          + (", natural order (bank (h, (i + j) mod 2^U) holds lane (i, h) of natural beat {j, c >> U})" if natural else ""))
        a(f"    logic [{AW - 1}:0] ra;")
        for l in range(W):
            a(f"    logic [{OW - 1}:0] rd_{l};")
        if TGW:
            a(f"    logic [{TGW - 1}:0] otag [{NSL}];")
            a(f"    always_ff @(posedge clk) if (k_ov && wb == '0) otag[{'ws' if SLB else '0'}] <= {{{', '.join(tcat)}}};")
        wsx = "ws, " if SLB else ""
        if not natural:
            for l in range(W):
                a(f"    {top}_pram_{sty} #(.W({OW}), .D({DEP}), .A({AW}), .R({RL})) u_ob{l} (.clk(clk), .we(k_ov), "
                  f".wa({{{wsx}wb}}), .wd(k_y_{l}), .ra(ra), .rd(rd_{l}));")
            a("    logic inc;")
            a("    assign inc = k_ov;")
        else:
            # write side: bank (h, b) takes core lane (h, (b - i) mod 2^U), i = beat mod 2^U, at {slot, b - i, c >> U}
            a(f"    logic [{U - 1}:0] wsh;")
            a(f"    assign wsh = {U}'(0) - wb[{U - 1}:0];")
            wr = rotator("wr", [[f"k_y_{h * MU + j}" for j in range(MU)] for h in range(g)], OW, "wsh", RT)
            wv = dly("k_ov", 1, RT, "wv", rst=True)
            wl = dly("plast", 1, RT, "wl", rst=True)
            wi = dly(f"wb[{U - 1}:0]", U, RT - 1, "wi") if RT > 1 else f"wb[{U - 1}:0]"
            hi = None
            if CHB:
                hi = dly(f"wb[{TBW - 1}:{U}]", CHB, RT, "wc")
            wsd = dly("ws", SLB, RT, "wsl") if SLB else None
            for b in range(MU):
                a(f"    logic [{U - 1}:0] wj_{b};")
                a(f"    always_ff @(posedge clk) wj_{b} <= {_c(b, U)} - {wi};")
            for h in range(g):
                for b in range(MU):
                    l = h * MU + b
                    addr = ", ".join(x for x in (wsd, f"wj_{b}", hi) if x)
                    a(f"    {top}_pram_{sty} #(.W({OW}), .D({DEP}), .A({AW}), .R({RL})) u_ob{l} (.clk(clk), .we({wv}), "
                      f".wa({{{addr}}}), .wd({wr[h][b]}), .ra(ra), .rd(rd_{l}));")
            a("    logic inc;")
            a(f"    assign inc = {wl};")
        # ---- reader
        ACB = _bits(DP + 2) if natural else _bits(DP * T + 2)
        KB = _clog(K)
        a("    // ---- reader: a beat is issued when it is in the buffer and the landing FIFO has room reserved for it")
        a(f"    logic [{TBW - 1}:0] rb;")
        a(f"    logic [{ACB - 1}:0] ac;")
        a(f"    logic [{KB}:0] resv, fc;")
        a("    logic issue, iok, can, rmid, dec, pop, pv, ov;")
        a(f"    logic [{KB}:0] add;")
        if narrow:
            a(f"    logic [{RB - 1}:0] ec;")
            a(f"    assign can = resv <= {_c(K - RHO, KB + 1)} && ec == '0;")
            a(f"    assign add = issue ? {_c(RHO, KB + 1)} : '0;")
        elif wide:
            a(f"    logic [{RB - 1}:0] rc;")
            a(f"    assign can = rc != '0 || resv <= {_c(K - 1, KB + 1)};")
            a(f"    assign add = {KB + 1}'(issue && rc == '0);")
        else:
            a(f"    assign can = resv <= {_c(K - 1, KB + 1)};")
            a(f"    assign add = {KB + 1}'(issue);")
        if natural:
            a("    assign iok = rmid || ac != '0;       // a polynomial is read once it is complete in the buffer")
            a("    assign dec = issue && !rmid;")
        else:
            a("    assign iok = ac != '0;")
            a("    assign dec = issue;")
        a("    assign issue = iok && can;")
        a("    logic done_q;")
        a("    assign done_r = done_q;")
        a("    always_ff @(posedge clk) begin")
        a("        if (rst) begin rb <= '0; ac <= '0; resv <= '0; rmid <= 1'b0; done_q <= 1'b0;"
          + (" rs <= '0;" if SLB else "") + (" ec <= '0;" if narrow else "") + (" rc <= '0;" if wide else "") + " end")
        a("        else begin")
        a("            if (issue) begin")
        a(f"                rb <= rb + 1'b1; rmid <= rb != {_c(T - 1, TBW)};")
        if SLB:
            a(f"                if (rb == {_c(T - 1, TBW)}) rs <= (rs == {_c(NSL - 1, SLB)}) ? '0 : rs + 1'b1;")
        if wide:
            a("                rc <= rc + 1'b1;")
        a("            end")
        if narrow:
            a("            if (issue || ec != '0) ec <= ec + 1'b1;")
        a(f"            done_q <= issue && rb == {_c(T - 1, TBW)};")
        a(f"            ac <= ac + {ACB}'(inc) - {ACB}'(dec);")
        a(f"            resv <= resv + add - {KB + 1}'(pop);")
        a("        end")
        a("    end")
        a("    // (held between issues: a narrow port takes the beat's chunks over several cycles)")
        a(f"    always_ff @(posedge clk) if (issue) ra <= {{{'rs, ' if SLB else ''}rb}};")
        vd = dly("issue", 1, PP - 1, "rv", rst=True)
        if natural:
            a(f"    logic [{U - 1}:0] rj_0;")
            a(f"    always_ff @(posedge clk) if (issue) rj_0 <= rb[{TBW - 1}:{TBW - U}];")
            jsrc = dly("rj_0", U, RL, "rj")
            if fault == "norot":
                a(f"    logic [{U - 1}:0] rj_z;")
                a("    assign rj_z = '0;                    // FAULT built on purpose: no read rotation")
                jsrc = "rj_z"
            rq2 = rotator("rr", [[f"rd_{h * MU + b}" for b in range(MU)] for h in range(g)], OW, jsrc, RT)
            rq = [rq2[nl % g][nl // g] for nl in range(W)]      # natural lane nl = i g + h
        else:
            rq = [f"rd_{l}" for l in range(W)]
        if TGW:
            a(f"    logic [{TGW - 1}:0] tq_0;")
            a(f"    always_ff @(posedge clk) tq_0 <= otag[{'rs' if SLB else '0'}];")
            tgd = dly("tq_0", TGW, PP - 2, "tq") if PP > 2 else "tq_0"
            a(f"    logic [{TGW - 1}:0] ptag;")
            a(f"    always_ff @(posedge clk) if ({vd}) ptag <= {tgd};")
        a("    // ---- push register: the port beat")
        for l in range(io):
            a(f"    logic [{OW - 1}:0] pd_{l};")
        if narrow:
            a(f"    logic [{RB - 1}:0] ci, cs;")
            a("    logic cvn;")
            a(f"    assign cs = {vd} ? '0 : ci;")
            a(f"    assign cvn = {vd} || ci != '0;")
            a("    always_ff @(posedge clk) begin")
            a("        if (rst) begin ci <= '0; pv <= 1'b0; end")
            a("        else begin pv <= cvn; if (cvn) ci <= cs + 1'b1; end")
            a("    end")
            a("    always_ff @(posedge clk) case (cs)")
            for i in range(RHO):
                a(f"        {_c(i, RB)}: begin " + " ".join(f"pd_{l} <= {rq[i * io + l]};" for l in range(io)) + " end")
            a("    endcase")
        elif wide:
            sd = dly("rc", RB, PP - 1, "rsub")
            a(f"    always_ff @(posedge clk) pv <= rst ? 1'b0 : ({vd} && {sd} == {_c(RHO - 1, RB)});")
            a(f"    always_ff @(posedge clk) if ({vd}) case ({sd})")
            for i in range(RHO):
                a(f"        {_c(i, RB)}: begin " + " ".join(f"pd_{i * W + l} <= {rq[l]};" for l in range(W)) + " end")
            a("    endcase")
        else:
            a(f"    always_ff @(posedge clk) pv <= rst ? 1'b0 : {vd};")
            a("    always_ff @(posedge clk) begin " + " ".join(f"pd_{l} <= {rq[l]};" for l in range(io)) + " end")
        # ---- landing FIFO
        LWD = io * OW + TGW
        a(f"    // ---- landing FIFO ({K} port beats, LUT RAM): out_ready feeds only its read pointer, the counters fc and")
        a("    // resv and the flag ov")
        a(f"    (* ram_style = \"distributed\" *) logic [{LWD - 1}:0] lmem [{K}];")
        a(f"    logic [{LWD - 1}:0] lq;")
        a(f"    logic [{KB - 1}:0] lw, lr;")
        a(f"    logic [{KB}:0] fc_n;")
        cat = (["ptag"] if TGW else []) + [f"pd_{l}" for l in reversed(range(io))]
        a(f"    always_ff @(posedge clk) if (pv) lmem[lw] <= {{{', '.join(cat)}}};")
        a("    assign lq = lmem[lr];")
        a(f"    assign pop = ov && {'out_ready' if oready else '1%sb1' % chr(39)};")
        a(f"    assign fc_n = fc + {KB + 1}'(pv) - {KB + 1}'(pop);")
        a("    always_ff @(posedge clk) begin")
        a("        if (rst) begin lw <= '0; lr <= '0; fc <= '0; ov <= 1'b0; end")
        a("        else begin")
        a("            if (pv) lw <= lw + 1'b1;")
        a("            if (pop) lr <= lr + 1'b1;")
        a("            fc <= fc_n; ov <= fc_n != '0;")
        a("        end")
        a("    end")
        a("    assign out_valid = ov;")
        for l in range(io):
            a(f"    assign y_out_{l} = lq[{l * OW} +: {OW}];")
        if MBT:
            a(f"    assign midx_out = lq[{io * OW} +: {MB}];")
        if DPT:
            a(f"    assign dir_out = lq[{io * OW + MBT}];")

    # ---- record loader --------------------------------------------------------------------------------------
    if record:
        LDL = po["LDL"]
        RIB = _bits(NR)
        SCB = _bits(LDL + 1)
        a(f"    // ---- record stream: a header (bit 0: keep the set) and the {sum(chunk)} entries of one modulus "
          f"({NR} regions in load-map order);")
        a(f"    // {NS} table sets, the next record goes to the next set once no polynomial in flight uses it")
        a(f"    logic [2:0] st;")
        a("    logic have, tacc, rlast, dlast;")
        a(f"    logic [{SCB - 1}:0] sc;")
        a(f"    logic [{RIB - 1}:0] ri;")
        a(f"    logic [{LA - 1}:0] la, cm1, lbase;")
        a(f"    logic [4:0] use_ [{NS}];")
        a(f"    assign tw_ready = st == 3'd{ST['HDR']} || st == 3'd{ST['DATA']};")
        a("    assign tacc = tw_valid && tw_ready;")
        a("    always_comb begin")
        a("        case (ri)")
        for k, cnk in enumerate(chunk):
            a(f"            {_c(k, RIB)}: cm1 = {_c(cnk - 1, LA)};")
        a("            default: cm1 = '0;")
        a("        endcase")
        a("    end")
        a("    assign rlast = la == cm1;")
        a(f"    assign dlast = rlast && ri == {_c(NR - 1, RIB)};")
        rokn = "rok_r" if fault == "norok" else "rok"
        if fault != "norok":
            pass
        a("    always_ff @(posedge clk) begin")
        a(f"        if (rst) begin st <= 3'd{ST['HDR']}; cur <= '0; tgt <= '0; have <= 1'b0; {rokn} <= 1'b0; sc <= '0; "
          f"ri <= '0; la <= '0; end")
        a("        else begin")
        a("            case (st)")
        a(f"                3'd{ST['HDR']}: if (tacc) begin")
        a(f"                    if (tw_data[0] && have) begin st <= 3'd{ST['OK']}; {rokn} <= 1'b1; end")
        a("                    else begin")
        a(f"                        tgt <= have ? ((cur == {_c(NS - 1, MB)}) ? '0 : cur + 1'b1) : '0;")
        a(f"                        st <= 3'd{ST['WAITF']}; ri <= '0; la <= '0;")
        a("                    end")
        a("                end")
        a(f"                3'd{ST['WAITF']}: if (use_[tgt] == '0) st <= 3'd{ST['DATA']};")
        a(f"                3'd{ST['DATA']}: if (tacc) begin")
        a("                    if (rlast) begin la <= '0; ri <= ri + 1'b1; end else la <= la + 1'b1;")
        a(f"                    if (dlast) begin st <= 3'd{ST['SETTLE']}; sc <= {_c(LDL - 1, SCB)}; end")
        a("                end")
        a(f"                3'd{ST['SETTLE']}: begin")
        a(f"                    if (sc == '0) begin st <= 3'd{ST['OK']}; {rokn} <= 1'b1; cur <= tgt; have <= 1'b1; end")
        a("                    else sc <= sc - 1'b1;")
        a("                end")
        a(f"                default: if (first) begin st <= 3'd{ST['HDR']}; {rokn} <= 1'b0; end")
        a("            endcase")
        a("        end")
        a("    end")
        a("    always_ff @(posedge clk) begin")
        a(f"        for (int s = 0; s < {NS}; s++) begin")
        a("            if (rst) use_[s] <= '0;")
        a(f"            else use_[s] <= use_[s] + 5'(first && cur == {MB}'(s)) - 5'(plast && k_mo == {MB}'(s));")
        a("        end")
        a("    end")
        a("    // the entry's address: its set's base in the region + the entry number (two registers to the core's port)")
        a("    always_comb begin")
        a("        case ({ri, tgt})")
        for k, cnk in enumerate(chunk):
            for s_ in range(NS):
                a(f"            {{{_c(k, RIB)}, {_c(s_, MB)}}}: lbase = {_c(s_ * cnk, LA)};")
        a("            default: lbase = '0;")
        a("        endcase")
        a("    end")
        a(f"    logic l1_v; logic [{RIB - 1}:0] l1_ri; logic [{LA - 1}:0] l1_la, l1_b; logic [{LW - 1}:0] l1_d;")
        a("    always_ff @(posedge clk) begin")
        a(f"        l1_v <= rst ? 1'b0 : (tacc && st == 3'd{ST['DATA']}); l1_ri <= ri; l1_la <= la; l1_b <= lbase; l1_d <= tw_data;")
        a(f"        ld_we <= rst ? 1'b0 : l1_v; ld_sel <= {SB}'(l1_ri); ld_addr <= l1_b + l1_la; ld_data <= l1_d;")
        a("    end")
    feats = [x for x in (f"out_ready, output buffer of {DP} polynomial(s)" if oready else
                         (None if direct else f"output buffer of {DP} polynomial(s)"),
                         "natural-order output" if natural else None,
                         "modulus records on tw_valid/tw_ready/tw_data" if record else None) if x]
    head = (f"// {top}: the hybrid NTT {name} ({W} words per beat) behind ports of {io} words per beat "
            f"({sp['n'] // io} beats per polynomial): {'; '.join(feats)}")
    return "\n".join(["`timescale 1ns / 1ps", head, f"module {top} (\n" + ",\n".join(ports) + "\n    );"] + O +
                     ["endmodule"]) + "\n"


def _tb_ports(sp, NX, NY, NC, ld=None, ext=(), ntw=0, lw=0) -> str:
    """rtl_gen.hybrid_ntt._tb with out_ready and the record stream (patterns from files); a beat is checked when
    out_valid && out_ready."""
    name, top, W, Wd, OW, DP = sp["name"], sp["portTop"], sp["io"], sp["width"], sp["outWidth"], sp["dirPort"]
    po = sp["ports"]
    record, oready = po["record"], po["outReady"]
    MB = 0 if record else sp["MB"]
    L = ["`timescale 1ns / 1ps", f"module {top}_tb ();", "    logic clk = 1'b0;", "    always #5 clk = ~clk;",
         "    logic rst, in_valid, in_ready, out_valid, out_ready;"]
    if MB:
        L.append(f"    logic [{MB - 1}:0] MIDX, midx_out;")
    if DP:
        L.append("    logic DIR, dir_out;")
    for l in range(W):
        L.append(f"    logic [{Wd - 1}:0] x_in_{l}; logic [{Wd - 1}:0] x_ts_{l} [{NX}];")
        L.append(f"    logic [{OW - 1}:0] y_out_{l}; logic [{OW - 1}:0] y_ts_{l} [{NY}];")
    L.append(f"    logic [31:0] ycyc [{NY}]; logic vpat [{NC}]; logic opat [{NC}]; logic [15:0] tg_ts [{NX}]; "
             f"logic [15:0] ytg_ts [{NY}];")
    if record:
        L.append(f"    logic tw_valid, tw_ready; logic [{lw - 1}:0] tw_data; logic [{lw - 1}:0] tw_ts [{ntw}]; "
                 f"logic tpat [{NC}];")
    L.append("    initial begin")
    for l in range(W):
        L.append(f'        $readmemh("../../../../../testvectors/x_{l}.txt", x_ts_{l});')
        L.append(f'        $readmemh("../../../../../testvectors/y_{l}.txt", y_ts_{l});')
    L.append('        $readmemh("../../../../../testvectors/ycycle.txt", ycyc);')
    L.append('        $readmemh("../../../../../testvectors/valid.txt", vpat);')
    L.append('        $readmemh("../../../../../testvectors/oready.txt", opat);')
    L.append('        $readmemh("../../../../../testvectors/tags.txt", tg_ts);')
    L.append('        $readmemh("../../../../../testvectors/ytags.txt", ytg_ts);')
    if record:
        L.append('        $readmemh("../../../../../testvectors/tw.txt", tw_ts);')
        L.append('        $readmemh("../../../../../testvectors/twvalid.txt", tpat);')
    L.append("    end")
    conn = [".clk(clk)", ".rst(rst)", ".in_valid(in_valid)", ".in_ready(in_ready)"]
    if MB:
        conn += [".MIDX(MIDX)", ".midx_out(midx_out)"]
    if DP:
        conn += [".DIR(DIR)", ".dir_out(dir_out)"]
    if oready:
        conn.append(".out_ready(out_ready)")
    if record:
        conn += [".tw_valid(tw_valid)", ".tw_ready(tw_ready)", ".tw_data(tw_data)"]
    if ld:
        NL, SB, LA, LW = ld
        XW = max(SB, LA, LW)
        L.append(f"    logic ld_we = 1'b0; logic [{SB - 1}:0] ld_sel = '0; logic [{LA - 1}:0] ld_addr = '0; "
                 f"logic [{LW - 1}:0] ld_data = '0; logic [{XW - 1}:0] ld_ts [{3 * NL}];")
        L.append('    initial $readmemh("../../../../../testvectors/load.txt", ld_ts);')
        conn += [".ld_we(ld_we)", ".ld_sel(ld_sel)", ".ld_addr(ld_addr)", ".ld_data(ld_data)"]
    for ti, ab, tww in ext:
        L.append(f"    logic [{ab - 1}:0] tw_addr_{ti}; logic [{tww - 1}:0] tw_data_{ti};")
        L.append(f"    {name}_twx{ti} u_tw{ti} (.clk(clk), .addr(tw_addr_{ti}), .q0(tw_data_{ti}));")
        conn += [f".tw_addr_{ti}(tw_addr_{ti})", f".tw_data_{ti}(tw_data_{ti})"]
    conn += [f".x_in_{l}(x_in_{l})" for l in range(W)] + [".out_valid(out_valid)"]
    conn += [f".y_out_{l}(y_out_{l})" for l in range(W)]
    L.append(f"    {top} DUT ({', '.join(conn)});")
    L.append("    int c, bad, xb, ob, late, first_in, last_out, ti, stalled;")
    L.append("    initial begin")
    L.append("        bad = 0; xb = 0; ob = 0; late = 0; first_in = -1; last_out = -1; ti = 0; stalled = 0; rst = 1'b1; "
             "in_valid = 1'b0; out_ready = 1'b0;")
    if record:
        L.append("        tw_valid = 1'b0; tw_data = '0;")
    if MB:
        L.append("        MIDX = '0;")
    if DP:
        L.append("        DIR = 1'b0;")
    for l in range(W):
        L.append(f"        x_in_{l} = '0;")
    L.append("        repeat (100) @(posedge clk);")
    if ld:
        L.append("        // the load image (every table and modulus constant of the moduli under test), before the job")
        L.append(f"        for (c = 0; c < {ld[0]}; c++) begin")
        L.append(f"            #1; ld_we = 1'b1; ld_sel = {ld[1]}'(ld_ts[3 * c]); ld_addr = {ld[2]}'(ld_ts[3 * c + 1]); "
                 f"ld_data = {ld[3]}'(ld_ts[3 * c + 2]);")
        L.append("            @(posedge clk);")
        L.append("        end")
        L.append("        #1; ld_we = 1'b0;")
        L.append("        repeat (8) @(posedge clk);")
    L.append(f"        for (c = 0; c < {NC}; c++) begin")
    L.append("            #1;")
    L.append("            rst = 1'b0;")
    L.append(f"            in_valid = vpat[c] && (xb < {NX});")
    L.append("            out_ready = opat[c];")
    L.append(f"            if (xb < {NX}) begin")
    if MB:
        L.append(f"                MIDX = tg_ts[xb][{MB}:1];")
    if DP:
        L.append("                DIR = tg_ts[xb][0];")
    for l in range(W):
        L.append(f"                x_in_{l} = x_ts_{l}[xb];")
    L.append("            end")
    if record:
        L.append(f"            tw_valid = tpat[c] && (ti < {ntw});")
        L.append(f"            if (ti < {ntw}) tw_data = tw_ts[ti];")
    L.append("            #2;")
    L.append("            if (out_valid && !out_ready) stalled++;")
    L.append("            if (out_valid && out_ready) begin")
    L.append(f"                if (ob >= {NY}) begin bad++; if (bad < 10) $display(\"WRONG extra output beat at cycle %0d\", c); end")
    L.append("                else begin")
    L.append("                    if (c != ycyc[ob]) begin late++; if (late < 5) "
             "$display(\"WRONG beat %0d at cycle %0d, the model says %0d\", ob, c, ycyc[ob]); end")
    if MB:
        L.append(f"                    if (midx_out !== ytg_ts[ob][{MB}:1]) begin bad++; if (bad < 10) $display(\"WRONG beat %0d midx_out %0d\", ob, midx_out); end")
    if DP:
        L.append("                    if (dir_out !== ytg_ts[ob][0]) begin bad++; if (bad < 10) $display(\"WRONG beat %0d dir_out %0d\", ob, dir_out); end")
    for l in range(W):
        L.append(f"                    if (y_out_{l} !== y_ts_{l}[ob]) begin bad++; if (bad < 10) "
                 f"$display(\"WRONG beat %0d lane {l}: got %h want %h\", ob, y_out_{l}, y_ts_{l}[ob]); end")
    L.append("                    ob++; last_out = c;")
    L.append("                end")
    L.append("            end")
    L.append("            if (in_valid && in_ready) begin if (first_in < 0) first_in = c; xb++; end")
    if record:
        L.append("            if (tw_valid && tw_ready) ti++;")
    L.append("            @(posedge clk);")
    L.append("        end")
    L.append(f"        if (ob != {NY}) begin bad++; $display(\"WRONG: %0d of {NY} output beats\", ob); end")
    L.append(f"        if (xb != {NX}) begin bad++; $display(\"WRONG: %0d of {NX} input beats accepted\", xb); end")
    if record:
        L.append(f"        if (ti != {ntw}) begin bad++; $display(\"WRONG: %0d of {ntw} record entries accepted\", ti); end")
    L.append("        $display(\"[tb] rate: %0d beats in, %0d out, first input cycle %0d, last output cycle %0d, "
             "%0d late beats, %0d cycles with out_valid and no out_ready\", xb, ob, first_in, last_out, late, stalled);")
    L.append("        bad = bad + late;")
    L.append("        if (bad == 0) begin $display(\"SUCCESS!\"); $display(\"PASS All %0d Testvectors!\", ob); end")
    L.append("        else begin $display(\"TO BE DEBUGGED...\"); $display(\"FAILED: %0d wrong\", bad); end")
    L.append("        $finish();")
    L.append("    end")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def emit_ports(sp: dict, core_ports: list, regs: list, tb: dict | None, ext=()) -> dict:
    """Writes the wrapper (and its testbench); returns the manifest's additions."""
    from rtl_gen.iter_ntt import _ram_module
    from rtl_gen.utils import to_twos_complement_hex
    rtl = "RTL_generated"
    top, po = sp["portTop"], sp["ports"]
    io, Wd, OW = sp["io"], sp["width"], sp["outWidth"]
    record = po["record"]
    for stale in [x for x in os.listdir(rtl) if x.startswith(f"{top}_pram_") or x in (f"{top}.sv", f"{top}_tb.sv")]:
        os.remove(os.path.join(rtl, stale))
    if not po["direct"]:
        with open(os.path.join(rtl, f"{top}_pram_{po['bufStyle']}.sv"), "w", encoding="utf-8") as f:
            f.write(_ram_module(f"{top}_pram_{po['bufStyle']}", po["bufStyle"]))
    with open(os.path.join(rtl, f"{top}.sv"), "w", encoding="utf-8") as f:
        f.write(_wrapper(sp, core_ports, regs))
    man = {"top_name": top, "io_lanes": io, "out_ready": po["outReady"], "output_order": "natural" if po["natural"] else "core",
           "out_depth_polys": None if po["direct"] else po["DP"], "landing_fifo": None if po["direct"] else po["K"]}
    if record:
        NS = sp["M"]
        chunk = [r["depth"] // NS for r in regs]
        LW = max(r["width"] for r in regs)
        assert sum(chunk) == po["recordWords"], (f"record: the model counts {po['recordWords']} entries, the load map "
                                                 f"{sum(chunk)}")
        man.update(record_stream=True, record_entries=sum(chunk), record_data_bits=LW, table_sets=NS,
                   record_map=[{"name": r["name"], "entries": c, "width": r["width"]} for r, c in zip(regs, chunk)])
    if tb is not None:
        tv = "testvectors"
        os.makedirs(tv, exist_ok=True)
        NX, NY, NC = len(tb["x"]), len(tb["y"]), tb["cycles"]
        for l in range(io):
            with open(os.path.join(tv, f"x_{l}.txt"), "w") as f:
                f.write("".join(to_twos_complement_hex(bt[l], Wd) + "\n" for bt in tb["x"]))
            with open(os.path.join(tv, f"y_{l}.txt"), "w") as f:
                f.write("".join(to_twos_complement_hex(bt[l], OW) + "\n" for bt in tb["y"]))
        for fn, key in (("tags.txt", "tags"), ("ytags.txt", "ytags")):
            with open(os.path.join(tv, fn), "w") as f:
                f.write("".join(f"{(m << 1) | d:x}\n" for m, d in tb[key]))
        with open(os.path.join(tv, "ycycle.txt"), "w") as f:
            f.write("".join(f"{c:08x}\n" for c in tb["ycycle"]))
        for fn, key in (("valid.txt", "valid"), ("oready.txt", "oready")):
            with open(os.path.join(tv, fn), "w") as f:
                f.write("".join(f"{v}\n" for v in tb[key]))
        ld, ntw, lw = None, 0, 0
        if record:
            images = {"main": [r["values"] for r in regs]}
            if tb.get("altRegions") is not None:
                images["alt"] = [r["values"] for r in tb["altRegions"]]
                assert [len(v) for v in images["alt"]] == [len(v) for v in images["main"]]
            ent = []
            for p, (keep, src, mi) in enumerate(tb["records"]):
                ent.append(1 if keep else 0)
                if keep and p > 0:
                    continue
                for vals, cnk in zip(images[src], chunk):
                    ent += vals[mi * cnk:(mi + 1) * cnk]
            ntw, lw = len(ent), LW
            with open(os.path.join(tv, "tw.txt"), "w") as f:
                f.write("".join(f"{v:x}\n" for v in ent))
            with open(os.path.join(tv, "twvalid.txt"), "w") as f:
                f.write("".join(f"{v}\n" for v in tb["twvalid"]))
        elif sp.get("loadable"):
            from rtl_gen.hybrid_ntt import _bits as _b
            NL = sum(r["depth"] for r in regs)
            with open(os.path.join(tv, "load.txt"), "w") as f:
                f.write("".join(f"{k:x}\n{i:x}\n{v:x}\n" for k, r in enumerate(regs) for i, v in enumerate(r["values"])))
            ld = (NL, _b(len(regs)), max(_b(r["depth"]) for r in regs), max(r["width"] for r in regs))
        with open(os.path.join(rtl, f"{top}_tb.sv"), "w", encoding="utf-8") as f:
            f.write(_tb_ports(sp, NX, NY, NC, ld, ext, ntw, lw))
    return man
