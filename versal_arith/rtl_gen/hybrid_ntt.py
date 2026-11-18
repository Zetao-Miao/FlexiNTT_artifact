"""Hybrid NTT core generator (a block of U unrolled stages in a loop).

Consumes the dict spec of `operator_modeling.ntt.hybrid.HybridNTT.HybridNTT.getOperatorInterface`
and writes into the current directory:

  RTL_generated/<name>.sv          the core: controller, input FIFO (W banks), pool (W banks of
                                   (S+1) x T words), read and write rotators, the block (U stages of
                                   butterflies, one module), twiddle ROMs and round muxes, the
                                   modulus tables, the output (and its twist multipliers)
  RTL_generated/<name>_ram.sv      the simple dual port RAM (iter_ntt's)
  RTL_generated/<name>_tw*.sv      twiddle ROMs; <name>_tt*.sv twist ROMs
  RTL_generated/<name>_bu*.sv      the butterfly (Butterfly_RTL_gen)
  RTL_generated/<name>_tb.sv       with `tb`: polynomials back to back, every output beat checked for
                                   value, tags and cycle
  testvectors/                     x_<l>.txt, y_<l>.txt, tags.txt, ytags.txt, ycycle.txt, valid.txt

The controller is the twin of `HybridNTTScheme.simulateJob`, the offsets those of
`inOffset` / `blockOutOffset` / `writeOffset` / `outOffset`: change both together.

Pipeline of an issue at cycle t (valid at t+d = "tag d"):
  t        controller: slot, context, round, beat; read addresses registered
  t+1      tag 1; FIFO / pool read address registers
  t+1+RL   RAM data
  t+2+RL   source mux (FIFO in round 0, else pool), bank order
  +rotLat  read rotator (un-rotate by the top U beat bits; 0 in round 0), 4:1 per level
  Tin      block input register (lane = h + g j of rotator group h, entry j)
  +j Ls    stage j input; butterfly latency Lbu; output register (bypass / x2^-1 merged)
  BO       block output = Tin + U Ls
  +rotLat  write rotator (by the beat mod 2^U); write register at WO = BO + rotLat + 1
  BO+1     last round: y_out register (twist: + its latency)
"""
from __future__ import annotations

import os
import glob
import json


def _bits(x: int) -> int:
    return max(1, (x - 1).bit_length())


def _c(v: int, w: int) -> str:
    return f"{w}'d{v}"


def _h(v: int, w: int) -> str:
    return f"{w}'h{v:x}"


