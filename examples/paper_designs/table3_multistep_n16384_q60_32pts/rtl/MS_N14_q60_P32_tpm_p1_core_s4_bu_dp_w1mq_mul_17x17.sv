`timescale 1ns / 1ps

module MS_N14_q60_P32_tpm_p1_core_s4_bu_dp_w1mq_mul_17x17 (
    input  logic clk,
    input  logic reset,
    input  logic [16:0] A,
    input  logic [16:0] B,
    output logic [33:0] P
);

    logic [16:0] in0;
    logic [16:0] in1;
    logic [16:0] sl0;
    logic [16:0] sl1;
    logic [33:0] dsp0;

    assign in0 = A;

    assign in1 = B;

    assign sl0 = in0[16:0];

    assign sl1 = in1[16:0];

    (* keep_hierarchy = "yes" *) MS_N14_q60_P32_tpm_p1_core_s4_bu_dp_w1mq_versal_dsp58_signed_multiplier_uu_17x17 u_dsp0 (
        .clk   (clk),
        .reset (reset),
        .A     (sl0),
        .B     (sl1),
        .P     (dsp0)
    );

    assign P = dsp0;

endmodule
