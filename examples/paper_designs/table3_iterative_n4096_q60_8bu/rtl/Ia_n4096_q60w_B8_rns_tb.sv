`timescale 1ns / 1ps
module Ia_n4096_q60w_B8_rns_tb ();
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst, in_valid, in_ready, out_valid;
    logic DIR = 1'b1;
    logic tw_valid, tw_ready; logic [119:0] tw_data; logic [119:0] tw_ts [6171]; logic twpat [13396];
    logic [59:0] x_in_0; logic [59:0] x_ts_0 [6144];
    logic [59:0] y_out_0; logic [59:0] y_ts_0 [6144];
    logic [59:0] x_in_1; logic [59:0] x_ts_1 [6144];
    logic [59:0] y_out_1; logic [59:0] y_ts_1 [6144];
    logic [31:0] ycyc [6144]; logic vpat [13396];
    initial begin
        $readmemh("../../../../../testvectors/x_0.txt", x_ts_0);
        $readmemh("../../../../../testvectors/y_0.txt", y_ts_0);
        $readmemh("../../../../../testvectors/x_1.txt", x_ts_1);
        $readmemh("../../../../../testvectors/y_1.txt", y_ts_1);
        $readmemh("../../../../../testvectors/ycycle.txt", ycyc);
        $readmemh("../../../../../testvectors/valid.txt", vpat);
        $readmemh("../../../../../testvectors/tw_stream.txt", tw_ts);
        $readmemh("../../../../../testvectors/twvalid.txt", twpat);
    end
    Ia_n4096_q60w_B8_rns DUT (.clk(clk), .rst(rst), .DIR(DIR), .tw_valid(tw_valid), .tw_ready(tw_ready), .tw_data(tw_data), .in_valid(in_valid), .in_ready(in_ready), .x_in_0(x_in_0), .x_in_1(x_in_1), .out_valid(out_valid), .y_out_0(y_out_0), .y_out_1(y_out_1));
    int c, bad, xb, ob, late, twb;
    initial begin
        bad = 0; xb = 0; ob = 0; late = 0; rst = 1'b1; in_valid = 1'b0;
        twb = 0; tw_valid = 1'b0; tw_data = '0;
        x_in_0 = '0;
        x_in_1 = '0;
        repeat (30) @(posedge clk);
        for (c = 0; c < 13396; c++) begin
            #1;
            rst = 1'b0;
            in_valid = vpat[c] && (xb < 6144);
            tw_valid = twpat[c] && (twb < 6171);
            tw_data = (twb < 6171) ? tw_ts[twb] : '0;
            x_in_0 = (xb < 6144) ? x_ts_0[xb] : '0;
            x_in_1 = (xb < 6144) ? x_ts_1[xb] : '0;
            #2;
            if (out_valid && ob < 6144 && (ob % 2048 == 0 || ob % 2048 == 2047)) $display("MEAS out %s poly %0d cycle %0d", (ob % 2048 == 0) ? "first" : "last", ob / 2048, c);
            if (out_valid) begin
                if (ob >= 6144) begin bad++; if (bad < 10) $display("WRONG extra output beat at cycle %0d", c); end
                else begin
                    if (c != ycyc[ob]) begin late++; if (late < 5) $display("WRONG beat %0d at cycle %0d, the model says %0d", ob, c, ycyc[ob]); end
                    if (y_out_0 !== y_ts_0[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 0: got %h want %h", ob, y_out_0, y_ts_0[ob]); end
                    if (y_out_1 !== y_ts_1[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 1: got %h want %h", ob, y_out_1, y_ts_1[ob]); end
                    ob++;
                end
            end
            if (in_valid && in_ready && (xb % 2048 == 0 || xb % 2048 == 2047)) $display("MEAS in %s poly %0d cycle %0d", (xb % 2048 == 0) ? "first" : "last", xb / 2048, c);
            if (in_valid && in_ready) xb++;
            if (tw_valid && tw_ready) twb++;
            @(posedge clk);
        end
        if (ob != 6144) begin bad++; $display("WRONG: %0d of 6144 output beats", ob); end
        if (xb != 6144) begin bad++; $display("WRONG: %0d of 6144 input beats accepted", xb); end
        if (twb != 6171) begin bad++; $display("WRONG: %0d of 6171 record beats accepted", twb); end
        bad = bad + late;
        if (bad == 0) begin $display("SUCCESS!"); $display("PASS All %0d Testvectors!", ob); end
        else begin $display("TO BE DEBUGGED..."); $display("FAILED: %0d wrong", bad); end
        $finish();
    end
endmodule
