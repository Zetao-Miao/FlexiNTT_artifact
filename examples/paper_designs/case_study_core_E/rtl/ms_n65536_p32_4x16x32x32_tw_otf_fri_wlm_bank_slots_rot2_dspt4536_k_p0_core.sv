`timescale 1ns / 1ps
// ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core: streaming NTT, n=4, 4 lanes, frame 1 cycles, run-time q, direction both, latency 33
module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core (
    input  logic clk,
    input  logic rst,
    input  logic DIR,
    input  logic [2:0] MIDX,
    input  logic [44:0] mq_QH,
    input  logic [61:0] mq_QHALF,
    input  logic tw_rst,
    input  logic tw_wen,
    input  logic [61:0] tw_wdata,
    input  logic [2:0] tw_slot,
    input  logic tw_dir,
    input  logic [61:0] x_in_0,
    input  logic [61:0] x_in_1,
    input  logic [61:0] x_in_2,
    input  logic [61:0] x_in_3,
    output logic [61:0] y_out_0,
    output logic [61:0] y_out_1,
    output logic [61:0] y_out_2,
    output logic [61:0] y_out_3
    );
    (* max_fanout = 32 *) logic tw_rst_p, tw_wen_p; (* max_fanout = 32 *) logic [61:0] tw_wdata_p;
    always_ff @(posedge clk) begin tw_rst_p <= tw_rst; tw_wen_p <= tw_wen; tw_wdata_p <= tw_wdata; end
    (* max_fanout = 32 *) logic [0:0] tw_wi;
    always_ff @(posedge clk) tw_wi <= tw_rst_p ? '0 : (tw_wen_p ? tw_wi + 1'b1 : tw_wi);
    (* max_fanout = 32 *) logic [61:0] tw_wd_q;
    always_ff @(posedge clk) tw_wd_q <= tw_wdata_p;
    logic [2:0] tw_slot_p; always_ff @(posedge clk) tw_slot_p <= tw_slot;
    (* max_fanout = 32 *) logic [2:0] tw_sl;
    always_ff @(posedge clk) if (tw_rst_p) tw_sl <= tw_slot_p;
    logic tw_dir_p; always_ff @(posedge clk) tw_dir_p <= tw_dir;
    (* max_fanout = 32 *) logic tw_dr;
    always_ff @(posedge clk) if (tw_rst_p) tw_dr <= tw_dir_p;
    logic [106:0] cq_1;
    always_ff @(posedge clk) cq_1 <= {mq_QHALF, mq_QH};
    logic [3:0] mx_1;
    always_ff @(posedge clk) if (1'b1) mx_1 <= {MIDX, DIR};
    // per-frame moduli: input lead of 2 cycles
    logic [61:0] xl_0;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core_dly #(.W(62), .D(2)) xl0_dly (.clk(clk), .din(x_in_0), .dout(xl_0));
    logic [61:0] xl_1;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core_dly #(.W(62), .D(2)) xl1_dly (.clk(clk), .din(x_in_1), .dout(xl_1));
    logic [61:0] xl_2;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core_dly #(.W(62), .D(2)) xl2_dly (.clk(clk), .din(x_in_2), .dout(xl_2));
    logic [61:0] xl_3;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core_dly #(.W(62), .D(2)) xl3_dly (.clk(clk), .din(x_in_3), .dout(xl_3));
    // stage 0: 2 butterflies on lane pairs (bit 0), latency 3
    (* max_fanout = 16 *) logic [44:0] s0_QH;
    always_ff @(posedge clk) s0_QH <= cq_1[44:0];
    (* max_fanout = 16 *) logic [61:0] s0_QHALF;
    always_ff @(posedge clk) s0_QHALF <= cq_1[106:45];
    logic [61:0] s0_k0_xr; logic [61:0] s0_k0_yr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core_s0_c0 s0_k0 (.clk(clk), .aIn(xl_0), .bIn(xl_1), .QH(s0_QH), .aOut(s0_k0_xr), .bOut(s0_k0_yr));
    logic [61:0] s0_o0;
    logic [106:0] cq_4;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core_dly_c #(.W(107), .D(3)) cq_4_i (.clk(clk), .din(cq_1), .dout(cq_4));
    (* max_fanout = 16 *) logic [44:0] s0h3_QH;
    always_ff @(posedge clk) s0h3_QH <= cq_4[44:0];
    (* max_fanout = 16 *) logic [61:0] s0h3_QHALF;
    always_ff @(posedge clk) s0h3_QHALF <= cq_4[106:45];
    logic [61:0] s0_o0_h_x, s0_o0_h;
    assign s0_o0_h_x = s0_k0_xr;
    (* max_fanout = 16 *) logic [3:0] mx_2;
    always_ff @(posedge clk) mx_2 <= mx_1;
    (* max_fanout = 16 *) logic [3:0] mx_3;
    always_ff @(posedge clk) mx_3 <= mx_2;
    (* max_fanout = 16 *) logic [3:0] mx_4;
    always_ff @(posedge clk) mx_4 <= mx_3;
    (* max_fanout = 16 *) logic [3:0] mx_5;
    always_ff @(posedge clk) mx_5 <= mx_4;
    always_ff @(posedge clk) s0_o0_h <= mx_5[0] ? (62'(s0_o0_h_x >> 1) + (s0_o0_h_x[0] ? 62'(s0h3_QHALF) : 62'd0)) : s0_o0_h_x;
    assign s0_o0 = s0_o0_h;
    logic [61:0] s0_o1;
    logic [61:0] s0_o1_h_x, s0_o1_h;
    assign s0_o1_h_x = s0_k0_yr;
    always_ff @(posedge clk) s0_o1_h <= mx_5[0] ? (62'(s0_o1_h_x >> 1) + (s0_o1_h_x[0] ? 62'(s0h3_QHALF) : 62'd0)) : s0_o1_h_x;
    assign s0_o1 = s0_o1_h;
    logic [61:0] s0_k1_xr; logic [61:0] s0_k1_yr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core_s0_c0 s0_k1 (.clk(clk), .aIn(xl_2), .bIn(xl_3), .QH(s0_QH), .aOut(s0_k1_xr), .bOut(s0_k1_yr));
    logic [61:0] s0_o2;
    logic [61:0] s0_o2_h_x, s0_o2_h;
    assign s0_o2_h_x = s0_k1_xr;
    always_ff @(posedge clk) s0_o2_h <= mx_5[0] ? (62'(s0_o2_h_x >> 1) + (s0_o2_h_x[0] ? 62'(s0h3_QHALF) : 62'd0)) : s0_o2_h_x;
    assign s0_o2 = s0_o2_h;
    logic [61:0] s0_o3;
    logic [61:0] s0_o3_h_x, s0_o3_h;
    assign s0_o3_h_x = s0_k1_yr;
    always_ff @(posedge clk) s0_o3_h <= mx_5[0] ? (62'(s0_o3_h_x >> 1) + (s0_o3_h_x[0] ? 62'(s0h3_QHALF) : 62'd0)) : s0_o3_h_x;
    assign s0_o3 = s0_o3_h;
    // stage 1: 2 butterflies on lane pairs (bit 1), latency 26
    logic [106:0] cq_5;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core_dly_c #(.W(107), .D(1)) cq_5_i (.clk(clk), .din(cq_4), .dout(cq_5));
    (* max_fanout = 16 *) logic [44:0] s1_QH;
    always_ff @(posedge clk) s1_QH <= cq_5[44:0];
    (* max_fanout = 16 *) logic [61:0] s1_QHALF;
    always_ff @(posedge clk) s1_QHALF <= cq_5[106:45];
    logic [61:0] s1_k0_xr; logic [61:0] s1_k0_yr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core_s1_c0 s1_k0 (.clk(clk), .aIn(s0_o0), .bIn(s0_o2), .QH(s1_QH), .aOut(s1_k0_xr), .bOut(s1_k0_yr));
    logic [61:0] s1_o0;
    logic [106:0] cq_8;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core_dly_c #(.W(107), .D(3)) cq_8_i (.clk(clk), .din(cq_5), .dout(cq_8));
    (* max_fanout = 16 *) logic [44:0] s1h3_QH;
    always_ff @(posedge clk) s1h3_QH <= cq_8[44:0];
    (* max_fanout = 16 *) logic [61:0] s1h3_QHALF;
    always_ff @(posedge clk) s1h3_QHALF <= cq_8[106:45];
    logic [61:0] s1_o0_h_x, s1_o0_h;
    assign s1_o0_h_x = s1_k0_xr;
    (* max_fanout = 16 *) logic [3:0] mx_6;
    always_ff @(posedge clk) mx_6 <= mx_5;
    (* max_fanout = 16 *) logic [3:0] mx_7;
    always_ff @(posedge clk) mx_7 <= mx_6;
    (* max_fanout = 16 *) logic [3:0] mx_8;
    always_ff @(posedge clk) mx_8 <= mx_7;
    (* max_fanout = 16 *) logic [3:0] mx_9;
    always_ff @(posedge clk) mx_9 <= mx_8;
    always_ff @(posedge clk) s1_o0_h <= mx_9[0] ? (62'(s1_o0_h_x >> 1) + (s1_o0_h_x[0] ? 62'(s1h3_QHALF) : 62'd0)) : s1_o0_h_x;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core_dly #(.W(62), .D(23)) s1_o0_bal (.clk(clk), .din(s1_o0_h), .dout(s1_o0));
    logic [61:0] s1_o2;
    logic [61:0] s1_o2_h_x, s1_o2_h;
    assign s1_o2_h_x = s1_k0_yr;
    always_ff @(posedge clk) s1_o2_h <= mx_9[0] ? (62'(s1_o2_h_x >> 1) + (s1_o2_h_x[0] ? 62'(s1h3_QHALF) : 62'd0)) : s1_o2_h_x;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core_dly #(.W(62), .D(23)) s1_o2_bal (.clk(clk), .din(s1_o2_h), .dout(s1_o2));
    logic [61:0] s1_t0_c0_w;
    logic s1_t0_c0_tab_hit_c, s1_t0_c0_tab_hit; logic [0:0] s1_t0_c0_tab_rel;
    assign s1_t0_c0_tab_rel = tw_wi - 1'd0;
    assign s1_t0_c0_tab_hit_c = tw_wen_p && (tw_wi >= 1'd0) && (tw_wi < 1'd1);
    logic [0:0] s1_t0_c0_tab_col_c, s1_t0_c0_tab_col; logic [3:0] s1_t0_c0_tab_wa_c, s1_t0_c0_tab_wa;
    assign s1_t0_c0_tab_col_c = '0;
    assign s1_t0_c0_tab_wa_c = {tw_sl[2:0], tw_dr};
    always_ff @(posedge clk) begin s1_t0_c0_tab_hit <= s1_t0_c0_tab_hit_c; s1_t0_c0_tab_col <= s1_t0_c0_tab_col_c; s1_t0_c0_tab_wa <= s1_t0_c0_tab_wa_c; end
    logic s1_t0_c0_tab_hit_q; logic [0:0] s1_t0_c0_tab_col_q; logic [3:0] s1_t0_c0_tab_wa_q;
    (* equivalent_register_removal = "no" *) logic [61:0] s1_t0_c0_tab_wd_q;
    always_ff @(posedge clk) begin s1_t0_c0_tab_hit_q <= s1_t0_c0_tab_hit; s1_t0_c0_tab_col_q <= s1_t0_c0_tab_col; s1_t0_c0_tab_wa_q <= s1_t0_c0_tab_wa; s1_t0_c0_tab_wd_q <= tw_wd_q[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core_tab0 s1_t0_c0_tab (.clk(clk), .addr({mx_4[3:0]}), .we(s1_t0_c0_tab_hit_q), .wa(s1_t0_c0_tab_wa_q), .wcol(s1_t0_c0_tab_col_q), .wd(s1_t0_c0_tab_wd_q), .q0(s1_t0_c0_w));
    logic [61:0] s1_k1_xr; logic [61:0] s1_k1_yr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core_s1_bu s1_k1 (.clk(clk), .aIn(s0_o1), .bIn(s0_o3), .W(s1_t0_c0_w), .QH(s1_QH), .aOut(s1_k1_xr), .bOut(s1_k1_yr));
    logic [61:0] s1_o1;
    logic [106:0] cq_31;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core_dly_c #(.W(107), .D(23)) cq_31_i (.clk(clk), .din(cq_8), .dout(cq_31));
    (* max_fanout = 16 *) logic [44:0] s1h26_QH;
    always_ff @(posedge clk) s1h26_QH <= cq_31[44:0];
    (* max_fanout = 16 *) logic [61:0] s1h26_QHALF;
    always_ff @(posedge clk) s1h26_QHALF <= cq_31[106:45];
    logic [61:0] s1_o1_h_x, s1_o1_h;
    assign s1_o1_h_x = s1_k1_xr;
    (* max_fanout = 16 *) logic [3:0] mx_10;
    always_ff @(posedge clk) mx_10 <= mx_9;
    (* max_fanout = 16 *) logic [3:0] mx_11;
    always_ff @(posedge clk) mx_11 <= mx_10;
    (* max_fanout = 16 *) logic [3:0] mx_12;
    always_ff @(posedge clk) mx_12 <= mx_11;
    (* max_fanout = 16 *) logic [3:0] mx_13;
    always_ff @(posedge clk) mx_13 <= mx_12;
    (* max_fanout = 16 *) logic [3:0] mx_14;
    always_ff @(posedge clk) mx_14 <= mx_13;
    (* max_fanout = 16 *) logic [3:0] mx_15;
    always_ff @(posedge clk) mx_15 <= mx_14;
    (* max_fanout = 16 *) logic [3:0] mx_16;
    always_ff @(posedge clk) mx_16 <= mx_15;
    (* max_fanout = 16 *) logic [3:0] mx_17;
    always_ff @(posedge clk) mx_17 <= mx_16;
    (* max_fanout = 16 *) logic [3:0] mx_18;
    always_ff @(posedge clk) mx_18 <= mx_17;
    (* max_fanout = 16 *) logic [3:0] mx_19;
    always_ff @(posedge clk) mx_19 <= mx_18;
    (* max_fanout = 16 *) logic [3:0] mx_20;
    always_ff @(posedge clk) mx_20 <= mx_19;
    (* max_fanout = 16 *) logic [3:0] mx_21;
    always_ff @(posedge clk) mx_21 <= mx_20;
    (* max_fanout = 16 *) logic [3:0] mx_22;
    always_ff @(posedge clk) mx_22 <= mx_21;
    (* max_fanout = 16 *) logic [3:0] mx_23;
    always_ff @(posedge clk) mx_23 <= mx_22;
    (* max_fanout = 16 *) logic [3:0] mx_24;
    always_ff @(posedge clk) mx_24 <= mx_23;
    (* max_fanout = 16 *) logic [3:0] mx_25;
    always_ff @(posedge clk) mx_25 <= mx_24;
    (* max_fanout = 16 *) logic [3:0] mx_26;
    always_ff @(posedge clk) mx_26 <= mx_25;
    (* max_fanout = 16 *) logic [3:0] mx_27;
    always_ff @(posedge clk) mx_27 <= mx_26;
    (* max_fanout = 16 *) logic [3:0] mx_28;
    always_ff @(posedge clk) mx_28 <= mx_27;
    (* max_fanout = 16 *) logic [3:0] mx_29;
    always_ff @(posedge clk) mx_29 <= mx_28;
    (* max_fanout = 16 *) logic [3:0] mx_30;
    always_ff @(posedge clk) mx_30 <= mx_29;
    (* max_fanout = 16 *) logic [3:0] mx_31;
    always_ff @(posedge clk) mx_31 <= mx_30;
    (* max_fanout = 16 *) logic [3:0] mx_32;
    always_ff @(posedge clk) mx_32 <= mx_31;
    always_ff @(posedge clk) s1_o1_h <= mx_32[0] ? (62'(s1_o1_h_x >> 1) + (s1_o1_h_x[0] ? 62'(s1h26_QHALF) : 62'd0)) : s1_o1_h_x;
    assign s1_o1 = s1_o1_h;
    logic [61:0] s1_o3;
    logic [61:0] s1_o3_h_x, s1_o3_h;
    assign s1_o3_h_x = s1_k1_yr;
    always_ff @(posedge clk) s1_o3_h <= mx_32[0] ? (62'(s1_o3_h_x >> 1) + (s1_o3_h_x[0] ? 62'(s1h26_QHALF) : 62'd0)) : s1_o3_h_x;
    assign s1_o3 = s1_o3_h;
    assign y_out_0 = s1_o0;
    assign y_out_1 = s1_o1;
    assign y_out_2 = s1_o2;
    assign y_out_3 = s1_o3;
endmodule
