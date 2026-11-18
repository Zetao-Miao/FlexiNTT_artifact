`timescale 1ns / 1ps

module ev_ld_io4_k_bu_dp_mp_mul_30x30 (
    input  logic clk,
    input  logic reset,
    input  logic [29:0] A,
    input  logic [29:0] B,
    output logic [59:0] P
);

    logic [29:0] in0;
    logic [29:0] in1;
    logic [25:0] sl0;
    logic [22:0] sl1;
    logic [48:0] dsp0;
    logic [25:0] sl2;
    logic [6:0] sl3;
    logic [32:0] dsp1;
    logic [3:0] sl4;
    logic [25:0] sl5;
    logic [29:0] dsp2;
    logic [3:0] sl6;
    logic [3:0] sl7;
    logic [7:0] lut0;
    logic [59:0] sum0;

    assign in0 = A;

    assign in1 = B;

    assign sl0 = in0[25:0];

    assign sl1 = in1[22:0];

    (* keep_hierarchy = "yes" *) ev_ld_io4_k_bu_dp_mp_versal_dsp58_signed_multiplier_uu_26x23 u_dsp0 (
        .clk   (clk),
        .reset (reset),
        .A     (sl0),
        .B     (sl1),
        .P     (dsp0)
    );

    assign sl2 = in0[25:0];

    assign sl3 = in1[29:23];

    (* keep_hierarchy = "yes" *) ev_ld_io4_k_bu_dp_mp_versal_dsp58_signed_multiplier_uu_26x7 u_dsp1 (
        .clk   (clk),
        .reset (reset),
        .A     (sl2),
        .B     (sl3),
        .P     (dsp1)
    );

    assign sl4 = in0[29:26];

    assign sl5 = in1[25:0];

    (* keep_hierarchy = "yes" *) ev_ld_io4_k_bu_dp_mp_versal_dsp58_signed_multiplier_uu_4x26_t u_dsp2 (
        .clk   (clk),
        .reset (reset),
        .A     (sl4),
        .B     (sl5),
        .P     (dsp2)
    );

    assign sl6 = in0[29:26];

    assign sl7 = in1[29:26];

    (* keep_hierarchy = "yes" *) ev_ld_io4_k_bu_dp_mp_lut_bmult_uu_4x4 u_lut0 (
        .clk   (clk),
        .A     (sl6),
        .B     (sl7),
        .P     (lut0)
    );

    (* keep_hierarchy = "yes" *) ev_ld_io4_k_bu_dp_mp_terminal_bitheap_60_8f2ace4be0 u_sum0 (
        .clk   (clk),
        .term0 (dsp0),
        .term1 (dsp1),
        .term2 (dsp2),
        .term3 (lut0),
        .P     (sum0)
    );

    assign P = sum0;

endmodule
