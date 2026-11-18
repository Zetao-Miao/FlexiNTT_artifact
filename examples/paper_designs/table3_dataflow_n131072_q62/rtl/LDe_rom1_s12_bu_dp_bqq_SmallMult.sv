`timescale 1ns / 1ps

(* use_dsp = "no" *)
module LDe_rom1_s12_bu_dp_bqq_SmallMult #(
    parameter  int WA       = 4,
    parameter  int WB       = 4,
    parameter  bit A_SIGNED = 1,
    parameter  bit B_SIGNED = 1,
    parameter  int LATENCY  = 1,
    localparam int PW = WA + WB
) (
    input  logic clk,
    input  logic [WA-1:0] A,
    input  logic [WB-1:0] B,
    output logic [PW-1:0] P
);
    logic [PW-1:0] prod;

    // The four sign combinations are hardcoded separately: SV's
    // signedness is decided by context -- as soon as one unsigned
    // operand is in an expression, the whole multiplication is
    // evaluated as unsigned, and the signed side gets treated as
    // a big positive number. So a ternary shortcut here isn't safe.
    generate
        if (A_SIGNED && B_SIGNED) begin : g_ss
            assign prod = PW'($signed(A)) * PW'($signed(B));
        end else if (A_SIGNED) begin : g_su
            assign prod = PW'($signed(A)) * PW'($signed({1'b0, B}));
        end else if (B_SIGNED) begin : g_us
            assign prod = PW'($signed({1'b0, A})) * PW'($signed(B));
        end else begin : g_uu
            assign prod = PW'(A) * PW'(B);
        end
    endgenerate

    generate
        if (LATENCY == 0) begin : g_comb
            assign P = prod;
        end else begin : g_pipe
            logic [PW-1:0] stage [0:LATENCY-1];
            always_ff @(posedge clk) begin
                stage[0] <= prod;
                for (int i = 1; i < LATENCY; i++)
                    stage[i] <= stage[i-1];
            end
            assign P = stage[LATENCY-1];
        end
    endgenerate
endmodule

