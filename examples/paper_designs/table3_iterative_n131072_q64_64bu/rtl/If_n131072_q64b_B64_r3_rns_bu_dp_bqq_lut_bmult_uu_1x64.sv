`timescale 1ns / 1ps

module If_n131072_q64b_B64_r3_rns_bu_dp_bqq_lut_bmult_uu_1x64 (
    input  logic clk,
    input  logic [0:0] A,
    input  logic [63:0] B,
    output logic [64:0] P
);

    logic [0:0] inner_a;
    logic [63:0] inner_b;
    logic [64:0] inner_p;

    assign inner_a = A;
    assign inner_b = B;

    // seed library declares inner latency = 1 cycle(s)
    (* keep_hierarchy = "yes" *) If_n131072_q64b_B64_r3_rns_bu_dp_bqq_SmallMult #(
        .WA           (1),
        .WB           (64),
        .A_SIGNED     (0),
        .B_SIGNED     (0),
        .LATENCY      (1)
    ) u_inner (
        .clk (clk),
        .A   (inner_a),
        .B   (inner_b),
        .P   (inner_p)
    );

    assign P = $unsigned(inner_p[64:0]);

endmodule

