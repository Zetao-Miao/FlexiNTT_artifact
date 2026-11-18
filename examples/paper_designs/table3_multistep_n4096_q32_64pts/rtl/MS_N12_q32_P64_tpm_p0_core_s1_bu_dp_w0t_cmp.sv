`timescale 1ns / 1ps

module MS_N12_q32_P64_tpm_p0_core_s1_bu_dp_w0t_cmp (
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
    input  logic          col32,
    input  logic          col33,
    input  logic          col34,
    input  logic          col35,
    input  logic          col36,
    input  logic          col37,
    input  logic          col38,
    input  logic          col39,
    input  logic          col40,
    input  logic          col41,
    input  logic          col42,
    input  logic          col43,
    input  logic          col44,
    input  logic          col45,
    input  logic          col46,
    input  logic          col47,
    output logic [48 : 0] comp_out
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
    logic          layer0_col32;
    logic          layer0_col33;
    logic          layer0_col34;
    logic          layer0_col35;
    logic          layer0_col36;
    logic          layer0_col37;
    logic          layer0_col38;
    logic          layer0_col39;
    logic          layer0_col40;
    logic          layer0_col41;
    logic          layer0_col42;
    logic          layer0_col43;
    logic          layer0_col44;
    logic          layer0_col45;
    logic          layer0_col46;
    logic          layer0_col47;
    
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
    logic          layer1_col32;
    logic          layer1_col33;
    logic          layer1_col34;
    logic          layer1_col35;
    logic          layer1_col36;
    logic          layer1_col37;
    logic          layer1_col38;
    logic          layer1_col39;
    logic          layer1_col40;
    logic          layer1_col41;
    logic          layer1_col42;
    logic          layer1_col43;
    logic          layer1_col44;
    logic          layer1_col45;
    logic          layer1_col46;
    logic          layer1_col47;
    
    // terminal addition as a plain add: the tail of two-bit columns runs to the end of the heap
    logic [48:0] terminal_op0;
    logic [48:0] terminal_op1;
    logic [48:0] terminal_op2;
    logic [48:0] terminal_sum;
    
    // ------------------------------ LAYER 0 ------------------------------
    assign layer1_col0 = layer0_col0;
    assign layer1_col1 = layer0_col1;
    assign layer1_col2 = layer0_col2;
    assign layer1_col3 = layer0_col3;
    assign layer1_col4 = layer0_col4;
    assign layer1_col5 = layer0_col5;
    assign layer1_col6 = layer0_col6;
    assign layer1_col7 = layer0_col7;
    assign layer1_col8 = layer0_col8;
    assign layer1_col9 = layer0_col9;
    assign layer1_col10 = layer0_col10;
    assign layer1_col11 = layer0_col11;
    assign layer1_col12 = layer0_col12;
    assign layer1_col13 = layer0_col13;
    assign layer1_col14 = layer0_col14;
    assign layer1_col15 = layer0_col15;
    assign layer1_col16 = layer0_col16;
    assign layer1_col17 = layer0_col17;
    assign layer1_col18 = layer0_col18;
    assign layer1_col19 = layer0_col19;
    assign layer1_col20 = layer0_col20;
    assign layer1_col21 = layer0_col21;
    assign layer1_col22 = layer0_col22;
    assign layer1_col23 = layer0_col23;
    assign layer1_col24 = layer0_col24;
    assign layer1_col25 = layer0_col25;
    assign layer1_col26 = layer0_col26;
    assign layer1_col27 = layer0_col27;
    assign layer1_col28 = layer0_col28;
    assign layer1_col29 = layer0_col29;
    assign layer1_col30 = layer0_col30;
    assign layer1_col31 = layer0_col31;
    assign layer1_col32    = layer0_col32;
    assign layer1_col33    = layer0_col33;
    assign layer1_col34    = layer0_col34;
    assign layer1_col35    = layer0_col35;
    assign layer1_col36    = layer0_col36;
    assign layer1_col37    = layer0_col37;
    assign layer1_col38    = layer0_col38;
    assign layer1_col39    = layer0_col39;
    assign layer1_col40    = layer0_col40;
    assign layer1_col41    = layer0_col41;
    assign layer1_col42    = layer0_col42;
    assign layer1_col43    = layer0_col43;
    assign layer1_col44    = layer0_col44;
    assign layer1_col45    = layer0_col45;
    assign layer1_col46    = layer0_col46;
    assign layer1_col47    = layer0_col47;
    
    
    // -------------------------------------------------- TERMINAL ADDITION ------------------------------------------------
    assign terminal_op0 = {1'b0, layer1_col47, layer1_col46, layer1_col45, layer1_col44, layer1_col43, layer1_col42, layer1_col41, layer1_col40, layer1_col39, layer1_col38, layer1_col37, layer1_col36, layer1_col35, layer1_col34, layer1_col33, layer1_col32, layer1_col31[0], layer1_col30[0], layer1_col29[0], layer1_col28[0], layer1_col27[0], layer1_col26[0], layer1_col25[0], layer1_col24[0], layer1_col23[0], layer1_col22[0], layer1_col21[0], layer1_col20[0], layer1_col19[0], layer1_col18[0], layer1_col17[0], layer1_col16[0], layer1_col15[0], layer1_col14[0], layer1_col13[0], layer1_col12[0], layer1_col11[0], layer1_col10[0], layer1_col9[0], layer1_col8[0], layer1_col7[0], layer1_col6[0], layer1_col5[0], layer1_col4[0], layer1_col3[0], layer1_col2[0], layer1_col1[0], layer1_col0[0]};
    assign terminal_op1 = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, layer1_col31[1], layer1_col30[1], layer1_col29[1], layer1_col28[1], layer1_col27[1], layer1_col26[1], layer1_col25[1], layer1_col24[1], layer1_col23[1], layer1_col22[1], layer1_col21[1], layer1_col20[1], layer1_col19[1], layer1_col18[1], layer1_col17[1], layer1_col16[1], layer1_col15[1], layer1_col14[1], layer1_col13[1], layer1_col12[1], layer1_col11[1], layer1_col10[1], layer1_col9[1], layer1_col8[1], layer1_col7[1], layer1_col6[1], layer1_col5[1], layer1_col4[1], layer1_col3[1], layer1_col2[1], layer1_col1[1], layer1_col0[1]};
    assign terminal_op2 = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, layer1_col0[2]};
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
    
endmodule