`timescale 1ns / 1ps

module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt6480_oc2cc7e_k_p1_core_s1_bu_dp_w2mq_terminal_bitheap_62_fee6e50bbd (
    input  logic clk,
    input  logic [42:0] term0,
    input  logic [35:0] term1,
    output logic [61:0] P
);

    // tallest column has only 2 bit(s), no GPC compressor tree needed; sign_mode=extend
    logic [61:0] sum_comb;

    logic [61:0] addend0;
    assign addend0 = 62'(term0);
    logic [61:0] addend1;
    assign addend1 = (62'(term1) << 26);

    assign sum_comb = addend0 + addend1;

    logic [61:0] stage [0:0];
    always_ff @(posedge clk) begin
        stage[0] <= sum_comb;
    end
    assign P = $unsigned(stage[0]);

endmodule

