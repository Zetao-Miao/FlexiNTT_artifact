`timescale 1ns / 1ps

// LDb_rom1_s9_bu: CT butterfly mod q = 0, the datapath LDb_rom1_s9_bu_dp (modular multiplier + modular adder/subtractor); latency 14
module LDb_rom1_s9_bu (
    input  logic clk,
    input  logic [31:0] aIn,
    input  logic [31:0] bIn,
    input  logic [31:0] W,
    input  logic [15:0] QH,
    output logic [31:0] aOut,
    output logic [31:0] bOut
    );
    LDb_rom1_s9_bu_dp LDb_rom1_s9_bu_dp_inst (.clk(clk), .A(aIn), .B(bIn), .W(W), .QH(QH), .X(aOut), .Y(bOut));
endmodule
