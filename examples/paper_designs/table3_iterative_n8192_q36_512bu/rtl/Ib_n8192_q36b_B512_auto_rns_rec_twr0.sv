`timescale 1ns / 1ps
module Ib_n8192_q36b_B512_auto_rns_rec_twr0 (
    input  logic clk,
    input  logic [6:0] addr,
    input  logic we,
    input  logic [6:0] wa,
    input  logic [35:0] wd,
    output logic [35:0] q0
    );
    (* ram_style = "block" *) logic [35:0] m0 [87];
    always_ff @(posedge clk) if (we) m0[wa] <= wd[35:0];
    logic [35:0] r0;
    always_ff @(posedge clk) r0 <= m0[addr];
    always_ff @(posedge clk) q0 <= r0;
endmodule
