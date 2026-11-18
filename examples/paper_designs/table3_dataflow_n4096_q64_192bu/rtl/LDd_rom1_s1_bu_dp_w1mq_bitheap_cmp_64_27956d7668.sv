`timescale 1ns / 1ps

module LDd_rom1_s1_bu_dp_w1mq_bitheap_cmp_64_27956d7668 (
    input  logic          clk,
    input  logic          in_col0,
    input  logic          in_col1,
    input  logic          in_col2,
    input  logic          in_col3,
    input  logic          in_col4,
    input  logic          in_col5,
    input  logic          in_col6,
    input  logic          in_col7,
    input  logic          in_col8,
    input  logic          in_col9,
    input  logic          in_col10,
    input  logic          in_col11,
    input  logic          in_col12,
    input  logic          in_col13,
    input  logic          in_col14,
    input  logic          in_col15,
    input  logic          in_col16,
    input  logic          in_col17,
    input  logic          in_col18,
    input  logic          in_col19,
    input  logic          in_col20,
    input  logic          in_col21,
    input  logic          in_col22,
    input  logic [1  : 0] in_col23,
    input  logic [1  : 0] in_col24,
    input  logic [1  : 0] in_col25,
    input  logic [2  : 0] in_col26,
    input  logic [2  : 0] in_col27,
    input  logic [2  : 0] in_col28,
    input  logic [2  : 0] in_col29,
    input  logic [2  : 0] in_col30,
    input  logic [2  : 0] in_col31,
    input  logic [2  : 0] in_col32,
    input  logic [2  : 0] in_col33,
    input  logic [2  : 0] in_col34,
    input  logic [2  : 0] in_col35,
    input  logic [2  : 0] in_col36,
    input  logic [2  : 0] in_col37,
    input  logic [2  : 0] in_col38,
    input  logic [2  : 0] in_col39,
    input  logic [2  : 0] in_col40,
    input  logic [2  : 0] in_col41,
    input  logic [2  : 0] in_col42,
    input  logic [2  : 0] in_col43,
    input  logic [2  : 0] in_col44,
    input  logic [2  : 0] in_col45,
    input  logic [2  : 0] in_col46,
    input  logic [2  : 0] in_col47,
    input  logic [2  : 0] in_col48,
    input  logic [1  : 0] in_col49,
    input  logic [1  : 0] in_col50,
    input  logic [1  : 0] in_col51,
    input  logic [3  : 0] in_col52,
    input  logic [2  : 0] in_col53,
    input  logic [4  : 0] in_col54,
    input  logic [3  : 0] in_col55,
    input  logic [5  : 0] in_col56,
    input  logic [4  : 0] in_col57,
    input  logic [4  : 0] in_col58,
    input  logic [4  : 0] in_col59,
    input  logic [3  : 0] in_col60,
    input  logic [2  : 0] in_col61,
    input  logic [2  : 0] in_col62,
    input  logic [1  : 0] in_col63,
    output logic [65 : 0] comp_out
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
    logic [1  : 0] layer0_col23;
    logic [1  : 0] layer0_col24;
    logic [1  : 0] layer0_col25;
    logic [2  : 0] layer0_col26;
    logic [2  : 0] layer0_col27;
    logic [2  : 0] layer0_col28;
    logic [2  : 0] layer0_col29;
    logic [2  : 0] layer0_col30;
    logic [2  : 0] layer0_col31;
    logic [2  : 0] layer0_col32;
    logic [2  : 0] layer0_col33;
    logic [2  : 0] layer0_col34;
    logic [2  : 0] layer0_col35;
    logic [2  : 0] layer0_col36;
    logic [2  : 0] layer0_col37;
    logic [2  : 0] layer0_col38;
    logic [2  : 0] layer0_col39;
    logic [2  : 0] layer0_col40;
    logic [2  : 0] layer0_col41;
    logic [2  : 0] layer0_col42;
    logic [2  : 0] layer0_col43;
    logic [2  : 0] layer0_col44;
    logic [2  : 0] layer0_col45;
    logic [2  : 0] layer0_col46;
    logic [2  : 0] layer0_col47;
    logic [2  : 0] layer0_col48;
    logic [1  : 0] layer0_col49;
    logic [1  : 0] layer0_col50;
    logic [1  : 0] layer0_col51;
    logic [3  : 0] layer0_col52;
    logic [2  : 0] layer0_col53;
    logic [4  : 0] layer0_col54;
    logic [3  : 0] layer0_col55;
    logic [5  : 0] layer0_col56;
    logic [4  : 0] layer0_col57;
    logic [4  : 0] layer0_col58;
    logic [4  : 0] layer0_col59;
    logic [3  : 0] layer0_col60;
    logic [2  : 0] layer0_col61;
    logic [2  : 0] layer0_col62;
    logic [1  : 0] layer0_col63;
    
    logic [3 : 0] COUT_LA_l0_c0_s0;
    logic         CIN_LA_l0_c0_s0;
    logic [7 : 0] CY_LA_l0_c0_s0;
    logic [7 : 0] PROP_LA_l0_c0_s0;
    
    (* dont_touch = "true" *) logic [2 : 0] C0_c3_2_l0_c0_i0;
    logic [1 : 0] O_c3_2_l0_c0_i0;
    logic         CY_c3_2_l0_c0_i0;
    logic         PROP_c3_2_l0_c0_i0;
    logic         l0_c0_i0;
    
    logic [2 : 0] C0_c3_2_l0_c0_i1;
    logic [1 : 0] O_c3_2_l0_c0_i1;
    logic         CY_c3_2_l0_c0_i1;
    logic         PROP_c3_2_l0_c0_i1;
    logic         l0_c0_i1;
    
    logic [4 : 0] C0_c15_3_l0_c0_i2;
    logic         C1_c15_3_l0_c0_i2;
    logic         CLA_c15_3_l0_c0_i2;
    logic [2 : 0] O_c15_3_l0_c0_i2;
    logic [1 : 0] CY_c15_3_l0_c0_i2;
    logic [1 : 0] PROP_c15_3_l0_c0_i2;
    logic         l0_c0_i2;
    
    logic [2 : 0] C0_c3_2_l0_c0_i3;
    logic [1 : 0] O_c3_2_l0_c0_i3;
    logic         CY_c3_2_l0_c0_i3;
    logic         PROP_c3_2_l0_c0_i3;
    logic         l0_c0_i3;
    
    logic [2 : 0] C0_c3_2_l0_c0_i4;
    logic [1 : 0] O_c3_2_l0_c0_i4;
    logic         CY_c3_2_l0_c0_i4;
    logic         PROP_c3_2_l0_c0_i4;
    logic         l0_c0_i4;
    
    logic [2 : 0] C0_c3_2_l0_c0_i5;
    logic [1 : 0] O_c3_2_l0_c0_i5;
    logic         CY_c3_2_l0_c0_i5;
    logic         PROP_c3_2_l0_c0_i5;
    logic         l0_c0_i5;
    
    (* dont_touch = "true" *) logic [2 : 0] C0_c223_4_l0_f0;
    logic [1 : 0] C1_c223_4_l0_f0;
    logic [1 : 0] C2_c223_4_l0_f0;
    logic         CLA_c223_4_l0_f0;
    logic [3 : 0] O_c223_4_l0_f0;
    logic [1 : 0] CY_c223_4_l0_f0;
    logic [1 : 0] PROP_c223_4_l0_f0;
    
    logic [3 : 0] COUT_LA_l0_floating_placement;
    logic         CIN_LA_l0_floating_placement;
    logic [7 : 0] CY_LA_l0_floating_placement;
    logic [7 : 0] PROP_LA_l0_floating_placement;
    
    
    
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
    logic [1  : 0] layer1_col23;
    logic [1  : 0] layer1_col24;
    logic [1  : 0] layer1_col25;
    logic [2  : 0] layer1_col26;
    logic [2  : 0] layer1_col27;
    logic [2  : 0] layer1_col28;
    logic [2  : 0] layer1_col29;
    logic [2  : 0] layer1_col30;
    logic [2  : 0] layer1_col31;
    logic [2  : 0] layer1_col32;
    logic [2  : 0] layer1_col33;
    logic [2  : 0] layer1_col34;
    logic [2  : 0] layer1_col35;
    logic [2  : 0] layer1_col36;
    logic [2  : 0] layer1_col37;
    logic [2  : 0] layer1_col38;
    logic [2  : 0] layer1_col39;
    logic [2  : 0] layer1_col40;
    logic [2  : 0] layer1_col41;
    logic [2  : 0] layer1_col42;
    logic [2  : 0] layer1_col43;
    logic [2  : 0] layer1_col44;
    logic [2  : 0] layer1_col45;
    logic [2  : 0] layer1_col46;
    logic [2  : 0] layer1_col47;
    logic [2  : 0] layer1_col48;
    logic [1  : 0] layer1_col49;
    logic [1  : 0] layer1_col50;
    logic [1  : 0] layer1_col51;
    logic [3  : 0] layer1_col52;
    logic [2  : 0] layer1_col53;
    logic [2  : 0] layer1_col54;
    logic [2  : 0] layer1_col55;
    logic [2  : 0] layer1_col56;
    logic [2  : 0] layer1_col57;
    logic [2  : 0] layer1_col58;
    logic [2  : 0] layer1_col59;
    logic [3  : 0] layer1_col60;
    logic [3  : 0] layer1_col61;
    logic [2  : 0] layer1_col62;
    logic [1  : 0] layer1_col63;
    
    logic [37 : 0] terminal_chain1_out;
    
    logic [19 : 0] COUT_LA_terminal_chain1;
    logic [4  : 0] CIN_LA_terminal_chain1;
    logic [39 : 0] CY_LA_terminal_chain1;
    logic [39 : 0] PROP_LA_terminal_chain1;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i0;
    logic         C1_c15_3_terminal_chain1_i0;
    logic         CLA_c15_3_terminal_chain1_i0;
    logic [2 : 0] O_c15_3_terminal_chain1_i0;
    logic [1 : 0] CY_c15_3_terminal_chain1_i0;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i0;
    logic         terminal_chain1_i0;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i1;
    logic         C1_c15_3_terminal_chain1_i1;
    logic         CLA_c15_3_terminal_chain1_i1;
    logic [2 : 0] O_c15_3_terminal_chain1_i1;
    logic [1 : 0] CY_c15_3_terminal_chain1_i1;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i1;
    logic         terminal_chain1_i1;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i2;
    logic         C1_c15_3_terminal_chain1_i2;
    logic         CLA_c15_3_terminal_chain1_i2;
    logic [2 : 0] O_c15_3_terminal_chain1_i2;
    logic [1 : 0] CY_c15_3_terminal_chain1_i2;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i2;
    logic         terminal_chain1_i2;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i3;
    logic         C1_c15_3_terminal_chain1_i3;
    logic         CLA_c15_3_terminal_chain1_i3;
    logic [2 : 0] O_c15_3_terminal_chain1_i3;
    logic [1 : 0] CY_c15_3_terminal_chain1_i3;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i3;
    logic         terminal_chain1_i3;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i4;
    logic         C1_c15_3_terminal_chain1_i4;
    logic         CLA_c15_3_terminal_chain1_i4;
    logic [2 : 0] O_c15_3_terminal_chain1_i4;
    logic [1 : 0] CY_c15_3_terminal_chain1_i4;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i4;
    logic         terminal_chain1_i4;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i5;
    logic         C1_c15_3_terminal_chain1_i5;
    logic         CLA_c15_3_terminal_chain1_i5;
    logic [2 : 0] O_c15_3_terminal_chain1_i5;
    logic [1 : 0] CY_c15_3_terminal_chain1_i5;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i5;
    logic         terminal_chain1_i5;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i6;
    logic         C1_c15_3_terminal_chain1_i6;
    logic         CLA_c15_3_terminal_chain1_i6;
    logic [2 : 0] O_c15_3_terminal_chain1_i6;
    logic [1 : 0] CY_c15_3_terminal_chain1_i6;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i6;
    logic         terminal_chain1_i6;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i7;
    logic         C1_c15_3_terminal_chain1_i7;
    logic         CLA_c15_3_terminal_chain1_i7;
    logic [2 : 0] O_c15_3_terminal_chain1_i7;
    logic [1 : 0] CY_c15_3_terminal_chain1_i7;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i7;
    logic         terminal_chain1_i7;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i8;
    logic         C1_c15_3_terminal_chain1_i8;
    logic         CLA_c15_3_terminal_chain1_i8;
    logic [2 : 0] O_c15_3_terminal_chain1_i8;
    logic [1 : 0] CY_c15_3_terminal_chain1_i8;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i8;
    logic         terminal_chain1_i8;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i9;
    logic         C1_c15_3_terminal_chain1_i9;
    logic         CLA_c15_3_terminal_chain1_i9;
    logic [2 : 0] O_c15_3_terminal_chain1_i9;
    logic [1 : 0] CY_c15_3_terminal_chain1_i9;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i9;
    logic         terminal_chain1_i9;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i10;
    logic         C1_c15_3_terminal_chain1_i10;
    logic         CLA_c15_3_terminal_chain1_i10;
    logic [2 : 0] O_c15_3_terminal_chain1_i10;
    logic [1 : 0] CY_c15_3_terminal_chain1_i10;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i10;
    logic         terminal_chain1_i10;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i11;
    logic         C1_c15_3_terminal_chain1_i11;
    logic         CLA_c15_3_terminal_chain1_i11;
    logic [2 : 0] O_c15_3_terminal_chain1_i11;
    logic [1 : 0] CY_c15_3_terminal_chain1_i11;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i11;
    logic         terminal_chain1_i11;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i12;
    logic         C1_c15_3_terminal_chain1_i12;
    logic         CLA_c15_3_terminal_chain1_i12;
    logic [2 : 0] O_c15_3_terminal_chain1_i12;
    logic [1 : 0] CY_c15_3_terminal_chain1_i12;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i12;
    logic         terminal_chain1_i12;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i13;
    logic         C1_c15_3_terminal_chain1_i13;
    logic         CLA_c15_3_terminal_chain1_i13;
    logic [2 : 0] O_c15_3_terminal_chain1_i13;
    logic [1 : 0] CY_c15_3_terminal_chain1_i13;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i13;
    logic         terminal_chain1_i13;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i14;
    logic         C1_c15_3_terminal_chain1_i14;
    logic         CLA_c15_3_terminal_chain1_i14;
    logic [2 : 0] O_c15_3_terminal_chain1_i14;
    logic [1 : 0] CY_c15_3_terminal_chain1_i14;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i14;
    logic         terminal_chain1_i14;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i15;
    logic         C1_c15_3_terminal_chain1_i15;
    logic         CLA_c15_3_terminal_chain1_i15;
    logic [2 : 0] O_c15_3_terminal_chain1_i15;
    logic [1 : 0] CY_c15_3_terminal_chain1_i15;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i15;
    logic         terminal_chain1_i15;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i16;
    logic         C1_c15_3_terminal_chain1_i16;
    logic         CLA_c15_3_terminal_chain1_i16;
    logic [2 : 0] O_c15_3_terminal_chain1_i16;
    logic [1 : 0] CY_c15_3_terminal_chain1_i16;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i16;
    logic         terminal_chain1_i16;
    
    logic [4 : 0] C0_c15_3_terminal_chain1_i17;
    logic         C1_c15_3_terminal_chain1_i17;
    logic         CLA_c15_3_terminal_chain1_i17;
    logic [2 : 0] O_c15_3_terminal_chain1_i17;
    logic [1 : 0] CY_c15_3_terminal_chain1_i17;
    logic [1 : 0] PROP_c15_3_terminal_chain1_i17;
    logic         terminal_chain1_i17;
    
    logic [2 : 0] C0_c3_2_terminal_chain1_i18;
    logic [1 : 0] O_c3_2_terminal_chain1_i18;
    logic         CY_c3_2_terminal_chain1_i18;
    logic         PROP_c3_2_terminal_chain1_i18;
    logic         terminal_chain1_i18;
    
    logic [42 : 0] terminal_chain2_out;
    
    logic [23 : 0] COUT_LA_terminal_chain2;
    logic [5  : 0] CIN_LA_terminal_chain2;
    logic [47 : 0] CY_LA_terminal_chain2;
    logic [47 : 0] PROP_LA_terminal_chain2;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i0;
    logic [1 : 0] O_c3_2_terminal_chain2_i0;
    logic         CY_c3_2_terminal_chain2_i0;
    logic         PROP_c3_2_terminal_chain2_i0;
    logic         terminal_chain2_i0;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i1;
    logic [1 : 0] O_c3_2_terminal_chain2_i1;
    logic         CY_c3_2_terminal_chain2_i1;
    logic         PROP_c3_2_terminal_chain2_i1;
    logic         terminal_chain2_i1;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i2;
    logic [1 : 0] O_c3_2_terminal_chain2_i2;
    logic         CY_c3_2_terminal_chain2_i2;
    logic         PROP_c3_2_terminal_chain2_i2;
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
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i16;
    logic         C1_c15_3_terminal_chain2_i16;
    logic         CLA_c15_3_terminal_chain2_i16;
    logic [2 : 0] O_c15_3_terminal_chain2_i16;
    logic [1 : 0] CY_c15_3_terminal_chain2_i16;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i16;
    logic         terminal_chain2_i16;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i17;
    logic         C1_c15_3_terminal_chain2_i17;
    logic         CLA_c15_3_terminal_chain2_i17;
    logic [2 : 0] O_c15_3_terminal_chain2_i17;
    logic [1 : 0] CY_c15_3_terminal_chain2_i17;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i17;
    logic         terminal_chain2_i17;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i18;
    logic         C1_c15_3_terminal_chain2_i18;
    logic         CLA_c15_3_terminal_chain2_i18;
    logic [2 : 0] O_c15_3_terminal_chain2_i18;
    logic [1 : 0] CY_c15_3_terminal_chain2_i18;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i18;
    logic         terminal_chain2_i18;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i19;
    logic         C1_c15_3_terminal_chain2_i19;
    logic         CLA_c15_3_terminal_chain2_i19;
    logic [2 : 0] O_c15_3_terminal_chain2_i19;
    logic [1 : 0] CY_c15_3_terminal_chain2_i19;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i19;
    logic         terminal_chain2_i19;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i20;
    logic         C1_c15_3_terminal_chain2_i20;
    logic         CLA_c15_3_terminal_chain2_i20;
    logic [2 : 0] O_c15_3_terminal_chain2_i20;
    logic [1 : 0] CY_c15_3_terminal_chain2_i20;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i20;
    logic         terminal_chain2_i20;
    
    logic [4 : 0] C0_c15_3_terminal_chain2_i21;
    logic         C1_c15_3_terminal_chain2_i21;
    logic         CLA_c15_3_terminal_chain2_i21;
    logic [2 : 0] O_c15_3_terminal_chain2_i21;
    logic [1 : 0] CY_c15_3_terminal_chain2_i21;
    logic [1 : 0] PROP_c15_3_terminal_chain2_i21;
    logic         terminal_chain2_i21;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i22;
    logic [1 : 0] O_c3_2_terminal_chain2_i22;
    logic         CY_c3_2_terminal_chain2_i22;
    logic         PROP_c3_2_terminal_chain2_i22;
    logic         terminal_chain2_i22;
    
    // ------------------------------ LAYER 0 ------------------------------
    // GPC chain0 in layer0:
    // -- (3 : 2] at column 54
    // -- (3 : 2] at column 55
    // -- (1,5 : 3] at column 56
    // -- (3 : 2] at column 58
    // -- (3 : 2] at column 59
    // -- (3 : 2] at column 60
    
    LOOKAHEAD8 #(
        .LOOKB("FALSE"),
        .LOOKD("TRUE" ),
        .LOOKF("TRUE" ),
        .LOOKH("FALSE"))
    LOOKAHEAD8_l0_c0_s0_inst0 (
        .COUTB(COUT_LA_l0_c0_s0[0]),
        .COUTD(COUT_LA_l0_c0_s0[1]),
        .COUTF(COUT_LA_l0_c0_s0[2]),
        .COUTH(COUT_LA_l0_c0_s0[3]),
        .CIN  (CIN_LA_l0_c0_s0    ),
        .CYA  (CY_LA_l0_c0_s0[0]  ),
        .CYB  (CY_LA_l0_c0_s0[1]  ),
        .CYC  (CY_LA_l0_c0_s0[2]  ),
        .CYD  (CY_LA_l0_c0_s0[3]  ),
        .CYE  (CY_LA_l0_c0_s0[4]  ),
        .CYF  (CY_LA_l0_c0_s0[5]  ),
        .CYG  (CY_LA_l0_c0_s0[6]  ),
        .CYH  (CY_LA_l0_c0_s0[7]  ),
        .PROPA(PROP_LA_l0_c0_s0[0]),
        .PROPB(PROP_LA_l0_c0_s0[1]),
        .PROPC(PROP_LA_l0_c0_s0[2]),
        .PROPD(PROP_LA_l0_c0_s0[3]),
        .PROPE(PROP_LA_l0_c0_s0[4]),
        .PROPF(PROP_LA_l0_c0_s0[5]),
        .PROPG(PROP_LA_l0_c0_s0[6]),
        .PROPH(PROP_LA_l0_c0_s0[7]));

    c3_2 #(.OUTREG("TRUE" ),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("TRUE" ),
           .LASTS ("FALSE"))
    c3_2_l0_c0_i0(
        .clk (clk               ),
        .C0  (C0_c3_2_l0_c0_i0  ),
        .O   (O_c3_2_l0_c0_i0   ),
        .CY  (CY_c3_2_l0_c0_i0  ),
        .PROP(PROP_c3_2_l0_c0_i0));
    
    assign C0_c3_2_l0_c0_i0 = layer0_col54[2:0];
    
    assign layer1_col54[0] = O_c3_2_l0_c0_i0[0];
    
    assign l0_c0_i0            = O_c3_2_l0_c0_i0[1];
    assign CY_LA_l0_c0_s0[0]   = CY_c3_2_l0_c0_i0;
    assign PROP_LA_l0_c0_s0[0] = PROP_c3_2_l0_c0_i0;
    
    assign CIN_LA_l0_c0_s0    = C0_c3_2_l0_c0_i0[2];
    
    c3_2 #(.OUTREG("TRUE" ),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("TRUE" ),
           .LASTS ("FALSE"))
    c3_2_l0_c0_i1(
        .clk (clk               ),
        .C0  (C0_c3_2_l0_c0_i1  ),
        .O   (O_c3_2_l0_c0_i1   ),
        .CY  (CY_c3_2_l0_c0_i1  ),
        .PROP(PROP_c3_2_l0_c0_i1));
    
    assign C0_c3_2_l0_c0_i1 = {l0_c0_i0, layer0_col55[1:0]};
    
    assign layer1_col55[0] = O_c3_2_l0_c0_i1[0];
    
    assign l0_c0_i1            = COUT_LA_l0_c0_s0[0];
    assign CY_LA_l0_c0_s0[1]   = CY_c3_2_l0_c0_i1;
    assign PROP_LA_l0_c0_s0[1] = PROP_c3_2_l0_c0_i1;
    
    c15_3 #(.OUTREG("TRUE" ),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_l0_c0_i2(
        .clk (clk                ),
        .C0  (C0_c15_3_l0_c0_i2  ),
        .C1  (C1_c15_3_l0_c0_i2  ),
        .CLA (CLA_c15_3_l0_c0_i2 ),
        .O   (O_c15_3_l0_c0_i2   ),
        .CY  (CY_c15_3_l0_c0_i2  ),
        .PROP(PROP_c15_3_l0_c0_i2));
    
    assign C0_c15_3_l0_c0_i2 = {l0_c0_i1, layer0_col56[3:0]};
    assign C1_c15_3_l0_c0_i2 = layer0_col57[0];
    
    assign layer1_col56[0] = O_c15_3_l0_c0_i2[0];
    assign layer1_col57[0] = O_c15_3_l0_c0_i2[1];
    
    assign l0_c0_i2              = COUT_LA_l0_c0_s0[1];
    assign CY_LA_l0_c0_s0[3:2]   = CY_c15_3_l0_c0_i2;
    assign PROP_LA_l0_c0_s0[3:2] = PROP_c15_3_l0_c0_i2;
    
    c3_2 #(.OUTREG("TRUE" ),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_l0_c0_i3(
        .clk (clk               ),
        .C0  (C0_c3_2_l0_c0_i3  ),
        .O   (O_c3_2_l0_c0_i3   ),
        .CY  (CY_c3_2_l0_c0_i3  ),
        .PROP(PROP_c3_2_l0_c0_i3));
    
    assign C0_c3_2_l0_c0_i3 = {l0_c0_i2, layer0_col58[1:0]};
    
    assign layer1_col58[0] = O_c3_2_l0_c0_i3[0];
    
    assign l0_c0_i3            = O_c3_2_l0_c0_i3[1];
    assign CY_LA_l0_c0_s0[4]   = CY_c3_2_l0_c0_i3;
    assign PROP_LA_l0_c0_s0[4] = PROP_c3_2_l0_c0_i3;
    
    c3_2 #(.OUTREG("TRUE" ),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_l0_c0_i4(
        .clk (clk               ),
        .C0  (C0_c3_2_l0_c0_i4  ),
        .O   (O_c3_2_l0_c0_i4   ),
        .CY  (CY_c3_2_l0_c0_i4  ),
        .PROP(PROP_c3_2_l0_c0_i4));
    
    assign C0_c3_2_l0_c0_i4 = {l0_c0_i3, layer0_col59[1:0]};
    
    assign layer1_col59 = {1'b0, O_c223_4_l0_f0[2], O_c3_2_l0_c0_i4[0]};
    
    assign l0_c0_i4            = COUT_LA_l0_c0_s0[2];
    assign CY_LA_l0_c0_s0[5]   = CY_c3_2_l0_c0_i4;
    assign PROP_LA_l0_c0_s0[5] = PROP_c3_2_l0_c0_i4;
    
    c3_2 #(.OUTREG("TRUE" ),
           .LEAVEC("FALSE"),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("TRUE" ))
    c3_2_l0_c0_i5(
        .clk (clk               ),
        .C0  (C0_c3_2_l0_c0_i5  ),
        .O   (O_c3_2_l0_c0_i5   ),
        .CY  (CY_c3_2_l0_c0_i5  ),
        .PROP(PROP_c3_2_l0_c0_i5));
    
    assign C0_c3_2_l0_c0_i5 = {l0_c0_i4, layer0_col60[1:0]};
    
    assign layer1_col60[0] = O_c3_2_l0_c0_i5[0];
    assign layer1_col61[0] = O_c3_2_l0_c0_i5[1];
    
    assign l0_c0_i5            = O_c3_2_l0_c0_i5[1];
    assign CY_LA_l0_c0_s0[6]   = CY_c3_2_l0_c0_i5;
    assign PROP_LA_l0_c0_s0[6] = PROP_c3_2_l0_c0_i5;
    
    // GPC0 in layer0: (2,2,3 : 4] at column 57
    
    c223_4 #(.OUTREG("TRUE" ),
             .LEAVEC("FALSE"),
             .POSODD("FALSE"))
    c223_4_l0_f0(
        .clk (clk              ),
        .C0  (C0_c223_4_l0_f0  ),
        .C1  (C1_c223_4_l0_f0  ),
        .C2  (C2_c223_4_l0_f0  ),
        .CLA (CLA_c223_4_l0_f0 ),
        .O   (O_c223_4_l0_f0   ),
        .CY  (CY_c223_4_l0_f0  ),
        .PROP(PROP_c223_4_l0_f0));
    
    assign C0_c223_4_l0_f0 = layer0_col57[3:1];
    assign C1_c223_4_l0_f0 = layer0_col58[3:2];
    assign C2_c223_4_l0_f0 = layer0_col59[3:2];
    
    assign layer1_col57[1] = O_c223_4_l0_f0[0];
    assign layer1_col58[1] = O_c223_4_l0_f0[1];
    assign layer1_col60[1] = O_c223_4_l0_f0[3];
    
    LOOKAHEAD8 #(
        .LOOKB("FALSE"),
        .LOOKD("FALSE"),
        .LOOKF("FALSE"),
        .LOOKH("FALSE"))
    LOOKAHEAD8_l0_floating_placement_inst0 (
        .COUTB(COUT_LA_l0_floating_placement[0]),
        .COUTD(COUT_LA_l0_floating_placement[1]),
        .COUTF(COUT_LA_l0_floating_placement[2]),
        .COUTH(COUT_LA_l0_floating_placement[3]),
        .CIN  (CIN_LA_l0_floating_placement    ),
        .CYA  (CY_LA_l0_floating_placement[0]  ),
        .CYB  (CY_LA_l0_floating_placement[1]  ),
        .CYC  (CY_LA_l0_floating_placement[2]  ),
        .CYD  (CY_LA_l0_floating_placement[3]  ),
        .CYE  (CY_LA_l0_floating_placement[4]  ),
        .CYF  (CY_LA_l0_floating_placement[5]  ),
        .CYG  (CY_LA_l0_floating_placement[6]  ),
        .CYH  (CY_LA_l0_floating_placement[7]  ),
        .PROPA(PROP_LA_l0_floating_placement[0]),
        .PROPB(PROP_LA_l0_floating_placement[1]),
        .PROPC(PROP_LA_l0_floating_placement[2]),
        .PROPD(PROP_LA_l0_floating_placement[3]),
        .PROPE(PROP_LA_l0_floating_placement[4]),
        .PROPF(PROP_LA_l0_floating_placement[5]),
        .PROPG(PROP_LA_l0_floating_placement[6]),
        .PROPH(PROP_LA_l0_floating_placement[7]));

    assign CY_LA_l0_floating_placement[1:0]   = CY_c223_4_l0_f0;
    assign PROP_LA_l0_floating_placement[1:0] = PROP_c223_4_l0_f0;
    assign CIN_LA_l0_floating_placement    = C0_c223_4_l0_f0[2];
    
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
        layer1_col23[0] <= layer0_col23[0];
        layer1_col23[1] <= layer0_col23[1];
        layer1_col24[0] <= layer0_col24[0];
        layer1_col24[1] <= layer0_col24[1];
        layer1_col25[0] <= layer0_col25[0];
        layer1_col25[1] <= layer0_col25[1];
        layer1_col26[0] <= layer0_col26[0];
        layer1_col26[1] <= layer0_col26[1];
        layer1_col26[2] <= layer0_col26[2];
        layer1_col27[0] <= layer0_col27[0];
        layer1_col27[1] <= layer0_col27[1];
        layer1_col27[2] <= layer0_col27[2];
        layer1_col28[0] <= layer0_col28[0];
        layer1_col28[1] <= layer0_col28[1];
        layer1_col28[2] <= layer0_col28[2];
        layer1_col29[0] <= layer0_col29[0];
        layer1_col29[1] <= layer0_col29[1];
        layer1_col29[2] <= layer0_col29[2];
        layer1_col30[0] <= layer0_col30[0];
        layer1_col30[1] <= layer0_col30[1];
        layer1_col30[2] <= layer0_col30[2];
        layer1_col31[0] <= layer0_col31[0];
        layer1_col31[1] <= layer0_col31[1];
        layer1_col31[2] <= layer0_col31[2];
        layer1_col32[0] <= layer0_col32[0];
        layer1_col32[1] <= layer0_col32[1];
        layer1_col32[2] <= layer0_col32[2];
        layer1_col33[0] <= layer0_col33[0];
        layer1_col33[1] <= layer0_col33[1];
        layer1_col33[2] <= layer0_col33[2];
        layer1_col34[0] <= layer0_col34[0];
        layer1_col34[1] <= layer0_col34[1];
        layer1_col34[2] <= layer0_col34[2];
        layer1_col35[0] <= layer0_col35[0];
        layer1_col35[1] <= layer0_col35[1];
        layer1_col35[2] <= layer0_col35[2];
        layer1_col36[0] <= layer0_col36[0];
        layer1_col36[1] <= layer0_col36[1];
        layer1_col36[2] <= layer0_col36[2];
        layer1_col37[0] <= layer0_col37[0];
        layer1_col37[1] <= layer0_col37[1];
        layer1_col37[2] <= layer0_col37[2];
        layer1_col38[0] <= layer0_col38[0];
        layer1_col38[1] <= layer0_col38[1];
        layer1_col38[2] <= layer0_col38[2];
        layer1_col39[0] <= layer0_col39[0];
        layer1_col39[1] <= layer0_col39[1];
        layer1_col39[2] <= layer0_col39[2];
        layer1_col40[0] <= layer0_col40[0];
        layer1_col40[1] <= layer0_col40[1];
        layer1_col40[2] <= layer0_col40[2];
        layer1_col41[0] <= layer0_col41[0];
        layer1_col41[1] <= layer0_col41[1];
        layer1_col41[2] <= layer0_col41[2];
        layer1_col42[0] <= layer0_col42[0];
        layer1_col42[1] <= layer0_col42[1];
        layer1_col42[2] <= layer0_col42[2];
        layer1_col43[0] <= layer0_col43[0];
        layer1_col43[1] <= layer0_col43[1];
        layer1_col43[2] <= layer0_col43[2];
        layer1_col44[0] <= layer0_col44[0];
        layer1_col44[1] <= layer0_col44[1];
        layer1_col44[2] <= layer0_col44[2];
        layer1_col45[0] <= layer0_col45[0];
        layer1_col45[1] <= layer0_col45[1];
        layer1_col45[2] <= layer0_col45[2];
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
        layer1_col50[0] <= layer0_col50[0];
        layer1_col50[1] <= layer0_col50[1];
        layer1_col51[0] <= layer0_col51[0];
        layer1_col51[1] <= layer0_col51[1];
        layer1_col52[0] <= layer0_col52[0];
        layer1_col52[1] <= layer0_col52[1];
        layer1_col52[2] <= layer0_col52[2];
        layer1_col52[3] <= layer0_col52[3];
        layer1_col53[0] <= layer0_col53[0];
        layer1_col53[1] <= layer0_col53[1];
        layer1_col53[2] <= layer0_col53[2];
        layer1_col54[1] <= layer0_col54[3];
        layer1_col54[2] <= layer0_col54[4];
        layer1_col55[1] <= layer0_col55[2];
        layer1_col55[2] <= layer0_col55[3];
        layer1_col56[1] <= layer0_col56[4];
        layer1_col56[2] <= layer0_col56[5];
        layer1_col57[2] <= layer0_col57[4];
        layer1_col58[2] <= layer0_col58[4];

        layer1_col60[2] <= layer0_col60[2];

        layer1_col61[1] <= layer0_col61[0];
        layer1_col61[2] <= layer0_col61[1];
        layer1_col61[3] <= layer0_col61[2];
        layer1_col62[0] <= layer0_col62[0];
        layer1_col62[1] <= layer0_col62[1];

        layer1_col63[0] <= layer0_col63[0];
        layer1_col63[1] <= layer0_col63[1];
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

    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("TRUE" ),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i0(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain1_i0  ),
        .C1  (C1_c15_3_terminal_chain1_i0  ),
        .CLA (CLA_c15_3_terminal_chain1_i0 ),
        .O   (O_c15_3_terminal_chain1_i0   ),
        .CY  (CY_c15_3_terminal_chain1_i0  ),
        .PROP(PROP_c15_3_terminal_chain1_i0));
    assign C0_c15_3_terminal_chain1_i0 = {layer1_col27[2], layer1_col27[1], layer1_col27[0], 1'b0, 1'b0};
    assign C1_c15_3_terminal_chain1_i0    = layer1_col28[0];
    
    assign terminal_chain1_out = {O_c3_2_terminal_chain1_i18[1], O_c3_2_terminal_chain1_i18[0], O_c15_3_terminal_chain1_i17[1], O_c15_3_terminal_chain1_i17[0], O_c15_3_terminal_chain1_i16[1], O_c15_3_terminal_chain1_i16[0], O_c15_3_terminal_chain1_i15[1], O_c15_3_terminal_chain1_i15[0], O_c15_3_terminal_chain1_i14[1], O_c15_3_terminal_chain1_i14[0], O_c15_3_terminal_chain1_i13[1], O_c15_3_terminal_chain1_i13[0], O_c15_3_terminal_chain1_i12[1], O_c15_3_terminal_chain1_i12[0], O_c15_3_terminal_chain1_i11[1], O_c15_3_terminal_chain1_i11[0], O_c15_3_terminal_chain1_i10[1], O_c15_3_terminal_chain1_i10[0], O_c15_3_terminal_chain1_i9[1], O_c15_3_terminal_chain1_i9[0], O_c15_3_terminal_chain1_i8[1], O_c15_3_terminal_chain1_i8[0], O_c15_3_terminal_chain1_i7[1], O_c15_3_terminal_chain1_i7[0], O_c15_3_terminal_chain1_i6[1], O_c15_3_terminal_chain1_i6[0], O_c15_3_terminal_chain1_i5[1], O_c15_3_terminal_chain1_i5[0], O_c15_3_terminal_chain1_i4[1], O_c15_3_terminal_chain1_i4[0], O_c15_3_terminal_chain1_i3[1], O_c15_3_terminal_chain1_i3[0], O_c15_3_terminal_chain1_i2[1], O_c15_3_terminal_chain1_i2[0], O_c15_3_terminal_chain1_i1[1], O_c15_3_terminal_chain1_i1[0], O_c15_3_terminal_chain1_i0[1], O_c15_3_terminal_chain1_i0[0]};
    
    assign terminal_chain1_i0           = COUT_LA_terminal_chain1[0];
    assign CY_LA_terminal_chain1[1:0]   = CY_c15_3_terminal_chain1_i0;
    assign PROP_LA_terminal_chain1[1:0] = PROP_c15_3_terminal_chain1_i0;
    
    assign CIN_LA_terminal_chain1 = {COUT_LA_terminal_chain1[15], COUT_LA_terminal_chain1[11], COUT_LA_terminal_chain1[7], COUT_LA_terminal_chain1[3], C0_c15_3_terminal_chain1_i0[4]};
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i1(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain1_i1  ),
        .C1  (C1_c15_3_terminal_chain1_i1  ),
        .CLA (CLA_c15_3_terminal_chain1_i1 ),
        .O   (O_c15_3_terminal_chain1_i1   ),
        .CY  (CY_c15_3_terminal_chain1_i1  ),
        .PROP(PROP_c15_3_terminal_chain1_i1));
    
    assign C0_c15_3_terminal_chain1_i1 = {terminal_chain1_i0, layer1_col29[2], layer1_col29[1], layer1_col29[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i1    = layer1_col30[0];
    
    
    assign terminal_chain1_i1           = COUT_LA_terminal_chain1[1];
    assign CY_LA_terminal_chain1[3:2]   = CY_c15_3_terminal_chain1_i1;
    assign PROP_LA_terminal_chain1[3:2] = PROP_c15_3_terminal_chain1_i1;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i2(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain1_i2  ),
        .C1  (C1_c15_3_terminal_chain1_i2  ),
        .CLA (CLA_c15_3_terminal_chain1_i2 ),
        .O   (O_c15_3_terminal_chain1_i2   ),
        .CY  (CY_c15_3_terminal_chain1_i2  ),
        .PROP(PROP_c15_3_terminal_chain1_i2));
    
    assign C0_c15_3_terminal_chain1_i2 = {terminal_chain1_i1, layer1_col31[2], layer1_col31[1], layer1_col31[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i2    = layer1_col32[0];
    
    
    assign terminal_chain1_i2           = COUT_LA_terminal_chain1[2];
    assign CY_LA_terminal_chain1[5:4]   = CY_c15_3_terminal_chain1_i2;
    assign PROP_LA_terminal_chain1[5:4] = PROP_c15_3_terminal_chain1_i2;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i3(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain1_i3  ),
        .C1  (C1_c15_3_terminal_chain1_i3  ),
        .CLA (CLA_c15_3_terminal_chain1_i3 ),
        .O   (O_c15_3_terminal_chain1_i3   ),
        .CY  (CY_c15_3_terminal_chain1_i3  ),
        .PROP(PROP_c15_3_terminal_chain1_i3));
    
    assign C0_c15_3_terminal_chain1_i3 = {terminal_chain1_i2, layer1_col33[2], layer1_col33[1], layer1_col33[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i3    = layer1_col34[0];
    
    
    assign terminal_chain1_i3           = COUT_LA_terminal_chain1[3];
    assign CY_LA_terminal_chain1[7:6]   = CY_c15_3_terminal_chain1_i3;
    assign PROP_LA_terminal_chain1[7:6] = PROP_c15_3_terminal_chain1_i3;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i4(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain1_i4  ),
        .C1  (C1_c15_3_terminal_chain1_i4  ),
        .CLA (CLA_c15_3_terminal_chain1_i4 ),
        .O   (O_c15_3_terminal_chain1_i4   ),
        .CY  (CY_c15_3_terminal_chain1_i4  ),
        .PROP(PROP_c15_3_terminal_chain1_i4));
    
    assign C0_c15_3_terminal_chain1_i4 = {terminal_chain1_i3, layer1_col35[2], layer1_col35[1], layer1_col35[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i4    = layer1_col36[0];
    
    
    assign terminal_chain1_i4           = COUT_LA_terminal_chain1[4];
    assign CY_LA_terminal_chain1[9:8]   = CY_c15_3_terminal_chain1_i4;
    assign PROP_LA_terminal_chain1[9:8] = PROP_c15_3_terminal_chain1_i4;
    
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i5(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain1_i5  ),
        .C1  (C1_c15_3_terminal_chain1_i5  ),
        .CLA (CLA_c15_3_terminal_chain1_i5 ),
        .O   (O_c15_3_terminal_chain1_i5   ),
        .CY  (CY_c15_3_terminal_chain1_i5  ),
        .PROP(PROP_c15_3_terminal_chain1_i5));
    
    assign C0_c15_3_terminal_chain1_i5 = {terminal_chain1_i4, layer1_col37[2], layer1_col37[1], layer1_col37[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i5    = layer1_col38[0];
    
    
    assign terminal_chain1_i5             = COUT_LA_terminal_chain1[5];
    assign CY_LA_terminal_chain1[11:10]   = CY_c15_3_terminal_chain1_i5;
    assign PROP_LA_terminal_chain1[11:10] = PROP_c15_3_terminal_chain1_i5;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i6(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain1_i6  ),
        .C1  (C1_c15_3_terminal_chain1_i6  ),
        .CLA (CLA_c15_3_terminal_chain1_i6 ),
        .O   (O_c15_3_terminal_chain1_i6   ),
        .CY  (CY_c15_3_terminal_chain1_i6  ),
        .PROP(PROP_c15_3_terminal_chain1_i6));
    
    assign C0_c15_3_terminal_chain1_i6 = {terminal_chain1_i5, layer1_col39[2], layer1_col39[1], layer1_col39[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i6    = layer1_col40[0];
    
    
    assign terminal_chain1_i6             = COUT_LA_terminal_chain1[6];
    assign CY_LA_terminal_chain1[13:12]   = CY_c15_3_terminal_chain1_i6;
    assign PROP_LA_terminal_chain1[13:12] = PROP_c15_3_terminal_chain1_i6;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i7(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain1_i7  ),
        .C1  (C1_c15_3_terminal_chain1_i7  ),
        .CLA (CLA_c15_3_terminal_chain1_i7 ),
        .O   (O_c15_3_terminal_chain1_i7   ),
        .CY  (CY_c15_3_terminal_chain1_i7  ),
        .PROP(PROP_c15_3_terminal_chain1_i7));
    
    assign C0_c15_3_terminal_chain1_i7 = {terminal_chain1_i6, layer1_col41[2], layer1_col41[1], layer1_col41[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i7    = layer1_col42[0];
    
    
    assign terminal_chain1_i7             = COUT_LA_terminal_chain1[7];
    assign CY_LA_terminal_chain1[15:14]   = CY_c15_3_terminal_chain1_i7;
    assign PROP_LA_terminal_chain1[15:14] = PROP_c15_3_terminal_chain1_i7;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i8(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain1_i8  ),
        .C1  (C1_c15_3_terminal_chain1_i8  ),
        .CLA (CLA_c15_3_terminal_chain1_i8 ),
        .O   (O_c15_3_terminal_chain1_i8   ),
        .CY  (CY_c15_3_terminal_chain1_i8  ),
        .PROP(PROP_c15_3_terminal_chain1_i8));
    
    assign C0_c15_3_terminal_chain1_i8 = {terminal_chain1_i7, layer1_col43[2], layer1_col43[1], layer1_col43[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i8    = layer1_col44[0];
    
    
    assign terminal_chain1_i8             = COUT_LA_terminal_chain1[8];
    assign CY_LA_terminal_chain1[17:16]   = CY_c15_3_terminal_chain1_i8;
    assign PROP_LA_terminal_chain1[17:16] = PROP_c15_3_terminal_chain1_i8;
    
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i9(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain1_i9  ),
        .C1  (C1_c15_3_terminal_chain1_i9  ),
        .CLA (CLA_c15_3_terminal_chain1_i9 ),
        .O   (O_c15_3_terminal_chain1_i9   ),
        .CY  (CY_c15_3_terminal_chain1_i9  ),
        .PROP(PROP_c15_3_terminal_chain1_i9));
    
    assign C0_c15_3_terminal_chain1_i9 = {terminal_chain1_i8, layer1_col45[2], layer1_col45[1], layer1_col45[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i9    = layer1_col46[0];
    
    
    assign terminal_chain1_i9             = COUT_LA_terminal_chain1[9];
    assign CY_LA_terminal_chain1[19:18]   = CY_c15_3_terminal_chain1_i9;
    assign PROP_LA_terminal_chain1[19:18] = PROP_c15_3_terminal_chain1_i9;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i10(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i10  ),
        .C1  (C1_c15_3_terminal_chain1_i10  ),
        .CLA (CLA_c15_3_terminal_chain1_i10 ),
        .O   (O_c15_3_terminal_chain1_i10   ),
        .CY  (CY_c15_3_terminal_chain1_i10  ),
        .PROP(PROP_c15_3_terminal_chain1_i10));
    
    assign C0_c15_3_terminal_chain1_i10 = {terminal_chain1_i9, layer1_col47[2], layer1_col47[1], layer1_col47[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i10    = layer1_col48[0];
    
    
    assign terminal_chain1_i10            = COUT_LA_terminal_chain1[10];
    assign CY_LA_terminal_chain1[21:20]   = CY_c15_3_terminal_chain1_i10;
    assign PROP_LA_terminal_chain1[21:20] = PROP_c15_3_terminal_chain1_i10;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i11(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i11  ),
        .C1  (C1_c15_3_terminal_chain1_i11  ),
        .CLA (CLA_c15_3_terminal_chain1_i11 ),
        .O   (O_c15_3_terminal_chain1_i11   ),
        .CY  (CY_c15_3_terminal_chain1_i11  ),
        .PROP(PROP_c15_3_terminal_chain1_i11));
    
    assign C0_c15_3_terminal_chain1_i11 = {terminal_chain1_i10, layer1_col49[1], layer1_col49[0], 1'b0, 1'b0};
    assign C1_c15_3_terminal_chain1_i11    = layer1_col50[0];
    
    
    assign terminal_chain1_i11            = COUT_LA_terminal_chain1[11];
    assign CY_LA_terminal_chain1[23:22]   = CY_c15_3_terminal_chain1_i11;
    assign PROP_LA_terminal_chain1[23:22] = PROP_c15_3_terminal_chain1_i11;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i12(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i12  ),
        .C1  (C1_c15_3_terminal_chain1_i12  ),
        .CLA (CLA_c15_3_terminal_chain1_i12 ),
        .O   (O_c15_3_terminal_chain1_i12   ),
        .CY  (CY_c15_3_terminal_chain1_i12  ),
        .PROP(PROP_c15_3_terminal_chain1_i12));
    
    assign C0_c15_3_terminal_chain1_i12 = {terminal_chain1_i11, layer1_col51[1], layer1_col51[0], 1'b0, 1'b0};
    assign C1_c15_3_terminal_chain1_i12    = layer1_col52[0];
    
    
    assign terminal_chain1_i12            = COUT_LA_terminal_chain1[12];
    assign CY_LA_terminal_chain1[25:24]   = CY_c15_3_terminal_chain1_i12;
    assign PROP_LA_terminal_chain1[25:24] = PROP_c15_3_terminal_chain1_i12;
    
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i13(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i13  ),
        .C1  (C1_c15_3_terminal_chain1_i13  ),
        .CLA (CLA_c15_3_terminal_chain1_i13 ),
        .O   (O_c15_3_terminal_chain1_i13   ),
        .CY  (CY_c15_3_terminal_chain1_i13  ),
        .PROP(PROP_c15_3_terminal_chain1_i13));
    
    assign C0_c15_3_terminal_chain1_i13 = {terminal_chain1_i12, layer1_col53[2], layer1_col53[1], layer1_col53[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i13    = layer1_col54[0];
    
    
    assign terminal_chain1_i13            = COUT_LA_terminal_chain1[13];
    assign CY_LA_terminal_chain1[27:26]   = CY_c15_3_terminal_chain1_i13;
    assign PROP_LA_terminal_chain1[27:26] = PROP_c15_3_terminal_chain1_i13;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i14(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i14  ),
        .C1  (C1_c15_3_terminal_chain1_i14  ),
        .CLA (CLA_c15_3_terminal_chain1_i14 ),
        .O   (O_c15_3_terminal_chain1_i14   ),
        .CY  (CY_c15_3_terminal_chain1_i14  ),
        .PROP(PROP_c15_3_terminal_chain1_i14));
    
    assign C0_c15_3_terminal_chain1_i14 = {terminal_chain1_i13, layer1_col55[2], layer1_col55[1], layer1_col55[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i14    = layer1_col56[0];
    
    
    assign terminal_chain1_i14            = COUT_LA_terminal_chain1[14];
    assign CY_LA_terminal_chain1[29:28]   = CY_c15_3_terminal_chain1_i14;
    assign PROP_LA_terminal_chain1[29:28] = PROP_c15_3_terminal_chain1_i14;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i15(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i15  ),
        .C1  (C1_c15_3_terminal_chain1_i15  ),
        .CLA (CLA_c15_3_terminal_chain1_i15 ),
        .O   (O_c15_3_terminal_chain1_i15   ),
        .CY  (CY_c15_3_terminal_chain1_i15  ),
        .PROP(PROP_c15_3_terminal_chain1_i15));
    
    assign C0_c15_3_terminal_chain1_i15 = {terminal_chain1_i14, layer1_col57[2], layer1_col57[1], layer1_col57[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i15    = layer1_col58[0];
    
    
    assign terminal_chain1_i15            = COUT_LA_terminal_chain1[15];
    assign CY_LA_terminal_chain1[31:30]   = CY_c15_3_terminal_chain1_i15;
    assign PROP_LA_terminal_chain1[31:30] = PROP_c15_3_terminal_chain1_i15;
    
    c15_3 #(.C0_INV(5'h8),
            .OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE")) c15_3_terminal_chain1_i16(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i16  ),
        .C1  (C1_c15_3_terminal_chain1_i16  ),
        .CLA (CLA_c15_3_terminal_chain1_i16 ),
        .O   (O_c15_3_terminal_chain1_i16   ),
        .CY  (CY_c15_3_terminal_chain1_i16  ),
        .PROP(PROP_c15_3_terminal_chain1_i16));
    
    assign C0_c15_3_terminal_chain1_i16 = {terminal_chain1_i15, layer1_col59[2], layer1_col59[1], layer1_col59[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i16    = layer1_col60[0];
    
    
    assign terminal_chain1_i16            = COUT_LA_terminal_chain1[16];
    assign CY_LA_terminal_chain1[33:32]   = CY_c15_3_terminal_chain1_i16;
    assign PROP_LA_terminal_chain1[33:32] = PROP_c15_3_terminal_chain1_i16;
    
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain1_i17(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain1_i17  ),
        .C1  (C1_c15_3_terminal_chain1_i17  ),
        .CLA (CLA_c15_3_terminal_chain1_i17 ),
        .O   (O_c15_3_terminal_chain1_i17   ),
        .CY  (CY_c15_3_terminal_chain1_i17  ),
        .PROP(PROP_c15_3_terminal_chain1_i17));
    
    assign C0_c15_3_terminal_chain1_i17 = {terminal_chain1_i16, layer1_col61[3], layer1_col61[2], layer1_col61[1], layer1_col61[0]};
    assign C1_c15_3_terminal_chain1_i17    = layer1_col62[0];
    
    
    assign terminal_chain1_i17            = COUT_LA_terminal_chain1[17];
    assign CY_LA_terminal_chain1[35:34]   = CY_c15_3_terminal_chain1_i17;
    assign PROP_LA_terminal_chain1[35:34] = PROP_c15_3_terminal_chain1_i17;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("TRUE" ))
    c3_2_terminal_chain1_i18(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i18  ),
        .O   (O_c3_2_terminal_chain1_i18   ),
        .CY  (CY_c3_2_terminal_chain1_i18  ),
        .PROP(PROP_c3_2_terminal_chain1_i18));
    
    assign C0_c3_2_terminal_chain1_i18 = {terminal_chain1_i17, layer1_col63[1], layer1_col63[0]};
    
    
    assign terminal_chain1_i18         = O_c3_2_terminal_chain1_i18[1];
    assign CY_LA_terminal_chain1[36]   = CY_c3_2_terminal_chain1_i18;
    assign PROP_LA_terminal_chain1[36] = PROP_c3_2_terminal_chain1_i18;
    
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

    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("TRUE" ),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i0(
        .clk (clk                         ),
        .C0  (C0_c3_2_terminal_chain2_i0  ),
        .O   (O_c3_2_terminal_chain2_i0   ),
        .CY  (CY_c3_2_terminal_chain2_i0  ),
        .PROP(PROP_c3_2_terminal_chain2_i0));
    
    assign C0_c3_2_terminal_chain2_i0 = {layer1_col23[1], layer1_col23[0], 1'b0};
    
    assign terminal_chain2_out = {O_c3_2_terminal_chain2_i22[1], O_c3_2_terminal_chain2_i22[0], O_c15_3_terminal_chain2_i21[1], O_c15_3_terminal_chain2_i21[0], O_c15_3_terminal_chain2_i20[1], O_c15_3_terminal_chain2_i20[0], O_c15_3_terminal_chain2_i19[1], O_c15_3_terminal_chain2_i19[0], O_c15_3_terminal_chain2_i18[1], O_c15_3_terminal_chain2_i18[0], O_c15_3_terminal_chain2_i17[1], O_c15_3_terminal_chain2_i17[0], O_c15_3_terminal_chain2_i16[1], O_c15_3_terminal_chain2_i16[0], O_c15_3_terminal_chain2_i15[1], O_c15_3_terminal_chain2_i15[0], O_c15_3_terminal_chain2_i14[1], O_c15_3_terminal_chain2_i14[0], O_c15_3_terminal_chain2_i13[1], O_c15_3_terminal_chain2_i13[0], O_c15_3_terminal_chain2_i12[1], O_c15_3_terminal_chain2_i12[0], O_c15_3_terminal_chain2_i11[1], O_c15_3_terminal_chain2_i11[0], O_c15_3_terminal_chain2_i10[1], O_c15_3_terminal_chain2_i10[0], O_c15_3_terminal_chain2_i9[1], O_c15_3_terminal_chain2_i9[0], O_c15_3_terminal_chain2_i8[1], O_c15_3_terminal_chain2_i8[0], O_c15_3_terminal_chain2_i7[1], O_c15_3_terminal_chain2_i7[0], O_c15_3_terminal_chain2_i6[1], O_c15_3_terminal_chain2_i6[0], O_c15_3_terminal_chain2_i5[1], O_c15_3_terminal_chain2_i5[0], O_c15_3_terminal_chain2_i4[1], O_c15_3_terminal_chain2_i4[0], O_c15_3_terminal_chain2_i3[1], O_c15_3_terminal_chain2_i3[0], O_c3_2_terminal_chain2_i2[0], O_c3_2_terminal_chain2_i1[0], O_c3_2_terminal_chain2_i0[0]};
    assign terminal_chain2_i0         = O_c3_2_terminal_chain2_i0[1];
    assign CY_LA_terminal_chain2[0]   = CY_c3_2_terminal_chain2_i0;
    assign PROP_LA_terminal_chain2[0] = PROP_c3_2_terminal_chain2_i0;
    
    assign CIN_LA_terminal_chain2 = {COUT_LA_terminal_chain2[19], COUT_LA_terminal_chain2[15], COUT_LA_terminal_chain2[11], COUT_LA_terminal_chain2[7], COUT_LA_terminal_chain2[3], C0_c3_2_terminal_chain2_i0[2]};
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("TRUE" ),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i1(
        .clk (clk                         ),
        .C0  (C0_c3_2_terminal_chain2_i1  ),
        .O   (O_c3_2_terminal_chain2_i1   ),
        .CY  (CY_c3_2_terminal_chain2_i1  ),
        .PROP(PROP_c3_2_terminal_chain2_i1));
    
    assign C0_c3_2_terminal_chain2_i1 = {terminal_chain2_i0, layer1_col24[1], layer1_col24[0]};
    
    assign terminal_chain2_i1         = COUT_LA_terminal_chain2[0];
    assign CY_LA_terminal_chain2[1]   = CY_c3_2_terminal_chain2_i1;
    assign PROP_LA_terminal_chain2[1] = PROP_c3_2_terminal_chain2_i1;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i2(
        .clk (clk                         ),
        .C0  (C0_c3_2_terminal_chain2_i2  ),
        .O   (O_c3_2_terminal_chain2_i2   ),
        .CY  (CY_c3_2_terminal_chain2_i2  ),
        .PROP(PROP_c3_2_terminal_chain2_i2));
    
    assign C0_c3_2_terminal_chain2_i2 = {terminal_chain2_i1, layer1_col25[1], layer1_col25[0]};
    
    assign terminal_chain2_i2         = O_c3_2_terminal_chain2_i2[1];
    assign CY_LA_terminal_chain2[2]   = CY_c3_2_terminal_chain2_i2;
    assign PROP_LA_terminal_chain2[2] = PROP_c3_2_terminal_chain2_i2;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
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
    
    assign C0_c15_3_terminal_chain2_i3 = {terminal_chain2_i2, layer1_col26[2], layer1_col26[1], layer1_col26[0], 1'b0};
    assign C1_c15_3_terminal_chain2_i3    = terminal_chain1_out[0];
    
    
    assign CLA_c15_3_terminal_chain2_i3 = COUT_LA_terminal_chain2[1];
    assign terminal_chain2_i3           = O_c15_3_terminal_chain2_i3[2];
    assign CY_LA_terminal_chain2[4:3]   = CY_c15_3_terminal_chain2_i3;
    assign PROP_LA_terminal_chain2[4:3] = PROP_c15_3_terminal_chain2_i3;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
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
    
    assign C0_c15_3_terminal_chain2_i4 = {terminal_chain2_i3, terminal_chain1_out[1], layer1_col28[2], layer1_col28[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i4    = terminal_chain1_out[2];
    
    
    assign CLA_c15_3_terminal_chain2_i4 = COUT_LA_terminal_chain2[2];
    assign terminal_chain2_i4           = O_c15_3_terminal_chain2_i4[2];
    assign CY_LA_terminal_chain2[6:5]   = CY_c15_3_terminal_chain2_i4;
    assign PROP_LA_terminal_chain2[6:5] = PROP_c15_3_terminal_chain2_i4;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
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
    
    assign C0_c15_3_terminal_chain2_i5 = {terminal_chain2_i4, terminal_chain1_out[3], layer1_col30[2], layer1_col30[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i5    = terminal_chain1_out[4];
    
    
    assign CLA_c15_3_terminal_chain2_i5 = COUT_LA_terminal_chain2[3];
    assign terminal_chain2_i5           = O_c15_3_terminal_chain2_i5[2];
    assign CY_LA_terminal_chain2[8:7]   = CY_c15_3_terminal_chain2_i5;
    assign PROP_LA_terminal_chain2[8:7] = PROP_c15_3_terminal_chain2_i5;
    
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
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
    
    assign C0_c15_3_terminal_chain2_i6 = {terminal_chain2_i5, terminal_chain1_out[5], layer1_col32[2], layer1_col32[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i6    = terminal_chain1_out[6];
    
    
    assign CLA_c15_3_terminal_chain2_i6  = COUT_LA_terminal_chain2[4];
    assign terminal_chain2_i6            = O_c15_3_terminal_chain2_i6[2];
    assign CY_LA_terminal_chain2[10:9]   = CY_c15_3_terminal_chain2_i6;
    assign PROP_LA_terminal_chain2[10:9] = PROP_c15_3_terminal_chain2_i6;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
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
    
    assign C0_c15_3_terminal_chain2_i7 = {terminal_chain2_i6, terminal_chain1_out[7], layer1_col34[2], layer1_col34[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i7    = terminal_chain1_out[8];
    
    
    assign CLA_c15_3_terminal_chain2_i7   = COUT_LA_terminal_chain2[5];
    assign terminal_chain2_i7             = O_c15_3_terminal_chain2_i7[2];
    assign CY_LA_terminal_chain2[12:11]   = CY_c15_3_terminal_chain2_i7;
    assign PROP_LA_terminal_chain2[12:11] = PROP_c15_3_terminal_chain2_i7;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
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
    
    assign C0_c15_3_terminal_chain2_i8 = {terminal_chain2_i7, terminal_chain1_out[9], layer1_col36[2], layer1_col36[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i8    = terminal_chain1_out[10];
    
    
    assign CLA_c15_3_terminal_chain2_i8   = COUT_LA_terminal_chain2[6];
    assign terminal_chain2_i8             = O_c15_3_terminal_chain2_i8[2];
    assign CY_LA_terminal_chain2[14:13]   = CY_c15_3_terminal_chain2_i8;
    assign PROP_LA_terminal_chain2[14:13] = PROP_c15_3_terminal_chain2_i8;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
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
    
    assign C0_c15_3_terminal_chain2_i9 = {terminal_chain2_i8, terminal_chain1_out[11], layer1_col38[2], layer1_col38[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i9    = terminal_chain1_out[12];
    
    
    assign CLA_c15_3_terminal_chain2_i9   = COUT_LA_terminal_chain2[7];
    assign terminal_chain2_i9             = O_c15_3_terminal_chain2_i9[2];
    assign CY_LA_terminal_chain2[16:15]   = CY_c15_3_terminal_chain2_i9;
    assign PROP_LA_terminal_chain2[16:15] = PROP_c15_3_terminal_chain2_i9;
    
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
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
    
    assign C0_c15_3_terminal_chain2_i10 = {terminal_chain2_i9, terminal_chain1_out[13], layer1_col40[2], layer1_col40[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i10    = terminal_chain1_out[14];
    
    
    assign CLA_c15_3_terminal_chain2_i10  = COUT_LA_terminal_chain2[8];
    assign terminal_chain2_i10            = O_c15_3_terminal_chain2_i10[2];
    assign CY_LA_terminal_chain2[18:17]   = CY_c15_3_terminal_chain2_i10;
    assign PROP_LA_terminal_chain2[18:17] = PROP_c15_3_terminal_chain2_i10;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
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
    
    assign C0_c15_3_terminal_chain2_i11 = {terminal_chain2_i10, terminal_chain1_out[15], layer1_col42[2], layer1_col42[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i11    = terminal_chain1_out[16];
    
    
    assign CLA_c15_3_terminal_chain2_i11  = COUT_LA_terminal_chain2[9];
    assign terminal_chain2_i11            = O_c15_3_terminal_chain2_i11[2];
    assign CY_LA_terminal_chain2[20:19]   = CY_c15_3_terminal_chain2_i11;
    assign PROP_LA_terminal_chain2[20:19] = PROP_c15_3_terminal_chain2_i11;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
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
    
    assign C0_c15_3_terminal_chain2_i12 = {terminal_chain2_i11, terminal_chain1_out[17], layer1_col44[2], layer1_col44[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i12    = terminal_chain1_out[18];
    
    
    assign CLA_c15_3_terminal_chain2_i12  = COUT_LA_terminal_chain2[10];
    assign terminal_chain2_i12            = O_c15_3_terminal_chain2_i12[2];
    assign CY_LA_terminal_chain2[22:21]   = CY_c15_3_terminal_chain2_i12;
    assign PROP_LA_terminal_chain2[22:21] = PROP_c15_3_terminal_chain2_i12;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
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
    
    assign C0_c15_3_terminal_chain2_i13 = {terminal_chain2_i12, terminal_chain1_out[19], layer1_col46[2], layer1_col46[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i13    = terminal_chain1_out[20];
    
    
    assign CLA_c15_3_terminal_chain2_i13  = COUT_LA_terminal_chain2[11];
    assign terminal_chain2_i13            = O_c15_3_terminal_chain2_i13[2];
    assign CY_LA_terminal_chain2[24:23]   = CY_c15_3_terminal_chain2_i13;
    assign PROP_LA_terminal_chain2[24:23] = PROP_c15_3_terminal_chain2_i13;
    
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
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
    
    assign C0_c15_3_terminal_chain2_i14 = {terminal_chain2_i13, terminal_chain1_out[21], layer1_col48[2], layer1_col48[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i14    = terminal_chain1_out[22];
    
    
    assign CLA_c15_3_terminal_chain2_i14  = COUT_LA_terminal_chain2[12];
    assign terminal_chain2_i14            = O_c15_3_terminal_chain2_i14[2];
    assign CY_LA_terminal_chain2[26:25]   = CY_c15_3_terminal_chain2_i14;
    assign PROP_LA_terminal_chain2[26:25] = PROP_c15_3_terminal_chain2_i14;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
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
    
    assign C0_c15_3_terminal_chain2_i15 = {terminal_chain2_i14, terminal_chain1_out[23], layer1_col50[1], 1'b0, 1'b0};
    assign C1_c15_3_terminal_chain2_i15    = terminal_chain1_out[24];
    
    
    assign CLA_c15_3_terminal_chain2_i15  = COUT_LA_terminal_chain2[13];
    assign terminal_chain2_i15            = O_c15_3_terminal_chain2_i15[2];
    assign CY_LA_terminal_chain2[28:27]   = CY_c15_3_terminal_chain2_i15;
    assign PROP_LA_terminal_chain2[28:27] = PROP_c15_3_terminal_chain2_i15;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i16(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain2_i16  ),
        .C1  (C1_c15_3_terminal_chain2_i16  ),
        .CLA (CLA_c15_3_terminal_chain2_i16 ),
        .O   (O_c15_3_terminal_chain2_i16   ),
        .CY  (CY_c15_3_terminal_chain2_i16  ),
        .PROP(PROP_c15_3_terminal_chain2_i16));
    
    assign C0_c15_3_terminal_chain2_i16 = {terminal_chain2_i15, terminal_chain1_out[25], layer1_col52[3], layer1_col52[2], layer1_col52[1]};
    assign C1_c15_3_terminal_chain2_i16    = terminal_chain1_out[26];
    
    
    assign CLA_c15_3_terminal_chain2_i16  = COUT_LA_terminal_chain2[14];
    assign terminal_chain2_i16            = O_c15_3_terminal_chain2_i16[2];
    assign CY_LA_terminal_chain2[30:29]   = CY_c15_3_terminal_chain2_i16;
    assign PROP_LA_terminal_chain2[30:29] = PROP_c15_3_terminal_chain2_i16;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i17(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain2_i17  ),
        .C1  (C1_c15_3_terminal_chain2_i17  ),
        .CLA (CLA_c15_3_terminal_chain2_i17 ),
        .O   (O_c15_3_terminal_chain2_i17   ),
        .CY  (CY_c15_3_terminal_chain2_i17  ),
        .PROP(PROP_c15_3_terminal_chain2_i17));
    
    assign C0_c15_3_terminal_chain2_i17 = {terminal_chain2_i16, terminal_chain1_out[27], layer1_col54[2], layer1_col54[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i17    = terminal_chain1_out[28];
    
    
    assign CLA_c15_3_terminal_chain2_i17  = COUT_LA_terminal_chain2[15];
    assign terminal_chain2_i17            = O_c15_3_terminal_chain2_i17[2];
    assign CY_LA_terminal_chain2[32:31]   = CY_c15_3_terminal_chain2_i17;
    assign PROP_LA_terminal_chain2[32:31] = PROP_c15_3_terminal_chain2_i17;
    
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i18(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain2_i18  ),
        .C1  (C1_c15_3_terminal_chain2_i18  ),
        .CLA (CLA_c15_3_terminal_chain2_i18 ),
        .O   (O_c15_3_terminal_chain2_i18   ),
        .CY  (CY_c15_3_terminal_chain2_i18  ),
        .PROP(PROP_c15_3_terminal_chain2_i18));
    
    assign C0_c15_3_terminal_chain2_i18 = {terminal_chain2_i17, terminal_chain1_out[29], layer1_col56[2], layer1_col56[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i18    = terminal_chain1_out[30];
    
    
    assign CLA_c15_3_terminal_chain2_i18  = COUT_LA_terminal_chain2[16];
    assign terminal_chain2_i18            = O_c15_3_terminal_chain2_i18[2];
    assign CY_LA_terminal_chain2[34:33]   = CY_c15_3_terminal_chain2_i18;
    assign PROP_LA_terminal_chain2[34:33] = PROP_c15_3_terminal_chain2_i18;
    
    c15_3 #(.OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_terminal_chain2_i19(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain2_i19  ),
        .C1  (C1_c15_3_terminal_chain2_i19  ),
        .CLA (CLA_c15_3_terminal_chain2_i19 ),
        .O   (O_c15_3_terminal_chain2_i19   ),
        .CY  (CY_c15_3_terminal_chain2_i19  ),
        .PROP(PROP_c15_3_terminal_chain2_i19));
    
    assign C0_c15_3_terminal_chain2_i19 = {terminal_chain2_i18, terminal_chain1_out[31], layer1_col58[2], layer1_col58[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i19    = terminal_chain1_out[32];
    
    
    assign CLA_c15_3_terminal_chain2_i19  = COUT_LA_terminal_chain2[17];
    assign terminal_chain2_i19            = O_c15_3_terminal_chain2_i19[2];
    assign CY_LA_terminal_chain2[36:35]   = CY_c15_3_terminal_chain2_i19;
    assign PROP_LA_terminal_chain2[36:35] = PROP_c15_3_terminal_chain2_i19;
    
    c15_3 #(.C0_INV(5'h4),
            .OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE")) c15_3_terminal_chain2_i20(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain2_i20  ),
        .C1  (C1_c15_3_terminal_chain2_i20  ),
        .CLA (CLA_c15_3_terminal_chain2_i20 ),
        .O   (O_c15_3_terminal_chain2_i20   ),
        .CY  (CY_c15_3_terminal_chain2_i20  ),
        .PROP(PROP_c15_3_terminal_chain2_i20));
    
    assign C0_c15_3_terminal_chain2_i20 = {terminal_chain2_i19, terminal_chain1_out[33], layer1_col60[3], layer1_col60[2], layer1_col60[1]};
    assign C1_c15_3_terminal_chain2_i20    = terminal_chain1_out[34];
    
    
    assign CLA_c15_3_terminal_chain2_i20  = COUT_LA_terminal_chain2[18];
    assign terminal_chain2_i20            = O_c15_3_terminal_chain2_i20[2];
    assign CY_LA_terminal_chain2[38:37]   = CY_c15_3_terminal_chain2_i20;
    assign PROP_LA_terminal_chain2[38:37] = PROP_c15_3_terminal_chain2_i20;
    
    c15_3 #(.C0_INV(5'h4),
            .OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("TRUE" ),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE")) c15_3_terminal_chain2_i21(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain2_i21  ),
        .C1  (C1_c15_3_terminal_chain2_i21  ),
        .CLA (CLA_c15_3_terminal_chain2_i21 ),
        .O   (O_c15_3_terminal_chain2_i21   ),
        .CY  (CY_c15_3_terminal_chain2_i21  ),
        .PROP(PROP_c15_3_terminal_chain2_i21));
    
    assign C0_c15_3_terminal_chain2_i21 = {terminal_chain2_i20, terminal_chain1_out[35], layer1_col62[2], layer1_col62[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i21    = terminal_chain1_out[36];
    
    
    assign CLA_c15_3_terminal_chain2_i21  = COUT_LA_terminal_chain2[19];
    assign terminal_chain2_i21            = O_c15_3_terminal_chain2_i21[2];
    assign CY_LA_terminal_chain2[40:39]   = CY_c15_3_terminal_chain2_i21;
    assign PROP_LA_terminal_chain2[40:39] = PROP_c15_3_terminal_chain2_i21;
    
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("TRUE" ))
    c3_2_terminal_chain2_i22(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i22  ),
        .O   (O_c3_2_terminal_chain2_i22   ),
        .CY  (CY_c3_2_terminal_chain2_i22  ),
        .PROP(PROP_c3_2_terminal_chain2_i22));
    
    assign C0_c3_2_terminal_chain2_i22 = {terminal_chain2_i21, 1'b0, terminal_chain1_out[37]};
    
    
    assign terminal_chain2_i22         = COUT_LA_terminal_chain2[20];
    assign CY_LA_terminal_chain2[41]   = CY_c3_2_terminal_chain2_i22;
    assign PROP_LA_terminal_chain2[41] = PROP_c3_2_terminal_chain2_i22;
    
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
    
        comp_out[25:23] <= terminal_chain2_out[2:0];
    
        comp_out[65:26] <= terminal_chain2_out[42:3];
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
    
    assign layer1_col60[3] = 1'b0;
    assign layer1_col62[2] = 1'b0;
endmodule