`timescale 1ns / 1ps

// LDe_rom1_s5_bu: CT butterfly mod q = 0, the datapath LDe_rom1_s5_bu_dp (modular multiplier + modular adder/subtractor); latency 16
module LDe_rom1_s5_bu (
    input  logic clk,
    input  logic [61:0] aIn,
    input  logic [61:0] bIn,
    input  logic [61:0] W,
    input  logic [61:0] Q,
    input  logic [63:0] MU,
    output logic [61:0] aOut,
    output logic [61:0] bOut
    );
    LDe_rom1_s5_bu_dp LDe_rom1_s5_bu_dp_inst (.clk(clk), .A(aIn), .B(bIn), .W(W), .Q(Q), .MU(MU), .X(aOut), .Y(bOut));
endmodule
