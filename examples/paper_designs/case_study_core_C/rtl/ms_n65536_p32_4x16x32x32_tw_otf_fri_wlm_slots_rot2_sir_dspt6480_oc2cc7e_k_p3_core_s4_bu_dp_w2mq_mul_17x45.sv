`timescale 1ns / 1ps

module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt6480_oc2cc7e_k_p3_core_s4_bu_dp_w2mq_mul_17x45 (
    input  logic clk,
    input  logic reset,
    input  logic [16:0] A,
    input  logic [44:0] B,
    output logic [61:0] P
);

    logic [16:0] in0;
    logic [44:0] in1;
    logic [16:0] sl0;
    logic [25:0] sl1;
    logic [42:0] dsp0;
    logic [16:0] sl2;
    logic [18:0] sl3;
    logic [35:0] dsp1;
    logic [61:0] sum0;

    assign in0 = A;

    assign in1 = B;

    assign sl0 = in0[16:0];

    assign sl1 = in1[25:0];

    (* keep_hierarchy = "yes" *) ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt6480_oc2cc7e_k_p3_core_s4_bu_dp_w2mq_versal_dsp58_signed_multiplier_uu_17x26_t u_dsp0 (
        .clk   (clk),
        .reset (reset),
        .A     (sl0),
        .B     (sl1),
        .P     (dsp0)
    );

    assign sl2 = in0[16:0];

    assign sl3 = in1[44:26];

    (* keep_hierarchy = "yes" *) ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt6480_oc2cc7e_k_p3_core_s4_bu_dp_w2mq_versal_dsp58_signed_multiplier_uu_17x19 u_dsp1 (
        .clk   (clk),
        .reset (reset),
        .A     (sl2),
        .B     (sl3),
        .P     (dsp1)
    );

    (* keep_hierarchy = "yes" *) ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt6480_oc2cc7e_k_p3_core_s4_bu_dp_w2mq_terminal_bitheap_62_fee6e50bbd u_sum0 (
        .clk   (clk),
        .term0 (dsp0),
        .term1 (dsp1),
        .P     (sum0)
    );

    assign P = sum0;

endmodule
