`timescale 1ns / 1ps

module LDd_rom1_s11_bu_dp_w0mq_versal_dsp58_signed_multiplier_uu_6x26_t (
    input  logic clk,
    input  logic reset,
    input  logic [5:0] A,
    input  logic [25:0] B,
    output logic [31:0] P
);

    logic signed [26:0] inner_a;
    logic signed [23:0] inner_b;
    logic signed [50:0] inner_p;

    assign inner_a = $signed({1'b0, B});
    assign inner_b = $signed({18'b0, A});

    // seed library declares inner latency = 1 cycle(s)
    (* keep_hierarchy = "yes" *) LDd_rom1_s11_bu_dp_w0mq_SingleDSP #(
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

