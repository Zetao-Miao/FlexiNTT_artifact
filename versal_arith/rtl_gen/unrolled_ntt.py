"""The fully pipelined (unrolled) NTT's wrapper and testbench.

The core `<top>_core` is `rtl_gen.ntt.StreamNTT_RTL_gen` at lanes = n (one frame per
cycle; built by `operator_modeling.ntt.dataflow.UnrolledNTT.UnrolledNTT`). This file adds

  * `<top>`: ports in the requested order (`x_in_<i>` / `y_out_<k>`, natural or
    bit-reversed: in a spatial design a reordering is wiring), `in_valid` ->
    `out_valid` (a delay of the latency, cleared by `rst`), and the per-frame tag
    `MIDX` / `DIR` -> `midx_out` / `dir_out` aligned with the outputs;
  * `<top>_tb`: a new transform on every valid cycle (MIDX and DIR changing every
    cycle), invalid cycles with random data and tags in between; every cycle checks
    out_valid, and every valid output cycle checks every lane and the tags, at the
    exact cycle (latency + input cycle), so a slower interval fails;
  * testvectors/x_in.txt, y_out.txt (one packed line per cycle, port 0 in the LSBs),
    ctl.txt (valid | DIR << 1 | MIDX << 2 per cycle).
"""
from __future__ import annotations

import json
import os

from rtl_gen.ntt import _pack_per_slot


