`timescale 1ns / 1ps

module MS_N14_q60_P32_tpm_twmul_w0mq_mul_43x17 (
    input  logic clk,
    input  logic reset,
    input  logic [42:0] A,
    input  logic [16:0] B,
    output logic [59:0] P
);

    logic [42:0] in0;
    logic [16:0] in1;
    logic [25:0] sl0;
    logic [16:0] sl1;
    logic [42:0] dsp0;
    logic [16:0] sl2;
    logic [16:0] sl3;
    logic [33:0] dsp1;
    logic [59:0] sum0;

    assign in0 = A;

    assign in1 = B;

    assign sl0 = in0[25:0];

    assign sl1 = in1[16:0];

    (* keep_hierarchy = "yes" *) MS_N14_q60_P32_tpm_twmul_w0mq_versal_dsp58_signed_multiplier_uu_26x17 u_dsp0 (
        .clk   (clk),
        .reset (reset),
        .A     (sl0),
        .B     (sl1),
        .P     (dsp0)
    );

    assign sl2 = in0[42:26];

    assign sl3 = in1[16:0];

    (* keep_hierarchy = "yes" *) MS_N14_q60_P32_tpm_twmul_w0mq_versal_dsp58_signed_multiplier_uu_17x17 u_dsp1 (
        .clk   (clk),
        .reset (reset),
        .A     (sl2),
        .B     (sl3),
        .P     (dsp1)
    );

    (* keep_hierarchy = "yes" *) MS_N14_q60_P32_tpm_twmul_w0mq_terminal_bitheap_60_77e170bee8 u_sum0 (
        .clk   (clk),
        .term0 (dsp0),
        .term1 (dsp1),
        .P     (sum0)
    );

    assign P = sum0;

endmodule
