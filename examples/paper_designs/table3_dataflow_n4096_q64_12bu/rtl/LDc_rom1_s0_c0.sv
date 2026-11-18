`timescale 1ns / 1ps

// LDc_rom1_s0_c0: CT butterfly mod q = 0, the datapath LDc_rom1_s0_c0_dp (modular multiplier + modular adder/subtractor); latency 3
module LDc_rom1_s0_c0 (
    input  logic clk,
    input  logic [63:0] aIn,
    input  logic [63:0] bIn,
    input  logic [31:0] QH,
    output logic [63:0] aOut,
    output logic [63:0] bOut
    );
    LDc_rom1_s0_c0_dp LDc_rom1_s0_c0_dp_inst (.clk(clk), .A(aIn), .B(bIn), .QH(QH), .X(aOut), .Y(bOut));
endmodule
