`timescale 1ns / 1ps
module LDd_rom1_tab15 (
    input  logic clk,
    input  logic [2:0] addr,
    input  logic we,
    input  logic [1:0] wa,
    input  logic [0:0] wcol,
    input  logic [63:0] wd,
    output logic [63:0] q0
    );
    logic [2:0] addr_q;
    always_ff @(posedge clk) addr_q <= addr;
    logic [63:0] m0 [4];
    always_ff @(posedge clk) if (we && wcol == 0) m0[wa] <= wd[63:0];
    always_ff @(posedge clk) q0 <= m0[addr_q];
endmodule
