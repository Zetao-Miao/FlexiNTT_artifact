`timescale 1ns / 1ps
// MS_N12_q32_P64_tpm_p0: fully pipelined NTT, n=64, one transform per cycle, latency 81, ports in natural / natural order
module MS_N12_q32_P64_tpm_p0 (
    input  logic clk,
    input  logic rst,
    input  logic in_valid,
    input  logic DIR,
    input  logic [15:0] QH,
    input  logic [31:0] QHALF,
    input  logic tw_rst,
    input  logic tw_wen,
    input  logic [31:0] tw_wdata,
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
    logic [31:0] c_y_0;
    logic [31:0] c_y_1;
    logic [31:0] c_y_2;
    logic [31:0] c_y_3;
    logic [31:0] c_y_4;
    logic [31:0] c_y_5;
    logic [31:0] c_y_6;
    logic [31:0] c_y_7;
    logic [31:0] c_y_8;
    logic [31:0] c_y_9;
    logic [31:0] c_y_10;
    logic [31:0] c_y_11;
    logic [31:0] c_y_12;
    logic [31:0] c_y_13;
    logic [31:0] c_y_14;
    logic [31:0] c_y_15;
    logic [31:0] c_y_16;
    logic [31:0] c_y_17;
    logic [31:0] c_y_18;
    logic [31:0] c_y_19;
    logic [31:0] c_y_20;
    logic [31:0] c_y_21;
    logic [31:0] c_y_22;
    logic [31:0] c_y_23;
    logic [31:0] c_y_24;
    logic [31:0] c_y_25;
    logic [31:0] c_y_26;
    logic [31:0] c_y_27;
    logic [31:0] c_y_28;
    logic [31:0] c_y_29;
    logic [31:0] c_y_30;
    logic [31:0] c_y_31;
    logic [31:0] c_y_32;
    logic [31:0] c_y_33;
    logic [31:0] c_y_34;
    logic [31:0] c_y_35;
    logic [31:0] c_y_36;
    logic [31:0] c_y_37;
    logic [31:0] c_y_38;
    logic [31:0] c_y_39;
    logic [31:0] c_y_40;
    logic [31:0] c_y_41;
    logic [31:0] c_y_42;
    logic [31:0] c_y_43;
    logic [31:0] c_y_44;
    logic [31:0] c_y_45;
    logic [31:0] c_y_46;
    logic [31:0] c_y_47;
    logic [31:0] c_y_48;
    logic [31:0] c_y_49;
    logic [31:0] c_y_50;
    logic [31:0] c_y_51;
    logic [31:0] c_y_52;
    logic [31:0] c_y_53;
    logic [31:0] c_y_54;
    logic [31:0] c_y_55;
    logic [31:0] c_y_56;
    logic [31:0] c_y_57;
    logic [31:0] c_y_58;
    logic [31:0] c_y_59;
    logic [31:0] c_y_60;
    logic [31:0] c_y_61;
    logic [31:0] c_y_62;
    logic [31:0] c_y_63;
    MS_N12_q32_P64_tpm_p0_core u_core (
        .clk(clk),
        .rst(rst),
        .DIR(DIR),
        .QH(QH),
        .QHALF(QHALF),
        .tw_rst(tw_rst),
        .tw_wen(tw_wen),
        .tw_wdata(tw_wdata),
        .x_in_0(x_in_0),
        .x_in_1(x_in_32),
        .x_in_2(x_in_16),
        .x_in_3(x_in_48),
        .x_in_4(x_in_8),
        .x_in_5(x_in_40),
        .x_in_6(x_in_24),
        .x_in_7(x_in_56),
        .x_in_8(x_in_4),
        .x_in_9(x_in_36),
        .x_in_10(x_in_20),
        .x_in_11(x_in_52),
        .x_in_12(x_in_12),
        .x_in_13(x_in_44),
        .x_in_14(x_in_28),
        .x_in_15(x_in_60),
        .x_in_16(x_in_2),
        .x_in_17(x_in_34),
        .x_in_18(x_in_18),
        .x_in_19(x_in_50),
        .x_in_20(x_in_10),
        .x_in_21(x_in_42),
        .x_in_22(x_in_26),
        .x_in_23(x_in_58),
        .x_in_24(x_in_6),
        .x_in_25(x_in_38),
        .x_in_26(x_in_22),
        .x_in_27(x_in_54),
        .x_in_28(x_in_14),
        .x_in_29(x_in_46),
        .x_in_30(x_in_30),
        .x_in_31(x_in_62),
        .x_in_32(x_in_1),
        .x_in_33(x_in_33),
        .x_in_34(x_in_17),
        .x_in_35(x_in_49),
        .x_in_36(x_in_9),
        .x_in_37(x_in_41),
        .x_in_38(x_in_25),
        .x_in_39(x_in_57),
        .x_in_40(x_in_5),
        .x_in_41(x_in_37),
        .x_in_42(x_in_21),
        .x_in_43(x_in_53),
        .x_in_44(x_in_13),
        .x_in_45(x_in_45),
        .x_in_46(x_in_29),
        .x_in_47(x_in_61),
        .x_in_48(x_in_3),
        .x_in_49(x_in_35),
        .x_in_50(x_in_19),
        .x_in_51(x_in_51),
        .x_in_52(x_in_11),
        .x_in_53(x_in_43),
        .x_in_54(x_in_27),
        .x_in_55(x_in_59),
        .x_in_56(x_in_7),
        .x_in_57(x_in_39),
        .x_in_58(x_in_23),
        .x_in_59(x_in_55),
        .x_in_60(x_in_15),
        .x_in_61(x_in_47),
        .x_in_62(x_in_31),
        .x_in_63(x_in_63),
        .y_out_0(c_y_0),
        .y_out_1(c_y_1),
        .y_out_2(c_y_2),
        .y_out_3(c_y_3),
        .y_out_4(c_y_4),
        .y_out_5(c_y_5),
        .y_out_6(c_y_6),
        .y_out_7(c_y_7),
        .y_out_8(c_y_8),
        .y_out_9(c_y_9),
        .y_out_10(c_y_10),
        .y_out_11(c_y_11),
        .y_out_12(c_y_12),
        .y_out_13(c_y_13),
        .y_out_14(c_y_14),
        .y_out_15(c_y_15),
        .y_out_16(c_y_16),
        .y_out_17(c_y_17),
        .y_out_18(c_y_18),
        .y_out_19(c_y_19),
        .y_out_20(c_y_20),
        .y_out_21(c_y_21),
        .y_out_22(c_y_22),
        .y_out_23(c_y_23),
        .y_out_24(c_y_24),
        .y_out_25(c_y_25),
        .y_out_26(c_y_26),
        .y_out_27(c_y_27),
        .y_out_28(c_y_28),
        .y_out_29(c_y_29),
        .y_out_30(c_y_30),
        .y_out_31(c_y_31),
        .y_out_32(c_y_32),
        .y_out_33(c_y_33),
        .y_out_34(c_y_34),
        .y_out_35(c_y_35),
        .y_out_36(c_y_36),
        .y_out_37(c_y_37),
        .y_out_38(c_y_38),
        .y_out_39(c_y_39),
        .y_out_40(c_y_40),
        .y_out_41(c_y_41),
        .y_out_42(c_y_42),
        .y_out_43(c_y_43),
        .y_out_44(c_y_44),
        .y_out_45(c_y_45),
        .y_out_46(c_y_46),
        .y_out_47(c_y_47),
        .y_out_48(c_y_48),
        .y_out_49(c_y_49),
        .y_out_50(c_y_50),
        .y_out_51(c_y_51),
        .y_out_52(c_y_52),
        .y_out_53(c_y_53),
        .y_out_54(c_y_54),
        .y_out_55(c_y_55),
        .y_out_56(c_y_56),
        .y_out_57(c_y_57),
        .y_out_58(c_y_58),
        .y_out_59(c_y_59),
        .y_out_60(c_y_60),
        .y_out_61(c_y_61),
        .y_out_62(c_y_62),
        .y_out_63(c_y_63));
    assign y_out_0 = c_y_0;
    assign y_out_1 = c_y_1;
    assign y_out_2 = c_y_2;
    assign y_out_3 = c_y_3;
    assign y_out_4 = c_y_4;
    assign y_out_5 = c_y_5;
    assign y_out_6 = c_y_6;
    assign y_out_7 = c_y_7;
    assign y_out_8 = c_y_8;
    assign y_out_9 = c_y_9;
    assign y_out_10 = c_y_10;
    assign y_out_11 = c_y_11;
    assign y_out_12 = c_y_12;
    assign y_out_13 = c_y_13;
    assign y_out_14 = c_y_14;
    assign y_out_15 = c_y_15;
    assign y_out_16 = c_y_16;
    assign y_out_17 = c_y_17;
    assign y_out_18 = c_y_18;
    assign y_out_19 = c_y_19;
    assign y_out_20 = c_y_20;
    assign y_out_21 = c_y_21;
    assign y_out_22 = c_y_22;
    assign y_out_23 = c_y_23;
    assign y_out_24 = c_y_24;
    assign y_out_25 = c_y_25;
    assign y_out_26 = c_y_26;
    assign y_out_27 = c_y_27;
    assign y_out_28 = c_y_28;
    assign y_out_29 = c_y_29;
    assign y_out_30 = c_y_30;
    assign y_out_31 = c_y_31;
    assign y_out_32 = c_y_32;
    assign y_out_33 = c_y_33;
    assign y_out_34 = c_y_34;
    assign y_out_35 = c_y_35;
    assign y_out_36 = c_y_36;
    assign y_out_37 = c_y_37;
    assign y_out_38 = c_y_38;
    assign y_out_39 = c_y_39;
    assign y_out_40 = c_y_40;
    assign y_out_41 = c_y_41;
    assign y_out_42 = c_y_42;
    assign y_out_43 = c_y_43;
    assign y_out_44 = c_y_44;
    assign y_out_45 = c_y_45;
    assign y_out_46 = c_y_46;
    assign y_out_47 = c_y_47;
    assign y_out_48 = c_y_48;
    assign y_out_49 = c_y_49;
    assign y_out_50 = c_y_50;
    assign y_out_51 = c_y_51;
    assign y_out_52 = c_y_52;
    assign y_out_53 = c_y_53;
    assign y_out_54 = c_y_54;
    assign y_out_55 = c_y_55;
    assign y_out_56 = c_y_56;
    assign y_out_57 = c_y_57;
    assign y_out_58 = c_y_58;
    assign y_out_59 = c_y_59;
    assign y_out_60 = c_y_60;
    assign y_out_61 = c_y_61;
    assign y_out_62 = c_y_62;
    assign y_out_63 = c_y_63;
    logic [80:0] v_sr;
    always_ff @(posedge clk) v_sr <= rst ? '0 : {v_sr[79:0], in_valid};
    assign out_valid = v_sr[80];
    logic [0:0] t_sr [81];
    always_ff @(posedge clk) begin t_sr[0] <= DIR; for (int i = 1; i < 81; i++) t_sr[i] <= t_sr[i-1]; end
    assign dir_out = t_sr[80][0];
endmodule
