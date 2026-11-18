`timescale 1ns / 1ps
// MS_N12_q60_P32_tpm: multi-step NTT, N=4096, sizes [32, 4, 32], 32 lanes, frame 128 cycles, latency 388, fixed q
module MS_N12_q60_P32_tpm (
    input  logic clk,
    input  logic rst,
    input  logic in_valid,
    input  logic DIR,
    input  logic ld_rst,
    input  logic ld_wen,
    input  logic [59:0] ld_wdata,
    input  logic [16:0] QH,
    input  logic [59:0] QHALF,
    input  logic [59:0] x_in_0,
    input  logic [59:0] x_in_1,
    input  logic [59:0] x_in_2,
    input  logic [59:0] x_in_3,
    input  logic [59:0] x_in_4,
    input  logic [59:0] x_in_5,
    input  logic [59:0] x_in_6,
    input  logic [59:0] x_in_7,
    input  logic [59:0] x_in_8,
    input  logic [59:0] x_in_9,
    input  logic [59:0] x_in_10,
    input  logic [59:0] x_in_11,
    input  logic [59:0] x_in_12,
    input  logic [59:0] x_in_13,
    input  logic [59:0] x_in_14,
    input  logic [59:0] x_in_15,
    input  logic [59:0] x_in_16,
    input  logic [59:0] x_in_17,
    input  logic [59:0] x_in_18,
    input  logic [59:0] x_in_19,
    input  logic [59:0] x_in_20,
    input  logic [59:0] x_in_21,
    input  logic [59:0] x_in_22,
    input  logic [59:0] x_in_23,
    input  logic [59:0] x_in_24,
    input  logic [59:0] x_in_25,
    input  logic [59:0] x_in_26,
    input  logic [59:0] x_in_27,
    input  logic [59:0] x_in_28,
    input  logic [59:0] x_in_29,
    input  logic [59:0] x_in_30,
    input  logic [59:0] x_in_31,
    output logic out_valid,
    output logic dir_out,
    output logic [59:0] y_out_0,
    output logic [59:0] y_out_1,
    output logic [59:0] y_out_2,
    output logic [59:0] y_out_3,
    output logic [59:0] y_out_4,
    output logic [59:0] y_out_5,
    output logic [59:0] y_out_6,
    output logic [59:0] y_out_7,
    output logic [59:0] y_out_8,
    output logic [59:0] y_out_9,
    output logic [59:0] y_out_10,
    output logic [59:0] y_out_11,
    output logic [59:0] y_out_12,
    output logic [59:0] y_out_13,
    output logic [59:0] y_out_14,
    output logic [59:0] y_out_15,
    output logic [59:0] y_out_16,
    output logic [59:0] y_out_17,
    output logic [59:0] y_out_18,
    output logic [59:0] y_out_19,
    output logic [59:0] y_out_20,
    output logic [59:0] y_out_21,
    output logic [59:0] y_out_22,
    output logic [59:0] y_out_23,
    output logic [59:0] y_out_24,
    output logic [59:0] y_out_25,
    output logic [59:0] y_out_26,
    output logic [59:0] y_out_27,
    output logic [59:0] y_out_28,
    output logic [59:0] y_out_29,
    output logic [59:0] y_out_30,
    output logic [59:0] y_out_31
    );
    // load port: one word per ld_wen after ld_rst, 16382 words: the sub-NTT images, then the tables
    (* max_fanout = 32 *) logic ld_rst_p, ld_wen_p; (* max_fanout = 32 *) logic [59:0] ld_wdata_p;
    always_ff @(posedge clk) begin ld_rst_p <= ld_rst; ld_wen_p <= ld_wen; ld_wdata_p <= ld_wdata; end
    (* max_fanout = 32 *) logic [13:0] ld_i;
    always_ff @(posedge clk) ld_i <= ld_rst_p ? '0 : (ld_wen_p ? ld_i + 1'b1 : ld_i);
    (* max_fanout = 32 *) logic [59:0] ld_d; always_ff @(posedge clk) ld_d <= ld_wdata_p;
    (* max_fanout = 32 *) logic ld_v, ld_r; always_ff @(posedge clk) begin ld_v <= ld_wen_p; ld_r <= ld_rst_p; end
    logic [13:0] ld_iq; always_ff @(posedge clk) ld_iq <= ld_i;
    logic [59:0] d0_0; assign d0_0 = x_in_0;
    logic [59:0] d0_1; assign d0_1 = x_in_1;
    logic [59:0] d0_2; assign d0_2 = x_in_2;
    logic [59:0] d0_3; assign d0_3 = x_in_3;
    logic [59:0] d0_4; assign d0_4 = x_in_4;
    logic [59:0] d0_5; assign d0_5 = x_in_5;
    logic [59:0] d0_6; assign d0_6 = x_in_6;
    logic [59:0] d0_7; assign d0_7 = x_in_7;
    logic [59:0] d0_8; assign d0_8 = x_in_8;
    logic [59:0] d0_9; assign d0_9 = x_in_9;
    logic [59:0] d0_10; assign d0_10 = x_in_10;
    logic [59:0] d0_11; assign d0_11 = x_in_11;
    logic [59:0] d0_12; assign d0_12 = x_in_12;
    logic [59:0] d0_13; assign d0_13 = x_in_13;
    logic [59:0] d0_14; assign d0_14 = x_in_14;
    logic [59:0] d0_15; assign d0_15 = x_in_15;
    logic [59:0] d0_16; assign d0_16 = x_in_16;
    logic [59:0] d0_17; assign d0_17 = x_in_17;
    logic [59:0] d0_18; assign d0_18 = x_in_18;
    logic [59:0] d0_19; assign d0_19 = x_in_19;
    logic [59:0] d0_20; assign d0_20 = x_in_20;
    logic [59:0] d0_21; assign d0_21 = x_in_21;
    logic [59:0] d0_22; assign d0_22 = x_in_22;
    logic [59:0] d0_23; assign d0_23 = x_in_23;
    logic [59:0] d0_24; assign d0_24 = x_in_24;
    logic [59:0] d0_25; assign d0_25 = x_in_25;
    logic [59:0] d0_26; assign d0_26 = x_in_26;
    logic [59:0] d0_27; assign d0_27 = x_in_27;
    logic [59:0] d0_28; assign d0_28 = x_in_28;
    logic [59:0] d0_29; assign d0_29 = x_in_29;
    logic [59:0] d0_30; assign d0_30 = x_in_30;
    logic [59:0] d0_31; assign d0_31 = x_in_31;
    logic v0; assign v0 = in_valid;
    logic [0:0] g0; assign g0 = DIR;
    // block 0: pass 0, 1 x MS_N12_q60_P32_tpm_p0 (32-point), latency 83
    logic [59:0] b0_c0_y0, b0_c0_y1, b0_c0_y2, b0_c0_y3, b0_c0_y4, b0_c0_y5, b0_c0_y6, b0_c0_y7, b0_c0_y8, b0_c0_y9, b0_c0_y10, b0_c0_y11, b0_c0_y12, b0_c0_y13, b0_c0_y14, b0_c0_y15, b0_c0_y16, b0_c0_y17, b0_c0_y18, b0_c0_y19, b0_c0_y20, b0_c0_y21, b0_c0_y22, b0_c0_y23, b0_c0_y24, b0_c0_y25, b0_c0_y26, b0_c0_y27, b0_c0_y28, b0_c0_y29, b0_c0_y30, b0_c0_y31;
    logic b0_c0_v; logic b0_c0_di;
    logic b0_c0_lr, b0_c0_lw; (* equivalent_register_removal = "no" *) logic [59:0] b0_c0_ld;
    always_ff @(posedge clk) begin b0_c0_lr <= ld_r; b0_c0_lw <= ld_v && ld_iq >= 14'd0 && ld_iq < 14'd62; b0_c0_ld <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_p0 b0_c0 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c0_v), .DIR(g0[0]), .tw_rst(b0_c0_lr), .tw_wen(b0_c0_lw), .tw_wdata(b0_c0_ld), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(d0_0), .x_in_1(d0_1), .x_in_2(d0_2), .x_in_3(d0_3), .x_in_4(d0_4), .x_in_5(d0_5), .x_in_6(d0_6), .x_in_7(d0_7), .x_in_8(d0_8), .x_in_9(d0_9), .x_in_10(d0_10), .x_in_11(d0_11), .x_in_12(d0_12), .x_in_13(d0_13), .x_in_14(d0_14), .x_in_15(d0_15), .x_in_16(d0_16), .x_in_17(d0_17), .x_in_18(d0_18), .x_in_19(d0_19), .x_in_20(d0_20), .x_in_21(d0_21), .x_in_22(d0_22), .x_in_23(d0_23), .x_in_24(d0_24), .x_in_25(d0_25), .x_in_26(d0_26), .x_in_27(d0_27), .x_in_28(d0_28), .x_in_29(d0_29), .x_in_30(d0_30), .x_in_31(d0_31), .y_out_0(b0_c0_y0), .y_out_1(b0_c0_y1), .y_out_2(b0_c0_y2), .y_out_3(b0_c0_y3), .y_out_4(b0_c0_y4), .y_out_5(b0_c0_y5), .y_out_6(b0_c0_y6), .y_out_7(b0_c0_y7), .y_out_8(b0_c0_y8), .y_out_9(b0_c0_y9), .y_out_10(b0_c0_y10), .y_out_11(b0_c0_y11), .y_out_12(b0_c0_y12), .y_out_13(b0_c0_y13), .y_out_14(b0_c0_y14), .y_out_15(b0_c0_y15), .y_out_16(b0_c0_y16), .y_out_17(b0_c0_y17), .y_out_18(b0_c0_y18), .y_out_19(b0_c0_y19), .y_out_20(b0_c0_y20), .y_out_21(b0_c0_y21), .y_out_22(b0_c0_y22), .y_out_23(b0_c0_y23), .y_out_24(b0_c0_y24), .y_out_25(b0_c0_y25), .y_out_26(b0_c0_y26), .y_out_27(b0_c0_y27), .y_out_28(b0_c0_y28), .y_out_29(b0_c0_y29), .y_out_30(b0_c0_y30), .y_out_31(b0_c0_y31));
    logic [0:0] b0_tag;
    MS_N12_q60_P32_tpm_dly_c #(.W(1), .D(83)) b0_tag_i (.clk(clk), .din(g0), .dout(b0_tag));
    // block 1: lane-time transpose, lane bits [0, 1] <-> cycle bits [5,7), 8 x S=4, latency 131
    logic [59:0] b1_g0_i [0:3]; logic [59:0] b1_g0_o [0:3]; logic b1_g0_v;
    assign b1_g0_i[0] = b0_c0_y0;
    assign b1_g0_i[1] = b0_c0_y1;
    assign b1_g0_i[2] = b0_c0_y2;
    assign b1_g0_i[3] = b0_c0_y3;
    lt_bmb_transpose #(.S(4), .LO(5), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g0 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g0_i), .data_out_valid(b1_g0_v), .data_out(b1_g0_o));
    logic [59:0] b1_g1_i [0:3]; logic [59:0] b1_g1_o [0:3]; logic b1_g1_v;
    assign b1_g1_i[0] = b0_c0_y4;
    assign b1_g1_i[1] = b0_c0_y5;
    assign b1_g1_i[2] = b0_c0_y6;
    assign b1_g1_i[3] = b0_c0_y7;
    lt_bmb_transpose #(.S(4), .LO(5), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g1 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g1_i), .data_out_valid(b1_g1_v), .data_out(b1_g1_o));
    logic [59:0] b1_g2_i [0:3]; logic [59:0] b1_g2_o [0:3]; logic b1_g2_v;
    assign b1_g2_i[0] = b0_c0_y8;
    assign b1_g2_i[1] = b0_c0_y9;
    assign b1_g2_i[2] = b0_c0_y10;
    assign b1_g2_i[3] = b0_c0_y11;
    lt_bmb_transpose #(.S(4), .LO(5), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g2 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g2_i), .data_out_valid(b1_g2_v), .data_out(b1_g2_o));
    logic [59:0] b1_g3_i [0:3]; logic [59:0] b1_g3_o [0:3]; logic b1_g3_v;
    assign b1_g3_i[0] = b0_c0_y12;
    assign b1_g3_i[1] = b0_c0_y13;
    assign b1_g3_i[2] = b0_c0_y14;
    assign b1_g3_i[3] = b0_c0_y15;
    lt_bmb_transpose #(.S(4), .LO(5), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g3 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g3_i), .data_out_valid(b1_g3_v), .data_out(b1_g3_o));
    logic [59:0] b1_g4_i [0:3]; logic [59:0] b1_g4_o [0:3]; logic b1_g4_v;
    assign b1_g4_i[0] = b0_c0_y16;
    assign b1_g4_i[1] = b0_c0_y17;
    assign b1_g4_i[2] = b0_c0_y18;
    assign b1_g4_i[3] = b0_c0_y19;
    lt_bmb_transpose #(.S(4), .LO(5), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g4 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g4_i), .data_out_valid(b1_g4_v), .data_out(b1_g4_o));
    logic [59:0] b1_g5_i [0:3]; logic [59:0] b1_g5_o [0:3]; logic b1_g5_v;
    assign b1_g5_i[0] = b0_c0_y20;
    assign b1_g5_i[1] = b0_c0_y21;
    assign b1_g5_i[2] = b0_c0_y22;
    assign b1_g5_i[3] = b0_c0_y23;
    lt_bmb_transpose #(.S(4), .LO(5), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g5 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g5_i), .data_out_valid(b1_g5_v), .data_out(b1_g5_o));
    logic [59:0] b1_g6_i [0:3]; logic [59:0] b1_g6_o [0:3]; logic b1_g6_v;
    assign b1_g6_i[0] = b0_c0_y24;
    assign b1_g6_i[1] = b0_c0_y25;
    assign b1_g6_i[2] = b0_c0_y26;
    assign b1_g6_i[3] = b0_c0_y27;
    lt_bmb_transpose #(.S(4), .LO(5), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g6 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g6_i), .data_out_valid(b1_g6_v), .data_out(b1_g6_o));
    logic [59:0] b1_g7_i [0:3]; logic [59:0] b1_g7_o [0:3]; logic b1_g7_v;
    assign b1_g7_i[0] = b0_c0_y28;
    assign b1_g7_i[1] = b0_c0_y29;
    assign b1_g7_i[2] = b0_c0_y30;
    assign b1_g7_i[3] = b0_c0_y31;
    lt_bmb_transpose #(.S(4), .LO(5), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g7 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g7_i), .data_out_valid(b1_g7_v), .data_out(b1_g7_o));
    logic [0:0] b1_tag;
    MS_N12_q60_P32_tpm_dly_c #(.W(1), .D(131)) b1_tag_i (.clk(clk), .din(b0_tag), .dout(b1_tag));
    logic [6:0] b2_cnt;
    always_ff @(posedge clk) b2_cnt <= rst ? '0 : (b1_g0_v ? b2_cnt + 1'b1 : b2_cnt);
    logic [59:0] b2_w0;
    logic b2_w0_lwe; logic [2:0] b2_w0_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w0_lwd;
    always_ff @(posedge clk) begin b2_w0_lwe <= ld_v && ld_iq >= 14'd62 && ld_iq < 14'd70; b2_w0_lwa <= 3'(ld_iq - 14'd62); b2_w0_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab0 b2_w0_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w0_lwe), .wa(b2_w0_lwa), .wcol(1'b0), .wd(b2_w0_lwd), .q0(b2_w0));
    logic [59:0] b2_w1;
    logic b2_w1_lwe; logic [2:0] b2_w1_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w1_lwd;
    always_ff @(posedge clk) begin b2_w1_lwe <= ld_v && ld_iq >= 14'd70 && ld_iq < 14'd78; b2_w1_lwa <= 3'(ld_iq - 14'd70); b2_w1_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab1 b2_w1_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w1_lwe), .wa(b2_w1_lwa), .wcol(1'b0), .wd(b2_w1_lwd), .q0(b2_w1));
    logic [59:0] b2_w2;
    logic b2_w2_lwe; logic [2:0] b2_w2_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w2_lwd;
    always_ff @(posedge clk) begin b2_w2_lwe <= ld_v && ld_iq >= 14'd78 && ld_iq < 14'd86; b2_w2_lwa <= 3'(ld_iq - 14'd78); b2_w2_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab2 b2_w2_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w2_lwe), .wa(b2_w2_lwa), .wcol(1'b0), .wd(b2_w2_lwd), .q0(b2_w2));
    logic [59:0] b2_w3;
    logic b2_w3_lwe; logic [2:0] b2_w3_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w3_lwd;
    always_ff @(posedge clk) begin b2_w3_lwe <= ld_v && ld_iq >= 14'd86 && ld_iq < 14'd94; b2_w3_lwa <= 3'(ld_iq - 14'd86); b2_w3_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab3 b2_w3_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w3_lwe), .wa(b2_w3_lwa), .wcol(1'b0), .wd(b2_w3_lwd), .q0(b2_w3));
    logic [59:0] b2_w4;
    logic b2_w4_lwe; logic [2:0] b2_w4_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w4_lwd;
    always_ff @(posedge clk) begin b2_w4_lwe <= ld_v && ld_iq >= 14'd94 && ld_iq < 14'd102; b2_w4_lwa <= 3'(ld_iq - 14'd94); b2_w4_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab4 b2_w4_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w4_lwe), .wa(b2_w4_lwa), .wcol(1'b0), .wd(b2_w4_lwd), .q0(b2_w4));
    logic [59:0] b2_w5;
    logic b2_w5_lwe; logic [2:0] b2_w5_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w5_lwd;
    always_ff @(posedge clk) begin b2_w5_lwe <= ld_v && ld_iq >= 14'd102 && ld_iq < 14'd110; b2_w5_lwa <= 3'(ld_iq - 14'd102); b2_w5_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab5 b2_w5_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w5_lwe), .wa(b2_w5_lwa), .wcol(1'b0), .wd(b2_w5_lwd), .q0(b2_w5));
    logic [59:0] b2_w6;
    logic b2_w6_lwe; logic [2:0] b2_w6_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w6_lwd;
    always_ff @(posedge clk) begin b2_w6_lwe <= ld_v && ld_iq >= 14'd110 && ld_iq < 14'd118; b2_w6_lwa <= 3'(ld_iq - 14'd110); b2_w6_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab6 b2_w6_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w6_lwe), .wa(b2_w6_lwa), .wcol(1'b0), .wd(b2_w6_lwd), .q0(b2_w6));
    logic [59:0] b2_w7;
    logic b2_w7_lwe; logic [2:0] b2_w7_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w7_lwd;
    always_ff @(posedge clk) begin b2_w7_lwe <= ld_v && ld_iq >= 14'd118 && ld_iq < 14'd126; b2_w7_lwa <= 3'(ld_iq - 14'd118); b2_w7_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab7 b2_w7_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w7_lwe), .wa(b2_w7_lwa), .wcol(1'b0), .wd(b2_w7_lwd), .q0(b2_w7));
    logic [59:0] b2_w8;
    logic b2_w8_lwe; logic [2:0] b2_w8_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w8_lwd;
    always_ff @(posedge clk) begin b2_w8_lwe <= ld_v && ld_iq >= 14'd126 && ld_iq < 14'd134; b2_w8_lwa <= 3'(ld_iq - 14'd126); b2_w8_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab8 b2_w8_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w8_lwe), .wa(b2_w8_lwa), .wcol(1'b0), .wd(b2_w8_lwd), .q0(b2_w8));
    logic [59:0] b2_w9;
    logic b2_w9_lwe; logic [2:0] b2_w9_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w9_lwd;
    always_ff @(posedge clk) begin b2_w9_lwe <= ld_v && ld_iq >= 14'd134 && ld_iq < 14'd142; b2_w9_lwa <= 3'(ld_iq - 14'd134); b2_w9_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab9 b2_w9_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w9_lwe), .wa(b2_w9_lwa), .wcol(1'b0), .wd(b2_w9_lwd), .q0(b2_w9));
    logic [59:0] b2_w10;
    logic b2_w10_lwe; logic [2:0] b2_w10_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w10_lwd;
    always_ff @(posedge clk) begin b2_w10_lwe <= ld_v && ld_iq >= 14'd142 && ld_iq < 14'd150; b2_w10_lwa <= 3'(ld_iq - 14'd142); b2_w10_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab10 b2_w10_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w10_lwe), .wa(b2_w10_lwa), .wcol(1'b0), .wd(b2_w10_lwd), .q0(b2_w10));
    logic [59:0] b2_w11;
    logic b2_w11_lwe; logic [2:0] b2_w11_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w11_lwd;
    always_ff @(posedge clk) begin b2_w11_lwe <= ld_v && ld_iq >= 14'd150 && ld_iq < 14'd158; b2_w11_lwa <= 3'(ld_iq - 14'd150); b2_w11_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab11 b2_w11_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w11_lwe), .wa(b2_w11_lwa), .wcol(1'b0), .wd(b2_w11_lwd), .q0(b2_w11));
    logic [59:0] b2_w12;
    logic b2_w12_lwe; logic [2:0] b2_w12_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w12_lwd;
    always_ff @(posedge clk) begin b2_w12_lwe <= ld_v && ld_iq >= 14'd158 && ld_iq < 14'd166; b2_w12_lwa <= 3'(ld_iq - 14'd158); b2_w12_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab12 b2_w12_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w12_lwe), .wa(b2_w12_lwa), .wcol(1'b0), .wd(b2_w12_lwd), .q0(b2_w12));
    logic [59:0] b2_w13;
    logic b2_w13_lwe; logic [2:0] b2_w13_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w13_lwd;
    always_ff @(posedge clk) begin b2_w13_lwe <= ld_v && ld_iq >= 14'd166 && ld_iq < 14'd174; b2_w13_lwa <= 3'(ld_iq - 14'd166); b2_w13_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab13 b2_w13_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w13_lwe), .wa(b2_w13_lwa), .wcol(1'b0), .wd(b2_w13_lwd), .q0(b2_w13));
    logic [59:0] b2_w14;
    logic b2_w14_lwe; logic [2:0] b2_w14_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w14_lwd;
    always_ff @(posedge clk) begin b2_w14_lwe <= ld_v && ld_iq >= 14'd174 && ld_iq < 14'd182; b2_w14_lwa <= 3'(ld_iq - 14'd174); b2_w14_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab14 b2_w14_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w14_lwe), .wa(b2_w14_lwa), .wcol(1'b0), .wd(b2_w14_lwd), .q0(b2_w14));
    logic [59:0] b2_w15;
    logic b2_w15_lwe; logic [2:0] b2_w15_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w15_lwd;
    always_ff @(posedge clk) begin b2_w15_lwe <= ld_v && ld_iq >= 14'd182 && ld_iq < 14'd190; b2_w15_lwa <= 3'(ld_iq - 14'd182); b2_w15_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab15 b2_w15_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w15_lwe), .wa(b2_w15_lwa), .wcol(1'b0), .wd(b2_w15_lwd), .q0(b2_w15));
    logic [59:0] b2_w16;
    logic b2_w16_lwe; logic [2:0] b2_w16_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w16_lwd;
    always_ff @(posedge clk) begin b2_w16_lwe <= ld_v && ld_iq >= 14'd190 && ld_iq < 14'd198; b2_w16_lwa <= 3'(ld_iq - 14'd190); b2_w16_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab16 b2_w16_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w16_lwe), .wa(b2_w16_lwa), .wcol(1'b0), .wd(b2_w16_lwd), .q0(b2_w16));
    logic [59:0] b2_w17;
    logic b2_w17_lwe; logic [2:0] b2_w17_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w17_lwd;
    always_ff @(posedge clk) begin b2_w17_lwe <= ld_v && ld_iq >= 14'd198 && ld_iq < 14'd206; b2_w17_lwa <= 3'(ld_iq - 14'd198); b2_w17_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab17 b2_w17_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w17_lwe), .wa(b2_w17_lwa), .wcol(1'b0), .wd(b2_w17_lwd), .q0(b2_w17));
    logic [59:0] b2_w18;
    logic b2_w18_lwe; logic [2:0] b2_w18_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w18_lwd;
    always_ff @(posedge clk) begin b2_w18_lwe <= ld_v && ld_iq >= 14'd206 && ld_iq < 14'd214; b2_w18_lwa <= 3'(ld_iq - 14'd206); b2_w18_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab18 b2_w18_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w18_lwe), .wa(b2_w18_lwa), .wcol(1'b0), .wd(b2_w18_lwd), .q0(b2_w18));
    logic [59:0] b2_w19;
    logic b2_w19_lwe; logic [2:0] b2_w19_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w19_lwd;
    always_ff @(posedge clk) begin b2_w19_lwe <= ld_v && ld_iq >= 14'd214 && ld_iq < 14'd222; b2_w19_lwa <= 3'(ld_iq - 14'd214); b2_w19_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab19 b2_w19_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w19_lwe), .wa(b2_w19_lwa), .wcol(1'b0), .wd(b2_w19_lwd), .q0(b2_w19));
    logic [59:0] b2_w20;
    logic b2_w20_lwe; logic [2:0] b2_w20_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w20_lwd;
    always_ff @(posedge clk) begin b2_w20_lwe <= ld_v && ld_iq >= 14'd222 && ld_iq < 14'd230; b2_w20_lwa <= 3'(ld_iq - 14'd222); b2_w20_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab20 b2_w20_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w20_lwe), .wa(b2_w20_lwa), .wcol(1'b0), .wd(b2_w20_lwd), .q0(b2_w20));
    logic [59:0] b2_w21;
    logic b2_w21_lwe; logic [2:0] b2_w21_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w21_lwd;
    always_ff @(posedge clk) begin b2_w21_lwe <= ld_v && ld_iq >= 14'd230 && ld_iq < 14'd238; b2_w21_lwa <= 3'(ld_iq - 14'd230); b2_w21_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab21 b2_w21_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w21_lwe), .wa(b2_w21_lwa), .wcol(1'b0), .wd(b2_w21_lwd), .q0(b2_w21));
    logic [59:0] b2_w22;
    logic b2_w22_lwe; logic [2:0] b2_w22_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w22_lwd;
    always_ff @(posedge clk) begin b2_w22_lwe <= ld_v && ld_iq >= 14'd238 && ld_iq < 14'd246; b2_w22_lwa <= 3'(ld_iq - 14'd238); b2_w22_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab22 b2_w22_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w22_lwe), .wa(b2_w22_lwa), .wcol(1'b0), .wd(b2_w22_lwd), .q0(b2_w22));
    logic [59:0] b2_w23;
    logic b2_w23_lwe; logic [2:0] b2_w23_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_w23_lwd;
    always_ff @(posedge clk) begin b2_w23_lwe <= ld_v && ld_iq >= 14'd246 && ld_iq < 14'd254; b2_w23_lwa <= 3'(ld_iq - 14'd246); b2_w23_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b2_tab23 b2_w23_i (.clk(clk), .addr({b1_tag[0], b2_cnt[6], b2_cnt[5]}), .we(b2_w23_lwe), .wa(b2_w23_lwa), .wcol(1'b0), .wd(b2_w23_lwd), .q0(b2_w23));
    logic [59:0] b2_d0;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d0_i (.clk(clk), .din(b1_g0_o[0]), .dout(b2_d0));
    logic [59:0] b2_d1;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d1_i (.clk(clk), .din(b1_g0_o[1]), .dout(b2_d1));
    logic [59:0] b2_d2;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d2_i (.clk(clk), .din(b1_g0_o[2]), .dout(b2_d2));
    logic [59:0] b2_d3;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d3_i (.clk(clk), .din(b1_g0_o[3]), .dout(b2_d3));
    logic [59:0] b2_d4;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d4_i (.clk(clk), .din(b1_g1_o[0]), .dout(b2_d4));
    logic [59:0] b2_d5;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d5_i (.clk(clk), .din(b1_g1_o[1]), .dout(b2_d5));
    logic [59:0] b2_d6;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d6_i (.clk(clk), .din(b1_g1_o[2]), .dout(b2_d6));
    logic [59:0] b2_d7;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d7_i (.clk(clk), .din(b1_g1_o[3]), .dout(b2_d7));
    logic [59:0] b2_d8;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d8_i (.clk(clk), .din(b1_g2_o[0]), .dout(b2_d8));
    logic [59:0] b2_d9;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d9_i (.clk(clk), .din(b1_g2_o[1]), .dout(b2_d9));
    logic [59:0] b2_d10;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d10_i (.clk(clk), .din(b1_g2_o[2]), .dout(b2_d10));
    logic [59:0] b2_d11;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d11_i (.clk(clk), .din(b1_g2_o[3]), .dout(b2_d11));
    logic [59:0] b2_d12;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d12_i (.clk(clk), .din(b1_g3_o[0]), .dout(b2_d12));
    logic [59:0] b2_d13;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d13_i (.clk(clk), .din(b1_g3_o[1]), .dout(b2_d13));
    logic [59:0] b2_d14;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d14_i (.clk(clk), .din(b1_g3_o[2]), .dout(b2_d14));
    logic [59:0] b2_d15;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d15_i (.clk(clk), .din(b1_g3_o[3]), .dout(b2_d15));
    logic [59:0] b2_d16;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d16_i (.clk(clk), .din(b1_g4_o[0]), .dout(b2_d16));
    logic [59:0] b2_d17;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d17_i (.clk(clk), .din(b1_g4_o[1]), .dout(b2_d17));
    logic [59:0] b2_d18;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d18_i (.clk(clk), .din(b1_g4_o[2]), .dout(b2_d18));
    logic [59:0] b2_d19;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d19_i (.clk(clk), .din(b1_g4_o[3]), .dout(b2_d19));
    logic [59:0] b2_d20;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d20_i (.clk(clk), .din(b1_g5_o[0]), .dout(b2_d20));
    logic [59:0] b2_d21;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d21_i (.clk(clk), .din(b1_g5_o[1]), .dout(b2_d21));
    logic [59:0] b2_d22;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d22_i (.clk(clk), .din(b1_g5_o[2]), .dout(b2_d22));
    logic [59:0] b2_d23;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d23_i (.clk(clk), .din(b1_g5_o[3]), .dout(b2_d23));
    logic [59:0] b2_d24;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d24_i (.clk(clk), .din(b1_g6_o[0]), .dout(b2_d24));
    logic [59:0] b2_d25;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d25_i (.clk(clk), .din(b1_g6_o[1]), .dout(b2_d25));
    logic [59:0] b2_d26;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d26_i (.clk(clk), .din(b1_g6_o[2]), .dout(b2_d26));
    logic [59:0] b2_d27;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d27_i (.clk(clk), .din(b1_g6_o[3]), .dout(b2_d27));
    logic [59:0] b2_d28;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d28_i (.clk(clk), .din(b1_g7_o[0]), .dout(b2_d28));
    logic [59:0] b2_d29;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d29_i (.clk(clk), .din(b1_g7_o[1]), .dout(b2_d29));
    logic [59:0] b2_d30;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d30_i (.clk(clk), .din(b1_g7_o[2]), .dout(b2_d30));
    logic [59:0] b2_d31;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_d31_i (.clk(clk), .din(b1_g7_o[3]), .dout(b2_d31));
    logic [1:0] b2_pv_sr;
    always_ff @(posedge clk) b2_pv_sr <= rst ? '0 : {b2_pv_sr[0:0], b1_g0_v};
    logic b2_pv; assign b2_pv = b2_pv_sr[1];
    logic [0:0] b2_pg;
    MS_N12_q60_P32_tpm_dly_c #(.W(1), .D(2)) b2_pg_i (.clk(clk), .din(b1_tag), .dout(b2_pg));
    // block 2: pass 1, 8 x MS_N12_q60_P32_tpm_p1 (4-point), latency 36
    logic [59:0] b2_c0_y0, b2_c0_y1, b2_c0_y2, b2_c0_y3;
    logic b2_c0_v; logic b2_c0_di;
    MS_N12_q60_P32_tpm_p1 b2_c0 (.clk(clk), .rst(rst), .in_valid(b2_pv), .out_valid(b2_c0_v), .DIR(b2_pg[0]), .tw_0_0(b2_w0), .tw_0_1(b2_w0), .tw_1_0(b2_w1), .tw_1_1(b2_w2), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(b2_d0), .x_in_1(b2_d1), .x_in_2(b2_d2), .x_in_3(b2_d3), .y_out_0(b2_c0_y0), .y_out_1(b2_c0_y1), .y_out_2(b2_c0_y2), .y_out_3(b2_c0_y3));
    logic [59:0] b2_c1_y0, b2_c1_y1, b2_c1_y2, b2_c1_y3;
    logic b2_c1_v; logic b2_c1_di;
    MS_N12_q60_P32_tpm_p1 b2_c1 (.clk(clk), .rst(rst), .in_valid(b2_pv), .out_valid(b2_c1_v), .DIR(b2_pg[0]), .tw_0_0(b2_w3), .tw_0_1(b2_w3), .tw_1_0(b2_w4), .tw_1_1(b2_w5), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(b2_d4), .x_in_1(b2_d5), .x_in_2(b2_d6), .x_in_3(b2_d7), .y_out_0(b2_c1_y0), .y_out_1(b2_c1_y1), .y_out_2(b2_c1_y2), .y_out_3(b2_c1_y3));
    logic [59:0] b2_c2_y0, b2_c2_y1, b2_c2_y2, b2_c2_y3;
    logic b2_c2_v; logic b2_c2_di;
    MS_N12_q60_P32_tpm_p1 b2_c2 (.clk(clk), .rst(rst), .in_valid(b2_pv), .out_valid(b2_c2_v), .DIR(b2_pg[0]), .tw_0_0(b2_w6), .tw_0_1(b2_w6), .tw_1_0(b2_w7), .tw_1_1(b2_w8), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(b2_d8), .x_in_1(b2_d9), .x_in_2(b2_d10), .x_in_3(b2_d11), .y_out_0(b2_c2_y0), .y_out_1(b2_c2_y1), .y_out_2(b2_c2_y2), .y_out_3(b2_c2_y3));
    logic [59:0] b2_c3_y0, b2_c3_y1, b2_c3_y2, b2_c3_y3;
    logic b2_c3_v; logic b2_c3_di;
    MS_N12_q60_P32_tpm_p1 b2_c3 (.clk(clk), .rst(rst), .in_valid(b2_pv), .out_valid(b2_c3_v), .DIR(b2_pg[0]), .tw_0_0(b2_w9), .tw_0_1(b2_w9), .tw_1_0(b2_w10), .tw_1_1(b2_w11), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(b2_d12), .x_in_1(b2_d13), .x_in_2(b2_d14), .x_in_3(b2_d15), .y_out_0(b2_c3_y0), .y_out_1(b2_c3_y1), .y_out_2(b2_c3_y2), .y_out_3(b2_c3_y3));
    logic [59:0] b2_c4_y0, b2_c4_y1, b2_c4_y2, b2_c4_y3;
    logic b2_c4_v; logic b2_c4_di;
    MS_N12_q60_P32_tpm_p1 b2_c4 (.clk(clk), .rst(rst), .in_valid(b2_pv), .out_valid(b2_c4_v), .DIR(b2_pg[0]), .tw_0_0(b2_w12), .tw_0_1(b2_w12), .tw_1_0(b2_w13), .tw_1_1(b2_w14), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(b2_d16), .x_in_1(b2_d17), .x_in_2(b2_d18), .x_in_3(b2_d19), .y_out_0(b2_c4_y0), .y_out_1(b2_c4_y1), .y_out_2(b2_c4_y2), .y_out_3(b2_c4_y3));
    logic [59:0] b2_c5_y0, b2_c5_y1, b2_c5_y2, b2_c5_y3;
    logic b2_c5_v; logic b2_c5_di;
    MS_N12_q60_P32_tpm_p1 b2_c5 (.clk(clk), .rst(rst), .in_valid(b2_pv), .out_valid(b2_c5_v), .DIR(b2_pg[0]), .tw_0_0(b2_w15), .tw_0_1(b2_w15), .tw_1_0(b2_w16), .tw_1_1(b2_w17), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(b2_d20), .x_in_1(b2_d21), .x_in_2(b2_d22), .x_in_3(b2_d23), .y_out_0(b2_c5_y0), .y_out_1(b2_c5_y1), .y_out_2(b2_c5_y2), .y_out_3(b2_c5_y3));
    logic [59:0] b2_c6_y0, b2_c6_y1, b2_c6_y2, b2_c6_y3;
    logic b2_c6_v; logic b2_c6_di;
    MS_N12_q60_P32_tpm_p1 b2_c6 (.clk(clk), .rst(rst), .in_valid(b2_pv), .out_valid(b2_c6_v), .DIR(b2_pg[0]), .tw_0_0(b2_w18), .tw_0_1(b2_w18), .tw_1_0(b2_w19), .tw_1_1(b2_w20), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(b2_d24), .x_in_1(b2_d25), .x_in_2(b2_d26), .x_in_3(b2_d27), .y_out_0(b2_c6_y0), .y_out_1(b2_c6_y1), .y_out_2(b2_c6_y2), .y_out_3(b2_c6_y3));
    logic [59:0] b2_c7_y0, b2_c7_y1, b2_c7_y2, b2_c7_y3;
    logic b2_c7_v; logic b2_c7_di;
    MS_N12_q60_P32_tpm_p1 b2_c7 (.clk(clk), .rst(rst), .in_valid(b2_pv), .out_valid(b2_c7_v), .DIR(b2_pg[0]), .tw_0_0(b2_w21), .tw_0_1(b2_w21), .tw_1_0(b2_w22), .tw_1_1(b2_w23), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(b2_d28), .x_in_1(b2_d29), .x_in_2(b2_d30), .x_in_3(b2_d31), .y_out_0(b2_c7_y0), .y_out_1(b2_c7_y1), .y_out_2(b2_c7_y2), .y_out_3(b2_c7_y3));
    logic [0:0] b2_tag;
    MS_N12_q60_P32_tpm_dly_c #(.W(1), .D(34)) b2_tag_i (.clk(clk), .din(b2_pg), .dout(b2_tag));
    // block 3: lane-time transpose, lane bits [0, 1, 2, 3, 4] <-> cycle bits [0,5), 1 x S=32, latency 39
    logic [59:0] b3_g0_i [0:31]; logic [59:0] b3_g0_o [0:31]; logic b3_g0_v;
    assign b3_g0_i[0] = b2_c0_y0;
    assign b3_g0_i[1] = b2_c0_y1;
    assign b3_g0_i[2] = b2_c0_y2;
    assign b3_g0_i[3] = b2_c0_y3;
    assign b3_g0_i[4] = b2_c1_y0;
    assign b3_g0_i[5] = b2_c1_y1;
    assign b3_g0_i[6] = b2_c1_y2;
    assign b3_g0_i[7] = b2_c1_y3;
    assign b3_g0_i[8] = b2_c2_y0;
    assign b3_g0_i[9] = b2_c2_y1;
    assign b3_g0_i[10] = b2_c2_y2;
    assign b3_g0_i[11] = b2_c2_y3;
    assign b3_g0_i[12] = b2_c3_y0;
    assign b3_g0_i[13] = b2_c3_y1;
    assign b3_g0_i[14] = b2_c3_y2;
    assign b3_g0_i[15] = b2_c3_y3;
    assign b3_g0_i[16] = b2_c4_y0;
    assign b3_g0_i[17] = b2_c4_y1;
    assign b3_g0_i[18] = b2_c4_y2;
    assign b3_g0_i[19] = b2_c4_y3;
    assign b3_g0_i[20] = b2_c5_y0;
    assign b3_g0_i[21] = b2_c5_y1;
    assign b3_g0_i[22] = b2_c5_y2;
    assign b3_g0_i[23] = b2_c5_y3;
    assign b3_g0_i[24] = b2_c6_y0;
    assign b3_g0_i[25] = b2_c6_y1;
    assign b3_g0_i[26] = b2_c6_y2;
    assign b3_g0_i[27] = b2_c6_y3;
    assign b3_g0_i[28] = b2_c7_y0;
    assign b3_g0_i[29] = b2_c7_y1;
    assign b3_g0_i[30] = b2_c7_y2;
    assign b3_g0_i[31] = b2_c7_y3;
    lt_bmb_transpose #(.S(32), .LO(0), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h7), .RAM_STYLE("distributed")) b3_g0 (.clk(clk), .rst(rst), .data_valid(b2_c0_v), .data_in(b3_g0_i), .data_out_valid(b3_g0_v), .data_out(b3_g0_o));
    logic [0:0] b3_tag;
    MS_N12_q60_P32_tpm_dly_c #(.W(1), .D(39)) b3_tag_i (.clk(clk), .din(b2_tag), .dout(b3_tag));
    logic [6:0] b4_cnt;
    always_ff @(posedge clk) b4_cnt <= rst ? '0 : (b3_g0_v ? b4_cnt + 1'b1 : b4_cnt);
    logic [59:0] b4_w0;
    logic b4_w0_lwe; logic [7:0] b4_w0_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w0_lwd;
    always_ff @(posedge clk) begin b4_w0_lwe <= ld_v && ld_iq >= 14'd254 && ld_iq < 14'd510; b4_w0_lwa <= 8'(ld_iq - 14'd254); b4_w0_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab0 b4_w0_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w0_lwe), .wa(b4_w0_lwa), .wcol(1'b0), .wd(b4_w0_lwd), .q0(b4_w0));
    logic [59:0] b4_w1;
    logic b4_w1_lwe; logic [7:0] b4_w1_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w1_lwd;
    always_ff @(posedge clk) begin b4_w1_lwe <= ld_v && ld_iq >= 14'd510 && ld_iq < 14'd766; b4_w1_lwa <= 8'(ld_iq - 14'd510); b4_w1_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab1 b4_w1_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w1_lwe), .wa(b4_w1_lwa), .wcol(1'b0), .wd(b4_w1_lwd), .q0(b4_w1));
    logic [59:0] b4_w2;
    logic b4_w2_lwe; logic [7:0] b4_w2_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w2_lwd;
    always_ff @(posedge clk) begin b4_w2_lwe <= ld_v && ld_iq >= 14'd766 && ld_iq < 14'd1022; b4_w2_lwa <= 8'(ld_iq - 14'd766); b4_w2_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab2 b4_w2_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w2_lwe), .wa(b4_w2_lwa), .wcol(1'b0), .wd(b4_w2_lwd), .q0(b4_w2));
    logic [59:0] b4_w3;
    logic b4_w3_lwe; logic [7:0] b4_w3_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w3_lwd;
    always_ff @(posedge clk) begin b4_w3_lwe <= ld_v && ld_iq >= 14'd1022 && ld_iq < 14'd1278; b4_w3_lwa <= 8'(ld_iq - 14'd1022); b4_w3_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab3 b4_w3_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w3_lwe), .wa(b4_w3_lwa), .wcol(1'b0), .wd(b4_w3_lwd), .q0(b4_w3));
    logic [59:0] b4_w4;
    logic b4_w4_lwe; logic [7:0] b4_w4_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w4_lwd;
    always_ff @(posedge clk) begin b4_w4_lwe <= ld_v && ld_iq >= 14'd1278 && ld_iq < 14'd1534; b4_w4_lwa <= 8'(ld_iq - 14'd1278); b4_w4_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab4 b4_w4_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w4_lwe), .wa(b4_w4_lwa), .wcol(1'b0), .wd(b4_w4_lwd), .q0(b4_w4));
    logic [59:0] b4_w5;
    logic b4_w5_lwe; logic [7:0] b4_w5_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w5_lwd;
    always_ff @(posedge clk) begin b4_w5_lwe <= ld_v && ld_iq >= 14'd1534 && ld_iq < 14'd1790; b4_w5_lwa <= 8'(ld_iq - 14'd1534); b4_w5_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab5 b4_w5_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w5_lwe), .wa(b4_w5_lwa), .wcol(1'b0), .wd(b4_w5_lwd), .q0(b4_w5));
    logic [59:0] b4_w6;
    logic b4_w6_lwe; logic [7:0] b4_w6_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w6_lwd;
    always_ff @(posedge clk) begin b4_w6_lwe <= ld_v && ld_iq >= 14'd1790 && ld_iq < 14'd2046; b4_w6_lwa <= 8'(ld_iq - 14'd1790); b4_w6_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab6 b4_w6_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w6_lwe), .wa(b4_w6_lwa), .wcol(1'b0), .wd(b4_w6_lwd), .q0(b4_w6));
    logic [59:0] b4_w7;
    logic b4_w7_lwe; logic [7:0] b4_w7_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w7_lwd;
    always_ff @(posedge clk) begin b4_w7_lwe <= ld_v && ld_iq >= 14'd2046 && ld_iq < 14'd2302; b4_w7_lwa <= 8'(ld_iq - 14'd2046); b4_w7_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab7 b4_w7_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w7_lwe), .wa(b4_w7_lwa), .wcol(1'b0), .wd(b4_w7_lwd), .q0(b4_w7));
    logic [59:0] b4_w8;
    logic b4_w8_lwe; logic [7:0] b4_w8_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w8_lwd;
    always_ff @(posedge clk) begin b4_w8_lwe <= ld_v && ld_iq >= 14'd2302 && ld_iq < 14'd2558; b4_w8_lwa <= 8'(ld_iq - 14'd2302); b4_w8_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab8 b4_w8_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w8_lwe), .wa(b4_w8_lwa), .wcol(1'b0), .wd(b4_w8_lwd), .q0(b4_w8));
    logic [59:0] b4_w9;
    logic b4_w9_lwe; logic [7:0] b4_w9_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w9_lwd;
    always_ff @(posedge clk) begin b4_w9_lwe <= ld_v && ld_iq >= 14'd2558 && ld_iq < 14'd2814; b4_w9_lwa <= 8'(ld_iq - 14'd2558); b4_w9_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab9 b4_w9_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w9_lwe), .wa(b4_w9_lwa), .wcol(1'b0), .wd(b4_w9_lwd), .q0(b4_w9));
    logic [59:0] b4_w10;
    logic b4_w10_lwe; logic [7:0] b4_w10_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w10_lwd;
    always_ff @(posedge clk) begin b4_w10_lwe <= ld_v && ld_iq >= 14'd2814 && ld_iq < 14'd3070; b4_w10_lwa <= 8'(ld_iq - 14'd2814); b4_w10_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab10 b4_w10_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w10_lwe), .wa(b4_w10_lwa), .wcol(1'b0), .wd(b4_w10_lwd), .q0(b4_w10));
    logic [59:0] b4_w11;
    logic b4_w11_lwe; logic [7:0] b4_w11_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w11_lwd;
    always_ff @(posedge clk) begin b4_w11_lwe <= ld_v && ld_iq >= 14'd3070 && ld_iq < 14'd3326; b4_w11_lwa <= 8'(ld_iq - 14'd3070); b4_w11_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab11 b4_w11_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w11_lwe), .wa(b4_w11_lwa), .wcol(1'b0), .wd(b4_w11_lwd), .q0(b4_w11));
    logic [59:0] b4_w12;
    logic b4_w12_lwe; logic [7:0] b4_w12_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w12_lwd;
    always_ff @(posedge clk) begin b4_w12_lwe <= ld_v && ld_iq >= 14'd3326 && ld_iq < 14'd3582; b4_w12_lwa <= 8'(ld_iq - 14'd3326); b4_w12_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab12 b4_w12_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w12_lwe), .wa(b4_w12_lwa), .wcol(1'b0), .wd(b4_w12_lwd), .q0(b4_w12));
    logic [59:0] b4_w13;
    logic b4_w13_lwe; logic [7:0] b4_w13_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w13_lwd;
    always_ff @(posedge clk) begin b4_w13_lwe <= ld_v && ld_iq >= 14'd3582 && ld_iq < 14'd3838; b4_w13_lwa <= 8'(ld_iq - 14'd3582); b4_w13_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab13 b4_w13_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w13_lwe), .wa(b4_w13_lwa), .wcol(1'b0), .wd(b4_w13_lwd), .q0(b4_w13));
    logic [59:0] b4_w14;
    logic b4_w14_lwe; logic [7:0] b4_w14_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w14_lwd;
    always_ff @(posedge clk) begin b4_w14_lwe <= ld_v && ld_iq >= 14'd3838 && ld_iq < 14'd4094; b4_w14_lwa <= 8'(ld_iq - 14'd3838); b4_w14_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab14 b4_w14_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w14_lwe), .wa(b4_w14_lwa), .wcol(1'b0), .wd(b4_w14_lwd), .q0(b4_w14));
    logic [59:0] b4_w15;
    logic b4_w15_lwe; logic [7:0] b4_w15_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w15_lwd;
    always_ff @(posedge clk) begin b4_w15_lwe <= ld_v && ld_iq >= 14'd4094 && ld_iq < 14'd4350; b4_w15_lwa <= 8'(ld_iq - 14'd4094); b4_w15_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab15 b4_w15_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w15_lwe), .wa(b4_w15_lwa), .wcol(1'b0), .wd(b4_w15_lwd), .q0(b4_w15));
    logic [59:0] b4_w16;
    logic b4_w16_lwe; logic [7:0] b4_w16_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w16_lwd;
    always_ff @(posedge clk) begin b4_w16_lwe <= ld_v && ld_iq >= 14'd4350 && ld_iq < 14'd4606; b4_w16_lwa <= 8'(ld_iq - 14'd4350); b4_w16_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab16 b4_w16_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w16_lwe), .wa(b4_w16_lwa), .wcol(1'b0), .wd(b4_w16_lwd), .q0(b4_w16));
    logic [59:0] b4_w17;
    logic b4_w17_lwe; logic [7:0] b4_w17_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w17_lwd;
    always_ff @(posedge clk) begin b4_w17_lwe <= ld_v && ld_iq >= 14'd4606 && ld_iq < 14'd4862; b4_w17_lwa <= 8'(ld_iq - 14'd4606); b4_w17_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab17 b4_w17_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w17_lwe), .wa(b4_w17_lwa), .wcol(1'b0), .wd(b4_w17_lwd), .q0(b4_w17));
    logic [59:0] b4_w18;
    logic b4_w18_lwe; logic [7:0] b4_w18_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w18_lwd;
    always_ff @(posedge clk) begin b4_w18_lwe <= ld_v && ld_iq >= 14'd4862 && ld_iq < 14'd5118; b4_w18_lwa <= 8'(ld_iq - 14'd4862); b4_w18_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab18 b4_w18_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w18_lwe), .wa(b4_w18_lwa), .wcol(1'b0), .wd(b4_w18_lwd), .q0(b4_w18));
    logic [59:0] b4_w19;
    logic b4_w19_lwe; logic [7:0] b4_w19_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w19_lwd;
    always_ff @(posedge clk) begin b4_w19_lwe <= ld_v && ld_iq >= 14'd5118 && ld_iq < 14'd5374; b4_w19_lwa <= 8'(ld_iq - 14'd5118); b4_w19_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab19 b4_w19_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w19_lwe), .wa(b4_w19_lwa), .wcol(1'b0), .wd(b4_w19_lwd), .q0(b4_w19));
    logic [59:0] b4_w20;
    logic b4_w20_lwe; logic [7:0] b4_w20_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w20_lwd;
    always_ff @(posedge clk) begin b4_w20_lwe <= ld_v && ld_iq >= 14'd5374 && ld_iq < 14'd5630; b4_w20_lwa <= 8'(ld_iq - 14'd5374); b4_w20_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab20 b4_w20_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w20_lwe), .wa(b4_w20_lwa), .wcol(1'b0), .wd(b4_w20_lwd), .q0(b4_w20));
    logic [59:0] b4_w21;
    logic b4_w21_lwe; logic [7:0] b4_w21_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w21_lwd;
    always_ff @(posedge clk) begin b4_w21_lwe <= ld_v && ld_iq >= 14'd5630 && ld_iq < 14'd5886; b4_w21_lwa <= 8'(ld_iq - 14'd5630); b4_w21_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab21 b4_w21_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w21_lwe), .wa(b4_w21_lwa), .wcol(1'b0), .wd(b4_w21_lwd), .q0(b4_w21));
    logic [59:0] b4_w22;
    logic b4_w22_lwe; logic [7:0] b4_w22_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w22_lwd;
    always_ff @(posedge clk) begin b4_w22_lwe <= ld_v && ld_iq >= 14'd5886 && ld_iq < 14'd6142; b4_w22_lwa <= 8'(ld_iq - 14'd5886); b4_w22_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab22 b4_w22_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w22_lwe), .wa(b4_w22_lwa), .wcol(1'b0), .wd(b4_w22_lwd), .q0(b4_w22));
    logic [59:0] b4_w23;
    logic b4_w23_lwe; logic [7:0] b4_w23_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w23_lwd;
    always_ff @(posedge clk) begin b4_w23_lwe <= ld_v && ld_iq >= 14'd6142 && ld_iq < 14'd6398; b4_w23_lwa <= 8'(ld_iq - 14'd6142); b4_w23_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab23 b4_w23_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w23_lwe), .wa(b4_w23_lwa), .wcol(1'b0), .wd(b4_w23_lwd), .q0(b4_w23));
    logic [59:0] b4_w24;
    logic b4_w24_lwe; logic [7:0] b4_w24_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w24_lwd;
    always_ff @(posedge clk) begin b4_w24_lwe <= ld_v && ld_iq >= 14'd6398 && ld_iq < 14'd6654; b4_w24_lwa <= 8'(ld_iq - 14'd6398); b4_w24_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab24 b4_w24_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w24_lwe), .wa(b4_w24_lwa), .wcol(1'b0), .wd(b4_w24_lwd), .q0(b4_w24));
    logic [59:0] b4_w25;
    logic b4_w25_lwe; logic [7:0] b4_w25_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w25_lwd;
    always_ff @(posedge clk) begin b4_w25_lwe <= ld_v && ld_iq >= 14'd6654 && ld_iq < 14'd6910; b4_w25_lwa <= 8'(ld_iq - 14'd6654); b4_w25_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab25 b4_w25_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w25_lwe), .wa(b4_w25_lwa), .wcol(1'b0), .wd(b4_w25_lwd), .q0(b4_w25));
    logic [59:0] b4_w26;
    logic b4_w26_lwe; logic [7:0] b4_w26_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w26_lwd;
    always_ff @(posedge clk) begin b4_w26_lwe <= ld_v && ld_iq >= 14'd6910 && ld_iq < 14'd7166; b4_w26_lwa <= 8'(ld_iq - 14'd6910); b4_w26_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab26 b4_w26_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w26_lwe), .wa(b4_w26_lwa), .wcol(1'b0), .wd(b4_w26_lwd), .q0(b4_w26));
    logic [59:0] b4_w27;
    logic b4_w27_lwe; logic [7:0] b4_w27_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w27_lwd;
    always_ff @(posedge clk) begin b4_w27_lwe <= ld_v && ld_iq >= 14'd7166 && ld_iq < 14'd7422; b4_w27_lwa <= 8'(ld_iq - 14'd7166); b4_w27_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab27 b4_w27_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w27_lwe), .wa(b4_w27_lwa), .wcol(1'b0), .wd(b4_w27_lwd), .q0(b4_w27));
    logic [59:0] b4_w28;
    logic b4_w28_lwe; logic [7:0] b4_w28_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w28_lwd;
    always_ff @(posedge clk) begin b4_w28_lwe <= ld_v && ld_iq >= 14'd7422 && ld_iq < 14'd7678; b4_w28_lwa <= 8'(ld_iq - 14'd7422); b4_w28_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab28 b4_w28_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w28_lwe), .wa(b4_w28_lwa), .wcol(1'b0), .wd(b4_w28_lwd), .q0(b4_w28));
    logic [59:0] b4_w29;
    logic b4_w29_lwe; logic [7:0] b4_w29_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w29_lwd;
    always_ff @(posedge clk) begin b4_w29_lwe <= ld_v && ld_iq >= 14'd7678 && ld_iq < 14'd7934; b4_w29_lwa <= 8'(ld_iq - 14'd7678); b4_w29_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab29 b4_w29_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w29_lwe), .wa(b4_w29_lwa), .wcol(1'b0), .wd(b4_w29_lwd), .q0(b4_w29));
    logic [59:0] b4_w30;
    logic b4_w30_lwe; logic [7:0] b4_w30_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b4_w30_lwd;
    always_ff @(posedge clk) begin b4_w30_lwe <= ld_v && ld_iq >= 14'd7934 && ld_iq < 14'd8190; b4_w30_lwa <= 8'(ld_iq - 14'd7934); b4_w30_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_b4_tab30 b4_w30_i (.clk(clk), .addr({b3_tag[0], b4_cnt[6], b4_cnt[5], b4_cnt[4], b4_cnt[3], b4_cnt[2], b4_cnt[1], b4_cnt[0]}), .we(b4_w30_lwe), .wa(b4_w30_lwa), .wcol(1'b0), .wd(b4_w30_lwd), .q0(b4_w30));
    logic [59:0] b4_d0;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d0_i (.clk(clk), .din(b3_g0_o[0]), .dout(b4_d0));
    logic [59:0] b4_d1;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d1_i (.clk(clk), .din(b3_g0_o[1]), .dout(b4_d1));
    logic [59:0] b4_d2;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d2_i (.clk(clk), .din(b3_g0_o[2]), .dout(b4_d2));
    logic [59:0] b4_d3;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d3_i (.clk(clk), .din(b3_g0_o[3]), .dout(b4_d3));
    logic [59:0] b4_d4;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d4_i (.clk(clk), .din(b3_g0_o[4]), .dout(b4_d4));
    logic [59:0] b4_d5;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d5_i (.clk(clk), .din(b3_g0_o[5]), .dout(b4_d5));
    logic [59:0] b4_d6;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d6_i (.clk(clk), .din(b3_g0_o[6]), .dout(b4_d6));
    logic [59:0] b4_d7;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d7_i (.clk(clk), .din(b3_g0_o[7]), .dout(b4_d7));
    logic [59:0] b4_d8;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d8_i (.clk(clk), .din(b3_g0_o[8]), .dout(b4_d8));
    logic [59:0] b4_d9;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d9_i (.clk(clk), .din(b3_g0_o[9]), .dout(b4_d9));
    logic [59:0] b4_d10;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d10_i (.clk(clk), .din(b3_g0_o[10]), .dout(b4_d10));
    logic [59:0] b4_d11;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d11_i (.clk(clk), .din(b3_g0_o[11]), .dout(b4_d11));
    logic [59:0] b4_d12;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d12_i (.clk(clk), .din(b3_g0_o[12]), .dout(b4_d12));
    logic [59:0] b4_d13;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d13_i (.clk(clk), .din(b3_g0_o[13]), .dout(b4_d13));
    logic [59:0] b4_d14;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d14_i (.clk(clk), .din(b3_g0_o[14]), .dout(b4_d14));
    logic [59:0] b4_d15;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d15_i (.clk(clk), .din(b3_g0_o[15]), .dout(b4_d15));
    logic [59:0] b4_d16;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d16_i (.clk(clk), .din(b3_g0_o[16]), .dout(b4_d16));
    logic [59:0] b4_d17;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d17_i (.clk(clk), .din(b3_g0_o[17]), .dout(b4_d17));
    logic [59:0] b4_d18;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d18_i (.clk(clk), .din(b3_g0_o[18]), .dout(b4_d18));
    logic [59:0] b4_d19;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d19_i (.clk(clk), .din(b3_g0_o[19]), .dout(b4_d19));
    logic [59:0] b4_d20;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d20_i (.clk(clk), .din(b3_g0_o[20]), .dout(b4_d20));
    logic [59:0] b4_d21;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d21_i (.clk(clk), .din(b3_g0_o[21]), .dout(b4_d21));
    logic [59:0] b4_d22;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d22_i (.clk(clk), .din(b3_g0_o[22]), .dout(b4_d22));
    logic [59:0] b4_d23;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d23_i (.clk(clk), .din(b3_g0_o[23]), .dout(b4_d23));
    logic [59:0] b4_d24;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d24_i (.clk(clk), .din(b3_g0_o[24]), .dout(b4_d24));
    logic [59:0] b4_d25;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d25_i (.clk(clk), .din(b3_g0_o[25]), .dout(b4_d25));
    logic [59:0] b4_d26;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d26_i (.clk(clk), .din(b3_g0_o[26]), .dout(b4_d26));
    logic [59:0] b4_d27;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d27_i (.clk(clk), .din(b3_g0_o[27]), .dout(b4_d27));
    logic [59:0] b4_d28;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d28_i (.clk(clk), .din(b3_g0_o[28]), .dout(b4_d28));
    logic [59:0] b4_d29;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d29_i (.clk(clk), .din(b3_g0_o[29]), .dout(b4_d29));
    logic [59:0] b4_d30;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d30_i (.clk(clk), .din(b3_g0_o[30]), .dout(b4_d30));
    logic [59:0] b4_d31;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b4_d31_i (.clk(clk), .din(b3_g0_o[31]), .dout(b4_d31));
    logic [1:0] b4_pv_sr;
    always_ff @(posedge clk) b4_pv_sr <= rst ? '0 : {b4_pv_sr[0:0], b3_g0_v};
    logic b4_pv; assign b4_pv = b4_pv_sr[1];
    logic [0:0] b4_pg;
    MS_N12_q60_P32_tpm_dly_c #(.W(1), .D(2)) b4_pg_i (.clk(clk), .din(b3_tag), .dout(b4_pg));
    // block 4: pass 2, 1 x MS_N12_q60_P32_tpm_p2 (32-point), latency 84
    logic [59:0] b4_c0_y0, b4_c0_y1, b4_c0_y2, b4_c0_y3, b4_c0_y4, b4_c0_y5, b4_c0_y6, b4_c0_y7, b4_c0_y8, b4_c0_y9, b4_c0_y10, b4_c0_y11, b4_c0_y12, b4_c0_y13, b4_c0_y14, b4_c0_y15, b4_c0_y16, b4_c0_y17, b4_c0_y18, b4_c0_y19, b4_c0_y20, b4_c0_y21, b4_c0_y22, b4_c0_y23, b4_c0_y24, b4_c0_y25, b4_c0_y26, b4_c0_y27, b4_c0_y28, b4_c0_y29, b4_c0_y30, b4_c0_y31;
    logic b4_c0_v; logic b4_c0_di;
    MS_N12_q60_P32_tpm_p2 b4_c0 (.clk(clk), .rst(rst), .in_valid(b4_pv), .out_valid(b4_c0_v), .DIR(b4_pg[0]), .tw_0_0(b4_w0), .tw_0_1(b4_w0), .tw_0_2(b4_w0), .tw_0_3(b4_w0), .tw_0_4(b4_w0), .tw_0_5(b4_w0), .tw_0_6(b4_w0), .tw_0_7(b4_w0), .tw_0_8(b4_w0), .tw_0_9(b4_w0), .tw_0_10(b4_w0), .tw_0_11(b4_w0), .tw_0_12(b4_w0), .tw_0_13(b4_w0), .tw_0_14(b4_w0), .tw_0_15(b4_w0), .tw_1_0(b4_w1), .tw_1_1(b4_w2), .tw_1_2(b4_w1), .tw_1_3(b4_w2), .tw_1_4(b4_w1), .tw_1_5(b4_w2), .tw_1_6(b4_w1), .tw_1_7(b4_w2), .tw_1_8(b4_w1), .tw_1_9(b4_w2), .tw_1_10(b4_w1), .tw_1_11(b4_w2), .tw_1_12(b4_w1), .tw_1_13(b4_w2), .tw_1_14(b4_w1), .tw_1_15(b4_w2), .tw_2_0(b4_w3), .tw_2_1(b4_w4), .tw_2_2(b4_w5), .tw_2_3(b4_w6), .tw_2_4(b4_w3), .tw_2_5(b4_w4), .tw_2_6(b4_w5), .tw_2_7(b4_w6), .tw_2_8(b4_w3), .tw_2_9(b4_w4), .tw_2_10(b4_w5), .tw_2_11(b4_w6), .tw_2_12(b4_w3), .tw_2_13(b4_w4), .tw_2_14(b4_w5), .tw_2_15(b4_w6), .tw_3_0(b4_w7), .tw_3_1(b4_w8), .tw_3_2(b4_w9), .tw_3_3(b4_w10), .tw_3_4(b4_w11), .tw_3_5(b4_w12), .tw_3_6(b4_w13), .tw_3_7(b4_w14), .tw_3_8(b4_w7), .tw_3_9(b4_w8), .tw_3_10(b4_w9), .tw_3_11(b4_w10), .tw_3_12(b4_w11), .tw_3_13(b4_w12), .tw_3_14(b4_w13), .tw_3_15(b4_w14), .tw_4_0(b4_w15), .tw_4_1(b4_w16), .tw_4_2(b4_w17), .tw_4_3(b4_w18), .tw_4_4(b4_w19), .tw_4_5(b4_w20), .tw_4_6(b4_w21), .tw_4_7(b4_w22), .tw_4_8(b4_w23), .tw_4_9(b4_w24), .tw_4_10(b4_w25), .tw_4_11(b4_w26), .tw_4_12(b4_w27), .tw_4_13(b4_w28), .tw_4_14(b4_w29), .tw_4_15(b4_w30), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(b4_d0), .x_in_1(b4_d1), .x_in_2(b4_d2), .x_in_3(b4_d3), .x_in_4(b4_d4), .x_in_5(b4_d5), .x_in_6(b4_d6), .x_in_7(b4_d7), .x_in_8(b4_d8), .x_in_9(b4_d9), .x_in_10(b4_d10), .x_in_11(b4_d11), .x_in_12(b4_d12), .x_in_13(b4_d13), .x_in_14(b4_d14), .x_in_15(b4_d15), .x_in_16(b4_d16), .x_in_17(b4_d17), .x_in_18(b4_d18), .x_in_19(b4_d19), .x_in_20(b4_d20), .x_in_21(b4_d21), .x_in_22(b4_d22), .x_in_23(b4_d23), .x_in_24(b4_d24), .x_in_25(b4_d25), .x_in_26(b4_d26), .x_in_27(b4_d27), .x_in_28(b4_d28), .x_in_29(b4_d29), .x_in_30(b4_d30), .x_in_31(b4_d31), .y_out_0(b4_c0_y0), .y_out_1(b4_c0_y1), .y_out_2(b4_c0_y2), .y_out_3(b4_c0_y3), .y_out_4(b4_c0_y4), .y_out_5(b4_c0_y5), .y_out_6(b4_c0_y6), .y_out_7(b4_c0_y7), .y_out_8(b4_c0_y8), .y_out_9(b4_c0_y9), .y_out_10(b4_c0_y10), .y_out_11(b4_c0_y11), .y_out_12(b4_c0_y12), .y_out_13(b4_c0_y13), .y_out_14(b4_c0_y14), .y_out_15(b4_c0_y15), .y_out_16(b4_c0_y16), .y_out_17(b4_c0_y17), .y_out_18(b4_c0_y18), .y_out_19(b4_c0_y19), .y_out_20(b4_c0_y20), .y_out_21(b4_c0_y21), .y_out_22(b4_c0_y22), .y_out_23(b4_c0_y23), .y_out_24(b4_c0_y24), .y_out_25(b4_c0_y25), .y_out_26(b4_c0_y26), .y_out_27(b4_c0_y27), .y_out_28(b4_c0_y28), .y_out_29(b4_c0_y29), .y_out_30(b4_c0_y30), .y_out_31(b4_c0_y31));
    logic [0:0] b4_tag;
    MS_N12_q60_P32_tpm_dly_c #(.W(1), .D(82)) b4_tag_i (.clk(clk), .din(b4_pg), .dout(b4_tag));
    // block 5: twiddle stage 3, latency 15 (tables 2, multiplier 13)
    logic [6:0] b5_cnt;
    always_ff @(posedge clk) b5_cnt <= rst ? '0 : (b4_c0_v ? b5_cnt + 1'b1 : b5_cnt);
    logic [59:0] b5_t0;
    logic b5_t0_lwe; logic [7:0] b5_t0_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t0_lwd;
    always_ff @(posedge clk) begin b5_t0_lwe <= ld_v && ld_iq >= 14'd8190 && ld_iq < 14'd8446; b5_t0_lwa <= 8'(ld_iq - 14'd8190); b5_t0_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab0 b5_t0_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t0_lwe), .wa(b5_t0_lwa), .wcol(1'b0), .wd(b5_t0_lwd), .q0(b5_t0));
    logic [59:0] b5_t1;
    logic b5_t1_lwe; logic [7:0] b5_t1_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t1_lwd;
    always_ff @(posedge clk) begin b5_t1_lwe <= ld_v && ld_iq >= 14'd8446 && ld_iq < 14'd8702; b5_t1_lwa <= 8'(ld_iq - 14'd8446); b5_t1_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab1 b5_t1_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t1_lwe), .wa(b5_t1_lwa), .wcol(1'b0), .wd(b5_t1_lwd), .q0(b5_t1));
    logic [59:0] b5_t2;
    logic b5_t2_lwe; logic [7:0] b5_t2_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t2_lwd;
    always_ff @(posedge clk) begin b5_t2_lwe <= ld_v && ld_iq >= 14'd8702 && ld_iq < 14'd8958; b5_t2_lwa <= 8'(ld_iq - 14'd8702); b5_t2_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab2 b5_t2_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t2_lwe), .wa(b5_t2_lwa), .wcol(1'b0), .wd(b5_t2_lwd), .q0(b5_t2));
    logic [59:0] b5_t3;
    logic b5_t3_lwe; logic [7:0] b5_t3_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t3_lwd;
    always_ff @(posedge clk) begin b5_t3_lwe <= ld_v && ld_iq >= 14'd8958 && ld_iq < 14'd9214; b5_t3_lwa <= 8'(ld_iq - 14'd8958); b5_t3_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab3 b5_t3_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t3_lwe), .wa(b5_t3_lwa), .wcol(1'b0), .wd(b5_t3_lwd), .q0(b5_t3));
    logic [59:0] b5_t4;
    logic b5_t4_lwe; logic [7:0] b5_t4_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t4_lwd;
    always_ff @(posedge clk) begin b5_t4_lwe <= ld_v && ld_iq >= 14'd9214 && ld_iq < 14'd9470; b5_t4_lwa <= 8'(ld_iq - 14'd9214); b5_t4_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab4 b5_t4_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t4_lwe), .wa(b5_t4_lwa), .wcol(1'b0), .wd(b5_t4_lwd), .q0(b5_t4));
    logic [59:0] b5_t5;
    logic b5_t5_lwe; logic [7:0] b5_t5_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t5_lwd;
    always_ff @(posedge clk) begin b5_t5_lwe <= ld_v && ld_iq >= 14'd9470 && ld_iq < 14'd9726; b5_t5_lwa <= 8'(ld_iq - 14'd9470); b5_t5_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab5 b5_t5_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t5_lwe), .wa(b5_t5_lwa), .wcol(1'b0), .wd(b5_t5_lwd), .q0(b5_t5));
    logic [59:0] b5_t6;
    logic b5_t6_lwe; logic [7:0] b5_t6_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t6_lwd;
    always_ff @(posedge clk) begin b5_t6_lwe <= ld_v && ld_iq >= 14'd9726 && ld_iq < 14'd9982; b5_t6_lwa <= 8'(ld_iq - 14'd9726); b5_t6_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab6 b5_t6_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t6_lwe), .wa(b5_t6_lwa), .wcol(1'b0), .wd(b5_t6_lwd), .q0(b5_t6));
    logic [59:0] b5_t7;
    logic b5_t7_lwe; logic [7:0] b5_t7_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t7_lwd;
    always_ff @(posedge clk) begin b5_t7_lwe <= ld_v && ld_iq >= 14'd9982 && ld_iq < 14'd10238; b5_t7_lwa <= 8'(ld_iq - 14'd9982); b5_t7_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab7 b5_t7_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t7_lwe), .wa(b5_t7_lwa), .wcol(1'b0), .wd(b5_t7_lwd), .q0(b5_t7));
    logic [59:0] b5_t8;
    logic b5_t8_lwe; logic [7:0] b5_t8_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t8_lwd;
    always_ff @(posedge clk) begin b5_t8_lwe <= ld_v && ld_iq >= 14'd10238 && ld_iq < 14'd10494; b5_t8_lwa <= 8'(ld_iq - 14'd10238); b5_t8_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab8 b5_t8_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t8_lwe), .wa(b5_t8_lwa), .wcol(1'b0), .wd(b5_t8_lwd), .q0(b5_t8));
    logic [59:0] b5_t9;
    logic b5_t9_lwe; logic [7:0] b5_t9_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t9_lwd;
    always_ff @(posedge clk) begin b5_t9_lwe <= ld_v && ld_iq >= 14'd10494 && ld_iq < 14'd10750; b5_t9_lwa <= 8'(ld_iq - 14'd10494); b5_t9_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab9 b5_t9_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t9_lwe), .wa(b5_t9_lwa), .wcol(1'b0), .wd(b5_t9_lwd), .q0(b5_t9));
    logic [59:0] b5_t10;
    logic b5_t10_lwe; logic [7:0] b5_t10_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t10_lwd;
    always_ff @(posedge clk) begin b5_t10_lwe <= ld_v && ld_iq >= 14'd10750 && ld_iq < 14'd11006; b5_t10_lwa <= 8'(ld_iq - 14'd10750); b5_t10_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab10 b5_t10_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t10_lwe), .wa(b5_t10_lwa), .wcol(1'b0), .wd(b5_t10_lwd), .q0(b5_t10));
    logic [59:0] b5_t11;
    logic b5_t11_lwe; logic [7:0] b5_t11_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t11_lwd;
    always_ff @(posedge clk) begin b5_t11_lwe <= ld_v && ld_iq >= 14'd11006 && ld_iq < 14'd11262; b5_t11_lwa <= 8'(ld_iq - 14'd11006); b5_t11_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab11 b5_t11_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t11_lwe), .wa(b5_t11_lwa), .wcol(1'b0), .wd(b5_t11_lwd), .q0(b5_t11));
    logic [59:0] b5_t12;
    logic b5_t12_lwe; logic [7:0] b5_t12_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t12_lwd;
    always_ff @(posedge clk) begin b5_t12_lwe <= ld_v && ld_iq >= 14'd11262 && ld_iq < 14'd11518; b5_t12_lwa <= 8'(ld_iq - 14'd11262); b5_t12_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab12 b5_t12_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t12_lwe), .wa(b5_t12_lwa), .wcol(1'b0), .wd(b5_t12_lwd), .q0(b5_t12));
    logic [59:0] b5_t13;
    logic b5_t13_lwe; logic [7:0] b5_t13_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t13_lwd;
    always_ff @(posedge clk) begin b5_t13_lwe <= ld_v && ld_iq >= 14'd11518 && ld_iq < 14'd11774; b5_t13_lwa <= 8'(ld_iq - 14'd11518); b5_t13_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab13 b5_t13_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t13_lwe), .wa(b5_t13_lwa), .wcol(1'b0), .wd(b5_t13_lwd), .q0(b5_t13));
    logic [59:0] b5_t14;
    logic b5_t14_lwe; logic [7:0] b5_t14_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t14_lwd;
    always_ff @(posedge clk) begin b5_t14_lwe <= ld_v && ld_iq >= 14'd11774 && ld_iq < 14'd12030; b5_t14_lwa <= 8'(ld_iq - 14'd11774); b5_t14_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab14 b5_t14_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t14_lwe), .wa(b5_t14_lwa), .wcol(1'b0), .wd(b5_t14_lwd), .q0(b5_t14));
    logic [59:0] b5_t15;
    logic b5_t15_lwe; logic [7:0] b5_t15_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t15_lwd;
    always_ff @(posedge clk) begin b5_t15_lwe <= ld_v && ld_iq >= 14'd12030 && ld_iq < 14'd12286; b5_t15_lwa <= 8'(ld_iq - 14'd12030); b5_t15_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab15 b5_t15_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t15_lwe), .wa(b5_t15_lwa), .wcol(1'b0), .wd(b5_t15_lwd), .q0(b5_t15));
    logic [59:0] b5_t16;
    logic b5_t16_lwe; logic [7:0] b5_t16_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t16_lwd;
    always_ff @(posedge clk) begin b5_t16_lwe <= ld_v && ld_iq >= 14'd12286 && ld_iq < 14'd12542; b5_t16_lwa <= 8'(ld_iq - 14'd12286); b5_t16_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab16 b5_t16_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t16_lwe), .wa(b5_t16_lwa), .wcol(1'b0), .wd(b5_t16_lwd), .q0(b5_t16));
    logic [59:0] b5_t17;
    logic b5_t17_lwe; logic [7:0] b5_t17_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t17_lwd;
    always_ff @(posedge clk) begin b5_t17_lwe <= ld_v && ld_iq >= 14'd12542 && ld_iq < 14'd12798; b5_t17_lwa <= 8'(ld_iq - 14'd12542); b5_t17_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab17 b5_t17_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t17_lwe), .wa(b5_t17_lwa), .wcol(1'b0), .wd(b5_t17_lwd), .q0(b5_t17));
    logic [59:0] b5_t18;
    logic b5_t18_lwe; logic [7:0] b5_t18_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t18_lwd;
    always_ff @(posedge clk) begin b5_t18_lwe <= ld_v && ld_iq >= 14'd12798 && ld_iq < 14'd13054; b5_t18_lwa <= 8'(ld_iq - 14'd12798); b5_t18_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab18 b5_t18_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t18_lwe), .wa(b5_t18_lwa), .wcol(1'b0), .wd(b5_t18_lwd), .q0(b5_t18));
    logic [59:0] b5_t19;
    logic b5_t19_lwe; logic [7:0] b5_t19_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t19_lwd;
    always_ff @(posedge clk) begin b5_t19_lwe <= ld_v && ld_iq >= 14'd13054 && ld_iq < 14'd13310; b5_t19_lwa <= 8'(ld_iq - 14'd13054); b5_t19_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab19 b5_t19_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t19_lwe), .wa(b5_t19_lwa), .wcol(1'b0), .wd(b5_t19_lwd), .q0(b5_t19));
    logic [59:0] b5_t20;
    logic b5_t20_lwe; logic [7:0] b5_t20_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t20_lwd;
    always_ff @(posedge clk) begin b5_t20_lwe <= ld_v && ld_iq >= 14'd13310 && ld_iq < 14'd13566; b5_t20_lwa <= 8'(ld_iq - 14'd13310); b5_t20_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab20 b5_t20_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t20_lwe), .wa(b5_t20_lwa), .wcol(1'b0), .wd(b5_t20_lwd), .q0(b5_t20));
    logic [59:0] b5_t21;
    logic b5_t21_lwe; logic [7:0] b5_t21_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t21_lwd;
    always_ff @(posedge clk) begin b5_t21_lwe <= ld_v && ld_iq >= 14'd13566 && ld_iq < 14'd13822; b5_t21_lwa <= 8'(ld_iq - 14'd13566); b5_t21_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab21 b5_t21_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t21_lwe), .wa(b5_t21_lwa), .wcol(1'b0), .wd(b5_t21_lwd), .q0(b5_t21));
    logic [59:0] b5_t22;
    logic b5_t22_lwe; logic [7:0] b5_t22_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t22_lwd;
    always_ff @(posedge clk) begin b5_t22_lwe <= ld_v && ld_iq >= 14'd13822 && ld_iq < 14'd14078; b5_t22_lwa <= 8'(ld_iq - 14'd13822); b5_t22_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab22 b5_t22_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t22_lwe), .wa(b5_t22_lwa), .wcol(1'b0), .wd(b5_t22_lwd), .q0(b5_t22));
    logic [59:0] b5_t23;
    logic b5_t23_lwe; logic [7:0] b5_t23_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t23_lwd;
    always_ff @(posedge clk) begin b5_t23_lwe <= ld_v && ld_iq >= 14'd14078 && ld_iq < 14'd14334; b5_t23_lwa <= 8'(ld_iq - 14'd14078); b5_t23_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab23 b5_t23_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t23_lwe), .wa(b5_t23_lwa), .wcol(1'b0), .wd(b5_t23_lwd), .q0(b5_t23));
    logic [59:0] b5_t24;
    logic b5_t24_lwe; logic [7:0] b5_t24_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t24_lwd;
    always_ff @(posedge clk) begin b5_t24_lwe <= ld_v && ld_iq >= 14'd14334 && ld_iq < 14'd14590; b5_t24_lwa <= 8'(ld_iq - 14'd14334); b5_t24_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab24 b5_t24_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t24_lwe), .wa(b5_t24_lwa), .wcol(1'b0), .wd(b5_t24_lwd), .q0(b5_t24));
    logic [59:0] b5_t25;
    logic b5_t25_lwe; logic [7:0] b5_t25_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t25_lwd;
    always_ff @(posedge clk) begin b5_t25_lwe <= ld_v && ld_iq >= 14'd14590 && ld_iq < 14'd14846; b5_t25_lwa <= 8'(ld_iq - 14'd14590); b5_t25_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab25 b5_t25_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t25_lwe), .wa(b5_t25_lwa), .wcol(1'b0), .wd(b5_t25_lwd), .q0(b5_t25));
    logic [59:0] b5_t26;
    logic b5_t26_lwe; logic [7:0] b5_t26_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t26_lwd;
    always_ff @(posedge clk) begin b5_t26_lwe <= ld_v && ld_iq >= 14'd14846 && ld_iq < 14'd15102; b5_t26_lwa <= 8'(ld_iq - 14'd14846); b5_t26_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab26 b5_t26_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t26_lwe), .wa(b5_t26_lwa), .wcol(1'b0), .wd(b5_t26_lwd), .q0(b5_t26));
    logic [59:0] b5_t27;
    logic b5_t27_lwe; logic [7:0] b5_t27_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t27_lwd;
    always_ff @(posedge clk) begin b5_t27_lwe <= ld_v && ld_iq >= 14'd15102 && ld_iq < 14'd15358; b5_t27_lwa <= 8'(ld_iq - 14'd15102); b5_t27_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab27 b5_t27_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t27_lwe), .wa(b5_t27_lwa), .wcol(1'b0), .wd(b5_t27_lwd), .q0(b5_t27));
    logic [59:0] b5_t28;
    logic b5_t28_lwe; logic [7:0] b5_t28_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t28_lwd;
    always_ff @(posedge clk) begin b5_t28_lwe <= ld_v && ld_iq >= 14'd15358 && ld_iq < 14'd15614; b5_t28_lwa <= 8'(ld_iq - 14'd15358); b5_t28_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab28 b5_t28_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t28_lwe), .wa(b5_t28_lwa), .wcol(1'b0), .wd(b5_t28_lwd), .q0(b5_t28));
    logic [59:0] b5_t29;
    logic b5_t29_lwe; logic [7:0] b5_t29_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t29_lwd;
    always_ff @(posedge clk) begin b5_t29_lwe <= ld_v && ld_iq >= 14'd15614 && ld_iq < 14'd15870; b5_t29_lwa <= 8'(ld_iq - 14'd15614); b5_t29_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab29 b5_t29_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t29_lwe), .wa(b5_t29_lwa), .wcol(1'b0), .wd(b5_t29_lwd), .q0(b5_t29));
    logic [59:0] b5_t30;
    logic b5_t30_lwe; logic [7:0] b5_t30_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t30_lwd;
    always_ff @(posedge clk) begin b5_t30_lwe <= ld_v && ld_iq >= 14'd15870 && ld_iq < 14'd16126; b5_t30_lwa <= 8'(ld_iq - 14'd15870); b5_t30_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab30 b5_t30_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t30_lwe), .wa(b5_t30_lwa), .wcol(1'b0), .wd(b5_t30_lwd), .q0(b5_t30));
    logic [59:0] b5_t31;
    logic b5_t31_lwe; logic [7:0] b5_t31_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t31_lwd;
    always_ff @(posedge clk) begin b5_t31_lwe <= ld_v && ld_iq >= 14'd16126 && ld_iq < 14'd16382; b5_t31_lwa <= 8'(ld_iq - 14'd16126); b5_t31_lwd <= ld_d[59:0]; end
    MS_N12_q60_P32_tpm_tw3_tab31 b5_t31_i (.clk(clk), .addr({b4_tag[0], b5_cnt[6], b5_cnt[5], b5_cnt[4], b5_cnt[3], b5_cnt[2], b5_cnt[1], b5_cnt[0]}), .we(b5_t31_lwe), .wa(b5_t31_lwa), .wcol(1'b0), .wd(b5_t31_lwd), .q0(b5_t31));
    logic [59:0] b5_l0_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l0_a_i (.clk(clk), .din(b4_c0_y0), .dout(b5_l0_a));
    logic [59:0] b5_l0_p;
    MS_N12_q60_P32_tpm_twmul b5_l0_mul (.clk(clk), .A(b5_l0_a), .B(b5_t0), .QH(QH[16:0]), .P(b5_l0_p));
    logic [59:0] b5_l1_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l1_a_i (.clk(clk), .din(b4_c0_y1), .dout(b5_l1_a));
    logic [59:0] b5_l1_p;
    MS_N12_q60_P32_tpm_twmul b5_l1_mul (.clk(clk), .A(b5_l1_a), .B(b5_t1), .QH(QH[16:0]), .P(b5_l1_p));
    logic [59:0] b5_l2_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l2_a_i (.clk(clk), .din(b4_c0_y2), .dout(b5_l2_a));
    logic [59:0] b5_l2_p;
    MS_N12_q60_P32_tpm_twmul b5_l2_mul (.clk(clk), .A(b5_l2_a), .B(b5_t2), .QH(QH[16:0]), .P(b5_l2_p));
    logic [59:0] b5_l3_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l3_a_i (.clk(clk), .din(b4_c0_y3), .dout(b5_l3_a));
    logic [59:0] b5_l3_p;
    MS_N12_q60_P32_tpm_twmul b5_l3_mul (.clk(clk), .A(b5_l3_a), .B(b5_t3), .QH(QH[16:0]), .P(b5_l3_p));
    logic [59:0] b5_l4_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l4_a_i (.clk(clk), .din(b4_c0_y4), .dout(b5_l4_a));
    logic [59:0] b5_l4_p;
    MS_N12_q60_P32_tpm_twmul b5_l4_mul (.clk(clk), .A(b5_l4_a), .B(b5_t4), .QH(QH[16:0]), .P(b5_l4_p));
    logic [59:0] b5_l5_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l5_a_i (.clk(clk), .din(b4_c0_y5), .dout(b5_l5_a));
    logic [59:0] b5_l5_p;
    MS_N12_q60_P32_tpm_twmul b5_l5_mul (.clk(clk), .A(b5_l5_a), .B(b5_t5), .QH(QH[16:0]), .P(b5_l5_p));
    logic [59:0] b5_l6_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l6_a_i (.clk(clk), .din(b4_c0_y6), .dout(b5_l6_a));
    logic [59:0] b5_l6_p;
    MS_N12_q60_P32_tpm_twmul b5_l6_mul (.clk(clk), .A(b5_l6_a), .B(b5_t6), .QH(QH[16:0]), .P(b5_l6_p));
    logic [59:0] b5_l7_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l7_a_i (.clk(clk), .din(b4_c0_y7), .dout(b5_l7_a));
    logic [59:0] b5_l7_p;
    MS_N12_q60_P32_tpm_twmul b5_l7_mul (.clk(clk), .A(b5_l7_a), .B(b5_t7), .QH(QH[16:0]), .P(b5_l7_p));
    logic [59:0] b5_l8_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l8_a_i (.clk(clk), .din(b4_c0_y8), .dout(b5_l8_a));
    logic [59:0] b5_l8_p;
    MS_N12_q60_P32_tpm_twmul b5_l8_mul (.clk(clk), .A(b5_l8_a), .B(b5_t8), .QH(QH[16:0]), .P(b5_l8_p));
    logic [59:0] b5_l9_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l9_a_i (.clk(clk), .din(b4_c0_y9), .dout(b5_l9_a));
    logic [59:0] b5_l9_p;
    MS_N12_q60_P32_tpm_twmul b5_l9_mul (.clk(clk), .A(b5_l9_a), .B(b5_t9), .QH(QH[16:0]), .P(b5_l9_p));
    logic [59:0] b5_l10_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l10_a_i (.clk(clk), .din(b4_c0_y10), .dout(b5_l10_a));
    logic [59:0] b5_l10_p;
    MS_N12_q60_P32_tpm_twmul b5_l10_mul (.clk(clk), .A(b5_l10_a), .B(b5_t10), .QH(QH[16:0]), .P(b5_l10_p));
    logic [59:0] b5_l11_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l11_a_i (.clk(clk), .din(b4_c0_y11), .dout(b5_l11_a));
    logic [59:0] b5_l11_p;
    MS_N12_q60_P32_tpm_twmul b5_l11_mul (.clk(clk), .A(b5_l11_a), .B(b5_t11), .QH(QH[16:0]), .P(b5_l11_p));
    logic [59:0] b5_l12_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l12_a_i (.clk(clk), .din(b4_c0_y12), .dout(b5_l12_a));
    logic [59:0] b5_l12_p;
    MS_N12_q60_P32_tpm_twmul b5_l12_mul (.clk(clk), .A(b5_l12_a), .B(b5_t12), .QH(QH[16:0]), .P(b5_l12_p));
    logic [59:0] b5_l13_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l13_a_i (.clk(clk), .din(b4_c0_y13), .dout(b5_l13_a));
    logic [59:0] b5_l13_p;
    MS_N12_q60_P32_tpm_twmul b5_l13_mul (.clk(clk), .A(b5_l13_a), .B(b5_t13), .QH(QH[16:0]), .P(b5_l13_p));
    logic [59:0] b5_l14_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l14_a_i (.clk(clk), .din(b4_c0_y14), .dout(b5_l14_a));
    logic [59:0] b5_l14_p;
    MS_N12_q60_P32_tpm_twmul b5_l14_mul (.clk(clk), .A(b5_l14_a), .B(b5_t14), .QH(QH[16:0]), .P(b5_l14_p));
    logic [59:0] b5_l15_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l15_a_i (.clk(clk), .din(b4_c0_y15), .dout(b5_l15_a));
    logic [59:0] b5_l15_p;
    MS_N12_q60_P32_tpm_twmul b5_l15_mul (.clk(clk), .A(b5_l15_a), .B(b5_t15), .QH(QH[16:0]), .P(b5_l15_p));
    logic [59:0] b5_l16_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l16_a_i (.clk(clk), .din(b4_c0_y16), .dout(b5_l16_a));
    logic [59:0] b5_l16_p;
    MS_N12_q60_P32_tpm_twmul b5_l16_mul (.clk(clk), .A(b5_l16_a), .B(b5_t16), .QH(QH[16:0]), .P(b5_l16_p));
    logic [59:0] b5_l17_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l17_a_i (.clk(clk), .din(b4_c0_y17), .dout(b5_l17_a));
    logic [59:0] b5_l17_p;
    MS_N12_q60_P32_tpm_twmul b5_l17_mul (.clk(clk), .A(b5_l17_a), .B(b5_t17), .QH(QH[16:0]), .P(b5_l17_p));
    logic [59:0] b5_l18_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l18_a_i (.clk(clk), .din(b4_c0_y18), .dout(b5_l18_a));
    logic [59:0] b5_l18_p;
    MS_N12_q60_P32_tpm_twmul b5_l18_mul (.clk(clk), .A(b5_l18_a), .B(b5_t18), .QH(QH[16:0]), .P(b5_l18_p));
    logic [59:0] b5_l19_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l19_a_i (.clk(clk), .din(b4_c0_y19), .dout(b5_l19_a));
    logic [59:0] b5_l19_p;
    MS_N12_q60_P32_tpm_twmul b5_l19_mul (.clk(clk), .A(b5_l19_a), .B(b5_t19), .QH(QH[16:0]), .P(b5_l19_p));
    logic [59:0] b5_l20_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l20_a_i (.clk(clk), .din(b4_c0_y20), .dout(b5_l20_a));
    logic [59:0] b5_l20_p;
    MS_N12_q60_P32_tpm_twmul b5_l20_mul (.clk(clk), .A(b5_l20_a), .B(b5_t20), .QH(QH[16:0]), .P(b5_l20_p));
    logic [59:0] b5_l21_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l21_a_i (.clk(clk), .din(b4_c0_y21), .dout(b5_l21_a));
    logic [59:0] b5_l21_p;
    MS_N12_q60_P32_tpm_twmul b5_l21_mul (.clk(clk), .A(b5_l21_a), .B(b5_t21), .QH(QH[16:0]), .P(b5_l21_p));
    logic [59:0] b5_l22_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l22_a_i (.clk(clk), .din(b4_c0_y22), .dout(b5_l22_a));
    logic [59:0] b5_l22_p;
    MS_N12_q60_P32_tpm_twmul b5_l22_mul (.clk(clk), .A(b5_l22_a), .B(b5_t22), .QH(QH[16:0]), .P(b5_l22_p));
    logic [59:0] b5_l23_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l23_a_i (.clk(clk), .din(b4_c0_y23), .dout(b5_l23_a));
    logic [59:0] b5_l23_p;
    MS_N12_q60_P32_tpm_twmul b5_l23_mul (.clk(clk), .A(b5_l23_a), .B(b5_t23), .QH(QH[16:0]), .P(b5_l23_p));
    logic [59:0] b5_l24_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l24_a_i (.clk(clk), .din(b4_c0_y24), .dout(b5_l24_a));
    logic [59:0] b5_l24_p;
    MS_N12_q60_P32_tpm_twmul b5_l24_mul (.clk(clk), .A(b5_l24_a), .B(b5_t24), .QH(QH[16:0]), .P(b5_l24_p));
    logic [59:0] b5_l25_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l25_a_i (.clk(clk), .din(b4_c0_y25), .dout(b5_l25_a));
    logic [59:0] b5_l25_p;
    MS_N12_q60_P32_tpm_twmul b5_l25_mul (.clk(clk), .A(b5_l25_a), .B(b5_t25), .QH(QH[16:0]), .P(b5_l25_p));
    logic [59:0] b5_l26_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l26_a_i (.clk(clk), .din(b4_c0_y26), .dout(b5_l26_a));
    logic [59:0] b5_l26_p;
    MS_N12_q60_P32_tpm_twmul b5_l26_mul (.clk(clk), .A(b5_l26_a), .B(b5_t26), .QH(QH[16:0]), .P(b5_l26_p));
    logic [59:0] b5_l27_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l27_a_i (.clk(clk), .din(b4_c0_y27), .dout(b5_l27_a));
    logic [59:0] b5_l27_p;
    MS_N12_q60_P32_tpm_twmul b5_l27_mul (.clk(clk), .A(b5_l27_a), .B(b5_t27), .QH(QH[16:0]), .P(b5_l27_p));
    logic [59:0] b5_l28_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l28_a_i (.clk(clk), .din(b4_c0_y28), .dout(b5_l28_a));
    logic [59:0] b5_l28_p;
    MS_N12_q60_P32_tpm_twmul b5_l28_mul (.clk(clk), .A(b5_l28_a), .B(b5_t28), .QH(QH[16:0]), .P(b5_l28_p));
    logic [59:0] b5_l29_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l29_a_i (.clk(clk), .din(b4_c0_y29), .dout(b5_l29_a));
    logic [59:0] b5_l29_p;
    MS_N12_q60_P32_tpm_twmul b5_l29_mul (.clk(clk), .A(b5_l29_a), .B(b5_t29), .QH(QH[16:0]), .P(b5_l29_p));
    logic [59:0] b5_l30_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l30_a_i (.clk(clk), .din(b4_c0_y30), .dout(b5_l30_a));
    logic [59:0] b5_l30_p;
    MS_N12_q60_P32_tpm_twmul b5_l30_mul (.clk(clk), .A(b5_l30_a), .B(b5_t30), .QH(QH[16:0]), .P(b5_l30_p));
    logic [59:0] b5_l31_a;
    MS_N12_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l31_a_i (.clk(clk), .din(b4_c0_y31), .dout(b5_l31_a));
    logic [59:0] b5_l31_p;
    MS_N12_q60_P32_tpm_twmul b5_l31_mul (.clk(clk), .A(b5_l31_a), .B(b5_t31), .QH(QH[16:0]), .P(b5_l31_p));
    logic [14:0] b5_v_sr;
    always_ff @(posedge clk) b5_v_sr <= rst ? '0 : {b5_v_sr[13:0], b4_c0_v};
    logic b5_v; assign b5_v = b5_v_sr[14];
    logic [0:0] b5_tag;
    MS_N12_q60_P32_tpm_dly_c #(.W(1), .D(15)) b5_tag_i (.clk(clk), .din(b4_tag), .dout(b5_tag));
    assign out_valid = b5_v;
    assign dir_out = b5_tag[0];
    assign y_out_0 = b5_l0_p;
    assign y_out_1 = b5_l1_p;
    assign y_out_2 = b5_l2_p;
    assign y_out_3 = b5_l3_p;
    assign y_out_4 = b5_l4_p;
    assign y_out_5 = b5_l5_p;
    assign y_out_6 = b5_l6_p;
    assign y_out_7 = b5_l7_p;
    assign y_out_8 = b5_l8_p;
    assign y_out_9 = b5_l9_p;
    assign y_out_10 = b5_l10_p;
    assign y_out_11 = b5_l11_p;
    assign y_out_12 = b5_l12_p;
    assign y_out_13 = b5_l13_p;
    assign y_out_14 = b5_l14_p;
    assign y_out_15 = b5_l15_p;
    assign y_out_16 = b5_l16_p;
    assign y_out_17 = b5_l17_p;
    assign y_out_18 = b5_l18_p;
    assign y_out_19 = b5_l19_p;
    assign y_out_20 = b5_l20_p;
    assign y_out_21 = b5_l21_p;
    assign y_out_22 = b5_l22_p;
    assign y_out_23 = b5_l23_p;
    assign y_out_24 = b5_l24_p;
    assign y_out_25 = b5_l25_p;
    assign y_out_26 = b5_l26_p;
    assign y_out_27 = b5_l27_p;
    assign y_out_28 = b5_l28_p;
    assign y_out_29 = b5_l29_p;
    assign y_out_30 = b5_l30_p;
    assign y_out_31 = b5_l31_p;
endmodule
