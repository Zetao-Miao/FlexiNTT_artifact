`timescale 1ns / 1ps

module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p3_core_twist_w3mq_mul_11x45 (
    input  logic clk,
    input  logic reset,
    input  logic [10:0] A,
    input  logic [44:0] B,
    output logic [55:0] P
);

    logic [10:0] in0;
    logic [44:0] in1;
    logic [10:0] sl0;
    logic [25:0] sl1;
    logic [36:0] dsp0;
    logic [10:0] sl2;
    logic [18:0] sl3;
    logic signed [139:0] lut0;
    logic [55:0] sum0;

    assign in0 = A;

    assign in1 = B;

    assign sl0 = in0[10:0];

    assign sl1 = in1[25:0];

    (* keep_hierarchy = "yes" *) ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p3_core_twist_w3mq_versal_dsp58_signed_multiplier_uu_11x26_t u_dsp0 (
        .clk   (clk),
        .reset (reset),
        .A     (sl0),
        .B     (sl1),
        .P     (dsp0)
    );

    assign sl2 = in0[10:0];

    assign sl3 = in1[44:26];

    (* keep_hierarchy = "yes" *) ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p3_core_twist_w3mq_lut_pp_uu_11x19 u_lut0 (
        .clk   (clk),
        .A     (sl2),
        .B     (sl3),
        .P     (lut0)
    );

    (* keep_hierarchy = "yes" *) ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p3_core_twist_w3mq_terminal_bitheap_56_ac7e01b123 u_sum0 (
        .clk   (clk),
        .term0 (dsp0),
        .term1 (lut0),
        .P     (sum0)
    );

    assign P = sum0;

endmodule
