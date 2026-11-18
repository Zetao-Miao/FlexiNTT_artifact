`timescale 1ns / 1ps

module ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p3_core_s2_bu_dp_mp_delay_line #(
    parameter int WIDTH  = 1,
    parameter int CYCLES = 1
) (
    input  logic             clk,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);
    generate
        if (CYCLES == 0) begin : g_passthrough
            assign q = d;
        end else begin : g_chain
            logic [WIDTH-1:0] r [0:CYCLES-1];
            always_ff @(posedge clk) begin
                r[0] <= d;
                for (int i = 1; i < CYCLES; i++) r[i] <= r[i-1];
            end
            assign q = r[CYCLES-1];
        end
    endgenerate
endmodule

