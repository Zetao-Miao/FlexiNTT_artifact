`timescale 1ns / 1ps
// Id_n65536_q52w_B32_rns: iterative NTT, n=65536, 32 butterflies over 2 x 64 banks of 1024 x 52 bits, 4 I/O lanes, run-time q, direction both, butterfly latency 17, write-back latency 23, stage gaps [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
module Id_n65536_q52w_B32_rns (
    input  logic clk,
    input  logic rst,
    input  logic DIR,
    input  logic tw_valid,
    output logic tw_ready,
    input  logic [415:0] tw_data,
    input  logic in_valid,
    output logic in_ready,
    input  logic [51:0] x_in_0,
    input  logic [51:0] x_in_1,
    input  logic [51:0] x_in_2,
    input  logic [51:0] x_in_3,
    output logic out_valid,
    output logic [51:0] y_out_0,
    output logic [51:0] y_out_1,
    output logic [51:0] y_out_2,
    output logic [51:0] y_out_3
    );
    (* max_fanout = 32 *) logic DIR_r;
    always_ff @(posedge clk) DIR_r <= DIR;
    (* max_fanout = 16 *) logic [25:0] QH_r;
    logic [25:0] QH_n;      // the next polynomial's (record header), into QH_r at its start
    (* max_fanout = 16 *) logic [51:0] QHALF_r;
    logic [51:0] QHALF_n;      // the next polynomial's (record header), into QHALF_r at its start
    // ---- controller: fill (input), compute (butterflies), drain (output) over two bank sets
    logic fset; logic [13:0] fptr; logic [1:0] full, busy, res;
    logic cact, cset, cnext; logic [3:0] s; logic [9:0] tau; logic [0:0] gap;
    logic dact, dset, dnext; logic [13:0] dptr;
    logic [22:0] dsr, dsrs;
    logic fill_ok, acc, flast, issue, tlast, clast, startc, dlastb, startd, done, done_set;
    // ---- record stream (recycle): per polynomial a header (bit 0 keep, then the modulus constants), then its twiddles, 8 entries a beat
    localparam logic [1:0] L_HDR = 2'd0, L_DATA = 2'd1, L_WAIT = 2'd2;
    logic [1:0] lst, lst_n; logic lahead, lahead_n, nkeep, hdr_ok, perm, tacc, hlast, klast, hkeep;
    logic [3:0] ls, ls_n; logic [11:0] lk, lk_n; logic [0:0] hptr, hptr_n;
    logic [4:0] qw;
    logic [4:0] relst; logic twok;
    assign hdr_ok = (lst == L_WAIT) || ((lst == L_DATA) && lahead);
    assign fill_ok = !full[fset] && !busy[fset] && (!res[fset] || (dact && (dset == fset) && (fptr < dptr)));
    assign in_ready = fill_ok;
    assign acc = in_valid && fill_ok && !rst;
    assign flast = fptr == 14'd16383;
    assign issue = cact && (gap == '0) && twok;
    assign tlast = tau == 10'd1023;
    assign clast = issue && tlast && (s == 4'd15);
    assign startc = full[cnext] && hdr_ok && (nkeep ? (!cact || clast) : (!cact && (qw == '0)));
    assign dlastb = dact && (dptr == 14'd16383);
    assign startd = res[dnext] && (!dact || dlastb);
    assign done = dsr[22]; assign done_set = dsrs[22];
    logic [0:0] gap_of;
    always_comb begin
        case (s)
            default: gap_of = '0;
        endcase
    end
    always_ff @(posedge clk) begin
        if (rst) begin
            fset <= 1'b0; fptr <= '0; full <= '0; busy <= '0; res <= '0;
            cact <= 1'b0; cset <= 1'b0; cnext <= 1'b0; s <= '0; tau <= '0; gap <= '0;
            dact <= 1'b0; dset <= 1'b0; dnext <= 1'b0; dptr <= '0; dsr <= '0; dsrs <= '0;
        end else begin
            if (acc) begin
                fptr <= flast ? '0 : fptr + 1'b1;
                if (flast) begin full[fset] <= 1'b1; fset <= ~fset; end
            end
            dsr <= {dsr[21:0], clast}; dsrs <= {dsrs[21:0], cset};
            if (startc) begin
                full[cnext] <= 1'b0; busy[cnext] <= 1'b1;
                cact <= 1'b1; cset <= cnext; cnext <= ~cnext; s <= '0; tau <= '0; gap <= '0;
            end else if (clast) cact <= 1'b0;
            else if (issue) begin
                if (tlast) begin gap <= gap_of; s <= s + 1'b1; tau <= '0; end
                else tau <= tau + 1'b1;
            end else if (cact && gap != '0) gap <= gap - 1'b1;
            if (done) begin busy[done_set] <= 1'b0; res[done_set] <= 1'b1; end
            if (dlastb) res[dset] <= 1'b0;
            if (startd) begin dact <= 1'b1; dset <= dnext; dnext <= ~dnext; dptr <= '0; end
            else if (dlastb) dact <= 1'b0;
            else if (dact) dptr <= dptr + 1'b1;
        end
    end
    // ---- the loader (twin: IterativeNTTScheme._simulateJobRns)
    assign perm = !lahead || (relst > 5'(ls));
    assign tw_ready = (lst == L_HDR) || ((lst == L_DATA) && perm);
    assign tacc = tw_valid && tw_ready && !rst;
    assign hlast = 1'b1;
    function automatic logic [11:0] nbs_of(input logic [3:0] s_);
        case (s_)
            4'd0: nbs_of = 12'd3;
            4'd1: nbs_of = 12'd3;
            4'd2: nbs_of = 12'd3;
            4'd3: nbs_of = 12'd3;
            4'd4: nbs_of = 12'd3;
            4'd5: nbs_of = 12'd3;
            4'd6: nbs_of = 12'd7;
            4'd7: nbs_of = 12'd15;
            4'd8: nbs_of = 12'd31;
            4'd9: nbs_of = 12'd63;
            4'd10: nbs_of = 12'd127;
            4'd11: nbs_of = 12'd255;
            4'd12: nbs_of = 12'd511;
            4'd13: nbs_of = 12'd1023;
            4'd14: nbs_of = 12'd2047;
            4'd15: nbs_of = 12'd4095;
            default: nbs_of = '0;
        endcase
    endfunction
    assign klast = lk == nbs_of(ls);
    logic [415:0] hdr_w; assign hdr_w = tw_data;
    assign hkeep = hdr_w[0];
    always_comb begin
        lst_n = lst; lahead_n = lahead; ls_n = ls; lk_n = lk; hptr_n = hptr;
        case (lst)
            L_HDR: if (tacc) begin
                if (hlast) begin
                    hptr_n = '0;
                    if (hkeep) lst_n = L_WAIT;
                    else begin lst_n = L_DATA; ls_n = '0; lk_n = '0; lahead_n = 1'b1; end
                end else hptr_n = hptr + 1'b1;
            end
            L_DATA: begin
                if (startc) lahead_n = 1'b0;
                if (tacc) begin
                    if (klast) begin
                        lk_n = '0; ls_n = ls + 1'b1;
                        if (ls == 4'd15) begin ls_n = '0; lst_n = (lahead && !startc) ? L_WAIT : L_HDR; end
                    end else lk_n = lk + 1'b1;
                end
            end
            L_WAIT: if (startc) lst_n = L_HDR;
            default: lst_n = L_HDR;
        endcase
    end
    logic [3:0] s_nx; logic [9:0] tau_nx;
    assign s_nx = startc ? '0 : ((issue && tlast) ? s + 1'b1 : s);
    assign tau_nx = startc ? '0 : (issue ? (tlast ? '0 : tau + 1'b1) : tau);
    always_ff @(posedge clk) begin
        if (rst) begin
            lst <= L_HDR; lahead <= 1'b1; ls <= '0; lk <= '0; hptr <= '0; nkeep <= 1'b0; qw <= '0; relst <= 5'd16; twok <= 1'b0;
        end else begin
            lst <= lst_n; lahead <= lahead_n; ls <= ls_n; lk <= lk_n; hptr <= hptr_n;
            if (lst == L_HDR && tacc && hlast) nkeep <= hkeep;
            qw <= clast ? 5'd19 : ((qw != '0) ? qw - 1'b1 : '0);
            if (startc) relst <= '0; else if (clast) relst <= 5'd16; else if (issue && (tau == '0)) relst <= 5'(s);
            twok <= (tau_nx != '0) || !((lst_n == L_DATA) && !lahead_n) || (ls_n > s_nx);
        end
    end
    // the modulus constants: the header into *_n, into *_r (the butterflies' constants) at the start of a polynomial with a new modulus
    always_ff @(posedge clk) begin
        if (lst == L_HDR && tacc && hlast && !hkeep) QH_n <= hdr_w[26:1];
        if (lst == L_HDR && tacc && hlast && !hkeep) QHALF_n <= hdr_w[78:27];
        if (!rst && startc && !nkeep) begin QH_r <= QH_n; QHALF_r <= QHALF_n; end
    end
    // ---- stage decode (IterativeNTTScheme.rowAddrs / flip / twiddleIndex)
    function automatic logic [20:0] rows_of(input logic [3:0] s_, input logic [9:0] t_);
        logic [9:0] ha, hb; logic f;
        ha = t_; hb = t_; f = ^t_;
        case (s_)
            4'd6: begin ha = {t_[9:1], 1'b0}; hb = ha | 10'h1; f = t_[0] ^ (^ha); end
            4'd7: begin ha = {t_[9:2], 1'b0, t_[1:1]}; hb = ha | 10'h2; f = t_[0] ^ (^ha); end
            4'd8: begin ha = {t_[9:3], 1'b0, t_[2:1]}; hb = ha | 10'h4; f = t_[0] ^ (^ha); end
            4'd9: begin ha = {t_[9:4], 1'b0, t_[3:1]}; hb = ha | 10'h8; f = t_[0] ^ (^ha); end
            4'd10: begin ha = {t_[9:5], 1'b0, t_[4:1]}; hb = ha | 10'h10; f = t_[0] ^ (^ha); end
            4'd11: begin ha = {t_[9:6], 1'b0, t_[5:1]}; hb = ha | 10'h20; f = t_[0] ^ (^ha); end
            4'd12: begin ha = {t_[9:7], 1'b0, t_[6:1]}; hb = ha | 10'h40; f = t_[0] ^ (^ha); end
            4'd13: begin ha = {t_[9:8], 1'b0, t_[7:1]}; hb = ha | 10'h80; f = t_[0] ^ (^ha); end
            4'd14: begin ha = {t_[9:9], 1'b0, t_[8:1]}; hb = ha | 10'h100; f = t_[0] ^ (^ha); end
            4'd15: begin ha = {1'b0, t_[9:1]}; hb = ha | 10'h200; f = t_[0] ^ (^ha); end
            default: ;
        endcase
        rows_of = {f, hb, ha};
    endfunction
    function automatic logic [10:0] tidx_of(input logic [3:0] s_, input logic [9:0] t_);
        case (s_)
            4'd6: tidx_of = 11'd0 + 11'(t_ & 10'h1);
            4'd7: tidx_of = 11'd2 + 11'(t_ & 10'h3);
            4'd8: tidx_of = 11'd6 + 11'(t_ & 10'h7);
            4'd9: tidx_of = 11'd14 + 11'(t_ & 10'hf);
            4'd10: tidx_of = 11'd30 + 11'(t_ & 10'h1f);
            4'd11: tidx_of = 11'd62 + 11'(t_ & 10'h3f);
            4'd12: tidx_of = 11'd126 + 11'(t_ & 10'h7f);
            4'd13: tidx_of = 11'd254 + 11'(t_ & 10'hff);
            4'd14: tidx_of = 11'd510 + 11'(t_ & 10'h1ff);
            4'd15: tidx_of = 11'd1022 + 11'(t_ & 10'h3ff);
            default: tidx_of = '0;
        endcase
    endfunction
    logic [20:0] c_rows; assign c_rows = rows_of(s, tau);
    logic [9:0] c_hA, c_hB; logic c_flip;
    assign c_hA = c_rows[9:0]; assign c_hB = c_rows[19:10]; assign c_flip = c_rows[20];
    // ---- issue bundle, delayed: cb_*[k] is the read issued k+1 cycles ago (k = 0 .. 21)
    logic cb_v [22]; logic cb_set [22]; logic cb_f [22];
    logic [3:0] cb_s [22]; logic [9:0] cb_t [22]; logic [31:0] cb_sw [22];
    logic [31:0] c_sw;
    always_comb begin
        c_sw = '0;
        if (DIR_r) case (s)
            4'd1: c_sw = 32'haaaaaaaa;
            4'd2: c_sw = 32'heeeeeeee;
            4'd3: c_sw = 32'hfefefefe;
            4'd4: c_sw = 32'hfffefffe;
            4'd5: c_sw = 32'hfffffffe;
            4'd6: c_sw = {31'h7fffffff, |(tau & 10'h1)};
            4'd7: c_sw = {31'h7fffffff, |(tau & 10'h3)};
            4'd8: c_sw = {31'h7fffffff, |(tau & 10'h7)};
            4'd9: c_sw = {31'h7fffffff, |(tau & 10'hf)};
            4'd10: c_sw = {31'h7fffffff, |(tau & 10'h1f)};
            4'd11: c_sw = {31'h7fffffff, |(tau & 10'h3f)};
            4'd12: c_sw = {31'h7fffffff, |(tau & 10'h7f)};
            4'd13: c_sw = {31'h7fffffff, |(tau & 10'hff)};
            4'd14: c_sw = {31'h7fffffff, |(tau & 10'h1ff)};
            4'd15: c_sw = {31'h7fffffff, |(tau & 10'h3ff)};
            default: ;
        endcase
    end
    always_ff @(posedge clk) begin
        if (rst) for (int i = 0; i <= 21; i++) cb_v[i] <= 1'b0;
        else begin
            cb_v[0] <= issue;
            for (int i = 1; i <= 21; i++) cb_v[i] <= cb_v[i-1];
        end
        cb_set[0] <= cset; cb_f[0] <= c_flip; cb_s[0] <= s; cb_t[0] <= tau; cb_sw[0] <= c_sw;
        for (int i = 1; i <= 21; i++) begin cb_set[i] <= cb_set[i-1]; cb_f[i] <= cb_f[i-1]; cb_s[i] <= cb_s[i-1]; cb_t[i] <= cb_t[i-1]; cb_sw[i] <= cb_sw[i-1]; end
    end
    // ---- drain: beat dptr of set dset, row dptr >> lsub
    logic [9:0] drow; assign drow = 10'(dptr >> 4);
    logic [3:0] dsub; assign dsub = dptr[3:0];
    logic db_v [3]; logic db_set [3]; logic db_pi [3]; logic [3:0] db_sub [3];
    always_ff @(posedge clk) begin
        if (rst) for (int i = 0; i <= 2; i++) db_v[i] <= 1'b0;
        else begin
            db_v[0] <= dact;
            for (int i = 1; i <= 2; i++) db_v[i] <= db_v[i-1];
        end
        db_set[0] <= dset; db_pi[0] <= ^drow; db_sub[0] <= dsub;
        for (int i = 1; i <= 2; i++) begin db_set[i] <= db_set[i-1]; db_pi[i] <= db_pi[i-1]; db_sub[i] <= db_sub[i-1]; end
    end
    // ---- fill: beat fptr of set fset, row fptr >> lsub
    logic [9:0] frow; assign frow = 10'(fptr >> 4);
    logic fpi; assign fpi = ^frow;
    logic [3:0] fsub; assign fsub = fptr[3:0];
    logic [20:0] w_rows; assign w_rows = rows_of(cb_s[21], cb_t[21]);
    logic [9:0] w_hA, w_hB; assign w_hA = w_rows[9:0]; assign w_hB = w_rows[19:10];
    logic w_v, w_set, w_f; assign w_v = cb_v[21]; assign w_set = cb_set[21]; assign w_f = cb_f[21];
    logic [0:0] rc0;
    logic [3:0] rc1;
    logic [1:0] rc2;
    logic [3:0] rc3;
    logic [1:0] rc4;
    logic [3:0] rc5;
    logic [2:0] rc6;
    logic [2:0] rc7;
    logic [1:0] rc8;
    logic [3:0] rc9;
    logic [2:0] rc10;
    logic [2:0] rc11;
    logic [2:0] rc12;
    logic [2:0] rc13;
    logic [2:0] rc14;
    logic [2:0] rc15;
    logic [1:0] rc16;
    logic [3:0] rc17;
    logic [2:0] rc18;
    logic [2:0] rc19;
    logic [2:0] rc20;
    logic [2:0] rc21;
    logic [2:0] rc22;
    logic [2:0] rc23;
    logic [2:0] rc24;
    logic [2:0] rc25;
    logic [2:0] rc26;
    logic [2:0] rc27;
    logic [2:0] rc28;
    logic [2:0] rc29;
    logic [3:0] rc30;
    logic [1:0] rc31;
    logic [1:0] rc32;
    logic [3:0] rc33;
    logic [2:0] rc34;
    logic [2:0] rc35;
    logic [2:0] rc36;
    logic [2:0] rc37;
    logic [2:0] rc38;
    logic [2:0] rc39;
    logic [2:0] rc40;
    logic [2:0] rc41;
    logic [2:0] rc42;
    logic [2:0] rc43;
    logic [2:0] rc44;
    logic [2:0] rc45;
    logic [3:0] rc46;
    logic [1:0] rc47;
    logic [2:0] rc48;
    logic [2:0] rc49;
    logic [2:0] rc50;
    logic [2:0] rc51;
    logic [2:0] rc52;
    logic [2:0] rc53;
    logic [3:0] rc54;
    logic [1:0] rc55;
    logic [2:0] rc56;
    logic [2:0] rc57;
    logic [3:0] rc58;
    logic [1:0] rc59;
    logic [3:0] rc60;
    logic [1:0] rc61;
    logic [3:0] rc62;
    logic [0:0] rc63;
    logic [1:0] wc0;
    logic [2:0] wc1;
    logic [2:0] wc2;
    logic [2:0] wc3;
    logic [2:0] wc4;
    logic [3:0] wc5;
    logic [2:0] wc6;
    logic [2:0] wc7;
    logic [2:0] wc8;
    logic [3:0] wc9;
    logic [3:0] wc10;
    logic [3:0] wc11;
    logic [2:0] wc12;
    logic [3:0] wc13;
    logic [2:0] wc14;
    logic [2:0] wc15;
    logic [2:0] wc16;
    logic [2:0] wc17;
    logic [3:0] wc18;
    logic [2:0] wc19;
    logic [3:0] wc20;
    logic [3:0] wc21;
    logic [3:0] wc22;
    logic [2:0] wc23;
    logic [2:0] wc24;
    logic [2:0] wc25;
    logic [3:0] wc26;
    logic [2:0] wc27;
    logic [2:0] wc28;
    logic [2:0] wc29;
    logic [2:0] wc30;
    logic [1:0] wc31;
    logic [1:0] wc32;
    logic [2:0] wc33;
    logic [2:0] wc34;
    logic [2:0] wc35;
    logic [2:0] wc36;
    logic [3:0] wc37;
    logic [2:0] wc38;
    logic [2:0] wc39;
    logic [2:0] wc40;
    logic [3:0] wc41;
    logic [3:0] wc42;
    logic [3:0] wc43;
    logic [2:0] wc44;
    logic [3:0] wc45;
    logic [2:0] wc46;
    logic [2:0] wc47;
    logic [2:0] wc48;
    logic [2:0] wc49;
    logic [3:0] wc50;
    logic [2:0] wc51;
    logic [3:0] wc52;
    logic [3:0] wc53;
    logic [3:0] wc54;
    logic [2:0] wc55;
    logic [2:0] wc56;
    logic [2:0] wc57;
    logic [3:0] wc58;
    logic [2:0] wc59;
    logic [2:0] wc60;
    logic [2:0] wc61;
    logic [2:0] wc62;
    logic [1:0] wc63;
    logic [3:0] rk_s, wk_s; logic rk_f, wk_f;
    assign rk_s = cb_s[1]; assign rk_f = cb_f[1];
    assign wk_s = cb_s[20]; assign wk_f = cb_f[20];
    always_ff @(posedge clk) begin
        case ({rk_s, rk_f})
            {4'd0, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd1; rc2 <= 2'd1; rc3 <= 4'd1; rc4 <= 2'd1; rc5 <= 4'd1; rc6 <= 3'd2; rc7 <= 3'd1; rc8 <= 2'd1; rc9 <= 4'd1; rc10 <= 3'd2; rc11 <= 3'd1; rc12 <= 3'd2; rc13 <= 3'd1; rc14 <= 3'd3; rc15 <= 3'd1; rc16 <= 2'd1; rc17 <= 4'd1; rc18 <= 3'd2; rc19 <= 3'd1; rc20 <= 3'd2; rc21 <= 3'd1; rc22 <= 3'd3; rc23 <= 3'd1; rc24 <= 3'd2; rc25 <= 3'd1; rc26 <= 3'd3; rc27 <= 3'd1; rc28 <= 3'd3; rc29 <= 3'd1; rc30 <= 4'd4; rc31 <= 2'd1; rc32 <= 2'd2; rc33 <= 4'd5; rc34 <= 3'd4; rc35 <= 3'd4; rc36 <= 3'd4; rc37 <= 3'd4; rc38 <= 3'd6; rc39 <= 3'd3; rc40 <= 3'd4; rc41 <= 3'd4; rc42 <= 3'd6; rc43 <= 3'd3; rc44 <= 3'd6; rc45 <= 3'd3; rc46 <= 4'd8; rc47 <= 2'd2; rc48 <= 3'd4; rc49 <= 3'd4; rc50 <= 3'd6; rc51 <= 3'd3; rc52 <= 3'd6; rc53 <= 3'd3; rc54 <= 4'd8; rc55 <= 2'd2; rc56 <= 3'd6; rc57 <= 3'd3; rc58 <= 4'd8; rc59 <= 2'd2; rc60 <= 4'd8; rc61 <= 2'd2; rc62 <= 4'd10; rc63 <= 1'd1; end
            {4'd0, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd7; rc2 <= 2'd3; rc3 <= 4'd6; rc4 <= 2'd3; rc5 <= 4'd6; rc6 <= 3'd5; rc7 <= 3'd5; rc8 <= 2'd3; rc9 <= 4'd6; rc10 <= 3'd5; rc11 <= 3'd5; rc12 <= 3'd5; rc13 <= 3'd5; rc14 <= 3'd7; rc15 <= 3'd4; rc16 <= 2'd3; rc17 <= 4'd6; rc18 <= 3'd5; rc19 <= 3'd5; rc20 <= 3'd5; rc21 <= 3'd5; rc22 <= 3'd7; rc23 <= 3'd4; rc24 <= 3'd5; rc25 <= 3'd5; rc26 <= 3'd7; rc27 <= 3'd4; rc28 <= 3'd7; rc29 <= 3'd4; rc30 <= 4'd9; rc31 <= 2'd3; rc32 <= 2'd0; rc33 <= 4'd0; rc34 <= 3'd1; rc35 <= 3'd0; rc36 <= 3'd1; rc37 <= 3'd0; rc38 <= 3'd2; rc39 <= 3'd0; rc40 <= 3'd1; rc41 <= 3'd0; rc42 <= 3'd2; rc43 <= 3'd0; rc44 <= 3'd2; rc45 <= 3'd0; rc46 <= 4'd3; rc47 <= 2'd0; rc48 <= 3'd1; rc49 <= 3'd0; rc50 <= 3'd2; rc51 <= 3'd0; rc52 <= 3'd2; rc53 <= 3'd0; rc54 <= 4'd3; rc55 <= 2'd0; rc56 <= 3'd2; rc57 <= 3'd0; rc58 <= 4'd3; rc59 <= 2'd0; rc60 <= 4'd3; rc61 <= 2'd0; rc62 <= 4'd4; rc63 <= 1'd0; end
            {4'd1, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd2; rc2 <= 2'd0; rc3 <= 4'd1; rc4 <= 2'd1; rc5 <= 4'd2; rc6 <= 3'd1; rc7 <= 3'd1; rc8 <= 2'd1; rc9 <= 4'd2; rc10 <= 3'd1; rc11 <= 3'd1; rc12 <= 3'd2; rc13 <= 3'd2; rc14 <= 3'd2; rc15 <= 3'd1; rc16 <= 2'd1; rc17 <= 4'd2; rc18 <= 3'd1; rc19 <= 3'd1; rc20 <= 3'd2; rc21 <= 3'd2; rc22 <= 3'd2; rc23 <= 3'd1; rc24 <= 3'd2; rc25 <= 3'd2; rc26 <= 3'd2; rc27 <= 3'd1; rc28 <= 3'd3; rc29 <= 3'd2; rc30 <= 4'd3; rc31 <= 2'd1; rc32 <= 2'd2; rc33 <= 4'd6; rc34 <= 3'd3; rc35 <= 3'd4; rc36 <= 3'd4; rc37 <= 3'd5; rc38 <= 3'd5; rc39 <= 3'd3; rc40 <= 3'd4; rc41 <= 3'd5; rc42 <= 3'd5; rc43 <= 3'd3; rc44 <= 3'd6; rc45 <= 3'd4; rc46 <= 4'd7; rc47 <= 2'd2; rc48 <= 3'd4; rc49 <= 3'd5; rc50 <= 3'd5; rc51 <= 3'd3; rc52 <= 3'd6; rc53 <= 3'd4; rc54 <= 4'd7; rc55 <= 2'd2; rc56 <= 3'd6; rc57 <= 3'd4; rc58 <= 4'd7; rc59 <= 2'd2; rc60 <= 4'd8; rc61 <= 2'd3; rc62 <= 4'd9; rc63 <= 1'd1; end
            {4'd1, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd8; rc2 <= 2'd2; rc3 <= 4'd6; rc4 <= 2'd3; rc5 <= 4'd7; rc6 <= 3'd4; rc7 <= 3'd5; rc8 <= 2'd3; rc9 <= 4'd7; rc10 <= 3'd4; rc11 <= 3'd5; rc12 <= 3'd5; rc13 <= 3'd6; rc14 <= 3'd6; rc15 <= 3'd4; rc16 <= 2'd3; rc17 <= 4'd7; rc18 <= 3'd4; rc19 <= 3'd5; rc20 <= 3'd5; rc21 <= 3'd6; rc22 <= 3'd6; rc23 <= 3'd4; rc24 <= 3'd5; rc25 <= 3'd6; rc26 <= 3'd6; rc27 <= 3'd4; rc28 <= 3'd7; rc29 <= 3'd5; rc30 <= 4'd8; rc31 <= 2'd3; rc32 <= 2'd0; rc33 <= 4'd1; rc34 <= 3'd0; rc35 <= 3'd0; rc36 <= 3'd1; rc37 <= 3'd1; rc38 <= 3'd1; rc39 <= 3'd0; rc40 <= 3'd1; rc41 <= 3'd1; rc42 <= 3'd1; rc43 <= 3'd0; rc44 <= 3'd2; rc45 <= 3'd1; rc46 <= 4'd2; rc47 <= 2'd0; rc48 <= 3'd1; rc49 <= 3'd1; rc50 <= 3'd1; rc51 <= 3'd0; rc52 <= 3'd2; rc53 <= 3'd1; rc54 <= 4'd2; rc55 <= 2'd0; rc56 <= 3'd2; rc57 <= 3'd1; rc58 <= 4'd2; rc59 <= 2'd0; rc60 <= 4'd3; rc61 <= 2'd1; rc62 <= 4'd3; rc63 <= 1'd0; end
            {4'd2, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd3; rc2 <= 2'd0; rc3 <= 4'd2; rc4 <= 2'd0; rc5 <= 4'd2; rc6 <= 3'd0; rc7 <= 3'd1; rc8 <= 2'd1; rc9 <= 4'd3; rc10 <= 3'd1; rc11 <= 3'd2; rc12 <= 3'd1; rc13 <= 3'd2; rc14 <= 3'd1; rc15 <= 3'd1; rc16 <= 2'd1; rc17 <= 4'd3; rc18 <= 3'd1; rc19 <= 3'd2; rc20 <= 3'd1; rc21 <= 3'd2; rc22 <= 3'd1; rc23 <= 3'd1; rc24 <= 3'd2; rc25 <= 3'd3; rc26 <= 3'd2; rc27 <= 3'd2; rc28 <= 3'd2; rc29 <= 3'd2; rc30 <= 4'd2; rc31 <= 2'd1; rc32 <= 2'd2; rc33 <= 4'd7; rc34 <= 3'd3; rc35 <= 3'd5; rc36 <= 3'd3; rc37 <= 3'd5; rc38 <= 3'd4; rc39 <= 3'd3; rc40 <= 3'd4; rc41 <= 3'd6; rc42 <= 3'd5; rc43 <= 3'd4; rc44 <= 3'd5; rc45 <= 3'd4; rc46 <= 4'd6; rc47 <= 2'd2; rc48 <= 3'd4; rc49 <= 3'd6; rc50 <= 3'd5; rc51 <= 3'd4; rc52 <= 3'd5; rc53 <= 3'd4; rc54 <= 4'd6; rc55 <= 2'd2; rc56 <= 3'd6; rc57 <= 3'd5; rc58 <= 4'd7; rc59 <= 2'd3; rc60 <= 4'd7; rc61 <= 2'd3; rc62 <= 4'd8; rc63 <= 1'd1; end
            {4'd2, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd9; rc2 <= 2'd2; rc3 <= 4'd7; rc4 <= 2'd2; rc5 <= 4'd7; rc6 <= 3'd3; rc7 <= 3'd5; rc8 <= 2'd3; rc9 <= 4'd8; rc10 <= 3'd4; rc11 <= 3'd6; rc12 <= 3'd4; rc13 <= 3'd6; rc14 <= 3'd5; rc15 <= 3'd4; rc16 <= 2'd3; rc17 <= 4'd8; rc18 <= 3'd4; rc19 <= 3'd6; rc20 <= 3'd4; rc21 <= 3'd6; rc22 <= 3'd5; rc23 <= 3'd4; rc24 <= 3'd5; rc25 <= 3'd7; rc26 <= 3'd6; rc27 <= 3'd5; rc28 <= 3'd6; rc29 <= 3'd5; rc30 <= 4'd7; rc31 <= 2'd3; rc32 <= 2'd0; rc33 <= 4'd2; rc34 <= 3'd0; rc35 <= 3'd1; rc36 <= 3'd0; rc37 <= 3'd1; rc38 <= 3'd0; rc39 <= 3'd0; rc40 <= 3'd1; rc41 <= 3'd2; rc42 <= 3'd1; rc43 <= 3'd1; rc44 <= 3'd1; rc45 <= 3'd1; rc46 <= 4'd1; rc47 <= 2'd0; rc48 <= 3'd1; rc49 <= 3'd2; rc50 <= 3'd1; rc51 <= 3'd1; rc52 <= 3'd1; rc53 <= 3'd1; rc54 <= 4'd1; rc55 <= 2'd0; rc56 <= 3'd2; rc57 <= 3'd2; rc58 <= 4'd2; rc59 <= 2'd1; rc60 <= 4'd2; rc61 <= 2'd1; rc62 <= 4'd2; rc63 <= 1'd0; end
            {4'd3, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd4; rc2 <= 2'd0; rc3 <= 4'd3; rc4 <= 2'd0; rc5 <= 4'd3; rc6 <= 3'd0; rc7 <= 3'd2; rc8 <= 2'd0; rc9 <= 4'd3; rc10 <= 3'd0; rc11 <= 3'd2; rc12 <= 3'd0; rc13 <= 3'd2; rc14 <= 3'd0; rc15 <= 3'd1; rc16 <= 2'd1; rc17 <= 4'd4; rc18 <= 3'd1; rc19 <= 3'd3; rc20 <= 3'd1; rc21 <= 3'd3; rc22 <= 3'd1; rc23 <= 3'd2; rc24 <= 3'd1; rc25 <= 3'd3; rc26 <= 3'd1; rc27 <= 3'd2; rc28 <= 3'd1; rc29 <= 3'd2; rc30 <= 4'd1; rc31 <= 2'd1; rc32 <= 2'd2; rc33 <= 4'd8; rc34 <= 3'd3; rc35 <= 3'd6; rc36 <= 3'd3; rc37 <= 3'd6; rc38 <= 3'd4; rc39 <= 3'd4; rc40 <= 3'd3; rc41 <= 3'd6; rc42 <= 3'd4; rc43 <= 3'd4; rc44 <= 3'd4; rc45 <= 3'd4; rc46 <= 4'd5; rc47 <= 2'd2; rc48 <= 3'd4; rc49 <= 3'd7; rc50 <= 3'd5; rc51 <= 3'd5; rc52 <= 3'd5; rc53 <= 3'd5; rc54 <= 4'd6; rc55 <= 2'd3; rc56 <= 3'd5; rc57 <= 3'd5; rc58 <= 4'd6; rc59 <= 2'd3; rc60 <= 4'd6; rc61 <= 2'd3; rc62 <= 4'd7; rc63 <= 1'd1; end
            {4'd3, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd10; rc2 <= 2'd2; rc3 <= 4'd8; rc4 <= 2'd2; rc5 <= 4'd8; rc6 <= 3'd3; rc7 <= 3'd6; rc8 <= 2'd2; rc9 <= 4'd8; rc10 <= 3'd3; rc11 <= 3'd6; rc12 <= 3'd3; rc13 <= 3'd6; rc14 <= 3'd4; rc15 <= 3'd4; rc16 <= 2'd3; rc17 <= 4'd9; rc18 <= 3'd4; rc19 <= 3'd7; rc20 <= 3'd4; rc21 <= 3'd7; rc22 <= 3'd5; rc23 <= 3'd5; rc24 <= 3'd4; rc25 <= 3'd7; rc26 <= 3'd5; rc27 <= 3'd5; rc28 <= 3'd5; rc29 <= 3'd5; rc30 <= 4'd6; rc31 <= 2'd3; rc32 <= 2'd0; rc33 <= 4'd3; rc34 <= 3'd0; rc35 <= 3'd2; rc36 <= 3'd0; rc37 <= 3'd2; rc38 <= 3'd0; rc39 <= 3'd1; rc40 <= 3'd0; rc41 <= 3'd2; rc42 <= 3'd0; rc43 <= 3'd1; rc44 <= 3'd0; rc45 <= 3'd1; rc46 <= 4'd0; rc47 <= 2'd0; rc48 <= 3'd1; rc49 <= 3'd3; rc50 <= 3'd1; rc51 <= 3'd2; rc52 <= 3'd1; rc53 <= 3'd2; rc54 <= 4'd1; rc55 <= 2'd1; rc56 <= 3'd1; rc57 <= 3'd2; rc58 <= 4'd1; rc59 <= 2'd1; rc60 <= 4'd1; rc61 <= 2'd1; rc62 <= 4'd1; rc63 <= 1'd0; end
            {4'd4, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd5; rc2 <= 2'd0; rc3 <= 4'd4; rc4 <= 2'd0; rc5 <= 4'd4; rc6 <= 3'd0; rc7 <= 3'd3; rc8 <= 2'd0; rc9 <= 4'd4; rc10 <= 3'd0; rc11 <= 3'd3; rc12 <= 3'd0; rc13 <= 3'd3; rc14 <= 3'd0; rc15 <= 3'd2; rc16 <= 2'd0; rc17 <= 4'd4; rc18 <= 3'd0; rc19 <= 3'd3; rc20 <= 3'd0; rc21 <= 3'd3; rc22 <= 3'd0; rc23 <= 3'd2; rc24 <= 3'd0; rc25 <= 3'd3; rc26 <= 3'd0; rc27 <= 3'd2; rc28 <= 3'd0; rc29 <= 3'd2; rc30 <= 4'd0; rc31 <= 2'd1; rc32 <= 2'd2; rc33 <= 4'd9; rc34 <= 3'd3; rc35 <= 3'd7; rc36 <= 3'd3; rc37 <= 3'd7; rc38 <= 3'd4; rc39 <= 3'd5; rc40 <= 3'd3; rc41 <= 3'd7; rc42 <= 3'd4; rc43 <= 3'd5; rc44 <= 3'd4; rc45 <= 3'd5; rc46 <= 4'd5; rc47 <= 2'd3; rc48 <= 3'd3; rc49 <= 3'd7; rc50 <= 3'd4; rc51 <= 3'd5; rc52 <= 3'd4; rc53 <= 3'd5; rc54 <= 4'd5; rc55 <= 2'd3; rc56 <= 3'd4; rc57 <= 3'd5; rc58 <= 4'd5; rc59 <= 2'd3; rc60 <= 4'd5; rc61 <= 2'd3; rc62 <= 4'd6; rc63 <= 1'd1; end
            {4'd4, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd11; rc2 <= 2'd2; rc3 <= 4'd9; rc4 <= 2'd2; rc5 <= 4'd9; rc6 <= 3'd3; rc7 <= 3'd7; rc8 <= 2'd2; rc9 <= 4'd9; rc10 <= 3'd3; rc11 <= 3'd7; rc12 <= 3'd3; rc13 <= 3'd7; rc14 <= 3'd4; rc15 <= 3'd5; rc16 <= 2'd2; rc17 <= 4'd9; rc18 <= 3'd3; rc19 <= 3'd7; rc20 <= 3'd3; rc21 <= 3'd7; rc22 <= 3'd4; rc23 <= 3'd5; rc24 <= 3'd3; rc25 <= 3'd7; rc26 <= 3'd4; rc27 <= 3'd5; rc28 <= 3'd4; rc29 <= 3'd5; rc30 <= 4'd5; rc31 <= 2'd3; rc32 <= 2'd0; rc33 <= 4'd4; rc34 <= 3'd0; rc35 <= 3'd3; rc36 <= 3'd0; rc37 <= 3'd3; rc38 <= 3'd0; rc39 <= 3'd2; rc40 <= 3'd0; rc41 <= 3'd3; rc42 <= 3'd0; rc43 <= 3'd2; rc44 <= 3'd0; rc45 <= 3'd2; rc46 <= 4'd0; rc47 <= 2'd1; rc48 <= 3'd0; rc49 <= 3'd3; rc50 <= 3'd0; rc51 <= 3'd2; rc52 <= 3'd0; rc53 <= 3'd2; rc54 <= 4'd0; rc55 <= 2'd1; rc56 <= 3'd0; rc57 <= 3'd2; rc58 <= 4'd0; rc59 <= 2'd1; rc60 <= 4'd0; rc61 <= 2'd1; rc62 <= 4'd0; rc63 <= 1'd0; end
            {4'd5, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd6; rc2 <= 2'd0; rc3 <= 4'd5; rc4 <= 2'd0; rc5 <= 4'd5; rc6 <= 3'd0; rc7 <= 3'd4; rc8 <= 2'd0; rc9 <= 4'd5; rc10 <= 3'd0; rc11 <= 3'd4; rc12 <= 3'd0; rc13 <= 3'd4; rc14 <= 3'd0; rc15 <= 3'd3; rc16 <= 2'd0; rc17 <= 4'd5; rc18 <= 3'd0; rc19 <= 3'd4; rc20 <= 3'd0; rc21 <= 3'd4; rc22 <= 3'd0; rc23 <= 3'd3; rc24 <= 3'd0; rc25 <= 3'd4; rc26 <= 3'd0; rc27 <= 3'd3; rc28 <= 3'd0; rc29 <= 3'd3; rc30 <= 4'd0; rc31 <= 2'd2; rc32 <= 2'd1; rc33 <= 4'd9; rc34 <= 3'd2; rc35 <= 3'd7; rc36 <= 3'd2; rc37 <= 3'd7; rc38 <= 3'd3; rc39 <= 3'd5; rc40 <= 3'd2; rc41 <= 3'd7; rc42 <= 3'd3; rc43 <= 3'd5; rc44 <= 3'd3; rc45 <= 3'd5; rc46 <= 4'd4; rc47 <= 2'd3; rc48 <= 3'd2; rc49 <= 3'd7; rc50 <= 3'd3; rc51 <= 3'd5; rc52 <= 3'd3; rc53 <= 3'd5; rc54 <= 4'd4; rc55 <= 2'd3; rc56 <= 3'd3; rc57 <= 3'd5; rc58 <= 4'd4; rc59 <= 2'd3; rc60 <= 4'd4; rc61 <= 2'd3; rc62 <= 4'd5; rc63 <= 1'd1; end
            {4'd5, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 3'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 3'd0; rc12 <= 3'd3; rc13 <= 3'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 3'd0; rc20 <= 3'd3; rc21 <= 3'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 3'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 2'd0; rc32 <= 2'd3; rc33 <= 4'd4; rc34 <= 3'd5; rc35 <= 3'd3; rc36 <= 3'd5; rc37 <= 3'd3; rc38 <= 3'd7; rc39 <= 3'd2; rc40 <= 3'd5; rc41 <= 3'd3; rc42 <= 3'd7; rc43 <= 3'd2; rc44 <= 3'd7; rc45 <= 3'd2; rc46 <= 4'd9; rc47 <= 2'd1; rc48 <= 3'd5; rc49 <= 3'd3; rc50 <= 3'd7; rc51 <= 3'd2; rc52 <= 3'd7; rc53 <= 3'd2; rc54 <= 4'd9; rc55 <= 2'd1; rc56 <= 3'd7; rc57 <= 3'd2; rc58 <= 4'd9; rc59 <= 2'd1; rc60 <= 4'd9; rc61 <= 2'd1; rc62 <= 4'd11; rc63 <= 1'd0; end
            {4'd6, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd6; rc2 <= 2'd0; rc3 <= 4'd5; rc4 <= 2'd0; rc5 <= 4'd5; rc6 <= 3'd0; rc7 <= 3'd4; rc8 <= 2'd0; rc9 <= 4'd5; rc10 <= 3'd0; rc11 <= 3'd4; rc12 <= 3'd0; rc13 <= 3'd4; rc14 <= 3'd0; rc15 <= 3'd3; rc16 <= 2'd0; rc17 <= 4'd5; rc18 <= 3'd0; rc19 <= 3'd4; rc20 <= 3'd0; rc21 <= 3'd4; rc22 <= 3'd0; rc23 <= 3'd3; rc24 <= 3'd0; rc25 <= 3'd4; rc26 <= 3'd0; rc27 <= 3'd3; rc28 <= 3'd0; rc29 <= 3'd3; rc30 <= 4'd0; rc31 <= 2'd2; rc32 <= 2'd1; rc33 <= 4'd9; rc34 <= 3'd2; rc35 <= 3'd7; rc36 <= 3'd2; rc37 <= 3'd7; rc38 <= 3'd3; rc39 <= 3'd5; rc40 <= 3'd2; rc41 <= 3'd7; rc42 <= 3'd3; rc43 <= 3'd5; rc44 <= 3'd3; rc45 <= 3'd5; rc46 <= 4'd4; rc47 <= 2'd3; rc48 <= 3'd2; rc49 <= 3'd7; rc50 <= 3'd3; rc51 <= 3'd5; rc52 <= 3'd3; rc53 <= 3'd5; rc54 <= 4'd4; rc55 <= 2'd3; rc56 <= 3'd3; rc57 <= 3'd5; rc58 <= 4'd4; rc59 <= 2'd3; rc60 <= 4'd4; rc61 <= 2'd3; rc62 <= 4'd5; rc63 <= 1'd1; end
            {4'd6, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 3'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 3'd0; rc12 <= 3'd3; rc13 <= 3'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 3'd0; rc20 <= 3'd3; rc21 <= 3'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 3'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 2'd0; rc32 <= 2'd3; rc33 <= 4'd4; rc34 <= 3'd5; rc35 <= 3'd3; rc36 <= 3'd5; rc37 <= 3'd3; rc38 <= 3'd7; rc39 <= 3'd2; rc40 <= 3'd5; rc41 <= 3'd3; rc42 <= 3'd7; rc43 <= 3'd2; rc44 <= 3'd7; rc45 <= 3'd2; rc46 <= 4'd9; rc47 <= 2'd1; rc48 <= 3'd5; rc49 <= 3'd3; rc50 <= 3'd7; rc51 <= 3'd2; rc52 <= 3'd7; rc53 <= 3'd2; rc54 <= 4'd9; rc55 <= 2'd1; rc56 <= 3'd7; rc57 <= 3'd2; rc58 <= 4'd9; rc59 <= 2'd1; rc60 <= 4'd9; rc61 <= 2'd1; rc62 <= 4'd11; rc63 <= 1'd0; end
            {4'd7, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd6; rc2 <= 2'd0; rc3 <= 4'd5; rc4 <= 2'd0; rc5 <= 4'd5; rc6 <= 3'd0; rc7 <= 3'd4; rc8 <= 2'd0; rc9 <= 4'd5; rc10 <= 3'd0; rc11 <= 3'd4; rc12 <= 3'd0; rc13 <= 3'd4; rc14 <= 3'd0; rc15 <= 3'd3; rc16 <= 2'd0; rc17 <= 4'd5; rc18 <= 3'd0; rc19 <= 3'd4; rc20 <= 3'd0; rc21 <= 3'd4; rc22 <= 3'd0; rc23 <= 3'd3; rc24 <= 3'd0; rc25 <= 3'd4; rc26 <= 3'd0; rc27 <= 3'd3; rc28 <= 3'd0; rc29 <= 3'd3; rc30 <= 4'd0; rc31 <= 2'd2; rc32 <= 2'd1; rc33 <= 4'd9; rc34 <= 3'd2; rc35 <= 3'd7; rc36 <= 3'd2; rc37 <= 3'd7; rc38 <= 3'd3; rc39 <= 3'd5; rc40 <= 3'd2; rc41 <= 3'd7; rc42 <= 3'd3; rc43 <= 3'd5; rc44 <= 3'd3; rc45 <= 3'd5; rc46 <= 4'd4; rc47 <= 2'd3; rc48 <= 3'd2; rc49 <= 3'd7; rc50 <= 3'd3; rc51 <= 3'd5; rc52 <= 3'd3; rc53 <= 3'd5; rc54 <= 4'd4; rc55 <= 2'd3; rc56 <= 3'd3; rc57 <= 3'd5; rc58 <= 4'd4; rc59 <= 2'd3; rc60 <= 4'd4; rc61 <= 2'd3; rc62 <= 4'd5; rc63 <= 1'd1; end
            {4'd7, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 3'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 3'd0; rc12 <= 3'd3; rc13 <= 3'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 3'd0; rc20 <= 3'd3; rc21 <= 3'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 3'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 2'd0; rc32 <= 2'd3; rc33 <= 4'd4; rc34 <= 3'd5; rc35 <= 3'd3; rc36 <= 3'd5; rc37 <= 3'd3; rc38 <= 3'd7; rc39 <= 3'd2; rc40 <= 3'd5; rc41 <= 3'd3; rc42 <= 3'd7; rc43 <= 3'd2; rc44 <= 3'd7; rc45 <= 3'd2; rc46 <= 4'd9; rc47 <= 2'd1; rc48 <= 3'd5; rc49 <= 3'd3; rc50 <= 3'd7; rc51 <= 3'd2; rc52 <= 3'd7; rc53 <= 3'd2; rc54 <= 4'd9; rc55 <= 2'd1; rc56 <= 3'd7; rc57 <= 3'd2; rc58 <= 4'd9; rc59 <= 2'd1; rc60 <= 4'd9; rc61 <= 2'd1; rc62 <= 4'd11; rc63 <= 1'd0; end
            {4'd8, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd6; rc2 <= 2'd0; rc3 <= 4'd5; rc4 <= 2'd0; rc5 <= 4'd5; rc6 <= 3'd0; rc7 <= 3'd4; rc8 <= 2'd0; rc9 <= 4'd5; rc10 <= 3'd0; rc11 <= 3'd4; rc12 <= 3'd0; rc13 <= 3'd4; rc14 <= 3'd0; rc15 <= 3'd3; rc16 <= 2'd0; rc17 <= 4'd5; rc18 <= 3'd0; rc19 <= 3'd4; rc20 <= 3'd0; rc21 <= 3'd4; rc22 <= 3'd0; rc23 <= 3'd3; rc24 <= 3'd0; rc25 <= 3'd4; rc26 <= 3'd0; rc27 <= 3'd3; rc28 <= 3'd0; rc29 <= 3'd3; rc30 <= 4'd0; rc31 <= 2'd2; rc32 <= 2'd1; rc33 <= 4'd9; rc34 <= 3'd2; rc35 <= 3'd7; rc36 <= 3'd2; rc37 <= 3'd7; rc38 <= 3'd3; rc39 <= 3'd5; rc40 <= 3'd2; rc41 <= 3'd7; rc42 <= 3'd3; rc43 <= 3'd5; rc44 <= 3'd3; rc45 <= 3'd5; rc46 <= 4'd4; rc47 <= 2'd3; rc48 <= 3'd2; rc49 <= 3'd7; rc50 <= 3'd3; rc51 <= 3'd5; rc52 <= 3'd3; rc53 <= 3'd5; rc54 <= 4'd4; rc55 <= 2'd3; rc56 <= 3'd3; rc57 <= 3'd5; rc58 <= 4'd4; rc59 <= 2'd3; rc60 <= 4'd4; rc61 <= 2'd3; rc62 <= 4'd5; rc63 <= 1'd1; end
            {4'd8, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 3'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 3'd0; rc12 <= 3'd3; rc13 <= 3'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 3'd0; rc20 <= 3'd3; rc21 <= 3'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 3'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 2'd0; rc32 <= 2'd3; rc33 <= 4'd4; rc34 <= 3'd5; rc35 <= 3'd3; rc36 <= 3'd5; rc37 <= 3'd3; rc38 <= 3'd7; rc39 <= 3'd2; rc40 <= 3'd5; rc41 <= 3'd3; rc42 <= 3'd7; rc43 <= 3'd2; rc44 <= 3'd7; rc45 <= 3'd2; rc46 <= 4'd9; rc47 <= 2'd1; rc48 <= 3'd5; rc49 <= 3'd3; rc50 <= 3'd7; rc51 <= 3'd2; rc52 <= 3'd7; rc53 <= 3'd2; rc54 <= 4'd9; rc55 <= 2'd1; rc56 <= 3'd7; rc57 <= 3'd2; rc58 <= 4'd9; rc59 <= 2'd1; rc60 <= 4'd9; rc61 <= 2'd1; rc62 <= 4'd11; rc63 <= 1'd0; end
            {4'd9, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd6; rc2 <= 2'd0; rc3 <= 4'd5; rc4 <= 2'd0; rc5 <= 4'd5; rc6 <= 3'd0; rc7 <= 3'd4; rc8 <= 2'd0; rc9 <= 4'd5; rc10 <= 3'd0; rc11 <= 3'd4; rc12 <= 3'd0; rc13 <= 3'd4; rc14 <= 3'd0; rc15 <= 3'd3; rc16 <= 2'd0; rc17 <= 4'd5; rc18 <= 3'd0; rc19 <= 3'd4; rc20 <= 3'd0; rc21 <= 3'd4; rc22 <= 3'd0; rc23 <= 3'd3; rc24 <= 3'd0; rc25 <= 3'd4; rc26 <= 3'd0; rc27 <= 3'd3; rc28 <= 3'd0; rc29 <= 3'd3; rc30 <= 4'd0; rc31 <= 2'd2; rc32 <= 2'd1; rc33 <= 4'd9; rc34 <= 3'd2; rc35 <= 3'd7; rc36 <= 3'd2; rc37 <= 3'd7; rc38 <= 3'd3; rc39 <= 3'd5; rc40 <= 3'd2; rc41 <= 3'd7; rc42 <= 3'd3; rc43 <= 3'd5; rc44 <= 3'd3; rc45 <= 3'd5; rc46 <= 4'd4; rc47 <= 2'd3; rc48 <= 3'd2; rc49 <= 3'd7; rc50 <= 3'd3; rc51 <= 3'd5; rc52 <= 3'd3; rc53 <= 3'd5; rc54 <= 4'd4; rc55 <= 2'd3; rc56 <= 3'd3; rc57 <= 3'd5; rc58 <= 4'd4; rc59 <= 2'd3; rc60 <= 4'd4; rc61 <= 2'd3; rc62 <= 4'd5; rc63 <= 1'd1; end
            {4'd9, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 3'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 3'd0; rc12 <= 3'd3; rc13 <= 3'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 3'd0; rc20 <= 3'd3; rc21 <= 3'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 3'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 2'd0; rc32 <= 2'd3; rc33 <= 4'd4; rc34 <= 3'd5; rc35 <= 3'd3; rc36 <= 3'd5; rc37 <= 3'd3; rc38 <= 3'd7; rc39 <= 3'd2; rc40 <= 3'd5; rc41 <= 3'd3; rc42 <= 3'd7; rc43 <= 3'd2; rc44 <= 3'd7; rc45 <= 3'd2; rc46 <= 4'd9; rc47 <= 2'd1; rc48 <= 3'd5; rc49 <= 3'd3; rc50 <= 3'd7; rc51 <= 3'd2; rc52 <= 3'd7; rc53 <= 3'd2; rc54 <= 4'd9; rc55 <= 2'd1; rc56 <= 3'd7; rc57 <= 3'd2; rc58 <= 4'd9; rc59 <= 2'd1; rc60 <= 4'd9; rc61 <= 2'd1; rc62 <= 4'd11; rc63 <= 1'd0; end
            {4'd10, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd6; rc2 <= 2'd0; rc3 <= 4'd5; rc4 <= 2'd0; rc5 <= 4'd5; rc6 <= 3'd0; rc7 <= 3'd4; rc8 <= 2'd0; rc9 <= 4'd5; rc10 <= 3'd0; rc11 <= 3'd4; rc12 <= 3'd0; rc13 <= 3'd4; rc14 <= 3'd0; rc15 <= 3'd3; rc16 <= 2'd0; rc17 <= 4'd5; rc18 <= 3'd0; rc19 <= 3'd4; rc20 <= 3'd0; rc21 <= 3'd4; rc22 <= 3'd0; rc23 <= 3'd3; rc24 <= 3'd0; rc25 <= 3'd4; rc26 <= 3'd0; rc27 <= 3'd3; rc28 <= 3'd0; rc29 <= 3'd3; rc30 <= 4'd0; rc31 <= 2'd2; rc32 <= 2'd1; rc33 <= 4'd9; rc34 <= 3'd2; rc35 <= 3'd7; rc36 <= 3'd2; rc37 <= 3'd7; rc38 <= 3'd3; rc39 <= 3'd5; rc40 <= 3'd2; rc41 <= 3'd7; rc42 <= 3'd3; rc43 <= 3'd5; rc44 <= 3'd3; rc45 <= 3'd5; rc46 <= 4'd4; rc47 <= 2'd3; rc48 <= 3'd2; rc49 <= 3'd7; rc50 <= 3'd3; rc51 <= 3'd5; rc52 <= 3'd3; rc53 <= 3'd5; rc54 <= 4'd4; rc55 <= 2'd3; rc56 <= 3'd3; rc57 <= 3'd5; rc58 <= 4'd4; rc59 <= 2'd3; rc60 <= 4'd4; rc61 <= 2'd3; rc62 <= 4'd5; rc63 <= 1'd1; end
            {4'd10, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 3'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 3'd0; rc12 <= 3'd3; rc13 <= 3'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 3'd0; rc20 <= 3'd3; rc21 <= 3'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 3'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 2'd0; rc32 <= 2'd3; rc33 <= 4'd4; rc34 <= 3'd5; rc35 <= 3'd3; rc36 <= 3'd5; rc37 <= 3'd3; rc38 <= 3'd7; rc39 <= 3'd2; rc40 <= 3'd5; rc41 <= 3'd3; rc42 <= 3'd7; rc43 <= 3'd2; rc44 <= 3'd7; rc45 <= 3'd2; rc46 <= 4'd9; rc47 <= 2'd1; rc48 <= 3'd5; rc49 <= 3'd3; rc50 <= 3'd7; rc51 <= 3'd2; rc52 <= 3'd7; rc53 <= 3'd2; rc54 <= 4'd9; rc55 <= 2'd1; rc56 <= 3'd7; rc57 <= 3'd2; rc58 <= 4'd9; rc59 <= 2'd1; rc60 <= 4'd9; rc61 <= 2'd1; rc62 <= 4'd11; rc63 <= 1'd0; end
            {4'd11, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd6; rc2 <= 2'd0; rc3 <= 4'd5; rc4 <= 2'd0; rc5 <= 4'd5; rc6 <= 3'd0; rc7 <= 3'd4; rc8 <= 2'd0; rc9 <= 4'd5; rc10 <= 3'd0; rc11 <= 3'd4; rc12 <= 3'd0; rc13 <= 3'd4; rc14 <= 3'd0; rc15 <= 3'd3; rc16 <= 2'd0; rc17 <= 4'd5; rc18 <= 3'd0; rc19 <= 3'd4; rc20 <= 3'd0; rc21 <= 3'd4; rc22 <= 3'd0; rc23 <= 3'd3; rc24 <= 3'd0; rc25 <= 3'd4; rc26 <= 3'd0; rc27 <= 3'd3; rc28 <= 3'd0; rc29 <= 3'd3; rc30 <= 4'd0; rc31 <= 2'd2; rc32 <= 2'd1; rc33 <= 4'd9; rc34 <= 3'd2; rc35 <= 3'd7; rc36 <= 3'd2; rc37 <= 3'd7; rc38 <= 3'd3; rc39 <= 3'd5; rc40 <= 3'd2; rc41 <= 3'd7; rc42 <= 3'd3; rc43 <= 3'd5; rc44 <= 3'd3; rc45 <= 3'd5; rc46 <= 4'd4; rc47 <= 2'd3; rc48 <= 3'd2; rc49 <= 3'd7; rc50 <= 3'd3; rc51 <= 3'd5; rc52 <= 3'd3; rc53 <= 3'd5; rc54 <= 4'd4; rc55 <= 2'd3; rc56 <= 3'd3; rc57 <= 3'd5; rc58 <= 4'd4; rc59 <= 2'd3; rc60 <= 4'd4; rc61 <= 2'd3; rc62 <= 4'd5; rc63 <= 1'd1; end
            {4'd11, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 3'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 3'd0; rc12 <= 3'd3; rc13 <= 3'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 3'd0; rc20 <= 3'd3; rc21 <= 3'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 3'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 2'd0; rc32 <= 2'd3; rc33 <= 4'd4; rc34 <= 3'd5; rc35 <= 3'd3; rc36 <= 3'd5; rc37 <= 3'd3; rc38 <= 3'd7; rc39 <= 3'd2; rc40 <= 3'd5; rc41 <= 3'd3; rc42 <= 3'd7; rc43 <= 3'd2; rc44 <= 3'd7; rc45 <= 3'd2; rc46 <= 4'd9; rc47 <= 2'd1; rc48 <= 3'd5; rc49 <= 3'd3; rc50 <= 3'd7; rc51 <= 3'd2; rc52 <= 3'd7; rc53 <= 3'd2; rc54 <= 4'd9; rc55 <= 2'd1; rc56 <= 3'd7; rc57 <= 3'd2; rc58 <= 4'd9; rc59 <= 2'd1; rc60 <= 4'd9; rc61 <= 2'd1; rc62 <= 4'd11; rc63 <= 1'd0; end
            {4'd12, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd6; rc2 <= 2'd0; rc3 <= 4'd5; rc4 <= 2'd0; rc5 <= 4'd5; rc6 <= 3'd0; rc7 <= 3'd4; rc8 <= 2'd0; rc9 <= 4'd5; rc10 <= 3'd0; rc11 <= 3'd4; rc12 <= 3'd0; rc13 <= 3'd4; rc14 <= 3'd0; rc15 <= 3'd3; rc16 <= 2'd0; rc17 <= 4'd5; rc18 <= 3'd0; rc19 <= 3'd4; rc20 <= 3'd0; rc21 <= 3'd4; rc22 <= 3'd0; rc23 <= 3'd3; rc24 <= 3'd0; rc25 <= 3'd4; rc26 <= 3'd0; rc27 <= 3'd3; rc28 <= 3'd0; rc29 <= 3'd3; rc30 <= 4'd0; rc31 <= 2'd2; rc32 <= 2'd1; rc33 <= 4'd9; rc34 <= 3'd2; rc35 <= 3'd7; rc36 <= 3'd2; rc37 <= 3'd7; rc38 <= 3'd3; rc39 <= 3'd5; rc40 <= 3'd2; rc41 <= 3'd7; rc42 <= 3'd3; rc43 <= 3'd5; rc44 <= 3'd3; rc45 <= 3'd5; rc46 <= 4'd4; rc47 <= 2'd3; rc48 <= 3'd2; rc49 <= 3'd7; rc50 <= 3'd3; rc51 <= 3'd5; rc52 <= 3'd3; rc53 <= 3'd5; rc54 <= 4'd4; rc55 <= 2'd3; rc56 <= 3'd3; rc57 <= 3'd5; rc58 <= 4'd4; rc59 <= 2'd3; rc60 <= 4'd4; rc61 <= 2'd3; rc62 <= 4'd5; rc63 <= 1'd1; end
            {4'd12, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 3'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 3'd0; rc12 <= 3'd3; rc13 <= 3'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 3'd0; rc20 <= 3'd3; rc21 <= 3'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 3'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 2'd0; rc32 <= 2'd3; rc33 <= 4'd4; rc34 <= 3'd5; rc35 <= 3'd3; rc36 <= 3'd5; rc37 <= 3'd3; rc38 <= 3'd7; rc39 <= 3'd2; rc40 <= 3'd5; rc41 <= 3'd3; rc42 <= 3'd7; rc43 <= 3'd2; rc44 <= 3'd7; rc45 <= 3'd2; rc46 <= 4'd9; rc47 <= 2'd1; rc48 <= 3'd5; rc49 <= 3'd3; rc50 <= 3'd7; rc51 <= 3'd2; rc52 <= 3'd7; rc53 <= 3'd2; rc54 <= 4'd9; rc55 <= 2'd1; rc56 <= 3'd7; rc57 <= 3'd2; rc58 <= 4'd9; rc59 <= 2'd1; rc60 <= 4'd9; rc61 <= 2'd1; rc62 <= 4'd11; rc63 <= 1'd0; end
            {4'd13, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd6; rc2 <= 2'd0; rc3 <= 4'd5; rc4 <= 2'd0; rc5 <= 4'd5; rc6 <= 3'd0; rc7 <= 3'd4; rc8 <= 2'd0; rc9 <= 4'd5; rc10 <= 3'd0; rc11 <= 3'd4; rc12 <= 3'd0; rc13 <= 3'd4; rc14 <= 3'd0; rc15 <= 3'd3; rc16 <= 2'd0; rc17 <= 4'd5; rc18 <= 3'd0; rc19 <= 3'd4; rc20 <= 3'd0; rc21 <= 3'd4; rc22 <= 3'd0; rc23 <= 3'd3; rc24 <= 3'd0; rc25 <= 3'd4; rc26 <= 3'd0; rc27 <= 3'd3; rc28 <= 3'd0; rc29 <= 3'd3; rc30 <= 4'd0; rc31 <= 2'd2; rc32 <= 2'd1; rc33 <= 4'd9; rc34 <= 3'd2; rc35 <= 3'd7; rc36 <= 3'd2; rc37 <= 3'd7; rc38 <= 3'd3; rc39 <= 3'd5; rc40 <= 3'd2; rc41 <= 3'd7; rc42 <= 3'd3; rc43 <= 3'd5; rc44 <= 3'd3; rc45 <= 3'd5; rc46 <= 4'd4; rc47 <= 2'd3; rc48 <= 3'd2; rc49 <= 3'd7; rc50 <= 3'd3; rc51 <= 3'd5; rc52 <= 3'd3; rc53 <= 3'd5; rc54 <= 4'd4; rc55 <= 2'd3; rc56 <= 3'd3; rc57 <= 3'd5; rc58 <= 4'd4; rc59 <= 2'd3; rc60 <= 4'd4; rc61 <= 2'd3; rc62 <= 4'd5; rc63 <= 1'd1; end
            {4'd13, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 3'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 3'd0; rc12 <= 3'd3; rc13 <= 3'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 3'd0; rc20 <= 3'd3; rc21 <= 3'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 3'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 2'd0; rc32 <= 2'd3; rc33 <= 4'd4; rc34 <= 3'd5; rc35 <= 3'd3; rc36 <= 3'd5; rc37 <= 3'd3; rc38 <= 3'd7; rc39 <= 3'd2; rc40 <= 3'd5; rc41 <= 3'd3; rc42 <= 3'd7; rc43 <= 3'd2; rc44 <= 3'd7; rc45 <= 3'd2; rc46 <= 4'd9; rc47 <= 2'd1; rc48 <= 3'd5; rc49 <= 3'd3; rc50 <= 3'd7; rc51 <= 3'd2; rc52 <= 3'd7; rc53 <= 3'd2; rc54 <= 4'd9; rc55 <= 2'd1; rc56 <= 3'd7; rc57 <= 3'd2; rc58 <= 4'd9; rc59 <= 2'd1; rc60 <= 4'd9; rc61 <= 2'd1; rc62 <= 4'd11; rc63 <= 1'd0; end
            {4'd14, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd6; rc2 <= 2'd0; rc3 <= 4'd5; rc4 <= 2'd0; rc5 <= 4'd5; rc6 <= 3'd0; rc7 <= 3'd4; rc8 <= 2'd0; rc9 <= 4'd5; rc10 <= 3'd0; rc11 <= 3'd4; rc12 <= 3'd0; rc13 <= 3'd4; rc14 <= 3'd0; rc15 <= 3'd3; rc16 <= 2'd0; rc17 <= 4'd5; rc18 <= 3'd0; rc19 <= 3'd4; rc20 <= 3'd0; rc21 <= 3'd4; rc22 <= 3'd0; rc23 <= 3'd3; rc24 <= 3'd0; rc25 <= 3'd4; rc26 <= 3'd0; rc27 <= 3'd3; rc28 <= 3'd0; rc29 <= 3'd3; rc30 <= 4'd0; rc31 <= 2'd2; rc32 <= 2'd1; rc33 <= 4'd9; rc34 <= 3'd2; rc35 <= 3'd7; rc36 <= 3'd2; rc37 <= 3'd7; rc38 <= 3'd3; rc39 <= 3'd5; rc40 <= 3'd2; rc41 <= 3'd7; rc42 <= 3'd3; rc43 <= 3'd5; rc44 <= 3'd3; rc45 <= 3'd5; rc46 <= 4'd4; rc47 <= 2'd3; rc48 <= 3'd2; rc49 <= 3'd7; rc50 <= 3'd3; rc51 <= 3'd5; rc52 <= 3'd3; rc53 <= 3'd5; rc54 <= 4'd4; rc55 <= 2'd3; rc56 <= 3'd3; rc57 <= 3'd5; rc58 <= 4'd4; rc59 <= 2'd3; rc60 <= 4'd4; rc61 <= 2'd3; rc62 <= 4'd5; rc63 <= 1'd1; end
            {4'd14, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 3'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 3'd0; rc12 <= 3'd3; rc13 <= 3'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 3'd0; rc20 <= 3'd3; rc21 <= 3'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 3'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 2'd0; rc32 <= 2'd3; rc33 <= 4'd4; rc34 <= 3'd5; rc35 <= 3'd3; rc36 <= 3'd5; rc37 <= 3'd3; rc38 <= 3'd7; rc39 <= 3'd2; rc40 <= 3'd5; rc41 <= 3'd3; rc42 <= 3'd7; rc43 <= 3'd2; rc44 <= 3'd7; rc45 <= 3'd2; rc46 <= 4'd9; rc47 <= 2'd1; rc48 <= 3'd5; rc49 <= 3'd3; rc50 <= 3'd7; rc51 <= 3'd2; rc52 <= 3'd7; rc53 <= 3'd2; rc54 <= 4'd9; rc55 <= 2'd1; rc56 <= 3'd7; rc57 <= 3'd2; rc58 <= 4'd9; rc59 <= 2'd1; rc60 <= 4'd9; rc61 <= 2'd1; rc62 <= 4'd11; rc63 <= 1'd0; end
            {4'd15, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd6; rc2 <= 2'd0; rc3 <= 4'd5; rc4 <= 2'd0; rc5 <= 4'd5; rc6 <= 3'd0; rc7 <= 3'd4; rc8 <= 2'd0; rc9 <= 4'd5; rc10 <= 3'd0; rc11 <= 3'd4; rc12 <= 3'd0; rc13 <= 3'd4; rc14 <= 3'd0; rc15 <= 3'd3; rc16 <= 2'd0; rc17 <= 4'd5; rc18 <= 3'd0; rc19 <= 3'd4; rc20 <= 3'd0; rc21 <= 3'd4; rc22 <= 3'd0; rc23 <= 3'd3; rc24 <= 3'd0; rc25 <= 3'd4; rc26 <= 3'd0; rc27 <= 3'd3; rc28 <= 3'd0; rc29 <= 3'd3; rc30 <= 4'd0; rc31 <= 2'd2; rc32 <= 2'd1; rc33 <= 4'd9; rc34 <= 3'd2; rc35 <= 3'd7; rc36 <= 3'd2; rc37 <= 3'd7; rc38 <= 3'd3; rc39 <= 3'd5; rc40 <= 3'd2; rc41 <= 3'd7; rc42 <= 3'd3; rc43 <= 3'd5; rc44 <= 3'd3; rc45 <= 3'd5; rc46 <= 4'd4; rc47 <= 2'd3; rc48 <= 3'd2; rc49 <= 3'd7; rc50 <= 3'd3; rc51 <= 3'd5; rc52 <= 3'd3; rc53 <= 3'd5; rc54 <= 4'd4; rc55 <= 2'd3; rc56 <= 3'd3; rc57 <= 3'd5; rc58 <= 4'd4; rc59 <= 2'd3; rc60 <= 4'd4; rc61 <= 2'd3; rc62 <= 4'd5; rc63 <= 1'd1; end
            {4'd15, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 3'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 3'd0; rc12 <= 3'd3; rc13 <= 3'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 3'd0; rc20 <= 3'd3; rc21 <= 3'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 3'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 2'd0; rc32 <= 2'd3; rc33 <= 4'd4; rc34 <= 3'd5; rc35 <= 3'd3; rc36 <= 3'd5; rc37 <= 3'd3; rc38 <= 3'd7; rc39 <= 3'd2; rc40 <= 3'd5; rc41 <= 3'd3; rc42 <= 3'd7; rc43 <= 3'd2; rc44 <= 3'd7; rc45 <= 3'd2; rc46 <= 4'd9; rc47 <= 2'd1; rc48 <= 3'd5; rc49 <= 3'd3; rc50 <= 3'd7; rc51 <= 3'd2; rc52 <= 3'd7; rc53 <= 3'd2; rc54 <= 4'd9; rc55 <= 2'd1; rc56 <= 3'd7; rc57 <= 3'd2; rc58 <= 4'd9; rc59 <= 2'd1; rc60 <= 4'd9; rc61 <= 2'd1; rc62 <= 4'd11; rc63 <= 1'd0; end
            default: ;
        endcase
    end
    always_ff @(posedge clk) begin
        case ({wk_s, wk_f})
            {4'd0, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd0; wc2 <= 3'd1; wc3 <= 3'd0; wc4 <= 3'd1; wc5 <= 4'd1; wc6 <= 3'd1; wc7 <= 3'd0; wc8 <= 3'd1; wc9 <= 4'd1; wc10 <= 4'd2; wc11 <= 4'd1; wc12 <= 3'd1; wc13 <= 4'd1; wc14 <= 3'd1; wc15 <= 3'd0; wc16 <= 3'd1; wc17 <= 3'd1; wc18 <= 4'd2; wc19 <= 3'd1; wc20 <= 4'd2; wc21 <= 4'd2; wc22 <= 4'd2; wc23 <= 3'd1; wc24 <= 3'd1; wc25 <= 3'd1; wc26 <= 4'd2; wc27 <= 3'd1; wc28 <= 3'd1; wc29 <= 3'd1; wc30 <= 3'd1; wc31 <= 2'd0; wc32 <= 2'd2; wc33 <= 3'd3; wc34 <= 3'd5; wc35 <= 3'd3; wc36 <= 3'd5; wc37 <= 4'd6; wc38 <= 3'd5; wc39 <= 3'd3; wc40 <= 3'd5; wc41 <= 4'd6; wc42 <= 4'd8; wc43 <= 4'd6; wc44 <= 3'd5; wc45 <= 4'd6; wc46 <= 3'd5; wc47 <= 3'd3; wc48 <= 3'd4; wc49 <= 3'd5; wc50 <= 4'd7; wc51 <= 3'd5; wc52 <= 4'd7; wc53 <= 4'd8; wc54 <= 4'd7; wc55 <= 3'd5; wc56 <= 3'd4; wc57 <= 3'd5; wc58 <= 4'd7; wc59 <= 3'd5; wc60 <= 3'd4; wc61 <= 3'd5; wc62 <= 3'd4; wc63 <= 2'd2; end
            {4'd0, 1'b1}: begin wc0 <= 2'd2; wc1 <= 3'd3; wc2 <= 3'd5; wc3 <= 3'd3; wc4 <= 3'd5; wc5 <= 4'd6; wc6 <= 3'd5; wc7 <= 3'd3; wc8 <= 3'd5; wc9 <= 4'd6; wc10 <= 4'd8; wc11 <= 4'd6; wc12 <= 3'd5; wc13 <= 4'd6; wc14 <= 3'd5; wc15 <= 3'd3; wc16 <= 3'd4; wc17 <= 3'd5; wc18 <= 4'd7; wc19 <= 3'd5; wc20 <= 4'd7; wc21 <= 4'd8; wc22 <= 4'd7; wc23 <= 3'd5; wc24 <= 3'd4; wc25 <= 3'd5; wc26 <= 4'd7; wc27 <= 3'd5; wc28 <= 3'd4; wc29 <= 3'd5; wc30 <= 3'd4; wc31 <= 2'd2; wc32 <= 2'd0; wc33 <= 3'd0; wc34 <= 3'd1; wc35 <= 3'd0; wc36 <= 3'd1; wc37 <= 4'd1; wc38 <= 3'd1; wc39 <= 3'd0; wc40 <= 3'd1; wc41 <= 4'd1; wc42 <= 4'd2; wc43 <= 4'd1; wc44 <= 3'd1; wc45 <= 4'd1; wc46 <= 3'd1; wc47 <= 3'd0; wc48 <= 3'd1; wc49 <= 3'd1; wc50 <= 4'd2; wc51 <= 3'd1; wc52 <= 4'd2; wc53 <= 4'd2; wc54 <= 4'd2; wc55 <= 3'd1; wc56 <= 3'd1; wc57 <= 3'd1; wc58 <= 4'd2; wc59 <= 3'd1; wc60 <= 3'd1; wc61 <= 3'd1; wc62 <= 3'd1; wc63 <= 2'd0; end
            {4'd1, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd0; wc3 <= 3'd0; wc4 <= 3'd1; wc5 <= 4'd2; wc6 <= 3'd0; wc7 <= 3'd0; wc8 <= 3'd1; wc9 <= 4'd2; wc10 <= 4'd1; wc11 <= 4'd1; wc12 <= 3'd1; wc13 <= 4'd2; wc14 <= 3'd0; wc15 <= 3'd0; wc16 <= 3'd1; wc17 <= 3'd2; wc18 <= 4'd1; wc19 <= 3'd1; wc20 <= 4'd2; wc21 <= 4'd3; wc22 <= 4'd1; wc23 <= 3'd1; wc24 <= 3'd1; wc25 <= 3'd2; wc26 <= 4'd1; wc27 <= 3'd1; wc28 <= 3'd1; wc29 <= 3'd2; wc30 <= 3'd0; wc31 <= 2'd0; wc32 <= 2'd2; wc33 <= 3'd4; wc34 <= 3'd4; wc35 <= 3'd3; wc36 <= 3'd5; wc37 <= 4'd7; wc38 <= 3'd4; wc39 <= 3'd3; wc40 <= 3'd5; wc41 <= 4'd7; wc42 <= 4'd7; wc43 <= 4'd6; wc44 <= 3'd5; wc45 <= 4'd7; wc46 <= 3'd4; wc47 <= 3'd3; wc48 <= 3'd4; wc49 <= 3'd6; wc50 <= 4'd6; wc51 <= 3'd5; wc52 <= 4'd7; wc53 <= 4'd9; wc54 <= 4'd6; wc55 <= 3'd5; wc56 <= 3'd4; wc57 <= 3'd6; wc58 <= 4'd6; wc59 <= 3'd5; wc60 <= 3'd4; wc61 <= 3'd6; wc62 <= 3'd3; wc63 <= 2'd2; end
            {4'd1, 1'b1}: begin wc0 <= 2'd2; wc1 <= 3'd4; wc2 <= 3'd4; wc3 <= 3'd3; wc4 <= 3'd5; wc5 <= 4'd7; wc6 <= 3'd4; wc7 <= 3'd3; wc8 <= 3'd5; wc9 <= 4'd7; wc10 <= 4'd7; wc11 <= 4'd6; wc12 <= 3'd5; wc13 <= 4'd7; wc14 <= 3'd4; wc15 <= 3'd3; wc16 <= 3'd4; wc17 <= 3'd6; wc18 <= 4'd6; wc19 <= 3'd5; wc20 <= 4'd7; wc21 <= 4'd9; wc22 <= 4'd6; wc23 <= 3'd5; wc24 <= 3'd4; wc25 <= 3'd6; wc26 <= 4'd6; wc27 <= 3'd5; wc28 <= 3'd4; wc29 <= 3'd6; wc30 <= 3'd3; wc31 <= 2'd2; wc32 <= 2'd0; wc33 <= 3'd1; wc34 <= 3'd0; wc35 <= 3'd0; wc36 <= 3'd1; wc37 <= 4'd2; wc38 <= 3'd0; wc39 <= 3'd0; wc40 <= 3'd1; wc41 <= 4'd2; wc42 <= 4'd1; wc43 <= 4'd1; wc44 <= 3'd1; wc45 <= 4'd2; wc46 <= 3'd0; wc47 <= 3'd0; wc48 <= 3'd1; wc49 <= 3'd2; wc50 <= 4'd1; wc51 <= 3'd1; wc52 <= 4'd2; wc53 <= 4'd3; wc54 <= 4'd1; wc55 <= 3'd1; wc56 <= 3'd1; wc57 <= 3'd2; wc58 <= 4'd1; wc59 <= 3'd1; wc60 <= 3'd1; wc61 <= 3'd2; wc62 <= 3'd0; wc63 <= 2'd0; end
            {4'd2, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd0; wc5 <= 4'd0; wc6 <= 3'd0; wc7 <= 3'd0; wc8 <= 3'd1; wc9 <= 4'd2; wc10 <= 4'd3; wc11 <= 4'd2; wc12 <= 3'd0; wc13 <= 4'd0; wc14 <= 3'd0; wc15 <= 3'd0; wc16 <= 3'd1; wc17 <= 3'd2; wc18 <= 4'd3; wc19 <= 3'd2; wc20 <= 4'd1; wc21 <= 4'd1; wc22 <= 4'd1; wc23 <= 3'd1; wc24 <= 3'd1; wc25 <= 3'd2; wc26 <= 4'd3; wc27 <= 3'd2; wc28 <= 3'd0; wc29 <= 3'd0; wc30 <= 3'd0; wc31 <= 2'd0; wc32 <= 2'd2; wc33 <= 3'd4; wc34 <= 3'd6; wc35 <= 3'd4; wc36 <= 3'd4; wc37 <= 4'd5; wc38 <= 3'd4; wc39 <= 3'd3; wc40 <= 3'd5; wc41 <= 4'd7; wc42 <= 4'd9; wc43 <= 4'd7; wc44 <= 3'd4; wc45 <= 4'd5; wc46 <= 3'd4; wc47 <= 3'd3; wc48 <= 3'd4; wc49 <= 3'd6; wc50 <= 4'd8; wc51 <= 3'd6; wc52 <= 4'd6; wc53 <= 4'd7; wc54 <= 4'd6; wc55 <= 3'd5; wc56 <= 3'd4; wc57 <= 3'd6; wc58 <= 4'd8; wc59 <= 3'd6; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; end
            {4'd2, 1'b1}: begin wc0 <= 2'd2; wc1 <= 3'd4; wc2 <= 3'd6; wc3 <= 3'd4; wc4 <= 3'd4; wc5 <= 4'd5; wc6 <= 3'd4; wc7 <= 3'd3; wc8 <= 3'd5; wc9 <= 4'd7; wc10 <= 4'd9; wc11 <= 4'd7; wc12 <= 3'd4; wc13 <= 4'd5; wc14 <= 3'd4; wc15 <= 3'd3; wc16 <= 3'd4; wc17 <= 3'd6; wc18 <= 4'd8; wc19 <= 3'd6; wc20 <= 4'd6; wc21 <= 4'd7; wc22 <= 4'd6; wc23 <= 3'd5; wc24 <= 3'd4; wc25 <= 3'd6; wc26 <= 4'd8; wc27 <= 3'd6; wc28 <= 3'd3; wc29 <= 3'd4; wc30 <= 3'd3; wc31 <= 2'd2; wc32 <= 2'd0; wc33 <= 3'd1; wc34 <= 3'd2; wc35 <= 3'd1; wc36 <= 3'd0; wc37 <= 4'd0; wc38 <= 3'd0; wc39 <= 3'd0; wc40 <= 3'd1; wc41 <= 4'd2; wc42 <= 4'd3; wc43 <= 4'd2; wc44 <= 3'd0; wc45 <= 4'd0; wc46 <= 3'd0; wc47 <= 3'd0; wc48 <= 3'd1; wc49 <= 3'd2; wc50 <= 4'd3; wc51 <= 3'd2; wc52 <= 4'd1; wc53 <= 4'd1; wc54 <= 4'd1; wc55 <= 3'd1; wc56 <= 3'd1; wc57 <= 3'd2; wc58 <= 4'd3; wc59 <= 3'd2; wc60 <= 3'd0; wc61 <= 3'd0; wc62 <= 3'd0; wc63 <= 2'd0; end
            {4'd3, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd0; wc9 <= 4'd0; wc10 <= 4'd0; wc11 <= 4'd0; wc12 <= 3'd0; wc13 <= 4'd0; wc14 <= 3'd0; wc15 <= 3'd0; wc16 <= 3'd1; wc17 <= 3'd2; wc18 <= 4'd3; wc19 <= 3'd2; wc20 <= 4'd3; wc21 <= 4'd4; wc22 <= 4'd3; wc23 <= 3'd2; wc24 <= 3'd0; wc25 <= 3'd0; wc26 <= 4'd0; wc27 <= 3'd0; wc28 <= 3'd0; wc29 <= 3'd0; wc30 <= 3'd0; wc31 <= 2'd0; wc32 <= 2'd2; wc33 <= 3'd4; wc34 <= 3'd6; wc35 <= 3'd4; wc36 <= 3'd6; wc37 <= 4'd8; wc38 <= 3'd6; wc39 <= 3'd4; wc40 <= 3'd4; wc41 <= 4'd5; wc42 <= 4'd6; wc43 <= 4'd5; wc44 <= 3'd4; wc45 <= 4'd5; wc46 <= 3'd4; wc47 <= 3'd3; wc48 <= 3'd4; wc49 <= 3'd6; wc50 <= 4'd8; wc51 <= 3'd6; wc52 <= 4'd8; wc53 <= 4'd10; wc54 <= 4'd8; wc55 <= 3'd6; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; end
            {4'd3, 1'b1}: begin wc0 <= 2'd2; wc1 <= 3'd4; wc2 <= 3'd6; wc3 <= 3'd4; wc4 <= 3'd6; wc5 <= 4'd8; wc6 <= 3'd6; wc7 <= 3'd4; wc8 <= 3'd4; wc9 <= 4'd5; wc10 <= 4'd6; wc11 <= 4'd5; wc12 <= 3'd4; wc13 <= 4'd5; wc14 <= 3'd4; wc15 <= 3'd3; wc16 <= 3'd4; wc17 <= 3'd6; wc18 <= 4'd8; wc19 <= 3'd6; wc20 <= 4'd8; wc21 <= 4'd10; wc22 <= 4'd8; wc23 <= 3'd6; wc24 <= 3'd3; wc25 <= 3'd4; wc26 <= 4'd5; wc27 <= 3'd4; wc28 <= 3'd3; wc29 <= 3'd4; wc30 <= 3'd3; wc31 <= 2'd2; wc32 <= 2'd0; wc33 <= 3'd1; wc34 <= 3'd2; wc35 <= 3'd1; wc36 <= 3'd2; wc37 <= 4'd3; wc38 <= 3'd2; wc39 <= 3'd1; wc40 <= 3'd0; wc41 <= 4'd0; wc42 <= 4'd0; wc43 <= 4'd0; wc44 <= 3'd0; wc45 <= 4'd0; wc46 <= 3'd0; wc47 <= 3'd0; wc48 <= 3'd1; wc49 <= 3'd2; wc50 <= 4'd3; wc51 <= 3'd2; wc52 <= 4'd3; wc53 <= 4'd4; wc54 <= 4'd3; wc55 <= 3'd2; wc56 <= 3'd0; wc57 <= 3'd0; wc58 <= 4'd0; wc59 <= 3'd0; wc60 <= 3'd0; wc61 <= 3'd0; wc62 <= 3'd0; wc63 <= 2'd0; end
            {4'd4, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd0; wc17 <= 3'd0; wc18 <= 4'd0; wc19 <= 3'd0; wc20 <= 4'd0; wc21 <= 4'd0; wc22 <= 4'd0; wc23 <= 3'd0; wc24 <= 3'd0; wc25 <= 3'd0; wc26 <= 4'd0; wc27 <= 3'd0; wc28 <= 3'd0; wc29 <= 3'd0; wc30 <= 3'd0; wc31 <= 2'd0; wc32 <= 2'd2; wc33 <= 3'd4; wc34 <= 3'd6; wc35 <= 3'd4; wc36 <= 3'd6; wc37 <= 4'd8; wc38 <= 3'd6; wc39 <= 3'd4; wc40 <= 3'd6; wc41 <= 4'd8; wc42 <= 4'd10; wc43 <= 4'd8; wc44 <= 3'd6; wc45 <= 4'd8; wc46 <= 3'd6; wc47 <= 3'd4; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; end
            {4'd4, 1'b1}: begin wc0 <= 2'd2; wc1 <= 3'd4; wc2 <= 3'd6; wc3 <= 3'd4; wc4 <= 3'd6; wc5 <= 4'd8; wc6 <= 3'd6; wc7 <= 3'd4; wc8 <= 3'd6; wc9 <= 4'd8; wc10 <= 4'd10; wc11 <= 4'd8; wc12 <= 3'd6; wc13 <= 4'd8; wc14 <= 3'd6; wc15 <= 3'd4; wc16 <= 3'd3; wc17 <= 3'd4; wc18 <= 4'd5; wc19 <= 3'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 3'd4; wc24 <= 3'd3; wc25 <= 3'd4; wc26 <= 4'd5; wc27 <= 3'd4; wc28 <= 3'd3; wc29 <= 3'd4; wc30 <= 3'd3; wc31 <= 2'd2; wc32 <= 2'd0; wc33 <= 3'd1; wc34 <= 3'd2; wc35 <= 3'd1; wc36 <= 3'd2; wc37 <= 4'd3; wc38 <= 3'd2; wc39 <= 3'd1; wc40 <= 3'd2; wc41 <= 4'd3; wc42 <= 4'd4; wc43 <= 4'd3; wc44 <= 3'd2; wc45 <= 4'd3; wc46 <= 3'd2; wc47 <= 3'd1; wc48 <= 3'd0; wc49 <= 3'd0; wc50 <= 4'd0; wc51 <= 3'd0; wc52 <= 4'd0; wc53 <= 4'd0; wc54 <= 4'd0; wc55 <= 3'd0; wc56 <= 3'd0; wc57 <= 3'd0; wc58 <= 4'd0; wc59 <= 3'd0; wc60 <= 3'd0; wc61 <= 3'd0; wc62 <= 3'd0; wc63 <= 2'd0; end
            {4'd5, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 3'd3; wc18 <= 4'd4; wc19 <= 3'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 3'd3; wc24 <= 3'd2; wc25 <= 3'd3; wc26 <= 4'd4; wc27 <= 3'd3; wc28 <= 3'd2; wc29 <= 3'd3; wc30 <= 3'd2; wc31 <= 2'd1; wc32 <= 2'd1; wc33 <= 3'd2; wc34 <= 3'd3; wc35 <= 3'd2; wc36 <= 3'd3; wc37 <= 4'd4; wc38 <= 3'd3; wc39 <= 3'd2; wc40 <= 3'd3; wc41 <= 4'd4; wc42 <= 4'd5; wc43 <= 4'd4; wc44 <= 3'd3; wc45 <= 4'd4; wc46 <= 3'd3; wc47 <= 3'd2; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; end
            {4'd5, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 3'd4; wc18 <= 4'd5; wc19 <= 3'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 3'd4; wc24 <= 3'd3; wc25 <= 3'd4; wc26 <= 4'd5; wc27 <= 3'd4; wc28 <= 3'd3; wc29 <= 3'd4; wc30 <= 3'd3; wc31 <= 2'd2; wc32 <= 2'd0; wc33 <= 3'd1; wc34 <= 3'd2; wc35 <= 3'd1; wc36 <= 3'd2; wc37 <= 4'd3; wc38 <= 3'd2; wc39 <= 3'd1; wc40 <= 3'd2; wc41 <= 4'd3; wc42 <= 4'd4; wc43 <= 4'd3; wc44 <= 3'd2; wc45 <= 4'd3; wc46 <= 3'd2; wc47 <= 3'd1; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; end
            {4'd6, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 3'd3; wc18 <= 4'd4; wc19 <= 3'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 3'd3; wc24 <= 3'd2; wc25 <= 3'd3; wc26 <= 4'd4; wc27 <= 3'd3; wc28 <= 3'd2; wc29 <= 3'd3; wc30 <= 3'd2; wc31 <= 2'd1; wc32 <= 2'd1; wc33 <= 3'd2; wc34 <= 3'd3; wc35 <= 3'd2; wc36 <= 3'd3; wc37 <= 4'd4; wc38 <= 3'd3; wc39 <= 3'd2; wc40 <= 3'd3; wc41 <= 4'd4; wc42 <= 4'd5; wc43 <= 4'd4; wc44 <= 3'd3; wc45 <= 4'd4; wc46 <= 3'd3; wc47 <= 3'd2; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; end
            {4'd6, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 3'd4; wc18 <= 4'd5; wc19 <= 3'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 3'd4; wc24 <= 3'd3; wc25 <= 3'd4; wc26 <= 4'd5; wc27 <= 3'd4; wc28 <= 3'd3; wc29 <= 3'd4; wc30 <= 3'd3; wc31 <= 2'd2; wc32 <= 2'd0; wc33 <= 3'd1; wc34 <= 3'd2; wc35 <= 3'd1; wc36 <= 3'd2; wc37 <= 4'd3; wc38 <= 3'd2; wc39 <= 3'd1; wc40 <= 3'd2; wc41 <= 4'd3; wc42 <= 4'd4; wc43 <= 4'd3; wc44 <= 3'd2; wc45 <= 4'd3; wc46 <= 3'd2; wc47 <= 3'd1; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; end
            {4'd7, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 3'd3; wc18 <= 4'd4; wc19 <= 3'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 3'd3; wc24 <= 3'd2; wc25 <= 3'd3; wc26 <= 4'd4; wc27 <= 3'd3; wc28 <= 3'd2; wc29 <= 3'd3; wc30 <= 3'd2; wc31 <= 2'd1; wc32 <= 2'd1; wc33 <= 3'd2; wc34 <= 3'd3; wc35 <= 3'd2; wc36 <= 3'd3; wc37 <= 4'd4; wc38 <= 3'd3; wc39 <= 3'd2; wc40 <= 3'd3; wc41 <= 4'd4; wc42 <= 4'd5; wc43 <= 4'd4; wc44 <= 3'd3; wc45 <= 4'd4; wc46 <= 3'd3; wc47 <= 3'd2; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; end
            {4'd7, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 3'd4; wc18 <= 4'd5; wc19 <= 3'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 3'd4; wc24 <= 3'd3; wc25 <= 3'd4; wc26 <= 4'd5; wc27 <= 3'd4; wc28 <= 3'd3; wc29 <= 3'd4; wc30 <= 3'd3; wc31 <= 2'd2; wc32 <= 2'd0; wc33 <= 3'd1; wc34 <= 3'd2; wc35 <= 3'd1; wc36 <= 3'd2; wc37 <= 4'd3; wc38 <= 3'd2; wc39 <= 3'd1; wc40 <= 3'd2; wc41 <= 4'd3; wc42 <= 4'd4; wc43 <= 4'd3; wc44 <= 3'd2; wc45 <= 4'd3; wc46 <= 3'd2; wc47 <= 3'd1; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; end
            {4'd8, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 3'd3; wc18 <= 4'd4; wc19 <= 3'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 3'd3; wc24 <= 3'd2; wc25 <= 3'd3; wc26 <= 4'd4; wc27 <= 3'd3; wc28 <= 3'd2; wc29 <= 3'd3; wc30 <= 3'd2; wc31 <= 2'd1; wc32 <= 2'd1; wc33 <= 3'd2; wc34 <= 3'd3; wc35 <= 3'd2; wc36 <= 3'd3; wc37 <= 4'd4; wc38 <= 3'd3; wc39 <= 3'd2; wc40 <= 3'd3; wc41 <= 4'd4; wc42 <= 4'd5; wc43 <= 4'd4; wc44 <= 3'd3; wc45 <= 4'd4; wc46 <= 3'd3; wc47 <= 3'd2; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; end
            {4'd8, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 3'd4; wc18 <= 4'd5; wc19 <= 3'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 3'd4; wc24 <= 3'd3; wc25 <= 3'd4; wc26 <= 4'd5; wc27 <= 3'd4; wc28 <= 3'd3; wc29 <= 3'd4; wc30 <= 3'd3; wc31 <= 2'd2; wc32 <= 2'd0; wc33 <= 3'd1; wc34 <= 3'd2; wc35 <= 3'd1; wc36 <= 3'd2; wc37 <= 4'd3; wc38 <= 3'd2; wc39 <= 3'd1; wc40 <= 3'd2; wc41 <= 4'd3; wc42 <= 4'd4; wc43 <= 4'd3; wc44 <= 3'd2; wc45 <= 4'd3; wc46 <= 3'd2; wc47 <= 3'd1; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; end
            {4'd9, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 3'd3; wc18 <= 4'd4; wc19 <= 3'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 3'd3; wc24 <= 3'd2; wc25 <= 3'd3; wc26 <= 4'd4; wc27 <= 3'd3; wc28 <= 3'd2; wc29 <= 3'd3; wc30 <= 3'd2; wc31 <= 2'd1; wc32 <= 2'd1; wc33 <= 3'd2; wc34 <= 3'd3; wc35 <= 3'd2; wc36 <= 3'd3; wc37 <= 4'd4; wc38 <= 3'd3; wc39 <= 3'd2; wc40 <= 3'd3; wc41 <= 4'd4; wc42 <= 4'd5; wc43 <= 4'd4; wc44 <= 3'd3; wc45 <= 4'd4; wc46 <= 3'd3; wc47 <= 3'd2; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; end
            {4'd9, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 3'd4; wc18 <= 4'd5; wc19 <= 3'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 3'd4; wc24 <= 3'd3; wc25 <= 3'd4; wc26 <= 4'd5; wc27 <= 3'd4; wc28 <= 3'd3; wc29 <= 3'd4; wc30 <= 3'd3; wc31 <= 2'd2; wc32 <= 2'd0; wc33 <= 3'd1; wc34 <= 3'd2; wc35 <= 3'd1; wc36 <= 3'd2; wc37 <= 4'd3; wc38 <= 3'd2; wc39 <= 3'd1; wc40 <= 3'd2; wc41 <= 4'd3; wc42 <= 4'd4; wc43 <= 4'd3; wc44 <= 3'd2; wc45 <= 4'd3; wc46 <= 3'd2; wc47 <= 3'd1; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; end
            {4'd10, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 3'd3; wc18 <= 4'd4; wc19 <= 3'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 3'd3; wc24 <= 3'd2; wc25 <= 3'd3; wc26 <= 4'd4; wc27 <= 3'd3; wc28 <= 3'd2; wc29 <= 3'd3; wc30 <= 3'd2; wc31 <= 2'd1; wc32 <= 2'd1; wc33 <= 3'd2; wc34 <= 3'd3; wc35 <= 3'd2; wc36 <= 3'd3; wc37 <= 4'd4; wc38 <= 3'd3; wc39 <= 3'd2; wc40 <= 3'd3; wc41 <= 4'd4; wc42 <= 4'd5; wc43 <= 4'd4; wc44 <= 3'd3; wc45 <= 4'd4; wc46 <= 3'd3; wc47 <= 3'd2; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; end
            {4'd10, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 3'd4; wc18 <= 4'd5; wc19 <= 3'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 3'd4; wc24 <= 3'd3; wc25 <= 3'd4; wc26 <= 4'd5; wc27 <= 3'd4; wc28 <= 3'd3; wc29 <= 3'd4; wc30 <= 3'd3; wc31 <= 2'd2; wc32 <= 2'd0; wc33 <= 3'd1; wc34 <= 3'd2; wc35 <= 3'd1; wc36 <= 3'd2; wc37 <= 4'd3; wc38 <= 3'd2; wc39 <= 3'd1; wc40 <= 3'd2; wc41 <= 4'd3; wc42 <= 4'd4; wc43 <= 4'd3; wc44 <= 3'd2; wc45 <= 4'd3; wc46 <= 3'd2; wc47 <= 3'd1; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; end
            {4'd11, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 3'd3; wc18 <= 4'd4; wc19 <= 3'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 3'd3; wc24 <= 3'd2; wc25 <= 3'd3; wc26 <= 4'd4; wc27 <= 3'd3; wc28 <= 3'd2; wc29 <= 3'd3; wc30 <= 3'd2; wc31 <= 2'd1; wc32 <= 2'd1; wc33 <= 3'd2; wc34 <= 3'd3; wc35 <= 3'd2; wc36 <= 3'd3; wc37 <= 4'd4; wc38 <= 3'd3; wc39 <= 3'd2; wc40 <= 3'd3; wc41 <= 4'd4; wc42 <= 4'd5; wc43 <= 4'd4; wc44 <= 3'd3; wc45 <= 4'd4; wc46 <= 3'd3; wc47 <= 3'd2; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; end
            {4'd11, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 3'd4; wc18 <= 4'd5; wc19 <= 3'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 3'd4; wc24 <= 3'd3; wc25 <= 3'd4; wc26 <= 4'd5; wc27 <= 3'd4; wc28 <= 3'd3; wc29 <= 3'd4; wc30 <= 3'd3; wc31 <= 2'd2; wc32 <= 2'd0; wc33 <= 3'd1; wc34 <= 3'd2; wc35 <= 3'd1; wc36 <= 3'd2; wc37 <= 4'd3; wc38 <= 3'd2; wc39 <= 3'd1; wc40 <= 3'd2; wc41 <= 4'd3; wc42 <= 4'd4; wc43 <= 4'd3; wc44 <= 3'd2; wc45 <= 4'd3; wc46 <= 3'd2; wc47 <= 3'd1; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; end
            {4'd12, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 3'd3; wc18 <= 4'd4; wc19 <= 3'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 3'd3; wc24 <= 3'd2; wc25 <= 3'd3; wc26 <= 4'd4; wc27 <= 3'd3; wc28 <= 3'd2; wc29 <= 3'd3; wc30 <= 3'd2; wc31 <= 2'd1; wc32 <= 2'd1; wc33 <= 3'd2; wc34 <= 3'd3; wc35 <= 3'd2; wc36 <= 3'd3; wc37 <= 4'd4; wc38 <= 3'd3; wc39 <= 3'd2; wc40 <= 3'd3; wc41 <= 4'd4; wc42 <= 4'd5; wc43 <= 4'd4; wc44 <= 3'd3; wc45 <= 4'd4; wc46 <= 3'd3; wc47 <= 3'd2; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; end
            {4'd12, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 3'd4; wc18 <= 4'd5; wc19 <= 3'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 3'd4; wc24 <= 3'd3; wc25 <= 3'd4; wc26 <= 4'd5; wc27 <= 3'd4; wc28 <= 3'd3; wc29 <= 3'd4; wc30 <= 3'd3; wc31 <= 2'd2; wc32 <= 2'd0; wc33 <= 3'd1; wc34 <= 3'd2; wc35 <= 3'd1; wc36 <= 3'd2; wc37 <= 4'd3; wc38 <= 3'd2; wc39 <= 3'd1; wc40 <= 3'd2; wc41 <= 4'd3; wc42 <= 4'd4; wc43 <= 4'd3; wc44 <= 3'd2; wc45 <= 4'd3; wc46 <= 3'd2; wc47 <= 3'd1; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; end
            {4'd13, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 3'd3; wc18 <= 4'd4; wc19 <= 3'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 3'd3; wc24 <= 3'd2; wc25 <= 3'd3; wc26 <= 4'd4; wc27 <= 3'd3; wc28 <= 3'd2; wc29 <= 3'd3; wc30 <= 3'd2; wc31 <= 2'd1; wc32 <= 2'd1; wc33 <= 3'd2; wc34 <= 3'd3; wc35 <= 3'd2; wc36 <= 3'd3; wc37 <= 4'd4; wc38 <= 3'd3; wc39 <= 3'd2; wc40 <= 3'd3; wc41 <= 4'd4; wc42 <= 4'd5; wc43 <= 4'd4; wc44 <= 3'd3; wc45 <= 4'd4; wc46 <= 3'd3; wc47 <= 3'd2; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; end
            {4'd13, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 3'd4; wc18 <= 4'd5; wc19 <= 3'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 3'd4; wc24 <= 3'd3; wc25 <= 3'd4; wc26 <= 4'd5; wc27 <= 3'd4; wc28 <= 3'd3; wc29 <= 3'd4; wc30 <= 3'd3; wc31 <= 2'd2; wc32 <= 2'd0; wc33 <= 3'd1; wc34 <= 3'd2; wc35 <= 3'd1; wc36 <= 3'd2; wc37 <= 4'd3; wc38 <= 3'd2; wc39 <= 3'd1; wc40 <= 3'd2; wc41 <= 4'd3; wc42 <= 4'd4; wc43 <= 4'd3; wc44 <= 3'd2; wc45 <= 4'd3; wc46 <= 3'd2; wc47 <= 3'd1; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; end
            {4'd14, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 3'd3; wc18 <= 4'd4; wc19 <= 3'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 3'd3; wc24 <= 3'd2; wc25 <= 3'd3; wc26 <= 4'd4; wc27 <= 3'd3; wc28 <= 3'd2; wc29 <= 3'd3; wc30 <= 3'd2; wc31 <= 2'd1; wc32 <= 2'd1; wc33 <= 3'd2; wc34 <= 3'd3; wc35 <= 3'd2; wc36 <= 3'd3; wc37 <= 4'd4; wc38 <= 3'd3; wc39 <= 3'd2; wc40 <= 3'd3; wc41 <= 4'd4; wc42 <= 4'd5; wc43 <= 4'd4; wc44 <= 3'd3; wc45 <= 4'd4; wc46 <= 3'd3; wc47 <= 3'd2; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; end
            {4'd14, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 3'd4; wc18 <= 4'd5; wc19 <= 3'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 3'd4; wc24 <= 3'd3; wc25 <= 3'd4; wc26 <= 4'd5; wc27 <= 3'd4; wc28 <= 3'd3; wc29 <= 3'd4; wc30 <= 3'd3; wc31 <= 2'd2; wc32 <= 2'd0; wc33 <= 3'd1; wc34 <= 3'd2; wc35 <= 3'd1; wc36 <= 3'd2; wc37 <= 4'd3; wc38 <= 3'd2; wc39 <= 3'd1; wc40 <= 3'd2; wc41 <= 4'd3; wc42 <= 4'd4; wc43 <= 4'd3; wc44 <= 3'd2; wc45 <= 4'd3; wc46 <= 3'd2; wc47 <= 3'd1; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; end
            {4'd15, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 3'd3; wc18 <= 4'd4; wc19 <= 3'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 3'd3; wc24 <= 3'd2; wc25 <= 3'd3; wc26 <= 4'd4; wc27 <= 3'd3; wc28 <= 3'd2; wc29 <= 3'd3; wc30 <= 3'd2; wc31 <= 2'd1; wc32 <= 2'd1; wc33 <= 3'd2; wc34 <= 3'd3; wc35 <= 3'd2; wc36 <= 3'd3; wc37 <= 4'd4; wc38 <= 3'd3; wc39 <= 3'd2; wc40 <= 3'd3; wc41 <= 4'd4; wc42 <= 4'd5; wc43 <= 4'd4; wc44 <= 3'd3; wc45 <= 4'd4; wc46 <= 3'd3; wc47 <= 3'd2; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; end
            {4'd15, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 3'd4; wc18 <= 4'd5; wc19 <= 3'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 3'd4; wc24 <= 3'd3; wc25 <= 3'd4; wc26 <= 4'd5; wc27 <= 3'd4; wc28 <= 3'd3; wc29 <= 3'd4; wc30 <= 3'd3; wc31 <= 2'd2; wc32 <= 2'd0; wc33 <= 3'd1; wc34 <= 3'd2; wc35 <= 3'd1; wc36 <= 3'd2; wc37 <= 4'd3; wc38 <= 3'd2; wc39 <= 3'd1; wc40 <= 3'd2; wc41 <= 4'd3; wc42 <= 4'd4; wc43 <= 4'd3; wc44 <= 3'd2; wc45 <= 4'd3; wc46 <= 3'd2; wc47 <= 3'd1; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; end
            default: ;
        endcase
    end
    // ---- data banks: 2 sets x 2B banks (bank of m: (m mod 2B) ^ (parity(m >> (b+1)) << b), address m >> (b+1))
    logic m0_0_we; logic [9:0] m0_0_wa, m0_0_ra; logic [51:0] m0_0_wd, m0_0_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_0 (.clk(clk), .we(m0_0_we), .wa(m0_0_wa), .wd(m0_0_wd), .ra(m0_0_ra), .rd(m0_0_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_0_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_0_ra <= drow;
    logic m0_1_we; logic [9:0] m0_1_wa, m0_1_ra; logic [51:0] m0_1_wd, m0_1_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_1 (.clk(clk), .we(m0_1_we), .wa(m0_1_wa), .wd(m0_1_wd), .ra(m0_1_ra), .rd(m0_1_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_1_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_1_ra <= drow;
    logic m0_2_we; logic [9:0] m0_2_wa, m0_2_ra; logic [51:0] m0_2_wd, m0_2_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_2 (.clk(clk), .we(m0_2_we), .wa(m0_2_wa), .wd(m0_2_wd), .ra(m0_2_ra), .rd(m0_2_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_2_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_2_ra <= drow;
    logic m0_3_we; logic [9:0] m0_3_wa, m0_3_ra; logic [51:0] m0_3_wd, m0_3_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_3 (.clk(clk), .we(m0_3_we), .wa(m0_3_wa), .wd(m0_3_wd), .ra(m0_3_ra), .rd(m0_3_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_3_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_3_ra <= drow;
    logic m0_4_we; logic [9:0] m0_4_wa, m0_4_ra; logic [51:0] m0_4_wd, m0_4_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_4 (.clk(clk), .we(m0_4_we), .wa(m0_4_wa), .wd(m0_4_wd), .ra(m0_4_ra), .rd(m0_4_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_4_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_4_ra <= drow;
    logic m0_5_we; logic [9:0] m0_5_wa, m0_5_ra; logic [51:0] m0_5_wd, m0_5_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_5 (.clk(clk), .we(m0_5_we), .wa(m0_5_wa), .wd(m0_5_wd), .ra(m0_5_ra), .rd(m0_5_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_5_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_5_ra <= drow;
    logic m0_6_we; logic [9:0] m0_6_wa, m0_6_ra; logic [51:0] m0_6_wd, m0_6_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_6 (.clk(clk), .we(m0_6_we), .wa(m0_6_wa), .wd(m0_6_wd), .ra(m0_6_ra), .rd(m0_6_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_6_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_6_ra <= drow;
    logic m0_7_we; logic [9:0] m0_7_wa, m0_7_ra; logic [51:0] m0_7_wd, m0_7_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_7 (.clk(clk), .we(m0_7_we), .wa(m0_7_wa), .wd(m0_7_wd), .ra(m0_7_ra), .rd(m0_7_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_7_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_7_ra <= drow;
    logic m0_8_we; logic [9:0] m0_8_wa, m0_8_ra; logic [51:0] m0_8_wd, m0_8_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_8 (.clk(clk), .we(m0_8_we), .wa(m0_8_wa), .wd(m0_8_wd), .ra(m0_8_ra), .rd(m0_8_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_8_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_8_ra <= drow;
    logic m0_9_we; logic [9:0] m0_9_wa, m0_9_ra; logic [51:0] m0_9_wd, m0_9_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_9 (.clk(clk), .we(m0_9_we), .wa(m0_9_wa), .wd(m0_9_wd), .ra(m0_9_ra), .rd(m0_9_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_9_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_9_ra <= drow;
    logic m0_10_we; logic [9:0] m0_10_wa, m0_10_ra; logic [51:0] m0_10_wd, m0_10_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_10 (.clk(clk), .we(m0_10_we), .wa(m0_10_wa), .wd(m0_10_wd), .ra(m0_10_ra), .rd(m0_10_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_10_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_10_ra <= drow;
    logic m0_11_we; logic [9:0] m0_11_wa, m0_11_ra; logic [51:0] m0_11_wd, m0_11_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_11 (.clk(clk), .we(m0_11_we), .wa(m0_11_wa), .wd(m0_11_wd), .ra(m0_11_ra), .rd(m0_11_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_11_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_11_ra <= drow;
    logic m0_12_we; logic [9:0] m0_12_wa, m0_12_ra; logic [51:0] m0_12_wd, m0_12_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_12 (.clk(clk), .we(m0_12_we), .wa(m0_12_wa), .wd(m0_12_wd), .ra(m0_12_ra), .rd(m0_12_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_12_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_12_ra <= drow;
    logic m0_13_we; logic [9:0] m0_13_wa, m0_13_ra; logic [51:0] m0_13_wd, m0_13_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_13 (.clk(clk), .we(m0_13_we), .wa(m0_13_wa), .wd(m0_13_wd), .ra(m0_13_ra), .rd(m0_13_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_13_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_13_ra <= drow;
    logic m0_14_we; logic [9:0] m0_14_wa, m0_14_ra; logic [51:0] m0_14_wd, m0_14_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_14 (.clk(clk), .we(m0_14_we), .wa(m0_14_wa), .wd(m0_14_wd), .ra(m0_14_ra), .rd(m0_14_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_14_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_14_ra <= drow;
    logic m0_15_we; logic [9:0] m0_15_wa, m0_15_ra; logic [51:0] m0_15_wd, m0_15_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_15 (.clk(clk), .we(m0_15_we), .wa(m0_15_wa), .wd(m0_15_wd), .ra(m0_15_ra), .rd(m0_15_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_15_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_15_ra <= drow;
    logic m0_16_we; logic [9:0] m0_16_wa, m0_16_ra; logic [51:0] m0_16_wd, m0_16_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_16 (.clk(clk), .we(m0_16_we), .wa(m0_16_wa), .wd(m0_16_wd), .ra(m0_16_ra), .rd(m0_16_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_16_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_16_ra <= drow;
    logic m0_17_we; logic [9:0] m0_17_wa, m0_17_ra; logic [51:0] m0_17_wd, m0_17_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_17 (.clk(clk), .we(m0_17_we), .wa(m0_17_wa), .wd(m0_17_wd), .ra(m0_17_ra), .rd(m0_17_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_17_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_17_ra <= drow;
    logic m0_18_we; logic [9:0] m0_18_wa, m0_18_ra; logic [51:0] m0_18_wd, m0_18_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_18 (.clk(clk), .we(m0_18_we), .wa(m0_18_wa), .wd(m0_18_wd), .ra(m0_18_ra), .rd(m0_18_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_18_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_18_ra <= drow;
    logic m0_19_we; logic [9:0] m0_19_wa, m0_19_ra; logic [51:0] m0_19_wd, m0_19_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_19 (.clk(clk), .we(m0_19_we), .wa(m0_19_wa), .wd(m0_19_wd), .ra(m0_19_ra), .rd(m0_19_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_19_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_19_ra <= drow;
    logic m0_20_we; logic [9:0] m0_20_wa, m0_20_ra; logic [51:0] m0_20_wd, m0_20_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_20 (.clk(clk), .we(m0_20_we), .wa(m0_20_wa), .wd(m0_20_wd), .ra(m0_20_ra), .rd(m0_20_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_20_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_20_ra <= drow;
    logic m0_21_we; logic [9:0] m0_21_wa, m0_21_ra; logic [51:0] m0_21_wd, m0_21_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_21 (.clk(clk), .we(m0_21_we), .wa(m0_21_wa), .wd(m0_21_wd), .ra(m0_21_ra), .rd(m0_21_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_21_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_21_ra <= drow;
    logic m0_22_we; logic [9:0] m0_22_wa, m0_22_ra; logic [51:0] m0_22_wd, m0_22_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_22 (.clk(clk), .we(m0_22_we), .wa(m0_22_wa), .wd(m0_22_wd), .ra(m0_22_ra), .rd(m0_22_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_22_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_22_ra <= drow;
    logic m0_23_we; logic [9:0] m0_23_wa, m0_23_ra; logic [51:0] m0_23_wd, m0_23_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_23 (.clk(clk), .we(m0_23_we), .wa(m0_23_wa), .wd(m0_23_wd), .ra(m0_23_ra), .rd(m0_23_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_23_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_23_ra <= drow;
    logic m0_24_we; logic [9:0] m0_24_wa, m0_24_ra; logic [51:0] m0_24_wd, m0_24_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_24 (.clk(clk), .we(m0_24_we), .wa(m0_24_wa), .wd(m0_24_wd), .ra(m0_24_ra), .rd(m0_24_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_24_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_24_ra <= drow;
    logic m0_25_we; logic [9:0] m0_25_wa, m0_25_ra; logic [51:0] m0_25_wd, m0_25_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_25 (.clk(clk), .we(m0_25_we), .wa(m0_25_wa), .wd(m0_25_wd), .ra(m0_25_ra), .rd(m0_25_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_25_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_25_ra <= drow;
    logic m0_26_we; logic [9:0] m0_26_wa, m0_26_ra; logic [51:0] m0_26_wd, m0_26_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_26 (.clk(clk), .we(m0_26_we), .wa(m0_26_wa), .wd(m0_26_wd), .ra(m0_26_ra), .rd(m0_26_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_26_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_26_ra <= drow;
    logic m0_27_we; logic [9:0] m0_27_wa, m0_27_ra; logic [51:0] m0_27_wd, m0_27_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_27 (.clk(clk), .we(m0_27_we), .wa(m0_27_wa), .wd(m0_27_wd), .ra(m0_27_ra), .rd(m0_27_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_27_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_27_ra <= drow;
    logic m0_28_we; logic [9:0] m0_28_wa, m0_28_ra; logic [51:0] m0_28_wd, m0_28_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_28 (.clk(clk), .we(m0_28_we), .wa(m0_28_wa), .wd(m0_28_wd), .ra(m0_28_ra), .rd(m0_28_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_28_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_28_ra <= drow;
    logic m0_29_we; logic [9:0] m0_29_wa, m0_29_ra; logic [51:0] m0_29_wd, m0_29_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_29 (.clk(clk), .we(m0_29_we), .wa(m0_29_wa), .wd(m0_29_wd), .ra(m0_29_ra), .rd(m0_29_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_29_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_29_ra <= drow;
    logic m0_30_we; logic [9:0] m0_30_wa, m0_30_ra; logic [51:0] m0_30_wd, m0_30_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_30 (.clk(clk), .we(m0_30_we), .wa(m0_30_wa), .wd(m0_30_wd), .ra(m0_30_ra), .rd(m0_30_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_30_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_30_ra <= drow;
    logic m0_31_we; logic [9:0] m0_31_wa, m0_31_ra; logic [51:0] m0_31_wd, m0_31_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_31 (.clk(clk), .we(m0_31_we), .wa(m0_31_wa), .wd(m0_31_wd), .ra(m0_31_ra), .rd(m0_31_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_31_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_31_ra <= drow;
    logic m0_32_we; logic [9:0] m0_32_wa, m0_32_ra; logic [51:0] m0_32_wd, m0_32_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_32 (.clk(clk), .we(m0_32_we), .wa(m0_32_wa), .wd(m0_32_wd), .ra(m0_32_ra), .rd(m0_32_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_32_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_32_ra <= drow;
    logic m0_33_we; logic [9:0] m0_33_wa, m0_33_ra; logic [51:0] m0_33_wd, m0_33_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_33 (.clk(clk), .we(m0_33_we), .wa(m0_33_wa), .wd(m0_33_wd), .ra(m0_33_ra), .rd(m0_33_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_33_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_33_ra <= drow;
    logic m0_34_we; logic [9:0] m0_34_wa, m0_34_ra; logic [51:0] m0_34_wd, m0_34_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_34 (.clk(clk), .we(m0_34_we), .wa(m0_34_wa), .wd(m0_34_wd), .ra(m0_34_ra), .rd(m0_34_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_34_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_34_ra <= drow;
    logic m0_35_we; logic [9:0] m0_35_wa, m0_35_ra; logic [51:0] m0_35_wd, m0_35_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_35 (.clk(clk), .we(m0_35_we), .wa(m0_35_wa), .wd(m0_35_wd), .ra(m0_35_ra), .rd(m0_35_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_35_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_35_ra <= drow;
    logic m0_36_we; logic [9:0] m0_36_wa, m0_36_ra; logic [51:0] m0_36_wd, m0_36_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_36 (.clk(clk), .we(m0_36_we), .wa(m0_36_wa), .wd(m0_36_wd), .ra(m0_36_ra), .rd(m0_36_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_36_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_36_ra <= drow;
    logic m0_37_we; logic [9:0] m0_37_wa, m0_37_ra; logic [51:0] m0_37_wd, m0_37_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_37 (.clk(clk), .we(m0_37_we), .wa(m0_37_wa), .wd(m0_37_wd), .ra(m0_37_ra), .rd(m0_37_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_37_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_37_ra <= drow;
    logic m0_38_we; logic [9:0] m0_38_wa, m0_38_ra; logic [51:0] m0_38_wd, m0_38_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_38 (.clk(clk), .we(m0_38_we), .wa(m0_38_wa), .wd(m0_38_wd), .ra(m0_38_ra), .rd(m0_38_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_38_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_38_ra <= drow;
    logic m0_39_we; logic [9:0] m0_39_wa, m0_39_ra; logic [51:0] m0_39_wd, m0_39_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_39 (.clk(clk), .we(m0_39_we), .wa(m0_39_wa), .wd(m0_39_wd), .ra(m0_39_ra), .rd(m0_39_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_39_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_39_ra <= drow;
    logic m0_40_we; logic [9:0] m0_40_wa, m0_40_ra; logic [51:0] m0_40_wd, m0_40_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_40 (.clk(clk), .we(m0_40_we), .wa(m0_40_wa), .wd(m0_40_wd), .ra(m0_40_ra), .rd(m0_40_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_40_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_40_ra <= drow;
    logic m0_41_we; logic [9:0] m0_41_wa, m0_41_ra; logic [51:0] m0_41_wd, m0_41_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_41 (.clk(clk), .we(m0_41_we), .wa(m0_41_wa), .wd(m0_41_wd), .ra(m0_41_ra), .rd(m0_41_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_41_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_41_ra <= drow;
    logic m0_42_we; logic [9:0] m0_42_wa, m0_42_ra; logic [51:0] m0_42_wd, m0_42_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_42 (.clk(clk), .we(m0_42_we), .wa(m0_42_wa), .wd(m0_42_wd), .ra(m0_42_ra), .rd(m0_42_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_42_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_42_ra <= drow;
    logic m0_43_we; logic [9:0] m0_43_wa, m0_43_ra; logic [51:0] m0_43_wd, m0_43_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_43 (.clk(clk), .we(m0_43_we), .wa(m0_43_wa), .wd(m0_43_wd), .ra(m0_43_ra), .rd(m0_43_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_43_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_43_ra <= drow;
    logic m0_44_we; logic [9:0] m0_44_wa, m0_44_ra; logic [51:0] m0_44_wd, m0_44_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_44 (.clk(clk), .we(m0_44_we), .wa(m0_44_wa), .wd(m0_44_wd), .ra(m0_44_ra), .rd(m0_44_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_44_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_44_ra <= drow;
    logic m0_45_we; logic [9:0] m0_45_wa, m0_45_ra; logic [51:0] m0_45_wd, m0_45_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_45 (.clk(clk), .we(m0_45_we), .wa(m0_45_wa), .wd(m0_45_wd), .ra(m0_45_ra), .rd(m0_45_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_45_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_45_ra <= drow;
    logic m0_46_we; logic [9:0] m0_46_wa, m0_46_ra; logic [51:0] m0_46_wd, m0_46_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_46 (.clk(clk), .we(m0_46_we), .wa(m0_46_wa), .wd(m0_46_wd), .ra(m0_46_ra), .rd(m0_46_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_46_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_46_ra <= drow;
    logic m0_47_we; logic [9:0] m0_47_wa, m0_47_ra; logic [51:0] m0_47_wd, m0_47_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_47 (.clk(clk), .we(m0_47_we), .wa(m0_47_wa), .wd(m0_47_wd), .ra(m0_47_ra), .rd(m0_47_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_47_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_47_ra <= drow;
    logic m0_48_we; logic [9:0] m0_48_wa, m0_48_ra; logic [51:0] m0_48_wd, m0_48_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_48 (.clk(clk), .we(m0_48_we), .wa(m0_48_wa), .wd(m0_48_wd), .ra(m0_48_ra), .rd(m0_48_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_48_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_48_ra <= drow;
    logic m0_49_we; logic [9:0] m0_49_wa, m0_49_ra; logic [51:0] m0_49_wd, m0_49_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_49 (.clk(clk), .we(m0_49_we), .wa(m0_49_wa), .wd(m0_49_wd), .ra(m0_49_ra), .rd(m0_49_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_49_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_49_ra <= drow;
    logic m0_50_we; logic [9:0] m0_50_wa, m0_50_ra; logic [51:0] m0_50_wd, m0_50_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_50 (.clk(clk), .we(m0_50_we), .wa(m0_50_wa), .wd(m0_50_wd), .ra(m0_50_ra), .rd(m0_50_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_50_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_50_ra <= drow;
    logic m0_51_we; logic [9:0] m0_51_wa, m0_51_ra; logic [51:0] m0_51_wd, m0_51_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_51 (.clk(clk), .we(m0_51_we), .wa(m0_51_wa), .wd(m0_51_wd), .ra(m0_51_ra), .rd(m0_51_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_51_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_51_ra <= drow;
    logic m0_52_we; logic [9:0] m0_52_wa, m0_52_ra; logic [51:0] m0_52_wd, m0_52_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_52 (.clk(clk), .we(m0_52_we), .wa(m0_52_wa), .wd(m0_52_wd), .ra(m0_52_ra), .rd(m0_52_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_52_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_52_ra <= drow;
    logic m0_53_we; logic [9:0] m0_53_wa, m0_53_ra; logic [51:0] m0_53_wd, m0_53_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_53 (.clk(clk), .we(m0_53_we), .wa(m0_53_wa), .wd(m0_53_wd), .ra(m0_53_ra), .rd(m0_53_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_53_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_53_ra <= drow;
    logic m0_54_we; logic [9:0] m0_54_wa, m0_54_ra; logic [51:0] m0_54_wd, m0_54_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_54 (.clk(clk), .we(m0_54_we), .wa(m0_54_wa), .wd(m0_54_wd), .ra(m0_54_ra), .rd(m0_54_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_54_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_54_ra <= drow;
    logic m0_55_we; logic [9:0] m0_55_wa, m0_55_ra; logic [51:0] m0_55_wd, m0_55_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_55 (.clk(clk), .we(m0_55_we), .wa(m0_55_wa), .wd(m0_55_wd), .ra(m0_55_ra), .rd(m0_55_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_55_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_55_ra <= drow;
    logic m0_56_we; logic [9:0] m0_56_wa, m0_56_ra; logic [51:0] m0_56_wd, m0_56_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_56 (.clk(clk), .we(m0_56_we), .wa(m0_56_wa), .wd(m0_56_wd), .ra(m0_56_ra), .rd(m0_56_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_56_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_56_ra <= drow;
    logic m0_57_we; logic [9:0] m0_57_wa, m0_57_ra; logic [51:0] m0_57_wd, m0_57_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_57 (.clk(clk), .we(m0_57_we), .wa(m0_57_wa), .wd(m0_57_wd), .ra(m0_57_ra), .rd(m0_57_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_57_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_57_ra <= drow;
    logic m0_58_we; logic [9:0] m0_58_wa, m0_58_ra; logic [51:0] m0_58_wd, m0_58_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_58 (.clk(clk), .we(m0_58_we), .wa(m0_58_wa), .wd(m0_58_wd), .ra(m0_58_ra), .rd(m0_58_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_58_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_58_ra <= drow;
    logic m0_59_we; logic [9:0] m0_59_wa, m0_59_ra; logic [51:0] m0_59_wd, m0_59_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_59 (.clk(clk), .we(m0_59_we), .wa(m0_59_wa), .wd(m0_59_wd), .ra(m0_59_ra), .rd(m0_59_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_59_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_59_ra <= drow;
    logic m0_60_we; logic [9:0] m0_60_wa, m0_60_ra; logic [51:0] m0_60_wd, m0_60_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_60 (.clk(clk), .we(m0_60_we), .wa(m0_60_wa), .wd(m0_60_wd), .ra(m0_60_ra), .rd(m0_60_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_60_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_60_ra <= drow;
    logic m0_61_we; logic [9:0] m0_61_wa, m0_61_ra; logic [51:0] m0_61_wd, m0_61_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_61 (.clk(clk), .we(m0_61_we), .wa(m0_61_wa), .wd(m0_61_wd), .ra(m0_61_ra), .rd(m0_61_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_61_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_61_ra <= drow;
    logic m0_62_we; logic [9:0] m0_62_wa, m0_62_ra; logic [51:0] m0_62_wd, m0_62_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_62 (.clk(clk), .we(m0_62_we), .wa(m0_62_wa), .wd(m0_62_wd), .ra(m0_62_ra), .rd(m0_62_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_62_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_62_ra <= drow;
    logic m0_63_we; logic [9:0] m0_63_wa, m0_63_ra; logic [51:0] m0_63_wd, m0_63_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m0_63 (.clk(clk), .we(m0_63_we), .wa(m0_63_wa), .wd(m0_63_wd), .ra(m0_63_ra), .rd(m0_63_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_63_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_63_ra <= drow;
    logic m1_0_we; logic [9:0] m1_0_wa, m1_0_ra; logic [51:0] m1_0_wd, m1_0_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_0 (.clk(clk), .we(m1_0_we), .wa(m1_0_wa), .wd(m1_0_wd), .ra(m1_0_ra), .rd(m1_0_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_0_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_0_ra <= drow;
    logic m1_1_we; logic [9:0] m1_1_wa, m1_1_ra; logic [51:0] m1_1_wd, m1_1_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_1 (.clk(clk), .we(m1_1_we), .wa(m1_1_wa), .wd(m1_1_wd), .ra(m1_1_ra), .rd(m1_1_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_1_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_1_ra <= drow;
    logic m1_2_we; logic [9:0] m1_2_wa, m1_2_ra; logic [51:0] m1_2_wd, m1_2_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_2 (.clk(clk), .we(m1_2_we), .wa(m1_2_wa), .wd(m1_2_wd), .ra(m1_2_ra), .rd(m1_2_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_2_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_2_ra <= drow;
    logic m1_3_we; logic [9:0] m1_3_wa, m1_3_ra; logic [51:0] m1_3_wd, m1_3_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_3 (.clk(clk), .we(m1_3_we), .wa(m1_3_wa), .wd(m1_3_wd), .ra(m1_3_ra), .rd(m1_3_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_3_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_3_ra <= drow;
    logic m1_4_we; logic [9:0] m1_4_wa, m1_4_ra; logic [51:0] m1_4_wd, m1_4_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_4 (.clk(clk), .we(m1_4_we), .wa(m1_4_wa), .wd(m1_4_wd), .ra(m1_4_ra), .rd(m1_4_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_4_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_4_ra <= drow;
    logic m1_5_we; logic [9:0] m1_5_wa, m1_5_ra; logic [51:0] m1_5_wd, m1_5_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_5 (.clk(clk), .we(m1_5_we), .wa(m1_5_wa), .wd(m1_5_wd), .ra(m1_5_ra), .rd(m1_5_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_5_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_5_ra <= drow;
    logic m1_6_we; logic [9:0] m1_6_wa, m1_6_ra; logic [51:0] m1_6_wd, m1_6_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_6 (.clk(clk), .we(m1_6_we), .wa(m1_6_wa), .wd(m1_6_wd), .ra(m1_6_ra), .rd(m1_6_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_6_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_6_ra <= drow;
    logic m1_7_we; logic [9:0] m1_7_wa, m1_7_ra; logic [51:0] m1_7_wd, m1_7_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_7 (.clk(clk), .we(m1_7_we), .wa(m1_7_wa), .wd(m1_7_wd), .ra(m1_7_ra), .rd(m1_7_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_7_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_7_ra <= drow;
    logic m1_8_we; logic [9:0] m1_8_wa, m1_8_ra; logic [51:0] m1_8_wd, m1_8_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_8 (.clk(clk), .we(m1_8_we), .wa(m1_8_wa), .wd(m1_8_wd), .ra(m1_8_ra), .rd(m1_8_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_8_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_8_ra <= drow;
    logic m1_9_we; logic [9:0] m1_9_wa, m1_9_ra; logic [51:0] m1_9_wd, m1_9_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_9 (.clk(clk), .we(m1_9_we), .wa(m1_9_wa), .wd(m1_9_wd), .ra(m1_9_ra), .rd(m1_9_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_9_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_9_ra <= drow;
    logic m1_10_we; logic [9:0] m1_10_wa, m1_10_ra; logic [51:0] m1_10_wd, m1_10_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_10 (.clk(clk), .we(m1_10_we), .wa(m1_10_wa), .wd(m1_10_wd), .ra(m1_10_ra), .rd(m1_10_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_10_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_10_ra <= drow;
    logic m1_11_we; logic [9:0] m1_11_wa, m1_11_ra; logic [51:0] m1_11_wd, m1_11_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_11 (.clk(clk), .we(m1_11_we), .wa(m1_11_wa), .wd(m1_11_wd), .ra(m1_11_ra), .rd(m1_11_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_11_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_11_ra <= drow;
    logic m1_12_we; logic [9:0] m1_12_wa, m1_12_ra; logic [51:0] m1_12_wd, m1_12_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_12 (.clk(clk), .we(m1_12_we), .wa(m1_12_wa), .wd(m1_12_wd), .ra(m1_12_ra), .rd(m1_12_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_12_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_12_ra <= drow;
    logic m1_13_we; logic [9:0] m1_13_wa, m1_13_ra; logic [51:0] m1_13_wd, m1_13_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_13 (.clk(clk), .we(m1_13_we), .wa(m1_13_wa), .wd(m1_13_wd), .ra(m1_13_ra), .rd(m1_13_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_13_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_13_ra <= drow;
    logic m1_14_we; logic [9:0] m1_14_wa, m1_14_ra; logic [51:0] m1_14_wd, m1_14_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_14 (.clk(clk), .we(m1_14_we), .wa(m1_14_wa), .wd(m1_14_wd), .ra(m1_14_ra), .rd(m1_14_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_14_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_14_ra <= drow;
    logic m1_15_we; logic [9:0] m1_15_wa, m1_15_ra; logic [51:0] m1_15_wd, m1_15_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_15 (.clk(clk), .we(m1_15_we), .wa(m1_15_wa), .wd(m1_15_wd), .ra(m1_15_ra), .rd(m1_15_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_15_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_15_ra <= drow;
    logic m1_16_we; logic [9:0] m1_16_wa, m1_16_ra; logic [51:0] m1_16_wd, m1_16_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_16 (.clk(clk), .we(m1_16_we), .wa(m1_16_wa), .wd(m1_16_wd), .ra(m1_16_ra), .rd(m1_16_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_16_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_16_ra <= drow;
    logic m1_17_we; logic [9:0] m1_17_wa, m1_17_ra; logic [51:0] m1_17_wd, m1_17_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_17 (.clk(clk), .we(m1_17_we), .wa(m1_17_wa), .wd(m1_17_wd), .ra(m1_17_ra), .rd(m1_17_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_17_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_17_ra <= drow;
    logic m1_18_we; logic [9:0] m1_18_wa, m1_18_ra; logic [51:0] m1_18_wd, m1_18_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_18 (.clk(clk), .we(m1_18_we), .wa(m1_18_wa), .wd(m1_18_wd), .ra(m1_18_ra), .rd(m1_18_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_18_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_18_ra <= drow;
    logic m1_19_we; logic [9:0] m1_19_wa, m1_19_ra; logic [51:0] m1_19_wd, m1_19_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_19 (.clk(clk), .we(m1_19_we), .wa(m1_19_wa), .wd(m1_19_wd), .ra(m1_19_ra), .rd(m1_19_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_19_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_19_ra <= drow;
    logic m1_20_we; logic [9:0] m1_20_wa, m1_20_ra; logic [51:0] m1_20_wd, m1_20_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_20 (.clk(clk), .we(m1_20_we), .wa(m1_20_wa), .wd(m1_20_wd), .ra(m1_20_ra), .rd(m1_20_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_20_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_20_ra <= drow;
    logic m1_21_we; logic [9:0] m1_21_wa, m1_21_ra; logic [51:0] m1_21_wd, m1_21_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_21 (.clk(clk), .we(m1_21_we), .wa(m1_21_wa), .wd(m1_21_wd), .ra(m1_21_ra), .rd(m1_21_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_21_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_21_ra <= drow;
    logic m1_22_we; logic [9:0] m1_22_wa, m1_22_ra; logic [51:0] m1_22_wd, m1_22_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_22 (.clk(clk), .we(m1_22_we), .wa(m1_22_wa), .wd(m1_22_wd), .ra(m1_22_ra), .rd(m1_22_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_22_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_22_ra <= drow;
    logic m1_23_we; logic [9:0] m1_23_wa, m1_23_ra; logic [51:0] m1_23_wd, m1_23_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_23 (.clk(clk), .we(m1_23_we), .wa(m1_23_wa), .wd(m1_23_wd), .ra(m1_23_ra), .rd(m1_23_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_23_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_23_ra <= drow;
    logic m1_24_we; logic [9:0] m1_24_wa, m1_24_ra; logic [51:0] m1_24_wd, m1_24_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_24 (.clk(clk), .we(m1_24_we), .wa(m1_24_wa), .wd(m1_24_wd), .ra(m1_24_ra), .rd(m1_24_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_24_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_24_ra <= drow;
    logic m1_25_we; logic [9:0] m1_25_wa, m1_25_ra; logic [51:0] m1_25_wd, m1_25_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_25 (.clk(clk), .we(m1_25_we), .wa(m1_25_wa), .wd(m1_25_wd), .ra(m1_25_ra), .rd(m1_25_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_25_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_25_ra <= drow;
    logic m1_26_we; logic [9:0] m1_26_wa, m1_26_ra; logic [51:0] m1_26_wd, m1_26_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_26 (.clk(clk), .we(m1_26_we), .wa(m1_26_wa), .wd(m1_26_wd), .ra(m1_26_ra), .rd(m1_26_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_26_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_26_ra <= drow;
    logic m1_27_we; logic [9:0] m1_27_wa, m1_27_ra; logic [51:0] m1_27_wd, m1_27_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_27 (.clk(clk), .we(m1_27_we), .wa(m1_27_wa), .wd(m1_27_wd), .ra(m1_27_ra), .rd(m1_27_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_27_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_27_ra <= drow;
    logic m1_28_we; logic [9:0] m1_28_wa, m1_28_ra; logic [51:0] m1_28_wd, m1_28_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_28 (.clk(clk), .we(m1_28_we), .wa(m1_28_wa), .wd(m1_28_wd), .ra(m1_28_ra), .rd(m1_28_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_28_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_28_ra <= drow;
    logic m1_29_we; logic [9:0] m1_29_wa, m1_29_ra; logic [51:0] m1_29_wd, m1_29_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_29 (.clk(clk), .we(m1_29_we), .wa(m1_29_wa), .wd(m1_29_wd), .ra(m1_29_ra), .rd(m1_29_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_29_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_29_ra <= drow;
    logic m1_30_we; logic [9:0] m1_30_wa, m1_30_ra; logic [51:0] m1_30_wd, m1_30_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_30 (.clk(clk), .we(m1_30_we), .wa(m1_30_wa), .wd(m1_30_wd), .ra(m1_30_ra), .rd(m1_30_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_30_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_30_ra <= drow;
    logic m1_31_we; logic [9:0] m1_31_wa, m1_31_ra; logic [51:0] m1_31_wd, m1_31_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_31 (.clk(clk), .we(m1_31_we), .wa(m1_31_wa), .wd(m1_31_wd), .ra(m1_31_ra), .rd(m1_31_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_31_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_31_ra <= drow;
    logic m1_32_we; logic [9:0] m1_32_wa, m1_32_ra; logic [51:0] m1_32_wd, m1_32_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_32 (.clk(clk), .we(m1_32_we), .wa(m1_32_wa), .wd(m1_32_wd), .ra(m1_32_ra), .rd(m1_32_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_32_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_32_ra <= drow;
    logic m1_33_we; logic [9:0] m1_33_wa, m1_33_ra; logic [51:0] m1_33_wd, m1_33_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_33 (.clk(clk), .we(m1_33_we), .wa(m1_33_wa), .wd(m1_33_wd), .ra(m1_33_ra), .rd(m1_33_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_33_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_33_ra <= drow;
    logic m1_34_we; logic [9:0] m1_34_wa, m1_34_ra; logic [51:0] m1_34_wd, m1_34_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_34 (.clk(clk), .we(m1_34_we), .wa(m1_34_wa), .wd(m1_34_wd), .ra(m1_34_ra), .rd(m1_34_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_34_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_34_ra <= drow;
    logic m1_35_we; logic [9:0] m1_35_wa, m1_35_ra; logic [51:0] m1_35_wd, m1_35_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_35 (.clk(clk), .we(m1_35_we), .wa(m1_35_wa), .wd(m1_35_wd), .ra(m1_35_ra), .rd(m1_35_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_35_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_35_ra <= drow;
    logic m1_36_we; logic [9:0] m1_36_wa, m1_36_ra; logic [51:0] m1_36_wd, m1_36_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_36 (.clk(clk), .we(m1_36_we), .wa(m1_36_wa), .wd(m1_36_wd), .ra(m1_36_ra), .rd(m1_36_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_36_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_36_ra <= drow;
    logic m1_37_we; logic [9:0] m1_37_wa, m1_37_ra; logic [51:0] m1_37_wd, m1_37_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_37 (.clk(clk), .we(m1_37_we), .wa(m1_37_wa), .wd(m1_37_wd), .ra(m1_37_ra), .rd(m1_37_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_37_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_37_ra <= drow;
    logic m1_38_we; logic [9:0] m1_38_wa, m1_38_ra; logic [51:0] m1_38_wd, m1_38_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_38 (.clk(clk), .we(m1_38_we), .wa(m1_38_wa), .wd(m1_38_wd), .ra(m1_38_ra), .rd(m1_38_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_38_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_38_ra <= drow;
    logic m1_39_we; logic [9:0] m1_39_wa, m1_39_ra; logic [51:0] m1_39_wd, m1_39_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_39 (.clk(clk), .we(m1_39_we), .wa(m1_39_wa), .wd(m1_39_wd), .ra(m1_39_ra), .rd(m1_39_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_39_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_39_ra <= drow;
    logic m1_40_we; logic [9:0] m1_40_wa, m1_40_ra; logic [51:0] m1_40_wd, m1_40_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_40 (.clk(clk), .we(m1_40_we), .wa(m1_40_wa), .wd(m1_40_wd), .ra(m1_40_ra), .rd(m1_40_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_40_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_40_ra <= drow;
    logic m1_41_we; logic [9:0] m1_41_wa, m1_41_ra; logic [51:0] m1_41_wd, m1_41_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_41 (.clk(clk), .we(m1_41_we), .wa(m1_41_wa), .wd(m1_41_wd), .ra(m1_41_ra), .rd(m1_41_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_41_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_41_ra <= drow;
    logic m1_42_we; logic [9:0] m1_42_wa, m1_42_ra; logic [51:0] m1_42_wd, m1_42_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_42 (.clk(clk), .we(m1_42_we), .wa(m1_42_wa), .wd(m1_42_wd), .ra(m1_42_ra), .rd(m1_42_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_42_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_42_ra <= drow;
    logic m1_43_we; logic [9:0] m1_43_wa, m1_43_ra; logic [51:0] m1_43_wd, m1_43_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_43 (.clk(clk), .we(m1_43_we), .wa(m1_43_wa), .wd(m1_43_wd), .ra(m1_43_ra), .rd(m1_43_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_43_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_43_ra <= drow;
    logic m1_44_we; logic [9:0] m1_44_wa, m1_44_ra; logic [51:0] m1_44_wd, m1_44_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_44 (.clk(clk), .we(m1_44_we), .wa(m1_44_wa), .wd(m1_44_wd), .ra(m1_44_ra), .rd(m1_44_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_44_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_44_ra <= drow;
    logic m1_45_we; logic [9:0] m1_45_wa, m1_45_ra; logic [51:0] m1_45_wd, m1_45_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_45 (.clk(clk), .we(m1_45_we), .wa(m1_45_wa), .wd(m1_45_wd), .ra(m1_45_ra), .rd(m1_45_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_45_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_45_ra <= drow;
    logic m1_46_we; logic [9:0] m1_46_wa, m1_46_ra; logic [51:0] m1_46_wd, m1_46_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_46 (.clk(clk), .we(m1_46_we), .wa(m1_46_wa), .wd(m1_46_wd), .ra(m1_46_ra), .rd(m1_46_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_46_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_46_ra <= drow;
    logic m1_47_we; logic [9:0] m1_47_wa, m1_47_ra; logic [51:0] m1_47_wd, m1_47_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_47 (.clk(clk), .we(m1_47_we), .wa(m1_47_wa), .wd(m1_47_wd), .ra(m1_47_ra), .rd(m1_47_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_47_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_47_ra <= drow;
    logic m1_48_we; logic [9:0] m1_48_wa, m1_48_ra; logic [51:0] m1_48_wd, m1_48_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_48 (.clk(clk), .we(m1_48_we), .wa(m1_48_wa), .wd(m1_48_wd), .ra(m1_48_ra), .rd(m1_48_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_48_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_48_ra <= drow;
    logic m1_49_we; logic [9:0] m1_49_wa, m1_49_ra; logic [51:0] m1_49_wd, m1_49_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_49 (.clk(clk), .we(m1_49_we), .wa(m1_49_wa), .wd(m1_49_wd), .ra(m1_49_ra), .rd(m1_49_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_49_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_49_ra <= drow;
    logic m1_50_we; logic [9:0] m1_50_wa, m1_50_ra; logic [51:0] m1_50_wd, m1_50_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_50 (.clk(clk), .we(m1_50_we), .wa(m1_50_wa), .wd(m1_50_wd), .ra(m1_50_ra), .rd(m1_50_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_50_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_50_ra <= drow;
    logic m1_51_we; logic [9:0] m1_51_wa, m1_51_ra; logic [51:0] m1_51_wd, m1_51_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_51 (.clk(clk), .we(m1_51_we), .wa(m1_51_wa), .wd(m1_51_wd), .ra(m1_51_ra), .rd(m1_51_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_51_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_51_ra <= drow;
    logic m1_52_we; logic [9:0] m1_52_wa, m1_52_ra; logic [51:0] m1_52_wd, m1_52_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_52 (.clk(clk), .we(m1_52_we), .wa(m1_52_wa), .wd(m1_52_wd), .ra(m1_52_ra), .rd(m1_52_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_52_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_52_ra <= drow;
    logic m1_53_we; logic [9:0] m1_53_wa, m1_53_ra; logic [51:0] m1_53_wd, m1_53_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_53 (.clk(clk), .we(m1_53_we), .wa(m1_53_wa), .wd(m1_53_wd), .ra(m1_53_ra), .rd(m1_53_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_53_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_53_ra <= drow;
    logic m1_54_we; logic [9:0] m1_54_wa, m1_54_ra; logic [51:0] m1_54_wd, m1_54_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_54 (.clk(clk), .we(m1_54_we), .wa(m1_54_wa), .wd(m1_54_wd), .ra(m1_54_ra), .rd(m1_54_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_54_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_54_ra <= drow;
    logic m1_55_we; logic [9:0] m1_55_wa, m1_55_ra; logic [51:0] m1_55_wd, m1_55_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_55 (.clk(clk), .we(m1_55_we), .wa(m1_55_wa), .wd(m1_55_wd), .ra(m1_55_ra), .rd(m1_55_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_55_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_55_ra <= drow;
    logic m1_56_we; logic [9:0] m1_56_wa, m1_56_ra; logic [51:0] m1_56_wd, m1_56_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_56 (.clk(clk), .we(m1_56_we), .wa(m1_56_wa), .wd(m1_56_wd), .ra(m1_56_ra), .rd(m1_56_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_56_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_56_ra <= drow;
    logic m1_57_we; logic [9:0] m1_57_wa, m1_57_ra; logic [51:0] m1_57_wd, m1_57_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_57 (.clk(clk), .we(m1_57_we), .wa(m1_57_wa), .wd(m1_57_wd), .ra(m1_57_ra), .rd(m1_57_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_57_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_57_ra <= drow;
    logic m1_58_we; logic [9:0] m1_58_wa, m1_58_ra; logic [51:0] m1_58_wd, m1_58_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_58 (.clk(clk), .we(m1_58_we), .wa(m1_58_wa), .wd(m1_58_wd), .ra(m1_58_ra), .rd(m1_58_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_58_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_58_ra <= drow;
    logic m1_59_we; logic [9:0] m1_59_wa, m1_59_ra; logic [51:0] m1_59_wd, m1_59_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_59 (.clk(clk), .we(m1_59_we), .wa(m1_59_wa), .wd(m1_59_wd), .ra(m1_59_ra), .rd(m1_59_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_59_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_59_ra <= drow;
    logic m1_60_we; logic [9:0] m1_60_wa, m1_60_ra; logic [51:0] m1_60_wd, m1_60_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_60 (.clk(clk), .we(m1_60_we), .wa(m1_60_wa), .wd(m1_60_wd), .ra(m1_60_ra), .rd(m1_60_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_60_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_60_ra <= drow;
    logic m1_61_we; logic [9:0] m1_61_wa, m1_61_ra; logic [51:0] m1_61_wd, m1_61_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_61 (.clk(clk), .we(m1_61_we), .wa(m1_61_wa), .wd(m1_61_wd), .ra(m1_61_ra), .rd(m1_61_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_61_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_61_ra <= drow;
    logic m1_62_we; logic [9:0] m1_62_wa, m1_62_ra; logic [51:0] m1_62_wd, m1_62_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_62 (.clk(clk), .we(m1_62_we), .wa(m1_62_wa), .wd(m1_62_wd), .ra(m1_62_ra), .rd(m1_62_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_62_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_62_ra <= drow;
    logic m1_63_we; logic [9:0] m1_63_wa, m1_63_ra; logic [51:0] m1_63_wd, m1_63_rd;
    Id_n65536_q52w_B32_rns_ram_block #(.W(52), .D(1024), .A(10), .R(2)) u_m1_63 (.clk(clk), .we(m1_63_we), .wa(m1_63_wa), .wd(m1_63_wd), .ra(m1_63_ra), .rd(m1_63_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_63_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_63_ra <= drow;
    logic [51:0] rdc0; assign rdc0 = cb_set[2] ? m1_0_rd : m0_0_rd;
    logic [51:0] rdc1; assign rdc1 = cb_set[2] ? m1_1_rd : m0_1_rd;
    logic [51:0] rdc2; assign rdc2 = cb_set[2] ? m1_2_rd : m0_2_rd;
    logic [51:0] rdc3; assign rdc3 = cb_set[2] ? m1_3_rd : m0_3_rd;
    logic [51:0] rdc4; assign rdc4 = cb_set[2] ? m1_4_rd : m0_4_rd;
    logic [51:0] rdc5; assign rdc5 = cb_set[2] ? m1_5_rd : m0_5_rd;
    logic [51:0] rdc6; assign rdc6 = cb_set[2] ? m1_6_rd : m0_6_rd;
    logic [51:0] rdc7; assign rdc7 = cb_set[2] ? m1_7_rd : m0_7_rd;
    logic [51:0] rdc8; assign rdc8 = cb_set[2] ? m1_8_rd : m0_8_rd;
    logic [51:0] rdc9; assign rdc9 = cb_set[2] ? m1_9_rd : m0_9_rd;
    logic [51:0] rdc10; assign rdc10 = cb_set[2] ? m1_10_rd : m0_10_rd;
    logic [51:0] rdc11; assign rdc11 = cb_set[2] ? m1_11_rd : m0_11_rd;
    logic [51:0] rdc12; assign rdc12 = cb_set[2] ? m1_12_rd : m0_12_rd;
    logic [51:0] rdc13; assign rdc13 = cb_set[2] ? m1_13_rd : m0_13_rd;
    logic [51:0] rdc14; assign rdc14 = cb_set[2] ? m1_14_rd : m0_14_rd;
    logic [51:0] rdc15; assign rdc15 = cb_set[2] ? m1_15_rd : m0_15_rd;
    logic [51:0] rdc16; assign rdc16 = cb_set[2] ? m1_16_rd : m0_16_rd;
    logic [51:0] rdc17; assign rdc17 = cb_set[2] ? m1_17_rd : m0_17_rd;
    logic [51:0] rdc18; assign rdc18 = cb_set[2] ? m1_18_rd : m0_18_rd;
    logic [51:0] rdc19; assign rdc19 = cb_set[2] ? m1_19_rd : m0_19_rd;
    logic [51:0] rdc20; assign rdc20 = cb_set[2] ? m1_20_rd : m0_20_rd;
    logic [51:0] rdc21; assign rdc21 = cb_set[2] ? m1_21_rd : m0_21_rd;
    logic [51:0] rdc22; assign rdc22 = cb_set[2] ? m1_22_rd : m0_22_rd;
    logic [51:0] rdc23; assign rdc23 = cb_set[2] ? m1_23_rd : m0_23_rd;
    logic [51:0] rdc24; assign rdc24 = cb_set[2] ? m1_24_rd : m0_24_rd;
    logic [51:0] rdc25; assign rdc25 = cb_set[2] ? m1_25_rd : m0_25_rd;
    logic [51:0] rdc26; assign rdc26 = cb_set[2] ? m1_26_rd : m0_26_rd;
    logic [51:0] rdc27; assign rdc27 = cb_set[2] ? m1_27_rd : m0_27_rd;
    logic [51:0] rdc28; assign rdc28 = cb_set[2] ? m1_28_rd : m0_28_rd;
    logic [51:0] rdc29; assign rdc29 = cb_set[2] ? m1_29_rd : m0_29_rd;
    logic [51:0] rdc30; assign rdc30 = cb_set[2] ? m1_30_rd : m0_30_rd;
    logic [51:0] rdc31; assign rdc31 = cb_set[2] ? m1_31_rd : m0_31_rd;
    logic [51:0] rdc32; assign rdc32 = cb_set[2] ? m1_32_rd : m0_32_rd;
    logic [51:0] rdc33; assign rdc33 = cb_set[2] ? m1_33_rd : m0_33_rd;
    logic [51:0] rdc34; assign rdc34 = cb_set[2] ? m1_34_rd : m0_34_rd;
    logic [51:0] rdc35; assign rdc35 = cb_set[2] ? m1_35_rd : m0_35_rd;
    logic [51:0] rdc36; assign rdc36 = cb_set[2] ? m1_36_rd : m0_36_rd;
    logic [51:0] rdc37; assign rdc37 = cb_set[2] ? m1_37_rd : m0_37_rd;
    logic [51:0] rdc38; assign rdc38 = cb_set[2] ? m1_38_rd : m0_38_rd;
    logic [51:0] rdc39; assign rdc39 = cb_set[2] ? m1_39_rd : m0_39_rd;
    logic [51:0] rdc40; assign rdc40 = cb_set[2] ? m1_40_rd : m0_40_rd;
    logic [51:0] rdc41; assign rdc41 = cb_set[2] ? m1_41_rd : m0_41_rd;
    logic [51:0] rdc42; assign rdc42 = cb_set[2] ? m1_42_rd : m0_42_rd;
    logic [51:0] rdc43; assign rdc43 = cb_set[2] ? m1_43_rd : m0_43_rd;
    logic [51:0] rdc44; assign rdc44 = cb_set[2] ? m1_44_rd : m0_44_rd;
    logic [51:0] rdc45; assign rdc45 = cb_set[2] ? m1_45_rd : m0_45_rd;
    logic [51:0] rdc46; assign rdc46 = cb_set[2] ? m1_46_rd : m0_46_rd;
    logic [51:0] rdc47; assign rdc47 = cb_set[2] ? m1_47_rd : m0_47_rd;
    logic [51:0] rdc48; assign rdc48 = cb_set[2] ? m1_48_rd : m0_48_rd;
    logic [51:0] rdc49; assign rdc49 = cb_set[2] ? m1_49_rd : m0_49_rd;
    logic [51:0] rdc50; assign rdc50 = cb_set[2] ? m1_50_rd : m0_50_rd;
    logic [51:0] rdc51; assign rdc51 = cb_set[2] ? m1_51_rd : m0_51_rd;
    logic [51:0] rdc52; assign rdc52 = cb_set[2] ? m1_52_rd : m0_52_rd;
    logic [51:0] rdc53; assign rdc53 = cb_set[2] ? m1_53_rd : m0_53_rd;
    logic [51:0] rdc54; assign rdc54 = cb_set[2] ? m1_54_rd : m0_54_rd;
    logic [51:0] rdc55; assign rdc55 = cb_set[2] ? m1_55_rd : m0_55_rd;
    logic [51:0] rdc56; assign rdc56 = cb_set[2] ? m1_56_rd : m0_56_rd;
    logic [51:0] rdc57; assign rdc57 = cb_set[2] ? m1_57_rd : m0_57_rd;
    logic [51:0] rdc58; assign rdc58 = cb_set[2] ? m1_58_rd : m0_58_rd;
    logic [51:0] rdc59; assign rdc59 = cb_set[2] ? m1_59_rd : m0_59_rd;
    logic [51:0] rdc60; assign rdc60 = cb_set[2] ? m1_60_rd : m0_60_rd;
    logic [51:0] rdc61; assign rdc61 = cb_set[2] ? m1_61_rd : m0_61_rd;
    logic [51:0] rdc62; assign rdc62 = cb_set[2] ? m1_62_rd : m0_62_rd;
    logic [51:0] rdc63; assign rdc63 = cb_set[2] ? m1_63_rd : m0_63_rd;
    // ---- operand mux (sources per port: IterativeNTTScheme.readSources)
    logic [51:0] op0;
    always_ff @(posedge clk) case (rc0)
        1'd0: op0 <= rdc0;
        1'd1: op0 <= rdc32;
        default: op0 <= rdc0;
    endcase
    logic [51:0] op1;
    always_ff @(posedge clk) case (rc1)
        4'd0: op1 <= rdc0;
        4'd1: op1 <= rdc1;
        4'd2: op1 <= rdc2;
        4'd3: op1 <= rdc4;
        4'd4: op1 <= rdc8;
        4'd5: op1 <= rdc16;
        4'd6: op1 <= rdc32;
        4'd7: op1 <= rdc33;
        4'd8: op1 <= rdc34;
        4'd9: op1 <= rdc36;
        4'd10: op1 <= rdc40;
        4'd11: op1 <= rdc48;
        default: op1 <= rdc0;
    endcase
    logic [51:0] op2;
    always_ff @(posedge clk) case (rc2)
        2'd0: op2 <= rdc1;
        2'd1: op2 <= rdc2;
        2'd2: op2 <= rdc33;
        2'd3: op2 <= rdc34;
        default: op2 <= rdc1;
    endcase
    logic [51:0] op3;
    always_ff @(posedge clk) case (rc3)
        4'd0: op3 <= rdc1;
        4'd1: op3 <= rdc3;
        4'd2: op3 <= rdc5;
        4'd3: op3 <= rdc9;
        4'd4: op3 <= rdc17;
        4'd5: op3 <= rdc33;
        4'd6: op3 <= rdc35;
        4'd7: op3 <= rdc37;
        4'd8: op3 <= rdc41;
        4'd9: op3 <= rdc49;
        default: op3 <= rdc1;
    endcase
    logic [51:0] op4;
    always_ff @(posedge clk) case (rc4)
        2'd0: op4 <= rdc2;
        2'd1: op4 <= rdc4;
        2'd2: op4 <= rdc34;
        2'd3: op4 <= rdc36;
        default: op4 <= rdc2;
    endcase
    logic [51:0] op5;
    always_ff @(posedge clk) case (rc5)
        4'd0: op5 <= rdc2;
        4'd1: op5 <= rdc5;
        4'd2: op5 <= rdc6;
        4'd3: op5 <= rdc10;
        4'd4: op5 <= rdc18;
        4'd5: op5 <= rdc34;
        4'd6: op5 <= rdc37;
        4'd7: op5 <= rdc38;
        4'd8: op5 <= rdc42;
        4'd9: op5 <= rdc50;
        default: op5 <= rdc2;
    endcase
    logic [51:0] op6;
    always_ff @(posedge clk) case (rc6)
        3'd0: op6 <= rdc3;
        3'd1: op6 <= rdc5;
        3'd2: op6 <= rdc6;
        3'd3: op6 <= rdc35;
        3'd4: op6 <= rdc37;
        3'd5: op6 <= rdc38;
        default: op6 <= rdc3;
    endcase
    logic [51:0] op7;
    always_ff @(posedge clk) case (rc7)
        3'd0: op7 <= rdc3;
        3'd1: op7 <= rdc7;
        3'd2: op7 <= rdc11;
        3'd3: op7 <= rdc19;
        3'd4: op7 <= rdc35;
        3'd5: op7 <= rdc39;
        3'd6: op7 <= rdc43;
        3'd7: op7 <= rdc51;
        default: op7 <= rdc3;
    endcase
    logic [51:0] op8;
    always_ff @(posedge clk) case (rc8)
        2'd0: op8 <= rdc4;
        2'd1: op8 <= rdc8;
        2'd2: op8 <= rdc36;
        2'd3: op8 <= rdc40;
        default: op8 <= rdc4;
    endcase
    logic [51:0] op9;
    always_ff @(posedge clk) case (rc9)
        4'd0: op9 <= rdc4;
        4'd1: op9 <= rdc9;
        4'd2: op9 <= rdc10;
        4'd3: op9 <= rdc12;
        4'd4: op9 <= rdc20;
        4'd5: op9 <= rdc36;
        4'd6: op9 <= rdc41;
        4'd7: op9 <= rdc42;
        4'd8: op9 <= rdc44;
        4'd9: op9 <= rdc52;
        default: op9 <= rdc4;
    endcase
    logic [51:0] op10;
    always_ff @(posedge clk) case (rc10)
        3'd0: op10 <= rdc5;
        3'd1: op10 <= rdc9;
        3'd2: op10 <= rdc10;
        3'd3: op10 <= rdc37;
        3'd4: op10 <= rdc41;
        3'd5: op10 <= rdc42;
        default: op10 <= rdc5;
    endcase
    logic [51:0] op11;
    always_ff @(posedge clk) case (rc11)
        3'd0: op11 <= rdc5;
        3'd1: op11 <= rdc11;
        3'd2: op11 <= rdc13;
        3'd3: op11 <= rdc21;
        3'd4: op11 <= rdc37;
        3'd5: op11 <= rdc43;
        3'd6: op11 <= rdc45;
        3'd7: op11 <= rdc53;
        default: op11 <= rdc5;
    endcase
    logic [51:0] op12;
    always_ff @(posedge clk) case (rc12)
        3'd0: op12 <= rdc6;
        3'd1: op12 <= rdc10;
        3'd2: op12 <= rdc12;
        3'd3: op12 <= rdc38;
        3'd4: op12 <= rdc42;
        3'd5: op12 <= rdc44;
        default: op12 <= rdc6;
    endcase
    logic [51:0] op13;
    always_ff @(posedge clk) case (rc13)
        3'd0: op13 <= rdc6;
        3'd1: op13 <= rdc13;
        3'd2: op13 <= rdc14;
        3'd3: op13 <= rdc22;
        3'd4: op13 <= rdc38;
        3'd5: op13 <= rdc45;
        3'd6: op13 <= rdc46;
        3'd7: op13 <= rdc54;
        default: op13 <= rdc6;
    endcase
    logic [51:0] op14;
    always_ff @(posedge clk) case (rc14)
        3'd0: op14 <= rdc7;
        3'd1: op14 <= rdc11;
        3'd2: op14 <= rdc13;
        3'd3: op14 <= rdc14;
        3'd4: op14 <= rdc39;
        3'd5: op14 <= rdc43;
        3'd6: op14 <= rdc45;
        3'd7: op14 <= rdc46;
        default: op14 <= rdc7;
    endcase
    logic [51:0] op15;
    always_ff @(posedge clk) case (rc15)
        3'd0: op15 <= rdc7;
        3'd1: op15 <= rdc15;
        3'd2: op15 <= rdc23;
        3'd3: op15 <= rdc39;
        3'd4: op15 <= rdc47;
        3'd5: op15 <= rdc55;
        default: op15 <= rdc7;
    endcase
    logic [51:0] op16;
    always_ff @(posedge clk) case (rc16)
        2'd0: op16 <= rdc8;
        2'd1: op16 <= rdc16;
        2'd2: op16 <= rdc40;
        2'd3: op16 <= rdc48;
        default: op16 <= rdc8;
    endcase
    logic [51:0] op17;
    always_ff @(posedge clk) case (rc17)
        4'd0: op17 <= rdc8;
        4'd1: op17 <= rdc17;
        4'd2: op17 <= rdc18;
        4'd3: op17 <= rdc20;
        4'd4: op17 <= rdc24;
        4'd5: op17 <= rdc40;
        4'd6: op17 <= rdc49;
        4'd7: op17 <= rdc50;
        4'd8: op17 <= rdc52;
        4'd9: op17 <= rdc56;
        default: op17 <= rdc8;
    endcase
    logic [51:0] op18;
    always_ff @(posedge clk) case (rc18)
        3'd0: op18 <= rdc9;
        3'd1: op18 <= rdc17;
        3'd2: op18 <= rdc18;
        3'd3: op18 <= rdc41;
        3'd4: op18 <= rdc49;
        3'd5: op18 <= rdc50;
        default: op18 <= rdc9;
    endcase
    logic [51:0] op19;
    always_ff @(posedge clk) case (rc19)
        3'd0: op19 <= rdc9;
        3'd1: op19 <= rdc19;
        3'd2: op19 <= rdc21;
        3'd3: op19 <= rdc25;
        3'd4: op19 <= rdc41;
        3'd5: op19 <= rdc51;
        3'd6: op19 <= rdc53;
        3'd7: op19 <= rdc57;
        default: op19 <= rdc9;
    endcase
    logic [51:0] op20;
    always_ff @(posedge clk) case (rc20)
        3'd0: op20 <= rdc10;
        3'd1: op20 <= rdc18;
        3'd2: op20 <= rdc20;
        3'd3: op20 <= rdc42;
        3'd4: op20 <= rdc50;
        3'd5: op20 <= rdc52;
        default: op20 <= rdc10;
    endcase
    logic [51:0] op21;
    always_ff @(posedge clk) case (rc21)
        3'd0: op21 <= rdc10;
        3'd1: op21 <= rdc21;
        3'd2: op21 <= rdc22;
        3'd3: op21 <= rdc26;
        3'd4: op21 <= rdc42;
        3'd5: op21 <= rdc53;
        3'd6: op21 <= rdc54;
        3'd7: op21 <= rdc58;
        default: op21 <= rdc10;
    endcase
    logic [51:0] op22;
    always_ff @(posedge clk) case (rc22)
        3'd0: op22 <= rdc11;
        3'd1: op22 <= rdc19;
        3'd2: op22 <= rdc21;
        3'd3: op22 <= rdc22;
        3'd4: op22 <= rdc43;
        3'd5: op22 <= rdc51;
        3'd6: op22 <= rdc53;
        3'd7: op22 <= rdc54;
        default: op22 <= rdc11;
    endcase
    logic [51:0] op23;
    always_ff @(posedge clk) case (rc23)
        3'd0: op23 <= rdc11;
        3'd1: op23 <= rdc23;
        3'd2: op23 <= rdc27;
        3'd3: op23 <= rdc43;
        3'd4: op23 <= rdc55;
        3'd5: op23 <= rdc59;
        default: op23 <= rdc11;
    endcase
    logic [51:0] op24;
    always_ff @(posedge clk) case (rc24)
        3'd0: op24 <= rdc12;
        3'd1: op24 <= rdc20;
        3'd2: op24 <= rdc24;
        3'd3: op24 <= rdc44;
        3'd4: op24 <= rdc52;
        3'd5: op24 <= rdc56;
        default: op24 <= rdc12;
    endcase
    logic [51:0] op25;
    always_ff @(posedge clk) case (rc25)
        3'd0: op25 <= rdc12;
        3'd1: op25 <= rdc25;
        3'd2: op25 <= rdc26;
        3'd3: op25 <= rdc28;
        3'd4: op25 <= rdc44;
        3'd5: op25 <= rdc57;
        3'd6: op25 <= rdc58;
        3'd7: op25 <= rdc60;
        default: op25 <= rdc12;
    endcase
    logic [51:0] op26;
    always_ff @(posedge clk) case (rc26)
        3'd0: op26 <= rdc13;
        3'd1: op26 <= rdc21;
        3'd2: op26 <= rdc25;
        3'd3: op26 <= rdc26;
        3'd4: op26 <= rdc45;
        3'd5: op26 <= rdc53;
        3'd6: op26 <= rdc57;
        3'd7: op26 <= rdc58;
        default: op26 <= rdc13;
    endcase
    logic [51:0] op27;
    always_ff @(posedge clk) case (rc27)
        3'd0: op27 <= rdc13;
        3'd1: op27 <= rdc27;
        3'd2: op27 <= rdc29;
        3'd3: op27 <= rdc45;
        3'd4: op27 <= rdc59;
        3'd5: op27 <= rdc61;
        default: op27 <= rdc13;
    endcase
    logic [51:0] op28;
    always_ff @(posedge clk) case (rc28)
        3'd0: op28 <= rdc14;
        3'd1: op28 <= rdc22;
        3'd2: op28 <= rdc26;
        3'd3: op28 <= rdc28;
        3'd4: op28 <= rdc46;
        3'd5: op28 <= rdc54;
        3'd6: op28 <= rdc58;
        3'd7: op28 <= rdc60;
        default: op28 <= rdc14;
    endcase
    logic [51:0] op29;
    always_ff @(posedge clk) case (rc29)
        3'd0: op29 <= rdc14;
        3'd1: op29 <= rdc29;
        3'd2: op29 <= rdc30;
        3'd3: op29 <= rdc46;
        3'd4: op29 <= rdc61;
        3'd5: op29 <= rdc62;
        default: op29 <= rdc14;
    endcase
    logic [51:0] op30;
    always_ff @(posedge clk) case (rc30)
        4'd0: op30 <= rdc15;
        4'd1: op30 <= rdc23;
        4'd2: op30 <= rdc27;
        4'd3: op30 <= rdc29;
        4'd4: op30 <= rdc30;
        4'd5: op30 <= rdc47;
        4'd6: op30 <= rdc55;
        4'd7: op30 <= rdc59;
        4'd8: op30 <= rdc61;
        4'd9: op30 <= rdc62;
        default: op30 <= rdc15;
    endcase
    logic [51:0] op31;
    always_ff @(posedge clk) case (rc31)
        2'd0: op31 <= rdc15;
        2'd1: op31 <= rdc31;
        2'd2: op31 <= rdc47;
        2'd3: op31 <= rdc63;
        default: op31 <= rdc15;
    endcase
    logic [51:0] op32;
    always_ff @(posedge clk) case (rc32)
        2'd0: op32 <= rdc0;
        2'd1: op32 <= rdc16;
        2'd2: op32 <= rdc32;
        2'd3: op32 <= rdc48;
        default: op32 <= rdc0;
    endcase
    logic [51:0] op33;
    always_ff @(posedge clk) case (rc33)
        4'd0: op33 <= rdc1;
        4'd1: op33 <= rdc2;
        4'd2: op33 <= rdc4;
        4'd3: op33 <= rdc8;
        4'd4: op33 <= rdc16;
        4'd5: op33 <= rdc33;
        4'd6: op33 <= rdc34;
        4'd7: op33 <= rdc36;
        4'd8: op33 <= rdc40;
        4'd9: op33 <= rdc48;
        default: op33 <= rdc1;
    endcase
    logic [51:0] op34;
    always_ff @(posedge clk) case (rc34)
        3'd0: op34 <= rdc1;
        3'd1: op34 <= rdc2;
        3'd2: op34 <= rdc17;
        3'd3: op34 <= rdc33;
        3'd4: op34 <= rdc34;
        3'd5: op34 <= rdc49;
        default: op34 <= rdc1;
    endcase
    logic [51:0] op35;
    always_ff @(posedge clk) case (rc35)
        3'd0: op35 <= rdc3;
        3'd1: op35 <= rdc5;
        3'd2: op35 <= rdc9;
        3'd3: op35 <= rdc17;
        3'd4: op35 <= rdc35;
        3'd5: op35 <= rdc37;
        3'd6: op35 <= rdc41;
        3'd7: op35 <= rdc49;
        default: op35 <= rdc3;
    endcase
    logic [51:0] op36;
    always_ff @(posedge clk) case (rc36)
        3'd0: op36 <= rdc2;
        3'd1: op36 <= rdc4;
        3'd2: op36 <= rdc18;
        3'd3: op36 <= rdc34;
        3'd4: op36 <= rdc36;
        3'd5: op36 <= rdc50;
        default: op36 <= rdc2;
    endcase
    logic [51:0] op37;
    always_ff @(posedge clk) case (rc37)
        3'd0: op37 <= rdc5;
        3'd1: op37 <= rdc6;
        3'd2: op37 <= rdc10;
        3'd3: op37 <= rdc18;
        3'd4: op37 <= rdc37;
        3'd5: op37 <= rdc38;
        3'd6: op37 <= rdc42;
        3'd7: op37 <= rdc50;
        default: op37 <= rdc5;
    endcase
    logic [51:0] op38;
    always_ff @(posedge clk) case (rc38)
        3'd0: op38 <= rdc3;
        3'd1: op38 <= rdc5;
        3'd2: op38 <= rdc6;
        3'd3: op38 <= rdc19;
        3'd4: op38 <= rdc35;
        3'd5: op38 <= rdc37;
        3'd6: op38 <= rdc38;
        3'd7: op38 <= rdc51;
        default: op38 <= rdc3;
    endcase
    logic [51:0] op39;
    always_ff @(posedge clk) case (rc39)
        3'd0: op39 <= rdc7;
        3'd1: op39 <= rdc11;
        3'd2: op39 <= rdc19;
        3'd3: op39 <= rdc39;
        3'd4: op39 <= rdc43;
        3'd5: op39 <= rdc51;
        default: op39 <= rdc7;
    endcase
    logic [51:0] op40;
    always_ff @(posedge clk) case (rc40)
        3'd0: op40 <= rdc4;
        3'd1: op40 <= rdc8;
        3'd2: op40 <= rdc20;
        3'd3: op40 <= rdc36;
        3'd4: op40 <= rdc40;
        3'd5: op40 <= rdc52;
        default: op40 <= rdc4;
    endcase
    logic [51:0] op41;
    always_ff @(posedge clk) case (rc41)
        3'd0: op41 <= rdc9;
        3'd1: op41 <= rdc10;
        3'd2: op41 <= rdc12;
        3'd3: op41 <= rdc20;
        3'd4: op41 <= rdc41;
        3'd5: op41 <= rdc42;
        3'd6: op41 <= rdc44;
        3'd7: op41 <= rdc52;
        default: op41 <= rdc9;
    endcase
    logic [51:0] op42;
    always_ff @(posedge clk) case (rc42)
        3'd0: op42 <= rdc5;
        3'd1: op42 <= rdc9;
        3'd2: op42 <= rdc10;
        3'd3: op42 <= rdc21;
        3'd4: op42 <= rdc37;
        3'd5: op42 <= rdc41;
        3'd6: op42 <= rdc42;
        3'd7: op42 <= rdc53;
        default: op42 <= rdc5;
    endcase
    logic [51:0] op43;
    always_ff @(posedge clk) case (rc43)
        3'd0: op43 <= rdc11;
        3'd1: op43 <= rdc13;
        3'd2: op43 <= rdc21;
        3'd3: op43 <= rdc43;
        3'd4: op43 <= rdc45;
        3'd5: op43 <= rdc53;
        default: op43 <= rdc11;
    endcase
    logic [51:0] op44;
    always_ff @(posedge clk) case (rc44)
        3'd0: op44 <= rdc6;
        3'd1: op44 <= rdc10;
        3'd2: op44 <= rdc12;
        3'd3: op44 <= rdc22;
        3'd4: op44 <= rdc38;
        3'd5: op44 <= rdc42;
        3'd6: op44 <= rdc44;
        3'd7: op44 <= rdc54;
        default: op44 <= rdc6;
    endcase
    logic [51:0] op45;
    always_ff @(posedge clk) case (rc45)
        3'd0: op45 <= rdc13;
        3'd1: op45 <= rdc14;
        3'd2: op45 <= rdc22;
        3'd3: op45 <= rdc45;
        3'd4: op45 <= rdc46;
        3'd5: op45 <= rdc54;
        default: op45 <= rdc13;
    endcase
    logic [51:0] op46;
    always_ff @(posedge clk) case (rc46)
        4'd0: op46 <= rdc7;
        4'd1: op46 <= rdc11;
        4'd2: op46 <= rdc13;
        4'd3: op46 <= rdc14;
        4'd4: op46 <= rdc23;
        4'd5: op46 <= rdc39;
        4'd6: op46 <= rdc43;
        4'd7: op46 <= rdc45;
        4'd8: op46 <= rdc46;
        4'd9: op46 <= rdc55;
        default: op46 <= rdc7;
    endcase
    logic [51:0] op47;
    always_ff @(posedge clk) case (rc47)
        2'd0: op47 <= rdc15;
        2'd1: op47 <= rdc23;
        2'd2: op47 <= rdc47;
        2'd3: op47 <= rdc55;
        default: op47 <= rdc15;
    endcase
    logic [51:0] op48;
    always_ff @(posedge clk) case (rc48)
        3'd0: op48 <= rdc8;
        3'd1: op48 <= rdc16;
        3'd2: op48 <= rdc24;
        3'd3: op48 <= rdc40;
        3'd4: op48 <= rdc48;
        3'd5: op48 <= rdc56;
        default: op48 <= rdc8;
    endcase
    logic [51:0] op49;
    always_ff @(posedge clk) case (rc49)
        3'd0: op49 <= rdc17;
        3'd1: op49 <= rdc18;
        3'd2: op49 <= rdc20;
        3'd3: op49 <= rdc24;
        3'd4: op49 <= rdc49;
        3'd5: op49 <= rdc50;
        3'd6: op49 <= rdc52;
        3'd7: op49 <= rdc56;
        default: op49 <= rdc17;
    endcase
    logic [51:0] op50;
    always_ff @(posedge clk) case (rc50)
        3'd0: op50 <= rdc9;
        3'd1: op50 <= rdc17;
        3'd2: op50 <= rdc18;
        3'd3: op50 <= rdc25;
        3'd4: op50 <= rdc41;
        3'd5: op50 <= rdc49;
        3'd6: op50 <= rdc50;
        3'd7: op50 <= rdc57;
        default: op50 <= rdc9;
    endcase
    logic [51:0] op51;
    always_ff @(posedge clk) case (rc51)
        3'd0: op51 <= rdc19;
        3'd1: op51 <= rdc21;
        3'd2: op51 <= rdc25;
        3'd3: op51 <= rdc51;
        3'd4: op51 <= rdc53;
        3'd5: op51 <= rdc57;
        default: op51 <= rdc19;
    endcase
    logic [51:0] op52;
    always_ff @(posedge clk) case (rc52)
        3'd0: op52 <= rdc10;
        3'd1: op52 <= rdc18;
        3'd2: op52 <= rdc20;
        3'd3: op52 <= rdc26;
        3'd4: op52 <= rdc42;
        3'd5: op52 <= rdc50;
        3'd6: op52 <= rdc52;
        3'd7: op52 <= rdc58;
        default: op52 <= rdc10;
    endcase
    logic [51:0] op53;
    always_ff @(posedge clk) case (rc53)
        3'd0: op53 <= rdc21;
        3'd1: op53 <= rdc22;
        3'd2: op53 <= rdc26;
        3'd3: op53 <= rdc53;
        3'd4: op53 <= rdc54;
        3'd5: op53 <= rdc58;
        default: op53 <= rdc21;
    endcase
    logic [51:0] op54;
    always_ff @(posedge clk) case (rc54)
        4'd0: op54 <= rdc11;
        4'd1: op54 <= rdc19;
        4'd2: op54 <= rdc21;
        4'd3: op54 <= rdc22;
        4'd4: op54 <= rdc27;
        4'd5: op54 <= rdc43;
        4'd6: op54 <= rdc51;
        4'd7: op54 <= rdc53;
        4'd8: op54 <= rdc54;
        4'd9: op54 <= rdc59;
        default: op54 <= rdc11;
    endcase
    logic [51:0] op55;
    always_ff @(posedge clk) case (rc55)
        2'd0: op55 <= rdc23;
        2'd1: op55 <= rdc27;
        2'd2: op55 <= rdc55;
        2'd3: op55 <= rdc59;
        default: op55 <= rdc23;
    endcase
    logic [51:0] op56;
    always_ff @(posedge clk) case (rc56)
        3'd0: op56 <= rdc12;
        3'd1: op56 <= rdc20;
        3'd2: op56 <= rdc24;
        3'd3: op56 <= rdc28;
        3'd4: op56 <= rdc44;
        3'd5: op56 <= rdc52;
        3'd6: op56 <= rdc56;
        3'd7: op56 <= rdc60;
        default: op56 <= rdc12;
    endcase
    logic [51:0] op57;
    always_ff @(posedge clk) case (rc57)
        3'd0: op57 <= rdc25;
        3'd1: op57 <= rdc26;
        3'd2: op57 <= rdc28;
        3'd3: op57 <= rdc57;
        3'd4: op57 <= rdc58;
        3'd5: op57 <= rdc60;
        default: op57 <= rdc25;
    endcase
    logic [51:0] op58;
    always_ff @(posedge clk) case (rc58)
        4'd0: op58 <= rdc13;
        4'd1: op58 <= rdc21;
        4'd2: op58 <= rdc25;
        4'd3: op58 <= rdc26;
        4'd4: op58 <= rdc29;
        4'd5: op58 <= rdc45;
        4'd6: op58 <= rdc53;
        4'd7: op58 <= rdc57;
        4'd8: op58 <= rdc58;
        4'd9: op58 <= rdc61;
        default: op58 <= rdc13;
    endcase
    logic [51:0] op59;
    always_ff @(posedge clk) case (rc59)
        2'd0: op59 <= rdc27;
        2'd1: op59 <= rdc29;
        2'd2: op59 <= rdc59;
        2'd3: op59 <= rdc61;
        default: op59 <= rdc27;
    endcase
    logic [51:0] op60;
    always_ff @(posedge clk) case (rc60)
        4'd0: op60 <= rdc14;
        4'd1: op60 <= rdc22;
        4'd2: op60 <= rdc26;
        4'd3: op60 <= rdc28;
        4'd4: op60 <= rdc30;
        4'd5: op60 <= rdc46;
        4'd6: op60 <= rdc54;
        4'd7: op60 <= rdc58;
        4'd8: op60 <= rdc60;
        4'd9: op60 <= rdc62;
        default: op60 <= rdc14;
    endcase
    logic [51:0] op61;
    always_ff @(posedge clk) case (rc61)
        2'd0: op61 <= rdc29;
        2'd1: op61 <= rdc30;
        2'd2: op61 <= rdc61;
        2'd3: op61 <= rdc62;
        default: op61 <= rdc29;
    endcase
    logic [51:0] op62;
    always_ff @(posedge clk) case (rc62)
        4'd0: op62 <= rdc15;
        4'd1: op62 <= rdc23;
        4'd2: op62 <= rdc27;
        4'd3: op62 <= rdc29;
        4'd4: op62 <= rdc30;
        4'd5: op62 <= rdc31;
        4'd6: op62 <= rdc47;
        4'd7: op62 <= rdc55;
        4'd8: op62 <= rdc59;
        4'd9: op62 <= rdc61;
        4'd10: op62 <= rdc62;
        4'd11: op62 <= rdc63;
        default: op62 <= rdc15;
    endcase
    logic [51:0] op63;
    always_ff @(posedge clk) case (rc63)
        1'd0: op63 <= rdc31;
        1'd1: op63 <= rdc63;
        default: op63 <= rdc31;
    endcase
    // ---- twiddle tables (two per butterfly: stages > b, and the stage constants of stages <= b),
    // addresses = twiddleIndex (+ the inverse half); the choice registered with the data
    (* max_fanout = 16 *) logic [10:0] ta, ta0; (* max_fanout = 16 *) logic [2:0] tca;
    always_ff @(posedge clk) ta <= tidx_of(s, DIR_r ? ~tau : tau);
    always_ff @(posedge clk) ta0 <= tidx_of(s, DIR_r ? 10'(-tau) : tau);
    always_ff @(posedge clk) tca <= 3'(s);
    logic tsel [3]; always_ff @(posedge clk) begin tsel[0] <= s > 4'd5; for (int i = 1; i <= 2; i++) tsel[i] <= tsel[i-1]; end
    logic tsel_r; assign tsel_r = tsel[2];
    // ---- table write ports from the record stream (IterativeNTT.rnsRecord order)
    logic [11:0] lw_rest; assign lw_rest = 12'(lk >> 2);
    function automatic logic [10:0] lwa_t_of(input logic [3:0] s_, input logic [11:0] r_);
        case (s_)
            4'd6: lwa_t_of = 11'd0 + 11'(r_ & 12'h1);
            4'd7: lwa_t_of = 11'd2 + 11'(r_ & 12'h3);
            4'd8: lwa_t_of = 11'd6 + 11'(r_ & 12'h7);
            4'd9: lwa_t_of = 11'd14 + 11'(r_ & 12'hf);
            4'd10: lwa_t_of = 11'd30 + 11'(r_ & 12'h1f);
            4'd11: lwa_t_of = 11'd62 + 11'(r_ & 12'h3f);
            4'd12: lwa_t_of = 11'd126 + 11'(r_ & 12'h7f);
            4'd13: lwa_t_of = 11'd254 + 11'(r_ & 12'hff);
            4'd14: lwa_t_of = 11'd510 + 11'(r_ & 12'h1ff);
            4'd15: lwa_t_of = 11'd1022 + 11'(r_ & 12'h3ff);
            default: lwa_t_of = '0;
        endcase
    endfunction
    function automatic logic [2:0] lwa_c_of(input logic [3:0] s_, input logic [11:0] r_);
        lwa_c_of = 3'(s_);
    endfunction
    (* max_fanout = 16 *) logic [10:0] lw_wa_t; (* max_fanout = 16 *) logic [2:0] lw_wa_c;
    logic lw_go, lw_t; assign lw_go = tacc && (lst == L_DATA); assign lw_t = ls > 4'd5;
    always_ff @(posedge clk) begin lw_wa_t <= {lwa_t_of(ls, lw_rest)}; lw_wa_c <= {lwa_c_of(ls, lw_rest)}; end
    logic lw_wet0, lw_wec0; logic [51:0] lw_wd0;
    always_ff @(posedge clk) begin lw_wet0 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec0 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd0 <= tw_data[51:0]; end
    logic lw_wet1, lw_wec1; logic [51:0] lw_wd1;
    always_ff @(posedge clk) begin lw_wet1 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec1 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd1 <= tw_data[103:52]; end
    logic lw_wet2, lw_wec2; logic [51:0] lw_wd2;
    always_ff @(posedge clk) begin lw_wet2 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec2 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd2 <= tw_data[155:104]; end
    logic lw_wet3, lw_wec3; logic [51:0] lw_wd3;
    always_ff @(posedge clk) begin lw_wet3 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec3 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd3 <= tw_data[207:156]; end
    logic lw_wet4, lw_wec4; logic [51:0] lw_wd4;
    always_ff @(posedge clk) begin lw_wet4 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec4 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd4 <= tw_data[259:208]; end
    logic lw_wet5, lw_wec5; logic [51:0] lw_wd5;
    always_ff @(posedge clk) begin lw_wet5 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec5 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd5 <= tw_data[311:260]; end
    logic lw_wet6, lw_wec6; logic [51:0] lw_wd6;
    always_ff @(posedge clk) begin lw_wet6 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec6 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd6 <= tw_data[363:312]; end
    logic lw_wet7, lw_wec7; logic [51:0] lw_wd7;
    always_ff @(posedge clk) begin lw_wet7 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec7 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd7 <= tw_data[415:364]; end
    logic lw_wet8, lw_wec8; logic [51:0] lw_wd8;
    always_ff @(posedge clk) begin lw_wet8 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec8 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd8 <= tw_data[51:0]; end
    logic lw_wet9, lw_wec9; logic [51:0] lw_wd9;
    always_ff @(posedge clk) begin lw_wet9 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec9 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd9 <= tw_data[103:52]; end
    logic lw_wet10, lw_wec10; logic [51:0] lw_wd10;
    always_ff @(posedge clk) begin lw_wet10 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec10 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd10 <= tw_data[155:104]; end
    logic lw_wet11, lw_wec11; logic [51:0] lw_wd11;
    always_ff @(posedge clk) begin lw_wet11 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec11 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd11 <= tw_data[207:156]; end
    logic lw_wet12, lw_wec12; logic [51:0] lw_wd12;
    always_ff @(posedge clk) begin lw_wet12 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec12 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd12 <= tw_data[259:208]; end
    logic lw_wet13, lw_wec13; logic [51:0] lw_wd13;
    always_ff @(posedge clk) begin lw_wet13 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec13 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd13 <= tw_data[311:260]; end
    logic lw_wet14, lw_wec14; logic [51:0] lw_wd14;
    always_ff @(posedge clk) begin lw_wet14 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec14 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd14 <= tw_data[363:312]; end
    logic lw_wet15, lw_wec15; logic [51:0] lw_wd15;
    always_ff @(posedge clk) begin lw_wet15 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec15 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd15 <= tw_data[415:364]; end
    logic lw_wet16, lw_wec16; logic [51:0] lw_wd16;
    always_ff @(posedge clk) begin lw_wet16 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec16 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd16 <= tw_data[51:0]; end
    logic lw_wet17, lw_wec17; logic [51:0] lw_wd17;
    always_ff @(posedge clk) begin lw_wet17 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec17 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd17 <= tw_data[103:52]; end
    logic lw_wet18, lw_wec18; logic [51:0] lw_wd18;
    always_ff @(posedge clk) begin lw_wet18 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec18 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd18 <= tw_data[155:104]; end
    logic lw_wet19, lw_wec19; logic [51:0] lw_wd19;
    always_ff @(posedge clk) begin lw_wet19 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec19 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd19 <= tw_data[207:156]; end
    logic lw_wet20, lw_wec20; logic [51:0] lw_wd20;
    always_ff @(posedge clk) begin lw_wet20 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec20 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd20 <= tw_data[259:208]; end
    logic lw_wet21, lw_wec21; logic [51:0] lw_wd21;
    always_ff @(posedge clk) begin lw_wet21 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec21 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd21 <= tw_data[311:260]; end
    logic lw_wet22, lw_wec22; logic [51:0] lw_wd22;
    always_ff @(posedge clk) begin lw_wet22 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec22 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd22 <= tw_data[363:312]; end
    logic lw_wet23, lw_wec23; logic [51:0] lw_wd23;
    always_ff @(posedge clk) begin lw_wet23 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec23 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd23 <= tw_data[415:364]; end
    logic lw_wet24, lw_wec24; logic [51:0] lw_wd24;
    always_ff @(posedge clk) begin lw_wet24 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec24 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd24 <= tw_data[51:0]; end
    logic lw_wet25, lw_wec25; logic [51:0] lw_wd25;
    always_ff @(posedge clk) begin lw_wet25 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec25 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd25 <= tw_data[103:52]; end
    logic lw_wet26, lw_wec26; logic [51:0] lw_wd26;
    always_ff @(posedge clk) begin lw_wet26 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec26 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd26 <= tw_data[155:104]; end
    logic lw_wet27, lw_wec27; logic [51:0] lw_wd27;
    always_ff @(posedge clk) begin lw_wet27 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec27 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd27 <= tw_data[207:156]; end
    logic lw_wet28, lw_wec28; logic [51:0] lw_wd28;
    always_ff @(posedge clk) begin lw_wet28 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec28 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd28 <= tw_data[259:208]; end
    logic lw_wet29, lw_wec29; logic [51:0] lw_wd29;
    always_ff @(posedge clk) begin lw_wet29 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec29 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd29 <= tw_data[311:260]; end
    logic lw_wet30, lw_wec30; logic [51:0] lw_wd30;
    always_ff @(posedge clk) begin lw_wet30 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec30 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd30 <= tw_data[363:312]; end
    logic lw_wet31, lw_wec31; logic [51:0] lw_wd31;
    always_ff @(posedge clk) begin lw_wet31 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec31 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd31 <= tw_data[415:364]; end
    logic [51:0] twr0, tcr0, twr0_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw0 (.clk(clk), .addr(ta0), .we(lw_wet0), .wa(lw_wa_t), .wd(lw_wd0), .q0(twr0));
    Id_n65536_q52w_B32_rns_twr1 u_tc0 (.clk(clk), .addr(tca), .we(lw_wec0), .wa(lw_wa_c), .wd(lw_wd0), .q0(tcr0));
    logic [51:0] twr1, tcr1, twr1_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw1 (.clk(clk), .addr(ta), .we(lw_wet1), .wa(lw_wa_t), .wd(lw_wd1), .q0(twr1));
    Id_n65536_q52w_B32_rns_twr1 u_tc1 (.clk(clk), .addr(tca), .we(lw_wec1), .wa(lw_wa_c), .wd(lw_wd1), .q0(tcr1));
    logic [51:0] twr2, tcr2, twr2_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw2 (.clk(clk), .addr(ta), .we(lw_wet2), .wa(lw_wa_t), .wd(lw_wd2), .q0(twr2));
    Id_n65536_q52w_B32_rns_twr1 u_tc2 (.clk(clk), .addr(tca), .we(lw_wec2), .wa(lw_wa_c), .wd(lw_wd2), .q0(tcr2));
    logic [51:0] twr3, tcr3, twr3_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw3 (.clk(clk), .addr(ta), .we(lw_wet3), .wa(lw_wa_t), .wd(lw_wd3), .q0(twr3));
    Id_n65536_q52w_B32_rns_twr1 u_tc3 (.clk(clk), .addr(tca), .we(lw_wec3), .wa(lw_wa_c), .wd(lw_wd3), .q0(tcr3));
    logic [51:0] twr4, tcr4, twr4_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw4 (.clk(clk), .addr(ta), .we(lw_wet4), .wa(lw_wa_t), .wd(lw_wd4), .q0(twr4));
    Id_n65536_q52w_B32_rns_twr1 u_tc4 (.clk(clk), .addr(tca), .we(lw_wec4), .wa(lw_wa_c), .wd(lw_wd4), .q0(tcr4));
    logic [51:0] twr5, tcr5, twr5_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw5 (.clk(clk), .addr(ta), .we(lw_wet5), .wa(lw_wa_t), .wd(lw_wd5), .q0(twr5));
    Id_n65536_q52w_B32_rns_twr1 u_tc5 (.clk(clk), .addr(tca), .we(lw_wec5), .wa(lw_wa_c), .wd(lw_wd5), .q0(tcr5));
    logic [51:0] twr6, tcr6, twr6_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw6 (.clk(clk), .addr(ta), .we(lw_wet6), .wa(lw_wa_t), .wd(lw_wd6), .q0(twr6));
    Id_n65536_q52w_B32_rns_twr1 u_tc6 (.clk(clk), .addr(tca), .we(lw_wec6), .wa(lw_wa_c), .wd(lw_wd6), .q0(tcr6));
    logic [51:0] twr7, tcr7, twr7_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw7 (.clk(clk), .addr(ta), .we(lw_wet7), .wa(lw_wa_t), .wd(lw_wd7), .q0(twr7));
    Id_n65536_q52w_B32_rns_twr1 u_tc7 (.clk(clk), .addr(tca), .we(lw_wec7), .wa(lw_wa_c), .wd(lw_wd7), .q0(tcr7));
    logic [51:0] twr8, tcr8, twr8_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw8 (.clk(clk), .addr(ta), .we(lw_wet8), .wa(lw_wa_t), .wd(lw_wd8), .q0(twr8));
    Id_n65536_q52w_B32_rns_twr1 u_tc8 (.clk(clk), .addr(tca), .we(lw_wec8), .wa(lw_wa_c), .wd(lw_wd8), .q0(tcr8));
    logic [51:0] twr9, tcr9, twr9_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw9 (.clk(clk), .addr(ta), .we(lw_wet9), .wa(lw_wa_t), .wd(lw_wd9), .q0(twr9));
    Id_n65536_q52w_B32_rns_twr1 u_tc9 (.clk(clk), .addr(tca), .we(lw_wec9), .wa(lw_wa_c), .wd(lw_wd9), .q0(tcr9));
    logic [51:0] twr10, tcr10, twr10_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw10 (.clk(clk), .addr(ta), .we(lw_wet10), .wa(lw_wa_t), .wd(lw_wd10), .q0(twr10));
    Id_n65536_q52w_B32_rns_twr1 u_tc10 (.clk(clk), .addr(tca), .we(lw_wec10), .wa(lw_wa_c), .wd(lw_wd10), .q0(tcr10));
    logic [51:0] twr11, tcr11, twr11_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw11 (.clk(clk), .addr(ta), .we(lw_wet11), .wa(lw_wa_t), .wd(lw_wd11), .q0(twr11));
    Id_n65536_q52w_B32_rns_twr1 u_tc11 (.clk(clk), .addr(tca), .we(lw_wec11), .wa(lw_wa_c), .wd(lw_wd11), .q0(tcr11));
    logic [51:0] twr12, tcr12, twr12_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw12 (.clk(clk), .addr(ta), .we(lw_wet12), .wa(lw_wa_t), .wd(lw_wd12), .q0(twr12));
    Id_n65536_q52w_B32_rns_twr1 u_tc12 (.clk(clk), .addr(tca), .we(lw_wec12), .wa(lw_wa_c), .wd(lw_wd12), .q0(tcr12));
    logic [51:0] twr13, tcr13, twr13_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw13 (.clk(clk), .addr(ta), .we(lw_wet13), .wa(lw_wa_t), .wd(lw_wd13), .q0(twr13));
    Id_n65536_q52w_B32_rns_twr1 u_tc13 (.clk(clk), .addr(tca), .we(lw_wec13), .wa(lw_wa_c), .wd(lw_wd13), .q0(tcr13));
    logic [51:0] twr14, tcr14, twr14_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw14 (.clk(clk), .addr(ta), .we(lw_wet14), .wa(lw_wa_t), .wd(lw_wd14), .q0(twr14));
    Id_n65536_q52w_B32_rns_twr1 u_tc14 (.clk(clk), .addr(tca), .we(lw_wec14), .wa(lw_wa_c), .wd(lw_wd14), .q0(tcr14));
    logic [51:0] twr15, tcr15, twr15_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw15 (.clk(clk), .addr(ta), .we(lw_wet15), .wa(lw_wa_t), .wd(lw_wd15), .q0(twr15));
    Id_n65536_q52w_B32_rns_twr1 u_tc15 (.clk(clk), .addr(tca), .we(lw_wec15), .wa(lw_wa_c), .wd(lw_wd15), .q0(tcr15));
    logic [51:0] twr16, tcr16, twr16_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw16 (.clk(clk), .addr(ta), .we(lw_wet16), .wa(lw_wa_t), .wd(lw_wd16), .q0(twr16));
    Id_n65536_q52w_B32_rns_twr1 u_tc16 (.clk(clk), .addr(tca), .we(lw_wec16), .wa(lw_wa_c), .wd(lw_wd16), .q0(tcr16));
    logic [51:0] twr17, tcr17, twr17_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw17 (.clk(clk), .addr(ta), .we(lw_wet17), .wa(lw_wa_t), .wd(lw_wd17), .q0(twr17));
    Id_n65536_q52w_B32_rns_twr1 u_tc17 (.clk(clk), .addr(tca), .we(lw_wec17), .wa(lw_wa_c), .wd(lw_wd17), .q0(tcr17));
    logic [51:0] twr18, tcr18, twr18_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw18 (.clk(clk), .addr(ta), .we(lw_wet18), .wa(lw_wa_t), .wd(lw_wd18), .q0(twr18));
    Id_n65536_q52w_B32_rns_twr1 u_tc18 (.clk(clk), .addr(tca), .we(lw_wec18), .wa(lw_wa_c), .wd(lw_wd18), .q0(tcr18));
    logic [51:0] twr19, tcr19, twr19_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw19 (.clk(clk), .addr(ta), .we(lw_wet19), .wa(lw_wa_t), .wd(lw_wd19), .q0(twr19));
    Id_n65536_q52w_B32_rns_twr1 u_tc19 (.clk(clk), .addr(tca), .we(lw_wec19), .wa(lw_wa_c), .wd(lw_wd19), .q0(tcr19));
    logic [51:0] twr20, tcr20, twr20_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw20 (.clk(clk), .addr(ta), .we(lw_wet20), .wa(lw_wa_t), .wd(lw_wd20), .q0(twr20));
    Id_n65536_q52w_B32_rns_twr1 u_tc20 (.clk(clk), .addr(tca), .we(lw_wec20), .wa(lw_wa_c), .wd(lw_wd20), .q0(tcr20));
    logic [51:0] twr21, tcr21, twr21_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw21 (.clk(clk), .addr(ta), .we(lw_wet21), .wa(lw_wa_t), .wd(lw_wd21), .q0(twr21));
    Id_n65536_q52w_B32_rns_twr1 u_tc21 (.clk(clk), .addr(tca), .we(lw_wec21), .wa(lw_wa_c), .wd(lw_wd21), .q0(tcr21));
    logic [51:0] twr22, tcr22, twr22_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw22 (.clk(clk), .addr(ta), .we(lw_wet22), .wa(lw_wa_t), .wd(lw_wd22), .q0(twr22));
    Id_n65536_q52w_B32_rns_twr1 u_tc22 (.clk(clk), .addr(tca), .we(lw_wec22), .wa(lw_wa_c), .wd(lw_wd22), .q0(tcr22));
    logic [51:0] twr23, tcr23, twr23_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw23 (.clk(clk), .addr(ta), .we(lw_wet23), .wa(lw_wa_t), .wd(lw_wd23), .q0(twr23));
    Id_n65536_q52w_B32_rns_twr1 u_tc23 (.clk(clk), .addr(tca), .we(lw_wec23), .wa(lw_wa_c), .wd(lw_wd23), .q0(tcr23));
    logic [51:0] twr24, tcr24, twr24_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw24 (.clk(clk), .addr(ta), .we(lw_wet24), .wa(lw_wa_t), .wd(lw_wd24), .q0(twr24));
    Id_n65536_q52w_B32_rns_twr1 u_tc24 (.clk(clk), .addr(tca), .we(lw_wec24), .wa(lw_wa_c), .wd(lw_wd24), .q0(tcr24));
    logic [51:0] twr25, tcr25, twr25_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw25 (.clk(clk), .addr(ta), .we(lw_wet25), .wa(lw_wa_t), .wd(lw_wd25), .q0(twr25));
    Id_n65536_q52w_B32_rns_twr1 u_tc25 (.clk(clk), .addr(tca), .we(lw_wec25), .wa(lw_wa_c), .wd(lw_wd25), .q0(tcr25));
    logic [51:0] twr26, tcr26, twr26_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw26 (.clk(clk), .addr(ta), .we(lw_wet26), .wa(lw_wa_t), .wd(lw_wd26), .q0(twr26));
    Id_n65536_q52w_B32_rns_twr1 u_tc26 (.clk(clk), .addr(tca), .we(lw_wec26), .wa(lw_wa_c), .wd(lw_wd26), .q0(tcr26));
    logic [51:0] twr27, tcr27, twr27_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw27 (.clk(clk), .addr(ta), .we(lw_wet27), .wa(lw_wa_t), .wd(lw_wd27), .q0(twr27));
    Id_n65536_q52w_B32_rns_twr1 u_tc27 (.clk(clk), .addr(tca), .we(lw_wec27), .wa(lw_wa_c), .wd(lw_wd27), .q0(tcr27));
    logic [51:0] twr28, tcr28, twr28_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw28 (.clk(clk), .addr(ta), .we(lw_wet28), .wa(lw_wa_t), .wd(lw_wd28), .q0(twr28));
    Id_n65536_q52w_B32_rns_twr1 u_tc28 (.clk(clk), .addr(tca), .we(lw_wec28), .wa(lw_wa_c), .wd(lw_wd28), .q0(tcr28));
    logic [51:0] twr29, tcr29, twr29_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw29 (.clk(clk), .addr(ta), .we(lw_wet29), .wa(lw_wa_t), .wd(lw_wd29), .q0(twr29));
    Id_n65536_q52w_B32_rns_twr1 u_tc29 (.clk(clk), .addr(tca), .we(lw_wec29), .wa(lw_wa_c), .wd(lw_wd29), .q0(tcr29));
    logic [51:0] twr30, tcr30, twr30_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw30 (.clk(clk), .addr(ta), .we(lw_wet30), .wa(lw_wa_t), .wd(lw_wd30), .q0(twr30));
    Id_n65536_q52w_B32_rns_twr1 u_tc30 (.clk(clk), .addr(tca), .we(lw_wec30), .wa(lw_wa_c), .wd(lw_wd30), .q0(tcr30));
    logic [51:0] twr31, tcr31, twr31_q;
    Id_n65536_q52w_B32_rns_twr0 u_tw31 (.clk(clk), .addr(ta), .we(lw_wet31), .wa(lw_wa_t), .wd(lw_wd31), .q0(twr31));
    Id_n65536_q52w_B32_rns_twr1 u_tc31 (.clk(clk), .addr(tca), .we(lw_wec31), .wa(lw_wa_c), .wd(lw_wd31), .q0(tcr31));
    always_ff @(posedge clk) twr0_q <= tsel_r ? twr0 : tcr0;
    always_ff @(posedge clk) twr1_q <= tsel_r ? (DIR_r ? twr31 : twr1) : (DIR_r ? tcr31 : tcr1);
    always_ff @(posedge clk) twr2_q <= tsel_r ? (DIR_r ? twr30 : twr2) : (DIR_r ? tcr30 : tcr2);
    always_ff @(posedge clk) twr3_q <= tsel_r ? (DIR_r ? twr29 : twr3) : (DIR_r ? tcr29 : tcr3);
    always_ff @(posedge clk) twr4_q <= tsel_r ? (DIR_r ? twr28 : twr4) : (DIR_r ? tcr28 : tcr4);
    always_ff @(posedge clk) twr5_q <= tsel_r ? (DIR_r ? twr27 : twr5) : (DIR_r ? tcr27 : tcr5);
    always_ff @(posedge clk) twr6_q <= tsel_r ? (DIR_r ? twr26 : twr6) : (DIR_r ? tcr26 : tcr6);
    always_ff @(posedge clk) twr7_q <= tsel_r ? (DIR_r ? twr25 : twr7) : (DIR_r ? tcr25 : tcr7);
    always_ff @(posedge clk) twr8_q <= tsel_r ? (DIR_r ? twr24 : twr8) : (DIR_r ? tcr24 : tcr8);
    always_ff @(posedge clk) twr9_q <= tsel_r ? (DIR_r ? twr23 : twr9) : (DIR_r ? tcr23 : tcr9);
    always_ff @(posedge clk) twr10_q <= tsel_r ? (DIR_r ? twr22 : twr10) : (DIR_r ? tcr22 : tcr10);
    always_ff @(posedge clk) twr11_q <= tsel_r ? (DIR_r ? twr21 : twr11) : (DIR_r ? tcr21 : tcr11);
    always_ff @(posedge clk) twr12_q <= tsel_r ? (DIR_r ? twr20 : twr12) : (DIR_r ? tcr20 : tcr12);
    always_ff @(posedge clk) twr13_q <= tsel_r ? (DIR_r ? twr19 : twr13) : (DIR_r ? tcr19 : tcr13);
    always_ff @(posedge clk) twr14_q <= tsel_r ? (DIR_r ? twr18 : twr14) : (DIR_r ? tcr18 : tcr14);
    always_ff @(posedge clk) twr15_q <= tsel_r ? (DIR_r ? twr17 : twr15) : (DIR_r ? tcr17 : tcr15);
    always_ff @(posedge clk) twr16_q <= tsel_r ? twr16 : tcr16;
    always_ff @(posedge clk) twr17_q <= tsel_r ? (DIR_r ? twr15 : twr17) : (DIR_r ? tcr15 : tcr17);
    always_ff @(posedge clk) twr18_q <= tsel_r ? (DIR_r ? twr14 : twr18) : (DIR_r ? tcr14 : tcr18);
    always_ff @(posedge clk) twr19_q <= tsel_r ? (DIR_r ? twr13 : twr19) : (DIR_r ? tcr13 : tcr19);
    always_ff @(posedge clk) twr20_q <= tsel_r ? (DIR_r ? twr12 : twr20) : (DIR_r ? tcr12 : tcr20);
    always_ff @(posedge clk) twr21_q <= tsel_r ? (DIR_r ? twr11 : twr21) : (DIR_r ? tcr11 : tcr21);
    always_ff @(posedge clk) twr22_q <= tsel_r ? (DIR_r ? twr10 : twr22) : (DIR_r ? tcr10 : tcr22);
    always_ff @(posedge clk) twr23_q <= tsel_r ? (DIR_r ? twr9 : twr23) : (DIR_r ? tcr9 : tcr23);
    always_ff @(posedge clk) twr24_q <= tsel_r ? (DIR_r ? twr8 : twr24) : (DIR_r ? tcr8 : tcr24);
    always_ff @(posedge clk) twr25_q <= tsel_r ? (DIR_r ? twr7 : twr25) : (DIR_r ? tcr7 : tcr25);
    always_ff @(posedge clk) twr26_q <= tsel_r ? (DIR_r ? twr6 : twr26) : (DIR_r ? tcr6 : tcr26);
    always_ff @(posedge clk) twr27_q <= tsel_r ? (DIR_r ? twr5 : twr27) : (DIR_r ? tcr5 : tcr27);
    always_ff @(posedge clk) twr28_q <= tsel_r ? (DIR_r ? twr4 : twr28) : (DIR_r ? tcr4 : tcr28);
    always_ff @(posedge clk) twr29_q <= tsel_r ? (DIR_r ? twr3 : twr29) : (DIR_r ? tcr3 : tcr29);
    always_ff @(posedge clk) twr30_q <= tsel_r ? (DIR_r ? twr2 : twr30) : (DIR_r ? tcr2 : tcr30);
    always_ff @(posedge clk) twr31_q <= tsel_r ? (DIR_r ? twr1 : twr31) : (DIR_r ? tcr1 : tcr31);
    // ---- 32 butterflies (Id_n65536_q52w_B32_rns_bu, latency 17), output register / x2^-1 halver
    (* max_fanout = 16 *) logic [25:0] b0q_QH;
    always_ff @(posedge clk) b0q_QH <= QH_r;
    logic [51:0] xr0; logic [51:0] yr0;
    Id_n65536_q52w_B32_rns_bu u_bu0 (.clk(clk), .aIn(op0), .bIn(op1), .W(twr0_q), .QH(b0q_QH), .aOut(xr0), .bOut(yr0));
    logic [51:0] xo0, xo0_x; assign xo0_x = (cb_sw[20][0] ? yr0 : xr0);
    (* max_fanout = 16 *) logic [51:0] b0q_QHALF;
    always_ff @(posedge clk) b0q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo0 <= DIR_r ? (52'(xo0_x >> 1) + (xo0_x[0] ? 52'(b0q_QHALF) : 52'd0)) : xo0_x;
    logic [51:0] yo0, yo0_x; assign yo0_x = (cb_sw[20][0] ? xr0 : yr0);
    always_ff @(posedge clk) yo0 <= DIR_r ? (52'(yo0_x >> 1) + (yo0_x[0] ? 52'(b0q_QHALF) : 52'd0)) : yo0_x;
    (* max_fanout = 16 *) logic [25:0] b1q_QH;
    always_ff @(posedge clk) b1q_QH <= QH_r;
    logic [51:0] xr1; logic [51:0] yr1;
    Id_n65536_q52w_B32_rns_bu u_bu1 (.clk(clk), .aIn(op2), .bIn(op3), .W(twr1_q), .QH(b1q_QH), .aOut(xr1), .bOut(yr1));
    logic [51:0] xo1, xo1_x; assign xo1_x = (cb_sw[20][1] ? yr1 : xr1);
    (* max_fanout = 16 *) logic [51:0] b1q_QHALF;
    always_ff @(posedge clk) b1q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo1 <= DIR_r ? (52'(xo1_x >> 1) + (xo1_x[0] ? 52'(b1q_QHALF) : 52'd0)) : xo1_x;
    logic [51:0] yo1, yo1_x; assign yo1_x = (cb_sw[20][1] ? xr1 : yr1);
    always_ff @(posedge clk) yo1 <= DIR_r ? (52'(yo1_x >> 1) + (yo1_x[0] ? 52'(b1q_QHALF) : 52'd0)) : yo1_x;
    (* max_fanout = 16 *) logic [25:0] b2q_QH;
    always_ff @(posedge clk) b2q_QH <= QH_r;
    logic [51:0] xr2; logic [51:0] yr2;
    Id_n65536_q52w_B32_rns_bu u_bu2 (.clk(clk), .aIn(op4), .bIn(op5), .W(twr2_q), .QH(b2q_QH), .aOut(xr2), .bOut(yr2));
    logic [51:0] xo2, xo2_x; assign xo2_x = (cb_sw[20][2] ? yr2 : xr2);
    (* max_fanout = 16 *) logic [51:0] b2q_QHALF;
    always_ff @(posedge clk) b2q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo2 <= DIR_r ? (52'(xo2_x >> 1) + (xo2_x[0] ? 52'(b2q_QHALF) : 52'd0)) : xo2_x;
    logic [51:0] yo2, yo2_x; assign yo2_x = (cb_sw[20][2] ? xr2 : yr2);
    always_ff @(posedge clk) yo2 <= DIR_r ? (52'(yo2_x >> 1) + (yo2_x[0] ? 52'(b2q_QHALF) : 52'd0)) : yo2_x;
    (* max_fanout = 16 *) logic [25:0] b3q_QH;
    always_ff @(posedge clk) b3q_QH <= QH_r;
    logic [51:0] xr3; logic [51:0] yr3;
    Id_n65536_q52w_B32_rns_bu u_bu3 (.clk(clk), .aIn(op6), .bIn(op7), .W(twr3_q), .QH(b3q_QH), .aOut(xr3), .bOut(yr3));
    logic [51:0] xo3, xo3_x; assign xo3_x = (cb_sw[20][3] ? yr3 : xr3);
    (* max_fanout = 16 *) logic [51:0] b3q_QHALF;
    always_ff @(posedge clk) b3q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo3 <= DIR_r ? (52'(xo3_x >> 1) + (xo3_x[0] ? 52'(b3q_QHALF) : 52'd0)) : xo3_x;
    logic [51:0] yo3, yo3_x; assign yo3_x = (cb_sw[20][3] ? xr3 : yr3);
    always_ff @(posedge clk) yo3 <= DIR_r ? (52'(yo3_x >> 1) + (yo3_x[0] ? 52'(b3q_QHALF) : 52'd0)) : yo3_x;
    (* max_fanout = 16 *) logic [25:0] b4q_QH;
    always_ff @(posedge clk) b4q_QH <= QH_r;
    logic [51:0] xr4; logic [51:0] yr4;
    Id_n65536_q52w_B32_rns_bu u_bu4 (.clk(clk), .aIn(op8), .bIn(op9), .W(twr4_q), .QH(b4q_QH), .aOut(xr4), .bOut(yr4));
    logic [51:0] xo4, xo4_x; assign xo4_x = (cb_sw[20][4] ? yr4 : xr4);
    (* max_fanout = 16 *) logic [51:0] b4q_QHALF;
    always_ff @(posedge clk) b4q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo4 <= DIR_r ? (52'(xo4_x >> 1) + (xo4_x[0] ? 52'(b4q_QHALF) : 52'd0)) : xo4_x;
    logic [51:0] yo4, yo4_x; assign yo4_x = (cb_sw[20][4] ? xr4 : yr4);
    always_ff @(posedge clk) yo4 <= DIR_r ? (52'(yo4_x >> 1) + (yo4_x[0] ? 52'(b4q_QHALF) : 52'd0)) : yo4_x;
    (* max_fanout = 16 *) logic [25:0] b5q_QH;
    always_ff @(posedge clk) b5q_QH <= QH_r;
    logic [51:0] xr5; logic [51:0] yr5;
    Id_n65536_q52w_B32_rns_bu u_bu5 (.clk(clk), .aIn(op10), .bIn(op11), .W(twr5_q), .QH(b5q_QH), .aOut(xr5), .bOut(yr5));
    logic [51:0] xo5, xo5_x; assign xo5_x = (cb_sw[20][5] ? yr5 : xr5);
    (* max_fanout = 16 *) logic [51:0] b5q_QHALF;
    always_ff @(posedge clk) b5q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo5 <= DIR_r ? (52'(xo5_x >> 1) + (xo5_x[0] ? 52'(b5q_QHALF) : 52'd0)) : xo5_x;
    logic [51:0] yo5, yo5_x; assign yo5_x = (cb_sw[20][5] ? xr5 : yr5);
    always_ff @(posedge clk) yo5 <= DIR_r ? (52'(yo5_x >> 1) + (yo5_x[0] ? 52'(b5q_QHALF) : 52'd0)) : yo5_x;
    (* max_fanout = 16 *) logic [25:0] b6q_QH;
    always_ff @(posedge clk) b6q_QH <= QH_r;
    logic [51:0] xr6; logic [51:0] yr6;
    Id_n65536_q52w_B32_rns_bu u_bu6 (.clk(clk), .aIn(op12), .bIn(op13), .W(twr6_q), .QH(b6q_QH), .aOut(xr6), .bOut(yr6));
    logic [51:0] xo6, xo6_x; assign xo6_x = (cb_sw[20][6] ? yr6 : xr6);
    (* max_fanout = 16 *) logic [51:0] b6q_QHALF;
    always_ff @(posedge clk) b6q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo6 <= DIR_r ? (52'(xo6_x >> 1) + (xo6_x[0] ? 52'(b6q_QHALF) : 52'd0)) : xo6_x;
    logic [51:0] yo6, yo6_x; assign yo6_x = (cb_sw[20][6] ? xr6 : yr6);
    always_ff @(posedge clk) yo6 <= DIR_r ? (52'(yo6_x >> 1) + (yo6_x[0] ? 52'(b6q_QHALF) : 52'd0)) : yo6_x;
    (* max_fanout = 16 *) logic [25:0] b7q_QH;
    always_ff @(posedge clk) b7q_QH <= QH_r;
    logic [51:0] xr7; logic [51:0] yr7;
    Id_n65536_q52w_B32_rns_bu u_bu7 (.clk(clk), .aIn(op14), .bIn(op15), .W(twr7_q), .QH(b7q_QH), .aOut(xr7), .bOut(yr7));
    logic [51:0] xo7, xo7_x; assign xo7_x = (cb_sw[20][7] ? yr7 : xr7);
    (* max_fanout = 16 *) logic [51:0] b7q_QHALF;
    always_ff @(posedge clk) b7q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo7 <= DIR_r ? (52'(xo7_x >> 1) + (xo7_x[0] ? 52'(b7q_QHALF) : 52'd0)) : xo7_x;
    logic [51:0] yo7, yo7_x; assign yo7_x = (cb_sw[20][7] ? xr7 : yr7);
    always_ff @(posedge clk) yo7 <= DIR_r ? (52'(yo7_x >> 1) + (yo7_x[0] ? 52'(b7q_QHALF) : 52'd0)) : yo7_x;
    (* max_fanout = 16 *) logic [25:0] b8q_QH;
    always_ff @(posedge clk) b8q_QH <= QH_r;
    logic [51:0] xr8; logic [51:0] yr8;
    Id_n65536_q52w_B32_rns_bu u_bu8 (.clk(clk), .aIn(op16), .bIn(op17), .W(twr8_q), .QH(b8q_QH), .aOut(xr8), .bOut(yr8));
    logic [51:0] xo8, xo8_x; assign xo8_x = (cb_sw[20][8] ? yr8 : xr8);
    (* max_fanout = 16 *) logic [51:0] b8q_QHALF;
    always_ff @(posedge clk) b8q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo8 <= DIR_r ? (52'(xo8_x >> 1) + (xo8_x[0] ? 52'(b8q_QHALF) : 52'd0)) : xo8_x;
    logic [51:0] yo8, yo8_x; assign yo8_x = (cb_sw[20][8] ? xr8 : yr8);
    always_ff @(posedge clk) yo8 <= DIR_r ? (52'(yo8_x >> 1) + (yo8_x[0] ? 52'(b8q_QHALF) : 52'd0)) : yo8_x;
    (* max_fanout = 16 *) logic [25:0] b9q_QH;
    always_ff @(posedge clk) b9q_QH <= QH_r;
    logic [51:0] xr9; logic [51:0] yr9;
    Id_n65536_q52w_B32_rns_bu u_bu9 (.clk(clk), .aIn(op18), .bIn(op19), .W(twr9_q), .QH(b9q_QH), .aOut(xr9), .bOut(yr9));
    logic [51:0] xo9, xo9_x; assign xo9_x = (cb_sw[20][9] ? yr9 : xr9);
    (* max_fanout = 16 *) logic [51:0] b9q_QHALF;
    always_ff @(posedge clk) b9q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo9 <= DIR_r ? (52'(xo9_x >> 1) + (xo9_x[0] ? 52'(b9q_QHALF) : 52'd0)) : xo9_x;
    logic [51:0] yo9, yo9_x; assign yo9_x = (cb_sw[20][9] ? xr9 : yr9);
    always_ff @(posedge clk) yo9 <= DIR_r ? (52'(yo9_x >> 1) + (yo9_x[0] ? 52'(b9q_QHALF) : 52'd0)) : yo9_x;
    (* max_fanout = 16 *) logic [25:0] b10q_QH;
    always_ff @(posedge clk) b10q_QH <= QH_r;
    logic [51:0] xr10; logic [51:0] yr10;
    Id_n65536_q52w_B32_rns_bu u_bu10 (.clk(clk), .aIn(op20), .bIn(op21), .W(twr10_q), .QH(b10q_QH), .aOut(xr10), .bOut(yr10));
    logic [51:0] xo10, xo10_x; assign xo10_x = (cb_sw[20][10] ? yr10 : xr10);
    (* max_fanout = 16 *) logic [51:0] b10q_QHALF;
    always_ff @(posedge clk) b10q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo10 <= DIR_r ? (52'(xo10_x >> 1) + (xo10_x[0] ? 52'(b10q_QHALF) : 52'd0)) : xo10_x;
    logic [51:0] yo10, yo10_x; assign yo10_x = (cb_sw[20][10] ? xr10 : yr10);
    always_ff @(posedge clk) yo10 <= DIR_r ? (52'(yo10_x >> 1) + (yo10_x[0] ? 52'(b10q_QHALF) : 52'd0)) : yo10_x;
    (* max_fanout = 16 *) logic [25:0] b11q_QH;
    always_ff @(posedge clk) b11q_QH <= QH_r;
    logic [51:0] xr11; logic [51:0] yr11;
    Id_n65536_q52w_B32_rns_bu u_bu11 (.clk(clk), .aIn(op22), .bIn(op23), .W(twr11_q), .QH(b11q_QH), .aOut(xr11), .bOut(yr11));
    logic [51:0] xo11, xo11_x; assign xo11_x = (cb_sw[20][11] ? yr11 : xr11);
    (* max_fanout = 16 *) logic [51:0] b11q_QHALF;
    always_ff @(posedge clk) b11q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo11 <= DIR_r ? (52'(xo11_x >> 1) + (xo11_x[0] ? 52'(b11q_QHALF) : 52'd0)) : xo11_x;
    logic [51:0] yo11, yo11_x; assign yo11_x = (cb_sw[20][11] ? xr11 : yr11);
    always_ff @(posedge clk) yo11 <= DIR_r ? (52'(yo11_x >> 1) + (yo11_x[0] ? 52'(b11q_QHALF) : 52'd0)) : yo11_x;
    (* max_fanout = 16 *) logic [25:0] b12q_QH;
    always_ff @(posedge clk) b12q_QH <= QH_r;
    logic [51:0] xr12; logic [51:0] yr12;
    Id_n65536_q52w_B32_rns_bu u_bu12 (.clk(clk), .aIn(op24), .bIn(op25), .W(twr12_q), .QH(b12q_QH), .aOut(xr12), .bOut(yr12));
    logic [51:0] xo12, xo12_x; assign xo12_x = (cb_sw[20][12] ? yr12 : xr12);
    (* max_fanout = 16 *) logic [51:0] b12q_QHALF;
    always_ff @(posedge clk) b12q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo12 <= DIR_r ? (52'(xo12_x >> 1) + (xo12_x[0] ? 52'(b12q_QHALF) : 52'd0)) : xo12_x;
    logic [51:0] yo12, yo12_x; assign yo12_x = (cb_sw[20][12] ? xr12 : yr12);
    always_ff @(posedge clk) yo12 <= DIR_r ? (52'(yo12_x >> 1) + (yo12_x[0] ? 52'(b12q_QHALF) : 52'd0)) : yo12_x;
    (* max_fanout = 16 *) logic [25:0] b13q_QH;
    always_ff @(posedge clk) b13q_QH <= QH_r;
    logic [51:0] xr13; logic [51:0] yr13;
    Id_n65536_q52w_B32_rns_bu u_bu13 (.clk(clk), .aIn(op26), .bIn(op27), .W(twr13_q), .QH(b13q_QH), .aOut(xr13), .bOut(yr13));
    logic [51:0] xo13, xo13_x; assign xo13_x = (cb_sw[20][13] ? yr13 : xr13);
    (* max_fanout = 16 *) logic [51:0] b13q_QHALF;
    always_ff @(posedge clk) b13q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo13 <= DIR_r ? (52'(xo13_x >> 1) + (xo13_x[0] ? 52'(b13q_QHALF) : 52'd0)) : xo13_x;
    logic [51:0] yo13, yo13_x; assign yo13_x = (cb_sw[20][13] ? xr13 : yr13);
    always_ff @(posedge clk) yo13 <= DIR_r ? (52'(yo13_x >> 1) + (yo13_x[0] ? 52'(b13q_QHALF) : 52'd0)) : yo13_x;
    (* max_fanout = 16 *) logic [25:0] b14q_QH;
    always_ff @(posedge clk) b14q_QH <= QH_r;
    logic [51:0] xr14; logic [51:0] yr14;
    Id_n65536_q52w_B32_rns_bu u_bu14 (.clk(clk), .aIn(op28), .bIn(op29), .W(twr14_q), .QH(b14q_QH), .aOut(xr14), .bOut(yr14));
    logic [51:0] xo14, xo14_x; assign xo14_x = (cb_sw[20][14] ? yr14 : xr14);
    (* max_fanout = 16 *) logic [51:0] b14q_QHALF;
    always_ff @(posedge clk) b14q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo14 <= DIR_r ? (52'(xo14_x >> 1) + (xo14_x[0] ? 52'(b14q_QHALF) : 52'd0)) : xo14_x;
    logic [51:0] yo14, yo14_x; assign yo14_x = (cb_sw[20][14] ? xr14 : yr14);
    always_ff @(posedge clk) yo14 <= DIR_r ? (52'(yo14_x >> 1) + (yo14_x[0] ? 52'(b14q_QHALF) : 52'd0)) : yo14_x;
    (* max_fanout = 16 *) logic [25:0] b15q_QH;
    always_ff @(posedge clk) b15q_QH <= QH_r;
    logic [51:0] xr15; logic [51:0] yr15;
    Id_n65536_q52w_B32_rns_bu u_bu15 (.clk(clk), .aIn(op30), .bIn(op31), .W(twr15_q), .QH(b15q_QH), .aOut(xr15), .bOut(yr15));
    logic [51:0] xo15, xo15_x; assign xo15_x = (cb_sw[20][15] ? yr15 : xr15);
    (* max_fanout = 16 *) logic [51:0] b15q_QHALF;
    always_ff @(posedge clk) b15q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo15 <= DIR_r ? (52'(xo15_x >> 1) + (xo15_x[0] ? 52'(b15q_QHALF) : 52'd0)) : xo15_x;
    logic [51:0] yo15, yo15_x; assign yo15_x = (cb_sw[20][15] ? xr15 : yr15);
    always_ff @(posedge clk) yo15 <= DIR_r ? (52'(yo15_x >> 1) + (yo15_x[0] ? 52'(b15q_QHALF) : 52'd0)) : yo15_x;
    (* max_fanout = 16 *) logic [25:0] b16q_QH;
    always_ff @(posedge clk) b16q_QH <= QH_r;
    logic [51:0] xr16; logic [51:0] yr16;
    Id_n65536_q52w_B32_rns_bu u_bu16 (.clk(clk), .aIn(op32), .bIn(op33), .W(twr16_q), .QH(b16q_QH), .aOut(xr16), .bOut(yr16));
    logic [51:0] xo16, xo16_x; assign xo16_x = (cb_sw[20][16] ? yr16 : xr16);
    (* max_fanout = 16 *) logic [51:0] b16q_QHALF;
    always_ff @(posedge clk) b16q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo16 <= DIR_r ? (52'(xo16_x >> 1) + (xo16_x[0] ? 52'(b16q_QHALF) : 52'd0)) : xo16_x;
    logic [51:0] yo16, yo16_x; assign yo16_x = (cb_sw[20][16] ? xr16 : yr16);
    always_ff @(posedge clk) yo16 <= DIR_r ? (52'(yo16_x >> 1) + (yo16_x[0] ? 52'(b16q_QHALF) : 52'd0)) : yo16_x;
    (* max_fanout = 16 *) logic [25:0] b17q_QH;
    always_ff @(posedge clk) b17q_QH <= QH_r;
    logic [51:0] xr17; logic [51:0] yr17;
    Id_n65536_q52w_B32_rns_bu u_bu17 (.clk(clk), .aIn(op34), .bIn(op35), .W(twr17_q), .QH(b17q_QH), .aOut(xr17), .bOut(yr17));
    logic [51:0] xo17, xo17_x; assign xo17_x = (cb_sw[20][17] ? yr17 : xr17);
    (* max_fanout = 16 *) logic [51:0] b17q_QHALF;
    always_ff @(posedge clk) b17q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo17 <= DIR_r ? (52'(xo17_x >> 1) + (xo17_x[0] ? 52'(b17q_QHALF) : 52'd0)) : xo17_x;
    logic [51:0] yo17, yo17_x; assign yo17_x = (cb_sw[20][17] ? xr17 : yr17);
    always_ff @(posedge clk) yo17 <= DIR_r ? (52'(yo17_x >> 1) + (yo17_x[0] ? 52'(b17q_QHALF) : 52'd0)) : yo17_x;
    (* max_fanout = 16 *) logic [25:0] b18q_QH;
    always_ff @(posedge clk) b18q_QH <= QH_r;
    logic [51:0] xr18; logic [51:0] yr18;
    Id_n65536_q52w_B32_rns_bu u_bu18 (.clk(clk), .aIn(op36), .bIn(op37), .W(twr18_q), .QH(b18q_QH), .aOut(xr18), .bOut(yr18));
    logic [51:0] xo18, xo18_x; assign xo18_x = (cb_sw[20][18] ? yr18 : xr18);
    (* max_fanout = 16 *) logic [51:0] b18q_QHALF;
    always_ff @(posedge clk) b18q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo18 <= DIR_r ? (52'(xo18_x >> 1) + (xo18_x[0] ? 52'(b18q_QHALF) : 52'd0)) : xo18_x;
    logic [51:0] yo18, yo18_x; assign yo18_x = (cb_sw[20][18] ? xr18 : yr18);
    always_ff @(posedge clk) yo18 <= DIR_r ? (52'(yo18_x >> 1) + (yo18_x[0] ? 52'(b18q_QHALF) : 52'd0)) : yo18_x;
    (* max_fanout = 16 *) logic [25:0] b19q_QH;
    always_ff @(posedge clk) b19q_QH <= QH_r;
    logic [51:0] xr19; logic [51:0] yr19;
    Id_n65536_q52w_B32_rns_bu u_bu19 (.clk(clk), .aIn(op38), .bIn(op39), .W(twr19_q), .QH(b19q_QH), .aOut(xr19), .bOut(yr19));
    logic [51:0] xo19, xo19_x; assign xo19_x = (cb_sw[20][19] ? yr19 : xr19);
    (* max_fanout = 16 *) logic [51:0] b19q_QHALF;
    always_ff @(posedge clk) b19q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo19 <= DIR_r ? (52'(xo19_x >> 1) + (xo19_x[0] ? 52'(b19q_QHALF) : 52'd0)) : xo19_x;
    logic [51:0] yo19, yo19_x; assign yo19_x = (cb_sw[20][19] ? xr19 : yr19);
    always_ff @(posedge clk) yo19 <= DIR_r ? (52'(yo19_x >> 1) + (yo19_x[0] ? 52'(b19q_QHALF) : 52'd0)) : yo19_x;
    (* max_fanout = 16 *) logic [25:0] b20q_QH;
    always_ff @(posedge clk) b20q_QH <= QH_r;
    logic [51:0] xr20; logic [51:0] yr20;
    Id_n65536_q52w_B32_rns_bu u_bu20 (.clk(clk), .aIn(op40), .bIn(op41), .W(twr20_q), .QH(b20q_QH), .aOut(xr20), .bOut(yr20));
    logic [51:0] xo20, xo20_x; assign xo20_x = (cb_sw[20][20] ? yr20 : xr20);
    (* max_fanout = 16 *) logic [51:0] b20q_QHALF;
    always_ff @(posedge clk) b20q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo20 <= DIR_r ? (52'(xo20_x >> 1) + (xo20_x[0] ? 52'(b20q_QHALF) : 52'd0)) : xo20_x;
    logic [51:0] yo20, yo20_x; assign yo20_x = (cb_sw[20][20] ? xr20 : yr20);
    always_ff @(posedge clk) yo20 <= DIR_r ? (52'(yo20_x >> 1) + (yo20_x[0] ? 52'(b20q_QHALF) : 52'd0)) : yo20_x;
    (* max_fanout = 16 *) logic [25:0] b21q_QH;
    always_ff @(posedge clk) b21q_QH <= QH_r;
    logic [51:0] xr21; logic [51:0] yr21;
    Id_n65536_q52w_B32_rns_bu u_bu21 (.clk(clk), .aIn(op42), .bIn(op43), .W(twr21_q), .QH(b21q_QH), .aOut(xr21), .bOut(yr21));
    logic [51:0] xo21, xo21_x; assign xo21_x = (cb_sw[20][21] ? yr21 : xr21);
    (* max_fanout = 16 *) logic [51:0] b21q_QHALF;
    always_ff @(posedge clk) b21q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo21 <= DIR_r ? (52'(xo21_x >> 1) + (xo21_x[0] ? 52'(b21q_QHALF) : 52'd0)) : xo21_x;
    logic [51:0] yo21, yo21_x; assign yo21_x = (cb_sw[20][21] ? xr21 : yr21);
    always_ff @(posedge clk) yo21 <= DIR_r ? (52'(yo21_x >> 1) + (yo21_x[0] ? 52'(b21q_QHALF) : 52'd0)) : yo21_x;
    (* max_fanout = 16 *) logic [25:0] b22q_QH;
    always_ff @(posedge clk) b22q_QH <= QH_r;
    logic [51:0] xr22; logic [51:0] yr22;
    Id_n65536_q52w_B32_rns_bu u_bu22 (.clk(clk), .aIn(op44), .bIn(op45), .W(twr22_q), .QH(b22q_QH), .aOut(xr22), .bOut(yr22));
    logic [51:0] xo22, xo22_x; assign xo22_x = (cb_sw[20][22] ? yr22 : xr22);
    (* max_fanout = 16 *) logic [51:0] b22q_QHALF;
    always_ff @(posedge clk) b22q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo22 <= DIR_r ? (52'(xo22_x >> 1) + (xo22_x[0] ? 52'(b22q_QHALF) : 52'd0)) : xo22_x;
    logic [51:0] yo22, yo22_x; assign yo22_x = (cb_sw[20][22] ? xr22 : yr22);
    always_ff @(posedge clk) yo22 <= DIR_r ? (52'(yo22_x >> 1) + (yo22_x[0] ? 52'(b22q_QHALF) : 52'd0)) : yo22_x;
    (* max_fanout = 16 *) logic [25:0] b23q_QH;
    always_ff @(posedge clk) b23q_QH <= QH_r;
    logic [51:0] xr23; logic [51:0] yr23;
    Id_n65536_q52w_B32_rns_bu u_bu23 (.clk(clk), .aIn(op46), .bIn(op47), .W(twr23_q), .QH(b23q_QH), .aOut(xr23), .bOut(yr23));
    logic [51:0] xo23, xo23_x; assign xo23_x = (cb_sw[20][23] ? yr23 : xr23);
    (* max_fanout = 16 *) logic [51:0] b23q_QHALF;
    always_ff @(posedge clk) b23q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo23 <= DIR_r ? (52'(xo23_x >> 1) + (xo23_x[0] ? 52'(b23q_QHALF) : 52'd0)) : xo23_x;
    logic [51:0] yo23, yo23_x; assign yo23_x = (cb_sw[20][23] ? xr23 : yr23);
    always_ff @(posedge clk) yo23 <= DIR_r ? (52'(yo23_x >> 1) + (yo23_x[0] ? 52'(b23q_QHALF) : 52'd0)) : yo23_x;
    (* max_fanout = 16 *) logic [25:0] b24q_QH;
    always_ff @(posedge clk) b24q_QH <= QH_r;
    logic [51:0] xr24; logic [51:0] yr24;
    Id_n65536_q52w_B32_rns_bu u_bu24 (.clk(clk), .aIn(op48), .bIn(op49), .W(twr24_q), .QH(b24q_QH), .aOut(xr24), .bOut(yr24));
    logic [51:0] xo24, xo24_x; assign xo24_x = (cb_sw[20][24] ? yr24 : xr24);
    (* max_fanout = 16 *) logic [51:0] b24q_QHALF;
    always_ff @(posedge clk) b24q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo24 <= DIR_r ? (52'(xo24_x >> 1) + (xo24_x[0] ? 52'(b24q_QHALF) : 52'd0)) : xo24_x;
    logic [51:0] yo24, yo24_x; assign yo24_x = (cb_sw[20][24] ? xr24 : yr24);
    always_ff @(posedge clk) yo24 <= DIR_r ? (52'(yo24_x >> 1) + (yo24_x[0] ? 52'(b24q_QHALF) : 52'd0)) : yo24_x;
    (* max_fanout = 16 *) logic [25:0] b25q_QH;
    always_ff @(posedge clk) b25q_QH <= QH_r;
    logic [51:0] xr25; logic [51:0] yr25;
    Id_n65536_q52w_B32_rns_bu u_bu25 (.clk(clk), .aIn(op50), .bIn(op51), .W(twr25_q), .QH(b25q_QH), .aOut(xr25), .bOut(yr25));
    logic [51:0] xo25, xo25_x; assign xo25_x = (cb_sw[20][25] ? yr25 : xr25);
    (* max_fanout = 16 *) logic [51:0] b25q_QHALF;
    always_ff @(posedge clk) b25q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo25 <= DIR_r ? (52'(xo25_x >> 1) + (xo25_x[0] ? 52'(b25q_QHALF) : 52'd0)) : xo25_x;
    logic [51:0] yo25, yo25_x; assign yo25_x = (cb_sw[20][25] ? xr25 : yr25);
    always_ff @(posedge clk) yo25 <= DIR_r ? (52'(yo25_x >> 1) + (yo25_x[0] ? 52'(b25q_QHALF) : 52'd0)) : yo25_x;
    (* max_fanout = 16 *) logic [25:0] b26q_QH;
    always_ff @(posedge clk) b26q_QH <= QH_r;
    logic [51:0] xr26; logic [51:0] yr26;
    Id_n65536_q52w_B32_rns_bu u_bu26 (.clk(clk), .aIn(op52), .bIn(op53), .W(twr26_q), .QH(b26q_QH), .aOut(xr26), .bOut(yr26));
    logic [51:0] xo26, xo26_x; assign xo26_x = (cb_sw[20][26] ? yr26 : xr26);
    (* max_fanout = 16 *) logic [51:0] b26q_QHALF;
    always_ff @(posedge clk) b26q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo26 <= DIR_r ? (52'(xo26_x >> 1) + (xo26_x[0] ? 52'(b26q_QHALF) : 52'd0)) : xo26_x;
    logic [51:0] yo26, yo26_x; assign yo26_x = (cb_sw[20][26] ? xr26 : yr26);
    always_ff @(posedge clk) yo26 <= DIR_r ? (52'(yo26_x >> 1) + (yo26_x[0] ? 52'(b26q_QHALF) : 52'd0)) : yo26_x;
    (* max_fanout = 16 *) logic [25:0] b27q_QH;
    always_ff @(posedge clk) b27q_QH <= QH_r;
    logic [51:0] xr27; logic [51:0] yr27;
    Id_n65536_q52w_B32_rns_bu u_bu27 (.clk(clk), .aIn(op54), .bIn(op55), .W(twr27_q), .QH(b27q_QH), .aOut(xr27), .bOut(yr27));
    logic [51:0] xo27, xo27_x; assign xo27_x = (cb_sw[20][27] ? yr27 : xr27);
    (* max_fanout = 16 *) logic [51:0] b27q_QHALF;
    always_ff @(posedge clk) b27q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo27 <= DIR_r ? (52'(xo27_x >> 1) + (xo27_x[0] ? 52'(b27q_QHALF) : 52'd0)) : xo27_x;
    logic [51:0] yo27, yo27_x; assign yo27_x = (cb_sw[20][27] ? xr27 : yr27);
    always_ff @(posedge clk) yo27 <= DIR_r ? (52'(yo27_x >> 1) + (yo27_x[0] ? 52'(b27q_QHALF) : 52'd0)) : yo27_x;
    (* max_fanout = 16 *) logic [25:0] b28q_QH;
    always_ff @(posedge clk) b28q_QH <= QH_r;
    logic [51:0] xr28; logic [51:0] yr28;
    Id_n65536_q52w_B32_rns_bu u_bu28 (.clk(clk), .aIn(op56), .bIn(op57), .W(twr28_q), .QH(b28q_QH), .aOut(xr28), .bOut(yr28));
    logic [51:0] xo28, xo28_x; assign xo28_x = (cb_sw[20][28] ? yr28 : xr28);
    (* max_fanout = 16 *) logic [51:0] b28q_QHALF;
    always_ff @(posedge clk) b28q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo28 <= DIR_r ? (52'(xo28_x >> 1) + (xo28_x[0] ? 52'(b28q_QHALF) : 52'd0)) : xo28_x;
    logic [51:0] yo28, yo28_x; assign yo28_x = (cb_sw[20][28] ? xr28 : yr28);
    always_ff @(posedge clk) yo28 <= DIR_r ? (52'(yo28_x >> 1) + (yo28_x[0] ? 52'(b28q_QHALF) : 52'd0)) : yo28_x;
    (* max_fanout = 16 *) logic [25:0] b29q_QH;
    always_ff @(posedge clk) b29q_QH <= QH_r;
    logic [51:0] xr29; logic [51:0] yr29;
    Id_n65536_q52w_B32_rns_bu u_bu29 (.clk(clk), .aIn(op58), .bIn(op59), .W(twr29_q), .QH(b29q_QH), .aOut(xr29), .bOut(yr29));
    logic [51:0] xo29, xo29_x; assign xo29_x = (cb_sw[20][29] ? yr29 : xr29);
    (* max_fanout = 16 *) logic [51:0] b29q_QHALF;
    always_ff @(posedge clk) b29q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo29 <= DIR_r ? (52'(xo29_x >> 1) + (xo29_x[0] ? 52'(b29q_QHALF) : 52'd0)) : xo29_x;
    logic [51:0] yo29, yo29_x; assign yo29_x = (cb_sw[20][29] ? xr29 : yr29);
    always_ff @(posedge clk) yo29 <= DIR_r ? (52'(yo29_x >> 1) + (yo29_x[0] ? 52'(b29q_QHALF) : 52'd0)) : yo29_x;
    (* max_fanout = 16 *) logic [25:0] b30q_QH;
    always_ff @(posedge clk) b30q_QH <= QH_r;
    logic [51:0] xr30; logic [51:0] yr30;
    Id_n65536_q52w_B32_rns_bu u_bu30 (.clk(clk), .aIn(op60), .bIn(op61), .W(twr30_q), .QH(b30q_QH), .aOut(xr30), .bOut(yr30));
    logic [51:0] xo30, xo30_x; assign xo30_x = (cb_sw[20][30] ? yr30 : xr30);
    (* max_fanout = 16 *) logic [51:0] b30q_QHALF;
    always_ff @(posedge clk) b30q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo30 <= DIR_r ? (52'(xo30_x >> 1) + (xo30_x[0] ? 52'(b30q_QHALF) : 52'd0)) : xo30_x;
    logic [51:0] yo30, yo30_x; assign yo30_x = (cb_sw[20][30] ? xr30 : yr30);
    always_ff @(posedge clk) yo30 <= DIR_r ? (52'(yo30_x >> 1) + (yo30_x[0] ? 52'(b30q_QHALF) : 52'd0)) : yo30_x;
    (* max_fanout = 16 *) logic [25:0] b31q_QH;
    always_ff @(posedge clk) b31q_QH <= QH_r;
    logic [51:0] xr31; logic [51:0] yr31;
    Id_n65536_q52w_B32_rns_bu u_bu31 (.clk(clk), .aIn(op62), .bIn(op63), .W(twr31_q), .QH(b31q_QH), .aOut(xr31), .bOut(yr31));
    logic [51:0] xo31, xo31_x; assign xo31_x = (cb_sw[20][31] ? yr31 : xr31);
    (* max_fanout = 16 *) logic [51:0] b31q_QHALF;
    always_ff @(posedge clk) b31q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo31 <= DIR_r ? (52'(xo31_x >> 1) + (xo31_x[0] ? 52'(b31q_QHALF) : 52'd0)) : xo31_x;
    logic [51:0] yo31, yo31_x; assign yo31_x = (cb_sw[20][31] ? xr31 : yr31);
    always_ff @(posedge clk) yo31 <= DIR_r ? (52'(yo31_x >> 1) + (yo31_x[0] ? 52'(b31q_QHALF) : 52'd0)) : yo31_x;
    // ---- write back in place (sources per bank: IterativeNTTScheme.readSources), or the fill
    logic [51:0] wdat0;
    always_comb case (wc0)
        2'd0: wdat0 = xo0;
        2'd1: wdat0 = yo0;
        2'd2: wdat0 = xo16;
        default: wdat0 = xo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_0_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_0_we <= 1'b1; m0_0_wa <= (w_f ? w_hB : w_hA); m0_0_wd <= wdat0; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd8) : (fsub == 4'd0))) begin m0_0_we <= 1'b1; m0_0_wa <= frow; m0_0_wd <= x_in_0; end
        else m0_0_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_0_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_0_we <= 1'b1; m1_0_wa <= (w_f ? w_hB : w_hA); m1_0_wd <= wdat0; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd8) : (fsub == 4'd0))) begin m1_0_we <= 1'b1; m1_0_wa <= frow; m1_0_wd <= x_in_0; end
        else m1_0_we <= 1'b0;
    end
    logic [51:0] wdat1;
    always_comb case (wc1)
        3'd0: wdat1 = yo0;
        3'd1: wdat1 = xo1;
        3'd2: wdat1 = yo1;
        3'd3: wdat1 = yo16;
        3'd4: wdat1 = xo17;
        default: wdat1 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_1_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_1_we <= 1'b1; m0_1_wa <= (w_f ? w_hB : w_hA); m0_1_wd <= wdat1; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd8) : (fsub == 4'd0))) begin m0_1_we <= 1'b1; m0_1_wa <= frow; m0_1_wd <= x_in_1; end
        else m0_1_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_1_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_1_we <= 1'b1; m1_1_wa <= (w_f ? w_hB : w_hA); m1_1_wd <= wdat1; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd8) : (fsub == 4'd0))) begin m1_1_we <= 1'b1; m1_1_wa <= frow; m1_1_wd <= x_in_1; end
        else m1_1_we <= 1'b0;
    end
    logic [51:0] wdat2;
    always_comb case (wc2)
        3'd0: wdat2 = yo0;
        3'd1: wdat2 = xo1;
        3'd2: wdat2 = xo2;
        3'd3: wdat2 = yo2;
        3'd4: wdat2 = yo16;
        3'd5: wdat2 = xo17;
        3'd6: wdat2 = xo18;
        default: wdat2 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_2_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_2_we <= 1'b1; m0_2_wa <= (w_f ? w_hB : w_hA); m0_2_wd <= wdat2; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd8) : (fsub == 4'd0))) begin m0_2_we <= 1'b1; m0_2_wa <= frow; m0_2_wd <= x_in_2; end
        else m0_2_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_2_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_2_we <= 1'b1; m1_2_wa <= (w_f ? w_hB : w_hA); m1_2_wd <= wdat2; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd8) : (fsub == 4'd0))) begin m1_2_we <= 1'b1; m1_2_wa <= frow; m1_2_wd <= x_in_2; end
        else m1_2_we <= 1'b0;
    end
    logic [51:0] wdat3;
    always_comb case (wc3)
        3'd0: wdat3 = yo1;
        3'd1: wdat3 = xo3;
        3'd2: wdat3 = yo3;
        3'd3: wdat3 = yo17;
        3'd4: wdat3 = xo19;
        default: wdat3 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_3_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_3_we <= 1'b1; m0_3_wa <= (w_f ? w_hB : w_hA); m0_3_wd <= wdat3; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd8) : (fsub == 4'd0))) begin m0_3_we <= 1'b1; m0_3_wa <= frow; m0_3_wd <= x_in_3; end
        else m0_3_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_3_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_3_we <= 1'b1; m1_3_wa <= (w_f ? w_hB : w_hA); m1_3_wd <= wdat3; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd8) : (fsub == 4'd0))) begin m1_3_we <= 1'b1; m1_3_wa <= frow; m1_3_wd <= x_in_3; end
        else m1_3_we <= 1'b0;
    end
    logic [51:0] wdat4;
    always_comb case (wc4)
        3'd0: wdat4 = yo0;
        3'd1: wdat4 = xo2;
        3'd2: wdat4 = xo4;
        3'd3: wdat4 = yo4;
        3'd4: wdat4 = yo16;
        3'd5: wdat4 = xo18;
        3'd6: wdat4 = xo20;
        default: wdat4 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_4_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_4_we <= 1'b1; m0_4_wa <= (w_f ? w_hB : w_hA); m0_4_wd <= wdat4; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m0_4_we <= 1'b1; m0_4_wa <= frow; m0_4_wd <= x_in_0; end
        else m0_4_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_4_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_4_we <= 1'b1; m1_4_wa <= (w_f ? w_hB : w_hA); m1_4_wd <= wdat4; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m1_4_we <= 1'b1; m1_4_wa <= frow; m1_4_wd <= x_in_0; end
        else m1_4_we <= 1'b0;
    end
    logic [51:0] wdat5;
    always_comb case (wc5)
        4'd0: wdat5 = yo1;
        4'd1: wdat5 = yo2;
        4'd2: wdat5 = xo3;
        4'd3: wdat5 = xo5;
        4'd4: wdat5 = yo5;
        4'd5: wdat5 = yo17;
        4'd6: wdat5 = yo18;
        4'd7: wdat5 = xo19;
        4'd8: wdat5 = xo21;
        default: wdat5 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_5_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_5_we <= 1'b1; m0_5_wa <= (w_f ? w_hB : w_hA); m0_5_wd <= wdat5; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m0_5_we <= 1'b1; m0_5_wa <= frow; m0_5_wd <= x_in_1; end
        else m0_5_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_5_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_5_we <= 1'b1; m1_5_wa <= (w_f ? w_hB : w_hA); m1_5_wd <= wdat5; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m1_5_we <= 1'b1; m1_5_wa <= frow; m1_5_wd <= x_in_1; end
        else m1_5_we <= 1'b0;
    end
    logic [51:0] wdat6;
    always_comb case (wc6)
        3'd0: wdat6 = yo2;
        3'd1: wdat6 = xo3;
        3'd2: wdat6 = xo6;
        3'd3: wdat6 = yo6;
        3'd4: wdat6 = yo18;
        3'd5: wdat6 = xo19;
        3'd6: wdat6 = xo22;
        default: wdat6 = yo2;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_6_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_6_we <= 1'b1; m0_6_wa <= (w_f ? w_hB : w_hA); m0_6_wd <= wdat6; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m0_6_we <= 1'b1; m0_6_wa <= frow; m0_6_wd <= x_in_2; end
        else m0_6_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_6_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_6_we <= 1'b1; m1_6_wa <= (w_f ? w_hB : w_hA); m1_6_wd <= wdat6; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m1_6_we <= 1'b1; m1_6_wa <= frow; m1_6_wd <= x_in_2; end
        else m1_6_we <= 1'b0;
    end
    logic [51:0] wdat7;
    always_comb case (wc7)
        3'd0: wdat7 = yo3;
        3'd1: wdat7 = xo7;
        3'd2: wdat7 = yo7;
        3'd3: wdat7 = yo19;
        3'd4: wdat7 = xo23;
        default: wdat7 = yo3;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_7_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_7_we <= 1'b1; m0_7_wa <= (w_f ? w_hB : w_hA); m0_7_wd <= wdat7; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m0_7_we <= 1'b1; m0_7_wa <= frow; m0_7_wd <= x_in_3; end
        else m0_7_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_7_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_7_we <= 1'b1; m1_7_wa <= (w_f ? w_hB : w_hA); m1_7_wd <= wdat7; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m1_7_we <= 1'b1; m1_7_wa <= frow; m1_7_wd <= x_in_3; end
        else m1_7_we <= 1'b0;
    end
    logic [51:0] wdat8;
    always_comb case (wc8)
        3'd0: wdat8 = yo0;
        3'd1: wdat8 = xo4;
        3'd2: wdat8 = xo8;
        3'd3: wdat8 = yo8;
        3'd4: wdat8 = yo16;
        3'd5: wdat8 = xo20;
        3'd6: wdat8 = xo24;
        default: wdat8 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_8_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_8_we <= 1'b1; m0_8_wa <= (w_f ? w_hB : w_hA); m0_8_wd <= wdat8; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m0_8_we <= 1'b1; m0_8_wa <= frow; m0_8_wd <= x_in_0; end
        else m0_8_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_8_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_8_we <= 1'b1; m1_8_wa <= (w_f ? w_hB : w_hA); m1_8_wd <= wdat8; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m1_8_we <= 1'b1; m1_8_wa <= frow; m1_8_wd <= x_in_0; end
        else m1_8_we <= 1'b0;
    end
    logic [51:0] wdat9;
    always_comb case (wc9)
        4'd0: wdat9 = yo1;
        4'd1: wdat9 = yo4;
        4'd2: wdat9 = xo5;
        4'd3: wdat9 = xo9;
        4'd4: wdat9 = yo9;
        4'd5: wdat9 = yo17;
        4'd6: wdat9 = yo20;
        4'd7: wdat9 = xo21;
        4'd8: wdat9 = xo25;
        default: wdat9 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_9_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_9_we <= 1'b1; m0_9_wa <= (w_f ? w_hB : w_hA); m0_9_wd <= wdat9; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m0_9_we <= 1'b1; m0_9_wa <= frow; m0_9_wd <= x_in_1; end
        else m0_9_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_9_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_9_we <= 1'b1; m1_9_wa <= (w_f ? w_hB : w_hA); m1_9_wd <= wdat9; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m1_9_we <= 1'b1; m1_9_wa <= frow; m1_9_wd <= x_in_1; end
        else m1_9_we <= 1'b0;
    end
    logic [51:0] wdat10;
    always_comb case (wc10)
        4'd0: wdat10 = yo2;
        4'd1: wdat10 = yo4;
        4'd2: wdat10 = xo5;
        4'd3: wdat10 = xo6;
        4'd4: wdat10 = xo10;
        4'd5: wdat10 = yo10;
        4'd6: wdat10 = yo18;
        4'd7: wdat10 = yo20;
        4'd8: wdat10 = xo21;
        4'd9: wdat10 = xo22;
        4'd10: wdat10 = xo26;
        default: wdat10 = yo2;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_10_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_10_we <= 1'b1; m0_10_wa <= (w_f ? w_hB : w_hA); m0_10_wd <= wdat10; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m0_10_we <= 1'b1; m0_10_wa <= frow; m0_10_wd <= x_in_2; end
        else m0_10_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_10_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_10_we <= 1'b1; m1_10_wa <= (w_f ? w_hB : w_hA); m1_10_wd <= wdat10; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m1_10_we <= 1'b1; m1_10_wa <= frow; m1_10_wd <= x_in_2; end
        else m1_10_we <= 1'b0;
    end
    logic [51:0] wdat11;
    always_comb case (wc11)
        4'd0: wdat11 = yo3;
        4'd1: wdat11 = yo5;
        4'd2: wdat11 = xo7;
        4'd3: wdat11 = xo11;
        4'd4: wdat11 = yo11;
        4'd5: wdat11 = yo19;
        4'd6: wdat11 = yo21;
        4'd7: wdat11 = xo23;
        4'd8: wdat11 = xo27;
        default: wdat11 = yo3;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_11_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_11_we <= 1'b1; m0_11_wa <= (w_f ? w_hB : w_hA); m0_11_wd <= wdat11; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m0_11_we <= 1'b1; m0_11_wa <= frow; m0_11_wd <= x_in_3; end
        else m0_11_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_11_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_11_we <= 1'b1; m1_11_wa <= (w_f ? w_hB : w_hA); m1_11_wd <= wdat11; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m1_11_we <= 1'b1; m1_11_wa <= frow; m1_11_wd <= x_in_3; end
        else m1_11_we <= 1'b0;
    end
    logic [51:0] wdat12;
    always_comb case (wc12)
        3'd0: wdat12 = yo4;
        3'd1: wdat12 = xo6;
        3'd2: wdat12 = xo12;
        3'd3: wdat12 = yo12;
        3'd4: wdat12 = yo20;
        3'd5: wdat12 = xo22;
        3'd6: wdat12 = xo28;
        default: wdat12 = yo4;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_12_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_12_we <= 1'b1; m0_12_wa <= (w_f ? w_hB : w_hA); m0_12_wd <= wdat12; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m0_12_we <= 1'b1; m0_12_wa <= frow; m0_12_wd <= x_in_0; end
        else m0_12_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_12_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_12_we <= 1'b1; m1_12_wa <= (w_f ? w_hB : w_hA); m1_12_wd <= wdat12; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m1_12_we <= 1'b1; m1_12_wa <= frow; m1_12_wd <= x_in_0; end
        else m1_12_we <= 1'b0;
    end
    logic [51:0] wdat13;
    always_comb case (wc13)
        4'd0: wdat13 = yo5;
        4'd1: wdat13 = yo6;
        4'd2: wdat13 = xo7;
        4'd3: wdat13 = xo13;
        4'd4: wdat13 = yo13;
        4'd5: wdat13 = yo21;
        4'd6: wdat13 = yo22;
        4'd7: wdat13 = xo23;
        4'd8: wdat13 = xo29;
        default: wdat13 = yo5;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_13_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_13_we <= 1'b1; m0_13_wa <= (w_f ? w_hB : w_hA); m0_13_wd <= wdat13; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m0_13_we <= 1'b1; m0_13_wa <= frow; m0_13_wd <= x_in_1; end
        else m0_13_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_13_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_13_we <= 1'b1; m1_13_wa <= (w_f ? w_hB : w_hA); m1_13_wd <= wdat13; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m1_13_we <= 1'b1; m1_13_wa <= frow; m1_13_wd <= x_in_1; end
        else m1_13_we <= 1'b0;
    end
    logic [51:0] wdat14;
    always_comb case (wc14)
        3'd0: wdat14 = yo6;
        3'd1: wdat14 = xo7;
        3'd2: wdat14 = xo14;
        3'd3: wdat14 = yo14;
        3'd4: wdat14 = yo22;
        3'd5: wdat14 = xo23;
        3'd6: wdat14 = xo30;
        default: wdat14 = yo6;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_14_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_14_we <= 1'b1; m0_14_wa <= (w_f ? w_hB : w_hA); m0_14_wd <= wdat14; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m0_14_we <= 1'b1; m0_14_wa <= frow; m0_14_wd <= x_in_2; end
        else m0_14_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_14_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_14_we <= 1'b1; m1_14_wa <= (w_f ? w_hB : w_hA); m1_14_wd <= wdat14; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m1_14_we <= 1'b1; m1_14_wa <= frow; m1_14_wd <= x_in_2; end
        else m1_14_we <= 1'b0;
    end
    logic [51:0] wdat15;
    always_comb case (wc15)
        3'd0: wdat15 = yo7;
        3'd1: wdat15 = xo15;
        3'd2: wdat15 = yo15;
        3'd3: wdat15 = yo23;
        3'd4: wdat15 = xo31;
        default: wdat15 = yo7;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_15_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_15_we <= 1'b1; m0_15_wa <= (w_f ? w_hB : w_hA); m0_15_wd <= wdat15; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m0_15_we <= 1'b1; m0_15_wa <= frow; m0_15_wd <= x_in_3; end
        else m0_15_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_15_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_15_we <= 1'b1; m1_15_wa <= (w_f ? w_hB : w_hA); m1_15_wd <= wdat15; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m1_15_we <= 1'b1; m1_15_wa <= frow; m1_15_wd <= x_in_3; end
        else m1_15_we <= 1'b0;
    end
    logic [51:0] wdat16;
    always_comb case (wc16)
        3'd0: wdat16 = yo0;
        3'd1: wdat16 = xo8;
        3'd2: wdat16 = xo16;
        3'd3: wdat16 = yo16;
        3'd4: wdat16 = xo24;
        default: wdat16 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_16_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_16_we <= 1'b1; m0_16_wa <= (w_f ? w_hB : w_hA); m0_16_wd <= wdat16; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m0_16_we <= 1'b1; m0_16_wa <= frow; m0_16_wd <= x_in_0; end
        else m0_16_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_16_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_16_we <= 1'b1; m1_16_wa <= (w_f ? w_hB : w_hA); m1_16_wd <= wdat16; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m1_16_we <= 1'b1; m1_16_wa <= frow; m1_16_wd <= x_in_0; end
        else m1_16_we <= 1'b0;
    end
    logic [51:0] wdat17;
    always_comb case (wc17)
        3'd0: wdat17 = yo1;
        3'd1: wdat17 = yo8;
        3'd2: wdat17 = xo9;
        3'd3: wdat17 = xo17;
        3'd4: wdat17 = yo17;
        3'd5: wdat17 = yo24;
        3'd6: wdat17 = xo25;
        default: wdat17 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_17_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_17_we <= 1'b1; m0_17_wa <= (w_f ? w_hB : w_hA); m0_17_wd <= wdat17; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m0_17_we <= 1'b1; m0_17_wa <= frow; m0_17_wd <= x_in_1; end
        else m0_17_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_17_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_17_we <= 1'b1; m1_17_wa <= (w_f ? w_hB : w_hA); m1_17_wd <= wdat17; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m1_17_we <= 1'b1; m1_17_wa <= frow; m1_17_wd <= x_in_1; end
        else m1_17_we <= 1'b0;
    end
    logic [51:0] wdat18;
    always_comb case (wc18)
        4'd0: wdat18 = yo2;
        4'd1: wdat18 = yo8;
        4'd2: wdat18 = xo9;
        4'd3: wdat18 = xo10;
        4'd4: wdat18 = xo18;
        4'd5: wdat18 = yo18;
        4'd6: wdat18 = yo24;
        4'd7: wdat18 = xo25;
        4'd8: wdat18 = xo26;
        default: wdat18 = yo2;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_18_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_18_we <= 1'b1; m0_18_wa <= (w_f ? w_hB : w_hA); m0_18_wd <= wdat18; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m0_18_we <= 1'b1; m0_18_wa <= frow; m0_18_wd <= x_in_2; end
        else m0_18_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_18_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_18_we <= 1'b1; m1_18_wa <= (w_f ? w_hB : w_hA); m1_18_wd <= wdat18; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m1_18_we <= 1'b1; m1_18_wa <= frow; m1_18_wd <= x_in_2; end
        else m1_18_we <= 1'b0;
    end
    logic [51:0] wdat19;
    always_comb case (wc19)
        3'd0: wdat19 = yo3;
        3'd1: wdat19 = yo9;
        3'd2: wdat19 = xo11;
        3'd3: wdat19 = xo19;
        3'd4: wdat19 = yo19;
        3'd5: wdat19 = yo25;
        3'd6: wdat19 = xo27;
        default: wdat19 = yo3;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_19_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_19_we <= 1'b1; m0_19_wa <= (w_f ? w_hB : w_hA); m0_19_wd <= wdat19; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m0_19_we <= 1'b1; m0_19_wa <= frow; m0_19_wd <= x_in_3; end
        else m0_19_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_19_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_19_we <= 1'b1; m1_19_wa <= (w_f ? w_hB : w_hA); m1_19_wd <= wdat19; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m1_19_we <= 1'b1; m1_19_wa <= frow; m1_19_wd <= x_in_3; end
        else m1_19_we <= 1'b0;
    end
    logic [51:0] wdat20;
    always_comb case (wc20)
        4'd0: wdat20 = yo4;
        4'd1: wdat20 = yo8;
        4'd2: wdat20 = xo10;
        4'd3: wdat20 = xo12;
        4'd4: wdat20 = xo20;
        4'd5: wdat20 = yo20;
        4'd6: wdat20 = yo24;
        4'd7: wdat20 = xo26;
        4'd8: wdat20 = xo28;
        default: wdat20 = yo4;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_20_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_20_we <= 1'b1; m0_20_wa <= (w_f ? w_hB : w_hA); m0_20_wd <= wdat20; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m0_20_we <= 1'b1; m0_20_wa <= frow; m0_20_wd <= x_in_0; end
        else m0_20_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_20_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_20_we <= 1'b1; m1_20_wa <= (w_f ? w_hB : w_hA); m1_20_wd <= wdat20; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m1_20_we <= 1'b1; m1_20_wa <= frow; m1_20_wd <= x_in_0; end
        else m1_20_we <= 1'b0;
    end
    logic [51:0] wdat21;
    always_comb case (wc21)
        4'd0: wdat21 = yo5;
        4'd1: wdat21 = yo9;
        4'd2: wdat21 = yo10;
        4'd3: wdat21 = xo11;
        4'd4: wdat21 = xo13;
        4'd5: wdat21 = xo21;
        4'd6: wdat21 = yo21;
        4'd7: wdat21 = yo25;
        4'd8: wdat21 = yo26;
        4'd9: wdat21 = xo27;
        4'd10: wdat21 = xo29;
        default: wdat21 = yo5;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_21_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_21_we <= 1'b1; m0_21_wa <= (w_f ? w_hB : w_hA); m0_21_wd <= wdat21; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m0_21_we <= 1'b1; m0_21_wa <= frow; m0_21_wd <= x_in_1; end
        else m0_21_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_21_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_21_we <= 1'b1; m1_21_wa <= (w_f ? w_hB : w_hA); m1_21_wd <= wdat21; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m1_21_we <= 1'b1; m1_21_wa <= frow; m1_21_wd <= x_in_1; end
        else m1_21_we <= 1'b0;
    end
    logic [51:0] wdat22;
    always_comb case (wc22)
        4'd0: wdat22 = yo6;
        4'd1: wdat22 = yo10;
        4'd2: wdat22 = xo11;
        4'd3: wdat22 = xo14;
        4'd4: wdat22 = xo22;
        4'd5: wdat22 = yo22;
        4'd6: wdat22 = yo26;
        4'd7: wdat22 = xo27;
        4'd8: wdat22 = xo30;
        default: wdat22 = yo6;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_22_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_22_we <= 1'b1; m0_22_wa <= (w_f ? w_hB : w_hA); m0_22_wd <= wdat22; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m0_22_we <= 1'b1; m0_22_wa <= frow; m0_22_wd <= x_in_2; end
        else m0_22_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_22_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_22_we <= 1'b1; m1_22_wa <= (w_f ? w_hB : w_hA); m1_22_wd <= wdat22; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m1_22_we <= 1'b1; m1_22_wa <= frow; m1_22_wd <= x_in_2; end
        else m1_22_we <= 1'b0;
    end
    logic [51:0] wdat23;
    always_comb case (wc23)
        3'd0: wdat23 = yo7;
        3'd1: wdat23 = yo11;
        3'd2: wdat23 = xo15;
        3'd3: wdat23 = xo23;
        3'd4: wdat23 = yo23;
        3'd5: wdat23 = yo27;
        3'd6: wdat23 = xo31;
        default: wdat23 = yo7;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_23_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_23_we <= 1'b1; m0_23_wa <= (w_f ? w_hB : w_hA); m0_23_wd <= wdat23; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m0_23_we <= 1'b1; m0_23_wa <= frow; m0_23_wd <= x_in_3; end
        else m0_23_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_23_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_23_we <= 1'b1; m1_23_wa <= (w_f ? w_hB : w_hA); m1_23_wd <= wdat23; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m1_23_we <= 1'b1; m1_23_wa <= frow; m1_23_wd <= x_in_3; end
        else m1_23_we <= 1'b0;
    end
    logic [51:0] wdat24;
    always_comb case (wc24)
        3'd0: wdat24 = yo8;
        3'd1: wdat24 = xo12;
        3'd2: wdat24 = xo24;
        3'd3: wdat24 = yo24;
        3'd4: wdat24 = xo28;
        default: wdat24 = yo8;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_24_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_24_we <= 1'b1; m0_24_wa <= (w_f ? w_hB : w_hA); m0_24_wd <= wdat24; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m0_24_we <= 1'b1; m0_24_wa <= frow; m0_24_wd <= x_in_0; end
        else m0_24_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_24_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_24_we <= 1'b1; m1_24_wa <= (w_f ? w_hB : w_hA); m1_24_wd <= wdat24; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m1_24_we <= 1'b1; m1_24_wa <= frow; m1_24_wd <= x_in_0; end
        else m1_24_we <= 1'b0;
    end
    logic [51:0] wdat25;
    always_comb case (wc25)
        3'd0: wdat25 = yo9;
        3'd1: wdat25 = yo12;
        3'd2: wdat25 = xo13;
        3'd3: wdat25 = xo25;
        3'd4: wdat25 = yo25;
        3'd5: wdat25 = yo28;
        3'd6: wdat25 = xo29;
        default: wdat25 = yo9;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_25_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_25_we <= 1'b1; m0_25_wa <= (w_f ? w_hB : w_hA); m0_25_wd <= wdat25; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m0_25_we <= 1'b1; m0_25_wa <= frow; m0_25_wd <= x_in_1; end
        else m0_25_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_25_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_25_we <= 1'b1; m1_25_wa <= (w_f ? w_hB : w_hA); m1_25_wd <= wdat25; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m1_25_we <= 1'b1; m1_25_wa <= frow; m1_25_wd <= x_in_1; end
        else m1_25_we <= 1'b0;
    end
    logic [51:0] wdat26;
    always_comb case (wc26)
        4'd0: wdat26 = yo10;
        4'd1: wdat26 = yo12;
        4'd2: wdat26 = xo13;
        4'd3: wdat26 = xo14;
        4'd4: wdat26 = xo26;
        4'd5: wdat26 = yo26;
        4'd6: wdat26 = yo28;
        4'd7: wdat26 = xo29;
        4'd8: wdat26 = xo30;
        default: wdat26 = yo10;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_26_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_26_we <= 1'b1; m0_26_wa <= (w_f ? w_hB : w_hA); m0_26_wd <= wdat26; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m0_26_we <= 1'b1; m0_26_wa <= frow; m0_26_wd <= x_in_2; end
        else m0_26_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_26_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_26_we <= 1'b1; m1_26_wa <= (w_f ? w_hB : w_hA); m1_26_wd <= wdat26; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m1_26_we <= 1'b1; m1_26_wa <= frow; m1_26_wd <= x_in_2; end
        else m1_26_we <= 1'b0;
    end
    logic [51:0] wdat27;
    always_comb case (wc27)
        3'd0: wdat27 = yo11;
        3'd1: wdat27 = yo13;
        3'd2: wdat27 = xo15;
        3'd3: wdat27 = xo27;
        3'd4: wdat27 = yo27;
        3'd5: wdat27 = yo29;
        3'd6: wdat27 = xo31;
        default: wdat27 = yo11;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_27_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_27_we <= 1'b1; m0_27_wa <= (w_f ? w_hB : w_hA); m0_27_wd <= wdat27; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m0_27_we <= 1'b1; m0_27_wa <= frow; m0_27_wd <= x_in_3; end
        else m0_27_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_27_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_27_we <= 1'b1; m1_27_wa <= (w_f ? w_hB : w_hA); m1_27_wd <= wdat27; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m1_27_we <= 1'b1; m1_27_wa <= frow; m1_27_wd <= x_in_3; end
        else m1_27_we <= 1'b0;
    end
    logic [51:0] wdat28;
    always_comb case (wc28)
        3'd0: wdat28 = yo12;
        3'd1: wdat28 = xo14;
        3'd2: wdat28 = xo28;
        3'd3: wdat28 = yo28;
        3'd4: wdat28 = xo30;
        default: wdat28 = yo12;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_28_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_28_we <= 1'b1; m0_28_wa <= (w_f ? w_hB : w_hA); m0_28_wd <= wdat28; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m0_28_we <= 1'b1; m0_28_wa <= frow; m0_28_wd <= x_in_0; end
        else m0_28_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_28_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_28_we <= 1'b1; m1_28_wa <= (w_f ? w_hB : w_hA); m1_28_wd <= wdat28; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m1_28_we <= 1'b1; m1_28_wa <= frow; m1_28_wd <= x_in_0; end
        else m1_28_we <= 1'b0;
    end
    logic [51:0] wdat29;
    always_comb case (wc29)
        3'd0: wdat29 = yo13;
        3'd1: wdat29 = yo14;
        3'd2: wdat29 = xo15;
        3'd3: wdat29 = xo29;
        3'd4: wdat29 = yo29;
        3'd5: wdat29 = yo30;
        3'd6: wdat29 = xo31;
        default: wdat29 = yo13;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_29_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_29_we <= 1'b1; m0_29_wa <= (w_f ? w_hB : w_hA); m0_29_wd <= wdat29; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m0_29_we <= 1'b1; m0_29_wa <= frow; m0_29_wd <= x_in_1; end
        else m0_29_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_29_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_29_we <= 1'b1; m1_29_wa <= (w_f ? w_hB : w_hA); m1_29_wd <= wdat29; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m1_29_we <= 1'b1; m1_29_wa <= frow; m1_29_wd <= x_in_1; end
        else m1_29_we <= 1'b0;
    end
    logic [51:0] wdat30;
    always_comb case (wc30)
        3'd0: wdat30 = yo14;
        3'd1: wdat30 = xo15;
        3'd2: wdat30 = xo30;
        3'd3: wdat30 = yo30;
        3'd4: wdat30 = xo31;
        default: wdat30 = yo14;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_30_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_30_we <= 1'b1; m0_30_wa <= (w_f ? w_hB : w_hA); m0_30_wd <= wdat30; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m0_30_we <= 1'b1; m0_30_wa <= frow; m0_30_wd <= x_in_2; end
        else m0_30_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_30_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_30_we <= 1'b1; m1_30_wa <= (w_f ? w_hB : w_hA); m1_30_wd <= wdat30; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m1_30_we <= 1'b1; m1_30_wa <= frow; m1_30_wd <= x_in_2; end
        else m1_30_we <= 1'b0;
    end
    logic [51:0] wdat31;
    always_comb case (wc31)
        2'd0: wdat31 = yo15;
        2'd1: wdat31 = xo31;
        2'd2: wdat31 = yo31;
        default: wdat31 = yo15;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_31_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_31_we <= 1'b1; m0_31_wa <= (w_f ? w_hB : w_hA); m0_31_wd <= wdat31; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m0_31_we <= 1'b1; m0_31_wa <= frow; m0_31_wd <= x_in_3; end
        else m0_31_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_31_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_31_we <= 1'b1; m1_31_wa <= (w_f ? w_hB : w_hA); m1_31_wd <= wdat31; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m1_31_we <= 1'b1; m1_31_wa <= frow; m1_31_wd <= x_in_3; end
        else m1_31_we <= 1'b0;
    end
    logic [51:0] wdat32;
    always_comb case (wc32)
        2'd0: wdat32 = xo0;
        2'd1: wdat32 = yo0;
        2'd2: wdat32 = xo16;
        default: wdat32 = xo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_32_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_32_we <= 1'b1; m0_32_wa <= (w_f ? w_hA : w_hB); m0_32_wd <= wdat32; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m0_32_we <= 1'b1; m0_32_wa <= frow; m0_32_wd <= x_in_0; end
        else m0_32_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_32_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_32_we <= 1'b1; m1_32_wa <= (w_f ? w_hA : w_hB); m1_32_wd <= wdat32; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m1_32_we <= 1'b1; m1_32_wa <= frow; m1_32_wd <= x_in_0; end
        else m1_32_we <= 1'b0;
    end
    logic [51:0] wdat33;
    always_comb case (wc33)
        3'd0: wdat33 = yo0;
        3'd1: wdat33 = xo1;
        3'd2: wdat33 = yo1;
        3'd3: wdat33 = yo16;
        3'd4: wdat33 = xo17;
        default: wdat33 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_33_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_33_we <= 1'b1; m0_33_wa <= (w_f ? w_hA : w_hB); m0_33_wd <= wdat33; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m0_33_we <= 1'b1; m0_33_wa <= frow; m0_33_wd <= x_in_1; end
        else m0_33_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_33_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_33_we <= 1'b1; m1_33_wa <= (w_f ? w_hA : w_hB); m1_33_wd <= wdat33; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m1_33_we <= 1'b1; m1_33_wa <= frow; m1_33_wd <= x_in_1; end
        else m1_33_we <= 1'b0;
    end
    logic [51:0] wdat34;
    always_comb case (wc34)
        3'd0: wdat34 = yo0;
        3'd1: wdat34 = xo1;
        3'd2: wdat34 = xo2;
        3'd3: wdat34 = yo2;
        3'd4: wdat34 = yo16;
        3'd5: wdat34 = xo17;
        3'd6: wdat34 = xo18;
        default: wdat34 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_34_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_34_we <= 1'b1; m0_34_wa <= (w_f ? w_hA : w_hB); m0_34_wd <= wdat34; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m0_34_we <= 1'b1; m0_34_wa <= frow; m0_34_wd <= x_in_2; end
        else m0_34_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_34_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_34_we <= 1'b1; m1_34_wa <= (w_f ? w_hA : w_hB); m1_34_wd <= wdat34; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m1_34_we <= 1'b1; m1_34_wa <= frow; m1_34_wd <= x_in_2; end
        else m1_34_we <= 1'b0;
    end
    logic [51:0] wdat35;
    always_comb case (wc35)
        3'd0: wdat35 = yo1;
        3'd1: wdat35 = xo3;
        3'd2: wdat35 = yo3;
        3'd3: wdat35 = yo17;
        3'd4: wdat35 = xo19;
        default: wdat35 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_35_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_35_we <= 1'b1; m0_35_wa <= (w_f ? w_hA : w_hB); m0_35_wd <= wdat35; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m0_35_we <= 1'b1; m0_35_wa <= frow; m0_35_wd <= x_in_3; end
        else m0_35_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_35_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_35_we <= 1'b1; m1_35_wa <= (w_f ? w_hA : w_hB); m1_35_wd <= wdat35; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m1_35_we <= 1'b1; m1_35_wa <= frow; m1_35_wd <= x_in_3; end
        else m1_35_we <= 1'b0;
    end
    logic [51:0] wdat36;
    always_comb case (wc36)
        3'd0: wdat36 = yo0;
        3'd1: wdat36 = xo2;
        3'd2: wdat36 = xo4;
        3'd3: wdat36 = yo4;
        3'd4: wdat36 = yo16;
        3'd5: wdat36 = xo18;
        3'd6: wdat36 = xo20;
        default: wdat36 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_36_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_36_we <= 1'b1; m0_36_wa <= (w_f ? w_hA : w_hB); m0_36_wd <= wdat36; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m0_36_we <= 1'b1; m0_36_wa <= frow; m0_36_wd <= x_in_0; end
        else m0_36_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_36_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_36_we <= 1'b1; m1_36_wa <= (w_f ? w_hA : w_hB); m1_36_wd <= wdat36; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m1_36_we <= 1'b1; m1_36_wa <= frow; m1_36_wd <= x_in_0; end
        else m1_36_we <= 1'b0;
    end
    logic [51:0] wdat37;
    always_comb case (wc37)
        4'd0: wdat37 = yo1;
        4'd1: wdat37 = yo2;
        4'd2: wdat37 = xo3;
        4'd3: wdat37 = xo5;
        4'd4: wdat37 = yo5;
        4'd5: wdat37 = yo17;
        4'd6: wdat37 = yo18;
        4'd7: wdat37 = xo19;
        4'd8: wdat37 = xo21;
        default: wdat37 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_37_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_37_we <= 1'b1; m0_37_wa <= (w_f ? w_hA : w_hB); m0_37_wd <= wdat37; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m0_37_we <= 1'b1; m0_37_wa <= frow; m0_37_wd <= x_in_1; end
        else m0_37_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_37_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_37_we <= 1'b1; m1_37_wa <= (w_f ? w_hA : w_hB); m1_37_wd <= wdat37; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m1_37_we <= 1'b1; m1_37_wa <= frow; m1_37_wd <= x_in_1; end
        else m1_37_we <= 1'b0;
    end
    logic [51:0] wdat38;
    always_comb case (wc38)
        3'd0: wdat38 = yo2;
        3'd1: wdat38 = xo3;
        3'd2: wdat38 = xo6;
        3'd3: wdat38 = yo6;
        3'd4: wdat38 = yo18;
        3'd5: wdat38 = xo19;
        3'd6: wdat38 = xo22;
        default: wdat38 = yo2;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_38_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_38_we <= 1'b1; m0_38_wa <= (w_f ? w_hA : w_hB); m0_38_wd <= wdat38; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m0_38_we <= 1'b1; m0_38_wa <= frow; m0_38_wd <= x_in_2; end
        else m0_38_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_38_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_38_we <= 1'b1; m1_38_wa <= (w_f ? w_hA : w_hB); m1_38_wd <= wdat38; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m1_38_we <= 1'b1; m1_38_wa <= frow; m1_38_wd <= x_in_2; end
        else m1_38_we <= 1'b0;
    end
    logic [51:0] wdat39;
    always_comb case (wc39)
        3'd0: wdat39 = yo3;
        3'd1: wdat39 = xo7;
        3'd2: wdat39 = yo7;
        3'd3: wdat39 = yo19;
        3'd4: wdat39 = xo23;
        default: wdat39 = yo3;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_39_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_39_we <= 1'b1; m0_39_wa <= (w_f ? w_hA : w_hB); m0_39_wd <= wdat39; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m0_39_we <= 1'b1; m0_39_wa <= frow; m0_39_wd <= x_in_3; end
        else m0_39_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_39_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_39_we <= 1'b1; m1_39_wa <= (w_f ? w_hA : w_hB); m1_39_wd <= wdat39; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m1_39_we <= 1'b1; m1_39_wa <= frow; m1_39_wd <= x_in_3; end
        else m1_39_we <= 1'b0;
    end
    logic [51:0] wdat40;
    always_comb case (wc40)
        3'd0: wdat40 = yo0;
        3'd1: wdat40 = xo4;
        3'd2: wdat40 = xo8;
        3'd3: wdat40 = yo8;
        3'd4: wdat40 = yo16;
        3'd5: wdat40 = xo20;
        3'd6: wdat40 = xo24;
        default: wdat40 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_40_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_40_we <= 1'b1; m0_40_wa <= (w_f ? w_hA : w_hB); m0_40_wd <= wdat40; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m0_40_we <= 1'b1; m0_40_wa <= frow; m0_40_wd <= x_in_0; end
        else m0_40_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_40_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_40_we <= 1'b1; m1_40_wa <= (w_f ? w_hA : w_hB); m1_40_wd <= wdat40; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m1_40_we <= 1'b1; m1_40_wa <= frow; m1_40_wd <= x_in_0; end
        else m1_40_we <= 1'b0;
    end
    logic [51:0] wdat41;
    always_comb case (wc41)
        4'd0: wdat41 = yo1;
        4'd1: wdat41 = yo4;
        4'd2: wdat41 = xo5;
        4'd3: wdat41 = xo9;
        4'd4: wdat41 = yo9;
        4'd5: wdat41 = yo17;
        4'd6: wdat41 = yo20;
        4'd7: wdat41 = xo21;
        4'd8: wdat41 = xo25;
        default: wdat41 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_41_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_41_we <= 1'b1; m0_41_wa <= (w_f ? w_hA : w_hB); m0_41_wd <= wdat41; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m0_41_we <= 1'b1; m0_41_wa <= frow; m0_41_wd <= x_in_1; end
        else m0_41_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_41_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_41_we <= 1'b1; m1_41_wa <= (w_f ? w_hA : w_hB); m1_41_wd <= wdat41; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m1_41_we <= 1'b1; m1_41_wa <= frow; m1_41_wd <= x_in_1; end
        else m1_41_we <= 1'b0;
    end
    logic [51:0] wdat42;
    always_comb case (wc42)
        4'd0: wdat42 = yo2;
        4'd1: wdat42 = yo4;
        4'd2: wdat42 = xo5;
        4'd3: wdat42 = xo6;
        4'd4: wdat42 = xo10;
        4'd5: wdat42 = yo10;
        4'd6: wdat42 = yo18;
        4'd7: wdat42 = yo20;
        4'd8: wdat42 = xo21;
        4'd9: wdat42 = xo22;
        4'd10: wdat42 = xo26;
        default: wdat42 = yo2;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_42_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_42_we <= 1'b1; m0_42_wa <= (w_f ? w_hA : w_hB); m0_42_wd <= wdat42; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m0_42_we <= 1'b1; m0_42_wa <= frow; m0_42_wd <= x_in_2; end
        else m0_42_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_42_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_42_we <= 1'b1; m1_42_wa <= (w_f ? w_hA : w_hB); m1_42_wd <= wdat42; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m1_42_we <= 1'b1; m1_42_wa <= frow; m1_42_wd <= x_in_2; end
        else m1_42_we <= 1'b0;
    end
    logic [51:0] wdat43;
    always_comb case (wc43)
        4'd0: wdat43 = yo3;
        4'd1: wdat43 = yo5;
        4'd2: wdat43 = xo7;
        4'd3: wdat43 = xo11;
        4'd4: wdat43 = yo11;
        4'd5: wdat43 = yo19;
        4'd6: wdat43 = yo21;
        4'd7: wdat43 = xo23;
        4'd8: wdat43 = xo27;
        default: wdat43 = yo3;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_43_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_43_we <= 1'b1; m0_43_wa <= (w_f ? w_hA : w_hB); m0_43_wd <= wdat43; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m0_43_we <= 1'b1; m0_43_wa <= frow; m0_43_wd <= x_in_3; end
        else m0_43_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_43_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_43_we <= 1'b1; m1_43_wa <= (w_f ? w_hA : w_hB); m1_43_wd <= wdat43; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m1_43_we <= 1'b1; m1_43_wa <= frow; m1_43_wd <= x_in_3; end
        else m1_43_we <= 1'b0;
    end
    logic [51:0] wdat44;
    always_comb case (wc44)
        3'd0: wdat44 = yo4;
        3'd1: wdat44 = xo6;
        3'd2: wdat44 = xo12;
        3'd3: wdat44 = yo12;
        3'd4: wdat44 = yo20;
        3'd5: wdat44 = xo22;
        3'd6: wdat44 = xo28;
        default: wdat44 = yo4;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_44_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_44_we <= 1'b1; m0_44_wa <= (w_f ? w_hA : w_hB); m0_44_wd <= wdat44; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m0_44_we <= 1'b1; m0_44_wa <= frow; m0_44_wd <= x_in_0; end
        else m0_44_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_44_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_44_we <= 1'b1; m1_44_wa <= (w_f ? w_hA : w_hB); m1_44_wd <= wdat44; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m1_44_we <= 1'b1; m1_44_wa <= frow; m1_44_wd <= x_in_0; end
        else m1_44_we <= 1'b0;
    end
    logic [51:0] wdat45;
    always_comb case (wc45)
        4'd0: wdat45 = yo5;
        4'd1: wdat45 = yo6;
        4'd2: wdat45 = xo7;
        4'd3: wdat45 = xo13;
        4'd4: wdat45 = yo13;
        4'd5: wdat45 = yo21;
        4'd6: wdat45 = yo22;
        4'd7: wdat45 = xo23;
        4'd8: wdat45 = xo29;
        default: wdat45 = yo5;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_45_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_45_we <= 1'b1; m0_45_wa <= (w_f ? w_hA : w_hB); m0_45_wd <= wdat45; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m0_45_we <= 1'b1; m0_45_wa <= frow; m0_45_wd <= x_in_1; end
        else m0_45_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_45_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_45_we <= 1'b1; m1_45_wa <= (w_f ? w_hA : w_hB); m1_45_wd <= wdat45; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m1_45_we <= 1'b1; m1_45_wa <= frow; m1_45_wd <= x_in_1; end
        else m1_45_we <= 1'b0;
    end
    logic [51:0] wdat46;
    always_comb case (wc46)
        3'd0: wdat46 = yo6;
        3'd1: wdat46 = xo7;
        3'd2: wdat46 = xo14;
        3'd3: wdat46 = yo14;
        3'd4: wdat46 = yo22;
        3'd5: wdat46 = xo23;
        3'd6: wdat46 = xo30;
        default: wdat46 = yo6;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_46_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_46_we <= 1'b1; m0_46_wa <= (w_f ? w_hA : w_hB); m0_46_wd <= wdat46; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m0_46_we <= 1'b1; m0_46_wa <= frow; m0_46_wd <= x_in_2; end
        else m0_46_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_46_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_46_we <= 1'b1; m1_46_wa <= (w_f ? w_hA : w_hB); m1_46_wd <= wdat46; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m1_46_we <= 1'b1; m1_46_wa <= frow; m1_46_wd <= x_in_2; end
        else m1_46_we <= 1'b0;
    end
    logic [51:0] wdat47;
    always_comb case (wc47)
        3'd0: wdat47 = yo7;
        3'd1: wdat47 = xo15;
        3'd2: wdat47 = yo15;
        3'd3: wdat47 = yo23;
        3'd4: wdat47 = xo31;
        default: wdat47 = yo7;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_47_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_47_we <= 1'b1; m0_47_wa <= (w_f ? w_hA : w_hB); m0_47_wd <= wdat47; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m0_47_we <= 1'b1; m0_47_wa <= frow; m0_47_wd <= x_in_3; end
        else m0_47_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_47_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_47_we <= 1'b1; m1_47_wa <= (w_f ? w_hA : w_hB); m1_47_wd <= wdat47; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m1_47_we <= 1'b1; m1_47_wa <= frow; m1_47_wd <= x_in_3; end
        else m1_47_we <= 1'b0;
    end
    logic [51:0] wdat48;
    always_comb case (wc48)
        3'd0: wdat48 = yo0;
        3'd1: wdat48 = xo8;
        3'd2: wdat48 = xo16;
        3'd3: wdat48 = yo16;
        3'd4: wdat48 = xo24;
        default: wdat48 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_48_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_48_we <= 1'b1; m0_48_wa <= (w_f ? w_hA : w_hB); m0_48_wd <= wdat48; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m0_48_we <= 1'b1; m0_48_wa <= frow; m0_48_wd <= x_in_0; end
        else m0_48_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_48_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_48_we <= 1'b1; m1_48_wa <= (w_f ? w_hA : w_hB); m1_48_wd <= wdat48; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m1_48_we <= 1'b1; m1_48_wa <= frow; m1_48_wd <= x_in_0; end
        else m1_48_we <= 1'b0;
    end
    logic [51:0] wdat49;
    always_comb case (wc49)
        3'd0: wdat49 = yo1;
        3'd1: wdat49 = yo8;
        3'd2: wdat49 = xo9;
        3'd3: wdat49 = xo17;
        3'd4: wdat49 = yo17;
        3'd5: wdat49 = yo24;
        3'd6: wdat49 = xo25;
        default: wdat49 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_49_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_49_we <= 1'b1; m0_49_wa <= (w_f ? w_hA : w_hB); m0_49_wd <= wdat49; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m0_49_we <= 1'b1; m0_49_wa <= frow; m0_49_wd <= x_in_1; end
        else m0_49_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_49_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_49_we <= 1'b1; m1_49_wa <= (w_f ? w_hA : w_hB); m1_49_wd <= wdat49; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m1_49_we <= 1'b1; m1_49_wa <= frow; m1_49_wd <= x_in_1; end
        else m1_49_we <= 1'b0;
    end
    logic [51:0] wdat50;
    always_comb case (wc50)
        4'd0: wdat50 = yo2;
        4'd1: wdat50 = yo8;
        4'd2: wdat50 = xo9;
        4'd3: wdat50 = xo10;
        4'd4: wdat50 = xo18;
        4'd5: wdat50 = yo18;
        4'd6: wdat50 = yo24;
        4'd7: wdat50 = xo25;
        4'd8: wdat50 = xo26;
        default: wdat50 = yo2;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_50_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_50_we <= 1'b1; m0_50_wa <= (w_f ? w_hA : w_hB); m0_50_wd <= wdat50; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m0_50_we <= 1'b1; m0_50_wa <= frow; m0_50_wd <= x_in_2; end
        else m0_50_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_50_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_50_we <= 1'b1; m1_50_wa <= (w_f ? w_hA : w_hB); m1_50_wd <= wdat50; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m1_50_we <= 1'b1; m1_50_wa <= frow; m1_50_wd <= x_in_2; end
        else m1_50_we <= 1'b0;
    end
    logic [51:0] wdat51;
    always_comb case (wc51)
        3'd0: wdat51 = yo3;
        3'd1: wdat51 = yo9;
        3'd2: wdat51 = xo11;
        3'd3: wdat51 = xo19;
        3'd4: wdat51 = yo19;
        3'd5: wdat51 = yo25;
        3'd6: wdat51 = xo27;
        default: wdat51 = yo3;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_51_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_51_we <= 1'b1; m0_51_wa <= (w_f ? w_hA : w_hB); m0_51_wd <= wdat51; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m0_51_we <= 1'b1; m0_51_wa <= frow; m0_51_wd <= x_in_3; end
        else m0_51_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_51_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_51_we <= 1'b1; m1_51_wa <= (w_f ? w_hA : w_hB); m1_51_wd <= wdat51; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m1_51_we <= 1'b1; m1_51_wa <= frow; m1_51_wd <= x_in_3; end
        else m1_51_we <= 1'b0;
    end
    logic [51:0] wdat52;
    always_comb case (wc52)
        4'd0: wdat52 = yo4;
        4'd1: wdat52 = yo8;
        4'd2: wdat52 = xo10;
        4'd3: wdat52 = xo12;
        4'd4: wdat52 = xo20;
        4'd5: wdat52 = yo20;
        4'd6: wdat52 = yo24;
        4'd7: wdat52 = xo26;
        4'd8: wdat52 = xo28;
        default: wdat52 = yo4;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_52_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_52_we <= 1'b1; m0_52_wa <= (w_f ? w_hA : w_hB); m0_52_wd <= wdat52; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m0_52_we <= 1'b1; m0_52_wa <= frow; m0_52_wd <= x_in_0; end
        else m0_52_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_52_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_52_we <= 1'b1; m1_52_wa <= (w_f ? w_hA : w_hB); m1_52_wd <= wdat52; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m1_52_we <= 1'b1; m1_52_wa <= frow; m1_52_wd <= x_in_0; end
        else m1_52_we <= 1'b0;
    end
    logic [51:0] wdat53;
    always_comb case (wc53)
        4'd0: wdat53 = yo5;
        4'd1: wdat53 = yo9;
        4'd2: wdat53 = yo10;
        4'd3: wdat53 = xo11;
        4'd4: wdat53 = xo13;
        4'd5: wdat53 = xo21;
        4'd6: wdat53 = yo21;
        4'd7: wdat53 = yo25;
        4'd8: wdat53 = yo26;
        4'd9: wdat53 = xo27;
        4'd10: wdat53 = xo29;
        default: wdat53 = yo5;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_53_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_53_we <= 1'b1; m0_53_wa <= (w_f ? w_hA : w_hB); m0_53_wd <= wdat53; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m0_53_we <= 1'b1; m0_53_wa <= frow; m0_53_wd <= x_in_1; end
        else m0_53_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_53_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_53_we <= 1'b1; m1_53_wa <= (w_f ? w_hA : w_hB); m1_53_wd <= wdat53; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m1_53_we <= 1'b1; m1_53_wa <= frow; m1_53_wd <= x_in_1; end
        else m1_53_we <= 1'b0;
    end
    logic [51:0] wdat54;
    always_comb case (wc54)
        4'd0: wdat54 = yo6;
        4'd1: wdat54 = yo10;
        4'd2: wdat54 = xo11;
        4'd3: wdat54 = xo14;
        4'd4: wdat54 = xo22;
        4'd5: wdat54 = yo22;
        4'd6: wdat54 = yo26;
        4'd7: wdat54 = xo27;
        4'd8: wdat54 = xo30;
        default: wdat54 = yo6;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_54_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_54_we <= 1'b1; m0_54_wa <= (w_f ? w_hA : w_hB); m0_54_wd <= wdat54; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m0_54_we <= 1'b1; m0_54_wa <= frow; m0_54_wd <= x_in_2; end
        else m0_54_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_54_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_54_we <= 1'b1; m1_54_wa <= (w_f ? w_hA : w_hB); m1_54_wd <= wdat54; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m1_54_we <= 1'b1; m1_54_wa <= frow; m1_54_wd <= x_in_2; end
        else m1_54_we <= 1'b0;
    end
    logic [51:0] wdat55;
    always_comb case (wc55)
        3'd0: wdat55 = yo7;
        3'd1: wdat55 = yo11;
        3'd2: wdat55 = xo15;
        3'd3: wdat55 = xo23;
        3'd4: wdat55 = yo23;
        3'd5: wdat55 = yo27;
        3'd6: wdat55 = xo31;
        default: wdat55 = yo7;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_55_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_55_we <= 1'b1; m0_55_wa <= (w_f ? w_hA : w_hB); m0_55_wd <= wdat55; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m0_55_we <= 1'b1; m0_55_wa <= frow; m0_55_wd <= x_in_3; end
        else m0_55_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_55_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_55_we <= 1'b1; m1_55_wa <= (w_f ? w_hA : w_hB); m1_55_wd <= wdat55; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m1_55_we <= 1'b1; m1_55_wa <= frow; m1_55_wd <= x_in_3; end
        else m1_55_we <= 1'b0;
    end
    logic [51:0] wdat56;
    always_comb case (wc56)
        3'd0: wdat56 = yo8;
        3'd1: wdat56 = xo12;
        3'd2: wdat56 = xo24;
        3'd3: wdat56 = yo24;
        3'd4: wdat56 = xo28;
        default: wdat56 = yo8;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_56_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_56_we <= 1'b1; m0_56_wa <= (w_f ? w_hA : w_hB); m0_56_wd <= wdat56; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m0_56_we <= 1'b1; m0_56_wa <= frow; m0_56_wd <= x_in_0; end
        else m0_56_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_56_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_56_we <= 1'b1; m1_56_wa <= (w_f ? w_hA : w_hB); m1_56_wd <= wdat56; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m1_56_we <= 1'b1; m1_56_wa <= frow; m1_56_wd <= x_in_0; end
        else m1_56_we <= 1'b0;
    end
    logic [51:0] wdat57;
    always_comb case (wc57)
        3'd0: wdat57 = yo9;
        3'd1: wdat57 = yo12;
        3'd2: wdat57 = xo13;
        3'd3: wdat57 = xo25;
        3'd4: wdat57 = yo25;
        3'd5: wdat57 = yo28;
        3'd6: wdat57 = xo29;
        default: wdat57 = yo9;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_57_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_57_we <= 1'b1; m0_57_wa <= (w_f ? w_hA : w_hB); m0_57_wd <= wdat57; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m0_57_we <= 1'b1; m0_57_wa <= frow; m0_57_wd <= x_in_1; end
        else m0_57_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_57_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_57_we <= 1'b1; m1_57_wa <= (w_f ? w_hA : w_hB); m1_57_wd <= wdat57; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m1_57_we <= 1'b1; m1_57_wa <= frow; m1_57_wd <= x_in_1; end
        else m1_57_we <= 1'b0;
    end
    logic [51:0] wdat58;
    always_comb case (wc58)
        4'd0: wdat58 = yo10;
        4'd1: wdat58 = yo12;
        4'd2: wdat58 = xo13;
        4'd3: wdat58 = xo14;
        4'd4: wdat58 = xo26;
        4'd5: wdat58 = yo26;
        4'd6: wdat58 = yo28;
        4'd7: wdat58 = xo29;
        4'd8: wdat58 = xo30;
        default: wdat58 = yo10;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_58_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_58_we <= 1'b1; m0_58_wa <= (w_f ? w_hA : w_hB); m0_58_wd <= wdat58; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m0_58_we <= 1'b1; m0_58_wa <= frow; m0_58_wd <= x_in_2; end
        else m0_58_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_58_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_58_we <= 1'b1; m1_58_wa <= (w_f ? w_hA : w_hB); m1_58_wd <= wdat58; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m1_58_we <= 1'b1; m1_58_wa <= frow; m1_58_wd <= x_in_2; end
        else m1_58_we <= 1'b0;
    end
    logic [51:0] wdat59;
    always_comb case (wc59)
        3'd0: wdat59 = yo11;
        3'd1: wdat59 = yo13;
        3'd2: wdat59 = xo15;
        3'd3: wdat59 = xo27;
        3'd4: wdat59 = yo27;
        3'd5: wdat59 = yo29;
        3'd6: wdat59 = xo31;
        default: wdat59 = yo11;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_59_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_59_we <= 1'b1; m0_59_wa <= (w_f ? w_hA : w_hB); m0_59_wd <= wdat59; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m0_59_we <= 1'b1; m0_59_wa <= frow; m0_59_wd <= x_in_3; end
        else m0_59_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_59_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_59_we <= 1'b1; m1_59_wa <= (w_f ? w_hA : w_hB); m1_59_wd <= wdat59; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m1_59_we <= 1'b1; m1_59_wa <= frow; m1_59_wd <= x_in_3; end
        else m1_59_we <= 1'b0;
    end
    logic [51:0] wdat60;
    always_comb case (wc60)
        3'd0: wdat60 = yo12;
        3'd1: wdat60 = xo14;
        3'd2: wdat60 = xo28;
        3'd3: wdat60 = yo28;
        3'd4: wdat60 = xo30;
        default: wdat60 = yo12;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_60_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_60_we <= 1'b1; m0_60_wa <= (w_f ? w_hA : w_hB); m0_60_wd <= wdat60; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m0_60_we <= 1'b1; m0_60_wa <= frow; m0_60_wd <= x_in_0; end
        else m0_60_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_60_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_60_we <= 1'b1; m1_60_wa <= (w_f ? w_hA : w_hB); m1_60_wd <= wdat60; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m1_60_we <= 1'b1; m1_60_wa <= frow; m1_60_wd <= x_in_0; end
        else m1_60_we <= 1'b0;
    end
    logic [51:0] wdat61;
    always_comb case (wc61)
        3'd0: wdat61 = yo13;
        3'd1: wdat61 = yo14;
        3'd2: wdat61 = xo15;
        3'd3: wdat61 = xo29;
        3'd4: wdat61 = yo29;
        3'd5: wdat61 = yo30;
        3'd6: wdat61 = xo31;
        default: wdat61 = yo13;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_61_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_61_we <= 1'b1; m0_61_wa <= (w_f ? w_hA : w_hB); m0_61_wd <= wdat61; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m0_61_we <= 1'b1; m0_61_wa <= frow; m0_61_wd <= x_in_1; end
        else m0_61_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_61_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_61_we <= 1'b1; m1_61_wa <= (w_f ? w_hA : w_hB); m1_61_wd <= wdat61; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m1_61_we <= 1'b1; m1_61_wa <= frow; m1_61_wd <= x_in_1; end
        else m1_61_we <= 1'b0;
    end
    logic [51:0] wdat62;
    always_comb case (wc62)
        3'd0: wdat62 = yo14;
        3'd1: wdat62 = xo15;
        3'd2: wdat62 = xo30;
        3'd3: wdat62 = yo30;
        3'd4: wdat62 = xo31;
        default: wdat62 = yo14;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_62_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_62_we <= 1'b1; m0_62_wa <= (w_f ? w_hA : w_hB); m0_62_wd <= wdat62; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m0_62_we <= 1'b1; m0_62_wa <= frow; m0_62_wd <= x_in_2; end
        else m0_62_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_62_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_62_we <= 1'b1; m1_62_wa <= (w_f ? w_hA : w_hB); m1_62_wd <= wdat62; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m1_62_we <= 1'b1; m1_62_wa <= frow; m1_62_wd <= x_in_2; end
        else m1_62_we <= 1'b0;
    end
    logic [51:0] wdat63;
    always_comb case (wc63)
        2'd0: wdat63 = yo15;
        2'd1: wdat63 = xo31;
        2'd2: wdat63 = yo31;
        default: wdat63 = yo15;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_63_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_63_we <= 1'b1; m0_63_wa <= (w_f ? w_hA : w_hB); m0_63_wd <= wdat63; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m0_63_we <= 1'b1; m0_63_wa <= frow; m0_63_wd <= x_in_3; end
        else m0_63_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_63_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_63_we <= 1'b1; m1_63_wa <= (w_f ? w_hA : w_hB); m1_63_wd <= wdat63; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m1_63_we <= 1'b1; m1_63_wa <= frow; m1_63_wd <= x_in_3; end
        else m1_63_we <= 1'b0;
    end
    // ---- output: lane l of beat (row, sub) is bank ((sub*io + l) ^ (parity(row) << b))
    logic [51:0] drd0; assign drd0 = db_set[2] ? m1_0_rd : m0_0_rd;
    logic [51:0] drd1; assign drd1 = db_set[2] ? m1_1_rd : m0_1_rd;
    logic [51:0] drd2; assign drd2 = db_set[2] ? m1_2_rd : m0_2_rd;
    logic [51:0] drd3; assign drd3 = db_set[2] ? m1_3_rd : m0_3_rd;
    logic [51:0] drd4; assign drd4 = db_set[2] ? m1_4_rd : m0_4_rd;
    logic [51:0] drd5; assign drd5 = db_set[2] ? m1_5_rd : m0_5_rd;
    logic [51:0] drd6; assign drd6 = db_set[2] ? m1_6_rd : m0_6_rd;
    logic [51:0] drd7; assign drd7 = db_set[2] ? m1_7_rd : m0_7_rd;
    logic [51:0] drd8; assign drd8 = db_set[2] ? m1_8_rd : m0_8_rd;
    logic [51:0] drd9; assign drd9 = db_set[2] ? m1_9_rd : m0_9_rd;
    logic [51:0] drd10; assign drd10 = db_set[2] ? m1_10_rd : m0_10_rd;
    logic [51:0] drd11; assign drd11 = db_set[2] ? m1_11_rd : m0_11_rd;
    logic [51:0] drd12; assign drd12 = db_set[2] ? m1_12_rd : m0_12_rd;
    logic [51:0] drd13; assign drd13 = db_set[2] ? m1_13_rd : m0_13_rd;
    logic [51:0] drd14; assign drd14 = db_set[2] ? m1_14_rd : m0_14_rd;
    logic [51:0] drd15; assign drd15 = db_set[2] ? m1_15_rd : m0_15_rd;
    logic [51:0] drd16; assign drd16 = db_set[2] ? m1_16_rd : m0_16_rd;
    logic [51:0] drd17; assign drd17 = db_set[2] ? m1_17_rd : m0_17_rd;
    logic [51:0] drd18; assign drd18 = db_set[2] ? m1_18_rd : m0_18_rd;
    logic [51:0] drd19; assign drd19 = db_set[2] ? m1_19_rd : m0_19_rd;
    logic [51:0] drd20; assign drd20 = db_set[2] ? m1_20_rd : m0_20_rd;
    logic [51:0] drd21; assign drd21 = db_set[2] ? m1_21_rd : m0_21_rd;
    logic [51:0] drd22; assign drd22 = db_set[2] ? m1_22_rd : m0_22_rd;
    logic [51:0] drd23; assign drd23 = db_set[2] ? m1_23_rd : m0_23_rd;
    logic [51:0] drd24; assign drd24 = db_set[2] ? m1_24_rd : m0_24_rd;
    logic [51:0] drd25; assign drd25 = db_set[2] ? m1_25_rd : m0_25_rd;
    logic [51:0] drd26; assign drd26 = db_set[2] ? m1_26_rd : m0_26_rd;
    logic [51:0] drd27; assign drd27 = db_set[2] ? m1_27_rd : m0_27_rd;
    logic [51:0] drd28; assign drd28 = db_set[2] ? m1_28_rd : m0_28_rd;
    logic [51:0] drd29; assign drd29 = db_set[2] ? m1_29_rd : m0_29_rd;
    logic [51:0] drd30; assign drd30 = db_set[2] ? m1_30_rd : m0_30_rd;
    logic [51:0] drd31; assign drd31 = db_set[2] ? m1_31_rd : m0_31_rd;
    logic [51:0] drd32; assign drd32 = db_set[2] ? m1_32_rd : m0_32_rd;
    logic [51:0] drd33; assign drd33 = db_set[2] ? m1_33_rd : m0_33_rd;
    logic [51:0] drd34; assign drd34 = db_set[2] ? m1_34_rd : m0_34_rd;
    logic [51:0] drd35; assign drd35 = db_set[2] ? m1_35_rd : m0_35_rd;
    logic [51:0] drd36; assign drd36 = db_set[2] ? m1_36_rd : m0_36_rd;
    logic [51:0] drd37; assign drd37 = db_set[2] ? m1_37_rd : m0_37_rd;
    logic [51:0] drd38; assign drd38 = db_set[2] ? m1_38_rd : m0_38_rd;
    logic [51:0] drd39; assign drd39 = db_set[2] ? m1_39_rd : m0_39_rd;
    logic [51:0] drd40; assign drd40 = db_set[2] ? m1_40_rd : m0_40_rd;
    logic [51:0] drd41; assign drd41 = db_set[2] ? m1_41_rd : m0_41_rd;
    logic [51:0] drd42; assign drd42 = db_set[2] ? m1_42_rd : m0_42_rd;
    logic [51:0] drd43; assign drd43 = db_set[2] ? m1_43_rd : m0_43_rd;
    logic [51:0] drd44; assign drd44 = db_set[2] ? m1_44_rd : m0_44_rd;
    logic [51:0] drd45; assign drd45 = db_set[2] ? m1_45_rd : m0_45_rd;
    logic [51:0] drd46; assign drd46 = db_set[2] ? m1_46_rd : m0_46_rd;
    logic [51:0] drd47; assign drd47 = db_set[2] ? m1_47_rd : m0_47_rd;
    logic [51:0] drd48; assign drd48 = db_set[2] ? m1_48_rd : m0_48_rd;
    logic [51:0] drd49; assign drd49 = db_set[2] ? m1_49_rd : m0_49_rd;
    logic [51:0] drd50; assign drd50 = db_set[2] ? m1_50_rd : m0_50_rd;
    logic [51:0] drd51; assign drd51 = db_set[2] ? m1_51_rd : m0_51_rd;
    logic [51:0] drd52; assign drd52 = db_set[2] ? m1_52_rd : m0_52_rd;
    logic [51:0] drd53; assign drd53 = db_set[2] ? m1_53_rd : m0_53_rd;
    logic [51:0] drd54; assign drd54 = db_set[2] ? m1_54_rd : m0_54_rd;
    logic [51:0] drd55; assign drd55 = db_set[2] ? m1_55_rd : m0_55_rd;
    logic [51:0] drd56; assign drd56 = db_set[2] ? m1_56_rd : m0_56_rd;
    logic [51:0] drd57; assign drd57 = db_set[2] ? m1_57_rd : m0_57_rd;
    logic [51:0] drd58; assign drd58 = db_set[2] ? m1_58_rd : m0_58_rd;
    logic [51:0] drd59; assign drd59 = db_set[2] ? m1_59_rd : m0_59_rd;
    logic [51:0] drd60; assign drd60 = db_set[2] ? m1_60_rd : m0_60_rd;
    logic [51:0] drd61; assign drd61 = db_set[2] ? m1_61_rd : m0_61_rd;
    logic [51:0] drd62; assign drd62 = db_set[2] ? m1_62_rd : m0_62_rd;
    logic [51:0] drd63; assign drd63 = db_set[2] ? m1_63_rd : m0_63_rd;
    logic [51:0] yr_0;
    always_ff @(posedge clk) case ({db_sub[2], db_pi[2]})
        {4'd0, 1'b0}: yr_0 <= drd0;
        {4'd0, 1'b1}: yr_0 <= drd32;
        {4'd1, 1'b0}: yr_0 <= drd4;
        {4'd1, 1'b1}: yr_0 <= drd36;
        {4'd2, 1'b0}: yr_0 <= drd8;
        {4'd2, 1'b1}: yr_0 <= drd40;
        {4'd3, 1'b0}: yr_0 <= drd12;
        {4'd3, 1'b1}: yr_0 <= drd44;
        {4'd4, 1'b0}: yr_0 <= drd16;
        {4'd4, 1'b1}: yr_0 <= drd48;
        {4'd5, 1'b0}: yr_0 <= drd20;
        {4'd5, 1'b1}: yr_0 <= drd52;
        {4'd6, 1'b0}: yr_0 <= drd24;
        {4'd6, 1'b1}: yr_0 <= drd56;
        {4'd7, 1'b0}: yr_0 <= drd28;
        {4'd7, 1'b1}: yr_0 <= drd60;
        {4'd8, 1'b0}: yr_0 <= drd32;
        {4'd8, 1'b1}: yr_0 <= drd0;
        {4'd9, 1'b0}: yr_0 <= drd36;
        {4'd9, 1'b1}: yr_0 <= drd4;
        {4'd10, 1'b0}: yr_0 <= drd40;
        {4'd10, 1'b1}: yr_0 <= drd8;
        {4'd11, 1'b0}: yr_0 <= drd44;
        {4'd11, 1'b1}: yr_0 <= drd12;
        {4'd12, 1'b0}: yr_0 <= drd48;
        {4'd12, 1'b1}: yr_0 <= drd16;
        {4'd13, 1'b0}: yr_0 <= drd52;
        {4'd13, 1'b1}: yr_0 <= drd20;
        {4'd14, 1'b0}: yr_0 <= drd56;
        {4'd14, 1'b1}: yr_0 <= drd24;
        {4'd15, 1'b0}: yr_0 <= drd60;
        {4'd15, 1'b1}: yr_0 <= drd28;
        default: yr_0 <= drd0;
    endcase
    logic [51:0] yr_1;
    always_ff @(posedge clk) case ({db_sub[2], db_pi[2]})
        {4'd0, 1'b0}: yr_1 <= drd1;
        {4'd0, 1'b1}: yr_1 <= drd33;
        {4'd1, 1'b0}: yr_1 <= drd5;
        {4'd1, 1'b1}: yr_1 <= drd37;
        {4'd2, 1'b0}: yr_1 <= drd9;
        {4'd2, 1'b1}: yr_1 <= drd41;
        {4'd3, 1'b0}: yr_1 <= drd13;
        {4'd3, 1'b1}: yr_1 <= drd45;
        {4'd4, 1'b0}: yr_1 <= drd17;
        {4'd4, 1'b1}: yr_1 <= drd49;
        {4'd5, 1'b0}: yr_1 <= drd21;
        {4'd5, 1'b1}: yr_1 <= drd53;
        {4'd6, 1'b0}: yr_1 <= drd25;
        {4'd6, 1'b1}: yr_1 <= drd57;
        {4'd7, 1'b0}: yr_1 <= drd29;
        {4'd7, 1'b1}: yr_1 <= drd61;
        {4'd8, 1'b0}: yr_1 <= drd33;
        {4'd8, 1'b1}: yr_1 <= drd1;
        {4'd9, 1'b0}: yr_1 <= drd37;
        {4'd9, 1'b1}: yr_1 <= drd5;
        {4'd10, 1'b0}: yr_1 <= drd41;
        {4'd10, 1'b1}: yr_1 <= drd9;
        {4'd11, 1'b0}: yr_1 <= drd45;
        {4'd11, 1'b1}: yr_1 <= drd13;
        {4'd12, 1'b0}: yr_1 <= drd49;
        {4'd12, 1'b1}: yr_1 <= drd17;
        {4'd13, 1'b0}: yr_1 <= drd53;
        {4'd13, 1'b1}: yr_1 <= drd21;
        {4'd14, 1'b0}: yr_1 <= drd57;
        {4'd14, 1'b1}: yr_1 <= drd25;
        {4'd15, 1'b0}: yr_1 <= drd61;
        {4'd15, 1'b1}: yr_1 <= drd29;
        default: yr_1 <= drd1;
    endcase
    logic [51:0] yr_2;
    always_ff @(posedge clk) case ({db_sub[2], db_pi[2]})
        {4'd0, 1'b0}: yr_2 <= drd2;
        {4'd0, 1'b1}: yr_2 <= drd34;
        {4'd1, 1'b0}: yr_2 <= drd6;
        {4'd1, 1'b1}: yr_2 <= drd38;
        {4'd2, 1'b0}: yr_2 <= drd10;
        {4'd2, 1'b1}: yr_2 <= drd42;
        {4'd3, 1'b0}: yr_2 <= drd14;
        {4'd3, 1'b1}: yr_2 <= drd46;
        {4'd4, 1'b0}: yr_2 <= drd18;
        {4'd4, 1'b1}: yr_2 <= drd50;
        {4'd5, 1'b0}: yr_2 <= drd22;
        {4'd5, 1'b1}: yr_2 <= drd54;
        {4'd6, 1'b0}: yr_2 <= drd26;
        {4'd6, 1'b1}: yr_2 <= drd58;
        {4'd7, 1'b0}: yr_2 <= drd30;
        {4'd7, 1'b1}: yr_2 <= drd62;
        {4'd8, 1'b0}: yr_2 <= drd34;
        {4'd8, 1'b1}: yr_2 <= drd2;
        {4'd9, 1'b0}: yr_2 <= drd38;
        {4'd9, 1'b1}: yr_2 <= drd6;
        {4'd10, 1'b0}: yr_2 <= drd42;
        {4'd10, 1'b1}: yr_2 <= drd10;
        {4'd11, 1'b0}: yr_2 <= drd46;
        {4'd11, 1'b1}: yr_2 <= drd14;
        {4'd12, 1'b0}: yr_2 <= drd50;
        {4'd12, 1'b1}: yr_2 <= drd18;
        {4'd13, 1'b0}: yr_2 <= drd54;
        {4'd13, 1'b1}: yr_2 <= drd22;
        {4'd14, 1'b0}: yr_2 <= drd58;
        {4'd14, 1'b1}: yr_2 <= drd26;
        {4'd15, 1'b0}: yr_2 <= drd62;
        {4'd15, 1'b1}: yr_2 <= drd30;
        default: yr_2 <= drd2;
    endcase
    logic [51:0] yr_3;
    always_ff @(posedge clk) case ({db_sub[2], db_pi[2]})
        {4'd0, 1'b0}: yr_3 <= drd3;
        {4'd0, 1'b1}: yr_3 <= drd35;
        {4'd1, 1'b0}: yr_3 <= drd7;
        {4'd1, 1'b1}: yr_3 <= drd39;
        {4'd2, 1'b0}: yr_3 <= drd11;
        {4'd2, 1'b1}: yr_3 <= drd43;
        {4'd3, 1'b0}: yr_3 <= drd15;
        {4'd3, 1'b1}: yr_3 <= drd47;
        {4'd4, 1'b0}: yr_3 <= drd19;
        {4'd4, 1'b1}: yr_3 <= drd51;
        {4'd5, 1'b0}: yr_3 <= drd23;
        {4'd5, 1'b1}: yr_3 <= drd55;
        {4'd6, 1'b0}: yr_3 <= drd27;
        {4'd6, 1'b1}: yr_3 <= drd59;
        {4'd7, 1'b0}: yr_3 <= drd31;
        {4'd7, 1'b1}: yr_3 <= drd63;
        {4'd8, 1'b0}: yr_3 <= drd35;
        {4'd8, 1'b1}: yr_3 <= drd3;
        {4'd9, 1'b0}: yr_3 <= drd39;
        {4'd9, 1'b1}: yr_3 <= drd7;
        {4'd10, 1'b0}: yr_3 <= drd43;
        {4'd10, 1'b1}: yr_3 <= drd11;
        {4'd11, 1'b0}: yr_3 <= drd47;
        {4'd11, 1'b1}: yr_3 <= drd15;
        {4'd12, 1'b0}: yr_3 <= drd51;
        {4'd12, 1'b1}: yr_3 <= drd19;
        {4'd13, 1'b0}: yr_3 <= drd55;
        {4'd13, 1'b1}: yr_3 <= drd23;
        {4'd14, 1'b0}: yr_3 <= drd59;
        {4'd14, 1'b1}: yr_3 <= drd27;
        {4'd15, 1'b0}: yr_3 <= drd63;
        {4'd15, 1'b1}: yr_3 <= drd31;
        default: yr_3 <= drd3;
    endcase
    logic yv; always_ff @(posedge clk) yv <= rst ? 1'b0 : db_v[2];
    assign y_out_0 = yr_0;
    assign y_out_1 = yr_1;
    assign y_out_2 = yr_2;
    assign y_out_3 = yr_3;
    assign out_valid = yv;
endmodule
