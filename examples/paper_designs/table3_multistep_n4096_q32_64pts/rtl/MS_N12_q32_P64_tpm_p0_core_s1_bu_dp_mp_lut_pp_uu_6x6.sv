`timescale 1ns / 1ps

module MS_N12_q32_P64_tpm_p0_core_s1_bu_dp_mp_lut_pp_uu_6x6 (
    input  logic clk,
    input  logic [5:0] A,
    input  logic [5:0] B,
    output logic signed [35:0] P
);

    logic signed [6:0] inner_a;
    logic signed [6:0] inner_b;
    assign inner_a = $signed({1'b0, A});
    assign inner_b = $signed({1'b0, B});

    (* keep_hierarchy = "yes" *) MS_N12_q32_P64_tpm_p0_core_s1_bu_dp_mp_Bmult7x7_pp_bitheap_gen u_inner (
        .clk (clk),
        .OPA (inner_a),
        .OPB ({inner_b[6], inner_b}),
        .col0 (P[1:0]),
        .col1 (P[2:2]),
        .col2 (P[5:3]),
        .col3 (P[7:6]),
        .col4 (P[11:8]),
        .col5 (P[14:12]),
        .col6 (P[19:15]),
        .col7 (P[23:20]),
        .col8 (P[26:24]),
        .col9 (P[29:27]),
        .col10 (P[31:30]),
        .col11 (P[33:32]),
        .col12 (P[34:34]),
        .col13 (P[35:35])
    );

endmodule

