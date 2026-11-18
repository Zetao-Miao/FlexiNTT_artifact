`timescale 1ns / 1ps
// ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k: multi-step NTT, N=65536, sizes [4, 16, 32, 32], 32 lanes, frame 2048 cycles, latency 3662, 5 moduli (MIDX per polynomial)
module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k (
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
    // load port: one word per ld_wen after ld_rst, 1822 words: the sub-NTT images, then the tables
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
    // block 0: pass 0, 8 x ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p0 (4-point), latency 59
    logic [61:0] b0_c0_y0, b0_c0_y1, b0_c0_y2, b0_c0_y3;
    logic b0_c0_v; logic [2:0] b0_c0_mi; logic b0_c0_di;
    logic b0_c0_lr, b0_c0_lw; (* equivalent_register_removal = "no" *) logic [61:0] b0_c0_ld;
    always_ff @(posedge clk) begin b0_c0_lr <= ld_r; b0_c0_lw <= ld_v && ld_iq >= 11'd0 && ld_iq < 11'd3; b0_c0_ld <= ld_d[61:0]; end
    logic [2:0] b0_c0_ls; always_ff @(posedge clk) b0_c0_ls <= ld_sl;
    logic b0_c0_ldr; always_ff @(posedge clk) b0_c0_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p0 b0_c0 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c0_v), .MIDX(g0[3:1]), .midx_out(b0_c0_mi), .mq_QH(g0[48:4]), .mq_QHALF(g0[110:49]), .DIR(g0[0]), .dir_out(b0_c0_di), .tw_rst(b0_c0_lr), .tw_wen(b0_c0_lw), .tw_wdata(b0_c0_ld), .tw_slot(b0_c0_ls), .tw_dir(b0_c0_ldr), .x_in_0(d0_0), .x_in_1(d0_8), .x_in_2(d0_16), .x_in_3(d0_24), .y_out_0(b0_c0_y0), .y_out_1(b0_c0_y1), .y_out_2(b0_c0_y2), .y_out_3(b0_c0_y3));
    logic [61:0] b0_c1_y0, b0_c1_y1, b0_c1_y2, b0_c1_y3;
    logic b0_c1_v; logic [2:0] b0_c1_mi; logic b0_c1_di;
    logic b0_c1_lr, b0_c1_lw; (* equivalent_register_removal = "no" *) logic [61:0] b0_c1_ld;
    always_ff @(posedge clk) begin b0_c1_lr <= ld_r; b0_c1_lw <= ld_v && ld_iq >= 11'd0 && ld_iq < 11'd3; b0_c1_ld <= ld_d[61:0]; end
    logic [2:0] b0_c1_ls; always_ff @(posedge clk) b0_c1_ls <= ld_sl;
    logic b0_c1_ldr; always_ff @(posedge clk) b0_c1_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p0 b0_c1 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c1_v), .MIDX(g0[3:1]), .midx_out(b0_c1_mi), .mq_QH(g0[48:4]), .mq_QHALF(g0[110:49]), .DIR(g0[0]), .dir_out(b0_c1_di), .tw_rst(b0_c1_lr), .tw_wen(b0_c1_lw), .tw_wdata(b0_c1_ld), .tw_slot(b0_c1_ls), .tw_dir(b0_c1_ldr), .x_in_0(d0_1), .x_in_1(d0_9), .x_in_2(d0_17), .x_in_3(d0_25), .y_out_0(b0_c1_y0), .y_out_1(b0_c1_y1), .y_out_2(b0_c1_y2), .y_out_3(b0_c1_y3));
    logic [61:0] b0_c2_y0, b0_c2_y1, b0_c2_y2, b0_c2_y3;
    logic b0_c2_v; logic [2:0] b0_c2_mi; logic b0_c2_di;
    logic b0_c2_lr, b0_c2_lw; (* equivalent_register_removal = "no" *) logic [61:0] b0_c2_ld;
    always_ff @(posedge clk) begin b0_c2_lr <= ld_r; b0_c2_lw <= ld_v && ld_iq >= 11'd0 && ld_iq < 11'd3; b0_c2_ld <= ld_d[61:0]; end
    logic [2:0] b0_c2_ls; always_ff @(posedge clk) b0_c2_ls <= ld_sl;
    logic b0_c2_ldr; always_ff @(posedge clk) b0_c2_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p0 b0_c2 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c2_v), .MIDX(g0[3:1]), .midx_out(b0_c2_mi), .mq_QH(g0[48:4]), .mq_QHALF(g0[110:49]), .DIR(g0[0]), .dir_out(b0_c2_di), .tw_rst(b0_c2_lr), .tw_wen(b0_c2_lw), .tw_wdata(b0_c2_ld), .tw_slot(b0_c2_ls), .tw_dir(b0_c2_ldr), .x_in_0(d0_2), .x_in_1(d0_10), .x_in_2(d0_18), .x_in_3(d0_26), .y_out_0(b0_c2_y0), .y_out_1(b0_c2_y1), .y_out_2(b0_c2_y2), .y_out_3(b0_c2_y3));
    logic [61:0] b0_c3_y0, b0_c3_y1, b0_c3_y2, b0_c3_y3;
    logic b0_c3_v; logic [2:0] b0_c3_mi; logic b0_c3_di;
    logic b0_c3_lr, b0_c3_lw; (* equivalent_register_removal = "no" *) logic [61:0] b0_c3_ld;
    always_ff @(posedge clk) begin b0_c3_lr <= ld_r; b0_c3_lw <= ld_v && ld_iq >= 11'd0 && ld_iq < 11'd3; b0_c3_ld <= ld_d[61:0]; end
    logic [2:0] b0_c3_ls; always_ff @(posedge clk) b0_c3_ls <= ld_sl;
    logic b0_c3_ldr; always_ff @(posedge clk) b0_c3_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p0 b0_c3 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c3_v), .MIDX(g0[3:1]), .midx_out(b0_c3_mi), .mq_QH(g0[48:4]), .mq_QHALF(g0[110:49]), .DIR(g0[0]), .dir_out(b0_c3_di), .tw_rst(b0_c3_lr), .tw_wen(b0_c3_lw), .tw_wdata(b0_c3_ld), .tw_slot(b0_c3_ls), .tw_dir(b0_c3_ldr), .x_in_0(d0_3), .x_in_1(d0_11), .x_in_2(d0_19), .x_in_3(d0_27), .y_out_0(b0_c3_y0), .y_out_1(b0_c3_y1), .y_out_2(b0_c3_y2), .y_out_3(b0_c3_y3));
    logic [61:0] b0_c4_y0, b0_c4_y1, b0_c4_y2, b0_c4_y3;
    logic b0_c4_v; logic [2:0] b0_c4_mi; logic b0_c4_di;
    logic b0_c4_lr, b0_c4_lw; (* equivalent_register_removal = "no" *) logic [61:0] b0_c4_ld;
    always_ff @(posedge clk) begin b0_c4_lr <= ld_r; b0_c4_lw <= ld_v && ld_iq >= 11'd0 && ld_iq < 11'd3; b0_c4_ld <= ld_d[61:0]; end
    logic [2:0] b0_c4_ls; always_ff @(posedge clk) b0_c4_ls <= ld_sl;
    logic b0_c4_ldr; always_ff @(posedge clk) b0_c4_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p0 b0_c4 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c4_v), .MIDX(g0[3:1]), .midx_out(b0_c4_mi), .mq_QH(g0[48:4]), .mq_QHALF(g0[110:49]), .DIR(g0[0]), .dir_out(b0_c4_di), .tw_rst(b0_c4_lr), .tw_wen(b0_c4_lw), .tw_wdata(b0_c4_ld), .tw_slot(b0_c4_ls), .tw_dir(b0_c4_ldr), .x_in_0(d0_4), .x_in_1(d0_12), .x_in_2(d0_20), .x_in_3(d0_28), .y_out_0(b0_c4_y0), .y_out_1(b0_c4_y1), .y_out_2(b0_c4_y2), .y_out_3(b0_c4_y3));
    logic [61:0] b0_c5_y0, b0_c5_y1, b0_c5_y2, b0_c5_y3;
    logic b0_c5_v; logic [2:0] b0_c5_mi; logic b0_c5_di;
    logic b0_c5_lr, b0_c5_lw; (* equivalent_register_removal = "no" *) logic [61:0] b0_c5_ld;
    always_ff @(posedge clk) begin b0_c5_lr <= ld_r; b0_c5_lw <= ld_v && ld_iq >= 11'd0 && ld_iq < 11'd3; b0_c5_ld <= ld_d[61:0]; end
    logic [2:0] b0_c5_ls; always_ff @(posedge clk) b0_c5_ls <= ld_sl;
    logic b0_c5_ldr; always_ff @(posedge clk) b0_c5_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p0 b0_c5 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c5_v), .MIDX(g0[3:1]), .midx_out(b0_c5_mi), .mq_QH(g0[48:4]), .mq_QHALF(g0[110:49]), .DIR(g0[0]), .dir_out(b0_c5_di), .tw_rst(b0_c5_lr), .tw_wen(b0_c5_lw), .tw_wdata(b0_c5_ld), .tw_slot(b0_c5_ls), .tw_dir(b0_c5_ldr), .x_in_0(d0_5), .x_in_1(d0_13), .x_in_2(d0_21), .x_in_3(d0_29), .y_out_0(b0_c5_y0), .y_out_1(b0_c5_y1), .y_out_2(b0_c5_y2), .y_out_3(b0_c5_y3));
    logic [61:0] b0_c6_y0, b0_c6_y1, b0_c6_y2, b0_c6_y3;
    logic b0_c6_v; logic [2:0] b0_c6_mi; logic b0_c6_di;
    logic b0_c6_lr, b0_c6_lw; (* equivalent_register_removal = "no" *) logic [61:0] b0_c6_ld;
    always_ff @(posedge clk) begin b0_c6_lr <= ld_r; b0_c6_lw <= ld_v && ld_iq >= 11'd0 && ld_iq < 11'd3; b0_c6_ld <= ld_d[61:0]; end
    logic [2:0] b0_c6_ls; always_ff @(posedge clk) b0_c6_ls <= ld_sl;
    logic b0_c6_ldr; always_ff @(posedge clk) b0_c6_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p0 b0_c6 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c6_v), .MIDX(g0[3:1]), .midx_out(b0_c6_mi), .mq_QH(g0[48:4]), .mq_QHALF(g0[110:49]), .DIR(g0[0]), .dir_out(b0_c6_di), .tw_rst(b0_c6_lr), .tw_wen(b0_c6_lw), .tw_wdata(b0_c6_ld), .tw_slot(b0_c6_ls), .tw_dir(b0_c6_ldr), .x_in_0(d0_6), .x_in_1(d0_14), .x_in_2(d0_22), .x_in_3(d0_30), .y_out_0(b0_c6_y0), .y_out_1(b0_c6_y1), .y_out_2(b0_c6_y2), .y_out_3(b0_c6_y3));
    logic [61:0] b0_c7_y0, b0_c7_y1, b0_c7_y2, b0_c7_y3;
    logic b0_c7_v; logic [2:0] b0_c7_mi; logic b0_c7_di;
    logic b0_c7_lr, b0_c7_lw; (* equivalent_register_removal = "no" *) logic [61:0] b0_c7_ld;
    always_ff @(posedge clk) begin b0_c7_lr <= ld_r; b0_c7_lw <= ld_v && ld_iq >= 11'd0 && ld_iq < 11'd3; b0_c7_ld <= ld_d[61:0]; end
    logic [2:0] b0_c7_ls; always_ff @(posedge clk) b0_c7_ls <= ld_sl;
    logic b0_c7_ldr; always_ff @(posedge clk) b0_c7_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p0 b0_c7 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c7_v), .MIDX(g0[3:1]), .midx_out(b0_c7_mi), .mq_QH(g0[48:4]), .mq_QHALF(g0[110:49]), .DIR(g0[0]), .dir_out(b0_c7_di), .tw_rst(b0_c7_lr), .tw_wen(b0_c7_lw), .tw_wdata(b0_c7_ld), .tw_slot(b0_c7_ls), .tw_dir(b0_c7_ldr), .x_in_0(d0_7), .x_in_1(d0_15), .x_in_2(d0_23), .x_in_3(d0_31), .y_out_0(b0_c7_y0), .y_out_1(b0_c7_y1), .y_out_2(b0_c7_y2), .y_out_3(b0_c7_y3));
    logic [106:0] b0_cq0; assign b0_cq0 = g0[110:4];
    logic [106:0] b0_cq;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(107), .D(59)) b0_cq_i (.clk(clk), .din(b0_cq0), .dout(b0_cq));
    logic [110:0] b0_tag; assign b0_tag = {b0_cq, b0_c0_mi, b0_c0_di};
    // block 1: lane-time transpose, lane bits [3] <-> cycle bits [10,11), 16 x S=2, latency 2051
    logic [61:0] b1_g0_i [0:1]; logic [61:0] b1_g0_o [0:1]; logic b1_g0_v;
    assign b1_g0_i[0] = b0_c0_y0;
    assign b1_g0_i[1] = b0_c0_y1;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g0 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g0_i), .data_out_valid(b1_g0_v), .data_out(b1_g0_o));
    logic [61:0] b1_g1_i [0:1]; logic [61:0] b1_g1_o [0:1]; logic b1_g1_v;
    assign b1_g1_i[0] = b0_c1_y0;
    assign b1_g1_i[1] = b0_c1_y1;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g1 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g1_i), .data_out_valid(b1_g1_v), .data_out(b1_g1_o));
    logic [61:0] b1_g2_i [0:1]; logic [61:0] b1_g2_o [0:1]; logic b1_g2_v;
    assign b1_g2_i[0] = b0_c2_y0;
    assign b1_g2_i[1] = b0_c2_y1;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g2 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g2_i), .data_out_valid(b1_g2_v), .data_out(b1_g2_o));
    logic [61:0] b1_g3_i [0:1]; logic [61:0] b1_g3_o [0:1]; logic b1_g3_v;
    assign b1_g3_i[0] = b0_c3_y0;
    assign b1_g3_i[1] = b0_c3_y1;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g3 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g3_i), .data_out_valid(b1_g3_v), .data_out(b1_g3_o));
    logic [61:0] b1_g4_i [0:1]; logic [61:0] b1_g4_o [0:1]; logic b1_g4_v;
    assign b1_g4_i[0] = b0_c4_y0;
    assign b1_g4_i[1] = b0_c4_y1;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g4 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g4_i), .data_out_valid(b1_g4_v), .data_out(b1_g4_o));
    logic [61:0] b1_g5_i [0:1]; logic [61:0] b1_g5_o [0:1]; logic b1_g5_v;
    assign b1_g5_i[0] = b0_c5_y0;
    assign b1_g5_i[1] = b0_c5_y1;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g5 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g5_i), .data_out_valid(b1_g5_v), .data_out(b1_g5_o));
    logic [61:0] b1_g6_i [0:1]; logic [61:0] b1_g6_o [0:1]; logic b1_g6_v;
    assign b1_g6_i[0] = b0_c6_y0;
    assign b1_g6_i[1] = b0_c6_y1;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g6 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g6_i), .data_out_valid(b1_g6_v), .data_out(b1_g6_o));
    logic [61:0] b1_g7_i [0:1]; logic [61:0] b1_g7_o [0:1]; logic b1_g7_v;
    assign b1_g7_i[0] = b0_c7_y0;
    assign b1_g7_i[1] = b0_c7_y1;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g7 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g7_i), .data_out_valid(b1_g7_v), .data_out(b1_g7_o));
    logic [61:0] b1_g8_i [0:1]; logic [61:0] b1_g8_o [0:1]; logic b1_g8_v;
    assign b1_g8_i[0] = b0_c0_y2;
    assign b1_g8_i[1] = b0_c0_y3;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g8 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g8_i), .data_out_valid(b1_g8_v), .data_out(b1_g8_o));
    logic [61:0] b1_g9_i [0:1]; logic [61:0] b1_g9_o [0:1]; logic b1_g9_v;
    assign b1_g9_i[0] = b0_c1_y2;
    assign b1_g9_i[1] = b0_c1_y3;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g9 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g9_i), .data_out_valid(b1_g9_v), .data_out(b1_g9_o));
    logic [61:0] b1_g10_i [0:1]; logic [61:0] b1_g10_o [0:1]; logic b1_g10_v;
    assign b1_g10_i[0] = b0_c2_y2;
    assign b1_g10_i[1] = b0_c2_y3;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g10 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g10_i), .data_out_valid(b1_g10_v), .data_out(b1_g10_o));
    logic [61:0] b1_g11_i [0:1]; logic [61:0] b1_g11_o [0:1]; logic b1_g11_v;
    assign b1_g11_i[0] = b0_c3_y2;
    assign b1_g11_i[1] = b0_c3_y3;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g11 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g11_i), .data_out_valid(b1_g11_v), .data_out(b1_g11_o));
    logic [61:0] b1_g12_i [0:1]; logic [61:0] b1_g12_o [0:1]; logic b1_g12_v;
    assign b1_g12_i[0] = b0_c4_y2;
    assign b1_g12_i[1] = b0_c4_y3;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g12 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g12_i), .data_out_valid(b1_g12_v), .data_out(b1_g12_o));
    logic [61:0] b1_g13_i [0:1]; logic [61:0] b1_g13_o [0:1]; logic b1_g13_v;
    assign b1_g13_i[0] = b0_c5_y2;
    assign b1_g13_i[1] = b0_c5_y3;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g13 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g13_i), .data_out_valid(b1_g13_v), .data_out(b1_g13_o));
    logic [61:0] b1_g14_i [0:1]; logic [61:0] b1_g14_o [0:1]; logic b1_g14_v;
    assign b1_g14_i[0] = b0_c6_y2;
    assign b1_g14_i[1] = b0_c6_y3;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g14 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g14_i), .data_out_valid(b1_g14_v), .data_out(b1_g14_o));
    logic [61:0] b1_g15_i [0:1]; logic [61:0] b1_g15_o [0:1]; logic b1_g15_v;
    assign b1_g15_i[0] = b0_c7_y2;
    assign b1_g15_i[1] = b0_c7_y3;
    lt_bmb_transpose #(.S(2), .LO(10), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h1), .RAM_STYLE("block")) b1_g15 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g15_i), .data_out_valid(b1_g15_v), .data_out(b1_g15_o));
    logic [110:0] b1_tag;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(111), .D(2051)) b1_tag_i (.clk(clk), .din(b0_tag), .dout(b1_tag));
    // block 2: twiddle stage 1, latency 27 (tables 2, multiplier 25)
    logic [10:0] b2_cnt;
    always_ff @(posedge clk) b2_cnt <= rst ? '0 : (b1_g0_v ? b2_cnt + 1'b1 : b2_cnt);
    logic [61:0] b2_t0;
    logic b2_t0_lwe; logic [4:0] b2_t0_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t0_lwd;
    always_ff @(posedge clk) begin b2_t0_lwe <= ld_v && ld_iq >= 11'd0 && ld_iq < 11'd2; b2_t0_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd0)}; b2_t0_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab0 b2_t0_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t0_lwe), .wa(b2_t0_lwa), .wcol(1'b0), .wd(b2_t0_lwd), .q0(b2_t0));
    logic [61:0] b2_t1;
    logic b2_t1_lwe; logic [4:0] b2_t1_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t1_lwd;
    always_ff @(posedge clk) begin b2_t1_lwe <= ld_v && ld_iq >= 11'd2 && ld_iq < 11'd4; b2_t1_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd2)}; b2_t1_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab1 b2_t1_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t1_lwe), .wa(b2_t1_lwa), .wcol(1'b0), .wd(b2_t1_lwd), .q0(b2_t1));
    logic [61:0] b2_t2;
    logic b2_t2_lwe; logic [4:0] b2_t2_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t2_lwd;
    always_ff @(posedge clk) begin b2_t2_lwe <= ld_v && ld_iq >= 11'd3 && ld_iq < 11'd5; b2_t2_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd3)}; b2_t2_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab2 b2_t2_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t2_lwe), .wa(b2_t2_lwa), .wcol(1'b0), .wd(b2_t2_lwd), .q0(b2_t2));
    logic [61:0] b2_t3;
    logic b2_t3_lwe; logic [4:0] b2_t3_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t3_lwd;
    always_ff @(posedge clk) begin b2_t3_lwe <= ld_v && ld_iq >= 11'd4 && ld_iq < 11'd6; b2_t3_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd4)}; b2_t3_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab3 b2_t3_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t3_lwe), .wa(b2_t3_lwa), .wcol(1'b0), .wd(b2_t3_lwd), .q0(b2_t3));
    logic [61:0] b2_t4;
    logic b2_t4_lwe; logic [4:0] b2_t4_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t4_lwd;
    always_ff @(posedge clk) begin b2_t4_lwe <= ld_v && ld_iq >= 11'd5 && ld_iq < 11'd7; b2_t4_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd5)}; b2_t4_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab4 b2_t4_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t4_lwe), .wa(b2_t4_lwa), .wcol(1'b0), .wd(b2_t4_lwd), .q0(b2_t4));
    logic [61:0] b2_t5;
    logic b2_t5_lwe; logic [4:0] b2_t5_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t5_lwd;
    always_ff @(posedge clk) begin b2_t5_lwe <= ld_v && ld_iq >= 11'd6 && ld_iq < 11'd8; b2_t5_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd6)}; b2_t5_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab5 b2_t5_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t5_lwe), .wa(b2_t5_lwa), .wcol(1'b0), .wd(b2_t5_lwd), .q0(b2_t5));
    logic [61:0] b2_t6;
    logic b2_t6_lwe; logic [4:0] b2_t6_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t6_lwd;
    always_ff @(posedge clk) begin b2_t6_lwe <= ld_v && ld_iq >= 11'd7 && ld_iq < 11'd9; b2_t6_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd7)}; b2_t6_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab6 b2_t6_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t6_lwe), .wa(b2_t6_lwa), .wcol(1'b0), .wd(b2_t6_lwd), .q0(b2_t6));
    logic [61:0] b2_t7;
    logic b2_t7_lwe; logic [4:0] b2_t7_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t7_lwd;
    always_ff @(posedge clk) begin b2_t7_lwe <= ld_v && ld_iq >= 11'd8 && ld_iq < 11'd10; b2_t7_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd8)}; b2_t7_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab7 b2_t7_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t7_lwe), .wa(b2_t7_lwa), .wcol(1'b0), .wd(b2_t7_lwd), .q0(b2_t7));
    logic [61:0] b2_t8;
    logic b2_t8_lwe; logic [4:0] b2_t8_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t8_lwd;
    always_ff @(posedge clk) begin b2_t8_lwe <= ld_v && ld_iq >= 11'd9 && ld_iq < 11'd11; b2_t8_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd9)}; b2_t8_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab8 b2_t8_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t8_lwe), .wa(b2_t8_lwa), .wcol(1'b0), .wd(b2_t8_lwd), .q0(b2_t8));
    logic [61:0] b2_t9;
    logic b2_t9_lwe; logic [4:0] b2_t9_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t9_lwd;
    always_ff @(posedge clk) begin b2_t9_lwe <= ld_v && ld_iq >= 11'd10 && ld_iq < 11'd12; b2_t9_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd10)}; b2_t9_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab9 b2_t9_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t9_lwe), .wa(b2_t9_lwa), .wcol(1'b0), .wd(b2_t9_lwd), .q0(b2_t9));
    logic [61:0] b2_t10;
    logic b2_t10_lwe; logic [4:0] b2_t10_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t10_lwd;
    always_ff @(posedge clk) begin b2_t10_lwe <= ld_v && ld_iq >= 11'd11 && ld_iq < 11'd13; b2_t10_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd11)}; b2_t10_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab10 b2_t10_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t10_lwe), .wa(b2_t10_lwa), .wcol(1'b0), .wd(b2_t10_lwd), .q0(b2_t10));
    logic [61:0] b2_t11;
    logic b2_t11_lwe; logic [4:0] b2_t11_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t11_lwd;
    always_ff @(posedge clk) begin b2_t11_lwe <= ld_v && ld_iq >= 11'd12 && ld_iq < 11'd14; b2_t11_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd12)}; b2_t11_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab11 b2_t11_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t11_lwe), .wa(b2_t11_lwa), .wcol(1'b0), .wd(b2_t11_lwd), .q0(b2_t11));
    logic [61:0] b2_t12;
    logic b2_t12_lwe; logic [4:0] b2_t12_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t12_lwd;
    always_ff @(posedge clk) begin b2_t12_lwe <= ld_v && ld_iq >= 11'd13 && ld_iq < 11'd15; b2_t12_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd13)}; b2_t12_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab12 b2_t12_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t12_lwe), .wa(b2_t12_lwa), .wcol(1'b0), .wd(b2_t12_lwd), .q0(b2_t12));
    logic [61:0] b2_t13;
    logic b2_t13_lwe; logic [4:0] b2_t13_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t13_lwd;
    always_ff @(posedge clk) begin b2_t13_lwe <= ld_v && ld_iq >= 11'd14 && ld_iq < 11'd16; b2_t13_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd14)}; b2_t13_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab13 b2_t13_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t13_lwe), .wa(b2_t13_lwa), .wcol(1'b0), .wd(b2_t13_lwd), .q0(b2_t13));
    logic [61:0] b2_t14;
    logic b2_t14_lwe; logic [4:0] b2_t14_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t14_lwd;
    always_ff @(posedge clk) begin b2_t14_lwe <= ld_v && ld_iq >= 11'd15 && ld_iq < 11'd17; b2_t14_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd15)}; b2_t14_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab14 b2_t14_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t14_lwe), .wa(b2_t14_lwa), .wcol(1'b0), .wd(b2_t14_lwd), .q0(b2_t14));
    logic [61:0] b2_t15;
    logic b2_t15_lwe; logic [4:0] b2_t15_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t15_lwd;
    always_ff @(posedge clk) begin b2_t15_lwe <= ld_v && ld_iq >= 11'd16 && ld_iq < 11'd18; b2_t15_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd16)}; b2_t15_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab15 b2_t15_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t15_lwe), .wa(b2_t15_lwa), .wcol(1'b0), .wd(b2_t15_lwd), .q0(b2_t15));
    logic [61:0] b2_t16;
    logic b2_t16_lwe; logic [4:0] b2_t16_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t16_lwd;
    always_ff @(posedge clk) begin b2_t16_lwe <= ld_v && ld_iq >= 11'd17 && ld_iq < 11'd19; b2_t16_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd17)}; b2_t16_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab16 b2_t16_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t16_lwe), .wa(b2_t16_lwa), .wcol(1'b0), .wd(b2_t16_lwd), .q0(b2_t16));
    logic [61:0] b2_t17;
    logic b2_t17_lwe; logic [4:0] b2_t17_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t17_lwd;
    always_ff @(posedge clk) begin b2_t17_lwe <= ld_v && ld_iq >= 11'd18 && ld_iq < 11'd20; b2_t17_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd18)}; b2_t17_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab17 b2_t17_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t17_lwe), .wa(b2_t17_lwa), .wcol(1'b0), .wd(b2_t17_lwd), .q0(b2_t17));
    logic [61:0] b2_t18;
    logic b2_t18_lwe; logic [4:0] b2_t18_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t18_lwd;
    always_ff @(posedge clk) begin b2_t18_lwe <= ld_v && ld_iq >= 11'd19 && ld_iq < 11'd21; b2_t18_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd19)}; b2_t18_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab18 b2_t18_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t18_lwe), .wa(b2_t18_lwa), .wcol(1'b0), .wd(b2_t18_lwd), .q0(b2_t18));
    logic [61:0] b2_t19;
    logic b2_t19_lwe; logic [4:0] b2_t19_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t19_lwd;
    always_ff @(posedge clk) begin b2_t19_lwe <= ld_v && ld_iq >= 11'd20 && ld_iq < 11'd22; b2_t19_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd20)}; b2_t19_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab19 b2_t19_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t19_lwe), .wa(b2_t19_lwa), .wcol(1'b0), .wd(b2_t19_lwd), .q0(b2_t19));
    logic [61:0] b2_t20;
    logic b2_t20_lwe; logic [4:0] b2_t20_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t20_lwd;
    always_ff @(posedge clk) begin b2_t20_lwe <= ld_v && ld_iq >= 11'd21 && ld_iq < 11'd23; b2_t20_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd21)}; b2_t20_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab20 b2_t20_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t20_lwe), .wa(b2_t20_lwa), .wcol(1'b0), .wd(b2_t20_lwd), .q0(b2_t20));
    logic [61:0] b2_t21;
    logic b2_t21_lwe; logic [4:0] b2_t21_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t21_lwd;
    always_ff @(posedge clk) begin b2_t21_lwe <= ld_v && ld_iq >= 11'd22 && ld_iq < 11'd24; b2_t21_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd22)}; b2_t21_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab21 b2_t21_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t21_lwe), .wa(b2_t21_lwa), .wcol(1'b0), .wd(b2_t21_lwd), .q0(b2_t21));
    logic [61:0] b2_t22;
    logic b2_t22_lwe; logic [4:0] b2_t22_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t22_lwd;
    always_ff @(posedge clk) begin b2_t22_lwe <= ld_v && ld_iq >= 11'd23 && ld_iq < 11'd25; b2_t22_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd23)}; b2_t22_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab22 b2_t22_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t22_lwe), .wa(b2_t22_lwa), .wcol(1'b0), .wd(b2_t22_lwd), .q0(b2_t22));
    logic [61:0] b2_t23;
    logic b2_t23_lwe; logic [4:0] b2_t23_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t23_lwd;
    always_ff @(posedge clk) begin b2_t23_lwe <= ld_v && ld_iq >= 11'd24 && ld_iq < 11'd26; b2_t23_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd24)}; b2_t23_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab23 b2_t23_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t23_lwe), .wa(b2_t23_lwa), .wcol(1'b0), .wd(b2_t23_lwd), .q0(b2_t23));
    logic [61:0] b2_t24;
    logic b2_t24_lwe; logic [4:0] b2_t24_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t24_lwd;
    always_ff @(posedge clk) begin b2_t24_lwe <= ld_v && ld_iq >= 11'd25 && ld_iq < 11'd27; b2_t24_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd25)}; b2_t24_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab24 b2_t24_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t24_lwe), .wa(b2_t24_lwa), .wcol(1'b0), .wd(b2_t24_lwd), .q0(b2_t24));
    logic [61:0] b2_t25;
    logic b2_t25_lwe; logic [4:0] b2_t25_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t25_lwd;
    always_ff @(posedge clk) begin b2_t25_lwe <= ld_v && ld_iq >= 11'd26 && ld_iq < 11'd28; b2_t25_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd26)}; b2_t25_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab25 b2_t25_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t25_lwe), .wa(b2_t25_lwa), .wcol(1'b0), .wd(b2_t25_lwd), .q0(b2_t25));
    logic [61:0] b2_t26;
    logic b2_t26_lwe; logic [4:0] b2_t26_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t26_lwd;
    always_ff @(posedge clk) begin b2_t26_lwe <= ld_v && ld_iq >= 11'd27 && ld_iq < 11'd29; b2_t26_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd27)}; b2_t26_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab26 b2_t26_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t26_lwe), .wa(b2_t26_lwa), .wcol(1'b0), .wd(b2_t26_lwd), .q0(b2_t26));
    logic [61:0] b2_t27;
    logic b2_t27_lwe; logic [4:0] b2_t27_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t27_lwd;
    always_ff @(posedge clk) begin b2_t27_lwe <= ld_v && ld_iq >= 11'd28 && ld_iq < 11'd30; b2_t27_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd28)}; b2_t27_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab27 b2_t27_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t27_lwe), .wa(b2_t27_lwa), .wcol(1'b0), .wd(b2_t27_lwd), .q0(b2_t27));
    logic [61:0] b2_t28;
    logic b2_t28_lwe; logic [4:0] b2_t28_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t28_lwd;
    always_ff @(posedge clk) begin b2_t28_lwe <= ld_v && ld_iq >= 11'd29 && ld_iq < 11'd31; b2_t28_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd29)}; b2_t28_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab28 b2_t28_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t28_lwe), .wa(b2_t28_lwa), .wcol(1'b0), .wd(b2_t28_lwd), .q0(b2_t28));
    logic [61:0] b2_t29;
    logic b2_t29_lwe; logic [4:0] b2_t29_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t29_lwd;
    always_ff @(posedge clk) begin b2_t29_lwe <= ld_v && ld_iq >= 11'd30 && ld_iq < 11'd32; b2_t29_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd30)}; b2_t29_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab29 b2_t29_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t29_lwe), .wa(b2_t29_lwa), .wcol(1'b0), .wd(b2_t29_lwd), .q0(b2_t29));
    logic [61:0] b2_t30;
    logic b2_t30_lwe; logic [4:0] b2_t30_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t30_lwd;
    always_ff @(posedge clk) begin b2_t30_lwe <= ld_v && ld_iq >= 11'd31 && ld_iq < 11'd33; b2_t30_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd31)}; b2_t30_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab30 b2_t30_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t30_lwe), .wa(b2_t30_lwa), .wcol(1'b0), .wd(b2_t30_lwd), .q0(b2_t30));
    logic [61:0] b2_t31;
    logic b2_t31_lwe; logic [4:0] b2_t31_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t31_lwd;
    always_ff @(posedge clk) begin b2_t31_lwe <= ld_v && ld_iq >= 11'd32 && ld_iq < 11'd34; b2_t31_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 11'd32)}; b2_t31_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw1_tab31 b2_t31_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t31_lwe), .wa(b2_t31_lwa), .wcol(1'b0), .wd(b2_t31_lwd), .q0(b2_t31));
    logic [61:0] b2_l0_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l0_a_i (.clk(clk), .din(b1_g0_o[0]), .dout(b2_l0_a));
    logic [44:0] b2_mq2_0_QH_c; assign b2_mq2_0_QH_c = b1_tag[48:4];
    logic [44:0] b2_mq2_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(45), .D(1)) b2_mq2_0_QH_i (.clk(clk), .din(b2_mq2_0_QH_c), .dout(b2_mq2_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_mq2_s0_QH;
    always_ff @(posedge clk) b2_mq2_s0_QH <= b2_mq2_0_QH;
    logic [61:0] b2_l0_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l0_mul (.clk(clk), .A(b2_l0_a), .B(b2_t0), .QH(b2_mq2_s0_QH), .P(b2_l0_p));
    logic [61:0] b2_l1_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l1_a_i (.clk(clk), .din(b1_g1_o[0]), .dout(b2_l1_a));
    logic [61:0] b2_l1_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l1_mul (.clk(clk), .A(b2_l1_a), .B(b2_t1), .QH(b2_mq2_s0_QH), .P(b2_l1_p));
    logic [61:0] b2_l2_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l2_a_i (.clk(clk), .din(b1_g2_o[0]), .dout(b2_l2_a));
    logic [61:0] b2_l2_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l2_mul (.clk(clk), .A(b2_l2_a), .B(b2_t2), .QH(b2_mq2_s0_QH), .P(b2_l2_p));
    logic [61:0] b2_l3_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l3_a_i (.clk(clk), .din(b1_g3_o[0]), .dout(b2_l3_a));
    logic [61:0] b2_l3_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l3_mul (.clk(clk), .A(b2_l3_a), .B(b2_t3), .QH(b2_mq2_s0_QH), .P(b2_l3_p));
    logic [61:0] b2_l4_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l4_a_i (.clk(clk), .din(b1_g4_o[0]), .dout(b2_l4_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_mq2_s1_QH;
    always_ff @(posedge clk) b2_mq2_s1_QH <= b2_mq2_0_QH;
    logic [61:0] b2_l4_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l4_mul (.clk(clk), .A(b2_l4_a), .B(b2_t4), .QH(b2_mq2_s1_QH), .P(b2_l4_p));
    logic [61:0] b2_l5_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l5_a_i (.clk(clk), .din(b1_g5_o[0]), .dout(b2_l5_a));
    logic [61:0] b2_l5_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l5_mul (.clk(clk), .A(b2_l5_a), .B(b2_t5), .QH(b2_mq2_s1_QH), .P(b2_l5_p));
    logic [61:0] b2_l6_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l6_a_i (.clk(clk), .din(b1_g6_o[0]), .dout(b2_l6_a));
    logic [61:0] b2_l6_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l6_mul (.clk(clk), .A(b2_l6_a), .B(b2_t6), .QH(b2_mq2_s1_QH), .P(b2_l6_p));
    logic [61:0] b2_l7_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l7_a_i (.clk(clk), .din(b1_g7_o[0]), .dout(b2_l7_a));
    logic [61:0] b2_l7_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l7_mul (.clk(clk), .A(b2_l7_a), .B(b2_t7), .QH(b2_mq2_s1_QH), .P(b2_l7_p));
    logic [61:0] b2_l8_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l8_a_i (.clk(clk), .din(b1_g0_o[1]), .dout(b2_l8_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_mq2_s2_QH;
    always_ff @(posedge clk) b2_mq2_s2_QH <= b2_mq2_0_QH;
    logic [61:0] b2_l8_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l8_mul (.clk(clk), .A(b2_l8_a), .B(b2_t8), .QH(b2_mq2_s2_QH), .P(b2_l8_p));
    logic [61:0] b2_l9_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l9_a_i (.clk(clk), .din(b1_g1_o[1]), .dout(b2_l9_a));
    logic [61:0] b2_l9_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l9_mul (.clk(clk), .A(b2_l9_a), .B(b2_t9), .QH(b2_mq2_s2_QH), .P(b2_l9_p));
    logic [61:0] b2_l10_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l10_a_i (.clk(clk), .din(b1_g2_o[1]), .dout(b2_l10_a));
    logic [61:0] b2_l10_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l10_mul (.clk(clk), .A(b2_l10_a), .B(b2_t10), .QH(b2_mq2_s2_QH), .P(b2_l10_p));
    logic [61:0] b2_l11_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l11_a_i (.clk(clk), .din(b1_g3_o[1]), .dout(b2_l11_a));
    logic [61:0] b2_l11_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l11_mul (.clk(clk), .A(b2_l11_a), .B(b2_t11), .QH(b2_mq2_s2_QH), .P(b2_l11_p));
    logic [61:0] b2_l12_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l12_a_i (.clk(clk), .din(b1_g4_o[1]), .dout(b2_l12_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_mq2_s3_QH;
    always_ff @(posedge clk) b2_mq2_s3_QH <= b2_mq2_0_QH;
    logic [61:0] b2_l12_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l12_mul (.clk(clk), .A(b2_l12_a), .B(b2_t12), .QH(b2_mq2_s3_QH), .P(b2_l12_p));
    logic [61:0] b2_l13_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l13_a_i (.clk(clk), .din(b1_g5_o[1]), .dout(b2_l13_a));
    logic [61:0] b2_l13_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l13_mul (.clk(clk), .A(b2_l13_a), .B(b2_t13), .QH(b2_mq2_s3_QH), .P(b2_l13_p));
    logic [61:0] b2_l14_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l14_a_i (.clk(clk), .din(b1_g6_o[1]), .dout(b2_l14_a));
    logic [61:0] b2_l14_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l14_mul (.clk(clk), .A(b2_l14_a), .B(b2_t14), .QH(b2_mq2_s3_QH), .P(b2_l14_p));
    logic [61:0] b2_l15_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l15_a_i (.clk(clk), .din(b1_g7_o[1]), .dout(b2_l15_a));
    logic [61:0] b2_l15_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l15_mul (.clk(clk), .A(b2_l15_a), .B(b2_t15), .QH(b2_mq2_s3_QH), .P(b2_l15_p));
    logic [61:0] b2_l16_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l16_a_i (.clk(clk), .din(b1_g8_o[0]), .dout(b2_l16_a));
    logic [44:0] b2_mq2_1_QH_c; assign b2_mq2_1_QH_c = b1_tag[48:4];
    logic [44:0] b2_mq2_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(45), .D(1)) b2_mq2_1_QH_i (.clk(clk), .din(b2_mq2_1_QH_c), .dout(b2_mq2_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_mq2_s4_QH;
    always_ff @(posedge clk) b2_mq2_s4_QH <= b2_mq2_1_QH;
    logic [61:0] b2_l16_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l16_mul (.clk(clk), .A(b2_l16_a), .B(b2_t16), .QH(b2_mq2_s4_QH), .P(b2_l16_p));
    logic [61:0] b2_l17_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l17_a_i (.clk(clk), .din(b1_g9_o[0]), .dout(b2_l17_a));
    logic [61:0] b2_l17_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l17_mul (.clk(clk), .A(b2_l17_a), .B(b2_t17), .QH(b2_mq2_s4_QH), .P(b2_l17_p));
    logic [61:0] b2_l18_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l18_a_i (.clk(clk), .din(b1_g10_o[0]), .dout(b2_l18_a));
    logic [61:0] b2_l18_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l18_mul (.clk(clk), .A(b2_l18_a), .B(b2_t18), .QH(b2_mq2_s4_QH), .P(b2_l18_p));
    logic [61:0] b2_l19_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l19_a_i (.clk(clk), .din(b1_g11_o[0]), .dout(b2_l19_a));
    logic [61:0] b2_l19_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l19_mul (.clk(clk), .A(b2_l19_a), .B(b2_t19), .QH(b2_mq2_s4_QH), .P(b2_l19_p));
    logic [61:0] b2_l20_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l20_a_i (.clk(clk), .din(b1_g12_o[0]), .dout(b2_l20_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_mq2_s5_QH;
    always_ff @(posedge clk) b2_mq2_s5_QH <= b2_mq2_1_QH;
    logic [61:0] b2_l20_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l20_mul (.clk(clk), .A(b2_l20_a), .B(b2_t20), .QH(b2_mq2_s5_QH), .P(b2_l20_p));
    logic [61:0] b2_l21_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l21_a_i (.clk(clk), .din(b1_g13_o[0]), .dout(b2_l21_a));
    logic [61:0] b2_l21_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l21_mul (.clk(clk), .A(b2_l21_a), .B(b2_t21), .QH(b2_mq2_s5_QH), .P(b2_l21_p));
    logic [61:0] b2_l22_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l22_a_i (.clk(clk), .din(b1_g14_o[0]), .dout(b2_l22_a));
    logic [61:0] b2_l22_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l22_mul (.clk(clk), .A(b2_l22_a), .B(b2_t22), .QH(b2_mq2_s5_QH), .P(b2_l22_p));
    logic [61:0] b2_l23_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l23_a_i (.clk(clk), .din(b1_g15_o[0]), .dout(b2_l23_a));
    logic [61:0] b2_l23_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l23_mul (.clk(clk), .A(b2_l23_a), .B(b2_t23), .QH(b2_mq2_s5_QH), .P(b2_l23_p));
    logic [61:0] b2_l24_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l24_a_i (.clk(clk), .din(b1_g8_o[1]), .dout(b2_l24_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_mq2_s6_QH;
    always_ff @(posedge clk) b2_mq2_s6_QH <= b2_mq2_1_QH;
    logic [61:0] b2_l24_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l24_mul (.clk(clk), .A(b2_l24_a), .B(b2_t24), .QH(b2_mq2_s6_QH), .P(b2_l24_p));
    logic [61:0] b2_l25_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l25_a_i (.clk(clk), .din(b1_g9_o[1]), .dout(b2_l25_a));
    logic [61:0] b2_l25_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l25_mul (.clk(clk), .A(b2_l25_a), .B(b2_t25), .QH(b2_mq2_s6_QH), .P(b2_l25_p));
    logic [61:0] b2_l26_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l26_a_i (.clk(clk), .din(b1_g10_o[1]), .dout(b2_l26_a));
    logic [61:0] b2_l26_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l26_mul (.clk(clk), .A(b2_l26_a), .B(b2_t26), .QH(b2_mq2_s6_QH), .P(b2_l26_p));
    logic [61:0] b2_l27_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l27_a_i (.clk(clk), .din(b1_g11_o[1]), .dout(b2_l27_a));
    logic [61:0] b2_l27_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l27_mul (.clk(clk), .A(b2_l27_a), .B(b2_t27), .QH(b2_mq2_s6_QH), .P(b2_l27_p));
    logic [61:0] b2_l28_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l28_a_i (.clk(clk), .din(b1_g12_o[1]), .dout(b2_l28_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_mq2_s7_QH;
    always_ff @(posedge clk) b2_mq2_s7_QH <= b2_mq2_1_QH;
    logic [61:0] b2_l28_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l28_mul (.clk(clk), .A(b2_l28_a), .B(b2_t28), .QH(b2_mq2_s7_QH), .P(b2_l28_p));
    logic [61:0] b2_l29_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l29_a_i (.clk(clk), .din(b1_g13_o[1]), .dout(b2_l29_a));
    logic [61:0] b2_l29_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l29_mul (.clk(clk), .A(b2_l29_a), .B(b2_t29), .QH(b2_mq2_s7_QH), .P(b2_l29_p));
    logic [61:0] b2_l30_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l30_a_i (.clk(clk), .din(b1_g14_o[1]), .dout(b2_l30_a));
    logic [61:0] b2_l30_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l30_mul (.clk(clk), .A(b2_l30_a), .B(b2_t30), .QH(b2_mq2_s7_QH), .P(b2_l30_p));
    logic [61:0] b2_l31_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(2)) b2_l31_a_i (.clk(clk), .din(b1_g15_o[1]), .dout(b2_l31_a));
    logic [61:0] b2_l31_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b2_l31_mul (.clk(clk), .A(b2_l31_a), .B(b2_t31), .QH(b2_mq2_s7_QH), .P(b2_l31_p));
    logic [26:0] b2_v_sr;
    always_ff @(posedge clk) b2_v_sr <= rst ? '0 : {b2_v_sr[25:0], b1_g0_v};
    logic b2_v; assign b2_v = b2_v_sr[26];
    logic [110:0] b2_tag;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(111), .D(27)) b2_tag_i (.clk(clk), .din(b1_tag), .dout(b2_tag));
    // block 3: pass 1, 2 x ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p1 (16-point), latency 90
    logic [61:0] b3_c0_y0, b3_c0_y1, b3_c0_y2, b3_c0_y3, b3_c0_y4, b3_c0_y5, b3_c0_y6, b3_c0_y7, b3_c0_y8, b3_c0_y9, b3_c0_y10, b3_c0_y11, b3_c0_y12, b3_c0_y13, b3_c0_y14, b3_c0_y15;
    logic b3_c0_v; logic [2:0] b3_c0_mi; logic b3_c0_di;
    logic b3_c0_lr, b3_c0_lw; (* equivalent_register_removal = "no" *) logic [61:0] b3_c0_ld;
    always_ff @(posedge clk) begin b3_c0_lr <= ld_r; b3_c0_lw <= ld_v && ld_iq >= 11'd33 && ld_iq < 11'd40; b3_c0_ld <= ld_d[61:0]; end
    logic [2:0] b3_c0_ls; always_ff @(posedge clk) b3_c0_ls <= ld_sl;
    logic b3_c0_ldr; always_ff @(posedge clk) b3_c0_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p1 b3_c0 (.clk(clk), .rst(rst), .in_valid(b2_v), .out_valid(b3_c0_v), .MIDX(b2_tag[3:1]), .midx_out(b3_c0_mi), .mq_QH(b2_tag[48:4]), .mq_QHALF(b2_tag[110:49]), .DIR(b2_tag[0]), .dir_out(b3_c0_di), .tw_rst(b3_c0_lr), .tw_wen(b3_c0_lw), .tw_wdata(b3_c0_ld), .tw_slot(b3_c0_ls), .tw_dir(b3_c0_ldr), .x_in_0(b2_l0_p), .x_in_1(b2_l8_p), .x_in_2(b2_l1_p), .x_in_3(b2_l9_p), .x_in_4(b2_l2_p), .x_in_5(b2_l10_p), .x_in_6(b2_l3_p), .x_in_7(b2_l11_p), .x_in_8(b2_l4_p), .x_in_9(b2_l12_p), .x_in_10(b2_l5_p), .x_in_11(b2_l13_p), .x_in_12(b2_l6_p), .x_in_13(b2_l14_p), .x_in_14(b2_l7_p), .x_in_15(b2_l15_p), .y_out_0(b3_c0_y0), .y_out_1(b3_c0_y1), .y_out_2(b3_c0_y2), .y_out_3(b3_c0_y3), .y_out_4(b3_c0_y4), .y_out_5(b3_c0_y5), .y_out_6(b3_c0_y6), .y_out_7(b3_c0_y7), .y_out_8(b3_c0_y8), .y_out_9(b3_c0_y9), .y_out_10(b3_c0_y10), .y_out_11(b3_c0_y11), .y_out_12(b3_c0_y12), .y_out_13(b3_c0_y13), .y_out_14(b3_c0_y14), .y_out_15(b3_c0_y15));
    logic [61:0] b3_c1_y0, b3_c1_y1, b3_c1_y2, b3_c1_y3, b3_c1_y4, b3_c1_y5, b3_c1_y6, b3_c1_y7, b3_c1_y8, b3_c1_y9, b3_c1_y10, b3_c1_y11, b3_c1_y12, b3_c1_y13, b3_c1_y14, b3_c1_y15;
    logic b3_c1_v; logic [2:0] b3_c1_mi; logic b3_c1_di;
    logic b3_c1_lr, b3_c1_lw; (* equivalent_register_removal = "no" *) logic [61:0] b3_c1_ld;
    always_ff @(posedge clk) begin b3_c1_lr <= ld_r; b3_c1_lw <= ld_v && ld_iq >= 11'd33 && ld_iq < 11'd40; b3_c1_ld <= ld_d[61:0]; end
    logic [2:0] b3_c1_ls; always_ff @(posedge clk) b3_c1_ls <= ld_sl;
    logic b3_c1_ldr; always_ff @(posedge clk) b3_c1_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p1 b3_c1 (.clk(clk), .rst(rst), .in_valid(b2_v), .out_valid(b3_c1_v), .MIDX(b2_tag[3:1]), .midx_out(b3_c1_mi), .mq_QH(b2_tag[48:4]), .mq_QHALF(b2_tag[110:49]), .DIR(b2_tag[0]), .dir_out(b3_c1_di), .tw_rst(b3_c1_lr), .tw_wen(b3_c1_lw), .tw_wdata(b3_c1_ld), .tw_slot(b3_c1_ls), .tw_dir(b3_c1_ldr), .x_in_0(b2_l16_p), .x_in_1(b2_l24_p), .x_in_2(b2_l17_p), .x_in_3(b2_l25_p), .x_in_4(b2_l18_p), .x_in_5(b2_l26_p), .x_in_6(b2_l19_p), .x_in_7(b2_l27_p), .x_in_8(b2_l20_p), .x_in_9(b2_l28_p), .x_in_10(b2_l21_p), .x_in_11(b2_l29_p), .x_in_12(b2_l22_p), .x_in_13(b2_l30_p), .x_in_14(b2_l23_p), .x_in_15(b2_l31_p), .y_out_0(b3_c1_y0), .y_out_1(b3_c1_y1), .y_out_2(b3_c1_y2), .y_out_3(b3_c1_y3), .y_out_4(b3_c1_y4), .y_out_5(b3_c1_y5), .y_out_6(b3_c1_y6), .y_out_7(b3_c1_y7), .y_out_8(b3_c1_y8), .y_out_9(b3_c1_y9), .y_out_10(b3_c1_y10), .y_out_11(b3_c1_y11), .y_out_12(b3_c1_y12), .y_out_13(b3_c1_y13), .y_out_14(b3_c1_y14), .y_out_15(b3_c1_y15));
    logic [106:0] b3_cq0; assign b3_cq0 = b2_tag[110:4];
    logic [106:0] b3_cq;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(107), .D(90)) b3_cq_i (.clk(clk), .din(b3_cq0), .dout(b3_cq));
    logic [110:0] b3_tag; assign b3_tag = {b3_cq, b3_c0_mi, b3_c0_di};
    // block 4: lane-time transpose, lane bits [0, 1, 2, 3, 4] <-> cycle bits [5,10), 1 x S=32, latency 1031
    logic [61:0] b4_g0_i [0:31]; logic [61:0] b4_g0_o [0:31]; logic b4_g0_v;
    assign b4_g0_i[0] = b3_c0_y0;
    assign b4_g0_i[1] = b3_c0_y2;
    assign b4_g0_i[2] = b3_c0_y4;
    assign b4_g0_i[3] = b3_c0_y6;
    assign b4_g0_i[4] = b3_c0_y8;
    assign b4_g0_i[5] = b3_c0_y10;
    assign b4_g0_i[6] = b3_c0_y12;
    assign b4_g0_i[7] = b3_c0_y14;
    assign b4_g0_i[8] = b3_c0_y1;
    assign b4_g0_i[9] = b3_c0_y3;
    assign b4_g0_i[10] = b3_c0_y5;
    assign b4_g0_i[11] = b3_c0_y7;
    assign b4_g0_i[12] = b3_c0_y9;
    assign b4_g0_i[13] = b3_c0_y11;
    assign b4_g0_i[14] = b3_c0_y13;
    assign b4_g0_i[15] = b3_c0_y15;
    assign b4_g0_i[16] = b3_c1_y0;
    assign b4_g0_i[17] = b3_c1_y2;
    assign b4_g0_i[18] = b3_c1_y4;
    assign b4_g0_i[19] = b3_c1_y6;
    assign b4_g0_i[20] = b3_c1_y8;
    assign b4_g0_i[21] = b3_c1_y10;
    assign b4_g0_i[22] = b3_c1_y12;
    assign b4_g0_i[23] = b3_c1_y14;
    assign b4_g0_i[24] = b3_c1_y1;
    assign b4_g0_i[25] = b3_c1_y3;
    assign b4_g0_i[26] = b3_c1_y5;
    assign b4_g0_i[27] = b3_c1_y7;
    assign b4_g0_i[28] = b3_c1_y9;
    assign b4_g0_i[29] = b3_c1_y11;
    assign b4_g0_i[30] = b3_c1_y13;
    assign b4_g0_i[31] = b3_c1_y15;
    lt_bmb_transpose #(.S(32), .LO(5), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h7), .RAM_STYLE("block")) b4_g0 (.clk(clk), .rst(rst), .data_valid(b3_c0_v), .data_in(b4_g0_i), .data_out_valid(b4_g0_v), .data_out(b4_g0_o));
    logic [110:0] b4_tag;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(111), .D(1031)) b4_tag_i (.clk(clk), .din(b3_tag), .dout(b4_tag));
    // block 5: twiddle stage 2, latency 52 (tables 2, generator 25, multiplier 25)
    logic [10:0] b5_cnt;
    always_ff @(posedge clk) b5_cnt <= rst ? '0 : (b4_g0_v ? b5_cnt + 1'b1 : b5_cnt);
    logic [61:0] b5_t0;
    logic b5_t0_lwe; logic [5:0] b5_t0_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t0_lwd;
    always_ff @(posedge clk) begin b5_t0_lwe <= ld_v && ld_iq >= 11'd34 && ld_iq < 11'd38; b5_t0_lwa <= {ld_slq[2:0], ld_drq, 2'(ld_iq - 11'd34)}; b5_t0_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab0 b5_t0_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[6], b5_cnt[5]}), .we(b5_t0_lwe), .wa(b5_t0_lwa), .wcol(1'b0), .wd(b5_t0_lwd), .q0(b5_t0));
    logic [61:0] b5_t1;
    logic b5_t1_lwe; logic [5:0] b5_t1_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t1_lwd;
    always_ff @(posedge clk) begin b5_t1_lwe <= ld_v && ld_iq >= 11'd38 && ld_iq < 11'd42; b5_t1_lwa <= {ld_slq[2:0], ld_drq, 2'(ld_iq - 11'd38)}; b5_t1_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab1 b5_t1_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[8], b5_cnt[7]}), .we(b5_t1_lwe), .wa(b5_t1_lwa), .wcol(1'b0), .wd(b5_t1_lwd), .q0(b5_t1));
    logic [61:0] b5_t2;
    logic b5_t2_lwe; logic [6:0] b5_t2_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t2_lwd;
    always_ff @(posedge clk) begin b5_t2_lwe <= ld_v && ld_iq >= 11'd40 && ld_iq < 11'd48; b5_t2_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd40)}; b5_t2_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab2 b5_t2_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t2_lwe), .wa(b5_t2_lwa), .wcol(1'b0), .wd(b5_t2_lwd), .q0(b5_t2));
    logic [61:0] b5_t3;
    logic b5_t3_lwe; logic [6:0] b5_t3_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t3_lwd;
    always_ff @(posedge clk) begin b5_t3_lwe <= ld_v && ld_iq >= 11'd42 && ld_iq < 11'd50; b5_t3_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd42)}; b5_t3_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab3 b5_t3_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t3_lwe), .wa(b5_t3_lwa), .wcol(1'b0), .wd(b5_t3_lwd), .q0(b5_t3));
    logic [61:0] b5_t4;
    logic b5_t4_lwe; logic [6:0] b5_t4_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t4_lwd;
    always_ff @(posedge clk) begin b5_t4_lwe <= ld_v && ld_iq >= 11'd48 && ld_iq < 11'd56; b5_t4_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd48)}; b5_t4_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab4 b5_t4_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t4_lwe), .wa(b5_t4_lwa), .wcol(1'b0), .wd(b5_t4_lwd), .q0(b5_t4));
    logic [61:0] b5_t5;
    logic b5_t5_lwe; logic [6:0] b5_t5_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t5_lwd;
    always_ff @(posedge clk) begin b5_t5_lwe <= ld_v && ld_iq >= 11'd50 && ld_iq < 11'd58; b5_t5_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd50)}; b5_t5_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab5 b5_t5_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t5_lwe), .wa(b5_t5_lwa), .wcol(1'b0), .wd(b5_t5_lwd), .q0(b5_t5));
    logic [61:0] b5_t6;
    logic b5_t6_lwe; logic [6:0] b5_t6_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t6_lwd;
    always_ff @(posedge clk) begin b5_t6_lwe <= ld_v && ld_iq >= 11'd56 && ld_iq < 11'd64; b5_t6_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd56)}; b5_t6_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab6 b5_t6_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t6_lwe), .wa(b5_t6_lwa), .wcol(1'b0), .wd(b5_t6_lwd), .q0(b5_t6));
    logic [61:0] b5_t7;
    logic b5_t7_lwe; logic [6:0] b5_t7_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t7_lwd;
    always_ff @(posedge clk) begin b5_t7_lwe <= ld_v && ld_iq >= 11'd58 && ld_iq < 11'd66; b5_t7_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd58)}; b5_t7_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab7 b5_t7_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t7_lwe), .wa(b5_t7_lwa), .wcol(1'b0), .wd(b5_t7_lwd), .q0(b5_t7));
    logic [61:0] b5_t8;
    logic b5_t8_lwe; logic [6:0] b5_t8_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t8_lwd;
    always_ff @(posedge clk) begin b5_t8_lwe <= ld_v && ld_iq >= 11'd64 && ld_iq < 11'd72; b5_t8_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd64)}; b5_t8_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab8 b5_t8_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t8_lwe), .wa(b5_t8_lwa), .wcol(1'b0), .wd(b5_t8_lwd), .q0(b5_t8));
    logic [61:0] b5_t9;
    logic b5_t9_lwe; logic [6:0] b5_t9_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t9_lwd;
    always_ff @(posedge clk) begin b5_t9_lwe <= ld_v && ld_iq >= 11'd66 && ld_iq < 11'd74; b5_t9_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd66)}; b5_t9_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab9 b5_t9_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t9_lwe), .wa(b5_t9_lwa), .wcol(1'b0), .wd(b5_t9_lwd), .q0(b5_t9));
    logic [61:0] b5_t10;
    logic b5_t10_lwe; logic [6:0] b5_t10_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t10_lwd;
    always_ff @(posedge clk) begin b5_t10_lwe <= ld_v && ld_iq >= 11'd72 && ld_iq < 11'd80; b5_t10_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd72)}; b5_t10_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab10 b5_t10_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t10_lwe), .wa(b5_t10_lwa), .wcol(1'b0), .wd(b5_t10_lwd), .q0(b5_t10));
    logic [61:0] b5_t11;
    logic b5_t11_lwe; logic [6:0] b5_t11_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t11_lwd;
    always_ff @(posedge clk) begin b5_t11_lwe <= ld_v && ld_iq >= 11'd74 && ld_iq < 11'd82; b5_t11_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd74)}; b5_t11_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab11 b5_t11_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t11_lwe), .wa(b5_t11_lwa), .wcol(1'b0), .wd(b5_t11_lwd), .q0(b5_t11));
    logic [61:0] b5_t12;
    logic b5_t12_lwe; logic [6:0] b5_t12_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t12_lwd;
    always_ff @(posedge clk) begin b5_t12_lwe <= ld_v && ld_iq >= 11'd80 && ld_iq < 11'd88; b5_t12_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd80)}; b5_t12_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab12 b5_t12_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t12_lwe), .wa(b5_t12_lwa), .wcol(1'b0), .wd(b5_t12_lwd), .q0(b5_t12));
    logic [61:0] b5_t13;
    logic b5_t13_lwe; logic [6:0] b5_t13_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t13_lwd;
    always_ff @(posedge clk) begin b5_t13_lwe <= ld_v && ld_iq >= 11'd82 && ld_iq < 11'd90; b5_t13_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd82)}; b5_t13_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab13 b5_t13_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t13_lwe), .wa(b5_t13_lwa), .wcol(1'b0), .wd(b5_t13_lwd), .q0(b5_t13));
    logic [61:0] b5_t14;
    logic b5_t14_lwe; logic [6:0] b5_t14_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t14_lwd;
    always_ff @(posedge clk) begin b5_t14_lwe <= ld_v && ld_iq >= 11'd88 && ld_iq < 11'd96; b5_t14_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd88)}; b5_t14_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab14 b5_t14_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t14_lwe), .wa(b5_t14_lwa), .wcol(1'b0), .wd(b5_t14_lwd), .q0(b5_t14));
    logic [61:0] b5_t15;
    logic b5_t15_lwe; logic [6:0] b5_t15_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t15_lwd;
    always_ff @(posedge clk) begin b5_t15_lwe <= ld_v && ld_iq >= 11'd90 && ld_iq < 11'd98; b5_t15_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd90)}; b5_t15_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab15 b5_t15_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t15_lwe), .wa(b5_t15_lwa), .wcol(1'b0), .wd(b5_t15_lwd), .q0(b5_t15));
    logic [61:0] b5_t16;
    logic b5_t16_lwe; logic [6:0] b5_t16_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t16_lwd;
    always_ff @(posedge clk) begin b5_t16_lwe <= ld_v && ld_iq >= 11'd96 && ld_iq < 11'd104; b5_t16_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd96)}; b5_t16_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab16 b5_t16_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t16_lwe), .wa(b5_t16_lwa), .wcol(1'b0), .wd(b5_t16_lwd), .q0(b5_t16));
    logic [61:0] b5_t17;
    logic b5_t17_lwe; logic [6:0] b5_t17_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t17_lwd;
    always_ff @(posedge clk) begin b5_t17_lwe <= ld_v && ld_iq >= 11'd98 && ld_iq < 11'd106; b5_t17_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd98)}; b5_t17_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab17 b5_t17_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t17_lwe), .wa(b5_t17_lwa), .wcol(1'b0), .wd(b5_t17_lwd), .q0(b5_t17));
    logic [61:0] b5_t18;
    logic b5_t18_lwe; logic [6:0] b5_t18_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t18_lwd;
    always_ff @(posedge clk) begin b5_t18_lwe <= ld_v && ld_iq >= 11'd104 && ld_iq < 11'd112; b5_t18_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd104)}; b5_t18_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab18 b5_t18_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t18_lwe), .wa(b5_t18_lwa), .wcol(1'b0), .wd(b5_t18_lwd), .q0(b5_t18));
    logic [61:0] b5_t19;
    logic b5_t19_lwe; logic [6:0] b5_t19_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t19_lwd;
    always_ff @(posedge clk) begin b5_t19_lwe <= ld_v && ld_iq >= 11'd106 && ld_iq < 11'd114; b5_t19_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd106)}; b5_t19_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab19 b5_t19_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t19_lwe), .wa(b5_t19_lwa), .wcol(1'b0), .wd(b5_t19_lwd), .q0(b5_t19));
    logic [61:0] b5_t20;
    logic b5_t20_lwe; logic [6:0] b5_t20_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t20_lwd;
    always_ff @(posedge clk) begin b5_t20_lwe <= ld_v && ld_iq >= 11'd112 && ld_iq < 11'd120; b5_t20_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd112)}; b5_t20_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab20 b5_t20_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t20_lwe), .wa(b5_t20_lwa), .wcol(1'b0), .wd(b5_t20_lwd), .q0(b5_t20));
    logic [61:0] b5_t21;
    logic b5_t21_lwe; logic [6:0] b5_t21_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t21_lwd;
    always_ff @(posedge clk) begin b5_t21_lwe <= ld_v && ld_iq >= 11'd114 && ld_iq < 11'd122; b5_t21_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd114)}; b5_t21_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab21 b5_t21_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t21_lwe), .wa(b5_t21_lwa), .wcol(1'b0), .wd(b5_t21_lwd), .q0(b5_t21));
    logic [61:0] b5_t22;
    logic b5_t22_lwe; logic [6:0] b5_t22_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t22_lwd;
    always_ff @(posedge clk) begin b5_t22_lwe <= ld_v && ld_iq >= 11'd120 && ld_iq < 11'd128; b5_t22_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd120)}; b5_t22_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab22 b5_t22_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t22_lwe), .wa(b5_t22_lwa), .wcol(1'b0), .wd(b5_t22_lwd), .q0(b5_t22));
    logic [61:0] b5_t23;
    logic b5_t23_lwe; logic [6:0] b5_t23_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t23_lwd;
    always_ff @(posedge clk) begin b5_t23_lwe <= ld_v && ld_iq >= 11'd122 && ld_iq < 11'd130; b5_t23_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd122)}; b5_t23_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab23 b5_t23_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t23_lwe), .wa(b5_t23_lwa), .wcol(1'b0), .wd(b5_t23_lwd), .q0(b5_t23));
    logic [61:0] b5_t24;
    logic b5_t24_lwe; logic [6:0] b5_t24_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t24_lwd;
    always_ff @(posedge clk) begin b5_t24_lwe <= ld_v && ld_iq >= 11'd128 && ld_iq < 11'd136; b5_t24_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd128)}; b5_t24_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab24 b5_t24_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t24_lwe), .wa(b5_t24_lwa), .wcol(1'b0), .wd(b5_t24_lwd), .q0(b5_t24));
    logic [61:0] b5_t25;
    logic b5_t25_lwe; logic [6:0] b5_t25_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t25_lwd;
    always_ff @(posedge clk) begin b5_t25_lwe <= ld_v && ld_iq >= 11'd130 && ld_iq < 11'd138; b5_t25_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd130)}; b5_t25_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab25 b5_t25_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t25_lwe), .wa(b5_t25_lwa), .wcol(1'b0), .wd(b5_t25_lwd), .q0(b5_t25));
    logic [61:0] b5_t26;
    logic b5_t26_lwe; logic [6:0] b5_t26_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t26_lwd;
    always_ff @(posedge clk) begin b5_t26_lwe <= ld_v && ld_iq >= 11'd136 && ld_iq < 11'd144; b5_t26_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd136)}; b5_t26_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab26 b5_t26_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t26_lwe), .wa(b5_t26_lwa), .wcol(1'b0), .wd(b5_t26_lwd), .q0(b5_t26));
    logic [61:0] b5_t27;
    logic b5_t27_lwe; logic [6:0] b5_t27_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t27_lwd;
    always_ff @(posedge clk) begin b5_t27_lwe <= ld_v && ld_iq >= 11'd138 && ld_iq < 11'd146; b5_t27_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd138)}; b5_t27_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab27 b5_t27_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t27_lwe), .wa(b5_t27_lwa), .wcol(1'b0), .wd(b5_t27_lwd), .q0(b5_t27));
    logic [61:0] b5_t28;
    logic b5_t28_lwe; logic [6:0] b5_t28_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t28_lwd;
    always_ff @(posedge clk) begin b5_t28_lwe <= ld_v && ld_iq >= 11'd144 && ld_iq < 11'd152; b5_t28_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd144)}; b5_t28_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab28 b5_t28_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t28_lwe), .wa(b5_t28_lwa), .wcol(1'b0), .wd(b5_t28_lwd), .q0(b5_t28));
    logic [61:0] b5_t29;
    logic b5_t29_lwe; logic [6:0] b5_t29_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t29_lwd;
    always_ff @(posedge clk) begin b5_t29_lwe <= ld_v && ld_iq >= 11'd146 && ld_iq < 11'd154; b5_t29_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd146)}; b5_t29_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab29 b5_t29_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t29_lwe), .wa(b5_t29_lwa), .wcol(1'b0), .wd(b5_t29_lwd), .q0(b5_t29));
    logic [61:0] b5_t30;
    logic b5_t30_lwe; logic [6:0] b5_t30_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t30_lwd;
    always_ff @(posedge clk) begin b5_t30_lwe <= ld_v && ld_iq >= 11'd152 && ld_iq < 11'd160; b5_t30_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd152)}; b5_t30_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab30 b5_t30_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t30_lwe), .wa(b5_t30_lwa), .wcol(1'b0), .wd(b5_t30_lwd), .q0(b5_t30));
    logic [61:0] b5_t31;
    logic b5_t31_lwe; logic [6:0] b5_t31_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t31_lwd;
    always_ff @(posedge clk) begin b5_t31_lwe <= ld_v && ld_iq >= 11'd154 && ld_iq < 11'd162; b5_t31_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd154)}; b5_t31_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab31 b5_t31_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t31_lwe), .wa(b5_t31_lwa), .wcol(1'b0), .wd(b5_t31_lwd), .q0(b5_t31));
    logic [61:0] b5_t32;
    logic b5_t32_lwe; logic [6:0] b5_t32_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t32_lwd;
    always_ff @(posedge clk) begin b5_t32_lwe <= ld_v && ld_iq >= 11'd160 && ld_iq < 11'd168; b5_t32_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd160)}; b5_t32_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab32 b5_t32_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t32_lwe), .wa(b5_t32_lwa), .wcol(1'b0), .wd(b5_t32_lwd), .q0(b5_t32));
    logic [61:0] b5_t33;
    logic b5_t33_lwe; logic [6:0] b5_t33_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t33_lwd;
    always_ff @(posedge clk) begin b5_t33_lwe <= ld_v && ld_iq >= 11'd162 && ld_iq < 11'd170; b5_t33_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd162)}; b5_t33_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab33 b5_t33_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t33_lwe), .wa(b5_t33_lwa), .wcol(1'b0), .wd(b5_t33_lwd), .q0(b5_t33));
    logic [61:0] b5_t34;
    logic b5_t34_lwe; logic [6:0] b5_t34_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t34_lwd;
    always_ff @(posedge clk) begin b5_t34_lwe <= ld_v && ld_iq >= 11'd168 && ld_iq < 11'd176; b5_t34_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd168)}; b5_t34_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab34 b5_t34_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t34_lwe), .wa(b5_t34_lwa), .wcol(1'b0), .wd(b5_t34_lwd), .q0(b5_t34));
    logic [61:0] b5_t35;
    logic b5_t35_lwe; logic [6:0] b5_t35_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t35_lwd;
    always_ff @(posedge clk) begin b5_t35_lwe <= ld_v && ld_iq >= 11'd170 && ld_iq < 11'd178; b5_t35_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd170)}; b5_t35_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab35 b5_t35_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t35_lwe), .wa(b5_t35_lwa), .wcol(1'b0), .wd(b5_t35_lwd), .q0(b5_t35));
    logic [61:0] b5_t36;
    logic b5_t36_lwe; logic [6:0] b5_t36_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t36_lwd;
    always_ff @(posedge clk) begin b5_t36_lwe <= ld_v && ld_iq >= 11'd176 && ld_iq < 11'd184; b5_t36_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd176)}; b5_t36_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab36 b5_t36_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t36_lwe), .wa(b5_t36_lwa), .wcol(1'b0), .wd(b5_t36_lwd), .q0(b5_t36));
    logic [61:0] b5_t37;
    logic b5_t37_lwe; logic [6:0] b5_t37_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t37_lwd;
    always_ff @(posedge clk) begin b5_t37_lwe <= ld_v && ld_iq >= 11'd178 && ld_iq < 11'd186; b5_t37_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd178)}; b5_t37_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab37 b5_t37_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t37_lwe), .wa(b5_t37_lwa), .wcol(1'b0), .wd(b5_t37_lwd), .q0(b5_t37));
    logic [61:0] b5_t38;
    logic b5_t38_lwe; logic [6:0] b5_t38_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t38_lwd;
    always_ff @(posedge clk) begin b5_t38_lwe <= ld_v && ld_iq >= 11'd184 && ld_iq < 11'd192; b5_t38_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd184)}; b5_t38_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab38 b5_t38_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t38_lwe), .wa(b5_t38_lwa), .wcol(1'b0), .wd(b5_t38_lwd), .q0(b5_t38));
    logic [61:0] b5_t39;
    logic b5_t39_lwe; logic [6:0] b5_t39_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t39_lwd;
    always_ff @(posedge clk) begin b5_t39_lwe <= ld_v && ld_iq >= 11'd186 && ld_iq < 11'd194; b5_t39_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd186)}; b5_t39_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab39 b5_t39_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t39_lwe), .wa(b5_t39_lwa), .wcol(1'b0), .wd(b5_t39_lwd), .q0(b5_t39));
    logic [61:0] b5_t40;
    logic b5_t40_lwe; logic [6:0] b5_t40_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t40_lwd;
    always_ff @(posedge clk) begin b5_t40_lwe <= ld_v && ld_iq >= 11'd192 && ld_iq < 11'd200; b5_t40_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd192)}; b5_t40_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab40 b5_t40_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t40_lwe), .wa(b5_t40_lwa), .wcol(1'b0), .wd(b5_t40_lwd), .q0(b5_t40));
    logic [61:0] b5_t41;
    logic b5_t41_lwe; logic [6:0] b5_t41_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t41_lwd;
    always_ff @(posedge clk) begin b5_t41_lwe <= ld_v && ld_iq >= 11'd194 && ld_iq < 11'd202; b5_t41_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd194)}; b5_t41_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab41 b5_t41_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t41_lwe), .wa(b5_t41_lwa), .wcol(1'b0), .wd(b5_t41_lwd), .q0(b5_t41));
    logic [61:0] b5_t42;
    logic b5_t42_lwe; logic [6:0] b5_t42_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t42_lwd;
    always_ff @(posedge clk) begin b5_t42_lwe <= ld_v && ld_iq >= 11'd200 && ld_iq < 11'd208; b5_t42_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd200)}; b5_t42_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab42 b5_t42_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t42_lwe), .wa(b5_t42_lwa), .wcol(1'b0), .wd(b5_t42_lwd), .q0(b5_t42));
    logic [61:0] b5_t43;
    logic b5_t43_lwe; logic [6:0] b5_t43_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t43_lwd;
    always_ff @(posedge clk) begin b5_t43_lwe <= ld_v && ld_iq >= 11'd202 && ld_iq < 11'd210; b5_t43_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd202)}; b5_t43_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab43 b5_t43_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t43_lwe), .wa(b5_t43_lwa), .wcol(1'b0), .wd(b5_t43_lwd), .q0(b5_t43));
    logic [61:0] b5_t44;
    logic b5_t44_lwe; logic [6:0] b5_t44_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t44_lwd;
    always_ff @(posedge clk) begin b5_t44_lwe <= ld_v && ld_iq >= 11'd208 && ld_iq < 11'd216; b5_t44_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd208)}; b5_t44_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab44 b5_t44_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t44_lwe), .wa(b5_t44_lwa), .wcol(1'b0), .wd(b5_t44_lwd), .q0(b5_t44));
    logic [61:0] b5_t45;
    logic b5_t45_lwe; logic [6:0] b5_t45_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t45_lwd;
    always_ff @(posedge clk) begin b5_t45_lwe <= ld_v && ld_iq >= 11'd210 && ld_iq < 11'd218; b5_t45_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd210)}; b5_t45_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab45 b5_t45_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t45_lwe), .wa(b5_t45_lwa), .wcol(1'b0), .wd(b5_t45_lwd), .q0(b5_t45));
    logic [61:0] b5_t46;
    logic b5_t46_lwe; logic [6:0] b5_t46_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t46_lwd;
    always_ff @(posedge clk) begin b5_t46_lwe <= ld_v && ld_iq >= 11'd216 && ld_iq < 11'd224; b5_t46_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd216)}; b5_t46_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab46 b5_t46_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t46_lwe), .wa(b5_t46_lwa), .wcol(1'b0), .wd(b5_t46_lwd), .q0(b5_t46));
    logic [61:0] b5_t47;
    logic b5_t47_lwe; logic [6:0] b5_t47_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t47_lwd;
    always_ff @(posedge clk) begin b5_t47_lwe <= ld_v && ld_iq >= 11'd218 && ld_iq < 11'd226; b5_t47_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd218)}; b5_t47_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab47 b5_t47_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t47_lwe), .wa(b5_t47_lwa), .wcol(1'b0), .wd(b5_t47_lwd), .q0(b5_t47));
    logic [61:0] b5_t48;
    logic b5_t48_lwe; logic [6:0] b5_t48_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t48_lwd;
    always_ff @(posedge clk) begin b5_t48_lwe <= ld_v && ld_iq >= 11'd224 && ld_iq < 11'd232; b5_t48_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd224)}; b5_t48_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab48 b5_t48_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t48_lwe), .wa(b5_t48_lwa), .wcol(1'b0), .wd(b5_t48_lwd), .q0(b5_t48));
    logic [61:0] b5_t49;
    logic b5_t49_lwe; logic [6:0] b5_t49_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t49_lwd;
    always_ff @(posedge clk) begin b5_t49_lwe <= ld_v && ld_iq >= 11'd226 && ld_iq < 11'd234; b5_t49_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd226)}; b5_t49_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab49 b5_t49_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t49_lwe), .wa(b5_t49_lwa), .wcol(1'b0), .wd(b5_t49_lwd), .q0(b5_t49));
    logic [61:0] b5_t50;
    logic b5_t50_lwe; logic [6:0] b5_t50_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t50_lwd;
    always_ff @(posedge clk) begin b5_t50_lwe <= ld_v && ld_iq >= 11'd232 && ld_iq < 11'd240; b5_t50_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd232)}; b5_t50_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab50 b5_t50_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t50_lwe), .wa(b5_t50_lwa), .wcol(1'b0), .wd(b5_t50_lwd), .q0(b5_t50));
    logic [61:0] b5_t51;
    logic b5_t51_lwe; logic [6:0] b5_t51_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t51_lwd;
    always_ff @(posedge clk) begin b5_t51_lwe <= ld_v && ld_iq >= 11'd234 && ld_iq < 11'd242; b5_t51_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd234)}; b5_t51_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab51 b5_t51_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t51_lwe), .wa(b5_t51_lwa), .wcol(1'b0), .wd(b5_t51_lwd), .q0(b5_t51));
    logic [61:0] b5_t52;
    logic b5_t52_lwe; logic [6:0] b5_t52_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t52_lwd;
    always_ff @(posedge clk) begin b5_t52_lwe <= ld_v && ld_iq >= 11'd240 && ld_iq < 11'd248; b5_t52_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd240)}; b5_t52_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab52 b5_t52_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t52_lwe), .wa(b5_t52_lwa), .wcol(1'b0), .wd(b5_t52_lwd), .q0(b5_t52));
    logic [61:0] b5_t53;
    logic b5_t53_lwe; logic [6:0] b5_t53_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t53_lwd;
    always_ff @(posedge clk) begin b5_t53_lwe <= ld_v && ld_iq >= 11'd242 && ld_iq < 11'd250; b5_t53_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd242)}; b5_t53_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab53 b5_t53_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t53_lwe), .wa(b5_t53_lwa), .wcol(1'b0), .wd(b5_t53_lwd), .q0(b5_t53));
    logic [61:0] b5_t54;
    logic b5_t54_lwe; logic [6:0] b5_t54_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t54_lwd;
    always_ff @(posedge clk) begin b5_t54_lwe <= ld_v && ld_iq >= 11'd248 && ld_iq < 11'd256; b5_t54_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd248)}; b5_t54_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab54 b5_t54_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t54_lwe), .wa(b5_t54_lwa), .wcol(1'b0), .wd(b5_t54_lwd), .q0(b5_t54));
    logic [61:0] b5_t55;
    logic b5_t55_lwe; logic [6:0] b5_t55_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t55_lwd;
    always_ff @(posedge clk) begin b5_t55_lwe <= ld_v && ld_iq >= 11'd250 && ld_iq < 11'd258; b5_t55_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd250)}; b5_t55_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab55 b5_t55_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t55_lwe), .wa(b5_t55_lwa), .wcol(1'b0), .wd(b5_t55_lwd), .q0(b5_t55));
    logic [61:0] b5_t56;
    logic b5_t56_lwe; logic [6:0] b5_t56_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t56_lwd;
    always_ff @(posedge clk) begin b5_t56_lwe <= ld_v && ld_iq >= 11'd256 && ld_iq < 11'd264; b5_t56_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd256)}; b5_t56_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab56 b5_t56_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t56_lwe), .wa(b5_t56_lwa), .wcol(1'b0), .wd(b5_t56_lwd), .q0(b5_t56));
    logic [61:0] b5_t57;
    logic b5_t57_lwe; logic [6:0] b5_t57_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t57_lwd;
    always_ff @(posedge clk) begin b5_t57_lwe <= ld_v && ld_iq >= 11'd258 && ld_iq < 11'd266; b5_t57_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd258)}; b5_t57_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab57 b5_t57_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t57_lwe), .wa(b5_t57_lwa), .wcol(1'b0), .wd(b5_t57_lwd), .q0(b5_t57));
    logic [61:0] b5_t58;
    logic b5_t58_lwe; logic [6:0] b5_t58_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t58_lwd;
    always_ff @(posedge clk) begin b5_t58_lwe <= ld_v && ld_iq >= 11'd264 && ld_iq < 11'd272; b5_t58_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd264)}; b5_t58_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab58 b5_t58_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t58_lwe), .wa(b5_t58_lwa), .wcol(1'b0), .wd(b5_t58_lwd), .q0(b5_t58));
    logic [61:0] b5_t59;
    logic b5_t59_lwe; logic [6:0] b5_t59_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t59_lwd;
    always_ff @(posedge clk) begin b5_t59_lwe <= ld_v && ld_iq >= 11'd266 && ld_iq < 11'd274; b5_t59_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd266)}; b5_t59_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab59 b5_t59_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t59_lwe), .wa(b5_t59_lwa), .wcol(1'b0), .wd(b5_t59_lwd), .q0(b5_t59));
    logic [61:0] b5_t60;
    logic b5_t60_lwe; logic [6:0] b5_t60_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t60_lwd;
    always_ff @(posedge clk) begin b5_t60_lwe <= ld_v && ld_iq >= 11'd272 && ld_iq < 11'd280; b5_t60_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd272)}; b5_t60_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab60 b5_t60_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t60_lwe), .wa(b5_t60_lwa), .wcol(1'b0), .wd(b5_t60_lwd), .q0(b5_t60));
    logic [61:0] b5_t61;
    logic b5_t61_lwe; logic [6:0] b5_t61_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t61_lwd;
    always_ff @(posedge clk) begin b5_t61_lwe <= ld_v && ld_iq >= 11'd274 && ld_iq < 11'd282; b5_t61_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd274)}; b5_t61_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab61 b5_t61_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t61_lwe), .wa(b5_t61_lwa), .wcol(1'b0), .wd(b5_t61_lwd), .q0(b5_t61));
    logic [61:0] b5_t62;
    logic b5_t62_lwe; logic [6:0] b5_t62_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t62_lwd;
    always_ff @(posedge clk) begin b5_t62_lwe <= ld_v && ld_iq >= 11'd280 && ld_iq < 11'd288; b5_t62_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd280)}; b5_t62_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab62 b5_t62_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5]}), .we(b5_t62_lwe), .wa(b5_t62_lwa), .wcol(1'b0), .wd(b5_t62_lwd), .q0(b5_t62));
    logic [61:0] b5_t63;
    logic b5_t63_lwe; logic [6:0] b5_t63_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t63_lwd;
    always_ff @(posedge clk) begin b5_t63_lwe <= ld_v && ld_iq >= 11'd282 && ld_iq < 11'd290; b5_t63_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd282)}; b5_t63_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw2_tab63 b5_t63_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t63_lwe), .wa(b5_t63_lwa), .wcol(1'b0), .wd(b5_t63_lwd), .q0(b5_t63));
    logic [61:0] b5_l0_w;
    logic [44:0] b5_gq2_0_QH_c; assign b5_gq2_0_QH_c = b4_tag[48:4];
    logic [44:0] b5_gq2_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(45), .D(1)) b5_gq2_0_QH_i (.clk(clk), .din(b5_gq2_0_QH_c), .dout(b5_gq2_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq2_s0_QH;
    always_ff @(posedge clk) b5_gq2_s0_QH <= b5_gq2_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l0_gen (.clk(clk), .A(b5_t0), .B(b5_t1), .QH(b5_gq2_s0_QH), .P(b5_l0_w));
    logic [61:0] b5_l0_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l0_a_i (.clk(clk), .din(b4_g0_o[0]), .dout(b5_l0_a));
    logic [44:0] b5_mq27_0_QH_c; assign b5_mq27_0_QH_c = b4_tag[48:4];
    logic [44:0] b5_mq27_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(45), .D(26)) b5_mq27_0_QH_i (.clk(clk), .din(b5_mq27_0_QH_c), .dout(b5_mq27_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_mq27_s0_QH;
    always_ff @(posedge clk) b5_mq27_s0_QH <= b5_mq27_0_QH;
    logic [61:0] b5_l0_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l0_mul (.clk(clk), .A(b5_l0_a), .B(b5_l0_w), .QH(b5_mq27_s0_QH), .P(b5_l0_p));
    logic [61:0] b5_l1_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l1_gen (.clk(clk), .A(b5_t2), .B(b5_t3), .QH(b5_gq2_s0_QH), .P(b5_l1_w));
    logic [61:0] b5_l1_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l1_a_i (.clk(clk), .din(b4_g0_o[1]), .dout(b5_l1_a));
    logic [61:0] b5_l1_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l1_mul (.clk(clk), .A(b5_l1_a), .B(b5_l1_w), .QH(b5_mq27_s0_QH), .P(b5_l1_p));
    logic [61:0] b5_l2_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l2_gen (.clk(clk), .A(b5_t4), .B(b5_t5), .QH(b5_gq2_s0_QH), .P(b5_l2_w));
    logic [61:0] b5_l2_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l2_a_i (.clk(clk), .din(b4_g0_o[2]), .dout(b5_l2_a));
    logic [61:0] b5_l2_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l2_mul (.clk(clk), .A(b5_l2_a), .B(b5_l2_w), .QH(b5_mq27_s0_QH), .P(b5_l2_p));
    logic [61:0] b5_l3_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l3_gen (.clk(clk), .A(b5_t6), .B(b5_t7), .QH(b5_gq2_s0_QH), .P(b5_l3_w));
    logic [61:0] b5_l3_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l3_a_i (.clk(clk), .din(b4_g0_o[3]), .dout(b5_l3_a));
    logic [61:0] b5_l3_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l3_mul (.clk(clk), .A(b5_l3_a), .B(b5_l3_w), .QH(b5_mq27_s0_QH), .P(b5_l3_p));
    logic [61:0] b5_l4_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq2_s1_QH;
    always_ff @(posedge clk) b5_gq2_s1_QH <= b5_gq2_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l4_gen (.clk(clk), .A(b5_t8), .B(b5_t9), .QH(b5_gq2_s1_QH), .P(b5_l4_w));
    logic [61:0] b5_l4_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l4_a_i (.clk(clk), .din(b4_g0_o[4]), .dout(b5_l4_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_mq27_s1_QH;
    always_ff @(posedge clk) b5_mq27_s1_QH <= b5_mq27_0_QH;
    logic [61:0] b5_l4_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l4_mul (.clk(clk), .A(b5_l4_a), .B(b5_l4_w), .QH(b5_mq27_s1_QH), .P(b5_l4_p));
    logic [61:0] b5_l5_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l5_gen (.clk(clk), .A(b5_t10), .B(b5_t11), .QH(b5_gq2_s1_QH), .P(b5_l5_w));
    logic [61:0] b5_l5_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l5_a_i (.clk(clk), .din(b4_g0_o[5]), .dout(b5_l5_a));
    logic [61:0] b5_l5_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l5_mul (.clk(clk), .A(b5_l5_a), .B(b5_l5_w), .QH(b5_mq27_s1_QH), .P(b5_l5_p));
    logic [61:0] b5_l6_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l6_gen (.clk(clk), .A(b5_t12), .B(b5_t13), .QH(b5_gq2_s1_QH), .P(b5_l6_w));
    logic [61:0] b5_l6_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l6_a_i (.clk(clk), .din(b4_g0_o[6]), .dout(b5_l6_a));
    logic [61:0] b5_l6_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l6_mul (.clk(clk), .A(b5_l6_a), .B(b5_l6_w), .QH(b5_mq27_s1_QH), .P(b5_l6_p));
    logic [61:0] b5_l7_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l7_gen (.clk(clk), .A(b5_t14), .B(b5_t15), .QH(b5_gq2_s1_QH), .P(b5_l7_w));
    logic [61:0] b5_l7_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l7_a_i (.clk(clk), .din(b4_g0_o[7]), .dout(b5_l7_a));
    logic [61:0] b5_l7_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l7_mul (.clk(clk), .A(b5_l7_a), .B(b5_l7_w), .QH(b5_mq27_s1_QH), .P(b5_l7_p));
    logic [61:0] b5_l8_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq2_s2_QH;
    always_ff @(posedge clk) b5_gq2_s2_QH <= b5_gq2_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l8_gen (.clk(clk), .A(b5_t16), .B(b5_t17), .QH(b5_gq2_s2_QH), .P(b5_l8_w));
    logic [61:0] b5_l8_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l8_a_i (.clk(clk), .din(b4_g0_o[8]), .dout(b5_l8_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_mq27_s2_QH;
    always_ff @(posedge clk) b5_mq27_s2_QH <= b5_mq27_0_QH;
    logic [61:0] b5_l8_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l8_mul (.clk(clk), .A(b5_l8_a), .B(b5_l8_w), .QH(b5_mq27_s2_QH), .P(b5_l8_p));
    logic [61:0] b5_l9_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l9_gen (.clk(clk), .A(b5_t18), .B(b5_t19), .QH(b5_gq2_s2_QH), .P(b5_l9_w));
    logic [61:0] b5_l9_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l9_a_i (.clk(clk), .din(b4_g0_o[9]), .dout(b5_l9_a));
    logic [61:0] b5_l9_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l9_mul (.clk(clk), .A(b5_l9_a), .B(b5_l9_w), .QH(b5_mq27_s2_QH), .P(b5_l9_p));
    logic [61:0] b5_l10_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l10_gen (.clk(clk), .A(b5_t20), .B(b5_t21), .QH(b5_gq2_s2_QH), .P(b5_l10_w));
    logic [61:0] b5_l10_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l10_a_i (.clk(clk), .din(b4_g0_o[10]), .dout(b5_l10_a));
    logic [61:0] b5_l10_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l10_mul (.clk(clk), .A(b5_l10_a), .B(b5_l10_w), .QH(b5_mq27_s2_QH), .P(b5_l10_p));
    logic [61:0] b5_l11_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l11_gen (.clk(clk), .A(b5_t22), .B(b5_t23), .QH(b5_gq2_s2_QH), .P(b5_l11_w));
    logic [61:0] b5_l11_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l11_a_i (.clk(clk), .din(b4_g0_o[11]), .dout(b5_l11_a));
    logic [61:0] b5_l11_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l11_mul (.clk(clk), .A(b5_l11_a), .B(b5_l11_w), .QH(b5_mq27_s2_QH), .P(b5_l11_p));
    logic [61:0] b5_l12_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq2_s3_QH;
    always_ff @(posedge clk) b5_gq2_s3_QH <= b5_gq2_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l12_gen (.clk(clk), .A(b5_t24), .B(b5_t25), .QH(b5_gq2_s3_QH), .P(b5_l12_w));
    logic [61:0] b5_l12_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l12_a_i (.clk(clk), .din(b4_g0_o[12]), .dout(b5_l12_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_mq27_s3_QH;
    always_ff @(posedge clk) b5_mq27_s3_QH <= b5_mq27_0_QH;
    logic [61:0] b5_l12_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l12_mul (.clk(clk), .A(b5_l12_a), .B(b5_l12_w), .QH(b5_mq27_s3_QH), .P(b5_l12_p));
    logic [61:0] b5_l13_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l13_gen (.clk(clk), .A(b5_t26), .B(b5_t27), .QH(b5_gq2_s3_QH), .P(b5_l13_w));
    logic [61:0] b5_l13_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l13_a_i (.clk(clk), .din(b4_g0_o[13]), .dout(b5_l13_a));
    logic [61:0] b5_l13_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l13_mul (.clk(clk), .A(b5_l13_a), .B(b5_l13_w), .QH(b5_mq27_s3_QH), .P(b5_l13_p));
    logic [61:0] b5_l14_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l14_gen (.clk(clk), .A(b5_t28), .B(b5_t29), .QH(b5_gq2_s3_QH), .P(b5_l14_w));
    logic [61:0] b5_l14_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l14_a_i (.clk(clk), .din(b4_g0_o[14]), .dout(b5_l14_a));
    logic [61:0] b5_l14_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l14_mul (.clk(clk), .A(b5_l14_a), .B(b5_l14_w), .QH(b5_mq27_s3_QH), .P(b5_l14_p));
    logic [61:0] b5_l15_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l15_gen (.clk(clk), .A(b5_t30), .B(b5_t31), .QH(b5_gq2_s3_QH), .P(b5_l15_w));
    logic [61:0] b5_l15_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l15_a_i (.clk(clk), .din(b4_g0_o[15]), .dout(b5_l15_a));
    logic [61:0] b5_l15_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l15_mul (.clk(clk), .A(b5_l15_a), .B(b5_l15_w), .QH(b5_mq27_s3_QH), .P(b5_l15_p));
    logic [61:0] b5_l16_w;
    logic [44:0] b5_gq2_1_QH_c; assign b5_gq2_1_QH_c = b4_tag[48:4];
    logic [44:0] b5_gq2_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(45), .D(1)) b5_gq2_1_QH_i (.clk(clk), .din(b5_gq2_1_QH_c), .dout(b5_gq2_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq2_s4_QH;
    always_ff @(posedge clk) b5_gq2_s4_QH <= b5_gq2_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l16_gen (.clk(clk), .A(b5_t32), .B(b5_t33), .QH(b5_gq2_s4_QH), .P(b5_l16_w));
    logic [61:0] b5_l16_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l16_a_i (.clk(clk), .din(b4_g0_o[16]), .dout(b5_l16_a));
    logic [44:0] b5_mq27_1_QH_c; assign b5_mq27_1_QH_c = b4_tag[48:4];
    logic [44:0] b5_mq27_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(45), .D(26)) b5_mq27_1_QH_i (.clk(clk), .din(b5_mq27_1_QH_c), .dout(b5_mq27_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_mq27_s4_QH;
    always_ff @(posedge clk) b5_mq27_s4_QH <= b5_mq27_1_QH;
    logic [61:0] b5_l16_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l16_mul (.clk(clk), .A(b5_l16_a), .B(b5_l16_w), .QH(b5_mq27_s4_QH), .P(b5_l16_p));
    logic [61:0] b5_l17_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l17_gen (.clk(clk), .A(b5_t34), .B(b5_t35), .QH(b5_gq2_s4_QH), .P(b5_l17_w));
    logic [61:0] b5_l17_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l17_a_i (.clk(clk), .din(b4_g0_o[17]), .dout(b5_l17_a));
    logic [61:0] b5_l17_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l17_mul (.clk(clk), .A(b5_l17_a), .B(b5_l17_w), .QH(b5_mq27_s4_QH), .P(b5_l17_p));
    logic [61:0] b5_l18_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l18_gen (.clk(clk), .A(b5_t36), .B(b5_t37), .QH(b5_gq2_s4_QH), .P(b5_l18_w));
    logic [61:0] b5_l18_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l18_a_i (.clk(clk), .din(b4_g0_o[18]), .dout(b5_l18_a));
    logic [61:0] b5_l18_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l18_mul (.clk(clk), .A(b5_l18_a), .B(b5_l18_w), .QH(b5_mq27_s4_QH), .P(b5_l18_p));
    logic [61:0] b5_l19_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l19_gen (.clk(clk), .A(b5_t38), .B(b5_t39), .QH(b5_gq2_s4_QH), .P(b5_l19_w));
    logic [61:0] b5_l19_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l19_a_i (.clk(clk), .din(b4_g0_o[19]), .dout(b5_l19_a));
    logic [61:0] b5_l19_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l19_mul (.clk(clk), .A(b5_l19_a), .B(b5_l19_w), .QH(b5_mq27_s4_QH), .P(b5_l19_p));
    logic [61:0] b5_l20_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq2_s5_QH;
    always_ff @(posedge clk) b5_gq2_s5_QH <= b5_gq2_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l20_gen (.clk(clk), .A(b5_t40), .B(b5_t41), .QH(b5_gq2_s5_QH), .P(b5_l20_w));
    logic [61:0] b5_l20_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l20_a_i (.clk(clk), .din(b4_g0_o[20]), .dout(b5_l20_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_mq27_s5_QH;
    always_ff @(posedge clk) b5_mq27_s5_QH <= b5_mq27_1_QH;
    logic [61:0] b5_l20_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l20_mul (.clk(clk), .A(b5_l20_a), .B(b5_l20_w), .QH(b5_mq27_s5_QH), .P(b5_l20_p));
    logic [61:0] b5_l21_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l21_gen (.clk(clk), .A(b5_t42), .B(b5_t43), .QH(b5_gq2_s5_QH), .P(b5_l21_w));
    logic [61:0] b5_l21_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l21_a_i (.clk(clk), .din(b4_g0_o[21]), .dout(b5_l21_a));
    logic [61:0] b5_l21_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l21_mul (.clk(clk), .A(b5_l21_a), .B(b5_l21_w), .QH(b5_mq27_s5_QH), .P(b5_l21_p));
    logic [61:0] b5_l22_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l22_gen (.clk(clk), .A(b5_t44), .B(b5_t45), .QH(b5_gq2_s5_QH), .P(b5_l22_w));
    logic [61:0] b5_l22_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l22_a_i (.clk(clk), .din(b4_g0_o[22]), .dout(b5_l22_a));
    logic [61:0] b5_l22_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l22_mul (.clk(clk), .A(b5_l22_a), .B(b5_l22_w), .QH(b5_mq27_s5_QH), .P(b5_l22_p));
    logic [61:0] b5_l23_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l23_gen (.clk(clk), .A(b5_t46), .B(b5_t47), .QH(b5_gq2_s5_QH), .P(b5_l23_w));
    logic [61:0] b5_l23_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l23_a_i (.clk(clk), .din(b4_g0_o[23]), .dout(b5_l23_a));
    logic [61:0] b5_l23_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l23_mul (.clk(clk), .A(b5_l23_a), .B(b5_l23_w), .QH(b5_mq27_s5_QH), .P(b5_l23_p));
    logic [61:0] b5_l24_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq2_s6_QH;
    always_ff @(posedge clk) b5_gq2_s6_QH <= b5_gq2_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l24_gen (.clk(clk), .A(b5_t48), .B(b5_t49), .QH(b5_gq2_s6_QH), .P(b5_l24_w));
    logic [61:0] b5_l24_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l24_a_i (.clk(clk), .din(b4_g0_o[24]), .dout(b5_l24_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_mq27_s6_QH;
    always_ff @(posedge clk) b5_mq27_s6_QH <= b5_mq27_1_QH;
    logic [61:0] b5_l24_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l24_mul (.clk(clk), .A(b5_l24_a), .B(b5_l24_w), .QH(b5_mq27_s6_QH), .P(b5_l24_p));
    logic [61:0] b5_l25_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l25_gen (.clk(clk), .A(b5_t50), .B(b5_t51), .QH(b5_gq2_s6_QH), .P(b5_l25_w));
    logic [61:0] b5_l25_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l25_a_i (.clk(clk), .din(b4_g0_o[25]), .dout(b5_l25_a));
    logic [61:0] b5_l25_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l25_mul (.clk(clk), .A(b5_l25_a), .B(b5_l25_w), .QH(b5_mq27_s6_QH), .P(b5_l25_p));
    logic [61:0] b5_l26_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l26_gen (.clk(clk), .A(b5_t52), .B(b5_t53), .QH(b5_gq2_s6_QH), .P(b5_l26_w));
    logic [61:0] b5_l26_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l26_a_i (.clk(clk), .din(b4_g0_o[26]), .dout(b5_l26_a));
    logic [61:0] b5_l26_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l26_mul (.clk(clk), .A(b5_l26_a), .B(b5_l26_w), .QH(b5_mq27_s6_QH), .P(b5_l26_p));
    logic [61:0] b5_l27_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l27_gen (.clk(clk), .A(b5_t54), .B(b5_t55), .QH(b5_gq2_s6_QH), .P(b5_l27_w));
    logic [61:0] b5_l27_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l27_a_i (.clk(clk), .din(b4_g0_o[27]), .dout(b5_l27_a));
    logic [61:0] b5_l27_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l27_mul (.clk(clk), .A(b5_l27_a), .B(b5_l27_w), .QH(b5_mq27_s6_QH), .P(b5_l27_p));
    logic [61:0] b5_l28_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq2_s7_QH;
    always_ff @(posedge clk) b5_gq2_s7_QH <= b5_gq2_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l28_gen (.clk(clk), .A(b5_t56), .B(b5_t57), .QH(b5_gq2_s7_QH), .P(b5_l28_w));
    logic [61:0] b5_l28_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l28_a_i (.clk(clk), .din(b4_g0_o[28]), .dout(b5_l28_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_mq27_s7_QH;
    always_ff @(posedge clk) b5_mq27_s7_QH <= b5_mq27_1_QH;
    logic [61:0] b5_l28_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l28_mul (.clk(clk), .A(b5_l28_a), .B(b5_l28_w), .QH(b5_mq27_s7_QH), .P(b5_l28_p));
    logic [61:0] b5_l29_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l29_gen (.clk(clk), .A(b5_t58), .B(b5_t59), .QH(b5_gq2_s7_QH), .P(b5_l29_w));
    logic [61:0] b5_l29_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l29_a_i (.clk(clk), .din(b4_g0_o[29]), .dout(b5_l29_a));
    logic [61:0] b5_l29_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l29_mul (.clk(clk), .A(b5_l29_a), .B(b5_l29_w), .QH(b5_mq27_s7_QH), .P(b5_l29_p));
    logic [61:0] b5_l30_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l30_gen (.clk(clk), .A(b5_t60), .B(b5_t61), .QH(b5_gq2_s7_QH), .P(b5_l30_w));
    logic [61:0] b5_l30_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l30_a_i (.clk(clk), .din(b4_g0_o[30]), .dout(b5_l30_a));
    logic [61:0] b5_l30_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l30_mul (.clk(clk), .A(b5_l30_a), .B(b5_l30_w), .QH(b5_mq27_s7_QH), .P(b5_l30_p));
    logic [61:0] b5_l31_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b5_l31_gen (.clk(clk), .A(b5_t62), .B(b5_t63), .QH(b5_gq2_s7_QH), .P(b5_l31_w));
    logic [61:0] b5_l31_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b5_l31_a_i (.clk(clk), .din(b4_g0_o[31]), .dout(b5_l31_a));
    logic [61:0] b5_l31_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b5_l31_mul (.clk(clk), .A(b5_l31_a), .B(b5_l31_w), .QH(b5_mq27_s7_QH), .P(b5_l31_p));
    logic [51:0] b5_v_sr;
    always_ff @(posedge clk) b5_v_sr <= rst ? '0 : {b5_v_sr[50:0], b4_g0_v};
    logic b5_v; assign b5_v = b5_v_sr[51];
    logic [110:0] b5_tag;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(111), .D(52)) b5_tag_i (.clk(clk), .din(b4_tag), .dout(b5_tag));
    // block 6: pass 2, 1 x ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p2 (32-point), latency 118
    logic [61:0] b6_c0_y0, b6_c0_y1, b6_c0_y2, b6_c0_y3, b6_c0_y4, b6_c0_y5, b6_c0_y6, b6_c0_y7, b6_c0_y8, b6_c0_y9, b6_c0_y10, b6_c0_y11, b6_c0_y12, b6_c0_y13, b6_c0_y14, b6_c0_y15, b6_c0_y16, b6_c0_y17, b6_c0_y18, b6_c0_y19, b6_c0_y20, b6_c0_y21, b6_c0_y22, b6_c0_y23, b6_c0_y24, b6_c0_y25, b6_c0_y26, b6_c0_y27, b6_c0_y28, b6_c0_y29, b6_c0_y30, b6_c0_y31;
    logic b6_c0_v; logic [2:0] b6_c0_mi; logic b6_c0_di;
    logic b6_c0_lr, b6_c0_lw; (* equivalent_register_removal = "no" *) logic [61:0] b6_c0_ld;
    always_ff @(posedge clk) begin b6_c0_lr <= ld_r; b6_c0_lw <= ld_v && ld_iq >= 11'd288 && ld_iq < 11'd303; b6_c0_ld <= ld_d[61:0]; end
    logic [2:0] b6_c0_ls; always_ff @(posedge clk) b6_c0_ls <= ld_sl;
    logic b6_c0_ldr; always_ff @(posedge clk) b6_c0_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p2 b6_c0 (.clk(clk), .rst(rst), .in_valid(b5_v), .out_valid(b6_c0_v), .MIDX(b5_tag[3:1]), .midx_out(b6_c0_mi), .mq_QH(b5_tag[48:4]), .mq_QHALF(b5_tag[110:49]), .DIR(b5_tag[0]), .dir_out(b6_c0_di), .tw_rst(b6_c0_lr), .tw_wen(b6_c0_lw), .tw_wdata(b6_c0_ld), .tw_slot(b6_c0_ls), .tw_dir(b6_c0_ldr), .x_in_0(b5_l0_p), .x_in_1(b5_l1_p), .x_in_2(b5_l2_p), .x_in_3(b5_l3_p), .x_in_4(b5_l4_p), .x_in_5(b5_l5_p), .x_in_6(b5_l6_p), .x_in_7(b5_l7_p), .x_in_8(b5_l8_p), .x_in_9(b5_l9_p), .x_in_10(b5_l10_p), .x_in_11(b5_l11_p), .x_in_12(b5_l12_p), .x_in_13(b5_l13_p), .x_in_14(b5_l14_p), .x_in_15(b5_l15_p), .x_in_16(b5_l16_p), .x_in_17(b5_l17_p), .x_in_18(b5_l18_p), .x_in_19(b5_l19_p), .x_in_20(b5_l20_p), .x_in_21(b5_l21_p), .x_in_22(b5_l22_p), .x_in_23(b5_l23_p), .x_in_24(b5_l24_p), .x_in_25(b5_l25_p), .x_in_26(b5_l26_p), .x_in_27(b5_l27_p), .x_in_28(b5_l28_p), .x_in_29(b5_l29_p), .x_in_30(b5_l30_p), .x_in_31(b5_l31_p), .y_out_0(b6_c0_y0), .y_out_1(b6_c0_y1), .y_out_2(b6_c0_y2), .y_out_3(b6_c0_y3), .y_out_4(b6_c0_y4), .y_out_5(b6_c0_y5), .y_out_6(b6_c0_y6), .y_out_7(b6_c0_y7), .y_out_8(b6_c0_y8), .y_out_9(b6_c0_y9), .y_out_10(b6_c0_y10), .y_out_11(b6_c0_y11), .y_out_12(b6_c0_y12), .y_out_13(b6_c0_y13), .y_out_14(b6_c0_y14), .y_out_15(b6_c0_y15), .y_out_16(b6_c0_y16), .y_out_17(b6_c0_y17), .y_out_18(b6_c0_y18), .y_out_19(b6_c0_y19), .y_out_20(b6_c0_y20), .y_out_21(b6_c0_y21), .y_out_22(b6_c0_y22), .y_out_23(b6_c0_y23), .y_out_24(b6_c0_y24), .y_out_25(b6_c0_y25), .y_out_26(b6_c0_y26), .y_out_27(b6_c0_y27), .y_out_28(b6_c0_y28), .y_out_29(b6_c0_y29), .y_out_30(b6_c0_y30), .y_out_31(b6_c0_y31));
    logic [106:0] b6_cq0; assign b6_cq0 = b5_tag[110:4];
    logic [106:0] b6_cq;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(107), .D(118)) b6_cq_i (.clk(clk), .din(b6_cq0), .dout(b6_cq));
    logic [110:0] b6_tag; assign b6_tag = {b6_cq, b6_c0_mi, b6_c0_di};
    // block 7: lane-time transpose, lane bits [0, 1, 2, 3, 4] <-> cycle bits [0,5), 1 x S=32, latency 39
    logic [61:0] b7_g0_i [0:31]; logic [61:0] b7_g0_o [0:31]; logic b7_g0_v;
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
    assign b7_g0_i[16] = b6_c0_y16;
    assign b7_g0_i[17] = b6_c0_y17;
    assign b7_g0_i[18] = b6_c0_y18;
    assign b7_g0_i[19] = b6_c0_y19;
    assign b7_g0_i[20] = b6_c0_y20;
    assign b7_g0_i[21] = b6_c0_y21;
    assign b7_g0_i[22] = b6_c0_y22;
    assign b7_g0_i[23] = b6_c0_y23;
    assign b7_g0_i[24] = b6_c0_y24;
    assign b7_g0_i[25] = b6_c0_y25;
    assign b7_g0_i[26] = b6_c0_y26;
    assign b7_g0_i[27] = b6_c0_y27;
    assign b7_g0_i[28] = b6_c0_y28;
    assign b7_g0_i[29] = b6_c0_y29;
    assign b7_g0_i[30] = b6_c0_y30;
    assign b7_g0_i[31] = b6_c0_y31;
    lt_bmb_transpose #(.S(32), .LO(0), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h7), .RAM_STYLE("distributed")) b7_g0 (.clk(clk), .rst(rst), .data_valid(b6_c0_v), .data_in(b7_g0_i), .data_out_valid(b7_g0_v), .data_out(b7_g0_o));
    logic [110:0] b7_tag;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(111), .D(39)) b7_tag_i (.clk(clk), .din(b6_tag), .dout(b7_tag));
    // block 8: twiddle stage 3, latency 52 (tables 2, generator 25, multiplier 25)
    logic [10:0] b8_cnt;
    always_ff @(posedge clk) b8_cnt <= rst ? '0 : (b7_g0_v ? b8_cnt + 1'b1 : b8_cnt);
    logic [61:0] b8_t0;
    logic b8_t0_lwe; logic [6:0] b8_t0_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t0_lwd;
    always_ff @(posedge clk) begin b8_t0_lwe <= ld_v && ld_iq >= 11'd290 && ld_iq < 11'd298; b8_t0_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 11'd290)}; b8_t0_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab0 b8_t0_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t0_lwe), .wa(b8_t0_lwa), .wcol(1'b0), .wd(b8_t0_lwd), .q0(b8_t0));
    logic [61:0] b8_t1;
    logic b8_t1_lwe; logic [5:0] b8_t1_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t1_lwd;
    always_ff @(posedge clk) begin b8_t1_lwe <= ld_v && ld_iq >= 11'd298 && ld_iq < 11'd302; b8_t1_lwa <= {ld_slq[2:0], ld_drq, 2'(ld_iq - 11'd298)}; b8_t1_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab1 b8_t1_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[4], b8_cnt[3]}), .we(b8_t1_lwe), .wa(b8_t1_lwa), .wcol(1'b0), .wd(b8_t1_lwd), .q0(b8_t1));
    logic [61:0] b8_t2;
    logic b8_t2_lwe; logic [9:0] b8_t2_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t2_lwd;
    always_ff @(posedge clk) begin b8_t2_lwe <= ld_v && ld_iq >= 11'd302 && ld_iq < 11'd366; b8_t2_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd302)}; b8_t2_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab2 b8_t2_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t2_lwe), .wa(b8_t2_lwa), .wcol(1'b0), .wd(b8_t2_lwd), .q0(b8_t2));
    logic [61:0] b8_t3;
    logic b8_t3_lwe; logic [8:0] b8_t3_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t3_lwd;
    always_ff @(posedge clk) begin b8_t3_lwe <= ld_v && ld_iq >= 11'd303 && ld_iq < 11'd335; b8_t3_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd303)}; b8_t3_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab3 b8_t3_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t3_lwe), .wa(b8_t3_lwa), .wcol(1'b0), .wd(b8_t3_lwd), .q0(b8_t3));
    logic [61:0] b8_t4;
    logic b8_t4_lwe; logic [9:0] b8_t4_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t4_lwd;
    always_ff @(posedge clk) begin b8_t4_lwe <= ld_v && ld_iq >= 11'd335 && ld_iq < 11'd399; b8_t4_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd335)}; b8_t4_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab4 b8_t4_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t4_lwe), .wa(b8_t4_lwa), .wcol(1'b0), .wd(b8_t4_lwd), .q0(b8_t4));
    logic [61:0] b8_t5;
    logic b8_t5_lwe; logic [8:0] b8_t5_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t5_lwd;
    always_ff @(posedge clk) begin b8_t5_lwe <= ld_v && ld_iq >= 11'd366 && ld_iq < 11'd398; b8_t5_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd366)}; b8_t5_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab5 b8_t5_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t5_lwe), .wa(b8_t5_lwa), .wcol(1'b0), .wd(b8_t5_lwd), .q0(b8_t5));
    logic [61:0] b8_t6;
    logic b8_t6_lwe; logic [9:0] b8_t6_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t6_lwd;
    always_ff @(posedge clk) begin b8_t6_lwe <= ld_v && ld_iq >= 11'd398 && ld_iq < 11'd462; b8_t6_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd398)}; b8_t6_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab6 b8_t6_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t6_lwe), .wa(b8_t6_lwa), .wcol(1'b0), .wd(b8_t6_lwd), .q0(b8_t6));
    logic [61:0] b8_t7;
    logic b8_t7_lwe; logic [8:0] b8_t7_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t7_lwd;
    always_ff @(posedge clk) begin b8_t7_lwe <= ld_v && ld_iq >= 11'd399 && ld_iq < 11'd431; b8_t7_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd399)}; b8_t7_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab7 b8_t7_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t7_lwe), .wa(b8_t7_lwa), .wcol(1'b0), .wd(b8_t7_lwd), .q0(b8_t7));
    logic [61:0] b8_t8;
    logic b8_t8_lwe; logic [9:0] b8_t8_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t8_lwd;
    always_ff @(posedge clk) begin b8_t8_lwe <= ld_v && ld_iq >= 11'd431 && ld_iq < 11'd495; b8_t8_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd431)}; b8_t8_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab8 b8_t8_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t8_lwe), .wa(b8_t8_lwa), .wcol(1'b0), .wd(b8_t8_lwd), .q0(b8_t8));
    logic [61:0] b8_t9;
    logic b8_t9_lwe; logic [8:0] b8_t9_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t9_lwd;
    always_ff @(posedge clk) begin b8_t9_lwe <= ld_v && ld_iq >= 11'd462 && ld_iq < 11'd494; b8_t9_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd462)}; b8_t9_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab9 b8_t9_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t9_lwe), .wa(b8_t9_lwa), .wcol(1'b0), .wd(b8_t9_lwd), .q0(b8_t9));
    logic [61:0] b8_t10;
    logic b8_t10_lwe; logic [9:0] b8_t10_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t10_lwd;
    always_ff @(posedge clk) begin b8_t10_lwe <= ld_v && ld_iq >= 11'd494 && ld_iq < 11'd558; b8_t10_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd494)}; b8_t10_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab10 b8_t10_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t10_lwe), .wa(b8_t10_lwa), .wcol(1'b0), .wd(b8_t10_lwd), .q0(b8_t10));
    logic [61:0] b8_t11;
    logic b8_t11_lwe; logic [8:0] b8_t11_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t11_lwd;
    always_ff @(posedge clk) begin b8_t11_lwe <= ld_v && ld_iq >= 11'd495 && ld_iq < 11'd527; b8_t11_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd495)}; b8_t11_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab11 b8_t11_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t11_lwe), .wa(b8_t11_lwa), .wcol(1'b0), .wd(b8_t11_lwd), .q0(b8_t11));
    logic [61:0] b8_t12;
    logic b8_t12_lwe; logic [9:0] b8_t12_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t12_lwd;
    always_ff @(posedge clk) begin b8_t12_lwe <= ld_v && ld_iq >= 11'd527 && ld_iq < 11'd591; b8_t12_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd527)}; b8_t12_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab12 b8_t12_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t12_lwe), .wa(b8_t12_lwa), .wcol(1'b0), .wd(b8_t12_lwd), .q0(b8_t12));
    logic [61:0] b8_t13;
    logic b8_t13_lwe; logic [8:0] b8_t13_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t13_lwd;
    always_ff @(posedge clk) begin b8_t13_lwe <= ld_v && ld_iq >= 11'd558 && ld_iq < 11'd590; b8_t13_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd558)}; b8_t13_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab13 b8_t13_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t13_lwe), .wa(b8_t13_lwa), .wcol(1'b0), .wd(b8_t13_lwd), .q0(b8_t13));
    logic [61:0] b8_t14;
    logic b8_t14_lwe; logic [9:0] b8_t14_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t14_lwd;
    always_ff @(posedge clk) begin b8_t14_lwe <= ld_v && ld_iq >= 11'd590 && ld_iq < 11'd654; b8_t14_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd590)}; b8_t14_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab14 b8_t14_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t14_lwe), .wa(b8_t14_lwa), .wcol(1'b0), .wd(b8_t14_lwd), .q0(b8_t14));
    logic [61:0] b8_t15;
    logic b8_t15_lwe; logic [8:0] b8_t15_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t15_lwd;
    always_ff @(posedge clk) begin b8_t15_lwe <= ld_v && ld_iq >= 11'd591 && ld_iq < 11'd623; b8_t15_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd591)}; b8_t15_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab15 b8_t15_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t15_lwe), .wa(b8_t15_lwa), .wcol(1'b0), .wd(b8_t15_lwd), .q0(b8_t15));
    logic [61:0] b8_t16;
    logic b8_t16_lwe; logic [9:0] b8_t16_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t16_lwd;
    always_ff @(posedge clk) begin b8_t16_lwe <= ld_v && ld_iq >= 11'd623 && ld_iq < 11'd687; b8_t16_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd623)}; b8_t16_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab16 b8_t16_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t16_lwe), .wa(b8_t16_lwa), .wcol(1'b0), .wd(b8_t16_lwd), .q0(b8_t16));
    logic [61:0] b8_t17;
    logic b8_t17_lwe; logic [8:0] b8_t17_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t17_lwd;
    always_ff @(posedge clk) begin b8_t17_lwe <= ld_v && ld_iq >= 11'd654 && ld_iq < 11'd686; b8_t17_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd654)}; b8_t17_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab17 b8_t17_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t17_lwe), .wa(b8_t17_lwa), .wcol(1'b0), .wd(b8_t17_lwd), .q0(b8_t17));
    logic [61:0] b8_t18;
    logic b8_t18_lwe; logic [9:0] b8_t18_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t18_lwd;
    always_ff @(posedge clk) begin b8_t18_lwe <= ld_v && ld_iq >= 11'd686 && ld_iq < 11'd750; b8_t18_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd686)}; b8_t18_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab18 b8_t18_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t18_lwe), .wa(b8_t18_lwa), .wcol(1'b0), .wd(b8_t18_lwd), .q0(b8_t18));
    logic [61:0] b8_t19;
    logic b8_t19_lwe; logic [8:0] b8_t19_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t19_lwd;
    always_ff @(posedge clk) begin b8_t19_lwe <= ld_v && ld_iq >= 11'd687 && ld_iq < 11'd719; b8_t19_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd687)}; b8_t19_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab19 b8_t19_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t19_lwe), .wa(b8_t19_lwa), .wcol(1'b0), .wd(b8_t19_lwd), .q0(b8_t19));
    logic [61:0] b8_t20;
    logic b8_t20_lwe; logic [9:0] b8_t20_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t20_lwd;
    always_ff @(posedge clk) begin b8_t20_lwe <= ld_v && ld_iq >= 11'd719 && ld_iq < 11'd783; b8_t20_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd719)}; b8_t20_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab20 b8_t20_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t20_lwe), .wa(b8_t20_lwa), .wcol(1'b0), .wd(b8_t20_lwd), .q0(b8_t20));
    logic [61:0] b8_t21;
    logic b8_t21_lwe; logic [8:0] b8_t21_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t21_lwd;
    always_ff @(posedge clk) begin b8_t21_lwe <= ld_v && ld_iq >= 11'd750 && ld_iq < 11'd782; b8_t21_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd750)}; b8_t21_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab21 b8_t21_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t21_lwe), .wa(b8_t21_lwa), .wcol(1'b0), .wd(b8_t21_lwd), .q0(b8_t21));
    logic [61:0] b8_t22;
    logic b8_t22_lwe; logic [9:0] b8_t22_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t22_lwd;
    always_ff @(posedge clk) begin b8_t22_lwe <= ld_v && ld_iq >= 11'd782 && ld_iq < 11'd846; b8_t22_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd782)}; b8_t22_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab22 b8_t22_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t22_lwe), .wa(b8_t22_lwa), .wcol(1'b0), .wd(b8_t22_lwd), .q0(b8_t22));
    logic [61:0] b8_t23;
    logic b8_t23_lwe; logic [8:0] b8_t23_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t23_lwd;
    always_ff @(posedge clk) begin b8_t23_lwe <= ld_v && ld_iq >= 11'd783 && ld_iq < 11'd815; b8_t23_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd783)}; b8_t23_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab23 b8_t23_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t23_lwe), .wa(b8_t23_lwa), .wcol(1'b0), .wd(b8_t23_lwd), .q0(b8_t23));
    logic [61:0] b8_t24;
    logic b8_t24_lwe; logic [9:0] b8_t24_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t24_lwd;
    always_ff @(posedge clk) begin b8_t24_lwe <= ld_v && ld_iq >= 11'd815 && ld_iq < 11'd879; b8_t24_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd815)}; b8_t24_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab24 b8_t24_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t24_lwe), .wa(b8_t24_lwa), .wcol(1'b0), .wd(b8_t24_lwd), .q0(b8_t24));
    logic [61:0] b8_t25;
    logic b8_t25_lwe; logic [8:0] b8_t25_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t25_lwd;
    always_ff @(posedge clk) begin b8_t25_lwe <= ld_v && ld_iq >= 11'd846 && ld_iq < 11'd878; b8_t25_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd846)}; b8_t25_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab25 b8_t25_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t25_lwe), .wa(b8_t25_lwa), .wcol(1'b0), .wd(b8_t25_lwd), .q0(b8_t25));
    logic [61:0] b8_t26;
    logic b8_t26_lwe; logic [9:0] b8_t26_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t26_lwd;
    always_ff @(posedge clk) begin b8_t26_lwe <= ld_v && ld_iq >= 11'd878 && ld_iq < 11'd942; b8_t26_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd878)}; b8_t26_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab26 b8_t26_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t26_lwe), .wa(b8_t26_lwa), .wcol(1'b0), .wd(b8_t26_lwd), .q0(b8_t26));
    logic [61:0] b8_t27;
    logic b8_t27_lwe; logic [8:0] b8_t27_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t27_lwd;
    always_ff @(posedge clk) begin b8_t27_lwe <= ld_v && ld_iq >= 11'd879 && ld_iq < 11'd911; b8_t27_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd879)}; b8_t27_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab27 b8_t27_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t27_lwe), .wa(b8_t27_lwa), .wcol(1'b0), .wd(b8_t27_lwd), .q0(b8_t27));
    logic [61:0] b8_t28;
    logic b8_t28_lwe; logic [9:0] b8_t28_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t28_lwd;
    always_ff @(posedge clk) begin b8_t28_lwe <= ld_v && ld_iq >= 11'd911 && ld_iq < 11'd975; b8_t28_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd911)}; b8_t28_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab28 b8_t28_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t28_lwe), .wa(b8_t28_lwa), .wcol(1'b0), .wd(b8_t28_lwd), .q0(b8_t28));
    logic [61:0] b8_t29;
    logic b8_t29_lwe; logic [8:0] b8_t29_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t29_lwd;
    always_ff @(posedge clk) begin b8_t29_lwe <= ld_v && ld_iq >= 11'd942 && ld_iq < 11'd974; b8_t29_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd942)}; b8_t29_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab29 b8_t29_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t29_lwe), .wa(b8_t29_lwa), .wcol(1'b0), .wd(b8_t29_lwd), .q0(b8_t29));
    logic [61:0] b8_t30;
    logic b8_t30_lwe; logic [9:0] b8_t30_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t30_lwd;
    always_ff @(posedge clk) begin b8_t30_lwe <= ld_v && ld_iq >= 11'd974 && ld_iq < 11'd1038; b8_t30_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd974)}; b8_t30_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab30 b8_t30_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t30_lwe), .wa(b8_t30_lwa), .wcol(1'b0), .wd(b8_t30_lwd), .q0(b8_t30));
    logic [61:0] b8_t31;
    logic b8_t31_lwe; logic [8:0] b8_t31_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t31_lwd;
    always_ff @(posedge clk) begin b8_t31_lwe <= ld_v && ld_iq >= 11'd975 && ld_iq < 11'd1007; b8_t31_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd975)}; b8_t31_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab31 b8_t31_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t31_lwe), .wa(b8_t31_lwa), .wcol(1'b0), .wd(b8_t31_lwd), .q0(b8_t31));
    logic [61:0] b8_t32;
    logic b8_t32_lwe; logic [9:0] b8_t32_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t32_lwd;
    always_ff @(posedge clk) begin b8_t32_lwe <= ld_v && ld_iq >= 11'd1007 && ld_iq < 11'd1071; b8_t32_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1007)}; b8_t32_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab32 b8_t32_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t32_lwe), .wa(b8_t32_lwa), .wcol(1'b0), .wd(b8_t32_lwd), .q0(b8_t32));
    logic [61:0] b8_t33;
    logic b8_t33_lwe; logic [8:0] b8_t33_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t33_lwd;
    always_ff @(posedge clk) begin b8_t33_lwe <= ld_v && ld_iq >= 11'd1038 && ld_iq < 11'd1070; b8_t33_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1038)}; b8_t33_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab33 b8_t33_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t33_lwe), .wa(b8_t33_lwa), .wcol(1'b0), .wd(b8_t33_lwd), .q0(b8_t33));
    logic [61:0] b8_t34;
    logic b8_t34_lwe; logic [9:0] b8_t34_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t34_lwd;
    always_ff @(posedge clk) begin b8_t34_lwe <= ld_v && ld_iq >= 11'd1070 && ld_iq < 11'd1134; b8_t34_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1070)}; b8_t34_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab34 b8_t34_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t34_lwe), .wa(b8_t34_lwa), .wcol(1'b0), .wd(b8_t34_lwd), .q0(b8_t34));
    logic [61:0] b8_t35;
    logic b8_t35_lwe; logic [8:0] b8_t35_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t35_lwd;
    always_ff @(posedge clk) begin b8_t35_lwe <= ld_v && ld_iq >= 11'd1071 && ld_iq < 11'd1103; b8_t35_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1071)}; b8_t35_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab35 b8_t35_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t35_lwe), .wa(b8_t35_lwa), .wcol(1'b0), .wd(b8_t35_lwd), .q0(b8_t35));
    logic [61:0] b8_t36;
    logic b8_t36_lwe; logic [9:0] b8_t36_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t36_lwd;
    always_ff @(posedge clk) begin b8_t36_lwe <= ld_v && ld_iq >= 11'd1103 && ld_iq < 11'd1167; b8_t36_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1103)}; b8_t36_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab36 b8_t36_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t36_lwe), .wa(b8_t36_lwa), .wcol(1'b0), .wd(b8_t36_lwd), .q0(b8_t36));
    logic [61:0] b8_t37;
    logic b8_t37_lwe; logic [8:0] b8_t37_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t37_lwd;
    always_ff @(posedge clk) begin b8_t37_lwe <= ld_v && ld_iq >= 11'd1134 && ld_iq < 11'd1166; b8_t37_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1134)}; b8_t37_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab37 b8_t37_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t37_lwe), .wa(b8_t37_lwa), .wcol(1'b0), .wd(b8_t37_lwd), .q0(b8_t37));
    logic [61:0] b8_t38;
    logic b8_t38_lwe; logic [9:0] b8_t38_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t38_lwd;
    always_ff @(posedge clk) begin b8_t38_lwe <= ld_v && ld_iq >= 11'd1166 && ld_iq < 11'd1230; b8_t38_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1166)}; b8_t38_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab38 b8_t38_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t38_lwe), .wa(b8_t38_lwa), .wcol(1'b0), .wd(b8_t38_lwd), .q0(b8_t38));
    logic [61:0] b8_t39;
    logic b8_t39_lwe; logic [8:0] b8_t39_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t39_lwd;
    always_ff @(posedge clk) begin b8_t39_lwe <= ld_v && ld_iq >= 11'd1167 && ld_iq < 11'd1199; b8_t39_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1167)}; b8_t39_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab39 b8_t39_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t39_lwe), .wa(b8_t39_lwa), .wcol(1'b0), .wd(b8_t39_lwd), .q0(b8_t39));
    logic [61:0] b8_t40;
    logic b8_t40_lwe; logic [9:0] b8_t40_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t40_lwd;
    always_ff @(posedge clk) begin b8_t40_lwe <= ld_v && ld_iq >= 11'd1199 && ld_iq < 11'd1263; b8_t40_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1199)}; b8_t40_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab40 b8_t40_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t40_lwe), .wa(b8_t40_lwa), .wcol(1'b0), .wd(b8_t40_lwd), .q0(b8_t40));
    logic [61:0] b8_t41;
    logic b8_t41_lwe; logic [8:0] b8_t41_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t41_lwd;
    always_ff @(posedge clk) begin b8_t41_lwe <= ld_v && ld_iq >= 11'd1230 && ld_iq < 11'd1262; b8_t41_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1230)}; b8_t41_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab41 b8_t41_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t41_lwe), .wa(b8_t41_lwa), .wcol(1'b0), .wd(b8_t41_lwd), .q0(b8_t41));
    logic [61:0] b8_t42;
    logic b8_t42_lwe; logic [9:0] b8_t42_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t42_lwd;
    always_ff @(posedge clk) begin b8_t42_lwe <= ld_v && ld_iq >= 11'd1262 && ld_iq < 11'd1326; b8_t42_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1262)}; b8_t42_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab42 b8_t42_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t42_lwe), .wa(b8_t42_lwa), .wcol(1'b0), .wd(b8_t42_lwd), .q0(b8_t42));
    logic [61:0] b8_t43;
    logic b8_t43_lwe; logic [8:0] b8_t43_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t43_lwd;
    always_ff @(posedge clk) begin b8_t43_lwe <= ld_v && ld_iq >= 11'd1263 && ld_iq < 11'd1295; b8_t43_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1263)}; b8_t43_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab43 b8_t43_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t43_lwe), .wa(b8_t43_lwa), .wcol(1'b0), .wd(b8_t43_lwd), .q0(b8_t43));
    logic [61:0] b8_t44;
    logic b8_t44_lwe; logic [9:0] b8_t44_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t44_lwd;
    always_ff @(posedge clk) begin b8_t44_lwe <= ld_v && ld_iq >= 11'd1295 && ld_iq < 11'd1359; b8_t44_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1295)}; b8_t44_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab44 b8_t44_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t44_lwe), .wa(b8_t44_lwa), .wcol(1'b0), .wd(b8_t44_lwd), .q0(b8_t44));
    logic [61:0] b8_t45;
    logic b8_t45_lwe; logic [8:0] b8_t45_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t45_lwd;
    always_ff @(posedge clk) begin b8_t45_lwe <= ld_v && ld_iq >= 11'd1326 && ld_iq < 11'd1358; b8_t45_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1326)}; b8_t45_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab45 b8_t45_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t45_lwe), .wa(b8_t45_lwa), .wcol(1'b0), .wd(b8_t45_lwd), .q0(b8_t45));
    logic [61:0] b8_t46;
    logic b8_t46_lwe; logic [9:0] b8_t46_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t46_lwd;
    always_ff @(posedge clk) begin b8_t46_lwe <= ld_v && ld_iq >= 11'd1358 && ld_iq < 11'd1422; b8_t46_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1358)}; b8_t46_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab46 b8_t46_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t46_lwe), .wa(b8_t46_lwa), .wcol(1'b0), .wd(b8_t46_lwd), .q0(b8_t46));
    logic [61:0] b8_t47;
    logic b8_t47_lwe; logic [8:0] b8_t47_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t47_lwd;
    always_ff @(posedge clk) begin b8_t47_lwe <= ld_v && ld_iq >= 11'd1359 && ld_iq < 11'd1391; b8_t47_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1359)}; b8_t47_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab47 b8_t47_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t47_lwe), .wa(b8_t47_lwa), .wcol(1'b0), .wd(b8_t47_lwd), .q0(b8_t47));
    logic [61:0] b8_t48;
    logic b8_t48_lwe; logic [9:0] b8_t48_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t48_lwd;
    always_ff @(posedge clk) begin b8_t48_lwe <= ld_v && ld_iq >= 11'd1391 && ld_iq < 11'd1455; b8_t48_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1391)}; b8_t48_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab48 b8_t48_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t48_lwe), .wa(b8_t48_lwa), .wcol(1'b0), .wd(b8_t48_lwd), .q0(b8_t48));
    logic [61:0] b8_t49;
    logic b8_t49_lwe; logic [8:0] b8_t49_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t49_lwd;
    always_ff @(posedge clk) begin b8_t49_lwe <= ld_v && ld_iq >= 11'd1422 && ld_iq < 11'd1454; b8_t49_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1422)}; b8_t49_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab49 b8_t49_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t49_lwe), .wa(b8_t49_lwa), .wcol(1'b0), .wd(b8_t49_lwd), .q0(b8_t49));
    logic [61:0] b8_t50;
    logic b8_t50_lwe; logic [9:0] b8_t50_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t50_lwd;
    always_ff @(posedge clk) begin b8_t50_lwe <= ld_v && ld_iq >= 11'd1454 && ld_iq < 11'd1518; b8_t50_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1454)}; b8_t50_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab50 b8_t50_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t50_lwe), .wa(b8_t50_lwa), .wcol(1'b0), .wd(b8_t50_lwd), .q0(b8_t50));
    logic [61:0] b8_t51;
    logic b8_t51_lwe; logic [8:0] b8_t51_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t51_lwd;
    always_ff @(posedge clk) begin b8_t51_lwe <= ld_v && ld_iq >= 11'd1455 && ld_iq < 11'd1487; b8_t51_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1455)}; b8_t51_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab51 b8_t51_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t51_lwe), .wa(b8_t51_lwa), .wcol(1'b0), .wd(b8_t51_lwd), .q0(b8_t51));
    logic [61:0] b8_t52;
    logic b8_t52_lwe; logic [9:0] b8_t52_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t52_lwd;
    always_ff @(posedge clk) begin b8_t52_lwe <= ld_v && ld_iq >= 11'd1487 && ld_iq < 11'd1551; b8_t52_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1487)}; b8_t52_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab52 b8_t52_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t52_lwe), .wa(b8_t52_lwa), .wcol(1'b0), .wd(b8_t52_lwd), .q0(b8_t52));
    logic [61:0] b8_t53;
    logic b8_t53_lwe; logic [8:0] b8_t53_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t53_lwd;
    always_ff @(posedge clk) begin b8_t53_lwe <= ld_v && ld_iq >= 11'd1518 && ld_iq < 11'd1550; b8_t53_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1518)}; b8_t53_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab53 b8_t53_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t53_lwe), .wa(b8_t53_lwa), .wcol(1'b0), .wd(b8_t53_lwd), .q0(b8_t53));
    logic [61:0] b8_t54;
    logic b8_t54_lwe; logic [9:0] b8_t54_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t54_lwd;
    always_ff @(posedge clk) begin b8_t54_lwe <= ld_v && ld_iq >= 11'd1550 && ld_iq < 11'd1614; b8_t54_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1550)}; b8_t54_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab54 b8_t54_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t54_lwe), .wa(b8_t54_lwa), .wcol(1'b0), .wd(b8_t54_lwd), .q0(b8_t54));
    logic [61:0] b8_t55;
    logic b8_t55_lwe; logic [8:0] b8_t55_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t55_lwd;
    always_ff @(posedge clk) begin b8_t55_lwe <= ld_v && ld_iq >= 11'd1551 && ld_iq < 11'd1583; b8_t55_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1551)}; b8_t55_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab55 b8_t55_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t55_lwe), .wa(b8_t55_lwa), .wcol(1'b0), .wd(b8_t55_lwd), .q0(b8_t55));
    logic [61:0] b8_t56;
    logic b8_t56_lwe; logic [9:0] b8_t56_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t56_lwd;
    always_ff @(posedge clk) begin b8_t56_lwe <= ld_v && ld_iq >= 11'd1583 && ld_iq < 11'd1647; b8_t56_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1583)}; b8_t56_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab56 b8_t56_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t56_lwe), .wa(b8_t56_lwa), .wcol(1'b0), .wd(b8_t56_lwd), .q0(b8_t56));
    logic [61:0] b8_t57;
    logic b8_t57_lwe; logic [8:0] b8_t57_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t57_lwd;
    always_ff @(posedge clk) begin b8_t57_lwe <= ld_v && ld_iq >= 11'd1614 && ld_iq < 11'd1646; b8_t57_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1614)}; b8_t57_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab57 b8_t57_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t57_lwe), .wa(b8_t57_lwa), .wcol(1'b0), .wd(b8_t57_lwd), .q0(b8_t57));
    logic [61:0] b8_t58;
    logic b8_t58_lwe; logic [9:0] b8_t58_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t58_lwd;
    always_ff @(posedge clk) begin b8_t58_lwe <= ld_v && ld_iq >= 11'd1646 && ld_iq < 11'd1710; b8_t58_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1646)}; b8_t58_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab58 b8_t58_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t58_lwe), .wa(b8_t58_lwa), .wcol(1'b0), .wd(b8_t58_lwd), .q0(b8_t58));
    logic [61:0] b8_t59;
    logic b8_t59_lwe; logic [8:0] b8_t59_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t59_lwd;
    always_ff @(posedge clk) begin b8_t59_lwe <= ld_v && ld_iq >= 11'd1647 && ld_iq < 11'd1679; b8_t59_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1647)}; b8_t59_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab59 b8_t59_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t59_lwe), .wa(b8_t59_lwa), .wcol(1'b0), .wd(b8_t59_lwd), .q0(b8_t59));
    logic [61:0] b8_t60;
    logic b8_t60_lwe; logic [9:0] b8_t60_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t60_lwd;
    always_ff @(posedge clk) begin b8_t60_lwe <= ld_v && ld_iq >= 11'd1679 && ld_iq < 11'd1743; b8_t60_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1679)}; b8_t60_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab60 b8_t60_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t60_lwe), .wa(b8_t60_lwa), .wcol(1'b0), .wd(b8_t60_lwd), .q0(b8_t60));
    logic [61:0] b8_t61;
    logic b8_t61_lwe; logic [8:0] b8_t61_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t61_lwd;
    always_ff @(posedge clk) begin b8_t61_lwe <= ld_v && ld_iq >= 11'd1710 && ld_iq < 11'd1742; b8_t61_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1710)}; b8_t61_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab61 b8_t61_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t61_lwe), .wa(b8_t61_lwa), .wcol(1'b0), .wd(b8_t61_lwd), .q0(b8_t61));
    logic [61:0] b8_t62;
    logic b8_t62_lwe; logic [9:0] b8_t62_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t62_lwd;
    always_ff @(posedge clk) begin b8_t62_lwe <= ld_v && ld_iq >= 11'd1742 && ld_iq < 11'd1806; b8_t62_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 11'd1742)}; b8_t62_lwd <= ld_d[123:62]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab62 b8_t62_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t62_lwe), .wa(b8_t62_lwa), .wcol(1'b0), .wd(b8_t62_lwd), .q0(b8_t62));
    logic [61:0] b8_t63;
    logic b8_t63_lwe; logic [8:0] b8_t63_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t63_lwd;
    always_ff @(posedge clk) begin b8_t63_lwe <= ld_v && ld_iq >= 11'd1743 && ld_iq < 11'd1775; b8_t63_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 11'd1743)}; b8_t63_lwd <= ld_d[61:0]; end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_tw3_tab63 b8_t63_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t63_lwe), .wa(b8_t63_lwa), .wcol(1'b0), .wd(b8_t63_lwd), .q0(b8_t63));
    logic [61:0] b8_l0_w;
    logic [44:0] b8_gq2_0_QH_c; assign b8_gq2_0_QH_c = b7_tag[48:4];
    logic [44:0] b8_gq2_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(45), .D(1)) b8_gq2_0_QH_i (.clk(clk), .din(b8_gq2_0_QH_c), .dout(b8_gq2_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq2_s0_QH;
    always_ff @(posedge clk) b8_gq2_s0_QH <= b8_gq2_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l0_gen (.clk(clk), .A(b8_t0), .B(b8_t1), .QH(b8_gq2_s0_QH), .P(b8_l0_w));
    logic [61:0] b8_l0_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l0_a_i (.clk(clk), .din(b7_g0_o[0]), .dout(b8_l0_a));
    logic [44:0] b8_mq27_0_QH_c; assign b8_mq27_0_QH_c = b7_tag[48:4];
    logic [44:0] b8_mq27_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(45), .D(26)) b8_mq27_0_QH_i (.clk(clk), .din(b8_mq27_0_QH_c), .dout(b8_mq27_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_mq27_s0_QH;
    always_ff @(posedge clk) b8_mq27_s0_QH <= b8_mq27_0_QH;
    logic [61:0] b8_l0_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l0_mul (.clk(clk), .A(b8_l0_a), .B(b8_l0_w), .QH(b8_mq27_s0_QH), .P(b8_l0_p));
    logic [61:0] b8_l1_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l1_gen (.clk(clk), .A(b8_t2), .B(b8_t3), .QH(b8_gq2_s0_QH), .P(b8_l1_w));
    logic [61:0] b8_l1_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l1_a_i (.clk(clk), .din(b7_g0_o[1]), .dout(b8_l1_a));
    logic [61:0] b8_l1_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l1_mul (.clk(clk), .A(b8_l1_a), .B(b8_l1_w), .QH(b8_mq27_s0_QH), .P(b8_l1_p));
    logic [61:0] b8_l2_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l2_gen (.clk(clk), .A(b8_t4), .B(b8_t5), .QH(b8_gq2_s0_QH), .P(b8_l2_w));
    logic [61:0] b8_l2_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l2_a_i (.clk(clk), .din(b7_g0_o[2]), .dout(b8_l2_a));
    logic [61:0] b8_l2_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l2_mul (.clk(clk), .A(b8_l2_a), .B(b8_l2_w), .QH(b8_mq27_s0_QH), .P(b8_l2_p));
    logic [61:0] b8_l3_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l3_gen (.clk(clk), .A(b8_t6), .B(b8_t7), .QH(b8_gq2_s0_QH), .P(b8_l3_w));
    logic [61:0] b8_l3_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l3_a_i (.clk(clk), .din(b7_g0_o[3]), .dout(b8_l3_a));
    logic [61:0] b8_l3_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l3_mul (.clk(clk), .A(b8_l3_a), .B(b8_l3_w), .QH(b8_mq27_s0_QH), .P(b8_l3_p));
    logic [61:0] b8_l4_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq2_s1_QH;
    always_ff @(posedge clk) b8_gq2_s1_QH <= b8_gq2_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l4_gen (.clk(clk), .A(b8_t8), .B(b8_t9), .QH(b8_gq2_s1_QH), .P(b8_l4_w));
    logic [61:0] b8_l4_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l4_a_i (.clk(clk), .din(b7_g0_o[4]), .dout(b8_l4_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_mq27_s1_QH;
    always_ff @(posedge clk) b8_mq27_s1_QH <= b8_mq27_0_QH;
    logic [61:0] b8_l4_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l4_mul (.clk(clk), .A(b8_l4_a), .B(b8_l4_w), .QH(b8_mq27_s1_QH), .P(b8_l4_p));
    logic [61:0] b8_l5_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l5_gen (.clk(clk), .A(b8_t10), .B(b8_t11), .QH(b8_gq2_s1_QH), .P(b8_l5_w));
    logic [61:0] b8_l5_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l5_a_i (.clk(clk), .din(b7_g0_o[5]), .dout(b8_l5_a));
    logic [61:0] b8_l5_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l5_mul (.clk(clk), .A(b8_l5_a), .B(b8_l5_w), .QH(b8_mq27_s1_QH), .P(b8_l5_p));
    logic [61:0] b8_l6_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l6_gen (.clk(clk), .A(b8_t12), .B(b8_t13), .QH(b8_gq2_s1_QH), .P(b8_l6_w));
    logic [61:0] b8_l6_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l6_a_i (.clk(clk), .din(b7_g0_o[6]), .dout(b8_l6_a));
    logic [61:0] b8_l6_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l6_mul (.clk(clk), .A(b8_l6_a), .B(b8_l6_w), .QH(b8_mq27_s1_QH), .P(b8_l6_p));
    logic [61:0] b8_l7_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l7_gen (.clk(clk), .A(b8_t14), .B(b8_t15), .QH(b8_gq2_s1_QH), .P(b8_l7_w));
    logic [61:0] b8_l7_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l7_a_i (.clk(clk), .din(b7_g0_o[7]), .dout(b8_l7_a));
    logic [61:0] b8_l7_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l7_mul (.clk(clk), .A(b8_l7_a), .B(b8_l7_w), .QH(b8_mq27_s1_QH), .P(b8_l7_p));
    logic [61:0] b8_l8_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq2_s2_QH;
    always_ff @(posedge clk) b8_gq2_s2_QH <= b8_gq2_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l8_gen (.clk(clk), .A(b8_t16), .B(b8_t17), .QH(b8_gq2_s2_QH), .P(b8_l8_w));
    logic [61:0] b8_l8_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l8_a_i (.clk(clk), .din(b7_g0_o[8]), .dout(b8_l8_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_mq27_s2_QH;
    always_ff @(posedge clk) b8_mq27_s2_QH <= b8_mq27_0_QH;
    logic [61:0] b8_l8_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l8_mul (.clk(clk), .A(b8_l8_a), .B(b8_l8_w), .QH(b8_mq27_s2_QH), .P(b8_l8_p));
    logic [61:0] b8_l9_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l9_gen (.clk(clk), .A(b8_t18), .B(b8_t19), .QH(b8_gq2_s2_QH), .P(b8_l9_w));
    logic [61:0] b8_l9_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l9_a_i (.clk(clk), .din(b7_g0_o[9]), .dout(b8_l9_a));
    logic [61:0] b8_l9_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l9_mul (.clk(clk), .A(b8_l9_a), .B(b8_l9_w), .QH(b8_mq27_s2_QH), .P(b8_l9_p));
    logic [61:0] b8_l10_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l10_gen (.clk(clk), .A(b8_t20), .B(b8_t21), .QH(b8_gq2_s2_QH), .P(b8_l10_w));
    logic [61:0] b8_l10_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l10_a_i (.clk(clk), .din(b7_g0_o[10]), .dout(b8_l10_a));
    logic [61:0] b8_l10_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l10_mul (.clk(clk), .A(b8_l10_a), .B(b8_l10_w), .QH(b8_mq27_s2_QH), .P(b8_l10_p));
    logic [61:0] b8_l11_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l11_gen (.clk(clk), .A(b8_t22), .B(b8_t23), .QH(b8_gq2_s2_QH), .P(b8_l11_w));
    logic [61:0] b8_l11_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l11_a_i (.clk(clk), .din(b7_g0_o[11]), .dout(b8_l11_a));
    logic [61:0] b8_l11_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l11_mul (.clk(clk), .A(b8_l11_a), .B(b8_l11_w), .QH(b8_mq27_s2_QH), .P(b8_l11_p));
    logic [61:0] b8_l12_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq2_s3_QH;
    always_ff @(posedge clk) b8_gq2_s3_QH <= b8_gq2_0_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l12_gen (.clk(clk), .A(b8_t24), .B(b8_t25), .QH(b8_gq2_s3_QH), .P(b8_l12_w));
    logic [61:0] b8_l12_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l12_a_i (.clk(clk), .din(b7_g0_o[12]), .dout(b8_l12_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_mq27_s3_QH;
    always_ff @(posedge clk) b8_mq27_s3_QH <= b8_mq27_0_QH;
    logic [61:0] b8_l12_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l12_mul (.clk(clk), .A(b8_l12_a), .B(b8_l12_w), .QH(b8_mq27_s3_QH), .P(b8_l12_p));
    logic [61:0] b8_l13_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l13_gen (.clk(clk), .A(b8_t26), .B(b8_t27), .QH(b8_gq2_s3_QH), .P(b8_l13_w));
    logic [61:0] b8_l13_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l13_a_i (.clk(clk), .din(b7_g0_o[13]), .dout(b8_l13_a));
    logic [61:0] b8_l13_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l13_mul (.clk(clk), .A(b8_l13_a), .B(b8_l13_w), .QH(b8_mq27_s3_QH), .P(b8_l13_p));
    logic [61:0] b8_l14_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l14_gen (.clk(clk), .A(b8_t28), .B(b8_t29), .QH(b8_gq2_s3_QH), .P(b8_l14_w));
    logic [61:0] b8_l14_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l14_a_i (.clk(clk), .din(b7_g0_o[14]), .dout(b8_l14_a));
    logic [61:0] b8_l14_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l14_mul (.clk(clk), .A(b8_l14_a), .B(b8_l14_w), .QH(b8_mq27_s3_QH), .P(b8_l14_p));
    logic [61:0] b8_l15_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l15_gen (.clk(clk), .A(b8_t30), .B(b8_t31), .QH(b8_gq2_s3_QH), .P(b8_l15_w));
    logic [61:0] b8_l15_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l15_a_i (.clk(clk), .din(b7_g0_o[15]), .dout(b8_l15_a));
    logic [61:0] b8_l15_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l15_mul (.clk(clk), .A(b8_l15_a), .B(b8_l15_w), .QH(b8_mq27_s3_QH), .P(b8_l15_p));
    logic [61:0] b8_l16_w;
    logic [44:0] b8_gq2_1_QH_c; assign b8_gq2_1_QH_c = b7_tag[48:4];
    logic [44:0] b8_gq2_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(45), .D(1)) b8_gq2_1_QH_i (.clk(clk), .din(b8_gq2_1_QH_c), .dout(b8_gq2_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq2_s4_QH;
    always_ff @(posedge clk) b8_gq2_s4_QH <= b8_gq2_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l16_gen (.clk(clk), .A(b8_t32), .B(b8_t33), .QH(b8_gq2_s4_QH), .P(b8_l16_w));
    logic [61:0] b8_l16_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l16_a_i (.clk(clk), .din(b7_g0_o[16]), .dout(b8_l16_a));
    logic [44:0] b8_mq27_1_QH_c; assign b8_mq27_1_QH_c = b7_tag[48:4];
    logic [44:0] b8_mq27_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(45), .D(26)) b8_mq27_1_QH_i (.clk(clk), .din(b8_mq27_1_QH_c), .dout(b8_mq27_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_mq27_s4_QH;
    always_ff @(posedge clk) b8_mq27_s4_QH <= b8_mq27_1_QH;
    logic [61:0] b8_l16_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l16_mul (.clk(clk), .A(b8_l16_a), .B(b8_l16_w), .QH(b8_mq27_s4_QH), .P(b8_l16_p));
    logic [61:0] b8_l17_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l17_gen (.clk(clk), .A(b8_t34), .B(b8_t35), .QH(b8_gq2_s4_QH), .P(b8_l17_w));
    logic [61:0] b8_l17_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l17_a_i (.clk(clk), .din(b7_g0_o[17]), .dout(b8_l17_a));
    logic [61:0] b8_l17_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l17_mul (.clk(clk), .A(b8_l17_a), .B(b8_l17_w), .QH(b8_mq27_s4_QH), .P(b8_l17_p));
    logic [61:0] b8_l18_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l18_gen (.clk(clk), .A(b8_t36), .B(b8_t37), .QH(b8_gq2_s4_QH), .P(b8_l18_w));
    logic [61:0] b8_l18_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l18_a_i (.clk(clk), .din(b7_g0_o[18]), .dout(b8_l18_a));
    logic [61:0] b8_l18_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l18_mul (.clk(clk), .A(b8_l18_a), .B(b8_l18_w), .QH(b8_mq27_s4_QH), .P(b8_l18_p));
    logic [61:0] b8_l19_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l19_gen (.clk(clk), .A(b8_t38), .B(b8_t39), .QH(b8_gq2_s4_QH), .P(b8_l19_w));
    logic [61:0] b8_l19_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l19_a_i (.clk(clk), .din(b7_g0_o[19]), .dout(b8_l19_a));
    logic [61:0] b8_l19_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l19_mul (.clk(clk), .A(b8_l19_a), .B(b8_l19_w), .QH(b8_mq27_s4_QH), .P(b8_l19_p));
    logic [61:0] b8_l20_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq2_s5_QH;
    always_ff @(posedge clk) b8_gq2_s5_QH <= b8_gq2_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l20_gen (.clk(clk), .A(b8_t40), .B(b8_t41), .QH(b8_gq2_s5_QH), .P(b8_l20_w));
    logic [61:0] b8_l20_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l20_a_i (.clk(clk), .din(b7_g0_o[20]), .dout(b8_l20_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_mq27_s5_QH;
    always_ff @(posedge clk) b8_mq27_s5_QH <= b8_mq27_1_QH;
    logic [61:0] b8_l20_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l20_mul (.clk(clk), .A(b8_l20_a), .B(b8_l20_w), .QH(b8_mq27_s5_QH), .P(b8_l20_p));
    logic [61:0] b8_l21_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l21_gen (.clk(clk), .A(b8_t42), .B(b8_t43), .QH(b8_gq2_s5_QH), .P(b8_l21_w));
    logic [61:0] b8_l21_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l21_a_i (.clk(clk), .din(b7_g0_o[21]), .dout(b8_l21_a));
    logic [61:0] b8_l21_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l21_mul (.clk(clk), .A(b8_l21_a), .B(b8_l21_w), .QH(b8_mq27_s5_QH), .P(b8_l21_p));
    logic [61:0] b8_l22_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l22_gen (.clk(clk), .A(b8_t44), .B(b8_t45), .QH(b8_gq2_s5_QH), .P(b8_l22_w));
    logic [61:0] b8_l22_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l22_a_i (.clk(clk), .din(b7_g0_o[22]), .dout(b8_l22_a));
    logic [61:0] b8_l22_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l22_mul (.clk(clk), .A(b8_l22_a), .B(b8_l22_w), .QH(b8_mq27_s5_QH), .P(b8_l22_p));
    logic [61:0] b8_l23_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l23_gen (.clk(clk), .A(b8_t46), .B(b8_t47), .QH(b8_gq2_s5_QH), .P(b8_l23_w));
    logic [61:0] b8_l23_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l23_a_i (.clk(clk), .din(b7_g0_o[23]), .dout(b8_l23_a));
    logic [61:0] b8_l23_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l23_mul (.clk(clk), .A(b8_l23_a), .B(b8_l23_w), .QH(b8_mq27_s5_QH), .P(b8_l23_p));
    logic [61:0] b8_l24_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq2_s6_QH;
    always_ff @(posedge clk) b8_gq2_s6_QH <= b8_gq2_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l24_gen (.clk(clk), .A(b8_t48), .B(b8_t49), .QH(b8_gq2_s6_QH), .P(b8_l24_w));
    logic [61:0] b8_l24_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l24_a_i (.clk(clk), .din(b7_g0_o[24]), .dout(b8_l24_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_mq27_s6_QH;
    always_ff @(posedge clk) b8_mq27_s6_QH <= b8_mq27_1_QH;
    logic [61:0] b8_l24_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l24_mul (.clk(clk), .A(b8_l24_a), .B(b8_l24_w), .QH(b8_mq27_s6_QH), .P(b8_l24_p));
    logic [61:0] b8_l25_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l25_gen (.clk(clk), .A(b8_t50), .B(b8_t51), .QH(b8_gq2_s6_QH), .P(b8_l25_w));
    logic [61:0] b8_l25_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l25_a_i (.clk(clk), .din(b7_g0_o[25]), .dout(b8_l25_a));
    logic [61:0] b8_l25_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l25_mul (.clk(clk), .A(b8_l25_a), .B(b8_l25_w), .QH(b8_mq27_s6_QH), .P(b8_l25_p));
    logic [61:0] b8_l26_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l26_gen (.clk(clk), .A(b8_t52), .B(b8_t53), .QH(b8_gq2_s6_QH), .P(b8_l26_w));
    logic [61:0] b8_l26_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l26_a_i (.clk(clk), .din(b7_g0_o[26]), .dout(b8_l26_a));
    logic [61:0] b8_l26_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l26_mul (.clk(clk), .A(b8_l26_a), .B(b8_l26_w), .QH(b8_mq27_s6_QH), .P(b8_l26_p));
    logic [61:0] b8_l27_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l27_gen (.clk(clk), .A(b8_t54), .B(b8_t55), .QH(b8_gq2_s6_QH), .P(b8_l27_w));
    logic [61:0] b8_l27_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l27_a_i (.clk(clk), .din(b7_g0_o[27]), .dout(b8_l27_a));
    logic [61:0] b8_l27_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l27_mul (.clk(clk), .A(b8_l27_a), .B(b8_l27_w), .QH(b8_mq27_s6_QH), .P(b8_l27_p));
    logic [61:0] b8_l28_w;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq2_s7_QH;
    always_ff @(posedge clk) b8_gq2_s7_QH <= b8_gq2_1_QH;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l28_gen (.clk(clk), .A(b8_t56), .B(b8_t57), .QH(b8_gq2_s7_QH), .P(b8_l28_w));
    logic [61:0] b8_l28_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l28_a_i (.clk(clk), .din(b7_g0_o[28]), .dout(b8_l28_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_mq27_s7_QH;
    always_ff @(posedge clk) b8_mq27_s7_QH <= b8_mq27_1_QH;
    logic [61:0] b8_l28_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l28_mul (.clk(clk), .A(b8_l28_a), .B(b8_l28_w), .QH(b8_mq27_s7_QH), .P(b8_l28_p));
    logic [61:0] b8_l29_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l29_gen (.clk(clk), .A(b8_t58), .B(b8_t59), .QH(b8_gq2_s7_QH), .P(b8_l29_w));
    logic [61:0] b8_l29_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l29_a_i (.clk(clk), .din(b7_g0_o[29]), .dout(b8_l29_a));
    logic [61:0] b8_l29_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l29_mul (.clk(clk), .A(b8_l29_a), .B(b8_l29_w), .QH(b8_mq27_s7_QH), .P(b8_l29_p));
    logic [61:0] b8_l30_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l30_gen (.clk(clk), .A(b8_t60), .B(b8_t61), .QH(b8_gq2_s7_QH), .P(b8_l30_w));
    logic [61:0] b8_l30_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l30_a_i (.clk(clk), .din(b7_g0_o[30]), .dout(b8_l30_a));
    logic [61:0] b8_l30_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l30_mul (.clk(clk), .A(b8_l30_a), .B(b8_l30_w), .QH(b8_mq27_s7_QH), .P(b8_l30_p));
    logic [61:0] b8_l31_w;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twgen b8_l31_gen (.clk(clk), .A(b8_t62), .B(b8_t63), .QH(b8_gq2_s7_QH), .P(b8_l31_w));
    logic [61:0] b8_l31_a;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(62), .D(27)) b8_l31_a_i (.clk(clk), .din(b7_g0_o[31]), .dout(b8_l31_a));
    logic [61:0] b8_l31_p;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_twmul b8_l31_mul (.clk(clk), .A(b8_l31_a), .B(b8_l31_w), .QH(b8_mq27_s7_QH), .P(b8_l31_p));
    logic [51:0] b8_v_sr;
    always_ff @(posedge clk) b8_v_sr <= rst ? '0 : {b8_v_sr[50:0], b7_g0_v};
    logic b8_v; assign b8_v = b8_v_sr[51];
    logic [110:0] b8_tag;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(111), .D(52)) b8_tag_i (.clk(clk), .din(b7_tag), .dout(b8_tag));
    // block 9: pass 3, 1 x ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p3 (32-point), latency 143
    logic [61:0] b9_c0_y0, b9_c0_y1, b9_c0_y2, b9_c0_y3, b9_c0_y4, b9_c0_y5, b9_c0_y6, b9_c0_y7, b9_c0_y8, b9_c0_y9, b9_c0_y10, b9_c0_y11, b9_c0_y12, b9_c0_y13, b9_c0_y14, b9_c0_y15, b9_c0_y16, b9_c0_y17, b9_c0_y18, b9_c0_y19, b9_c0_y20, b9_c0_y21, b9_c0_y22, b9_c0_y23, b9_c0_y24, b9_c0_y25, b9_c0_y26, b9_c0_y27, b9_c0_y28, b9_c0_y29, b9_c0_y30, b9_c0_y31;
    logic b9_c0_v; logic [2:0] b9_c0_mi; logic b9_c0_di;
    logic b9_c0_lr, b9_c0_lw; (* equivalent_register_removal = "no" *) logic [61:0] b9_c0_ld;
    always_ff @(posedge clk) begin b9_c0_lr <= ld_r; b9_c0_lw <= ld_v && ld_iq >= 11'd1775 && ld_iq < 11'd1822; b9_c0_ld <= ld_d[61:0]; end
    logic [2:0] b9_c0_ls; always_ff @(posedge clk) b9_c0_ls <= ld_sl;
    logic b9_c0_ldr; always_ff @(posedge clk) b9_c0_ldr <= ld_dr;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p3 b9_c0 (.clk(clk), .rst(rst), .in_valid(b8_v), .out_valid(b9_c0_v), .MIDX(b8_tag[3:1]), .midx_out(b9_c0_mi), .mq_QH(b8_tag[48:4]), .mq_QHALF(b8_tag[110:49]), .DIR(b8_tag[0]), .dir_out(b9_c0_di), .tw_rst(b9_c0_lr), .tw_wen(b9_c0_lw), .tw_wdata(b9_c0_ld), .tw_slot(b9_c0_ls), .tw_dir(b9_c0_ldr), .x_in_0(b8_l0_p), .x_in_1(b8_l1_p), .x_in_2(b8_l2_p), .x_in_3(b8_l3_p), .x_in_4(b8_l4_p), .x_in_5(b8_l5_p), .x_in_6(b8_l6_p), .x_in_7(b8_l7_p), .x_in_8(b8_l8_p), .x_in_9(b8_l9_p), .x_in_10(b8_l10_p), .x_in_11(b8_l11_p), .x_in_12(b8_l12_p), .x_in_13(b8_l13_p), .x_in_14(b8_l14_p), .x_in_15(b8_l15_p), .x_in_16(b8_l16_p), .x_in_17(b8_l17_p), .x_in_18(b8_l18_p), .x_in_19(b8_l19_p), .x_in_20(b8_l20_p), .x_in_21(b8_l21_p), .x_in_22(b8_l22_p), .x_in_23(b8_l23_p), .x_in_24(b8_l24_p), .x_in_25(b8_l25_p), .x_in_26(b8_l26_p), .x_in_27(b8_l27_p), .x_in_28(b8_l28_p), .x_in_29(b8_l29_p), .x_in_30(b8_l30_p), .x_in_31(b8_l31_p), .y_out_0(b9_c0_y0), .y_out_1(b9_c0_y1), .y_out_2(b9_c0_y2), .y_out_3(b9_c0_y3), .y_out_4(b9_c0_y4), .y_out_5(b9_c0_y5), .y_out_6(b9_c0_y6), .y_out_7(b9_c0_y7), .y_out_8(b9_c0_y8), .y_out_9(b9_c0_y9), .y_out_10(b9_c0_y10), .y_out_11(b9_c0_y11), .y_out_12(b9_c0_y12), .y_out_13(b9_c0_y13), .y_out_14(b9_c0_y14), .y_out_15(b9_c0_y15), .y_out_16(b9_c0_y16), .y_out_17(b9_c0_y17), .y_out_18(b9_c0_y18), .y_out_19(b9_c0_y19), .y_out_20(b9_c0_y20), .y_out_21(b9_c0_y21), .y_out_22(b9_c0_y22), .y_out_23(b9_c0_y23), .y_out_24(b9_c0_y24), .y_out_25(b9_c0_y25), .y_out_26(b9_c0_y26), .y_out_27(b9_c0_y27), .y_out_28(b9_c0_y28), .y_out_29(b9_c0_y29), .y_out_30(b9_c0_y30), .y_out_31(b9_c0_y31));
    logic [106:0] b9_cq0; assign b9_cq0 = b8_tag[110:4];
    logic [106:0] b9_cq;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_dly_c #(.W(107), .D(143)) b9_cq_i (.clk(clk), .din(b9_cq0), .dout(b9_cq));
    logic [110:0] b9_tag; assign b9_tag = {b9_cq, b9_c0_mi, b9_c0_di};
    assign out_valid = b9_c0_v;
    assign midx_out = b9_tag[3:1];
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
