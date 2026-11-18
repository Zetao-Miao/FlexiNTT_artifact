`timescale 1ns / 1ps

// LDd_rom1_s1_c0: CT butterfly mod q = 0, the datapath LDd_rom1_s1_c0_dp (modular multiplier + modular adder/subtractor); latency 3
module LDd_rom1_s1_c0 (
    input  logic clk,
    input  logic [63:0] aIn,
    input  logic [63:0] bIn,
    input  logic [31:0] QH,
    output logic [63:0] aOut,
    output logic [63:0] bOut
    );
    LDd_rom1_s1_c0_dp LDd_rom1_s1_c0_dp_inst (.clk(clk), .A(aIn), .B(bIn), .QH(QH), .X(aOut), .Y(bOut));
endmodule
