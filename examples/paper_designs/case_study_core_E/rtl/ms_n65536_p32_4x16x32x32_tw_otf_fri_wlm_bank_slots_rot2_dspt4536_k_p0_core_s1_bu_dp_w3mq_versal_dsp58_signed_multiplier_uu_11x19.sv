`timescale 1ns / 1ps

module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core_s1_bu_dp_w3mq_versal_dsp58_signed_multiplier_uu_11x19 (
    input  logic clk,
    input  logic reset,
    input  logic [10:0] A,
    input  logic [18:0] B,
    output logic [29:0] P
);

    logic signed [26:0] inner_a;
    logic signed [23:0] inner_b;
    logic signed [50:0] inner_p;

    assign inner_a = $signed({16'b0, A});
    assign inner_b = $signed({5'b0, B});

    // seed library declares inner latency = 1 cycle(s)
    (* keep_hierarchy = "yes" *) ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p0_core_s1_bu_dp_w3mq_SingleDSP #(
        .LATENCY      (1),
        .OUT_REG      (0)
    ) u_inner (
        .clk (clk),
        .reset (reset),
        .in_valid (1'b1),
        .X   (inner_a),
        .Y   (inner_b),
        .P   (inner_p)
    );

    assign P = $unsigned(inner_p[29:0]);

endmodule

