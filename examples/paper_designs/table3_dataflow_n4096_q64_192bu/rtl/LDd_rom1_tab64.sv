`timescale 1ns / 1ps
module LDd_rom1_tab64 (
    input  logic clk,
    input  logic [5:0] addr,
    input  logic we,
    input  logic [4:0] wa,
    input  logic [0:0] wcol,
    input  logic [63:0] wd,
    output logic [63:0] q0
    );
    logic [5:0] addr_q;
    always_ff @(posedge clk) addr_q <= addr;
    logic [63:0] m0 [32];
    always_ff @(posedge clk) if (we && wcol == 0) m0[wa] <= wd[63:0];
    always_ff @(posedge clk) q0 <= m0[addr_q];
endmodule
