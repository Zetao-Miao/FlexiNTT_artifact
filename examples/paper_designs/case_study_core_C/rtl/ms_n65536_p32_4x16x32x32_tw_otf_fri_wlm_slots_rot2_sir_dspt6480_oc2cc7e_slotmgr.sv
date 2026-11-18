`timescale 1ns / 1ps
// ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt6480_oc2cc7e_slotmgr: slot manager, 5 slots, keys of 8 bits. A slot may be loaded 5333 cycles after the first beat of its
// last polynomial; its next polynomial may start 13 cycles after the first load word; a load is 1822 cycles.
// The decision on an announcement is pipelined (queue, latch, 3 comparison round(s), apply).
module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt6480_oc2cc7e_slotmgr (
    input  logic clk,
    input  logic rst,
    input  logic ann_valid,                 // the key of the next polynomial that was not announced yet
    input  logic [7:0] ann_key,
    input  logic poly_start,                // the first beat of a polynomial is at the core in this cycle
    output logic [2:0] midx,              // its slot (valid with poly_start, held after)
    output logic ld_req,                    // one cycle: send the load of ld_key
    output logic [7:0] ld_key,
    input  logic ld_wen,                    // a load word is on the core's load port
    output logic tw_rst,                    // to the core's loader: a load of slot tw_slot starts
    output logic [2:0] tw_slot,
    output logic slot_err,                  // sticky
    output logic [2:0] err_code             // 1 no free slot, 2 polynomial not announced, 3 slot not ready, 4 gap in a load, 5 queue full
    );
    localparam int K = 5;
    logic [7:0] key [K];
    logic valid [K];
    logic [13:0] busy [K];             // cycles until the slot may be loaded again
    logic [13:0] ready [K];            // cycles until the slot may be used (after its load started)
    logic rwait [K];                         // its load has not started yet
    logic [4:0] pend [K];                    // announced polynomials of the slot that have not started
    logic [19:0] age [K];             // cycles since its last polynomial started

    // --- the announcements that wait -----------------------------------------------------------------------
    logic [7:0] aq_k [4];
    logic [2:0] aq_w, aq_r;
    logic aq_empty, aq_full;
    assign aq_empty = (aq_w == aq_r);
    assign aq_full = (aq_w[1:0] == aq_r[1:0]) && (aq_w[2] != aq_r[2]);
    logic [7:0] aq_head;
    assign aq_head = aq_k[aq_r[1:0]];

    // --- one decision at a time: latch, compare, apply ---------------------------------------------------------
    logic dbusy;
    logic [3:0] dcnt;
    logic [7:0] d_key;
    logic [K - 1:0] hitv, freev;
    logic [20:0] sc [K];                  // never used first, then the longest unused
    logic hit; logic [2:0] hit_i;
    logic t0_f [8]; logic [20:0] t0_s [8]; logic [2:0] t0_i [8];
    assign t0_f[0] = freev[0]; assign t0_s[0] = sc[0]; assign t0_i[0] = 3'd0;
    assign t0_f[1] = freev[1]; assign t0_s[1] = sc[1]; assign t0_i[1] = 3'd1;
    assign t0_f[2] = freev[2]; assign t0_s[2] = sc[2]; assign t0_i[2] = 3'd2;
    assign t0_f[3] = freev[3]; assign t0_s[3] = sc[3]; assign t0_i[3] = 3'd3;
    assign t0_f[4] = freev[4]; assign t0_s[4] = sc[4]; assign t0_i[4] = 3'd4;
    assign t0_f[5] = 1'b0; assign t0_s[5] = '0; assign t0_i[5] = '0;
    assign t0_f[6] = 1'b0; assign t0_s[6] = '0; assign t0_i[6] = '0;
    assign t0_f[7] = 1'b0; assign t0_s[7] = '0; assign t0_i[7] = '0;
    logic t1_f [4]; logic [20:0] t1_s [4]; logic [2:0] t1_i [4];
    always_ff @(posedge clk) begin
        if (t0_f[1] && (!t0_f[0] || t0_s[1] > t0_s[0])) begin t1_f[0] <= 1'b1; t1_s[0] <= t0_s[1]; t1_i[0] <= t0_i[1]; end
        else begin t1_f[0] <= t0_f[0]; t1_s[0] <= t0_s[0]; t1_i[0] <= t0_i[0]; end
        if (t0_f[3] && (!t0_f[2] || t0_s[3] > t0_s[2])) begin t1_f[1] <= 1'b1; t1_s[1] <= t0_s[3]; t1_i[1] <= t0_i[3]; end
        else begin t1_f[1] <= t0_f[2]; t1_s[1] <= t0_s[2]; t1_i[1] <= t0_i[2]; end
        if (t0_f[5] && (!t0_f[4] || t0_s[5] > t0_s[4])) begin t1_f[2] <= 1'b1; t1_s[2] <= t0_s[5]; t1_i[2] <= t0_i[5]; end
        else begin t1_f[2] <= t0_f[4]; t1_s[2] <= t0_s[4]; t1_i[2] <= t0_i[4]; end
        if (t0_f[7] && (!t0_f[6] || t0_s[7] > t0_s[6])) begin t1_f[3] <= 1'b1; t1_s[3] <= t0_s[7]; t1_i[3] <= t0_i[7]; end
        else begin t1_f[3] <= t0_f[6]; t1_s[3] <= t0_s[6]; t1_i[3] <= t0_i[6]; end
    end
    logic t2_f [2]; logic [20:0] t2_s [2]; logic [2:0] t2_i [2];
    always_ff @(posedge clk) begin
        if (t1_f[1] && (!t1_f[0] || t1_s[1] > t1_s[0])) begin t2_f[0] <= 1'b1; t2_s[0] <= t1_s[1]; t2_i[0] <= t1_i[1]; end
        else begin t2_f[0] <= t1_f[0]; t2_s[0] <= t1_s[0]; t2_i[0] <= t1_i[0]; end
        if (t1_f[3] && (!t1_f[2] || t1_s[3] > t1_s[2])) begin t2_f[1] <= 1'b1; t2_s[1] <= t1_s[3]; t2_i[1] <= t1_i[3]; end
        else begin t2_f[1] <= t1_f[2]; t2_s[1] <= t1_s[2]; t2_i[1] <= t1_i[2]; end
    end
    logic t3_f [1]; logic [20:0] t3_s [1]; logic [2:0] t3_i [1];
    always_ff @(posedge clk) begin
        if (t2_f[1] && (!t2_f[0] || t2_s[1] > t2_s[0])) begin t3_f[0] <= 1'b1; t3_s[0] <= t2_s[1]; t3_i[0] <= t2_i[1]; end
        else begin t3_f[0] <= t2_f[0]; t3_s[0] <= t2_s[0]; t3_i[0] <= t2_i[0]; end
    end
    logic apply, a_go, a_miss;
    logic [2:0] a_slot;
    assign apply = dbusy && (dcnt == 4'd3);
    assign a_slot = hit ? hit_i : t3_i[0];
    assign a_miss = apply && !hit && t3_f[0];
    assign a_go = apply && (hit || t3_f[0]);

    // --- the order of the announced polynomials ---------------------------------------------------------------
    logic [2:0] of [16];
    logic [4:0] of_w, of_r, of_r_n;
    logic of_empty, of_full;
    assign of_empty = (of_w == of_r);
    assign of_full = (of_w[3:0] == of_r[3:0]) && (of_w[4] != of_r[4]);
    logic [2:0] head_q, midx_r;       // head_q: the slot of the next polynomial, in a register
    logic take, push;
    assign take = poly_start && !of_empty;
    assign of_r_n = of_r + 5'(take);
    assign midx = take ? head_q : midx_r;

    // --- the loads that wait, and the loader ----------------------------------------------------------------------
    logic [2:0] lq_s [4];
    logic [7:0] lq_k [4];
    logic [2:0] lq_w, lq_r;
    logic lq_empty, lq_full;
    assign lq_empty = (lq_w == lq_r);
    assign lq_full = (lq_w[1:0] == lq_r[1:0]) && (lq_w[2] != lq_r[2]);
    assign push = a_go && !of_full && !(a_miss && lq_full);
    logic running, started;
    logic nxt_valid;                         // the next load was requested while this one runs (back to back)
    logic [2:0] nxt_slot;
    logic [2:0] cur;
    logic [13:0] wcnt;
    logic first_word, last_word;
    assign first_word = running && !started && ld_wen;
    assign last_word = running && ld_wen && (wcnt == 14'd1821);
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
            end
        end else begin
            // every slot: its counters, with at most one decision and one start in a cycle
            for (int i = 0; i < K; i++) begin
                if (take && head_q == 3'(i)) begin
                    busy[i] <= 14'd5333;
                    age[i] <= '0;
                end else begin
                    if (busy[i] != '0) busy[i] <= busy[i] - 1'b1;
                    if (!(&age[i])) age[i] <= age[i] + 1'b1;
                end
                if (first_word && cur == 3'(i)) begin
                    ready[i] <= 14'd12;
                    rwait[i] <= 1'b0;
                end else if (ready[i] != '0) ready[i] <= ready[i] - 1'b1;
                pend[i] <= pend[i] + 5'((push && a_slot == 3'(i)) ? 1 : 0)
                                   - 5'((take && head_q == 3'(i)) ? 1 : 0);
                if (push && a_miss && a_slot == 3'(i)) begin
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
                    aq_k[aq_w[1:0]] <= ann_key;
                    aq_w <= aq_w + 1'b1;
                end
            end
            // the decision: latch (hit and free flags from the registers of this cycle), compare, apply
            if (!dbusy) begin
                if (!aq_empty) begin
                    dbusy <= 1'b1; dcnt <= '0; d_key <= aq_head; aq_r <= aq_r + 1'b1;
                    for (int i = 0; i < K; i++) begin
                        hitv[i] <= valid[i] && key[i] == aq_head;
                        // free: never used, or idle long enough with nothing announced and no load under way
                        freev[i] <= !valid[i] || (busy[i] == '0 && pend[i] == '0 && ready[i] == '0 && !rwait[i]);
                        sc[i] <= !valid[i] ? {1'b1, 20'd0} : {1'b0, age[i]};
                    end
                end
            end else begin
                dcnt <= dcnt + 1'b1;
                if (dcnt == 4'd0) begin
                    hit <= |hitv;
                    hit_i <= '0;
            if (hitv[4]) hit_i <= 3'd4;
            if (hitv[3]) hit_i <= 3'd3;
            if (hitv[2]) hit_i <= 3'd2;
            if (hitv[1]) hit_i <= 3'd1;
            if (hitv[0]) hit_i <= 3'd0;
                end
                if (apply) begin
                    dbusy <= 1'b0;
                    if (!hit && !t3_f[0]) begin
                        if (!slot_err) begin slot_err <= 1'b1; err_code <= 3'd1; end
                    end else if (of_full || (a_miss && lq_full)) begin
                        if (!slot_err) begin slot_err <= 1'b1; err_code <= 3'd5; end
                    end else begin
                        of[of_w[3:0]] <= a_slot;
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
            head_q <= (push && of_w[3:0] == of_r_n[3:0]) ? a_slot : of[of_r_n[3:0]];
            // a polynomial starts
            if (poly_start) begin
                if (!take) begin
                    if (1 && !slot_err) begin slot_err <= 1'b1; err_code <= 3'd2; end
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
                if (1 && !nxt_valid && !lq_empty && wcnt <= 14'd1819) begin
                    nxt_valid <= 1'b1;
                    nxt_slot <= lq_s[lq_r[1:0]];
                    ld_key <= lq_k[lq_r[1:0]];
                    ld_req <= 1'b1;
                    lq_r <= lq_r + 1'b1;
                end
                if (ld_wen) begin
                    started <= 1'b1;
                    wcnt <= wcnt + 1'b1;
                    if (nxt_valid && wcnt == 14'd1820) begin
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
