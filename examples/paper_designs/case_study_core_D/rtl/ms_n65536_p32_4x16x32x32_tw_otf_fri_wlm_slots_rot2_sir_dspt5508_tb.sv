`timescale 1ns / 1ps
module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508_tb;
    logic clk = 0; always #1 clk = ~clk;
    logic rst = 1;
    logic in_valid = 0; logic out_valid;
    logic DIR = 0; logic dir_out;
    logic [2:0] qid = '0; logic [2:0] qi [0:12344];
    initial $readmemh("../testvectors/qid_in.txt", qi);
    logic [44:0] mq_QH_tab [0:4]; logic [44:0] mq_QH;
    initial begin mq_QH_tab[0] = 45'h1ffffffff3c7; mq_QH_tab[1] = 45'h1ffffffff3a7; mq_QH_tab[2] = 45'h1ffffffff39b; mq_QH_tab[3] = 45'h1ffffffff379; mq_QH_tab[4] = 45'h1ffffffff36b; end
    assign mq_QH = mq_QH_tab[qid];
    logic [61:0] mq_QHALF_tab [0:4]; logic [61:0] mq_QHALF;
    initial begin mq_QHALF_tab[0] = 62'h1ffffffff3c70001; mq_QHALF_tab[1] = 62'h1ffffffff3a70001; mq_QHALF_tab[2] = 62'h1ffffffff39b0001; mq_QHALF_tab[3] = 62'h1ffffffff3790001; mq_QHALF_tab[4] = 62'h1ffffffff36b0001; end
    assign mq_QHALF = mq_QHALF_tab[qid];
    logic ld_wen = 0; logic [123:0] ld_wdata = '0; logic [123:0] ldm [0:10931];
    logic ann_valid = 0; logic [7:0] ann_key = '0; logic [8:0] am [0:12344];
    logic ld_req; logic [7:0] ld_key; logic slot_err; logic [2:0] err_code;
    logic [61:0] x [0:31]; logic [61:0] y [0:31];
    logic [1983:0] xm [0:12344]; logic [1983:0] ym [0:16014];
    logic [4:0] ci [0:12344]; logic [4:0] co [0:16014];
    initial begin $readmemh("../testvectors/x_in.txt", xm); $readmemh("../testvectors/y_out.txt", ym); $readmemh("../testvectors/ctl_in.txt", ci); $readmemh("../testvectors/ctl_out.txt", co); $readmemh("../testvectors/ann_in.txt", am); $readmemh("../testvectors/ldimg.txt", ldm); end
    ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_slots_rot2_sir_dspt5508 dut (.clk(clk), .rst(rst), .in_valid(in_valid), .out_valid(out_valid), .DIR(DIR), .dir_out(dir_out), .mq_QH(mq_QH), .mq_QHALF(mq_QHALF), .ld_wen(ld_wen), .ld_wdata(ld_wdata), .ann_valid(ann_valid), .ann_key(ann_key), .ld_req(ld_req), .ld_key(ld_key), .slot_err(slot_err), .err_code(err_code), .x_in_0(x[0]), .x_in_1(x[1]), .x_in_2(x[2]), .x_in_3(x[3]), .x_in_4(x[4]), .x_in_5(x[5]), .x_in_6(x[6]), .x_in_7(x[7]), .x_in_8(x[8]), .x_in_9(x[9]), .x_in_10(x[10]), .x_in_11(x[11]), .x_in_12(x[12]), .x_in_13(x[13]), .x_in_14(x[14]), .x_in_15(x[15]), .x_in_16(x[16]), .x_in_17(x[17]), .x_in_18(x[18]), .x_in_19(x[19]), .x_in_20(x[20]), .x_in_21(x[21]), .x_in_22(x[22]), .x_in_23(x[23]), .x_in_24(x[24]), .x_in_25(x[25]), .x_in_26(x[26]), .x_in_27(x[27]), .x_in_28(x[28]), .x_in_29(x[29]), .x_in_30(x[30]), .x_in_31(x[31]), .y_out_0(y[0]), .y_out_1(y[1]), .y_out_2(y[2]), .y_out_3(y[3]), .y_out_4(y[4]), .y_out_5(y[5]), .y_out_6(y[6]), .y_out_7(y[7]), .y_out_8(y[8]), .y_out_9(y[9]), .y_out_10(y[10]), .y_out_11(y[11]), .y_out_12(y[12]), .y_out_13(y[13]), .y_out_14(y[14]), .y_out_15(y[15]), .y_out_16(y[16]), .y_out_17(y[17]), .y_out_18(y[18]), .y_out_19(y[19]), .y_out_20(y[20]), .y_out_21(y[21]), .y_out_22(y[22]), .y_out_23(y[23]), .y_out_24(y[24]), .y_out_25(y[25]), .y_out_26(y[26]), .y_out_27(y[27]), .y_out_28(y[28]), .y_out_29(y[29]), .y_out_30(y[30]), .y_out_31(y[31]));
    integer m = 0, l, errs = 0, outs = 0, first_in = -1, last_in = -1, first_out = -1, last_out = -1;
    integer li = 0, lbase = 0, qbase = 0, loads = 0; logic lrun = 0, lpend = 0; logic started = 0;
    initial begin
        for (l = 0; l < 32; l++) x[l] = '0;
        repeat (80) @(posedge clk);   // past the 100 ns global set/reset of the DSP58 models (2 ns clock)
        rst <= 0; @(posedge clk); started <= 1;
    end
    always @(posedge clk) if (started) begin
        #0.1;
        if (lrun && li >= 1822) lrun = 0;
        if (!lrun && lpend) begin lbase = qbase; li = 0; lrun = 1; lpend = 0; end
        if (lrun) begin ld_wen = 1; ld_wdata = ldm[lbase + li]; li = li + 1; end
        else ld_wen = 0;
        if (ld_req) begin
            if (lpend) begin $display("[tb] two load requests wait"); errs++; end
            case (ld_key)
                8'd2: qbase = 0;
                8'd3: qbase = 9110;
                8'd5: qbase = 1822;
                8'd6: qbase = 3644;
                8'd9: qbase = 5466;
                8'd10: qbase = 7288;
                default: begin $display("[tb] load of an unknown key %0d", ld_key); qbase = 0; end
            endcase
            lpend = 1; loads = loads + 1;
        end
        if (slot_err) begin errs++; if (errs < 10) $display("[tb] cycle %0d: slot error code %0d", m, err_code); end
        if (m < 16015) begin
            if (out_valid !== co[m][0]) begin errs++; if (errs < 10) $display("[tb] cycle %0d: out_valid %b, expected %b", m, out_valid, co[m][0]); end
            else if (out_valid) begin
                outs++; if (first_out < 0) first_out = m; last_out = m;
                for (l = 0; l < 32; l++) if (y[l] !== ym[m][l*62 +: 62]) begin errs++; if (errs < 10) $display("[tb] cycle %0d lane %0d: %h, expected %h", m, l, y[l], ym[m][l*62 +: 62]); end
                if (dir_out !== co[m][1]) begin errs++; if (errs < 10) $display("[tb] cycle %0d: dir_out %b", m, dir_out); end
            end
            if (m < 12345) begin
                in_valid = ci[m][0]; DIR = ci[m][1]; qid = qi[m];
                ann_valid = am[m][0]; ann_key = am[m][8:1];
                for (l = 0; l < 32; l++) x[l] = xm[m][l*62 +: 62];
                if (ci[m][0]) begin if (first_in < 0) first_in = m; last_in = m; end
            end else begin in_valid = 0; ann_valid = 0; end
            m = m + 1;
        end else begin
            $display("[tb] fed 12288 beats over cycles %0d..%0d, %0d beats out over cycles %0d..%0d (latency 3662), %0d errors, %0d loads on request", first_in, last_in, outs, first_out, last_out, errs, loads);
            if (errs == 0 && outs == 12288 && (last_out - first_out) == (last_in - first_in)) $display("[tb] PASS"); else $display("[tb] FAIL");
            $finish;
        end
    end
endmodule
