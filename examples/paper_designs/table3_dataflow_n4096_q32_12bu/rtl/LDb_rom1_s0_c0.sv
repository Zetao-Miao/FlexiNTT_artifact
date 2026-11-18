`timescale 1ns / 1ps

// LDb_rom1_s0_c0: CT butterfly mod q = 0, the datapath LDb_rom1_s0_c0_dp (modular multiplier + modular adder/subtractor); latency 3
module LDb_rom1_s0_c0 (
    input  logic clk,
    input  logic [31:0] aIn,
    input  logic [31:0] bIn,
    input  logic [15:0] QH,
    output logic [31:0] aOut,
    output logic [31:0] bOut
    );
    LDb_rom1_s0_c0_dp LDb_rom1_s0_c0_dp_inst (.clk(clk), .A(aIn), .B(bIn), .QH(QH), .X(aOut), .Y(bOut));
endmodule
