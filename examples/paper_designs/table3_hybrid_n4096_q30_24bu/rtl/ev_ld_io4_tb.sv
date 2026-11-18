`timescale 1ns / 1ps
module ev_ld_io4_tb ();
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst, in_valid, in_ready, out_valid;
    logic [1:0] MIDX, midx_out;
    logic DIR, dir_out;
    logic [29:0] x_in_0; logic [29:0] x_ts_0 [5120];
    logic [29:0] y_out_0; logic [29:0] y_ts_0 [5120];
    logic [29:0] x_in_1; logic [29:0] x_ts_1 [5120];
    logic [29:0] y_out_1; logic [29:0] y_ts_1 [5120];
    logic [29:0] x_in_2; logic [29:0] x_ts_2 [5120];
    logic [29:0] y_out_2; logic [29:0] y_ts_2 [5120];
    logic [29:0] x_in_3; logic [29:0] x_ts_3 [5120];
    logic [29:0] y_out_3; logic [29:0] y_ts_3 [5120];
    logic [31:0] ycyc [5120]; logic vpat [7254]; logic [15:0] tg_ts [5120]; logic [15:0] ytg_ts [5120];
    initial begin
        $readmemh("../../../../../testvectors/x_0.txt", x_ts_0);
        $readmemh("../../../../../testvectors/y_0.txt", y_ts_0);
        $readmemh("../../../../../testvectors/x_1.txt", x_ts_1);
        $readmemh("../../../../../testvectors/y_1.txt", y_ts_1);
        $readmemh("../../../../../testvectors/x_2.txt", x_ts_2);
        $readmemh("../../../../../testvectors/y_2.txt", y_ts_2);
        $readmemh("../../../../../testvectors/x_3.txt", x_ts_3);
        $readmemh("../../../../../testvectors/y_3.txt", y_ts_3);
        $readmemh("../../../../../testvectors/ycycle.txt", ycyc);
        $readmemh("../../../../../testvectors/valid.txt", vpat);
        $readmemh("../../../../../testvectors/tags.txt", tg_ts);
        $readmemh("../../../../../testvectors/ytags.txt", ytg_ts);
    end
    logic ld_we = 1'b0; logic [5:0] ld_sel = '0; logic [10:0] ld_addr = '0; logic [31:0] ld_data = '0; logic [31:0] ld_ts [196632];
    initial $readmemh("../../../../../testvectors/load.txt", ld_ts);
    ev_ld_io4 DUT (.clk(clk), .rst(rst), .in_valid(in_valid), .in_ready(in_ready), .MIDX(MIDX), .midx_out(midx_out), .DIR(DIR), .dir_out(dir_out), .ld_we(ld_we), .ld_sel(ld_sel), .ld_addr(ld_addr), .ld_data(ld_data), .x_in_0(x_in_0), .x_in_1(x_in_1), .x_in_2(x_in_2), .x_in_3(x_in_3), .out_valid(out_valid), .y_out_0(y_out_0), .y_out_1(y_out_1), .y_out_2(y_out_2), .y_out_3(y_out_3));
    int c, bad, xb, ob, late, first_in, last_out;
    initial begin
        bad = 0; xb = 0; ob = 0; late = 0; first_in = -1; last_out = -1; rst = 1'b1; in_valid = 1'b0;
        MIDX = '0;
        DIR = 1'b0;
        x_in_0 = '0;
        x_in_1 = '0;
        x_in_2 = '0;
        x_in_3 = '0;
        repeat (100) @(posedge clk);
        // the load image (every table and modulus constant of the moduli under test), before the job
        for (c = 0; c < 65544; c++) begin
            #1; ld_we = 1'b1; ld_sel = 6'(ld_ts[3 * c]); ld_addr = 11'(ld_ts[3 * c + 1]); ld_data = 32'(ld_ts[3 * c + 2]);
            @(posedge clk);
        end
        #1; ld_we = 1'b0;
        repeat (8) @(posedge clk);
        for (c = 0; c < 7254; c++) begin
            #1;
            rst = 1'b0;
            in_valid = vpat[c] && (xb < 5120);
            if (xb < 5120) begin
                MIDX = tg_ts[xb][2:1];
                DIR = tg_ts[xb][0];
                x_in_0 = x_ts_0[xb];
                x_in_1 = x_ts_1[xb];
                x_in_2 = x_ts_2[xb];
                x_in_3 = x_ts_3[xb];
            end
            #2;
            if (out_valid) begin
                if (ob >= 5120) begin bad++; if (bad < 10) $display("WRONG extra output beat at cycle %0d", c); end
                else begin
                    if (c != ycyc[ob]) begin late++; if (late < 5) $display("WRONG beat %0d at cycle %0d, the model says %0d", ob, c, ycyc[ob]); end
                    if (midx_out !== ytg_ts[ob][2:1]) begin bad++; if (bad < 10) $display("WRONG beat %0d midx_out %0d", ob, midx_out); end
                    if (dir_out !== ytg_ts[ob][0]) begin bad++; if (bad < 10) $display("WRONG beat %0d dir_out %0d", ob, dir_out); end
                    if (y_out_0 !== y_ts_0[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 0: got %h want %h", ob, y_out_0, y_ts_0[ob]); end
                    if (y_out_1 !== y_ts_1[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 1: got %h want %h", ob, y_out_1, y_ts_1[ob]); end
                    if (y_out_2 !== y_ts_2[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 2: got %h want %h", ob, y_out_2, y_ts_2[ob]); end
                    if (y_out_3 !== y_ts_3[ob]) begin bad++; if (bad < 10) $display("WRONG beat %0d lane 3: got %h want %h", ob, y_out_3, y_ts_3[ob]); end
                    ob++; last_out = c;
                end
            end
            if (in_valid && in_ready) begin if (first_in < 0) first_in = c; xb++; end
            @(posedge clk);
        end
        if (ob != 5120) begin bad++; $display("WRONG: %0d of 5120 output beats", ob); end
        if (xb != 5120) begin bad++; $display("WRONG: %0d of 5120 input beats accepted", xb); end
        $display("[tb] rate: %0d beats in, %0d out, first input cycle %0d, last output cycle %0d, %0d late beats", xb, ob, first_in, last_out, late);
        bad = bad + late;
        if (bad == 0) begin $display("SUCCESS!"); $display("PASS All %0d Testvectors!", ob); end
        else begin $display("TO BE DEBUGGED..."); $display("FAILED: %0d wrong", bad); end
        $finish();
    end
endmodule
