"""The slot manager of an NTT core with run-time moduli (2026-11-15).

A core with `loadableModuli` keeps its twiddle tables in K slots. Without a manager the outside names the slot of
each polynomial (MIDX) and drives the loader itself: that is the mode in which every modulus is loaded once and
stays. With the manager the slots rotate:

  * the outside ANNOUNCES the key of every coming polynomial (`ann_valid`, `ann_key`: a modulus identifier of its
    own choice), one announcement per polynomial, in order, early enough (the lead time of the design);
  * a key that sits in a slot is reused (a hit); otherwise the manager takes a free slot, the one unused the
    longest, and REQUESTS the load (`ld_req` with `ld_key`): the outside answers with the load words of that key
    on the core's load port, WORDS cycles in a row;
  * when a polynomial starts, the manager hands the core its slot (MIDX);
  * `slot_err` rises and stays when the timing was broken: no free slot, a polynomial whose slot is not loaded in
    time, a polynomial that was not announced (strict cores), or a load with a gap.

The two timing numbers come from the generator (`slotTiming`): a slot may be loaded `AFTER` cycles after the first
beat of its last polynomial, and its next polynomial may start `BEFORE` cycles after the first load word. With
K >= ceil((AFTER + lead) / frame) + 1 a free slot always exists, whatever the sequence of moduli, so the pipeline
never waits.
"""
from __future__ import annotations

import os


def clog2(x: int) -> int:
    return max(1, (x - 1).bit_length())


#: cycles from an announcement to the manager's decision at the most (queue of one, latch, the comparison tree
#: for up to 32 slots, apply); part of the lead time of an announcement
DECIDE = 8


