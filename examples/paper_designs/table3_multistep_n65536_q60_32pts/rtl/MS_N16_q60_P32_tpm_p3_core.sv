`timescale 1ns / 1ps
// MS_N16_q60_P32_tpm_p3_core: streaming NTT, n=32, 32 lanes, frame 1 cycles, run-time q, direction both, latency 78
module MS_N16_q60_P32_tpm_p3_core (
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
    (* max_fanout = 32 *) logic tw_rst_p, tw_wen_p; (* max_fanout = 32 *) logic [59:0] tw_wdata_p;
    always_ff @(posedge clk) begin tw_rst_p <= tw_rst; tw_wen_p <= tw_wen; tw_wdata_p <= tw_wdata; end
    (* max_fanout = 32 *) logic [6:0] tw_wi;
    always_ff @(posedge clk) tw_wi <= tw_rst_p ? '0 : (tw_wen_p ? tw_wi + 1'b1 : tw_wi);
    (* max_fanout = 32 *) logic [59:0] tw_wd_q;
    always_ff @(posedge clk) tw_wd_q <= tw_wdata_p;
    logic [0:0] mx_1;
    always_ff @(posedge clk) mx_1 <= DIR;
    // per-frame direction: input lead of 2 cycles
    logic [59:0] xl_0;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl0_dly (.clk(clk), .din(x_in_0), .dout(xl_0));
    logic [59:0] xl_1;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl1_dly (.clk(clk), .din(x_in_1), .dout(xl_1));
    logic [59:0] xl_2;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl2_dly (.clk(clk), .din(x_in_2), .dout(xl_2));
    logic [59:0] xl_3;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl3_dly (.clk(clk), .din(x_in_3), .dout(xl_3));
    logic [59:0] xl_4;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl4_dly (.clk(clk), .din(x_in_4), .dout(xl_4));
    logic [59:0] xl_5;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl5_dly (.clk(clk), .din(x_in_5), .dout(xl_5));
    logic [59:0] xl_6;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl6_dly (.clk(clk), .din(x_in_6), .dout(xl_6));
    logic [59:0] xl_7;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl7_dly (.clk(clk), .din(x_in_7), .dout(xl_7));
    logic [59:0] xl_8;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl8_dly (.clk(clk), .din(x_in_8), .dout(xl_8));
    logic [59:0] xl_9;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl9_dly (.clk(clk), .din(x_in_9), .dout(xl_9));
    logic [59:0] xl_10;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl10_dly (.clk(clk), .din(x_in_10), .dout(xl_10));
    logic [59:0] xl_11;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl11_dly (.clk(clk), .din(x_in_11), .dout(xl_11));
    logic [59:0] xl_12;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl12_dly (.clk(clk), .din(x_in_12), .dout(xl_12));
    logic [59:0] xl_13;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl13_dly (.clk(clk), .din(x_in_13), .dout(xl_13));
    logic [59:0] xl_14;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl14_dly (.clk(clk), .din(x_in_14), .dout(xl_14));
    logic [59:0] xl_15;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl15_dly (.clk(clk), .din(x_in_15), .dout(xl_15));
    logic [59:0] xl_16;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl16_dly (.clk(clk), .din(x_in_16), .dout(xl_16));
    logic [59:0] xl_17;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl17_dly (.clk(clk), .din(x_in_17), .dout(xl_17));
    logic [59:0] xl_18;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl18_dly (.clk(clk), .din(x_in_18), .dout(xl_18));
    logic [59:0] xl_19;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl19_dly (.clk(clk), .din(x_in_19), .dout(xl_19));
    logic [59:0] xl_20;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl20_dly (.clk(clk), .din(x_in_20), .dout(xl_20));
    logic [59:0] xl_21;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl21_dly (.clk(clk), .din(x_in_21), .dout(xl_21));
    logic [59:0] xl_22;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl22_dly (.clk(clk), .din(x_in_22), .dout(xl_22));
    logic [59:0] xl_23;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl23_dly (.clk(clk), .din(x_in_23), .dout(xl_23));
    logic [59:0] xl_24;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl24_dly (.clk(clk), .din(x_in_24), .dout(xl_24));
    logic [59:0] xl_25;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl25_dly (.clk(clk), .din(x_in_25), .dout(xl_25));
    logic [59:0] xl_26;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl26_dly (.clk(clk), .din(x_in_26), .dout(xl_26));
    logic [59:0] xl_27;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl27_dly (.clk(clk), .din(x_in_27), .dout(xl_27));
    logic [59:0] xl_28;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl28_dly (.clk(clk), .din(x_in_28), .dout(xl_28));
    logic [59:0] xl_29;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl29_dly (.clk(clk), .din(x_in_29), .dout(xl_29));
    logic [59:0] xl_30;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl30_dly (.clk(clk), .din(x_in_30), .dout(xl_30));
    logic [59:0] xl_31;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(2)) xl31_dly (.clk(clk), .din(x_in_31), .dout(xl_31));
    (* max_fanout = 16 *) logic [16:0] QH_r;
    always_ff @(posedge clk) QH_r <= QH;
    (* max_fanout = 16 *) logic [59:0] QHALF_r;
    always_ff @(posedge clk) QHALF_r <= QHALF;
    // stage 0: 16 butterflies on lane pairs (bit 0), latency 3
    (* max_fanout = 16 *) logic [16:0] s0q_QH;
    always_ff @(posedge clk) s0q_QH <= QH_r;
    logic [59:0] s0_k0_xr; logic [59:0] s0_k0_yr;
    MS_N16_q60_P32_tpm_p3_core_s0_c0 s0_k0 (.clk(clk), .aIn(xl_0), .bIn(xl_1), .QH(s0q_QH), .aOut(s0_k0_xr), .bOut(s0_k0_yr));
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
    MS_N16_q60_P32_tpm_p3_core_s0_c0 s0_k1 (.clk(clk), .aIn(xl_2), .bIn(xl_3), .QH(s0q_QH), .aOut(s0_k1_xr), .bOut(s0_k1_yr));
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
    MS_N16_q60_P32_tpm_p3_core_s0_c0 s0_k2 (.clk(clk), .aIn(xl_4), .bIn(xl_5), .QH(s0q_QH), .aOut(s0_k2_xr), .bOut(s0_k2_yr));
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
    MS_N16_q60_P32_tpm_p3_core_s0_c0 s0_k3 (.clk(clk), .aIn(xl_6), .bIn(xl_7), .QH(s0q_QH), .aOut(s0_k3_xr), .bOut(s0_k3_yr));
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
    MS_N16_q60_P32_tpm_p3_core_s0_c0 s0_k4 (.clk(clk), .aIn(xl_8), .bIn(xl_9), .QH(s0q_QH), .aOut(s0_k4_xr), .bOut(s0_k4_yr));
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
    MS_N16_q60_P32_tpm_p3_core_s0_c0 s0_k5 (.clk(clk), .aIn(xl_10), .bIn(xl_11), .QH(s0q_QH), .aOut(s0_k5_xr), .bOut(s0_k5_yr));
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
    MS_N16_q60_P32_tpm_p3_core_s0_c0 s0_k6 (.clk(clk), .aIn(xl_12), .bIn(xl_13), .QH(s0q_QH), .aOut(s0_k6_xr), .bOut(s0_k6_yr));
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
    MS_N16_q60_P32_tpm_p3_core_s0_c0 s0_k7 (.clk(clk), .aIn(xl_14), .bIn(xl_15), .QH(s0q_QH), .aOut(s0_k7_xr), .bOut(s0_k7_yr));
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
    logic [59:0] s0_k8_xr; logic [59:0] s0_k8_yr;
    MS_N16_q60_P32_tpm_p3_core_s0_c0 s0_k8 (.clk(clk), .aIn(xl_16), .bIn(xl_17), .QH(s0q_QH), .aOut(s0_k8_xr), .bOut(s0_k8_yr));
    logic [59:0] s0_o16;
    logic [59:0] s0_o16_h_x, s0_o16_h;
    assign s0_o16_h_x = s0_k8_xr;
    always_ff @(posedge clk) s0_o16_h <= mx_5[0] ? (60'(s0_o16_h_x >> 1) + (s0_o16_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o16_h_x;
    assign s0_o16 = s0_o16_h;
    logic [59:0] s0_o17;
    logic [59:0] s0_o17_h_x, s0_o17_h;
    assign s0_o17_h_x = s0_k8_yr;
    always_ff @(posedge clk) s0_o17_h <= mx_5[0] ? (60'(s0_o17_h_x >> 1) + (s0_o17_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o17_h_x;
    assign s0_o17 = s0_o17_h;
    logic [59:0] s0_k9_xr; logic [59:0] s0_k9_yr;
    MS_N16_q60_P32_tpm_p3_core_s0_c0 s0_k9 (.clk(clk), .aIn(xl_18), .bIn(xl_19), .QH(s0q_QH), .aOut(s0_k9_xr), .bOut(s0_k9_yr));
    logic [59:0] s0_o18;
    logic [59:0] s0_o18_h_x, s0_o18_h;
    assign s0_o18_h_x = s0_k9_xr;
    always_ff @(posedge clk) s0_o18_h <= mx_5[0] ? (60'(s0_o18_h_x >> 1) + (s0_o18_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o18_h_x;
    assign s0_o18 = s0_o18_h;
    logic [59:0] s0_o19;
    logic [59:0] s0_o19_h_x, s0_o19_h;
    assign s0_o19_h_x = s0_k9_yr;
    always_ff @(posedge clk) s0_o19_h <= mx_5[0] ? (60'(s0_o19_h_x >> 1) + (s0_o19_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o19_h_x;
    assign s0_o19 = s0_o19_h;
    logic [59:0] s0_k10_xr; logic [59:0] s0_k10_yr;
    MS_N16_q60_P32_tpm_p3_core_s0_c0 s0_k10 (.clk(clk), .aIn(xl_20), .bIn(xl_21), .QH(s0q_QH), .aOut(s0_k10_xr), .bOut(s0_k10_yr));
    logic [59:0] s0_o20;
    logic [59:0] s0_o20_h_x, s0_o20_h;
    assign s0_o20_h_x = s0_k10_xr;
    always_ff @(posedge clk) s0_o20_h <= mx_5[0] ? (60'(s0_o20_h_x >> 1) + (s0_o20_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o20_h_x;
    assign s0_o20 = s0_o20_h;
    logic [59:0] s0_o21;
    logic [59:0] s0_o21_h_x, s0_o21_h;
    assign s0_o21_h_x = s0_k10_yr;
    always_ff @(posedge clk) s0_o21_h <= mx_5[0] ? (60'(s0_o21_h_x >> 1) + (s0_o21_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o21_h_x;
    assign s0_o21 = s0_o21_h;
    logic [59:0] s0_k11_xr; logic [59:0] s0_k11_yr;
    MS_N16_q60_P32_tpm_p3_core_s0_c0 s0_k11 (.clk(clk), .aIn(xl_22), .bIn(xl_23), .QH(s0q_QH), .aOut(s0_k11_xr), .bOut(s0_k11_yr));
    logic [59:0] s0_o22;
    logic [59:0] s0_o22_h_x, s0_o22_h;
    assign s0_o22_h_x = s0_k11_xr;
    always_ff @(posedge clk) s0_o22_h <= mx_5[0] ? (60'(s0_o22_h_x >> 1) + (s0_o22_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o22_h_x;
    assign s0_o22 = s0_o22_h;
    logic [59:0] s0_o23;
    logic [59:0] s0_o23_h_x, s0_o23_h;
    assign s0_o23_h_x = s0_k11_yr;
    always_ff @(posedge clk) s0_o23_h <= mx_5[0] ? (60'(s0_o23_h_x >> 1) + (s0_o23_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o23_h_x;
    assign s0_o23 = s0_o23_h;
    logic [59:0] s0_k12_xr; logic [59:0] s0_k12_yr;
    MS_N16_q60_P32_tpm_p3_core_s0_c0 s0_k12 (.clk(clk), .aIn(xl_24), .bIn(xl_25), .QH(s0q_QH), .aOut(s0_k12_xr), .bOut(s0_k12_yr));
    logic [59:0] s0_o24;
    logic [59:0] s0_o24_h_x, s0_o24_h;
    assign s0_o24_h_x = s0_k12_xr;
    always_ff @(posedge clk) s0_o24_h <= mx_5[0] ? (60'(s0_o24_h_x >> 1) + (s0_o24_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o24_h_x;
    assign s0_o24 = s0_o24_h;
    logic [59:0] s0_o25;
    logic [59:0] s0_o25_h_x, s0_o25_h;
    assign s0_o25_h_x = s0_k12_yr;
    always_ff @(posedge clk) s0_o25_h <= mx_5[0] ? (60'(s0_o25_h_x >> 1) + (s0_o25_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o25_h_x;
    assign s0_o25 = s0_o25_h;
    logic [59:0] s0_k13_xr; logic [59:0] s0_k13_yr;
    MS_N16_q60_P32_tpm_p3_core_s0_c0 s0_k13 (.clk(clk), .aIn(xl_26), .bIn(xl_27), .QH(s0q_QH), .aOut(s0_k13_xr), .bOut(s0_k13_yr));
    logic [59:0] s0_o26;
    logic [59:0] s0_o26_h_x, s0_o26_h;
    assign s0_o26_h_x = s0_k13_xr;
    always_ff @(posedge clk) s0_o26_h <= mx_5[0] ? (60'(s0_o26_h_x >> 1) + (s0_o26_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o26_h_x;
    assign s0_o26 = s0_o26_h;
    logic [59:0] s0_o27;
    logic [59:0] s0_o27_h_x, s0_o27_h;
    assign s0_o27_h_x = s0_k13_yr;
    always_ff @(posedge clk) s0_o27_h <= mx_5[0] ? (60'(s0_o27_h_x >> 1) + (s0_o27_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o27_h_x;
    assign s0_o27 = s0_o27_h;
    logic [59:0] s0_k14_xr; logic [59:0] s0_k14_yr;
    MS_N16_q60_P32_tpm_p3_core_s0_c0 s0_k14 (.clk(clk), .aIn(xl_28), .bIn(xl_29), .QH(s0q_QH), .aOut(s0_k14_xr), .bOut(s0_k14_yr));
    logic [59:0] s0_o28;
    logic [59:0] s0_o28_h_x, s0_o28_h;
    assign s0_o28_h_x = s0_k14_xr;
    always_ff @(posedge clk) s0_o28_h <= mx_5[0] ? (60'(s0_o28_h_x >> 1) + (s0_o28_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o28_h_x;
    assign s0_o28 = s0_o28_h;
    logic [59:0] s0_o29;
    logic [59:0] s0_o29_h_x, s0_o29_h;
    assign s0_o29_h_x = s0_k14_yr;
    always_ff @(posedge clk) s0_o29_h <= mx_5[0] ? (60'(s0_o29_h_x >> 1) + (s0_o29_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o29_h_x;
    assign s0_o29 = s0_o29_h;
    logic [59:0] s0_k15_xr; logic [59:0] s0_k15_yr;
    MS_N16_q60_P32_tpm_p3_core_s0_c0 s0_k15 (.clk(clk), .aIn(xl_30), .bIn(xl_31), .QH(s0q_QH), .aOut(s0_k15_xr), .bOut(s0_k15_yr));
    logic [59:0] s0_o30;
    logic [59:0] s0_o30_h_x, s0_o30_h;
    assign s0_o30_h_x = s0_k15_xr;
    always_ff @(posedge clk) s0_o30_h <= mx_5[0] ? (60'(s0_o30_h_x >> 1) + (s0_o30_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o30_h_x;
    assign s0_o30 = s0_o30_h;
    logic [59:0] s0_o31;
    logic [59:0] s0_o31_h_x, s0_o31_h;
    assign s0_o31_h_x = s0_k15_yr;
    always_ff @(posedge clk) s0_o31_h <= mx_5[0] ? (60'(s0_o31_h_x >> 1) + (s0_o31_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o31_h_x;
    assign s0_o31 = s0_o31_h;
    // stage 1: 16 butterflies on lane pairs (bit 1), latency 14
    (* max_fanout = 16 *) logic [16:0] s1q_QH;
    always_ff @(posedge clk) s1q_QH <= QH_r;
    logic [59:0] s1_k0_xr; logic [59:0] s1_k0_yr;
    MS_N16_q60_P32_tpm_p3_core_s1_c0 s1_k0 (.clk(clk), .aIn(s0_o0), .bIn(s0_o2), .QH(s1q_QH), .aOut(s1_k0_xr), .bOut(s1_k0_yr));
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
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s1_o0_bal (.clk(clk), .din(s1_o0_h), .dout(s1_o0));
    logic [59:0] s1_o2;
    logic [59:0] s1_o2_h_x, s1_o2_h;
    assign s1_o2_h_x = s1_k0_yr;
    always_ff @(posedge clk) s1_o2_h <= mx_9[0] ? (60'(s1_o2_h_x >> 1) + (s1_o2_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o2_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s1_o2_bal (.clk(clk), .din(s1_o2_h), .dout(s1_o2));
    logic [59:0] s1_t0_c0_w;
    logic s1_t0_c0_tab_hit_c, s1_t0_c0_tab_hit; logic [6:0] s1_t0_c0_tab_rel;
    assign s1_t0_c0_tab_rel = tw_wi - 7'd0;
    assign s1_t0_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd0) && (tw_wi < 7'd2);
    logic [0:0] s1_t0_c0_tab_col_c, s1_t0_c0_tab_col; logic [0:0] s1_t0_c0_tab_wa_c, s1_t0_c0_tab_wa;
    assign s1_t0_c0_tab_col_c = '0; assign s1_t0_c0_tab_wa_c = s1_t0_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s1_t0_c0_tab_hit <= s1_t0_c0_tab_hit_c; s1_t0_c0_tab_col <= s1_t0_c0_tab_col_c; s1_t0_c0_tab_wa <= s1_t0_c0_tab_wa_c; end
    logic s1_t0_c0_tab_hit_q; logic [0:0] s1_t0_c0_tab_col_q; logic [0:0] s1_t0_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s1_t0_c0_tab_wd_q;
    always_ff @(posedge clk) begin s1_t0_c0_tab_hit_q <= s1_t0_c0_tab_hit; s1_t0_c0_tab_col_q <= s1_t0_c0_tab_col; s1_t0_c0_tab_wa_q <= s1_t0_c0_tab_wa; s1_t0_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab0 s1_t0_c0_tab (.clk(clk), .addr({mx_4}), .we(s1_t0_c0_tab_hit_q), .wa(s1_t0_c0_tab_wa_q), .wcol(s1_t0_c0_tab_col_q), .wd(s1_t0_c0_tab_wd_q), .q0(s1_t0_c0_w));
    logic [59:0] s1_k1_xr; logic [59:0] s1_k1_yr;
    MS_N16_q60_P32_tpm_p3_core_s1_bu s1_k1 (.clk(clk), .aIn(s0_o1), .bIn(s0_o3), .W(s1_t0_c0_w), .QH(s1q_QH), .aOut(s1_k1_xr), .bOut(s1_k1_yr));
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
    MS_N16_q60_P32_tpm_p3_core_s1_c0 s1_k2 (.clk(clk), .aIn(s0_o4), .bIn(s0_o6), .QH(s1q_QH), .aOut(s1_k2_xr), .bOut(s1_k2_yr));
    logic [59:0] s1_o4;
    logic [59:0] s1_o4_h_x, s1_o4_h;
    assign s1_o4_h_x = s1_k2_xr;
    always_ff @(posedge clk) s1_o4_h <= mx_9[0] ? (60'(s1_o4_h_x >> 1) + (s1_o4_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o4_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s1_o4_bal (.clk(clk), .din(s1_o4_h), .dout(s1_o4));
    logic [59:0] s1_o6;
    logic [59:0] s1_o6_h_x, s1_o6_h;
    assign s1_o6_h_x = s1_k2_yr;
    always_ff @(posedge clk) s1_o6_h <= mx_9[0] ? (60'(s1_o6_h_x >> 1) + (s1_o6_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o6_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s1_o6_bal (.clk(clk), .din(s1_o6_h), .dout(s1_o6));
    logic [59:0] s1_k3_xr; logic [59:0] s1_k3_yr;
    MS_N16_q60_P32_tpm_p3_core_s1_bu s1_k3 (.clk(clk), .aIn(s0_o5), .bIn(s0_o7), .W(s1_t0_c0_w), .QH(s1q_QH), .aOut(s1_k3_xr), .bOut(s1_k3_yr));
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
    MS_N16_q60_P32_tpm_p3_core_s1_c0 s1_k4 (.clk(clk), .aIn(s0_o8), .bIn(s0_o10), .QH(s1q_QH), .aOut(s1_k4_xr), .bOut(s1_k4_yr));
    logic [59:0] s1_o8;
    logic [59:0] s1_o8_h_x, s1_o8_h;
    assign s1_o8_h_x = s1_k4_xr;
    always_ff @(posedge clk) s1_o8_h <= mx_9[0] ? (60'(s1_o8_h_x >> 1) + (s1_o8_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o8_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s1_o8_bal (.clk(clk), .din(s1_o8_h), .dout(s1_o8));
    logic [59:0] s1_o10;
    logic [59:0] s1_o10_h_x, s1_o10_h;
    assign s1_o10_h_x = s1_k4_yr;
    always_ff @(posedge clk) s1_o10_h <= mx_9[0] ? (60'(s1_o10_h_x >> 1) + (s1_o10_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o10_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s1_o10_bal (.clk(clk), .din(s1_o10_h), .dout(s1_o10));
    logic [59:0] s1_k5_xr; logic [59:0] s1_k5_yr;
    MS_N16_q60_P32_tpm_p3_core_s1_bu s1_k5 (.clk(clk), .aIn(s0_o9), .bIn(s0_o11), .W(s1_t0_c0_w), .QH(s1q_QH), .aOut(s1_k5_xr), .bOut(s1_k5_yr));
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
    MS_N16_q60_P32_tpm_p3_core_s1_c0 s1_k6 (.clk(clk), .aIn(s0_o12), .bIn(s0_o14), .QH(s1q_QH), .aOut(s1_k6_xr), .bOut(s1_k6_yr));
    logic [59:0] s1_o12;
    logic [59:0] s1_o12_h_x, s1_o12_h;
    assign s1_o12_h_x = s1_k6_xr;
    always_ff @(posedge clk) s1_o12_h <= mx_9[0] ? (60'(s1_o12_h_x >> 1) + (s1_o12_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o12_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s1_o12_bal (.clk(clk), .din(s1_o12_h), .dout(s1_o12));
    logic [59:0] s1_o14;
    logic [59:0] s1_o14_h_x, s1_o14_h;
    assign s1_o14_h_x = s1_k6_yr;
    always_ff @(posedge clk) s1_o14_h <= mx_9[0] ? (60'(s1_o14_h_x >> 1) + (s1_o14_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o14_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s1_o14_bal (.clk(clk), .din(s1_o14_h), .dout(s1_o14));
    logic [59:0] s1_k7_xr; logic [59:0] s1_k7_yr;
    MS_N16_q60_P32_tpm_p3_core_s1_bu s1_k7 (.clk(clk), .aIn(s0_o13), .bIn(s0_o15), .W(s1_t0_c0_w), .QH(s1q_QH), .aOut(s1_k7_xr), .bOut(s1_k7_yr));
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
    logic [59:0] s1_k8_xr; logic [59:0] s1_k8_yr;
    MS_N16_q60_P32_tpm_p3_core_s1_c0 s1_k8 (.clk(clk), .aIn(s0_o16), .bIn(s0_o18), .QH(s1q_QH), .aOut(s1_k8_xr), .bOut(s1_k8_yr));
    logic [59:0] s1_o16;
    logic [59:0] s1_o16_h_x, s1_o16_h;
    assign s1_o16_h_x = s1_k8_xr;
    always_ff @(posedge clk) s1_o16_h <= mx_9[0] ? (60'(s1_o16_h_x >> 1) + (s1_o16_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o16_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s1_o16_bal (.clk(clk), .din(s1_o16_h), .dout(s1_o16));
    logic [59:0] s1_o18;
    logic [59:0] s1_o18_h_x, s1_o18_h;
    assign s1_o18_h_x = s1_k8_yr;
    always_ff @(posedge clk) s1_o18_h <= mx_9[0] ? (60'(s1_o18_h_x >> 1) + (s1_o18_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o18_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s1_o18_bal (.clk(clk), .din(s1_o18_h), .dout(s1_o18));
    logic [59:0] s1_t0_c1_w;
    logic s1_t0_c1_tab_hit_c, s1_t0_c1_tab_hit; logic [6:0] s1_t0_c1_tab_rel;
    assign s1_t0_c1_tab_rel = tw_wi - 7'd0;
    assign s1_t0_c1_tab_hit_c = tw_wen_p && (tw_wi >= 7'd0) && (tw_wi < 7'd2);
    logic [0:0] s1_t0_c1_tab_col_c, s1_t0_c1_tab_col; logic [0:0] s1_t0_c1_tab_wa_c, s1_t0_c1_tab_wa;
    assign s1_t0_c1_tab_col_c = '0; assign s1_t0_c1_tab_wa_c = s1_t0_c1_tab_rel[0:0];
    always_ff @(posedge clk) begin s1_t0_c1_tab_hit <= s1_t0_c1_tab_hit_c; s1_t0_c1_tab_col <= s1_t0_c1_tab_col_c; s1_t0_c1_tab_wa <= s1_t0_c1_tab_wa_c; end
    logic s1_t0_c1_tab_hit_q; logic [0:0] s1_t0_c1_tab_col_q; logic [0:0] s1_t0_c1_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s1_t0_c1_tab_wd_q;
    always_ff @(posedge clk) begin s1_t0_c1_tab_hit_q <= s1_t0_c1_tab_hit; s1_t0_c1_tab_col_q <= s1_t0_c1_tab_col; s1_t0_c1_tab_wa_q <= s1_t0_c1_tab_wa; s1_t0_c1_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab0 s1_t0_c1_tab (.clk(clk), .addr({mx_4}), .we(s1_t0_c1_tab_hit_q), .wa(s1_t0_c1_tab_wa_q), .wcol(s1_t0_c1_tab_col_q), .wd(s1_t0_c1_tab_wd_q), .q0(s1_t0_c1_w));
    logic [59:0] s1_k9_xr; logic [59:0] s1_k9_yr;
    MS_N16_q60_P32_tpm_p3_core_s1_bu s1_k9 (.clk(clk), .aIn(s0_o17), .bIn(s0_o19), .W(s1_t0_c1_w), .QH(s1q_QH), .aOut(s1_k9_xr), .bOut(s1_k9_yr));
    logic [59:0] s1_o17;
    logic [59:0] s1_o17_h_x, s1_o17_h;
    assign s1_o17_h_x = s1_k9_xr;
    always_ff @(posedge clk) s1_o17_h <= mx_20[0] ? (60'(s1_o17_h_x >> 1) + (s1_o17_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o17_h_x;
    assign s1_o17 = s1_o17_h;
    logic [59:0] s1_o19;
    logic [59:0] s1_o19_h_x, s1_o19_h;
    assign s1_o19_h_x = s1_k9_yr;
    always_ff @(posedge clk) s1_o19_h <= mx_20[0] ? (60'(s1_o19_h_x >> 1) + (s1_o19_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o19_h_x;
    assign s1_o19 = s1_o19_h;
    logic [59:0] s1_k10_xr; logic [59:0] s1_k10_yr;
    MS_N16_q60_P32_tpm_p3_core_s1_c0 s1_k10 (.clk(clk), .aIn(s0_o20), .bIn(s0_o22), .QH(s1q_QH), .aOut(s1_k10_xr), .bOut(s1_k10_yr));
    logic [59:0] s1_o20;
    logic [59:0] s1_o20_h_x, s1_o20_h;
    assign s1_o20_h_x = s1_k10_xr;
    always_ff @(posedge clk) s1_o20_h <= mx_9[0] ? (60'(s1_o20_h_x >> 1) + (s1_o20_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o20_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s1_o20_bal (.clk(clk), .din(s1_o20_h), .dout(s1_o20));
    logic [59:0] s1_o22;
    logic [59:0] s1_o22_h_x, s1_o22_h;
    assign s1_o22_h_x = s1_k10_yr;
    always_ff @(posedge clk) s1_o22_h <= mx_9[0] ? (60'(s1_o22_h_x >> 1) + (s1_o22_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o22_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s1_o22_bal (.clk(clk), .din(s1_o22_h), .dout(s1_o22));
    logic [59:0] s1_k11_xr; logic [59:0] s1_k11_yr;
    MS_N16_q60_P32_tpm_p3_core_s1_bu s1_k11 (.clk(clk), .aIn(s0_o21), .bIn(s0_o23), .W(s1_t0_c1_w), .QH(s1q_QH), .aOut(s1_k11_xr), .bOut(s1_k11_yr));
    logic [59:0] s1_o21;
    logic [59:0] s1_o21_h_x, s1_o21_h;
    assign s1_o21_h_x = s1_k11_xr;
    always_ff @(posedge clk) s1_o21_h <= mx_20[0] ? (60'(s1_o21_h_x >> 1) + (s1_o21_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o21_h_x;
    assign s1_o21 = s1_o21_h;
    logic [59:0] s1_o23;
    logic [59:0] s1_o23_h_x, s1_o23_h;
    assign s1_o23_h_x = s1_k11_yr;
    always_ff @(posedge clk) s1_o23_h <= mx_20[0] ? (60'(s1_o23_h_x >> 1) + (s1_o23_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o23_h_x;
    assign s1_o23 = s1_o23_h;
    logic [59:0] s1_k12_xr; logic [59:0] s1_k12_yr;
    MS_N16_q60_P32_tpm_p3_core_s1_c0 s1_k12 (.clk(clk), .aIn(s0_o24), .bIn(s0_o26), .QH(s1q_QH), .aOut(s1_k12_xr), .bOut(s1_k12_yr));
    logic [59:0] s1_o24;
    logic [59:0] s1_o24_h_x, s1_o24_h;
    assign s1_o24_h_x = s1_k12_xr;
    always_ff @(posedge clk) s1_o24_h <= mx_9[0] ? (60'(s1_o24_h_x >> 1) + (s1_o24_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o24_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s1_o24_bal (.clk(clk), .din(s1_o24_h), .dout(s1_o24));
    logic [59:0] s1_o26;
    logic [59:0] s1_o26_h_x, s1_o26_h;
    assign s1_o26_h_x = s1_k12_yr;
    always_ff @(posedge clk) s1_o26_h <= mx_9[0] ? (60'(s1_o26_h_x >> 1) + (s1_o26_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o26_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s1_o26_bal (.clk(clk), .din(s1_o26_h), .dout(s1_o26));
    logic [59:0] s1_k13_xr; logic [59:0] s1_k13_yr;
    MS_N16_q60_P32_tpm_p3_core_s1_bu s1_k13 (.clk(clk), .aIn(s0_o25), .bIn(s0_o27), .W(s1_t0_c1_w), .QH(s1q_QH), .aOut(s1_k13_xr), .bOut(s1_k13_yr));
    logic [59:0] s1_o25;
    logic [59:0] s1_o25_h_x, s1_o25_h;
    assign s1_o25_h_x = s1_k13_xr;
    always_ff @(posedge clk) s1_o25_h <= mx_20[0] ? (60'(s1_o25_h_x >> 1) + (s1_o25_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o25_h_x;
    assign s1_o25 = s1_o25_h;
    logic [59:0] s1_o27;
    logic [59:0] s1_o27_h_x, s1_o27_h;
    assign s1_o27_h_x = s1_k13_yr;
    always_ff @(posedge clk) s1_o27_h <= mx_20[0] ? (60'(s1_o27_h_x >> 1) + (s1_o27_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o27_h_x;
    assign s1_o27 = s1_o27_h;
    logic [59:0] s1_k14_xr; logic [59:0] s1_k14_yr;
    MS_N16_q60_P32_tpm_p3_core_s1_c0 s1_k14 (.clk(clk), .aIn(s0_o28), .bIn(s0_o30), .QH(s1q_QH), .aOut(s1_k14_xr), .bOut(s1_k14_yr));
    logic [59:0] s1_o28;
    logic [59:0] s1_o28_h_x, s1_o28_h;
    assign s1_o28_h_x = s1_k14_xr;
    always_ff @(posedge clk) s1_o28_h <= mx_9[0] ? (60'(s1_o28_h_x >> 1) + (s1_o28_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o28_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s1_o28_bal (.clk(clk), .din(s1_o28_h), .dout(s1_o28));
    logic [59:0] s1_o30;
    logic [59:0] s1_o30_h_x, s1_o30_h;
    assign s1_o30_h_x = s1_k14_yr;
    always_ff @(posedge clk) s1_o30_h <= mx_9[0] ? (60'(s1_o30_h_x >> 1) + (s1_o30_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o30_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s1_o30_bal (.clk(clk), .din(s1_o30_h), .dout(s1_o30));
    logic [59:0] s1_k15_xr; logic [59:0] s1_k15_yr;
    MS_N16_q60_P32_tpm_p3_core_s1_bu s1_k15 (.clk(clk), .aIn(s0_o29), .bIn(s0_o31), .W(s1_t0_c1_w), .QH(s1q_QH), .aOut(s1_k15_xr), .bOut(s1_k15_yr));
    logic [59:0] s1_o29;
    logic [59:0] s1_o29_h_x, s1_o29_h;
    assign s1_o29_h_x = s1_k15_xr;
    always_ff @(posedge clk) s1_o29_h <= mx_20[0] ? (60'(s1_o29_h_x >> 1) + (s1_o29_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o29_h_x;
    assign s1_o29 = s1_o29_h;
    logic [59:0] s1_o31;
    logic [59:0] s1_o31_h_x, s1_o31_h;
    assign s1_o31_h_x = s1_k15_yr;
    always_ff @(posedge clk) s1_o31_h <= mx_20[0] ? (60'(s1_o31_h_x >> 1) + (s1_o31_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o31_h_x;
    assign s1_o31 = s1_o31_h;
    // stage 2: 16 butterflies on lane pairs (bit 2), latency 14
    (* max_fanout = 16 *) logic [16:0] s2q_QH;
    always_ff @(posedge clk) s2q_QH <= QH_r;
    logic [59:0] s2_k0_xr; logic [59:0] s2_k0_yr;
    MS_N16_q60_P32_tpm_p3_core_s2_c0 s2_k0 (.clk(clk), .aIn(s1_o0), .bIn(s1_o4), .QH(s2q_QH), .aOut(s2_k0_xr), .bOut(s2_k0_yr));
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
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s2_o0_bal (.clk(clk), .din(s2_o0_h), .dout(s2_o0));
    logic [59:0] s2_o4;
    logic [59:0] s2_o4_h_x, s2_o4_h;
    assign s2_o4_h_x = s2_k0_yr;
    always_ff @(posedge clk) s2_o4_h <= mx_24[0] ? (60'(s2_o4_h_x >> 1) + (s2_o4_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o4_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s2_o4_bal (.clk(clk), .din(s2_o4_h), .dout(s2_o4));
    logic [59:0] s2_t1_c0_w;
    logic s2_t1_c0_tab_hit_c, s2_t1_c0_tab_hit; logic [6:0] s2_t1_c0_tab_rel;
    assign s2_t1_c0_tab_rel = tw_wi - 7'd2;
    assign s2_t1_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd2) && (tw_wi < 7'd4);
    logic [0:0] s2_t1_c0_tab_col_c, s2_t1_c0_tab_col; logic [0:0] s2_t1_c0_tab_wa_c, s2_t1_c0_tab_wa;
    assign s2_t1_c0_tab_col_c = '0; assign s2_t1_c0_tab_wa_c = s2_t1_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s2_t1_c0_tab_hit <= s2_t1_c0_tab_hit_c; s2_t1_c0_tab_col <= s2_t1_c0_tab_col_c; s2_t1_c0_tab_wa <= s2_t1_c0_tab_wa_c; end
    logic s2_t1_c0_tab_hit_q; logic [0:0] s2_t1_c0_tab_col_q; logic [0:0] s2_t1_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s2_t1_c0_tab_wd_q;
    always_ff @(posedge clk) begin s2_t1_c0_tab_hit_q <= s2_t1_c0_tab_hit; s2_t1_c0_tab_col_q <= s2_t1_c0_tab_col; s2_t1_c0_tab_wa_q <= s2_t1_c0_tab_wa; s2_t1_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab1 s2_t1_c0_tab (.clk(clk), .addr({mx_19}), .we(s2_t1_c0_tab_hit_q), .wa(s2_t1_c0_tab_wa_q), .wcol(s2_t1_c0_tab_col_q), .wd(s2_t1_c0_tab_wd_q), .q0(s2_t1_c0_w));
    logic [59:0] s2_k1_xr; logic [59:0] s2_k1_yr;
    MS_N16_q60_P32_tpm_p3_core_s2_bu s2_k1 (.clk(clk), .aIn(s1_o1), .bIn(s1_o5), .W(s2_t1_c0_w), .QH(s2q_QH), .aOut(s2_k1_xr), .bOut(s2_k1_yr));
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
    logic s2_t0_c0_tab_hit_c, s2_t0_c0_tab_hit; logic [6:0] s2_t0_c0_tab_rel;
    assign s2_t0_c0_tab_rel = tw_wi - 7'd0;
    assign s2_t0_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd0) && (tw_wi < 7'd2);
    logic [0:0] s2_t0_c0_tab_col_c, s2_t0_c0_tab_col; logic [0:0] s2_t0_c0_tab_wa_c, s2_t0_c0_tab_wa;
    assign s2_t0_c0_tab_col_c = '0; assign s2_t0_c0_tab_wa_c = s2_t0_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s2_t0_c0_tab_hit <= s2_t0_c0_tab_hit_c; s2_t0_c0_tab_col <= s2_t0_c0_tab_col_c; s2_t0_c0_tab_wa <= s2_t0_c0_tab_wa_c; end
    logic s2_t0_c0_tab_hit_q; logic [0:0] s2_t0_c0_tab_col_q; logic [0:0] s2_t0_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s2_t0_c0_tab_wd_q;
    always_ff @(posedge clk) begin s2_t0_c0_tab_hit_q <= s2_t0_c0_tab_hit; s2_t0_c0_tab_col_q <= s2_t0_c0_tab_col; s2_t0_c0_tab_wa_q <= s2_t0_c0_tab_wa; s2_t0_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab0 s2_t0_c0_tab (.clk(clk), .addr({mx_19}), .we(s2_t0_c0_tab_hit_q), .wa(s2_t0_c0_tab_wa_q), .wcol(s2_t0_c0_tab_col_q), .wd(s2_t0_c0_tab_wd_q), .q0(s2_t0_c0_w));
    logic [59:0] s2_k2_xr; logic [59:0] s2_k2_yr;
    MS_N16_q60_P32_tpm_p3_core_s2_bu s2_k2 (.clk(clk), .aIn(s1_o2), .bIn(s1_o6), .W(s2_t0_c0_w), .QH(s2q_QH), .aOut(s2_k2_xr), .bOut(s2_k2_yr));
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
    logic s2_t2_c0_tab_hit_c, s2_t2_c0_tab_hit; logic [6:0] s2_t2_c0_tab_rel;
    assign s2_t2_c0_tab_rel = tw_wi - 7'd4;
    assign s2_t2_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd4) && (tw_wi < 7'd6);
    logic [0:0] s2_t2_c0_tab_col_c, s2_t2_c0_tab_col; logic [0:0] s2_t2_c0_tab_wa_c, s2_t2_c0_tab_wa;
    assign s2_t2_c0_tab_col_c = '0; assign s2_t2_c0_tab_wa_c = s2_t2_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s2_t2_c0_tab_hit <= s2_t2_c0_tab_hit_c; s2_t2_c0_tab_col <= s2_t2_c0_tab_col_c; s2_t2_c0_tab_wa <= s2_t2_c0_tab_wa_c; end
    logic s2_t2_c0_tab_hit_q; logic [0:0] s2_t2_c0_tab_col_q; logic [0:0] s2_t2_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s2_t2_c0_tab_wd_q;
    always_ff @(posedge clk) begin s2_t2_c0_tab_hit_q <= s2_t2_c0_tab_hit; s2_t2_c0_tab_col_q <= s2_t2_c0_tab_col; s2_t2_c0_tab_wa_q <= s2_t2_c0_tab_wa; s2_t2_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab2 s2_t2_c0_tab (.clk(clk), .addr({mx_19}), .we(s2_t2_c0_tab_hit_q), .wa(s2_t2_c0_tab_wa_q), .wcol(s2_t2_c0_tab_col_q), .wd(s2_t2_c0_tab_wd_q), .q0(s2_t2_c0_w));
    logic [59:0] s2_k3_xr; logic [59:0] s2_k3_yr;
    MS_N16_q60_P32_tpm_p3_core_s2_bu s2_k3 (.clk(clk), .aIn(s1_o3), .bIn(s1_o7), .W(s2_t2_c0_w), .QH(s2q_QH), .aOut(s2_k3_xr), .bOut(s2_k3_yr));
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
    MS_N16_q60_P32_tpm_p3_core_s2_c0 s2_k4 (.clk(clk), .aIn(s1_o8), .bIn(s1_o12), .QH(s2q_QH), .aOut(s2_k4_xr), .bOut(s2_k4_yr));
    logic [59:0] s2_o8;
    logic [59:0] s2_o8_h_x, s2_o8_h;
    assign s2_o8_h_x = s2_k4_xr;
    always_ff @(posedge clk) s2_o8_h <= mx_24[0] ? (60'(s2_o8_h_x >> 1) + (s2_o8_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o8_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s2_o8_bal (.clk(clk), .din(s2_o8_h), .dout(s2_o8));
    logic [59:0] s2_o12;
    logic [59:0] s2_o12_h_x, s2_o12_h;
    assign s2_o12_h_x = s2_k4_yr;
    always_ff @(posedge clk) s2_o12_h <= mx_24[0] ? (60'(s2_o12_h_x >> 1) + (s2_o12_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o12_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s2_o12_bal (.clk(clk), .din(s2_o12_h), .dout(s2_o12));
    logic [59:0] s2_k5_xr; logic [59:0] s2_k5_yr;
    MS_N16_q60_P32_tpm_p3_core_s2_bu s2_k5 (.clk(clk), .aIn(s1_o9), .bIn(s1_o13), .W(s2_t1_c0_w), .QH(s2q_QH), .aOut(s2_k5_xr), .bOut(s2_k5_yr));
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
    MS_N16_q60_P32_tpm_p3_core_s2_bu s2_k6 (.clk(clk), .aIn(s1_o10), .bIn(s1_o14), .W(s2_t0_c0_w), .QH(s2q_QH), .aOut(s2_k6_xr), .bOut(s2_k6_yr));
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
    MS_N16_q60_P32_tpm_p3_core_s2_bu s2_k7 (.clk(clk), .aIn(s1_o11), .bIn(s1_o15), .W(s2_t2_c0_w), .QH(s2q_QH), .aOut(s2_k7_xr), .bOut(s2_k7_yr));
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
    logic [59:0] s2_k8_xr; logic [59:0] s2_k8_yr;
    MS_N16_q60_P32_tpm_p3_core_s2_c0 s2_k8 (.clk(clk), .aIn(s1_o16), .bIn(s1_o20), .QH(s2q_QH), .aOut(s2_k8_xr), .bOut(s2_k8_yr));
    logic [59:0] s2_o16;
    logic [59:0] s2_o16_h_x, s2_o16_h;
    assign s2_o16_h_x = s2_k8_xr;
    always_ff @(posedge clk) s2_o16_h <= mx_24[0] ? (60'(s2_o16_h_x >> 1) + (s2_o16_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o16_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s2_o16_bal (.clk(clk), .din(s2_o16_h), .dout(s2_o16));
    logic [59:0] s2_o20;
    logic [59:0] s2_o20_h_x, s2_o20_h;
    assign s2_o20_h_x = s2_k8_yr;
    always_ff @(posedge clk) s2_o20_h <= mx_24[0] ? (60'(s2_o20_h_x >> 1) + (s2_o20_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o20_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s2_o20_bal (.clk(clk), .din(s2_o20_h), .dout(s2_o20));
    logic [59:0] s2_k9_xr; logic [59:0] s2_k9_yr;
    MS_N16_q60_P32_tpm_p3_core_s2_bu s2_k9 (.clk(clk), .aIn(s1_o17), .bIn(s1_o21), .W(s2_t1_c0_w), .QH(s2q_QH), .aOut(s2_k9_xr), .bOut(s2_k9_yr));
    logic [59:0] s2_o17;
    logic [59:0] s2_o17_h_x, s2_o17_h;
    assign s2_o17_h_x = s2_k9_xr;
    always_ff @(posedge clk) s2_o17_h <= mx_35[0] ? (60'(s2_o17_h_x >> 1) + (s2_o17_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o17_h_x;
    assign s2_o17 = s2_o17_h;
    logic [59:0] s2_o21;
    logic [59:0] s2_o21_h_x, s2_o21_h;
    assign s2_o21_h_x = s2_k9_yr;
    always_ff @(posedge clk) s2_o21_h <= mx_35[0] ? (60'(s2_o21_h_x >> 1) + (s2_o21_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o21_h_x;
    assign s2_o21 = s2_o21_h;
    logic [59:0] s2_k10_xr; logic [59:0] s2_k10_yr;
    MS_N16_q60_P32_tpm_p3_core_s2_bu s2_k10 (.clk(clk), .aIn(s1_o18), .bIn(s1_o22), .W(s2_t0_c0_w), .QH(s2q_QH), .aOut(s2_k10_xr), .bOut(s2_k10_yr));
    logic [59:0] s2_o18;
    logic [59:0] s2_o18_h_x, s2_o18_h;
    assign s2_o18_h_x = s2_k10_xr;
    always_ff @(posedge clk) s2_o18_h <= mx_35[0] ? (60'(s2_o18_h_x >> 1) + (s2_o18_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o18_h_x;
    assign s2_o18 = s2_o18_h;
    logic [59:0] s2_o22;
    logic [59:0] s2_o22_h_x, s2_o22_h;
    assign s2_o22_h_x = s2_k10_yr;
    always_ff @(posedge clk) s2_o22_h <= mx_35[0] ? (60'(s2_o22_h_x >> 1) + (s2_o22_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o22_h_x;
    assign s2_o22 = s2_o22_h;
    logic [59:0] s2_k11_xr; logic [59:0] s2_k11_yr;
    MS_N16_q60_P32_tpm_p3_core_s2_bu s2_k11 (.clk(clk), .aIn(s1_o19), .bIn(s1_o23), .W(s2_t2_c0_w), .QH(s2q_QH), .aOut(s2_k11_xr), .bOut(s2_k11_yr));
    logic [59:0] s2_o19;
    logic [59:0] s2_o19_h_x, s2_o19_h;
    assign s2_o19_h_x = s2_k11_xr;
    always_ff @(posedge clk) s2_o19_h <= mx_35[0] ? (60'(s2_o19_h_x >> 1) + (s2_o19_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o19_h_x;
    assign s2_o19 = s2_o19_h;
    logic [59:0] s2_o23;
    logic [59:0] s2_o23_h_x, s2_o23_h;
    assign s2_o23_h_x = s2_k11_yr;
    always_ff @(posedge clk) s2_o23_h <= mx_35[0] ? (60'(s2_o23_h_x >> 1) + (s2_o23_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o23_h_x;
    assign s2_o23 = s2_o23_h;
    logic [59:0] s2_k12_xr; logic [59:0] s2_k12_yr;
    MS_N16_q60_P32_tpm_p3_core_s2_c0 s2_k12 (.clk(clk), .aIn(s1_o24), .bIn(s1_o28), .QH(s2q_QH), .aOut(s2_k12_xr), .bOut(s2_k12_yr));
    logic [59:0] s2_o24;
    logic [59:0] s2_o24_h_x, s2_o24_h;
    assign s2_o24_h_x = s2_k12_xr;
    always_ff @(posedge clk) s2_o24_h <= mx_24[0] ? (60'(s2_o24_h_x >> 1) + (s2_o24_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o24_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s2_o24_bal (.clk(clk), .din(s2_o24_h), .dout(s2_o24));
    logic [59:0] s2_o28;
    logic [59:0] s2_o28_h_x, s2_o28_h;
    assign s2_o28_h_x = s2_k12_yr;
    always_ff @(posedge clk) s2_o28_h <= mx_24[0] ? (60'(s2_o28_h_x >> 1) + (s2_o28_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o28_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s2_o28_bal (.clk(clk), .din(s2_o28_h), .dout(s2_o28));
    logic [59:0] s2_k13_xr; logic [59:0] s2_k13_yr;
    MS_N16_q60_P32_tpm_p3_core_s2_bu s2_k13 (.clk(clk), .aIn(s1_o25), .bIn(s1_o29), .W(s2_t1_c0_w), .QH(s2q_QH), .aOut(s2_k13_xr), .bOut(s2_k13_yr));
    logic [59:0] s2_o25;
    logic [59:0] s2_o25_h_x, s2_o25_h;
    assign s2_o25_h_x = s2_k13_xr;
    always_ff @(posedge clk) s2_o25_h <= mx_35[0] ? (60'(s2_o25_h_x >> 1) + (s2_o25_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o25_h_x;
    assign s2_o25 = s2_o25_h;
    logic [59:0] s2_o29;
    logic [59:0] s2_o29_h_x, s2_o29_h;
    assign s2_o29_h_x = s2_k13_yr;
    always_ff @(posedge clk) s2_o29_h <= mx_35[0] ? (60'(s2_o29_h_x >> 1) + (s2_o29_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o29_h_x;
    assign s2_o29 = s2_o29_h;
    logic [59:0] s2_k14_xr; logic [59:0] s2_k14_yr;
    MS_N16_q60_P32_tpm_p3_core_s2_bu s2_k14 (.clk(clk), .aIn(s1_o26), .bIn(s1_o30), .W(s2_t0_c0_w), .QH(s2q_QH), .aOut(s2_k14_xr), .bOut(s2_k14_yr));
    logic [59:0] s2_o26;
    logic [59:0] s2_o26_h_x, s2_o26_h;
    assign s2_o26_h_x = s2_k14_xr;
    always_ff @(posedge clk) s2_o26_h <= mx_35[0] ? (60'(s2_o26_h_x >> 1) + (s2_o26_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o26_h_x;
    assign s2_o26 = s2_o26_h;
    logic [59:0] s2_o30;
    logic [59:0] s2_o30_h_x, s2_o30_h;
    assign s2_o30_h_x = s2_k14_yr;
    always_ff @(posedge clk) s2_o30_h <= mx_35[0] ? (60'(s2_o30_h_x >> 1) + (s2_o30_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o30_h_x;
    assign s2_o30 = s2_o30_h;
    logic [59:0] s2_k15_xr; logic [59:0] s2_k15_yr;
    MS_N16_q60_P32_tpm_p3_core_s2_bu s2_k15 (.clk(clk), .aIn(s1_o27), .bIn(s1_o31), .W(s2_t2_c0_w), .QH(s2q_QH), .aOut(s2_k15_xr), .bOut(s2_k15_yr));
    logic [59:0] s2_o27;
    logic [59:0] s2_o27_h_x, s2_o27_h;
    assign s2_o27_h_x = s2_k15_xr;
    always_ff @(posedge clk) s2_o27_h <= mx_35[0] ? (60'(s2_o27_h_x >> 1) + (s2_o27_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o27_h_x;
    assign s2_o27 = s2_o27_h;
    logic [59:0] s2_o31;
    logic [59:0] s2_o31_h_x, s2_o31_h;
    assign s2_o31_h_x = s2_k15_yr;
    always_ff @(posedge clk) s2_o31_h <= mx_35[0] ? (60'(s2_o31_h_x >> 1) + (s2_o31_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o31_h_x;
    assign s2_o31 = s2_o31_h;
    // stage 3: 16 butterflies on lane pairs (bit 3), latency 14
    (* max_fanout = 16 *) logic [16:0] s3q_QH;
    always_ff @(posedge clk) s3q_QH <= QH_r;
    logic [59:0] s3_k0_xr; logic [59:0] s3_k0_yr;
    MS_N16_q60_P32_tpm_p3_core_s3_c0 s3_k0 (.clk(clk), .aIn(s2_o0), .bIn(s2_o8), .QH(s3q_QH), .aOut(s3_k0_xr), .bOut(s3_k0_yr));
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
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s3_o0_bal (.clk(clk), .din(s3_o0_h), .dout(s3_o0));
    logic [59:0] s3_o8;
    logic [59:0] s3_o8_h_x, s3_o8_h;
    assign s3_o8_h_x = s3_k0_yr;
    always_ff @(posedge clk) s3_o8_h <= mx_39[0] ? (60'(s3_o8_h_x >> 1) + (s3_o8_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o8_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s3_o8_bal (.clk(clk), .din(s3_o8_h), .dout(s3_o8));
    logic [59:0] s3_t3_c0_w;
    logic s3_t3_c0_tab_hit_c, s3_t3_c0_tab_hit; logic [6:0] s3_t3_c0_tab_rel;
    assign s3_t3_c0_tab_rel = tw_wi - 7'd6;
    assign s3_t3_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd6) && (tw_wi < 7'd8);
    logic [0:0] s3_t3_c0_tab_col_c, s3_t3_c0_tab_col; logic [0:0] s3_t3_c0_tab_wa_c, s3_t3_c0_tab_wa;
    assign s3_t3_c0_tab_col_c = '0; assign s3_t3_c0_tab_wa_c = s3_t3_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s3_t3_c0_tab_hit <= s3_t3_c0_tab_hit_c; s3_t3_c0_tab_col <= s3_t3_c0_tab_col_c; s3_t3_c0_tab_wa <= s3_t3_c0_tab_wa_c; end
    logic s3_t3_c0_tab_hit_q; logic [0:0] s3_t3_c0_tab_col_q; logic [0:0] s3_t3_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s3_t3_c0_tab_wd_q;
    always_ff @(posedge clk) begin s3_t3_c0_tab_hit_q <= s3_t3_c0_tab_hit; s3_t3_c0_tab_col_q <= s3_t3_c0_tab_col; s3_t3_c0_tab_wa_q <= s3_t3_c0_tab_wa; s3_t3_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab3 s3_t3_c0_tab (.clk(clk), .addr({mx_34}), .we(s3_t3_c0_tab_hit_q), .wa(s3_t3_c0_tab_wa_q), .wcol(s3_t3_c0_tab_col_q), .wd(s3_t3_c0_tab_wd_q), .q0(s3_t3_c0_w));
    logic [59:0] s3_k1_xr; logic [59:0] s3_k1_yr;
    MS_N16_q60_P32_tpm_p3_core_s3_bu s3_k1 (.clk(clk), .aIn(s2_o1), .bIn(s2_o9), .W(s3_t3_c0_w), .QH(s3q_QH), .aOut(s3_k1_xr), .bOut(s3_k1_yr));
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
    logic s3_t1_c0_tab_hit_c, s3_t1_c0_tab_hit; logic [6:0] s3_t1_c0_tab_rel;
    assign s3_t1_c0_tab_rel = tw_wi - 7'd2;
    assign s3_t1_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd2) && (tw_wi < 7'd4);
    logic [0:0] s3_t1_c0_tab_col_c, s3_t1_c0_tab_col; logic [0:0] s3_t1_c0_tab_wa_c, s3_t1_c0_tab_wa;
    assign s3_t1_c0_tab_col_c = '0; assign s3_t1_c0_tab_wa_c = s3_t1_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s3_t1_c0_tab_hit <= s3_t1_c0_tab_hit_c; s3_t1_c0_tab_col <= s3_t1_c0_tab_col_c; s3_t1_c0_tab_wa <= s3_t1_c0_tab_wa_c; end
    logic s3_t1_c0_tab_hit_q; logic [0:0] s3_t1_c0_tab_col_q; logic [0:0] s3_t1_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s3_t1_c0_tab_wd_q;
    always_ff @(posedge clk) begin s3_t1_c0_tab_hit_q <= s3_t1_c0_tab_hit; s3_t1_c0_tab_col_q <= s3_t1_c0_tab_col; s3_t1_c0_tab_wa_q <= s3_t1_c0_tab_wa; s3_t1_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab1 s3_t1_c0_tab (.clk(clk), .addr({mx_34}), .we(s3_t1_c0_tab_hit_q), .wa(s3_t1_c0_tab_wa_q), .wcol(s3_t1_c0_tab_col_q), .wd(s3_t1_c0_tab_wd_q), .q0(s3_t1_c0_w));
    logic [59:0] s3_k2_xr; logic [59:0] s3_k2_yr;
    MS_N16_q60_P32_tpm_p3_core_s3_bu s3_k2 (.clk(clk), .aIn(s2_o2), .bIn(s2_o10), .W(s3_t1_c0_w), .QH(s3q_QH), .aOut(s3_k2_xr), .bOut(s3_k2_yr));
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
    logic s3_t4_c0_tab_hit_c, s3_t4_c0_tab_hit; logic [6:0] s3_t4_c0_tab_rel;
    assign s3_t4_c0_tab_rel = tw_wi - 7'd8;
    assign s3_t4_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd8) && (tw_wi < 7'd10);
    logic [0:0] s3_t4_c0_tab_col_c, s3_t4_c0_tab_col; logic [0:0] s3_t4_c0_tab_wa_c, s3_t4_c0_tab_wa;
    assign s3_t4_c0_tab_col_c = '0; assign s3_t4_c0_tab_wa_c = s3_t4_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s3_t4_c0_tab_hit <= s3_t4_c0_tab_hit_c; s3_t4_c0_tab_col <= s3_t4_c0_tab_col_c; s3_t4_c0_tab_wa <= s3_t4_c0_tab_wa_c; end
    logic s3_t4_c0_tab_hit_q; logic [0:0] s3_t4_c0_tab_col_q; logic [0:0] s3_t4_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s3_t4_c0_tab_wd_q;
    always_ff @(posedge clk) begin s3_t4_c0_tab_hit_q <= s3_t4_c0_tab_hit; s3_t4_c0_tab_col_q <= s3_t4_c0_tab_col; s3_t4_c0_tab_wa_q <= s3_t4_c0_tab_wa; s3_t4_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab4 s3_t4_c0_tab (.clk(clk), .addr({mx_34}), .we(s3_t4_c0_tab_hit_q), .wa(s3_t4_c0_tab_wa_q), .wcol(s3_t4_c0_tab_col_q), .wd(s3_t4_c0_tab_wd_q), .q0(s3_t4_c0_w));
    logic [59:0] s3_k3_xr; logic [59:0] s3_k3_yr;
    MS_N16_q60_P32_tpm_p3_core_s3_bu s3_k3 (.clk(clk), .aIn(s2_o3), .bIn(s2_o11), .W(s3_t4_c0_w), .QH(s3q_QH), .aOut(s3_k3_xr), .bOut(s3_k3_yr));
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
    logic s3_t0_c0_tab_hit_c, s3_t0_c0_tab_hit; logic [6:0] s3_t0_c0_tab_rel;
    assign s3_t0_c0_tab_rel = tw_wi - 7'd0;
    assign s3_t0_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd0) && (tw_wi < 7'd2);
    logic [0:0] s3_t0_c0_tab_col_c, s3_t0_c0_tab_col; logic [0:0] s3_t0_c0_tab_wa_c, s3_t0_c0_tab_wa;
    assign s3_t0_c0_tab_col_c = '0; assign s3_t0_c0_tab_wa_c = s3_t0_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s3_t0_c0_tab_hit <= s3_t0_c0_tab_hit_c; s3_t0_c0_tab_col <= s3_t0_c0_tab_col_c; s3_t0_c0_tab_wa <= s3_t0_c0_tab_wa_c; end
    logic s3_t0_c0_tab_hit_q; logic [0:0] s3_t0_c0_tab_col_q; logic [0:0] s3_t0_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s3_t0_c0_tab_wd_q;
    always_ff @(posedge clk) begin s3_t0_c0_tab_hit_q <= s3_t0_c0_tab_hit; s3_t0_c0_tab_col_q <= s3_t0_c0_tab_col; s3_t0_c0_tab_wa_q <= s3_t0_c0_tab_wa; s3_t0_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab0 s3_t0_c0_tab (.clk(clk), .addr({mx_34}), .we(s3_t0_c0_tab_hit_q), .wa(s3_t0_c0_tab_wa_q), .wcol(s3_t0_c0_tab_col_q), .wd(s3_t0_c0_tab_wd_q), .q0(s3_t0_c0_w));
    logic [59:0] s3_k4_xr; logic [59:0] s3_k4_yr;
    MS_N16_q60_P32_tpm_p3_core_s3_bu s3_k4 (.clk(clk), .aIn(s2_o4), .bIn(s2_o12), .W(s3_t0_c0_w), .QH(s3q_QH), .aOut(s3_k4_xr), .bOut(s3_k4_yr));
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
    logic s3_t5_c0_tab_hit_c, s3_t5_c0_tab_hit; logic [6:0] s3_t5_c0_tab_rel;
    assign s3_t5_c0_tab_rel = tw_wi - 7'd10;
    assign s3_t5_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd10) && (tw_wi < 7'd12);
    logic [0:0] s3_t5_c0_tab_col_c, s3_t5_c0_tab_col; logic [0:0] s3_t5_c0_tab_wa_c, s3_t5_c0_tab_wa;
    assign s3_t5_c0_tab_col_c = '0; assign s3_t5_c0_tab_wa_c = s3_t5_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s3_t5_c0_tab_hit <= s3_t5_c0_tab_hit_c; s3_t5_c0_tab_col <= s3_t5_c0_tab_col_c; s3_t5_c0_tab_wa <= s3_t5_c0_tab_wa_c; end
    logic s3_t5_c0_tab_hit_q; logic [0:0] s3_t5_c0_tab_col_q; logic [0:0] s3_t5_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s3_t5_c0_tab_wd_q;
    always_ff @(posedge clk) begin s3_t5_c0_tab_hit_q <= s3_t5_c0_tab_hit; s3_t5_c0_tab_col_q <= s3_t5_c0_tab_col; s3_t5_c0_tab_wa_q <= s3_t5_c0_tab_wa; s3_t5_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab5 s3_t5_c0_tab (.clk(clk), .addr({mx_34}), .we(s3_t5_c0_tab_hit_q), .wa(s3_t5_c0_tab_wa_q), .wcol(s3_t5_c0_tab_col_q), .wd(s3_t5_c0_tab_wd_q), .q0(s3_t5_c0_w));
    logic [59:0] s3_k5_xr; logic [59:0] s3_k5_yr;
    MS_N16_q60_P32_tpm_p3_core_s3_bu s3_k5 (.clk(clk), .aIn(s2_o5), .bIn(s2_o13), .W(s3_t5_c0_w), .QH(s3q_QH), .aOut(s3_k5_xr), .bOut(s3_k5_yr));
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
    logic s3_t2_c0_tab_hit_c, s3_t2_c0_tab_hit; logic [6:0] s3_t2_c0_tab_rel;
    assign s3_t2_c0_tab_rel = tw_wi - 7'd4;
    assign s3_t2_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd4) && (tw_wi < 7'd6);
    logic [0:0] s3_t2_c0_tab_col_c, s3_t2_c0_tab_col; logic [0:0] s3_t2_c0_tab_wa_c, s3_t2_c0_tab_wa;
    assign s3_t2_c0_tab_col_c = '0; assign s3_t2_c0_tab_wa_c = s3_t2_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s3_t2_c0_tab_hit <= s3_t2_c0_tab_hit_c; s3_t2_c0_tab_col <= s3_t2_c0_tab_col_c; s3_t2_c0_tab_wa <= s3_t2_c0_tab_wa_c; end
    logic s3_t2_c0_tab_hit_q; logic [0:0] s3_t2_c0_tab_col_q; logic [0:0] s3_t2_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s3_t2_c0_tab_wd_q;
    always_ff @(posedge clk) begin s3_t2_c0_tab_hit_q <= s3_t2_c0_tab_hit; s3_t2_c0_tab_col_q <= s3_t2_c0_tab_col; s3_t2_c0_tab_wa_q <= s3_t2_c0_tab_wa; s3_t2_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab2 s3_t2_c0_tab (.clk(clk), .addr({mx_34}), .we(s3_t2_c0_tab_hit_q), .wa(s3_t2_c0_tab_wa_q), .wcol(s3_t2_c0_tab_col_q), .wd(s3_t2_c0_tab_wd_q), .q0(s3_t2_c0_w));
    logic [59:0] s3_k6_xr; logic [59:0] s3_k6_yr;
    MS_N16_q60_P32_tpm_p3_core_s3_bu s3_k6 (.clk(clk), .aIn(s2_o6), .bIn(s2_o14), .W(s3_t2_c0_w), .QH(s3q_QH), .aOut(s3_k6_xr), .bOut(s3_k6_yr));
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
    logic s3_t6_c0_tab_hit_c, s3_t6_c0_tab_hit; logic [6:0] s3_t6_c0_tab_rel;
    assign s3_t6_c0_tab_rel = tw_wi - 7'd12;
    assign s3_t6_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd12) && (tw_wi < 7'd14);
    logic [0:0] s3_t6_c0_tab_col_c, s3_t6_c0_tab_col; logic [0:0] s3_t6_c0_tab_wa_c, s3_t6_c0_tab_wa;
    assign s3_t6_c0_tab_col_c = '0; assign s3_t6_c0_tab_wa_c = s3_t6_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s3_t6_c0_tab_hit <= s3_t6_c0_tab_hit_c; s3_t6_c0_tab_col <= s3_t6_c0_tab_col_c; s3_t6_c0_tab_wa <= s3_t6_c0_tab_wa_c; end
    logic s3_t6_c0_tab_hit_q; logic [0:0] s3_t6_c0_tab_col_q; logic [0:0] s3_t6_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s3_t6_c0_tab_wd_q;
    always_ff @(posedge clk) begin s3_t6_c0_tab_hit_q <= s3_t6_c0_tab_hit; s3_t6_c0_tab_col_q <= s3_t6_c0_tab_col; s3_t6_c0_tab_wa_q <= s3_t6_c0_tab_wa; s3_t6_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab6 s3_t6_c0_tab (.clk(clk), .addr({mx_34}), .we(s3_t6_c0_tab_hit_q), .wa(s3_t6_c0_tab_wa_q), .wcol(s3_t6_c0_tab_col_q), .wd(s3_t6_c0_tab_wd_q), .q0(s3_t6_c0_w));
    logic [59:0] s3_k7_xr; logic [59:0] s3_k7_yr;
    MS_N16_q60_P32_tpm_p3_core_s3_bu s3_k7 (.clk(clk), .aIn(s2_o7), .bIn(s2_o15), .W(s3_t6_c0_w), .QH(s3q_QH), .aOut(s3_k7_xr), .bOut(s3_k7_yr));
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
    logic [59:0] s3_k8_xr; logic [59:0] s3_k8_yr;
    MS_N16_q60_P32_tpm_p3_core_s3_c0 s3_k8 (.clk(clk), .aIn(s2_o16), .bIn(s2_o24), .QH(s3q_QH), .aOut(s3_k8_xr), .bOut(s3_k8_yr));
    logic [59:0] s3_o16;
    logic [59:0] s3_o16_h_x, s3_o16_h;
    assign s3_o16_h_x = s3_k8_xr;
    always_ff @(posedge clk) s3_o16_h <= mx_39[0] ? (60'(s3_o16_h_x >> 1) + (s3_o16_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o16_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s3_o16_bal (.clk(clk), .din(s3_o16_h), .dout(s3_o16));
    logic [59:0] s3_o24;
    logic [59:0] s3_o24_h_x, s3_o24_h;
    assign s3_o24_h_x = s3_k8_yr;
    always_ff @(posedge clk) s3_o24_h <= mx_39[0] ? (60'(s3_o24_h_x >> 1) + (s3_o24_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o24_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s3_o24_bal (.clk(clk), .din(s3_o24_h), .dout(s3_o24));
    logic [59:0] s3_k9_xr; logic [59:0] s3_k9_yr;
    MS_N16_q60_P32_tpm_p3_core_s3_bu s3_k9 (.clk(clk), .aIn(s2_o17), .bIn(s2_o25), .W(s3_t3_c0_w), .QH(s3q_QH), .aOut(s3_k9_xr), .bOut(s3_k9_yr));
    logic [59:0] s3_o17;
    logic [59:0] s3_o17_h_x, s3_o17_h;
    assign s3_o17_h_x = s3_k9_xr;
    always_ff @(posedge clk) s3_o17_h <= mx_50[0] ? (60'(s3_o17_h_x >> 1) + (s3_o17_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o17_h_x;
    assign s3_o17 = s3_o17_h;
    logic [59:0] s3_o25;
    logic [59:0] s3_o25_h_x, s3_o25_h;
    assign s3_o25_h_x = s3_k9_yr;
    always_ff @(posedge clk) s3_o25_h <= mx_50[0] ? (60'(s3_o25_h_x >> 1) + (s3_o25_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o25_h_x;
    assign s3_o25 = s3_o25_h;
    logic [59:0] s3_k10_xr; logic [59:0] s3_k10_yr;
    MS_N16_q60_P32_tpm_p3_core_s3_bu s3_k10 (.clk(clk), .aIn(s2_o18), .bIn(s2_o26), .W(s3_t1_c0_w), .QH(s3q_QH), .aOut(s3_k10_xr), .bOut(s3_k10_yr));
    logic [59:0] s3_o18;
    logic [59:0] s3_o18_h_x, s3_o18_h;
    assign s3_o18_h_x = s3_k10_xr;
    always_ff @(posedge clk) s3_o18_h <= mx_50[0] ? (60'(s3_o18_h_x >> 1) + (s3_o18_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o18_h_x;
    assign s3_o18 = s3_o18_h;
    logic [59:0] s3_o26;
    logic [59:0] s3_o26_h_x, s3_o26_h;
    assign s3_o26_h_x = s3_k10_yr;
    always_ff @(posedge clk) s3_o26_h <= mx_50[0] ? (60'(s3_o26_h_x >> 1) + (s3_o26_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o26_h_x;
    assign s3_o26 = s3_o26_h;
    logic [59:0] s3_k11_xr; logic [59:0] s3_k11_yr;
    MS_N16_q60_P32_tpm_p3_core_s3_bu s3_k11 (.clk(clk), .aIn(s2_o19), .bIn(s2_o27), .W(s3_t4_c0_w), .QH(s3q_QH), .aOut(s3_k11_xr), .bOut(s3_k11_yr));
    logic [59:0] s3_o19;
    logic [59:0] s3_o19_h_x, s3_o19_h;
    assign s3_o19_h_x = s3_k11_xr;
    always_ff @(posedge clk) s3_o19_h <= mx_50[0] ? (60'(s3_o19_h_x >> 1) + (s3_o19_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o19_h_x;
    assign s3_o19 = s3_o19_h;
    logic [59:0] s3_o27;
    logic [59:0] s3_o27_h_x, s3_o27_h;
    assign s3_o27_h_x = s3_k11_yr;
    always_ff @(posedge clk) s3_o27_h <= mx_50[0] ? (60'(s3_o27_h_x >> 1) + (s3_o27_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o27_h_x;
    assign s3_o27 = s3_o27_h;
    logic [59:0] s3_k12_xr; logic [59:0] s3_k12_yr;
    MS_N16_q60_P32_tpm_p3_core_s3_bu s3_k12 (.clk(clk), .aIn(s2_o20), .bIn(s2_o28), .W(s3_t0_c0_w), .QH(s3q_QH), .aOut(s3_k12_xr), .bOut(s3_k12_yr));
    logic [59:0] s3_o20;
    logic [59:0] s3_o20_h_x, s3_o20_h;
    assign s3_o20_h_x = s3_k12_xr;
    always_ff @(posedge clk) s3_o20_h <= mx_50[0] ? (60'(s3_o20_h_x >> 1) + (s3_o20_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o20_h_x;
    assign s3_o20 = s3_o20_h;
    logic [59:0] s3_o28;
    logic [59:0] s3_o28_h_x, s3_o28_h;
    assign s3_o28_h_x = s3_k12_yr;
    always_ff @(posedge clk) s3_o28_h <= mx_50[0] ? (60'(s3_o28_h_x >> 1) + (s3_o28_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o28_h_x;
    assign s3_o28 = s3_o28_h;
    logic [59:0] s3_k13_xr; logic [59:0] s3_k13_yr;
    MS_N16_q60_P32_tpm_p3_core_s3_bu s3_k13 (.clk(clk), .aIn(s2_o21), .bIn(s2_o29), .W(s3_t5_c0_w), .QH(s3q_QH), .aOut(s3_k13_xr), .bOut(s3_k13_yr));
    logic [59:0] s3_o21;
    logic [59:0] s3_o21_h_x, s3_o21_h;
    assign s3_o21_h_x = s3_k13_xr;
    always_ff @(posedge clk) s3_o21_h <= mx_50[0] ? (60'(s3_o21_h_x >> 1) + (s3_o21_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o21_h_x;
    assign s3_o21 = s3_o21_h;
    logic [59:0] s3_o29;
    logic [59:0] s3_o29_h_x, s3_o29_h;
    assign s3_o29_h_x = s3_k13_yr;
    always_ff @(posedge clk) s3_o29_h <= mx_50[0] ? (60'(s3_o29_h_x >> 1) + (s3_o29_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o29_h_x;
    assign s3_o29 = s3_o29_h;
    logic [59:0] s3_k14_xr; logic [59:0] s3_k14_yr;
    MS_N16_q60_P32_tpm_p3_core_s3_bu s3_k14 (.clk(clk), .aIn(s2_o22), .bIn(s2_o30), .W(s3_t2_c0_w), .QH(s3q_QH), .aOut(s3_k14_xr), .bOut(s3_k14_yr));
    logic [59:0] s3_o22;
    logic [59:0] s3_o22_h_x, s3_o22_h;
    assign s3_o22_h_x = s3_k14_xr;
    always_ff @(posedge clk) s3_o22_h <= mx_50[0] ? (60'(s3_o22_h_x >> 1) + (s3_o22_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o22_h_x;
    assign s3_o22 = s3_o22_h;
    logic [59:0] s3_o30;
    logic [59:0] s3_o30_h_x, s3_o30_h;
    assign s3_o30_h_x = s3_k14_yr;
    always_ff @(posedge clk) s3_o30_h <= mx_50[0] ? (60'(s3_o30_h_x >> 1) + (s3_o30_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o30_h_x;
    assign s3_o30 = s3_o30_h;
    logic [59:0] s3_k15_xr; logic [59:0] s3_k15_yr;
    MS_N16_q60_P32_tpm_p3_core_s3_bu s3_k15 (.clk(clk), .aIn(s2_o23), .bIn(s2_o31), .W(s3_t6_c0_w), .QH(s3q_QH), .aOut(s3_k15_xr), .bOut(s3_k15_yr));
    logic [59:0] s3_o23;
    logic [59:0] s3_o23_h_x, s3_o23_h;
    assign s3_o23_h_x = s3_k15_xr;
    always_ff @(posedge clk) s3_o23_h <= mx_50[0] ? (60'(s3_o23_h_x >> 1) + (s3_o23_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o23_h_x;
    assign s3_o23 = s3_o23_h;
    logic [59:0] s3_o31;
    logic [59:0] s3_o31_h_x, s3_o31_h;
    assign s3_o31_h_x = s3_k15_yr;
    always_ff @(posedge clk) s3_o31_h <= mx_50[0] ? (60'(s3_o31_h_x >> 1) + (s3_o31_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o31_h_x;
    assign s3_o31 = s3_o31_h;
    // stage 4: 16 butterflies on lane pairs (bit 4), latency 14
    (* max_fanout = 16 *) logic [16:0] s4q_QH;
    always_ff @(posedge clk) s4q_QH <= QH_r;
    logic [59:0] s4_k0_xr; logic [59:0] s4_k0_yr;
    MS_N16_q60_P32_tpm_p3_core_s4_c0 s4_k0 (.clk(clk), .aIn(s3_o0), .bIn(s3_o16), .QH(s4q_QH), .aOut(s4_k0_xr), .bOut(s4_k0_yr));
    logic [59:0] s4_o0;
    (* max_fanout = 16 *) logic [59:0] s4q_QHALF;
    always_ff @(posedge clk) s4q_QHALF <= QHALF_r;
    logic [59:0] s4_o0_h_x, s4_o0_h;
    assign s4_o0_h_x = s4_k0_xr;
    (* max_fanout = 16 *) logic [0:0] mx_51;
    always_ff @(posedge clk) mx_51 <= mx_50;
    (* max_fanout = 16 *) logic [0:0] mx_52;
    always_ff @(posedge clk) mx_52 <= mx_51;
    (* max_fanout = 16 *) logic [0:0] mx_53;
    always_ff @(posedge clk) mx_53 <= mx_52;
    (* max_fanout = 16 *) logic [0:0] mx_54;
    always_ff @(posedge clk) mx_54 <= mx_53;
    always_ff @(posedge clk) s4_o0_h <= mx_54[0] ? (60'(s4_o0_h_x >> 1) + (s4_o0_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o0_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s4_o0_bal (.clk(clk), .din(s4_o0_h), .dout(s4_o0));
    logic [59:0] s4_o16;
    logic [59:0] s4_o16_h_x, s4_o16_h;
    assign s4_o16_h_x = s4_k0_yr;
    always_ff @(posedge clk) s4_o16_h <= mx_54[0] ? (60'(s4_o16_h_x >> 1) + (s4_o16_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o16_h_x;
    MS_N16_q60_P32_tpm_p3_core_dly #(.W(60), .D(11)) s4_o16_bal (.clk(clk), .din(s4_o16_h), .dout(s4_o16));
    logic [59:0] s4_t7_c0_w;
    logic s4_t7_c0_tab_hit_c, s4_t7_c0_tab_hit; logic [6:0] s4_t7_c0_tab_rel;
    assign s4_t7_c0_tab_rel = tw_wi - 7'd14;
    assign s4_t7_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd14) && (tw_wi < 7'd16);
    logic [0:0] s4_t7_c0_tab_col_c, s4_t7_c0_tab_col; logic [0:0] s4_t7_c0_tab_wa_c, s4_t7_c0_tab_wa;
    assign s4_t7_c0_tab_col_c = '0; assign s4_t7_c0_tab_wa_c = s4_t7_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s4_t7_c0_tab_hit <= s4_t7_c0_tab_hit_c; s4_t7_c0_tab_col <= s4_t7_c0_tab_col_c; s4_t7_c0_tab_wa <= s4_t7_c0_tab_wa_c; end
    logic s4_t7_c0_tab_hit_q; logic [0:0] s4_t7_c0_tab_col_q; logic [0:0] s4_t7_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s4_t7_c0_tab_wd_q;
    always_ff @(posedge clk) begin s4_t7_c0_tab_hit_q <= s4_t7_c0_tab_hit; s4_t7_c0_tab_col_q <= s4_t7_c0_tab_col; s4_t7_c0_tab_wa_q <= s4_t7_c0_tab_wa; s4_t7_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab7 s4_t7_c0_tab (.clk(clk), .addr({mx_49}), .we(s4_t7_c0_tab_hit_q), .wa(s4_t7_c0_tab_wa_q), .wcol(s4_t7_c0_tab_col_q), .wd(s4_t7_c0_tab_wd_q), .q0(s4_t7_c0_w));
    logic [59:0] s4_k1_xr; logic [59:0] s4_k1_yr;
    MS_N16_q60_P32_tpm_p3_core_s4_bu s4_k1 (.clk(clk), .aIn(s3_o1), .bIn(s3_o17), .W(s4_t7_c0_w), .QH(s4q_QH), .aOut(s4_k1_xr), .bOut(s4_k1_yr));
    logic [59:0] s4_o1;
    logic [59:0] s4_o1_h_x, s4_o1_h;
    assign s4_o1_h_x = s4_k1_xr;
    (* max_fanout = 16 *) logic [0:0] mx_55;
    always_ff @(posedge clk) mx_55 <= mx_54;
    (* max_fanout = 16 *) logic [0:0] mx_56;
    always_ff @(posedge clk) mx_56 <= mx_55;
    (* max_fanout = 16 *) logic [0:0] mx_57;
    always_ff @(posedge clk) mx_57 <= mx_56;
    (* max_fanout = 16 *) logic [0:0] mx_58;
    always_ff @(posedge clk) mx_58 <= mx_57;
    (* max_fanout = 16 *) logic [0:0] mx_59;
    always_ff @(posedge clk) mx_59 <= mx_58;
    (* max_fanout = 16 *) logic [0:0] mx_60;
    always_ff @(posedge clk) mx_60 <= mx_59;
    (* max_fanout = 16 *) logic [0:0] mx_61;
    always_ff @(posedge clk) mx_61 <= mx_60;
    (* max_fanout = 16 *) logic [0:0] mx_62;
    always_ff @(posedge clk) mx_62 <= mx_61;
    (* max_fanout = 16 *) logic [0:0] mx_63;
    always_ff @(posedge clk) mx_63 <= mx_62;
    (* max_fanout = 16 *) logic [0:0] mx_64;
    always_ff @(posedge clk) mx_64 <= mx_63;
    (* max_fanout = 16 *) logic [0:0] mx_65;
    always_ff @(posedge clk) mx_65 <= mx_64;
    always_ff @(posedge clk) s4_o1_h <= mx_65[0] ? (60'(s4_o1_h_x >> 1) + (s4_o1_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o1_h_x;
    assign s4_o1 = s4_o1_h;
    logic [59:0] s4_o17;
    logic [59:0] s4_o17_h_x, s4_o17_h;
    assign s4_o17_h_x = s4_k1_yr;
    always_ff @(posedge clk) s4_o17_h <= mx_65[0] ? (60'(s4_o17_h_x >> 1) + (s4_o17_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o17_h_x;
    assign s4_o17 = s4_o17_h;
    logic [59:0] s4_t3_c0_w;
    logic s4_t3_c0_tab_hit_c, s4_t3_c0_tab_hit; logic [6:0] s4_t3_c0_tab_rel;
    assign s4_t3_c0_tab_rel = tw_wi - 7'd6;
    assign s4_t3_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd6) && (tw_wi < 7'd8);
    logic [0:0] s4_t3_c0_tab_col_c, s4_t3_c0_tab_col; logic [0:0] s4_t3_c0_tab_wa_c, s4_t3_c0_tab_wa;
    assign s4_t3_c0_tab_col_c = '0; assign s4_t3_c0_tab_wa_c = s4_t3_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s4_t3_c0_tab_hit <= s4_t3_c0_tab_hit_c; s4_t3_c0_tab_col <= s4_t3_c0_tab_col_c; s4_t3_c0_tab_wa <= s4_t3_c0_tab_wa_c; end
    logic s4_t3_c0_tab_hit_q; logic [0:0] s4_t3_c0_tab_col_q; logic [0:0] s4_t3_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s4_t3_c0_tab_wd_q;
    always_ff @(posedge clk) begin s4_t3_c0_tab_hit_q <= s4_t3_c0_tab_hit; s4_t3_c0_tab_col_q <= s4_t3_c0_tab_col; s4_t3_c0_tab_wa_q <= s4_t3_c0_tab_wa; s4_t3_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab3 s4_t3_c0_tab (.clk(clk), .addr({mx_49}), .we(s4_t3_c0_tab_hit_q), .wa(s4_t3_c0_tab_wa_q), .wcol(s4_t3_c0_tab_col_q), .wd(s4_t3_c0_tab_wd_q), .q0(s4_t3_c0_w));
    logic [59:0] s4_k2_xr; logic [59:0] s4_k2_yr;
    MS_N16_q60_P32_tpm_p3_core_s4_bu s4_k2 (.clk(clk), .aIn(s3_o2), .bIn(s3_o18), .W(s4_t3_c0_w), .QH(s4q_QH), .aOut(s4_k2_xr), .bOut(s4_k2_yr));
    logic [59:0] s4_o2;
    logic [59:0] s4_o2_h_x, s4_o2_h;
    assign s4_o2_h_x = s4_k2_xr;
    always_ff @(posedge clk) s4_o2_h <= mx_65[0] ? (60'(s4_o2_h_x >> 1) + (s4_o2_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o2_h_x;
    assign s4_o2 = s4_o2_h;
    logic [59:0] s4_o18;
    logic [59:0] s4_o18_h_x, s4_o18_h;
    assign s4_o18_h_x = s4_k2_yr;
    always_ff @(posedge clk) s4_o18_h <= mx_65[0] ? (60'(s4_o18_h_x >> 1) + (s4_o18_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o18_h_x;
    assign s4_o18 = s4_o18_h;
    logic [59:0] s4_t8_c0_w;
    logic s4_t8_c0_tab_hit_c, s4_t8_c0_tab_hit; logic [6:0] s4_t8_c0_tab_rel;
    assign s4_t8_c0_tab_rel = tw_wi - 7'd16;
    assign s4_t8_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd16) && (tw_wi < 7'd18);
    logic [0:0] s4_t8_c0_tab_col_c, s4_t8_c0_tab_col; logic [0:0] s4_t8_c0_tab_wa_c, s4_t8_c0_tab_wa;
    assign s4_t8_c0_tab_col_c = '0; assign s4_t8_c0_tab_wa_c = s4_t8_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s4_t8_c0_tab_hit <= s4_t8_c0_tab_hit_c; s4_t8_c0_tab_col <= s4_t8_c0_tab_col_c; s4_t8_c0_tab_wa <= s4_t8_c0_tab_wa_c; end
    logic s4_t8_c0_tab_hit_q; logic [0:0] s4_t8_c0_tab_col_q; logic [0:0] s4_t8_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s4_t8_c0_tab_wd_q;
    always_ff @(posedge clk) begin s4_t8_c0_tab_hit_q <= s4_t8_c0_tab_hit; s4_t8_c0_tab_col_q <= s4_t8_c0_tab_col; s4_t8_c0_tab_wa_q <= s4_t8_c0_tab_wa; s4_t8_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab8 s4_t8_c0_tab (.clk(clk), .addr({mx_49}), .we(s4_t8_c0_tab_hit_q), .wa(s4_t8_c0_tab_wa_q), .wcol(s4_t8_c0_tab_col_q), .wd(s4_t8_c0_tab_wd_q), .q0(s4_t8_c0_w));
    logic [59:0] s4_k3_xr; logic [59:0] s4_k3_yr;
    MS_N16_q60_P32_tpm_p3_core_s4_bu s4_k3 (.clk(clk), .aIn(s3_o3), .bIn(s3_o19), .W(s4_t8_c0_w), .QH(s4q_QH), .aOut(s4_k3_xr), .bOut(s4_k3_yr));
    logic [59:0] s4_o3;
    logic [59:0] s4_o3_h_x, s4_o3_h;
    assign s4_o3_h_x = s4_k3_xr;
    always_ff @(posedge clk) s4_o3_h <= mx_65[0] ? (60'(s4_o3_h_x >> 1) + (s4_o3_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o3_h_x;
    assign s4_o3 = s4_o3_h;
    logic [59:0] s4_o19;
    logic [59:0] s4_o19_h_x, s4_o19_h;
    assign s4_o19_h_x = s4_k3_yr;
    always_ff @(posedge clk) s4_o19_h <= mx_65[0] ? (60'(s4_o19_h_x >> 1) + (s4_o19_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o19_h_x;
    assign s4_o19 = s4_o19_h;
    logic [59:0] s4_t1_c0_w;
    logic s4_t1_c0_tab_hit_c, s4_t1_c0_tab_hit; logic [6:0] s4_t1_c0_tab_rel;
    assign s4_t1_c0_tab_rel = tw_wi - 7'd2;
    assign s4_t1_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd2) && (tw_wi < 7'd4);
    logic [0:0] s4_t1_c0_tab_col_c, s4_t1_c0_tab_col; logic [0:0] s4_t1_c0_tab_wa_c, s4_t1_c0_tab_wa;
    assign s4_t1_c0_tab_col_c = '0; assign s4_t1_c0_tab_wa_c = s4_t1_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s4_t1_c0_tab_hit <= s4_t1_c0_tab_hit_c; s4_t1_c0_tab_col <= s4_t1_c0_tab_col_c; s4_t1_c0_tab_wa <= s4_t1_c0_tab_wa_c; end
    logic s4_t1_c0_tab_hit_q; logic [0:0] s4_t1_c0_tab_col_q; logic [0:0] s4_t1_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s4_t1_c0_tab_wd_q;
    always_ff @(posedge clk) begin s4_t1_c0_tab_hit_q <= s4_t1_c0_tab_hit; s4_t1_c0_tab_col_q <= s4_t1_c0_tab_col; s4_t1_c0_tab_wa_q <= s4_t1_c0_tab_wa; s4_t1_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab1 s4_t1_c0_tab (.clk(clk), .addr({mx_49}), .we(s4_t1_c0_tab_hit_q), .wa(s4_t1_c0_tab_wa_q), .wcol(s4_t1_c0_tab_col_q), .wd(s4_t1_c0_tab_wd_q), .q0(s4_t1_c0_w));
    logic [59:0] s4_k4_xr; logic [59:0] s4_k4_yr;
    MS_N16_q60_P32_tpm_p3_core_s4_bu s4_k4 (.clk(clk), .aIn(s3_o4), .bIn(s3_o20), .W(s4_t1_c0_w), .QH(s4q_QH), .aOut(s4_k4_xr), .bOut(s4_k4_yr));
    logic [59:0] s4_o4;
    logic [59:0] s4_o4_h_x, s4_o4_h;
    assign s4_o4_h_x = s4_k4_xr;
    always_ff @(posedge clk) s4_o4_h <= mx_65[0] ? (60'(s4_o4_h_x >> 1) + (s4_o4_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o4_h_x;
    assign s4_o4 = s4_o4_h;
    logic [59:0] s4_o20;
    logic [59:0] s4_o20_h_x, s4_o20_h;
    assign s4_o20_h_x = s4_k4_yr;
    always_ff @(posedge clk) s4_o20_h <= mx_65[0] ? (60'(s4_o20_h_x >> 1) + (s4_o20_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o20_h_x;
    assign s4_o20 = s4_o20_h;
    logic [59:0] s4_t9_c0_w;
    logic s4_t9_c0_tab_hit_c, s4_t9_c0_tab_hit; logic [6:0] s4_t9_c0_tab_rel;
    assign s4_t9_c0_tab_rel = tw_wi - 7'd18;
    assign s4_t9_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd18) && (tw_wi < 7'd20);
    logic [0:0] s4_t9_c0_tab_col_c, s4_t9_c0_tab_col; logic [0:0] s4_t9_c0_tab_wa_c, s4_t9_c0_tab_wa;
    assign s4_t9_c0_tab_col_c = '0; assign s4_t9_c0_tab_wa_c = s4_t9_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s4_t9_c0_tab_hit <= s4_t9_c0_tab_hit_c; s4_t9_c0_tab_col <= s4_t9_c0_tab_col_c; s4_t9_c0_tab_wa <= s4_t9_c0_tab_wa_c; end
    logic s4_t9_c0_tab_hit_q; logic [0:0] s4_t9_c0_tab_col_q; logic [0:0] s4_t9_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s4_t9_c0_tab_wd_q;
    always_ff @(posedge clk) begin s4_t9_c0_tab_hit_q <= s4_t9_c0_tab_hit; s4_t9_c0_tab_col_q <= s4_t9_c0_tab_col; s4_t9_c0_tab_wa_q <= s4_t9_c0_tab_wa; s4_t9_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab9 s4_t9_c0_tab (.clk(clk), .addr({mx_49}), .we(s4_t9_c0_tab_hit_q), .wa(s4_t9_c0_tab_wa_q), .wcol(s4_t9_c0_tab_col_q), .wd(s4_t9_c0_tab_wd_q), .q0(s4_t9_c0_w));
    logic [59:0] s4_k5_xr; logic [59:0] s4_k5_yr;
    MS_N16_q60_P32_tpm_p3_core_s4_bu s4_k5 (.clk(clk), .aIn(s3_o5), .bIn(s3_o21), .W(s4_t9_c0_w), .QH(s4q_QH), .aOut(s4_k5_xr), .bOut(s4_k5_yr));
    logic [59:0] s4_o5;
    logic [59:0] s4_o5_h_x, s4_o5_h;
    assign s4_o5_h_x = s4_k5_xr;
    always_ff @(posedge clk) s4_o5_h <= mx_65[0] ? (60'(s4_o5_h_x >> 1) + (s4_o5_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o5_h_x;
    assign s4_o5 = s4_o5_h;
    logic [59:0] s4_o21;
    logic [59:0] s4_o21_h_x, s4_o21_h;
    assign s4_o21_h_x = s4_k5_yr;
    always_ff @(posedge clk) s4_o21_h <= mx_65[0] ? (60'(s4_o21_h_x >> 1) + (s4_o21_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o21_h_x;
    assign s4_o21 = s4_o21_h;
    logic [59:0] s4_t4_c0_w;
    logic s4_t4_c0_tab_hit_c, s4_t4_c0_tab_hit; logic [6:0] s4_t4_c0_tab_rel;
    assign s4_t4_c0_tab_rel = tw_wi - 7'd8;
    assign s4_t4_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd8) && (tw_wi < 7'd10);
    logic [0:0] s4_t4_c0_tab_col_c, s4_t4_c0_tab_col; logic [0:0] s4_t4_c0_tab_wa_c, s4_t4_c0_tab_wa;
    assign s4_t4_c0_tab_col_c = '0; assign s4_t4_c0_tab_wa_c = s4_t4_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s4_t4_c0_tab_hit <= s4_t4_c0_tab_hit_c; s4_t4_c0_tab_col <= s4_t4_c0_tab_col_c; s4_t4_c0_tab_wa <= s4_t4_c0_tab_wa_c; end
    logic s4_t4_c0_tab_hit_q; logic [0:0] s4_t4_c0_tab_col_q; logic [0:0] s4_t4_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s4_t4_c0_tab_wd_q;
    always_ff @(posedge clk) begin s4_t4_c0_tab_hit_q <= s4_t4_c0_tab_hit; s4_t4_c0_tab_col_q <= s4_t4_c0_tab_col; s4_t4_c0_tab_wa_q <= s4_t4_c0_tab_wa; s4_t4_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab4 s4_t4_c0_tab (.clk(clk), .addr({mx_49}), .we(s4_t4_c0_tab_hit_q), .wa(s4_t4_c0_tab_wa_q), .wcol(s4_t4_c0_tab_col_q), .wd(s4_t4_c0_tab_wd_q), .q0(s4_t4_c0_w));
    logic [59:0] s4_k6_xr; logic [59:0] s4_k6_yr;
    MS_N16_q60_P32_tpm_p3_core_s4_bu s4_k6 (.clk(clk), .aIn(s3_o6), .bIn(s3_o22), .W(s4_t4_c0_w), .QH(s4q_QH), .aOut(s4_k6_xr), .bOut(s4_k6_yr));
    logic [59:0] s4_o6;
    logic [59:0] s4_o6_h_x, s4_o6_h;
    assign s4_o6_h_x = s4_k6_xr;
    always_ff @(posedge clk) s4_o6_h <= mx_65[0] ? (60'(s4_o6_h_x >> 1) + (s4_o6_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o6_h_x;
    assign s4_o6 = s4_o6_h;
    logic [59:0] s4_o22;
    logic [59:0] s4_o22_h_x, s4_o22_h;
    assign s4_o22_h_x = s4_k6_yr;
    always_ff @(posedge clk) s4_o22_h <= mx_65[0] ? (60'(s4_o22_h_x >> 1) + (s4_o22_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o22_h_x;
    assign s4_o22 = s4_o22_h;
    logic [59:0] s4_t10_c0_w;
    logic s4_t10_c0_tab_hit_c, s4_t10_c0_tab_hit; logic [6:0] s4_t10_c0_tab_rel;
    assign s4_t10_c0_tab_rel = tw_wi - 7'd20;
    assign s4_t10_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd20) && (tw_wi < 7'd22);
    logic [0:0] s4_t10_c0_tab_col_c, s4_t10_c0_tab_col; logic [0:0] s4_t10_c0_tab_wa_c, s4_t10_c0_tab_wa;
    assign s4_t10_c0_tab_col_c = '0; assign s4_t10_c0_tab_wa_c = s4_t10_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s4_t10_c0_tab_hit <= s4_t10_c0_tab_hit_c; s4_t10_c0_tab_col <= s4_t10_c0_tab_col_c; s4_t10_c0_tab_wa <= s4_t10_c0_tab_wa_c; end
    logic s4_t10_c0_tab_hit_q; logic [0:0] s4_t10_c0_tab_col_q; logic [0:0] s4_t10_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s4_t10_c0_tab_wd_q;
    always_ff @(posedge clk) begin s4_t10_c0_tab_hit_q <= s4_t10_c0_tab_hit; s4_t10_c0_tab_col_q <= s4_t10_c0_tab_col; s4_t10_c0_tab_wa_q <= s4_t10_c0_tab_wa; s4_t10_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab10 s4_t10_c0_tab (.clk(clk), .addr({mx_49}), .we(s4_t10_c0_tab_hit_q), .wa(s4_t10_c0_tab_wa_q), .wcol(s4_t10_c0_tab_col_q), .wd(s4_t10_c0_tab_wd_q), .q0(s4_t10_c0_w));
    logic [59:0] s4_k7_xr; logic [59:0] s4_k7_yr;
    MS_N16_q60_P32_tpm_p3_core_s4_bu s4_k7 (.clk(clk), .aIn(s3_o7), .bIn(s3_o23), .W(s4_t10_c0_w), .QH(s4q_QH), .aOut(s4_k7_xr), .bOut(s4_k7_yr));
    logic [59:0] s4_o7;
    logic [59:0] s4_o7_h_x, s4_o7_h;
    assign s4_o7_h_x = s4_k7_xr;
    always_ff @(posedge clk) s4_o7_h <= mx_65[0] ? (60'(s4_o7_h_x >> 1) + (s4_o7_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o7_h_x;
    assign s4_o7 = s4_o7_h;
    logic [59:0] s4_o23;
    logic [59:0] s4_o23_h_x, s4_o23_h;
    assign s4_o23_h_x = s4_k7_yr;
    always_ff @(posedge clk) s4_o23_h <= mx_65[0] ? (60'(s4_o23_h_x >> 1) + (s4_o23_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o23_h_x;
    assign s4_o23 = s4_o23_h;
    logic [59:0] s4_t0_c0_w;
    logic s4_t0_c0_tab_hit_c, s4_t0_c0_tab_hit; logic [6:0] s4_t0_c0_tab_rel;
    assign s4_t0_c0_tab_rel = tw_wi - 7'd0;
    assign s4_t0_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd0) && (tw_wi < 7'd2);
    logic [0:0] s4_t0_c0_tab_col_c, s4_t0_c0_tab_col; logic [0:0] s4_t0_c0_tab_wa_c, s4_t0_c0_tab_wa;
    assign s4_t0_c0_tab_col_c = '0; assign s4_t0_c0_tab_wa_c = s4_t0_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s4_t0_c0_tab_hit <= s4_t0_c0_tab_hit_c; s4_t0_c0_tab_col <= s4_t0_c0_tab_col_c; s4_t0_c0_tab_wa <= s4_t0_c0_tab_wa_c; end
    logic s4_t0_c0_tab_hit_q; logic [0:0] s4_t0_c0_tab_col_q; logic [0:0] s4_t0_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s4_t0_c0_tab_wd_q;
    always_ff @(posedge clk) begin s4_t0_c0_tab_hit_q <= s4_t0_c0_tab_hit; s4_t0_c0_tab_col_q <= s4_t0_c0_tab_col; s4_t0_c0_tab_wa_q <= s4_t0_c0_tab_wa; s4_t0_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab0 s4_t0_c0_tab (.clk(clk), .addr({mx_49}), .we(s4_t0_c0_tab_hit_q), .wa(s4_t0_c0_tab_wa_q), .wcol(s4_t0_c0_tab_col_q), .wd(s4_t0_c0_tab_wd_q), .q0(s4_t0_c0_w));
    logic [59:0] s4_k8_xr; logic [59:0] s4_k8_yr;
    MS_N16_q60_P32_tpm_p3_core_s4_bu s4_k8 (.clk(clk), .aIn(s3_o8), .bIn(s3_o24), .W(s4_t0_c0_w), .QH(s4q_QH), .aOut(s4_k8_xr), .bOut(s4_k8_yr));
    logic [59:0] s4_o8;
    logic [59:0] s4_o8_h_x, s4_o8_h;
    assign s4_o8_h_x = s4_k8_xr;
    always_ff @(posedge clk) s4_o8_h <= mx_65[0] ? (60'(s4_o8_h_x >> 1) + (s4_o8_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o8_h_x;
    assign s4_o8 = s4_o8_h;
    logic [59:0] s4_o24;
    logic [59:0] s4_o24_h_x, s4_o24_h;
    assign s4_o24_h_x = s4_k8_yr;
    always_ff @(posedge clk) s4_o24_h <= mx_65[0] ? (60'(s4_o24_h_x >> 1) + (s4_o24_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o24_h_x;
    assign s4_o24 = s4_o24_h;
    logic [59:0] s4_t11_c0_w;
    logic s4_t11_c0_tab_hit_c, s4_t11_c0_tab_hit; logic [6:0] s4_t11_c0_tab_rel;
    assign s4_t11_c0_tab_rel = tw_wi - 7'd22;
    assign s4_t11_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd22) && (tw_wi < 7'd24);
    logic [0:0] s4_t11_c0_tab_col_c, s4_t11_c0_tab_col; logic [0:0] s4_t11_c0_tab_wa_c, s4_t11_c0_tab_wa;
    assign s4_t11_c0_tab_col_c = '0; assign s4_t11_c0_tab_wa_c = s4_t11_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s4_t11_c0_tab_hit <= s4_t11_c0_tab_hit_c; s4_t11_c0_tab_col <= s4_t11_c0_tab_col_c; s4_t11_c0_tab_wa <= s4_t11_c0_tab_wa_c; end
    logic s4_t11_c0_tab_hit_q; logic [0:0] s4_t11_c0_tab_col_q; logic [0:0] s4_t11_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s4_t11_c0_tab_wd_q;
    always_ff @(posedge clk) begin s4_t11_c0_tab_hit_q <= s4_t11_c0_tab_hit; s4_t11_c0_tab_col_q <= s4_t11_c0_tab_col; s4_t11_c0_tab_wa_q <= s4_t11_c0_tab_wa; s4_t11_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab11 s4_t11_c0_tab (.clk(clk), .addr({mx_49}), .we(s4_t11_c0_tab_hit_q), .wa(s4_t11_c0_tab_wa_q), .wcol(s4_t11_c0_tab_col_q), .wd(s4_t11_c0_tab_wd_q), .q0(s4_t11_c0_w));
    logic [59:0] s4_k9_xr; logic [59:0] s4_k9_yr;
    MS_N16_q60_P32_tpm_p3_core_s4_bu s4_k9 (.clk(clk), .aIn(s3_o9), .bIn(s3_o25), .W(s4_t11_c0_w), .QH(s4q_QH), .aOut(s4_k9_xr), .bOut(s4_k9_yr));
    logic [59:0] s4_o9;
    logic [59:0] s4_o9_h_x, s4_o9_h;
    assign s4_o9_h_x = s4_k9_xr;
    always_ff @(posedge clk) s4_o9_h <= mx_65[0] ? (60'(s4_o9_h_x >> 1) + (s4_o9_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o9_h_x;
    assign s4_o9 = s4_o9_h;
    logic [59:0] s4_o25;
    logic [59:0] s4_o25_h_x, s4_o25_h;
    assign s4_o25_h_x = s4_k9_yr;
    always_ff @(posedge clk) s4_o25_h <= mx_65[0] ? (60'(s4_o25_h_x >> 1) + (s4_o25_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o25_h_x;
    assign s4_o25 = s4_o25_h;
    logic [59:0] s4_t5_c0_w;
    logic s4_t5_c0_tab_hit_c, s4_t5_c0_tab_hit; logic [6:0] s4_t5_c0_tab_rel;
    assign s4_t5_c0_tab_rel = tw_wi - 7'd10;
    assign s4_t5_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd10) && (tw_wi < 7'd12);
    logic [0:0] s4_t5_c0_tab_col_c, s4_t5_c0_tab_col; logic [0:0] s4_t5_c0_tab_wa_c, s4_t5_c0_tab_wa;
    assign s4_t5_c0_tab_col_c = '0; assign s4_t5_c0_tab_wa_c = s4_t5_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s4_t5_c0_tab_hit <= s4_t5_c0_tab_hit_c; s4_t5_c0_tab_col <= s4_t5_c0_tab_col_c; s4_t5_c0_tab_wa <= s4_t5_c0_tab_wa_c; end
    logic s4_t5_c0_tab_hit_q; logic [0:0] s4_t5_c0_tab_col_q; logic [0:0] s4_t5_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s4_t5_c0_tab_wd_q;
    always_ff @(posedge clk) begin s4_t5_c0_tab_hit_q <= s4_t5_c0_tab_hit; s4_t5_c0_tab_col_q <= s4_t5_c0_tab_col; s4_t5_c0_tab_wa_q <= s4_t5_c0_tab_wa; s4_t5_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab5 s4_t5_c0_tab (.clk(clk), .addr({mx_49}), .we(s4_t5_c0_tab_hit_q), .wa(s4_t5_c0_tab_wa_q), .wcol(s4_t5_c0_tab_col_q), .wd(s4_t5_c0_tab_wd_q), .q0(s4_t5_c0_w));
    logic [59:0] s4_k10_xr; logic [59:0] s4_k10_yr;
    MS_N16_q60_P32_tpm_p3_core_s4_bu s4_k10 (.clk(clk), .aIn(s3_o10), .bIn(s3_o26), .W(s4_t5_c0_w), .QH(s4q_QH), .aOut(s4_k10_xr), .bOut(s4_k10_yr));
    logic [59:0] s4_o10;
    logic [59:0] s4_o10_h_x, s4_o10_h;
    assign s4_o10_h_x = s4_k10_xr;
    always_ff @(posedge clk) s4_o10_h <= mx_65[0] ? (60'(s4_o10_h_x >> 1) + (s4_o10_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o10_h_x;
    assign s4_o10 = s4_o10_h;
    logic [59:0] s4_o26;
    logic [59:0] s4_o26_h_x, s4_o26_h;
    assign s4_o26_h_x = s4_k10_yr;
    always_ff @(posedge clk) s4_o26_h <= mx_65[0] ? (60'(s4_o26_h_x >> 1) + (s4_o26_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o26_h_x;
    assign s4_o26 = s4_o26_h;
    logic [59:0] s4_t12_c0_w;
    logic s4_t12_c0_tab_hit_c, s4_t12_c0_tab_hit; logic [6:0] s4_t12_c0_tab_rel;
    assign s4_t12_c0_tab_rel = tw_wi - 7'd24;
    assign s4_t12_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd24) && (tw_wi < 7'd26);
    logic [0:0] s4_t12_c0_tab_col_c, s4_t12_c0_tab_col; logic [0:0] s4_t12_c0_tab_wa_c, s4_t12_c0_tab_wa;
    assign s4_t12_c0_tab_col_c = '0; assign s4_t12_c0_tab_wa_c = s4_t12_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s4_t12_c0_tab_hit <= s4_t12_c0_tab_hit_c; s4_t12_c0_tab_col <= s4_t12_c0_tab_col_c; s4_t12_c0_tab_wa <= s4_t12_c0_tab_wa_c; end
    logic s4_t12_c0_tab_hit_q; logic [0:0] s4_t12_c0_tab_col_q; logic [0:0] s4_t12_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s4_t12_c0_tab_wd_q;
    always_ff @(posedge clk) begin s4_t12_c0_tab_hit_q <= s4_t12_c0_tab_hit; s4_t12_c0_tab_col_q <= s4_t12_c0_tab_col; s4_t12_c0_tab_wa_q <= s4_t12_c0_tab_wa; s4_t12_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab12 s4_t12_c0_tab (.clk(clk), .addr({mx_49}), .we(s4_t12_c0_tab_hit_q), .wa(s4_t12_c0_tab_wa_q), .wcol(s4_t12_c0_tab_col_q), .wd(s4_t12_c0_tab_wd_q), .q0(s4_t12_c0_w));
    logic [59:0] s4_k11_xr; logic [59:0] s4_k11_yr;
    MS_N16_q60_P32_tpm_p3_core_s4_bu s4_k11 (.clk(clk), .aIn(s3_o11), .bIn(s3_o27), .W(s4_t12_c0_w), .QH(s4q_QH), .aOut(s4_k11_xr), .bOut(s4_k11_yr));
    logic [59:0] s4_o11;
    logic [59:0] s4_o11_h_x, s4_o11_h;
    assign s4_o11_h_x = s4_k11_xr;
    always_ff @(posedge clk) s4_o11_h <= mx_65[0] ? (60'(s4_o11_h_x >> 1) + (s4_o11_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o11_h_x;
    assign s4_o11 = s4_o11_h;
    logic [59:0] s4_o27;
    logic [59:0] s4_o27_h_x, s4_o27_h;
    assign s4_o27_h_x = s4_k11_yr;
    always_ff @(posedge clk) s4_o27_h <= mx_65[0] ? (60'(s4_o27_h_x >> 1) + (s4_o27_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o27_h_x;
    assign s4_o27 = s4_o27_h;
    logic [59:0] s4_t2_c0_w;
    logic s4_t2_c0_tab_hit_c, s4_t2_c0_tab_hit; logic [6:0] s4_t2_c0_tab_rel;
    assign s4_t2_c0_tab_rel = tw_wi - 7'd4;
    assign s4_t2_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd4) && (tw_wi < 7'd6);
    logic [0:0] s4_t2_c0_tab_col_c, s4_t2_c0_tab_col; logic [0:0] s4_t2_c0_tab_wa_c, s4_t2_c0_tab_wa;
    assign s4_t2_c0_tab_col_c = '0; assign s4_t2_c0_tab_wa_c = s4_t2_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s4_t2_c0_tab_hit <= s4_t2_c0_tab_hit_c; s4_t2_c0_tab_col <= s4_t2_c0_tab_col_c; s4_t2_c0_tab_wa <= s4_t2_c0_tab_wa_c; end
    logic s4_t2_c0_tab_hit_q; logic [0:0] s4_t2_c0_tab_col_q; logic [0:0] s4_t2_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s4_t2_c0_tab_wd_q;
    always_ff @(posedge clk) begin s4_t2_c0_tab_hit_q <= s4_t2_c0_tab_hit; s4_t2_c0_tab_col_q <= s4_t2_c0_tab_col; s4_t2_c0_tab_wa_q <= s4_t2_c0_tab_wa; s4_t2_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab2 s4_t2_c0_tab (.clk(clk), .addr({mx_49}), .we(s4_t2_c0_tab_hit_q), .wa(s4_t2_c0_tab_wa_q), .wcol(s4_t2_c0_tab_col_q), .wd(s4_t2_c0_tab_wd_q), .q0(s4_t2_c0_w));
    logic [59:0] s4_k12_xr; logic [59:0] s4_k12_yr;
    MS_N16_q60_P32_tpm_p3_core_s4_bu s4_k12 (.clk(clk), .aIn(s3_o12), .bIn(s3_o28), .W(s4_t2_c0_w), .QH(s4q_QH), .aOut(s4_k12_xr), .bOut(s4_k12_yr));
    logic [59:0] s4_o12;
    logic [59:0] s4_o12_h_x, s4_o12_h;
    assign s4_o12_h_x = s4_k12_xr;
    always_ff @(posedge clk) s4_o12_h <= mx_65[0] ? (60'(s4_o12_h_x >> 1) + (s4_o12_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o12_h_x;
    assign s4_o12 = s4_o12_h;
    logic [59:0] s4_o28;
    logic [59:0] s4_o28_h_x, s4_o28_h;
    assign s4_o28_h_x = s4_k12_yr;
    always_ff @(posedge clk) s4_o28_h <= mx_65[0] ? (60'(s4_o28_h_x >> 1) + (s4_o28_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o28_h_x;
    assign s4_o28 = s4_o28_h;
    logic [59:0] s4_t13_c0_w;
    logic s4_t13_c0_tab_hit_c, s4_t13_c0_tab_hit; logic [6:0] s4_t13_c0_tab_rel;
    assign s4_t13_c0_tab_rel = tw_wi - 7'd26;
    assign s4_t13_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd26) && (tw_wi < 7'd28);
    logic [0:0] s4_t13_c0_tab_col_c, s4_t13_c0_tab_col; logic [0:0] s4_t13_c0_tab_wa_c, s4_t13_c0_tab_wa;
    assign s4_t13_c0_tab_col_c = '0; assign s4_t13_c0_tab_wa_c = s4_t13_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s4_t13_c0_tab_hit <= s4_t13_c0_tab_hit_c; s4_t13_c0_tab_col <= s4_t13_c0_tab_col_c; s4_t13_c0_tab_wa <= s4_t13_c0_tab_wa_c; end
    logic s4_t13_c0_tab_hit_q; logic [0:0] s4_t13_c0_tab_col_q; logic [0:0] s4_t13_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s4_t13_c0_tab_wd_q;
    always_ff @(posedge clk) begin s4_t13_c0_tab_hit_q <= s4_t13_c0_tab_hit; s4_t13_c0_tab_col_q <= s4_t13_c0_tab_col; s4_t13_c0_tab_wa_q <= s4_t13_c0_tab_wa; s4_t13_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab13 s4_t13_c0_tab (.clk(clk), .addr({mx_49}), .we(s4_t13_c0_tab_hit_q), .wa(s4_t13_c0_tab_wa_q), .wcol(s4_t13_c0_tab_col_q), .wd(s4_t13_c0_tab_wd_q), .q0(s4_t13_c0_w));
    logic [59:0] s4_k13_xr; logic [59:0] s4_k13_yr;
    MS_N16_q60_P32_tpm_p3_core_s4_bu s4_k13 (.clk(clk), .aIn(s3_o13), .bIn(s3_o29), .W(s4_t13_c0_w), .QH(s4q_QH), .aOut(s4_k13_xr), .bOut(s4_k13_yr));
    logic [59:0] s4_o13;
    logic [59:0] s4_o13_h_x, s4_o13_h;
    assign s4_o13_h_x = s4_k13_xr;
    always_ff @(posedge clk) s4_o13_h <= mx_65[0] ? (60'(s4_o13_h_x >> 1) + (s4_o13_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o13_h_x;
    assign s4_o13 = s4_o13_h;
    logic [59:0] s4_o29;
    logic [59:0] s4_o29_h_x, s4_o29_h;
    assign s4_o29_h_x = s4_k13_yr;
    always_ff @(posedge clk) s4_o29_h <= mx_65[0] ? (60'(s4_o29_h_x >> 1) + (s4_o29_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o29_h_x;
    assign s4_o29 = s4_o29_h;
    logic [59:0] s4_t6_c0_w;
    logic s4_t6_c0_tab_hit_c, s4_t6_c0_tab_hit; logic [6:0] s4_t6_c0_tab_rel;
    assign s4_t6_c0_tab_rel = tw_wi - 7'd12;
    assign s4_t6_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd12) && (tw_wi < 7'd14);
    logic [0:0] s4_t6_c0_tab_col_c, s4_t6_c0_tab_col; logic [0:0] s4_t6_c0_tab_wa_c, s4_t6_c0_tab_wa;
    assign s4_t6_c0_tab_col_c = '0; assign s4_t6_c0_tab_wa_c = s4_t6_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s4_t6_c0_tab_hit <= s4_t6_c0_tab_hit_c; s4_t6_c0_tab_col <= s4_t6_c0_tab_col_c; s4_t6_c0_tab_wa <= s4_t6_c0_tab_wa_c; end
    logic s4_t6_c0_tab_hit_q; logic [0:0] s4_t6_c0_tab_col_q; logic [0:0] s4_t6_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s4_t6_c0_tab_wd_q;
    always_ff @(posedge clk) begin s4_t6_c0_tab_hit_q <= s4_t6_c0_tab_hit; s4_t6_c0_tab_col_q <= s4_t6_c0_tab_col; s4_t6_c0_tab_wa_q <= s4_t6_c0_tab_wa; s4_t6_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab6 s4_t6_c0_tab (.clk(clk), .addr({mx_49}), .we(s4_t6_c0_tab_hit_q), .wa(s4_t6_c0_tab_wa_q), .wcol(s4_t6_c0_tab_col_q), .wd(s4_t6_c0_tab_wd_q), .q0(s4_t6_c0_w));
    logic [59:0] s4_k14_xr; logic [59:0] s4_k14_yr;
    MS_N16_q60_P32_tpm_p3_core_s4_bu s4_k14 (.clk(clk), .aIn(s3_o14), .bIn(s3_o30), .W(s4_t6_c0_w), .QH(s4q_QH), .aOut(s4_k14_xr), .bOut(s4_k14_yr));
    logic [59:0] s4_o14;
    logic [59:0] s4_o14_h_x, s4_o14_h;
    assign s4_o14_h_x = s4_k14_xr;
    always_ff @(posedge clk) s4_o14_h <= mx_65[0] ? (60'(s4_o14_h_x >> 1) + (s4_o14_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o14_h_x;
    assign s4_o14 = s4_o14_h;
    logic [59:0] s4_o30;
    logic [59:0] s4_o30_h_x, s4_o30_h;
    assign s4_o30_h_x = s4_k14_yr;
    always_ff @(posedge clk) s4_o30_h <= mx_65[0] ? (60'(s4_o30_h_x >> 1) + (s4_o30_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o30_h_x;
    assign s4_o30 = s4_o30_h;
    logic [59:0] s4_t14_c0_w;
    logic s4_t14_c0_tab_hit_c, s4_t14_c0_tab_hit; logic [6:0] s4_t14_c0_tab_rel;
    assign s4_t14_c0_tab_rel = tw_wi - 7'd28;
    assign s4_t14_c0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd28) && (tw_wi < 7'd30);
    logic [0:0] s4_t14_c0_tab_col_c, s4_t14_c0_tab_col; logic [0:0] s4_t14_c0_tab_wa_c, s4_t14_c0_tab_wa;
    assign s4_t14_c0_tab_col_c = '0; assign s4_t14_c0_tab_wa_c = s4_t14_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s4_t14_c0_tab_hit <= s4_t14_c0_tab_hit_c; s4_t14_c0_tab_col <= s4_t14_c0_tab_col_c; s4_t14_c0_tab_wa <= s4_t14_c0_tab_wa_c; end
    logic s4_t14_c0_tab_hit_q; logic [0:0] s4_t14_c0_tab_col_q; logic [0:0] s4_t14_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s4_t14_c0_tab_wd_q;
    always_ff @(posedge clk) begin s4_t14_c0_tab_hit_q <= s4_t14_c0_tab_hit; s4_t14_c0_tab_col_q <= s4_t14_c0_tab_col; s4_t14_c0_tab_wa_q <= s4_t14_c0_tab_wa; s4_t14_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab14 s4_t14_c0_tab (.clk(clk), .addr({mx_49}), .we(s4_t14_c0_tab_hit_q), .wa(s4_t14_c0_tab_wa_q), .wcol(s4_t14_c0_tab_col_q), .wd(s4_t14_c0_tab_wd_q), .q0(s4_t14_c0_w));
    logic [59:0] s4_k15_xr; logic [59:0] s4_k15_yr;
    MS_N16_q60_P32_tpm_p3_core_s4_bu s4_k15 (.clk(clk), .aIn(s3_o15), .bIn(s3_o31), .W(s4_t14_c0_w), .QH(s4q_QH), .aOut(s4_k15_xr), .bOut(s4_k15_yr));
    logic [59:0] s4_o15;
    logic [59:0] s4_o15_h_x, s4_o15_h;
    assign s4_o15_h_x = s4_k15_xr;
    always_ff @(posedge clk) s4_o15_h <= mx_65[0] ? (60'(s4_o15_h_x >> 1) + (s4_o15_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o15_h_x;
    assign s4_o15 = s4_o15_h;
    logic [59:0] s4_o31;
    logic [59:0] s4_o31_h_x, s4_o31_h;
    assign s4_o31_h_x = s4_k15_yr;
    always_ff @(posedge clk) s4_o31_h <= mx_65[0] ? (60'(s4_o31_h_x >> 1) + (s4_o31_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o31_h_x;
    assign s4_o31 = s4_o31_h;
    (* max_fanout = 16 *) logic [16:0] twq_QH;
    always_ff @(posedge clk) twq_QH <= QH_r;
    // output twist: n^-1 (psi^-k) per lane, latency 12
    logic [59:0] tw0_w; logic [59:0] tw0_p;
    logic tw0_tab_hit_c, tw0_tab_hit; logic [6:0] tw0_tab_rel;
    assign tw0_tab_rel = tw_wi - 7'd30;
    assign tw0_tab_hit_c = tw_wen_p && (tw_wi >= 7'd30) && (tw_wi < 7'd32);
    logic [0:0] tw0_tab_col_c, tw0_tab_col; logic [0:0] tw0_tab_wa_c, tw0_tab_wa;
    assign tw0_tab_col_c = '0; assign tw0_tab_wa_c = tw0_tab_rel[0:0];
    always_ff @(posedge clk) begin tw0_tab_hit <= tw0_tab_hit_c; tw0_tab_col <= tw0_tab_col_c; tw0_tab_wa <= tw0_tab_wa_c; end
    logic tw0_tab_hit_q; logic [0:0] tw0_tab_col_q; logic [0:0] tw0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw0_tab_wd_q;
    always_ff @(posedge clk) begin tw0_tab_hit_q <= tw0_tab_hit; tw0_tab_col_q <= tw0_tab_col; tw0_tab_wa_q <= tw0_tab_wa; tw0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab15 tw0_tab (.clk(clk), .addr({mx_64}), .we(tw0_tab_hit_q), .wa(tw0_tab_wa_q), .wcol(tw0_tab_col_q), .wd(tw0_tab_wd_q), .q0(tw0_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw0_mul (.clk(clk), .A(s4_o0), .B(tw0_w), .QH(twq_QH), .P(tw0_p));
    logic [59:0] tw1_w; logic [59:0] tw1_p;
    logic tw1_tab_hit_c, tw1_tab_hit; logic [6:0] tw1_tab_rel;
    assign tw1_tab_rel = tw_wi - 7'd32;
    assign tw1_tab_hit_c = tw_wen_p && (tw_wi >= 7'd32) && (tw_wi < 7'd34);
    logic [0:0] tw1_tab_col_c, tw1_tab_col; logic [0:0] tw1_tab_wa_c, tw1_tab_wa;
    assign tw1_tab_col_c = '0; assign tw1_tab_wa_c = tw1_tab_rel[0:0];
    always_ff @(posedge clk) begin tw1_tab_hit <= tw1_tab_hit_c; tw1_tab_col <= tw1_tab_col_c; tw1_tab_wa <= tw1_tab_wa_c; end
    logic tw1_tab_hit_q; logic [0:0] tw1_tab_col_q; logic [0:0] tw1_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw1_tab_wd_q;
    always_ff @(posedge clk) begin tw1_tab_hit_q <= tw1_tab_hit; tw1_tab_col_q <= tw1_tab_col; tw1_tab_wa_q <= tw1_tab_wa; tw1_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab16 tw1_tab (.clk(clk), .addr({mx_64}), .we(tw1_tab_hit_q), .wa(tw1_tab_wa_q), .wcol(tw1_tab_col_q), .wd(tw1_tab_wd_q), .q0(tw1_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw1_mul (.clk(clk), .A(s4_o1), .B(tw1_w), .QH(twq_QH), .P(tw1_p));
    logic [59:0] tw2_w; logic [59:0] tw2_p;
    logic tw2_tab_hit_c, tw2_tab_hit; logic [6:0] tw2_tab_rel;
    assign tw2_tab_rel = tw_wi - 7'd34;
    assign tw2_tab_hit_c = tw_wen_p && (tw_wi >= 7'd34) && (tw_wi < 7'd36);
    logic [0:0] tw2_tab_col_c, tw2_tab_col; logic [0:0] tw2_tab_wa_c, tw2_tab_wa;
    assign tw2_tab_col_c = '0; assign tw2_tab_wa_c = tw2_tab_rel[0:0];
    always_ff @(posedge clk) begin tw2_tab_hit <= tw2_tab_hit_c; tw2_tab_col <= tw2_tab_col_c; tw2_tab_wa <= tw2_tab_wa_c; end
    logic tw2_tab_hit_q; logic [0:0] tw2_tab_col_q; logic [0:0] tw2_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw2_tab_wd_q;
    always_ff @(posedge clk) begin tw2_tab_hit_q <= tw2_tab_hit; tw2_tab_col_q <= tw2_tab_col; tw2_tab_wa_q <= tw2_tab_wa; tw2_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab17 tw2_tab (.clk(clk), .addr({mx_64}), .we(tw2_tab_hit_q), .wa(tw2_tab_wa_q), .wcol(tw2_tab_col_q), .wd(tw2_tab_wd_q), .q0(tw2_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw2_mul (.clk(clk), .A(s4_o2), .B(tw2_w), .QH(twq_QH), .P(tw2_p));
    logic [59:0] tw3_w; logic [59:0] tw3_p;
    logic tw3_tab_hit_c, tw3_tab_hit; logic [6:0] tw3_tab_rel;
    assign tw3_tab_rel = tw_wi - 7'd36;
    assign tw3_tab_hit_c = tw_wen_p && (tw_wi >= 7'd36) && (tw_wi < 7'd38);
    logic [0:0] tw3_tab_col_c, tw3_tab_col; logic [0:0] tw3_tab_wa_c, tw3_tab_wa;
    assign tw3_tab_col_c = '0; assign tw3_tab_wa_c = tw3_tab_rel[0:0];
    always_ff @(posedge clk) begin tw3_tab_hit <= tw3_tab_hit_c; tw3_tab_col <= tw3_tab_col_c; tw3_tab_wa <= tw3_tab_wa_c; end
    logic tw3_tab_hit_q; logic [0:0] tw3_tab_col_q; logic [0:0] tw3_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw3_tab_wd_q;
    always_ff @(posedge clk) begin tw3_tab_hit_q <= tw3_tab_hit; tw3_tab_col_q <= tw3_tab_col; tw3_tab_wa_q <= tw3_tab_wa; tw3_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab18 tw3_tab (.clk(clk), .addr({mx_64}), .we(tw3_tab_hit_q), .wa(tw3_tab_wa_q), .wcol(tw3_tab_col_q), .wd(tw3_tab_wd_q), .q0(tw3_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw3_mul (.clk(clk), .A(s4_o3), .B(tw3_w), .QH(twq_QH), .P(tw3_p));
    logic [59:0] tw4_w; logic [59:0] tw4_p;
    logic tw4_tab_hit_c, tw4_tab_hit; logic [6:0] tw4_tab_rel;
    assign tw4_tab_rel = tw_wi - 7'd38;
    assign tw4_tab_hit_c = tw_wen_p && (tw_wi >= 7'd38) && (tw_wi < 7'd40);
    logic [0:0] tw4_tab_col_c, tw4_tab_col; logic [0:0] tw4_tab_wa_c, tw4_tab_wa;
    assign tw4_tab_col_c = '0; assign tw4_tab_wa_c = tw4_tab_rel[0:0];
    always_ff @(posedge clk) begin tw4_tab_hit <= tw4_tab_hit_c; tw4_tab_col <= tw4_tab_col_c; tw4_tab_wa <= tw4_tab_wa_c; end
    logic tw4_tab_hit_q; logic [0:0] tw4_tab_col_q; logic [0:0] tw4_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw4_tab_wd_q;
    always_ff @(posedge clk) begin tw4_tab_hit_q <= tw4_tab_hit; tw4_tab_col_q <= tw4_tab_col; tw4_tab_wa_q <= tw4_tab_wa; tw4_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab19 tw4_tab (.clk(clk), .addr({mx_64}), .we(tw4_tab_hit_q), .wa(tw4_tab_wa_q), .wcol(tw4_tab_col_q), .wd(tw4_tab_wd_q), .q0(tw4_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw4_mul (.clk(clk), .A(s4_o4), .B(tw4_w), .QH(twq_QH), .P(tw4_p));
    logic [59:0] tw5_w; logic [59:0] tw5_p;
    logic tw5_tab_hit_c, tw5_tab_hit; logic [6:0] tw5_tab_rel;
    assign tw5_tab_rel = tw_wi - 7'd40;
    assign tw5_tab_hit_c = tw_wen_p && (tw_wi >= 7'd40) && (tw_wi < 7'd42);
    logic [0:0] tw5_tab_col_c, tw5_tab_col; logic [0:0] tw5_tab_wa_c, tw5_tab_wa;
    assign tw5_tab_col_c = '0; assign tw5_tab_wa_c = tw5_tab_rel[0:0];
    always_ff @(posedge clk) begin tw5_tab_hit <= tw5_tab_hit_c; tw5_tab_col <= tw5_tab_col_c; tw5_tab_wa <= tw5_tab_wa_c; end
    logic tw5_tab_hit_q; logic [0:0] tw5_tab_col_q; logic [0:0] tw5_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw5_tab_wd_q;
    always_ff @(posedge clk) begin tw5_tab_hit_q <= tw5_tab_hit; tw5_tab_col_q <= tw5_tab_col; tw5_tab_wa_q <= tw5_tab_wa; tw5_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab20 tw5_tab (.clk(clk), .addr({mx_64}), .we(tw5_tab_hit_q), .wa(tw5_tab_wa_q), .wcol(tw5_tab_col_q), .wd(tw5_tab_wd_q), .q0(tw5_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw5_mul (.clk(clk), .A(s4_o5), .B(tw5_w), .QH(twq_QH), .P(tw5_p));
    logic [59:0] tw6_w; logic [59:0] tw6_p;
    logic tw6_tab_hit_c, tw6_tab_hit; logic [6:0] tw6_tab_rel;
    assign tw6_tab_rel = tw_wi - 7'd42;
    assign tw6_tab_hit_c = tw_wen_p && (tw_wi >= 7'd42) && (tw_wi < 7'd44);
    logic [0:0] tw6_tab_col_c, tw6_tab_col; logic [0:0] tw6_tab_wa_c, tw6_tab_wa;
    assign tw6_tab_col_c = '0; assign tw6_tab_wa_c = tw6_tab_rel[0:0];
    always_ff @(posedge clk) begin tw6_tab_hit <= tw6_tab_hit_c; tw6_tab_col <= tw6_tab_col_c; tw6_tab_wa <= tw6_tab_wa_c; end
    logic tw6_tab_hit_q; logic [0:0] tw6_tab_col_q; logic [0:0] tw6_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw6_tab_wd_q;
    always_ff @(posedge clk) begin tw6_tab_hit_q <= tw6_tab_hit; tw6_tab_col_q <= tw6_tab_col; tw6_tab_wa_q <= tw6_tab_wa; tw6_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab21 tw6_tab (.clk(clk), .addr({mx_64}), .we(tw6_tab_hit_q), .wa(tw6_tab_wa_q), .wcol(tw6_tab_col_q), .wd(tw6_tab_wd_q), .q0(tw6_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw6_mul (.clk(clk), .A(s4_o6), .B(tw6_w), .QH(twq_QH), .P(tw6_p));
    logic [59:0] tw7_w; logic [59:0] tw7_p;
    logic tw7_tab_hit_c, tw7_tab_hit; logic [6:0] tw7_tab_rel;
    assign tw7_tab_rel = tw_wi - 7'd44;
    assign tw7_tab_hit_c = tw_wen_p && (tw_wi >= 7'd44) && (tw_wi < 7'd46);
    logic [0:0] tw7_tab_col_c, tw7_tab_col; logic [0:0] tw7_tab_wa_c, tw7_tab_wa;
    assign tw7_tab_col_c = '0; assign tw7_tab_wa_c = tw7_tab_rel[0:0];
    always_ff @(posedge clk) begin tw7_tab_hit <= tw7_tab_hit_c; tw7_tab_col <= tw7_tab_col_c; tw7_tab_wa <= tw7_tab_wa_c; end
    logic tw7_tab_hit_q; logic [0:0] tw7_tab_col_q; logic [0:0] tw7_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw7_tab_wd_q;
    always_ff @(posedge clk) begin tw7_tab_hit_q <= tw7_tab_hit; tw7_tab_col_q <= tw7_tab_col; tw7_tab_wa_q <= tw7_tab_wa; tw7_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab22 tw7_tab (.clk(clk), .addr({mx_64}), .we(tw7_tab_hit_q), .wa(tw7_tab_wa_q), .wcol(tw7_tab_col_q), .wd(tw7_tab_wd_q), .q0(tw7_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw7_mul (.clk(clk), .A(s4_o7), .B(tw7_w), .QH(twq_QH), .P(tw7_p));
    logic [59:0] tw8_w; logic [59:0] tw8_p;
    logic tw8_tab_hit_c, tw8_tab_hit; logic [6:0] tw8_tab_rel;
    assign tw8_tab_rel = tw_wi - 7'd46;
    assign tw8_tab_hit_c = tw_wen_p && (tw_wi >= 7'd46) && (tw_wi < 7'd48);
    logic [0:0] tw8_tab_col_c, tw8_tab_col; logic [0:0] tw8_tab_wa_c, tw8_tab_wa;
    assign tw8_tab_col_c = '0; assign tw8_tab_wa_c = tw8_tab_rel[0:0];
    always_ff @(posedge clk) begin tw8_tab_hit <= tw8_tab_hit_c; tw8_tab_col <= tw8_tab_col_c; tw8_tab_wa <= tw8_tab_wa_c; end
    logic tw8_tab_hit_q; logic [0:0] tw8_tab_col_q; logic [0:0] tw8_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw8_tab_wd_q;
    always_ff @(posedge clk) begin tw8_tab_hit_q <= tw8_tab_hit; tw8_tab_col_q <= tw8_tab_col; tw8_tab_wa_q <= tw8_tab_wa; tw8_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab23 tw8_tab (.clk(clk), .addr({mx_64}), .we(tw8_tab_hit_q), .wa(tw8_tab_wa_q), .wcol(tw8_tab_col_q), .wd(tw8_tab_wd_q), .q0(tw8_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw8_mul (.clk(clk), .A(s4_o8), .B(tw8_w), .QH(twq_QH), .P(tw8_p));
    logic [59:0] tw9_w; logic [59:0] tw9_p;
    logic tw9_tab_hit_c, tw9_tab_hit; logic [6:0] tw9_tab_rel;
    assign tw9_tab_rel = tw_wi - 7'd48;
    assign tw9_tab_hit_c = tw_wen_p && (tw_wi >= 7'd48) && (tw_wi < 7'd50);
    logic [0:0] tw9_tab_col_c, tw9_tab_col; logic [0:0] tw9_tab_wa_c, tw9_tab_wa;
    assign tw9_tab_col_c = '0; assign tw9_tab_wa_c = tw9_tab_rel[0:0];
    always_ff @(posedge clk) begin tw9_tab_hit <= tw9_tab_hit_c; tw9_tab_col <= tw9_tab_col_c; tw9_tab_wa <= tw9_tab_wa_c; end
    logic tw9_tab_hit_q; logic [0:0] tw9_tab_col_q; logic [0:0] tw9_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw9_tab_wd_q;
    always_ff @(posedge clk) begin tw9_tab_hit_q <= tw9_tab_hit; tw9_tab_col_q <= tw9_tab_col; tw9_tab_wa_q <= tw9_tab_wa; tw9_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab24 tw9_tab (.clk(clk), .addr({mx_64}), .we(tw9_tab_hit_q), .wa(tw9_tab_wa_q), .wcol(tw9_tab_col_q), .wd(tw9_tab_wd_q), .q0(tw9_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw9_mul (.clk(clk), .A(s4_o9), .B(tw9_w), .QH(twq_QH), .P(tw9_p));
    logic [59:0] tw10_w; logic [59:0] tw10_p;
    logic tw10_tab_hit_c, tw10_tab_hit; logic [6:0] tw10_tab_rel;
    assign tw10_tab_rel = tw_wi - 7'd50;
    assign tw10_tab_hit_c = tw_wen_p && (tw_wi >= 7'd50) && (tw_wi < 7'd52);
    logic [0:0] tw10_tab_col_c, tw10_tab_col; logic [0:0] tw10_tab_wa_c, tw10_tab_wa;
    assign tw10_tab_col_c = '0; assign tw10_tab_wa_c = tw10_tab_rel[0:0];
    always_ff @(posedge clk) begin tw10_tab_hit <= tw10_tab_hit_c; tw10_tab_col <= tw10_tab_col_c; tw10_tab_wa <= tw10_tab_wa_c; end
    logic tw10_tab_hit_q; logic [0:0] tw10_tab_col_q; logic [0:0] tw10_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw10_tab_wd_q;
    always_ff @(posedge clk) begin tw10_tab_hit_q <= tw10_tab_hit; tw10_tab_col_q <= tw10_tab_col; tw10_tab_wa_q <= tw10_tab_wa; tw10_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab25 tw10_tab (.clk(clk), .addr({mx_64}), .we(tw10_tab_hit_q), .wa(tw10_tab_wa_q), .wcol(tw10_tab_col_q), .wd(tw10_tab_wd_q), .q0(tw10_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw10_mul (.clk(clk), .A(s4_o10), .B(tw10_w), .QH(twq_QH), .P(tw10_p));
    logic [59:0] tw11_w; logic [59:0] tw11_p;
    logic tw11_tab_hit_c, tw11_tab_hit; logic [6:0] tw11_tab_rel;
    assign tw11_tab_rel = tw_wi - 7'd52;
    assign tw11_tab_hit_c = tw_wen_p && (tw_wi >= 7'd52) && (tw_wi < 7'd54);
    logic [0:0] tw11_tab_col_c, tw11_tab_col; logic [0:0] tw11_tab_wa_c, tw11_tab_wa;
    assign tw11_tab_col_c = '0; assign tw11_tab_wa_c = tw11_tab_rel[0:0];
    always_ff @(posedge clk) begin tw11_tab_hit <= tw11_tab_hit_c; tw11_tab_col <= tw11_tab_col_c; tw11_tab_wa <= tw11_tab_wa_c; end
    logic tw11_tab_hit_q; logic [0:0] tw11_tab_col_q; logic [0:0] tw11_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw11_tab_wd_q;
    always_ff @(posedge clk) begin tw11_tab_hit_q <= tw11_tab_hit; tw11_tab_col_q <= tw11_tab_col; tw11_tab_wa_q <= tw11_tab_wa; tw11_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab26 tw11_tab (.clk(clk), .addr({mx_64}), .we(tw11_tab_hit_q), .wa(tw11_tab_wa_q), .wcol(tw11_tab_col_q), .wd(tw11_tab_wd_q), .q0(tw11_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw11_mul (.clk(clk), .A(s4_o11), .B(tw11_w), .QH(twq_QH), .P(tw11_p));
    logic [59:0] tw12_w; logic [59:0] tw12_p;
    logic tw12_tab_hit_c, tw12_tab_hit; logic [6:0] tw12_tab_rel;
    assign tw12_tab_rel = tw_wi - 7'd54;
    assign tw12_tab_hit_c = tw_wen_p && (tw_wi >= 7'd54) && (tw_wi < 7'd56);
    logic [0:0] tw12_tab_col_c, tw12_tab_col; logic [0:0] tw12_tab_wa_c, tw12_tab_wa;
    assign tw12_tab_col_c = '0; assign tw12_tab_wa_c = tw12_tab_rel[0:0];
    always_ff @(posedge clk) begin tw12_tab_hit <= tw12_tab_hit_c; tw12_tab_col <= tw12_tab_col_c; tw12_tab_wa <= tw12_tab_wa_c; end
    logic tw12_tab_hit_q; logic [0:0] tw12_tab_col_q; logic [0:0] tw12_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw12_tab_wd_q;
    always_ff @(posedge clk) begin tw12_tab_hit_q <= tw12_tab_hit; tw12_tab_col_q <= tw12_tab_col; tw12_tab_wa_q <= tw12_tab_wa; tw12_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab27 tw12_tab (.clk(clk), .addr({mx_64}), .we(tw12_tab_hit_q), .wa(tw12_tab_wa_q), .wcol(tw12_tab_col_q), .wd(tw12_tab_wd_q), .q0(tw12_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw12_mul (.clk(clk), .A(s4_o12), .B(tw12_w), .QH(twq_QH), .P(tw12_p));
    logic [59:0] tw13_w; logic [59:0] tw13_p;
    logic tw13_tab_hit_c, tw13_tab_hit; logic [6:0] tw13_tab_rel;
    assign tw13_tab_rel = tw_wi - 7'd56;
    assign tw13_tab_hit_c = tw_wen_p && (tw_wi >= 7'd56) && (tw_wi < 7'd58);
    logic [0:0] tw13_tab_col_c, tw13_tab_col; logic [0:0] tw13_tab_wa_c, tw13_tab_wa;
    assign tw13_tab_col_c = '0; assign tw13_tab_wa_c = tw13_tab_rel[0:0];
    always_ff @(posedge clk) begin tw13_tab_hit <= tw13_tab_hit_c; tw13_tab_col <= tw13_tab_col_c; tw13_tab_wa <= tw13_tab_wa_c; end
    logic tw13_tab_hit_q; logic [0:0] tw13_tab_col_q; logic [0:0] tw13_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw13_tab_wd_q;
    always_ff @(posedge clk) begin tw13_tab_hit_q <= tw13_tab_hit; tw13_tab_col_q <= tw13_tab_col; tw13_tab_wa_q <= tw13_tab_wa; tw13_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab28 tw13_tab (.clk(clk), .addr({mx_64}), .we(tw13_tab_hit_q), .wa(tw13_tab_wa_q), .wcol(tw13_tab_col_q), .wd(tw13_tab_wd_q), .q0(tw13_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw13_mul (.clk(clk), .A(s4_o13), .B(tw13_w), .QH(twq_QH), .P(tw13_p));
    logic [59:0] tw14_w; logic [59:0] tw14_p;
    logic tw14_tab_hit_c, tw14_tab_hit; logic [6:0] tw14_tab_rel;
    assign tw14_tab_rel = tw_wi - 7'd58;
    assign tw14_tab_hit_c = tw_wen_p && (tw_wi >= 7'd58) && (tw_wi < 7'd60);
    logic [0:0] tw14_tab_col_c, tw14_tab_col; logic [0:0] tw14_tab_wa_c, tw14_tab_wa;
    assign tw14_tab_col_c = '0; assign tw14_tab_wa_c = tw14_tab_rel[0:0];
    always_ff @(posedge clk) begin tw14_tab_hit <= tw14_tab_hit_c; tw14_tab_col <= tw14_tab_col_c; tw14_tab_wa <= tw14_tab_wa_c; end
    logic tw14_tab_hit_q; logic [0:0] tw14_tab_col_q; logic [0:0] tw14_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw14_tab_wd_q;
    always_ff @(posedge clk) begin tw14_tab_hit_q <= tw14_tab_hit; tw14_tab_col_q <= tw14_tab_col; tw14_tab_wa_q <= tw14_tab_wa; tw14_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab29 tw14_tab (.clk(clk), .addr({mx_64}), .we(tw14_tab_hit_q), .wa(tw14_tab_wa_q), .wcol(tw14_tab_col_q), .wd(tw14_tab_wd_q), .q0(tw14_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw14_mul (.clk(clk), .A(s4_o14), .B(tw14_w), .QH(twq_QH), .P(tw14_p));
    logic [59:0] tw15_w; logic [59:0] tw15_p;
    logic tw15_tab_hit_c, tw15_tab_hit; logic [6:0] tw15_tab_rel;
    assign tw15_tab_rel = tw_wi - 7'd60;
    assign tw15_tab_hit_c = tw_wen_p && (tw_wi >= 7'd60) && (tw_wi < 7'd62);
    logic [0:0] tw15_tab_col_c, tw15_tab_col; logic [0:0] tw15_tab_wa_c, tw15_tab_wa;
    assign tw15_tab_col_c = '0; assign tw15_tab_wa_c = tw15_tab_rel[0:0];
    always_ff @(posedge clk) begin tw15_tab_hit <= tw15_tab_hit_c; tw15_tab_col <= tw15_tab_col_c; tw15_tab_wa <= tw15_tab_wa_c; end
    logic tw15_tab_hit_q; logic [0:0] tw15_tab_col_q; logic [0:0] tw15_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw15_tab_wd_q;
    always_ff @(posedge clk) begin tw15_tab_hit_q <= tw15_tab_hit; tw15_tab_col_q <= tw15_tab_col; tw15_tab_wa_q <= tw15_tab_wa; tw15_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab30 tw15_tab (.clk(clk), .addr({mx_64}), .we(tw15_tab_hit_q), .wa(tw15_tab_wa_q), .wcol(tw15_tab_col_q), .wd(tw15_tab_wd_q), .q0(tw15_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw15_mul (.clk(clk), .A(s4_o15), .B(tw15_w), .QH(twq_QH), .P(tw15_p));
    logic [59:0] tw16_w; logic [59:0] tw16_p;
    logic tw16_tab_hit_c, tw16_tab_hit; logic [6:0] tw16_tab_rel;
    assign tw16_tab_rel = tw_wi - 7'd62;
    assign tw16_tab_hit_c = tw_wen_p && (tw_wi >= 7'd62) && (tw_wi < 7'd64);
    logic [0:0] tw16_tab_col_c, tw16_tab_col; logic [0:0] tw16_tab_wa_c, tw16_tab_wa;
    assign tw16_tab_col_c = '0; assign tw16_tab_wa_c = tw16_tab_rel[0:0];
    always_ff @(posedge clk) begin tw16_tab_hit <= tw16_tab_hit_c; tw16_tab_col <= tw16_tab_col_c; tw16_tab_wa <= tw16_tab_wa_c; end
    logic tw16_tab_hit_q; logic [0:0] tw16_tab_col_q; logic [0:0] tw16_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw16_tab_wd_q;
    always_ff @(posedge clk) begin tw16_tab_hit_q <= tw16_tab_hit; tw16_tab_col_q <= tw16_tab_col; tw16_tab_wa_q <= tw16_tab_wa; tw16_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab31 tw16_tab (.clk(clk), .addr({mx_64}), .we(tw16_tab_hit_q), .wa(tw16_tab_wa_q), .wcol(tw16_tab_col_q), .wd(tw16_tab_wd_q), .q0(tw16_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw16_mul (.clk(clk), .A(s4_o16), .B(tw16_w), .QH(twq_QH), .P(tw16_p));
    logic [59:0] tw17_w; logic [59:0] tw17_p;
    logic tw17_tab_hit_c, tw17_tab_hit; logic [6:0] tw17_tab_rel;
    assign tw17_tab_rel = tw_wi - 7'd64;
    assign tw17_tab_hit_c = tw_wen_p && (tw_wi >= 7'd64) && (tw_wi < 7'd66);
    logic [0:0] tw17_tab_col_c, tw17_tab_col; logic [0:0] tw17_tab_wa_c, tw17_tab_wa;
    assign tw17_tab_col_c = '0; assign tw17_tab_wa_c = tw17_tab_rel[0:0];
    always_ff @(posedge clk) begin tw17_tab_hit <= tw17_tab_hit_c; tw17_tab_col <= tw17_tab_col_c; tw17_tab_wa <= tw17_tab_wa_c; end
    logic tw17_tab_hit_q; logic [0:0] tw17_tab_col_q; logic [0:0] tw17_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw17_tab_wd_q;
    always_ff @(posedge clk) begin tw17_tab_hit_q <= tw17_tab_hit; tw17_tab_col_q <= tw17_tab_col; tw17_tab_wa_q <= tw17_tab_wa; tw17_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab32 tw17_tab (.clk(clk), .addr({mx_64}), .we(tw17_tab_hit_q), .wa(tw17_tab_wa_q), .wcol(tw17_tab_col_q), .wd(tw17_tab_wd_q), .q0(tw17_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw17_mul (.clk(clk), .A(s4_o17), .B(tw17_w), .QH(twq_QH), .P(tw17_p));
    logic [59:0] tw18_w; logic [59:0] tw18_p;
    logic tw18_tab_hit_c, tw18_tab_hit; logic [6:0] tw18_tab_rel;
    assign tw18_tab_rel = tw_wi - 7'd66;
    assign tw18_tab_hit_c = tw_wen_p && (tw_wi >= 7'd66) && (tw_wi < 7'd68);
    logic [0:0] tw18_tab_col_c, tw18_tab_col; logic [0:0] tw18_tab_wa_c, tw18_tab_wa;
    assign tw18_tab_col_c = '0; assign tw18_tab_wa_c = tw18_tab_rel[0:0];
    always_ff @(posedge clk) begin tw18_tab_hit <= tw18_tab_hit_c; tw18_tab_col <= tw18_tab_col_c; tw18_tab_wa <= tw18_tab_wa_c; end
    logic tw18_tab_hit_q; logic [0:0] tw18_tab_col_q; logic [0:0] tw18_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw18_tab_wd_q;
    always_ff @(posedge clk) begin tw18_tab_hit_q <= tw18_tab_hit; tw18_tab_col_q <= tw18_tab_col; tw18_tab_wa_q <= tw18_tab_wa; tw18_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab33 tw18_tab (.clk(clk), .addr({mx_64}), .we(tw18_tab_hit_q), .wa(tw18_tab_wa_q), .wcol(tw18_tab_col_q), .wd(tw18_tab_wd_q), .q0(tw18_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw18_mul (.clk(clk), .A(s4_o18), .B(tw18_w), .QH(twq_QH), .P(tw18_p));
    logic [59:0] tw19_w; logic [59:0] tw19_p;
    logic tw19_tab_hit_c, tw19_tab_hit; logic [6:0] tw19_tab_rel;
    assign tw19_tab_rel = tw_wi - 7'd68;
    assign tw19_tab_hit_c = tw_wen_p && (tw_wi >= 7'd68) && (tw_wi < 7'd70);
    logic [0:0] tw19_tab_col_c, tw19_tab_col; logic [0:0] tw19_tab_wa_c, tw19_tab_wa;
    assign tw19_tab_col_c = '0; assign tw19_tab_wa_c = tw19_tab_rel[0:0];
    always_ff @(posedge clk) begin tw19_tab_hit <= tw19_tab_hit_c; tw19_tab_col <= tw19_tab_col_c; tw19_tab_wa <= tw19_tab_wa_c; end
    logic tw19_tab_hit_q; logic [0:0] tw19_tab_col_q; logic [0:0] tw19_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw19_tab_wd_q;
    always_ff @(posedge clk) begin tw19_tab_hit_q <= tw19_tab_hit; tw19_tab_col_q <= tw19_tab_col; tw19_tab_wa_q <= tw19_tab_wa; tw19_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab34 tw19_tab (.clk(clk), .addr({mx_64}), .we(tw19_tab_hit_q), .wa(tw19_tab_wa_q), .wcol(tw19_tab_col_q), .wd(tw19_tab_wd_q), .q0(tw19_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw19_mul (.clk(clk), .A(s4_o19), .B(tw19_w), .QH(twq_QH), .P(tw19_p));
    logic [59:0] tw20_w; logic [59:0] tw20_p;
    logic tw20_tab_hit_c, tw20_tab_hit; logic [6:0] tw20_tab_rel;
    assign tw20_tab_rel = tw_wi - 7'd70;
    assign tw20_tab_hit_c = tw_wen_p && (tw_wi >= 7'd70) && (tw_wi < 7'd72);
    logic [0:0] tw20_tab_col_c, tw20_tab_col; logic [0:0] tw20_tab_wa_c, tw20_tab_wa;
    assign tw20_tab_col_c = '0; assign tw20_tab_wa_c = tw20_tab_rel[0:0];
    always_ff @(posedge clk) begin tw20_tab_hit <= tw20_tab_hit_c; tw20_tab_col <= tw20_tab_col_c; tw20_tab_wa <= tw20_tab_wa_c; end
    logic tw20_tab_hit_q; logic [0:0] tw20_tab_col_q; logic [0:0] tw20_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw20_tab_wd_q;
    always_ff @(posedge clk) begin tw20_tab_hit_q <= tw20_tab_hit; tw20_tab_col_q <= tw20_tab_col; tw20_tab_wa_q <= tw20_tab_wa; tw20_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab35 tw20_tab (.clk(clk), .addr({mx_64}), .we(tw20_tab_hit_q), .wa(tw20_tab_wa_q), .wcol(tw20_tab_col_q), .wd(tw20_tab_wd_q), .q0(tw20_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw20_mul (.clk(clk), .A(s4_o20), .B(tw20_w), .QH(twq_QH), .P(tw20_p));
    logic [59:0] tw21_w; logic [59:0] tw21_p;
    logic tw21_tab_hit_c, tw21_tab_hit; logic [6:0] tw21_tab_rel;
    assign tw21_tab_rel = tw_wi - 7'd72;
    assign tw21_tab_hit_c = tw_wen_p && (tw_wi >= 7'd72) && (tw_wi < 7'd74);
    logic [0:0] tw21_tab_col_c, tw21_tab_col; logic [0:0] tw21_tab_wa_c, tw21_tab_wa;
    assign tw21_tab_col_c = '0; assign tw21_tab_wa_c = tw21_tab_rel[0:0];
    always_ff @(posedge clk) begin tw21_tab_hit <= tw21_tab_hit_c; tw21_tab_col <= tw21_tab_col_c; tw21_tab_wa <= tw21_tab_wa_c; end
    logic tw21_tab_hit_q; logic [0:0] tw21_tab_col_q; logic [0:0] tw21_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw21_tab_wd_q;
    always_ff @(posedge clk) begin tw21_tab_hit_q <= tw21_tab_hit; tw21_tab_col_q <= tw21_tab_col; tw21_tab_wa_q <= tw21_tab_wa; tw21_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab36 tw21_tab (.clk(clk), .addr({mx_64}), .we(tw21_tab_hit_q), .wa(tw21_tab_wa_q), .wcol(tw21_tab_col_q), .wd(tw21_tab_wd_q), .q0(tw21_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw21_mul (.clk(clk), .A(s4_o21), .B(tw21_w), .QH(twq_QH), .P(tw21_p));
    logic [59:0] tw22_w; logic [59:0] tw22_p;
    logic tw22_tab_hit_c, tw22_tab_hit; logic [6:0] tw22_tab_rel;
    assign tw22_tab_rel = tw_wi - 7'd74;
    assign tw22_tab_hit_c = tw_wen_p && (tw_wi >= 7'd74) && (tw_wi < 7'd76);
    logic [0:0] tw22_tab_col_c, tw22_tab_col; logic [0:0] tw22_tab_wa_c, tw22_tab_wa;
    assign tw22_tab_col_c = '0; assign tw22_tab_wa_c = tw22_tab_rel[0:0];
    always_ff @(posedge clk) begin tw22_tab_hit <= tw22_tab_hit_c; tw22_tab_col <= tw22_tab_col_c; tw22_tab_wa <= tw22_tab_wa_c; end
    logic tw22_tab_hit_q; logic [0:0] tw22_tab_col_q; logic [0:0] tw22_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw22_tab_wd_q;
    always_ff @(posedge clk) begin tw22_tab_hit_q <= tw22_tab_hit; tw22_tab_col_q <= tw22_tab_col; tw22_tab_wa_q <= tw22_tab_wa; tw22_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab37 tw22_tab (.clk(clk), .addr({mx_64}), .we(tw22_tab_hit_q), .wa(tw22_tab_wa_q), .wcol(tw22_tab_col_q), .wd(tw22_tab_wd_q), .q0(tw22_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw22_mul (.clk(clk), .A(s4_o22), .B(tw22_w), .QH(twq_QH), .P(tw22_p));
    logic [59:0] tw23_w; logic [59:0] tw23_p;
    logic tw23_tab_hit_c, tw23_tab_hit; logic [6:0] tw23_tab_rel;
    assign tw23_tab_rel = tw_wi - 7'd76;
    assign tw23_tab_hit_c = tw_wen_p && (tw_wi >= 7'd76) && (tw_wi < 7'd78);
    logic [0:0] tw23_tab_col_c, tw23_tab_col; logic [0:0] tw23_tab_wa_c, tw23_tab_wa;
    assign tw23_tab_col_c = '0; assign tw23_tab_wa_c = tw23_tab_rel[0:0];
    always_ff @(posedge clk) begin tw23_tab_hit <= tw23_tab_hit_c; tw23_tab_col <= tw23_tab_col_c; tw23_tab_wa <= tw23_tab_wa_c; end
    logic tw23_tab_hit_q; logic [0:0] tw23_tab_col_q; logic [0:0] tw23_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw23_tab_wd_q;
    always_ff @(posedge clk) begin tw23_tab_hit_q <= tw23_tab_hit; tw23_tab_col_q <= tw23_tab_col; tw23_tab_wa_q <= tw23_tab_wa; tw23_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab38 tw23_tab (.clk(clk), .addr({mx_64}), .we(tw23_tab_hit_q), .wa(tw23_tab_wa_q), .wcol(tw23_tab_col_q), .wd(tw23_tab_wd_q), .q0(tw23_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw23_mul (.clk(clk), .A(s4_o23), .B(tw23_w), .QH(twq_QH), .P(tw23_p));
    logic [59:0] tw24_w; logic [59:0] tw24_p;
    logic tw24_tab_hit_c, tw24_tab_hit; logic [6:0] tw24_tab_rel;
    assign tw24_tab_rel = tw_wi - 7'd78;
    assign tw24_tab_hit_c = tw_wen_p && (tw_wi >= 7'd78) && (tw_wi < 7'd80);
    logic [0:0] tw24_tab_col_c, tw24_tab_col; logic [0:0] tw24_tab_wa_c, tw24_tab_wa;
    assign tw24_tab_col_c = '0; assign tw24_tab_wa_c = tw24_tab_rel[0:0];
    always_ff @(posedge clk) begin tw24_tab_hit <= tw24_tab_hit_c; tw24_tab_col <= tw24_tab_col_c; tw24_tab_wa <= tw24_tab_wa_c; end
    logic tw24_tab_hit_q; logic [0:0] tw24_tab_col_q; logic [0:0] tw24_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw24_tab_wd_q;
    always_ff @(posedge clk) begin tw24_tab_hit_q <= tw24_tab_hit; tw24_tab_col_q <= tw24_tab_col; tw24_tab_wa_q <= tw24_tab_wa; tw24_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab39 tw24_tab (.clk(clk), .addr({mx_64}), .we(tw24_tab_hit_q), .wa(tw24_tab_wa_q), .wcol(tw24_tab_col_q), .wd(tw24_tab_wd_q), .q0(tw24_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw24_mul (.clk(clk), .A(s4_o24), .B(tw24_w), .QH(twq_QH), .P(tw24_p));
    logic [59:0] tw25_w; logic [59:0] tw25_p;
    logic tw25_tab_hit_c, tw25_tab_hit; logic [6:0] tw25_tab_rel;
    assign tw25_tab_rel = tw_wi - 7'd80;
    assign tw25_tab_hit_c = tw_wen_p && (tw_wi >= 7'd80) && (tw_wi < 7'd82);
    logic [0:0] tw25_tab_col_c, tw25_tab_col; logic [0:0] tw25_tab_wa_c, tw25_tab_wa;
    assign tw25_tab_col_c = '0; assign tw25_tab_wa_c = tw25_tab_rel[0:0];
    always_ff @(posedge clk) begin tw25_tab_hit <= tw25_tab_hit_c; tw25_tab_col <= tw25_tab_col_c; tw25_tab_wa <= tw25_tab_wa_c; end
    logic tw25_tab_hit_q; logic [0:0] tw25_tab_col_q; logic [0:0] tw25_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw25_tab_wd_q;
    always_ff @(posedge clk) begin tw25_tab_hit_q <= tw25_tab_hit; tw25_tab_col_q <= tw25_tab_col; tw25_tab_wa_q <= tw25_tab_wa; tw25_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab40 tw25_tab (.clk(clk), .addr({mx_64}), .we(tw25_tab_hit_q), .wa(tw25_tab_wa_q), .wcol(tw25_tab_col_q), .wd(tw25_tab_wd_q), .q0(tw25_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw25_mul (.clk(clk), .A(s4_o25), .B(tw25_w), .QH(twq_QH), .P(tw25_p));
    logic [59:0] tw26_w; logic [59:0] tw26_p;
    logic tw26_tab_hit_c, tw26_tab_hit; logic [6:0] tw26_tab_rel;
    assign tw26_tab_rel = tw_wi - 7'd82;
    assign tw26_tab_hit_c = tw_wen_p && (tw_wi >= 7'd82) && (tw_wi < 7'd84);
    logic [0:0] tw26_tab_col_c, tw26_tab_col; logic [0:0] tw26_tab_wa_c, tw26_tab_wa;
    assign tw26_tab_col_c = '0; assign tw26_tab_wa_c = tw26_tab_rel[0:0];
    always_ff @(posedge clk) begin tw26_tab_hit <= tw26_tab_hit_c; tw26_tab_col <= tw26_tab_col_c; tw26_tab_wa <= tw26_tab_wa_c; end
    logic tw26_tab_hit_q; logic [0:0] tw26_tab_col_q; logic [0:0] tw26_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw26_tab_wd_q;
    always_ff @(posedge clk) begin tw26_tab_hit_q <= tw26_tab_hit; tw26_tab_col_q <= tw26_tab_col; tw26_tab_wa_q <= tw26_tab_wa; tw26_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab41 tw26_tab (.clk(clk), .addr({mx_64}), .we(tw26_tab_hit_q), .wa(tw26_tab_wa_q), .wcol(tw26_tab_col_q), .wd(tw26_tab_wd_q), .q0(tw26_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw26_mul (.clk(clk), .A(s4_o26), .B(tw26_w), .QH(twq_QH), .P(tw26_p));
    logic [59:0] tw27_w; logic [59:0] tw27_p;
    logic tw27_tab_hit_c, tw27_tab_hit; logic [6:0] tw27_tab_rel;
    assign tw27_tab_rel = tw_wi - 7'd84;
    assign tw27_tab_hit_c = tw_wen_p && (tw_wi >= 7'd84) && (tw_wi < 7'd86);
    logic [0:0] tw27_tab_col_c, tw27_tab_col; logic [0:0] tw27_tab_wa_c, tw27_tab_wa;
    assign tw27_tab_col_c = '0; assign tw27_tab_wa_c = tw27_tab_rel[0:0];
    always_ff @(posedge clk) begin tw27_tab_hit <= tw27_tab_hit_c; tw27_tab_col <= tw27_tab_col_c; tw27_tab_wa <= tw27_tab_wa_c; end
    logic tw27_tab_hit_q; logic [0:0] tw27_tab_col_q; logic [0:0] tw27_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw27_tab_wd_q;
    always_ff @(posedge clk) begin tw27_tab_hit_q <= tw27_tab_hit; tw27_tab_col_q <= tw27_tab_col; tw27_tab_wa_q <= tw27_tab_wa; tw27_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab42 tw27_tab (.clk(clk), .addr({mx_64}), .we(tw27_tab_hit_q), .wa(tw27_tab_wa_q), .wcol(tw27_tab_col_q), .wd(tw27_tab_wd_q), .q0(tw27_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw27_mul (.clk(clk), .A(s4_o27), .B(tw27_w), .QH(twq_QH), .P(tw27_p));
    logic [59:0] tw28_w; logic [59:0] tw28_p;
    logic tw28_tab_hit_c, tw28_tab_hit; logic [6:0] tw28_tab_rel;
    assign tw28_tab_rel = tw_wi - 7'd86;
    assign tw28_tab_hit_c = tw_wen_p && (tw_wi >= 7'd86) && (tw_wi < 7'd88);
    logic [0:0] tw28_tab_col_c, tw28_tab_col; logic [0:0] tw28_tab_wa_c, tw28_tab_wa;
    assign tw28_tab_col_c = '0; assign tw28_tab_wa_c = tw28_tab_rel[0:0];
    always_ff @(posedge clk) begin tw28_tab_hit <= tw28_tab_hit_c; tw28_tab_col <= tw28_tab_col_c; tw28_tab_wa <= tw28_tab_wa_c; end
    logic tw28_tab_hit_q; logic [0:0] tw28_tab_col_q; logic [0:0] tw28_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw28_tab_wd_q;
    always_ff @(posedge clk) begin tw28_tab_hit_q <= tw28_tab_hit; tw28_tab_col_q <= tw28_tab_col; tw28_tab_wa_q <= tw28_tab_wa; tw28_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab43 tw28_tab (.clk(clk), .addr({mx_64}), .we(tw28_tab_hit_q), .wa(tw28_tab_wa_q), .wcol(tw28_tab_col_q), .wd(tw28_tab_wd_q), .q0(tw28_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw28_mul (.clk(clk), .A(s4_o28), .B(tw28_w), .QH(twq_QH), .P(tw28_p));
    logic [59:0] tw29_w; logic [59:0] tw29_p;
    logic tw29_tab_hit_c, tw29_tab_hit; logic [6:0] tw29_tab_rel;
    assign tw29_tab_rel = tw_wi - 7'd88;
    assign tw29_tab_hit_c = tw_wen_p && (tw_wi >= 7'd88) && (tw_wi < 7'd90);
    logic [0:0] tw29_tab_col_c, tw29_tab_col; logic [0:0] tw29_tab_wa_c, tw29_tab_wa;
    assign tw29_tab_col_c = '0; assign tw29_tab_wa_c = tw29_tab_rel[0:0];
    always_ff @(posedge clk) begin tw29_tab_hit <= tw29_tab_hit_c; tw29_tab_col <= tw29_tab_col_c; tw29_tab_wa <= tw29_tab_wa_c; end
    logic tw29_tab_hit_q; logic [0:0] tw29_tab_col_q; logic [0:0] tw29_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw29_tab_wd_q;
    always_ff @(posedge clk) begin tw29_tab_hit_q <= tw29_tab_hit; tw29_tab_col_q <= tw29_tab_col; tw29_tab_wa_q <= tw29_tab_wa; tw29_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab44 tw29_tab (.clk(clk), .addr({mx_64}), .we(tw29_tab_hit_q), .wa(tw29_tab_wa_q), .wcol(tw29_tab_col_q), .wd(tw29_tab_wd_q), .q0(tw29_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw29_mul (.clk(clk), .A(s4_o29), .B(tw29_w), .QH(twq_QH), .P(tw29_p));
    logic [59:0] tw30_w; logic [59:0] tw30_p;
    logic tw30_tab_hit_c, tw30_tab_hit; logic [6:0] tw30_tab_rel;
    assign tw30_tab_rel = tw_wi - 7'd90;
    assign tw30_tab_hit_c = tw_wen_p && (tw_wi >= 7'd90) && (tw_wi < 7'd92);
    logic [0:0] tw30_tab_col_c, tw30_tab_col; logic [0:0] tw30_tab_wa_c, tw30_tab_wa;
    assign tw30_tab_col_c = '0; assign tw30_tab_wa_c = tw30_tab_rel[0:0];
    always_ff @(posedge clk) begin tw30_tab_hit <= tw30_tab_hit_c; tw30_tab_col <= tw30_tab_col_c; tw30_tab_wa <= tw30_tab_wa_c; end
    logic tw30_tab_hit_q; logic [0:0] tw30_tab_col_q; logic [0:0] tw30_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw30_tab_wd_q;
    always_ff @(posedge clk) begin tw30_tab_hit_q <= tw30_tab_hit; tw30_tab_col_q <= tw30_tab_col; tw30_tab_wa_q <= tw30_tab_wa; tw30_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab45 tw30_tab (.clk(clk), .addr({mx_64}), .we(tw30_tab_hit_q), .wa(tw30_tab_wa_q), .wcol(tw30_tab_col_q), .wd(tw30_tab_wd_q), .q0(tw30_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw30_mul (.clk(clk), .A(s4_o30), .B(tw30_w), .QH(twq_QH), .P(tw30_p));
    logic [59:0] tw31_w; logic [59:0] tw31_p;
    logic tw31_tab_hit_c, tw31_tab_hit; logic [6:0] tw31_tab_rel;
    assign tw31_tab_rel = tw_wi - 7'd92;
    assign tw31_tab_hit_c = tw_wen_p && (tw_wi >= 7'd92) && (tw_wi < 7'd94);
    logic [0:0] tw31_tab_col_c, tw31_tab_col; logic [0:0] tw31_tab_wa_c, tw31_tab_wa;
    assign tw31_tab_col_c = '0; assign tw31_tab_wa_c = tw31_tab_rel[0:0];
    always_ff @(posedge clk) begin tw31_tab_hit <= tw31_tab_hit_c; tw31_tab_col <= tw31_tab_col_c; tw31_tab_wa <= tw31_tab_wa_c; end
    logic tw31_tab_hit_q; logic [0:0] tw31_tab_col_q; logic [0:0] tw31_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] tw31_tab_wd_q;
    always_ff @(posedge clk) begin tw31_tab_hit_q <= tw31_tab_hit; tw31_tab_col_q <= tw31_tab_col; tw31_tab_wa_q <= tw31_tab_wa; tw31_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p3_core_tab46 tw31_tab (.clk(clk), .addr({mx_64}), .we(tw31_tab_hit_q), .wa(tw31_tab_wa_q), .wcol(tw31_tab_col_q), .wd(tw31_tab_wd_q), .q0(tw31_w));
    MS_N16_q60_P32_tpm_p3_core_twist tw31_mul (.clk(clk), .A(s4_o31), .B(tw31_w), .QH(twq_QH), .P(tw31_p));
    assign y_out_0 = tw0_p;
    assign y_out_1 = tw1_p;
    assign y_out_2 = tw2_p;
    assign y_out_3 = tw3_p;
    assign y_out_4 = tw4_p;
    assign y_out_5 = tw5_p;
    assign y_out_6 = tw6_p;
    assign y_out_7 = tw7_p;
    assign y_out_8 = tw8_p;
    assign y_out_9 = tw9_p;
    assign y_out_10 = tw10_p;
    assign y_out_11 = tw11_p;
    assign y_out_12 = tw12_p;
    assign y_out_13 = tw13_p;
    assign y_out_14 = tw14_p;
    assign y_out_15 = tw15_p;
    assign y_out_16 = tw16_p;
    assign y_out_17 = tw17_p;
    assign y_out_18 = tw18_p;
    assign y_out_19 = tw19_p;
    assign y_out_20 = tw20_p;
    assign y_out_21 = tw21_p;
    assign y_out_22 = tw22_p;
    assign y_out_23 = tw23_p;
    assign y_out_24 = tw24_p;
    assign y_out_25 = tw25_p;
    assign y_out_26 = tw26_p;
    assign y_out_27 = tw27_p;
    assign y_out_28 = tw28_p;
    assign y_out_29 = tw29_p;
    assign y_out_30 = tw30_p;
    assign y_out_31 = tw31_p;
endmodule
