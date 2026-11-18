"""Iterative NTT core, constant-geometry memory organisation (IterNTTSpec.memOrg == 'constgeo').

Called by `rtl_gen.iter_ntt.IterNTT_RTL_gen` (same files, ports, testbench and manifest as the in-place
core). The twin is `operator_modeling.ntt.iterative.IterativeNTTScheme.IterativeNTTScheme` with memOrg 'constgeo'
(`cgRow`, `cgPair`, `cgWrite`, `cgReadBanks`, `cgWriteSource`, `cgTwiddleIndex`, `nextSet`, `scratchSet`,
`resultSet`, `simulateJob`): any change here must be made there.

Structure:
  3 sets x 2B banks (bank map as in place: (p mod 2B) ^ (parity(p >> (b+1)) << b), address p >> (b+1)).
  A polynomial is filled into set X, computed between X (stages s even read it) and its scratch Y (stages s
  odd), and drained from its result set (X for L even, Y for L odd); the third set drains the previous result
  and takes the next polynomial in lock-step. L even: X alternates 0 / 2, Y = 1; L odd: X -> X + 2 mod 3,
  Y = X + 1 mod 3.
  Stage s, cycle t reads row r = rotr_H(t, cgShifts[s]) of the read set, every bank at address r; butterfly k
  takes banks 2k, 2k+1 (B = 1: banks pi, 1 - pi, pi = parity(r)): fixed wiring. Its outputs X (a + wb), Y go
  to banks i + B (pi ^ e), i = k ^ pi B/2, at address (r >> 1) + e T/2: per bank a 2:1 write mux selected
  by pi (cgWriteSource).
  Twiddles: one table per butterfly, stage s's region at twBases[s], entry (r >> (H - s)) for s <= H, r above.

Pipeline as in place (Pw = R + Pbu + 4): issue t; t+1 bank addresses and the twiddle address registered;
t+1+R RAM data, the read-set mux; t+2+R operands and twiddles registered; +Pbu butterfly; output register
(halver); write mux; we / wa / wd registered; the RAM writes on the edge ending t + Pw.
"""
from __future__ import annotations

import json
import os


