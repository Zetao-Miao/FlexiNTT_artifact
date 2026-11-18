`timescale 1ns / 1ps
module ev_ld_io4_k_tt1 (
    input  logic clk,
    input  logic [10:0] addr,
    output logic [29:0] q0,
    input  logic we,
    input  logic [10:0] wa,
    input  logic [29:0] wd
    );
    (* ram_style = "block" *) logic [29:0] m0 [2048];
    always_ff @(posedge clk) if (we) m0[wa] <= wd;
    logic [29:0] r0;
    always_ff @(posedge clk) r0 <= m0[addr];
    always_ff @(posedge clk) q0 <= r0;
endmodule
