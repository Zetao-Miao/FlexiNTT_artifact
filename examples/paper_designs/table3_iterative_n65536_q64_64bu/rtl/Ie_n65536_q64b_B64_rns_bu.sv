`timescale 1ns / 1ps

// Ie_n65536_q64b_B64_rns_bu: CT butterfly mod q = 0, the datapath Ie_n65536_q64b_B64_rns_bu_dp (modular multiplier + modular adder/subtractor); latency 16
module Ie_n65536_q64b_B64_rns_bu (
    input  logic clk,
    input  logic [63:0] aIn,
    input  logic [63:0] bIn,
    input  logic [63:0] W,
    input  logic [63:0] Q,
    input  logic [65:0] MU,
    output logic [63:0] aOut,
    output logic [63:0] bOut
    );
    Ie_n65536_q64b_B64_rns_bu_dp Ie_n65536_q64b_B64_rns_bu_dp_inst (.clk(clk), .A(aIn), .B(bIn), .W(W), .Q(Q), .MU(MU), .X(aOut), .Y(bOut));
endmodule
