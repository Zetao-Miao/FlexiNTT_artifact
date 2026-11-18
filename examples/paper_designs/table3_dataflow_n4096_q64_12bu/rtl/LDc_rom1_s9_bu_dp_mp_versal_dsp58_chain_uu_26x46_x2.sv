`timescale 1ns / 1ps

module LDc_rom1_s9_bu_dp_mp_versal_dsp58_chain_uu_26x46_x2 (
    input  logic clk,
    input  logic reset,
    input  logic [25:0] A,
    input  logic [45:0] B,
    output logic [71:0] P
);

    logic signed [26:0] inner_a;
    logic signed [46:0] inner_b;
    logic signed [73:0] inner_p;

    assign inner_a = $signed({1'b0, A});
    assign inner_b = $signed({1'b0, B});

    // seed library declares inner latency = 2 cycle(s)
    (* keep_hierarchy = "yes" *) LDc_rom1_s9_bu_dp_mp_DSPChain_L2_lat2 u_inner (
        .clk (clk),
        .reset (reset),
        .in_valid (1'b1),
        .X   (inner_a),
        .Y   (inner_b),
        .P   (inner_p)
    );

    assign P = $unsigned(inner_p[71:0]);

endmodule

