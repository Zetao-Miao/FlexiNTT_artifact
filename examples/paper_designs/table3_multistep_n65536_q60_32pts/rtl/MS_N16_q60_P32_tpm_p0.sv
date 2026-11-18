`timescale 1ns / 1ps
// MS_N16_q60_P32_tpm_p0: fully pipelined NTT, n=4, one transform per cycle, latency 33, ports in natural / natural order
module MS_N16_q60_P32_tpm_p0 (
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
    output logic out_valid,
    output logic dir_out,
    output logic [59:0] y_out_0,
    output logic [59:0] y_out_1,
    output logic [59:0] y_out_2,
    output logic [59:0] y_out_3
    );
    logic [59:0] c_y_0;
    logic [59:0] c_y_1;
    logic [59:0] c_y_2;
    logic [59:0] c_y_3;
    MS_N16_q60_P32_tpm_p0_core u_core (
        .clk(clk),
        .rst(rst),
        .DIR(DIR),
        .QH(QH),
        .QHALF(QHALF),
        .tw_rst(tw_rst),
        .tw_wen(tw_wen),
        .tw_wdata(tw_wdata),
        .x_in_0(x_in_0),
        .x_in_1(x_in_2),
        .x_in_2(x_in_1),
        .x_in_3(x_in_3),
        .y_out_0(c_y_0),
        .y_out_1(c_y_1),
        .y_out_2(c_y_2),
        .y_out_3(c_y_3));
    assign y_out_0 = c_y_0;
    assign y_out_1 = c_y_1;
    assign y_out_2 = c_y_2;
    assign y_out_3 = c_y_3;
    logic [32:0] v_sr;
    always_ff @(posedge clk) v_sr <= rst ? '0 : {v_sr[31:0], in_valid};
    assign out_valid = v_sr[32];
    logic [0:0] t_sr [33];
    always_ff @(posedge clk) begin t_sr[0] <= DIR; for (int i = 1; i < 33; i++) t_sr[i] <= t_sr[i-1]; end
    assign dir_out = t_sr[32][0];
endmodule
