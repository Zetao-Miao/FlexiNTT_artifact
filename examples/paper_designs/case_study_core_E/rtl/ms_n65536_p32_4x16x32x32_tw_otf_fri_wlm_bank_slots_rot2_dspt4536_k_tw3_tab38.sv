`timescale 1ns / 1ps
module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_tw3_tab38 (
    input  logic clk,
    input  logic [9:0] addr,
    input  logic we,
    input  logic [9:0] wa,
    input  logic [0:0] wcol,
    input  logic [61:0] wd,
    output logic [61:0] q0
    );
    logic [9:0] addr_q;
    always_ff @(posedge clk) addr_q <= addr;
    (* ram_style = "block" *) logic [61:0] m0 [640];
    always_ff @(posedge clk) if (we && wcol == 0) m0[wa] <= wd[61:0];
    always_ff @(posedge clk) q0 <= m0[addr_q];
endmodule
