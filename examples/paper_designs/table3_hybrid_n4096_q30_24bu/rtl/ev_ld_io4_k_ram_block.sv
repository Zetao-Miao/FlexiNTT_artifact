`timescale 1ns / 1ps
// simple dual port RAM: one write port, one read port registered R times (R = 1 or 2)
module ev_ld_io4_k_ram_block #(parameter int W = 8, parameter int D = 4, parameter int A = 2, parameter int R = 2) (
    input  logic clk,
    input  logic we,
    input  logic [A-1:0] wa,
    input  logic [W-1:0] wd,
    input  logic [A-1:0] ra,
    output logic [W-1:0] rd
    );
    (* ram_style = "block" *) logic [W-1:0] mem [D];
    logic [W-1:0] r1;
    always_ff @(posedge clk) if (we) mem[wa] <= wd;
    always_ff @(posedge clk) r1 <= mem[ra];
    generate
    if (R >= 2) begin : g_rr
        logic [W-1:0] rr [R-1];
        always_ff @(posedge clk) begin
            rr[0] <= r1;
            for (int i = 1; i < R - 1; i++) rr[i] <= rr[i-1];
        end
        assign rd = rr[R-2];
    end else begin : g_r1
        assign rd = r1;
    end
    endgenerate
endmodule
