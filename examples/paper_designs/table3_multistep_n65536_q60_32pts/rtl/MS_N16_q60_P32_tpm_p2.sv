`timescale 1ns / 1ps
// MS_N16_q60_P32_tpm_p2: fully pipelined NTT, n=16, one transform per cycle, latency 51, ports in natural / natural order
module MS_N16_q60_P32_tpm_p2 (
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
    output logic [59:0] y_out_15
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
    MS_N16_q60_P32_tpm_p2_core u_core (
        .clk(clk),
        .rst(rst),
        .DIR(DIR),
        .QH(QH),
        .QHALF(QHALF),
        .tw_rst(tw_rst),
        .tw_wen(tw_wen),
        .tw_wdata(tw_wdata),
        .x_in_0(x_in_0),
        .x_in_1(x_in_8),
        .x_in_2(x_in_4),
        .x_in_3(x_in_12),
        .x_in_4(x_in_2),
        .x_in_5(x_in_10),
        .x_in_6(x_in_6),
        .x_in_7(x_in_14),
        .x_in_8(x_in_1),
        .x_in_9(x_in_9),
        .x_in_10(x_in_5),
        .x_in_11(x_in_13),
        .x_in_12(x_in_3),
        .x_in_13(x_in_11),
        .x_in_14(x_in_7),
        .x_in_15(x_in_15),
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
        .y_out_15(c_y_15));
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
    logic [50:0] v_sr;
    always_ff @(posedge clk) v_sr <= rst ? '0 : {v_sr[49:0], in_valid};
    assign out_valid = v_sr[50];
    logic [0:0] t_sr [51];
    always_ff @(posedge clk) begin t_sr[0] <= DIR; for (int i = 1; i < 51; i++) t_sr[i] <= t_sr[i-1]; end
    assign dir_out = t_sr[50][0];
endmodule
