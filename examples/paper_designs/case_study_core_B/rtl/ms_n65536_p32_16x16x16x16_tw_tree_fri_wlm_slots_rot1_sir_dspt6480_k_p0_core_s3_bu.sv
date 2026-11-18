`timescale 1ns / 1ps

// ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p0_core_s3_bu: CT butterfly mod q = 0, the datapath ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p0_core_s3_bu_dp (modular multiplier + modular adder/subtractor); latency 26
module ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p0_core_s3_bu (
    input  logic clk,
    input  logic [61:0] aIn,
    input  logic [61:0] bIn,
    input  logic [61:0] W,
    input  logic [44:0] QH,
    output logic [61:0] aOut,
    output logic [61:0] bOut
    );
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p0_core_s3_bu_dp ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p0_core_s3_bu_dp_inst (.clk(clk), .A(aIn), .B(bIn), .W(W), .QH(QH), .X(aOut), .Y(bOut));
endmodule
