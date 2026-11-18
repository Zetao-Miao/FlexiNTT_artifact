`timescale 1ns / 1ps
module Id_n65536_q52w_B32_rns_twr0 (
    input  logic clk,
    input  logic [10:0] addr,
    input  logic we,
    input  logic [10:0] wa,
    input  logic [51:0] wd,
    output logic [51:0] q0
    );
    (* ram_style = "block" *) logic [51:0] m0 [2046];
    always_ff @(posedge clk) if (we) m0[wa] <= wd[51:0];
    logic [51:0] r0;
    always_ff @(posedge clk) r0 <= m0[addr];
    always_ff @(posedge clk) q0 <= r0;
endmodule
