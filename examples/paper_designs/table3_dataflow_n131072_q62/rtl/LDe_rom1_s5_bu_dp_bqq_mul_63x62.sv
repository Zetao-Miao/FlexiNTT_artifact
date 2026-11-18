`timescale 1ns / 1ps

module LDe_rom1_s5_bu_dp_bqq_mul_63x62 (
    input  logic clk,
    input  logic reset,
    input  logic [62:0] A,
    input  logic [61:0] B,
    output logic [124:0] P
);

    logic [62:0] in0;
    logic [61:0] in1;
    logic [61:0] sl0;
    logic [25:0] sl1;
    logic [45:0] sl2;
    logic [71:0] dsp0;
    logic [25:0] sl3;
    logic [45:0] sl4;
    logic [71:0] dsp1;
    logic [25:0] sl5;
    logic [15:0] sl6;
    logic [41:0] dsp2;
    logic [25:0] sl7;
    logic [15:0] sl8;
    logic [41:0] dsp3;
    logic [9:0] sl9;
    logic [25:0] sl10;
    logic [35:0] dsp4;
    logic [9:0] sl11;
    logic [25:0] sl12;
    logic [35:0] dsp5;
    logic [9:0] sl13;
    logic [9:0] sl14;
    logic [19:0] dsp6;
    logic [0:0] sl15;
    logic [0:0] sl16;
    logic [61:0] sl17;
    logic [62:0] lut0;
    logic [41:0] dly0;
    logic [41:0] dly1;
    logic [35:0] dly2;
    logic [35:0] dly3;
    logic [19:0] dly4;
    logic [62:0] dly5;
    logic [124:0] sum0;

    assign in0 = A;

    assign in1 = B;

    assign sl0 = in0[61:0];

    assign sl1 = sl0[25:0];

    assign sl2 = in1[45:0];

    (* keep_hierarchy = "yes" *) LDe_rom1_s5_bu_dp_bqq_versal_dsp58_chain_uu_26x46_x2 u_dsp0 (
        .clk   (clk),
        .reset (reset),
        .A     (sl1),
        .B     (sl2),
        .P     (dsp0)
    );

    assign sl3 = sl0[51:26];

    assign sl4 = in1[45:0];

    (* keep_hierarchy = "yes" *) LDe_rom1_s5_bu_dp_bqq_versal_dsp58_chain_uu_26x46_x2 u_dsp1 (
        .clk   (clk),
        .reset (reset),
        .A     (sl3),
        .B     (sl4),
        .P     (dsp1)
    );

    assign sl5 = sl0[25:0];

    assign sl6 = in1[61:46];

    (* keep_hierarchy = "yes" *) LDe_rom1_s5_bu_dp_bqq_versal_dsp58_signed_multiplier_uu_26x16 u_dsp2 (
        .clk   (clk),
        .reset (reset),
        .A     (sl5),
        .B     (sl6),
        .P     (dsp2)
    );

    assign sl7 = sl0[51:26];

    assign sl8 = in1[61:46];

    (* keep_hierarchy = "yes" *) LDe_rom1_s5_bu_dp_bqq_versal_dsp58_signed_multiplier_uu_26x16 u_dsp3 (
        .clk   (clk),
        .reset (reset),
        .A     (sl7),
        .B     (sl8),
        .P     (dsp3)
    );

    assign sl9 = sl0[61:52];

    assign sl10 = in1[25:0];

    (* keep_hierarchy = "yes" *) LDe_rom1_s5_bu_dp_bqq_versal_dsp58_signed_multiplier_uu_10x26_t u_dsp4 (
        .clk   (clk),
        .reset (reset),
        .A     (sl9),
        .B     (sl10),
        .P     (dsp4)
    );

    assign sl11 = sl0[61:52];

    assign sl12 = in1[51:26];

    (* keep_hierarchy = "yes" *) LDe_rom1_s5_bu_dp_bqq_versal_dsp58_signed_multiplier_uu_10x26_t u_dsp5 (
        .clk   (clk),
        .reset (reset),
        .A     (sl11),
        .B     (sl12),
        .P     (dsp5)
    );

    assign sl13 = sl0[61:52];

    assign sl14 = in1[61:52];

    (* keep_hierarchy = "yes" *) LDe_rom1_s5_bu_dp_bqq_versal_dsp58_signed_multiplier_uu_10x10 u_dsp6 (
        .clk   (clk),
        .reset (reset),
        .A     (sl13),
        .B     (sl14),
        .P     (dsp6)
    );

    assign sl15 = in0[62:62];

    assign sl16 = sl15[0:0];

    assign sl17 = in1[61:0];

    (* keep_hierarchy = "yes" *) LDe_rom1_s5_bu_dp_bqq_lut_bmult_uu_1x62 u_lut0 (
        .clk   (clk),
        .A     (sl16),
        .B     (sl17),
        .P     (lut0)
    );

    (* keep_hierarchy = "yes" *) LDe_rom1_s5_bu_dp_bqq_delay_line #(
        .WIDTH  (42),
        .CYCLES (1)
    ) u_dly0 (
        .clk (clk),
        .d   (dsp2),
        .q   (dly0)
    );

    (* keep_hierarchy = "yes" *) LDe_rom1_s5_bu_dp_bqq_delay_line #(
        .WIDTH  (42),
        .CYCLES (1)
    ) u_dly1 (
        .clk (clk),
        .d   (dsp3),
        .q   (dly1)
    );

    (* keep_hierarchy = "yes" *) LDe_rom1_s5_bu_dp_bqq_delay_line #(
        .WIDTH  (36),
        .CYCLES (1)
    ) u_dly2 (
        .clk (clk),
        .d   (dsp4),
        .q   (dly2)
    );

    (* keep_hierarchy = "yes" *) LDe_rom1_s5_bu_dp_bqq_delay_line #(
        .WIDTH  (36),
        .CYCLES (1)
    ) u_dly3 (
        .clk (clk),
        .d   (dsp5),
        .q   (dly3)
    );

    (* keep_hierarchy = "yes" *) LDe_rom1_s5_bu_dp_bqq_delay_line #(
        .WIDTH  (20),
        .CYCLES (1)
    ) u_dly4 (
        .clk (clk),
        .d   (dsp6),
        .q   (dly4)
    );

    (* keep_hierarchy = "yes" *) LDe_rom1_s5_bu_dp_bqq_delay_line #(
        .WIDTH  (63),
        .CYCLES (1)
    ) u_dly5 (
        .clk (clk),
        .d   (lut0),
        .q   (dly5)
    );

    (* keep_hierarchy = "yes" *) LDe_rom1_s5_bu_dp_bqq_terminal_bitheap_125_b5a932aa49 u_sum0 (
        .clk   (clk),
        .term0 (dsp0),
        .term1 (dsp1),
        .term2 (dly0),
        .term3 (dly1),
        .term4 (dly2),
        .term5 (dly3),
        .term6 (dly4),
        .term7 (dly5),
        .P     (sum0)
    );

    assign P = sum0;

endmodule
