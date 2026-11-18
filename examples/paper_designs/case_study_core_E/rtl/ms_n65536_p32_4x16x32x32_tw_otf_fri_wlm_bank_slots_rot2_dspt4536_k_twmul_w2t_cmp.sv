`timescale 1ns / 1ps

module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_twmul_w2t_cmp (
    input  logic          clk,
    input  logic [2  : 0] col0,
    input  logic [1  : 0] col1,
    input  logic [1  : 0] col2,
    input  logic [1  : 0] col3,
    input  logic [1  : 0] col4,
    input  logic [1  : 0] col5,
    input  logic [1  : 0] col6,
    input  logic [1  : 0] col7,
    input  logic [1  : 0] col8,
    input  logic [1  : 0] col9,
    input  logic [1  : 0] col10,
    input  logic [1  : 0] col11,
    input  logic [1  : 0] col12,
    input  logic [1  : 0] col13,
    input  logic [1  : 0] col14,
    input  logic [1  : 0] col15,
    input  logic [1  : 0] col16,
    input  logic [1  : 0] col17,
    input  logic [1  : 0] col18,
    input  logic [1  : 0] col19,
    input  logic [1  : 0] col20,
    input  logic [1  : 0] col21,
    input  logic [1  : 0] col22,
    input  logic [1  : 0] col23,
    input  logic [1  : 0] col24,
    input  logic [1  : 0] col25,
    input  logic [1  : 0] col26,
    input  logic [1  : 0] col27,
    input  logic [1  : 0] col28,
    input  logic [1  : 0] col29,
    input  logic [1  : 0] col30,
    input  logic [1  : 0] col31,
    input  logic [1  : 0] col32,
    input  logic [1  : 0] col33,
    input  logic [1  : 0] col34,
    input  logic [1  : 0] col35,
    input  logic [1  : 0] col36,
    input  logic [1  : 0] col37,
    input  logic [1  : 0] col38,
    input  logic [1  : 0] col39,
    input  logic [1  : 0] col40,
    input  logic [1  : 0] col41,
    input  logic [1  : 0] col42,
    input  logic [1  : 0] col43,
    input  logic [1  : 0] col44,
    input  logic [1  : 0] col45,
    input  logic [1  : 0] col46,
    input  logic [1  : 0] col47,
    input  logic [1  : 0] col48,
    input  logic [1  : 0] col49,
    input  logic [1  : 0] col50,
    input  logic [1  : 0] col51,
    input  logic [1  : 0] col52,
    input  logic [1  : 0] col53,
    input  logic [1  : 0] col54,
    input  logic [1  : 0] col55,
    input  logic [1  : 0] col56,
    input  logic [1  : 0] col57,
    input  logic [1  : 0] col58,
    input  logic [1  : 0] col59,
    input  logic [1  : 0] col60,
    input  logic [1  : 0] col61,
    input  logic          col62,
    input  logic          col63,
    input  logic          col64,
    input  logic          col65,
    input  logic          col66,
    input  logic          col67,
    input  logic          col68,
    input  logic          col69,
    input  logic          col70,
    input  logic          col71,
    input  logic          col72,
    input  logic          col73,
    output logic [74 : 0] comp_out
    );

    
    // ------------------------------ LAYER 0 ------------------------------
    logic [2  : 0] layer0_col0;
    logic [1  : 0] layer0_col1;
    logic [1  : 0] layer0_col2;
    logic [1  : 0] layer0_col3;
    logic [1  : 0] layer0_col4;
    logic [1  : 0] layer0_col5;
    logic [1  : 0] layer0_col6;
    logic [1  : 0] layer0_col7;
    logic [1  : 0] layer0_col8;
    logic [1  : 0] layer0_col9;
    logic [1  : 0] layer0_col10;
    logic [1  : 0] layer0_col11;
    logic [1  : 0] layer0_col12;
    logic [1  : 0] layer0_col13;
    logic [1  : 0] layer0_col14;
    logic [1  : 0] layer0_col15;
    logic [1  : 0] layer0_col16;
    logic [1  : 0] layer0_col17;
    logic [1  : 0] layer0_col18;
    logic [1  : 0] layer0_col19;
    logic [1  : 0] layer0_col20;
    logic [1  : 0] layer0_col21;
    logic [1  : 0] layer0_col22;
    logic [1  : 0] layer0_col23;
    logic [1  : 0] layer0_col24;
    logic [1  : 0] layer0_col25;
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
    logic [1  : 0] layer0_col46;
    logic [1  : 0] layer0_col47;
    logic [1  : 0] layer0_col48;
    logic [1  : 0] layer0_col49;
    logic [1  : 0] layer0_col50;
    logic [1  : 0] layer0_col51;
    logic [1  : 0] layer0_col52;
    logic [1  : 0] layer0_col53;
    logic [1  : 0] layer0_col54;
    logic [1  : 0] layer0_col55;
    logic [1  : 0] layer0_col56;
    logic [1  : 0] layer0_col57;
    logic [1  : 0] layer0_col58;
    logic [1  : 0] layer0_col59;
    logic [1  : 0] layer0_col60;
    logic [1  : 0] layer0_col61;
    logic          layer0_col62;
    logic          layer0_col63;
    logic          layer0_col64;
    logic          layer0_col65;
    logic          layer0_col66;
    logic          layer0_col67;
    logic          layer0_col68;
    logic          layer0_col69;
    logic          layer0_col70;
    logic          layer0_col71;
    logic          layer0_col72;
    logic          layer0_col73;
    
    logic    COUT_LA_l0_floating_placement;
    logic    CIN_LA_l0_floating_placement;
    logic    CY_LA_l0_floating_placement;
    logic    PROP_LA_l0_floating_placement;
    
    
    
    // -------------------------------------------------- TERMINAL ADDITION ------------------------------------------------
    logic [2  : 0] layer1_col0;
    logic [1  : 0] layer1_col1;
    logic [1  : 0] layer1_col2;
    logic [1  : 0] layer1_col3;
    logic [1  : 0] layer1_col4;
    logic [1  : 0] layer1_col5;
    logic [1  : 0] layer1_col6;
    logic [1  : 0] layer1_col7;
    logic [1  : 0] layer1_col8;
    logic [1  : 0] layer1_col9;
    logic [1  : 0] layer1_col10;
    logic [1  : 0] layer1_col11;
    logic [1  : 0] layer1_col12;
    logic [1  : 0] layer1_col13;
    logic [1  : 0] layer1_col14;
    logic [1  : 0] layer1_col15;
    logic [1  : 0] layer1_col16;
    logic [1  : 0] layer1_col17;
    logic [1  : 0] layer1_col18;
    logic [1  : 0] layer1_col19;
    logic [1  : 0] layer1_col20;
    logic [1  : 0] layer1_col21;
    logic [1  : 0] layer1_col22;
    logic [1  : 0] layer1_col23;
    logic [1  : 0] layer1_col24;
    logic [1  : 0] layer1_col25;
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
    logic [1  : 0] layer1_col46;
    logic [1  : 0] layer1_col47;
    logic [1  : 0] layer1_col48;
    logic [1  : 0] layer1_col49;
    logic [1  : 0] layer1_col50;
    logic [1  : 0] layer1_col51;
    logic [1  : 0] layer1_col52;
    logic [1  : 0] layer1_col53;
    logic [1  : 0] layer1_col54;
    logic [1  : 0] layer1_col55;
    logic [1  : 0] layer1_col56;
    logic [1  : 0] layer1_col57;
    logic [1  : 0] layer1_col58;
    logic [1  : 0] layer1_col59;
    logic [1  : 0] layer1_col60;
    logic [1  : 0] layer1_col61;
    logic          layer1_col62;
    logic          layer1_col63;
    logic          layer1_col64;
    logic          layer1_col65;
    logic          layer1_col66;
    logic          layer1_col67;
    logic          layer1_col68;
    logic          layer1_col69;
    logic          layer1_col70;
    logic          layer1_col71;
    logic          layer1_col72;
    logic          layer1_col73;
    
    // terminal addition as a plain add: the tail of two-bit columns runs to the end of the heap
    logic [74:0] terminal_op0;
    logic [74:0] terminal_op1;
    logic [74:0] terminal_op2;
    logic [74:0] terminal_sum;
    
    // ------------------------------ LAYER 0 ------------------------------
    always_ff @(posedge clk) begin
        layer1_col0[0] <= layer0_col0[0];
        layer1_col0[1] <= layer0_col0[1];
        layer1_col0[2] <= layer0_col0[2];
        layer1_col1[0] <= layer0_col1[0];
        layer1_col1[1] <= layer0_col1[1];
        layer1_col2[0] <= layer0_col2[0];
        layer1_col2[1] <= layer0_col2[1];
        layer1_col3[0] <= layer0_col3[0];
        layer1_col3[1] <= layer0_col3[1];
        layer1_col4[0] <= layer0_col4[0];
        layer1_col4[1] <= layer0_col4[1];
        layer1_col5[0] <= layer0_col5[0];
        layer1_col5[1] <= layer0_col5[1];
        layer1_col6[0] <= layer0_col6[0];
        layer1_col6[1] <= layer0_col6[1];
        layer1_col7[0] <= layer0_col7[0];
        layer1_col7[1] <= layer0_col7[1];
        layer1_col8[0] <= layer0_col8[0];
        layer1_col8[1] <= layer0_col8[1];
        layer1_col9[0] <= layer0_col9[0];
        layer1_col9[1] <= layer0_col9[1];
        layer1_col10[0] <= layer0_col10[0];
        layer1_col10[1] <= layer0_col10[1];
        layer1_col11[0] <= layer0_col11[0];
        layer1_col11[1] <= layer0_col11[1];
        layer1_col12[0] <= layer0_col12[0];
        layer1_col12[1] <= layer0_col12[1];
        layer1_col13[0] <= layer0_col13[0];
        layer1_col13[1] <= layer0_col13[1];
        layer1_col14[0] <= layer0_col14[0];
        layer1_col14[1] <= layer0_col14[1];
        layer1_col15[0] <= layer0_col15[0];
        layer1_col15[1] <= layer0_col15[1];
        layer1_col16[0] <= layer0_col16[0];
        layer1_col16[1] <= layer0_col16[1];
        layer1_col17[0] <= layer0_col17[0];
        layer1_col17[1] <= layer0_col17[1];
        layer1_col18[0] <= layer0_col18[0];
        layer1_col18[1] <= layer0_col18[1];
        layer1_col19[0] <= layer0_col19[0];
        layer1_col19[1] <= layer0_col19[1];
        layer1_col20[0] <= layer0_col20[0];
        layer1_col20[1] <= layer0_col20[1];
        layer1_col21[0] <= layer0_col21[0];
        layer1_col21[1] <= layer0_col21[1];
        layer1_col22[0] <= layer0_col22[0];
        layer1_col22[1] <= layer0_col22[1];
        layer1_col23[0] <= layer0_col23[0];
        layer1_col23[1] <= layer0_col23[1];
        layer1_col24[0] <= layer0_col24[0];
        layer1_col24[1] <= layer0_col24[1];
        layer1_col25[0] <= layer0_col25[0];
        layer1_col25[1] <= layer0_col25[1];
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
        layer1_col47[0] <= layer0_col47[0];
        layer1_col47[1] <= layer0_col47[1];
        layer1_col48[0] <= layer0_col48[0];
        layer1_col48[1] <= layer0_col48[1];
        layer1_col49[0] <= layer0_col49[0];
        layer1_col49[1] <= layer0_col49[1];
        layer1_col50[0] <= layer0_col50[0];
        layer1_col50[1] <= layer0_col50[1];
        layer1_col51[0] <= layer0_col51[0];
        layer1_col51[1] <= layer0_col51[1];
        layer1_col52[0] <= layer0_col52[0];
        layer1_col52[1] <= layer0_col52[1];
        layer1_col53[0] <= layer0_col53[0];
        layer1_col53[1] <= layer0_col53[1];
        layer1_col54[0] <= layer0_col54[0];
        layer1_col54[1] <= layer0_col54[1];
        layer1_col55[0] <= layer0_col55[0];
        layer1_col55[1] <= layer0_col55[1];
        layer1_col56[0] <= layer0_col56[0];
        layer1_col56[1] <= layer0_col56[1];
        layer1_col57[0] <= layer0_col57[0];
        layer1_col57[1] <= layer0_col57[1];
        layer1_col58[0] <= layer0_col58[0];
        layer1_col58[1] <= layer0_col58[1];
        layer1_col59[0] <= layer0_col59[0];
        layer1_col59[1] <= layer0_col59[1];
        layer1_col60[0] <= layer0_col60[0];
        layer1_col60[1] <= layer0_col60[1];
        layer1_col61[0] <= layer0_col61[0];
        layer1_col61[1] <= layer0_col61[1];
        layer1_col62    <= layer0_col62;
        layer1_col63    <= layer0_col63;
        layer1_col64    <= layer0_col64;
        layer1_col65    <= layer0_col65;
        layer1_col66    <= layer0_col66;
        layer1_col67    <= layer0_col67;
        layer1_col68    <= layer0_col68;
        layer1_col69    <= layer0_col69;
        layer1_col70    <= layer0_col70;
        layer1_col71    <= layer0_col71;
        layer1_col72    <= layer0_col72;
        layer1_col73    <= layer0_col73;
    end
    
    
    
    // -------------------------------------------------- TERMINAL ADDITION ------------------------------------------------
    assign terminal_op0 = {1'b0, layer1_col73, layer1_col72, layer1_col71, layer1_col70, layer1_col69, layer1_col68, layer1_col67, layer1_col66, layer1_col65, layer1_col64, layer1_col63, layer1_col62, layer1_col61[0], layer1_col60[0], layer1_col59[0], layer1_col58[0], layer1_col57[0], layer1_col56[0], layer1_col55[0], layer1_col54[0], layer1_col53[0], layer1_col52[0], layer1_col51[0], layer1_col50[0], layer1_col49[0], layer1_col48[0], layer1_col47[0], layer1_col46[0], layer1_col45[0], layer1_col44[0], layer1_col43[0], layer1_col42[0], layer1_col41[0], layer1_col40[0], layer1_col39[0], layer1_col38[0], layer1_col37[0], layer1_col36[0], layer1_col35[0], layer1_col34[0], layer1_col33[0], layer1_col32[0], layer1_col31[0], layer1_col30[0], layer1_col29[0], layer1_col28[0], layer1_col27[0], layer1_col26[0], layer1_col25[0], layer1_col24[0], layer1_col23[0], layer1_col22[0], layer1_col21[0], layer1_col20[0], layer1_col19[0], layer1_col18[0], layer1_col17[0], layer1_col16[0], layer1_col15[0], layer1_col14[0], layer1_col13[0], layer1_col12[0], layer1_col11[0], layer1_col10[0], layer1_col9[0], layer1_col8[0], layer1_col7[0], layer1_col6[0], layer1_col5[0], layer1_col4[0], layer1_col3[0], layer1_col2[0], layer1_col1[0], layer1_col0[0]};
    assign terminal_op1 = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, layer1_col61[1], layer1_col60[1], layer1_col59[1], layer1_col58[1], layer1_col57[1], layer1_col56[1], layer1_col55[1], layer1_col54[1], layer1_col53[1], layer1_col52[1], layer1_col51[1], layer1_col50[1], layer1_col49[1], layer1_col48[1], layer1_col47[1], layer1_col46[1], layer1_col45[1], layer1_col44[1], layer1_col43[1], layer1_col42[1], layer1_col41[1], layer1_col40[1], layer1_col39[1], layer1_col38[1], layer1_col37[1], layer1_col36[1], layer1_col35[1], layer1_col34[1], layer1_col33[1], layer1_col32[1], layer1_col31[1], layer1_col30[1], layer1_col29[1], layer1_col28[1], layer1_col27[1], layer1_col26[1], layer1_col25[1], layer1_col24[1], layer1_col23[1], layer1_col22[1], layer1_col21[1], layer1_col20[1], layer1_col19[1], layer1_col18[1], layer1_col17[1], layer1_col16[1], layer1_col15[1], layer1_col14[1], layer1_col13[1], layer1_col12[1], layer1_col11[1], layer1_col10[1], layer1_col9[1], layer1_col8[1], layer1_col7[1], layer1_col6[1], layer1_col5[1], layer1_col4[1], layer1_col3[1], layer1_col2[1], layer1_col1[1], layer1_col0[1]};
    assign terminal_op2 = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, layer1_col0[2]};
    assign terminal_sum = terminal_op0 + terminal_op1 + terminal_op2;
    
    always_ff @(posedge clk) begin
        comp_out <= terminal_sum;
    end
    
    // -------------------------------------- ASSIGNMENT OF MODULE INPUTS AND COMPRESSOR INPUTS --------------------------------------
    assign layer0_col0    = col0;
    assign layer0_col1    = col1;
    assign layer0_col2    = col2;
    assign layer0_col3    = col3;
    assign layer0_col4    = col4;
    assign layer0_col5    = col5;
    assign layer0_col6    = col6;
    assign layer0_col7    = col7;
    assign layer0_col8    = col8;
    assign layer0_col9    = col9;
    assign layer0_col10   = col10;
    assign layer0_col11   = col11;
    assign layer0_col12   = col12;
    assign layer0_col13   = col13;
    assign layer0_col14   = col14;
    assign layer0_col15   = col15;
    assign layer0_col16   = col16;
    assign layer0_col17   = col17;
    assign layer0_col18   = col18;
    assign layer0_col19   = col19;
    assign layer0_col20   = col20;
    assign layer0_col21   = col21;
    assign layer0_col22   = col22;
    assign layer0_col23   = col23;
    assign layer0_col24   = col24;
    assign layer0_col25   = col25;
    assign layer0_col26   = col26;
    assign layer0_col27   = col27;
    assign layer0_col28   = col28;
    assign layer0_col29   = col29;
    assign layer0_col30   = col30;
    assign layer0_col31   = col31;
    assign layer0_col32   = col32;
    assign layer0_col33   = col33;
    assign layer0_col34   = col34;
    assign layer0_col35   = col35;
    assign layer0_col36   = col36;
    assign layer0_col37   = col37;
    assign layer0_col38   = col38;
    assign layer0_col39   = col39;
    assign layer0_col40   = col40;
    assign layer0_col41   = col41;
    assign layer0_col42   = col42;
    assign layer0_col43   = col43;
    assign layer0_col44   = col44;
    assign layer0_col45   = col45;
    assign layer0_col46   = col46;
    assign layer0_col47   = col47;
    assign layer0_col48   = col48;
    assign layer0_col49   = col49;
    assign layer0_col50   = col50;
    assign layer0_col51   = col51;
    assign layer0_col52   = col52;
    assign layer0_col53   = col53;
    assign layer0_col54   = col54;
    assign layer0_col55   = col55;
    assign layer0_col56   = col56;
    assign layer0_col57   = col57;
    assign layer0_col58   = col58;
    assign layer0_col59   = col59;
    assign layer0_col60   = col60;
    assign layer0_col61   = col61;
    assign layer0_col62   = col62;
    assign layer0_col63   = col63;
    assign layer0_col64   = col64;
    assign layer0_col65   = col65;
    assign layer0_col66   = col66;
    assign layer0_col67   = col67;
    assign layer0_col68   = col68;
    assign layer0_col69   = col69;
    assign layer0_col70   = col70;
    assign layer0_col71   = col71;
    assign layer0_col72   = col72;
    assign layer0_col73   = col73;
    
endmodule