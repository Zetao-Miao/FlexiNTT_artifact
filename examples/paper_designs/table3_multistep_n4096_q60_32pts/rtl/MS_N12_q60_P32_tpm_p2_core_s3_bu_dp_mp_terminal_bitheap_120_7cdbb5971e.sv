`timescale 1ns / 1ps

module MS_N12_q60_P32_tpm_p2_core_s3_bu_dp_mp_terminal_bitheap_120_7cdbb5971e (
    input  logic clk,
    input  logic [71:0] term0,
    input  logic [71:0] term1,
    input  logic [39:0] term2,
    input  logic [39:0] term3,
    input  logic [33:0] term4,
    input  logic [33:0] term5,
    input  logic [15:0] term6,
    output logic [119:0] P
);

    // heap_width=120, comp_out=121 bits
    logic [120:0] comp_out;

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
    logic [1:0] in_col26;
    assign in_col26 = {term1[0], term0[26]};
    logic [1:0] in_col27;
    assign in_col27 = {term1[1], term0[27]};
    logic [1:0] in_col28;
    assign in_col28 = {term1[2], term0[28]};
    logic [1:0] in_col29;
    assign in_col29 = {term1[3], term0[29]};
    logic [1:0] in_col30;
    assign in_col30 = {term1[4], term0[30]};
    logic [1:0] in_col31;
    assign in_col31 = {term1[5], term0[31]};
    logic [1:0] in_col32;
    assign in_col32 = {term1[6], term0[32]};
    logic [1:0] in_col33;
    assign in_col33 = {term1[7], term0[33]};
    logic [1:0] in_col34;
    assign in_col34 = {term1[8], term0[34]};
    logic [1:0] in_col35;
    assign in_col35 = {term1[9], term0[35]};
    logic [1:0] in_col36;
    assign in_col36 = {term1[10], term0[36]};
    logic [1:0] in_col37;
    assign in_col37 = {term1[11], term0[37]};
    logic [1:0] in_col38;
    assign in_col38 = {term1[12], term0[38]};
    logic [1:0] in_col39;
    assign in_col39 = {term1[13], term0[39]};
    logic [1:0] in_col40;
    assign in_col40 = {term1[14], term0[40]};
    logic [1:0] in_col41;
    assign in_col41 = {term1[15], term0[41]};
    logic [1:0] in_col42;
    assign in_col42 = {term1[16], term0[42]};
    logic [1:0] in_col43;
    assign in_col43 = {term1[17], term0[43]};
    logic [1:0] in_col44;
    assign in_col44 = {term1[18], term0[44]};
    logic [1:0] in_col45;
    assign in_col45 = {term1[19], term0[45]};
    logic [2:0] in_col46;
    assign in_col46 = {term2[0], term1[20], term0[46]};
    logic [2:0] in_col47;
    assign in_col47 = {term2[1], term1[21], term0[47]};
    logic [2:0] in_col48;
    assign in_col48 = {term2[2], term1[22], term0[48]};
    logic [2:0] in_col49;
    assign in_col49 = {term2[3], term1[23], term0[49]};
    logic [2:0] in_col50;
    assign in_col50 = {term2[4], term1[24], term0[50]};
    logic [2:0] in_col51;
    assign in_col51 = {term2[5], term1[25], term0[51]};
    logic [3:0] in_col52;
    assign in_col52 = {term4[0], term2[6], term1[26], term0[52]};
    logic [3:0] in_col53;
    assign in_col53 = {term4[1], term2[7], term1[27], term0[53]};
    logic [3:0] in_col54;
    assign in_col54 = {term4[2], term2[8], term1[28], term0[54]};
    logic [3:0] in_col55;
    assign in_col55 = {term4[3], term2[9], term1[29], term0[55]};
    logic [3:0] in_col56;
    assign in_col56 = {term4[4], term2[10], term1[30], term0[56]};
    logic [3:0] in_col57;
    assign in_col57 = {term4[5], term2[11], term1[31], term0[57]};
    logic [3:0] in_col58;
    assign in_col58 = {term4[6], term2[12], term1[32], term0[58]};
    logic [3:0] in_col59;
    assign in_col59 = {term4[7], term2[13], term1[33], term0[59]};
    logic [3:0] in_col60;
    assign in_col60 = {term4[8], term2[14], term1[34], term0[60]};
    logic [3:0] in_col61;
    assign in_col61 = {term4[9], term2[15], term1[35], term0[61]};
    logic [3:0] in_col62;
    assign in_col62 = {term4[10], term2[16], term1[36], term0[62]};
    logic [3:0] in_col63;
    assign in_col63 = {term4[11], term2[17], term1[37], term0[63]};
    logic [3:0] in_col64;
    assign in_col64 = {term4[12], term2[18], term1[38], term0[64]};
    logic [3:0] in_col65;
    assign in_col65 = {term4[13], term2[19], term1[39], term0[65]};
    logic [3:0] in_col66;
    assign in_col66 = {term4[14], term2[20], term1[40], term0[66]};
    logic [3:0] in_col67;
    assign in_col67 = {term4[15], term2[21], term1[41], term0[67]};
    logic [3:0] in_col68;
    assign in_col68 = {term4[16], term2[22], term1[42], term0[68]};
    logic [3:0] in_col69;
    assign in_col69 = {term4[17], term2[23], term1[43], term0[69]};
    logic [3:0] in_col70;
    assign in_col70 = {term4[18], term2[24], term1[44], term0[70]};
    logic [3:0] in_col71;
    assign in_col71 = {term4[19], term2[25], term1[45], term0[71]};
    logic [3:0] in_col72;
    assign in_col72 = {term4[20], term3[0], term2[26], term1[46]};
    logic [3:0] in_col73;
    assign in_col73 = {term4[21], term3[1], term2[27], term1[47]};
    logic [3:0] in_col74;
    assign in_col74 = {term4[22], term3[2], term2[28], term1[48]};
    logic [3:0] in_col75;
    assign in_col75 = {term4[23], term3[3], term2[29], term1[49]};
    logic [3:0] in_col76;
    assign in_col76 = {term4[24], term3[4], term2[30], term1[50]};
    logic [3:0] in_col77;
    assign in_col77 = {term4[25], term3[5], term2[31], term1[51]};
    logic [4:0] in_col78;
    assign in_col78 = {term5[0], term4[26], term3[6], term2[32], term1[52]};
    logic [4:0] in_col79;
    assign in_col79 = {term5[1], term4[27], term3[7], term2[33], term1[53]};
    logic [4:0] in_col80;
    assign in_col80 = {term5[2], term4[28], term3[8], term2[34], term1[54]};
    logic [4:0] in_col81;
    assign in_col81 = {term5[3], term4[29], term3[9], term2[35], term1[55]};
    logic [4:0] in_col82;
    assign in_col82 = {term5[4], term4[30], term3[10], term2[36], term1[56]};
    logic [4:0] in_col83;
    assign in_col83 = {term5[5], term4[31], term3[11], term2[37], term1[57]};
    logic [4:0] in_col84;
    assign in_col84 = {term5[6], term4[32], term3[12], term2[38], term1[58]};
    logic [4:0] in_col85;
    assign in_col85 = {term5[7], term4[33], term3[13], term2[39], term1[59]};
    logic [2:0] in_col86;
    assign in_col86 = {term5[8], term3[14], term1[60]};
    logic [2:0] in_col87;
    assign in_col87 = {term5[9], term3[15], term1[61]};
    logic [2:0] in_col88;
    assign in_col88 = {term5[10], term3[16], term1[62]};
    logic [2:0] in_col89;
    assign in_col89 = {term5[11], term3[17], term1[63]};
    logic [2:0] in_col90;
    assign in_col90 = {term5[12], term3[18], term1[64]};
    logic [2:0] in_col91;
    assign in_col91 = {term5[13], term3[19], term1[65]};
    logic [2:0] in_col92;
    assign in_col92 = {term5[14], term3[20], term1[66]};
    logic [2:0] in_col93;
    assign in_col93 = {term5[15], term3[21], term1[67]};
    logic [2:0] in_col94;
    assign in_col94 = {term5[16], term3[22], term1[68]};
    logic [2:0] in_col95;
    assign in_col95 = {term5[17], term3[23], term1[69]};
    logic [2:0] in_col96;
    assign in_col96 = {term5[18], term3[24], term1[70]};
    logic [2:0] in_col97;
    assign in_col97 = {term5[19], term3[25], term1[71]};
    logic [1:0] in_col98;
    assign in_col98 = {term5[20], term3[26]};
    logic [1:0] in_col99;
    assign in_col99 = {term5[21], term3[27]};
    logic [1:0] in_col100;
    assign in_col100 = {term5[22], term3[28]};
    logic [1:0] in_col101;
    assign in_col101 = {term5[23], term3[29]};
    logic [1:0] in_col102;
    assign in_col102 = {term5[24], term3[30]};
    logic [1:0] in_col103;
    assign in_col103 = {term5[25], term3[31]};
    logic [2:0] in_col104;
    assign in_col104 = {term6[0], term5[26], term3[32]};
    logic [2:0] in_col105;
    assign in_col105 = {term6[1], term5[27], term3[33]};
    logic [2:0] in_col106;
    assign in_col106 = {term6[2], term5[28], term3[34]};
    logic [2:0] in_col107;
    assign in_col107 = {term6[3], term5[29], term3[35]};
    logic [2:0] in_col108;
    assign in_col108 = {term6[4], term5[30], term3[36]};
    logic [2:0] in_col109;
    assign in_col109 = {term6[5], term5[31], term3[37]};
    logic [2:0] in_col110;
    assign in_col110 = {term6[6], term5[32], term3[38]};
    logic [2:0] in_col111;
    assign in_col111 = {term6[7], term5[33], term3[39]};
    logic in_col112;
    assign in_col112 = term6[8];
    logic in_col113;
    assign in_col113 = term6[9];
    logic in_col114;
    assign in_col114 = term6[10];
    logic in_col115;
    assign in_col115 = term6[11];
    logic in_col116;
    assign in_col116 = term6[12];
    logic in_col117;
    assign in_col117 = term6[13];
    logic in_col118;
    assign in_col118 = term6[14];
    logic in_col119;
    assign in_col119 = term6[15];

    (* keep_hierarchy = "yes" *) MS_N12_q60_P32_tpm_p2_core_s3_bu_dp_mp_bitheap_cmp_120_7cdbb5971e u_cmp (
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
        .in_col56 (in_col56),
        .in_col57 (in_col57),
        .in_col58 (in_col58),
        .in_col59 (in_col59),
        .in_col60 (in_col60),
        .in_col61 (in_col61),
        .in_col62 (in_col62),
        .in_col63 (in_col63),
        .in_col64 (in_col64),
        .in_col65 (in_col65),
        .in_col66 (in_col66),
        .in_col67 (in_col67),
        .in_col68 (in_col68),
        .in_col69 (in_col69),
        .in_col70 (in_col70),
        .in_col71 (in_col71),
        .in_col72 (in_col72),
        .in_col73 (in_col73),
        .in_col74 (in_col74),
        .in_col75 (in_col75),
        .in_col76 (in_col76),
        .in_col77 (in_col77),
        .in_col78 (in_col78),
        .in_col79 (in_col79),
        .in_col80 (in_col80),
        .in_col81 (in_col81),
        .in_col82 (in_col82),
        .in_col83 (in_col83),
        .in_col84 (in_col84),
        .in_col85 (in_col85),
        .in_col86 (in_col86),
        .in_col87 (in_col87),
        .in_col88 (in_col88),
        .in_col89 (in_col89),
        .in_col90 (in_col90),
        .in_col91 (in_col91),
        .in_col92 (in_col92),
        .in_col93 (in_col93),
        .in_col94 (in_col94),
        .in_col95 (in_col95),
        .in_col96 (in_col96),
        .in_col97 (in_col97),
        .in_col98 (in_col98),
        .in_col99 (in_col99),
        .in_col100 (in_col100),
        .in_col101 (in_col101),
        .in_col102 (in_col102),
        .in_col103 (in_col103),
        .in_col104 (in_col104),
        .in_col105 (in_col105),
        .in_col106 (in_col106),
        .in_col107 (in_col107),
        .in_col108 (in_col108),
        .in_col109 (in_col109),
        .in_col110 (in_col110),
        .in_col111 (in_col111),
        .in_col112 (in_col112),
        .in_col113 (in_col113),
        .in_col114 (in_col114),
        .in_col115 (in_col115),
        .in_col116 (in_col116),
        .in_col117 (in_col117),
        .in_col118 (in_col118),
        .in_col119 (in_col119),
        .comp_out (comp_out)
    );

    assign P = $unsigned(comp_out[119:0]);

endmodule

