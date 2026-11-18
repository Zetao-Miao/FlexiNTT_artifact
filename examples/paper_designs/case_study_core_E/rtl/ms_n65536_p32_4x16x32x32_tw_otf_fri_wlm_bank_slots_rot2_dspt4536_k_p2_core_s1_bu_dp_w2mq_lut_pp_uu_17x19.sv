`timescale 1ns / 1ps

module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p2_core_s1_bu_dp_w2mq_lut_pp_uu_17x19 (
    input  logic clk,
    input  logic [16:0] A,
    input  logic [18:0] B,
    output logic signed [199:0] P
);

    logic signed [17:0] inner_a;
    logic signed [19:0] inner_b;
    assign inner_a = $signed({1'b0, A});
    assign inner_b = $signed({1'b0, B});

    (* keep_hierarchy = "yes" *) ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p2_core_s1_bu_dp_w2mq_Bmult18x20_pp_bitheap_gen u_inner (
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
        .col13 (P[62:56]),
        .col14 (P[71:63]),
        .col15 (P[79:72]),
        .col16 (P[89:80]),
        .col17 (P[98:90]),
        .col18 (P[109:99]),
        .col19 (P[118:110]),
        .col20 (P[127:119]),
        .col21 (P[135:128]),
        .col22 (P[143:136]),
        .col23 (P[150:144]),
        .col24 (P[157:151]),
        .col25 (P[163:158]),
        .col26 (P[169:164]),
        .col27 (P[174:170]),
        .col28 (P[179:175]),
        .col29 (P[183:180]),
        .col30 (P[187:184]),
        .col31 (P[190:188]),
        .col32 (P[193:191]),
        .col33 (P[195:194]),
        .col34 (P[197:196]),
        .col35 (P[198:198]),
        .col36 (P[199:199])
    );

endmodule

