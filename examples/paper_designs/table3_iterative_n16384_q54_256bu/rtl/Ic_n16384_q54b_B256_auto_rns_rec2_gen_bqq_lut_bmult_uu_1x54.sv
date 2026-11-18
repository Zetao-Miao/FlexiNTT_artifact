`timescale 1ns / 1ps

module Ic_n16384_q54b_B256_auto_rns_rec2_gen_bqq_lut_bmult_uu_1x54 (
    input  logic clk,
    input  logic [0:0] A,
    input  logic [53:0] B,
    output logic [54:0] P
);

    logic [0:0] inner_a;
    logic [53:0] inner_b;
    logic [54:0] inner_p;

    assign inner_a = A;
    assign inner_b = B;

    // seed library declares inner latency = 1 cycle(s)
    (* keep_hierarchy = "yes" *) Ic_n16384_q54b_B256_auto_rns_rec2_gen_bqq_SmallMult #(
        .WA           (1),
        .WB           (54),
        .A_SIGNED     (0),
        .B_SIGNED     (0),
        .LATENCY      (1)
    ) u_inner (
        .clk (clk),
        .A   (inner_a),
        .B   (inner_b),
        .P   (inner_p)
    );

    assign P = $unsigned(inner_p[54:0]);

endmodule

