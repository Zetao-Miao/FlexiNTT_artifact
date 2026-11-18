`timescale 1ns / 1ps
module LDe_rom1_tb ();
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst;
    logic DIR; logic di_ts [3];
    logic [0:0] MIDX; logic [0:0] mi_ts [3];
    logic [61:0] mq_Q; logic [61:0] mq_Q_ts [3];
    logic [63:0] mq_MU; logic [63:0] mq_MU_ts [3];
    logic [61:0] mq_QHALF; logic [61:0] mq_QHALF_ts [3];
    initial begin
        mq_Q_ts[0] = 62'h2000000000460001; mq_MU_ts[0] = 64'hfffffffffdcffff8; mq_QHALF_ts[0] = 62'h1000000000230001;
        mq_Q_ts[1] = 62'h2000000000460001; mq_MU_ts[1] = 64'hfffffffffdcffff8; mq_QHALF_ts[1] = 62'h1000000000230001;
        mq_Q_ts[2] = 62'h2000000000460001; mq_MU_ts[2] = 64'hfffffffffdcffff8; mq_QHALF_ts[2] = 62'h1000000000230001;
    end
    logic tw_rst, tw_wen; logic [61:0] tw_wdata; logic [61:0] tw_ts [262134];
    logic [0:0] tw_slot;
    logic [61:0] x_in_0; logic [61:0] x_ts_0 [49152];
    logic [61:0] y_out_0; logic [61:0] y_ts_0 [49152];
    logic [61:0] x_in_1; logic [61:0] x_ts_1 [49152];
    logic [61:0] y_out_1; logic [61:0] y_ts_1 [49152];
    logic [61:0] x_in_2; logic [61:0] x_ts_2 [49152];
    logic [61:0] y_out_2; logic [61:0] y_ts_2 [49152];
    logic [61:0] x_in_3; logic [61:0] x_ts_3 [49152];
    logic [61:0] y_out_3; logic [61:0] y_ts_3 [49152];
    logic [61:0] x_in_4; logic [61:0] x_ts_4 [49152];
    logic [61:0] y_out_4; logic [61:0] y_ts_4 [49152];
    logic [61:0] x_in_5; logic [61:0] x_ts_5 [49152];
    logic [61:0] y_out_5; logic [61:0] y_ts_5 [49152];
    logic [61:0] x_in_6; logic [61:0] x_ts_6 [49152];
    logic [61:0] y_out_6; logic [61:0] y_ts_6 [49152];
    logic [61:0] x_in_7; logic [61:0] x_ts_7 [49152];
    logic [61:0] y_out_7; logic [61:0] y_ts_7 [49152];
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
        $readmemh("../../../../../testvectors/tw_load.txt", tw_ts);
        $readmemh("../../../../../testvectors/midx.txt", mi_ts);
        $readmemh("../../../../../testvectors/dir.txt", di_ts);
    end
    LDe_rom1 DUT (.clk(clk), .rst(rst), .DIR(DIR), .MIDX(MIDX), .mq_Q(mq_Q), .mq_MU(mq_MU), .mq_QHALF(mq_QHALF), .tw_rst(tw_rst), .tw_wen(tw_wen), .tw_wdata(tw_wdata), .tw_slot(tw_slot), .x_in_0(x_in_0), .x_in_1(x_in_1), .x_in_2(x_in_2), .x_in_3(x_in_3), .x_in_4(x_in_4), .x_in_5(x_in_5), .x_in_6(x_in_6), .x_in_7(x_in_7), .y_out_0(y_out_0), .y_out_1(y_out_1), .y_out_2(y_out_2), .y_out_3(y_out_3), .y_out_4(y_out_4), .y_out_5(y_out_5), .y_out_6(y_out_6), .y_out_7(y_out_7));
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
        MIDX = mi_ts[0];
        DIR = di_ts[0];
        mq_Q = mq_Q_ts[0];
        mq_MU = mq_MU_ts[0];
        mq_QHALF = mq_QHALF_ts[0];
        tw_rst = 1'b0; tw_wen = 1'b0; tw_wdata = '0; tw_slot = '0;
        repeat (2) @(posedge clk);
        #1 tw_rst = 1'b1; tw_slot = 1'd0; @(posedge clk); #1 tw_rst = 1'b0;
        for (c = 0; c < 262134; c++) begin tw_wen = 1'b1; tw_wdata = tw_ts[0 + c]; @(posedge clk); #1; end
        tw_wen = 1'b0;
        repeat (30) @(posedge clk);
        for (c = 0; c < 65829; c++) begin
            #1;
            rst = 1'b0;
            tw_rst = 1'b0; tw_wen = 1'b0;
            if (c < 49152) begin
                x_in_0 = x_ts_0[c];
                x_in_1 = x_ts_1[c];
                x_in_2 = x_ts_2[c];
                x_in_3 = x_ts_3[c];
                x_in_4 = x_ts_4[c];
                x_in_5 = x_ts_5[c];
                x_in_6 = x_ts_6[c];
                x_in_7 = x_ts_7[c];
                MIDX = mi_ts[c / 16384];
                mq_Q = mq_Q_ts[c / 16384];
                mq_MU = mq_MU_ts[c / 16384];
                mq_QHALF = mq_QHALF_ts[c / 16384];
                DIR = di_ts[c / 16384];
            end
            if (c >= 16677) begin
                #2;
                if (y_out_0 !== y_ts_0[c - 16677]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 0: got %h want %h", c - 16677, y_out_0, y_ts_0[c - 16677]); end
                if (y_out_1 !== y_ts_1[c - 16677]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 1: got %h want %h", c - 16677, y_out_1, y_ts_1[c - 16677]); end
                if (y_out_2 !== y_ts_2[c - 16677]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 2: got %h want %h", c - 16677, y_out_2, y_ts_2[c - 16677]); end
                if (y_out_3 !== y_ts_3[c - 16677]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 3: got %h want %h", c - 16677, y_out_3, y_ts_3[c - 16677]); end
                if (y_out_4 !== y_ts_4[c - 16677]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 4: got %h want %h", c - 16677, y_out_4, y_ts_4[c - 16677]); end
                if (y_out_5 !== y_ts_5[c - 16677]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 5: got %h want %h", c - 16677, y_out_5, y_ts_5[c - 16677]); end
                if (y_out_6 !== y_ts_6[c - 16677]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 6: got %h want %h", c - 16677, y_out_6, y_ts_6[c - 16677]); end
                if (y_out_7 !== y_ts_7[c - 16677]) begin bad++; if (bad < 10) $display("WRONG cycle %0d lane 7: got %h want %h", c - 16677, y_out_7, y_ts_7[c - 16677]); end
                checked++;
            end
            @(posedge clk);
        end
        if (bad == 0) begin $display("SUCCESS!"); $display("PASS All %0d Testvectors!", checked); end
        else begin $display("TO BE DEBUGGED..."); $display("FAILED: %0d lane values wrong", bad); end
        $finish();
    end
endmodule