def emit_slot_manager(name: str, K: int, KW: int, after: int, before: int, words: int, fifo: int = 16,
                      strict: bool = True, ahead: int = 0) -> str:
    """`<name>`: the manager for K slots and keys of KW bits. `words`: cycles of one load. `fifo`: announcements
    that may wait (a power of two). `strict`: a polynomial that was not announced is an error (cores with a valid
    input); else it is an idle frame.

    Timing (2026-11-16): nothing is decided in the cycle of the announcement. Announcements wait in a queue of
    four; one at a time is latched with a registered hit flag and free flag per slot, the oldest free slot is found
    by a comparison tree with one register level per round, and the decision is applied from registers. The
    slot of the next polynomial is kept in a register (`head_q`). An announcement is decided at most DECIDE cycles
    after it arrives when announcements are at least that far apart."""
    if K > 32:
        raise ValueError(f'{name}: the slot manager is built for at most 32 slots')
    KB = clog2(K)
    CB = max(after, before, words).bit_length() + 1
    FB = clog2(fifo)
    AGB = 20
    LV = (K - 1).bit_length()               # rounds of the comparison tree
    NP = 1 << LV
    AP = max(LV, 1)                         # the decision is applied when dcnt == AP
    T = []
    # the comparison tree: level 0 is the latched (free, score, index) per slot, padded with never-free entries
    T.append(f"    logic t0_f [{NP}]; logic [{AGB}:0] t0_s [{NP}]; logic [{KB - 1}:0] t0_i [{NP}];")
    for i in range(NP):
        if i < K:
            T.append(f"    assign t0_f[{i}] = freev[{i}]; assign t0_s[{i}] = sc[{i}]; assign t0_i[{i}] = {KB}'d{i};")
        else:
            T.append(f"    assign t0_f[{i}] = 1'b0; assign t0_s[{i}] = '0; assign t0_i[{i}] = '0;")
    for l in range(1, LV + 1):
        n = NP >> l
        T.append(f"    logic t{l}_f [{n}]; logic [{AGB}:0] t{l}_s [{n}]; logic [{KB - 1}:0] t{l}_i [{n}];")
        T.append("    always_ff @(posedge clk) begin")
        for i in range(n):
            a_, b_ = 2 * i, 2 * i + 1
            # the left entry wins unless only the right one is free, or both are and the right one is older
            T.append(f"        if (t{l - 1}_f[{b_}] && (!t{l - 1}_f[{a_}] || t{l - 1}_s[{b_}] > t{l - 1}_s[{a_}])) begin "
                     f"t{l}_f[{i}] <= 1'b1; t{l}_s[{i}] <= t{l - 1}_s[{b_}]; t{l}_i[{i}] <= t{l - 1}_i[{b_}]; end")
            T.append(f"        else begin t{l}_f[{i}] <= t{l - 1}_f[{a_}]; t{l}_s[{i}] <= t{l - 1}_s[{a_}]; "
                     f"t{l}_i[{i}] <= t{l - 1}_i[{a_}]; end")
        T.append("    end")
    tree = "\n".join(T)
    hitenc = "\n".join(f"            if (hitv[{i}]) hit_i <= {KB}'d{i};" for i in reversed(range(K)))
    # ahead >= 1 (cores without a valid input, where every frame boundary is a possible start): an announcement is
    # for the polynomial at the `ahead`-th frame boundary after the cycle it arrives in, so it may be more than one
    # frame early. Each announcement carries the number of that boundary through the queues.
    if ahead:
        st_decl = (f"    // --- the frame an announcement is for: the boundary number {ahead} after its arrival\n"
                   f"    logic [7:0] fbc, fbn; assign fbn = fbc + 8'(poly_start);\n"
                   f"    logic [7:0] aq_d [4]; logic [7:0] d_due; logic [7:0] of_d [{fifo}]; logic [7:0] head_due;\n"
                   f"    logic [7:0] due_gap; assign due_gap = fbc + 8'd1 - head_due;\n"
                   f"    logic due_ok; assign due_ok = !due_gap[7];\n")
        take_x = "poly_start && !of_empty && due_ok"
        st_rst = " fbc <= '0; d_due <= '0; head_due <= '0;"
        st_cnt = "            fbc <= fbn;\n"
        st_ann = f"\n                    aq_d[aq_w[1:0]] <= fbn + 8'd{ahead};"
        st_lat = " d_due <= aq_d[aq_r[1:0]];"
        st_push = f"\n                        of_d[of_w[{FB - 1}:0]] <= d_due;"
        st_head = (f"\n            head_due <= (push && of_w[{FB - 1}:0] == of_r_n[{FB - 1}:0]) ? d_due : "
                   f"of_d[of_r_n[{FB - 1}:0]];")
    else:
        st_decl, take_x, st_rst, st_cnt, st_ann, st_lat, st_push, st_head = "", "poly_start && !of_empty", "", "", "", "", "", ""
    return f"""`timescale 1ns / 1ps
// {name}: slot manager, {K} slots, keys of {KW} bits. A slot may be loaded {after} cycles after the first beat of its
// last polynomial; its next polynomial may start {before} cycles after the first load word; a load is {words} cycles.
// The decision on an announcement is pipelined (queue, latch, {LV} comparison round(s), apply).
module {name} (
    input  logic clk,
    input  logic rst,
    input  logic ann_valid,                 // the key of the next polynomial that was not announced yet
    input  logic [{KW - 1}:0] ann_key,
    input  logic poly_start,                // the first beat of a polynomial is at the core in this cycle
    output logic [{KB - 1}:0] midx,              // its slot (valid with poly_start, held after)
    output logic ld_req,                    // one cycle: send the load of ld_key
    output logic [{KW - 1}:0] ld_key,
    input  logic ld_wen,                    // a load word is on the core's load port
    output logic tw_rst,                    // to the core's loader: a load of slot tw_slot starts
    output logic [{KB - 1}:0] tw_slot,
    output logic slot_err,                  // sticky
    output logic [2:0] err_code             // 1 no free slot, 2 polynomial not announced, 3 slot not ready, 4 gap in a load, 5 queue full
    );
    localparam int K = {K};
    logic [{KW - 1}:0] key [K];
    logic valid [K];
    logic [{CB - 1}:0] busy [K];             // cycles until the slot may be loaded again
    logic [{CB - 1}:0] ready [K];            // cycles until the slot may be used (after its load started)
    logic rwait [K];                         // its load has not started yet
    logic [4:0] pend [K];                    // announced polynomials of the slot that have not started
    logic [{AGB - 1}:0] age [K];             // cycles since its last polynomial started

    // --- the announcements that wait -----------------------------------------------------------------------
    logic [{KW - 1}:0] aq_k [4];
    logic [2:0] aq_w, aq_r;
    logic aq_empty, aq_full;
    assign aq_empty = (aq_w == aq_r);
    assign aq_full = (aq_w[1:0] == aq_r[1:0]) && (aq_w[2] != aq_r[2]);
    logic [{KW - 1}:0] aq_head;
    assign aq_head = aq_k[aq_r[1:0]];

    // --- one decision at a time: latch, compare, apply ---------------------------------------------------------
    logic dbusy;
    logic [3:0] dcnt;
    logic [{KW - 1}:0] d_key;
    logic [K - 1:0] hitv, freev;
    logic [{AGB}:0] sc [K];                  // never used first, then the longest unused
    logic hit; logic [{KB - 1}:0] hit_i;
{tree}
    logic apply, a_go, a_miss;
    logic [{KB - 1}:0] a_slot;
    assign apply = dbusy && (dcnt == 4'd{AP});
    assign a_slot = hit ? hit_i : t{LV}_i[0];
    assign a_miss = apply && !hit && t{LV}_f[0];
    assign a_go = apply && (hit || t{LV}_f[0]);

    // --- the order of the announced polynomials ---------------------------------------------------------------
    logic [{KB - 1}:0] of [{fifo}];
    logic [{FB}:0] of_w, of_r, of_r_n;
    logic of_empty, of_full;
    assign of_empty = (of_w == of_r);
    assign of_full = (of_w[{FB - 1}:0] == of_r[{FB - 1}:0]) && (of_w[{FB}] != of_r[{FB}]);
    logic [{KB - 1}:0] head_q, midx_r;       // head_q: the slot of the next polynomial, in a register
{st_decl}    logic take, push;
    assign take = {take_x};
    assign of_r_n = of_r + {FB + 1}'(take);
    assign midx = take ? head_q : midx_r;

    // --- the loads that wait, and the loader ----------------------------------------------------------------------
    logic [{KB - 1}:0] lq_s [4];
    logic [{KW - 1}:0] lq_k [4];
    logic [2:0] lq_w, lq_r;
    logic lq_empty, lq_full;
    assign lq_empty = (lq_w == lq_r);
    assign lq_full = (lq_w[1:0] == lq_r[1:0]) && (lq_w[2] != lq_r[2]);
    assign push = a_go && !of_full && !(a_miss && lq_full);
    logic running, started;
    logic nxt_valid;                         // the next load was requested while this one runs (back to back)
    logic [{KB - 1}:0] nxt_slot;
    logic [{KB - 1}:0] cur;
    logic [{CB - 1}:0] wcnt;
    logic first_word, last_word;
    assign first_word = running && !started && ld_wen;
    assign last_word = running && ld_wen && (wcnt == {CB}'d{words - 1});
    logic nrdy [K];
    always_comb for (int i = 0; i < K; i++) nrdy[i] = (ready[i] != '0) || rwait[i];

    always_ff @(posedge clk) begin
        ld_req <= 1'b0;
        tw_rst <= 1'b0;
        if (rst) begin
            of_w <= '0; of_r <= '0; lq_w <= '0; lq_r <= '0; running <= 1'b0; started <= 1'b0; wcnt <= '0;
            nxt_valid <= 1'b0; nxt_slot <= '0; aq_w <= '0; aq_r <= '0; dbusy <= 1'b0; dcnt <= '0; d_key <= '0;
            hitv <= '0; freev <= '0; hit <= 1'b0; hit_i <= '0; head_q <= '0;
            slot_err <= 1'b0; err_code <= '0; midx_r <= '0; cur <= '0; tw_slot <= '0; ld_key <= '0;
            for (int i = 0; i < K; i++) begin
                valid[i] <= 1'b0; busy[i] <= '0; ready[i] <= '0; rwait[i] <= 1'b0; pend[i] <= '0; age[i] <= '0;
                key[i] <= '0; sc[i] <= '0;
            end{st_rst}
        end else begin
{st_cnt}            // every slot: its counters, with at most one decision and one start in a cycle
            for (int i = 0; i < K; i++) begin
                if (take && head_q == {KB}'(i)) begin
                    busy[i] <= {CB}'d{after};
                    age[i] <= '0;
                end else begin
                    if (busy[i] != '0) busy[i] <= busy[i] - 1'b1;
                    if (!(&age[i])) age[i] <= age[i] + 1'b1;
                end
                if (first_word && cur == {KB}'(i)) begin
                    ready[i] <= {CB}'d{max(before - 1, 0)};
                    rwait[i] <= 1'b0;
                end else if (ready[i] != '0) ready[i] <= ready[i] - 1'b1;
                pend[i] <= pend[i] + 5'((push && a_slot == {KB}'(i)) ? 1 : 0)
                                   - 5'((take && head_q == {KB}'(i)) ? 1 : 0);
                if (push && a_miss && a_slot == {KB}'(i)) begin
                    key[i] <= d_key;
                    valid[i] <= 1'b1;
                    rwait[i] <= 1'b1;
                end
            end
            // an announcement arrives
            if (ann_valid) begin
                if (aq_full) begin
                    if (!slot_err) begin slot_err <= 1'b1; err_code <= 3'd5; end
                end else begin
                    aq_k[aq_w[1:0]] <= ann_key;{st_ann}
                    aq_w <= aq_w + 1'b1;
                end
            end
            // the decision: latch (hit and free flags from the registers of this cycle), compare, apply
            if (!dbusy) begin
                if (!aq_empty) begin
                    dbusy <= 1'b1; dcnt <= '0; d_key <= aq_head; aq_r <= aq_r + 1'b1;{st_lat}
                    for (int i = 0; i < K; i++) begin
                        hitv[i] <= valid[i] && key[i] == aq_head;
                        // free: never used, or idle long enough with nothing announced and no load under way
                        freev[i] <= !valid[i] || (busy[i] == '0 && pend[i] == '0 && ready[i] == '0 && !rwait[i]);
                        sc[i] <= !valid[i] ? {{1'b1, {AGB}'d0}} : {{1'b0, age[i]}};
                    end
                end
            end else begin
                dcnt <= dcnt + 1'b1;
                if (dcnt == 4'd0) begin
                    hit <= |hitv;
                    hit_i <= '0;
{hitenc}
                end
                if (apply) begin
                    dbusy <= 1'b0;
                    if (!hit && !t{LV}_f[0]) begin
                        if (!slot_err) begin slot_err <= 1'b1; err_code <= 3'd1; end
                    end else if (of_full || (a_miss && lq_full)) begin
                        if (!slot_err) begin slot_err <= 1'b1; err_code <= 3'd5; end
                    end else begin
                        of[of_w[{FB - 1}:0]] <= a_slot;{st_push}
                        of_w <= of_w + 1'b1;
                        if (a_miss) begin
                            lq_s[lq_w[1:0]] <= a_slot;
                            lq_k[lq_w[1:0]] <= d_key;
                            lq_w <= lq_w + 1'b1;
                        end
                    end
                end
            end
            // the slot of the next polynomial, kept in a register
            head_q <= (push && of_w[{FB - 1}:0] == of_r_n[{FB - 1}:0]) ? a_slot : of[of_r_n[{FB - 1}:0]];{st_head}
            // a polynomial starts
            if (poly_start) begin
                if (!take) begin
                    if ({1 if strict else 0} && !slot_err) begin slot_err <= 1'b1; err_code <= 3'd2; end
                end else begin
                    of_r <= of_r + 1'b1;
                    midx_r <= head_q;
                    if (nrdy[head_q] && !slot_err) begin slot_err <= 1'b1; err_code <= 3'd3; end
                end
            end
            // the loader: one load at a time, the words in consecutive cycles
            if (!running) begin
                if (!lq_empty) begin
                    running <= 1'b1; started <= 1'b0; wcnt <= '0;
                    cur <= lq_s[lq_r[1:0]];
                    tw_slot <= lq_s[lq_r[1:0]];
                    ld_key <= lq_k[lq_r[1:0]];
                    tw_rst <= 1'b1;
                    ld_req <= 1'b1;
                    lq_r <= lq_r + 1'b1;
                end
            end else begin
                // a load that waits is requested while this one runs: its words may follow the last word of
                // this load with no idle cycle (tw_rst goes with that last word), so a load may be as long as
                // a frame
                if ({1 if words >= 8 else 0} && !nxt_valid && !lq_empty && wcnt <= {CB}'d{max(words - 3, 0)}) begin
                    nxt_valid <= 1'b1;
                    nxt_slot <= lq_s[lq_r[1:0]];
                    ld_key <= lq_k[lq_r[1:0]];
                    ld_req <= 1'b1;
                    lq_r <= lq_r + 1'b1;
                end
                if (ld_wen) begin
                    started <= 1'b1;
                    wcnt <= wcnt + 1'b1;
                    if (nxt_valid && wcnt == {CB}'d{max(words - 2, 0)}) begin
                        tw_rst <= 1'b1;
                        tw_slot <= nxt_slot;
                    end
                    if (last_word) begin
                        if (nxt_valid) begin
                            started <= 1'b0; wcnt <= '0; cur <= nxt_slot; nxt_valid <= 1'b0;
                        end else running <= 1'b0;
                    end
                end else if (started && !slot_err) begin
                    slot_err <= 1'b1; err_code <= 3'd4;
                end
            end
        end
    end
endmodule
"""


