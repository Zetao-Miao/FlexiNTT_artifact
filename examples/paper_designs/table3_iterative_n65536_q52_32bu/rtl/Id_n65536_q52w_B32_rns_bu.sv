`timescale 1ns / 1ps

// Id_n65536_q52w_B32_rns_bu: CT butterfly mod q = 0, the datapath Id_n65536_q52w_B32_rns_bu_dp (modular multiplier + modular adder/subtractor); latency 17
module Id_n65536_q52w_B32_rns_bu (
    input  logic clk,
    input  logic [51:0] aIn,
    input  logic [51:0] bIn,
    input  logic [51:0] W,
    input  logic [25:0] QH,
    output logic [51:0] aOut,
    output logic [51:0] bOut
    );
    Id_n65536_q52w_B32_rns_bu_dp Id_n65536_q52w_B32_rns_bu_dp_inst (.clk(clk), .A(aIn), .B(bIn), .W(W), .QH(QH), .X(aOut), .Y(bOut));
endmodule
