`timescale 1ns / 1ps

module LDe_rom1_s16_bu_dp_bqq_lut_bmult_uu_1x62 (
    input  logic clk,
    input  logic [0:0] A,
    input  logic [61:0] B,
    output logic [62:0] P
);

    logic [0:0] inner_a;
    logic [61:0] inner_b;
    logic [62:0] inner_p;

    assign inner_a = A;
    assign inner_b = B;

    // seed library declares inner latency = 1 cycle(s)
    (* keep_hierarchy = "yes" *) LDe_rom1_s16_bu_dp_bqq_SmallMult #(
        .WA           (1),
        .WB           (62),
        .A_SIGNED     (0),
        .B_SIGNED     (0),
        .LATENCY      (1)
    ) u_inner (
        .clk (clk),
        .A   (inner_a),
        .B   (inner_b),
        .P   (inner_p)
    );

    assign P = $unsigned(inner_p[62:0]);

endmodule

