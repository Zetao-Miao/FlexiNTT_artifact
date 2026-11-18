`timescale 1ns / 1ps

// LDd_rom1_s8_bu: CT butterfly mod q = 0, the datapath LDd_rom1_s8_bu_dp (modular multiplier + modular adder/subtractor); latency 19
module LDd_rom1_s8_bu (
    input  logic clk,
    input  logic [63:0] aIn,
    input  logic [63:0] bIn,
    input  logic [63:0] W,
    input  logic [31:0] QH,
    output logic [63:0] aOut,
    output logic [63:0] bOut
    );
    LDd_rom1_s8_bu_dp LDd_rom1_s8_bu_dp_inst (.clk(clk), .A(aIn), .B(bIn), .W(W), .QH(QH), .X(aOut), .Y(bOut));
endmodule
