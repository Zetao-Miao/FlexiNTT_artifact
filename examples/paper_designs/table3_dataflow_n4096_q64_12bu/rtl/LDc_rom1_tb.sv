`timescale 1ns / 1ps
module LDc_rom1_tb ();
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
    logic tw_rst, tw_wen; logic [63:0] tw_wdata; logic [63:0] tw_ts [8188];
    logic [0:0] tw_slot;
    logic [63:0] x_in_0; logic [63:0] x_ts_0 [6144];
    logic [63:0] y_out_0; logic [63:0] y_ts_0 [6144];
    logic [63:0] x_in_1; logic [63:0] x_ts_1 [6144];
    logic [63:0] y_out_1; logic [63:0] y_ts_1 [6144];
    initial begin
        $readmemh("../../../../../testvectors/x_0.txt", x_ts_0);
        $readmemh("../../../../../testvectors/y_0.txt", y_ts_0);
        $readmemh("../../../../../testvectors/x_1.txt", x_ts_1);
        $readmemh("../../../../../testvectors/y_1.txt", y_ts_1);
        $readmemh("../../../../../testvectors/tw_load.txt", tw_ts);
        $readmemh("../../../../../testvectors/midx.txt", mi_ts);
        $readmemh("../../../../../testvectors/dir.txt", di_ts);
    end
    LDc_rom1 DUT (.clk(clk), .rst(rst), .DIR(DIR), .MIDX(MIDX), .mq_QH(mq_QH), .mq_QHALF(mq_QHALF), .tw_rst(tw_rst), .tw_wen(tw_wen), .tw_wdata(tw_wdata), .tw_slot(tw_slot), .x_in_0(x_in_0), .x_in_1(x_in_1), .y_out_0(y_out_0), .y_out_1(y_out_1));
    int c, bad, checked;
    initial begin
        bad = 0; checked = 0; rst = 1'b1;
        x_in_0 = '0;
        x_in_1 = '0;
        MIDX = mi_ts[0];
        DIR = di_ts[0];
        mq_QH = mq_QH_ts[0];
        mq_QHALF = mq_QHALF_ts[0];
        tw_rst = 1'b0; tw_wen = 1'b0; tw_wdata = '0; tw_slot = '0;
        repeat (2) @(posedge clk);
        #1 tw_rst = 1'b1; tw_slot = 1'd0; @(posedge clk); #1 tw_rst = 1'b0;
        for (c = 0; c < 8188; c++) begin tw_wen = 1'b1; tw_wdata = tw_ts[0 + c]; @(posedge clk); #1; end
        tw_wen = 1'b0;
        repeat (30) @(posedge clk);
        for (c = 0; c < 8417; c++) begin
            #1;
            rst = 1'b0;
            tw_rst = 1'b0; tw_wen = 1'b0;
            if (c < 6144) begin
                x_in_0 = x_ts_0[c];
                x_in_1 = x_ts_1[c];
                MIDX = mi_ts[c / 2048];
                mq_QH = mq_QH_ts[c / 2048];
                mq_QHALF = mq_QHALF_ts[c / 2048];
                DIR = di_ts[c / 2048];
            end
            if (c >= 2273) begin
                #2;
                if (y_out_0 !== y_ts_0[c - 2273]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 0: got %h want %h", c - 2273, y_out_0, y_ts_0[c - 2273]); end
                if (y_out_1 !== y_ts_1[c - 2273]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 1: got %h want %h", c - 2273, y_out_1, y_ts_1[c - 2273]); end
                checked++;
            end
            @(posedge clk);
        end
        if (bad == 0) begin $display("SUCCESS!"); $display("PASS All %0d Testvectors!", checked); end
        else begin $display("TO BE DEBUGGED..."); $display("FAILED: %0d lane values wrong", bad); end
        $finish();
    end
endmodule
