`timescale 1ns / 1ps
// ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k: multi-step NTT, N=65536, sizes [16, 16, 16, 16], 32 lanes, frame 2048 cycles, latency 3215, 5 moduli (MIDX per polynomial)
module ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k (
    input  logic clk,
    input  logic rst,
    input  logic in_valid,
    input  logic [2:0] MIDX,
    input  logic DIR,
    input  logic [44:0] mq_QH,
    input  logic [61:0] mq_QHALF,
    input  logic ld_rst,
    input  logic ld_wen,
    input  logic [61:0] ld_wdata,
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
    // load port: one word per ld_wen after ld_rst, 303 words: the sub-NTT images, then the tables
    (* max_fanout = 32 *) logic ld_rst_p, ld_wen_p; (* max_fanout = 32 *) logic [61:0] ld_wdata_p;
    always_ff @(posedge clk) begin ld_rst_p <= ld_rst; ld_wen_p <= ld_wen; ld_wdata_p <= ld_wdata; end
    (* max_fanout = 32 *) logic [8:0] ld_i;
    always_ff @(posedge clk) ld_i <= ld_rst_p ? '0 : (ld_wen_p ? ld_i + 1'b1 : ld_i);
    (* max_fanout = 32 *) logic [61:0] ld_d; always_ff @(posedge clk) ld_d <= ld_wdata_p;
    (* max_fanout = 32 *) logic ld_v, ld_r; always_ff @(posedge clk) begin ld_v <= ld_wen_p; ld_r <= ld_rst_p; end
    logic [8:0] ld_iq; always_ff @(posedge clk) ld_iq <= ld_i;
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
    // block 0: pass 0, 2 x ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p0 (16-point), latency 115
    logic [61:0] b0_c0_y0, b0_c0_y1, b0_c0_y2, b0_c0_y3, b0_c0_y4, b0_c0_y5, b0_c0_y6, b0_c0_y7, b0_c0_y8, b0_c0_y9, b0_c0_y10, b0_c0_y11, b0_c0_y12, b0_c0_y13, b0_c0_y14, b0_c0_y15;
    logic b0_c0_v; logic [2:0] b0_c0_mi; logic b0_c0_di;
    logic b0_c0_lr, b0_c0_lw; (* equivalent_register_removal = "no" *) logic [61:0] b0_c0_ld;
    always_ff @(posedge clk) begin b0_c0_lr <= ld_r; b0_c0_lw <= ld_v && ld_iq >= 9'd0 && ld_iq < 9'd15; b0_c0_ld <= ld_d[61:0]; end
    logic [2:0] b0_c0_ls; always_ff @(posedge clk) b0_c0_ls <= ld_sl;
    logic b0_c0_ldr; always_ff @(posedge clk) b0_c0_ldr <= ld_dr;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p0 b0_c0 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c0_v), .MIDX(g0[3:1]), .midx_out(b0_c0_mi), .mq_QH(g0[48:4]), .mq_QHALF(g0[110:49]), .DIR(g0[0]), .dir_out(b0_c0_di), .tw_rst(b0_c0_lr), .tw_wen(b0_c0_lw), .tw_wdata(b0_c0_ld), .tw_slot(b0_c0_ls), .tw_dir(b0_c0_ldr), .x_in_0(d0_0), .x_in_1(d0_2), .x_in_2(d0_4), .x_in_3(d0_6), .x_in_4(d0_8), .x_in_5(d0_10), .x_in_6(d0_12), .x_in_7(d0_14), .x_in_8(d0_16), .x_in_9(d0_18), .x_in_10(d0_20), .x_in_11(d0_22), .x_in_12(d0_24), .x_in_13(d0_26), .x_in_14(d0_28), .x_in_15(d0_30), .y_out_0(b0_c0_y0), .y_out_1(b0_c0_y1), .y_out_2(b0_c0_y2), .y_out_3(b0_c0_y3), .y_out_4(b0_c0_y4), .y_out_5(b0_c0_y5), .y_out_6(b0_c0_y6), .y_out_7(b0_c0_y7), .y_out_8(b0_c0_y8), .y_out_9(b0_c0_y9), .y_out_10(b0_c0_y10), .y_out_11(b0_c0_y11), .y_out_12(b0_c0_y12), .y_out_13(b0_c0_y13), .y_out_14(b0_c0_y14), .y_out_15(b0_c0_y15));
    logic [61:0] b0_c1_y0, b0_c1_y1, b0_c1_y2, b0_c1_y3, b0_c1_y4, b0_c1_y5, b0_c1_y6, b0_c1_y7, b0_c1_y8, b0_c1_y9, b0_c1_y10, b0_c1_y11, b0_c1_y12, b0_c1_y13, b0_c1_y14, b0_c1_y15;
    logic b0_c1_v; logic [2:0] b0_c1_mi; logic b0_c1_di;
    logic b0_c1_lr, b0_c1_lw; (* equivalent_register_removal = "no" *) logic [61:0] b0_c1_ld;
    always_ff @(posedge clk) begin b0_c1_lr <= ld_r; b0_c1_lw <= ld_v && ld_iq >= 9'd0 && ld_iq < 9'd15; b0_c1_ld <= ld_d[61:0]; end
    logic [2:0] b0_c1_ls; always_ff @(posedge clk) b0_c1_ls <= ld_sl;
    logic b0_c1_ldr; always_ff @(posedge clk) b0_c1_ldr <= ld_dr;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p0 b0_c1 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c1_v), .MIDX(g0[3:1]), .midx_out(b0_c1_mi), .mq_QH(g0[48:4]), .mq_QHALF(g0[110:49]), .DIR(g0[0]), .dir_out(b0_c1_di), .tw_rst(b0_c1_lr), .tw_wen(b0_c1_lw), .tw_wdata(b0_c1_ld), .tw_slot(b0_c1_ls), .tw_dir(b0_c1_ldr), .x_in_0(d0_1), .x_in_1(d0_3), .x_in_2(d0_5), .x_in_3(d0_7), .x_in_4(d0_9), .x_in_5(d0_11), .x_in_6(d0_13), .x_in_7(d0_15), .x_in_8(d0_17), .x_in_9(d0_19), .x_in_10(d0_21), .x_in_11(d0_23), .x_in_12(d0_25), .x_in_13(d0_27), .x_in_14(d0_29), .x_in_15(d0_31), .y_out_0(b0_c1_y0), .y_out_1(b0_c1_y1), .y_out_2(b0_c1_y2), .y_out_3(b0_c1_y3), .y_out_4(b0_c1_y4), .y_out_5(b0_c1_y5), .y_out_6(b0_c1_y6), .y_out_7(b0_c1_y7), .y_out_8(b0_c1_y8), .y_out_9(b0_c1_y9), .y_out_10(b0_c1_y10), .y_out_11(b0_c1_y11), .y_out_12(b0_c1_y12), .y_out_13(b0_c1_y13), .y_out_14(b0_c1_y14), .y_out_15(b0_c1_y15));
    logic [106:0] b0_cq0; assign b0_cq0 = g0[110:4];
    logic [106:0] b0_cq;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(107), .D(115)) b0_cq_i (.clk(clk), .din(b0_cq0), .dout(b0_cq));
    logic [110:0] b0_tag; assign b0_tag = {b0_cq, b0_c0_mi, b0_c0_di};
    // block 1: lane-time transpose, lane bits [1, 2, 3] <-> cycle bits [8,11), 4 x S=8, latency 2053
    logic [61:0] b1_g0_i [0:7]; logic [61:0] b1_g0_o [0:7]; logic b1_g0_v;
    assign b1_g0_i[0] = b0_c0_y0;
    assign b1_g0_i[1] = b0_c0_y1;
    assign b1_g0_i[2] = b0_c0_y2;
    assign b1_g0_i[3] = b0_c0_y3;
    assign b1_g0_i[4] = b0_c0_y4;
    assign b1_g0_i[5] = b0_c0_y5;
    assign b1_g0_i[6] = b0_c0_y6;
    assign b1_g0_i[7] = b0_c0_y7;
    lt_bmb_transpose #(.S(8), .LO(8), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h3), .RAM_STYLE("block")) b1_g0 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g0_i), .data_out_valid(b1_g0_v), .data_out(b1_g0_o));
    logic [61:0] b1_g1_i [0:7]; logic [61:0] b1_g1_o [0:7]; logic b1_g1_v;
    assign b1_g1_i[0] = b0_c1_y0;
    assign b1_g1_i[1] = b0_c1_y1;
    assign b1_g1_i[2] = b0_c1_y2;
    assign b1_g1_i[3] = b0_c1_y3;
    assign b1_g1_i[4] = b0_c1_y4;
    assign b1_g1_i[5] = b0_c1_y5;
    assign b1_g1_i[6] = b0_c1_y6;
    assign b1_g1_i[7] = b0_c1_y7;
    lt_bmb_transpose #(.S(8), .LO(8), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h3), .RAM_STYLE("block")) b1_g1 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g1_i), .data_out_valid(b1_g1_v), .data_out(b1_g1_o));
    logic [61:0] b1_g2_i [0:7]; logic [61:0] b1_g2_o [0:7]; logic b1_g2_v;
    assign b1_g2_i[0] = b0_c0_y8;
    assign b1_g2_i[1] = b0_c0_y9;
    assign b1_g2_i[2] = b0_c0_y10;
    assign b1_g2_i[3] = b0_c0_y11;
    assign b1_g2_i[4] = b0_c0_y12;
    assign b1_g2_i[5] = b0_c0_y13;
    assign b1_g2_i[6] = b0_c0_y14;
    assign b1_g2_i[7] = b0_c0_y15;
    lt_bmb_transpose #(.S(8), .LO(8), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h3), .RAM_STYLE("block")) b1_g2 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g2_i), .data_out_valid(b1_g2_v), .data_out(b1_g2_o));
    logic [61:0] b1_g3_i [0:7]; logic [61:0] b1_g3_o [0:7]; logic b1_g3_v;
    assign b1_g3_i[0] = b0_c1_y8;
    assign b1_g3_i[1] = b0_c1_y9;
    assign b1_g3_i[2] = b0_c1_y10;
    assign b1_g3_i[3] = b0_c1_y11;
    assign b1_g3_i[4] = b0_c1_y12;
    assign b1_g3_i[5] = b0_c1_y13;
    assign b1_g3_i[6] = b0_c1_y14;
    assign b1_g3_i[7] = b0_c1_y15;
    lt_bmb_transpose #(.S(8), .LO(8), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h3), .RAM_STYLE("block")) b1_g3 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g3_i), .data_out_valid(b1_g3_v), .data_out(b1_g3_o));
    logic [110:0] b1_tag;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(111), .D(2053)) b1_tag_i (.clk(clk), .din(b0_tag), .dout(b1_tag));
    // block 2: twiddle stage 1, latency 157 (tables 3, generator 25, multiplier 24)
    logic [10:0] b2_cnt;
    always_ff @(posedge clk) b2_cnt <= rst ? '0 : (b1_g0_v ? b2_cnt + 1'b1 : b2_cnt);
    logic [61:0] b2_t0;
    (* shreg_extract = "no" *) logic [61:0] b2_t0_q0;
    logic b2_t0_lwe; logic [5:0] b2_t0_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t0_lwd;
    always_ff @(posedge clk) begin b2_t0_lwe <= ld_v && ld_iq >= 9'd15 && ld_iq < 9'd19; b2_t0_lwa <= {ld_slq[2:0], ld_drq, 2'(ld_iq - 9'd15)}; b2_t0_lwd <= ld_d[61:0]; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_tw1_tab0 b2_t0_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[9], b2_cnt[8]}), .we(b2_t0_lwe), .wa(b2_t0_lwa), .wcol(1'b0), .wd(b2_t0_lwd), .q0(b2_t0_q0));
    always_ff @(posedge clk) begin b2_t0 <= b2_t0_q0; end
    logic [61:0] b2_t1;
    (* shreg_extract = "no" *) logic [61:0] b2_t1_q0;
    logic b2_t1_lwe; logic [4:0] b2_t1_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t1_lwd;
    always_ff @(posedge clk) begin b2_t1_lwe <= ld_v && ld_iq >= 9'd19 && ld_iq < 9'd21; b2_t1_lwa <= {ld_slq[2:0], ld_drq, 1'(ld_iq - 9'd19)}; b2_t1_lwd <= ld_d[61:0]; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_tw1_tab1 b2_t1_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10]}), .we(b2_t1_lwe), .wa(b2_t1_lwa), .wcol(1'b0), .wd(b2_t1_lwd), .q0(b2_t1_q0));
    always_ff @(posedge clk) begin b2_t1 <= b2_t1_q0; end
    logic [61:0] b2_t2;
    (* shreg_extract = "no" *) logic [61:0] b2_t2_q0;
    logic b2_t2_lwe; logic [6:0] b2_t2_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t2_lwd;
    always_ff @(posedge clk) begin b2_t2_lwe <= ld_v && ld_iq >= 9'd21 && ld_iq < 9'd29; b2_t2_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 9'd21)}; b2_t2_lwd <= ld_d[61:0]; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_tw1_tab2 b2_t2_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10], b2_cnt[9], b2_cnt[8]}), .we(b2_t2_lwe), .wa(b2_t2_lwa), .wcol(1'b0), .wd(b2_t2_lwd), .q0(b2_t2_q0));
    always_ff @(posedge clk) begin b2_t2 <= b2_t2_q0; end
    logic [61:0] b2_t3;
    (* shreg_extract = "no" *) logic [61:0] b2_t3_q0;
    logic b2_t3_lwe; logic [5:0] b2_t3_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t3_lwd;
    always_ff @(posedge clk) begin b2_t3_lwe <= ld_v && ld_iq >= 9'd29 && ld_iq < 9'd33; b2_t3_lwa <= {ld_slq[2:0], ld_drq, 2'(ld_iq - 9'd29)}; b2_t3_lwd <= ld_d[61:0]; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_tw1_tab3 b2_t3_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[9], b2_cnt[8]}), .we(b2_t3_lwe), .wa(b2_t3_lwa), .wcol(1'b0), .wd(b2_t3_lwd), .q0(b2_t3_q0));
    always_ff @(posedge clk) begin b2_t3 <= b2_t3_q0; end
    logic [61:0] b2_t4;
    (* shreg_extract = "no" *) logic [61:0] b2_t4_q0;
    logic b2_t4_lwe; logic [6:0] b2_t4_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b2_t4_lwd;
    always_ff @(posedge clk) begin b2_t4_lwe <= ld_v && ld_iq >= 9'd33 && ld_iq < 9'd41; b2_t4_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 9'd33)}; b2_t4_lwd <= ld_d[61:0]; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_tw1_tab4 b2_t4_i (.clk(clk), .addr({b1_tag[3:1], b1_tag[0], b2_cnt[10], b2_cnt[9], b2_cnt[8]}), .we(b2_t4_lwe), .wa(b2_t4_lwa), .wcol(1'b0), .wd(b2_t4_lwd), .q0(b2_t4_q0));
    always_ff @(posedge clk) begin b2_t4 <= b2_t4_q0; end
    logic [61:0] b2_g0_z;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_zg_ia, b2_g0_zg_ib;
    always_ff @(posedge clk) begin b2_g0_zg_ia <= b2_t0; b2_g0_zg_ib <= b2_t1; end
    logic [44:0] b2_gq4_0_QH_c; assign b2_gq4_0_QH_c = b1_tag[48:4];
    logic [44:0] b2_gq4_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(3)) b2_gq4_0_QH_i (.clk(clk), .din(b2_gq4_0_QH_c), .dout(b2_gq4_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_gq4_s0_QH;
    always_ff @(posedge clk) b2_gq4_s0_QH <= b2_gq4_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_zg (.clk(clk), .A(b2_g0_zg_ia), .B(b2_g0_zg_ib), .QH(b2_gq4_s0_QH), .P(b2_g0_z));
    logic [61:0] b2_g0_yd;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_g0_yd_i (.clk(clk), .din(b2_t2), .dout(b2_g0_yd));
    logic [61:0] b2_g0_zp1;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_zp1_m_ia, b2_g0_zp1_m_ib;
    always_ff @(posedge clk) begin b2_g0_zp1_m_ia <= b2_g0_z; b2_g0_zp1_m_ib <= b2_g0_z; end
    logic [44:0] b2_gq30_0_QH_c; assign b2_gq30_0_QH_c = b1_tag[48:4];
    logic [44:0] b2_gq30_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(29)) b2_gq30_0_QH_i (.clk(clk), .din(b2_gq30_0_QH_c), .dout(b2_gq30_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_gq30_s0_QH;
    always_ff @(posedge clk) b2_gq30_s0_QH <= b2_gq30_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_zp1_m (.clk(clk), .A(b2_g0_zp1_m_ia), .B(b2_g0_zp1_m_ib), .QH(b2_gq30_s0_QH), .P(b2_g0_zp1));
    logic [61:0] b2_g0_zp2;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_zp2_m_ia, b2_g0_zp2_m_ib;
    always_ff @(posedge clk) begin b2_g0_zp2_m_ia <= b2_g0_zp1; b2_g0_zp2_m_ib <= b2_g0_zp1; end
    logic [44:0] b2_gq56_0_QH_c; assign b2_gq56_0_QH_c = b1_tag[48:4];
    logic [44:0] b2_gq56_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(55)) b2_gq56_0_QH_i (.clk(clk), .din(b2_gq56_0_QH_c), .dout(b2_gq56_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_gq56_s0_QH;
    always_ff @(posedge clk) b2_gq56_s0_QH <= b2_gq56_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_zp2_m (.clk(clk), .A(b2_g0_zp2_m_ia), .B(b2_g0_zp2_m_ib), .QH(b2_gq56_s0_QH), .P(b2_g0_zp2));
    logic [61:0] b2_g0_zp3;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_zp3_m_ia, b2_g0_zp3_m_ib;
    always_ff @(posedge clk) begin b2_g0_zp3_m_ia <= b2_g0_zp2; b2_g0_zp3_m_ib <= b2_g0_zp2; end
    logic [44:0] b2_gq82_0_QH_c; assign b2_gq82_0_QH_c = b1_tag[48:4];
    logic [44:0] b2_gq82_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(81)) b2_gq82_0_QH_i (.clk(clk), .din(b2_gq82_0_QH_c), .dout(b2_gq82_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_gq82_s0_QH;
    always_ff @(posedge clk) b2_gq82_s0_QH <= b2_gq82_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_zp3_m (.clk(clk), .A(b2_g0_zp3_m_ia), .B(b2_g0_zp3_m_ib), .QH(b2_gq82_s0_QH), .P(b2_g0_zp3));
    logic [61:0] b2_g0_w1;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_w1_m_ia, b2_g0_w1_m_ib;
    always_ff @(posedge clk) begin b2_g0_w1_m_ia <= b2_g0_yd; b2_g0_w1_m_ib <= b2_g0_z; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_w1_m (.clk(clk), .A(b2_g0_w1_m_ia), .B(b2_g0_w1_m_ib), .QH(b2_gq30_s0_QH), .P(b2_g0_w1));
    logic [61:0] b2_g0_w2_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_g0_w2_a_i (.clk(clk), .din(b2_g0_yd), .dout(b2_g0_w2_a));
    logic [61:0] b2_g0_w2;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_w2_m_ia, b2_g0_w2_m_ib;
    always_ff @(posedge clk) begin b2_g0_w2_m_ia <= b2_g0_w2_a; b2_g0_w2_m_ib <= b2_g0_zp1; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_w2_m (.clk(clk), .A(b2_g0_w2_m_ia), .B(b2_g0_w2_m_ib), .QH(b2_gq56_s0_QH), .P(b2_g0_w2));
    logic [61:0] b2_g0_w3;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_w3_m_ia, b2_g0_w3_m_ib;
    always_ff @(posedge clk) begin b2_g0_w3_m_ia <= b2_g0_w1; b2_g0_w3_m_ib <= b2_g0_zp1; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_w3_m (.clk(clk), .A(b2_g0_w3_m_ia), .B(b2_g0_w3_m_ib), .QH(b2_gq56_s0_QH), .P(b2_g0_w3));
    logic [61:0] b2_g0_w4_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b2_g0_w4_a_i (.clk(clk), .din(b2_g0_yd), .dout(b2_g0_w4_a));
    logic [61:0] b2_g0_w4;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_w4_m_ia, b2_g0_w4_m_ib;
    always_ff @(posedge clk) begin b2_g0_w4_m_ia <= b2_g0_w4_a; b2_g0_w4_m_ib <= b2_g0_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_w4_m (.clk(clk), .A(b2_g0_w4_m_ia), .B(b2_g0_w4_m_ib), .QH(b2_gq82_s0_QH), .P(b2_g0_w4));
    logic [61:0] b2_g0_w5_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_g0_w5_a_i (.clk(clk), .din(b2_g0_w1), .dout(b2_g0_w5_a));
    logic [61:0] b2_g0_w5;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_w5_m_ia, b2_g0_w5_m_ib;
    always_ff @(posedge clk) begin b2_g0_w5_m_ia <= b2_g0_w5_a; b2_g0_w5_m_ib <= b2_g0_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_w5_m (.clk(clk), .A(b2_g0_w5_m_ia), .B(b2_g0_w5_m_ib), .QH(b2_gq82_s0_QH), .P(b2_g0_w5));
    logic [61:0] b2_g0_w6;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_w6_m_ia, b2_g0_w6_m_ib;
    always_ff @(posedge clk) begin b2_g0_w6_m_ia <= b2_g0_w2; b2_g0_w6_m_ib <= b2_g0_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_w6_m (.clk(clk), .A(b2_g0_w6_m_ia), .B(b2_g0_w6_m_ib), .QH(b2_gq82_s0_QH), .P(b2_g0_w6));
    logic [61:0] b2_g0_w7;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_w7_m_ia, b2_g0_w7_m_ib;
    always_ff @(posedge clk) begin b2_g0_w7_m_ia <= b2_g0_w3; b2_g0_w7_m_ib <= b2_g0_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_w7_m (.clk(clk), .A(b2_g0_w7_m_ia), .B(b2_g0_w7_m_ib), .QH(b2_gq82_s0_QH), .P(b2_g0_w7));
    logic [61:0] b2_g0_w8_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(78)) b2_g0_w8_a_i (.clk(clk), .din(b2_g0_yd), .dout(b2_g0_w8_a));
    logic [61:0] b2_g0_w8;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_w8_m_ia, b2_g0_w8_m_ib;
    always_ff @(posedge clk) begin b2_g0_w8_m_ia <= b2_g0_w8_a; b2_g0_w8_m_ib <= b2_g0_zp3; end
    logic [44:0] b2_gq108_0_QH_c; assign b2_gq108_0_QH_c = b1_tag[48:4];
    logic [44:0] b2_gq108_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(107)) b2_gq108_0_QH_i (.clk(clk), .din(b2_gq108_0_QH_c), .dout(b2_gq108_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_gq108_s0_QH;
    always_ff @(posedge clk) b2_gq108_s0_QH <= b2_gq108_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_w8_m (.clk(clk), .A(b2_g0_w8_m_ia), .B(b2_g0_w8_m_ib), .QH(b2_gq108_s0_QH), .P(b2_g0_w8));
    logic [61:0] b2_g0_w9_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b2_g0_w9_a_i (.clk(clk), .din(b2_g0_w1), .dout(b2_g0_w9_a));
    logic [61:0] b2_g0_w9;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_w9_m_ia, b2_g0_w9_m_ib;
    always_ff @(posedge clk) begin b2_g0_w9_m_ia <= b2_g0_w9_a; b2_g0_w9_m_ib <= b2_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_w9_m (.clk(clk), .A(b2_g0_w9_m_ia), .B(b2_g0_w9_m_ib), .QH(b2_gq108_s0_QH), .P(b2_g0_w9));
    logic [61:0] b2_g0_w10_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_g0_w10_a_i (.clk(clk), .din(b2_g0_w2), .dout(b2_g0_w10_a));
    logic [61:0] b2_g0_w10;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_w10_m_ia, b2_g0_w10_m_ib;
    always_ff @(posedge clk) begin b2_g0_w10_m_ia <= b2_g0_w10_a; b2_g0_w10_m_ib <= b2_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_w10_m (.clk(clk), .A(b2_g0_w10_m_ia), .B(b2_g0_w10_m_ib), .QH(b2_gq108_s0_QH), .P(b2_g0_w10));
    logic [61:0] b2_g0_w11_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_g0_w11_a_i (.clk(clk), .din(b2_g0_w3), .dout(b2_g0_w11_a));
    logic [61:0] b2_g0_w11;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_w11_m_ia, b2_g0_w11_m_ib;
    always_ff @(posedge clk) begin b2_g0_w11_m_ia <= b2_g0_w11_a; b2_g0_w11_m_ib <= b2_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_w11_m (.clk(clk), .A(b2_g0_w11_m_ia), .B(b2_g0_w11_m_ib), .QH(b2_gq108_s0_QH), .P(b2_g0_w11));
    logic [61:0] b2_g0_w12;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_w12_m_ia, b2_g0_w12_m_ib;
    always_ff @(posedge clk) begin b2_g0_w12_m_ia <= b2_g0_w4; b2_g0_w12_m_ib <= b2_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_w12_m (.clk(clk), .A(b2_g0_w12_m_ia), .B(b2_g0_w12_m_ib), .QH(b2_gq108_s0_QH), .P(b2_g0_w12));
    logic [61:0] b2_g0_w13;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_w13_m_ia, b2_g0_w13_m_ib;
    always_ff @(posedge clk) begin b2_g0_w13_m_ia <= b2_g0_w5; b2_g0_w13_m_ib <= b2_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_w13_m (.clk(clk), .A(b2_g0_w13_m_ia), .B(b2_g0_w13_m_ib), .QH(b2_gq108_s0_QH), .P(b2_g0_w13));
    logic [61:0] b2_g0_w14;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_w14_m_ia, b2_g0_w14_m_ib;
    always_ff @(posedge clk) begin b2_g0_w14_m_ia <= b2_g0_w6; b2_g0_w14_m_ib <= b2_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_w14_m (.clk(clk), .A(b2_g0_w14_m_ia), .B(b2_g0_w14_m_ib), .QH(b2_gq108_s0_QH), .P(b2_g0_w14));
    logic [61:0] b2_g0_w15;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g0_w15_m_ia, b2_g0_w15_m_ib;
    always_ff @(posedge clk) begin b2_g0_w15_m_ia <= b2_g0_w7; b2_g0_w15_m_ib <= b2_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g0_w15_m (.clk(clk), .A(b2_g0_w15_m_ia), .B(b2_g0_w15_m_ib), .QH(b2_gq108_s0_QH), .P(b2_g0_w15));
    logic [61:0] b2_l0_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l0_a_i (.clk(clk), .din(b1_g0_o[0]), .dout(b2_l0_a));
    logic [44:0] b2_mq133_0_QH_c; assign b2_mq133_0_QH_c = b1_tag[48:4];
    logic [44:0] b2_mq133_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(132)) b2_mq133_0_QH_i (.clk(clk), .din(b2_mq133_0_QH_c), .dout(b2_mq133_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_mq133_s0_QH;
    always_ff @(posedge clk) b2_mq133_s0_QH <= b2_mq133_0_QH;
    logic [61:0] b2_l0_p;
    logic [61:0] b2_l0_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(104)) b2_l0_w_i (.clk(clk), .din(b2_g0_yd), .dout(b2_l0_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l0_mul (.clk(clk), .A(b2_l0_a), .B(b2_l0_w), .QH(b2_mq133_s0_QH), .P(b2_l0_p));
    logic [61:0] b2_l2_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l2_a_i (.clk(clk), .din(b1_g0_o[1]), .dout(b2_l2_a));
    logic [61:0] b2_l2_p;
    logic [61:0] b2_l2_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(78)) b2_l2_w_i (.clk(clk), .din(b2_g0_w1), .dout(b2_l2_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l2_mul (.clk(clk), .A(b2_l2_a), .B(b2_l2_w), .QH(b2_mq133_s0_QH), .P(b2_l2_p));
    logic [61:0] b2_l4_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l4_a_i (.clk(clk), .din(b1_g0_o[2]), .dout(b2_l4_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_mq133_s1_QH;
    always_ff @(posedge clk) b2_mq133_s1_QH <= b2_mq133_0_QH;
    logic [61:0] b2_l4_p;
    logic [61:0] b2_l4_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b2_l4_w_i (.clk(clk), .din(b2_g0_w2), .dout(b2_l4_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l4_mul (.clk(clk), .A(b2_l4_a), .B(b2_l4_w), .QH(b2_mq133_s1_QH), .P(b2_l4_p));
    logic [61:0] b2_l6_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l6_a_i (.clk(clk), .din(b1_g0_o[3]), .dout(b2_l6_a));
    logic [61:0] b2_l6_p;
    logic [61:0] b2_l6_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b2_l6_w_i (.clk(clk), .din(b2_g0_w3), .dout(b2_l6_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l6_mul (.clk(clk), .A(b2_l6_a), .B(b2_l6_w), .QH(b2_mq133_s1_QH), .P(b2_l6_p));
    logic [61:0] b2_l8_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l8_a_i (.clk(clk), .din(b1_g0_o[4]), .dout(b2_l8_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_mq133_s2_QH;
    always_ff @(posedge clk) b2_mq133_s2_QH <= b2_mq133_0_QH;
    logic [61:0] b2_l8_p;
    logic [61:0] b2_l8_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_l8_w_i (.clk(clk), .din(b2_g0_w4), .dout(b2_l8_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l8_mul (.clk(clk), .A(b2_l8_a), .B(b2_l8_w), .QH(b2_mq133_s2_QH), .P(b2_l8_p));
    logic [61:0] b2_l10_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l10_a_i (.clk(clk), .din(b1_g0_o[5]), .dout(b2_l10_a));
    logic [61:0] b2_l10_p;
    logic [61:0] b2_l10_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_l10_w_i (.clk(clk), .din(b2_g0_w5), .dout(b2_l10_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l10_mul (.clk(clk), .A(b2_l10_a), .B(b2_l10_w), .QH(b2_mq133_s2_QH), .P(b2_l10_p));
    logic [61:0] b2_l12_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l12_a_i (.clk(clk), .din(b1_g0_o[6]), .dout(b2_l12_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_mq133_s3_QH;
    always_ff @(posedge clk) b2_mq133_s3_QH <= b2_mq133_0_QH;
    logic [61:0] b2_l12_p;
    logic [61:0] b2_l12_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_l12_w_i (.clk(clk), .din(b2_g0_w6), .dout(b2_l12_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l12_mul (.clk(clk), .A(b2_l12_a), .B(b2_l12_w), .QH(b2_mq133_s3_QH), .P(b2_l12_p));
    logic [61:0] b2_l14_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l14_a_i (.clk(clk), .din(b1_g0_o[7]), .dout(b2_l14_a));
    logic [61:0] b2_l14_p;
    logic [61:0] b2_l14_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_l14_w_i (.clk(clk), .din(b2_g0_w7), .dout(b2_l14_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l14_mul (.clk(clk), .A(b2_l14_a), .B(b2_l14_w), .QH(b2_mq133_s3_QH), .P(b2_l14_p));
    logic [61:0] b2_l1_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l1_a_i (.clk(clk), .din(b1_g1_o[0]), .dout(b2_l1_a));
    logic [61:0] b2_l1_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l1_mul (.clk(clk), .A(b2_l1_a), .B(b2_g0_w8), .QH(b2_mq133_s0_QH), .P(b2_l1_p));
    logic [61:0] b2_l3_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l3_a_i (.clk(clk), .din(b1_g1_o[1]), .dout(b2_l3_a));
    logic [61:0] b2_l3_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l3_mul (.clk(clk), .A(b2_l3_a), .B(b2_g0_w9), .QH(b2_mq133_s0_QH), .P(b2_l3_p));
    logic [61:0] b2_l5_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l5_a_i (.clk(clk), .din(b1_g1_o[2]), .dout(b2_l5_a));
    logic [61:0] b2_l5_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l5_mul (.clk(clk), .A(b2_l5_a), .B(b2_g0_w10), .QH(b2_mq133_s1_QH), .P(b2_l5_p));
    logic [61:0] b2_l7_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l7_a_i (.clk(clk), .din(b1_g1_o[3]), .dout(b2_l7_a));
    logic [61:0] b2_l7_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l7_mul (.clk(clk), .A(b2_l7_a), .B(b2_g0_w11), .QH(b2_mq133_s1_QH), .P(b2_l7_p));
    logic [61:0] b2_l9_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l9_a_i (.clk(clk), .din(b1_g1_o[4]), .dout(b2_l9_a));
    logic [61:0] b2_l9_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l9_mul (.clk(clk), .A(b2_l9_a), .B(b2_g0_w12), .QH(b2_mq133_s2_QH), .P(b2_l9_p));
    logic [61:0] b2_l11_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l11_a_i (.clk(clk), .din(b1_g1_o[5]), .dout(b2_l11_a));
    logic [61:0] b2_l11_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l11_mul (.clk(clk), .A(b2_l11_a), .B(b2_g0_w13), .QH(b2_mq133_s2_QH), .P(b2_l11_p));
    logic [61:0] b2_l13_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l13_a_i (.clk(clk), .din(b1_g1_o[6]), .dout(b2_l13_a));
    logic [61:0] b2_l13_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l13_mul (.clk(clk), .A(b2_l13_a), .B(b2_g0_w14), .QH(b2_mq133_s3_QH), .P(b2_l13_p));
    logic [61:0] b2_l15_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l15_a_i (.clk(clk), .din(b1_g1_o[7]), .dout(b2_l15_a));
    logic [61:0] b2_l15_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l15_mul (.clk(clk), .A(b2_l15_a), .B(b2_g0_w15), .QH(b2_mq133_s3_QH), .P(b2_l15_p));
    logic [61:0] b2_g1_z;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_zg_ia, b2_g1_zg_ib;
    always_ff @(posedge clk) begin b2_g1_zg_ia <= b2_t3; b2_g1_zg_ib <= b2_t1; end
    logic [44:0] b2_gq4_1_QH_c; assign b2_gq4_1_QH_c = b1_tag[48:4];
    logic [44:0] b2_gq4_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(3)) b2_gq4_1_QH_i (.clk(clk), .din(b2_gq4_1_QH_c), .dout(b2_gq4_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_gq4_s4_QH;
    always_ff @(posedge clk) b2_gq4_s4_QH <= b2_gq4_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_zg (.clk(clk), .A(b2_g1_zg_ia), .B(b2_g1_zg_ib), .QH(b2_gq4_s4_QH), .P(b2_g1_z));
    logic [61:0] b2_g1_yd;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_g1_yd_i (.clk(clk), .din(b2_t4), .dout(b2_g1_yd));
    logic [61:0] b2_g1_zp1;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_zp1_m_ia, b2_g1_zp1_m_ib;
    always_ff @(posedge clk) begin b2_g1_zp1_m_ia <= b2_g1_z; b2_g1_zp1_m_ib <= b2_g1_z; end
    logic [44:0] b2_gq30_1_QH_c; assign b2_gq30_1_QH_c = b1_tag[48:4];
    logic [44:0] b2_gq30_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(29)) b2_gq30_1_QH_i (.clk(clk), .din(b2_gq30_1_QH_c), .dout(b2_gq30_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_gq30_s4_QH;
    always_ff @(posedge clk) b2_gq30_s4_QH <= b2_gq30_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_zp1_m (.clk(clk), .A(b2_g1_zp1_m_ia), .B(b2_g1_zp1_m_ib), .QH(b2_gq30_s4_QH), .P(b2_g1_zp1));
    logic [61:0] b2_g1_zp2;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_zp2_m_ia, b2_g1_zp2_m_ib;
    always_ff @(posedge clk) begin b2_g1_zp2_m_ia <= b2_g1_zp1; b2_g1_zp2_m_ib <= b2_g1_zp1; end
    logic [44:0] b2_gq56_1_QH_c; assign b2_gq56_1_QH_c = b1_tag[48:4];
    logic [44:0] b2_gq56_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(55)) b2_gq56_1_QH_i (.clk(clk), .din(b2_gq56_1_QH_c), .dout(b2_gq56_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_gq56_s4_QH;
    always_ff @(posedge clk) b2_gq56_s4_QH <= b2_gq56_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_zp2_m (.clk(clk), .A(b2_g1_zp2_m_ia), .B(b2_g1_zp2_m_ib), .QH(b2_gq56_s4_QH), .P(b2_g1_zp2));
    logic [61:0] b2_g1_zp3;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_zp3_m_ia, b2_g1_zp3_m_ib;
    always_ff @(posedge clk) begin b2_g1_zp3_m_ia <= b2_g1_zp2; b2_g1_zp3_m_ib <= b2_g1_zp2; end
    logic [44:0] b2_gq82_1_QH_c; assign b2_gq82_1_QH_c = b1_tag[48:4];
    logic [44:0] b2_gq82_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(81)) b2_gq82_1_QH_i (.clk(clk), .din(b2_gq82_1_QH_c), .dout(b2_gq82_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_gq82_s4_QH;
    always_ff @(posedge clk) b2_gq82_s4_QH <= b2_gq82_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_zp3_m (.clk(clk), .A(b2_g1_zp3_m_ia), .B(b2_g1_zp3_m_ib), .QH(b2_gq82_s4_QH), .P(b2_g1_zp3));
    logic [61:0] b2_g1_w1;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_w1_m_ia, b2_g1_w1_m_ib;
    always_ff @(posedge clk) begin b2_g1_w1_m_ia <= b2_g1_yd; b2_g1_w1_m_ib <= b2_g1_z; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_w1_m (.clk(clk), .A(b2_g1_w1_m_ia), .B(b2_g1_w1_m_ib), .QH(b2_gq30_s4_QH), .P(b2_g1_w1));
    logic [61:0] b2_g1_w2_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_g1_w2_a_i (.clk(clk), .din(b2_g1_yd), .dout(b2_g1_w2_a));
    logic [61:0] b2_g1_w2;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_w2_m_ia, b2_g1_w2_m_ib;
    always_ff @(posedge clk) begin b2_g1_w2_m_ia <= b2_g1_w2_a; b2_g1_w2_m_ib <= b2_g1_zp1; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_w2_m (.clk(clk), .A(b2_g1_w2_m_ia), .B(b2_g1_w2_m_ib), .QH(b2_gq56_s4_QH), .P(b2_g1_w2));
    logic [61:0] b2_g1_w3;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_w3_m_ia, b2_g1_w3_m_ib;
    always_ff @(posedge clk) begin b2_g1_w3_m_ia <= b2_g1_w1; b2_g1_w3_m_ib <= b2_g1_zp1; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_w3_m (.clk(clk), .A(b2_g1_w3_m_ia), .B(b2_g1_w3_m_ib), .QH(b2_gq56_s4_QH), .P(b2_g1_w3));
    logic [61:0] b2_g1_w4_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b2_g1_w4_a_i (.clk(clk), .din(b2_g1_yd), .dout(b2_g1_w4_a));
    logic [61:0] b2_g1_w4;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_w4_m_ia, b2_g1_w4_m_ib;
    always_ff @(posedge clk) begin b2_g1_w4_m_ia <= b2_g1_w4_a; b2_g1_w4_m_ib <= b2_g1_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_w4_m (.clk(clk), .A(b2_g1_w4_m_ia), .B(b2_g1_w4_m_ib), .QH(b2_gq82_s4_QH), .P(b2_g1_w4));
    logic [61:0] b2_g1_w5_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_g1_w5_a_i (.clk(clk), .din(b2_g1_w1), .dout(b2_g1_w5_a));
    logic [61:0] b2_g1_w5;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_w5_m_ia, b2_g1_w5_m_ib;
    always_ff @(posedge clk) begin b2_g1_w5_m_ia <= b2_g1_w5_a; b2_g1_w5_m_ib <= b2_g1_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_w5_m (.clk(clk), .A(b2_g1_w5_m_ia), .B(b2_g1_w5_m_ib), .QH(b2_gq82_s4_QH), .P(b2_g1_w5));
    logic [61:0] b2_g1_w6;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_w6_m_ia, b2_g1_w6_m_ib;
    always_ff @(posedge clk) begin b2_g1_w6_m_ia <= b2_g1_w2; b2_g1_w6_m_ib <= b2_g1_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_w6_m (.clk(clk), .A(b2_g1_w6_m_ia), .B(b2_g1_w6_m_ib), .QH(b2_gq82_s4_QH), .P(b2_g1_w6));
    logic [61:0] b2_g1_w7;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_w7_m_ia, b2_g1_w7_m_ib;
    always_ff @(posedge clk) begin b2_g1_w7_m_ia <= b2_g1_w3; b2_g1_w7_m_ib <= b2_g1_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_w7_m (.clk(clk), .A(b2_g1_w7_m_ia), .B(b2_g1_w7_m_ib), .QH(b2_gq82_s4_QH), .P(b2_g1_w7));
    logic [61:0] b2_g1_w8_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(78)) b2_g1_w8_a_i (.clk(clk), .din(b2_g1_yd), .dout(b2_g1_w8_a));
    logic [61:0] b2_g1_w8;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_w8_m_ia, b2_g1_w8_m_ib;
    always_ff @(posedge clk) begin b2_g1_w8_m_ia <= b2_g1_w8_a; b2_g1_w8_m_ib <= b2_g1_zp3; end
    logic [44:0] b2_gq108_1_QH_c; assign b2_gq108_1_QH_c = b1_tag[48:4];
    logic [44:0] b2_gq108_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(107)) b2_gq108_1_QH_i (.clk(clk), .din(b2_gq108_1_QH_c), .dout(b2_gq108_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_gq108_s4_QH;
    always_ff @(posedge clk) b2_gq108_s4_QH <= b2_gq108_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_w8_m (.clk(clk), .A(b2_g1_w8_m_ia), .B(b2_g1_w8_m_ib), .QH(b2_gq108_s4_QH), .P(b2_g1_w8));
    logic [61:0] b2_g1_w9_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b2_g1_w9_a_i (.clk(clk), .din(b2_g1_w1), .dout(b2_g1_w9_a));
    logic [61:0] b2_g1_w9;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_w9_m_ia, b2_g1_w9_m_ib;
    always_ff @(posedge clk) begin b2_g1_w9_m_ia <= b2_g1_w9_a; b2_g1_w9_m_ib <= b2_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_w9_m (.clk(clk), .A(b2_g1_w9_m_ia), .B(b2_g1_w9_m_ib), .QH(b2_gq108_s4_QH), .P(b2_g1_w9));
    logic [61:0] b2_g1_w10_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_g1_w10_a_i (.clk(clk), .din(b2_g1_w2), .dout(b2_g1_w10_a));
    logic [61:0] b2_g1_w10;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_w10_m_ia, b2_g1_w10_m_ib;
    always_ff @(posedge clk) begin b2_g1_w10_m_ia <= b2_g1_w10_a; b2_g1_w10_m_ib <= b2_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_w10_m (.clk(clk), .A(b2_g1_w10_m_ia), .B(b2_g1_w10_m_ib), .QH(b2_gq108_s4_QH), .P(b2_g1_w10));
    logic [61:0] b2_g1_w11_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_g1_w11_a_i (.clk(clk), .din(b2_g1_w3), .dout(b2_g1_w11_a));
    logic [61:0] b2_g1_w11;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_w11_m_ia, b2_g1_w11_m_ib;
    always_ff @(posedge clk) begin b2_g1_w11_m_ia <= b2_g1_w11_a; b2_g1_w11_m_ib <= b2_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_w11_m (.clk(clk), .A(b2_g1_w11_m_ia), .B(b2_g1_w11_m_ib), .QH(b2_gq108_s4_QH), .P(b2_g1_w11));
    logic [61:0] b2_g1_w12;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_w12_m_ia, b2_g1_w12_m_ib;
    always_ff @(posedge clk) begin b2_g1_w12_m_ia <= b2_g1_w4; b2_g1_w12_m_ib <= b2_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_w12_m (.clk(clk), .A(b2_g1_w12_m_ia), .B(b2_g1_w12_m_ib), .QH(b2_gq108_s4_QH), .P(b2_g1_w12));
    logic [61:0] b2_g1_w13;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_w13_m_ia, b2_g1_w13_m_ib;
    always_ff @(posedge clk) begin b2_g1_w13_m_ia <= b2_g1_w5; b2_g1_w13_m_ib <= b2_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_w13_m (.clk(clk), .A(b2_g1_w13_m_ia), .B(b2_g1_w13_m_ib), .QH(b2_gq108_s4_QH), .P(b2_g1_w13));
    logic [61:0] b2_g1_w14;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_w14_m_ia, b2_g1_w14_m_ib;
    always_ff @(posedge clk) begin b2_g1_w14_m_ia <= b2_g1_w6; b2_g1_w14_m_ib <= b2_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_w14_m (.clk(clk), .A(b2_g1_w14_m_ia), .B(b2_g1_w14_m_ib), .QH(b2_gq108_s4_QH), .P(b2_g1_w14));
    logic [61:0] b2_g1_w15;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b2_g1_w15_m_ia, b2_g1_w15_m_ib;
    always_ff @(posedge clk) begin b2_g1_w15_m_ia <= b2_g1_w7; b2_g1_w15_m_ib <= b2_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b2_g1_w15_m (.clk(clk), .A(b2_g1_w15_m_ia), .B(b2_g1_w15_m_ib), .QH(b2_gq108_s4_QH), .P(b2_g1_w15));
    logic [61:0] b2_l16_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l16_a_i (.clk(clk), .din(b1_g2_o[0]), .dout(b2_l16_a));
    logic [44:0] b2_mq133_1_QH_c; assign b2_mq133_1_QH_c = b1_tag[48:4];
    logic [44:0] b2_mq133_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(132)) b2_mq133_1_QH_i (.clk(clk), .din(b2_mq133_1_QH_c), .dout(b2_mq133_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_mq133_s4_QH;
    always_ff @(posedge clk) b2_mq133_s4_QH <= b2_mq133_1_QH;
    logic [61:0] b2_l16_p;
    logic [61:0] b2_l16_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(104)) b2_l16_w_i (.clk(clk), .din(b2_g1_yd), .dout(b2_l16_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l16_mul (.clk(clk), .A(b2_l16_a), .B(b2_l16_w), .QH(b2_mq133_s4_QH), .P(b2_l16_p));
    logic [61:0] b2_l18_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l18_a_i (.clk(clk), .din(b1_g2_o[1]), .dout(b2_l18_a));
    logic [61:0] b2_l18_p;
    logic [61:0] b2_l18_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(78)) b2_l18_w_i (.clk(clk), .din(b2_g1_w1), .dout(b2_l18_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l18_mul (.clk(clk), .A(b2_l18_a), .B(b2_l18_w), .QH(b2_mq133_s4_QH), .P(b2_l18_p));
    logic [61:0] b2_l20_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l20_a_i (.clk(clk), .din(b1_g2_o[2]), .dout(b2_l20_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_mq133_s5_QH;
    always_ff @(posedge clk) b2_mq133_s5_QH <= b2_mq133_1_QH;
    logic [61:0] b2_l20_p;
    logic [61:0] b2_l20_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b2_l20_w_i (.clk(clk), .din(b2_g1_w2), .dout(b2_l20_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l20_mul (.clk(clk), .A(b2_l20_a), .B(b2_l20_w), .QH(b2_mq133_s5_QH), .P(b2_l20_p));
    logic [61:0] b2_l22_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l22_a_i (.clk(clk), .din(b1_g2_o[3]), .dout(b2_l22_a));
    logic [61:0] b2_l22_p;
    logic [61:0] b2_l22_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b2_l22_w_i (.clk(clk), .din(b2_g1_w3), .dout(b2_l22_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l22_mul (.clk(clk), .A(b2_l22_a), .B(b2_l22_w), .QH(b2_mq133_s5_QH), .P(b2_l22_p));
    logic [61:0] b2_l24_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l24_a_i (.clk(clk), .din(b1_g2_o[4]), .dout(b2_l24_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_mq133_s6_QH;
    always_ff @(posedge clk) b2_mq133_s6_QH <= b2_mq133_1_QH;
    logic [61:0] b2_l24_p;
    logic [61:0] b2_l24_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_l24_w_i (.clk(clk), .din(b2_g1_w4), .dout(b2_l24_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l24_mul (.clk(clk), .A(b2_l24_a), .B(b2_l24_w), .QH(b2_mq133_s6_QH), .P(b2_l24_p));
    logic [61:0] b2_l26_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l26_a_i (.clk(clk), .din(b1_g2_o[5]), .dout(b2_l26_a));
    logic [61:0] b2_l26_p;
    logic [61:0] b2_l26_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_l26_w_i (.clk(clk), .din(b2_g1_w5), .dout(b2_l26_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l26_mul (.clk(clk), .A(b2_l26_a), .B(b2_l26_w), .QH(b2_mq133_s6_QH), .P(b2_l26_p));
    logic [61:0] b2_l28_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l28_a_i (.clk(clk), .din(b1_g2_o[6]), .dout(b2_l28_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b2_mq133_s7_QH;
    always_ff @(posedge clk) b2_mq133_s7_QH <= b2_mq133_1_QH;
    logic [61:0] b2_l28_p;
    logic [61:0] b2_l28_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_l28_w_i (.clk(clk), .din(b2_g1_w6), .dout(b2_l28_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l28_mul (.clk(clk), .A(b2_l28_a), .B(b2_l28_w), .QH(b2_mq133_s7_QH), .P(b2_l28_p));
    logic [61:0] b2_l30_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l30_a_i (.clk(clk), .din(b1_g2_o[7]), .dout(b2_l30_a));
    logic [61:0] b2_l30_p;
    logic [61:0] b2_l30_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b2_l30_w_i (.clk(clk), .din(b2_g1_w7), .dout(b2_l30_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l30_mul (.clk(clk), .A(b2_l30_a), .B(b2_l30_w), .QH(b2_mq133_s7_QH), .P(b2_l30_p));
    logic [61:0] b2_l17_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l17_a_i (.clk(clk), .din(b1_g3_o[0]), .dout(b2_l17_a));
    logic [61:0] b2_l17_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l17_mul (.clk(clk), .A(b2_l17_a), .B(b2_g1_w8), .QH(b2_mq133_s4_QH), .P(b2_l17_p));
    logic [61:0] b2_l19_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l19_a_i (.clk(clk), .din(b1_g3_o[1]), .dout(b2_l19_a));
    logic [61:0] b2_l19_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l19_mul (.clk(clk), .A(b2_l19_a), .B(b2_g1_w9), .QH(b2_mq133_s4_QH), .P(b2_l19_p));
    logic [61:0] b2_l21_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l21_a_i (.clk(clk), .din(b1_g3_o[2]), .dout(b2_l21_a));
    logic [61:0] b2_l21_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l21_mul (.clk(clk), .A(b2_l21_a), .B(b2_g1_w10), .QH(b2_mq133_s5_QH), .P(b2_l21_p));
    logic [61:0] b2_l23_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l23_a_i (.clk(clk), .din(b1_g3_o[3]), .dout(b2_l23_a));
    logic [61:0] b2_l23_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l23_mul (.clk(clk), .A(b2_l23_a), .B(b2_g1_w11), .QH(b2_mq133_s5_QH), .P(b2_l23_p));
    logic [61:0] b2_l25_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l25_a_i (.clk(clk), .din(b1_g3_o[4]), .dout(b2_l25_a));
    logic [61:0] b2_l25_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l25_mul (.clk(clk), .A(b2_l25_a), .B(b2_g1_w12), .QH(b2_mq133_s6_QH), .P(b2_l25_p));
    logic [61:0] b2_l27_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l27_a_i (.clk(clk), .din(b1_g3_o[5]), .dout(b2_l27_a));
    logic [61:0] b2_l27_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l27_mul (.clk(clk), .A(b2_l27_a), .B(b2_g1_w13), .QH(b2_mq133_s6_QH), .P(b2_l27_p));
    logic [61:0] b2_l29_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l29_a_i (.clk(clk), .din(b1_g3_o[6]), .dout(b2_l29_a));
    logic [61:0] b2_l29_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l29_mul (.clk(clk), .A(b2_l29_a), .B(b2_g1_w14), .QH(b2_mq133_s7_QH), .P(b2_l29_p));
    logic [61:0] b2_l31_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b2_l31_a_i (.clk(clk), .din(b1_g3_o[7]), .dout(b2_l31_a));
    logic [61:0] b2_l31_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b2_l31_mul (.clk(clk), .A(b2_l31_a), .B(b2_g1_w15), .QH(b2_mq133_s7_QH), .P(b2_l31_p));
    logic [156:0] b2_v_sr;
    always_ff @(posedge clk) b2_v_sr <= rst ? '0 : {b2_v_sr[155:0], b1_g0_v};
    logic b2_v; assign b2_v = b2_v_sr[156];
    logic [110:0] b2_tag;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(111), .D(157)) b2_tag_i (.clk(clk), .din(b1_tag), .dout(b2_tag));
    // block 3: pass 1, 2 x ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p1 (16-point), latency 90
    logic [61:0] b3_c0_y0, b3_c0_y1, b3_c0_y2, b3_c0_y3, b3_c0_y4, b3_c0_y5, b3_c0_y6, b3_c0_y7, b3_c0_y8, b3_c0_y9, b3_c0_y10, b3_c0_y11, b3_c0_y12, b3_c0_y13, b3_c0_y14, b3_c0_y15;
    logic b3_c0_v; logic [2:0] b3_c0_mi; logic b3_c0_di;
    logic b3_c0_lr, b3_c0_lw; (* equivalent_register_removal = "no" *) logic [61:0] b3_c0_ld;
    always_ff @(posedge clk) begin b3_c0_lr <= ld_r; b3_c0_lw <= ld_v && ld_iq >= 9'd41 && ld_iq < 9'd48; b3_c0_ld <= ld_d[61:0]; end
    logic [2:0] b3_c0_ls; always_ff @(posedge clk) b3_c0_ls <= ld_sl;
    logic b3_c0_ldr; always_ff @(posedge clk) b3_c0_ldr <= ld_dr;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p1 b3_c0 (.clk(clk), .rst(rst), .in_valid(b2_v), .out_valid(b3_c0_v), .MIDX(b2_tag[3:1]), .midx_out(b3_c0_mi), .mq_QH(b2_tag[48:4]), .mq_QHALF(b2_tag[110:49]), .DIR(b2_tag[0]), .dir_out(b3_c0_di), .tw_rst(b3_c0_lr), .tw_wen(b3_c0_lw), .tw_wdata(b3_c0_ld), .tw_slot(b3_c0_ls), .tw_dir(b3_c0_ldr), .x_in_0(b2_l0_p), .x_in_1(b2_l2_p), .x_in_2(b2_l4_p), .x_in_3(b2_l6_p), .x_in_4(b2_l8_p), .x_in_5(b2_l10_p), .x_in_6(b2_l12_p), .x_in_7(b2_l14_p), .x_in_8(b2_l1_p), .x_in_9(b2_l3_p), .x_in_10(b2_l5_p), .x_in_11(b2_l7_p), .x_in_12(b2_l9_p), .x_in_13(b2_l11_p), .x_in_14(b2_l13_p), .x_in_15(b2_l15_p), .y_out_0(b3_c0_y0), .y_out_1(b3_c0_y1), .y_out_2(b3_c0_y2), .y_out_3(b3_c0_y3), .y_out_4(b3_c0_y4), .y_out_5(b3_c0_y5), .y_out_6(b3_c0_y6), .y_out_7(b3_c0_y7), .y_out_8(b3_c0_y8), .y_out_9(b3_c0_y9), .y_out_10(b3_c0_y10), .y_out_11(b3_c0_y11), .y_out_12(b3_c0_y12), .y_out_13(b3_c0_y13), .y_out_14(b3_c0_y14), .y_out_15(b3_c0_y15));
    logic [61:0] b3_c1_y0, b3_c1_y1, b3_c1_y2, b3_c1_y3, b3_c1_y4, b3_c1_y5, b3_c1_y6, b3_c1_y7, b3_c1_y8, b3_c1_y9, b3_c1_y10, b3_c1_y11, b3_c1_y12, b3_c1_y13, b3_c1_y14, b3_c1_y15;
    logic b3_c1_v; logic [2:0] b3_c1_mi; logic b3_c1_di;
    logic b3_c1_lr, b3_c1_lw; (* equivalent_register_removal = "no" *) logic [61:0] b3_c1_ld;
    always_ff @(posedge clk) begin b3_c1_lr <= ld_r; b3_c1_lw <= ld_v && ld_iq >= 9'd41 && ld_iq < 9'd48; b3_c1_ld <= ld_d[61:0]; end
    logic [2:0] b3_c1_ls; always_ff @(posedge clk) b3_c1_ls <= ld_sl;
    logic b3_c1_ldr; always_ff @(posedge clk) b3_c1_ldr <= ld_dr;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p1 b3_c1 (.clk(clk), .rst(rst), .in_valid(b2_v), .out_valid(b3_c1_v), .MIDX(b2_tag[3:1]), .midx_out(b3_c1_mi), .mq_QH(b2_tag[48:4]), .mq_QHALF(b2_tag[110:49]), .DIR(b2_tag[0]), .dir_out(b3_c1_di), .tw_rst(b3_c1_lr), .tw_wen(b3_c1_lw), .tw_wdata(b3_c1_ld), .tw_slot(b3_c1_ls), .tw_dir(b3_c1_ldr), .x_in_0(b2_l16_p), .x_in_1(b2_l18_p), .x_in_2(b2_l20_p), .x_in_3(b2_l22_p), .x_in_4(b2_l24_p), .x_in_5(b2_l26_p), .x_in_6(b2_l28_p), .x_in_7(b2_l30_p), .x_in_8(b2_l17_p), .x_in_9(b2_l19_p), .x_in_10(b2_l21_p), .x_in_11(b2_l23_p), .x_in_12(b2_l25_p), .x_in_13(b2_l27_p), .x_in_14(b2_l29_p), .x_in_15(b2_l31_p), .y_out_0(b3_c1_y0), .y_out_1(b3_c1_y1), .y_out_2(b3_c1_y2), .y_out_3(b3_c1_y3), .y_out_4(b3_c1_y4), .y_out_5(b3_c1_y5), .y_out_6(b3_c1_y6), .y_out_7(b3_c1_y7), .y_out_8(b3_c1_y8), .y_out_9(b3_c1_y9), .y_out_10(b3_c1_y10), .y_out_11(b3_c1_y11), .y_out_12(b3_c1_y12), .y_out_13(b3_c1_y13), .y_out_14(b3_c1_y14), .y_out_15(b3_c1_y15));
    logic [106:0] b3_cq0; assign b3_cq0 = b2_tag[110:4];
    logic [106:0] b3_cq;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(107), .D(90)) b3_cq_i (.clk(clk), .din(b3_cq0), .dout(b3_cq));
    logic [110:0] b3_tag; assign b3_tag = {b3_cq, b3_c0_mi, b3_c0_di};
    // block 4: lane-time transpose, lane bits [0, 1, 2, 3] <-> cycle bits [4,8), 2 x S=16, latency 261
    logic [61:0] b4_g0_i [0:15]; logic [61:0] b4_g0_o [0:15]; logic b4_g0_v;
    assign b4_g0_i[0] = b3_c0_y0;
    assign b4_g0_i[1] = b3_c0_y8;
    assign b4_g0_i[2] = b3_c0_y1;
    assign b4_g0_i[3] = b3_c0_y9;
    assign b4_g0_i[4] = b3_c0_y2;
    assign b4_g0_i[5] = b3_c0_y10;
    assign b4_g0_i[6] = b3_c0_y3;
    assign b4_g0_i[7] = b3_c0_y11;
    assign b4_g0_i[8] = b3_c0_y4;
    assign b4_g0_i[9] = b3_c0_y12;
    assign b4_g0_i[10] = b3_c0_y5;
    assign b4_g0_i[11] = b3_c0_y13;
    assign b4_g0_i[12] = b3_c0_y6;
    assign b4_g0_i[13] = b3_c0_y14;
    assign b4_g0_i[14] = b3_c0_y7;
    assign b4_g0_i[15] = b3_c0_y15;
    lt_bmb_transpose #(.S(16), .LO(4), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h3), .RAM_STYLE("block")) b4_g0 (.clk(clk), .rst(rst), .data_valid(b3_c0_v), .data_in(b4_g0_i), .data_out_valid(b4_g0_v), .data_out(b4_g0_o));
    logic [61:0] b4_g1_i [0:15]; logic [61:0] b4_g1_o [0:15]; logic b4_g1_v;
    assign b4_g1_i[0] = b3_c1_y0;
    assign b4_g1_i[1] = b3_c1_y8;
    assign b4_g1_i[2] = b3_c1_y1;
    assign b4_g1_i[3] = b3_c1_y9;
    assign b4_g1_i[4] = b3_c1_y2;
    assign b4_g1_i[5] = b3_c1_y10;
    assign b4_g1_i[6] = b3_c1_y3;
    assign b4_g1_i[7] = b3_c1_y11;
    assign b4_g1_i[8] = b3_c1_y4;
    assign b4_g1_i[9] = b3_c1_y12;
    assign b4_g1_i[10] = b3_c1_y5;
    assign b4_g1_i[11] = b3_c1_y13;
    assign b4_g1_i[12] = b3_c1_y6;
    assign b4_g1_i[13] = b3_c1_y14;
    assign b4_g1_i[14] = b3_c1_y7;
    assign b4_g1_i[15] = b3_c1_y15;
    lt_bmb_transpose #(.S(16), .LO(4), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h3), .RAM_STYLE("block")) b4_g1 (.clk(clk), .rst(rst), .data_valid(b3_c0_v), .data_in(b4_g1_i), .data_out_valid(b4_g1_v), .data_out(b4_g1_o));
    logic [110:0] b4_tag;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(111), .D(261)) b4_tag_i (.clk(clk), .din(b3_tag), .dout(b4_tag));
    // block 5: twiddle stage 2, latency 157 (tables 3, generator 25, multiplier 24)
    logic [10:0] b5_cnt;
    always_ff @(posedge clk) b5_cnt <= rst ? '0 : (b4_g0_v ? b5_cnt + 1'b1 : b5_cnt);
    logic [61:0] b5_t0;
    (* shreg_extract = "no" *) logic [61:0] b5_t0_q0;
    logic b5_t0_lwe; logic [7:0] b5_t0_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t0_lwd;
    always_ff @(posedge clk) begin b5_t0_lwe <= ld_v && ld_iq >= 9'd48 && ld_iq < 9'd64; b5_t0_lwa <= {ld_slq[2:0], ld_drq, 4'(ld_iq - 9'd48)}; b5_t0_lwd <= ld_d[61:0]; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_tw2_tab0 b5_t0_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5], b5_cnt[4]}), .we(b5_t0_lwe), .wa(b5_t0_lwa), .wcol(1'b0), .wd(b5_t0_lwd), .q0(b5_t0_q0));
    always_ff @(posedge clk) begin b5_t0 <= b5_t0_q0; end
    logic [61:0] b5_t1;
    (* shreg_extract = "no" *) logic [61:0] b5_t1_q0;
    logic b5_t1_lwe; logic [6:0] b5_t1_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t1_lwd;
    always_ff @(posedge clk) begin b5_t1_lwe <= ld_v && ld_iq >= 9'd64 && ld_iq < 9'd72; b5_t1_lwa <= {ld_slq[2:0], ld_drq, 3'(ld_iq - 9'd64)}; b5_t1_lwd <= ld_d[61:0]; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_tw2_tab1 b5_t1_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[10], b5_cnt[9], b5_cnt[8]}), .we(b5_t1_lwe), .wa(b5_t1_lwa), .wcol(1'b0), .wd(b5_t1_lwd), .q0(b5_t1_q0));
    always_ff @(posedge clk) begin b5_t1 <= b5_t1_q0; end
    logic [61:0] b5_t2;
    (* shreg_extract = "no" *) logic [61:0] b5_t2_q0;
    logic b5_t2_lwe; logic [7:0] b5_t2_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t2_lwd;
    always_ff @(posedge clk) begin b5_t2_lwe <= ld_v && ld_iq >= 9'd72 && ld_iq < 9'd88; b5_t2_lwa <= {ld_slq[2:0], ld_drq, 4'(ld_iq - 9'd72)}; b5_t2_lwd <= ld_d[61:0]; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_tw2_tab2 b5_t2_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5], b5_cnt[4]}), .we(b5_t2_lwe), .wa(b5_t2_lwa), .wcol(1'b0), .wd(b5_t2_lwd), .q0(b5_t2_q0));
    always_ff @(posedge clk) begin b5_t2 <= b5_t2_q0; end
    logic [61:0] b5_t3;
    (* shreg_extract = "no" *) logic [61:0] b5_t3_q0;
    logic b5_t3_lwe; logic [7:0] b5_t3_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b5_t3_lwd;
    always_ff @(posedge clk) begin b5_t3_lwe <= ld_v && ld_iq >= 9'd88 && ld_iq < 9'd104; b5_t3_lwa <= {ld_slq[2:0], ld_drq, 4'(ld_iq - 9'd88)}; b5_t3_lwd <= ld_d[61:0]; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_tw2_tab3 b5_t3_i (.clk(clk), .addr({b4_tag[3:1], b4_tag[0], b5_cnt[7], b5_cnt[6], b5_cnt[5], b5_cnt[4]}), .we(b5_t3_lwe), .wa(b5_t3_lwa), .wcol(1'b0), .wd(b5_t3_lwd), .q0(b5_t3_q0));
    always_ff @(posedge clk) begin b5_t3 <= b5_t3_q0; end
    logic [61:0] b5_g0_z;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_zg_ia, b5_g0_zg_ib;
    always_ff @(posedge clk) begin b5_g0_zg_ia <= b5_t0; b5_g0_zg_ib <= b5_t1; end
    logic [44:0] b5_gq4_0_QH_c; assign b5_gq4_0_QH_c = b4_tag[48:4];
    logic [44:0] b5_gq4_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(3)) b5_gq4_0_QH_i (.clk(clk), .din(b5_gq4_0_QH_c), .dout(b5_gq4_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq4_s0_QH;
    always_ff @(posedge clk) b5_gq4_s0_QH <= b5_gq4_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_zg (.clk(clk), .A(b5_g0_zg_ia), .B(b5_g0_zg_ib), .QH(b5_gq4_s0_QH), .P(b5_g0_z));
    logic [61:0] b5_g0_yd;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_g0_yd_i (.clk(clk), .din(b5_t2), .dout(b5_g0_yd));
    logic [61:0] b5_g0_zp1;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_zp1_m_ia, b5_g0_zp1_m_ib;
    always_ff @(posedge clk) begin b5_g0_zp1_m_ia <= b5_g0_z; b5_g0_zp1_m_ib <= b5_g0_z; end
    logic [44:0] b5_gq30_0_QH_c; assign b5_gq30_0_QH_c = b4_tag[48:4];
    logic [44:0] b5_gq30_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(29)) b5_gq30_0_QH_i (.clk(clk), .din(b5_gq30_0_QH_c), .dout(b5_gq30_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq30_s0_QH;
    always_ff @(posedge clk) b5_gq30_s0_QH <= b5_gq30_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_zp1_m (.clk(clk), .A(b5_g0_zp1_m_ia), .B(b5_g0_zp1_m_ib), .QH(b5_gq30_s0_QH), .P(b5_g0_zp1));
    logic [61:0] b5_g0_zp2;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_zp2_m_ia, b5_g0_zp2_m_ib;
    always_ff @(posedge clk) begin b5_g0_zp2_m_ia <= b5_g0_zp1; b5_g0_zp2_m_ib <= b5_g0_zp1; end
    logic [44:0] b5_gq56_0_QH_c; assign b5_gq56_0_QH_c = b4_tag[48:4];
    logic [44:0] b5_gq56_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(55)) b5_gq56_0_QH_i (.clk(clk), .din(b5_gq56_0_QH_c), .dout(b5_gq56_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq56_s0_QH;
    always_ff @(posedge clk) b5_gq56_s0_QH <= b5_gq56_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_zp2_m (.clk(clk), .A(b5_g0_zp2_m_ia), .B(b5_g0_zp2_m_ib), .QH(b5_gq56_s0_QH), .P(b5_g0_zp2));
    logic [61:0] b5_g0_zp3;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_zp3_m_ia, b5_g0_zp3_m_ib;
    always_ff @(posedge clk) begin b5_g0_zp3_m_ia <= b5_g0_zp2; b5_g0_zp3_m_ib <= b5_g0_zp2; end
    logic [44:0] b5_gq82_0_QH_c; assign b5_gq82_0_QH_c = b4_tag[48:4];
    logic [44:0] b5_gq82_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(81)) b5_gq82_0_QH_i (.clk(clk), .din(b5_gq82_0_QH_c), .dout(b5_gq82_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq82_s0_QH;
    always_ff @(posedge clk) b5_gq82_s0_QH <= b5_gq82_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_zp3_m (.clk(clk), .A(b5_g0_zp3_m_ia), .B(b5_g0_zp3_m_ib), .QH(b5_gq82_s0_QH), .P(b5_g0_zp3));
    logic [61:0] b5_g0_w1;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_w1_m_ia, b5_g0_w1_m_ib;
    always_ff @(posedge clk) begin b5_g0_w1_m_ia <= b5_g0_yd; b5_g0_w1_m_ib <= b5_g0_z; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_w1_m (.clk(clk), .A(b5_g0_w1_m_ia), .B(b5_g0_w1_m_ib), .QH(b5_gq30_s0_QH), .P(b5_g0_w1));
    logic [61:0] b5_g0_w2_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_g0_w2_a_i (.clk(clk), .din(b5_g0_yd), .dout(b5_g0_w2_a));
    logic [61:0] b5_g0_w2;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_w2_m_ia, b5_g0_w2_m_ib;
    always_ff @(posedge clk) begin b5_g0_w2_m_ia <= b5_g0_w2_a; b5_g0_w2_m_ib <= b5_g0_zp1; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_w2_m (.clk(clk), .A(b5_g0_w2_m_ia), .B(b5_g0_w2_m_ib), .QH(b5_gq56_s0_QH), .P(b5_g0_w2));
    logic [61:0] b5_g0_w3;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_w3_m_ia, b5_g0_w3_m_ib;
    always_ff @(posedge clk) begin b5_g0_w3_m_ia <= b5_g0_w1; b5_g0_w3_m_ib <= b5_g0_zp1; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_w3_m (.clk(clk), .A(b5_g0_w3_m_ia), .B(b5_g0_w3_m_ib), .QH(b5_gq56_s0_QH), .P(b5_g0_w3));
    logic [61:0] b5_g0_w4_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b5_g0_w4_a_i (.clk(clk), .din(b5_g0_yd), .dout(b5_g0_w4_a));
    logic [61:0] b5_g0_w4;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_w4_m_ia, b5_g0_w4_m_ib;
    always_ff @(posedge clk) begin b5_g0_w4_m_ia <= b5_g0_w4_a; b5_g0_w4_m_ib <= b5_g0_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_w4_m (.clk(clk), .A(b5_g0_w4_m_ia), .B(b5_g0_w4_m_ib), .QH(b5_gq82_s0_QH), .P(b5_g0_w4));
    logic [61:0] b5_g0_w5_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_g0_w5_a_i (.clk(clk), .din(b5_g0_w1), .dout(b5_g0_w5_a));
    logic [61:0] b5_g0_w5;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_w5_m_ia, b5_g0_w5_m_ib;
    always_ff @(posedge clk) begin b5_g0_w5_m_ia <= b5_g0_w5_a; b5_g0_w5_m_ib <= b5_g0_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_w5_m (.clk(clk), .A(b5_g0_w5_m_ia), .B(b5_g0_w5_m_ib), .QH(b5_gq82_s0_QH), .P(b5_g0_w5));
    logic [61:0] b5_g0_w6;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_w6_m_ia, b5_g0_w6_m_ib;
    always_ff @(posedge clk) begin b5_g0_w6_m_ia <= b5_g0_w2; b5_g0_w6_m_ib <= b5_g0_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_w6_m (.clk(clk), .A(b5_g0_w6_m_ia), .B(b5_g0_w6_m_ib), .QH(b5_gq82_s0_QH), .P(b5_g0_w6));
    logic [61:0] b5_g0_w7;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_w7_m_ia, b5_g0_w7_m_ib;
    always_ff @(posedge clk) begin b5_g0_w7_m_ia <= b5_g0_w3; b5_g0_w7_m_ib <= b5_g0_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_w7_m (.clk(clk), .A(b5_g0_w7_m_ia), .B(b5_g0_w7_m_ib), .QH(b5_gq82_s0_QH), .P(b5_g0_w7));
    logic [61:0] b5_g0_w8_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(78)) b5_g0_w8_a_i (.clk(clk), .din(b5_g0_yd), .dout(b5_g0_w8_a));
    logic [61:0] b5_g0_w8;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_w8_m_ia, b5_g0_w8_m_ib;
    always_ff @(posedge clk) begin b5_g0_w8_m_ia <= b5_g0_w8_a; b5_g0_w8_m_ib <= b5_g0_zp3; end
    logic [44:0] b5_gq108_0_QH_c; assign b5_gq108_0_QH_c = b4_tag[48:4];
    logic [44:0] b5_gq108_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(107)) b5_gq108_0_QH_i (.clk(clk), .din(b5_gq108_0_QH_c), .dout(b5_gq108_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq108_s0_QH;
    always_ff @(posedge clk) b5_gq108_s0_QH <= b5_gq108_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_w8_m (.clk(clk), .A(b5_g0_w8_m_ia), .B(b5_g0_w8_m_ib), .QH(b5_gq108_s0_QH), .P(b5_g0_w8));
    logic [61:0] b5_g0_w9_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b5_g0_w9_a_i (.clk(clk), .din(b5_g0_w1), .dout(b5_g0_w9_a));
    logic [61:0] b5_g0_w9;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_w9_m_ia, b5_g0_w9_m_ib;
    always_ff @(posedge clk) begin b5_g0_w9_m_ia <= b5_g0_w9_a; b5_g0_w9_m_ib <= b5_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_w9_m (.clk(clk), .A(b5_g0_w9_m_ia), .B(b5_g0_w9_m_ib), .QH(b5_gq108_s0_QH), .P(b5_g0_w9));
    logic [61:0] b5_g0_w10_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_g0_w10_a_i (.clk(clk), .din(b5_g0_w2), .dout(b5_g0_w10_a));
    logic [61:0] b5_g0_w10;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_w10_m_ia, b5_g0_w10_m_ib;
    always_ff @(posedge clk) begin b5_g0_w10_m_ia <= b5_g0_w10_a; b5_g0_w10_m_ib <= b5_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_w10_m (.clk(clk), .A(b5_g0_w10_m_ia), .B(b5_g0_w10_m_ib), .QH(b5_gq108_s0_QH), .P(b5_g0_w10));
    logic [61:0] b5_g0_w11_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_g0_w11_a_i (.clk(clk), .din(b5_g0_w3), .dout(b5_g0_w11_a));
    logic [61:0] b5_g0_w11;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_w11_m_ia, b5_g0_w11_m_ib;
    always_ff @(posedge clk) begin b5_g0_w11_m_ia <= b5_g0_w11_a; b5_g0_w11_m_ib <= b5_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_w11_m (.clk(clk), .A(b5_g0_w11_m_ia), .B(b5_g0_w11_m_ib), .QH(b5_gq108_s0_QH), .P(b5_g0_w11));
    logic [61:0] b5_g0_w12;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_w12_m_ia, b5_g0_w12_m_ib;
    always_ff @(posedge clk) begin b5_g0_w12_m_ia <= b5_g0_w4; b5_g0_w12_m_ib <= b5_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_w12_m (.clk(clk), .A(b5_g0_w12_m_ia), .B(b5_g0_w12_m_ib), .QH(b5_gq108_s0_QH), .P(b5_g0_w12));
    logic [61:0] b5_g0_w13;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_w13_m_ia, b5_g0_w13_m_ib;
    always_ff @(posedge clk) begin b5_g0_w13_m_ia <= b5_g0_w5; b5_g0_w13_m_ib <= b5_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_w13_m (.clk(clk), .A(b5_g0_w13_m_ia), .B(b5_g0_w13_m_ib), .QH(b5_gq108_s0_QH), .P(b5_g0_w13));
    logic [61:0] b5_g0_w14;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_w14_m_ia, b5_g0_w14_m_ib;
    always_ff @(posedge clk) begin b5_g0_w14_m_ia <= b5_g0_w6; b5_g0_w14_m_ib <= b5_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_w14_m (.clk(clk), .A(b5_g0_w14_m_ia), .B(b5_g0_w14_m_ib), .QH(b5_gq108_s0_QH), .P(b5_g0_w14));
    logic [61:0] b5_g0_w15;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g0_w15_m_ia, b5_g0_w15_m_ib;
    always_ff @(posedge clk) begin b5_g0_w15_m_ia <= b5_g0_w7; b5_g0_w15_m_ib <= b5_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g0_w15_m (.clk(clk), .A(b5_g0_w15_m_ia), .B(b5_g0_w15_m_ib), .QH(b5_gq108_s0_QH), .P(b5_g0_w15));
    logic [61:0] b5_l0_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l0_a_i (.clk(clk), .din(b4_g0_o[0]), .dout(b5_l0_a));
    logic [44:0] b5_mq133_0_QH_c; assign b5_mq133_0_QH_c = b4_tag[48:4];
    logic [44:0] b5_mq133_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(132)) b5_mq133_0_QH_i (.clk(clk), .din(b5_mq133_0_QH_c), .dout(b5_mq133_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_mq133_s0_QH;
    always_ff @(posedge clk) b5_mq133_s0_QH <= b5_mq133_0_QH;
    logic [61:0] b5_l0_p;
    logic [61:0] b5_l0_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(104)) b5_l0_w_i (.clk(clk), .din(b5_g0_yd), .dout(b5_l0_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l0_mul (.clk(clk), .A(b5_l0_a), .B(b5_l0_w), .QH(b5_mq133_s0_QH), .P(b5_l0_p));
    logic [61:0] b5_l1_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l1_a_i (.clk(clk), .din(b4_g0_o[1]), .dout(b5_l1_a));
    logic [61:0] b5_l1_p;
    logic [61:0] b5_l1_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(78)) b5_l1_w_i (.clk(clk), .din(b5_g0_w1), .dout(b5_l1_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l1_mul (.clk(clk), .A(b5_l1_a), .B(b5_l1_w), .QH(b5_mq133_s0_QH), .P(b5_l1_p));
    logic [61:0] b5_l2_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l2_a_i (.clk(clk), .din(b4_g0_o[2]), .dout(b5_l2_a));
    logic [61:0] b5_l2_p;
    logic [61:0] b5_l2_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b5_l2_w_i (.clk(clk), .din(b5_g0_w2), .dout(b5_l2_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l2_mul (.clk(clk), .A(b5_l2_a), .B(b5_l2_w), .QH(b5_mq133_s0_QH), .P(b5_l2_p));
    logic [61:0] b5_l3_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l3_a_i (.clk(clk), .din(b4_g0_o[3]), .dout(b5_l3_a));
    logic [61:0] b5_l3_p;
    logic [61:0] b5_l3_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b5_l3_w_i (.clk(clk), .din(b5_g0_w3), .dout(b5_l3_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l3_mul (.clk(clk), .A(b5_l3_a), .B(b5_l3_w), .QH(b5_mq133_s0_QH), .P(b5_l3_p));
    logic [61:0] b5_l4_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l4_a_i (.clk(clk), .din(b4_g0_o[4]), .dout(b5_l4_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_mq133_s1_QH;
    always_ff @(posedge clk) b5_mq133_s1_QH <= b5_mq133_0_QH;
    logic [61:0] b5_l4_p;
    logic [61:0] b5_l4_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_l4_w_i (.clk(clk), .din(b5_g0_w4), .dout(b5_l4_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l4_mul (.clk(clk), .A(b5_l4_a), .B(b5_l4_w), .QH(b5_mq133_s1_QH), .P(b5_l4_p));
    logic [61:0] b5_l5_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l5_a_i (.clk(clk), .din(b4_g0_o[5]), .dout(b5_l5_a));
    logic [61:0] b5_l5_p;
    logic [61:0] b5_l5_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_l5_w_i (.clk(clk), .din(b5_g0_w5), .dout(b5_l5_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l5_mul (.clk(clk), .A(b5_l5_a), .B(b5_l5_w), .QH(b5_mq133_s1_QH), .P(b5_l5_p));
    logic [61:0] b5_l6_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l6_a_i (.clk(clk), .din(b4_g0_o[6]), .dout(b5_l6_a));
    logic [61:0] b5_l6_p;
    logic [61:0] b5_l6_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_l6_w_i (.clk(clk), .din(b5_g0_w6), .dout(b5_l6_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l6_mul (.clk(clk), .A(b5_l6_a), .B(b5_l6_w), .QH(b5_mq133_s1_QH), .P(b5_l6_p));
    logic [61:0] b5_l7_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l7_a_i (.clk(clk), .din(b4_g0_o[7]), .dout(b5_l7_a));
    logic [61:0] b5_l7_p;
    logic [61:0] b5_l7_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_l7_w_i (.clk(clk), .din(b5_g0_w7), .dout(b5_l7_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l7_mul (.clk(clk), .A(b5_l7_a), .B(b5_l7_w), .QH(b5_mq133_s1_QH), .P(b5_l7_p));
    logic [61:0] b5_l8_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l8_a_i (.clk(clk), .din(b4_g0_o[8]), .dout(b5_l8_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_mq133_s2_QH;
    always_ff @(posedge clk) b5_mq133_s2_QH <= b5_mq133_0_QH;
    logic [61:0] b5_l8_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l8_mul (.clk(clk), .A(b5_l8_a), .B(b5_g0_w8), .QH(b5_mq133_s2_QH), .P(b5_l8_p));
    logic [61:0] b5_l9_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l9_a_i (.clk(clk), .din(b4_g0_o[9]), .dout(b5_l9_a));
    logic [61:0] b5_l9_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l9_mul (.clk(clk), .A(b5_l9_a), .B(b5_g0_w9), .QH(b5_mq133_s2_QH), .P(b5_l9_p));
    logic [61:0] b5_l10_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l10_a_i (.clk(clk), .din(b4_g0_o[10]), .dout(b5_l10_a));
    logic [61:0] b5_l10_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l10_mul (.clk(clk), .A(b5_l10_a), .B(b5_g0_w10), .QH(b5_mq133_s2_QH), .P(b5_l10_p));
    logic [61:0] b5_l11_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l11_a_i (.clk(clk), .din(b4_g0_o[11]), .dout(b5_l11_a));
    logic [61:0] b5_l11_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l11_mul (.clk(clk), .A(b5_l11_a), .B(b5_g0_w11), .QH(b5_mq133_s2_QH), .P(b5_l11_p));
    logic [61:0] b5_l12_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l12_a_i (.clk(clk), .din(b4_g0_o[12]), .dout(b5_l12_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_mq133_s3_QH;
    always_ff @(posedge clk) b5_mq133_s3_QH <= b5_mq133_0_QH;
    logic [61:0] b5_l12_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l12_mul (.clk(clk), .A(b5_l12_a), .B(b5_g0_w12), .QH(b5_mq133_s3_QH), .P(b5_l12_p));
    logic [61:0] b5_l13_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l13_a_i (.clk(clk), .din(b4_g0_o[13]), .dout(b5_l13_a));
    logic [61:0] b5_l13_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l13_mul (.clk(clk), .A(b5_l13_a), .B(b5_g0_w13), .QH(b5_mq133_s3_QH), .P(b5_l13_p));
    logic [61:0] b5_l14_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l14_a_i (.clk(clk), .din(b4_g0_o[14]), .dout(b5_l14_a));
    logic [61:0] b5_l14_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l14_mul (.clk(clk), .A(b5_l14_a), .B(b5_g0_w14), .QH(b5_mq133_s3_QH), .P(b5_l14_p));
    logic [61:0] b5_l15_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l15_a_i (.clk(clk), .din(b4_g0_o[15]), .dout(b5_l15_a));
    logic [61:0] b5_l15_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l15_mul (.clk(clk), .A(b5_l15_a), .B(b5_g0_w15), .QH(b5_mq133_s3_QH), .P(b5_l15_p));
    logic [61:0] b5_g1_z;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_zg_ia, b5_g1_zg_ib;
    always_ff @(posedge clk) begin b5_g1_zg_ia <= b5_t3; b5_g1_zg_ib <= b5_t1; end
    logic [44:0] b5_gq4_1_QH_c; assign b5_gq4_1_QH_c = b4_tag[48:4];
    logic [44:0] b5_gq4_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(3)) b5_gq4_1_QH_i (.clk(clk), .din(b5_gq4_1_QH_c), .dout(b5_gq4_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq4_s4_QH;
    always_ff @(posedge clk) b5_gq4_s4_QH <= b5_gq4_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_zg (.clk(clk), .A(b5_g1_zg_ia), .B(b5_g1_zg_ib), .QH(b5_gq4_s4_QH), .P(b5_g1_z));
    logic [61:0] b5_g1_yd;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_g1_yd_i (.clk(clk), .din(b5_t2), .dout(b5_g1_yd));
    logic [61:0] b5_g1_zp1;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_zp1_m_ia, b5_g1_zp1_m_ib;
    always_ff @(posedge clk) begin b5_g1_zp1_m_ia <= b5_g1_z; b5_g1_zp1_m_ib <= b5_g1_z; end
    logic [44:0] b5_gq30_1_QH_c; assign b5_gq30_1_QH_c = b4_tag[48:4];
    logic [44:0] b5_gq30_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(29)) b5_gq30_1_QH_i (.clk(clk), .din(b5_gq30_1_QH_c), .dout(b5_gq30_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq30_s4_QH;
    always_ff @(posedge clk) b5_gq30_s4_QH <= b5_gq30_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_zp1_m (.clk(clk), .A(b5_g1_zp1_m_ia), .B(b5_g1_zp1_m_ib), .QH(b5_gq30_s4_QH), .P(b5_g1_zp1));
    logic [61:0] b5_g1_zp2;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_zp2_m_ia, b5_g1_zp2_m_ib;
    always_ff @(posedge clk) begin b5_g1_zp2_m_ia <= b5_g1_zp1; b5_g1_zp2_m_ib <= b5_g1_zp1; end
    logic [44:0] b5_gq56_1_QH_c; assign b5_gq56_1_QH_c = b4_tag[48:4];
    logic [44:0] b5_gq56_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(55)) b5_gq56_1_QH_i (.clk(clk), .din(b5_gq56_1_QH_c), .dout(b5_gq56_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq56_s4_QH;
    always_ff @(posedge clk) b5_gq56_s4_QH <= b5_gq56_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_zp2_m (.clk(clk), .A(b5_g1_zp2_m_ia), .B(b5_g1_zp2_m_ib), .QH(b5_gq56_s4_QH), .P(b5_g1_zp2));
    logic [61:0] b5_g1_zp3;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_zp3_m_ia, b5_g1_zp3_m_ib;
    always_ff @(posedge clk) begin b5_g1_zp3_m_ia <= b5_g1_zp2; b5_g1_zp3_m_ib <= b5_g1_zp2; end
    logic [44:0] b5_gq82_1_QH_c; assign b5_gq82_1_QH_c = b4_tag[48:4];
    logic [44:0] b5_gq82_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(81)) b5_gq82_1_QH_i (.clk(clk), .din(b5_gq82_1_QH_c), .dout(b5_gq82_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq82_s4_QH;
    always_ff @(posedge clk) b5_gq82_s4_QH <= b5_gq82_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_zp3_m (.clk(clk), .A(b5_g1_zp3_m_ia), .B(b5_g1_zp3_m_ib), .QH(b5_gq82_s4_QH), .P(b5_g1_zp3));
    logic [61:0] b5_g1_w1;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_w1_m_ia, b5_g1_w1_m_ib;
    always_ff @(posedge clk) begin b5_g1_w1_m_ia <= b5_g1_yd; b5_g1_w1_m_ib <= b5_g1_z; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_w1_m (.clk(clk), .A(b5_g1_w1_m_ia), .B(b5_g1_w1_m_ib), .QH(b5_gq30_s4_QH), .P(b5_g1_w1));
    logic [61:0] b5_g1_w2_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_g1_w2_a_i (.clk(clk), .din(b5_g1_yd), .dout(b5_g1_w2_a));
    logic [61:0] b5_g1_w2;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_w2_m_ia, b5_g1_w2_m_ib;
    always_ff @(posedge clk) begin b5_g1_w2_m_ia <= b5_g1_w2_a; b5_g1_w2_m_ib <= b5_g1_zp1; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_w2_m (.clk(clk), .A(b5_g1_w2_m_ia), .B(b5_g1_w2_m_ib), .QH(b5_gq56_s4_QH), .P(b5_g1_w2));
    logic [61:0] b5_g1_w3;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_w3_m_ia, b5_g1_w3_m_ib;
    always_ff @(posedge clk) begin b5_g1_w3_m_ia <= b5_g1_w1; b5_g1_w3_m_ib <= b5_g1_zp1; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_w3_m (.clk(clk), .A(b5_g1_w3_m_ia), .B(b5_g1_w3_m_ib), .QH(b5_gq56_s4_QH), .P(b5_g1_w3));
    logic [61:0] b5_g1_w4_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b5_g1_w4_a_i (.clk(clk), .din(b5_g1_yd), .dout(b5_g1_w4_a));
    logic [61:0] b5_g1_w4;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_w4_m_ia, b5_g1_w4_m_ib;
    always_ff @(posedge clk) begin b5_g1_w4_m_ia <= b5_g1_w4_a; b5_g1_w4_m_ib <= b5_g1_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_w4_m (.clk(clk), .A(b5_g1_w4_m_ia), .B(b5_g1_w4_m_ib), .QH(b5_gq82_s4_QH), .P(b5_g1_w4));
    logic [61:0] b5_g1_w5_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_g1_w5_a_i (.clk(clk), .din(b5_g1_w1), .dout(b5_g1_w5_a));
    logic [61:0] b5_g1_w5;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_w5_m_ia, b5_g1_w5_m_ib;
    always_ff @(posedge clk) begin b5_g1_w5_m_ia <= b5_g1_w5_a; b5_g1_w5_m_ib <= b5_g1_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_w5_m (.clk(clk), .A(b5_g1_w5_m_ia), .B(b5_g1_w5_m_ib), .QH(b5_gq82_s4_QH), .P(b5_g1_w5));
    logic [61:0] b5_g1_w6;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_w6_m_ia, b5_g1_w6_m_ib;
    always_ff @(posedge clk) begin b5_g1_w6_m_ia <= b5_g1_w2; b5_g1_w6_m_ib <= b5_g1_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_w6_m (.clk(clk), .A(b5_g1_w6_m_ia), .B(b5_g1_w6_m_ib), .QH(b5_gq82_s4_QH), .P(b5_g1_w6));
    logic [61:0] b5_g1_w7;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_w7_m_ia, b5_g1_w7_m_ib;
    always_ff @(posedge clk) begin b5_g1_w7_m_ia <= b5_g1_w3; b5_g1_w7_m_ib <= b5_g1_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_w7_m (.clk(clk), .A(b5_g1_w7_m_ia), .B(b5_g1_w7_m_ib), .QH(b5_gq82_s4_QH), .P(b5_g1_w7));
    logic [61:0] b5_g1_w8_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(78)) b5_g1_w8_a_i (.clk(clk), .din(b5_g1_yd), .dout(b5_g1_w8_a));
    logic [61:0] b5_g1_w8;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_w8_m_ia, b5_g1_w8_m_ib;
    always_ff @(posedge clk) begin b5_g1_w8_m_ia <= b5_g1_w8_a; b5_g1_w8_m_ib <= b5_g1_zp3; end
    logic [44:0] b5_gq108_1_QH_c; assign b5_gq108_1_QH_c = b4_tag[48:4];
    logic [44:0] b5_gq108_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(107)) b5_gq108_1_QH_i (.clk(clk), .din(b5_gq108_1_QH_c), .dout(b5_gq108_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_gq108_s4_QH;
    always_ff @(posedge clk) b5_gq108_s4_QH <= b5_gq108_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_w8_m (.clk(clk), .A(b5_g1_w8_m_ia), .B(b5_g1_w8_m_ib), .QH(b5_gq108_s4_QH), .P(b5_g1_w8));
    logic [61:0] b5_g1_w9_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b5_g1_w9_a_i (.clk(clk), .din(b5_g1_w1), .dout(b5_g1_w9_a));
    logic [61:0] b5_g1_w9;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_w9_m_ia, b5_g1_w9_m_ib;
    always_ff @(posedge clk) begin b5_g1_w9_m_ia <= b5_g1_w9_a; b5_g1_w9_m_ib <= b5_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_w9_m (.clk(clk), .A(b5_g1_w9_m_ia), .B(b5_g1_w9_m_ib), .QH(b5_gq108_s4_QH), .P(b5_g1_w9));
    logic [61:0] b5_g1_w10_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_g1_w10_a_i (.clk(clk), .din(b5_g1_w2), .dout(b5_g1_w10_a));
    logic [61:0] b5_g1_w10;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_w10_m_ia, b5_g1_w10_m_ib;
    always_ff @(posedge clk) begin b5_g1_w10_m_ia <= b5_g1_w10_a; b5_g1_w10_m_ib <= b5_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_w10_m (.clk(clk), .A(b5_g1_w10_m_ia), .B(b5_g1_w10_m_ib), .QH(b5_gq108_s4_QH), .P(b5_g1_w10));
    logic [61:0] b5_g1_w11_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_g1_w11_a_i (.clk(clk), .din(b5_g1_w3), .dout(b5_g1_w11_a));
    logic [61:0] b5_g1_w11;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_w11_m_ia, b5_g1_w11_m_ib;
    always_ff @(posedge clk) begin b5_g1_w11_m_ia <= b5_g1_w11_a; b5_g1_w11_m_ib <= b5_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_w11_m (.clk(clk), .A(b5_g1_w11_m_ia), .B(b5_g1_w11_m_ib), .QH(b5_gq108_s4_QH), .P(b5_g1_w11));
    logic [61:0] b5_g1_w12;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_w12_m_ia, b5_g1_w12_m_ib;
    always_ff @(posedge clk) begin b5_g1_w12_m_ia <= b5_g1_w4; b5_g1_w12_m_ib <= b5_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_w12_m (.clk(clk), .A(b5_g1_w12_m_ia), .B(b5_g1_w12_m_ib), .QH(b5_gq108_s4_QH), .P(b5_g1_w12));
    logic [61:0] b5_g1_w13;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_w13_m_ia, b5_g1_w13_m_ib;
    always_ff @(posedge clk) begin b5_g1_w13_m_ia <= b5_g1_w5; b5_g1_w13_m_ib <= b5_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_w13_m (.clk(clk), .A(b5_g1_w13_m_ia), .B(b5_g1_w13_m_ib), .QH(b5_gq108_s4_QH), .P(b5_g1_w13));
    logic [61:0] b5_g1_w14;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_w14_m_ia, b5_g1_w14_m_ib;
    always_ff @(posedge clk) begin b5_g1_w14_m_ia <= b5_g1_w6; b5_g1_w14_m_ib <= b5_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_w14_m (.clk(clk), .A(b5_g1_w14_m_ia), .B(b5_g1_w14_m_ib), .QH(b5_gq108_s4_QH), .P(b5_g1_w14));
    logic [61:0] b5_g1_w15;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b5_g1_w15_m_ia, b5_g1_w15_m_ib;
    always_ff @(posedge clk) begin b5_g1_w15_m_ia <= b5_g1_w7; b5_g1_w15_m_ib <= b5_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b5_g1_w15_m (.clk(clk), .A(b5_g1_w15_m_ia), .B(b5_g1_w15_m_ib), .QH(b5_gq108_s4_QH), .P(b5_g1_w15));
    logic [61:0] b5_l16_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l16_a_i (.clk(clk), .din(b4_g1_o[0]), .dout(b5_l16_a));
    logic [44:0] b5_mq133_1_QH_c; assign b5_mq133_1_QH_c = b4_tag[48:4];
    logic [44:0] b5_mq133_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(132)) b5_mq133_1_QH_i (.clk(clk), .din(b5_mq133_1_QH_c), .dout(b5_mq133_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_mq133_s4_QH;
    always_ff @(posedge clk) b5_mq133_s4_QH <= b5_mq133_1_QH;
    logic [61:0] b5_l16_p;
    logic [61:0] b5_l16_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(104)) b5_l16_w_i (.clk(clk), .din(b5_g1_yd), .dout(b5_l16_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l16_mul (.clk(clk), .A(b5_l16_a), .B(b5_l16_w), .QH(b5_mq133_s4_QH), .P(b5_l16_p));
    logic [61:0] b5_l17_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l17_a_i (.clk(clk), .din(b4_g1_o[1]), .dout(b5_l17_a));
    logic [61:0] b5_l17_p;
    logic [61:0] b5_l17_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(78)) b5_l17_w_i (.clk(clk), .din(b5_g1_w1), .dout(b5_l17_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l17_mul (.clk(clk), .A(b5_l17_a), .B(b5_l17_w), .QH(b5_mq133_s4_QH), .P(b5_l17_p));
    logic [61:0] b5_l18_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l18_a_i (.clk(clk), .din(b4_g1_o[2]), .dout(b5_l18_a));
    logic [61:0] b5_l18_p;
    logic [61:0] b5_l18_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b5_l18_w_i (.clk(clk), .din(b5_g1_w2), .dout(b5_l18_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l18_mul (.clk(clk), .A(b5_l18_a), .B(b5_l18_w), .QH(b5_mq133_s4_QH), .P(b5_l18_p));
    logic [61:0] b5_l19_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l19_a_i (.clk(clk), .din(b4_g1_o[3]), .dout(b5_l19_a));
    logic [61:0] b5_l19_p;
    logic [61:0] b5_l19_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b5_l19_w_i (.clk(clk), .din(b5_g1_w3), .dout(b5_l19_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l19_mul (.clk(clk), .A(b5_l19_a), .B(b5_l19_w), .QH(b5_mq133_s4_QH), .P(b5_l19_p));
    logic [61:0] b5_l20_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l20_a_i (.clk(clk), .din(b4_g1_o[4]), .dout(b5_l20_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_mq133_s5_QH;
    always_ff @(posedge clk) b5_mq133_s5_QH <= b5_mq133_1_QH;
    logic [61:0] b5_l20_p;
    logic [61:0] b5_l20_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_l20_w_i (.clk(clk), .din(b5_g1_w4), .dout(b5_l20_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l20_mul (.clk(clk), .A(b5_l20_a), .B(b5_l20_w), .QH(b5_mq133_s5_QH), .P(b5_l20_p));
    logic [61:0] b5_l21_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l21_a_i (.clk(clk), .din(b4_g1_o[5]), .dout(b5_l21_a));
    logic [61:0] b5_l21_p;
    logic [61:0] b5_l21_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_l21_w_i (.clk(clk), .din(b5_g1_w5), .dout(b5_l21_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l21_mul (.clk(clk), .A(b5_l21_a), .B(b5_l21_w), .QH(b5_mq133_s5_QH), .P(b5_l21_p));
    logic [61:0] b5_l22_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l22_a_i (.clk(clk), .din(b4_g1_o[6]), .dout(b5_l22_a));
    logic [61:0] b5_l22_p;
    logic [61:0] b5_l22_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_l22_w_i (.clk(clk), .din(b5_g1_w6), .dout(b5_l22_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l22_mul (.clk(clk), .A(b5_l22_a), .B(b5_l22_w), .QH(b5_mq133_s5_QH), .P(b5_l22_p));
    logic [61:0] b5_l23_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l23_a_i (.clk(clk), .din(b4_g1_o[7]), .dout(b5_l23_a));
    logic [61:0] b5_l23_p;
    logic [61:0] b5_l23_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b5_l23_w_i (.clk(clk), .din(b5_g1_w7), .dout(b5_l23_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l23_mul (.clk(clk), .A(b5_l23_a), .B(b5_l23_w), .QH(b5_mq133_s5_QH), .P(b5_l23_p));
    logic [61:0] b5_l24_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l24_a_i (.clk(clk), .din(b4_g1_o[8]), .dout(b5_l24_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_mq133_s6_QH;
    always_ff @(posedge clk) b5_mq133_s6_QH <= b5_mq133_1_QH;
    logic [61:0] b5_l24_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l24_mul (.clk(clk), .A(b5_l24_a), .B(b5_g1_w8), .QH(b5_mq133_s6_QH), .P(b5_l24_p));
    logic [61:0] b5_l25_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l25_a_i (.clk(clk), .din(b4_g1_o[9]), .dout(b5_l25_a));
    logic [61:0] b5_l25_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l25_mul (.clk(clk), .A(b5_l25_a), .B(b5_g1_w9), .QH(b5_mq133_s6_QH), .P(b5_l25_p));
    logic [61:0] b5_l26_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l26_a_i (.clk(clk), .din(b4_g1_o[10]), .dout(b5_l26_a));
    logic [61:0] b5_l26_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l26_mul (.clk(clk), .A(b5_l26_a), .B(b5_g1_w10), .QH(b5_mq133_s6_QH), .P(b5_l26_p));
    logic [61:0] b5_l27_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l27_a_i (.clk(clk), .din(b4_g1_o[11]), .dout(b5_l27_a));
    logic [61:0] b5_l27_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l27_mul (.clk(clk), .A(b5_l27_a), .B(b5_g1_w11), .QH(b5_mq133_s6_QH), .P(b5_l27_p));
    logic [61:0] b5_l28_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l28_a_i (.clk(clk), .din(b4_g1_o[12]), .dout(b5_l28_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b5_mq133_s7_QH;
    always_ff @(posedge clk) b5_mq133_s7_QH <= b5_mq133_1_QH;
    logic [61:0] b5_l28_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l28_mul (.clk(clk), .A(b5_l28_a), .B(b5_g1_w12), .QH(b5_mq133_s7_QH), .P(b5_l28_p));
    logic [61:0] b5_l29_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l29_a_i (.clk(clk), .din(b4_g1_o[13]), .dout(b5_l29_a));
    logic [61:0] b5_l29_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l29_mul (.clk(clk), .A(b5_l29_a), .B(b5_g1_w13), .QH(b5_mq133_s7_QH), .P(b5_l29_p));
    logic [61:0] b5_l30_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l30_a_i (.clk(clk), .din(b4_g1_o[14]), .dout(b5_l30_a));
    logic [61:0] b5_l30_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l30_mul (.clk(clk), .A(b5_l30_a), .B(b5_g1_w14), .QH(b5_mq133_s7_QH), .P(b5_l30_p));
    logic [61:0] b5_l31_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b5_l31_a_i (.clk(clk), .din(b4_g1_o[15]), .dout(b5_l31_a));
    logic [61:0] b5_l31_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b5_l31_mul (.clk(clk), .A(b5_l31_a), .B(b5_g1_w15), .QH(b5_mq133_s7_QH), .P(b5_l31_p));
    logic [156:0] b5_v_sr;
    always_ff @(posedge clk) b5_v_sr <= rst ? '0 : {b5_v_sr[155:0], b4_g0_v};
    logic b5_v; assign b5_v = b5_v_sr[156];
    logic [110:0] b5_tag;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(111), .D(157)) b5_tag_i (.clk(clk), .din(b4_tag), .dout(b5_tag));
    // block 6: pass 2, 2 x ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p1 (16-point), latency 90
    logic [61:0] b6_c0_y0, b6_c0_y1, b6_c0_y2, b6_c0_y3, b6_c0_y4, b6_c0_y5, b6_c0_y6, b6_c0_y7, b6_c0_y8, b6_c0_y9, b6_c0_y10, b6_c0_y11, b6_c0_y12, b6_c0_y13, b6_c0_y14, b6_c0_y15;
    logic b6_c0_v; logic [2:0] b6_c0_mi; logic b6_c0_di;
    logic b6_c0_lr, b6_c0_lw; (* equivalent_register_removal = "no" *) logic [61:0] b6_c0_ld;
    always_ff @(posedge clk) begin b6_c0_lr <= ld_r; b6_c0_lw <= ld_v && ld_iq >= 9'd41 && ld_iq < 9'd48; b6_c0_ld <= ld_d[61:0]; end
    logic [2:0] b6_c0_ls; always_ff @(posedge clk) b6_c0_ls <= ld_sl;
    logic b6_c0_ldr; always_ff @(posedge clk) b6_c0_ldr <= ld_dr;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p1 b6_c0 (.clk(clk), .rst(rst), .in_valid(b5_v), .out_valid(b6_c0_v), .MIDX(b5_tag[3:1]), .midx_out(b6_c0_mi), .mq_QH(b5_tag[48:4]), .mq_QHALF(b5_tag[110:49]), .DIR(b5_tag[0]), .dir_out(b6_c0_di), .tw_rst(b6_c0_lr), .tw_wen(b6_c0_lw), .tw_wdata(b6_c0_ld), .tw_slot(b6_c0_ls), .tw_dir(b6_c0_ldr), .x_in_0(b5_l0_p), .x_in_1(b5_l1_p), .x_in_2(b5_l2_p), .x_in_3(b5_l3_p), .x_in_4(b5_l4_p), .x_in_5(b5_l5_p), .x_in_6(b5_l6_p), .x_in_7(b5_l7_p), .x_in_8(b5_l8_p), .x_in_9(b5_l9_p), .x_in_10(b5_l10_p), .x_in_11(b5_l11_p), .x_in_12(b5_l12_p), .x_in_13(b5_l13_p), .x_in_14(b5_l14_p), .x_in_15(b5_l15_p), .y_out_0(b6_c0_y0), .y_out_1(b6_c0_y1), .y_out_2(b6_c0_y2), .y_out_3(b6_c0_y3), .y_out_4(b6_c0_y4), .y_out_5(b6_c0_y5), .y_out_6(b6_c0_y6), .y_out_7(b6_c0_y7), .y_out_8(b6_c0_y8), .y_out_9(b6_c0_y9), .y_out_10(b6_c0_y10), .y_out_11(b6_c0_y11), .y_out_12(b6_c0_y12), .y_out_13(b6_c0_y13), .y_out_14(b6_c0_y14), .y_out_15(b6_c0_y15));
    logic [61:0] b6_c1_y0, b6_c1_y1, b6_c1_y2, b6_c1_y3, b6_c1_y4, b6_c1_y5, b6_c1_y6, b6_c1_y7, b6_c1_y8, b6_c1_y9, b6_c1_y10, b6_c1_y11, b6_c1_y12, b6_c1_y13, b6_c1_y14, b6_c1_y15;
    logic b6_c1_v; logic [2:0] b6_c1_mi; logic b6_c1_di;
    logic b6_c1_lr, b6_c1_lw; (* equivalent_register_removal = "no" *) logic [61:0] b6_c1_ld;
    always_ff @(posedge clk) begin b6_c1_lr <= ld_r; b6_c1_lw <= ld_v && ld_iq >= 9'd41 && ld_iq < 9'd48; b6_c1_ld <= ld_d[61:0]; end
    logic [2:0] b6_c1_ls; always_ff @(posedge clk) b6_c1_ls <= ld_sl;
    logic b6_c1_ldr; always_ff @(posedge clk) b6_c1_ldr <= ld_dr;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p1 b6_c1 (.clk(clk), .rst(rst), .in_valid(b5_v), .out_valid(b6_c1_v), .MIDX(b5_tag[3:1]), .midx_out(b6_c1_mi), .mq_QH(b5_tag[48:4]), .mq_QHALF(b5_tag[110:49]), .DIR(b5_tag[0]), .dir_out(b6_c1_di), .tw_rst(b6_c1_lr), .tw_wen(b6_c1_lw), .tw_wdata(b6_c1_ld), .tw_slot(b6_c1_ls), .tw_dir(b6_c1_ldr), .x_in_0(b5_l16_p), .x_in_1(b5_l17_p), .x_in_2(b5_l18_p), .x_in_3(b5_l19_p), .x_in_4(b5_l20_p), .x_in_5(b5_l21_p), .x_in_6(b5_l22_p), .x_in_7(b5_l23_p), .x_in_8(b5_l24_p), .x_in_9(b5_l25_p), .x_in_10(b5_l26_p), .x_in_11(b5_l27_p), .x_in_12(b5_l28_p), .x_in_13(b5_l29_p), .x_in_14(b5_l30_p), .x_in_15(b5_l31_p), .y_out_0(b6_c1_y0), .y_out_1(b6_c1_y1), .y_out_2(b6_c1_y2), .y_out_3(b6_c1_y3), .y_out_4(b6_c1_y4), .y_out_5(b6_c1_y5), .y_out_6(b6_c1_y6), .y_out_7(b6_c1_y7), .y_out_8(b6_c1_y8), .y_out_9(b6_c1_y9), .y_out_10(b6_c1_y10), .y_out_11(b6_c1_y11), .y_out_12(b6_c1_y12), .y_out_13(b6_c1_y13), .y_out_14(b6_c1_y14), .y_out_15(b6_c1_y15));
    logic [106:0] b6_cq0; assign b6_cq0 = b5_tag[110:4];
    logic [106:0] b6_cq;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(107), .D(90)) b6_cq_i (.clk(clk), .din(b6_cq0), .dout(b6_cq));
    logic [110:0] b6_tag; assign b6_tag = {b6_cq, b6_c0_mi, b6_c0_di};
    // block 7: lane-time transpose, lane bits [0, 1, 2, 3] <-> cycle bits [0,4), 2 x S=16, latency 21
    logic [61:0] b7_g0_i [0:15]; logic [61:0] b7_g0_o [0:15]; logic b7_g0_v;
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
    lt_bmb_transpose #(.S(16), .LO(0), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h3), .RAM_STYLE("distributed")) b7_g0 (.clk(clk), .rst(rst), .data_valid(b6_c0_v), .data_in(b7_g0_i), .data_out_valid(b7_g0_v), .data_out(b7_g0_o));
    logic [61:0] b7_g1_i [0:15]; logic [61:0] b7_g1_o [0:15]; logic b7_g1_v;
    assign b7_g1_i[0] = b6_c1_y0;
    assign b7_g1_i[1] = b6_c1_y1;
    assign b7_g1_i[2] = b6_c1_y2;
    assign b7_g1_i[3] = b6_c1_y3;
    assign b7_g1_i[4] = b6_c1_y4;
    assign b7_g1_i[5] = b6_c1_y5;
    assign b7_g1_i[6] = b6_c1_y6;
    assign b7_g1_i[7] = b6_c1_y7;
    assign b7_g1_i[8] = b6_c1_y8;
    assign b7_g1_i[9] = b6_c1_y9;
    assign b7_g1_i[10] = b6_c1_y10;
    assign b7_g1_i[11] = b6_c1_y11;
    assign b7_g1_i[12] = b6_c1_y12;
    assign b7_g1_i[13] = b6_c1_y13;
    assign b7_g1_i[14] = b6_c1_y14;
    assign b7_g1_i[15] = b6_c1_y15;
    lt_bmb_transpose #(.S(16), .LO(0), .ELEMENT_WIDTH(62), .REG_FLAGS(32'h3), .RAM_STYLE("distributed")) b7_g1 (.clk(clk), .rst(rst), .data_valid(b6_c0_v), .data_in(b7_g1_i), .data_out_valid(b7_g1_v), .data_out(b7_g1_o));
    logic [110:0] b7_tag;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(111), .D(21)) b7_tag_i (.clk(clk), .din(b6_tag), .dout(b7_tag));
    // block 8: twiddle stage 3, latency 157 (tables 3, generator 25, multiplier 24)
    logic [10:0] b8_cnt;
    always_ff @(posedge clk) b8_cnt <= rst ? '0 : (b7_g0_v ? b8_cnt + 1'b1 : b8_cnt);
    logic [61:0] b8_t0;
    (* shreg_extract = "no" *) logic [61:0] b8_t0_q0;
    logic b8_t0_lwe; logic [9:0] b8_t0_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t0_lwd;
    always_ff @(posedge clk) begin b8_t0_lwe <= ld_v && ld_iq >= 9'd104 && ld_iq < 9'd168; b8_t0_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 9'd104)}; b8_t0_lwd <= ld_d[61:0]; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_tw3_tab0 b8_t0_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t0_lwe), .wa(b8_t0_lwa), .wcol(1'b0), .wd(b8_t0_lwd), .q0(b8_t0_q0));
    always_ff @(posedge clk) begin b8_t0 <= b8_t0_q0; end
    logic [61:0] b8_t1;
    (* shreg_extract = "no" *) logic [61:0] b8_t1_q0;
    logic b8_t1_lwe; logic [8:0] b8_t1_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t1_lwd;
    always_ff @(posedge clk) begin b8_t1_lwe <= ld_v && ld_iq >= 9'd168 && ld_iq < 9'd200; b8_t1_lwa <= {ld_slq[2:0], ld_drq, 5'(ld_iq - 9'd168)}; b8_t1_lwd <= ld_d[61:0]; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_tw3_tab1 b8_t1_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[10], b8_cnt[9], b8_cnt[8], b8_cnt[7], b8_cnt[6]}), .we(b8_t1_lwe), .wa(b8_t1_lwa), .wcol(1'b0), .wd(b8_t1_lwd), .q0(b8_t1_q0));
    always_ff @(posedge clk) begin b8_t1 <= b8_t1_q0; end
    logic [61:0] b8_t2;
    (* shreg_extract = "no" *) logic [61:0] b8_t2_q0;
    logic b8_t2_lwe; logic [7:0] b8_t2_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t2_lwd;
    always_ff @(posedge clk) begin b8_t2_lwe <= ld_v && ld_iq >= 9'd200 && ld_iq < 9'd216; b8_t2_lwa <= {ld_slq[2:0], ld_drq, 4'(ld_iq - 9'd200)}; b8_t2_lwd <= ld_d[61:0]; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_tw3_tab2 b8_t2_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t2_lwe), .wa(b8_t2_lwa), .wcol(1'b0), .wd(b8_t2_lwd), .q0(b8_t2_q0));
    always_ff @(posedge clk) begin b8_t2 <= b8_t2_q0; end
    logic [61:0] b8_t3;
    (* shreg_extract = "no" *) logic [61:0] b8_t3_q0;
    logic b8_t3_lwe; logic [9:0] b8_t3_lwa; (* equivalent_register_removal = "no" *) logic [61:0] b8_t3_lwd;
    always_ff @(posedge clk) begin b8_t3_lwe <= ld_v && ld_iq >= 9'd216 && ld_iq < 9'd280; b8_t3_lwa <= {ld_slq[2:0], ld_drq, 6'(ld_iq - 9'd216)}; b8_t3_lwd <= ld_d[61:0]; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_tw3_tab3 b8_t3_i (.clk(clk), .addr({b7_tag[3:1], b7_tag[0], b8_cnt[5], b8_cnt[4], b8_cnt[3], b8_cnt[2], b8_cnt[1], b8_cnt[0]}), .we(b8_t3_lwe), .wa(b8_t3_lwa), .wcol(1'b0), .wd(b8_t3_lwd), .q0(b8_t3_q0));
    always_ff @(posedge clk) begin b8_t3 <= b8_t3_q0; end
    logic [61:0] b8_g0_z;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_zg_ia, b8_g0_zg_ib;
    always_ff @(posedge clk) begin b8_g0_zg_ia <= b8_t0; b8_g0_zg_ib <= b8_t1; end
    logic [44:0] b8_gq4_0_QH_c; assign b8_gq4_0_QH_c = b7_tag[48:4];
    logic [44:0] b8_gq4_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(3)) b8_gq4_0_QH_i (.clk(clk), .din(b8_gq4_0_QH_c), .dout(b8_gq4_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq4_s0_QH;
    always_ff @(posedge clk) b8_gq4_s0_QH <= b8_gq4_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_zg (.clk(clk), .A(b8_g0_zg_ia), .B(b8_g0_zg_ib), .QH(b8_gq4_s0_QH), .P(b8_g0_z));
    logic [61:0] b8_g0_yd;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_g0_yd_i (.clk(clk), .din(b8_t2), .dout(b8_g0_yd));
    logic [61:0] b8_g0_zp1;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_zp1_m_ia, b8_g0_zp1_m_ib;
    always_ff @(posedge clk) begin b8_g0_zp1_m_ia <= b8_g0_z; b8_g0_zp1_m_ib <= b8_g0_z; end
    logic [44:0] b8_gq30_0_QH_c; assign b8_gq30_0_QH_c = b7_tag[48:4];
    logic [44:0] b8_gq30_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(29)) b8_gq30_0_QH_i (.clk(clk), .din(b8_gq30_0_QH_c), .dout(b8_gq30_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq30_s0_QH;
    always_ff @(posedge clk) b8_gq30_s0_QH <= b8_gq30_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_zp1_m (.clk(clk), .A(b8_g0_zp1_m_ia), .B(b8_g0_zp1_m_ib), .QH(b8_gq30_s0_QH), .P(b8_g0_zp1));
    logic [61:0] b8_g0_zp2;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_zp2_m_ia, b8_g0_zp2_m_ib;
    always_ff @(posedge clk) begin b8_g0_zp2_m_ia <= b8_g0_zp1; b8_g0_zp2_m_ib <= b8_g0_zp1; end
    logic [44:0] b8_gq56_0_QH_c; assign b8_gq56_0_QH_c = b7_tag[48:4];
    logic [44:0] b8_gq56_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(55)) b8_gq56_0_QH_i (.clk(clk), .din(b8_gq56_0_QH_c), .dout(b8_gq56_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq56_s0_QH;
    always_ff @(posedge clk) b8_gq56_s0_QH <= b8_gq56_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_zp2_m (.clk(clk), .A(b8_g0_zp2_m_ia), .B(b8_g0_zp2_m_ib), .QH(b8_gq56_s0_QH), .P(b8_g0_zp2));
    logic [61:0] b8_g0_zp3;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_zp3_m_ia, b8_g0_zp3_m_ib;
    always_ff @(posedge clk) begin b8_g0_zp3_m_ia <= b8_g0_zp2; b8_g0_zp3_m_ib <= b8_g0_zp2; end
    logic [44:0] b8_gq82_0_QH_c; assign b8_gq82_0_QH_c = b7_tag[48:4];
    logic [44:0] b8_gq82_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(81)) b8_gq82_0_QH_i (.clk(clk), .din(b8_gq82_0_QH_c), .dout(b8_gq82_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq82_s0_QH;
    always_ff @(posedge clk) b8_gq82_s0_QH <= b8_gq82_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_zp3_m (.clk(clk), .A(b8_g0_zp3_m_ia), .B(b8_g0_zp3_m_ib), .QH(b8_gq82_s0_QH), .P(b8_g0_zp3));
    logic [61:0] b8_g0_w1;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_w1_m_ia, b8_g0_w1_m_ib;
    always_ff @(posedge clk) begin b8_g0_w1_m_ia <= b8_g0_yd; b8_g0_w1_m_ib <= b8_g0_z; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_w1_m (.clk(clk), .A(b8_g0_w1_m_ia), .B(b8_g0_w1_m_ib), .QH(b8_gq30_s0_QH), .P(b8_g0_w1));
    logic [61:0] b8_g0_w2_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_g0_w2_a_i (.clk(clk), .din(b8_g0_yd), .dout(b8_g0_w2_a));
    logic [61:0] b8_g0_w2;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_w2_m_ia, b8_g0_w2_m_ib;
    always_ff @(posedge clk) begin b8_g0_w2_m_ia <= b8_g0_w2_a; b8_g0_w2_m_ib <= b8_g0_zp1; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_w2_m (.clk(clk), .A(b8_g0_w2_m_ia), .B(b8_g0_w2_m_ib), .QH(b8_gq56_s0_QH), .P(b8_g0_w2));
    logic [61:0] b8_g0_w3;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_w3_m_ia, b8_g0_w3_m_ib;
    always_ff @(posedge clk) begin b8_g0_w3_m_ia <= b8_g0_w1; b8_g0_w3_m_ib <= b8_g0_zp1; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_w3_m (.clk(clk), .A(b8_g0_w3_m_ia), .B(b8_g0_w3_m_ib), .QH(b8_gq56_s0_QH), .P(b8_g0_w3));
    logic [61:0] b8_g0_w4_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b8_g0_w4_a_i (.clk(clk), .din(b8_g0_yd), .dout(b8_g0_w4_a));
    logic [61:0] b8_g0_w4;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_w4_m_ia, b8_g0_w4_m_ib;
    always_ff @(posedge clk) begin b8_g0_w4_m_ia <= b8_g0_w4_a; b8_g0_w4_m_ib <= b8_g0_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_w4_m (.clk(clk), .A(b8_g0_w4_m_ia), .B(b8_g0_w4_m_ib), .QH(b8_gq82_s0_QH), .P(b8_g0_w4));
    logic [61:0] b8_g0_w5_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_g0_w5_a_i (.clk(clk), .din(b8_g0_w1), .dout(b8_g0_w5_a));
    logic [61:0] b8_g0_w5;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_w5_m_ia, b8_g0_w5_m_ib;
    always_ff @(posedge clk) begin b8_g0_w5_m_ia <= b8_g0_w5_a; b8_g0_w5_m_ib <= b8_g0_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_w5_m (.clk(clk), .A(b8_g0_w5_m_ia), .B(b8_g0_w5_m_ib), .QH(b8_gq82_s0_QH), .P(b8_g0_w5));
    logic [61:0] b8_g0_w6;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_w6_m_ia, b8_g0_w6_m_ib;
    always_ff @(posedge clk) begin b8_g0_w6_m_ia <= b8_g0_w2; b8_g0_w6_m_ib <= b8_g0_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_w6_m (.clk(clk), .A(b8_g0_w6_m_ia), .B(b8_g0_w6_m_ib), .QH(b8_gq82_s0_QH), .P(b8_g0_w6));
    logic [61:0] b8_g0_w7;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_w7_m_ia, b8_g0_w7_m_ib;
    always_ff @(posedge clk) begin b8_g0_w7_m_ia <= b8_g0_w3; b8_g0_w7_m_ib <= b8_g0_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_w7_m (.clk(clk), .A(b8_g0_w7_m_ia), .B(b8_g0_w7_m_ib), .QH(b8_gq82_s0_QH), .P(b8_g0_w7));
    logic [61:0] b8_g0_w8_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(78)) b8_g0_w8_a_i (.clk(clk), .din(b8_g0_yd), .dout(b8_g0_w8_a));
    logic [61:0] b8_g0_w8;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_w8_m_ia, b8_g0_w8_m_ib;
    always_ff @(posedge clk) begin b8_g0_w8_m_ia <= b8_g0_w8_a; b8_g0_w8_m_ib <= b8_g0_zp3; end
    logic [44:0] b8_gq108_0_QH_c; assign b8_gq108_0_QH_c = b7_tag[48:4];
    logic [44:0] b8_gq108_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(107)) b8_gq108_0_QH_i (.clk(clk), .din(b8_gq108_0_QH_c), .dout(b8_gq108_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq108_s0_QH;
    always_ff @(posedge clk) b8_gq108_s0_QH <= b8_gq108_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_w8_m (.clk(clk), .A(b8_g0_w8_m_ia), .B(b8_g0_w8_m_ib), .QH(b8_gq108_s0_QH), .P(b8_g0_w8));
    logic [61:0] b8_g0_w9_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b8_g0_w9_a_i (.clk(clk), .din(b8_g0_w1), .dout(b8_g0_w9_a));
    logic [61:0] b8_g0_w9;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_w9_m_ia, b8_g0_w9_m_ib;
    always_ff @(posedge clk) begin b8_g0_w9_m_ia <= b8_g0_w9_a; b8_g0_w9_m_ib <= b8_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_w9_m (.clk(clk), .A(b8_g0_w9_m_ia), .B(b8_g0_w9_m_ib), .QH(b8_gq108_s0_QH), .P(b8_g0_w9));
    logic [61:0] b8_g0_w10_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_g0_w10_a_i (.clk(clk), .din(b8_g0_w2), .dout(b8_g0_w10_a));
    logic [61:0] b8_g0_w10;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_w10_m_ia, b8_g0_w10_m_ib;
    always_ff @(posedge clk) begin b8_g0_w10_m_ia <= b8_g0_w10_a; b8_g0_w10_m_ib <= b8_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_w10_m (.clk(clk), .A(b8_g0_w10_m_ia), .B(b8_g0_w10_m_ib), .QH(b8_gq108_s0_QH), .P(b8_g0_w10));
    logic [61:0] b8_g0_w11_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_g0_w11_a_i (.clk(clk), .din(b8_g0_w3), .dout(b8_g0_w11_a));
    logic [61:0] b8_g0_w11;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_w11_m_ia, b8_g0_w11_m_ib;
    always_ff @(posedge clk) begin b8_g0_w11_m_ia <= b8_g0_w11_a; b8_g0_w11_m_ib <= b8_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_w11_m (.clk(clk), .A(b8_g0_w11_m_ia), .B(b8_g0_w11_m_ib), .QH(b8_gq108_s0_QH), .P(b8_g0_w11));
    logic [61:0] b8_g0_w12;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_w12_m_ia, b8_g0_w12_m_ib;
    always_ff @(posedge clk) begin b8_g0_w12_m_ia <= b8_g0_w4; b8_g0_w12_m_ib <= b8_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_w12_m (.clk(clk), .A(b8_g0_w12_m_ia), .B(b8_g0_w12_m_ib), .QH(b8_gq108_s0_QH), .P(b8_g0_w12));
    logic [61:0] b8_g0_w13;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_w13_m_ia, b8_g0_w13_m_ib;
    always_ff @(posedge clk) begin b8_g0_w13_m_ia <= b8_g0_w5; b8_g0_w13_m_ib <= b8_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_w13_m (.clk(clk), .A(b8_g0_w13_m_ia), .B(b8_g0_w13_m_ib), .QH(b8_gq108_s0_QH), .P(b8_g0_w13));
    logic [61:0] b8_g0_w14;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_w14_m_ia, b8_g0_w14_m_ib;
    always_ff @(posedge clk) begin b8_g0_w14_m_ia <= b8_g0_w6; b8_g0_w14_m_ib <= b8_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_w14_m (.clk(clk), .A(b8_g0_w14_m_ia), .B(b8_g0_w14_m_ib), .QH(b8_gq108_s0_QH), .P(b8_g0_w14));
    logic [61:0] b8_g0_w15;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g0_w15_m_ia, b8_g0_w15_m_ib;
    always_ff @(posedge clk) begin b8_g0_w15_m_ia <= b8_g0_w7; b8_g0_w15_m_ib <= b8_g0_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g0_w15_m (.clk(clk), .A(b8_g0_w15_m_ia), .B(b8_g0_w15_m_ib), .QH(b8_gq108_s0_QH), .P(b8_g0_w15));
    logic [61:0] b8_l0_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l0_a_i (.clk(clk), .din(b7_g0_o[0]), .dout(b8_l0_a));
    logic [44:0] b8_mq133_0_QH_c; assign b8_mq133_0_QH_c = b7_tag[48:4];
    logic [44:0] b8_mq133_0_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(132)) b8_mq133_0_QH_i (.clk(clk), .din(b8_mq133_0_QH_c), .dout(b8_mq133_0_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_mq133_s0_QH;
    always_ff @(posedge clk) b8_mq133_s0_QH <= b8_mq133_0_QH;
    logic [61:0] b8_l0_p;
    logic [61:0] b8_l0_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(104)) b8_l0_w_i (.clk(clk), .din(b8_g0_yd), .dout(b8_l0_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l0_mul (.clk(clk), .A(b8_l0_a), .B(b8_l0_w), .QH(b8_mq133_s0_QH), .P(b8_l0_p));
    logic [61:0] b8_l1_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l1_a_i (.clk(clk), .din(b7_g0_o[1]), .dout(b8_l1_a));
    logic [61:0] b8_l1_p;
    logic [61:0] b8_l1_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(78)) b8_l1_w_i (.clk(clk), .din(b8_g0_w1), .dout(b8_l1_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l1_mul (.clk(clk), .A(b8_l1_a), .B(b8_l1_w), .QH(b8_mq133_s0_QH), .P(b8_l1_p));
    logic [61:0] b8_l2_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l2_a_i (.clk(clk), .din(b7_g0_o[2]), .dout(b8_l2_a));
    logic [61:0] b8_l2_p;
    logic [61:0] b8_l2_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b8_l2_w_i (.clk(clk), .din(b8_g0_w2), .dout(b8_l2_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l2_mul (.clk(clk), .A(b8_l2_a), .B(b8_l2_w), .QH(b8_mq133_s0_QH), .P(b8_l2_p));
    logic [61:0] b8_l3_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l3_a_i (.clk(clk), .din(b7_g0_o[3]), .dout(b8_l3_a));
    logic [61:0] b8_l3_p;
    logic [61:0] b8_l3_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b8_l3_w_i (.clk(clk), .din(b8_g0_w3), .dout(b8_l3_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l3_mul (.clk(clk), .A(b8_l3_a), .B(b8_l3_w), .QH(b8_mq133_s0_QH), .P(b8_l3_p));
    logic [61:0] b8_l4_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l4_a_i (.clk(clk), .din(b7_g0_o[4]), .dout(b8_l4_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_mq133_s1_QH;
    always_ff @(posedge clk) b8_mq133_s1_QH <= b8_mq133_0_QH;
    logic [61:0] b8_l4_p;
    logic [61:0] b8_l4_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_l4_w_i (.clk(clk), .din(b8_g0_w4), .dout(b8_l4_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l4_mul (.clk(clk), .A(b8_l4_a), .B(b8_l4_w), .QH(b8_mq133_s1_QH), .P(b8_l4_p));
    logic [61:0] b8_l5_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l5_a_i (.clk(clk), .din(b7_g0_o[5]), .dout(b8_l5_a));
    logic [61:0] b8_l5_p;
    logic [61:0] b8_l5_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_l5_w_i (.clk(clk), .din(b8_g0_w5), .dout(b8_l5_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l5_mul (.clk(clk), .A(b8_l5_a), .B(b8_l5_w), .QH(b8_mq133_s1_QH), .P(b8_l5_p));
    logic [61:0] b8_l6_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l6_a_i (.clk(clk), .din(b7_g0_o[6]), .dout(b8_l6_a));
    logic [61:0] b8_l6_p;
    logic [61:0] b8_l6_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_l6_w_i (.clk(clk), .din(b8_g0_w6), .dout(b8_l6_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l6_mul (.clk(clk), .A(b8_l6_a), .B(b8_l6_w), .QH(b8_mq133_s1_QH), .P(b8_l6_p));
    logic [61:0] b8_l7_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l7_a_i (.clk(clk), .din(b7_g0_o[7]), .dout(b8_l7_a));
    logic [61:0] b8_l7_p;
    logic [61:0] b8_l7_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_l7_w_i (.clk(clk), .din(b8_g0_w7), .dout(b8_l7_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l7_mul (.clk(clk), .A(b8_l7_a), .B(b8_l7_w), .QH(b8_mq133_s1_QH), .P(b8_l7_p));
    logic [61:0] b8_l8_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l8_a_i (.clk(clk), .din(b7_g0_o[8]), .dout(b8_l8_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_mq133_s2_QH;
    always_ff @(posedge clk) b8_mq133_s2_QH <= b8_mq133_0_QH;
    logic [61:0] b8_l8_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l8_mul (.clk(clk), .A(b8_l8_a), .B(b8_g0_w8), .QH(b8_mq133_s2_QH), .P(b8_l8_p));
    logic [61:0] b8_l9_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l9_a_i (.clk(clk), .din(b7_g0_o[9]), .dout(b8_l9_a));
    logic [61:0] b8_l9_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l9_mul (.clk(clk), .A(b8_l9_a), .B(b8_g0_w9), .QH(b8_mq133_s2_QH), .P(b8_l9_p));
    logic [61:0] b8_l10_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l10_a_i (.clk(clk), .din(b7_g0_o[10]), .dout(b8_l10_a));
    logic [61:0] b8_l10_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l10_mul (.clk(clk), .A(b8_l10_a), .B(b8_g0_w10), .QH(b8_mq133_s2_QH), .P(b8_l10_p));
    logic [61:0] b8_l11_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l11_a_i (.clk(clk), .din(b7_g0_o[11]), .dout(b8_l11_a));
    logic [61:0] b8_l11_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l11_mul (.clk(clk), .A(b8_l11_a), .B(b8_g0_w11), .QH(b8_mq133_s2_QH), .P(b8_l11_p));
    logic [61:0] b8_l12_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l12_a_i (.clk(clk), .din(b7_g0_o[12]), .dout(b8_l12_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_mq133_s3_QH;
    always_ff @(posedge clk) b8_mq133_s3_QH <= b8_mq133_0_QH;
    logic [61:0] b8_l12_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l12_mul (.clk(clk), .A(b8_l12_a), .B(b8_g0_w12), .QH(b8_mq133_s3_QH), .P(b8_l12_p));
    logic [61:0] b8_l13_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l13_a_i (.clk(clk), .din(b7_g0_o[13]), .dout(b8_l13_a));
    logic [61:0] b8_l13_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l13_mul (.clk(clk), .A(b8_l13_a), .B(b8_g0_w13), .QH(b8_mq133_s3_QH), .P(b8_l13_p));
    logic [61:0] b8_l14_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l14_a_i (.clk(clk), .din(b7_g0_o[14]), .dout(b8_l14_a));
    logic [61:0] b8_l14_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l14_mul (.clk(clk), .A(b8_l14_a), .B(b8_g0_w14), .QH(b8_mq133_s3_QH), .P(b8_l14_p));
    logic [61:0] b8_l15_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l15_a_i (.clk(clk), .din(b7_g0_o[15]), .dout(b8_l15_a));
    logic [61:0] b8_l15_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l15_mul (.clk(clk), .A(b8_l15_a), .B(b8_g0_w15), .QH(b8_mq133_s3_QH), .P(b8_l15_p));
    logic [61:0] b8_g1_z;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_zg_ia, b8_g1_zg_ib;
    always_ff @(posedge clk) begin b8_g1_zg_ia <= b8_t3; b8_g1_zg_ib <= b8_t1; end
    logic [44:0] b8_gq4_1_QH_c; assign b8_gq4_1_QH_c = b7_tag[48:4];
    logic [44:0] b8_gq4_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(3)) b8_gq4_1_QH_i (.clk(clk), .din(b8_gq4_1_QH_c), .dout(b8_gq4_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq4_s4_QH;
    always_ff @(posedge clk) b8_gq4_s4_QH <= b8_gq4_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_zg (.clk(clk), .A(b8_g1_zg_ia), .B(b8_g1_zg_ib), .QH(b8_gq4_s4_QH), .P(b8_g1_z));
    logic [61:0] b8_g1_yd;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_g1_yd_i (.clk(clk), .din(b8_t2), .dout(b8_g1_yd));
    logic [61:0] b8_g1_zp1;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_zp1_m_ia, b8_g1_zp1_m_ib;
    always_ff @(posedge clk) begin b8_g1_zp1_m_ia <= b8_g1_z; b8_g1_zp1_m_ib <= b8_g1_z; end
    logic [44:0] b8_gq30_1_QH_c; assign b8_gq30_1_QH_c = b7_tag[48:4];
    logic [44:0] b8_gq30_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(29)) b8_gq30_1_QH_i (.clk(clk), .din(b8_gq30_1_QH_c), .dout(b8_gq30_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq30_s4_QH;
    always_ff @(posedge clk) b8_gq30_s4_QH <= b8_gq30_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_zp1_m (.clk(clk), .A(b8_g1_zp1_m_ia), .B(b8_g1_zp1_m_ib), .QH(b8_gq30_s4_QH), .P(b8_g1_zp1));
    logic [61:0] b8_g1_zp2;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_zp2_m_ia, b8_g1_zp2_m_ib;
    always_ff @(posedge clk) begin b8_g1_zp2_m_ia <= b8_g1_zp1; b8_g1_zp2_m_ib <= b8_g1_zp1; end
    logic [44:0] b8_gq56_1_QH_c; assign b8_gq56_1_QH_c = b7_tag[48:4];
    logic [44:0] b8_gq56_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(55)) b8_gq56_1_QH_i (.clk(clk), .din(b8_gq56_1_QH_c), .dout(b8_gq56_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq56_s4_QH;
    always_ff @(posedge clk) b8_gq56_s4_QH <= b8_gq56_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_zp2_m (.clk(clk), .A(b8_g1_zp2_m_ia), .B(b8_g1_zp2_m_ib), .QH(b8_gq56_s4_QH), .P(b8_g1_zp2));
    logic [61:0] b8_g1_zp3;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_zp3_m_ia, b8_g1_zp3_m_ib;
    always_ff @(posedge clk) begin b8_g1_zp3_m_ia <= b8_g1_zp2; b8_g1_zp3_m_ib <= b8_g1_zp2; end
    logic [44:0] b8_gq82_1_QH_c; assign b8_gq82_1_QH_c = b7_tag[48:4];
    logic [44:0] b8_gq82_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(81)) b8_gq82_1_QH_i (.clk(clk), .din(b8_gq82_1_QH_c), .dout(b8_gq82_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq82_s4_QH;
    always_ff @(posedge clk) b8_gq82_s4_QH <= b8_gq82_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_zp3_m (.clk(clk), .A(b8_g1_zp3_m_ia), .B(b8_g1_zp3_m_ib), .QH(b8_gq82_s4_QH), .P(b8_g1_zp3));
    logic [61:0] b8_g1_w1;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_w1_m_ia, b8_g1_w1_m_ib;
    always_ff @(posedge clk) begin b8_g1_w1_m_ia <= b8_g1_yd; b8_g1_w1_m_ib <= b8_g1_z; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_w1_m (.clk(clk), .A(b8_g1_w1_m_ia), .B(b8_g1_w1_m_ib), .QH(b8_gq30_s4_QH), .P(b8_g1_w1));
    logic [61:0] b8_g1_w2_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_g1_w2_a_i (.clk(clk), .din(b8_g1_yd), .dout(b8_g1_w2_a));
    logic [61:0] b8_g1_w2;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_w2_m_ia, b8_g1_w2_m_ib;
    always_ff @(posedge clk) begin b8_g1_w2_m_ia <= b8_g1_w2_a; b8_g1_w2_m_ib <= b8_g1_zp1; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_w2_m (.clk(clk), .A(b8_g1_w2_m_ia), .B(b8_g1_w2_m_ib), .QH(b8_gq56_s4_QH), .P(b8_g1_w2));
    logic [61:0] b8_g1_w3;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_w3_m_ia, b8_g1_w3_m_ib;
    always_ff @(posedge clk) begin b8_g1_w3_m_ia <= b8_g1_w1; b8_g1_w3_m_ib <= b8_g1_zp1; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_w3_m (.clk(clk), .A(b8_g1_w3_m_ia), .B(b8_g1_w3_m_ib), .QH(b8_gq56_s4_QH), .P(b8_g1_w3));
    logic [61:0] b8_g1_w4_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b8_g1_w4_a_i (.clk(clk), .din(b8_g1_yd), .dout(b8_g1_w4_a));
    logic [61:0] b8_g1_w4;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_w4_m_ia, b8_g1_w4_m_ib;
    always_ff @(posedge clk) begin b8_g1_w4_m_ia <= b8_g1_w4_a; b8_g1_w4_m_ib <= b8_g1_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_w4_m (.clk(clk), .A(b8_g1_w4_m_ia), .B(b8_g1_w4_m_ib), .QH(b8_gq82_s4_QH), .P(b8_g1_w4));
    logic [61:0] b8_g1_w5_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_g1_w5_a_i (.clk(clk), .din(b8_g1_w1), .dout(b8_g1_w5_a));
    logic [61:0] b8_g1_w5;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_w5_m_ia, b8_g1_w5_m_ib;
    always_ff @(posedge clk) begin b8_g1_w5_m_ia <= b8_g1_w5_a; b8_g1_w5_m_ib <= b8_g1_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_w5_m (.clk(clk), .A(b8_g1_w5_m_ia), .B(b8_g1_w5_m_ib), .QH(b8_gq82_s4_QH), .P(b8_g1_w5));
    logic [61:0] b8_g1_w6;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_w6_m_ia, b8_g1_w6_m_ib;
    always_ff @(posedge clk) begin b8_g1_w6_m_ia <= b8_g1_w2; b8_g1_w6_m_ib <= b8_g1_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_w6_m (.clk(clk), .A(b8_g1_w6_m_ia), .B(b8_g1_w6_m_ib), .QH(b8_gq82_s4_QH), .P(b8_g1_w6));
    logic [61:0] b8_g1_w7;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_w7_m_ia, b8_g1_w7_m_ib;
    always_ff @(posedge clk) begin b8_g1_w7_m_ia <= b8_g1_w3; b8_g1_w7_m_ib <= b8_g1_zp2; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_w7_m (.clk(clk), .A(b8_g1_w7_m_ia), .B(b8_g1_w7_m_ib), .QH(b8_gq82_s4_QH), .P(b8_g1_w7));
    logic [61:0] b8_g1_w8_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(78)) b8_g1_w8_a_i (.clk(clk), .din(b8_g1_yd), .dout(b8_g1_w8_a));
    logic [61:0] b8_g1_w8;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_w8_m_ia, b8_g1_w8_m_ib;
    always_ff @(posedge clk) begin b8_g1_w8_m_ia <= b8_g1_w8_a; b8_g1_w8_m_ib <= b8_g1_zp3; end
    logic [44:0] b8_gq108_1_QH_c; assign b8_gq108_1_QH_c = b7_tag[48:4];
    logic [44:0] b8_gq108_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(107)) b8_gq108_1_QH_i (.clk(clk), .din(b8_gq108_1_QH_c), .dout(b8_gq108_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_gq108_s4_QH;
    always_ff @(posedge clk) b8_gq108_s4_QH <= b8_gq108_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_w8_m (.clk(clk), .A(b8_g1_w8_m_ia), .B(b8_g1_w8_m_ib), .QH(b8_gq108_s4_QH), .P(b8_g1_w8));
    logic [61:0] b8_g1_w9_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b8_g1_w9_a_i (.clk(clk), .din(b8_g1_w1), .dout(b8_g1_w9_a));
    logic [61:0] b8_g1_w9;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_w9_m_ia, b8_g1_w9_m_ib;
    always_ff @(posedge clk) begin b8_g1_w9_m_ia <= b8_g1_w9_a; b8_g1_w9_m_ib <= b8_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_w9_m (.clk(clk), .A(b8_g1_w9_m_ia), .B(b8_g1_w9_m_ib), .QH(b8_gq108_s4_QH), .P(b8_g1_w9));
    logic [61:0] b8_g1_w10_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_g1_w10_a_i (.clk(clk), .din(b8_g1_w2), .dout(b8_g1_w10_a));
    logic [61:0] b8_g1_w10;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_w10_m_ia, b8_g1_w10_m_ib;
    always_ff @(posedge clk) begin b8_g1_w10_m_ia <= b8_g1_w10_a; b8_g1_w10_m_ib <= b8_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_w10_m (.clk(clk), .A(b8_g1_w10_m_ia), .B(b8_g1_w10_m_ib), .QH(b8_gq108_s4_QH), .P(b8_g1_w10));
    logic [61:0] b8_g1_w11_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_g1_w11_a_i (.clk(clk), .din(b8_g1_w3), .dout(b8_g1_w11_a));
    logic [61:0] b8_g1_w11;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_w11_m_ia, b8_g1_w11_m_ib;
    always_ff @(posedge clk) begin b8_g1_w11_m_ia <= b8_g1_w11_a; b8_g1_w11_m_ib <= b8_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_w11_m (.clk(clk), .A(b8_g1_w11_m_ia), .B(b8_g1_w11_m_ib), .QH(b8_gq108_s4_QH), .P(b8_g1_w11));
    logic [61:0] b8_g1_w12;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_w12_m_ia, b8_g1_w12_m_ib;
    always_ff @(posedge clk) begin b8_g1_w12_m_ia <= b8_g1_w4; b8_g1_w12_m_ib <= b8_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_w12_m (.clk(clk), .A(b8_g1_w12_m_ia), .B(b8_g1_w12_m_ib), .QH(b8_gq108_s4_QH), .P(b8_g1_w12));
    logic [61:0] b8_g1_w13;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_w13_m_ia, b8_g1_w13_m_ib;
    always_ff @(posedge clk) begin b8_g1_w13_m_ia <= b8_g1_w5; b8_g1_w13_m_ib <= b8_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_w13_m (.clk(clk), .A(b8_g1_w13_m_ia), .B(b8_g1_w13_m_ib), .QH(b8_gq108_s4_QH), .P(b8_g1_w13));
    logic [61:0] b8_g1_w14;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_w14_m_ia, b8_g1_w14_m_ib;
    always_ff @(posedge clk) begin b8_g1_w14_m_ia <= b8_g1_w6; b8_g1_w14_m_ib <= b8_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_w14_m (.clk(clk), .A(b8_g1_w14_m_ia), .B(b8_g1_w14_m_ib), .QH(b8_gq108_s4_QH), .P(b8_g1_w14));
    logic [61:0] b8_g1_w15;
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [61:0] b8_g1_w15_m_ia, b8_g1_w15_m_ib;
    always_ff @(posedge clk) begin b8_g1_w15_m_ia <= b8_g1_w7; b8_g1_w15_m_ib <= b8_g1_zp3; end
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twgen b8_g1_w15_m (.clk(clk), .A(b8_g1_w15_m_ia), .B(b8_g1_w15_m_ib), .QH(b8_gq108_s4_QH), .P(b8_g1_w15));
    logic [61:0] b8_l16_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l16_a_i (.clk(clk), .din(b7_g1_o[0]), .dout(b8_l16_a));
    logic [44:0] b8_mq133_1_QH_c; assign b8_mq133_1_QH_c = b7_tag[48:4];
    logic [44:0] b8_mq133_1_QH;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(45), .D(132)) b8_mq133_1_QH_i (.clk(clk), .din(b8_mq133_1_QH_c), .dout(b8_mq133_1_QH));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_mq133_s4_QH;
    always_ff @(posedge clk) b8_mq133_s4_QH <= b8_mq133_1_QH;
    logic [61:0] b8_l16_p;
    logic [61:0] b8_l16_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(104)) b8_l16_w_i (.clk(clk), .din(b8_g1_yd), .dout(b8_l16_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l16_mul (.clk(clk), .A(b8_l16_a), .B(b8_l16_w), .QH(b8_mq133_s4_QH), .P(b8_l16_p));
    logic [61:0] b8_l17_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l17_a_i (.clk(clk), .din(b7_g1_o[1]), .dout(b8_l17_a));
    logic [61:0] b8_l17_p;
    logic [61:0] b8_l17_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(78)) b8_l17_w_i (.clk(clk), .din(b8_g1_w1), .dout(b8_l17_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l17_mul (.clk(clk), .A(b8_l17_a), .B(b8_l17_w), .QH(b8_mq133_s4_QH), .P(b8_l17_p));
    logic [61:0] b8_l18_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l18_a_i (.clk(clk), .din(b7_g1_o[2]), .dout(b8_l18_a));
    logic [61:0] b8_l18_p;
    logic [61:0] b8_l18_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b8_l18_w_i (.clk(clk), .din(b8_g1_w2), .dout(b8_l18_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l18_mul (.clk(clk), .A(b8_l18_a), .B(b8_l18_w), .QH(b8_mq133_s4_QH), .P(b8_l18_p));
    logic [61:0] b8_l19_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l19_a_i (.clk(clk), .din(b7_g1_o[3]), .dout(b8_l19_a));
    logic [61:0] b8_l19_p;
    logic [61:0] b8_l19_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(52)) b8_l19_w_i (.clk(clk), .din(b8_g1_w3), .dout(b8_l19_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l19_mul (.clk(clk), .A(b8_l19_a), .B(b8_l19_w), .QH(b8_mq133_s4_QH), .P(b8_l19_p));
    logic [61:0] b8_l20_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l20_a_i (.clk(clk), .din(b7_g1_o[4]), .dout(b8_l20_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_mq133_s5_QH;
    always_ff @(posedge clk) b8_mq133_s5_QH <= b8_mq133_1_QH;
    logic [61:0] b8_l20_p;
    logic [61:0] b8_l20_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_l20_w_i (.clk(clk), .din(b8_g1_w4), .dout(b8_l20_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l20_mul (.clk(clk), .A(b8_l20_a), .B(b8_l20_w), .QH(b8_mq133_s5_QH), .P(b8_l20_p));
    logic [61:0] b8_l21_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l21_a_i (.clk(clk), .din(b7_g1_o[5]), .dout(b8_l21_a));
    logic [61:0] b8_l21_p;
    logic [61:0] b8_l21_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_l21_w_i (.clk(clk), .din(b8_g1_w5), .dout(b8_l21_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l21_mul (.clk(clk), .A(b8_l21_a), .B(b8_l21_w), .QH(b8_mq133_s5_QH), .P(b8_l21_p));
    logic [61:0] b8_l22_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l22_a_i (.clk(clk), .din(b7_g1_o[6]), .dout(b8_l22_a));
    logic [61:0] b8_l22_p;
    logic [61:0] b8_l22_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_l22_w_i (.clk(clk), .din(b8_g1_w6), .dout(b8_l22_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l22_mul (.clk(clk), .A(b8_l22_a), .B(b8_l22_w), .QH(b8_mq133_s5_QH), .P(b8_l22_p));
    logic [61:0] b8_l23_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l23_a_i (.clk(clk), .din(b7_g1_o[7]), .dout(b8_l23_a));
    logic [61:0] b8_l23_p;
    logic [61:0] b8_l23_w;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(26)) b8_l23_w_i (.clk(clk), .din(b8_g1_w7), .dout(b8_l23_w));
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l23_mul (.clk(clk), .A(b8_l23_a), .B(b8_l23_w), .QH(b8_mq133_s5_QH), .P(b8_l23_p));
    logic [61:0] b8_l24_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l24_a_i (.clk(clk), .din(b7_g1_o[8]), .dout(b8_l24_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_mq133_s6_QH;
    always_ff @(posedge clk) b8_mq133_s6_QH <= b8_mq133_1_QH;
    logic [61:0] b8_l24_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l24_mul (.clk(clk), .A(b8_l24_a), .B(b8_g1_w8), .QH(b8_mq133_s6_QH), .P(b8_l24_p));
    logic [61:0] b8_l25_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l25_a_i (.clk(clk), .din(b7_g1_o[9]), .dout(b8_l25_a));
    logic [61:0] b8_l25_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l25_mul (.clk(clk), .A(b8_l25_a), .B(b8_g1_w9), .QH(b8_mq133_s6_QH), .P(b8_l25_p));
    logic [61:0] b8_l26_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l26_a_i (.clk(clk), .din(b7_g1_o[10]), .dout(b8_l26_a));
    logic [61:0] b8_l26_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l26_mul (.clk(clk), .A(b8_l26_a), .B(b8_g1_w10), .QH(b8_mq133_s6_QH), .P(b8_l26_p));
    logic [61:0] b8_l27_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l27_a_i (.clk(clk), .din(b7_g1_o[11]), .dout(b8_l27_a));
    logic [61:0] b8_l27_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l27_mul (.clk(clk), .A(b8_l27_a), .B(b8_g1_w11), .QH(b8_mq133_s6_QH), .P(b8_l27_p));
    logic [61:0] b8_l28_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l28_a_i (.clk(clk), .din(b7_g1_o[12]), .dout(b8_l28_a));
    (* equivalent_register_removal = "no", shreg_extract = "no" *) logic [44:0] b8_mq133_s7_QH;
    always_ff @(posedge clk) b8_mq133_s7_QH <= b8_mq133_1_QH;
    logic [61:0] b8_l28_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l28_mul (.clk(clk), .A(b8_l28_a), .B(b8_g1_w12), .QH(b8_mq133_s7_QH), .P(b8_l28_p));
    logic [61:0] b8_l29_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l29_a_i (.clk(clk), .din(b7_g1_o[13]), .dout(b8_l29_a));
    logic [61:0] b8_l29_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l29_mul (.clk(clk), .A(b8_l29_a), .B(b8_g1_w13), .QH(b8_mq133_s7_QH), .P(b8_l29_p));
    logic [61:0] b8_l30_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l30_a_i (.clk(clk), .din(b7_g1_o[14]), .dout(b8_l30_a));
    logic [61:0] b8_l30_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l30_mul (.clk(clk), .A(b8_l30_a), .B(b8_g1_w14), .QH(b8_mq133_s7_QH), .P(b8_l30_p));
    logic [61:0] b8_l31_a;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(62), .D(133)) b8_l31_a_i (.clk(clk), .din(b7_g1_o[15]), .dout(b8_l31_a));
    logic [61:0] b8_l31_p;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_twmul b8_l31_mul (.clk(clk), .A(b8_l31_a), .B(b8_g1_w15), .QH(b8_mq133_s7_QH), .P(b8_l31_p));
    logic [156:0] b8_v_sr;
    always_ff @(posedge clk) b8_v_sr <= rst ? '0 : {b8_v_sr[155:0], b7_g0_v};
    logic b8_v; assign b8_v = b8_v_sr[156];
    logic [110:0] b8_tag;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(111), .D(157)) b8_tag_i (.clk(clk), .din(b7_tag), .dout(b8_tag));
    // block 9: pass 3, 2 x ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p3 (16-point), latency 114
    logic [61:0] b9_c0_y0, b9_c0_y1, b9_c0_y2, b9_c0_y3, b9_c0_y4, b9_c0_y5, b9_c0_y6, b9_c0_y7, b9_c0_y8, b9_c0_y9, b9_c0_y10, b9_c0_y11, b9_c0_y12, b9_c0_y13, b9_c0_y14, b9_c0_y15;
    logic b9_c0_v; logic [2:0] b9_c0_mi; logic b9_c0_di;
    logic b9_c0_lr, b9_c0_lw; (* equivalent_register_removal = "no" *) logic [61:0] b9_c0_ld;
    always_ff @(posedge clk) begin b9_c0_lr <= ld_r; b9_c0_lw <= ld_v && ld_iq >= 9'd280 && ld_iq < 9'd303; b9_c0_ld <= ld_d[61:0]; end
    logic [2:0] b9_c0_ls; always_ff @(posedge clk) b9_c0_ls <= ld_sl;
    logic b9_c0_ldr; always_ff @(posedge clk) b9_c0_ldr <= ld_dr;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p3 b9_c0 (.clk(clk), .rst(rst), .in_valid(b8_v), .out_valid(b9_c0_v), .MIDX(b8_tag[3:1]), .midx_out(b9_c0_mi), .mq_QH(b8_tag[48:4]), .mq_QHALF(b8_tag[110:49]), .DIR(b8_tag[0]), .dir_out(b9_c0_di), .tw_rst(b9_c0_lr), .tw_wen(b9_c0_lw), .tw_wdata(b9_c0_ld), .tw_slot(b9_c0_ls), .tw_dir(b9_c0_ldr), .x_in_0(b8_l0_p), .x_in_1(b8_l1_p), .x_in_2(b8_l2_p), .x_in_3(b8_l3_p), .x_in_4(b8_l4_p), .x_in_5(b8_l5_p), .x_in_6(b8_l6_p), .x_in_7(b8_l7_p), .x_in_8(b8_l8_p), .x_in_9(b8_l9_p), .x_in_10(b8_l10_p), .x_in_11(b8_l11_p), .x_in_12(b8_l12_p), .x_in_13(b8_l13_p), .x_in_14(b8_l14_p), .x_in_15(b8_l15_p), .y_out_0(b9_c0_y0), .y_out_1(b9_c0_y1), .y_out_2(b9_c0_y2), .y_out_3(b9_c0_y3), .y_out_4(b9_c0_y4), .y_out_5(b9_c0_y5), .y_out_6(b9_c0_y6), .y_out_7(b9_c0_y7), .y_out_8(b9_c0_y8), .y_out_9(b9_c0_y9), .y_out_10(b9_c0_y10), .y_out_11(b9_c0_y11), .y_out_12(b9_c0_y12), .y_out_13(b9_c0_y13), .y_out_14(b9_c0_y14), .y_out_15(b9_c0_y15));
    logic [61:0] b9_c1_y0, b9_c1_y1, b9_c1_y2, b9_c1_y3, b9_c1_y4, b9_c1_y5, b9_c1_y6, b9_c1_y7, b9_c1_y8, b9_c1_y9, b9_c1_y10, b9_c1_y11, b9_c1_y12, b9_c1_y13, b9_c1_y14, b9_c1_y15;
    logic b9_c1_v; logic [2:0] b9_c1_mi; logic b9_c1_di;
    logic b9_c1_lr, b9_c1_lw; (* equivalent_register_removal = "no" *) logic [61:0] b9_c1_ld;
    always_ff @(posedge clk) begin b9_c1_lr <= ld_r; b9_c1_lw <= ld_v && ld_iq >= 9'd280 && ld_iq < 9'd303; b9_c1_ld <= ld_d[61:0]; end
    logic [2:0] b9_c1_ls; always_ff @(posedge clk) b9_c1_ls <= ld_sl;
    logic b9_c1_ldr; always_ff @(posedge clk) b9_c1_ldr <= ld_dr;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p3 b9_c1 (.clk(clk), .rst(rst), .in_valid(b8_v), .out_valid(b9_c1_v), .MIDX(b8_tag[3:1]), .midx_out(b9_c1_mi), .mq_QH(b8_tag[48:4]), .mq_QHALF(b8_tag[110:49]), .DIR(b8_tag[0]), .dir_out(b9_c1_di), .tw_rst(b9_c1_lr), .tw_wen(b9_c1_lw), .tw_wdata(b9_c1_ld), .tw_slot(b9_c1_ls), .tw_dir(b9_c1_ldr), .x_in_0(b8_l16_p), .x_in_1(b8_l17_p), .x_in_2(b8_l18_p), .x_in_3(b8_l19_p), .x_in_4(b8_l20_p), .x_in_5(b8_l21_p), .x_in_6(b8_l22_p), .x_in_7(b8_l23_p), .x_in_8(b8_l24_p), .x_in_9(b8_l25_p), .x_in_10(b8_l26_p), .x_in_11(b8_l27_p), .x_in_12(b8_l28_p), .x_in_13(b8_l29_p), .x_in_14(b8_l30_p), .x_in_15(b8_l31_p), .y_out_0(b9_c1_y0), .y_out_1(b9_c1_y1), .y_out_2(b9_c1_y2), .y_out_3(b9_c1_y3), .y_out_4(b9_c1_y4), .y_out_5(b9_c1_y5), .y_out_6(b9_c1_y6), .y_out_7(b9_c1_y7), .y_out_8(b9_c1_y8), .y_out_9(b9_c1_y9), .y_out_10(b9_c1_y10), .y_out_11(b9_c1_y11), .y_out_12(b9_c1_y12), .y_out_13(b9_c1_y13), .y_out_14(b9_c1_y14), .y_out_15(b9_c1_y15));
    logic [106:0] b9_cq0; assign b9_cq0 = b8_tag[110:4];
    logic [106:0] b9_cq;
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_dly_c #(.W(107), .D(114)) b9_cq_i (.clk(clk), .din(b9_cq0), .dout(b9_cq));
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
    assign y_out_16 = b9_c1_y0;
    assign y_out_17 = b9_c1_y1;
    assign y_out_18 = b9_c1_y2;
    assign y_out_19 = b9_c1_y3;
    assign y_out_20 = b9_c1_y4;
    assign y_out_21 = b9_c1_y5;
    assign y_out_22 = b9_c1_y6;
    assign y_out_23 = b9_c1_y7;
    assign y_out_24 = b9_c1_y8;
    assign y_out_25 = b9_c1_y9;
    assign y_out_26 = b9_c1_y10;
    assign y_out_27 = b9_c1_y11;
    assign y_out_28 = b9_c1_y12;
    assign y_out_29 = b9_c1_y13;
    assign y_out_30 = b9_c1_y14;
    assign y_out_31 = b9_c1_y15;
endmodule
