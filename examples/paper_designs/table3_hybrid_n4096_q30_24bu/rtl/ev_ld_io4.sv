`timescale 1ns / 1ps
// ev_ld_io4: the hybrid NTT ev_ld_io4_k (16 words per beat) behind ports of 4 words per beat (1024 beats per polynomial)
module ev_ld_io4 (
    input  logic clk,
    input  logic rst,
    input  logic in_valid,
    output logic in_ready,
    input  logic [1:0] MIDX,
    input  logic DIR,
    input  logic [29:0] x_in_0,
    input  logic [29:0] x_in_1,
    input  logic [29:0] x_in_2,
    input  logic [29:0] x_in_3,
    output logic out_valid,
    output logic [1:0] midx_out,
    output logic dir_out,
    output logic [29:0] y_out_0,
    output logic [29:0] y_out_1,
    output logic [29:0] y_out_2,
    output logic [29:0] y_out_3,
    input  logic ld_we,
    input  logic [5:0] ld_sel,
    input  logic [10:0] ld_addr,
    input  logic [31:0] ld_data
    );
    logic k_valid, k_ready, k_ov;
    logic [29:0] k_x_0; logic [29:0] k_y_0;
    logic [29:0] k_x_1; logic [29:0] k_y_1;
    logic [29:0] k_x_2; logic [29:0] k_y_2;
    logic [29:0] k_x_3; logic [29:0] k_y_3;
    logic [29:0] k_x_4; logic [29:0] k_y_4;
    logic [29:0] k_x_5; logic [29:0] k_y_5;
    logic [29:0] k_x_6; logic [29:0] k_y_6;
    logic [29:0] k_x_7; logic [29:0] k_y_7;
    logic [29:0] k_x_8; logic [29:0] k_y_8;
    logic [29:0] k_x_9; logic [29:0] k_y_9;
    logic [29:0] k_x_10; logic [29:0] k_y_10;
    logic [29:0] k_x_11; logic [29:0] k_y_11;
    logic [29:0] k_x_12; logic [29:0] k_y_12;
    logic [29:0] k_x_13; logic [29:0] k_y_13;
    logic [29:0] k_x_14; logic [29:0] k_y_14;
    logic [29:0] k_x_15; logic [29:0] k_y_15;
    logic [1:0] k_midx, k_mo;
    logic k_dir, k_do;
    ev_ld_io4_k u_core (.clk(clk), .rst(rst), .in_valid(k_valid), .in_ready(k_ready), .MIDX(k_midx), .midx_out(k_mo), .DIR(k_dir), .dir_out(k_do), .x_in_0(k_x_0), .x_in_1(k_x_1), .x_in_2(k_x_2), .x_in_3(k_x_3), .x_in_4(k_x_4), .x_in_5(k_x_5), .x_in_6(k_x_6), .x_in_7(k_x_7), .x_in_8(k_x_8), .x_in_9(k_x_9), .x_in_10(k_x_10), .x_in_11(k_x_11), .x_in_12(k_x_12), .x_in_13(k_x_13), .x_in_14(k_x_14), .x_in_15(k_x_15), .out_valid(k_ov), .y_out_0(k_y_0), .y_out_1(k_y_1), .y_out_2(k_y_2), .y_out_3(k_y_3), .y_out_4(k_y_4), .y_out_5(k_y_5), .y_out_6(k_y_6), .y_out_7(k_y_7), .y_out_8(k_y_8), .y_out_9(k_y_9), .y_out_10(k_y_10), .y_out_11(k_y_11), .y_out_12(k_y_12), .y_out_13(k_y_13), .y_out_14(k_y_14), .y_out_15(k_y_15), .ld_we(ld_we), .ld_sel(ld_sel), .ld_addr(ld_addr), .ld_data(ld_data));
    logic acc, kacc;
    logic [1:0] ic;
    logic full;
    assign acc = in_valid && in_ready;
    assign kacc = full && k_ready;
    assign k_valid = full;
    // ---- input: 4 port beats make one core beat; the tags are those of a core beat's first port beat
    assign in_ready = !full || k_ready;
    always_ff @(posedge clk) begin
        if (rst) begin ic <= '0; full <= 1'b0; end
        else begin
            if (acc) ic <= ic + 1'b1;
            if (acc && ic == 2'd3) full <= 1'b1; else if (kacc) full <= 1'b0;
        end
    end
    always_ff @(posedge clk) if (acc) begin
        if (ic == '0) begin k_midx <= MIDX; k_dir <= DIR; end
        case (ic)
            2'd0: begin k_x_0 <= x_in_0; k_x_1 <= x_in_1; k_x_2 <= x_in_2; k_x_3 <= x_in_3; end
            2'd1: begin k_x_4 <= x_in_0; k_x_5 <= x_in_1; k_x_6 <= x_in_2; k_x_7 <= x_in_3; end
            2'd2: begin k_x_8 <= x_in_0; k_x_9 <= x_in_1; k_x_10 <= x_in_2; k_x_11 <= x_in_3; end
            2'd3: begin k_x_12 <= x_in_0; k_x_13 <= x_in_1; k_x_14 <= x_in_2; k_x_15 <= x_in_3; end
        endcase
    end
    // ---- output: a buffer of 2 polynomials (512 core beats); one core beat leaves in 4 cycles
    logic [482:0] ob [512];
    logic [482:0] od, oq;
    logic [9:0] wp, rp;
    logic [1:0] ec, s1_i;
    logic issue, s1_v;
    assign od = {k_do, k_mo, k_y_15, k_y_14, k_y_13, k_y_12, k_y_11, k_y_10, k_y_9, k_y_8, k_y_7, k_y_6, k_y_5, k_y_4, k_y_3, k_y_2, k_y_1, k_y_0};
    assign issue = (ec == '0) && (rp != wp);
    always_ff @(posedge clk) if (k_ov) ob[wp[8:0]] <= od;
    always_ff @(posedge clk) if (issue) oq <= ob[rp[8:0]];
    always_ff @(posedge clk) begin
        if (rst) begin wp <= '0; rp <= '0; ec <= '0; s1_v <= 1'b0; out_valid <= 1'b0; end
        else begin
            if (k_ov) wp <= wp + 1'b1;
            if (issue) rp <= rp + 1'b1;
            if (issue || ec != '0) ec <= ec + 1'b1;
            s1_v <= issue || ec != '0;
            out_valid <= s1_v;
        end
        s1_i <= ec;
    end
    always_ff @(posedge clk) begin
        midx_out <= oq[480 +: 2];
        dir_out <= oq[482];
        case (s1_i)
            2'd0: begin y_out_0 <= oq[0 +: 30]; y_out_1 <= oq[30 +: 30]; y_out_2 <= oq[60 +: 30]; y_out_3 <= oq[90 +: 30]; end
            2'd1: begin y_out_0 <= oq[120 +: 30]; y_out_1 <= oq[150 +: 30]; y_out_2 <= oq[180 +: 30]; y_out_3 <= oq[210 +: 30]; end
            2'd2: begin y_out_0 <= oq[240 +: 30]; y_out_1 <= oq[270 +: 30]; y_out_2 <= oq[300 +: 30]; y_out_3 <= oq[330 +: 30]; end
            2'd3: begin y_out_0 <= oq[360 +: 30]; y_out_1 <= oq[390 +: 30]; y_out_2 <= oq[420 +: 30]; y_out_3 <= oq[450 +: 30]; end
        endcase
    end
endmodule
