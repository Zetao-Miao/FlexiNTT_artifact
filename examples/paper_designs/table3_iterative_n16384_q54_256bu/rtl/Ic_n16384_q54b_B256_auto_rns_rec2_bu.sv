`timescale 1ns / 1ps

// Ic_n16384_q54b_B256_auto_rns_rec2_bu: CT butterfly mod q = 0, the datapath Ic_n16384_q54b_B256_auto_rns_rec2_bu_dp (modular multiplier + modular adder/subtractor); latency 16
module Ic_n16384_q54b_B256_auto_rns_rec2_bu (
    input  logic clk,
    input  logic [53:0] aIn,
    input  logic [53:0] bIn,
    input  logic [53:0] W,
    input  logic [53:0] Q,
    input  logic [55:0] MU,
    output logic [53:0] aOut,
    output logic [53:0] bOut
    );
    Ic_n16384_q54b_B256_auto_rns_rec2_bu_dp Ic_n16384_q54b_B256_auto_rns_rec2_bu_dp_inst (.clk(clk), .A(aIn), .B(bIn), .W(W), .Q(Q), .MU(MU), .X(aOut), .Y(bOut));
endmodule
