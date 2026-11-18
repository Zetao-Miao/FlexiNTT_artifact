`timescale 1ns / 1ps

// ev_ld_io4_k_bu: CT butterfly mod q = 0, the datapath ev_ld_io4_k_bu_dp (modular multiplier + modular adder/subtractor); latency 11
module ev_ld_io4_k_bu (
    input  logic clk,
    input  logic [29:0] aIn,
    input  logic [29:0] bIn,
    input  logic [29:0] W,
    input  logic [29:0] Q,
    input  logic [31:0] MU,
    output logic [29:0] aOut,
    output logic [29:0] bOut
    );
    ev_ld_io4_k_bu_dp ev_ld_io4_k_bu_dp_inst (.clk(clk), .A(aIn), .B(bIn), .W(W), .Q(Q), .MU(MU), .X(aOut), .Y(bOut));
endmodule
