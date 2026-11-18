`timescale 1ns / 1ps

module Id_n65536_q52w_B32_rns_bu_dp_w0mq_terminal_bitheap_52_5cfdc20381 (
    input  logic clk,
    input  logic [48:0] term0,
    input  logic [28:0] term1,
    output logic [51:0] P
);

    // tallest column has only 2 bit(s), no GPC compressor tree needed; sign_mode=extend
    logic [51:0] sum_comb;

    logic [51:0] addend0;
    assign addend0 = 52'(term0);
    logic [51:0] addend1;
    assign addend1 = (52'(term1) << 23);

    assign sum_comb = addend0 + addend1;

    logic [51:0] stage [0:0];
    always_ff @(posedge clk) begin
        stage[0] <= sum_comb;
    end
    assign P = $unsigned(stage[0]);

endmodule

