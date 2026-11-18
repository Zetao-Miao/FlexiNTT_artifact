`timescale 1ns / 1ps
module LDc_rom1_dly #(parameter int W = 8, parameter int D = 1) (
    input  logic clk,
    input  logic [W-1:0] din,
    output logic [W-1:0] dout
    );
    generate
    if (D < 64) begin : g_sr
        logic [W-1:0] sr [D];
        always_ff @(posedge clk) begin
            sr[0] <= din;
            for (int i = 1; i < D; i++) sr[i] <= sr[i-1];
        end
        assign dout = sr[D-1];
    end else begin : g_ram
        // 2026-11-16: D - 2 words and two read registers (the second is the block RAM's output register), so the
        // word leaves a register: a block RAM read without it took half the cycle before the multiplier it feeds
        localparam int A = $clog2(D - 2);
        (* ram_style = "block" *) logic [W-1:0] mem [D-2];
        logic [A-1:0] ptr = '0;
        logic [W-1:0] rd;
        always_ff @(posedge clk) begin
            rd <= mem[ptr];
            dout <= rd;
            mem[ptr] <= din;
            ptr <= (ptr == A'(D - 3)) ? '0 : ptr + 1'b1;
        end
    end
    endgenerate
endmodule

// LDc_rom1_dly_c: the same delay with a flip-flop at both ends (modulus constants and tags, 2026-11-16): the value
// leaves a register next to its source and arrives in a register next to its consumers (replicated beyond 8
// loads), with the shift register or RAM in between. A shift register alone sits in one place, so the hop to
// the next point of use was one long wire.
module LDc_rom1_dly_c #(parameter int W = 8, parameter int D = 1) (
    input  logic clk,
    input  logic [W-1:0] din,
    output logic [W-1:0] dout
    );
    (* shreg_extract = "no", max_fanout = 8 *) logic [W-1:0] s_out;
    generate
    if (D == 1) begin : g_one
        always_ff @(posedge clk) s_out <= din;
    end else begin : g_ends
        (* shreg_extract = "no" *) logic [W-1:0] s_in;
        logic [W-1:0] mid;
        always_ff @(posedge clk) s_in <= din;
        if (D == 2) begin : g_two
            assign mid = s_in;
        end else begin : g_mid
            LDc_rom1_dly #(.W(W), .D(D - 2)) m_i (.clk(clk), .din(s_in), .dout(mid));
        end
        always_ff @(posedge clk) s_out <= mid;
    end
    endgenerate
    assign dout = s_out;
endmodule
