`timescale 1ns / 1ps
// MS_N16_q60_P32_tpm_p2_core: streaming NTT, n=16, 16 lanes, frame 1 cycles, run-time q, direction both, latency 51
module MS_N16_q60_P32_tpm_p2_core (
    input  logic clk,
    input  logic rst,
    input  logic DIR,
    input  logic [16:0] QH,
    input  logic [59:0] QHALF,
    input  logic tw_rst,
    input  logic tw_wen,
    input  logic [59:0] tw_wdata,
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
    output logic [59:0] y_out_15
    );
    (* max_fanout = 32 *) logic tw_rst_p, tw_wen_p; (* max_fanout = 32 *) logic [59:0] tw_wdata_p;
    always_ff @(posedge clk) begin tw_rst_p <= tw_rst; tw_wen_p <= tw_wen; tw_wdata_p <= tw_wdata; end
    (* max_fanout = 32 *) logic [3:0] tw_wi;
    always_ff @(posedge clk) tw_wi <= tw_rst_p ? '0 : (tw_wen_p ? tw_wi + 1'b1 : tw_wi);
    (* max_fanout = 32 *) logic [59:0] tw_wd_q;
    always_ff @(posedge clk) tw_wd_q <= tw_wdata_p;
    logic [0:0] mx_1;
    always_ff @(posedge clk) mx_1 <= DIR;
    // per-frame direction: input lead of 2 cycles
    logic [59:0] xl_0;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl0_dly (.clk(clk), .din(x_in_0), .dout(xl_0));
    logic [59:0] xl_1;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl1_dly (.clk(clk), .din(x_in_1), .dout(xl_1));
    logic [59:0] xl_2;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl2_dly (.clk(clk), .din(x_in_2), .dout(xl_2));
    logic [59:0] xl_3;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl3_dly (.clk(clk), .din(x_in_3), .dout(xl_3));
    logic [59:0] xl_4;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl4_dly (.clk(clk), .din(x_in_4), .dout(xl_4));
    logic [59:0] xl_5;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl5_dly (.clk(clk), .din(x_in_5), .dout(xl_5));
    logic [59:0] xl_6;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl6_dly (.clk(clk), .din(x_in_6), .dout(xl_6));
    logic [59:0] xl_7;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl7_dly (.clk(clk), .din(x_in_7), .dout(xl_7));
    logic [59:0] xl_8;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl8_dly (.clk(clk), .din(x_in_8), .dout(xl_8));
    logic [59:0] xl_9;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl9_dly (.clk(clk), .din(x_in_9), .dout(xl_9));
    logic [59:0] xl_10;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl10_dly (.clk(clk), .din(x_in_10), .dout(xl_10));
    logic [59:0] xl_11;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl11_dly (.clk(clk), .din(x_in_11), .dout(xl_11));
    logic [59:0] xl_12;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl12_dly (.clk(clk), .din(x_in_12), .dout(xl_12));
    logic [59:0] xl_13;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl13_dly (.clk(clk), .din(x_in_13), .dout(xl_13));
    logic [59:0] xl_14;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl14_dly (.clk(clk), .din(x_in_14), .dout(xl_14));
    logic [59:0] xl_15;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl15_dly (.clk(clk), .din(x_in_15), .dout(xl_15));
    (* max_fanout = 16 *) logic [16:0] QH_r;
    always_ff @(posedge clk) QH_r <= QH;
    (* max_fanout = 16 *) logic [59:0] QHALF_r;
    always_ff @(posedge clk) QHALF_r <= QHALF;
    // stage 0: 8 butterflies on lane pairs (bit 0), latency 3
    (* max_fanout = 16 *) logic [16:0] s0q_QH;
    always_ff @(posedge clk) s0q_QH <= QH_r;
    logic [59:0] s0_k0_xr; logic [59:0] s0_k0_yr;
    MS_N16_q60_P32_tpm_p2_core_s0_c0 s0_k0 (.clk(clk), .aIn(xl_0), .bIn(xl_1), .QH(s0q_QH), .aOut(s0_k0_xr), .bOut(s0_k0_yr));
    logic [59:0] s0_o0;
    (* max_fanout = 16 *) logic [59:0] s0q_QHALF;
    always_ff @(posedge clk) s0q_QHALF <= QHALF_r;
    logic [59:0] s0_o0_h_x, s0_o0_h;
    assign s0_o0_h_x = s0_k0_xr;
    (* max_fanout = 16 *) logic [0:0] mx_2;
    always_ff @(posedge clk) mx_2 <= mx_1;
    (* max_fanout = 16 *) logic [0:0] mx_3;
    always_ff @(posedge clk) mx_3 <= mx_2;
    (* max_fanout = 16 *) logic [0:0] mx_4;
    always_ff @(posedge clk) mx_4 <= mx_3;
    (* max_fanout = 16 *) logic [0:0] mx_5;
    always_ff @(posedge clk) mx_5 <= mx_4;
    always_ff @(posedge clk) s0_o0_h <= mx_5[0] ? (60'(s0_o0_h_x >> 1) + (s0_o0_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o0_h_x;
    assign s0_o0 = s0_o0_h;
    logic [59:0] s0_o1;
    logic [59:0] s0_o1_h_x, s0_o1_h;
    assign s0_o1_h_x = s0_k0_yr;
    always_ff @(posedge clk) s0_o1_h <= mx_5[0] ? (60'(s0_o1_h_x >> 1) + (s0_o1_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o1_h_x;
    assign s0_o1 = s0_o1_h;
    logic [59:0] s0_k1_xr; logic [59:0] s0_k1_yr;
    MS_N16_q60_P32_tpm_p2_core_s0_c0 s0_k1 (.clk(clk), .aIn(xl_2), .bIn(xl_3), .QH(s0q_QH), .aOut(s0_k1_xr), .bOut(s0_k1_yr));
    logic [59:0] s0_o2;
    logic [59:0] s0_o2_h_x, s0_o2_h;
    assign s0_o2_h_x = s0_k1_xr;
    always_ff @(posedge clk) s0_o2_h <= mx_5[0] ? (60'(s0_o2_h_x >> 1) + (s0_o2_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o2_h_x;
    assign s0_o2 = s0_o2_h;
    logic [59:0] s0_o3;
    logic [59:0] s0_o3_h_x, s0_o3_h;
    assign s0_o3_h_x = s0_k1_yr;
    always_ff @(posedge clk) s0_o3_h <= mx_5[0] ? (60'(s0_o3_h_x >> 1) + (s0_o3_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o3_h_x;
    assign s0_o3 = s0_o3_h;
    logic [59:0] s0_k2_xr; logic [59:0] s0_k2_yr;
    MS_N16_q60_P32_tpm_p2_core_s0_c0 s0_k2 (.clk(clk), .aIn(xl_4), .bIn(xl_5), .QH(s0q_QH), .aOut(s0_k2_xr), .bOut(s0_k2_yr));
    logic [59:0] s0_o4;
    logic [59:0] s0_o4_h_x, s0_o4_h;
    assign s0_o4_h_x = s0_k2_xr;
    always_ff @(posedge clk) s0_o4_h <= mx_5[0] ? (60'(s0_o4_h_x >> 1) + (s0_o4_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o4_h_x;
    assign s0_o4 = s0_o4_h;
    logic [59:0] s0_o5;
    logic [59:0] s0_o5_h_x, s0_o5_h;
    assign s0_o5_h_x = s0_k2_yr;
    always_ff @(posedge clk) s0_o5_h <= mx_5[0] ? (60'(s0_o5_h_x >> 1) + (s0_o5_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o5_h_x;
    assign s0_o5 = s0_o5_h;
    logic [59:0] s0_k3_xr; logic [59:0] s0_k3_yr;
    MS_N16_q60_P32_tpm_p2_core_s0_c0 s0_k3 (.clk(clk), .aIn(xl_6), .bIn(xl_7), .QH(s0q_QH), .aOut(s0_k3_xr), .bOut(s0_k3_yr));
    logic [59:0] s0_o6;
    logic [59:0] s0_o6_h_x, s0_o6_h;
    assign s0_o6_h_x = s0_k3_xr;
    always_ff @(posedge clk) s0_o6_h <= mx_5[0] ? (60'(s0_o6_h_x >> 1) + (s0_o6_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o6_h_x;
    assign s0_o6 = s0_o6_h;
    logic [59:0] s0_o7;
    logic [59:0] s0_o7_h_x, s0_o7_h;
    assign s0_o7_h_x = s0_k3_yr;
    always_ff @(posedge clk) s0_o7_h <= mx_5[0] ? (60'(s0_o7_h_x >> 1) + (s0_o7_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o7_h_x;
    assign s0_o7 = s0_o7_h;
    logic [59:0] s0_k4_xr; logic [59:0] s0_k4_yr;
    MS_N16_q60_P32_tpm_p2_core_s0_c0 s0_k4 (.clk(clk), .aIn(xl_8), .bIn(xl_9), .QH(s0q_QH), .aOut(s0_k4_xr), .bOut(s0_k4_yr));
    logic [59:0] s0_o8;
    logic [59:0] s0_o8_h_x, s0_o8_h;
    assign s0_o8_h_x = s0_k4_xr;
    always_ff @(posedge clk) s0_o8_h <= mx_5[0] ? (60'(s0_o8_h_x >> 1) + (s0_o8_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o8_h_x;
    assign s0_o8 = s0_o8_h;
    logic [59:0] s0_o9;
    logic [59:0] s0_o9_h_x, s0_o9_h;
    assign s0_o9_h_x = s0_k4_yr;
    always_ff @(posedge clk) s0_o9_h <= mx_5[0] ? (60'(s0_o9_h_x >> 1) + (s0_o9_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o9_h_x;
    assign s0_o9 = s0_o9_h;
    logic [59:0] s0_k5_xr; logic [59:0] s0_k5_yr;
    MS_N16_q60_P32_tpm_p2_core_s0_c0 s0_k5 (.clk(clk), .aIn(xl_10), .bIn(xl_11), .QH(s0q_QH), .aOut(s0_k5_xr), .bOut(s0_k5_yr));
    logic [59:0] s0_o10;
    logic [59:0] s0_o10_h_x, s0_o10_h;
    assign s0_o10_h_x = s0_k5_xr;
    always_ff @(posedge clk) s0_o10_h <= mx_5[0] ? (60'(s0_o10_h_x >> 1) + (s0_o10_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o10_h_x;
    assign s0_o10 = s0_o10_h;
    logic [59:0] s0_o11;
    logic [59:0] s0_o11_h_x, s0_o11_h;
    assign s0_o11_h_x = s0_k5_yr;
    always_ff @(posedge clk) s0_o11_h <= mx_5[0] ? (60'(s0_o11_h_x >> 1) + (s0_o11_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o11_h_x;
    assign s0_o11 = s0_o11_h;
    logic [59:0] s0_k6_xr; logic [59:0] s0_k6_yr;
    MS_N16_q60_P32_tpm_p2_core_s0_c0 s0_k6 (.clk(clk), .aIn(xl_12), .bIn(xl_13), .QH(s0q_QH), .aOut(s0_k6_xr), .bOut(s0_k6_yr));
    logic [59:0] s0_o12;
    logic [59:0] s0_o12_h_x, s0_o12_h;
    assign s0_o12_h_x = s0_k6_xr;
    always_ff @(posedge clk) s0_o12_h <= mx_5[0] ? (60'(s0_o12_h_x >> 1) + (s0_o12_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o12_h_x;
    assign s0_o12 = s0_o12_h;
    logic [59:0] s0_o13;
    logic [59:0] s0_o13_h_x, s0_o13_h;
    assign s0_o13_h_x = s0_k6_yr;
    always_ff @(posedge clk) s0_o13_h <= mx_5[0] ? (60'(s0_o13_h_x >> 1) + (s0_o13_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o13_h_x;
    assign s0_o13 = s0_o13_h;
    logic [59:0] s0_k7_xr; logic [59:0] s0_k7_yr;
    MS_N16_q60_P32_tpm_p2_core_s0_c0 s0_k7 (.clk(clk), .aIn(xl_14), .bIn(xl_15), .QH(s0q_QH), .aOut(s0_k7_xr), .bOut(s0_k7_yr));
    logic [59:0] s0_o14;
    logic [59:0] s0_o14_h_x, s0_o14_h;
    assign s0_o14_h_x = s0_k7_xr;
    always_ff @(posedge clk) s0_o14_h <= mx_5[0] ? (60'(s0_o14_h_x >> 1) + (s0_o14_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o14_h_x;
    assign s0_o14 = s0_o14_h;
    logic [59:0] s0_o15;
    logic [59:0] s0_o15_h_x, s0_o15_h;
    assign s0_o15_h_x = s0_k7_yr;
    always_ff @(posedge clk) s0_o15_h <= mx_5[0] ? (60'(s0_o15_h_x >> 1) + (s0_o15_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o15_h_x;
    assign s0_o15 = s0_o15_h;
    // stage 1: 8 butterflies on lane pairs (bit 1), latency 14
    (* max_fanout = 16 *) logic [16:0] s1q_QH;
    always_ff @(posedge clk) s1q_QH <= QH_r;
    logic [59:0] s1_k0_xr; logic [59:0] s1_k0_yr;
    MS_N16_q60_P32_tpm_p2_core_s1_c0 s1_k0 (.clk(clk), .aIn(s0_o0), .bIn(s0_o2), .QH(s1q_QH), .aOut(s1_k0_xr), .bOut(s1_k0_yr));
    logic [59:0] s1_o0;
    (* max_fanout = 16 *) logic [59:0] s1q_QHALF;
    always_ff @(posedge clk) s1q_QHALF <= QHALF_r;
    logic [59:0] s1_o0_h_x, s1_o0_h;
    assign s1_o0_h_x = s1_k0_xr;
    (* max_fanout = 16 *) logic [0:0] mx_6;
    always_ff @(posedge clk) mx_6 <= mx_5;
    (* max_fanout = 16 *) logic [0:0] mx_7;
    always_ff @(posedge clk) mx_7 <= mx_6;
    (* max_fanout = 16 *) logic [0:0] mx_8;
    always_ff @(posedge clk) mx_8 <= mx_7;
    (* max_fanout = 16 *) logic [0:0] mx_9;
    always_ff @(posedge clk) mx_9 <= mx_8;
    always_ff @(posedge clk) s1_o0_h <= mx_9[0] ? (60'(s1_o0_h_x >> 1) + (s1_o0_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o0_h_x;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(11)) s1_o0_bal (.clk(clk), .din(s1_o0_h), .dout(s1_o0));
    logic [59:0] s1_o2;
    logic [59:0] s1_o2_h_x, s1_o2_h;
    assign s1_o2_h_x = s1_k0_yr;
    always_ff @(posedge clk) s1_o2_h <= mx_9[0] ? (60'(s1_o2_h_x >> 1) + (s1_o2_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o2_h_x;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(11)) s1_o2_bal (.clk(clk), .din(s1_o2_h), .dout(s1_o2));
    logic [59:0] s1_t0_c0_w;
    logic s1_t0_c0_tab_hit_c, s1_t0_c0_tab_hit; logic [3:0] s1_t0_c0_tab_rel;
    assign s1_t0_c0_tab_rel = tw_wi - 4'd0;
    assign s1_t0_c0_tab_hit_c = tw_wen_p && (tw_wi >= 4'd0) && (tw_wi < 4'd2);
    logic [0:0] s1_t0_c0_tab_col_c, s1_t0_c0_tab_col; logic [0:0] s1_t0_c0_tab_wa_c, s1_t0_c0_tab_wa;
    assign s1_t0_c0_tab_col_c = '0; assign s1_t0_c0_tab_wa_c = s1_t0_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s1_t0_c0_tab_hit <= s1_t0_c0_tab_hit_c; s1_t0_c0_tab_col <= s1_t0_c0_tab_col_c; s1_t0_c0_tab_wa <= s1_t0_c0_tab_wa_c; end
    logic s1_t0_c0_tab_hit_q; logic [0:0] s1_t0_c0_tab_col_q; logic [0:0] s1_t0_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s1_t0_c0_tab_wd_q;
    always_ff @(posedge clk) begin s1_t0_c0_tab_hit_q <= s1_t0_c0_tab_hit; s1_t0_c0_tab_col_q <= s1_t0_c0_tab_col; s1_t0_c0_tab_wa_q <= s1_t0_c0_tab_wa; s1_t0_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p2_core_tab0 s1_t0_c0_tab (.clk(clk), .addr({mx_4}), .we(s1_t0_c0_tab_hit_q), .wa(s1_t0_c0_tab_wa_q), .wcol(s1_t0_c0_tab_col_q), .wd(s1_t0_c0_tab_wd_q), .q0(s1_t0_c0_w));
    logic [59:0] s1_k1_xr; logic [59:0] s1_k1_yr;
    MS_N16_q60_P32_tpm_p2_core_s1_bu s1_k1 (.clk(clk), .aIn(s0_o1), .bIn(s0_o3), .W(s1_t0_c0_w), .QH(s1q_QH), .aOut(s1_k1_xr), .bOut(s1_k1_yr));
    logic [59:0] s1_o1;
    logic [59:0] s1_o1_h_x, s1_o1_h;
    assign s1_o1_h_x = s1_k1_xr;
    (* max_fanout = 16 *) logic [0:0] mx_10;
    always_ff @(posedge clk) mx_10 <= mx_9;
    (* max_fanout = 16 *) logic [0:0] mx_11;
    always_ff @(posedge clk) mx_11 <= mx_10;
    (* max_fanout = 16 *) logic [0:0] mx_12;
    always_ff @(posedge clk) mx_12 <= mx_11;
    (* max_fanout = 16 *) logic [0:0] mx_13;
    always_ff @(posedge clk) mx_13 <= mx_12;
    (* max_fanout = 16 *) logic [0:0] mx_14;
    always_ff @(posedge clk) mx_14 <= mx_13;
    (* max_fanout = 16 *) logic [0:0] mx_15;
    always_ff @(posedge clk) mx_15 <= mx_14;
    (* max_fanout = 16 *) logic [0:0] mx_16;
    always_ff @(posedge clk) mx_16 <= mx_15;
    (* max_fanout = 16 *) logic [0:0] mx_17;
    always_ff @(posedge clk) mx_17 <= mx_16;
    (* max_fanout = 16 *) logic [0:0] mx_18;
    always_ff @(posedge clk) mx_18 <= mx_17;
    (* max_fanout = 16 *) logic [0:0] mx_19;
    always_ff @(posedge clk) mx_19 <= mx_18;
    (* max_fanout = 16 *) logic [0:0] mx_20;
    always_ff @(posedge clk) mx_20 <= mx_19;
    always_ff @(posedge clk) s1_o1_h <= mx_20[0] ? (60'(s1_o1_h_x >> 1) + (s1_o1_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o1_h_x;
    assign s1_o1 = s1_o1_h;
    logic [59:0] s1_o3;
    logic [59:0] s1_o3_h_x, s1_o3_h;
    assign s1_o3_h_x = s1_k1_yr;
    always_ff @(posedge clk) s1_o3_h <= mx_20[0] ? (60'(s1_o3_h_x >> 1) + (s1_o3_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o3_h_x;
    assign s1_o3 = s1_o3_h;
    logic [59:0] s1_k2_xr; logic [59:0] s1_k2_yr;
    MS_N16_q60_P32_tpm_p2_core_s1_c0 s1_k2 (.clk(clk), .aIn(s0_o4), .bIn(s0_o6), .QH(s1q_QH), .aOut(s1_k2_xr), .bOut(s1_k2_yr));
    logic [59:0] s1_o4;
    logic [59:0] s1_o4_h_x, s1_o4_h;
    assign s1_o4_h_x = s1_k2_xr;
    always_ff @(posedge clk) s1_o4_h <= mx_9[0] ? (60'(s1_o4_h_x >> 1) + (s1_o4_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o4_h_x;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(11)) s1_o4_bal (.clk(clk), .din(s1_o4_h), .dout(s1_o4));
    logic [59:0] s1_o6;
    logic [59:0] s1_o6_h_x, s1_o6_h;
    assign s1_o6_h_x = s1_k2_yr;
    always_ff @(posedge clk) s1_o6_h <= mx_9[0] ? (60'(s1_o6_h_x >> 1) + (s1_o6_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o6_h_x;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(11)) s1_o6_bal (.clk(clk), .din(s1_o6_h), .dout(s1_o6));
    logic [59:0] s1_k3_xr; logic [59:0] s1_k3_yr;
    MS_N16_q60_P32_tpm_p2_core_s1_bu s1_k3 (.clk(clk), .aIn(s0_o5), .bIn(s0_o7), .W(s1_t0_c0_w), .QH(s1q_QH), .aOut(s1_k3_xr), .bOut(s1_k3_yr));
    logic [59:0] s1_o5;
    logic [59:0] s1_o5_h_x, s1_o5_h;
    assign s1_o5_h_x = s1_k3_xr;
    always_ff @(posedge clk) s1_o5_h <= mx_20[0] ? (60'(s1_o5_h_x >> 1) + (s1_o5_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o5_h_x;
    assign s1_o5 = s1_o5_h;
    logic [59:0] s1_o7;
    logic [59:0] s1_o7_h_x, s1_o7_h;
    assign s1_o7_h_x = s1_k3_yr;
    always_ff @(posedge clk) s1_o7_h <= mx_20[0] ? (60'(s1_o7_h_x >> 1) + (s1_o7_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o7_h_x;
    assign s1_o7 = s1_o7_h;
    logic [59:0] s1_k4_xr; logic [59:0] s1_k4_yr;
    MS_N16_q60_P32_tpm_p2_core_s1_c0 s1_k4 (.clk(clk), .aIn(s0_o8), .bIn(s0_o10), .QH(s1q_QH), .aOut(s1_k4_xr), .bOut(s1_k4_yr));
    logic [59:0] s1_o8;
    logic [59:0] s1_o8_h_x, s1_o8_h;
    assign s1_o8_h_x = s1_k4_xr;
    always_ff @(posedge clk) s1_o8_h <= mx_9[0] ? (60'(s1_o8_h_x >> 1) + (s1_o8_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o8_h_x;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(11)) s1_o8_bal (.clk(clk), .din(s1_o8_h), .dout(s1_o8));
    logic [59:0] s1_o10;
    logic [59:0] s1_o10_h_x, s1_o10_h;
    assign s1_o10_h_x = s1_k4_yr;
    always_ff @(posedge clk) s1_o10_h <= mx_9[0] ? (60'(s1_o10_h_x >> 1) + (s1_o10_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o10_h_x;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(11)) s1_o10_bal (.clk(clk), .din(s1_o10_h), .dout(s1_o10));
    logic [59:0] s1_k5_xr; logic [59:0] s1_k5_yr;
    MS_N16_q60_P32_tpm_p2_core_s1_bu s1_k5 (.clk(clk), .aIn(s0_o9), .bIn(s0_o11), .W(s1_t0_c0_w), .QH(s1q_QH), .aOut(s1_k5_xr), .bOut(s1_k5_yr));
    logic [59:0] s1_o9;
    logic [59:0] s1_o9_h_x, s1_o9_h;
    assign s1_o9_h_x = s1_k5_xr;
    always_ff @(posedge clk) s1_o9_h <= mx_20[0] ? (60'(s1_o9_h_x >> 1) + (s1_o9_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o9_h_x;
    assign s1_o9 = s1_o9_h;
    logic [59:0] s1_o11;
    logic [59:0] s1_o11_h_x, s1_o11_h;
    assign s1_o11_h_x = s1_k5_yr;
    always_ff @(posedge clk) s1_o11_h <= mx_20[0] ? (60'(s1_o11_h_x >> 1) + (s1_o11_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o11_h_x;
    assign s1_o11 = s1_o11_h;
    logic [59:0] s1_k6_xr; logic [59:0] s1_k6_yr;
    MS_N16_q60_P32_tpm_p2_core_s1_c0 s1_k6 (.clk(clk), .aIn(s0_o12), .bIn(s0_o14), .QH(s1q_QH), .aOut(s1_k6_xr), .bOut(s1_k6_yr));
    logic [59:0] s1_o12;
    logic [59:0] s1_o12_h_x, s1_o12_h;
    assign s1_o12_h_x = s1_k6_xr;
    always_ff @(posedge clk) s1_o12_h <= mx_9[0] ? (60'(s1_o12_h_x >> 1) + (s1_o12_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o12_h_x;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(11)) s1_o12_bal (.clk(clk), .din(s1_o12_h), .dout(s1_o12));
    logic [59:0] s1_o14;
    logic [59:0] s1_o14_h_x, s1_o14_h;
    assign s1_o14_h_x = s1_k6_yr;
    always_ff @(posedge clk) s1_o14_h <= mx_9[0] ? (60'(s1_o14_h_x >> 1) + (s1_o14_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o14_h_x;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(11)) s1_o14_bal (.clk(clk), .din(s1_o14_h), .dout(s1_o14));
    logic [59:0] s1_k7_xr; logic [59:0] s1_k7_yr;
    MS_N16_q60_P32_tpm_p2_core_s1_bu s1_k7 (.clk(clk), .aIn(s0_o13), .bIn(s0_o15), .W(s1_t0_c0_w), .QH(s1q_QH), .aOut(s1_k7_xr), .bOut(s1_k7_yr));
    logic [59:0] s1_o13;
    logic [59:0] s1_o13_h_x, s1_o13_h;
    assign s1_o13_h_x = s1_k7_xr;
    always_ff @(posedge clk) s1_o13_h <= mx_20[0] ? (60'(s1_o13_h_x >> 1) + (s1_o13_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o13_h_x;
    assign s1_o13 = s1_o13_h;
    logic [59:0] s1_o15;
    logic [59:0] s1_o15_h_x, s1_o15_h;
    assign s1_o15_h_x = s1_k7_yr;
    always_ff @(posedge clk) s1_o15_h <= mx_20[0] ? (60'(s1_o15_h_x >> 1) + (s1_o15_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o15_h_x;
    assign s1_o15 = s1_o15_h;
    // stage 2: 8 butterflies on lane pairs (bit 2), latency 14
    (* max_fanout = 16 *) logic [16:0] s2q_QH;
    always_ff @(posedge clk) s2q_QH <= QH_r;
    logic [59:0] s2_k0_xr; logic [59:0] s2_k0_yr;
    MS_N16_q60_P32_tpm_p2_core_s2_c0 s2_k0 (.clk(clk), .aIn(s1_o0), .bIn(s1_o4), .QH(s2q_QH), .aOut(s2_k0_xr), .bOut(s2_k0_yr));
    logic [59:0] s2_o0;
    (* max_fanout = 16 *) logic [59:0] s2q_QHALF;
    always_ff @(posedge clk) s2q_QHALF <= QHALF_r;
    logic [59:0] s2_o0_h_x, s2_o0_h;
    assign s2_o0_h_x = s2_k0_xr;
    (* max_fanout = 16 *) logic [0:0] mx_21;
    always_ff @(posedge clk) mx_21 <= mx_20;
    (* max_fanout = 16 *) logic [0:0] mx_22;
    always_ff @(posedge clk) mx_22 <= mx_21;
    (* max_fanout = 16 *) logic [0:0] mx_23;
    always_ff @(posedge clk) mx_23 <= mx_22;
    (* max_fanout = 16 *) logic [0:0] mx_24;
    always_ff @(posedge clk) mx_24 <= mx_23;
    always_ff @(posedge clk) s2_o0_h <= mx_24[0] ? (60'(s2_o0_h_x >> 1) + (s2_o0_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o0_h_x;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(11)) s2_o0_bal (.clk(clk), .din(s2_o0_h), .dout(s2_o0));
    logic [59:0] s2_o4;
    logic [59:0] s2_o4_h_x, s2_o4_h;
    assign s2_o4_h_x = s2_k0_yr;
    always_ff @(posedge clk) s2_o4_h <= mx_24[0] ? (60'(s2_o4_h_x >> 1) + (s2_o4_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o4_h_x;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(11)) s2_o4_bal (.clk(clk), .din(s2_o4_h), .dout(s2_o4));
    logic [59:0] s2_t1_c0_w;
    logic s2_t1_c0_tab_hit_c, s2_t1_c0_tab_hit; logic [3:0] s2_t1_c0_tab_rel;
    assign s2_t1_c0_tab_rel = tw_wi - 4'd2;
    assign s2_t1_c0_tab_hit_c = tw_wen_p && (tw_wi >= 4'd2) && (tw_wi < 4'd4);
    logic [0:0] s2_t1_c0_tab_col_c, s2_t1_c0_tab_col; logic [0:0] s2_t1_c0_tab_wa_c, s2_t1_c0_tab_wa;
    assign s2_t1_c0_tab_col_c = '0; assign s2_t1_c0_tab_wa_c = s2_t1_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s2_t1_c0_tab_hit <= s2_t1_c0_tab_hit_c; s2_t1_c0_tab_col <= s2_t1_c0_tab_col_c; s2_t1_c0_tab_wa <= s2_t1_c0_tab_wa_c; end
    logic s2_t1_c0_tab_hit_q; logic [0:0] s2_t1_c0_tab_col_q; logic [0:0] s2_t1_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s2_t1_c0_tab_wd_q;
    always_ff @(posedge clk) begin s2_t1_c0_tab_hit_q <= s2_t1_c0_tab_hit; s2_t1_c0_tab_col_q <= s2_t1_c0_tab_col; s2_t1_c0_tab_wa_q <= s2_t1_c0_tab_wa; s2_t1_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p2_core_tab1 s2_t1_c0_tab (.clk(clk), .addr({mx_19}), .we(s2_t1_c0_tab_hit_q), .wa(s2_t1_c0_tab_wa_q), .wcol(s2_t1_c0_tab_col_q), .wd(s2_t1_c0_tab_wd_q), .q0(s2_t1_c0_w));
    logic [59:0] s2_k1_xr; logic [59:0] s2_k1_yr;
    MS_N16_q60_P32_tpm_p2_core_s2_bu s2_k1 (.clk(clk), .aIn(s1_o1), .bIn(s1_o5), .W(s2_t1_c0_w), .QH(s2q_QH), .aOut(s2_k1_xr), .bOut(s2_k1_yr));
    logic [59:0] s2_o1;
    logic [59:0] s2_o1_h_x, s2_o1_h;
    assign s2_o1_h_x = s2_k1_xr;
    (* max_fanout = 16 *) logic [0:0] mx_25;
    always_ff @(posedge clk) mx_25 <= mx_24;
    (* max_fanout = 16 *) logic [0:0] mx_26;
    always_ff @(posedge clk) mx_26 <= mx_25;
    (* max_fanout = 16 *) logic [0:0] mx_27;
    always_ff @(posedge clk) mx_27 <= mx_26;
    (* max_fanout = 16 *) logic [0:0] mx_28;
    always_ff @(posedge clk) mx_28 <= mx_27;
    (* max_fanout = 16 *) logic [0:0] mx_29;
    always_ff @(posedge clk) mx_29 <= mx_28;
    (* max_fanout = 16 *) logic [0:0] mx_30;
    always_ff @(posedge clk) mx_30 <= mx_29;
    (* max_fanout = 16 *) logic [0:0] mx_31;
    always_ff @(posedge clk) mx_31 <= mx_30;
    (* max_fanout = 16 *) logic [0:0] mx_32;
    always_ff @(posedge clk) mx_32 <= mx_31;
    (* max_fanout = 16 *) logic [0:0] mx_33;
    always_ff @(posedge clk) mx_33 <= mx_32;
    (* max_fanout = 16 *) logic [0:0] mx_34;
    always_ff @(posedge clk) mx_34 <= mx_33;
    (* max_fanout = 16 *) logic [0:0] mx_35;
    always_ff @(posedge clk) mx_35 <= mx_34;
    always_ff @(posedge clk) s2_o1_h <= mx_35[0] ? (60'(s2_o1_h_x >> 1) + (s2_o1_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o1_h_x;
    assign s2_o1 = s2_o1_h;
    logic [59:0] s2_o5;
    logic [59:0] s2_o5_h_x, s2_o5_h;
    assign s2_o5_h_x = s2_k1_yr;
    always_ff @(posedge clk) s2_o5_h <= mx_35[0] ? (60'(s2_o5_h_x >> 1) + (s2_o5_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o5_h_x;
    assign s2_o5 = s2_o5_h;
    logic [59:0] s2_t0_c0_w;
    logic s2_t0_c0_tab_hit_c, s2_t0_c0_tab_hit; logic [3:0] s2_t0_c0_tab_rel;
    assign s2_t0_c0_tab_rel = tw_wi - 4'd0;
    assign s2_t0_c0_tab_hit_c = tw_wen_p && (tw_wi >= 4'd0) && (tw_wi < 4'd2);
    logic [0:0] s2_t0_c0_tab_col_c, s2_t0_c0_tab_col; logic [0:0] s2_t0_c0_tab_wa_c, s2_t0_c0_tab_wa;
    assign s2_t0_c0_tab_col_c = '0; assign s2_t0_c0_tab_wa_c = s2_t0_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s2_t0_c0_tab_hit <= s2_t0_c0_tab_hit_c; s2_t0_c0_tab_col <= s2_t0_c0_tab_col_c; s2_t0_c0_tab_wa <= s2_t0_c0_tab_wa_c; end
    logic s2_t0_c0_tab_hit_q; logic [0:0] s2_t0_c0_tab_col_q; logic [0:0] s2_t0_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s2_t0_c0_tab_wd_q;
    always_ff @(posedge clk) begin s2_t0_c0_tab_hit_q <= s2_t0_c0_tab_hit; s2_t0_c0_tab_col_q <= s2_t0_c0_tab_col; s2_t0_c0_tab_wa_q <= s2_t0_c0_tab_wa; s2_t0_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p2_core_tab0 s2_t0_c0_tab (.clk(clk), .addr({mx_19}), .we(s2_t0_c0_tab_hit_q), .wa(s2_t0_c0_tab_wa_q), .wcol(s2_t0_c0_tab_col_q), .wd(s2_t0_c0_tab_wd_q), .q0(s2_t0_c0_w));
    logic [59:0] s2_k2_xr; logic [59:0] s2_k2_yr;
    MS_N16_q60_P32_tpm_p2_core_s2_bu s2_k2 (.clk(clk), .aIn(s1_o2), .bIn(s1_o6), .W(s2_t0_c0_w), .QH(s2q_QH), .aOut(s2_k2_xr), .bOut(s2_k2_yr));
    logic [59:0] s2_o2;
    logic [59:0] s2_o2_h_x, s2_o2_h;
    assign s2_o2_h_x = s2_k2_xr;
    always_ff @(posedge clk) s2_o2_h <= mx_35[0] ? (60'(s2_o2_h_x >> 1) + (s2_o2_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o2_h_x;
    assign s2_o2 = s2_o2_h;
    logic [59:0] s2_o6;
    logic [59:0] s2_o6_h_x, s2_o6_h;
    assign s2_o6_h_x = s2_k2_yr;
    always_ff @(posedge clk) s2_o6_h <= mx_35[0] ? (60'(s2_o6_h_x >> 1) + (s2_o6_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o6_h_x;
    assign s2_o6 = s2_o6_h;
    logic [59:0] s2_t2_c0_w;
    logic s2_t2_c0_tab_hit_c, s2_t2_c0_tab_hit; logic [3:0] s2_t2_c0_tab_rel;
    assign s2_t2_c0_tab_rel = tw_wi - 4'd4;
    assign s2_t2_c0_tab_hit_c = tw_wen_p && (tw_wi >= 4'd4) && (tw_wi < 4'd6);
    logic [0:0] s2_t2_c0_tab_col_c, s2_t2_c0_tab_col; logic [0:0] s2_t2_c0_tab_wa_c, s2_t2_c0_tab_wa;
    assign s2_t2_c0_tab_col_c = '0; assign s2_t2_c0_tab_wa_c = s2_t2_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s2_t2_c0_tab_hit <= s2_t2_c0_tab_hit_c; s2_t2_c0_tab_col <= s2_t2_c0_tab_col_c; s2_t2_c0_tab_wa <= s2_t2_c0_tab_wa_c; end
    logic s2_t2_c0_tab_hit_q; logic [0:0] s2_t2_c0_tab_col_q; logic [0:0] s2_t2_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s2_t2_c0_tab_wd_q;
    always_ff @(posedge clk) begin s2_t2_c0_tab_hit_q <= s2_t2_c0_tab_hit; s2_t2_c0_tab_col_q <= s2_t2_c0_tab_col; s2_t2_c0_tab_wa_q <= s2_t2_c0_tab_wa; s2_t2_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p2_core_tab2 s2_t2_c0_tab (.clk(clk), .addr({mx_19}), .we(s2_t2_c0_tab_hit_q), .wa(s2_t2_c0_tab_wa_q), .wcol(s2_t2_c0_tab_col_q), .wd(s2_t2_c0_tab_wd_q), .q0(s2_t2_c0_w));
    logic [59:0] s2_k3_xr; logic [59:0] s2_k3_yr;
    MS_N16_q60_P32_tpm_p2_core_s2_bu s2_k3 (.clk(clk), .aIn(s1_o3), .bIn(s1_o7), .W(s2_t2_c0_w), .QH(s2q_QH), .aOut(s2_k3_xr), .bOut(s2_k3_yr));
    logic [59:0] s2_o3;
    logic [59:0] s2_o3_h_x, s2_o3_h;
    assign s2_o3_h_x = s2_k3_xr;
    always_ff @(posedge clk) s2_o3_h <= mx_35[0] ? (60'(s2_o3_h_x >> 1) + (s2_o3_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o3_h_x;
    assign s2_o3 = s2_o3_h;
    logic [59:0] s2_o7;
    logic [59:0] s2_o7_h_x, s2_o7_h;
    assign s2_o7_h_x = s2_k3_yr;
    always_ff @(posedge clk) s2_o7_h <= mx_35[0] ? (60'(s2_o7_h_x >> 1) + (s2_o7_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o7_h_x;
    assign s2_o7 = s2_o7_h;
    logic [59:0] s2_k4_xr; logic [59:0] s2_k4_yr;
    MS_N16_q60_P32_tpm_p2_core_s2_c0 s2_k4 (.clk(clk), .aIn(s1_o8), .bIn(s1_o12), .QH(s2q_QH), .aOut(s2_k4_xr), .bOut(s2_k4_yr));
    logic [59:0] s2_o8;
    logic [59:0] s2_o8_h_x, s2_o8_h;
    assign s2_o8_h_x = s2_k4_xr;
    always_ff @(posedge clk) s2_o8_h <= mx_24[0] ? (60'(s2_o8_h_x >> 1) + (s2_o8_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o8_h_x;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(11)) s2_o8_bal (.clk(clk), .din(s2_o8_h), .dout(s2_o8));
    logic [59:0] s2_o12;
    logic [59:0] s2_o12_h_x, s2_o12_h;
    assign s2_o12_h_x = s2_k4_yr;
    always_ff @(posedge clk) s2_o12_h <= mx_24[0] ? (60'(s2_o12_h_x >> 1) + (s2_o12_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o12_h_x;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(11)) s2_o12_bal (.clk(clk), .din(s2_o12_h), .dout(s2_o12));
    logic [59:0] s2_k5_xr; logic [59:0] s2_k5_yr;
    MS_N16_q60_P32_tpm_p2_core_s2_bu s2_k5 (.clk(clk), .aIn(s1_o9), .bIn(s1_o13), .W(s2_t1_c0_w), .QH(s2q_QH), .aOut(s2_k5_xr), .bOut(s2_k5_yr));
    logic [59:0] s2_o9;
    logic [59:0] s2_o9_h_x, s2_o9_h;
    assign s2_o9_h_x = s2_k5_xr;
    always_ff @(posedge clk) s2_o9_h <= mx_35[0] ? (60'(s2_o9_h_x >> 1) + (s2_o9_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o9_h_x;
    assign s2_o9 = s2_o9_h;
    logic [59:0] s2_o13;
    logic [59:0] s2_o13_h_x, s2_o13_h;
    assign s2_o13_h_x = s2_k5_yr;
    always_ff @(posedge clk) s2_o13_h <= mx_35[0] ? (60'(s2_o13_h_x >> 1) + (s2_o13_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o13_h_x;
    assign s2_o13 = s2_o13_h;
    logic [59:0] s2_k6_xr; logic [59:0] s2_k6_yr;
    MS_N16_q60_P32_tpm_p2_core_s2_bu s2_k6 (.clk(clk), .aIn(s1_o10), .bIn(s1_o14), .W(s2_t0_c0_w), .QH(s2q_QH), .aOut(s2_k6_xr), .bOut(s2_k6_yr));
    logic [59:0] s2_o10;
    logic [59:0] s2_o10_h_x, s2_o10_h;
    assign s2_o10_h_x = s2_k6_xr;
    always_ff @(posedge clk) s2_o10_h <= mx_35[0] ? (60'(s2_o10_h_x >> 1) + (s2_o10_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o10_h_x;
    assign s2_o10 = s2_o10_h;
    logic [59:0] s2_o14;
    logic [59:0] s2_o14_h_x, s2_o14_h;
    assign s2_o14_h_x = s2_k6_yr;
    always_ff @(posedge clk) s2_o14_h <= mx_35[0] ? (60'(s2_o14_h_x >> 1) + (s2_o14_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o14_h_x;
    assign s2_o14 = s2_o14_h;
    logic [59:0] s2_k7_xr; logic [59:0] s2_k7_yr;
    MS_N16_q60_P32_tpm_p2_core_s2_bu s2_k7 (.clk(clk), .aIn(s1_o11), .bIn(s1_o15), .W(s2_t2_c0_w), .QH(s2q_QH), .aOut(s2_k7_xr), .bOut(s2_k7_yr));
    logic [59:0] s2_o11;
    logic [59:0] s2_o11_h_x, s2_o11_h;
    assign s2_o11_h_x = s2_k7_xr;
    always_ff @(posedge clk) s2_o11_h <= mx_35[0] ? (60'(s2_o11_h_x >> 1) + (s2_o11_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o11_h_x;
    assign s2_o11 = s2_o11_h;
    logic [59:0] s2_o15;
    logic [59:0] s2_o15_h_x, s2_o15_h;
    assign s2_o15_h_x = s2_k7_yr;
    always_ff @(posedge clk) s2_o15_h <= mx_35[0] ? (60'(s2_o15_h_x >> 1) + (s2_o15_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o15_h_x;
    assign s2_o15 = s2_o15_h;
    // stage 3: 8 butterflies on lane pairs (bit 3), latency 14
    (* max_fanout = 16 *) logic [16:0] s3q_QH;
    always_ff @(posedge clk) s3q_QH <= QH_r;
    logic [59:0] s3_k0_xr; logic [59:0] s3_k0_yr;
    MS_N16_q60_P32_tpm_p2_core_s3_c0 s3_k0 (.clk(clk), .aIn(s2_o0), .bIn(s2_o8), .QH(s3q_QH), .aOut(s3_k0_xr), .bOut(s3_k0_yr));
    logic [59:0] s3_o0;
    (* max_fanout = 16 *) logic [59:0] s3q_QHALF;
    always_ff @(posedge clk) s3q_QHALF <= QHALF_r;
    logic [59:0] s3_o0_h_x, s3_o0_h;
    assign s3_o0_h_x = s3_k0_xr;
    (* max_fanout = 16 *) logic [0:0] mx_36;
    always_ff @(posedge clk) mx_36 <= mx_35;
    (* max_fanout = 16 *) logic [0:0] mx_37;
    always_ff @(posedge clk) mx_37 <= mx_36;
    (* max_fanout = 16 *) logic [0:0] mx_38;
    always_ff @(posedge clk) mx_38 <= mx_37;
    (* max_fanout = 16 *) logic [0:0] mx_39;
    always_ff @(posedge clk) mx_39 <= mx_38;
    always_ff @(posedge clk) s3_o0_h <= mx_39[0] ? (60'(s3_o0_h_x >> 1) + (s3_o0_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o0_h_x;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(11)) s3_o0_bal (.clk(clk), .din(s3_o0_h), .dout(s3_o0));
    logic [59:0] s3_o8;
    logic [59:0] s3_o8_h_x, s3_o8_h;
    assign s3_o8_h_x = s3_k0_yr;
    always_ff @(posedge clk) s3_o8_h <= mx_39[0] ? (60'(s3_o8_h_x >> 1) + (s3_o8_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o8_h_x;
    MS_N16_q60_P32_tpm_p2_core_dly #(.W(60), .D(11)) s3_o8_bal (.clk(clk), .din(s3_o8_h), .dout(s3_o8));
    logic [59:0] s3_t3_c0_w;
    logic s3_t3_c0_tab_hit_c, s3_t3_c0_tab_hit; logic [3:0] s3_t3_c0_tab_rel;
    assign s3_t3_c0_tab_rel = tw_wi - 4'd6;
    assign s3_t3_c0_tab_hit_c = tw_wen_p && (tw_wi >= 4'd6) && (tw_wi < 4'd8);
    logic [0:0] s3_t3_c0_tab_col_c, s3_t3_c0_tab_col; logic [0:0] s3_t3_c0_tab_wa_c, s3_t3_c0_tab_wa;
    assign s3_t3_c0_tab_col_c = '0; assign s3_t3_c0_tab_wa_c = s3_t3_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s3_t3_c0_tab_hit <= s3_t3_c0_tab_hit_c; s3_t3_c0_tab_col <= s3_t3_c0_tab_col_c; s3_t3_c0_tab_wa <= s3_t3_c0_tab_wa_c; end
    logic s3_t3_c0_tab_hit_q; logic [0:0] s3_t3_c0_tab_col_q; logic [0:0] s3_t3_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s3_t3_c0_tab_wd_q;
    always_ff @(posedge clk) begin s3_t3_c0_tab_hit_q <= s3_t3_c0_tab_hit; s3_t3_c0_tab_col_q <= s3_t3_c0_tab_col; s3_t3_c0_tab_wa_q <= s3_t3_c0_tab_wa; s3_t3_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p2_core_tab3 s3_t3_c0_tab (.clk(clk), .addr({mx_34}), .we(s3_t3_c0_tab_hit_q), .wa(s3_t3_c0_tab_wa_q), .wcol(s3_t3_c0_tab_col_q), .wd(s3_t3_c0_tab_wd_q), .q0(s3_t3_c0_w));
    logic [59:0] s3_k1_xr; logic [59:0] s3_k1_yr;
    MS_N16_q60_P32_tpm_p2_core_s3_bu s3_k1 (.clk(clk), .aIn(s2_o1), .bIn(s2_o9), .W(s3_t3_c0_w), .QH(s3q_QH), .aOut(s3_k1_xr), .bOut(s3_k1_yr));
    logic [59:0] s3_o1;
    logic [59:0] s3_o1_h_x, s3_o1_h;
    assign s3_o1_h_x = s3_k1_xr;
    (* max_fanout = 16 *) logic [0:0] mx_40;
    always_ff @(posedge clk) mx_40 <= mx_39;
    (* max_fanout = 16 *) logic [0:0] mx_41;
    always_ff @(posedge clk) mx_41 <= mx_40;
    (* max_fanout = 16 *) logic [0:0] mx_42;
    always_ff @(posedge clk) mx_42 <= mx_41;
    (* max_fanout = 16 *) logic [0:0] mx_43;
    always_ff @(posedge clk) mx_43 <= mx_42;
    (* max_fanout = 16 *) logic [0:0] mx_44;
    always_ff @(posedge clk) mx_44 <= mx_43;
    (* max_fanout = 16 *) logic [0:0] mx_45;
    always_ff @(posedge clk) mx_45 <= mx_44;
    (* max_fanout = 16 *) logic [0:0] mx_46;
    always_ff @(posedge clk) mx_46 <= mx_45;
    (* max_fanout = 16 *) logic [0:0] mx_47;
    always_ff @(posedge clk) mx_47 <= mx_46;
    (* max_fanout = 16 *) logic [0:0] mx_48;
    always_ff @(posedge clk) mx_48 <= mx_47;
    (* max_fanout = 16 *) logic [0:0] mx_49;
    always_ff @(posedge clk) mx_49 <= mx_48;
    (* max_fanout = 16 *) logic [0:0] mx_50;
    always_ff @(posedge clk) mx_50 <= mx_49;
    always_ff @(posedge clk) s3_o1_h <= mx_50[0] ? (60'(s3_o1_h_x >> 1) + (s3_o1_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o1_h_x;
    assign s3_o1 = s3_o1_h;
    logic [59:0] s3_o9;
    logic [59:0] s3_o9_h_x, s3_o9_h;
    assign s3_o9_h_x = s3_k1_yr;
    always_ff @(posedge clk) s3_o9_h <= mx_50[0] ? (60'(s3_o9_h_x >> 1) + (s3_o9_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o9_h_x;
    assign s3_o9 = s3_o9_h;
    logic [59:0] s3_t1_c0_w;
    logic s3_t1_c0_tab_hit_c, s3_t1_c0_tab_hit; logic [3:0] s3_t1_c0_tab_rel;
    assign s3_t1_c0_tab_rel = tw_wi - 4'd2;
    assign s3_t1_c0_tab_hit_c = tw_wen_p && (tw_wi >= 4'd2) && (tw_wi < 4'd4);
    logic [0:0] s3_t1_c0_tab_col_c, s3_t1_c0_tab_col; logic [0:0] s3_t1_c0_tab_wa_c, s3_t1_c0_tab_wa;
    assign s3_t1_c0_tab_col_c = '0; assign s3_t1_c0_tab_wa_c = s3_t1_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s3_t1_c0_tab_hit <= s3_t1_c0_tab_hit_c; s3_t1_c0_tab_col <= s3_t1_c0_tab_col_c; s3_t1_c0_tab_wa <= s3_t1_c0_tab_wa_c; end
    logic s3_t1_c0_tab_hit_q; logic [0:0] s3_t1_c0_tab_col_q; logic [0:0] s3_t1_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s3_t1_c0_tab_wd_q;
    always_ff @(posedge clk) begin s3_t1_c0_tab_hit_q <= s3_t1_c0_tab_hit; s3_t1_c0_tab_col_q <= s3_t1_c0_tab_col; s3_t1_c0_tab_wa_q <= s3_t1_c0_tab_wa; s3_t1_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p2_core_tab1 s3_t1_c0_tab (.clk(clk), .addr({mx_34}), .we(s3_t1_c0_tab_hit_q), .wa(s3_t1_c0_tab_wa_q), .wcol(s3_t1_c0_tab_col_q), .wd(s3_t1_c0_tab_wd_q), .q0(s3_t1_c0_w));
    logic [59:0] s3_k2_xr; logic [59:0] s3_k2_yr;
    MS_N16_q60_P32_tpm_p2_core_s3_bu s3_k2 (.clk(clk), .aIn(s2_o2), .bIn(s2_o10), .W(s3_t1_c0_w), .QH(s3q_QH), .aOut(s3_k2_xr), .bOut(s3_k2_yr));
    logic [59:0] s3_o2;
    logic [59:0] s3_o2_h_x, s3_o2_h;
    assign s3_o2_h_x = s3_k2_xr;
    always_ff @(posedge clk) s3_o2_h <= mx_50[0] ? (60'(s3_o2_h_x >> 1) + (s3_o2_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o2_h_x;
    assign s3_o2 = s3_o2_h;
    logic [59:0] s3_o10;
    logic [59:0] s3_o10_h_x, s3_o10_h;
    assign s3_o10_h_x = s3_k2_yr;
    always_ff @(posedge clk) s3_o10_h <= mx_50[0] ? (60'(s3_o10_h_x >> 1) + (s3_o10_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o10_h_x;
    assign s3_o10 = s3_o10_h;
    logic [59:0] s3_t4_c0_w;
    logic s3_t4_c0_tab_hit_c, s3_t4_c0_tab_hit; logic [3:0] s3_t4_c0_tab_rel;
    assign s3_t4_c0_tab_rel = tw_wi - 4'd8;
    assign s3_t4_c0_tab_hit_c = tw_wen_p && (tw_wi >= 4'd8) && (tw_wi < 4'd10);
    logic [0:0] s3_t4_c0_tab_col_c, s3_t4_c0_tab_col; logic [0:0] s3_t4_c0_tab_wa_c, s3_t4_c0_tab_wa;
    assign s3_t4_c0_tab_col_c = '0; assign s3_t4_c0_tab_wa_c = s3_t4_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s3_t4_c0_tab_hit <= s3_t4_c0_tab_hit_c; s3_t4_c0_tab_col <= s3_t4_c0_tab_col_c; s3_t4_c0_tab_wa <= s3_t4_c0_tab_wa_c; end
    logic s3_t4_c0_tab_hit_q; logic [0:0] s3_t4_c0_tab_col_q; logic [0:0] s3_t4_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s3_t4_c0_tab_wd_q;
    always_ff @(posedge clk) begin s3_t4_c0_tab_hit_q <= s3_t4_c0_tab_hit; s3_t4_c0_tab_col_q <= s3_t4_c0_tab_col; s3_t4_c0_tab_wa_q <= s3_t4_c0_tab_wa; s3_t4_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p2_core_tab4 s3_t4_c0_tab (.clk(clk), .addr({mx_34}), .we(s3_t4_c0_tab_hit_q), .wa(s3_t4_c0_tab_wa_q), .wcol(s3_t4_c0_tab_col_q), .wd(s3_t4_c0_tab_wd_q), .q0(s3_t4_c0_w));
    logic [59:0] s3_k3_xr; logic [59:0] s3_k3_yr;
    MS_N16_q60_P32_tpm_p2_core_s3_bu s3_k3 (.clk(clk), .aIn(s2_o3), .bIn(s2_o11), .W(s3_t4_c0_w), .QH(s3q_QH), .aOut(s3_k3_xr), .bOut(s3_k3_yr));
    logic [59:0] s3_o3;
    logic [59:0] s3_o3_h_x, s3_o3_h;
    assign s3_o3_h_x = s3_k3_xr;
    always_ff @(posedge clk) s3_o3_h <= mx_50[0] ? (60'(s3_o3_h_x >> 1) + (s3_o3_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o3_h_x;
    assign s3_o3 = s3_o3_h;
    logic [59:0] s3_o11;
    logic [59:0] s3_o11_h_x, s3_o11_h;
    assign s3_o11_h_x = s3_k3_yr;
    always_ff @(posedge clk) s3_o11_h <= mx_50[0] ? (60'(s3_o11_h_x >> 1) + (s3_o11_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o11_h_x;
    assign s3_o11 = s3_o11_h;
    logic [59:0] s3_t0_c0_w;
    logic s3_t0_c0_tab_hit_c, s3_t0_c0_tab_hit; logic [3:0] s3_t0_c0_tab_rel;
    assign s3_t0_c0_tab_rel = tw_wi - 4'd0;
    assign s3_t0_c0_tab_hit_c = tw_wen_p && (tw_wi >= 4'd0) && (tw_wi < 4'd2);
    logic [0:0] s3_t0_c0_tab_col_c, s3_t0_c0_tab_col; logic [0:0] s3_t0_c0_tab_wa_c, s3_t0_c0_tab_wa;
    assign s3_t0_c0_tab_col_c = '0; assign s3_t0_c0_tab_wa_c = s3_t0_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s3_t0_c0_tab_hit <= s3_t0_c0_tab_hit_c; s3_t0_c0_tab_col <= s3_t0_c0_tab_col_c; s3_t0_c0_tab_wa <= s3_t0_c0_tab_wa_c; end
    logic s3_t0_c0_tab_hit_q; logic [0:0] s3_t0_c0_tab_col_q; logic [0:0] s3_t0_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s3_t0_c0_tab_wd_q;
    always_ff @(posedge clk) begin s3_t0_c0_tab_hit_q <= s3_t0_c0_tab_hit; s3_t0_c0_tab_col_q <= s3_t0_c0_tab_col; s3_t0_c0_tab_wa_q <= s3_t0_c0_tab_wa; s3_t0_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p2_core_tab0 s3_t0_c0_tab (.clk(clk), .addr({mx_34}), .we(s3_t0_c0_tab_hit_q), .wa(s3_t0_c0_tab_wa_q), .wcol(s3_t0_c0_tab_col_q), .wd(s3_t0_c0_tab_wd_q), .q0(s3_t0_c0_w));
    logic [59:0] s3_k4_xr; logic [59:0] s3_k4_yr;
    MS_N16_q60_P32_tpm_p2_core_s3_bu s3_k4 (.clk(clk), .aIn(s2_o4), .bIn(s2_o12), .W(s3_t0_c0_w), .QH(s3q_QH), .aOut(s3_k4_xr), .bOut(s3_k4_yr));
    logic [59:0] s3_o4;
    logic [59:0] s3_o4_h_x, s3_o4_h;
    assign s3_o4_h_x = s3_k4_xr;
    always_ff @(posedge clk) s3_o4_h <= mx_50[0] ? (60'(s3_o4_h_x >> 1) + (s3_o4_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o4_h_x;
    assign s3_o4 = s3_o4_h;
    logic [59:0] s3_o12;
    logic [59:0] s3_o12_h_x, s3_o12_h;
    assign s3_o12_h_x = s3_k4_yr;
    always_ff @(posedge clk) s3_o12_h <= mx_50[0] ? (60'(s3_o12_h_x >> 1) + (s3_o12_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o12_h_x;
    assign s3_o12 = s3_o12_h;
    logic [59:0] s3_t5_c0_w;
    logic s3_t5_c0_tab_hit_c, s3_t5_c0_tab_hit; logic [3:0] s3_t5_c0_tab_rel;
    assign s3_t5_c0_tab_rel = tw_wi - 4'd10;
    assign s3_t5_c0_tab_hit_c = tw_wen_p && (tw_wi >= 4'd10) && (tw_wi < 4'd12);
    logic [0:0] s3_t5_c0_tab_col_c, s3_t5_c0_tab_col; logic [0:0] s3_t5_c0_tab_wa_c, s3_t5_c0_tab_wa;
    assign s3_t5_c0_tab_col_c = '0; assign s3_t5_c0_tab_wa_c = s3_t5_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s3_t5_c0_tab_hit <= s3_t5_c0_tab_hit_c; s3_t5_c0_tab_col <= s3_t5_c0_tab_col_c; s3_t5_c0_tab_wa <= s3_t5_c0_tab_wa_c; end
    logic s3_t5_c0_tab_hit_q; logic [0:0] s3_t5_c0_tab_col_q; logic [0:0] s3_t5_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s3_t5_c0_tab_wd_q;
    always_ff @(posedge clk) begin s3_t5_c0_tab_hit_q <= s3_t5_c0_tab_hit; s3_t5_c0_tab_col_q <= s3_t5_c0_tab_col; s3_t5_c0_tab_wa_q <= s3_t5_c0_tab_wa; s3_t5_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p2_core_tab5 s3_t5_c0_tab (.clk(clk), .addr({mx_34}), .we(s3_t5_c0_tab_hit_q), .wa(s3_t5_c0_tab_wa_q), .wcol(s3_t5_c0_tab_col_q), .wd(s3_t5_c0_tab_wd_q), .q0(s3_t5_c0_w));
    logic [59:0] s3_k5_xr; logic [59:0] s3_k5_yr;
    MS_N16_q60_P32_tpm_p2_core_s3_bu s3_k5 (.clk(clk), .aIn(s2_o5), .bIn(s2_o13), .W(s3_t5_c0_w), .QH(s3q_QH), .aOut(s3_k5_xr), .bOut(s3_k5_yr));
    logic [59:0] s3_o5;
    logic [59:0] s3_o5_h_x, s3_o5_h;
    assign s3_o5_h_x = s3_k5_xr;
    always_ff @(posedge clk) s3_o5_h <= mx_50[0] ? (60'(s3_o5_h_x >> 1) + (s3_o5_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o5_h_x;
    assign s3_o5 = s3_o5_h;
    logic [59:0] s3_o13;
    logic [59:0] s3_o13_h_x, s3_o13_h;
    assign s3_o13_h_x = s3_k5_yr;
    always_ff @(posedge clk) s3_o13_h <= mx_50[0] ? (60'(s3_o13_h_x >> 1) + (s3_o13_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o13_h_x;
    assign s3_o13 = s3_o13_h;
    logic [59:0] s3_t2_c0_w;
    logic s3_t2_c0_tab_hit_c, s3_t2_c0_tab_hit; logic [3:0] s3_t2_c0_tab_rel;
    assign s3_t2_c0_tab_rel = tw_wi - 4'd4;
    assign s3_t2_c0_tab_hit_c = tw_wen_p && (tw_wi >= 4'd4) && (tw_wi < 4'd6);
    logic [0:0] s3_t2_c0_tab_col_c, s3_t2_c0_tab_col; logic [0:0] s3_t2_c0_tab_wa_c, s3_t2_c0_tab_wa;
    assign s3_t2_c0_tab_col_c = '0; assign s3_t2_c0_tab_wa_c = s3_t2_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s3_t2_c0_tab_hit <= s3_t2_c0_tab_hit_c; s3_t2_c0_tab_col <= s3_t2_c0_tab_col_c; s3_t2_c0_tab_wa <= s3_t2_c0_tab_wa_c; end
    logic s3_t2_c0_tab_hit_q; logic [0:0] s3_t2_c0_tab_col_q; logic [0:0] s3_t2_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s3_t2_c0_tab_wd_q;
    always_ff @(posedge clk) begin s3_t2_c0_tab_hit_q <= s3_t2_c0_tab_hit; s3_t2_c0_tab_col_q <= s3_t2_c0_tab_col; s3_t2_c0_tab_wa_q <= s3_t2_c0_tab_wa; s3_t2_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p2_core_tab2 s3_t2_c0_tab (.clk(clk), .addr({mx_34}), .we(s3_t2_c0_tab_hit_q), .wa(s3_t2_c0_tab_wa_q), .wcol(s3_t2_c0_tab_col_q), .wd(s3_t2_c0_tab_wd_q), .q0(s3_t2_c0_w));
    logic [59:0] s3_k6_xr; logic [59:0] s3_k6_yr;
    MS_N16_q60_P32_tpm_p2_core_s3_bu s3_k6 (.clk(clk), .aIn(s2_o6), .bIn(s2_o14), .W(s3_t2_c0_w), .QH(s3q_QH), .aOut(s3_k6_xr), .bOut(s3_k6_yr));
    logic [59:0] s3_o6;
    logic [59:0] s3_o6_h_x, s3_o6_h;
    assign s3_o6_h_x = s3_k6_xr;
    always_ff @(posedge clk) s3_o6_h <= mx_50[0] ? (60'(s3_o6_h_x >> 1) + (s3_o6_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o6_h_x;
    assign s3_o6 = s3_o6_h;
    logic [59:0] s3_o14;
    logic [59:0] s3_o14_h_x, s3_o14_h;
    assign s3_o14_h_x = s3_k6_yr;
    always_ff @(posedge clk) s3_o14_h <= mx_50[0] ? (60'(s3_o14_h_x >> 1) + (s3_o14_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o14_h_x;
    assign s3_o14 = s3_o14_h;
    logic [59:0] s3_t6_c0_w;
    logic s3_t6_c0_tab_hit_c, s3_t6_c0_tab_hit; logic [3:0] s3_t6_c0_tab_rel;
    assign s3_t6_c0_tab_rel = tw_wi - 4'd12;
    assign s3_t6_c0_tab_hit_c = tw_wen_p && (tw_wi >= 4'd12) && (tw_wi < 4'd14);
    logic [0:0] s3_t6_c0_tab_col_c, s3_t6_c0_tab_col; logic [0:0] s3_t6_c0_tab_wa_c, s3_t6_c0_tab_wa;
    assign s3_t6_c0_tab_col_c = '0; assign s3_t6_c0_tab_wa_c = s3_t6_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s3_t6_c0_tab_hit <= s3_t6_c0_tab_hit_c; s3_t6_c0_tab_col <= s3_t6_c0_tab_col_c; s3_t6_c0_tab_wa <= s3_t6_c0_tab_wa_c; end
    logic s3_t6_c0_tab_hit_q; logic [0:0] s3_t6_c0_tab_col_q; logic [0:0] s3_t6_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s3_t6_c0_tab_wd_q;
    always_ff @(posedge clk) begin s3_t6_c0_tab_hit_q <= s3_t6_c0_tab_hit; s3_t6_c0_tab_col_q <= s3_t6_c0_tab_col; s3_t6_c0_tab_wa_q <= s3_t6_c0_tab_wa; s3_t6_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p2_core_tab6 s3_t6_c0_tab (.clk(clk), .addr({mx_34}), .we(s3_t6_c0_tab_hit_q), .wa(s3_t6_c0_tab_wa_q), .wcol(s3_t6_c0_tab_col_q), .wd(s3_t6_c0_tab_wd_q), .q0(s3_t6_c0_w));
    logic [59:0] s3_k7_xr; logic [59:0] s3_k7_yr;
    MS_N16_q60_P32_tpm_p2_core_s3_bu s3_k7 (.clk(clk), .aIn(s2_o7), .bIn(s2_o15), .W(s3_t6_c0_w), .QH(s3q_QH), .aOut(s3_k7_xr), .bOut(s3_k7_yr));
    logic [59:0] s3_o7;
    logic [59:0] s3_o7_h_x, s3_o7_h;
    assign s3_o7_h_x = s3_k7_xr;
    always_ff @(posedge clk) s3_o7_h <= mx_50[0] ? (60'(s3_o7_h_x >> 1) + (s3_o7_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o7_h_x;
    assign s3_o7 = s3_o7_h;
    logic [59:0] s3_o15;
    logic [59:0] s3_o15_h_x, s3_o15_h;
    assign s3_o15_h_x = s3_k7_yr;
    always_ff @(posedge clk) s3_o15_h <= mx_50[0] ? (60'(s3_o15_h_x >> 1) + (s3_o15_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o15_h_x;
    assign s3_o15 = s3_o15_h;
    assign y_out_0 = s3_o0;
    assign y_out_1 = s3_o1;
    assign y_out_2 = s3_o2;
    assign y_out_3 = s3_o3;
    assign y_out_4 = s3_o4;
    assign y_out_5 = s3_o5;
    assign y_out_6 = s3_o6;
    assign y_out_7 = s3_o7;
    assign y_out_8 = s3_o8;
    assign y_out_9 = s3_o9;
    assign y_out_10 = s3_o10;
    assign y_out_11 = s3_o11;
    assign y_out_12 = s3_o12;
    assign y_out_13 = s3_o13;
    assign y_out_14 = s3_o14;
    assign y_out_15 = s3_o15;
endmodule