def _lram_module(name: str, w: int, depth: int, R: int, style: str) -> str:
    """A table of a loadable core: the ROM's read port (addr -> q0 after R registers) and one write port."""
    A = _bits(depth)
    L = ["`timescale 1ns / 1ps", f"module {name} (", "    input  logic clk,", f"    input  logic [{A - 1}:0] addr,",
         f"    output logic [{w - 1}:0] q0,", "    input  logic we,", f"    input  logic [{A - 1}:0] wa,",
         f"    input  logic [{w - 1}:0] wd", "    );",
         f"    (* ram_style = \"{style}\" *) logic [{w - 1}:0] m0 [{depth}];",
         "    always_ff @(posedge clk) if (we) m0[wa] <= wd;",
         f"    logic [{w - 1}:0] r0;", "    always_ff @(posedge clk) r0 <= m0[addr];"]
    prev = "r0"
    for k in range(2, R):
        L.append(f"    logic [{w - 1}:0] r0_{k};")
        L.append(f"    always_ff @(posedge clk) r0_{k} <= {prev};")
        prev = f"r0_{k}"
    L.append(f"    always_ff @(posedge clk) q0 <= {prev};" if R >= 2 else "    assign q0 = r0;")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def HybridNTT_RTL_gen(sp: dict, tb: dict | None = None) -> dict:
    from rtl_gen.butterfly import Butterfly_RTL_gen
    from rtl_gen.datapath import Datapath_RTL_gen
    from rtl_gen.iter_ntt import _ram_module, _rom_module
    from rtl_gen.utils import to_twos_complement_hex
    name = sp["name"]
    n, L, U, g, W, T, CB, R, e, S = (sp[k] for k in ("n", "L", "U", "g", "W", "T", "CB", "R", "e", "S"))
    RL, Lbu, Ls, RT, Tin, BO, WO, OO, DL = (sp[k] for k in ("RL", "Lbu", "Ls", "rotLat", "Tin", "BO", "WO",
                                                         "OO", "slot"))
    OFF, ID, Wd, OW, MB, M = sp["offsets"], sp["inDepth"], sp["width"], sp["outWidth"], sp["MB"], sp["M"]
    DP = sp["dirPort"]
    D = len(sp["dirs"])
    MU = 1 << U
    TW = sp["twWidth"]
    TWW = TW + sp.get("wpWidth", 0)          # a butterfly's twiddle word: {WP, W} with Shoup butterflies
    bs = sp["bu"]
    qports = sp["qports"]                     # per consumer: [(port, width)]
    qw = {c: dict(v) for c, v in qports.items()}
    gen = sp.get("gen")
    LEAD = sp.get("lead", 0)
    XR = sp.get("XR", 0)                      # crossing registers: XR of the lead registers, XR after the write register
    tw = sp["twist"]
    rtl = "RTL_generated"
    os.makedirs(rtl, exist_ok=True)
    for stale in glob.glob(os.path.join(rtl, f"{name}*.sv")):
        os.remove(stale)
    SHR = sp.get("share") or {}             # shared inverse twiddles: table -> (source table, map, sign rule)
    SHM = sp.get("shareMap") or {}          # table -> the address map of its read in an inverse polynomial
    FAN = sp.get("fan") or {}                 # fan-out trees (fanout=): the scheme's plan, name -> levels
    FR = sp.get("fanShift", 0)                # cycles the trees add between an issue and its RAM read
    assert Tin == 3 + RL + RT + LEAD + FR and BO == Tin + U * Ls and WO == BO + RT + 1 + XR
    # --- sub-modules -----------------------------------------------------------------
    Butterfly_RTL_gen(spec=bs, gen_testbench=False)
    if tw is not None:
        Datapath_RTL_gen(spec=tw["datapath"], gen_testbench=False, submodules=tw["submodules"], write_xdc=False)
    if gen is not None:
        Datapath_RTL_gen(spec=gen["datapath"], gen_testbench=False, submodules=gen["submodules"], write_xdc=False)
    if os.path.isfile("manifest.json"):
        os.remove("manifest.json")
    for sty in {sp["fifoStyle"], sp["poolStyle"]}:
        with open(os.path.join(rtl, f"{name}_ram_{sty}.sv"), "w", encoding="utf-8") as f:
            f.write(_ram_module(f"{name}_ram_{sty}", sty))
    tabs = sp["tables"]
    from operator_modeling.ntt.memory import ramCost as _rc

    # loadable: every table is a RAM and every modulus constant a register, written through the load port;
    # a region = one table (address = the table's) or one modulus constant (address = MIDX)
    LD = bool(sp.get("loadable"))
    regs, ridx = [], {}

    def region(nm, w, vals):
        ridx[nm] = len(regs)
        regs.append({"name": nm, "width": w, "depth": len(vals), "values": list(vals)})
        return ridx[nm]

    def _rom(nm, vals, sty=None, w=TW):
        sty = sty or _rc(len(vals), w, "auto")["style"]
        with open(os.path.join(rtl, f"{nm}.sv"), "w", encoding="utf-8") as f:
            if LD:
                region(nm, w, vals)
                f.write(_lram_module(nm, w, len(vals), RL, sty))
            else:
                f.write(_rom_module(nm, [w], [vals], len(vals), RL, sty))

    # 'stream': the twiddle tables are outside the core (tw_addr_<i> out, tw_data_<i> in RL cycles later); the
    # table modules are still written, as <name>_twx<i>, for the testbench to play the supplier
    EXT = bool(sp.get("external"))
    ext = []

    def ldp(nm):
        """The load port connections of table module nm ('' when not loadable)."""
        if not LD or nm not in ridx:
            return ""
        r = regs[ridx[nm]]
        return f", .we(ld_en[{ridx[nm]}]), .wa(ld_a[{_bits(r['depth']) - 1}:0]), .wd(ld_d[{r['width'] - 1}:0])"
    for ti, t in enumerate(tabs):
        if t["src"] == "rec":
            _rom(f"{name}_tb{ti}", t["base"])
            if len(t["upd"]) > 1 or LD:
                _rom(f"{name}_tu{ti}", t["upd"])
        elif t["src"] == "otf":
            _rom(f"{name}_tl{ti}", t["lo"])
            _rom(f"{name}_th{ti}", t["hi"])
        elif t["src"] == "tree":
            if len(t["cst"]) > 1 or LD:
                _rom(f"{name}_th{ti}", t["cst"])
        elif EXT and (t["style"] != "const" or LD):
            with open(os.path.join(rtl, f"{name}_twx{ti}.sv"), "w", encoding="utf-8") as f:
                f.write(_rom_module(f"{name}_twx{ti}", [TWW], [t["values"]], len(t["values"]), RL, "distributed"))
            ext.append((ti, _bits(len(t["values"]))))
        elif t["style"] != "const" or LD:
            _rom(f"{name}_tw{ti}", t["values"], t["style"] if t["style"] != "const" else "distributed", TWW)
    if tw is not None and tw.get("src") == "rec":
        for l in range(W):
            _rom(f"{name}_ttb{l}", tw["rec"]["base"][l])
        if len(tw["rec"]["upd"]) > 1 or LD:
            _rom(f"{name}_ttu", tw["rec"]["upd"])
    elif tw is not None:
        from operator_modeling.ntt.memory import ramCost
        tst = ramCost(tw["depth"], TW, "auto")["style"]
        for l in range(W):
            _rom(f"{name}_tt{l}", tw["tables"][l], tst)

    O = []

    def a(x):
        O.append("    " + x)

    def fk(nm):
        """Levels of the fan-out tree nm (0: no tree)."""
        return len((FAN.get(nm) or {}).get("levels", ()))

    def ftree(nm, tag, sigs, N, rst=(), pad=0, levels=None):
        """The tree nm behind the registers sigs = [(name, width, source)] (pad: single registers in front);
        returns sink -> {name: expression} (the sources themselves without a tree)."""
        from rtl_gen.iter_ntt_cg import _tree
        lv = [1] * pad + list((FAN.get(nm) or {}).get("levels", ()) if levels is None else levels)
        return _tree(a, tag, sigs, N, lv, rst)
    KS, KT = fk("stage tags"), fk("twiddle fan-out")
    mleaf = {}                                # register name -> its tree's leaves (sink -> {'v': expression})

    # --- ports ----------------------------------------------------------------------------
    ports = ["    input  logic clk", "    input  logic rst", "    input  logic in_valid", "    output logic in_ready"]
    if MB:
        ports.append(f"    input  logic [{MB - 1}:0] MIDX")
    if DP:
        ports.append("    input  logic DIR")
    ports += [f"    input  logic [{Wd - 1}:0] x_in_{l}" for l in range(W)]
    ports.append("    output logic out_valid")
    if MB:
        ports.append(f"    output logic [{MB - 1}:0] midx_out")
    if DP:
        ports.append("    output logic dir_out")
    ports += [f"    output logic [{OW - 1}:0] y_out_{l}" for l in range(W)]

    # --- tag fields ------------------------------------------------------------------------
    RB = _bits(R)
    XB = _bits(S)
    BB = _bits(S + 1)
    PA = _bits((S + 1) * T)
    FA = _bits(ID)
    fields = [("last", 1), ("r0", 1), ("r", RB), ("c", CB), ("wb", BB)]
    if MB:
        fields.append(("m", MB))
    if DP:
        fields.append(("d", 1))
    pos, o = {}, 0
    for nm, w in fields:
        pos[nm] = (o, w)
        o += w
    TGW = o
    used = set()

    def tg(d: int, f: str) -> str:
        """Field f of the issue's tag d cycles after the issue (d >= 1)."""
        assert d >= 1, d
        used.add(d)
        if f == "v":
            return f"vch[{d - 1}]"
        lo, w = pos[f]
        return f"tg{d}[{lo + w - 1}:{lo}]" if w > 1 else f"tg{d}[{lo}]"

    # --- controller (twin: HybridNTTScheme.simulateJob) --------------------------------------
    a("// ---- controller: slots of %d cycles, %d context(s), %d rounds, round offsets %s" % (DL, S, R, OFF))
    CW = _bits(DL + 1)
    NW = _bits(ID + 1)
    a(f"logic running; logic [{XB - 1}:0] xr; logic [{RB - 1}:0] kdr; logic [{CW - 1}:0] cc; logic [{BB - 1}:0] wbr;")
    a(f"logic [{S - 1}:0] act; logic [{NW - 1}:0] count; logic [{FA - 1}:0] wcnt, rptr;")
    if MB:
        a(f"logic [{MB - 1}:0] cm_ [{S}];")
    if DP:
        a(f"logic cd_ [{S}];")
    TQ = 4
    if MB:
        a(f"logic [{MB - 1}:0] tq_m [{TQ}];")
    if DP:
        a(f"logic tq_d [{TQ}];")
    a("logic [1:0] tq_w, tq_r;")
    a(f"logic start, run_c, slot0, take, stopc, run_n, iss, r0iss, accept, send;")
    a(f"logic [{XB - 1}:0] x_c; logic [{RB - 1}:0] kd_c, r_c; logic [{CW - 1}:0] cc_c; logic [{BB - 1}:0] wb_c, rb_c;")
    a(f"logic [{S - 1}:0] act_c;")
    if FR:
        a(f"logic [{NW - 1}:0] countw; logic [{FR - 1}:0] r0d;   // fan-out trees: the FIFO count as the writer sees it")
    a(f"assign in_ready = {'countw' if FR else 'count'} < {_c(ID, NW)};")
    a("assign accept = in_valid && in_ready;")
    a("always_comb begin")
    a(f"    start = !running && (count >= {_c(T, NW)});")
    a("    run_c = running || start;")
    a(f"    x_c = start ? '0 : xr; kd_c = start ? '0 : kdr; cc_c = start ? '0 : cc; wb_c = start ? '0 : wbr;")
    a("    case (x_c)")
    for x in range(S):
        a(f"        {_c(x, XB)}: r_c = {RB}'((kd_c + {_c(OFF[x], RB + 1)}) % {R});")
    a("        default: r_c = '0;")
    a("    endcase")
    a(f"    slot0 = run_c && (cc_c == '0) && (r_c == '0);")
    a(f"    take = slot0 && (count >= {_c(T, NW)});")
    a("    act_c = act;")
    a("    if (slot0) act_c[x_c] = take;")
    a("    stopc = slot0 && (act_c == '0);")
    a("    run_n = run_c && !stopc;")
    a(f"    iss = run_n && act_c[x_c] && (cc_c < {_c(T, CW)});")
    a("    r0iss = iss && (r_c == '0);")
    a(f"    rb_c = (wb_c == {_c(S, BB)}) ? '0 : wb_c + 1'b1;")
    a("end")
    tsh = CB - U
    a("always_ff @(posedge clk) begin")
    a("    if (rst) begin")
    a("        running <= 1'b0; xr <= '0; kdr <= '0; cc <= '0; wbr <= '0; act <= '0; count <= '0;")
    a("        wcnt <= '0; rptr <= '0; tq_w <= '0; tq_r <= '0;")
    a("    end else begin")
    a("        running <= run_n;")
    a("        act <= act_c;")
    a(f"        count <= {NW}'(count + {NW}'(accept) - {NW}'(r0iss));")
    a("        if (run_n) begin")
    a(f"            if (cc_c == {_c(DL - 1, CW)}) begin")
    a("                cc <= '0;")
    a(f"                wbr <= (wb_c == {_c(S, BB)}) ? '0 : wb_c + 1'b1;")
    if S > 1:
        a(f"                xr <= (x_c == {_c(S - 1, XB)}) ? '0 : x_c + 1'b1;")
        a(f"                kdr <= (x_c == {_c(S - 1, XB)}) ? ((kd_c == {_c(R - 1, RB)}) ? '0 : kd_c + 1'b1) : kd_c;")
    else:
        a("                xr <= '0;")
        a(f"                kdr <= (kd_c == {_c(R - 1, RB)}) ? '0 : kd_c + 1'b1;")
    a("            end else begin")
    a("                cc <= cc_c + 1'b1; wbr <= wb_c; xr <= x_c; kdr <= kd_c;")
    a("            end")
    a("        end")
    a("        if (take) tq_r <= tq_r + 1'b1;")
    a(f"        if (r0iss) rptr <= (rptr == {_c(ID - 1, FA)}) ? '0 : rptr + 1'b1;")
    a(f"        if (accept) begin")
    a(f"            wcnt <= (wcnt == {_c(ID - 1, FA)}) ? '0 : wcnt + 1'b1;")
    a(f"            if (wcnt % {T} == 0) tq_w <= tq_w + 1'b1;")
    a("        end")
    a("    end")
    a("end")
    if FR:
        a("always_ff @(posedge clk) begin")
        a("    if (rst) begin countw <= '0; r0d <= '0; end else begin")
        a(f"        r0d <= {FR}'({{r0d, r0iss}});")
        a(f"        countw <= {NW}'(countw + {NW}'(accept) - {NW}'(r0d[{FR - 1}]));")
        a("    end")
        a("end")
    # tag FIFO and context tags (no reset needed: written before read)
    a("always_ff @(posedge clk) begin")
    a(f"    if (accept && (wcnt % {T} == 0)) begin")
    if MB:
        a("        tq_m[tq_w] <= MIDX;")
    if DP:
        a("        tq_d[tq_w] <= DIR;")
    a("    end")
    a("    if (take) begin")
    if MB:
        a("        cm_[x_c] <= tq_m[tq_r];")
    if DP:
        a("        cd_[x_c] <= tq_d[tq_r];")
    a("    end")
    a("end")
    # issue tag (tag 1) and read addresses
    a(f"logic [{TGW - 1}:0] tg1;")
    a(f"(* max_fanout = 16 *) logic [{FA - 1}:0] fifo_ra;")
    for k in range(MU):
        a(f"(* max_fanout = 16 *) logic [{PA - 1}:0] pool_ra{k};")
    mexpr = "(take ? tq_m[tq_r] : cm_[x_c])" if MB else None
    dexpr = "(take ? tq_d[tq_r] : cd_[x_c])" if DP else None
    a("always_ff @(posedge clk) begin")
    parts = []
    for nm, w in reversed(fields):
        if nm == "last":
            parts.append(f"(r_c == {_c(R - 1, RB)})")
        elif nm == "r0":
            parts.append("(r_c == '0)")
        elif nm == "r":
            parts.append("r_c")
        elif nm == "c":
            parts.append(f"{CB}'(cc_c)")
        elif nm == "wb":
            parts.append("wb_c")
        elif nm == "m":
            parts.append(mexpr)
        elif nm == "d":
            parts.append(dexpr)
    a(f"    tg1 <= {{{', '.join(parts)}}};")
    a("    fifo_ra <= rptr;")
    for k in range(MU):
        cm = f"{CB}'(cc_c) & {_c((1 << tsh) - 1, CB)}" if tsh else f"{CB}'d0"
        tt = f"({CB}'(cc_c) >> {tsh})"
        a(f"    pool_ra{k} <= {PA}'(rb_c) * {PA}'({T}) + {PA}'(({cm}) << {U}) + {PA}'(({_c(k, U + 1)} - {U + 1}'({tt})) & {_c(MU - 1, U + 1)});")
    a("end")
    fra, pra = ["fifo_ra"] * W, [f"pool_ra{b % MU}" for b in range(W)]
    if FR:
        a(f"// fan-out trees: the read addresses reach the banks {FR} cycle(s) later")
        lf = ftree("fifo read", "ft_fifo", [("ra", FA, "fifo_ra")], W, pad=FR - fk("fifo read"))
        fra = [lf(l)["ra"] for l in range(W)]
        for k in range(MU):
            lf = ftree("pool read", f"ft_pool{k}", [("ra", PA, f"pool_ra{k}")], g, pad=FR - fk("pool read"))
            for h in range(g):
                pra[h * MU + k] = lf(h)["ra"]

    # --- input FIFO (W banks) and pool (W banks) ------------------------------------------------
    a("// ---- input FIFO: lane l -> bank l, address = beat (mod depth); pool: bank h*2^U + ((lo + c) mod 2^U)")
    a(f"logic fw_e; logic [{FA - 1}:0] fw_a;")
    for l in range(W):
        a(f"logic [{Wd - 1}:0] fw_d{l}, fifo_rd{l}, pool_rd{l};")
    a("always_ff @(posedge clk) begin")
    a("    fw_e <= rst ? 1'b0 : accept; fw_a <= wcnt;")
    for l in range(W):
        a(f"    fw_d{l} <= x_in_{l};")
    a("end")
    for l in range(W):
        a(f"{name}_ram_{sp['fifoStyle']} #(.W({Wd}), .D({ID}), .A({FA}), .R({RL})) u_fifo{l} (.clk(clk), "
          f".we(fw_e), .wa(fw_a), .wd(fw_d{l}), .ra({fra[l]}), .rd(fifo_rd{l}));")
    a(f"(* max_fanout = 32 *) logic pw_e; (* max_fanout = 32 *) logic [{PA - 1}:0] pw_a;")
    pwl = ftree("pool write", "ft_pw", [("e", 1, "pw_e"), ("a", PA, "pw_a")], W, rst=("e",))
    for b in range(W):
        a(f"logic [{Wd - 1}:0] pw_d{b};")
        a(f"{name}_ram_{sp['poolStyle']} #(.W({Wd}), .D({(S + 1) * T}), .A({PA}), .R({RL})) u_pool{b} (.clk(clk), "
          f".we({pwl(b)['e']}), .wa({pwl(b)['a']}), .wd(pw_d{b}), .ra({pra[b]}), .rd(pool_rd{b}));")

    # --- read path: source mux, read rotator, block input ------------------------------------
    a("// ---- read path: source mux (bank order), rotate group h left by the top U beat bits, block input")
    d0 = 2 + RL
    a(f"(* max_fanout = 32 *) logic src_r0;")
    sr_d = RL + FR - fk("source select")
    a(f"always_ff @(posedge clk) src_r0 <= {tg(sr_d, 'r0')};   // valid with the RAM data (t+1+RL)")
    srl = ftree("source select", "ft_src", [("s", 1, "src_r0")], W)

    def rot_levels(prefix, ins, amt_at, sign, d_first, fan=None):
        """Emit a pipelined rotator over each group of MU signals: out[h][j] = in[h][(j + sign*amt) mod MU].
        amt_at(level) -> (signal of the amount bits valid at the level's input cycle). Returns the outputs."""
        cur = ins
        for i in range(RT):
            nb = min(2, U - 2 * i)
            amt = amt_at(i)
            a(f"(* max_fanout = 32 *) logic [{nb - 1}:0] {prefix}a{i};")
            a(f"always_ff @(posedge clk) {prefix}a{i} <= {amt};")
            ral = ftree(fan, f"ft_{prefix}{i}", [("a", nb, f"{prefix}a{i}")], W)
            nxt = []
            for b in range(W):
                h, j = b // MU, b % MU
                nm = f"{prefix}{i}_{b}"
                a(f"logic [{Wd - 1}:0] {nm};")
                nxt.append(nm)
            # the amount register is one level early: the level's mux uses it in the following cycle
            for b in range(W):
                h, j = b // MU, b % MU
                srcs = [cur[h * MU + ((j + sign * dd * (4 ** i)) % MU)] for dd in range(1 << nb)]
                if nb == 1:
                    a(f"always_ff @(posedge clk) {nxt[b]} <= {ral(b)['a']} ? {srcs[1]} : {srcs[0]};")
                else:
                    a(f"always_ff @(posedge clk) case ({ral(b)['a']}) 2'd0: {nxt[b]} <= {srcs[0]}; "
                      f"2'd1: {nxt[b]} <= {srcs[1]}; 2'd2: {nxt[b]} <= {srcs[2]}; default: {nxt[b]} <= {srcs[3]}; endcase")
            cur = nxt
        return cur

    srcn = []
    for b in range(W):
        h, j = b // MU, b % MU
        a(f"logic [{Wd - 1}:0] src{b};")
        a(f"always_ff @(posedge clk) src{b} <= {srl(b)['s']} ? fifo_rd{h + g * j} : pool_rd{b};")
        srcn.append(f"src{b}")
    # src valid at t+2+RL; level i's register valid at t+3+RL+i, its amount register at t+2+RL+i (from tag
    # t+1+RL+i); amount = round 0 ? 0 : the top U beat bits
    top = f"{tg(1, 'c')}"

    def ramt(i):
        d = 1 + RL + i + FR - fk("read rotate")
        lo = tsh + 2 * i
        nb = min(2, U - 2 * i)
        cbits = f"{tg(d, 'c').split('[')[0]}[{pos['c'][0] + lo + nb - 1}:{pos['c'][0] + lo}]"
        used.add(d)
        return f"{tg(d, 'r0')} ? '0 : {cbits}"
    rout = rot_levels("rr", srcn, ramt, +1, d0, "read rotate")
    # the rotator's last level is valid at t+2+RL+RT; the block input register at Tin = t+3+RL+RT
    a("// block input register: lane h + g j <- rotator group h, entry j")
    st = []
    for l in range(W):
        a(f"logic [{Wd - 1}:0] s0_{l};")
        st.append(f"s0_{l}")
    for b in range(W):
        h, j = b // MU, b % MU
        a(f"always_ff @(posedge clk) s0_{h + g * j} <= {rout[b]};")
    NOSR = '(* shreg_extract = "no" *) ' if XR else ""
    if LEAD:
        a(f"// {LEAD} lead register(s): the generated twiddles of stage 0 need that many cycles from the issue's tag")
        for l in range(W):
            a(f"{NOSR}logic [{Wd - 1}:0] sl_{l} [{LEAD}];")
            a(f"always_ff @(posedge clk) begin sl_{l}[0] <= s0_{l}; "
              + "".join(f"sl_{l}[{k}] <= sl_{l}[{k - 1}]; " for k in range(1, LEAD)) + "end")
        st = [f"sl_{l}[{LEAD - 1}]" for l in range(W)]

    # --- modulus tables ------------------------------------------------------------------------

    def mreg(nm, qp, d, cons="bu", fan=None, N=0):
        """A register named nm holding consumer cons's port qp for the tag's modulus, valid at t+d."""
        w = qw[cons][qp]
        mt = sp["mtab"][cons]
        kf = fk(fan) if fan and (LD or MB) else 0
        d -= kf                                  # a fan-out tree behind it (mleaf): loaded that much earlier
        a(f"(* max_fanout = 16 *) logic [{w - 1}:0] {nm};")
        if LD:
            hq = f"hq_{cons}_{qp}"
            if hq not in ridx:
                k = region(hq, w, mt[qp])
                a(f"logic [{w - 1}:0] {hq} [{M}];")
                a(f"always_ff @(posedge clk) if (ld_en[{k}]) {hq}[{f'ld_a[{MB - 1}:0]' if MB else '0'}] <= ld_d[{w - 1}:0];")
            a(f"always_ff @(posedge clk) {nm} <= {hq}[{tg(d - 1, 'm') if MB else '0'}];")
        elif MB:
            a(f"always_ff @(posedge clk) case ({tg(d - 1, 'm')})")
            for i, v in enumerate(mt[qp]):
                a(f"    {_c(i, MB)}: {nm} <= {_h(v, w)};")
            a(f"    default: {nm} <= {_h(mt[qp][0], w)};")
            a("endcase")
        else:
            a(f"assign {nm} = {_h(mt[qp][0], w)};")
        if kf:
            mleaf[nm] = ftree(fan, f"ft_{nm}", [("v", w, nm)], N)
        return nm

    # --- twiddle ROMs (per table: one round, one stage), fan-out registers --------------------------
    a("// ---- twiddle tables: address {MIDX, DIR, top beat bits}; ROM -> fan-out register -> round mux / W register")
    tfo = {}
    tfn = {}

    def ftf(ti, nm):
        """Table ti's fan-out register nm, or its tree's leaves (fanout=; every table padded to KT levels)."""
        t = tabs[ti]
        if not KT or (t["src"] == "rom" and t["style"] == "const" and not LD):
            return nm
        lv = list(FAN["twiddle fan-out"]["tables"][ti])
        return ftree(None, f"ft_{nm}", [("w", TWW, nm)], max(1, t["users"]), levels=[1] * (KT - len(lv)) + lv)

    def tfu(ti):
        """Table ti's word for its next butterfly."""
        x = tfo[ti]
        if not callable(x):
            return x
        tfn[ti] = tfn.get(ti, -1) + 1
        return x(tfn[ti])["w"]

    def twinst(ti):
        """Table ti's read: address ta<ti> -> word tq<ti> RL cycles later (the table module, or the tw ports)."""
        if EXT:
            ab = dict(ext)[ti]
            ports.extend([f"    output logic [{ab - 1}:0] tw_addr_{ti}", f"    input  logic [{TWW - 1}:0] tw_data_{ti}"])
            a(f"assign tw_addr_{ti} = ta{ti}; assign tq{ti} = tw_data_{ti};")
        else:
            a(f"{name}_tw{ti} u_tw{ti} (.clk(clk), .addr(ta{ti}), .q0(tq{ti}){ldp(f'{name}_tw{ti}')});")
    for ti, t in enumerate(tabs):
        j, sb = t["j"] if "j" in t else None, t["sb"]
        jj = sp_table_stage(sp, ti)
        A_ = Tin + jj * Ls - RL - 2 - KT     # address register valid at t+A_
        nm = f"tf{ti}"
        a(f"(* max_fanout = 16 *) logic [{TWW - 1}:0] {nm};")
        if t["src"] != "rom":
            # a generator: v valid at t+Ov, the fan-out register at Ov+1 (= the ROM path's)
            Ov = Tin + jj * Ls - 2 - KT
            LG = gen["latency"]
            y = Ov - 1 - LG                      # the multiplier's inputs valid at t+y
            dpg = gen["datapath"]
            pwg = dpg.wire(dict(dpg.outputs)["P"]).bitWidth
            ging = {x.name: x.bitWidth for x in dpg.inputs}
            gq = "" if t["src"] == "tbase" else \
                "".join(f", .{x.name}({mreg(f'g{ti}_{x.name}', x.name, y, 'gen')})" for x in dpg.inputs
                        if x.name not in ("A", "B"))
            if t["src"] != "tbase":
                a(f"logic [{TW - 1}:0] gv{ti}; logic [{pwg - 1}:0] gp{ti};")

            def addr(nmA, depth, tagd, ebits, ehi):
                """An address register valid at t+tagd+1: (m D + d) * entries + entry bits [ehi-ebits, ehi) of c."""
                AB = _bits(depth)
                ents = depth // (M * D)
                md = []
                if MB:
                    md.append(f"{AB}'({tg(tagd, 'm')}) * {AB}'({D})")
                if DP and D == 2:
                    md.append(f"{AB}'({tg(tagd, 'd')})")
                mdx = f"({' + '.join(md)})" if md else f"{AB}'d0"
                if ebits:
                    lo_ = pos["c"][0] + ehi - ebits
                    used.add(tagd)
                    ex = f"{AB}'(tg{tagd}[{pos['c'][0] + ehi - 1}:{lo_}])"
                else:
                    ex = f"{AB}'d0"
                a(f"logic [{AB - 1}:0] {nmA};")
                a(f"always_ff @(posedge clk) {nmA} <= {mdx} * {AB}'({ents}) + {ex};")
            if t["src"] == "tbase":
                # 'tree': this table is read early (word at t+y) for the derived tables, and delayed for its own use
                addr(f"ta{ti}", len(t["values"]), y - RL - 1, sb, CB)
                a(f"logic [{TW - 1}:0] tq{ti};")
                twinst(ti)
                a(f"logic [{TW - 1}:0] td{ti} [{LG + 1}];")
                a(f"always_ff @(posedge clk) begin td{ti}[0] <= tq{ti}; "
                  + "".join(f"td{ti}[{k2}] <= td{ti}[{k2 - 1}]; " for k2 in range(1, LG + 1)) + "end")
                a(f"always_ff @(posedge clk) {nm} <= td{ti}[{LG}];")
                tfo[ti] = ftf(ti, nm)
                continue
            if t["src"] == "tree":
                # the base table's word times this table's constant (per modulus and direction)
                if len(t["cst"]) > 1 or LD:
                    addr(f"gha{ti}", len(t["cst"]), y - RL - 1, 0, CB)
                    a(f"logic [{TW - 1}:0] ghq{ti};")
                    a(f"{name}_th{ti} u_th{ti} (.clk(clk), .addr(gha{ti}), .q0(ghq{ti}){ldp(f'{name}_th{ti}')});")
                    bv = f"ghq{ti}"
                else:
                    bv = _h(t["cst"][0], TW)
                a(f"{dpg.name} u_gen{ti} (.clk(clk), .A({ging['A']}'(tq{t['base']})), .B({ging['B']}'({bv})){gq}, .P(gp{ti}));")
                a(f"always_ff @(posedge clk) gv{ti} <= {TW}'(gp{ti});")
            elif t["src"] == "otf":
                h = t["h"]
                addr(f"gla{ti}", len(t["lo"]), y - RL - 1, h, CB - sb + h)
                addr(f"gha{ti}", len(t["hi"]), y - RL - 1, sb - h, CB)
                a(f"logic [{TW - 1}:0] glq{ti}, ghq{ti};")
                a(f"{name}_tl{ti} u_tl{ti} (.clk(clk), .addr(gla{ti}), .q0(glq{ti}){ldp(f'{name}_tl{ti}')});")
                a(f"{name}_th{ti} u_th{ti} (.clk(clk), .addr(gha{ti}), .q0(ghq{ti}){ldp(f'{name}_th{ti}')});")
                av, bv = f"glq{ti}", f"ghq{ti}"
                a(f"{dpg.name} u_gen{ti} (.clk(clk), .A({ging['A']}'({av})), .B({ging['B']}'({bv})){gq}, .P(gp{ti}));")
                a(f"always_ff @(posedge clk) gv{ti} <= {TW}'(gp{ti});")
            else:
                k, Dr = t["k"], t["D"]
                dA = Dr - LG - 1
                assert dA >= 0
                # base word (entries i < k), valid at t+Ov-1; the update word valid at t+y
                kb = max(1, (k - 1).bit_length())
                ib = min(sb, kb)
                # base address: (m D + d) k + min(i, k - 1), i = the top sb bits of c
                AB = _bits(len(t["base"]))
                md = []
                if MB:
                    md.append(f"{AB}'({tg(Ov - 2 - RL, 'm')}) * {AB}'({D})")
                if DP and D == 2:
                    md.append(f"{AB}'({tg(Ov - 2 - RL, 'd')})")
                mdx = f"({' + '.join(md)})" if md else f"{AB}'d0"
                ci = f"tg{Ov - 2 - RL}[{pos['c'][0] + CB - 1}:{pos['c'][0] + CB - sb}]"
                used.add(Ov - 2 - RL)
                a(f"logic [{AB - 1}:0] gba{ti};")
                a(f"always_ff @(posedge clk) gba{ti} <= {mdx} * {AB}'({k}) + (({ci}) < {sb}'d{k} ? {AB}'({ci}) : {AB}'d0);")
                a(f"logic [{TW - 1}:0] gbq{ti};")
                a(f"{name}_tb{ti} u_tb{ti} (.clk(clk), .addr(gba{ti}), .q0(gbq{ti}){ldp(f'{name}_tb{ti}')});")
                if len(t["upd"]) > 1 or LD:
                    addr(f"gua{ti}", len(t["upd"]), y - RL - 1, 0, CB)
                    a(f"logic [{TW - 1}:0] guq{ti};")
                    a(f"{name}_tu{ti} u_tu{ti} (.clk(clk), .addr(gua{ti}), .q0(guq{ti}){ldp(f'{name}_tu{ti}')});")
                    bv = f"guq{ti}"
                else:
                    bv = _h(t["upd"][0], TW)
                if dA:
                    a(f"logic [{TW - 1}:0] gd{ti} [{dA}];")
                    a(f"always_ff @(posedge clk) begin gd{ti}[0] <= gv{ti}; "
                      + "".join(f"gd{ti}[{k2}] <= gd{ti}[{k2 - 1}]; " for k2 in range(1, dA)) + "end")
                    av = f"gd{ti}[{dA - 1}]"
                else:
                    av = f"gv{ti}"
                a(f"{dpg.name} u_gen{ti} (.clk(clk), .A({ging['A']}'({av})), .B({ging['B']}'({bv})){gq}, .P(gp{ti}));")
                a(f"always_ff @(posedge clk) gv{ti} <= ({tg(Ov - 1, 'c')} < {CB}'d{Dr}) ? gbq{ti} : {TW}'(gp{ti});")
            a(f"always_ff @(posedge clk) {nm} <= gv{ti};")
        elif t["style"] == "const" and not LD:
            a(f"assign {nm} = {_h(t['values'][0], TWW)};")
        elif t.get("sel"):
            # unified: the forward's entry is the top beat bits, the inverse's the low ones (per direction)
            depth = len(t["values"])
            AB = _bits(depth)
            E = t["E"]
            md = []
            if MB:
                md.append(f"{AB}'({tg(A_ - 1, 'm')}) * {AB}'({D})")
            if DP and D == 2:
                md.append(f"{AB}'({tg(A_ - 1, 'd')})")
            mdx = f"({' + '.join(md)})" if md else f"{AB}'d0"
            ents = []
            for (lo_, nb_) in t["sel"]:
                if nb_:
                    ents.append(f"{AB}'(tg{A_ - 1}[{pos['c'][0] + lo_ + nb_ - 1}:{pos['c'][0] + lo_}])")
                    used.add(A_ - 1)
                else:
                    ents.append(f"{AB}'d0")
            ex = f"({tg(A_ - 1, 'd')} ? {ents[1]} : {ents[0]})" if len(ents) == 2 else ents[0]
            a(f"logic [{AB - 1}:0] ta{ti}; logic [{TWW - 1}:0] tq{ti};")
            a(f"always_ff @(posedge clk) ta{ti} <= {mdx} * {AB}'({E}) + {ex};")
            twinst(ti)
            a(f"always_ff @(posedge clk) {nm} <= tq{ti};")
        else:
            depth = len(t["values"])
            AB = _bits(depth)
            parts = []
            if MB:
                parts.append(tg(A_ - 1, "m"))
            if DP and D == 2 and ti not in SHR:
                parts.append(tg(A_ - 1, "d"))
            if sb:
                lo = pos["c"][0] + CB - sb
                parts.append(f"tg{A_ - 1}[{pos['c'][0] + CB - 1}:{lo}]")
                used.add(A_ - 1)
                if SHM.get(ti) in ("neg", "cpl"):
                    # shared inverse: an inverse polynomial reads the forward block at -entry or ~entry
                    eb = parts[-1]
                    parts[-1] = f"({tg(A_ - 1, 'd')} ? " + (f"~{eb}" if SHM[ti] == "cpl" else f"({sb}'d0 - {eb})") + f" : {eb})"
            if not parts:
                parts.append("1'b0")
            a(f"logic [{AB - 1}:0] ta{ti}; logic [{TWW - 1}:0] tq{ti};")
            a(f"always_ff @(posedge clk) ta{ti} <= {AB}'({{{', '.join(parts)}}});")
            twinst(ti)
            a(f"always_ff @(posedge clk) {nm} <= tq{ti};")
        tfo[ti] = ftf(ti, nm)

    # --- the block: U stages --------------------------------------------------------------------
    use = sp["use"]
    swn = {}
    a(f"// ---- the block: {U} stages of {W // 2} butterflies ({bs.name}, latency {Lbu}); stage j pairs lane bit j")
    half = sp["halve"]
    for j in range(U):
        dj = Tin + j * Ls                    # stage j input valid at t+dj
        qn = {}
        for qp, _ in qports.get("bu", []):
            qn[qp] = mreg(f"q{j}_{qp}", qp, dj, "bu", "modulus constants", W // 2)
        if any(pn == "DIR" for pn, _ in bs.extraPorts):
            # the unified butterfly: CT (0) or GS (1), in step with its operands
            a(f"(* max_fanout = 16 *) logic bd{j};")
            a(f"always_ff @(posedge clk) bd{j} <= {tg(dj - 1 - KS, 'd') if DP else ('1' if sp['direction'] == 'inverse' else '0')};")
            qn["DIR"] = f"bd{j}"
            if DP and KS:
                mleaf[f"bd{j}"] = ftree("stage tags", f"ft_bd{j}", [("v", 1, f"bd{j}")], W // 2)
        dout = dj + Lbu                      # butterfly outputs valid at t+dout; stage register at +1
        hvl = bpl = rsl = None                   # fan-out trees of this stage's tags (per butterfly)
        bi = -1
        if half:
            a(f"(* max_fanout = 32 *) logic hv{j};")
            a(f"always_ff @(posedge clk) hv{j} <= {tg(dout - 1 - KS, 'd') if DP else ('1' if sp['direction'] == 'inverse' else '0')};")
            if DP and KS:
                hvl = ftree("stage tags", f"ft_hv{j}", [("v", 1, f"hv{j}")], W // 2)
            qh = mreg(f"qh{j}", "QHALF", dout, "half") if "half" in qw else _h((sp["q"] + 1) // 2, Wd)
        byp = j < e
        if byp:
            a(f"(* max_fanout = 32 *) logic bp{j};")
            a(f"always_ff @(posedge clk) bp{j} <= {tg(dout - 1 - KS, 'r0')};")
            if KS:
                bpl = ftree("stage tags", f"ft_bp{j}", [("v", 1, f"bp{j}")], W // 2)
        nxt = [None] * W
        for l in range(W):
            a(f"logic [{Wd - 1}:0] s{j + 1}_{l};")
            nxt[l] = f"s{j + 1}_{l}"
        for (jj, h, aa, la, lb) in sp["pairs"]:
            if jj != j:
                continue
            bi += 1
            hvx = hvl(bi)["v"] if hvl else f"hv{j}"
            bpx = bpl(bi)["v"] if bpl else f"bp{j}"
            # W register: the round mux over this butterfly's tables
            wn = f"w{j}_{la}"
            a(f"logic [{TWW - 1}:0] {wn};")
            srcs = [(r, use[(j, la, r)]) for r in range(R)]
            srcs = [(r, tfu(ti)) for r, ti in srcs if ti is not None]
            xsh = [(r, use[(j, la, r)], SHR[use[(j, la, r)]][0]) for r in range(R) if use[(j, la, r)] in SHR]
            if any(ti != tj for _, ti, tj in xsh):
                # shared inverse: in some round the inverse's word comes from another table of the stage
                inv = {r: tj for r, _, tj in xsh}
                a(f"always_ff @(posedge clk) case ({{{tg(dj - 1, 'd')}, {tg(dj - 1, 'r')}}})")
                for r in range(R):
                    ti = use[(j, la, r)]
                    if ti is None:
                        continue
                    if inv.get(r, ti) == ti:
                        a(f"    {{1'b0, {_c(r, RB)}}}, {{1'b1, {_c(r, RB)}}}: {wn} <= {tfu(ti)};")
                    else:
                        a(f"    {{1'b0, {_c(r, RB)}}}: {wn} <= {tfu(ti)};")
                        a(f"    {{1'b1, {_c(r, RB)}}}: {wn} <= {tfu(inv[r])};")
                a(f"    default: {wn} <= {srcs[0][1]};")
                a("endcase")
            elif len(srcs) == 1:
                a(f"always_ff @(posedge clk) {wn} <= {srcs[0][1]};")
            else:
                if KS and rsl is None:
                    rsl = ftree("stage tags", f"ft_rs{j}", [("r", RB, tg(dj - 1 - KS, 'r'))], W // 2)
                a(f"always_ff @(posedge clk) case ({rsl(bi)['r'] if rsl else tg(dj - 1, 'r')})")
                for r, sname in srcs:
                    a(f"    {_c(r, RB)}: {wn} <= {sname};")
                a(f"    default: {wn} <= {srcs[0][1]};")
                a("endcase")
            conn = [".clk(clk)", f".aIn({st[la]})", f".bIn({st[lb]})", f".W({wn}[{TW - 1}:0])"]
            if TWW > TW:
                conn.append(f".WP({wn}[{TWW - 1}:{TW}])")
            for pn, _ in bs.extraPorts:
                if pn not in ("W", "WP"):
                    conn.append(f".{pn}({mleaf[qn[pn]](bi)['v'] if qn[pn] in mleaf else qn[pn]})")
            xr, yr = f"bx{j}_{la}", f"by{j}_{la}"
            swx = None
            ssig = tuple((r, SHR[use[(j, la, r)]][2]) for r in range(R)
                         if use[(j, la, r)] in SHR and SHR[use[(j, la, r)]][2] != "+")
            if ssig:
                # shared inverse: the inverse's word is minus the forward word read: the two outputs swap
                if (j, ssig) not in swn:
                    swn[(j, ssig)] = f"sw{j}_{len(swn)}"
                    terms = []
                    for r, rule in ssig:
                        sbr = tabs[use[(j, la, r)]]["sb"]
                        cnd = f"{tg(dout - 1, 'r')} == {_c(r, RB)}"
                        if rule in ("nz", "z"):
                            cnd += f" && ({'|' if rule == 'nz' else '~|'}tg{dout - 1}[{pos['c'][0] + CB - 1}:{pos['c'][0] + CB - sbr}])"
                        terms.append(f"({cnd})")
                    a(f"(* max_fanout = 32 *) logic {swn[(j, ssig)]};")
                    a(f"always_ff @(posedge clk) {swn[(j, ssig)]} <= {tg(dout - 1, 'd')} && ({' || '.join(terms)});")
                swx = swn[(j, ssig)]
            a(f"logic [{bs.aOutBitWidth - 1}:0] {xr}; logic [{bs.bOutBitWidth - 1}:0] {yr};")
            conn += [f".aOut({xr})", f".bOut({yr})"]
            a(f"{bs.name} u_bu{j}_{la} ({', '.join(conn)});")
            for v, bw, lane in ((xr, bs.aOutBitWidth, la), (yr, bs.bOutBitWidth, lb)):
                vx = v if bw == Wd else f"{Wd}'({v})"
                if swx:
                    ov, ow = (yr, bs.bOutBitWidth) if v == xr else (xr, bs.aOutBitWidth)
                    a(f"logic [{Wd - 1}:0] {v}s; assign {v}s = {swx} ? " + (ov if ow == Wd else f"{Wd}'({ov})") + f" : {vx};")
                    vx = f"{v}s"
                if half:
                    vx = f"({hvx} ? ({Wd}'({vx} >> 1) + ({vx}[0] ? {Wd}'({qh}) : '0)) : {vx})"
                if byp:
                    # the stage's input delayed by the butterfly latency
                    dn = f"bd{j}_{lane}"
                    a(f"logic [{Wd - 1}:0] {dn} [{Lbu}];")
                    a(f"always_ff @(posedge clk) begin {dn}[0] <= {st[lane]}; "
                      + "".join(f"{dn}[{k}] <= {dn}[{k - 1}]; " for k in range(1, Lbu)) + "end")
                    vx = f"({bpx} ? {dn}[{Lbu - 1}] : {vx})"
                a(f"always_ff @(posedge clk) {nxt[lane]} <= {vx};")
        st = nxt
    blk = st                                  # valid at t+BO

    # --- write path: rotate group hi right by c mod 2^U, write register ---------------------------
    a("// ---- write path: bank hi*2^U + ((lo + c) mod 2^U) <- lane hi*2^U + lo")

    def wamt(i):
        d = BO - 1 + i - fk("write rotate")
        lo = 2 * i
        nb = min(2, U - 2 * i)
        used.add(d)
        return f"tg{d}[{pos['c'][0] + lo + nb - 1}:{pos['c'][0] + lo}]"
    # blk lane b = hi*MU + lo; out bank k of group hi = blk[hi*MU + (k - c)]
    wout = rot_levels("wr", blk, wamt, -1, BO, "write rotate")
    a("always_ff @(posedge clk) begin")
    pw_t = BO + RT + XR - fk("pool write")
    a(f"    pw_e <= {tg(pw_t, 'v')} && !{tg(pw_t, 'last')};")
    a(f"    pw_a <= {PA}'({tg(pw_t, 'wb')}) * {PA}'({T}) + {PA}'({tg(pw_t, 'c')});")
    a("end")
    for b in range(W):
        if XR:
            # crossing registers between the write rotator and the write register
            a(f"{NOSR}logic [{Wd - 1}:0] pwx{b} [{XR}];")
            a(f"always_ff @(posedge clk) begin pwx{b}[0] <= {wout[b]}; "
              + "".join(f"pwx{b}[{k}] <= pwx{b}[{k - 1}]; " for k in range(1, XR)) + "end")
            wout[b] = f"pwx{b}[{XR - 1}]"
        a(f"always_ff @(posedge clk) pw_d{b} <= {wout[b]};")

    # --- output ---------------------------------------------------------------------------------
    a("// ---- output: the last round's block output (through the twist multipliers)")
    if tw is not None:
        dpt = tw["datapath"]
        pw = dpt.wire(dict(dpt.outputs)["P"]).bitWidth
        ain = {x.name: x.bitWidth for x in dpt.inputs}
        tqn = {}
        for x in dpt.inputs:
            if x.name not in ("A", "B"):
                tqn[x.name] = mreg(f"tq_{x.name}", x.name, BO, "twist", "twist constants", W)
        if tw.get("src") == "rec":
            # the twist operands by a recurrence per lane: v(c) = v(c - Dr) x upd (Kim), v valid at t+BO-1
            rec = tw["rec"]
            Dr = rec["D"]
            LG = gen["latency"]
            dpg = gen["datapath"]
            pwg = dpg.wire(dict(dpg.outputs)["P"]).bitWidth
            ging = {x.name: x.bitWidth for x in dpg.inputs}
            Ov = BO - 1
            y = Ov - 1 - LG
            dA = Dr - LG - 1
            assert dA >= 0
            gq = "".join(f", .{x.name}({mreg(f'tgq_{x.name}', x.name, y, 'gen')})" for x in dpg.inputs
                         if x.name not in ("A", "B"))
            AB = _bits(len(rec["base"][0]))
            md = []
            if MB:
                md.append(f"{AB}'({tg(Ov - 2 - RL - fk('twist address'), 'm')}) * {AB}'({D})")
            if DP and D == 2:
                md.append(f"{AB}'({tg(Ov - 2 - RL - fk('twist address'), 'd')})")
            mdx = f"({' + '.join(md)})" if md else f"{AB}'d0"
            cc_ = tg(Ov - 2 - RL - fk('twist address'), "c")
            a(f"(* max_fanout = 16 *) logic [{AB - 1}:0] ttba;")
            a(f"always_ff @(posedge clk) ttba <= {mdx} * {AB}'({Dr}) + (({cc_}) < {CB}'d{Dr} ? {AB}'({cc_}) : {AB}'d0);")
            ttl = ftree("twist address", "ft_ttba", [("a", AB, "ttba")], W)
            if len(rec["upd"]) > 1 or LD:
                UB = _bits(len(rec["upd"]))
                md2 = []
                if MB:
                    md2.append(f"{UB}'({tg(y - RL - 1, 'm')}) * {UB}'({D})")
                if DP and D == 2:
                    md2.append(f"{UB}'({tg(y - RL - 1, 'd')})")
                if not md2:
                    md2.append(f"{UB}'d0")
                a(f"logic [{UB - 1}:0] ttua; (* max_fanout = 16 *) logic [{TW - 1}:0] ttuq;")
                a(f"always_ff @(posedge clk) ttua <= {' + '.join(md2)};")
                a(f"{name}_ttu u_ttu (.clk(clk), .addr(ttua), .q0(ttuq){ldp(f'{name}_ttu')});")
                ub = "ttuq"
            else:
                ub = _h(rec["upd"][0], TW)
            sel = f"({tg(Ov - 1, 'c')} < {CB}'d{Dr})"
            for l in range(W):
                a(f"logic [{TW - 1}:0] ttr{l}, ttb{l}, tbq{l}; logic [{pw - 1}:0] tp{l}; logic [{pwg - 1}:0] tgp{l};")
                a(f"{name}_ttb{l} u_ttb{l} (.clk(clk), .addr({ttl(l)['a']}), .q0(tbq{l}){ldp(f'{name}_ttb{l}')});")
                if dA:
                    a(f"logic [{TW - 1}:0] ttd{l} [{dA}];")
                    a(f"always_ff @(posedge clk) begin ttd{l}[0] <= ttr{l}; "
                      + "".join(f"ttd{l}[{k2}] <= ttd{l}[{k2 - 1}]; " for k2 in range(1, dA)) + "end")
                    av_ = f"ttd{l}[{dA - 1}]"
                else:
                    av_ = f"ttr{l}"
                a(f"{dpg.name} u_ttg{l} (.clk(clk), .A({ging['A']}'({av_})), .B({ging['B']}'({ub})){gq}, .P(tgp{l}));")
                a(f"always_ff @(posedge clk) ttr{l} <= {sel} ? tbq{l} : {TW}'(tgp{l});")
                a(f"always_ff @(posedge clk) ttb{l} <= ttr{l};")
        else:
            TTA = _bits(tw["depth"])
            A_ = BO - RL - 1 - fk("twist address")
            parts = []
            if MB:
                parts.append(tg(A_ - 1, "m"))
            if DP and D == 2:
                parts.append(tg(A_ - 1, "d"))
            parts.append(tg(A_ - 1, "c"))
            a(f"(* max_fanout = 16 *) logic [{TTA - 1}:0] tta;")
            a(f"always_ff @(posedge clk) tta <= {TTA}'({{{', '.join(parts)}}});")
            ttl = ftree("twist address", "ft_tta", [("a", TTA, "tta")], W)
            for l in range(W):
                a(f"logic [{TW - 1}:0] ttr{l}, ttb{l}; logic [{pw - 1}:0] tp{l};")
                a(f"{name}_tt{l} u_tt{l} (.clk(clk), .addr({ttl(l)['a']}), .q0(ttr{l}){ldp(f'{name}_tt{l}')});")
                a(f"always_ff @(posedge clk) ttb{l} <= ttr{l};")
        for l in range(W):
            av = blk[l] if ain["A"] == Wd else f"{ain['A']}'({blk[l]})"
            qc = "".join(f", .{k}({mleaf[v](l)['v'] if v in mleaf else v})" for k, v in tqn.items())
            a(f"{dpt.name} u_twist{l} (.clk(clk), .A({av}), .B(ttb{l}){qc}, .P(tp{l}));")
            a(f"always_ff @(posedge clk) y_out_{l} <= {OW}'(tp{l});")
        LT = tw["latency"]
    else:
        LT = 0
        for l in range(W):
            a(f"always_ff @(posedge clk) y_out_{l} <= {OW}'({blk[l]});")
    assert OO == BO + LT + 1
    a("always_ff @(posedge clk) begin")
    a(f"    out_valid <= rst ? 1'b0 : ({tg(BO + LT, 'v')} && {tg(BO + LT, 'last')});")
    if MB:
        a(f"    midx_out <= {tg(BO + LT, 'm')};")
    if DP:
        a(f"    dir_out <= {tg(BO + LT, 'd')};")
    a("end")

    # --- tag pipeline (emitted last: its length is known now) ------------------------------------
    DMX = max(used)
    decl = [f"    // ---- tag pipeline: tag d = the issue's fields d cycles later (valid bits reset), d <= {DMX}",
            f"    logic [{DMX - 1}:0] vch;"] + [f"    logic [{TGW - 1}:0] tg{d};" for d in range(2, DMX + 1)]
    tail = ["    always_ff @(posedge clk) vch <= rst ? '0 : " + (f"{{vch[{DMX - 2}:0], iss}};" if DMX > 1 else "iss;")]
    tail += [f"    always_ff @(posedge clk) tg{d} <= tg{d - 1};" for d in range(2, DMX + 1)]
    # the controller's tag-1 and issue declarations first, then the rest
    first = [x for x in O if x.strip().startswith("logic start, run_c") or x.strip() == f"logic [{TGW - 1}:0] tg1;"]
    for x in first:
        O.remove(x)
    if LD:
        NR = len(regs)
        SB, LA, LW = _bits(NR), max(_bits(r["depth"]) for r in regs), max(r["width"] for r in regs)
        ports += ["    input  logic ld_we", f"    input  logic [{SB - 1}:0] ld_sel", f"    input  logic [{LA - 1}:0] ld_addr",
                  f"    input  logic [{LW - 1}:0] ld_data"]
        decl = [f"    // ---- load port: {NR} regions (manifest.json: load_map), one word per cycle; a region may be written",
                "    // while no polynomial in flight uses the words written",
                f"    (* max_fanout = 32 *) logic [{NR - 1}:0] ld_en; (* max_fanout = 32 *) logic [{LA - 1}:0] ld_a; "
                f"(* max_fanout = 32 *) logic [{LW - 1}:0] ld_d;",
                "    always_ff @(posedge clk) begin",
                f"        ld_en <= ld_we ? ({NR}'d1 << ld_sel) : '0; ld_a <= ld_addr; ld_d <= ld_data;",
                "    end"] + decl
    O[:] = first + decl + O + tail
    head = (f"// {name}: hybrid NTT, n={n}, block of {U} stages x {W // 2} butterflies ({g} group(s) of {MU} lanes), "
            f"{R} rounds ({e} stage(s) bypassed in round 0), {S} context(s), slot {DL} cycles, "
            f"interval {R * DL}, {f'run-time modulus ({M} loadable slot(s))' if LD else 'moduli ' + str(sp['moduli']) if MB else 'q=' + str(sp['q'])}, "
            f"direction {sp['direction']}{', negacyclic' if sp['negacyclic'] else ''}")
    out = ["`timescale 1ns / 1ps", head, f"module {name} (\n" + ",\n".join(ports) + "\n    );"] + O + ["endmodule"]
    with open(os.path.join(rtl, f"{name}.sv"), "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")

    # --- testbench --------------------------------------------------------------------------------
    if tb is not None and not sp.get("portTop"):
        tv = "testvectors"
        os.makedirs(tv, exist_ok=True)
        NX, NY, NC = len(tb["x"]), len(tb["y"]), tb["cycles"]
        for l in range(sp.get("io") or W):
            with open(os.path.join(tv, f"x_{l}.txt"), "w") as f:
                f.write("".join(to_twos_complement_hex(bt[l], Wd) + "\n" for bt in tb["x"]))
            with open(os.path.join(tv, f"y_{l}.txt"), "w") as f:
                f.write("".join(to_twos_complement_hex(bt[l], OW) + "\n" for bt in tb["y"]))
        with open(os.path.join(tv, "tags.txt"), "w") as f:
            f.write("".join(f"{(m << 1) | d:x}\n" for m, d in tb["tags"]))
        with open(os.path.join(tv, "ytags.txt"), "w") as f:
            f.write("".join(f"{(m << 1) | d:x}\n" for m, d in tb["ytags"]))
        with open(os.path.join(tv, "ycycle.txt"), "w") as f:
            f.write("".join(f"{c:08x}\n" for c in tb["ycycle"]))
        with open(os.path.join(tv, "valid.txt"), "w") as f:
            f.write("".join(f"{v}\n" for v in tb["valid"]))
        NL = sum(r["depth"] for r in regs)
        if LD:
            with open(os.path.join(tv, "load.txt"), "w") as f:
                f.write("".join(f"{k:x}\n{i:x}\n{v:x}\n" for k, r in enumerate(regs) for i, v in enumerate(r["values"])))
        with open(os.path.join(rtl, f"{sp.get('ioTop') or name}_tb.sv"), "w", encoding="utf-8") as f:
            f.write(_tb(dict(sp, W=sp.get("io") or W), NX, NY, NC, (NL, SB, LA, LW) if LD else None,
                        [(ti, ab, TWW) for ti, ab in ext], dut=sp.get("ioTop")))
    if sp.get("ioTop"):
        with open(os.path.join(rtl, f"{sp['ioTop']}.sv"), "w", encoding="utf-8") as f:
            f.write(_io_wrapper(sp, ports))
    manifest = {"top_name": sp.get("ioTop") or name, "io_lanes": sp.get("io") or W, "n": n, "stages": U, "groups": g, "lanes": W, "rounds": R, "bypassed": e,
                "contexts": S, "slot": DL, "interval": R * DL, "width": Wd, "out_width": OW, "bu_latency": Lbu,
                "in_offset": Tin, "block_out": BO, "write_offset": WO, "out_offset": OO, "fifo_depth": ID,
                "tables": len(tabs), "midx_bits": MB, "dir_port": DP, "moduli": sp["moduli"]}
    if FAN:
        manifest.update(fanout=sp.get("fanout"), fan_shift=FR, fan_trees={k: list(v["levels"]) for k, v in FAN.items()})
    if LD:
        manifest.update(loadable=True, load_sel_bits=SB, load_addr_bits=LA, load_data_bits=LW,
                        load_map=[{"sel": k, "name": r["name"], "width": r["width"], "depth": r["depth"]}
                                  for k, r in enumerate(regs)])
        with open("load_image.json", "w", encoding="utf-8") as f:
            json.dump({"moduli": sp["moduli"], "regions": [{"sel": k, "name": r["name"], "values": r["values"]}
                                                           for k, r in enumerate(regs)]}, f)
    if sp.get("portTop"):
        # outReady / natural order / record stream: the wrapper and its testbench (rtl_gen.hybrid_ports)
        from rtl_gen.hybrid_ports import emit_ports
        manifest.update(emit_ports(sp, ports, regs, tb, [(ti, ab, TWW) for ti, ab in ext]))
    with open("manifest.json", "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    return manifest


def sp_table_stage(sp: dict, ti: int) -> int:
    """The stage a table serves (tables are per round and stage)."""
    for (j, la, r), t in sp["use"].items():
        if t == ti:
            return j
    raise AssertionError(f"table {ti} unused")


def _io_wrapper(sp: dict, core_ports: list) -> str:
    """The port adapters around the core `sp['name']` for ports of io words per beat (module `sp['ioTop']`;
    the twin: HybridNTTScheme.simulateIoJob). Narrower ports: the input beats are gathered into one core beat,
    the core's output beats wait in a buffer of `outBufPolys` polynomials and leave io words per cycle. Wider
    ports: the input beat is held and fed in io/W core beats, the output beats are collected."""
    import re
    name, top, W, io, T = sp["name"], sp["ioTop"], sp["W"], sp["io"], sp["T"]
    Wd, OW, MB, DP = sp["width"], sp["outWidth"], sp["MB"], sp["dirPort"]
    narrow = io < W
    RHO = W // io if narrow else io // W
    RB = _bits(RHO)
    std = {"clk", "rst", "in_valid", "in_ready", "out_valid", "MIDX", "DIR", "midx_out", "dir_out"}
    extra = []
    for p in core_ports:
        pn = re.split(r"\s+", p.strip())[-1]
        if pn not in std and not re.fullmatch(r"(x_in|y_out)_\d+", pn):
            extra.append((p, pn))
    ports = ["    input  logic clk", "    input  logic rst", "    input  logic in_valid", "    output logic in_ready"]
    if MB:
        ports.append(f"    input  logic [{MB - 1}:0] MIDX")
    if DP:
        ports.append("    input  logic DIR")
    ports += [f"    input  logic [{Wd - 1}:0] x_in_{l}" for l in range(io)]
    ports.append("    output logic out_valid")
    if MB:
        ports.append(f"    output logic [{MB - 1}:0] midx_out")
    if DP:
        ports.append("    output logic dir_out")
    ports += [f"    output logic [{OW - 1}:0] y_out_{l}" for l in range(io)]
    ports += [p for p, _ in extra]
    O = []
    a = O.append
    a("    logic k_valid, k_ready, k_ov;")
    for l in range(W):
        a(f"    logic [{Wd - 1}:0] k_x_{l}; logic [{OW - 1}:0] k_y_{l};")
    conn = [".clk(clk)", ".rst(rst)", ".in_valid(k_valid)", ".in_ready(k_ready)"]
    if MB:
        a(f"    logic [{MB - 1}:0] k_midx, k_mo;")
        conn += [".MIDX(k_midx)", ".midx_out(k_mo)"]
    if DP:
        a("    logic k_dir, k_do;")
        conn += [".DIR(k_dir)", ".dir_out(k_do)"]
    conn += [f".x_in_{l}(k_x_{l})" for l in range(W)] + [".out_valid(k_ov)"]
    conn += [f".y_out_{l}(k_y_{l})" for l in range(W)] + [f".{pn}({pn})" for _, pn in extra]
    a(f"    {name} u_core ({', '.join(conn)});")
    a("    logic acc, kacc;")
    a(f"    logic [{RB - 1}:0] ic;")
    a("    logic full;")
    a("    assign acc = in_valid && in_ready;")
    a("    assign kacc = full && k_ready;")
    a("    assign k_valid = full;")
    tagc = ([" k_midx <= MIDX;"] if MB else []) + ([" k_dir <= DIR;"] if DP else [])
    if narrow:
        a(f"    // ---- input: {RHO} port beats make one core beat; the tags are those of a core beat's first port beat")
        a("    assign in_ready = !full || k_ready;")
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
        DEP = sp["outBufPolys"] * T
        PB = _bits(DEP)
        BW = W * OW + MB + (1 if DP else 0)
        a(f"    // ---- output: a buffer of {sp['outBufPolys']} polynomials ({DEP} core beats); one core beat leaves in {RHO} cycles")
        a(f"    logic [{BW - 1}:0] ob [{DEP}];")
        a(f"    logic [{BW - 1}:0] od, oq;")
        a(f"    logic [{PB}:0] wp, rp;")
        a(f"    logic [{RB - 1}:0] ec, s1_i;")
        a("    logic issue, s1_v;")
        cat = (["k_do"] if DP else []) + (["k_mo"] if MB else []) + [f"k_y_{l}" for l in reversed(range(W))]
        a(f"    assign od = {{{', '.join(cat)}}};")
        a("    assign issue = (ec == '0) && (rp != wp);")
        a(f"    always_ff @(posedge clk) if (k_ov) ob[wp[{PB - 1}:0]] <= od;")
        a(f"    always_ff @(posedge clk) if (issue) oq <= ob[rp[{PB - 1}:0]];")
        a("    always_ff @(posedge clk) begin")
        a("        if (rst) begin wp <= '0; rp <= '0; ec <= '0; s1_v <= 1'b0; out_valid <= 1'b0; end")
        a("        else begin")
        a("            if (k_ov) wp <= wp + 1'b1;")
        a("            if (issue) rp <= rp + 1'b1;")
        a("            if (issue || ec != '0) ec <= ec + 1'b1;")
        a("            s1_v <= issue || ec != '0;")
        a("            out_valid <= s1_v;")
        a("        end")
        a("        s1_i <= ec;")
        a("    end")
        a("    always_ff @(posedge clk) begin")
        if MB:
            a(f"        midx_out <= oq[{W * OW} +: {MB}];")
        if DP:
            a(f"        dir_out <= oq[{W * OW + MB}];")
        a("        case (s1_i)")
        for i in range(RHO):
            a(f"            {_c(i, RB)}: begin " +
              " ".join(f"y_out_{l} <= oq[{(i * io + l) * OW} +: {OW}];" for l in range(io)) + " end")
        a("        endcase")
        a("    end")
    else:
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
        a(f"    // ---- output: {RHO} core beats make one port beat")
        a(f"    logic [{RB - 1}:0] oc;")
        a("    always_ff @(posedge clk) begin")
        a("        if (rst) begin oc <= '0; out_valid <= 1'b0; end")
        a("        else begin")
        a("            if (k_ov) oc <= oc + 1'b1;")
        a(f"            out_valid <= k_ov && oc == {_c(RHO - 1, RB)};")
        a("        end")
        a("    end")
        a("    always_ff @(posedge clk) if (k_ov) begin")
        if MB:
            a("        midx_out <= k_mo;")
        if DP:
            a("        dir_out <= k_do;")
        a("        case (oc)")
        for i in range(RHO):
            a(f"            {_c(i, RB)}: begin " + " ".join(f"y_out_{i * W + l} <= k_y_{l};" for l in range(W)) + " end")
        a("        endcase")
        a("    end")
    head = (f"// {top}: the hybrid NTT {name} ({W} words per beat) behind ports of {io} words per beat "
            f"({sp['n'] // io} beats per polynomial)")
    return "\n".join(["`timescale 1ns / 1ps", head, f"module {top} (\n" + ",\n".join(ports) + "\n    );"] + O +
                     ["endmodule"]) + "\n"


def _tb(sp, NX, NY, NC, ld=None, ext=(), dut=None) -> str:
    name, W, Wd, OW, MB, DP = sp["name"], sp["W"], sp["width"], sp["outWidth"], sp["MB"], sp["dirPort"]
    dut = dut or name
    L = ["`timescale 1ns / 1ps", f"module {dut}_tb ();", "    logic clk = 1'b0;", "    always #5 clk = ~clk;",
         "    logic rst, in_valid, in_ready, out_valid;"]
    if MB:
        L.append(f"    logic [{MB - 1}:0] MIDX, midx_out;")
    if DP:
        L.append("    logic DIR, dir_out;")
    for l in range(W):
        L.append(f"    logic [{Wd - 1}:0] x_in_{l}; logic [{Wd - 1}:0] x_ts_{l} [{NX}];")
        L.append(f"    logic [{OW - 1}:0] y_out_{l}; logic [{OW - 1}:0] y_ts_{l} [{NY}];")
    L.append(f"    logic [31:0] ycyc [{NY}]; logic vpat [{NC}]; logic [15:0] tg_ts [{NX}]; logic [15:0] ytg_ts [{NY}];")
    L.append("    initial begin")
    for l in range(W):
        L.append(f'        $readmemh("../../../../../testvectors/x_{l}.txt", x_ts_{l});')
        L.append(f'        $readmemh("../../../../../testvectors/y_{l}.txt", y_ts_{l});')
    L.append('        $readmemh("../../../../../testvectors/ycycle.txt", ycyc);')
    L.append('        $readmemh("../../../../../testvectors/valid.txt", vpat);')
    L.append('        $readmemh("../../../../../testvectors/tags.txt", tg_ts);')
    L.append('        $readmemh("../../../../../testvectors/ytags.txt", ytg_ts);')
    L.append("    end")
    conn = [".clk(clk)", ".rst(rst)", ".in_valid(in_valid)", ".in_ready(in_ready)"]
    if MB:
        conn += [".MIDX(MIDX)", ".midx_out(midx_out)"]
    if DP:
        conn += [".DIR(DIR)", ".dir_out(dir_out)"]
    if ld:
        NL, SB, LA, LW = ld
        XW = max(SB, LA, LW)
        L.append(f"    logic ld_we = 1'b0; logic [{SB - 1}:0] ld_sel = '0; logic [{LA - 1}:0] ld_addr = '0; "
                 f"logic [{LW - 1}:0] ld_data = '0; logic [{XW - 1}:0] ld_ts [{3 * NL}];")
        L.append('    initial $readmemh("../../../../../testvectors/load.txt", ld_ts);')
        conn += [".ld_we(ld_we)", ".ld_sel(ld_sel)", ".ld_addr(ld_addr)", ".ld_data(ld_data)"]
    for ti, ab, tww in ext:
        # the twiddle supplier: the table outside the core
        L.append(f"    logic [{ab - 1}:0] tw_addr_{ti}; logic [{tww - 1}:0] tw_data_{ti};")
        L.append(f"    {name}_twx{ti} u_tw{ti} (.clk(clk), .addr(tw_addr_{ti}), .q0(tw_data_{ti}));")
        conn += [f".tw_addr_{ti}(tw_addr_{ti})", f".tw_data_{ti}(tw_data_{ti})"]
    conn += [f".x_in_{l}(x_in_{l})" for l in range(W)] + [".out_valid(out_valid)"]
    conn += [f".y_out_{l}(y_out_{l})" for l in range(W)]
    L.append(f"    {dut} DUT ({', '.join(conn)});")
    L.append("    int c, bad, xb, ob, late, first_in, last_out;")
    L.append("    initial begin")
    L.append("        bad = 0; xb = 0; ob = 0; late = 0; first_in = -1; last_out = -1; rst = 1'b1; in_valid = 1'b0;")
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
    L.append(f"            if (xb < {NX}) begin")
    if MB:
        L.append(f"                MIDX = tg_ts[xb][{MB}:1];")
    if DP:
        L.append("                DIR = tg_ts[xb][0];")
    for l in range(W):
        L.append(f"                x_in_{l} = x_ts_{l}[xb];")
    L.append("            end")
    L.append("            #2;")
    L.append("            if (out_valid) begin")
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
    L.append("            @(posedge clk);")
    L.append("        end")
    L.append(f"        if (ob != {NY}) begin bad++; $display(\"WRONG: %0d of {NY} output beats\", ob); end")
    L.append(f"        if (xb != {NX}) begin bad++; $display(\"WRONG: %0d of {NX} input beats accepted\", xb); end")
    L.append("        $display(\"[tb] rate: %0d beats in, %0d out, first input cycle %0d, last output cycle %0d, "
             "%0d late beats\", xb, ob, first_in, last_out, late);")
    L.append("        bad = bad + late;")
    L.append("        if (bad == 0) begin $display(\"SUCCESS!\"); $display(\"PASS All %0d Testvectors!\", ob); end")
    L.append("        else begin $display(\"TO BE DEBUGGED...\"); $display(\"FAILED: %0d wrong\", bad); end")
    L.append("        $finish();")
    L.append("    end")
    L.append("endmodule")
    return "\n".join(L) + "\n"
