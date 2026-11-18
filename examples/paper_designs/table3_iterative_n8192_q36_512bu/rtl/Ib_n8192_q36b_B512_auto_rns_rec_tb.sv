`timescale 1ns / 1ps
module Ib_n8192_q36b_B512_auto_rns_rec_tb ();
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst, in_valid, in_ready, out_valid;
    logic DIR = 1'b1;
    logic tw_valid, tw_ready; logic [71:0] tw_data; logic [71:0] tw_ts [99]; logic twpat [1376];
    logic [35:0] x_in_0; logic [35:0] x_ts_0 [768];
    logic [35:0] y_out_0; logic [35:0] y_ts_0 [768];
    logic [35:0] x_in_1; logic [35:0] x_ts_1 [768];
    logic [35:0] y_out_1; logic [35:0] y_ts_1 [768];
    logic [35:0] x_in_2; logic [35:0] x_ts_2 [768];
    logic [35:0] y_out_2; logic [35:0] y_ts_2 [768];
    logic [35:0] x_in_3; logic [35:0] x_ts_3 [768];
    logic [35:0] y_out_3; logic [35:0] y_ts_3 [768];
    logic [35:0] x_in_4; logic [35:0] x_ts_4 [768];
    logic [35:0] y_out_4; logic [35:0] y_ts_4 [768];
    logic [35:0] x_in_5; logic [35:0] x_ts_5 [768];
    logic [35:0] y_out_5; logic [35:0] y_ts_5 [768];
    logic [35:0] x_in_6; logic [35:0] x_ts_6 [768];
    logic [35:0] y_out_6; logic [35:0] y_ts_6 [768];
    logic [35:0] x_in_7; logic [35:0] x_ts_7 [768];
    logic [35:0] y_out_7; logic [35:0] y_ts_7 [768];
    logic [35:0] x_in_8; logic [35:0] x_ts_8 [768];
    logic [35:0] y_out_8; logic [35:0] y_ts_8 [768];
    logic [35:0] x_in_9; logic [35:0] x_ts_9 [768];
    logic [35:0] y_out_9; logic [35:0] y_ts_9 [768];
    logic [35:0] x_in_10; logic [35:0] x_ts_10 [768];
    logic [35:0] y_out_10; logic [35:0] y_ts_10 [768];
    logic [35:0] x_in_11; logic [35:0] x_ts_11 [768];
    logic [35:0] y_out_11; logic [35:0] y_ts_11 [768];
    logic [35:0] x_in_12; logic [35:0] x_ts_12 [768];
    logic [35:0] y_out_12; logic [35:0] y_ts_12 [768];
    logic [35:0] x_in_13; logic [35:0] x_ts_13 [768];
    logic [35:0] y_out_13; logic [35:0] y_ts_13 [768];
    logic [35:0] x_in_14; logic [35:0] x_ts_14 [768];
    logic [35:0] y_out_14; logic [35:0] y_ts_14 [768];
    logic [35:0] x_in_15; logic [35:0] x_ts_15 [768];
    logic [35:0] y_out_15; logic [35:0] y_ts_15 [768];
    logic [35:0] x_in_16; logic [35:0] x_ts_16 [768];
    logic [35:0] y_out_16; logic [35:0] y_ts_16 [768];
    logic [35:0] x_in_17; logic [35:0] x_ts_17 [768];
    logic [35:0] y_out_17; logic [35:0] y_ts_17 [768];
    logic [35:0] x_in_18; logic [35:0] x_ts_18 [768];
    logic [35:0] y_out_18; logic [35:0] y_ts_18 [768];
    logic [35:0] x_in_19; logic [35:0] x_ts_19 [768];
    logic [35:0] y_out_19; logic [35:0] y_ts_19 [768];
    logic [35:0] x_in_20; logic [35:0] x_ts_20 [768];
    logic [35:0] y_out_20; logic [35:0] y_ts_20 [768];
    logic [35:0] x_in_21; logic [35:0] x_ts_21 [768];
    logic [35:0] y_out_21; logic [35:0] y_ts_21 [768];
    logic [35:0] x_in_22; logic [35:0] x_ts_22 [768];
    logic [35:0] y_out_22; logic [35:0] y_ts_22 [768];
    logic [35:0] x_in_23; logic [35:0] x_ts_23 [768];
    logic [35:0] y_out_23; logic [35:0] y_ts_23 [768];
    logic [35:0] x_in_24; logic [35:0] x_ts_24 [768];
    logic [35:0] y_out_24; logic [35:0] y_ts_24 [768];
    logic [35:0] x_in_25; logic [35:0] x_ts_25 [768];
    logic [35:0] y_out_25; logic [35:0] y_ts_25 [768];
    logic [35:0] x_in_26; logic [35:0] x_ts_26 [768];
    logic [35:0] y_out_26; logic [35:0] y_ts_26 [768];
    logic [35:0] x_in_27; logic [35:0] x_ts_27 [768];
    logic [35:0] y_out_27; logic [35:0] y_ts_27 [768];
    logic [35:0] x_in_28; logic [35:0] x_ts_28 [768];
    logic [35:0] y_out_28; logic [35:0] y_ts_28 [768];
    logic [35:0] x_in_29; logic [35:0] x_ts_29 [768];
    logic [35:0] y_out_29; logic [35:0] y_ts_29 [768];
    logic [35:0] x_in_30; logic [35:0] x_ts_30 [768];
    logic [35:0] y_out_30; logic [35:0] y_ts_30 [768];
    logic [35:0] x_in_31; logic [35:0] x_ts_31 [768];
    logic [35:0] y_out_31; logic [35:0] y_ts_31 [768];
    logic [31:0] ycyc [768]; logic vpat [1376];
    initial begin
        $readmemh("../../../../../testvectors/x_0.txt", x_ts_0);
        $readmemh("../../../../../testvectors/y_0.txt", y_ts_0);
        $readmemh("../../../../../testvectors/x_1.txt", x_ts_1);
        $readmemh("../../../../../testvectors/y_1.txt", y_ts_1);
        $readmemh("../../../../../testvectors/x_2.txt", x_ts_2);
        $readmemh("../../../../../testvectors/y_2.txt", y_ts_2);
        $readmemh("../../../../../testvectors/x_3.txt", x_ts_3);
        $readmemh("../../../../../testvectors/y_3.txt", y_ts_3);
        $readmemh("../../../../../testvectors/x_4.txt", x_ts_4);
        $readmemh("../../../../../testvectors/y_4.txt", y_ts_4);
        $readmemh("../../../../../testvectors/x_5.txt", x_ts_5);
        $readmemh("../../../../../testvectors/y_5.txt", y_ts_5);
        $readmemh("../../../../../testvectors/x_6.txt", x_ts_6);
        $readmemh("../../../../../testvectors/y_6.txt", y_ts_6);
        $readmemh("../../../../../testvectors/x_7.txt", x_ts_7);
        $readmemh("../../../../../testvectors/y_7.txt", y_ts_7);
        $readmemh("../../../../../testvectors/x_8.txt", x_ts_8);
        $readmemh("../../../../../testvectors/y_8.txt", y_ts_8);
        $readmemh("../../../../../testvectors/x_9.txt", x_ts_9);
        $readmemh("../../../../../testvectors/y_9.txt", y_ts_9);
        $readmemh("../../../../../testvectors/x_10.txt", x_ts_10);
        $readmemh("../../../../../testvectors/y_10.txt", y_ts_10);
        $readmemh("../../../../../testvectors/x_11.txt", x_ts_11);
        $readmemh("../../../../../testvectors/y_11.txt", y_ts_11);
        $readmemh("../../../../../testvectors/x_12.txt", x_ts_12);
        $readmemh("../../../../../testvectors/y_12.txt", y_ts_12);
        $readmemh("../../../../../testvectors/x_13.txt", x_ts_13);
        $readmemh("../../../../../testvectors/y_13.txt", y_ts_13);
        $readmemh("../../../../../testvectors/x_14.txt", x_ts_14);
        $readmemh("../../../../../testvectors/y_14.txt", y_ts_14);
        $readmemh("../../../../../testvectors/x_15.txt", x_ts_15);
        $readmemh("../../../../../testvectors/y_15.txt", y_ts_15);
        $readmemh("../../../../../testvectors/x_16.txt", x_ts_16);
        $readmemh("../../../../../testvectors/y_16.txt", y_ts_16);
        $readmemh("../../../../../testvectors/x_17.txt", x_ts_17);
        $readmemh("../../../../../testvectors/y_17.txt", y_ts_17);
        $readmemh("../../../../../testvectors/x_18.txt", x_ts_18);
        $readmemh("../../../../../testvectors/y_18.txt", y_ts_18);
        $readmemh("../../../../../testvectors/x_19.txt", x_ts_19);
        $readmemh("../../../../../testvectors/y_19.txt", y_ts_19);
        $readmemh("../../../../../testvectors/x_20.txt", x_ts_20);
        $readmemh("../../../../../testvectors/y_20.txt", y_ts_20);
        $readmemh("../../../../../testvectors/x_21.txt", x_ts_21);
        $readmemh("../../../../../testvectors/y_21.txt", y_ts_21);
        $readmemh("../../../../../testvectors/x_22.txt", x_ts_22);
        $readmemh("../../../../../testvectors/y_22.txt", y_ts_22);
        $readmemh("../../../../../testvectors/x_23.txt", x_ts_23);
        $readmemh("../../../../../testvectors/y_23.txt", y_ts_23);
        $readmemh("../../../../../testvectors/x_24.txt", x_ts_24);
        $readmemh("../../../../../testvectors/y_24.txt", y_ts_24);
        $readmemh("../../../../../testvectors/x_25.txt", x_ts_25);
        $readmemh("../../../../../testvectors/y_25.txt", y_ts_25);
        $readmemh("../../../../../testvectors/x_26.txt", x_ts_26);
        $readmemh("../../../../../testvectors/y_26.txt", y_ts_26);
        $readmemh("../../../../../testvectors/x_27.txt", x_ts_27);
        $readmemh("../../../../../testvectors/y_27.txt", y_ts_27);
        $readmemh("../../../../../testvectors/x_28.txt", x_ts_28);
        $readmemh("../../../../../testvectors/y_28.txt", y_ts_28);
        $readmemh("../../../../../testvectors/x_29.txt", x_ts_29);
        $readmemh("../../../../../testvectors/y_29.txt", y_ts_29);
        $readmemh("../../../../../testvectors/x_30.txt", x_ts_30);
        $readmemh("../../../../../testvectors/y_30.txt", y_ts_30);
        $readmemh("../../../../../testvectors/x_31.txt", x_ts_31);
        $readmemh("../../../../../testvectors/y_31.txt", y_ts_31);
        $readmemh("../../../../../testvectors/ycycle.txt", ycyc);
        $readmemh("../../../../../testvectors/valid.txt", vpat);
        $readmemh("../../../../../testvectors/tw_stream.txt", tw_ts);
        $readmemh("../../../../../testvectors/twvalid.txt", twpat);
    end
    Ib_n8192_q36b_B512_auto_rns_rec DUT (.clk(clk), .rst(rst), .DIR(DIR), .tw_valid(tw_valid), .tw_ready(tw_ready), .tw_data(tw_data), .in_valid(in_valid), .in_ready(in_ready), .x_in_0(x_in_0), .x_in_1(x_in_1), .x_in_2(x_in_2), .x_in_3(x_in_3), .x_in_4(x_in_4), .x_in_5(x_in_5), .x_in_6(x_in_6), .x_in_7(x_in_7), .x_in_8(x_in_8), .x_in_9(x_in_9), .x_in_10(x_in_10), .x_in_11(x_in_11), .x_in_12(x_in_12), .x_in_13(x_in_13), .x_in_14(x_in_14), .x_in_15(x_in_15), .x_in_16(x_in_16), .x_in_17(x_in_17), .x_in_18(x_in_18), .x_in_19(x_in_19), .x_in_20(x_in_20), .x_in_21(x_in_21), .x_in_22(x_in_22), .x_in_23(x_in_23), .x_in_24(x_in_24), .x_in_25(x_in_25), .x_in_26(x_in_26), .x_in_27(x_in_27), .x_in_28(x_in_28), .x_in_29(x_in_29), .x_in_30(x_in_30), .x_in_31(x_in_31), .out_valid(out_valid), .y_out_0(y_out_0), .y_out_1(y_out_1), .y_out_2(y_out_2), .y_out_3(y_out_3), .y_out_4(y_out_4), .y_out_5(y_out_5), .y_out_6(y_out_6), .y_out_7(y_out_7), .y_out_8(y_out_8), .y_out_9(y_out_9), .y_out_10(y_out_10), .y_out_11(y_out_11), .y_out_12(y_out_12), .y_out_13(y_out_13), .y_out_14(y_out_14), .y_out_15(y_out_15), .y_out_16(y_out_16), .y_out_17(y_out_17), .y_out_18(y_out_18), .y_out_19(y_out_19), .y_out_20(y_out_20), .y_out_21(y_out_21), .y_out_22(y_out_22), .y_out_23(y_out_23), .y_out_24(y_out_24), .y_out_25(y_out_25), .y_out_26(y_out_26), .y_out_27(y_out_27), .y_out_28(y_out_28), .y_out_29(y_out_29), .y_out_30(y_out_30), .y_out_31(y_out_31));
    int c, bad, xb, ob, late, twb;
    initial begin
        bad = 0; xb = 0; ob = 0; late = 0; rst = 1'b1; in_valid = 1'b0;
        twb = 0; tw_valid = 1'b0; tw_data = '0;
        x_in_0 = '0;
        x_in_1 = '0;
        x_in_2 = '0;
        x_in_3 = '0;
        x_in_4 = '0;
        x_in_5 = '0;
        x_in_6 = '0;
        x_in_7 = '0;
        x_in_8 = '0;
        x_in_9 = '0;
        x_in_10 = '0;
        x_in_11 = '0;
        x_in_12 = '0;
        x_in_13 = '0;
        x_in_14 = '0;
        x_in_15 = '0;
        x_in_16 = '0;
        x_in_17 = '0;
        x_in_18 = '0;
        x_in_19 = '0;
        x_in_20 = '0;
        x_in_21 = '0;
        x_in_22 = '0;
        x_in_23 = '0;
        x_in_24 = '0;
        x_in_25 = '0;
        x_in_26 = '0;
        x_in_27 = '0;
        x_in_28 = '0;
        x_in_29 = '0;
        x_in_30 = '0;
        x_in_31 = '0;
        repeat (30) @(posedge clk);
        for (c = 0; c < 1376; c++) begin
            #1;
            rst = 1'b0;
            in_valid = vpat[c] && (xb < 768);
            tw_valid = twpat[c] && (twb < 99);
            tw_data = (twb < 99) ? tw_ts[twb] : '0;
            x_in_0 = (xb < 768) ? x_ts_0[xb] : '0;
            x_in_1 = (xb < 768) ? x_ts_1[xb] : '0;
            x_in_2 = (xb < 768) ? x_ts_2[xb] : '0;
            x_in_3 = (xb < 768) ? x_ts_3[xb] : '0;
            x_in_4 = (xb < 768) ? x_ts_4[xb] : '0;
            x_in_5 = (xb < 768) ? x_ts_5[xb] : '0;
            x_in_6 = (xb < 768) ? x_ts_6[xb] : '0;
            x_in_7 = (xb < 768) ? x_ts_7[xb] : '0;
            x_in_8 = (xb < 768) ? x_ts_8[xb] : '0;
            x_in_9 = (xb < 768) ? x_ts_9[xb] : '0;
            x_in_10 = (xb < 768) ? x_ts_10[xb] : '0;
            x_in_11 = (xb < 768) ? x_ts_11[xb] : '0;
            x_in_12 = (xb < 768) ? x_ts_12[xb] : '0;
            x_in_13 = (xb < 768) ? x_ts_13[xb] : '0;
            x_in_14 = (xb < 768) ? x_ts_14[xb] : '0;
            x_in_15 = (xb < 768) ? x_ts_15[xb] : '0;
            x_in_16 = (xb < 768) ? x_ts_16[xb] : '0;
            x_in_17 = (xb < 768) ? x_ts_17[xb] : '0;
            x_in_18 = (xb < 768) ? x_ts_18[xb] : '0;
            x_in_19 = (xb < 768) ? x_ts_19[xb] : '0;
            x_in_20 = (xb < 768) ? x_ts_20[xb] : '0;
            x_in_21 = (xb < 768) ? x_ts_21[xb] : '0;
            x_in_22 = (xb < 768) ? x_ts_22[xb] : '0;
            x_in_23 = (xb < 768) ? x_ts_23[xb] : '0;
            x_in_24 = (xb < 768) ? x_ts_24[xb] : '0;
            x_in_25 = (xb < 768) ? x_ts_25[xb] : '0;
            x_in_26 = (xb < 768) ? x_ts_26[xb] : '0;
            x_in_27 = (xb < 768) ? x_ts_27[xb] : '0;
            x_in_28 = (xb < 768) ? x_ts_28[xb] : '0;
            x_in_29 = (xb < 768) ? x_ts_29[xb] : '0;
            x_in_30 = (xb < 768) ? x_ts_30[xb] : '0;
            x_in_31 = (xb < 768) ? x_ts_31[xb] : '0;
            #2;
            if (out_valid && ob < 768 && (ob % 256 == 0 || ob % 256 == 255)) $display("MEAS out %s poly %0d cycle %0d", (ob % 256 == 0) ? "first" : "last", ob / 256, c);
            if (out_valid) begin
                if (ob >= 768) begin bad++; if (bad < 10) $display("WRONG extra output beat at cycle %0d", c); end
                else begin
                    if (c != ycyc[ob]) begin late++; if (late < 5) $display("WRONG beat %0d at cycle %0d, the model says %0d", ob, c, ycyc[ob]); end
                    if (y_out_0 !== y_ts_0[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 0: got %h want %h", ob, y_out_0, y_ts_0[ob]); end
                    if (y_out_1 !== y_ts_1[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 1: got %h want %h", ob, y_out_1, y_ts_1[ob]); end
                    if (y_out_2 !== y_ts_2[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 2: got %h want %h", ob, y_out_2, y_ts_2[ob]); end
                    if (y_out_3 !== y_ts_3[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 3: got %h want %h", ob, y_out_3, y_ts_3[ob]); end
                    if (y_out_4 !== y_ts_4[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 4: got %h want %h", ob, y_out_4, y_ts_4[ob]); end
                    if (y_out_5 !== y_ts_5[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 5: got %h want %h", ob, y_out_5, y_ts_5[ob]); end
                    if (y_out_6 !== y_ts_6[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 6: got %h want %h", ob, y_out_6, y_ts_6[ob]); end
                    if (y_out_7 !== y_ts_7[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 7: got %h want %h", ob, y_out_7, y_ts_7[ob]); end
                    if (y_out_8 !== y_ts_8[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 8: got %h want %h", ob, y_out_8, y_ts_8[ob]); end
                    if (y_out_9 !== y_ts_9[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 9: got %h want %h", ob, y_out_9, y_ts_9[ob]); end
                    if (y_out_10 !== y_ts_10[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 10: got %h want %h", ob, y_out_10, y_ts_10[ob]); end
                    if (y_out_11 !== y_ts_11[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 11: got %h want %h", ob, y_out_11, y_ts_11[ob]); end
                    if (y_out_12 !== y_ts_12[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 12: got %h want %h", ob, y_out_12, y_ts_12[ob]); end
                    if (y_out_13 !== y_ts_13[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 13: got %h want %h", ob, y_out_13, y_ts_13[ob]); end
                    if (y_out_14 !== y_ts_14[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 14: got %h want %h", ob, y_out_14, y_ts_14[ob]); end
                    if (y_out_15 !== y_ts_15[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 15: got %h want %h", ob, y_out_15, y_ts_15[ob]); end
                    if (y_out_16 !== y_ts_16[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 16: got %h want %h", ob, y_out_16, y_ts_16[ob]); end
                    if (y_out_17 !== y_ts_17[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 17: got %h want %h", ob, y_out_17, y_ts_17[ob]); end
                    if (y_out_18 !== y_ts_18[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 18: got %h want %h", ob, y_out_18, y_ts_18[ob]); end
                    if (y_out_19 !== y_ts_19[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 19: got %h want %h", ob, y_out_19, y_ts_19[ob]); end
                    if (y_out_20 !== y_ts_20[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 20: got %h want %h", ob, y_out_20, y_ts_20[ob]); end
                    if (y_out_21 !== y_ts_21[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 21: got %h want %h", ob, y_out_21, y_ts_21[ob]); end
                    if (y_out_22 !== y_ts_22[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 22: got %h want %h", ob, y_out_22, y_ts_22[ob]); end
                    if (y_out_23 !== y_ts_23[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 23: got %h want %h", ob, y_out_23, y_ts_23[ob]); end
                    if (y_out_24 !== y_ts_24[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 24: got %h want %h", ob, y_out_24, y_ts_24[ob]); end
                    if (y_out_25 !== y_ts_25[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 25: got %h want %h", ob, y_out_25, y_ts_25[ob]); end
                    if (y_out_26 !== y_ts_26[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 26: got %h want %h", ob, y_out_26, y_ts_26[ob]); end
                    if (y_out_27 !== y_ts_27[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 27: got %h want %h", ob, y_out_27, y_ts_27[ob]); end
                    if (y_out_28 !== y_ts_28[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 28: got %h want %h", ob, y_out_28, y_ts_28[ob]); end
                    if (y_out_29 !== y_ts_29[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 29: got %h want %h", ob, y_out_29, y_ts_29[ob]); end
                    if (y_out_30 !== y_ts_30[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 30: got %h want %h", ob, y_out_30, y_ts_30[ob]); end
                    if (y_out_31 !== y_ts_31[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 31: got %h want %h", ob, y_out_31, y_ts_31[ob]); end
                    ob++;
                end
            end
            if (in_valid && in_ready && (xb % 256 == 0 || xb % 256 == 255)) $display("MEAS in %s poly %0d cycle %0d", (xb % 256 == 0) ? "first" : "last", xb / 256, c);
            if (in_valid && in_ready) xb++;
            if (tw_valid && tw_ready) twb++;
            @(posedge clk);
        end
        if (ob != 768) begin bad++; $display("WRONG: %0d of 768 output beats", ob); end
        if (xb != 768) begin bad++; $display("WRONG: %0d of 768 input beats accepted", xb); end
        if (twb != 99) begin bad++; $display("WRONG: %0d of 99 record beats accepted", twb); end
        bad = bad + late;
        if (bad == 0) begin $display("SUCCESS!"); $display("PASS All %0d Testvectors!", ob); end
        else begin $display("TO BE DEBUGGED..."); $display("FAILED: %0d wrong", bad); end
        $finish();
    end
endmodule
