`timescale 1ns / 1ps

module ev_ld_io4_k_bu_dp_mp_terminal_bitheap_60_8f2ace4be0 (
    input  logic clk,
    input  logic [48:0] term0,
    input  logic [32:0] term1,
    input  logic [29:0] term2,
    input  logic [7:0] term3,
    output logic [59:0] P
);

    // heap_width=60, comp_out=61 bits
    logic [60:0] comp_out;

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
    logic [1:0] in_col23;
    assign in_col23 = {term1[0], term0[23]};
    logic [1:0] in_col24;
    assign in_col24 = {term1[1], term0[24]};
    logic [1:0] in_col25;
    assign in_col25 = {term1[2], term0[25]};
    logic [2:0] in_col26;
    assign in_col26 = {term2[0], term1[3], term0[26]};
    logic [2:0] in_col27;
    assign in_col27 = {term2[1], term1[4], term0[27]};
    logic [2:0] in_col28;
    assign in_col28 = {term2[2], term1[5], term0[28]};
    logic [2:0] in_col29;
    assign in_col29 = {term2[3], term1[6], term0[29]};
    logic [2:0] in_col30;
    assign in_col30 = {term2[4], term1[7], term0[30]};
    logic [2:0] in_col31;
    assign in_col31 = {term2[5], term1[8], term0[31]};
    logic [2:0] in_col32;
    assign in_col32 = {term2[6], term1[9], term0[32]};
    logic [2:0] in_col33;
    assign in_col33 = {term2[7], term1[10], term0[33]};
    logic [2:0] in_col34;
    assign in_col34 = {term2[8], term1[11], term0[34]};
    logic [2:0] in_col35;
    assign in_col35 = {term2[9], term1[12], term0[35]};
    logic [2:0] in_col36;
    assign in_col36 = {term2[10], term1[13], term0[36]};
    logic [2:0] in_col37;
    assign in_col37 = {term2[11], term1[14], term0[37]};
    logic [2:0] in_col38;
    assign in_col38 = {term2[12], term1[15], term0[38]};
    logic [2:0] in_col39;
    assign in_col39 = {term2[13], term1[16], term0[39]};
    logic [2:0] in_col40;
    assign in_col40 = {term2[14], term1[17], term0[40]};
    logic [2:0] in_col41;
    assign in_col41 = {term2[15], term1[18], term0[41]};
    logic [2:0] in_col42;
    assign in_col42 = {term2[16], term1[19], term0[42]};
    logic [2:0] in_col43;
    assign in_col43 = {term2[17], term1[20], term0[43]};
    logic [2:0] in_col44;
    assign in_col44 = {term2[18], term1[21], term0[44]};
    logic [2:0] in_col45;
    assign in_col45 = {term2[19], term1[22], term0[45]};
    logic [2:0] in_col46;
    assign in_col46 = {term2[20], term1[23], term0[46]};
    logic [2:0] in_col47;
    assign in_col47 = {term2[21], term1[24], term0[47]};
    logic [2:0] in_col48;
    assign in_col48 = {term2[22], term1[25], term0[48]};
    logic [1:0] in_col49;
    assign in_col49 = {term2[23], term1[26]};
    logic [1:0] in_col50;
    assign in_col50 = {term2[24], term1[27]};
    logic [1:0] in_col51;
    assign in_col51 = {term2[25], term1[28]};
    logic [2:0] in_col52;
    assign in_col52 = {term3[0], term2[26], term1[29]};
    logic [2:0] in_col53;
    assign in_col53 = {term3[1], term2[27], term1[30]};
    logic [2:0] in_col54;
    assign in_col54 = {term3[2], term2[28], term1[31]};
    logic [2:0] in_col55;
    assign in_col55 = {term3[3], term2[29], term1[32]};
    logic in_col56;
    assign in_col56 = term3[4];
    logic in_col57;
    assign in_col57 = term3[5];
    logic in_col58;
    assign in_col58 = term3[6];
    logic in_col59;
    assign in_col59 = term3[7];

    (* keep_hierarchy = "yes" *) ev_ld_io4_k_bu_dp_mp_bitheap_cmp_60_8f2ace4be0 u_cmp (
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
        .comp_out (comp_out)
    );

    assign P = $unsigned(comp_out[59:0]);

endmodule

