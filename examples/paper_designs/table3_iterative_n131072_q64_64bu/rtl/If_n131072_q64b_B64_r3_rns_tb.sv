`timescale 1ns / 1ps
module If_n131072_q64b_B64_r3_rns_tb ();
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst, in_valid, in_ready, out_valid;
    logic DIR = 1'b1;
    logic tw_valid, tw_ready; logic [511:0] tw_data; logic [511:0] tw_ts [49275]; logic twpat [85077];
    logic [63:0] x_in_0; logic [63:0] x_ts_0 [49152];
    logic [63:0] y_out_0; logic [63:0] y_ts_0 [49152];
    logic [63:0] x_in_1; logic [63:0] x_ts_1 [49152];
    logic [63:0] y_out_1; logic [63:0] y_ts_1 [49152];
    logic [63:0] x_in_2; logic [63:0] x_ts_2 [49152];
    logic [63:0] y_out_2; logic [63:0] y_ts_2 [49152];
    logic [63:0] x_in_3; logic [63:0] x_ts_3 [49152];
    logic [63:0] y_out_3; logic [63:0] y_ts_3 [49152];
    logic [63:0] x_in_4; logic [63:0] x_ts_4 [49152];
    logic [63:0] y_out_4; logic [63:0] y_ts_4 [49152];
    logic [63:0] x_in_5; logic [63:0] x_ts_5 [49152];
    logic [63:0] y_out_5; logic [63:0] y_ts_5 [49152];
    logic [63:0] x_in_6; logic [63:0] x_ts_6 [49152];
    logic [63:0] y_out_6; logic [63:0] y_ts_6 [49152];
    logic [63:0] x_in_7; logic [63:0] x_ts_7 [49152];
    logic [63:0] y_out_7; logic [63:0] y_ts_7 [49152];
    logic [31:0] ycyc [49152]; logic vpat [85077];
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
        $readmemh("../../../../../testvectors/ycycle.txt", ycyc);
        $readmemh("../../../../../testvectors/valid.txt", vpat);
        $readmemh("../../../../../testvectors/tw_stream.txt", tw_ts);
        $readmemh("../../../../../testvectors/twvalid.txt", twpat);
    end
    If_n131072_q64b_B64_r3_rns DUT (.clk(clk), .rst(rst), .DIR(DIR), .tw_valid(tw_valid), .tw_ready(tw_ready), .tw_data(tw_data), .in_valid(in_valid), .in_ready(in_ready), .x_in_0(x_in_0), .x_in_1(x_in_1), .x_in_2(x_in_2), .x_in_3(x_in_3), .x_in_4(x_in_4), .x_in_5(x_in_5), .x_in_6(x_in_6), .x_in_7(x_in_7), .out_valid(out_valid), .y_out_0(y_out_0), .y_out_1(y_out_1), .y_out_2(y_out_2), .y_out_3(y_out_3), .y_out_4(y_out_4), .y_out_5(y_out_5), .y_out_6(y_out_6), .y_out_7(y_out_7));
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
        repeat (30) @(posedge clk);
        for (c = 0; c < 85077; c++) begin
            #1;
            rst = 1'b0;
            in_valid = vpat[c] && (xb < 49152);
            tw_valid = twpat[c] && (twb < 49275);
            tw_data = (twb < 49275) ? tw_ts[twb] : '0;
            x_in_0 = (xb < 49152) ? x_ts_0[xb] : '0;
            x_in_1 = (xb < 49152) ? x_ts_1[xb] : '0;
            x_in_2 = (xb < 49152) ? x_ts_2[xb] : '0;
            x_in_3 = (xb < 49152) ? x_ts_3[xb] : '0;
            x_in_4 = (xb < 49152) ? x_ts_4[xb] : '0;
            x_in_5 = (xb < 49152) ? x_ts_5[xb] : '0;
            x_in_6 = (xb < 49152) ? x_ts_6[xb] : '0;
            x_in_7 = (xb < 49152) ? x_ts_7[xb] : '0;
            #2;
            if (out_valid && ob < 49152 && (ob % 16384 == 0 || ob % 16384 == 16383)) $display("MEAS out %s poly %0d cycle %0d", (ob % 16384 == 0) ? "first" : "last", ob / 16384, c);
            if (out_valid) begin
                if (ob >= 49152) begin bad++; if (bad < 10) $display("WRONG extra output beat at cycle %0d", c); end
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
                    ob++;
                end
            end
            if (in_valid && in_ready && (xb % 16384 == 0 || xb % 16384 == 16383)) $display("MEAS in %s poly %0d cycle %0d", (xb % 16384 == 0) ? "first" : "last", xb / 16384, c);
            if (in_valid && in_ready) xb++;
            if (tw_valid && tw_ready) twb++;
            @(posedge clk);
        end
        if (ob != 49152) begin bad++; $display("WRONG: %0d of 49152 output beats", ob); end
        if (xb != 49152) begin bad++; $display("WRONG: %0d of 49152 input beats accepted", xb); end
        if (twb != 49275) begin bad++; $display("WRONG: %0d of 49275 record beats accepted", twb); end
        bad = bad + late;
        if (bad == 0) begin $display("SUCCESS!"); $display("PASS All %0d Testvectors!", ob); end
        else begin $display("TO BE DEBUGGED..."); $display("FAILED: %0d wrong", bad); end
        $finish();
    end
endmodule
