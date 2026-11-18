`timescale 1ns / 1ps

module LDe_rom1_s7_bu_dp_bqq_versal_dsp58_signed_multiplier_uu_26x16 (
    input  logic clk,
    input  logic reset,
    input  logic [25:0] A,
    input  logic [15:0] B,
    output logic [41:0] P
);

    logic signed [26:0] inner_a;
    logic signed [23:0] inner_b;
    logic signed [50:0] inner_p;

    assign inner_a = $signed({1'b0, A});
    assign inner_b = $signed({8'b0, B});

    // seed library declares inner latency = 1 cycle(s)
    (* keep_hierarchy = "yes" *) LDe_rom1_s7_bu_dp_bqq_SingleDSP #(
        .LATENCY      (1),
        .OUT_REG      (0)
    ) u_inner (
        .clk (clk),
        .reset (reset),
        .in_valid (1'b1),
        .X   (inner_a),
        .Y   (inner_b),
        .P   (inner_p)
    );

    assign P = $unsigned(inner_p[41:0]);

endmodule

