`timescale 1ns / 1ps

module Ib_n8192_q36b_B512_auto_rns_rec_gen_bqq_lut_bmult_uu_1x36 (
    input  logic clk,
    input  logic [0:0] A,
    input  logic [35:0] B,
    output logic [36:0] P
);

    logic [0:0] inner_a;
    logic [35:0] inner_b;
    logic [36:0] inner_p;

    assign inner_a = A;
    assign inner_b = B;

    // seed library declares inner latency = 1 cycle(s)
    (* keep_hierarchy = "yes" *) Ib_n8192_q36b_B512_auto_rns_rec_gen_bqq_SmallMult #(
        .WA           (1),
        .WB           (36),
        .A_SIGNED     (0),
        .B_SIGNED     (0),
        .LATENCY      (1)
    ) u_inner (
        .clk (clk),
        .A   (inner_a),
        .B   (inner_b),
        .P   (inner_p)
    );

    assign P = $unsigned(inner_p[36:0]);

endmodule