def UnrolledNTT_wrapper_gen(w: dict, core_meta: dict, tb: dict | None = None) -> dict:
    top, core, n = w["top"], w["core"], w["n"]
    IW, OW, LAT = w["inWidth"], w["outWidth"], w["latency"]
    MB = w["midxBits"]
    DP = bool(w["dirPort"])
    PF = MB > 0
    FD = bool(w.get("frameDir"))                 # DIR per transform without per-frame moduli
    TD = DP and (PF or FD)                       # dir_out leaves with the data
    TGW = MB + (1 if TD else 0)
    qports = list(zip(core_meta["q_ports"], core_meta["q_port_widths"])) if not PF else []
    loadW = core_meta.get("load_words", 0)
    TWW = core_meta.get("tw_width", 0)
    NS, SW = core_meta.get("stream_classes", 0), core_meta.get("stream_width", 0)
    # twiddleSource='port': core input tw_s<c> is butterfly twPorts[c] = (s, k), exposed as tw_<s>_<k>
    tpn = [f"tw_{a}_{b}" for a, b in w.get("twPorts") or []] or [f"tw_s{c}" for c in range(NS)]
    rtl = "RTL_generated"
    os.makedirs(rtl, exist_ok=True)
    ports = ["    input  logic clk", "    input  logic rst", "    input  logic in_valid"]
    if PF:
        ports.append(f"    input  logic [{MB - 1}:0] MIDX")
    if DP:
        ports.append("    input  logic DIR")
    ports += [f"    input  logic [{wd - 1}:0] {qp}" for qp, wd in qports]
    # run-time moduli per polynomial: the modulus constants come with each transform (mq_*), as MIDX does
    MTQ = list(zip(core_meta["q_ports"], core_meta["q_port_widths"])) if (PF and core_meta.get("loadable_moduli")) else []
    if MTQ:
        ports += [f"    input  logic [{wd - 1}:0] mq_{qp}" for qp, wd in MTQ]
    if loadW:
        ports += ["    input  logic tw_rst", "    input  logic tw_wen", f"    input  logic [{TWW - 1}:0] tw_wdata"]
        if MTQ:
            ports.append(f"    input  logic [{MB - 1}:0] tw_slot")
        if MTQ and core_meta.get("load_by_dir"):
            ports.append("    input  logic tw_dir")
    ports += [f"    input  logic [{SW - 1}:0] {tpn[c]}" for c in range(NS)]
    ports += [f"    input  logic [{IW - 1}:0] x_in_{i}" for i in range(n)]
    ports.append("    output logic out_valid")
    if PF:
        ports.append(f"    output logic [{MB - 1}:0] midx_out")
    if TD:
        ports.append("    output logic dir_out")
    ports += [f"    output logic [{OW - 1}:0] y_out_{k}" for k in range(n)]
    L = ["`timescale 1ns / 1ps",
         f"// {top}: fully pipelined NTT, n={n}, one transform per cycle, latency {LAT}, "
         f"ports in {w['inputOrder']} / {w['outputOrder']} order"
         + (f", {len(w['moduli'])} moduli (MIDX per transform)" if PF else ""),
         f"module {top} (\n" + ",\n".join(ports) + "\n    );"]
    for k in range(n):
        L.append(f"    logic [{OW - 1}:0] c_y_{k};")
    conn = [".clk(clk)", ".rst(rst)"]
    if DP:
        conn.append(".DIR(DIR)")
    if PF:
        conn.append(".MIDX(MIDX)")
    conn += [f".{qp}({qp})" for qp, _ in qports]
    if MTQ:
        conn += [f".mq_{qp}(mq_{qp})" for qp, _ in MTQ]
    if loadW:
        conn += [".tw_rst(tw_rst)", ".tw_wen(tw_wen)", ".tw_wdata(tw_wdata)"] + ([".tw_slot(tw_slot)"] if MTQ else [])
        conn += [".tw_dir(tw_dir)"] if (MTQ and core_meta.get("load_by_dir")) else []
    conn += [f".tw_s{c}({tpn[c]})" for c in range(NS)]
    conn += [f".x_in_{l}(x_in_{w['inWiring'][l]})" for l in range(n)]
    conn += [f".y_out_{l}(c_y_{l})" for l in range(n)]
    L.append(f"    {core} u_core (\n        " + ",\n        ".join(conn) + ");")
    for p in range(n):
        L.append(f"    assign y_out_{p} = c_y_{w['outWiring'][p]};")
    # valid: a delay line cleared by rst; the tag: a plain delay line (SRLs)
    if LAT:
        L.append(f"    logic [{LAT - 1}:0] v_sr;")
        L.append(f"    always_ff @(posedge clk) v_sr <= rst ? '0 : {{v_sr[{max(LAT - 2, 0)}:0], in_valid}};"
                 if LAT > 1 else "    always_ff @(posedge clk) v_sr <= rst ? '0 : in_valid;")
        L.append(f"    assign out_valid = v_sr[{LAT - 1}];")
        if TGW:
            tag = "{MIDX, DIR}" if (TD and PF) else ("MIDX" if PF else "DIR")
            L.append(f"    logic [{TGW - 1}:0] t_sr [{LAT}];")
            L.append(f"    always_ff @(posedge clk) begin t_sr[0] <= {tag}; "
                     f"for (int i = 1; i < {LAT}; i++) t_sr[i] <= t_sr[i-1]; end")
            if TD and PF:
                L.append(f"    assign midx_out = t_sr[{LAT - 1}][{TGW - 1}:1];")
                L.append(f"    assign dir_out = t_sr[{LAT - 1}][0];")
            elif PF:
                L.append(f"    assign midx_out = t_sr[{LAT - 1}];")
            else:
                L.append(f"    assign dir_out = t_sr[{LAT - 1}][0];")
    else:
        L.append("    assign out_valid = in_valid;")
        if PF:
            L.append("    assign midx_out = MIDX;")
        if TD:
            L.append("    assign dir_out = DIR;")
    L.append("endmodule")
    with open(os.path.join(rtl, f"{top}.sv"), "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")
    test = 0
    if tb is not None:
        cyc = tb["cycles"]
        test = len(cyc)
        tv = "testvectors"
        os.makedirs(tv, exist_ok=True)
        moduli = w["moduli"]
        with open(os.path.join(tv, "x_in.txt"), "w") as f:
            f.write("".join(_pack_per_slot(c["x"], [IW] * n) + "\n" for c in cyc))
        with open(os.path.join(tv, "y_out.txt"), "w") as f:
            f.write("".join(_pack_per_slot(c["y"] if c["y"] else [0] * n, [OW] * n) + "\n" for c in cyc))
        QW = sum(wd for _, wd in qports)
        if qports:                               # one q per job: the modulus ports per cycle, packed in port order
            with open(os.path.join(tv, "q_in.txt"), "w") as f:
                f.write("".join(_pack_per_slot([c["qv"][qp] for qp, _ in qports], [wd for _, wd in qports]) + "\n"
                                for c in cyc))
        if loadW:                                # the load port per cycle: rst | wen << 1 | data << 2
            with open(os.path.join(tv, "ld_in.txt"), "w") as f:
                f.write("".join(f"{(c['ld'][0] | (c['ld'][1] << 1) | (c['ld'][2] << 2)):x}\n" for c in cyc))
        if NS:
            with open(os.path.join(tv, "tw_in.txt"), "w") as f:
                f.write("".join(_pack_per_slot(c["tw"], [SW] * NS) + "\n" for c in cyc))
        with open(os.path.join(tv, "ctl.txt"), "w") as f:
            for c in cyc:
                v = c["v"] | ((1 if c["d"] == "inv" else 0) << 1) | ((moduli.index(c["q"]) if PF else 0) << 2)
                f.write(f"{v:x}\n")
        with open(os.path.join(rtl, f"{top}_tb.sv"), "w", encoding="utf-8") as f:
            f.write(_emit_tb(top, n, IW, OW, LAT, MB, DP, PF, test, sum(c["v"] for c in cyc), tpn[:NS], SW,
                             TD=TD, qports=qports, loadW=loadW, TWW=TWW))
    meta = dict(core_meta)
    meta.update(top_name=top, core_name=core, latency=LAT, interval=1, in_width=IW, out_width=OW,
                modulus_index_bits=MB, dir_port=DP, input_order=w["inputOrder"], output_order=w["outputOrder"],
                test_cycles=test)
    with open("manifest.json", "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)
    return meta


def _emit_tb(top, n, IW, OW, LAT, MB, DP, PF, test, nvalid, tpn=(), SW=0, TD=None, qports=(), loadW=0,
             TWW=0) -> str:
    XW, YW, CW = n * IW, n * OW, 2 + max(MB, 1)
    NS = len(tpn)
    TD = (DP and PF) if TD is None else TD
    QW = sum(wd for _, wd in qports)
    L = ["`timescale 1ns / 1ps", f"module {top}_tb ();", "    logic clk = 1'b0;", "    always #5 clk = ~clk;",
         "    logic rst, in_valid, out_valid;",
         f"    logic [{XW - 1}:0] x_ts [{test}]; logic [{YW - 1}:0] y_ts [{test}]; logic [{CW - 1}:0] c_ts [{test}];",
         f"    logic [{XW - 1}:0] xv; logic [{YW - 1}:0] yv;"]
    if PF:
        L.append(f"    logic [{MB - 1}:0] MIDX, midx_out;")
    if DP:
        L.append("    logic DIR;")
    if TD:
        L.append("    logic dir_out;")
    for i in range(n):
        L.append(f"    logic [{IW - 1}:0] x_in_{i}; logic [{OW - 1}:0] y_out_{i};")
        L.append(f"    assign x_in_{i} = xv[{(i + 1) * IW - 1}:{i * IW}];")
    L.append("    assign yv = {" + ", ".join(f"y_out_{k}" for k in reversed(range(n))) + "};")
    if qports:
        L.append(f"    logic [{QW - 1}:0] q_ts [{test}]; logic [{QW - 1}:0] qv;")
        off = 0
        for qp, wd in qports:
            L.append(f"    logic [{wd - 1}:0] {qp}; assign {qp} = qv[{off + wd - 1}:{off}];")
            off += wd
    if loadW:
        L.append(f"    logic [{TWW + 1}:0] ld_ts [{test}]; logic [{TWW + 1}:0] ldv;")
        L.append(f"    logic tw_rst, tw_wen; logic [{TWW - 1}:0] tw_wdata;")
        L.append(f"    assign tw_rst = ldv[0]; assign tw_wen = ldv[1]; assign tw_wdata = ldv[{TWW + 1}:2];")
    if NS:
        L.append(f"    logic [{NS * SW - 1}:0] tw_ts [{test}]; logic [{NS * SW - 1}:0] twv;")
        for c, nm in enumerate(tpn):
            L.append(f"    logic [{SW - 1}:0] {nm}; assign {nm} = twv[{(c + 1) * SW - 1}:{c * SW}];")
    L.append("    initial begin")
    L.append('        $readmemh("../../../../../testvectors/x_in.txt", x_ts);')
    L.append('        $readmemh("../../../../../testvectors/y_out.txt", y_ts);')
    L.append('        $readmemh("../../../../../testvectors/ctl.txt", c_ts);')
    if NS:
        L.append('        $readmemh("../../../../../testvectors/tw_in.txt", tw_ts);')
    if qports:
        L.append('        $readmemh("../../../../../testvectors/q_in.txt", q_ts);')
    if loadW:
        L.append('        $readmemh("../../../../../testvectors/ld_in.txt", ld_ts);')
    L.append("    end")
    conn = [".clk(clk)", ".rst(rst)", ".in_valid(in_valid)", ".out_valid(out_valid)"]
    if PF:
        conn += [".MIDX(MIDX)", ".midx_out(midx_out)"]
    if DP:
        conn.append(".DIR(DIR)")
    if TD:
        conn.append(".dir_out(dir_out)")
    conn += [f".{qp}({qp})" for qp, _ in qports]
    if loadW:
        conn += [".tw_rst(tw_rst)", ".tw_wen(tw_wen)", ".tw_wdata(tw_wdata)"]
    conn += [f".{nm}({nm})" for nm in tpn]
    conn += [f".x_in_{i}(x_in_{i})" for i in range(n)] + [f".y_out_{k}(y_out_{k})" for k in range(n)]
    L.append(f"    {top} DUT ({', '.join(conn)});")
    L.append("    int c, bad, checked, vbad, firstOut, lastOut;")
    L.append("    initial begin")
    L.append("        bad = 0; checked = 0; vbad = 0; firstOut = -1; lastOut = -1; rst = 1'b1; in_valid = 1'b0; xv = '0;")
    if NS:
        L.append("        twv = '0;")
    if qports:
        L.append("        qv = q_ts[0];")
    if loadW:
        L.append("        ldv = '0;")
    if PF:
        L.append("        MIDX = '0;")
    if DP:
        L.append("        DIR = 1'b0;")
    # past the global set/reset pulse (100 ns), during which the DSP58 models hold their registers
    L.append("        repeat (30) @(posedge clk);")
    L.append(f"        for (c = 0; c < {test + LAT}; c++) begin")
    L.append("            #1;")
    L.append("            rst = 1'b0;")
    L.append(f"            if (c < {test}) begin")
    L.append("                xv = x_ts[c]; in_valid = c_ts[c][0];")
    if NS:
        L.append("                twv = tw_ts[c];")
    if qports:
        L.append("                qv = q_ts[c];")
    if loadW:
        L.append("                ldv = ld_ts[c];")
    if DP:
        L.append("                DIR = c_ts[c][1];")
    if PF:
        L.append(f"                MIDX = c_ts[c][{MB + 1}:2];")
    L.append("            end else begin in_valid = 1'b0;" + (" ldv = '0;" if loadW else "") + " end")
    L.append("            #2;")
    # out_valid on every cycle: the input's valid LAT cycles earlier, 0 before
    L.append(f"            if (out_valid !== ((c >= {LAT}) ? c_ts[c - {LAT}][0] : 1'b0)) begin vbad++; "
             f"if (vbad < 10) $display(\"WRONG out_valid at cycle %0d: %b\", c, out_valid); end")
    L.append(f"            if (c >= {LAT} && c_ts[c - {LAT}][0]) begin")
    L.append(f"                if (yv !== y_ts[c - {LAT}]) begin bad++; "
             f"if (bad < 10) $display(\"WRONG transform at input cycle %0d: got %h want %h\", c - {LAT}, yv, y_ts[c - {LAT}]); end")
    if PF:
        L.append(f"                if (midx_out !== c_ts[c - {LAT}][{MB + 1}:2]) begin bad++; "
                 f"if (bad < 10) $display(\"WRONG midx_out at input cycle %0d\", c - {LAT}); end")
    if TD:
        L.append(f"                if (dir_out !== c_ts[c - {LAT}][1]) begin bad++; "
                 f"if (bad < 10) $display(\"WRONG dir_out at input cycle %0d\", c - {LAT}); end")
    L.append("                checked++; if (firstOut < 0) firstOut = c; lastOut = c;")
    L.append("            end")
    L.append("            @(posedge clk);")
    L.append("        end")
    # the rate: every valid input left exactly LAT cycles later, so the interval is the input's (1 per cycle)
    L.append(f"        $display(\"rate: %0d transforms checked, outputs on cycles %0d..%0d (%0d input cycles, "
             f"latency {LAT}, interval 1)\", checked, firstOut, lastOut, {test});")
    L.append(f"        if (bad == 0 && vbad == 0 && checked == {nvalid}) begin $display(\"SUCCESS!\"); "
             f"$display(\"PASS All %0d Testvectors!\", checked); end")
    L.append("        else begin $display(\"TO BE DEBUGGED...\"); "
             "$display(\"FAILED: %0d out of %0d testvectors failed (out_valid errors %0d)\", bad, checked, vbad); end")
    L.append("        $finish();")
    L.append("    end")
    L.append("endmodule")
    return "\n".join(L) + "\n"
