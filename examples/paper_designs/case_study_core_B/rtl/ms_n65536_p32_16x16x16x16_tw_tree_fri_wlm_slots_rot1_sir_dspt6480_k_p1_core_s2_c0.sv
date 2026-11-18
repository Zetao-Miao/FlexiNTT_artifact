`timescale 1ns / 1ps

// ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p1_core_s2_c0: CT butterfly mod q = 0, the datapath ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p1_core_s2_c0_dp (modular multiplier + modular adder/subtractor); latency 3
module ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p1_core_s2_c0 (
    input  logic clk,
    input  logic [61:0] aIn,
    input  logic [61:0] bIn,
    input  logic [44:0] QH,
    output logic [61:0] aOut,
    output logic [61:0] bOut
    );
    ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p1_core_s2_c0_dp ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p1_core_s2_c0_dp_inst (.clk(clk), .A(aIn), .B(bIn), .QH(QH), .X(aOut), .Y(bOut));
endmodule
