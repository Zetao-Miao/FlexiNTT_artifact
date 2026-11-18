"""twiddleSource 'rec' for the in-place iterative NTT (twiddleBuffer 'recycle'): the loader and the generator
groups that write every twiddle table on chip (IterativeNTTScheme.recIpPlan; twin `_simulateJobRec`).

The record is its header alone: keep, the modulus constants, the factors RF<i> (generator domain, RF0 the
identity) and the stage seeds RS<i>. A record's units are issued in order, at most one a cycle, each when
its own stage region is free: per stage the prefix (rc['plan']['prefix']: the chain and the doubling steps
with their bubbles, a small ROM) up to the stage's last prefix step, then the stride y = SD .. N-1 (a
counter). A unit issued in cycle c: c+1 its fields registered; c+2 the multiplier's operands (the seed or
the group store's entry, the factor or the identity); c+2+Pm the product; the table and store write
registers in cycle c+3+Pm = c+PG (IterativeNTTScheme.genLatency). Called by rtl_gen/iter_ntt.py.

With seeds (recSeeds, rc['plan']['K'] >= 1; IterativeNTTScheme._recIpPlanSeeded) each stage's units start with
its seed beats, taken from the record stream (tw_ready also in DATA): for y = 0 .. kk-1, for m = 0 .. NGP-1 one
beat = entry y of groups 2m (tw_data lane 0) and 2m+1 (lane 1). A seed beat is a unit like any other: the two
groups' multipliers take the lane as operand and the identity factor RF0, and table and store are written in
cycle c+PG, the other groups masked. Then the prefix ROM (doubling steps y >= K and bubbles) and the stride as
before. There is no chain and the header has no stage seeds. Without seeds the emitted text is unchanged.
"""


def rec_ip_loader(a, sp, rc, L, SW, HB, HBW, QB, QBW, RW, TLW, qports):
    """The loader: header beats as the streamed record's, then the units; the write side (region count for
    the stage hold, the end of DATA) follows the unit pipeline's last stage."""
    from rtl_gen.iter_ntt import _bits, _c
    pl = rc["plan"]
    d, SD, b, g = pl["d"], pl["SD"], sp.b, pl["g"]
    prefix, plast, N = list(pl["prefix"]), list(pl["plast"]), list(pl["N"])
    NP = max(plast) + 1
    PW = _bits(NP)
    YW = max(d, _bits(max(N)))
    NSL = len(pl["slots"])
    SLW = _bits(NSL)
    CHW = _bits(max(1, pl["nA"]))
    D = rc["genLatency"] - 1
    if pl.get("K"):
        _seeded_units(a, sp, rc, L, SW, RW, PW, YW, NSL, SLW, NP)
        _loader_tail(a, sp, rc, L, SW, HB, HBW, QB, QBW, RW, TLW, qports, seeded=True)
        return
    a(f"// ---- the loader, twiddleSource 'rec' in place: {rc['units']} units a record (no stream beats; per "
      f"stage a prefix of at most {NP} steps, then the stride), write {D + 1} cycles after the issue")
    a(f"logic [{SW - 1}:0] us; logic upre, ifin; logic [{PW - 1}:0] up; logic [{YW - 1}:0] uy;")
    a(f"logic p_g, p_as, p_chv, p_wt; logic [{d - 1}:0] p_y, p_ra; logic [{SLW - 1}:0] p_slot; logic [{CHW - 1}:0] p_ch;")
    a("always_comb begin")
    a("    case (up)")
    for i, st in enumerate(prefix[:NP]):
        if st[0] == 'B':
            a(f"        {_c(i, PW)}: begin p_g = 1'b0; p_y = '0; p_as = 1'b0; p_ra = '0; p_slot = '0; p_chv = 1'b0; "
              f"p_ch = '0; p_wt = 1'b0; end")
        else:
            _, y, asrc, ra, slot, ch, wt = st
            a(f"        {_c(i, PW)}: begin p_g = 1'b1; p_y = {_c(y, d)}; p_as = 1'b{asrc}; p_ra = {_c(ra, d)}; "
              f"p_slot = {_c(slot, SLW)}; p_chv = 1'b{int(ch >= 0)}; p_ch = {_c(max(ch, 0), CHW)}; p_wt = 1'b{wt}; end")
    a("        default: begin p_g = 1'b0; p_y = '0; p_as = 1'b0; p_ra = '0; p_slot = '0; p_chv = 1'b0; p_ch = '0; "
      "p_wt = 1'b0; end")
    a("    endcase")
    a("end")
    a(f"logic [{PW - 1}:0] u_pl; logic [{YW - 1}:0] u_yl; logic u_str;       // the stage's last prefix step, "
      "last entry, stride")
    a("always_comb begin")
    a("    case (us)")
    for st in range(L):
        a(f"        {_c(st, SW)}: begin u_pl = {_c(plast[st], PW)}; u_yl = {_c(N[st] - 1, YW)}; "
          f"u_str = 1'b{int(N[st] > SD)}; end")
    a("        default: begin u_pl = '0; u_yl = '0; u_str = 1'b0; end")
    a("    endcase")
    a("end")
    a(f"logic u_g, u_as, u_chv, u_wt, u_rl, u_last, u_pend; logic [{YW - 1}:0] u_y; logic [{d - 1}:0] u_ra; "
      f"logic [{SLW - 1}:0] u_slot;")
    a("assign u_g = upre ? p_g : 1'b1; assign u_as = upre && p_as; assign u_chv = upre && p_chv; "
      "assign u_wt = upre ? p_wt : 1'b1;")
    a(f"assign u_y = upre ? {YW}'(p_y) : uy; assign u_ra = upre ? p_ra : uy[{d - 1}:0]; "
      f"assign u_slot = upre ? p_slot : {_c(pl['slotC'], SLW)};")
    a("assign u_pend = upre && (up == u_pl);")
    a("assign u_rl = upre ? (u_pend && !u_str) : (uy == u_yl);")
    a(f"assign u_last = u_rl && (us == {_c(L - 1, SW)});")
    a("logic u_ok, iss, wev_v, wev_rl, wev_last;")
    a("assign u_ok = (lst == L_DATA) && !ifin;")
    a(f"assign perm = !lahead || (relst > {RW}'(us));")
    a("assign tw_ready = (lst == L_HDR);")
    a("assign tacc = tw_valid && tw_ready && !rst;")
    a("assign iss = u_ok && perm && !rst;")
    _loader_tail(a, sp, rc, L, SW, HB, HBW, QB, QBW, RW, TLW, qports, seeded=False)


