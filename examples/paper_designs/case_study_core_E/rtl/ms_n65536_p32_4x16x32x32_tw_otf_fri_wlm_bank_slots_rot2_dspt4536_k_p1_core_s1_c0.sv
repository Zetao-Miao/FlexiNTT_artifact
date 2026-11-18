`timescale 1ns / 1ps

// ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p1_core_s1_c0: CT butterfly mod q = 0, the datapath ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p1_core_s1_c0_dp (modular multiplier + modular adder/subtractor); latency 3
module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p1_core_s1_c0 (
    input  logic clk,
    input  logic [61:0] aIn,
    input  logic [61:0] bIn,
    input  logic [44:0] QH,
    output logic [61:0] aOut,
    output logic [61:0] bOut
    );
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p1_core_s1_c0_dp ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p1_core_s1_c0_dp_inst (.clk(clk), .A(aIn), .B(bIn), .QH(QH), .X(aOut), .Y(bOut));
endmodule
