`timescale 1ns / 1ps

module Ib_n8192_q36b_B512_auto_rns_rec_gen_t_mul_36x36 (
    input  logic clk,
    input  logic reset,
    input  logic [35:0] A,
    input  logic [35:0] B,
    output logic [71:0] P
);

    logic [35:0] in0;
    logic [35:0] in1;
    logic [25:0] sl0;
    logic [22:0] sl1;
    logic [48:0] dsp0;
    logic [25:0] sl2;
    logic [12:0] sl3;
    logic [38:0] dsp1;
    logic [9:0] sl4;
    logic [25:0] sl5;
    logic [35:0] dsp2;
    logic [9:0] sl6;
    logic [9:0] sl7;
    logic [19:0] dsp3;
    logic [71:0] sum0;

    assign in0 = A;

    assign in1 = B;

    assign sl0 = in0[25:0];

    assign sl1 = in1[22:0];

    (* keep_hierarchy = "yes" *) Ib_n8192_q36b_B512_auto_rns_rec_gen_t_versal_dsp58_signed_multiplier_uu_26x23 u_dsp0 (
        .clk   (clk),
        .reset (reset),
        .A     (sl0),
        .B     (sl1),
        .P     (dsp0)
    );

    assign sl2 = in0[25:0];

    assign sl3 = in1[35:23];

    (* keep_hierarchy = "yes" *) Ib_n8192_q36b_B512_auto_rns_rec_gen_t_versal_dsp58_signed_multiplier_uu_26x13 u_dsp1 (
        .clk   (clk),
        .reset (reset),
        .A     (sl2),
        .B     (sl3),
        .P     (dsp1)
    );

    assign sl4 = in0[35:26];

    assign sl5 = in1[25:0];

    (* keep_hierarchy = "yes" *) Ib_n8192_q36b_B512_auto_rns_rec_gen_t_versal_dsp58_signed_multiplier_uu_10x26_t u_dsp2 (
        .clk   (clk),
        .reset (reset),
        .A     (sl4),
        .B     (sl5),
        .P     (dsp2)
    );

    assign sl6 = in0[35:26];

    assign sl7 = in1[35:26];

    (* keep_hierarchy = "yes" *) Ib_n8192_q36b_B512_auto_rns_rec_gen_t_versal_dsp58_signed_multiplier_uu_10x10 u_dsp3 (
        .clk   (clk),
        .reset (reset),
        .A     (sl6),
        .B     (sl7),
        .P     (dsp3)
    );

    (* keep_hierarchy = "yes" *) Ib_n8192_q36b_B512_auto_rns_rec_gen_t_terminal_bitheap_72_53b5667603 u_sum0 (
        .clk   (clk),
        .term0 (dsp0),
        .term1 (dsp1),
        .term2 (dsp2),
        .term3 (dsp3),
        .P     (sum0)
    );

    assign P = sum0;

endmodule