def _seeded_units(a, sp, rc, L, SW, RW, PW, YW, NSL, SLW, NP):
    """The unit decode with seeds: per stage the seed beats (uph 0: entry uy, group pair um), the prefix ROM
    (uph 1: step up), the stride (uph 2: entry uy)."""
    from rtl_gen.iter_ntt import _bits, _c
    pl = rc["plan"]
    d, SD, K, NGP = pl["d"], pl["SD"], pl["K"], pl["NGP"]
    prefix, plast, N, kk = list(pl["prefix"]), list(pl["plast"]), list(pl["N"]), list(pl["kk"])
    D = rc["genLatency"] - 1
    MW = _bits(NGP)
    a(f"// ---- the loader, twiddleSource 'rec' in place with {K} seeds a group and stage: {rc['units']} units a "
      f"record ({rc['streamBeats']} seed beats on the stream, {NGP} a seeded entry; per stage the seeds, a prefix of "
      f"at most {NP} steps, then the stride), write {D + 1} cycles after the issue")
    a(f"logic [{SW - 1}:0] us; logic [1:0] uph; logic ifin; logic [{PW - 1}:0] up; logic [{YW - 1}:0] uy;"
      + (f" logic [{MW - 1}:0] um;" if NGP > 1 else ""))
    a(f"logic p_g; logic [{d - 1}:0] p_y, p_ra; logic [{SLW - 1}:0] p_slot;")
    a("always_comb begin")
    a("    case (up)")
    for i, st in enumerate(prefix[:NP]):
        if st[0] == 'B':
            a(f"        {_c(i, PW)}: begin p_g = 1'b0; p_y = '0; p_ra = '0; p_slot = '0; end")
        else:
            _, y, asrc, ra, slot, ch, wt = st
            a(f"        {_c(i, PW)}: begin p_g = 1'b1; p_y = {_c(y, d)}; p_ra = {_c(ra, d)}; "
              f"p_slot = {_c(slot, SLW)}; end")
    a("        default: begin p_g = 1'b0; p_y = '0; p_ra = '0; p_slot = '0; end")
    a("    endcase")
    a("end")
    a(f"logic [{YW - 1}:0] u_kl, u_yl; logic [{PW - 1}:0] u_pl; logic u_hp, u_str;       // the stage's last seeded "
      "entry, last entry, last prefix step, prefix, stride")
    a("always_comb begin")
    a("    case (us)")
    for st in range(L):
        a(f"        {_c(st, SW)}: begin u_kl = {_c(kk[st] - 1, YW)}; u_yl = {_c(N[st] - 1, YW)}; "
          f"u_pl = {_c(max(plast[st], 0), PW)}; u_hp = 1'b{int(plast[st] >= 0)}; u_str = 1'b{int(N[st] > SD)}; end")
    a("        default: begin u_kl = '0; u_yl = '0; u_pl = '0; u_hp = 1'b0; u_str = 1'b0; end")
    a("    endcase")
    a("end")
    a(f"logic u_sd, u_pp, u_sl, u_g, u_rl, u_last, u_pend; logic [{YW - 1}:0] u_y; logic [{d - 1}:0] u_ra; "
      f"logic [{SLW - 1}:0] u_slot;")
    a("assign u_sd = uph == 2'd0; assign u_pp = uph == 2'd1;")
    a("assign u_g = u_pp ? p_g : 1'b1;")
    a(f"assign u_y = u_pp ? {YW}'(p_y) : uy; assign u_ra = u_pp ? p_ra : uy[{d - 1}:0]; "
      f"assign u_slot = u_pp ? p_slot : {_c(pl['slotC'], SLW)};")
    a("assign u_sl = u_sd && (uy == u_kl)" + (f" && (um == {_c(NGP - 1, MW)});" if NGP > 1 else ";")
      + "       // the stage's last seed beat")
    a("assign u_pend = u_pp && (up == u_pl);")
    a("assign u_rl = u_sd ? (u_sl && !u_hp && !u_str) : (u_pp ? (u_pend && !u_str) : (uy == u_yl));")
    a(f"assign u_last = u_rl && (us == {_c(L - 1, SW)});")
    a("logic u_ok, iss, wev_v, wev_rl, wev_last;")
    a("assign u_ok = (lst == L_DATA) && !ifin;")
    a(f"assign perm = !lahead || (relst > {RW}'(us));")
    a("assign tw_ready = (lst == L_HDR) || (u_ok && perm && u_sd);       // the header, or a seed beat whose "
      "region is free")
    a("assign tacc = tw_valid && tw_ready && !rst;")
    a("assign iss = u_ok && perm && !rst && (!u_sd || tw_valid);")


