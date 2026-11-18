`timescale 1ns / 1ps
module LDd_rom1_tb ();
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst;
    logic DIR; logic di_ts [3];
    logic [0:0] MIDX; logic [0:0] mi_ts [3];
    logic [31:0] mq_QH; logic [31:0] mq_QH_ts [3];
    logic [63:0] mq_QHALF; logic [63:0] mq_QHALF_ts [3];
    initial begin
        mq_QH_ts[0] = 32'h80000025; mq_QHALF_ts[0] = 64'h4000001280000001;
        mq_QH_ts[1] = 32'h80000025; mq_QHALF_ts[1] = 64'h4000001280000001;
        mq_QH_ts[2] = 32'h80000025; mq_QHALF_ts[2] = 64'h4000001280000001;
    end
    logic tw_rst, tw_wen; logic [63:0] tw_wdata; logic [63:0] tw_ts [8158];
    logic [0:0] tw_slot;
    logic [63:0] x_in_0; logic [63:0] x_ts_0 [384];
    logic [63:0] y_out_0; logic [63:0] y_ts_0 [384];
    logic [63:0] x_in_1; logic [63:0] x_ts_1 [384];
    logic [63:0] y_out_1; logic [63:0] y_ts_1 [384];
    logic [63:0] x_in_2; logic [63:0] x_ts_2 [384];
    logic [63:0] y_out_2; logic [63:0] y_ts_2 [384];
    logic [63:0] x_in_3; logic [63:0] x_ts_3 [384];
    logic [63:0] y_out_3; logic [63:0] y_ts_3 [384];
    logic [63:0] x_in_4; logic [63:0] x_ts_4 [384];
    logic [63:0] y_out_4; logic [63:0] y_ts_4 [384];
    logic [63:0] x_in_5; logic [63:0] x_ts_5 [384];
    logic [63:0] y_out_5; logic [63:0] y_ts_5 [384];
    logic [63:0] x_in_6; logic [63:0] x_ts_6 [384];
    logic [63:0] y_out_6; logic [63:0] y_ts_6 [384];
    logic [63:0] x_in_7; logic [63:0] x_ts_7 [384];
    logic [63:0] y_out_7; logic [63:0] y_ts_7 [384];
    logic [63:0] x_in_8; logic [63:0] x_ts_8 [384];
    logic [63:0] y_out_8; logic [63:0] y_ts_8 [384];
    logic [63:0] x_in_9; logic [63:0] x_ts_9 [384];
    logic [63:0] y_out_9; logic [63:0] y_ts_9 [384];
    logic [63:0] x_in_10; logic [63:0] x_ts_10 [384];
    logic [63:0] y_out_10; logic [63:0] y_ts_10 [384];
    logic [63:0] x_in_11; logic [63:0] x_ts_11 [384];
    logic [63:0] y_out_11; logic [63:0] y_ts_11 [384];
    logic [63:0] x_in_12; logic [63:0] x_ts_12 [384];
    logic [63:0] y_out_12; logic [63:0] y_ts_12 [384];
    logic [63:0] x_in_13; logic [63:0] x_ts_13 [384];
    logic [63:0] y_out_13; logic [63:0] y_ts_13 [384];
    logic [63:0] x_in_14; logic [63:0] x_ts_14 [384];
    logic [63:0] y_out_14; logic [63:0] y_ts_14 [384];
    logic [63:0] x_in_15; logic [63:0] x_ts_15 [384];
    logic [63:0] y_out_15; logic [63:0] y_ts_15 [384];
    logic [63:0] x_in_16; logic [63:0] x_ts_16 [384];
    logic [63:0] y_out_16; logic [63:0] y_ts_16 [384];
    logic [63:0] x_in_17; logic [63:0] x_ts_17 [384];
    logic [63:0] y_out_17; logic [63:0] y_ts_17 [384];
    logic [63:0] x_in_18; logic [63:0] x_ts_18 [384];
    logic [63:0] y_out_18; logic [63:0] y_ts_18 [384];
    logic [63:0] x_in_19; logic [63:0] x_ts_19 [384];
    logic [63:0] y_out_19; logic [63:0] y_ts_19 [384];
    logic [63:0] x_in_20; logic [63:0] x_ts_20 [384];
    logic [63:0] y_out_20; logic [63:0] y_ts_20 [384];
    logic [63:0] x_in_21; logic [63:0] x_ts_21 [384];
    logic [63:0] y_out_21; logic [63:0] y_ts_21 [384];
    logic [63:0] x_in_22; logic [63:0] x_ts_22 [384];
    logic [63:0] y_out_22; logic [63:0] y_ts_22 [384];
    logic [63:0] x_in_23; logic [63:0] x_ts_23 [384];
    logic [63:0] y_out_23; logic [63:0] y_ts_23 [384];
    logic [63:0] x_in_24; logic [63:0] x_ts_24 [384];
    logic [63:0] y_out_24; logic [63:0] y_ts_24 [384];
    logic [63:0] x_in_25; logic [63:0] x_ts_25 [384];
    logic [63:0] y_out_25; logic [63:0] y_ts_25 [384];
    logic [63:0] x_in_26; logic [63:0] x_ts_26 [384];
    logic [63:0] y_out_26; logic [63:0] y_ts_26 [384];
    logic [63:0] x_in_27; logic [63:0] x_ts_27 [384];
    logic [63:0] y_out_27; logic [63:0] y_ts_27 [384];
    logic [63:0] x_in_28; logic [63:0] x_ts_28 [384];
    logic [63:0] y_out_28; logic [63:0] y_ts_28 [384];
    logic [63:0] x_in_29; logic [63:0] x_ts_29 [384];
    logic [63:0] y_out_29; logic [63:0] y_ts_29 [384];
    logic [63:0] x_in_30; logic [63:0] x_ts_30 [384];
    logic [63:0] y_out_30; logic [63:0] y_ts_30 [384];
    logic [63:0] x_in_31; logic [63:0] x_ts_31 [384];
    logic [63:0] y_out_31; logic [63:0] y_ts_31 [384];
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
        $readmemh("../../../../../testvectors/tw_load.txt", tw_ts);
        $readmemh("../../../../../testvectors/midx.txt", mi_ts);
        $readmemh("../../../../../testvectors/dir.txt", di_ts);
    end
    LDd_rom1 DUT (.clk(clk), .rst(rst), .DIR(DIR), .MIDX(MIDX), .mq_QH(mq_QH), .mq_QHALF(mq_QHALF), .tw_rst(tw_rst), .tw_wen(tw_wen), .tw_wdata(tw_wdata), .tw_slot(tw_slot), .x_in_0(x_in_0), .x_in_1(x_in_1), .x_in_2(x_in_2), .x_in_3(x_in_3), .x_in_4(x_in_4), .x_in_5(x_in_5), .x_in_6(x_in_6), .x_in_7(x_in_7), .x_in_8(x_in_8), .x_in_9(x_in_9), .x_in_10(x_in_10), .x_in_11(x_in_11), .x_in_12(x_in_12), .x_in_13(x_in_13), .x_in_14(x_in_14), .x_in_15(x_in_15), .x_in_16(x_in_16), .x_in_17(x_in_17), .x_in_18(x_in_18), .x_in_19(x_in_19), .x_in_20(x_in_20), .x_in_21(x_in_21), .x_in_22(x_in_22), .x_in_23(x_in_23), .x_in_24(x_in_24), .x_in_25(x_in_25), .x_in_26(x_in_26), .x_in_27(x_in_27), .x_in_28(x_in_28), .x_in_29(x_in_29), .x_in_30(x_in_30), .x_in_31(x_in_31), .y_out_0(y_out_0), .y_out_1(y_out_1), .y_out_2(y_out_2), .y_out_3(y_out_3), .y_out_4(y_out_4), .y_out_5(y_out_5), .y_out_6(y_out_6), .y_out_7(y_out_7), .y_out_8(y_out_8), .y_out_9(y_out_9), .y_out_10(y_out_10), .y_out_11(y_out_11), .y_out_12(y_out_12), .y_out_13(y_out_13), .y_out_14(y_out_14), .y_out_15(y_out_15), .y_out_16(y_out_16), .y_out_17(y_out_17), .y_out_18(y_out_18), .y_out_19(y_out_19), .y_out_20(y_out_20), .y_out_21(y_out_21), .y_out_22(y_out_22), .y_out_23(y_out_23), .y_out_24(y_out_24), .y_out_25(y_out_25), .y_out_26(y_out_26), .y_out_27(y_out_27), .y_out_28(y_out_28), .y_out_29(y_out_29), .y_out_30(y_out_30), .y_out_31(y_out_31));
    int c, bad, checked;
    initial begin
        bad = 0; checked = 0; rst = 1'b1;
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
        MIDX = mi_ts[0];
        DIR = di_ts[0];
        mq_QH = mq_QH_ts[0];
        mq_QHALF = mq_QHALF_ts[0];
        tw_rst = 1'b0; tw_wen = 1'b0; tw_wdata = '0; tw_slot = '0;
        repeat (2) @(posedge clk);
        #1 tw_rst = 1'b1; tw_slot = 1'd0; @(posedge clk); #1 tw_rst = 1'b0;
        for (c = 0; c < 8158; c++) begin tw_wen = 1'b1; tw_wdata = tw_ts[0 + c]; @(posedge clk); #1; end
        tw_wen = 1'b0;
        repeat (30) @(posedge clk);
        for (c = 0; c < 748; c++) begin
            #1;
            rst = 1'b0;
            tw_rst = 1'b0; tw_wen = 1'b0;
            if (c < 384) begin
                x_in_0 = x_ts_0[c];
                x_in_1 = x_ts_1[c];
                x_in_2 = x_ts_2[c];
                x_in_3 = x_ts_3[c];
                x_in_4 = x_ts_4[c];
                x_in_5 = x_ts_5[c];
                x_in_6 = x_ts_6[c];
                x_in_7 = x_ts_7[c];
                x_in_8 = x_ts_8[c];
                x_in_9 = x_ts_9[c];
                x_in_10 = x_ts_10[c];
                x_in_11 = x_ts_11[c];
                x_in_12 = x_ts_12[c];
                x_in_13 = x_ts_13[c];
                x_in_14 = x_ts_14[c];
                x_in_15 = x_ts_15[c];
                x_in_16 = x_ts_16[c];
                x_in_17 = x_ts_17[c];
                x_in_18 = x_ts_18[c];
                x_in_19 = x_ts_19[c];
                x_in_20 = x_ts_20[c];
                x_in_21 = x_ts_21[c];
                x_in_22 = x_ts_22[c];
                x_in_23 = x_ts_23[c];
                x_in_24 = x_ts_24[c];
                x_in_25 = x_ts_25[c];
                x_in_26 = x_ts_26[c];
                x_in_27 = x_ts_27[c];
                x_in_28 = x_ts_28[c];
                x_in_29 = x_ts_29[c];
                x_in_30 = x_ts_30[c];
                x_in_31 = x_ts_31[c];
                MIDX = mi_ts[c / 128];
                mq_QH = mq_QH_ts[c / 128];
                mq_QHALF = mq_QHALF_ts[c / 128];
                DIR = di_ts[c / 128];
            end
            if (c >= 364) begin
                #2;
                if (y_out_0 !== y_ts_0[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 0: got %h want %h", c - 364, y_out_0, y_ts_0[c - 364]); end
                if (y_out_1 !== y_ts_1[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 1: got %h want %h", c - 364, y_out_1, y_ts_1[c - 364]); end
                if (y_out_2 !== y_ts_2[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 2: got %h want %h", c - 364, y_out_2, y_ts_2[c - 364]); end
                if (y_out_3 !== y_ts_3[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 3: got %h want %h", c - 364, y_out_3, y_ts_3[c - 364]); end
                if (y_out_4 !== y_ts_4[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 4: got %h want %h", c - 364, y_out_4, y_ts_4[c - 364]); end
                if (y_out_5 !== y_ts_5[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 5: got %h want %h", c - 364, y_out_5, y_ts_5[c - 364]); end
                if (y_out_6 !== y_ts_6[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 6: got %h want %h", c - 364, y_out_6, y_ts_6[c - 364]); end
                if (y_out_7 !== y_ts_7[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 7: got %h want %h", c - 364, y_out_7, y_ts_7[c - 364]); end
                if (y_out_8 !== y_ts_8[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 8: got %h want %h", c - 364, y_out_8, y_ts_8[c - 364]); end
                if (y_out_9 !== y_ts_9[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 9: got %h want %h", c - 364, y_out_9, y_ts_9[c - 364]); end
                if (y_out_10 !== y_ts_10[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 10: got %h want %h", c - 364, y_out_10, y_ts_10[c - 364]); end
                if (y_out_11 !== y_ts_11[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 11: got %h want %h", c - 364, y_out_11, y_ts_11[c - 364]); end
                if (y_out_12 !== y_ts_12[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 12: got %h want %h", c - 364, y_out_12, y_ts_12[c - 364]); end
                if (y_out_13 !== y_ts_13[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 13: got %h want %h", c - 364, y_out_13, y_ts_13[c - 364]); end
                if (y_out_14 !== y_ts_14[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 14: got %h want %h", c - 364, y_out_14, y_ts_14[c - 364]); end
                if (y_out_15 !== y_ts_15[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 15: got %h want %h", c - 364, y_out_15, y_ts_15[c - 364]); end
                if (y_out_16 !== y_ts_16[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 16: got %h want %h", c - 364, y_out_16, y_ts_16[c - 364]); end
                if (y_out_17 !== y_ts_17[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 17: got %h want %h", c - 364, y_out_17, y_ts_17[c - 364]); end
                if (y_out_18 !== y_ts_18[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 18: got %h want %h", c - 364, y_out_18, y_ts_18[c - 364]); end
                if (y_out_19 !== y_ts_19[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 19: got %h want %h", c - 364, y_out_19, y_ts_19[c - 364]); end
                if (y_out_20 !== y_ts_20[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 20: got %h want %h", c - 364, y_out_20, y_ts_20[c - 364]); end
                if (y_out_21 !== y_ts_21[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 21: got %h want %h", c - 364, y_out_21, y_ts_21[c - 364]); end
                if (y_out_22 !== y_ts_22[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 22: got %h want %h", c - 364, y_out_22, y_ts_22[c - 364]); end
                if (y_out_23 !== y_ts_23[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 23: got %h want %h", c - 364, y_out_23, y_ts_23[c - 364]); end
                if (y_out_24 !== y_ts_24[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 24: got %h want %h", c - 364, y_out_24, y_ts_24[c - 364]); end
                if (y_out_25 !== y_ts_25[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 25: got %h want %h", c - 364, y_out_25, y_ts_25[c - 364]); end
                if (y_out_26 !== y_ts_26[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 26: got %h want %h", c - 364, y_out_26, y_ts_26[c - 364]); end
                if (y_out_27 !== y_ts_27[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 27: got %h want %h", c - 364, y_out_27, y_ts_27[c - 364]); end
                if (y_out_28 !== y_ts_28[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 28: got %h want %h", c - 364, y_out_28, y_ts_28[c - 364]); end
                if (y_out_29 !== y_ts_29[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 29: got %h want %h", c - 364, y_out_29, y_ts_29[c - 364]); end
                if (y_out_30 !== y_ts_30[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 30: got %h want %h", c - 364, y_out_30, y_ts_30[c - 364]); end
                if (y_out_31 !== y_ts_31[c - 364]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 31: got %h want %h", c - 364, y_out_31, y_ts_31[c - 364]); end
                checked++;
            end
            @(posedge clk);
        end
        if (bad == 0) begin $display("SUCCESS!"); $display("PASS All %0d Testvectors!", checked); end
        else begin $display("TO BE DEBUGGED..."); $display("FAILED: %0d lane values wrong", bad); end
        $finish();
    end
endmodule
