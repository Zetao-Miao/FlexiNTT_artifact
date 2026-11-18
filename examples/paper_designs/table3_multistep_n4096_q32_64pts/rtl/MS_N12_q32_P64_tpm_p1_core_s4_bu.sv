`timescale 1ns / 1ps

// MS_N12_q32_P64_tpm_p1_core_s4_bu: CT butterfly mod q = 0, the datapath MS_N12_q32_P64_tpm_p1_core_s4_bu_dp (modular multiplier + modular adder/subtractor); latency 12
module MS_N12_q32_P64_tpm_p1_core_s4_bu (
    input  logic clk,
    input  logic [31:0] aIn,
    input  logic [31:0] bIn,
    input  logic [31:0] W,
    input  logic [15:0] QH,
    output logic [31:0] aOut,
    output logic [31:0] bOut
    );
    MS_N12_q32_P64_tpm_p1_core_s4_bu_dp MS_N12_q32_P64_tpm_p1_core_s4_bu_dp_inst (.clk(clk), .A(aIn), .B(bIn), .W(W), .QH(QH), .X(aOut), .Y(bOut));
endmodule