def _loader_tail(a, sp, rc, L, SW, HB, HBW, QB, QBW, RW, TLW, qports, seeded):
    """The header and the loader's state (shared by both unit decodes)."""
    from rtl_gen.iter_ntt import _bits, _c
    pl = rc["plan"]
    SD, N = pl["SD"], list(pl["N"])
    YW = max(pl["d"], _bits(max(N)))
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
    H = sp.H
    a(f"logic [{SW - 1}:0] s_nx; logic [{H - 1}:0] tau_nx;")
    a("assign s_nx = startc ? '0 : ((issue && tlast) ? s + 1'b1 : s);")
    a("assign tau_nx = startc ? '0 : (issue ? (tlast ? '0 : tau + 1'b1) : tau);")
    a("always_ff @(posedge clk) begin")
    a("    if (rst) begin")
    if seeded:
        NGP = pl["NGP"]
        MW = _bits(NGP)
        um0 = " um <= '0;" if NGP > 1 else ""
        ysd = _c(SD, YW) if max(N) > SD else "'0"
        a(f"        lst <= L_HDR; lahead <= 1'b1; ws <= '0; hptr <= '0; nkeep <= 1'b0; qw <= '0; relst <= {_c(L, RW)}; "
          f"twok <= 1'b0; us <= '0; uph <= 2'd0; up <= '0; uy <= '0;{um0} ifin <= 1'b0;")
        a("    end else begin")
        a("        lst <= lst_n; lahead <= lahead_n; ws <= ws_n; hptr <= hptr_n;")
        a("        if (lst == L_HDR && tacc && hlast) nkeep <= hkeep;")
        a(f"        if (lst == L_HDR && tacc && hlast && !hkeep) begin us <= '0; uph <= 2'd0; up <= '0; uy <= '0;{um0} "
          f"ifin <= 1'b0; end")
        a("        else if (iss) begin")
        a(f"            if (u_rl) begin us <= u_last ? '0 : us + 1'b1; uph <= 2'd0; up <= '0; uy <= '0;{um0} "
          f"ifin <= u_last; end")
        a("            else if (u_sd) begin")
        a(f"                if (u_sl) begin if (u_hp) begin uph <= 2'd1; up <= '0; end else begin uph <= 2'd2; "
          f"uy <= {ysd}; end{um0} end")
        if NGP > 1:
            a(f"                else if (um == {_c(NGP - 1, MW)}) begin um <= '0; uy <= uy + 1'b1; end")
            a("                else um <= um + 1'b1;")
        else:
            a("                else uy <= uy + 1'b1;")
        a("            end else if (u_pp) begin")
        a(f"                if (u_pend) begin uph <= 2'd2; uy <= {ysd}; end else up <= up + 1'b1;")
        a("            end else uy <= uy + 1'b1;")
        a("        end")
    else:
        a(f"        lst <= L_HDR; lahead <= 1'b1; ws <= '0; hptr <= '0; nkeep <= 1'b0; qw <= '0; relst <= {_c(L, RW)}; "
          f"twok <= 1'b0; us <= '0; upre <= 1'b1; up <= '0; uy <= '0; ifin <= 1'b0;")
        a("    end else begin")
        a("        lst <= lst_n; lahead <= lahead_n; ws <= ws_n; hptr <= hptr_n;")
        a("        if (lst == L_HDR && tacc && hlast) nkeep <= hkeep;")
        a("        if (lst == L_HDR && tacc && hlast && !hkeep) begin us <= '0; upre <= 1'b1; up <= '0; ifin <= 1'b0; end")
        a("        else if (iss) begin")
        a("            if (u_rl) begin us <= u_last ? '0 : us + 1'b1; upre <= 1'b1; up <= '0; ifin <= u_last; end")
        a(f"            else if (u_pend) begin upre <= 1'b0; uy <= {_c(SD, YW) if max(N) > SD else chr(39) + '0'}; end")
        a("            else if (upre) up <= up + 1'b1;")
        a("            else uy <= uy + 1'b1;")
        a("        end")
    a(f"        qw <= clast ? {_c(QB, QBW)} : ((qw != '0) ? qw - 1'b1 : '0);")
    a(f"        if (startc) relst <= '0; else if (clast) relst <= {_c(L, RW)}; "
      f"else if (issue && (tau == '0)) relst <= {RW}'(s);")
    a("        twok <= (tau_nx != '0) || !((lst_n == L_DATA) && !lahead_n) || (ws_n > s_nx);")
    a("    end")
    a("end")
    for tag, i, off, w in rc["factorLayout"]:
        a(f"logic [{w - 1}:0] R{tag}{i}_n;      // header: "
          + ("factor (generator domain)" + (", the identity" if i == 0 else "") if tag == 'F' else "stage seed"))
    a("always_ff @(posedge clk) begin")
    if HB > 1:
        a("    if (lst == L_HDR && tacc && !hlast) hb[hptr] <= tw_data;")
    for qp, off, w in sp.headerLayout:
        a(f"    if (lst == L_HDR && tacc && hlast && !hkeep) {qp}_n <= hdr_w[{off + w - 1}:{off}];")
    for tag, i, off, w in rc["factorLayout"]:
        a(f"    if (lst == L_HDR && tacc && hlast && !hkeep) R{tag}{i}_n <= hdr_w[{off + w - 1}:{off}];")
    a("    if (!rst && startc && !nkeep) begin " + " ".join(f"{qp}_r <= {qp}_n;" for qp, _ in qports) + " end")
    a("end")


