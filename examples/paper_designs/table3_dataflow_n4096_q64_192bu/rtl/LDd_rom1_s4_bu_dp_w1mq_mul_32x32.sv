`timescale 1ns / 1ps

module LDd_rom1_s4_bu_dp_w1mq_mul_32x32 (
    input  logic clk,
    input  logic reset,
    input  logic [31:0] A,
    input  logic [31:0] B,
    output logic [63:0] P
);

    logic [31:0] in0;
    logic [31:0] in1;
    logic [25:0] sl0;
    logic [22:0] sl1;
    logic [48:0] dsp0;
    logic [25:0] sl2;
    logic [8:0] sl3;
    logic [34:0] dsp1;
    logic [5:0] sl4;
    logic [25:0] sl5;
    logic [31:0] dsp2;
    logic [5:0] sl6;
    logic [5:0] sl7;
    logic signed [35:0] lut0;
    logic [63:0] sum0;

    assign in0 = A;

    assign in1 = B;

    assign sl0 = in0[25:0];

    assign sl1 = in1[22:0];

    (* keep_hierarchy = "yes" *) LDd_rom1_s4_bu_dp_w1mq_versal_dsp58_signed_multiplier_uu_26x23 u_dsp0 (
        .clk   (clk),
        .reset (reset),
        .A     (sl0),
        .B     (sl1),
        .P     (dsp0)
    );

    assign sl2 = in0[25:0];

    assign sl3 = in1[31:23];

    (* keep_hierarchy = "yes" *) LDd_rom1_s4_bu_dp_w1mq_versal_dsp58_signed_multiplier_uu_26x9 u_dsp1 (
        .clk   (clk),
        .reset (reset),
        .A     (sl2),
        .B     (sl3),
        .P     (dsp1)
    );

    assign sl4 = in0[31:26];

    assign sl5 = in1[25:0];

    (* keep_hierarchy = "yes" *) LDd_rom1_s4_bu_dp_w1mq_versal_dsp58_signed_multiplier_uu_6x26_t u_dsp2 (
        .clk   (clk),
        .reset (reset),
        .A     (sl4),
        .B     (sl5),
        .P     (dsp2)
    );

    assign sl6 = in0[31:26];

    assign sl7 = in1[31:26];

    (* keep_hierarchy = "yes" *) LDd_rom1_s4_bu_dp_w1mq_lut_pp_uu_6x6 u_lut0 (
        .clk   (clk),
        .A     (sl6),
        .B     (sl7),
        .P     (lut0)
    );

    (* keep_hierarchy = "yes" *) LDd_rom1_s4_bu_dp_w1mq_terminal_bitheap_64_27956d7668 u_sum0 (
        .clk   (clk),
        .term0 (dsp0),
        .term1 (dsp1),
        .term2 (dsp2),
        .term3 (lut0),
        .P     (sum0)
    );

    assign P = sum0;

endmodule
