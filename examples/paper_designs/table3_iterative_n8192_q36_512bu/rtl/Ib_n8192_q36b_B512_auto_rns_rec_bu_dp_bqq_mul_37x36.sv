`timescale 1ns / 1ps

module Ib_n8192_q36b_B512_auto_rns_rec_bu_dp_bqq_mul_37x36 (
    input  logic clk,
    input  logic reset,
    input  logic [36:0] A,
    input  logic [35:0] B,
    output logic [72:0] P
);

    logic [36:0] in0;
    logic [35:0] in1;
    logic [35:0] sl0;
    logic [25:0] sl1;
    logic [22:0] sl2;
    logic [48:0] dsp0;
    logic [25:0] sl3;
    logic [12:0] sl4;
    logic [38:0] dsp1;
    logic [9:0] sl5;
    logic [25:0] sl6;
    logic [35:0] dsp2;
    logic [9:0] sl7;
    logic [9:0] sl8;
    logic [19:0] dsp3;
    logic [0:0] sl9;
    logic [0:0] sl10;
    logic [35:0] sl11;
    logic [36:0] lut0;
    logic [72:0] sum0;

    assign in0 = A;

    assign in1 = B;

    assign sl0 = in0[35:0];

    assign sl1 = sl0[25:0];

    assign sl2 = in1[22:0];

    (* keep_hierarchy = "yes" *) Ib_n8192_q36b_B512_auto_rns_rec_bu_dp_bqq_versal_dsp58_signed_multiplier_uu_26x23 u_dsp0 (
        .clk   (clk),
        .reset (reset),
        .A     (sl1),
        .B     (sl2),
        .P     (dsp0)
    );

    assign sl3 = sl0[25:0];

    assign sl4 = in1[35:23];

    (* keep_hierarchy = "yes" *) Ib_n8192_q36b_B512_auto_rns_rec_bu_dp_bqq_versal_dsp58_signed_multiplier_uu_26x13 u_dsp1 (
        .clk   (clk),
        .reset (reset),
        .A     (sl3),
        .B     (sl4),
        .P     (dsp1)
    );

    assign sl5 = sl0[35:26];

    assign sl6 = in1[25:0];

    (* keep_hierarchy = "yes" *) Ib_n8192_q36b_B512_auto_rns_rec_bu_dp_bqq_versal_dsp58_signed_multiplier_uu_10x26_t u_dsp2 (
        .clk   (clk),
        .reset (reset),
        .A     (sl5),
        .B     (sl6),
        .P     (dsp2)
    );

    assign sl7 = sl0[35:26];

    assign sl8 = in1[35:26];

    (* keep_hierarchy = "yes" *) Ib_n8192_q36b_B512_auto_rns_rec_bu_dp_bqq_versal_dsp58_signed_multiplier_uu_10x10 u_dsp3 (
        .clk   (clk),
        .reset (reset),
        .A     (sl7),
        .B     (sl8),
        .P     (dsp3)
    );

    assign sl9 = in0[36:36];

    assign sl10 = sl9[0:0];

    assign sl11 = in1[35:0];

    (* keep_hierarchy = "yes" *) Ib_n8192_q36b_B512_auto_rns_rec_bu_dp_bqq_lut_bmult_uu_1x36 u_lut0 (
        .clk   (clk),
        .A     (sl10),
        .B     (sl11),
        .P     (lut0)
    );

    (* keep_hierarchy = "yes" *) Ib_n8192_q36b_B512_auto_rns_rec_bu_dp_bqq_terminal_bitheap_73_88d0fc7066 u_sum0 (
        .clk   (clk),
        .term0 (dsp0),
        .term1 (dsp1),
        .term2 (dsp2),
        .term3 (dsp3),
        .term4 (lut0),
        .P     (sum0)
    );

    assign P = sum0;

endmodule
