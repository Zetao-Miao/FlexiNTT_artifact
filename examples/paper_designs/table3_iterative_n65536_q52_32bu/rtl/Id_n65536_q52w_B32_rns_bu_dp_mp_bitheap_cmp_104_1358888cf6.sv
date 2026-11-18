`timescale 1ns / 1ps

module Id_n65536_q52w_B32_rns_bu_dp_mp_bitheap_cmp_104_1358888cf6 (
    input  logic           clk,
    input  logic           in_col0,
    input  logic           in_col1,
    input  logic           in_col2,
    input  logic           in_col3,
    input  logic           in_col4,
    input  logic           in_col5,
    input  logic           in_col6,
    input  logic           in_col7,
    input  logic           in_col8,
    input  logic           in_col9,
    input  logic           in_col10,
    input  logic           in_col11,
    input  logic           in_col12,
    input  logic           in_col13,
    input  logic           in_col14,
    input  logic           in_col15,
    input  logic           in_col16,
    input  logic           in_col17,
    input  logic           in_col18,
    input  logic           in_col19,
    input  logic           in_col20,
    input  logic           in_col21,
    input  logic           in_col22,
    input  logic           in_col23,
    input  logic           in_col24,
    input  logic           in_col25,
    input  logic [1   : 0] in_col26,
    input  logic [1   : 0] in_col27,
    input  logic [1   : 0] in_col28,
    input  logic [1   : 0] in_col29,
    input  logic [1   : 0] in_col30,
    input  logic [1   : 0] in_col31,
    input  logic [1   : 0] in_col32,
    input  logic [1   : 0] in_col33,
    input  logic [1   : 0] in_col34,
    input  logic [1   : 0] in_col35,
    input  logic [1   : 0] in_col36,
    input  logic [1   : 0] in_col37,
    input  logic [1   : 0] in_col38,
    input  logic [1   : 0] in_col39,
    input  logic [1   : 0] in_col40,
    input  logic [1   : 0] in_col41,
    input  logic [1   : 0] in_col42,
    input  logic [1   : 0] in_col43,
    input  logic [1   : 0] in_col44,
    input  logic [1   : 0] in_col45,
    input  logic [2   : 0] in_col46,
    input  logic [2   : 0] in_col47,
    input  logic [2   : 0] in_col48,
    input  logic [2   : 0] in_col49,
    input  logic [2   : 0] in_col50,
    input  logic [2   : 0] in_col51,
    input  logic [2   : 0] in_col52,
    input  logic [2   : 0] in_col53,
    input  logic [2   : 0] in_col54,
    input  logic [2   : 0] in_col55,
    input  logic [2   : 0] in_col56,
    input  logic [2   : 0] in_col57,
    input  logic [2   : 0] in_col58,
    input  logic [2   : 0] in_col59,
    input  logic [2   : 0] in_col60,
    input  logic [2   : 0] in_col61,
    input  logic [2   : 0] in_col62,
    input  logic [2   : 0] in_col63,
    input  logic [2   : 0] in_col64,
    input  logic [2   : 0] in_col65,
    input  logic [2   : 0] in_col66,
    input  logic [2   : 0] in_col67,
    input  logic [2   : 0] in_col68,
    input  logic [2   : 0] in_col69,
    input  logic [2   : 0] in_col70,
    input  logic [2   : 0] in_col71,
    input  logic [2   : 0] in_col72,
    input  logic [2   : 0] in_col73,
    input  logic [2   : 0] in_col74,
    input  logic [2   : 0] in_col75,
    input  logic [2   : 0] in_col76,
    input  logic [2   : 0] in_col77,
    input  logic [1   : 0] in_col78,
    input  logic [1   : 0] in_col79,
    input  logic [1   : 0] in_col80,
    input  logic [1   : 0] in_col81,
    input  logic [1   : 0] in_col82,
    input  logic [1   : 0] in_col83,
    input  logic [1   : 0] in_col84,
    input  logic [1   : 0] in_col85,
    input  logic [1   : 0] in_col86,
    input  logic [1   : 0] in_col87,
    input  logic [1   : 0] in_col88,
    input  logic [1   : 0] in_col89,
    input  logic [1   : 0] in_col90,
    input  logic [1   : 0] in_col91,
    input  logic [1   : 0] in_col92,
    input  logic [1   : 0] in_col93,
    input  logic [1   : 0] in_col94,
    input  logic [1   : 0] in_col95,
    input  logic [1   : 0] in_col96,
    input  logic [1   : 0] in_col97,
    input  logic           in_col98,
    input  logic           in_col99,
    input  logic           in_col100,
    input  logic           in_col101,
    input  logic           in_col102,
    input  logic           in_col103,
    output logic [104 : 0] comp_out
    );

    
    // ------------------------------ LAYER 0 ------------------------------
    logic          layer0_col0;
    logic          layer0_col1;
    logic          layer0_col2;
    logic          layer0_col3;
    logic          layer0_col4;
    logic          layer0_col5;
    logic          layer0_col6;
    logic          layer0_col7;
    logic          layer0_col8;
    logic          layer0_col9;
    logic          layer0_col10;
    logic          layer0_col11;
    logic          layer0_col12;
    logic          layer0_col13;
    logic          layer0_col14;
    logic          layer0_col15;
    logic          layer0_col16;
    logic          layer0_col17;
    logic          layer0_col18;
    logic          layer0_col19;
    logic          layer0_col20;
    logic          layer0_col21;
    logic          layer0_col22;
    logic          layer0_col23;
    logic          layer0_col24;
    logic          layer0_col25;
    logic [1  : 0] layer0_col26;
    logic [1  : 0] layer0_col27;
    logic [1  : 0] layer0_col28;
    logic [1  : 0] layer0_col29;
    logic [1  : 0] layer0_col30;
    logic [1  : 0] layer0_col31;
    logic [1  : 0] layer0_col32;
    logic [1  : 0] layer0_col33;
    logic [1  : 0] layer0_col34;
    logic [1  : 0] layer0_col35;
    logic [1  : 0] layer0_col36;
    logic [1  : 0] layer0_col37;
    logic [1  : 0] layer0_col38;
    logic [1  : 0] layer0_col39;
    logic [1  : 0] layer0_col40;
    logic [1  : 0] layer0_col41;
    logic [1  : 0] layer0_col42;
    logic [1  : 0] layer0_col43;
    logic [1  : 0] layer0_col44;
    logic [1  : 0] layer0_col45;
    logic [2  : 0] layer0_col46;
    logic [2  : 0] layer0_col47;
    logic [2  : 0] layer0_col48;
    logic [2  : 0] layer0_col49;
    logic [2  : 0] layer0_col50;
    logic [2  : 0] layer0_col51;
    logic [2  : 0] layer0_col52;
    logic [2  : 0] layer0_col53;
    logic [2  : 0] layer0_col54;
    logic [2  : 0] layer0_col55;
    logic [2  : 0] layer0_col56;
    logic [2  : 0] layer0_col57;
    logic [2  : 0] layer0_col58;
    logic [2  : 0] layer0_col59;
    logic [2  : 0] layer0_col60;
    logic [2  : 0] layer0_col61;
    logic [2  : 0] layer0_col62;
    logic [2  : 0] layer0_col63;
    logic [2  : 0] layer0_col64;
    logic [2  : 0] layer0_col65;
    logic [2  : 0] layer0_col66;
    logic [2  : 0] layer0_col67;
    logic [2  : 0] layer0_col68;
    logic [2  : 0] layer0_col69;
    logic [2  : 0] layer0_col70;
    logic [2  : 0] layer0_col71;
    logic [2  : 0] layer0_col72;
    logic [2  : 0] layer0_col73;
    logic [2  : 0] layer0_col74;
    logic [2  : 0] layer0_col75;
    logic [2  : 0] layer0_col76;
    logic [2  : 0] layer0_col77;
    logic [1  : 0] layer0_col78;
    logic [1  : 0] layer0_col79;
    logic [1  : 0] layer0_col80;
    logic [1  : 0] layer0_col81;
    logic [1  : 0] layer0_col82;
    logic [1  : 0] layer0_col83;
    logic [1  : 0] layer0_col84;
    logic [1  : 0] layer0_col85;
    logic [1  : 0] layer0_col86;
    logic [1  : 0] layer0_col87;
    logic [1  : 0] layer0_col88;
    logic [1  : 0] layer0_col89;
    logic [1  : 0] layer0_col90;
    logic [1  : 0] layer0_col91;
    logic [1  : 0] layer0_col92;
    logic [1  : 0] layer0_col93;
    logic [1  : 0] layer0_col94;
    logic [1  : 0] layer0_col95;
    logic [1  : 0] layer0_col96;
    logic [1  : 0] layer0_col97;
    logic          layer0_col98;
    logic          layer0_col99;
    logic          layer0_col100;
    logic          layer0_col101;
    logic          layer0_col102;
    logic          layer0_col103;
    
    logic    COUT_LA_l0_floating_placement;
    logic    CIN_LA_l0_floating_placement;
    logic    CY_LA_l0_floating_placement;
    logic    PROP_LA_l0_floating_placement;
    
    
    
    // -------------------------------------------------- TERMINAL ADDITION ------------------------------------------------
    logic          layer1_col0;
    logic          layer1_col1;
    logic          layer1_col2;
    logic          layer1_col3;
    logic          layer1_col4;
    logic          layer1_col5;
    logic          layer1_col6;
    logic          layer1_col7;
    logic          layer1_col8;
    logic          layer1_col9;
    logic          layer1_col10;
    logic          layer1_col11;
    logic          layer1_col12;
    logic          layer1_col13;
    logic          layer1_col14;
    logic          layer1_col15;
    logic          layer1_col16;
    logic          layer1_col17;
    logic          layer1_col18;
    logic          layer1_col19;
    logic          layer1_col20;
    logic          layer1_col21;
    logic          layer1_col22;
    logic          layer1_col23;
    logic          layer1_col24;
    logic          layer1_col25;
    logic [1  : 0] layer1_col26;
    logic [1  : 0] layer1_col27;
    logic [1  : 0] layer1_col28;
    logic [1  : 0] layer1_col29;
    logic [1  : 0] layer1_col30;
    logic [1  : 0] layer1_col31;
    logic [1  : 0] layer1_col32;
    logic [1  : 0] layer1_col33;
    logic [1  : 0] layer1_col34;
    logic [1  : 0] layer1_col35;
    logic [1  : 0] layer1_col36;
    logic [1  : 0] layer1_col37;
    logic [1  : 0] layer1_col38;
    logic [1  : 0] layer1_col39;
    logic [1  : 0] layer1_col40;
    logic [1  : 0] layer1_col41;
    logic [1  : 0] layer1_col42;
    logic [1  : 0] layer1_col43;
    logic [1  : 0] layer1_col44;
    logic [1  : 0] layer1_col45;
    logic [2  : 0] layer1_col46;
    logic [2  : 0] layer1_col47;
    logic [2  : 0] layer1_col48;
    logic [2  : 0] layer1_col49;
    logic [2  : 0] layer1_col50;
    logic [2  : 0] layer1_col51;
    logic [2  : 0] layer1_col52;
    logic [2  : 0] layer1_col53;
    logic [2  : 0] layer1_col54;
    logic [2  : 0] layer1_col55;
    logic [2  : 0] layer1_col56;
    logic [2  : 0] layer1_col57;
    logic [2  : 0] layer1_col58;
    logic [2  : 0] layer1_col59;
    logic [2  : 0] layer1_col60;
    logic [2  : 0] layer1_col61;
    logic [2  : 0] layer1_col62;
    logic [2  : 0] layer1_col63;
    logic [2  : 0] layer1_col64;
    logic [2  : 0] layer1_col65;
    logic [2  : 0] layer1_col66;
    logic [2  : 0] layer1_col67;
    logic [2  : 0] layer1_col68;
    logic [2  : 0] layer1_col69;
    logic [2  : 0] layer1_col70;
    logic [2  : 0] layer1_col71;
    logic [2  : 0] layer1_col72;
    logic [2  : 0] layer1_col73;
    logic [2  : 0] layer1_col74;
    logic [2  : 0] layer1_col75;
    logic [2  : 0] layer1_col76;
    logic [2  : 0] layer1_col77;
    logic [1  : 0] layer1_col78;
    logic [1  : 0] layer1_col79;
    logic [1  : 0] layer1_col80;
    logic [1  : 0] layer1_col81;
    logic [1  : 0] layer1_col82;
    logic [1  : 0] layer1_col83;
    logic [1  : 0] layer1_col84;
    logic [1  : 0] layer1_col85;
    logic [1  : 0] layer1_col86;
    logic [1  : 0] layer1_col87;
    logic [1  : 0] layer1_col88;
    logic [1  : 0] layer1_col89;
    logic [1  : 0] layer1_col90;
    logic [1  : 0] layer1_col91;
    logic [1  : 0] layer1_col92;
    logic [1  : 0] layer1_col93;
    logic [1  : 0] layer1_col94;
    logic [1  : 0] layer1_col95;
    logic [1  : 0] layer1_col96;
    logic [1  : 0] layer1_col97;
    logic          layer1_col98;
    logic          layer1_col99;
    logic          layer1_col100;
    logic          layer1_col101;
    logic          layer1_col102;
    logic          layer1_col103;
    
    logic [72 : 0] terminal_chain1_out;
    
    logic [35 : 0] COUT_LA_terminal_chain1;
    logic [8  : 0] CIN_LA_terminal_chain1;
    logic [71 : 0] CY_LA_terminal_chain1;
    logic [71 : 0] PROP_LA_terminal_chain1;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i0;
    logic [1 : 0] O_c3_2_terminal_chain1_i0;
    logic         CY_c3_2_terminal_chain1_i0;
    logic         PROP_c3_2_terminal_chain1_i0;
    logic         terminal_chain1_i0;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i1;
    logic [1 : 0] O_c3_2_terminal_chain1_i1;
    logic         CY_c3_2_terminal_chain1_i1;
    logic         PROP_c3_2_terminal_chain1_i1;
    logic         terminal_chain1_i1;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i2;
    logic [1 : 0] O_c3_2_terminal_chain1_i2;
    logic         CY_c3_2_terminal_chain1_i2;
    logic         PROP_c3_2_terminal_chain1_i2;
    logic         terminal_chain1_i2;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i3;
    logic [1 : 0] O_c3_2_terminal_chain1_i3;
    logic         CY_c3_2_terminal_chain1_i3;
    logic         PROP_c3_2_terminal_chain1_i3;
    logic         terminal_chain1_i3;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i4;
    logic [1 : 0] O_c3_2_terminal_chain1_i4;
    logic         CY_c3_2_terminal_chain1_i4;
    logic         PROP_c3_2_terminal_chain1_i4;
    logic         terminal_chain1_i4;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i5;
    logic [1 : 0] O_c3_2_terminal_chain1_i5;
    logic         CY_c3_2_terminal_chain1_i5;
    logic         PROP_c3_2_terminal_chain1_i5;
    logic         terminal_chain1_i5;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i6;
    logic [1 : 0] O_c3_2_terminal_chain1_i6;
    logic         CY_c3_2_terminal_chain1_i6;
    logic         PROP_c3_2_terminal_chain1_i6;
    logic         terminal_chain1_i6;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i7;
    logic [1 : 0] O_c3_2_terminal_chain1_i7;
    logic         CY_c3_2_terminal_chain1_i7;
    logic         PROP_c3_2_terminal_chain1_i7;
    logic         terminal_chain1_i7;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i8;
    logic [1 : 0] O_c3_2_terminal_chain1_i8;
    logic         CY_c3_2_terminal_chain1_i8;
    logic         PROP_c3_2_terminal_chain1_i8;
    logic         terminal_chain1_i8;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i9;
    logic [1 : 0] O_c3_2_terminal_chain1_i9;
    logic         CY_c3_2_terminal_chain1_i9;
    logic         PROP_c3_2_terminal_chain1_i9;
    logic         terminal_chain1_i9;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i10;
    logic [1 : 0] O_c3_2_terminal_chain1_i10;
    logic         CY_c3_2_terminal_chain1_i10;
    logic         PROP_c3_2_terminal_chain1_i10;
    logic         terminal_chain1_i10;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i11;
    logic [1 : 0] O_c3_2_terminal_chain1_i11;
    logic         CY_c3_2_terminal_chain1_i11;
    logic         PROP_c3_2_terminal_chain1_i11;
    logic         terminal_chain1_i11;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i12;
    logic [1 : 0] O_c3_2_terminal_chain1_i12;
    logic         CY_c3_2_terminal_chain1_i12;
    logic         PROP_c3_2_terminal_chain1_i12;
    logic         terminal_chain1_i12;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i13;
    logic [1 : 0] O_c3_2_terminal_chain1_i13;
    logic         CY_c3_2_terminal_chain1_i13;
    logic         PROP_c3_2_terminal_chain1_i13;
    logic         terminal_chain1_i13;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i14;
    logic [1 : 0] O_c3_2_terminal_chain1_i14;
    logic         CY_c3_2_terminal_chain1_i14;
    logic         PROP_c3_2_terminal_chain1_i14;
    logic         terminal_chain1_i14;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i15;
    logic [1 : 0] O_c3_2_terminal_chain1_i15;
    logic         CY_c3_2_terminal_chain1_i15;
    logic         PROP_c3_2_terminal_chain1_i15;
    logic         terminal_chain1_i15;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i16;
    logic [1 : 0] O_c3_2_terminal_chain1_i16;
    logic         CY_c3_2_terminal_chain1_i16;
    logic         PROP_c3_2_terminal_chain1_i16;
    logic         terminal_chain1_i16;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i17;
    logic [1 : 0] O_c3_2_terminal_chain1_i17;
    logic         CY_c3_2_terminal_chain1_i17;
    logic         PROP_c3_2_terminal_chain1_i17;
    logic         terminal_chain1_i17;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i18;
    logic [1 : 0] O_c3_2_terminal_chain1_i18;
    logic         CY_c3_2_terminal_chain1_i18;
    logic         PROP_c3_2_terminal_chain1_i18;
    logic         terminal_chain1_i18;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i19;
    logic [1 : 0] O_c3_2_terminal_chain1_i19;
    logic         CY_c3_2_terminal_chain1_i19;
    logic         PROP_c3_2_terminal_chain1_i19;
    logic         terminal_chain1_i19;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i20;
    logic         C1_c15_3_terminal_chain1_i20;
    logic         CLA_c15_3_terminal_chain1_i20;
    logic [2 : 0] O_c15_3_terminal_chain1_i20;
    logic [1 : 0] CY_c15_3_terminal_chain1_i20;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i20;
    logic         terminal_chain1_i20;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i21;
    logic         C1_c15_3_terminal_chain1_i21;
    logic         CLA_c15_3_terminal_chain1_i21;
    logic [2 : 0] O_c15_3_terminal_chain1_i21;
    logic [1 : 0] CY_c15_3_terminal_chain1_i21;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i21;
    logic         terminal_chain1_i21;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i22;
    logic         C1_c15_3_terminal_chain1_i22;
    logic         CLA_c15_3_terminal_chain1_i22;
    logic [2 : 0] O_c15_3_terminal_chain1_i22;
    logic [1 : 0] CY_c15_3_terminal_chain1_i22;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i22;
    logic         terminal_chain1_i22;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i23;
    logic         C1_c15_3_terminal_chain1_i23;
    logic         CLA_c15_3_terminal_chain1_i23;
    logic [2 : 0] O_c15_3_terminal_chain1_i23;
    logic [1 : 0] CY_c15_3_terminal_chain1_i23;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i23;
    logic         terminal_chain1_i23;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i24;
    logic         C1_c15_3_terminal_chain1_i24;
    logic         CLA_c15_3_terminal_chain1_i24;
    logic [2 : 0] O_c15_3_terminal_chain1_i24;
    logic [1 : 0] CY_c15_3_terminal_chain1_i24;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i24;
    logic         terminal_chain1_i24;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i25;
    logic         C1_c15_3_terminal_chain1_i25;
    logic         CLA_c15_3_terminal_chain1_i25;
    logic [2 : 0] O_c15_3_terminal_chain1_i25;
    logic [1 : 0] CY_c15_3_terminal_chain1_i25;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i25;
    logic         terminal_chain1_i25;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i26;
    logic         C1_c15_3_terminal_chain1_i26;
    logic         CLA_c15_3_terminal_chain1_i26;
    logic [2 : 0] O_c15_3_terminal_chain1_i26;
    logic [1 : 0] CY_c15_3_terminal_chain1_i26;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i26;
    logic         terminal_chain1_i26;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i27;
    logic         C1_c15_3_terminal_chain1_i27;
    logic         CLA_c15_3_terminal_chain1_i27;
    logic [2 : 0] O_c15_3_terminal_chain1_i27;
    logic [1 : 0] CY_c15_3_terminal_chain1_i27;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i27;
    logic         terminal_chain1_i27;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i28;
    logic         C1_c15_3_terminal_chain1_i28;
    logic         CLA_c15_3_terminal_chain1_i28;
    logic [2 : 0] O_c15_3_terminal_chain1_i28;
    logic [1 : 0] CY_c15_3_terminal_chain1_i28;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i28;
    logic         terminal_chain1_i28;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i29;
    logic         C1_c15_3_terminal_chain1_i29;
    logic         CLA_c15_3_terminal_chain1_i29;
    logic [2 : 0] O_c15_3_terminal_chain1_i29;
    logic [1 : 0] CY_c15_3_terminal_chain1_i29;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i29;
    logic         terminal_chain1_i29;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i30;
    logic         C1_c15_3_terminal_chain1_i30;
    logic         CLA_c15_3_terminal_chain1_i30;
    logic [2 : 0] O_c15_3_terminal_chain1_i30;
    logic [1 : 0] CY_c15_3_terminal_chain1_i30;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i30;
    logic         terminal_chain1_i30;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i31;
    logic         C1_c15_3_terminal_chain1_i31;
    logic         CLA_c15_3_terminal_chain1_i31;
    logic [2 : 0] O_c15_3_terminal_chain1_i31;
    logic [1 : 0] CY_c15_3_terminal_chain1_i31;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i31;
    logic         terminal_chain1_i31;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i32;
    logic         C1_c15_3_terminal_chain1_i32;
    logic         CLA_c15_3_terminal_chain1_i32;
    logic [2 : 0] O_c15_3_terminal_chain1_i32;
    logic [1 : 0] CY_c15_3_terminal_chain1_i32;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i32;
    logic         terminal_chain1_i32;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i33;
    logic         C1_c15_3_terminal_chain1_i33;
    logic         CLA_c15_3_terminal_chain1_i33;
    logic [2 : 0] O_c15_3_terminal_chain1_i33;
    logic [1 : 0] CY_c15_3_terminal_chain1_i33;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i33;
    logic         terminal_chain1_i33;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i34;
    logic         C1_c15_3_terminal_chain1_i34;
    logic         CLA_c15_3_terminal_chain1_i34;
    logic [2 : 0] O_c15_3_terminal_chain1_i34;
    logic [1 : 0] CY_c15_3_terminal_chain1_i34;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i34;
    logic         terminal_chain1_i34;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i35;
    logic         C1_c15_3_terminal_chain1_i35;
    logic         CLA_c15_3_terminal_chain1_i35;
    logic [2 : 0] O_c15_3_terminal_chain1_i35;
    logic [1 : 0] CY_c15_3_terminal_chain1_i35;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i35;
    logic         terminal_chain1_i35;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i36;
    logic [1 : 0] O_c3_2_terminal_chain1_i36;
    logic         CY_c3_2_terminal_chain1_i36;
    logic         PROP_c3_2_terminal_chain1_i36;
    logic         terminal_chain1_i36;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i37;
    logic [1 : 0] O_c3_2_terminal_chain1_i37;
    logic         CY_c3_2_terminal_chain1_i37;
    logic         PROP_c3_2_terminal_chain1_i37;
    logic         terminal_chain1_i37;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i38;
    logic [1 : 0] O_c3_2_terminal_chain1_i38;
    logic         CY_c3_2_terminal_chain1_i38;
    logic         PROP_c3_2_terminal_chain1_i38;
    logic         terminal_chain1_i38;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i39;
    logic [1 : 0] O_c3_2_terminal_chain1_i39;
    logic         CY_c3_2_terminal_chain1_i39;
    logic         PROP_c3_2_terminal_chain1_i39;
    logic         terminal_chain1_i39;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i40;
    logic [1 : 0] O_c3_2_terminal_chain1_i40;
    logic         CY_c3_2_terminal_chain1_i40;
    logic         PROP_c3_2_terminal_chain1_i40;
    logic         terminal_chain1_i40;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i41;
    logic [1 : 0] O_c3_2_terminal_chain1_i41;
    logic         CY_c3_2_terminal_chain1_i41;
    logic         PROP_c3_2_terminal_chain1_i41;
    logic         terminal_chain1_i41;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i42;
    logic [1 : 0] O_c3_2_terminal_chain1_i42;
    logic         CY_c3_2_terminal_chain1_i42;
    logic         PROP_c3_2_terminal_chain1_i42;
    logic         terminal_chain1_i42;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i43;
    logic [1 : 0] O_c3_2_terminal_chain1_i43;
    logic         CY_c3_2_terminal_chain1_i43;
    logic         PROP_c3_2_terminal_chain1_i43;
    logic         terminal_chain1_i43;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i44;
    logic [1 : 0] O_c3_2_terminal_chain1_i44;
    logic         CY_c3_2_terminal_chain1_i44;
    logic         PROP_c3_2_terminal_chain1_i44;
    logic         terminal_chain1_i44;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i45;
    logic [1 : 0] O_c3_2_terminal_chain1_i45;
    logic         CY_c3_2_terminal_chain1_i45;
    logic         PROP_c3_2_terminal_chain1_i45;
    logic         terminal_chain1_i45;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i46;
    logic [1 : 0] O_c3_2_terminal_chain1_i46;
    logic         CY_c3_2_terminal_chain1_i46;
    logic         PROP_c3_2_terminal_chain1_i46;
    logic         terminal_chain1_i46;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i47;
    logic [1 : 0] O_c3_2_terminal_chain1_i47;
    logic         CY_c3_2_terminal_chain1_i47;
    logic         PROP_c3_2_terminal_chain1_i47;
    logic         terminal_chain1_i47;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i48;
    logic [1 : 0] O_c3_2_terminal_chain1_i48;
    logic         CY_c3_2_terminal_chain1_i48;
    logic         PROP_c3_2_terminal_chain1_i48;
    logic         terminal_chain1_i48;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i49;
    logic [1 : 0] O_c3_2_terminal_chain1_i49;
    logic         CY_c3_2_terminal_chain1_i49;
    logic         PROP_c3_2_terminal_chain1_i49;
    logic         terminal_chain1_i49;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i50;
    logic [1 : 0] O_c3_2_terminal_chain1_i50;
    logic         CY_c3_2_terminal_chain1_i50;
    logic         PROP_c3_2_terminal_chain1_i50;
    logic         terminal_chain1_i50;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i51;
    logic [1 : 0] O_c3_2_terminal_chain1_i51;
    logic         CY_c3_2_terminal_chain1_i51;
    logic         PROP_c3_2_terminal_chain1_i51;
    logic         terminal_chain1_i51;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i52;
    logic [1 : 0] O_c3_2_terminal_chain1_i52;
    logic         CY_c3_2_terminal_chain1_i52;
    logic         PROP_c3_2_terminal_chain1_i52;
    logic         terminal_chain1_i52;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i53;
    logic [1 : 0] O_c3_2_terminal_chain1_i53;
    logic         CY_c3_2_terminal_chain1_i53;
    logic         PROP_c3_2_terminal_chain1_i53;
    logic         terminal_chain1_i53;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i54;
    logic [1 : 0] O_c3_2_terminal_chain1_i54;
    logic         CY_c3_2_terminal_chain1_i54;
    logic         PROP_c3_2_terminal_chain1_i54;
    logic         terminal_chain1_i54;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i55;
    logic [1 : 0] O_c3_2_terminal_chain1_i55;
    logic         CY_c3_2_terminal_chain1_i55;
    logic         PROP_c3_2_terminal_chain1_i55;
    logic         terminal_chain1_i55;
    
    logic [57 : 0] terminal_chain2_out;
    
    logic [31 : 0] COUT_LA_terminal_chain2;
    logic [7  : 0] CIN_LA_terminal_chain2;
    logic [63 : 0] CY_LA_terminal_chain2;
    logic [63 : 0] PROP_LA_terminal_chain2;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i0;
    logic         C1_c15_3_terminal_chain2_i0;
    logic         CLA_c15_3_terminal_chain2_i0;
    logic [2 : 0] O_c15_3_terminal_chain2_i0;
    logic [1 : 0] CY_c15_3_terminal_chain2_i0;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i0;
    logic         terminal_chain2_i0;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i1;
    logic         C1_c15_3_terminal_chain2_i1;
    logic         CLA_c15_3_terminal_chain2_i1;
    logic [2 : 0] O_c15_3_terminal_chain2_i1;
    logic [1 : 0] CY_c15_3_terminal_chain2_i1;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i1;
    logic         terminal_chain2_i1;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i2;
    logic         C1_c15_3_terminal_chain2_i2;
    logic         CLA_c15_3_terminal_chain2_i2;
    logic [2 : 0] O_c15_3_terminal_chain2_i2;
    logic [1 : 0] CY_c15_3_terminal_chain2_i2;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i2;
    logic         terminal_chain2_i2;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i3;
    logic         C1_c15_3_terminal_chain2_i3;
    logic         CLA_c15_3_terminal_chain2_i3;
    logic [2 : 0] O_c15_3_terminal_chain2_i3;
    logic [1 : 0] CY_c15_3_terminal_chain2_i3;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i3;
    logic         terminal_chain2_i3;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i4;
    logic         C1_c15_3_terminal_chain2_i4;
    logic         CLA_c15_3_terminal_chain2_i4;
    logic [2 : 0] O_c15_3_terminal_chain2_i4;
    logic [1 : 0] CY_c15_3_terminal_chain2_i4;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i4;
    logic         terminal_chain2_i4;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i5;
    logic         C1_c15_3_terminal_chain2_i5;
    logic         CLA_c15_3_terminal_chain2_i5;
    logic [2 : 0] O_c15_3_terminal_chain2_i5;
    logic [1 : 0] CY_c15_3_terminal_chain2_i5;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i5;
    logic         terminal_chain2_i5;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i6;
    logic         C1_c15_3_terminal_chain2_i6;
    logic         CLA_c15_3_terminal_chain2_i6;
    logic [2 : 0] O_c15_3_terminal_chain2_i6;
    logic [1 : 0] CY_c15_3_terminal_chain2_i6;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i6;
    logic         terminal_chain2_i6;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i7;
    logic         C1_c15_3_terminal_chain2_i7;
    logic         CLA_c15_3_terminal_chain2_i7;
    logic [2 : 0] O_c15_3_terminal_chain2_i7;
    logic [1 : 0] CY_c15_3_terminal_chain2_i7;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i7;
    logic         terminal_chain2_i7;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i8;
    logic         C1_c15_3_terminal_chain2_i8;
    logic         CLA_c15_3_terminal_chain2_i8;
    logic [2 : 0] O_c15_3_terminal_chain2_i8;
    logic [1 : 0] CY_c15_3_terminal_chain2_i8;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i8;
    logic         terminal_chain2_i8;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i9;
    logic         C1_c15_3_terminal_chain2_i9;
    logic         CLA_c15_3_terminal_chain2_i9;
    logic [2 : 0] O_c15_3_terminal_chain2_i9;
    logic [1 : 0] CY_c15_3_terminal_chain2_i9;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i9;
    logic         terminal_chain2_i9;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i10;
    logic         C1_c15_3_terminal_chain2_i10;
    logic         CLA_c15_3_terminal_chain2_i10;
    logic [2 : 0] O_c15_3_terminal_chain2_i10;
    logic [1 : 0] CY_c15_3_terminal_chain2_i10;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i10;
    logic         terminal_chain2_i10;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i11;
    logic         C1_c15_3_terminal_chain2_i11;
    logic         CLA_c15_3_terminal_chain2_i11;
    logic [2 : 0] O_c15_3_terminal_chain2_i11;
    logic [1 : 0] CY_c15_3_terminal_chain2_i11;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i11;
    logic         terminal_chain2_i11;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i12;
    logic         C1_c15_3_terminal_chain2_i12;
    logic         CLA_c15_3_terminal_chain2_i12;
    logic [2 : 0] O_c15_3_terminal_chain2_i12;
    logic [1 : 0] CY_c15_3_terminal_chain2_i12;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i12;
    logic         terminal_chain2_i12;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i13;
    logic         C1_c15_3_terminal_chain2_i13;
    logic         CLA_c15_3_terminal_chain2_i13;
    logic [2 : 0] O_c15_3_terminal_chain2_i13;
    logic [1 : 0] CY_c15_3_terminal_chain2_i13;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i13;
    logic         terminal_chain2_i13;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i14;
    logic         C1_c15_3_terminal_chain2_i14;
    logic         CLA_c15_3_terminal_chain2_i14;
    logic [2 : 0] O_c15_3_terminal_chain2_i14;
    logic [1 : 0] CY_c15_3_terminal_chain2_i14;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i14;
    logic         terminal_chain2_i14;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i15;
    logic         C1_c15_3_terminal_chain2_i15;
    logic         CLA_c15_3_terminal_chain2_i15;
    logic [2 : 0] O_c15_3_terminal_chain2_i15;
    logic [1 : 0] CY_c15_3_terminal_chain2_i15;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i15;
    logic         terminal_chain2_i15;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i16;
    logic [1 : 0] O_c3_2_terminal_chain2_i16;
    logic         CY_c3_2_terminal_chain2_i16;
    logic         PROP_c3_2_terminal_chain2_i16;
    logic         terminal_chain2_i16;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i17;
    logic [1 : 0] O_c3_2_terminal_chain2_i17;
    logic         CY_c3_2_terminal_chain2_i17;
    logic         PROP_c3_2_terminal_chain2_i17;
    logic         terminal_chain2_i17;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i18;
    logic [1 : 0] O_c3_2_terminal_chain2_i18;
    logic         CY_c3_2_terminal_chain2_i18;
    logic         PROP_c3_2_terminal_chain2_i18;
    logic         terminal_chain2_i18;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i19;
    logic [1 : 0] O_c3_2_terminal_chain2_i19;
    logic         CY_c3_2_terminal_chain2_i19;
    logic         PROP_c3_2_terminal_chain2_i19;
    logic         terminal_chain2_i19;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i20;
    logic [1 : 0] O_c3_2_terminal_chain2_i20;
    logic         CY_c3_2_terminal_chain2_i20;
    logic         PROP_c3_2_terminal_chain2_i20;
    logic         terminal_chain2_i20;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i21;
    logic [1 : 0] O_c3_2_terminal_chain2_i21;
    logic         CY_c3_2_terminal_chain2_i21;
    logic         PROP_c3_2_terminal_chain2_i21;
    logic         terminal_chain2_i21;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i22;
    logic [1 : 0] O_c3_2_terminal_chain2_i22;
    logic         CY_c3_2_terminal_chain2_i22;
    logic         PROP_c3_2_terminal_chain2_i22;
    logic         terminal_chain2_i22;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i23;
    logic [1 : 0] O_c3_2_terminal_chain2_i23;
    logic         CY_c3_2_terminal_chain2_i23;
    logic         PROP_c3_2_terminal_chain2_i23;
    logic         terminal_chain2_i23;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i24;
    logic [1 : 0] O_c3_2_terminal_chain2_i24;
    logic         CY_c3_2_terminal_chain2_i24;
    logic         PROP_c3_2_terminal_chain2_i24;
    logic         terminal_chain2_i24;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i25;
    logic [1 : 0] O_c3_2_terminal_chain2_i25;
    logic         CY_c3_2_terminal_chain2_i25;
    logic         PROP_c3_2_terminal_chain2_i25;
    logic         terminal_chain2_i25;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i26;
    logic [1 : 0] O_c3_2_terminal_chain2_i26;
    logic         CY_c3_2_terminal_chain2_i26;
    logic         PROP_c3_2_terminal_chain2_i26;
    logic         terminal_chain2_i26;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i27;
    logic [1 : 0] O_c3_2_terminal_chain2_i27;
    logic         CY_c3_2_terminal_chain2_i27;
    logic         PROP_c3_2_terminal_chain2_i27;
    logic         terminal_chain2_i27;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i28;
    logic [1 : 0] O_c3_2_terminal_chain2_i28;
    logic         CY_c3_2_terminal_chain2_i28;
    logic         PROP_c3_2_terminal_chain2_i28;
    logic         terminal_chain2_i28;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i29;
    logic [1 : 0] O_c3_2_terminal_chain2_i29;
    logic         CY_c3_2_terminal_chain2_i29;
    logic         PROP_c3_2_terminal_chain2_i29;
    logic         terminal_chain2_i29;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i30;
    logic [1 : 0] O_c3_2_terminal_chain2_i30;
    logic         CY_c3_2_terminal_chain2_i30;
    logic         PROP_c3_2_terminal_chain2_i30;
    logic         terminal_chain2_i30;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i31;
    logic [1 : 0] O_c3_2_terminal_chain2_i31;
    logic         CY_c3_2_terminal_chain2_i31;
    logic         PROP_c3_2_terminal_chain2_i31;
    logic         terminal_chain2_i31;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i32;
    logic [1 : 0] O_c3_2_terminal_chain2_i32;
    logic         CY_c3_2_terminal_chain2_i32;
    logic         PROP_c3_2_terminal_chain2_i32;
    logic         terminal_chain2_i32;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i33;
    logic [1 : 0] O_c3_2_terminal_chain2_i33;
    logic         CY_c3_2_terminal_chain2_i33;
    logic         PROP_c3_2_terminal_chain2_i33;
    logic         terminal_chain2_i33;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i34;
    logic [1 : 0] O_c3_2_terminal_chain2_i34;
    logic         CY_c3_2_terminal_chain2_i34;
    logic         PROP_c3_2_terminal_chain2_i34;
    logic         terminal_chain2_i34;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i35;
    logic [1 : 0] O_c3_2_terminal_chain2_i35;
    logic         CY_c3_2_terminal_chain2_i35;
    logic         PROP_c3_2_terminal_chain2_i35;
    logic         terminal_chain2_i35;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i36;
    logic [1 : 0] O_c3_2_terminal_chain2_i36;
    logic         CY_c3_2_terminal_chain2_i36;
    logic         PROP_c3_2_terminal_chain2_i36;
    logic         terminal_chain2_i36;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i37;
    logic [1 : 0] O_c3_2_terminal_chain2_i37;
    logic         CY_c3_2_terminal_chain2_i37;
    logic         PROP_c3_2_terminal_chain2_i37;
    logic         terminal_chain2_i37;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i38;
    logic [1 : 0] O_c3_2_terminal_chain2_i38;
    logic         CY_c3_2_terminal_chain2_i38;
    logic         PROP_c3_2_terminal_chain2_i38;
    logic         terminal_chain2_i38;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i39;
    logic [1 : 0] O_c3_2_terminal_chain2_i39;
    logic         CY_c3_2_terminal_chain2_i39;
    logic         PROP_c3_2_terminal_chain2_i39;
    logic         terminal_chain2_i39;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i40;
    logic [1 : 0] O_c3_2_terminal_chain2_i40;
    logic         CY_c3_2_terminal_chain2_i40;
    logic         PROP_c3_2_terminal_chain2_i40;
    logic         terminal_chain2_i40;
    
    // ------------------------------ LAYER 0 ------------------------------
    always_ff @(posedge clk) begin
        layer1_col0    <= layer0_col0;
        layer1_col1    <= layer0_col1;
        layer1_col2    <= layer0_col2;
        layer1_col3    <= layer0_col3;
        layer1_col4    <= layer0_col4;
        layer1_col5    <= layer0_col5;
        layer1_col6    <= layer0_col6;
        layer1_col7    <= layer0_col7;
        layer1_col8    <= layer0_col8;
        layer1_col9    <= layer0_col9;
        layer1_col10    <= layer0_col10;
        layer1_col11    <= layer0_col11;
        layer1_col12    <= layer0_col12;
        layer1_col13    <= layer0_col13;
        layer1_col14    <= layer0_col14;
        layer1_col15    <= layer0_col15;
        layer1_col16    <= layer0_col16;
        layer1_col17    <= layer0_col17;
        layer1_col18    <= layer0_col18;
        layer1_col19    <= layer0_col19;
        layer1_col20    <= layer0_col20;
        layer1_col21    <= layer0_col21;
        layer1_col22    <= layer0_col22;
        layer1_col23    <= layer0_col23;
        layer1_col24    <= layer0_col24;
        layer1_col25    <= layer0_col25;
        layer1_col26[0] <= layer0_col26[0];
        layer1_col26[1] <= layer0_col26[1];
        layer1_col27[0] <= layer0_col27[0];
        layer1_col27[1] <= layer0_col27[1];
        layer1_col28[0] <= layer0_col28[0];
        layer1_col28[1] <= layer0_col28[1];
        layer1_col29[0] <= layer0_col29[0];
        layer1_col29[1] <= layer0_col29[1];
        layer1_col30[0] <= layer0_col30[0];
        layer1_col30[1] <= layer0_col30[1];
        layer1_col31[0] <= layer0_col31[0];
        layer1_col31[1] <= layer0_col31[1];
        layer1_col32[0] <= layer0_col32[0];
        layer1_col32[1] <= layer0_col32[1];
        layer1_col33[0] <= layer0_col33[0];
        layer1_col33[1] <= layer0_col33[1];
        layer1_col34[0] <= layer0_col34[0];
        layer1_col34[1] <= layer0_col34[1];
        layer1_col35[0] <= layer0_col35[0];
        layer1_col35[1] <= layer0_col35[1];
        layer1_col36[0] <= layer0_col36[0];
        layer1_col36[1] <= layer0_col36[1];
        layer1_col37[0] <= layer0_col37[0];
        layer1_col37[1] <= layer0_col37[1];
        layer1_col38[0] <= layer0_col38[0];
        layer1_col38[1] <= layer0_col38[1];
        layer1_col39[0] <= layer0_col39[0];
        layer1_col39[1] <= layer0_col39[1];
        layer1_col40[0] <= layer0_col40[0];
        layer1_col40[1] <= layer0_col40[1];
        layer1_col41[0] <= layer0_col41[0];
        layer1_col41[1] <= layer0_col41[1];
        layer1_col42[0] <= layer0_col42[0];
        layer1_col42[1] <= layer0_col42[1];
        layer1_col43[0] <= layer0_col43[0];
        layer1_col43[1] <= layer0_col43[1];
        layer1_col44[0] <= layer0_col44[0];
        layer1_col44[1] <= layer0_col44[1];
        layer1_col45[0] <= layer0_col45[0];
        layer1_col45[1] <= layer0_col45[1];
        layer1_col46[0] <= layer0_col46[0];
        layer1_col46[1] <= layer0_col46[1];
        layer1_col46[2] <= layer0_col46[2];
        layer1_col47[0] <= layer0_col47[0];
        layer1_col47[1] <= layer0_col47[1];
        layer1_col47[2] <= layer0_col47[2];
        layer1_col48[0] <= layer0_col48[0];
        layer1_col48[1] <= layer0_col48[1];
        layer1_col48[2] <= layer0_col48[2];
        layer1_col49[0] <= layer0_col49[0];
        layer1_col49[1] <= layer0_col49[1];
        layer1_col49[2] <= layer0_col49[2];
        layer1_col50[0] <= layer0_col50[0];
        layer1_col50[1] <= layer0_col50[1];
        layer1_col50[2] <= layer0_col50[2];
        layer1_col51[0] <= layer0_col51[0];
        layer1_col51[1] <= layer0_col51[1];
        layer1_col51[2] <= layer0_col51[2];
        layer1_col52[0] <= layer0_col52[0];
        layer1_col52[1] <= layer0_col52[1];
        layer1_col52[2] <= layer0_col52[2];
        layer1_col53[0] <= layer0_col53[0];
        layer1_col53[1] <= layer0_col53[1];
        layer1_col53[2] <= layer0_col53[2];
        layer1_col54[0] <= layer0_col54[0];
        layer1_col54[1] <= layer0_col54[1];
        layer1_col54[2] <= layer0_col54[2];
        layer1_col55[0] <= layer0_col55[0];
        layer1_col55[1] <= layer0_col55[1];
        layer1_col55[2] <= layer0_col55[2];
        layer1_col56[0] <= layer0_col56[0];
        layer1_col56[1] <= layer0_col56[1];
        layer1_col56[2] <= layer0_col56[2];
        layer1_col57[0] <= layer0_col57[0];
        layer1_col57[1] <= layer0_col57[1];
        layer1_col57[2] <= layer0_col57[2];
        layer1_col58[0] <= layer0_col58[0];
        layer1_col58[1] <= layer0_col58[1];
        layer1_col58[2] <= layer0_col58[2];
        layer1_col59[0] <= layer0_col59[0];
        layer1_col59[1] <= layer0_col59[1];
        layer1_col59[2] <= layer0_col59[2];
        layer1_col60[0] <= layer0_col60[0];
        layer1_col60[1] <= layer0_col60[1];
        layer1_col60[2] <= layer0_col60[2];
        layer1_col61[0] <= layer0_col61[0];
        layer1_col61[1] <= layer0_col61[1];
        layer1_col61[2] <= layer0_col61[2];
        layer1_col62[0] <= layer0_col62[0];
        layer1_col62[1] <= layer0_col62[1];
        layer1_col62[2] <= layer0_col62[2];
        layer1_col63[0] <= layer0_col63[0];
        layer1_col63[1] <= layer0_col63[1];
        layer1_col63[2] <= layer0_col63[2];
        layer1_col64[0] <= layer0_col64[0];
        layer1_col64[1] <= layer0_col64[1];
        layer1_col64[2] <= layer0_col64[2];
        layer1_col65[0] <= layer0_col65[0];
        layer1_col65[1] <= layer0_col65[1];
        layer1_col65[2] <= layer0_col65[2];
        layer1_col66[0] <= layer0_col66[0];
        layer1_col66[1] <= layer0_col66[1];
        layer1_col66[2] <= layer0_col66[2];
        layer1_col67[0] <= layer0_col67[0];
        layer1_col67[1] <= layer0_col67[1];
        layer1_col67[2] <= layer0_col67[2];
        layer1_col68[0] <= layer0_col68[0];
        layer1_col68[1] <= layer0_col68[1];
        layer1_col68[2] <= layer0_col68[2];
        layer1_col69[0] <= layer0_col69[0];
        layer1_col69[1] <= layer0_col69[1];
        layer1_col69[2] <= layer0_col69[2];
        layer1_col70[0] <= layer0_col70[0];
        layer1_col70[1] <= layer0_col70[1];
        layer1_col70[2] <= layer0_col70[2];
        layer1_col71[0] <= layer0_col71[0];
        layer1_col71[1] <= layer0_col71[1];
        layer1_col71[2] <= layer0_col71[2];
        layer1_col72[0] <= layer0_col72[0];
        layer1_col72[1] <= layer0_col72[1];
        layer1_col72[2] <= layer0_col72[2];
        layer1_col73[0] <= layer0_col73[0];
        layer1_col73[1] <= layer0_col73[1];
        layer1_col73[2] <= layer0_col73[2];
        layer1_col74[0] <= layer0_col74[0];
        layer1_col74[1] <= layer0_col74[1];
        layer1_col74[2] <= layer0_col74[2];
        layer1_col75[0] <= layer0_col75[0];
        layer1_col75[1] <= layer0_col75[1];
        layer1_col75[2] <= layer0_col75[2];
        layer1_col76[0] <= layer0_col76[0];
        layer1_col76[1] <= layer0_col76[1];
        layer1_col76[2] <= layer0_col76[2];
        layer1_col77[0] <= layer0_col77[0];
        layer1_col77[1] <= layer0_col77[1];
        layer1_col77[2] <= layer0_col77[2];
        layer1_col78[0] <= layer0_col78[0];
        layer1_col78[1] <= layer0_col78[1];
        layer1_col79[0] <= layer0_col79[0];
        layer1_col79[1] <= layer0_col79[1];
        layer1_col80[0] <= layer0_col80[0];
        layer1_col80[1] <= layer0_col80[1];
        layer1_col81[0] <= layer0_col81[0];
        layer1_col81[1] <= layer0_col81[1];
        layer1_col82[0] <= layer0_col82[0];
        layer1_col82[1] <= layer0_col82[1];
        layer1_col83[0] <= layer0_col83[0];
        layer1_col83[1] <= layer0_col83[1];
        layer1_col84[0] <= layer0_col84[0];
        layer1_col84[1] <= layer0_col84[1];
        layer1_col85[0] <= layer0_col85[0];
        layer1_col85[1] <= layer0_col85[1];
        layer1_col86[0] <= layer0_col86[0];
        layer1_col86[1] <= layer0_col86[1];
        layer1_col87[0] <= layer0_col87[0];
        layer1_col87[1] <= layer0_col87[1];
        layer1_col88[0] <= layer0_col88[0];
        layer1_col88[1] <= layer0_col88[1];
        layer1_col89[0] <= layer0_col89[0];
        layer1_col89[1] <= layer0_col89[1];
        layer1_col90[0] <= layer0_col90[0];
        layer1_col90[1] <= layer0_col90[1];
        layer1_col91[0] <= layer0_col91[0];
        layer1_col91[1] <= layer0_col91[1];
        layer1_col92[0] <= layer0_col92[0];
        layer1_col92[1] <= layer0_col92[1];
        layer1_col93[0] <= layer0_col93[0];
        layer1_col93[1] <= layer0_col93[1];
        layer1_col94[0] <= layer0_col94[0];
        layer1_col94[1] <= layer0_col94[1];
        layer1_col95[0] <= layer0_col95[0];
        layer1_col95[1] <= layer0_col95[1];
        layer1_col96[0] <= layer0_col96[0];
        layer1_col96[1] <= layer0_col96[1];
        layer1_col97[0] <= layer0_col97[0];
        layer1_col97[1] <= layer0_col97[1];
        layer1_col98    <= layer0_col98;
        layer1_col99    <= layer0_col99;
        layer1_col100    <= layer0_col100;
        layer1_col101    <= layer0_col101;
        layer1_col102    <= layer0_col102;
        layer1_col103    <= layer0_col103;
    end
    
    
    
    // -------------------------------------------------- TERMINAL ADDITION ------------------------------------------------
    LOOKAHEAD8 #(
        .LOOKB("FALSE"),
        .LOOKD("TRUE" ),
        .LOOKF("TRUE" ),
        .LOOKH("TRUE" ))
    LOOKAHEAD8_terminal_chain1_inst0 (
        .COUTB(COUT_LA_terminal_chain1[0]),
        .COUTD(COUT_LA_terminal_chain1[1]),
        .COUTF(COUT_LA_terminal_chain1[2]),
        .COUTH(COUT_LA_terminal_chain1[3]),
        .CIN  (CIN_LA_terminal_chain1[0] ),
        .CYA  (CY_LA_terminal_chain1[0]  ),
        .CYB  (CY_LA_terminal_chain1[1]  ),
        .CYC  (CY_LA_terminal_chain1[2]  ),
        .CYD  (CY_LA_terminal_chain1[3]  ),
        .CYE  (CY_LA_terminal_chain1[4]  ),
        .CYF  (CY_LA_terminal_chain1[5]  ),
        .CYG  (CY_LA_terminal_chain1[6]  ),
        .CYH  (CY_LA_terminal_chain1[7]  ),
        .PROPA(PROP_LA_terminal_chain1[0]),
        .PROPB(PROP_LA_terminal_chain1[1]),
        .PROPC(PROP_LA_terminal_chain1[2]),
        .PROPD(PROP_LA_terminal_chain1[3]),
        .PROPE(PROP_LA_terminal_chain1[4]),
        .PROPF(PROP_LA_terminal_chain1[5]),
        .PROPG(PROP_LA_terminal_chain1[6]),
        .PROPH(PROP_LA_terminal_chain1[7]));

    LOOKAHEAD8 #(
        .LOOKB("TRUE"),
        .LOOKD("TRUE"),
        .LOOKF("TRUE"),
        .LOOKH("TRUE"))
    LOOKAHEAD8_terminal_chain1_inst1 (
        .COUTB(COUT_LA_terminal_chain1[4] ),
        .COUTD(COUT_LA_terminal_chain1[5] ),
        .COUTF(COUT_LA_terminal_chain1[6] ),
        .COUTH(COUT_LA_terminal_chain1[7] ),
        .CIN  (CIN_LA_terminal_chain1[1]  ),
        .CYA  (CY_LA_terminal_chain1[8]   ),
        .CYB  (CY_LA_terminal_chain1[9]   ),
        .CYC  (CY_LA_terminal_chain1[10]  ),
        .CYD  (CY_LA_terminal_chain1[11]  ),
        .CYE  (CY_LA_terminal_chain1[12]  ),
        .CYF  (CY_LA_terminal_chain1[13]  ),
        .CYG  (CY_LA_terminal_chain1[14]  ),
        .CYH  (CY_LA_terminal_chain1[15]  ),
        .PROPA(PROP_LA_terminal_chain1[8] ),
        .PROPB(PROP_LA_terminal_chain1[9] ),
        .PROPC(PROP_LA_terminal_chain1[10]),
        .PROPD(PROP_LA_terminal_chain1[11]),
        .PROPE(PROP_LA_terminal_chain1[12]),
        .PROPF(PROP_LA_terminal_chain1[13]),
        .PROPG(PROP_LA_terminal_chain1[14]),
        .PROPH(PROP_LA_terminal_chain1[15]));

    LOOKAHEAD8 #(
        .LOOKB("TRUE"),
        .LOOKD("TRUE"),
        .LOOKF("TRUE"),
        .LOOKH("TRUE"))
    LOOKAHEAD8_terminal_chain1_inst2 (
        .COUTB(COUT_LA_terminal_chain1[8] ),
        .COUTD(COUT_LA_terminal_chain1[9] ),
        .COUTF(COUT_LA_terminal_chain1[10]),
        .COUTH(COUT_LA_terminal_chain1[11]),
        .CIN  (CIN_LA_terminal_chain1[2]  ),
        .CYA  (CY_LA_terminal_chain1[16]  ),
        .CYB  (CY_LA_terminal_chain1[17]  ),
        .CYC  (CY_LA_terminal_chain1[18]  ),
        .CYD  (CY_LA_terminal_chain1[19]  ),
        .CYE  (CY_LA_terminal_chain1[20]  ),
        .CYF  (CY_LA_terminal_chain1[21]  ),
        .CYG  (CY_LA_terminal_chain1[22]  ),
        .CYH  (CY_LA_terminal_chain1[23]  ),
        .PROPA(PROP_LA_terminal_chain1[16]),
        .PROPB(PROP_LA_terminal_chain1[17]),
        .PROPC(PROP_LA_terminal_chain1[18]),
        .PROPD(PROP_LA_terminal_chain1[19]),
        .PROPE(PROP_LA_terminal_chain1[20]),
        .PROPF(PROP_LA_terminal_chain1[21]),
        .PROPG(PROP_LA_terminal_chain1[22]),
        .PROPH(PROP_LA_terminal_chain1[23]));

    LOOKAHEAD8 #(
        .LOOKB("TRUE"),
        .LOOKD("TRUE"),
        .LOOKF("TRUE"),
        .LOOKH("TRUE"))
    LOOKAHEAD8_terminal_chain1_inst3 (
        .COUTB(COUT_LA_terminal_chain1[12]),
        .COUTD(COUT_LA_terminal_chain1[13]),
        .COUTF(COUT_LA_terminal_chain1[14]),
        .COUTH(COUT_LA_terminal_chain1[15]),
        .CIN  (CIN_LA_terminal_chain1[3]  ),
        .CYA  (CY_LA_terminal_chain1[24]  ),
        .CYB  (CY_LA_terminal_chain1[25]  ),
        .CYC  (CY_LA_terminal_chain1[26]  ),
        .CYD  (CY_LA_terminal_chain1[27]  ),
        .CYE  (CY_LA_terminal_chain1[28]  ),
        .CYF  (CY_LA_terminal_chain1[29]  ),
        .CYG  (CY_LA_terminal_chain1[30]  ),
        .CYH  (CY_LA_terminal_chain1[31]  ),
        .PROPA(PROP_LA_terminal_chain1[24]),
        .PROPB(PROP_LA_terminal_chain1[25]),
        .PROPC(PROP_LA_terminal_chain1[26]),
        .PROPD(PROP_LA_terminal_chain1[27]),
        .PROPE(PROP_LA_terminal_chain1[28]),
        .PROPF(PROP_LA_terminal_chain1[29]),
        .PROPG(PROP_LA_terminal_chain1[30]),
        .PROPH(PROP_LA_terminal_chain1[31]));

    LOOKAHEAD8 #(
        .LOOKB("TRUE"),
        .LOOKD("TRUE"),
        .LOOKF("TRUE"),
        .LOOKH("TRUE"))
    LOOKAHEAD8_terminal_chain1_inst4 (
        .COUTB(COUT_LA_terminal_chain1[16]),
        .COUTD(COUT_LA_terminal_chain1[17]),
        .COUTF(COUT_LA_terminal_chain1[18]),
        .COUTH(COUT_LA_terminal_chain1[19]),
        .CIN  (CIN_LA_terminal_chain1[4]  ),
        .CYA  (CY_LA_terminal_chain1[32]  ),
        .CYB  (CY_LA_terminal_chain1[33]  ),
        .CYC  (CY_LA_terminal_chain1[34]  ),
        .CYD  (CY_LA_terminal_chain1[35]  ),
        .CYE  (CY_LA_terminal_chain1[36]  ),
        .CYF  (CY_LA_terminal_chain1[37]  ),
        .CYG  (CY_LA_terminal_chain1[38]  ),
        .CYH  (CY_LA_terminal_chain1[39]  ),
        .PROPA(PROP_LA_terminal_chain1[32]),
        .PROPB(PROP_LA_terminal_chain1[33]),
        .PROPC(PROP_LA_terminal_chain1[34]),
        .PROPD(PROP_LA_terminal_chain1[35]),
        .PROPE(PROP_LA_terminal_chain1[36]),
        .PROPF(PROP_LA_terminal_chain1[37]),
        .PROPG(PROP_LA_terminal_chain1[38]),
        .PROPH(PROP_LA_terminal_chain1[39]));

    LOOKAHEAD8 #(
        .LOOKB("TRUE"),
        .LOOKD("TRUE"),
        .LOOKF("TRUE"),
        .LOOKH("TRUE"))
    LOOKAHEAD8_terminal_chain1_inst5 (
        .COUTB(COUT_LA_terminal_chain1[20]),
        .COUTD(COUT_LA_terminal_chain1[21]),
        .COUTF(COUT_LA_terminal_chain1[22]),
        .COUTH(COUT_LA_terminal_chain1[23]),
        .CIN  (CIN_LA_terminal_chain1[5]  ),
        .CYA  (CY_LA_terminal_chain1[40]  ),
        .CYB  (CY_LA_terminal_chain1[41]  ),
        .CYC  (CY_LA_terminal_chain1[42]  ),
        .CYD  (CY_LA_terminal_chain1[43]  ),
        .CYE  (CY_LA_terminal_chain1[44]  ),
        .CYF  (CY_LA_terminal_chain1[45]  ),
        .CYG  (CY_LA_terminal_chain1[46]  ),
        .CYH  (CY_LA_terminal_chain1[47]  ),
        .PROPA(PROP_LA_terminal_chain1[40]),
        .PROPB(PROP_LA_terminal_chain1[41]),
        .PROPC(PROP_LA_terminal_chain1[42]),
        .PROPD(PROP_LA_terminal_chain1[43]),
        .PROPE(PROP_LA_terminal_chain1[44]),
        .PROPF(PROP_LA_terminal_chain1[45]),
        .PROPG(PROP_LA_terminal_chain1[46]),
        .PROPH(PROP_LA_terminal_chain1[47]));

    LOOKAHEAD8 #(
        .LOOKB("TRUE"),
        .LOOKD("TRUE"),
        .LOOKF("TRUE"),
        .LOOKH("TRUE"))
    LOOKAHEAD8_terminal_chain1_inst6 (
        .COUTB(COUT_LA_terminal_chain1[24]),
        .COUTD(COUT_LA_terminal_chain1[25]),
        .COUTF(COUT_LA_terminal_chain1[26]),
        .COUTH(COUT_LA_terminal_chain1[27]),
        .CIN  (CIN_LA_terminal_chain1[6]  ),
        .CYA  (CY_LA_terminal_chain1[48]  ),
        .CYB  (CY_LA_terminal_chain1[49]  ),
        .CYC  (CY_LA_terminal_chain1[50]  ),
        .CYD  (CY_LA_terminal_chain1[51]  ),
        .CYE  (CY_LA_terminal_chain1[52]  ),
        .CYF  (CY_LA_terminal_chain1[53]  ),
        .CYG  (CY_LA_terminal_chain1[54]  ),
        .CYH  (CY_LA_terminal_chain1[55]  ),
        .PROPA(PROP_LA_terminal_chain1[48]),
        .PROPB(PROP_LA_terminal_chain1[49]),
        .PROPC(PROP_LA_terminal_chain1[50]),
        .PROPD(PROP_LA_terminal_chain1[51]),
        .PROPE(PROP_LA_terminal_chain1[52]),
        .PROPF(PROP_LA_terminal_chain1[53]),
        .PROPG(PROP_LA_terminal_chain1[54]),
        .PROPH(PROP_LA_terminal_chain1[55]));

    LOOKAHEAD8 #(
        .LOOKB("TRUE"),
        .LOOKD("TRUE"),
        .LOOKF("TRUE"),
        .LOOKH("TRUE"))
    LOOKAHEAD8_terminal_chain1_inst7 (
        .COUTB(COUT_LA_terminal_chain1[28]),
        .COUTD(COUT_LA_terminal_chain1[29]),
        .COUTF(COUT_LA_terminal_chain1[30]),
        .COUTH(COUT_LA_terminal_chain1[31]),
        .CIN  (CIN_LA_terminal_chain1[7]  ),
        .CYA  (CY_LA_terminal_chain1[56]  ),
        .CYB  (CY_LA_terminal_chain1[57]  ),
        .CYC  (CY_LA_terminal_chain1[58]  ),
        .CYD  (CY_LA_terminal_chain1[59]  ),
        .CYE  (CY_LA_terminal_chain1[60]  ),
        .CYF  (CY_LA_terminal_chain1[61]  ),
        .CYG  (CY_LA_terminal_chain1[62]  ),
        .CYH  (CY_LA_terminal_chain1[63]  ),
        .PROPA(PROP_LA_terminal_chain1[56]),
        .PROPB(PROP_LA_terminal_chain1[57]),
        .PROPC(PROP_LA_terminal_chain1[58]),
        .PROPD(PROP_LA_terminal_chain1[59]),
        .PROPE(PROP_LA_terminal_chain1[60]),
        .PROPF(PROP_LA_terminal_chain1[61]),
        .PROPG(PROP_LA_terminal_chain1[62]),
        .PROPH(PROP_LA_terminal_chain1[63]));

    LOOKAHEAD8 #(
        .LOOKB("TRUE"),
        .LOOKD("TRUE"),
        .LOOKF("TRUE"),
        .LOOKH("TRUE"))
    LOOKAHEAD8_terminal_chain1_inst8 (
        .COUTB(COUT_LA_terminal_chain1[32]),
        .COUTD(COUT_LA_terminal_chain1[33]),
        .COUTF(COUT_LA_terminal_chain1[34]),
        .COUTH(COUT_LA_terminal_chain1[35]),
        .CIN  (CIN_LA_terminal_chain1[8]  ),
        .CYA  (CY_LA_terminal_chain1[64]  ),
        .CYB  (CY_LA_terminal_chain1[65]  ),
        .CYC  (CY_LA_terminal_chain1[66]  ),
        .CYD  (CY_LA_terminal_chain1[67]  ),
        .CYE  (CY_LA_terminal_chain1[68]  ),
        .CYF  (CY_LA_terminal_chain1[69]  ),
        .CYG  (CY_LA_terminal_chain1[70]  ),
        .CYH  (CY_LA_terminal_chain1[71]  ),
        .PROPA(PROP_LA_terminal_chain1[64]),
        .PROPB(PROP_LA_terminal_chain1[65]),
        .PROPC(PROP_LA_terminal_chain1[66]),
        .PROPD(PROP_LA_terminal_chain1[67]),
        .PROPE(PROP_LA_terminal_chain1[68]),
        .PROPF(PROP_LA_terminal_chain1[69]),
        .PROPG(PROP_LA_terminal_chain1[70]),
        .PROPH(PROP_LA_terminal_chain1[71]));

    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("TRUE" ),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i0(
        .clk (clk                         ),
        .C0  (C0_c3_2_terminal_chain1_i0  ),
        .O   (O_c3_2_terminal_chain1_i0   ),
        .CY  (CY_c3_2_terminal_chain1_i0  ),
        .PROP(PROP_c3_2_terminal_chain1_i0));
    
    assign C0_c3_2_terminal_chain1_i0 = {1'b0, layer1_col26[1], layer1_col26[0]};
    
    assign terminal_chain1_out = {O_c3_2_terminal_chain1_i55[1], O_c3_2_terminal_chain1_i55[0], O_c3_2_terminal_chain1_i54[0], O_c3_2_terminal_chain1_i53[0], O_c3_2_terminal_chain1_i52[0], O_c3_2_terminal_chain1_i51[0], O_c3_2_terminal_chain1_i50[0], O_c3_2_terminal_chain1_i49[0], O_c3_2_terminal_chain1_i48[0], O_c3_2_terminal_chain1_i47[0], O_c3_2_terminal_chain1_i46[0], O_c3_2_terminal_chain1_i45[0], O_c3_2_terminal_chain1_i44[0], O_c3_2_terminal_chain1_i43[0], O_c3_2_terminal_chain1_i42[0], O_c3_2_terminal_chain1_i41[0], O_c3_2_terminal_chain1_i40[0], O_c3_2_terminal_chain1_i39[0], O_c3_2_terminal_chain1_i38[0], O_c3_2_terminal_chain1_i37[0], O_c3_2_terminal_chain1_i36[0], O_c15_3_terminal_chain1_i35[1], O_c15_3_terminal_chain1_i35[0], O_c15_3_terminal_chain1_i34[1], O_c15_3_terminal_chain1_i34[0], O_c15_3_terminal_chain1_i33[1], O_c15_3_terminal_chain1_i33[0], O_c15_3_terminal_chain1_i32[1], O_c15_3_terminal_chain1_i32[0], O_c15_3_terminal_chain1_i31[1], O_c15_3_terminal_chain1_i31[0], O_c15_3_terminal_chain1_i30[1], O_c15_3_terminal_chain1_i30[0], O_c15_3_terminal_chain1_i29[1], O_c15_3_terminal_chain1_i29[0], O_c15_3_terminal_chain1_i28[1], O_c15_3_terminal_chain1_i28[0], O_c15_3_terminal_chain1_i27[1], O_c15_3_terminal_chain1_i27[0], O_c15_3_terminal_chain1_i26[1], O_c15_3_terminal_chain1_i26[0], O_c15_3_terminal_chain1_i25[1], O_c15_3_terminal_chain1_i25[0], O_c15_3_terminal_chain1_i24[1], O_c15_3_terminal_chain1_i24[0], O_c15_3_terminal_chain1_i23[1], O_c15_3_terminal_chain1_i23[0], O_c15_3_terminal_chain1_i22[1], O_c15_3_terminal_chain1_i22[0], O_c15_3_terminal_chain1_i21[1], O_c15_3_terminal_chain1_i21[0], O_c15_3_terminal_chain1_i20[1], O_c15_3_terminal_chain1_i20[0], O_c3_2_terminal_chain1_i19[0], O_c3_2_terminal_chain1_i18[0], O_c3_2_terminal_chain1_i17[0], O_c3_2_terminal_chain1_i16[0], O_c3_2_terminal_chain1_i15[0], O_c3_2_terminal_chain1_i14[0], O_c3_2_terminal_chain1_i13[0], O_c3_2_terminal_chain1_i12[0], O_c3_2_terminal_chain1_i11[0], O_c3_2_terminal_chain1_i10[0], O_c3_2_terminal_chain1_i9[0], O_c3_2_terminal_chain1_i8[0], O_c3_2_terminal_chain1_i7[0], O_c3_2_terminal_chain1_i6[0], O_c3_2_terminal_chain1_i5[0], O_c3_2_terminal_chain1_i4[0], O_c3_2_terminal_chain1_i3[0], O_c3_2_terminal_chain1_i2[0], O_c3_2_terminal_chain1_i1[0], O_c3_2_terminal_chain1_i0[0]};
    
    assign terminal_chain1_i0         = O_c3_2_terminal_chain1_i0[1];
    assign CY_LA_terminal_chain1 = {CY_c3_2_terminal_chain1_i55, CY_c3_2_terminal_chain1_i54, CY_c3_2_terminal_chain1_i53, CY_c3_2_terminal_chain1_i52, CY_c3_2_terminal_chain1_i51, CY_c3_2_terminal_chain1_i50, CY_c3_2_terminal_chain1_i49, CY_c3_2_terminal_chain1_i48, CY_c3_2_terminal_chain1_i47, CY_c3_2_terminal_chain1_i46, CY_c3_2_terminal_chain1_i45, CY_c3_2_terminal_chain1_i44, CY_c3_2_terminal_chain1_i43, CY_c3_2_terminal_chain1_i42, CY_c3_2_terminal_chain1_i41, CY_c3_2_terminal_chain1_i40, CY_c3_2_terminal_chain1_i39, CY_c3_2_terminal_chain1_i38, CY_c3_2_terminal_chain1_i37, CY_c3_2_terminal_chain1_i36, CY_c15_3_terminal_chain1_i35, CY_c15_3_terminal_chain1_i34, CY_c15_3_terminal_chain1_i33, CY_c15_3_terminal_chain1_i32, CY_c15_3_terminal_chain1_i31, CY_c15_3_terminal_chain1_i30, CY_c15_3_terminal_chain1_i29, CY_c15_3_terminal_chain1_i28, CY_c15_3_terminal_chain1_i27, CY_c15_3_terminal_chain1_i26, CY_c15_3_terminal_chain1_i25, CY_c15_3_terminal_chain1_i24, CY_c15_3_terminal_chain1_i23, CY_c15_3_terminal_chain1_i22, CY_c15_3_terminal_chain1_i21, CY_c15_3_terminal_chain1_i20, CY_c3_2_terminal_chain1_i19, CY_c3_2_terminal_chain1_i18, CY_c3_2_terminal_chain1_i17, CY_c3_2_terminal_chain1_i16, CY_c3_2_terminal_chain1_i15, CY_c3_2_terminal_chain1_i14, CY_c3_2_terminal_chain1_i13, CY_c3_2_terminal_chain1_i12, CY_c3_2_terminal_chain1_i11, CY_c3_2_terminal_chain1_i10, CY_c3_2_terminal_chain1_i9, CY_c3_2_terminal_chain1_i8, CY_c3_2_terminal_chain1_i7, CY_c3_2_terminal_chain1_i6, CY_c3_2_terminal_chain1_i5, CY_c3_2_terminal_chain1_i4, CY_c3_2_terminal_chain1_i3, CY_c3_2_terminal_chain1_i2, CY_c3_2_terminal_chain1_i1, CY_c3_2_terminal_chain1_i0};
    assign PROP_LA_terminal_chain1 = {PROP_c3_2_terminal_chain1_i55, PROP_c3_2_terminal_chain1_i54, PROP_c3_2_terminal_chain1_i53, PROP_c3_2_terminal_chain1_i52, PROP_c3_2_terminal_chain1_i51, PROP_c3_2_terminal_chain1_i50, PROP_c3_2_terminal_chain1_i49, PROP_c3_2_terminal_chain1_i48, PROP_c3_2_terminal_chain1_i47, PROP_c3_2_terminal_chain1_i46, PROP_c3_2_terminal_chain1_i45, PROP_c3_2_terminal_chain1_i44, PROP_c3_2_terminal_chain1_i43, PROP_c3_2_terminal_chain1_i42, PROP_c3_2_terminal_chain1_i41, PROP_c3_2_terminal_chain1_i40, PROP_c3_2_terminal_chain1_i39, PROP_c3_2_terminal_chain1_i38, PROP_c3_2_terminal_chain1_i37, PROP_c3_2_terminal_chain1_i36, PROP_c15_3_terminal_chain1_i35, PROP_c15_3_terminal_chain1_i34, PROP_c15_3_terminal_chain1_i33, PROP_c15_3_terminal_chain1_i32, PROP_c15_3_terminal_chain1_i31, PROP_c15_3_terminal_chain1_i30, PROP_c15_3_terminal_chain1_i29, PROP_c15_3_terminal_chain1_i28, PROP_c15_3_terminal_chain1_i27, PROP_c15_3_terminal_chain1_i26, PROP_c15_3_terminal_chain1_i25, PROP_c15_3_terminal_chain1_i24, PROP_c15_3_terminal_chain1_i23, PROP_c15_3_terminal_chain1_i22, PROP_c15_3_terminal_chain1_i21, PROP_c15_3_terminal_chain1_i20, PROP_c3_2_terminal_chain1_i19, PROP_c3_2_terminal_chain1_i18, PROP_c3_2_terminal_chain1_i17, PROP_c3_2_terminal_chain1_i16, PROP_c3_2_terminal_chain1_i15, PROP_c3_2_terminal_chain1_i14, PROP_c3_2_terminal_chain1_i13, PROP_c3_2_terminal_chain1_i12, PROP_c3_2_terminal_chain1_i11, PROP_c3_2_terminal_chain1_i10, PROP_c3_2_terminal_chain1_i9, PROP_c3_2_terminal_chain1_i8, PROP_c3_2_terminal_chain1_i7, PROP_c3_2_terminal_chain1_i6, PROP_c3_2_terminal_chain1_i5, PROP_c3_2_terminal_chain1_i4, PROP_c3_2_terminal_chain1_i3, PROP_c3_2_terminal_chain1_i2, PROP_c3_2_terminal_chain1_i1, PROP_c3_2_terminal_chain1_i0};
    
    assign CIN_LA_terminal_chain1 = {COUT_LA_terminal_chain1[31], COUT_LA_terminal_chain1[27], COUT_LA_terminal_chain1[23], COUT_LA_terminal_chain1[19], COUT_LA_terminal_chain1[15], COUT_LA_terminal_chain1[11], COUT_LA_terminal_chain1[7], COUT_LA_terminal_chain1[3], C0_c3_2_terminal_chain1_i0[2]};
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("TRUE" ),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i1(
        .clk (clk                         ),
        .C0  (C0_c3_2_terminal_chain1_i1  ),
        .O   (O_c3_2_terminal_chain1_i1   ),
        .CY  (CY_c3_2_terminal_chain1_i1  ),
        .PROP(PROP_c3_2_terminal_chain1_i1));
    
    assign C0_c3_2_terminal_chain1_i1 = {terminal_chain1_i0, layer1_col27[1], layer1_col27[0]};
    
    
    assign terminal_chain1_i1         = COUT_LA_terminal_chain1[0];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i2(
        .clk (clk                         ),
        .C0  (C0_c3_2_terminal_chain1_i2  ),
        .O   (O_c3_2_terminal_chain1_i2   ),
        .CY  (CY_c3_2_terminal_chain1_i2  ),
        .PROP(PROP_c3_2_terminal_chain1_i2));
    
    assign C0_c3_2_terminal_chain1_i2 = {terminal_chain1_i1, layer1_col28[1], layer1_col28[0]};
    
    
    assign terminal_chain1_i2         = O_c3_2_terminal_chain1_i2[1];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i3(
        .clk (clk                         ),
        .C0  (C0_c3_2_terminal_chain1_i3  ),
        .O   (O_c3_2_terminal_chain1_i3   ),
        .CY  (CY_c3_2_terminal_chain1_i3  ),
        .PROP(PROP_c3_2_terminal_chain1_i3));
    
    assign C0_c3_2_terminal_chain1_i3 = {terminal_chain1_i2, layer1_col29[1], layer1_col29[0]};
    
    
    assign terminal_chain1_i3         = COUT_LA_terminal_chain1[1];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i4(
        .clk (clk                         ),
        .C0  (C0_c3_2_terminal_chain1_i4  ),
        .O   (O_c3_2_terminal_chain1_i4   ),
        .CY  (CY_c3_2_terminal_chain1_i4  ),
        .PROP(PROP_c3_2_terminal_chain1_i4));
    
    assign C0_c3_2_terminal_chain1_i4 = {terminal_chain1_i3, layer1_col30[1], layer1_col30[0]};
    
    
    assign terminal_chain1_i4         = O_c3_2_terminal_chain1_i4[1];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i5(
        .clk (clk                         ),
        .C0  (C0_c3_2_terminal_chain1_i5  ),
        .O   (O_c3_2_terminal_chain1_i5   ),
        .CY  (CY_c3_2_terminal_chain1_i5  ),
        .PROP(PROP_c3_2_terminal_chain1_i5));
    
    assign C0_c3_2_terminal_chain1_i5 = {terminal_chain1_i4, layer1_col31[1], layer1_col31[0]};
    
    
    assign terminal_chain1_i5         = COUT_LA_terminal_chain1[2];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i6(
        .clk (clk                         ),
        .C0  (C0_c3_2_terminal_chain1_i6  ),
        .O   (O_c3_2_terminal_chain1_i6   ),
        .CY  (CY_c3_2_terminal_chain1_i6  ),
        .PROP(PROP_c3_2_terminal_chain1_i6));
    
    assign C0_c3_2_terminal_chain1_i6 = {terminal_chain1_i5, layer1_col32[1], layer1_col32[0]};
    
    
    assign terminal_chain1_i6         = O_c3_2_terminal_chain1_i6[1];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i7(
        .clk (clk                         ),
        .C0  (C0_c3_2_terminal_chain1_i7  ),
        .O   (O_c3_2_terminal_chain1_i7   ),
        .CY  (CY_c3_2_terminal_chain1_i7  ),
        .PROP(PROP_c3_2_terminal_chain1_i7));
    
    assign C0_c3_2_terminal_chain1_i7 = {terminal_chain1_i6, layer1_col33[1], layer1_col33[0]};
    
    
    assign terminal_chain1_i7         = COUT_LA_terminal_chain1[3];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i8(
        .clk (clk                         ),
        .C0  (C0_c3_2_terminal_chain1_i8  ),
        .O   (O_c3_2_terminal_chain1_i8   ),
        .CY  (CY_c3_2_terminal_chain1_i8  ),
        .PROP(PROP_c3_2_terminal_chain1_i8));
    
    assign C0_c3_2_terminal_chain1_i8 = {terminal_chain1_i7, layer1_col34[1], layer1_col34[0]};
    
    
    assign terminal_chain1_i8         = O_c3_2_terminal_chain1_i8[1];
    
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i9(
        .clk (clk                         ),
        .C0  (C0_c3_2_terminal_chain1_i9  ),
        .O   (O_c3_2_terminal_chain1_i9   ),
        .CY  (CY_c3_2_terminal_chain1_i9  ),
        .PROP(PROP_c3_2_terminal_chain1_i9));
    
    assign C0_c3_2_terminal_chain1_i9 = {terminal_chain1_i8, layer1_col35[1], layer1_col35[0]};
    
    
    assign terminal_chain1_i9         = COUT_LA_terminal_chain1[4];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i10(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i10  ),
        .O   (O_c3_2_terminal_chain1_i10   ),
        .CY  (CY_c3_2_terminal_chain1_i10  ),
        .PROP(PROP_c3_2_terminal_chain1_i10));
    
    assign C0_c3_2_terminal_chain1_i10 = {terminal_chain1_i9, layer1_col36[1], layer1_col36[0]};
    
    
    assign terminal_chain1_i10         = O_c3_2_terminal_chain1_i10[1];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i11(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i11  ),
        .O   (O_c3_2_terminal_chain1_i11   ),
        .CY  (CY_c3_2_terminal_chain1_i11  ),
        .PROP(PROP_c3_2_terminal_chain1_i11));
    
    assign C0_c3_2_terminal_chain1_i11 = {terminal_chain1_i10, layer1_col37[1], layer1_col37[0]};
    
    
    assign terminal_chain1_i11         = COUT_LA_terminal_chain1[5];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i12(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i12  ),
        .O   (O_c3_2_terminal_chain1_i12   ),
        .CY  (CY_c3_2_terminal_chain1_i12  ),
        .PROP(PROP_c3_2_terminal_chain1_i12));
    
    assign C0_c3_2_terminal_chain1_i12 = {terminal_chain1_i11, layer1_col38[1], layer1_col38[0]};
    
    
    assign terminal_chain1_i12         = O_c3_2_terminal_chain1_i12[1];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i13(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i13  ),
        .O   (O_c3_2_terminal_chain1_i13   ),
        .CY  (CY_c3_2_terminal_chain1_i13  ),
        .PROP(PROP_c3_2_terminal_chain1_i13));
    
    assign C0_c3_2_terminal_chain1_i13 = {terminal_chain1_i12, layer1_col39[1], layer1_col39[0]};
    
    
    assign terminal_chain1_i13         = COUT_LA_terminal_chain1[6];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i14(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i14  ),
        .O   (O_c3_2_terminal_chain1_i14   ),
        .CY  (CY_c3_2_terminal_chain1_i14  ),
        .PROP(PROP_c3_2_terminal_chain1_i14));
    
    assign C0_c3_2_terminal_chain1_i14 = {terminal_chain1_i13, layer1_col40[1], layer1_col40[0]};
    
    
    assign terminal_chain1_i14         = O_c3_2_terminal_chain1_i14[1];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i15(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i15  ),
        .O   (O_c3_2_terminal_chain1_i15   ),
        .CY  (CY_c3_2_terminal_chain1_i15  ),
        .PROP(PROP_c3_2_terminal_chain1_i15));
    
    assign C0_c3_2_terminal_chain1_i15 = {terminal_chain1_i14, layer1_col41[1], layer1_col41[0]};
    
    
    assign terminal_chain1_i15         = COUT_LA_terminal_chain1[7];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i16(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i16  ),
        .O   (O_c3_2_terminal_chain1_i16   ),
        .CY  (CY_c3_2_terminal_chain1_i16  ),
        .PROP(PROP_c3_2_terminal_chain1_i16));
    
    assign C0_c3_2_terminal_chain1_i16 = {terminal_chain1_i15, layer1_col42[1], layer1_col42[0]};
    
    
    assign terminal_chain1_i16         = O_c3_2_terminal_chain1_i16[1];
    
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i17(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i17  ),
        .O   (O_c3_2_terminal_chain1_i17   ),
        .CY  (CY_c3_2_terminal_chain1_i17  ),
        .PROP(PROP_c3_2_terminal_chain1_i17));
    
    assign C0_c3_2_terminal_chain1_i17 = {terminal_chain1_i16, layer1_col43[1], layer1_col43[0]};
    
    
    assign terminal_chain1_i17         = COUT_LA_terminal_chain1[8];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i18(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i18  ),
        .O   (O_c3_2_terminal_chain1_i18   ),
        .CY  (CY_c3_2_terminal_chain1_i18  ),
        .PROP(PROP_c3_2_terminal_chain1_i18));
    
    assign C0_c3_2_terminal_chain1_i18 = {terminal_chain1_i17, layer1_col44[1], layer1_col44[0]};
    
    
    assign terminal_chain1_i18         = O_c3_2_terminal_chain1_i18[1];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i19(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i19  ),
        .O   (O_c3_2_terminal_chain1_i19   ),
        .CY  (CY_c3_2_terminal_chain1_i19  ),
        .PROP(PROP_c3_2_terminal_chain1_i19));
    
    assign C0_c3_2_terminal_chain1_i19 = {terminal_chain1_i18, layer1_col45[1], layer1_col45[0]};
    
    
    assign terminal_chain1_i19         = COUT_LA_terminal_chain1[9];
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i20(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i20  ),
        .C1  (C1_c15_3_terminal_chain1_i20  ),
        .CLA (CLA_c15_3_terminal_chain1_i20 ),
        .O   (O_c15_3_terminal_chain1_i20   ),
        .CY  (CY_c15_3_terminal_chain1_i20  ),
        .PROP(PROP_c15_3_terminal_chain1_i20));
    
    assign C0_c15_3_terminal_chain1_i20 = {terminal_chain1_i19, layer1_col46[2], layer1_col46[1], layer1_col46[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i20    = layer1_col47[0];
    
    
    assign terminal_chain1_i20            = COUT_LA_terminal_chain1[10];
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i21(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i21  ),
        .C1  (C1_c15_3_terminal_chain1_i21  ),
        .CLA (CLA_c15_3_terminal_chain1_i21 ),
        .O   (O_c15_3_terminal_chain1_i21   ),
        .CY  (CY_c15_3_terminal_chain1_i21  ),
        .PROP(PROP_c15_3_terminal_chain1_i21));
    
    assign C0_c15_3_terminal_chain1_i21 = {terminal_chain1_i20, layer1_col48[2], layer1_col48[1], layer1_col48[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i21    = layer1_col49[0];
    
    
    assign terminal_chain1_i21            = COUT_LA_terminal_chain1[11];
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i22(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i22  ),
        .C1  (C1_c15_3_terminal_chain1_i22  ),
        .CLA (CLA_c15_3_terminal_chain1_i22 ),
        .O   (O_c15_3_terminal_chain1_i22   ),
        .CY  (CY_c15_3_terminal_chain1_i22  ),
        .PROP(PROP_c15_3_terminal_chain1_i22));
    
    assign C0_c15_3_terminal_chain1_i22 = {terminal_chain1_i21, layer1_col50[2], layer1_col50[1], layer1_col50[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i22    = layer1_col51[0];
    
    
    assign terminal_chain1_i22            = COUT_LA_terminal_chain1[12];
    
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i23(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i23  ),
        .C1  (C1_c15_3_terminal_chain1_i23  ),
        .CLA (CLA_c15_3_terminal_chain1_i23 ),
        .O   (O_c15_3_terminal_chain1_i23   ),
        .CY  (CY_c15_3_terminal_chain1_i23  ),
        .PROP(PROP_c15_3_terminal_chain1_i23));
    
    assign C0_c15_3_terminal_chain1_i23 = {terminal_chain1_i22, layer1_col52[2], layer1_col52[1], layer1_col52[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i23    = layer1_col53[0];
    
    
    assign terminal_chain1_i23            = COUT_LA_terminal_chain1[13];
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i24(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i24  ),
        .C1  (C1_c15_3_terminal_chain1_i24  ),
        .CLA (CLA_c15_3_terminal_chain1_i24 ),
        .O   (O_c15_3_terminal_chain1_i24   ),
        .CY  (CY_c15_3_terminal_chain1_i24  ),
        .PROP(PROP_c15_3_terminal_chain1_i24));
    
    assign C0_c15_3_terminal_chain1_i24 = {terminal_chain1_i23, layer1_col54[2], layer1_col54[1], layer1_col54[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i24    = layer1_col55[0];
    
    
    assign terminal_chain1_i24            = COUT_LA_terminal_chain1[14];
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i25(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i25  ),
        .C1  (C1_c15_3_terminal_chain1_i25  ),
        .CLA (CLA_c15_3_terminal_chain1_i25 ),
        .O   (O_c15_3_terminal_chain1_i25   ),
        .CY  (CY_c15_3_terminal_chain1_i25  ),
        .PROP(PROP_c15_3_terminal_chain1_i25));
    
    assign C0_c15_3_terminal_chain1_i25 = {terminal_chain1_i24, layer1_col56[2], layer1_col56[1], layer1_col56[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i25    = layer1_col57[0];
    
    
    assign terminal_chain1_i25            = COUT_LA_terminal_chain1[15];
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i26(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i26  ),
        .C1  (C1_c15_3_terminal_chain1_i26  ),
        .CLA (CLA_c15_3_terminal_chain1_i26 ),
        .O   (O_c15_3_terminal_chain1_i26   ),
        .CY  (CY_c15_3_terminal_chain1_i26  ),
        .PROP(PROP_c15_3_terminal_chain1_i26));
    
    assign C0_c15_3_terminal_chain1_i26 = {terminal_chain1_i25, layer1_col58[2], layer1_col58[1], layer1_col58[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i26    = layer1_col59[0];
    
    
    assign terminal_chain1_i26            = COUT_LA_terminal_chain1[16];
    
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i27(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i27  ),
        .C1  (C1_c15_3_terminal_chain1_i27  ),
        .CLA (CLA_c15_3_terminal_chain1_i27 ),
        .O   (O_c15_3_terminal_chain1_i27   ),
        .CY  (CY_c15_3_terminal_chain1_i27  ),
        .PROP(PROP_c15_3_terminal_chain1_i27));
    
    assign C0_c15_3_terminal_chain1_i27 = {terminal_chain1_i26, layer1_col60[2], layer1_col60[1], layer1_col60[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i27    = layer1_col61[0];
    
    
    assign terminal_chain1_i27            = COUT_LA_terminal_chain1[17];
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i28(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i28  ),
        .C1  (C1_c15_3_terminal_chain1_i28  ),
        .CLA (CLA_c15_3_terminal_chain1_i28 ),
        .O   (O_c15_3_terminal_chain1_i28   ),
        .CY  (CY_c15_3_terminal_chain1_i28  ),
        .PROP(PROP_c15_3_terminal_chain1_i28));
    
    assign C0_c15_3_terminal_chain1_i28 = {terminal_chain1_i27, layer1_col62[2], layer1_col62[1], layer1_col62[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i28    = layer1_col63[0];
    
    
    assign terminal_chain1_i28            = COUT_LA_terminal_chain1[18];
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i29(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i29  ),
        .C1  (C1_c15_3_terminal_chain1_i29  ),
        .CLA (CLA_c15_3_terminal_chain1_i29 ),
        .O   (O_c15_3_terminal_chain1_i29   ),
        .CY  (CY_c15_3_terminal_chain1_i29  ),
        .PROP(PROP_c15_3_terminal_chain1_i29));
    
    assign C0_c15_3_terminal_chain1_i29 = {terminal_chain1_i28, layer1_col64[2], layer1_col64[1], layer1_col64[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i29    = layer1_col65[0];
    
    
    assign terminal_chain1_i29            = COUT_LA_terminal_chain1[19];
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i30(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i30  ),
        .C1  (C1_c15_3_terminal_chain1_i30  ),
        .CLA (CLA_c15_3_terminal_chain1_i30 ),
        .O   (O_c15_3_terminal_chain1_i30   ),
        .CY  (CY_c15_3_terminal_chain1_i30  ),
        .PROP(PROP_c15_3_terminal_chain1_i30));
    
    assign C0_c15_3_terminal_chain1_i30 = {terminal_chain1_i29, layer1_col66[2], layer1_col66[1], layer1_col66[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i30    = layer1_col67[0];
    
    
    assign terminal_chain1_i30            = COUT_LA_terminal_chain1[20];
    
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i31(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i31  ),
        .C1  (C1_c15_3_terminal_chain1_i31  ),
        .CLA (CLA_c15_3_terminal_chain1_i31 ),
        .O   (O_c15_3_terminal_chain1_i31   ),
        .CY  (CY_c15_3_terminal_chain1_i31  ),
        .PROP(PROP_c15_3_terminal_chain1_i31));
    
    assign C0_c15_3_terminal_chain1_i31 = {terminal_chain1_i30, layer1_col68[2], layer1_col68[1], layer1_col68[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i31    = layer1_col69[0];
    
    
    assign terminal_chain1_i31            = COUT_LA_terminal_chain1[21];
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i32(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i32  ),
        .C1  (C1_c15_3_terminal_chain1_i32  ),
        .CLA (CLA_c15_3_terminal_chain1_i32 ),
        .O   (O_c15_3_terminal_chain1_i32   ),
        .CY  (CY_c15_3_terminal_chain1_i32  ),
        .PROP(PROP_c15_3_terminal_chain1_i32));
    
    assign C0_c15_3_terminal_chain1_i32 = {terminal_chain1_i31, layer1_col70[2], layer1_col70[1], layer1_col70[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i32    = layer1_col71[0];
    
    
    assign terminal_chain1_i32            = COUT_LA_terminal_chain1[22];
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i33(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i33  ),
        .C1  (C1_c15_3_terminal_chain1_i33  ),
        .CLA (CLA_c15_3_terminal_chain1_i33 ),
        .O   (O_c15_3_terminal_chain1_i33   ),
        .CY  (CY_c15_3_terminal_chain1_i33  ),
        .PROP(PROP_c15_3_terminal_chain1_i33));
    
    assign C0_c15_3_terminal_chain1_i33 = {terminal_chain1_i32, layer1_col72[2], layer1_col72[1], layer1_col72[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i33    = layer1_col73[0];
    
    
    assign terminal_chain1_i33            = COUT_LA_terminal_chain1[23];
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i34(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i34  ),
        .C1  (C1_c15_3_terminal_chain1_i34  ),
        .CLA (CLA_c15_3_terminal_chain1_i34 ),
        .O   (O_c15_3_terminal_chain1_i34   ),
        .CY  (CY_c15_3_terminal_chain1_i34  ),
        .PROP(PROP_c15_3_terminal_chain1_i34));
    
    assign C0_c15_3_terminal_chain1_i34 = {terminal_chain1_i33, layer1_col74[2], layer1_col74[1], layer1_col74[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i34    = layer1_col75[0];
    
    
    assign terminal_chain1_i34            = COUT_LA_terminal_chain1[24];
    
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i35(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i35  ),
        .C1  (C1_c15_3_terminal_chain1_i35  ),
        .CLA (CLA_c15_3_terminal_chain1_i35 ),
        .O   (O_c15_3_terminal_chain1_i35   ),
        .CY  (CY_c15_3_terminal_chain1_i35  ),
        .PROP(PROP_c15_3_terminal_chain1_i35));
    
    assign C0_c15_3_terminal_chain1_i35 = {terminal_chain1_i34, layer1_col76[2], layer1_col76[1], layer1_col76[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i35    = layer1_col77[0];
    
    
    assign terminal_chain1_i35            = COUT_LA_terminal_chain1[25];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i36(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i36  ),
        .O   (O_c3_2_terminal_chain1_i36   ),
        .CY  (CY_c3_2_terminal_chain1_i36  ),
        .PROP(PROP_c3_2_terminal_chain1_i36));
    
    assign C0_c3_2_terminal_chain1_i36 = {terminal_chain1_i35, layer1_col78[1], layer1_col78[0]};
    
    
    assign terminal_chain1_i36         = O_c3_2_terminal_chain1_i36[1];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i37(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i37  ),
        .O   (O_c3_2_terminal_chain1_i37   ),
        .CY  (CY_c3_2_terminal_chain1_i37  ),
        .PROP(PROP_c3_2_terminal_chain1_i37));
    
    assign C0_c3_2_terminal_chain1_i37 = {terminal_chain1_i36, layer1_col79[1], layer1_col79[0]};
    
    
    assign terminal_chain1_i37         = COUT_LA_terminal_chain1[26];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i38(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i38  ),
        .O   (O_c3_2_terminal_chain1_i38   ),
        .CY  (CY_c3_2_terminal_chain1_i38  ),
        .PROP(PROP_c3_2_terminal_chain1_i38));
    
    assign C0_c3_2_terminal_chain1_i38 = {terminal_chain1_i37, layer1_col80[1], layer1_col80[0]};
    
    
    assign terminal_chain1_i38         = O_c3_2_terminal_chain1_i38[1];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i39(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i39  ),
        .O   (O_c3_2_terminal_chain1_i39   ),
        .CY  (CY_c3_2_terminal_chain1_i39  ),
        .PROP(PROP_c3_2_terminal_chain1_i39));
    
    assign C0_c3_2_terminal_chain1_i39 = {terminal_chain1_i38, layer1_col81[1], layer1_col81[0]};
    
    
    assign terminal_chain1_i39         = COUT_LA_terminal_chain1[27];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i40(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i40  ),
        .O   (O_c3_2_terminal_chain1_i40   ),
        .CY  (CY_c3_2_terminal_chain1_i40  ),
        .PROP(PROP_c3_2_terminal_chain1_i40));
    
    assign C0_c3_2_terminal_chain1_i40 = {terminal_chain1_i39, layer1_col82[1], layer1_col82[0]};
    
    
    assign terminal_chain1_i40         = O_c3_2_terminal_chain1_i40[1];
    
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i41(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i41  ),
        .O   (O_c3_2_terminal_chain1_i41   ),
        .CY  (CY_c3_2_terminal_chain1_i41  ),
        .PROP(PROP_c3_2_terminal_chain1_i41));
    
    assign C0_c3_2_terminal_chain1_i41 = {terminal_chain1_i40, layer1_col83[1], layer1_col83[0]};
    
    
    assign terminal_chain1_i41         = COUT_LA_terminal_chain1[28];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i42(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i42  ),
        .O   (O_c3_2_terminal_chain1_i42   ),
        .CY  (CY_c3_2_terminal_chain1_i42  ),
        .PROP(PROP_c3_2_terminal_chain1_i42));
    
    assign C0_c3_2_terminal_chain1_i42 = {terminal_chain1_i41, layer1_col84[1], layer1_col84[0]};
    
    
    assign terminal_chain1_i42         = O_c3_2_terminal_chain1_i42[1];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i43(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i43  ),
        .O   (O_c3_2_terminal_chain1_i43   ),
        .CY  (CY_c3_2_terminal_chain1_i43  ),
        .PROP(PROP_c3_2_terminal_chain1_i43));
    
    assign C0_c3_2_terminal_chain1_i43 = {terminal_chain1_i42, layer1_col85[1], layer1_col85[0]};
    
    
    assign terminal_chain1_i43         = COUT_LA_terminal_chain1[29];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i44(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i44  ),
        .O   (O_c3_2_terminal_chain1_i44   ),
        .CY  (CY_c3_2_terminal_chain1_i44  ),
        .PROP(PROP_c3_2_terminal_chain1_i44));
    
    assign C0_c3_2_terminal_chain1_i44 = {terminal_chain1_i43, layer1_col86[1], layer1_col86[0]};
    
    
    assign terminal_chain1_i44         = O_c3_2_terminal_chain1_i44[1];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i45(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i45  ),
        .O   (O_c3_2_terminal_chain1_i45   ),
        .CY  (CY_c3_2_terminal_chain1_i45  ),
        .PROP(PROP_c3_2_terminal_chain1_i45));
    
    assign C0_c3_2_terminal_chain1_i45 = {terminal_chain1_i44, layer1_col87[1], layer1_col87[0]};
    
    
    assign terminal_chain1_i45         = COUT_LA_terminal_chain1[30];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i46(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i46  ),
        .O   (O_c3_2_terminal_chain1_i46   ),
        .CY  (CY_c3_2_terminal_chain1_i46  ),
        .PROP(PROP_c3_2_terminal_chain1_i46));
    
    assign C0_c3_2_terminal_chain1_i46 = {terminal_chain1_i45, layer1_col88[1], layer1_col88[0]};
    
    
    assign terminal_chain1_i46         = O_c3_2_terminal_chain1_i46[1];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i47(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i47  ),
        .O   (O_c3_2_terminal_chain1_i47   ),
        .CY  (CY_c3_2_terminal_chain1_i47  ),
        .PROP(PROP_c3_2_terminal_chain1_i47));
    
    assign C0_c3_2_terminal_chain1_i47 = {terminal_chain1_i46, layer1_col89[1], layer1_col89[0]};
    
    
    assign terminal_chain1_i47         = COUT_LA_terminal_chain1[31];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i48(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i48  ),
        .O   (O_c3_2_terminal_chain1_i48   ),
        .CY  (CY_c3_2_terminal_chain1_i48  ),
        .PROP(PROP_c3_2_terminal_chain1_i48));
    
    assign C0_c3_2_terminal_chain1_i48 = {terminal_chain1_i47, layer1_col90[1], layer1_col90[0]};
    
    
    assign terminal_chain1_i48         = O_c3_2_terminal_chain1_i48[1];
    
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i49(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i49  ),
        .O   (O_c3_2_terminal_chain1_i49   ),
        .CY  (CY_c3_2_terminal_chain1_i49  ),
        .PROP(PROP_c3_2_terminal_chain1_i49));
    
    assign C0_c3_2_terminal_chain1_i49 = {terminal_chain1_i48, layer1_col91[1], layer1_col91[0]};
    
    
    assign terminal_chain1_i49         = COUT_LA_terminal_chain1[32];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i50(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i50  ),
        .O   (O_c3_2_terminal_chain1_i50   ),
        .CY  (CY_c3_2_terminal_chain1_i50  ),
        .PROP(PROP_c3_2_terminal_chain1_i50));
    
    assign C0_c3_2_terminal_chain1_i50 = {terminal_chain1_i49, layer1_col92[1], layer1_col92[0]};
    
    
    assign terminal_chain1_i50         = O_c3_2_terminal_chain1_i50[1];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i51(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i51  ),
        .O   (O_c3_2_terminal_chain1_i51   ),
        .CY  (CY_c3_2_terminal_chain1_i51  ),
        .PROP(PROP_c3_2_terminal_chain1_i51));
    
    assign C0_c3_2_terminal_chain1_i51 = {terminal_chain1_i50, layer1_col93[1], layer1_col93[0]};
    
    
    assign terminal_chain1_i51         = COUT_LA_terminal_chain1[33];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i52(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i52  ),
        .O   (O_c3_2_terminal_chain1_i52   ),
        .CY  (CY_c3_2_terminal_chain1_i52  ),
        .PROP(PROP_c3_2_terminal_chain1_i52));
    
    assign C0_c3_2_terminal_chain1_i52 = {terminal_chain1_i51, layer1_col94[1], layer1_col94[0]};
    
    
    assign terminal_chain1_i52         = O_c3_2_terminal_chain1_i52[1];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i53(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i53  ),
        .O   (O_c3_2_terminal_chain1_i53   ),
        .CY  (CY_c3_2_terminal_chain1_i53  ),
        .PROP(PROP_c3_2_terminal_chain1_i53));
    
    assign C0_c3_2_terminal_chain1_i53 = {terminal_chain1_i52, layer1_col95[1], layer1_col95[0]};
    
    
    assign terminal_chain1_i53         = COUT_LA_terminal_chain1[34];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i54(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i54  ),
        .O   (O_c3_2_terminal_chain1_i54   ),
        .CY  (CY_c3_2_terminal_chain1_i54  ),
        .PROP(PROP_c3_2_terminal_chain1_i54));
    
    assign C0_c3_2_terminal_chain1_i54 = {terminal_chain1_i53, layer1_col96[1], layer1_col96[0]};
    
    
    assign terminal_chain1_i54         = O_c3_2_terminal_chain1_i54[1];
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("TRUE" ))
    c3_2_terminal_chain1_i55(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i55  ),
        .O   (O_c3_2_terminal_chain1_i55   ),
        .CY  (CY_c3_2_terminal_chain1_i55  ),
        .PROP(PROP_c3_2_terminal_chain1_i55));
    
    assign C0_c3_2_terminal_chain1_i55 = {terminal_chain1_i54, layer1_col97[1], layer1_col97[0]};
    
    
    assign terminal_chain1_i55         = COUT_LA_terminal_chain1[35];
    
    LOOKAHEAD8 #(
        .LOOKB("FALSE"),
        .LOOKD("TRUE" ),
        .LOOKF("TRUE" ),
        .LOOKH("TRUE" ))
    LOOKAHEAD8_terminal_chain2_inst0 (
        .COUTB(COUT_LA_terminal_chain2[0]),
        .COUTD(COUT_LA_terminal_chain2[1]),
        .COUTF(COUT_LA_terminal_chain2[2]),
        .COUTH(COUT_LA_terminal_chain2[3]),
        .CIN  (CIN_LA_terminal_chain2[0] ),
        .CYA  (CY_LA_terminal_chain2[0]  ),
        .CYB  (CY_LA_terminal_chain2[1]  ),
        .CYC  (CY_LA_terminal_chain2[2]  ),
        .CYD  (CY_LA_terminal_chain2[3]  ),
        .CYE  (CY_LA_terminal_chain2[4]  ),
        .CYF  (CY_LA_terminal_chain2[5]  ),
        .CYG  (CY_LA_terminal_chain2[6]  ),
        .CYH  (CY_LA_terminal_chain2[7]  ),
        .PROPA(PROP_LA_terminal_chain2[0]),
        .PROPB(PROP_LA_terminal_chain2[1]),
        .PROPC(PROP_LA_terminal_chain2[2]),
        .PROPD(PROP_LA_terminal_chain2[3]),
        .PROPE(PROP_LA_terminal_chain2[4]),
        .PROPF(PROP_LA_terminal_chain2[5]),
        .PROPG(PROP_LA_terminal_chain2[6]),
        .PROPH(PROP_LA_terminal_chain2[7]));

    LOOKAHEAD8 #(
        .LOOKB("TRUE"),
        .LOOKD("TRUE"),
        .LOOKF("TRUE"),
        .LOOKH("TRUE"))
    LOOKAHEAD8_terminal_chain2_inst1 (
        .COUTB(COUT_LA_terminal_chain2[4] ),
        .COUTD(COUT_LA_terminal_chain2[5] ),
        .COUTF(COUT_LA_terminal_chain2[6] ),
        .COUTH(COUT_LA_terminal_chain2[7] ),
        .CIN  (CIN_LA_terminal_chain2[1]  ),
        .CYA  (CY_LA_terminal_chain2[8]   ),
        .CYB  (CY_LA_terminal_chain2[9]   ),
        .CYC  (CY_LA_terminal_chain2[10]  ),
        .CYD  (CY_LA_terminal_chain2[11]  ),
        .CYE  (CY_LA_terminal_chain2[12]  ),
        .CYF  (CY_LA_terminal_chain2[13]  ),
        .CYG  (CY_LA_terminal_chain2[14]  ),
        .CYH  (CY_LA_terminal_chain2[15]  ),
        .PROPA(PROP_LA_terminal_chain2[8] ),
        .PROPB(PROP_LA_terminal_chain2[9] ),
        .PROPC(PROP_LA_terminal_chain2[10]),
        .PROPD(PROP_LA_terminal_chain2[11]),
        .PROPE(PROP_LA_terminal_chain2[12]),
        .PROPF(PROP_LA_terminal_chain2[13]),
        .PROPG(PROP_LA_terminal_chain2[14]),
        .PROPH(PROP_LA_terminal_chain2[15]));

    LOOKAHEAD8 #(
        .LOOKB("TRUE"),
        .LOOKD("TRUE"),
        .LOOKF("TRUE"),
        .LOOKH("TRUE"))
    LOOKAHEAD8_terminal_chain2_inst2 (
        .COUTB(COUT_LA_terminal_chain2[8] ),
        .COUTD(COUT_LA_terminal_chain2[9] ),
        .COUTF(COUT_LA_terminal_chain2[10]),
        .COUTH(COUT_LA_terminal_chain2[11]),
        .CIN  (CIN_LA_terminal_chain2[2]  ),
        .CYA  (CY_LA_terminal_chain2[16]  ),
        .CYB  (CY_LA_terminal_chain2[17]  ),
        .CYC  (CY_LA_terminal_chain2[18]  ),
        .CYD  (CY_LA_terminal_chain2[19]  ),
        .CYE  (CY_LA_terminal_chain2[20]  ),
        .CYF  (CY_LA_terminal_chain2[21]  ),
        .CYG  (CY_LA_terminal_chain2[22]  ),
        .CYH  (CY_LA_terminal_chain2[23]  ),
        .PROPA(PROP_LA_terminal_chain2[16]),
        .PROPB(PROP_LA_terminal_chain2[17]),
        .PROPC(PROP_LA_terminal_chain2[18]),
        .PROPD(PROP_LA_terminal_chain2[19]),
        .PROPE(PROP_LA_terminal_chain2[20]),
        .PROPF(PROP_LA_terminal_chain2[21]),
        .PROPG(PROP_LA_terminal_chain2[22]),
        .PROPH(PROP_LA_terminal_chain2[23]));

    LOOKAHEAD8 #(
        .LOOKB("TRUE"),
        .LOOKD("TRUE"),
        .LOOKF("TRUE"),
        .LOOKH("TRUE"))
    LOOKAHEAD8_terminal_chain2_inst3 (
        .COUTB(COUT_LA_terminal_chain2[12]),
        .COUTD(COUT_LA_terminal_chain2[13]),
        .COUTF(COUT_LA_terminal_chain2[14]),
        .COUTH(COUT_LA_terminal_chain2[15]),
        .CIN  (CIN_LA_terminal_chain2[3]  ),
        .CYA  (CY_LA_terminal_chain2[24]  ),
        .CYB  (CY_LA_terminal_chain2[25]  ),
        .CYC  (CY_LA_terminal_chain2[26]  ),
        .CYD  (CY_LA_terminal_chain2[27]  ),
        .CYE  (CY_LA_terminal_chain2[28]  ),
        .CYF  (CY_LA_terminal_chain2[29]  ),
        .CYG  (CY_LA_terminal_chain2[30]  ),
        .CYH  (CY_LA_terminal_chain2[31]  ),
        .PROPA(PROP_LA_terminal_chain2[24]),
        .PROPB(PROP_LA_terminal_chain2[25]),
        .PROPC(PROP_LA_terminal_chain2[26]),
        .PROPD(PROP_LA_terminal_chain2[27]),
        .PROPE(PROP_LA_terminal_chain2[28]),
        .PROPF(PROP_LA_terminal_chain2[29]),
        .PROPG(PROP_LA_terminal_chain2[30]),
        .PROPH(PROP_LA_terminal_chain2[31]));

    LOOKAHEAD8 #(
        .LOOKB("TRUE"),
        .LOOKD("TRUE"),
        .LOOKF("TRUE"),
        .LOOKH("TRUE"))
    LOOKAHEAD8_terminal_chain2_inst4 (
        .COUTB(COUT_LA_terminal_chain2[16]),
        .COUTD(COUT_LA_terminal_chain2[17]),
        .COUTF(COUT_LA_terminal_chain2[18]),
        .COUTH(COUT_LA_terminal_chain2[19]),
        .CIN  (CIN_LA_terminal_chain2[4]  ),
        .CYA  (CY_LA_terminal_chain2[32]  ),
        .CYB  (CY_LA_terminal_chain2[33]  ),
        .CYC  (CY_LA_terminal_chain2[34]  ),
        .CYD  (CY_LA_terminal_chain2[35]  ),
        .CYE  (CY_LA_terminal_chain2[36]  ),
        .CYF  (CY_LA_terminal_chain2[37]  ),
        .CYG  (CY_LA_terminal_chain2[38]  ),
        .CYH  (CY_LA_terminal_chain2[39]  ),
        .PROPA(PROP_LA_terminal_chain2[32]),
        .PROPB(PROP_LA_terminal_chain2[33]),
        .PROPC(PROP_LA_terminal_chain2[34]),
        .PROPD(PROP_LA_terminal_chain2[35]),
        .PROPE(PROP_LA_terminal_chain2[36]),
        .PROPF(PROP_LA_terminal_chain2[37]),
        .PROPG(PROP_LA_terminal_chain2[38]),
        .PROPH(PROP_LA_terminal_chain2[39]));

    LOOKAHEAD8 #(
        .LOOKB("TRUE"),
        .LOOKD("TRUE"),
        .LOOKF("TRUE"),
        .LOOKH("TRUE"))
    LOOKAHEAD8_terminal_chain2_inst5 (
        .COUTB(COUT_LA_terminal_chain2[20]),
        .COUTD(COUT_LA_terminal_chain2[21]),
        .COUTF(COUT_LA_terminal_chain2[22]),
        .COUTH(COUT_LA_terminal_chain2[23]),
        .CIN  (CIN_LA_terminal_chain2[5]  ),
        .CYA  (CY_LA_terminal_chain2[40]  ),
        .CYB  (CY_LA_terminal_chain2[41]  ),
        .CYC  (CY_LA_terminal_chain2[42]  ),
        .CYD  (CY_LA_terminal_chain2[43]  ),
        .CYE  (CY_LA_terminal_chain2[44]  ),
        .CYF  (CY_LA_terminal_chain2[45]  ),
        .CYG  (CY_LA_terminal_chain2[46]  ),
        .CYH  (CY_LA_terminal_chain2[47]  ),
        .PROPA(PROP_LA_terminal_chain2[40]),
        .PROPB(PROP_LA_terminal_chain2[41]),
        .PROPC(PROP_LA_terminal_chain2[42]),
        .PROPD(PROP_LA_terminal_chain2[43]),
        .PROPE(PROP_LA_terminal_chain2[44]),
        .PROPF(PROP_LA_terminal_chain2[45]),
        .PROPG(PROP_LA_terminal_chain2[46]),
        .PROPH(PROP_LA_terminal_chain2[47]));

    LOOKAHEAD8 #(
        .LOOKB("TRUE"),
        .LOOKD("TRUE"),
        .LOOKF("TRUE"),
        .LOOKH("TRUE"))
    LOOKAHEAD8_terminal_chain2_inst6 (
        .COUTB(COUT_LA_terminal_chain2[24]),
        .COUTD(COUT_LA_terminal_chain2[25]),
        .COUTF(COUT_LA_terminal_chain2[26]),
        .COUTH(COUT_LA_terminal_chain2[27]),
        .CIN  (CIN_LA_terminal_chain2[6]  ),
        .CYA  (CY_LA_terminal_chain2[48]  ),
        .CYB  (CY_LA_terminal_chain2[49]  ),
        .CYC  (CY_LA_terminal_chain2[50]  ),
        .CYD  (CY_LA_terminal_chain2[51]  ),
        .CYE  (CY_LA_terminal_chain2[52]  ),
        .CYF  (CY_LA_terminal_chain2[53]  ),
        .CYG  (CY_LA_terminal_chain2[54]  ),
        .CYH  (CY_LA_terminal_chain2[55]  ),
        .PROPA(PROP_LA_terminal_chain2[48]),
        .PROPB(PROP_LA_terminal_chain2[49]),
        .PROPC(PROP_LA_terminal_chain2[50]),
        .PROPD(PROP_LA_terminal_chain2[51]),
        .PROPE(PROP_LA_terminal_chain2[52]),
        .PROPF(PROP_LA_terminal_chain2[53]),
        .PROPG(PROP_LA_terminal_chain2[54]),
        .PROPH(PROP_LA_terminal_chain2[55]));

    LOOKAHEAD8 #(
        .LOOKB("TRUE"),
        .LOOKD("TRUE"),
        .LOOKF("TRUE"),
        .LOOKH("TRUE"))
    LOOKAHEAD8_terminal_chain2_inst7 (
        .COUTB(COUT_LA_terminal_chain2[28]),
        .COUTD(COUT_LA_terminal_chain2[29]),
        .COUTF(COUT_LA_terminal_chain2[30]),
        .COUTH(COUT_LA_terminal_chain2[31]),
        .CIN  (CIN_LA_terminal_chain2[7]  ),
        .CYA  (CY_LA_terminal_chain2[56]  ),
        .CYB  (CY_LA_terminal_chain2[57]  ),
        .CYC  (CY_LA_terminal_chain2[58]  ),
        .CYD  (CY_LA_terminal_chain2[59]  ),
        .CYE  (CY_LA_terminal_chain2[60]  ),
        .CYF  (CY_LA_terminal_chain2[61]  ),
        .CYG  (CY_LA_terminal_chain2[62]  ),
        .CYH  (CY_LA_terminal_chain2[63]  ),
        .PROPA(PROP_LA_terminal_chain2[56]),
        .PROPB(PROP_LA_terminal_chain2[57]),
        .PROPC(PROP_LA_terminal_chain2[58]),
        .PROPD(PROP_LA_terminal_chain2[59]),
        .PROPE(PROP_LA_terminal_chain2[60]),
        .PROPF(PROP_LA_terminal_chain2[61]),
        .PROPG(PROP_LA_terminal_chain2[62]),
        .PROPH(PROP_LA_terminal_chain2[63]));

    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("TRUE" ),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i0(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain2_i0  ),
        .C1  (C1_c15_3_terminal_chain2_i0  ),
        .CLA (CLA_c15_3_terminal_chain2_i0 ),
        .O   (O_c15_3_terminal_chain2_i0   ),
        .CY  (CY_c15_3_terminal_chain2_i0  ),
        .PROP(PROP_c15_3_terminal_chain2_i0));
    
    assign C0_c15_3_terminal_chain2_i0 = {1'b0, terminal_chain1_out[21], layer1_col47[2], layer1_col47[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i0    = terminal_chain1_out[22];
    
    assign terminal_chain2_out = {O_c3_2_terminal_chain2_i40[1], O_c3_2_terminal_chain2_i40[0], O_c3_2_terminal_chain2_i39[0], O_c3_2_terminal_chain2_i38[0], O_c3_2_terminal_chain2_i37[0], O_c3_2_terminal_chain2_i36[0], O_c3_2_terminal_chain2_i35[0], O_c3_2_terminal_chain2_i34[0], O_c3_2_terminal_chain2_i33[0], O_c3_2_terminal_chain2_i32[0], O_c3_2_terminal_chain2_i31[0], O_c3_2_terminal_chain2_i30[0], O_c3_2_terminal_chain2_i29[0], O_c3_2_terminal_chain2_i28[0], O_c3_2_terminal_chain2_i27[0], O_c3_2_terminal_chain2_i26[0], O_c3_2_terminal_chain2_i25[0], O_c3_2_terminal_chain2_i24[0], O_c3_2_terminal_chain2_i23[0], O_c3_2_terminal_chain2_i22[0], O_c3_2_terminal_chain2_i21[0], O_c3_2_terminal_chain2_i20[0], O_c3_2_terminal_chain2_i19[0], O_c3_2_terminal_chain2_i18[0], O_c3_2_terminal_chain2_i17[0], O_c3_2_terminal_chain2_i16[0], O_c15_3_terminal_chain2_i15[1], O_c15_3_terminal_chain2_i15[0], O_c15_3_terminal_chain2_i14[1], O_c15_3_terminal_chain2_i14[0], O_c15_3_terminal_chain2_i13[1], O_c15_3_terminal_chain2_i13[0], O_c15_3_terminal_chain2_i12[1], O_c15_3_terminal_chain2_i12[0], O_c15_3_terminal_chain2_i11[1], O_c15_3_terminal_chain2_i11[0], O_c15_3_terminal_chain2_i10[1], O_c15_3_terminal_chain2_i10[0], O_c15_3_terminal_chain2_i9[1], O_c15_3_terminal_chain2_i9[0], O_c15_3_terminal_chain2_i8[1], O_c15_3_terminal_chain2_i8[0], O_c15_3_terminal_chain2_i7[1], O_c15_3_terminal_chain2_i7[0], O_c15_3_terminal_chain2_i6[1], O_c15_3_terminal_chain2_i6[0], O_c15_3_terminal_chain2_i5[1], O_c15_3_terminal_chain2_i5[0], O_c15_3_terminal_chain2_i4[1], O_c15_3_terminal_chain2_i4[0], O_c15_3_terminal_chain2_i3[1], O_c15_3_terminal_chain2_i3[0], O_c15_3_terminal_chain2_i2[1], O_c15_3_terminal_chain2_i2[0], O_c15_3_terminal_chain2_i1[1], O_c15_3_terminal_chain2_i1[0], O_c15_3_terminal_chain2_i0[1], O_c15_3_terminal_chain2_i0[0]};
    
    assign terminal_chain2_i0           = COUT_LA_terminal_chain2[0];
    assign CY_LA_terminal_chain2[1:0]   = CY_c15_3_terminal_chain2_i0;
    assign PROP_LA_terminal_chain2[1:0] = PROP_c15_3_terminal_chain2_i0;
    
    assign CIN_LA_terminal_chain2 = {COUT_LA_terminal_chain2[27], COUT_LA_terminal_chain2[23], COUT_LA_terminal_chain2[19], COUT_LA_terminal_chain2[15], COUT_LA_terminal_chain2[11], COUT_LA_terminal_chain2[7], COUT_LA_terminal_chain2[3], C0_c15_3_terminal_chain2_i0[4]};
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i1(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain2_i1  ),
        .C1  (C1_c15_3_terminal_chain2_i1  ),
        .CLA (CLA_c15_3_terminal_chain2_i1 ),
        .O   (O_c15_3_terminal_chain2_i1   ),
        .CY  (CY_c15_3_terminal_chain2_i1  ),
        .PROP(PROP_c15_3_terminal_chain2_i1));
    
    assign C0_c15_3_terminal_chain2_i1 = {terminal_chain2_i0, terminal_chain1_out[23], layer1_col49[2], layer1_col49[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i1    = terminal_chain1_out[24];
    
    
    assign terminal_chain2_i1           = COUT_LA_terminal_chain2[1];
    assign CY_LA_terminal_chain2[3:2]   = CY_c15_3_terminal_chain2_i1;
    assign PROP_LA_terminal_chain2[3:2] = PROP_c15_3_terminal_chain2_i1;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i2(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain2_i2  ),
        .C1  (C1_c15_3_terminal_chain2_i2  ),
        .CLA (CLA_c15_3_terminal_chain2_i2 ),
        .O   (O_c15_3_terminal_chain2_i2   ),
        .CY  (CY_c15_3_terminal_chain2_i2  ),
        .PROP(PROP_c15_3_terminal_chain2_i2));
    
    assign C0_c15_3_terminal_chain2_i2 = {terminal_chain2_i1, terminal_chain1_out[25], layer1_col51[2], layer1_col51[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i2    = terminal_chain1_out[26];
    
    
    assign terminal_chain2_i2           = COUT_LA_terminal_chain2[2];
    assign CY_LA_terminal_chain2[5:4]   = CY_c15_3_terminal_chain2_i2;
    assign PROP_LA_terminal_chain2[5:4] = PROP_c15_3_terminal_chain2_i2;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i3(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain2_i3  ),
        .C1  (C1_c15_3_terminal_chain2_i3  ),
        .CLA (CLA_c15_3_terminal_chain2_i3 ),
        .O   (O_c15_3_terminal_chain2_i3   ),
        .CY  (CY_c15_3_terminal_chain2_i3  ),
        .PROP(PROP_c15_3_terminal_chain2_i3));
    
    assign C0_c15_3_terminal_chain2_i3 = {terminal_chain2_i2, terminal_chain1_out[27], layer1_col53[2], layer1_col53[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i3    = terminal_chain1_out[28];
    
    
    assign terminal_chain2_i3           = COUT_LA_terminal_chain2[3];
    assign CY_LA_terminal_chain2[7:6]   = CY_c15_3_terminal_chain2_i3;
    assign PROP_LA_terminal_chain2[7:6] = PROP_c15_3_terminal_chain2_i3;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i4(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain2_i4  ),
        .C1  (C1_c15_3_terminal_chain2_i4  ),
        .CLA (CLA_c15_3_terminal_chain2_i4 ),
        .O   (O_c15_3_terminal_chain2_i4   ),
        .CY  (CY_c15_3_terminal_chain2_i4  ),
        .PROP(PROP_c15_3_terminal_chain2_i4));
    
    assign C0_c15_3_terminal_chain2_i4 = {terminal_chain2_i3, terminal_chain1_out[29], layer1_col55[2], layer1_col55[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i4    = terminal_chain1_out[30];
    
    
    assign terminal_chain2_i4           = COUT_LA_terminal_chain2[4];
    assign CY_LA_terminal_chain2[9:8]   = CY_c15_3_terminal_chain2_i4;
    assign PROP_LA_terminal_chain2[9:8] = PROP_c15_3_terminal_chain2_i4;
    
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i5(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain2_i5  ),
        .C1  (C1_c15_3_terminal_chain2_i5  ),
        .CLA (CLA_c15_3_terminal_chain2_i5 ),
        .O   (O_c15_3_terminal_chain2_i5   ),
        .CY  (CY_c15_3_terminal_chain2_i5  ),
        .PROP(PROP_c15_3_terminal_chain2_i5));
    
    assign C0_c15_3_terminal_chain2_i5 = {terminal_chain2_i4, terminal_chain1_out[31], layer1_col57[2], layer1_col57[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i5    = terminal_chain1_out[32];
    
    
    assign terminal_chain2_i5             = COUT_LA_terminal_chain2[5];
    assign CY_LA_terminal_chain2[11:10]   = CY_c15_3_terminal_chain2_i5;
    assign PROP_LA_terminal_chain2[11:10] = PROP_c15_3_terminal_chain2_i5;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i6(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain2_i6  ),
        .C1  (C1_c15_3_terminal_chain2_i6  ),
        .CLA (CLA_c15_3_terminal_chain2_i6 ),
        .O   (O_c15_3_terminal_chain2_i6   ),
        .CY  (CY_c15_3_terminal_chain2_i6  ),
        .PROP(PROP_c15_3_terminal_chain2_i6));
    
    assign C0_c15_3_terminal_chain2_i6 = {terminal_chain2_i5, terminal_chain1_out[33], layer1_col59[2], layer1_col59[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i6    = terminal_chain1_out[34];
    
    
    assign terminal_chain2_i6             = COUT_LA_terminal_chain2[6];
    assign CY_LA_terminal_chain2[13:12]   = CY_c15_3_terminal_chain2_i6;
    assign PROP_LA_terminal_chain2[13:12] = PROP_c15_3_terminal_chain2_i6;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i7(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain2_i7  ),
        .C1  (C1_c15_3_terminal_chain2_i7  ),
        .CLA (CLA_c15_3_terminal_chain2_i7 ),
        .O   (O_c15_3_terminal_chain2_i7   ),
        .CY  (CY_c15_3_terminal_chain2_i7  ),
        .PROP(PROP_c15_3_terminal_chain2_i7));
    
    assign C0_c15_3_terminal_chain2_i7 = {terminal_chain2_i6, terminal_chain1_out[35], layer1_col61[2], layer1_col61[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i7    = terminal_chain1_out[36];
    
    
    assign terminal_chain2_i7             = COUT_LA_terminal_chain2[7];
    assign CY_LA_terminal_chain2[15:14]   = CY_c15_3_terminal_chain2_i7;
    assign PROP_LA_terminal_chain2[15:14] = PROP_c15_3_terminal_chain2_i7;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i8(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain2_i8  ),
        .C1  (C1_c15_3_terminal_chain2_i8  ),
        .CLA (CLA_c15_3_terminal_chain2_i8 ),
        .O   (O_c15_3_terminal_chain2_i8   ),
        .CY  (CY_c15_3_terminal_chain2_i8  ),
        .PROP(PROP_c15_3_terminal_chain2_i8));
    
    assign C0_c15_3_terminal_chain2_i8 = {terminal_chain2_i7, terminal_chain1_out[37], layer1_col63[2], layer1_col63[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i8    = terminal_chain1_out[38];
    
    
    assign terminal_chain2_i8             = COUT_LA_terminal_chain2[8];
    assign CY_LA_terminal_chain2[17:16]   = CY_c15_3_terminal_chain2_i8;
    assign PROP_LA_terminal_chain2[17:16] = PROP_c15_3_terminal_chain2_i8;
    
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i9(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain2_i9  ),
        .C1  (C1_c15_3_terminal_chain2_i9  ),
        .CLA (CLA_c15_3_terminal_chain2_i9 ),
        .O   (O_c15_3_terminal_chain2_i9   ),
        .CY  (CY_c15_3_terminal_chain2_i9  ),
        .PROP(PROP_c15_3_terminal_chain2_i9));
    
    assign C0_c15_3_terminal_chain2_i9 = {terminal_chain2_i8, terminal_chain1_out[39], layer1_col65[2], layer1_col65[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i9    = terminal_chain1_out[40];
    
    
    assign terminal_chain2_i9             = COUT_LA_terminal_chain2[9];
    assign CY_LA_terminal_chain2[19:18]   = CY_c15_3_terminal_chain2_i9;
    assign PROP_LA_terminal_chain2[19:18] = PROP_c15_3_terminal_chain2_i9;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i10(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain2_i10  ),
        .C1  (C1_c15_3_terminal_chain2_i10  ),
        .CLA (CLA_c15_3_terminal_chain2_i10 ),
        .O   (O_c15_3_terminal_chain2_i10   ),
        .CY  (CY_c15_3_terminal_chain2_i10  ),
        .PROP(PROP_c15_3_terminal_chain2_i10));
    
    assign C0_c15_3_terminal_chain2_i10 = {terminal_chain2_i9, terminal_chain1_out[41], layer1_col67[2], layer1_col67[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i10    = terminal_chain1_out[42];
    
    
    assign terminal_chain2_i10            = COUT_LA_terminal_chain2[10];
    assign CY_LA_terminal_chain2[21:20]   = CY_c15_3_terminal_chain2_i10;
    assign PROP_LA_terminal_chain2[21:20] = PROP_c15_3_terminal_chain2_i10;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i11(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain2_i11  ),
        .C1  (C1_c15_3_terminal_chain2_i11  ),
        .CLA (CLA_c15_3_terminal_chain2_i11 ),
        .O   (O_c15_3_terminal_chain2_i11   ),
        .CY  (CY_c15_3_terminal_chain2_i11  ),
        .PROP(PROP_c15_3_terminal_chain2_i11));
    
    assign C0_c15_3_terminal_chain2_i11 = {terminal_chain2_i10, terminal_chain1_out[43], layer1_col69[2], layer1_col69[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i11    = terminal_chain1_out[44];
    
    
    assign terminal_chain2_i11            = COUT_LA_terminal_chain2[11];
    assign CY_LA_terminal_chain2[23:22]   = CY_c15_3_terminal_chain2_i11;
    assign PROP_LA_terminal_chain2[23:22] = PROP_c15_3_terminal_chain2_i11;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i12(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain2_i12  ),
        .C1  (C1_c15_3_terminal_chain2_i12  ),
        .CLA (CLA_c15_3_terminal_chain2_i12 ),
        .O   (O_c15_3_terminal_chain2_i12   ),
        .CY  (CY_c15_3_terminal_chain2_i12  ),
        .PROP(PROP_c15_3_terminal_chain2_i12));
    
    assign C0_c15_3_terminal_chain2_i12 = {terminal_chain2_i11, terminal_chain1_out[45], layer1_col71[2], layer1_col71[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i12    = terminal_chain1_out[46];
    
    
    assign terminal_chain2_i12            = COUT_LA_terminal_chain2[12];
    assign CY_LA_terminal_chain2[25:24]   = CY_c15_3_terminal_chain2_i12;
    assign PROP_LA_terminal_chain2[25:24] = PROP_c15_3_terminal_chain2_i12;
    
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i13(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain2_i13  ),
        .C1  (C1_c15_3_terminal_chain2_i13  ),
        .CLA (CLA_c15_3_terminal_chain2_i13 ),
        .O   (O_c15_3_terminal_chain2_i13   ),
        .CY  (CY_c15_3_terminal_chain2_i13  ),
        .PROP(PROP_c15_3_terminal_chain2_i13));
    
    assign C0_c15_3_terminal_chain2_i13 = {terminal_chain2_i12, terminal_chain1_out[47], layer1_col73[2], layer1_col73[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i13    = terminal_chain1_out[48];
    
    
    assign terminal_chain2_i13            = COUT_LA_terminal_chain2[13];
    assign CY_LA_terminal_chain2[27:26]   = CY_c15_3_terminal_chain2_i13;
    assign PROP_LA_terminal_chain2[27:26] = PROP_c15_3_terminal_chain2_i13;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i14(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain2_i14  ),
        .C1  (C1_c15_3_terminal_chain2_i14  ),
        .CLA (CLA_c15_3_terminal_chain2_i14 ),
        .O   (O_c15_3_terminal_chain2_i14   ),
        .CY  (CY_c15_3_terminal_chain2_i14  ),
        .PROP(PROP_c15_3_terminal_chain2_i14));
    
    assign C0_c15_3_terminal_chain2_i14 = {terminal_chain2_i13, terminal_chain1_out[49], layer1_col75[2], layer1_col75[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i14    = terminal_chain1_out[50];
    
    
    assign terminal_chain2_i14            = COUT_LA_terminal_chain2[14];
    assign CY_LA_terminal_chain2[29:28]   = CY_c15_3_terminal_chain2_i14;
    assign PROP_LA_terminal_chain2[29:28] = PROP_c15_3_terminal_chain2_i14;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i15(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain2_i15  ),
        .C1  (C1_c15_3_terminal_chain2_i15  ),
        .CLA (CLA_c15_3_terminal_chain2_i15 ),
        .O   (O_c15_3_terminal_chain2_i15   ),
        .CY  (CY_c15_3_terminal_chain2_i15  ),
        .PROP(PROP_c15_3_terminal_chain2_i15));
    
    assign C0_c15_3_terminal_chain2_i15 = {terminal_chain2_i14, terminal_chain1_out[51], layer1_col77[2], layer1_col77[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i15    = terminal_chain1_out[52];
    
    
    assign terminal_chain2_i15            = COUT_LA_terminal_chain2[15];
    assign CY_LA_terminal_chain2[31:30]   = CY_c15_3_terminal_chain2_i15;
    assign PROP_LA_terminal_chain2[31:30] = PROP_c15_3_terminal_chain2_i15;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i16(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i16  ),
        .O   (O_c3_2_terminal_chain2_i16   ),
        .CY  (CY_c3_2_terminal_chain2_i16  ),
        .PROP(PROP_c3_2_terminal_chain2_i16));
    
    assign C0_c3_2_terminal_chain2_i16 = {terminal_chain2_i15, 1'b0, terminal_chain1_out[53]};
    
    
    assign terminal_chain2_i16         = O_c3_2_terminal_chain2_i16[1];
    assign CY_LA_terminal_chain2[32]   = CY_c3_2_terminal_chain2_i16;
    assign PROP_LA_terminal_chain2[32] = PROP_c3_2_terminal_chain2_i16;
    
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i17(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i17  ),
        .O   (O_c3_2_terminal_chain2_i17   ),
        .CY  (CY_c3_2_terminal_chain2_i17  ),
        .PROP(PROP_c3_2_terminal_chain2_i17));
    
    assign C0_c3_2_terminal_chain2_i17 = {terminal_chain2_i16, 1'b0, terminal_chain1_out[54]};
    
    
    assign terminal_chain2_i17         = COUT_LA_terminal_chain2[16];
    assign CY_LA_terminal_chain2[33]   = CY_c3_2_terminal_chain2_i17;
    assign PROP_LA_terminal_chain2[33] = PROP_c3_2_terminal_chain2_i17;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i18(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i18  ),
        .O   (O_c3_2_terminal_chain2_i18   ),
        .CY  (CY_c3_2_terminal_chain2_i18  ),
        .PROP(PROP_c3_2_terminal_chain2_i18));
    
    assign C0_c3_2_terminal_chain2_i18 = {terminal_chain2_i17, 1'b0, terminal_chain1_out[55]};
    
    
    assign terminal_chain2_i18         = O_c3_2_terminal_chain2_i18[1];
    assign CY_LA_terminal_chain2[34]   = CY_c3_2_terminal_chain2_i18;
    assign PROP_LA_terminal_chain2[34] = PROP_c3_2_terminal_chain2_i18;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i19(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i19  ),
        .O   (O_c3_2_terminal_chain2_i19   ),
        .CY  (CY_c3_2_terminal_chain2_i19  ),
        .PROP(PROP_c3_2_terminal_chain2_i19));
    
    assign C0_c3_2_terminal_chain2_i19 = {terminal_chain2_i18, 1'b0, terminal_chain1_out[56]};
    
    
    assign terminal_chain2_i19         = COUT_LA_terminal_chain2[17];
    assign CY_LA_terminal_chain2[35]   = CY_c3_2_terminal_chain2_i19;
    assign PROP_LA_terminal_chain2[35] = PROP_c3_2_terminal_chain2_i19;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i20(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i20  ),
        .O   (O_c3_2_terminal_chain2_i20   ),
        .CY  (CY_c3_2_terminal_chain2_i20  ),
        .PROP(PROP_c3_2_terminal_chain2_i20));
    
    assign C0_c3_2_terminal_chain2_i20 = {terminal_chain2_i19, 1'b0, terminal_chain1_out[57]};
    
    
    assign terminal_chain2_i20         = O_c3_2_terminal_chain2_i20[1];
    assign CY_LA_terminal_chain2[36]   = CY_c3_2_terminal_chain2_i20;
    assign PROP_LA_terminal_chain2[36] = PROP_c3_2_terminal_chain2_i20;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i21(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i21  ),
        .O   (O_c3_2_terminal_chain2_i21   ),
        .CY  (CY_c3_2_terminal_chain2_i21  ),
        .PROP(PROP_c3_2_terminal_chain2_i21));
    
    assign C0_c3_2_terminal_chain2_i21 = {terminal_chain2_i20, 1'b0, terminal_chain1_out[58]};
    
    
    assign terminal_chain2_i21         = COUT_LA_terminal_chain2[18];
    assign CY_LA_terminal_chain2[37]   = CY_c3_2_terminal_chain2_i21;
    assign PROP_LA_terminal_chain2[37] = PROP_c3_2_terminal_chain2_i21;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i22(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i22  ),
        .O   (O_c3_2_terminal_chain2_i22   ),
        .CY  (CY_c3_2_terminal_chain2_i22  ),
        .PROP(PROP_c3_2_terminal_chain2_i22));
    
    assign C0_c3_2_terminal_chain2_i22 = {terminal_chain2_i21, 1'b0, terminal_chain1_out[59]};
    
    
    assign terminal_chain2_i22         = O_c3_2_terminal_chain2_i22[1];
    assign CY_LA_terminal_chain2[38]   = CY_c3_2_terminal_chain2_i22;
    assign PROP_LA_terminal_chain2[38] = PROP_c3_2_terminal_chain2_i22;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i23(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i23  ),
        .O   (O_c3_2_terminal_chain2_i23   ),
        .CY  (CY_c3_2_terminal_chain2_i23  ),
        .PROP(PROP_c3_2_terminal_chain2_i23));
    
    assign C0_c3_2_terminal_chain2_i23 = {terminal_chain2_i22, 1'b0, terminal_chain1_out[60]};
    
    
    assign terminal_chain2_i23         = COUT_LA_terminal_chain2[19];
    assign CY_LA_terminal_chain2[39]   = CY_c3_2_terminal_chain2_i23;
    assign PROP_LA_terminal_chain2[39] = PROP_c3_2_terminal_chain2_i23;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i24(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i24  ),
        .O   (O_c3_2_terminal_chain2_i24   ),
        .CY  (CY_c3_2_terminal_chain2_i24  ),
        .PROP(PROP_c3_2_terminal_chain2_i24));
    
    assign C0_c3_2_terminal_chain2_i24 = {terminal_chain2_i23, 1'b0, terminal_chain1_out[61]};
    
    
    assign terminal_chain2_i24         = O_c3_2_terminal_chain2_i24[1];
    assign CY_LA_terminal_chain2[40]   = CY_c3_2_terminal_chain2_i24;
    assign PROP_LA_terminal_chain2[40] = PROP_c3_2_terminal_chain2_i24;
    
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i25(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i25  ),
        .O   (O_c3_2_terminal_chain2_i25   ),
        .CY  (CY_c3_2_terminal_chain2_i25  ),
        .PROP(PROP_c3_2_terminal_chain2_i25));
    
    assign C0_c3_2_terminal_chain2_i25 = {terminal_chain2_i24, 1'b0, terminal_chain1_out[62]};
    
    
    assign terminal_chain2_i25         = COUT_LA_terminal_chain2[20];
    assign CY_LA_terminal_chain2[41]   = CY_c3_2_terminal_chain2_i25;
    assign PROP_LA_terminal_chain2[41] = PROP_c3_2_terminal_chain2_i25;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i26(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i26  ),
        .O   (O_c3_2_terminal_chain2_i26   ),
        .CY  (CY_c3_2_terminal_chain2_i26  ),
        .PROP(PROP_c3_2_terminal_chain2_i26));
    
    assign C0_c3_2_terminal_chain2_i26 = {terminal_chain2_i25, 1'b0, terminal_chain1_out[63]};
    
    
    assign terminal_chain2_i26         = O_c3_2_terminal_chain2_i26[1];
    assign CY_LA_terminal_chain2[42]   = CY_c3_2_terminal_chain2_i26;
    assign PROP_LA_terminal_chain2[42] = PROP_c3_2_terminal_chain2_i26;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i27(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i27  ),
        .O   (O_c3_2_terminal_chain2_i27   ),
        .CY  (CY_c3_2_terminal_chain2_i27  ),
        .PROP(PROP_c3_2_terminal_chain2_i27));
    
    assign C0_c3_2_terminal_chain2_i27 = {terminal_chain2_i26, 1'b0, terminal_chain1_out[64]};
    
    
    assign terminal_chain2_i27         = COUT_LA_terminal_chain2[21];
    assign CY_LA_terminal_chain2[43]   = CY_c3_2_terminal_chain2_i27;
    assign PROP_LA_terminal_chain2[43] = PROP_c3_2_terminal_chain2_i27;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i28(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i28  ),
        .O   (O_c3_2_terminal_chain2_i28   ),
        .CY  (CY_c3_2_terminal_chain2_i28  ),
        .PROP(PROP_c3_2_terminal_chain2_i28));
    
    assign C0_c3_2_terminal_chain2_i28 = {terminal_chain2_i27, 1'b0, terminal_chain1_out[65]};
    
    
    assign terminal_chain2_i28         = O_c3_2_terminal_chain2_i28[1];
    assign CY_LA_terminal_chain2[44]   = CY_c3_2_terminal_chain2_i28;
    assign PROP_LA_terminal_chain2[44] = PROP_c3_2_terminal_chain2_i28;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i29(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i29  ),
        .O   (O_c3_2_terminal_chain2_i29   ),
        .CY  (CY_c3_2_terminal_chain2_i29  ),
        .PROP(PROP_c3_2_terminal_chain2_i29));
    
    assign C0_c3_2_terminal_chain2_i29 = {terminal_chain2_i28, 1'b0, terminal_chain1_out[66]};
    
    
    assign terminal_chain2_i29         = COUT_LA_terminal_chain2[22];
    assign CY_LA_terminal_chain2[45]   = CY_c3_2_terminal_chain2_i29;
    assign PROP_LA_terminal_chain2[45] = PROP_c3_2_terminal_chain2_i29;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i30(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i30  ),
        .O   (O_c3_2_terminal_chain2_i30   ),
        .CY  (CY_c3_2_terminal_chain2_i30  ),
        .PROP(PROP_c3_2_terminal_chain2_i30));
    
    assign C0_c3_2_terminal_chain2_i30 = {terminal_chain2_i29, 1'b0, terminal_chain1_out[67]};
    
    
    assign terminal_chain2_i30         = O_c3_2_terminal_chain2_i30[1];
    assign CY_LA_terminal_chain2[46]   = CY_c3_2_terminal_chain2_i30;
    assign PROP_LA_terminal_chain2[46] = PROP_c3_2_terminal_chain2_i30;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i31(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i31  ),
        .O   (O_c3_2_terminal_chain2_i31   ),
        .CY  (CY_c3_2_terminal_chain2_i31  ),
        .PROP(PROP_c3_2_terminal_chain2_i31));
    
    assign C0_c3_2_terminal_chain2_i31 = {terminal_chain2_i30, 1'b0, terminal_chain1_out[68]};
    
    
    assign terminal_chain2_i31         = COUT_LA_terminal_chain2[23];
    assign CY_LA_terminal_chain2[47]   = CY_c3_2_terminal_chain2_i31;
    assign PROP_LA_terminal_chain2[47] = PROP_c3_2_terminal_chain2_i31;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i32(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i32  ),
        .O   (O_c3_2_terminal_chain2_i32   ),
        .CY  (CY_c3_2_terminal_chain2_i32  ),
        .PROP(PROP_c3_2_terminal_chain2_i32));
    
    assign C0_c3_2_terminal_chain2_i32 = {terminal_chain2_i31, 1'b0, terminal_chain1_out[69]};
    
    
    assign terminal_chain2_i32         = O_c3_2_terminal_chain2_i32[1];
    assign CY_LA_terminal_chain2[48]   = CY_c3_2_terminal_chain2_i32;
    assign PROP_LA_terminal_chain2[48] = PROP_c3_2_terminal_chain2_i32;
    
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i33(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i33  ),
        .O   (O_c3_2_terminal_chain2_i33   ),
        .CY  (CY_c3_2_terminal_chain2_i33  ),
        .PROP(PROP_c3_2_terminal_chain2_i33));
    
    assign C0_c3_2_terminal_chain2_i33 = {terminal_chain2_i32, 1'b0, terminal_chain1_out[70]};
    
    
    assign terminal_chain2_i33         = COUT_LA_terminal_chain2[24];
    assign CY_LA_terminal_chain2[49]   = CY_c3_2_terminal_chain2_i33;
    assign PROP_LA_terminal_chain2[49] = PROP_c3_2_terminal_chain2_i33;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i34(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i34  ),
        .O   (O_c3_2_terminal_chain2_i34   ),
        .CY  (CY_c3_2_terminal_chain2_i34  ),
        .PROP(PROP_c3_2_terminal_chain2_i34));
    
    assign C0_c3_2_terminal_chain2_i34 = {terminal_chain2_i33, 1'b0, terminal_chain1_out[71]};
    
    
    assign terminal_chain2_i34         = O_c3_2_terminal_chain2_i34[1];
    assign CY_LA_terminal_chain2[50]   = CY_c3_2_terminal_chain2_i34;
    assign PROP_LA_terminal_chain2[50] = PROP_c3_2_terminal_chain2_i34;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i35(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i35  ),
        .O   (O_c3_2_terminal_chain2_i35   ),
        .CY  (CY_c3_2_terminal_chain2_i35  ),
        .PROP(PROP_c3_2_terminal_chain2_i35));
    
    assign C0_c3_2_terminal_chain2_i35 = {terminal_chain2_i34, layer1_col98, terminal_chain1_out[72]};
    
    
    assign terminal_chain2_i35         = COUT_LA_terminal_chain2[25];
    assign CY_LA_terminal_chain2[51]   = CY_c3_2_terminal_chain2_i35;
    assign PROP_LA_terminal_chain2[51] = PROP_c3_2_terminal_chain2_i35;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i36(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i36  ),
        .O   (O_c3_2_terminal_chain2_i36   ),
        .CY  (CY_c3_2_terminal_chain2_i36  ),
        .PROP(PROP_c3_2_terminal_chain2_i36));
    
    assign C0_c3_2_terminal_chain2_i36 = {terminal_chain2_i35, layer1_col99, 1'b0};
    
    
    assign terminal_chain2_i36         = O_c3_2_terminal_chain2_i36[1];
    assign CY_LA_terminal_chain2[52]   = CY_c3_2_terminal_chain2_i36;
    assign PROP_LA_terminal_chain2[52] = PROP_c3_2_terminal_chain2_i36;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i37(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i37  ),
        .O   (O_c3_2_terminal_chain2_i37   ),
        .CY  (CY_c3_2_terminal_chain2_i37  ),
        .PROP(PROP_c3_2_terminal_chain2_i37));
    
    assign C0_c3_2_terminal_chain2_i37 = {terminal_chain2_i36, layer1_col100, 1'b0};
    
    
    assign terminal_chain2_i37         = COUT_LA_terminal_chain2[26];
    assign CY_LA_terminal_chain2[53]   = CY_c3_2_terminal_chain2_i37;
    assign PROP_LA_terminal_chain2[53] = PROP_c3_2_terminal_chain2_i37;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i38(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i38  ),
        .O   (O_c3_2_terminal_chain2_i38   ),
        .CY  (CY_c3_2_terminal_chain2_i38  ),
        .PROP(PROP_c3_2_terminal_chain2_i38));
    
    assign C0_c3_2_terminal_chain2_i38 = {terminal_chain2_i37, layer1_col101, 1'b0};
    
    
    assign terminal_chain2_i38         = O_c3_2_terminal_chain2_i38[1];
    assign CY_LA_terminal_chain2[54]   = CY_c3_2_terminal_chain2_i38;
    assign PROP_LA_terminal_chain2[54] = PROP_c3_2_terminal_chain2_i38;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i39(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i39  ),
        .O   (O_c3_2_terminal_chain2_i39   ),
        .CY  (CY_c3_2_terminal_chain2_i39  ),
        .PROP(PROP_c3_2_terminal_chain2_i39));
    
    assign C0_c3_2_terminal_chain2_i39 = {terminal_chain2_i38, layer1_col102, 1'b0};
    
    
    assign terminal_chain2_i39         = COUT_LA_terminal_chain2[27];
    assign CY_LA_terminal_chain2[55]   = CY_c3_2_terminal_chain2_i39;
    assign PROP_LA_terminal_chain2[55] = PROP_c3_2_terminal_chain2_i39;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("TRUE" ))
    c3_2_terminal_chain2_i40(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i40  ),
        .O   (O_c3_2_terminal_chain2_i40   ),
        .CY  (CY_c3_2_terminal_chain2_i40  ),
        .PROP(PROP_c3_2_terminal_chain2_i40));
    
    assign C0_c3_2_terminal_chain2_i40 = {terminal_chain2_i39, layer1_col103, 1'b0};
    
    
    assign terminal_chain2_i40         = O_c3_2_terminal_chain2_i40[1];
    assign CY_LA_terminal_chain2[56]   = CY_c3_2_terminal_chain2_i40;
    assign PROP_LA_terminal_chain2[56] = PROP_c3_2_terminal_chain2_i40;
    
    
    always_ff @(posedge clk) begin
        comp_out[0] <= layer1_col0;
        comp_out[1] <= layer1_col1;
        comp_out[2] <= layer1_col2;
        comp_out[3] <= layer1_col3;
        comp_out[4] <= layer1_col4;
        comp_out[5] <= layer1_col5;
        comp_out[6] <= layer1_col6;
        comp_out[7] <= layer1_col7;
        comp_out[8] <= layer1_col8;
        comp_out[9] <= layer1_col9;
        comp_out[10] <= layer1_col10;
        comp_out[11] <= layer1_col11;
        comp_out[12] <= layer1_col12;
        comp_out[13] <= layer1_col13;
        comp_out[14] <= layer1_col14;
        comp_out[15] <= layer1_col15;
        comp_out[16] <= layer1_col16;
        comp_out[17] <= layer1_col17;
        comp_out[18] <= layer1_col18;
        comp_out[19] <= layer1_col19;
        comp_out[20] <= layer1_col20;
        comp_out[21] <= layer1_col21;
        comp_out[22] <= layer1_col22;
        comp_out[23] <= layer1_col23;
        comp_out[24] <= layer1_col24;
        comp_out[25] <= layer1_col25;
    
        comp_out[46:26] <= terminal_chain1_out[20:0];
    
        comp_out[104:47] <= terminal_chain2_out[57:0];
    end
    
    // -------------------------------------- ASSIGNMENT OF MODULE INPUTS AND COMPRESSOR INPUTS --------------------------------------
    assign layer0_col0    = in_col0;
    assign layer0_col1    = in_col1;
    assign layer0_col2    = in_col2;
    assign layer0_col3    = in_col3;
    assign layer0_col4    = in_col4;
    assign layer0_col5    = in_col5;
    assign layer0_col6    = in_col6;
    assign layer0_col7    = in_col7;
    assign layer0_col8    = in_col8;
    assign layer0_col9    = in_col9;
    assign layer0_col10   = in_col10;
    assign layer0_col11   = in_col11;
    assign layer0_col12   = in_col12;
    assign layer0_col13   = in_col13;
    assign layer0_col14   = in_col14;
    assign layer0_col15   = in_col15;
    assign layer0_col16   = in_col16;
    assign layer0_col17   = in_col17;
    assign layer0_col18   = in_col18;
    assign layer0_col19   = in_col19;
    assign layer0_col20   = in_col20;
    assign layer0_col21   = in_col21;
    assign layer0_col22   = in_col22;
    assign layer0_col23   = in_col23;
    assign layer0_col24   = in_col24;
    assign layer0_col25   = in_col25;
    assign layer0_col26   = in_col26;
    assign layer0_col27   = in_col27;
    assign layer0_col28   = in_col28;
    assign layer0_col29   = in_col29;
    assign layer0_col30   = in_col30;
    assign layer0_col31   = in_col31;
    assign layer0_col32   = in_col32;
    assign layer0_col33   = in_col33;
    assign layer0_col34   = in_col34;
    assign layer0_col35   = in_col35;
    assign layer0_col36   = in_col36;
    assign layer0_col37   = in_col37;
    assign layer0_col38   = in_col38;
    assign layer0_col39   = in_col39;
    assign layer0_col40   = in_col40;
    assign layer0_col41   = in_col41;
    assign layer0_col42   = in_col42;
    assign layer0_col43   = in_col43;
    assign layer0_col44   = in_col44;
    assign layer0_col45   = in_col45;
    assign layer0_col46   = in_col46;
    assign layer0_col47   = in_col47;
    assign layer0_col48   = in_col48;
    assign layer0_col49   = in_col49;
    assign layer0_col50   = in_col50;
    assign layer0_col51   = in_col51;
    assign layer0_col52   = in_col52;
    assign layer0_col53   = in_col53;
    assign layer0_col54   = in_col54;
    assign layer0_col55   = in_col55;
    assign layer0_col56   = in_col56;
    assign layer0_col57   = in_col57;
    assign layer0_col58   = in_col58;
    assign layer0_col59   = in_col59;
    assign layer0_col60   = in_col60;
    assign layer0_col61   = in_col61;
    assign layer0_col62   = in_col62;
    assign layer0_col63   = in_col63;
    assign layer0_col64   = in_col64;
    assign layer0_col65   = in_col65;
    assign layer0_col66   = in_col66;
    assign layer0_col67   = in_col67;
    assign layer0_col68   = in_col68;
    assign layer0_col69   = in_col69;
    assign layer0_col70   = in_col70;
    assign layer0_col71   = in_col71;
    assign layer0_col72   = in_col72;
    assign layer0_col73   = in_col73;
    assign layer0_col74   = in_col74;
    assign layer0_col75   = in_col75;
    assign layer0_col76   = in_col76;
    assign layer0_col77   = in_col77;
    assign layer0_col78   = in_col78;
    assign layer0_col79   = in_col79;
    assign layer0_col80   = in_col80;
    assign layer0_col81   = in_col81;
    assign layer0_col82   = in_col82;
    assign layer0_col83   = in_col83;
    assign layer0_col84   = in_col84;
    assign layer0_col85   = in_col85;
    assign layer0_col86   = in_col86;
    assign layer0_col87   = in_col87;
    assign layer0_col88   = in_col88;
    assign layer0_col89   = in_col89;
    assign layer0_col90   = in_col90;
    assign layer0_col91   = in_col91;
    assign layer0_col92   = in_col92;
    assign layer0_col93   = in_col93;
    assign layer0_col94   = in_col94;
    assign layer0_col95   = in_col95;
    assign layer0_col96   = in_col96;
    assign layer0_col97   = in_col97;
    assign layer0_col98   = in_col98;
    assign layer0_col99   = in_col99;
    assign layer0_col100  = in_col100;
    assign layer0_col101  = in_col101;
    assign layer0_col102  = in_col102;
    assign layer0_col103  = in_col103;
    
endmodule