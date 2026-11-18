`timescale 1ns / 1ps

module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p2_core_s3_bu_dp_w2mq_mul_17x45 (
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
    logic signed [199:0] lut0;
    logic [61:0] sum0;

    assign in0 = A;

    assign in1 = B;

    assign sl0 = in0[16:0];

    assign sl1 = in1[25:0];

    (* keep_hierarchy = "yes" *) ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p2_core_s3_bu_dp_w2mq_versal_dsp58_signed_multiplier_uu_17x26_t u_dsp0 (
        .clk   (clk),
        .reset (reset),
        .A     (sl0),
        .B     (sl1),
        .P     (dsp0)
    );

    assign sl2 = in0[16:0];

    assign sl3 = in1[44:26];

    (* keep_hierarchy = "yes" *) ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p2_core_s3_bu_dp_w2mq_lut_pp_uu_17x19 u_lut0 (
        .clk   (clk),
        .A     (sl2),
        .B     (sl3),
        .P     (lut0)
    );

    (* keep_hierarchy = "yes" *) ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p2_core_s3_bu_dp_w2mq_terminal_bitheap_62_b47782932a u_sum0 (
        .clk   (clk),
        .term0 (dsp0),
        .term1 (lut0),
        .P     (sum0)
    );

    assign P = sum0;

endmodule
