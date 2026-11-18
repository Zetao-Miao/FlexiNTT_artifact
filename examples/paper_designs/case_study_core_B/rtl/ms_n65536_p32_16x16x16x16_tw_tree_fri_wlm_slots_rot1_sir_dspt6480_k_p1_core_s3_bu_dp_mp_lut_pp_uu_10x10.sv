`timescale 1ns / 1ps

module ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p1_core_s3_bu_dp_mp_lut_pp_uu_10x10 (
    input  logic clk,
    input  logic [9:0] A,
    input  logic [9:0] B,
    output logic signed [77:0] P
);

    logic signed [10:0] inner_a;
    logic signed [10:0] inner_b;
    assign inner_a = $signed({1'b0, A});
    assign inner_b = $signed({1'b0, B});

    (* keep_hierarchy = "yes" *) ms_n65536_p32_16x16x16x16_tw_tree_fri_wlm_slots_rot1_sir_dspt6480_k_p1_core_s3_bu_dp_mp_Bmult11x11_pp_bitheap_gen u_inner (
        .clk (clk),
        .OPA (inner_a),
        .OPB ({inner_b[10], inner_b}),
        .col0 (P[1:0]),
        .col1 (P[2:2]),
        .col2 (P[5:3]),
        .col3 (P[7:6]),
        .col4 (P[11:8]),
        .col5 (P[14:12]),
        .col6 (P[19:15]),
        .col7 (P[23:20]),
        .col8 (P[29:24]),
        .col9 (P[34:30]),
        .col10 (P[41:35]),
        .col11 (P[47:42]),
        .col12 (P[52:48]),
        .col13 (P[57:53]),
        .col14 (P[61:58]),
        .col15 (P[65:62]),
        .col16 (P[68:66]),
        .col17 (P[71:69]),
        .col18 (P[73:72]),
        .col19 (P[75:74]),
        .col20 (P[76:76]),
        .col21 (P[77:77])
    );

endmodule

