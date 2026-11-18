`timescale 1ns / 1ps

module LDb_rom1_s4_bu_dp_w0mq_mul_16x16 (
    input  logic clk,
    input  logic reset,
    input  logic [15:0] A,
    input  logic [15:0] B,
    output logic [31:0] P
);

    logic [15:0] in0;
    logic [15:0] in1;
    logic [15:0] sl0;
    logic [15:0] sl1;
    logic [31:0] dsp0;

    assign in0 = A;

    assign in1 = B;

    assign sl0 = in0[15:0];

    assign sl1 = in1[15:0];

    (* keep_hierarchy = "yes" *) LDb_rom1_s4_bu_dp_w0mq_versal_dsp58_signed_multiplier_uu_16x16 u_dsp0 (
        .clk   (clk),
        .reset (reset),
        .A     (sl0),
        .B     (sl1),
        .P     (dsp0)
    );

    assign P = dsp0;

endmodule
