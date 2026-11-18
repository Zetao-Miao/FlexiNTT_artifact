`timescale 1ns / 1ps

module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p1_core_s3_bu_dp_w3mq_terminal_bitheap_56_ac7e01b123 (
    input  logic clk,
    input  logic [36:0] term0,
    input  logic signed [139:0] term1,
    output logic [55:0] P
);

    // heap_width=56, comp_out=58 bits
    logic [57:0] comp_out;

    logic in_col0;
    assign in_col0 = term0[0];
    logic in_col1;
    assign in_col1 = term0[1];
    logic in_col2;
    assign in_col2 = term0[2];
    logic in_col3;
    assign in_col3 = term0[3];
    logic in_col4;
    assign in_col4 = term0[4];
    logic in_col5;
    assign in_col5 = term0[5];
    logic in_col6;
    assign in_col6 = term0[6];
    logic in_col7;
    assign in_col7 = term0[7];
    logic in_col8;
    assign in_col8 = term0[8];
    logic in_col9;
    assign in_col9 = term0[9];
    logic in_col10;
    assign in_col10 = term0[10];
    logic in_col11;
    assign in_col11 = term0[11];
    logic in_col12;
    assign in_col12 = term0[12];
    logic in_col13;
    assign in_col13 = term0[13];
    logic in_col14;
    assign in_col14 = term0[14];
    logic in_col15;
    assign in_col15 = term0[15];
    logic in_col16;
    assign in_col16 = term0[16];
    logic in_col17;
    assign in_col17 = term0[17];
    logic in_col18;
    assign in_col18 = term0[18];
    logic in_col19;
    assign in_col19 = term0[19];
    logic in_col20;
    assign in_col20 = term0[20];
    logic in_col21;
    assign in_col21 = term0[21];
    logic in_col22;
    assign in_col22 = term0[22];
    logic in_col23;
    assign in_col23 = term0[23];
    logic in_col24;
    assign in_col24 = term0[24];
    logic in_col25;
    assign in_col25 = term0[25];
    logic [2:0] in_col26;
    assign in_col26 = {term1[1], term1[0], term0[26]};
    logic [1:0] in_col27;
    assign in_col27 = {term1[2], term0[27]};
    logic [3:0] in_col28;
    assign in_col28 = {term1[5], term1[4], term1[3], term0[28]};
    logic [2:0] in_col29;
    assign in_col29 = {term1[7], term1[6], term0[29]};
    logic [4:0] in_col30;
    assign in_col30 = {term1[11], term1[10], term1[9], term1[8], term0[30]};
    logic [3:0] in_col31;
    assign in_col31 = {term1[14], term1[13], term1[12], term0[31]};
    logic [5:0] in_col32;
    assign in_col32 = {term1[19], term1[18], term1[17], term1[16], term1[15], term0[32]};
    logic [4:0] in_col33;
    assign in_col33 = {term1[23], term1[22], term1[21], term1[20], term0[33]};
    logic [6:0] in_col34;
    assign in_col34 = {term1[29], term1[28], term1[27], term1[26], term1[25], term1[24], term0[34]};
    logic [5:0] in_col35;
    assign in_col35 = {term1[34], term1[33], term1[32], term1[31], term1[30], term0[35]};
    logic [7:0] in_col36;
    assign in_col36 = {term1[41], term1[40], term1[39], term1[38], term1[37], term1[36], term1[35], term0[36]};
    logic [5:0] in_col37;
    assign in_col37 = {term1[47], term1[46], term1[45], term1[44], term1[43], term1[42]};
    logic [8:0] in_col38;
    assign in_col38 = {1'b0, term1[55], term1[54], term1[53], term1[52], term1[51], term1[50], term1[49], term1[48]};
    logic [6:0] in_col39;
    assign in_col39 = {1'b0, term1[61], term1[60], term1[59], term1[58], term1[57], term1[56]};
    logic [7:0] in_col40;
    assign in_col40 = {term1[69], term1[68], term1[67], term1[66], term1[65], term1[64], term1[63], term1[62]};
    logic [6:0] in_col41;
    assign in_col41 = {1'b0, term1[75], term1[74], term1[73], term1[72], term1[71], term1[70]};
    logic [7:0] in_col42;
    assign in_col42 = {term1[83], term1[82], term1[81], term1[80], term1[79], term1[78], term1[77], term1[76]};
    logic [6:0] in_col43;
    assign in_col43 = {1'b0, term1[89], term1[88], term1[87], term1[86], term1[85], term1[84]};
    logic [7:0] in_col44;
    assign in_col44 = {term1[97], term1[96], term1[95], term1[94], term1[93], term1[92], term1[91], term1[90]};
    logic [6:0] in_col45;
    assign in_col45 = {1'b0, term1[103], term1[102], term1[101], term1[100], term1[99], term1[98]};
    logic [5:0] in_col46;
    assign in_col46 = {term1[109], term1[108], term1[107], term1[106], term1[105], term1[104]};
    logic [5:0] in_col47;
    assign in_col47 = {1'b0, term1[114], term1[113], term1[112], term1[111], term1[110]};
    logic [4:0] in_col48;
    assign in_col48 = {term1[119], term1[118], term1[117], term1[116], term1[115]};
    logic [4:0] in_col49;
    assign in_col49 = {1'b0, term1[123], term1[122], term1[121], term1[120]};
    logic [3:0] in_col50;
    assign in_col50 = {term1[127], term1[126], term1[125], term1[124]};
    logic [3:0] in_col51;
    assign in_col51 = {1'b0, term1[130], term1[129], term1[128]};
    logic [2:0] in_col52;
    assign in_col52 = {term1[133], term1[132], term1[131]};
    logic [2:0] in_col53;
    assign in_col53 = {1'b0, term1[135], term1[134]};
    logic [1:0] in_col54;
    assign in_col54 = {term1[137], term1[136]};
    logic [1:0] in_col55;
    assign in_col55 = {1'b0, term1[138]};

    (* keep_hierarchy = "yes" *) ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p1_core_s3_bu_dp_w3mq_bitheap_cmp_56_ac7e01b123 u_cmp (
        .clk      (clk),
        .in_col0 (in_col0),
        .in_col1 (in_col1),
        .in_col2 (in_col2),
        .in_col3 (in_col3),
        .in_col4 (in_col4),
        .in_col5 (in_col5),
        .in_col6 (in_col6),
        .in_col7 (in_col7),
        .in_col8 (in_col8),
        .in_col9 (in_col9),
        .in_col10 (in_col10),
        .in_col11 (in_col11),
        .in_col12 (in_col12),
        .in_col13 (in_col13),
        .in_col14 (in_col14),
        .in_col15 (in_col15),
        .in_col16 (in_col16),
        .in_col17 (in_col17),
        .in_col18 (in_col18),
        .in_col19 (in_col19),
        .in_col20 (in_col20),
        .in_col21 (in_col21),
        .in_col22 (in_col22),
        .in_col23 (in_col23),
        .in_col24 (in_col24),
        .in_col25 (in_col25),
        .in_col26 (in_col26),
        .in_col27 (in_col27),
        .in_col28 (in_col28),
        .in_col29 (in_col29),
        .in_col30 (in_col30),
        .in_col31 (in_col31),
        .in_col32 (in_col32),
        .in_col33 (in_col33),
        .in_col34 (in_col34),
        .in_col35 (in_col35),
        .in_col36 (in_col36),
        .in_col37 (in_col37),
        .in_col38 (in_col38),
        .in_col39 (in_col39),
        .in_col40 (in_col40),
        .in_col41 (in_col41),
        .in_col42 (in_col42),
        .in_col43 (in_col43),
        .in_col44 (in_col44),
        .in_col45 (in_col45),
        .in_col46 (in_col46),
        .in_col47 (in_col47),
        .in_col48 (in_col48),
        .in_col49 (in_col49),
        .in_col50 (in_col50),
        .in_col51 (in_col51),
        .in_col52 (in_col52),
        .in_col53 (in_col53),
        .in_col54 (in_col54),
        .in_col55 (in_col55),
        .comp_out (comp_out)
    );

    assign P = $unsigned(comp_out[55:0]);

endmodule

