`timescale 1ns / 1ps
// Ia_n4096_q60w_B8_rns: iterative NTT, n=4096, 8 butterflies over 2 x 16 banks of 256 x 60 bits, 2 I/O lanes, run-time q, direction both, butterfly latency 17, write-back latency 23, stage gaps [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
module Ia_n4096_q60w_B8_rns (
    input  logic clk,
    input  logic rst,
    input  logic DIR,
    input  logic tw_valid,
    output logic tw_ready,
    input  logic [119:0] tw_data,
    input  logic in_valid,
    output logic in_ready,
    input  logic [59:0] x_in_0,
    input  logic [59:0] x_in_1,
    output logic out_valid,
    output logic [59:0] y_out_0,
    output logic [59:0] y_out_1
    );
    (* max_fanout = 32 *) logic DIR_r;
    always_ff @(posedge clk) DIR_r <= DIR;
    (* max_fanout = 16 *) logic [29:0] QH_r;
    logic [29:0] QH_n;      // the next polynomial's (record header), into QH_r at its start
    (* max_fanout = 16 *) logic [59:0] QHALF_r;
    logic [59:0] QHALF_n;      // the next polynomial's (record header), into QHALF_r at its start
    // ---- controller: fill (input), compute (butterflies), drain (output) over two bank sets
    logic fset; logic [10:0] fptr; logic [1:0] full, busy, res;
    logic cact, cset, cnext; logic [3:0] s; logic [7:0] tau; logic [0:0] gap;
    logic dact, dset, dnext; logic [10:0] dptr;
    logic [22:0] dsr, dsrs;
    logic fill_ok, acc, flast, issue, tlast, clast, startc, dlastb, startd, done, done_set;
    // ---- record stream (recycle): per polynomial a header (bit 0 keep, then the modulus constants), then its twiddles, 2 entries a beat
    localparam logic [1:0] L_HDR = 2'd0, L_DATA = 2'd1, L_WAIT = 2'd2;
    logic [1:0] lst, lst_n; logic lahead, lahead_n, nkeep, hdr_ok, perm, tacc, hlast, klast, hkeep;
    logic [3:0] ls, ls_n; logic [9:0] lk, lk_n; logic [0:0] hptr, hptr_n;
    logic [4:0] qw;
    logic [3:0] relst; logic twok;
    assign hdr_ok = (lst == L_WAIT) || ((lst == L_DATA) && lahead);
    assign fill_ok = !full[fset] && !busy[fset] && (!res[fset] || (dact && (dset == fset) && (fptr < dptr)));
    assign in_ready = fill_ok;
    assign acc = in_valid && fill_ok && !rst;
    assign flast = fptr == 11'd2047;
    assign issue = cact && (gap == '0) && twok;
    assign tlast = tau == 8'd255;
    assign clast = issue && tlast && (s == 4'd11);
    assign startc = full[cnext] && hdr_ok && (nkeep ? (!cact || clast) : (!cact && (qw == '0)));
    assign dlastb = dact && (dptr == 11'd2047);
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
    assign perm = !lahead || (relst > 4'(ls));
    assign tw_ready = (lst == L_HDR) || ((lst == L_DATA) && perm);
    assign tacc = tw_valid && tw_ready && !rst;
    assign hlast = 1'b1;
    function automatic logic [9:0] nbs_of(input logic [3:0] s_);
        case (s_)
            4'd0: nbs_of = 10'd3;
            4'd1: nbs_of = 10'd3;
            4'd2: nbs_of = 10'd3;
            4'd3: nbs_of = 10'd3;
            4'd4: nbs_of = 10'd7;
            4'd5: nbs_of = 10'd15;
            4'd6: nbs_of = 10'd31;
            4'd7: nbs_of = 10'd63;
            4'd8: nbs_of = 10'd127;
            4'd9: nbs_of = 10'd255;
            4'd10: nbs_of = 10'd511;
            4'd11: nbs_of = 10'd1023;
            default: nbs_of = '0;
        endcase
    endfunction
    assign klast = lk == nbs_of(ls);
    logic [119:0] hdr_w; assign hdr_w = tw_data;
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
                        if (ls == 4'd11) begin ls_n = '0; lst_n = (lahead && !startc) ? L_WAIT : L_HDR; end
                    end else lk_n = lk + 1'b1;
                end
            end
            L_WAIT: if (startc) lst_n = L_HDR;
            default: lst_n = L_HDR;
        endcase
    end
    logic [3:0] s_nx; logic [7:0] tau_nx;
    assign s_nx = startc ? '0 : ((issue && tlast) ? s + 1'b1 : s);
    assign tau_nx = startc ? '0 : (issue ? (tlast ? '0 : tau + 1'b1) : tau);
    always_ff @(posedge clk) begin
        if (rst) begin
            lst <= L_HDR; lahead <= 1'b1; ls <= '0; lk <= '0; hptr <= '0; nkeep <= 1'b0; qw <= '0; relst <= 4'd12; twok <= 1'b0;
        end else begin
            lst <= lst_n; lahead <= lahead_n; ls <= ls_n; lk <= lk_n; hptr <= hptr_n;
            if (lst == L_HDR && tacc && hlast) nkeep <= hkeep;
            qw <= clast ? 5'd19 : ((qw != '0) ? qw - 1'b1 : '0);
            if (startc) relst <= '0; else if (clast) relst <= 4'd12; else if (issue && (tau == '0)) relst <= 4'(s);
            twok <= (tau_nx != '0) || !((lst_n == L_DATA) && !lahead_n) || (ls_n > s_nx);
        end
    end
    // the modulus constants: the header into *_n, into *_r (the butterflies' constants) at the start of a polynomial with a new modulus
    always_ff @(posedge clk) begin
        if (lst == L_HDR && tacc && hlast && !hkeep) QH_n <= hdr_w[30:1];
        if (lst == L_HDR && tacc && hlast && !hkeep) QHALF_n <= hdr_w[90:31];
        if (!rst && startc && !nkeep) begin QH_r <= QH_n; QHALF_r <= QHALF_n; end
    end
    // ---- stage decode (IterativeNTTScheme.rowAddrs / flip / twiddleIndex)
    function automatic logic [16:0] rows_of(input logic [3:0] s_, input logic [7:0] t_);
        logic [7:0] ha, hb; logic f;
        ha = t_; hb = t_; f = ^t_;
        case (s_)
            4'd4: begin ha = {t_[7:1], 1'b0}; hb = ha | 8'h1; f = t_[0] ^ (^ha); end
            4'd5: begin ha = {t_[7:2], 1'b0, t_[1:1]}; hb = ha | 8'h2; f = t_[0] ^ (^ha); end
            4'd6: begin ha = {t_[7:3], 1'b0, t_[2:1]}; hb = ha | 8'h4; f = t_[0] ^ (^ha); end
            4'd7: begin ha = {t_[7:4], 1'b0, t_[3:1]}; hb = ha | 8'h8; f = t_[0] ^ (^ha); end
            4'd8: begin ha = {t_[7:5], 1'b0, t_[4:1]}; hb = ha | 8'h10; f = t_[0] ^ (^ha); end
            4'd9: begin ha = {t_[7:6], 1'b0, t_[5:1]}; hb = ha | 8'h20; f = t_[0] ^ (^ha); end
            4'd10: begin ha = {t_[7:7], 1'b0, t_[6:1]}; hb = ha | 8'h40; f = t_[0] ^ (^ha); end
            4'd11: begin ha = {1'b0, t_[7:1]}; hb = ha | 8'h80; f = t_[0] ^ (^ha); end
            default: ;
        endcase
        rows_of = {f, hb, ha};
    endfunction
    function automatic logic [8:0] tidx_of(input logic [3:0] s_, input logic [7:0] t_);
        case (s_)
            4'd4: tidx_of = 9'd0 + 9'(t_ & 8'h1);
            4'd5: tidx_of = 9'd2 + 9'(t_ & 8'h3);
            4'd6: tidx_of = 9'd6 + 9'(t_ & 8'h7);
            4'd7: tidx_of = 9'd14 + 9'(t_ & 8'hf);
            4'd8: tidx_of = 9'd30 + 9'(t_ & 8'h1f);
            4'd9: tidx_of = 9'd62 + 9'(t_ & 8'h3f);
            4'd10: tidx_of = 9'd126 + 9'(t_ & 8'h7f);
            4'd11: tidx_of = 9'd254 + 9'(t_ & 8'hff);
            default: tidx_of = '0;
        endcase
    endfunction
    logic [16:0] c_rows; assign c_rows = rows_of(s, tau);
    logic [7:0] c_hA, c_hB; logic c_flip;
    assign c_hA = c_rows[7:0]; assign c_hB = c_rows[15:8]; assign c_flip = c_rows[16];
    // ---- issue bundle, delayed: cb_*[k] is the read issued k+1 cycles ago (k = 0 .. 21)
    logic cb_v [22]; logic cb_set [22]; logic cb_f [22];
    logic [3:0] cb_s [22]; logic [7:0] cb_t [22]; logic [7:0] cb_sw [22];
    logic [7:0] c_sw;
    always_comb begin
        c_sw = '0;
        if (DIR_r) case (s)
            4'd1: c_sw = 8'haa;
            4'd2: c_sw = 8'hee;
            4'd3: c_sw = 8'hfe;
            4'd4: c_sw = {7'h7f, |(tau & 8'h1)};
            4'd5: c_sw = {7'h7f, |(tau & 8'h3)};
            4'd6: c_sw = {7'h7f, |(tau & 8'h7)};
            4'd7: c_sw = {7'h7f, |(tau & 8'hf)};
            4'd8: c_sw = {7'h7f, |(tau & 8'h1f)};
            4'd9: c_sw = {7'h7f, |(tau & 8'h3f)};
            4'd10: c_sw = {7'h7f, |(tau & 8'h7f)};
            4'd11: c_sw = {7'h7f, |(tau & 8'hff)};
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
    logic [7:0] drow; assign drow = 8'(dptr >> 3);
    logic [2:0] dsub; assign dsub = dptr[2:0];
    logic db_v [3]; logic db_set [3]; logic db_pi [3]; logic [2:0] db_sub [3];
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
    logic [7:0] frow; assign frow = 8'(fptr >> 3);
    logic fpi; assign fpi = ^frow;
    logic [2:0] fsub; assign fsub = fptr[2:0];
    logic [16:0] w_rows; assign w_rows = rows_of(cb_s[21], cb_t[21]);
    logic [7:0] w_hA, w_hB; assign w_hA = w_rows[7:0]; assign w_hB = w_rows[15:8];
    logic w_v, w_set, w_f; assign w_v = cb_v[21]; assign w_set = cb_set[21]; assign w_f = cb_f[21];
    logic [0:0] rc0;
    logic [2:0] rc1;
    logic [1:0] rc2;
    logic [2:0] rc3;
    logic [1:0] rc4;
    logic [2:0] rc5;
    logic [2:0] rc6;
    logic [1:0] rc7;
    logic [1:0] rc8;
    logic [2:0] rc9;
    logic [2:0] rc10;
    logic [1:0] rc11;
    logic [2:0] rc12;
    logic [1:0] rc13;
    logic [2:0] rc14;
    logic [0:0] rc15;
    logic [1:0] wc0;
    logic [2:0] wc1;
    logic [2:0] wc2;
    logic [2:0] wc3;
    logic [2:0] wc4;
    logic [2:0] wc5;
    logic [2:0] wc6;
    logic [1:0] wc7;
    logic [1:0] wc8;
    logic [2:0] wc9;
    logic [2:0] wc10;
    logic [2:0] wc11;
    logic [2:0] wc12;
    logic [2:0] wc13;
    logic [2:0] wc14;
    logic [1:0] wc15;
    logic [3:0] rk_s, wk_s; logic rk_f, wk_f;
    assign rk_s = cb_s[1]; assign rk_f = cb_f[1];
    assign wk_s = cb_s[20]; assign wk_f = cb_f[20];
    always_ff @(posedge clk) begin
        case ({rk_s, rk_f})
            {4'd0, 1'b0}: begin rc0 <= 1'd0; rc1 <= 3'd1; rc2 <= 2'd1; rc3 <= 3'd1; rc4 <= 2'd1; rc5 <= 3'd1; rc6 <= 3'd2; rc7 <= 2'd1; rc8 <= 2'd2; rc9 <= 3'd3; rc10 <= 3'd4; rc11 <= 2'd2; rc12 <= 3'd4; rc13 <= 2'd2; rc14 <= 3'd6; rc15 <= 1'd1; end
            {4'd0, 1'b1}: begin rc0 <= 1'd1; rc1 <= 3'd5; rc2 <= 2'd3; rc3 <= 3'd4; rc4 <= 2'd3; rc5 <= 3'd4; rc6 <= 3'd5; rc7 <= 2'd3; rc8 <= 2'd0; rc9 <= 3'd0; rc10 <= 3'd1; rc11 <= 2'd0; rc12 <= 3'd1; rc13 <= 2'd0; rc14 <= 3'd2; rc15 <= 1'd0; end
            {4'd1, 1'b0}: begin rc0 <= 1'd0; rc1 <= 3'd2; rc2 <= 2'd0; rc3 <= 3'd1; rc4 <= 2'd1; rc5 <= 3'd2; rc6 <= 3'd1; rc7 <= 2'd1; rc8 <= 2'd2; rc9 <= 3'd4; rc10 <= 3'd3; rc11 <= 2'd2; rc12 <= 3'd4; rc13 <= 2'd3; rc14 <= 3'd5; rc15 <= 1'd1; end
            {4'd1, 1'b1}: begin rc0 <= 1'd1; rc1 <= 3'd6; rc2 <= 2'd2; rc3 <= 3'd4; rc4 <= 2'd3; rc5 <= 3'd5; rc6 <= 3'd4; rc7 <= 2'd3; rc8 <= 2'd0; rc9 <= 3'd1; rc10 <= 3'd0; rc11 <= 2'd0; rc12 <= 3'd1; rc13 <= 2'd1; rc14 <= 3'd1; rc15 <= 1'd0; end
            {4'd2, 1'b0}: begin rc0 <= 1'd0; rc1 <= 3'd3; rc2 <= 2'd0; rc3 <= 3'd2; rc4 <= 2'd0; rc5 <= 3'd2; rc6 <= 3'd0; rc7 <= 2'd1; rc8 <= 2'd2; rc9 <= 3'd5; rc10 <= 3'd3; rc11 <= 2'd3; rc12 <= 3'd3; rc13 <= 2'd3; rc14 <= 3'd4; rc15 <= 1'd1; end
            {4'd2, 1'b1}: begin rc0 <= 1'd1; rc1 <= 3'd7; rc2 <= 2'd2; rc3 <= 3'd5; rc4 <= 2'd2; rc5 <= 3'd5; rc6 <= 3'd3; rc7 <= 2'd3; rc8 <= 2'd0; rc9 <= 3'd2; rc10 <= 3'd0; rc11 <= 2'd1; rc12 <= 3'd0; rc13 <= 2'd1; rc14 <= 3'd0; rc15 <= 1'd0; end
            {4'd3, 1'b0}: begin rc0 <= 1'd0; rc1 <= 3'd4; rc2 <= 2'd0; rc3 <= 3'd3; rc4 <= 2'd0; rc5 <= 3'd3; rc6 <= 3'd0; rc7 <= 2'd2; rc8 <= 2'd1; rc9 <= 3'd5; rc10 <= 3'd2; rc11 <= 2'd3; rc12 <= 3'd2; rc13 <= 2'd3; rc14 <= 3'd3; rc15 <= 1'd1; end
            {4'd3, 1'b1}: begin rc0 <= 1'd1; rc1 <= 3'd0; rc2 <= 2'd2; rc3 <= 3'd0; rc4 <= 2'd2; rc5 <= 3'd0; rc6 <= 3'd3; rc7 <= 2'd0; rc8 <= 2'd3; rc9 <= 3'd2; rc10 <= 3'd5; rc11 <= 2'd1; rc12 <= 3'd5; rc13 <= 2'd1; rc14 <= 3'd7; rc15 <= 1'd0; end
            {4'd4, 1'b0}: begin rc0 <= 1'd0; rc1 <= 3'd4; rc2 <= 2'd0; rc3 <= 3'd3; rc4 <= 2'd0; rc5 <= 3'd3; rc6 <= 3'd0; rc7 <= 2'd2; rc8 <= 2'd1; rc9 <= 3'd5; rc10 <= 3'd2; rc11 <= 2'd3; rc12 <= 3'd2; rc13 <= 2'd3; rc14 <= 3'd3; rc15 <= 1'd1; end
            {4'd4, 1'b1}: begin rc0 <= 1'd1; rc1 <= 3'd0; rc2 <= 2'd2; rc3 <= 3'd0; rc4 <= 2'd2; rc5 <= 3'd0; rc6 <= 3'd3; rc7 <= 2'd0; rc8 <= 2'd3; rc9 <= 3'd2; rc10 <= 3'd5; rc11 <= 2'd1; rc12 <= 3'd5; rc13 <= 2'd1; rc14 <= 3'd7; rc15 <= 1'd0; end
            {4'd5, 1'b0}: begin rc0 <= 1'd0; rc1 <= 3'd4; rc2 <= 2'd0; rc3 <= 3'd3; rc4 <= 2'd0; rc5 <= 3'd3; rc6 <= 3'd0; rc7 <= 2'd2; rc8 <= 2'd1; rc9 <= 3'd5; rc10 <= 3'd2; rc11 <= 2'd3; rc12 <= 3'd2; rc13 <= 2'd3; rc14 <= 3'd3; rc15 <= 1'd1; end
            {4'd5, 1'b1}: begin rc0 <= 1'd1; rc1 <= 3'd0; rc2 <= 2'd2; rc3 <= 3'd0; rc4 <= 2'd2; rc5 <= 3'd0; rc6 <= 3'd3; rc7 <= 2'd0; rc8 <= 2'd3; rc9 <= 3'd2; rc10 <= 3'd5; rc11 <= 2'd1; rc12 <= 3'd5; rc13 <= 2'd1; rc14 <= 3'd7; rc15 <= 1'd0; end
            {4'd6, 1'b0}: begin rc0 <= 1'd0; rc1 <= 3'd4; rc2 <= 2'd0; rc3 <= 3'd3; rc4 <= 2'd0; rc5 <= 3'd3; rc6 <= 3'd0; rc7 <= 2'd2; rc8 <= 2'd1; rc9 <= 3'd5; rc10 <= 3'd2; rc11 <= 2'd3; rc12 <= 3'd2; rc13 <= 2'd3; rc14 <= 3'd3; rc15 <= 1'd1; end
            {4'd6, 1'b1}: begin rc0 <= 1'd1; rc1 <= 3'd0; rc2 <= 2'd2; rc3 <= 3'd0; rc4 <= 2'd2; rc5 <= 3'd0; rc6 <= 3'd3; rc7 <= 2'd0; rc8 <= 2'd3; rc9 <= 3'd2; rc10 <= 3'd5; rc11 <= 2'd1; rc12 <= 3'd5; rc13 <= 2'd1; rc14 <= 3'd7; rc15 <= 1'd0; end
            {4'd7, 1'b0}: begin rc0 <= 1'd0; rc1 <= 3'd4; rc2 <= 2'd0; rc3 <= 3'd3; rc4 <= 2'd0; rc5 <= 3'd3; rc6 <= 3'd0; rc7 <= 2'd2; rc8 <= 2'd1; rc9 <= 3'd5; rc10 <= 3'd2; rc11 <= 2'd3; rc12 <= 3'd2; rc13 <= 2'd3; rc14 <= 3'd3; rc15 <= 1'd1; end
            {4'd7, 1'b1}: begin rc0 <= 1'd1; rc1 <= 3'd0; rc2 <= 2'd2; rc3 <= 3'd0; rc4 <= 2'd2; rc5 <= 3'd0; rc6 <= 3'd3; rc7 <= 2'd0; rc8 <= 2'd3; rc9 <= 3'd2; rc10 <= 3'd5; rc11 <= 2'd1; rc12 <= 3'd5; rc13 <= 2'd1; rc14 <= 3'd7; rc15 <= 1'd0; end
            {4'd8, 1'b0}: begin rc0 <= 1'd0; rc1 <= 3'd4; rc2 <= 2'd0; rc3 <= 3'd3; rc4 <= 2'd0; rc5 <= 3'd3; rc6 <= 3'd0; rc7 <= 2'd2; rc8 <= 2'd1; rc9 <= 3'd5; rc10 <= 3'd2; rc11 <= 2'd3; rc12 <= 3'd2; rc13 <= 2'd3; rc14 <= 3'd3; rc15 <= 1'd1; end
            {4'd8, 1'b1}: begin rc0 <= 1'd1; rc1 <= 3'd0; rc2 <= 2'd2; rc3 <= 3'd0; rc4 <= 2'd2; rc5 <= 3'd0; rc6 <= 3'd3; rc7 <= 2'd0; rc8 <= 2'd3; rc9 <= 3'd2; rc10 <= 3'd5; rc11 <= 2'd1; rc12 <= 3'd5; rc13 <= 2'd1; rc14 <= 3'd7; rc15 <= 1'd0; end
            {4'd9, 1'b0}: begin rc0 <= 1'd0; rc1 <= 3'd4; rc2 <= 2'd0; rc3 <= 3'd3; rc4 <= 2'd0; rc5 <= 3'd3; rc6 <= 3'd0; rc7 <= 2'd2; rc8 <= 2'd1; rc9 <= 3'd5; rc10 <= 3'd2; rc11 <= 2'd3; rc12 <= 3'd2; rc13 <= 2'd3; rc14 <= 3'd3; rc15 <= 1'd1; end
            {4'd9, 1'b1}: begin rc0 <= 1'd1; rc1 <= 3'd0; rc2 <= 2'd2; rc3 <= 3'd0; rc4 <= 2'd2; rc5 <= 3'd0; rc6 <= 3'd3; rc7 <= 2'd0; rc8 <= 2'd3; rc9 <= 3'd2; rc10 <= 3'd5; rc11 <= 2'd1; rc12 <= 3'd5; rc13 <= 2'd1; rc14 <= 3'd7; rc15 <= 1'd0; end
            {4'd10, 1'b0}: begin rc0 <= 1'd0; rc1 <= 3'd4; rc2 <= 2'd0; rc3 <= 3'd3; rc4 <= 2'd0; rc5 <= 3'd3; rc6 <= 3'd0; rc7 <= 2'd2; rc8 <= 2'd1; rc9 <= 3'd5; rc10 <= 3'd2; rc11 <= 2'd3; rc12 <= 3'd2; rc13 <= 2'd3; rc14 <= 3'd3; rc15 <= 1'd1; end
            {4'd10, 1'b1}: begin rc0 <= 1'd1; rc1 <= 3'd0; rc2 <= 2'd2; rc3 <= 3'd0; rc4 <= 2'd2; rc5 <= 3'd0; rc6 <= 3'd3; rc7 <= 2'd0; rc8 <= 2'd3; rc9 <= 3'd2; rc10 <= 3'd5; rc11 <= 2'd1; rc12 <= 3'd5; rc13 <= 2'd1; rc14 <= 3'd7; rc15 <= 1'd0; end
            {4'd11, 1'b0}: begin rc0 <= 1'd0; rc1 <= 3'd4; rc2 <= 2'd0; rc3 <= 3'd3; rc4 <= 2'd0; rc5 <= 3'd3; rc6 <= 3'd0; rc7 <= 2'd2; rc8 <= 2'd1; rc9 <= 3'd5; rc10 <= 3'd2; rc11 <= 2'd3; rc12 <= 3'd2; rc13 <= 2'd3; rc14 <= 3'd3; rc15 <= 1'd1; end
            {4'd11, 1'b1}: begin rc0 <= 1'd1; rc1 <= 3'd0; rc2 <= 2'd2; rc3 <= 3'd0; rc4 <= 2'd2; rc5 <= 3'd0; rc6 <= 3'd3; rc7 <= 2'd0; rc8 <= 2'd3; rc9 <= 3'd2; rc10 <= 3'd5; rc11 <= 2'd1; rc12 <= 3'd5; rc13 <= 2'd1; rc14 <= 3'd7; rc15 <= 1'd0; end
            default: ;
        endcase
    end
    always_ff @(posedge clk) begin
        case ({wk_s, wk_f})
            {4'd0, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd0; wc2 <= 3'd1; wc3 <= 3'd0; wc4 <= 3'd1; wc5 <= 3'd1; wc6 <= 3'd1; wc7 <= 2'd0; wc8 <= 2'd2; wc9 <= 3'd3; wc10 <= 3'd5; wc11 <= 3'd3; wc12 <= 3'd4; wc13 <= 3'd5; wc14 <= 3'd4; wc15 <= 2'd2; end
            {4'd0, 1'b1}: begin wc0 <= 2'd2; wc1 <= 3'd3; wc2 <= 3'd5; wc3 <= 3'd3; wc4 <= 3'd4; wc5 <= 3'd5; wc6 <= 3'd4; wc7 <= 2'd2; wc8 <= 2'd0; wc9 <= 3'd0; wc10 <= 3'd1; wc11 <= 3'd0; wc12 <= 3'd1; wc13 <= 3'd1; wc14 <= 3'd1; wc15 <= 2'd0; end
            {4'd1, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd0; wc3 <= 3'd0; wc4 <= 3'd1; wc5 <= 3'd2; wc6 <= 3'd0; wc7 <= 2'd0; wc8 <= 2'd2; wc9 <= 3'd4; wc10 <= 3'd4; wc11 <= 3'd3; wc12 <= 3'd4; wc13 <= 3'd6; wc14 <= 3'd3; wc15 <= 2'd2; end
            {4'd1, 1'b1}: begin wc0 <= 2'd2; wc1 <= 3'd4; wc2 <= 3'd4; wc3 <= 3'd3; wc4 <= 3'd4; wc5 <= 3'd6; wc6 <= 3'd3; wc7 <= 2'd2; wc8 <= 2'd0; wc9 <= 3'd1; wc10 <= 3'd0; wc11 <= 3'd0; wc12 <= 3'd1; wc13 <= 3'd2; wc14 <= 3'd0; wc15 <= 2'd0; end
            {4'd2, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd0; wc5 <= 3'd0; wc6 <= 3'd0; wc7 <= 2'd0; wc8 <= 2'd2; wc9 <= 3'd4; wc10 <= 3'd6; wc11 <= 3'd4; wc12 <= 3'd3; wc13 <= 3'd4; wc14 <= 3'd3; wc15 <= 2'd2; end
            {4'd2, 1'b1}: begin wc0 <= 2'd2; wc1 <= 3'd4; wc2 <= 3'd6; wc3 <= 3'd4; wc4 <= 3'd3; wc5 <= 3'd4; wc6 <= 3'd3; wc7 <= 2'd2; wc8 <= 2'd0; wc9 <= 3'd1; wc10 <= 3'd2; wc11 <= 3'd1; wc12 <= 3'd0; wc13 <= 3'd0; wc14 <= 3'd0; wc15 <= 2'd0; end
            {4'd3, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 3'd3; wc6 <= 3'd2; wc7 <= 2'd1; wc8 <= 2'd1; wc9 <= 3'd2; wc10 <= 3'd3; wc11 <= 3'd2; wc12 <= 3'd3; wc13 <= 3'd4; wc14 <= 3'd3; wc15 <= 2'd2; end
            {4'd3, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 3'd4; wc6 <= 3'd3; wc7 <= 2'd2; wc8 <= 2'd0; wc9 <= 3'd1; wc10 <= 3'd2; wc11 <= 3'd1; wc12 <= 3'd2; wc13 <= 3'd3; wc14 <= 3'd2; wc15 <= 2'd1; end
            {4'd4, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 3'd3; wc6 <= 3'd2; wc7 <= 2'd1; wc8 <= 2'd1; wc9 <= 3'd2; wc10 <= 3'd3; wc11 <= 3'd2; wc12 <= 3'd3; wc13 <= 3'd4; wc14 <= 3'd3; wc15 <= 2'd2; end
            {4'd4, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 3'd4; wc6 <= 3'd3; wc7 <= 2'd2; wc8 <= 2'd0; wc9 <= 3'd1; wc10 <= 3'd2; wc11 <= 3'd1; wc12 <= 3'd2; wc13 <= 3'd3; wc14 <= 3'd2; wc15 <= 2'd1; end
            {4'd5, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 3'd3; wc6 <= 3'd2; wc7 <= 2'd1; wc8 <= 2'd1; wc9 <= 3'd2; wc10 <= 3'd3; wc11 <= 3'd2; wc12 <= 3'd3; wc13 <= 3'd4; wc14 <= 3'd3; wc15 <= 2'd2; end
            {4'd5, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 3'd4; wc6 <= 3'd3; wc7 <= 2'd2; wc8 <= 2'd0; wc9 <= 3'd1; wc10 <= 3'd2; wc11 <= 3'd1; wc12 <= 3'd2; wc13 <= 3'd3; wc14 <= 3'd2; wc15 <= 2'd1; end
            {4'd6, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 3'd3; wc6 <= 3'd2; wc7 <= 2'd1; wc8 <= 2'd1; wc9 <= 3'd2; wc10 <= 3'd3; wc11 <= 3'd2; wc12 <= 3'd3; wc13 <= 3'd4; wc14 <= 3'd3; wc15 <= 2'd2; end
            {4'd6, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 3'd4; wc6 <= 3'd3; wc7 <= 2'd2; wc8 <= 2'd0; wc9 <= 3'd1; wc10 <= 3'd2; wc11 <= 3'd1; wc12 <= 3'd2; wc13 <= 3'd3; wc14 <= 3'd2; wc15 <= 2'd1; end
            {4'd7, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 3'd3; wc6 <= 3'd2; wc7 <= 2'd1; wc8 <= 2'd1; wc9 <= 3'd2; wc10 <= 3'd3; wc11 <= 3'd2; wc12 <= 3'd3; wc13 <= 3'd4; wc14 <= 3'd3; wc15 <= 2'd2; end
            {4'd7, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 3'd4; wc6 <= 3'd3; wc7 <= 2'd2; wc8 <= 2'd0; wc9 <= 3'd1; wc10 <= 3'd2; wc11 <= 3'd1; wc12 <= 3'd2; wc13 <= 3'd3; wc14 <= 3'd2; wc15 <= 2'd1; end
            {4'd8, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 3'd3; wc6 <= 3'd2; wc7 <= 2'd1; wc8 <= 2'd1; wc9 <= 3'd2; wc10 <= 3'd3; wc11 <= 3'd2; wc12 <= 3'd3; wc13 <= 3'd4; wc14 <= 3'd3; wc15 <= 2'd2; end
            {4'd8, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 3'd4; wc6 <= 3'd3; wc7 <= 2'd2; wc8 <= 2'd0; wc9 <= 3'd1; wc10 <= 3'd2; wc11 <= 3'd1; wc12 <= 3'd2; wc13 <= 3'd3; wc14 <= 3'd2; wc15 <= 2'd1; end
            {4'd9, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 3'd3; wc6 <= 3'd2; wc7 <= 2'd1; wc8 <= 2'd1; wc9 <= 3'd2; wc10 <= 3'd3; wc11 <= 3'd2; wc12 <= 3'd3; wc13 <= 3'd4; wc14 <= 3'd3; wc15 <= 2'd2; end
            {4'd9, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 3'd4; wc6 <= 3'd3; wc7 <= 2'd2; wc8 <= 2'd0; wc9 <= 3'd1; wc10 <= 3'd2; wc11 <= 3'd1; wc12 <= 3'd2; wc13 <= 3'd3; wc14 <= 3'd2; wc15 <= 2'd1; end
            {4'd10, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 3'd3; wc6 <= 3'd2; wc7 <= 2'd1; wc8 <= 2'd1; wc9 <= 3'd2; wc10 <= 3'd3; wc11 <= 3'd2; wc12 <= 3'd3; wc13 <= 3'd4; wc14 <= 3'd3; wc15 <= 2'd2; end
            {4'd10, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 3'd4; wc6 <= 3'd3; wc7 <= 2'd2; wc8 <= 2'd0; wc9 <= 3'd1; wc10 <= 3'd2; wc11 <= 3'd1; wc12 <= 3'd2; wc13 <= 3'd3; wc14 <= 3'd2; wc15 <= 2'd1; end
            {4'd11, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 3'd3; wc6 <= 3'd2; wc7 <= 2'd1; wc8 <= 2'd1; wc9 <= 3'd2; wc10 <= 3'd3; wc11 <= 3'd2; wc12 <= 3'd3; wc13 <= 3'd4; wc14 <= 3'd3; wc15 <= 2'd2; end
            {4'd11, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 3'd4; wc6 <= 3'd3; wc7 <= 2'd2; wc8 <= 2'd0; wc9 <= 3'd1; wc10 <= 3'd2; wc11 <= 3'd1; wc12 <= 3'd2; wc13 <= 3'd3; wc14 <= 3'd2; wc15 <= 2'd1; end
            default: ;
        endcase
    end
    // ---- data banks: 2 sets x 2B banks (bank of m: (m mod 2B) ^ (parity(m >> (b+1)) << b), address m >> (b+1))
    logic m0_0_we; logic [7:0] m0_0_wa, m0_0_ra; logic [59:0] m0_0_wd, m0_0_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m0_0 (.clk(clk), .we(m0_0_we), .wa(m0_0_wa), .wd(m0_0_wd), .ra(m0_0_ra), .rd(m0_0_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_0_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_0_ra <= drow;
    logic m0_1_we; logic [7:0] m0_1_wa, m0_1_ra; logic [59:0] m0_1_wd, m0_1_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m0_1 (.clk(clk), .we(m0_1_we), .wa(m0_1_wa), .wd(m0_1_wd), .ra(m0_1_ra), .rd(m0_1_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_1_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_1_ra <= drow;
    logic m0_2_we; logic [7:0] m0_2_wa, m0_2_ra; logic [59:0] m0_2_wd, m0_2_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m0_2 (.clk(clk), .we(m0_2_we), .wa(m0_2_wa), .wd(m0_2_wd), .ra(m0_2_ra), .rd(m0_2_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_2_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_2_ra <= drow;
    logic m0_3_we; logic [7:0] m0_3_wa, m0_3_ra; logic [59:0] m0_3_wd, m0_3_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m0_3 (.clk(clk), .we(m0_3_we), .wa(m0_3_wa), .wd(m0_3_wd), .ra(m0_3_ra), .rd(m0_3_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_3_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_3_ra <= drow;
    logic m0_4_we; logic [7:0] m0_4_wa, m0_4_ra; logic [59:0] m0_4_wd, m0_4_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m0_4 (.clk(clk), .we(m0_4_we), .wa(m0_4_wa), .wd(m0_4_wd), .ra(m0_4_ra), .rd(m0_4_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_4_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_4_ra <= drow;
    logic m0_5_we; logic [7:0] m0_5_wa, m0_5_ra; logic [59:0] m0_5_wd, m0_5_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m0_5 (.clk(clk), .we(m0_5_we), .wa(m0_5_wa), .wd(m0_5_wd), .ra(m0_5_ra), .rd(m0_5_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_5_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_5_ra <= drow;
    logic m0_6_we; logic [7:0] m0_6_wa, m0_6_ra; logic [59:0] m0_6_wd, m0_6_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m0_6 (.clk(clk), .we(m0_6_we), .wa(m0_6_wa), .wd(m0_6_wd), .ra(m0_6_ra), .rd(m0_6_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_6_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_6_ra <= drow;
    logic m0_7_we; logic [7:0] m0_7_wa, m0_7_ra; logic [59:0] m0_7_wd, m0_7_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m0_7 (.clk(clk), .we(m0_7_we), .wa(m0_7_wa), .wd(m0_7_wd), .ra(m0_7_ra), .rd(m0_7_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_7_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_7_ra <= drow;
    logic m0_8_we; logic [7:0] m0_8_wa, m0_8_ra; logic [59:0] m0_8_wd, m0_8_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m0_8 (.clk(clk), .we(m0_8_we), .wa(m0_8_wa), .wd(m0_8_wd), .ra(m0_8_ra), .rd(m0_8_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_8_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_8_ra <= drow;
    logic m0_9_we; logic [7:0] m0_9_wa, m0_9_ra; logic [59:0] m0_9_wd, m0_9_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m0_9 (.clk(clk), .we(m0_9_we), .wa(m0_9_wa), .wd(m0_9_wd), .ra(m0_9_ra), .rd(m0_9_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_9_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_9_ra <= drow;
    logic m0_10_we; logic [7:0] m0_10_wa, m0_10_ra; logic [59:0] m0_10_wd, m0_10_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m0_10 (.clk(clk), .we(m0_10_we), .wa(m0_10_wa), .wd(m0_10_wd), .ra(m0_10_ra), .rd(m0_10_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_10_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_10_ra <= drow;
    logic m0_11_we; logic [7:0] m0_11_wa, m0_11_ra; logic [59:0] m0_11_wd, m0_11_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m0_11 (.clk(clk), .we(m0_11_we), .wa(m0_11_wa), .wd(m0_11_wd), .ra(m0_11_ra), .rd(m0_11_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_11_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_11_ra <= drow;
    logic m0_12_we; logic [7:0] m0_12_wa, m0_12_ra; logic [59:0] m0_12_wd, m0_12_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m0_12 (.clk(clk), .we(m0_12_we), .wa(m0_12_wa), .wd(m0_12_wd), .ra(m0_12_ra), .rd(m0_12_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_12_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_12_ra <= drow;
    logic m0_13_we; logic [7:0] m0_13_wa, m0_13_ra; logic [59:0] m0_13_wd, m0_13_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m0_13 (.clk(clk), .we(m0_13_we), .wa(m0_13_wa), .wd(m0_13_wd), .ra(m0_13_ra), .rd(m0_13_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_13_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_13_ra <= drow;
    logic m0_14_we; logic [7:0] m0_14_wa, m0_14_ra; logic [59:0] m0_14_wd, m0_14_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m0_14 (.clk(clk), .we(m0_14_we), .wa(m0_14_wa), .wd(m0_14_wd), .ra(m0_14_ra), .rd(m0_14_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_14_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_14_ra <= drow;
    logic m0_15_we; logic [7:0] m0_15_wa, m0_15_ra; logic [59:0] m0_15_wd, m0_15_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m0_15 (.clk(clk), .we(m0_15_we), .wa(m0_15_wa), .wd(m0_15_wd), .ra(m0_15_ra), .rd(m0_15_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_15_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_15_ra <= drow;
    logic m1_0_we; logic [7:0] m1_0_wa, m1_0_ra; logic [59:0] m1_0_wd, m1_0_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m1_0 (.clk(clk), .we(m1_0_we), .wa(m1_0_wa), .wd(m1_0_wd), .ra(m1_0_ra), .rd(m1_0_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_0_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_0_ra <= drow;
    logic m1_1_we; logic [7:0] m1_1_wa, m1_1_ra; logic [59:0] m1_1_wd, m1_1_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m1_1 (.clk(clk), .we(m1_1_we), .wa(m1_1_wa), .wd(m1_1_wd), .ra(m1_1_ra), .rd(m1_1_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_1_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_1_ra <= drow;
    logic m1_2_we; logic [7:0] m1_2_wa, m1_2_ra; logic [59:0] m1_2_wd, m1_2_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m1_2 (.clk(clk), .we(m1_2_we), .wa(m1_2_wa), .wd(m1_2_wd), .ra(m1_2_ra), .rd(m1_2_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_2_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_2_ra <= drow;
    logic m1_3_we; logic [7:0] m1_3_wa, m1_3_ra; logic [59:0] m1_3_wd, m1_3_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m1_3 (.clk(clk), .we(m1_3_we), .wa(m1_3_wa), .wd(m1_3_wd), .ra(m1_3_ra), .rd(m1_3_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_3_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_3_ra <= drow;
    logic m1_4_we; logic [7:0] m1_4_wa, m1_4_ra; logic [59:0] m1_4_wd, m1_4_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m1_4 (.clk(clk), .we(m1_4_we), .wa(m1_4_wa), .wd(m1_4_wd), .ra(m1_4_ra), .rd(m1_4_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_4_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_4_ra <= drow;
    logic m1_5_we; logic [7:0] m1_5_wa, m1_5_ra; logic [59:0] m1_5_wd, m1_5_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m1_5 (.clk(clk), .we(m1_5_we), .wa(m1_5_wa), .wd(m1_5_wd), .ra(m1_5_ra), .rd(m1_5_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_5_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_5_ra <= drow;
    logic m1_6_we; logic [7:0] m1_6_wa, m1_6_ra; logic [59:0] m1_6_wd, m1_6_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m1_6 (.clk(clk), .we(m1_6_we), .wa(m1_6_wa), .wd(m1_6_wd), .ra(m1_6_ra), .rd(m1_6_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_6_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_6_ra <= drow;
    logic m1_7_we; logic [7:0] m1_7_wa, m1_7_ra; logic [59:0] m1_7_wd, m1_7_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m1_7 (.clk(clk), .we(m1_7_we), .wa(m1_7_wa), .wd(m1_7_wd), .ra(m1_7_ra), .rd(m1_7_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_7_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_7_ra <= drow;
    logic m1_8_we; logic [7:0] m1_8_wa, m1_8_ra; logic [59:0] m1_8_wd, m1_8_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m1_8 (.clk(clk), .we(m1_8_we), .wa(m1_8_wa), .wd(m1_8_wd), .ra(m1_8_ra), .rd(m1_8_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_8_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_8_ra <= drow;
    logic m1_9_we; logic [7:0] m1_9_wa, m1_9_ra; logic [59:0] m1_9_wd, m1_9_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m1_9 (.clk(clk), .we(m1_9_we), .wa(m1_9_wa), .wd(m1_9_wd), .ra(m1_9_ra), .rd(m1_9_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_9_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_9_ra <= drow;
    logic m1_10_we; logic [7:0] m1_10_wa, m1_10_ra; logic [59:0] m1_10_wd, m1_10_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m1_10 (.clk(clk), .we(m1_10_we), .wa(m1_10_wa), .wd(m1_10_wd), .ra(m1_10_ra), .rd(m1_10_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_10_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_10_ra <= drow;
    logic m1_11_we; logic [7:0] m1_11_wa, m1_11_ra; logic [59:0] m1_11_wd, m1_11_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m1_11 (.clk(clk), .we(m1_11_we), .wa(m1_11_wa), .wd(m1_11_wd), .ra(m1_11_ra), .rd(m1_11_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_11_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_11_ra <= drow;
    logic m1_12_we; logic [7:0] m1_12_wa, m1_12_ra; logic [59:0] m1_12_wd, m1_12_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m1_12 (.clk(clk), .we(m1_12_we), .wa(m1_12_wa), .wd(m1_12_wd), .ra(m1_12_ra), .rd(m1_12_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_12_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_12_ra <= drow;
    logic m1_13_we; logic [7:0] m1_13_wa, m1_13_ra; logic [59:0] m1_13_wd, m1_13_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m1_13 (.clk(clk), .we(m1_13_we), .wa(m1_13_wa), .wd(m1_13_wd), .ra(m1_13_ra), .rd(m1_13_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_13_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_13_ra <= drow;
    logic m1_14_we; logic [7:0] m1_14_wa, m1_14_ra; logic [59:0] m1_14_wd, m1_14_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m1_14 (.clk(clk), .we(m1_14_we), .wa(m1_14_wa), .wd(m1_14_wd), .ra(m1_14_ra), .rd(m1_14_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_14_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_14_ra <= drow;
    logic m1_15_we; logic [7:0] m1_15_wa, m1_15_ra; logic [59:0] m1_15_wd, m1_15_rd;
    Ia_n4096_q60w_B8_rns_ram_block #(.W(60), .D(256), .A(8), .R(2)) u_m1_15 (.clk(clk), .we(m1_15_we), .wa(m1_15_wa), .wd(m1_15_wd), .ra(m1_15_ra), .rd(m1_15_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_15_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_15_ra <= drow;
    logic [59:0] rdc0; assign rdc0 = cb_set[2] ? m1_0_rd : m0_0_rd;
    logic [59:0] rdc1; assign rdc1 = cb_set[2] ? m1_1_rd : m0_1_rd;
    logic [59:0] rdc2; assign rdc2 = cb_set[2] ? m1_2_rd : m0_2_rd;
    logic [59:0] rdc3; assign rdc3 = cb_set[2] ? m1_3_rd : m0_3_rd;
    logic [59:0] rdc4; assign rdc4 = cb_set[2] ? m1_4_rd : m0_4_rd;
    logic [59:0] rdc5; assign rdc5 = cb_set[2] ? m1_5_rd : m0_5_rd;
    logic [59:0] rdc6; assign rdc6 = cb_set[2] ? m1_6_rd : m0_6_rd;
    logic [59:0] rdc7; assign rdc7 = cb_set[2] ? m1_7_rd : m0_7_rd;
    logic [59:0] rdc8; assign rdc8 = cb_set[2] ? m1_8_rd : m0_8_rd;
    logic [59:0] rdc9; assign rdc9 = cb_set[2] ? m1_9_rd : m0_9_rd;
    logic [59:0] rdc10; assign rdc10 = cb_set[2] ? m1_10_rd : m0_10_rd;
    logic [59:0] rdc11; assign rdc11 = cb_set[2] ? m1_11_rd : m0_11_rd;
    logic [59:0] rdc12; assign rdc12 = cb_set[2] ? m1_12_rd : m0_12_rd;
    logic [59:0] rdc13; assign rdc13 = cb_set[2] ? m1_13_rd : m0_13_rd;
    logic [59:0] rdc14; assign rdc14 = cb_set[2] ? m1_14_rd : m0_14_rd;
    logic [59:0] rdc15; assign rdc15 = cb_set[2] ? m1_15_rd : m0_15_rd;
    // ---- operand mux (sources per port: IterativeNTTScheme.readSources)
    logic [59:0] op0;
    always_ff @(posedge clk) case (rc0)
        1'd0: op0 <= rdc0;
        1'd1: op0 <= rdc8;
        default: op0 <= rdc0;
    endcase
    logic [59:0] op1;
    always_ff @(posedge clk) case (rc1)
        3'd0: op1 <= rdc0;
        3'd1: op1 <= rdc1;
        3'd2: op1 <= rdc2;
        3'd3: op1 <= rdc4;
        3'd4: op1 <= rdc8;
        3'd5: op1 <= rdc9;
        3'd6: op1 <= rdc10;
        3'd7: op1 <= rdc12;
        default: op1 <= rdc0;
    endcase
    logic [59:0] op2;
    always_ff @(posedge clk) case (rc2)
        2'd0: op2 <= rdc1;
        2'd1: op2 <= rdc2;
        2'd2: op2 <= rdc9;
        2'd3: op2 <= rdc10;
        default: op2 <= rdc1;
    endcase
    logic [59:0] op3;
    always_ff @(posedge clk) case (rc3)
        3'd0: op3 <= rdc1;
        3'd1: op3 <= rdc3;
        3'd2: op3 <= rdc5;
        3'd3: op3 <= rdc9;
        3'd4: op3 <= rdc11;
        3'd5: op3 <= rdc13;
        default: op3 <= rdc1;
    endcase
    logic [59:0] op4;
    always_ff @(posedge clk) case (rc4)
        2'd0: op4 <= rdc2;
        2'd1: op4 <= rdc4;
        2'd2: op4 <= rdc10;
        2'd3: op4 <= rdc12;
        default: op4 <= rdc2;
    endcase
    logic [59:0] op5;
    always_ff @(posedge clk) case (rc5)
        3'd0: op5 <= rdc2;
        3'd1: op5 <= rdc5;
        3'd2: op5 <= rdc6;
        3'd3: op5 <= rdc10;
        3'd4: op5 <= rdc13;
        3'd5: op5 <= rdc14;
        default: op5 <= rdc2;
    endcase
    logic [59:0] op6;
    always_ff @(posedge clk) case (rc6)
        3'd0: op6 <= rdc3;
        3'd1: op6 <= rdc5;
        3'd2: op6 <= rdc6;
        3'd3: op6 <= rdc11;
        3'd4: op6 <= rdc13;
        3'd5: op6 <= rdc14;
        default: op6 <= rdc3;
    endcase
    logic [59:0] op7;
    always_ff @(posedge clk) case (rc7)
        2'd0: op7 <= rdc3;
        2'd1: op7 <= rdc7;
        2'd2: op7 <= rdc11;
        2'd3: op7 <= rdc15;
        default: op7 <= rdc3;
    endcase
    logic [59:0] op8;
    always_ff @(posedge clk) case (rc8)
        2'd0: op8 <= rdc0;
        2'd1: op8 <= rdc4;
        2'd2: op8 <= rdc8;
        2'd3: op8 <= rdc12;
        default: op8 <= rdc0;
    endcase
    logic [59:0] op9;
    always_ff @(posedge clk) case (rc9)
        3'd0: op9 <= rdc1;
        3'd1: op9 <= rdc2;
        3'd2: op9 <= rdc4;
        3'd3: op9 <= rdc9;
        3'd4: op9 <= rdc10;
        3'd5: op9 <= rdc12;
        default: op9 <= rdc1;
    endcase
    logic [59:0] op10;
    always_ff @(posedge clk) case (rc10)
        3'd0: op10 <= rdc1;
        3'd1: op10 <= rdc2;
        3'd2: op10 <= rdc5;
        3'd3: op10 <= rdc9;
        3'd4: op10 <= rdc10;
        3'd5: op10 <= rdc13;
        default: op10 <= rdc1;
    endcase
    logic [59:0] op11;
    always_ff @(posedge clk) case (rc11)
        2'd0: op11 <= rdc3;
        2'd1: op11 <= rdc5;
        2'd2: op11 <= rdc11;
        2'd3: op11 <= rdc13;
        default: op11 <= rdc3;
    endcase
    logic [59:0] op12;
    always_ff @(posedge clk) case (rc12)
        3'd0: op12 <= rdc2;
        3'd1: op12 <= rdc4;
        3'd2: op12 <= rdc6;
        3'd3: op12 <= rdc10;
        3'd4: op12 <= rdc12;
        3'd5: op12 <= rdc14;
        default: op12 <= rdc2;
    endcase
    logic [59:0] op13;
    always_ff @(posedge clk) case (rc13)
        2'd0: op13 <= rdc5;
        2'd1: op13 <= rdc6;
        2'd2: op13 <= rdc13;
        2'd3: op13 <= rdc14;
        default: op13 <= rdc5;
    endcase
    logic [59:0] op14;
    always_ff @(posedge clk) case (rc14)
        3'd0: op14 <= rdc3;
        3'd1: op14 <= rdc5;
        3'd2: op14 <= rdc6;
        3'd3: op14 <= rdc7;
        3'd4: op14 <= rdc11;
        3'd5: op14 <= rdc13;
        3'd6: op14 <= rdc14;
        3'd7: op14 <= rdc15;
        default: op14 <= rdc3;
    endcase
    logic [59:0] op15;
    always_ff @(posedge clk) case (rc15)
        1'd0: op15 <= rdc7;
        1'd1: op15 <= rdc15;
        default: op15 <= rdc7;
    endcase
    // ---- twiddle tables (two per butterfly: stages > b, and the stage constants of stages <= b),
    // addresses = twiddleIndex (+ the inverse half); the choice registered with the data
    (* max_fanout = 16 *) logic [8:0] ta, ta0; (* max_fanout = 16 *) logic [1:0] tca;
    always_ff @(posedge clk) ta <= tidx_of(s, DIR_r ? ~tau : tau);
    always_ff @(posedge clk) ta0 <= tidx_of(s, DIR_r ? 8'(-tau) : tau);
    always_ff @(posedge clk) tca <= 2'(s);
    logic tsel [3]; always_ff @(posedge clk) begin tsel[0] <= s > 4'd3; for (int i = 1; i <= 2; i++) tsel[i] <= tsel[i-1]; end
    logic tsel_r; assign tsel_r = tsel[2];
    // ---- table write ports from the record stream (IterativeNTT.rnsRecord order)
    logic [9:0] lw_rest; assign lw_rest = 10'(lk >> 2);
    function automatic logic [8:0] lwa_t_of(input logic [3:0] s_, input logic [9:0] r_);
        case (s_)
            4'd4: lwa_t_of = 9'd0 + 9'(r_ & 10'h1);
            4'd5: lwa_t_of = 9'd2 + 9'(r_ & 10'h3);
            4'd6: lwa_t_of = 9'd6 + 9'(r_ & 10'h7);
            4'd7: lwa_t_of = 9'd14 + 9'(r_ & 10'hf);
            4'd8: lwa_t_of = 9'd30 + 9'(r_ & 10'h1f);
            4'd9: lwa_t_of = 9'd62 + 9'(r_ & 10'h3f);
            4'd10: lwa_t_of = 9'd126 + 9'(r_ & 10'h7f);
            4'd11: lwa_t_of = 9'd254 + 9'(r_ & 10'hff);
            default: lwa_t_of = '0;
        endcase
    endfunction
    function automatic logic [1:0] lwa_c_of(input logic [3:0] s_, input logic [9:0] r_);
        lwa_c_of = 2'(s_);
    endfunction
    (* max_fanout = 16 *) logic [8:0] lw_wa_t; (* max_fanout = 16 *) logic [1:0] lw_wa_c;
    logic lw_go, lw_t; assign lw_go = tacc && (lst == L_DATA); assign lw_t = ls > 4'd3;
    always_ff @(posedge clk) begin lw_wa_t <= {lwa_t_of(ls, lw_rest)}; lw_wa_c <= {lwa_c_of(ls, lw_rest)}; end
    logic lw_wet0, lw_wec0; logic [59:0] lw_wd0;
    always_ff @(posedge clk) begin lw_wet0 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec0 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd0 <= tw_data[59:0]; end
    logic lw_wet1, lw_wec1; logic [59:0] lw_wd1;
    always_ff @(posedge clk) begin lw_wet1 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec1 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd1 <= tw_data[119:60]; end
    logic lw_wet2, lw_wec2; logic [59:0] lw_wd2;
    always_ff @(posedge clk) begin lw_wet2 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec2 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd2 <= tw_data[59:0]; end
    logic lw_wet3, lw_wec3; logic [59:0] lw_wd3;
    always_ff @(posedge clk) begin lw_wet3 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec3 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd3 <= tw_data[119:60]; end
    logic lw_wet4, lw_wec4; logic [59:0] lw_wd4;
    always_ff @(posedge clk) begin lw_wet4 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec4 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd4 <= tw_data[59:0]; end
    logic lw_wet5, lw_wec5; logic [59:0] lw_wd5;
    always_ff @(posedge clk) begin lw_wet5 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec5 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd5 <= tw_data[119:60]; end
    logic lw_wet6, lw_wec6; logic [59:0] lw_wd6;
    always_ff @(posedge clk) begin lw_wet6 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec6 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd6 <= tw_data[59:0]; end
    logic lw_wet7, lw_wec7; logic [59:0] lw_wd7;
    always_ff @(posedge clk) begin lw_wet7 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec7 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd7 <= tw_data[119:60]; end
    logic [59:0] twr0, tcr0, twr0_q;
    Ia_n4096_q60w_B8_rns_twr0 u_tw0 (.clk(clk), .addr(ta0), .we(lw_wet0), .wa(lw_wa_t), .wd(lw_wd0), .q0(twr0));
    Ia_n4096_q60w_B8_rns_twr1 u_tc0 (.clk(clk), .addr(tca), .we(lw_wec0), .wa(lw_wa_c), .wd(lw_wd0), .q0(tcr0));
    logic [59:0] twr1, tcr1, twr1_q;
    Ia_n4096_q60w_B8_rns_twr0 u_tw1 (.clk(clk), .addr(ta), .we(lw_wet1), .wa(lw_wa_t), .wd(lw_wd1), .q0(twr1));
    Ia_n4096_q60w_B8_rns_twr1 u_tc1 (.clk(clk), .addr(tca), .we(lw_wec1), .wa(lw_wa_c), .wd(lw_wd1), .q0(tcr1));
    logic [59:0] twr2, tcr2, twr2_q;
    Ia_n4096_q60w_B8_rns_twr0 u_tw2 (.clk(clk), .addr(ta), .we(lw_wet2), .wa(lw_wa_t), .wd(lw_wd2), .q0(twr2));
    Ia_n4096_q60w_B8_rns_twr1 u_tc2 (.clk(clk), .addr(tca), .we(lw_wec2), .wa(lw_wa_c), .wd(lw_wd2), .q0(tcr2));
    logic [59:0] twr3, tcr3, twr3_q;
    Ia_n4096_q60w_B8_rns_twr0 u_tw3 (.clk(clk), .addr(ta), .we(lw_wet3), .wa(lw_wa_t), .wd(lw_wd3), .q0(twr3));
    Ia_n4096_q60w_B8_rns_twr1 u_tc3 (.clk(clk), .addr(tca), .we(lw_wec3), .wa(lw_wa_c), .wd(lw_wd3), .q0(tcr3));
    logic [59:0] twr4, tcr4, twr4_q;
    Ia_n4096_q60w_B8_rns_twr0 u_tw4 (.clk(clk), .addr(ta), .we(lw_wet4), .wa(lw_wa_t), .wd(lw_wd4), .q0(twr4));
    Ia_n4096_q60w_B8_rns_twr1 u_tc4 (.clk(clk), .addr(tca), .we(lw_wec4), .wa(lw_wa_c), .wd(lw_wd4), .q0(tcr4));
    logic [59:0] twr5, tcr5, twr5_q;
    Ia_n4096_q60w_B8_rns_twr0 u_tw5 (.clk(clk), .addr(ta), .we(lw_wet5), .wa(lw_wa_t), .wd(lw_wd5), .q0(twr5));
    Ia_n4096_q60w_B8_rns_twr1 u_tc5 (.clk(clk), .addr(tca), .we(lw_wec5), .wa(lw_wa_c), .wd(lw_wd5), .q0(tcr5));
    logic [59:0] twr6, tcr6, twr6_q;
    Ia_n4096_q60w_B8_rns_twr0 u_tw6 (.clk(clk), .addr(ta), .we(lw_wet6), .wa(lw_wa_t), .wd(lw_wd6), .q0(twr6));
    Ia_n4096_q60w_B8_rns_twr1 u_tc6 (.clk(clk), .addr(tca), .we(lw_wec6), .wa(lw_wa_c), .wd(lw_wd6), .q0(tcr6));
    logic [59:0] twr7, tcr7, twr7_q;
    Ia_n4096_q60w_B8_rns_twr0 u_tw7 (.clk(clk), .addr(ta), .we(lw_wet7), .wa(lw_wa_t), .wd(lw_wd7), .q0(twr7));
    Ia_n4096_q60w_B8_rns_twr1 u_tc7 (.clk(clk), .addr(tca), .we(lw_wec7), .wa(lw_wa_c), .wd(lw_wd7), .q0(tcr7));
    always_ff @(posedge clk) twr0_q <= tsel_r ? twr0 : tcr0;
    always_ff @(posedge clk) twr1_q <= tsel_r ? (DIR_r ? twr7 : twr1) : (DIR_r ? tcr7 : tcr1);
    always_ff @(posedge clk) twr2_q <= tsel_r ? (DIR_r ? twr6 : twr2) : (DIR_r ? tcr6 : tcr2);
    always_ff @(posedge clk) twr3_q <= tsel_r ? (DIR_r ? twr5 : twr3) : (DIR_r ? tcr5 : tcr3);
    always_ff @(posedge clk) twr4_q <= tsel_r ? twr4 : tcr4;
    always_ff @(posedge clk) twr5_q <= tsel_r ? (DIR_r ? twr3 : twr5) : (DIR_r ? tcr3 : tcr5);
    always_ff @(posedge clk) twr6_q <= tsel_r ? (DIR_r ? twr2 : twr6) : (DIR_r ? tcr2 : tcr6);
    always_ff @(posedge clk) twr7_q <= tsel_r ? (DIR_r ? twr1 : twr7) : (DIR_r ? tcr1 : tcr7);
    // ---- 8 butterflies (Ia_n4096_q60w_B8_rns_bu, latency 17), output register / x2^-1 halver
    (* max_fanout = 16 *) logic [29:0] b0q_QH;
    always_ff @(posedge clk) b0q_QH <= QH_r;
    logic [59:0] xr0; logic [59:0] yr0;
    Ia_n4096_q60w_B8_rns_bu u_bu0 (.clk(clk), .aIn(op0), .bIn(op1), .W(twr0_q), .QH(b0q_QH), .aOut(xr0), .bOut(yr0));
    logic [59:0] xo0, xo0_x; assign xo0_x = (cb_sw[20][0] ? yr0 : xr0);
    (* max_fanout = 16 *) logic [59:0] b0q_QHALF;
    always_ff @(posedge clk) b0q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo0 <= DIR_r ? (60'(xo0_x >> 1) + (xo0_x[0] ? 60'(b0q_QHALF) : 60'd0)) : xo0_x;
    logic [59:0] yo0, yo0_x; assign yo0_x = (cb_sw[20][0] ? xr0 : yr0);
    always_ff @(posedge clk) yo0 <= DIR_r ? (60'(yo0_x >> 1) + (yo0_x[0] ? 60'(b0q_QHALF) : 60'd0)) : yo0_x;
    (* max_fanout = 16 *) logic [29:0] b1q_QH;
    always_ff @(posedge clk) b1q_QH <= QH_r;
    logic [59:0] xr1; logic [59:0] yr1;
    Ia_n4096_q60w_B8_rns_bu u_bu1 (.clk(clk), .aIn(op2), .bIn(op3), .W(twr1_q), .QH(b1q_QH), .aOut(xr1), .bOut(yr1));
    logic [59:0] xo1, xo1_x; assign xo1_x = (cb_sw[20][1] ? yr1 : xr1);
    (* max_fanout = 16 *) logic [59:0] b1q_QHALF;
    always_ff @(posedge clk) b1q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo1 <= DIR_r ? (60'(xo1_x >> 1) + (xo1_x[0] ? 60'(b1q_QHALF) : 60'd0)) : xo1_x;
    logic [59:0] yo1, yo1_x; assign yo1_x = (cb_sw[20][1] ? xr1 : yr1);
    always_ff @(posedge clk) yo1 <= DIR_r ? (60'(yo1_x >> 1) + (yo1_x[0] ? 60'(b1q_QHALF) : 60'd0)) : yo1_x;
    (* max_fanout = 16 *) logic [29:0] b2q_QH;
    always_ff @(posedge clk) b2q_QH <= QH_r;
    logic [59:0] xr2; logic [59:0] yr2;
    Ia_n4096_q60w_B8_rns_bu u_bu2 (.clk(clk), .aIn(op4), .bIn(op5), .W(twr2_q), .QH(b2q_QH), .aOut(xr2), .bOut(yr2));
    logic [59:0] xo2, xo2_x; assign xo2_x = (cb_sw[20][2] ? yr2 : xr2);
    (* max_fanout = 16 *) logic [59:0] b2q_QHALF;
    always_ff @(posedge clk) b2q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo2 <= DIR_r ? (60'(xo2_x >> 1) + (xo2_x[0] ? 60'(b2q_QHALF) : 60'd0)) : xo2_x;
    logic [59:0] yo2, yo2_x; assign yo2_x = (cb_sw[20][2] ? xr2 : yr2);
    always_ff @(posedge clk) yo2 <= DIR_r ? (60'(yo2_x >> 1) + (yo2_x[0] ? 60'(b2q_QHALF) : 60'd0)) : yo2_x;
    (* max_fanout = 16 *) logic [29:0] b3q_QH;
    always_ff @(posedge clk) b3q_QH <= QH_r;
    logic [59:0] xr3; logic [59:0] yr3;
    Ia_n4096_q60w_B8_rns_bu u_bu3 (.clk(clk), .aIn(op6), .bIn(op7), .W(twr3_q), .QH(b3q_QH), .aOut(xr3), .bOut(yr3));
    logic [59:0] xo3, xo3_x; assign xo3_x = (cb_sw[20][3] ? yr3 : xr3);
    (* max_fanout = 16 *) logic [59:0] b3q_QHALF;
    always_ff @(posedge clk) b3q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo3 <= DIR_r ? (60'(xo3_x >> 1) + (xo3_x[0] ? 60'(b3q_QHALF) : 60'd0)) : xo3_x;
    logic [59:0] yo3, yo3_x; assign yo3_x = (cb_sw[20][3] ? xr3 : yr3);
    always_ff @(posedge clk) yo3 <= DIR_r ? (60'(yo3_x >> 1) + (yo3_x[0] ? 60'(b3q_QHALF) : 60'd0)) : yo3_x;
    (* max_fanout = 16 *) logic [29:0] b4q_QH;
    always_ff @(posedge clk) b4q_QH <= QH_r;
    logic [59:0] xr4; logic [59:0] yr4;
    Ia_n4096_q60w_B8_rns_bu u_bu4 (.clk(clk), .aIn(op8), .bIn(op9), .W(twr4_q), .QH(b4q_QH), .aOut(xr4), .bOut(yr4));
    logic [59:0] xo4, xo4_x; assign xo4_x = (cb_sw[20][4] ? yr4 : xr4);
    (* max_fanout = 16 *) logic [59:0] b4q_QHALF;
    always_ff @(posedge clk) b4q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo4 <= DIR_r ? (60'(xo4_x >> 1) + (xo4_x[0] ? 60'(b4q_QHALF) : 60'd0)) : xo4_x;
    logic [59:0] yo4, yo4_x; assign yo4_x = (cb_sw[20][4] ? xr4 : yr4);
    always_ff @(posedge clk) yo4 <= DIR_r ? (60'(yo4_x >> 1) + (yo4_x[0] ? 60'(b4q_QHALF) : 60'd0)) : yo4_x;
    (* max_fanout = 16 *) logic [29:0] b5q_QH;
    always_ff @(posedge clk) b5q_QH <= QH_r;
    logic [59:0] xr5; logic [59:0] yr5;
    Ia_n4096_q60w_B8_rns_bu u_bu5 (.clk(clk), .aIn(op10), .bIn(op11), .W(twr5_q), .QH(b5q_QH), .aOut(xr5), .bOut(yr5));
    logic [59:0] xo5, xo5_x; assign xo5_x = (cb_sw[20][5] ? yr5 : xr5);
    (* max_fanout = 16 *) logic [59:0] b5q_QHALF;
    always_ff @(posedge clk) b5q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo5 <= DIR_r ? (60'(xo5_x >> 1) + (xo5_x[0] ? 60'(b5q_QHALF) : 60'd0)) : xo5_x;
    logic [59:0] yo5, yo5_x; assign yo5_x = (cb_sw[20][5] ? xr5 : yr5);
    always_ff @(posedge clk) yo5 <= DIR_r ? (60'(yo5_x >> 1) + (yo5_x[0] ? 60'(b5q_QHALF) : 60'd0)) : yo5_x;
    (* max_fanout = 16 *) logic [29:0] b6q_QH;
    always_ff @(posedge clk) b6q_QH <= QH_r;
    logic [59:0] xr6; logic [59:0] yr6;
    Ia_n4096_q60w_B8_rns_bu u_bu6 (.clk(clk), .aIn(op12), .bIn(op13), .W(twr6_q), .QH(b6q_QH), .aOut(xr6), .bOut(yr6));
    logic [59:0] xo6, xo6_x; assign xo6_x = (cb_sw[20][6] ? yr6 : xr6);
    (* max_fanout = 16 *) logic [59:0] b6q_QHALF;
    always_ff @(posedge clk) b6q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo6 <= DIR_r ? (60'(xo6_x >> 1) + (xo6_x[0] ? 60'(b6q_QHALF) : 60'd0)) : xo6_x;
    logic [59:0] yo6, yo6_x; assign yo6_x = (cb_sw[20][6] ? xr6 : yr6);
    always_ff @(posedge clk) yo6 <= DIR_r ? (60'(yo6_x >> 1) + (yo6_x[0] ? 60'(b6q_QHALF) : 60'd0)) : yo6_x;
    (* max_fanout = 16 *) logic [29:0] b7q_QH;
    always_ff @(posedge clk) b7q_QH <= QH_r;
    logic [59:0] xr7; logic [59:0] yr7;
    Ia_n4096_q60w_B8_rns_bu u_bu7 (.clk(clk), .aIn(op14), .bIn(op15), .W(twr7_q), .QH(b7q_QH), .aOut(xr7), .bOut(yr7));
    logic [59:0] xo7, xo7_x; assign xo7_x = (cb_sw[20][7] ? yr7 : xr7);
    (* max_fanout = 16 *) logic [59:0] b7q_QHALF;
    always_ff @(posedge clk) b7q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo7 <= DIR_r ? (60'(xo7_x >> 1) + (xo7_x[0] ? 60'(b7q_QHALF) : 60'd0)) : xo7_x;
    logic [59:0] yo7, yo7_x; assign yo7_x = (cb_sw[20][7] ? xr7 : yr7);
    always_ff @(posedge clk) yo7 <= DIR_r ? (60'(yo7_x >> 1) + (yo7_x[0] ? 60'(b7q_QHALF) : 60'd0)) : yo7_x;
    // ---- write back in place (sources per bank: IterativeNTTScheme.readSources), or the fill
    logic [59:0] wdat0;
    always_comb case (wc0)
        2'd0: wdat0 = xo0;
        2'd1: wdat0 = yo0;
        2'd2: wdat0 = xo4;
        default: wdat0 = xo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_0_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_0_we <= 1'b1; m0_0_wa <= (w_f ? w_hB : w_hA); m0_0_wd <= wdat0; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 3'd4) : (fsub == 3'd0))) begin m0_0_we <= 1'b1; m0_0_wa <= frow; m0_0_wd <= x_in_0; end
        else m0_0_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_0_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_0_we <= 1'b1; m1_0_wa <= (w_f ? w_hB : w_hA); m1_0_wd <= wdat0; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 3'd4) : (fsub == 3'd0))) begin m1_0_we <= 1'b1; m1_0_wa <= frow; m1_0_wd <= x_in_0; end
        else m1_0_we <= 1'b0;
    end
    logic [59:0] wdat1;
    always_comb case (wc1)
        3'd0: wdat1 = yo0;
        3'd1: wdat1 = xo1;
        3'd2: wdat1 = yo1;
        3'd3: wdat1 = yo4;
        3'd4: wdat1 = xo5;
        default: wdat1 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_1_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_1_we <= 1'b1; m0_1_wa <= (w_f ? w_hB : w_hA); m0_1_wd <= wdat1; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 3'd4) : (fsub == 3'd0))) begin m0_1_we <= 1'b1; m0_1_wa <= frow; m0_1_wd <= x_in_1; end
        else m0_1_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_1_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_1_we <= 1'b1; m1_1_wa <= (w_f ? w_hB : w_hA); m1_1_wd <= wdat1; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 3'd4) : (fsub == 3'd0))) begin m1_1_we <= 1'b1; m1_1_wa <= frow; m1_1_wd <= x_in_1; end
        else m1_1_we <= 1'b0;
    end
    logic [59:0] wdat2;
    always_comb case (wc2)
        3'd0: wdat2 = yo0;
        3'd1: wdat2 = xo1;
        3'd2: wdat2 = xo2;
        3'd3: wdat2 = yo2;
        3'd4: wdat2 = yo4;
        3'd5: wdat2 = xo5;
        3'd6: wdat2 = xo6;
        default: wdat2 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_2_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_2_we <= 1'b1; m0_2_wa <= (w_f ? w_hB : w_hA); m0_2_wd <= wdat2; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 3'd5) : (fsub == 3'd1))) begin m0_2_we <= 1'b1; m0_2_wa <= frow; m0_2_wd <= x_in_0; end
        else m0_2_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_2_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_2_we <= 1'b1; m1_2_wa <= (w_f ? w_hB : w_hA); m1_2_wd <= wdat2; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 3'd5) : (fsub == 3'd1))) begin m1_2_we <= 1'b1; m1_2_wa <= frow; m1_2_wd <= x_in_0; end
        else m1_2_we <= 1'b0;
    end
    logic [59:0] wdat3;
    always_comb case (wc3)
        3'd0: wdat3 = yo1;
        3'd1: wdat3 = xo3;
        3'd2: wdat3 = yo3;
        3'd3: wdat3 = yo5;
        3'd4: wdat3 = xo7;
        default: wdat3 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_3_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_3_we <= 1'b1; m0_3_wa <= (w_f ? w_hB : w_hA); m0_3_wd <= wdat3; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 3'd5) : (fsub == 3'd1))) begin m0_3_we <= 1'b1; m0_3_wa <= frow; m0_3_wd <= x_in_1; end
        else m0_3_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_3_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_3_we <= 1'b1; m1_3_wa <= (w_f ? w_hB : w_hA); m1_3_wd <= wdat3; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 3'd5) : (fsub == 3'd1))) begin m1_3_we <= 1'b1; m1_3_wa <= frow; m1_3_wd <= x_in_1; end
        else m1_3_we <= 1'b0;
    end
    logic [59:0] wdat4;
    always_comb case (wc4)
        3'd0: wdat4 = yo0;
        3'd1: wdat4 = xo2;
        3'd2: wdat4 = xo4;
        3'd3: wdat4 = yo4;
        3'd4: wdat4 = xo6;
        default: wdat4 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_4_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_4_we <= 1'b1; m0_4_wa <= (w_f ? w_hB : w_hA); m0_4_wd <= wdat4; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 3'd6) : (fsub == 3'd2))) begin m0_4_we <= 1'b1; m0_4_wa <= frow; m0_4_wd <= x_in_0; end
        else m0_4_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_4_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_4_we <= 1'b1; m1_4_wa <= (w_f ? w_hB : w_hA); m1_4_wd <= wdat4; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 3'd6) : (fsub == 3'd2))) begin m1_4_we <= 1'b1; m1_4_wa <= frow; m1_4_wd <= x_in_0; end
        else m1_4_we <= 1'b0;
    end
    logic [59:0] wdat5;
    always_comb case (wc5)
        3'd0: wdat5 = yo1;
        3'd1: wdat5 = yo2;
        3'd2: wdat5 = xo3;
        3'd3: wdat5 = xo5;
        3'd4: wdat5 = yo5;
        3'd5: wdat5 = yo6;
        3'd6: wdat5 = xo7;
        default: wdat5 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_5_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_5_we <= 1'b1; m0_5_wa <= (w_f ? w_hB : w_hA); m0_5_wd <= wdat5; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 3'd6) : (fsub == 3'd2))) begin m0_5_we <= 1'b1; m0_5_wa <= frow; m0_5_wd <= x_in_1; end
        else m0_5_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_5_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_5_we <= 1'b1; m1_5_wa <= (w_f ? w_hB : w_hA); m1_5_wd <= wdat5; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 3'd6) : (fsub == 3'd2))) begin m1_5_we <= 1'b1; m1_5_wa <= frow; m1_5_wd <= x_in_1; end
        else m1_5_we <= 1'b0;
    end
    logic [59:0] wdat6;
    always_comb case (wc6)
        3'd0: wdat6 = yo2;
        3'd1: wdat6 = xo3;
        3'd2: wdat6 = xo6;
        3'd3: wdat6 = yo6;
        3'd4: wdat6 = xo7;
        default: wdat6 = yo2;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_6_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_6_we <= 1'b1; m0_6_wa <= (w_f ? w_hB : w_hA); m0_6_wd <= wdat6; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 3'd7) : (fsub == 3'd3))) begin m0_6_we <= 1'b1; m0_6_wa <= frow; m0_6_wd <= x_in_0; end
        else m0_6_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_6_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_6_we <= 1'b1; m1_6_wa <= (w_f ? w_hB : w_hA); m1_6_wd <= wdat6; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 3'd7) : (fsub == 3'd3))) begin m1_6_we <= 1'b1; m1_6_wa <= frow; m1_6_wd <= x_in_0; end
        else m1_6_we <= 1'b0;
    end
    logic [59:0] wdat7;
    always_comb case (wc7)
        2'd0: wdat7 = yo3;
        2'd1: wdat7 = xo7;
        2'd2: wdat7 = yo7;
        default: wdat7 = yo3;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_7_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_7_we <= 1'b1; m0_7_wa <= (w_f ? w_hB : w_hA); m0_7_wd <= wdat7; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 3'd7) : (fsub == 3'd3))) begin m0_7_we <= 1'b1; m0_7_wa <= frow; m0_7_wd <= x_in_1; end
        else m0_7_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_7_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_7_we <= 1'b1; m1_7_wa <= (w_f ? w_hB : w_hA); m1_7_wd <= wdat7; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 3'd7) : (fsub == 3'd3))) begin m1_7_we <= 1'b1; m1_7_wa <= frow; m1_7_wd <= x_in_1; end
        else m1_7_we <= 1'b0;
    end
    logic [59:0] wdat8;
    always_comb case (wc8)
        2'd0: wdat8 = xo0;
        2'd1: wdat8 = yo0;
        2'd2: wdat8 = xo4;
        default: wdat8 = xo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_8_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_8_we <= 1'b1; m0_8_wa <= (w_f ? w_hA : w_hB); m0_8_wd <= wdat8; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 3'd0) : (fsub == 3'd4))) begin m0_8_we <= 1'b1; m0_8_wa <= frow; m0_8_wd <= x_in_0; end
        else m0_8_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_8_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_8_we <= 1'b1; m1_8_wa <= (w_f ? w_hA : w_hB); m1_8_wd <= wdat8; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 3'd0) : (fsub == 3'd4))) begin m1_8_we <= 1'b1; m1_8_wa <= frow; m1_8_wd <= x_in_0; end
        else m1_8_we <= 1'b0;
    end
    logic [59:0] wdat9;
    always_comb case (wc9)
        3'd0: wdat9 = yo0;
        3'd1: wdat9 = xo1;
        3'd2: wdat9 = yo1;
        3'd3: wdat9 = yo4;
        3'd4: wdat9 = xo5;
        default: wdat9 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_9_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_9_we <= 1'b1; m0_9_wa <= (w_f ? w_hA : w_hB); m0_9_wd <= wdat9; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 3'd0) : (fsub == 3'd4))) begin m0_9_we <= 1'b1; m0_9_wa <= frow; m0_9_wd <= x_in_1; end
        else m0_9_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_9_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_9_we <= 1'b1; m1_9_wa <= (w_f ? w_hA : w_hB); m1_9_wd <= wdat9; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 3'd0) : (fsub == 3'd4))) begin m1_9_we <= 1'b1; m1_9_wa <= frow; m1_9_wd <= x_in_1; end
        else m1_9_we <= 1'b0;
    end
    logic [59:0] wdat10;
    always_comb case (wc10)
        3'd0: wdat10 = yo0;
        3'd1: wdat10 = xo1;
        3'd2: wdat10 = xo2;
        3'd3: wdat10 = yo2;
        3'd4: wdat10 = yo4;
        3'd5: wdat10 = xo5;
        3'd6: wdat10 = xo6;
        default: wdat10 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_10_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_10_we <= 1'b1; m0_10_wa <= (w_f ? w_hA : w_hB); m0_10_wd <= wdat10; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 3'd1) : (fsub == 3'd5))) begin m0_10_we <= 1'b1; m0_10_wa <= frow; m0_10_wd <= x_in_0; end
        else m0_10_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_10_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_10_we <= 1'b1; m1_10_wa <= (w_f ? w_hA : w_hB); m1_10_wd <= wdat10; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 3'd1) : (fsub == 3'd5))) begin m1_10_we <= 1'b1; m1_10_wa <= frow; m1_10_wd <= x_in_0; end
        else m1_10_we <= 1'b0;
    end
    logic [59:0] wdat11;
    always_comb case (wc11)
        3'd0: wdat11 = yo1;
        3'd1: wdat11 = xo3;
        3'd2: wdat11 = yo3;
        3'd3: wdat11 = yo5;
        3'd4: wdat11 = xo7;
        default: wdat11 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_11_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_11_we <= 1'b1; m0_11_wa <= (w_f ? w_hA : w_hB); m0_11_wd <= wdat11; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 3'd1) : (fsub == 3'd5))) begin m0_11_we <= 1'b1; m0_11_wa <= frow; m0_11_wd <= x_in_1; end
        else m0_11_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_11_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_11_we <= 1'b1; m1_11_wa <= (w_f ? w_hA : w_hB); m1_11_wd <= wdat11; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 3'd1) : (fsub == 3'd5))) begin m1_11_we <= 1'b1; m1_11_wa <= frow; m1_11_wd <= x_in_1; end
        else m1_11_we <= 1'b0;
    end
    logic [59:0] wdat12;
    always_comb case (wc12)
        3'd0: wdat12 = yo0;
        3'd1: wdat12 = xo2;
        3'd2: wdat12 = xo4;
        3'd3: wdat12 = yo4;
        3'd4: wdat12 = xo6;
        default: wdat12 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_12_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_12_we <= 1'b1; m0_12_wa <= (w_f ? w_hA : w_hB); m0_12_wd <= wdat12; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 3'd2) : (fsub == 3'd6))) begin m0_12_we <= 1'b1; m0_12_wa <= frow; m0_12_wd <= x_in_0; end
        else m0_12_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_12_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_12_we <= 1'b1; m1_12_wa <= (w_f ? w_hA : w_hB); m1_12_wd <= wdat12; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 3'd2) : (fsub == 3'd6))) begin m1_12_we <= 1'b1; m1_12_wa <= frow; m1_12_wd <= x_in_0; end
        else m1_12_we <= 1'b0;
    end
    logic [59:0] wdat13;
    always_comb case (wc13)
        3'd0: wdat13 = yo1;
        3'd1: wdat13 = yo2;
        3'd2: wdat13 = xo3;
        3'd3: wdat13 = xo5;
        3'd4: wdat13 = yo5;
        3'd5: wdat13 = yo6;
        3'd6: wdat13 = xo7;
        default: wdat13 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_13_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_13_we <= 1'b1; m0_13_wa <= (w_f ? w_hA : w_hB); m0_13_wd <= wdat13; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 3'd2) : (fsub == 3'd6))) begin m0_13_we <= 1'b1; m0_13_wa <= frow; m0_13_wd <= x_in_1; end
        else m0_13_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_13_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_13_we <= 1'b1; m1_13_wa <= (w_f ? w_hA : w_hB); m1_13_wd <= wdat13; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 3'd2) : (fsub == 3'd6))) begin m1_13_we <= 1'b1; m1_13_wa <= frow; m1_13_wd <= x_in_1; end
        else m1_13_we <= 1'b0;
    end
    logic [59:0] wdat14;
    always_comb case (wc14)
        3'd0: wdat14 = yo2;
        3'd1: wdat14 = xo3;
        3'd2: wdat14 = xo6;
        3'd3: wdat14 = yo6;
        3'd4: wdat14 = xo7;
        default: wdat14 = yo2;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_14_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_14_we <= 1'b1; m0_14_wa <= (w_f ? w_hA : w_hB); m0_14_wd <= wdat14; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 3'd3) : (fsub == 3'd7))) begin m0_14_we <= 1'b1; m0_14_wa <= frow; m0_14_wd <= x_in_0; end
        else m0_14_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_14_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_14_we <= 1'b1; m1_14_wa <= (w_f ? w_hA : w_hB); m1_14_wd <= wdat14; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 3'd3) : (fsub == 3'd7))) begin m1_14_we <= 1'b1; m1_14_wa <= frow; m1_14_wd <= x_in_0; end
        else m1_14_we <= 1'b0;
    end
    logic [59:0] wdat15;
    always_comb case (wc15)
        2'd0: wdat15 = yo3;
        2'd1: wdat15 = xo7;
        2'd2: wdat15 = yo7;
        default: wdat15 = yo3;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_15_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_15_we <= 1'b1; m0_15_wa <= (w_f ? w_hA : w_hB); m0_15_wd <= wdat15; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 3'd3) : (fsub == 3'd7))) begin m0_15_we <= 1'b1; m0_15_wa <= frow; m0_15_wd <= x_in_1; end
        else m0_15_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_15_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_15_we <= 1'b1; m1_15_wa <= (w_f ? w_hA : w_hB); m1_15_wd <= wdat15; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 3'd3) : (fsub == 3'd7))) begin m1_15_we <= 1'b1; m1_15_wa <= frow; m1_15_wd <= x_in_1; end
        else m1_15_we <= 1'b0;
    end
    // ---- output: lane l of beat (row, sub) is bank ((sub*io + l) ^ (parity(row) << b))
    logic [59:0] drd0; assign drd0 = db_set[2] ? m1_0_rd : m0_0_rd;
    logic [59:0] drd1; assign drd1 = db_set[2] ? m1_1_rd : m0_1_rd;
    logic [59:0] drd2; assign drd2 = db_set[2] ? m1_2_rd : m0_2_rd;
    logic [59:0] drd3; assign drd3 = db_set[2] ? m1_3_rd : m0_3_rd;
    logic [59:0] drd4; assign drd4 = db_set[2] ? m1_4_rd : m0_4_rd;
    logic [59:0] drd5; assign drd5 = db_set[2] ? m1_5_rd : m0_5_rd;
    logic [59:0] drd6; assign drd6 = db_set[2] ? m1_6_rd : m0_6_rd;
    logic [59:0] drd7; assign drd7 = db_set[2] ? m1_7_rd : m0_7_rd;
    logic [59:0] drd8; assign drd8 = db_set[2] ? m1_8_rd : m0_8_rd;
    logic [59:0] drd9; assign drd9 = db_set[2] ? m1_9_rd : m0_9_rd;
    logic [59:0] drd10; assign drd10 = db_set[2] ? m1_10_rd : m0_10_rd;
    logic [59:0] drd11; assign drd11 = db_set[2] ? m1_11_rd : m0_11_rd;
    logic [59:0] drd12; assign drd12 = db_set[2] ? m1_12_rd : m0_12_rd;
    logic [59:0] drd13; assign drd13 = db_set[2] ? m1_13_rd : m0_13_rd;
    logic [59:0] drd14; assign drd14 = db_set[2] ? m1_14_rd : m0_14_rd;
    logic [59:0] drd15; assign drd15 = db_set[2] ? m1_15_rd : m0_15_rd;
    logic [59:0] yr_0;
    always_ff @(posedge clk) case ({db_sub[2], db_pi[2]})
        {3'd0, 1'b0}: yr_0 <= drd0;
        {3'd0, 1'b1}: yr_0 <= drd8;
        {3'd1, 1'b0}: yr_0 <= drd2;
        {3'd1, 1'b1}: yr_0 <= drd10;
        {3'd2, 1'b0}: yr_0 <= drd4;
        {3'd2, 1'b1}: yr_0 <= drd12;
        {3'd3, 1'b0}: yr_0 <= drd6;
        {3'd3, 1'b1}: yr_0 <= drd14;
        {3'd4, 1'b0}: yr_0 <= drd8;
        {3'd4, 1'b1}: yr_0 <= drd0;
        {3'd5, 1'b0}: yr_0 <= drd10;
        {3'd5, 1'b1}: yr_0 <= drd2;
        {3'd6, 1'b0}: yr_0 <= drd12;
        {3'd6, 1'b1}: yr_0 <= drd4;
        {3'd7, 1'b0}: yr_0 <= drd14;
        {3'd7, 1'b1}: yr_0 <= drd6;
        default: yr_0 <= drd0;
    endcase
    logic [59:0] yr_1;
    always_ff @(posedge clk) case ({db_sub[2], db_pi[2]})
        {3'd0, 1'b0}: yr_1 <= drd1;
        {3'd0, 1'b1}: yr_1 <= drd9;
        {3'd1, 1'b0}: yr_1 <= drd3;
        {3'd1, 1'b1}: yr_1 <= drd11;
        {3'd2, 1'b0}: yr_1 <= drd5;
        {3'd2, 1'b1}: yr_1 <= drd13;
        {3'd3, 1'b0}: yr_1 <= drd7;
        {3'd3, 1'b1}: yr_1 <= drd15;
        {3'd4, 1'b0}: yr_1 <= drd9;
        {3'd4, 1'b1}: yr_1 <= drd1;
        {3'd5, 1'b0}: yr_1 <= drd11;
        {3'd5, 1'b1}: yr_1 <= drd3;
        {3'd6, 1'b0}: yr_1 <= drd13;
        {3'd6, 1'b1}: yr_1 <= drd5;
        {3'd7, 1'b0}: yr_1 <= drd15;
        {3'd7, 1'b1}: yr_1 <= drd7;
        default: yr_1 <= drd1;
    endcase
    logic yv; always_ff @(posedge clk) yv <= rst ? 1'b0 : db_v[2];
    assign y_out_0 = yr_0;
    assign y_out_1 = yr_1;
    assign out_valid = yv;
endmodule
