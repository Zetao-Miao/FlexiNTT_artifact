"""The multi-step NTT's top and testbench (`operator_modeling.ntt.multistep.MultiStepNTT` builds the spec dict).

Top `<name>`: clk, rst, in_valid, [MIDX], [DIR], x_in_<l> (P lanes) -> out_valid, [midx_out], [dir_out],
y_out_<l>. One beat per cycle; a polynomial is F consecutive valid beats; any gap between polynomials.
Every block is a fixed delay, so out_valid / midx_out / dir_out are the inputs delayed by `latency`.

The spec (all names already resolved by the operator):
  name, P, F, W, latency, IW (MIDX bits, 0 = fixed q), dirPort, moduli
  blocks: list in order, each one of
    {'kind': 'transpose', 'S', 'lo', 'laneBits', 'flags' (int REG_FLAGS), 'latency', 'ramStyle'}
    {'kind': 'pass', 'module', 'n', 'groups' (per copy: list of lanes, port r -> lane), 'latency'}
    {'kind': 'twiddle', 't', 'latency', 'lanes': per lane None (bypass) or
        {'rom': table id} | {'lo': id, 'hi': id}, 'tables': [{id, bits (cycle bits, LSB first), depth,
        values}], 'mul': module, 'mulLat', 'gen': module|None, 'genLat', 'qports': [(name, width)],
        'qtable': {port: [value per modulus]}, 'modShare'}
    {'kind': 'cross', 'n'}   n register stages on every lane, the valid and the tag (crossRegs)
    {'kind': 'wire', 'src'}  a lane permutation: new lane bit b = old lane bit src[b] (output order)
  options (2026-11-14; absent = off): tabLat (cycles from a table address to its word, default 2), stream
  (the tables outside: ports tw_addr_<k> / tw_data_<k>, companion module <name>_twsrc for simulation),
  ready {'depth', 'ramStyle'} (ports in_ready / out_ready: the pipeline is module <name>_core, the top adds the
  input gate and the output FIFO).
"""
from __future__ import annotations

import os

from rtl_gen.ntt import _emit_delay_module, _emit_modtab_module, _emit_table_module, _pack_per_slot


def _styled_table(tn, tbl, W, abits):
    """A ROM module (`_emit_table_module`), or a RAM with a write port when the table is loaded (`ram`), with the
    memory-style attribute of its table (romStyle: distributed | block | ultra) on the array."""
    if tbl.get("ram"):
        txt = _emit_table_module(tn, {"depth": tbl["depth"], "cols": [W], "mode": "ram"}, abits)
        st = tbl.get("romStyle")
        if st:
            decl = f"    logic [{W - 1}:0] m0 [{tbl['depth']}];"
            return txt.replace(decl, f'    (* ram_style = "{st}" *) logic [{W - 1}:0] m0 [{tbl["depth"]}];')
        return txt
    else:
        txt = _emit_table_module(tn, {"depth": tbl["depth"], "cols": [W], "mode": "rom", "values": [tbl["values"]]},
                                 abits)
    st = tbl.get("romStyle")
    if st:
        decl = f"    logic [{W - 1}:0] m0 [{tbl['depth']}];"
        assert decl in txt, tn
        txt = txt.replace(decl, f'    (* rom_style = "{st}" *) logic [{W - 1}:0] m0 [{tbl["depth"]}];')
    return txt


