`timescale 1ns / 1ps
module MS_N14_q60_P32_tpm_tw2_tab25 (
    input  logic clk,
    input  logic [4:0] addr,
    input  logic we,
    input  logic [4:0] wa,
    input  logic [0:0] wcol,
    input  logic [59:0] wd,
    output logic [59:0] q0
    );
    logic [4:0] addr_q;
    always_ff @(posedge clk) addr_q <= addr;
    (* ram_style = "distributed" *) logic [59:0] m0 [32];
    always_ff @(posedge clk) if (we && wcol == 0) m0[wa] <= wd[59:0];
    always_ff @(posedge clk) q0 <= m0[addr_q];
endmodule
