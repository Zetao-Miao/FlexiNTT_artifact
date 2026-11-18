`timescale 1ns / 1ps

module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p2_core_s1_bu_dp_w3mq_lut_pp_uu_11x19 (
    input  logic clk,
    input  logic [10:0] A,
    input  logic [18:0] B,
    output logic signed [139:0] P
);

    logic signed [11:0] inner_a;
    logic signed [19:0] inner_b;
    assign inner_a = $signed({1'b0, A});
    assign inner_b = $signed({1'b0, B});

    (* keep_hierarchy = "yes" *) ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p2_core_s1_bu_dp_w3mq_Bmult12x20_pp_bitheap_gen u_inner (
        .clk (clk),
        .OPA (inner_a),
        .OPB (inner_b),
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
        .col12 (P[55:48]),
        .col13 (P[61:56]),
        .col14 (P[69:62]),
        .col15 (P[75:70]),
        .col16 (P[83:76]),
        .col17 (P[89:84]),
        .col18 (P[97:90]),
        .col19 (P[103:98]),
        .col20 (P[109:104]),
        .col21 (P[114:110]),
        .col22 (P[119:115]),
        .col23 (P[123:120]),
        .col24 (P[127:124]),
        .col25 (P[130:128]),
        .col26 (P[133:131]),
        .col27 (P[135:134]),
        .col28 (P[137:136]),
        .col29 (P[138:138]),
        .col30 (P[139:139])
    );

endmodule

