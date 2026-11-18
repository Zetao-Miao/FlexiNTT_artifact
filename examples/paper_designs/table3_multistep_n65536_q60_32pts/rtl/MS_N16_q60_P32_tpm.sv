`timescale 1ns / 1ps
// MS_N16_q60_P32_tpm: multi-step NTT, N=65536, sizes [4, 32, 16, 32], 32 lanes, frame 2048 cycles, latency 2889, fixed q
module MS_N16_q60_P32_tpm (
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
    // load port: one word per ld_wen after ld_rst, 10272 words: the sub-NTT images, then the tables
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
    // block 0: pass 0, 8 x MS_N16_q60_P32_tpm_p0 (4-point), latency 33
    logic [59:0] b0_c0_y0, b0_c0_y1, b0_c0_y2, b0_c0_y3;
    logic b0_c0_v; logic b0_c0_di;
    logic b0_c0_lr, b0_c0_lw; (* equivalent_register_removal = "no" *) logic [59:0] b0_c0_ld;
    always_ff @(posedge clk) begin b0_c0_lr <= ld_r; b0_c0_lw <= ld_v && ld_iq >= 14'd0 && ld_iq < 14'd6; b0_c0_ld <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_p0 b0_c0 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c0_v), .DIR(g0[0]), .tw_rst(b0_c0_lr), .tw_wen(b0_c0_lw), .tw_wdata(b0_c0_ld), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(d0_0), .x_in_1(d0_8), .x_in_2(d0_16), .x_in_3(d0_24), .y_out_0(b0_c0_y0), .y_out_1(b0_c0_y1), .y_out_2(b0_c0_y2), .y_out_3(b0_c0_y3));
    logic [59:0] b0_c1_y0, b0_c1_y1, b0_c1_y2, b0_c1_y3;
    logic b0_c1_v; logic b0_c1_di;
    logic b0_c1_lr, b0_c1_lw; (* equivalent_register_removal = "no" *) logic [59:0] b0_c1_ld;
    always_ff @(posedge clk) begin b0_c1_lr <= ld_r; b0_c1_lw <= ld_v && ld_iq >= 14'd0 && ld_iq < 14'd6; b0_c1_ld <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_p0 b0_c1 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c1_v), .DIR(g0[0]), .tw_rst(b0_c1_lr), .tw_wen(b0_c1_lw), .tw_wdata(b0_c1_ld), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(d0_1), .x_in_1(d0_9), .x_in_2(d0_17), .x_in_3(d0_25), .y_out_0(b0_c1_y0), .y_out_1(b0_c1_y1), .y_out_2(b0_c1_y2), .y_out_3(b0_c1_y3));
    logic [59:0] b0_c2_y0, b0_c2_y1, b0_c2_y2, b0_c2_y3;
    logic b0_c2_v; logic b0_c2_di;
    logic b0_c2_lr, b0_c2_lw; (* equivalent_register_removal = "no" *) logic [59:0] b0_c2_ld;
    always_ff @(posedge clk) begin b0_c2_lr <= ld_r; b0_c2_lw <= ld_v && ld_iq >= 14'd0 && ld_iq < 14'd6; b0_c2_ld <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_p0 b0_c2 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c2_v), .DIR(g0[0]), .tw_rst(b0_c2_lr), .tw_wen(b0_c2_lw), .tw_wdata(b0_c2_ld), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(d0_2), .x_in_1(d0_10), .x_in_2(d0_18), .x_in_3(d0_26), .y_out_0(b0_c2_y0), .y_out_1(b0_c2_y1), .y_out_2(b0_c2_y2), .y_out_3(b0_c2_y3));
    logic [59:0] b0_c3_y0, b0_c3_y1, b0_c3_y2, b0_c3_y3;
    logic b0_c3_v; logic b0_c3_di;
    logic b0_c3_lr, b0_c3_lw; (* equivalent_register_removal = "no" *) logic [59:0] b0_c3_ld;
    always_ff @(posedge clk) begin b0_c3_lr <= ld_r; b0_c3_lw <= ld_v && ld_iq >= 14'd0 && ld_iq < 14'd6; b0_c3_ld <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_p0 b0_c3 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c3_v), .DIR(g0[0]), .tw_rst(b0_c3_lr), .tw_wen(b0_c3_lw), .tw_wdata(b0_c3_ld), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(d0_3), .x_in_1(d0_11), .x_in_2(d0_19), .x_in_3(d0_27), .y_out_0(b0_c3_y0), .y_out_1(b0_c3_y1), .y_out_2(b0_c3_y2), .y_out_3(b0_c3_y3));
    logic [59:0] b0_c4_y0, b0_c4_y1, b0_c4_y2, b0_c4_y3;
    logic b0_c4_v; logic b0_c4_di;
    logic b0_c4_lr, b0_c4_lw; (* equivalent_register_removal = "no" *) logic [59:0] b0_c4_ld;
    always_ff @(posedge clk) begin b0_c4_lr <= ld_r; b0_c4_lw <= ld_v && ld_iq >= 14'd0 && ld_iq < 14'd6; b0_c4_ld <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_p0 b0_c4 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c4_v), .DIR(g0[0]), .tw_rst(b0_c4_lr), .tw_wen(b0_c4_lw), .tw_wdata(b0_c4_ld), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(d0_4), .x_in_1(d0_12), .x_in_2(d0_20), .x_in_3(d0_28), .y_out_0(b0_c4_y0), .y_out_1(b0_c4_y1), .y_out_2(b0_c4_y2), .y_out_3(b0_c4_y3));
    logic [59:0] b0_c5_y0, b0_c5_y1, b0_c5_y2, b0_c5_y3;
    logic b0_c5_v; logic b0_c5_di;
    logic b0_c5_lr, b0_c5_lw; (* equivalent_register_removal = "no" *) logic [59:0] b0_c5_ld;
    always_ff @(posedge clk) begin b0_c5_lr <= ld_r; b0_c5_lw <= ld_v && ld_iq >= 14'd0 && ld_iq < 14'd6; b0_c5_ld <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_p0 b0_c5 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c5_v), .DIR(g0[0]), .tw_rst(b0_c5_lr), .tw_wen(b0_c5_lw), .tw_wdata(b0_c5_ld), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(d0_5), .x_in_1(d0_13), .x_in_2(d0_21), .x_in_3(d0_29), .y_out_0(b0_c5_y0), .y_out_1(b0_c5_y1), .y_out_2(b0_c5_y2), .y_out_3(b0_c5_y3));
    logic [59:0] b0_c6_y0, b0_c6_y1, b0_c6_y2, b0_c6_y3;
    logic b0_c6_v; logic b0_c6_di;
    logic b0_c6_lr, b0_c6_lw; (* equivalent_register_removal = "no" *) logic [59:0] b0_c6_ld;
    always_ff @(posedge clk) begin b0_c6_lr <= ld_r; b0_c6_lw <= ld_v && ld_iq >= 14'd0 && ld_iq < 14'd6; b0_c6_ld <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_p0 b0_c6 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c6_v), .DIR(g0[0]), .tw_rst(b0_c6_lr), .tw_wen(b0_c6_lw), .tw_wdata(b0_c6_ld), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(d0_6), .x_in_1(d0_14), .x_in_2(d0_22), .x_in_3(d0_30), .y_out_0(b0_c6_y0), .y_out_1(b0_c6_y1), .y_out_2(b0_c6_y2), .y_out_3(b0_c6_y3));
    logic [59:0] b0_c7_y0, b0_c7_y1, b0_c7_y2, b0_c7_y3;
    logic b0_c7_v; logic b0_c7_di;
    logic b0_c7_lr, b0_c7_lw; (* equivalent_register_removal = "no" *) logic [59:0] b0_c7_ld;
    always_ff @(posedge clk) begin b0_c7_lr <= ld_r; b0_c7_lw <= ld_v && ld_iq >= 14'd0 && ld_iq < 14'd6; b0_c7_ld <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_p0 b0_c7 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c7_v), .DIR(g0[0]), .tw_rst(b0_c7_lr), .tw_wen(b0_c7_lw), .tw_wdata(b0_c7_ld), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(d0_7), .x_in_1(d0_15), .x_in_2(d0_23), .x_in_3(d0_31), .y_out_0(b0_c7_y0), .y_out_1(b0_c7_y1), .y_out_2(b0_c7_y2), .y_out_3(b0_c7_y3));
    logic [0:0] b0_tag;
    MS_N16_q60_P32_tpm_dly_c #(.W(1), .D(33)) b0_tag_i (.clk(clk), .din(g0), .dout(b0_tag));
    // block 1: lane-time transpose, lane bits [3, 4] <-> cycle bits [9,11), 8 x S=4, latency 2051
    logic [59:0] b1_g0_i [0:3]; logic [59:0] b1_g0_o [0:3]; logic b1_g0_v;
    assign b1_g0_i[0] = b0_c0_y0;
    assign b1_g0_i[1] = b0_c0_y1;
    assign b1_g0_i[2] = b0_c0_y2;
    assign b1_g0_i[3] = b0_c0_y3;
    lt_bmb_transpose #(.S(4), .LO(9), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g0 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g0_i), .data_out_valid(b1_g0_v), .data_out(b1_g0_o));
    logic [59:0] b1_g1_i [0:3]; logic [59:0] b1_g1_o [0:3]; logic b1_g1_v;
    assign b1_g1_i[0] = b0_c1_y0;
    assign b1_g1_i[1] = b0_c1_y1;
    assign b1_g1_i[2] = b0_c1_y2;
    assign b1_g1_i[3] = b0_c1_y3;
    lt_bmb_transpose #(.S(4), .LO(9), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g1 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g1_i), .data_out_valid(b1_g1_v), .data_out(b1_g1_o));
    logic [59:0] b1_g2_i [0:3]; logic [59:0] b1_g2_o [0:3]; logic b1_g2_v;
    assign b1_g2_i[0] = b0_c2_y0;
    assign b1_g2_i[1] = b0_c2_y1;
    assign b1_g2_i[2] = b0_c2_y2;
    assign b1_g2_i[3] = b0_c2_y3;
    lt_bmb_transpose #(.S(4), .LO(9), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g2 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g2_i), .data_out_valid(b1_g2_v), .data_out(b1_g2_o));
    logic [59:0] b1_g3_i [0:3]; logic [59:0] b1_g3_o [0:3]; logic b1_g3_v;
    assign b1_g3_i[0] = b0_c3_y0;
    assign b1_g3_i[1] = b0_c3_y1;
    assign b1_g3_i[2] = b0_c3_y2;
    assign b1_g3_i[3] = b0_c3_y3;
    lt_bmb_transpose #(.S(4), .LO(9), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g3 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g3_i), .data_out_valid(b1_g3_v), .data_out(b1_g3_o));
    logic [59:0] b1_g4_i [0:3]; logic [59:0] b1_g4_o [0:3]; logic b1_g4_v;
    assign b1_g4_i[0] = b0_c4_y0;
    assign b1_g4_i[1] = b0_c4_y1;
    assign b1_g4_i[2] = b0_c4_y2;
    assign b1_g4_i[3] = b0_c4_y3;
    lt_bmb_transpose #(.S(4), .LO(9), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g4 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g4_i), .data_out_valid(b1_g4_v), .data_out(b1_g4_o));
    logic [59:0] b1_g5_i [0:3]; logic [59:0] b1_g5_o [0:3]; logic b1_g5_v;
    assign b1_g5_i[0] = b0_c5_y0;
    assign b1_g5_i[1] = b0_c5_y1;
    assign b1_g5_i[2] = b0_c5_y2;
    assign b1_g5_i[3] = b0_c5_y3;
    lt_bmb_transpose #(.S(4), .LO(9), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g5 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g5_i), .data_out_valid(b1_g5_v), .data_out(b1_g5_o));
    logic [59:0] b1_g6_i [0:3]; logic [59:0] b1_g6_o [0:3]; logic b1_g6_v;
    assign b1_g6_i[0] = b0_c6_y0;
    assign b1_g6_i[1] = b0_c6_y1;
    assign b1_g6_i[2] = b0_c6_y2;
    assign b1_g6_i[3] = b0_c6_y3;
    lt_bmb_transpose #(.S(4), .LO(9), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g6 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g6_i), .data_out_valid(b1_g6_v), .data_out(b1_g6_o));
    logic [59:0] b1_g7_i [0:3]; logic [59:0] b1_g7_o [0:3]; logic b1_g7_v;
    assign b1_g7_i[0] = b0_c7_y0;
    assign b1_g7_i[1] = b0_c7_y1;
    assign b1_g7_i[2] = b0_c7_y2;
    assign b1_g7_i[3] = b0_c7_y3;
    lt_bmb_transpose #(.S(4), .LO(9), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g7 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g7_i), .data_out_valid(b1_g7_v), .data_out(b1_g7_o));
    logic [0:0] b1_tag;
    MS_N16_q60_P32_tpm_dly_c #(.W(1), .D(2051)) b1_tag_i (.clk(clk), .din(b0_tag), .dout(b1_tag));
    // block 2: twiddle stage 1, latency 14 (tables 2, multiplier 12)
    logic [10:0] b2_cnt;
    always_ff @(posedge clk) b2_cnt <= rst ? '0 : (b1_g0_v ? b2_cnt + 1'b1 : b2_cnt);
    logic [59:0] b2_t0;
    logic b2_t0_lwe; logic [2:0] b2_t0_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t0_lwd;
    always_ff @(posedge clk) begin b2_t0_lwe <= ld_v && ld_iq >= 14'd144 && ld_iq < 14'd152; b2_t0_lwa <= 3'(ld_iq - 14'd144); b2_t0_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab0 b2_t0_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t0_lwe), .wa(b2_t0_lwa), .wcol(1'b0), .wd(b2_t0_lwd), .q0(b2_t0));
    logic [59:0] b2_t1;
    logic b2_t1_lwe; logic [2:0] b2_t1_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t1_lwd;
    always_ff @(posedge clk) begin b2_t1_lwe <= ld_v && ld_iq >= 14'd152 && ld_iq < 14'd160; b2_t1_lwa <= 3'(ld_iq - 14'd152); b2_t1_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab1 b2_t1_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t1_lwe), .wa(b2_t1_lwa), .wcol(1'b0), .wd(b2_t1_lwd), .q0(b2_t1));
    logic [59:0] b2_t2;
    logic b2_t2_lwe; logic [2:0] b2_t2_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t2_lwd;
    always_ff @(posedge clk) begin b2_t2_lwe <= ld_v && ld_iq >= 14'd160 && ld_iq < 14'd168; b2_t2_lwa <= 3'(ld_iq - 14'd160); b2_t2_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab2 b2_t2_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t2_lwe), .wa(b2_t2_lwa), .wcol(1'b0), .wd(b2_t2_lwd), .q0(b2_t2));
    logic [59:0] b2_t3;
    logic b2_t3_lwe; logic [2:0] b2_t3_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t3_lwd;
    always_ff @(posedge clk) begin b2_t3_lwe <= ld_v && ld_iq >= 14'd168 && ld_iq < 14'd176; b2_t3_lwa <= 3'(ld_iq - 14'd168); b2_t3_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab3 b2_t3_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t3_lwe), .wa(b2_t3_lwa), .wcol(1'b0), .wd(b2_t3_lwd), .q0(b2_t3));
    logic [59:0] b2_t4;
    logic b2_t4_lwe; logic [2:0] b2_t4_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t4_lwd;
    always_ff @(posedge clk) begin b2_t4_lwe <= ld_v && ld_iq >= 14'd176 && ld_iq < 14'd184; b2_t4_lwa <= 3'(ld_iq - 14'd176); b2_t4_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab4 b2_t4_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t4_lwe), .wa(b2_t4_lwa), .wcol(1'b0), .wd(b2_t4_lwd), .q0(b2_t4));
    logic [59:0] b2_t5;
    logic b2_t5_lwe; logic [2:0] b2_t5_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t5_lwd;
    always_ff @(posedge clk) begin b2_t5_lwe <= ld_v && ld_iq >= 14'd184 && ld_iq < 14'd192; b2_t5_lwa <= 3'(ld_iq - 14'd184); b2_t5_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab5 b2_t5_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t5_lwe), .wa(b2_t5_lwa), .wcol(1'b0), .wd(b2_t5_lwd), .q0(b2_t5));
    logic [59:0] b2_t6;
    logic b2_t6_lwe; logic [2:0] b2_t6_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t6_lwd;
    always_ff @(posedge clk) begin b2_t6_lwe <= ld_v && ld_iq >= 14'd192 && ld_iq < 14'd200; b2_t6_lwa <= 3'(ld_iq - 14'd192); b2_t6_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab6 b2_t6_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t6_lwe), .wa(b2_t6_lwa), .wcol(1'b0), .wd(b2_t6_lwd), .q0(b2_t6));
    logic [59:0] b2_t7;
    logic b2_t7_lwe; logic [2:0] b2_t7_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t7_lwd;
    always_ff @(posedge clk) begin b2_t7_lwe <= ld_v && ld_iq >= 14'd200 && ld_iq < 14'd208; b2_t7_lwa <= 3'(ld_iq - 14'd200); b2_t7_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab7 b2_t7_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t7_lwe), .wa(b2_t7_lwa), .wcol(1'b0), .wd(b2_t7_lwd), .q0(b2_t7));
    logic [59:0] b2_t8;
    logic b2_t8_lwe; logic [2:0] b2_t8_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t8_lwd;
    always_ff @(posedge clk) begin b2_t8_lwe <= ld_v && ld_iq >= 14'd208 && ld_iq < 14'd216; b2_t8_lwa <= 3'(ld_iq - 14'd208); b2_t8_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab8 b2_t8_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t8_lwe), .wa(b2_t8_lwa), .wcol(1'b0), .wd(b2_t8_lwd), .q0(b2_t8));
    logic [59:0] b2_t9;
    logic b2_t9_lwe; logic [2:0] b2_t9_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t9_lwd;
    always_ff @(posedge clk) begin b2_t9_lwe <= ld_v && ld_iq >= 14'd216 && ld_iq < 14'd224; b2_t9_lwa <= 3'(ld_iq - 14'd216); b2_t9_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab9 b2_t9_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t9_lwe), .wa(b2_t9_lwa), .wcol(1'b0), .wd(b2_t9_lwd), .q0(b2_t9));
    logic [59:0] b2_t10;
    logic b2_t10_lwe; logic [2:0] b2_t10_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t10_lwd;
    always_ff @(posedge clk) begin b2_t10_lwe <= ld_v && ld_iq >= 14'd224 && ld_iq < 14'd232; b2_t10_lwa <= 3'(ld_iq - 14'd224); b2_t10_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab10 b2_t10_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t10_lwe), .wa(b2_t10_lwa), .wcol(1'b0), .wd(b2_t10_lwd), .q0(b2_t10));
    logic [59:0] b2_t11;
    logic b2_t11_lwe; logic [2:0] b2_t11_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t11_lwd;
    always_ff @(posedge clk) begin b2_t11_lwe <= ld_v && ld_iq >= 14'd232 && ld_iq < 14'd240; b2_t11_lwa <= 3'(ld_iq - 14'd232); b2_t11_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab11 b2_t11_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t11_lwe), .wa(b2_t11_lwa), .wcol(1'b0), .wd(b2_t11_lwd), .q0(b2_t11));
    logic [59:0] b2_t12;
    logic b2_t12_lwe; logic [2:0] b2_t12_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t12_lwd;
    always_ff @(posedge clk) begin b2_t12_lwe <= ld_v && ld_iq >= 14'd240 && ld_iq < 14'd248; b2_t12_lwa <= 3'(ld_iq - 14'd240); b2_t12_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab12 b2_t12_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t12_lwe), .wa(b2_t12_lwa), .wcol(1'b0), .wd(b2_t12_lwd), .q0(b2_t12));
    logic [59:0] b2_t13;
    logic b2_t13_lwe; logic [2:0] b2_t13_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t13_lwd;
    always_ff @(posedge clk) begin b2_t13_lwe <= ld_v && ld_iq >= 14'd248 && ld_iq < 14'd256; b2_t13_lwa <= 3'(ld_iq - 14'd248); b2_t13_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab13 b2_t13_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t13_lwe), .wa(b2_t13_lwa), .wcol(1'b0), .wd(b2_t13_lwd), .q0(b2_t13));
    logic [59:0] b2_t14;
    logic b2_t14_lwe; logic [2:0] b2_t14_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t14_lwd;
    always_ff @(posedge clk) begin b2_t14_lwe <= ld_v && ld_iq >= 14'd256 && ld_iq < 14'd264; b2_t14_lwa <= 3'(ld_iq - 14'd256); b2_t14_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab14 b2_t14_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t14_lwe), .wa(b2_t14_lwa), .wcol(1'b0), .wd(b2_t14_lwd), .q0(b2_t14));
    logic [59:0] b2_t15;
    logic b2_t15_lwe; logic [2:0] b2_t15_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t15_lwd;
    always_ff @(posedge clk) begin b2_t15_lwe <= ld_v && ld_iq >= 14'd264 && ld_iq < 14'd272; b2_t15_lwa <= 3'(ld_iq - 14'd264); b2_t15_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab15 b2_t15_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t15_lwe), .wa(b2_t15_lwa), .wcol(1'b0), .wd(b2_t15_lwd), .q0(b2_t15));
    logic [59:0] b2_t16;
    logic b2_t16_lwe; logic [2:0] b2_t16_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t16_lwd;
    always_ff @(posedge clk) begin b2_t16_lwe <= ld_v && ld_iq >= 14'd272 && ld_iq < 14'd280; b2_t16_lwa <= 3'(ld_iq - 14'd272); b2_t16_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab16 b2_t16_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t16_lwe), .wa(b2_t16_lwa), .wcol(1'b0), .wd(b2_t16_lwd), .q0(b2_t16));
    logic [59:0] b2_t17;
    logic b2_t17_lwe; logic [2:0] b2_t17_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t17_lwd;
    always_ff @(posedge clk) begin b2_t17_lwe <= ld_v && ld_iq >= 14'd280 && ld_iq < 14'd288; b2_t17_lwa <= 3'(ld_iq - 14'd280); b2_t17_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab17 b2_t17_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t17_lwe), .wa(b2_t17_lwa), .wcol(1'b0), .wd(b2_t17_lwd), .q0(b2_t17));
    logic [59:0] b2_t18;
    logic b2_t18_lwe; logic [2:0] b2_t18_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t18_lwd;
    always_ff @(posedge clk) begin b2_t18_lwe <= ld_v && ld_iq >= 14'd288 && ld_iq < 14'd296; b2_t18_lwa <= 3'(ld_iq - 14'd288); b2_t18_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab18 b2_t18_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t18_lwe), .wa(b2_t18_lwa), .wcol(1'b0), .wd(b2_t18_lwd), .q0(b2_t18));
    logic [59:0] b2_t19;
    logic b2_t19_lwe; logic [2:0] b2_t19_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t19_lwd;
    always_ff @(posedge clk) begin b2_t19_lwe <= ld_v && ld_iq >= 14'd296 && ld_iq < 14'd304; b2_t19_lwa <= 3'(ld_iq - 14'd296); b2_t19_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab19 b2_t19_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t19_lwe), .wa(b2_t19_lwa), .wcol(1'b0), .wd(b2_t19_lwd), .q0(b2_t19));
    logic [59:0] b2_t20;
    logic b2_t20_lwe; logic [2:0] b2_t20_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t20_lwd;
    always_ff @(posedge clk) begin b2_t20_lwe <= ld_v && ld_iq >= 14'd304 && ld_iq < 14'd312; b2_t20_lwa <= 3'(ld_iq - 14'd304); b2_t20_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab20 b2_t20_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t20_lwe), .wa(b2_t20_lwa), .wcol(1'b0), .wd(b2_t20_lwd), .q0(b2_t20));
    logic [59:0] b2_t21;
    logic b2_t21_lwe; logic [2:0] b2_t21_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t21_lwd;
    always_ff @(posedge clk) begin b2_t21_lwe <= ld_v && ld_iq >= 14'd312 && ld_iq < 14'd320; b2_t21_lwa <= 3'(ld_iq - 14'd312); b2_t21_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab21 b2_t21_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t21_lwe), .wa(b2_t21_lwa), .wcol(1'b0), .wd(b2_t21_lwd), .q0(b2_t21));
    logic [59:0] b2_t22;
    logic b2_t22_lwe; logic [2:0] b2_t22_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t22_lwd;
    always_ff @(posedge clk) begin b2_t22_lwe <= ld_v && ld_iq >= 14'd320 && ld_iq < 14'd328; b2_t22_lwa <= 3'(ld_iq - 14'd320); b2_t22_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab22 b2_t22_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t22_lwe), .wa(b2_t22_lwa), .wcol(1'b0), .wd(b2_t22_lwd), .q0(b2_t22));
    logic [59:0] b2_t23;
    logic b2_t23_lwe; logic [2:0] b2_t23_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t23_lwd;
    always_ff @(posedge clk) begin b2_t23_lwe <= ld_v && ld_iq >= 14'd328 && ld_iq < 14'd336; b2_t23_lwa <= 3'(ld_iq - 14'd328); b2_t23_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab23 b2_t23_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t23_lwe), .wa(b2_t23_lwa), .wcol(1'b0), .wd(b2_t23_lwd), .q0(b2_t23));
    logic [59:0] b2_t24;
    logic b2_t24_lwe; logic [2:0] b2_t24_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t24_lwd;
    always_ff @(posedge clk) begin b2_t24_lwe <= ld_v && ld_iq >= 14'd336 && ld_iq < 14'd344; b2_t24_lwa <= 3'(ld_iq - 14'd336); b2_t24_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab24 b2_t24_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t24_lwe), .wa(b2_t24_lwa), .wcol(1'b0), .wd(b2_t24_lwd), .q0(b2_t24));
    logic [59:0] b2_t25;
    logic b2_t25_lwe; logic [2:0] b2_t25_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t25_lwd;
    always_ff @(posedge clk) begin b2_t25_lwe <= ld_v && ld_iq >= 14'd344 && ld_iq < 14'd352; b2_t25_lwa <= 3'(ld_iq - 14'd344); b2_t25_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab25 b2_t25_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t25_lwe), .wa(b2_t25_lwa), .wcol(1'b0), .wd(b2_t25_lwd), .q0(b2_t25));
    logic [59:0] b2_t26;
    logic b2_t26_lwe; logic [2:0] b2_t26_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t26_lwd;
    always_ff @(posedge clk) begin b2_t26_lwe <= ld_v && ld_iq >= 14'd352 && ld_iq < 14'd360; b2_t26_lwa <= 3'(ld_iq - 14'd352); b2_t26_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab26 b2_t26_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t26_lwe), .wa(b2_t26_lwa), .wcol(1'b0), .wd(b2_t26_lwd), .q0(b2_t26));
    logic [59:0] b2_t27;
    logic b2_t27_lwe; logic [2:0] b2_t27_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t27_lwd;
    always_ff @(posedge clk) begin b2_t27_lwe <= ld_v && ld_iq >= 14'd360 && ld_iq < 14'd368; b2_t27_lwa <= 3'(ld_iq - 14'd360); b2_t27_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab27 b2_t27_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t27_lwe), .wa(b2_t27_lwa), .wcol(1'b0), .wd(b2_t27_lwd), .q0(b2_t27));
    logic [59:0] b2_t28;
    logic b2_t28_lwe; logic [2:0] b2_t28_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t28_lwd;
    always_ff @(posedge clk) begin b2_t28_lwe <= ld_v && ld_iq >= 14'd368 && ld_iq < 14'd376; b2_t28_lwa <= 3'(ld_iq - 14'd368); b2_t28_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab28 b2_t28_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t28_lwe), .wa(b2_t28_lwa), .wcol(1'b0), .wd(b2_t28_lwd), .q0(b2_t28));
    logic [59:0] b2_t29;
    logic b2_t29_lwe; logic [2:0] b2_t29_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t29_lwd;
    always_ff @(posedge clk) begin b2_t29_lwe <= ld_v && ld_iq >= 14'd376 && ld_iq < 14'd384; b2_t29_lwa <= 3'(ld_iq - 14'd376); b2_t29_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab29 b2_t29_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t29_lwe), .wa(b2_t29_lwa), .wcol(1'b0), .wd(b2_t29_lwd), .q0(b2_t29));
    logic [59:0] b2_t30;
    logic b2_t30_lwe; logic [2:0] b2_t30_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t30_lwd;
    always_ff @(posedge clk) begin b2_t30_lwe <= ld_v && ld_iq >= 14'd384 && ld_iq < 14'd392; b2_t30_lwa <= 3'(ld_iq - 14'd384); b2_t30_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab30 b2_t30_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t30_lwe), .wa(b2_t30_lwa), .wcol(1'b0), .wd(b2_t30_lwd), .q0(b2_t30));
    logic [59:0] b2_t31;
    logic b2_t31_lwe; logic [2:0] b2_t31_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b2_t31_lwd;
    always_ff @(posedge clk) begin b2_t31_lwe <= ld_v && ld_iq >= 14'd392 && ld_iq < 14'd400; b2_t31_lwa <= 3'(ld_iq - 14'd392); b2_t31_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw1_tab31 b2_t31_i (.clk(clk), .addr({b1_tag[0], b2_cnt[10], b2_cnt[9]}), .we(b2_t31_lwe), .wa(b2_t31_lwa), .wcol(1'b0), .wd(b2_t31_lwd), .q0(b2_t31));
    logic [59:0] b2_l0_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l0_a_i (.clk(clk), .din(b1_g0_o[0]), .dout(b2_l0_a));
    logic [59:0] b2_l0_p;
    MS_N16_q60_P32_tpm_twmul b2_l0_mul (.clk(clk), .A(b2_l0_a), .B(b2_t0), .QH(QH[16:0]), .P(b2_l0_p));
    logic [59:0] b2_l1_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l1_a_i (.clk(clk), .din(b1_g1_o[0]), .dout(b2_l1_a));
    logic [59:0] b2_l1_p;
    MS_N16_q60_P32_tpm_twmul b2_l1_mul (.clk(clk), .A(b2_l1_a), .B(b2_t1), .QH(QH[16:0]), .P(b2_l1_p));
    logic [59:0] b2_l2_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l2_a_i (.clk(clk), .din(b1_g2_o[0]), .dout(b2_l2_a));
    logic [59:0] b2_l2_p;
    MS_N16_q60_P32_tpm_twmul b2_l2_mul (.clk(clk), .A(b2_l2_a), .B(b2_t2), .QH(QH[16:0]), .P(b2_l2_p));
    logic [59:0] b2_l3_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l3_a_i (.clk(clk), .din(b1_g3_o[0]), .dout(b2_l3_a));
    logic [59:0] b2_l3_p;
    MS_N16_q60_P32_tpm_twmul b2_l3_mul (.clk(clk), .A(b2_l3_a), .B(b2_t3), .QH(QH[16:0]), .P(b2_l3_p));
    logic [59:0] b2_l4_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l4_a_i (.clk(clk), .din(b1_g4_o[0]), .dout(b2_l4_a));
    logic [59:0] b2_l4_p;
    MS_N16_q60_P32_tpm_twmul b2_l4_mul (.clk(clk), .A(b2_l4_a), .B(b2_t4), .QH(QH[16:0]), .P(b2_l4_p));
    logic [59:0] b2_l5_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l5_a_i (.clk(clk), .din(b1_g5_o[0]), .dout(b2_l5_a));
    logic [59:0] b2_l5_p;
    MS_N16_q60_P32_tpm_twmul b2_l5_mul (.clk(clk), .A(b2_l5_a), .B(b2_t5), .QH(QH[16:0]), .P(b2_l5_p));
    logic [59:0] b2_l6_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l6_a_i (.clk(clk), .din(b1_g6_o[0]), .dout(b2_l6_a));
    logic [59:0] b2_l6_p;
    MS_N16_q60_P32_tpm_twmul b2_l6_mul (.clk(clk), .A(b2_l6_a), .B(b2_t6), .QH(QH[16:0]), .P(b2_l6_p));
    logic [59:0] b2_l7_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l7_a_i (.clk(clk), .din(b1_g7_o[0]), .dout(b2_l7_a));
    logic [59:0] b2_l7_p;
    MS_N16_q60_P32_tpm_twmul b2_l7_mul (.clk(clk), .A(b2_l7_a), .B(b2_t7), .QH(QH[16:0]), .P(b2_l7_p));
    logic [59:0] b2_l8_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l8_a_i (.clk(clk), .din(b1_g0_o[1]), .dout(b2_l8_a));
    logic [59:0] b2_l8_p;
    MS_N16_q60_P32_tpm_twmul b2_l8_mul (.clk(clk), .A(b2_l8_a), .B(b2_t8), .QH(QH[16:0]), .P(b2_l8_p));
    logic [59:0] b2_l9_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l9_a_i (.clk(clk), .din(b1_g1_o[1]), .dout(b2_l9_a));
    logic [59:0] b2_l9_p;
    MS_N16_q60_P32_tpm_twmul b2_l9_mul (.clk(clk), .A(b2_l9_a), .B(b2_t9), .QH(QH[16:0]), .P(b2_l9_p));
    logic [59:0] b2_l10_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l10_a_i (.clk(clk), .din(b1_g2_o[1]), .dout(b2_l10_a));
    logic [59:0] b2_l10_p;
    MS_N16_q60_P32_tpm_twmul b2_l10_mul (.clk(clk), .A(b2_l10_a), .B(b2_t10), .QH(QH[16:0]), .P(b2_l10_p));
    logic [59:0] b2_l11_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l11_a_i (.clk(clk), .din(b1_g3_o[1]), .dout(b2_l11_a));
    logic [59:0] b2_l11_p;
    MS_N16_q60_P32_tpm_twmul b2_l11_mul (.clk(clk), .A(b2_l11_a), .B(b2_t11), .QH(QH[16:0]), .P(b2_l11_p));
    logic [59:0] b2_l12_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l12_a_i (.clk(clk), .din(b1_g4_o[1]), .dout(b2_l12_a));
    logic [59:0] b2_l12_p;
    MS_N16_q60_P32_tpm_twmul b2_l12_mul (.clk(clk), .A(b2_l12_a), .B(b2_t12), .QH(QH[16:0]), .P(b2_l12_p));
    logic [59:0] b2_l13_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l13_a_i (.clk(clk), .din(b1_g5_o[1]), .dout(b2_l13_a));
    logic [59:0] b2_l13_p;
    MS_N16_q60_P32_tpm_twmul b2_l13_mul (.clk(clk), .A(b2_l13_a), .B(b2_t13), .QH(QH[16:0]), .P(b2_l13_p));
    logic [59:0] b2_l14_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l14_a_i (.clk(clk), .din(b1_g6_o[1]), .dout(b2_l14_a));
    logic [59:0] b2_l14_p;
    MS_N16_q60_P32_tpm_twmul b2_l14_mul (.clk(clk), .A(b2_l14_a), .B(b2_t14), .QH(QH[16:0]), .P(b2_l14_p));
    logic [59:0] b2_l15_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l15_a_i (.clk(clk), .din(b1_g7_o[1]), .dout(b2_l15_a));
    logic [59:0] b2_l15_p;
    MS_N16_q60_P32_tpm_twmul b2_l15_mul (.clk(clk), .A(b2_l15_a), .B(b2_t15), .QH(QH[16:0]), .P(b2_l15_p));
    logic [59:0] b2_l16_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l16_a_i (.clk(clk), .din(b1_g0_o[2]), .dout(b2_l16_a));
    logic [59:0] b2_l16_p;
    MS_N16_q60_P32_tpm_twmul b2_l16_mul (.clk(clk), .A(b2_l16_a), .B(b2_t16), .QH(QH[16:0]), .P(b2_l16_p));
    logic [59:0] b2_l17_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l17_a_i (.clk(clk), .din(b1_g1_o[2]), .dout(b2_l17_a));
    logic [59:0] b2_l17_p;
    MS_N16_q60_P32_tpm_twmul b2_l17_mul (.clk(clk), .A(b2_l17_a), .B(b2_t17), .QH(QH[16:0]), .P(b2_l17_p));
    logic [59:0] b2_l18_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l18_a_i (.clk(clk), .din(b1_g2_o[2]), .dout(b2_l18_a));
    logic [59:0] b2_l18_p;
    MS_N16_q60_P32_tpm_twmul b2_l18_mul (.clk(clk), .A(b2_l18_a), .B(b2_t18), .QH(QH[16:0]), .P(b2_l18_p));
    logic [59:0] b2_l19_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l19_a_i (.clk(clk), .din(b1_g3_o[2]), .dout(b2_l19_a));
    logic [59:0] b2_l19_p;
    MS_N16_q60_P32_tpm_twmul b2_l19_mul (.clk(clk), .A(b2_l19_a), .B(b2_t19), .QH(QH[16:0]), .P(b2_l19_p));
    logic [59:0] b2_l20_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l20_a_i (.clk(clk), .din(b1_g4_o[2]), .dout(b2_l20_a));
    logic [59:0] b2_l20_p;
    MS_N16_q60_P32_tpm_twmul b2_l20_mul (.clk(clk), .A(b2_l20_a), .B(b2_t20), .QH(QH[16:0]), .P(b2_l20_p));
    logic [59:0] b2_l21_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l21_a_i (.clk(clk), .din(b1_g5_o[2]), .dout(b2_l21_a));
    logic [59:0] b2_l21_p;
    MS_N16_q60_P32_tpm_twmul b2_l21_mul (.clk(clk), .A(b2_l21_a), .B(b2_t21), .QH(QH[16:0]), .P(b2_l21_p));
    logic [59:0] b2_l22_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l22_a_i (.clk(clk), .din(b1_g6_o[2]), .dout(b2_l22_a));
    logic [59:0] b2_l22_p;
    MS_N16_q60_P32_tpm_twmul b2_l22_mul (.clk(clk), .A(b2_l22_a), .B(b2_t22), .QH(QH[16:0]), .P(b2_l22_p));
    logic [59:0] b2_l23_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l23_a_i (.clk(clk), .din(b1_g7_o[2]), .dout(b2_l23_a));
    logic [59:0] b2_l23_p;
    MS_N16_q60_P32_tpm_twmul b2_l23_mul (.clk(clk), .A(b2_l23_a), .B(b2_t23), .QH(QH[16:0]), .P(b2_l23_p));
    logic [59:0] b2_l24_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l24_a_i (.clk(clk), .din(b1_g0_o[3]), .dout(b2_l24_a));
    logic [59:0] b2_l24_p;
    MS_N16_q60_P32_tpm_twmul b2_l24_mul (.clk(clk), .A(b2_l24_a), .B(b2_t24), .QH(QH[16:0]), .P(b2_l24_p));
    logic [59:0] b2_l25_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l25_a_i (.clk(clk), .din(b1_g1_o[3]), .dout(b2_l25_a));
    logic [59:0] b2_l25_p;
    MS_N16_q60_P32_tpm_twmul b2_l25_mul (.clk(clk), .A(b2_l25_a), .B(b2_t25), .QH(QH[16:0]), .P(b2_l25_p));
    logic [59:0] b2_l26_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l26_a_i (.clk(clk), .din(b1_g2_o[3]), .dout(b2_l26_a));
    logic [59:0] b2_l26_p;
    MS_N16_q60_P32_tpm_twmul b2_l26_mul (.clk(clk), .A(b2_l26_a), .B(b2_t26), .QH(QH[16:0]), .P(b2_l26_p));
    logic [59:0] b2_l27_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l27_a_i (.clk(clk), .din(b1_g3_o[3]), .dout(b2_l27_a));
    logic [59:0] b2_l27_p;
    MS_N16_q60_P32_tpm_twmul b2_l27_mul (.clk(clk), .A(b2_l27_a), .B(b2_t27), .QH(QH[16:0]), .P(b2_l27_p));
    logic [59:0] b2_l28_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l28_a_i (.clk(clk), .din(b1_g4_o[3]), .dout(b2_l28_a));
    logic [59:0] b2_l28_p;
    MS_N16_q60_P32_tpm_twmul b2_l28_mul (.clk(clk), .A(b2_l28_a), .B(b2_t28), .QH(QH[16:0]), .P(b2_l28_p));
    logic [59:0] b2_l29_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l29_a_i (.clk(clk), .din(b1_g5_o[3]), .dout(b2_l29_a));
    logic [59:0] b2_l29_p;
    MS_N16_q60_P32_tpm_twmul b2_l29_mul (.clk(clk), .A(b2_l29_a), .B(b2_t29), .QH(QH[16:0]), .P(b2_l29_p));
    logic [59:0] b2_l30_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l30_a_i (.clk(clk), .din(b1_g6_o[3]), .dout(b2_l30_a));
    logic [59:0] b2_l30_p;
    MS_N16_q60_P32_tpm_twmul b2_l30_mul (.clk(clk), .A(b2_l30_a), .B(b2_t30), .QH(QH[16:0]), .P(b2_l30_p));
    logic [59:0] b2_l31_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b2_l31_a_i (.clk(clk), .din(b1_g7_o[3]), .dout(b2_l31_a));
    logic [59:0] b2_l31_p;
    MS_N16_q60_P32_tpm_twmul b2_l31_mul (.clk(clk), .A(b2_l31_a), .B(b2_t31), .QH(QH[16:0]), .P(b2_l31_p));
    logic [13:0] b2_v_sr;
    always_ff @(posedge clk) b2_v_sr <= rst ? '0 : {b2_v_sr[12:0], b1_g0_v};
    logic b2_v; assign b2_v = b2_v_sr[13];
    logic [0:0] b2_tag;
    MS_N16_q60_P32_tpm_dly_c #(.W(1), .D(14)) b2_tag_i (.clk(clk), .din(b1_tag), .dout(b2_tag));
    // block 3: pass 1, 1 x MS_N16_q60_P32_tpm_p1 (32-point), latency 66
    logic [59:0] b3_c0_y0, b3_c0_y1, b3_c0_y2, b3_c0_y3, b3_c0_y4, b3_c0_y5, b3_c0_y6, b3_c0_y7, b3_c0_y8, b3_c0_y9, b3_c0_y10, b3_c0_y11, b3_c0_y12, b3_c0_y13, b3_c0_y14, b3_c0_y15, b3_c0_y16, b3_c0_y17, b3_c0_y18, b3_c0_y19, b3_c0_y20, b3_c0_y21, b3_c0_y22, b3_c0_y23, b3_c0_y24, b3_c0_y25, b3_c0_y26, b3_c0_y27, b3_c0_y28, b3_c0_y29, b3_c0_y30, b3_c0_y31;
    logic b3_c0_v; logic b3_c0_di;
    logic b3_c0_lr, b3_c0_lw; (* equivalent_register_removal = "no" *) logic [59:0] b3_c0_ld;
    always_ff @(posedge clk) begin b3_c0_lr <= ld_r; b3_c0_lw <= ld_v && ld_iq >= 14'd6 && ld_iq < 14'd36; b3_c0_ld <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_p1 b3_c0 (.clk(clk), .rst(rst), .in_valid(b2_v), .out_valid(b3_c0_v), .DIR(b2_tag[0]), .tw_rst(b3_c0_lr), .tw_wen(b3_c0_lw), .tw_wdata(b3_c0_ld), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(b2_l0_p), .x_in_1(b2_l8_p), .x_in_2(b2_l16_p), .x_in_3(b2_l24_p), .x_in_4(b2_l1_p), .x_in_5(b2_l9_p), .x_in_6(b2_l17_p), .x_in_7(b2_l25_p), .x_in_8(b2_l2_p), .x_in_9(b2_l10_p), .x_in_10(b2_l18_p), .x_in_11(b2_l26_p), .x_in_12(b2_l3_p), .x_in_13(b2_l11_p), .x_in_14(b2_l19_p), .x_in_15(b2_l27_p), .x_in_16(b2_l4_p), .x_in_17(b2_l12_p), .x_in_18(b2_l20_p), .x_in_19(b2_l28_p), .x_in_20(b2_l5_p), .x_in_21(b2_l13_p), .x_in_22(b2_l21_p), .x_in_23(b2_l29_p), .x_in_24(b2_l6_p), .x_in_25(b2_l14_p), .x_in_26(b2_l22_p), .x_in_27(b2_l30_p), .x_in_28(b2_l7_p), .x_in_29(b2_l15_p), .x_in_30(b2_l23_p), .x_in_31(b2_l31_p), .y_out_0(b3_c0_y0), .y_out_1(b3_c0_y1), .y_out_2(b3_c0_y2), .y_out_3(b3_c0_y3), .y_out_4(b3_c0_y4), .y_out_5(b3_c0_y5), .y_out_6(b3_c0_y6), .y_out_7(b3_c0_y7), .y_out_8(b3_c0_y8), .y_out_9(b3_c0_y9), .y_out_10(b3_c0_y10), .y_out_11(b3_c0_y11), .y_out_12(b3_c0_y12), .y_out_13(b3_c0_y13), .y_out_14(b3_c0_y14), .y_out_15(b3_c0_y15), .y_out_16(b3_c0_y16), .y_out_17(b3_c0_y17), .y_out_18(b3_c0_y18), .y_out_19(b3_c0_y19), .y_out_20(b3_c0_y20), .y_out_21(b3_c0_y21), .y_out_22(b3_c0_y22), .y_out_23(b3_c0_y23), .y_out_24(b3_c0_y24), .y_out_25(b3_c0_y25), .y_out_26(b3_c0_y26), .y_out_27(b3_c0_y27), .y_out_28(b3_c0_y28), .y_out_29(b3_c0_y29), .y_out_30(b3_c0_y30), .y_out_31(b3_c0_y31));
    logic [0:0] b3_tag;
    MS_N16_q60_P32_tpm_dly_c #(.W(1), .D(66)) b3_tag_i (.clk(clk), .din(b2_tag), .dout(b3_tag));
    // block 4: lane-time transpose, lane bits [0, 1, 2, 3] <-> cycle bits [5,9), 2 x S=16, latency 517
    logic [59:0] b4_g0_i [0:15]; logic [59:0] b4_g0_o [0:15]; logic b4_g0_v;
    assign b4_g0_i[0] = b3_c0_y0;
    assign b4_g0_i[1] = b3_c0_y4;
    assign b4_g0_i[2] = b3_c0_y8;
    assign b4_g0_i[3] = b3_c0_y12;
    assign b4_g0_i[4] = b3_c0_y16;
    assign b4_g0_i[5] = b3_c0_y20;
    assign b4_g0_i[6] = b3_c0_y24;
    assign b4_g0_i[7] = b3_c0_y28;
    assign b4_g0_i[8] = b3_c0_y1;
    assign b4_g0_i[9] = b3_c0_y5;
    assign b4_g0_i[10] = b3_c0_y9;
    assign b4_g0_i[11] = b3_c0_y13;
    assign b4_g0_i[12] = b3_c0_y17;
    assign b4_g0_i[13] = b3_c0_y21;
    assign b4_g0_i[14] = b3_c0_y25;
    assign b4_g0_i[15] = b3_c0_y29;
    lt_bmb_transpose #(.S(16), .LO(5), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h3), .RAM_STYLE("block")) b4_g0 (.clk(clk), .rst(rst), .data_valid(b3_c0_v), .data_in(b4_g0_i), .data_out_valid(b4_g0_v), .data_out(b4_g0_o));
    logic [59:0] b4_g1_i [0:15]; logic [59:0] b4_g1_o [0:15]; logic b4_g1_v;
    assign b4_g1_i[0] = b3_c0_y2;
    assign b4_g1_i[1] = b3_c0_y6;
    assign b4_g1_i[2] = b3_c0_y10;
    assign b4_g1_i[3] = b3_c0_y14;
    assign b4_g1_i[4] = b3_c0_y18;
    assign b4_g1_i[5] = b3_c0_y22;
    assign b4_g1_i[6] = b3_c0_y26;
    assign b4_g1_i[7] = b3_c0_y30;
    assign b4_g1_i[8] = b3_c0_y3;
    assign b4_g1_i[9] = b3_c0_y7;
    assign b4_g1_i[10] = b3_c0_y11;
    assign b4_g1_i[11] = b3_c0_y15;
    assign b4_g1_i[12] = b3_c0_y19;
    assign b4_g1_i[13] = b3_c0_y23;
    assign b4_g1_i[14] = b3_c0_y27;
    assign b4_g1_i[15] = b3_c0_y31;
    lt_bmb_transpose #(.S(16), .LO(5), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h3), .RAM_STYLE("block")) b4_g1 (.clk(clk), .rst(rst), .data_valid(b3_c0_v), .data_in(b4_g1_i), .data_out_valid(b4_g1_v), .data_out(b4_g1_o));
    logic [0:0] b4_tag;
    MS_N16_q60_P32_tpm_dly_c #(.W(1), .D(517)) b4_tag_i (.clk(clk), .din(b3_tag), .dout(b4_tag));
    // block 5: twiddle stage 2, latency 14 (tables 2, multiplier 12)
    logic [10:0] b5_cnt;
    always_ff @(posedge clk) b5_cnt <= rst ? '0 : (b4_g0_v ? b5_cnt + 1'b1 : b5_cnt);
    logic [59:0] b5_t0;
    logic b5_t0_lwe; logic [4:0] b5_t0_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t0_lwd;
    always_ff @(posedge clk) begin b5_t0_lwe <= ld_v && ld_iq >= 14'd400 && ld_iq < 14'd432; b5_t0_lwa <= 5'(ld_iq - 14'd400); b5_t0_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab0 b5_t0_i (.clk(clk), .addr({b4_tag[0], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t0_lwe), .wa(b5_t0_lwa), .wcol(1'b0), .wd(b5_t0_lwd), .q0(b5_t0));
    logic [59:0] b5_t1;
    logic b5_t1_lwe; logic [6:0] b5_t1_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t1_lwd;
    always_ff @(posedge clk) begin b5_t1_lwe <= ld_v && ld_iq >= 14'd432 && ld_iq < 14'd560; b5_t1_lwa <= 7'(ld_iq - 14'd432); b5_t1_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab1 b5_t1_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t1_lwe), .wa(b5_t1_lwa), .wcol(1'b0), .wd(b5_t1_lwd), .q0(b5_t1));
    logic [59:0] b5_t2;
    logic b5_t2_lwe; logic [6:0] b5_t2_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t2_lwd;
    always_ff @(posedge clk) begin b5_t2_lwe <= ld_v && ld_iq >= 14'd560 && ld_iq < 14'd688; b5_t2_lwa <= 7'(ld_iq - 14'd560); b5_t2_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab2 b5_t2_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t2_lwe), .wa(b5_t2_lwa), .wcol(1'b0), .wd(b5_t2_lwd), .q0(b5_t2));
    logic [59:0] b5_t3;
    logic b5_t3_lwe; logic [6:0] b5_t3_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t3_lwd;
    always_ff @(posedge clk) begin b5_t3_lwe <= ld_v && ld_iq >= 14'd688 && ld_iq < 14'd816; b5_t3_lwa <= 7'(ld_iq - 14'd688); b5_t3_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab3 b5_t3_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t3_lwe), .wa(b5_t3_lwa), .wcol(1'b0), .wd(b5_t3_lwd), .q0(b5_t3));
    logic [59:0] b5_t4;
    logic b5_t4_lwe; logic [6:0] b5_t4_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t4_lwd;
    always_ff @(posedge clk) begin b5_t4_lwe <= ld_v && ld_iq >= 14'd816 && ld_iq < 14'd944; b5_t4_lwa <= 7'(ld_iq - 14'd816); b5_t4_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab4 b5_t4_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t4_lwe), .wa(b5_t4_lwa), .wcol(1'b0), .wd(b5_t4_lwd), .q0(b5_t4));
    logic [59:0] b5_t5;
    logic b5_t5_lwe; logic [6:0] b5_t5_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t5_lwd;
    always_ff @(posedge clk) begin b5_t5_lwe <= ld_v && ld_iq >= 14'd944 && ld_iq < 14'd1072; b5_t5_lwa <= 7'(ld_iq - 14'd944); b5_t5_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab5 b5_t5_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t5_lwe), .wa(b5_t5_lwa), .wcol(1'b0), .wd(b5_t5_lwd), .q0(b5_t5));
    logic [59:0] b5_t6;
    logic b5_t6_lwe; logic [6:0] b5_t6_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t6_lwd;
    always_ff @(posedge clk) begin b5_t6_lwe <= ld_v && ld_iq >= 14'd1072 && ld_iq < 14'd1200; b5_t6_lwa <= 7'(ld_iq - 14'd1072); b5_t6_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab6 b5_t6_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t6_lwe), .wa(b5_t6_lwa), .wcol(1'b0), .wd(b5_t6_lwd), .q0(b5_t6));
    logic [59:0] b5_t7;
    logic b5_t7_lwe; logic [6:0] b5_t7_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t7_lwd;
    always_ff @(posedge clk) begin b5_t7_lwe <= ld_v && ld_iq >= 14'd1200 && ld_iq < 14'd1328; b5_t7_lwa <= 7'(ld_iq - 14'd1200); b5_t7_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab7 b5_t7_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t7_lwe), .wa(b5_t7_lwa), .wcol(1'b0), .wd(b5_t7_lwd), .q0(b5_t7));
    logic [59:0] b5_t8;
    logic b5_t8_lwe; logic [6:0] b5_t8_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t8_lwd;
    always_ff @(posedge clk) begin b5_t8_lwe <= ld_v && ld_iq >= 14'd1328 && ld_iq < 14'd1456; b5_t8_lwa <= 7'(ld_iq - 14'd1328); b5_t8_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab8 b5_t8_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t8_lwe), .wa(b5_t8_lwa), .wcol(1'b0), .wd(b5_t8_lwd), .q0(b5_t8));
    logic [59:0] b5_t9;
    logic b5_t9_lwe; logic [6:0] b5_t9_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t9_lwd;
    always_ff @(posedge clk) begin b5_t9_lwe <= ld_v && ld_iq >= 14'd1456 && ld_iq < 14'd1584; b5_t9_lwa <= 7'(ld_iq - 14'd1456); b5_t9_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab9 b5_t9_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t9_lwe), .wa(b5_t9_lwa), .wcol(1'b0), .wd(b5_t9_lwd), .q0(b5_t9));
    logic [59:0] b5_t10;
    logic b5_t10_lwe; logic [6:0] b5_t10_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t10_lwd;
    always_ff @(posedge clk) begin b5_t10_lwe <= ld_v && ld_iq >= 14'd1584 && ld_iq < 14'd1712; b5_t10_lwa <= 7'(ld_iq - 14'd1584); b5_t10_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab10 b5_t10_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t10_lwe), .wa(b5_t10_lwa), .wcol(1'b0), .wd(b5_t10_lwd), .q0(b5_t10));
    logic [59:0] b5_t11;
    logic b5_t11_lwe; logic [6:0] b5_t11_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t11_lwd;
    always_ff @(posedge clk) begin b5_t11_lwe <= ld_v && ld_iq >= 14'd1712 && ld_iq < 14'd1840; b5_t11_lwa <= 7'(ld_iq - 14'd1712); b5_t11_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab11 b5_t11_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t11_lwe), .wa(b5_t11_lwa), .wcol(1'b0), .wd(b5_t11_lwd), .q0(b5_t11));
    logic [59:0] b5_t12;
    logic b5_t12_lwe; logic [6:0] b5_t12_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t12_lwd;
    always_ff @(posedge clk) begin b5_t12_lwe <= ld_v && ld_iq >= 14'd1840 && ld_iq < 14'd1968; b5_t12_lwa <= 7'(ld_iq - 14'd1840); b5_t12_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab12 b5_t12_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t12_lwe), .wa(b5_t12_lwa), .wcol(1'b0), .wd(b5_t12_lwd), .q0(b5_t12));
    logic [59:0] b5_t13;
    logic b5_t13_lwe; logic [6:0] b5_t13_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t13_lwd;
    always_ff @(posedge clk) begin b5_t13_lwe <= ld_v && ld_iq >= 14'd1968 && ld_iq < 14'd2096; b5_t13_lwa <= 7'(ld_iq - 14'd1968); b5_t13_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab13 b5_t13_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t13_lwe), .wa(b5_t13_lwa), .wcol(1'b0), .wd(b5_t13_lwd), .q0(b5_t13));
    logic [59:0] b5_t14;
    logic b5_t14_lwe; logic [6:0] b5_t14_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t14_lwd;
    always_ff @(posedge clk) begin b5_t14_lwe <= ld_v && ld_iq >= 14'd2096 && ld_iq < 14'd2224; b5_t14_lwa <= 7'(ld_iq - 14'd2096); b5_t14_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab14 b5_t14_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t14_lwe), .wa(b5_t14_lwa), .wcol(1'b0), .wd(b5_t14_lwd), .q0(b5_t14));
    logic [59:0] b5_t15;
    logic b5_t15_lwe; logic [6:0] b5_t15_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t15_lwd;
    always_ff @(posedge clk) begin b5_t15_lwe <= ld_v && ld_iq >= 14'd2224 && ld_iq < 14'd2352; b5_t15_lwa <= 7'(ld_iq - 14'd2224); b5_t15_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab15 b5_t15_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t15_lwe), .wa(b5_t15_lwa), .wcol(1'b0), .wd(b5_t15_lwd), .q0(b5_t15));
    logic [59:0] b5_t16;
    logic b5_t16_lwe; logic [4:0] b5_t16_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t16_lwd;
    always_ff @(posedge clk) begin b5_t16_lwe <= ld_v && ld_iq >= 14'd2352 && ld_iq < 14'd2384; b5_t16_lwa <= 5'(ld_iq - 14'd2352); b5_t16_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab16 b5_t16_i (.clk(clk), .addr({b4_tag[0], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t16_lwe), .wa(b5_t16_lwa), .wcol(1'b0), .wd(b5_t16_lwd), .q0(b5_t16));
    logic [59:0] b5_t17;
    logic b5_t17_lwe; logic [6:0] b5_t17_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t17_lwd;
    always_ff @(posedge clk) begin b5_t17_lwe <= ld_v && ld_iq >= 14'd2384 && ld_iq < 14'd2512; b5_t17_lwa <= 7'(ld_iq - 14'd2384); b5_t17_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab17 b5_t17_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t17_lwe), .wa(b5_t17_lwa), .wcol(1'b0), .wd(b5_t17_lwd), .q0(b5_t17));
    logic [59:0] b5_t18;
    logic b5_t18_lwe; logic [6:0] b5_t18_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t18_lwd;
    always_ff @(posedge clk) begin b5_t18_lwe <= ld_v && ld_iq >= 14'd2512 && ld_iq < 14'd2640; b5_t18_lwa <= 7'(ld_iq - 14'd2512); b5_t18_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab18 b5_t18_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t18_lwe), .wa(b5_t18_lwa), .wcol(1'b0), .wd(b5_t18_lwd), .q0(b5_t18));
    logic [59:0] b5_t19;
    logic b5_t19_lwe; logic [6:0] b5_t19_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t19_lwd;
    always_ff @(posedge clk) begin b5_t19_lwe <= ld_v && ld_iq >= 14'd2640 && ld_iq < 14'd2768; b5_t19_lwa <= 7'(ld_iq - 14'd2640); b5_t19_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab19 b5_t19_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t19_lwe), .wa(b5_t19_lwa), .wcol(1'b0), .wd(b5_t19_lwd), .q0(b5_t19));
    logic [59:0] b5_t20;
    logic b5_t20_lwe; logic [6:0] b5_t20_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t20_lwd;
    always_ff @(posedge clk) begin b5_t20_lwe <= ld_v && ld_iq >= 14'd2768 && ld_iq < 14'd2896; b5_t20_lwa <= 7'(ld_iq - 14'd2768); b5_t20_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab20 b5_t20_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t20_lwe), .wa(b5_t20_lwa), .wcol(1'b0), .wd(b5_t20_lwd), .q0(b5_t20));
    logic [59:0] b5_t21;
    logic b5_t21_lwe; logic [6:0] b5_t21_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t21_lwd;
    always_ff @(posedge clk) begin b5_t21_lwe <= ld_v && ld_iq >= 14'd2896 && ld_iq < 14'd3024; b5_t21_lwa <= 7'(ld_iq - 14'd2896); b5_t21_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab21 b5_t21_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t21_lwe), .wa(b5_t21_lwa), .wcol(1'b0), .wd(b5_t21_lwd), .q0(b5_t21));
    logic [59:0] b5_t22;
    logic b5_t22_lwe; logic [6:0] b5_t22_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t22_lwd;
    always_ff @(posedge clk) begin b5_t22_lwe <= ld_v && ld_iq >= 14'd3024 && ld_iq < 14'd3152; b5_t22_lwa <= 7'(ld_iq - 14'd3024); b5_t22_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab22 b5_t22_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t22_lwe), .wa(b5_t22_lwa), .wcol(1'b0), .wd(b5_t22_lwd), .q0(b5_t22));
    logic [59:0] b5_t23;
    logic b5_t23_lwe; logic [6:0] b5_t23_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t23_lwd;
    always_ff @(posedge clk) begin b5_t23_lwe <= ld_v && ld_iq >= 14'd3152 && ld_iq < 14'd3280; b5_t23_lwa <= 7'(ld_iq - 14'd3152); b5_t23_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab23 b5_t23_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t23_lwe), .wa(b5_t23_lwa), .wcol(1'b0), .wd(b5_t23_lwd), .q0(b5_t23));
    logic [59:0] b5_t24;
    logic b5_t24_lwe; logic [6:0] b5_t24_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t24_lwd;
    always_ff @(posedge clk) begin b5_t24_lwe <= ld_v && ld_iq >= 14'd3280 && ld_iq < 14'd3408; b5_t24_lwa <= 7'(ld_iq - 14'd3280); b5_t24_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab24 b5_t24_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t24_lwe), .wa(b5_t24_lwa), .wcol(1'b0), .wd(b5_t24_lwd), .q0(b5_t24));
    logic [59:0] b5_t25;
    logic b5_t25_lwe; logic [6:0] b5_t25_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t25_lwd;
    always_ff @(posedge clk) begin b5_t25_lwe <= ld_v && ld_iq >= 14'd3408 && ld_iq < 14'd3536; b5_t25_lwa <= 7'(ld_iq - 14'd3408); b5_t25_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab25 b5_t25_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t25_lwe), .wa(b5_t25_lwa), .wcol(1'b0), .wd(b5_t25_lwd), .q0(b5_t25));
    logic [59:0] b5_t26;
    logic b5_t26_lwe; logic [6:0] b5_t26_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t26_lwd;
    always_ff @(posedge clk) begin b5_t26_lwe <= ld_v && ld_iq >= 14'd3536 && ld_iq < 14'd3664; b5_t26_lwa <= 7'(ld_iq - 14'd3536); b5_t26_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab26 b5_t26_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t26_lwe), .wa(b5_t26_lwa), .wcol(1'b0), .wd(b5_t26_lwd), .q0(b5_t26));
    logic [59:0] b5_t27;
    logic b5_t27_lwe; logic [6:0] b5_t27_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t27_lwd;
    always_ff @(posedge clk) begin b5_t27_lwe <= ld_v && ld_iq >= 14'd3664 && ld_iq < 14'd3792; b5_t27_lwa <= 7'(ld_iq - 14'd3664); b5_t27_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab27 b5_t27_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t27_lwe), .wa(b5_t27_lwa), .wcol(1'b0), .wd(b5_t27_lwd), .q0(b5_t27));
    logic [59:0] b5_t28;
    logic b5_t28_lwe; logic [6:0] b5_t28_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t28_lwd;
    always_ff @(posedge clk) begin b5_t28_lwe <= ld_v && ld_iq >= 14'd3792 && ld_iq < 14'd3920; b5_t28_lwa <= 7'(ld_iq - 14'd3792); b5_t28_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab28 b5_t28_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t28_lwe), .wa(b5_t28_lwa), .wcol(1'b0), .wd(b5_t28_lwd), .q0(b5_t28));
    logic [59:0] b5_t29;
    logic b5_t29_lwe; logic [6:0] b5_t29_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t29_lwd;
    always_ff @(posedge clk) begin b5_t29_lwe <= ld_v && ld_iq >= 14'd3920 && ld_iq < 14'd4048; b5_t29_lwa <= 7'(ld_iq - 14'd3920); b5_t29_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab29 b5_t29_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t29_lwe), .wa(b5_t29_lwa), .wcol(1'b0), .wd(b5_t29_lwd), .q0(b5_t29));
    logic [59:0] b5_t30;
    logic b5_t30_lwe; logic [6:0] b5_t30_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t30_lwd;
    always_ff @(posedge clk) begin b5_t30_lwe <= ld_v && ld_iq >= 14'd4048 && ld_iq < 14'd4176; b5_t30_lwa <= 7'(ld_iq - 14'd4048); b5_t30_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab30 b5_t30_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t30_lwe), .wa(b5_t30_lwa), .wcol(1'b0), .wd(b5_t30_lwd), .q0(b5_t30));
    logic [59:0] b5_t31;
    logic b5_t31_lwe; logic [6:0] b5_t31_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b5_t31_lwd;
    always_ff @(posedge clk) begin b5_t31_lwe <= ld_v && ld_iq >= 14'd4176 && ld_iq < 14'd4304; b5_t31_lwa <= 7'(ld_iq - 14'd4176); b5_t31_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw2_tab31 b5_t31_i (.clk(clk), .addr({b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t31_lwe), .wa(b5_t31_lwa), .wcol(1'b0), .wd(b5_t31_lwd), .q0(b5_t31));
    logic [59:0] b5_l0_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l0_a_i (.clk(clk), .din(b4_g0_o[0]), .dout(b5_l0_a));
    logic [59:0] b5_l0_p;
    MS_N16_q60_P32_tpm_twmul b5_l0_mul (.clk(clk), .A(b5_l0_a), .B(b5_t0), .QH(QH[16:0]), .P(b5_l0_p));
    logic [59:0] b5_l1_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l1_a_i (.clk(clk), .din(b4_g0_o[1]), .dout(b5_l1_a));
    logic [59:0] b5_l1_p;
    MS_N16_q60_P32_tpm_twmul b5_l1_mul (.clk(clk), .A(b5_l1_a), .B(b5_t1), .QH(QH[16:0]), .P(b5_l1_p));
    logic [59:0] b5_l2_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l2_a_i (.clk(clk), .din(b4_g0_o[2]), .dout(b5_l2_a));
    logic [59:0] b5_l2_p;
    MS_N16_q60_P32_tpm_twmul b5_l2_mul (.clk(clk), .A(b5_l2_a), .B(b5_t2), .QH(QH[16:0]), .P(b5_l2_p));
    logic [59:0] b5_l3_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l3_a_i (.clk(clk), .din(b4_g0_o[3]), .dout(b5_l3_a));
    logic [59:0] b5_l3_p;
    MS_N16_q60_P32_tpm_twmul b5_l3_mul (.clk(clk), .A(b5_l3_a), .B(b5_t3), .QH(QH[16:0]), .P(b5_l3_p));
    logic [59:0] b5_l4_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l4_a_i (.clk(clk), .din(b4_g0_o[4]), .dout(b5_l4_a));
    logic [59:0] b5_l4_p;
    MS_N16_q60_P32_tpm_twmul b5_l4_mul (.clk(clk), .A(b5_l4_a), .B(b5_t4), .QH(QH[16:0]), .P(b5_l4_p));
    logic [59:0] b5_l5_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l5_a_i (.clk(clk), .din(b4_g0_o[5]), .dout(b5_l5_a));
    logic [59:0] b5_l5_p;
    MS_N16_q60_P32_tpm_twmul b5_l5_mul (.clk(clk), .A(b5_l5_a), .B(b5_t5), .QH(QH[16:0]), .P(b5_l5_p));
    logic [59:0] b5_l6_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l6_a_i (.clk(clk), .din(b4_g0_o[6]), .dout(b5_l6_a));
    logic [59:0] b5_l6_p;
    MS_N16_q60_P32_tpm_twmul b5_l6_mul (.clk(clk), .A(b5_l6_a), .B(b5_t6), .QH(QH[16:0]), .P(b5_l6_p));
    logic [59:0] b5_l7_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l7_a_i (.clk(clk), .din(b4_g0_o[7]), .dout(b5_l7_a));
    logic [59:0] b5_l7_p;
    MS_N16_q60_P32_tpm_twmul b5_l7_mul (.clk(clk), .A(b5_l7_a), .B(b5_t7), .QH(QH[16:0]), .P(b5_l7_p));
    logic [59:0] b5_l8_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l8_a_i (.clk(clk), .din(b4_g0_o[8]), .dout(b5_l8_a));
    logic [59:0] b5_l8_p;
    MS_N16_q60_P32_tpm_twmul b5_l8_mul (.clk(clk), .A(b5_l8_a), .B(b5_t8), .QH(QH[16:0]), .P(b5_l8_p));
    logic [59:0] b5_l9_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l9_a_i (.clk(clk), .din(b4_g0_o[9]), .dout(b5_l9_a));
    logic [59:0] b5_l9_p;
    MS_N16_q60_P32_tpm_twmul b5_l9_mul (.clk(clk), .A(b5_l9_a), .B(b5_t9), .QH(QH[16:0]), .P(b5_l9_p));
    logic [59:0] b5_l10_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l10_a_i (.clk(clk), .din(b4_g0_o[10]), .dout(b5_l10_a));
    logic [59:0] b5_l10_p;
    MS_N16_q60_P32_tpm_twmul b5_l10_mul (.clk(clk), .A(b5_l10_a), .B(b5_t10), .QH(QH[16:0]), .P(b5_l10_p));
    logic [59:0] b5_l11_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l11_a_i (.clk(clk), .din(b4_g0_o[11]), .dout(b5_l11_a));
    logic [59:0] b5_l11_p;
    MS_N16_q60_P32_tpm_twmul b5_l11_mul (.clk(clk), .A(b5_l11_a), .B(b5_t11), .QH(QH[16:0]), .P(b5_l11_p));
    logic [59:0] b5_l12_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l12_a_i (.clk(clk), .din(b4_g0_o[12]), .dout(b5_l12_a));
    logic [59:0] b5_l12_p;
    MS_N16_q60_P32_tpm_twmul b5_l12_mul (.clk(clk), .A(b5_l12_a), .B(b5_t12), .QH(QH[16:0]), .P(b5_l12_p));
    logic [59:0] b5_l13_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l13_a_i (.clk(clk), .din(b4_g0_o[13]), .dout(b5_l13_a));
    logic [59:0] b5_l13_p;
    MS_N16_q60_P32_tpm_twmul b5_l13_mul (.clk(clk), .A(b5_l13_a), .B(b5_t13), .QH(QH[16:0]), .P(b5_l13_p));
    logic [59:0] b5_l14_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l14_a_i (.clk(clk), .din(b4_g0_o[14]), .dout(b5_l14_a));
    logic [59:0] b5_l14_p;
    MS_N16_q60_P32_tpm_twmul b5_l14_mul (.clk(clk), .A(b5_l14_a), .B(b5_t14), .QH(QH[16:0]), .P(b5_l14_p));
    logic [59:0] b5_l15_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l15_a_i (.clk(clk), .din(b4_g0_o[15]), .dout(b5_l15_a));
    logic [59:0] b5_l15_p;
    MS_N16_q60_P32_tpm_twmul b5_l15_mul (.clk(clk), .A(b5_l15_a), .B(b5_t15), .QH(QH[16:0]), .P(b5_l15_p));
    logic [59:0] b5_l16_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l16_a_i (.clk(clk), .din(b4_g1_o[0]), .dout(b5_l16_a));
    logic [59:0] b5_l16_p;
    MS_N16_q60_P32_tpm_twmul b5_l16_mul (.clk(clk), .A(b5_l16_a), .B(b5_t16), .QH(QH[16:0]), .P(b5_l16_p));
    logic [59:0] b5_l17_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l17_a_i (.clk(clk), .din(b4_g1_o[1]), .dout(b5_l17_a));
    logic [59:0] b5_l17_p;
    MS_N16_q60_P32_tpm_twmul b5_l17_mul (.clk(clk), .A(b5_l17_a), .B(b5_t17), .QH(QH[16:0]), .P(b5_l17_p));
    logic [59:0] b5_l18_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l18_a_i (.clk(clk), .din(b4_g1_o[2]), .dout(b5_l18_a));
    logic [59:0] b5_l18_p;
    MS_N16_q60_P32_tpm_twmul b5_l18_mul (.clk(clk), .A(b5_l18_a), .B(b5_t18), .QH(QH[16:0]), .P(b5_l18_p));
    logic [59:0] b5_l19_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l19_a_i (.clk(clk), .din(b4_g1_o[3]), .dout(b5_l19_a));
    logic [59:0] b5_l19_p;
    MS_N16_q60_P32_tpm_twmul b5_l19_mul (.clk(clk), .A(b5_l19_a), .B(b5_t19), .QH(QH[16:0]), .P(b5_l19_p));
    logic [59:0] b5_l20_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l20_a_i (.clk(clk), .din(b4_g1_o[4]), .dout(b5_l20_a));
    logic [59:0] b5_l20_p;
    MS_N16_q60_P32_tpm_twmul b5_l20_mul (.clk(clk), .A(b5_l20_a), .B(b5_t20), .QH(QH[16:0]), .P(b5_l20_p));
    logic [59:0] b5_l21_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l21_a_i (.clk(clk), .din(b4_g1_o[5]), .dout(b5_l21_a));
    logic [59:0] b5_l21_p;
    MS_N16_q60_P32_tpm_twmul b5_l21_mul (.clk(clk), .A(b5_l21_a), .B(b5_t21), .QH(QH[16:0]), .P(b5_l21_p));
    logic [59:0] b5_l22_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l22_a_i (.clk(clk), .din(b4_g1_o[6]), .dout(b5_l22_a));
    logic [59:0] b5_l22_p;
    MS_N16_q60_P32_tpm_twmul b5_l22_mul (.clk(clk), .A(b5_l22_a), .B(b5_t22), .QH(QH[16:0]), .P(b5_l22_p));
    logic [59:0] b5_l23_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l23_a_i (.clk(clk), .din(b4_g1_o[7]), .dout(b5_l23_a));
    logic [59:0] b5_l23_p;
    MS_N16_q60_P32_tpm_twmul b5_l23_mul (.clk(clk), .A(b5_l23_a), .B(b5_t23), .QH(QH[16:0]), .P(b5_l23_p));
    logic [59:0] b5_l24_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l24_a_i (.clk(clk), .din(b4_g1_o[8]), .dout(b5_l24_a));
    logic [59:0] b5_l24_p;
    MS_N16_q60_P32_tpm_twmul b5_l24_mul (.clk(clk), .A(b5_l24_a), .B(b5_t24), .QH(QH[16:0]), .P(b5_l24_p));
    logic [59:0] b5_l25_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l25_a_i (.clk(clk), .din(b4_g1_o[9]), .dout(b5_l25_a));
    logic [59:0] b5_l25_p;
    MS_N16_q60_P32_tpm_twmul b5_l25_mul (.clk(clk), .A(b5_l25_a), .B(b5_t25), .QH(QH[16:0]), .P(b5_l25_p));
    logic [59:0] b5_l26_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l26_a_i (.clk(clk), .din(b4_g1_o[10]), .dout(b5_l26_a));
    logic [59:0] b5_l26_p;
    MS_N16_q60_P32_tpm_twmul b5_l26_mul (.clk(clk), .A(b5_l26_a), .B(b5_t26), .QH(QH[16:0]), .P(b5_l26_p));
    logic [59:0] b5_l27_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l27_a_i (.clk(clk), .din(b4_g1_o[11]), .dout(b5_l27_a));
    logic [59:0] b5_l27_p;
    MS_N16_q60_P32_tpm_twmul b5_l27_mul (.clk(clk), .A(b5_l27_a), .B(b5_t27), .QH(QH[16:0]), .P(b5_l27_p));
    logic [59:0] b5_l28_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l28_a_i (.clk(clk), .din(b4_g1_o[12]), .dout(b5_l28_a));
    logic [59:0] b5_l28_p;
    MS_N16_q60_P32_tpm_twmul b5_l28_mul (.clk(clk), .A(b5_l28_a), .B(b5_t28), .QH(QH[16:0]), .P(b5_l28_p));
    logic [59:0] b5_l29_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l29_a_i (.clk(clk), .din(b4_g1_o[13]), .dout(b5_l29_a));
    logic [59:0] b5_l29_p;
    MS_N16_q60_P32_tpm_twmul b5_l29_mul (.clk(clk), .A(b5_l29_a), .B(b5_t29), .QH(QH[16:0]), .P(b5_l29_p));
    logic [59:0] b5_l30_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l30_a_i (.clk(clk), .din(b4_g1_o[14]), .dout(b5_l30_a));
    logic [59:0] b5_l30_p;
    MS_N16_q60_P32_tpm_twmul b5_l30_mul (.clk(clk), .A(b5_l30_a), .B(b5_t30), .QH(QH[16:0]), .P(b5_l30_p));
    logic [59:0] b5_l31_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(2)) b5_l31_a_i (.clk(clk), .din(b4_g1_o[15]), .dout(b5_l31_a));
    logic [59:0] b5_l31_p;
    MS_N16_q60_P32_tpm_twmul b5_l31_mul (.clk(clk), .A(b5_l31_a), .B(b5_t31), .QH(QH[16:0]), .P(b5_l31_p));
    logic [13:0] b5_v_sr;
    always_ff @(posedge clk) b5_v_sr <= rst ? '0 : {b5_v_sr[12:0], b4_g0_v};
    logic b5_v; assign b5_v = b5_v_sr[13];
    logic [0:0] b5_tag;
    MS_N16_q60_P32_tpm_dly_c #(.W(1), .D(14)) b5_tag_i (.clk(clk), .din(b4_tag), .dout(b5_tag));
    // block 6: pass 2, 2 x MS_N16_q60_P32_tpm_p2 (16-point), latency 51
    logic [59:0] b6_c0_y0, b6_c0_y1, b6_c0_y2, b6_c0_y3, b6_c0_y4, b6_c0_y5, b6_c0_y6, b6_c0_y7, b6_c0_y8, b6_c0_y9, b6_c0_y10, b6_c0_y11, b6_c0_y12, b6_c0_y13, b6_c0_y14, b6_c0_y15;
    logic b6_c0_v; logic b6_c0_di;
    logic b6_c0_lr, b6_c0_lw; (* equivalent_register_removal = "no" *) logic [59:0] b6_c0_ld;
    always_ff @(posedge clk) begin b6_c0_lr <= ld_r; b6_c0_lw <= ld_v && ld_iq >= 14'd36 && ld_iq < 14'd50; b6_c0_ld <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_p2 b6_c0 (.clk(clk), .rst(rst), .in_valid(b5_v), .out_valid(b6_c0_v), .DIR(b5_tag[0]), .tw_rst(b6_c0_lr), .tw_wen(b6_c0_lw), .tw_wdata(b6_c0_ld), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(b5_l0_p), .x_in_1(b5_l1_p), .x_in_2(b5_l2_p), .x_in_3(b5_l3_p), .x_in_4(b5_l4_p), .x_in_5(b5_l5_p), .x_in_6(b5_l6_p), .x_in_7(b5_l7_p), .x_in_8(b5_l8_p), .x_in_9(b5_l9_p), .x_in_10(b5_l10_p), .x_in_11(b5_l11_p), .x_in_12(b5_l12_p), .x_in_13(b5_l13_p), .x_in_14(b5_l14_p), .x_in_15(b5_l15_p), .y_out_0(b6_c0_y0), .y_out_1(b6_c0_y1), .y_out_2(b6_c0_y2), .y_out_3(b6_c0_y3), .y_out_4(b6_c0_y4), .y_out_5(b6_c0_y5), .y_out_6(b6_c0_y6), .y_out_7(b6_c0_y7), .y_out_8(b6_c0_y8), .y_out_9(b6_c0_y9), .y_out_10(b6_c0_y10), .y_out_11(b6_c0_y11), .y_out_12(b6_c0_y12), .y_out_13(b6_c0_y13), .y_out_14(b6_c0_y14), .y_out_15(b6_c0_y15));
    logic [59:0] b6_c1_y0, b6_c1_y1, b6_c1_y2, b6_c1_y3, b6_c1_y4, b6_c1_y5, b6_c1_y6, b6_c1_y7, b6_c1_y8, b6_c1_y9, b6_c1_y10, b6_c1_y11, b6_c1_y12, b6_c1_y13, b6_c1_y14, b6_c1_y15;
    logic b6_c1_v; logic b6_c1_di;
    logic b6_c1_lr, b6_c1_lw; (* equivalent_register_removal = "no" *) logic [59:0] b6_c1_ld;
    always_ff @(posedge clk) begin b6_c1_lr <= ld_r; b6_c1_lw <= ld_v && ld_iq >= 14'd36 && ld_iq < 14'd50; b6_c1_ld <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_p2 b6_c1 (.clk(clk), .rst(rst), .in_valid(b5_v), .out_valid(b6_c1_v), .DIR(b5_tag[0]), .tw_rst(b6_c1_lr), .tw_wen(b6_c1_lw), .tw_wdata(b6_c1_ld), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(b5_l16_p), .x_in_1(b5_l17_p), .x_in_2(b5_l18_p), .x_in_3(b5_l19_p), .x_in_4(b5_l20_p), .x_in_5(b5_l21_p), .x_in_6(b5_l22_p), .x_in_7(b5_l23_p), .x_in_8(b5_l24_p), .x_in_9(b5_l25_p), .x_in_10(b5_l26_p), .x_in_11(b5_l27_p), .x_in_12(b5_l28_p), .x_in_13(b5_l29_p), .x_in_14(b5_l30_p), .x_in_15(b5_l31_p), .y_out_0(b6_c1_y0), .y_out_1(b6_c1_y1), .y_out_2(b6_c1_y2), .y_out_3(b6_c1_y3), .y_out_4(b6_c1_y4), .y_out_5(b6_c1_y5), .y_out_6(b6_c1_y6), .y_out_7(b6_c1_y7), .y_out_8(b6_c1_y8), .y_out_9(b6_c1_y9), .y_out_10(b6_c1_y10), .y_out_11(b6_c1_y11), .y_out_12(b6_c1_y12), .y_out_13(b6_c1_y13), .y_out_14(b6_c1_y14), .y_out_15(b6_c1_y15));
    logic [0:0] b6_tag;
    MS_N16_q60_P32_tpm_dly_c #(.W(1), .D(51)) b6_tag_i (.clk(clk), .din(b5_tag), .dout(b6_tag));
    // block 7: lane-time transpose, lane bits [0, 1, 2, 3, 4] <-> cycle bits [0,5), 1 x S=32, latency 39
    logic [59:0] b7_g0_i [0:31]; logic [59:0] b7_g0_o [0:31]; logic b7_g0_v;
    assign b7_g0_i[0] = b6_c0_y0;
    assign b7_g0_i[1] = b6_c0_y1;
    assign b7_g0_i[2] = b6_c0_y2;
    assign b7_g0_i[3] = b6_c0_y3;
    assign b7_g0_i[4] = b6_c0_y4;
    assign b7_g0_i[5] = b6_c0_y5;
    assign b7_g0_i[6] = b6_c0_y6;
    assign b7_g0_i[7] = b6_c0_y7;
    assign b7_g0_i[8] = b6_c0_y8;
    assign b7_g0_i[9] = b6_c0_y9;
    assign b7_g0_i[10] = b6_c0_y10;
    assign b7_g0_i[11] = b6_c0_y11;
    assign b7_g0_i[12] = b6_c0_y12;
    assign b7_g0_i[13] = b6_c0_y13;
    assign b7_g0_i[14] = b6_c0_y14;
    assign b7_g0_i[15] = b6_c0_y15;
    assign b7_g0_i[16] = b6_c1_y0;
    assign b7_g0_i[17] = b6_c1_y1;
    assign b7_g0_i[18] = b6_c1_y2;
    assign b7_g0_i[19] = b6_c1_y3;
    assign b7_g0_i[20] = b6_c1_y4;
    assign b7_g0_i[21] = b6_c1_y5;
    assign b7_g0_i[22] = b6_c1_y6;
    assign b7_g0_i[23] = b6_c1_y7;
    assign b7_g0_i[24] = b6_c1_y8;
    assign b7_g0_i[25] = b6_c1_y9;
    assign b7_g0_i[26] = b6_c1_y10;
    assign b7_g0_i[27] = b6_c1_y11;
    assign b7_g0_i[28] = b6_c1_y12;
    assign b7_g0_i[29] = b6_c1_y13;
    assign b7_g0_i[30] = b6_c1_y14;
    assign b7_g0_i[31] = b6_c1_y15;
    lt_bmb_transpose #(.S(32), .LO(0), .ELEMENT_WIDTH(60), .REG_FLAGS(32'h7), .RAM_STYLE("distributed")) b7_g0 (.clk(clk), .rst(rst), .data_valid(b6_c0_v), .data_in(b7_g0_i), .data_out_valid(b7_g0_v), .data_out(b7_g0_o));
    logic [0:0] b7_tag;
    MS_N16_q60_P32_tpm_dly_c #(.W(1), .D(39)) b7_tag_i (.clk(clk), .din(b6_tag), .dout(b7_tag));
    // block 8: twiddle stage 3, latency 26 (tables 2, generator 12, multiplier 12)
    logic [10:0] b8_cnt;
    always_ff @(posedge clk) b8_cnt <= rst ? '0 : (b7_g0_v ? b8_cnt + 1'b1 : b8_cnt);
    logic [59:0] b8_t0;
    logic b8_t0_lwe; logic [2:0] b8_t0_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t0_lwd;
    always_ff @(posedge clk) begin b8_t0_lwe <= ld_v && ld_iq >= 14'd4304 && ld_iq < 14'd4312; b8_t0_lwa <= 3'(ld_iq - 14'd4304); b8_t0_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab0 b8_t0_i (.clk(clk), .addr({b7_tag[0], b8_cnt[1], b8_cnt[0]}), .we(b8_t0_lwe), .wa(b8_t0_lwa), .wcol(1'b0), .wd(b8_t0_lwd), .q0(b8_t0));
    logic [59:0] b8_t1;
    logic b8_t1_lwe; logic [2:0] b8_t1_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t1_lwd;
    always_ff @(posedge clk) begin b8_t1_lwe <= ld_v && ld_iq >= 14'd4312 && ld_iq < 14'd4320; b8_t1_lwa <= 3'(ld_iq - 14'd4312); b8_t1_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab1 b8_t1_i (.clk(clk), .addr({b7_tag[0], b8_cnt[3], b8_cnt[2]}), .we(b8_t1_lwe), .wa(b8_t1_lwa), .wcol(1'b0), .wd(b8_t1_lwd), .q0(b8_t1));
    logic [59:0] b8_t2;
    logic b8_t2_lwe; logic [6:0] b8_t2_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t2_lwd;
    always_ff @(posedge clk) begin b8_t2_lwe <= ld_v && ld_iq >= 14'd4320 && ld_iq < 14'd4448; b8_t2_lwa <= 7'(ld_iq - 14'd4320); b8_t2_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab2 b8_t2_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t2_lwe), .wa(b8_t2_lwa), .wcol(1'b0), .wd(b8_t2_lwd), .q0(b8_t2));
    logic [59:0] b8_t3;
    logic b8_t3_lwe; logic [5:0] b8_t3_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t3_lwd;
    always_ff @(posedge clk) begin b8_t3_lwe <= ld_v && ld_iq >= 14'd4448 && ld_iq < 14'd4512; b8_t3_lwa <= 6'(ld_iq - 14'd4448); b8_t3_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab3 b8_t3_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t3_lwe), .wa(b8_t3_lwa), .wcol(1'b0), .wd(b8_t3_lwd), .q0(b8_t3));
    logic [59:0] b8_t4;
    logic b8_t4_lwe; logic [6:0] b8_t4_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t4_lwd;
    always_ff @(posedge clk) begin b8_t4_lwe <= ld_v && ld_iq >= 14'd4512 && ld_iq < 14'd4640; b8_t4_lwa <= 7'(ld_iq - 14'd4512); b8_t4_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab4 b8_t4_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t4_lwe), .wa(b8_t4_lwa), .wcol(1'b0), .wd(b8_t4_lwd), .q0(b8_t4));
    logic [59:0] b8_t5;
    logic b8_t5_lwe; logic [5:0] b8_t5_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t5_lwd;
    always_ff @(posedge clk) begin b8_t5_lwe <= ld_v && ld_iq >= 14'd4640 && ld_iq < 14'd4704; b8_t5_lwa <= 6'(ld_iq - 14'd4640); b8_t5_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab5 b8_t5_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t5_lwe), .wa(b8_t5_lwa), .wcol(1'b0), .wd(b8_t5_lwd), .q0(b8_t5));
    logic [59:0] b8_t6;
    logic b8_t6_lwe; logic [6:0] b8_t6_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t6_lwd;
    always_ff @(posedge clk) begin b8_t6_lwe <= ld_v && ld_iq >= 14'd4704 && ld_iq < 14'd4832; b8_t6_lwa <= 7'(ld_iq - 14'd4704); b8_t6_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab6 b8_t6_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t6_lwe), .wa(b8_t6_lwa), .wcol(1'b0), .wd(b8_t6_lwd), .q0(b8_t6));
    logic [59:0] b8_t7;
    logic b8_t7_lwe; logic [5:0] b8_t7_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t7_lwd;
    always_ff @(posedge clk) begin b8_t7_lwe <= ld_v && ld_iq >= 14'd4832 && ld_iq < 14'd4896; b8_t7_lwa <= 6'(ld_iq - 14'd4832); b8_t7_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab7 b8_t7_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t7_lwe), .wa(b8_t7_lwa), .wcol(1'b0), .wd(b8_t7_lwd), .q0(b8_t7));
    logic [59:0] b8_t8;
    logic b8_t8_lwe; logic [6:0] b8_t8_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t8_lwd;
    always_ff @(posedge clk) begin b8_t8_lwe <= ld_v && ld_iq >= 14'd4896 && ld_iq < 14'd5024; b8_t8_lwa <= 7'(ld_iq - 14'd4896); b8_t8_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab8 b8_t8_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t8_lwe), .wa(b8_t8_lwa), .wcol(1'b0), .wd(b8_t8_lwd), .q0(b8_t8));
    logic [59:0] b8_t9;
    logic b8_t9_lwe; logic [5:0] b8_t9_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t9_lwd;
    always_ff @(posedge clk) begin b8_t9_lwe <= ld_v && ld_iq >= 14'd5024 && ld_iq < 14'd5088; b8_t9_lwa <= 6'(ld_iq - 14'd5024); b8_t9_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab9 b8_t9_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t9_lwe), .wa(b8_t9_lwa), .wcol(1'b0), .wd(b8_t9_lwd), .q0(b8_t9));
    logic [59:0] b8_t10;
    logic b8_t10_lwe; logic [6:0] b8_t10_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t10_lwd;
    always_ff @(posedge clk) begin b8_t10_lwe <= ld_v && ld_iq >= 14'd5088 && ld_iq < 14'd5216; b8_t10_lwa <= 7'(ld_iq - 14'd5088); b8_t10_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab10 b8_t10_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t10_lwe), .wa(b8_t10_lwa), .wcol(1'b0), .wd(b8_t10_lwd), .q0(b8_t10));
    logic [59:0] b8_t11;
    logic b8_t11_lwe; logic [5:0] b8_t11_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t11_lwd;
    always_ff @(posedge clk) begin b8_t11_lwe <= ld_v && ld_iq >= 14'd5216 && ld_iq < 14'd5280; b8_t11_lwa <= 6'(ld_iq - 14'd5216); b8_t11_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab11 b8_t11_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t11_lwe), .wa(b8_t11_lwa), .wcol(1'b0), .wd(b8_t11_lwd), .q0(b8_t11));
    logic [59:0] b8_t12;
    logic b8_t12_lwe; logic [6:0] b8_t12_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t12_lwd;
    always_ff @(posedge clk) begin b8_t12_lwe <= ld_v && ld_iq >= 14'd5280 && ld_iq < 14'd5408; b8_t12_lwa <= 7'(ld_iq - 14'd5280); b8_t12_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab12 b8_t12_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t12_lwe), .wa(b8_t12_lwa), .wcol(1'b0), .wd(b8_t12_lwd), .q0(b8_t12));
    logic [59:0] b8_t13;
    logic b8_t13_lwe; logic [5:0] b8_t13_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t13_lwd;
    always_ff @(posedge clk) begin b8_t13_lwe <= ld_v && ld_iq >= 14'd5408 && ld_iq < 14'd5472; b8_t13_lwa <= 6'(ld_iq - 14'd5408); b8_t13_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab13 b8_t13_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t13_lwe), .wa(b8_t13_lwa), .wcol(1'b0), .wd(b8_t13_lwd), .q0(b8_t13));
    logic [59:0] b8_t14;
    logic b8_t14_lwe; logic [6:0] b8_t14_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t14_lwd;
    always_ff @(posedge clk) begin b8_t14_lwe <= ld_v && ld_iq >= 14'd5472 && ld_iq < 14'd5600; b8_t14_lwa <= 7'(ld_iq - 14'd5472); b8_t14_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab14 b8_t14_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t14_lwe), .wa(b8_t14_lwa), .wcol(1'b0), .wd(b8_t14_lwd), .q0(b8_t14));
    logic [59:0] b8_t15;
    logic b8_t15_lwe; logic [5:0] b8_t15_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t15_lwd;
    always_ff @(posedge clk) begin b8_t15_lwe <= ld_v && ld_iq >= 14'd5600 && ld_iq < 14'd5664; b8_t15_lwa <= 6'(ld_iq - 14'd5600); b8_t15_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab15 b8_t15_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t15_lwe), .wa(b8_t15_lwa), .wcol(1'b0), .wd(b8_t15_lwd), .q0(b8_t15));
    logic [59:0] b8_t16;
    logic b8_t16_lwe; logic [6:0] b8_t16_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t16_lwd;
    always_ff @(posedge clk) begin b8_t16_lwe <= ld_v && ld_iq >= 14'd5664 && ld_iq < 14'd5792; b8_t16_lwa <= 7'(ld_iq - 14'd5664); b8_t16_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab16 b8_t16_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t16_lwe), .wa(b8_t16_lwa), .wcol(1'b0), .wd(b8_t16_lwd), .q0(b8_t16));
    logic [59:0] b8_t17;
    logic b8_t17_lwe; logic [5:0] b8_t17_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t17_lwd;
    always_ff @(posedge clk) begin b8_t17_lwe <= ld_v && ld_iq >= 14'd5792 && ld_iq < 14'd5856; b8_t17_lwa <= 6'(ld_iq - 14'd5792); b8_t17_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab17 b8_t17_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t17_lwe), .wa(b8_t17_lwa), .wcol(1'b0), .wd(b8_t17_lwd), .q0(b8_t17));
    logic [59:0] b8_t18;
    logic b8_t18_lwe; logic [6:0] b8_t18_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t18_lwd;
    always_ff @(posedge clk) begin b8_t18_lwe <= ld_v && ld_iq >= 14'd5856 && ld_iq < 14'd5984; b8_t18_lwa <= 7'(ld_iq - 14'd5856); b8_t18_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab18 b8_t18_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t18_lwe), .wa(b8_t18_lwa), .wcol(1'b0), .wd(b8_t18_lwd), .q0(b8_t18));
    logic [59:0] b8_t19;
    logic b8_t19_lwe; logic [5:0] b8_t19_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t19_lwd;
    always_ff @(posedge clk) begin b8_t19_lwe <= ld_v && ld_iq >= 14'd5984 && ld_iq < 14'd6048; b8_t19_lwa <= 6'(ld_iq - 14'd5984); b8_t19_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab19 b8_t19_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t19_lwe), .wa(b8_t19_lwa), .wcol(1'b0), .wd(b8_t19_lwd), .q0(b8_t19));
    logic [59:0] b8_t20;
    logic b8_t20_lwe; logic [6:0] b8_t20_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t20_lwd;
    always_ff @(posedge clk) begin b8_t20_lwe <= ld_v && ld_iq >= 14'd6048 && ld_iq < 14'd6176; b8_t20_lwa <= 7'(ld_iq - 14'd6048); b8_t20_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab20 b8_t20_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t20_lwe), .wa(b8_t20_lwa), .wcol(1'b0), .wd(b8_t20_lwd), .q0(b8_t20));
    logic [59:0] b8_t21;
    logic b8_t21_lwe; logic [5:0] b8_t21_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t21_lwd;
    always_ff @(posedge clk) begin b8_t21_lwe <= ld_v && ld_iq >= 14'd6176 && ld_iq < 14'd6240; b8_t21_lwa <= 6'(ld_iq - 14'd6176); b8_t21_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab21 b8_t21_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t21_lwe), .wa(b8_t21_lwa), .wcol(1'b0), .wd(b8_t21_lwd), .q0(b8_t21));
    logic [59:0] b8_t22;
    logic b8_t22_lwe; logic [6:0] b8_t22_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t22_lwd;
    always_ff @(posedge clk) begin b8_t22_lwe <= ld_v && ld_iq >= 14'd6240 && ld_iq < 14'd6368; b8_t22_lwa <= 7'(ld_iq - 14'd6240); b8_t22_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab22 b8_t22_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t22_lwe), .wa(b8_t22_lwa), .wcol(1'b0), .wd(b8_t22_lwd), .q0(b8_t22));
    logic [59:0] b8_t23;
    logic b8_t23_lwe; logic [5:0] b8_t23_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t23_lwd;
    always_ff @(posedge clk) begin b8_t23_lwe <= ld_v && ld_iq >= 14'd6368 && ld_iq < 14'd6432; b8_t23_lwa <= 6'(ld_iq - 14'd6368); b8_t23_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab23 b8_t23_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t23_lwe), .wa(b8_t23_lwa), .wcol(1'b0), .wd(b8_t23_lwd), .q0(b8_t23));
    logic [59:0] b8_t24;
    logic b8_t24_lwe; logic [6:0] b8_t24_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t24_lwd;
    always_ff @(posedge clk) begin b8_t24_lwe <= ld_v && ld_iq >= 14'd6432 && ld_iq < 14'd6560; b8_t24_lwa <= 7'(ld_iq - 14'd6432); b8_t24_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab24 b8_t24_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t24_lwe), .wa(b8_t24_lwa), .wcol(1'b0), .wd(b8_t24_lwd), .q0(b8_t24));
    logic [59:0] b8_t25;
    logic b8_t25_lwe; logic [5:0] b8_t25_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t25_lwd;
    always_ff @(posedge clk) begin b8_t25_lwe <= ld_v && ld_iq >= 14'd6560 && ld_iq < 14'd6624; b8_t25_lwa <= 6'(ld_iq - 14'd6560); b8_t25_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab25 b8_t25_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t25_lwe), .wa(b8_t25_lwa), .wcol(1'b0), .wd(b8_t25_lwd), .q0(b8_t25));
    logic [59:0] b8_t26;
    logic b8_t26_lwe; logic [6:0] b8_t26_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t26_lwd;
    always_ff @(posedge clk) begin b8_t26_lwe <= ld_v && ld_iq >= 14'd6624 && ld_iq < 14'd6752; b8_t26_lwa <= 7'(ld_iq - 14'd6624); b8_t26_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab26 b8_t26_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t26_lwe), .wa(b8_t26_lwa), .wcol(1'b0), .wd(b8_t26_lwd), .q0(b8_t26));
    logic [59:0] b8_t27;
    logic b8_t27_lwe; logic [5:0] b8_t27_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t27_lwd;
    always_ff @(posedge clk) begin b8_t27_lwe <= ld_v && ld_iq >= 14'd6752 && ld_iq < 14'd6816; b8_t27_lwa <= 6'(ld_iq - 14'd6752); b8_t27_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab27 b8_t27_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t27_lwe), .wa(b8_t27_lwa), .wcol(1'b0), .wd(b8_t27_lwd), .q0(b8_t27));
    logic [59:0] b8_t28;
    logic b8_t28_lwe; logic [6:0] b8_t28_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t28_lwd;
    always_ff @(posedge clk) begin b8_t28_lwe <= ld_v && ld_iq >= 14'd6816 && ld_iq < 14'd6944; b8_t28_lwa <= 7'(ld_iq - 14'd6816); b8_t28_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab28 b8_t28_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t28_lwe), .wa(b8_t28_lwa), .wcol(1'b0), .wd(b8_t28_lwd), .q0(b8_t28));
    logic [59:0] b8_t29;
    logic b8_t29_lwe; logic [5:0] b8_t29_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t29_lwd;
    always_ff @(posedge clk) begin b8_t29_lwe <= ld_v && ld_iq >= 14'd6944 && ld_iq < 14'd7008; b8_t29_lwa <= 6'(ld_iq - 14'd6944); b8_t29_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab29 b8_t29_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t29_lwe), .wa(b8_t29_lwa), .wcol(1'b0), .wd(b8_t29_lwd), .q0(b8_t29));
    logic [59:0] b8_t30;
    logic b8_t30_lwe; logic [6:0] b8_t30_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t30_lwd;
    always_ff @(posedge clk) begin b8_t30_lwe <= ld_v && ld_iq >= 14'd7008 && ld_iq < 14'd7136; b8_t30_lwa <= 7'(ld_iq - 14'd7008); b8_t30_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab30 b8_t30_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t30_lwe), .wa(b8_t30_lwa), .wcol(1'b0), .wd(b8_t30_lwd), .q0(b8_t30));
    logic [59:0] b8_t31;
    logic b8_t31_lwe; logic [5:0] b8_t31_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t31_lwd;
    always_ff @(posedge clk) begin b8_t31_lwe <= ld_v && ld_iq >= 14'd7136 && ld_iq < 14'd7200; b8_t31_lwa <= 6'(ld_iq - 14'd7136); b8_t31_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab31 b8_t31_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t31_lwe), .wa(b8_t31_lwa), .wcol(1'b0), .wd(b8_t31_lwd), .q0(b8_t31));
    logic [59:0] b8_t32;
    logic b8_t32_lwe; logic [6:0] b8_t32_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t32_lwd;
    always_ff @(posedge clk) begin b8_t32_lwe <= ld_v && ld_iq >= 14'd7200 && ld_iq < 14'd7328; b8_t32_lwa <= 7'(ld_iq - 14'd7200); b8_t32_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab32 b8_t32_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t32_lwe), .wa(b8_t32_lwa), .wcol(1'b0), .wd(b8_t32_lwd), .q0(b8_t32));
    logic [59:0] b8_t33;
    logic b8_t33_lwe; logic [5:0] b8_t33_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t33_lwd;
    always_ff @(posedge clk) begin b8_t33_lwe <= ld_v && ld_iq >= 14'd7328 && ld_iq < 14'd7392; b8_t33_lwa <= 6'(ld_iq - 14'd7328); b8_t33_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab33 b8_t33_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t33_lwe), .wa(b8_t33_lwa), .wcol(1'b0), .wd(b8_t33_lwd), .q0(b8_t33));
    logic [59:0] b8_t34;
    logic b8_t34_lwe; logic [6:0] b8_t34_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t34_lwd;
    always_ff @(posedge clk) begin b8_t34_lwe <= ld_v && ld_iq >= 14'd7392 && ld_iq < 14'd7520; b8_t34_lwa <= 7'(ld_iq - 14'd7392); b8_t34_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab34 b8_t34_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t34_lwe), .wa(b8_t34_lwa), .wcol(1'b0), .wd(b8_t34_lwd), .q0(b8_t34));
    logic [59:0] b8_t35;
    logic b8_t35_lwe; logic [5:0] b8_t35_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t35_lwd;
    always_ff @(posedge clk) begin b8_t35_lwe <= ld_v && ld_iq >= 14'd7520 && ld_iq < 14'd7584; b8_t35_lwa <= 6'(ld_iq - 14'd7520); b8_t35_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab35 b8_t35_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t35_lwe), .wa(b8_t35_lwa), .wcol(1'b0), .wd(b8_t35_lwd), .q0(b8_t35));
    logic [59:0] b8_t36;
    logic b8_t36_lwe; logic [6:0] b8_t36_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t36_lwd;
    always_ff @(posedge clk) begin b8_t36_lwe <= ld_v && ld_iq >= 14'd7584 && ld_iq < 14'd7712; b8_t36_lwa <= 7'(ld_iq - 14'd7584); b8_t36_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab36 b8_t36_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t36_lwe), .wa(b8_t36_lwa), .wcol(1'b0), .wd(b8_t36_lwd), .q0(b8_t36));
    logic [59:0] b8_t37;
    logic b8_t37_lwe; logic [5:0] b8_t37_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t37_lwd;
    always_ff @(posedge clk) begin b8_t37_lwe <= ld_v && ld_iq >= 14'd7712 && ld_iq < 14'd7776; b8_t37_lwa <= 6'(ld_iq - 14'd7712); b8_t37_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab37 b8_t37_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t37_lwe), .wa(b8_t37_lwa), .wcol(1'b0), .wd(b8_t37_lwd), .q0(b8_t37));
    logic [59:0] b8_t38;
    logic b8_t38_lwe; logic [6:0] b8_t38_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t38_lwd;
    always_ff @(posedge clk) begin b8_t38_lwe <= ld_v && ld_iq >= 14'd7776 && ld_iq < 14'd7904; b8_t38_lwa <= 7'(ld_iq - 14'd7776); b8_t38_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab38 b8_t38_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t38_lwe), .wa(b8_t38_lwa), .wcol(1'b0), .wd(b8_t38_lwd), .q0(b8_t38));
    logic [59:0] b8_t39;
    logic b8_t39_lwe; logic [5:0] b8_t39_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t39_lwd;
    always_ff @(posedge clk) begin b8_t39_lwe <= ld_v && ld_iq >= 14'd7904 && ld_iq < 14'd7968; b8_t39_lwa <= 6'(ld_iq - 14'd7904); b8_t39_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab39 b8_t39_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t39_lwe), .wa(b8_t39_lwa), .wcol(1'b0), .wd(b8_t39_lwd), .q0(b8_t39));
    logic [59:0] b8_t40;
    logic b8_t40_lwe; logic [6:0] b8_t40_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t40_lwd;
    always_ff @(posedge clk) begin b8_t40_lwe <= ld_v && ld_iq >= 14'd7968 && ld_iq < 14'd8096; b8_t40_lwa <= 7'(ld_iq - 14'd7968); b8_t40_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab40 b8_t40_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t40_lwe), .wa(b8_t40_lwa), .wcol(1'b0), .wd(b8_t40_lwd), .q0(b8_t40));
    logic [59:0] b8_t41;
    logic b8_t41_lwe; logic [5:0] b8_t41_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t41_lwd;
    always_ff @(posedge clk) begin b8_t41_lwe <= ld_v && ld_iq >= 14'd8096 && ld_iq < 14'd8160; b8_t41_lwa <= 6'(ld_iq - 14'd8096); b8_t41_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab41 b8_t41_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t41_lwe), .wa(b8_t41_lwa), .wcol(1'b0), .wd(b8_t41_lwd), .q0(b8_t41));
    logic [59:0] b8_t42;
    logic b8_t42_lwe; logic [6:0] b8_t42_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t42_lwd;
    always_ff @(posedge clk) begin b8_t42_lwe <= ld_v && ld_iq >= 14'd8160 && ld_iq < 14'd8288; b8_t42_lwa <= 7'(ld_iq - 14'd8160); b8_t42_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab42 b8_t42_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t42_lwe), .wa(b8_t42_lwa), .wcol(1'b0), .wd(b8_t42_lwd), .q0(b8_t42));
    logic [59:0] b8_t43;
    logic b8_t43_lwe; logic [5:0] b8_t43_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t43_lwd;
    always_ff @(posedge clk) begin b8_t43_lwe <= ld_v && ld_iq >= 14'd8288 && ld_iq < 14'd8352; b8_t43_lwa <= 6'(ld_iq - 14'd8288); b8_t43_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab43 b8_t43_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t43_lwe), .wa(b8_t43_lwa), .wcol(1'b0), .wd(b8_t43_lwd), .q0(b8_t43));
    logic [59:0] b8_t44;
    logic b8_t44_lwe; logic [6:0] b8_t44_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t44_lwd;
    always_ff @(posedge clk) begin b8_t44_lwe <= ld_v && ld_iq >= 14'd8352 && ld_iq < 14'd8480; b8_t44_lwa <= 7'(ld_iq - 14'd8352); b8_t44_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab44 b8_t44_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t44_lwe), .wa(b8_t44_lwa), .wcol(1'b0), .wd(b8_t44_lwd), .q0(b8_t44));
    logic [59:0] b8_t45;
    logic b8_t45_lwe; logic [5:0] b8_t45_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t45_lwd;
    always_ff @(posedge clk) begin b8_t45_lwe <= ld_v && ld_iq >= 14'd8480 && ld_iq < 14'd8544; b8_t45_lwa <= 6'(ld_iq - 14'd8480); b8_t45_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab45 b8_t45_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t45_lwe), .wa(b8_t45_lwa), .wcol(1'b0), .wd(b8_t45_lwd), .q0(b8_t45));
    logic [59:0] b8_t46;
    logic b8_t46_lwe; logic [6:0] b8_t46_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t46_lwd;
    always_ff @(posedge clk) begin b8_t46_lwe <= ld_v && ld_iq >= 14'd8544 && ld_iq < 14'd8672; b8_t46_lwa <= 7'(ld_iq - 14'd8544); b8_t46_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab46 b8_t46_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t46_lwe), .wa(b8_t46_lwa), .wcol(1'b0), .wd(b8_t46_lwd), .q0(b8_t46));
    logic [59:0] b8_t47;
    logic b8_t47_lwe; logic [5:0] b8_t47_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t47_lwd;
    always_ff @(posedge clk) begin b8_t47_lwe <= ld_v && ld_iq >= 14'd8672 && ld_iq < 14'd8736; b8_t47_lwa <= 6'(ld_iq - 14'd8672); b8_t47_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab47 b8_t47_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t47_lwe), .wa(b8_t47_lwa), .wcol(1'b0), .wd(b8_t47_lwd), .q0(b8_t47));
    logic [59:0] b8_t48;
    logic b8_t48_lwe; logic [6:0] b8_t48_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t48_lwd;
    always_ff @(posedge clk) begin b8_t48_lwe <= ld_v && ld_iq >= 14'd8736 && ld_iq < 14'd8864; b8_t48_lwa <= 7'(ld_iq - 14'd8736); b8_t48_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab48 b8_t48_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t48_lwe), .wa(b8_t48_lwa), .wcol(1'b0), .wd(b8_t48_lwd), .q0(b8_t48));
    logic [59:0] b8_t49;
    logic b8_t49_lwe; logic [5:0] b8_t49_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t49_lwd;
    always_ff @(posedge clk) begin b8_t49_lwe <= ld_v && ld_iq >= 14'd8864 && ld_iq < 14'd8928; b8_t49_lwa <= 6'(ld_iq - 14'd8864); b8_t49_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab49 b8_t49_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t49_lwe), .wa(b8_t49_lwa), .wcol(1'b0), .wd(b8_t49_lwd), .q0(b8_t49));
    logic [59:0] b8_t50;
    logic b8_t50_lwe; logic [6:0] b8_t50_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t50_lwd;
    always_ff @(posedge clk) begin b8_t50_lwe <= ld_v && ld_iq >= 14'd8928 && ld_iq < 14'd9056; b8_t50_lwa <= 7'(ld_iq - 14'd8928); b8_t50_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab50 b8_t50_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t50_lwe), .wa(b8_t50_lwa), .wcol(1'b0), .wd(b8_t50_lwd), .q0(b8_t50));
    logic [59:0] b8_t51;
    logic b8_t51_lwe; logic [5:0] b8_t51_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t51_lwd;
    always_ff @(posedge clk) begin b8_t51_lwe <= ld_v && ld_iq >= 14'd9056 && ld_iq < 14'd9120; b8_t51_lwa <= 6'(ld_iq - 14'd9056); b8_t51_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab51 b8_t51_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t51_lwe), .wa(b8_t51_lwa), .wcol(1'b0), .wd(b8_t51_lwd), .q0(b8_t51));
    logic [59:0] b8_t52;
    logic b8_t52_lwe; logic [6:0] b8_t52_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t52_lwd;
    always_ff @(posedge clk) begin b8_t52_lwe <= ld_v && ld_iq >= 14'd9120 && ld_iq < 14'd9248; b8_t52_lwa <= 7'(ld_iq - 14'd9120); b8_t52_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab52 b8_t52_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t52_lwe), .wa(b8_t52_lwa), .wcol(1'b0), .wd(b8_t52_lwd), .q0(b8_t52));
    logic [59:0] b8_t53;
    logic b8_t53_lwe; logic [5:0] b8_t53_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t53_lwd;
    always_ff @(posedge clk) begin b8_t53_lwe <= ld_v && ld_iq >= 14'd9248 && ld_iq < 14'd9312; b8_t53_lwa <= 6'(ld_iq - 14'd9248); b8_t53_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab53 b8_t53_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t53_lwe), .wa(b8_t53_lwa), .wcol(1'b0), .wd(b8_t53_lwd), .q0(b8_t53));
    logic [59:0] b8_t54;
    logic b8_t54_lwe; logic [6:0] b8_t54_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t54_lwd;
    always_ff @(posedge clk) begin b8_t54_lwe <= ld_v && ld_iq >= 14'd9312 && ld_iq < 14'd9440; b8_t54_lwa <= 7'(ld_iq - 14'd9312); b8_t54_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab54 b8_t54_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t54_lwe), .wa(b8_t54_lwa), .wcol(1'b0), .wd(b8_t54_lwd), .q0(b8_t54));
    logic [59:0] b8_t55;
    logic b8_t55_lwe; logic [5:0] b8_t55_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t55_lwd;
    always_ff @(posedge clk) begin b8_t55_lwe <= ld_v && ld_iq >= 14'd9440 && ld_iq < 14'd9504; b8_t55_lwa <= 6'(ld_iq - 14'd9440); b8_t55_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab55 b8_t55_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t55_lwe), .wa(b8_t55_lwa), .wcol(1'b0), .wd(b8_t55_lwd), .q0(b8_t55));
    logic [59:0] b8_t56;
    logic b8_t56_lwe; logic [6:0] b8_t56_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t56_lwd;
    always_ff @(posedge clk) begin b8_t56_lwe <= ld_v && ld_iq >= 14'd9504 && ld_iq < 14'd9632; b8_t56_lwa <= 7'(ld_iq - 14'd9504); b8_t56_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab56 b8_t56_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t56_lwe), .wa(b8_t56_lwa), .wcol(1'b0), .wd(b8_t56_lwd), .q0(b8_t56));
    logic [59:0] b8_t57;
    logic b8_t57_lwe; logic [5:0] b8_t57_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t57_lwd;
    always_ff @(posedge clk) begin b8_t57_lwe <= ld_v && ld_iq >= 14'd9632 && ld_iq < 14'd9696; b8_t57_lwa <= 6'(ld_iq - 14'd9632); b8_t57_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab57 b8_t57_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t57_lwe), .wa(b8_t57_lwa), .wcol(1'b0), .wd(b8_t57_lwd), .q0(b8_t57));
    logic [59:0] b8_t58;
    logic b8_t58_lwe; logic [6:0] b8_t58_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t58_lwd;
    always_ff @(posedge clk) begin b8_t58_lwe <= ld_v && ld_iq >= 14'd9696 && ld_iq < 14'd9824; b8_t58_lwa <= 7'(ld_iq - 14'd9696); b8_t58_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab58 b8_t58_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t58_lwe), .wa(b8_t58_lwa), .wcol(1'b0), .wd(b8_t58_lwd), .q0(b8_t58));
    logic [59:0] b8_t59;
    logic b8_t59_lwe; logic [5:0] b8_t59_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t59_lwd;
    always_ff @(posedge clk) begin b8_t59_lwe <= ld_v && ld_iq >= 14'd9824 && ld_iq < 14'd9888; b8_t59_lwa <= 6'(ld_iq - 14'd9824); b8_t59_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab59 b8_t59_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t59_lwe), .wa(b8_t59_lwa), .wcol(1'b0), .wd(b8_t59_lwd), .q0(b8_t59));
    logic [59:0] b8_t60;
    logic b8_t60_lwe; logic [6:0] b8_t60_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t60_lwd;
    always_ff @(posedge clk) begin b8_t60_lwe <= ld_v && ld_iq >= 14'd9888 && ld_iq < 14'd10016; b8_t60_lwa <= 7'(ld_iq - 14'd9888); b8_t60_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab60 b8_t60_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t60_lwe), .wa(b8_t60_lwa), .wcol(1'b0), .wd(b8_t60_lwd), .q0(b8_t60));
    logic [59:0] b8_t61;
    logic b8_t61_lwe; logic [5:0] b8_t61_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t61_lwd;
    always_ff @(posedge clk) begin b8_t61_lwe <= ld_v && ld_iq >= 14'd10016 && ld_iq < 14'd10080; b8_t61_lwa <= 6'(ld_iq - 14'd10016); b8_t61_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab61 b8_t61_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t61_lwe), .wa(b8_t61_lwa), .wcol(1'b0), .wd(b8_t61_lwd), .q0(b8_t61));
    logic [59:0] b8_t62;
    logic b8_t62_lwe; logic [6:0] b8_t62_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t62_lwd;
    always_ff @(posedge clk) begin b8_t62_lwe <= ld_v && ld_iq >= 14'd10080 && ld_iq < 14'd10208; b8_t62_lwa <= 7'(ld_iq - 14'd10080); b8_t62_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab62 b8_t62_i (.clk(clk), .addr({b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t62_lwe), .wa(b8_t62_lwa), .wcol(1'b0), .wd(b8_t62_lwd), .q0(b8_t62));
    logic [59:0] b8_t63;
    logic b8_t63_lwe; logic [5:0] b8_t63_lwa; (* equivalent_register_removal = "no" *) logic [59:0] b8_t63_lwd;
    always_ff @(posedge clk) begin b8_t63_lwe <= ld_v && ld_iq >= 14'd10208 && ld_iq < 14'd10272; b8_t63_lwa <= 6'(ld_iq - 14'd10208); b8_t63_lwd <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_tw3_tab63 b8_t63_i (.clk(clk), .addr({b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t63_lwe), .wa(b8_t63_lwa), .wcol(1'b0), .wd(b8_t63_lwd), .q0(b8_t63));
    logic [59:0] b8_l0_w;
    MS_N16_q60_P32_tpm_twgen b8_l0_gen (.clk(clk), .A(b8_t0), .B(b8_t1), .QH(QH[16:0]), .P(b8_l0_w));
    logic [59:0] b8_l0_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l0_a_i (.clk(clk), .din(b7_g0_o[0]), .dout(b8_l0_a));
    logic [59:0] b8_l0_p;
    MS_N16_q60_P32_tpm_twmul b8_l0_mul (.clk(clk), .A(b8_l0_a), .B(b8_l0_w), .QH(QH[16:0]), .P(b8_l0_p));
    logic [59:0] b8_l1_w;
    MS_N16_q60_P32_tpm_twgen b8_l1_gen (.clk(clk), .A(b8_t2), .B(b8_t3), .QH(QH[16:0]), .P(b8_l1_w));
    logic [59:0] b8_l1_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l1_a_i (.clk(clk), .din(b7_g0_o[1]), .dout(b8_l1_a));
    logic [59:0] b8_l1_p;
    MS_N16_q60_P32_tpm_twmul b8_l1_mul (.clk(clk), .A(b8_l1_a), .B(b8_l1_w), .QH(QH[16:0]), .P(b8_l1_p));
    logic [59:0] b8_l2_w;
    MS_N16_q60_P32_tpm_twgen b8_l2_gen (.clk(clk), .A(b8_t4), .B(b8_t5), .QH(QH[16:0]), .P(b8_l2_w));
    logic [59:0] b8_l2_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l2_a_i (.clk(clk), .din(b7_g0_o[2]), .dout(b8_l2_a));
    logic [59:0] b8_l2_p;
    MS_N16_q60_P32_tpm_twmul b8_l2_mul (.clk(clk), .A(b8_l2_a), .B(b8_l2_w), .QH(QH[16:0]), .P(b8_l2_p));
    logic [59:0] b8_l3_w;
    MS_N16_q60_P32_tpm_twgen b8_l3_gen (.clk(clk), .A(b8_t6), .B(b8_t7), .QH(QH[16:0]), .P(b8_l3_w));
    logic [59:0] b8_l3_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l3_a_i (.clk(clk), .din(b7_g0_o[3]), .dout(b8_l3_a));
    logic [59:0] b8_l3_p;
    MS_N16_q60_P32_tpm_twmul b8_l3_mul (.clk(clk), .A(b8_l3_a), .B(b8_l3_w), .QH(QH[16:0]), .P(b8_l3_p));
    logic [59:0] b8_l4_w;
    MS_N16_q60_P32_tpm_twgen b8_l4_gen (.clk(clk), .A(b8_t8), .B(b8_t9), .QH(QH[16:0]), .P(b8_l4_w));
    logic [59:0] b8_l4_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l4_a_i (.clk(clk), .din(b7_g0_o[4]), .dout(b8_l4_a));
    logic [59:0] b8_l4_p;
    MS_N16_q60_P32_tpm_twmul b8_l4_mul (.clk(clk), .A(b8_l4_a), .B(b8_l4_w), .QH(QH[16:0]), .P(b8_l4_p));
    logic [59:0] b8_l5_w;
    MS_N16_q60_P32_tpm_twgen b8_l5_gen (.clk(clk), .A(b8_t10), .B(b8_t11), .QH(QH[16:0]), .P(b8_l5_w));
    logic [59:0] b8_l5_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l5_a_i (.clk(clk), .din(b7_g0_o[5]), .dout(b8_l5_a));
    logic [59:0] b8_l5_p;
    MS_N16_q60_P32_tpm_twmul b8_l5_mul (.clk(clk), .A(b8_l5_a), .B(b8_l5_w), .QH(QH[16:0]), .P(b8_l5_p));
    logic [59:0] b8_l6_w;
    MS_N16_q60_P32_tpm_twgen b8_l6_gen (.clk(clk), .A(b8_t12), .B(b8_t13), .QH(QH[16:0]), .P(b8_l6_w));
    logic [59:0] b8_l6_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l6_a_i (.clk(clk), .din(b7_g0_o[6]), .dout(b8_l6_a));
    logic [59:0] b8_l6_p;
    MS_N16_q60_P32_tpm_twmul b8_l6_mul (.clk(clk), .A(b8_l6_a), .B(b8_l6_w), .QH(QH[16:0]), .P(b8_l6_p));
    logic [59:0] b8_l7_w;
    MS_N16_q60_P32_tpm_twgen b8_l7_gen (.clk(clk), .A(b8_t14), .B(b8_t15), .QH(QH[16:0]), .P(b8_l7_w));
    logic [59:0] b8_l7_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l7_a_i (.clk(clk), .din(b7_g0_o[7]), .dout(b8_l7_a));
    logic [59:0] b8_l7_p;
    MS_N16_q60_P32_tpm_twmul b8_l7_mul (.clk(clk), .A(b8_l7_a), .B(b8_l7_w), .QH(QH[16:0]), .P(b8_l7_p));
    logic [59:0] b8_l8_w;
    MS_N16_q60_P32_tpm_twgen b8_l8_gen (.clk(clk), .A(b8_t16), .B(b8_t17), .QH(QH[16:0]), .P(b8_l8_w));
    logic [59:0] b8_l8_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l8_a_i (.clk(clk), .din(b7_g0_o[8]), .dout(b8_l8_a));
    logic [59:0] b8_l8_p;
    MS_N16_q60_P32_tpm_twmul b8_l8_mul (.clk(clk), .A(b8_l8_a), .B(b8_l8_w), .QH(QH[16:0]), .P(b8_l8_p));
    logic [59:0] b8_l9_w;
    MS_N16_q60_P32_tpm_twgen b8_l9_gen (.clk(clk), .A(b8_t18), .B(b8_t19), .QH(QH[16:0]), .P(b8_l9_w));
    logic [59:0] b8_l9_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l9_a_i (.clk(clk), .din(b7_g0_o[9]), .dout(b8_l9_a));
    logic [59:0] b8_l9_p;
    MS_N16_q60_P32_tpm_twmul b8_l9_mul (.clk(clk), .A(b8_l9_a), .B(b8_l9_w), .QH(QH[16:0]), .P(b8_l9_p));
    logic [59:0] b8_l10_w;
    MS_N16_q60_P32_tpm_twgen b8_l10_gen (.clk(clk), .A(b8_t20), .B(b8_t21), .QH(QH[16:0]), .P(b8_l10_w));
    logic [59:0] b8_l10_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l10_a_i (.clk(clk), .din(b7_g0_o[10]), .dout(b8_l10_a));
    logic [59:0] b8_l10_p;
    MS_N16_q60_P32_tpm_twmul b8_l10_mul (.clk(clk), .A(b8_l10_a), .B(b8_l10_w), .QH(QH[16:0]), .P(b8_l10_p));
    logic [59:0] b8_l11_w;
    MS_N16_q60_P32_tpm_twgen b8_l11_gen (.clk(clk), .A(b8_t22), .B(b8_t23), .QH(QH[16:0]), .P(b8_l11_w));
    logic [59:0] b8_l11_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l11_a_i (.clk(clk), .din(b7_g0_o[11]), .dout(b8_l11_a));
    logic [59:0] b8_l11_p;
    MS_N16_q60_P32_tpm_twmul b8_l11_mul (.clk(clk), .A(b8_l11_a), .B(b8_l11_w), .QH(QH[16:0]), .P(b8_l11_p));
    logic [59:0] b8_l12_w;
    MS_N16_q60_P32_tpm_twgen b8_l12_gen (.clk(clk), .A(b8_t24), .B(b8_t25), .QH(QH[16:0]), .P(b8_l12_w));
    logic [59:0] b8_l12_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l12_a_i (.clk(clk), .din(b7_g0_o[12]), .dout(b8_l12_a));
    logic [59:0] b8_l12_p;
    MS_N16_q60_P32_tpm_twmul b8_l12_mul (.clk(clk), .A(b8_l12_a), .B(b8_l12_w), .QH(QH[16:0]), .P(b8_l12_p));
    logic [59:0] b8_l13_w;
    MS_N16_q60_P32_tpm_twgen b8_l13_gen (.clk(clk), .A(b8_t26), .B(b8_t27), .QH(QH[16:0]), .P(b8_l13_w));
    logic [59:0] b8_l13_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l13_a_i (.clk(clk), .din(b7_g0_o[13]), .dout(b8_l13_a));
    logic [59:0] b8_l13_p;
    MS_N16_q60_P32_tpm_twmul b8_l13_mul (.clk(clk), .A(b8_l13_a), .B(b8_l13_w), .QH(QH[16:0]), .P(b8_l13_p));
    logic [59:0] b8_l14_w;
    MS_N16_q60_P32_tpm_twgen b8_l14_gen (.clk(clk), .A(b8_t28), .B(b8_t29), .QH(QH[16:0]), .P(b8_l14_w));
    logic [59:0] b8_l14_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l14_a_i (.clk(clk), .din(b7_g0_o[14]), .dout(b8_l14_a));
    logic [59:0] b8_l14_p;
    MS_N16_q60_P32_tpm_twmul b8_l14_mul (.clk(clk), .A(b8_l14_a), .B(b8_l14_w), .QH(QH[16:0]), .P(b8_l14_p));
    logic [59:0] b8_l15_w;
    MS_N16_q60_P32_tpm_twgen b8_l15_gen (.clk(clk), .A(b8_t30), .B(b8_t31), .QH(QH[16:0]), .P(b8_l15_w));
    logic [59:0] b8_l15_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l15_a_i (.clk(clk), .din(b7_g0_o[15]), .dout(b8_l15_a));
    logic [59:0] b8_l15_p;
    MS_N16_q60_P32_tpm_twmul b8_l15_mul (.clk(clk), .A(b8_l15_a), .B(b8_l15_w), .QH(QH[16:0]), .P(b8_l15_p));
    logic [59:0] b8_l16_w;
    MS_N16_q60_P32_tpm_twgen b8_l16_gen (.clk(clk), .A(b8_t32), .B(b8_t33), .QH(QH[16:0]), .P(b8_l16_w));
    logic [59:0] b8_l16_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l16_a_i (.clk(clk), .din(b7_g0_o[16]), .dout(b8_l16_a));
    logic [59:0] b8_l16_p;
    MS_N16_q60_P32_tpm_twmul b8_l16_mul (.clk(clk), .A(b8_l16_a), .B(b8_l16_w), .QH(QH[16:0]), .P(b8_l16_p));
    logic [59:0] b8_l17_w;
    MS_N16_q60_P32_tpm_twgen b8_l17_gen (.clk(clk), .A(b8_t34), .B(b8_t35), .QH(QH[16:0]), .P(b8_l17_w));
    logic [59:0] b8_l17_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l17_a_i (.clk(clk), .din(b7_g0_o[17]), .dout(b8_l17_a));
    logic [59:0] b8_l17_p;
    MS_N16_q60_P32_tpm_twmul b8_l17_mul (.clk(clk), .A(b8_l17_a), .B(b8_l17_w), .QH(QH[16:0]), .P(b8_l17_p));
    logic [59:0] b8_l18_w;
    MS_N16_q60_P32_tpm_twgen b8_l18_gen (.clk(clk), .A(b8_t36), .B(b8_t37), .QH(QH[16:0]), .P(b8_l18_w));
    logic [59:0] b8_l18_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l18_a_i (.clk(clk), .din(b7_g0_o[18]), .dout(b8_l18_a));
    logic [59:0] b8_l18_p;
    MS_N16_q60_P32_tpm_twmul b8_l18_mul (.clk(clk), .A(b8_l18_a), .B(b8_l18_w), .QH(QH[16:0]), .P(b8_l18_p));
    logic [59:0] b8_l19_w;
    MS_N16_q60_P32_tpm_twgen b8_l19_gen (.clk(clk), .A(b8_t38), .B(b8_t39), .QH(QH[16:0]), .P(b8_l19_w));
    logic [59:0] b8_l19_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l19_a_i (.clk(clk), .din(b7_g0_o[19]), .dout(b8_l19_a));
    logic [59:0] b8_l19_p;
    MS_N16_q60_P32_tpm_twmul b8_l19_mul (.clk(clk), .A(b8_l19_a), .B(b8_l19_w), .QH(QH[16:0]), .P(b8_l19_p));
    logic [59:0] b8_l20_w;
    MS_N16_q60_P32_tpm_twgen b8_l20_gen (.clk(clk), .A(b8_t40), .B(b8_t41), .QH(QH[16:0]), .P(b8_l20_w));
    logic [59:0] b8_l20_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l20_a_i (.clk(clk), .din(b7_g0_o[20]), .dout(b8_l20_a));
    logic [59:0] b8_l20_p;
    MS_N16_q60_P32_tpm_twmul b8_l20_mul (.clk(clk), .A(b8_l20_a), .B(b8_l20_w), .QH(QH[16:0]), .P(b8_l20_p));
    logic [59:0] b8_l21_w;
    MS_N16_q60_P32_tpm_twgen b8_l21_gen (.clk(clk), .A(b8_t42), .B(b8_t43), .QH(QH[16:0]), .P(b8_l21_w));
    logic [59:0] b8_l21_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l21_a_i (.clk(clk), .din(b7_g0_o[21]), .dout(b8_l21_a));
    logic [59:0] b8_l21_p;
    MS_N16_q60_P32_tpm_twmul b8_l21_mul (.clk(clk), .A(b8_l21_a), .B(b8_l21_w), .QH(QH[16:0]), .P(b8_l21_p));
    logic [59:0] b8_l22_w;
    MS_N16_q60_P32_tpm_twgen b8_l22_gen (.clk(clk), .A(b8_t44), .B(b8_t45), .QH(QH[16:0]), .P(b8_l22_w));
    logic [59:0] b8_l22_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l22_a_i (.clk(clk), .din(b7_g0_o[22]), .dout(b8_l22_a));
    logic [59:0] b8_l22_p;
    MS_N16_q60_P32_tpm_twmul b8_l22_mul (.clk(clk), .A(b8_l22_a), .B(b8_l22_w), .QH(QH[16:0]), .P(b8_l22_p));
    logic [59:0] b8_l23_w;
    MS_N16_q60_P32_tpm_twgen b8_l23_gen (.clk(clk), .A(b8_t46), .B(b8_t47), .QH(QH[16:0]), .P(b8_l23_w));
    logic [59:0] b8_l23_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l23_a_i (.clk(clk), .din(b7_g0_o[23]), .dout(b8_l23_a));
    logic [59:0] b8_l23_p;
    MS_N16_q60_P32_tpm_twmul b8_l23_mul (.clk(clk), .A(b8_l23_a), .B(b8_l23_w), .QH(QH[16:0]), .P(b8_l23_p));
    logic [59:0] b8_l24_w;
    MS_N16_q60_P32_tpm_twgen b8_l24_gen (.clk(clk), .A(b8_t48), .B(b8_t49), .QH(QH[16:0]), .P(b8_l24_w));
    logic [59:0] b8_l24_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l24_a_i (.clk(clk), .din(b7_g0_o[24]), .dout(b8_l24_a));
    logic [59:0] b8_l24_p;
    MS_N16_q60_P32_tpm_twmul b8_l24_mul (.clk(clk), .A(b8_l24_a), .B(b8_l24_w), .QH(QH[16:0]), .P(b8_l24_p));
    logic [59:0] b8_l25_w;
    MS_N16_q60_P32_tpm_twgen b8_l25_gen (.clk(clk), .A(b8_t50), .B(b8_t51), .QH(QH[16:0]), .P(b8_l25_w));
    logic [59:0] b8_l25_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l25_a_i (.clk(clk), .din(b7_g0_o[25]), .dout(b8_l25_a));
    logic [59:0] b8_l25_p;
    MS_N16_q60_P32_tpm_twmul b8_l25_mul (.clk(clk), .A(b8_l25_a), .B(b8_l25_w), .QH(QH[16:0]), .P(b8_l25_p));
    logic [59:0] b8_l26_w;
    MS_N16_q60_P32_tpm_twgen b8_l26_gen (.clk(clk), .A(b8_t52), .B(b8_t53), .QH(QH[16:0]), .P(b8_l26_w));
    logic [59:0] b8_l26_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l26_a_i (.clk(clk), .din(b7_g0_o[26]), .dout(b8_l26_a));
    logic [59:0] b8_l26_p;
    MS_N16_q60_P32_tpm_twmul b8_l26_mul (.clk(clk), .A(b8_l26_a), .B(b8_l26_w), .QH(QH[16:0]), .P(b8_l26_p));
    logic [59:0] b8_l27_w;
    MS_N16_q60_P32_tpm_twgen b8_l27_gen (.clk(clk), .A(b8_t54), .B(b8_t55), .QH(QH[16:0]), .P(b8_l27_w));
    logic [59:0] b8_l27_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l27_a_i (.clk(clk), .din(b7_g0_o[27]), .dout(b8_l27_a));
    logic [59:0] b8_l27_p;
    MS_N16_q60_P32_tpm_twmul b8_l27_mul (.clk(clk), .A(b8_l27_a), .B(b8_l27_w), .QH(QH[16:0]), .P(b8_l27_p));
    logic [59:0] b8_l28_w;
    MS_N16_q60_P32_tpm_twgen b8_l28_gen (.clk(clk), .A(b8_t56), .B(b8_t57), .QH(QH[16:0]), .P(b8_l28_w));
    logic [59:0] b8_l28_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l28_a_i (.clk(clk), .din(b7_g0_o[28]), .dout(b8_l28_a));
    logic [59:0] b8_l28_p;
    MS_N16_q60_P32_tpm_twmul b8_l28_mul (.clk(clk), .A(b8_l28_a), .B(b8_l28_w), .QH(QH[16:0]), .P(b8_l28_p));
    logic [59:0] b8_l29_w;
    MS_N16_q60_P32_tpm_twgen b8_l29_gen (.clk(clk), .A(b8_t58), .B(b8_t59), .QH(QH[16:0]), .P(b8_l29_w));
    logic [59:0] b8_l29_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l29_a_i (.clk(clk), .din(b7_g0_o[29]), .dout(b8_l29_a));
    logic [59:0] b8_l29_p;
    MS_N16_q60_P32_tpm_twmul b8_l29_mul (.clk(clk), .A(b8_l29_a), .B(b8_l29_w), .QH(QH[16:0]), .P(b8_l29_p));
    logic [59:0] b8_l30_w;
    MS_N16_q60_P32_tpm_twgen b8_l30_gen (.clk(clk), .A(b8_t60), .B(b8_t61), .QH(QH[16:0]), .P(b8_l30_w));
    logic [59:0] b8_l30_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l30_a_i (.clk(clk), .din(b7_g0_o[30]), .dout(b8_l30_a));
    logic [59:0] b8_l30_p;
    MS_N16_q60_P32_tpm_twmul b8_l30_mul (.clk(clk), .A(b8_l30_a), .B(b8_l30_w), .QH(QH[16:0]), .P(b8_l30_p));
    logic [59:0] b8_l31_w;
    MS_N16_q60_P32_tpm_twgen b8_l31_gen (.clk(clk), .A(b8_t62), .B(b8_t63), .QH(QH[16:0]), .P(b8_l31_w));
    logic [59:0] b8_l31_a;
    MS_N16_q60_P32_tpm_dly_c #(.W(60), .D(14)) b8_l31_a_i (.clk(clk), .din(b7_g0_o[31]), .dout(b8_l31_a));
    logic [59:0] b8_l31_p;
    MS_N16_q60_P32_tpm_twmul b8_l31_mul (.clk(clk), .A(b8_l31_a), .B(b8_l31_w), .QH(QH[16:0]), .P(b8_l31_p));
    logic [25:0] b8_v_sr;
    always_ff @(posedge clk) b8_v_sr <= rst ? '0 : {b8_v_sr[24:0], b7_g0_v};
    logic b8_v; assign b8_v = b8_v_sr[25];
    logic [0:0] b8_tag;
    MS_N16_q60_P32_tpm_dly_c #(.W(1), .D(26)) b8_tag_i (.clk(clk), .din(b7_tag), .dout(b8_tag));
    // block 9: pass 3, 1 x MS_N16_q60_P32_tpm_p3 (32-point), latency 78
    logic [59:0] b9_c0_y0, b9_c0_y1, b9_c0_y2, b9_c0_y3, b9_c0_y4, b9_c0_y5, b9_c0_y6, b9_c0_y7, b9_c0_y8, b9_c0_y9, b9_c0_y10, b9_c0_y11, b9_c0_y12, b9_c0_y13, b9_c0_y14, b9_c0_y15, b9_c0_y16, b9_c0_y17, b9_c0_y18, b9_c0_y19, b9_c0_y20, b9_c0_y21, b9_c0_y22, b9_c0_y23, b9_c0_y24, b9_c0_y25, b9_c0_y26, b9_c0_y27, b9_c0_y28, b9_c0_y29, b9_c0_y30, b9_c0_y31;
    logic b9_c0_v; logic b9_c0_di;
    logic b9_c0_lr, b9_c0_lw; (* equivalent_register_removal = "no" *) logic [59:0] b9_c0_ld;
    always_ff @(posedge clk) begin b9_c0_lr <= ld_r; b9_c0_lw <= ld_v && ld_iq >= 14'd50 && ld_iq < 14'd144; b9_c0_ld <= ld_d[59:0]; end
    MS_N16_q60_P32_tpm_p3 b9_c0 (.clk(clk), .rst(rst), .in_valid(b8_v), .out_valid(b9_c0_v), .DIR(b8_tag[0]), .tw_rst(b9_c0_lr), .tw_wen(b9_c0_lw), .tw_wdata(b9_c0_ld), .QH(QH[16:0]), .QHALF(QHALF[59:0]), .x_in_0(b8_l0_p), .x_in_1(b8_l1_p), .x_in_2(b8_l2_p), .x_in_3(b8_l3_p), .x_in_4(b8_l4_p), .x_in_5(b8_l5_p), .x_in_6(b8_l6_p), .x_in_7(b8_l7_p), .x_in_8(b8_l8_p), .x_in_9(b8_l9_p), .x_in_10(b8_l10_p), .x_in_11(b8_l11_p), .x_in_12(b8_l12_p), .x_in_13(b8_l13_p), .x_in_14(b8_l14_p), .x_in_15(b8_l15_p), .x_in_16(b8_l16_p), .x_in_17(b8_l17_p), .x_in_18(b8_l18_p), .x_in_19(b8_l19_p), .x_in_20(b8_l20_p), .x_in_21(b8_l21_p), .x_in_22(b8_l22_p), .x_in_23(b8_l23_p), .x_in_24(b8_l24_p), .x_in_25(b8_l25_p), .x_in_26(b8_l26_p), .x_in_27(b8_l27_p), .x_in_28(b8_l28_p), .x_in_29(b8_l29_p), .x_in_30(b8_l30_p), .x_in_31(b8_l31_p), .y_out_0(b9_c0_y0), .y_out_1(b9_c0_y1), .y_out_2(b9_c0_y2), .y_out_3(b9_c0_y3), .y_out_4(b9_c0_y4), .y_out_5(b9_c0_y5), .y_out_6(b9_c0_y6), .y_out_7(b9_c0_y7), .y_out_8(b9_c0_y8), .y_out_9(b9_c0_y9), .y_out_10(b9_c0_y10), .y_out_11(b9_c0_y11), .y_out_12(b9_c0_y12), .y_out_13(b9_c0_y13), .y_out_14(b9_c0_y14), .y_out_15(b9_c0_y15), .y_out_16(b9_c0_y16), .y_out_17(b9_c0_y17), .y_out_18(b9_c0_y18), .y_out_19(b9_c0_y19), .y_out_20(b9_c0_y20), .y_out_21(b9_c0_y21), .y_out_22(b9_c0_y22), .y_out_23(b9_c0_y23), .y_out_24(b9_c0_y24), .y_out_25(b9_c0_y25), .y_out_26(b9_c0_y26), .y_out_27(b9_c0_y27), .y_out_28(b9_c0_y28), .y_out_29(b9_c0_y29), .y_out_30(b9_c0_y30), .y_out_31(b9_c0_y31));
    logic [0:0] b9_tag;
    MS_N16_q60_P32_tpm_dly_c #(.W(1), .D(78)) b9_tag_i (.clk(clk), .din(b8_tag), .dout(b9_tag));
    assign out_valid = b9_c0_v;
    assign dir_out = b9_tag[0];
    assign y_out_0 = b9_c0_y0;
    assign y_out_1 = b9_c0_y1;
    assign y_out_2 = b9_c0_y2;
    assign y_out_3 = b9_c0_y3;
    assign y_out_4 = b9_c0_y4;
    assign y_out_5 = b9_c0_y5;
    assign y_out_6 = b9_c0_y6;
    assign y_out_7 = b9_c0_y7;
    assign y_out_8 = b9_c0_y8;
    assign y_out_9 = b9_c0_y9;
    assign y_out_10 = b9_c0_y10;
    assign y_out_11 = b9_c0_y11;
    assign y_out_12 = b9_c0_y12;
    assign y_out_13 = b9_c0_y13;
    assign y_out_14 = b9_c0_y14;
    assign y_out_15 = b9_c0_y15;
    assign y_out_16 = b9_c0_y16;
    assign y_out_17 = b9_c0_y17;
    assign y_out_18 = b9_c0_y18;
    assign y_out_19 = b9_c0_y19;
    assign y_out_20 = b9_c0_y20;
    assign y_out_21 = b9_c0_y21;
    assign y_out_22 = b9_c0_y22;
    assign y_out_23 = b9_c0_y23;
    assign y_out_24 = b9_c0_y24;
    assign y_out_25 = b9_c0_y25;
    assign y_out_26 = b9_c0_y26;
    assign y_out_27 = b9_c0_y27;
    assign y_out_28 = b9_c0_y28;
    assign y_out_29 = b9_c0_y29;
    assign y_out_30 = b9_c0_y30;
    assign y_out_31 = b9_c0_y31;
endmodule
