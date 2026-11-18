`timescale 1ns / 1ps
// MS_N12_q32_P64_tpm: multi-step NTT, N=4096, sizes [64, 64], 64 lanes, frame 64 cycles, latency 246, fixed q
module MS_N12_q32_P64_tpm (
    input  logic clk,
    input  logic rst,
    input  logic in_valid,
    input  logic DIR,
    input  logic ld_rst,
    input  logic ld_wen,
    input  logic [31:0] ld_wdata,
    input  logic [15:0] QH,
    input  logic [31:0] QHALF,
    input  logic [31:0] x_in_0,
    input  logic [31:0] x_in_1,
    input  logic [31:0] x_in_2,
    input  logic [31:0] x_in_3,
    input  logic [31:0] x_in_4,
    input  logic [31:0] x_in_5,
    input  logic [31:0] x_in_6,
    input  logic [31:0] x_in_7,
    input  logic [31:0] x_in_8,
    input  logic [31:0] x_in_9,
    input  logic [31:0] x_in_10,
    input  logic [31:0] x_in_11,
    input  logic [31:0] x_in_12,
    input  logic [31:0] x_in_13,
    input  logic [31:0] x_in_14,
    input  logic [31:0] x_in_15,
    input  logic [31:0] x_in_16,
    input  logic [31:0] x_in_17,
    input  logic [31:0] x_in_18,
    input  logic [31:0] x_in_19,
    input  logic [31:0] x_in_20,
    input  logic [31:0] x_in_21,
    input  logic [31:0] x_in_22,
    input  logic [31:0] x_in_23,
    input  logic [31:0] x_in_24,
    input  logic [31:0] x_in_25,
    input  logic [31:0] x_in_26,
    input  logic [31:0] x_in_27,
    input  logic [31:0] x_in_28,
    input  logic [31:0] x_in_29,
    input  logic [31:0] x_in_30,
    input  logic [31:0] x_in_31,
    input  logic [31:0] x_in_32,
    input  logic [31:0] x_in_33,
    input  logic [31:0] x_in_34,
    input  logic [31:0] x_in_35,
    input  logic [31:0] x_in_36,
    input  logic [31:0] x_in_37,
    input  logic [31:0] x_in_38,
    input  logic [31:0] x_in_39,
    input  logic [31:0] x_in_40,
    input  logic [31:0] x_in_41,
    input  logic [31:0] x_in_42,
    input  logic [31:0] x_in_43,
    input  logic [31:0] x_in_44,
    input  logic [31:0] x_in_45,
    input  logic [31:0] x_in_46,
    input  logic [31:0] x_in_47,
    input  logic [31:0] x_in_48,
    input  logic [31:0] x_in_49,
    input  logic [31:0] x_in_50,
    input  logic [31:0] x_in_51,
    input  logic [31:0] x_in_52,
    input  logic [31:0] x_in_53,
    input  logic [31:0] x_in_54,
    input  logic [31:0] x_in_55,
    input  logic [31:0] x_in_56,
    input  logic [31:0] x_in_57,
    input  logic [31:0] x_in_58,
    input  logic [31:0] x_in_59,
    input  logic [31:0] x_in_60,
    input  logic [31:0] x_in_61,
    input  logic [31:0] x_in_62,
    input  logic [31:0] x_in_63,
    output logic out_valid,
    output logic dir_out,
    output logic [31:0] y_out_0,
    output logic [31:0] y_out_1,
    output logic [31:0] y_out_2,
    output logic [31:0] y_out_3,
    output logic [31:0] y_out_4,
    output logic [31:0] y_out_5,
    output logic [31:0] y_out_6,
    output logic [31:0] y_out_7,
    output logic [31:0] y_out_8,
    output logic [31:0] y_out_9,
    output logic [31:0] y_out_10,
    output logic [31:0] y_out_11,
    output logic [31:0] y_out_12,
    output logic [31:0] y_out_13,
    output logic [31:0] y_out_14,
    output logic [31:0] y_out_15,
    output logic [31:0] y_out_16,
    output logic [31:0] y_out_17,
    output logic [31:0] y_out_18,
    output logic [31:0] y_out_19,
    output logic [31:0] y_out_20,
    output logic [31:0] y_out_21,
    output logic [31:0] y_out_22,
    output logic [31:0] y_out_23,
    output logic [31:0] y_out_24,
    output logic [31:0] y_out_25,
    output logic [31:0] y_out_26,
    output logic [31:0] y_out_27,
    output logic [31:0] y_out_28,
    output logic [31:0] y_out_29,
    output logic [31:0] y_out_30,
    output logic [31:0] y_out_31,
    output logic [31:0] y_out_32,
    output logic [31:0] y_out_33,
    output logic [31:0] y_out_34,
    output logic [31:0] y_out_35,
    output logic [31:0] y_out_36,
    output logic [31:0] y_out_37,
    output logic [31:0] y_out_38,
    output logic [31:0] y_out_39,
    output logic [31:0] y_out_40,
    output logic [31:0] y_out_41,
    output logic [31:0] y_out_42,
    output logic [31:0] y_out_43,
    output logic [31:0] y_out_44,
    output logic [31:0] y_out_45,
    output logic [31:0] y_out_46,
    output logic [31:0] y_out_47,
    output logic [31:0] y_out_48,
    output logic [31:0] y_out_49,
    output logic [31:0] y_out_50,
    output logic [31:0] y_out_51,
    output logic [31:0] y_out_52,
    output logic [31:0] y_out_53,
    output logic [31:0] y_out_54,
    output logic [31:0] y_out_55,
    output logic [31:0] y_out_56,
    output logic [31:0] y_out_57,
    output logic [31:0] y_out_58,
    output logic [31:0] y_out_59,
    output logic [31:0] y_out_60,
    output logic [31:0] y_out_61,
    output logic [31:0] y_out_62,
    output logic [31:0] y_out_63
    );
    // load port: one word per ld_wen after ld_rst, 16382 words: the sub-NTT images, then the tables
    (* max_fanout = 32 *) logic ld_rst_p, ld_wen_p; (* max_fanout = 32 *) logic [31:0] ld_wdata_p;
    always_ff @(posedge clk) begin ld_rst_p <= ld_rst; ld_wen_p <= ld_wen; ld_wdata_p <= ld_wdata; end
    (* max_fanout = 32 *) logic [13:0] ld_i;
    always_ff @(posedge clk) ld_i <= ld_rst_p ? '0 : (ld_wen_p ? ld_i + 1'b1 : ld_i);
    (* max_fanout = 32 *) logic [31:0] ld_d; always_ff @(posedge clk) ld_d <= ld_wdata_p;
    (* max_fanout = 32 *) logic ld_v, ld_r; always_ff @(posedge clk) begin ld_v <= ld_wen_p; ld_r <= ld_rst_p; end
    logic [13:0] ld_iq; always_ff @(posedge clk) ld_iq <= ld_i;
    logic [31:0] d0_0; assign d0_0 = x_in_0;
    logic [31:0] d0_1; assign d0_1 = x_in_1;
    logic [31:0] d0_2; assign d0_2 = x_in_2;
    logic [31:0] d0_3; assign d0_3 = x_in_3;
    logic [31:0] d0_4; assign d0_4 = x_in_4;
    logic [31:0] d0_5; assign d0_5 = x_in_5;
    logic [31:0] d0_6; assign d0_6 = x_in_6;
    logic [31:0] d0_7; assign d0_7 = x_in_7;
    logic [31:0] d0_8; assign d0_8 = x_in_8;
    logic [31:0] d0_9; assign d0_9 = x_in_9;
    logic [31:0] d0_10; assign d0_10 = x_in_10;
    logic [31:0] d0_11; assign d0_11 = x_in_11;
    logic [31:0] d0_12; assign d0_12 = x_in_12;
    logic [31:0] d0_13; assign d0_13 = x_in_13;
    logic [31:0] d0_14; assign d0_14 = x_in_14;
    logic [31:0] d0_15; assign d0_15 = x_in_15;
    logic [31:0] d0_16; assign d0_16 = x_in_16;
    logic [31:0] d0_17; assign d0_17 = x_in_17;
    logic [31:0] d0_18; assign d0_18 = x_in_18;
    logic [31:0] d0_19; assign d0_19 = x_in_19;
    logic [31:0] d0_20; assign d0_20 = x_in_20;
    logic [31:0] d0_21; assign d0_21 = x_in_21;
    logic [31:0] d0_22; assign d0_22 = x_in_22;
    logic [31:0] d0_23; assign d0_23 = x_in_23;
    logic [31:0] d0_24; assign d0_24 = x_in_24;
    logic [31:0] d0_25; assign d0_25 = x_in_25;
    logic [31:0] d0_26; assign d0_26 = x_in_26;
    logic [31:0] d0_27; assign d0_27 = x_in_27;
    logic [31:0] d0_28; assign d0_28 = x_in_28;
    logic [31:0] d0_29; assign d0_29 = x_in_29;
    logic [31:0] d0_30; assign d0_30 = x_in_30;
    logic [31:0] d0_31; assign d0_31 = x_in_31;
    logic [31:0] d0_32; assign d0_32 = x_in_32;
    logic [31:0] d0_33; assign d0_33 = x_in_33;
    logic [31:0] d0_34; assign d0_34 = x_in_34;
    logic [31:0] d0_35; assign d0_35 = x_in_35;
    logic [31:0] d0_36; assign d0_36 = x_in_36;
    logic [31:0] d0_37; assign d0_37 = x_in_37;
    logic [31:0] d0_38; assign d0_38 = x_in_38;
    logic [31:0] d0_39; assign d0_39 = x_in_39;
    logic [31:0] d0_40; assign d0_40 = x_in_40;
    logic [31:0] d0_41; assign d0_41 = x_in_41;
    logic [31:0] d0_42; assign d0_42 = x_in_42;
    logic [31:0] d0_43; assign d0_43 = x_in_43;
    logic [31:0] d0_44; assign d0_44 = x_in_44;
    logic [31:0] d0_45; assign d0_45 = x_in_45;
    logic [31:0] d0_46; assign d0_46 = x_in_46;
    logic [31:0] d0_47; assign d0_47 = x_in_47;
    logic [31:0] d0_48; assign d0_48 = x_in_48;
    logic [31:0] d0_49; assign d0_49 = x_in_49;
    logic [31:0] d0_50; assign d0_50 = x_in_50;
    logic [31:0] d0_51; assign d0_51 = x_in_51;
    logic [31:0] d0_52; assign d0_52 = x_in_52;
    logic [31:0] d0_53; assign d0_53 = x_in_53;
    logic [31:0] d0_54; assign d0_54 = x_in_54;
    logic [31:0] d0_55; assign d0_55 = x_in_55;
    logic [31:0] d0_56; assign d0_56 = x_in_56;
    logic [31:0] d0_57; assign d0_57 = x_in_57;
    logic [31:0] d0_58; assign d0_58 = x_in_58;
    logic [31:0] d0_59; assign d0_59 = x_in_59;
    logic [31:0] d0_60; assign d0_60 = x_in_60;
    logic [31:0] d0_61; assign d0_61 = x_in_61;
    logic [31:0] d0_62; assign d0_62 = x_in_62;
    logic [31:0] d0_63; assign d0_63 = x_in_63;
    logic v0; assign v0 = in_valid;
    logic [0:0] g0; assign g0 = DIR;
    // block 0: pass 0, 1 x MS_N12_q32_P64_tpm_p0 (64-point), latency 81
    logic [31:0] b0_c0_y0, b0_c0_y1, b0_c0_y2, b0_c0_y3, b0_c0_y4, b0_c0_y5, b0_c0_y6, b0_c0_y7, b0_c0_y8, b0_c0_y9, b0_c0_y10, b0_c0_y11, b0_c0_y12, b0_c0_y13, b0_c0_y14, b0_c0_y15, b0_c0_y16, b0_c0_y17, b0_c0_y18, b0_c0_y19, b0_c0_y20, b0_c0_y21, b0_c0_y22, b0_c0_y23, b0_c0_y24, b0_c0_y25, b0_c0_y26, b0_c0_y27, b0_c0_y28, b0_c0_y29, b0_c0_y30, b0_c0_y31, b0_c0_y32, b0_c0_y33, b0_c0_y34, b0_c0_y35, b0_c0_y36, b0_c0_y37, b0_c0_y38, b0_c0_y39, b0_c0_y40, b0_c0_y41, b0_c0_y42, b0_c0_y43, b0_c0_y44, b0_c0_y45, b0_c0_y46, b0_c0_y47, b0_c0_y48, b0_c0_y49, b0_c0_y50, b0_c0_y51, b0_c0_y52, b0_c0_y53, b0_c0_y54, b0_c0_y55, b0_c0_y56, b0_c0_y57, b0_c0_y58, b0_c0_y59, b0_c0_y60, b0_c0_y61, b0_c0_y62, b0_c0_y63;
    logic b0_c0_v; logic b0_c0_di;
    logic b0_c0_lr, b0_c0_lw; (* equivalent_register_removal = "no" *) logic [31:0] b0_c0_ld;
    always_ff @(posedge clk) begin b0_c0_lr <= ld_r; b0_c0_lw <= ld_v && ld_iq >= 14'd0 && ld_iq < 14'd126; b0_c0_ld <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_p0 b0_c0 (.clk(clk), .rst(rst), .in_valid(v0), .out_valid(b0_c0_v), .DIR(g0[0]), .tw_rst(b0_c0_lr), .tw_wen(b0_c0_lw), .tw_wdata(b0_c0_ld), .QH(QH[15:0]), .QHALF(QHALF[31:0]), .x_in_0(d0_0), .x_in_1(d0_1), .x_in_2(d0_2), .x_in_3(d0_3), .x_in_4(d0_4), .x_in_5(d0_5), .x_in_6(d0_6), .x_in_7(d0_7), .x_in_8(d0_8), .x_in_9(d0_9), .x_in_10(d0_10), .x_in_11(d0_11), .x_in_12(d0_12), .x_in_13(d0_13), .x_in_14(d0_14), .x_in_15(d0_15), .x_in_16(d0_16), .x_in_17(d0_17), .x_in_18(d0_18), .x_in_19(d0_19), .x_in_20(d0_20), .x_in_21(d0_21), .x_in_22(d0_22), .x_in_23(d0_23), .x_in_24(d0_24), .x_in_25(d0_25), .x_in_26(d0_26), .x_in_27(d0_27), .x_in_28(d0_28), .x_in_29(d0_29), .x_in_30(d0_30), .x_in_31(d0_31), .x_in_32(d0_32), .x_in_33(d0_33), .x_in_34(d0_34), .x_in_35(d0_35), .x_in_36(d0_36), .x_in_37(d0_37), .x_in_38(d0_38), .x_in_39(d0_39), .x_in_40(d0_40), .x_in_41(d0_41), .x_in_42(d0_42), .x_in_43(d0_43), .x_in_44(d0_44), .x_in_45(d0_45), .x_in_46(d0_46), .x_in_47(d0_47), .x_in_48(d0_48), .x_in_49(d0_49), .x_in_50(d0_50), .x_in_51(d0_51), .x_in_52(d0_52), .x_in_53(d0_53), .x_in_54(d0_54), .x_in_55(d0_55), .x_in_56(d0_56), .x_in_57(d0_57), .x_in_58(d0_58), .x_in_59(d0_59), .x_in_60(d0_60), .x_in_61(d0_61), .x_in_62(d0_62), .x_in_63(d0_63), .y_out_0(b0_c0_y0), .y_out_1(b0_c0_y1), .y_out_2(b0_c0_y2), .y_out_3(b0_c0_y3), .y_out_4(b0_c0_y4), .y_out_5(b0_c0_y5), .y_out_6(b0_c0_y6), .y_out_7(b0_c0_y7), .y_out_8(b0_c0_y8), .y_out_9(b0_c0_y9), .y_out_10(b0_c0_y10), .y_out_11(b0_c0_y11), .y_out_12(b0_c0_y12), .y_out_13(b0_c0_y13), .y_out_14(b0_c0_y14), .y_out_15(b0_c0_y15), .y_out_16(b0_c0_y16), .y_out_17(b0_c0_y17), .y_out_18(b0_c0_y18), .y_out_19(b0_c0_y19), .y_out_20(b0_c0_y20), .y_out_21(b0_c0_y21), .y_out_22(b0_c0_y22), .y_out_23(b0_c0_y23), .y_out_24(b0_c0_y24), .y_out_25(b0_c0_y25), .y_out_26(b0_c0_y26), .y_out_27(b0_c0_y27), .y_out_28(b0_c0_y28), .y_out_29(b0_c0_y29), .y_out_30(b0_c0_y30), .y_out_31(b0_c0_y31), .y_out_32(b0_c0_y32), .y_out_33(b0_c0_y33), .y_out_34(b0_c0_y34), .y_out_35(b0_c0_y35), .y_out_36(b0_c0_y36), .y_out_37(b0_c0_y37), .y_out_38(b0_c0_y38), .y_out_39(b0_c0_y39), .y_out_40(b0_c0_y40), .y_out_41(b0_c0_y41), .y_out_42(b0_c0_y42), .y_out_43(b0_c0_y43), .y_out_44(b0_c0_y44), .y_out_45(b0_c0_y45), .y_out_46(b0_c0_y46), .y_out_47(b0_c0_y47), .y_out_48(b0_c0_y48), .y_out_49(b0_c0_y49), .y_out_50(b0_c0_y50), .y_out_51(b0_c0_y51), .y_out_52(b0_c0_y52), .y_out_53(b0_c0_y53), .y_out_54(b0_c0_y54), .y_out_55(b0_c0_y55), .y_out_56(b0_c0_y56), .y_out_57(b0_c0_y57), .y_out_58(b0_c0_y58), .y_out_59(b0_c0_y59), .y_out_60(b0_c0_y60), .y_out_61(b0_c0_y61), .y_out_62(b0_c0_y62), .y_out_63(b0_c0_y63));
    logic [0:0] b0_tag;
    MS_N12_q32_P64_tpm_dly_c #(.W(1), .D(81)) b0_tag_i (.clk(clk), .din(g0), .dout(b0_tag));
    // block 1: lane-time transpose, lane bits [0, 1, 2, 3, 4, 5] <-> cycle bits [0,6), 1 x S=64, latency 71
    logic [31:0] b1_g0_i [0:63]; logic [31:0] b1_g0_o [0:63]; logic b1_g0_v;
    assign b1_g0_i[0] = b0_c0_y0;
    assign b1_g0_i[1] = b0_c0_y1;
    assign b1_g0_i[2] = b0_c0_y2;
    assign b1_g0_i[3] = b0_c0_y3;
    assign b1_g0_i[4] = b0_c0_y4;
    assign b1_g0_i[5] = b0_c0_y5;
    assign b1_g0_i[6] = b0_c0_y6;
    assign b1_g0_i[7] = b0_c0_y7;
    assign b1_g0_i[8] = b0_c0_y8;
    assign b1_g0_i[9] = b0_c0_y9;
    assign b1_g0_i[10] = b0_c0_y10;
    assign b1_g0_i[11] = b0_c0_y11;
    assign b1_g0_i[12] = b0_c0_y12;
    assign b1_g0_i[13] = b0_c0_y13;
    assign b1_g0_i[14] = b0_c0_y14;
    assign b1_g0_i[15] = b0_c0_y15;
    assign b1_g0_i[16] = b0_c0_y16;
    assign b1_g0_i[17] = b0_c0_y17;
    assign b1_g0_i[18] = b0_c0_y18;
    assign b1_g0_i[19] = b0_c0_y19;
    assign b1_g0_i[20] = b0_c0_y20;
    assign b1_g0_i[21] = b0_c0_y21;
    assign b1_g0_i[22] = b0_c0_y22;
    assign b1_g0_i[23] = b0_c0_y23;
    assign b1_g0_i[24] = b0_c0_y24;
    assign b1_g0_i[25] = b0_c0_y25;
    assign b1_g0_i[26] = b0_c0_y26;
    assign b1_g0_i[27] = b0_c0_y27;
    assign b1_g0_i[28] = b0_c0_y28;
    assign b1_g0_i[29] = b0_c0_y29;
    assign b1_g0_i[30] = b0_c0_y30;
    assign b1_g0_i[31] = b0_c0_y31;
    assign b1_g0_i[32] = b0_c0_y32;
    assign b1_g0_i[33] = b0_c0_y33;
    assign b1_g0_i[34] = b0_c0_y34;
    assign b1_g0_i[35] = b0_c0_y35;
    assign b1_g0_i[36] = b0_c0_y36;
    assign b1_g0_i[37] = b0_c0_y37;
    assign b1_g0_i[38] = b0_c0_y38;
    assign b1_g0_i[39] = b0_c0_y39;
    assign b1_g0_i[40] = b0_c0_y40;
    assign b1_g0_i[41] = b0_c0_y41;
    assign b1_g0_i[42] = b0_c0_y42;
    assign b1_g0_i[43] = b0_c0_y43;
    assign b1_g0_i[44] = b0_c0_y44;
    assign b1_g0_i[45] = b0_c0_y45;
    assign b1_g0_i[46] = b0_c0_y46;
    assign b1_g0_i[47] = b0_c0_y47;
    assign b1_g0_i[48] = b0_c0_y48;
    assign b1_g0_i[49] = b0_c0_y49;
    assign b1_g0_i[50] = b0_c0_y50;
    assign b1_g0_i[51] = b0_c0_y51;
    assign b1_g0_i[52] = b0_c0_y52;
    assign b1_g0_i[53] = b0_c0_y53;
    assign b1_g0_i[54] = b0_c0_y54;
    assign b1_g0_i[55] = b0_c0_y55;
    assign b1_g0_i[56] = b0_c0_y56;
    assign b1_g0_i[57] = b0_c0_y57;
    assign b1_g0_i[58] = b0_c0_y58;
    assign b1_g0_i[59] = b0_c0_y59;
    assign b1_g0_i[60] = b0_c0_y60;
    assign b1_g0_i[61] = b0_c0_y61;
    assign b1_g0_i[62] = b0_c0_y62;
    assign b1_g0_i[63] = b0_c0_y63;
    lt_bmb_transpose #(.S(64), .LO(0), .ELEMENT_WIDTH(32), .REG_FLAGS(32'h7), .RAM_STYLE("distributed")) b1_g0 (.clk(clk), .rst(rst), .data_valid(b0_c0_v), .data_in(b1_g0_i), .data_out_valid(b1_g0_v), .data_out(b1_g0_o));
    logic [0:0] b1_tag;
    MS_N12_q32_P64_tpm_dly_c #(.W(1), .D(71)) b1_tag_i (.clk(clk), .din(b0_tag), .dout(b1_tag));
    logic [5:0] b2_cnt;
    always_ff @(posedge clk) b2_cnt <= rst ? '0 : (b1_g0_v ? b2_cnt + 1'b1 : b2_cnt);
    logic [31:0] b2_w0;
    logic b2_w0_lwe; logic [6:0] b2_w0_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w0_lwd;
    always_ff @(posedge clk) begin b2_w0_lwe <= ld_v && ld_iq >= 14'd126 && ld_iq < 14'd254; b2_w0_lwa <= 7'(ld_iq - 14'd126); b2_w0_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab0 b2_w0_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w0_lwe), .wa(b2_w0_lwa), .wcol(1'b0), .wd(b2_w0_lwd), .q0(b2_w0));
    logic [31:0] b2_w1;
    logic b2_w1_lwe; logic [6:0] b2_w1_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w1_lwd;
    always_ff @(posedge clk) begin b2_w1_lwe <= ld_v && ld_iq >= 14'd254 && ld_iq < 14'd382; b2_w1_lwa <= 7'(ld_iq - 14'd254); b2_w1_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab1 b2_w1_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w1_lwe), .wa(b2_w1_lwa), .wcol(1'b0), .wd(b2_w1_lwd), .q0(b2_w1));
    logic [31:0] b2_w2;
    logic b2_w2_lwe; logic [6:0] b2_w2_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w2_lwd;
    always_ff @(posedge clk) begin b2_w2_lwe <= ld_v && ld_iq >= 14'd382 && ld_iq < 14'd510; b2_w2_lwa <= 7'(ld_iq - 14'd382); b2_w2_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab2 b2_w2_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w2_lwe), .wa(b2_w2_lwa), .wcol(1'b0), .wd(b2_w2_lwd), .q0(b2_w2));
    logic [31:0] b2_w3;
    logic b2_w3_lwe; logic [6:0] b2_w3_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w3_lwd;
    always_ff @(posedge clk) begin b2_w3_lwe <= ld_v && ld_iq >= 14'd510 && ld_iq < 14'd638; b2_w3_lwa <= 7'(ld_iq - 14'd510); b2_w3_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab3 b2_w3_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w3_lwe), .wa(b2_w3_lwa), .wcol(1'b0), .wd(b2_w3_lwd), .q0(b2_w3));
    logic [31:0] b2_w4;
    logic b2_w4_lwe; logic [6:0] b2_w4_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w4_lwd;
    always_ff @(posedge clk) begin b2_w4_lwe <= ld_v && ld_iq >= 14'd638 && ld_iq < 14'd766; b2_w4_lwa <= 7'(ld_iq - 14'd638); b2_w4_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab4 b2_w4_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w4_lwe), .wa(b2_w4_lwa), .wcol(1'b0), .wd(b2_w4_lwd), .q0(b2_w4));
    logic [31:0] b2_w5;
    logic b2_w5_lwe; logic [6:0] b2_w5_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w5_lwd;
    always_ff @(posedge clk) begin b2_w5_lwe <= ld_v && ld_iq >= 14'd766 && ld_iq < 14'd894; b2_w5_lwa <= 7'(ld_iq - 14'd766); b2_w5_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab5 b2_w5_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w5_lwe), .wa(b2_w5_lwa), .wcol(1'b0), .wd(b2_w5_lwd), .q0(b2_w5));
    logic [31:0] b2_w6;
    logic b2_w6_lwe; logic [6:0] b2_w6_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w6_lwd;
    always_ff @(posedge clk) begin b2_w6_lwe <= ld_v && ld_iq >= 14'd894 && ld_iq < 14'd1022; b2_w6_lwa <= 7'(ld_iq - 14'd894); b2_w6_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab6 b2_w6_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w6_lwe), .wa(b2_w6_lwa), .wcol(1'b0), .wd(b2_w6_lwd), .q0(b2_w6));
    logic [31:0] b2_w7;
    logic b2_w7_lwe; logic [6:0] b2_w7_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w7_lwd;
    always_ff @(posedge clk) begin b2_w7_lwe <= ld_v && ld_iq >= 14'd1022 && ld_iq < 14'd1150; b2_w7_lwa <= 7'(ld_iq - 14'd1022); b2_w7_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab7 b2_w7_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w7_lwe), .wa(b2_w7_lwa), .wcol(1'b0), .wd(b2_w7_lwd), .q0(b2_w7));
    logic [31:0] b2_w8;
    logic b2_w8_lwe; logic [6:0] b2_w8_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w8_lwd;
    always_ff @(posedge clk) begin b2_w8_lwe <= ld_v && ld_iq >= 14'd1150 && ld_iq < 14'd1278; b2_w8_lwa <= 7'(ld_iq - 14'd1150); b2_w8_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab8 b2_w8_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w8_lwe), .wa(b2_w8_lwa), .wcol(1'b0), .wd(b2_w8_lwd), .q0(b2_w8));
    logic [31:0] b2_w9;
    logic b2_w9_lwe; logic [6:0] b2_w9_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w9_lwd;
    always_ff @(posedge clk) begin b2_w9_lwe <= ld_v && ld_iq >= 14'd1278 && ld_iq < 14'd1406; b2_w9_lwa <= 7'(ld_iq - 14'd1278); b2_w9_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab9 b2_w9_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w9_lwe), .wa(b2_w9_lwa), .wcol(1'b0), .wd(b2_w9_lwd), .q0(b2_w9));
    logic [31:0] b2_w10;
    logic b2_w10_lwe; logic [6:0] b2_w10_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w10_lwd;
    always_ff @(posedge clk) begin b2_w10_lwe <= ld_v && ld_iq >= 14'd1406 && ld_iq < 14'd1534; b2_w10_lwa <= 7'(ld_iq - 14'd1406); b2_w10_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab10 b2_w10_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w10_lwe), .wa(b2_w10_lwa), .wcol(1'b0), .wd(b2_w10_lwd), .q0(b2_w10));
    logic [31:0] b2_w11;
    logic b2_w11_lwe; logic [6:0] b2_w11_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w11_lwd;
    always_ff @(posedge clk) begin b2_w11_lwe <= ld_v && ld_iq >= 14'd1534 && ld_iq < 14'd1662; b2_w11_lwa <= 7'(ld_iq - 14'd1534); b2_w11_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab11 b2_w11_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w11_lwe), .wa(b2_w11_lwa), .wcol(1'b0), .wd(b2_w11_lwd), .q0(b2_w11));
    logic [31:0] b2_w12;
    logic b2_w12_lwe; logic [6:0] b2_w12_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w12_lwd;
    always_ff @(posedge clk) begin b2_w12_lwe <= ld_v && ld_iq >= 14'd1662 && ld_iq < 14'd1790; b2_w12_lwa <= 7'(ld_iq - 14'd1662); b2_w12_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab12 b2_w12_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w12_lwe), .wa(b2_w12_lwa), .wcol(1'b0), .wd(b2_w12_lwd), .q0(b2_w12));
    logic [31:0] b2_w13;
    logic b2_w13_lwe; logic [6:0] b2_w13_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w13_lwd;
    always_ff @(posedge clk) begin b2_w13_lwe <= ld_v && ld_iq >= 14'd1790 && ld_iq < 14'd1918; b2_w13_lwa <= 7'(ld_iq - 14'd1790); b2_w13_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab13 b2_w13_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w13_lwe), .wa(b2_w13_lwa), .wcol(1'b0), .wd(b2_w13_lwd), .q0(b2_w13));
    logic [31:0] b2_w14;
    logic b2_w14_lwe; logic [6:0] b2_w14_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w14_lwd;
    always_ff @(posedge clk) begin b2_w14_lwe <= ld_v && ld_iq >= 14'd1918 && ld_iq < 14'd2046; b2_w14_lwa <= 7'(ld_iq - 14'd1918); b2_w14_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab14 b2_w14_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w14_lwe), .wa(b2_w14_lwa), .wcol(1'b0), .wd(b2_w14_lwd), .q0(b2_w14));
    logic [31:0] b2_w15;
    logic b2_w15_lwe; logic [6:0] b2_w15_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w15_lwd;
    always_ff @(posedge clk) begin b2_w15_lwe <= ld_v && ld_iq >= 14'd2046 && ld_iq < 14'd2174; b2_w15_lwa <= 7'(ld_iq - 14'd2046); b2_w15_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab15 b2_w15_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w15_lwe), .wa(b2_w15_lwa), .wcol(1'b0), .wd(b2_w15_lwd), .q0(b2_w15));
    logic [31:0] b2_w16;
    logic b2_w16_lwe; logic [6:0] b2_w16_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w16_lwd;
    always_ff @(posedge clk) begin b2_w16_lwe <= ld_v && ld_iq >= 14'd2174 && ld_iq < 14'd2302; b2_w16_lwa <= 7'(ld_iq - 14'd2174); b2_w16_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab16 b2_w16_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w16_lwe), .wa(b2_w16_lwa), .wcol(1'b0), .wd(b2_w16_lwd), .q0(b2_w16));
    logic [31:0] b2_w17;
    logic b2_w17_lwe; logic [6:0] b2_w17_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w17_lwd;
    always_ff @(posedge clk) begin b2_w17_lwe <= ld_v && ld_iq >= 14'd2302 && ld_iq < 14'd2430; b2_w17_lwa <= 7'(ld_iq - 14'd2302); b2_w17_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab17 b2_w17_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w17_lwe), .wa(b2_w17_lwa), .wcol(1'b0), .wd(b2_w17_lwd), .q0(b2_w17));
    logic [31:0] b2_w18;
    logic b2_w18_lwe; logic [6:0] b2_w18_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w18_lwd;
    always_ff @(posedge clk) begin b2_w18_lwe <= ld_v && ld_iq >= 14'd2430 && ld_iq < 14'd2558; b2_w18_lwa <= 7'(ld_iq - 14'd2430); b2_w18_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab18 b2_w18_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w18_lwe), .wa(b2_w18_lwa), .wcol(1'b0), .wd(b2_w18_lwd), .q0(b2_w18));
    logic [31:0] b2_w19;
    logic b2_w19_lwe; logic [6:0] b2_w19_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w19_lwd;
    always_ff @(posedge clk) begin b2_w19_lwe <= ld_v && ld_iq >= 14'd2558 && ld_iq < 14'd2686; b2_w19_lwa <= 7'(ld_iq - 14'd2558); b2_w19_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab19 b2_w19_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w19_lwe), .wa(b2_w19_lwa), .wcol(1'b0), .wd(b2_w19_lwd), .q0(b2_w19));
    logic [31:0] b2_w20;
    logic b2_w20_lwe; logic [6:0] b2_w20_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w20_lwd;
    always_ff @(posedge clk) begin b2_w20_lwe <= ld_v && ld_iq >= 14'd2686 && ld_iq < 14'd2814; b2_w20_lwa <= 7'(ld_iq - 14'd2686); b2_w20_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab20 b2_w20_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w20_lwe), .wa(b2_w20_lwa), .wcol(1'b0), .wd(b2_w20_lwd), .q0(b2_w20));
    logic [31:0] b2_w21;
    logic b2_w21_lwe; logic [6:0] b2_w21_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w21_lwd;
    always_ff @(posedge clk) begin b2_w21_lwe <= ld_v && ld_iq >= 14'd2814 && ld_iq < 14'd2942; b2_w21_lwa <= 7'(ld_iq - 14'd2814); b2_w21_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab21 b2_w21_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w21_lwe), .wa(b2_w21_lwa), .wcol(1'b0), .wd(b2_w21_lwd), .q0(b2_w21));
    logic [31:0] b2_w22;
    logic b2_w22_lwe; logic [6:0] b2_w22_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w22_lwd;
    always_ff @(posedge clk) begin b2_w22_lwe <= ld_v && ld_iq >= 14'd2942 && ld_iq < 14'd3070; b2_w22_lwa <= 7'(ld_iq - 14'd2942); b2_w22_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab22 b2_w22_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w22_lwe), .wa(b2_w22_lwa), .wcol(1'b0), .wd(b2_w22_lwd), .q0(b2_w22));
    logic [31:0] b2_w23;
    logic b2_w23_lwe; logic [6:0] b2_w23_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w23_lwd;
    always_ff @(posedge clk) begin b2_w23_lwe <= ld_v && ld_iq >= 14'd3070 && ld_iq < 14'd3198; b2_w23_lwa <= 7'(ld_iq - 14'd3070); b2_w23_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab23 b2_w23_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w23_lwe), .wa(b2_w23_lwa), .wcol(1'b0), .wd(b2_w23_lwd), .q0(b2_w23));
    logic [31:0] b2_w24;
    logic b2_w24_lwe; logic [6:0] b2_w24_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w24_lwd;
    always_ff @(posedge clk) begin b2_w24_lwe <= ld_v && ld_iq >= 14'd3198 && ld_iq < 14'd3326; b2_w24_lwa <= 7'(ld_iq - 14'd3198); b2_w24_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab24 b2_w24_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w24_lwe), .wa(b2_w24_lwa), .wcol(1'b0), .wd(b2_w24_lwd), .q0(b2_w24));
    logic [31:0] b2_w25;
    logic b2_w25_lwe; logic [6:0] b2_w25_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w25_lwd;
    always_ff @(posedge clk) begin b2_w25_lwe <= ld_v && ld_iq >= 14'd3326 && ld_iq < 14'd3454; b2_w25_lwa <= 7'(ld_iq - 14'd3326); b2_w25_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab25 b2_w25_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w25_lwe), .wa(b2_w25_lwa), .wcol(1'b0), .wd(b2_w25_lwd), .q0(b2_w25));
    logic [31:0] b2_w26;
    logic b2_w26_lwe; logic [6:0] b2_w26_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w26_lwd;
    always_ff @(posedge clk) begin b2_w26_lwe <= ld_v && ld_iq >= 14'd3454 && ld_iq < 14'd3582; b2_w26_lwa <= 7'(ld_iq - 14'd3454); b2_w26_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab26 b2_w26_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w26_lwe), .wa(b2_w26_lwa), .wcol(1'b0), .wd(b2_w26_lwd), .q0(b2_w26));
    logic [31:0] b2_w27;
    logic b2_w27_lwe; logic [6:0] b2_w27_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w27_lwd;
    always_ff @(posedge clk) begin b2_w27_lwe <= ld_v && ld_iq >= 14'd3582 && ld_iq < 14'd3710; b2_w27_lwa <= 7'(ld_iq - 14'd3582); b2_w27_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab27 b2_w27_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w27_lwe), .wa(b2_w27_lwa), .wcol(1'b0), .wd(b2_w27_lwd), .q0(b2_w27));
    logic [31:0] b2_w28;
    logic b2_w28_lwe; logic [6:0] b2_w28_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w28_lwd;
    always_ff @(posedge clk) begin b2_w28_lwe <= ld_v && ld_iq >= 14'd3710 && ld_iq < 14'd3838; b2_w28_lwa <= 7'(ld_iq - 14'd3710); b2_w28_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab28 b2_w28_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w28_lwe), .wa(b2_w28_lwa), .wcol(1'b0), .wd(b2_w28_lwd), .q0(b2_w28));
    logic [31:0] b2_w29;
    logic b2_w29_lwe; logic [6:0] b2_w29_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w29_lwd;
    always_ff @(posedge clk) begin b2_w29_lwe <= ld_v && ld_iq >= 14'd3838 && ld_iq < 14'd3966; b2_w29_lwa <= 7'(ld_iq - 14'd3838); b2_w29_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab29 b2_w29_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w29_lwe), .wa(b2_w29_lwa), .wcol(1'b0), .wd(b2_w29_lwd), .q0(b2_w29));
    logic [31:0] b2_w30;
    logic b2_w30_lwe; logic [6:0] b2_w30_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w30_lwd;
    always_ff @(posedge clk) begin b2_w30_lwe <= ld_v && ld_iq >= 14'd3966 && ld_iq < 14'd4094; b2_w30_lwa <= 7'(ld_iq - 14'd3966); b2_w30_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab30 b2_w30_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w30_lwe), .wa(b2_w30_lwa), .wcol(1'b0), .wd(b2_w30_lwd), .q0(b2_w30));
    logic [31:0] b2_w31;
    logic b2_w31_lwe; logic [6:0] b2_w31_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w31_lwd;
    always_ff @(posedge clk) begin b2_w31_lwe <= ld_v && ld_iq >= 14'd4094 && ld_iq < 14'd4222; b2_w31_lwa <= 7'(ld_iq - 14'd4094); b2_w31_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab31 b2_w31_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w31_lwe), .wa(b2_w31_lwa), .wcol(1'b0), .wd(b2_w31_lwd), .q0(b2_w31));
    logic [31:0] b2_w32;
    logic b2_w32_lwe; logic [6:0] b2_w32_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w32_lwd;
    always_ff @(posedge clk) begin b2_w32_lwe <= ld_v && ld_iq >= 14'd4222 && ld_iq < 14'd4350; b2_w32_lwa <= 7'(ld_iq - 14'd4222); b2_w32_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab32 b2_w32_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w32_lwe), .wa(b2_w32_lwa), .wcol(1'b0), .wd(b2_w32_lwd), .q0(b2_w32));
    logic [31:0] b2_w33;
    logic b2_w33_lwe; logic [6:0] b2_w33_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w33_lwd;
    always_ff @(posedge clk) begin b2_w33_lwe <= ld_v && ld_iq >= 14'd4350 && ld_iq < 14'd4478; b2_w33_lwa <= 7'(ld_iq - 14'd4350); b2_w33_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab33 b2_w33_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w33_lwe), .wa(b2_w33_lwa), .wcol(1'b0), .wd(b2_w33_lwd), .q0(b2_w33));
    logic [31:0] b2_w34;
    logic b2_w34_lwe; logic [6:0] b2_w34_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w34_lwd;
    always_ff @(posedge clk) begin b2_w34_lwe <= ld_v && ld_iq >= 14'd4478 && ld_iq < 14'd4606; b2_w34_lwa <= 7'(ld_iq - 14'd4478); b2_w34_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab34 b2_w34_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w34_lwe), .wa(b2_w34_lwa), .wcol(1'b0), .wd(b2_w34_lwd), .q0(b2_w34));
    logic [31:0] b2_w35;
    logic b2_w35_lwe; logic [6:0] b2_w35_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w35_lwd;
    always_ff @(posedge clk) begin b2_w35_lwe <= ld_v && ld_iq >= 14'd4606 && ld_iq < 14'd4734; b2_w35_lwa <= 7'(ld_iq - 14'd4606); b2_w35_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab35 b2_w35_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w35_lwe), .wa(b2_w35_lwa), .wcol(1'b0), .wd(b2_w35_lwd), .q0(b2_w35));
    logic [31:0] b2_w36;
    logic b2_w36_lwe; logic [6:0] b2_w36_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w36_lwd;
    always_ff @(posedge clk) begin b2_w36_lwe <= ld_v && ld_iq >= 14'd4734 && ld_iq < 14'd4862; b2_w36_lwa <= 7'(ld_iq - 14'd4734); b2_w36_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab36 b2_w36_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w36_lwe), .wa(b2_w36_lwa), .wcol(1'b0), .wd(b2_w36_lwd), .q0(b2_w36));
    logic [31:0] b2_w37;
    logic b2_w37_lwe; logic [6:0] b2_w37_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w37_lwd;
    always_ff @(posedge clk) begin b2_w37_lwe <= ld_v && ld_iq >= 14'd4862 && ld_iq < 14'd4990; b2_w37_lwa <= 7'(ld_iq - 14'd4862); b2_w37_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab37 b2_w37_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w37_lwe), .wa(b2_w37_lwa), .wcol(1'b0), .wd(b2_w37_lwd), .q0(b2_w37));
    logic [31:0] b2_w38;
    logic b2_w38_lwe; logic [6:0] b2_w38_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w38_lwd;
    always_ff @(posedge clk) begin b2_w38_lwe <= ld_v && ld_iq >= 14'd4990 && ld_iq < 14'd5118; b2_w38_lwa <= 7'(ld_iq - 14'd4990); b2_w38_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab38 b2_w38_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w38_lwe), .wa(b2_w38_lwa), .wcol(1'b0), .wd(b2_w38_lwd), .q0(b2_w38));
    logic [31:0] b2_w39;
    logic b2_w39_lwe; logic [6:0] b2_w39_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w39_lwd;
    always_ff @(posedge clk) begin b2_w39_lwe <= ld_v && ld_iq >= 14'd5118 && ld_iq < 14'd5246; b2_w39_lwa <= 7'(ld_iq - 14'd5118); b2_w39_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab39 b2_w39_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w39_lwe), .wa(b2_w39_lwa), .wcol(1'b0), .wd(b2_w39_lwd), .q0(b2_w39));
    logic [31:0] b2_w40;
    logic b2_w40_lwe; logic [6:0] b2_w40_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w40_lwd;
    always_ff @(posedge clk) begin b2_w40_lwe <= ld_v && ld_iq >= 14'd5246 && ld_iq < 14'd5374; b2_w40_lwa <= 7'(ld_iq - 14'd5246); b2_w40_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab40 b2_w40_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w40_lwe), .wa(b2_w40_lwa), .wcol(1'b0), .wd(b2_w40_lwd), .q0(b2_w40));
    logic [31:0] b2_w41;
    logic b2_w41_lwe; logic [6:0] b2_w41_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w41_lwd;
    always_ff @(posedge clk) begin b2_w41_lwe <= ld_v && ld_iq >= 14'd5374 && ld_iq < 14'd5502; b2_w41_lwa <= 7'(ld_iq - 14'd5374); b2_w41_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab41 b2_w41_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w41_lwe), .wa(b2_w41_lwa), .wcol(1'b0), .wd(b2_w41_lwd), .q0(b2_w41));
    logic [31:0] b2_w42;
    logic b2_w42_lwe; logic [6:0] b2_w42_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w42_lwd;
    always_ff @(posedge clk) begin b2_w42_lwe <= ld_v && ld_iq >= 14'd5502 && ld_iq < 14'd5630; b2_w42_lwa <= 7'(ld_iq - 14'd5502); b2_w42_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab42 b2_w42_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w42_lwe), .wa(b2_w42_lwa), .wcol(1'b0), .wd(b2_w42_lwd), .q0(b2_w42));
    logic [31:0] b2_w43;
    logic b2_w43_lwe; logic [6:0] b2_w43_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w43_lwd;
    always_ff @(posedge clk) begin b2_w43_lwe <= ld_v && ld_iq >= 14'd5630 && ld_iq < 14'd5758; b2_w43_lwa <= 7'(ld_iq - 14'd5630); b2_w43_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab43 b2_w43_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w43_lwe), .wa(b2_w43_lwa), .wcol(1'b0), .wd(b2_w43_lwd), .q0(b2_w43));
    logic [31:0] b2_w44;
    logic b2_w44_lwe; logic [6:0] b2_w44_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w44_lwd;
    always_ff @(posedge clk) begin b2_w44_lwe <= ld_v && ld_iq >= 14'd5758 && ld_iq < 14'd5886; b2_w44_lwa <= 7'(ld_iq - 14'd5758); b2_w44_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab44 b2_w44_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w44_lwe), .wa(b2_w44_lwa), .wcol(1'b0), .wd(b2_w44_lwd), .q0(b2_w44));
    logic [31:0] b2_w45;
    logic b2_w45_lwe; logic [6:0] b2_w45_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w45_lwd;
    always_ff @(posedge clk) begin b2_w45_lwe <= ld_v && ld_iq >= 14'd5886 && ld_iq < 14'd6014; b2_w45_lwa <= 7'(ld_iq - 14'd5886); b2_w45_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab45 b2_w45_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w45_lwe), .wa(b2_w45_lwa), .wcol(1'b0), .wd(b2_w45_lwd), .q0(b2_w45));
    logic [31:0] b2_w46;
    logic b2_w46_lwe; logic [6:0] b2_w46_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w46_lwd;
    always_ff @(posedge clk) begin b2_w46_lwe <= ld_v && ld_iq >= 14'd6014 && ld_iq < 14'd6142; b2_w46_lwa <= 7'(ld_iq - 14'd6014); b2_w46_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab46 b2_w46_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w46_lwe), .wa(b2_w46_lwa), .wcol(1'b0), .wd(b2_w46_lwd), .q0(b2_w46));
    logic [31:0] b2_w47;
    logic b2_w47_lwe; logic [6:0] b2_w47_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w47_lwd;
    always_ff @(posedge clk) begin b2_w47_lwe <= ld_v && ld_iq >= 14'd6142 && ld_iq < 14'd6270; b2_w47_lwa <= 7'(ld_iq - 14'd6142); b2_w47_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab47 b2_w47_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w47_lwe), .wa(b2_w47_lwa), .wcol(1'b0), .wd(b2_w47_lwd), .q0(b2_w47));
    logic [31:0] b2_w48;
    logic b2_w48_lwe; logic [6:0] b2_w48_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w48_lwd;
    always_ff @(posedge clk) begin b2_w48_lwe <= ld_v && ld_iq >= 14'd6270 && ld_iq < 14'd6398; b2_w48_lwa <= 7'(ld_iq - 14'd6270); b2_w48_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab48 b2_w48_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w48_lwe), .wa(b2_w48_lwa), .wcol(1'b0), .wd(b2_w48_lwd), .q0(b2_w48));
    logic [31:0] b2_w49;
    logic b2_w49_lwe; logic [6:0] b2_w49_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w49_lwd;
    always_ff @(posedge clk) begin b2_w49_lwe <= ld_v && ld_iq >= 14'd6398 && ld_iq < 14'd6526; b2_w49_lwa <= 7'(ld_iq - 14'd6398); b2_w49_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab49 b2_w49_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w49_lwe), .wa(b2_w49_lwa), .wcol(1'b0), .wd(b2_w49_lwd), .q0(b2_w49));
    logic [31:0] b2_w50;
    logic b2_w50_lwe; logic [6:0] b2_w50_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w50_lwd;
    always_ff @(posedge clk) begin b2_w50_lwe <= ld_v && ld_iq >= 14'd6526 && ld_iq < 14'd6654; b2_w50_lwa <= 7'(ld_iq - 14'd6526); b2_w50_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab50 b2_w50_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w50_lwe), .wa(b2_w50_lwa), .wcol(1'b0), .wd(b2_w50_lwd), .q0(b2_w50));
    logic [31:0] b2_w51;
    logic b2_w51_lwe; logic [6:0] b2_w51_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w51_lwd;
    always_ff @(posedge clk) begin b2_w51_lwe <= ld_v && ld_iq >= 14'd6654 && ld_iq < 14'd6782; b2_w51_lwa <= 7'(ld_iq - 14'd6654); b2_w51_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab51 b2_w51_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w51_lwe), .wa(b2_w51_lwa), .wcol(1'b0), .wd(b2_w51_lwd), .q0(b2_w51));
    logic [31:0] b2_w52;
    logic b2_w52_lwe; logic [6:0] b2_w52_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w52_lwd;
    always_ff @(posedge clk) begin b2_w52_lwe <= ld_v && ld_iq >= 14'd6782 && ld_iq < 14'd6910; b2_w52_lwa <= 7'(ld_iq - 14'd6782); b2_w52_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab52 b2_w52_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w52_lwe), .wa(b2_w52_lwa), .wcol(1'b0), .wd(b2_w52_lwd), .q0(b2_w52));
    logic [31:0] b2_w53;
    logic b2_w53_lwe; logic [6:0] b2_w53_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w53_lwd;
    always_ff @(posedge clk) begin b2_w53_lwe <= ld_v && ld_iq >= 14'd6910 && ld_iq < 14'd7038; b2_w53_lwa <= 7'(ld_iq - 14'd6910); b2_w53_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab53 b2_w53_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w53_lwe), .wa(b2_w53_lwa), .wcol(1'b0), .wd(b2_w53_lwd), .q0(b2_w53));
    logic [31:0] b2_w54;
    logic b2_w54_lwe; logic [6:0] b2_w54_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w54_lwd;
    always_ff @(posedge clk) begin b2_w54_lwe <= ld_v && ld_iq >= 14'd7038 && ld_iq < 14'd7166; b2_w54_lwa <= 7'(ld_iq - 14'd7038); b2_w54_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab54 b2_w54_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w54_lwe), .wa(b2_w54_lwa), .wcol(1'b0), .wd(b2_w54_lwd), .q0(b2_w54));
    logic [31:0] b2_w55;
    logic b2_w55_lwe; logic [6:0] b2_w55_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w55_lwd;
    always_ff @(posedge clk) begin b2_w55_lwe <= ld_v && ld_iq >= 14'd7166 && ld_iq < 14'd7294; b2_w55_lwa <= 7'(ld_iq - 14'd7166); b2_w55_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab55 b2_w55_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w55_lwe), .wa(b2_w55_lwa), .wcol(1'b0), .wd(b2_w55_lwd), .q0(b2_w55));
    logic [31:0] b2_w56;
    logic b2_w56_lwe; logic [6:0] b2_w56_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w56_lwd;
    always_ff @(posedge clk) begin b2_w56_lwe <= ld_v && ld_iq >= 14'd7294 && ld_iq < 14'd7422; b2_w56_lwa <= 7'(ld_iq - 14'd7294); b2_w56_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab56 b2_w56_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w56_lwe), .wa(b2_w56_lwa), .wcol(1'b0), .wd(b2_w56_lwd), .q0(b2_w56));
    logic [31:0] b2_w57;
    logic b2_w57_lwe; logic [6:0] b2_w57_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w57_lwd;
    always_ff @(posedge clk) begin b2_w57_lwe <= ld_v && ld_iq >= 14'd7422 && ld_iq < 14'd7550; b2_w57_lwa <= 7'(ld_iq - 14'd7422); b2_w57_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab57 b2_w57_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w57_lwe), .wa(b2_w57_lwa), .wcol(1'b0), .wd(b2_w57_lwd), .q0(b2_w57));
    logic [31:0] b2_w58;
    logic b2_w58_lwe; logic [6:0] b2_w58_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w58_lwd;
    always_ff @(posedge clk) begin b2_w58_lwe <= ld_v && ld_iq >= 14'd7550 && ld_iq < 14'd7678; b2_w58_lwa <= 7'(ld_iq - 14'd7550); b2_w58_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab58 b2_w58_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w58_lwe), .wa(b2_w58_lwa), .wcol(1'b0), .wd(b2_w58_lwd), .q0(b2_w58));
    logic [31:0] b2_w59;
    logic b2_w59_lwe; logic [6:0] b2_w59_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w59_lwd;
    always_ff @(posedge clk) begin b2_w59_lwe <= ld_v && ld_iq >= 14'd7678 && ld_iq < 14'd7806; b2_w59_lwa <= 7'(ld_iq - 14'd7678); b2_w59_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab59 b2_w59_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w59_lwe), .wa(b2_w59_lwa), .wcol(1'b0), .wd(b2_w59_lwd), .q0(b2_w59));
    logic [31:0] b2_w60;
    logic b2_w60_lwe; logic [6:0] b2_w60_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w60_lwd;
    always_ff @(posedge clk) begin b2_w60_lwe <= ld_v && ld_iq >= 14'd7806 && ld_iq < 14'd7934; b2_w60_lwa <= 7'(ld_iq - 14'd7806); b2_w60_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab60 b2_w60_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w60_lwe), .wa(b2_w60_lwa), .wcol(1'b0), .wd(b2_w60_lwd), .q0(b2_w60));
    logic [31:0] b2_w61;
    logic b2_w61_lwe; logic [6:0] b2_w61_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w61_lwd;
    always_ff @(posedge clk) begin b2_w61_lwe <= ld_v && ld_iq >= 14'd7934 && ld_iq < 14'd8062; b2_w61_lwa <= 7'(ld_iq - 14'd7934); b2_w61_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab61 b2_w61_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w61_lwe), .wa(b2_w61_lwa), .wcol(1'b0), .wd(b2_w61_lwd), .q0(b2_w61));
    logic [31:0] b2_w62;
    logic b2_w62_lwe; logic [6:0] b2_w62_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b2_w62_lwd;
    always_ff @(posedge clk) begin b2_w62_lwe <= ld_v && ld_iq >= 14'd8062 && ld_iq < 14'd8190; b2_w62_lwa <= 7'(ld_iq - 14'd8062); b2_w62_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_b2_tab62 b2_w62_i (.clk(clk), .addr({b1_tag[0], b2_cnt[5], b2_cnt[4], b2_cnt[3], b2_cnt[2], b2_cnt[1], b2_cnt[0]}), .we(b2_w62_lwe), .wa(b2_w62_lwa), .wcol(1'b0), .wd(b2_w62_lwd), .q0(b2_w62));
    logic [31:0] b2_d0;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d0_i (.clk(clk), .din(b1_g0_o[0]), .dout(b2_d0));
    logic [31:0] b2_d1;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d1_i (.clk(clk), .din(b1_g0_o[1]), .dout(b2_d1));
    logic [31:0] b2_d2;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d2_i (.clk(clk), .din(b1_g0_o[2]), .dout(b2_d2));
    logic [31:0] b2_d3;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d3_i (.clk(clk), .din(b1_g0_o[3]), .dout(b2_d3));
    logic [31:0] b2_d4;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d4_i (.clk(clk), .din(b1_g0_o[4]), .dout(b2_d4));
    logic [31:0] b2_d5;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d5_i (.clk(clk), .din(b1_g0_o[5]), .dout(b2_d5));
    logic [31:0] b2_d6;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d6_i (.clk(clk), .din(b1_g0_o[6]), .dout(b2_d6));
    logic [31:0] b2_d7;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d7_i (.clk(clk), .din(b1_g0_o[7]), .dout(b2_d7));
    logic [31:0] b2_d8;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d8_i (.clk(clk), .din(b1_g0_o[8]), .dout(b2_d8));
    logic [31:0] b2_d9;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d9_i (.clk(clk), .din(b1_g0_o[9]), .dout(b2_d9));
    logic [31:0] b2_d10;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d10_i (.clk(clk), .din(b1_g0_o[10]), .dout(b2_d10));
    logic [31:0] b2_d11;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d11_i (.clk(clk), .din(b1_g0_o[11]), .dout(b2_d11));
    logic [31:0] b2_d12;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d12_i (.clk(clk), .din(b1_g0_o[12]), .dout(b2_d12));
    logic [31:0] b2_d13;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d13_i (.clk(clk), .din(b1_g0_o[13]), .dout(b2_d13));
    logic [31:0] b2_d14;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d14_i (.clk(clk), .din(b1_g0_o[14]), .dout(b2_d14));
    logic [31:0] b2_d15;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d15_i (.clk(clk), .din(b1_g0_o[15]), .dout(b2_d15));
    logic [31:0] b2_d16;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d16_i (.clk(clk), .din(b1_g0_o[16]), .dout(b2_d16));
    logic [31:0] b2_d17;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d17_i (.clk(clk), .din(b1_g0_o[17]), .dout(b2_d17));
    logic [31:0] b2_d18;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d18_i (.clk(clk), .din(b1_g0_o[18]), .dout(b2_d18));
    logic [31:0] b2_d19;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d19_i (.clk(clk), .din(b1_g0_o[19]), .dout(b2_d19));
    logic [31:0] b2_d20;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d20_i (.clk(clk), .din(b1_g0_o[20]), .dout(b2_d20));
    logic [31:0] b2_d21;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d21_i (.clk(clk), .din(b1_g0_o[21]), .dout(b2_d21));
    logic [31:0] b2_d22;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d22_i (.clk(clk), .din(b1_g0_o[22]), .dout(b2_d22));
    logic [31:0] b2_d23;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d23_i (.clk(clk), .din(b1_g0_o[23]), .dout(b2_d23));
    logic [31:0] b2_d24;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d24_i (.clk(clk), .din(b1_g0_o[24]), .dout(b2_d24));
    logic [31:0] b2_d25;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d25_i (.clk(clk), .din(b1_g0_o[25]), .dout(b2_d25));
    logic [31:0] b2_d26;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d26_i (.clk(clk), .din(b1_g0_o[26]), .dout(b2_d26));
    logic [31:0] b2_d27;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d27_i (.clk(clk), .din(b1_g0_o[27]), .dout(b2_d27));
    logic [31:0] b2_d28;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d28_i (.clk(clk), .din(b1_g0_o[28]), .dout(b2_d28));
    logic [31:0] b2_d29;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d29_i (.clk(clk), .din(b1_g0_o[29]), .dout(b2_d29));
    logic [31:0] b2_d30;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d30_i (.clk(clk), .din(b1_g0_o[30]), .dout(b2_d30));
    logic [31:0] b2_d31;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d31_i (.clk(clk), .din(b1_g0_o[31]), .dout(b2_d31));
    logic [31:0] b2_d32;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d32_i (.clk(clk), .din(b1_g0_o[32]), .dout(b2_d32));
    logic [31:0] b2_d33;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d33_i (.clk(clk), .din(b1_g0_o[33]), .dout(b2_d33));
    logic [31:0] b2_d34;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d34_i (.clk(clk), .din(b1_g0_o[34]), .dout(b2_d34));
    logic [31:0] b2_d35;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d35_i (.clk(clk), .din(b1_g0_o[35]), .dout(b2_d35));
    logic [31:0] b2_d36;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d36_i (.clk(clk), .din(b1_g0_o[36]), .dout(b2_d36));
    logic [31:0] b2_d37;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d37_i (.clk(clk), .din(b1_g0_o[37]), .dout(b2_d37));
    logic [31:0] b2_d38;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d38_i (.clk(clk), .din(b1_g0_o[38]), .dout(b2_d38));
    logic [31:0] b2_d39;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d39_i (.clk(clk), .din(b1_g0_o[39]), .dout(b2_d39));
    logic [31:0] b2_d40;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d40_i (.clk(clk), .din(b1_g0_o[40]), .dout(b2_d40));
    logic [31:0] b2_d41;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d41_i (.clk(clk), .din(b1_g0_o[41]), .dout(b2_d41));
    logic [31:0] b2_d42;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d42_i (.clk(clk), .din(b1_g0_o[42]), .dout(b2_d42));
    logic [31:0] b2_d43;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d43_i (.clk(clk), .din(b1_g0_o[43]), .dout(b2_d43));
    logic [31:0] b2_d44;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d44_i (.clk(clk), .din(b1_g0_o[44]), .dout(b2_d44));
    logic [31:0] b2_d45;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d45_i (.clk(clk), .din(b1_g0_o[45]), .dout(b2_d45));
    logic [31:0] b2_d46;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d46_i (.clk(clk), .din(b1_g0_o[46]), .dout(b2_d46));
    logic [31:0] b2_d47;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d47_i (.clk(clk), .din(b1_g0_o[47]), .dout(b2_d47));
    logic [31:0] b2_d48;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d48_i (.clk(clk), .din(b1_g0_o[48]), .dout(b2_d48));
    logic [31:0] b2_d49;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d49_i (.clk(clk), .din(b1_g0_o[49]), .dout(b2_d49));
    logic [31:0] b2_d50;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d50_i (.clk(clk), .din(b1_g0_o[50]), .dout(b2_d50));
    logic [31:0] b2_d51;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d51_i (.clk(clk), .din(b1_g0_o[51]), .dout(b2_d51));
    logic [31:0] b2_d52;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d52_i (.clk(clk), .din(b1_g0_o[52]), .dout(b2_d52));
    logic [31:0] b2_d53;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d53_i (.clk(clk), .din(b1_g0_o[53]), .dout(b2_d53));
    logic [31:0] b2_d54;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d54_i (.clk(clk), .din(b1_g0_o[54]), .dout(b2_d54));
    logic [31:0] b2_d55;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d55_i (.clk(clk), .din(b1_g0_o[55]), .dout(b2_d55));
    logic [31:0] b2_d56;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d56_i (.clk(clk), .din(b1_g0_o[56]), .dout(b2_d56));
    logic [31:0] b2_d57;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d57_i (.clk(clk), .din(b1_g0_o[57]), .dout(b2_d57));
    logic [31:0] b2_d58;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d58_i (.clk(clk), .din(b1_g0_o[58]), .dout(b2_d58));
    logic [31:0] b2_d59;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d59_i (.clk(clk), .din(b1_g0_o[59]), .dout(b2_d59));
    logic [31:0] b2_d60;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d60_i (.clk(clk), .din(b1_g0_o[60]), .dout(b2_d60));
    logic [31:0] b2_d61;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d61_i (.clk(clk), .din(b1_g0_o[61]), .dout(b2_d61));
    logic [31:0] b2_d62;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d62_i (.clk(clk), .din(b1_g0_o[62]), .dout(b2_d62));
    logic [31:0] b2_d63;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b2_d63_i (.clk(clk), .din(b1_g0_o[63]), .dout(b2_d63));
    logic [1:0] b2_pv_sr;
    always_ff @(posedge clk) b2_pv_sr <= rst ? '0 : {b2_pv_sr[0:0], b1_g0_v};
    logic b2_pv; assign b2_pv = b2_pv_sr[1];
    logic [0:0] b2_pg;
    MS_N12_q32_P64_tpm_dly_c #(.W(1), .D(2)) b2_pg_i (.clk(clk), .din(b1_tag), .dout(b2_pg));
    // block 2: pass 1, 1 x MS_N12_q32_P64_tpm_p1 (64-point), latency 82
    logic [31:0] b2_c0_y0, b2_c0_y1, b2_c0_y2, b2_c0_y3, b2_c0_y4, b2_c0_y5, b2_c0_y6, b2_c0_y7, b2_c0_y8, b2_c0_y9, b2_c0_y10, b2_c0_y11, b2_c0_y12, b2_c0_y13, b2_c0_y14, b2_c0_y15, b2_c0_y16, b2_c0_y17, b2_c0_y18, b2_c0_y19, b2_c0_y20, b2_c0_y21, b2_c0_y22, b2_c0_y23, b2_c0_y24, b2_c0_y25, b2_c0_y26, b2_c0_y27, b2_c0_y28, b2_c0_y29, b2_c0_y30, b2_c0_y31, b2_c0_y32, b2_c0_y33, b2_c0_y34, b2_c0_y35, b2_c0_y36, b2_c0_y37, b2_c0_y38, b2_c0_y39, b2_c0_y40, b2_c0_y41, b2_c0_y42, b2_c0_y43, b2_c0_y44, b2_c0_y45, b2_c0_y46, b2_c0_y47, b2_c0_y48, b2_c0_y49, b2_c0_y50, b2_c0_y51, b2_c0_y52, b2_c0_y53, b2_c0_y54, b2_c0_y55, b2_c0_y56, b2_c0_y57, b2_c0_y58, b2_c0_y59, b2_c0_y60, b2_c0_y61, b2_c0_y62, b2_c0_y63;
    logic b2_c0_v; logic b2_c0_di;
    MS_N12_q32_P64_tpm_p1 b2_c0 (.clk(clk), .rst(rst), .in_valid(b2_pv), .out_valid(b2_c0_v), .DIR(b2_pg[0]), .tw_0_0(b2_w0), .tw_0_1(b2_w0), .tw_0_2(b2_w0), .tw_0_3(b2_w0), .tw_0_4(b2_w0), .tw_0_5(b2_w0), .tw_0_6(b2_w0), .tw_0_7(b2_w0), .tw_0_8(b2_w0), .tw_0_9(b2_w0), .tw_0_10(b2_w0), .tw_0_11(b2_w0), .tw_0_12(b2_w0), .tw_0_13(b2_w0), .tw_0_14(b2_w0), .tw_0_15(b2_w0), .tw_0_16(b2_w0), .tw_0_17(b2_w0), .tw_0_18(b2_w0), .tw_0_19(b2_w0), .tw_0_20(b2_w0), .tw_0_21(b2_w0), .tw_0_22(b2_w0), .tw_0_23(b2_w0), .tw_0_24(b2_w0), .tw_0_25(b2_w0), .tw_0_26(b2_w0), .tw_0_27(b2_w0), .tw_0_28(b2_w0), .tw_0_29(b2_w0), .tw_0_30(b2_w0), .tw_0_31(b2_w0), .tw_1_0(b2_w1), .tw_1_1(b2_w2), .tw_1_2(b2_w1), .tw_1_3(b2_w2), .tw_1_4(b2_w1), .tw_1_5(b2_w2), .tw_1_6(b2_w1), .tw_1_7(b2_w2), .tw_1_8(b2_w1), .tw_1_9(b2_w2), .tw_1_10(b2_w1), .tw_1_11(b2_w2), .tw_1_12(b2_w1), .tw_1_13(b2_w2), .tw_1_14(b2_w1), .tw_1_15(b2_w2), .tw_1_16(b2_w1), .tw_1_17(b2_w2), .tw_1_18(b2_w1), .tw_1_19(b2_w2), .tw_1_20(b2_w1), .tw_1_21(b2_w2), .tw_1_22(b2_w1), .tw_1_23(b2_w2), .tw_1_24(b2_w1), .tw_1_25(b2_w2), .tw_1_26(b2_w1), .tw_1_27(b2_w2), .tw_1_28(b2_w1), .tw_1_29(b2_w2), .tw_1_30(b2_w1), .tw_1_31(b2_w2), .tw_2_0(b2_w3), .tw_2_1(b2_w4), .tw_2_2(b2_w5), .tw_2_3(b2_w6), .tw_2_4(b2_w3), .tw_2_5(b2_w4), .tw_2_6(b2_w5), .tw_2_7(b2_w6), .tw_2_8(b2_w3), .tw_2_9(b2_w4), .tw_2_10(b2_w5), .tw_2_11(b2_w6), .tw_2_12(b2_w3), .tw_2_13(b2_w4), .tw_2_14(b2_w5), .tw_2_15(b2_w6), .tw_2_16(b2_w3), .tw_2_17(b2_w4), .tw_2_18(b2_w5), .tw_2_19(b2_w6), .tw_2_20(b2_w3), .tw_2_21(b2_w4), .tw_2_22(b2_w5), .tw_2_23(b2_w6), .tw_2_24(b2_w3), .tw_2_25(b2_w4), .tw_2_26(b2_w5), .tw_2_27(b2_w6), .tw_2_28(b2_w3), .tw_2_29(b2_w4), .tw_2_30(b2_w5), .tw_2_31(b2_w6), .tw_3_0(b2_w7), .tw_3_1(b2_w8), .tw_3_2(b2_w9), .tw_3_3(b2_w10), .tw_3_4(b2_w11), .tw_3_5(b2_w12), .tw_3_6(b2_w13), .tw_3_7(b2_w14), .tw_3_8(b2_w7), .tw_3_9(b2_w8), .tw_3_10(b2_w9), .tw_3_11(b2_w10), .tw_3_12(b2_w11), .tw_3_13(b2_w12), .tw_3_14(b2_w13), .tw_3_15(b2_w14), .tw_3_16(b2_w7), .tw_3_17(b2_w8), .tw_3_18(b2_w9), .tw_3_19(b2_w10), .tw_3_20(b2_w11), .tw_3_21(b2_w12), .tw_3_22(b2_w13), .tw_3_23(b2_w14), .tw_3_24(b2_w7), .tw_3_25(b2_w8), .tw_3_26(b2_w9), .tw_3_27(b2_w10), .tw_3_28(b2_w11), .tw_3_29(b2_w12), .tw_3_30(b2_w13), .tw_3_31(b2_w14), .tw_4_0(b2_w15), .tw_4_1(b2_w16), .tw_4_2(b2_w17), .tw_4_3(b2_w18), .tw_4_4(b2_w19), .tw_4_5(b2_w20), .tw_4_6(b2_w21), .tw_4_7(b2_w22), .tw_4_8(b2_w23), .tw_4_9(b2_w24), .tw_4_10(b2_w25), .tw_4_11(b2_w26), .tw_4_12(b2_w27), .tw_4_13(b2_w28), .tw_4_14(b2_w29), .tw_4_15(b2_w30), .tw_4_16(b2_w15), .tw_4_17(b2_w16), .tw_4_18(b2_w17), .tw_4_19(b2_w18), .tw_4_20(b2_w19), .tw_4_21(b2_w20), .tw_4_22(b2_w21), .tw_4_23(b2_w22), .tw_4_24(b2_w23), .tw_4_25(b2_w24), .tw_4_26(b2_w25), .tw_4_27(b2_w26), .tw_4_28(b2_w27), .tw_4_29(b2_w28), .tw_4_30(b2_w29), .tw_4_31(b2_w30), .tw_5_0(b2_w31), .tw_5_1(b2_w32), .tw_5_2(b2_w33), .tw_5_3(b2_w34), .tw_5_4(b2_w35), .tw_5_5(b2_w36), .tw_5_6(b2_w37), .tw_5_7(b2_w38), .tw_5_8(b2_w39), .tw_5_9(b2_w40), .tw_5_10(b2_w41), .tw_5_11(b2_w42), .tw_5_12(b2_w43), .tw_5_13(b2_w44), .tw_5_14(b2_w45), .tw_5_15(b2_w46), .tw_5_16(b2_w47), .tw_5_17(b2_w48), .tw_5_18(b2_w49), .tw_5_19(b2_w50), .tw_5_20(b2_w51), .tw_5_21(b2_w52), .tw_5_22(b2_w53), .tw_5_23(b2_w54), .tw_5_24(b2_w55), .tw_5_25(b2_w56), .tw_5_26(b2_w57), .tw_5_27(b2_w58), .tw_5_28(b2_w59), .tw_5_29(b2_w60), .tw_5_30(b2_w61), .tw_5_31(b2_w62), .QH(QH[15:0]), .QHALF(QHALF[31:0]), .x_in_0(b2_d0), .x_in_1(b2_d1), .x_in_2(b2_d2), .x_in_3(b2_d3), .x_in_4(b2_d4), .x_in_5(b2_d5), .x_in_6(b2_d6), .x_in_7(b2_d7), .x_in_8(b2_d8), .x_in_9(b2_d9), .x_in_10(b2_d10), .x_in_11(b2_d11), .x_in_12(b2_d12), .x_in_13(b2_d13), .x_in_14(b2_d14), .x_in_15(b2_d15), .x_in_16(b2_d16), .x_in_17(b2_d17), .x_in_18(b2_d18), .x_in_19(b2_d19), .x_in_20(b2_d20), .x_in_21(b2_d21), .x_in_22(b2_d22), .x_in_23(b2_d23), .x_in_24(b2_d24), .x_in_25(b2_d25), .x_in_26(b2_d26), .x_in_27(b2_d27), .x_in_28(b2_d28), .x_in_29(b2_d29), .x_in_30(b2_d30), .x_in_31(b2_d31), .x_in_32(b2_d32), .x_in_33(b2_d33), .x_in_34(b2_d34), .x_in_35(b2_d35), .x_in_36(b2_d36), .x_in_37(b2_d37), .x_in_38(b2_d38), .x_in_39(b2_d39), .x_in_40(b2_d40), .x_in_41(b2_d41), .x_in_42(b2_d42), .x_in_43(b2_d43), .x_in_44(b2_d44), .x_in_45(b2_d45), .x_in_46(b2_d46), .x_in_47(b2_d47), .x_in_48(b2_d48), .x_in_49(b2_d49), .x_in_50(b2_d50), .x_in_51(b2_d51), .x_in_52(b2_d52), .x_in_53(b2_d53), .x_in_54(b2_d54), .x_in_55(b2_d55), .x_in_56(b2_d56), .x_in_57(b2_d57), .x_in_58(b2_d58), .x_in_59(b2_d59), .x_in_60(b2_d60), .x_in_61(b2_d61), .x_in_62(b2_d62), .x_in_63(b2_d63), .y_out_0(b2_c0_y0), .y_out_1(b2_c0_y1), .y_out_2(b2_c0_y2), .y_out_3(b2_c0_y3), .y_out_4(b2_c0_y4), .y_out_5(b2_c0_y5), .y_out_6(b2_c0_y6), .y_out_7(b2_c0_y7), .y_out_8(b2_c0_y8), .y_out_9(b2_c0_y9), .y_out_10(b2_c0_y10), .y_out_11(b2_c0_y11), .y_out_12(b2_c0_y12), .y_out_13(b2_c0_y13), .y_out_14(b2_c0_y14), .y_out_15(b2_c0_y15), .y_out_16(b2_c0_y16), .y_out_17(b2_c0_y17), .y_out_18(b2_c0_y18), .y_out_19(b2_c0_y19), .y_out_20(b2_c0_y20), .y_out_21(b2_c0_y21), .y_out_22(b2_c0_y22), .y_out_23(b2_c0_y23), .y_out_24(b2_c0_y24), .y_out_25(b2_c0_y25), .y_out_26(b2_c0_y26), .y_out_27(b2_c0_y27), .y_out_28(b2_c0_y28), .y_out_29(b2_c0_y29), .y_out_30(b2_c0_y30), .y_out_31(b2_c0_y31), .y_out_32(b2_c0_y32), .y_out_33(b2_c0_y33), .y_out_34(b2_c0_y34), .y_out_35(b2_c0_y35), .y_out_36(b2_c0_y36), .y_out_37(b2_c0_y37), .y_out_38(b2_c0_y38), .y_out_39(b2_c0_y39), .y_out_40(b2_c0_y40), .y_out_41(b2_c0_y41), .y_out_42(b2_c0_y42), .y_out_43(b2_c0_y43), .y_out_44(b2_c0_y44), .y_out_45(b2_c0_y45), .y_out_46(b2_c0_y46), .y_out_47(b2_c0_y47), .y_out_48(b2_c0_y48), .y_out_49(b2_c0_y49), .y_out_50(b2_c0_y50), .y_out_51(b2_c0_y51), .y_out_52(b2_c0_y52), .y_out_53(b2_c0_y53), .y_out_54(b2_c0_y54), .y_out_55(b2_c0_y55), .y_out_56(b2_c0_y56), .y_out_57(b2_c0_y57), .y_out_58(b2_c0_y58), .y_out_59(b2_c0_y59), .y_out_60(b2_c0_y60), .y_out_61(b2_c0_y61), .y_out_62(b2_c0_y62), .y_out_63(b2_c0_y63));
    logic [0:0] b2_tag;
    MS_N12_q32_P64_tpm_dly_c #(.W(1), .D(80)) b2_tag_i (.clk(clk), .din(b2_pg), .dout(b2_tag));
    // block 3: twiddle stage 2, latency 12 (tables 2, multiplier 10)
    logic [5:0] b3_cnt;
    always_ff @(posedge clk) b3_cnt <= rst ? '0 : (b2_c0_v ? b3_cnt + 1'b1 : b3_cnt);
    logic [31:0] b3_t0;
    logic b3_t0_lwe; logic [6:0] b3_t0_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t0_lwd;
    always_ff @(posedge clk) begin b3_t0_lwe <= ld_v && ld_iq >= 14'd8190 && ld_iq < 14'd8318; b3_t0_lwa <= 7'(ld_iq - 14'd8190); b3_t0_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab0 b3_t0_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t0_lwe), .wa(b3_t0_lwa), .wcol(1'b0), .wd(b3_t0_lwd), .q0(b3_t0));
    logic [31:0] b3_t1;
    logic b3_t1_lwe; logic [6:0] b3_t1_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t1_lwd;
    always_ff @(posedge clk) begin b3_t1_lwe <= ld_v && ld_iq >= 14'd8318 && ld_iq < 14'd8446; b3_t1_lwa <= 7'(ld_iq - 14'd8318); b3_t1_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab1 b3_t1_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t1_lwe), .wa(b3_t1_lwa), .wcol(1'b0), .wd(b3_t1_lwd), .q0(b3_t1));
    logic [31:0] b3_t2;
    logic b3_t2_lwe; logic [6:0] b3_t2_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t2_lwd;
    always_ff @(posedge clk) begin b3_t2_lwe <= ld_v && ld_iq >= 14'd8446 && ld_iq < 14'd8574; b3_t2_lwa <= 7'(ld_iq - 14'd8446); b3_t2_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab2 b3_t2_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t2_lwe), .wa(b3_t2_lwa), .wcol(1'b0), .wd(b3_t2_lwd), .q0(b3_t2));
    logic [31:0] b3_t3;
    logic b3_t3_lwe; logic [6:0] b3_t3_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t3_lwd;
    always_ff @(posedge clk) begin b3_t3_lwe <= ld_v && ld_iq >= 14'd8574 && ld_iq < 14'd8702; b3_t3_lwa <= 7'(ld_iq - 14'd8574); b3_t3_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab3 b3_t3_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t3_lwe), .wa(b3_t3_lwa), .wcol(1'b0), .wd(b3_t3_lwd), .q0(b3_t3));
    logic [31:0] b3_t4;
    logic b3_t4_lwe; logic [6:0] b3_t4_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t4_lwd;
    always_ff @(posedge clk) begin b3_t4_lwe <= ld_v && ld_iq >= 14'd8702 && ld_iq < 14'd8830; b3_t4_lwa <= 7'(ld_iq - 14'd8702); b3_t4_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab4 b3_t4_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t4_lwe), .wa(b3_t4_lwa), .wcol(1'b0), .wd(b3_t4_lwd), .q0(b3_t4));
    logic [31:0] b3_t5;
    logic b3_t5_lwe; logic [6:0] b3_t5_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t5_lwd;
    always_ff @(posedge clk) begin b3_t5_lwe <= ld_v && ld_iq >= 14'd8830 && ld_iq < 14'd8958; b3_t5_lwa <= 7'(ld_iq - 14'd8830); b3_t5_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab5 b3_t5_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t5_lwe), .wa(b3_t5_lwa), .wcol(1'b0), .wd(b3_t5_lwd), .q0(b3_t5));
    logic [31:0] b3_t6;
    logic b3_t6_lwe; logic [6:0] b3_t6_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t6_lwd;
    always_ff @(posedge clk) begin b3_t6_lwe <= ld_v && ld_iq >= 14'd8958 && ld_iq < 14'd9086; b3_t6_lwa <= 7'(ld_iq - 14'd8958); b3_t6_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab6 b3_t6_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t6_lwe), .wa(b3_t6_lwa), .wcol(1'b0), .wd(b3_t6_lwd), .q0(b3_t6));
    logic [31:0] b3_t7;
    logic b3_t7_lwe; logic [6:0] b3_t7_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t7_lwd;
    always_ff @(posedge clk) begin b3_t7_lwe <= ld_v && ld_iq >= 14'd9086 && ld_iq < 14'd9214; b3_t7_lwa <= 7'(ld_iq - 14'd9086); b3_t7_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab7 b3_t7_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t7_lwe), .wa(b3_t7_lwa), .wcol(1'b0), .wd(b3_t7_lwd), .q0(b3_t7));
    logic [31:0] b3_t8;
    logic b3_t8_lwe; logic [6:0] b3_t8_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t8_lwd;
    always_ff @(posedge clk) begin b3_t8_lwe <= ld_v && ld_iq >= 14'd9214 && ld_iq < 14'd9342; b3_t8_lwa <= 7'(ld_iq - 14'd9214); b3_t8_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab8 b3_t8_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t8_lwe), .wa(b3_t8_lwa), .wcol(1'b0), .wd(b3_t8_lwd), .q0(b3_t8));
    logic [31:0] b3_t9;
    logic b3_t9_lwe; logic [6:0] b3_t9_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t9_lwd;
    always_ff @(posedge clk) begin b3_t9_lwe <= ld_v && ld_iq >= 14'd9342 && ld_iq < 14'd9470; b3_t9_lwa <= 7'(ld_iq - 14'd9342); b3_t9_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab9 b3_t9_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t9_lwe), .wa(b3_t9_lwa), .wcol(1'b0), .wd(b3_t9_lwd), .q0(b3_t9));
    logic [31:0] b3_t10;
    logic b3_t10_lwe; logic [6:0] b3_t10_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t10_lwd;
    always_ff @(posedge clk) begin b3_t10_lwe <= ld_v && ld_iq >= 14'd9470 && ld_iq < 14'd9598; b3_t10_lwa <= 7'(ld_iq - 14'd9470); b3_t10_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab10 b3_t10_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t10_lwe), .wa(b3_t10_lwa), .wcol(1'b0), .wd(b3_t10_lwd), .q0(b3_t10));
    logic [31:0] b3_t11;
    logic b3_t11_lwe; logic [6:0] b3_t11_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t11_lwd;
    always_ff @(posedge clk) begin b3_t11_lwe <= ld_v && ld_iq >= 14'd9598 && ld_iq < 14'd9726; b3_t11_lwa <= 7'(ld_iq - 14'd9598); b3_t11_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab11 b3_t11_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t11_lwe), .wa(b3_t11_lwa), .wcol(1'b0), .wd(b3_t11_lwd), .q0(b3_t11));
    logic [31:0] b3_t12;
    logic b3_t12_lwe; logic [6:0] b3_t12_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t12_lwd;
    always_ff @(posedge clk) begin b3_t12_lwe <= ld_v && ld_iq >= 14'd9726 && ld_iq < 14'd9854; b3_t12_lwa <= 7'(ld_iq - 14'd9726); b3_t12_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab12 b3_t12_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t12_lwe), .wa(b3_t12_lwa), .wcol(1'b0), .wd(b3_t12_lwd), .q0(b3_t12));
    logic [31:0] b3_t13;
    logic b3_t13_lwe; logic [6:0] b3_t13_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t13_lwd;
    always_ff @(posedge clk) begin b3_t13_lwe <= ld_v && ld_iq >= 14'd9854 && ld_iq < 14'd9982; b3_t13_lwa <= 7'(ld_iq - 14'd9854); b3_t13_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab13 b3_t13_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t13_lwe), .wa(b3_t13_lwa), .wcol(1'b0), .wd(b3_t13_lwd), .q0(b3_t13));
    logic [31:0] b3_t14;
    logic b3_t14_lwe; logic [6:0] b3_t14_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t14_lwd;
    always_ff @(posedge clk) begin b3_t14_lwe <= ld_v && ld_iq >= 14'd9982 && ld_iq < 14'd10110; b3_t14_lwa <= 7'(ld_iq - 14'd9982); b3_t14_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab14 b3_t14_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t14_lwe), .wa(b3_t14_lwa), .wcol(1'b0), .wd(b3_t14_lwd), .q0(b3_t14));
    logic [31:0] b3_t15;
    logic b3_t15_lwe; logic [6:0] b3_t15_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t15_lwd;
    always_ff @(posedge clk) begin b3_t15_lwe <= ld_v && ld_iq >= 14'd10110 && ld_iq < 14'd10238; b3_t15_lwa <= 7'(ld_iq - 14'd10110); b3_t15_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab15 b3_t15_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t15_lwe), .wa(b3_t15_lwa), .wcol(1'b0), .wd(b3_t15_lwd), .q0(b3_t15));
    logic [31:0] b3_t16;
    logic b3_t16_lwe; logic [6:0] b3_t16_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t16_lwd;
    always_ff @(posedge clk) begin b3_t16_lwe <= ld_v && ld_iq >= 14'd10238 && ld_iq < 14'd10366; b3_t16_lwa <= 7'(ld_iq - 14'd10238); b3_t16_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab16 b3_t16_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t16_lwe), .wa(b3_t16_lwa), .wcol(1'b0), .wd(b3_t16_lwd), .q0(b3_t16));
    logic [31:0] b3_t17;
    logic b3_t17_lwe; logic [6:0] b3_t17_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t17_lwd;
    always_ff @(posedge clk) begin b3_t17_lwe <= ld_v && ld_iq >= 14'd10366 && ld_iq < 14'd10494; b3_t17_lwa <= 7'(ld_iq - 14'd10366); b3_t17_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab17 b3_t17_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t17_lwe), .wa(b3_t17_lwa), .wcol(1'b0), .wd(b3_t17_lwd), .q0(b3_t17));
    logic [31:0] b3_t18;
    logic b3_t18_lwe; logic [6:0] b3_t18_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t18_lwd;
    always_ff @(posedge clk) begin b3_t18_lwe <= ld_v && ld_iq >= 14'd10494 && ld_iq < 14'd10622; b3_t18_lwa <= 7'(ld_iq - 14'd10494); b3_t18_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab18 b3_t18_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t18_lwe), .wa(b3_t18_lwa), .wcol(1'b0), .wd(b3_t18_lwd), .q0(b3_t18));
    logic [31:0] b3_t19;
    logic b3_t19_lwe; logic [6:0] b3_t19_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t19_lwd;
    always_ff @(posedge clk) begin b3_t19_lwe <= ld_v && ld_iq >= 14'd10622 && ld_iq < 14'd10750; b3_t19_lwa <= 7'(ld_iq - 14'd10622); b3_t19_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab19 b3_t19_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t19_lwe), .wa(b3_t19_lwa), .wcol(1'b0), .wd(b3_t19_lwd), .q0(b3_t19));
    logic [31:0] b3_t20;
    logic b3_t20_lwe; logic [6:0] b3_t20_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t20_lwd;
    always_ff @(posedge clk) begin b3_t20_lwe <= ld_v && ld_iq >= 14'd10750 && ld_iq < 14'd10878; b3_t20_lwa <= 7'(ld_iq - 14'd10750); b3_t20_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab20 b3_t20_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t20_lwe), .wa(b3_t20_lwa), .wcol(1'b0), .wd(b3_t20_lwd), .q0(b3_t20));
    logic [31:0] b3_t21;
    logic b3_t21_lwe; logic [6:0] b3_t21_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t21_lwd;
    always_ff @(posedge clk) begin b3_t21_lwe <= ld_v && ld_iq >= 14'd10878 && ld_iq < 14'd11006; b3_t21_lwa <= 7'(ld_iq - 14'd10878); b3_t21_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab21 b3_t21_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t21_lwe), .wa(b3_t21_lwa), .wcol(1'b0), .wd(b3_t21_lwd), .q0(b3_t21));
    logic [31:0] b3_t22;
    logic b3_t22_lwe; logic [6:0] b3_t22_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t22_lwd;
    always_ff @(posedge clk) begin b3_t22_lwe <= ld_v && ld_iq >= 14'd11006 && ld_iq < 14'd11134; b3_t22_lwa <= 7'(ld_iq - 14'd11006); b3_t22_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab22 b3_t22_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t22_lwe), .wa(b3_t22_lwa), .wcol(1'b0), .wd(b3_t22_lwd), .q0(b3_t22));
    logic [31:0] b3_t23;
    logic b3_t23_lwe; logic [6:0] b3_t23_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t23_lwd;
    always_ff @(posedge clk) begin b3_t23_lwe <= ld_v && ld_iq >= 14'd11134 && ld_iq < 14'd11262; b3_t23_lwa <= 7'(ld_iq - 14'd11134); b3_t23_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab23 b3_t23_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t23_lwe), .wa(b3_t23_lwa), .wcol(1'b0), .wd(b3_t23_lwd), .q0(b3_t23));
    logic [31:0] b3_t24;
    logic b3_t24_lwe; logic [6:0] b3_t24_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t24_lwd;
    always_ff @(posedge clk) begin b3_t24_lwe <= ld_v && ld_iq >= 14'd11262 && ld_iq < 14'd11390; b3_t24_lwa <= 7'(ld_iq - 14'd11262); b3_t24_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab24 b3_t24_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t24_lwe), .wa(b3_t24_lwa), .wcol(1'b0), .wd(b3_t24_lwd), .q0(b3_t24));
    logic [31:0] b3_t25;
    logic b3_t25_lwe; logic [6:0] b3_t25_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t25_lwd;
    always_ff @(posedge clk) begin b3_t25_lwe <= ld_v && ld_iq >= 14'd11390 && ld_iq < 14'd11518; b3_t25_lwa <= 7'(ld_iq - 14'd11390); b3_t25_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab25 b3_t25_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t25_lwe), .wa(b3_t25_lwa), .wcol(1'b0), .wd(b3_t25_lwd), .q0(b3_t25));
    logic [31:0] b3_t26;
    logic b3_t26_lwe; logic [6:0] b3_t26_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t26_lwd;
    always_ff @(posedge clk) begin b3_t26_lwe <= ld_v && ld_iq >= 14'd11518 && ld_iq < 14'd11646; b3_t26_lwa <= 7'(ld_iq - 14'd11518); b3_t26_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab26 b3_t26_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t26_lwe), .wa(b3_t26_lwa), .wcol(1'b0), .wd(b3_t26_lwd), .q0(b3_t26));
    logic [31:0] b3_t27;
    logic b3_t27_lwe; logic [6:0] b3_t27_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t27_lwd;
    always_ff @(posedge clk) begin b3_t27_lwe <= ld_v && ld_iq >= 14'd11646 && ld_iq < 14'd11774; b3_t27_lwa <= 7'(ld_iq - 14'd11646); b3_t27_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab27 b3_t27_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t27_lwe), .wa(b3_t27_lwa), .wcol(1'b0), .wd(b3_t27_lwd), .q0(b3_t27));
    logic [31:0] b3_t28;
    logic b3_t28_lwe; logic [6:0] b3_t28_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t28_lwd;
    always_ff @(posedge clk) begin b3_t28_lwe <= ld_v && ld_iq >= 14'd11774 && ld_iq < 14'd11902; b3_t28_lwa <= 7'(ld_iq - 14'd11774); b3_t28_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab28 b3_t28_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t28_lwe), .wa(b3_t28_lwa), .wcol(1'b0), .wd(b3_t28_lwd), .q0(b3_t28));
    logic [31:0] b3_t29;
    logic b3_t29_lwe; logic [6:0] b3_t29_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t29_lwd;
    always_ff @(posedge clk) begin b3_t29_lwe <= ld_v && ld_iq >= 14'd11902 && ld_iq < 14'd12030; b3_t29_lwa <= 7'(ld_iq - 14'd11902); b3_t29_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab29 b3_t29_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t29_lwe), .wa(b3_t29_lwa), .wcol(1'b0), .wd(b3_t29_lwd), .q0(b3_t29));
    logic [31:0] b3_t30;
    logic b3_t30_lwe; logic [6:0] b3_t30_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t30_lwd;
    always_ff @(posedge clk) begin b3_t30_lwe <= ld_v && ld_iq >= 14'd12030 && ld_iq < 14'd12158; b3_t30_lwa <= 7'(ld_iq - 14'd12030); b3_t30_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab30 b3_t30_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t30_lwe), .wa(b3_t30_lwa), .wcol(1'b0), .wd(b3_t30_lwd), .q0(b3_t30));
    logic [31:0] b3_t31;
    logic b3_t31_lwe; logic [6:0] b3_t31_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t31_lwd;
    always_ff @(posedge clk) begin b3_t31_lwe <= ld_v && ld_iq >= 14'd12158 && ld_iq < 14'd12286; b3_t31_lwa <= 7'(ld_iq - 14'd12158); b3_t31_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab31 b3_t31_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t31_lwe), .wa(b3_t31_lwa), .wcol(1'b0), .wd(b3_t31_lwd), .q0(b3_t31));
    logic [31:0] b3_t32;
    logic b3_t32_lwe; logic [6:0] b3_t32_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t32_lwd;
    always_ff @(posedge clk) begin b3_t32_lwe <= ld_v && ld_iq >= 14'd12286 && ld_iq < 14'd12414; b3_t32_lwa <= 7'(ld_iq - 14'd12286); b3_t32_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab32 b3_t32_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t32_lwe), .wa(b3_t32_lwa), .wcol(1'b0), .wd(b3_t32_lwd), .q0(b3_t32));
    logic [31:0] b3_t33;
    logic b3_t33_lwe; logic [6:0] b3_t33_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t33_lwd;
    always_ff @(posedge clk) begin b3_t33_lwe <= ld_v && ld_iq >= 14'd12414 && ld_iq < 14'd12542; b3_t33_lwa <= 7'(ld_iq - 14'd12414); b3_t33_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab33 b3_t33_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t33_lwe), .wa(b3_t33_lwa), .wcol(1'b0), .wd(b3_t33_lwd), .q0(b3_t33));
    logic [31:0] b3_t34;
    logic b3_t34_lwe; logic [6:0] b3_t34_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t34_lwd;
    always_ff @(posedge clk) begin b3_t34_lwe <= ld_v && ld_iq >= 14'd12542 && ld_iq < 14'd12670; b3_t34_lwa <= 7'(ld_iq - 14'd12542); b3_t34_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab34 b3_t34_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t34_lwe), .wa(b3_t34_lwa), .wcol(1'b0), .wd(b3_t34_lwd), .q0(b3_t34));
    logic [31:0] b3_t35;
    logic b3_t35_lwe; logic [6:0] b3_t35_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t35_lwd;
    always_ff @(posedge clk) begin b3_t35_lwe <= ld_v && ld_iq >= 14'd12670 && ld_iq < 14'd12798; b3_t35_lwa <= 7'(ld_iq - 14'd12670); b3_t35_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab35 b3_t35_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t35_lwe), .wa(b3_t35_lwa), .wcol(1'b0), .wd(b3_t35_lwd), .q0(b3_t35));
    logic [31:0] b3_t36;
    logic b3_t36_lwe; logic [6:0] b3_t36_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t36_lwd;
    always_ff @(posedge clk) begin b3_t36_lwe <= ld_v && ld_iq >= 14'd12798 && ld_iq < 14'd12926; b3_t36_lwa <= 7'(ld_iq - 14'd12798); b3_t36_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab36 b3_t36_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t36_lwe), .wa(b3_t36_lwa), .wcol(1'b0), .wd(b3_t36_lwd), .q0(b3_t36));
    logic [31:0] b3_t37;
    logic b3_t37_lwe; logic [6:0] b3_t37_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t37_lwd;
    always_ff @(posedge clk) begin b3_t37_lwe <= ld_v && ld_iq >= 14'd12926 && ld_iq < 14'd13054; b3_t37_lwa <= 7'(ld_iq - 14'd12926); b3_t37_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab37 b3_t37_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t37_lwe), .wa(b3_t37_lwa), .wcol(1'b0), .wd(b3_t37_lwd), .q0(b3_t37));
    logic [31:0] b3_t38;
    logic b3_t38_lwe; logic [6:0] b3_t38_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t38_lwd;
    always_ff @(posedge clk) begin b3_t38_lwe <= ld_v && ld_iq >= 14'd13054 && ld_iq < 14'd13182; b3_t38_lwa <= 7'(ld_iq - 14'd13054); b3_t38_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab38 b3_t38_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t38_lwe), .wa(b3_t38_lwa), .wcol(1'b0), .wd(b3_t38_lwd), .q0(b3_t38));
    logic [31:0] b3_t39;
    logic b3_t39_lwe; logic [6:0] b3_t39_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t39_lwd;
    always_ff @(posedge clk) begin b3_t39_lwe <= ld_v && ld_iq >= 14'd13182 && ld_iq < 14'd13310; b3_t39_lwa <= 7'(ld_iq - 14'd13182); b3_t39_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab39 b3_t39_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t39_lwe), .wa(b3_t39_lwa), .wcol(1'b0), .wd(b3_t39_lwd), .q0(b3_t39));
    logic [31:0] b3_t40;
    logic b3_t40_lwe; logic [6:0] b3_t40_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t40_lwd;
    always_ff @(posedge clk) begin b3_t40_lwe <= ld_v && ld_iq >= 14'd13310 && ld_iq < 14'd13438; b3_t40_lwa <= 7'(ld_iq - 14'd13310); b3_t40_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab40 b3_t40_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t40_lwe), .wa(b3_t40_lwa), .wcol(1'b0), .wd(b3_t40_lwd), .q0(b3_t40));
    logic [31:0] b3_t41;
    logic b3_t41_lwe; logic [6:0] b3_t41_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t41_lwd;
    always_ff @(posedge clk) begin b3_t41_lwe <= ld_v && ld_iq >= 14'd13438 && ld_iq < 14'd13566; b3_t41_lwa <= 7'(ld_iq - 14'd13438); b3_t41_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab41 b3_t41_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t41_lwe), .wa(b3_t41_lwa), .wcol(1'b0), .wd(b3_t41_lwd), .q0(b3_t41));
    logic [31:0] b3_t42;
    logic b3_t42_lwe; logic [6:0] b3_t42_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t42_lwd;
    always_ff @(posedge clk) begin b3_t42_lwe <= ld_v && ld_iq >= 14'd13566 && ld_iq < 14'd13694; b3_t42_lwa <= 7'(ld_iq - 14'd13566); b3_t42_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab42 b3_t42_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t42_lwe), .wa(b3_t42_lwa), .wcol(1'b0), .wd(b3_t42_lwd), .q0(b3_t42));
    logic [31:0] b3_t43;
    logic b3_t43_lwe; logic [6:0] b3_t43_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t43_lwd;
    always_ff @(posedge clk) begin b3_t43_lwe <= ld_v && ld_iq >= 14'd13694 && ld_iq < 14'd13822; b3_t43_lwa <= 7'(ld_iq - 14'd13694); b3_t43_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab43 b3_t43_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t43_lwe), .wa(b3_t43_lwa), .wcol(1'b0), .wd(b3_t43_lwd), .q0(b3_t43));
    logic [31:0] b3_t44;
    logic b3_t44_lwe; logic [6:0] b3_t44_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t44_lwd;
    always_ff @(posedge clk) begin b3_t44_lwe <= ld_v && ld_iq >= 14'd13822 && ld_iq < 14'd13950; b3_t44_lwa <= 7'(ld_iq - 14'd13822); b3_t44_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab44 b3_t44_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t44_lwe), .wa(b3_t44_lwa), .wcol(1'b0), .wd(b3_t44_lwd), .q0(b3_t44));
    logic [31:0] b3_t45;
    logic b3_t45_lwe; logic [6:0] b3_t45_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t45_lwd;
    always_ff @(posedge clk) begin b3_t45_lwe <= ld_v && ld_iq >= 14'd13950 && ld_iq < 14'd14078; b3_t45_lwa <= 7'(ld_iq - 14'd13950); b3_t45_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab45 b3_t45_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t45_lwe), .wa(b3_t45_lwa), .wcol(1'b0), .wd(b3_t45_lwd), .q0(b3_t45));
    logic [31:0] b3_t46;
    logic b3_t46_lwe; logic [6:0] b3_t46_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t46_lwd;
    always_ff @(posedge clk) begin b3_t46_lwe <= ld_v && ld_iq >= 14'd14078 && ld_iq < 14'd14206; b3_t46_lwa <= 7'(ld_iq - 14'd14078); b3_t46_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab46 b3_t46_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t46_lwe), .wa(b3_t46_lwa), .wcol(1'b0), .wd(b3_t46_lwd), .q0(b3_t46));
    logic [31:0] b3_t47;
    logic b3_t47_lwe; logic [6:0] b3_t47_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t47_lwd;
    always_ff @(posedge clk) begin b3_t47_lwe <= ld_v && ld_iq >= 14'd14206 && ld_iq < 14'd14334; b3_t47_lwa <= 7'(ld_iq - 14'd14206); b3_t47_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab47 b3_t47_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t47_lwe), .wa(b3_t47_lwa), .wcol(1'b0), .wd(b3_t47_lwd), .q0(b3_t47));
    logic [31:0] b3_t48;
    logic b3_t48_lwe; logic [6:0] b3_t48_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t48_lwd;
    always_ff @(posedge clk) begin b3_t48_lwe <= ld_v && ld_iq >= 14'd14334 && ld_iq < 14'd14462; b3_t48_lwa <= 7'(ld_iq - 14'd14334); b3_t48_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab48 b3_t48_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t48_lwe), .wa(b3_t48_lwa), .wcol(1'b0), .wd(b3_t48_lwd), .q0(b3_t48));
    logic [31:0] b3_t49;
    logic b3_t49_lwe; logic [6:0] b3_t49_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t49_lwd;
    always_ff @(posedge clk) begin b3_t49_lwe <= ld_v && ld_iq >= 14'd14462 && ld_iq < 14'd14590; b3_t49_lwa <= 7'(ld_iq - 14'd14462); b3_t49_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab49 b3_t49_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t49_lwe), .wa(b3_t49_lwa), .wcol(1'b0), .wd(b3_t49_lwd), .q0(b3_t49));
    logic [31:0] b3_t50;
    logic b3_t50_lwe; logic [6:0] b3_t50_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t50_lwd;
    always_ff @(posedge clk) begin b3_t50_lwe <= ld_v && ld_iq >= 14'd14590 && ld_iq < 14'd14718; b3_t50_lwa <= 7'(ld_iq - 14'd14590); b3_t50_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab50 b3_t50_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t50_lwe), .wa(b3_t50_lwa), .wcol(1'b0), .wd(b3_t50_lwd), .q0(b3_t50));
    logic [31:0] b3_t51;
    logic b3_t51_lwe; logic [6:0] b3_t51_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t51_lwd;
    always_ff @(posedge clk) begin b3_t51_lwe <= ld_v && ld_iq >= 14'd14718 && ld_iq < 14'd14846; b3_t51_lwa <= 7'(ld_iq - 14'd14718); b3_t51_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab51 b3_t51_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t51_lwe), .wa(b3_t51_lwa), .wcol(1'b0), .wd(b3_t51_lwd), .q0(b3_t51));
    logic [31:0] b3_t52;
    logic b3_t52_lwe; logic [6:0] b3_t52_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t52_lwd;
    always_ff @(posedge clk) begin b3_t52_lwe <= ld_v && ld_iq >= 14'd14846 && ld_iq < 14'd14974; b3_t52_lwa <= 7'(ld_iq - 14'd14846); b3_t52_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab52 b3_t52_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t52_lwe), .wa(b3_t52_lwa), .wcol(1'b0), .wd(b3_t52_lwd), .q0(b3_t52));
    logic [31:0] b3_t53;
    logic b3_t53_lwe; logic [6:0] b3_t53_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t53_lwd;
    always_ff @(posedge clk) begin b3_t53_lwe <= ld_v && ld_iq >= 14'd14974 && ld_iq < 14'd15102; b3_t53_lwa <= 7'(ld_iq - 14'd14974); b3_t53_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab53 b3_t53_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t53_lwe), .wa(b3_t53_lwa), .wcol(1'b0), .wd(b3_t53_lwd), .q0(b3_t53));
    logic [31:0] b3_t54;
    logic b3_t54_lwe; logic [6:0] b3_t54_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t54_lwd;
    always_ff @(posedge clk) begin b3_t54_lwe <= ld_v && ld_iq >= 14'd15102 && ld_iq < 14'd15230; b3_t54_lwa <= 7'(ld_iq - 14'd15102); b3_t54_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab54 b3_t54_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t54_lwe), .wa(b3_t54_lwa), .wcol(1'b0), .wd(b3_t54_lwd), .q0(b3_t54));
    logic [31:0] b3_t55;
    logic b3_t55_lwe; logic [6:0] b3_t55_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t55_lwd;
    always_ff @(posedge clk) begin b3_t55_lwe <= ld_v && ld_iq >= 14'd15230 && ld_iq < 14'd15358; b3_t55_lwa <= 7'(ld_iq - 14'd15230); b3_t55_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab55 b3_t55_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t55_lwe), .wa(b3_t55_lwa), .wcol(1'b0), .wd(b3_t55_lwd), .q0(b3_t55));
    logic [31:0] b3_t56;
    logic b3_t56_lwe; logic [6:0] b3_t56_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t56_lwd;
    always_ff @(posedge clk) begin b3_t56_lwe <= ld_v && ld_iq >= 14'd15358 && ld_iq < 14'd15486; b3_t56_lwa <= 7'(ld_iq - 14'd15358); b3_t56_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab56 b3_t56_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t56_lwe), .wa(b3_t56_lwa), .wcol(1'b0), .wd(b3_t56_lwd), .q0(b3_t56));
    logic [31:0] b3_t57;
    logic b3_t57_lwe; logic [6:0] b3_t57_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t57_lwd;
    always_ff @(posedge clk) begin b3_t57_lwe <= ld_v && ld_iq >= 14'd15486 && ld_iq < 14'd15614; b3_t57_lwa <= 7'(ld_iq - 14'd15486); b3_t57_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab57 b3_t57_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t57_lwe), .wa(b3_t57_lwa), .wcol(1'b0), .wd(b3_t57_lwd), .q0(b3_t57));
    logic [31:0] b3_t58;
    logic b3_t58_lwe; logic [6:0] b3_t58_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t58_lwd;
    always_ff @(posedge clk) begin b3_t58_lwe <= ld_v && ld_iq >= 14'd15614 && ld_iq < 14'd15742; b3_t58_lwa <= 7'(ld_iq - 14'd15614); b3_t58_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab58 b3_t58_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t58_lwe), .wa(b3_t58_lwa), .wcol(1'b0), .wd(b3_t58_lwd), .q0(b3_t58));
    logic [31:0] b3_t59;
    logic b3_t59_lwe; logic [6:0] b3_t59_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t59_lwd;
    always_ff @(posedge clk) begin b3_t59_lwe <= ld_v && ld_iq >= 14'd15742 && ld_iq < 14'd15870; b3_t59_lwa <= 7'(ld_iq - 14'd15742); b3_t59_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab59 b3_t59_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t59_lwe), .wa(b3_t59_lwa), .wcol(1'b0), .wd(b3_t59_lwd), .q0(b3_t59));
    logic [31:0] b3_t60;
    logic b3_t60_lwe; logic [6:0] b3_t60_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t60_lwd;
    always_ff @(posedge clk) begin b3_t60_lwe <= ld_v && ld_iq >= 14'd15870 && ld_iq < 14'd15998; b3_t60_lwa <= 7'(ld_iq - 14'd15870); b3_t60_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab60 b3_t60_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t60_lwe), .wa(b3_t60_lwa), .wcol(1'b0), .wd(b3_t60_lwd), .q0(b3_t60));
    logic [31:0] b3_t61;
    logic b3_t61_lwe; logic [6:0] b3_t61_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t61_lwd;
    always_ff @(posedge clk) begin b3_t61_lwe <= ld_v && ld_iq >= 14'd15998 && ld_iq < 14'd16126; b3_t61_lwa <= 7'(ld_iq - 14'd15998); b3_t61_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab61 b3_t61_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t61_lwe), .wa(b3_t61_lwa), .wcol(1'b0), .wd(b3_t61_lwd), .q0(b3_t61));
    logic [31:0] b3_t62;
    logic b3_t62_lwe; logic [6:0] b3_t62_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t62_lwd;
    always_ff @(posedge clk) begin b3_t62_lwe <= ld_v && ld_iq >= 14'd16126 && ld_iq < 14'd16254; b3_t62_lwa <= 7'(ld_iq - 14'd16126); b3_t62_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab62 b3_t62_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t62_lwe), .wa(b3_t62_lwa), .wcol(1'b0), .wd(b3_t62_lwd), .q0(b3_t62));
    logic [31:0] b3_t63;
    logic b3_t63_lwe; logic [6:0] b3_t63_lwa; (* equivalent_register_removal = "no" *) logic [31:0] b3_t63_lwd;
    always_ff @(posedge clk) begin b3_t63_lwe <= ld_v && ld_iq >= 14'd16254 && ld_iq < 14'd16382; b3_t63_lwa <= 7'(ld_iq - 14'd16254); b3_t63_lwd <= ld_d[31:0]; end
    MS_N12_q32_P64_tpm_tw2_tab63 b3_t63_i (.clk(clk), .addr({b2_tag[0], b3_cnt[5], b3_cnt[4], b3_cnt[3], b3_cnt[2], b3_cnt[1], b3_cnt[0]}), .we(b3_t63_lwe), .wa(b3_t63_lwa), .wcol(1'b0), .wd(b3_t63_lwd), .q0(b3_t63));
    logic [31:0] b3_l0_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l0_a_i (.clk(clk), .din(b2_c0_y0), .dout(b3_l0_a));
    logic [31:0] b3_l0_p;
    MS_N12_q32_P64_tpm_twmul b3_l0_mul (.clk(clk), .A(b3_l0_a), .B(b3_t0), .QH(QH[15:0]), .P(b3_l0_p));
    logic [31:0] b3_l1_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l1_a_i (.clk(clk), .din(b2_c0_y1), .dout(b3_l1_a));
    logic [31:0] b3_l1_p;
    MS_N12_q32_P64_tpm_twmul b3_l1_mul (.clk(clk), .A(b3_l1_a), .B(b3_t1), .QH(QH[15:0]), .P(b3_l1_p));
    logic [31:0] b3_l2_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l2_a_i (.clk(clk), .din(b2_c0_y2), .dout(b3_l2_a));
    logic [31:0] b3_l2_p;
    MS_N12_q32_P64_tpm_twmul b3_l2_mul (.clk(clk), .A(b3_l2_a), .B(b3_t2), .QH(QH[15:0]), .P(b3_l2_p));
    logic [31:0] b3_l3_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l3_a_i (.clk(clk), .din(b2_c0_y3), .dout(b3_l3_a));
    logic [31:0] b3_l3_p;
    MS_N12_q32_P64_tpm_twmul b3_l3_mul (.clk(clk), .A(b3_l3_a), .B(b3_t3), .QH(QH[15:0]), .P(b3_l3_p));
    logic [31:0] b3_l4_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l4_a_i (.clk(clk), .din(b2_c0_y4), .dout(b3_l4_a));
    logic [31:0] b3_l4_p;
    MS_N12_q32_P64_tpm_twmul b3_l4_mul (.clk(clk), .A(b3_l4_a), .B(b3_t4), .QH(QH[15:0]), .P(b3_l4_p));
    logic [31:0] b3_l5_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l5_a_i (.clk(clk), .din(b2_c0_y5), .dout(b3_l5_a));
    logic [31:0] b3_l5_p;
    MS_N12_q32_P64_tpm_twmul b3_l5_mul (.clk(clk), .A(b3_l5_a), .B(b3_t5), .QH(QH[15:0]), .P(b3_l5_p));
    logic [31:0] b3_l6_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l6_a_i (.clk(clk), .din(b2_c0_y6), .dout(b3_l6_a));
    logic [31:0] b3_l6_p;
    MS_N12_q32_P64_tpm_twmul b3_l6_mul (.clk(clk), .A(b3_l6_a), .B(b3_t6), .QH(QH[15:0]), .P(b3_l6_p));
    logic [31:0] b3_l7_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l7_a_i (.clk(clk), .din(b2_c0_y7), .dout(b3_l7_a));
    logic [31:0] b3_l7_p;
    MS_N12_q32_P64_tpm_twmul b3_l7_mul (.clk(clk), .A(b3_l7_a), .B(b3_t7), .QH(QH[15:0]), .P(b3_l7_p));
    logic [31:0] b3_l8_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l8_a_i (.clk(clk), .din(b2_c0_y8), .dout(b3_l8_a));
    logic [31:0] b3_l8_p;
    MS_N12_q32_P64_tpm_twmul b3_l8_mul (.clk(clk), .A(b3_l8_a), .B(b3_t8), .QH(QH[15:0]), .P(b3_l8_p));
    logic [31:0] b3_l9_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l9_a_i (.clk(clk), .din(b2_c0_y9), .dout(b3_l9_a));
    logic [31:0] b3_l9_p;
    MS_N12_q32_P64_tpm_twmul b3_l9_mul (.clk(clk), .A(b3_l9_a), .B(b3_t9), .QH(QH[15:0]), .P(b3_l9_p));
    logic [31:0] b3_l10_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l10_a_i (.clk(clk), .din(b2_c0_y10), .dout(b3_l10_a));
    logic [31:0] b3_l10_p;
    MS_N12_q32_P64_tpm_twmul b3_l10_mul (.clk(clk), .A(b3_l10_a), .B(b3_t10), .QH(QH[15:0]), .P(b3_l10_p));
    logic [31:0] b3_l11_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l11_a_i (.clk(clk), .din(b2_c0_y11), .dout(b3_l11_a));
    logic [31:0] b3_l11_p;
    MS_N12_q32_P64_tpm_twmul b3_l11_mul (.clk(clk), .A(b3_l11_a), .B(b3_t11), .QH(QH[15:0]), .P(b3_l11_p));
    logic [31:0] b3_l12_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l12_a_i (.clk(clk), .din(b2_c0_y12), .dout(b3_l12_a));
    logic [31:0] b3_l12_p;
    MS_N12_q32_P64_tpm_twmul b3_l12_mul (.clk(clk), .A(b3_l12_a), .B(b3_t12), .QH(QH[15:0]), .P(b3_l12_p));
    logic [31:0] b3_l13_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l13_a_i (.clk(clk), .din(b2_c0_y13), .dout(b3_l13_a));
    logic [31:0] b3_l13_p;
    MS_N12_q32_P64_tpm_twmul b3_l13_mul (.clk(clk), .A(b3_l13_a), .B(b3_t13), .QH(QH[15:0]), .P(b3_l13_p));
    logic [31:0] b3_l14_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l14_a_i (.clk(clk), .din(b2_c0_y14), .dout(b3_l14_a));
    logic [31:0] b3_l14_p;
    MS_N12_q32_P64_tpm_twmul b3_l14_mul (.clk(clk), .A(b3_l14_a), .B(b3_t14), .QH(QH[15:0]), .P(b3_l14_p));
    logic [31:0] b3_l15_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l15_a_i (.clk(clk), .din(b2_c0_y15), .dout(b3_l15_a));
    logic [31:0] b3_l15_p;
    MS_N12_q32_P64_tpm_twmul b3_l15_mul (.clk(clk), .A(b3_l15_a), .B(b3_t15), .QH(QH[15:0]), .P(b3_l15_p));
    logic [31:0] b3_l16_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l16_a_i (.clk(clk), .din(b2_c0_y16), .dout(b3_l16_a));
    logic [31:0] b3_l16_p;
    MS_N12_q32_P64_tpm_twmul b3_l16_mul (.clk(clk), .A(b3_l16_a), .B(b3_t16), .QH(QH[15:0]), .P(b3_l16_p));
    logic [31:0] b3_l17_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l17_a_i (.clk(clk), .din(b2_c0_y17), .dout(b3_l17_a));
    logic [31:0] b3_l17_p;
    MS_N12_q32_P64_tpm_twmul b3_l17_mul (.clk(clk), .A(b3_l17_a), .B(b3_t17), .QH(QH[15:0]), .P(b3_l17_p));
    logic [31:0] b3_l18_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l18_a_i (.clk(clk), .din(b2_c0_y18), .dout(b3_l18_a));
    logic [31:0] b3_l18_p;
    MS_N12_q32_P64_tpm_twmul b3_l18_mul (.clk(clk), .A(b3_l18_a), .B(b3_t18), .QH(QH[15:0]), .P(b3_l18_p));
    logic [31:0] b3_l19_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l19_a_i (.clk(clk), .din(b2_c0_y19), .dout(b3_l19_a));
    logic [31:0] b3_l19_p;
    MS_N12_q32_P64_tpm_twmul b3_l19_mul (.clk(clk), .A(b3_l19_a), .B(b3_t19), .QH(QH[15:0]), .P(b3_l19_p));
    logic [31:0] b3_l20_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l20_a_i (.clk(clk), .din(b2_c0_y20), .dout(b3_l20_a));
    logic [31:0] b3_l20_p;
    MS_N12_q32_P64_tpm_twmul b3_l20_mul (.clk(clk), .A(b3_l20_a), .B(b3_t20), .QH(QH[15:0]), .P(b3_l20_p));
    logic [31:0] b3_l21_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l21_a_i (.clk(clk), .din(b2_c0_y21), .dout(b3_l21_a));
    logic [31:0] b3_l21_p;
    MS_N12_q32_P64_tpm_twmul b3_l21_mul (.clk(clk), .A(b3_l21_a), .B(b3_t21), .QH(QH[15:0]), .P(b3_l21_p));
    logic [31:0] b3_l22_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l22_a_i (.clk(clk), .din(b2_c0_y22), .dout(b3_l22_a));
    logic [31:0] b3_l22_p;
    MS_N12_q32_P64_tpm_twmul b3_l22_mul (.clk(clk), .A(b3_l22_a), .B(b3_t22), .QH(QH[15:0]), .P(b3_l22_p));
    logic [31:0] b3_l23_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l23_a_i (.clk(clk), .din(b2_c0_y23), .dout(b3_l23_a));
    logic [31:0] b3_l23_p;
    MS_N12_q32_P64_tpm_twmul b3_l23_mul (.clk(clk), .A(b3_l23_a), .B(b3_t23), .QH(QH[15:0]), .P(b3_l23_p));
    logic [31:0] b3_l24_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l24_a_i (.clk(clk), .din(b2_c0_y24), .dout(b3_l24_a));
    logic [31:0] b3_l24_p;
    MS_N12_q32_P64_tpm_twmul b3_l24_mul (.clk(clk), .A(b3_l24_a), .B(b3_t24), .QH(QH[15:0]), .P(b3_l24_p));
    logic [31:0] b3_l25_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l25_a_i (.clk(clk), .din(b2_c0_y25), .dout(b3_l25_a));
    logic [31:0] b3_l25_p;
    MS_N12_q32_P64_tpm_twmul b3_l25_mul (.clk(clk), .A(b3_l25_a), .B(b3_t25), .QH(QH[15:0]), .P(b3_l25_p));
    logic [31:0] b3_l26_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l26_a_i (.clk(clk), .din(b2_c0_y26), .dout(b3_l26_a));
    logic [31:0] b3_l26_p;
    MS_N12_q32_P64_tpm_twmul b3_l26_mul (.clk(clk), .A(b3_l26_a), .B(b3_t26), .QH(QH[15:0]), .P(b3_l26_p));
    logic [31:0] b3_l27_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l27_a_i (.clk(clk), .din(b2_c0_y27), .dout(b3_l27_a));
    logic [31:0] b3_l27_p;
    MS_N12_q32_P64_tpm_twmul b3_l27_mul (.clk(clk), .A(b3_l27_a), .B(b3_t27), .QH(QH[15:0]), .P(b3_l27_p));
    logic [31:0] b3_l28_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l28_a_i (.clk(clk), .din(b2_c0_y28), .dout(b3_l28_a));
    logic [31:0] b3_l28_p;
    MS_N12_q32_P64_tpm_twmul b3_l28_mul (.clk(clk), .A(b3_l28_a), .B(b3_t28), .QH(QH[15:0]), .P(b3_l28_p));
    logic [31:0] b3_l29_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l29_a_i (.clk(clk), .din(b2_c0_y29), .dout(b3_l29_a));
    logic [31:0] b3_l29_p;
    MS_N12_q32_P64_tpm_twmul b3_l29_mul (.clk(clk), .A(b3_l29_a), .B(b3_t29), .QH(QH[15:0]), .P(b3_l29_p));
    logic [31:0] b3_l30_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l30_a_i (.clk(clk), .din(b2_c0_y30), .dout(b3_l30_a));
    logic [31:0] b3_l30_p;
    MS_N12_q32_P64_tpm_twmul b3_l30_mul (.clk(clk), .A(b3_l30_a), .B(b3_t30), .QH(QH[15:0]), .P(b3_l30_p));
    logic [31:0] b3_l31_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l31_a_i (.clk(clk), .din(b2_c0_y31), .dout(b3_l31_a));
    logic [31:0] b3_l31_p;
    MS_N12_q32_P64_tpm_twmul b3_l31_mul (.clk(clk), .A(b3_l31_a), .B(b3_t31), .QH(QH[15:0]), .P(b3_l31_p));
    logic [31:0] b3_l32_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l32_a_i (.clk(clk), .din(b2_c0_y32), .dout(b3_l32_a));
    logic [31:0] b3_l32_p;
    MS_N12_q32_P64_tpm_twmul b3_l32_mul (.clk(clk), .A(b3_l32_a), .B(b3_t32), .QH(QH[15:0]), .P(b3_l32_p));
    logic [31:0] b3_l33_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l33_a_i (.clk(clk), .din(b2_c0_y33), .dout(b3_l33_a));
    logic [31:0] b3_l33_p;
    MS_N12_q32_P64_tpm_twmul b3_l33_mul (.clk(clk), .A(b3_l33_a), .B(b3_t33), .QH(QH[15:0]), .P(b3_l33_p));
    logic [31:0] b3_l34_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l34_a_i (.clk(clk), .din(b2_c0_y34), .dout(b3_l34_a));
    logic [31:0] b3_l34_p;
    MS_N12_q32_P64_tpm_twmul b3_l34_mul (.clk(clk), .A(b3_l34_a), .B(b3_t34), .QH(QH[15:0]), .P(b3_l34_p));
    logic [31:0] b3_l35_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l35_a_i (.clk(clk), .din(b2_c0_y35), .dout(b3_l35_a));
    logic [31:0] b3_l35_p;
    MS_N12_q32_P64_tpm_twmul b3_l35_mul (.clk(clk), .A(b3_l35_a), .B(b3_t35), .QH(QH[15:0]), .P(b3_l35_p));
    logic [31:0] b3_l36_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l36_a_i (.clk(clk), .din(b2_c0_y36), .dout(b3_l36_a));
    logic [31:0] b3_l36_p;
    MS_N12_q32_P64_tpm_twmul b3_l36_mul (.clk(clk), .A(b3_l36_a), .B(b3_t36), .QH(QH[15:0]), .P(b3_l36_p));
    logic [31:0] b3_l37_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l37_a_i (.clk(clk), .din(b2_c0_y37), .dout(b3_l37_a));
    logic [31:0] b3_l37_p;
    MS_N12_q32_P64_tpm_twmul b3_l37_mul (.clk(clk), .A(b3_l37_a), .B(b3_t37), .QH(QH[15:0]), .P(b3_l37_p));
    logic [31:0] b3_l38_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l38_a_i (.clk(clk), .din(b2_c0_y38), .dout(b3_l38_a));
    logic [31:0] b3_l38_p;
    MS_N12_q32_P64_tpm_twmul b3_l38_mul (.clk(clk), .A(b3_l38_a), .B(b3_t38), .QH(QH[15:0]), .P(b3_l38_p));
    logic [31:0] b3_l39_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l39_a_i (.clk(clk), .din(b2_c0_y39), .dout(b3_l39_a));
    logic [31:0] b3_l39_p;
    MS_N12_q32_P64_tpm_twmul b3_l39_mul (.clk(clk), .A(b3_l39_a), .B(b3_t39), .QH(QH[15:0]), .P(b3_l39_p));
    logic [31:0] b3_l40_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l40_a_i (.clk(clk), .din(b2_c0_y40), .dout(b3_l40_a));
    logic [31:0] b3_l40_p;
    MS_N12_q32_P64_tpm_twmul b3_l40_mul (.clk(clk), .A(b3_l40_a), .B(b3_t40), .QH(QH[15:0]), .P(b3_l40_p));
    logic [31:0] b3_l41_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l41_a_i (.clk(clk), .din(b2_c0_y41), .dout(b3_l41_a));
    logic [31:0] b3_l41_p;
    MS_N12_q32_P64_tpm_twmul b3_l41_mul (.clk(clk), .A(b3_l41_a), .B(b3_t41), .QH(QH[15:0]), .P(b3_l41_p));
    logic [31:0] b3_l42_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l42_a_i (.clk(clk), .din(b2_c0_y42), .dout(b3_l42_a));
    logic [31:0] b3_l42_p;
    MS_N12_q32_P64_tpm_twmul b3_l42_mul (.clk(clk), .A(b3_l42_a), .B(b3_t42), .QH(QH[15:0]), .P(b3_l42_p));
    logic [31:0] b3_l43_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l43_a_i (.clk(clk), .din(b2_c0_y43), .dout(b3_l43_a));
    logic [31:0] b3_l43_p;
    MS_N12_q32_P64_tpm_twmul b3_l43_mul (.clk(clk), .A(b3_l43_a), .B(b3_t43), .QH(QH[15:0]), .P(b3_l43_p));
    logic [31:0] b3_l44_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l44_a_i (.clk(clk), .din(b2_c0_y44), .dout(b3_l44_a));
    logic [31:0] b3_l44_p;
    MS_N12_q32_P64_tpm_twmul b3_l44_mul (.clk(clk), .A(b3_l44_a), .B(b3_t44), .QH(QH[15:0]), .P(b3_l44_p));
    logic [31:0] b3_l45_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l45_a_i (.clk(clk), .din(b2_c0_y45), .dout(b3_l45_a));
    logic [31:0] b3_l45_p;
    MS_N12_q32_P64_tpm_twmul b3_l45_mul (.clk(clk), .A(b3_l45_a), .B(b3_t45), .QH(QH[15:0]), .P(b3_l45_p));
    logic [31:0] b3_l46_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l46_a_i (.clk(clk), .din(b2_c0_y46), .dout(b3_l46_a));
    logic [31:0] b3_l46_p;
    MS_N12_q32_P64_tpm_twmul b3_l46_mul (.clk(clk), .A(b3_l46_a), .B(b3_t46), .QH(QH[15:0]), .P(b3_l46_p));
    logic [31:0] b3_l47_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l47_a_i (.clk(clk), .din(b2_c0_y47), .dout(b3_l47_a));
    logic [31:0] b3_l47_p;
    MS_N12_q32_P64_tpm_twmul b3_l47_mul (.clk(clk), .A(b3_l47_a), .B(b3_t47), .QH(QH[15:0]), .P(b3_l47_p));
    logic [31:0] b3_l48_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l48_a_i (.clk(clk), .din(b2_c0_y48), .dout(b3_l48_a));
    logic [31:0] b3_l48_p;
    MS_N12_q32_P64_tpm_twmul b3_l48_mul (.clk(clk), .A(b3_l48_a), .B(b3_t48), .QH(QH[15:0]), .P(b3_l48_p));
    logic [31:0] b3_l49_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l49_a_i (.clk(clk), .din(b2_c0_y49), .dout(b3_l49_a));
    logic [31:0] b3_l49_p;
    MS_N12_q32_P64_tpm_twmul b3_l49_mul (.clk(clk), .A(b3_l49_a), .B(b3_t49), .QH(QH[15:0]), .P(b3_l49_p));
    logic [31:0] b3_l50_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l50_a_i (.clk(clk), .din(b2_c0_y50), .dout(b3_l50_a));
    logic [31:0] b3_l50_p;
    MS_N12_q32_P64_tpm_twmul b3_l50_mul (.clk(clk), .A(b3_l50_a), .B(b3_t50), .QH(QH[15:0]), .P(b3_l50_p));
    logic [31:0] b3_l51_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l51_a_i (.clk(clk), .din(b2_c0_y51), .dout(b3_l51_a));
    logic [31:0] b3_l51_p;
    MS_N12_q32_P64_tpm_twmul b3_l51_mul (.clk(clk), .A(b3_l51_a), .B(b3_t51), .QH(QH[15:0]), .P(b3_l51_p));
    logic [31:0] b3_l52_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l52_a_i (.clk(clk), .din(b2_c0_y52), .dout(b3_l52_a));
    logic [31:0] b3_l52_p;
    MS_N12_q32_P64_tpm_twmul b3_l52_mul (.clk(clk), .A(b3_l52_a), .B(b3_t52), .QH(QH[15:0]), .P(b3_l52_p));
    logic [31:0] b3_l53_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l53_a_i (.clk(clk), .din(b2_c0_y53), .dout(b3_l53_a));
    logic [31:0] b3_l53_p;
    MS_N12_q32_P64_tpm_twmul b3_l53_mul (.clk(clk), .A(b3_l53_a), .B(b3_t53), .QH(QH[15:0]), .P(b3_l53_p));
    logic [31:0] b3_l54_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l54_a_i (.clk(clk), .din(b2_c0_y54), .dout(b3_l54_a));
    logic [31:0] b3_l54_p;
    MS_N12_q32_P64_tpm_twmul b3_l54_mul (.clk(clk), .A(b3_l54_a), .B(b3_t54), .QH(QH[15:0]), .P(b3_l54_p));
    logic [31:0] b3_l55_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l55_a_i (.clk(clk), .din(b2_c0_y55), .dout(b3_l55_a));
    logic [31:0] b3_l55_p;
    MS_N12_q32_P64_tpm_twmul b3_l55_mul (.clk(clk), .A(b3_l55_a), .B(b3_t55), .QH(QH[15:0]), .P(b3_l55_p));
    logic [31:0] b3_l56_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l56_a_i (.clk(clk), .din(b2_c0_y56), .dout(b3_l56_a));
    logic [31:0] b3_l56_p;
    MS_N12_q32_P64_tpm_twmul b3_l56_mul (.clk(clk), .A(b3_l56_a), .B(b3_t56), .QH(QH[15:0]), .P(b3_l56_p));
    logic [31:0] b3_l57_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l57_a_i (.clk(clk), .din(b2_c0_y57), .dout(b3_l57_a));
    logic [31:0] b3_l57_p;
    MS_N12_q32_P64_tpm_twmul b3_l57_mul (.clk(clk), .A(b3_l57_a), .B(b3_t57), .QH(QH[15:0]), .P(b3_l57_p));
    logic [31:0] b3_l58_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l58_a_i (.clk(clk), .din(b2_c0_y58), .dout(b3_l58_a));
    logic [31:0] b3_l58_p;
    MS_N12_q32_P64_tpm_twmul b3_l58_mul (.clk(clk), .A(b3_l58_a), .B(b3_t58), .QH(QH[15:0]), .P(b3_l58_p));
    logic [31:0] b3_l59_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l59_a_i (.clk(clk), .din(b2_c0_y59), .dout(b3_l59_a));
    logic [31:0] b3_l59_p;
    MS_N12_q32_P64_tpm_twmul b3_l59_mul (.clk(clk), .A(b3_l59_a), .B(b3_t59), .QH(QH[15:0]), .P(b3_l59_p));
    logic [31:0] b3_l60_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l60_a_i (.clk(clk), .din(b2_c0_y60), .dout(b3_l60_a));
    logic [31:0] b3_l60_p;
    MS_N12_q32_P64_tpm_twmul b3_l60_mul (.clk(clk), .A(b3_l60_a), .B(b3_t60), .QH(QH[15:0]), .P(b3_l60_p));
    logic [31:0] b3_l61_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l61_a_i (.clk(clk), .din(b2_c0_y61), .dout(b3_l61_a));
    logic [31:0] b3_l61_p;
    MS_N12_q32_P64_tpm_twmul b3_l61_mul (.clk(clk), .A(b3_l61_a), .B(b3_t61), .QH(QH[15:0]), .P(b3_l61_p));
    logic [31:0] b3_l62_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l62_a_i (.clk(clk), .din(b2_c0_y62), .dout(b3_l62_a));
    logic [31:0] b3_l62_p;
    MS_N12_q32_P64_tpm_twmul b3_l62_mul (.clk(clk), .A(b3_l62_a), .B(b3_t62), .QH(QH[15:0]), .P(b3_l62_p));
    logic [31:0] b3_l63_a;
    MS_N12_q32_P64_tpm_dly_c #(.W(32), .D(2)) b3_l63_a_i (.clk(clk), .din(b2_c0_y63), .dout(b3_l63_a));
    logic [31:0] b3_l63_p;
    MS_N12_q32_P64_tpm_twmul b3_l63_mul (.clk(clk), .A(b3_l63_a), .B(b3_t63), .QH(QH[15:0]), .P(b3_l63_p));
    logic [11:0] b3_v_sr;
    always_ff @(posedge clk) b3_v_sr <= rst ? '0 : {b3_v_sr[10:0], b2_c0_v};
    logic b3_v; assign b3_v = b3_v_sr[11];
    logic [0:0] b3_tag;
    MS_N12_q32_P64_tpm_dly_c #(.W(1), .D(12)) b3_tag_i (.clk(clk), .din(b2_tag), .dout(b3_tag));
    assign out_valid = b3_v;
    assign dir_out = b3_tag[0];
    assign y_out_0 = b3_l0_p;
    assign y_out_1 = b3_l1_p;
    assign y_out_2 = b3_l2_p;
    assign y_out_3 = b3_l3_p;
    assign y_out_4 = b3_l4_p;
    assign y_out_5 = b3_l5_p;
    assign y_out_6 = b3_l6_p;
    assign y_out_7 = b3_l7_p;
    assign y_out_8 = b3_l8_p;
    assign y_out_9 = b3_l9_p;
    assign y_out_10 = b3_l10_p;
    assign y_out_11 = b3_l11_p;
    assign y_out_12 = b3_l12_p;
    assign y_out_13 = b3_l13_p;
    assign y_out_14 = b3_l14_p;
    assign y_out_15 = b3_l15_p;
    assign y_out_16 = b3_l16_p;
    assign y_out_17 = b3_l17_p;
    assign y_out_18 = b3_l18_p;
    assign y_out_19 = b3_l19_p;
    assign y_out_20 = b3_l20_p;
    assign y_out_21 = b3_l21_p;
    assign y_out_22 = b3_l22_p;
    assign y_out_23 = b3_l23_p;
    assign y_out_24 = b3_l24_p;
    assign y_out_25 = b3_l25_p;
    assign y_out_26 = b3_l26_p;
    assign y_out_27 = b3_l27_p;
    assign y_out_28 = b3_l28_p;
    assign y_out_29 = b3_l29_p;
    assign y_out_30 = b3_l30_p;
    assign y_out_31 = b3_l31_p;
    assign y_out_32 = b3_l32_p;
    assign y_out_33 = b3_l33_p;
    assign y_out_34 = b3_l34_p;
    assign y_out_35 = b3_l35_p;
    assign y_out_36 = b3_l36_p;
    assign y_out_37 = b3_l37_p;
    assign y_out_38 = b3_l38_p;
    assign y_out_39 = b3_l39_p;
    assign y_out_40 = b3_l40_p;
    assign y_out_41 = b3_l41_p;
    assign y_out_42 = b3_l42_p;
    assign y_out_43 = b3_l43_p;
    assign y_out_44 = b3_l44_p;
    assign y_out_45 = b3_l45_p;
    assign y_out_46 = b3_l46_p;
    assign y_out_47 = b3_l47_p;
    assign y_out_48 = b3_l48_p;
    assign y_out_49 = b3_l49_p;
    assign y_out_50 = b3_l50_p;
    assign y_out_51 = b3_l51_p;
    assign y_out_52 = b3_l52_p;
    assign y_out_53 = b3_l53_p;
    assign y_out_54 = b3_l54_p;
    assign y_out_55 = b3_l55_p;
    assign y_out_56 = b3_l56_p;
    assign y_out_57 = b3_l57_p;
    assign y_out_58 = b3_l58_p;
    assign y_out_59 = b3_l59_p;
    assign y_out_60 = b3_l60_p;
    assign y_out_61 = b3_l61_p;
    assign y_out_62 = b3_l62_p;
    assign y_out_63 = b3_l63_p;
endmodule
