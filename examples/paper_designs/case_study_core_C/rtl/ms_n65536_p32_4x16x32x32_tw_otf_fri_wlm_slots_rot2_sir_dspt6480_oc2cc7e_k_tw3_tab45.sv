`timescale 1ns / 1ps
module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt6480_oc2cc7e_k_tw3_tab45 (
    input  logic clk,
    input  logic [8:0] addr,
    input  logic we,
    input  logic [8:0] wa,
    input  logic [0:0] wcol,
    input  logic [61:0] wd,
    output logic [61:0] q0
    );
    logic [8:0] addr_q;
    always_ff @(posedge clk) addr_q <= addr;
    (* ram_style = "block" *) logic [61:0] m0 [320];
    always_ff @(posedge clk) if (we && wcol == 0) m0[wa] <= wd[61:0];
    always_ff @(posedge clk) q0 <= m0[addr_q];
endmodule
