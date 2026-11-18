`timescale 1ns / 1ps

module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_k_p0_core_s0_bu_dp_w3mq_terminal_bitheap_56_477ddf788c (
    input  logic clk,
    input  logic [36:0] term0,
    input  logic [29:0] term1,
    output logic [55:0] P
);

    // tallest column has only 2 bit(s), no GPC compressor tree needed; sign_mode=extend
    logic [55:0] sum_comb;

    logic [55:0] addend0;
    assign addend0 = 56'(term0);
    logic [55:0] addend1;
    assign addend1 = (56'(term1) << 26);

    assign sum_comb = addend0 + addend1;

    logic [55:0] stage [0:0];
    always_ff @(posedge clk) begin
        stage[0] <= sum_comb;
    end
    assign P = $unsigned(stage[0]);

endmodule

