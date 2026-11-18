`timescale 1ns / 1ps

module ev_ld_io4_k_bu_dp_bqq_mul_31x30 (
    input  logic clk,
    input  logic reset,
    input  logic [30:0] A,
    input  logic [29:0] B,
    output logic [60:0] P
);

    logic [30:0] in0;
    logic [29:0] in1;
    logic [29:0] sl0;
    logic [25:0] sl1;
    logic [22:0] sl2;
    logic [48:0] dsp0;
    logic [25:0] sl3;
    logic [6:0] sl4;
    logic [32:0] dsp1;
    logic [3:0] sl5;
    logic [25:0] sl6;
    logic [29:0] dsp2;
    logic [3:0] sl7;
    logic [3:0] sl8;
    logic [7:0] lut0;
    logic [0:0] sl9;
    logic [0:0] sl10;
    logic [29:0] sl11;
    logic [30:0] lut1;
    logic [60:0] sum0;

    assign in0 = A;

    assign in1 = B;

    assign sl0 = in0[29:0];

    assign sl1 = sl0[25:0];

    assign sl2 = in1[22:0];

    (* keep_hierarchy = "yes" *) ev_ld_io4_k_bu_dp_bqq_versal_dsp58_signed_multiplier_uu_26x23 u_dsp0 (
        .clk   (clk),
        .reset (reset),
        .A     (sl1),
        .B     (sl2),
        .P     (dsp0)
    );

    assign sl3 = sl0[25:0];

    assign sl4 = in1[29:23];

    (* keep_hierarchy = "yes" *) ev_ld_io4_k_bu_dp_bqq_versal_dsp58_signed_multiplier_uu_26x7 u_dsp1 (
        .clk   (clk),
        .reset (reset),
        .A     (sl3),
        .B     (sl4),
        .P     (dsp1)
    );

    assign sl5 = sl0[29:26];

    assign sl6 = in1[25:0];

    (* keep_hierarchy = "yes" *) ev_ld_io4_k_bu_dp_bqq_versal_dsp58_signed_multiplier_uu_4x26_t u_dsp2 (
        .clk   (clk),
        .reset (reset),
        .A     (sl5),
        .B     (sl6),
        .P     (dsp2)
    );

    assign sl7 = sl0[29:26];

    assign sl8 = in1[29:26];

    (* keep_hierarchy = "yes" *) ev_ld_io4_k_bu_dp_bqq_lut_bmult_uu_4x4 u_lut0 (
        .clk   (clk),
        .A     (sl7),
        .B     (sl8),
        .P     (lut0)
    );

    assign sl9 = in0[30:30];

    assign sl10 = sl9[0:0];

    assign sl11 = in1[29:0];

    (* keep_hierarchy = "yes" *) ev_ld_io4_k_bu_dp_bqq_lut_bmult_uu_1x30 u_lut1 (
        .clk   (clk),
        .A     (sl10),
        .B     (sl11),
        .P     (lut1)
    );

    (* keep_hierarchy = "yes" *) ev_ld_io4_k_bu_dp_bqq_terminal_bitheap_61_853f2a950c u_sum0 (
        .clk   (clk),
        .term0 (dsp0),
        .term1 (dsp1),
        .term2 (dsp2),
        .term3 (lut0),
        .term4 (lut1),
        .P     (sum0)
    );

    assign P = sum0;

endmodule
