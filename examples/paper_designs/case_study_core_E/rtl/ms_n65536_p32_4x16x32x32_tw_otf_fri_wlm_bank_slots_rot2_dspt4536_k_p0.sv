`timescale 1ns / 1ps
// ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0: fully pipelined NTT, n=4, one transform per cycle, latency 33, ports in natural / natural order, 5 moduli (MIDX per transform)
module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0 (
    input  logic clk,
    input  logic rst,
    input  logic in_valid,
    input  logic [2:0] MIDX,
    input  logic DIR,
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
    output logic out_valid,
    output logic [2:0] midx_out,
    output logic dir_out,
    output logic [61:0] y_out_0,
    output logic [61:0] y_out_1,
    output logic [61:0] y_out_2,
    output logic [61:0] y_out_3
    );
    logic [61:0] c_y_0;
    logic [61:0] c_y_1;
    logic [61:0] c_y_2;
    logic [61:0] c_y_3;
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core u_core (
        .clk(clk),
        .rst(rst),
        .DIR(DIR),
        .MIDX(MIDX),
        .mq_QH(mq_QH),
        .mq_QHALF(mq_QHALF),
        .tw_rst(tw_rst),
        .tw_wen(tw_wen),
        .tw_wdata(tw_wdata),
        .tw_slot(tw_slot),
        .tw_dir(tw_dir),
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
    logic [3:0] t_sr [33];
    always_ff @(posedge clk) begin t_sr[0] <= {MIDX, DIR}; for (int i = 1; i < 33; i++) t_sr[i] <= t_sr[i-1]; end
    assign midx_out = t_sr[32][3:1];
    assign dir_out = t_sr[32][0];
endmodule
