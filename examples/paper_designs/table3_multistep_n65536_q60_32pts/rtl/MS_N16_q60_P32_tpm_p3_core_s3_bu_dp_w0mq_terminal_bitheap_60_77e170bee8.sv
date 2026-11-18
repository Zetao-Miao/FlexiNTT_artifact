`timescale 1ns / 1ps

module MS_N16_q60_P32_tpm_p3_core_s3_bu_dp_w0mq_terminal_bitheap_60_77e170bee8 (
    input  logic clk,
    input  logic [42:0] term0,
    input  logic [33:0] term1,
    output logic [59:0] P
);

    // tallest column has only 2 bit(s), no GPC compressor tree needed; sign_mode=extend
    logic [59:0] sum_comb;

    logic [59:0] addend0;
    assign addend0 = 60'(term0);
    logic [59:0] addend1;
    assign addend1 = (60'(term1) << 26);

    assign sum_comb = addend0 + addend1;

    logic [59:0] stage [0:0];
    always_ff @(posedge clk) begin
        stage[0] <= sum_comb;
    end
    assign P = $unsigned(stage[0]);

endmodule