def slots_needed(after: int, lead: int, frame: int) -> int:
    """Slots for any sequence of moduli: the polynomials that started in the last `after` cycles pin their slots,
    the ones announced in the last `lead` cycles pin theirs, and one more is free."""
    return -(-after // frame) + -(-lead // frame) + 1


def lead_cycles(before: int, words: int, respond: int = 4) -> int:
    """How long before its first beat a polynomial must be announced: the load request goes out (2 cycles), the
    outside answers within `respond` cycles, and the polynomial may start `before` cycles after the first word.
    A load that had to wait for the one in front starts at most 4 cycles later (it is requested while that one
    runs and follows it with no idle cycle), as long as a load is no longer than a frame. The manager decides
    at most DECIDE cycles after the announcement."""
    return before + respond + 8 + DECIDE


def emit_managed_stream_top(top: str, core: str, core_sv: str, mgr: str, F: int, KW: int) -> str:
    """`<top>`: the dataflow core `<core>` with its slot manager. Every core port passes through, except MIDX,
    tw_rst and tw_slot, which the manager drives. Adds ann_valid, ann_key, ld_req, ld_key, slot_err, err_code."""
    from rtl_gen.hweval import parse_module_ports
    cp = parse_module_ports(core_sv, core)
    inner = {'MIDX', 'tw_rst', 'tw_slot', 'tw_dir'}      # tw_dir (load by direction): the lowest bit of the key
    kb = next(p.width for p in cp if p.name == 'MIDX')
    ports = []
    for p in cp:
        if p.name in inner:
            continue
        ports.append(f"    {p.direction} logic {f'[{p.width - 1}:0] ' if p.width > 1 else ''}{p.name}")
    ports += ["    input  logic ann_valid", f"    input  logic [{KW - 1}:0] ann_key", "    output logic ld_req",
              f"    output logic [{KW - 1}:0] ld_key", "    output logic slot_err", "    output logic [2:0] err_code"]
    FB = (F - 1).bit_length() if F > 1 else 0
    L = ["`timescale 1ns / 1ps", f"// {top}: {core} with its slot manager (run-time moduli, slots that rotate)",
         f"module {top} (\n" + ",\n".join(ports) + "\n    );"]
    if FB:
        L.append(f"    logic [{FB - 1}:0] cnt;")
        L.append("    always_ff @(posedge clk) cnt <= rst ? '0 : cnt + 1'b1;     // the core's own frame counter")
        L.append(f"    logic ps; assign ps = !rst && (cnt == {FB}'d0);")
    else:
        L.append("    logic ps; assign ps = !rst;")
    L.append(f"    logic [{kb - 1}:0] m_idx, m_slot; logic m_rst;")
    L.append(f"    {mgr} mgr (.clk(clk), .rst(rst), .ann_valid(ann_valid), .ann_key(ann_key), .poly_start(ps), "
             f".midx(m_idx), .ld_req(ld_req), .ld_key(ld_key), .ld_wen(tw_wen), .tw_rst(m_rst), .tw_slot(m_slot), "
             f".slot_err(slot_err), .err_code(err_code));")
    conn = []
    for p in cp:
        sig = {'MIDX': 'm_idx', 'tw_rst': 'm_rst', 'tw_slot': 'm_slot', 'tw_dir': 'ld_key[0]'}.get(p.name, p.name)
        conn.append(f".{p.name}({sig})")
    L.append(f"    {core} core (" + ", ".join(conn) + ");")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def emit_managed_stream_tb(top: str, spec, tb: dict, TWW: int, KW: int) -> str:
    """Testbench of a managed dataflow top. `tb`: 'pre' idle frames in front, 'keys' (one per frame, -1: idle),
    'lead' (cycles an announcement is ahead), 'imageOf' {key: index into the load file}, 'mq' (constants per frame),
    'dirs'. The load is REACTIVE: the testbench answers ld_req with the words of ld_key. Every output beat of the
    real frames is checked for value and cycle, and slot_err must stay low."""
    P, LAT, F = spec.lanes, spec.latency, spec.frameCycles
    qports = spec.roms["qPorts"]
    loadW = spec.roms["loadWords"]
    NF = len(tb["keys"])
    test = NF * F
    PRE = tb["pre"] * F
    nimg = len(tb["imageOf"])
    L = ["`timescale 1ns / 1ps", f"module {top}_tb ();", "    logic clk = 1'b0;", "    always #5 clk = ~clk;",
         "    logic rst;"]
    if spec.dirPort:
        L.append(f"    logic DIR; logic di_ts [{NF}];")
    for qp, w in qports:
        L.append(f"    logic [{w - 1}:0] mq_{qp}; logic [{w - 1}:0] mq_{qp}_ts [{NF}];")
    L.append("    initial begin")
    for f_, vals in enumerate(tb["mq"]):
        L.append("        " + " ".join(f"mq_{qp}_ts[{f_}] = {w}'h{vals[qp]:x};" for qp, w in qports))
    L.append("    end")
    L.append(f"    logic tw_wen = 1'b0; logic [{TWW - 1}:0] tw_wdata = '0; logic [{TWW - 1}:0] tw_ts [{loadW * nimg}];")
    L.append(f"    logic ann_valid = 1'b0; logic [{KW - 1}:0] ann_key = '0; logic ld_req; logic [{KW - 1}:0] ld_key;")
    L.append("    logic slot_err; logic [2:0] err_code;")
    for l in range(P):
        L.append(f"    logic [{spec.inWidth - 1}:0] x_in_{l}; logic [{spec.inWidth - 1}:0] x_ts_{l} [{test}];")
        L.append(f"    logic [{spec.outWidth - 1}:0] y_out_{l}; logic [{spec.outWidth - 1}:0] y_ts_{l} [{test}];")
    L.append("    initial begin")
    for l in range(P):
        L.append(f'        $readmemh("../../../../../testvectors/x_{l}.txt", x_ts_{l});')
        L.append(f'        $readmemh("../../../../../testvectors/y_{l}.txt", y_ts_{l});')
    L.append('        $readmemh("../../../../../testvectors/tw_load.txt", tw_ts);')
    if spec.dirPort:
        L.append('        $readmemh("../../../../../testvectors/dir.txt", di_ts);')
    L.append("    end")
    conn = [".clk(clk)", ".rst(rst)"] + ([".DIR(DIR)"] if spec.dirPort else [])
    conn += [f".mq_{qp}(mq_{qp})" for qp, _ in qports]
    conn += [".tw_wen(tw_wen)", ".tw_wdata(tw_wdata)", ".ann_valid(ann_valid)", ".ann_key(ann_key)", ".ld_req(ld_req)",
             ".ld_key(ld_key)", ".slot_err(slot_err)", ".err_code(err_code)"]
    conn += [f".x_in_{l}(x_in_{l})" for l in range(P)] + [f".y_out_{l}(y_out_{l})" for l in range(P)]
    L.append(f"    {top} DUT ({', '.join(conn)});")
    # the load, on request: the image of the key that the manager asks for, WORDS cycles in a row
    L.append("    int li, lbase, qbase, loads = 0;")
    L.append("    logic lrun = 1'b0, lpend = 1'b0;")
    L.append("    always @(posedge clk) begin")
    L.append("        #1;")
    L.append(f"        if (lrun && li >= {loadW}) lrun = 1'b0;")
    L.append("        if (!lrun && lpend) begin lbase = qbase; li = 0; lrun = 1'b1; lpend = 1'b0; end")
    L.append("        if (lrun) begin tw_wen = 1'b1; tw_wdata = tw_ts[lbase + li]; li = li + 1; end")
    L.append("        else tw_wen = 1'b0;")
    L.append("        if (ld_req) begin")
    L.append("            if (lpend) begin $display(\"TB: FAIL two load requests wait\"); $finish; end")
    L.append("            case (ld_key)")
    for k, im in sorted(tb["imageOf"].items()):
        L.append(f"                {KW}'d{k}: qbase = {im * loadW};")
    L.append("                default: begin $display(\"TB: load of an unknown key %0d\", ld_key); qbase = 0; end")
    L.append("            endcase")
    L.append("            lpend = 1'b1; loads = loads + 1;")
    L.append("        end")
    L.append("    end")
    L.append("    int c, bad, checked;")
    L.append("    initial begin")
    L.append("        bad = 0; checked = 0; rst = 1'b1;")
    for l in range(P):
        L.append(f"        x_in_{l} = '0;")
    if spec.dirPort:
        L.append("        DIR = 1'b0;")
    L += [f"        mq_{qp} = '0;" for qp, _ in qports]
    L.append("        repeat (30) @(posedge clk);       // past the global set/reset pulse of the DSP58 models")
    L.append(f"        for (c = 0; c < {test + LAT}; c++) begin")
    L.append("            #1;")
    L.append("            rst = 1'b0;")
    L.append("            ann_valid = 1'b0;")
    for f_, k in enumerate(tb["keys"]):
        if k >= 0:
            L.append(f"            if (c == {f_ * F - tb['lead']}) begin ann_valid = 1'b1; ann_key = {KW}'d{k}; end")
    L.append(f"            if (c < {test}) begin")
    for l in range(P):
        L.append(f"                x_in_{l} = x_ts_{l}[c];")
    if spec.dirPort:
        L.append(f"                DIR = di_ts[c / {F}];")
    L += [f"                mq_{qp} = mq_{qp}_ts[c / {F}];" for qp, _ in qports]
    L.append("            end")
    L.append(f"            if (c >= {LAT + PRE}) begin")
    L.append("                #2;")
    for l in range(P):
        L.append(f"                if (y_out_{l} !== y_ts_{l}[c - {LAT}]) begin bad++; "
                 f"if (bad < 10) $display(\"WRONG cycle %0d lane {l}: got %h want %h\", c - {LAT}, y_out_{l}, y_ts_{l}[c - {LAT}]); end")
    L.append("                checked++;")
    L.append("            end")
    L.append("            if (slot_err) begin bad++; if (bad < 10) $display(\"SLOT ERROR code %0d at cycle %0d\", err_code, c); end")
    L.append("            @(posedge clk);")
    L.append("        end")
    L.append("        $display(\"managed run: %0d loads on request\", loads);")
    L.append("        if (bad == 0) begin $display(\"SUCCESS!\"); $display(\"PASS All %0d Testvectors!\", checked); end")
    L.append("        else begin $display(\"TO BE DEBUGGED...\"); $display(\"FAILED: %0d lane values wrong\", bad); end")
    L.append("        $finish();")
    L.append("    end")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def emit_managed_multistep_top(top: str, core: str, core_sv: str, mgr: str, F: int, KW: int) -> str:
    """`<top>`: the multi-step core `<core>` with its slot manager. Every core port passes through, except MIDX,
    ld_rst and ld_slot, which the manager drives. A polynomial starts on the first of every F valid beats.
    Adds ann_valid, ann_key, ld_req, ld_key, slot_err, err_code."""
    from rtl_gen.hweval import parse_module_ports
    cp = parse_module_ports(core_sv, core)
    inner = {'MIDX', 'ld_rst', 'ld_slot', 'ld_dir'}      # ld_dir (load by direction): the lowest bit of the key
    kb = next(p.width for p in cp if p.name == 'MIDX')
    ports = [f"    {p.direction} logic {f'[{p.width - 1}:0] ' if p.width > 1 else ''}{p.name}" for p in cp
             if p.name not in inner]
    ports += ["    input  logic ann_valid", f"    input  logic [{KW - 1}:0] ann_key", "    output logic ld_req",
              f"    output logic [{KW - 1}:0] ld_key", "    output logic slot_err", "    output logic [2:0] err_code"]
    FB = max(1, (F - 1).bit_length())
    L = ["`timescale 1ns / 1ps", f"// {top}: {core} with its slot manager (run-time moduli, slots that rotate)",
         f"module {top} (\n" + ",\n".join(ports) + "\n    );",
         f"    logic [{FB - 1}:0] bc;                  // the beat of the polynomial at the input",
         f"    always_ff @(posedge clk) bc <= rst ? '0 : (in_valid ? ((bc == {FB}'d{F - 1}) ? '0 : bc + 1'b1) : bc);",
         f"    logic ps; assign ps = in_valid && (bc == {FB}'d0);",
         f"    logic [{kb - 1}:0] m_idx, m_slot; logic m_rst;",
         f"    {mgr} mgr (.clk(clk), .rst(rst), .ann_valid(ann_valid), .ann_key(ann_key), .poly_start(ps), "
         f".midx(m_idx), .ld_req(ld_req), .ld_key(ld_key), .ld_wen(ld_wen), .tw_rst(m_rst), .tw_slot(m_slot), "
         f".slot_err(slot_err), .err_code(err_code));"]
    conn = [f".{p.name}({ {'MIDX': 'm_idx', 'ld_rst': 'm_rst', 'ld_slot': 'm_slot', 'ld_dir': 'ld_key[0]'}.get(p.name, p.name) })" for p in cp]
    L.append(f"    {core} core (" + ", ".join(conn) + ");")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def emit_managed_multistep_tb(top: str, spec: dict, tb: dict, KW: int) -> str:
    """Testbench of a managed multi-step top, on the vector files of the core's generator (x_in, y_out, ctl_in,
    ctl_out, qid_in) plus ann_in.txt (valid | key << 1 per cycle) and ldimg.txt (the load of each key). The load is
    REACTIVE: ld_req is answered with the words of ld_key. Checks out_valid and every output beat on its cycle, and
    that slot_err stays low."""
    P, W, IW, DP, LAT = spec["P"], spec["W"], spec["IW"], spec["dirPort"], spec["latency"]
    cyc, exp = tb["cycles"], tb["expect"]
    T, E = len(cyc), len(exp)
    CW = 2 + max(IW, 1)
    MT, LD = spec["mtLoad"], spec["load"]
    LDW, WORDS = LD["ldw"], LD["words"]
    nimg = len(tb["imageOf"])
    nval = sum(c["v"] for c in cyc)
    NQ = len(tb["mqTable"])
    QB = max(1, (NQ - 1).bit_length())
    L = ["`timescale 1ns / 1ps", f"module {top}_tb;", "    logic clk = 0; always #1 clk = ~clk;", "    logic rst = 1;",
         "    logic in_valid = 0; logic out_valid;"]
    if DP:
        L.append("    logic DIR = 0; logic dir_out;")
    L.append(f"    logic [{QB - 1}:0] qid = '0; logic [{QB - 1}:0] qi [0:{T - 1}];")
    L.append('    initial $readmemh("../testvectors/qid_in.txt", qi);')
    for p_, w_ in MT["ports"]:
        L.append(f"    logic [{w_ - 1}:0] mq_{p_}_tab [0:{NQ - 1}]; logic [{w_ - 1}:0] mq_{p_};")
        L.append("    initial begin " + " ".join(f"mq_{p_}_tab[{i_}] = {w_}'h{v_.get(p_, 0):x};" for i_, v_ in enumerate(tb["mqTable"])) + " end")
        L.append(f"    assign mq_{p_} = mq_{p_}_tab[qid];")
    L.append(f"    logic ld_wen = 0; logic [{LDW - 1}:0] ld_wdata = '0; logic [{LDW - 1}:0] ldm [0:{WORDS * nimg - 1}];")
    L.append(f"    logic ann_valid = 0; logic [{KW - 1}:0] ann_key = '0; logic [{KW}:0] am [0:{T - 1}];")
    L.append(f"    logic ld_req; logic [{KW - 1}:0] ld_key; logic slot_err; logic [2:0] err_code;")
    L.append(f"    logic [{W - 1}:0] x [0:{P - 1}]; logic [{W - 1}:0] y [0:{P - 1}];")
    L.append(f"    logic [{P * W - 1}:0] xm [0:{T - 1}]; logic [{P * W - 1}:0] ym [0:{E - 1}];")
    L.append(f"    logic [{CW - 1}:0] ci [0:{T - 1}]; logic [{CW - 1}:0] co [0:{E - 1}];")
    L.append('    initial begin $readmemh("../testvectors/x_in.txt", xm); $readmemh("../testvectors/y_out.txt", ym); '
             '$readmemh("../testvectors/ctl_in.txt", ci); $readmemh("../testvectors/ctl_out.txt", co); '
             '$readmemh("../testvectors/ann_in.txt", am); $readmemh("../testvectors/ldimg.txt", ldm); end')
    conn = [".clk(clk)", ".rst(rst)", ".in_valid(in_valid)", ".out_valid(out_valid)"]
    if DP:
        conn += [".DIR(DIR)", ".dir_out(dir_out)"]
    conn += [f".mq_{p_}(mq_{p_})" for p_, _ in MT["ports"]]
    conn += [".ld_wen(ld_wen)", ".ld_wdata(ld_wdata)", ".ann_valid(ann_valid)", ".ann_key(ann_key)", ".ld_req(ld_req)",
             ".ld_key(ld_key)", ".slot_err(slot_err)", ".err_code(err_code)"]
    conn += [f".x_in_{l}(x[{l}])" for l in range(P)] + [f".y_out_{l}(y[{l}])" for l in range(P)]
    L.append(f"    {top} dut (" + ", ".join(conn) + ");")
    L.append("    integer m = 0, l, errs = 0, outs = 0, first_in = -1, last_in = -1, first_out = -1, last_out = -1;")
    L.append("    integer li = 0, lbase = 0, qbase = 0, loads = 0; logic lrun = 0, lpend = 0; logic started = 0;")
    L.append("    initial begin")
    L.append(f"        for (l = 0; l < {P}; l++) x[l] = '0;")
    L.append("        repeat (80) @(posedge clk);   // past the 100 ns global set/reset of the DSP58 models (2 ns clock)")
    L.append("        rst <= 0; @(posedge clk); started <= 1;")
    L.append("    end")
    L.append("    always @(posedge clk) if (started) begin")
    L.append("        #0.1;")
    # the load, on request
    L.append(f"        if (lrun && li >= {WORDS}) lrun = 0;")
    L.append("        if (!lrun && lpend) begin lbase = qbase; li = 0; lrun = 1; lpend = 0; end")
    L.append("        if (lrun) begin ld_wen = 1; ld_wdata = ldm[lbase + li]; li = li + 1; end")
    L.append("        else ld_wen = 0;")
    L.append("        if (ld_req) begin")
    L.append("            if (lpend) begin $display(\"[tb] two load requests wait\"); errs++; end")
    L.append("            case (ld_key)")
    for k, im in sorted(tb["imageOf"].items()):
        L.append(f"                {KW}'d{k}: qbase = {im * WORDS};")
    L.append("                default: begin $display(\"[tb] load of an unknown key %0d\", ld_key); qbase = 0; end")
    L.append("            endcase")
    L.append("            lpend = 1; loads = loads + 1;")
    L.append("        end")
    L.append("        if (slot_err) begin errs++; if (errs < 10) $display(\"[tb] cycle %0d: slot error code %0d\", m, err_code); end")
    L.append(f"        if (m < {E}) begin")
    L.append("            if (out_valid !== co[m][0]) begin errs++; if (errs < 10) "
             "$display(\"[tb] cycle %0d: out_valid %b, expected %b\", m, out_valid, co[m][0]); end")
    L.append("            else if (out_valid) begin")
    L.append("                outs++; if (first_out < 0) first_out = m; last_out = m;")
    L.append(f"                for (l = 0; l < {P}; l++) if (y[l] !== ym[m][l*{W} +: {W}]) begin errs++; if (errs < 10) "
             f"$display(\"[tb] cycle %0d lane %0d: %h, expected %h\", m, l, y[l], ym[m][l*{W} +: {W}]); end")
    if DP:
        L.append("                if (dir_out !== co[m][1]) begin errs++; if (errs < 10) $display(\"[tb] cycle %0d: dir_out %b\", m, dir_out); end")
    L.append("            end")
    L.append(f"            if (m < {T}) begin")
    L.append("                in_valid = ci[m][0];" + (" DIR = ci[m][1];" if DP else "") + " qid = qi[m];")
    L.append(f"                ann_valid = am[m][0]; ann_key = am[m][{KW}:1];")
    L.append(f"                for (l = 0; l < {P}; l++) x[l] = xm[m][l*{W} +: {W}];")
    L.append("                if (ci[m][0]) begin if (first_in < 0) first_in = m; last_in = m; end")
    L.append("            end else begin in_valid = 0; ann_valid = 0; end")
    L.append("            m = m + 1;")
    L.append("        end else begin")
    L.append(f"            $display(\"[tb] fed {nval} beats over cycles %0d..%0d, %0d beats out over cycles %0d..%0d "
             f"(latency {LAT}), %0d errors, %0d loads on request\", first_in, last_in, outs, first_out, last_out, errs, loads);")
    L.append(f"            if (errs == 0 && outs == {nval} && (last_out - first_out) == (last_in - first_in)) "
             "$display(\"[tb] PASS\"); else $display(\"[tb] FAIL\");")
    L.append("            $finish;")
    L.append("        end")
    L.append("    end")
    L.append("endmodule")
    return "\n".join(L) + "\n"
