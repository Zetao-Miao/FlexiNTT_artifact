`timescale 1ns / 1ps
// MS_N16_q60_P32_tpm_p3: fully pipelined NTT, n=32, one transform per cycle, latency 78, ports in natural / natural order
module MS_N16_q60_P32_tpm_p3 (
    input  logic clk,
    input  logic rst,
    input  logic in_valid,
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
    output logic out_valid,
    output logic dir_out,
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
    logic [59:0] c_y_0;
    logic [59:0] c_y_1;
    logic [59:0] c_y_2;
    logic [59:0] c_y_3;
    logic [59:0] c_y_4;
    logic [59:0] c_y_5;
    logic [59:0] c_y_6;
    logic [59:0] c_y_7;
    logic [59:0] c_y_8;
    logic [59:0] c_y_9;
    logic [59:0] c_y_10;
    logic [59:0] c_y_11;
    logic [59:0] c_y_12;
    logic [59:0] c_y_13;
    logic [59:0] c_y_14;
    logic [59:0] c_y_15;
    logic [59:0] c_y_16;
    logic [59:0] c_y_17;
    logic [59:0] c_y_18;
    logic [59:0] c_y_19;
    logic [59:0] c_y_20;
    logic [59:0] c_y_21;
    logic [59:0] c_y_22;
    logic [59:0] c_y_23;
    logic [59:0] c_y_24;
    logic [59:0] c_y_25;
    logic [59:0] c_y_26;
    logic [59:0] c_y_27;
    logic [59:0] c_y_28;
    logic [59:0] c_y_29;
    logic [59:0] c_y_30;
    logic [59:0] c_y_31;
    MS_N16_q60_P32_tpm_p3_core u_core (
        .clk(clk),
        .rst(rst),
        .DIR(DIR),
        .QH(QH),
        .QHALF(QHALF),
        .tw_rst(tw_rst),
        .tw_wen(tw_wen),
        .tw_wdata(tw_wdata),
        .x_in_0(x_in_0),
        .x_in_1(x_in_16),
        .x_in_2(x_in_8),
        .x_in_3(x_in_24),
        .x_in_4(x_in_4),
        .x_in_5(x_in_20),
        .x_in_6(x_in_12),
        .x_in_7(x_in_28),
        .x_in_8(x_in_2),
        .x_in_9(x_in_18),
        .x_in_10(x_in_10),
        .x_in_11(x_in_26),
        .x_in_12(x_in_6),
        .x_in_13(x_in_22),
        .x_in_14(x_in_14),
        .x_in_15(x_in_30),
        .x_in_16(x_in_1),
        .x_in_17(x_in_17),
        .x_in_18(x_in_9),
        .x_in_19(x_in_25),
        .x_in_20(x_in_5),
        .x_in_21(x_in_21),
        .x_in_22(x_in_13),
        .x_in_23(x_in_29),
        .x_in_24(x_in_3),
        .x_in_25(x_in_19),
        .x_in_26(x_in_11),
        .x_in_27(x_in_27),
        .x_in_28(x_in_7),
        .x_in_29(x_in_23),
        .x_in_30(x_in_15),
        .x_in_31(x_in_31),
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
        .y_out_31(c_y_31));
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
    logic [77:0] v_sr;
    always_ff @(posedge clk) v_sr <= rst ? '0 : {v_sr[76:0], in_valid};
    assign out_valid = v_sr[77];
    logic [0:0] t_sr [78];
    always_ff @(posedge clk) begin t_sr[0] <= DIR; for (int i = 1; i < 78; i++) t_sr[i] <= t_sr[i-1]; end
    assign dir_out = t_sr[77][0];
endmodule
