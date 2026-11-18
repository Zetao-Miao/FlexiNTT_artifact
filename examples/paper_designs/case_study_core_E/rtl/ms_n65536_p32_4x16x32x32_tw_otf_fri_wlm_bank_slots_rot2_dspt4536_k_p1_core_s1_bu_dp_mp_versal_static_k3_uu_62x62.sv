`timescale 1ns / 1ps

module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p1_core_s1_bu_dp_mp_versal_static_k3_uu_62x62 (
    input  logic clk,
    input  logic reset,
    input  logic [61:0] A,
    input  logic [61:0] B,
    output logic [123:0] P
);

    logic signed [69:0] inner_a;
    logic signed [66:0] inner_b;
    logic signed [136:0] inner_p;

    assign inner_a = $signed({8'b0, A});
    assign inner_b = $signed({5'b0, B});

    // seed library declares inner latency = 5 cycle(s)
    (* keep_hierarchy = "yes" *) ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p1_core_s1_bu_dp_mp_Karatsuba3x3_lat5 u_inner (
        .clk (clk),
        .reset (reset),
        .in_valid (1'b1),
        .X   (inner_a),
        .Y   (inner_b),
        .P   (inner_p)
    );

    assign P = $unsigned(inner_p[123:0]);

endmodule

