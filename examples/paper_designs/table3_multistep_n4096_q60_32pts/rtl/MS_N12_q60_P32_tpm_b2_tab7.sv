`timescale 1ns / 1ps
module MS_N12_q60_P32_tpm_b2_tab7 (
    input  logic clk,
    input  logic [2:0] addr,
    input  logic we,
    input  logic [2:0] wa,
    input  logic [0:0] wcol,
    input  logic [59:0] wd,
    output logic [59:0] q0
    );
    logic [2:0] addr_q;
    always_ff @(posedge clk) addr_q <= addr;
    (* ram_style = "distributed" *) logic [59:0] m0 [8];
    always_ff @(posedge clk) if (we && wcol == 0) m0[wa] <= wd[59:0];
    always_ff @(posedge clk) q0 <= m0[addr_q];
endmodule
