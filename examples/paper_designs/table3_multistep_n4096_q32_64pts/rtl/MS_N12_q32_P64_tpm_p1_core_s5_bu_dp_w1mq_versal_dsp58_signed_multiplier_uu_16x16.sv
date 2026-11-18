`timescale 1ns / 1ps

module MS_N12_q32_P64_tpm_p1_core_s5_bu_dp_w1mq_versal_dsp58_signed_multiplier_uu_16x16 (
    input  logic clk,
    input  logic reset,
    input  logic [15:0] A,
    input  logic [15:0] B,
    output logic [31:0] P
);

    logic signed [26:0] inner_a;
    logic signed [23:0] inner_b;
    logic signed [50:0] inner_p;

    assign inner_a = $signed({11'b0, A});
    assign inner_b = $signed({8'b0, B});

    // seed library declares inner latency = 1 cycle(s)
    (* keep_hierarchy = "yes" *) MS_N12_q32_P64_tpm_p1_core_s5_bu_dp_w1mq_SingleDSP #(
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

    assign P = $unsigned(inner_p[31:0]);

endmodule

