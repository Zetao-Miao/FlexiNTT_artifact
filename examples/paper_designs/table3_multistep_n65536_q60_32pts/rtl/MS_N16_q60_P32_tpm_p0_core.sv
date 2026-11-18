`timescale 1ns / 1ps
// MS_N16_q60_P32_tpm_p0_core: streaming NTT, n=4, 4 lanes, frame 1 cycles, run-time q, direction both, latency 33
module MS_N16_q60_P32_tpm_p0_core (
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
    output logic [59:0] y_out_0,
    output logic [59:0] y_out_1,
    output logic [59:0] y_out_2,
    output logic [59:0] y_out_3
    );
    (* max_fanout = 32 *) logic tw_rst_p, tw_wen_p; (* max_fanout = 32 *) logic [59:0] tw_wdata_p;
    always_ff @(posedge clk) begin tw_rst_p <= tw_rst; tw_wen_p <= tw_wen; tw_wdata_p <= tw_wdata; end
    (* max_fanout = 32 *) logic [2:0] tw_wi;
    always_ff @(posedge clk) tw_wi <= tw_rst_p ? '0 : (tw_wen_p ? tw_wi + 1'b1 : tw_wi);
    (* max_fanout = 32 *) logic [59:0] tw_wd_q;
    always_ff @(posedge clk) tw_wd_q <= tw_wdata_p;
    logic [0:0] mx_1;
    always_ff @(posedge clk) mx_1 <= DIR;
    // per-frame direction: input lead of 3 cycles
    logic [59:0] xl_0;
    MS_N16_q60_P32_tpm_p0_core_dly #(.W(60), .D(3)) xl0_dly (.clk(clk), .din(x_in_0), .dout(xl_0));
    logic [59:0] xl_1;
    MS_N16_q60_P32_tpm_p0_core_dly #(.W(60), .D(3)) xl1_dly (.clk(clk), .din(x_in_1), .dout(xl_1));
    logic [59:0] xl_2;
    MS_N16_q60_P32_tpm_p0_core_dly #(.W(60), .D(3)) xl2_dly (.clk(clk), .din(x_in_2), .dout(xl_2));
    logic [59:0] xl_3;
    MS_N16_q60_P32_tpm_p0_core_dly #(.W(60), .D(3)) xl3_dly (.clk(clk), .din(x_in_3), .dout(xl_3));
    (* max_fanout = 16 *) logic [16:0] QH_r;
    always_ff @(posedge clk) QH_r <= QH;
    (* max_fanout = 16 *) logic [59:0] QHALF_r;
    always_ff @(posedge clk) QHALF_r <= QHALF;
    // stage 0: 2 butterflies on lane pairs (bit 0), latency 14
    logic [59:0] s0_t0_c0_w;
    logic s0_t0_c0_tab_hit_c, s0_t0_c0_tab_hit; logic [2:0] s0_t0_c0_tab_rel;
    assign s0_t0_c0_tab_rel = tw_wi - 3'd0;
    assign s0_t0_c0_tab_hit_c = tw_wen_p && (tw_wi >= 3'd0) && (tw_wi < 3'd2);
    logic [0:0] s0_t0_c0_tab_col_c, s0_t0_c0_tab_col; logic [0:0] s0_t0_c0_tab_wa_c, s0_t0_c0_tab_wa;
    assign s0_t0_c0_tab_col_c = '0; assign s0_t0_c0_tab_wa_c = s0_t0_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s0_t0_c0_tab_hit <= s0_t0_c0_tab_hit_c; s0_t0_c0_tab_col <= s0_t0_c0_tab_col_c; s0_t0_c0_tab_wa <= s0_t0_c0_tab_wa_c; end
    logic s0_t0_c0_tab_hit_q; logic [0:0] s0_t0_c0_tab_col_q; logic [0:0] s0_t0_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s0_t0_c0_tab_wd_q;
    always_ff @(posedge clk) begin s0_t0_c0_tab_hit_q <= s0_t0_c0_tab_hit; s0_t0_c0_tab_col_q <= s0_t0_c0_tab_col; s0_t0_c0_tab_wa_q <= s0_t0_c0_tab_wa; s0_t0_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p0_core_tab0 s0_t0_c0_tab (.clk(clk), .addr({mx_1}), .we(s0_t0_c0_tab_hit_q), .wa(s0_t0_c0_tab_wa_q), .wcol(s0_t0_c0_tab_col_q), .wd(s0_t0_c0_tab_wd_q), .q0(s0_t0_c0_w));
    (* max_fanout = 16 *) logic [16:0] s0q_QH;
    always_ff @(posedge clk) s0q_QH <= QH_r;
    logic [59:0] s0_k0_xr; logic [59:0] s0_k0_yr;
    MS_N16_q60_P32_tpm_p0_core_s0_bu s0_k0 (.clk(clk), .aIn(xl_0), .bIn(xl_1), .W(s0_t0_c0_w), .QH(s0q_QH), .aOut(s0_k0_xr), .bOut(s0_k0_yr));
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
    logic [59:0] s0_k1_xr; logic [59:0] s0_k1_yr;
    MS_N16_q60_P32_tpm_p0_core_s0_bu s0_k1 (.clk(clk), .aIn(xl_2), .bIn(xl_3), .W(s0_t0_c0_w), .QH(s0q_QH), .aOut(s0_k1_xr), .bOut(s0_k1_yr));
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
    // stage 1: 2 butterflies on lane pairs (bit 1), latency 14
    logic [59:0] s1_t1_c0_w;
    logic s1_t1_c0_tab_hit_c, s1_t1_c0_tab_hit; logic [2:0] s1_t1_c0_tab_rel;
    assign s1_t1_c0_tab_rel = tw_wi - 3'd2;
    assign s1_t1_c0_tab_hit_c = tw_wen_p && (tw_wi >= 3'd2) && (tw_wi < 3'd4);
    logic [0:0] s1_t1_c0_tab_col_c, s1_t1_c0_tab_col; logic [0:0] s1_t1_c0_tab_wa_c, s1_t1_c0_tab_wa;
    assign s1_t1_c0_tab_col_c = '0; assign s1_t1_c0_tab_wa_c = s1_t1_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s1_t1_c0_tab_hit <= s1_t1_c0_tab_hit_c; s1_t1_c0_tab_col <= s1_t1_c0_tab_col_c; s1_t1_c0_tab_wa <= s1_t1_c0_tab_wa_c; end
    logic s1_t1_c0_tab_hit_q; logic [0:0] s1_t1_c0_tab_col_q; logic [0:0] s1_t1_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s1_t1_c0_tab_wd_q;
    always_ff @(posedge clk) begin s1_t1_c0_tab_hit_q <= s1_t1_c0_tab_hit; s1_t1_c0_tab_col_q <= s1_t1_c0_tab_col; s1_t1_c0_tab_wa_q <= s1_t1_c0_tab_wa; s1_t1_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p0_core_tab1 s1_t1_c0_tab (.clk(clk), .addr({mx_16}), .we(s1_t1_c0_tab_hit_q), .wa(s1_t1_c0_tab_wa_q), .wcol(s1_t1_c0_tab_col_q), .wd(s1_t1_c0_tab_wd_q), .q0(s1_t1_c0_w));
    (* max_fanout = 16 *) logic [16:0] s1q_QH;
    always_ff @(posedge clk) s1q_QH <= QH_r;
    logic [59:0] s1_k0_xr; logic [59:0] s1_k0_yr;
    MS_N16_q60_P32_tpm_p0_core_s1_bu s1_k0 (.clk(clk), .aIn(s0_o0), .bIn(s0_o2), .W(s1_t1_c0_w), .QH(s1q_QH), .aOut(s1_k0_xr), .bOut(s1_k0_yr));
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
    always_ff @(posedge clk) s1_o0_h <= mx_32[0] ? (60'(s1_o0_h_x >> 1) + (s1_o0_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o0_h_x;
    assign s1_o0 = s1_o0_h;
    logic [59:0] s1_o2;
    logic [59:0] s1_o2_h_x, s1_o2_h;
    assign s1_o2_h_x = s1_k0_yr;
    always_ff @(posedge clk) s1_o2_h <= mx_32[0] ? (60'(s1_o2_h_x >> 1) + (s1_o2_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o2_h_x;
    assign s1_o2 = s1_o2_h;
    logic [59:0] s1_t2_c0_w;
    logic s1_t2_c0_tab_hit_c, s1_t2_c0_tab_hit; logic [2:0] s1_t2_c0_tab_rel;
    assign s1_t2_c0_tab_rel = tw_wi - 3'd4;
    assign s1_t2_c0_tab_hit_c = tw_wen_p && (tw_wi >= 3'd4) && (tw_wi < 3'd6);
    logic [0:0] s1_t2_c0_tab_col_c, s1_t2_c0_tab_col; logic [0:0] s1_t2_c0_tab_wa_c, s1_t2_c0_tab_wa;
    assign s1_t2_c0_tab_col_c = '0; assign s1_t2_c0_tab_wa_c = s1_t2_c0_tab_rel[0:0];
    always_ff @(posedge clk) begin s1_t2_c0_tab_hit <= s1_t2_c0_tab_hit_c; s1_t2_c0_tab_col <= s1_t2_c0_tab_col_c; s1_t2_c0_tab_wa <= s1_t2_c0_tab_wa_c; end
    logic s1_t2_c0_tab_hit_q; logic [0:0] s1_t2_c0_tab_col_q; logic [0:0] s1_t2_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [59:0] s1_t2_c0_tab_wd_q;
    always_ff @(posedge clk) begin s1_t2_c0_tab_hit_q <= s1_t2_c0_tab_hit; s1_t2_c0_tab_col_q <= s1_t2_c0_tab_col; s1_t2_c0_tab_wa_q <= s1_t2_c0_tab_wa; s1_t2_c0_tab_wd_q <= tw_wd_q[59:0]; end
    MS_N16_q60_P32_tpm_p0_core_tab2 s1_t2_c0_tab (.clk(clk), .addr({mx_16}), .we(s1_t2_c0_tab_hit_q), .wa(s1_t2_c0_tab_wa_q), .wcol(s1_t2_c0_tab_col_q), .wd(s1_t2_c0_tab_wd_q), .q0(s1_t2_c0_w));
    logic [59:0] s1_k1_xr; logic [59:0] s1_k1_yr;
    MS_N16_q60_P32_tpm_p0_core_s1_bu s1_k1 (.clk(clk), .aIn(s0_o1), .bIn(s0_o3), .W(s1_t2_c0_w), .QH(s1q_QH), .aOut(s1_k1_xr), .bOut(s1_k1_yr));
    logic [59:0] s1_o1;
    logic [59:0] s1_o1_h_x, s1_o1_h;
    assign s1_o1_h_x = s1_k1_xr;
    always_ff @(posedge clk) s1_o1_h <= mx_32[0] ? (60'(s1_o1_h_x >> 1) + (s1_o1_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o1_h_x;
    assign s1_o1 = s1_o1_h;
    logic [59:0] s1_o3;
    logic [59:0] s1_o3_h_x, s1_o3_h;
    assign s1_o3_h_x = s1_k1_yr;
    always_ff @(posedge clk) s1_o3_h <= mx_32[0] ? (60'(s1_o3_h_x >> 1) + (s1_o3_h_x[0] ? 60'(s1q_QHALF) : 60'd0)) : s1_o3_h_x;
    assign s1_o3 = s1_o3_h;
    assign y_out_0 = s1_o0;
    assign y_out_1 = s1_o1;
    assign y_out_2 = s1_o2;
    assign y_out_3 = s1_o3;
endmodule
