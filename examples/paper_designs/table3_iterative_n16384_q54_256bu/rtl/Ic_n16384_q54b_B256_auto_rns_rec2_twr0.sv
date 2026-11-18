`timescale 1ns / 1ps
module Ic_n16384_q54b_B256_auto_rns_rec2_twr0 (
    input  logic clk,
    input  logic [8:0] addr,
    input  logic we,
    input  logic [8:0] wa,
    input  logic [53:0] wd,
    output logic [53:0] q0
    );
    (* ram_style = "block" *) logic [53:0] m0 [319];
    always_ff @(posedge clk) if (we) m0[wa] <= wd[53:0];
    logic [53:0] r0;
    always_ff @(posedge clk) r0 <= m0[addr];
    always_ff @(posedge clk) q0 <= r0;
endmodule
