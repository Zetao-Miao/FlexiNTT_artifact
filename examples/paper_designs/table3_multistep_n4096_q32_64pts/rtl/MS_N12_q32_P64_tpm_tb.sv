`timescale 1ns / 1ps
module MS_N12_q32_P64_tpm_tb;
    logic clk = 0; always #1 clk = ~clk;
    logic rst = 1;
    logic in_valid = 0;
    logic DIR = 0; logic dir_out;
    logic out_valid;
    logic ld_rst = 0, ld_wen = 0; logic [31:0] ld_wdata = '0;
    logic [33:0] lm [0:33461]; logic [47:0] qm [0:33461];
    initial begin $readmemh("../testvectors/ld_in.txt", lm); $readmemh("../testvectors/q_in.txt", qm); end
    logic [15:0] QH = '0;
    logic [31:0] QHALF = '0;
    logic [31:0] x [0:63]; logic [31:0] y [0:63];
    logic [2047:0] xm [0:33461]; logic [2047:0] ym [0:33715];
    logic [2:0] ci [0:33461]; logic [2:0] co [0:33715];
    initial begin $readmemh("../testvectors/x_in.txt", xm); $readmemh("../testvectors/y_out.txt", ym); $readmemh("../testvectors/ctl_in.txt", ci); $readmemh("../testvectors/ctl_out.txt", co); end
    MS_N12_q32_P64_tpm dut (.clk(clk), .rst(rst), .in_valid(in_valid), .out_valid(out_valid), .DIR(DIR), .dir_out(dir_out), .ld_rst(ld_rst), .ld_wen(ld_wen), .ld_wdata(ld_wdata), .QH(QH), .QHALF(QHALF), .x_in_0(x[0]), .x_in_1(x[1]), .x_in_2(x[2]), .x_in_3(x[3]), .x_in_4(x[4]), .x_in_5(x[5]), .x_in_6(x[6]), .x_in_7(x[7]), .x_in_8(x[8]), .x_in_9(x[9]), .x_in_10(x[10]), .x_in_11(x[11]), .x_in_12(x[12]), .x_in_13(x[13]), .x_in_14(x[14]), .x_in_15(x[15]), .x_in_16(x[16]), .x_in_17(x[17]), .x_in_18(x[18]), .x_in_19(x[19]), .x_in_20(x[20]), .x_in_21(x[21]), .x_in_22(x[22]), .x_in_23(x[23]), .x_in_24(x[24]), .x_in_25(x[25]), .x_in_26(x[26]), .x_in_27(x[27]), .x_in_28(x[28]), .x_in_29(x[29]), .x_in_30(x[30]), .x_in_31(x[31]), .x_in_32(x[32]), .x_in_33(x[33]), .x_in_34(x[34]), .x_in_35(x[35]), .x_in_36(x[36]), .x_in_37(x[37]), .x_in_38(x[38]), .x_in_39(x[39]), .x_in_40(x[40]), .x_in_41(x[41]), .x_in_42(x[42]), .x_in_43(x[43]), .x_in_44(x[44]), .x_in_45(x[45]), .x_in_46(x[46]), .x_in_47(x[47]), .x_in_48(x[48]), .x_in_49(x[49]), .x_in_50(x[50]), .x_in_51(x[51]), .x_in_52(x[52]), .x_in_53(x[53]), .x_in_54(x[54]), .x_in_55(x[55]), .x_in_56(x[56]), .x_in_57(x[57]), .x_in_58(x[58]), .x_in_59(x[59]), .x_in_60(x[60]), .x_in_61(x[61]), .x_in_62(x[62]), .x_in_63(x[63]), .y_out_0(y[0]), .y_out_1(y[1]), .y_out_2(y[2]), .y_out_3(y[3]), .y_out_4(y[4]), .y_out_5(y[5]), .y_out_6(y[6]), .y_out_7(y[7]), .y_out_8(y[8]), .y_out_9(y[9]), .y_out_10(y[10]), .y_out_11(y[11]), .y_out_12(y[12]), .y_out_13(y[13]), .y_out_14(y[14]), .y_out_15(y[15]), .y_out_16(y[16]), .y_out_17(y[17]), .y_out_18(y[18]), .y_out_19(y[19]), .y_out_20(y[20]), .y_out_21(y[21]), .y_out_22(y[22]), .y_out_23(y[23]), .y_out_24(y[24]), .y_out_25(y[25]), .y_out_26(y[26]), .y_out_27(y[27]), .y_out_28(y[28]), .y_out_29(y[29]), .y_out_30(y[30]), .y_out_31(y[31]), .y_out_32(y[32]), .y_out_33(y[33]), .y_out_34(y[34]), .y_out_35(y[35]), .y_out_36(y[36]), .y_out_37(y[37]), .y_out_38(y[38]), .y_out_39(y[39]), .y_out_40(y[40]), .y_out_41(y[41]), .y_out_42(y[42]), .y_out_43(y[43]), .y_out_44(y[44]), .y_out_45(y[45]), .y_out_46(y[46]), .y_out_47(y[47]), .y_out_48(y[48]), .y_out_49(y[49]), .y_out_50(y[50]), .y_out_51(y[51]), .y_out_52(y[52]), .y_out_53(y[53]), .y_out_54(y[54]), .y_out_55(y[55]), .y_out_56(y[56]), .y_out_57(y[57]), .y_out_58(y[58]), .y_out_59(y[59]), .y_out_60(y[60]), .y_out_61(y[61]), .y_out_62(y[62]), .y_out_63(y[63]));
    integer m = 0, l, errs = 0, outs = 0, first_in = -1, last_in = -1, first_out = -1, last_out = -1;
    logic started = 0; integer fd;
    initial fd = $fopen("y_dump.txt", "w");
    initial begin
        for (l = 0; l < 64; l++) x[l] = '0;
        repeat (80) @(posedge clk);   // past the 100 ns global set/reset of the DSP58 models (2 ns clock)
        rst <= 0; @(posedge clk); started <= 1;
    end
    // one counter m: after edge m the stimulus of cycle m is driven (sampled at edge m+1) and the
    // outputs visible are those the model expects at cycle m (input cycle + latency)
    always @(posedge clk) if (started) begin
        #0.1;
        if (m < 33716) begin
            if (out_valid !== co[m][0]) begin errs++; if (errs < 10) $display("[tb] cycle %0d: out_valid %b, expected %b", m, out_valid, co[m][0]); end
            else if (out_valid) begin
                outs++; if (first_out < 0) first_out = m; last_out = m;
                $fwrite(fd, "%0d", m); for (l = 0; l < 64; l++) $fwrite(fd, " %h", y[l]); $fwrite(fd, "\n");
                for (l = 0; l < 64; l++) if (y[l] !== ym[m][l*32 +: 32]) begin errs++; if (errs < 10) $display("[tb] cycle %0d lane %0d: %h, expected %h", m, l, y[l], ym[m][l*32 +: 32]); end
                if (dir_out !== co[m][1]) begin errs++; if (errs < 10) $display("[tb] cycle %0d: dir_out %b", m, dir_out); end
            end
            if (m < 33462) begin
                in_valid = ci[m][0]; DIR = ci[m][1];
                for (l = 0; l < 64; l++) x[l] = xm[m][l*32 +: 32];
                if (ci[m][0]) begin if (first_in < 0) first_in = m; last_in = m; end
                ld_rst = lm[m][0]; ld_wen = lm[m][1]; ld_wdata = lm[m][33:2];
                QH = qm[m][15:0];
                QHALF = qm[m][47:16];
            end else begin in_valid = 0; ld_wen = 0; ld_rst = 0; end
            m = m + 1;
        end else begin
            $display("[tb] fed 192 beats over cycles %0d..%0d, %0d beats out over cycles %0d..%0d (latency 246), %0d errors", first_in, last_in, outs, first_out, last_out, errs);
            if (errs == 0 && outs == 192 && (last_out - first_out) == (last_in - first_in)) $display("[tb] PASS"); else $display("[tb] FAIL");
            $finish;
        end
    end
endmodule