def IterNTT_CG_RTL_gen(spec, tb=None) -> dict:
    from rtl_gen.butterfly import Butterfly_RTL_gen
    from rtl_gen.datapath import Datapath_RTL_gen
    from rtl_gen.iter_ntt import (_bits, _c, _h, _ram_module, _rom_module, _twram_module, _twrns_module, _tb,
                                  _mrom_otag, _mrom_consts, _mrom_vectors)
    from rtl_gen.utils import to_twos_complement_hex
    import glob
    sp = spec
    name, B, L, b, H, io = sp.name, sp.B, sp.L, sp.b, sp.H, sp.io
    P = 2 * B
    T = 1 << H
    R = sp.R
    W = sp.width
    NB = sp.beats
    lsub = (P // io).bit_length() - 1
    FBW = _bits(NB)
    SW = _bits(L)
    Pbu = sp.buLatency
    XR = getattr(sp, "crossRegs", 0)       # register stages before and after the butterflies (SLR crossings)
    FT = getattr(sp, "fanout", None)       # fan-out trees (IterativeNTTScheme.fanoutPlan): dict or None
    Re = R + (FT["readTree"] if FT else 0)  # the read latency the schedule sees (RAM + read trees)
    K = Re + Pbu + 2 + 2 * XR
    Pw = sp.writeLatency
    assert Pw == Re + Pbu + 4 + 2 * XR
    assert H >= 1
    gmax = max(sp.gaps)
    GW = _bits(gmax + 1)
    Leven = L % 2 == 0
    rtl = "RTL_generated"
    os.makedirs(rtl, exist_ok=True)
    for stale in glob.glob(os.path.join(rtl, f"{name}*.sv")):
        os.remove(stale)
    # --- sub-modules -------------------------------------------------------------------
    Butterfly_RTL_gen(spec=sp.bu, gen_testbench=False)
    tw = sp.twist
    if tw is not None:
        Datapath_RTL_gen(spec=tw["datapath"], gen_testbench=False, submodules=tw["submodules"], write_xdc=False)
    rc = getattr(sp, "rec", None)          # twiddleSource 'rec': the tables written on chip (IterativeNTT._recSpec)
    if rc is not None and rc["gen"] is not None:
        Datapath_RTL_gen(spec=rc["gen"]["datapath"], gen_testbench=False, submodules=rc["gen"]["submodules"],
                         write_xdc=False)
    if os.path.isfile("manifest.json"):
        os.remove("manifest.json")
    ramMod = f"{name}_ram_{sp.memStyle}"
    with open(os.path.join(rtl, f"{ramMod}.sv"), "w", encoding="utf-8") as f:
        f.write(_ram_module(ramMod, sp.memStyle))
    tabs = list(sp.tables)
    assert len(tabs) == B and all(t.get("kind") == "t" for t in tabs)
    ttabs = list(tw["tables"]) if tw is not None else []
    tstyle = sp.twiddleStyle
    loadW = sp.loadWords
    ramTabs = [t for t in tabs + ttabs if t["mode"] == "ram"]
    for j, t in enumerate(tabs):
        if t["mode"] == "rom":
            with open(os.path.join(rtl, f"{name}_tw{j}.sv"), "w", encoding="utf-8") as f:
                f.write(_rom_module(f"{name}_tw{j}", t["cols"], t["values"], t["depth"], R, tstyle))
    for l, t in enumerate(ttabs):
        if t["mode"] == "rom":
            with open(os.path.join(rtl, f"{name}_tt{l}.sv"), "w", encoding="utf-8") as f:
                f.write(_rom_module(f"{name}_tt{l}", t["cols"], t["values"], t["depth"], R, tstyle))
    rns = getattr(sp, "twiddleBuffer", "single") != "single"
    dbl = rns and sp.twiddleBuffer == "double"
    recyc = rns and not dbl
    rec = rns and rc is not None
    rnsShapes = {}
    if rns:
        for t in tabs:
            key = (tuple(t["cols"]), t["depth"])
            if key not in rnsShapes:
                A1 = _bits(t["depth"]) + (1 if dbl else 0)
                rnsShapes[key] = (f"{name}_twr{len(rnsShapes)}", A1)
                with open(os.path.join(rtl, f"{rnsShapes[key][0]}.sv"), "w", encoding="utf-8") as f:
                    f.write(_twrns_module(rnsShapes[key][0], list(t["cols"]), (1 << A1) if dbl else t["depth"],
                                          A1, R, tstyle))
    ramShapes = {}
    for t in ramTabs:
        key = (tuple(t["cols"]), t["depth"], t.get("kind"))
        if key not in ramShapes:
            ramShapes[key] = f"{name}_twram{len(ramShapes)}"
            with open(os.path.join(rtl, f"{ramShapes[key]}.sv"), "w", encoding="utf-8") as f:
                f.write(_twram_module(ramShapes[key], list(t["cols"]), t["depth"], R, tstyle))

    bs = sp.bu
    qports = list(sp.qPorts)
    qw = dict(qports)
    O = []

    def a(x):
        O.append("    " + x)

    # --- ports (as in place) ----------------------------------------------------------------
    # moduli= (multi-modulus ROM, as rtl_gen/iter_ntt.py): MIDX (and DIR) with the first input beat of each
    # polynomial, the tag on the output (midx_out, dir_out); the constants from ROMs, no q ports
    mr = getattr(sp, "mrom", None)
    MB = mr["bits"] if mr else 0
    MDIR = bool(mr) and sp.dirPort
    TG = MB + (1 if MDIR else 0)
    mbub = bool(mr) and not getattr(sp, "qInline", False)
    if mr and FT:        # refused by IterativeNTTScheme; never built
        raise ValueError(f"{name}: fanout trees are not built with moduli=")
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

    if mr:
        a(f"// ---- moduli= : {len(mr['moduli'])} moduli in the ROMs; a polynomial's tag {{DIR, MIDX}} is taken with its "
          f"first input beat")
        a(f"logic [{TG - 1}:0] ftag [3]; logic [{TG - 1}:0] rtag [3]; logic [{TG - 1}:0] ctag, dtag;      "
          f"// per filled set; per result set; computing; draining")
        a(f"logic [{MB - 1}:0] cmidx, dmidx; assign cmidx = ctag[{MB - 1}:0]; assign dmidx = dtag[{MB - 1}:0];")
        if MDIR:
            a(f"(* max_fanout = 32 *) logic DIR_r; logic ddir; assign ddir = dtag[{MB}];")
        _mrom_consts(a, mr, qports, 3, TG)
    elif sp.dirPort:
        a("(* max_fanout = 32 *) logic DIR_r;")
        a("always_ff @(posedge clk) DIR_r <= DIR;")
    dpp = getattr(sp, "dirPerPoly", False)        # the direction per polynomial: a record header bit
    if dpp:
        if rec:                                   # refused by IterativeNTTScheme; never built
            raise ValueError(f"{name}: twiddleSource 'rec' is not built with dirPerPoly")
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
    # qSwitch 'inline' (as rtl_gen/iter_ntt.py): {qp}_dl[i] is {qp}_r i+1 cycles later; a consumer's copy takes
    # the tap that switches as the new polynomial's first operation reaches it
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

    KEEP = '(* keep = "true" *) ' if (getattr(sp, "crossRegs", 0) or (FT and FT.get("keepSinks", True))) else ''   # no merging of per-butterfly / per-bank copies
    lv = (lambda nm: list(FT["levels"].get(nm, []))) if FT else (lambda nm: [])
    padr = (lambda l_: [1] * (FT["readTree"] - len(l_)) + l_) if FT else (lambda l_: l_)
    qtrees = {}

    def qsig(tag: str, qp: str, sink: int | None = None, d: int | None = None) -> str:
        '''A registered copy of constant `qp`; inline with `d`: the copy `d` cycles behind {qp}_r (the tree's
        levels and this register counted).'''
        nm = f"{tag}_{qp}"
        if nm not in qcopies:
            qcopies.add(nm)
            src = f"{qp}_r"
            tree = bool(FT and sink is not None and lv("modulus constants"))
            if inl and d is not None:
                pre = d - 1 - (len(lv("modulus constants")) if tree else 0)
                if pre < 0:
                    raise ValueError(f"{name}: qSwitch 'inline': the modulus tree is deeper than the operand path")
                src = f"{qp}_dl[{pre - 1}]" if pre else f"{qp}_r"
            if tree:
                tk = (qp, src)
                if tk not in qtrees:
                    qtrees[tk] = _tree(a, f"ft_q{qp}" + (f"_{len(qtrees)}" if inl else ""), [("v", qw[qp], src)], B,
                                       lv("modulus constants"))
                src = qtrees[tk](sink)["v"]
            a(f"{KEEP}(* max_fanout = 16 *) logic [{qw[qp] - 1}:0] {nm};")
            a(f"always_ff @(posedge clk) {nm} <= {src};")
        return nm

    # --- set roles ------------------------------------------------------------------------------
    a(f"// ---- three bank sets: input X (filled, read by stages s even), scratch Y (stages s odd), "
      f"{'result in X' if Leven else 'result in Y'}; IterativeNTTScheme.nextSet / scratchSet / resultSet")
    a("function automatic logic [1:0] nx_of(input logic [1:0] x);")
    if Leven:
        a("    nx_of = (x == 2'd0) ? 2'd2 : 2'd0;")
    else:
        a("    nx_of = (x == 2'd0) ? 2'd2 : ((x == 2'd2) ? 2'd1 : 2'd0);")
    a("endfunction")
    a("function automatic logic [1:0] scr_of(input logic [1:0] x);")
    if Leven:
        a("    scr_of = 2'd1;")
    else:
        a("    scr_of = (x == 2'd0) ? 2'd1 : ((x == 2'd1) ? 2'd2 : 2'd0);")
    a("endfunction")
    a("function automatic logic [1:0] res_of(input logic [1:0] x);")
    a("    res_of = x;" if Leven else "    res_of = scr_of(x);")
    a("endfunction")

    # --- controller (twin: IterativeNTTScheme.simulateJob) --------------------------------------
    a("// ---- controller: fill (input), compute (butterflies), drain (output)")
    a(f"logic [1:0] fset, cset, cnext, dset, dnext; logic [{FBW - 1}:0] fptr, dptr; logic [2:0] full, busy, res;")
    a(f"logic cact; logic [{SW - 1}:0] s; logic [{H - 1}:0] tau; logic [{GW - 1}:0] gap;")
    a("logic dact;")
    a(f"logic [{Pw - 1}:0] dsr; logic [1:0] dsrs [{Pw}];")
    a("logic fill_ok, acc, flast, issue, tlast, clast, startc, dlastb, startd, done; logic [1:0] done_set;")
    if rns:
        HB, NBs, QB = sp.headerBeats, list(sp.stageBeats), sp.qBubble
        G = B // TL
        GB = G.bit_length() - 1
        KW = _bits(max(NBs))
        HBW = _bits(HB)
        QBW = _bits(QB + 1)
        RW = _bits(L + 1)
        a(f"// ---- record stream ({sp.twiddleBuffer}): per polynomial a header (bit 0 keep, then the modulus "
          f"constants), then its twiddles ({'its' if dpp else 'the job' + chr(39) + 's'} direction), {TL} entries a beat")
        a("localparam logic [1:0] L_HDR = 2'd0, L_DATA = 2'd1, L_WAIT = 2'd2;")
        if rec:
            a("logic [1:0] lst, lst_n; logic lahead, lahead_n, nkeep, hdr_ok, perm, tacc, hlast, hkeep;")
            a(f"logic [{SW - 1}:0] ws, ws_n; logic [{HBW - 1}:0] hptr, hptr_n;")
        else:
            a("logic [1:0] lst, lst_n; logic lahead, lahead_n, nkeep, hdr_ok, perm, tacc, hlast, klast, hkeep;")
            a(f"logic [{SW - 1}:0] ls, ls_n; logic [{KW - 1}:0] lk, lk_n; logic [{HBW - 1}:0] hptr, hptr_n;")
        a(f"logic [{QBW - 1}:0] qw;")
        if recyc:
            a(f"logic [{RW - 1}:0] relst; logic twok;")
        if dbl:
            a("logic lcopy, ccopy;")
        if recyc:
            a("assign hdr_ok = (lst == L_WAIT) || ((lst == L_DATA) && lahead);")
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
    a("        fset <= 2'd0; fptr <= '0; full <= '0; busy <= '0; res <= '0;")
    a("        cact <= 1'b0; cset <= 2'd0; cnext <= 2'd0; s <= '0; tau <= '0; gap <= '0;")
    a(f"        dact <= 1'b0; dset <= 2'd0; dnext <= res_of(2'd0); dptr <= '0; dsr <= '0;")
    a(f"        for (int i = 0; i < {Pw}; i++) dsrs[i] <= 2'd0;")
    a("    end else begin")
    a("        if (acc) begin")
    a("            fptr <= flast ? '0 : fptr + 1'b1;")
    a("            if (flast) begin full[fset] <= 1'b1; busy[res_of(fset)] <= 1'b1; fset <= nx_of(fset); end")
    a("        end")
    a(f"        dsr <= {{dsr[{Pw - 2}:0], clast}}; dsrs[0] <= res_of(cset);")
    a(f"        for (int i = 1; i < {Pw}; i++) dsrs[i] <= dsrs[i-1];")
    a("        if (startc) begin")
    a("            full[cnext] <= 1'b0;")
    a("            cact <= 1'b1; cset <= cnext; cnext <= nx_of(cnext); s <= '0; tau <= '0; gap <= '0;")
    a("        end else if (clast) cact <= 1'b0;")
    a("        else if (issue) begin")
    a("            if (tlast) begin gap <= gap_of; s <= s + 1'b1; tau <= '0; end")
    a("            else tau <= tau + 1'b1;")
    a("        end else if (cact && gap != '0) gap <= gap - 1'b1;" if rns else "        end else if (cact) gap <= gap - 1'b1;")
    a("        if (done) begin busy[done_set] <= 1'b0; res[done_set] <= 1'b1; end")
    a("        if (dlastb) res[dset] <= 1'b0;")
    a("        if (startd) begin dact <= 1'b1; dset <= dnext; dnext <= nx_of(dnext); dptr <= '0; end")
    a("        else if (dlastb) dact <= 1'b0;")
    a("        else if (dact) dptr <= dptr + 1'b1;")
    a("    end")
    a("end")
    if mr:
        # ftag[X] holds until set X is refilled (after its start). rtag[Y], the tag of the polynomial whose result
        # is in set Y, is rewritten at the start of the next polynomial with result set Y, whose fill began only
        # after a later result's drain had started (drains are in order), so after Y's own drain started
        a("always_ff @(posedge clk) begin")
        a("    if (rst) begin ctag <= '0; dtag <= '0;" + (" qw <= '0;" if mbub else "") + " end")
        a("    else begin")
        a("        if (startc) begin ctag <= ftag[cnext]; rtag[res_of(cnext)] <= ftag[cnext]; end")
        a("        if (startd) dtag <= rtag[dnext];")
        if mbub:
            a(f"        qw <= clast ? {_c(QB, QBW)} : ((qw != '0) ? qw - 1'b1 : '0);")
        a("    end")
        a(f"    if (acc && (fptr == '0)) ftag[fset] <= {{{'DIR, ' if MDIR else ''}MIDX}};")
        a("    if (!rst && startc) begin " + " ".join(f"{qp}_r <= fq_{qp}[cnext];" for qp, _ in qports)
          + (f" DIR_r <= ftag[cnext][{MB}];" if MDIR else "") + " end")
        a("end")

    if rec:
        _rec_loader(a, sp, rc, L, H, T, B, SW, HB, HBW, QB, QBW, RW, TLW, TEW, qports)
    if rns and not rec:
        a("// ---- the loader (twin: IterativeNTTScheme._simulateJobRns)")
        a(f"assign perm = !lahead || (relst > {RW}'(ls));" if recyc else "assign perm = 1'b1;")
        a("assign tw_ready = (lst == L_HDR) || ((lst == L_DATA) && perm);")
        a("assign tacc = tw_valid && tw_ready && !rst;")
        a(f"assign hlast = hptr == {_c(HB - 1, HBW)};" if HB > 1 else "assign hlast = 1'b1;")
        a(f"function automatic logic [{KW - 1}:0] nbs_of(input logic [{SW - 1}:0] s_);")
        a("    case (s_)")
        for st, nb in enumerate(NBs):
            a(f"        {_c(st, SW)}: nbs_of = {_c(nb - 1, KW)};")
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
        a("                if (hkeep) lst_n = L_WAIT;")
        a("                else begin lst_n = L_DATA; ls_n = '0; lk_n = '0; lahead_n = 1'b1; end")
        a("            end else hptr_n = hptr + 1'b1;")
        a("        end")
        a("        L_DATA: begin")
        a("            if (startc) lahead_n = 1'b0;")
        a("            if (tacc) begin")
        a("                if (klast) begin")
        a("                    lk_n = '0; ls_n = ls + 1'b1;")
        a(f"                    if (ls == {_c(L - 1, SW)}) begin ls_n = '0; lst_n = (lahead && !startc) ? L_WAIT : L_HDR; end")
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
        a(rs_)
        a("    end else begin")
        a("        lst <= lst_n; lahead <= lahead_n; ls <= ls_n; lk <= lk_n; hptr <= hptr_n;")
        a("        if (lst == L_HDR && tacc && hlast) nkeep <= hkeep;")
        if dbl:
            a("        if (lst == L_HDR && tacc && hlast && !hkeep) lcopy <= ~lcopy;")
            a("        if (startc && !nkeep) ccopy <= ~ccopy;")
        a(f"        qw <= clast ? {_c(QB, QBW)} : ((qw != '0) ? qw - 1'b1 : '0);")
        if recyc:
            a(f"        if (startc) relst <= '0; else if (clast) relst <= {_c(L, RW)}; "
              f"else if (issue && (tau == '0)) relst <= {RW}'(s);")
            a("        twok <= (tau_nx != '0) || !((lst_n == L_DATA) && !lahead_n) || (ls_n > s_nx);")
        a("    end")
        a("end")
        a("always_ff @(posedge clk) begin")
        if HB > 1:
            a("    if (lst == L_HDR && tacc && !hlast) hb[hptr] <= tw_data;")
        for qp, off, w in sp.headerLayout:
            a(f"    if (lst == L_HDR && tacc && hlast && !hkeep) {qp}_n <= hdr_w[{off + w - 1}:{off}];")
        a("    if (!rst && startc && !nkeep) begin " + " ".join(f"{qp}_r <= {qp}_n;" for qp, _ in qports)
          + (" DIR_r <= DIR_n;" if dpp else "") + " end")
        a("end")

    # --- stage decode: row, its parity, the read / write sets, the twiddle entry ---------------------
    TA = _bits(tabs[0].get("depth1", tabs[0]["depth"]))
    MX = bool(mr) and len(mr["moduli"]) > 1      # moduli=: the tables' address is {MIDX, the one-modulus address}
    shifts = list(sp.cgShifts)
    bases, depths = list(sp.twBases), list(sp.twDepths)

    def rot(k: int, t: str) -> str:
        return t if k == 0 else f"{{{t}[{k - 1}:0], {t}[{H - 1}:{k}]}}"
    a("// ---- stage decode (IterativeNTTScheme.cgRow / cgTwiddleIndex)")
    a(f"function automatic logic [{H - 1}:0] row_of(input logic [{SW - 1}:0] s_, input logic [{H - 1}:0] t_);")
    a("    case (s_)")
    for st in range(L):
        if shifts[st]:
            a(f"        {_c(st, SW)}: row_of = {rot(shifts[st], 't_')};")
    a("        default: row_of = t_;")
    a("    endcase")
    a("endfunction")
    a(f"function automatic logic [{TA - 1}:0] tidx_of(input logic [{SW - 1}:0] s_, input logic [{H - 1}:0] r_);")
    a("    case (s_)")
    for st in range(L):
        if st == 0:
            e = f"{_c(bases[0], TA)}"
        elif st < H:
            e = f"{_c(bases[st], TA)} + {TA}'(r_[{H - 1}:{H - st}])"
        else:
            e = f"{_c(bases[st], TA)} + {TA}'(r_)"
        a(f"        {_c(st, SW)}: tidx_of = {e};")
    a("        default: tidx_of = '0;")
    a("    endcase")
    a("endfunction")
    a(f"logic [{H - 1}:0] c_row; logic c_pi; logic [1:0] c_rset, c_wset;")
    a("assign c_row = row_of(s, tau); assign c_pi = ^c_row;")
    a("assign c_rset = s[0] ? scr_of(cset) : cset; assign c_wset = s[0] ? cset : scr_of(cset);")

    a(f"// ---- issue bundle, delayed: cb_*[k] is the read issued k+1 cycles ago (k = 0 .. {K})")
    MF = "(* max_fanout = 32 *) " if XR else ""
    a(f"{MF}logic cb_v [{K + 1}]; {MF}logic cb_pi [{K + 1}]; {MF}logic [1:0] cb_rset [{K + 1}]; {MF}logic [1:0] cb_wset [{K + 1}];")
    a(f"{MF}logic [{H - 1}:0] cb_row [{K + 1}];")
    a("always_ff @(posedge clk) begin")
    a(f"    if (rst) for (int i = 0; i <= {K}; i++) cb_v[i] <= 1'b0;")
    a("    else begin")
    a("        cb_v[0] <= issue;")
    a(f"        for (int i = 1; i <= {K}; i++) cb_v[i] <= cb_v[i-1];")
    a("    end")
    a("    cb_pi[0] <= c_pi; cb_rset[0] <= c_rset; cb_wset[0] <= c_wset; cb_row[0] <= c_row;")
    a(f"    for (int i = 1; i <= {K}; i++) begin cb_pi[i] <= cb_pi[i-1]; cb_rset[i] <= cb_rset[i-1]; "
      f"cb_wset[i] <= cb_wset[i-1]; cb_row[i] <= cb_row[i-1]; end")
    a("end")

    # --- drain decode (as in place, 2-bit set) ---------------------------------------------------
    a("// ---- drain: beat dptr of set dset, row dptr >> lsub")
    a(f"logic [{H - 1}:0] drow; assign drow = {H}'(dptr >> {lsub});")
    if lsub:
        a(f"logic [{lsub - 1}:0] dsub; assign dsub = dptr[{lsub - 1}:0];")
    DSUB = max(1, lsub)
    a(f"logic db_v [{Re + 1}]; logic [1:0] db_set [{Re + 1}]; logic db_pi [{Re + 1}]; logic [{DSUB - 1}:0] db_sub [{Re + 1}];")
    a("always_ff @(posedge clk) begin")
    a(f"    if (rst) for (int i = 0; i <= {Re}; i++) db_v[i] <= 1'b0;")
    a("    else begin")
    a("        db_v[0] <= dact;")
    a(f"        for (int i = 1; i <= {Re}; i++) db_v[i] <= db_v[i-1];")
    a("    end")
    a(f"    db_set[0] <= dset; db_pi[0] <= ^drow; db_sub[0] <= {'dsub' if lsub else chr(39) + '0'};")
    a(f"    for (int i = 1; i <= {Re}; i++) begin db_set[i] <= db_set[i-1]; db_pi[i] <= db_pi[i-1]; db_sub[i] <= db_sub[i-1]; end")
    a("end")
    a("// ---- fill: beat fptr of set fset, row fptr >> lsub")
    a(f"logic [{H - 1}:0] frow; assign frow = {H}'(fptr >> {lsub});")
    a("logic fpi; assign fpi = ^frow;")
    if lsub:
        a(f"logic [{lsub - 1}:0] fsub; assign fsub = fptr[{lsub - 1}:0];")

    # write stage
    a(f"logic w_v, w_pi; logic [1:0] w_set; logic [{H - 1}:0] w_row;")
    a(f"assign w_v = cb_v[{K}]; assign w_pi = cb_pi[{K}]; assign w_set = cb_wset[{K}]; assign w_row = cb_row[{K}];")
    wleaf = lambda X, k: {"v": "w_v", "pi": "w_pi", "set": "w_set", "row": "w_row"}
    if lv("bank write"):             # taken earlier from the issue chain: the leaves carry cb_*[K]
        dw = len(lv("bank write"))
        _wt = _tree(a, "ft_w", [("v", 1, f"cb_v[{K - dw}]"), ("pi", 1, f"cb_pi[{K - dw}]"),
                               ("set", 2, f"cb_wset[{K - dw}]"), ("row", H, f"cb_row[{K - dw}]")], 3 * P,
                    lv("bank write"), rst={"v"})
        wleaf = lambda X, k: _wt(3 * k + X)
    # the read side: every bank's read address (compute and drain), delayed by the read trees
    if FT and FT["readTree"]:
        _rt = _tree(a, "ft_r", [("iss", 1, "issue"), ("rset", 2, "c_rset"), ("row", H, "c_row"), ("dact", 1, "dact"),
                               ("dset", 2, "dset"), ("drow", H, "drow")], 3 * P, padr(lv("bank read")),
                    rst={"iss", "dact"})
        rleaf = lambda X, k: _rt(3 * k + X)
    else:
        rleaf = lambda X, k: {"iss": "issue", "rset": "c_rset", "row": "c_row", "dact": "dact", "dset": "dset",
                              "drow": "drow"}

    # --- banks -----------------------------------------------------------------------------------
    a("// ---- data banks: 3 sets x 2B banks, every bank of the read set at the row's address")
    for X in range(3):
        for k in range(P):
            nm = f"m{X}_{k}"
            a(f"{KEEP}logic {nm}_we; {KEEP}logic [{H - 1}:0] {nm}_wa, {nm}_ra; logic [{W - 1}:0] {nm}_wd, {nm}_rd;")
            a(f"{ramMod} #(.W({W}), .D({T}), .A({H}), .R({R})) u_{nm} (.clk(clk), .we({nm}_we), .wa({nm}_wa), "
              f".wd({nm}_wd), .ra({nm}_ra), .rd({nm}_rd));")
            rl_ = rleaf(X, k)
            a(f"always_ff @(posedge clk) if ({rl_['iss']} && {rl_['rset']} == 2'd{X}) {nm}_ra <= {rl_['row']}; "
              f"else if ({rl_['dact']} && {rl_['dset']} == 2'd{X}) {nm}_ra <= {rl_['drow']};")
    # read-set selects, registered per port (valid with the RAM data)
    a("// ---- operands: bank 2k, 2k+1 of the read set (B = 1: swapped by the row parity), selects registered")
    rsrc = lambda p_: f"cb_rset[{Re - 1}]"
    if lv("read select"):
        drs = len(lv("read select"))
        assert Re - 1 - drs >= 0
        _rs = _tree(a, "ft_rs", [("v", 2, f"cb_rset[{Re - 1 - drs}]")], P, lv("read select"))
        rsrc = lambda p_: _rs(p_)["v"]
    for p_ in range(P):
        a(f"{KEEP}(* max_fanout = 32 *) logic [1:0] rsel{p_}; always_ff @(posedge clk) rsel{p_} <= {rsrc(p_)};")
        a(f"logic [{W - 1}:0] rdc{p_};")
        a(f"always_comb case (rsel{p_}) 2'd1: rdc{p_} = m1_{p_}_rd; 2'd2: rdc{p_} = m2_{p_}_rd; default: rdc{p_} = m0_{p_}_rd; endcase")
    if b == 0:
        a(f"logic osw; always_ff @(posedge clk) osw <= cb_pi[{Re - 1}];")
        a(f"logic [{W - 1}:0] op0, op1;")
        a("always_ff @(posedge clk) begin op0 <= osw ? rdc1 : rdc0; op1 <= osw ? rdc0 : rdc1; end")
    else:
        for p_ in range(P):
            a(f"logic [{W - 1}:0] op{p_}; always_ff @(posedge clk) op{p_} <= rdc{p_};")

    def chain(sig: str, w: int) -> str:
        '''sig delayed by the X cross registers (the butterfly side of an SLR crossing).'''
        prev = sig
        for i in range(XR):
            nm = f"{sig}_x{i}"
            a(f"logic [{w - 1}:0] {nm}; always_ff @(posedge clk) {nm} <= {prev};")
            prev = nm
        return prev
    opin = [chain(f"op{p_}", W) for p_ in range(P)]

    # --- twiddle tables ----------------------------------------------------------------------------
    a("// ---- twiddle tables: one per butterfly, address cgTwiddleIndex (+ the inverse half)")
    a(f"(* max_fanout = 16 *) logic [{TA - 1}:0] ta;")
    dirOff = f" + ({dirs} ? {_c(sp.tdepth, TA)} : {_c(0, TA)})" if (sp.dirPort and not rns) else ""
    a(f"always_ff @(posedge clk) ta <= tidx_of(s, c_row){dirOff};")
    taOf = lambda j: "ta"
    if MX:
        a(f"(* max_fanout = 16 *) logic [{MB - 1}:0] cmidx_a; always_ff @(posedge clk) cmidx_a <= cmidx;")
    if FT and FT["readTree"]:            # the table addresses delayed as the bank reads
        _ta = _tree(a, "ft_ta", [("v", TA, "ta")], B, padr(lv("twiddle address")))
        taOf = lambda j: _ta(j)["v"]
    if inl and dbl:     # the copy of the read's own polynomial, delayed as its address (register + tree)
        nd_ = 1 + (len(padr(lv("twiddle address"))) if (FT and FT["readTree"]) else 0)
        a(f"logic [{nd_ - 1}:0] ccopy_d; logic ccopy_a; assign ccopy_a = ccopy_d[{nd_ - 1}];")
        a("always_ff @(posedge clk) ccopy_d <= " + (f"{{ccopy_d[{nd_ - 2}:0], ccopy}};" if nd_ > 1 else "ccopy;"))
    if loadW:
        a(f"(* max_fanout = 32 *) logic [{LW - 1}:0] tw_wi;")
        a("always_ff @(posedge clk) tw_wi <= tw_rst ? '0 : (tw_wen ? tw_wi + 1'b1 : tw_wi);")
        a(f"(* max_fanout = 32 *) logic [{TWW - 1}:0] tw_wd_q;")
        a("always_ff @(posedge clk) tw_wd_q <= tw_wdata;")
    waOf = lambda j: "lw_wa"
    if rec:
        waOf = _rec_writes(a, sp, rc, L, H, T, B, b, SW, TA, TEW, bases, depths, qsig, FT)
    if rns and not rec:
        a("// ---- table write ports from the record stream (IterativeNTT._rnsRecordCg order)")
        a(f"logic [{KW - 1}:0] lw_rest; assign lw_rest = {KW}'(lk >> {GB});")
        a(f"function automatic logic [{TA - 1}:0] lwa_of(input logic [{SW - 1}:0] s_, input logic [{KW - 1}:0] r_);")
        a("    case (s_)")
        for st in range(L):
            a(f"        {_c(st, SW)}: lwa_of = {_c(bases[st], TA)} + {TA}'(r_ & {_h(depths[st] - 1, KW)});")
        a("        default: lwa_of = '0;")
        a("    endcase")
        a("endfunction")
        cpw = "lcopy, " if dbl else ""
        a(f"(* max_fanout = 16 *) logic [{TA + dbl - 1}:0] lw_wa;")
        a("logic lw_go; assign lw_go = tacc && (lst == L_DATA);")
        a(f"always_ff @(posedge clk) lw_wa <= {{{cpw}lwa_of(ls, lw_rest)}};")
        for j in range(B):
            g = j // TL
            gm = f" && (lk[{GB - 1}:0] == {_c(g, GB)})" if GB else ""
            a(f"logic lw_we{j}; logic [{TEW - 1}:0] lw_wd{j};")
            a(f"always_ff @(posedge clk) begin lw_we{j} <= !rst && lw_go{gm}; "
              f"lw_wd{j} <= tw_data[{(j % TL) * TEW + TEW - 1}:{(j % TL) * TEW}]; end")

    def table_inst(t, inst, mod_rom, addr, outs):
        conn = [".clk(clk)", f".addr({addr})"]
        if t["mode"] == "rns":
            j_ = t["j"]
            if dbl:
                conn[1] = f".addr({{{'ccopy_a' if inl else 'ccopy'}, {addr}}})"
            conn += [f".we(lw_we{j_})", f".wa({waOf(j_)})", f".wd(lw_wd{j_})"]
            mod = rnsShapes[(tuple(t["cols"]), t["depth"])][0]
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
        t = tabs[j]
        outs = [f"twr{j}"] + ([f"twpr{j}"] if len(t["cols"]) > 1 else [])
        for o, cw in zip(outs, t["cols"]):
            a(f"logic [{cw - 1}:0] {o}, {o}_q; always_ff @(posedge clk) {o}_q <= {o};")
        table_inst(t, f"u_tw{j}", f"{name}_tw{j}", taOf(j), outs)
    twin = [[chain(f"{o}_q", cw) for o, cw in zip([f"twr{j}"] + ([f"twpr{j}"] if len(tabs[j]["cols"]) > 1 else []),
                                                   tabs[j]["cols"])] for j in range(B)]

    # --- butterflies ---------------------------------------------------------------------------------
    a(f"// ---- {B} butterflies ({bs.name}, latency {Pbu}), output register / x2^-1 halver")
    dirOf = lambda e: dirs
    if sp.halve and sp.dirPort and lv("direction"):
        _dt = _tree(a, "ft_dir", [("v", 1, "DIR_r")], P, lv("direction"))
        dirOf = lambda e: _dt(e)["v"]
    for j in range(B):
        conn = [".clk(clk)", f".aIn({opin[2 * j]})", f".bIn({opin[2 * j + 1]})", f".W({twin[j][0]})"]
        if len(tabs[j]["cols"]) > 1:
            conn.append(f".WP({twin[j][1]})")
        for pn, _ in bs.extraPorts:
            if pn not in ("W", "WP"):
                conn.append(f".{pn}({qsig(f'b{j}q', pn, j, Re + 2 + XR)})")
        a(f"logic [{bs.aOutBitWidth - 1}:0] xr{j}; logic [{bs.bOutBitWidth - 1}:0] yr{j};")
        conn += [f".aOut(xr{j})", f".bOut(yr{j})"]
        a(f"{bs.name} u_bu{j} ({', '.join(conn)});")
        ext = lambda sig, bw: sig if bw == W else f"{{{W - bw}'d0, {sig}}}"
        xv, yv = ext(f"xr{j}", bs.aOutBitWidth), ext(f"yr{j}", bs.bOutBitWidth)
        for v, dst in ((xv, f"xo{j}"), (yv, f"yo{j}")):
            a(f"logic [{W - 1}:0] {dst}, {dst}_x; assign {dst}_x = {v};")
            if sp.halve:
                qh = (qsig(f"h{j}q" if inl else f"b{j}q", "QHALF", j, Re + 2 + XR + Pbu) if "QHALF" in qw
                      else _c((sp.q + 1) // 2, W))
                hdir = dirOf(2 * j + (dst[0] == 'y'))
                if DDL and inl:       # the direction of the operation's own polynomial
                    hdir = qsig(f"h{j}q", "DIR", j, Re + 2 + XR + Pbu)
                if (dpp and not inl) or (MDIR and mbub):     # one more register, as the constants' copies: the direction switches after the bubble
                    hdir = f"b{j}q_DIR"
                    if hdir not in qcopies:
                        qcopies.add(hdir)
                        a(f"{KEEP}(* max_fanout = 16 *) logic {hdir}; always_ff @(posedge clk) {hdir} <= DIR_r;")
                a(f"always_ff @(posedge clk) {dst} <= {hdir} ? ({W}'({dst}_x >> 1) + ({dst}_x[0] ? {W}'({qh}) : {_c(0, W)})) : {dst}_x;")
            else:
                a(f"always_ff @(posedge clk) {dst} <= {dst}_x;")
    outd = {f"{k}{j}": chain(f"{k}{j}", W) for j in range(B) for k in ("xo", "yo")}

    # the fill bundle: with crossRegs registered once (max_fanout, replicated by synthesis) so the fill's
    # control and data reach the banks of every SLR register to register; the bank writes one cycle later,
    # still before the drain-side read it trails and before the compute's first read (start + 2 edges)
    fleaf = None
    if FT and FT["readTree"]:
        # the fill through trees as deep as the read trees: its writes land readTree cycles later, as the reads
        # of the drain it trails and the compute's first reads (THEORY: the fill / read order is kept)
        _ft = _tree(a, "ft_f", [("acc", 1, "acc"), ("set", 2, "fset"), ("row", H, "frow"), ("pi", 1, "fpi")]
                    + ([("sub", lsub, "fsub")] if lsub else []), 3 * P, padr(lv("fill")), rst={"acc"})
        users = {l: [] for l in range(io)}
        for k_ in range(P):
            for X_ in range(3):
                for l in sorted({k_ & (io - 1), (k_ ^ (1 << b)) & (io - 1)}):
                    users[l].append((X_, k_))
        _fd = {l: _tree(a, f"ft_x{l}", [("v", W, f"x_in_{l}")], len(users[l]), padr(lv("fill data")))
               for l in range(io)}

        def fleaf(X_, k_, l):
            return _fd[l](users[l].index((X_, k_)))["v"]
    if XR and not fleaf:
        a(f"(* max_fanout = 32 *) logic f_acc, f_pi; (* max_fanout = 32 *) logic [1:0] f_set; "
          f"(* max_fanout = 32 *) logic [{H - 1}:0] f_row;")
        a("always_ff @(posedge clk) begin f_acc <= acc; f_pi <= fpi; f_set <= fset; f_row <= frow; end")
        if lsub:
            a(f"(* max_fanout = 32 *) logic [{lsub - 1}:0] f_sub; always_ff @(posedge clk) f_sub <= fsub;")
        for l in range(io):
            a(f"(* max_fanout = 32 *) logic [{W - 1}:0] f_x{l}; always_ff @(posedge clk) f_x{l} <= x_in_{l};")
        acc_, fset_, frow_, fpi_, fsub_, xin = "f_acc", "f_set", "f_row", "f_pi", "f_sub", "f_x"
    else:
        acc_, fset_, frow_, fpi_, fsub_, xin = "acc", "fset", "frow", "fpi", "fsub", "x_in_"

    # --- write: per bank a 2:1 mux by the row parity (cgWriteSource), or the fill -----------------------
    a("// ---- write back to the other set: bank i + B (pi ^ e) <- butterfly i ^ pi B/2, output e; or the fill")
    half = B >> 1
    wsrc = lambda k: f"cb_pi[{K - 1}]"
    if lv("write select"):
        dws = len(lv("write select"))
        _ws = _tree(a, "ft_ws", [("v", 1, f"cb_pi[{K - 1 - dws}]")], P, lv("write select"))
        wsrc = lambda k: _ws(k)["v"]
    for k in range(P):
        tb_ = k >> b
        lo = k % B
        src0 = outd[f"{'xo' if tb_ == 0 else 'yo'}{lo}"]                         # pi = 0: butterfly lo, output tb_
        src1 = outd[f"{'xo' if tb_ == 1 else 'yo'}{lo ^ half if b else 0}"]     # pi = 1: butterfly lo ^ B/2, output 1 - tb_
        a(f"{KEEP}(* max_fanout = 32 *) logic wsel{k}; always_ff @(posedge clk) wsel{k} <= {wsrc(k)};")
        a(f"logic [{W - 1}:0] wdat{k}; assign wdat{k} = wsel{k} ? {src1} : {src0};")
        if H >= 2:
            waddr = f"{{w_pi ^ 1'b{tb_}, w_row[{H - 1}:1]}}"
        else:
            waddr = f"(w_pi ^ 1'b{tb_})"
        k0, k1 = k, k ^ (1 << b)
        l0, l1 = k0 & (io - 1), k1 & (io - 1)
        for X in range(3):
            m = f"m{X}_{k}"
            wl = wleaf(X, k)
            if H >= 2:
                waddr = f"{{{wl['pi']} ^ 1'b{tb_}, {wl['row']}[{H - 1}:1]}}"
            else:
                waddr = f"({wl['pi']} ^ 1'b{tb_})"
            if fleaf:
                fl_ = _ft(3 * k + X)
                acc_, fset_, frow_, fpi_, fsub_ = fl_["acc"], fl_["set"], fl_["row"], fl_["pi"], fl_.get("sub")
                fd0, fd1 = fleaf(X, k, l0), fleaf(X, k, l1)
            else:
                fd0, fd1 = f"{xin}{l0}", f"{xin}{l1}"
            if lsub:
                fwe = f"({fpi_} ? ({fsub_} == {_c(k1 >> (io.bit_length() - 1), lsub)}) : ({fsub_} == {_c(k0 >> (io.bit_length() - 1), lsub)}))"
            else:
                fwe = "1'b1"
            fdat = fd0 if l0 == l1 else f"({fpi_} ? {fd1} : {fd0})"
            a("always_ff @(posedge clk) begin")
            a(f"    if (rst) {m}_we <= 1'b0;")
            a(f"    else if ({wl['v']} && {wl['set']} == 2'd{X}) begin {m}_we <= 1'b1; {m}_wa <= {waddr}; {m}_wd <= wdat{k}; end")
            a(f"    else if ({acc_} && {fset_} == 2'd{X} && {fwe}) begin {m}_we <= 1'b1; {m}_wa <= {frow_}; {m}_wd <= {fdat}; end")
            a(f"    else {m}_we <= 1'b0;")
            a("end")

    # --- output stream (as in place, 3 sets) ---------------------------------------------------------
    a("// ---- output: lane l of beat (row, sub) is bank ((sub*io + l) ^ (parity(row) << b))")
    dsel = lambda k: f"db_set[{Re}]"
    if lv("drain select"):
        dd_ = len(lv("drain select"))
        _dt2 = _tree(a, "ft_ds", [("v", 2, f"db_set[{Re - dd_}]")], P, lv("drain select"))
        dsel = lambda k: _dt2(k)["v"]
    osel = lambda l: f"{{db_sub[{Re}], db_pi[{Re}]}}"
    if lv("output select"):
        do_ = len(lv("output select"))
        _ot = _tree(a, "ft_os", [("v", DSUB + 1, f"{{db_sub[{Re - do_}], db_pi[{Re - do_}]}}")], io,
                    lv("output select"))
        osel = lambda l: _ot(l)["v"]
    for k in range(P):
        a(f"logic [{W - 1}:0] drd{k};")
        a(f"always_comb case ({dsel(k)}) 2'd1: drd{k} = m1_{k}_rd; 2'd2: drd{k} = m2_{k}_rd; default: drd{k} = m0_{k}_rd; endcase")
    nsub = 1 << lsub
    for l in range(io):
        a(f"logic [{W - 1}:0] yr_{l};")
        a(f"always_ff @(posedge clk) case ({osel(l)})")
        for sub in range(nsub):
            for pi in (0, 1):
                kk = (sub * io + l) ^ (pi << b)
                a(f"    {{{_c(sub, DSUB)}, 1'b{pi}}}: yr_{l} <= drd{kk};")
        a(f"    default: yr_{l} <= drd{l};")
        a("endcase")
    a("logic yv; always_ff @(posedge clk) yv <= rst ? 1'b0 : db_v[%d];" % Re)
    if tw is not None:
        dp = tw["datapath"]
        pw = dp.wire(dict(dp.outputs)["P"]).bitWidth
        ain = {x.name: x.bitWidth for x in dp.inputs}
        tq = "" if mr else "".join(f", .{x.name}({qsig('twq', x.name)})" for x in dp.inputs if x.name not in ("A", "B"))
        TTA = _bits(ttabs[0].get("depth1", ttabs[0]["depth"]))
        a(f"(* max_fanout = 16 *) logic [{TTA - 1}:0] tta;")
        off = f" + ({'ddir' if mr else dirs} ? {_c(NB, TTA)} : {_c(0, TTA)})" if sp.dirPort else ""
        if mr:
            # the drained polynomial's index with the address; its constants with the data at the multipliers
            a(f"logic [{MB - 1}:0] dmidx_a, dmd [{R + 1}];")
            a(f"always_ff @(posedge clk) begin dmidx_a <= dmidx; dmd[0] <= dmidx; "
              f"for (int i = 1; i <= {R}; i++) dmd[i] <= dmd[i-1]; end")
            tq = ""
            for x in dp.inputs:
                if x.name in ("A", "B"):
                    continue
                a(f"(* max_fanout = 16 *) logic [{qw[x.name] - 1}:0] tq_{x.name}; "
                  f"always_ff @(posedge clk) tq_{x.name} <= mt_{x.name}(dmd[{R}]);")
                tq += f", .{x.name}(tq_{x.name})"
        a(f"always_ff @(posedge clk) tta <= {TTA}'(dptr){off};")
        ttaOf = "tta"
        if FT and FT["readTree"]:        # the twist tables read as late as the drained banks
            ttaOf = _tree(a, "ft_tt", [("v", TTA, "tta")], 1, [1] * FT["readTree"])(0)["v"]
        for l, t in enumerate(ttabs):
            a(f"logic [{t['cols'][0] - 1}:0] ttr{l}, ttr{l}_q; logic [{pw - 1}:0] tp{l};")
            a(f"always_ff @(posedge clk) ttr{l}_q <= ttr{l};")
            table_inst(t, f"u_tt{l}", f"{name}_tt{l}", ttaOf, [f"ttr{l}"])
            av = f"yr_{l}" if ain["A"] == W else f"{ain['A']}'(yr_{l})"
            a(f"{dp.name} u_twist{l} (.clk(clk), .A({av}), .B(ttr{l}_q){tq}, .P(tp{l}));")
            a(f"assign y_out_{l} = tp{l};")
        TLat = tw["latency"]
        if TLat:
            a(f"logic [{TLat - 1}:0] ovd; always_ff @(posedge clk) ovd <= rst ? '0 : "
              + (f"{{ovd[{TLat - 2}:0], yv}};" if TLat > 1 else "yv;"))
            a(f"assign out_valid = ovd[{TLat - 1}];")
        else:
            a("assign out_valid = yv;")
    else:
        for l in range(io):
            a(f"assign y_out_{l} = yr_{l};")
        a("assign out_valid = yv;")

    if mr:
        _mrom_otag(a, MB, MDIR, TG, Re + 2 + (tw["latency"] if tw is not None else 0))
    hdr = (f"// {name}: iterative NTT, constant geometry, n={sp.n}, {B} butterflies over 3 x {P} banks of {T} x {W} "
           f"bits, {io} I/O lanes, {'q=' + str(sp.q) if sp.q else 'run-time q'}, direction {sp.direction}, "
           f"butterfly latency {Pbu}, write-back latency {Pw}, stage gaps {list(sp.gaps)}, read-order shifts {shifts}")
    if sp.memOrgReport:
        hdr += f"\n// memOrg auto: {sp.memOrgReport['choice']} ({sp.memOrgReport['reason']})"
    if mr:
        hdr += (f"\n// moduli= {list(mr['moduli'])} in the ROMs (MIDX / DIR with a polynomial's first input beat), "
                f"qSwitch {'inline' if inl else 'bubble'}")
    top = ["`timescale 1ns / 1ps", hdr, f"module {name} (\n" + ",\n".join(ports) + "\n    );"] + O + ["endmodule"]
    with open(os.path.join(rtl, f"{name}.sv"), "w", encoding="utf-8") as f:
        f.write("\n".join(top) + "\n")

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
        if mr:
            _mrom_vectors(tv, tb)
        if rns:
            with open(os.path.join(tv, "tw_stream.txt"), "w") as f:
                f.write("".join(to_twos_complement_hex(v, TLW) + "\n" for v in tb["tw"]))
            with open(os.path.join(tv, "twvalid.txt"), "w") as f:
                f.write("".join(f"{v}\n" for v in tb["twvalid"]))
        with open(os.path.join(rtl, f"{name}_tb.sv"), "w", encoding="utf-8") as f:
            f.write(_tb(sp, tb, NX, NY, NC, TWW))
    manifest = {"top_name": name, "n": sp.n, "butterflies": B, "io_lanes": io, "banks": 3 * P, "bank_depth": T,
                "width": W, "out_width": sp.outWidth, "bu_latency": Pbu, "write_latency": Pw,
                "out_latency": sp.outLatency, "gaps": list(sp.gaps), "q_ports": [p for p, _ in qports],
                "q_port_widths": [w for _, w in qports], "load_words": loadW, "tw_width": TWW,
                "dir_port": sp.dirPort, "mem_style": sp.memStyle, "twiddle_style": sp.twiddleStyle,
                "mem_org": "constgeo", "cross_regs": XR, "cg_shifts": shifts, "tw_bases": bases, "tw_depths": depths,
                "mem_org_report": sp.memOrgReport}
    if rns:
        manifest.update(twiddle_buffer=sp.twiddleBuffer, tw_lanes=TL, tw_entry_cols=ecols, tw_beat_width=TLW,
                        header_beats=HB, header_layout=[list(x) for x in sp.headerLayout], stage_beats=NBs,
                        q_bubble=0 if inl else QB)
    if mr:
        manifest.update(moduli=list(mr["moduli"]), midx_bits=MB, q_switch="inline" if inl else "bubble",
                        q_bubble=0 if inl else mr["bubble"], modulus_table={k: list(v) for k, v in mr["table"].items()})
    if rec:
        manifest.update(twiddle_source="rec", rec_group=rc["group"], rec_generators=B // rc["group"],
                        rec_units=len(rc["units"]), rec_gen_latency=rc["genLatency"],
                        rec_stream_beats=rc["streamBeats"], rec_factor_layout=[list(x) for x in rc["factorLayout"]])
    with open("manifest.json", "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    return manifest


def _tree(a, tag, sigs, N, levels, rst=()):
    """Register trees for a broadcast to N sinks: `levels` registers per level (source side first, from
    IterativeNTTScheme.treeLevels), each fed by its parent (index j * n_prev / n), kept (no merging of the
    copies). sigs = [(name, width, source expression)]; `rst`: names reset to 0 (valids). Returns
    leaf(t) -> {name: expression} for sink t (sink t takes leaf t * n_last / N)."""
    if not levels:
        return lambda t: {nm: src for nm, w, src in sigs}
    for nm, w, src in sigs:
        for i, n in enumerate(levels):
            a(f'(* keep = "true" *) logic [{w - 1}:0] {tag}_{nm}_l{i} [{n}];')
        a("always_ff @(posedge clk) begin")
        if nm in rst:
            a("    if (rst) begin")
            for i, n in enumerate(levels):
                a(f"        for (int j = 0; j < {n}; j++) {tag}_{nm}_l{i}[j] <= '0;")
            a("    end else begin")
            ind = "        "
        else:
            ind = "    "
        a(f"{ind}for (int j = 0; j < {levels[0]}; j++) {tag}_{nm}_l0[j] <= {src};")
        for i in range(1, len(levels)):
            a(f"{ind}for (int j = 0; j < {levels[i]}; j++) {tag}_{nm}_l{i}[j] <= "
              f"{tag}_{nm}_l{i - 1}[(j * {levels[i - 1]}) / {levels[i]}];")
        if nm in rst:
            a("    end")
        a("end")
    last, nl = len(levels) - 1, levels[-1]
    return lambda t: {nm: f"{tag}_{nm}_l{last}[{(t * nl) // N}]" for nm, w, src in sigs}


def _rec_loader(a, sp, rc, L, H, T, B, SW, HB, HBW, QB, QBW, RW, TLW, TEW, qports):
    """twiddleSource 'rec': the loader (twin IterativeNTTScheme._simulateJobRec). The header beats as the
    streamed record's; then the record's units (rc['units']) in order, one a cycle at most: a stream beat when
    tw_valid, a generator operation or bubble any cycle, each when its own region is free; the write side
    (region count for the stage hold, the end of DATA) follows the unit pipeline's last stage."""
    from rtl_gen.iter_ntt import _bits, _c
    units = list(rc["units"])
    NU = len(units)
    UW = _bits(NU)
    G = rc["group"]
    g = G.bit_length() - 1
    CW = max(1, g)
    D = rc["genLatency"] - 1                      # unit pipeline stages between the issue and the write register
    a(f"// ---- the loader, twiddleSource 'rec': {NU} units a record ({rc['streamBeats']} stream beats, generator "
      f"operations, bubbles), write {D + 1} cycles after the issue")
    a("localparam logic [1:0] K_B = 2'd0, K_S = 2'd1, K_G = 2'd2;")
    a(f"logic [{UW - 1}:0] iu; logic ifin;")
    a(f"logic [1:0] u_kind; logic [{SW - 1}:0] u_s; logic [{H - 1}:0] u_idx; logic [{CW - 1}:0] u_c; logic u_rl, u_last;")
    a("always_comb begin")
    a("    case (iu)")
    kind = {'B': "K_B", 'S': "K_S", 'G': "K_G"}
    for i, (st, k, idx, c, rl, last) in enumerate(units):
        a(f"        {_c(i, UW)}: begin u_kind = {kind[k]}; u_s = {_c(st, SW)}; u_idx = {_c(idx, H)}; "
          f"u_c = {_c(c, CW)}; u_rl = 1'b{int(rl)}; u_last = 1'b{int(last)}; end")
    a("        default: begin u_kind = K_B; u_s = '0; u_idx = '0; u_c = '0; u_rl = 1'b0; u_last = 1'b0; end")
    a("    endcase")
    a("end")
    a("logic u_ok, iss, wev_v, wev_rl, wev_last;")
    a("assign u_ok = (lst == L_DATA) && !ifin;")
    a(f"assign perm = !lahead || (relst > {RW}'(u_s));")
    a("assign tw_ready = (lst == L_HDR) || (u_ok && perm && (u_kind == K_S));")
    a("assign tacc = tw_valid && tw_ready && !rst;")
    a("assign iss = u_ok && perm && ((u_kind == K_S) ? tw_valid : 1'b1) && !rst;")
    a(f"assign hlast = hptr == {_c(HB - 1, HBW)};" if HB > 1 else "assign hlast = 1'b1;")
    HW_ = HB * TLW
    if HB > 1:
        a(f"logic [{TLW - 1}:0] hb [{HB - 1}];")
        a(f"logic [{HW_ - 1}:0] hdr_w; assign hdr_w = {{tw_data, " + ", ".join(f"hb[{k}]" for k in range(HB - 2, -1, -1)) + "};")
    else:
        a(f"logic [{HW_ - 1}:0] hdr_w; assign hdr_w = tw_data;")
    a("assign hkeep = hdr_w[0];")
    a("always_comb begin")
    a("    lst_n = lst; lahead_n = lahead; ws_n = ws; hptr_n = hptr;")
    a("    case (lst)")
    a("        L_HDR: if (tacc) begin")
    a("            if (hlast) begin")
    a("                hptr_n = '0;")
    a("                if (hkeep) lst_n = L_WAIT;")
    a("                else begin lst_n = L_DATA; ws_n = '0; lahead_n = 1'b1; end")
    a("            end else hptr_n = hptr + 1'b1;")
    a("        end")
    a("        L_DATA: begin")
    a("            if (startc) lahead_n = 1'b0;")
    a("            if (wev_v) begin")
    a("                if (wev_rl) ws_n = ws + 1'b1;")
    a("                if (wev_last) begin ws_n = '0; lst_n = (lahead && !startc) ? L_WAIT : L_HDR; end")
    a("            end")
    a("        end")
    a("        L_WAIT: if (startc) lst_n = L_HDR;")
    a("        default: lst_n = L_HDR;")
    a("    endcase")
    a("end")
    a(f"logic [{SW - 1}:0] s_nx; logic [{H - 1}:0] tau_nx;")
    a("assign s_nx = startc ? '0 : ((issue && tlast) ? s + 1'b1 : s);")
    a("assign tau_nx = startc ? '0 : (issue ? (tlast ? '0 : tau + 1'b1) : tau);")
    a("always_ff @(posedge clk) begin")
    a("    if (rst) begin")
    a(f"        lst <= L_HDR; lahead <= 1'b1; ws <= '0; hptr <= '0; nkeep <= 1'b0; qw <= '0; relst <= {_c(L, RW)}; "
      f"twok <= 1'b0; iu <= '0; ifin <= 1'b0;")
    a("    end else begin")
    a("        lst <= lst_n; lahead <= lahead_n; ws <= ws_n; hptr <= hptr_n;")
    a("        if (lst == L_HDR && tacc && hlast) nkeep <= hkeep;")
    a("        if (lst == L_HDR && tacc && hlast && !hkeep) begin iu <= '0; ifin <= 1'b0; end")
    a("        else if (iss) begin if (u_last) begin iu <= '0; ifin <= 1'b1; end else iu <= iu + 1'b1; end")
    a(f"        qw <= clast ? {_c(QB, QBW)} : ((qw != '0) ? qw - 1'b1 : '0);")
    a(f"        if (startc) relst <= '0; else if (clast) relst <= {_c(L, RW)}; "
      f"else if (issue && (tau == '0)) relst <= {RW}'(s);")
    a("        twok <= (tau_nx != '0) || !((lst_n == L_DATA) && !lahead_n) || (ws_n > s_nx);")
    a("    end")
    a("end")
    for j, beta, off, w in rc["factorLayout"]:
        a(f"logic [{w - 1}:0] F{j}_{beta}_n;      // header: region H+{j} = region H+{j - 1} x F (bit b-{j} = {beta})")
    a("always_ff @(posedge clk) begin")
    if HB > 1:
        a("    if (lst == L_HDR && tacc && !hlast) hb[hptr] <= tw_data;")
    for qp, off, w in sp.headerLayout:
        a(f"    if (lst == L_HDR && tacc && hlast && !hkeep) {qp}_n <= hdr_w[{off + w - 1}:{off}];")
    for j, beta, off, w in rc["factorLayout"]:
        a(f"    if (lst == L_HDR && tacc && hlast && !hkeep) F{j}_{beta}_n <= hdr_w[{off + w - 1}:{off}];")
    a("    if (!rst && startc && !nkeep) begin " + " ".join(f"{qp}_r <= {qp}_n;" for qp, _ in qports) + " end")
    a("end")


def _rec_writes(a, sp, rc, L, H, T, B, b, SW, TA, TEW, bases, depths, qsig, FT=None):
    """twiddleSource 'rec': the unit pipeline, the generator groups and the table write ports. A unit issued
    in cycle c: c+1 its fields registered, the group stores read (LUTRAM) and the factor selected; c+2 the
    multiplier's operands; c+2+Pm its product; the table / store write registers in cycle c+3+Pm = c+PG
    (IterativeNTTScheme.genLatency). A stream beat travels the same pipeline (lane 0: butterflies
    k < B/2, lane 1: k >= B/2)."""
    from rtl_gen.iter_ntt import _bits, _c
    G = rc["group"]
    g = G.bit_length() - 1
    NG = B // G
    CW = max(1, g)
    D = rc["genLatency"] - 1
    gen = rc["gen"]
    E = TEW
    CSW = max(0, g - 1)                          # store: {region parity, parent class, row}
    SA = 1 + CSW + H
    SD = 1 << SA
    flw = rc["factorLayout"]
    lv = (lambda nm: list(FT["levels"].get(nm, []))) if FT else (lambda nm: [])
    dg = FT["genTree"] if FT else 0              # generator-operand tree (part of genLatency)
    a(f"// ---- twiddleSource 'rec': {NG} groups of {G} butterflies, "
      + (f"one multiplier ({gen['datapath'].name}, latency {gen['latency']}) each" if gen else "no generator "
         "(every region on the stream)"))
    # issue-time decode: table address, store addresses, the class mask, the factor bit per group
    a(f"function automatic logic [{TA - 1}:0] rwa_of(input logic [{SW - 1}:0] s_, input logic [{H - 1}:0] r_);")
    a("    case (s_)")
    for st in range(L):
        a(f"        {_c(st, SW)}: rwa_of = {_c(bases[st], TA)} + {TA}'(r_ & {H}'d{depths[st] - 1});")
    a("        default: rwa_of = '0;")
    a("    endcase")
    a("endfunction")
    a(f"logic [{TA - 1}:0] i_ta; assign i_ta = rwa_of(u_s, u_idx);")
    a(f"logic [{G - 1}:0] i_mask;")
    a("always_comb begin")
    a("    case (u_s)")
    for st in range(H + 2, L):
        j = st - H
        if b - j < g:
            bits = ", ".join(f"(u_c == {_c(l >> (b - j), CW)})" for l in range(G - 1, -1, -1))
            a(f"        {_c(st, SW)}: i_mask = {{{bits}}};")
    a("        default: i_mask = '1;")
    a("    endcase")
    a("end")
    if gen:
        a(f"logic [{NG - 1}:0] i_kv; logic i_fl;")
        a("always_comb begin")
        a("    case (u_s)")
        for st in range(H + 2, L):
            j = st - H
            if b - j < g:
                a(f"        {_c(st, SW)}: begin i_fl = 1'b1; i_kv = '0; end")
            else:
                kv = "".join(str(((gi * G) >> (b - j)) & 1) for gi in range(NG - 1, -1, -1))
                a(f"        {_c(st, SW)}: begin i_fl = 1'b0; i_kv = {NG}'b{kv}; end")
        a("        default: begin i_fl = 1'b0; i_kv = '0; end")
        a("    endcase")
        a("end")
        fw = gen["datapath"]
        ain = {x.name: x.bitWidth for x in fw.inputs}
        a(f"(* max_fanout = 16 *) logic [{ain['B'] - 1}:0] fa_q, fb_q;     // F[j][0], F[j][1] of the unit's region")
        a("always_ff @(posedge clk) begin")
        a("    case (u_s)")
        for st in range(H + 2, L):
            j = st - H
            a(f"        {_c(st, SW)}: begin fa_q <= F{j}_0_n; fb_q <= F{j}_1_n; end")
        a("        default: begin fa_q <= '0; fb_q <= '0; end")
        a("    endcase")
        a("end")
        # store addresses: read {(j-1) & 1, c >> 1, r}, write {j & 1, c, r} (the stream's region H+1: {1, 0, e})
        cpar = f"u_c[{CW - 1}:1], " if CSW else ""
        cown = f"u_c[{CSW - 1}:0], " if CSW else ""
        a(f"logic [{SA - 1}:0] i_ra, i_swa; logic i_swe;")
        a(f"logic [{SW - 1}:0] u_sh; assign u_sh = u_s - {_c(H, SW)};          // j")
        a(f"assign i_ra = {{~u_sh[0], {cpar}u_idx}};")
        a(f"assign i_swa = (u_kind == K_S) ? {{1'b1, {(str(CSW) + chr(39) + 'd0, ') if CSW else ''}u_idx}} : {{u_sh[0], {cown}u_idx}};")
        a(f"assign i_swe = ((u_kind == K_S) && (u_s == {_c(H + 1, SW)})) || ((u_kind == K_G) && (u_s != {_c(L - 1, SW)}));")
    # the unit pipeline: q*[k] holds the unit issued k+1 cycles ago (k = 0 .. D-1)
    if D > 0:
        a(f"logic q_v [{D}]; logic [1:0] q_k [{D}]; logic q_rl [{D}]; logic q_last [{D}]; "
          f"logic [{TA - 1}:0] q_ta [{D}]; logic [{G - 1}:0] q_mask [{D}]; logic [{2 * E - 1}:0] q_sd [{D}];")
        a("always_ff @(posedge clk) begin")
        a(f"    if (rst) for (int i = 0; i < {D}; i++) q_v[i] <= 1'b0;")
        a("    else begin")
        a("        q_v[0] <= iss;")
        a(f"        for (int i = 1; i < {D}; i++) q_v[i] <= q_v[i-1];")
        a("    end")
        a(f"    q_k[0] <= u_kind; q_rl[0] <= u_rl; q_last[0] <= u_last; q_ta[0] <= i_ta; q_mask[0] <= i_mask; "
          f"q_sd[0] <= tw_data[{2 * E - 1}:0];")
        a(f"    for (int i = 1; i < {D}; i++) begin q_k[i] <= q_k[i-1]; q_rl[i] <= q_rl[i-1]; q_last[i] <= q_last[i-1]; "
          f"q_ta[i] <= q_ta[i-1]; q_mask[i] <= q_mask[i-1]; q_sd[i] <= q_sd[i-1]; end")
        a("end")
        wv, wk, wrl, wlast, wta, wmask, wsd = (f"q_v[{D - 1}]", f"q_k[{D - 1}]", f"q_rl[{D - 1}]", f"q_last[{D - 1}]",
                                              f"q_ta[{D - 1}]", f"q_mask[{D - 1}]", f"q_sd[{D - 1}]")
    else:
        wv, wk, wrl, wlast, wta, wmask, wsd = "iss", "u_kind", "u_rl", "u_last", "i_ta", "i_mask", "tw_data"
    a(f"assign wev_v = {wv}; assign wev_rl = {wrl}; assign wev_last = {wlast};")
    if gen:
        a(f"logic [{SA - 1}:0] q_ra, q_swa [{D}]; logic q_swe [{D}]; logic q_fl, q_c0; logic [{NG - 1}:0] q_kv;")
        a("always_ff @(posedge clk) begin")
        a("    q_ra <= i_ra; q_fl <= i_fl; q_c0 <= u_c[0]; q_kv <= i_kv; q_swa[0] <= i_swa; q_swe[0] <= i_swe;")
        a(f"    for (int i = 1; i < {D}; i++) begin q_swa[i] <= q_swa[i-1]; q_swe[i] <= q_swe[i-1]; end")
        a("end")
        dp = gen["datapath"]
        pw = dp.wire(dict(dp.outputs)["P"]).bitWidth
        ain = {x.name: x.bitWidth for x in dp.inputs}
        if not FT:
            a(f"(* max_fanout = 16 *) logic st_we; (* max_fanout = 16 *) logic [{SA - 1}:0] st_wa;")
            a(f"always_ff @(posedge clk) begin st_we <= !rst && {wv} && q_swe[{D - 1}]; st_wa <= q_swa[{D - 1}]; end")
            opl = lambda gi: {"ra": "q_ra", "fl": "q_fl", "c0": "q_c0", "fa": "fa_q", "fb": "fb_q"}
            kvb = lambda gi: f"q_kv[{gi}]"
            gwl = lambda gi: {"k": wk, "sd": wsd}
            stw = lambda gi: ("st_we", "st_wa")
            gcs = lambda gi, x: f"{x.name}_n[{x.bitWidth - 1}:0]"
        else:
            # the operands of every group through a tree of dg levels (genLatency counts them), the per-group
            # factor bits delayed as much; the write-side signals of the groups taken earlier from the unit
            # pipeline (no cycle change); the header's constants to the groups through a static tree
            _op = _tree(a, "ft_go", [("ra", SA, "q_ra"), ("fl", 1, "q_fl"), ("c0", 1, "q_c0"),
                                     ("fa", ain['B'], "fa_q"), ("fb", ain['B'], "fb_q")], NG, lv("generator operands"))
            opl = lambda gi: _op(gi)
            if dg:
                a(f"logic [{NG - 1}:0] q_kvd [{dg}];")
                a("always_ff @(posedge clk) begin q_kvd[0] <= q_kv; "
                  + (f"for (int i = 1; i < {dg}; i++) q_kvd[i] <= q_kvd[i-1]; " if dg > 1 else "") + "end")
                kvb = lambda gi: f"q_kvd[{dg - 1}][{gi}]"
            else:
                kvb = lambda gi: f"q_kv[{gi}]"
            dgw = len(lv("generator writes"))
            ti = D - 1 - dgw
            assert ti >= 0
            _gw = _tree(a, "ft_gw", [("k", 2, f"q_k[{ti}]"), ("sd", 2 * E, f"q_sd[{ti}]"),
                                     ("we", 1, f"(q_v[{ti}] && q_swe[{ti}])"), ("wa", SA, f"q_swa[{ti}]")], NG,
                        lv("generator writes"), rst={"we"})
            gwl = lambda gi: _gw(gi)
            for gi in range(NG):
                a(f"(* keep = \"true\" *) logic st_we{gi}; (* keep = \"true\" *) logic [{SA - 1}:0] st_wa{gi};")
                a(f"always_ff @(posedge clk) begin st_we{gi} <= !rst && {_gw(gi)['we']}; st_wa{gi} <= {_gw(gi)['wa']}; end")
            stw = lambda gi: (f"st_we{gi}", f"st_wa{gi}")
            cts = {x.name: _tree(a, f"ft_gq{x.name}", [("v", x.bitWidth, f"{x.name}_n[{x.bitWidth - 1}:0]")], NG,
                                 lv("generator constants")) for x in dp.inputs if x.name not in ("A", "B")}
            gcs = lambda gi, x: cts[x.name](gi)["v"]
    for gi in range(NG):
        kt = ((gi * G) >> (b - 1)) & 1
        lane = f"{wsd}[{(kt + 1) * E - 1}:{kt * E}]"
        if gen:
            a(f"// group {gi}: butterflies {gi * G} .. {gi * G + G - 1} (lane {kt})")
            a(f"(* ram_style = \"distributed\" *) logic [{E - 1}:0] st{gi} [{SD}];")
            a(f"logic [{E - 1}:0] gd{gi}, gsd{gi}, gx{gi}; logic [{ain['B'] - 1}:0] gf{gi}; logic [{pw - 1}:0] gp{gi};")
            o_ = opl(gi)
            swe_, swa_ = stw(gi)
            a(f"always_ff @(posedge clk) if ({swe_}) st{gi}[{swa_}] <= gsd{gi};")
            a(f"always_ff @(posedge clk) begin gx{gi} <= st{gi}[{o_['ra']}]; "
              f"gf{gi} <= ({o_['fl']} ? {o_['c0']} : {kvb(gi)}) ? {o_['fb']} : {o_['fa']}; end")
            for x in dp.inputs:            # the generators run on the next polynomial's constants (the header's)
                if x.name not in ("A", "B"):
                    a(f"(* max_fanout = 16 *) logic [{x.bitWidth - 1}:0] g{gi}q_{x.name}; "
                      f"always_ff @(posedge clk) g{gi}q_{x.name} <= {gcs(gi, x)};")
            tq = "".join(f", .{x.name}(g{gi}q_{x.name})" for x in dp.inputs if x.name not in ("A", "B"))
            av = f"gx{gi}" if ain["A"] == E else f"{ain['A']}'(gx{gi})"
            a(f"{dp.name} u_gen{gi} (.clk(clk), .A({av}), .B(gf{gi}){tq}, .P(gp{gi}));")
            gpv = f"gp{gi}" if pw == E else f"{E}'(gp{gi})"
            gw_ = gwl(gi)
            lane_ = f"{gw_['sd']}[{(kt + 1) * E - 1}:{kt * E}]"
            a(f"assign gd{gi} = ({gw_['k']} == K_S) ? {lane_} : {gpv};")
            a(f"always_ff @(posedge clk) gsd{gi} <= gd{gi};")
        else:
            a(f"logic [{E - 1}:0] gd{gi}; assign gd{gi} = {lane};")
    if lv("table writes"):
        # the table write ports' address and enables taken earlier from the unit pipeline: the address leaves
        # are the write address registers (cycle c+PG), the enable leaves feed the per-table enables
        dtw = len(lv("table writes"))
        assert D - dtw >= 0 and dtw >= 1
        _tw = _tree(a, "ft_tw", [("v", 1, f"q_v[{D - 1 - dtw}]"), ("k", 2, f"q_k[{D - 1 - dtw}]"),
                                 ("mask", G, f"q_mask[{D - 1 - dtw}]")], B, lv("table writes"), rst={"v"})
        _twa = _tree(a, "ft_twa", [("wa", TA, f"q_ta[{D - dtw}]")], B, lv("table writes"))
        for j in range(B):
            gi, l = j // G, j % G
            t_ = _tw(j)
            a(f"logic lw_we{j}; logic [{TEW - 1}:0] lw_wd{j};")
            a(f"always_ff @(posedge clk) begin lw_we{j} <= !rst && {t_['v']} && (({t_['k']} == K_S) || "
              f"(({t_['k']} == K_G) && {t_['mask']}[{l}])); lw_wd{j} <= gd{gi}; end")
        return lambda j: _twa(j)["wa"]
    a(f"(* max_fanout = 16 *) logic [{TA - 1}:0] lw_wa;")
    a(f"always_ff @(posedge clk) lw_wa <= {wta};")
    for j in range(B):
        gi, l = j // G, j % G
        a(f"logic lw_we{j}; logic [{TEW - 1}:0] lw_wd{j};")
        a(f"always_ff @(posedge clk) begin lw_we{j} <= !rst && {wv} && (({wk} == K_S) || (({wk} == K_G) && "
          f"{wmask}[{l}])); lw_wd{j} <= gd{gi}; end")
    return lambda j: "lw_wa"
