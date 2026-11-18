`timescale 1ns / 1ps
module LDe_rom1_tab24 (
    input  logic clk,
    input  logic [7:0] addr,
    input  logic we,
    input  logic [6:0] wa,
    input  logic [0:0] wcol,
    input  logic [61:0] wd,
    output logic [61:0] q0
    );
    logic [7:0] addr_q;
    always_ff @(posedge clk) addr_q <= addr;
    logic [61:0] m0 [128];
    always_ff @(posedge clk) if (we && wcol == 0) m0[wa] <= wd[61:0];
    always_ff @(posedge clk) q0 <= m0[addr_q];
endmodule
