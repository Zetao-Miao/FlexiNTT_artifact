`timescale 1ns / 1ps
module Ie_n65536_q64b_B64_rns_twr1 (
    input  logic clk,
    input  logic [2:0] addr,
    input  logic we,
    input  logic [2:0] wa,
    input  logic [63:0] wd,
    output logic [63:0] q0
    );
    (* ram_style = "distributed" *) logic [63:0] m0 [7];
    always_ff @(posedge clk) if (we) m0[wa] <= wd[63:0];
    logic [63:0] r0;
    always_ff @(posedge clk) r0 <= m0[addr];
    always_ff @(posedge clk) q0 <= r0;
endmodule
