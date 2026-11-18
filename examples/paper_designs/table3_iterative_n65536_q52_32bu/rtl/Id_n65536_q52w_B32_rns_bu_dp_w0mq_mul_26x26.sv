`timescale 1ns / 1ps

module Id_n65536_q52w_B32_rns_bu_dp_w0mq_mul_26x26 (
    input  logic clk,
    input  logic reset,
    input  logic [25:0] A,
    input  logic [25:0] B,
    output logic [51:0] P
);

    logic [25:0] in0;
    logic [25:0] in1;
    logic [25:0] sl0;
    logic [22:0] sl1;
    logic [48:0] dsp0;
    logic [25:0] sl2;
    logic [2:0] sl3;
    logic [28:0] dsp1;
    logic [51:0] sum0;

    assign in0 = A;

    assign in1 = B;

    assign sl0 = in0[25:0];

    assign sl1 = in1[22:0];

    (* keep_hierarchy = "yes" *) Id_n65536_q52w_B32_rns_bu_dp_w0mq_versal_dsp58_signed_multiplier_uu_26x23 u_dsp0 (
        .clk   (clk),
        .reset (reset),
        .A     (sl0),
        .B     (sl1),
        .P     (dsp0)
    );

    assign sl2 = in0[25:0];

    assign sl3 = in1[25:23];

    (* keep_hierarchy = "yes" *) Id_n65536_q52w_B32_rns_bu_dp_w0mq_versal_dsp58_signed_multiplier_uu_26x3 u_dsp1 (
        .clk   (clk),
        .reset (reset),
        .A     (sl2),
        .B     (sl3),
        .P     (dsp1)
    );

    (* keep_hierarchy = "yes" *) Id_n65536_q52w_B32_rns_bu_dp_w0mq_terminal_bitheap_52_5cfdc20381 u_sum0 (
        .clk   (clk),
        .term0 (dsp0),
        .term1 (dsp1),
        .P     (sum0)
    );

    assign P = sum0;

endmodule