def MultiStep_RTL_gen(spec: dict, tb: dict | None = None) -> dict:
    name, P, F, W, LAT = spec["name"], spec["P"], spec["F"], spec["W"], spec["latency"]
    IW, DP = spec["IW"], spec["dirPort"]
    FB = max(1, (F - 1).bit_length())
    TGW = IW + (1 if DP else 0)
    TL = spec.get("tabLat", 2)            # cycles from a table address to its word
    STREAM = bool(spec.get("stream"))     # tables outside the core
    RDY = spec.get("ready")               # in_ready / out_ready top around the pipeline
    top = f"{name}_core" if RDY else name
    ext = []                              # stream supply: one entry per table read {k, abits, module}
    rtl = "RTL_generated"
    os.makedirs(rtl, exist_ok=True)
    dly = f"{name}_dly"
    with open(os.path.join(rtl, f"{dly}.sv"), "w") as f:
        f.write(_emit_delay_module(dly))
    ports = ["    input  logic clk", "    input  logic rst", "    input  logic in_valid"]
    if IW:
        ports.append(f"    input  logic [{IW - 1}:0] MIDX")
    if DP:
        ports.append("    input  logic DIR")
    # run-time moduli with a change per polynomial: the modulus constants of a polynomial come with it on
    # mq_<P> and travel in the tag beside the data, above {MIDX, DIR}, down to every small NTT
    MT = spec.get("mtLoad")
    CW = sum(w_ for _, w_ in MT["ports"]) if MT else 0
    GW = TGW + CW
    cslice, _o = {}, TGW
    for p_, w_ in (MT["ports"] if MT else []):
        cslice[p_] = (_o + w_ - 1, _o)
        _o += w_
    if MT:
        ports += [f"    input  logic [{w_ - 1}:0] mq_{p_}" for p_, w_ in MT["ports"]]
    LD = spec.get("load")
    if LD:
        LDL = max([W] + [b.get("subTWW", 1) for b in spec["blocks"] if b["kind"] == "pass"])     # one load word
        LR = LD.get("lanes", 1)             # words per cycle on the load port: lane l is bits [l*LDL, (l+1)*LDL)
        LDW = LDL * LR
        LD["ldw"] = LDW
        ports += ["    input  logic ld_rst", "    input  logic ld_wen", f"    input  logic [{LDW - 1}:0] ld_wdata"]
        ports += [f"    input  logic [{w_ - 1}:0] {p_}" for p_, w_ in LD["qports"]]
        if LD.get("slots"):                 # run-time moduli: one load fills the block of this slot in every table
            ports.append(f"    input  logic [{IW - 1}:0] ld_slot")
        if LD.get("byDir"):                 # a load fills one direction of the slot
            ports.append("    input  logic ld_dir")
    ports += [f"    input  logic [{W - 1}:0] x_in_{l}" for l in range(P)]
    ports.append("    output logic out_valid")
    if IW:
        ports.append(f"    output logic [{IW - 1}:0] midx_out")
    if DP:
        ports.append("    output logic dir_out")
    ports += [f"    output logic [{W - 1}:0] y_out_{l}" for l in range(P)]
    L = ["`timescale 1ns / 1ps",
         f"// {name}: multi-step NTT, N={spec['N']}, sizes {spec['sizes']}, {P} lanes, frame {F} cycles, "
         f"latency {LAT}" + (f", {len(spec['moduli'])} moduli (MIDX per polynomial)" if IW else ", fixed q"),
         f"module {top} (\n" + ",\n".join(ports) + "\n    );"]
    if LD:
        GB = max(1, LD["words"].bit_length())
        L.append(f"    // load port: one word per ld_wen after ld_rst, {LD['words']} words: the sub-NTT images, then the tables")
        # 2026-11-16: the load port is registered once more (ld_*_p), and every table and small NTT takes its
        # load signals from registers of its own: the load is a broadcast to the whole core
        L.append(f"    (* max_fanout = 32 *) logic ld_rst_p, ld_wen_p; (* max_fanout = 32 *) logic [{LDW - 1}:0] ld_wdata_p;")
        L.append("    always_ff @(posedge clk) begin ld_rst_p <= ld_rst; ld_wen_p <= ld_wen; ld_wdata_p <= ld_wdata; end")
        L.append(f"    (* max_fanout = 32 *) logic [{GB - 1}:0] ld_i;")
        L.append("    always_ff @(posedge clk) ld_i <= ld_rst_p ? '0 : (ld_wen_p ? ld_i + 1'b1 : ld_i);")
        L.append(f"    (* max_fanout = 32 *) logic [{LDW - 1}:0] ld_d; always_ff @(posedge clk) ld_d <= ld_wdata_p;")
        L.append("    (* max_fanout = 32 *) logic ld_v, ld_r; always_ff @(posedge clk) begin ld_v <= ld_wen_p; ld_r <= ld_rst_p; end")
        L.append(f"    logic [{GB - 1}:0] ld_iq; always_ff @(posedge clk) ld_iq <= ld_i;")
        if LD.get("slots"):
            L.append(f"    logic [{IW - 1}:0] ld_slot_p; always_ff @(posedge clk) ld_slot_p <= ld_slot;")
            L.append(f"    (* max_fanout = 32 *) logic [{IW - 1}:0] ld_sl; always_ff @(posedge clk) if (ld_rst_p) ld_sl <= ld_slot_p;")
            # the writes land one cycle after the word (ld_v, ld_iq): the slot of that cycle, so a load that
            # starts right after the last word of another (ld_rst with that word) does not move its last write
            L.append(f"    (* max_fanout = 32 *) logic [{IW - 1}:0] ld_slq; always_ff @(posedge clk) ld_slq <= ld_sl;")
        if LD.get("byDir"):
            L.append("    logic ld_dir_p; always_ff @(posedge clk) ld_dir_p <= ld_dir;")
            L.append("    (* max_fanout = 32 *) logic ld_dr; always_ff @(posedge clk) if (ld_rst_p) ld_dr <= ld_dir_p;")
            L.append("    (* max_fanout = 32 *) logic ld_drq; always_ff @(posedge clk) ld_drq <= ld_dr;")
    # the stream: data cur[l], valid v, tag {midx, dir}
    for l in range(P):
        L.append(f"    logic [{W - 1}:0] d0_{l}; assign d0_{l} = x_in_{l};")
    cur = [f"d0_{l}" for l in range(P)]
    L.append("    logic v0; assign v0 = in_valid;")
    v = "v0"
    if TGW:
        tag_in = "{MIDX, DIR}" if (IW and DP) else ("MIDX" if IW else "DIR")
        tag_in = ("{" + ", ".join([f"mq_{p_}" for p_, _ in reversed(MT["ports"])] + [tag_in.strip("{}")]) + "}") if MT else tag_in
        L.append(f"    logic [{GW - 1}:0] g0; assign g0 = {tag_in};")
    g = "g0" if TGW else None

    def tag_parts(gs):
        mi = f"{gs}[{TGW - 1}:{1 if DP else 0}]" if IW else None
        di = f"{gs}[0]" if DP else None
        return mi, di

    def delay(sig, width, depth, nm):
        if depth == 0:
            return sig
        L.append(f"    logic [{width - 1}:0] {nm};")
        # the tag with the modulus constants: a flip-flop at both ends of the hop (ntt._emit_delay_module, `_c`)
        L.append(f"    {dly}_c #(.W({width}), .D({depth})) {nm}_i (.clk(clk), .din({sig}), .dout({nm}));")
        return nm

    def vdelay(sig, depth, nm):
        # valid: a shift register cleared by rst (RAM delay lines carry no reset)
        if depth == 0:
            return sig
        L.append(f"    logic [{depth - 1}:0] {nm}_sr;")
        L.append(f"    always_ff @(posedge clk) {nm}_sr <= rst ? '0 : "
                 + (f"{{{nm}_sr[{depth - 2}:0], {sig}}};" if depth > 1 else f"{sig};"))
        L.append(f"    logic {nm}; assign {nm} = {nm}_sr[{depth - 1}];")
        return nm

    def table(tn, o, a_, tbl):
        # one table read: `o` (declared by the caller) is the word TL cycles after the address a_
        if STREAM:
            k_ = len(ext)
            ext.append({"k": k_, "abits": max(1, tbl["abits"]), "module": tn})
            L.append(f"    assign tw_addr_{k_} = {a_}; assign {o} = tw_data_{k_};   // table {tn}, outside the core")
            return
        q_ = o
        if TL > 2:
            st = [f"{o}_q{i}" for i in range(TL - 2)] + [o]
            q_ = st[0]
            L.append(f'    (* shreg_extract = "no" *) logic [{W - 1}:0] ' + ", ".join(st[:-1]) + ";")
        if tbl.get("ram") and tbl.get("sblock"):
            # a slot table: the load writes block ld_sl, at {slot, word of the block}
            ab = max(1, (tbl["depth"] - 1).bit_length())
            bd = tbl["sblock"]
            if bd & (bd - 1):
                raise AssertionError(f"{tn}: a slot block of {bd} words is not a power of two")
            half = tbl.get("ldir") == "half"         # load by direction: the half ld_dr of the block
            if half:
                bd //= 2
            bab = bd.bit_length() - 1
            sb = ab - bab - (1 if half else 0)
            wa = "{" + ", ".join(x for x in ((f"ld_slq[{sb - 1}:0]" if sb > 0 else ""), ("ld_drq" if half else ""),
                                              (f"{bab}'(ld_iq - {GB}'d{tbl['base']})" if bab else "")) if x) + "}"
            own = f" && ld_drq == 1'b{1 if tbl['ldir'] == 'inv' else 0}" if tbl.get("ldir") in ("fwd", "inv") else ""
            L.append(f"    logic {o}_lwe; logic [{ab - 1}:0] {o}_lwa; "
                     f"(* equivalent_register_removal = \"no\" *) logic [{W - 1}:0] {o}_lwd;")
            L.append(f"    always_ff @(posedge clk) begin {o}_lwe <= ld_v{own} && ld_iq >= {GB}'d{tbl['base']} "
                     f"&& ld_iq < {GB}'d{tbl['base'] + bd}; {o}_lwa <= {wa}; "
                     f"{o}_lwd <= ld_d[{tbl.get('ldl', 0) * LDL + W - 1}:{tbl.get('ldl', 0) * LDL}]; end")
            L.append(f"    {tn} {o}_i (.clk(clk), .addr({a_}), .we({o}_lwe), .wa({o}_lwa), .wcol(1'b0), "
                     f".wd({o}_lwd), .q0({q_}));")
        elif tbl.get("ram"):
            ab = max(1, (tbl["depth"] - 1).bit_length())
            L.append(f"    logic {o}_lwe; logic [{ab - 1}:0] {o}_lwa; "
                     f"(* equivalent_register_removal = \"no\" *) logic [{W - 1}:0] {o}_lwd;")
            L.append(f"    always_ff @(posedge clk) begin {o}_lwe <= ld_v && ld_iq >= {GB}'d{tbl['base']} "
                     f"&& ld_iq < {GB}'d{tbl['base'] + tbl['depth']}; {o}_lwa <= {ab}'(ld_iq - {GB}'d{tbl['base']}); "
                     f"{o}_lwd <= ld_d[{W - 1}:0]; end")
            L.append(f"    {tn} {o}_i (.clk(clk), .addr({a_}), .we({o}_lwe), .wa({o}_lwa), .wcol(1'b0), "
                     f".wd({o}_lwd), .q0({q_}));")
        else:
            L.append(f"    {tn} {o}_i (.clk(clk), .addr({a_}), .q0({q_}));")
        if TL > 2:
            L.append("    always_ff @(posedge clk) begin " + " ".join(f"{st[i + 1]} <= {st[i]};" for i in range(TL - 2))
                     + " end")

    files = []
    for bi, b in enumerate(spec["blocks"]):
        k = b["kind"]
        pre = f"b{bi}"
        if k == "transpose":
            S, lo, lb = b["S"], b["lo"], b["laneBits"]
            others = [x for x in range(P.bit_length() - 1) if x not in lb]
            nxt = [None] * P
            L.append(f"    // block {bi}: lane-time transpose, lane bits {lb} <-> cycle bits [{lo},{lo + len(lb)}), "
                     f"{P // S} x S={S}, latency {b['latency']}")
            for gi in range(P // S):
                base = sum(((gi >> i) & 1) << x for i, x in enumerate(others))
                lanes = [base | sum(((u >> i) & 1) << x for i, x in enumerate(lb)) for u in range(S)]
                u = f"{pre}_g{gi}"
                L.append(f"    logic [{W - 1}:0] {u}_i [0:{S - 1}]; logic [{W - 1}:0] {u}_o [0:{S - 1}]; logic {u}_v;")
                for i_, ln in enumerate(lanes):
                    L.append(f"    assign {u}_i[{i_}] = {cur[ln]};")
                    nxt[ln] = f"{u}_o[{i_}]"
                L.append(f"    lt_bmb_transpose #(.S({S}), .LO({lo}), .ELEMENT_WIDTH({W}), .REG_FLAGS(32'h{b['flags']:x}), "
                         f".RAM_STYLE(\"{b['ramStyle']}\")) {u} (.clk(clk), .rst(rst), .data_valid({v}), "
                         f".data_in({u}_i), .data_out_valid({u}_v), .data_out({u}_o));")
            v = f"{pre}_g0_v"
            if g:
                g = delay(g, GW, b["latency"], f"{pre}_tag")
            cur = nxt
        elif k == "pass":
            mod, n = b["module"], b["n"]
            nxt = [None] * P
            pt = b.get("ports")
            twsig = None
            if pt:
                # folded form: every butterfly's twiddle from a table per beat ({MIDX, DIR, cycle bits}, read
                # 2 cycles ahead of the data, which waits 2 cycles here)
                mi0, di0 = tag_parts(g) if g else (None, None)
                cn = f"{pre}_cnt"
                L.append(f"    logic [{FB - 1}:0] {cn};")
                if F > 1:
                    L.append(f"    always_ff @(posedge clk) {cn} <= rst ? '0 : ({v} ? {cn} + 1'b1 : {cn});")
                else:
                    L.append(f"    assign {cn} = '0;")
                twsig = {}
                offs = pt.get("offs")                # portAlign='address': the stage offset of every port
                # the table address {MIDX, DIR, frame cycle}: as it is, or (address-aligned) one copy per stage
                # offset, delayed by it, so every table word leaves when its stage needs it
                asrc = {None: (mi0, di0, cn)}
                tuse = {}                            # table id -> the offsets it is read at
                if offs:
                    for row in pt["use"]:
                        for u_, o_ in zip(row, offs):
                            for x_ in (u_ if isinstance(u_, (tuple, list)) else [u_]):
                                tuse.setdefault(x_, set()).add(o_)
                    BW = FB + TGW
                    L.append(f"    logic [{BW - 1}:0] {pre}_ab0; assign {pre}_ab0 = "
                             + (f"{{{g}{f'[{TGW - 1}:0]' if MT else ''}, {cn}}};" if g else f"{cn};"))
                    prev, po = f"{pre}_ab0", 0
                    for o_ in sorted(set(offs)):
                        if o_ > po:
                            nm_ = f"{pre}_ab{o_}"
                            L.append(f"    logic [{BW - 1}:0] {nm_};")
                            L.append(f"    {dly} #(.W({BW}), .D({o_ - po})) {nm_}_i (.clk(clk), .din({prev}), .dout({nm_}));")
                            prev, po = nm_, o_
                        mo_ = f"{prev}[{BW - 1}:{FB + (1 if DP else 0)}]" if IW else None
                        do_ = f"{prev}[{FB}]" if DP else None
                        L.append(f"    logic [{FB - 1}:0] {pre}_cn{o_}; assign {pre}_cn{o_} = {prev}[{FB - 1}:0];")
                        asrc[o_] = (mo_, do_, f"{pre}_cn{o_}")
                for tbl in pt["tables"]:
                    tn = f"{name}_b{bi}_tab{tbl['id']}"
                    td = DP and not tbl.get("dir")       # a table of both directions: DIR in its address
                    abits = len(tbl["bits"]) + (1 if td else 0) + IW
                    tbl["abits"] = abits
                    with open(os.path.join(rtl, f"{tn}.sv"), "w") as f:
                        f.write(_styled_table(tn, tbl, W, abits))
                    for o_ in (sorted(tuse.get(tbl["id"], ())) if offs else [None]):
                        mi_, di_, cn_ = asrc[o_]
                        parts = ([mi_] if IW else []) + ([di_] if td else []) + [f"{cn_}[{x}]" for x in reversed(tbl["bits"])]
                        a_ = "{" + ", ".join(parts) + "}" if parts else "1'b0"
                        o = f"{pre}_w{tbl['id']}" + ("" if o_ is None else f"_o{o_}")
                        L.append(f"    logic [{W - 1}:0] {o};")
                        table(tn, o, a_, tbl)
                        twsig[(tbl["id"], o_)] = o
                pairs = sorted({(tuple(u_), o_) for row in pt["use"] for u_, o_ in zip(row, offs or [None] * len(row))
                                if isinstance(u_, (tuple, list))}, key=lambda x: (x[0], -1 if x[1] is None else x[1]))
                if pairs:
                    # folded_gs: a table per direction; the port takes the one of the beat's DIR, registered
                    # (DIR here is 2 cycles ahead of the table words: delayed to them)
                    for o_ in sorted({x[1] for x in pairs}, key=lambda x: -1 if x is None else x):
                        ds = f"{pre}_dsel" + ("" if o_ is None else f"_o{o_}")
                        L.append(f"    (* max_fanout = 32 *) logic {ds}_1, {ds};")
                        dsrc = asrc[o_][1] if TL == 2 else delay(asrc[o_][1], 1, TL - 2, f"{ds}_e")
                        L.append(f"    always_ff @(posedge clk) begin {ds}_1 <= {dsrc}; {ds} <= {ds}_1; end")
                    for (fi, ii), o_ in pairs:
                        sfx = "" if o_ is None else f"_o{o_}"
                        o = f"{pre}_x{fi}_{ii}{sfx}"
                        L.append(f"    logic [{W - 1}:0] {o}; always_ff @(posedge clk) {o} <= {pre}_dsel{sfx} ? "
                                 f"{twsig[(ii, o_)]} : {twsig[(fi, o_)]};")
                        twsig[((fi, ii), o_)] = o
                cur = [delay(cur[l], W, pt["lat"], f"{pre}_d{l}") for l in range(P)]
                v = vdelay(v, pt["lat"], f"{pre}_pv")
                if g:
                    g = delay(g, GW, pt["lat"], f"{pre}_pg")
            mi, di = tag_parts(g) if g else (None, None)
            L.append(f"    // block {bi}: pass {b['t']}, {len(b['groups'])} x {mod} ({n}-point), latency {b['latency']}")
            for ci, lanes in enumerate(b["groups"]):
                u = f"{pre}_c{ci}"
                outs = [f"{u}_y{r}" for r in range(n)]
                L.append(f"    logic [{W - 1}:0] " + ", ".join(outs) + ";")
                L.append(f"    logic {u}_v;" + (f" logic [{IW - 1}:0] {u}_mi;" if IW else "") + (f" logic {u}_di;" if DP else ""))
                conn = [".clk(clk)", ".rst(rst)", f".in_valid({v})", f".out_valid({u}_v)"]
                if IW:
                    conn += [f".MIDX({mi})", f".midx_out({u}_mi)"]
                if MT:                      # the constants of this polynomial, from the tag at the small NTT's input
                    conn += [f".mq_{p_}({g}[{cslice[p_][1] + w_ - 1}:{cslice[p_][1]}])" for p_, w_ in b.get("subMt", [])]
                if DP:
                    conn += [f".DIR({di})"] + ([f".dir_out({u}_di)"] if IW else [])
                if pt:
                    conn += [f".{pn}({twsig[(tuple(u_) if isinstance(u_, (tuple, list)) else u_, o_)]})"
                             for pn, u_, o_ in zip(pt["names"], pt["use"][ci], pt.get("offs") or [None] * len(pt["names"]))]
                if LD and (not LD.get("slots") or any(x["module"] == mod for x in LD["segments"])):
                    seg = next(x for x in LD["segments"] if x["module"] == mod)
                    tww = b.get("subTWW", W)
                    if seg['len']:
                        L.append(f"    logic {u}_lr, {u}_lw; (* equivalent_register_removal = \"no\" *) logic [{tww - 1}:0] {u}_ld;")
                        L.append(f"    always_ff @(posedge clk) begin {u}_lr <= ld_r; {u}_lw <= ld_v && ld_iq >= {GB}'d{seg['base']} && "
                                 f"ld_iq < {GB}'d{seg['base'] + seg['len']}; "
                                 f"{u}_ld <= ld_d[{seg.get('ldl', 0) * LDL + tww - 1}:{seg.get('ldl', 0) * LDL}]; end")
                        conn += [f".tw_rst({u}_lr)", f".tw_wen({u}_lw)", f".tw_wdata({u}_ld)"]
                        if LD.get("slots"):
                            L.append(f"    logic [{IW - 1}:0] {u}_ls; always_ff @(posedge clk) {u}_ls <= ld_sl;")
                            conn.append(f".tw_slot({u}_ls)")
                        if LD.get("byDir"):
                            L.append(f"    logic {u}_ldr; always_ff @(posedge clk) {u}_ldr <= ld_dr;")
                            conn.append(f".tw_dir({u}_ldr)")
                    conn += [f".{p_}({p_}[{w_ - 1}:0])" for p_, w_ in b["subQ"]]
                conn += [f".x_in_{r}({cur[ln]})" for r, ln in enumerate(lanes)]
                conn += [f".y_out_{r}({outs[r]})" for r in range(n)]
                L.append(f"    {mod} {u} (" + ", ".join(conn) + ");")
                for r, ln in enumerate(lanes):
                    nxt[ln] = outs[r]
            v = f"{pre}_c0_v"
            if g:
                if IW:
                    gg = f"{{{pre}_c0_mi, {pre}_c0_di}}" if DP else f"{pre}_c0_mi"
                    if MT:
                        # the small NTT hands back the index and the direction; the constants wait beside it
                        L.append(f"    logic [{CW - 1}:0] {pre}_cq0; assign {pre}_cq0 = {g}[{GW - 1}:{TGW}];")
                        cq = delay(f"{pre}_cq0", CW, b["latency"] - (pt["lat"] if pt else 0), f"{pre}_cq")
                        gg = f"{{{cq}, {gg.strip('{}')}}}"
                    L.append(f"    logic [{GW - 1}:0] {pre}_tag; assign {pre}_tag = {gg};")
                    g = f"{pre}_tag"
                else:
                    g = delay(g, GW, b["latency"] - (pt["lat"] if pt else 0), f"{pre}_tag")
            cur = nxt
        elif k == "twiddle":
            t = b["t"]
            tl, ml, glat = b["latency"], b["mulLat"], b["genLat"]
            pre_lat = tl - ml          # table + generator cycles in front of the multiplier
            L.append(f"    // block {bi}: twiddle stage {t}, latency {tl} (tables {TL}"
                     + (f", generator {glat}" if b["gen"] else "") + f", multiplier {ml})")
            for tbl in b["tables"]:
                tn = f"{name}_tw{t}_tab{tbl['id']}"
                tbl["module"] = tn
                abits = len(tbl["bits"]) + (1 if DP else 0) + IW
                tbl["abits"] = abits
                with open(os.path.join(rtl, f"{tn}.sv"), "w") as f:
                    f.write(_styled_table(tn, tbl, W, abits))
            # frame cycle counter of this stage (whole polynomials)
            cn = f"{pre}_cnt"
            L.append(f"    logic [{FB - 1}:0] {cn};")
            if F > 1:
                L.append(f"    always_ff @(posedge clk) {cn} <= rst ? '0 : ({v} ? {cn} + 1'b1 : {cn});")
            else:
                L.append(f"    assign {cn} = '0;")
            mi, di = tag_parts(g) if g else (None, None)

            def addr(tbl):
                parts = []
                if IW:
                    parts.append(mi)
                if DP:
                    parts.append(di)
                parts += [f"{cn}[{x}]" for x in reversed(tbl["bits"])]
                return "{" + ", ".join(parts) + "}" if parts else "1'b0"
            tabout = {}
            for tbl in b["tables"]:
                o = f"{pre}_t{tbl['id']}"
                tabout[tbl["id"]] = o
                L.append(f"    logic [{W - 1}:0] {o};")
                table(tbl["module"], o, addr(tbl), tbl)
            # modulus constants, one table copy per modShare lanes, aligned with the multiplier inputs
            qp = b["qports"]
            mts = {}

            def qsig(at: int, lane: int, kind: str):
                if LD and not LD.get("slots"):
                    return {p_: f"{p_}[{w_ - 1}:0]" for p_, w_ in qp}
                key = (at, lane // b["modShare"], kind)
                if key in mts and not MT:
                    return mts[key]
                nm = f"{pre}_{kind}{at}_{lane // b['modShare']}"
                if MT:
                    # the constants of the polynomial at this multiplier: from the tag, `at` cycles into the block.
                    # 2026-11-16: one delay line per group of lanes ends one cycle early, and every QSUB lanes take
                    # the constants from a register of their own (the group's lanes are spread over the block, and
                    # one register at the end of the line could not reach all their multipliers in a cycle)
                    QSUB = 4
                    k2 = (at, lane // QSUB, kind, 'q')
                    if k2 in mts:
                        return mts[k2]
                    if at < 2:
                        mts[k2] = {}
                        for p_, w_ in qp:
                            hi_, lo_ = cslice[p_][1] + w_ - 1, cslice[p_][1]
                            n2 = f"{pre}_{kind}{at}_s{lane // QSUB}_{p_}"
                            L.append(f"    logic [{w_ - 1}:0] {n2}_c; assign {n2}_c = {g}[{hi_}:{lo_}];")
                            mts[k2][p_] = delay(f"{n2}_c", w_, at, n2) if at >= 1 else f"{n2}_c"
                        return mts[k2]
                    if key not in mts:
                        mts[key] = {}
                        for p_, w_ in qp:
                            hi_, lo_ = cslice[p_][1] + w_ - 1, cslice[p_][1]
                            L.append(f"    logic [{w_ - 1}:0] {nm}_{p_}_c; assign {nm}_{p_}_c = {g}[{hi_}:{lo_}];")
                            mts[key][p_] = delay(f"{nm}_{p_}_c", w_, at - 1, f"{nm}_{p_}")
                    mts[k2] = {}
                    for p_, w_ in qp:
                        n2 = f"{pre}_{kind}{at}_s{lane // QSUB}_{p_}"
                        L.append(f'    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [{w_ - 1}:0] {n2};')
                        L.append(f"    always_ff @(posedge clk) {n2} <= {mts[key][p_]};")
                        mts[k2][p_] = n2
                    return mts[k2]
                mid = delay(mi, IW, at - 1, f"{nm}_mi") if at >= 1 else mi
                outs = ", ".join(f".{p}({nm}_{p})" for p, _ in qp)
                for p, w in qp:
                    L.append(f"    logic [{w - 1}:0] {nm}_{p};")
                L.append(f"    {name}_mtab {nm} (.clk(clk), .idx({mid}), {outs});")
                mts[key] = {p: f"{nm}_{p}" for p, _ in qp}
                return mts[key]
            nxt = [None] * P
            tr = b.get("tree")
            if tr:
                # power tree per lane group: Z (two-level: lo x hi, one generator) and Y from tables, then
                # Z^(2^b) by squaring and w(j + 2^b) = w(j) Z^(2^b) level by level; w(0) = Y; data times w(j)
                IR = tr.get("inreg", 0)
                G = glat + IR

                def tin(inst, a_sig, b_sig):
                    # the tree multiplier's own input registers (kept: a power feeds up to half the lanes)
                    if not IR:
                        return a_sig, b_sig
                    L.append(f'    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [{W - 1}:0] {inst}_ia, {inst}_ib;')
                    L.append(f"    always_ff @(posedge clk) begin {inst}_ia <= {a_sig}; {inst}_ib <= {b_sig}; end")
                    return f"{inst}_ia", f"{inst}_ib"
                S0 = TL + (G if tr["two"] else 0)
                for gi, gr in enumerate(tr["groups"]):
                    u = f"{pre}_g{gi}"
                    gt = gr["tab"]
                    gq = lambda at: "".join(f", .{p}({x})" for p, x in (qsig(at, gr["lanes"][0], 'gq').items() if qp else []))
                    if tr["two"]:
                        L.append(f"    logic [{W - 1}:0] {u}_z;")
                        ia_, ib_ = tin(f"{u}_zg", tabout[gt['zlo']], tabout[gt['zhi']])
                        L.append(f"    {b['gen']} {u}_zg (.clk(clk), .A({ia_}), .B({ib_}){gq(TL + IR)}, .P({u}_z));")
                        z = f"{u}_z"
                    else:
                        z = tabout[gt["z"]]
                    if "y" in gt:
                        y = delay(tabout[gt["y"]], W, S0 - TL, f"{u}_yd")
                    else:
                        y = None
                    pw = {0: z}                    # Z^(2^b), available at S0 + b G
                    for lv in range(1, tr["depth"]):
                        nm = f"{u}_zp{lv}"
                        L.append(f"    logic [{W - 1}:0] {nm};")
                        ia_, ib_ = tin(f"{nm}_m", pw[lv - 1], pw[lv - 1])
                        L.append(f"    {b['gen']} {nm}_m (.clk(clk), .A({ia_}), .B({ib_}){gq(S0 + (lv - 1) * G + IR)}, .P({nm}));")
                        pw[lv] = nm
                    # w(j): level lv (j in [2^lv, 2^(lv+1))) ready at S0 + (lv + 1) G; w(0) = Y ready at S0
                    wv = {0: (y, S0)}
                    for lv in range(tr["depth"]):
                        for j in range(1 << lv, 1 << (lv + 1)):
                            src, at = wv[j - (1 << lv)]
                            t0 = S0 + lv * G               # when Z^(2^lv) and the level's inputs are aligned
                            nm = f"{u}_w{j}"
                            if src is None:                # Y = 1: w(2^lv) = Z^(2^lv)
                                wv[j] = (pw[lv], S0 + lv * G)
                                continue
                            a_ = delay(src, W, t0 - at, f"{nm}_a")
                            L.append(f"    logic [{W - 1}:0] {nm};")
                            ia_, ib_ = tin(f"{nm}_m", a_, pw[lv])
                            L.append(f"    {b['gen']} {nm}_m (.clk(clk), .A({ia_}), .B({ib_}){gq(t0 + IR)}, .P({nm}));")
                            wv[j] = (nm, t0 + G)
                    TT = S0 + tr["depth"] * G               # every w(j) aligned here
                    for j, ln in enumerate(gr["lanes"]):
                        src, at = wv[j]
                        a_ = delay(cur[ln], W, TT, f"{pre}_l{ln}_a")
                        mq = "".join(f", .{p}({x})" for p, x in (qsig(TT, ln, 'mq').items() if qp else []))
                        L.append(f"    logic [{W - 1}:0] {pre}_l{ln}_p;")
                        if src is None:                    # j = 0 and Y = 1: factor 1
                            nxt[ln] = delay(a_, W, ml, f"{pre}_l{ln}_byp")
                            continue
                        w_ = delay(src, W, TT - at, f"{pre}_l{ln}_w")
                        L.append(f"    {b['mul']} {pre}_l{ln}_mul (.clk(clk), .A({a_}), .B({w_}){mq}, .P({pre}_l{ln}_p));")
                        nxt[ln] = f"{pre}_l{ln}_p"
                    if TT + ml != tl:
                        raise AssertionError(f"{name}: tree stage {t}: built latency {TT + ml} != model {tl}")
            for l, ln in enumerate(b["lanes"]):
                if tr:
                    break
                u = f"{pre}_l{l}"
                if ln is None:
                    nxt[l] = delay(cur[l], W, tl, f"{u}_byp")
                    continue
                if "rom" in ln:
                    w_ = tabout[ln["rom"]]
                else:
                    w_ = f"{u}_w"
                    L.append(f"    logic [{W - 1}:0] {w_};")
                    gq = "".join(f", .{p}({s})" for p, s in (qsig(TL, l, 'gq').items() if qp else []))
                    L.append(f"    {b['gen']} {u}_gen (.clk(clk), .A({tabout[ln['lo']]}), .B({tabout[ln['hi']]}){gq}, .P({w_}));")
                lat_here = TL + (glat if "lo" in ln else 0)
                a_ = delay(cur[l], W, lat_here, f"{u}_a")
                if "rom" in ln and pre_lat > TL:
                    w_ = delay(w_, W, pre_lat - TL, f"{u}_wd")
                    a_ = delay(a_, W, pre_lat - TL, f"{u}_ad")
                mq = "".join(f", .{p}({s})" for p, s in (qsig(pre_lat, l, 'mq').items() if qp else []))
                L.append(f"    logic [{W - 1}:0] {u}_p;")
                L.append(f"    {b['mul']} {u}_mul (.clk(clk), .A({a_}), .B({w_}){mq}, .P({u}_p));")
                nxt[l] = f"{u}_p"
            v = vdelay(v, tl, f"{pre}_v")
            if g:
                g = delay(g, GW, tl, f"{pre}_tag")
            cur = nxt
        elif k == "cross":
            n = b["n"]
            L.append(f"    // block {bi}: {n} register stage(s) between blocks (crossRegs; never shift registers)")
            nxt = []
            for l in range(P):
                st = [f"{pre}_x{l}_{i}" for i in range(n)]
                L.append(f'    (* shreg_extract = "no" *) logic [{W - 1}:0] ' + ", ".join(st) + ";")
                L.append("    always_ff @(posedge clk) begin "
                         + " ".join(f"{st[i]} <= {cur[l] if i == 0 else st[i - 1]};" for i in range(n)) + " end")
                nxt.append(st[-1])
            st = [f"{pre}_xv_{i}" for i in range(n)]
            L.append('    (* shreg_extract = "no" *) logic ' + ", ".join(st) + ";")
            L.append("    always_ff @(posedge clk) begin "
                     + " ".join(f"{st[i]} <= rst ? 1'b0 : {v if i == 0 else st[i - 1]};" for i in range(n)) + " end")
            v = st[-1]
            if g:
                st = [f"{pre}_xg_{i}" for i in range(n)]
                L.append(f'    (* shreg_extract = "no" *) logic [{GW - 1}:0] ' + ", ".join(st) + ";")
                L.append("    always_ff @(posedge clk) begin "
                         + " ".join(f"{st[i]} <= {g if i == 0 else st[i - 1]};" for i in range(n)) + " end")
                g = st[-1]
            cur = nxt
        elif k == "wire":
            src = b["src"]
            L.append(f"    // block {bi}: lane permutation (wiring): new lane bit b = old lane bit {src}[b]")
            nxt = [None] * P
            for l in range(P):
                nxt[sum(((l >> x) & 1) << i for i, x in enumerate(src))] = cur[l]
            cur = nxt
        else:
            raise ValueError(k)
    extports = []
    for e in ext:
        extports.append(f"    output logic [{e['abits'] - 1}:0] tw_addr_{e['k']}")
        extports.append(f"    input  logic [{W - 1}:0] tw_data_{e['k']}")
    if extports:
        L[2] = f"module {top} (\n" + ",\n".join(ports + extports) + "\n    );"
    L.append(f"    assign out_valid = {v};")
    if IW:
        L.append(f"    assign midx_out = {tag_parts(g)[0]};")
    if DP:
        L.append(f"    assign dir_out = {tag_parts(g)[1]};")
    for l in range(P):
        L.append(f"    assign y_out_{l} = {cur[l]};")
    L.append("endmodule")
    with open(os.path.join(rtl, f"{top}.sv"), "w") as f:
        f.write("\n".join(L) + "\n")
    spec["_ext"] = ext
    if STREAM:
        with open(os.path.join(rtl, f"{name}_twsrc.sv"), "w") as f:
            f.write(_emit_twsrc(name, W, TL, ext))
    if RDY:
        with open(os.path.join(rtl, f"{name}.sv"), "w") as f:
            f.write(_emit_ready_top(spec, top, ports + extports))
    if spec.get("qtable"):
        with open(os.path.join(rtl, f"{name}_mtab.sv"), "w") as f:
            f.write(_emit_modtab_module(f"{name}_mtab", spec["qtable"], dict(spec["qwidths"]), IW))
    meta = {"top": name, "latency": LAT, "lanes": P, "frame": F}
    if tb is not None:
        meta.update(_emit_tb(spec, tb))
    return meta


def _emit_twsrc(name, W, TL, ext) -> str:
    """Stream supply, the outside half for simulation: every table of the design (the same ROM modules) behind
    the core's tw_addr_<k> / tw_data_<k> ports, each word TL (+ EXTRA) cycles after its address."""
    L = ["`timescale 1ns / 1ps",
         f"// {name}_twsrc: the twiddle tables of {name} (tableSupply='stream'), latency {TL} + EXTRA",
         f"module {name}_twsrc_d #(parameter int W = 1, parameter int D = 0) (input logic clk, input logic [W-1:0] din, "
         "output logic [W-1:0] dout);",
         "    generate if (D == 0) begin : g0 assign dout = din; end else begin : g1",
         "        logic [W-1:0] sr [0:D-1];",
         "        always_ff @(posedge clk) begin sr[0] <= din; for (int i = 1; i < D; i++) sr[i] <= sr[i-1]; end",
         "        assign dout = sr[D-1];",
         "    end endgenerate",
         "endmodule",
         f"module {name}_twsrc #(parameter int EXTRA = 0) (",
         "    input  logic clk"]
    for e in ext:
        L[-1] += ","
        L.append(f"    input  logic [{e['abits'] - 1}:0] tw_addr_{e['k']},")
        L.append(f"    output logic [{W - 1}:0] tw_data_{e['k']}")
    L.append("    );")
    for e in ext:
        k = e["k"]
        L.append(f"    logic [{W - 1}:0] r{k}; {e['module']} t{k} (.clk(clk), .addr(tw_addr_{k}), .q0(r{k}));")
        L.append(f"    {name}_twsrc_d #(.W({W}), .D({TL - 2} + EXTRA)) d{k} (.clk(clk), .din(r{k}), .dout(tw_data_{k}));")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def _emit_ready_top(spec, core, cports) -> str:
    """The `outReady` top: in_ready / out_ready around the fixed pipeline `core`. A polynomial is taken only when
    all of it fits the output FIFO behind everything in flight (occ + F <= DEPTH), so the pipeline never stalls;
    the FIFO (memory, read register q, output register o) adds 3 cycles with out_ready high."""
    name, P, F, W = spec["name"], spec["P"], spec["F"], spec["W"]
    IW, DP = spec["IW"], spec["dirPort"]
    TGW = IW + (1 if DP else 0)
    D = spec["ready"]["depth"]
    AW = D.bit_length() - 1
    FB = max(1, (F - 1).bit_length())
    DW = P * W + TGW
    ports = []
    for p in cports:
        ports.append(p)
        if p.strip() == "input  logic in_valid":
            ports.append("    output logic in_ready")
        if p.strip() == "output logic out_valid":
            ports.append("    input  logic out_ready")
    L = ["`timescale 1ns / 1ps",
         f"// {name}: {core} with in_ready / out_ready; output FIFO of {D} beats x {DW} bits; latency "
         f"{spec['latency']} with out_ready high",
         f"module {name} (\n" + ",\n".join(ports) + "\n    );",
         "    logic acc, take; assign acc = in_valid & in_ready; assign take = out_valid & out_ready;",
         f"    logic [{FB - 1}:0] fc; logic [{AW}:0] occ, occ_n; logic last;",
         f"    assign last = (fc == {FB}'d{F - 1});",
         f"    assign occ_n = occ + {AW + 1}'(acc) - {AW + 1}'(take);",
         "    always_ff @(posedge clk) begin",
         "        if (rst) begin fc <= '0; occ <= '0; in_ready <= 1'b0; end",
         "        else begin",
         "            if (acc) fc <= last ? '0 : fc + 1'b1;",
         "            occ <= occ_n;",
         f"            in_ready <= (acc ? ~last : (fc != '0)) | (occ_n <= {AW + 1}'d{D - F});",
         "        end",
         "    end",
         "    logic c_v;" + (f" logic [{IW - 1}:0] c_mi;" if IW else "") + (" logic c_di;" if DP else ""),
         f"    logic [{W - 1}:0] " + ", ".join(f"c_y{l}" for l in range(P)) + ";"]
    conn = []
    for p in cports:
        pn = p.split()[-1]
        if pn == "in_valid":
            conn.append(".in_valid(acc)")
        elif pn == "out_valid":
            conn.append(".out_valid(c_v)")
        elif pn == "midx_out":
            conn.append(".midx_out(c_mi)")
        elif pn == "dir_out":
            conn.append(".dir_out(c_di)")
        elif pn.startswith("y_out_"):
            conn.append(f".{pn}(c_y{pn[6:]})")
        else:
            conn.append(f".{pn}({pn})")
    L.append(f"    {core} core (" + ", ".join(conn) + ");")
    tag = ([f"c_mi"] if IW else []) + (["c_di"] if DP else [])
    L += [f"    logic [{DW - 1}:0] din, q, o; logic q_v, o_v;",
          "    assign din = {" + ", ".join(tag + [f"c_y{l}" for l in reversed(range(P))]) + "};",
          f"    (* ram_style = \"{spec['ready']['ramStyle']}\" *) logic [{DW - 1}:0] mem [{D}];",
          f"    logic [{AW - 1}:0] wp, rp; logic [{AW}:0] cnt;",
          "    (* max_fanout = 64 *) logic q_take, rd;",
          "    assign q_take = q_v & (~o_v | out_ready);",
          "    assign rd = (cnt != '0) & (~q_v | q_take);",
          "    always_ff @(posedge clk) begin",
          "        if (c_v) mem[wp] <= din;",
          "        if (rd) q <= mem[rp];",
          "        if (q_take) o <= q;",
          "    end",
          "    always_ff @(posedge clk) begin",
          "        if (rst) begin wp <= '0; rp <= '0; cnt <= '0; q_v <= 1'b0; o_v <= 1'b0; end",
          "        else begin",
          "            if (c_v) wp <= wp + 1'b1;",
          "            if (rd) rp <= rp + 1'b1;",
          f"            cnt <= cnt + {AW + 1}'(c_v) - {AW + 1}'(rd);",
          "            if (rd) q_v <= 1'b1; else if (q_take) q_v <= 1'b0;",
          "            if (q_take) o_v <= 1'b1; else if (out_ready) o_v <= 1'b0;",
          "        end",
          "    end",
          "    assign out_valid = o_v;"]
    if IW:
        L.append(f"    assign midx_out = o[{DW - 1}:{P * W + (1 if DP else 0)}];")
    if DP:
        L.append(f"    assign dir_out = o[{P * W}];")
    for l in range(P):
        L.append(f"    assign y_out_{l} = o[{l * W} +: {W}];")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def _emit_tb(spec, tb) -> dict:
    """tb: {'cycles': [{'v', 'x': [P], 'mi', 'di'}], 'expect': per cycle None or {'y': [P], 'mi', 'di'}}.
    Every cycle checks out_valid against the expectation (so a beat a cycle late or early fails), every
    valid output beat its lanes and tag."""
    name, P, W, IW, DP = spec["name"], spec["P"], spec["W"], spec["IW"], spec["dirPort"]
    cyc, exp = tb["cycles"], tb["expect"]
    T = len(cyc)
    tv = "testvectors"
    os.makedirs(tv, exist_ok=True)
    with open(os.path.join(tv, "x_in.txt"), "w") as f:
        f.write("".join(_pack_per_slot(c["x"], [W] * P) + "\n" for c in cyc))
    LD = spec.get("load")
    if LD:
        LDW = LD["ldw"]
        QW = sum(w_ for _, w_ in LD["qports"])
        with open(os.path.join(tv, "ld_in.txt"), "w") as f:
            f.write("".join(f"{c['ld'][0] | (c['ld'][1] << 1) | (c['ld'][2] << 2):x}\n" for c in cyc))
        if LD.get("slots"):
            with open(os.path.join(tv, "ls_in.txt"), "w") as f:
                f.write("".join(f"{c.get('ls', 0):x}\n" for c in cyc))
        with open(os.path.join(tv, "q_in.txt"), "w") as f:
            for c in cyc:
                v, o = 0, 0
                for p_, w_ in LD["qports"]:
                    v |= (c['q'].get(p_, 0) & ((1 << w_) - 1)) << o
                    o += w_
                f.write(f"{v:x}\n")
    if spec.get("mtLoad"):
        with open(os.path.join(tv, "qid_in.txt"), "w") as f:
            f.write("".join(f"{c.get('qi', 0):x}\n" for c in cyc))
    with open(os.path.join(tv, "ctl_in.txt"), "w") as f:
        f.write("".join(f"{c['v'] | (c['di'] << 1) | (c['mi'] << 2):x}\n" for c in cyc))
    with open(os.path.join(tv, "y_out.txt"), "w") as f:
        f.write("".join(_pack_per_slot(e["y"] if e else [0] * P, [W] * P) + "\n" for e in exp))
    with open(os.path.join(tv, "ctl_out.txt"), "w") as f:
        f.write("".join(f"{(1 if e else 0) | ((e['di'] if e else 0) << 1) | ((e['mi'] if e else 0) << 2):x}\n"
                        for e in exp))
    nval = sum(c["v"] for c in cyc)
    RDY = bool(tb.get("ready"))
    ext = spec.get("_ext") or []
    if RDY:
        nval = tb["beats"]
        with open(os.path.join(tv, "rdy.txt"), "w") as f:
            f.write("".join(f"{c['ordy'] | (c['irdy'] << 1):x}\n" for c in cyc))
    CW = 2 + max(IW, 1)
    L = ["`timescale 1ns / 1ps", f"module {name}_tb" + (" #(parameter int SRC_EXTRA = 0)" if ext else "") + ";",
         "    logic clk = 0; always #1 clk = ~clk;", "    logic rst = 1;", "    logic in_valid = 0;"]
    if IW:
        L.append(f"    logic [{IW - 1}:0] MIDX = 0; logic [{IW - 1}:0] midx_out;")
    if DP:
        L.append("    logic DIR = 0; logic dir_out;")
    L.append("    logic out_valid;")
    MT = spec.get("mtLoad")
    if MT:                                  # the constants of the modulus of each cycle's polynomial
        NQ = len(tb["mqTable"])
        QB = max(1, (NQ - 1).bit_length())
        L.append(f"    logic [{QB - 1}:0] qid = '0; logic [{QB - 1}:0] qi [0:{T - 1}];")
        L.append('    initial $readmemh("../testvectors/qid_in.txt", qi);')
        for p_, w_ in MT["ports"]:
            L.append(f"    logic [{w_ - 1}:0] mq_{p_}_tab [0:{NQ - 1}]; logic [{w_ - 1}:0] mq_{p_};")
            L.append("    initial begin " + " ".join(f"mq_{p_}_tab[{i_}] = {w_}'h{v_.get(p_, 0):x};" for i_, v_ in enumerate(tb["mqTable"])) + " end")
            L.append(f"    assign mq_{p_} = mq_{p_}_tab[qid];")
    if LD:
        L.append(f"    logic ld_rst = 0, ld_wen = 0; logic [{LDW - 1}:0] ld_wdata = '0;")
        L.append(f"    logic [{LDW + 1}:0] lm [0:{T - 1}]; logic [{max(1, QW) - 1}:0] qm [0:{T - 1}];")
        if LD.get("slots"):
            L.append(f"    logic [{IW - 1}:0] ld_slot = '0; logic ld_dir = 0; logic [{IW}:0] lsm [0:{T - 1}];")
            L.append('    initial $readmemh("../testvectors/ls_in.txt", lsm);')
        L.append('    initial begin $readmemh("../testvectors/ld_in.txt", lm); $readmemh("../testvectors/q_in.txt", qm); end')
        for p_, w_ in LD["qports"]:
            L.append(f"    logic [{w_ - 1}:0] {p_} = '0;")
    L.append(f"    logic [{W - 1}:0] x [0:{P - 1}]; logic [{W - 1}:0] y [0:{P - 1}];")
    L.append(f"    logic [{P * W - 1}:0] xm [0:{T - 1}]; logic [{P * W - 1}:0] ym [0:{len(exp) - 1}];")
    L.append(f"    logic [{CW - 1}:0] ci [0:{T - 1}]; logic [{CW - 1}:0] co [0:{len(exp) - 1}];")
    L.append('    initial begin $readmemh("../testvectors/x_in.txt", xm); $readmemh("../testvectors/y_out.txt", ym); '
             '$readmemh("../testvectors/ctl_in.txt", ci); $readmemh("../testvectors/ctl_out.txt", co); end')
    conn = [".clk(clk)", ".rst(rst)", ".in_valid(in_valid)", ".out_valid(out_valid)"]
    if IW:
        conn += [".MIDX(MIDX)", ".midx_out(midx_out)"]
    if DP:
        conn += [".DIR(DIR)", ".dir_out(dir_out)"]
    if LD:
        conn += [".ld_rst(ld_rst)", ".ld_wen(ld_wen)", ".ld_wdata(ld_wdata)"] + [f".{p_}({p_})" for p_, _ in LD["qports"]]
        conn += [".ld_slot(ld_slot)"] if LD.get("slots") else []
        conn += [".ld_dir(ld_dir)"] if LD.get("byDir") else []
    if MT:
        conn += [f".mq_{p_}(mq_{p_})" for p_, _ in MT["ports"]]
    conn += [f".x_in_{l}(x[{l}])" for l in range(P)] + [f".y_out_{l}(y[{l}])" for l in range(P)]
    if RDY:
        L.append(f"    logic out_ready = 1; logic in_ready; logic [1:0] rm [0:{T - 1}];")
        L.append('    initial $readmemh("../testvectors/rdy.txt", rm);')
        conn += [".in_ready(in_ready)", ".out_ready(out_ready)"]
    if ext:
        # the tables outside the core (tableSupply='stream'): the companion source, SRC_EXTRA cycles late on demand
        for e in ext:
            L.append(f"    logic [{e['abits'] - 1}:0] tw_addr_{e['k']}; logic [{W - 1}:0] tw_data_{e['k']};")
            conn += [f".tw_addr_{e['k']}(tw_addr_{e['k']})", f".tw_data_{e['k']}(tw_data_{e['k']})"]
        L.append(f"    {name}_twsrc #(.EXTRA(SRC_EXTRA)) src (.clk(clk), "
                 + ", ".join(f".tw_addr_{e['k']}(tw_addr_{e['k']}), .tw_data_{e['k']}(tw_data_{e['k']})" for e in ext) + ");")
    L.append(f"    {name} dut (" + ", ".join(conn) + ");")
    E = len(exp)
    L.append("    integer m = 0, l, errs = 0, outs = 0, first_in = -1, last_in = -1, first_out = -1, last_out = -1;")
    L.append("    logic started = 0; integer fd;")
    L.append("    initial fd = $fopen(\"y_dump.txt\", \"w\");")
    L.append("    initial begin")
    L.append(f"        for (l = 0; l < {P}; l++) x[l] = '0;")
    L.append("        repeat (80) @(posedge clk);   // past the 100 ns global set/reset of the DSP58 models (2 ns clock)")
    L.append("        rst <= 0; @(posedge clk); started <= 1;")
    L.append("    end")
    L.append("    // one counter m: after edge m the stimulus of cycle m is driven (sampled at edge m+1) and the")
    L.append("    // outputs visible are those the model expects at cycle m (input cycle + latency)")
    L.append("    always @(posedge clk) if (started) begin")
    L.append("        #0.1;")
    L.append(f"        if (m < {E}) begin")
    L.append("            if (out_valid !== co[m][0]) begin errs++; if (errs < 10) "
             "$display(\"[tb] cycle %0d: out_valid %b, expected %b\", m, out_valid, co[m][0]); end")
    L.append("            else if (out_valid) begin")
    L.append("                " + (f"if (m >= {T} || rm[m][0]) " if RDY else "")       # ready mode: count the beats taken
             + "outs++; if (first_out < 0) first_out = m; last_out = m;")
    L.append(f"                $fwrite(fd, \"%0d\", m); for (l = 0; l < {P}; l++) $fwrite(fd, \" %h\", y[l]); $fwrite(fd, \"\\n\");")
    L.append(f"                for (l = 0; l < {P}; l++) if (y[l] !== ym[m][l*{W} +: {W}]) begin errs++; if (errs < 10) "
             f"$display(\"[tb] cycle %0d lane %0d: %h, expected %h\", m, l, y[l], ym[m][l*{W} +: {W}]); end")
    if IW:
        L.append(f"                if (midx_out !== co[m][{IW + 1}:2]) begin errs++; if (errs < 10) $display(\"[tb] cycle %0d: midx_out %0d\", m, midx_out); end")
    if DP:
        L.append("                if (dir_out !== co[m][1]) begin errs++; if (errs < 10) $display(\"[tb] cycle %0d: dir_out %b\", m, dir_out); end")
    L.append("            end")
    if RDY:
        L.append(f"            if (m < {T} && in_ready !== rm[m][1]) begin errs++; if (errs < 10) "
                 "$display(\"[tb] cycle %0d: in_ready %b, expected %b\", m, in_ready, rm[m][1]); end")
    L.append(f"            if (m < {T}) begin")
    if MT:
        L.append("                qid = qi[m];")
    L.append("                in_valid = ci[m][0];" + (" DIR = ci[m][1];" if DP else "")
             + (f" MIDX = ci[m][{IW + 1}:2];" if IW else ""))
    L.append(f"                for (l = 0; l < {P}; l++) x[l] = xm[m][l*{W} +: {W}];")
    if RDY:
        L.append("                out_ready = rm[m][0];")
    L.append("                if (ci[m][0]) begin if (first_in < 0) first_in = m; last_in = m; end")
    if LD:
        L.append(f"                ld_rst = lm[m][0]; ld_wen = lm[m][1]; ld_wdata = lm[m][{LDW + 1}:2];"
                 + (f" ld_slot = lsm[m][{IW - 1}:0]; ld_dir = lsm[m][{IW}];" if LD.get("slots") else ""))
        o = 0
        for p_, w_ in LD["qports"]:
            L.append(f"                {p_} = qm[m][{o + w_ - 1}:{o}];")
            o += w_
    L.append("            end else begin in_valid = 0;" + (" ld_wen = 0; ld_rst = 0;" if LD else "")
             + (" out_ready = 1;" if RDY else "") + " end")
    L.append("            m = m + 1;")
    L.append("        end else begin")
    L.append(f"            $display(\"[tb] fed {nval} beats over cycles %0d..%0d, %0d beats out over cycles %0d..%0d "
             f"(latency {spec['latency']}), %0d errors\", first_in, last_in, outs, first_out, last_out, errs);")
    L.append(f"            if (errs == 0 && outs == {nval}" + ("" if RDY else " && (last_out - first_out) == (last_in - first_in)") + ") "
             "$display(\"[tb] PASS\"); else $display(\"[tb] FAIL\");")
    L.append("            $finish;")
    L.append("        end")
    L.append("    end")
    L.append("endmodule")
    with open(os.path.join("RTL_generated", f"{name}_tb.sv"), "w") as f:
        f.write("\n".join(L) + "\n")
    return {"test_cycles": T, "test_beats": nval}
