`timescale 1ns / 1ps
module Ia_n4096_q60w_B8_rns_twr0 (
    input  logic clk,
    input  logic [8:0] addr,
    input  logic we,
    input  logic [8:0] wa,
    input  logic [59:0] wd,
    output logic [59:0] q0
    );
    (* ram_style = "block" *) logic [59:0] m0 [510];
    always_ff @(posedge clk) if (we) m0[wa] <= wd[59:0];
    logic [59:0] r0;
    always_ff @(posedge clk) r0 <= m0[addr];
    always_ff @(posedge clk) q0 <= r0;
endmodule