def rec_ip_writes(a, sp, rc, L, B, b, SW, TA, CA, TEW):
    """The unit pipeline, the generator groups (one multiplier and a LUTRAM store each) and the table write
    ports (lw_wet<j> / lw_wec<j>, lw_wa_t / lw_wa_c, lw_wd<j>)."""
    from rtl_gen.iter_ntt import _bits, _c
    pl = rc["plan"]
    G, g, d, SD = pl["G"], pl["g"], pl["d"], pl["SD"]
    NG = B // G
    D = rc["genLatency"] - 1
    gen = rc["gen"]
    dp = gen["datapath"]
    E = TEW
    pw = dp.wire(dict(dp.outputs)["P"]).bitWidth
    ain = {x.name: x.bitWidth for x in dp.inputs}
    FW = ain["B"]
    NSL = len(pl["slots"])
    SLW = _bits(NSL)
    CHW = _bits(max(1, pl["nA"]))
    YW = max(d, _bits(max(pl["N"])))
    NF, NS = len(pl["fexp"]), len(pl["sexp"])
    if pl.get("K"):
        return _seeded_writes(a, sp, rc, L, B, b, SW, TA, CA, TEW)
    a(f"// ---- twiddleSource 'rec' in place: {NG} groups of {G} butterflies, one multiplier ({dp.name}, latency "
      f"{gen['latency']}) and a store of {SD} entries each; {NF} factors, {NS} stage seeds")
    # issue cycle: the table addresses
    a(f"logic [{TA - 1}:0] i_ta; logic [{CA - 1}:0] i_ca; logic i_t;")
    a(f"function automatic logic [{TA - 1}:0] rtb_of(input logic [{SW - 1}:0] s_);")
    a("    case (s_)")
    for st in range(b + 1, L):
        a(f"        {_c(st, SW)}: rtb_of = {_c((1 << (st - b)) - 2, TA)};")
    a("        default: rtb_of = '0;")
    a("    endcase")
    a("endfunction")
    a(f"assign i_ta = rtb_of(us) + {TA}'(u_y >> {g}); assign i_ca = {CA}'(us); assign i_t = us > {_c(b, SW)};")
    # c+1: the unit's fields; the factor and the seed of its stage
    a(f"logic q_v [{D}]; logic q_g [{D}]; logic q_rl [{D}]; logic q_last [{D}]; logic q_wt [{D}]; logic q_t [{D}]; "
      f"logic [{TA - 1}:0] q_ta [{D}]; logic [{CA - 1}:0] q_ca [{D}]; logic [{d - 1}:0] q_swa [{D}];"
      + (f" logic [{g - 1}:0] q_l [{D}];" if g else ""))
    a("always_ff @(posedge clk) begin")
    a(f"    if (rst) for (int i = 0; i < {D}; i++) q_v[i] <= 1'b0;")
    a("    else begin")
    a("        q_v[0] <= iss;")
    a(f"        for (int i = 1; i < {D}; i++) q_v[i] <= q_v[i-1];")
    a("    end")
    a(f"    q_g[0] <= u_g; q_rl[0] <= u_rl; q_last[0] <= u_last; q_wt[0] <= u_wt; q_t[0] <= i_t; q_ta[0] <= i_ta; "
      f"q_ca[0] <= i_ca; q_swa[0] <= u_y[{d - 1}:0];" + (f" q_l[0] <= u_y[{g - 1}:0];" if g else ""))
    a(f"    for (int i = 1; i < {D}; i++) begin q_g[i] <= q_g[i-1]; q_rl[i] <= q_rl[i-1]; q_last[i] <= q_last[i-1]; "
      f"q_wt[i] <= q_wt[i-1]; q_t[i] <= q_t[i-1]; q_ta[i] <= q_ta[i-1]; q_ca[i] <= q_ca[i-1]; q_swa[i] <= q_swa[i-1];"
      + (" q_l[i] <= q_l[i-1];" if g else "") + " end")
    a("end")
    a(f"assign wev_v = q_v[{D - 1}]; assign wev_rl = q_rl[{D - 1}]; assign wev_last = q_last[{D - 1}];")
    a(f"logic [{SW - 1}:0] q_us; logic [{SLW - 1}:0] q_slot; logic q_as, q_chv; logic [{CHW - 1}:0] q_ch; "
      f"logic [{d - 1}:0] q_ra;")
    a("always_ff @(posedge clk) begin q_us <= us; q_slot <= u_slot; q_as <= u_as; q_chv <= u_chv; q_ch <= p_ch; "
      "q_ra <= u_ra; end")
    a(f"logic [{FW - 1}:0] f_sel; logic [{E - 1}:0] s_sel;       // the factor of (stage, slot), the stage's seed")
    a("always_comb begin")
    a("    case ({q_us, q_slot})")
    by = {}
    for st in range(L):
        for sl in range(NSL):
            fi = pl["fid"][st][sl]
            if fi:
                by.setdefault(fi, []).append(f"{{{_c(st, SW)}, {_c(sl, SLW)}}}")
    for fi in sorted(by):
        a(f"        {', '.join(by[fi])}: f_sel = RF{fi}_n;")
    a("        default: f_sel = RF0_n;")
    a("    endcase")
    a("end")
    if NS > 1:
        a("always_comb begin")
        a("    case (q_us)")
        for st in range(L):
            a(f"        {_c(st, SW)}: s_sel = RS{pl['sid'][st]}_n;")
        a("        default: s_sel = RS0_n;")
        a("    endcase")
        a("end")
    else:
        a("assign s_sel = RS0_n;")
    a(f"(* max_fanout = 16 *) logic st_we; (* max_fanout = 16 *) logic [{d - 1}:0] st_wa;")
    a(f"always_ff @(posedge clk) begin st_we <= !rst && q_v[{D - 1}] && q_g[{D - 1}]; st_wa <= q_swa[{D - 1}]; end")
    for gi in range(NG):
        a(f"// group {gi}: butterflies {gi * G} .. {gi * G + G - 1}")
        a(f"(* ram_style = \"distributed\" *) logic [{E - 1}:0] st{gi} [{SD}];")
        a(f"logic [{E - 1}:0] gd{gi}, gsd{gi}, gx{gi}; logic [{FW - 1}:0] gf{gi}; logic [{pw - 1}:0] gp{gi};")
        a(f"always_ff @(posedge clk) if (st_we) st{gi}[st_wa] <= gsd{gi};")
        # the chain's factor applies when bit g + q_ch of the group's first butterfly (bit q_ch of gi) is set
        bits = [c for c in range(pl["nA"]) if (gi >> c) & 1]
        on = " || ".join(f"(q_ch == {_c(c, CHW)})" for c in bits) if bits else "1'b0"
        fsel = f"(q_chv && !({on})) ? RF0_n : f_sel"
        a(f"always_ff @(posedge clk) begin gx{gi} <= q_as ? s_sel : st{gi}[q_ra]; gf{gi} <= {fsel}; end")
        for x in dp.inputs:                # the generators run on the next polynomial's constants (the header's)
            if x.name not in ("A", "B"):
                a(f"(* max_fanout = 16 *) logic [{x.bitWidth - 1}:0] g{gi}q_{x.name}; "
                  f"always_ff @(posedge clk) g{gi}q_{x.name} <= {x.name}_n[{x.bitWidth - 1}:0];")
        tq = "".join(f", .{x.name}(g{gi}q_{x.name})" for x in dp.inputs if x.name not in ("A", "B"))
        av = f"gx{gi}" if ain["A"] == E else f"{ain['A']}'(gx{gi})"
        a(f"{dp.name} u_gen{gi} (.clk(clk), .A({av}), .B(gf{gi}){tq}, .P(gp{gi}));")
        a(f"assign gd{gi} = " + (f"gp{gi};" if pw == E else f"{E}'(gp{gi});"))
        a(f"always_ff @(posedge clk) gsd{gi} <= gd{gi};")
    a(f"(* max_fanout = 16 *) logic [{TA - 1}:0] lw_wa_t; (* max_fanout = 16 *) logic [{CA - 1}:0] lw_wa_c;")
    a(f"always_ff @(posedge clk) begin lw_wa_t <= q_ta[{D - 1}]; lw_wa_c <= q_ca[{D - 1}]; end")
    a(f"logic lw_go; assign lw_go = q_v[{D - 1}] && q_g[{D - 1}] && q_wt[{D - 1}];")
    for j in range(B):
        gi, l = j // G, j % G
        lm = f" && (q_l[{D - 1}] == {_c(l, g)})" if g else ""
        a(f"logic lw_wet{j}, lw_wec{j}; logic [{TEW - 1}:0] lw_wd{j};")
        a(f"always_ff @(posedge clk) begin lw_wet{j} <= !rst && lw_go && q_t[{D - 1}]{lm}; "
          f"lw_wec{j} <= !rst && lw_go && !q_t[{D - 1}]{lm}; lw_wd{j} <= gd{gi}; end")


