`timescale 1ns / 1ps

// MS_N12_q60_P32_tpm_p2_core_s3_bu: CT butterfly mod q = 0, the datapath MS_N12_q60_P32_tpm_p2_core_s3_bu_dp (modular multiplier + modular adder/subtractor); latency 15
module MS_N12_q60_P32_tpm_p2_core_s3_bu (
    input  logic clk,
    input  logic [59:0] aIn,
    input  logic [59:0] bIn,
    input  logic [59:0] W,
    input  logic [16:0] QH,
    output logic [59:0] aOut,
    output logic [59:0] bOut
    );
    MS_N12_q60_P32_tpm_p2_core_s3_bu_dp MS_N12_q60_P32_tpm_p2_core_s3_bu_dp_inst (.clk(clk), .A(aIn), .B(bIn), .W(W), .QH(QH), .X(aOut), .Y(bOut));
endmodule
