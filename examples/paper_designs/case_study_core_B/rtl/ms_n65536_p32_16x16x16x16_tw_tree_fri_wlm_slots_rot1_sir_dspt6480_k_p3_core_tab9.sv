`timescale 1ns / 1ps
module ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p3_core_tab9 (
    input  logic clk,
    input  logic [3:0] addr,
    input  logic we,
    input  logic [3:0] wa,
    input  logic [0:0] wcol,
    input  logic [61:0] wd,
    output logic [61:0] q0
    );
    logic [3:0] addr_q;
    always_ff @(posedge clk) addr_q <= addr;
    (* ram_style = "distributed" *) logic [61:0] m0 [10];
    always_ff @(posedge clk) if (we && wcol == 0) m0[wa] <= wd[61:0];
    always_ff @(posedge clk) q0 <= m0[addr_q];
endmodule
