`timescale 1ns / 1ps

// Ib_n8192_q36b_B512_auto_rns_rec_bu: CT butterfly mod q = 0, the datapath Ib_n8192_q36b_B512_auto_rns_rec_bu_dp (modular multiplier + modular adder/subtractor); latency 13
module Ib_n8192_q36b_B512_auto_rns_rec_bu (
    input  logic clk,
    input  logic [35:0] aIn,
    input  logic [35:0] bIn,
    input  logic [35:0] W,
    input  logic [35:0] Q,
    input  logic [37:0] MU,
    output logic [35:0] aOut,
    output logic [35:0] bOut
    );
    Ib_n8192_q36b_B512_auto_rns_rec_bu_dp Ib_n8192_q36b_B512_auto_rns_rec_bu_dp_inst (.clk(clk), .A(aIn), .B(bIn), .W(W), .Q(Q), .MU(MU), .X(aOut), .Y(bOut));
endmodule
