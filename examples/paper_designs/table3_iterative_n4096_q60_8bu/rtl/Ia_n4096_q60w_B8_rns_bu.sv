`timescale 1ns / 1ps

// Ia_n4096_q60w_B8_rns_bu: CT butterfly mod q = 0, the datapath Ia_n4096_q60w_B8_rns_bu_dp (modular multiplier + modular adder/subtractor); latency 17
module Ia_n4096_q60w_B8_rns_bu (
    input  logic clk,
    input  logic [59:0] aIn,
    input  logic [59:0] bIn,
    input  logic [59:0] W,
    input  logic [29:0] QH,
    output logic [59:0] aOut,
    output logic [59:0] bOut
    );
    Ia_n4096_q60w_B8_rns_bu_dp Ia_n4096_q60w_B8_rns_bu_dp_inst (.clk(clk), .A(aIn), .B(bIn), .W(W), .QH(QH), .X(aOut), .Y(bOut));
endmodule
