`timescale 1ns / 1ps

module Ia_n4096_q60w_B8_rns_bu_dp_w1mq_lut_bmult_uu_4x4 (
    input  logic clk,
    input  logic [3:0] A,
    input  logic [3:0] B,
    output logic [7:0] P
);

    logic [3:0] inner_a;
    logic [3:0] inner_b;
    logic [7:0] inner_p;

    assign inner_a = A;
    assign inner_b = B;

    // seed library declares inner latency = 1 cycle(s)
    (* keep_hierarchy = "yes" *) Ia_n4096_q60w_B8_rns_bu_dp_w1mq_SmallMult #(
        .WA           (4),
        .WB           (4),
        .A_SIGNED     (0),
        .B_SIGNED     (0),
        .LATENCY      (1)
    ) u_inner (
        .clk (clk),
        .A   (inner_a),
        .B   (inner_b),
        .P   (inner_p)
    );

    assign P = $unsigned(inner_p[7:0]);

endmodule

