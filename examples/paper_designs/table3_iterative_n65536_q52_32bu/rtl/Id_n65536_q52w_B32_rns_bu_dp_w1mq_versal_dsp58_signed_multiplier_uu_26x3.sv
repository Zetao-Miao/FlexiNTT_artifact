`timescale 1ns / 1ps

module Id_n65536_q52w_B32_rns_bu_dp_w1mq_versal_dsp58_signed_multiplier_uu_26x3 (
    input  logic clk,
    input  logic reset,
    input  logic [25:0] A,
    input  logic [2:0] B,
    output logic [28:0] P
);

    logic signed [26:0] inner_a;
    logic signed [23:0] inner_b;
    logic signed [50:0] inner_p;

    assign inner_a = $signed({1'b0, A});
    assign inner_b = $signed({21'b0, B});

    // seed library declares inner latency = 1 cycle(s)
    (* keep_hierarchy = "yes" *) Id_n65536_q52w_B32_rns_bu_dp_w1mq_SingleDSP #(
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

    assign P = $unsigned(inner_p[28:0]);

endmodule

