`timescale 1ns / 1ps
// ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k: multi-step NTT, N=65536, sizes [4, 16, 32, 32], 32 lanes, frame 2048 cycles, latency 3703, 5 moduli (MIDX per polynomial)
module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k (
    input  logic clk,
    input  logic rst,
    input  logic in_valid,
    input  logic [2:0] MIDX,
    input  logic DIR,
    input  logic [44:0] mq_QH,
    input  logic [61:0] mq_QHALF,
    input  logic ld_rst,
    input  logic ld_wen,
    input  logic [123:0] ld_wdata,
    input  logic [2:0] ld_slot,
    input  logic ld_dir,
    input  logic [61:0] x_in_0,
    input  logic [61:0] x_in_1,
    input  logic [61:0] x_in_2,
    input  logic [61:0] x_in_3,
    input  logic [61:0] x_in_4,
    input  logic [61:0] x_in_5,
    input  logic [61:0] x_in_6,
    input  logic [61:0] x_in_7,
    input  logic [61:0] x_in_8,
    input  logic [61:0] x_in_9,
    input  logic [61:0] x_in_10,
    input  logic [61:0] x_in_11,
    input  logic [61:0] x_in_12,
    input  logic [61:0] x_in_13,
    input  logic [61:0] x_in_14,
    input  logic [61:0] x_in_15,
    input  logic [61:0] x_in_16,
    input  logic [61:0] x_in_17,
    input  logic [61:0] x_in_18,
    input  logic [61:0] x_in_19,
    input  logic [61:0] x_in_20,
    input  logic [61:0] x_in_21,
    input  logic [61:0] x_in_22,
    input  logic [61:0] x_in_23,
    input  logic [61:0] x_in_24,
    input  logic [61:0] x_in_25,
    input  logic [61:0] x_in_26,
    input  logic [61:0] x_in_27,
    input  logic [61:0] x_in_28,
    input  logic [61:0] x_in_29,
    input  logic [61:0] x_in_30,
    input  logic [61:0] x_in_31,
    output logic out_valid,
    output logic [2:0] midx_out,
    output logic dir_out,
    output logic [61:0] y_out_0,
    output logic [61:0] y_out_1,
    output logic [61:0] y_out_2,
    output logic [61:0] y_out_3,
    output logic [61:0] y_out_4,
    output logic [61:0] y_out_5,
    output logic [61:0] y_out_6,
    output logic [61:0] y_out_7,
    output logic [61:0] y_out_8,
    output logic [61:0] y_out_9,
    output logic [61:0] y_out_10,
    output logic [61:0] y_out_11,
    output logic [61:0] y_out_12,
    output logic [61:0] y_out_13,
    output logic [61:0] y_out_14,
    output logic [61:0] y_out_15,
    output logic [61:0] y_out_16,
    output logic [61:0] y_out_17,
    output logic [61:0] y_out_18,
    output logic [61:0] y_out_19,
    output logic [61:0] y_out_20,
    output logic [61:0] y_out_21,
    output logic [61:0] y_out_22,
    output logic [61:0] y_out_23,
    output logic [61:0] y_out_24,
    output logic [61:0] y_out_25,
    output logic [61:0] y_out_26,
    output logic [61:0] y_out_27,
    output logic [61:0] y_out_28,
    output logic [61:0] y_out_29,
    output logic [61:0] y_out_30,
    output logic [61:0] y_out_31
    );
    // load port: one word per ld_wen after ld_rst, 1807 words: the sub-NTT images, then the tables
    (* max_fanout = 32 *) logic ld_rst_p, ld_wen_p; (* max_fanout = 32 *) logic [123:0] ld_wdata_p;
    always_ff @(posedge clk) begin ld_rst_p <= ld_rst; ld_wen_p <= ld_wen; ld_wdata_p <= ld_wdata; end
    (* max_fanout = 32 *) logic [10:0] ld_i;
    always_ff @(posedge clk) ld_i <= ld_rst_p ? '0 : (ld_wen_p ? ld_i + 1'b1 : ld_i);
    (* max_fanout = 32 *) logic [123:0] ld_d; always_ff @(posedge clk) ld_d <= ld_wdata_p;
    (* max_fanout = 32 *) logic ld_v, ld_r; always_ff @(posedge clk) begin ld_v <= ld_wen_p; ld_r <= ld_rst_p; end
    logic [10:0] ld_iq; always_ff @(posedge clk) ld_iq <= ld_i;
    logic [2:0] ld_slot_p; always_ff @(posedge clk) ld_slot_p <= ld_slot;
    (* max_fanout = 32 *) logic [2:0] ld_sl; always_ff @(posedge clk) if (ld_rst_p) ld_sl <= ld_slot_p;
    (* max_fanout = 32 *) logic [2:0] ld_slq; always_ff @(posedge clk) ld_slq <= ld_sl;
    logic ld_dir_p; always_ff @(posedge clk) ld_dir_p <= ld_dir;
    (* max_fanout = 32 *) logic ld_dr; always_ff @(posedge clk) if (ld_rst_p) ld_dr <= ld_dir_p;
    (* max_fanout = 32 *) logic ld_drq; always_ff @(posedge clk) ld_drq <= ld_dr;
    logic [61:0] d0_0; assign d0_0 = x_in_0;
    logic [61:0] d0_1; assign d0_1 = x_in_1;
    logic [61:0] d0_2; assign d0_2 = x_in_2;
    logic [61:0] d0_3; assign d0_3 = x_in_3;
    logic [61:0] d0_4; assign d0_4 = x_in_4;
    logic [61:0] d0_5; assign d0_5 = x_in_5;
    logic [61:0] d0_6; assign d0_6 = x_in_6;
    logic [61:0] d0_7; assign d0_7 = x_in_7;
    logic [61:0] d0_8; assign d0_8 = x_in_8;
    logic [61:0] d0_9; assign d0_9 = x_in_9;
    logic [61:0] d0_10; assign d0_10 = x_in_10;
    logic [61:0] d0_11; assign d0_11 = x_in_11;
    logic [61:0] d0_12; assign d0_12 = x_in_12;
    logic [61:0] d0_13; assign d0_13 = x_in_13;
    logic [61:0] d0_14; assign d0_14 = x_in_14;
    logic [61:0] d0_15; assign d0_15 = x_in_15;
    logic [61:0] d0_16; assign d0_16 = x_in_16;
    logic [61:0] d0_17; assign d0_17 = x_in_17;
    logic [61:0] d0_18; assign d0_18 = x_in_18;
    logic [61:0] d0_19; assign d0_19 = x_in_19;
    logic [61:0] d0_20; assign d0_20 = x_in_20;
    logic [61:0] d0_21; assign d0_21 = x_in_21;
    logic [61:0] d0_22; assign d0_22 = x_in_22;
    logic [61:0] d0_23; assign d0_23 = x_in_23;
    logic [61:0] d0_24; assign d0_24 = x_in_24;
    logic [61:0] d0_25; assign d0_25 = x_in_25;
    logic [61:0] d0_26; assign d0_26 = x_in_26;
    logic [61:0] d0_27; assign d0_27 = x_in_27;
    logic [61:0] d0_28; assign d0_28 = x_in_28;
    logic [61:0] d0_29; assign d0_29 = x_in_29;
    logic [61:0] d0_30; assign d0_30 = x_in_30;
    logic [61:0] d0_31; assign d0_31 = x_in_31;
    logic v0; assign v0 = in_valid;
    logic [110:0] g0; assign g0 = {mq_QHALF, mq_QH, MIDX, DIR};
    // block 0: twiddle stage 0, latency 30 (tables 3, multiplier 27)
    logic [10:0] b0_cnt;
    always_ff @(posedge clk) b0_cnt <= rst ? '0 : (v0 ? b0_cnt + 1'b1 : b0_cnt);
    logic [61:0] b0_t0;
    (* shreg_extract = "no" *) logic [61:0] b0_t0_q0;
    logic b0_t0_lwe; logic [3:0] b0_t0_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b0_t0_lwd;
    always_ff @(posedge clk) begin b0_t0_lwe <= ld_v && ld_iq >= 11'd0 && ld_iq < 11'd1; b0_t0_lwa <= {ld_slq[2:0], ld_drq}; b0_t0_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw0_tab0 b0_t0_i (.clk(clk), .addr({g0[3:1], g0[0]}), .we(b0_t0_lwe), .wa(b0_t0_lwa), .wcol(1'b0), .wd(b0_t0_lwd), .q0(b0_t0_q0));
    always_ff @(posedge clk) begin b0_t0 <= b0_t0_q0; end
    logic [61:0] b0_t1;
    (* shreg_extract = "no" *) logic [61:0] b0_t1_q0;
    logic b0_t1_lwe; logic [3:0] b0_t1_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b0_t1_lwd;
    always_ff @(posedge clk) begin b0_t1_lwe <= ld_v && ld_iq >= 11'd0 && ld_iq < 11'd1; b0_t1_lwa <= {ld_slq[2:0], ld_drq}; b0_t1_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw0_tab1 b0_t1_i (.clk(clk), .addr({g0[3:1], g0[0]}), .we(b0_t1_lwe), .wa(b0_t1_lwa), .wcol(1'b0), .wd(b0_t1_lwd), .q0(b0_t1_q0));
    always_ff @(posedge clk) begin b0_t1 <= b0_t1_q0; end
    logic [61:0] b0_t2;
    (* shreg_extract = "no" *) logic [61:0] b0_t2_q0;
    logic b0_t2_lwe; logic [3:0] b0_t2_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b0_t2_lwd;
    always_ff @(posedge clk) begin b0_t2_lwe <= ld_v && ld_iq >= 11'd1 && ld_iq < 11'd2; b0_t2_lwa <= {ld_slq[2:0], ld_drq}; b0_t2_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw0_tab2 b0_t2_i (.clk(clk), .addr({g0[3:1], g0[0]}), .we(b0_t2_lwe), .wa(b0_t2_lwa), .wcol(1'b0), .wd(b0_t2_lwd), .q0(b0_t2_q0));
    always_ff @(posedge clk) begin b0_t2 <= b0_t2_q0; end
    logic [61:0] b0_l0_byp;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b0_l0_byp_i (.clk(clk), .din(d0_0), .dout(b0_l0_byp));
    logic [61:0] b0_l1_byp;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b0_l1_byp_i (.clk(clk), .din(d0_1), .dout(b0_l1_byp));
    logic [61:0] b0_l2_byp;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b0_l2_byp_i (.clk(clk), .din(d0_2), .dout(b0_l2_byp));
    logic [61:0] b0_l3_byp;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b0_l3_byp_i (.clk(clk), .din(d0_3), .dout(b0_l3_byp));
    logic [61:0] b0_l4_byp;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b0_l4_byp_i (.clk(clk), .din(d0_4), .dout(b0_l4_byp));
    logic [61:0] b0_l5_byp;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b0_l5_byp_i (.clk(clk), .din(d0_5), .dout(b0_l5_byp));
    logic [61:0] b0_l6_byp;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b0_l6_byp_i (.clk(clk), .din(d0_6), .dout(b0_l6_byp));
    logic [61:0] b0_l7_byp;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b0_l7_byp_i (.clk(clk), .din(d0_7), .dout(b0_l7_byp));
    logic [61:0] b0_l8_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l8_a_i (.clk(clk), .din(d0_8), .dout(b0_l8_a));
    logic [44:0] b0_mq3_0_QH_c; assign b0_mq3_0_QH_c = g0[48:4];
    logic [44:0] b0_mq3_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(45), .D(2)) b0_mq3_0_QH_i (.clk(clk), .din(b0_mq3_0_QH_c), .dout(b0_mq3_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b0_mq3_s2_QH;
    always_ff @(posedge clk) b0_mq3_s2_QH <= b0_mq3_0_QH;
    logic [61:0] b0_l8_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l8_mul (.clk(clk), .A(b0_l8_a), .B(b0_t0), .QH(b0_mq3_s2_QH), .P(b0_l8_p));
    logic [61:0] b0_l9_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l9_a_i (.clk(clk), .din(d0_9), .dout(b0_l9_a));
    logic [61:0] b0_l9_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l9_mul (.clk(clk), .A(b0_l9_a), .B(b0_t0), .QH(b0_mq3_s2_QH), .P(b0_l9_p));
    logic [61:0] b0_l10_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l10_a_i (.clk(clk), .din(d0_10), .dout(b0_l10_a));
    logic [61:0] b0_l10_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l10_mul (.clk(clk), .A(b0_l10_a), .B(b0_t0), .QH(b0_mq3_s2_QH), .P(b0_l10_p));
    logic [61:0] b0_l11_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l11_a_i (.clk(clk), .din(d0_11), .dout(b0_l11_a));
    logic [61:0] b0_l11_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l11_mul (.clk(clk), .A(b0_l11_a), .B(b0_t0), .QH(b0_mq3_s2_QH), .P(b0_l11_p));
    logic [61:0] b0_l12_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l12_a_i (.clk(clk), .din(d0_12), .dout(b0_l12_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b0_mq3_s3_QH;
    always_ff @(posedge clk) b0_mq3_s3_QH <= b0_mq3_0_QH;
    logic [61:0] b0_l12_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l12_mul (.clk(clk), .A(b0_l12_a), .B(b0_t0), .QH(b0_mq3_s3_QH), .P(b0_l12_p));
    logic [61:0] b0_l13_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l13_a_i (.clk(clk), .din(d0_13), .dout(b0_l13_a));
    logic [61:0] b0_l13_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l13_mul (.clk(clk), .A(b0_l13_a), .B(b0_t0), .QH(b0_mq3_s3_QH), .P(b0_l13_p));
    logic [61:0] b0_l14_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l14_a_i (.clk(clk), .din(d0_14), .dout(b0_l14_a));
    logic [61:0] b0_l14_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l14_mul (.clk(clk), .A(b0_l14_a), .B(b0_t0), .QH(b0_mq3_s3_QH), .P(b0_l14_p));
    logic [61:0] b0_l15_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l15_a_i (.clk(clk), .din(d0_15), .dout(b0_l15_a));
    logic [61:0] b0_l15_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l15_mul (.clk(clk), .A(b0_l15_a), .B(b0_t0), .QH(b0_mq3_s3_QH), .P(b0_l15_p));
    logic [61:0] b0_l16_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l16_a_i (.clk(clk), .din(d0_16), .dout(b0_l16_a));
    logic [44:0] b0_mq3_1_QH_c; assign b0_mq3_1_QH_c = g0[48:4];
    logic [44:0] b0_mq3_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(45), .D(2)) b0_mq3_1_QH_i (.clk(clk), .din(b0_mq3_1_QH_c), .dout(b0_mq3_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b0_mq3_s4_QH;
    always_ff @(posedge clk) b0_mq3_s4_QH <= b0_mq3_1_QH;
    logic [61:0] b0_l16_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l16_mul (.clk(clk), .A(b0_l16_a), .B(b0_t1), .QH(b0_mq3_s4_QH), .P(b0_l16_p));
    logic [61:0] b0_l17_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l17_a_i (.clk(clk), .din(d0_17), .dout(b0_l17_a));
    logic [61:0] b0_l17_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l17_mul (.clk(clk), .A(b0_l17_a), .B(b0_t1), .QH(b0_mq3_s4_QH), .P(b0_l17_p));
    logic [61:0] b0_l18_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l18_a_i (.clk(clk), .din(d0_18), .dout(b0_l18_a));
    logic [61:0] b0_l18_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l18_mul (.clk(clk), .A(b0_l18_a), .B(b0_t1), .QH(b0_mq3_s4_QH), .P(b0_l18_p));
    logic [61:0] b0_l19_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l19_a_i (.clk(clk), .din(d0_19), .dout(b0_l19_a));
    logic [61:0] b0_l19_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l19_mul (.clk(clk), .A(b0_l19_a), .B(b0_t1), .QH(b0_mq3_s4_QH), .P(b0_l19_p));
    logic [61:0] b0_l20_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l20_a_i (.clk(clk), .din(d0_20), .dout(b0_l20_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b0_mq3_s5_QH;
    always_ff @(posedge clk) b0_mq3_s5_QH <= b0_mq3_1_QH;
    logic [61:0] b0_l20_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l20_mul (.clk(clk), .A(b0_l20_a), .B(b0_t1), .QH(b0_mq3_s5_QH), .P(b0_l20_p));
    logic [61:0] b0_l21_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l21_a_i (.clk(clk), .din(d0_21), .dout(b0_l21_a));
    logic [61:0] b0_l21_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l21_mul (.clk(clk), .A(b0_l21_a), .B(b0_t1), .QH(b0_mq3_s5_QH), .P(b0_l21_p));
    logic [61:0] b0_l22_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l22_a_i (.clk(clk), .din(d0_22), .dout(b0_l22_a));
    logic [61:0] b0_l22_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l22_mul (.clk(clk), .A(b0_l22_a), .B(b0_t1), .QH(b0_mq3_s5_QH), .P(b0_l22_p));
    logic [61:0] b0_l23_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l23_a_i (.clk(clk), .din(d0_23), .dout(b0_l23_a));
    logic [61:0] b0_l23_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l23_mul (.clk(clk), .A(b0_l23_a), .B(b0_t1), .QH(b0_mq3_s5_QH), .P(b0_l23_p));
    logic [61:0] b0_l24_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l24_a_i (.clk(clk), .din(d0_24), .dout(b0_l24_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b0_mq3_s6_QH;
    always_ff @(posedge clk) b0_mq3_s6_QH <= b0_mq3_1_QH;
    logic [61:0] b0_l24_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l24_mul (.clk(clk), .A(b0_l24_a), .B(b0_t2), .QH(b0_mq3_s6_QH), .P(b0_l24_p));
    logic [61:0] b0_l25_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l25_a_i (.clk(clk), .din(d0_25), .dout(b0_l25_a));
    logic [61:0] b0_l25_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l25_mul (.clk(clk), .A(b0_l25_a), .B(b0_t2), .QH(b0_mq3_s6_QH), .P(b0_l25_p));
    logic [61:0] b0_l26_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l26_a_i (.clk(clk), .din(d0_26), .dout(b0_l26_a));
    logic [61:0] b0_l26_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l26_mul (.clk(clk), .A(b0_l26_a), .B(b0_t2), .QH(b0_mq3_s6_QH), .P(b0_l26_p));
    logic [61:0] b0_l27_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l27_a_i (.clk(clk), .din(d0_27), .dout(b0_l27_a));
    logic [61:0] b0_l27_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l27_mul (.clk(clk), .A(b0_l27_a), .B(b0_t2), .QH(b0_mq3_s6_QH), .P(b0_l27_p));
    logic [61:0] b0_l28_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l28_a_i (.clk(clk), .din(d0_28), .dout(b0_l28_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b0_mq3_s7_QH;
    always_ff @(posedge clk) b0_mq3_s7_QH <= b0_mq3_1_QH;
    logic [61:0] b0_l28_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l28_mul (.clk(clk), .A(b0_l28_a), .B(b0_t2), .QH(b0_mq3_s7_QH), .P(b0_l28_p));
    logic [61:0] b0_l29_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l29_a_i (.clk(clk), .din(d0_29), .dout(b0_l29_a));
    logic [61:0] b0_l29_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l29_mul (.clk(clk), .A(b0_l29_a), .B(b0_t2), .QH(b0_mq3_s7_QH), .P(b0_l29_p));
    logic [61:0] b0_l30_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l30_a_i (.clk(clk), .din(d0_30), .dout(b0_l30_a));
    logic [61:0] b0_l30_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l30_mul (.clk(clk), .A(b0_l30_a), .B(b0_t2), .QH(b0_mq3_s7_QH), .P(b0_l30_p));
    logic [61:0] b0_l31_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b0_l31_a_i (.clk(clk), .din(d0_31), .dout(b0_l31_a));
    logic [61:0] b0_l31_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b0_l31_mul (.clk(clk), .A(b0_l31_a), .B(b0_t2), .QH(b0_mq3_s7_QH), .P(b0_l31_p));
    logic [29:0] b0_v_sr;
    always_ff @(posedge clk) b0_v_sr <= rst ? '0 : {b0_v_sr[28:0], v0};
    logic b0_v; assign b0_v = b0_v_sr[29];
    logic [110:0] b0_tag;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(111), .D(30)) b0_tag_i (.clk(clk), .din(g0), .dout(b0_tag));
    // block 1: pass 0, 8 x ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0 (4-point), latency 33
    logic [61:0] b1_c0_y0, b1_c0_y1, b1_c0_y2, b1_c0_y3;
    logic b1_c0_v; logic [2:0] b1_c0_mi; logic b1_c0_di;
    logic b1_c0_lr, b1_c0_lw; (* equivalent_register_removal = "no" *) logic [61:0] b1_c0_ld;
    always_ff @(posedge clk) begin b1_c0_lr <= ld_r; b1_c0_lw <= ld_v && ld_iq >= 11'd1 && ld_iq < 11'd2; b1_c0_ld <= ld_d[123:62]; end
    logic [2:0] b1_c0_ls; always_ff @(posedge clk) b1_c0_ls <= ld_sl;
    logic b1_c0_ldr; always_ff @(posedge clk) b1_c0_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0 b1_c0 (.clk(clk), .rst(rst), .in_valid(b0_v), .out_valid(b1_c0_v), .MIDX(b0_tag[3:1]), .midx_out(b1_c0_mi), .mq_QH(b0_tag[48:4]), .mq_QHALF(b0_tag[110:49]), .DIR(b0_tag[0]), .dir_out(b1_c0_di), .tw_rst(b1_c0_lr), .tw_wen(b1_c0_lw), .tw_wdata(b1_c0_ld), .tw_slot(b1_c0_ls), .tw_dir(b1_c0_ldr), .x_in_0(b0_l0_byp), .x_in_1(b0_l8_p), .x_in_2(b0_l16_p), .x_in_3(b0_l24_p), .y_out_0(b1_c0_y0), .y_out_1(b1_c0_y1), .y_out_2(b1_c0_y2), .y_out_3(b1_c0_y3));
    logic [61:0] b1_c1_y0, b1_c1_y1, b1_c1_y2, b1_c1_y3;
    logic b1_c1_v; logic [2:0] b1_c1_mi; logic b1_c1_di;
    logic b1_c1_lr, b1_c1_lw; (* equivalent_register_removal = "no" *) logic [61:0] b1_c1_ld;
    always_ff @(posedge clk) begin b1_c1_lr <= ld_r; b1_c1_lw <= ld_v && ld_iq >= 11'd1 && ld_iq < 11'd2; b1_c1_ld <= ld_d[123:62]; end
    logic [2:0] b1_c1_ls; always_ff @(posedge clk) b1_c1_ls <= ld_sl;
    logic b1_c1_ldr; always_ff @(posedge clk) b1_c1_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0 b1_c1 (.clk(clk), .rst(rst), .in_valid(b0_v), .out_valid(b1_c1_v), .MIDX(b0_tag[3:1]), .midx_out(b1_c1_mi), .mq_QH(b0_tag[48:4]), .mq_QHALF(b0_tag[110:49]), .DIR(b0_tag[0]), .dir_out(b1_c1_di), .tw_rst(b1_c1_lr), .tw_wen(b1_c1_lw), .tw_wdata(b1_c1_ld), .tw_slot(b1_c1_ls), .tw_dir(b1_c1_ldr), .x_in_0(b0_l1_byp), .x_in_1(b0_l9_p), .x_in_2(b0_l17_p), .x_in_3(b0_l25_p), .y_out_0(b1_c1_y0), .y_out_1(b1_c1_y1), .y_out_2(b1_c1_y2), .y_out_3(b1_c1_y3));
    logic [61:0] b1_c2_y0, b1_c2_y1, b1_c2_y2, b1_c2_y3;
    logic b1_c2_v; logic [2:0] b1_c2_mi; logic b1_c2_di;
    logic b1_c2_lr, b1_c2_lw; (* equivalent_register_removal = "no" *) logic [61:0] b1_c2_ld;
    always_ff @(posedge clk) begin b1_c2_lr <= ld_r; b1_c2_lw <= ld_v && ld_iq >= 11'd1 && ld_iq < 11'd2; b1_c2_ld <= ld_d[123:62]; end
    logic [2:0] b1_c2_ls; always_ff @(posedge clk) b1_c2_ls <= ld_sl;
    logic b1_c2_ldr; always_ff @(posedge clk) b1_c2_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0 b1_c2 (.clk(clk), .rst(rst), .in_valid(b0_v), .out_valid(b1_c2_v), .MIDX(b0_tag[3:1]), .midx_out(b1_c2_mi), .mq_QH(b0_tag[48:4]), .mq_QHALF(b0_tag[110:49]), .DIR(b0_tag[0]), .dir_out(b1_c2_di), .tw_rst(b1_c2_lr), .tw_wen(b1_c2_lw), .tw_wdata(b1_c2_ld), .tw_slot(b1_c2_ls), .tw_dir(b1_c2_ldr), .x_in_0(b0_l2_byp), .x_in_1(b0_l10_p), .x_in_2(b0_l18_p), .x_in_3(b0_l26_p), .y_out_0(b1_c2_y0), .y_out_1(b1_c2_y1), .y_out_2(b1_c2_y2), .y_out_3(b1_c2_y3));
    logic [61:0] b1_c3_y0, b1_c3_y1, b1_c3_y2, b1_c3_y3;
    logic b1_c3_v; logic [2:0] b1_c3_mi; logic b1_c3_di;
    logic b1_c3_lr, b1_c3_lw; (* equivalent_register_removal = "no" *) logic [61:0] b1_c3_ld;
    always_ff @(posedge clk) begin b1_c3_lr <= ld_r; b1_c3_lw <= ld_v && ld_iq >= 11'd1 && ld_iq < 11'd2; b1_c3_ld <= ld_d[123:62]; end
    logic [2:0] b1_c3_ls; always_ff @(posedge clk) b1_c3_ls <= ld_sl;
    logic b1_c3_ldr; always_ff @(posedge clk) b1_c3_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0 b1_c3 (.clk(clk), .rst(rst), .in_valid(b0_v), .out_valid(b1_c3_v), .MIDX(b0_tag[3:1]), .midx_out(b1_c3_mi), .mq_QH(b0_tag[48:4]), .mq_QHALF(b0_tag[110:49]), .DIR(b0_tag[0]), .dir_out(b1_c3_di), .tw_rst(b1_c3_lr), .tw_wen(b1_c3_lw), .tw_wdata(b1_c3_ld), .tw_slot(b1_c3_ls), .tw_dir(b1_c3_ldr), .x_in_0(b0_l3_byp), .x_in_1(b0_l11_p), .x_in_2(b0_l19_p), .x_in_3(b0_l27_p), .y_out_0(b1_c3_y0), .y_out_1(b1_c3_y1), .y_out_2(b1_c3_y2), .y_out_3(b1_c3_y3));
    logic [61:0] b1_c4_y0, b1_c4_y1, b1_c4_y2, b1_c4_y3;
    logic b1_c4_v; logic [2:0] b1_c4_mi; logic b1_c4_di;
    logic b1_c4_lr, b1_c4_lw; (* equivalent_register_removal = "no" *) logic [61:0] b1_c4_ld;
    always_ff @(posedge clk) begin b1_c4_lr <= ld_r; b1_c4_lw <= ld_v && ld_iq >= 11'd1 && ld_iq < 11'd2; b1_c4_ld <= ld_d[123:62]; end
    logic [2:0] b1_c4_ls; always_ff @(posedge clk) b1_c4_ls <= ld_sl;
    logic b1_c4_ldr; always_ff @(posedge clk) b1_c4_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0 b1_c4 (.clk(clk), .rst(rst), .in_valid(b0_v), .out_valid(b1_c4_v), .MIDX(b0_tag[3:1]), .midx_out(b1_c4_mi), .mq_QH(b0_tag[48:4]), .mq_QHALF(b0_tag[110:49]), .DIR(b0_tag[0]), .dir_out(b1_c4_di), .tw_rst(b1_c4_lr), .tw_wen(b1_c4_lw), .tw_wdata(b1_c4_ld), .tw_slot(b1_c4_ls), .tw_dir(b1_c4_ldr), .x_in_0(b0_l4_byp), .x_in_1(b0_l12_p), .x_in_2(b0_l20_p), .x_in_3(b0_l28_p), .y_out_0(b1_c4_y0), .y_out_1(b1_c4_y1), .y_out_2(b1_c4_y2), .y_out_3(b1_c4_y3));
    logic [61:0] b1_c5_y0, b1_c5_y1, b1_c5_y2, b1_c5_y3;
    logic b1_c5_v; logic [2:0] b1_c5_mi; logic b1_c5_di;
    logic b1_c5_lr, b1_c5_lw; (* equivalent_register_removal = "no" *) logic [61:0] b1_c5_ld;
    always_ff @(posedge clk) begin b1_c5_lr <= ld_r; b1_c5_lw <= ld_v && ld_iq >= 11'd1 && ld_iq < 11'd2; b1_c5_ld <= ld_d[123:62]; end
    logic [2:0] b1_c5_ls; always_ff @(posedge clk) b1_c5_ls <= ld_sl;
    logic b1_c5_ldr; always_ff @(posedge clk) b1_c5_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0 b1_c5 (.clk(clk), .rst(rst), .in_valid(b0_v), .out_valid(b1_c5_v), .MIDX(b0_tag[3:1]), .midx_out(b1_c5_mi), .mq_QH(b0_tag[48:4]), .mq_QHALF(b0_tag[110:49]), .DIR(b0_tag[0]), .dir_out(b1_c5_di), .tw_rst(b1_c5_lr), .tw_wen(b1_c5_lw), .tw_wdata(b1_c5_ld), .tw_slot(b1_c5_ls), .tw_dir(b1_c5_ldr), .x_in_0(b0_l5_byp), .x_in_1(b0_l13_p), .x_in_2(b0_l21_p), .x_in_3(b0_l29_p), .y_out_0(b1_c5_y0), .y_out_1(b1_c5_y1), .y_out_2(b1_c5_y2), .y_out_3(b1_c5_y3));
    logic [61:0] b1_c6_y0, b1_c6_y1, b1_c6_y2, b1_c6_y3;
    logic b1_c6_v; logic [2:0] b1_c6_mi; logic b1_c6_di;
    logic b1_c6_lr, b1_c6_lw; (* equivalent_register_removal = "no" *) logic [61:0] b1_c6_ld;
    always_ff @(posedge clk) begin b1_c6_lr <= ld_r; b1_c6_lw <= ld_v && ld_iq >= 11'd1 && ld_iq < 11'd2; b1_c6_ld <= ld_d[123:62]; end
    logic [2:0] b1_c6_ls; always_ff @(posedge clk) b1_c6_ls <= ld_sl;
    logic b1_c6_ldr; always_ff @(posedge clk) b1_c6_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0 b1_c6 (.clk(clk), .rst(rst), .in_valid(b0_v), .out_valid(b1_c6_v), .MIDX(b0_tag[3:1]), .midx_out(b1_c6_mi), .mq_QH(b0_tag[48:4]), .mq_QHALF(b0_tag[110:49]), .DIR(b0_tag[0]), .dir_out(b1_c6_di), .tw_rst(b1_c6_lr), .tw_wen(b1_c6_lw), .tw_wdata(b1_c6_ld), .tw_slot(b1_c6_ls), .tw_dir(b1_c6_ldr), .x_in_0(b0_l6_byp), .x_in_1(b0_l14_p), .x_in_2(b0_l22_p), .x_in_3(b0_l30_p), .y_out_0(b1_c6_y0), .y_out_1(b1_c6_y1), .y_out_2(b1_c6_y2), .y_out_3(b1_c6_y3));
    logic [61:0] b1_c7_y0, b1_c7_y1, b1_c7_y2, b1_c7_y3;
    logic b1_c7_v; logic [2:0] b1_c7_mi; logic b1_c7_di;
    logic b1_c7_lr, b1_c7_lw; (* equivalent_register_removal = "no" *) logic [61:0] b1_c7_ld;
    always_ff @(posedge clk) begin b1_c7_lr <= ld_r; b1_c7_lw <= ld_v && ld_iq >= 11'd1 && ld_iq < 11'd2; b1_c7_ld <= ld_d[123:62]; end
    logic [2:0] b1_c7_ls; always_ff @(posedge clk) b1_c7_ls <= ld_sl;
    logic b1_c7_ldr; always_ff @(posedge clk) b1_c7_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0 b1_c7 (.clk(clk), .rst(rst), .in_valid(b0_v), .out_valid(b1_c7_v), .MIDX(b0_tag[3:1]), .midx_out(b1_c7_mi), .mq_QH(b0_tag[48:4]), .mq_QHALF(b0_tag[110:49]), .DIR(b0_tag[0]), .dir_out(b1_c7_di), .tw_rst(b1_c7_lr), .tw_wen(b1_c7_lw), .tw_wdata(b1_c7_ld), .tw_slot(b1_c7_ls), .tw_dir(b1_c7_ldr), .x_in_0(b0_l7_byp), .x_in_1(b0_l15_p), .x_in_2(b0_l23_p), .x_in_3(b0_l31_p), .y_out_0(b1_c7_y0), .y_out_1(b1_c7_y1), .y_out_2(b1_c7_y2), .y_out_3(b1_c7_y3));
    logic [106:0] b1_cq0; assign b1_cq0 = b0_tag[110:4];
    logic [106:0] b1_cq;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(107), .D(33)) b1_cq_i (.clk(clk), .din(b1_cq0), .dout(b1_cq));
    logic [110:0] b1_tag; assign b1_tag = {b1_cq, b1_c0_mi, b1_c0_di};
    // block 2: lane-time transpose, lane bits [3] <-> cycle bits [10,11), 16 x S=2, latency 2051
    logic [61:0] b2_g0_i [0:1]; logic [61:0] b2_g0_o [0:1]; logic b2_g0_v;
    assign b2_g0_i[0] = b1_c0_y0;
    assign b2_g0_i[1] = b1_c0_y1;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b2_g0 (.clk(clk), .rst(rst), .data_valid(b1_c0_v), .data_in(b2_g0_i), .data_out_valid(b2_g0_v), .data_out(b2_g0_o));
    logic [61:0] b2_g1_i [0:1]; logic [61:0] b2_g1_o [0:1]; logic b2_g1_v;
    assign b2_g1_i[0] = b1_c1_y0;
    assign b2_g1_i[1] = b1_c1_y1;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b2_g1 (.clk(clk), .rst(rst), .data_valid(b1_c0_v), .data_in(b2_g1_i), .data_out_valid(b2_g1_v), .data_out(b2_g1_o));
    logic [61:0] b2_g2_i [0:1]; logic [61:0] b2_g2_o [0:1]; logic b2_g2_v;
    assign b2_g2_i[0] = b1_c2_y0;
    assign b2_g2_i[1] = b1_c2_y1;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b2_g2 (.clk(clk), .rst(rst), .data_valid(b1_c0_v), .data_in(b2_g2_i), .data_out_valid(b2_g2_v), .data_out(b2_g2_o));
    logic [61:0] b2_g3_i [0:1]; logic [61:0] b2_g3_o [0:1]; logic b2_g3_v;
    assign b2_g3_i[0] = b1_c3_y0;
    assign b2_g3_i[1] = b1_c3_y1;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b2_g3 (.clk(clk), .rst(rst), .data_valid(b1_c0_v), .data_in(b2_g3_i), .data_out_valid(b2_g3_v), .data_out(b2_g3_o));
    logic [61:0] b2_g4_i [0:1]; logic [61:0] b2_g4_o [0:1]; logic b2_g4_v;
    assign b2_g4_i[0] = b1_c4_y0;
    assign b2_g4_i[1] = b1_c4_y1;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b2_g4 (.clk(clk), .rst(rst), .data_valid(b1_c0_v), .data_in(b2_g4_i), .data_out_valid(b2_g4_v), .data_out(b2_g4_o));
    logic [61:0] b2_g5_i [0:1]; logic [61:0] b2_g5_o [0:1]; logic b2_g5_v;
    assign b2_g5_i[0] = b1_c5_y0;
    assign b2_g5_i[1] = b1_c5_y1;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b2_g5 (.clk(clk), .rst(rst), .data_valid(b1_c0_v), .data_in(b2_g5_i), .data_out_valid(b2_g5_v), .data_out(b2_g5_o));
    logic [61:0] b2_g6_i [0:1]; logic [61:0] b2_g6_o [0:1]; logic b2_g6_v;
    assign b2_g6_i[0] = b1_c6_y0;
    assign b2_g6_i[1] = b1_c6_y1;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b2_g6 (.clk(clk), .rst(rst), .data_valid(b1_c0_v), .data_in(b2_g6_i), .data_out_valid(b2_g6_v), .data_out(b2_g6_o));
    logic [61:0] b2_g7_i [0:1]; logic [61:0] b2_g7_o [0:1]; logic b2_g7_v;
    assign b2_g7_i[0] = b1_c7_y0;
    assign b2_g7_i[1] = b1_c7_y1;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b2_g7 (.clk(clk), .rst(rst), .data_valid(b1_c0_v), .data_in(b2_g7_i), .data_out_valid(b2_g7_v), .data_out(b2_g7_o));
    logic [61:0] b2_g8_i [0:1]; logic [61:0] b2_g8_o [0:1]; logic b2_g8_v;
    assign b2_g8_i[0] = b1_c0_y2;
    assign b2_g8_i[1] = b1_c0_y3;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b2_g8 (.clk(clk), .rst(rst), .data_valid(b1_c0_v), .data_in(b2_g8_i), .data_out_valid(b2_g8_v), .data_out(b2_g8_o));
    logic [61:0] b2_g9_i [0:1]; logic [61:0] b2_g9_o [0:1]; logic b2_g9_v;
    assign b2_g9_i[0] = b1_c1_y2;
    assign b2_g9_i[1] = b1_c1_y3;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b2_g9 (.clk(clk), .rst(rst), .data_valid(b1_c0_v), .data_in(b2_g9_i), .data_out_valid(b2_g9_v), .data_out(b2_g9_o));
    logic [61:0] b2_g10_i [0:1]; logic [61:0] b2_g10_o [0:1]; logic b2_g10_v;
    assign b2_g10_i[0] = b1_c2_y2;
    assign b2_g10_i[1] = b1_c2_y3;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b2_g10 (.clk(clk), .rst(rst), .data_valid(b1_c0_v), .data_in(b2_g10_i), .data_out_valid(b2_g10_v), .data_out(b2_g10_o));
    logic [61:0] b2_g11_i [0:1]; logic [61:0] b2_g11_o [0:1]; logic b2_g11_v;
    assign b2_g11_i[0] = b1_c3_y2;
    assign b2_g11_i[1] = b1_c3_y3;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b2_g11 (.clk(clk), .rst(rst), .data_valid(b1_c0_v), .data_in(b2_g11_i), .data_out_valid(b2_g11_v), .data_out(b2_g11_o));
    logic [61:0] b2_g12_i [0:1]; logic [61:0] b2_g12_o [0:1]; logic b2_g12_v;
    assign b2_g12_i[0] = b1_c4_y2;
    assign b2_g12_i[1] = b1_c4_y3;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b2_g12 (.clk(clk), .rst(rst), .data_valid(b1_c0_v), .data_in(b2_g12_i), .data_out_valid(b2_g12_v), .data_out(b2_g12_o));
    logic [61:0] b2_g13_i [0:1]; logic [61:0] b2_g13_o [0:1]; logic b2_g13_v;
    assign b2_g13_i[0] = b1_c5_y2;
    assign b2_g13_i[1] = b1_c5_y3;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b2_g13 (.clk(clk), .rst(rst), .data_valid(b1_c0_v), .data_in(b2_g13_i), .data_out_valid(b2_g13_v), .data_out(b2_g13_o));
    logic [61:0] b2_g14_i [0:1]; logic [61:0] b2_g14_o [0:1]; logic b2_g14_v;
    assign b2_g14_i[0] = b1_c6_y2;
    assign b2_g14_i[1] = b1_c6_y3;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b2_g14 (.clk(clk), .rst(rst), .data_valid(b1_c0_v), .data_in(b2_g14_i), .data_out_valid(b2_g14_v), .data_out(b2_g14_o));
    logic [61:0] b2_g15_i [0:1]; logic [61:0] b2_g15_o [0:1]; logic b2_g15_v;
    assign b2_g15_i[0] = b1_c7_y2;
    assign b2_g15_i[1] = b1_c7_y3;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b2_g15 (.clk(clk), .rst(rst), .data_valid(b1_c0_v), .data_in(b2_g15_i), .data_out_valid(b2_g15_v), .data_out(b2_g15_o));
    logic [110:0] b2_tag;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(111), .D(2051)) b2_tag_i (.clk(clk), .din(b1_tag), .dout(b2_tag));
    // block 3: twiddle stage 1, latency 30 (tables 3, multiplier 27)
    logic [10:0] b3_cnt;
    always_ff @(posedge clk) b3_cnt <= rst ? '0 : (b2_g0_v ? b3_cnt + 1'b1 : b3_cnt);
    logic [61:0] b3_t0;
    (* shreg_extract = "no" *) logic [61:0] b3_t0_q0;
    logic b3_t0_lwe; logic [4:0] b3_t0_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t0_lwd;
    always_ff @(posedge clk) begin b3_t0_lwe <= ld_v && ld_iq >= 11'd2 && ld_iq < 11'd4; b3_t0_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd2)}; b3_t0_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab0 b3_t0_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t0_lwe), .wa(b3_t0_lwa), .wcol(1'b0), .wd(b3_t0_lwd), .q0(b3_t0_q0));
    always_ff @(posedge clk) begin b3_t0 <= b3_t0_q0; end
    logic [61:0] b3_t1;
    (* shreg_extract = "no" *) logic [61:0] b3_t1_q0;
    logic b3_t1_lwe; logic [4:0] b3_t1_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t1_lwd;
    always_ff @(posedge clk) begin b3_t1_lwe <= ld_v && ld_iq >= 11'd2 && ld_iq < 11'd4; b3_t1_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd2)}; b3_t1_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab1 b3_t1_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t1_lwe), .wa(b3_t1_lwa), .wcol(1'b0), .wd(b3_t1_lwd), .q0(b3_t1_q0));
    always_ff @(posedge clk) begin b3_t1 <= b3_t1_q0; end
    logic [61:0] b3_t2;
    (* shreg_extract = "no" *) logic [61:0] b3_t2_q0;
    logic b3_t2_lwe; logic [4:0] b3_t2_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t2_lwd;
    always_ff @(posedge clk) begin b3_t2_lwe <= ld_v && ld_iq >= 11'd4 && ld_iq < 11'd6; b3_t2_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd4)}; b3_t2_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab2 b3_t2_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t2_lwe), .wa(b3_t2_lwa), .wcol(1'b0), .wd(b3_t2_lwd), .q0(b3_t2_q0));
    always_ff @(posedge clk) begin b3_t2 <= b3_t2_q0; end
    logic [61:0] b3_t3;
    (* shreg_extract = "no" *) logic [61:0] b3_t3_q0;
    logic b3_t3_lwe; logic [4:0] b3_t3_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t3_lwd;
    always_ff @(posedge clk) begin b3_t3_lwe <= ld_v && ld_iq >= 11'd4 && ld_iq < 11'd6; b3_t3_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd4)}; b3_t3_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab3 b3_t3_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t3_lwe), .wa(b3_t3_lwa), .wcol(1'b0), .wd(b3_t3_lwd), .q0(b3_t3_q0));
    always_ff @(posedge clk) begin b3_t3 <= b3_t3_q0; end
    logic [61:0] b3_t4;
    (* shreg_extract = "no" *) logic [61:0] b3_t4_q0;
    logic b3_t4_lwe; logic [4:0] b3_t4_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t4_lwd;
    always_ff @(posedge clk) begin b3_t4_lwe <= ld_v && ld_iq >= 11'd6 && ld_iq < 11'd8; b3_t4_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd6)}; b3_t4_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab4 b3_t4_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t4_lwe), .wa(b3_t4_lwa), .wcol(1'b0), .wd(b3_t4_lwd), .q0(b3_t4_q0));
    always_ff @(posedge clk) begin b3_t4 <= b3_t4_q0; end
    logic [61:0] b3_t5;
    (* shreg_extract = "no" *) logic [61:0] b3_t5_q0;
    logic b3_t5_lwe; logic [4:0] b3_t5_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t5_lwd;
    always_ff @(posedge clk) begin b3_t5_lwe <= ld_v && ld_iq >= 11'd6 && ld_iq < 11'd8; b3_t5_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd6)}; b3_t5_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab5 b3_t5_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t5_lwe), .wa(b3_t5_lwa), .wcol(1'b0), .wd(b3_t5_lwd), .q0(b3_t5_q0));
    always_ff @(posedge clk) begin b3_t5 <= b3_t5_q0; end
    logic [61:0] b3_t6;
    (* shreg_extract = "no" *) logic [61:0] b3_t6_q0;
    logic b3_t6_lwe; logic [4:0] b3_t6_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t6_lwd;
    always_ff @(posedge clk) begin b3_t6_lwe <= ld_v && ld_iq >= 11'd8 && ld_iq < 11'd10; b3_t6_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd8)}; b3_t6_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab6 b3_t6_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t6_lwe), .wa(b3_t6_lwa), .wcol(1'b0), .wd(b3_t6_lwd), .q0(b3_t6_q0));
    always_ff @(posedge clk) begin b3_t6 <= b3_t6_q0; end
    logic [61:0] b3_t7;
    (* shreg_extract = "no" *) logic [61:0] b3_t7_q0;
    logic b3_t7_lwe; logic [4:0] b3_t7_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t7_lwd;
    always_ff @(posedge clk) begin b3_t7_lwe <= ld_v && ld_iq >= 11'd8 && ld_iq < 11'd10; b3_t7_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd8)}; b3_t7_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab7 b3_t7_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t7_lwe), .wa(b3_t7_lwa), .wcol(1'b0), .wd(b3_t7_lwd), .q0(b3_t7_q0));
    always_ff @(posedge clk) begin b3_t7 <= b3_t7_q0; end
    logic [61:0] b3_t8;
    (* shreg_extract = "no" *) logic [61:0] b3_t8_q0;
    logic b3_t8_lwe; logic [4:0] b3_t8_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t8_lwd;
    always_ff @(posedge clk) begin b3_t8_lwe <= ld_v && ld_iq >= 11'd10 && ld_iq < 11'd12; b3_t8_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd10)}; b3_t8_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab8 b3_t8_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t8_lwe), .wa(b3_t8_lwa), .wcol(1'b0), .wd(b3_t8_lwd), .q0(b3_t8_q0));
    always_ff @(posedge clk) begin b3_t8 <= b3_t8_q0; end
    logic [61:0] b3_t9;
    (* shreg_extract = "no" *) logic [61:0] b3_t9_q0;
    logic b3_t9_lwe; logic [4:0] b3_t9_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t9_lwd;
    always_ff @(posedge clk) begin b3_t9_lwe <= ld_v && ld_iq >= 11'd10 && ld_iq < 11'd12; b3_t9_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd10)}; b3_t9_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab9 b3_t9_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t9_lwe), .wa(b3_t9_lwa), .wcol(1'b0), .wd(b3_t9_lwd), .q0(b3_t9_q0));
    always_ff @(posedge clk) begin b3_t9 <= b3_t9_q0; end
    logic [61:0] b3_t10;
    (* shreg_extract = "no" *) logic [61:0] b3_t10_q0;
    logic b3_t10_lwe; logic [4:0] b3_t10_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t10_lwd;
    always_ff @(posedge clk) begin b3_t10_lwe <= ld_v && ld_iq >= 11'd12 && ld_iq < 11'd14; b3_t10_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd12)}; b3_t10_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab10 b3_t10_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t10_lwe), .wa(b3_t10_lwa), .wcol(1'b0), .wd(b3_t10_lwd), .q0(b3_t10_q0));
    always_ff @(posedge clk) begin b3_t10 <= b3_t10_q0; end
    logic [61:0] b3_t11;
    (* shreg_extract = "no" *) logic [61:0] b3_t11_q0;
    logic b3_t11_lwe; logic [4:0] b3_t11_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t11_lwd;
    always_ff @(posedge clk) begin b3_t11_lwe <= ld_v && ld_iq >= 11'd12 && ld_iq < 11'd14; b3_t11_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd12)}; b3_t11_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab11 b3_t11_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t11_lwe), .wa(b3_t11_lwa), .wcol(1'b0), .wd(b3_t11_lwd), .q0(b3_t11_q0));
    always_ff @(posedge clk) begin b3_t11 <= b3_t11_q0; end
    logic [61:0] b3_t12;
    (* shreg_extract = "no" *) logic [61:0] b3_t12_q0;
    logic b3_t12_lwe; logic [4:0] b3_t12_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t12_lwd;
    always_ff @(posedge clk) begin b3_t12_lwe <= ld_v && ld_iq >= 11'd14 && ld_iq < 11'd16; b3_t12_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd14)}; b3_t12_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab12 b3_t12_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t12_lwe), .wa(b3_t12_lwa), .wcol(1'b0), .wd(b3_t12_lwd), .q0(b3_t12_q0));
    always_ff @(posedge clk) begin b3_t12 <= b3_t12_q0; end
    logic [61:0] b3_t13;
    (* shreg_extract = "no" *) logic [61:0] b3_t13_q0;
    logic b3_t13_lwe; logic [4:0] b3_t13_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t13_lwd;
    always_ff @(posedge clk) begin b3_t13_lwe <= ld_v && ld_iq >= 11'd14 && ld_iq < 11'd16; b3_t13_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd14)}; b3_t13_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab13 b3_t13_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t13_lwe), .wa(b3_t13_lwa), .wcol(1'b0), .wd(b3_t13_lwd), .q0(b3_t13_q0));
    always_ff @(posedge clk) begin b3_t13 <= b3_t13_q0; end
    logic [61:0] b3_t14;
    (* shreg_extract = "no" *) logic [61:0] b3_t14_q0;
    logic b3_t14_lwe; logic [4:0] b3_t14_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t14_lwd;
    always_ff @(posedge clk) begin b3_t14_lwe <= ld_v && ld_iq >= 11'd16 && ld_iq < 11'd18; b3_t14_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd16)}; b3_t14_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab14 b3_t14_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t14_lwe), .wa(b3_t14_lwa), .wcol(1'b0), .wd(b3_t14_lwd), .q0(b3_t14_q0));
    always_ff @(posedge clk) begin b3_t14 <= b3_t14_q0; end
    logic [61:0] b3_t15;
    (* shreg_extract = "no" *) logic [61:0] b3_t15_q0;
    logic b3_t15_lwe; logic [4:0] b3_t15_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t15_lwd;
    always_ff @(posedge clk) begin b3_t15_lwe <= ld_v && ld_iq >= 11'd16 && ld_iq < 11'd18; b3_t15_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd16)}; b3_t15_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab15 b3_t15_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t15_lwe), .wa(b3_t15_lwa), .wcol(1'b0), .wd(b3_t15_lwd), .q0(b3_t15_q0));
    always_ff @(posedge clk) begin b3_t15 <= b3_t15_q0; end
    logic [61:0] b3_t16;
    (* shreg_extract = "no" *) logic [61:0] b3_t16_q0;
    logic b3_t16_lwe; logic [4:0] b3_t16_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t16_lwd;
    always_ff @(posedge clk) begin b3_t16_lwe <= ld_v && ld_iq >= 11'd18 && ld_iq < 11'd20; b3_t16_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd18)}; b3_t16_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab16 b3_t16_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t16_lwe), .wa(b3_t16_lwa), .wcol(1'b0), .wd(b3_t16_lwd), .q0(b3_t16_q0));
    always_ff @(posedge clk) begin b3_t16 <= b3_t16_q0; end
    logic [61:0] b3_t17;
    (* shreg_extract = "no" *) logic [61:0] b3_t17_q0;
    logic b3_t17_lwe; logic [4:0] b3_t17_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t17_lwd;
    always_ff @(posedge clk) begin b3_t17_lwe <= ld_v && ld_iq >= 11'd18 && ld_iq < 11'd20; b3_t17_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd18)}; b3_t17_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab17 b3_t17_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t17_lwe), .wa(b3_t17_lwa), .wcol(1'b0), .wd(b3_t17_lwd), .q0(b3_t17_q0));
    always_ff @(posedge clk) begin b3_t17 <= b3_t17_q0; end
    logic [61:0] b3_t18;
    (* shreg_extract = "no" *) logic [61:0] b3_t18_q0;
    logic b3_t18_lwe; logic [4:0] b3_t18_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t18_lwd;
    always_ff @(posedge clk) begin b3_t18_lwe <= ld_v && ld_iq >= 11'd20 && ld_iq < 11'd22; b3_t18_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd20)}; b3_t18_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab18 b3_t18_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t18_lwe), .wa(b3_t18_lwa), .wcol(1'b0), .wd(b3_t18_lwd), .q0(b3_t18_q0));
    always_ff @(posedge clk) begin b3_t18 <= b3_t18_q0; end
    logic [61:0] b3_t19;
    (* shreg_extract = "no" *) logic [61:0] b3_t19_q0;
    logic b3_t19_lwe; logic [4:0] b3_t19_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t19_lwd;
    always_ff @(posedge clk) begin b3_t19_lwe <= ld_v && ld_iq >= 11'd20 && ld_iq < 11'd22; b3_t19_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd20)}; b3_t19_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab19 b3_t19_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t19_lwe), .wa(b3_t19_lwa), .wcol(1'b0), .wd(b3_t19_lwd), .q0(b3_t19_q0));
    always_ff @(posedge clk) begin b3_t19 <= b3_t19_q0; end
    logic [61:0] b3_t20;
    (* shreg_extract = "no" *) logic [61:0] b3_t20_q0;
    logic b3_t20_lwe; logic [4:0] b3_t20_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t20_lwd;
    always_ff @(posedge clk) begin b3_t20_lwe <= ld_v && ld_iq >= 11'd22 && ld_iq < 11'd24; b3_t20_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd22)}; b3_t20_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab20 b3_t20_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t20_lwe), .wa(b3_t20_lwa), .wcol(1'b0), .wd(b3_t20_lwd), .q0(b3_t20_q0));
    always_ff @(posedge clk) begin b3_t20 <= b3_t20_q0; end
    logic [61:0] b3_t21;
    (* shreg_extract = "no" *) logic [61:0] b3_t21_q0;
    logic b3_t21_lwe; logic [4:0] b3_t21_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t21_lwd;
    always_ff @(posedge clk) begin b3_t21_lwe <= ld_v && ld_iq >= 11'd22 && ld_iq < 11'd24; b3_t21_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd22)}; b3_t21_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab21 b3_t21_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t21_lwe), .wa(b3_t21_lwa), .wcol(1'b0), .wd(b3_t21_lwd), .q0(b3_t21_q0));
    always_ff @(posedge clk) begin b3_t21 <= b3_t21_q0; end
    logic [61:0] b3_t22;
    (* shreg_extract = "no" *) logic [61:0] b3_t22_q0;
    logic b3_t22_lwe; logic [4:0] b3_t22_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t22_lwd;
    always_ff @(posedge clk) begin b3_t22_lwe <= ld_v && ld_iq >= 11'd24 && ld_iq < 11'd26; b3_t22_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd24)}; b3_t22_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab22 b3_t22_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t22_lwe), .wa(b3_t22_lwa), .wcol(1'b0), .wd(b3_t22_lwd), .q0(b3_t22_q0));
    always_ff @(posedge clk) begin b3_t22 <= b3_t22_q0; end
    logic [61:0] b3_t23;
    (* shreg_extract = "no" *) logic [61:0] b3_t23_q0;
    logic b3_t23_lwe; logic [4:0] b3_t23_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t23_lwd;
    always_ff @(posedge clk) begin b3_t23_lwe <= ld_v && ld_iq >= 11'd24 && ld_iq < 11'd26; b3_t23_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd24)}; b3_t23_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab23 b3_t23_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t23_lwe), .wa(b3_t23_lwa), .wcol(1'b0), .wd(b3_t23_lwd), .q0(b3_t23_q0));
    always_ff @(posedge clk) begin b3_t23 <= b3_t23_q0; end
    logic [61:0] b3_t24;
    (* shreg_extract = "no" *) logic [61:0] b3_t24_q0;
    logic b3_t24_lwe; logic [4:0] b3_t24_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t24_lwd;
    always_ff @(posedge clk) begin b3_t24_lwe <= ld_v && ld_iq >= 11'd26 && ld_iq < 11'd28; b3_t24_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd26)}; b3_t24_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab24 b3_t24_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t24_lwe), .wa(b3_t24_lwa), .wcol(1'b0), .wd(b3_t24_lwd), .q0(b3_t24_q0));
    always_ff @(posedge clk) begin b3_t24 <= b3_t24_q0; end
    logic [61:0] b3_t25;
    (* shreg_extract = "no" *) logic [61:0] b3_t25_q0;
    logic b3_t25_lwe; logic [4:0] b3_t25_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t25_lwd;
    always_ff @(posedge clk) begin b3_t25_lwe <= ld_v && ld_iq >= 11'd26 && ld_iq < 11'd28; b3_t25_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd26)}; b3_t25_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab25 b3_t25_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t25_lwe), .wa(b3_t25_lwa), .wcol(1'b0), .wd(b3_t25_lwd), .q0(b3_t25_q0));
    always_ff @(posedge clk) begin b3_t25 <= b3_t25_q0; end
    logic [61:0] b3_t26;
    (* shreg_extract = "no" *) logic [61:0] b3_t26_q0;
    logic b3_t26_lwe; logic [4:0] b3_t26_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t26_lwd;
    always_ff @(posedge clk) begin b3_t26_lwe <= ld_v && ld_iq >= 11'd28 && ld_iq < 11'd30; b3_t26_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd28)}; b3_t26_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab26 b3_t26_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t26_lwe), .wa(b3_t26_lwa), .wcol(1'b0), .wd(b3_t26_lwd), .q0(b3_t26_q0));
    always_ff @(posedge clk) begin b3_t26 <= b3_t26_q0; end
    logic [61:0] b3_t27;
    (* shreg_extract = "no" *) logic [61:0] b3_t27_q0;
    logic b3_t27_lwe; logic [4:0] b3_t27_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t27_lwd;
    always_ff @(posedge clk) begin b3_t27_lwe <= ld_v && ld_iq >= 11'd28 && ld_iq < 11'd30; b3_t27_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd28)}; b3_t27_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab27 b3_t27_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t27_lwe), .wa(b3_t27_lwa), .wcol(1'b0), .wd(b3_t27_lwd), .q0(b3_t27_q0));
    always_ff @(posedge clk) begin b3_t27 <= b3_t27_q0; end
    logic [61:0] b3_t28;
    (* shreg_extract = "no" *) logic [61:0] b3_t28_q0;
    logic b3_t28_lwe; logic [4:0] b3_t28_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t28_lwd;
    always_ff @(posedge clk) begin b3_t28_lwe <= ld_v && ld_iq >= 11'd30 && ld_iq < 11'd32; b3_t28_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd30)}; b3_t28_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab28 b3_t28_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t28_lwe), .wa(b3_t28_lwa), .wcol(1'b0), .wd(b3_t28_lwd), .q0(b3_t28_q0));
    always_ff @(posedge clk) begin b3_t28 <= b3_t28_q0; end
    logic [61:0] b3_t29;
    (* shreg_extract = "no" *) logic [61:0] b3_t29_q0;
    logic b3_t29_lwe; logic [4:0] b3_t29_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t29_lwd;
    always_ff @(posedge clk) begin b3_t29_lwe <= ld_v && ld_iq >= 11'd30 && ld_iq < 11'd32; b3_t29_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd30)}; b3_t29_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab29 b3_t29_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t29_lwe), .wa(b3_t29_lwa), .wcol(1'b0), .wd(b3_t29_lwd), .q0(b3_t29_q0));
    always_ff @(posedge clk) begin b3_t29 <= b3_t29_q0; end
    logic [61:0] b3_t30;
    (* shreg_extract = "no" *) logic [61:0] b3_t30_q0;
    logic b3_t30_lwe; logic [4:0] b3_t30_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t30_lwd;
    always_ff @(posedge clk) begin b3_t30_lwe <= ld_v && ld_iq >= 11'd32 && ld_iq < 11'd34; b3_t30_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd32)}; b3_t30_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab30 b3_t30_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t30_lwe), .wa(b3_t30_lwa), .wcol(1'b0), .wd(b3_t30_lwd), .q0(b3_t30_q0));
    always_ff @(posedge clk) begin b3_t30 <= b3_t30_q0; end
    logic [61:0] b3_t31;
    (* shreg_extract = "no" *) logic [61:0] b3_t31_q0;
    logic b3_t31_lwe; logic [4:0] b3_t31_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b3_t31_lwd;
    always_ff @(posedge clk) begin b3_t31_lwe <= ld_v && ld_iq >= 11'd32 && ld_iq < 11'd34; b3_t31_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd32)}; b3_t31_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw1_tab31 b3_t31_i (.clk(clk), .addr({b2_tag[3:1], b2_tag[0], b3_cnt[10]}), .we(b3_t31_lwe), .wa(b3_t31_lwa), .wcol(1'b0), .wd(b3_t31_lwd), .q0(b3_t31_q0));
    always_ff @(posedge clk) begin b3_t31 <= b3_t31_q0; end
    logic [61:0] b3_l0_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l0_a_i (.clk(clk), .din(b2_g0_o[0]), .dout(b3_l0_a));
    logic [44:0] b3_mq3_0_QH_c; assign b3_mq3_0_QH_c = b2_tag[48:4];
    logic [44:0] b3_mq3_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(45), .D(2)) b3_mq3_0_QH_i (.clk(clk), .din(b3_mq3_0_QH_c), .dout(b3_mq3_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b3_mq3_s0_QH;
    always_ff @(posedge clk) b3_mq3_s0_QH <= b3_mq3_0_QH;
    logic [61:0] b3_l0_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l0_mul (.clk(clk), .A(b3_l0_a), .B(b3_t0), .QH(b3_mq3_s0_QH), .P(b3_l0_p));
    logic [61:0] b3_l1_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l1_a_i (.clk(clk), .din(b2_g1_o[0]), .dout(b3_l1_a));
    logic [61:0] b3_l1_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l1_mul (.clk(clk), .A(b3_l1_a), .B(b3_t1), .QH(b3_mq3_s0_QH), .P(b3_l1_p));
    logic [61:0] b3_l2_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l2_a_i (.clk(clk), .din(b2_g2_o[0]), .dout(b3_l2_a));
    logic [61:0] b3_l2_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l2_mul (.clk(clk), .A(b3_l2_a), .B(b3_t2), .QH(b3_mq3_s0_QH), .P(b3_l2_p));
    logic [61:0] b3_l3_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l3_a_i (.clk(clk), .din(b2_g3_o[0]), .dout(b3_l3_a));
    logic [61:0] b3_l3_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l3_mul (.clk(clk), .A(b3_l3_a), .B(b3_t3), .QH(b3_mq3_s0_QH), .P(b3_l3_p));
    logic [61:0] b3_l4_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l4_a_i (.clk(clk), .din(b2_g4_o[0]), .dout(b3_l4_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b3_mq3_s1_QH;
    always_ff @(posedge clk) b3_mq3_s1_QH <= b3_mq3_0_QH;
    logic [61:0] b3_l4_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l4_mul (.clk(clk), .A(b3_l4_a), .B(b3_t4), .QH(b3_mq3_s1_QH), .P(b3_l4_p));
    logic [61:0] b3_l5_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l5_a_i (.clk(clk), .din(b2_g5_o[0]), .dout(b3_l5_a));
    logic [61:0] b3_l5_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l5_mul (.clk(clk), .A(b3_l5_a), .B(b3_t5), .QH(b3_mq3_s1_QH), .P(b3_l5_p));
    logic [61:0] b3_l6_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l6_a_i (.clk(clk), .din(b2_g6_o[0]), .dout(b3_l6_a));
    logic [61:0] b3_l6_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l6_mul (.clk(clk), .A(b3_l6_a), .B(b3_t6), .QH(b3_mq3_s1_QH), .P(b3_l6_p));
    logic [61:0] b3_l7_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l7_a_i (.clk(clk), .din(b2_g7_o[0]), .dout(b3_l7_a));
    logic [61:0] b3_l7_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l7_mul (.clk(clk), .A(b3_l7_a), .B(b3_t7), .QH(b3_mq3_s1_QH), .P(b3_l7_p));
    logic [61:0] b3_l8_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l8_a_i (.clk(clk), .din(b2_g0_o[1]), .dout(b3_l8_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b3_mq3_s2_QH;
    always_ff @(posedge clk) b3_mq3_s2_QH <= b3_mq3_0_QH;
    logic [61:0] b3_l8_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l8_mul (.clk(clk), .A(b3_l8_a), .B(b3_t8), .QH(b3_mq3_s2_QH), .P(b3_l8_p));
    logic [61:0] b3_l9_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l9_a_i (.clk(clk), .din(b2_g1_o[1]), .dout(b3_l9_a));
    logic [61:0] b3_l9_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l9_mul (.clk(clk), .A(b3_l9_a), .B(b3_t9), .QH(b3_mq3_s2_QH), .P(b3_l9_p));
    logic [61:0] b3_l10_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l10_a_i (.clk(clk), .din(b2_g2_o[1]), .dout(b3_l10_a));
    logic [61:0] b3_l10_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l10_mul (.clk(clk), .A(b3_l10_a), .B(b3_t10), .QH(b3_mq3_s2_QH), .P(b3_l10_p));
    logic [61:0] b3_l11_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l11_a_i (.clk(clk), .din(b2_g3_o[1]), .dout(b3_l11_a));
    logic [61:0] b3_l11_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l11_mul (.clk(clk), .A(b3_l11_a), .B(b3_t11), .QH(b3_mq3_s2_QH), .P(b3_l11_p));
    logic [61:0] b3_l12_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l12_a_i (.clk(clk), .din(b2_g4_o[1]), .dout(b3_l12_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b3_mq3_s3_QH;
    always_ff @(posedge clk) b3_mq3_s3_QH <= b3_mq3_0_QH;
    logic [61:0] b3_l12_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l12_mul (.clk(clk), .A(b3_l12_a), .B(b3_t12), .QH(b3_mq3_s3_QH), .P(b3_l12_p));
    logic [61:0] b3_l13_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l13_a_i (.clk(clk), .din(b2_g5_o[1]), .dout(b3_l13_a));
    logic [61:0] b3_l13_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l13_mul (.clk(clk), .A(b3_l13_a), .B(b3_t13), .QH(b3_mq3_s3_QH), .P(b3_l13_p));
    logic [61:0] b3_l14_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l14_a_i (.clk(clk), .din(b2_g6_o[1]), .dout(b3_l14_a));
    logic [61:0] b3_l14_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l14_mul (.clk(clk), .A(b3_l14_a), .B(b3_t14), .QH(b3_mq3_s3_QH), .P(b3_l14_p));
    logic [61:0] b3_l15_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l15_a_i (.clk(clk), .din(b2_g7_o[1]), .dout(b3_l15_a));
    logic [61:0] b3_l15_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l15_mul (.clk(clk), .A(b3_l15_a), .B(b3_t15), .QH(b3_mq3_s3_QH), .P(b3_l15_p));
    logic [61:0] b3_l16_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l16_a_i (.clk(clk), .din(b2_g8_o[0]), .dout(b3_l16_a));
    logic [44:0] b3_mq3_1_QH_c; assign b3_mq3_1_QH_c = b2_tag[48:4];
    logic [44:0] b3_mq3_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(45), .D(2)) b3_mq3_1_QH_i (.clk(clk), .din(b3_mq3_1_QH_c), .dout(b3_mq3_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b3_mq3_s4_QH;
    always_ff @(posedge clk) b3_mq3_s4_QH <= b3_mq3_1_QH;
    logic [61:0] b3_l16_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l16_mul (.clk(clk), .A(b3_l16_a), .B(b3_t16), .QH(b3_mq3_s4_QH), .P(b3_l16_p));
    logic [61:0] b3_l17_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l17_a_i (.clk(clk), .din(b2_g9_o[0]), .dout(b3_l17_a));
    logic [61:0] b3_l17_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l17_mul (.clk(clk), .A(b3_l17_a), .B(b3_t17), .QH(b3_mq3_s4_QH), .P(b3_l17_p));
    logic [61:0] b3_l18_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l18_a_i (.clk(clk), .din(b2_g10_o[0]), .dout(b3_l18_a));
    logic [61:0] b3_l18_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l18_mul (.clk(clk), .A(b3_l18_a), .B(b3_t18), .QH(b3_mq3_s4_QH), .P(b3_l18_p));
    logic [61:0] b3_l19_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l19_a_i (.clk(clk), .din(b2_g11_o[0]), .dout(b3_l19_a));
    logic [61:0] b3_l19_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l19_mul (.clk(clk), .A(b3_l19_a), .B(b3_t19), .QH(b3_mq3_s4_QH), .P(b3_l19_p));
    logic [61:0] b3_l20_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l20_a_i (.clk(clk), .din(b2_g12_o[0]), .dout(b3_l20_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b3_mq3_s5_QH;
    always_ff @(posedge clk) b3_mq3_s5_QH <= b3_mq3_1_QH;
    logic [61:0] b3_l20_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l20_mul (.clk(clk), .A(b3_l20_a), .B(b3_t20), .QH(b3_mq3_s5_QH), .P(b3_l20_p));
    logic [61:0] b3_l21_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l21_a_i (.clk(clk), .din(b2_g13_o[0]), .dout(b3_l21_a));
    logic [61:0] b3_l21_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l21_mul (.clk(clk), .A(b3_l21_a), .B(b3_t21), .QH(b3_mq3_s5_QH), .P(b3_l21_p));
    logic [61:0] b3_l22_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l22_a_i (.clk(clk), .din(b2_g14_o[0]), .dout(b3_l22_a));
    logic [61:0] b3_l22_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l22_mul (.clk(clk), .A(b3_l22_a), .B(b3_t22), .QH(b3_mq3_s5_QH), .P(b3_l22_p));
    logic [61:0] b3_l23_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l23_a_i (.clk(clk), .din(b2_g15_o[0]), .dout(b3_l23_a));
    logic [61:0] b3_l23_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l23_mul (.clk(clk), .A(b3_l23_a), .B(b3_t23), .QH(b3_mq3_s5_QH), .P(b3_l23_p));
    logic [61:0] b3_l24_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l24_a_i (.clk(clk), .din(b2_g8_o[1]), .dout(b3_l24_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b3_mq3_s6_QH;
    always_ff @(posedge clk) b3_mq3_s6_QH <= b3_mq3_1_QH;
    logic [61:0] b3_l24_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l24_mul (.clk(clk), .A(b3_l24_a), .B(b3_t24), .QH(b3_mq3_s6_QH), .P(b3_l24_p));
    logic [61:0] b3_l25_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l25_a_i (.clk(clk), .din(b2_g9_o[1]), .dout(b3_l25_a));
    logic [61:0] b3_l25_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l25_mul (.clk(clk), .A(b3_l25_a), .B(b3_t25), .QH(b3_mq3_s6_QH), .P(b3_l25_p));
    logic [61:0] b3_l26_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l26_a_i (.clk(clk), .din(b2_g10_o[1]), .dout(b3_l26_a));
    logic [61:0] b3_l26_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l26_mul (.clk(clk), .A(b3_l26_a), .B(b3_t26), .QH(b3_mq3_s6_QH), .P(b3_l26_p));
    logic [61:0] b3_l27_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l27_a_i (.clk(clk), .din(b2_g11_o[1]), .dout(b3_l27_a));
    logic [61:0] b3_l27_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l27_mul (.clk(clk), .A(b3_l27_a), .B(b3_t27), .QH(b3_mq3_s6_QH), .P(b3_l27_p));
    logic [61:0] b3_l28_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l28_a_i (.clk(clk), .din(b2_g12_o[1]), .dout(b3_l28_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b3_mq3_s7_QH;
    always_ff @(posedge clk) b3_mq3_s7_QH <= b3_mq3_1_QH;
    logic [61:0] b3_l28_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l28_mul (.clk(clk), .A(b3_l28_a), .B(b3_t28), .QH(b3_mq3_s7_QH), .P(b3_l28_p));
    logic [61:0] b3_l29_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l29_a_i (.clk(clk), .din(b2_g13_o[1]), .dout(b3_l29_a));
    logic [61:0] b3_l29_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l29_mul (.clk(clk), .A(b3_l29_a), .B(b3_t29), .QH(b3_mq3_s7_QH), .P(b3_l29_p));
    logic [61:0] b3_l30_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l30_a_i (.clk(clk), .din(b2_g14_o[1]), .dout(b3_l30_a));
    logic [61:0] b3_l30_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l30_mul (.clk(clk), .A(b3_l30_a), .B(b3_t30), .QH(b3_mq3_s7_QH), .P(b3_l30_p));
    logic [61:0] b3_l31_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b3_l31_a_i (.clk(clk), .din(b2_g15_o[1]), .dout(b3_l31_a));
    logic [61:0] b3_l31_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b3_l31_mul (.clk(clk), .A(b3_l31_a), .B(b3_t31), .QH(b3_mq3_s7_QH), .P(b3_l31_p));
    logic [29:0] b3_v_sr;
    always_ff @(posedge clk) b3_v_sr <= rst ? '0 : {b3_v_sr[28:0], b2_g0_v};
    logic b3_v; assign b3_v = b3_v_sr[29];
    logic [110:0] b3_tag;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(111), .D(30)) b3_tag_i (.clk(clk), .din(b2_tag), .dout(b3_tag));
    // block 4: pass 1, 2 x ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p1 (16-point), latency 93
    logic [61:0] b4_c0_y0, b4_c0_y1, b4_c0_y2, b4_c0_y3, b4_c0_y4, b4_c0_y5, b4_c0_y6, b4_c0_y7, b4_c0_y8, b4_c0_y9, b4_c0_y10, b4_c0_y11, b4_c0_y12, b4_c0_y13, b4_c0_y14, b4_c0_y15;
    logic b4_c0_v; logic [2:0] b4_c0_mi; logic b4_c0_di;
    logic b4_c0_lr, b4_c0_lw; (* equivalent_register_removal = "no" *) logic [61:0] b4_c0_ld;
    always_ff @(posedge clk) begin b4_c0_lr <= ld_r; b4_c0_lw <= ld_v && ld_iq >= 11'd34 && ld_iq < 11'd41; b4_c0_ld <= ld_d[61:0]; end
    logic [2:0] b4_c0_ls; always_ff @(posedge clk) b4_c0_ls <= ld_sl;
    logic b4_c0_ldr; always_ff @(posedge clk) b4_c0_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p1 b4_c0 (.clk(clk), .rst(rst), .in_valid(b3_v), .out_valid(b4_c0_v), .MIDX(b3_tag[3:1]), .midx_out(b4_c0_mi), .mq_QH(b3_tag[48:4]), .mq_QHALF(b3_tag[110:49]), .DIR(b3_tag[0]), .dir_out(b4_c0_di), .tw_rst(b4_c0_lr), .tw_wen(b4_c0_lw), .tw_wdata(b4_c0_ld), .tw_slot(b4_c0_ls), .tw_dir(b4_c0_ldr), .x_in_0(b3_l0_p), .x_in_1(b3_l8_p), .x_in_2(b3_l1_p), .x_in_3(b3_l9_p), .x_in_4(b3_l2_p), .x_in_5(b3_l10_p), .x_in_6(b3_l3_p), .x_in_7(b3_l11_p), .x_in_8(b3_l4_p), .x_in_9(b3_l12_p), .x_in_10(b3_l5_p), .x_in_11(b3_l13_p), .x_in_12(b3_l6_p), .x_in_13(b3_l14_p), .x_in_14(b3_l7_p), .x_in_15(b3_l15_p), .y_out_0(b4_c0_y0), .y_out_1(b4_c0_y1), .y_out_2(b4_c0_y2), .y_out_3(b4_c0_y3), .y_out_4(b4_c0_y4), .y_out_5(b4_c0_y5), .y_out_6(b4_c0_y6), .y_out_7(b4_c0_y7), .y_out_8(b4_c0_y8), .y_out_9(b4_c0_y9), .y_out_10(b4_c0_y10), .y_out_11(b4_c0_y11), .y_out_12(b4_c0_y12), .y_out_13(b4_c0_y13), .y_out_14(b4_c0_y14), .y_out_15(b4_c0_y15));
    logic [61:0] b4_c1_y0, b4_c1_y1, b4_c1_y2, b4_c1_y3, b4_c1_y4, b4_c1_y5, b4_c1_y6, b4_c1_y7, b4_c1_y8, b4_c1_y9, b4_c1_y10, b4_c1_y11, b4_c1_y12, b4_c1_y13, b4_c1_y14, b4_c1_y15;
    logic b4_c1_v; logic [2:0] b4_c1_mi; logic b4_c1_di;
    logic b4_c1_lr, b4_c1_lw; (* equivalent_register_removal = "no" *) logic [61:0] b4_c1_ld;
    always_ff @(posedge clk) begin b4_c1_lr <= ld_r; b4_c1_lw <= ld_v && ld_iq >= 11'd34 && ld_iq < 11'd41; b4_c1_ld <= ld_d[61:0]; end
    logic [2:0] b4_c1_ls; always_ff @(posedge clk) b4_c1_ls <= ld_sl;
    logic b4_c1_ldr; always_ff @(posedge clk) b4_c1_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p1 b4_c1 (.clk(clk), .rst(rst), .in_valid(b3_v), .out_valid(b4_c1_v), .MIDX(b3_tag[3:1]), .midx_out(b4_c1_mi), .mq_QH(b3_tag[48:4]), .mq_QHALF(b3_tag[110:49]), .DIR(b3_tag[0]), .dir_out(b4_c1_di), .tw_rst(b4_c1_lr), .tw_wen(b4_c1_lw), .tw_wdata(b4_c1_ld), .tw_slot(b4_c1_ls), .tw_dir(b4_c1_ldr), .x_in_0(b3_l16_p), .x_in_1(b3_l24_p), .x_in_2(b3_l17_p), .x_in_3(b3_l25_p), .x_in_4(b3_l18_p), .x_in_5(b3_l26_p), .x_in_6(b3_l19_p), .x_in_7(b3_l27_p), .x_in_8(b3_l20_p), .x_in_9(b3_l28_p), .x_in_10(b3_l21_p), .x_in_11(b3_l29_p), .x_in_12(b3_l22_p), .x_in_13(b3_l30_p), .x_in_14(b3_l23_p), .x_in_15(b3_l31_p), .y_out_0(b4_c1_y0), .y_out_1(b4_c1_y1), .y_out_2(b4_c1_y2), .y_out_3(b4_c1_y3), .y_out_4(b4_c1_y4), .y_out_5(b4_c1_y5), .y_out_6(b4_c1_y6), .y_out_7(b4_c1_y7), .y_out_8(b4_c1_y8), .y_out_9(b4_c1_y9), .y_out_10(b4_c1_y10), .y_out_11(b4_c1_y11), .y_out_12(b4_c1_y12), .y_out_13(b4_c1_y13), .y_out_14(b4_c1_y14), .y_out_15(b4_c1_y15));
    logic [106:0] b4_cq0; assign b4_cq0 = b3_tag[110:4];
    logic [106:0] b4_cq;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(107), .D(93)) b4_cq_i (.clk(clk), .din(b4_cq0), .dout(b4_cq));
    logic [110:0] b4_tag; assign b4_tag = {b4_cq, b4_c0_mi, b4_c0_di};
    // block 5: lane-time transpose, lane bits [0, 1, 2, 3, 4] <-> cycle bits [5,10), 1 x S=32, latency 1031
    logic [61:0] b5_g0_i [0:31]; logic [61:0] b5_g0_o [0:31]; logic b5_g0_v;
    assign b5_g0_i[0] = b4_c0_y0;
    assign b5_g0_i[1] = b4_c0_y2;
    assign b5_g0_i[2] = b4_c0_y4;
    assign b5_g0_i[3] = b4_c0_y6;
    assign b5_g0_i[4] = b4_c0_y8;
    assign b5_g0_i[5] = b4_c0_y10;
    assign b5_g0_i[6] = b4_c0_y12;
    assign b5_g0_i[7] = b4_c0_y14;
    assign b5_g0_i[8] = b4_c0_y1;
    assign b5_g0_i[9] = b4_c0_y3;
    assign b5_g0_i[10] = b4_c0_y5;
    assign b5_g0_i[11] = b4_c0_y7;
    assign b5_g0_i[12] = b4_c0_y9;
    assign b5_g0_i[13] = b4_c0_y11;
    assign b5_g0_i[14] = b4_c0_y13;
    assign b5_g0_i[15] = b4_c0_y15;
    assign b5_g0_i[16] = b4_c1_y0;
    assign b5_g0_i[17] = b4_c1_y2;
    assign b5_g0_i[18] = b4_c1_y4;
    assign b5_g0_i[19] = b4_c1_y6;
    assign b5_g0_i[20] = b4_c1_y8;
    assign b5_g0_i[21] = b4_c1_y10;
    assign b5_g0_i[22] = b4_c1_y12;
    assign b5_g0_i[23] = b4_c1_y14;
    assign b5_g0_i[24] = b4_c1_y1;
    assign b5_g0_i[25] = b4_c1_y3;
    assign b5_g0_i[26] = b4_c1_y5;
    assign b5_g0_i[27] = b4_c1_y7;
    assign b5_g0_i[28] = b4_c1_y9;
    assign b5_g0_i[29] = b4_c1_y11;
    assign b5_g0_i[30] = b4_c1_y13;
    assign b5_g0_i[31] = b4_c1_y15;
    lt_bmb_transpose #(.S(32), .LO(5), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h7), .RAM_STYLE("block")) b5_g0 (.clk(clk), .rst(rst), .data_valid(b4_c0_v), .data_in(b5_g0_i), .data_out_valid(b5_g0_v), .data_out(b5_g0_o));
    logic [110:0] b5_tag;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(111), .D(1031)) b5_tag_i (.clk(clk), .din(b4_tag), .dout(b5_tag));
    // block 6: twiddle stage 2, latency 57 (tables 3, generator 27, multiplier 27)
    logic [10:0] b6_cnt;
    always_ff @(posedge clk) b6_cnt <= rst ? '0 : (b5_g0_v ? b6_cnt + 1'b1 : b6_cnt);
    logic [61:0] b6_t0;
    (* shreg_extract = "no" *) logic [61:0] b6_t0_q0;
    logic b6_t0_lwe; logic [5:0] b6_t0_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t0_lwd;
    always_ff @(posedge clk) begin b6_t0_lwe <= ld_v && ld_iq >= 11'd34 && ld_iq < 11'd38; b6_t0_lwa <= {ld_slq[2:0], ld_drq, 2'(ld_iq - 11'd34)}; b6_t0_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab0 b6_t0_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[6], b6_cnt[5]}), .we(b6_t0_lwe), .wa(b6_t0_lwa), .wcol(1'b0), .wd(b6_t0_lwd), .q0(b6_t0_q0));
    always_ff @(posedge clk) begin b6_t0 <= b6_t0_q0; end
    logic [61:0] b6_t1;
    (* shreg_extract = "no" *) logic [61:0] b6_t1_q0;
    logic b6_t1_lwe; logic [5:0] b6_t1_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t1_lwd;
    always_ff @(posedge clk) begin b6_t1_lwe <= ld_v && ld_iq >= 11'd38 && ld_iq < 11'd42; b6_t1_lwa <= {ld_slq[2:0], ld_drq, 2'(ld_iq - 11'd38)}; b6_t1_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab1 b6_t1_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[8], b6_cnt[7]}), .we(b6_t1_lwe), .wa(b6_t1_lwa), .wcol(1'b0), .wd(b6_t1_lwd), .q0(b6_t1_q0));
    always_ff @(posedge clk) begin b6_t1 <= b6_t1_q0; end
    logic [61:0] b6_t2;
    (* shreg_extract = "no" *) logic [61:0] b6_t2_q0;
    logic b6_t2_lwe; logic [6:0] b6_t2_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t2_lwd;
    always_ff @(posedge clk) begin b6_t2_lwe <= ld_v && ld_iq >= 11'd41 && ld_iq < 11'd49; b6_t2_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd41)}; b6_t2_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab2 b6_t2_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t2_lwe), .wa(b6_t2_lwa), .wcol(1'b0), .wd(b6_t2_lwd), .q0(b6_t2_q0));
    always_ff @(posedge clk) begin b6_t2 <= b6_t2_q0; end
    logic [61:0] b6_t3;
    (* shreg_extract = "no" *) logic [61:0] b6_t3_q0;
    logic b6_t3_lwe; logic [6:0] b6_t3_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t3_lwd;
    always_ff @(posedge clk) begin b6_t3_lwe <= ld_v && ld_iq >= 11'd42 && ld_iq < 11'd50; b6_t3_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd42)}; b6_t3_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab3 b6_t3_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t3_lwe), .wa(b6_t3_lwa), .wcol(1'b0), .wd(b6_t3_lwd), .q0(b6_t3_q0));
    always_ff @(posedge clk) begin b6_t3 <= b6_t3_q0; end
    logic [61:0] b6_t4;
    (* shreg_extract = "no" *) logic [61:0] b6_t4_q0;
    logic b6_t4_lwe; logic [6:0] b6_t4_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t4_lwd;
    always_ff @(posedge clk) begin b6_t4_lwe <= ld_v && ld_iq >= 11'd49 && ld_iq < 11'd57; b6_t4_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd49)}; b6_t4_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab4 b6_t4_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t4_lwe), .wa(b6_t4_lwa), .wcol(1'b0), .wd(b6_t4_lwd), .q0(b6_t4_q0));
    always_ff @(posedge clk) begin b6_t4 <= b6_t4_q0; end
    logic [61:0] b6_t5;
    (* shreg_extract = "no" *) logic [61:0] b6_t5_q0;
    logic b6_t5_lwe; logic [6:0] b6_t5_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t5_lwd;
    always_ff @(posedge clk) begin b6_t5_lwe <= ld_v && ld_iq >= 11'd50 && ld_iq < 11'd58; b6_t5_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd50)}; b6_t5_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab5 b6_t5_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t5_lwe), .wa(b6_t5_lwa), .wcol(1'b0), .wd(b6_t5_lwd), .q0(b6_t5_q0));
    always_ff @(posedge clk) begin b6_t5 <= b6_t5_q0; end
    logic [61:0] b6_t6;
    (* shreg_extract = "no" *) logic [61:0] b6_t6_q0;
    logic b6_t6_lwe; logic [6:0] b6_t6_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t6_lwd;
    always_ff @(posedge clk) begin b6_t6_lwe <= ld_v && ld_iq >= 11'd57 && ld_iq < 11'd65; b6_t6_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd57)}; b6_t6_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab6 b6_t6_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t6_lwe), .wa(b6_t6_lwa), .wcol(1'b0), .wd(b6_t6_lwd), .q0(b6_t6_q0));
    always_ff @(posedge clk) begin b6_t6 <= b6_t6_q0; end
    logic [61:0] b6_t7;
    (* shreg_extract = "no" *) logic [61:0] b6_t7_q0;
    logic b6_t7_lwe; logic [6:0] b6_t7_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t7_lwd;
    always_ff @(posedge clk) begin b6_t7_lwe <= ld_v && ld_iq >= 11'd58 && ld_iq < 11'd66; b6_t7_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd58)}; b6_t7_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab7 b6_t7_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t7_lwe), .wa(b6_t7_lwa), .wcol(1'b0), .wd(b6_t7_lwd), .q0(b6_t7_q0));
    always_ff @(posedge clk) begin b6_t7 <= b6_t7_q0; end
    logic [61:0] b6_t8;
    (* shreg_extract = "no" *) logic [61:0] b6_t8_q0;
    logic b6_t8_lwe; logic [6:0] b6_t8_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t8_lwd;
    always_ff @(posedge clk) begin b6_t8_lwe <= ld_v && ld_iq >= 11'd65 && ld_iq < 11'd73; b6_t8_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd65)}; b6_t8_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab8 b6_t8_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t8_lwe), .wa(b6_t8_lwa), .wcol(1'b0), .wd(b6_t8_lwd), .q0(b6_t8_q0));
    always_ff @(posedge clk) begin b6_t8 <= b6_t8_q0; end
    logic [61:0] b6_t9;
    (* shreg_extract = "no" *) logic [61:0] b6_t9_q0;
    logic b6_t9_lwe; logic [6:0] b6_t9_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t9_lwd;
    always_ff @(posedge clk) begin b6_t9_lwe <= ld_v && ld_iq >= 11'd66 && ld_iq < 11'd74; b6_t9_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd66)}; b6_t9_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab9 b6_t9_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t9_lwe), .wa(b6_t9_lwa), .wcol(1'b0), .wd(b6_t9_lwd), .q0(b6_t9_q0));
    always_ff @(posedge clk) begin b6_t9 <= b6_t9_q0; end
    logic [61:0] b6_t10;
    (* shreg_extract = "no" *) logic [61:0] b6_t10_q0;
    logic b6_t10_lwe; logic [6:0] b6_t10_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t10_lwd;
    always_ff @(posedge clk) begin b6_t10_lwe <= ld_v && ld_iq >= 11'd73 && ld_iq < 11'd81; b6_t10_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd73)}; b6_t10_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab10 b6_t10_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t10_lwe), .wa(b6_t10_lwa), .wcol(1'b0), .wd(b6_t10_lwd), .q0(b6_t10_q0));
    always_ff @(posedge clk) begin b6_t10 <= b6_t10_q0; end
    logic [61:0] b6_t11;
    (* shreg_extract = "no" *) logic [61:0] b6_t11_q0;
    logic b6_t11_lwe; logic [6:0] b6_t11_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t11_lwd;
    always_ff @(posedge clk) begin b6_t11_lwe <= ld_v && ld_iq >= 11'd74 && ld_iq < 11'd82; b6_t11_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd74)}; b6_t11_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab11 b6_t11_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t11_lwe), .wa(b6_t11_lwa), .wcol(1'b0), .wd(b6_t11_lwd), .q0(b6_t11_q0));
    always_ff @(posedge clk) begin b6_t11 <= b6_t11_q0; end
    logic [61:0] b6_t12;
    (* shreg_extract = "no" *) logic [61:0] b6_t12_q0;
    logic b6_t12_lwe; logic [6:0] b6_t12_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t12_lwd;
    always_ff @(posedge clk) begin b6_t12_lwe <= ld_v && ld_iq >= 11'd81 && ld_iq < 11'd89; b6_t12_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd81)}; b6_t12_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab12 b6_t12_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t12_lwe), .wa(b6_t12_lwa), .wcol(1'b0), .wd(b6_t12_lwd), .q0(b6_t12_q0));
    always_ff @(posedge clk) begin b6_t12 <= b6_t12_q0; end
    logic [61:0] b6_t13;
    (* shreg_extract = "no" *) logic [61:0] b6_t13_q0;
    logic b6_t13_lwe; logic [6:0] b6_t13_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t13_lwd;
    always_ff @(posedge clk) begin b6_t13_lwe <= ld_v && ld_iq >= 11'd82 && ld_iq < 11'd90; b6_t13_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd82)}; b6_t13_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab13 b6_t13_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t13_lwe), .wa(b6_t13_lwa), .wcol(1'b0), .wd(b6_t13_lwd), .q0(b6_t13_q0));
    always_ff @(posedge clk) begin b6_t13 <= b6_t13_q0; end
    logic [61:0] b6_t14;
    (* shreg_extract = "no" *) logic [61:0] b6_t14_q0;
    logic b6_t14_lwe; logic [6:0] b6_t14_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t14_lwd;
    always_ff @(posedge clk) begin b6_t14_lwe <= ld_v && ld_iq >= 11'd89 && ld_iq < 11'd97; b6_t14_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd89)}; b6_t14_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab14 b6_t14_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t14_lwe), .wa(b6_t14_lwa), .wcol(1'b0), .wd(b6_t14_lwd), .q0(b6_t14_q0));
    always_ff @(posedge clk) begin b6_t14 <= b6_t14_q0; end
    logic [61:0] b6_t15;
    (* shreg_extract = "no" *) logic [61:0] b6_t15_q0;
    logic b6_t15_lwe; logic [6:0] b6_t15_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t15_lwd;
    always_ff @(posedge clk) begin b6_t15_lwe <= ld_v && ld_iq >= 11'd90 && ld_iq < 11'd98; b6_t15_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd90)}; b6_t15_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab15 b6_t15_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t15_lwe), .wa(b6_t15_lwa), .wcol(1'b0), .wd(b6_t15_lwd), .q0(b6_t15_q0));
    always_ff @(posedge clk) begin b6_t15 <= b6_t15_q0; end
    logic [61:0] b6_t16;
    (* shreg_extract = "no" *) logic [61:0] b6_t16_q0;
    logic b6_t16_lwe; logic [6:0] b6_t16_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t16_lwd;
    always_ff @(posedge clk) begin b6_t16_lwe <= ld_v && ld_iq >= 11'd97 && ld_iq < 11'd105; b6_t16_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd97)}; b6_t16_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab16 b6_t16_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t16_lwe), .wa(b6_t16_lwa), .wcol(1'b0), .wd(b6_t16_lwd), .q0(b6_t16_q0));
    always_ff @(posedge clk) begin b6_t16 <= b6_t16_q0; end
    logic [61:0] b6_t17;
    (* shreg_extract = "no" *) logic [61:0] b6_t17_q0;
    logic b6_t17_lwe; logic [6:0] b6_t17_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t17_lwd;
    always_ff @(posedge clk) begin b6_t17_lwe <= ld_v && ld_iq >= 11'd98 && ld_iq < 11'd106; b6_t17_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd98)}; b6_t17_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab17 b6_t17_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t17_lwe), .wa(b6_t17_lwa), .wcol(1'b0), .wd(b6_t17_lwd), .q0(b6_t17_q0));
    always_ff @(posedge clk) begin b6_t17 <= b6_t17_q0; end
    logic [61:0] b6_t18;
    (* shreg_extract = "no" *) logic [61:0] b6_t18_q0;
    logic b6_t18_lwe; logic [6:0] b6_t18_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t18_lwd;
    always_ff @(posedge clk) begin b6_t18_lwe <= ld_v && ld_iq >= 11'd105 && ld_iq < 11'd113; b6_t18_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd105)}; b6_t18_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab18 b6_t18_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t18_lwe), .wa(b6_t18_lwa), .wcol(1'b0), .wd(b6_t18_lwd), .q0(b6_t18_q0));
    always_ff @(posedge clk) begin b6_t18 <= b6_t18_q0; end
    logic [61:0] b6_t19;
    (* shreg_extract = "no" *) logic [61:0] b6_t19_q0;
    logic b6_t19_lwe; logic [6:0] b6_t19_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t19_lwd;
    always_ff @(posedge clk) begin b6_t19_lwe <= ld_v && ld_iq >= 11'd106 && ld_iq < 11'd114; b6_t19_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd106)}; b6_t19_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab19 b6_t19_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t19_lwe), .wa(b6_t19_lwa), .wcol(1'b0), .wd(b6_t19_lwd), .q0(b6_t19_q0));
    always_ff @(posedge clk) begin b6_t19 <= b6_t19_q0; end
    logic [61:0] b6_t20;
    (* shreg_extract = "no" *) logic [61:0] b6_t20_q0;
    logic b6_t20_lwe; logic [6:0] b6_t20_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t20_lwd;
    always_ff @(posedge clk) begin b6_t20_lwe <= ld_v && ld_iq >= 11'd113 && ld_iq < 11'd121; b6_t20_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd113)}; b6_t20_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab20 b6_t20_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t20_lwe), .wa(b6_t20_lwa), .wcol(1'b0), .wd(b6_t20_lwd), .q0(b6_t20_q0));
    always_ff @(posedge clk) begin b6_t20 <= b6_t20_q0; end
    logic [61:0] b6_t21;
    (* shreg_extract = "no" *) logic [61:0] b6_t21_q0;
    logic b6_t21_lwe; logic [6:0] b6_t21_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t21_lwd;
    always_ff @(posedge clk) begin b6_t21_lwe <= ld_v && ld_iq >= 11'd114 && ld_iq < 11'd122; b6_t21_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd114)}; b6_t21_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab21 b6_t21_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t21_lwe), .wa(b6_t21_lwa), .wcol(1'b0), .wd(b6_t21_lwd), .q0(b6_t21_q0));
    always_ff @(posedge clk) begin b6_t21 <= b6_t21_q0; end
    logic [61:0] b6_t22;
    (* shreg_extract = "no" *) logic [61:0] b6_t22_q0;
    logic b6_t22_lwe; logic [6:0] b6_t22_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t22_lwd;
    always_ff @(posedge clk) begin b6_t22_lwe <= ld_v && ld_iq >= 11'd121 && ld_iq < 11'd129; b6_t22_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd121)}; b6_t22_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab22 b6_t22_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t22_lwe), .wa(b6_t22_lwa), .wcol(1'b0), .wd(b6_t22_lwd), .q0(b6_t22_q0));
    always_ff @(posedge clk) begin b6_t22 <= b6_t22_q0; end
    logic [61:0] b6_t23;
    (* shreg_extract = "no" *) logic [61:0] b6_t23_q0;
    logic b6_t23_lwe; logic [6:0] b6_t23_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t23_lwd;
    always_ff @(posedge clk) begin b6_t23_lwe <= ld_v && ld_iq >= 11'd122 && ld_iq < 11'd130; b6_t23_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd122)}; b6_t23_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab23 b6_t23_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t23_lwe), .wa(b6_t23_lwa), .wcol(1'b0), .wd(b6_t23_lwd), .q0(b6_t23_q0));
    always_ff @(posedge clk) begin b6_t23 <= b6_t23_q0; end
    logic [61:0] b6_t24;
    (* shreg_extract = "no" *) logic [61:0] b6_t24_q0;
    logic b6_t24_lwe; logic [6:0] b6_t24_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t24_lwd;
    always_ff @(posedge clk) begin b6_t24_lwe <= ld_v && ld_iq >= 11'd129 && ld_iq < 11'd137; b6_t24_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd129)}; b6_t24_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab24 b6_t24_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t24_lwe), .wa(b6_t24_lwa), .wcol(1'b0), .wd(b6_t24_lwd), .q0(b6_t24_q0));
    always_ff @(posedge clk) begin b6_t24 <= b6_t24_q0; end
    logic [61:0] b6_t25;
    (* shreg_extract = "no" *) logic [61:0] b6_t25_q0;
    logic b6_t25_lwe; logic [6:0] b6_t25_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t25_lwd;
    always_ff @(posedge clk) begin b6_t25_lwe <= ld_v && ld_iq >= 11'd130 && ld_iq < 11'd138; b6_t25_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd130)}; b6_t25_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab25 b6_t25_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t25_lwe), .wa(b6_t25_lwa), .wcol(1'b0), .wd(b6_t25_lwd), .q0(b6_t25_q0));
    always_ff @(posedge clk) begin b6_t25 <= b6_t25_q0; end
    logic [61:0] b6_t26;
    (* shreg_extract = "no" *) logic [61:0] b6_t26_q0;
    logic b6_t26_lwe; logic [6:0] b6_t26_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t26_lwd;
    always_ff @(posedge clk) begin b6_t26_lwe <= ld_v && ld_iq >= 11'd137 && ld_iq < 11'd145; b6_t26_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd137)}; b6_t26_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab26 b6_t26_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t26_lwe), .wa(b6_t26_lwa), .wcol(1'b0), .wd(b6_t26_lwd), .q0(b6_t26_q0));
    always_ff @(posedge clk) begin b6_t26 <= b6_t26_q0; end
    logic [61:0] b6_t27;
    (* shreg_extract = "no" *) logic [61:0] b6_t27_q0;
    logic b6_t27_lwe; logic [6:0] b6_t27_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t27_lwd;
    always_ff @(posedge clk) begin b6_t27_lwe <= ld_v && ld_iq >= 11'd138 && ld_iq < 11'd146; b6_t27_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd138)}; b6_t27_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab27 b6_t27_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t27_lwe), .wa(b6_t27_lwa), .wcol(1'b0), .wd(b6_t27_lwd), .q0(b6_t27_q0));
    always_ff @(posedge clk) begin b6_t27 <= b6_t27_q0; end
    logic [61:0] b6_t28;
    (* shreg_extract = "no" *) logic [61:0] b6_t28_q0;
    logic b6_t28_lwe; logic [6:0] b6_t28_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t28_lwd;
    always_ff @(posedge clk) begin b6_t28_lwe <= ld_v && ld_iq >= 11'd145 && ld_iq < 11'd153; b6_t28_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd145)}; b6_t28_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab28 b6_t28_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t28_lwe), .wa(b6_t28_lwa), .wcol(1'b0), .wd(b6_t28_lwd), .q0(b6_t28_q0));
    always_ff @(posedge clk) begin b6_t28 <= b6_t28_q0; end
    logic [61:0] b6_t29;
    (* shreg_extract = "no" *) logic [61:0] b6_t29_q0;
    logic b6_t29_lwe; logic [6:0] b6_t29_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t29_lwd;
    always_ff @(posedge clk) begin b6_t29_lwe <= ld_v && ld_iq >= 11'd146 && ld_iq < 11'd154; b6_t29_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd146)}; b6_t29_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab29 b6_t29_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t29_lwe), .wa(b6_t29_lwa), .wcol(1'b0), .wd(b6_t29_lwd), .q0(b6_t29_q0));
    always_ff @(posedge clk) begin b6_t29 <= b6_t29_q0; end
    logic [61:0] b6_t30;
    (* shreg_extract = "no" *) logic [61:0] b6_t30_q0;
    logic b6_t30_lwe; logic [6:0] b6_t30_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t30_lwd;
    always_ff @(posedge clk) begin b6_t30_lwe <= ld_v && ld_iq >= 11'd153 && ld_iq < 11'd161; b6_t30_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd153)}; b6_t30_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab30 b6_t30_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t30_lwe), .wa(b6_t30_lwa), .wcol(1'b0), .wd(b6_t30_lwd), .q0(b6_t30_q0));
    always_ff @(posedge clk) begin b6_t30 <= b6_t30_q0; end
    logic [61:0] b6_t31;
    (* shreg_extract = "no" *) logic [61:0] b6_t31_q0;
    logic b6_t31_lwe; logic [6:0] b6_t31_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t31_lwd;
    always_ff @(posedge clk) begin b6_t31_lwe <= ld_v && ld_iq >= 11'd154 && ld_iq < 11'd162; b6_t31_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd154)}; b6_t31_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab31 b6_t31_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t31_lwe), .wa(b6_t31_lwa), .wcol(1'b0), .wd(b6_t31_lwd), .q0(b6_t31_q0));
    always_ff @(posedge clk) begin b6_t31 <= b6_t31_q0; end
    logic [61:0] b6_t32;
    (* shreg_extract = "no" *) logic [61:0] b6_t32_q0;
    logic b6_t32_lwe; logic [6:0] b6_t32_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t32_lwd;
    always_ff @(posedge clk) begin b6_t32_lwe <= ld_v && ld_iq >= 11'd161 && ld_iq < 11'd169; b6_t32_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd161)}; b6_t32_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab32 b6_t32_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t32_lwe), .wa(b6_t32_lwa), .wcol(1'b0), .wd(b6_t32_lwd), .q0(b6_t32_q0));
    always_ff @(posedge clk) begin b6_t32 <= b6_t32_q0; end
    logic [61:0] b6_t33;
    (* shreg_extract = "no" *) logic [61:0] b6_t33_q0;
    logic b6_t33_lwe; logic [6:0] b6_t33_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t33_lwd;
    always_ff @(posedge clk) begin b6_t33_lwe <= ld_v && ld_iq >= 11'd162 && ld_iq < 11'd170; b6_t33_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd162)}; b6_t33_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab33 b6_t33_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t33_lwe), .wa(b6_t33_lwa), .wcol(1'b0), .wd(b6_t33_lwd), .q0(b6_t33_q0));
    always_ff @(posedge clk) begin b6_t33 <= b6_t33_q0; end
    logic [61:0] b6_t34;
    (* shreg_extract = "no" *) logic [61:0] b6_t34_q0;
    logic b6_t34_lwe; logic [6:0] b6_t34_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t34_lwd;
    always_ff @(posedge clk) begin b6_t34_lwe <= ld_v && ld_iq >= 11'd169 && ld_iq < 11'd177; b6_t34_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd169)}; b6_t34_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab34 b6_t34_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t34_lwe), .wa(b6_t34_lwa), .wcol(1'b0), .wd(b6_t34_lwd), .q0(b6_t34_q0));
    always_ff @(posedge clk) begin b6_t34 <= b6_t34_q0; end
    logic [61:0] b6_t35;
    (* shreg_extract = "no" *) logic [61:0] b6_t35_q0;
    logic b6_t35_lwe; logic [6:0] b6_t35_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t35_lwd;
    always_ff @(posedge clk) begin b6_t35_lwe <= ld_v && ld_iq >= 11'd170 && ld_iq < 11'd178; b6_t35_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd170)}; b6_t35_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab35 b6_t35_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t35_lwe), .wa(b6_t35_lwa), .wcol(1'b0), .wd(b6_t35_lwd), .q0(b6_t35_q0));
    always_ff @(posedge clk) begin b6_t35 <= b6_t35_q0; end
    logic [61:0] b6_t36;
    (* shreg_extract = "no" *) logic [61:0] b6_t36_q0;
    logic b6_t36_lwe; logic [6:0] b6_t36_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t36_lwd;
    always_ff @(posedge clk) begin b6_t36_lwe <= ld_v && ld_iq >= 11'd177 && ld_iq < 11'd185; b6_t36_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd177)}; b6_t36_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab36 b6_t36_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t36_lwe), .wa(b6_t36_lwa), .wcol(1'b0), .wd(b6_t36_lwd), .q0(b6_t36_q0));
    always_ff @(posedge clk) begin b6_t36 <= b6_t36_q0; end
    logic [61:0] b6_t37;
    (* shreg_extract = "no" *) logic [61:0] b6_t37_q0;
    logic b6_t37_lwe; logic [6:0] b6_t37_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t37_lwd;
    always_ff @(posedge clk) begin b6_t37_lwe <= ld_v && ld_iq >= 11'd178 && ld_iq < 11'd186; b6_t37_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd178)}; b6_t37_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab37 b6_t37_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t37_lwe), .wa(b6_t37_lwa), .wcol(1'b0), .wd(b6_t37_lwd), .q0(b6_t37_q0));
    always_ff @(posedge clk) begin b6_t37 <= b6_t37_q0; end
    logic [61:0] b6_t38;
    (* shreg_extract = "no" *) logic [61:0] b6_t38_q0;
    logic b6_t38_lwe; logic [6:0] b6_t38_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t38_lwd;
    always_ff @(posedge clk) begin b6_t38_lwe <= ld_v && ld_iq >= 11'd185 && ld_iq < 11'd193; b6_t38_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd185)}; b6_t38_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab38 b6_t38_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t38_lwe), .wa(b6_t38_lwa), .wcol(1'b0), .wd(b6_t38_lwd), .q0(b6_t38_q0));
    always_ff @(posedge clk) begin b6_t38 <= b6_t38_q0; end
    logic [61:0] b6_t39;
    (* shreg_extract = "no" *) logic [61:0] b6_t39_q0;
    logic b6_t39_lwe; logic [6:0] b6_t39_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t39_lwd;
    always_ff @(posedge clk) begin b6_t39_lwe <= ld_v && ld_iq >= 11'd186 && ld_iq < 11'd194; b6_t39_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd186)}; b6_t39_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab39 b6_t39_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t39_lwe), .wa(b6_t39_lwa), .wcol(1'b0), .wd(b6_t39_lwd), .q0(b6_t39_q0));
    always_ff @(posedge clk) begin b6_t39 <= b6_t39_q0; end
    logic [61:0] b6_t40;
    (* shreg_extract = "no" *) logic [61:0] b6_t40_q0;
    logic b6_t40_lwe; logic [6:0] b6_t40_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t40_lwd;
    always_ff @(posedge clk) begin b6_t40_lwe <= ld_v && ld_iq >= 11'd193 && ld_iq < 11'd201; b6_t40_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd193)}; b6_t40_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab40 b6_t40_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t40_lwe), .wa(b6_t40_lwa), .wcol(1'b0), .wd(b6_t40_lwd), .q0(b6_t40_q0));
    always_ff @(posedge clk) begin b6_t40 <= b6_t40_q0; end
    logic [61:0] b6_t41;
    (* shreg_extract = "no" *) logic [61:0] b6_t41_q0;
    logic b6_t41_lwe; logic [6:0] b6_t41_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t41_lwd;
    always_ff @(posedge clk) begin b6_t41_lwe <= ld_v && ld_iq >= 11'd194 && ld_iq < 11'd202; b6_t41_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd194)}; b6_t41_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab41 b6_t41_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t41_lwe), .wa(b6_t41_lwa), .wcol(1'b0), .wd(b6_t41_lwd), .q0(b6_t41_q0));
    always_ff @(posedge clk) begin b6_t41 <= b6_t41_q0; end
    logic [61:0] b6_t42;
    (* shreg_extract = "no" *) logic [61:0] b6_t42_q0;
    logic b6_t42_lwe; logic [6:0] b6_t42_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t42_lwd;
    always_ff @(posedge clk) begin b6_t42_lwe <= ld_v && ld_iq >= 11'd201 && ld_iq < 11'd209; b6_t42_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd201)}; b6_t42_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab42 b6_t42_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t42_lwe), .wa(b6_t42_lwa), .wcol(1'b0), .wd(b6_t42_lwd), .q0(b6_t42_q0));
    always_ff @(posedge clk) begin b6_t42 <= b6_t42_q0; end
    logic [61:0] b6_t43;
    (* shreg_extract = "no" *) logic [61:0] b6_t43_q0;
    logic b6_t43_lwe; logic [6:0] b6_t43_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t43_lwd;
    always_ff @(posedge clk) begin b6_t43_lwe <= ld_v && ld_iq >= 11'd202 && ld_iq < 11'd210; b6_t43_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd202)}; b6_t43_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab43 b6_t43_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t43_lwe), .wa(b6_t43_lwa), .wcol(1'b0), .wd(b6_t43_lwd), .q0(b6_t43_q0));
    always_ff @(posedge clk) begin b6_t43 <= b6_t43_q0; end
    logic [61:0] b6_t44;
    (* shreg_extract = "no" *) logic [61:0] b6_t44_q0;
    logic b6_t44_lwe; logic [6:0] b6_t44_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t44_lwd;
    always_ff @(posedge clk) begin b6_t44_lwe <= ld_v && ld_iq >= 11'd209 && ld_iq < 11'd217; b6_t44_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd209)}; b6_t44_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab44 b6_t44_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t44_lwe), .wa(b6_t44_lwa), .wcol(1'b0), .wd(b6_t44_lwd), .q0(b6_t44_q0));
    always_ff @(posedge clk) begin b6_t44 <= b6_t44_q0; end
    logic [61:0] b6_t45;
    (* shreg_extract = "no" *) logic [61:0] b6_t45_q0;
    logic b6_t45_lwe; logic [6:0] b6_t45_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t45_lwd;
    always_ff @(posedge clk) begin b6_t45_lwe <= ld_v && ld_iq >= 11'd210 && ld_iq < 11'd218; b6_t45_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd210)}; b6_t45_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab45 b6_t45_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t45_lwe), .wa(b6_t45_lwa), .wcol(1'b0), .wd(b6_t45_lwd), .q0(b6_t45_q0));
    always_ff @(posedge clk) begin b6_t45 <= b6_t45_q0; end
    logic [61:0] b6_t46;
    (* shreg_extract = "no" *) logic [61:0] b6_t46_q0;
    logic b6_t46_lwe; logic [6:0] b6_t46_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t46_lwd;
    always_ff @(posedge clk) begin b6_t46_lwe <= ld_v && ld_iq >= 11'd217 && ld_iq < 11'd225; b6_t46_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd217)}; b6_t46_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab46 b6_t46_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t46_lwe), .wa(b6_t46_lwa), .wcol(1'b0), .wd(b6_t46_lwd), .q0(b6_t46_q0));
    always_ff @(posedge clk) begin b6_t46 <= b6_t46_q0; end
    logic [61:0] b6_t47;
    (* shreg_extract = "no" *) logic [61:0] b6_t47_q0;
    logic b6_t47_lwe; logic [6:0] b6_t47_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t47_lwd;
    always_ff @(posedge clk) begin b6_t47_lwe <= ld_v && ld_iq >= 11'd218 && ld_iq < 11'd226; b6_t47_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd218)}; b6_t47_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab47 b6_t47_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t47_lwe), .wa(b6_t47_lwa), .wcol(1'b0), .wd(b6_t47_lwd), .q0(b6_t47_q0));
    always_ff @(posedge clk) begin b6_t47 <= b6_t47_q0; end
    logic [61:0] b6_t48;
    (* shreg_extract = "no" *) logic [61:0] b6_t48_q0;
    logic b6_t48_lwe; logic [6:0] b6_t48_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t48_lwd;
    always_ff @(posedge clk) begin b6_t48_lwe <= ld_v && ld_iq >= 11'd225 && ld_iq < 11'd233; b6_t48_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd225)}; b6_t48_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab48 b6_t48_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t48_lwe), .wa(b6_t48_lwa), .wcol(1'b0), .wd(b6_t48_lwd), .q0(b6_t48_q0));
    always_ff @(posedge clk) begin b6_t48 <= b6_t48_q0; end
    logic [61:0] b6_t49;
    (* shreg_extract = "no" *) logic [61:0] b6_t49_q0;
    logic b6_t49_lwe; logic [6:0] b6_t49_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t49_lwd;
    always_ff @(posedge clk) begin b6_t49_lwe <= ld_v && ld_iq >= 11'd226 && ld_iq < 11'd234; b6_t49_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd226)}; b6_t49_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab49 b6_t49_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t49_lwe), .wa(b6_t49_lwa), .wcol(1'b0), .wd(b6_t49_lwd), .q0(b6_t49_q0));
    always_ff @(posedge clk) begin b6_t49 <= b6_t49_q0; end
    logic [61:0] b6_t50;
    (* shreg_extract = "no" *) logic [61:0] b6_t50_q0;
    logic b6_t50_lwe; logic [6:0] b6_t50_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t50_lwd;
    always_ff @(posedge clk) begin b6_t50_lwe <= ld_v && ld_iq >= 11'd233 && ld_iq < 11'd241; b6_t50_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd233)}; b6_t50_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab50 b6_t50_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t50_lwe), .wa(b6_t50_lwa), .wcol(1'b0), .wd(b6_t50_lwd), .q0(b6_t50_q0));
    always_ff @(posedge clk) begin b6_t50 <= b6_t50_q0; end
    logic [61:0] b6_t51;
    (* shreg_extract = "no" *) logic [61:0] b6_t51_q0;
    logic b6_t51_lwe; logic [6:0] b6_t51_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t51_lwd;
    always_ff @(posedge clk) begin b6_t51_lwe <= ld_v && ld_iq >= 11'd234 && ld_iq < 11'd242; b6_t51_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd234)}; b6_t51_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab51 b6_t51_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t51_lwe), .wa(b6_t51_lwa), .wcol(1'b0), .wd(b6_t51_lwd), .q0(b6_t51_q0));
    always_ff @(posedge clk) begin b6_t51 <= b6_t51_q0; end
    logic [61:0] b6_t52;
    (* shreg_extract = "no" *) logic [61:0] b6_t52_q0;
    logic b6_t52_lwe; logic [6:0] b6_t52_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t52_lwd;
    always_ff @(posedge clk) begin b6_t52_lwe <= ld_v && ld_iq >= 11'd241 && ld_iq < 11'd249; b6_t52_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd241)}; b6_t52_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab52 b6_t52_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t52_lwe), .wa(b6_t52_lwa), .wcol(1'b0), .wd(b6_t52_lwd), .q0(b6_t52_q0));
    always_ff @(posedge clk) begin b6_t52 <= b6_t52_q0; end
    logic [61:0] b6_t53;
    (* shreg_extract = "no" *) logic [61:0] b6_t53_q0;
    logic b6_t53_lwe; logic [6:0] b6_t53_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t53_lwd;
    always_ff @(posedge clk) begin b6_t53_lwe <= ld_v && ld_iq >= 11'd242 && ld_iq < 11'd250; b6_t53_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd242)}; b6_t53_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab53 b6_t53_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t53_lwe), .wa(b6_t53_lwa), .wcol(1'b0), .wd(b6_t53_lwd), .q0(b6_t53_q0));
    always_ff @(posedge clk) begin b6_t53 <= b6_t53_q0; end
    logic [61:0] b6_t54;
    (* shreg_extract = "no" *) logic [61:0] b6_t54_q0;
    logic b6_t54_lwe; logic [6:0] b6_t54_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t54_lwd;
    always_ff @(posedge clk) begin b6_t54_lwe <= ld_v && ld_iq >= 11'd249 && ld_iq < 11'd257; b6_t54_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd249)}; b6_t54_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab54 b6_t54_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t54_lwe), .wa(b6_t54_lwa), .wcol(1'b0), .wd(b6_t54_lwd), .q0(b6_t54_q0));
    always_ff @(posedge clk) begin b6_t54 <= b6_t54_q0; end
    logic [61:0] b6_t55;
    (* shreg_extract = "no" *) logic [61:0] b6_t55_q0;
    logic b6_t55_lwe; logic [6:0] b6_t55_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t55_lwd;
    always_ff @(posedge clk) begin b6_t55_lwe <= ld_v && ld_iq >= 11'd250 && ld_iq < 11'd258; b6_t55_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd250)}; b6_t55_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab55 b6_t55_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t55_lwe), .wa(b6_t55_lwa), .wcol(1'b0), .wd(b6_t55_lwd), .q0(b6_t55_q0));
    always_ff @(posedge clk) begin b6_t55 <= b6_t55_q0; end
    logic [61:0] b6_t56;
    (* shreg_extract = "no" *) logic [61:0] b6_t56_q0;
    logic b6_t56_lwe; logic [6:0] b6_t56_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t56_lwd;
    always_ff @(posedge clk) begin b6_t56_lwe <= ld_v && ld_iq >= 11'd257 && ld_iq < 11'd265; b6_t56_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd257)}; b6_t56_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab56 b6_t56_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t56_lwe), .wa(b6_t56_lwa), .wcol(1'b0), .wd(b6_t56_lwd), .q0(b6_t56_q0));
    always_ff @(posedge clk) begin b6_t56 <= b6_t56_q0; end
    logic [61:0] b6_t57;
    (* shreg_extract = "no" *) logic [61:0] b6_t57_q0;
    logic b6_t57_lwe; logic [6:0] b6_t57_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t57_lwd;
    always_ff @(posedge clk) begin b6_t57_lwe <= ld_v && ld_iq >= 11'd258 && ld_iq < 11'd266; b6_t57_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd258)}; b6_t57_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab57 b6_t57_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t57_lwe), .wa(b6_t57_lwa), .wcol(1'b0), .wd(b6_t57_lwd), .q0(b6_t57_q0));
    always_ff @(posedge clk) begin b6_t57 <= b6_t57_q0; end
    logic [61:0] b6_t58;
    (* shreg_extract = "no" *) logic [61:0] b6_t58_q0;
    logic b6_t58_lwe; logic [6:0] b6_t58_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t58_lwd;
    always_ff @(posedge clk) begin b6_t58_lwe <= ld_v && ld_iq >= 11'd265 && ld_iq < 11'd273; b6_t58_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd265)}; b6_t58_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab58 b6_t58_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t58_lwe), .wa(b6_t58_lwa), .wcol(1'b0), .wd(b6_t58_lwd), .q0(b6_t58_q0));
    always_ff @(posedge clk) begin b6_t58 <= b6_t58_q0; end
    logic [61:0] b6_t59;
    (* shreg_extract = "no" *) logic [61:0] b6_t59_q0;
    logic b6_t59_lwe; logic [6:0] b6_t59_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t59_lwd;
    always_ff @(posedge clk) begin b6_t59_lwe <= ld_v && ld_iq >= 11'd266 && ld_iq < 11'd274; b6_t59_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd266)}; b6_t59_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab59 b6_t59_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t59_lwe), .wa(b6_t59_lwa), .wcol(1'b0), .wd(b6_t59_lwd), .q0(b6_t59_q0));
    always_ff @(posedge clk) begin b6_t59 <= b6_t59_q0; end
    logic [61:0] b6_t60;
    (* shreg_extract = "no" *) logic [61:0] b6_t60_q0;
    logic b6_t60_lwe; logic [6:0] b6_t60_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t60_lwd;
    always_ff @(posedge clk) begin b6_t60_lwe <= ld_v && ld_iq >= 11'd273 && ld_iq < 11'd281; b6_t60_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd273)}; b6_t60_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab60 b6_t60_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t60_lwe), .wa(b6_t60_lwa), .wcol(1'b0), .wd(b6_t60_lwd), .q0(b6_t60_q0));
    always_ff @(posedge clk) begin b6_t60 <= b6_t60_q0; end
    logic [61:0] b6_t61;
    (* shreg_extract = "no" *) logic [61:0] b6_t61_q0;
    logic b6_t61_lwe; logic [6:0] b6_t61_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t61_lwd;
    always_ff @(posedge clk) begin b6_t61_lwe <= ld_v && ld_iq >= 11'd274 && ld_iq < 11'd282; b6_t61_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd274)}; b6_t61_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab61 b6_t61_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t61_lwe), .wa(b6_t61_lwa), .wcol(1'b0), .wd(b6_t61_lwd), .q0(b6_t61_q0));
    always_ff @(posedge clk) begin b6_t61 <= b6_t61_q0; end
    logic [61:0] b6_t62;
    (* shreg_extract = "no" *) logic [61:0] b6_t62_q0;
    logic b6_t62_lwe; logic [6:0] b6_t62_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t62_lwd;
    always_ff @(posedge clk) begin b6_t62_lwe <= ld_v && ld_iq >= 11'd281 && ld_iq < 11'd289; b6_t62_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd281)}; b6_t62_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab62 b6_t62_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[7], b6_cnt[6], b6_cnt[5]}), .we(b6_t62_lwe), .wa(b6_t62_lwa), .wcol(1'b0), .wd(b6_t62_lwd), .q0(b6_t62_q0));
    always_ff @(posedge clk) begin b6_t62 <= b6_t62_q0; end
    logic [61:0] b6_t63;
    (* shreg_extract = "no" *) logic [61:0] b6_t63_q0;
    logic b6_t63_lwe; logic [6:0] b6_t63_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b6_t63_lwd;
    always_ff @(posedge clk) begin b6_t63_lwe <= ld_v && ld_iq >= 11'd282 && ld_iq < 11'd290; b6_t63_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd282)}; b6_t63_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw2_tab63 b6_t63_i (.clk(clk), .addr({b5_tag[3:1], b5_tag[0], b6_cnt[10], b6_cnt[9], b6_cnt[8]}), .we(b6_t63_lwe), .wa(b6_t63_lwa), .wcol(1'b0), .wd(b6_t63_lwd), .q0(b6_t63_q0));
    always_ff @(posedge clk) begin b6_t63 <= b6_t63_q0; end
    logic [61:0] b6_l0_w;
    logic [44:0] b6_gq3_0_QH_c; assign b6_gq3_0_QH_c = b5_tag[48:4];
    logic [44:0] b6_gq3_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(45), .D(2)) b6_gq3_0_QH_i (.clk(clk), .din(b6_gq3_0_QH_c), .dout(b6_gq3_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b6_gq3_s0_QH;
    always_ff @(posedge clk) b6_gq3_s0_QH <= b6_gq3_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l0_gen (.clk(clk), .A(b6_t0), .B(b6_t1), .QH(b6_gq3_s0_QH), .P(b6_l0_w));
    logic [61:0] b6_l0_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l0_a_i (.clk(clk), .din(b5_g0_o[0]), .dout(b6_l0_a));
    logic [44:0] b6_mq30_0_QH_c; assign b6_mq30_0_QH_c = b5_tag[48:4];
    logic [44:0] b6_mq30_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(45), .D(29)) b6_mq30_0_QH_i (.clk(clk), .din(b6_mq30_0_QH_c), .dout(b6_mq30_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b6_mq30_s0_QH;
    always_ff @(posedge clk) b6_mq30_s0_QH <= b6_mq30_0_QH;
    logic [61:0] b6_l0_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l0_mul (.clk(clk), .A(b6_l0_a), .B(b6_l0_w), .QH(b6_mq30_s0_QH), .P(b6_l0_p));
    logic [61:0] b6_l1_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l1_gen (.clk(clk), .A(b6_t2), .B(b6_t3), .QH(b6_gq3_s0_QH), .P(b6_l1_w));
    logic [61:0] b6_l1_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l1_a_i (.clk(clk), .din(b5_g0_o[1]), .dout(b6_l1_a));
    logic [61:0] b6_l1_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l1_mul (.clk(clk), .A(b6_l1_a), .B(b6_l1_w), .QH(b6_mq30_s0_QH), .P(b6_l1_p));
    logic [61:0] b6_l2_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l2_gen (.clk(clk), .A(b6_t4), .B(b6_t5), .QH(b6_gq3_s0_QH), .P(b6_l2_w));
    logic [61:0] b6_l2_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l2_a_i (.clk(clk), .din(b5_g0_o[2]), .dout(b6_l2_a));
    logic [61:0] b6_l2_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l2_mul (.clk(clk), .A(b6_l2_a), .B(b6_l2_w), .QH(b6_mq30_s0_QH), .P(b6_l2_p));
    logic [61:0] b6_l3_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l3_gen (.clk(clk), .A(b6_t6), .B(b6_t7), .QH(b6_gq3_s0_QH), .P(b6_l3_w));
    logic [61:0] b6_l3_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l3_a_i (.clk(clk), .din(b5_g0_o[3]), .dout(b6_l3_a));
    logic [61:0] b6_l3_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l3_mul (.clk(clk), .A(b6_l3_a), .B(b6_l3_w), .QH(b6_mq30_s0_QH), .P(b6_l3_p));
    logic [61:0] b6_l4_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b6_gq3_s1_QH;
    always_ff @(posedge clk) b6_gq3_s1_QH <= b6_gq3_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l4_gen (.clk(clk), .A(b6_t8), .B(b6_t9), .QH(b6_gq3_s1_QH), .P(b6_l4_w));
    logic [61:0] b6_l4_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l4_a_i (.clk(clk), .din(b5_g0_o[4]), .dout(b6_l4_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b6_mq30_s1_QH;
    always_ff @(posedge clk) b6_mq30_s1_QH <= b6_mq30_0_QH;
    logic [61:0] b6_l4_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l4_mul (.clk(clk), .A(b6_l4_a), .B(b6_l4_w), .QH(b6_mq30_s1_QH), .P(b6_l4_p));
    logic [61:0] b6_l5_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l5_gen (.clk(clk), .A(b6_t10), .B(b6_t11), .QH(b6_gq3_s1_QH), .P(b6_l5_w));
    logic [61:0] b6_l5_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l5_a_i (.clk(clk), .din(b5_g0_o[5]), .dout(b6_l5_a));
    logic [61:0] b6_l5_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l5_mul (.clk(clk), .A(b6_l5_a), .B(b6_l5_w), .QH(b6_mq30_s1_QH), .P(b6_l5_p));
    logic [61:0] b6_l6_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l6_gen (.clk(clk), .A(b6_t12), .B(b6_t13), .QH(b6_gq3_s1_QH), .P(b6_l6_w));
    logic [61:0] b6_l6_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l6_a_i (.clk(clk), .din(b5_g0_o[6]), .dout(b6_l6_a));
    logic [61:0] b6_l6_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l6_mul (.clk(clk), .A(b6_l6_a), .B(b6_l6_w), .QH(b6_mq30_s1_QH), .P(b6_l6_p));
    logic [61:0] b6_l7_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l7_gen (.clk(clk), .A(b6_t14), .B(b6_t15), .QH(b6_gq3_s1_QH), .P(b6_l7_w));
    logic [61:0] b6_l7_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l7_a_i (.clk(clk), .din(b5_g0_o[7]), .dout(b6_l7_a));
    logic [61:0] b6_l7_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l7_mul (.clk(clk), .A(b6_l7_a), .B(b6_l7_w), .QH(b6_mq30_s1_QH), .P(b6_l7_p));
    logic [61:0] b6_l8_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b6_gq3_s2_QH;
    always_ff @(posedge clk) b6_gq3_s2_QH <= b6_gq3_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l8_gen (.clk(clk), .A(b6_t16), .B(b6_t17), .QH(b6_gq3_s2_QH), .P(b6_l8_w));
    logic [61:0] b6_l8_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l8_a_i (.clk(clk), .din(b5_g0_o[8]), .dout(b6_l8_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b6_mq30_s2_QH;
    always_ff @(posedge clk) b6_mq30_s2_QH <= b6_mq30_0_QH;
    logic [61:0] b6_l8_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l8_mul (.clk(clk), .A(b6_l8_a), .B(b6_l8_w), .QH(b6_mq30_s2_QH), .P(b6_l8_p));
    logic [61:0] b6_l9_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l9_gen (.clk(clk), .A(b6_t18), .B(b6_t19), .QH(b6_gq3_s2_QH), .P(b6_l9_w));
    logic [61:0] b6_l9_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l9_a_i (.clk(clk), .din(b5_g0_o[9]), .dout(b6_l9_a));
    logic [61:0] b6_l9_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l9_mul (.clk(clk), .A(b6_l9_a), .B(b6_l9_w), .QH(b6_mq30_s2_QH), .P(b6_l9_p));
    logic [61:0] b6_l10_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l10_gen (.clk(clk), .A(b6_t20), .B(b6_t21), .QH(b6_gq3_s2_QH), .P(b6_l10_w));
    logic [61:0] b6_l10_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l10_a_i (.clk(clk), .din(b5_g0_o[10]), .dout(b6_l10_a));
    logic [61:0] b6_l10_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l10_mul (.clk(clk), .A(b6_l10_a), .B(b6_l10_w), .QH(b6_mq30_s2_QH), .P(b6_l10_p));
    logic [61:0] b6_l11_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l11_gen (.clk(clk), .A(b6_t22), .B(b6_t23), .QH(b6_gq3_s2_QH), .P(b6_l11_w));
    logic [61:0] b6_l11_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l11_a_i (.clk(clk), .din(b5_g0_o[11]), .dout(b6_l11_a));
    logic [61:0] b6_l11_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l11_mul (.clk(clk), .A(b6_l11_a), .B(b6_l11_w), .QH(b6_mq30_s2_QH), .P(b6_l11_p));
    logic [61:0] b6_l12_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b6_gq3_s3_QH;
    always_ff @(posedge clk) b6_gq3_s3_QH <= b6_gq3_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l12_gen (.clk(clk), .A(b6_t24), .B(b6_t25), .QH(b6_gq3_s3_QH), .P(b6_l12_w));
    logic [61:0] b6_l12_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l12_a_i (.clk(clk), .din(b5_g0_o[12]), .dout(b6_l12_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b6_mq30_s3_QH;
    always_ff @(posedge clk) b6_mq30_s3_QH <= b6_mq30_0_QH;
    logic [61:0] b6_l12_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l12_mul (.clk(clk), .A(b6_l12_a), .B(b6_l12_w), .QH(b6_mq30_s3_QH), .P(b6_l12_p));
    logic [61:0] b6_l13_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l13_gen (.clk(clk), .A(b6_t26), .B(b6_t27), .QH(b6_gq3_s3_QH), .P(b6_l13_w));
    logic [61:0] b6_l13_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l13_a_i (.clk(clk), .din(b5_g0_o[13]), .dout(b6_l13_a));
    logic [61:0] b6_l13_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l13_mul (.clk(clk), .A(b6_l13_a), .B(b6_l13_w), .QH(b6_mq30_s3_QH), .P(b6_l13_p));
    logic [61:0] b6_l14_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l14_gen (.clk(clk), .A(b6_t28), .B(b6_t29), .QH(b6_gq3_s3_QH), .P(b6_l14_w));
    logic [61:0] b6_l14_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l14_a_i (.clk(clk), .din(b5_g0_o[14]), .dout(b6_l14_a));
    logic [61:0] b6_l14_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l14_mul (.clk(clk), .A(b6_l14_a), .B(b6_l14_w), .QH(b6_mq30_s3_QH), .P(b6_l14_p));
    logic [61:0] b6_l15_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l15_gen (.clk(clk), .A(b6_t30), .B(b6_t31), .QH(b6_gq3_s3_QH), .P(b6_l15_w));
    logic [61:0] b6_l15_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l15_a_i (.clk(clk), .din(b5_g0_o[15]), .dout(b6_l15_a));
    logic [61:0] b6_l15_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l15_mul (.clk(clk), .A(b6_l15_a), .B(b6_l15_w), .QH(b6_mq30_s3_QH), .P(b6_l15_p));
    logic [61:0] b6_l16_w;
    logic [44:0] b6_gq3_1_QH_c; assign b6_gq3_1_QH_c = b5_tag[48:4];
    logic [44:0] b6_gq3_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(45), .D(2)) b6_gq3_1_QH_i (.clk(clk), .din(b6_gq3_1_QH_c), .dout(b6_gq3_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b6_gq3_s4_QH;
    always_ff @(posedge clk) b6_gq3_s4_QH <= b6_gq3_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l16_gen (.clk(clk), .A(b6_t32), .B(b6_t33), .QH(b6_gq3_s4_QH), .P(b6_l16_w));
    logic [61:0] b6_l16_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l16_a_i (.clk(clk), .din(b5_g0_o[16]), .dout(b6_l16_a));
    logic [44:0] b6_mq30_1_QH_c; assign b6_mq30_1_QH_c = b5_tag[48:4];
    logic [44:0] b6_mq30_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(45), .D(29)) b6_mq30_1_QH_i (.clk(clk), .din(b6_mq30_1_QH_c), .dout(b6_mq30_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b6_mq30_s4_QH;
    always_ff @(posedge clk) b6_mq30_s4_QH <= b6_mq30_1_QH;
    logic [61:0] b6_l16_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l16_mul (.clk(clk), .A(b6_l16_a), .B(b6_l16_w), .QH(b6_mq30_s4_QH), .P(b6_l16_p));
    logic [61:0] b6_l17_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l17_gen (.clk(clk), .A(b6_t34), .B(b6_t35), .QH(b6_gq3_s4_QH), .P(b6_l17_w));
    logic [61:0] b6_l17_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l17_a_i (.clk(clk), .din(b5_g0_o[17]), .dout(b6_l17_a));
    logic [61:0] b6_l17_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l17_mul (.clk(clk), .A(b6_l17_a), .B(b6_l17_w), .QH(b6_mq30_s4_QH), .P(b6_l17_p));
    logic [61:0] b6_l18_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l18_gen (.clk(clk), .A(b6_t36), .B(b6_t37), .QH(b6_gq3_s4_QH), .P(b6_l18_w));
    logic [61:0] b6_l18_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l18_a_i (.clk(clk), .din(b5_g0_o[18]), .dout(b6_l18_a));
    logic [61:0] b6_l18_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l18_mul (.clk(clk), .A(b6_l18_a), .B(b6_l18_w), .QH(b6_mq30_s4_QH), .P(b6_l18_p));
    logic [61:0] b6_l19_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l19_gen (.clk(clk), .A(b6_t38), .B(b6_t39), .QH(b6_gq3_s4_QH), .P(b6_l19_w));
    logic [61:0] b6_l19_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l19_a_i (.clk(clk), .din(b5_g0_o[19]), .dout(b6_l19_a));
    logic [61:0] b6_l19_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l19_mul (.clk(clk), .A(b6_l19_a), .B(b6_l19_w), .QH(b6_mq30_s4_QH), .P(b6_l19_p));
    logic [61:0] b6_l20_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b6_gq3_s5_QH;
    always_ff @(posedge clk) b6_gq3_s5_QH <= b6_gq3_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l20_gen (.clk(clk), .A(b6_t40), .B(b6_t41), .QH(b6_gq3_s5_QH), .P(b6_l20_w));
    logic [61:0] b6_l20_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l20_a_i (.clk(clk), .din(b5_g0_o[20]), .dout(b6_l20_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b6_mq30_s5_QH;
    always_ff @(posedge clk) b6_mq30_s5_QH <= b6_mq30_1_QH;
    logic [61:0] b6_l20_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l20_mul (.clk(clk), .A(b6_l20_a), .B(b6_l20_w), .QH(b6_mq30_s5_QH), .P(b6_l20_p));
    logic [61:0] b6_l21_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l21_gen (.clk(clk), .A(b6_t42), .B(b6_t43), .QH(b6_gq3_s5_QH), .P(b6_l21_w));
    logic [61:0] b6_l21_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l21_a_i (.clk(clk), .din(b5_g0_o[21]), .dout(b6_l21_a));
    logic [61:0] b6_l21_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l21_mul (.clk(clk), .A(b6_l21_a), .B(b6_l21_w), .QH(b6_mq30_s5_QH), .P(b6_l21_p));
    logic [61:0] b6_l22_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l22_gen (.clk(clk), .A(b6_t44), .B(b6_t45), .QH(b6_gq3_s5_QH), .P(b6_l22_w));
    logic [61:0] b6_l22_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l22_a_i (.clk(clk), .din(b5_g0_o[22]), .dout(b6_l22_a));
    logic [61:0] b6_l22_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l22_mul (.clk(clk), .A(b6_l22_a), .B(b6_l22_w), .QH(b6_mq30_s5_QH), .P(b6_l22_p));
    logic [61:0] b6_l23_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l23_gen (.clk(clk), .A(b6_t46), .B(b6_t47), .QH(b6_gq3_s5_QH), .P(b6_l23_w));
    logic [61:0] b6_l23_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l23_a_i (.clk(clk), .din(b5_g0_o[23]), .dout(b6_l23_a));
    logic [61:0] b6_l23_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l23_mul (.clk(clk), .A(b6_l23_a), .B(b6_l23_w), .QH(b6_mq30_s5_QH), .P(b6_l23_p));
    logic [61:0] b6_l24_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b6_gq3_s6_QH;
    always_ff @(posedge clk) b6_gq3_s6_QH <= b6_gq3_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l24_gen (.clk(clk), .A(b6_t48), .B(b6_t49), .QH(b6_gq3_s6_QH), .P(b6_l24_w));
    logic [61:0] b6_l24_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l24_a_i (.clk(clk), .din(b5_g0_o[24]), .dout(b6_l24_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b6_mq30_s6_QH;
    always_ff @(posedge clk) b6_mq30_s6_QH <= b6_mq30_1_QH;
    logic [61:0] b6_l24_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l24_mul (.clk(clk), .A(b6_l24_a), .B(b6_l24_w), .QH(b6_mq30_s6_QH), .P(b6_l24_p));
    logic [61:0] b6_l25_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l25_gen (.clk(clk), .A(b6_t50), .B(b6_t51), .QH(b6_gq3_s6_QH), .P(b6_l25_w));
    logic [61:0] b6_l25_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l25_a_i (.clk(clk), .din(b5_g0_o[25]), .dout(b6_l25_a));
    logic [61:0] b6_l25_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l25_mul (.clk(clk), .A(b6_l25_a), .B(b6_l25_w), .QH(b6_mq30_s6_QH), .P(b6_l25_p));
    logic [61:0] b6_l26_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l26_gen (.clk(clk), .A(b6_t52), .B(b6_t53), .QH(b6_gq3_s6_QH), .P(b6_l26_w));
    logic [61:0] b6_l26_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l26_a_i (.clk(clk), .din(b5_g0_o[26]), .dout(b6_l26_a));
    logic [61:0] b6_l26_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l26_mul (.clk(clk), .A(b6_l26_a), .B(b6_l26_w), .QH(b6_mq30_s6_QH), .P(b6_l26_p));
    logic [61:0] b6_l27_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l27_gen (.clk(clk), .A(b6_t54), .B(b6_t55), .QH(b6_gq3_s6_QH), .P(b6_l27_w));
    logic [61:0] b6_l27_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l27_a_i (.clk(clk), .din(b5_g0_o[27]), .dout(b6_l27_a));
    logic [61:0] b6_l27_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l27_mul (.clk(clk), .A(b6_l27_a), .B(b6_l27_w), .QH(b6_mq30_s6_QH), .P(b6_l27_p));
    logic [61:0] b6_l28_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b6_gq3_s7_QH;
    always_ff @(posedge clk) b6_gq3_s7_QH <= b6_gq3_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l28_gen (.clk(clk), .A(b6_t56), .B(b6_t57), .QH(b6_gq3_s7_QH), .P(b6_l28_w));
    logic [61:0] b6_l28_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l28_a_i (.clk(clk), .din(b5_g0_o[28]), .dout(b6_l28_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b6_mq30_s7_QH;
    always_ff @(posedge clk) b6_mq30_s7_QH <= b6_mq30_1_QH;
    logic [61:0] b6_l28_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l28_mul (.clk(clk), .A(b6_l28_a), .B(b6_l28_w), .QH(b6_mq30_s7_QH), .P(b6_l28_p));
    logic [61:0] b6_l29_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l29_gen (.clk(clk), .A(b6_t58), .B(b6_t59), .QH(b6_gq3_s7_QH), .P(b6_l29_w));
    logic [61:0] b6_l29_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l29_a_i (.clk(clk), .din(b5_g0_o[29]), .dout(b6_l29_a));
    logic [61:0] b6_l29_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l29_mul (.clk(clk), .A(b6_l29_a), .B(b6_l29_w), .QH(b6_mq30_s7_QH), .P(b6_l29_p));
    logic [61:0] b6_l30_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l30_gen (.clk(clk), .A(b6_t60), .B(b6_t61), .QH(b6_gq3_s7_QH), .P(b6_l30_w));
    logic [61:0] b6_l30_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l30_a_i (.clk(clk), .din(b5_g0_o[30]), .dout(b6_l30_a));
    logic [61:0] b6_l30_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l30_mul (.clk(clk), .A(b6_l30_a), .B(b6_l30_w), .QH(b6_mq30_s7_QH), .P(b6_l30_p));
    logic [61:0] b6_l31_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b6_l31_gen (.clk(clk), .A(b6_t62), .B(b6_t63), .QH(b6_gq3_s7_QH), .P(b6_l31_w));
    logic [61:0] b6_l31_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b6_l31_a_i (.clk(clk), .din(b5_g0_o[31]), .dout(b6_l31_a));
    logic [61:0] b6_l31_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b6_l31_mul (.clk(clk), .A(b6_l31_a), .B(b6_l31_w), .QH(b6_mq30_s7_QH), .P(b6_l31_p));
    logic [56:0] b6_v_sr;
    always_ff @(posedge clk) b6_v_sr <= rst ? '0 : {b6_v_sr[55:0], b5_g0_v};
    logic b6_v; assign b6_v = b6_v_sr[56];
    logic [110:0] b6_tag;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(111), .D(57)) b6_tag_i (.clk(clk), .din(b5_tag), .dout(b6_tag));
    // block 7: pass 2, 1 x ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p2 (32-point), latency 126
    logic [61:0] b7_c0_y0, b7_c0_y1, b7_c0_y2, b7_c0_y3, b7_c0_y4, b7_c0_y5, b7_c0_y6, b7_c0_y7, b7_c0_y8, b7_c0_y9, b7_c0_y10, b7_c0_y11, b7_c0_y12, b7_c0_y13, b7_c0_y14, b7_c0_y15, b7_c0_y16, b7_c0_y17, b7_c0_y18, b7_c0_y19, b7_c0_y20, b7_c0_y21, b7_c0_y22, b7_c0_y23, b7_c0_y24, b7_c0_y25, b7_c0_y26, b7_c0_y27, b7_c0_y28, b7_c0_y29, b7_c0_y30, b7_c0_y31;
    logic b7_c0_v; logic [2:0] b7_c0_mi; logic b7_c0_di;
    logic b7_c0_lr, b7_c0_lw; (* equivalent_register_removal = "no" *) logic [61:0] b7_c0_ld;
    always_ff @(posedge clk) begin b7_c0_lr <= ld_r; b7_c0_lw <= ld_v && ld_iq >= 11'd289 && ld_iq < 11'd304; b7_c0_ld <= ld_d[61:0]; end
    logic [2:0] b7_c0_ls; always_ff @(posedge clk) b7_c0_ls <= ld_sl;
    logic b7_c0_ldr; always_ff @(posedge clk) b7_c0_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p2 b7_c0 (.clk(clk), .rst(rst), .in_valid(b6_v), .out_valid(b7_c0_v), .MIDX(b6_tag[3:1]), .midx_out(b7_c0_mi), .mq_QH(b6_tag[48:4]), .mq_QHALF(b6_tag[110:49]), .DIR(b6_tag[0]), .dir_out(b7_c0_di), .tw_rst(b7_c0_lr), .tw_wen(b7_c0_lw), .tw_wdata(b7_c0_ld), .tw_slot(b7_c0_ls), .tw_dir(b7_c0_ldr), .x_in_0(b6_l0_p), .x_in_1(b6_l1_p), .x_in_2(b6_l2_p), .x_in_3(b6_l3_p), .x_in_4(b6_l4_p), .x_in_5(b6_l5_p), .x_in_6(b6_l6_p), .x_in_7(b6_l7_p), .x_in_8(b6_l8_p), .x_in_9(b6_l9_p), .x_in_10(b6_l10_p), .x_in_11(b6_l11_p), .x_in_12(b6_l12_p), .x_in_13(b6_l13_p), .x_in_14(b6_l14_p), .x_in_15(b6_l15_p), .x_in_16(b6_l16_p), .x_in_17(b6_l17_p), .x_in_18(b6_l18_p), .x_in_19(b6_l19_p), .x_in_20(b6_l20_p), .x_in_21(b6_l21_p), .x_in_22(b6_l22_p), .x_in_23(b6_l23_p), .x_in_24(b6_l24_p), .x_in_25(b6_l25_p), .x_in_26(b6_l26_p), .x_in_27(b6_l27_p), .x_in_28(b6_l28_p), .x_in_29(b6_l29_p), .x_in_30(b6_l30_p), .x_in_31(b6_l31_p), .y_out_0(b7_c0_y0), .y_out_1(b7_c0_y1), .y_out_2(b7_c0_y2), .y_out_3(b7_c0_y3), .y_out_4(b7_c0_y4), .y_out_5(b7_c0_y5), .y_out_6(b7_c0_y6), .y_out_7(b7_c0_y7), .y_out_8(b7_c0_y8), .y_out_9(b7_c0_y9), .y_out_10(b7_c0_y10), .y_out_11(b7_c0_y11), .y_out_12(b7_c0_y12), .y_out_13(b7_c0_y13), .y_out_14(b7_c0_y14), .y_out_15(b7_c0_y15), .y_out_16(b7_c0_y16), .y_out_17(b7_c0_y17), .y_out_18(b7_c0_y18), .y_out_19(b7_c0_y19), .y_out_20(b7_c0_y20), .y_out_21(b7_c0_y21), .y_out_22(b7_c0_y22), .y_out_23(b7_c0_y23), .y_out_24(b7_c0_y24), .y_out_25(b7_c0_y25), .y_out_26(b7_c0_y26), .y_out_27(b7_c0_y27), .y_out_28(b7_c0_y28), .y_out_29(b7_c0_y29), .y_out_30(b7_c0_y30), .y_out_31(b7_c0_y31));
    logic [106:0] b7_cq0; assign b7_cq0 = b6_tag[110:4];
    logic [106:0] b7_cq;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(107), .D(126)) b7_cq_i (.clk(clk), .din(b7_cq0), .dout(b7_cq));
    logic [110:0] b7_tag; assign b7_tag = {b7_cq, b7_c0_mi, b7_c0_di};
    // block 8: lane-time transpose, lane bits [0, 1, 2, 3, 4] <-> cycle bits [0,5), 1 x S=32, latency 39
    logic [61:0] b8_g0_i [0:31]; logic [61:0] b8_g0_o [0:31]; logic b8_g0_v;
    assign b8_g0_i[0] = b7_c0_y0;
    assign b8_g0_i[1] = b7_c0_y1;
    assign b8_g0_i[2] = b7_c0_y2;
    assign b8_g0_i[3] = b7_c0_y3;
    assign b8_g0_i[4] = b7_c0_y4;
    assign b8_g0_i[5] = b7_c0_y5;
    assign b8_g0_i[6] = b7_c0_y6;
    assign b8_g0_i[7] = b7_c0_y7;
    assign b8_g0_i[8] = b7_c0_y8;
    assign b8_g0_i[9] = b7_c0_y9;
    assign b8_g0_i[10] = b7_c0_y10;
    assign b8_g0_i[11] = b7_c0_y11;
    assign b8_g0_i[12] = b7_c0_y12;
    assign b8_g0_i[13] = b7_c0_y13;
    assign b8_g0_i[14] = b7_c0_y14;
    assign b8_g0_i[15] = b7_c0_y15;
    assign b8_g0_i[16] = b7_c0_y16;
    assign b8_g0_i[17] = b7_c0_y17;
    assign b8_g0_i[18] = b7_c0_y18;
    assign b8_g0_i[19] = b7_c0_y19;
    assign b8_g0_i[20] = b7_c0_y20;
    assign b8_g0_i[21] = b7_c0_y21;
    assign b8_g0_i[22] = b7_c0_y22;
    assign b8_g0_i[23] = b7_c0_y23;
    assign b8_g0_i[24] = b7_c0_y24;
    assign b8_g0_i[25] = b7_c0_y25;
    assign b8_g0_i[26] = b7_c0_y26;
    assign b8_g0_i[27] = b7_c0_y27;
    assign b8_g0_i[28] = b7_c0_y28;
    assign b8_g0_i[29] = b7_c0_y29;
    assign b8_g0_i[30] = b7_c0_y30;
    assign b8_g0_i[31] = b7_c0_y31;
    lt_bmb_transpose #(.S(32), .LO(0), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h7), .RAM_STYLE("distributed")) b8_g0 (.clk(clk), .rst(rst), .data_valid(b7_c0_v), .data_in(b8_g0_i), .data_out_valid(b8_g0_v), .data_out(b8_g0_o));
    logic [110:0] b8_tag;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(111), .D(39)) b8_tag_i (.clk(clk), .din(b7_tag), .dout(b8_tag));
    // block 9: twiddle stage 3, latency 57 (tables 3, generator 27, multiplier 27)
    logic [10:0] b9_cnt;
    always_ff @(posedge clk) b9_cnt <= rst ? '0 : (b8_g0_v ? b9_cnt + 1'b1 : b9_cnt);
    logic [61:0] b9_t0;
    (* shreg_extract = "no" *) logic [61:0] b9_t0_q0;
    logic b9_t0_lwe; logic [6:0] b9_t0_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t0_lwd;
    always_ff @(posedge clk) begin b9_t0_lwe <= ld_v && ld_iq >= 11'd290 && ld_iq < 11'd298; b9_t0_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd290)}; b9_t0_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab0 b9_t0_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t0_lwe), .wa(b9_t0_lwa), .wcol(1'b0), .wd(b9_t0_lwd), .q0(b9_t0_q0));
    always_ff @(posedge clk) begin b9_t0 <= b9_t0_q0; end
    logic [61:0] b9_t1;
    (* shreg_extract = "no" *) logic [61:0] b9_t1_q0;
    logic b9_t1_lwe; logic [5:0] b9_t1_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t1_lwd;
    always_ff @(posedge clk) begin b9_t1_lwe <= ld_v && ld_iq >= 11'd298 && ld_iq < 11'd302; b9_t1_lwa <= {ld_slq[2:0], ld_drq, 2'(ld_iq - 11'd298)}; b9_t1_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab1 b9_t1_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[4], b9_cnt[3]}), .we(b9_t1_lwe), .wa(b9_t1_lwa), .wcol(1'b0), .wd(b9_t1_lwd), .q0(b9_t1_q0));
    always_ff @(posedge clk) begin b9_t1 <= b9_t1_q0; end
    logic [61:0] b9_t2;
    (* shreg_extract = "no" *) logic [61:0] b9_t2_q0;
    logic b9_t2_lwe; logic [9:0] b9_t2_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t2_lwd;
    always_ff @(posedge clk) begin b9_t2_lwe <= ld_v && ld_iq >= 11'd302 && ld_iq < 11'd366; b9_t2_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd302)}; b9_t2_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab2 b9_t2_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t2_lwe), .wa(b9_t2_lwa), .wcol(1'b0), .wd(b9_t2_lwd), .q0(b9_t2_q0));
    always_ff @(posedge clk) begin b9_t2 <= b9_t2_q0; end
    logic [61:0] b9_t3;
    (* shreg_extract = "no" *) logic [61:0] b9_t3_q0;
    logic b9_t3_lwe; logic [8:0] b9_t3_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t3_lwd;
    always_ff @(posedge clk) begin b9_t3_lwe <= ld_v && ld_iq >= 11'd304 && ld_iq < 11'd336; b9_t3_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd304)}; b9_t3_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab3 b9_t3_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t3_lwe), .wa(b9_t3_lwa), .wcol(1'b0), .wd(b9_t3_lwd), .q0(b9_t3_q0));
    always_ff @(posedge clk) begin b9_t3 <= b9_t3_q0; end
    logic [61:0] b9_t4;
    (* shreg_extract = "no" *) logic [61:0] b9_t4_q0;
    logic b9_t4_lwe; logic [9:0] b9_t4_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t4_lwd;
    always_ff @(posedge clk) begin b9_t4_lwe <= ld_v && ld_iq >= 11'd336 && ld_iq < 11'd400; b9_t4_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd336)}; b9_t4_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab4 b9_t4_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t4_lwe), .wa(b9_t4_lwa), .wcol(1'b0), .wd(b9_t4_lwd), .q0(b9_t4_q0));
    always_ff @(posedge clk) begin b9_t4 <= b9_t4_q0; end
    logic [61:0] b9_t5;
    (* shreg_extract = "no" *) logic [61:0] b9_t5_q0;
    logic b9_t5_lwe; logic [8:0] b9_t5_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t5_lwd;
    always_ff @(posedge clk) begin b9_t5_lwe <= ld_v && ld_iq >= 11'd366 && ld_iq < 11'd398; b9_t5_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd366)}; b9_t5_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab5 b9_t5_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t5_lwe), .wa(b9_t5_lwa), .wcol(1'b0), .wd(b9_t5_lwd), .q0(b9_t5_q0));
    always_ff @(posedge clk) begin b9_t5 <= b9_t5_q0; end
    logic [61:0] b9_t6;
    (* shreg_extract = "no" *) logic [61:0] b9_t6_q0;
    logic b9_t6_lwe; logic [9:0] b9_t6_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t6_lwd;
    always_ff @(posedge clk) begin b9_t6_lwe <= ld_v && ld_iq >= 11'd398 && ld_iq < 11'd462; b9_t6_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd398)}; b9_t6_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab6 b9_t6_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t6_lwe), .wa(b9_t6_lwa), .wcol(1'b0), .wd(b9_t6_lwd), .q0(b9_t6_q0));
    always_ff @(posedge clk) begin b9_t6 <= b9_t6_q0; end
    logic [61:0] b9_t7;
    (* shreg_extract = "no" *) logic [61:0] b9_t7_q0;
    logic b9_t7_lwe; logic [8:0] b9_t7_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t7_lwd;
    always_ff @(posedge clk) begin b9_t7_lwe <= ld_v && ld_iq >= 11'd400 && ld_iq < 11'd432; b9_t7_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd400)}; b9_t7_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab7 b9_t7_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t7_lwe), .wa(b9_t7_lwa), .wcol(1'b0), .wd(b9_t7_lwd), .q0(b9_t7_q0));
    always_ff @(posedge clk) begin b9_t7 <= b9_t7_q0; end
    logic [61:0] b9_t8;
    (* shreg_extract = "no" *) logic [61:0] b9_t8_q0;
    logic b9_t8_lwe; logic [9:0] b9_t8_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t8_lwd;
    always_ff @(posedge clk) begin b9_t8_lwe <= ld_v && ld_iq >= 11'd432 && ld_iq < 11'd496; b9_t8_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd432)}; b9_t8_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab8 b9_t8_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t8_lwe), .wa(b9_t8_lwa), .wcol(1'b0), .wd(b9_t8_lwd), .q0(b9_t8_q0));
    always_ff @(posedge clk) begin b9_t8 <= b9_t8_q0; end
    logic [61:0] b9_t9;
    (* shreg_extract = "no" *) logic [61:0] b9_t9_q0;
    logic b9_t9_lwe; logic [8:0] b9_t9_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t9_lwd;
    always_ff @(posedge clk) begin b9_t9_lwe <= ld_v && ld_iq >= 11'd462 && ld_iq < 11'd494; b9_t9_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd462)}; b9_t9_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab9 b9_t9_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t9_lwe), .wa(b9_t9_lwa), .wcol(1'b0), .wd(b9_t9_lwd), .q0(b9_t9_q0));
    always_ff @(posedge clk) begin b9_t9 <= b9_t9_q0; end
    logic [61:0] b9_t10;
    (* shreg_extract = "no" *) logic [61:0] b9_t10_q0;
    logic b9_t10_lwe; logic [9:0] b9_t10_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t10_lwd;
    always_ff @(posedge clk) begin b9_t10_lwe <= ld_v && ld_iq >= 11'd494 && ld_iq < 11'd558; b9_t10_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd494)}; b9_t10_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab10 b9_t10_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t10_lwe), .wa(b9_t10_lwa), .wcol(1'b0), .wd(b9_t10_lwd), .q0(b9_t10_q0));
    always_ff @(posedge clk) begin b9_t10 <= b9_t10_q0; end
    logic [61:0] b9_t11;
    (* shreg_extract = "no" *) logic [61:0] b9_t11_q0;
    logic b9_t11_lwe; logic [8:0] b9_t11_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t11_lwd;
    always_ff @(posedge clk) begin b9_t11_lwe <= ld_v && ld_iq >= 11'd496 && ld_iq < 11'd528; b9_t11_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd496)}; b9_t11_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab11 b9_t11_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t11_lwe), .wa(b9_t11_lwa), .wcol(1'b0), .wd(b9_t11_lwd), .q0(b9_t11_q0));
    always_ff @(posedge clk) begin b9_t11 <= b9_t11_q0; end
    logic [61:0] b9_t12;
    (* shreg_extract = "no" *) logic [61:0] b9_t12_q0;
    logic b9_t12_lwe; logic [9:0] b9_t12_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t12_lwd;
    always_ff @(posedge clk) begin b9_t12_lwe <= ld_v && ld_iq >= 11'd528 && ld_iq < 11'd592; b9_t12_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd528)}; b9_t12_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab12 b9_t12_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t12_lwe), .wa(b9_t12_lwa), .wcol(1'b0), .wd(b9_t12_lwd), .q0(b9_t12_q0));
    always_ff @(posedge clk) begin b9_t12 <= b9_t12_q0; end
    logic [61:0] b9_t13;
    (* shreg_extract = "no" *) logic [61:0] b9_t13_q0;
    logic b9_t13_lwe; logic [8:0] b9_t13_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t13_lwd;
    always_ff @(posedge clk) begin b9_t13_lwe <= ld_v && ld_iq >= 11'd558 && ld_iq < 11'd590; b9_t13_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd558)}; b9_t13_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab13 b9_t13_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t13_lwe), .wa(b9_t13_lwa), .wcol(1'b0), .wd(b9_t13_lwd), .q0(b9_t13_q0));
    always_ff @(posedge clk) begin b9_t13 <= b9_t13_q0; end
    logic [61:0] b9_t14;
    (* shreg_extract = "no" *) logic [61:0] b9_t14_q0;
    logic b9_t14_lwe; logic [9:0] b9_t14_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t14_lwd;
    always_ff @(posedge clk) begin b9_t14_lwe <= ld_v && ld_iq >= 11'd590 && ld_iq < 11'd654; b9_t14_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd590)}; b9_t14_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab14 b9_t14_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t14_lwe), .wa(b9_t14_lwa), .wcol(1'b0), .wd(b9_t14_lwd), .q0(b9_t14_q0));
    always_ff @(posedge clk) begin b9_t14 <= b9_t14_q0; end
    logic [61:0] b9_t15;
    (* shreg_extract = "no" *) logic [61:0] b9_t15_q0;
    logic b9_t15_lwe; logic [8:0] b9_t15_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t15_lwd;
    always_ff @(posedge clk) begin b9_t15_lwe <= ld_v && ld_iq >= 11'd592 && ld_iq < 11'd624; b9_t15_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd592)}; b9_t15_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab15 b9_t15_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t15_lwe), .wa(b9_t15_lwa), .wcol(1'b0), .wd(b9_t15_lwd), .q0(b9_t15_q0));
    always_ff @(posedge clk) begin b9_t15 <= b9_t15_q0; end
    logic [61:0] b9_t16;
    (* shreg_extract = "no" *) logic [61:0] b9_t16_q0;
    logic b9_t16_lwe; logic [9:0] b9_t16_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t16_lwd;
    always_ff @(posedge clk) begin b9_t16_lwe <= ld_v && ld_iq >= 11'd624 && ld_iq < 11'd688; b9_t16_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd624)}; b9_t16_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab16 b9_t16_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t16_lwe), .wa(b9_t16_lwa), .wcol(1'b0), .wd(b9_t16_lwd), .q0(b9_t16_q0));
    always_ff @(posedge clk) begin b9_t16 <= b9_t16_q0; end
    logic [61:0] b9_t17;
    (* shreg_extract = "no" *) logic [61:0] b9_t17_q0;
    logic b9_t17_lwe; logic [8:0] b9_t17_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t17_lwd;
    always_ff @(posedge clk) begin b9_t17_lwe <= ld_v && ld_iq >= 11'd654 && ld_iq < 11'd686; b9_t17_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd654)}; b9_t17_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab17 b9_t17_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t17_lwe), .wa(b9_t17_lwa), .wcol(1'b0), .wd(b9_t17_lwd), .q0(b9_t17_q0));
    always_ff @(posedge clk) begin b9_t17 <= b9_t17_q0; end
    logic [61:0] b9_t18;
    (* shreg_extract = "no" *) logic [61:0] b9_t18_q0;
    logic b9_t18_lwe; logic [9:0] b9_t18_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t18_lwd;
    always_ff @(posedge clk) begin b9_t18_lwe <= ld_v && ld_iq >= 11'd686 && ld_iq < 11'd750; b9_t18_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd686)}; b9_t18_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab18 b9_t18_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t18_lwe), .wa(b9_t18_lwa), .wcol(1'b0), .wd(b9_t18_lwd), .q0(b9_t18_q0));
    always_ff @(posedge clk) begin b9_t18 <= b9_t18_q0; end
    logic [61:0] b9_t19;
    (* shreg_extract = "no" *) logic [61:0] b9_t19_q0;
    logic b9_t19_lwe; logic [8:0] b9_t19_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t19_lwd;
    always_ff @(posedge clk) begin b9_t19_lwe <= ld_v && ld_iq >= 11'd688 && ld_iq < 11'd720; b9_t19_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd688)}; b9_t19_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab19 b9_t19_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t19_lwe), .wa(b9_t19_lwa), .wcol(1'b0), .wd(b9_t19_lwd), .q0(b9_t19_q0));
    always_ff @(posedge clk) begin b9_t19 <= b9_t19_q0; end
    logic [61:0] b9_t20;
    (* shreg_extract = "no" *) logic [61:0] b9_t20_q0;
    logic b9_t20_lwe; logic [9:0] b9_t20_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t20_lwd;
    always_ff @(posedge clk) begin b9_t20_lwe <= ld_v && ld_iq >= 11'd720 && ld_iq < 11'd784; b9_t20_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd720)}; b9_t20_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab20 b9_t20_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t20_lwe), .wa(b9_t20_lwa), .wcol(1'b0), .wd(b9_t20_lwd), .q0(b9_t20_q0));
    always_ff @(posedge clk) begin b9_t20 <= b9_t20_q0; end
    logic [61:0] b9_t21;
    (* shreg_extract = "no" *) logic [61:0] b9_t21_q0;
    logic b9_t21_lwe; logic [8:0] b9_t21_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t21_lwd;
    always_ff @(posedge clk) begin b9_t21_lwe <= ld_v && ld_iq >= 11'd750 && ld_iq < 11'd782; b9_t21_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd750)}; b9_t21_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab21 b9_t21_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t21_lwe), .wa(b9_t21_lwa), .wcol(1'b0), .wd(b9_t21_lwd), .q0(b9_t21_q0));
    always_ff @(posedge clk) begin b9_t21 <= b9_t21_q0; end
    logic [61:0] b9_t22;
    (* shreg_extract = "no" *) logic [61:0] b9_t22_q0;
    logic b9_t22_lwe; logic [9:0] b9_t22_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t22_lwd;
    always_ff @(posedge clk) begin b9_t22_lwe <= ld_v && ld_iq >= 11'd782 && ld_iq < 11'd846; b9_t22_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd782)}; b9_t22_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab22 b9_t22_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t22_lwe), .wa(b9_t22_lwa), .wcol(1'b0), .wd(b9_t22_lwd), .q0(b9_t22_q0));
    always_ff @(posedge clk) begin b9_t22 <= b9_t22_q0; end
    logic [61:0] b9_t23;
    (* shreg_extract = "no" *) logic [61:0] b9_t23_q0;
    logic b9_t23_lwe; logic [8:0] b9_t23_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t23_lwd;
    always_ff @(posedge clk) begin b9_t23_lwe <= ld_v && ld_iq >= 11'd784 && ld_iq < 11'd816; b9_t23_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd784)}; b9_t23_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab23 b9_t23_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t23_lwe), .wa(b9_t23_lwa), .wcol(1'b0), .wd(b9_t23_lwd), .q0(b9_t23_q0));
    always_ff @(posedge clk) begin b9_t23 <= b9_t23_q0; end
    logic [61:0] b9_t24;
    (* shreg_extract = "no" *) logic [61:0] b9_t24_q0;
    logic b9_t24_lwe; logic [9:0] b9_t24_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t24_lwd;
    always_ff @(posedge clk) begin b9_t24_lwe <= ld_v && ld_iq >= 11'd816 && ld_iq < 11'd880; b9_t24_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd816)}; b9_t24_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab24 b9_t24_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t24_lwe), .wa(b9_t24_lwa), .wcol(1'b0), .wd(b9_t24_lwd), .q0(b9_t24_q0));
    always_ff @(posedge clk) begin b9_t24 <= b9_t24_q0; end
    logic [61:0] b9_t25;
    (* shreg_extract = "no" *) logic [61:0] b9_t25_q0;
    logic b9_t25_lwe; logic [8:0] b9_t25_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t25_lwd;
    always_ff @(posedge clk) begin b9_t25_lwe <= ld_v && ld_iq >= 11'd846 && ld_iq < 11'd878; b9_t25_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd846)}; b9_t25_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab25 b9_t25_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t25_lwe), .wa(b9_t25_lwa), .wcol(1'b0), .wd(b9_t25_lwd), .q0(b9_t25_q0));
    always_ff @(posedge clk) begin b9_t25 <= b9_t25_q0; end
    logic [61:0] b9_t26;
    (* shreg_extract = "no" *) logic [61:0] b9_t26_q0;
    logic b9_t26_lwe; logic [9:0] b9_t26_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t26_lwd;
    always_ff @(posedge clk) begin b9_t26_lwe <= ld_v && ld_iq >= 11'd878 && ld_iq < 11'd942; b9_t26_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd878)}; b9_t26_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab26 b9_t26_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t26_lwe), .wa(b9_t26_lwa), .wcol(1'b0), .wd(b9_t26_lwd), .q0(b9_t26_q0));
    always_ff @(posedge clk) begin b9_t26 <= b9_t26_q0; end
    logic [61:0] b9_t27;
    (* shreg_extract = "no" *) logic [61:0] b9_t27_q0;
    logic b9_t27_lwe; logic [8:0] b9_t27_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t27_lwd;
    always_ff @(posedge clk) begin b9_t27_lwe <= ld_v && ld_iq >= 11'd880 && ld_iq < 11'd912; b9_t27_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd880)}; b9_t27_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab27 b9_t27_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t27_lwe), .wa(b9_t27_lwa), .wcol(1'b0), .wd(b9_t27_lwd), .q0(b9_t27_q0));
    always_ff @(posedge clk) begin b9_t27 <= b9_t27_q0; end
    logic [61:0] b9_t28;
    (* shreg_extract = "no" *) logic [61:0] b9_t28_q0;
    logic b9_t28_lwe; logic [9:0] b9_t28_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t28_lwd;
    always_ff @(posedge clk) begin b9_t28_lwe <= ld_v && ld_iq >= 11'd912 && ld_iq < 11'd976; b9_t28_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd912)}; b9_t28_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab28 b9_t28_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t28_lwe), .wa(b9_t28_lwa), .wcol(1'b0), .wd(b9_t28_lwd), .q0(b9_t28_q0));
    always_ff @(posedge clk) begin b9_t28 <= b9_t28_q0; end
    logic [61:0] b9_t29;
    (* shreg_extract = "no" *) logic [61:0] b9_t29_q0;
    logic b9_t29_lwe; logic [8:0] b9_t29_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t29_lwd;
    always_ff @(posedge clk) begin b9_t29_lwe <= ld_v && ld_iq >= 11'd942 && ld_iq < 11'd974; b9_t29_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd942)}; b9_t29_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab29 b9_t29_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t29_lwe), .wa(b9_t29_lwa), .wcol(1'b0), .wd(b9_t29_lwd), .q0(b9_t29_q0));
    always_ff @(posedge clk) begin b9_t29 <= b9_t29_q0; end
    logic [61:0] b9_t30;
    (* shreg_extract = "no" *) logic [61:0] b9_t30_q0;
    logic b9_t30_lwe; logic [9:0] b9_t30_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t30_lwd;
    always_ff @(posedge clk) begin b9_t30_lwe <= ld_v && ld_iq >= 11'd974 && ld_iq < 11'd1038; b9_t30_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd974)}; b9_t30_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab30 b9_t30_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t30_lwe), .wa(b9_t30_lwa), .wcol(1'b0), .wd(b9_t30_lwd), .q0(b9_t30_q0));
    always_ff @(posedge clk) begin b9_t30 <= b9_t30_q0; end
    logic [61:0] b9_t31;
    (* shreg_extract = "no" *) logic [61:0] b9_t31_q0;
    logic b9_t31_lwe; logic [8:0] b9_t31_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t31_lwd;
    always_ff @(posedge clk) begin b9_t31_lwe <= ld_v && ld_iq >= 11'd976 && ld_iq < 11'd1008; b9_t31_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd976)}; b9_t31_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab31 b9_t31_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t31_lwe), .wa(b9_t31_lwa), .wcol(1'b0), .wd(b9_t31_lwd), .q0(b9_t31_q0));
    always_ff @(posedge clk) begin b9_t31 <= b9_t31_q0; end
    logic [61:0] b9_t32;
    (* shreg_extract = "no" *) logic [61:0] b9_t32_q0;
    logic b9_t32_lwe; logic [9:0] b9_t32_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t32_lwd;
    always_ff @(posedge clk) begin b9_t32_lwe <= ld_v && ld_iq >= 11'd1008 && ld_iq < 11'd1072; b9_t32_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1008)}; b9_t32_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab32 b9_t32_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t32_lwe), .wa(b9_t32_lwa), .wcol(1'b0), .wd(b9_t32_lwd), .q0(b9_t32_q0));
    always_ff @(posedge clk) begin b9_t32 <= b9_t32_q0; end
    logic [61:0] b9_t33;
    (* shreg_extract = "no" *) logic [61:0] b9_t33_q0;
    logic b9_t33_lwe; logic [8:0] b9_t33_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t33_lwd;
    always_ff @(posedge clk) begin b9_t33_lwe <= ld_v && ld_iq >= 11'd1038 && ld_iq < 11'd1070; b9_t33_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1038)}; b9_t33_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab33 b9_t33_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t33_lwe), .wa(b9_t33_lwa), .wcol(1'b0), .wd(b9_t33_lwd), .q0(b9_t33_q0));
    always_ff @(posedge clk) begin b9_t33 <= b9_t33_q0; end
    logic [61:0] b9_t34;
    (* shreg_extract = "no" *) logic [61:0] b9_t34_q0;
    logic b9_t34_lwe; logic [9:0] b9_t34_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t34_lwd;
    always_ff @(posedge clk) begin b9_t34_lwe <= ld_v && ld_iq >= 11'd1070 && ld_iq < 11'd1134; b9_t34_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1070)}; b9_t34_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab34 b9_t34_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t34_lwe), .wa(b9_t34_lwa), .wcol(1'b0), .wd(b9_t34_lwd), .q0(b9_t34_q0));
    always_ff @(posedge clk) begin b9_t34 <= b9_t34_q0; end
    logic [61:0] b9_t35;
    (* shreg_extract = "no" *) logic [61:0] b9_t35_q0;
    logic b9_t35_lwe; logic [8:0] b9_t35_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t35_lwd;
    always_ff @(posedge clk) begin b9_t35_lwe <= ld_v && ld_iq >= 11'd1072 && ld_iq < 11'd1104; b9_t35_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1072)}; b9_t35_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab35 b9_t35_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t35_lwe), .wa(b9_t35_lwa), .wcol(1'b0), .wd(b9_t35_lwd), .q0(b9_t35_q0));
    always_ff @(posedge clk) begin b9_t35 <= b9_t35_q0; end
    logic [61:0] b9_t36;
    (* shreg_extract = "no" *) logic [61:0] b9_t36_q0;
    logic b9_t36_lwe; logic [9:0] b9_t36_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t36_lwd;
    always_ff @(posedge clk) begin b9_t36_lwe <= ld_v && ld_iq >= 11'd1104 && ld_iq < 11'd1168; b9_t36_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1104)}; b9_t36_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab36 b9_t36_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t36_lwe), .wa(b9_t36_lwa), .wcol(1'b0), .wd(b9_t36_lwd), .q0(b9_t36_q0));
    always_ff @(posedge clk) begin b9_t36 <= b9_t36_q0; end
    logic [61:0] b9_t37;
    (* shreg_extract = "no" *) logic [61:0] b9_t37_q0;
    logic b9_t37_lwe; logic [8:0] b9_t37_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t37_lwd;
    always_ff @(posedge clk) begin b9_t37_lwe <= ld_v && ld_iq >= 11'd1134 && ld_iq < 11'd1166; b9_t37_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1134)}; b9_t37_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab37 b9_t37_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t37_lwe), .wa(b9_t37_lwa), .wcol(1'b0), .wd(b9_t37_lwd), .q0(b9_t37_q0));
    always_ff @(posedge clk) begin b9_t37 <= b9_t37_q0; end
    logic [61:0] b9_t38;
    (* shreg_extract = "no" *) logic [61:0] b9_t38_q0;
    logic b9_t38_lwe; logic [9:0] b9_t38_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t38_lwd;
    always_ff @(posedge clk) begin b9_t38_lwe <= ld_v && ld_iq >= 11'd1166 && ld_iq < 11'd1230; b9_t38_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1166)}; b9_t38_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab38 b9_t38_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t38_lwe), .wa(b9_t38_lwa), .wcol(1'b0), .wd(b9_t38_lwd), .q0(b9_t38_q0));
    always_ff @(posedge clk) begin b9_t38 <= b9_t38_q0; end
    logic [61:0] b9_t39;
    (* shreg_extract = "no" *) logic [61:0] b9_t39_q0;
    logic b9_t39_lwe; logic [8:0] b9_t39_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t39_lwd;
    always_ff @(posedge clk) begin b9_t39_lwe <= ld_v && ld_iq >= 11'd1168 && ld_iq < 11'd1200; b9_t39_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1168)}; b9_t39_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab39 b9_t39_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t39_lwe), .wa(b9_t39_lwa), .wcol(1'b0), .wd(b9_t39_lwd), .q0(b9_t39_q0));
    always_ff @(posedge clk) begin b9_t39 <= b9_t39_q0; end
    logic [61:0] b9_t40;
    (* shreg_extract = "no" *) logic [61:0] b9_t40_q0;
    logic b9_t40_lwe; logic [9:0] b9_t40_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t40_lwd;
    always_ff @(posedge clk) begin b9_t40_lwe <= ld_v && ld_iq >= 11'd1200 && ld_iq < 11'd1264; b9_t40_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1200)}; b9_t40_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab40 b9_t40_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t40_lwe), .wa(b9_t40_lwa), .wcol(1'b0), .wd(b9_t40_lwd), .q0(b9_t40_q0));
    always_ff @(posedge clk) begin b9_t40 <= b9_t40_q0; end
    logic [61:0] b9_t41;
    (* shreg_extract = "no" *) logic [61:0] b9_t41_q0;
    logic b9_t41_lwe; logic [8:0] b9_t41_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t41_lwd;
    always_ff @(posedge clk) begin b9_t41_lwe <= ld_v && ld_iq >= 11'd1230 && ld_iq < 11'd1262; b9_t41_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1230)}; b9_t41_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab41 b9_t41_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t41_lwe), .wa(b9_t41_lwa), .wcol(1'b0), .wd(b9_t41_lwd), .q0(b9_t41_q0));
    always_ff @(posedge clk) begin b9_t41 <= b9_t41_q0; end
    logic [61:0] b9_t42;
    (* shreg_extract = "no" *) logic [61:0] b9_t42_q0;
    logic b9_t42_lwe; logic [9:0] b9_t42_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t42_lwd;
    always_ff @(posedge clk) begin b9_t42_lwe <= ld_v && ld_iq >= 11'd1262 && ld_iq < 11'd1326; b9_t42_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1262)}; b9_t42_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab42 b9_t42_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t42_lwe), .wa(b9_t42_lwa), .wcol(1'b0), .wd(b9_t42_lwd), .q0(b9_t42_q0));
    always_ff @(posedge clk) begin b9_t42 <= b9_t42_q0; end
    logic [61:0] b9_t43;
    (* shreg_extract = "no" *) logic [61:0] b9_t43_q0;
    logic b9_t43_lwe; logic [8:0] b9_t43_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t43_lwd;
    always_ff @(posedge clk) begin b9_t43_lwe <= ld_v && ld_iq >= 11'd1264 && ld_iq < 11'd1296; b9_t43_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1264)}; b9_t43_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab43 b9_t43_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t43_lwe), .wa(b9_t43_lwa), .wcol(1'b0), .wd(b9_t43_lwd), .q0(b9_t43_q0));
    always_ff @(posedge clk) begin b9_t43 <= b9_t43_q0; end
    logic [61:0] b9_t44;
    (* shreg_extract = "no" *) logic [61:0] b9_t44_q0;
    logic b9_t44_lwe; logic [9:0] b9_t44_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t44_lwd;
    always_ff @(posedge clk) begin b9_t44_lwe <= ld_v && ld_iq >= 11'd1296 && ld_iq < 11'd1360; b9_t44_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1296)}; b9_t44_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab44 b9_t44_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t44_lwe), .wa(b9_t44_lwa), .wcol(1'b0), .wd(b9_t44_lwd), .q0(b9_t44_q0));
    always_ff @(posedge clk) begin b9_t44 <= b9_t44_q0; end
    logic [61:0] b9_t45;
    (* shreg_extract = "no" *) logic [61:0] b9_t45_q0;
    logic b9_t45_lwe; logic [8:0] b9_t45_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t45_lwd;
    always_ff @(posedge clk) begin b9_t45_lwe <= ld_v && ld_iq >= 11'd1326 && ld_iq < 11'd1358; b9_t45_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1326)}; b9_t45_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab45 b9_t45_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t45_lwe), .wa(b9_t45_lwa), .wcol(1'b0), .wd(b9_t45_lwd), .q0(b9_t45_q0));
    always_ff @(posedge clk) begin b9_t45 <= b9_t45_q0; end
    logic [61:0] b9_t46;
    (* shreg_extract = "no" *) logic [61:0] b9_t46_q0;
    logic b9_t46_lwe; logic [9:0] b9_t46_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t46_lwd;
    always_ff @(posedge clk) begin b9_t46_lwe <= ld_v && ld_iq >= 11'd1358 && ld_iq < 11'd1422; b9_t46_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1358)}; b9_t46_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab46 b9_t46_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t46_lwe), .wa(b9_t46_lwa), .wcol(1'b0), .wd(b9_t46_lwd), .q0(b9_t46_q0));
    always_ff @(posedge clk) begin b9_t46 <= b9_t46_q0; end
    logic [61:0] b9_t47;
    (* shreg_extract = "no" *) logic [61:0] b9_t47_q0;
    logic b9_t47_lwe; logic [8:0] b9_t47_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t47_lwd;
    always_ff @(posedge clk) begin b9_t47_lwe <= ld_v && ld_iq >= 11'd1360 && ld_iq < 11'd1392; b9_t47_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1360)}; b9_t47_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab47 b9_t47_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t47_lwe), .wa(b9_t47_lwa), .wcol(1'b0), .wd(b9_t47_lwd), .q0(b9_t47_q0));
    always_ff @(posedge clk) begin b9_t47 <= b9_t47_q0; end
    logic [61:0] b9_t48;
    (* shreg_extract = "no" *) logic [61:0] b9_t48_q0;
    logic b9_t48_lwe; logic [9:0] b9_t48_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t48_lwd;
    always_ff @(posedge clk) begin b9_t48_lwe <= ld_v && ld_iq >= 11'd1392 && ld_iq < 11'd1456; b9_t48_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1392)}; b9_t48_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab48 b9_t48_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t48_lwe), .wa(b9_t48_lwa), .wcol(1'b0), .wd(b9_t48_lwd), .q0(b9_t48_q0));
    always_ff @(posedge clk) begin b9_t48 <= b9_t48_q0; end
    logic [61:0] b9_t49;
    (* shreg_extract = "no" *) logic [61:0] b9_t49_q0;
    logic b9_t49_lwe; logic [8:0] b9_t49_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t49_lwd;
    always_ff @(posedge clk) begin b9_t49_lwe <= ld_v && ld_iq >= 11'd1422 && ld_iq < 11'd1454; b9_t49_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1422)}; b9_t49_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab49 b9_t49_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t49_lwe), .wa(b9_t49_lwa), .wcol(1'b0), .wd(b9_t49_lwd), .q0(b9_t49_q0));
    always_ff @(posedge clk) begin b9_t49 <= b9_t49_q0; end
    logic [61:0] b9_t50;
    (* shreg_extract = "no" *) logic [61:0] b9_t50_q0;
    logic b9_t50_lwe; logic [9:0] b9_t50_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t50_lwd;
    always_ff @(posedge clk) begin b9_t50_lwe <= ld_v && ld_iq >= 11'd1454 && ld_iq < 11'd1518; b9_t50_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1454)}; b9_t50_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab50 b9_t50_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t50_lwe), .wa(b9_t50_lwa), .wcol(1'b0), .wd(b9_t50_lwd), .q0(b9_t50_q0));
    always_ff @(posedge clk) begin b9_t50 <= b9_t50_q0; end
    logic [61:0] b9_t51;
    (* shreg_extract = "no" *) logic [61:0] b9_t51_q0;
    logic b9_t51_lwe; logic [8:0] b9_t51_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t51_lwd;
    always_ff @(posedge clk) begin b9_t51_lwe <= ld_v && ld_iq >= 11'd1456 && ld_iq < 11'd1488; b9_t51_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1456)}; b9_t51_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab51 b9_t51_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t51_lwe), .wa(b9_t51_lwa), .wcol(1'b0), .wd(b9_t51_lwd), .q0(b9_t51_q0));
    always_ff @(posedge clk) begin b9_t51 <= b9_t51_q0; end
    logic [61:0] b9_t52;
    (* shreg_extract = "no" *) logic [61:0] b9_t52_q0;
    logic b9_t52_lwe; logic [9:0] b9_t52_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t52_lwd;
    always_ff @(posedge clk) begin b9_t52_lwe <= ld_v && ld_iq >= 11'd1488 && ld_iq < 11'd1552; b9_t52_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1488)}; b9_t52_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab52 b9_t52_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t52_lwe), .wa(b9_t52_lwa), .wcol(1'b0), .wd(b9_t52_lwd), .q0(b9_t52_q0));
    always_ff @(posedge clk) begin b9_t52 <= b9_t52_q0; end
    logic [61:0] b9_t53;
    (* shreg_extract = "no" *) logic [61:0] b9_t53_q0;
    logic b9_t53_lwe; logic [8:0] b9_t53_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t53_lwd;
    always_ff @(posedge clk) begin b9_t53_lwe <= ld_v && ld_iq >= 11'd1518 && ld_iq < 11'd1550; b9_t53_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1518)}; b9_t53_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab53 b9_t53_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t53_lwe), .wa(b9_t53_lwa), .wcol(1'b0), .wd(b9_t53_lwd), .q0(b9_t53_q0));
    always_ff @(posedge clk) begin b9_t53 <= b9_t53_q0; end
    logic [61:0] b9_t54;
    (* shreg_extract = "no" *) logic [61:0] b9_t54_q0;
    logic b9_t54_lwe; logic [9:0] b9_t54_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t54_lwd;
    always_ff @(posedge clk) begin b9_t54_lwe <= ld_v && ld_iq >= 11'd1550 && ld_iq < 11'd1614; b9_t54_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1550)}; b9_t54_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab54 b9_t54_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t54_lwe), .wa(b9_t54_lwa), .wcol(1'b0), .wd(b9_t54_lwd), .q0(b9_t54_q0));
    always_ff @(posedge clk) begin b9_t54 <= b9_t54_q0; end
    logic [61:0] b9_t55;
    (* shreg_extract = "no" *) logic [61:0] b9_t55_q0;
    logic b9_t55_lwe; logic [8:0] b9_t55_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t55_lwd;
    always_ff @(posedge clk) begin b9_t55_lwe <= ld_v && ld_iq >= 11'd1552 && ld_iq < 11'd1584; b9_t55_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1552)}; b9_t55_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab55 b9_t55_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t55_lwe), .wa(b9_t55_lwa), .wcol(1'b0), .wd(b9_t55_lwd), .q0(b9_t55_q0));
    always_ff @(posedge clk) begin b9_t55 <= b9_t55_q0; end
    logic [61:0] b9_t56;
    (* shreg_extract = "no" *) logic [61:0] b9_t56_q0;
    logic b9_t56_lwe; logic [9:0] b9_t56_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t56_lwd;
    always_ff @(posedge clk) begin b9_t56_lwe <= ld_v && ld_iq >= 11'd1584 && ld_iq < 11'd1648; b9_t56_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1584)}; b9_t56_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab56 b9_t56_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t56_lwe), .wa(b9_t56_lwa), .wcol(1'b0), .wd(b9_t56_lwd), .q0(b9_t56_q0));
    always_ff @(posedge clk) begin b9_t56 <= b9_t56_q0; end
    logic [61:0] b9_t57;
    (* shreg_extract = "no" *) logic [61:0] b9_t57_q0;
    logic b9_t57_lwe; logic [8:0] b9_t57_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t57_lwd;
    always_ff @(posedge clk) begin b9_t57_lwe <= ld_v && ld_iq >= 11'd1614 && ld_iq < 11'd1646; b9_t57_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1614)}; b9_t57_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab57 b9_t57_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t57_lwe), .wa(b9_t57_lwa), .wcol(1'b0), .wd(b9_t57_lwd), .q0(b9_t57_q0));
    always_ff @(posedge clk) begin b9_t57 <= b9_t57_q0; end
    logic [61:0] b9_t58;
    (* shreg_extract = "no" *) logic [61:0] b9_t58_q0;
    logic b9_t58_lwe; logic [9:0] b9_t58_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t58_lwd;
    always_ff @(posedge clk) begin b9_t58_lwe <= ld_v && ld_iq >= 11'd1646 && ld_iq < 11'd1710; b9_t58_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1646)}; b9_t58_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab58 b9_t58_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t58_lwe), .wa(b9_t58_lwa), .wcol(1'b0), .wd(b9_t58_lwd), .q0(b9_t58_q0));
    always_ff @(posedge clk) begin b9_t58 <= b9_t58_q0; end
    logic [61:0] b9_t59;
    (* shreg_extract = "no" *) logic [61:0] b9_t59_q0;
    logic b9_t59_lwe; logic [8:0] b9_t59_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t59_lwd;
    always_ff @(posedge clk) begin b9_t59_lwe <= ld_v && ld_iq >= 11'd1648 && ld_iq < 11'd1680; b9_t59_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1648)}; b9_t59_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab59 b9_t59_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t59_lwe), .wa(b9_t59_lwa), .wcol(1'b0), .wd(b9_t59_lwd), .q0(b9_t59_q0));
    always_ff @(posedge clk) begin b9_t59 <= b9_t59_q0; end
    logic [61:0] b9_t60;
    (* shreg_extract = "no" *) logic [61:0] b9_t60_q0;
    logic b9_t60_lwe; logic [9:0] b9_t60_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t60_lwd;
    always_ff @(posedge clk) begin b9_t60_lwe <= ld_v && ld_iq >= 11'd1680 && ld_iq < 11'd1744; b9_t60_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1680)}; b9_t60_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab60 b9_t60_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t60_lwe), .wa(b9_t60_lwa), .wcol(1'b0), .wd(b9_t60_lwd), .q0(b9_t60_q0));
    always_ff @(posedge clk) begin b9_t60 <= b9_t60_q0; end
    logic [61:0] b9_t61;
    (* shreg_extract = "no" *) logic [61:0] b9_t61_q0;
    logic b9_t61_lwe; logic [8:0] b9_t61_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t61_lwd;
    always_ff @(posedge clk) begin b9_t61_lwe <= ld_v && ld_iq >= 11'd1710 && ld_iq < 11'd1742; b9_t61_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1710)}; b9_t61_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab61 b9_t61_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t61_lwe), .wa(b9_t61_lwa), .wcol(1'b0), .wd(b9_t61_lwd), .q0(b9_t61_q0));
    always_ff @(posedge clk) begin b9_t61 <= b9_t61_q0; end
    logic [61:0] b9_t62;
    (* shreg_extract = "no" *) logic [61:0] b9_t62_q0;
    logic b9_t62_lwe; logic [9:0] b9_t62_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t62_lwd;
    always_ff @(posedge clk) begin b9_t62_lwe <= ld_v && ld_iq >= 11'd1742 && ld_iq < 11'd1806; b9_t62_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1742)}; b9_t62_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab62 b9_t62_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[5], b9_cnt[4], b9_cnt[3], b9_cnt[2], b9_cnt[1], b9_cnt[0]}), .we(b9_t62_lwe), .wa(b9_t62_lwa), .wcol(1'b0), .wd(b9_t62_lwd), .q0(b9_t62_q0));
    always_ff @(posedge clk) begin b9_t62 <= b9_t62_q0; end
    logic [61:0] b9_t63;
    (* shreg_extract = "no" *) logic [61:0] b9_t63_q0;
    logic b9_t63_lwe; logic [8:0] b9_t63_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b9_t63_lwd;
    always_ff @(posedge clk) begin b9_t63_lwe <= ld_v && ld_iq >= 11'd1744 && ld_iq < 11'd1776; b9_t63_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1744)}; b9_t63_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab63 b9_t63_i (.clk(clk), .addr({b8_tag[3:1], b8_tag[0], b9_cnt[10], b9_cnt[9], b9_cnt[8], b9_cnt[7], b9_cnt[6]}), .we(b9_t63_lwe), .wa(b9_t63_lwa), .wcol(1'b0), .wd(b9_t63_lwd), .q0(b9_t63_q0));
    always_ff @(posedge clk) begin b9_t63 <= b9_t63_q0; end
    logic [61:0] b9_l0_w;
    logic [44:0] b9_gq3_0_QH_c; assign b9_gq3_0_QH_c = b8_tag[48:4];
    logic [44:0] b9_gq3_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(45), .D(2)) b9_gq3_0_QH_i (.clk(clk), .din(b9_gq3_0_QH_c), .dout(b9_gq3_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b9_gq3_s0_QH;
    always_ff @(posedge clk) b9_gq3_s0_QH <= b9_gq3_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l0_gen (.clk(clk), .A(b9_t0), .B(b9_t1), .QH(b9_gq3_s0_QH), .P(b9_l0_w));
    logic [61:0] b9_l0_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l0_a_i (.clk(clk), .din(b8_g0_o[0]), .dout(b9_l0_a));
    logic [44:0] b9_mq30_0_QH_c; assign b9_mq30_0_QH_c = b8_tag[48:4];
    logic [44:0] b9_mq30_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(45), .D(29)) b9_mq30_0_QH_i (.clk(clk), .din(b9_mq30_0_QH_c), .dout(b9_mq30_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b9_mq30_s0_QH;
    always_ff @(posedge clk) b9_mq30_s0_QH <= b9_mq30_0_QH;
    logic [61:0] b9_l0_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l0_mul (.clk(clk), .A(b9_l0_a), .B(b9_l0_w), .QH(b9_mq30_s0_QH), .P(b9_l0_p));
    logic [61:0] b9_l1_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l1_gen (.clk(clk), .A(b9_t2), .B(b9_t3), .QH(b9_gq3_s0_QH), .P(b9_l1_w));
    logic [61:0] b9_l1_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l1_a_i (.clk(clk), .din(b8_g0_o[1]), .dout(b9_l1_a));
    logic [61:0] b9_l1_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l1_mul (.clk(clk), .A(b9_l1_a), .B(b9_l1_w), .QH(b9_mq30_s0_QH), .P(b9_l1_p));
    logic [61:0] b9_l2_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l2_gen (.clk(clk), .A(b9_t4), .B(b9_t5), .QH(b9_gq3_s0_QH), .P(b9_l2_w));
    logic [61:0] b9_l2_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l2_a_i (.clk(clk), .din(b8_g0_o[2]), .dout(b9_l2_a));
    logic [61:0] b9_l2_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l2_mul (.clk(clk), .A(b9_l2_a), .B(b9_l2_w), .QH(b9_mq30_s0_QH), .P(b9_l2_p));
    logic [61:0] b9_l3_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l3_gen (.clk(clk), .A(b9_t6), .B(b9_t7), .QH(b9_gq3_s0_QH), .P(b9_l3_w));
    logic [61:0] b9_l3_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l3_a_i (.clk(clk), .din(b8_g0_o[3]), .dout(b9_l3_a));
    logic [61:0] b9_l3_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l3_mul (.clk(clk), .A(b9_l3_a), .B(b9_l3_w), .QH(b9_mq30_s0_QH), .P(b9_l3_p));
    logic [61:0] b9_l4_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b9_gq3_s1_QH;
    always_ff @(posedge clk) b9_gq3_s1_QH <= b9_gq3_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l4_gen (.clk(clk), .A(b9_t8), .B(b9_t9), .QH(b9_gq3_s1_QH), .P(b9_l4_w));
    logic [61:0] b9_l4_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l4_a_i (.clk(clk), .din(b8_g0_o[4]), .dout(b9_l4_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b9_mq30_s1_QH;
    always_ff @(posedge clk) b9_mq30_s1_QH <= b9_mq30_0_QH;
    logic [61:0] b9_l4_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l4_mul (.clk(clk), .A(b9_l4_a), .B(b9_l4_w), .QH(b9_mq30_s1_QH), .P(b9_l4_p));
    logic [61:0] b9_l5_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l5_gen (.clk(clk), .A(b9_t10), .B(b9_t11), .QH(b9_gq3_s1_QH), .P(b9_l5_w));
    logic [61:0] b9_l5_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l5_a_i (.clk(clk), .din(b8_g0_o[5]), .dout(b9_l5_a));
    logic [61:0] b9_l5_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l5_mul (.clk(clk), .A(b9_l5_a), .B(b9_l5_w), .QH(b9_mq30_s1_QH), .P(b9_l5_p));
    logic [61:0] b9_l6_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l6_gen (.clk(clk), .A(b9_t12), .B(b9_t13), .QH(b9_gq3_s1_QH), .P(b9_l6_w));
    logic [61:0] b9_l6_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l6_a_i (.clk(clk), .din(b8_g0_o[6]), .dout(b9_l6_a));
    logic [61:0] b9_l6_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l6_mul (.clk(clk), .A(b9_l6_a), .B(b9_l6_w), .QH(b9_mq30_s1_QH), .P(b9_l6_p));
    logic [61:0] b9_l7_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l7_gen (.clk(clk), .A(b9_t14), .B(b9_t15), .QH(b9_gq3_s1_QH), .P(b9_l7_w));
    logic [61:0] b9_l7_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l7_a_i (.clk(clk), .din(b8_g0_o[7]), .dout(b9_l7_a));
    logic [61:0] b9_l7_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l7_mul (.clk(clk), .A(b9_l7_a), .B(b9_l7_w), .QH(b9_mq30_s1_QH), .P(b9_l7_p));
    logic [61:0] b9_l8_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b9_gq3_s2_QH;
    always_ff @(posedge clk) b9_gq3_s2_QH <= b9_gq3_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l8_gen (.clk(clk), .A(b9_t16), .B(b9_t17), .QH(b9_gq3_s2_QH), .P(b9_l8_w));
    logic [61:0] b9_l8_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l8_a_i (.clk(clk), .din(b8_g0_o[8]), .dout(b9_l8_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b9_mq30_s2_QH;
    always_ff @(posedge clk) b9_mq30_s2_QH <= b9_mq30_0_QH;
    logic [61:0] b9_l8_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l8_mul (.clk(clk), .A(b9_l8_a), .B(b9_l8_w), .QH(b9_mq30_s2_QH), .P(b9_l8_p));
    logic [61:0] b9_l9_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l9_gen (.clk(clk), .A(b9_t18), .B(b9_t19), .QH(b9_gq3_s2_QH), .P(b9_l9_w));
    logic [61:0] b9_l9_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l9_a_i (.clk(clk), .din(b8_g0_o[9]), .dout(b9_l9_a));
    logic [61:0] b9_l9_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l9_mul (.clk(clk), .A(b9_l9_a), .B(b9_l9_w), .QH(b9_mq30_s2_QH), .P(b9_l9_p));
    logic [61:0] b9_l10_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l10_gen (.clk(clk), .A(b9_t20), .B(b9_t21), .QH(b9_gq3_s2_QH), .P(b9_l10_w));
    logic [61:0] b9_l10_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l10_a_i (.clk(clk), .din(b8_g0_o[10]), .dout(b9_l10_a));
    logic [61:0] b9_l10_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l10_mul (.clk(clk), .A(b9_l10_a), .B(b9_l10_w), .QH(b9_mq30_s2_QH), .P(b9_l10_p));
    logic [61:0] b9_l11_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l11_gen (.clk(clk), .A(b9_t22), .B(b9_t23), .QH(b9_gq3_s2_QH), .P(b9_l11_w));
    logic [61:0] b9_l11_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l11_a_i (.clk(clk), .din(b8_g0_o[11]), .dout(b9_l11_a));
    logic [61:0] b9_l11_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l11_mul (.clk(clk), .A(b9_l11_a), .B(b9_l11_w), .QH(b9_mq30_s2_QH), .P(b9_l11_p));
    logic [61:0] b9_l12_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b9_gq3_s3_QH;
    always_ff @(posedge clk) b9_gq3_s3_QH <= b9_gq3_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l12_gen (.clk(clk), .A(b9_t24), .B(b9_t25), .QH(b9_gq3_s3_QH), .P(b9_l12_w));
    logic [61:0] b9_l12_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l12_a_i (.clk(clk), .din(b8_g0_o[12]), .dout(b9_l12_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b9_mq30_s3_QH;
    always_ff @(posedge clk) b9_mq30_s3_QH <= b9_mq30_0_QH;
    logic [61:0] b9_l12_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l12_mul (.clk(clk), .A(b9_l12_a), .B(b9_l12_w), .QH(b9_mq30_s3_QH), .P(b9_l12_p));
    logic [61:0] b9_l13_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l13_gen (.clk(clk), .A(b9_t26), .B(b9_t27), .QH(b9_gq3_s3_QH), .P(b9_l13_w));
    logic [61:0] b9_l13_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l13_a_i (.clk(clk), .din(b8_g0_o[13]), .dout(b9_l13_a));
    logic [61:0] b9_l13_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l13_mul (.clk(clk), .A(b9_l13_a), .B(b9_l13_w), .QH(b9_mq30_s3_QH), .P(b9_l13_p));
    logic [61:0] b9_l14_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l14_gen (.clk(clk), .A(b9_t28), .B(b9_t29), .QH(b9_gq3_s3_QH), .P(b9_l14_w));
    logic [61:0] b9_l14_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l14_a_i (.clk(clk), .din(b8_g0_o[14]), .dout(b9_l14_a));
    logic [61:0] b9_l14_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l14_mul (.clk(clk), .A(b9_l14_a), .B(b9_l14_w), .QH(b9_mq30_s3_QH), .P(b9_l14_p));
    logic [61:0] b9_l15_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l15_gen (.clk(clk), .A(b9_t30), .B(b9_t31), .QH(b9_gq3_s3_QH), .P(b9_l15_w));
    logic [61:0] b9_l15_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l15_a_i (.clk(clk), .din(b8_g0_o[15]), .dout(b9_l15_a));
    logic [61:0] b9_l15_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l15_mul (.clk(clk), .A(b9_l15_a), .B(b9_l15_w), .QH(b9_mq30_s3_QH), .P(b9_l15_p));
    logic [61:0] b9_l16_w;
    logic [44:0] b9_gq3_1_QH_c; assign b9_gq3_1_QH_c = b8_tag[48:4];
    logic [44:0] b9_gq3_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(45), .D(2)) b9_gq3_1_QH_i (.clk(clk), .din(b9_gq3_1_QH_c), .dout(b9_gq3_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b9_gq3_s4_QH;
    always_ff @(posedge clk) b9_gq3_s4_QH <= b9_gq3_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l16_gen (.clk(clk), .A(b9_t32), .B(b9_t33), .QH(b9_gq3_s4_QH), .P(b9_l16_w));
    logic [61:0] b9_l16_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l16_a_i (.clk(clk), .din(b8_g0_o[16]), .dout(b9_l16_a));
    logic [44:0] b9_mq30_1_QH_c; assign b9_mq30_1_QH_c = b8_tag[48:4];
    logic [44:0] b9_mq30_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(45), .D(29)) b9_mq30_1_QH_i (.clk(clk), .din(b9_mq30_1_QH_c), .dout(b9_mq30_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b9_mq30_s4_QH;
    always_ff @(posedge clk) b9_mq30_s4_QH <= b9_mq30_1_QH;
    logic [61:0] b9_l16_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l16_mul (.clk(clk), .A(b9_l16_a), .B(b9_l16_w), .QH(b9_mq30_s4_QH), .P(b9_l16_p));
    logic [61:0] b9_l17_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l17_gen (.clk(clk), .A(b9_t34), .B(b9_t35), .QH(b9_gq3_s4_QH), .P(b9_l17_w));
    logic [61:0] b9_l17_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l17_a_i (.clk(clk), .din(b8_g0_o[17]), .dout(b9_l17_a));
    logic [61:0] b9_l17_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l17_mul (.clk(clk), .A(b9_l17_a), .B(b9_l17_w), .QH(b9_mq30_s4_QH), .P(b9_l17_p));
    logic [61:0] b9_l18_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l18_gen (.clk(clk), .A(b9_t36), .B(b9_t37), .QH(b9_gq3_s4_QH), .P(b9_l18_w));
    logic [61:0] b9_l18_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l18_a_i (.clk(clk), .din(b8_g0_o[18]), .dout(b9_l18_a));
    logic [61:0] b9_l18_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l18_mul (.clk(clk), .A(b9_l18_a), .B(b9_l18_w), .QH(b9_mq30_s4_QH), .P(b9_l18_p));
    logic [61:0] b9_l19_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l19_gen (.clk(clk), .A(b9_t38), .B(b9_t39), .QH(b9_gq3_s4_QH), .P(b9_l19_w));
    logic [61:0] b9_l19_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l19_a_i (.clk(clk), .din(b8_g0_o[19]), .dout(b9_l19_a));
    logic [61:0] b9_l19_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l19_mul (.clk(clk), .A(b9_l19_a), .B(b9_l19_w), .QH(b9_mq30_s4_QH), .P(b9_l19_p));
    logic [61:0] b9_l20_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b9_gq3_s5_QH;
    always_ff @(posedge clk) b9_gq3_s5_QH <= b9_gq3_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l20_gen (.clk(clk), .A(b9_t40), .B(b9_t41), .QH(b9_gq3_s5_QH), .P(b9_l20_w));
    logic [61:0] b9_l20_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l20_a_i (.clk(clk), .din(b8_g0_o[20]), .dout(b9_l20_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b9_mq30_s5_QH;
    always_ff @(posedge clk) b9_mq30_s5_QH <= b9_mq30_1_QH;
    logic [61:0] b9_l20_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l20_mul (.clk(clk), .A(b9_l20_a), .B(b9_l20_w), .QH(b9_mq30_s5_QH), .P(b9_l20_p));
    logic [61:0] b9_l21_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l21_gen (.clk(clk), .A(b9_t42), .B(b9_t43), .QH(b9_gq3_s5_QH), .P(b9_l21_w));
    logic [61:0] b9_l21_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l21_a_i (.clk(clk), .din(b8_g0_o[21]), .dout(b9_l21_a));
    logic [61:0] b9_l21_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l21_mul (.clk(clk), .A(b9_l21_a), .B(b9_l21_w), .QH(b9_mq30_s5_QH), .P(b9_l21_p));
    logic [61:0] b9_l22_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l22_gen (.clk(clk), .A(b9_t44), .B(b9_t45), .QH(b9_gq3_s5_QH), .P(b9_l22_w));
    logic [61:0] b9_l22_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l22_a_i (.clk(clk), .din(b8_g0_o[22]), .dout(b9_l22_a));
    logic [61:0] b9_l22_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l22_mul (.clk(clk), .A(b9_l22_a), .B(b9_l22_w), .QH(b9_mq30_s5_QH), .P(b9_l22_p));
    logic [61:0] b9_l23_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l23_gen (.clk(clk), .A(b9_t46), .B(b9_t47), .QH(b9_gq3_s5_QH), .P(b9_l23_w));
    logic [61:0] b9_l23_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l23_a_i (.clk(clk), .din(b8_g0_o[23]), .dout(b9_l23_a));
    logic [61:0] b9_l23_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l23_mul (.clk(clk), .A(b9_l23_a), .B(b9_l23_w), .QH(b9_mq30_s5_QH), .P(b9_l23_p));
    logic [61:0] b9_l24_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b9_gq3_s6_QH;
    always_ff @(posedge clk) b9_gq3_s6_QH <= b9_gq3_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l24_gen (.clk(clk), .A(b9_t48), .B(b9_t49), .QH(b9_gq3_s6_QH), .P(b9_l24_w));
    logic [61:0] b9_l24_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l24_a_i (.clk(clk), .din(b8_g0_o[24]), .dout(b9_l24_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b9_mq30_s6_QH;
    always_ff @(posedge clk) b9_mq30_s6_QH <= b9_mq30_1_QH;
    logic [61:0] b9_l24_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l24_mul (.clk(clk), .A(b9_l24_a), .B(b9_l24_w), .QH(b9_mq30_s6_QH), .P(b9_l24_p));
    logic [61:0] b9_l25_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l25_gen (.clk(clk), .A(b9_t50), .B(b9_t51), .QH(b9_gq3_s6_QH), .P(b9_l25_w));
    logic [61:0] b9_l25_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l25_a_i (.clk(clk), .din(b8_g0_o[25]), .dout(b9_l25_a));
    logic [61:0] b9_l25_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l25_mul (.clk(clk), .A(b9_l25_a), .B(b9_l25_w), .QH(b9_mq30_s6_QH), .P(b9_l25_p));
    logic [61:0] b9_l26_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l26_gen (.clk(clk), .A(b9_t52), .B(b9_t53), .QH(b9_gq3_s6_QH), .P(b9_l26_w));
    logic [61:0] b9_l26_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l26_a_i (.clk(clk), .din(b8_g0_o[26]), .dout(b9_l26_a));
    logic [61:0] b9_l26_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l26_mul (.clk(clk), .A(b9_l26_a), .B(b9_l26_w), .QH(b9_mq30_s6_QH), .P(b9_l26_p));
    logic [61:0] b9_l27_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l27_gen (.clk(clk), .A(b9_t54), .B(b9_t55), .QH(b9_gq3_s6_QH), .P(b9_l27_w));
    logic [61:0] b9_l27_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l27_a_i (.clk(clk), .din(b8_g0_o[27]), .dout(b9_l27_a));
    logic [61:0] b9_l27_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l27_mul (.clk(clk), .A(b9_l27_a), .B(b9_l27_w), .QH(b9_mq30_s6_QH), .P(b9_l27_p));
    logic [61:0] b9_l28_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b9_gq3_s7_QH;
    always_ff @(posedge clk) b9_gq3_s7_QH <= b9_gq3_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l28_gen (.clk(clk), .A(b9_t56), .B(b9_t57), .QH(b9_gq3_s7_QH), .P(b9_l28_w));
    logic [61:0] b9_l28_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l28_a_i (.clk(clk), .din(b8_g0_o[28]), .dout(b9_l28_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b9_mq30_s7_QH;
    always_ff @(posedge clk) b9_mq30_s7_QH <= b9_mq30_1_QH;
    logic [61:0] b9_l28_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l28_mul (.clk(clk), .A(b9_l28_a), .B(b9_l28_w), .QH(b9_mq30_s7_QH), .P(b9_l28_p));
    logic [61:0] b9_l29_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l29_gen (.clk(clk), .A(b9_t58), .B(b9_t59), .QH(b9_gq3_s7_QH), .P(b9_l29_w));
    logic [61:0] b9_l29_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l29_a_i (.clk(clk), .din(b8_g0_o[29]), .dout(b9_l29_a));
    logic [61:0] b9_l29_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l29_mul (.clk(clk), .A(b9_l29_a), .B(b9_l29_w), .QH(b9_mq30_s7_QH), .P(b9_l29_p));
    logic [61:0] b9_l30_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l30_gen (.clk(clk), .A(b9_t60), .B(b9_t61), .QH(b9_gq3_s7_QH), .P(b9_l30_w));
    logic [61:0] b9_l30_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l30_a_i (.clk(clk), .din(b8_g0_o[30]), .dout(b9_l30_a));
    logic [61:0] b9_l30_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l30_mul (.clk(clk), .A(b9_l30_a), .B(b9_l30_w), .QH(b9_mq30_s7_QH), .P(b9_l30_p));
    logic [61:0] b9_l31_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twgen b9_l31_gen (.clk(clk), .A(b9_t62), .B(b9_t63), .QH(b9_gq3_s7_QH), .P(b9_l31_w));
    logic [61:0] b9_l31_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b9_l31_a_i (.clk(clk), .din(b8_g0_o[31]), .dout(b9_l31_a));
    logic [61:0] b9_l31_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b9_l31_mul (.clk(clk), .A(b9_l31_a), .B(b9_l31_w), .QH(b9_mq30_s7_QH), .P(b9_l31_p));
    logic [56:0] b9_v_sr;
    always_ff @(posedge clk) b9_v_sr <= rst ? '0 : {b9_v_sr[55:0], b8_g0_v};
    logic b9_v; assign b9_v = b9_v_sr[56];
    logic [110:0] b9_tag;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(111), .D(57)) b9_tag_i (.clk(clk), .din(b8_tag), .dout(b9_tag));
    // block 10: pass 3, 1 x ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p2 (32-point), latency 126
    logic [61:0] b10_c0_y0, b10_c0_y1, b10_c0_y2, b10_c0_y3, b10_c0_y4, b10_c0_y5, b10_c0_y6, b10_c0_y7, b10_c0_y8, b10_c0_y9, b10_c0_y10, b10_c0_y11, b10_c0_y12, b10_c0_y13, b10_c0_y14, b10_c0_y15, b10_c0_y16, b10_c0_y17, b10_c0_y18, b10_c0_y19, b10_c0_y20, b10_c0_y21, b10_c0_y22, b10_c0_y23, b10_c0_y24, b10_c0_y25, b10_c0_y26, b10_c0_y27, b10_c0_y28, b10_c0_y29, b10_c0_y30, b10_c0_y31;
    logic b10_c0_v; logic [2:0] b10_c0_mi; logic b10_c0_di;
    logic b10_c0_lr, b10_c0_lw; (* equivalent_register_removal = "no" *) logic [61:0] b10_c0_ld;
    always_ff @(posedge clk) begin b10_c0_lr <= ld_r; b10_c0_lw <= ld_v && ld_iq >= 11'd289 && ld_iq < 11'd304; b10_c0_ld <= ld_d[61:0]; end
    logic [2:0] b10_c0_ls; always_ff @(posedge clk) b10_c0_ls <= ld_sl;
    logic b10_c0_ldr; always_ff @(posedge clk) b10_c0_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p2 b10_c0 (.clk(clk), .rst(rst), .in_valid(b9_v), .out_valid(b10_c0_v), .MIDX(b9_tag[3:1]), .midx_out(b10_c0_mi), .mq_QH(b9_tag[48:4]), .mq_QHALF(b9_tag[110:49]), .DIR(b9_tag[0]), .dir_out(b10_c0_di), .tw_rst(b10_c0_lr), .tw_wen(b10_c0_lw), .tw_wdata(b10_c0_ld), .tw_slot(b10_c0_ls), .tw_dir(b10_c0_ldr), .x_in_0(b9_l0_p), .x_in_1(b9_l1_p), .x_in_2(b9_l2_p), .x_in_3(b9_l3_p), .x_in_4(b9_l4_p), .x_in_5(b9_l5_p), .x_in_6(b9_l6_p), .x_in_7(b9_l7_p), .x_in_8(b9_l8_p), .x_in_9(b9_l9_p), .x_in_10(b9_l10_p), .x_in_11(b9_l11_p), .x_in_12(b9_l12_p), .x_in_13(b9_l13_p), .x_in_14(b9_l14_p), .x_in_15(b9_l15_p), .x_in_16(b9_l16_p), .x_in_17(b9_l17_p), .x_in_18(b9_l18_p), .x_in_19(b9_l19_p), .x_in_20(b9_l20_p), .x_in_21(b9_l21_p), .x_in_22(b9_l22_p), .x_in_23(b9_l23_p), .x_in_24(b9_l24_p), .x_in_25(b9_l25_p), .x_in_26(b9_l26_p), .x_in_27(b9_l27_p), .x_in_28(b9_l28_p), .x_in_29(b9_l29_p), .x_in_30(b9_l30_p), .x_in_31(b9_l31_p), .y_out_0(b10_c0_y0), .y_out_1(b10_c0_y1), .y_out_2(b10_c0_y2), .y_out_3(b10_c0_y3), .y_out_4(b10_c0_y4), .y_out_5(b10_c0_y5), .y_out_6(b10_c0_y6), .y_out_7(b10_c0_y7), .y_out_8(b10_c0_y8), .y_out_9(b10_c0_y9), .y_out_10(b10_c0_y10), .y_out_11(b10_c0_y11), .y_out_12(b10_c0_y12), .y_out_13(b10_c0_y13), .y_out_14(b10_c0_y14), .y_out_15(b10_c0_y15), .y_out_16(b10_c0_y16), .y_out_17(b10_c0_y17), .y_out_18(b10_c0_y18), .y_out_19(b10_c0_y19), .y_out_20(b10_c0_y20), .y_out_21(b10_c0_y21), .y_out_22(b10_c0_y22), .y_out_23(b10_c0_y23), .y_out_24(b10_c0_y24), .y_out_25(b10_c0_y25), .y_out_26(b10_c0_y26), .y_out_27(b10_c0_y27), .y_out_28(b10_c0_y28), .y_out_29(b10_c0_y29), .y_out_30(b10_c0_y30), .y_out_31(b10_c0_y31));
    logic [106:0] b10_cq0; assign b10_cq0 = b9_tag[110:4];
    logic [106:0] b10_cq;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(107), .D(126)) b10_cq_i (.clk(clk), .din(b10_cq0), .dout(b10_cq));
    logic [110:0] b10_tag; assign b10_tag = {b10_cq, b10_c0_mi, b10_c0_di};
    // block 11: twiddle stage 4, latency 30 (tables 3, multiplier 27)
    logic [10:0] b11_cnt;
    always_ff @(posedge clk) b11_cnt <= rst ? '0 : (b10_c0_v ? b11_cnt + 1'b1 : b11_cnt);
    logic [61:0] b11_t0;
    (* shreg_extract = "no" *) logic [61:0] b11_t0_q0;
    logic b11_t0_lwe; logic [3:0] b11_t0_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t0_lwd;
    always_ff @(posedge clk) begin b11_t0_lwe <= ld_v && ld_iq >= 11'd1776 && ld_iq < 11'd1777; b11_t0_lwa <= {ld_slq[2:0], ld_drq}; b11_t0_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab0 b11_t0_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t0_lwe), .wa(b11_t0_lwa), .wcol(1'b0), .wd(b11_t0_lwd), .q0(b11_t0_q0));
    always_ff @(posedge clk) begin b11_t0 <= b11_t0_q0; end
    logic [61:0] b11_t1;
    (* shreg_extract = "no" *) logic [61:0] b11_t1_q0;
    logic b11_t1_lwe; logic [3:0] b11_t1_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t1_lwd;
    always_ff @(posedge clk) begin b11_t1_lwe <= ld_v && ld_iq >= 11'd1777 && ld_iq < 11'd1778; b11_t1_lwa <= {ld_slq[2:0], ld_drq}; b11_t1_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab1 b11_t1_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t1_lwe), .wa(b11_t1_lwa), .wcol(1'b0), .wd(b11_t1_lwd), .q0(b11_t1_q0));
    always_ff @(posedge clk) begin b11_t1 <= b11_t1_q0; end
    logic [61:0] b11_t2;
    (* shreg_extract = "no" *) logic [61:0] b11_t2_q0;
    logic b11_t2_lwe; logic [3:0] b11_t2_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t2_lwd;
    always_ff @(posedge clk) begin b11_t2_lwe <= ld_v && ld_iq >= 11'd1778 && ld_iq < 11'd1779; b11_t2_lwa <= {ld_slq[2:0], ld_drq}; b11_t2_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab2 b11_t2_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t2_lwe), .wa(b11_t2_lwa), .wcol(1'b0), .wd(b11_t2_lwd), .q0(b11_t2_q0));
    always_ff @(posedge clk) begin b11_t2 <= b11_t2_q0; end
    logic [61:0] b11_t3;
    (* shreg_extract = "no" *) logic [61:0] b11_t3_q0;
    logic b11_t3_lwe; logic [3:0] b11_t3_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t3_lwd;
    always_ff @(posedge clk) begin b11_t3_lwe <= ld_v && ld_iq >= 11'd1779 && ld_iq < 11'd1780; b11_t3_lwa <= {ld_slq[2:0], ld_drq}; b11_t3_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab3 b11_t3_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t3_lwe), .wa(b11_t3_lwa), .wcol(1'b0), .wd(b11_t3_lwd), .q0(b11_t3_q0));
    always_ff @(posedge clk) begin b11_t3 <= b11_t3_q0; end
    logic [61:0] b11_t4;
    (* shreg_extract = "no" *) logic [61:0] b11_t4_q0;
    logic b11_t4_lwe; logic [3:0] b11_t4_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t4_lwd;
    always_ff @(posedge clk) begin b11_t4_lwe <= ld_v && ld_iq >= 11'd1780 && ld_iq < 11'd1781; b11_t4_lwa <= {ld_slq[2:0], ld_drq}; b11_t4_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab4 b11_t4_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t4_lwe), .wa(b11_t4_lwa), .wcol(1'b0), .wd(b11_t4_lwd), .q0(b11_t4_q0));
    always_ff @(posedge clk) begin b11_t4 <= b11_t4_q0; end
    logic [61:0] b11_t5;
    (* shreg_extract = "no" *) logic [61:0] b11_t5_q0;
    logic b11_t5_lwe; logic [3:0] b11_t5_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t5_lwd;
    always_ff @(posedge clk) begin b11_t5_lwe <= ld_v && ld_iq >= 11'd1781 && ld_iq < 11'd1782; b11_t5_lwa <= {ld_slq[2:0], ld_drq}; b11_t5_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab5 b11_t5_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t5_lwe), .wa(b11_t5_lwa), .wcol(1'b0), .wd(b11_t5_lwd), .q0(b11_t5_q0));
    always_ff @(posedge clk) begin b11_t5 <= b11_t5_q0; end
    logic [61:0] b11_t6;
    (* shreg_extract = "no" *) logic [61:0] b11_t6_q0;
    logic b11_t6_lwe; logic [3:0] b11_t6_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t6_lwd;
    always_ff @(posedge clk) begin b11_t6_lwe <= ld_v && ld_iq >= 11'd1782 && ld_iq < 11'd1783; b11_t6_lwa <= {ld_slq[2:0], ld_drq}; b11_t6_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab6 b11_t6_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t6_lwe), .wa(b11_t6_lwa), .wcol(1'b0), .wd(b11_t6_lwd), .q0(b11_t6_q0));
    always_ff @(posedge clk) begin b11_t6 <= b11_t6_q0; end
    logic [61:0] b11_t7;
    (* shreg_extract = "no" *) logic [61:0] b11_t7_q0;
    logic b11_t7_lwe; logic [3:0] b11_t7_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t7_lwd;
    always_ff @(posedge clk) begin b11_t7_lwe <= ld_v && ld_iq >= 11'd1783 && ld_iq < 11'd1784; b11_t7_lwa <= {ld_slq[2:0], ld_drq}; b11_t7_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab7 b11_t7_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t7_lwe), .wa(b11_t7_lwa), .wcol(1'b0), .wd(b11_t7_lwd), .q0(b11_t7_q0));
    always_ff @(posedge clk) begin b11_t7 <= b11_t7_q0; end
    logic [61:0] b11_t8;
    (* shreg_extract = "no" *) logic [61:0] b11_t8_q0;
    logic b11_t8_lwe; logic [3:0] b11_t8_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t8_lwd;
    always_ff @(posedge clk) begin b11_t8_lwe <= ld_v && ld_iq >= 11'd1784 && ld_iq < 11'd1785; b11_t8_lwa <= {ld_slq[2:0], ld_drq}; b11_t8_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab8 b11_t8_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t8_lwe), .wa(b11_t8_lwa), .wcol(1'b0), .wd(b11_t8_lwd), .q0(b11_t8_q0));
    always_ff @(posedge clk) begin b11_t8 <= b11_t8_q0; end
    logic [61:0] b11_t9;
    (* shreg_extract = "no" *) logic [61:0] b11_t9_q0;
    logic b11_t9_lwe; logic [3:0] b11_t9_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t9_lwd;
    always_ff @(posedge clk) begin b11_t9_lwe <= ld_v && ld_iq >= 11'd1785 && ld_iq < 11'd1786; b11_t9_lwa <= {ld_slq[2:0], ld_drq}; b11_t9_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab9 b11_t9_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t9_lwe), .wa(b11_t9_lwa), .wcol(1'b0), .wd(b11_t9_lwd), .q0(b11_t9_q0));
    always_ff @(posedge clk) begin b11_t9 <= b11_t9_q0; end
    logic [61:0] b11_t10;
    (* shreg_extract = "no" *) logic [61:0] b11_t10_q0;
    logic b11_t10_lwe; logic [3:0] b11_t10_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t10_lwd;
    always_ff @(posedge clk) begin b11_t10_lwe <= ld_v && ld_iq >= 11'd1786 && ld_iq < 11'd1787; b11_t10_lwa <= {ld_slq[2:0], ld_drq}; b11_t10_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab10 b11_t10_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t10_lwe), .wa(b11_t10_lwa), .wcol(1'b0), .wd(b11_t10_lwd), .q0(b11_t10_q0));
    always_ff @(posedge clk) begin b11_t10 <= b11_t10_q0; end
    logic [61:0] b11_t11;
    (* shreg_extract = "no" *) logic [61:0] b11_t11_q0;
    logic b11_t11_lwe; logic [3:0] b11_t11_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t11_lwd;
    always_ff @(posedge clk) begin b11_t11_lwe <= ld_v && ld_iq >= 11'd1787 && ld_iq < 11'd1788; b11_t11_lwa <= {ld_slq[2:0], ld_drq}; b11_t11_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab11 b11_t11_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t11_lwe), .wa(b11_t11_lwa), .wcol(1'b0), .wd(b11_t11_lwd), .q0(b11_t11_q0));
    always_ff @(posedge clk) begin b11_t11 <= b11_t11_q0; end
    logic [61:0] b11_t12;
    (* shreg_extract = "no" *) logic [61:0] b11_t12_q0;
    logic b11_t12_lwe; logic [3:0] b11_t12_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t12_lwd;
    always_ff @(posedge clk) begin b11_t12_lwe <= ld_v && ld_iq >= 11'd1788 && ld_iq < 11'd1789; b11_t12_lwa <= {ld_slq[2:0], ld_drq}; b11_t12_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab12 b11_t12_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t12_lwe), .wa(b11_t12_lwa), .wcol(1'b0), .wd(b11_t12_lwd), .q0(b11_t12_q0));
    always_ff @(posedge clk) begin b11_t12 <= b11_t12_q0; end
    logic [61:0] b11_t13;
    (* shreg_extract = "no" *) logic [61:0] b11_t13_q0;
    logic b11_t13_lwe; logic [3:0] b11_t13_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t13_lwd;
    always_ff @(posedge clk) begin b11_t13_lwe <= ld_v && ld_iq >= 11'd1789 && ld_iq < 11'd1790; b11_t13_lwa <= {ld_slq[2:0], ld_drq}; b11_t13_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab13 b11_t13_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t13_lwe), .wa(b11_t13_lwa), .wcol(1'b0), .wd(b11_t13_lwd), .q0(b11_t13_q0));
    always_ff @(posedge clk) begin b11_t13 <= b11_t13_q0; end
    logic [61:0] b11_t14;
    (* shreg_extract = "no" *) logic [61:0] b11_t14_q0;
    logic b11_t14_lwe; logic [3:0] b11_t14_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t14_lwd;
    always_ff @(posedge clk) begin b11_t14_lwe <= ld_v && ld_iq >= 11'd1790 && ld_iq < 11'd1791; b11_t14_lwa <= {ld_slq[2:0], ld_drq}; b11_t14_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab14 b11_t14_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t14_lwe), .wa(b11_t14_lwa), .wcol(1'b0), .wd(b11_t14_lwd), .q0(b11_t14_q0));
    always_ff @(posedge clk) begin b11_t14 <= b11_t14_q0; end
    logic [61:0] b11_t15;
    (* shreg_extract = "no" *) logic [61:0] b11_t15_q0;
    logic b11_t15_lwe; logic [3:0] b11_t15_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t15_lwd;
    always_ff @(posedge clk) begin b11_t15_lwe <= ld_v && ld_iq >= 11'd1791 && ld_iq < 11'd1792; b11_t15_lwa <= {ld_slq[2:0], ld_drq}; b11_t15_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab15 b11_t15_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t15_lwe), .wa(b11_t15_lwa), .wcol(1'b0), .wd(b11_t15_lwd), .q0(b11_t15_q0));
    always_ff @(posedge clk) begin b11_t15 <= b11_t15_q0; end
    logic [61:0] b11_t16;
    (* shreg_extract = "no" *) logic [61:0] b11_t16_q0;
    logic b11_t16_lwe; logic [3:0] b11_t16_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t16_lwd;
    always_ff @(posedge clk) begin b11_t16_lwe <= ld_v && ld_iq >= 11'd1792 && ld_iq < 11'd1793; b11_t16_lwa <= {ld_slq[2:0], ld_drq}; b11_t16_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab16 b11_t16_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t16_lwe), .wa(b11_t16_lwa), .wcol(1'b0), .wd(b11_t16_lwd), .q0(b11_t16_q0));
    always_ff @(posedge clk) begin b11_t16 <= b11_t16_q0; end
    logic [61:0] b11_t17;
    (* shreg_extract = "no" *) logic [61:0] b11_t17_q0;
    logic b11_t17_lwe; logic [3:0] b11_t17_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t17_lwd;
    always_ff @(posedge clk) begin b11_t17_lwe <= ld_v && ld_iq >= 11'd1793 && ld_iq < 11'd1794; b11_t17_lwa <= {ld_slq[2:0], ld_drq}; b11_t17_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab17 b11_t17_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t17_lwe), .wa(b11_t17_lwa), .wcol(1'b0), .wd(b11_t17_lwd), .q0(b11_t17_q0));
    always_ff @(posedge clk) begin b11_t17 <= b11_t17_q0; end
    logic [61:0] b11_t18;
    (* shreg_extract = "no" *) logic [61:0] b11_t18_q0;
    logic b11_t18_lwe; logic [3:0] b11_t18_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t18_lwd;
    always_ff @(posedge clk) begin b11_t18_lwe <= ld_v && ld_iq >= 11'd1794 && ld_iq < 11'd1795; b11_t18_lwa <= {ld_slq[2:0], ld_drq}; b11_t18_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab18 b11_t18_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t18_lwe), .wa(b11_t18_lwa), .wcol(1'b0), .wd(b11_t18_lwd), .q0(b11_t18_q0));
    always_ff @(posedge clk) begin b11_t18 <= b11_t18_q0; end
    logic [61:0] b11_t19;
    (* shreg_extract = "no" *) logic [61:0] b11_t19_q0;
    logic b11_t19_lwe; logic [3:0] b11_t19_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t19_lwd;
    always_ff @(posedge clk) begin b11_t19_lwe <= ld_v && ld_iq >= 11'd1795 && ld_iq < 11'd1796; b11_t19_lwa <= {ld_slq[2:0], ld_drq}; b11_t19_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab19 b11_t19_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t19_lwe), .wa(b11_t19_lwa), .wcol(1'b0), .wd(b11_t19_lwd), .q0(b11_t19_q0));
    always_ff @(posedge clk) begin b11_t19 <= b11_t19_q0; end
    logic [61:0] b11_t20;
    (* shreg_extract = "no" *) logic [61:0] b11_t20_q0;
    logic b11_t20_lwe; logic [3:0] b11_t20_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t20_lwd;
    always_ff @(posedge clk) begin b11_t20_lwe <= ld_v && ld_iq >= 11'd1796 && ld_iq < 11'd1797; b11_t20_lwa <= {ld_slq[2:0], ld_drq}; b11_t20_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab20 b11_t20_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t20_lwe), .wa(b11_t20_lwa), .wcol(1'b0), .wd(b11_t20_lwd), .q0(b11_t20_q0));
    always_ff @(posedge clk) begin b11_t20 <= b11_t20_q0; end
    logic [61:0] b11_t21;
    (* shreg_extract = "no" *) logic [61:0] b11_t21_q0;
    logic b11_t21_lwe; logic [3:0] b11_t21_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t21_lwd;
    always_ff @(posedge clk) begin b11_t21_lwe <= ld_v && ld_iq >= 11'd1797 && ld_iq < 11'd1798; b11_t21_lwa <= {ld_slq[2:0], ld_drq}; b11_t21_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab21 b11_t21_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t21_lwe), .wa(b11_t21_lwa), .wcol(1'b0), .wd(b11_t21_lwd), .q0(b11_t21_q0));
    always_ff @(posedge clk) begin b11_t21 <= b11_t21_q0; end
    logic [61:0] b11_t22;
    (* shreg_extract = "no" *) logic [61:0] b11_t22_q0;
    logic b11_t22_lwe; logic [3:0] b11_t22_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t22_lwd;
    always_ff @(posedge clk) begin b11_t22_lwe <= ld_v && ld_iq >= 11'd1798 && ld_iq < 11'd1799; b11_t22_lwa <= {ld_slq[2:0], ld_drq}; b11_t22_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab22 b11_t22_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t22_lwe), .wa(b11_t22_lwa), .wcol(1'b0), .wd(b11_t22_lwd), .q0(b11_t22_q0));
    always_ff @(posedge clk) begin b11_t22 <= b11_t22_q0; end
    logic [61:0] b11_t23;
    (* shreg_extract = "no" *) logic [61:0] b11_t23_q0;
    logic b11_t23_lwe; logic [3:0] b11_t23_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t23_lwd;
    always_ff @(posedge clk) begin b11_t23_lwe <= ld_v && ld_iq >= 11'd1799 && ld_iq < 11'd1800; b11_t23_lwa <= {ld_slq[2:0], ld_drq}; b11_t23_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab23 b11_t23_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t23_lwe), .wa(b11_t23_lwa), .wcol(1'b0), .wd(b11_t23_lwd), .q0(b11_t23_q0));
    always_ff @(posedge clk) begin b11_t23 <= b11_t23_q0; end
    logic [61:0] b11_t24;
    (* shreg_extract = "no" *) logic [61:0] b11_t24_q0;
    logic b11_t24_lwe; logic [3:0] b11_t24_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t24_lwd;
    always_ff @(posedge clk) begin b11_t24_lwe <= ld_v && ld_iq >= 11'd1800 && ld_iq < 11'd1801; b11_t24_lwa <= {ld_slq[2:0], ld_drq}; b11_t24_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab24 b11_t24_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t24_lwe), .wa(b11_t24_lwa), .wcol(1'b0), .wd(b11_t24_lwd), .q0(b11_t24_q0));
    always_ff @(posedge clk) begin b11_t24 <= b11_t24_q0; end
    logic [61:0] b11_t25;
    (* shreg_extract = "no" *) logic [61:0] b11_t25_q0;
    logic b11_t25_lwe; logic [3:0] b11_t25_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t25_lwd;
    always_ff @(posedge clk) begin b11_t25_lwe <= ld_v && ld_iq >= 11'd1801 && ld_iq < 11'd1802; b11_t25_lwa <= {ld_slq[2:0], ld_drq}; b11_t25_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab25 b11_t25_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t25_lwe), .wa(b11_t25_lwa), .wcol(1'b0), .wd(b11_t25_lwd), .q0(b11_t25_q0));
    always_ff @(posedge clk) begin b11_t25 <= b11_t25_q0; end
    logic [61:0] b11_t26;
    (* shreg_extract = "no" *) logic [61:0] b11_t26_q0;
    logic b11_t26_lwe; logic [3:0] b11_t26_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t26_lwd;
    always_ff @(posedge clk) begin b11_t26_lwe <= ld_v && ld_iq >= 11'd1802 && ld_iq < 11'd1803; b11_t26_lwa <= {ld_slq[2:0], ld_drq}; b11_t26_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab26 b11_t26_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t26_lwe), .wa(b11_t26_lwa), .wcol(1'b0), .wd(b11_t26_lwd), .q0(b11_t26_q0));
    always_ff @(posedge clk) begin b11_t26 <= b11_t26_q0; end
    logic [61:0] b11_t27;
    (* shreg_extract = "no" *) logic [61:0] b11_t27_q0;
    logic b11_t27_lwe; logic [3:0] b11_t27_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t27_lwd;
    always_ff @(posedge clk) begin b11_t27_lwe <= ld_v && ld_iq >= 11'd1803 && ld_iq < 11'd1804; b11_t27_lwa <= {ld_slq[2:0], ld_drq}; b11_t27_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab27 b11_t27_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t27_lwe), .wa(b11_t27_lwa), .wcol(1'b0), .wd(b11_t27_lwd), .q0(b11_t27_q0));
    always_ff @(posedge clk) begin b11_t27 <= b11_t27_q0; end
    logic [61:0] b11_t28;
    (* shreg_extract = "no" *) logic [61:0] b11_t28_q0;
    logic b11_t28_lwe; logic [3:0] b11_t28_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t28_lwd;
    always_ff @(posedge clk) begin b11_t28_lwe <= ld_v && ld_iq >= 11'd1804 && ld_iq < 11'd1805; b11_t28_lwa <= {ld_slq[2:0], ld_drq}; b11_t28_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab28 b11_t28_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t28_lwe), .wa(b11_t28_lwa), .wcol(1'b0), .wd(b11_t28_lwd), .q0(b11_t28_q0));
    always_ff @(posedge clk) begin b11_t28 <= b11_t28_q0; end
    logic [61:0] b11_t29;
    (* shreg_extract = "no" *) logic [61:0] b11_t29_q0;
    logic b11_t29_lwe; logic [3:0] b11_t29_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t29_lwd;
    always_ff @(posedge clk) begin b11_t29_lwe <= ld_v && ld_iq >= 11'd1805 && ld_iq < 11'd1806; b11_t29_lwa <= {ld_slq[2:0], ld_drq}; b11_t29_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab29 b11_t29_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t29_lwe), .wa(b11_t29_lwa), .wcol(1'b0), .wd(b11_t29_lwd), .q0(b11_t29_q0));
    always_ff @(posedge clk) begin b11_t29 <= b11_t29_q0; end
    logic [61:0] b11_t30;
    (* shreg_extract = "no" *) logic [61:0] b11_t30_q0;
    logic b11_t30_lwe; logic [3:0] b11_t30_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b11_t30_lwd;
    always_ff @(posedge clk) begin b11_t30_lwe <= ld_v && ld_iq >= 11'd1806 && ld_iq < 11'd1807; b11_t30_lwa <= {ld_slq[2:0], ld_drq}; b11_t30_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw4_tab30 b11_t30_i (.clk(clk), .addr({b10_tag[3:1], b10_tag[0]}), .we(b11_t30_lwe), .wa(b11_t30_lwa), .wcol(1'b0), .wd(b11_t30_lwd), .q0(b11_t30_q0));
    always_ff @(posedge clk) begin b11_t30 <= b11_t30_q0; end
    logic [61:0] b11_l0_byp;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(30)) b11_l0_byp_i (.clk(clk), .din(b10_c0_y0), .dout(b11_l0_byp));
    logic [61:0] b11_l1_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l1_a_i (.clk(clk), .din(b10_c0_y1), .dout(b11_l1_a));
    logic [44:0] b11_mq3_0_QH_c; assign b11_mq3_0_QH_c = b10_tag[48:4];
    logic [44:0] b11_mq3_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(45), .D(2)) b11_mq3_0_QH_i (.clk(clk), .din(b11_mq3_0_QH_c), .dout(b11_mq3_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b11_mq3_s0_QH;
    always_ff @(posedge clk) b11_mq3_s0_QH <= b11_mq3_0_QH;
    logic [61:0] b11_l1_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l1_mul (.clk(clk), .A(b11_l1_a), .B(b11_t0), .QH(b11_mq3_s0_QH), .P(b11_l1_p));
    logic [61:0] b11_l2_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l2_a_i (.clk(clk), .din(b10_c0_y2), .dout(b11_l2_a));
    logic [61:0] b11_l2_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l2_mul (.clk(clk), .A(b11_l2_a), .B(b11_t1), .QH(b11_mq3_s0_QH), .P(b11_l2_p));
    logic [61:0] b11_l3_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l3_a_i (.clk(clk), .din(b10_c0_y3), .dout(b11_l3_a));
    logic [61:0] b11_l3_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l3_mul (.clk(clk), .A(b11_l3_a), .B(b11_t2), .QH(b11_mq3_s0_QH), .P(b11_l3_p));
    logic [61:0] b11_l4_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l4_a_i (.clk(clk), .din(b10_c0_y4), .dout(b11_l4_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b11_mq3_s1_QH;
    always_ff @(posedge clk) b11_mq3_s1_QH <= b11_mq3_0_QH;
    logic [61:0] b11_l4_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l4_mul (.clk(clk), .A(b11_l4_a), .B(b11_t3), .QH(b11_mq3_s1_QH), .P(b11_l4_p));
    logic [61:0] b11_l5_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l5_a_i (.clk(clk), .din(b10_c0_y5), .dout(b11_l5_a));
    logic [61:0] b11_l5_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l5_mul (.clk(clk), .A(b11_l5_a), .B(b11_t4), .QH(b11_mq3_s1_QH), .P(b11_l5_p));
    logic [61:0] b11_l6_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l6_a_i (.clk(clk), .din(b10_c0_y6), .dout(b11_l6_a));
    logic [61:0] b11_l6_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l6_mul (.clk(clk), .A(b11_l6_a), .B(b11_t5), .QH(b11_mq3_s1_QH), .P(b11_l6_p));
    logic [61:0] b11_l7_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l7_a_i (.clk(clk), .din(b10_c0_y7), .dout(b11_l7_a));
    logic [61:0] b11_l7_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l7_mul (.clk(clk), .A(b11_l7_a), .B(b11_t6), .QH(b11_mq3_s1_QH), .P(b11_l7_p));
    logic [61:0] b11_l8_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l8_a_i (.clk(clk), .din(b10_c0_y8), .dout(b11_l8_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b11_mq3_s2_QH;
    always_ff @(posedge clk) b11_mq3_s2_QH <= b11_mq3_0_QH;
    logic [61:0] b11_l8_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l8_mul (.clk(clk), .A(b11_l8_a), .B(b11_t7), .QH(b11_mq3_s2_QH), .P(b11_l8_p));
    logic [61:0] b11_l9_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l9_a_i (.clk(clk), .din(b10_c0_y9), .dout(b11_l9_a));
    logic [61:0] b11_l9_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l9_mul (.clk(clk), .A(b11_l9_a), .B(b11_t8), .QH(b11_mq3_s2_QH), .P(b11_l9_p));
    logic [61:0] b11_l10_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l10_a_i (.clk(clk), .din(b10_c0_y10), .dout(b11_l10_a));
    logic [61:0] b11_l10_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l10_mul (.clk(clk), .A(b11_l10_a), .B(b11_t9), .QH(b11_mq3_s2_QH), .P(b11_l10_p));
    logic [61:0] b11_l11_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l11_a_i (.clk(clk), .din(b10_c0_y11), .dout(b11_l11_a));
    logic [61:0] b11_l11_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l11_mul (.clk(clk), .A(b11_l11_a), .B(b11_t10), .QH(b11_mq3_s2_QH), .P(b11_l11_p));
    logic [61:0] b11_l12_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l12_a_i (.clk(clk), .din(b10_c0_y12), .dout(b11_l12_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b11_mq3_s3_QH;
    always_ff @(posedge clk) b11_mq3_s3_QH <= b11_mq3_0_QH;
    logic [61:0] b11_l12_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l12_mul (.clk(clk), .A(b11_l12_a), .B(b11_t11), .QH(b11_mq3_s3_QH), .P(b11_l12_p));
    logic [61:0] b11_l13_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l13_a_i (.clk(clk), .din(b10_c0_y13), .dout(b11_l13_a));
    logic [61:0] b11_l13_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l13_mul (.clk(clk), .A(b11_l13_a), .B(b11_t12), .QH(b11_mq3_s3_QH), .P(b11_l13_p));
    logic [61:0] b11_l14_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l14_a_i (.clk(clk), .din(b10_c0_y14), .dout(b11_l14_a));
    logic [61:0] b11_l14_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l14_mul (.clk(clk), .A(b11_l14_a), .B(b11_t13), .QH(b11_mq3_s3_QH), .P(b11_l14_p));
    logic [61:0] b11_l15_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l15_a_i (.clk(clk), .din(b10_c0_y15), .dout(b11_l15_a));
    logic [61:0] b11_l15_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l15_mul (.clk(clk), .A(b11_l15_a), .B(b11_t14), .QH(b11_mq3_s3_QH), .P(b11_l15_p));
    logic [61:0] b11_l16_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l16_a_i (.clk(clk), .din(b10_c0_y16), .dout(b11_l16_a));
    logic [44:0] b11_mq3_1_QH_c; assign b11_mq3_1_QH_c = b10_tag[48:4];
    logic [44:0] b11_mq3_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(45), .D(2)) b11_mq3_1_QH_i (.clk(clk), .din(b11_mq3_1_QH_c), .dout(b11_mq3_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b11_mq3_s4_QH;
    always_ff @(posedge clk) b11_mq3_s4_QH <= b11_mq3_1_QH;
    logic [61:0] b11_l16_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l16_mul (.clk(clk), .A(b11_l16_a), .B(b11_t15), .QH(b11_mq3_s4_QH), .P(b11_l16_p));
    logic [61:0] b11_l17_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l17_a_i (.clk(clk), .din(b10_c0_y17), .dout(b11_l17_a));
    logic [61:0] b11_l17_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l17_mul (.clk(clk), .A(b11_l17_a), .B(b11_t16), .QH(b11_mq3_s4_QH), .P(b11_l17_p));
    logic [61:0] b11_l18_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l18_a_i (.clk(clk), .din(b10_c0_y18), .dout(b11_l18_a));
    logic [61:0] b11_l18_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l18_mul (.clk(clk), .A(b11_l18_a), .B(b11_t17), .QH(b11_mq3_s4_QH), .P(b11_l18_p));
    logic [61:0] b11_l19_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l19_a_i (.clk(clk), .din(b10_c0_y19), .dout(b11_l19_a));
    logic [61:0] b11_l19_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l19_mul (.clk(clk), .A(b11_l19_a), .B(b11_t18), .QH(b11_mq3_s4_QH), .P(b11_l19_p));
    logic [61:0] b11_l20_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l20_a_i (.clk(clk), .din(b10_c0_y20), .dout(b11_l20_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b11_mq3_s5_QH;
    always_ff @(posedge clk) b11_mq3_s5_QH <= b11_mq3_1_QH;
    logic [61:0] b11_l20_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l20_mul (.clk(clk), .A(b11_l20_a), .B(b11_t19), .QH(b11_mq3_s5_QH), .P(b11_l20_p));
    logic [61:0] b11_l21_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l21_a_i (.clk(clk), .din(b10_c0_y21), .dout(b11_l21_a));
    logic [61:0] b11_l21_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l21_mul (.clk(clk), .A(b11_l21_a), .B(b11_t20), .QH(b11_mq3_s5_QH), .P(b11_l21_p));
    logic [61:0] b11_l22_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l22_a_i (.clk(clk), .din(b10_c0_y22), .dout(b11_l22_a));
    logic [61:0] b11_l22_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l22_mul (.clk(clk), .A(b11_l22_a), .B(b11_t21), .QH(b11_mq3_s5_QH), .P(b11_l22_p));
    logic [61:0] b11_l23_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l23_a_i (.clk(clk), .din(b10_c0_y23), .dout(b11_l23_a));
    logic [61:0] b11_l23_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l23_mul (.clk(clk), .A(b11_l23_a), .B(b11_t22), .QH(b11_mq3_s5_QH), .P(b11_l23_p));
    logic [61:0] b11_l24_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l24_a_i (.clk(clk), .din(b10_c0_y24), .dout(b11_l24_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b11_mq3_s6_QH;
    always_ff @(posedge clk) b11_mq3_s6_QH <= b11_mq3_1_QH;
    logic [61:0] b11_l24_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l24_mul (.clk(clk), .A(b11_l24_a), .B(b11_t23), .QH(b11_mq3_s6_QH), .P(b11_l24_p));
    logic [61:0] b11_l25_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l25_a_i (.clk(clk), .din(b10_c0_y25), .dout(b11_l25_a));
    logic [61:0] b11_l25_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l25_mul (.clk(clk), .A(b11_l25_a), .B(b11_t24), .QH(b11_mq3_s6_QH), .P(b11_l25_p));
    logic [61:0] b11_l26_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l26_a_i (.clk(clk), .din(b10_c0_y26), .dout(b11_l26_a));
    logic [61:0] b11_l26_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l26_mul (.clk(clk), .A(b11_l26_a), .B(b11_t25), .QH(b11_mq3_s6_QH), .P(b11_l26_p));
    logic [61:0] b11_l27_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l27_a_i (.clk(clk), .din(b10_c0_y27), .dout(b11_l27_a));
    logic [61:0] b11_l27_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l27_mul (.clk(clk), .A(b11_l27_a), .B(b11_t26), .QH(b11_mq3_s6_QH), .P(b11_l27_p));
    logic [61:0] b11_l28_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l28_a_i (.clk(clk), .din(b10_c0_y28), .dout(b11_l28_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b11_mq3_s7_QH;
    always_ff @(posedge clk) b11_mq3_s7_QH <= b11_mq3_1_QH;
    logic [61:0] b11_l28_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l28_mul (.clk(clk), .A(b11_l28_a), .B(b11_t27), .QH(b11_mq3_s7_QH), .P(b11_l28_p));
    logic [61:0] b11_l29_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l29_a_i (.clk(clk), .din(b10_c0_y29), .dout(b11_l29_a));
    logic [61:0] b11_l29_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l29_mul (.clk(clk), .A(b11_l29_a), .B(b11_t28), .QH(b11_mq3_s7_QH), .P(b11_l29_p));
    logic [61:0] b11_l30_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l30_a_i (.clk(clk), .din(b10_c0_y30), .dout(b11_l30_a));
    logic [61:0] b11_l30_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l30_mul (.clk(clk), .A(b11_l30_a), .B(b11_t29), .QH(b11_mq3_s7_QH), .P(b11_l30_p));
    logic [61:0] b11_l31_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(62), .D(3)) b11_l31_a_i (.clk(clk), .din(b10_c0_y31), .dout(b11_l31_a));
    logic [61:0] b11_l31_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul b11_l31_mul (.clk(clk), .A(b11_l31_a), .B(b11_t30), .QH(b11_mq3_s7_QH), .P(b11_l31_p));
    logic [29:0] b11_v_sr;
    always_ff @(posedge clk) b11_v_sr <= rst ? '0 : {b11_v_sr[28:0], b10_c0_v};
    logic b11_v; assign b11_v = b11_v_sr[29];
    logic [110:0] b11_tag;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_dly_c #(.W(111), .D(30)) b11_tag_i (.clk(clk), .din(b10_tag), .dout(b11_tag));
    assign out_valid = b11_v;
    assign midx_out = b11_tag[3:1];
    assign dir_out = b11_tag[0];
    assign y_out_0 = b11_l0_byp;
    assign y_out_1 = b11_l1_p;
    assign y_out_2 = b11_l2_p;
    assign y_out_3 = b11_l3_p;
    assign y_out_4 = b11_l4_p;
    assign y_out_5 = b11_l5_p;
    assign y_out_6 = b11_l6_p;
    assign y_out_7 = b11_l7_p;
    assign y_out_8 = b11_l8_p;
    assign y_out_9 = b11_l9_p;
    assign y_out_10 = b11_l10_p;
    assign y_out_11 = b11_l11_p;
    assign y_out_12 = b11_l12_p;
    assign y_out_13 = b11_l13_p;
    assign y_out_14 = b11_l14_p;
    assign y_out_15 = b11_l15_p;
    assign y_out_16 = b11_l16_p;
    assign y_out_17 = b11_l17_p;
    assign y_out_18 = b11_l18_p;
    assign y_out_19 = b11_l19_p;
    assign y_out_20 = b11_l20_p;
    assign y_out_21 = b11_l21_p;
    assign y_out_22 = b11_l22_p;
    assign y_out_23 = b11_l23_p;
    assign y_out_24 = b11_l24_p;
    assign y_out_25 = b11_l25_p;
    assign y_out_26 = b11_l26_p;
    assign y_out_27 = b11_l27_p;
    assign y_out_28 = b11_l28_p;
    assign y_out_29 = b11_l29_p;
    assign y_out_30 = b11_l30_p;
    assign y_out_31 = b11_l31_p;
endmodule
