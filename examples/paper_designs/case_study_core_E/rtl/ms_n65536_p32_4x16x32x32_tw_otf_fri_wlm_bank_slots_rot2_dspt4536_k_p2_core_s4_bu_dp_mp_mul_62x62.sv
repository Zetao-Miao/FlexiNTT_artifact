`timescale 1ns / 1ps

module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p2_core_s4_bu_dp_mp_mul_62x62 (
    input  logic clk,
    input  logic reset,
    input  logic [61:0] A,
    input  logic [61:0] B,
    output logic [123:0] P
);

    logic [61:0] in0;
    logic [61:0] in1;
    logic [61:0] sl0;
    logic [61:0] sl1;
    logic [123:0] dsp0;

    assign in0 = A;

    assign in1 = B;

    assign sl0 = in0[61:0];

    assign sl1 = in1[61:0];

    (* keep_hierarchy = "yes" *) ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p2_core_s4_bu_dp_mp_versal_static_k3_uu_62x62 u_dsp0 (
        .clk   (clk),
        .reset (reset),
        .A     (sl0),
        .B     (sl1),
        .P     (dsp0)
    );

    assign P = dsp0;

endmodule
