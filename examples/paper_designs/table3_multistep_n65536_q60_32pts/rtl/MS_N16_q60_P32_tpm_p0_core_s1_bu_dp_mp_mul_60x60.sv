`timescale 1ns / 1ps

module MS_N16_q60_P32_tpm_p0_core_s1_bu_dp_mp_mul_60x60 (
    input  logic clk,
    input  logic reset,
    input  logic [59:0] A,
    input  logic [59:0] B,
    output logic [119:0] P
);

    logic [59:0] in0;
    logic [59:0] in1;
    logic [25:0] sl0;
    logic [45:0] sl1;
    logic [71:0] dsp0;
    logic [25:0] sl2;
    logic [45:0] sl3;
    logic [71:0] dsp1;
    logic [25:0] sl4;
    logic [13:0] sl5;
    logic [39:0] dsp2;
    logic [25:0] sl6;
    logic [13:0] sl7;
    logic [39:0] dsp3;
    logic [7:0] sl8;
    logic [25:0] sl9;
    logic [33:0] dsp4;
    logic [7:0] sl10;
    logic [25:0] sl11;
    logic [33:0] dsp5;
    logic [7:0] sl12;
    logic [7:0] sl13;
    logic [15:0] dsp6;
    logic [39:0] dly0;
    logic [39:0] dly1;
    logic [33:0] dly2;
    logic [33:0] dly3;
    logic [15:0] dly4;
    logic [119:0] sum0;

    assign in0 = A;

    assign in1 = B;

    assign sl0 = in0[25:0];

    assign sl1 = in1[45:0];

    (* keep_hierarchy = "yes" *) MS_N16_q60_P32_tpm_p0_core_s1_bu_dp_mp_versal_dsp58_chain_uu_26x46_x2 u_dsp0 (
        .clk   (clk),
        .reset (reset),
        .A     (sl0),
        .B     (sl1),
        .P     (dsp0)
    );

    assign sl2 = in0[51:26];

    assign sl3 = in1[45:0];

    (* keep_hierarchy = "yes" *) MS_N16_q60_P32_tpm_p0_core_s1_bu_dp_mp_versal_dsp58_chain_uu_26x46_x2 u_dsp1 (
        .clk   (clk),
        .reset (reset),
        .A     (sl2),
        .B     (sl3),
        .P     (dsp1)
    );

    assign sl4 = in0[25:0];

    assign sl5 = in1[59:46];

    (* keep_hierarchy = "yes" *) MS_N16_q60_P32_tpm_p0_core_s1_bu_dp_mp_versal_dsp58_signed_multiplier_uu_26x14 u_dsp2 (
        .clk   (clk),
        .reset (reset),
        .A     (sl4),
        .B     (sl5),
        .P     (dsp2)
    );

    assign sl6 = in0[51:26];

    assign sl7 = in1[59:46];

    (* keep_hierarchy = "yes" *) MS_N16_q60_P32_tpm_p0_core_s1_bu_dp_mp_versal_dsp58_signed_multiplier_uu_26x14 u_dsp3 (
        .clk   (clk),
        .reset (reset),
        .A     (sl6),
        .B     (sl7),
        .P     (dsp3)
    );

    assign sl8 = in0[59:52];

    assign sl9 = in1[25:0];

    (* keep_hierarchy = "yes" *) MS_N16_q60_P32_tpm_p0_core_s1_bu_dp_mp_versal_dsp58_signed_multiplier_uu_8x26_t u_dsp4 (
        .clk   (clk),
        .reset (reset),
        .A     (sl8),
        .B     (sl9),
        .P     (dsp4)
    );

    assign sl10 = in0[59:52];

    assign sl11 = in1[51:26];

    (* keep_hierarchy = "yes" *) MS_N16_q60_P32_tpm_p0_core_s1_bu_dp_mp_versal_dsp58_signed_multiplier_uu_8x26_t u_dsp5 (
        .clk   (clk),
        .reset (reset),
        .A     (sl10),
        .B     (sl11),
        .P     (dsp5)
    );

    assign sl12 = in0[59:52];

    assign sl13 = in1[59:52];

    (* keep_hierarchy = "yes" *) MS_N16_q60_P32_tpm_p0_core_s1_bu_dp_mp_versal_dsp58_signed_multiplier_uu_8x8 u_dsp6 (
        .clk   (clk),
        .reset (reset),
        .A     (sl12),
        .B     (sl13),
        .P     (dsp6)
    );

    (* keep_hierarchy = "yes" *) MS_N16_q60_P32_tpm_p0_core_s1_bu_dp_mp_delay_line #(
        .WIDTH  (40),
        .CYCLES (1)
    ) u_dly0 (
        .clk (clk),
        .d   (dsp2),
        .q   (dly0)
    );

    (* keep_hierarchy = "yes" *) MS_N16_q60_P32_tpm_p0_core_s1_bu_dp_mp_delay_line #(
        .WIDTH  (40),
        .CYCLES (1)
    ) u_dly1 (
        .clk (clk),
        .d   (dsp3),
        .q   (dly1)
    );

    (* keep_hierarchy = "yes" *) MS_N16_q60_P32_tpm_p0_core_s1_bu_dp_mp_delay_line #(
        .WIDTH  (34),
        .CYCLES (1)
    ) u_dly2 (
        .clk (clk),
        .d   (dsp4),
        .q   (dly2)
    );

    (* keep_hierarchy = "yes" *) MS_N16_q60_P32_tpm_p0_core_s1_bu_dp_mp_delay_line #(
        .WIDTH  (34),
        .CYCLES (1)
    ) u_dly3 (
        .clk (clk),
        .d   (dsp5),
        .q   (dly3)
    );

    (* keep_hierarchy = "yes" *) MS_N16_q60_P32_tpm_p0_core_s1_bu_dp_mp_delay_line #(
        .WIDTH  (16),
        .CYCLES (1)
    ) u_dly4 (
        .clk (clk),
        .d   (dsp6),
        .q   (dly4)
    );

    (* keep_hierarchy = "yes" *) MS_N16_q60_P32_tpm_p0_core_s1_bu_dp_mp_terminal_bitheap_120_7cdbb5971e u_sum0 (
        .clk   (clk),
        .term0 (dsp0),
        .term1 (dsp1),
        .term2 (dly0),
        .term3 (dly1),
        .term4 (dly2),
        .term5 (dly3),
        .term6 (dly4),
        .P     (sum0)
    );

    assign P = sum0;

endmodule