def _seeded_writes(a, sp, rc, L, B, b, SW, TA, CA, TEW):
    """rec_ip_writes with seeds: a seed beat's lanes are the operands of groups 2m and 2m+1 (identity factor);
    the store and table writes of a seed beat are masked to its two groups."""
    from rtl_gen.iter_ntt import _bits, _c
    pl = rc["plan"]
    G, g, d, SD, K, NGP = pl["G"], pl["g"], pl["d"], pl["SD"], pl["K"], pl["NGP"]
    NG = B // G
    D = rc["genLatency"] - 1
    gen = rc["gen"]
    dp = gen["datapath"]
    E = TEW
    pw = dp.wire(dict(dp.outputs)["P"]).bitWidth
    ain = {x.name: x.bitWidth for x in dp.inputs}
    FW = ain["B"]
    NSL = len(pl["slots"])
    SLW = _bits(NSL)
    MW = _bits(NGP)
    msk = NGP > 1                                  # more than one group pair: a seed beat writes its pair only
    NF = len(pl["fexp"])
    a(f"// ---- twiddleSource 'rec' in place: {NG} groups of {G} butterflies, one multiplier ({dp.name}, latency "
      f"{gen['latency']}) and a store of {SD} entries each; {NF} factors; {K} seeds a group and stage from the "
      f"record stream ({pl['seedWords']} entries a record)")
    a(f"logic [{TA - 1}:0] i_ta; logic [{CA - 1}:0] i_ca; logic i_t;")
    a(f"function automatic logic [{TA - 1}:0] rtb_of(input logic [{SW - 1}:0] s_);")
    a("    case (s_)")
    for st in range(b + 1, L):
        a(f"        {_c(st, SW)}: rtb_of = {_c((1 << (st - b)) - 2, TA)};")
    a("        default: rtb_of = '0;")
    a("    endcase")
    a("endfunction")
    a(f"assign i_ta = rtb_of(us) + {TA}'(u_y >> {g}); assign i_ca = {CA}'(us); assign i_t = us > {_c(b, SW)};")
    a(f"logic q_v [{D}]; logic q_g [{D}]; logic q_rl [{D}]; logic q_last [{D}]; logic q_t [{D}]; "
      f"logic [{TA - 1}:0] q_ta [{D}]; logic [{CA - 1}:0] q_ca [{D}]; logic [{d - 1}:0] q_swa [{D}];"
      + (f" logic [{g - 1}:0] q_l [{D}];" if g else "")
      + (f" logic q_sd [{D}]; logic [{MW - 1}:0] q_m [{D}];" if msk else ""))
    a("always_ff @(posedge clk) begin")
    a(f"    if (rst) for (int i = 0; i < {D}; i++) q_v[i] <= 1'b0;")
    a("    else begin")
    a("        q_v[0] <= iss;")
    a(f"        for (int i = 1; i < {D}; i++) q_v[i] <= q_v[i-1];")
    a("    end")
    a(f"    q_g[0] <= u_g; q_rl[0] <= u_rl; q_last[0] <= u_last; q_t[0] <= i_t; q_ta[0] <= i_ta; "
      f"q_ca[0] <= i_ca; q_swa[0] <= u_y[{d - 1}:0];" + (f" q_l[0] <= u_y[{g - 1}:0];" if g else "")
      + (" q_sd[0] <= u_sd; q_m[0] <= um;" if msk else ""))
    a(f"    for (int i = 1; i < {D}; i++) begin q_g[i] <= q_g[i-1]; q_rl[i] <= q_rl[i-1]; q_last[i] <= q_last[i-1]; "
      f"q_t[i] <= q_t[i-1]; q_ta[i] <= q_ta[i-1]; q_ca[i] <= q_ca[i-1]; q_swa[i] <= q_swa[i-1];"
      + (" q_l[i] <= q_l[i-1];" if g else "") + (" q_sd[i] <= q_sd[i-1]; q_m[i] <= q_m[i-1];" if msk else "") + " end")
    a("end")
    a(f"assign wev_v = q_v[{D - 1}]; assign wev_rl = q_rl[{D - 1}]; assign wev_last = q_last[{D - 1}];")
    LN = 2 if NG > 1 else 1                        # lanes of a seed beat in use
    a(f"logic [{SW - 1}:0] q_us; logic [{SLW - 1}:0] q_slot; logic q_as; logic [{d - 1}:0] q_ra; "
      f"logic [{LN * E - 1}:0] q_sx;       // q_as: the operand is the seed beat (q_sx), the factor the identity")
    a(f"always_ff @(posedge clk) begin q_us <= us; q_slot <= u_slot; q_as <= u_sd; q_ra <= u_ra; "
      f"q_sx <= tw_data[{LN * E - 1}:0]; end")
    a(f"logic [{FW - 1}:0] f_sel;       // the factor of (stage, slot)")
    a("always_comb begin")
    a("    case ({q_us, q_slot})")
    by = {}
    for st in range(L):
        for sl in range(NSL):
            fi = pl["fid"][st][sl]
            if fi:
                by.setdefault(fi, []).append(f"{{{_c(st, SW)}, {_c(sl, SLW)}}}")
    for fi in sorted(by):
        a(f"        {', '.join(by[fi])}: f_sel = RF{fi}_n;")
    a("        default: f_sel = RF0_n;")
    a("    endcase")
    a("end")
    a(f"(* max_fanout = 16 *) logic st_we; (* max_fanout = 16 *) logic [{d - 1}:0] st_wa;")
    a(f"always_ff @(posedge clk) begin st_we <= !rst && q_v[{D - 1}] && q_g[{D - 1}]; st_wa <= q_swa[{D - 1}]; end")
    if msk:
        a(f"logic st_sd; logic [{MW - 1}:0] st_m; always_ff @(posedge clk) begin st_sd <= q_sd[{D - 1}]; "
          f"st_m <= q_m[{D - 1}]; end")
    for gi in range(NG):
        a(f"// group {gi}: butterflies {gi * G} .. {gi * G + G - 1}")
        a(f"(* ram_style = \"distributed\" *) logic [{E - 1}:0] st{gi} [{SD}];")
        a(f"logic [{E - 1}:0] gd{gi}, gsd{gi}, gx{gi}; logic [{FW - 1}:0] gf{gi}; logic [{pw - 1}:0] gp{gi};")
        we = f"st_we && (!st_sd || (st_m == {_c(gi >> 1, MW)}))" if msk else "st_we"
        a(f"always_ff @(posedge clk) if ({we}) st{gi}[st_wa] <= gsd{gi};")
        ln = gi & 1
        a(f"always_ff @(posedge clk) begin gx{gi} <= q_as ? q_sx[{ln * E + E - 1}:{ln * E}] : st{gi}[q_ra]; "
          f"gf{gi} <= q_as ? RF0_n : f_sel; end")
        for x in dp.inputs:                # the generators run on the next polynomial's constants (the header's)
            if x.name not in ("A", "B"):
                a(f"(* max_fanout = 16 *) logic [{x.bitWidth - 1}:0] g{gi}q_{x.name}; "
                  f"always_ff @(posedge clk) g{gi}q_{x.name} <= {x.name}_n[{x.bitWidth - 1}:0];")
        tq = "".join(f", .{x.name}(g{gi}q_{x.name})" for x in dp.inputs if x.name not in ("A", "B"))
        av = f"gx{gi}" if ain["A"] == E else f"{ain['A']}'(gx{gi})"
        a(f"{dp.name} u_gen{gi} (.clk(clk), .A({av}), .B(gf{gi}){tq}, .P(gp{gi}));")
        a(f"assign gd{gi} = " + (f"gp{gi};" if pw == E else f"{E}'(gp{gi});"))
        a(f"always_ff @(posedge clk) gsd{gi} <= gd{gi};")
    a(f"(* max_fanout = 16 *) logic [{TA - 1}:0] lw_wa_t; (* max_fanout = 16 *) logic [{CA - 1}:0] lw_wa_c;")
    a(f"always_ff @(posedge clk) begin lw_wa_t <= q_ta[{D - 1}]; lw_wa_c <= q_ca[{D - 1}]; end")
    a(f"logic lw_go; assign lw_go = q_v[{D - 1}] && q_g[{D - 1}];")
    for j in range(B):
        gi, l = j // G, j % G
        lm = f" && (q_l[{D - 1}] == {_c(l, g)})" if g else ""
        if msk:
            lm += f" && (!q_sd[{D - 1}] || (q_m[{D - 1}] == {_c(gi >> 1, MW)}))"
        a(f"logic lw_wet{j}, lw_wec{j}; logic [{TEW - 1}:0] lw_wd{j};")
        a(f"always_ff @(posedge clk) begin lw_wet{j} <= !rst && lw_go && q_t[{D - 1}]{lm}; "
          f"lw_wec{j} <= !rst && lw_go && !q_t[{D - 1}]{lm}; lw_wd{j} <= gd{gi}; end")
