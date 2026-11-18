`timescale 1ns / 1ps

module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_p2_core_s4_bu_dp_w3mq_bitheap_cmp_56_ac7e01b123 (
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
    input  logic          in_col23,
    input  logic          in_col24,
    input  logic          in_col25,
    input  logic [2  : 0] in_col26,
    input  logic [1  : 0] in_col27,
    input  logic [3  : 0] in_col28,
    input  logic [2  : 0] in_col29,
    input  logic [4  : 0] in_col30,
    input  logic [3  : 0] in_col31,
    input  logic [5  : 0] in_col32,
    input  logic [4  : 0] in_col33,
    input  logic [6  : 0] in_col34,
    input  logic [5  : 0] in_col35,
    input  logic [7  : 0] in_col36,
    input  logic [5  : 0] in_col37,
    input  logic [8  : 0] in_col38,
    input  logic [6  : 0] in_col39,
    input  logic [7  : 0] in_col40,
    input  logic [6  : 0] in_col41,
    input  logic [7  : 0] in_col42,
    input  logic [6  : 0] in_col43,
    input  logic [7  : 0] in_col44,
    input  logic [6  : 0] in_col45,
    input  logic [5  : 0] in_col46,
    input  logic [5  : 0] in_col47,
    input  logic [4  : 0] in_col48,
    input  logic [4  : 0] in_col49,
    input  logic [3  : 0] in_col50,
    input  logic [3  : 0] in_col51,
    input  logic [2  : 0] in_col52,
    input  logic [2  : 0] in_col53,
    input  logic [1  : 0] in_col54,
    input  logic [1  : 0] in_col55,
    output logic [57 : 0] comp_out
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
    logic [2  : 0] layer0_col26;
    logic [1  : 0] layer0_col27;
    logic [3  : 0] layer0_col28;
    logic [2  : 0] layer0_col29;
    logic [4  : 0] layer0_col30;
    logic [3  : 0] layer0_col31;
    logic [5  : 0] layer0_col32;
    logic [4  : 0] layer0_col33;
    logic [6  : 0] layer0_col34;
    logic [5  : 0] layer0_col35;
    logic [7  : 0] layer0_col36;
    logic [5  : 0] layer0_col37;
    logic [8  : 0] layer0_col38;
    logic [6  : 0] layer0_col39;
    logic [7  : 0] layer0_col40;
    logic [6  : 0] layer0_col41;
    logic [7  : 0] layer0_col42;
    logic [6  : 0] layer0_col43;
    logic [7  : 0] layer0_col44;
    logic [6  : 0] layer0_col45;
    logic [5  : 0] layer0_col46;
    logic [5  : 0] layer0_col47;
    logic [4  : 0] layer0_col48;
    logic [4  : 0] layer0_col49;
    logic [3  : 0] layer0_col50;
    logic [3  : 0] layer0_col51;
    logic [2  : 0] layer0_col52;
    logic [2  : 0] layer0_col53;
    logic [1  : 0] layer0_col54;
    logic [1  : 0] layer0_col55;
    
    logic [11 : 0] COUT_LA_l0_c0_s0;
    logic [2  : 0] CIN_LA_l0_c0_s0;
    logic [23 : 0] CY_LA_l0_c0_s0;
    logic [23 : 0] PROP_LA_l0_c0_s0;
    
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
    
    logic [4 : 0] C0_c15_3_l0_c0_i3;
    logic         C1_c15_3_l0_c0_i3;
    logic         CLA_c15_3_l0_c0_i3;
    logic [2 : 0] O_c15_3_l0_c0_i3;
    logic [1 : 0] CY_c15_3_l0_c0_i3;
    logic [1 : 0] PROP_c15_3_l0_c0_i3;
    logic         l0_c0_i3;
    
    logic [4 : 0] C0_c15_3_l0_c0_i4;
    logic         C1_c15_3_l0_c0_i4;
    logic         CLA_c15_3_l0_c0_i4;
    logic [2 : 0] O_c15_3_l0_c0_i4;
    logic [1 : 0] CY_c15_3_l0_c0_i4;
    logic [1 : 0] PROP_c15_3_l0_c0_i4;
    logic         l0_c0_i4;
    
    logic [4 : 0] C0_c15_3_l0_c0_i5;
    logic         C1_c15_3_l0_c0_i5;
    logic         CLA_c15_3_l0_c0_i5;
    logic [2 : 0] O_c15_3_l0_c0_i5;
    logic [1 : 0] CY_c15_3_l0_c0_i5;
    logic [1 : 0] PROP_c15_3_l0_c0_i5;
    logic         l0_c0_i5;
    
    logic [4 : 0] C0_c15_3_l0_c0_i6;
    logic         C1_c15_3_l0_c0_i6;
    logic         CLA_c15_3_l0_c0_i6;
    logic [2 : 0] O_c15_3_l0_c0_i6;
    logic [1 : 0] CY_c15_3_l0_c0_i6;
    logic [1 : 0] PROP_c15_3_l0_c0_i6;
    logic         l0_c0_i6;
    
    logic [4 : 0] C0_c15_3_l0_c0_i7;
    logic         C1_c15_3_l0_c0_i7;
    logic         CLA_c15_3_l0_c0_i7;
    logic [2 : 0] O_c15_3_l0_c0_i7;
    logic [1 : 0] CY_c15_3_l0_c0_i7;
    logic [1 : 0] PROP_c15_3_l0_c0_i7;
    logic         l0_c0_i7;
    
    logic [4 : 0] C0_c15_3_l0_c0_i8;
    logic         C1_c15_3_l0_c0_i8;
    logic         CLA_c15_3_l0_c0_i8;
    logic [2 : 0] O_c15_3_l0_c0_i8;
    logic [1 : 0] CY_c15_3_l0_c0_i8;
    logic [1 : 0] PROP_c15_3_l0_c0_i8;
    logic         l0_c0_i8;
    
    logic [4 : 0] C0_c15_3_l0_c0_i9;
    logic         C1_c15_3_l0_c0_i9;
    logic         CLA_c15_3_l0_c0_i9;
    logic [2 : 0] O_c15_3_l0_c0_i9;
    logic [1 : 0] CY_c15_3_l0_c0_i9;
    logic [1 : 0] PROP_c15_3_l0_c0_i9;
    logic         l0_c0_i9;
    
    logic [2 : 0] C0_c3_2_l0_c0_i10;
    logic [1 : 0] O_c3_2_l0_c0_i10;
    logic         CY_c3_2_l0_c0_i10;
    logic         PROP_c3_2_l0_c0_i10;
    logic         l0_c0_i10;
    
    logic [2 : 0] C0_c3_2_l0_c0_i11;
    logic [1 : 0] O_c3_2_l0_c0_i11;
    logic         CY_c3_2_l0_c0_i11;
    logic         PROP_c3_2_l0_c0_i11;
    logic         l0_c0_i11;
    
    logic [2 : 0] C0_c3_2_l0_c0_i12;
    logic [1 : 0] O_c3_2_l0_c0_i12;
    logic         CY_c3_2_l0_c0_i12;
    logic         PROP_c3_2_l0_c0_i12;
    logic         l0_c0_i12;
    
    logic [2 : 0] C0_c3_2_l0_c0_i13;
    logic [1 : 0] O_c3_2_l0_c0_i13;
    logic         CY_c3_2_l0_c0_i13;
    logic         PROP_c3_2_l0_c0_i13;
    logic         l0_c0_i13;
    
    logic [11 : 0] COUT_LA_l0_c1_s0;
    logic [2  : 0] CIN_LA_l0_c1_s0;
    logic [23 : 0] CY_LA_l0_c1_s0;
    logic [23 : 0] PROP_LA_l0_c1_s0;
    
    (* dont_touch = "true" *) logic [2 : 0] C0_c3_2_l0_c1_i0;
    logic [1 : 0] O_c3_2_l0_c1_i0;
    logic         CY_c3_2_l0_c1_i0;
    logic         PROP_c3_2_l0_c1_i0;
    logic         l0_c1_i0;
    
    logic [2 : 0] C0_c3_2_l0_c1_i1;
    logic [1 : 0] O_c3_2_l0_c1_i1;
    logic         CY_c3_2_l0_c1_i1;
    logic         PROP_c3_2_l0_c1_i1;
    logic         l0_c1_i1;
    
    logic [4 : 0] C0_c15_3_l0_c1_i2;
    logic         C1_c15_3_l0_c1_i2;
    logic         CLA_c15_3_l0_c1_i2;
    logic [2 : 0] O_c15_3_l0_c1_i2;
    logic [1 : 0] CY_c15_3_l0_c1_i2;
    logic [1 : 0] PROP_c15_3_l0_c1_i2;
    logic         l0_c1_i2;
    
    logic [4 : 0] C0_c15_3_l0_c1_i3;
    logic         C1_c15_3_l0_c1_i3;
    logic         CLA_c15_3_l0_c1_i3;
    logic [2 : 0] O_c15_3_l0_c1_i3;
    logic [1 : 0] CY_c15_3_l0_c1_i3;
    logic [1 : 0] PROP_c15_3_l0_c1_i3;
    logic         l0_c1_i3;
    
    logic [4 : 0] C0_c15_3_l0_c1_i4;
    logic         C1_c15_3_l0_c1_i4;
    logic         CLA_c15_3_l0_c1_i4;
    logic [2 : 0] O_c15_3_l0_c1_i4;
    logic [1 : 0] CY_c15_3_l0_c1_i4;
    logic [1 : 0] PROP_c15_3_l0_c1_i4;
    logic         l0_c1_i4;
    
    logic [4 : 0] C0_c15_3_l0_c1_i5;
    logic         C1_c15_3_l0_c1_i5;
    logic         CLA_c15_3_l0_c1_i5;
    logic [2 : 0] O_c15_3_l0_c1_i5;
    logic [1 : 0] CY_c15_3_l0_c1_i5;
    logic [1 : 0] PROP_c15_3_l0_c1_i5;
    logic         l0_c1_i5;
    
    logic [4 : 0] C0_c15_3_l0_c1_i6;
    logic         C1_c15_3_l0_c1_i6;
    logic         CLA_c15_3_l0_c1_i6;
    logic [2 : 0] O_c15_3_l0_c1_i6;
    logic [1 : 0] CY_c15_3_l0_c1_i6;
    logic [1 : 0] PROP_c15_3_l0_c1_i6;
    logic         l0_c1_i6;
    
    logic [4 : 0] C0_c15_3_l0_c1_i7;
    logic         C1_c15_3_l0_c1_i7;
    logic         CLA_c15_3_l0_c1_i7;
    logic [2 : 0] O_c15_3_l0_c1_i7;
    logic [1 : 0] CY_c15_3_l0_c1_i7;
    logic [1 : 0] PROP_c15_3_l0_c1_i7;
    logic         l0_c1_i7;
    
    logic [4 : 0] C0_c15_3_l0_c1_i8;
    logic         C1_c15_3_l0_c1_i8;
    logic         CLA_c15_3_l0_c1_i8;
    logic [2 : 0] O_c15_3_l0_c1_i8;
    logic [1 : 0] CY_c15_3_l0_c1_i8;
    logic [1 : 0] PROP_c15_3_l0_c1_i8;
    logic         l0_c1_i8;
    
    logic [2 : 0] C0_c3_2_l0_c1_i9;
    logic [1 : 0] O_c3_2_l0_c1_i9;
    logic         CY_c3_2_l0_c1_i9;
    logic         PROP_c3_2_l0_c1_i9;
    logic         l0_c1_i9;
    
    logic [2 : 0] C0_c3_2_l0_f0;
    logic [1 : 0] O_c3_2_l0_i0;
    logic         CY_c3_2_l0_f0;
    logic         PROP_c3_2_l0_f0;
    
    logic [3 : 0] COUT_LA_l0_c2_s0;
    logic         CIN_LA_l0_c2_s0;
    logic [7 : 0] CY_LA_l0_c2_s0;
    logic [7 : 0] PROP_LA_l0_c2_s0;
    
    (* dont_touch = "true" *) logic [2 : 0] C0_c223_4_l0_c2_i0;
    logic [1 : 0] C1_c223_4_l0_c2_i0;
    logic [1 : 0] C2_c223_4_l0_c2_i0;
    logic         CLA_c223_4_l0_c2_i0;
    logic [3 : 0] O_c223_4_l0_c2_i0;
    logic [1 : 0] CY_c223_4_l0_c2_i0;
    logic [1 : 0] PROP_c223_4_l0_c2_i0;
    logic         l0_c2_i0;
    
    logic [2 : 0] C0_c223_4_l0_c2_i1;
    logic [1 : 0] C1_c223_4_l0_c2_i1;
    logic [1 : 0] C2_c223_4_l0_c2_i1;
    logic         CLA_c223_4_l0_c2_i1;
    logic [3 : 0] O_c223_4_l0_c2_i1;
    logic [1 : 0] CY_c223_4_l0_c2_i1;
    logic [1 : 0] PROP_c223_4_l0_c2_i1;
    logic         l0_c2_i1;
    
    logic [3 : 0] COUT_LA_l0_c3_s0;
    logic         CIN_LA_l0_c3_s0;
    logic [7 : 0] CY_LA_l0_c3_s0;
    logic [7 : 0] PROP_LA_l0_c3_s0;
    
    (* dont_touch = "true" *) logic [2 : 0] C0_c3_2_l0_c3_i0;
    logic [1 : 0] O_c3_2_l0_c3_i0;
    logic         CY_c3_2_l0_c3_i0;
    logic         PROP_c3_2_l0_c3_i0;
    logic         l0_c3_i0;
    
    logic [2 : 0] C0_c3_2_l0_c3_i1;
    logic [1 : 0] O_c3_2_l0_c3_i1;
    logic         CY_c3_2_l0_c3_i1;
    logic         PROP_c3_2_l0_c3_i1;
    logic         l0_c3_i1;
    
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
    logic [2  : 0] layer1_col26;
    logic [1  : 0] layer1_col27;
    logic [3  : 0] layer1_col28;
    logic [2  : 0] layer1_col29;
    logic [2  : 0] layer1_col30;
    logic [2  : 0] layer1_col31;
    logic [2  : 0] layer1_col32;
    logic [2  : 0] layer1_col33;
    logic [2  : 0] layer1_col34;
    logic [2  : 0] layer1_col35;
    logic [2  : 0] layer1_col36;
    logic [3  : 0] layer1_col37;
    logic [3  : 0] layer1_col38;
    logic [2  : 0] layer1_col39;
    logic [3  : 0] layer1_col40;
    logic [2  : 0] layer1_col41;
    logic [3  : 0] layer1_col42;
    logic [2  : 0] layer1_col43;
    logic [3  : 0] layer1_col44;
    logic [2  : 0] layer1_col45;
    logic [3  : 0] layer1_col46;
    logic [2  : 0] layer1_col47;
    logic [3  : 0] layer1_col48;
    logic [2  : 0] layer1_col49;
    logic [3  : 0] layer1_col50;
    logic [2  : 0] layer1_col51;
    logic [3  : 0] layer1_col52;
    logic [2  : 0] layer1_col53;
    logic [1  : 0] layer1_col54;
    logic [1  : 0] layer1_col55;
    
    logic [30 : 0] terminal_chain1_out;
    
    logic [15 : 0] COUT_LA_terminal_chain1;
    logic [3  : 0] CIN_LA_terminal_chain1;
    logic [31 : 0] CY_LA_terminal_chain1;
    logic [31 : 0] PROP_LA_terminal_chain1;
    
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
    
    logic [28 : 0] terminal_chain2_out;
    
    logic [15 : 0] COUT_LA_terminal_chain2;
    logic [3  : 0] CIN_LA_terminal_chain2;
    logic [31 : 0] CY_LA_terminal_chain2;
    logic [31 : 0] PROP_LA_terminal_chain2;
    
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
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i13;
    logic [1 : 0] O_c3_2_terminal_chain2_i13;
    logic         CY_c3_2_terminal_chain2_i13;
    logic         PROP_c3_2_terminal_chain2_i13;
    logic         terminal_chain2_i13;
    
    logic [2 : 0] C0_c3_2_terminal_chain2_i14;
    logic [1 : 0] O_c3_2_terminal_chain2_i14;
    logic         CY_c3_2_terminal_chain2_i14;
    logic         PROP_c3_2_terminal_chain2_i14;
    logic         terminal_chain2_i14;
    
    // ------------------------------ LAYER 0 ------------------------------
    // GPC chain0 in layer0:
    // -- (3 : 2] at column 30
    // -- (3 : 2] at column 31
    // -- (1,5 : 3] at column 32
    // -- (1,5 : 3] at column 34
    // -- (1,5 : 3] at column 36
    // -- (1,5 : 3] at column 38
    // -- (1,5 : 3] at column 40
    // -- (1,5 : 3] at column 42
    // -- (1,5 : 3] at column 44
    // -- (1,5 : 3] at column 46
    // -- (3 : 2] at column 48
    // -- (3 : 2] at column 49
    // -- (3 : 2] at column 50
    // -- (3 : 2] at column 51
    
    LOOKAHEAD8 #(
        .LOOKB("FALSE"),
        .LOOKD("TRUE" ),
        .LOOKF("TRUE" ),
        .LOOKH("TRUE" ))
    LOOKAHEAD8_l0_c0_s0_inst0 (
        .COUTB(COUT_LA_l0_c0_s0[0]),
        .COUTD(COUT_LA_l0_c0_s0[1]),
        .COUTF(COUT_LA_l0_c0_s0[2]),
        .COUTH(COUT_LA_l0_c0_s0[3]),
        .CIN  (CIN_LA_l0_c0_s0[0] ),
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

    LOOKAHEAD8 #(
        .LOOKB("TRUE"),
        .LOOKD("TRUE"),
        .LOOKF("TRUE"),
        .LOOKH("TRUE"))
    LOOKAHEAD8_l0_c0_s0_inst1 (
        .COUTB(COUT_LA_l0_c0_s0[4] ),
        .COUTD(COUT_LA_l0_c0_s0[5] ),
        .COUTF(COUT_LA_l0_c0_s0[6] ),
        .COUTH(COUT_LA_l0_c0_s0[7] ),
        .CIN  (CIN_LA_l0_c0_s0[1]  ),
        .CYA  (CY_LA_l0_c0_s0[8]   ),
        .CYB  (CY_LA_l0_c0_s0[9]   ),
        .CYC  (CY_LA_l0_c0_s0[10]  ),
        .CYD  (CY_LA_l0_c0_s0[11]  ),
        .CYE  (CY_LA_l0_c0_s0[12]  ),
        .CYF  (CY_LA_l0_c0_s0[13]  ),
        .CYG  (CY_LA_l0_c0_s0[14]  ),
        .CYH  (CY_LA_l0_c0_s0[15]  ),
        .PROPA(PROP_LA_l0_c0_s0[8] ),
        .PROPB(PROP_LA_l0_c0_s0[9] ),
        .PROPC(PROP_LA_l0_c0_s0[10]),
        .PROPD(PROP_LA_l0_c0_s0[11]),
        .PROPE(PROP_LA_l0_c0_s0[12]),
        .PROPF(PROP_LA_l0_c0_s0[13]),
        .PROPG(PROP_LA_l0_c0_s0[14]),
        .PROPH(PROP_LA_l0_c0_s0[15]));

    LOOKAHEAD8 #(
        .LOOKB("TRUE" ),
        .LOOKD("TRUE" ),
        .LOOKF("FALSE"),
        .LOOKH("FALSE"))
    LOOKAHEAD8_l0_c0_s0_inst2 (
        .COUTB(COUT_LA_l0_c0_s0[8] ),
        .COUTD(COUT_LA_l0_c0_s0[9] ),
        .COUTF(COUT_LA_l0_c0_s0[10]),
        .COUTH(COUT_LA_l0_c0_s0[11]),
        .CIN  (CIN_LA_l0_c0_s0[2]  ),
        .CYA  (CY_LA_l0_c0_s0[16]  ),
        .CYB  (CY_LA_l0_c0_s0[17]  ),
        .CYC  (CY_LA_l0_c0_s0[18]  ),
        .CYD  (CY_LA_l0_c0_s0[19]  ),
        .CYE  (CY_LA_l0_c0_s0[20]  ),
        .CYF  (CY_LA_l0_c0_s0[21]  ),
        .CYG  (CY_LA_l0_c0_s0[22]  ),
        .CYH  (CY_LA_l0_c0_s0[23]  ),
        .PROPA(PROP_LA_l0_c0_s0[16]),
        .PROPB(PROP_LA_l0_c0_s0[17]),
        .PROPC(PROP_LA_l0_c0_s0[18]),
        .PROPD(PROP_LA_l0_c0_s0[19]),
        .PROPE(PROP_LA_l0_c0_s0[20]),
        .PROPF(PROP_LA_l0_c0_s0[21]),
        .PROPG(PROP_LA_l0_c0_s0[22]),
        .PROPH(PROP_LA_l0_c0_s0[23]));

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
    
    assign C0_c3_2_l0_c0_i0 = layer0_col30[2:0];
    
    assign layer1_col30[0] = O_c3_2_l0_c0_i0[0];
    
    assign l0_c0_i0            = O_c3_2_l0_c0_i0[1];
    assign CY_LA_l0_c0_s0[0]   = CY_c3_2_l0_c0_i0;
    assign PROP_LA_l0_c0_s0[0] = PROP_c3_2_l0_c0_i0;
    
    assign CIN_LA_l0_c0_s0 = {COUT_LA_l0_c0_s0[7], COUT_LA_l0_c0_s0[3], C0_c3_2_l0_c0_i0[2]};
    
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
    
    assign C0_c3_2_l0_c0_i1 = {l0_c0_i0, layer0_col31[1:0]};
    
    assign layer1_col31[0] = O_c3_2_l0_c0_i1[0];
    
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
    
    assign C0_c15_3_l0_c0_i2 = {l0_c0_i1, layer0_col32[3:0]};
    assign C1_c15_3_l0_c0_i2 = layer0_col33[0];
    
    assign layer1_col32[0] = O_c15_3_l0_c0_i2[0];
    assign layer1_col33[0] = O_c15_3_l0_c0_i2[1];
    
    assign l0_c0_i2              = COUT_LA_l0_c0_s0[1];
    assign CY_LA_l0_c0_s0[3:2]   = CY_c15_3_l0_c0_i2;
    assign PROP_LA_l0_c0_s0[3:2] = PROP_c15_3_l0_c0_i2;
    
    c15_3 #(.OUTREG("TRUE" ),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_l0_c0_i3(
        .clk (clk                ),
        .C0  (C0_c15_3_l0_c0_i3  ),
        .C1  (C1_c15_3_l0_c0_i3  ),
        .CLA (CLA_c15_3_l0_c0_i3 ),
        .O   (O_c15_3_l0_c0_i3   ),
        .CY  (CY_c15_3_l0_c0_i3  ),
        .PROP(PROP_c15_3_l0_c0_i3));
    
    assign C0_c15_3_l0_c0_i3 = {l0_c0_i2, layer0_col34[3:0]};
    assign C1_c15_3_l0_c0_i3 = layer0_col35[0];
    
    assign layer1_col34[0] = O_c15_3_l0_c0_i3[0];
    assign layer1_col35[0] = O_c15_3_l0_c0_i3[1];
    
    assign l0_c0_i3              = COUT_LA_l0_c0_s0[2];
    assign CY_LA_l0_c0_s0[5:4]   = CY_c15_3_l0_c0_i3;
    assign PROP_LA_l0_c0_s0[5:4] = PROP_c15_3_l0_c0_i3;
    
    c15_3 #(.OUTREG("TRUE" ),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_l0_c0_i4(
        .clk (clk                ),
        .C0  (C0_c15_3_l0_c0_i4  ),
        .C1  (C1_c15_3_l0_c0_i4  ),
        .CLA (CLA_c15_3_l0_c0_i4 ),
        .O   (O_c15_3_l0_c0_i4   ),
        .CY  (CY_c15_3_l0_c0_i4  ),
        .PROP(PROP_c15_3_l0_c0_i4));
    
    assign C0_c15_3_l0_c0_i4 = {l0_c0_i3, layer0_col36[3:0]};
    assign C1_c15_3_l0_c0_i4 = layer0_col37[0];
    
    assign layer1_col36 = {O_c3_2_l0_i0[0], O_c15_3_l0_c1_i2[1], O_c15_3_l0_c0_i4[0]};
    assign layer1_col37[0] = O_c15_3_l0_c0_i4[1];
    
    assign l0_c0_i4              = COUT_LA_l0_c0_s0[3];
    assign CY_LA_l0_c0_s0[7:6]   = CY_c15_3_l0_c0_i4;
    assign PROP_LA_l0_c0_s0[7:6] = PROP_c15_3_l0_c0_i4;
    
    c15_3 #(.OUTREG("TRUE" ),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_l0_c0_i5(
        .clk (clk                ),
        .C0  (C0_c15_3_l0_c0_i5  ),
        .C1  (C1_c15_3_l0_c0_i5  ),
        .CLA (CLA_c15_3_l0_c0_i5 ),
        .O   (O_c15_3_l0_c0_i5   ),
        .CY  (CY_c15_3_l0_c0_i5  ),
        .PROP(PROP_c15_3_l0_c0_i5));
    
    assign C0_c15_3_l0_c0_i5 = {l0_c0_i4, layer0_col38[3:0]};
    assign C1_c15_3_l0_c0_i5 = layer0_col39[0];
    
    assign layer1_col38 = {1'b0, O_c223_4_l0_c2_i0[0], O_c15_3_l0_c1_i3[1], O_c15_3_l0_c0_i5[0]};
    assign layer1_col39 = {O_c223_4_l0_c2_i0[1], O_c15_3_l0_c1_i4[0], O_c15_3_l0_c0_i5[1]};
    
    assign l0_c0_i5              = COUT_LA_l0_c0_s0[4];
    assign CY_LA_l0_c0_s0[9:8]   = CY_c15_3_l0_c0_i5;
    assign PROP_LA_l0_c0_s0[9:8] = PROP_c15_3_l0_c0_i5;
    
    
    c15_3 #(.OUTREG("TRUE" ),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_l0_c0_i6(
        .clk (clk                ),
        .C0  (C0_c15_3_l0_c0_i6  ),
        .C1  (C1_c15_3_l0_c0_i6  ),
        .CLA (CLA_c15_3_l0_c0_i6 ),
        .O   (O_c15_3_l0_c0_i6   ),
        .CY  (CY_c15_3_l0_c0_i6  ),
        .PROP(PROP_c15_3_l0_c0_i6));
    
    assign C0_c15_3_l0_c0_i6 = {l0_c0_i5, layer0_col40[3:0]};
    assign C1_c15_3_l0_c0_i6 = layer0_col41[0];
    
    assign layer1_col40[0] = O_c15_3_l0_c0_i6[0];
    assign layer1_col41 = {O_c223_4_l0_c2_i1[0], O_c15_3_l0_c1_i5[0], O_c15_3_l0_c0_i6[1]};
    
    assign l0_c0_i6                = COUT_LA_l0_c0_s0[5];
    assign CY_LA_l0_c0_s0[11:10]   = CY_c15_3_l0_c0_i6;
    assign PROP_LA_l0_c0_s0[11:10] = PROP_c15_3_l0_c0_i6;
    
    c15_3 #(.OUTREG("TRUE" ),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_l0_c0_i7(
        .clk (clk                ),
        .C0  (C0_c15_3_l0_c0_i7  ),
        .C1  (C1_c15_3_l0_c0_i7  ),
        .CLA (CLA_c15_3_l0_c0_i7 ),
        .O   (O_c15_3_l0_c0_i7   ),
        .CY  (CY_c15_3_l0_c0_i7  ),
        .PROP(PROP_c15_3_l0_c0_i7));
    
    assign C0_c15_3_l0_c0_i7 = {l0_c0_i6, layer0_col42[3:0]};
    assign C1_c15_3_l0_c0_i7 = layer0_col43[0];
    
    assign layer1_col42[0] = O_c15_3_l0_c0_i7[0];
    assign layer1_col43 = {O_c223_4_l0_c2_i1[2], O_c15_3_l0_c1_i6[0], O_c15_3_l0_c0_i7[1]};
    
    assign l0_c0_i7                = COUT_LA_l0_c0_s0[6];
    assign CY_LA_l0_c0_s0[13:12]   = CY_c15_3_l0_c0_i7;
    assign PROP_LA_l0_c0_s0[13:12] = PROP_c15_3_l0_c0_i7;
    
    c15_3 #(.OUTREG("TRUE" ),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_l0_c0_i8(
        .clk (clk                ),
        .C0  (C0_c15_3_l0_c0_i8  ),
        .C1  (C1_c15_3_l0_c0_i8  ),
        .CLA (CLA_c15_3_l0_c0_i8 ),
        .O   (O_c15_3_l0_c0_i8   ),
        .CY  (CY_c15_3_l0_c0_i8  ),
        .PROP(PROP_c15_3_l0_c0_i8));
    
    assign C0_c15_3_l0_c0_i8 = {l0_c0_i7, layer0_col44[3:0]};
    assign C1_c15_3_l0_c0_i8 = layer0_col45[0];
    
    assign layer1_col44 = {O_c3_2_l0_c3_i0[0], O_c223_4_l0_c2_i1[3], O_c15_3_l0_c1_i6[1], O_c15_3_l0_c0_i8[0]};
    assign layer1_col45 = {O_c3_2_l0_c3_i1[0], O_c15_3_l0_c1_i7[0], O_c15_3_l0_c0_i8[1]};
    
    assign l0_c0_i8                = COUT_LA_l0_c0_s0[7];
    assign CY_LA_l0_c0_s0[15:14]   = CY_c15_3_l0_c0_i8;
    assign PROP_LA_l0_c0_s0[15:14] = PROP_c15_3_l0_c0_i8;
    
    c15_3 #(.OUTREG("TRUE" ),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_l0_c0_i9(
        .clk (clk                ),
        .C0  (C0_c15_3_l0_c0_i9  ),
        .C1  (C1_c15_3_l0_c0_i9  ),
        .CLA (CLA_c15_3_l0_c0_i9 ),
        .O   (O_c15_3_l0_c0_i9   ),
        .CY  (CY_c15_3_l0_c0_i9  ),
        .PROP(PROP_c15_3_l0_c0_i9));
    
    assign C0_c15_3_l0_c0_i9 = {l0_c0_i8, layer0_col46[3:0]};
    assign C1_c15_3_l0_c0_i9 = layer0_col47[0];
    
    assign layer1_col46[0] = O_c15_3_l0_c0_i9[0];
    assign layer1_col47 = {1'b0, O_c15_3_l0_c1_i8[0], O_c15_3_l0_c0_i9[1]};
    
    assign l0_c0_i9                = COUT_LA_l0_c0_s0[8];
    assign CY_LA_l0_c0_s0[17:16]   = CY_c15_3_l0_c0_i9;
    assign PROP_LA_l0_c0_s0[17:16] = PROP_c15_3_l0_c0_i9;
    
    
    c3_2 #(.OUTREG("TRUE" ),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_l0_c0_i10(
        .clk (clk                ),
        .C0  (C0_c3_2_l0_c0_i10  ),
        .O   (O_c3_2_l0_c0_i10   ),
        .CY  (CY_c3_2_l0_c0_i10  ),
        .PROP(PROP_c3_2_l0_c0_i10));
    
    assign C0_c3_2_l0_c0_i10 = {l0_c0_i9, layer0_col48[1:0]};
    
    assign layer1_col48[0] = O_c3_2_l0_c0_i10[0];
    
    assign l0_c0_i10            = O_c3_2_l0_c0_i10[1];
    assign CY_LA_l0_c0_s0[18]   = CY_c3_2_l0_c0_i10;
    assign PROP_LA_l0_c0_s0[18] = PROP_c3_2_l0_c0_i10;
    
    c3_2 #(.OUTREG("TRUE" ),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_l0_c0_i11(
        .clk (clk                ),
        .C0  (C0_c3_2_l0_c0_i11  ),
        .O   (O_c3_2_l0_c0_i11   ),
        .CY  (CY_c3_2_l0_c0_i11  ),
        .PROP(PROP_c3_2_l0_c0_i11));
    
    assign C0_c3_2_l0_c0_i11 = {l0_c0_i10, layer0_col49[1:0]};
    
    assign layer1_col49 = {1'b0, O_c3_2_l0_c1_i9[0], O_c3_2_l0_c0_i11[0]};
    
    assign l0_c0_i11            = COUT_LA_l0_c0_s0[9];
    assign CY_LA_l0_c0_s0[19]   = CY_c3_2_l0_c0_i11;
    assign PROP_LA_l0_c0_s0[19] = PROP_c3_2_l0_c0_i11;
    
    c3_2 #(.OUTREG("TRUE" ),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_l0_c0_i12(
        .clk (clk                ),
        .C0  (C0_c3_2_l0_c0_i12  ),
        .O   (O_c3_2_l0_c0_i12   ),
        .CY  (CY_c3_2_l0_c0_i12  ),
        .PROP(PROP_c3_2_l0_c0_i12));
    
    assign C0_c3_2_l0_c0_i12 = {l0_c0_i11, layer0_col50[1:0]};
    
    assign layer1_col50[0] = O_c3_2_l0_c0_i12[0];
    
    assign l0_c0_i12            = O_c3_2_l0_c0_i12[1];
    assign CY_LA_l0_c0_s0[20]   = CY_c3_2_l0_c0_i12;
    assign PROP_LA_l0_c0_s0[20] = PROP_c3_2_l0_c0_i12;
    
    c3_2 #(.OUTREG("TRUE" ),
           .LEAVEC("FALSE"),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("TRUE" ))
    c3_2_l0_c0_i13(
        .clk (clk                ),
        .C0  (C0_c3_2_l0_c0_i13  ),
        .O   (O_c3_2_l0_c0_i13   ),
        .CY  (CY_c3_2_l0_c0_i13  ),
        .PROP(PROP_c3_2_l0_c0_i13));
    
    assign C0_c3_2_l0_c0_i13 = {l0_c0_i12, layer0_col51[1:0]};
    
    assign layer1_col51[0] = O_c3_2_l0_c0_i13[0];
    assign layer1_col52[0] = O_c3_2_l0_c0_i13[1];
    
    assign l0_c0_i13            = COUT_LA_l0_c0_s0[10];
    assign CY_LA_l0_c0_s0[21]   = CY_c3_2_l0_c0_i13;
    assign PROP_LA_l0_c0_s0[21] = PROP_c3_2_l0_c0_i13;
    
    // GPC chain1 in layer0:
    // -- (3 : 2] at column 33
    // -- (3 : 2] at column 34
    // -- (1,5 : 3] at column 35
    // -- (1,5 : 3] at column 37
    // -- (1,5 : 3] at column 39
    // -- (1,5 : 3] at column 41
    // -- (1,5 : 3] at column 43
    // -- (1,5 : 3] at column 45
    // -- (1,5 : 3] at column 47
    // -- (3 : 2] at column 49
    
    LOOKAHEAD8 #(
        .LOOKB("FALSE"),
        .LOOKD("TRUE" ),
        .LOOKF("TRUE" ),
        .LOOKH("TRUE" ))
    LOOKAHEAD8_l0_c1_s0_inst0 (
        .COUTB(COUT_LA_l0_c1_s0[0]),
        .COUTD(COUT_LA_l0_c1_s0[1]),
        .COUTF(COUT_LA_l0_c1_s0[2]),
        .COUTH(COUT_LA_l0_c1_s0[3]),
        .CIN  (CIN_LA_l0_c1_s0[0] ),
        .CYA  (CY_LA_l0_c1_s0[0]  ),
        .CYB  (CY_LA_l0_c1_s0[1]  ),
        .CYC  (CY_LA_l0_c1_s0[2]  ),
        .CYD  (CY_LA_l0_c1_s0[3]  ),
        .CYE  (CY_LA_l0_c1_s0[4]  ),
        .CYF  (CY_LA_l0_c1_s0[5]  ),
        .CYG  (CY_LA_l0_c1_s0[6]  ),
        .CYH  (CY_LA_l0_c1_s0[7]  ),
        .PROPA(PROP_LA_l0_c1_s0[0]),
        .PROPB(PROP_LA_l0_c1_s0[1]),
        .PROPC(PROP_LA_l0_c1_s0[2]),
        .PROPD(PROP_LA_l0_c1_s0[3]),
        .PROPE(PROP_LA_l0_c1_s0[4]),
        .PROPF(PROP_LA_l0_c1_s0[5]),
        .PROPG(PROP_LA_l0_c1_s0[6]),
        .PROPH(PROP_LA_l0_c1_s0[7]));

    LOOKAHEAD8 #(
        .LOOKB("TRUE"),
        .LOOKD("TRUE"),
        .LOOKF("TRUE"),
        .LOOKH("TRUE"))
    LOOKAHEAD8_l0_c1_s0_inst1 (
        .COUTB(COUT_LA_l0_c1_s0[4] ),
        .COUTD(COUT_LA_l0_c1_s0[5] ),
        .COUTF(COUT_LA_l0_c1_s0[6] ),
        .COUTH(COUT_LA_l0_c1_s0[7] ),
        .CIN  (CIN_LA_l0_c1_s0[1]  ),
        .CYA  (CY_LA_l0_c1_s0[8]   ),
        .CYB  (CY_LA_l0_c1_s0[9]   ),
        .CYC  (CY_LA_l0_c1_s0[10]  ),
        .CYD  (CY_LA_l0_c1_s0[11]  ),
        .CYE  (CY_LA_l0_c1_s0[12]  ),
        .CYF  (CY_LA_l0_c1_s0[13]  ),
        .CYG  (CY_LA_l0_c1_s0[14]  ),
        .CYH  (CY_LA_l0_c1_s0[15]  ),
        .PROPA(PROP_LA_l0_c1_s0[8] ),
        .PROPB(PROP_LA_l0_c1_s0[9] ),
        .PROPC(PROP_LA_l0_c1_s0[10]),
        .PROPD(PROP_LA_l0_c1_s0[11]),
        .PROPE(PROP_LA_l0_c1_s0[12]),
        .PROPF(PROP_LA_l0_c1_s0[13]),
        .PROPG(PROP_LA_l0_c1_s0[14]),
        .PROPH(PROP_LA_l0_c1_s0[15]));

    LOOKAHEAD8 #(
        .LOOKB("FALSE"),
        .LOOKD("FALSE"),
        .LOOKF("FALSE"),
        .LOOKH("FALSE"))
    LOOKAHEAD8_l0_c1_s0_inst2 (
        .COUTB(COUT_LA_l0_c1_s0[8] ),
        .COUTD(COUT_LA_l0_c1_s0[9] ),
        .COUTF(COUT_LA_l0_c1_s0[10]),
        .COUTH(COUT_LA_l0_c1_s0[11]),
        .CIN  (CIN_LA_l0_c1_s0[2]  ),
        .CYA  (CY_LA_l0_c1_s0[16]  ),
        .CYB  (CY_LA_l0_c1_s0[17]  ),
        .CYC  (CY_LA_l0_c1_s0[18]  ),
        .CYD  (CY_LA_l0_c1_s0[19]  ),
        .CYE  (CY_LA_l0_c1_s0[20]  ),
        .CYF  (CY_LA_l0_c1_s0[21]  ),
        .CYG  (CY_LA_l0_c1_s0[22]  ),
        .CYH  (CY_LA_l0_c1_s0[23]  ),
        .PROPA(PROP_LA_l0_c1_s0[16]),
        .PROPB(PROP_LA_l0_c1_s0[17]),
        .PROPC(PROP_LA_l0_c1_s0[18]),
        .PROPD(PROP_LA_l0_c1_s0[19]),
        .PROPE(PROP_LA_l0_c1_s0[20]),
        .PROPF(PROP_LA_l0_c1_s0[21]),
        .PROPG(PROP_LA_l0_c1_s0[22]),
        .PROPH(PROP_LA_l0_c1_s0[23]));

    c3_2 #(.OUTREG("TRUE" ),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("TRUE" ),
           .LASTS ("FALSE"))
    c3_2_l0_c1_i0(
        .clk (clk               ),
        .C0  (C0_c3_2_l0_c1_i0  ),
        .O   (O_c3_2_l0_c1_i0   ),
        .CY  (CY_c3_2_l0_c1_i0  ),
        .PROP(PROP_c3_2_l0_c1_i0));
    
    assign C0_c3_2_l0_c1_i0 = layer0_col33[3:1];
    
    assign layer1_col33[1] = O_c3_2_l0_c1_i0[0];
    
    assign l0_c1_i0            = O_c3_2_l0_c1_i0[1];
    assign CY_LA_l0_c1_s0[0]   = CY_c3_2_l0_c1_i0;
    assign PROP_LA_l0_c1_s0[0] = PROP_c3_2_l0_c1_i0;
    
    assign CIN_LA_l0_c1_s0 = {COUT_LA_l0_c1_s0[7], COUT_LA_l0_c1_s0[3], C0_c3_2_l0_c1_i0[2]};
    
    c3_2 #(.OUTREG("TRUE" ),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("TRUE" ),
           .LASTS ("FALSE"))
    c3_2_l0_c1_i1(
        .clk (clk               ),
        .C0  (C0_c3_2_l0_c1_i1  ),
        .O   (O_c3_2_l0_c1_i1   ),
        .CY  (CY_c3_2_l0_c1_i1  ),
        .PROP(PROP_c3_2_l0_c1_i1));
    
    assign C0_c3_2_l0_c1_i1 = {l0_c1_i0, layer0_col34[5:4]};
    
    assign layer1_col34[1] = O_c3_2_l0_c1_i1[0];
    
    assign l0_c1_i1            = COUT_LA_l0_c1_s0[0];
    assign CY_LA_l0_c1_s0[1]   = CY_c3_2_l0_c1_i1;
    assign PROP_LA_l0_c1_s0[1] = PROP_c3_2_l0_c1_i1;
    
    c15_3 #(.OUTREG("TRUE" ),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_l0_c1_i2(
        .clk (clk                ),
        .C0  (C0_c15_3_l0_c1_i2  ),
        .C1  (C1_c15_3_l0_c1_i2  ),
        .CLA (CLA_c15_3_l0_c1_i2 ),
        .O   (O_c15_3_l0_c1_i2   ),
        .CY  (CY_c15_3_l0_c1_i2  ),
        .PROP(PROP_c15_3_l0_c1_i2));
    
    assign C0_c15_3_l0_c1_i2 = {l0_c1_i1, layer0_col35[4:1]};
    assign C1_c15_3_l0_c1_i2 = layer0_col36[4];
    
    assign layer1_col35[1] = O_c15_3_l0_c1_i2[0];
    
    assign l0_c1_i2              = COUT_LA_l0_c1_s0[1];
    assign CY_LA_l0_c1_s0[3:2]   = CY_c15_3_l0_c1_i2;
    assign PROP_LA_l0_c1_s0[3:2] = PROP_c15_3_l0_c1_i2;
    
    c15_3 #(.OUTREG("TRUE" ),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_l0_c1_i3(
        .clk (clk                ),
        .C0  (C0_c15_3_l0_c1_i3  ),
        .C1  (C1_c15_3_l0_c1_i3  ),
        .CLA (CLA_c15_3_l0_c1_i3 ),
        .O   (O_c15_3_l0_c1_i3   ),
        .CY  (CY_c15_3_l0_c1_i3  ),
        .PROP(PROP_c15_3_l0_c1_i3));
    
    assign C0_c15_3_l0_c1_i3 = {l0_c1_i2, layer0_col37[4:1]};
    assign C1_c15_3_l0_c1_i3 = layer0_col38[4];
    
    assign layer1_col37[1] = O_c15_3_l0_c1_i3[0];
    
    assign l0_c1_i3              = COUT_LA_l0_c1_s0[2];
    assign CY_LA_l0_c1_s0[5:4]   = CY_c15_3_l0_c1_i3;
    assign PROP_LA_l0_c1_s0[5:4] = PROP_c15_3_l0_c1_i3;
    
    c15_3 #(.OUTREG("TRUE" ),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_l0_c1_i4(
        .clk (clk                ),
        .C0  (C0_c15_3_l0_c1_i4  ),
        .C1  (C1_c15_3_l0_c1_i4  ),
        .CLA (CLA_c15_3_l0_c1_i4 ),
        .O   (O_c15_3_l0_c1_i4   ),
        .CY  (CY_c15_3_l0_c1_i4  ),
        .PROP(PROP_c15_3_l0_c1_i4));
    
    assign C0_c15_3_l0_c1_i4 = {l0_c1_i3, layer0_col39[4:1]};
    assign C1_c15_3_l0_c1_i4 = layer0_col40[4];
    
    assign layer1_col40[1] = O_c15_3_l0_c1_i4[1];
    
    assign l0_c1_i4              = COUT_LA_l0_c1_s0[3];
    assign CY_LA_l0_c1_s0[7:6]   = CY_c15_3_l0_c1_i4;
    assign PROP_LA_l0_c1_s0[7:6] = PROP_c15_3_l0_c1_i4;
    
    c15_3 #(.OUTREG("TRUE" ),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_l0_c1_i5(
        .clk (clk                ),
        .C0  (C0_c15_3_l0_c1_i5  ),
        .C1  (C1_c15_3_l0_c1_i5  ),
        .CLA (CLA_c15_3_l0_c1_i5 ),
        .O   (O_c15_3_l0_c1_i5   ),
        .CY  (CY_c15_3_l0_c1_i5  ),
        .PROP(PROP_c15_3_l0_c1_i5));
    
    assign C0_c15_3_l0_c1_i5 = {l0_c1_i4, layer0_col41[4:1]};
    assign C1_c15_3_l0_c1_i5 = layer0_col42[4];
    
    assign layer1_col42[1] = O_c15_3_l0_c1_i5[1];
    
    assign l0_c1_i5              = COUT_LA_l0_c1_s0[4];
    assign CY_LA_l0_c1_s0[9:8]   = CY_c15_3_l0_c1_i5;
    assign PROP_LA_l0_c1_s0[9:8] = PROP_c15_3_l0_c1_i5;
    
    
    c15_3 #(.OUTREG("TRUE" ),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_l0_c1_i6(
        .clk (clk                ),
        .C0  (C0_c15_3_l0_c1_i6  ),
        .C1  (C1_c15_3_l0_c1_i6  ),
        .CLA (CLA_c15_3_l0_c1_i6 ),
        .O   (O_c15_3_l0_c1_i6   ),
        .CY  (CY_c15_3_l0_c1_i6  ),
        .PROP(PROP_c15_3_l0_c1_i6));
    
    assign C0_c15_3_l0_c1_i6 = {l0_c1_i5, layer0_col43[4:1]};
    assign C1_c15_3_l0_c1_i6 = layer0_col44[4];
    
    
    assign l0_c1_i6                = COUT_LA_l0_c1_s0[5];
    assign CY_LA_l0_c1_s0[11:10]   = CY_c15_3_l0_c1_i6;
    assign PROP_LA_l0_c1_s0[11:10] = PROP_c15_3_l0_c1_i6;
    
    c15_3 #(.OUTREG("TRUE" ),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_l0_c1_i7(
        .clk (clk                ),
        .C0  (C0_c15_3_l0_c1_i7  ),
        .C1  (C1_c15_3_l0_c1_i7  ),
        .CLA (CLA_c15_3_l0_c1_i7 ),
        .O   (O_c15_3_l0_c1_i7   ),
        .CY  (CY_c15_3_l0_c1_i7  ),
        .PROP(PROP_c15_3_l0_c1_i7));
    
    assign C0_c15_3_l0_c1_i7 = {l0_c1_i6, layer0_col45[4:1]};
    assign C1_c15_3_l0_c1_i7 = layer0_col46[4];
    
    assign layer1_col46[1] = O_c15_3_l0_c1_i7[1];
    
    assign l0_c1_i7                = COUT_LA_l0_c1_s0[6];
    assign CY_LA_l0_c1_s0[13:12]   = CY_c15_3_l0_c1_i7;
    assign PROP_LA_l0_c1_s0[13:12] = PROP_c15_3_l0_c1_i7;
    
    c15_3 #(.OUTREG("TRUE" ),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE"))
    c15_3_l0_c1_i8(
        .clk (clk                ),
        .C0  (C0_c15_3_l0_c1_i8  ),
        .C1  (C1_c15_3_l0_c1_i8  ),
        .CLA (CLA_c15_3_l0_c1_i8 ),
        .O   (O_c15_3_l0_c1_i8   ),
        .CY  (CY_c15_3_l0_c1_i8  ),
        .PROP(PROP_c15_3_l0_c1_i8));
    
    assign C0_c15_3_l0_c1_i8 = {l0_c1_i7, layer0_col47[4:1]};
    assign C1_c15_3_l0_c1_i8 = layer0_col48[2];
    
    assign layer1_col48[1] = O_c15_3_l0_c1_i8[1];
    
    assign l0_c1_i8                = COUT_LA_l0_c1_s0[7];
    assign CY_LA_l0_c1_s0[15:14]   = CY_c15_3_l0_c1_i8;
    assign PROP_LA_l0_c1_s0[15:14] = PROP_c15_3_l0_c1_i8;
    
    c3_2 #(.OUTREG("TRUE" ),
           .LEAVEC("FALSE"),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("TRUE" ))
    c3_2_l0_c1_i9(
        .clk (clk               ),
        .C0  (C0_c3_2_l0_c1_i9  ),
        .O   (O_c3_2_l0_c1_i9   ),
        .CY  (CY_c3_2_l0_c1_i9  ),
        .PROP(PROP_c3_2_l0_c1_i9));
    
    assign C0_c3_2_l0_c1_i9 = {l0_c1_i8, layer0_col49[3:2]};
    
    assign layer1_col50[1] = O_c3_2_l0_c1_i9[1];
    
    assign l0_c1_i9             = O_c3_2_l0_c1_i9[1];
    assign CY_LA_l0_c1_s0[16]   = CY_c3_2_l0_c1_i9;
    assign PROP_LA_l0_c1_s0[16] = PROP_c3_2_l0_c1_i9;
    
    
    // GPC0 in layer0: (3 : 2] at column 36
    
    c3_2 #(.OUTREG("TRUE" ),
           .LEAVEC("FALSE"),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_l0_f0(
        .clk (clk            ),
        .C0  (C0_c3_2_l0_f0  ),
        .O   (O_c3_2_l0_i0   ),
        .CY  (CY_c3_2_l0_f0  ),
        .PROP(PROP_c3_2_l0_f0));
    
    assign C0_c3_2_l0_f0 = layer0_col36[7:5];
    
    assign layer1_col37[2] = O_c3_2_l0_i0[1];
    
    // GPC chain2 in layer0:
    // -- (2,2,3 : 4] at column 38
    // -- (2,2,3 : 4] at column 41
    
    LOOKAHEAD8 #(
        .LOOKB("FALSE"),
        .LOOKD("FALSE"),
        .LOOKF("FALSE"),
        .LOOKH("FALSE"))
    LOOKAHEAD8_l0_c2_s0_inst0 (
        .COUTB(COUT_LA_l0_c2_s0[0]),
        .COUTD(COUT_LA_l0_c2_s0[1]),
        .COUTF(COUT_LA_l0_c2_s0[2]),
        .COUTH(COUT_LA_l0_c2_s0[3]),
        .CIN  (CIN_LA_l0_c2_s0    ),
        .CYA  (CY_LA_l0_c2_s0[0]  ),
        .CYB  (CY_LA_l0_c2_s0[1]  ),
        .CYC  (CY_LA_l0_c2_s0[2]  ),
        .CYD  (CY_LA_l0_c2_s0[3]  ),
        .CYE  (CY_LA_l0_c2_s0[4]  ),
        .CYF  (CY_LA_l0_c2_s0[5]  ),
        .CYG  (CY_LA_l0_c2_s0[6]  ),
        .CYH  (CY_LA_l0_c2_s0[7]  ),
        .PROPA(PROP_LA_l0_c2_s0[0]),
        .PROPB(PROP_LA_l0_c2_s0[1]),
        .PROPC(PROP_LA_l0_c2_s0[2]),
        .PROPD(PROP_LA_l0_c2_s0[3]),
        .PROPE(PROP_LA_l0_c2_s0[4]),
        .PROPF(PROP_LA_l0_c2_s0[5]),
        .PROPG(PROP_LA_l0_c2_s0[6]),
        .PROPH(PROP_LA_l0_c2_s0[7]));

    c223_4 #(.C1_INV(2'h2),
            .OUTREG("TRUE" ),
             .LEAVEC("TRUE" ),
             .POSODD("FALSE")) c223_4_l0_c2_i0(
        .clk (clk                 ),
        .C0  (C0_c223_4_l0_c2_i0  ),
        .C1  (C1_c223_4_l0_c2_i0  ),
        .C2  (C2_c223_4_l0_c2_i0  ),
        .CLA (CLA_c223_4_l0_c2_i0 ),
        .O   (O_c223_4_l0_c2_i0   ),
        .CY  (CY_c223_4_l0_c2_i0  ),
        .PROP(PROP_c223_4_l0_c2_i0));
    
    assign C0_c223_4_l0_c2_i0 = layer0_col38[7:5];
    assign C1_c223_4_l0_c2_i0 = layer0_col39[6:5];
    assign C2_c223_4_l0_c2_i0 = layer0_col40[6:5];
    
    assign layer1_col40[2] = O_c223_4_l0_c2_i0[2];
    
    assign l0_c2_i0              = COUT_LA_l0_c2_s0[0];
    assign CY_LA_l0_c2_s0[1:0]   = CY_c223_4_l0_c2_i0;
    assign PROP_LA_l0_c2_s0[1:0] = PROP_c223_4_l0_c2_i0;
    
    assign CIN_LA_l0_c2_s0    = C0_c223_4_l0_c2_i0[2];
    
    c223_4 #(.C0_INV(3'h2), .C2_INV(2'h2),
            .OUTREG("TRUE" ),
             .LEAVEC("FALSE"),
             .POSODD("FALSE")) c223_4_l0_c2_i1(
        .clk (clk                 ),
        .C0  (C0_c223_4_l0_c2_i1  ),
        .C1  (C1_c223_4_l0_c2_i1  ),
        .C2  (C2_c223_4_l0_c2_i1  ),
        .CLA (CLA_c223_4_l0_c2_i1 ),
        .O   (O_c223_4_l0_c2_i1   ),
        .CY  (CY_c223_4_l0_c2_i1  ),
        .PROP(PROP_c223_4_l0_c2_i1));
    
    assign C0_c223_4_l0_c2_i1 = {l0_c2_i0, layer0_col41[6:5]};
    assign C1_c223_4_l0_c2_i1 = layer0_col42[6:5];
    assign C2_c223_4_l0_c2_i1 = layer0_col43[6:5];
    
    assign layer1_col42[2] = O_c223_4_l0_c2_i1[1];
    
    assign l0_c2_i1              = COUT_LA_l0_c2_s0[1];
    assign CY_LA_l0_c2_s0[3:2]   = CY_c223_4_l0_c2_i1;
    assign PROP_LA_l0_c2_s0[3:2] = PROP_c223_4_l0_c2_i1;
    
    // GPC chain3 in layer0:
    // -- (3 : 2] at column 44
    // -- (3 : 2] at column 45
    
    LOOKAHEAD8 #(
        .LOOKB("FALSE"),
        .LOOKD("FALSE"),
        .LOOKF("FALSE"),
        .LOOKH("FALSE"))
    LOOKAHEAD8_l0_c3_s0_inst0 (
        .COUTB(COUT_LA_l0_c3_s0[0]),
        .COUTD(COUT_LA_l0_c3_s0[1]),
        .COUTF(COUT_LA_l0_c3_s0[2]),
        .COUTH(COUT_LA_l0_c3_s0[3]),
        .CIN  (CIN_LA_l0_c3_s0    ),
        .CYA  (CY_LA_l0_c3_s0[0]  ),
        .CYB  (CY_LA_l0_c3_s0[1]  ),
        .CYC  (CY_LA_l0_c3_s0[2]  ),
        .CYD  (CY_LA_l0_c3_s0[3]  ),
        .CYE  (CY_LA_l0_c3_s0[4]  ),
        .CYF  (CY_LA_l0_c3_s0[5]  ),
        .CYG  (CY_LA_l0_c3_s0[6]  ),
        .CYH  (CY_LA_l0_c3_s0[7]  ),
        .PROPA(PROP_LA_l0_c3_s0[0]),
        .PROPB(PROP_LA_l0_c3_s0[1]),
        .PROPC(PROP_LA_l0_c3_s0[2]),
        .PROPD(PROP_LA_l0_c3_s0[3]),
        .PROPE(PROP_LA_l0_c3_s0[4]),
        .PROPF(PROP_LA_l0_c3_s0[5]),
        .PROPG(PROP_LA_l0_c3_s0[6]),
        .PROPH(PROP_LA_l0_c3_s0[7]));

    c3_2 #(.OUTREG("TRUE" ),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("TRUE" ),
           .LASTS ("FALSE"))
    c3_2_l0_c3_i0(
        .clk (clk               ),
        .C0  (C0_c3_2_l0_c3_i0  ),
        .O   (O_c3_2_l0_c3_i0   ),
        .CY  (CY_c3_2_l0_c3_i0  ),
        .PROP(PROP_c3_2_l0_c3_i0));
    
    assign C0_c3_2_l0_c3_i0 = layer0_col44[7:5];
    
    
    assign l0_c3_i0            = O_c3_2_l0_c3_i0[1];
    assign CY_LA_l0_c3_s0[0]   = CY_c3_2_l0_c3_i0;
    assign PROP_LA_l0_c3_s0[0] = PROP_c3_2_l0_c3_i0;
    
    assign CIN_LA_l0_c3_s0    = C0_c3_2_l0_c3_i0[2];
    
    c3_2 #(.C0_INV(3'h2),
            .OUTREG("TRUE" ),
           .LEAVEC("FALSE"),
           .POSODD("TRUE" ),
           .FIRSTS("TRUE" ),
           .LASTS ("TRUE" )) c3_2_l0_c3_i1(
        .clk (clk               ),
        .C0  (C0_c3_2_l0_c3_i1  ),
        .O   (O_c3_2_l0_c3_i1   ),
        .CY  (CY_c3_2_l0_c3_i1  ),
        .PROP(PROP_c3_2_l0_c3_i1));
    
    assign C0_c3_2_l0_c3_i1 = {l0_c3_i0, layer0_col45[6:5]};
    
    assign layer1_col46[2] = O_c3_2_l0_c3_i1[1];
    
    assign l0_c3_i1            = COUT_LA_l0_c3_s0[0];
    assign CY_LA_l0_c3_s0[1]   = CY_c3_2_l0_c3_i1;
    assign PROP_LA_l0_c3_s0[1] = PROP_c3_2_l0_c3_i1;
    
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
        layer1_col26[2] <= layer0_col26[2];
        layer1_col27[0] <= layer0_col27[0];
        layer1_col27[1] <= layer0_col27[1];
        layer1_col28[0] <= layer0_col28[0];
        layer1_col28[1] <= layer0_col28[1];
        layer1_col28[2] <= layer0_col28[2];
        layer1_col28[3] <= layer0_col28[3];
        layer1_col29[0] <= layer0_col29[0];
        layer1_col29[1] <= layer0_col29[1];
        layer1_col29[2] <= layer0_col29[2];
        layer1_col30[1] <= layer0_col30[3];
        layer1_col30[2] <= layer0_col30[4];
        layer1_col31[1] <= layer0_col31[2];
        layer1_col31[2] <= layer0_col31[3];
        layer1_col32[1] <= layer0_col32[4];
        layer1_col32[2] <= layer0_col32[5];
        layer1_col33[2] <= layer0_col33[4];
        layer1_col34[2] <= layer0_col34[6];
        layer1_col35[2] <= layer0_col35[5];
        layer1_col37[3] <= layer0_col37[5];

        layer1_col40[3] <= layer0_col40[7];
        layer1_col42[3] <= layer0_col42[7];
        layer1_col46[3] <= layer0_col46[5];

        layer1_col48[2] <= layer0_col48[3];
        layer1_col48[3] <= layer0_col48[4];

        layer1_col50[2] <= layer0_col50[2];
        layer1_col50[3] <= layer0_col50[3];
        layer1_col51[1] <= layer0_col51[2];

        layer1_col52[1] <= layer0_col52[0];
        layer1_col52[2] <= layer0_col52[1];
        layer1_col52[3] <= layer0_col52[2];
        layer1_col53[0] <= layer0_col53[0];
        layer1_col53[1] <= layer0_col53[1];

        layer1_col54[0] <= layer0_col54[0];
        layer1_col54[1] <= layer0_col54[1];
        layer1_col55[0] <= layer0_col55[0];

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
    
    assign C0_c3_2_terminal_chain1_i0 = layer1_col26;
    
    assign terminal_chain1_out = {O_c3_2_terminal_chain1_i16[1], O_c3_2_terminal_chain1_i16[0], O_c3_2_terminal_chain1_i15[0], O_c15_3_terminal_chain1_i14[1], O_c15_3_terminal_chain1_i14[0], O_c15_3_terminal_chain1_i13[1], O_c15_3_terminal_chain1_i13[0], O_c15_3_terminal_chain1_i12[1], O_c15_3_terminal_chain1_i12[0], O_c15_3_terminal_chain1_i11[1], O_c15_3_terminal_chain1_i11[0], O_c15_3_terminal_chain1_i10[1], O_c15_3_terminal_chain1_i10[0], O_c15_3_terminal_chain1_i9[1], O_c15_3_terminal_chain1_i9[0], O_c15_3_terminal_chain1_i8[1], O_c15_3_terminal_chain1_i8[0], O_c15_3_terminal_chain1_i7[1], O_c15_3_terminal_chain1_i7[0], O_c15_3_terminal_chain1_i6[1], O_c15_3_terminal_chain1_i6[0], O_c15_3_terminal_chain1_i5[1], O_c15_3_terminal_chain1_i5[0], O_c15_3_terminal_chain1_i4[1], O_c15_3_terminal_chain1_i4[0], O_c15_3_terminal_chain1_i3[1], O_c15_3_terminal_chain1_i3[0], O_c15_3_terminal_chain1_i2[1], O_c15_3_terminal_chain1_i2[0], O_c3_2_terminal_chain1_i1[0], O_c3_2_terminal_chain1_i0[0]};
    
    assign terminal_chain1_i0         = O_c3_2_terminal_chain1_i0[1];
    assign CY_LA_terminal_chain1[0]   = CY_c3_2_terminal_chain1_i0;
    assign PROP_LA_terminal_chain1[0] = PROP_c3_2_terminal_chain1_i0;
    
    assign CIN_LA_terminal_chain1 = {COUT_LA_terminal_chain1[11], COUT_LA_terminal_chain1[7], COUT_LA_terminal_chain1[3], C0_c3_2_terminal_chain1_i0[2]};
    
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
    assign CY_LA_terminal_chain1[1]   = CY_c3_2_terminal_chain1_i1;
    assign PROP_LA_terminal_chain1[1] = PROP_c3_2_terminal_chain1_i1;
    
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
    
    assign C0_c15_3_terminal_chain1_i2 = {terminal_chain1_i1, layer1_col28[3], layer1_col28[2], layer1_col28[1], layer1_col28[0]};
    assign C1_c15_3_terminal_chain1_i2    = layer1_col29[0];
    
    
    assign terminal_chain1_i2           = COUT_LA_terminal_chain1[1];
    assign CY_LA_terminal_chain1[3:2]   = CY_c15_3_terminal_chain1_i2;
    assign PROP_LA_terminal_chain1[3:2] = PROP_c15_3_terminal_chain1_i2;
    
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
    
    assign C0_c15_3_terminal_chain1_i3 = {terminal_chain1_i2, layer1_col30[2], layer1_col30[1], layer1_col30[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i3    = layer1_col31[0];
    
    
    assign terminal_chain1_i3           = COUT_LA_terminal_chain1[2];
    assign CY_LA_terminal_chain1[5:4]   = CY_c15_3_terminal_chain1_i3;
    assign PROP_LA_terminal_chain1[5:4] = PROP_c15_3_terminal_chain1_i3;
    
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
    
    assign C0_c15_3_terminal_chain1_i4 = {terminal_chain1_i3, layer1_col32[2], layer1_col32[1], layer1_col32[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i4    = layer1_col33[0];
    
    
    assign terminal_chain1_i4           = COUT_LA_terminal_chain1[3];
    assign CY_LA_terminal_chain1[7:6]   = CY_c15_3_terminal_chain1_i4;
    assign PROP_LA_terminal_chain1[7:6] = PROP_c15_3_terminal_chain1_i4;
    
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
    
    assign C0_c15_3_terminal_chain1_i5 = {terminal_chain1_i4, layer1_col34[2], layer1_col34[1], layer1_col34[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i5    = layer1_col35[0];
    
    
    assign terminal_chain1_i5           = COUT_LA_terminal_chain1[4];
    assign CY_LA_terminal_chain1[9:8]   = CY_c15_3_terminal_chain1_i5;
    assign PROP_LA_terminal_chain1[9:8] = PROP_c15_3_terminal_chain1_i5;
    
    
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
    
    assign C0_c15_3_terminal_chain1_i6 = {terminal_chain1_i5, layer1_col36[2], layer1_col36[1], layer1_col36[0], 1'b0};
    assign C1_c15_3_terminal_chain1_i6    = layer1_col37[0];
    
    
    assign terminal_chain1_i6             = COUT_LA_terminal_chain1[5];
    assign CY_LA_terminal_chain1[11:10]   = CY_c15_3_terminal_chain1_i6;
    assign PROP_LA_terminal_chain1[11:10] = PROP_c15_3_terminal_chain1_i6;
    
    c15_3 #(.C0_INV(5'h8),
            .OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE")) c15_3_terminal_chain1_i7(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain1_i7  ),
        .C1  (C1_c15_3_terminal_chain1_i7  ),
        .CLA (CLA_c15_3_terminal_chain1_i7 ),
        .O   (O_c15_3_terminal_chain1_i7   ),
        .CY  (CY_c15_3_terminal_chain1_i7  ),
        .PROP(PROP_c15_3_terminal_chain1_i7));
    
    assign C0_c15_3_terminal_chain1_i7 = {terminal_chain1_i6, layer1_col38[3], layer1_col38[2], layer1_col38[1], layer1_col38[0]};
    assign C1_c15_3_terminal_chain1_i7    = layer1_col39[0];
    
    
    assign terminal_chain1_i7             = COUT_LA_terminal_chain1[6];
    assign CY_LA_terminal_chain1[13:12]   = CY_c15_3_terminal_chain1_i7;
    assign PROP_LA_terminal_chain1[13:12] = PROP_c15_3_terminal_chain1_i7;
    
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
    
    assign C0_c15_3_terminal_chain1_i8 = {terminal_chain1_i7, layer1_col40[3], layer1_col40[2], layer1_col40[1], layer1_col40[0]};
    assign C1_c15_3_terminal_chain1_i8    = layer1_col41[0];
    
    
    assign terminal_chain1_i8             = COUT_LA_terminal_chain1[7];
    assign CY_LA_terminal_chain1[15:14]   = CY_c15_3_terminal_chain1_i8;
    assign PROP_LA_terminal_chain1[15:14] = PROP_c15_3_terminal_chain1_i8;
    
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
    
    assign C0_c15_3_terminal_chain1_i9 = {terminal_chain1_i8, layer1_col42[3], layer1_col42[2], layer1_col42[1], layer1_col42[0]};
    assign C1_c15_3_terminal_chain1_i9    = layer1_col43[0];
    
    
    assign terminal_chain1_i9             = COUT_LA_terminal_chain1[8];
    assign CY_LA_terminal_chain1[17:16]   = CY_c15_3_terminal_chain1_i9;
    assign PROP_LA_terminal_chain1[17:16] = PROP_c15_3_terminal_chain1_i9;
    
    
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
    
    assign C0_c15_3_terminal_chain1_i10 = {terminal_chain1_i9, layer1_col44[3], layer1_col44[2], layer1_col44[1], layer1_col44[0]};
    assign C1_c15_3_terminal_chain1_i10    = layer1_col45[0];
    
    
    assign terminal_chain1_i10            = COUT_LA_terminal_chain1[9];
    assign CY_LA_terminal_chain1[19:18]   = CY_c15_3_terminal_chain1_i10;
    assign PROP_LA_terminal_chain1[19:18] = PROP_c15_3_terminal_chain1_i10;
    
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
    
    assign C0_c15_3_terminal_chain1_i11 = {terminal_chain1_i10, layer1_col46[3], layer1_col46[2], layer1_col46[1], layer1_col46[0]};
    assign C1_c15_3_terminal_chain1_i11    = layer1_col47[0];
    
    
    assign terminal_chain1_i11            = COUT_LA_terminal_chain1[10];
    assign CY_LA_terminal_chain1[21:20]   = CY_c15_3_terminal_chain1_i11;
    assign PROP_LA_terminal_chain1[21:20] = PROP_c15_3_terminal_chain1_i11;
    
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
    
    assign C0_c15_3_terminal_chain1_i12 = {terminal_chain1_i11, layer1_col48[3], layer1_col48[2], layer1_col48[1], layer1_col48[0]};
    assign C1_c15_3_terminal_chain1_i12    = layer1_col49[0];
    
    
    assign terminal_chain1_i12            = COUT_LA_terminal_chain1[11];
    assign CY_LA_terminal_chain1[23:22]   = CY_c15_3_terminal_chain1_i12;
    assign PROP_LA_terminal_chain1[23:22] = PROP_c15_3_terminal_chain1_i12;
    
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
    
    assign C0_c15_3_terminal_chain1_i13 = {terminal_chain1_i12, layer1_col50[3], layer1_col50[2], layer1_col50[1], layer1_col50[0]};
    assign C1_c15_3_terminal_chain1_i13    = layer1_col51[0];
    
    
    assign terminal_chain1_i13            = COUT_LA_terminal_chain1[12];
    assign CY_LA_terminal_chain1[25:24]   = CY_c15_3_terminal_chain1_i13;
    assign PROP_LA_terminal_chain1[25:24] = PROP_c15_3_terminal_chain1_i13;
    
    
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
    
    assign C0_c15_3_terminal_chain1_i14 = {terminal_chain1_i13, layer1_col52[3], layer1_col52[2], layer1_col52[1], layer1_col52[0]};
    assign C1_c15_3_terminal_chain1_i14    = layer1_col53[0];
    
    
    assign terminal_chain1_i14            = COUT_LA_terminal_chain1[13];
    assign CY_LA_terminal_chain1[27:26]   = CY_c15_3_terminal_chain1_i14;
    assign PROP_LA_terminal_chain1[27:26] = PROP_c15_3_terminal_chain1_i14;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain1_i15(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i15  ),
        .O   (O_c3_2_terminal_chain1_i15   ),
        .CY  (CY_c3_2_terminal_chain1_i15  ),
        .PROP(PROP_c3_2_terminal_chain1_i15));
    
    assign C0_c3_2_terminal_chain1_i15 = {terminal_chain1_i14, layer1_col54[1], layer1_col54[0]};
    
    
    assign terminal_chain1_i15         = O_c3_2_terminal_chain1_i15[1];
    assign CY_LA_terminal_chain1[28]   = CY_c3_2_terminal_chain1_i15;
    assign PROP_LA_terminal_chain1[28] = PROP_c3_2_terminal_chain1_i15;
    
    c3_2 #(.C0_INV(3'h2),
            .OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("TRUE" )) c3_2_terminal_chain1_i16(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain1_i16  ),
        .O   (O_c3_2_terminal_chain1_i16   ),
        .CY  (CY_c3_2_terminal_chain1_i16  ),
        .PROP(PROP_c3_2_terminal_chain1_i16));
    
    assign C0_c3_2_terminal_chain1_i16 = {terminal_chain1_i15, layer1_col55[1], layer1_col55[0]};
    
    
    assign terminal_chain1_i16         = COUT_LA_terminal_chain1[14];
    assign CY_LA_terminal_chain1[29]   = CY_c3_2_terminal_chain1_i16;
    assign PROP_LA_terminal_chain1[29] = PROP_c3_2_terminal_chain1_i16;
    
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
    
    assign C0_c15_3_terminal_chain2_i0 = {1'b0, terminal_chain1_out[3], layer1_col29[2], layer1_col29[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i0    = terminal_chain1_out[4];
    
    assign terminal_chain2_out = {O_c3_2_terminal_chain2_i14[1], O_c3_2_terminal_chain2_i14[0], O_c3_2_terminal_chain2_i13[0], O_c15_3_terminal_chain2_i12[1], O_c15_3_terminal_chain2_i12[0], O_c15_3_terminal_chain2_i11[1], O_c15_3_terminal_chain2_i11[0], O_c15_3_terminal_chain2_i10[1], O_c15_3_terminal_chain2_i10[0], O_c15_3_terminal_chain2_i9[1], O_c15_3_terminal_chain2_i9[0], O_c15_3_terminal_chain2_i8[1], O_c15_3_terminal_chain2_i8[0], O_c15_3_terminal_chain2_i7[1], O_c15_3_terminal_chain2_i7[0], O_c15_3_terminal_chain2_i6[1], O_c15_3_terminal_chain2_i6[0], O_c15_3_terminal_chain2_i5[1], O_c15_3_terminal_chain2_i5[0], O_c15_3_terminal_chain2_i4[1], O_c15_3_terminal_chain2_i4[0], O_c15_3_terminal_chain2_i3[1], O_c15_3_terminal_chain2_i3[0], O_c15_3_terminal_chain2_i2[1], O_c15_3_terminal_chain2_i2[0], O_c15_3_terminal_chain2_i1[1], O_c15_3_terminal_chain2_i1[0], O_c15_3_terminal_chain2_i0[1], O_c15_3_terminal_chain2_i0[0]};
    
    assign terminal_chain2_i0           = COUT_LA_terminal_chain2[0];
    assign CY_LA_terminal_chain2[1:0]   = CY_c15_3_terminal_chain2_i0;
    assign PROP_LA_terminal_chain2[1:0] = PROP_c15_3_terminal_chain2_i0;
    
    assign CIN_LA_terminal_chain2 = {COUT_LA_terminal_chain2[11], COUT_LA_terminal_chain2[7], COUT_LA_terminal_chain2[3], C0_c15_3_terminal_chain2_i0[4]};
    
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
    
    assign C0_c15_3_terminal_chain2_i1 = {terminal_chain2_i0, terminal_chain1_out[5], layer1_col31[2], layer1_col31[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i1    = terminal_chain1_out[6];
    
    
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
    
    assign C0_c15_3_terminal_chain2_i2 = {terminal_chain2_i1, terminal_chain1_out[7], layer1_col33[2], layer1_col33[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i2    = terminal_chain1_out[8];
    
    
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
    
    assign C0_c15_3_terminal_chain2_i3 = {terminal_chain2_i2, terminal_chain1_out[9], layer1_col35[2], layer1_col35[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i3    = terminal_chain1_out[10];
    
    
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
    
    assign C0_c15_3_terminal_chain2_i4 = {terminal_chain2_i3, terminal_chain1_out[11], layer1_col37[3], layer1_col37[2], layer1_col37[1]};
    assign C1_c15_3_terminal_chain2_i4    = terminal_chain1_out[12];
    
    
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
    
    assign C0_c15_3_terminal_chain2_i5 = {terminal_chain2_i4, terminal_chain1_out[13], layer1_col39[2], layer1_col39[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i5    = terminal_chain1_out[14];
    
    
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
    
    assign C0_c15_3_terminal_chain2_i6 = {terminal_chain2_i5, terminal_chain1_out[15], layer1_col41[2], layer1_col41[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i6    = terminal_chain1_out[16];
    
    
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
    
    assign C0_c15_3_terminal_chain2_i7 = {terminal_chain2_i6, terminal_chain1_out[17], layer1_col43[2], layer1_col43[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i7    = terminal_chain1_out[18];
    
    
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
    
    assign C0_c15_3_terminal_chain2_i8 = {terminal_chain2_i7, terminal_chain1_out[19], layer1_col45[2], layer1_col45[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i8    = terminal_chain1_out[20];
    
    
    assign terminal_chain2_i8             = COUT_LA_terminal_chain2[8];
    assign CY_LA_terminal_chain2[17:16]   = CY_c15_3_terminal_chain2_i8;
    assign PROP_LA_terminal_chain2[17:16] = PROP_c15_3_terminal_chain2_i8;
    
    
    c15_3 #(.C0_INV(5'h4),
            .OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE")) c15_3_terminal_chain2_i9(
        .clk (clk                          ),
        .C0  (C0_c15_3_terminal_chain2_i9  ),
        .C1  (C1_c15_3_terminal_chain2_i9  ),
        .CLA (CLA_c15_3_terminal_chain2_i9 ),
        .O   (O_c15_3_terminal_chain2_i9   ),
        .CY  (CY_c15_3_terminal_chain2_i9  ),
        .PROP(PROP_c15_3_terminal_chain2_i9));
    
    assign C0_c15_3_terminal_chain2_i9 = {terminal_chain2_i8, terminal_chain1_out[21], layer1_col47[2], layer1_col47[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i9    = terminal_chain1_out[22];
    
    
    assign terminal_chain2_i9             = COUT_LA_terminal_chain2[9];
    assign CY_LA_terminal_chain2[19:18]   = CY_c15_3_terminal_chain2_i9;
    assign PROP_LA_terminal_chain2[19:18] = PROP_c15_3_terminal_chain2_i9;
    
    c15_3 #(.C0_INV(5'h4),
            .OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE")) c15_3_terminal_chain2_i10(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain2_i10  ),
        .C1  (C1_c15_3_terminal_chain2_i10  ),
        .CLA (CLA_c15_3_terminal_chain2_i10 ),
        .O   (O_c15_3_terminal_chain2_i10   ),
        .CY  (CY_c15_3_terminal_chain2_i10  ),
        .PROP(PROP_c15_3_terminal_chain2_i10));
    
    assign C0_c15_3_terminal_chain2_i10 = {terminal_chain2_i9, terminal_chain1_out[23], layer1_col49[2], layer1_col49[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i10    = terminal_chain1_out[24];
    
    
    assign terminal_chain2_i10            = COUT_LA_terminal_chain2[10];
    assign CY_LA_terminal_chain2[21:20]   = CY_c15_3_terminal_chain2_i10;
    assign PROP_LA_terminal_chain2[21:20] = PROP_c15_3_terminal_chain2_i10;
    
    c15_3 #(.C0_INV(5'h4),
            .OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE")) c15_3_terminal_chain2_i11(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain2_i11  ),
        .C1  (C1_c15_3_terminal_chain2_i11  ),
        .CLA (CLA_c15_3_terminal_chain2_i11 ),
        .O   (O_c15_3_terminal_chain2_i11   ),
        .CY  (CY_c15_3_terminal_chain2_i11  ),
        .PROP(PROP_c15_3_terminal_chain2_i11));
    
    assign C0_c15_3_terminal_chain2_i11 = {terminal_chain2_i10, terminal_chain1_out[25], layer1_col51[2], layer1_col51[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i11    = terminal_chain1_out[26];
    
    
    assign terminal_chain2_i11            = COUT_LA_terminal_chain2[11];
    assign CY_LA_terminal_chain2[23:22]   = CY_c15_3_terminal_chain2_i11;
    assign PROP_LA_terminal_chain2[23:22] = PROP_c15_3_terminal_chain2_i11;
    
    c15_3 #(.C0_INV(5'h4),
            .OUTREG("FALSE"),
            .LEAVEC("TRUE" ),
            .POSODD("FALSE"),
            .FIRSTS("FALSE"),
            .LASTS ("FALSE")) c15_3_terminal_chain2_i12(
        .clk (clk                           ),
        .C0  (C0_c15_3_terminal_chain2_i12  ),
        .C1  (C1_c15_3_terminal_chain2_i12  ),
        .CLA (CLA_c15_3_terminal_chain2_i12 ),
        .O   (O_c15_3_terminal_chain2_i12   ),
        .CY  (CY_c15_3_terminal_chain2_i12  ),
        .PROP(PROP_c15_3_terminal_chain2_i12));
    
    assign C0_c15_3_terminal_chain2_i12 = {terminal_chain2_i11, terminal_chain1_out[27], layer1_col53[2], layer1_col53[1], 1'b0};
    assign C1_c15_3_terminal_chain2_i12    = terminal_chain1_out[28];
    
    
    assign terminal_chain2_i12            = COUT_LA_terminal_chain2[12];
    assign CY_LA_terminal_chain2[25:24]   = CY_c15_3_terminal_chain2_i12;
    assign PROP_LA_terminal_chain2[25:24] = PROP_c15_3_terminal_chain2_i12;
    
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("FALSE"),
           .FIRSTS("FALSE"),
           .LASTS ("FALSE"))
    c3_2_terminal_chain2_i13(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i13  ),
        .O   (O_c3_2_terminal_chain2_i13   ),
        .CY  (CY_c3_2_terminal_chain2_i13  ),
        .PROP(PROP_c3_2_terminal_chain2_i13));
    
    assign C0_c3_2_terminal_chain2_i13 = {terminal_chain2_i12, 1'b0, terminal_chain1_out[29]};
    
    
    assign terminal_chain2_i13         = O_c3_2_terminal_chain2_i13[1];
    assign CY_LA_terminal_chain2[26]   = CY_c3_2_terminal_chain2_i13;
    assign PROP_LA_terminal_chain2[26] = PROP_c3_2_terminal_chain2_i13;
    
    c3_2 #(.OUTREG("FALSE"),
           .LEAVEC("TRUE" ),
           .POSODD("TRUE" ),
           .FIRSTS("FALSE"),
           .LASTS ("TRUE" ))
    c3_2_terminal_chain2_i14(
        .clk (clk                          ),
        .C0  (C0_c3_2_terminal_chain2_i14  ),
        .O   (O_c3_2_terminal_chain2_i14   ),
        .CY  (CY_c3_2_terminal_chain2_i14  ),
        .PROP(PROP_c3_2_terminal_chain2_i14));
    
    assign C0_c3_2_terminal_chain2_i14 = {terminal_chain2_i13, 1'b0, terminal_chain1_out[30]};
    
    
    assign terminal_chain2_i14         = COUT_LA_terminal_chain2[13];
    assign CY_LA_terminal_chain2[27]   = CY_c3_2_terminal_chain2_i14;
    assign PROP_LA_terminal_chain2[27] = PROP_c3_2_terminal_chain2_i14;
    
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
    
        comp_out[28:26] <= terminal_chain1_out[2:0];
    
        comp_out[57:29] <= terminal_chain2_out[28:0];
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
    
    assign layer1_col51[2] = 1'b0;
    assign layer1_col53[2] = 1'b0;
    assign layer1_col55[1] = 1'b0;
endmodule