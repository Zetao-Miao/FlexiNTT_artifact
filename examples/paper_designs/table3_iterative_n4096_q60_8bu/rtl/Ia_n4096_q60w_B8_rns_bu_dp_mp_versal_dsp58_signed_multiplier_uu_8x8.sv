`timescale 1ns / 1ps

module Ia_n4096_q60w_B8_rns_bu_dp_mp_versal_dsp58_signed_multiplier_uu_8x8 (
    input  logic clk,
    input  logic reset,
    input  logic [7:0] A,
    input  logic [7:0] B,
    output logic [15:0] P
);

    logic signed [26:0] inner_a;
    logic signed [23:0] inner_b;
    logic signed [50:0] inner_p;

    assign inner_a = $signed({19'b0, A});
    assign inner_b = $signed({16'b0, B});

    // seed library declares inner latency = 1 cycle(s)
    (* keep_hierarchy = "yes" *) Ia_n4096_q60w_B8_rns_bu_dp_mp_SingleDSP #(
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

    assign P = $unsigned(inner_p[15:0]);

endmodule

