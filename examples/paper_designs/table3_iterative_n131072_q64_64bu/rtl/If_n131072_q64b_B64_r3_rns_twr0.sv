`timescale 1ns / 1ps
module If_n131072_q64b_B64_r3_rns_twr0 (
    input  logic clk,
    input  logic [10:0] addr,
    input  logic we,
    input  logic [10:0] wa,
    input  logic [63:0] wd,
    output logic [63:0] q0
    );
    (* ram_style = "block" *) logic [63:0] m0 [2046];
    always_ff @(posedge clk) if (we) m0[wa] <= wd[63:0];
    logic [63:0] r0;
    always_ff @(posedge clk) r0 <= m0[addr];
    logic [63:0] r0_2;
    always_ff @(posedge clk) r0_2 <= r0;
    always_ff @(posedge clk) q0 <= r0_2;
endmodule
