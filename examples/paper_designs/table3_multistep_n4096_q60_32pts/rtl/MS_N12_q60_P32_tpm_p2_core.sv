`timescale 1ns / 1ps
// MS_N12_q60_P32_tpm_p2_core: streaming NTT, n=32, 32 lanes, frame 1 cycles, run-time q, direction both, latency 82
module MS_N12_q60_P32_tpm_p2_core (
    input  logic clk,
    input  logic rst,
    input  logic DIR,
    input  logic [16:0] QH,
    input  logic [59:0] QHALF,
    input  logic [59:0] tw_s0,
    input  logic [59:0] tw_s1,
    input  logic [59:0] tw_s2,
    input  logic [59:0] tw_s3,
    input  logic [59:0] tw_s4,
    input  logic [59:0] tw_s5,
    input  logic [59:0] tw_s6,
    input  logic [59:0] tw_s7,
    input  logic [59:0] tw_s8,
    input  logic [59:0] tw_s9,
    input  logic [59:0] tw_s10,
    input  logic [59:0] tw_s11,
    input  logic [59:0] tw_s12,
    input  logic [59:0] tw_s13,
    input  logic [59:0] tw_s14,
    input  logic [59:0] tw_s15,
    input  logic [59:0] tw_s16,
    input  logic [59:0] tw_s17,
    input  logic [59:0] tw_s18,
    input  logic [59:0] tw_s19,
    input  logic [59:0] tw_s20,
    input  logic [59:0] tw_s21,
    input  logic [59:0] tw_s22,
    input  logic [59:0] tw_s23,
    input  logic [59:0] tw_s24,
    input  logic [59:0] tw_s25,
    input  logic [59:0] tw_s26,
    input  logic [59:0] tw_s27,
    input  logic [59:0] tw_s28,
    input  logic [59:0] tw_s29,
    input  logic [59:0] tw_s30,
    input  logic [59:0] tw_s31,
    input  logic [59:0] tw_s32,
    input  logic [59:0] tw_s33,
    input  logic [59:0] tw_s34,
    input  logic [59:0] tw_s35,
    input  logic [59:0] tw_s36,
    input  logic [59:0] tw_s37,
    input  logic [59:0] tw_s38,
    input  logic [59:0] tw_s39,
    input  logic [59:0] tw_s40,
    input  logic [59:0] tw_s41,
    input  logic [59:0] tw_s42,
    input  logic [59:0] tw_s43,
    input  logic [59:0] tw_s44,
    input  logic [59:0] tw_s45,
    input  logic [59:0] tw_s46,
    input  logic [59:0] tw_s47,
    input  logic [59:0] tw_s48,
    input  logic [59:0] tw_s49,
    input  logic [59:0] tw_s50,
    input  logic [59:0] tw_s51,
    input  logic [59:0] tw_s52,
    input  logic [59:0] tw_s53,
    input  logic [59:0] tw_s54,
    input  logic [59:0] tw_s55,
    input  logic [59:0] tw_s56,
    input  logic [59:0] tw_s57,
    input  logic [59:0] tw_s58,
    input  logic [59:0] tw_s59,
    input  logic [59:0] tw_s60,
    input  logic [59:0] tw_s61,
    input  logic [59:0] tw_s62,
    input  logic [59:0] tw_s63,
    input  logic [59:0] tw_s64,
    input  logic [59:0] tw_s65,
    input  logic [59:0] tw_s66,
    input  logic [59:0] tw_s67,
    input  logic [59:0] tw_s68,
    input  logic [59:0] tw_s69,
    input  logic [59:0] tw_s70,
    input  logic [59:0] tw_s71,
    input  logic [59:0] tw_s72,
    input  logic [59:0] tw_s73,
    input  logic [59:0] tw_s74,
    input  logic [59:0] tw_s75,
    input  logic [59:0] tw_s76,
    input  logic [59:0] tw_s77,
    input  logic [59:0] tw_s78,
    input  logic [59:0] tw_s79,
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
    logic [0:0] mx_1;
    always_ff @(posedge clk) mx_1 <= DIR;
    // per-frame direction: input lead of 2 cycles
    logic [59:0] xl_0;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl0_dly (.clk(clk), .din(x_in_0), .dout(xl_0));
    logic [59:0] xl_1;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl1_dly (.clk(clk), .din(x_in_1), .dout(xl_1));
    logic [59:0] xl_2;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl2_dly (.clk(clk), .din(x_in_2), .dout(xl_2));
    logic [59:0] xl_3;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl3_dly (.clk(clk), .din(x_in_3), .dout(xl_3));
    logic [59:0] xl_4;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl4_dly (.clk(clk), .din(x_in_4), .dout(xl_4));
    logic [59:0] xl_5;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl5_dly (.clk(clk), .din(x_in_5), .dout(xl_5));
    logic [59:0] xl_6;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl6_dly (.clk(clk), .din(x_in_6), .dout(xl_6));
    logic [59:0] xl_7;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl7_dly (.clk(clk), .din(x_in_7), .dout(xl_7));
    logic [59:0] xl_8;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl8_dly (.clk(clk), .din(x_in_8), .dout(xl_8));
    logic [59:0] xl_9;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl9_dly (.clk(clk), .din(x_in_9), .dout(xl_9));
    logic [59:0] xl_10;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl10_dly (.clk(clk), .din(x_in_10), .dout(xl_10));
    logic [59:0] xl_11;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl11_dly (.clk(clk), .din(x_in_11), .dout(xl_11));
    logic [59:0] xl_12;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl12_dly (.clk(clk), .din(x_in_12), .dout(xl_12));
    logic [59:0] xl_13;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl13_dly (.clk(clk), .din(x_in_13), .dout(xl_13));
    logic [59:0] xl_14;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl14_dly (.clk(clk), .din(x_in_14), .dout(xl_14));
    logic [59:0] xl_15;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl15_dly (.clk(clk), .din(x_in_15), .dout(xl_15));
    logic [59:0] xl_16;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl16_dly (.clk(clk), .din(x_in_16), .dout(xl_16));
    logic [59:0] xl_17;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl17_dly (.clk(clk), .din(x_in_17), .dout(xl_17));
    logic [59:0] xl_18;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl18_dly (.clk(clk), .din(x_in_18), .dout(xl_18));
    logic [59:0] xl_19;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl19_dly (.clk(clk), .din(x_in_19), .dout(xl_19));
    logic [59:0] xl_20;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl20_dly (.clk(clk), .din(x_in_20), .dout(xl_20));
    logic [59:0] xl_21;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl21_dly (.clk(clk), .din(x_in_21), .dout(xl_21));
    logic [59:0] xl_22;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl22_dly (.clk(clk), .din(x_in_22), .dout(xl_22));
    logic [59:0] xl_23;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl23_dly (.clk(clk), .din(x_in_23), .dout(xl_23));
    logic [59:0] xl_24;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl24_dly (.clk(clk), .din(x_in_24), .dout(xl_24));
    logic [59:0] xl_25;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl25_dly (.clk(clk), .din(x_in_25), .dout(xl_25));
    logic [59:0] xl_26;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl26_dly (.clk(clk), .din(x_in_26), .dout(xl_26));
    logic [59:0] xl_27;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl27_dly (.clk(clk), .din(x_in_27), .dout(xl_27));
    logic [59:0] xl_28;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl28_dly (.clk(clk), .din(x_in_28), .dout(xl_28));
    logic [59:0] xl_29;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl29_dly (.clk(clk), .din(x_in_29), .dout(xl_29));
    logic [59:0] xl_30;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl30_dly (.clk(clk), .din(x_in_30), .dout(xl_30));
    logic [59:0] xl_31;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) xl31_dly (.clk(clk), .din(x_in_31), .dout(xl_31));
    (* max_fanout = 16 *) logic [16:0] QH_r;
    always_ff @(posedge clk) QH_r <= QH;
    (* max_fanout = 16 *) logic [59:0] QHALF_r;
    always_ff @(posedge clk) QHALF_r <= QHALF;
    // stage 0: 16 butterflies on lane pairs (bit 0), latency 15
    logic [59:0] tws0_o2;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) tws0_o2_dly (.clk(clk), .din(tw_s0), .dout(tws0_o2));
    (* max_fanout = 16 *) logic [16:0] s0q_QH;
    always_ff @(posedge clk) s0q_QH <= QH_r;
    logic [59:0] s0_k0_xr; logic [59:0] s0_k0_yr;
    MS_N12_q60_P32_tpm_p2_core_s0_bu s0_k0 (.clk(clk), .aIn(xl_0), .bIn(xl_1), .W(tws0_o2), .QH(s0q_QH), .aOut(s0_k0_xr), .bOut(s0_k0_yr));
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
    (* max_fanout = 16 *) logic [0:0] mx_6;
    always_ff @(posedge clk) mx_6 <= mx_5;
    (* max_fanout = 16 *) logic [0:0] mx_7;
    always_ff @(posedge clk) mx_7 <= mx_6;
    (* max_fanout = 16 *) logic [0:0] mx_8;
    always_ff @(posedge clk) mx_8 <= mx_7;
    (* max_fanout = 16 *) logic [0:0] mx_9;
    always_ff @(posedge clk) mx_9 <= mx_8;
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
    always_ff @(posedge clk) s0_o0_h <= mx_17[0] ? (60'(s0_o0_h_x >> 1) + (s0_o0_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o0_h_x;
    assign s0_o0 = s0_o0_h;
    logic [59:0] s0_o1;
    logic [59:0] s0_o1_h_x, s0_o1_h;
    assign s0_o1_h_x = s0_k0_yr;
    always_ff @(posedge clk) s0_o1_h <= mx_17[0] ? (60'(s0_o1_h_x >> 1) + (s0_o1_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o1_h_x;
    assign s0_o1 = s0_o1_h;
    logic [59:0] tws1_o2;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) tws1_o2_dly (.clk(clk), .din(tw_s1), .dout(tws1_o2));
    logic [59:0] s0_k1_xr; logic [59:0] s0_k1_yr;
    MS_N12_q60_P32_tpm_p2_core_s0_bu s0_k1 (.clk(clk), .aIn(xl_2), .bIn(xl_3), .W(tws1_o2), .QH(s0q_QH), .aOut(s0_k1_xr), .bOut(s0_k1_yr));
    logic [59:0] s0_o2;
    logic [59:0] s0_o2_h_x, s0_o2_h;
    assign s0_o2_h_x = s0_k1_xr;
    always_ff @(posedge clk) s0_o2_h <= mx_17[0] ? (60'(s0_o2_h_x >> 1) + (s0_o2_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o2_h_x;
    assign s0_o2 = s0_o2_h;
    logic [59:0] s0_o3;
    logic [59:0] s0_o3_h_x, s0_o3_h;
    assign s0_o3_h_x = s0_k1_yr;
    always_ff @(posedge clk) s0_o3_h <= mx_17[0] ? (60'(s0_o3_h_x >> 1) + (s0_o3_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o3_h_x;
    assign s0_o3 = s0_o3_h;
    logic [59:0] tws2_o2;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) tws2_o2_dly (.clk(clk), .din(tw_s2), .dout(tws2_o2));
    logic [59:0] s0_k2_xr; logic [59:0] s0_k2_yr;
    MS_N12_q60_P32_tpm_p2_core_s0_bu s0_k2 (.clk(clk), .aIn(xl_4), .bIn(xl_5), .W(tws2_o2), .QH(s0q_QH), .aOut(s0_k2_xr), .bOut(s0_k2_yr));
    logic [59:0] s0_o4;
    logic [59:0] s0_o4_h_x, s0_o4_h;
    assign s0_o4_h_x = s0_k2_xr;
    always_ff @(posedge clk) s0_o4_h <= mx_17[0] ? (60'(s0_o4_h_x >> 1) + (s0_o4_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o4_h_x;
    assign s0_o4 = s0_o4_h;
    logic [59:0] s0_o5;
    logic [59:0] s0_o5_h_x, s0_o5_h;
    assign s0_o5_h_x = s0_k2_yr;
    always_ff @(posedge clk) s0_o5_h <= mx_17[0] ? (60'(s0_o5_h_x >> 1) + (s0_o5_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o5_h_x;
    assign s0_o5 = s0_o5_h;
    logic [59:0] tws3_o2;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) tws3_o2_dly (.clk(clk), .din(tw_s3), .dout(tws3_o2));
    logic [59:0] s0_k3_xr; logic [59:0] s0_k3_yr;
    MS_N12_q60_P32_tpm_p2_core_s0_bu s0_k3 (.clk(clk), .aIn(xl_6), .bIn(xl_7), .W(tws3_o2), .QH(s0q_QH), .aOut(s0_k3_xr), .bOut(s0_k3_yr));
    logic [59:0] s0_o6;
    logic [59:0] s0_o6_h_x, s0_o6_h;
    assign s0_o6_h_x = s0_k3_xr;
    always_ff @(posedge clk) s0_o6_h <= mx_17[0] ? (60'(s0_o6_h_x >> 1) + (s0_o6_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o6_h_x;
    assign s0_o6 = s0_o6_h;
    logic [59:0] s0_o7;
    logic [59:0] s0_o7_h_x, s0_o7_h;
    assign s0_o7_h_x = s0_k3_yr;
    always_ff @(posedge clk) s0_o7_h <= mx_17[0] ? (60'(s0_o7_h_x >> 1) + (s0_o7_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o7_h_x;
    assign s0_o7 = s0_o7_h;
    logic [59:0] tws4_o2;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) tws4_o2_dly (.clk(clk), .din(tw_s4), .dout(tws4_o2));
    logic [59:0] s0_k4_xr; logic [59:0] s0_k4_yr;
    MS_N12_q60_P32_tpm_p2_core_s0_bu s0_k4 (.clk(clk), .aIn(xl_8), .bIn(xl_9), .W(tws4_o2), .QH(s0q_QH), .aOut(s0_k4_xr), .bOut(s0_k4_yr));
    logic [59:0] s0_o8;
    logic [59:0] s0_o8_h_x, s0_o8_h;
    assign s0_o8_h_x = s0_k4_xr;
    always_ff @(posedge clk) s0_o8_h <= mx_17[0] ? (60'(s0_o8_h_x >> 1) + (s0_o8_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o8_h_x;
    assign s0_o8 = s0_o8_h;
    logic [59:0] s0_o9;
    logic [59:0] s0_o9_h_x, s0_o9_h;
    assign s0_o9_h_x = s0_k4_yr;
    always_ff @(posedge clk) s0_o9_h <= mx_17[0] ? (60'(s0_o9_h_x >> 1) + (s0_o9_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o9_h_x;
    assign s0_o9 = s0_o9_h;
    logic [59:0] tws5_o2;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) tws5_o2_dly (.clk(clk), .din(tw_s5), .dout(tws5_o2));
    logic [59:0] s0_k5_xr; logic [59:0] s0_k5_yr;
    MS_N12_q60_P32_tpm_p2_core_s0_bu s0_k5 (.clk(clk), .aIn(xl_10), .bIn(xl_11), .W(tws5_o2), .QH(s0q_QH), .aOut(s0_k5_xr), .bOut(s0_k5_yr));
    logic [59:0] s0_o10;
    logic [59:0] s0_o10_h_x, s0_o10_h;
    assign s0_o10_h_x = s0_k5_xr;
    always_ff @(posedge clk) s0_o10_h <= mx_17[0] ? (60'(s0_o10_h_x >> 1) + (s0_o10_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o10_h_x;
    assign s0_o10 = s0_o10_h;
    logic [59:0] s0_o11;
    logic [59:0] s0_o11_h_x, s0_o11_h;
    assign s0_o11_h_x = s0_k5_yr;
    always_ff @(posedge clk) s0_o11_h <= mx_17[0] ? (60'(s0_o11_h_x >> 1) + (s0_o11_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o11_h_x;
    assign s0_o11 = s0_o11_h;
    logic [59:0] tws6_o2;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) tws6_o2_dly (.clk(clk), .din(tw_s6), .dout(tws6_o2));
    logic [59:0] s0_k6_xr; logic [59:0] s0_k6_yr;
    MS_N12_q60_P32_tpm_p2_core_s0_bu s0_k6 (.clk(clk), .aIn(xl_12), .bIn(xl_13), .W(tws6_o2), .QH(s0q_QH), .aOut(s0_k6_xr), .bOut(s0_k6_yr));
    logic [59:0] s0_o12;
    logic [59:0] s0_o12_h_x, s0_o12_h;
    assign s0_o12_h_x = s0_k6_xr;
    always_ff @(posedge clk) s0_o12_h <= mx_17[0] ? (60'(s0_o12_h_x >> 1) + (s0_o12_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o12_h_x;
    assign s0_o12 = s0_o12_h;
    logic [59:0] s0_o13;
    logic [59:0] s0_o13_h_x, s0_o13_h;
    assign s0_o13_h_x = s0_k6_yr;
    always_ff @(posedge clk) s0_o13_h <= mx_17[0] ? (60'(s0_o13_h_x >> 1) + (s0_o13_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o13_h_x;
    assign s0_o13 = s0_o13_h;
    logic [59:0] tws7_o2;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) tws7_o2_dly (.clk(clk), .din(tw_s7), .dout(tws7_o2));
    logic [59:0] s0_k7_xr; logic [59:0] s0_k7_yr;
    MS_N12_q60_P32_tpm_p2_core_s0_bu s0_k7 (.clk(clk), .aIn(xl_14), .bIn(xl_15), .W(tws7_o2), .QH(s0q_QH), .aOut(s0_k7_xr), .bOut(s0_k7_yr));
    logic [59:0] s0_o14;
    logic [59:0] s0_o14_h_x, s0_o14_h;
    assign s0_o14_h_x = s0_k7_xr;
    always_ff @(posedge clk) s0_o14_h <= mx_17[0] ? (60'(s0_o14_h_x >> 1) + (s0_o14_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o14_h_x;
    assign s0_o14 = s0_o14_h;
    logic [59:0] s0_o15;
    logic [59:0] s0_o15_h_x, s0_o15_h;
    assign s0_o15_h_x = s0_k7_yr;
    always_ff @(posedge clk) s0_o15_h <= mx_17[0] ? (60'(s0_o15_h_x >> 1) + (s0_o15_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o15_h_x;
    assign s0_o15 = s0_o15_h;
    logic [59:0] tws8_o2;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) tws8_o2_dly (.clk(clk), .din(tw_s8), .dout(tws8_o2));
    logic [59:0] s0_k8_xr; logic [59:0] s0_k8_yr;
    MS_N12_q60_P32_tpm_p2_core_s0_bu s0_k8 (.clk(clk), .aIn(xl_16), .bIn(xl_17), .W(tws8_o2), .QH(s0q_QH), .aOut(s0_k8_xr), .bOut(s0_k8_yr));
    logic [59:0] s0_o16;
    logic [59:0] s0_o16_h_x, s0_o16_h;
    assign s0_o16_h_x = s0_k8_xr;
    always_ff @(posedge clk) s0_o16_h <= mx_17[0] ? (60'(s0_o16_h_x >> 1) + (s0_o16_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o16_h_x;
    assign s0_o16 = s0_o16_h;
    logic [59:0] s0_o17;
    logic [59:0] s0_o17_h_x, s0_o17_h;
    assign s0_o17_h_x = s0_k8_yr;
    always_ff @(posedge clk) s0_o17_h <= mx_17[0] ? (60'(s0_o17_h_x >> 1) + (s0_o17_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o17_h_x;
    assign s0_o17 = s0_o17_h;
    logic [59:0] tws9_o2;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) tws9_o2_dly (.clk(clk), .din(tw_s9), .dout(tws9_o2));
    logic [59:0] s0_k9_xr; logic [59:0] s0_k9_yr;
    MS_N12_q60_P32_tpm_p2_core_s0_bu s0_k9 (.clk(clk), .aIn(xl_18), .bIn(xl_19), .W(tws9_o2), .QH(s0q_QH), .aOut(s0_k9_xr), .bOut(s0_k9_yr));
    logic [59:0] s0_o18;
    logic [59:0] s0_o18_h_x, s0_o18_h;
    assign s0_o18_h_x = s0_k9_xr;
    always_ff @(posedge clk) s0_o18_h <= mx_17[0] ? (60'(s0_o18_h_x >> 1) + (s0_o18_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o18_h_x;
    assign s0_o18 = s0_o18_h;
    logic [59:0] s0_o19;
    logic [59:0] s0_o19_h_x, s0_o19_h;
    assign s0_o19_h_x = s0_k9_yr;
    always_ff @(posedge clk) s0_o19_h <= mx_17[0] ? (60'(s0_o19_h_x >> 1) + (s0_o19_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o19_h_x;
    assign s0_o19 = s0_o19_h;
    logic [59:0] tws10_o2;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) tws10_o2_dly (.clk(clk), .din(tw_s10), .dout(tws10_o2));
    logic [59:0] s0_k10_xr; logic [59:0] s0_k10_yr;
    MS_N12_q60_P32_tpm_p2_core_s0_bu s0_k10 (.clk(clk), .aIn(xl_20), .bIn(xl_21), .W(tws10_o2), .QH(s0q_QH), .aOut(s0_k10_xr), .bOut(s0_k10_yr));
    logic [59:0] s0_o20;
    logic [59:0] s0_o20_h_x, s0_o20_h;
    assign s0_o20_h_x = s0_k10_xr;
    always_ff @(posedge clk) s0_o20_h <= mx_17[0] ? (60'(s0_o20_h_x >> 1) + (s0_o20_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o20_h_x;
    assign s0_o20 = s0_o20_h;
    logic [59:0] s0_o21;
    logic [59:0] s0_o21_h_x, s0_o21_h;
    assign s0_o21_h_x = s0_k10_yr;
    always_ff @(posedge clk) s0_o21_h <= mx_17[0] ? (60'(s0_o21_h_x >> 1) + (s0_o21_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o21_h_x;
    assign s0_o21 = s0_o21_h;
    logic [59:0] tws11_o2;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) tws11_o2_dly (.clk(clk), .din(tw_s11), .dout(tws11_o2));
    logic [59:0] s0_k11_xr; logic [59:0] s0_k11_yr;
    MS_N12_q60_P32_tpm_p2_core_s0_bu s0_k11 (.clk(clk), .aIn(xl_22), .bIn(xl_23), .W(tws11_o2), .QH(s0q_QH), .aOut(s0_k11_xr), .bOut(s0_k11_yr));
    logic [59:0] s0_o22;
    logic [59:0] s0_o22_h_x, s0_o22_h;
    assign s0_o22_h_x = s0_k11_xr;
    always_ff @(posedge clk) s0_o22_h <= mx_17[0] ? (60'(s0_o22_h_x >> 1) + (s0_o22_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o22_h_x;
    assign s0_o22 = s0_o22_h;
    logic [59:0] s0_o23;
    logic [59:0] s0_o23_h_x, s0_o23_h;
    assign s0_o23_h_x = s0_k11_yr;
    always_ff @(posedge clk) s0_o23_h <= mx_17[0] ? (60'(s0_o23_h_x >> 1) + (s0_o23_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o23_h_x;
    assign s0_o23 = s0_o23_h;
    logic [59:0] tws12_o2;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) tws12_o2_dly (.clk(clk), .din(tw_s12), .dout(tws12_o2));
    logic [59:0] s0_k12_xr; logic [59:0] s0_k12_yr;
    MS_N12_q60_P32_tpm_p2_core_s0_bu s0_k12 (.clk(clk), .aIn(xl_24), .bIn(xl_25), .W(tws12_o2), .QH(s0q_QH), .aOut(s0_k12_xr), .bOut(s0_k12_yr));
    logic [59:0] s0_o24;
    logic [59:0] s0_o24_h_x, s0_o24_h;
    assign s0_o24_h_x = s0_k12_xr;
    always_ff @(posedge clk) s0_o24_h <= mx_17[0] ? (60'(s0_o24_h_x >> 1) + (s0_o24_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o24_h_x;
    assign s0_o24 = s0_o24_h;
    logic [59:0] s0_o25;
    logic [59:0] s0_o25_h_x, s0_o25_h;
    assign s0_o25_h_x = s0_k12_yr;
    always_ff @(posedge clk) s0_o25_h <= mx_17[0] ? (60'(s0_o25_h_x >> 1) + (s0_o25_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o25_h_x;
    assign s0_o25 = s0_o25_h;
    logic [59:0] tws13_o2;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) tws13_o2_dly (.clk(clk), .din(tw_s13), .dout(tws13_o2));
    logic [59:0] s0_k13_xr; logic [59:0] s0_k13_yr;
    MS_N12_q60_P32_tpm_p2_core_s0_bu s0_k13 (.clk(clk), .aIn(xl_26), .bIn(xl_27), .W(tws13_o2), .QH(s0q_QH), .aOut(s0_k13_xr), .bOut(s0_k13_yr));
    logic [59:0] s0_o26;
    logic [59:0] s0_o26_h_x, s0_o26_h;
    assign s0_o26_h_x = s0_k13_xr;
    always_ff @(posedge clk) s0_o26_h <= mx_17[0] ? (60'(s0_o26_h_x >> 1) + (s0_o26_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o26_h_x;
    assign s0_o26 = s0_o26_h;
    logic [59:0] s0_o27;
    logic [59:0] s0_o27_h_x, s0_o27_h;
    assign s0_o27_h_x = s0_k13_yr;
    always_ff @(posedge clk) s0_o27_h <= mx_17[0] ? (60'(s0_o27_h_x >> 1) + (s0_o27_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o27_h_x;
    assign s0_o27 = s0_o27_h;
    logic [59:0] tws14_o2;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) tws14_o2_dly (.clk(clk), .din(tw_s14), .dout(tws14_o2));
    logic [59:0] s0_k14_xr; logic [59:0] s0_k14_yr;
    MS_N12_q60_P32_tpm_p2_core_s0_bu s0_k14 (.clk(clk), .aIn(xl_28), .bIn(xl_29), .W(tws14_o2), .QH(s0q_QH), .aOut(s0_k14_xr), .bOut(s0_k14_yr));
    logic [59:0] s0_o28;
    logic [59:0] s0_o28_h_x, s0_o28_h;
    assign s0_o28_h_x = s0_k14_xr;
    always_ff @(posedge clk) s0_o28_h <= mx_17[0] ? (60'(s0_o28_h_x >> 1) + (s0_o28_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o28_h_x;
    assign s0_o28 = s0_o28_h;
    logic [59:0] s0_o29;
    logic [59:0] s0_o29_h_x, s0_o29_h;
    assign s0_o29_h_x = s0_k14_yr;
    always_ff @(posedge clk) s0_o29_h <= mx_17[0] ? (60'(s0_o29_h_x >> 1) + (s0_o29_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o29_h_x;
    assign s0_o29 = s0_o29_h;
    logic [59:0] tws15_o2;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(2)) tws15_o2_dly (.clk(clk), .din(tw_s15), .dout(tws15_o2));
    logic [59:0] s0_k15_xr; logic [59:0] s0_k15_yr;
    MS_N12_q60_P32_tpm_p2_core_s0_bu s0_k15 (.clk(clk), .aIn(xl_30), .bIn(xl_31), .W(tws15_o2), .QH(s0q_QH), .aOut(s0_k15_xr), .bOut(s0_k15_yr));
    logic [59:0] s0_o30;
    logic [59:0] s0_o30_h_x, s0_o30_h;
    assign s0_o30_h_x = s0_k15_xr;
    always_ff @(posedge clk) s0_o30_h <= mx_17[0] ? (60'(s0_o30_h_x >> 1) + (s0_o30_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o30_h_x;
    assign s0_o30 = s0_o30_h;
    logic [59:0] s0_o31;
    logic [59:0] s0_o31_h_x, s0_o31_h;
    assign s0_o31_h_x = s0_k15_yr;
    always_ff @(posedge clk) s0_o31_h <= mx_17[0] ? (60'(s0_o31_h_x >> 1) + (s0_o31_h_x[0] ? 60'(s0q_QHALF) : 60'd0)) : s0_o31_h_x;
    assign s0_o31 = s0_o31_h;
    // stage 1: 16 butterflies on lane pairs (bit 1), latency 15
    logic [59:0] tws16_o18;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(18)) tws16_o18_dly (.clk(clk), .din(tw_s16), .dout(tws16_o18));
    (* max_fanout = 16 *) logic [16:0] s1q_QH;
    always_ff @(posedge clk) s1q_QH <= QH_r;
    logic [59:0] s1_k0_xr; logic [59:0] s1_k0_yr;
    MS_N12_q60_P32_tpm_p2_core_s1_bu s1_k0 (.clk(clk), .aIn(s0_o0), .bIn(s0_o2), .W(tws16_o18), .QH(s1q_QH), .aOut(s1_k0_xr), .bOut(s1_k0_yr));
    logic [59:0] s1_o0;
    (* max_fanout = 16 *) logic [59:0] s1q_QHALF;
    always_ff @(posedge clk) s1q_QHALF <= QHALF_r;
    logic [59:0] s1_o0_h_x, s1_o0_h;
    assign s1_o0_h_x = s1_k0_xr;
    (* max_fanout = 16 *) logic [0:0] mx_18;
    always_ff @(posedge clk) mx_18 <= mx_17;
    (* max_fanout = 16 *) logic [0:0] mx_19;
    always_ff @(posedge clk) mx_19 <= mx_18;
    (* max_fanout = 16 *) logic [0:0] mx_20;
    always_ff @(posedge clk) mx_20 <= mx_19;
    (* max_fanout = 16 *) logic [0:0] mx_21;
    always_ff @(posedge clk) mx_21 <= mx_20;
    (* max_fanout = 16 *) logic [0:0] mx_22;
    always_ff @(posedge clk) mx_22 <= mx_21;
    (* max_fanout = 16 *) logic [0:0] mx_23;
    always_ff @(posedge clk) mx_23 <= mx_22;
    (* max_fanout = 16 *) logic [0:0] mx_24;
    always_ff @(posedge clk) mx_24 <= mx_23;
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
    always_ff @(posedge clk) s1_o0_h <= mx_33[0] ? (60'(s1_o0_h_x >> 1) + (s1_o0_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o0_h_x;
    assign s1_o0 = s1_o0_h;
    logic [59:0] s1_o2;
    logic [59:0] s1_o2_h_x, s1_o2_h;
    assign s1_o2_h_x = s1_k0_yr;
    always_ff @(posedge clk) s1_o2_h <= mx_33[0] ? (60'(s1_o2_h_x >> 1) + (s1_o2_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o2_h_x;
    assign s1_o2 = s1_o2_h;
    logic [59:0] tws17_o18;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(18)) tws17_o18_dly (.clk(clk), .din(tw_s17), .dout(tws17_o18));
    logic [59:0] s1_k1_xr; logic [59:0] s1_k1_yr;
    MS_N12_q60_P32_tpm_p2_core_s1_bu s1_k1 (.clk(clk), .aIn(s0_o1), .bIn(s0_o3), .W(tws17_o18), .QH(s1q_QH), .aOut(s1_k1_xr), .bOut(s1_k1_yr));
    logic [59:0] s1_o1;
    logic [59:0] s1_o1_h_x, s1_o1_h;
    assign s1_o1_h_x = s1_k1_xr;
    always_ff @(posedge clk) s1_o1_h <= mx_33[0] ? (60'(s1_o1_h_x >> 1) + (s1_o1_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o1_h_x;
    assign s1_o1 = s1_o1_h;
    logic [59:0] s1_o3;
    logic [59:0] s1_o3_h_x, s1_o3_h;
    assign s1_o3_h_x = s1_k1_yr;
    always_ff @(posedge clk) s1_o3_h <= mx_33[0] ? (60'(s1_o3_h_x >> 1) + (s1_o3_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o3_h_x;
    assign s1_o3 = s1_o3_h;
    logic [59:0] tws18_o18;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(18)) tws18_o18_dly (.clk(clk), .din(tw_s18), .dout(tws18_o18));
    logic [59:0] s1_k2_xr; logic [59:0] s1_k2_yr;
    MS_N12_q60_P32_tpm_p2_core_s1_bu s1_k2 (.clk(clk), .aIn(s0_o4), .bIn(s0_o6), .W(tws18_o18), .QH(s1q_QH), .aOut(s1_k2_xr), .bOut(s1_k2_yr));
    logic [59:0] s1_o4;
    logic [59:0] s1_o4_h_x, s1_o4_h;
    assign s1_o4_h_x = s1_k2_xr;
    always_ff @(posedge clk) s1_o4_h <= mx_33[0] ? (60'(s1_o4_h_x >> 1) + (s1_o4_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o4_h_x;
    assign s1_o4 = s1_o4_h;
    logic [59:0] s1_o6;
    logic [59:0] s1_o6_h_x, s1_o6_h;
    assign s1_o6_h_x = s1_k2_yr;
    always_ff @(posedge clk) s1_o6_h <= mx_33[0] ? (60'(s1_o6_h_x >> 1) + (s1_o6_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o6_h_x;
    assign s1_o6 = s1_o6_h;
    logic [59:0] tws19_o18;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(18)) tws19_o18_dly (.clk(clk), .din(tw_s19), .dout(tws19_o18));
    logic [59:0] s1_k3_xr; logic [59:0] s1_k3_yr;
    MS_N12_q60_P32_tpm_p2_core_s1_bu s1_k3 (.clk(clk), .aIn(s0_o5), .bIn(s0_o7), .W(tws19_o18), .QH(s1q_QH), .aOut(s1_k3_xr), .bOut(s1_k3_yr));
    logic [59:0] s1_o5;
    logic [59:0] s1_o5_h_x, s1_o5_h;
    assign s1_o5_h_x = s1_k3_xr;
    always_ff @(posedge clk) s1_o5_h <= mx_33[0] ? (60'(s1_o5_h_x >> 1) + (s1_o5_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o5_h_x;
    assign s1_o5 = s1_o5_h;
    logic [59:0] s1_o7;
    logic [59:0] s1_o7_h_x, s1_o7_h;
    assign s1_o7_h_x = s1_k3_yr;
    always_ff @(posedge clk) s1_o7_h <= mx_33[0] ? (60'(s1_o7_h_x >> 1) + (s1_o7_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o7_h_x;
    assign s1_o7 = s1_o7_h;
    logic [59:0] tws20_o18;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(18)) tws20_o18_dly (.clk(clk), .din(tw_s20), .dout(tws20_o18));
    logic [59:0] s1_k4_xr; logic [59:0] s1_k4_yr;
    MS_N12_q60_P32_tpm_p2_core_s1_bu s1_k4 (.clk(clk), .aIn(s0_o8), .bIn(s0_o10), .W(tws20_o18), .QH(s1q_QH), .aOut(s1_k4_xr), .bOut(s1_k4_yr));
    logic [59:0] s1_o8;
    logic [59:0] s1_o8_h_x, s1_o8_h;
    assign s1_o8_h_x = s1_k4_xr;
    always_ff @(posedge clk) s1_o8_h <= mx_33[0] ? (60'(s1_o8_h_x >> 1) + (s1_o8_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o8_h_x;
    assign s1_o8 = s1_o8_h;
    logic [59:0] s1_o10;
    logic [59:0] s1_o10_h_x, s1_o10_h;
    assign s1_o10_h_x = s1_k4_yr;
    always_ff @(posedge clk) s1_o10_h <= mx_33[0] ? (60'(s1_o10_h_x >> 1) + (s1_o10_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o10_h_x;
    assign s1_o10 = s1_o10_h;
    logic [59:0] tws21_o18;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(18)) tws21_o18_dly (.clk(clk), .din(tw_s21), .dout(tws21_o18));
    logic [59:0] s1_k5_xr; logic [59:0] s1_k5_yr;
    MS_N12_q60_P32_tpm_p2_core_s1_bu s1_k5 (.clk(clk), .aIn(s0_o9), .bIn(s0_o11), .W(tws21_o18), .QH(s1q_QH), .aOut(s1_k5_xr), .bOut(s1_k5_yr));
    logic [59:0] s1_o9;
    logic [59:0] s1_o9_h_x, s1_o9_h;
    assign s1_o9_h_x = s1_k5_xr;
    always_ff @(posedge clk) s1_o9_h <= mx_33[0] ? (60'(s1_o9_h_x >> 1) + (s1_o9_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o9_h_x;
    assign s1_o9 = s1_o9_h;
    logic [59:0] s1_o11;
    logic [59:0] s1_o11_h_x, s1_o11_h;
    assign s1_o11_h_x = s1_k5_yr;
    always_ff @(posedge clk) s1_o11_h <= mx_33[0] ? (60'(s1_o11_h_x >> 1) + (s1_o11_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o11_h_x;
    assign s1_o11 = s1_o11_h;
    logic [59:0] tws22_o18;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(18)) tws22_o18_dly (.clk(clk), .din(tw_s22), .dout(tws22_o18));
    logic [59:0] s1_k6_xr; logic [59:0] s1_k6_yr;
    MS_N12_q60_P32_tpm_p2_core_s1_bu s1_k6 (.clk(clk), .aIn(s0_o12), .bIn(s0_o14), .W(tws22_o18), .QH(s1q_QH), .aOut(s1_k6_xr), .bOut(s1_k6_yr));
    logic [59:0] s1_o12;
    logic [59:0] s1_o12_h_x, s1_o12_h;
    assign s1_o12_h_x = s1_k6_xr;
    always_ff @(posedge clk) s1_o12_h <= mx_33[0] ? (60'(s1_o12_h_x >> 1) + (s1_o12_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o12_h_x;
    assign s1_o12 = s1_o12_h;
    logic [59:0] s1_o14;
    logic [59:0] s1_o14_h_x, s1_o14_h;
    assign s1_o14_h_x = s1_k6_yr;
    always_ff @(posedge clk) s1_o14_h <= mx_33[0] ? (60'(s1_o14_h_x >> 1) + (s1_o14_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o14_h_x;
    assign s1_o14 = s1_o14_h;
    logic [59:0] tws23_o18;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(18)) tws23_o18_dly (.clk(clk), .din(tw_s23), .dout(tws23_o18));
    logic [59:0] s1_k7_xr; logic [59:0] s1_k7_yr;
    MS_N12_q60_P32_tpm_p2_core_s1_bu s1_k7 (.clk(clk), .aIn(s0_o13), .bIn(s0_o15), .W(tws23_o18), .QH(s1q_QH), .aOut(s1_k7_xr), .bOut(s1_k7_yr));
    logic [59:0] s1_o13;
    logic [59:0] s1_o13_h_x, s1_o13_h;
    assign s1_o13_h_x = s1_k7_xr;
    always_ff @(posedge clk) s1_o13_h <= mx_33[0] ? (60'(s1_o13_h_x >> 1) + (s1_o13_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o13_h_x;
    assign s1_o13 = s1_o13_h;
    logic [59:0] s1_o15;
    logic [59:0] s1_o15_h_x, s1_o15_h;
    assign s1_o15_h_x = s1_k7_yr;
    always_ff @(posedge clk) s1_o15_h <= mx_33[0] ? (60'(s1_o15_h_x >> 1) + (s1_o15_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o15_h_x;
    assign s1_o15 = s1_o15_h;
    logic [59:0] tws24_o18;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(18)) tws24_o18_dly (.clk(clk), .din(tw_s24), .dout(tws24_o18));
    logic [59:0] s1_k8_xr; logic [59:0] s1_k8_yr;
    MS_N12_q60_P32_tpm_p2_core_s1_bu s1_k8 (.clk(clk), .aIn(s0_o16), .bIn(s0_o18), .W(tws24_o18), .QH(s1q_QH), .aOut(s1_k8_xr), .bOut(s1_k8_yr));
    logic [59:0] s1_o16;
    logic [59:0] s1_o16_h_x, s1_o16_h;
    assign s1_o16_h_x = s1_k8_xr;
    always_ff @(posedge clk) s1_o16_h <= mx_33[0] ? (60'(s1_o16_h_x >> 1) + (s1_o16_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o16_h_x;
    assign s1_o16 = s1_o16_h;
    logic [59:0] s1_o18;
    logic [59:0] s1_o18_h_x, s1_o18_h;
    assign s1_o18_h_x = s1_k8_yr;
    always_ff @(posedge clk) s1_o18_h <= mx_33[0] ? (60'(s1_o18_h_x >> 1) + (s1_o18_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o18_h_x;
    assign s1_o18 = s1_o18_h;
    logic [59:0] tws25_o18;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(18)) tws25_o18_dly (.clk(clk), .din(tw_s25), .dout(tws25_o18));
    logic [59:0] s1_k9_xr; logic [59:0] s1_k9_yr;
    MS_N12_q60_P32_tpm_p2_core_s1_bu s1_k9 (.clk(clk), .aIn(s0_o17), .bIn(s0_o19), .W(tws25_o18), .QH(s1q_QH), .aOut(s1_k9_xr), .bOut(s1_k9_yr));
    logic [59:0] s1_o17;
    logic [59:0] s1_o17_h_x, s1_o17_h;
    assign s1_o17_h_x = s1_k9_xr;
    always_ff @(posedge clk) s1_o17_h <= mx_33[0] ? (60'(s1_o17_h_x >> 1) + (s1_o17_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o17_h_x;
    assign s1_o17 = s1_o17_h;
    logic [59:0] s1_o19;
    logic [59:0] s1_o19_h_x, s1_o19_h;
    assign s1_o19_h_x = s1_k9_yr;
    always_ff @(posedge clk) s1_o19_h <= mx_33[0] ? (60'(s1_o19_h_x >> 1) + (s1_o19_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o19_h_x;
    assign s1_o19 = s1_o19_h;
    logic [59:0] tws26_o18;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(18)) tws26_o18_dly (.clk(clk), .din(tw_s26), .dout(tws26_o18));
    logic [59:0] s1_k10_xr; logic [59:0] s1_k10_yr;
    MS_N12_q60_P32_tpm_p2_core_s1_bu s1_k10 (.clk(clk), .aIn(s0_o20), .bIn(s0_o22), .W(tws26_o18), .QH(s1q_QH), .aOut(s1_k10_xr), .bOut(s1_k10_yr));
    logic [59:0] s1_o20;
    logic [59:0] s1_o20_h_x, s1_o20_h;
    assign s1_o20_h_x = s1_k10_xr;
    always_ff @(posedge clk) s1_o20_h <= mx_33[0] ? (60'(s1_o20_h_x >> 1) + (s1_o20_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o20_h_x;
    assign s1_o20 = s1_o20_h;
    logic [59:0] s1_o22;
    logic [59:0] s1_o22_h_x, s1_o22_h;
    assign s1_o22_h_x = s1_k10_yr;
    always_ff @(posedge clk) s1_o22_h <= mx_33[0] ? (60'(s1_o22_h_x >> 1) + (s1_o22_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o22_h_x;
    assign s1_o22 = s1_o22_h;
    logic [59:0] tws27_o18;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(18)) tws27_o18_dly (.clk(clk), .din(tw_s27), .dout(tws27_o18));
    logic [59:0] s1_k11_xr; logic [59:0] s1_k11_yr;
    MS_N12_q60_P32_tpm_p2_core_s1_bu s1_k11 (.clk(clk), .aIn(s0_o21), .bIn(s0_o23), .W(tws27_o18), .QH(s1q_QH), .aOut(s1_k11_xr), .bOut(s1_k11_yr));
    logic [59:0] s1_o21;
    logic [59:0] s1_o21_h_x, s1_o21_h;
    assign s1_o21_h_x = s1_k11_xr;
    always_ff @(posedge clk) s1_o21_h <= mx_33[0] ? (60'(s1_o21_h_x >> 1) + (s1_o21_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o21_h_x;
    assign s1_o21 = s1_o21_h;
    logic [59:0] s1_o23;
    logic [59:0] s1_o23_h_x, s1_o23_h;
    assign s1_o23_h_x = s1_k11_yr;
    always_ff @(posedge clk) s1_o23_h <= mx_33[0] ? (60'(s1_o23_h_x >> 1) + (s1_o23_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o23_h_x;
    assign s1_o23 = s1_o23_h;
    logic [59:0] tws28_o18;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(18)) tws28_o18_dly (.clk(clk), .din(tw_s28), .dout(tws28_o18));
    logic [59:0] s1_k12_xr; logic [59:0] s1_k12_yr;
    MS_N12_q60_P32_tpm_p2_core_s1_bu s1_k12 (.clk(clk), .aIn(s0_o24), .bIn(s0_o26), .W(tws28_o18), .QH(s1q_QH), .aOut(s1_k12_xr), .bOut(s1_k12_yr));
    logic [59:0] s1_o24;
    logic [59:0] s1_o24_h_x, s1_o24_h;
    assign s1_o24_h_x = s1_k12_xr;
    always_ff @(posedge clk) s1_o24_h <= mx_33[0] ? (60'(s1_o24_h_x >> 1) + (s1_o24_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o24_h_x;
    assign s1_o24 = s1_o24_h;
    logic [59:0] s1_o26;
    logic [59:0] s1_o26_h_x, s1_o26_h;
    assign s1_o26_h_x = s1_k12_yr;
    always_ff @(posedge clk) s1_o26_h <= mx_33[0] ? (60'(s1_o26_h_x >> 1) + (s1_o26_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o26_h_x;
    assign s1_o26 = s1_o26_h;
    logic [59:0] tws29_o18;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(18)) tws29_o18_dly (.clk(clk), .din(tw_s29), .dout(tws29_o18));
    logic [59:0] s1_k13_xr; logic [59:0] s1_k13_yr;
    MS_N12_q60_P32_tpm_p2_core_s1_bu s1_k13 (.clk(clk), .aIn(s0_o25), .bIn(s0_o27), .W(tws29_o18), .QH(s1q_QH), .aOut(s1_k13_xr), .bOut(s1_k13_yr));
    logic [59:0] s1_o25;
    logic [59:0] s1_o25_h_x, s1_o25_h;
    assign s1_o25_h_x = s1_k13_xr;
    always_ff @(posedge clk) s1_o25_h <= mx_33[0] ? (60'(s1_o25_h_x >> 1) + (s1_o25_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o25_h_x;
    assign s1_o25 = s1_o25_h;
    logic [59:0] s1_o27;
    logic [59:0] s1_o27_h_x, s1_o27_h;
    assign s1_o27_h_x = s1_k13_yr;
    always_ff @(posedge clk) s1_o27_h <= mx_33[0] ? (60'(s1_o27_h_x >> 1) + (s1_o27_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o27_h_x;
    assign s1_o27 = s1_o27_h;
    logic [59:0] tws30_o18;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(18)) tws30_o18_dly (.clk(clk), .din(tw_s30), .dout(tws30_o18));
    logic [59:0] s1_k14_xr; logic [59:0] s1_k14_yr;
    MS_N12_q60_P32_tpm_p2_core_s1_bu s1_k14 (.clk(clk), .aIn(s0_o28), .bIn(s0_o30), .W(tws30_o18), .QH(s1q_QH), .aOut(s1_k14_xr), .bOut(s1_k14_yr));
    logic [59:0] s1_o28;
    logic [59:0] s1_o28_h_x, s1_o28_h;
    assign s1_o28_h_x = s1_k14_xr;
    always_ff @(posedge clk) s1_o28_h <= mx_33[0] ? (60'(s1_o28_h_x >> 1) + (s1_o28_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o28_h_x;
    assign s1_o28 = s1_o28_h;
    logic [59:0] s1_o30;
    logic [59:0] s1_o30_h_x, s1_o30_h;
    assign s1_o30_h_x = s1_k14_yr;
    always_ff @(posedge clk) s1_o30_h <= mx_33[0] ? (60'(s1_o30_h_x >> 1) + (s1_o30_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o30_h_x;
    assign s1_o30 = s1_o30_h;
    logic [59:0] tws31_o18;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(18)) tws31_o18_dly (.clk(clk), .din(tw_s31), .dout(tws31_o18));
    logic [59:0] s1_k15_xr; logic [59:0] s1_k15_yr;
    MS_N12_q60_P32_tpm_p2_core_s1_bu s1_k15 (.clk(clk), .aIn(s0_o29), .bIn(s0_o31), .W(tws31_o18), .QH(s1q_QH), .aOut(s1_k15_xr), .bOut(s1_k15_yr));
    logic [59:0] s1_o29;
    logic [59:0] s1_o29_h_x, s1_o29_h;
    assign s1_o29_h_x = s1_k15_xr;
    always_ff @(posedge clk) s1_o29_h <= mx_33[0] ? (60'(s1_o29_h_x >> 1) + (s1_o29_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o29_h_x;
    assign s1_o29 = s1_o29_h;
    logic [59:0] s1_o31;
    logic [59:0] s1_o31_h_x, s1_o31_h;
    assign s1_o31_h_x = s1_k15_yr;
    always_ff @(posedge clk) s1_o31_h <= mx_33[0] ? (60'(s1_o31_h_x >> 1) + (s1_o31_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o31_h_x;
    assign s1_o31 = s1_o31_h;
    // stage 2: 16 butterflies on lane pairs (bit 2), latency 15
    logic [59:0] tws32_o34;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(34)) tws32_o34_dly (.clk(clk), .din(tw_s32), .dout(tws32_o34));
    (* max_fanout = 16 *) logic [16:0] s2q_QH;
    always_ff @(posedge clk) s2q_QH <= QH_r;
    logic [59:0] s2_k0_xr; logic [59:0] s2_k0_yr;
    MS_N12_q60_P32_tpm_p2_core_s2_bu s2_k0 (.clk(clk), .aIn(s1_o0), .bIn(s1_o4), .W(tws32_o34), .QH(s2q_QH), .aOut(s2_k0_xr), .bOut(s2_k0_yr));
    logic [59:0] s2_o0;
    (* max_fanout = 16 *) logic [59:0] s2q_QHALF;
    always_ff @(posedge clk) s2q_QHALF <= QHALF_r;
    logic [59:0] s2_o0_h_x, s2_o0_h;
    assign s2_o0_h_x = s2_k0_xr;
    (* max_fanout = 16 *) logic [0:0] mx_34;
    always_ff @(posedge clk) mx_34 <= mx_33;
    (* max_fanout = 16 *) logic [0:0] mx_35;
    always_ff @(posedge clk) mx_35 <= mx_34;
    (* max_fanout = 16 *) logic [0:0] mx_36;
    always_ff @(posedge clk) mx_36 <= mx_35;
    (* max_fanout = 16 *) logic [0:0] mx_37;
    always_ff @(posedge clk) mx_37 <= mx_36;
    (* max_fanout = 16 *) logic [0:0] mx_38;
    always_ff @(posedge clk) mx_38 <= mx_37;
    (* max_fanout = 16 *) logic [0:0] mx_39;
    always_ff @(posedge clk) mx_39 <= mx_38;
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
    always_ff @(posedge clk) s2_o0_h <= mx_49[0] ? (60'(s2_o0_h_x >> 1) + (s2_o0_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o0_h_x;
    assign s2_o0 = s2_o0_h;
    logic [59:0] s2_o4;
    logic [59:0] s2_o4_h_x, s2_o4_h;
    assign s2_o4_h_x = s2_k0_yr;
    always_ff @(posedge clk) s2_o4_h <= mx_49[0] ? (60'(s2_o4_h_x >> 1) + (s2_o4_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o4_h_x;
    assign s2_o4 = s2_o4_h;
    logic [59:0] tws33_o34;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(34)) tws33_o34_dly (.clk(clk), .din(tw_s33), .dout(tws33_o34));
    logic [59:0] s2_k1_xr; logic [59:0] s2_k1_yr;
    MS_N12_q60_P32_tpm_p2_core_s2_bu s2_k1 (.clk(clk), .aIn(s1_o1), .bIn(s1_o5), .W(tws33_o34), .QH(s2q_QH), .aOut(s2_k1_xr), .bOut(s2_k1_yr));
    logic [59:0] s2_o1;
    logic [59:0] s2_o1_h_x, s2_o1_h;
    assign s2_o1_h_x = s2_k1_xr;
    always_ff @(posedge clk) s2_o1_h <= mx_49[0] ? (60'(s2_o1_h_x >> 1) + (s2_o1_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o1_h_x;
    assign s2_o1 = s2_o1_h;
    logic [59:0] s2_o5;
    logic [59:0] s2_o5_h_x, s2_o5_h;
    assign s2_o5_h_x = s2_k1_yr;
    always_ff @(posedge clk) s2_o5_h <= mx_49[0] ? (60'(s2_o5_h_x >> 1) + (s2_o5_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o5_h_x;
    assign s2_o5 = s2_o5_h;
    logic [59:0] tws34_o34;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(34)) tws34_o34_dly (.clk(clk), .din(tw_s34), .dout(tws34_o34));
    logic [59:0] s2_k2_xr; logic [59:0] s2_k2_yr;
    MS_N12_q60_P32_tpm_p2_core_s2_bu s2_k2 (.clk(clk), .aIn(s1_o2), .bIn(s1_o6), .W(tws34_o34), .QH(s2q_QH), .aOut(s2_k2_xr), .bOut(s2_k2_yr));
    logic [59:0] s2_o2;
    logic [59:0] s2_o2_h_x, s2_o2_h;
    assign s2_o2_h_x = s2_k2_xr;
    always_ff @(posedge clk) s2_o2_h <= mx_49[0] ? (60'(s2_o2_h_x >> 1) + (s2_o2_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o2_h_x;
    assign s2_o2 = s2_o2_h;
    logic [59:0] s2_o6;
    logic [59:0] s2_o6_h_x, s2_o6_h;
    assign s2_o6_h_x = s2_k2_yr;
    always_ff @(posedge clk) s2_o6_h <= mx_49[0] ? (60'(s2_o6_h_x >> 1) + (s2_o6_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o6_h_x;
    assign s2_o6 = s2_o6_h;
    logic [59:0] tws35_o34;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(34)) tws35_o34_dly (.clk(clk), .din(tw_s35), .dout(tws35_o34));
    logic [59:0] s2_k3_xr; logic [59:0] s2_k3_yr;
    MS_N12_q60_P32_tpm_p2_core_s2_bu s2_k3 (.clk(clk), .aIn(s1_o3), .bIn(s1_o7), .W(tws35_o34), .QH(s2q_QH), .aOut(s2_k3_xr), .bOut(s2_k3_yr));
    logic [59:0] s2_o3;
    logic [59:0] s2_o3_h_x, s2_o3_h;
    assign s2_o3_h_x = s2_k3_xr;
    always_ff @(posedge clk) s2_o3_h <= mx_49[0] ? (60'(s2_o3_h_x >> 1) + (s2_o3_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o3_h_x;
    assign s2_o3 = s2_o3_h;
    logic [59:0] s2_o7;
    logic [59:0] s2_o7_h_x, s2_o7_h;
    assign s2_o7_h_x = s2_k3_yr;
    always_ff @(posedge clk) s2_o7_h <= mx_49[0] ? (60'(s2_o7_h_x >> 1) + (s2_o7_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o7_h_x;
    assign s2_o7 = s2_o7_h;
    logic [59:0] tws36_o34;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(34)) tws36_o34_dly (.clk(clk), .din(tw_s36), .dout(tws36_o34));
    logic [59:0] s2_k4_xr; logic [59:0] s2_k4_yr;
    MS_N12_q60_P32_tpm_p2_core_s2_bu s2_k4 (.clk(clk), .aIn(s1_o8), .bIn(s1_o12), .W(tws36_o34), .QH(s2q_QH), .aOut(s2_k4_xr), .bOut(s2_k4_yr));
    logic [59:0] s2_o8;
    logic [59:0] s2_o8_h_x, s2_o8_h;
    assign s2_o8_h_x = s2_k4_xr;
    always_ff @(posedge clk) s2_o8_h <= mx_49[0] ? (60'(s2_o8_h_x >> 1) + (s2_o8_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o8_h_x;
    assign s2_o8 = s2_o8_h;
    logic [59:0] s2_o12;
    logic [59:0] s2_o12_h_x, s2_o12_h;
    assign s2_o12_h_x = s2_k4_yr;
    always_ff @(posedge clk) s2_o12_h <= mx_49[0] ? (60'(s2_o12_h_x >> 1) + (s2_o12_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o12_h_x;
    assign s2_o12 = s2_o12_h;
    logic [59:0] tws37_o34;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(34)) tws37_o34_dly (.clk(clk), .din(tw_s37), .dout(tws37_o34));
    logic [59:0] s2_k5_xr; logic [59:0] s2_k5_yr;
    MS_N12_q60_P32_tpm_p2_core_s2_bu s2_k5 (.clk(clk), .aIn(s1_o9), .bIn(s1_o13), .W(tws37_o34), .QH(s2q_QH), .aOut(s2_k5_xr), .bOut(s2_k5_yr));
    logic [59:0] s2_o9;
    logic [59:0] s2_o9_h_x, s2_o9_h;
    assign s2_o9_h_x = s2_k5_xr;
    always_ff @(posedge clk) s2_o9_h <= mx_49[0] ? (60'(s2_o9_h_x >> 1) + (s2_o9_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o9_h_x;
    assign s2_o9 = s2_o9_h;
    logic [59:0] s2_o13;
    logic [59:0] s2_o13_h_x, s2_o13_h;
    assign s2_o13_h_x = s2_k5_yr;
    always_ff @(posedge clk) s2_o13_h <= mx_49[0] ? (60'(s2_o13_h_x >> 1) + (s2_o13_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o13_h_x;
    assign s2_o13 = s2_o13_h;
    logic [59:0] tws38_o34;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(34)) tws38_o34_dly (.clk(clk), .din(tw_s38), .dout(tws38_o34));
    logic [59:0] s2_k6_xr; logic [59:0] s2_k6_yr;
    MS_N12_q60_P32_tpm_p2_core_s2_bu s2_k6 (.clk(clk), .aIn(s1_o10), .bIn(s1_o14), .W(tws38_o34), .QH(s2q_QH), .aOut(s2_k6_xr), .bOut(s2_k6_yr));
    logic [59:0] s2_o10;
    logic [59:0] s2_o10_h_x, s2_o10_h;
    assign s2_o10_h_x = s2_k6_xr;
    always_ff @(posedge clk) s2_o10_h <= mx_49[0] ? (60'(s2_o10_h_x >> 1) + (s2_o10_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o10_h_x;
    assign s2_o10 = s2_o10_h;
    logic [59:0] s2_o14;
    logic [59:0] s2_o14_h_x, s2_o14_h;
    assign s2_o14_h_x = s2_k6_yr;
    always_ff @(posedge clk) s2_o14_h <= mx_49[0] ? (60'(s2_o14_h_x >> 1) + (s2_o14_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o14_h_x;
    assign s2_o14 = s2_o14_h;
    logic [59:0] tws39_o34;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(34)) tws39_o34_dly (.clk(clk), .din(tw_s39), .dout(tws39_o34));
    logic [59:0] s2_k7_xr; logic [59:0] s2_k7_yr;
    MS_N12_q60_P32_tpm_p2_core_s2_bu s2_k7 (.clk(clk), .aIn(s1_o11), .bIn(s1_o15), .W(tws39_o34), .QH(s2q_QH), .aOut(s2_k7_xr), .bOut(s2_k7_yr));
    logic [59:0] s2_o11;
    logic [59:0] s2_o11_h_x, s2_o11_h;
    assign s2_o11_h_x = s2_k7_xr;
    always_ff @(posedge clk) s2_o11_h <= mx_49[0] ? (60'(s2_o11_h_x >> 1) + (s2_o11_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o11_h_x;
    assign s2_o11 = s2_o11_h;
    logic [59:0] s2_o15;
    logic [59:0] s2_o15_h_x, s2_o15_h;
    assign s2_o15_h_x = s2_k7_yr;
    always_ff @(posedge clk) s2_o15_h <= mx_49[0] ? (60'(s2_o15_h_x >> 1) + (s2_o15_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o15_h_x;
    assign s2_o15 = s2_o15_h;
    logic [59:0] tws40_o34;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(34)) tws40_o34_dly (.clk(clk), .din(tw_s40), .dout(tws40_o34));
    logic [59:0] s2_k8_xr; logic [59:0] s2_k8_yr;
    MS_N12_q60_P32_tpm_p2_core_s2_bu s2_k8 (.clk(clk), .aIn(s1_o16), .bIn(s1_o20), .W(tws40_o34), .QH(s2q_QH), .aOut(s2_k8_xr), .bOut(s2_k8_yr));
    logic [59:0] s2_o16;
    logic [59:0] s2_o16_h_x, s2_o16_h;
    assign s2_o16_h_x = s2_k8_xr;
    always_ff @(posedge clk) s2_o16_h <= mx_49[0] ? (60'(s2_o16_h_x >> 1) + (s2_o16_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o16_h_x;
    assign s2_o16 = s2_o16_h;
    logic [59:0] s2_o20;
    logic [59:0] s2_o20_h_x, s2_o20_h;
    assign s2_o20_h_x = s2_k8_yr;
    always_ff @(posedge clk) s2_o20_h <= mx_49[0] ? (60'(s2_o20_h_x >> 1) + (s2_o20_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o20_h_x;
    assign s2_o20 = s2_o20_h;
    logic [59:0] tws41_o34;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(34)) tws41_o34_dly (.clk(clk), .din(tw_s41), .dout(tws41_o34));
    logic [59:0] s2_k9_xr; logic [59:0] s2_k9_yr;
    MS_N12_q60_P32_tpm_p2_core_s2_bu s2_k9 (.clk(clk), .aIn(s1_o17), .bIn(s1_o21), .W(tws41_o34), .QH(s2q_QH), .aOut(s2_k9_xr), .bOut(s2_k9_yr));
    logic [59:0] s2_o17;
    logic [59:0] s2_o17_h_x, s2_o17_h;
    assign s2_o17_h_x = s2_k9_xr;
    always_ff @(posedge clk) s2_o17_h <= mx_49[0] ? (60'(s2_o17_h_x >> 1) + (s2_o17_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o17_h_x;
    assign s2_o17 = s2_o17_h;
    logic [59:0] s2_o21;
    logic [59:0] s2_o21_h_x, s2_o21_h;
    assign s2_o21_h_x = s2_k9_yr;
    always_ff @(posedge clk) s2_o21_h <= mx_49[0] ? (60'(s2_o21_h_x >> 1) + (s2_o21_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o21_h_x;
    assign s2_o21 = s2_o21_h;
    logic [59:0] tws42_o34;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(34)) tws42_o34_dly (.clk(clk), .din(tw_s42), .dout(tws42_o34));
    logic [59:0] s2_k10_xr; logic [59:0] s2_k10_yr;
    MS_N12_q60_P32_tpm_p2_core_s2_bu s2_k10 (.clk(clk), .aIn(s1_o18), .bIn(s1_o22), .W(tws42_o34), .QH(s2q_QH), .aOut(s2_k10_xr), .bOut(s2_k10_yr));
    logic [59:0] s2_o18;
    logic [59:0] s2_o18_h_x, s2_o18_h;
    assign s2_o18_h_x = s2_k10_xr;
    always_ff @(posedge clk) s2_o18_h <= mx_49[0] ? (60'(s2_o18_h_x >> 1) + (s2_o18_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o18_h_x;
    assign s2_o18 = s2_o18_h;
    logic [59:0] s2_o22;
    logic [59:0] s2_o22_h_x, s2_o22_h;
    assign s2_o22_h_x = s2_k10_yr;
    always_ff @(posedge clk) s2_o22_h <= mx_49[0] ? (60'(s2_o22_h_x >> 1) + (s2_o22_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o22_h_x;
    assign s2_o22 = s2_o22_h;
    logic [59:0] tws43_o34;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(34)) tws43_o34_dly (.clk(clk), .din(tw_s43), .dout(tws43_o34));
    logic [59:0] s2_k11_xr; logic [59:0] s2_k11_yr;
    MS_N12_q60_P32_tpm_p2_core_s2_bu s2_k11 (.clk(clk), .aIn(s1_o19), .bIn(s1_o23), .W(tws43_o34), .QH(s2q_QH), .aOut(s2_k11_xr), .bOut(s2_k11_yr));
    logic [59:0] s2_o19;
    logic [59:0] s2_o19_h_x, s2_o19_h;
    assign s2_o19_h_x = s2_k11_xr;
    always_ff @(posedge clk) s2_o19_h <= mx_49[0] ? (60'(s2_o19_h_x >> 1) + (s2_o19_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o19_h_x;
    assign s2_o19 = s2_o19_h;
    logic [59:0] s2_o23;
    logic [59:0] s2_o23_h_x, s2_o23_h;
    assign s2_o23_h_x = s2_k11_yr;
    always_ff @(posedge clk) s2_o23_h <= mx_49[0] ? (60'(s2_o23_h_x >> 1) + (s2_o23_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o23_h_x;
    assign s2_o23 = s2_o23_h;
    logic [59:0] tws44_o34;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(34)) tws44_o34_dly (.clk(clk), .din(tw_s44), .dout(tws44_o34));
    logic [59:0] s2_k12_xr; logic [59:0] s2_k12_yr;
    MS_N12_q60_P32_tpm_p2_core_s2_bu s2_k12 (.clk(clk), .aIn(s1_o24), .bIn(s1_o28), .W(tws44_o34), .QH(s2q_QH), .aOut(s2_k12_xr), .bOut(s2_k12_yr));
    logic [59:0] s2_o24;
    logic [59:0] s2_o24_h_x, s2_o24_h;
    assign s2_o24_h_x = s2_k12_xr;
    always_ff @(posedge clk) s2_o24_h <= mx_49[0] ? (60'(s2_o24_h_x >> 1) + (s2_o24_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o24_h_x;
    assign s2_o24 = s2_o24_h;
    logic [59:0] s2_o28;
    logic [59:0] s2_o28_h_x, s2_o28_h;
    assign s2_o28_h_x = s2_k12_yr;
    always_ff @(posedge clk) s2_o28_h <= mx_49[0] ? (60'(s2_o28_h_x >> 1) + (s2_o28_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o28_h_x;
    assign s2_o28 = s2_o28_h;
    logic [59:0] tws45_o34;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(34)) tws45_o34_dly (.clk(clk), .din(tw_s45), .dout(tws45_o34));
    logic [59:0] s2_k13_xr; logic [59:0] s2_k13_yr;
    MS_N12_q60_P32_tpm_p2_core_s2_bu s2_k13 (.clk(clk), .aIn(s1_o25), .bIn(s1_o29), .W(tws45_o34), .QH(s2q_QH), .aOut(s2_k13_xr), .bOut(s2_k13_yr));
    logic [59:0] s2_o25;
    logic [59:0] s2_o25_h_x, s2_o25_h;
    assign s2_o25_h_x = s2_k13_xr;
    always_ff @(posedge clk) s2_o25_h <= mx_49[0] ? (60'(s2_o25_h_x >> 1) + (s2_o25_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o25_h_x;
    assign s2_o25 = s2_o25_h;
    logic [59:0] s2_o29;
    logic [59:0] s2_o29_h_x, s2_o29_h;
    assign s2_o29_h_x = s2_k13_yr;
    always_ff @(posedge clk) s2_o29_h <= mx_49[0] ? (60'(s2_o29_h_x >> 1) + (s2_o29_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o29_h_x;
    assign s2_o29 = s2_o29_h;
    logic [59:0] tws46_o34;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(34)) tws46_o34_dly (.clk(clk), .din(tw_s46), .dout(tws46_o34));
    logic [59:0] s2_k14_xr; logic [59:0] s2_k14_yr;
    MS_N12_q60_P32_tpm_p2_core_s2_bu s2_k14 (.clk(clk), .aIn(s1_o26), .bIn(s1_o30), .W(tws46_o34), .QH(s2q_QH), .aOut(s2_k14_xr), .bOut(s2_k14_yr));
    logic [59:0] s2_o26;
    logic [59:0] s2_o26_h_x, s2_o26_h;
    assign s2_o26_h_x = s2_k14_xr;
    always_ff @(posedge clk) s2_o26_h <= mx_49[0] ? (60'(s2_o26_h_x >> 1) + (s2_o26_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o26_h_x;
    assign s2_o26 = s2_o26_h;
    logic [59:0] s2_o30;
    logic [59:0] s2_o30_h_x, s2_o30_h;
    assign s2_o30_h_x = s2_k14_yr;
    always_ff @(posedge clk) s2_o30_h <= mx_49[0] ? (60'(s2_o30_h_x >> 1) + (s2_o30_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o30_h_x;
    assign s2_o30 = s2_o30_h;
    logic [59:0] tws47_o34;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(34)) tws47_o34_dly (.clk(clk), .din(tw_s47), .dout(tws47_o34));
    logic [59:0] s2_k15_xr; logic [59:0] s2_k15_yr;
    MS_N12_q60_P32_tpm_p2_core_s2_bu s2_k15 (.clk(clk), .aIn(s1_o27), .bIn(s1_o31), .W(tws47_o34), .QH(s2q_QH), .aOut(s2_k15_xr), .bOut(s2_k15_yr));
    logic [59:0] s2_o27;
    logic [59:0] s2_o27_h_x, s2_o27_h;
    assign s2_o27_h_x = s2_k15_xr;
    always_ff @(posedge clk) s2_o27_h <= mx_49[0] ? (60'(s2_o27_h_x >> 1) + (s2_o27_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o27_h_x;
    assign s2_o27 = s2_o27_h;
    logic [59:0] s2_o31;
    logic [59:0] s2_o31_h_x, s2_o31_h;
    assign s2_o31_h_x = s2_k15_yr;
    always_ff @(posedge clk) s2_o31_h <= mx_49[0] ? (60'(s2_o31_h_x >> 1) + (s2_o31_h_x[0] ? 60'(s2q_QHALF) : 60'd0)) : s2_o31_h_x;
    assign s2_o31 = s2_o31_h;
    // stage 3: 16 butterflies on lane pairs (bit 3), latency 15
    logic [59:0] tws48_o50;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(50)) tws48_o50_dly (.clk(clk), .din(tw_s48), .dout(tws48_o50));
    (* max_fanout = 16 *) logic [16:0] s3q_QH;
    always_ff @(posedge clk) s3q_QH <= QH_r;
    logic [59:0] s3_k0_xr; logic [59:0] s3_k0_yr;
    MS_N12_q60_P32_tpm_p2_core_s3_bu s3_k0 (.clk(clk), .aIn(s2_o0), .bIn(s2_o8), .W(tws48_o50), .QH(s3q_QH), .aOut(s3_k0_xr), .bOut(s3_k0_yr));
    logic [59:0] s3_o0;
    (* max_fanout = 16 *) logic [59:0] s3q_QHALF;
    always_ff @(posedge clk) s3q_QHALF <= QHALF_r;
    logic [59:0] s3_o0_h_x, s3_o0_h;
    assign s3_o0_h_x = s3_k0_xr;
    (* max_fanout = 16 *) logic [0:0] mx_50;
    always_ff @(posedge clk) mx_50 <= mx_49;
    (* max_fanout = 16 *) logic [0:0] mx_51;
    always_ff @(posedge clk) mx_51 <= mx_50;
    (* max_fanout = 16 *) logic [0:0] mx_52;
    always_ff @(posedge clk) mx_52 <= mx_51;
    (* max_fanout = 16 *) logic [0:0] mx_53;
    always_ff @(posedge clk) mx_53 <= mx_52;
    (* max_fanout = 16 *) logic [0:0] mx_54;
    always_ff @(posedge clk) mx_54 <= mx_53;
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
    always_ff @(posedge clk) s3_o0_h <= mx_65[0] ? (60'(s3_o0_h_x >> 1) + (s3_o0_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o0_h_x;
    assign s3_o0 = s3_o0_h;
    logic [59:0] s3_o8;
    logic [59:0] s3_o8_h_x, s3_o8_h;
    assign s3_o8_h_x = s3_k0_yr;
    always_ff @(posedge clk) s3_o8_h <= mx_65[0] ? (60'(s3_o8_h_x >> 1) + (s3_o8_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o8_h_x;
    assign s3_o8 = s3_o8_h;
    logic [59:0] tws49_o50;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(50)) tws49_o50_dly (.clk(clk), .din(tw_s49), .dout(tws49_o50));
    logic [59:0] s3_k1_xr; logic [59:0] s3_k1_yr;
    MS_N12_q60_P32_tpm_p2_core_s3_bu s3_k1 (.clk(clk), .aIn(s2_o1), .bIn(s2_o9), .W(tws49_o50), .QH(s3q_QH), .aOut(s3_k1_xr), .bOut(s3_k1_yr));
    logic [59:0] s3_o1;
    logic [59:0] s3_o1_h_x, s3_o1_h;
    assign s3_o1_h_x = s3_k1_xr;
    always_ff @(posedge clk) s3_o1_h <= mx_65[0] ? (60'(s3_o1_h_x >> 1) + (s3_o1_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o1_h_x;
    assign s3_o1 = s3_o1_h;
    logic [59:0] s3_o9;
    logic [59:0] s3_o9_h_x, s3_o9_h;
    assign s3_o9_h_x = s3_k1_yr;
    always_ff @(posedge clk) s3_o9_h <= mx_65[0] ? (60'(s3_o9_h_x >> 1) + (s3_o9_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o9_h_x;
    assign s3_o9 = s3_o9_h;
    logic [59:0] tws50_o50;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(50)) tws50_o50_dly (.clk(clk), .din(tw_s50), .dout(tws50_o50));
    logic [59:0] s3_k2_xr; logic [59:0] s3_k2_yr;
    MS_N12_q60_P32_tpm_p2_core_s3_bu s3_k2 (.clk(clk), .aIn(s2_o2), .bIn(s2_o10), .W(tws50_o50), .QH(s3q_QH), .aOut(s3_k2_xr), .bOut(s3_k2_yr));
    logic [59:0] s3_o2;
    logic [59:0] s3_o2_h_x, s3_o2_h;
    assign s3_o2_h_x = s3_k2_xr;
    always_ff @(posedge clk) s3_o2_h <= mx_65[0] ? (60'(s3_o2_h_x >> 1) + (s3_o2_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o2_h_x;
    assign s3_o2 = s3_o2_h;
    logic [59:0] s3_o10;
    logic [59:0] s3_o10_h_x, s3_o10_h;
    assign s3_o10_h_x = s3_k2_yr;
    always_ff @(posedge clk) s3_o10_h <= mx_65[0] ? (60'(s3_o10_h_x >> 1) + (s3_o10_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o10_h_x;
    assign s3_o10 = s3_o10_h;
    logic [59:0] tws51_o50;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(50)) tws51_o50_dly (.clk(clk), .din(tw_s51), .dout(tws51_o50));
    logic [59:0] s3_k3_xr; logic [59:0] s3_k3_yr;
    MS_N12_q60_P32_tpm_p2_core_s3_bu s3_k3 (.clk(clk), .aIn(s2_o3), .bIn(s2_o11), .W(tws51_o50), .QH(s3q_QH), .aOut(s3_k3_xr), .bOut(s3_k3_yr));
    logic [59:0] s3_o3;
    logic [59:0] s3_o3_h_x, s3_o3_h;
    assign s3_o3_h_x = s3_k3_xr;
    always_ff @(posedge clk) s3_o3_h <= mx_65[0] ? (60'(s3_o3_h_x >> 1) + (s3_o3_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o3_h_x;
    assign s3_o3 = s3_o3_h;
    logic [59:0] s3_o11;
    logic [59:0] s3_o11_h_x, s3_o11_h;
    assign s3_o11_h_x = s3_k3_yr;
    always_ff @(posedge clk) s3_o11_h <= mx_65[0] ? (60'(s3_o11_h_x >> 1) + (s3_o11_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o11_h_x;
    assign s3_o11 = s3_o11_h;
    logic [59:0] tws52_o50;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(50)) tws52_o50_dly (.clk(clk), .din(tw_s52), .dout(tws52_o50));
    logic [59:0] s3_k4_xr; logic [59:0] s3_k4_yr;
    MS_N12_q60_P32_tpm_p2_core_s3_bu s3_k4 (.clk(clk), .aIn(s2_o4), .bIn(s2_o12), .W(tws52_o50), .QH(s3q_QH), .aOut(s3_k4_xr), .bOut(s3_k4_yr));
    logic [59:0] s3_o4;
    logic [59:0] s3_o4_h_x, s3_o4_h;
    assign s3_o4_h_x = s3_k4_xr;
    always_ff @(posedge clk) s3_o4_h <= mx_65[0] ? (60'(s3_o4_h_x >> 1) + (s3_o4_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o4_h_x;
    assign s3_o4 = s3_o4_h;
    logic [59:0] s3_o12;
    logic [59:0] s3_o12_h_x, s3_o12_h;
    assign s3_o12_h_x = s3_k4_yr;
    always_ff @(posedge clk) s3_o12_h <= mx_65[0] ? (60'(s3_o12_h_x >> 1) + (s3_o12_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o12_h_x;
    assign s3_o12 = s3_o12_h;
    logic [59:0] tws53_o50;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(50)) tws53_o50_dly (.clk(clk), .din(tw_s53), .dout(tws53_o50));
    logic [59:0] s3_k5_xr; logic [59:0] s3_k5_yr;
    MS_N12_q60_P32_tpm_p2_core_s3_bu s3_k5 (.clk(clk), .aIn(s2_o5), .bIn(s2_o13), .W(tws53_o50), .QH(s3q_QH), .aOut(s3_k5_xr), .bOut(s3_k5_yr));
    logic [59:0] s3_o5;
    logic [59:0] s3_o5_h_x, s3_o5_h;
    assign s3_o5_h_x = s3_k5_xr;
    always_ff @(posedge clk) s3_o5_h <= mx_65[0] ? (60'(s3_o5_h_x >> 1) + (s3_o5_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o5_h_x;
    assign s3_o5 = s3_o5_h;
    logic [59:0] s3_o13;
    logic [59:0] s3_o13_h_x, s3_o13_h;
    assign s3_o13_h_x = s3_k5_yr;
    always_ff @(posedge clk) s3_o13_h <= mx_65[0] ? (60'(s3_o13_h_x >> 1) + (s3_o13_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o13_h_x;
    assign s3_o13 = s3_o13_h;
    logic [59:0] tws54_o50;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(50)) tws54_o50_dly (.clk(clk), .din(tw_s54), .dout(tws54_o50));
    logic [59:0] s3_k6_xr; logic [59:0] s3_k6_yr;
    MS_N12_q60_P32_tpm_p2_core_s3_bu s3_k6 (.clk(clk), .aIn(s2_o6), .bIn(s2_o14), .W(tws54_o50), .QH(s3q_QH), .aOut(s3_k6_xr), .bOut(s3_k6_yr));
    logic [59:0] s3_o6;
    logic [59:0] s3_o6_h_x, s3_o6_h;
    assign s3_o6_h_x = s3_k6_xr;
    always_ff @(posedge clk) s3_o6_h <= mx_65[0] ? (60'(s3_o6_h_x >> 1) + (s3_o6_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o6_h_x;
    assign s3_o6 = s3_o6_h;
    logic [59:0] s3_o14;
    logic [59:0] s3_o14_h_x, s3_o14_h;
    assign s3_o14_h_x = s3_k6_yr;
    always_ff @(posedge clk) s3_o14_h <= mx_65[0] ? (60'(s3_o14_h_x >> 1) + (s3_o14_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o14_h_x;
    assign s3_o14 = s3_o14_h;
    logic [59:0] tws55_o50;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(50)) tws55_o50_dly (.clk(clk), .din(tw_s55), .dout(tws55_o50));
    logic [59:0] s3_k7_xr; logic [59:0] s3_k7_yr;
    MS_N12_q60_P32_tpm_p2_core_s3_bu s3_k7 (.clk(clk), .aIn(s2_o7), .bIn(s2_o15), .W(tws55_o50), .QH(s3q_QH), .aOut(s3_k7_xr), .bOut(s3_k7_yr));
    logic [59:0] s3_o7;
    logic [59:0] s3_o7_h_x, s3_o7_h;
    assign s3_o7_h_x = s3_k7_xr;
    always_ff @(posedge clk) s3_o7_h <= mx_65[0] ? (60'(s3_o7_h_x >> 1) + (s3_o7_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o7_h_x;
    assign s3_o7 = s3_o7_h;
    logic [59:0] s3_o15;
    logic [59:0] s3_o15_h_x, s3_o15_h;
    assign s3_o15_h_x = s3_k7_yr;
    always_ff @(posedge clk) s3_o15_h <= mx_65[0] ? (60'(s3_o15_h_x >> 1) + (s3_o15_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o15_h_x;
    assign s3_o15 = s3_o15_h;
    logic [59:0] tws56_o50;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(50)) tws56_o50_dly (.clk(clk), .din(tw_s56), .dout(tws56_o50));
    logic [59:0] s3_k8_xr; logic [59:0] s3_k8_yr;
    MS_N12_q60_P32_tpm_p2_core_s3_bu s3_k8 (.clk(clk), .aIn(s2_o16), .bIn(s2_o24), .W(tws56_o50), .QH(s3q_QH), .aOut(s3_k8_xr), .bOut(s3_k8_yr));
    logic [59:0] s3_o16;
    logic [59:0] s3_o16_h_x, s3_o16_h;
    assign s3_o16_h_x = s3_k8_xr;
    always_ff @(posedge clk) s3_o16_h <= mx_65[0] ? (60'(s3_o16_h_x >> 1) + (s3_o16_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o16_h_x;
    assign s3_o16 = s3_o16_h;
    logic [59:0] s3_o24;
    logic [59:0] s3_o24_h_x, s3_o24_h;
    assign s3_o24_h_x = s3_k8_yr;
    always_ff @(posedge clk) s3_o24_h <= mx_65[0] ? (60'(s3_o24_h_x >> 1) + (s3_o24_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o24_h_x;
    assign s3_o24 = s3_o24_h;
    logic [59:0] tws57_o50;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(50)) tws57_o50_dly (.clk(clk), .din(tw_s57), .dout(tws57_o50));
    logic [59:0] s3_k9_xr; logic [59:0] s3_k9_yr;
    MS_N12_q60_P32_tpm_p2_core_s3_bu s3_k9 (.clk(clk), .aIn(s2_o17), .bIn(s2_o25), .W(tws57_o50), .QH(s3q_QH), .aOut(s3_k9_xr), .bOut(s3_k9_yr));
    logic [59:0] s3_o17;
    logic [59:0] s3_o17_h_x, s3_o17_h;
    assign s3_o17_h_x = s3_k9_xr;
    always_ff @(posedge clk) s3_o17_h <= mx_65[0] ? (60'(s3_o17_h_x >> 1) + (s3_o17_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o17_h_x;
    assign s3_o17 = s3_o17_h;
    logic [59:0] s3_o25;
    logic [59:0] s3_o25_h_x, s3_o25_h;
    assign s3_o25_h_x = s3_k9_yr;
    always_ff @(posedge clk) s3_o25_h <= mx_65[0] ? (60'(s3_o25_h_x >> 1) + (s3_o25_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o25_h_x;
    assign s3_o25 = s3_o25_h;
    logic [59:0] tws58_o50;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(50)) tws58_o50_dly (.clk(clk), .din(tw_s58), .dout(tws58_o50));
    logic [59:0] s3_k10_xr; logic [59:0] s3_k10_yr;
    MS_N12_q60_P32_tpm_p2_core_s3_bu s3_k10 (.clk(clk), .aIn(s2_o18), .bIn(s2_o26), .W(tws58_o50), .QH(s3q_QH), .aOut(s3_k10_xr), .bOut(s3_k10_yr));
    logic [59:0] s3_o18;
    logic [59:0] s3_o18_h_x, s3_o18_h;
    assign s3_o18_h_x = s3_k10_xr;
    always_ff @(posedge clk) s3_o18_h <= mx_65[0] ? (60'(s3_o18_h_x >> 1) + (s3_o18_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o18_h_x;
    assign s3_o18 = s3_o18_h;
    logic [59:0] s3_o26;
    logic [59:0] s3_o26_h_x, s3_o26_h;
    assign s3_o26_h_x = s3_k10_yr;
    always_ff @(posedge clk) s3_o26_h <= mx_65[0] ? (60'(s3_o26_h_x >> 1) + (s3_o26_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o26_h_x;
    assign s3_o26 = s3_o26_h;
    logic [59:0] tws59_o50;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(50)) tws59_o50_dly (.clk(clk), .din(tw_s59), .dout(tws59_o50));
    logic [59:0] s3_k11_xr; logic [59:0] s3_k11_yr;
    MS_N12_q60_P32_tpm_p2_core_s3_bu s3_k11 (.clk(clk), .aIn(s2_o19), .bIn(s2_o27), .W(tws59_o50), .QH(s3q_QH), .aOut(s3_k11_xr), .bOut(s3_k11_yr));
    logic [59:0] s3_o19;
    logic [59:0] s3_o19_h_x, s3_o19_h;
    assign s3_o19_h_x = s3_k11_xr;
    always_ff @(posedge clk) s3_o19_h <= mx_65[0] ? (60'(s3_o19_h_x >> 1) + (s3_o19_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o19_h_x;
    assign s3_o19 = s3_o19_h;
    logic [59:0] s3_o27;
    logic [59:0] s3_o27_h_x, s3_o27_h;
    assign s3_o27_h_x = s3_k11_yr;
    always_ff @(posedge clk) s3_o27_h <= mx_65[0] ? (60'(s3_o27_h_x >> 1) + (s3_o27_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o27_h_x;
    assign s3_o27 = s3_o27_h;
    logic [59:0] tws60_o50;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(50)) tws60_o50_dly (.clk(clk), .din(tw_s60), .dout(tws60_o50));
    logic [59:0] s3_k12_xr; logic [59:0] s3_k12_yr;
    MS_N12_q60_P32_tpm_p2_core_s3_bu s3_k12 (.clk(clk), .aIn(s2_o20), .bIn(s2_o28), .W(tws60_o50), .QH(s3q_QH), .aOut(s3_k12_xr), .bOut(s3_k12_yr));
    logic [59:0] s3_o20;
    logic [59:0] s3_o20_h_x, s3_o20_h;
    assign s3_o20_h_x = s3_k12_xr;
    always_ff @(posedge clk) s3_o20_h <= mx_65[0] ? (60'(s3_o20_h_x >> 1) + (s3_o20_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o20_h_x;
    assign s3_o20 = s3_o20_h;
    logic [59:0] s3_o28;
    logic [59:0] s3_o28_h_x, s3_o28_h;
    assign s3_o28_h_x = s3_k12_yr;
    always_ff @(posedge clk) s3_o28_h <= mx_65[0] ? (60'(s3_o28_h_x >> 1) + (s3_o28_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o28_h_x;
    assign s3_o28 = s3_o28_h;
    logic [59:0] tws61_o50;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(50)) tws61_o50_dly (.clk(clk), .din(tw_s61), .dout(tws61_o50));
    logic [59:0] s3_k13_xr; logic [59:0] s3_k13_yr;
    MS_N12_q60_P32_tpm_p2_core_s3_bu s3_k13 (.clk(clk), .aIn(s2_o21), .bIn(s2_o29), .W(tws61_o50), .QH(s3q_QH), .aOut(s3_k13_xr), .bOut(s3_k13_yr));
    logic [59:0] s3_o21;
    logic [59:0] s3_o21_h_x, s3_o21_h;
    assign s3_o21_h_x = s3_k13_xr;
    always_ff @(posedge clk) s3_o21_h <= mx_65[0] ? (60'(s3_o21_h_x >> 1) + (s3_o21_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o21_h_x;
    assign s3_o21 = s3_o21_h;
    logic [59:0] s3_o29;
    logic [59:0] s3_o29_h_x, s3_o29_h;
    assign s3_o29_h_x = s3_k13_yr;
    always_ff @(posedge clk) s3_o29_h <= mx_65[0] ? (60'(s3_o29_h_x >> 1) + (s3_o29_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o29_h_x;
    assign s3_o29 = s3_o29_h;
    logic [59:0] tws62_o50;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(50)) tws62_o50_dly (.clk(clk), .din(tw_s62), .dout(tws62_o50));
    logic [59:0] s3_k14_xr; logic [59:0] s3_k14_yr;
    MS_N12_q60_P32_tpm_p2_core_s3_bu s3_k14 (.clk(clk), .aIn(s2_o22), .bIn(s2_o30), .W(tws62_o50), .QH(s3q_QH), .aOut(s3_k14_xr), .bOut(s3_k14_yr));
    logic [59:0] s3_o22;
    logic [59:0] s3_o22_h_x, s3_o22_h;
    assign s3_o22_h_x = s3_k14_xr;
    always_ff @(posedge clk) s3_o22_h <= mx_65[0] ? (60'(s3_o22_h_x >> 1) + (s3_o22_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o22_h_x;
    assign s3_o22 = s3_o22_h;
    logic [59:0] s3_o30;
    logic [59:0] s3_o30_h_x, s3_o30_h;
    assign s3_o30_h_x = s3_k14_yr;
    always_ff @(posedge clk) s3_o30_h <= mx_65[0] ? (60'(s3_o30_h_x >> 1) + (s3_o30_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o30_h_x;
    assign s3_o30 = s3_o30_h;
    logic [59:0] tws63_o50;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(50)) tws63_o50_dly (.clk(clk), .din(tw_s63), .dout(tws63_o50));
    logic [59:0] s3_k15_xr; logic [59:0] s3_k15_yr;
    MS_N12_q60_P32_tpm_p2_core_s3_bu s3_k15 (.clk(clk), .aIn(s2_o23), .bIn(s2_o31), .W(tws63_o50), .QH(s3q_QH), .aOut(s3_k15_xr), .bOut(s3_k15_yr));
    logic [59:0] s3_o23;
    logic [59:0] s3_o23_h_x, s3_o23_h;
    assign s3_o23_h_x = s3_k15_xr;
    always_ff @(posedge clk) s3_o23_h <= mx_65[0] ? (60'(s3_o23_h_x >> 1) + (s3_o23_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o23_h_x;
    assign s3_o23 = s3_o23_h;
    logic [59:0] s3_o31;
    logic [59:0] s3_o31_h_x, s3_o31_h;
    assign s3_o31_h_x = s3_k15_yr;
    always_ff @(posedge clk) s3_o31_h <= mx_65[0] ? (60'(s3_o31_h_x >> 1) + (s3_o31_h_x[0] ? 60'(s3q_QHALF) : 60'd0)) : s3_o31_h_x;
    assign s3_o31 = s3_o31_h;
    // stage 4: 16 butterflies on lane pairs (bit 4), latency 15
    logic [59:0] tws64_o66;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(66)) tws64_o66_dly (.clk(clk), .din(tw_s64), .dout(tws64_o66));
    (* max_fanout = 16 *) logic [16:0] s4q_QH;
    always_ff @(posedge clk) s4q_QH <= QH_r;
    logic [59:0] s4_k0_xr; logic [59:0] s4_k0_yr;
    MS_N12_q60_P32_tpm_p2_core_s4_bu s4_k0 (.clk(clk), .aIn(s3_o0), .bIn(s3_o16), .W(tws64_o66), .QH(s4q_QH), .aOut(s4_k0_xr), .bOut(s4_k0_yr));
    logic [59:0] s4_o0;
    (* max_fanout = 16 *) logic [59:0] s4q_QHALF;
    always_ff @(posedge clk) s4q_QHALF <= QHALF_r;
    logic [59:0] s4_o0_h_x, s4_o0_h;
    assign s4_o0_h_x = s4_k0_xr;
    (* max_fanout = 16 *) logic [0:0] mx_66;
    always_ff @(posedge clk) mx_66 <= mx_65;
    (* max_fanout = 16 *) logic [0:0] mx_67;
    always_ff @(posedge clk) mx_67 <= mx_66;
    (* max_fanout = 16 *) logic [0:0] mx_68;
    always_ff @(posedge clk) mx_68 <= mx_67;
    (* max_fanout = 16 *) logic [0:0] mx_69;
    always_ff @(posedge clk) mx_69 <= mx_68;
    (* max_fanout = 16 *) logic [0:0] mx_70;
    always_ff @(posedge clk) mx_70 <= mx_69;
    (* max_fanout = 16 *) logic [0:0] mx_71;
    always_ff @(posedge clk) mx_71 <= mx_70;
    (* max_fanout = 16 *) logic [0:0] mx_72;
    always_ff @(posedge clk) mx_72 <= mx_71;
    (* max_fanout = 16 *) logic [0:0] mx_73;
    always_ff @(posedge clk) mx_73 <= mx_72;
    (* max_fanout = 16 *) logic [0:0] mx_74;
    always_ff @(posedge clk) mx_74 <= mx_73;
    (* max_fanout = 16 *) logic [0:0] mx_75;
    always_ff @(posedge clk) mx_75 <= mx_74;
    (* max_fanout = 16 *) logic [0:0] mx_76;
    always_ff @(posedge clk) mx_76 <= mx_75;
    (* max_fanout = 16 *) logic [0:0] mx_77;
    always_ff @(posedge clk) mx_77 <= mx_76;
    (* max_fanout = 16 *) logic [0:0] mx_78;
    always_ff @(posedge clk) mx_78 <= mx_77;
    (* max_fanout = 16 *) logic [0:0] mx_79;
    always_ff @(posedge clk) mx_79 <= mx_78;
    (* max_fanout = 16 *) logic [0:0] mx_80;
    always_ff @(posedge clk) mx_80 <= mx_79;
    (* max_fanout = 16 *) logic [0:0] mx_81;
    always_ff @(posedge clk) mx_81 <= mx_80;
    always_ff @(posedge clk) s4_o0_h <= mx_81[0] ? (60'(s4_o0_h_x >> 1) + (s4_o0_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o0_h_x;
    assign s4_o0 = s4_o0_h;
    logic [59:0] s4_o16;
    logic [59:0] s4_o16_h_x, s4_o16_h;
    assign s4_o16_h_x = s4_k0_yr;
    always_ff @(posedge clk) s4_o16_h <= mx_81[0] ? (60'(s4_o16_h_x >> 1) + (s4_o16_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o16_h_x;
    assign s4_o16 = s4_o16_h;
    logic [59:0] tws65_o66;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(66)) tws65_o66_dly (.clk(clk), .din(tw_s65), .dout(tws65_o66));
    logic [59:0] s4_k1_xr; logic [59:0] s4_k1_yr;
    MS_N12_q60_P32_tpm_p2_core_s4_bu s4_k1 (.clk(clk), .aIn(s3_o1), .bIn(s3_o17), .W(tws65_o66), .QH(s4q_QH), .aOut(s4_k1_xr), .bOut(s4_k1_yr));
    logic [59:0] s4_o1;
    logic [59:0] s4_o1_h_x, s4_o1_h;
    assign s4_o1_h_x = s4_k1_xr;
    always_ff @(posedge clk) s4_o1_h <= mx_81[0] ? (60'(s4_o1_h_x >> 1) + (s4_o1_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o1_h_x;
    assign s4_o1 = s4_o1_h;
    logic [59:0] s4_o17;
    logic [59:0] s4_o17_h_x, s4_o17_h;
    assign s4_o17_h_x = s4_k1_yr;
    always_ff @(posedge clk) s4_o17_h <= mx_81[0] ? (60'(s4_o17_h_x >> 1) + (s4_o17_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o17_h_x;
    assign s4_o17 = s4_o17_h;
    logic [59:0] tws66_o66;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(66)) tws66_o66_dly (.clk(clk), .din(tw_s66), .dout(tws66_o66));
    logic [59:0] s4_k2_xr; logic [59:0] s4_k2_yr;
    MS_N12_q60_P32_tpm_p2_core_s4_bu s4_k2 (.clk(clk), .aIn(s3_o2), .bIn(s3_o18), .W(tws66_o66), .QH(s4q_QH), .aOut(s4_k2_xr), .bOut(s4_k2_yr));
    logic [59:0] s4_o2;
    logic [59:0] s4_o2_h_x, s4_o2_h;
    assign s4_o2_h_x = s4_k2_xr;
    always_ff @(posedge clk) s4_o2_h <= mx_81[0] ? (60'(s4_o2_h_x >> 1) + (s4_o2_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o2_h_x;
    assign s4_o2 = s4_o2_h;
    logic [59:0] s4_o18;
    logic [59:0] s4_o18_h_x, s4_o18_h;
    assign s4_o18_h_x = s4_k2_yr;
    always_ff @(posedge clk) s4_o18_h <= mx_81[0] ? (60'(s4_o18_h_x >> 1) + (s4_o18_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o18_h_x;
    assign s4_o18 = s4_o18_h;
    logic [59:0] tws67_o66;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(66)) tws67_o66_dly (.clk(clk), .din(tw_s67), .dout(tws67_o66));
    logic [59:0] s4_k3_xr; logic [59:0] s4_k3_yr;
    MS_N12_q60_P32_tpm_p2_core_s4_bu s4_k3 (.clk(clk), .aIn(s3_o3), .bIn(s3_o19), .W(tws67_o66), .QH(s4q_QH), .aOut(s4_k3_xr), .bOut(s4_k3_yr));
    logic [59:0] s4_o3;
    logic [59:0] s4_o3_h_x, s4_o3_h;
    assign s4_o3_h_x = s4_k3_xr;
    always_ff @(posedge clk) s4_o3_h <= mx_81[0] ? (60'(s4_o3_h_x >> 1) + (s4_o3_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o3_h_x;
    assign s4_o3 = s4_o3_h;
    logic [59:0] s4_o19;
    logic [59:0] s4_o19_h_x, s4_o19_h;
    assign s4_o19_h_x = s4_k3_yr;
    always_ff @(posedge clk) s4_o19_h <= mx_81[0] ? (60'(s4_o19_h_x >> 1) + (s4_o19_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o19_h_x;
    assign s4_o19 = s4_o19_h;
    logic [59:0] tws68_o66;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(66)) tws68_o66_dly (.clk(clk), .din(tw_s68), .dout(tws68_o66));
    logic [59:0] s4_k4_xr; logic [59:0] s4_k4_yr;
    MS_N12_q60_P32_tpm_p2_core_s4_bu s4_k4 (.clk(clk), .aIn(s3_o4), .bIn(s3_o20), .W(tws68_o66), .QH(s4q_QH), .aOut(s4_k4_xr), .bOut(s4_k4_yr));
    logic [59:0] s4_o4;
    logic [59:0] s4_o4_h_x, s4_o4_h;
    assign s4_o4_h_x = s4_k4_xr;
    always_ff @(posedge clk) s4_o4_h <= mx_81[0] ? (60'(s4_o4_h_x >> 1) + (s4_o4_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o4_h_x;
    assign s4_o4 = s4_o4_h;
    logic [59:0] s4_o20;
    logic [59:0] s4_o20_h_x, s4_o20_h;
    assign s4_o20_h_x = s4_k4_yr;
    always_ff @(posedge clk) s4_o20_h <= mx_81[0] ? (60'(s4_o20_h_x >> 1) + (s4_o20_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o20_h_x;
    assign s4_o20 = s4_o20_h;
    logic [59:0] tws69_o66;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(66)) tws69_o66_dly (.clk(clk), .din(tw_s69), .dout(tws69_o66));
    logic [59:0] s4_k5_xr; logic [59:0] s4_k5_yr;
    MS_N12_q60_P32_tpm_p2_core_s4_bu s4_k5 (.clk(clk), .aIn(s3_o5), .bIn(s3_o21), .W(tws69_o66), .QH(s4q_QH), .aOut(s4_k5_xr), .bOut(s4_k5_yr));
    logic [59:0] s4_o5;
    logic [59:0] s4_o5_h_x, s4_o5_h;
    assign s4_o5_h_x = s4_k5_xr;
    always_ff @(posedge clk) s4_o5_h <= mx_81[0] ? (60'(s4_o5_h_x >> 1) + (s4_o5_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o5_h_x;
    assign s4_o5 = s4_o5_h;
    logic [59:0] s4_o21;
    logic [59:0] s4_o21_h_x, s4_o21_h;
    assign s4_o21_h_x = s4_k5_yr;
    always_ff @(posedge clk) s4_o21_h <= mx_81[0] ? (60'(s4_o21_h_x >> 1) + (s4_o21_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o21_h_x;
    assign s4_o21 = s4_o21_h;
    logic [59:0] tws70_o66;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(66)) tws70_o66_dly (.clk(clk), .din(tw_s70), .dout(tws70_o66));
    logic [59:0] s4_k6_xr; logic [59:0] s4_k6_yr;
    MS_N12_q60_P32_tpm_p2_core_s4_bu s4_k6 (.clk(clk), .aIn(s3_o6), .bIn(s3_o22), .W(tws70_o66), .QH(s4q_QH), .aOut(s4_k6_xr), .bOut(s4_k6_yr));
    logic [59:0] s4_o6;
    logic [59:0] s4_o6_h_x, s4_o6_h;
    assign s4_o6_h_x = s4_k6_xr;
    always_ff @(posedge clk) s4_o6_h <= mx_81[0] ? (60'(s4_o6_h_x >> 1) + (s4_o6_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o6_h_x;
    assign s4_o6 = s4_o6_h;
    logic [59:0] s4_o22;
    logic [59:0] s4_o22_h_x, s4_o22_h;
    assign s4_o22_h_x = s4_k6_yr;
    always_ff @(posedge clk) s4_o22_h <= mx_81[0] ? (60'(s4_o22_h_x >> 1) + (s4_o22_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o22_h_x;
    assign s4_o22 = s4_o22_h;
    logic [59:0] tws71_o66;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(66)) tws71_o66_dly (.clk(clk), .din(tw_s71), .dout(tws71_o66));
    logic [59:0] s4_k7_xr; logic [59:0] s4_k7_yr;
    MS_N12_q60_P32_tpm_p2_core_s4_bu s4_k7 (.clk(clk), .aIn(s3_o7), .bIn(s3_o23), .W(tws71_o66), .QH(s4q_QH), .aOut(s4_k7_xr), .bOut(s4_k7_yr));
    logic [59:0] s4_o7;
    logic [59:0] s4_o7_h_x, s4_o7_h;
    assign s4_o7_h_x = s4_k7_xr;
    always_ff @(posedge clk) s4_o7_h <= mx_81[0] ? (60'(s4_o7_h_x >> 1) + (s4_o7_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o7_h_x;
    assign s4_o7 = s4_o7_h;
    logic [59:0] s4_o23;
    logic [59:0] s4_o23_h_x, s4_o23_h;
    assign s4_o23_h_x = s4_k7_yr;
    always_ff @(posedge clk) s4_o23_h <= mx_81[0] ? (60'(s4_o23_h_x >> 1) + (s4_o23_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o23_h_x;
    assign s4_o23 = s4_o23_h;
    logic [59:0] tws72_o66;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(66)) tws72_o66_dly (.clk(clk), .din(tw_s72), .dout(tws72_o66));
    logic [59:0] s4_k8_xr; logic [59:0] s4_k8_yr;
    MS_N12_q60_P32_tpm_p2_core_s4_bu s4_k8 (.clk(clk), .aIn(s3_o8), .bIn(s3_o24), .W(tws72_o66), .QH(s4q_QH), .aOut(s4_k8_xr), .bOut(s4_k8_yr));
    logic [59:0] s4_o8;
    logic [59:0] s4_o8_h_x, s4_o8_h;
    assign s4_o8_h_x = s4_k8_xr;
    always_ff @(posedge clk) s4_o8_h <= mx_81[0] ? (60'(s4_o8_h_x >> 1) + (s4_o8_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o8_h_x;
    assign s4_o8 = s4_o8_h;
    logic [59:0] s4_o24;
    logic [59:0] s4_o24_h_x, s4_o24_h;
    assign s4_o24_h_x = s4_k8_yr;
    always_ff @(posedge clk) s4_o24_h <= mx_81[0] ? (60'(s4_o24_h_x >> 1) + (s4_o24_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o24_h_x;
    assign s4_o24 = s4_o24_h;
    logic [59:0] tws73_o66;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(66)) tws73_o66_dly (.clk(clk), .din(tw_s73), .dout(tws73_o66));
    logic [59:0] s4_k9_xr; logic [59:0] s4_k9_yr;
    MS_N12_q60_P32_tpm_p2_core_s4_bu s4_k9 (.clk(clk), .aIn(s3_o9), .bIn(s3_o25), .W(tws73_o66), .QH(s4q_QH), .aOut(s4_k9_xr), .bOut(s4_k9_yr));
    logic [59:0] s4_o9;
    logic [59:0] s4_o9_h_x, s4_o9_h;
    assign s4_o9_h_x = s4_k9_xr;
    always_ff @(posedge clk) s4_o9_h <= mx_81[0] ? (60'(s4_o9_h_x >> 1) + (s4_o9_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o9_h_x;
    assign s4_o9 = s4_o9_h;
    logic [59:0] s4_o25;
    logic [59:0] s4_o25_h_x, s4_o25_h;
    assign s4_o25_h_x = s4_k9_yr;
    always_ff @(posedge clk) s4_o25_h <= mx_81[0] ? (60'(s4_o25_h_x >> 1) + (s4_o25_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o25_h_x;
    assign s4_o25 = s4_o25_h;
    logic [59:0] tws74_o66;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(66)) tws74_o66_dly (.clk(clk), .din(tw_s74), .dout(tws74_o66));
    logic [59:0] s4_k10_xr; logic [59:0] s4_k10_yr;
    MS_N12_q60_P32_tpm_p2_core_s4_bu s4_k10 (.clk(clk), .aIn(s3_o10), .bIn(s3_o26), .W(tws74_o66), .QH(s4q_QH), .aOut(s4_k10_xr), .bOut(s4_k10_yr));
    logic [59:0] s4_o10;
    logic [59:0] s4_o10_h_x, s4_o10_h;
    assign s4_o10_h_x = s4_k10_xr;
    always_ff @(posedge clk) s4_o10_h <= mx_81[0] ? (60'(s4_o10_h_x >> 1) + (s4_o10_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o10_h_x;
    assign s4_o10 = s4_o10_h;
    logic [59:0] s4_o26;
    logic [59:0] s4_o26_h_x, s4_o26_h;
    assign s4_o26_h_x = s4_k10_yr;
    always_ff @(posedge clk) s4_o26_h <= mx_81[0] ? (60'(s4_o26_h_x >> 1) + (s4_o26_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o26_h_x;
    assign s4_o26 = s4_o26_h;
    logic [59:0] tws75_o66;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(66)) tws75_o66_dly (.clk(clk), .din(tw_s75), .dout(tws75_o66));
    logic [59:0] s4_k11_xr; logic [59:0] s4_k11_yr;
    MS_N12_q60_P32_tpm_p2_core_s4_bu s4_k11 (.clk(clk), .aIn(s3_o11), .bIn(s3_o27), .W(tws75_o66), .QH(s4q_QH), .aOut(s4_k11_xr), .bOut(s4_k11_yr));
    logic [59:0] s4_o11;
    logic [59:0] s4_o11_h_x, s4_o11_h;
    assign s4_o11_h_x = s4_k11_xr;
    always_ff @(posedge clk) s4_o11_h <= mx_81[0] ? (60'(s4_o11_h_x >> 1) + (s4_o11_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o11_h_x;
    assign s4_o11 = s4_o11_h;
    logic [59:0] s4_o27;
    logic [59:0] s4_o27_h_x, s4_o27_h;
    assign s4_o27_h_x = s4_k11_yr;
    always_ff @(posedge clk) s4_o27_h <= mx_81[0] ? (60'(s4_o27_h_x >> 1) + (s4_o27_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o27_h_x;
    assign s4_o27 = s4_o27_h;
    logic [59:0] tws76_o66;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(66)) tws76_o66_dly (.clk(clk), .din(tw_s76), .dout(tws76_o66));
    logic [59:0] s4_k12_xr; logic [59:0] s4_k12_yr;
    MS_N12_q60_P32_tpm_p2_core_s4_bu s4_k12 (.clk(clk), .aIn(s3_o12), .bIn(s3_o28), .W(tws76_o66), .QH(s4q_QH), .aOut(s4_k12_xr), .bOut(s4_k12_yr));
    logic [59:0] s4_o12;
    logic [59:0] s4_o12_h_x, s4_o12_h;
    assign s4_o12_h_x = s4_k12_xr;
    always_ff @(posedge clk) s4_o12_h <= mx_81[0] ? (60'(s4_o12_h_x >> 1) + (s4_o12_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o12_h_x;
    assign s4_o12 = s4_o12_h;
    logic [59:0] s4_o28;
    logic [59:0] s4_o28_h_x, s4_o28_h;
    assign s4_o28_h_x = s4_k12_yr;
    always_ff @(posedge clk) s4_o28_h <= mx_81[0] ? (60'(s4_o28_h_x >> 1) + (s4_o28_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o28_h_x;
    assign s4_o28 = s4_o28_h;
    logic [59:0] tws77_o66;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(66)) tws77_o66_dly (.clk(clk), .din(tw_s77), .dout(tws77_o66));
    logic [59:0] s4_k13_xr; logic [59:0] s4_k13_yr;
    MS_N12_q60_P32_tpm_p2_core_s4_bu s4_k13 (.clk(clk), .aIn(s3_o13), .bIn(s3_o29), .W(tws77_o66), .QH(s4q_QH), .aOut(s4_k13_xr), .bOut(s4_k13_yr));
    logic [59:0] s4_o13;
    logic [59:0] s4_o13_h_x, s4_o13_h;
    assign s4_o13_h_x = s4_k13_xr;
    always_ff @(posedge clk) s4_o13_h <= mx_81[0] ? (60'(s4_o13_h_x >> 1) + (s4_o13_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o13_h_x;
    assign s4_o13 = s4_o13_h;
    logic [59:0] s4_o29;
    logic [59:0] s4_o29_h_x, s4_o29_h;
    assign s4_o29_h_x = s4_k13_yr;
    always_ff @(posedge clk) s4_o29_h <= mx_81[0] ? (60'(s4_o29_h_x >> 1) + (s4_o29_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o29_h_x;
    assign s4_o29 = s4_o29_h;
    logic [59:0] tws78_o66;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(66)) tws78_o66_dly (.clk(clk), .din(tw_s78), .dout(tws78_o66));
    logic [59:0] s4_k14_xr; logic [59:0] s4_k14_yr;
    MS_N12_q60_P32_tpm_p2_core_s4_bu s4_k14 (.clk(clk), .aIn(s3_o14), .bIn(s3_o30), .W(tws78_o66), .QH(s4q_QH), .aOut(s4_k14_xr), .bOut(s4_k14_yr));
    logic [59:0] s4_o14;
    logic [59:0] s4_o14_h_x, s4_o14_h;
    assign s4_o14_h_x = s4_k14_xr;
    always_ff @(posedge clk) s4_o14_h <= mx_81[0] ? (60'(s4_o14_h_x >> 1) + (s4_o14_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o14_h_x;
    assign s4_o14 = s4_o14_h;
    logic [59:0] s4_o30;
    logic [59:0] s4_o30_h_x, s4_o30_h;
    assign s4_o30_h_x = s4_k14_yr;
    always_ff @(posedge clk) s4_o30_h <= mx_81[0] ? (60'(s4_o30_h_x >> 1) + (s4_o30_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o30_h_x;
    assign s4_o30 = s4_o30_h;
    logic [59:0] tws79_o66;
    MS_N12_q60_P32_tpm_p2_core_dly #(.W(60), .D(66)) tws79_o66_dly (.clk(clk), .din(tw_s79), .dout(tws79_o66));
    logic [59:0] s4_k15_xr; logic [59:0] s4_k15_yr;
    MS_N12_q60_P32_tpm_p2_core_s4_bu s4_k15 (.clk(clk), .aIn(s3_o15), .bIn(s3_o31), .W(tws79_o66), .QH(s4q_QH), .aOut(s4_k15_xr), .bOut(s4_k15_yr));
    logic [59:0] s4_o15;
    logic [59:0] s4_o15_h_x, s4_o15_h;
    assign s4_o15_h_x = s4_k15_xr;
    always_ff @(posedge clk) s4_o15_h <= mx_81[0] ? (60'(s4_o15_h_x >> 1) + (s4_o15_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o15_h_x;
    assign s4_o15 = s4_o15_h;
    logic [59:0] s4_o31;
    logic [59:0] s4_o31_h_x, s4_o31_h;
    assign s4_o31_h_x = s4_k15_yr;
    always_ff @(posedge clk) s4_o31_h <= mx_81[0] ? (60'(s4_o31_h_x >> 1) + (s4_o31_h_x[0] ? 60'(s4q_QHALF) : 60'd0)) : s4_o31_h_x;
    assign s4_o31 = s4_o31_h;
    assign y_out_0 = s4_o0;
    assign y_out_1 = s4_o1;
    assign y_out_2 = s4_o2;
    assign y_out_3 = s4_o3;
    assign y_out_4 = s4_o4;
    assign y_out_5 = s4_o5;
    assign y_out_6 = s4_o6;
    assign y_out_7 = s4_o7;
    assign y_out_8 = s4_o8;
    assign y_out_9 = s4_o9;
    assign y_out_10 = s4_o10;
    assign y_out_11 = s4_o11;
    assign y_out_12 = s4_o12;
    assign y_out_13 = s4_o13;
    assign y_out_14 = s4_o14;
    assign y_out_15 = s4_o15;
    assign y_out_16 = s4_o16;
    assign y_out_17 = s4_o17;
    assign y_out_18 = s4_o18;
    assign y_out_19 = s4_o19;
    assign y_out_20 = s4_o20;
    assign y_out_21 = s4_o21;
    assign y_out_22 = s4_o22;
    assign y_out_23 = s4_o23;
    assign y_out_24 = s4_o24;
    assign y_out_25 = s4_o25;
    assign y_out_26 = s4_o26;
    assign y_out_27 = s4_o27;
    assign y_out_28 = s4_o28;
    assign y_out_29 = s4_o29;
    assign y_out_30 = s4_o30;
    assign y_out_31 = s4_o31;
endmodule
