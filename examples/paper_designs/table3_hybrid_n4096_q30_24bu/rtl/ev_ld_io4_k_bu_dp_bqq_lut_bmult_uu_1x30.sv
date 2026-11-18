`timescale 1ns / 1ps

module ev_ld_io4_k_bu_dp_bqq_lut_bmult_uu_1x30 (
    input  logic clk,
    input  logic [0:0] A,
    input  logic [29:0] B,
    output logic [30:0] P
);

    logic [0:0] inner_a;
    logic [29:0] inner_b;
    logic [30:0] inner_p;

    assign inner_a = A;
    assign inner_b = B;

    // seed library declares inner latency = 1 cycle(s)
    (* keep_hierarchy = "yes" *) ev_ld_io4_k_bu_dp_bqq_SmallMult #(
        .WA           (1),
        .WB           (30),
        .A_SIGNED     (0),
        .B_SIGNED     (0),
        .LATENCY      (1)
    ) u_inner (
        .clk (clk),
        .A   (inner_a),
        .B   (inner_b),
        .P   (inner_p)
    );

    assign P = $unsigned(inner_p[30:0]);

endmodule

