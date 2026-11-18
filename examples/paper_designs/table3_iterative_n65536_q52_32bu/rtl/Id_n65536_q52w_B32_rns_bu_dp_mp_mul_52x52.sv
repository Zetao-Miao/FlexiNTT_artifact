`timescale 1ns / 1ps

module Id_n65536_q52w_B32_rns_bu_dp_mp_mul_52x52 (
    input  logic clk,
    input  logic reset,
    input  logic [51:0] A,
    input  logic [51:0] B,
    output logic [103:0] P
);

    logic [51:0] in0;
    logic [51:0] in1;
    logic [25:0] sl0;
    logic [45:0] sl1;
    logic [71:0] dsp0;
    logic [25:0] sl2;
    logic [45:0] sl3;
    logic [71:0] dsp1;
    logic [25:0] sl4;
    logic [5:0] sl5;
    logic [31:0] dsp2;
    logic [25:0] sl6;
    logic [5:0] sl7;
    logic [31:0] dsp3;
    logic [31:0] dly0;
    logic [31:0] dly1;
    logic [103:0] sum0;

    assign in0 = A;

    assign in1 = B;

    assign sl0 = in0[25:0];

    assign sl1 = in1[45:0];

    (* keep_hierarchy = "yes" *) Id_n65536_q52w_B32_rns_bu_dp_mp_versal_dsp58_chain_uu_26x46_x2 u_dsp0 (
        .clk   (clk),
        .reset (reset),
        .A     (sl0),
        .B     (sl1),
        .P     (dsp0)
    );

    assign sl2 = in0[51:26];

    assign sl3 = in1[45:0];

    (* keep_hierarchy = "yes" *) Id_n65536_q52w_B32_rns_bu_dp_mp_versal_dsp58_chain_uu_26x46_x2 u_dsp1 (
        .clk   (clk),
        .reset (reset),
        .A     (sl2),
        .B     (sl3),
        .P     (dsp1)
    );

    assign sl4 = in0[25:0];

    assign sl5 = in1[51:46];

    (* keep_hierarchy = "yes" *) Id_n65536_q52w_B32_rns_bu_dp_mp_versal_dsp58_signed_multiplier_uu_26x6 u_dsp2 (
        .clk   (clk),
        .reset (reset),
        .A     (sl4),
        .B     (sl5),
        .P     (dsp2)
    );

    assign sl6 = in0[51:26];

    assign sl7 = in1[51:46];

    (* keep_hierarchy = "yes" *) Id_n65536_q52w_B32_rns_bu_dp_mp_versal_dsp58_signed_multiplier_uu_26x6 u_dsp3 (
        .clk   (clk),
        .reset (reset),
        .A     (sl6),
        .B     (sl7),
        .P     (dsp3)
    );

    (* keep_hierarchy = "yes" *) Id_n65536_q52w_B32_rns_bu_dp_mp_delay_line #(
        .WIDTH  (32),
        .CYCLES (1)
    ) u_dly0 (
        .clk (clk),
        .d   (dsp2),
        .q   (dly0)
    );

    (* keep_hierarchy = "yes" *) Id_n65536_q52w_B32_rns_bu_dp_mp_delay_line #(
        .WIDTH  (32),
        .CYCLES (1)
    ) u_dly1 (
        .clk (clk),
        .d   (dsp3),
        .q   (dly1)
    );

    (* keep_hierarchy = "yes" *) Id_n65536_q52w_B32_rns_bu_dp_mp_terminal_bitheap_104_1358888cf6 u_sum0 (
        .clk   (clk),
        .term0 (dsp0),
        .term1 (dsp1),
        .term2 (dly0),
        .term3 (dly1),
        .P     (sum0)
    );

    assign P = sum0;

endmodule
