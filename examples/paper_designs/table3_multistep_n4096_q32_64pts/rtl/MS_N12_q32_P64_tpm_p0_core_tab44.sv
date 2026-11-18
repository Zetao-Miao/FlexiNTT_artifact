`timescale 1ns / 1ps
module MS_N12_q32_P64_tpm_p0_core_tab44 (
    input  logic clk,
    input  logic [0:0] addr,
    input  logic we,
    input  logic [0:0] wa,
    input  logic [0:0] wcol,
    input  logic [31:0] wd,
    output logic [31:0] q0
    );
    logic [0:0] addr_q;
    always_ff @(posedge clk) addr_q <= addr;
    (* ram_style = "distributed" *) logic [31:0] m0 [2];
    always_ff @(posedge clk) if (we && wcol == 0) m0[wa] <= wd[31:0];
    always_ff @(posedge clk) q0 <= m0[addr_q];
endmodule
