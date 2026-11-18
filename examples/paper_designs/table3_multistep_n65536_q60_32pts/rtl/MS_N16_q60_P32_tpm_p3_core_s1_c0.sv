`timescale 1ns / 1ps

// MS_N16_q60_P32_tpm_p3_core_s1_c0: CT butterfly mod q = 0, the datapath MS_N16_q60_P32_tpm_p3_core_s1_c0_dp (modular multiplier + modular adder/subtractor); latency 3
module MS_N16_q60_P32_tpm_p3_core_s1_c0 (
    input  logic clk,
    input  logic [59:0] aIn,
    input  logic [59:0] bIn,
    input  logic [16:0] QH,
    output logic [59:0] aOut,
    output logic [59:0] bOut
    );
    MS_N16_q60_P32_tpm_p3_core_s1_c0_dp MS_N16_q60_P32_tpm_p3_core_s1_c0_dp_inst (.clk(clk), .A(aIn), .B(bIn), .QH(QH), .X(aOut), .Y(bOut));
endmodule
