`timescale 1ns / 1ps
// Ie_n65536_q64b_B64_rns: iterative NTT, n=65536, 64 butterflies over 2 x 128 banks of 512 x 64 bits, 8 I/O lanes, run-time q, direction both, butterfly latency 16, write-back latency 22, stage gaps [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
module Ie_n65536_q64b_B64_rns (
    input  logic clk,
    input  logic rst,
    input  logic DIR,
    input  logic tw_valid,
    output logic tw_ready,
    input  logic [1023:0] tw_data,
    input  logic in_valid,
    output logic in_ready,
    input  logic [63:0] x_in_0,
    input  logic [63:0] x_in_1,
    input  logic [63:0] x_in_2,
    input  logic [63:0] x_in_3,
    input  logic [63:0] x_in_4,
    input  logic [63:0] x_in_5,
    input  logic [63:0] x_in_6,
    input  logic [63:0] x_in_7,
    output logic out_valid,
    output logic [63:0] y_out_0,
    output logic [63:0] y_out_1,
    output logic [63:0] y_out_2,
    output logic [63:0] y_out_3,
    output logic [63:0] y_out_4,
    output logic [63:0] y_out_5,
    output logic [63:0] y_out_6,
    output logic [63:0] y_out_7
    );
    (* max_fanout = 32 *) logic DIR_r;
    always_ff @(posedge clk) DIR_r <= DIR;
    (* max_fanout = 16 *) logic [63:0] Q_r;
    logic [63:0] Q_n;      // the next polynomial's (record header), into Q_r at its start
    (* max_fanout = 16 *) logic [65:0] MU_r;
    logic [65:0] MU_n;      // the next polynomial's (record header), into MU_r at its start
    (* max_fanout = 16 *) logic [63:0] QHALF_r;
    logic [63:0] QHALF_n;      // the next polynomial's (record header), into QHALF_r at its start
    // ---- controller: fill (input), compute (butterflies), drain (output) over two bank sets
    logic fset; logic [12:0] fptr; logic [1:0] full, busy, res;
    logic cact, cset, cnext; logic [3:0] s; logic [8:0] tau; logic [0:0] gap;
    logic dact, dset, dnext; logic [12:0] dptr;
    logic [21:0] dsr, dsrs;
    logic fill_ok, acc, flast, issue, tlast, clast, startc, dlastb, startd, done, done_set;
    // ---- record stream (recycle): per polynomial a header (bit 0 keep, then the modulus constants), then its twiddles, 16 entries a beat
    localparam logic [1:0] L_HDR = 2'd0, L_DATA = 2'd1, L_WAIT = 2'd2;
    logic [1:0] lst, lst_n; logic lahead, lahead_n, nkeep, hdr_ok, perm, tacc, hlast, klast, hkeep;
    logic [3:0] ls, ls_n; logic [10:0] lk, lk_n; logic [0:0] hptr, hptr_n;
    logic [4:0] qw;
    logic [4:0] relst; logic twok;
    assign hdr_ok = (lst == L_WAIT) || ((lst == L_DATA) && lahead);
    assign fill_ok = !full[fset] && !busy[fset] && (!res[fset] || (dact && (dset == fset) && (fptr < dptr)));
    assign in_ready = fill_ok;
    assign acc = in_valid && fill_ok && !rst;
    assign flast = fptr == 13'd8191;
    assign issue = cact && (gap == '0) && twok;
    assign tlast = tau == 9'd511;
    assign clast = issue && tlast && (s == 4'd15);
    assign startc = full[cnext] && hdr_ok && (nkeep ? (!cact || clast) : (!cact && (qw == '0)));
    assign dlastb = dact && (dptr == 13'd8191);
    assign startd = res[dnext] && (!dact || dlastb);
    assign done = dsr[21]; assign done_set = dsrs[21];
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
            dsr <= {dsr[20:0], clast}; dsrs <= {dsrs[20:0], cset};
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
    function automatic logic [10:0] nbs_of(input logic [3:0] s_);
        case (s_)
            4'd0: nbs_of = 11'd3;
            4'd1: nbs_of = 11'd3;
            4'd2: nbs_of = 11'd3;
            4'd3: nbs_of = 11'd3;
            4'd4: nbs_of = 11'd3;
            4'd5: nbs_of = 11'd3;
            4'd6: nbs_of = 11'd3;
            4'd7: nbs_of = 11'd7;
            4'd8: nbs_of = 11'd15;
            4'd9: nbs_of = 11'd31;
            4'd10: nbs_of = 11'd63;
            4'd11: nbs_of = 11'd127;
            4'd12: nbs_of = 11'd255;
            4'd13: nbs_of = 11'd511;
            4'd14: nbs_of = 11'd1023;
            4'd15: nbs_of = 11'd2047;
            default: nbs_of = '0;
        endcase
    endfunction
    assign klast = lk == nbs_of(ls);
    logic [1023:0] hdr_w; assign hdr_w = tw_data;
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
    logic [3:0] s_nx; logic [8:0] tau_nx;
    assign s_nx = startc ? '0 : ((issue && tlast) ? s + 1'b1 : s);
    assign tau_nx = startc ? '0 : (issue ? (tlast ? '0 : tau + 1'b1) : tau);
    always_ff @(posedge clk) begin
        if (rst) begin
            lst <= L_HDR; lahead <= 1'b1; ls <= '0; lk <= '0; hptr <= '0; nkeep <= 1'b0; qw <= '0; relst <= 5'd16; twok <= 1'b0;
        end else begin
            lst <= lst_n; lahead <= lahead_n; ls <= ls_n; lk <= lk_n; hptr <= hptr_n;
            if (lst == L_HDR && tacc && hlast) nkeep <= hkeep;
            qw <= clast ? 5'd18 : ((qw != '0) ? qw - 1'b1 : '0);
            if (startc) relst <= '0; else if (clast) relst <= 5'd16; else if (issue && (tau == '0)) relst <= 5'(s);
            twok <= (tau_nx != '0) || !((lst_n == L_DATA) && !lahead_n) || (ls_n > s_nx);
        end
    end
    // the modulus constants: the header into *_n, into *_r (the butterflies' constants) at the start of a polynomial with a new modulus
    always_ff @(posedge clk) begin
        if (lst == L_HDR && tacc && hlast && !hkeep) Q_n <= hdr_w[64:1];
        if (lst == L_HDR && tacc && hlast && !hkeep) MU_n <= hdr_w[130:65];
        if (lst == L_HDR && tacc && hlast && !hkeep) QHALF_n <= hdr_w[194:131];
        if (!rst && startc && !nkeep) begin Q_r <= Q_n; MU_r <= MU_n; QHALF_r <= QHALF_n; end
    end
    // ---- stage decode (IterativeNTTScheme.rowAddrs / flip / twiddleIndex)
    function automatic logic [18:0] rows_of(input logic [3:0] s_, input logic [8:0] t_);
        logic [8:0] ha, hb; logic f;
        ha = t_; hb = t_; f = ^t_;
        case (s_)
            4'd7: begin ha = {t_[8:1], 1'b0}; hb = ha | 9'h1; f = t_[0] ^ (^ha); end
            4'd8: begin ha = {t_[8:2], 1'b0, t_[1:1]}; hb = ha | 9'h2; f = t_[0] ^ (^ha); end
            4'd9: begin ha = {t_[8:3], 1'b0, t_[2:1]}; hb = ha | 9'h4; f = t_[0] ^ (^ha); end
            4'd10: begin ha = {t_[8:4], 1'b0, t_[3:1]}; hb = ha | 9'h8; f = t_[0] ^ (^ha); end
            4'd11: begin ha = {t_[8:5], 1'b0, t_[4:1]}; hb = ha | 9'h10; f = t_[0] ^ (^ha); end
            4'd12: begin ha = {t_[8:6], 1'b0, t_[5:1]}; hb = ha | 9'h20; f = t_[0] ^ (^ha); end
            4'd13: begin ha = {t_[8:7], 1'b0, t_[6:1]}; hb = ha | 9'h40; f = t_[0] ^ (^ha); end
            4'd14: begin ha = {t_[8:8], 1'b0, t_[7:1]}; hb = ha | 9'h80; f = t_[0] ^ (^ha); end
            4'd15: begin ha = {1'b0, t_[8:1]}; hb = ha | 9'h100; f = t_[0] ^ (^ha); end
            default: ;
        endcase
        rows_of = {f, hb, ha};
    endfunction
    function automatic logic [9:0] tidx_of(input logic [3:0] s_, input logic [8:0] t_);
        case (s_)
            4'd7: tidx_of = 10'd0 + 10'(t_ & 9'h1);
            4'd8: tidx_of = 10'd2 + 10'(t_ & 9'h3);
            4'd9: tidx_of = 10'd6 + 10'(t_ & 9'h7);
            4'd10: tidx_of = 10'd14 + 10'(t_ & 9'hf);
            4'd11: tidx_of = 10'd30 + 10'(t_ & 9'h1f);
            4'd12: tidx_of = 10'd62 + 10'(t_ & 9'h3f);
            4'd13: tidx_of = 10'd126 + 10'(t_ & 9'h7f);
            4'd14: tidx_of = 10'd254 + 10'(t_ & 9'hff);
            4'd15: tidx_of = 10'd510 + 10'(t_ & 9'h1ff);
            default: tidx_of = '0;
        endcase
    endfunction
    logic [18:0] c_rows; assign c_rows = rows_of(s, tau);
    logic [8:0] c_hA, c_hB; logic c_flip;
    assign c_hA = c_rows[8:0]; assign c_hB = c_rows[17:9]; assign c_flip = c_rows[18];
    // ---- issue bundle, delayed: cb_*[k] is the read issued k+1 cycles ago (k = 0 .. 20)
    logic cb_v [21]; logic cb_set [21]; logic cb_f [21];
    logic [3:0] cb_s [21]; logic [8:0] cb_t [21]; logic [63:0] cb_sw [21];
    logic [63:0] c_sw;
    always_comb begin
        c_sw = '0;
        if (DIR_r) case (s)
            4'd1: c_sw = 64'haaaaaaaaaaaaaaaa;
            4'd2: c_sw = 64'heeeeeeeeeeeeeeee;
            4'd3: c_sw = 64'hfefefefefefefefe;
            4'd4: c_sw = 64'hfffefffefffefffe;
            4'd5: c_sw = 64'hfffffffefffffffe;
            4'd6: c_sw = 64'hfffffffffffffffe;
            4'd7: c_sw = {63'h7fffffffffffffff, |(tau & 9'h1)};
            4'd8: c_sw = {63'h7fffffffffffffff, |(tau & 9'h3)};
            4'd9: c_sw = {63'h7fffffffffffffff, |(tau & 9'h7)};
            4'd10: c_sw = {63'h7fffffffffffffff, |(tau & 9'hf)};
            4'd11: c_sw = {63'h7fffffffffffffff, |(tau & 9'h1f)};
            4'd12: c_sw = {63'h7fffffffffffffff, |(tau & 9'h3f)};
            4'd13: c_sw = {63'h7fffffffffffffff, |(tau & 9'h7f)};
            4'd14: c_sw = {63'h7fffffffffffffff, |(tau & 9'hff)};
            4'd15: c_sw = {63'h7fffffffffffffff, |(tau & 9'h1ff)};
            default: ;
        endcase
    end
    always_ff @(posedge clk) begin
        if (rst) for (int i = 0; i <= 20; i++) cb_v[i] <= 1'b0;
        else begin
            cb_v[0] <= issue;
            for (int i = 1; i <= 20; i++) cb_v[i] <= cb_v[i-1];
        end
        cb_set[0] <= cset; cb_f[0] <= c_flip; cb_s[0] <= s; cb_t[0] <= tau; cb_sw[0] <= c_sw;
        for (int i = 1; i <= 20; i++) begin cb_set[i] <= cb_set[i-1]; cb_f[i] <= cb_f[i-1]; cb_s[i] <= cb_s[i-1]; cb_t[i] <= cb_t[i-1]; cb_sw[i] <= cb_sw[i-1]; end
    end
    // ---- drain: beat dptr of set dset, row dptr >> lsub
    logic [8:0] drow; assign drow = 9'(dptr >> 4);
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
    logic [8:0] frow; assign frow = 9'(fptr >> 4);
    logic fpi; assign fpi = ^frow;
    logic [3:0] fsub; assign fsub = fptr[3:0];
    logic [18:0] w_rows; assign w_rows = rows_of(cb_s[20], cb_t[20]);
    logic [8:0] w_hA, w_hB; assign w_hA = w_rows[8:0]; assign w_hB = w_rows[17:9];
    logic w_v, w_set, w_f; assign w_v = cb_v[20]; assign w_set = cb_set[20]; assign w_f = cb_f[20];
    logic [0:0] rc0;
    logic [3:0] rc1;
    logic [1:0] rc2;
    logic [3:0] rc3;
    logic [1:0] rc4;
    logic [3:0] rc5;
    logic [2:0] rc6;
    logic [3:0] rc7;
    logic [1:0] rc8;
    logic [3:0] rc9;
    logic [2:0] rc10;
    logic [3:0] rc11;
    logic [2:0] rc12;
    logic [3:0] rc13;
    logic [2:0] rc14;
    logic [2:0] rc15;
    logic [1:0] rc16;
    logic [3:0] rc17;
    logic [2:0] rc18;
    logic [3:0] rc19;
    logic [2:0] rc20;
    logic [3:0] rc21;
    logic [2:0] rc22;
    logic [2:0] rc23;
    logic [2:0] rc24;
    logic [3:0] rc25;
    logic [2:0] rc26;
    logic [2:0] rc27;
    logic [2:0] rc28;
    logic [2:0] rc29;
    logic [3:0] rc30;
    logic [2:0] rc31;
    logic [1:0] rc32;
    logic [3:0] rc33;
    logic [2:0] rc34;
    logic [3:0] rc35;
    logic [2:0] rc36;
    logic [3:0] rc37;
    logic [2:0] rc38;
    logic [2:0] rc39;
    logic [2:0] rc40;
    logic [3:0] rc41;
    logic [2:0] rc42;
    logic [2:0] rc43;
    logic [2:0] rc44;
    logic [2:0] rc45;
    logic [3:0] rc46;
    logic [2:0] rc47;
    logic [2:0] rc48;
    logic [3:0] rc49;
    logic [2:0] rc50;
    logic [2:0] rc51;
    logic [2:0] rc52;
    logic [2:0] rc53;
    logic [3:0] rc54;
    logic [2:0] rc55;
    logic [2:0] rc56;
    logic [2:0] rc57;
    logic [3:0] rc58;
    logic [2:0] rc59;
    logic [3:0] rc60;
    logic [2:0] rc61;
    logic [3:0] rc62;
    logic [1:0] rc63;
    logic [1:0] rc64;
    logic [3:0] rc65;
    logic [2:0] rc66;
    logic [3:0] rc67;
    logic [2:0] rc68;
    logic [3:0] rc69;
    logic [2:0] rc70;
    logic [2:0] rc71;
    logic [2:0] rc72;
    logic [3:0] rc73;
    logic [2:0] rc74;
    logic [2:0] rc75;
    logic [2:0] rc76;
    logic [2:0] rc77;
    logic [3:0] rc78;
    logic [2:0] rc79;
    logic [2:0] rc80;
    logic [3:0] rc81;
    logic [2:0] rc82;
    logic [2:0] rc83;
    logic [2:0] rc84;
    logic [2:0] rc85;
    logic [3:0] rc86;
    logic [2:0] rc87;
    logic [2:0] rc88;
    logic [2:0] rc89;
    logic [3:0] rc90;
    logic [2:0] rc91;
    logic [3:0] rc92;
    logic [2:0] rc93;
    logic [3:0] rc94;
    logic [1:0] rc95;
    logic [2:0] rc96;
    logic [3:0] rc97;
    logic [2:0] rc98;
    logic [2:0] rc99;
    logic [2:0] rc100;
    logic [2:0] rc101;
    logic [3:0] rc102;
    logic [2:0] rc103;
    logic [2:0] rc104;
    logic [2:0] rc105;
    logic [3:0] rc106;
    logic [2:0] rc107;
    logic [3:0] rc108;
    logic [2:0] rc109;
    logic [3:0] rc110;
    logic [1:0] rc111;
    logic [2:0] rc112;
    logic [2:0] rc113;
    logic [3:0] rc114;
    logic [2:0] rc115;
    logic [3:0] rc116;
    logic [2:0] rc117;
    logic [3:0] rc118;
    logic [1:0] rc119;
    logic [3:0] rc120;
    logic [2:0] rc121;
    logic [3:0] rc122;
    logic [1:0] rc123;
    logic [3:0] rc124;
    logic [1:0] rc125;
    logic [3:0] rc126;
    logic [0:0] rc127;
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
    logic [3:0] wc17;
    logic [3:0] wc18;
    logic [3:0] wc19;
    logic [3:0] wc20;
    logic [3:0] wc21;
    logic [3:0] wc22;
    logic [3:0] wc23;
    logic [2:0] wc24;
    logic [3:0] wc25;
    logic [3:0] wc26;
    logic [3:0] wc27;
    logic [2:0] wc28;
    logic [3:0] wc29;
    logic [2:0] wc30;
    logic [2:0] wc31;
    logic [2:0] wc32;
    logic [2:0] wc33;
    logic [3:0] wc34;
    logic [2:0] wc35;
    logic [3:0] wc36;
    logic [3:0] wc37;
    logic [3:0] wc38;
    logic [2:0] wc39;
    logic [3:0] wc40;
    logic [3:0] wc41;
    logic [3:0] wc42;
    logic [3:0] wc43;
    logic [3:0] wc44;
    logic [3:0] wc45;
    logic [3:0] wc46;
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
    logic [1:0] wc64;
    logic [2:0] wc65;
    logic [2:0] wc66;
    logic [2:0] wc67;
    logic [2:0] wc68;
    logic [3:0] wc69;
    logic [2:0] wc70;
    logic [2:0] wc71;
    logic [2:0] wc72;
    logic [3:0] wc73;
    logic [3:0] wc74;
    logic [3:0] wc75;
    logic [2:0] wc76;
    logic [3:0] wc77;
    logic [2:0] wc78;
    logic [2:0] wc79;
    logic [2:0] wc80;
    logic [3:0] wc81;
    logic [3:0] wc82;
    logic [3:0] wc83;
    logic [3:0] wc84;
    logic [3:0] wc85;
    logic [3:0] wc86;
    logic [3:0] wc87;
    logic [2:0] wc88;
    logic [3:0] wc89;
    logic [3:0] wc90;
    logic [3:0] wc91;
    logic [2:0] wc92;
    logic [3:0] wc93;
    logic [2:0] wc94;
    logic [2:0] wc95;
    logic [2:0] wc96;
    logic [2:0] wc97;
    logic [3:0] wc98;
    logic [2:0] wc99;
    logic [3:0] wc100;
    logic [3:0] wc101;
    logic [3:0] wc102;
    logic [2:0] wc103;
    logic [3:0] wc104;
    logic [3:0] wc105;
    logic [3:0] wc106;
    logic [3:0] wc107;
    logic [3:0] wc108;
    logic [3:0] wc109;
    logic [3:0] wc110;
    logic [2:0] wc111;
    logic [2:0] wc112;
    logic [2:0] wc113;
    logic [3:0] wc114;
    logic [2:0] wc115;
    logic [3:0] wc116;
    logic [3:0] wc117;
    logic [3:0] wc118;
    logic [2:0] wc119;
    logic [2:0] wc120;
    logic [2:0] wc121;
    logic [3:0] wc122;
    logic [2:0] wc123;
    logic [2:0] wc124;
    logic [2:0] wc125;
    logic [2:0] wc126;
    logic [1:0] wc127;
    logic [3:0] rk_s, wk_s; logic rk_f, wk_f;
    assign rk_s = cb_s[1]; assign rk_f = cb_f[1];
    assign wk_s = cb_s[19]; assign wk_f = cb_f[19];
    always_ff @(posedge clk) begin
        case ({rk_s, rk_f})
            {4'd0, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd1; rc2 <= 2'd1; rc3 <= 4'd1; rc4 <= 2'd1; rc5 <= 4'd1; rc6 <= 3'd2; rc7 <= 4'd1; rc8 <= 2'd1; rc9 <= 4'd1; rc10 <= 3'd2; rc11 <= 4'd1; rc12 <= 3'd2; rc13 <= 4'd1; rc14 <= 3'd3; rc15 <= 3'd1; rc16 <= 2'd1; rc17 <= 4'd1; rc18 <= 3'd2; rc19 <= 4'd1; rc20 <= 3'd2; rc21 <= 4'd1; rc22 <= 3'd3; rc23 <= 3'd1; rc24 <= 3'd2; rc25 <= 4'd1; rc26 <= 3'd3; rc27 <= 3'd1; rc28 <= 3'd3; rc29 <= 3'd1; rc30 <= 4'd4; rc31 <= 3'd1; rc32 <= 2'd1; rc33 <= 4'd1; rc34 <= 3'd2; rc35 <= 4'd1; rc36 <= 3'd2; rc37 <= 4'd1; rc38 <= 3'd3; rc39 <= 3'd1; rc40 <= 3'd2; rc41 <= 4'd1; rc42 <= 3'd3; rc43 <= 3'd1; rc44 <= 3'd3; rc45 <= 3'd1; rc46 <= 4'd4; rc47 <= 3'd1; rc48 <= 3'd2; rc49 <= 4'd1; rc50 <= 3'd3; rc51 <= 3'd1; rc52 <= 3'd3; rc53 <= 3'd1; rc54 <= 4'd4; rc55 <= 3'd1; rc56 <= 3'd3; rc57 <= 3'd1; rc58 <= 4'd4; rc59 <= 3'd1; rc60 <= 4'd4; rc61 <= 3'd1; rc62 <= 4'd5; rc63 <= 2'd1; rc64 <= 2'd2; rc65 <= 4'd6; rc66 <= 3'd4; rc67 <= 4'd5; rc68 <= 3'd4; rc69 <= 4'd5; rc70 <= 3'd6; rc71 <= 3'd4; rc72 <= 3'd4; rc73 <= 4'd5; rc74 <= 3'd6; rc75 <= 3'd4; rc76 <= 3'd6; rc77 <= 3'd4; rc78 <= 4'd8; rc79 <= 3'd3; rc80 <= 3'd4; rc81 <= 4'd5; rc82 <= 3'd6; rc83 <= 3'd4; rc84 <= 3'd6; rc85 <= 3'd4; rc86 <= 4'd8; rc87 <= 3'd3; rc88 <= 3'd6; rc89 <= 3'd4; rc90 <= 4'd8; rc91 <= 3'd3; rc92 <= 4'd8; rc93 <= 3'd3; rc94 <= 4'd10; rc95 <= 2'd2; rc96 <= 3'd4; rc97 <= 4'd5; rc98 <= 3'd6; rc99 <= 3'd4; rc100 <= 3'd6; rc101 <= 3'd4; rc102 <= 4'd8; rc103 <= 3'd3; rc104 <= 3'd6; rc105 <= 3'd4; rc106 <= 4'd8; rc107 <= 3'd3; rc108 <= 4'd8; rc109 <= 3'd3; rc110 <= 4'd10; rc111 <= 2'd2; rc112 <= 3'd6; rc113 <= 3'd4; rc114 <= 4'd8; rc115 <= 3'd3; rc116 <= 4'd8; rc117 <= 3'd3; rc118 <= 4'd10; rc119 <= 2'd2; rc120 <= 4'd8; rc121 <= 3'd3; rc122 <= 4'd10; rc123 <= 2'd2; rc124 <= 4'd10; rc125 <= 2'd2; rc126 <= 4'd12; rc127 <= 1'd1; end
            {4'd0, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd8; rc2 <= 2'd3; rc3 <= 4'd7; rc4 <= 2'd3; rc5 <= 4'd7; rc6 <= 3'd5; rc7 <= 4'd6; rc8 <= 2'd3; rc9 <= 4'd7; rc10 <= 3'd5; rc11 <= 4'd6; rc12 <= 3'd5; rc13 <= 4'd6; rc14 <= 3'd7; rc15 <= 3'd5; rc16 <= 2'd3; rc17 <= 4'd7; rc18 <= 3'd5; rc19 <= 4'd6; rc20 <= 3'd5; rc21 <= 4'd6; rc22 <= 3'd7; rc23 <= 3'd5; rc24 <= 3'd5; rc25 <= 4'd6; rc26 <= 3'd7; rc27 <= 3'd5; rc28 <= 3'd7; rc29 <= 3'd5; rc30 <= 4'd9; rc31 <= 3'd4; rc32 <= 2'd3; rc33 <= 4'd7; rc34 <= 3'd5; rc35 <= 4'd6; rc36 <= 3'd5; rc37 <= 4'd6; rc38 <= 3'd7; rc39 <= 3'd5; rc40 <= 3'd5; rc41 <= 4'd6; rc42 <= 3'd7; rc43 <= 3'd5; rc44 <= 3'd7; rc45 <= 3'd5; rc46 <= 4'd9; rc47 <= 3'd4; rc48 <= 3'd5; rc49 <= 4'd6; rc50 <= 3'd7; rc51 <= 3'd5; rc52 <= 3'd7; rc53 <= 3'd5; rc54 <= 4'd9; rc55 <= 3'd4; rc56 <= 3'd7; rc57 <= 3'd5; rc58 <= 4'd9; rc59 <= 3'd4; rc60 <= 4'd9; rc61 <= 3'd4; rc62 <= 4'd11; rc63 <= 2'd3; rc64 <= 2'd0; rc65 <= 4'd0; rc66 <= 3'd1; rc67 <= 4'd0; rc68 <= 3'd1; rc69 <= 4'd0; rc70 <= 3'd2; rc71 <= 3'd0; rc72 <= 3'd1; rc73 <= 4'd0; rc74 <= 3'd2; rc75 <= 3'd0; rc76 <= 3'd2; rc77 <= 3'd0; rc78 <= 4'd3; rc79 <= 3'd0; rc80 <= 3'd1; rc81 <= 4'd0; rc82 <= 3'd2; rc83 <= 3'd0; rc84 <= 3'd2; rc85 <= 3'd0; rc86 <= 4'd3; rc87 <= 3'd0; rc88 <= 3'd2; rc89 <= 3'd0; rc90 <= 4'd3; rc91 <= 3'd0; rc92 <= 4'd3; rc93 <= 3'd0; rc94 <= 4'd4; rc95 <= 2'd0; rc96 <= 3'd1; rc97 <= 4'd0; rc98 <= 3'd2; rc99 <= 3'd0; rc100 <= 3'd2; rc101 <= 3'd0; rc102 <= 4'd3; rc103 <= 3'd0; rc104 <= 3'd2; rc105 <= 3'd0; rc106 <= 4'd3; rc107 <= 3'd0; rc108 <= 4'd3; rc109 <= 3'd0; rc110 <= 4'd4; rc111 <= 2'd0; rc112 <= 3'd2; rc113 <= 3'd0; rc114 <= 4'd3; rc115 <= 3'd0; rc116 <= 4'd3; rc117 <= 3'd0; rc118 <= 4'd4; rc119 <= 2'd0; rc120 <= 4'd3; rc121 <= 3'd0; rc122 <= 4'd4; rc123 <= 2'd0; rc124 <= 4'd4; rc125 <= 2'd0; rc126 <= 4'd5; rc127 <= 1'd0; end
            {4'd1, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd2; rc2 <= 2'd0; rc3 <= 4'd1; rc4 <= 2'd1; rc5 <= 4'd2; rc6 <= 3'd1; rc7 <= 4'd1; rc8 <= 2'd1; rc9 <= 4'd2; rc10 <= 3'd1; rc11 <= 4'd1; rc12 <= 3'd2; rc13 <= 4'd2; rc14 <= 3'd2; rc15 <= 3'd1; rc16 <= 2'd1; rc17 <= 4'd2; rc18 <= 3'd1; rc19 <= 4'd1; rc20 <= 3'd2; rc21 <= 4'd2; rc22 <= 3'd2; rc23 <= 3'd1; rc24 <= 3'd2; rc25 <= 4'd2; rc26 <= 3'd2; rc27 <= 3'd1; rc28 <= 3'd3; rc29 <= 3'd2; rc30 <= 4'd3; rc31 <= 3'd1; rc32 <= 2'd1; rc33 <= 4'd2; rc34 <= 3'd1; rc35 <= 4'd1; rc36 <= 3'd2; rc37 <= 4'd2; rc38 <= 3'd2; rc39 <= 3'd1; rc40 <= 3'd2; rc41 <= 4'd2; rc42 <= 3'd2; rc43 <= 3'd1; rc44 <= 3'd3; rc45 <= 3'd2; rc46 <= 4'd3; rc47 <= 3'd1; rc48 <= 3'd2; rc49 <= 4'd2; rc50 <= 3'd2; rc51 <= 3'd1; rc52 <= 3'd3; rc53 <= 3'd2; rc54 <= 4'd3; rc55 <= 3'd1; rc56 <= 3'd3; rc57 <= 3'd2; rc58 <= 4'd3; rc59 <= 3'd1; rc60 <= 4'd4; rc61 <= 3'd2; rc62 <= 4'd4; rc63 <= 2'd1; rc64 <= 2'd2; rc65 <= 4'd7; rc66 <= 3'd3; rc67 <= 4'd5; rc68 <= 3'd4; rc69 <= 4'd6; rc70 <= 3'd5; rc71 <= 3'd4; rc72 <= 3'd4; rc73 <= 4'd6; rc74 <= 3'd5; rc75 <= 3'd4; rc76 <= 3'd6; rc77 <= 3'd5; rc78 <= 4'd7; rc79 <= 3'd3; rc80 <= 3'd4; rc81 <= 4'd6; rc82 <= 3'd5; rc83 <= 3'd4; rc84 <= 3'd6; rc85 <= 3'd5; rc86 <= 4'd7; rc87 <= 3'd3; rc88 <= 3'd6; rc89 <= 3'd5; rc90 <= 4'd7; rc91 <= 3'd3; rc92 <= 4'd8; rc93 <= 3'd4; rc94 <= 4'd9; rc95 <= 2'd2; rc96 <= 3'd4; rc97 <= 4'd6; rc98 <= 3'd5; rc99 <= 3'd4; rc100 <= 3'd6; rc101 <= 3'd5; rc102 <= 4'd7; rc103 <= 3'd3; rc104 <= 3'd6; rc105 <= 3'd5; rc106 <= 4'd7; rc107 <= 3'd3; rc108 <= 4'd8; rc109 <= 3'd4; rc110 <= 4'd9; rc111 <= 2'd2; rc112 <= 3'd6; rc113 <= 3'd5; rc114 <= 4'd7; rc115 <= 3'd3; rc116 <= 4'd8; rc117 <= 3'd4; rc118 <= 4'd9; rc119 <= 2'd2; rc120 <= 4'd8; rc121 <= 3'd4; rc122 <= 4'd9; rc123 <= 2'd2; rc124 <= 4'd10; rc125 <= 2'd3; rc126 <= 4'd11; rc127 <= 1'd1; end
            {4'd1, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd9; rc2 <= 2'd2; rc3 <= 4'd7; rc4 <= 2'd3; rc5 <= 4'd8; rc6 <= 3'd4; rc7 <= 4'd6; rc8 <= 2'd3; rc9 <= 4'd8; rc10 <= 3'd4; rc11 <= 4'd6; rc12 <= 3'd5; rc13 <= 4'd7; rc14 <= 3'd6; rc15 <= 3'd5; rc16 <= 2'd3; rc17 <= 4'd8; rc18 <= 3'd4; rc19 <= 4'd6; rc20 <= 3'd5; rc21 <= 4'd7; rc22 <= 3'd6; rc23 <= 3'd5; rc24 <= 3'd5; rc25 <= 4'd7; rc26 <= 3'd6; rc27 <= 3'd5; rc28 <= 3'd7; rc29 <= 3'd6; rc30 <= 4'd8; rc31 <= 3'd4; rc32 <= 2'd3; rc33 <= 4'd8; rc34 <= 3'd4; rc35 <= 4'd6; rc36 <= 3'd5; rc37 <= 4'd7; rc38 <= 3'd6; rc39 <= 3'd5; rc40 <= 3'd5; rc41 <= 4'd7; rc42 <= 3'd6; rc43 <= 3'd5; rc44 <= 3'd7; rc45 <= 3'd6; rc46 <= 4'd8; rc47 <= 3'd4; rc48 <= 3'd5; rc49 <= 4'd7; rc50 <= 3'd6; rc51 <= 3'd5; rc52 <= 3'd7; rc53 <= 3'd6; rc54 <= 4'd8; rc55 <= 3'd4; rc56 <= 3'd7; rc57 <= 3'd6; rc58 <= 4'd8; rc59 <= 3'd4; rc60 <= 4'd9; rc61 <= 3'd5; rc62 <= 4'd10; rc63 <= 2'd3; rc64 <= 2'd0; rc65 <= 4'd1; rc66 <= 3'd0; rc67 <= 4'd0; rc68 <= 3'd1; rc69 <= 4'd1; rc70 <= 3'd1; rc71 <= 3'd0; rc72 <= 3'd1; rc73 <= 4'd1; rc74 <= 3'd1; rc75 <= 3'd0; rc76 <= 3'd2; rc77 <= 3'd1; rc78 <= 4'd2; rc79 <= 3'd0; rc80 <= 3'd1; rc81 <= 4'd1; rc82 <= 3'd1; rc83 <= 3'd0; rc84 <= 3'd2; rc85 <= 3'd1; rc86 <= 4'd2; rc87 <= 3'd0; rc88 <= 3'd2; rc89 <= 3'd1; rc90 <= 4'd2; rc91 <= 3'd0; rc92 <= 4'd3; rc93 <= 3'd1; rc94 <= 4'd3; rc95 <= 2'd0; rc96 <= 3'd1; rc97 <= 4'd1; rc98 <= 3'd1; rc99 <= 3'd0; rc100 <= 3'd2; rc101 <= 3'd1; rc102 <= 4'd2; rc103 <= 3'd0; rc104 <= 3'd2; rc105 <= 3'd1; rc106 <= 4'd2; rc107 <= 3'd0; rc108 <= 4'd3; rc109 <= 3'd1; rc110 <= 4'd3; rc111 <= 2'd0; rc112 <= 3'd2; rc113 <= 3'd1; rc114 <= 4'd2; rc115 <= 3'd0; rc116 <= 4'd3; rc117 <= 3'd1; rc118 <= 4'd3; rc119 <= 2'd0; rc120 <= 4'd3; rc121 <= 3'd1; rc122 <= 4'd3; rc123 <= 2'd0; rc124 <= 4'd4; rc125 <= 2'd1; rc126 <= 4'd4; rc127 <= 1'd0; end
            {4'd2, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd3; rc2 <= 2'd0; rc3 <= 4'd2; rc4 <= 2'd0; rc5 <= 4'd2; rc6 <= 3'd0; rc7 <= 4'd1; rc8 <= 2'd1; rc9 <= 4'd3; rc10 <= 3'd1; rc11 <= 4'd2; rc12 <= 3'd1; rc13 <= 4'd2; rc14 <= 3'd1; rc15 <= 3'd1; rc16 <= 2'd1; rc17 <= 4'd3; rc18 <= 3'd1; rc19 <= 4'd2; rc20 <= 3'd1; rc21 <= 4'd2; rc22 <= 3'd1; rc23 <= 3'd1; rc24 <= 3'd2; rc25 <= 4'd3; rc26 <= 3'd2; rc27 <= 3'd2; rc28 <= 3'd2; rc29 <= 3'd2; rc30 <= 4'd2; rc31 <= 3'd1; rc32 <= 2'd1; rc33 <= 4'd3; rc34 <= 3'd1; rc35 <= 4'd2; rc36 <= 3'd1; rc37 <= 4'd2; rc38 <= 3'd1; rc39 <= 3'd1; rc40 <= 3'd2; rc41 <= 4'd3; rc42 <= 3'd2; rc43 <= 3'd2; rc44 <= 3'd2; rc45 <= 3'd2; rc46 <= 4'd2; rc47 <= 3'd1; rc48 <= 3'd2; rc49 <= 4'd3; rc50 <= 3'd2; rc51 <= 3'd2; rc52 <= 3'd2; rc53 <= 3'd2; rc54 <= 4'd2; rc55 <= 3'd1; rc56 <= 3'd3; rc57 <= 3'd3; rc58 <= 4'd3; rc59 <= 3'd2; rc60 <= 4'd3; rc61 <= 3'd2; rc62 <= 4'd3; rc63 <= 2'd1; rc64 <= 2'd2; rc65 <= 4'd8; rc66 <= 3'd3; rc67 <= 4'd6; rc68 <= 3'd3; rc69 <= 4'd6; rc70 <= 3'd4; rc71 <= 3'd4; rc72 <= 3'd4; rc73 <= 4'd7; rc74 <= 3'd5; rc75 <= 3'd5; rc76 <= 3'd5; rc77 <= 3'd5; rc78 <= 4'd6; rc79 <= 3'd3; rc80 <= 3'd4; rc81 <= 4'd7; rc82 <= 3'd5; rc83 <= 3'd5; rc84 <= 3'd5; rc85 <= 3'd5; rc86 <= 4'd6; rc87 <= 3'd3; rc88 <= 3'd6; rc89 <= 3'd6; rc90 <= 4'd7; rc91 <= 3'd4; rc92 <= 4'd7; rc93 <= 3'd4; rc94 <= 4'd8; rc95 <= 2'd2; rc96 <= 3'd4; rc97 <= 4'd7; rc98 <= 3'd5; rc99 <= 3'd5; rc100 <= 3'd5; rc101 <= 3'd5; rc102 <= 4'd6; rc103 <= 3'd3; rc104 <= 3'd6; rc105 <= 3'd6; rc106 <= 4'd7; rc107 <= 3'd4; rc108 <= 4'd7; rc109 <= 3'd4; rc110 <= 4'd8; rc111 <= 2'd2; rc112 <= 3'd6; rc113 <= 3'd6; rc114 <= 4'd7; rc115 <= 3'd4; rc116 <= 4'd7; rc117 <= 3'd4; rc118 <= 4'd8; rc119 <= 2'd2; rc120 <= 4'd8; rc121 <= 3'd5; rc122 <= 4'd9; rc123 <= 2'd3; rc124 <= 4'd9; rc125 <= 2'd3; rc126 <= 4'd10; rc127 <= 1'd1; end
            {4'd2, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd10; rc2 <= 2'd2; rc3 <= 4'd8; rc4 <= 2'd2; rc5 <= 4'd8; rc6 <= 3'd3; rc7 <= 4'd6; rc8 <= 2'd3; rc9 <= 4'd9; rc10 <= 3'd4; rc11 <= 4'd7; rc12 <= 3'd4; rc13 <= 4'd7; rc14 <= 3'd5; rc15 <= 3'd5; rc16 <= 2'd3; rc17 <= 4'd9; rc18 <= 3'd4; rc19 <= 4'd7; rc20 <= 3'd4; rc21 <= 4'd7; rc22 <= 3'd5; rc23 <= 3'd5; rc24 <= 3'd5; rc25 <= 4'd8; rc26 <= 3'd6; rc27 <= 3'd6; rc28 <= 3'd6; rc29 <= 3'd6; rc30 <= 4'd7; rc31 <= 3'd4; rc32 <= 2'd3; rc33 <= 4'd9; rc34 <= 3'd4; rc35 <= 4'd7; rc36 <= 3'd4; rc37 <= 4'd7; rc38 <= 3'd5; rc39 <= 3'd5; rc40 <= 3'd5; rc41 <= 4'd8; rc42 <= 3'd6; rc43 <= 3'd6; rc44 <= 3'd6; rc45 <= 3'd6; rc46 <= 4'd7; rc47 <= 3'd4; rc48 <= 3'd5; rc49 <= 4'd8; rc50 <= 3'd6; rc51 <= 3'd6; rc52 <= 3'd6; rc53 <= 3'd6; rc54 <= 4'd7; rc55 <= 3'd4; rc56 <= 3'd7; rc57 <= 3'd7; rc58 <= 4'd8; rc59 <= 3'd5; rc60 <= 4'd8; rc61 <= 3'd5; rc62 <= 4'd9; rc63 <= 2'd3; rc64 <= 2'd0; rc65 <= 4'd2; rc66 <= 3'd0; rc67 <= 4'd1; rc68 <= 3'd0; rc69 <= 4'd1; rc70 <= 3'd0; rc71 <= 3'd0; rc72 <= 3'd1; rc73 <= 4'd2; rc74 <= 3'd1; rc75 <= 3'd1; rc76 <= 3'd1; rc77 <= 3'd1; rc78 <= 4'd1; rc79 <= 3'd0; rc80 <= 3'd1; rc81 <= 4'd2; rc82 <= 3'd1; rc83 <= 3'd1; rc84 <= 3'd1; rc85 <= 3'd1; rc86 <= 4'd1; rc87 <= 3'd0; rc88 <= 3'd2; rc89 <= 3'd2; rc90 <= 4'd2; rc91 <= 3'd1; rc92 <= 4'd2; rc93 <= 3'd1; rc94 <= 4'd2; rc95 <= 2'd0; rc96 <= 3'd1; rc97 <= 4'd2; rc98 <= 3'd1; rc99 <= 3'd1; rc100 <= 3'd1; rc101 <= 3'd1; rc102 <= 4'd1; rc103 <= 3'd0; rc104 <= 3'd2; rc105 <= 3'd2; rc106 <= 4'd2; rc107 <= 3'd1; rc108 <= 4'd2; rc109 <= 3'd1; rc110 <= 4'd2; rc111 <= 2'd0; rc112 <= 3'd2; rc113 <= 3'd2; rc114 <= 4'd2; rc115 <= 3'd1; rc116 <= 4'd2; rc117 <= 3'd1; rc118 <= 4'd2; rc119 <= 2'd0; rc120 <= 4'd3; rc121 <= 3'd2; rc122 <= 4'd3; rc123 <= 2'd1; rc124 <= 4'd3; rc125 <= 2'd1; rc126 <= 4'd3; rc127 <= 1'd0; end
            {4'd3, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd4; rc2 <= 2'd0; rc3 <= 4'd3; rc4 <= 2'd0; rc5 <= 4'd3; rc6 <= 3'd0; rc7 <= 4'd2; rc8 <= 2'd0; rc9 <= 4'd3; rc10 <= 3'd0; rc11 <= 4'd2; rc12 <= 3'd0; rc13 <= 4'd2; rc14 <= 3'd0; rc15 <= 3'd1; rc16 <= 2'd1; rc17 <= 4'd4; rc18 <= 3'd1; rc19 <= 4'd3; rc20 <= 3'd1; rc21 <= 4'd3; rc22 <= 3'd1; rc23 <= 3'd2; rc24 <= 3'd1; rc25 <= 4'd3; rc26 <= 3'd1; rc27 <= 3'd2; rc28 <= 3'd1; rc29 <= 3'd2; rc30 <= 4'd1; rc31 <= 3'd1; rc32 <= 2'd1; rc33 <= 4'd4; rc34 <= 3'd1; rc35 <= 4'd3; rc36 <= 3'd1; rc37 <= 4'd3; rc38 <= 3'd1; rc39 <= 3'd2; rc40 <= 3'd1; rc41 <= 4'd3; rc42 <= 3'd1; rc43 <= 3'd2; rc44 <= 3'd1; rc45 <= 3'd2; rc46 <= 4'd1; rc47 <= 3'd1; rc48 <= 3'd2; rc49 <= 4'd4; rc50 <= 3'd2; rc51 <= 3'd3; rc52 <= 3'd2; rc53 <= 3'd3; rc54 <= 4'd2; rc55 <= 3'd2; rc56 <= 3'd2; rc57 <= 3'd3; rc58 <= 4'd2; rc59 <= 3'd2; rc60 <= 4'd2; rc61 <= 3'd2; rc62 <= 4'd2; rc63 <= 2'd1; rc64 <= 2'd2; rc65 <= 4'd9; rc66 <= 3'd3; rc67 <= 4'd7; rc68 <= 3'd3; rc69 <= 4'd7; rc70 <= 3'd4; rc71 <= 3'd5; rc72 <= 3'd3; rc73 <= 4'd7; rc74 <= 3'd4; rc75 <= 3'd5; rc76 <= 3'd4; rc77 <= 3'd5; rc78 <= 4'd5; rc79 <= 3'd3; rc80 <= 3'd4; rc81 <= 4'd8; rc82 <= 3'd5; rc83 <= 3'd6; rc84 <= 3'd5; rc85 <= 3'd6; rc86 <= 4'd6; rc87 <= 3'd4; rc88 <= 3'd5; rc89 <= 3'd6; rc90 <= 4'd6; rc91 <= 3'd4; rc92 <= 4'd6; rc93 <= 3'd4; rc94 <= 4'd7; rc95 <= 2'd2; rc96 <= 3'd4; rc97 <= 4'd8; rc98 <= 3'd5; rc99 <= 3'd6; rc100 <= 3'd5; rc101 <= 3'd6; rc102 <= 4'd6; rc103 <= 3'd4; rc104 <= 3'd5; rc105 <= 3'd6; rc106 <= 4'd6; rc107 <= 3'd4; rc108 <= 4'd6; rc109 <= 3'd4; rc110 <= 4'd7; rc111 <= 2'd2; rc112 <= 3'd6; rc113 <= 3'd7; rc114 <= 4'd7; rc115 <= 3'd5; rc116 <= 4'd7; rc117 <= 3'd5; rc118 <= 4'd8; rc119 <= 2'd3; rc120 <= 4'd7; rc121 <= 3'd5; rc122 <= 4'd8; rc123 <= 2'd3; rc124 <= 4'd8; rc125 <= 2'd3; rc126 <= 4'd9; rc127 <= 1'd1; end
            {4'd3, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd11; rc2 <= 2'd2; rc3 <= 4'd9; rc4 <= 2'd2; rc5 <= 4'd9; rc6 <= 3'd3; rc7 <= 4'd7; rc8 <= 2'd2; rc9 <= 4'd9; rc10 <= 3'd3; rc11 <= 4'd7; rc12 <= 3'd3; rc13 <= 4'd7; rc14 <= 3'd4; rc15 <= 3'd5; rc16 <= 2'd3; rc17 <= 4'd10; rc18 <= 3'd4; rc19 <= 4'd8; rc20 <= 3'd4; rc21 <= 4'd8; rc22 <= 3'd5; rc23 <= 3'd6; rc24 <= 3'd4; rc25 <= 4'd8; rc26 <= 3'd5; rc27 <= 3'd6; rc28 <= 3'd5; rc29 <= 3'd6; rc30 <= 4'd6; rc31 <= 3'd4; rc32 <= 2'd3; rc33 <= 4'd10; rc34 <= 3'd4; rc35 <= 4'd8; rc36 <= 3'd4; rc37 <= 4'd8; rc38 <= 3'd5; rc39 <= 3'd6; rc40 <= 3'd4; rc41 <= 4'd8; rc42 <= 3'd5; rc43 <= 3'd6; rc44 <= 3'd5; rc45 <= 3'd6; rc46 <= 4'd6; rc47 <= 3'd4; rc48 <= 3'd5; rc49 <= 4'd9; rc50 <= 3'd6; rc51 <= 3'd7; rc52 <= 3'd6; rc53 <= 3'd7; rc54 <= 4'd7; rc55 <= 3'd5; rc56 <= 3'd6; rc57 <= 3'd7; rc58 <= 4'd7; rc59 <= 3'd5; rc60 <= 4'd7; rc61 <= 3'd5; rc62 <= 4'd8; rc63 <= 2'd3; rc64 <= 2'd0; rc65 <= 4'd3; rc66 <= 3'd0; rc67 <= 4'd2; rc68 <= 3'd0; rc69 <= 4'd2; rc70 <= 3'd0; rc71 <= 3'd1; rc72 <= 3'd0; rc73 <= 4'd2; rc74 <= 3'd0; rc75 <= 3'd1; rc76 <= 3'd0; rc77 <= 3'd1; rc78 <= 4'd0; rc79 <= 3'd0; rc80 <= 3'd1; rc81 <= 4'd3; rc82 <= 3'd1; rc83 <= 3'd2; rc84 <= 3'd1; rc85 <= 3'd2; rc86 <= 4'd1; rc87 <= 3'd1; rc88 <= 3'd1; rc89 <= 3'd2; rc90 <= 4'd1; rc91 <= 3'd1; rc92 <= 4'd1; rc93 <= 3'd1; rc94 <= 4'd1; rc95 <= 2'd0; rc96 <= 3'd1; rc97 <= 4'd3; rc98 <= 3'd1; rc99 <= 3'd2; rc100 <= 3'd1; rc101 <= 3'd2; rc102 <= 4'd1; rc103 <= 3'd1; rc104 <= 3'd1; rc105 <= 3'd2; rc106 <= 4'd1; rc107 <= 3'd1; rc108 <= 4'd1; rc109 <= 3'd1; rc110 <= 4'd1; rc111 <= 2'd0; rc112 <= 3'd2; rc113 <= 3'd3; rc114 <= 4'd2; rc115 <= 3'd2; rc116 <= 4'd2; rc117 <= 3'd2; rc118 <= 4'd2; rc119 <= 2'd1; rc120 <= 4'd2; rc121 <= 3'd2; rc122 <= 4'd2; rc123 <= 2'd1; rc124 <= 4'd2; rc125 <= 2'd1; rc126 <= 4'd2; rc127 <= 1'd0; end
            {4'd4, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd5; rc2 <= 2'd0; rc3 <= 4'd4; rc4 <= 2'd0; rc5 <= 4'd4; rc6 <= 3'd0; rc7 <= 4'd3; rc8 <= 2'd0; rc9 <= 4'd4; rc10 <= 3'd0; rc11 <= 4'd3; rc12 <= 3'd0; rc13 <= 4'd3; rc14 <= 3'd0; rc15 <= 3'd2; rc16 <= 2'd0; rc17 <= 4'd4; rc18 <= 3'd0; rc19 <= 4'd3; rc20 <= 3'd0; rc21 <= 4'd3; rc22 <= 3'd0; rc23 <= 3'd2; rc24 <= 3'd0; rc25 <= 4'd3; rc26 <= 3'd0; rc27 <= 3'd2; rc28 <= 3'd0; rc29 <= 3'd2; rc30 <= 4'd0; rc31 <= 3'd1; rc32 <= 2'd1; rc33 <= 4'd5; rc34 <= 3'd1; rc35 <= 4'd4; rc36 <= 3'd1; rc37 <= 4'd4; rc38 <= 3'd1; rc39 <= 3'd3; rc40 <= 3'd1; rc41 <= 4'd4; rc42 <= 3'd1; rc43 <= 3'd3; rc44 <= 3'd1; rc45 <= 3'd3; rc46 <= 4'd1; rc47 <= 3'd2; rc48 <= 3'd1; rc49 <= 4'd4; rc50 <= 3'd1; rc51 <= 3'd3; rc52 <= 3'd1; rc53 <= 3'd3; rc54 <= 4'd1; rc55 <= 3'd2; rc56 <= 3'd1; rc57 <= 3'd3; rc58 <= 4'd1; rc59 <= 3'd2; rc60 <= 4'd1; rc61 <= 3'd2; rc62 <= 4'd1; rc63 <= 2'd1; rc64 <= 2'd2; rc65 <= 4'd10; rc66 <= 3'd3; rc67 <= 4'd8; rc68 <= 3'd3; rc69 <= 4'd8; rc70 <= 3'd4; rc71 <= 3'd6; rc72 <= 3'd3; rc73 <= 4'd8; rc74 <= 3'd4; rc75 <= 3'd6; rc76 <= 3'd4; rc77 <= 3'd6; rc78 <= 4'd5; rc79 <= 3'd4; rc80 <= 3'd3; rc81 <= 4'd8; rc82 <= 3'd4; rc83 <= 3'd6; rc84 <= 3'd4; rc85 <= 3'd6; rc86 <= 4'd5; rc87 <= 3'd4; rc88 <= 3'd4; rc89 <= 3'd6; rc90 <= 4'd5; rc91 <= 3'd4; rc92 <= 4'd5; rc93 <= 3'd4; rc94 <= 4'd6; rc95 <= 2'd2; rc96 <= 3'd4; rc97 <= 4'd9; rc98 <= 3'd5; rc99 <= 3'd7; rc100 <= 3'd5; rc101 <= 3'd7; rc102 <= 4'd6; rc103 <= 3'd5; rc104 <= 3'd5; rc105 <= 3'd7; rc106 <= 4'd6; rc107 <= 3'd5; rc108 <= 4'd6; rc109 <= 3'd5; rc110 <= 4'd7; rc111 <= 2'd3; rc112 <= 3'd5; rc113 <= 3'd7; rc114 <= 4'd6; rc115 <= 3'd5; rc116 <= 4'd6; rc117 <= 3'd5; rc118 <= 4'd7; rc119 <= 2'd3; rc120 <= 4'd6; rc121 <= 3'd5; rc122 <= 4'd7; rc123 <= 2'd3; rc124 <= 4'd7; rc125 <= 2'd3; rc126 <= 4'd8; rc127 <= 1'd1; end
            {4'd4, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd12; rc2 <= 2'd2; rc3 <= 4'd10; rc4 <= 2'd2; rc5 <= 4'd10; rc6 <= 3'd3; rc7 <= 4'd8; rc8 <= 2'd2; rc9 <= 4'd10; rc10 <= 3'd3; rc11 <= 4'd8; rc12 <= 3'd3; rc13 <= 4'd8; rc14 <= 3'd4; rc15 <= 3'd6; rc16 <= 2'd2; rc17 <= 4'd10; rc18 <= 3'd3; rc19 <= 4'd8; rc20 <= 3'd3; rc21 <= 4'd8; rc22 <= 3'd4; rc23 <= 3'd6; rc24 <= 3'd3; rc25 <= 4'd8; rc26 <= 3'd4; rc27 <= 3'd6; rc28 <= 3'd4; rc29 <= 3'd6; rc30 <= 4'd5; rc31 <= 3'd4; rc32 <= 2'd3; rc33 <= 4'd11; rc34 <= 3'd4; rc35 <= 4'd9; rc36 <= 3'd4; rc37 <= 4'd9; rc38 <= 3'd5; rc39 <= 3'd7; rc40 <= 3'd4; rc41 <= 4'd9; rc42 <= 3'd5; rc43 <= 3'd7; rc44 <= 3'd5; rc45 <= 3'd7; rc46 <= 4'd6; rc47 <= 3'd5; rc48 <= 3'd4; rc49 <= 4'd9; rc50 <= 3'd5; rc51 <= 3'd7; rc52 <= 3'd5; rc53 <= 3'd7; rc54 <= 4'd6; rc55 <= 3'd5; rc56 <= 3'd5; rc57 <= 3'd7; rc58 <= 4'd6; rc59 <= 3'd5; rc60 <= 4'd6; rc61 <= 3'd5; rc62 <= 4'd7; rc63 <= 2'd3; rc64 <= 2'd0; rc65 <= 4'd4; rc66 <= 3'd0; rc67 <= 4'd3; rc68 <= 3'd0; rc69 <= 4'd3; rc70 <= 3'd0; rc71 <= 3'd2; rc72 <= 3'd0; rc73 <= 4'd3; rc74 <= 3'd0; rc75 <= 3'd2; rc76 <= 3'd0; rc77 <= 3'd2; rc78 <= 4'd0; rc79 <= 3'd1; rc80 <= 3'd0; rc81 <= 4'd3; rc82 <= 3'd0; rc83 <= 3'd2; rc84 <= 3'd0; rc85 <= 3'd2; rc86 <= 4'd0; rc87 <= 3'd1; rc88 <= 3'd0; rc89 <= 3'd2; rc90 <= 4'd0; rc91 <= 3'd1; rc92 <= 4'd0; rc93 <= 3'd1; rc94 <= 4'd0; rc95 <= 2'd0; rc96 <= 3'd1; rc97 <= 4'd4; rc98 <= 3'd1; rc99 <= 3'd3; rc100 <= 3'd1; rc101 <= 3'd3; rc102 <= 4'd1; rc103 <= 3'd2; rc104 <= 3'd1; rc105 <= 3'd3; rc106 <= 4'd1; rc107 <= 3'd2; rc108 <= 4'd1; rc109 <= 3'd2; rc110 <= 4'd1; rc111 <= 2'd1; rc112 <= 3'd1; rc113 <= 3'd3; rc114 <= 4'd1; rc115 <= 3'd2; rc116 <= 4'd1; rc117 <= 3'd2; rc118 <= 4'd1; rc119 <= 2'd1; rc120 <= 4'd1; rc121 <= 3'd2; rc122 <= 4'd1; rc123 <= 2'd1; rc124 <= 4'd1; rc125 <= 2'd1; rc126 <= 4'd1; rc127 <= 1'd0; end
            {4'd5, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd6; rc2 <= 2'd0; rc3 <= 4'd5; rc4 <= 2'd0; rc5 <= 4'd5; rc6 <= 3'd0; rc7 <= 4'd4; rc8 <= 2'd0; rc9 <= 4'd5; rc10 <= 3'd0; rc11 <= 4'd4; rc12 <= 3'd0; rc13 <= 4'd4; rc14 <= 3'd0; rc15 <= 3'd3; rc16 <= 2'd0; rc17 <= 4'd5; rc18 <= 3'd0; rc19 <= 4'd4; rc20 <= 3'd0; rc21 <= 4'd4; rc22 <= 3'd0; rc23 <= 3'd3; rc24 <= 3'd0; rc25 <= 4'd4; rc26 <= 3'd0; rc27 <= 3'd3; rc28 <= 3'd0; rc29 <= 3'd3; rc30 <= 4'd0; rc31 <= 3'd2; rc32 <= 2'd0; rc33 <= 4'd5; rc34 <= 3'd0; rc35 <= 4'd4; rc36 <= 3'd0; rc37 <= 4'd4; rc38 <= 3'd0; rc39 <= 3'd3; rc40 <= 3'd0; rc41 <= 4'd4; rc42 <= 3'd0; rc43 <= 3'd3; rc44 <= 3'd0; rc45 <= 3'd3; rc46 <= 4'd0; rc47 <= 3'd2; rc48 <= 3'd0; rc49 <= 4'd4; rc50 <= 3'd0; rc51 <= 3'd3; rc52 <= 3'd0; rc53 <= 3'd3; rc54 <= 4'd0; rc55 <= 3'd2; rc56 <= 3'd0; rc57 <= 3'd3; rc58 <= 4'd0; rc59 <= 3'd2; rc60 <= 4'd0; rc61 <= 3'd2; rc62 <= 4'd0; rc63 <= 2'd1; rc64 <= 2'd2; rc65 <= 4'd11; rc66 <= 3'd3; rc67 <= 4'd9; rc68 <= 3'd3; rc69 <= 4'd9; rc70 <= 3'd4; rc71 <= 3'd7; rc72 <= 3'd3; rc73 <= 4'd9; rc74 <= 3'd4; rc75 <= 3'd7; rc76 <= 3'd4; rc77 <= 3'd7; rc78 <= 4'd5; rc79 <= 3'd5; rc80 <= 3'd3; rc81 <= 4'd9; rc82 <= 3'd4; rc83 <= 3'd7; rc84 <= 3'd4; rc85 <= 3'd7; rc86 <= 4'd5; rc87 <= 3'd5; rc88 <= 3'd4; rc89 <= 3'd7; rc90 <= 4'd5; rc91 <= 3'd5; rc92 <= 4'd5; rc93 <= 3'd5; rc94 <= 4'd6; rc95 <= 2'd3; rc96 <= 3'd3; rc97 <= 4'd9; rc98 <= 3'd4; rc99 <= 3'd7; rc100 <= 3'd4; rc101 <= 3'd7; rc102 <= 4'd5; rc103 <= 3'd5; rc104 <= 3'd4; rc105 <= 3'd7; rc106 <= 4'd5; rc107 <= 3'd5; rc108 <= 4'd5; rc109 <= 3'd5; rc110 <= 4'd6; rc111 <= 2'd3; rc112 <= 3'd4; rc113 <= 3'd7; rc114 <= 4'd5; rc115 <= 3'd5; rc116 <= 4'd5; rc117 <= 3'd5; rc118 <= 4'd6; rc119 <= 2'd3; rc120 <= 4'd5; rc121 <= 3'd5; rc122 <= 4'd6; rc123 <= 2'd3; rc124 <= 4'd6; rc125 <= 2'd3; rc126 <= 4'd7; rc127 <= 1'd1; end
            {4'd5, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd13; rc2 <= 2'd2; rc3 <= 4'd11; rc4 <= 2'd2; rc5 <= 4'd11; rc6 <= 3'd3; rc7 <= 4'd9; rc8 <= 2'd2; rc9 <= 4'd11; rc10 <= 3'd3; rc11 <= 4'd9; rc12 <= 3'd3; rc13 <= 4'd9; rc14 <= 3'd4; rc15 <= 3'd7; rc16 <= 2'd2; rc17 <= 4'd11; rc18 <= 3'd3; rc19 <= 4'd9; rc20 <= 3'd3; rc21 <= 4'd9; rc22 <= 3'd4; rc23 <= 3'd7; rc24 <= 3'd3; rc25 <= 4'd9; rc26 <= 3'd4; rc27 <= 3'd7; rc28 <= 3'd4; rc29 <= 3'd7; rc30 <= 4'd5; rc31 <= 3'd5; rc32 <= 2'd2; rc33 <= 4'd11; rc34 <= 3'd3; rc35 <= 4'd9; rc36 <= 3'd3; rc37 <= 4'd9; rc38 <= 3'd4; rc39 <= 3'd7; rc40 <= 3'd3; rc41 <= 4'd9; rc42 <= 3'd4; rc43 <= 3'd7; rc44 <= 3'd4; rc45 <= 3'd7; rc46 <= 4'd5; rc47 <= 3'd5; rc48 <= 3'd3; rc49 <= 4'd9; rc50 <= 3'd4; rc51 <= 3'd7; rc52 <= 3'd4; rc53 <= 3'd7; rc54 <= 4'd5; rc55 <= 3'd5; rc56 <= 3'd4; rc57 <= 3'd7; rc58 <= 4'd5; rc59 <= 3'd5; rc60 <= 4'd5; rc61 <= 3'd5; rc62 <= 4'd6; rc63 <= 2'd3; rc64 <= 2'd0; rc65 <= 4'd5; rc66 <= 3'd0; rc67 <= 4'd4; rc68 <= 3'd0; rc69 <= 4'd4; rc70 <= 3'd0; rc71 <= 3'd3; rc72 <= 3'd0; rc73 <= 4'd4; rc74 <= 3'd0; rc75 <= 3'd3; rc76 <= 3'd0; rc77 <= 3'd3; rc78 <= 4'd0; rc79 <= 3'd2; rc80 <= 3'd0; rc81 <= 4'd4; rc82 <= 3'd0; rc83 <= 3'd3; rc84 <= 3'd0; rc85 <= 3'd3; rc86 <= 4'd0; rc87 <= 3'd2; rc88 <= 3'd0; rc89 <= 3'd3; rc90 <= 4'd0; rc91 <= 3'd2; rc92 <= 4'd0; rc93 <= 3'd2; rc94 <= 4'd0; rc95 <= 2'd1; rc96 <= 3'd0; rc97 <= 4'd4; rc98 <= 3'd0; rc99 <= 3'd3; rc100 <= 3'd0; rc101 <= 3'd3; rc102 <= 4'd0; rc103 <= 3'd2; rc104 <= 3'd0; rc105 <= 3'd3; rc106 <= 4'd0; rc107 <= 3'd2; rc108 <= 4'd0; rc109 <= 3'd2; rc110 <= 4'd0; rc111 <= 2'd1; rc112 <= 3'd0; rc113 <= 3'd3; rc114 <= 4'd0; rc115 <= 3'd2; rc116 <= 4'd0; rc117 <= 3'd2; rc118 <= 4'd0; rc119 <= 2'd1; rc120 <= 4'd0; rc121 <= 3'd2; rc122 <= 4'd0; rc123 <= 2'd1; rc124 <= 4'd0; rc125 <= 2'd1; rc126 <= 4'd0; rc127 <= 1'd0; end
            {4'd6, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd7; rc2 <= 2'd0; rc3 <= 4'd6; rc4 <= 2'd0; rc5 <= 4'd6; rc6 <= 3'd0; rc7 <= 4'd5; rc8 <= 2'd0; rc9 <= 4'd6; rc10 <= 3'd0; rc11 <= 4'd5; rc12 <= 3'd0; rc13 <= 4'd5; rc14 <= 3'd0; rc15 <= 3'd4; rc16 <= 2'd0; rc17 <= 4'd6; rc18 <= 3'd0; rc19 <= 4'd5; rc20 <= 3'd0; rc21 <= 4'd5; rc22 <= 3'd0; rc23 <= 3'd4; rc24 <= 3'd0; rc25 <= 4'd5; rc26 <= 3'd0; rc27 <= 3'd4; rc28 <= 3'd0; rc29 <= 3'd4; rc30 <= 4'd0; rc31 <= 3'd3; rc32 <= 2'd0; rc33 <= 4'd6; rc34 <= 3'd0; rc35 <= 4'd5; rc36 <= 3'd0; rc37 <= 4'd5; rc38 <= 3'd0; rc39 <= 3'd4; rc40 <= 3'd0; rc41 <= 4'd5; rc42 <= 3'd0; rc43 <= 3'd4; rc44 <= 3'd0; rc45 <= 3'd4; rc46 <= 4'd0; rc47 <= 3'd3; rc48 <= 3'd0; rc49 <= 4'd5; rc50 <= 3'd0; rc51 <= 3'd4; rc52 <= 3'd0; rc53 <= 3'd4; rc54 <= 4'd0; rc55 <= 3'd3; rc56 <= 3'd0; rc57 <= 3'd4; rc58 <= 4'd0; rc59 <= 3'd3; rc60 <= 4'd0; rc61 <= 3'd3; rc62 <= 4'd0; rc63 <= 2'd2; rc64 <= 2'd1; rc65 <= 4'd11; rc66 <= 3'd2; rc67 <= 4'd9; rc68 <= 3'd2; rc69 <= 4'd9; rc70 <= 3'd3; rc71 <= 3'd7; rc72 <= 3'd2; rc73 <= 4'd9; rc74 <= 3'd3; rc75 <= 3'd7; rc76 <= 3'd3; rc77 <= 3'd7; rc78 <= 4'd4; rc79 <= 3'd5; rc80 <= 3'd2; rc81 <= 4'd9; rc82 <= 3'd3; rc83 <= 3'd7; rc84 <= 3'd3; rc85 <= 3'd7; rc86 <= 4'd4; rc87 <= 3'd5; rc88 <= 3'd3; rc89 <= 3'd7; rc90 <= 4'd4; rc91 <= 3'd5; rc92 <= 4'd4; rc93 <= 3'd5; rc94 <= 4'd5; rc95 <= 2'd3; rc96 <= 3'd2; rc97 <= 4'd9; rc98 <= 3'd3; rc99 <= 3'd7; rc100 <= 3'd3; rc101 <= 3'd7; rc102 <= 4'd4; rc103 <= 3'd5; rc104 <= 3'd3; rc105 <= 3'd7; rc106 <= 4'd4; rc107 <= 3'd5; rc108 <= 4'd4; rc109 <= 3'd5; rc110 <= 4'd5; rc111 <= 2'd3; rc112 <= 3'd3; rc113 <= 3'd7; rc114 <= 4'd4; rc115 <= 3'd5; rc116 <= 4'd4; rc117 <= 3'd5; rc118 <= 4'd5; rc119 <= 2'd3; rc120 <= 4'd4; rc121 <= 3'd5; rc122 <= 4'd5; rc123 <= 2'd3; rc124 <= 4'd5; rc125 <= 2'd3; rc126 <= 4'd6; rc127 <= 1'd1; end
            {4'd6, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 4'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 4'd0; rc12 <= 3'd3; rc13 <= 4'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 4'd0; rc20 <= 3'd3; rc21 <= 4'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 4'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 3'd0; rc32 <= 2'd2; rc33 <= 4'd0; rc34 <= 3'd3; rc35 <= 4'd0; rc36 <= 3'd3; rc37 <= 4'd0; rc38 <= 3'd4; rc39 <= 3'd0; rc40 <= 3'd3; rc41 <= 4'd0; rc42 <= 3'd4; rc43 <= 3'd0; rc44 <= 3'd4; rc45 <= 3'd0; rc46 <= 4'd5; rc47 <= 3'd0; rc48 <= 3'd3; rc49 <= 4'd0; rc50 <= 3'd4; rc51 <= 3'd0; rc52 <= 3'd4; rc53 <= 3'd0; rc54 <= 4'd5; rc55 <= 3'd0; rc56 <= 3'd4; rc57 <= 3'd0; rc58 <= 4'd5; rc59 <= 3'd0; rc60 <= 4'd5; rc61 <= 3'd0; rc62 <= 4'd6; rc63 <= 2'd0; rc64 <= 2'd3; rc65 <= 4'd5; rc66 <= 3'd5; rc67 <= 4'd4; rc68 <= 3'd5; rc69 <= 4'd4; rc70 <= 3'd7; rc71 <= 3'd3; rc72 <= 3'd5; rc73 <= 4'd4; rc74 <= 3'd7; rc75 <= 3'd3; rc76 <= 3'd7; rc77 <= 3'd3; rc78 <= 4'd9; rc79 <= 3'd2; rc80 <= 3'd5; rc81 <= 4'd4; rc82 <= 3'd7; rc83 <= 3'd3; rc84 <= 3'd7; rc85 <= 3'd3; rc86 <= 4'd9; rc87 <= 3'd2; rc88 <= 3'd7; rc89 <= 3'd3; rc90 <= 4'd9; rc91 <= 3'd2; rc92 <= 4'd9; rc93 <= 3'd2; rc94 <= 4'd11; rc95 <= 2'd1; rc96 <= 3'd5; rc97 <= 4'd4; rc98 <= 3'd7; rc99 <= 3'd3; rc100 <= 3'd7; rc101 <= 3'd3; rc102 <= 4'd9; rc103 <= 3'd2; rc104 <= 3'd7; rc105 <= 3'd3; rc106 <= 4'd9; rc107 <= 3'd2; rc108 <= 4'd9; rc109 <= 3'd2; rc110 <= 4'd11; rc111 <= 2'd1; rc112 <= 3'd7; rc113 <= 3'd3; rc114 <= 4'd9; rc115 <= 3'd2; rc116 <= 4'd9; rc117 <= 3'd2; rc118 <= 4'd11; rc119 <= 2'd1; rc120 <= 4'd9; rc121 <= 3'd2; rc122 <= 4'd11; rc123 <= 2'd1; rc124 <= 4'd11; rc125 <= 2'd1; rc126 <= 4'd13; rc127 <= 1'd0; end
            {4'd7, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd7; rc2 <= 2'd0; rc3 <= 4'd6; rc4 <= 2'd0; rc5 <= 4'd6; rc6 <= 3'd0; rc7 <= 4'd5; rc8 <= 2'd0; rc9 <= 4'd6; rc10 <= 3'd0; rc11 <= 4'd5; rc12 <= 3'd0; rc13 <= 4'd5; rc14 <= 3'd0; rc15 <= 3'd4; rc16 <= 2'd0; rc17 <= 4'd6; rc18 <= 3'd0; rc19 <= 4'd5; rc20 <= 3'd0; rc21 <= 4'd5; rc22 <= 3'd0; rc23 <= 3'd4; rc24 <= 3'd0; rc25 <= 4'd5; rc26 <= 3'd0; rc27 <= 3'd4; rc28 <= 3'd0; rc29 <= 3'd4; rc30 <= 4'd0; rc31 <= 3'd3; rc32 <= 2'd0; rc33 <= 4'd6; rc34 <= 3'd0; rc35 <= 4'd5; rc36 <= 3'd0; rc37 <= 4'd5; rc38 <= 3'd0; rc39 <= 3'd4; rc40 <= 3'd0; rc41 <= 4'd5; rc42 <= 3'd0; rc43 <= 3'd4; rc44 <= 3'd0; rc45 <= 3'd4; rc46 <= 4'd0; rc47 <= 3'd3; rc48 <= 3'd0; rc49 <= 4'd5; rc50 <= 3'd0; rc51 <= 3'd4; rc52 <= 3'd0; rc53 <= 3'd4; rc54 <= 4'd0; rc55 <= 3'd3; rc56 <= 3'd0; rc57 <= 3'd4; rc58 <= 4'd0; rc59 <= 3'd3; rc60 <= 4'd0; rc61 <= 3'd3; rc62 <= 4'd0; rc63 <= 2'd2; rc64 <= 2'd1; rc65 <= 4'd11; rc66 <= 3'd2; rc67 <= 4'd9; rc68 <= 3'd2; rc69 <= 4'd9; rc70 <= 3'd3; rc71 <= 3'd7; rc72 <= 3'd2; rc73 <= 4'd9; rc74 <= 3'd3; rc75 <= 3'd7; rc76 <= 3'd3; rc77 <= 3'd7; rc78 <= 4'd4; rc79 <= 3'd5; rc80 <= 3'd2; rc81 <= 4'd9; rc82 <= 3'd3; rc83 <= 3'd7; rc84 <= 3'd3; rc85 <= 3'd7; rc86 <= 4'd4; rc87 <= 3'd5; rc88 <= 3'd3; rc89 <= 3'd7; rc90 <= 4'd4; rc91 <= 3'd5; rc92 <= 4'd4; rc93 <= 3'd5; rc94 <= 4'd5; rc95 <= 2'd3; rc96 <= 3'd2; rc97 <= 4'd9; rc98 <= 3'd3; rc99 <= 3'd7; rc100 <= 3'd3; rc101 <= 3'd7; rc102 <= 4'd4; rc103 <= 3'd5; rc104 <= 3'd3; rc105 <= 3'd7; rc106 <= 4'd4; rc107 <= 3'd5; rc108 <= 4'd4; rc109 <= 3'd5; rc110 <= 4'd5; rc111 <= 2'd3; rc112 <= 3'd3; rc113 <= 3'd7; rc114 <= 4'd4; rc115 <= 3'd5; rc116 <= 4'd4; rc117 <= 3'd5; rc118 <= 4'd5; rc119 <= 2'd3; rc120 <= 4'd4; rc121 <= 3'd5; rc122 <= 4'd5; rc123 <= 2'd3; rc124 <= 4'd5; rc125 <= 2'd3; rc126 <= 4'd6; rc127 <= 1'd1; end
            {4'd7, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 4'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 4'd0; rc12 <= 3'd3; rc13 <= 4'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 4'd0; rc20 <= 3'd3; rc21 <= 4'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 4'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 3'd0; rc32 <= 2'd2; rc33 <= 4'd0; rc34 <= 3'd3; rc35 <= 4'd0; rc36 <= 3'd3; rc37 <= 4'd0; rc38 <= 3'd4; rc39 <= 3'd0; rc40 <= 3'd3; rc41 <= 4'd0; rc42 <= 3'd4; rc43 <= 3'd0; rc44 <= 3'd4; rc45 <= 3'd0; rc46 <= 4'd5; rc47 <= 3'd0; rc48 <= 3'd3; rc49 <= 4'd0; rc50 <= 3'd4; rc51 <= 3'd0; rc52 <= 3'd4; rc53 <= 3'd0; rc54 <= 4'd5; rc55 <= 3'd0; rc56 <= 3'd4; rc57 <= 3'd0; rc58 <= 4'd5; rc59 <= 3'd0; rc60 <= 4'd5; rc61 <= 3'd0; rc62 <= 4'd6; rc63 <= 2'd0; rc64 <= 2'd3; rc65 <= 4'd5; rc66 <= 3'd5; rc67 <= 4'd4; rc68 <= 3'd5; rc69 <= 4'd4; rc70 <= 3'd7; rc71 <= 3'd3; rc72 <= 3'd5; rc73 <= 4'd4; rc74 <= 3'd7; rc75 <= 3'd3; rc76 <= 3'd7; rc77 <= 3'd3; rc78 <= 4'd9; rc79 <= 3'd2; rc80 <= 3'd5; rc81 <= 4'd4; rc82 <= 3'd7; rc83 <= 3'd3; rc84 <= 3'd7; rc85 <= 3'd3; rc86 <= 4'd9; rc87 <= 3'd2; rc88 <= 3'd7; rc89 <= 3'd3; rc90 <= 4'd9; rc91 <= 3'd2; rc92 <= 4'd9; rc93 <= 3'd2; rc94 <= 4'd11; rc95 <= 2'd1; rc96 <= 3'd5; rc97 <= 4'd4; rc98 <= 3'd7; rc99 <= 3'd3; rc100 <= 3'd7; rc101 <= 3'd3; rc102 <= 4'd9; rc103 <= 3'd2; rc104 <= 3'd7; rc105 <= 3'd3; rc106 <= 4'd9; rc107 <= 3'd2; rc108 <= 4'd9; rc109 <= 3'd2; rc110 <= 4'd11; rc111 <= 2'd1; rc112 <= 3'd7; rc113 <= 3'd3; rc114 <= 4'd9; rc115 <= 3'd2; rc116 <= 4'd9; rc117 <= 3'd2; rc118 <= 4'd11; rc119 <= 2'd1; rc120 <= 4'd9; rc121 <= 3'd2; rc122 <= 4'd11; rc123 <= 2'd1; rc124 <= 4'd11; rc125 <= 2'd1; rc126 <= 4'd13; rc127 <= 1'd0; end
            {4'd8, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd7; rc2 <= 2'd0; rc3 <= 4'd6; rc4 <= 2'd0; rc5 <= 4'd6; rc6 <= 3'd0; rc7 <= 4'd5; rc8 <= 2'd0; rc9 <= 4'd6; rc10 <= 3'd0; rc11 <= 4'd5; rc12 <= 3'd0; rc13 <= 4'd5; rc14 <= 3'd0; rc15 <= 3'd4; rc16 <= 2'd0; rc17 <= 4'd6; rc18 <= 3'd0; rc19 <= 4'd5; rc20 <= 3'd0; rc21 <= 4'd5; rc22 <= 3'd0; rc23 <= 3'd4; rc24 <= 3'd0; rc25 <= 4'd5; rc26 <= 3'd0; rc27 <= 3'd4; rc28 <= 3'd0; rc29 <= 3'd4; rc30 <= 4'd0; rc31 <= 3'd3; rc32 <= 2'd0; rc33 <= 4'd6; rc34 <= 3'd0; rc35 <= 4'd5; rc36 <= 3'd0; rc37 <= 4'd5; rc38 <= 3'd0; rc39 <= 3'd4; rc40 <= 3'd0; rc41 <= 4'd5; rc42 <= 3'd0; rc43 <= 3'd4; rc44 <= 3'd0; rc45 <= 3'd4; rc46 <= 4'd0; rc47 <= 3'd3; rc48 <= 3'd0; rc49 <= 4'd5; rc50 <= 3'd0; rc51 <= 3'd4; rc52 <= 3'd0; rc53 <= 3'd4; rc54 <= 4'd0; rc55 <= 3'd3; rc56 <= 3'd0; rc57 <= 3'd4; rc58 <= 4'd0; rc59 <= 3'd3; rc60 <= 4'd0; rc61 <= 3'd3; rc62 <= 4'd0; rc63 <= 2'd2; rc64 <= 2'd1; rc65 <= 4'd11; rc66 <= 3'd2; rc67 <= 4'd9; rc68 <= 3'd2; rc69 <= 4'd9; rc70 <= 3'd3; rc71 <= 3'd7; rc72 <= 3'd2; rc73 <= 4'd9; rc74 <= 3'd3; rc75 <= 3'd7; rc76 <= 3'd3; rc77 <= 3'd7; rc78 <= 4'd4; rc79 <= 3'd5; rc80 <= 3'd2; rc81 <= 4'd9; rc82 <= 3'd3; rc83 <= 3'd7; rc84 <= 3'd3; rc85 <= 3'd7; rc86 <= 4'd4; rc87 <= 3'd5; rc88 <= 3'd3; rc89 <= 3'd7; rc90 <= 4'd4; rc91 <= 3'd5; rc92 <= 4'd4; rc93 <= 3'd5; rc94 <= 4'd5; rc95 <= 2'd3; rc96 <= 3'd2; rc97 <= 4'd9; rc98 <= 3'd3; rc99 <= 3'd7; rc100 <= 3'd3; rc101 <= 3'd7; rc102 <= 4'd4; rc103 <= 3'd5; rc104 <= 3'd3; rc105 <= 3'd7; rc106 <= 4'd4; rc107 <= 3'd5; rc108 <= 4'd4; rc109 <= 3'd5; rc110 <= 4'd5; rc111 <= 2'd3; rc112 <= 3'd3; rc113 <= 3'd7; rc114 <= 4'd4; rc115 <= 3'd5; rc116 <= 4'd4; rc117 <= 3'd5; rc118 <= 4'd5; rc119 <= 2'd3; rc120 <= 4'd4; rc121 <= 3'd5; rc122 <= 4'd5; rc123 <= 2'd3; rc124 <= 4'd5; rc125 <= 2'd3; rc126 <= 4'd6; rc127 <= 1'd1; end
            {4'd8, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 4'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 4'd0; rc12 <= 3'd3; rc13 <= 4'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 4'd0; rc20 <= 3'd3; rc21 <= 4'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 4'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 3'd0; rc32 <= 2'd2; rc33 <= 4'd0; rc34 <= 3'd3; rc35 <= 4'd0; rc36 <= 3'd3; rc37 <= 4'd0; rc38 <= 3'd4; rc39 <= 3'd0; rc40 <= 3'd3; rc41 <= 4'd0; rc42 <= 3'd4; rc43 <= 3'd0; rc44 <= 3'd4; rc45 <= 3'd0; rc46 <= 4'd5; rc47 <= 3'd0; rc48 <= 3'd3; rc49 <= 4'd0; rc50 <= 3'd4; rc51 <= 3'd0; rc52 <= 3'd4; rc53 <= 3'd0; rc54 <= 4'd5; rc55 <= 3'd0; rc56 <= 3'd4; rc57 <= 3'd0; rc58 <= 4'd5; rc59 <= 3'd0; rc60 <= 4'd5; rc61 <= 3'd0; rc62 <= 4'd6; rc63 <= 2'd0; rc64 <= 2'd3; rc65 <= 4'd5; rc66 <= 3'd5; rc67 <= 4'd4; rc68 <= 3'd5; rc69 <= 4'd4; rc70 <= 3'd7; rc71 <= 3'd3; rc72 <= 3'd5; rc73 <= 4'd4; rc74 <= 3'd7; rc75 <= 3'd3; rc76 <= 3'd7; rc77 <= 3'd3; rc78 <= 4'd9; rc79 <= 3'd2; rc80 <= 3'd5; rc81 <= 4'd4; rc82 <= 3'd7; rc83 <= 3'd3; rc84 <= 3'd7; rc85 <= 3'd3; rc86 <= 4'd9; rc87 <= 3'd2; rc88 <= 3'd7; rc89 <= 3'd3; rc90 <= 4'd9; rc91 <= 3'd2; rc92 <= 4'd9; rc93 <= 3'd2; rc94 <= 4'd11; rc95 <= 2'd1; rc96 <= 3'd5; rc97 <= 4'd4; rc98 <= 3'd7; rc99 <= 3'd3; rc100 <= 3'd7; rc101 <= 3'd3; rc102 <= 4'd9; rc103 <= 3'd2; rc104 <= 3'd7; rc105 <= 3'd3; rc106 <= 4'd9; rc107 <= 3'd2; rc108 <= 4'd9; rc109 <= 3'd2; rc110 <= 4'd11; rc111 <= 2'd1; rc112 <= 3'd7; rc113 <= 3'd3; rc114 <= 4'd9; rc115 <= 3'd2; rc116 <= 4'd9; rc117 <= 3'd2; rc118 <= 4'd11; rc119 <= 2'd1; rc120 <= 4'd9; rc121 <= 3'd2; rc122 <= 4'd11; rc123 <= 2'd1; rc124 <= 4'd11; rc125 <= 2'd1; rc126 <= 4'd13; rc127 <= 1'd0; end
            {4'd9, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd7; rc2 <= 2'd0; rc3 <= 4'd6; rc4 <= 2'd0; rc5 <= 4'd6; rc6 <= 3'd0; rc7 <= 4'd5; rc8 <= 2'd0; rc9 <= 4'd6; rc10 <= 3'd0; rc11 <= 4'd5; rc12 <= 3'd0; rc13 <= 4'd5; rc14 <= 3'd0; rc15 <= 3'd4; rc16 <= 2'd0; rc17 <= 4'd6; rc18 <= 3'd0; rc19 <= 4'd5; rc20 <= 3'd0; rc21 <= 4'd5; rc22 <= 3'd0; rc23 <= 3'd4; rc24 <= 3'd0; rc25 <= 4'd5; rc26 <= 3'd0; rc27 <= 3'd4; rc28 <= 3'd0; rc29 <= 3'd4; rc30 <= 4'd0; rc31 <= 3'd3; rc32 <= 2'd0; rc33 <= 4'd6; rc34 <= 3'd0; rc35 <= 4'd5; rc36 <= 3'd0; rc37 <= 4'd5; rc38 <= 3'd0; rc39 <= 3'd4; rc40 <= 3'd0; rc41 <= 4'd5; rc42 <= 3'd0; rc43 <= 3'd4; rc44 <= 3'd0; rc45 <= 3'd4; rc46 <= 4'd0; rc47 <= 3'd3; rc48 <= 3'd0; rc49 <= 4'd5; rc50 <= 3'd0; rc51 <= 3'd4; rc52 <= 3'd0; rc53 <= 3'd4; rc54 <= 4'd0; rc55 <= 3'd3; rc56 <= 3'd0; rc57 <= 3'd4; rc58 <= 4'd0; rc59 <= 3'd3; rc60 <= 4'd0; rc61 <= 3'd3; rc62 <= 4'd0; rc63 <= 2'd2; rc64 <= 2'd1; rc65 <= 4'd11; rc66 <= 3'd2; rc67 <= 4'd9; rc68 <= 3'd2; rc69 <= 4'd9; rc70 <= 3'd3; rc71 <= 3'd7; rc72 <= 3'd2; rc73 <= 4'd9; rc74 <= 3'd3; rc75 <= 3'd7; rc76 <= 3'd3; rc77 <= 3'd7; rc78 <= 4'd4; rc79 <= 3'd5; rc80 <= 3'd2; rc81 <= 4'd9; rc82 <= 3'd3; rc83 <= 3'd7; rc84 <= 3'd3; rc85 <= 3'd7; rc86 <= 4'd4; rc87 <= 3'd5; rc88 <= 3'd3; rc89 <= 3'd7; rc90 <= 4'd4; rc91 <= 3'd5; rc92 <= 4'd4; rc93 <= 3'd5; rc94 <= 4'd5; rc95 <= 2'd3; rc96 <= 3'd2; rc97 <= 4'd9; rc98 <= 3'd3; rc99 <= 3'd7; rc100 <= 3'd3; rc101 <= 3'd7; rc102 <= 4'd4; rc103 <= 3'd5; rc104 <= 3'd3; rc105 <= 3'd7; rc106 <= 4'd4; rc107 <= 3'd5; rc108 <= 4'd4; rc109 <= 3'd5; rc110 <= 4'd5; rc111 <= 2'd3; rc112 <= 3'd3; rc113 <= 3'd7; rc114 <= 4'd4; rc115 <= 3'd5; rc116 <= 4'd4; rc117 <= 3'd5; rc118 <= 4'd5; rc119 <= 2'd3; rc120 <= 4'd4; rc121 <= 3'd5; rc122 <= 4'd5; rc123 <= 2'd3; rc124 <= 4'd5; rc125 <= 2'd3; rc126 <= 4'd6; rc127 <= 1'd1; end
            {4'd9, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 4'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 4'd0; rc12 <= 3'd3; rc13 <= 4'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 4'd0; rc20 <= 3'd3; rc21 <= 4'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 4'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 3'd0; rc32 <= 2'd2; rc33 <= 4'd0; rc34 <= 3'd3; rc35 <= 4'd0; rc36 <= 3'd3; rc37 <= 4'd0; rc38 <= 3'd4; rc39 <= 3'd0; rc40 <= 3'd3; rc41 <= 4'd0; rc42 <= 3'd4; rc43 <= 3'd0; rc44 <= 3'd4; rc45 <= 3'd0; rc46 <= 4'd5; rc47 <= 3'd0; rc48 <= 3'd3; rc49 <= 4'd0; rc50 <= 3'd4; rc51 <= 3'd0; rc52 <= 3'd4; rc53 <= 3'd0; rc54 <= 4'd5; rc55 <= 3'd0; rc56 <= 3'd4; rc57 <= 3'd0; rc58 <= 4'd5; rc59 <= 3'd0; rc60 <= 4'd5; rc61 <= 3'd0; rc62 <= 4'd6; rc63 <= 2'd0; rc64 <= 2'd3; rc65 <= 4'd5; rc66 <= 3'd5; rc67 <= 4'd4; rc68 <= 3'd5; rc69 <= 4'd4; rc70 <= 3'd7; rc71 <= 3'd3; rc72 <= 3'd5; rc73 <= 4'd4; rc74 <= 3'd7; rc75 <= 3'd3; rc76 <= 3'd7; rc77 <= 3'd3; rc78 <= 4'd9; rc79 <= 3'd2; rc80 <= 3'd5; rc81 <= 4'd4; rc82 <= 3'd7; rc83 <= 3'd3; rc84 <= 3'd7; rc85 <= 3'd3; rc86 <= 4'd9; rc87 <= 3'd2; rc88 <= 3'd7; rc89 <= 3'd3; rc90 <= 4'd9; rc91 <= 3'd2; rc92 <= 4'd9; rc93 <= 3'd2; rc94 <= 4'd11; rc95 <= 2'd1; rc96 <= 3'd5; rc97 <= 4'd4; rc98 <= 3'd7; rc99 <= 3'd3; rc100 <= 3'd7; rc101 <= 3'd3; rc102 <= 4'd9; rc103 <= 3'd2; rc104 <= 3'd7; rc105 <= 3'd3; rc106 <= 4'd9; rc107 <= 3'd2; rc108 <= 4'd9; rc109 <= 3'd2; rc110 <= 4'd11; rc111 <= 2'd1; rc112 <= 3'd7; rc113 <= 3'd3; rc114 <= 4'd9; rc115 <= 3'd2; rc116 <= 4'd9; rc117 <= 3'd2; rc118 <= 4'd11; rc119 <= 2'd1; rc120 <= 4'd9; rc121 <= 3'd2; rc122 <= 4'd11; rc123 <= 2'd1; rc124 <= 4'd11; rc125 <= 2'd1; rc126 <= 4'd13; rc127 <= 1'd0; end
            {4'd10, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd7; rc2 <= 2'd0; rc3 <= 4'd6; rc4 <= 2'd0; rc5 <= 4'd6; rc6 <= 3'd0; rc7 <= 4'd5; rc8 <= 2'd0; rc9 <= 4'd6; rc10 <= 3'd0; rc11 <= 4'd5; rc12 <= 3'd0; rc13 <= 4'd5; rc14 <= 3'd0; rc15 <= 3'd4; rc16 <= 2'd0; rc17 <= 4'd6; rc18 <= 3'd0; rc19 <= 4'd5; rc20 <= 3'd0; rc21 <= 4'd5; rc22 <= 3'd0; rc23 <= 3'd4; rc24 <= 3'd0; rc25 <= 4'd5; rc26 <= 3'd0; rc27 <= 3'd4; rc28 <= 3'd0; rc29 <= 3'd4; rc30 <= 4'd0; rc31 <= 3'd3; rc32 <= 2'd0; rc33 <= 4'd6; rc34 <= 3'd0; rc35 <= 4'd5; rc36 <= 3'd0; rc37 <= 4'd5; rc38 <= 3'd0; rc39 <= 3'd4; rc40 <= 3'd0; rc41 <= 4'd5; rc42 <= 3'd0; rc43 <= 3'd4; rc44 <= 3'd0; rc45 <= 3'd4; rc46 <= 4'd0; rc47 <= 3'd3; rc48 <= 3'd0; rc49 <= 4'd5; rc50 <= 3'd0; rc51 <= 3'd4; rc52 <= 3'd0; rc53 <= 3'd4; rc54 <= 4'd0; rc55 <= 3'd3; rc56 <= 3'd0; rc57 <= 3'd4; rc58 <= 4'd0; rc59 <= 3'd3; rc60 <= 4'd0; rc61 <= 3'd3; rc62 <= 4'd0; rc63 <= 2'd2; rc64 <= 2'd1; rc65 <= 4'd11; rc66 <= 3'd2; rc67 <= 4'd9; rc68 <= 3'd2; rc69 <= 4'd9; rc70 <= 3'd3; rc71 <= 3'd7; rc72 <= 3'd2; rc73 <= 4'd9; rc74 <= 3'd3; rc75 <= 3'd7; rc76 <= 3'd3; rc77 <= 3'd7; rc78 <= 4'd4; rc79 <= 3'd5; rc80 <= 3'd2; rc81 <= 4'd9; rc82 <= 3'd3; rc83 <= 3'd7; rc84 <= 3'd3; rc85 <= 3'd7; rc86 <= 4'd4; rc87 <= 3'd5; rc88 <= 3'd3; rc89 <= 3'd7; rc90 <= 4'd4; rc91 <= 3'd5; rc92 <= 4'd4; rc93 <= 3'd5; rc94 <= 4'd5; rc95 <= 2'd3; rc96 <= 3'd2; rc97 <= 4'd9; rc98 <= 3'd3; rc99 <= 3'd7; rc100 <= 3'd3; rc101 <= 3'd7; rc102 <= 4'd4; rc103 <= 3'd5; rc104 <= 3'd3; rc105 <= 3'd7; rc106 <= 4'd4; rc107 <= 3'd5; rc108 <= 4'd4; rc109 <= 3'd5; rc110 <= 4'd5; rc111 <= 2'd3; rc112 <= 3'd3; rc113 <= 3'd7; rc114 <= 4'd4; rc115 <= 3'd5; rc116 <= 4'd4; rc117 <= 3'd5; rc118 <= 4'd5; rc119 <= 2'd3; rc120 <= 4'd4; rc121 <= 3'd5; rc122 <= 4'd5; rc123 <= 2'd3; rc124 <= 4'd5; rc125 <= 2'd3; rc126 <= 4'd6; rc127 <= 1'd1; end
            {4'd10, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 4'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 4'd0; rc12 <= 3'd3; rc13 <= 4'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 4'd0; rc20 <= 3'd3; rc21 <= 4'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 4'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 3'd0; rc32 <= 2'd2; rc33 <= 4'd0; rc34 <= 3'd3; rc35 <= 4'd0; rc36 <= 3'd3; rc37 <= 4'd0; rc38 <= 3'd4; rc39 <= 3'd0; rc40 <= 3'd3; rc41 <= 4'd0; rc42 <= 3'd4; rc43 <= 3'd0; rc44 <= 3'd4; rc45 <= 3'd0; rc46 <= 4'd5; rc47 <= 3'd0; rc48 <= 3'd3; rc49 <= 4'd0; rc50 <= 3'd4; rc51 <= 3'd0; rc52 <= 3'd4; rc53 <= 3'd0; rc54 <= 4'd5; rc55 <= 3'd0; rc56 <= 3'd4; rc57 <= 3'd0; rc58 <= 4'd5; rc59 <= 3'd0; rc60 <= 4'd5; rc61 <= 3'd0; rc62 <= 4'd6; rc63 <= 2'd0; rc64 <= 2'd3; rc65 <= 4'd5; rc66 <= 3'd5; rc67 <= 4'd4; rc68 <= 3'd5; rc69 <= 4'd4; rc70 <= 3'd7; rc71 <= 3'd3; rc72 <= 3'd5; rc73 <= 4'd4; rc74 <= 3'd7; rc75 <= 3'd3; rc76 <= 3'd7; rc77 <= 3'd3; rc78 <= 4'd9; rc79 <= 3'd2; rc80 <= 3'd5; rc81 <= 4'd4; rc82 <= 3'd7; rc83 <= 3'd3; rc84 <= 3'd7; rc85 <= 3'd3; rc86 <= 4'd9; rc87 <= 3'd2; rc88 <= 3'd7; rc89 <= 3'd3; rc90 <= 4'd9; rc91 <= 3'd2; rc92 <= 4'd9; rc93 <= 3'd2; rc94 <= 4'd11; rc95 <= 2'd1; rc96 <= 3'd5; rc97 <= 4'd4; rc98 <= 3'd7; rc99 <= 3'd3; rc100 <= 3'd7; rc101 <= 3'd3; rc102 <= 4'd9; rc103 <= 3'd2; rc104 <= 3'd7; rc105 <= 3'd3; rc106 <= 4'd9; rc107 <= 3'd2; rc108 <= 4'd9; rc109 <= 3'd2; rc110 <= 4'd11; rc111 <= 2'd1; rc112 <= 3'd7; rc113 <= 3'd3; rc114 <= 4'd9; rc115 <= 3'd2; rc116 <= 4'd9; rc117 <= 3'd2; rc118 <= 4'd11; rc119 <= 2'd1; rc120 <= 4'd9; rc121 <= 3'd2; rc122 <= 4'd11; rc123 <= 2'd1; rc124 <= 4'd11; rc125 <= 2'd1; rc126 <= 4'd13; rc127 <= 1'd0; end
            {4'd11, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd7; rc2 <= 2'd0; rc3 <= 4'd6; rc4 <= 2'd0; rc5 <= 4'd6; rc6 <= 3'd0; rc7 <= 4'd5; rc8 <= 2'd0; rc9 <= 4'd6; rc10 <= 3'd0; rc11 <= 4'd5; rc12 <= 3'd0; rc13 <= 4'd5; rc14 <= 3'd0; rc15 <= 3'd4; rc16 <= 2'd0; rc17 <= 4'd6; rc18 <= 3'd0; rc19 <= 4'd5; rc20 <= 3'd0; rc21 <= 4'd5; rc22 <= 3'd0; rc23 <= 3'd4; rc24 <= 3'd0; rc25 <= 4'd5; rc26 <= 3'd0; rc27 <= 3'd4; rc28 <= 3'd0; rc29 <= 3'd4; rc30 <= 4'd0; rc31 <= 3'd3; rc32 <= 2'd0; rc33 <= 4'd6; rc34 <= 3'd0; rc35 <= 4'd5; rc36 <= 3'd0; rc37 <= 4'd5; rc38 <= 3'd0; rc39 <= 3'd4; rc40 <= 3'd0; rc41 <= 4'd5; rc42 <= 3'd0; rc43 <= 3'd4; rc44 <= 3'd0; rc45 <= 3'd4; rc46 <= 4'd0; rc47 <= 3'd3; rc48 <= 3'd0; rc49 <= 4'd5; rc50 <= 3'd0; rc51 <= 3'd4; rc52 <= 3'd0; rc53 <= 3'd4; rc54 <= 4'd0; rc55 <= 3'd3; rc56 <= 3'd0; rc57 <= 3'd4; rc58 <= 4'd0; rc59 <= 3'd3; rc60 <= 4'd0; rc61 <= 3'd3; rc62 <= 4'd0; rc63 <= 2'd2; rc64 <= 2'd1; rc65 <= 4'd11; rc66 <= 3'd2; rc67 <= 4'd9; rc68 <= 3'd2; rc69 <= 4'd9; rc70 <= 3'd3; rc71 <= 3'd7; rc72 <= 3'd2; rc73 <= 4'd9; rc74 <= 3'd3; rc75 <= 3'd7; rc76 <= 3'd3; rc77 <= 3'd7; rc78 <= 4'd4; rc79 <= 3'd5; rc80 <= 3'd2; rc81 <= 4'd9; rc82 <= 3'd3; rc83 <= 3'd7; rc84 <= 3'd3; rc85 <= 3'd7; rc86 <= 4'd4; rc87 <= 3'd5; rc88 <= 3'd3; rc89 <= 3'd7; rc90 <= 4'd4; rc91 <= 3'd5; rc92 <= 4'd4; rc93 <= 3'd5; rc94 <= 4'd5; rc95 <= 2'd3; rc96 <= 3'd2; rc97 <= 4'd9; rc98 <= 3'd3; rc99 <= 3'd7; rc100 <= 3'd3; rc101 <= 3'd7; rc102 <= 4'd4; rc103 <= 3'd5; rc104 <= 3'd3; rc105 <= 3'd7; rc106 <= 4'd4; rc107 <= 3'd5; rc108 <= 4'd4; rc109 <= 3'd5; rc110 <= 4'd5; rc111 <= 2'd3; rc112 <= 3'd3; rc113 <= 3'd7; rc114 <= 4'd4; rc115 <= 3'd5; rc116 <= 4'd4; rc117 <= 3'd5; rc118 <= 4'd5; rc119 <= 2'd3; rc120 <= 4'd4; rc121 <= 3'd5; rc122 <= 4'd5; rc123 <= 2'd3; rc124 <= 4'd5; rc125 <= 2'd3; rc126 <= 4'd6; rc127 <= 1'd1; end
            {4'd11, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 4'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 4'd0; rc12 <= 3'd3; rc13 <= 4'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 4'd0; rc20 <= 3'd3; rc21 <= 4'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 4'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 3'd0; rc32 <= 2'd2; rc33 <= 4'd0; rc34 <= 3'd3; rc35 <= 4'd0; rc36 <= 3'd3; rc37 <= 4'd0; rc38 <= 3'd4; rc39 <= 3'd0; rc40 <= 3'd3; rc41 <= 4'd0; rc42 <= 3'd4; rc43 <= 3'd0; rc44 <= 3'd4; rc45 <= 3'd0; rc46 <= 4'd5; rc47 <= 3'd0; rc48 <= 3'd3; rc49 <= 4'd0; rc50 <= 3'd4; rc51 <= 3'd0; rc52 <= 3'd4; rc53 <= 3'd0; rc54 <= 4'd5; rc55 <= 3'd0; rc56 <= 3'd4; rc57 <= 3'd0; rc58 <= 4'd5; rc59 <= 3'd0; rc60 <= 4'd5; rc61 <= 3'd0; rc62 <= 4'd6; rc63 <= 2'd0; rc64 <= 2'd3; rc65 <= 4'd5; rc66 <= 3'd5; rc67 <= 4'd4; rc68 <= 3'd5; rc69 <= 4'd4; rc70 <= 3'd7; rc71 <= 3'd3; rc72 <= 3'd5; rc73 <= 4'd4; rc74 <= 3'd7; rc75 <= 3'd3; rc76 <= 3'd7; rc77 <= 3'd3; rc78 <= 4'd9; rc79 <= 3'd2; rc80 <= 3'd5; rc81 <= 4'd4; rc82 <= 3'd7; rc83 <= 3'd3; rc84 <= 3'd7; rc85 <= 3'd3; rc86 <= 4'd9; rc87 <= 3'd2; rc88 <= 3'd7; rc89 <= 3'd3; rc90 <= 4'd9; rc91 <= 3'd2; rc92 <= 4'd9; rc93 <= 3'd2; rc94 <= 4'd11; rc95 <= 2'd1; rc96 <= 3'd5; rc97 <= 4'd4; rc98 <= 3'd7; rc99 <= 3'd3; rc100 <= 3'd7; rc101 <= 3'd3; rc102 <= 4'd9; rc103 <= 3'd2; rc104 <= 3'd7; rc105 <= 3'd3; rc106 <= 4'd9; rc107 <= 3'd2; rc108 <= 4'd9; rc109 <= 3'd2; rc110 <= 4'd11; rc111 <= 2'd1; rc112 <= 3'd7; rc113 <= 3'd3; rc114 <= 4'd9; rc115 <= 3'd2; rc116 <= 4'd9; rc117 <= 3'd2; rc118 <= 4'd11; rc119 <= 2'd1; rc120 <= 4'd9; rc121 <= 3'd2; rc122 <= 4'd11; rc123 <= 2'd1; rc124 <= 4'd11; rc125 <= 2'd1; rc126 <= 4'd13; rc127 <= 1'd0; end
            {4'd12, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd7; rc2 <= 2'd0; rc3 <= 4'd6; rc4 <= 2'd0; rc5 <= 4'd6; rc6 <= 3'd0; rc7 <= 4'd5; rc8 <= 2'd0; rc9 <= 4'd6; rc10 <= 3'd0; rc11 <= 4'd5; rc12 <= 3'd0; rc13 <= 4'd5; rc14 <= 3'd0; rc15 <= 3'd4; rc16 <= 2'd0; rc17 <= 4'd6; rc18 <= 3'd0; rc19 <= 4'd5; rc20 <= 3'd0; rc21 <= 4'd5; rc22 <= 3'd0; rc23 <= 3'd4; rc24 <= 3'd0; rc25 <= 4'd5; rc26 <= 3'd0; rc27 <= 3'd4; rc28 <= 3'd0; rc29 <= 3'd4; rc30 <= 4'd0; rc31 <= 3'd3; rc32 <= 2'd0; rc33 <= 4'd6; rc34 <= 3'd0; rc35 <= 4'd5; rc36 <= 3'd0; rc37 <= 4'd5; rc38 <= 3'd0; rc39 <= 3'd4; rc40 <= 3'd0; rc41 <= 4'd5; rc42 <= 3'd0; rc43 <= 3'd4; rc44 <= 3'd0; rc45 <= 3'd4; rc46 <= 4'd0; rc47 <= 3'd3; rc48 <= 3'd0; rc49 <= 4'd5; rc50 <= 3'd0; rc51 <= 3'd4; rc52 <= 3'd0; rc53 <= 3'd4; rc54 <= 4'd0; rc55 <= 3'd3; rc56 <= 3'd0; rc57 <= 3'd4; rc58 <= 4'd0; rc59 <= 3'd3; rc60 <= 4'd0; rc61 <= 3'd3; rc62 <= 4'd0; rc63 <= 2'd2; rc64 <= 2'd1; rc65 <= 4'd11; rc66 <= 3'd2; rc67 <= 4'd9; rc68 <= 3'd2; rc69 <= 4'd9; rc70 <= 3'd3; rc71 <= 3'd7; rc72 <= 3'd2; rc73 <= 4'd9; rc74 <= 3'd3; rc75 <= 3'd7; rc76 <= 3'd3; rc77 <= 3'd7; rc78 <= 4'd4; rc79 <= 3'd5; rc80 <= 3'd2; rc81 <= 4'd9; rc82 <= 3'd3; rc83 <= 3'd7; rc84 <= 3'd3; rc85 <= 3'd7; rc86 <= 4'd4; rc87 <= 3'd5; rc88 <= 3'd3; rc89 <= 3'd7; rc90 <= 4'd4; rc91 <= 3'd5; rc92 <= 4'd4; rc93 <= 3'd5; rc94 <= 4'd5; rc95 <= 2'd3; rc96 <= 3'd2; rc97 <= 4'd9; rc98 <= 3'd3; rc99 <= 3'd7; rc100 <= 3'd3; rc101 <= 3'd7; rc102 <= 4'd4; rc103 <= 3'd5; rc104 <= 3'd3; rc105 <= 3'd7; rc106 <= 4'd4; rc107 <= 3'd5; rc108 <= 4'd4; rc109 <= 3'd5; rc110 <= 4'd5; rc111 <= 2'd3; rc112 <= 3'd3; rc113 <= 3'd7; rc114 <= 4'd4; rc115 <= 3'd5; rc116 <= 4'd4; rc117 <= 3'd5; rc118 <= 4'd5; rc119 <= 2'd3; rc120 <= 4'd4; rc121 <= 3'd5; rc122 <= 4'd5; rc123 <= 2'd3; rc124 <= 4'd5; rc125 <= 2'd3; rc126 <= 4'd6; rc127 <= 1'd1; end
            {4'd12, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 4'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 4'd0; rc12 <= 3'd3; rc13 <= 4'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 4'd0; rc20 <= 3'd3; rc21 <= 4'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 4'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 3'd0; rc32 <= 2'd2; rc33 <= 4'd0; rc34 <= 3'd3; rc35 <= 4'd0; rc36 <= 3'd3; rc37 <= 4'd0; rc38 <= 3'd4; rc39 <= 3'd0; rc40 <= 3'd3; rc41 <= 4'd0; rc42 <= 3'd4; rc43 <= 3'd0; rc44 <= 3'd4; rc45 <= 3'd0; rc46 <= 4'd5; rc47 <= 3'd0; rc48 <= 3'd3; rc49 <= 4'd0; rc50 <= 3'd4; rc51 <= 3'd0; rc52 <= 3'd4; rc53 <= 3'd0; rc54 <= 4'd5; rc55 <= 3'd0; rc56 <= 3'd4; rc57 <= 3'd0; rc58 <= 4'd5; rc59 <= 3'd0; rc60 <= 4'd5; rc61 <= 3'd0; rc62 <= 4'd6; rc63 <= 2'd0; rc64 <= 2'd3; rc65 <= 4'd5; rc66 <= 3'd5; rc67 <= 4'd4; rc68 <= 3'd5; rc69 <= 4'd4; rc70 <= 3'd7; rc71 <= 3'd3; rc72 <= 3'd5; rc73 <= 4'd4; rc74 <= 3'd7; rc75 <= 3'd3; rc76 <= 3'd7; rc77 <= 3'd3; rc78 <= 4'd9; rc79 <= 3'd2; rc80 <= 3'd5; rc81 <= 4'd4; rc82 <= 3'd7; rc83 <= 3'd3; rc84 <= 3'd7; rc85 <= 3'd3; rc86 <= 4'd9; rc87 <= 3'd2; rc88 <= 3'd7; rc89 <= 3'd3; rc90 <= 4'd9; rc91 <= 3'd2; rc92 <= 4'd9; rc93 <= 3'd2; rc94 <= 4'd11; rc95 <= 2'd1; rc96 <= 3'd5; rc97 <= 4'd4; rc98 <= 3'd7; rc99 <= 3'd3; rc100 <= 3'd7; rc101 <= 3'd3; rc102 <= 4'd9; rc103 <= 3'd2; rc104 <= 3'd7; rc105 <= 3'd3; rc106 <= 4'd9; rc107 <= 3'd2; rc108 <= 4'd9; rc109 <= 3'd2; rc110 <= 4'd11; rc111 <= 2'd1; rc112 <= 3'd7; rc113 <= 3'd3; rc114 <= 4'd9; rc115 <= 3'd2; rc116 <= 4'd9; rc117 <= 3'd2; rc118 <= 4'd11; rc119 <= 2'd1; rc120 <= 4'd9; rc121 <= 3'd2; rc122 <= 4'd11; rc123 <= 2'd1; rc124 <= 4'd11; rc125 <= 2'd1; rc126 <= 4'd13; rc127 <= 1'd0; end
            {4'd13, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd7; rc2 <= 2'd0; rc3 <= 4'd6; rc4 <= 2'd0; rc5 <= 4'd6; rc6 <= 3'd0; rc7 <= 4'd5; rc8 <= 2'd0; rc9 <= 4'd6; rc10 <= 3'd0; rc11 <= 4'd5; rc12 <= 3'd0; rc13 <= 4'd5; rc14 <= 3'd0; rc15 <= 3'd4; rc16 <= 2'd0; rc17 <= 4'd6; rc18 <= 3'd0; rc19 <= 4'd5; rc20 <= 3'd0; rc21 <= 4'd5; rc22 <= 3'd0; rc23 <= 3'd4; rc24 <= 3'd0; rc25 <= 4'd5; rc26 <= 3'd0; rc27 <= 3'd4; rc28 <= 3'd0; rc29 <= 3'd4; rc30 <= 4'd0; rc31 <= 3'd3; rc32 <= 2'd0; rc33 <= 4'd6; rc34 <= 3'd0; rc35 <= 4'd5; rc36 <= 3'd0; rc37 <= 4'd5; rc38 <= 3'd0; rc39 <= 3'd4; rc40 <= 3'd0; rc41 <= 4'd5; rc42 <= 3'd0; rc43 <= 3'd4; rc44 <= 3'd0; rc45 <= 3'd4; rc46 <= 4'd0; rc47 <= 3'd3; rc48 <= 3'd0; rc49 <= 4'd5; rc50 <= 3'd0; rc51 <= 3'd4; rc52 <= 3'd0; rc53 <= 3'd4; rc54 <= 4'd0; rc55 <= 3'd3; rc56 <= 3'd0; rc57 <= 3'd4; rc58 <= 4'd0; rc59 <= 3'd3; rc60 <= 4'd0; rc61 <= 3'd3; rc62 <= 4'd0; rc63 <= 2'd2; rc64 <= 2'd1; rc65 <= 4'd11; rc66 <= 3'd2; rc67 <= 4'd9; rc68 <= 3'd2; rc69 <= 4'd9; rc70 <= 3'd3; rc71 <= 3'd7; rc72 <= 3'd2; rc73 <= 4'd9; rc74 <= 3'd3; rc75 <= 3'd7; rc76 <= 3'd3; rc77 <= 3'd7; rc78 <= 4'd4; rc79 <= 3'd5; rc80 <= 3'd2; rc81 <= 4'd9; rc82 <= 3'd3; rc83 <= 3'd7; rc84 <= 3'd3; rc85 <= 3'd7; rc86 <= 4'd4; rc87 <= 3'd5; rc88 <= 3'd3; rc89 <= 3'd7; rc90 <= 4'd4; rc91 <= 3'd5; rc92 <= 4'd4; rc93 <= 3'd5; rc94 <= 4'd5; rc95 <= 2'd3; rc96 <= 3'd2; rc97 <= 4'd9; rc98 <= 3'd3; rc99 <= 3'd7; rc100 <= 3'd3; rc101 <= 3'd7; rc102 <= 4'd4; rc103 <= 3'd5; rc104 <= 3'd3; rc105 <= 3'd7; rc106 <= 4'd4; rc107 <= 3'd5; rc108 <= 4'd4; rc109 <= 3'd5; rc110 <= 4'd5; rc111 <= 2'd3; rc112 <= 3'd3; rc113 <= 3'd7; rc114 <= 4'd4; rc115 <= 3'd5; rc116 <= 4'd4; rc117 <= 3'd5; rc118 <= 4'd5; rc119 <= 2'd3; rc120 <= 4'd4; rc121 <= 3'd5; rc122 <= 4'd5; rc123 <= 2'd3; rc124 <= 4'd5; rc125 <= 2'd3; rc126 <= 4'd6; rc127 <= 1'd1; end
            {4'd13, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 4'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 4'd0; rc12 <= 3'd3; rc13 <= 4'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 4'd0; rc20 <= 3'd3; rc21 <= 4'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 4'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 3'd0; rc32 <= 2'd2; rc33 <= 4'd0; rc34 <= 3'd3; rc35 <= 4'd0; rc36 <= 3'd3; rc37 <= 4'd0; rc38 <= 3'd4; rc39 <= 3'd0; rc40 <= 3'd3; rc41 <= 4'd0; rc42 <= 3'd4; rc43 <= 3'd0; rc44 <= 3'd4; rc45 <= 3'd0; rc46 <= 4'd5; rc47 <= 3'd0; rc48 <= 3'd3; rc49 <= 4'd0; rc50 <= 3'd4; rc51 <= 3'd0; rc52 <= 3'd4; rc53 <= 3'd0; rc54 <= 4'd5; rc55 <= 3'd0; rc56 <= 3'd4; rc57 <= 3'd0; rc58 <= 4'd5; rc59 <= 3'd0; rc60 <= 4'd5; rc61 <= 3'd0; rc62 <= 4'd6; rc63 <= 2'd0; rc64 <= 2'd3; rc65 <= 4'd5; rc66 <= 3'd5; rc67 <= 4'd4; rc68 <= 3'd5; rc69 <= 4'd4; rc70 <= 3'd7; rc71 <= 3'd3; rc72 <= 3'd5; rc73 <= 4'd4; rc74 <= 3'd7; rc75 <= 3'd3; rc76 <= 3'd7; rc77 <= 3'd3; rc78 <= 4'd9; rc79 <= 3'd2; rc80 <= 3'd5; rc81 <= 4'd4; rc82 <= 3'd7; rc83 <= 3'd3; rc84 <= 3'd7; rc85 <= 3'd3; rc86 <= 4'd9; rc87 <= 3'd2; rc88 <= 3'd7; rc89 <= 3'd3; rc90 <= 4'd9; rc91 <= 3'd2; rc92 <= 4'd9; rc93 <= 3'd2; rc94 <= 4'd11; rc95 <= 2'd1; rc96 <= 3'd5; rc97 <= 4'd4; rc98 <= 3'd7; rc99 <= 3'd3; rc100 <= 3'd7; rc101 <= 3'd3; rc102 <= 4'd9; rc103 <= 3'd2; rc104 <= 3'd7; rc105 <= 3'd3; rc106 <= 4'd9; rc107 <= 3'd2; rc108 <= 4'd9; rc109 <= 3'd2; rc110 <= 4'd11; rc111 <= 2'd1; rc112 <= 3'd7; rc113 <= 3'd3; rc114 <= 4'd9; rc115 <= 3'd2; rc116 <= 4'd9; rc117 <= 3'd2; rc118 <= 4'd11; rc119 <= 2'd1; rc120 <= 4'd9; rc121 <= 3'd2; rc122 <= 4'd11; rc123 <= 2'd1; rc124 <= 4'd11; rc125 <= 2'd1; rc126 <= 4'd13; rc127 <= 1'd0; end
            {4'd14, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd7; rc2 <= 2'd0; rc3 <= 4'd6; rc4 <= 2'd0; rc5 <= 4'd6; rc6 <= 3'd0; rc7 <= 4'd5; rc8 <= 2'd0; rc9 <= 4'd6; rc10 <= 3'd0; rc11 <= 4'd5; rc12 <= 3'd0; rc13 <= 4'd5; rc14 <= 3'd0; rc15 <= 3'd4; rc16 <= 2'd0; rc17 <= 4'd6; rc18 <= 3'd0; rc19 <= 4'd5; rc20 <= 3'd0; rc21 <= 4'd5; rc22 <= 3'd0; rc23 <= 3'd4; rc24 <= 3'd0; rc25 <= 4'd5; rc26 <= 3'd0; rc27 <= 3'd4; rc28 <= 3'd0; rc29 <= 3'd4; rc30 <= 4'd0; rc31 <= 3'd3; rc32 <= 2'd0; rc33 <= 4'd6; rc34 <= 3'd0; rc35 <= 4'd5; rc36 <= 3'd0; rc37 <= 4'd5; rc38 <= 3'd0; rc39 <= 3'd4; rc40 <= 3'd0; rc41 <= 4'd5; rc42 <= 3'd0; rc43 <= 3'd4; rc44 <= 3'd0; rc45 <= 3'd4; rc46 <= 4'd0; rc47 <= 3'd3; rc48 <= 3'd0; rc49 <= 4'd5; rc50 <= 3'd0; rc51 <= 3'd4; rc52 <= 3'd0; rc53 <= 3'd4; rc54 <= 4'd0; rc55 <= 3'd3; rc56 <= 3'd0; rc57 <= 3'd4; rc58 <= 4'd0; rc59 <= 3'd3; rc60 <= 4'd0; rc61 <= 3'd3; rc62 <= 4'd0; rc63 <= 2'd2; rc64 <= 2'd1; rc65 <= 4'd11; rc66 <= 3'd2; rc67 <= 4'd9; rc68 <= 3'd2; rc69 <= 4'd9; rc70 <= 3'd3; rc71 <= 3'd7; rc72 <= 3'd2; rc73 <= 4'd9; rc74 <= 3'd3; rc75 <= 3'd7; rc76 <= 3'd3; rc77 <= 3'd7; rc78 <= 4'd4; rc79 <= 3'd5; rc80 <= 3'd2; rc81 <= 4'd9; rc82 <= 3'd3; rc83 <= 3'd7; rc84 <= 3'd3; rc85 <= 3'd7; rc86 <= 4'd4; rc87 <= 3'd5; rc88 <= 3'd3; rc89 <= 3'd7; rc90 <= 4'd4; rc91 <= 3'd5; rc92 <= 4'd4; rc93 <= 3'd5; rc94 <= 4'd5; rc95 <= 2'd3; rc96 <= 3'd2; rc97 <= 4'd9; rc98 <= 3'd3; rc99 <= 3'd7; rc100 <= 3'd3; rc101 <= 3'd7; rc102 <= 4'd4; rc103 <= 3'd5; rc104 <= 3'd3; rc105 <= 3'd7; rc106 <= 4'd4; rc107 <= 3'd5; rc108 <= 4'd4; rc109 <= 3'd5; rc110 <= 4'd5; rc111 <= 2'd3; rc112 <= 3'd3; rc113 <= 3'd7; rc114 <= 4'd4; rc115 <= 3'd5; rc116 <= 4'd4; rc117 <= 3'd5; rc118 <= 4'd5; rc119 <= 2'd3; rc120 <= 4'd4; rc121 <= 3'd5; rc122 <= 4'd5; rc123 <= 2'd3; rc124 <= 4'd5; rc125 <= 2'd3; rc126 <= 4'd6; rc127 <= 1'd1; end
            {4'd14, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 4'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 4'd0; rc12 <= 3'd3; rc13 <= 4'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 4'd0; rc20 <= 3'd3; rc21 <= 4'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 4'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 3'd0; rc32 <= 2'd2; rc33 <= 4'd0; rc34 <= 3'd3; rc35 <= 4'd0; rc36 <= 3'd3; rc37 <= 4'd0; rc38 <= 3'd4; rc39 <= 3'd0; rc40 <= 3'd3; rc41 <= 4'd0; rc42 <= 3'd4; rc43 <= 3'd0; rc44 <= 3'd4; rc45 <= 3'd0; rc46 <= 4'd5; rc47 <= 3'd0; rc48 <= 3'd3; rc49 <= 4'd0; rc50 <= 3'd4; rc51 <= 3'd0; rc52 <= 3'd4; rc53 <= 3'd0; rc54 <= 4'd5; rc55 <= 3'd0; rc56 <= 3'd4; rc57 <= 3'd0; rc58 <= 4'd5; rc59 <= 3'd0; rc60 <= 4'd5; rc61 <= 3'd0; rc62 <= 4'd6; rc63 <= 2'd0; rc64 <= 2'd3; rc65 <= 4'd5; rc66 <= 3'd5; rc67 <= 4'd4; rc68 <= 3'd5; rc69 <= 4'd4; rc70 <= 3'd7; rc71 <= 3'd3; rc72 <= 3'd5; rc73 <= 4'd4; rc74 <= 3'd7; rc75 <= 3'd3; rc76 <= 3'd7; rc77 <= 3'd3; rc78 <= 4'd9; rc79 <= 3'd2; rc80 <= 3'd5; rc81 <= 4'd4; rc82 <= 3'd7; rc83 <= 3'd3; rc84 <= 3'd7; rc85 <= 3'd3; rc86 <= 4'd9; rc87 <= 3'd2; rc88 <= 3'd7; rc89 <= 3'd3; rc90 <= 4'd9; rc91 <= 3'd2; rc92 <= 4'd9; rc93 <= 3'd2; rc94 <= 4'd11; rc95 <= 2'd1; rc96 <= 3'd5; rc97 <= 4'd4; rc98 <= 3'd7; rc99 <= 3'd3; rc100 <= 3'd7; rc101 <= 3'd3; rc102 <= 4'd9; rc103 <= 3'd2; rc104 <= 3'd7; rc105 <= 3'd3; rc106 <= 4'd9; rc107 <= 3'd2; rc108 <= 4'd9; rc109 <= 3'd2; rc110 <= 4'd11; rc111 <= 2'd1; rc112 <= 3'd7; rc113 <= 3'd3; rc114 <= 4'd9; rc115 <= 3'd2; rc116 <= 4'd9; rc117 <= 3'd2; rc118 <= 4'd11; rc119 <= 2'd1; rc120 <= 4'd9; rc121 <= 3'd2; rc122 <= 4'd11; rc123 <= 2'd1; rc124 <= 4'd11; rc125 <= 2'd1; rc126 <= 4'd13; rc127 <= 1'd0; end
            {4'd15, 1'b0}: begin rc0 <= 1'd0; rc1 <= 4'd7; rc2 <= 2'd0; rc3 <= 4'd6; rc4 <= 2'd0; rc5 <= 4'd6; rc6 <= 3'd0; rc7 <= 4'd5; rc8 <= 2'd0; rc9 <= 4'd6; rc10 <= 3'd0; rc11 <= 4'd5; rc12 <= 3'd0; rc13 <= 4'd5; rc14 <= 3'd0; rc15 <= 3'd4; rc16 <= 2'd0; rc17 <= 4'd6; rc18 <= 3'd0; rc19 <= 4'd5; rc20 <= 3'd0; rc21 <= 4'd5; rc22 <= 3'd0; rc23 <= 3'd4; rc24 <= 3'd0; rc25 <= 4'd5; rc26 <= 3'd0; rc27 <= 3'd4; rc28 <= 3'd0; rc29 <= 3'd4; rc30 <= 4'd0; rc31 <= 3'd3; rc32 <= 2'd0; rc33 <= 4'd6; rc34 <= 3'd0; rc35 <= 4'd5; rc36 <= 3'd0; rc37 <= 4'd5; rc38 <= 3'd0; rc39 <= 3'd4; rc40 <= 3'd0; rc41 <= 4'd5; rc42 <= 3'd0; rc43 <= 3'd4; rc44 <= 3'd0; rc45 <= 3'd4; rc46 <= 4'd0; rc47 <= 3'd3; rc48 <= 3'd0; rc49 <= 4'd5; rc50 <= 3'd0; rc51 <= 3'd4; rc52 <= 3'd0; rc53 <= 3'd4; rc54 <= 4'd0; rc55 <= 3'd3; rc56 <= 3'd0; rc57 <= 3'd4; rc58 <= 4'd0; rc59 <= 3'd3; rc60 <= 4'd0; rc61 <= 3'd3; rc62 <= 4'd0; rc63 <= 2'd2; rc64 <= 2'd1; rc65 <= 4'd11; rc66 <= 3'd2; rc67 <= 4'd9; rc68 <= 3'd2; rc69 <= 4'd9; rc70 <= 3'd3; rc71 <= 3'd7; rc72 <= 3'd2; rc73 <= 4'd9; rc74 <= 3'd3; rc75 <= 3'd7; rc76 <= 3'd3; rc77 <= 3'd7; rc78 <= 4'd4; rc79 <= 3'd5; rc80 <= 3'd2; rc81 <= 4'd9; rc82 <= 3'd3; rc83 <= 3'd7; rc84 <= 3'd3; rc85 <= 3'd7; rc86 <= 4'd4; rc87 <= 3'd5; rc88 <= 3'd3; rc89 <= 3'd7; rc90 <= 4'd4; rc91 <= 3'd5; rc92 <= 4'd4; rc93 <= 3'd5; rc94 <= 4'd5; rc95 <= 2'd3; rc96 <= 3'd2; rc97 <= 4'd9; rc98 <= 3'd3; rc99 <= 3'd7; rc100 <= 3'd3; rc101 <= 3'd7; rc102 <= 4'd4; rc103 <= 3'd5; rc104 <= 3'd3; rc105 <= 3'd7; rc106 <= 4'd4; rc107 <= 3'd5; rc108 <= 4'd4; rc109 <= 3'd5; rc110 <= 4'd5; rc111 <= 2'd3; rc112 <= 3'd3; rc113 <= 3'd7; rc114 <= 4'd4; rc115 <= 3'd5; rc116 <= 4'd4; rc117 <= 3'd5; rc118 <= 4'd5; rc119 <= 2'd3; rc120 <= 4'd4; rc121 <= 3'd5; rc122 <= 4'd5; rc123 <= 2'd3; rc124 <= 4'd5; rc125 <= 2'd3; rc126 <= 4'd6; rc127 <= 1'd1; end
            {4'd15, 1'b1}: begin rc0 <= 1'd1; rc1 <= 4'd0; rc2 <= 2'd2; rc3 <= 4'd0; rc4 <= 2'd2; rc5 <= 4'd0; rc6 <= 3'd3; rc7 <= 4'd0; rc8 <= 2'd2; rc9 <= 4'd0; rc10 <= 3'd3; rc11 <= 4'd0; rc12 <= 3'd3; rc13 <= 4'd0; rc14 <= 3'd4; rc15 <= 3'd0; rc16 <= 2'd2; rc17 <= 4'd0; rc18 <= 3'd3; rc19 <= 4'd0; rc20 <= 3'd3; rc21 <= 4'd0; rc22 <= 3'd4; rc23 <= 3'd0; rc24 <= 3'd3; rc25 <= 4'd0; rc26 <= 3'd4; rc27 <= 3'd0; rc28 <= 3'd4; rc29 <= 3'd0; rc30 <= 4'd5; rc31 <= 3'd0; rc32 <= 2'd2; rc33 <= 4'd0; rc34 <= 3'd3; rc35 <= 4'd0; rc36 <= 3'd3; rc37 <= 4'd0; rc38 <= 3'd4; rc39 <= 3'd0; rc40 <= 3'd3; rc41 <= 4'd0; rc42 <= 3'd4; rc43 <= 3'd0; rc44 <= 3'd4; rc45 <= 3'd0; rc46 <= 4'd5; rc47 <= 3'd0; rc48 <= 3'd3; rc49 <= 4'd0; rc50 <= 3'd4; rc51 <= 3'd0; rc52 <= 3'd4; rc53 <= 3'd0; rc54 <= 4'd5; rc55 <= 3'd0; rc56 <= 3'd4; rc57 <= 3'd0; rc58 <= 4'd5; rc59 <= 3'd0; rc60 <= 4'd5; rc61 <= 3'd0; rc62 <= 4'd6; rc63 <= 2'd0; rc64 <= 2'd3; rc65 <= 4'd5; rc66 <= 3'd5; rc67 <= 4'd4; rc68 <= 3'd5; rc69 <= 4'd4; rc70 <= 3'd7; rc71 <= 3'd3; rc72 <= 3'd5; rc73 <= 4'd4; rc74 <= 3'd7; rc75 <= 3'd3; rc76 <= 3'd7; rc77 <= 3'd3; rc78 <= 4'd9; rc79 <= 3'd2; rc80 <= 3'd5; rc81 <= 4'd4; rc82 <= 3'd7; rc83 <= 3'd3; rc84 <= 3'd7; rc85 <= 3'd3; rc86 <= 4'd9; rc87 <= 3'd2; rc88 <= 3'd7; rc89 <= 3'd3; rc90 <= 4'd9; rc91 <= 3'd2; rc92 <= 4'd9; rc93 <= 3'd2; rc94 <= 4'd11; rc95 <= 2'd1; rc96 <= 3'd5; rc97 <= 4'd4; rc98 <= 3'd7; rc99 <= 3'd3; rc100 <= 3'd7; rc101 <= 3'd3; rc102 <= 4'd9; rc103 <= 3'd2; rc104 <= 3'd7; rc105 <= 3'd3; rc106 <= 4'd9; rc107 <= 3'd2; rc108 <= 4'd9; rc109 <= 3'd2; rc110 <= 4'd11; rc111 <= 2'd1; rc112 <= 3'd7; rc113 <= 3'd3; rc114 <= 4'd9; rc115 <= 3'd2; rc116 <= 4'd9; rc117 <= 3'd2; rc118 <= 4'd11; rc119 <= 2'd1; rc120 <= 4'd9; rc121 <= 3'd2; rc122 <= 4'd11; rc123 <= 2'd1; rc124 <= 4'd11; rc125 <= 2'd1; rc126 <= 4'd13; rc127 <= 1'd0; end
            default: ;
        endcase
    end
    always_ff @(posedge clk) begin
        case ({wk_s, wk_f})
            {4'd0, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd0; wc2 <= 3'd1; wc3 <= 3'd0; wc4 <= 3'd1; wc5 <= 4'd1; wc6 <= 3'd1; wc7 <= 3'd0; wc8 <= 3'd1; wc9 <= 4'd1; wc10 <= 4'd2; wc11 <= 4'd1; wc12 <= 3'd1; wc13 <= 4'd1; wc14 <= 3'd1; wc15 <= 3'd0; wc16 <= 3'd1; wc17 <= 4'd1; wc18 <= 4'd2; wc19 <= 4'd1; wc20 <= 4'd2; wc21 <= 4'd2; wc22 <= 4'd2; wc23 <= 4'd1; wc24 <= 3'd1; wc25 <= 4'd1; wc26 <= 4'd2; wc27 <= 4'd1; wc28 <= 3'd1; wc29 <= 4'd1; wc30 <= 3'd1; wc31 <= 3'd0; wc32 <= 3'd1; wc33 <= 3'd1; wc34 <= 4'd2; wc35 <= 3'd1; wc36 <= 4'd2; wc37 <= 4'd2; wc38 <= 4'd2; wc39 <= 3'd1; wc40 <= 4'd2; wc41 <= 4'd2; wc42 <= 4'd3; wc43 <= 4'd2; wc44 <= 4'd2; wc45 <= 4'd2; wc46 <= 4'd2; wc47 <= 3'd1; wc48 <= 3'd1; wc49 <= 3'd1; wc50 <= 4'd2; wc51 <= 3'd1; wc52 <= 4'd2; wc53 <= 4'd2; wc54 <= 4'd2; wc55 <= 3'd1; wc56 <= 3'd1; wc57 <= 3'd1; wc58 <= 4'd2; wc59 <= 3'd1; wc60 <= 3'd1; wc61 <= 3'd1; wc62 <= 3'd1; wc63 <= 2'd0; wc64 <= 2'd2; wc65 <= 3'd3; wc66 <= 3'd5; wc67 <= 3'd3; wc68 <= 3'd5; wc69 <= 4'd6; wc70 <= 3'd5; wc71 <= 3'd3; wc72 <= 3'd5; wc73 <= 4'd6; wc74 <= 4'd8; wc75 <= 4'd6; wc76 <= 3'd5; wc77 <= 4'd6; wc78 <= 3'd5; wc79 <= 3'd3; wc80 <= 3'd5; wc81 <= 4'd6; wc82 <= 4'd8; wc83 <= 4'd6; wc84 <= 4'd8; wc85 <= 4'd9; wc86 <= 4'd8; wc87 <= 4'd6; wc88 <= 3'd5; wc89 <= 4'd6; wc90 <= 4'd8; wc91 <= 4'd6; wc92 <= 3'd5; wc93 <= 4'd6; wc94 <= 3'd5; wc95 <= 3'd3; wc96 <= 3'd4; wc97 <= 3'd5; wc98 <= 4'd7; wc99 <= 3'd5; wc100 <= 4'd7; wc101 <= 4'd8; wc102 <= 4'd7; wc103 <= 3'd5; wc104 <= 4'd7; wc105 <= 4'd8; wc106 <= 4'd10; wc107 <= 4'd8; wc108 <= 4'd7; wc109 <= 4'd8; wc110 <= 4'd7; wc111 <= 3'd5; wc112 <= 3'd4; wc113 <= 3'd5; wc114 <= 4'd7; wc115 <= 3'd5; wc116 <= 4'd7; wc117 <= 4'd8; wc118 <= 4'd7; wc119 <= 3'd5; wc120 <= 3'd4; wc121 <= 3'd5; wc122 <= 4'd7; wc123 <= 3'd5; wc124 <= 3'd4; wc125 <= 3'd5; wc126 <= 3'd4; wc127 <= 2'd2; end
            {4'd0, 1'b1}: begin wc0 <= 2'd2; wc1 <= 3'd3; wc2 <= 3'd5; wc3 <= 3'd3; wc4 <= 3'd5; wc5 <= 4'd6; wc6 <= 3'd5; wc7 <= 3'd3; wc8 <= 3'd5; wc9 <= 4'd6; wc10 <= 4'd8; wc11 <= 4'd6; wc12 <= 3'd5; wc13 <= 4'd6; wc14 <= 3'd5; wc15 <= 3'd3; wc16 <= 3'd5; wc17 <= 4'd6; wc18 <= 4'd8; wc19 <= 4'd6; wc20 <= 4'd8; wc21 <= 4'd9; wc22 <= 4'd8; wc23 <= 4'd6; wc24 <= 3'd5; wc25 <= 4'd6; wc26 <= 4'd8; wc27 <= 4'd6; wc28 <= 3'd5; wc29 <= 4'd6; wc30 <= 3'd5; wc31 <= 3'd3; wc32 <= 3'd4; wc33 <= 3'd5; wc34 <= 4'd7; wc35 <= 3'd5; wc36 <= 4'd7; wc37 <= 4'd8; wc38 <= 4'd7; wc39 <= 3'd5; wc40 <= 4'd7; wc41 <= 4'd8; wc42 <= 4'd10; wc43 <= 4'd8; wc44 <= 4'd7; wc45 <= 4'd8; wc46 <= 4'd7; wc47 <= 3'd5; wc48 <= 3'd4; wc49 <= 3'd5; wc50 <= 4'd7; wc51 <= 3'd5; wc52 <= 4'd7; wc53 <= 4'd8; wc54 <= 4'd7; wc55 <= 3'd5; wc56 <= 3'd4; wc57 <= 3'd5; wc58 <= 4'd7; wc59 <= 3'd5; wc60 <= 3'd4; wc61 <= 3'd5; wc62 <= 3'd4; wc63 <= 2'd2; wc64 <= 2'd0; wc65 <= 3'd0; wc66 <= 3'd1; wc67 <= 3'd0; wc68 <= 3'd1; wc69 <= 4'd1; wc70 <= 3'd1; wc71 <= 3'd0; wc72 <= 3'd1; wc73 <= 4'd1; wc74 <= 4'd2; wc75 <= 4'd1; wc76 <= 3'd1; wc77 <= 4'd1; wc78 <= 3'd1; wc79 <= 3'd0; wc80 <= 3'd1; wc81 <= 4'd1; wc82 <= 4'd2; wc83 <= 4'd1; wc84 <= 4'd2; wc85 <= 4'd2; wc86 <= 4'd2; wc87 <= 4'd1; wc88 <= 3'd1; wc89 <= 4'd1; wc90 <= 4'd2; wc91 <= 4'd1; wc92 <= 3'd1; wc93 <= 4'd1; wc94 <= 3'd1; wc95 <= 3'd0; wc96 <= 3'd1; wc97 <= 3'd1; wc98 <= 4'd2; wc99 <= 3'd1; wc100 <= 4'd2; wc101 <= 4'd2; wc102 <= 4'd2; wc103 <= 3'd1; wc104 <= 4'd2; wc105 <= 4'd2; wc106 <= 4'd3; wc107 <= 4'd2; wc108 <= 4'd2; wc109 <= 4'd2; wc110 <= 4'd2; wc111 <= 3'd1; wc112 <= 3'd1; wc113 <= 3'd1; wc114 <= 4'd2; wc115 <= 3'd1; wc116 <= 4'd2; wc117 <= 4'd2; wc118 <= 4'd2; wc119 <= 3'd1; wc120 <= 3'd1; wc121 <= 3'd1; wc122 <= 4'd2; wc123 <= 3'd1; wc124 <= 3'd1; wc125 <= 3'd1; wc126 <= 3'd1; wc127 <= 2'd0; end
            {4'd1, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd0; wc3 <= 3'd0; wc4 <= 3'd1; wc5 <= 4'd2; wc6 <= 3'd0; wc7 <= 3'd0; wc8 <= 3'd1; wc9 <= 4'd2; wc10 <= 4'd1; wc11 <= 4'd1; wc12 <= 3'd1; wc13 <= 4'd2; wc14 <= 3'd0; wc15 <= 3'd0; wc16 <= 3'd1; wc17 <= 4'd2; wc18 <= 4'd1; wc19 <= 4'd1; wc20 <= 4'd2; wc21 <= 4'd3; wc22 <= 4'd1; wc23 <= 4'd1; wc24 <= 3'd1; wc25 <= 4'd2; wc26 <= 4'd1; wc27 <= 4'd1; wc28 <= 3'd1; wc29 <= 4'd2; wc30 <= 3'd0; wc31 <= 3'd0; wc32 <= 3'd1; wc33 <= 3'd2; wc34 <= 4'd1; wc35 <= 3'd1; wc36 <= 4'd2; wc37 <= 4'd3; wc38 <= 4'd1; wc39 <= 3'd1; wc40 <= 4'd2; wc41 <= 4'd3; wc42 <= 4'd2; wc43 <= 4'd2; wc44 <= 4'd2; wc45 <= 4'd3; wc46 <= 4'd1; wc47 <= 3'd1; wc48 <= 3'd1; wc49 <= 3'd2; wc50 <= 4'd1; wc51 <= 3'd1; wc52 <= 4'd2; wc53 <= 4'd3; wc54 <= 4'd1; wc55 <= 3'd1; wc56 <= 3'd1; wc57 <= 3'd2; wc58 <= 4'd1; wc59 <= 3'd1; wc60 <= 3'd1; wc61 <= 3'd2; wc62 <= 3'd0; wc63 <= 2'd0; wc64 <= 2'd2; wc65 <= 3'd4; wc66 <= 3'd4; wc67 <= 3'd3; wc68 <= 3'd5; wc69 <= 4'd7; wc70 <= 3'd4; wc71 <= 3'd3; wc72 <= 3'd5; wc73 <= 4'd7; wc74 <= 4'd7; wc75 <= 4'd6; wc76 <= 3'd5; wc77 <= 4'd7; wc78 <= 3'd4; wc79 <= 3'd3; wc80 <= 3'd5; wc81 <= 4'd7; wc82 <= 4'd7; wc83 <= 4'd6; wc84 <= 4'd8; wc85 <= 4'd10; wc86 <= 4'd7; wc87 <= 4'd6; wc88 <= 3'd5; wc89 <= 4'd7; wc90 <= 4'd7; wc91 <= 4'd6; wc92 <= 3'd5; wc93 <= 4'd7; wc94 <= 3'd4; wc95 <= 3'd3; wc96 <= 3'd4; wc97 <= 3'd6; wc98 <= 4'd6; wc99 <= 3'd5; wc100 <= 4'd7; wc101 <= 4'd9; wc102 <= 4'd6; wc103 <= 3'd5; wc104 <= 4'd7; wc105 <= 4'd9; wc106 <= 4'd9; wc107 <= 4'd8; wc108 <= 4'd7; wc109 <= 4'd9; wc110 <= 4'd6; wc111 <= 3'd5; wc112 <= 3'd4; wc113 <= 3'd6; wc114 <= 4'd6; wc115 <= 3'd5; wc116 <= 4'd7; wc117 <= 4'd9; wc118 <= 4'd6; wc119 <= 3'd5; wc120 <= 3'd4; wc121 <= 3'd6; wc122 <= 4'd6; wc123 <= 3'd5; wc124 <= 3'd4; wc125 <= 3'd6; wc126 <= 3'd3; wc127 <= 2'd2; end
            {4'd1, 1'b1}: begin wc0 <= 2'd2; wc1 <= 3'd4; wc2 <= 3'd4; wc3 <= 3'd3; wc4 <= 3'd5; wc5 <= 4'd7; wc6 <= 3'd4; wc7 <= 3'd3; wc8 <= 3'd5; wc9 <= 4'd7; wc10 <= 4'd7; wc11 <= 4'd6; wc12 <= 3'd5; wc13 <= 4'd7; wc14 <= 3'd4; wc15 <= 3'd3; wc16 <= 3'd5; wc17 <= 4'd7; wc18 <= 4'd7; wc19 <= 4'd6; wc20 <= 4'd8; wc21 <= 4'd10; wc22 <= 4'd7; wc23 <= 4'd6; wc24 <= 3'd5; wc25 <= 4'd7; wc26 <= 4'd7; wc27 <= 4'd6; wc28 <= 3'd5; wc29 <= 4'd7; wc30 <= 3'd4; wc31 <= 3'd3; wc32 <= 3'd4; wc33 <= 3'd6; wc34 <= 4'd6; wc35 <= 3'd5; wc36 <= 4'd7; wc37 <= 4'd9; wc38 <= 4'd6; wc39 <= 3'd5; wc40 <= 4'd7; wc41 <= 4'd9; wc42 <= 4'd9; wc43 <= 4'd8; wc44 <= 4'd7; wc45 <= 4'd9; wc46 <= 4'd6; wc47 <= 3'd5; wc48 <= 3'd4; wc49 <= 3'd6; wc50 <= 4'd6; wc51 <= 3'd5; wc52 <= 4'd7; wc53 <= 4'd9; wc54 <= 4'd6; wc55 <= 3'd5; wc56 <= 3'd4; wc57 <= 3'd6; wc58 <= 4'd6; wc59 <= 3'd5; wc60 <= 3'd4; wc61 <= 3'd6; wc62 <= 3'd3; wc63 <= 2'd2; wc64 <= 2'd0; wc65 <= 3'd1; wc66 <= 3'd0; wc67 <= 3'd0; wc68 <= 3'd1; wc69 <= 4'd2; wc70 <= 3'd0; wc71 <= 3'd0; wc72 <= 3'd1; wc73 <= 4'd2; wc74 <= 4'd1; wc75 <= 4'd1; wc76 <= 3'd1; wc77 <= 4'd2; wc78 <= 3'd0; wc79 <= 3'd0; wc80 <= 3'd1; wc81 <= 4'd2; wc82 <= 4'd1; wc83 <= 4'd1; wc84 <= 4'd2; wc85 <= 4'd3; wc86 <= 4'd1; wc87 <= 4'd1; wc88 <= 3'd1; wc89 <= 4'd2; wc90 <= 4'd1; wc91 <= 4'd1; wc92 <= 3'd1; wc93 <= 4'd2; wc94 <= 3'd0; wc95 <= 3'd0; wc96 <= 3'd1; wc97 <= 3'd2; wc98 <= 4'd1; wc99 <= 3'd1; wc100 <= 4'd2; wc101 <= 4'd3; wc102 <= 4'd1; wc103 <= 3'd1; wc104 <= 4'd2; wc105 <= 4'd3; wc106 <= 4'd2; wc107 <= 4'd2; wc108 <= 4'd2; wc109 <= 4'd3; wc110 <= 4'd1; wc111 <= 3'd1; wc112 <= 3'd1; wc113 <= 3'd2; wc114 <= 4'd1; wc115 <= 3'd1; wc116 <= 4'd2; wc117 <= 4'd3; wc118 <= 4'd1; wc119 <= 3'd1; wc120 <= 3'd1; wc121 <= 3'd2; wc122 <= 4'd1; wc123 <= 3'd1; wc124 <= 3'd1; wc125 <= 3'd2; wc126 <= 3'd0; wc127 <= 2'd0; end
            {4'd2, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd0; wc5 <= 4'd0; wc6 <= 3'd0; wc7 <= 3'd0; wc8 <= 3'd1; wc9 <= 4'd2; wc10 <= 4'd3; wc11 <= 4'd2; wc12 <= 3'd0; wc13 <= 4'd0; wc14 <= 3'd0; wc15 <= 3'd0; wc16 <= 3'd1; wc17 <= 4'd2; wc18 <= 4'd3; wc19 <= 4'd2; wc20 <= 4'd1; wc21 <= 4'd1; wc22 <= 4'd1; wc23 <= 4'd1; wc24 <= 3'd1; wc25 <= 4'd2; wc26 <= 4'd3; wc27 <= 4'd2; wc28 <= 3'd0; wc29 <= 4'd0; wc30 <= 3'd0; wc31 <= 3'd0; wc32 <= 3'd1; wc33 <= 3'd2; wc34 <= 4'd3; wc35 <= 3'd2; wc36 <= 4'd1; wc37 <= 4'd1; wc38 <= 4'd1; wc39 <= 3'd1; wc40 <= 4'd2; wc41 <= 4'd3; wc42 <= 4'd4; wc43 <= 4'd3; wc44 <= 4'd1; wc45 <= 4'd1; wc46 <= 4'd1; wc47 <= 3'd1; wc48 <= 3'd1; wc49 <= 3'd2; wc50 <= 4'd3; wc51 <= 3'd2; wc52 <= 4'd1; wc53 <= 4'd1; wc54 <= 4'd1; wc55 <= 3'd1; wc56 <= 3'd1; wc57 <= 3'd2; wc58 <= 4'd3; wc59 <= 3'd2; wc60 <= 3'd0; wc61 <= 3'd0; wc62 <= 3'd0; wc63 <= 2'd0; wc64 <= 2'd2; wc65 <= 3'd4; wc66 <= 3'd6; wc67 <= 3'd4; wc68 <= 3'd4; wc69 <= 4'd5; wc70 <= 3'd4; wc71 <= 3'd3; wc72 <= 3'd5; wc73 <= 4'd7; wc74 <= 4'd9; wc75 <= 4'd7; wc76 <= 3'd4; wc77 <= 4'd5; wc78 <= 3'd4; wc79 <= 3'd3; wc80 <= 3'd5; wc81 <= 4'd7; wc82 <= 4'd9; wc83 <= 4'd7; wc84 <= 4'd7; wc85 <= 4'd8; wc86 <= 4'd7; wc87 <= 4'd6; wc88 <= 3'd5; wc89 <= 4'd7; wc90 <= 4'd9; wc91 <= 4'd7; wc92 <= 3'd4; wc93 <= 4'd5; wc94 <= 3'd4; wc95 <= 3'd3; wc96 <= 3'd4; wc97 <= 3'd6; wc98 <= 4'd8; wc99 <= 3'd6; wc100 <= 4'd6; wc101 <= 4'd7; wc102 <= 4'd6; wc103 <= 3'd5; wc104 <= 4'd7; wc105 <= 4'd9; wc106 <= 4'd11; wc107 <= 4'd9; wc108 <= 4'd6; wc109 <= 4'd7; wc110 <= 4'd6; wc111 <= 3'd5; wc112 <= 3'd4; wc113 <= 3'd6; wc114 <= 4'd8; wc115 <= 3'd6; wc116 <= 4'd6; wc117 <= 4'd7; wc118 <= 4'd6; wc119 <= 3'd5; wc120 <= 3'd4; wc121 <= 3'd6; wc122 <= 4'd8; wc123 <= 3'd6; wc124 <= 3'd3; wc125 <= 3'd4; wc126 <= 3'd3; wc127 <= 2'd2; end
            {4'd2, 1'b1}: begin wc0 <= 2'd2; wc1 <= 3'd4; wc2 <= 3'd6; wc3 <= 3'd4; wc4 <= 3'd4; wc5 <= 4'd5; wc6 <= 3'd4; wc7 <= 3'd3; wc8 <= 3'd5; wc9 <= 4'd7; wc10 <= 4'd9; wc11 <= 4'd7; wc12 <= 3'd4; wc13 <= 4'd5; wc14 <= 3'd4; wc15 <= 3'd3; wc16 <= 3'd5; wc17 <= 4'd7; wc18 <= 4'd9; wc19 <= 4'd7; wc20 <= 4'd7; wc21 <= 4'd8; wc22 <= 4'd7; wc23 <= 4'd6; wc24 <= 3'd5; wc25 <= 4'd7; wc26 <= 4'd9; wc27 <= 4'd7; wc28 <= 3'd4; wc29 <= 4'd5; wc30 <= 3'd4; wc31 <= 3'd3; wc32 <= 3'd4; wc33 <= 3'd6; wc34 <= 4'd8; wc35 <= 3'd6; wc36 <= 4'd6; wc37 <= 4'd7; wc38 <= 4'd6; wc39 <= 3'd5; wc40 <= 4'd7; wc41 <= 4'd9; wc42 <= 4'd11; wc43 <= 4'd9; wc44 <= 4'd6; wc45 <= 4'd7; wc46 <= 4'd6; wc47 <= 3'd5; wc48 <= 3'd4; wc49 <= 3'd6; wc50 <= 4'd8; wc51 <= 3'd6; wc52 <= 4'd6; wc53 <= 4'd7; wc54 <= 4'd6; wc55 <= 3'd5; wc56 <= 3'd4; wc57 <= 3'd6; wc58 <= 4'd8; wc59 <= 3'd6; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; wc64 <= 2'd0; wc65 <= 3'd1; wc66 <= 3'd2; wc67 <= 3'd1; wc68 <= 3'd0; wc69 <= 4'd0; wc70 <= 3'd0; wc71 <= 3'd0; wc72 <= 3'd1; wc73 <= 4'd2; wc74 <= 4'd3; wc75 <= 4'd2; wc76 <= 3'd0; wc77 <= 4'd0; wc78 <= 3'd0; wc79 <= 3'd0; wc80 <= 3'd1; wc81 <= 4'd2; wc82 <= 4'd3; wc83 <= 4'd2; wc84 <= 4'd1; wc85 <= 4'd1; wc86 <= 4'd1; wc87 <= 4'd1; wc88 <= 3'd1; wc89 <= 4'd2; wc90 <= 4'd3; wc91 <= 4'd2; wc92 <= 3'd0; wc93 <= 4'd0; wc94 <= 3'd0; wc95 <= 3'd0; wc96 <= 3'd1; wc97 <= 3'd2; wc98 <= 4'd3; wc99 <= 3'd2; wc100 <= 4'd1; wc101 <= 4'd1; wc102 <= 4'd1; wc103 <= 3'd1; wc104 <= 4'd2; wc105 <= 4'd3; wc106 <= 4'd4; wc107 <= 4'd3; wc108 <= 4'd1; wc109 <= 4'd1; wc110 <= 4'd1; wc111 <= 3'd1; wc112 <= 3'd1; wc113 <= 3'd2; wc114 <= 4'd3; wc115 <= 3'd2; wc116 <= 4'd1; wc117 <= 4'd1; wc118 <= 4'd1; wc119 <= 3'd1; wc120 <= 3'd1; wc121 <= 3'd2; wc122 <= 4'd3; wc123 <= 3'd2; wc124 <= 3'd0; wc125 <= 3'd0; wc126 <= 3'd0; wc127 <= 2'd0; end
            {4'd3, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd0; wc9 <= 4'd0; wc10 <= 4'd0; wc11 <= 4'd0; wc12 <= 3'd0; wc13 <= 4'd0; wc14 <= 3'd0; wc15 <= 3'd0; wc16 <= 3'd1; wc17 <= 4'd2; wc18 <= 4'd3; wc19 <= 4'd2; wc20 <= 4'd3; wc21 <= 4'd4; wc22 <= 4'd3; wc23 <= 4'd2; wc24 <= 3'd0; wc25 <= 4'd0; wc26 <= 4'd0; wc27 <= 4'd0; wc28 <= 3'd0; wc29 <= 4'd0; wc30 <= 3'd0; wc31 <= 3'd0; wc32 <= 3'd1; wc33 <= 3'd2; wc34 <= 4'd3; wc35 <= 3'd2; wc36 <= 4'd3; wc37 <= 4'd4; wc38 <= 4'd3; wc39 <= 3'd2; wc40 <= 4'd1; wc41 <= 4'd1; wc42 <= 4'd1; wc43 <= 4'd1; wc44 <= 4'd1; wc45 <= 4'd1; wc46 <= 4'd1; wc47 <= 3'd1; wc48 <= 3'd1; wc49 <= 3'd2; wc50 <= 4'd3; wc51 <= 3'd2; wc52 <= 4'd3; wc53 <= 4'd4; wc54 <= 4'd3; wc55 <= 3'd2; wc56 <= 3'd0; wc57 <= 3'd0; wc58 <= 4'd0; wc59 <= 3'd0; wc60 <= 3'd0; wc61 <= 3'd0; wc62 <= 3'd0; wc63 <= 2'd0; wc64 <= 2'd2; wc65 <= 3'd4; wc66 <= 3'd6; wc67 <= 3'd4; wc68 <= 3'd6; wc69 <= 4'd8; wc70 <= 3'd6; wc71 <= 3'd4; wc72 <= 3'd4; wc73 <= 4'd5; wc74 <= 4'd6; wc75 <= 4'd5; wc76 <= 3'd4; wc77 <= 4'd5; wc78 <= 3'd4; wc79 <= 3'd3; wc80 <= 3'd5; wc81 <= 4'd7; wc82 <= 4'd9; wc83 <= 4'd7; wc84 <= 4'd9; wc85 <= 4'd11; wc86 <= 4'd9; wc87 <= 4'd7; wc88 <= 3'd4; wc89 <= 4'd5; wc90 <= 4'd6; wc91 <= 4'd5; wc92 <= 3'd4; wc93 <= 4'd5; wc94 <= 3'd4; wc95 <= 3'd3; wc96 <= 3'd4; wc97 <= 3'd6; wc98 <= 4'd8; wc99 <= 3'd6; wc100 <= 4'd8; wc101 <= 4'd10; wc102 <= 4'd8; wc103 <= 3'd6; wc104 <= 4'd6; wc105 <= 4'd7; wc106 <= 4'd8; wc107 <= 4'd7; wc108 <= 4'd6; wc109 <= 4'd7; wc110 <= 4'd6; wc111 <= 3'd5; wc112 <= 3'd4; wc113 <= 3'd6; wc114 <= 4'd8; wc115 <= 3'd6; wc116 <= 4'd8; wc117 <= 4'd10; wc118 <= 4'd8; wc119 <= 3'd6; wc120 <= 3'd3; wc121 <= 3'd4; wc122 <= 4'd5; wc123 <= 3'd4; wc124 <= 3'd3; wc125 <= 3'd4; wc126 <= 3'd3; wc127 <= 2'd2; end
            {4'd3, 1'b1}: begin wc0 <= 2'd2; wc1 <= 3'd4; wc2 <= 3'd6; wc3 <= 3'd4; wc4 <= 3'd6; wc5 <= 4'd8; wc6 <= 3'd6; wc7 <= 3'd4; wc8 <= 3'd4; wc9 <= 4'd5; wc10 <= 4'd6; wc11 <= 4'd5; wc12 <= 3'd4; wc13 <= 4'd5; wc14 <= 3'd4; wc15 <= 3'd3; wc16 <= 3'd5; wc17 <= 4'd7; wc18 <= 4'd9; wc19 <= 4'd7; wc20 <= 4'd9; wc21 <= 4'd11; wc22 <= 4'd9; wc23 <= 4'd7; wc24 <= 3'd4; wc25 <= 4'd5; wc26 <= 4'd6; wc27 <= 4'd5; wc28 <= 3'd4; wc29 <= 4'd5; wc30 <= 3'd4; wc31 <= 3'd3; wc32 <= 3'd4; wc33 <= 3'd6; wc34 <= 4'd8; wc35 <= 3'd6; wc36 <= 4'd8; wc37 <= 4'd10; wc38 <= 4'd8; wc39 <= 3'd6; wc40 <= 4'd6; wc41 <= 4'd7; wc42 <= 4'd8; wc43 <= 4'd7; wc44 <= 4'd6; wc45 <= 4'd7; wc46 <= 4'd6; wc47 <= 3'd5; wc48 <= 3'd4; wc49 <= 3'd6; wc50 <= 4'd8; wc51 <= 3'd6; wc52 <= 4'd8; wc53 <= 4'd10; wc54 <= 4'd8; wc55 <= 3'd6; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; wc64 <= 2'd0; wc65 <= 3'd1; wc66 <= 3'd2; wc67 <= 3'd1; wc68 <= 3'd2; wc69 <= 4'd3; wc70 <= 3'd2; wc71 <= 3'd1; wc72 <= 3'd0; wc73 <= 4'd0; wc74 <= 4'd0; wc75 <= 4'd0; wc76 <= 3'd0; wc77 <= 4'd0; wc78 <= 3'd0; wc79 <= 3'd0; wc80 <= 3'd1; wc81 <= 4'd2; wc82 <= 4'd3; wc83 <= 4'd2; wc84 <= 4'd3; wc85 <= 4'd4; wc86 <= 4'd3; wc87 <= 4'd2; wc88 <= 3'd0; wc89 <= 4'd0; wc90 <= 4'd0; wc91 <= 4'd0; wc92 <= 3'd0; wc93 <= 4'd0; wc94 <= 3'd0; wc95 <= 3'd0; wc96 <= 3'd1; wc97 <= 3'd2; wc98 <= 4'd3; wc99 <= 3'd2; wc100 <= 4'd3; wc101 <= 4'd4; wc102 <= 4'd3; wc103 <= 3'd2; wc104 <= 4'd1; wc105 <= 4'd1; wc106 <= 4'd1; wc107 <= 4'd1; wc108 <= 4'd1; wc109 <= 4'd1; wc110 <= 4'd1; wc111 <= 3'd1; wc112 <= 3'd1; wc113 <= 3'd2; wc114 <= 4'd3; wc115 <= 3'd2; wc116 <= 4'd3; wc117 <= 4'd4; wc118 <= 4'd3; wc119 <= 3'd2; wc120 <= 3'd0; wc121 <= 3'd0; wc122 <= 4'd0; wc123 <= 3'd0; wc124 <= 3'd0; wc125 <= 3'd0; wc126 <= 3'd0; wc127 <= 2'd0; end
            {4'd4, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd0; wc17 <= 4'd0; wc18 <= 4'd0; wc19 <= 4'd0; wc20 <= 4'd0; wc21 <= 4'd0; wc22 <= 4'd0; wc23 <= 4'd0; wc24 <= 3'd0; wc25 <= 4'd0; wc26 <= 4'd0; wc27 <= 4'd0; wc28 <= 3'd0; wc29 <= 4'd0; wc30 <= 3'd0; wc31 <= 3'd0; wc32 <= 3'd1; wc33 <= 3'd2; wc34 <= 4'd3; wc35 <= 3'd2; wc36 <= 4'd3; wc37 <= 4'd4; wc38 <= 4'd3; wc39 <= 3'd2; wc40 <= 4'd3; wc41 <= 4'd4; wc42 <= 4'd5; wc43 <= 4'd4; wc44 <= 4'd3; wc45 <= 4'd4; wc46 <= 4'd3; wc47 <= 3'd2; wc48 <= 3'd0; wc49 <= 3'd0; wc50 <= 4'd0; wc51 <= 3'd0; wc52 <= 4'd0; wc53 <= 4'd0; wc54 <= 4'd0; wc55 <= 3'd0; wc56 <= 3'd0; wc57 <= 3'd0; wc58 <= 4'd0; wc59 <= 3'd0; wc60 <= 3'd0; wc61 <= 3'd0; wc62 <= 3'd0; wc63 <= 2'd0; wc64 <= 2'd2; wc65 <= 3'd4; wc66 <= 3'd6; wc67 <= 3'd4; wc68 <= 3'd6; wc69 <= 4'd8; wc70 <= 3'd6; wc71 <= 3'd4; wc72 <= 3'd6; wc73 <= 4'd8; wc74 <= 4'd10; wc75 <= 4'd8; wc76 <= 3'd6; wc77 <= 4'd8; wc78 <= 3'd6; wc79 <= 3'd4; wc80 <= 3'd4; wc81 <= 4'd5; wc82 <= 4'd6; wc83 <= 4'd5; wc84 <= 4'd6; wc85 <= 4'd7; wc86 <= 4'd6; wc87 <= 4'd5; wc88 <= 3'd4; wc89 <= 4'd5; wc90 <= 4'd6; wc91 <= 4'd5; wc92 <= 3'd4; wc93 <= 4'd5; wc94 <= 3'd4; wc95 <= 3'd3; wc96 <= 3'd4; wc97 <= 3'd6; wc98 <= 4'd8; wc99 <= 3'd6; wc100 <= 4'd8; wc101 <= 4'd10; wc102 <= 4'd8; wc103 <= 3'd6; wc104 <= 4'd8; wc105 <= 4'd10; wc106 <= 4'd12; wc107 <= 4'd10; wc108 <= 4'd8; wc109 <= 4'd10; wc110 <= 4'd8; wc111 <= 3'd6; wc112 <= 3'd3; wc113 <= 3'd4; wc114 <= 4'd5; wc115 <= 3'd4; wc116 <= 4'd5; wc117 <= 4'd6; wc118 <= 4'd5; wc119 <= 3'd4; wc120 <= 3'd3; wc121 <= 3'd4; wc122 <= 4'd5; wc123 <= 3'd4; wc124 <= 3'd3; wc125 <= 3'd4; wc126 <= 3'd3; wc127 <= 2'd2; end
            {4'd4, 1'b1}: begin wc0 <= 2'd2; wc1 <= 3'd4; wc2 <= 3'd6; wc3 <= 3'd4; wc4 <= 3'd6; wc5 <= 4'd8; wc6 <= 3'd6; wc7 <= 3'd4; wc8 <= 3'd6; wc9 <= 4'd8; wc10 <= 4'd10; wc11 <= 4'd8; wc12 <= 3'd6; wc13 <= 4'd8; wc14 <= 3'd6; wc15 <= 3'd4; wc16 <= 3'd4; wc17 <= 4'd5; wc18 <= 4'd6; wc19 <= 4'd5; wc20 <= 4'd6; wc21 <= 4'd7; wc22 <= 4'd6; wc23 <= 4'd5; wc24 <= 3'd4; wc25 <= 4'd5; wc26 <= 4'd6; wc27 <= 4'd5; wc28 <= 3'd4; wc29 <= 4'd5; wc30 <= 3'd4; wc31 <= 3'd3; wc32 <= 3'd4; wc33 <= 3'd6; wc34 <= 4'd8; wc35 <= 3'd6; wc36 <= 4'd8; wc37 <= 4'd10; wc38 <= 4'd8; wc39 <= 3'd6; wc40 <= 4'd8; wc41 <= 4'd10; wc42 <= 4'd12; wc43 <= 4'd10; wc44 <= 4'd8; wc45 <= 4'd10; wc46 <= 4'd8; wc47 <= 3'd6; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; wc64 <= 2'd0; wc65 <= 3'd1; wc66 <= 3'd2; wc67 <= 3'd1; wc68 <= 3'd2; wc69 <= 4'd3; wc70 <= 3'd2; wc71 <= 3'd1; wc72 <= 3'd2; wc73 <= 4'd3; wc74 <= 4'd4; wc75 <= 4'd3; wc76 <= 3'd2; wc77 <= 4'd3; wc78 <= 3'd2; wc79 <= 3'd1; wc80 <= 3'd0; wc81 <= 4'd0; wc82 <= 4'd0; wc83 <= 4'd0; wc84 <= 4'd0; wc85 <= 4'd0; wc86 <= 4'd0; wc87 <= 4'd0; wc88 <= 3'd0; wc89 <= 4'd0; wc90 <= 4'd0; wc91 <= 4'd0; wc92 <= 3'd0; wc93 <= 4'd0; wc94 <= 3'd0; wc95 <= 3'd0; wc96 <= 3'd1; wc97 <= 3'd2; wc98 <= 4'd3; wc99 <= 3'd2; wc100 <= 4'd3; wc101 <= 4'd4; wc102 <= 4'd3; wc103 <= 3'd2; wc104 <= 4'd3; wc105 <= 4'd4; wc106 <= 4'd5; wc107 <= 4'd4; wc108 <= 4'd3; wc109 <= 4'd4; wc110 <= 4'd3; wc111 <= 3'd2; wc112 <= 3'd0; wc113 <= 3'd0; wc114 <= 4'd0; wc115 <= 3'd0; wc116 <= 4'd0; wc117 <= 4'd0; wc118 <= 4'd0; wc119 <= 3'd0; wc120 <= 3'd0; wc121 <= 3'd0; wc122 <= 4'd0; wc123 <= 3'd0; wc124 <= 3'd0; wc125 <= 3'd0; wc126 <= 3'd0; wc127 <= 2'd0; end
            {4'd5, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 4'd3; wc18 <= 4'd4; wc19 <= 4'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 4'd3; wc24 <= 3'd2; wc25 <= 4'd3; wc26 <= 4'd4; wc27 <= 4'd3; wc28 <= 3'd2; wc29 <= 4'd3; wc30 <= 3'd2; wc31 <= 3'd1; wc32 <= 3'd0; wc33 <= 3'd0; wc34 <= 4'd0; wc35 <= 3'd0; wc36 <= 4'd0; wc37 <= 4'd0; wc38 <= 4'd0; wc39 <= 3'd0; wc40 <= 4'd0; wc41 <= 4'd0; wc42 <= 4'd0; wc43 <= 4'd0; wc44 <= 4'd0; wc45 <= 4'd0; wc46 <= 4'd0; wc47 <= 3'd0; wc48 <= 3'd0; wc49 <= 3'd0; wc50 <= 4'd0; wc51 <= 3'd0; wc52 <= 4'd0; wc53 <= 4'd0; wc54 <= 4'd0; wc55 <= 3'd0; wc56 <= 3'd0; wc57 <= 3'd0; wc58 <= 4'd0; wc59 <= 3'd0; wc60 <= 3'd0; wc61 <= 3'd0; wc62 <= 3'd0; wc63 <= 2'd0; wc64 <= 2'd2; wc65 <= 3'd4; wc66 <= 3'd6; wc67 <= 3'd4; wc68 <= 3'd6; wc69 <= 4'd8; wc70 <= 3'd6; wc71 <= 3'd4; wc72 <= 3'd6; wc73 <= 4'd8; wc74 <= 4'd10; wc75 <= 4'd8; wc76 <= 3'd6; wc77 <= 4'd8; wc78 <= 3'd6; wc79 <= 3'd4; wc80 <= 3'd6; wc81 <= 4'd8; wc82 <= 4'd10; wc83 <= 4'd8; wc84 <= 4'd10; wc85 <= 4'd12; wc86 <= 4'd10; wc87 <= 4'd8; wc88 <= 3'd6; wc89 <= 4'd8; wc90 <= 4'd10; wc91 <= 4'd8; wc92 <= 3'd6; wc93 <= 4'd8; wc94 <= 3'd6; wc95 <= 3'd4; wc96 <= 3'd3; wc97 <= 3'd4; wc98 <= 4'd5; wc99 <= 3'd4; wc100 <= 4'd5; wc101 <= 4'd6; wc102 <= 4'd5; wc103 <= 3'd4; wc104 <= 4'd5; wc105 <= 4'd6; wc106 <= 4'd7; wc107 <= 4'd6; wc108 <= 4'd5; wc109 <= 4'd6; wc110 <= 4'd5; wc111 <= 3'd4; wc112 <= 3'd3; wc113 <= 3'd4; wc114 <= 4'd5; wc115 <= 3'd4; wc116 <= 4'd5; wc117 <= 4'd6; wc118 <= 4'd5; wc119 <= 3'd4; wc120 <= 3'd3; wc121 <= 3'd4; wc122 <= 4'd5; wc123 <= 3'd4; wc124 <= 3'd3; wc125 <= 3'd4; wc126 <= 3'd3; wc127 <= 2'd2; end
            {4'd5, 1'b1}: begin wc0 <= 2'd2; wc1 <= 3'd4; wc2 <= 3'd6; wc3 <= 3'd4; wc4 <= 3'd6; wc5 <= 4'd8; wc6 <= 3'd6; wc7 <= 3'd4; wc8 <= 3'd6; wc9 <= 4'd8; wc10 <= 4'd10; wc11 <= 4'd8; wc12 <= 3'd6; wc13 <= 4'd8; wc14 <= 3'd6; wc15 <= 3'd4; wc16 <= 3'd6; wc17 <= 4'd8; wc18 <= 4'd10; wc19 <= 4'd8; wc20 <= 4'd10; wc21 <= 4'd12; wc22 <= 4'd10; wc23 <= 4'd8; wc24 <= 3'd6; wc25 <= 4'd8; wc26 <= 4'd10; wc27 <= 4'd8; wc28 <= 3'd6; wc29 <= 4'd8; wc30 <= 3'd6; wc31 <= 3'd4; wc32 <= 3'd3; wc33 <= 3'd4; wc34 <= 4'd5; wc35 <= 3'd4; wc36 <= 4'd5; wc37 <= 4'd6; wc38 <= 4'd5; wc39 <= 3'd4; wc40 <= 4'd5; wc41 <= 4'd6; wc42 <= 4'd7; wc43 <= 4'd6; wc44 <= 4'd5; wc45 <= 4'd6; wc46 <= 4'd5; wc47 <= 3'd4; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; wc64 <= 2'd0; wc65 <= 3'd1; wc66 <= 3'd2; wc67 <= 3'd1; wc68 <= 3'd2; wc69 <= 4'd3; wc70 <= 3'd2; wc71 <= 3'd1; wc72 <= 3'd2; wc73 <= 4'd3; wc74 <= 4'd4; wc75 <= 4'd3; wc76 <= 3'd2; wc77 <= 4'd3; wc78 <= 3'd2; wc79 <= 3'd1; wc80 <= 3'd2; wc81 <= 4'd3; wc82 <= 4'd4; wc83 <= 4'd3; wc84 <= 4'd4; wc85 <= 4'd5; wc86 <= 4'd4; wc87 <= 4'd3; wc88 <= 3'd2; wc89 <= 4'd3; wc90 <= 4'd4; wc91 <= 4'd3; wc92 <= 3'd2; wc93 <= 4'd3; wc94 <= 3'd2; wc95 <= 3'd1; wc96 <= 3'd0; wc97 <= 3'd0; wc98 <= 4'd0; wc99 <= 3'd0; wc100 <= 4'd0; wc101 <= 4'd0; wc102 <= 4'd0; wc103 <= 3'd0; wc104 <= 4'd0; wc105 <= 4'd0; wc106 <= 4'd0; wc107 <= 4'd0; wc108 <= 4'd0; wc109 <= 4'd0; wc110 <= 4'd0; wc111 <= 3'd0; wc112 <= 3'd0; wc113 <= 3'd0; wc114 <= 4'd0; wc115 <= 3'd0; wc116 <= 4'd0; wc117 <= 4'd0; wc118 <= 4'd0; wc119 <= 3'd0; wc120 <= 3'd0; wc121 <= 3'd0; wc122 <= 4'd0; wc123 <= 3'd0; wc124 <= 3'd0; wc125 <= 3'd0; wc126 <= 3'd0; wc127 <= 2'd0; end
            {4'd6, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 4'd3; wc18 <= 4'd4; wc19 <= 4'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 4'd3; wc24 <= 3'd2; wc25 <= 4'd3; wc26 <= 4'd4; wc27 <= 4'd3; wc28 <= 3'd2; wc29 <= 4'd3; wc30 <= 3'd2; wc31 <= 3'd1; wc32 <= 3'd2; wc33 <= 3'd3; wc34 <= 4'd4; wc35 <= 3'd3; wc36 <= 4'd4; wc37 <= 4'd5; wc38 <= 4'd4; wc39 <= 3'd3; wc40 <= 4'd4; wc41 <= 4'd5; wc42 <= 4'd6; wc43 <= 4'd5; wc44 <= 4'd4; wc45 <= 4'd5; wc46 <= 4'd4; wc47 <= 3'd3; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; wc64 <= 2'd1; wc65 <= 3'd2; wc66 <= 3'd3; wc67 <= 3'd2; wc68 <= 3'd3; wc69 <= 4'd4; wc70 <= 3'd3; wc71 <= 3'd2; wc72 <= 3'd3; wc73 <= 4'd4; wc74 <= 4'd5; wc75 <= 4'd4; wc76 <= 3'd3; wc77 <= 4'd4; wc78 <= 3'd3; wc79 <= 3'd2; wc80 <= 3'd3; wc81 <= 4'd4; wc82 <= 4'd5; wc83 <= 4'd4; wc84 <= 4'd5; wc85 <= 4'd6; wc86 <= 4'd5; wc87 <= 4'd4; wc88 <= 3'd3; wc89 <= 4'd4; wc90 <= 4'd5; wc91 <= 4'd4; wc92 <= 3'd3; wc93 <= 4'd4; wc94 <= 3'd3; wc95 <= 3'd2; wc96 <= 3'd3; wc97 <= 3'd4; wc98 <= 4'd5; wc99 <= 3'd4; wc100 <= 4'd5; wc101 <= 4'd6; wc102 <= 4'd5; wc103 <= 3'd4; wc104 <= 4'd5; wc105 <= 4'd6; wc106 <= 4'd7; wc107 <= 4'd6; wc108 <= 4'd5; wc109 <= 4'd6; wc110 <= 4'd5; wc111 <= 3'd4; wc112 <= 3'd3; wc113 <= 3'd4; wc114 <= 4'd5; wc115 <= 3'd4; wc116 <= 4'd5; wc117 <= 4'd6; wc118 <= 4'd5; wc119 <= 3'd4; wc120 <= 3'd3; wc121 <= 3'd4; wc122 <= 4'd5; wc123 <= 3'd4; wc124 <= 3'd3; wc125 <= 3'd4; wc126 <= 3'd3; wc127 <= 2'd2; end
            {4'd6, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 4'd4; wc18 <= 4'd5; wc19 <= 4'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 4'd4; wc24 <= 3'd3; wc25 <= 4'd4; wc26 <= 4'd5; wc27 <= 4'd4; wc28 <= 3'd3; wc29 <= 4'd4; wc30 <= 3'd3; wc31 <= 3'd2; wc32 <= 3'd3; wc33 <= 3'd4; wc34 <= 4'd5; wc35 <= 3'd4; wc36 <= 4'd5; wc37 <= 4'd6; wc38 <= 4'd5; wc39 <= 3'd4; wc40 <= 4'd5; wc41 <= 4'd6; wc42 <= 4'd7; wc43 <= 4'd6; wc44 <= 4'd5; wc45 <= 4'd6; wc46 <= 4'd5; wc47 <= 3'd4; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; wc64 <= 2'd0; wc65 <= 3'd1; wc66 <= 3'd2; wc67 <= 3'd1; wc68 <= 3'd2; wc69 <= 4'd3; wc70 <= 3'd2; wc71 <= 3'd1; wc72 <= 3'd2; wc73 <= 4'd3; wc74 <= 4'd4; wc75 <= 4'd3; wc76 <= 3'd2; wc77 <= 4'd3; wc78 <= 3'd2; wc79 <= 3'd1; wc80 <= 3'd2; wc81 <= 4'd3; wc82 <= 4'd4; wc83 <= 4'd3; wc84 <= 4'd4; wc85 <= 4'd5; wc86 <= 4'd4; wc87 <= 4'd3; wc88 <= 3'd2; wc89 <= 4'd3; wc90 <= 4'd4; wc91 <= 4'd3; wc92 <= 3'd2; wc93 <= 4'd3; wc94 <= 3'd2; wc95 <= 3'd1; wc96 <= 3'd2; wc97 <= 3'd3; wc98 <= 4'd4; wc99 <= 3'd3; wc100 <= 4'd4; wc101 <= 4'd5; wc102 <= 4'd4; wc103 <= 3'd3; wc104 <= 4'd4; wc105 <= 4'd5; wc106 <= 4'd6; wc107 <= 4'd5; wc108 <= 4'd4; wc109 <= 4'd5; wc110 <= 4'd4; wc111 <= 3'd3; wc112 <= 3'd2; wc113 <= 3'd3; wc114 <= 4'd4; wc115 <= 3'd3; wc116 <= 4'd4; wc117 <= 4'd5; wc118 <= 4'd4; wc119 <= 3'd3; wc120 <= 3'd2; wc121 <= 3'd3; wc122 <= 4'd4; wc123 <= 3'd3; wc124 <= 3'd2; wc125 <= 3'd3; wc126 <= 3'd2; wc127 <= 2'd1; end
            {4'd7, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 4'd3; wc18 <= 4'd4; wc19 <= 4'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 4'd3; wc24 <= 3'd2; wc25 <= 4'd3; wc26 <= 4'd4; wc27 <= 4'd3; wc28 <= 3'd2; wc29 <= 4'd3; wc30 <= 3'd2; wc31 <= 3'd1; wc32 <= 3'd2; wc33 <= 3'd3; wc34 <= 4'd4; wc35 <= 3'd3; wc36 <= 4'd4; wc37 <= 4'd5; wc38 <= 4'd4; wc39 <= 3'd3; wc40 <= 4'd4; wc41 <= 4'd5; wc42 <= 4'd6; wc43 <= 4'd5; wc44 <= 4'd4; wc45 <= 4'd5; wc46 <= 4'd4; wc47 <= 3'd3; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; wc64 <= 2'd1; wc65 <= 3'd2; wc66 <= 3'd3; wc67 <= 3'd2; wc68 <= 3'd3; wc69 <= 4'd4; wc70 <= 3'd3; wc71 <= 3'd2; wc72 <= 3'd3; wc73 <= 4'd4; wc74 <= 4'd5; wc75 <= 4'd4; wc76 <= 3'd3; wc77 <= 4'd4; wc78 <= 3'd3; wc79 <= 3'd2; wc80 <= 3'd3; wc81 <= 4'd4; wc82 <= 4'd5; wc83 <= 4'd4; wc84 <= 4'd5; wc85 <= 4'd6; wc86 <= 4'd5; wc87 <= 4'd4; wc88 <= 3'd3; wc89 <= 4'd4; wc90 <= 4'd5; wc91 <= 4'd4; wc92 <= 3'd3; wc93 <= 4'd4; wc94 <= 3'd3; wc95 <= 3'd2; wc96 <= 3'd3; wc97 <= 3'd4; wc98 <= 4'd5; wc99 <= 3'd4; wc100 <= 4'd5; wc101 <= 4'd6; wc102 <= 4'd5; wc103 <= 3'd4; wc104 <= 4'd5; wc105 <= 4'd6; wc106 <= 4'd7; wc107 <= 4'd6; wc108 <= 4'd5; wc109 <= 4'd6; wc110 <= 4'd5; wc111 <= 3'd4; wc112 <= 3'd3; wc113 <= 3'd4; wc114 <= 4'd5; wc115 <= 3'd4; wc116 <= 4'd5; wc117 <= 4'd6; wc118 <= 4'd5; wc119 <= 3'd4; wc120 <= 3'd3; wc121 <= 3'd4; wc122 <= 4'd5; wc123 <= 3'd4; wc124 <= 3'd3; wc125 <= 3'd4; wc126 <= 3'd3; wc127 <= 2'd2; end
            {4'd7, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 4'd4; wc18 <= 4'd5; wc19 <= 4'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 4'd4; wc24 <= 3'd3; wc25 <= 4'd4; wc26 <= 4'd5; wc27 <= 4'd4; wc28 <= 3'd3; wc29 <= 4'd4; wc30 <= 3'd3; wc31 <= 3'd2; wc32 <= 3'd3; wc33 <= 3'd4; wc34 <= 4'd5; wc35 <= 3'd4; wc36 <= 4'd5; wc37 <= 4'd6; wc38 <= 4'd5; wc39 <= 3'd4; wc40 <= 4'd5; wc41 <= 4'd6; wc42 <= 4'd7; wc43 <= 4'd6; wc44 <= 4'd5; wc45 <= 4'd6; wc46 <= 4'd5; wc47 <= 3'd4; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; wc64 <= 2'd0; wc65 <= 3'd1; wc66 <= 3'd2; wc67 <= 3'd1; wc68 <= 3'd2; wc69 <= 4'd3; wc70 <= 3'd2; wc71 <= 3'd1; wc72 <= 3'd2; wc73 <= 4'd3; wc74 <= 4'd4; wc75 <= 4'd3; wc76 <= 3'd2; wc77 <= 4'd3; wc78 <= 3'd2; wc79 <= 3'd1; wc80 <= 3'd2; wc81 <= 4'd3; wc82 <= 4'd4; wc83 <= 4'd3; wc84 <= 4'd4; wc85 <= 4'd5; wc86 <= 4'd4; wc87 <= 4'd3; wc88 <= 3'd2; wc89 <= 4'd3; wc90 <= 4'd4; wc91 <= 4'd3; wc92 <= 3'd2; wc93 <= 4'd3; wc94 <= 3'd2; wc95 <= 3'd1; wc96 <= 3'd2; wc97 <= 3'd3; wc98 <= 4'd4; wc99 <= 3'd3; wc100 <= 4'd4; wc101 <= 4'd5; wc102 <= 4'd4; wc103 <= 3'd3; wc104 <= 4'd4; wc105 <= 4'd5; wc106 <= 4'd6; wc107 <= 4'd5; wc108 <= 4'd4; wc109 <= 4'd5; wc110 <= 4'd4; wc111 <= 3'd3; wc112 <= 3'd2; wc113 <= 3'd3; wc114 <= 4'd4; wc115 <= 3'd3; wc116 <= 4'd4; wc117 <= 4'd5; wc118 <= 4'd4; wc119 <= 3'd3; wc120 <= 3'd2; wc121 <= 3'd3; wc122 <= 4'd4; wc123 <= 3'd3; wc124 <= 3'd2; wc125 <= 3'd3; wc126 <= 3'd2; wc127 <= 2'd1; end
            {4'd8, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 4'd3; wc18 <= 4'd4; wc19 <= 4'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 4'd3; wc24 <= 3'd2; wc25 <= 4'd3; wc26 <= 4'd4; wc27 <= 4'd3; wc28 <= 3'd2; wc29 <= 4'd3; wc30 <= 3'd2; wc31 <= 3'd1; wc32 <= 3'd2; wc33 <= 3'd3; wc34 <= 4'd4; wc35 <= 3'd3; wc36 <= 4'd4; wc37 <= 4'd5; wc38 <= 4'd4; wc39 <= 3'd3; wc40 <= 4'd4; wc41 <= 4'd5; wc42 <= 4'd6; wc43 <= 4'd5; wc44 <= 4'd4; wc45 <= 4'd5; wc46 <= 4'd4; wc47 <= 3'd3; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; wc64 <= 2'd1; wc65 <= 3'd2; wc66 <= 3'd3; wc67 <= 3'd2; wc68 <= 3'd3; wc69 <= 4'd4; wc70 <= 3'd3; wc71 <= 3'd2; wc72 <= 3'd3; wc73 <= 4'd4; wc74 <= 4'd5; wc75 <= 4'd4; wc76 <= 3'd3; wc77 <= 4'd4; wc78 <= 3'd3; wc79 <= 3'd2; wc80 <= 3'd3; wc81 <= 4'd4; wc82 <= 4'd5; wc83 <= 4'd4; wc84 <= 4'd5; wc85 <= 4'd6; wc86 <= 4'd5; wc87 <= 4'd4; wc88 <= 3'd3; wc89 <= 4'd4; wc90 <= 4'd5; wc91 <= 4'd4; wc92 <= 3'd3; wc93 <= 4'd4; wc94 <= 3'd3; wc95 <= 3'd2; wc96 <= 3'd3; wc97 <= 3'd4; wc98 <= 4'd5; wc99 <= 3'd4; wc100 <= 4'd5; wc101 <= 4'd6; wc102 <= 4'd5; wc103 <= 3'd4; wc104 <= 4'd5; wc105 <= 4'd6; wc106 <= 4'd7; wc107 <= 4'd6; wc108 <= 4'd5; wc109 <= 4'd6; wc110 <= 4'd5; wc111 <= 3'd4; wc112 <= 3'd3; wc113 <= 3'd4; wc114 <= 4'd5; wc115 <= 3'd4; wc116 <= 4'd5; wc117 <= 4'd6; wc118 <= 4'd5; wc119 <= 3'd4; wc120 <= 3'd3; wc121 <= 3'd4; wc122 <= 4'd5; wc123 <= 3'd4; wc124 <= 3'd3; wc125 <= 3'd4; wc126 <= 3'd3; wc127 <= 2'd2; end
            {4'd8, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 4'd4; wc18 <= 4'd5; wc19 <= 4'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 4'd4; wc24 <= 3'd3; wc25 <= 4'd4; wc26 <= 4'd5; wc27 <= 4'd4; wc28 <= 3'd3; wc29 <= 4'd4; wc30 <= 3'd3; wc31 <= 3'd2; wc32 <= 3'd3; wc33 <= 3'd4; wc34 <= 4'd5; wc35 <= 3'd4; wc36 <= 4'd5; wc37 <= 4'd6; wc38 <= 4'd5; wc39 <= 3'd4; wc40 <= 4'd5; wc41 <= 4'd6; wc42 <= 4'd7; wc43 <= 4'd6; wc44 <= 4'd5; wc45 <= 4'd6; wc46 <= 4'd5; wc47 <= 3'd4; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; wc64 <= 2'd0; wc65 <= 3'd1; wc66 <= 3'd2; wc67 <= 3'd1; wc68 <= 3'd2; wc69 <= 4'd3; wc70 <= 3'd2; wc71 <= 3'd1; wc72 <= 3'd2; wc73 <= 4'd3; wc74 <= 4'd4; wc75 <= 4'd3; wc76 <= 3'd2; wc77 <= 4'd3; wc78 <= 3'd2; wc79 <= 3'd1; wc80 <= 3'd2; wc81 <= 4'd3; wc82 <= 4'd4; wc83 <= 4'd3; wc84 <= 4'd4; wc85 <= 4'd5; wc86 <= 4'd4; wc87 <= 4'd3; wc88 <= 3'd2; wc89 <= 4'd3; wc90 <= 4'd4; wc91 <= 4'd3; wc92 <= 3'd2; wc93 <= 4'd3; wc94 <= 3'd2; wc95 <= 3'd1; wc96 <= 3'd2; wc97 <= 3'd3; wc98 <= 4'd4; wc99 <= 3'd3; wc100 <= 4'd4; wc101 <= 4'd5; wc102 <= 4'd4; wc103 <= 3'd3; wc104 <= 4'd4; wc105 <= 4'd5; wc106 <= 4'd6; wc107 <= 4'd5; wc108 <= 4'd4; wc109 <= 4'd5; wc110 <= 4'd4; wc111 <= 3'd3; wc112 <= 3'd2; wc113 <= 3'd3; wc114 <= 4'd4; wc115 <= 3'd3; wc116 <= 4'd4; wc117 <= 4'd5; wc118 <= 4'd4; wc119 <= 3'd3; wc120 <= 3'd2; wc121 <= 3'd3; wc122 <= 4'd4; wc123 <= 3'd3; wc124 <= 3'd2; wc125 <= 3'd3; wc126 <= 3'd2; wc127 <= 2'd1; end
            {4'd9, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 4'd3; wc18 <= 4'd4; wc19 <= 4'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 4'd3; wc24 <= 3'd2; wc25 <= 4'd3; wc26 <= 4'd4; wc27 <= 4'd3; wc28 <= 3'd2; wc29 <= 4'd3; wc30 <= 3'd2; wc31 <= 3'd1; wc32 <= 3'd2; wc33 <= 3'd3; wc34 <= 4'd4; wc35 <= 3'd3; wc36 <= 4'd4; wc37 <= 4'd5; wc38 <= 4'd4; wc39 <= 3'd3; wc40 <= 4'd4; wc41 <= 4'd5; wc42 <= 4'd6; wc43 <= 4'd5; wc44 <= 4'd4; wc45 <= 4'd5; wc46 <= 4'd4; wc47 <= 3'd3; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; wc64 <= 2'd1; wc65 <= 3'd2; wc66 <= 3'd3; wc67 <= 3'd2; wc68 <= 3'd3; wc69 <= 4'd4; wc70 <= 3'd3; wc71 <= 3'd2; wc72 <= 3'd3; wc73 <= 4'd4; wc74 <= 4'd5; wc75 <= 4'd4; wc76 <= 3'd3; wc77 <= 4'd4; wc78 <= 3'd3; wc79 <= 3'd2; wc80 <= 3'd3; wc81 <= 4'd4; wc82 <= 4'd5; wc83 <= 4'd4; wc84 <= 4'd5; wc85 <= 4'd6; wc86 <= 4'd5; wc87 <= 4'd4; wc88 <= 3'd3; wc89 <= 4'd4; wc90 <= 4'd5; wc91 <= 4'd4; wc92 <= 3'd3; wc93 <= 4'd4; wc94 <= 3'd3; wc95 <= 3'd2; wc96 <= 3'd3; wc97 <= 3'd4; wc98 <= 4'd5; wc99 <= 3'd4; wc100 <= 4'd5; wc101 <= 4'd6; wc102 <= 4'd5; wc103 <= 3'd4; wc104 <= 4'd5; wc105 <= 4'd6; wc106 <= 4'd7; wc107 <= 4'd6; wc108 <= 4'd5; wc109 <= 4'd6; wc110 <= 4'd5; wc111 <= 3'd4; wc112 <= 3'd3; wc113 <= 3'd4; wc114 <= 4'd5; wc115 <= 3'd4; wc116 <= 4'd5; wc117 <= 4'd6; wc118 <= 4'd5; wc119 <= 3'd4; wc120 <= 3'd3; wc121 <= 3'd4; wc122 <= 4'd5; wc123 <= 3'd4; wc124 <= 3'd3; wc125 <= 3'd4; wc126 <= 3'd3; wc127 <= 2'd2; end
            {4'd9, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 4'd4; wc18 <= 4'd5; wc19 <= 4'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 4'd4; wc24 <= 3'd3; wc25 <= 4'd4; wc26 <= 4'd5; wc27 <= 4'd4; wc28 <= 3'd3; wc29 <= 4'd4; wc30 <= 3'd3; wc31 <= 3'd2; wc32 <= 3'd3; wc33 <= 3'd4; wc34 <= 4'd5; wc35 <= 3'd4; wc36 <= 4'd5; wc37 <= 4'd6; wc38 <= 4'd5; wc39 <= 3'd4; wc40 <= 4'd5; wc41 <= 4'd6; wc42 <= 4'd7; wc43 <= 4'd6; wc44 <= 4'd5; wc45 <= 4'd6; wc46 <= 4'd5; wc47 <= 3'd4; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; wc64 <= 2'd0; wc65 <= 3'd1; wc66 <= 3'd2; wc67 <= 3'd1; wc68 <= 3'd2; wc69 <= 4'd3; wc70 <= 3'd2; wc71 <= 3'd1; wc72 <= 3'd2; wc73 <= 4'd3; wc74 <= 4'd4; wc75 <= 4'd3; wc76 <= 3'd2; wc77 <= 4'd3; wc78 <= 3'd2; wc79 <= 3'd1; wc80 <= 3'd2; wc81 <= 4'd3; wc82 <= 4'd4; wc83 <= 4'd3; wc84 <= 4'd4; wc85 <= 4'd5; wc86 <= 4'd4; wc87 <= 4'd3; wc88 <= 3'd2; wc89 <= 4'd3; wc90 <= 4'd4; wc91 <= 4'd3; wc92 <= 3'd2; wc93 <= 4'd3; wc94 <= 3'd2; wc95 <= 3'd1; wc96 <= 3'd2; wc97 <= 3'd3; wc98 <= 4'd4; wc99 <= 3'd3; wc100 <= 4'd4; wc101 <= 4'd5; wc102 <= 4'd4; wc103 <= 3'd3; wc104 <= 4'd4; wc105 <= 4'd5; wc106 <= 4'd6; wc107 <= 4'd5; wc108 <= 4'd4; wc109 <= 4'd5; wc110 <= 4'd4; wc111 <= 3'd3; wc112 <= 3'd2; wc113 <= 3'd3; wc114 <= 4'd4; wc115 <= 3'd3; wc116 <= 4'd4; wc117 <= 4'd5; wc118 <= 4'd4; wc119 <= 3'd3; wc120 <= 3'd2; wc121 <= 3'd3; wc122 <= 4'd4; wc123 <= 3'd3; wc124 <= 3'd2; wc125 <= 3'd3; wc126 <= 3'd2; wc127 <= 2'd1; end
            {4'd10, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 4'd3; wc18 <= 4'd4; wc19 <= 4'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 4'd3; wc24 <= 3'd2; wc25 <= 4'd3; wc26 <= 4'd4; wc27 <= 4'd3; wc28 <= 3'd2; wc29 <= 4'd3; wc30 <= 3'd2; wc31 <= 3'd1; wc32 <= 3'd2; wc33 <= 3'd3; wc34 <= 4'd4; wc35 <= 3'd3; wc36 <= 4'd4; wc37 <= 4'd5; wc38 <= 4'd4; wc39 <= 3'd3; wc40 <= 4'd4; wc41 <= 4'd5; wc42 <= 4'd6; wc43 <= 4'd5; wc44 <= 4'd4; wc45 <= 4'd5; wc46 <= 4'd4; wc47 <= 3'd3; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; wc64 <= 2'd1; wc65 <= 3'd2; wc66 <= 3'd3; wc67 <= 3'd2; wc68 <= 3'd3; wc69 <= 4'd4; wc70 <= 3'd3; wc71 <= 3'd2; wc72 <= 3'd3; wc73 <= 4'd4; wc74 <= 4'd5; wc75 <= 4'd4; wc76 <= 3'd3; wc77 <= 4'd4; wc78 <= 3'd3; wc79 <= 3'd2; wc80 <= 3'd3; wc81 <= 4'd4; wc82 <= 4'd5; wc83 <= 4'd4; wc84 <= 4'd5; wc85 <= 4'd6; wc86 <= 4'd5; wc87 <= 4'd4; wc88 <= 3'd3; wc89 <= 4'd4; wc90 <= 4'd5; wc91 <= 4'd4; wc92 <= 3'd3; wc93 <= 4'd4; wc94 <= 3'd3; wc95 <= 3'd2; wc96 <= 3'd3; wc97 <= 3'd4; wc98 <= 4'd5; wc99 <= 3'd4; wc100 <= 4'd5; wc101 <= 4'd6; wc102 <= 4'd5; wc103 <= 3'd4; wc104 <= 4'd5; wc105 <= 4'd6; wc106 <= 4'd7; wc107 <= 4'd6; wc108 <= 4'd5; wc109 <= 4'd6; wc110 <= 4'd5; wc111 <= 3'd4; wc112 <= 3'd3; wc113 <= 3'd4; wc114 <= 4'd5; wc115 <= 3'd4; wc116 <= 4'd5; wc117 <= 4'd6; wc118 <= 4'd5; wc119 <= 3'd4; wc120 <= 3'd3; wc121 <= 3'd4; wc122 <= 4'd5; wc123 <= 3'd4; wc124 <= 3'd3; wc125 <= 3'd4; wc126 <= 3'd3; wc127 <= 2'd2; end
            {4'd10, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 4'd4; wc18 <= 4'd5; wc19 <= 4'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 4'd4; wc24 <= 3'd3; wc25 <= 4'd4; wc26 <= 4'd5; wc27 <= 4'd4; wc28 <= 3'd3; wc29 <= 4'd4; wc30 <= 3'd3; wc31 <= 3'd2; wc32 <= 3'd3; wc33 <= 3'd4; wc34 <= 4'd5; wc35 <= 3'd4; wc36 <= 4'd5; wc37 <= 4'd6; wc38 <= 4'd5; wc39 <= 3'd4; wc40 <= 4'd5; wc41 <= 4'd6; wc42 <= 4'd7; wc43 <= 4'd6; wc44 <= 4'd5; wc45 <= 4'd6; wc46 <= 4'd5; wc47 <= 3'd4; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; wc64 <= 2'd0; wc65 <= 3'd1; wc66 <= 3'd2; wc67 <= 3'd1; wc68 <= 3'd2; wc69 <= 4'd3; wc70 <= 3'd2; wc71 <= 3'd1; wc72 <= 3'd2; wc73 <= 4'd3; wc74 <= 4'd4; wc75 <= 4'd3; wc76 <= 3'd2; wc77 <= 4'd3; wc78 <= 3'd2; wc79 <= 3'd1; wc80 <= 3'd2; wc81 <= 4'd3; wc82 <= 4'd4; wc83 <= 4'd3; wc84 <= 4'd4; wc85 <= 4'd5; wc86 <= 4'd4; wc87 <= 4'd3; wc88 <= 3'd2; wc89 <= 4'd3; wc90 <= 4'd4; wc91 <= 4'd3; wc92 <= 3'd2; wc93 <= 4'd3; wc94 <= 3'd2; wc95 <= 3'd1; wc96 <= 3'd2; wc97 <= 3'd3; wc98 <= 4'd4; wc99 <= 3'd3; wc100 <= 4'd4; wc101 <= 4'd5; wc102 <= 4'd4; wc103 <= 3'd3; wc104 <= 4'd4; wc105 <= 4'd5; wc106 <= 4'd6; wc107 <= 4'd5; wc108 <= 4'd4; wc109 <= 4'd5; wc110 <= 4'd4; wc111 <= 3'd3; wc112 <= 3'd2; wc113 <= 3'd3; wc114 <= 4'd4; wc115 <= 3'd3; wc116 <= 4'd4; wc117 <= 4'd5; wc118 <= 4'd4; wc119 <= 3'd3; wc120 <= 3'd2; wc121 <= 3'd3; wc122 <= 4'd4; wc123 <= 3'd3; wc124 <= 3'd2; wc125 <= 3'd3; wc126 <= 3'd2; wc127 <= 2'd1; end
            {4'd11, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 4'd3; wc18 <= 4'd4; wc19 <= 4'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 4'd3; wc24 <= 3'd2; wc25 <= 4'd3; wc26 <= 4'd4; wc27 <= 4'd3; wc28 <= 3'd2; wc29 <= 4'd3; wc30 <= 3'd2; wc31 <= 3'd1; wc32 <= 3'd2; wc33 <= 3'd3; wc34 <= 4'd4; wc35 <= 3'd3; wc36 <= 4'd4; wc37 <= 4'd5; wc38 <= 4'd4; wc39 <= 3'd3; wc40 <= 4'd4; wc41 <= 4'd5; wc42 <= 4'd6; wc43 <= 4'd5; wc44 <= 4'd4; wc45 <= 4'd5; wc46 <= 4'd4; wc47 <= 3'd3; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; wc64 <= 2'd1; wc65 <= 3'd2; wc66 <= 3'd3; wc67 <= 3'd2; wc68 <= 3'd3; wc69 <= 4'd4; wc70 <= 3'd3; wc71 <= 3'd2; wc72 <= 3'd3; wc73 <= 4'd4; wc74 <= 4'd5; wc75 <= 4'd4; wc76 <= 3'd3; wc77 <= 4'd4; wc78 <= 3'd3; wc79 <= 3'd2; wc80 <= 3'd3; wc81 <= 4'd4; wc82 <= 4'd5; wc83 <= 4'd4; wc84 <= 4'd5; wc85 <= 4'd6; wc86 <= 4'd5; wc87 <= 4'd4; wc88 <= 3'd3; wc89 <= 4'd4; wc90 <= 4'd5; wc91 <= 4'd4; wc92 <= 3'd3; wc93 <= 4'd4; wc94 <= 3'd3; wc95 <= 3'd2; wc96 <= 3'd3; wc97 <= 3'd4; wc98 <= 4'd5; wc99 <= 3'd4; wc100 <= 4'd5; wc101 <= 4'd6; wc102 <= 4'd5; wc103 <= 3'd4; wc104 <= 4'd5; wc105 <= 4'd6; wc106 <= 4'd7; wc107 <= 4'd6; wc108 <= 4'd5; wc109 <= 4'd6; wc110 <= 4'd5; wc111 <= 3'd4; wc112 <= 3'd3; wc113 <= 3'd4; wc114 <= 4'd5; wc115 <= 3'd4; wc116 <= 4'd5; wc117 <= 4'd6; wc118 <= 4'd5; wc119 <= 3'd4; wc120 <= 3'd3; wc121 <= 3'd4; wc122 <= 4'd5; wc123 <= 3'd4; wc124 <= 3'd3; wc125 <= 3'd4; wc126 <= 3'd3; wc127 <= 2'd2; end
            {4'd11, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 4'd4; wc18 <= 4'd5; wc19 <= 4'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 4'd4; wc24 <= 3'd3; wc25 <= 4'd4; wc26 <= 4'd5; wc27 <= 4'd4; wc28 <= 3'd3; wc29 <= 4'd4; wc30 <= 3'd3; wc31 <= 3'd2; wc32 <= 3'd3; wc33 <= 3'd4; wc34 <= 4'd5; wc35 <= 3'd4; wc36 <= 4'd5; wc37 <= 4'd6; wc38 <= 4'd5; wc39 <= 3'd4; wc40 <= 4'd5; wc41 <= 4'd6; wc42 <= 4'd7; wc43 <= 4'd6; wc44 <= 4'd5; wc45 <= 4'd6; wc46 <= 4'd5; wc47 <= 3'd4; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; wc64 <= 2'd0; wc65 <= 3'd1; wc66 <= 3'd2; wc67 <= 3'd1; wc68 <= 3'd2; wc69 <= 4'd3; wc70 <= 3'd2; wc71 <= 3'd1; wc72 <= 3'd2; wc73 <= 4'd3; wc74 <= 4'd4; wc75 <= 4'd3; wc76 <= 3'd2; wc77 <= 4'd3; wc78 <= 3'd2; wc79 <= 3'd1; wc80 <= 3'd2; wc81 <= 4'd3; wc82 <= 4'd4; wc83 <= 4'd3; wc84 <= 4'd4; wc85 <= 4'd5; wc86 <= 4'd4; wc87 <= 4'd3; wc88 <= 3'd2; wc89 <= 4'd3; wc90 <= 4'd4; wc91 <= 4'd3; wc92 <= 3'd2; wc93 <= 4'd3; wc94 <= 3'd2; wc95 <= 3'd1; wc96 <= 3'd2; wc97 <= 3'd3; wc98 <= 4'd4; wc99 <= 3'd3; wc100 <= 4'd4; wc101 <= 4'd5; wc102 <= 4'd4; wc103 <= 3'd3; wc104 <= 4'd4; wc105 <= 4'd5; wc106 <= 4'd6; wc107 <= 4'd5; wc108 <= 4'd4; wc109 <= 4'd5; wc110 <= 4'd4; wc111 <= 3'd3; wc112 <= 3'd2; wc113 <= 3'd3; wc114 <= 4'd4; wc115 <= 3'd3; wc116 <= 4'd4; wc117 <= 4'd5; wc118 <= 4'd4; wc119 <= 3'd3; wc120 <= 3'd2; wc121 <= 3'd3; wc122 <= 4'd4; wc123 <= 3'd3; wc124 <= 3'd2; wc125 <= 3'd3; wc126 <= 3'd2; wc127 <= 2'd1; end
            {4'd12, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 4'd3; wc18 <= 4'd4; wc19 <= 4'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 4'd3; wc24 <= 3'd2; wc25 <= 4'd3; wc26 <= 4'd4; wc27 <= 4'd3; wc28 <= 3'd2; wc29 <= 4'd3; wc30 <= 3'd2; wc31 <= 3'd1; wc32 <= 3'd2; wc33 <= 3'd3; wc34 <= 4'd4; wc35 <= 3'd3; wc36 <= 4'd4; wc37 <= 4'd5; wc38 <= 4'd4; wc39 <= 3'd3; wc40 <= 4'd4; wc41 <= 4'd5; wc42 <= 4'd6; wc43 <= 4'd5; wc44 <= 4'd4; wc45 <= 4'd5; wc46 <= 4'd4; wc47 <= 3'd3; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; wc64 <= 2'd1; wc65 <= 3'd2; wc66 <= 3'd3; wc67 <= 3'd2; wc68 <= 3'd3; wc69 <= 4'd4; wc70 <= 3'd3; wc71 <= 3'd2; wc72 <= 3'd3; wc73 <= 4'd4; wc74 <= 4'd5; wc75 <= 4'd4; wc76 <= 3'd3; wc77 <= 4'd4; wc78 <= 3'd3; wc79 <= 3'd2; wc80 <= 3'd3; wc81 <= 4'd4; wc82 <= 4'd5; wc83 <= 4'd4; wc84 <= 4'd5; wc85 <= 4'd6; wc86 <= 4'd5; wc87 <= 4'd4; wc88 <= 3'd3; wc89 <= 4'd4; wc90 <= 4'd5; wc91 <= 4'd4; wc92 <= 3'd3; wc93 <= 4'd4; wc94 <= 3'd3; wc95 <= 3'd2; wc96 <= 3'd3; wc97 <= 3'd4; wc98 <= 4'd5; wc99 <= 3'd4; wc100 <= 4'd5; wc101 <= 4'd6; wc102 <= 4'd5; wc103 <= 3'd4; wc104 <= 4'd5; wc105 <= 4'd6; wc106 <= 4'd7; wc107 <= 4'd6; wc108 <= 4'd5; wc109 <= 4'd6; wc110 <= 4'd5; wc111 <= 3'd4; wc112 <= 3'd3; wc113 <= 3'd4; wc114 <= 4'd5; wc115 <= 3'd4; wc116 <= 4'd5; wc117 <= 4'd6; wc118 <= 4'd5; wc119 <= 3'd4; wc120 <= 3'd3; wc121 <= 3'd4; wc122 <= 4'd5; wc123 <= 3'd4; wc124 <= 3'd3; wc125 <= 3'd4; wc126 <= 3'd3; wc127 <= 2'd2; end
            {4'd12, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 4'd4; wc18 <= 4'd5; wc19 <= 4'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 4'd4; wc24 <= 3'd3; wc25 <= 4'd4; wc26 <= 4'd5; wc27 <= 4'd4; wc28 <= 3'd3; wc29 <= 4'd4; wc30 <= 3'd3; wc31 <= 3'd2; wc32 <= 3'd3; wc33 <= 3'd4; wc34 <= 4'd5; wc35 <= 3'd4; wc36 <= 4'd5; wc37 <= 4'd6; wc38 <= 4'd5; wc39 <= 3'd4; wc40 <= 4'd5; wc41 <= 4'd6; wc42 <= 4'd7; wc43 <= 4'd6; wc44 <= 4'd5; wc45 <= 4'd6; wc46 <= 4'd5; wc47 <= 3'd4; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; wc64 <= 2'd0; wc65 <= 3'd1; wc66 <= 3'd2; wc67 <= 3'd1; wc68 <= 3'd2; wc69 <= 4'd3; wc70 <= 3'd2; wc71 <= 3'd1; wc72 <= 3'd2; wc73 <= 4'd3; wc74 <= 4'd4; wc75 <= 4'd3; wc76 <= 3'd2; wc77 <= 4'd3; wc78 <= 3'd2; wc79 <= 3'd1; wc80 <= 3'd2; wc81 <= 4'd3; wc82 <= 4'd4; wc83 <= 4'd3; wc84 <= 4'd4; wc85 <= 4'd5; wc86 <= 4'd4; wc87 <= 4'd3; wc88 <= 3'd2; wc89 <= 4'd3; wc90 <= 4'd4; wc91 <= 4'd3; wc92 <= 3'd2; wc93 <= 4'd3; wc94 <= 3'd2; wc95 <= 3'd1; wc96 <= 3'd2; wc97 <= 3'd3; wc98 <= 4'd4; wc99 <= 3'd3; wc100 <= 4'd4; wc101 <= 4'd5; wc102 <= 4'd4; wc103 <= 3'd3; wc104 <= 4'd4; wc105 <= 4'd5; wc106 <= 4'd6; wc107 <= 4'd5; wc108 <= 4'd4; wc109 <= 4'd5; wc110 <= 4'd4; wc111 <= 3'd3; wc112 <= 3'd2; wc113 <= 3'd3; wc114 <= 4'd4; wc115 <= 3'd3; wc116 <= 4'd4; wc117 <= 4'd5; wc118 <= 4'd4; wc119 <= 3'd3; wc120 <= 3'd2; wc121 <= 3'd3; wc122 <= 4'd4; wc123 <= 3'd3; wc124 <= 3'd2; wc125 <= 3'd3; wc126 <= 3'd2; wc127 <= 2'd1; end
            {4'd13, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 4'd3; wc18 <= 4'd4; wc19 <= 4'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 4'd3; wc24 <= 3'd2; wc25 <= 4'd3; wc26 <= 4'd4; wc27 <= 4'd3; wc28 <= 3'd2; wc29 <= 4'd3; wc30 <= 3'd2; wc31 <= 3'd1; wc32 <= 3'd2; wc33 <= 3'd3; wc34 <= 4'd4; wc35 <= 3'd3; wc36 <= 4'd4; wc37 <= 4'd5; wc38 <= 4'd4; wc39 <= 3'd3; wc40 <= 4'd4; wc41 <= 4'd5; wc42 <= 4'd6; wc43 <= 4'd5; wc44 <= 4'd4; wc45 <= 4'd5; wc46 <= 4'd4; wc47 <= 3'd3; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; wc64 <= 2'd1; wc65 <= 3'd2; wc66 <= 3'd3; wc67 <= 3'd2; wc68 <= 3'd3; wc69 <= 4'd4; wc70 <= 3'd3; wc71 <= 3'd2; wc72 <= 3'd3; wc73 <= 4'd4; wc74 <= 4'd5; wc75 <= 4'd4; wc76 <= 3'd3; wc77 <= 4'd4; wc78 <= 3'd3; wc79 <= 3'd2; wc80 <= 3'd3; wc81 <= 4'd4; wc82 <= 4'd5; wc83 <= 4'd4; wc84 <= 4'd5; wc85 <= 4'd6; wc86 <= 4'd5; wc87 <= 4'd4; wc88 <= 3'd3; wc89 <= 4'd4; wc90 <= 4'd5; wc91 <= 4'd4; wc92 <= 3'd3; wc93 <= 4'd4; wc94 <= 3'd3; wc95 <= 3'd2; wc96 <= 3'd3; wc97 <= 3'd4; wc98 <= 4'd5; wc99 <= 3'd4; wc100 <= 4'd5; wc101 <= 4'd6; wc102 <= 4'd5; wc103 <= 3'd4; wc104 <= 4'd5; wc105 <= 4'd6; wc106 <= 4'd7; wc107 <= 4'd6; wc108 <= 4'd5; wc109 <= 4'd6; wc110 <= 4'd5; wc111 <= 3'd4; wc112 <= 3'd3; wc113 <= 3'd4; wc114 <= 4'd5; wc115 <= 3'd4; wc116 <= 4'd5; wc117 <= 4'd6; wc118 <= 4'd5; wc119 <= 3'd4; wc120 <= 3'd3; wc121 <= 3'd4; wc122 <= 4'd5; wc123 <= 3'd4; wc124 <= 3'd3; wc125 <= 3'd4; wc126 <= 3'd3; wc127 <= 2'd2; end
            {4'd13, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 4'd4; wc18 <= 4'd5; wc19 <= 4'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 4'd4; wc24 <= 3'd3; wc25 <= 4'd4; wc26 <= 4'd5; wc27 <= 4'd4; wc28 <= 3'd3; wc29 <= 4'd4; wc30 <= 3'd3; wc31 <= 3'd2; wc32 <= 3'd3; wc33 <= 3'd4; wc34 <= 4'd5; wc35 <= 3'd4; wc36 <= 4'd5; wc37 <= 4'd6; wc38 <= 4'd5; wc39 <= 3'd4; wc40 <= 4'd5; wc41 <= 4'd6; wc42 <= 4'd7; wc43 <= 4'd6; wc44 <= 4'd5; wc45 <= 4'd6; wc46 <= 4'd5; wc47 <= 3'd4; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; wc64 <= 2'd0; wc65 <= 3'd1; wc66 <= 3'd2; wc67 <= 3'd1; wc68 <= 3'd2; wc69 <= 4'd3; wc70 <= 3'd2; wc71 <= 3'd1; wc72 <= 3'd2; wc73 <= 4'd3; wc74 <= 4'd4; wc75 <= 4'd3; wc76 <= 3'd2; wc77 <= 4'd3; wc78 <= 3'd2; wc79 <= 3'd1; wc80 <= 3'd2; wc81 <= 4'd3; wc82 <= 4'd4; wc83 <= 4'd3; wc84 <= 4'd4; wc85 <= 4'd5; wc86 <= 4'd4; wc87 <= 4'd3; wc88 <= 3'd2; wc89 <= 4'd3; wc90 <= 4'd4; wc91 <= 4'd3; wc92 <= 3'd2; wc93 <= 4'd3; wc94 <= 3'd2; wc95 <= 3'd1; wc96 <= 3'd2; wc97 <= 3'd3; wc98 <= 4'd4; wc99 <= 3'd3; wc100 <= 4'd4; wc101 <= 4'd5; wc102 <= 4'd4; wc103 <= 3'd3; wc104 <= 4'd4; wc105 <= 4'd5; wc106 <= 4'd6; wc107 <= 4'd5; wc108 <= 4'd4; wc109 <= 4'd5; wc110 <= 4'd4; wc111 <= 3'd3; wc112 <= 3'd2; wc113 <= 3'd3; wc114 <= 4'd4; wc115 <= 3'd3; wc116 <= 4'd4; wc117 <= 4'd5; wc118 <= 4'd4; wc119 <= 3'd3; wc120 <= 3'd2; wc121 <= 3'd3; wc122 <= 4'd4; wc123 <= 3'd3; wc124 <= 3'd2; wc125 <= 3'd3; wc126 <= 3'd2; wc127 <= 2'd1; end
            {4'd14, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 4'd3; wc18 <= 4'd4; wc19 <= 4'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 4'd3; wc24 <= 3'd2; wc25 <= 4'd3; wc26 <= 4'd4; wc27 <= 4'd3; wc28 <= 3'd2; wc29 <= 4'd3; wc30 <= 3'd2; wc31 <= 3'd1; wc32 <= 3'd2; wc33 <= 3'd3; wc34 <= 4'd4; wc35 <= 3'd3; wc36 <= 4'd4; wc37 <= 4'd5; wc38 <= 4'd4; wc39 <= 3'd3; wc40 <= 4'd4; wc41 <= 4'd5; wc42 <= 4'd6; wc43 <= 4'd5; wc44 <= 4'd4; wc45 <= 4'd5; wc46 <= 4'd4; wc47 <= 3'd3; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; wc64 <= 2'd1; wc65 <= 3'd2; wc66 <= 3'd3; wc67 <= 3'd2; wc68 <= 3'd3; wc69 <= 4'd4; wc70 <= 3'd3; wc71 <= 3'd2; wc72 <= 3'd3; wc73 <= 4'd4; wc74 <= 4'd5; wc75 <= 4'd4; wc76 <= 3'd3; wc77 <= 4'd4; wc78 <= 3'd3; wc79 <= 3'd2; wc80 <= 3'd3; wc81 <= 4'd4; wc82 <= 4'd5; wc83 <= 4'd4; wc84 <= 4'd5; wc85 <= 4'd6; wc86 <= 4'd5; wc87 <= 4'd4; wc88 <= 3'd3; wc89 <= 4'd4; wc90 <= 4'd5; wc91 <= 4'd4; wc92 <= 3'd3; wc93 <= 4'd4; wc94 <= 3'd3; wc95 <= 3'd2; wc96 <= 3'd3; wc97 <= 3'd4; wc98 <= 4'd5; wc99 <= 3'd4; wc100 <= 4'd5; wc101 <= 4'd6; wc102 <= 4'd5; wc103 <= 3'd4; wc104 <= 4'd5; wc105 <= 4'd6; wc106 <= 4'd7; wc107 <= 4'd6; wc108 <= 4'd5; wc109 <= 4'd6; wc110 <= 4'd5; wc111 <= 3'd4; wc112 <= 3'd3; wc113 <= 3'd4; wc114 <= 4'd5; wc115 <= 3'd4; wc116 <= 4'd5; wc117 <= 4'd6; wc118 <= 4'd5; wc119 <= 3'd4; wc120 <= 3'd3; wc121 <= 3'd4; wc122 <= 4'd5; wc123 <= 3'd4; wc124 <= 3'd3; wc125 <= 3'd4; wc126 <= 3'd3; wc127 <= 2'd2; end
            {4'd14, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 4'd4; wc18 <= 4'd5; wc19 <= 4'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 4'd4; wc24 <= 3'd3; wc25 <= 4'd4; wc26 <= 4'd5; wc27 <= 4'd4; wc28 <= 3'd3; wc29 <= 4'd4; wc30 <= 3'd3; wc31 <= 3'd2; wc32 <= 3'd3; wc33 <= 3'd4; wc34 <= 4'd5; wc35 <= 3'd4; wc36 <= 4'd5; wc37 <= 4'd6; wc38 <= 4'd5; wc39 <= 3'd4; wc40 <= 4'd5; wc41 <= 4'd6; wc42 <= 4'd7; wc43 <= 4'd6; wc44 <= 4'd5; wc45 <= 4'd6; wc46 <= 4'd5; wc47 <= 3'd4; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; wc64 <= 2'd0; wc65 <= 3'd1; wc66 <= 3'd2; wc67 <= 3'd1; wc68 <= 3'd2; wc69 <= 4'd3; wc70 <= 3'd2; wc71 <= 3'd1; wc72 <= 3'd2; wc73 <= 4'd3; wc74 <= 4'd4; wc75 <= 4'd3; wc76 <= 3'd2; wc77 <= 4'd3; wc78 <= 3'd2; wc79 <= 3'd1; wc80 <= 3'd2; wc81 <= 4'd3; wc82 <= 4'd4; wc83 <= 4'd3; wc84 <= 4'd4; wc85 <= 4'd5; wc86 <= 4'd4; wc87 <= 4'd3; wc88 <= 3'd2; wc89 <= 4'd3; wc90 <= 4'd4; wc91 <= 4'd3; wc92 <= 3'd2; wc93 <= 4'd3; wc94 <= 3'd2; wc95 <= 3'd1; wc96 <= 3'd2; wc97 <= 3'd3; wc98 <= 4'd4; wc99 <= 3'd3; wc100 <= 4'd4; wc101 <= 4'd5; wc102 <= 4'd4; wc103 <= 3'd3; wc104 <= 4'd4; wc105 <= 4'd5; wc106 <= 4'd6; wc107 <= 4'd5; wc108 <= 4'd4; wc109 <= 4'd5; wc110 <= 4'd4; wc111 <= 3'd3; wc112 <= 3'd2; wc113 <= 3'd3; wc114 <= 4'd4; wc115 <= 3'd3; wc116 <= 4'd4; wc117 <= 4'd5; wc118 <= 4'd4; wc119 <= 3'd3; wc120 <= 3'd2; wc121 <= 3'd3; wc122 <= 4'd4; wc123 <= 3'd3; wc124 <= 3'd2; wc125 <= 3'd3; wc126 <= 3'd2; wc127 <= 2'd1; end
            {4'd15, 1'b0}: begin wc0 <= 2'd0; wc1 <= 3'd1; wc2 <= 3'd2; wc3 <= 3'd1; wc4 <= 3'd2; wc5 <= 4'd3; wc6 <= 3'd2; wc7 <= 3'd1; wc8 <= 3'd2; wc9 <= 4'd3; wc10 <= 4'd4; wc11 <= 4'd3; wc12 <= 3'd2; wc13 <= 4'd3; wc14 <= 3'd2; wc15 <= 3'd1; wc16 <= 3'd2; wc17 <= 4'd3; wc18 <= 4'd4; wc19 <= 4'd3; wc20 <= 4'd4; wc21 <= 4'd5; wc22 <= 4'd4; wc23 <= 4'd3; wc24 <= 3'd2; wc25 <= 4'd3; wc26 <= 4'd4; wc27 <= 4'd3; wc28 <= 3'd2; wc29 <= 4'd3; wc30 <= 3'd2; wc31 <= 3'd1; wc32 <= 3'd2; wc33 <= 3'd3; wc34 <= 4'd4; wc35 <= 3'd3; wc36 <= 4'd4; wc37 <= 4'd5; wc38 <= 4'd4; wc39 <= 3'd3; wc40 <= 4'd4; wc41 <= 4'd5; wc42 <= 4'd6; wc43 <= 4'd5; wc44 <= 4'd4; wc45 <= 4'd5; wc46 <= 4'd4; wc47 <= 3'd3; wc48 <= 3'd2; wc49 <= 3'd3; wc50 <= 4'd4; wc51 <= 3'd3; wc52 <= 4'd4; wc53 <= 4'd5; wc54 <= 4'd4; wc55 <= 3'd3; wc56 <= 3'd2; wc57 <= 3'd3; wc58 <= 4'd4; wc59 <= 3'd3; wc60 <= 3'd2; wc61 <= 3'd3; wc62 <= 3'd2; wc63 <= 2'd1; wc64 <= 2'd1; wc65 <= 3'd2; wc66 <= 3'd3; wc67 <= 3'd2; wc68 <= 3'd3; wc69 <= 4'd4; wc70 <= 3'd3; wc71 <= 3'd2; wc72 <= 3'd3; wc73 <= 4'd4; wc74 <= 4'd5; wc75 <= 4'd4; wc76 <= 3'd3; wc77 <= 4'd4; wc78 <= 3'd3; wc79 <= 3'd2; wc80 <= 3'd3; wc81 <= 4'd4; wc82 <= 4'd5; wc83 <= 4'd4; wc84 <= 4'd5; wc85 <= 4'd6; wc86 <= 4'd5; wc87 <= 4'd4; wc88 <= 3'd3; wc89 <= 4'd4; wc90 <= 4'd5; wc91 <= 4'd4; wc92 <= 3'd3; wc93 <= 4'd4; wc94 <= 3'd3; wc95 <= 3'd2; wc96 <= 3'd3; wc97 <= 3'd4; wc98 <= 4'd5; wc99 <= 3'd4; wc100 <= 4'd5; wc101 <= 4'd6; wc102 <= 4'd5; wc103 <= 3'd4; wc104 <= 4'd5; wc105 <= 4'd6; wc106 <= 4'd7; wc107 <= 4'd6; wc108 <= 4'd5; wc109 <= 4'd6; wc110 <= 4'd5; wc111 <= 3'd4; wc112 <= 3'd3; wc113 <= 3'd4; wc114 <= 4'd5; wc115 <= 3'd4; wc116 <= 4'd5; wc117 <= 4'd6; wc118 <= 4'd5; wc119 <= 3'd4; wc120 <= 3'd3; wc121 <= 3'd4; wc122 <= 4'd5; wc123 <= 3'd4; wc124 <= 3'd3; wc125 <= 3'd4; wc126 <= 3'd3; wc127 <= 2'd2; end
            {4'd15, 1'b1}: begin wc0 <= 2'd1; wc1 <= 3'd2; wc2 <= 3'd3; wc3 <= 3'd2; wc4 <= 3'd3; wc5 <= 4'd4; wc6 <= 3'd3; wc7 <= 3'd2; wc8 <= 3'd3; wc9 <= 4'd4; wc10 <= 4'd5; wc11 <= 4'd4; wc12 <= 3'd3; wc13 <= 4'd4; wc14 <= 3'd3; wc15 <= 3'd2; wc16 <= 3'd3; wc17 <= 4'd4; wc18 <= 4'd5; wc19 <= 4'd4; wc20 <= 4'd5; wc21 <= 4'd6; wc22 <= 4'd5; wc23 <= 4'd4; wc24 <= 3'd3; wc25 <= 4'd4; wc26 <= 4'd5; wc27 <= 4'd4; wc28 <= 3'd3; wc29 <= 4'd4; wc30 <= 3'd3; wc31 <= 3'd2; wc32 <= 3'd3; wc33 <= 3'd4; wc34 <= 4'd5; wc35 <= 3'd4; wc36 <= 4'd5; wc37 <= 4'd6; wc38 <= 4'd5; wc39 <= 3'd4; wc40 <= 4'd5; wc41 <= 4'd6; wc42 <= 4'd7; wc43 <= 4'd6; wc44 <= 4'd5; wc45 <= 4'd6; wc46 <= 4'd5; wc47 <= 3'd4; wc48 <= 3'd3; wc49 <= 3'd4; wc50 <= 4'd5; wc51 <= 3'd4; wc52 <= 4'd5; wc53 <= 4'd6; wc54 <= 4'd5; wc55 <= 3'd4; wc56 <= 3'd3; wc57 <= 3'd4; wc58 <= 4'd5; wc59 <= 3'd4; wc60 <= 3'd3; wc61 <= 3'd4; wc62 <= 3'd3; wc63 <= 2'd2; wc64 <= 2'd0; wc65 <= 3'd1; wc66 <= 3'd2; wc67 <= 3'd1; wc68 <= 3'd2; wc69 <= 4'd3; wc70 <= 3'd2; wc71 <= 3'd1; wc72 <= 3'd2; wc73 <= 4'd3; wc74 <= 4'd4; wc75 <= 4'd3; wc76 <= 3'd2; wc77 <= 4'd3; wc78 <= 3'd2; wc79 <= 3'd1; wc80 <= 3'd2; wc81 <= 4'd3; wc82 <= 4'd4; wc83 <= 4'd3; wc84 <= 4'd4; wc85 <= 4'd5; wc86 <= 4'd4; wc87 <= 4'd3; wc88 <= 3'd2; wc89 <= 4'd3; wc90 <= 4'd4; wc91 <= 4'd3; wc92 <= 3'd2; wc93 <= 4'd3; wc94 <= 3'd2; wc95 <= 3'd1; wc96 <= 3'd2; wc97 <= 3'd3; wc98 <= 4'd4; wc99 <= 3'd3; wc100 <= 4'd4; wc101 <= 4'd5; wc102 <= 4'd4; wc103 <= 3'd3; wc104 <= 4'd4; wc105 <= 4'd5; wc106 <= 4'd6; wc107 <= 4'd5; wc108 <= 4'd4; wc109 <= 4'd5; wc110 <= 4'd4; wc111 <= 3'd3; wc112 <= 3'd2; wc113 <= 3'd3; wc114 <= 4'd4; wc115 <= 3'd3; wc116 <= 4'd4; wc117 <= 4'd5; wc118 <= 4'd4; wc119 <= 3'd3; wc120 <= 3'd2; wc121 <= 3'd3; wc122 <= 4'd4; wc123 <= 3'd3; wc124 <= 3'd2; wc125 <= 3'd3; wc126 <= 3'd2; wc127 <= 2'd1; end
            default: ;
        endcase
    end
    // ---- data banks: 2 sets x 2B banks (bank of m: (m mod 2B) ^ (parity(m >> (b+1)) << b), address m >> (b+1))
    logic m0_0_we; logic [8:0] m0_0_wa, m0_0_ra; logic [63:0] m0_0_wd, m0_0_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_0 (.clk(clk), .we(m0_0_we), .wa(m0_0_wa), .wd(m0_0_wd), .ra(m0_0_ra), .rd(m0_0_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_0_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_0_ra <= drow;
    logic m0_1_we; logic [8:0] m0_1_wa, m0_1_ra; logic [63:0] m0_1_wd, m0_1_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_1 (.clk(clk), .we(m0_1_we), .wa(m0_1_wa), .wd(m0_1_wd), .ra(m0_1_ra), .rd(m0_1_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_1_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_1_ra <= drow;
    logic m0_2_we; logic [8:0] m0_2_wa, m0_2_ra; logic [63:0] m0_2_wd, m0_2_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_2 (.clk(clk), .we(m0_2_we), .wa(m0_2_wa), .wd(m0_2_wd), .ra(m0_2_ra), .rd(m0_2_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_2_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_2_ra <= drow;
    logic m0_3_we; logic [8:0] m0_3_wa, m0_3_ra; logic [63:0] m0_3_wd, m0_3_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_3 (.clk(clk), .we(m0_3_we), .wa(m0_3_wa), .wd(m0_3_wd), .ra(m0_3_ra), .rd(m0_3_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_3_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_3_ra <= drow;
    logic m0_4_we; logic [8:0] m0_4_wa, m0_4_ra; logic [63:0] m0_4_wd, m0_4_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_4 (.clk(clk), .we(m0_4_we), .wa(m0_4_wa), .wd(m0_4_wd), .ra(m0_4_ra), .rd(m0_4_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_4_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_4_ra <= drow;
    logic m0_5_we; logic [8:0] m0_5_wa, m0_5_ra; logic [63:0] m0_5_wd, m0_5_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_5 (.clk(clk), .we(m0_5_we), .wa(m0_5_wa), .wd(m0_5_wd), .ra(m0_5_ra), .rd(m0_5_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_5_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_5_ra <= drow;
    logic m0_6_we; logic [8:0] m0_6_wa, m0_6_ra; logic [63:0] m0_6_wd, m0_6_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_6 (.clk(clk), .we(m0_6_we), .wa(m0_6_wa), .wd(m0_6_wd), .ra(m0_6_ra), .rd(m0_6_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_6_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_6_ra <= drow;
    logic m0_7_we; logic [8:0] m0_7_wa, m0_7_ra; logic [63:0] m0_7_wd, m0_7_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_7 (.clk(clk), .we(m0_7_we), .wa(m0_7_wa), .wd(m0_7_wd), .ra(m0_7_ra), .rd(m0_7_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_7_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_7_ra <= drow;
    logic m0_8_we; logic [8:0] m0_8_wa, m0_8_ra; logic [63:0] m0_8_wd, m0_8_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_8 (.clk(clk), .we(m0_8_we), .wa(m0_8_wa), .wd(m0_8_wd), .ra(m0_8_ra), .rd(m0_8_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_8_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_8_ra <= drow;
    logic m0_9_we; logic [8:0] m0_9_wa, m0_9_ra; logic [63:0] m0_9_wd, m0_9_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_9 (.clk(clk), .we(m0_9_we), .wa(m0_9_wa), .wd(m0_9_wd), .ra(m0_9_ra), .rd(m0_9_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_9_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_9_ra <= drow;
    logic m0_10_we; logic [8:0] m0_10_wa, m0_10_ra; logic [63:0] m0_10_wd, m0_10_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_10 (.clk(clk), .we(m0_10_we), .wa(m0_10_wa), .wd(m0_10_wd), .ra(m0_10_ra), .rd(m0_10_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_10_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_10_ra <= drow;
    logic m0_11_we; logic [8:0] m0_11_wa, m0_11_ra; logic [63:0] m0_11_wd, m0_11_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_11 (.clk(clk), .we(m0_11_we), .wa(m0_11_wa), .wd(m0_11_wd), .ra(m0_11_ra), .rd(m0_11_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_11_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_11_ra <= drow;
    logic m0_12_we; logic [8:0] m0_12_wa, m0_12_ra; logic [63:0] m0_12_wd, m0_12_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_12 (.clk(clk), .we(m0_12_we), .wa(m0_12_wa), .wd(m0_12_wd), .ra(m0_12_ra), .rd(m0_12_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_12_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_12_ra <= drow;
    logic m0_13_we; logic [8:0] m0_13_wa, m0_13_ra; logic [63:0] m0_13_wd, m0_13_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_13 (.clk(clk), .we(m0_13_we), .wa(m0_13_wa), .wd(m0_13_wd), .ra(m0_13_ra), .rd(m0_13_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_13_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_13_ra <= drow;
    logic m0_14_we; logic [8:0] m0_14_wa, m0_14_ra; logic [63:0] m0_14_wd, m0_14_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_14 (.clk(clk), .we(m0_14_we), .wa(m0_14_wa), .wd(m0_14_wd), .ra(m0_14_ra), .rd(m0_14_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_14_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_14_ra <= drow;
    logic m0_15_we; logic [8:0] m0_15_wa, m0_15_ra; logic [63:0] m0_15_wd, m0_15_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_15 (.clk(clk), .we(m0_15_we), .wa(m0_15_wa), .wd(m0_15_wd), .ra(m0_15_ra), .rd(m0_15_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_15_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_15_ra <= drow;
    logic m0_16_we; logic [8:0] m0_16_wa, m0_16_ra; logic [63:0] m0_16_wd, m0_16_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_16 (.clk(clk), .we(m0_16_we), .wa(m0_16_wa), .wd(m0_16_wd), .ra(m0_16_ra), .rd(m0_16_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_16_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_16_ra <= drow;
    logic m0_17_we; logic [8:0] m0_17_wa, m0_17_ra; logic [63:0] m0_17_wd, m0_17_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_17 (.clk(clk), .we(m0_17_we), .wa(m0_17_wa), .wd(m0_17_wd), .ra(m0_17_ra), .rd(m0_17_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_17_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_17_ra <= drow;
    logic m0_18_we; logic [8:0] m0_18_wa, m0_18_ra; logic [63:0] m0_18_wd, m0_18_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_18 (.clk(clk), .we(m0_18_we), .wa(m0_18_wa), .wd(m0_18_wd), .ra(m0_18_ra), .rd(m0_18_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_18_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_18_ra <= drow;
    logic m0_19_we; logic [8:0] m0_19_wa, m0_19_ra; logic [63:0] m0_19_wd, m0_19_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_19 (.clk(clk), .we(m0_19_we), .wa(m0_19_wa), .wd(m0_19_wd), .ra(m0_19_ra), .rd(m0_19_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_19_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_19_ra <= drow;
    logic m0_20_we; logic [8:0] m0_20_wa, m0_20_ra; logic [63:0] m0_20_wd, m0_20_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_20 (.clk(clk), .we(m0_20_we), .wa(m0_20_wa), .wd(m0_20_wd), .ra(m0_20_ra), .rd(m0_20_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_20_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_20_ra <= drow;
    logic m0_21_we; logic [8:0] m0_21_wa, m0_21_ra; logic [63:0] m0_21_wd, m0_21_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_21 (.clk(clk), .we(m0_21_we), .wa(m0_21_wa), .wd(m0_21_wd), .ra(m0_21_ra), .rd(m0_21_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_21_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_21_ra <= drow;
    logic m0_22_we; logic [8:0] m0_22_wa, m0_22_ra; logic [63:0] m0_22_wd, m0_22_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_22 (.clk(clk), .we(m0_22_we), .wa(m0_22_wa), .wd(m0_22_wd), .ra(m0_22_ra), .rd(m0_22_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_22_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_22_ra <= drow;
    logic m0_23_we; logic [8:0] m0_23_wa, m0_23_ra; logic [63:0] m0_23_wd, m0_23_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_23 (.clk(clk), .we(m0_23_we), .wa(m0_23_wa), .wd(m0_23_wd), .ra(m0_23_ra), .rd(m0_23_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_23_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_23_ra <= drow;
    logic m0_24_we; logic [8:0] m0_24_wa, m0_24_ra; logic [63:0] m0_24_wd, m0_24_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_24 (.clk(clk), .we(m0_24_we), .wa(m0_24_wa), .wd(m0_24_wd), .ra(m0_24_ra), .rd(m0_24_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_24_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_24_ra <= drow;
    logic m0_25_we; logic [8:0] m0_25_wa, m0_25_ra; logic [63:0] m0_25_wd, m0_25_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_25 (.clk(clk), .we(m0_25_we), .wa(m0_25_wa), .wd(m0_25_wd), .ra(m0_25_ra), .rd(m0_25_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_25_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_25_ra <= drow;
    logic m0_26_we; logic [8:0] m0_26_wa, m0_26_ra; logic [63:0] m0_26_wd, m0_26_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_26 (.clk(clk), .we(m0_26_we), .wa(m0_26_wa), .wd(m0_26_wd), .ra(m0_26_ra), .rd(m0_26_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_26_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_26_ra <= drow;
    logic m0_27_we; logic [8:0] m0_27_wa, m0_27_ra; logic [63:0] m0_27_wd, m0_27_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_27 (.clk(clk), .we(m0_27_we), .wa(m0_27_wa), .wd(m0_27_wd), .ra(m0_27_ra), .rd(m0_27_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_27_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_27_ra <= drow;
    logic m0_28_we; logic [8:0] m0_28_wa, m0_28_ra; logic [63:0] m0_28_wd, m0_28_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_28 (.clk(clk), .we(m0_28_we), .wa(m0_28_wa), .wd(m0_28_wd), .ra(m0_28_ra), .rd(m0_28_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_28_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_28_ra <= drow;
    logic m0_29_we; logic [8:0] m0_29_wa, m0_29_ra; logic [63:0] m0_29_wd, m0_29_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_29 (.clk(clk), .we(m0_29_we), .wa(m0_29_wa), .wd(m0_29_wd), .ra(m0_29_ra), .rd(m0_29_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_29_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_29_ra <= drow;
    logic m0_30_we; logic [8:0] m0_30_wa, m0_30_ra; logic [63:0] m0_30_wd, m0_30_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_30 (.clk(clk), .we(m0_30_we), .wa(m0_30_wa), .wd(m0_30_wd), .ra(m0_30_ra), .rd(m0_30_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_30_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_30_ra <= drow;
    logic m0_31_we; logic [8:0] m0_31_wa, m0_31_ra; logic [63:0] m0_31_wd, m0_31_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_31 (.clk(clk), .we(m0_31_we), .wa(m0_31_wa), .wd(m0_31_wd), .ra(m0_31_ra), .rd(m0_31_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_31_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_31_ra <= drow;
    logic m0_32_we; logic [8:0] m0_32_wa, m0_32_ra; logic [63:0] m0_32_wd, m0_32_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_32 (.clk(clk), .we(m0_32_we), .wa(m0_32_wa), .wd(m0_32_wd), .ra(m0_32_ra), .rd(m0_32_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_32_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_32_ra <= drow;
    logic m0_33_we; logic [8:0] m0_33_wa, m0_33_ra; logic [63:0] m0_33_wd, m0_33_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_33 (.clk(clk), .we(m0_33_we), .wa(m0_33_wa), .wd(m0_33_wd), .ra(m0_33_ra), .rd(m0_33_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_33_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_33_ra <= drow;
    logic m0_34_we; logic [8:0] m0_34_wa, m0_34_ra; logic [63:0] m0_34_wd, m0_34_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_34 (.clk(clk), .we(m0_34_we), .wa(m0_34_wa), .wd(m0_34_wd), .ra(m0_34_ra), .rd(m0_34_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_34_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_34_ra <= drow;
    logic m0_35_we; logic [8:0] m0_35_wa, m0_35_ra; logic [63:0] m0_35_wd, m0_35_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_35 (.clk(clk), .we(m0_35_we), .wa(m0_35_wa), .wd(m0_35_wd), .ra(m0_35_ra), .rd(m0_35_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_35_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_35_ra <= drow;
    logic m0_36_we; logic [8:0] m0_36_wa, m0_36_ra; logic [63:0] m0_36_wd, m0_36_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_36 (.clk(clk), .we(m0_36_we), .wa(m0_36_wa), .wd(m0_36_wd), .ra(m0_36_ra), .rd(m0_36_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_36_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_36_ra <= drow;
    logic m0_37_we; logic [8:0] m0_37_wa, m0_37_ra; logic [63:0] m0_37_wd, m0_37_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_37 (.clk(clk), .we(m0_37_we), .wa(m0_37_wa), .wd(m0_37_wd), .ra(m0_37_ra), .rd(m0_37_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_37_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_37_ra <= drow;
    logic m0_38_we; logic [8:0] m0_38_wa, m0_38_ra; logic [63:0] m0_38_wd, m0_38_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_38 (.clk(clk), .we(m0_38_we), .wa(m0_38_wa), .wd(m0_38_wd), .ra(m0_38_ra), .rd(m0_38_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_38_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_38_ra <= drow;
    logic m0_39_we; logic [8:0] m0_39_wa, m0_39_ra; logic [63:0] m0_39_wd, m0_39_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_39 (.clk(clk), .we(m0_39_we), .wa(m0_39_wa), .wd(m0_39_wd), .ra(m0_39_ra), .rd(m0_39_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_39_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_39_ra <= drow;
    logic m0_40_we; logic [8:0] m0_40_wa, m0_40_ra; logic [63:0] m0_40_wd, m0_40_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_40 (.clk(clk), .we(m0_40_we), .wa(m0_40_wa), .wd(m0_40_wd), .ra(m0_40_ra), .rd(m0_40_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_40_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_40_ra <= drow;
    logic m0_41_we; logic [8:0] m0_41_wa, m0_41_ra; logic [63:0] m0_41_wd, m0_41_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_41 (.clk(clk), .we(m0_41_we), .wa(m0_41_wa), .wd(m0_41_wd), .ra(m0_41_ra), .rd(m0_41_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_41_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_41_ra <= drow;
    logic m0_42_we; logic [8:0] m0_42_wa, m0_42_ra; logic [63:0] m0_42_wd, m0_42_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_42 (.clk(clk), .we(m0_42_we), .wa(m0_42_wa), .wd(m0_42_wd), .ra(m0_42_ra), .rd(m0_42_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_42_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_42_ra <= drow;
    logic m0_43_we; logic [8:0] m0_43_wa, m0_43_ra; logic [63:0] m0_43_wd, m0_43_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_43 (.clk(clk), .we(m0_43_we), .wa(m0_43_wa), .wd(m0_43_wd), .ra(m0_43_ra), .rd(m0_43_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_43_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_43_ra <= drow;
    logic m0_44_we; logic [8:0] m0_44_wa, m0_44_ra; logic [63:0] m0_44_wd, m0_44_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_44 (.clk(clk), .we(m0_44_we), .wa(m0_44_wa), .wd(m0_44_wd), .ra(m0_44_ra), .rd(m0_44_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_44_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_44_ra <= drow;
    logic m0_45_we; logic [8:0] m0_45_wa, m0_45_ra; logic [63:0] m0_45_wd, m0_45_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_45 (.clk(clk), .we(m0_45_we), .wa(m0_45_wa), .wd(m0_45_wd), .ra(m0_45_ra), .rd(m0_45_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_45_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_45_ra <= drow;
    logic m0_46_we; logic [8:0] m0_46_wa, m0_46_ra; logic [63:0] m0_46_wd, m0_46_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_46 (.clk(clk), .we(m0_46_we), .wa(m0_46_wa), .wd(m0_46_wd), .ra(m0_46_ra), .rd(m0_46_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_46_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_46_ra <= drow;
    logic m0_47_we; logic [8:0] m0_47_wa, m0_47_ra; logic [63:0] m0_47_wd, m0_47_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_47 (.clk(clk), .we(m0_47_we), .wa(m0_47_wa), .wd(m0_47_wd), .ra(m0_47_ra), .rd(m0_47_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_47_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_47_ra <= drow;
    logic m0_48_we; logic [8:0] m0_48_wa, m0_48_ra; logic [63:0] m0_48_wd, m0_48_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_48 (.clk(clk), .we(m0_48_we), .wa(m0_48_wa), .wd(m0_48_wd), .ra(m0_48_ra), .rd(m0_48_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_48_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_48_ra <= drow;
    logic m0_49_we; logic [8:0] m0_49_wa, m0_49_ra; logic [63:0] m0_49_wd, m0_49_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_49 (.clk(clk), .we(m0_49_we), .wa(m0_49_wa), .wd(m0_49_wd), .ra(m0_49_ra), .rd(m0_49_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_49_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_49_ra <= drow;
    logic m0_50_we; logic [8:0] m0_50_wa, m0_50_ra; logic [63:0] m0_50_wd, m0_50_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_50 (.clk(clk), .we(m0_50_we), .wa(m0_50_wa), .wd(m0_50_wd), .ra(m0_50_ra), .rd(m0_50_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_50_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_50_ra <= drow;
    logic m0_51_we; logic [8:0] m0_51_wa, m0_51_ra; logic [63:0] m0_51_wd, m0_51_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_51 (.clk(clk), .we(m0_51_we), .wa(m0_51_wa), .wd(m0_51_wd), .ra(m0_51_ra), .rd(m0_51_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_51_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_51_ra <= drow;
    logic m0_52_we; logic [8:0] m0_52_wa, m0_52_ra; logic [63:0] m0_52_wd, m0_52_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_52 (.clk(clk), .we(m0_52_we), .wa(m0_52_wa), .wd(m0_52_wd), .ra(m0_52_ra), .rd(m0_52_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_52_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_52_ra <= drow;
    logic m0_53_we; logic [8:0] m0_53_wa, m0_53_ra; logic [63:0] m0_53_wd, m0_53_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_53 (.clk(clk), .we(m0_53_we), .wa(m0_53_wa), .wd(m0_53_wd), .ra(m0_53_ra), .rd(m0_53_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_53_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_53_ra <= drow;
    logic m0_54_we; logic [8:0] m0_54_wa, m0_54_ra; logic [63:0] m0_54_wd, m0_54_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_54 (.clk(clk), .we(m0_54_we), .wa(m0_54_wa), .wd(m0_54_wd), .ra(m0_54_ra), .rd(m0_54_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_54_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_54_ra <= drow;
    logic m0_55_we; logic [8:0] m0_55_wa, m0_55_ra; logic [63:0] m0_55_wd, m0_55_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_55 (.clk(clk), .we(m0_55_we), .wa(m0_55_wa), .wd(m0_55_wd), .ra(m0_55_ra), .rd(m0_55_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_55_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_55_ra <= drow;
    logic m0_56_we; logic [8:0] m0_56_wa, m0_56_ra; logic [63:0] m0_56_wd, m0_56_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_56 (.clk(clk), .we(m0_56_we), .wa(m0_56_wa), .wd(m0_56_wd), .ra(m0_56_ra), .rd(m0_56_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_56_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_56_ra <= drow;
    logic m0_57_we; logic [8:0] m0_57_wa, m0_57_ra; logic [63:0] m0_57_wd, m0_57_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_57 (.clk(clk), .we(m0_57_we), .wa(m0_57_wa), .wd(m0_57_wd), .ra(m0_57_ra), .rd(m0_57_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_57_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_57_ra <= drow;
    logic m0_58_we; logic [8:0] m0_58_wa, m0_58_ra; logic [63:0] m0_58_wd, m0_58_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_58 (.clk(clk), .we(m0_58_we), .wa(m0_58_wa), .wd(m0_58_wd), .ra(m0_58_ra), .rd(m0_58_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_58_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_58_ra <= drow;
    logic m0_59_we; logic [8:0] m0_59_wa, m0_59_ra; logic [63:0] m0_59_wd, m0_59_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_59 (.clk(clk), .we(m0_59_we), .wa(m0_59_wa), .wd(m0_59_wd), .ra(m0_59_ra), .rd(m0_59_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_59_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_59_ra <= drow;
    logic m0_60_we; logic [8:0] m0_60_wa, m0_60_ra; logic [63:0] m0_60_wd, m0_60_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_60 (.clk(clk), .we(m0_60_we), .wa(m0_60_wa), .wd(m0_60_wd), .ra(m0_60_ra), .rd(m0_60_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_60_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_60_ra <= drow;
    logic m0_61_we; logic [8:0] m0_61_wa, m0_61_ra; logic [63:0] m0_61_wd, m0_61_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_61 (.clk(clk), .we(m0_61_we), .wa(m0_61_wa), .wd(m0_61_wd), .ra(m0_61_ra), .rd(m0_61_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_61_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_61_ra <= drow;
    logic m0_62_we; logic [8:0] m0_62_wa, m0_62_ra; logic [63:0] m0_62_wd, m0_62_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_62 (.clk(clk), .we(m0_62_we), .wa(m0_62_wa), .wd(m0_62_wd), .ra(m0_62_ra), .rd(m0_62_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_62_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_62_ra <= drow;
    logic m0_63_we; logic [8:0] m0_63_wa, m0_63_ra; logic [63:0] m0_63_wd, m0_63_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_63 (.clk(clk), .we(m0_63_we), .wa(m0_63_wa), .wd(m0_63_wd), .ra(m0_63_ra), .rd(m0_63_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_63_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b0) m0_63_ra <= drow;
    logic m0_64_we; logic [8:0] m0_64_wa, m0_64_ra; logic [63:0] m0_64_wd, m0_64_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_64 (.clk(clk), .we(m0_64_we), .wa(m0_64_wa), .wd(m0_64_wd), .ra(m0_64_ra), .rd(m0_64_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_64_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_64_ra <= drow;
    logic m0_65_we; logic [8:0] m0_65_wa, m0_65_ra; logic [63:0] m0_65_wd, m0_65_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_65 (.clk(clk), .we(m0_65_we), .wa(m0_65_wa), .wd(m0_65_wd), .ra(m0_65_ra), .rd(m0_65_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_65_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_65_ra <= drow;
    logic m0_66_we; logic [8:0] m0_66_wa, m0_66_ra; logic [63:0] m0_66_wd, m0_66_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_66 (.clk(clk), .we(m0_66_we), .wa(m0_66_wa), .wd(m0_66_wd), .ra(m0_66_ra), .rd(m0_66_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_66_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_66_ra <= drow;
    logic m0_67_we; logic [8:0] m0_67_wa, m0_67_ra; logic [63:0] m0_67_wd, m0_67_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_67 (.clk(clk), .we(m0_67_we), .wa(m0_67_wa), .wd(m0_67_wd), .ra(m0_67_ra), .rd(m0_67_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_67_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_67_ra <= drow;
    logic m0_68_we; logic [8:0] m0_68_wa, m0_68_ra; logic [63:0] m0_68_wd, m0_68_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_68 (.clk(clk), .we(m0_68_we), .wa(m0_68_wa), .wd(m0_68_wd), .ra(m0_68_ra), .rd(m0_68_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_68_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_68_ra <= drow;
    logic m0_69_we; logic [8:0] m0_69_wa, m0_69_ra; logic [63:0] m0_69_wd, m0_69_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_69 (.clk(clk), .we(m0_69_we), .wa(m0_69_wa), .wd(m0_69_wd), .ra(m0_69_ra), .rd(m0_69_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_69_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_69_ra <= drow;
    logic m0_70_we; logic [8:0] m0_70_wa, m0_70_ra; logic [63:0] m0_70_wd, m0_70_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_70 (.clk(clk), .we(m0_70_we), .wa(m0_70_wa), .wd(m0_70_wd), .ra(m0_70_ra), .rd(m0_70_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_70_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_70_ra <= drow;
    logic m0_71_we; logic [8:0] m0_71_wa, m0_71_ra; logic [63:0] m0_71_wd, m0_71_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_71 (.clk(clk), .we(m0_71_we), .wa(m0_71_wa), .wd(m0_71_wd), .ra(m0_71_ra), .rd(m0_71_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_71_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_71_ra <= drow;
    logic m0_72_we; logic [8:0] m0_72_wa, m0_72_ra; logic [63:0] m0_72_wd, m0_72_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_72 (.clk(clk), .we(m0_72_we), .wa(m0_72_wa), .wd(m0_72_wd), .ra(m0_72_ra), .rd(m0_72_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_72_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_72_ra <= drow;
    logic m0_73_we; logic [8:0] m0_73_wa, m0_73_ra; logic [63:0] m0_73_wd, m0_73_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_73 (.clk(clk), .we(m0_73_we), .wa(m0_73_wa), .wd(m0_73_wd), .ra(m0_73_ra), .rd(m0_73_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_73_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_73_ra <= drow;
    logic m0_74_we; logic [8:0] m0_74_wa, m0_74_ra; logic [63:0] m0_74_wd, m0_74_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_74 (.clk(clk), .we(m0_74_we), .wa(m0_74_wa), .wd(m0_74_wd), .ra(m0_74_ra), .rd(m0_74_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_74_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_74_ra <= drow;
    logic m0_75_we; logic [8:0] m0_75_wa, m0_75_ra; logic [63:0] m0_75_wd, m0_75_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_75 (.clk(clk), .we(m0_75_we), .wa(m0_75_wa), .wd(m0_75_wd), .ra(m0_75_ra), .rd(m0_75_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_75_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_75_ra <= drow;
    logic m0_76_we; logic [8:0] m0_76_wa, m0_76_ra; logic [63:0] m0_76_wd, m0_76_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_76 (.clk(clk), .we(m0_76_we), .wa(m0_76_wa), .wd(m0_76_wd), .ra(m0_76_ra), .rd(m0_76_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_76_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_76_ra <= drow;
    logic m0_77_we; logic [8:0] m0_77_wa, m0_77_ra; logic [63:0] m0_77_wd, m0_77_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_77 (.clk(clk), .we(m0_77_we), .wa(m0_77_wa), .wd(m0_77_wd), .ra(m0_77_ra), .rd(m0_77_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_77_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_77_ra <= drow;
    logic m0_78_we; logic [8:0] m0_78_wa, m0_78_ra; logic [63:0] m0_78_wd, m0_78_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_78 (.clk(clk), .we(m0_78_we), .wa(m0_78_wa), .wd(m0_78_wd), .ra(m0_78_ra), .rd(m0_78_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_78_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_78_ra <= drow;
    logic m0_79_we; logic [8:0] m0_79_wa, m0_79_ra; logic [63:0] m0_79_wd, m0_79_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_79 (.clk(clk), .we(m0_79_we), .wa(m0_79_wa), .wd(m0_79_wd), .ra(m0_79_ra), .rd(m0_79_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_79_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_79_ra <= drow;
    logic m0_80_we; logic [8:0] m0_80_wa, m0_80_ra; logic [63:0] m0_80_wd, m0_80_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_80 (.clk(clk), .we(m0_80_we), .wa(m0_80_wa), .wd(m0_80_wd), .ra(m0_80_ra), .rd(m0_80_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_80_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_80_ra <= drow;
    logic m0_81_we; logic [8:0] m0_81_wa, m0_81_ra; logic [63:0] m0_81_wd, m0_81_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_81 (.clk(clk), .we(m0_81_we), .wa(m0_81_wa), .wd(m0_81_wd), .ra(m0_81_ra), .rd(m0_81_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_81_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_81_ra <= drow;
    logic m0_82_we; logic [8:0] m0_82_wa, m0_82_ra; logic [63:0] m0_82_wd, m0_82_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_82 (.clk(clk), .we(m0_82_we), .wa(m0_82_wa), .wd(m0_82_wd), .ra(m0_82_ra), .rd(m0_82_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_82_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_82_ra <= drow;
    logic m0_83_we; logic [8:0] m0_83_wa, m0_83_ra; logic [63:0] m0_83_wd, m0_83_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_83 (.clk(clk), .we(m0_83_we), .wa(m0_83_wa), .wd(m0_83_wd), .ra(m0_83_ra), .rd(m0_83_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_83_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_83_ra <= drow;
    logic m0_84_we; logic [8:0] m0_84_wa, m0_84_ra; logic [63:0] m0_84_wd, m0_84_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_84 (.clk(clk), .we(m0_84_we), .wa(m0_84_wa), .wd(m0_84_wd), .ra(m0_84_ra), .rd(m0_84_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_84_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_84_ra <= drow;
    logic m0_85_we; logic [8:0] m0_85_wa, m0_85_ra; logic [63:0] m0_85_wd, m0_85_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_85 (.clk(clk), .we(m0_85_we), .wa(m0_85_wa), .wd(m0_85_wd), .ra(m0_85_ra), .rd(m0_85_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_85_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_85_ra <= drow;
    logic m0_86_we; logic [8:0] m0_86_wa, m0_86_ra; logic [63:0] m0_86_wd, m0_86_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_86 (.clk(clk), .we(m0_86_we), .wa(m0_86_wa), .wd(m0_86_wd), .ra(m0_86_ra), .rd(m0_86_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_86_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_86_ra <= drow;
    logic m0_87_we; logic [8:0] m0_87_wa, m0_87_ra; logic [63:0] m0_87_wd, m0_87_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_87 (.clk(clk), .we(m0_87_we), .wa(m0_87_wa), .wd(m0_87_wd), .ra(m0_87_ra), .rd(m0_87_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_87_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_87_ra <= drow;
    logic m0_88_we; logic [8:0] m0_88_wa, m0_88_ra; logic [63:0] m0_88_wd, m0_88_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_88 (.clk(clk), .we(m0_88_we), .wa(m0_88_wa), .wd(m0_88_wd), .ra(m0_88_ra), .rd(m0_88_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_88_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_88_ra <= drow;
    logic m0_89_we; logic [8:0] m0_89_wa, m0_89_ra; logic [63:0] m0_89_wd, m0_89_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_89 (.clk(clk), .we(m0_89_we), .wa(m0_89_wa), .wd(m0_89_wd), .ra(m0_89_ra), .rd(m0_89_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_89_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_89_ra <= drow;
    logic m0_90_we; logic [8:0] m0_90_wa, m0_90_ra; logic [63:0] m0_90_wd, m0_90_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_90 (.clk(clk), .we(m0_90_we), .wa(m0_90_wa), .wd(m0_90_wd), .ra(m0_90_ra), .rd(m0_90_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_90_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_90_ra <= drow;
    logic m0_91_we; logic [8:0] m0_91_wa, m0_91_ra; logic [63:0] m0_91_wd, m0_91_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_91 (.clk(clk), .we(m0_91_we), .wa(m0_91_wa), .wd(m0_91_wd), .ra(m0_91_ra), .rd(m0_91_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_91_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_91_ra <= drow;
    logic m0_92_we; logic [8:0] m0_92_wa, m0_92_ra; logic [63:0] m0_92_wd, m0_92_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_92 (.clk(clk), .we(m0_92_we), .wa(m0_92_wa), .wd(m0_92_wd), .ra(m0_92_ra), .rd(m0_92_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_92_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_92_ra <= drow;
    logic m0_93_we; logic [8:0] m0_93_wa, m0_93_ra; logic [63:0] m0_93_wd, m0_93_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_93 (.clk(clk), .we(m0_93_we), .wa(m0_93_wa), .wd(m0_93_wd), .ra(m0_93_ra), .rd(m0_93_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_93_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_93_ra <= drow;
    logic m0_94_we; logic [8:0] m0_94_wa, m0_94_ra; logic [63:0] m0_94_wd, m0_94_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_94 (.clk(clk), .we(m0_94_we), .wa(m0_94_wa), .wd(m0_94_wd), .ra(m0_94_ra), .rd(m0_94_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_94_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_94_ra <= drow;
    logic m0_95_we; logic [8:0] m0_95_wa, m0_95_ra; logic [63:0] m0_95_wd, m0_95_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_95 (.clk(clk), .we(m0_95_we), .wa(m0_95_wa), .wd(m0_95_wd), .ra(m0_95_ra), .rd(m0_95_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_95_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_95_ra <= drow;
    logic m0_96_we; logic [8:0] m0_96_wa, m0_96_ra; logic [63:0] m0_96_wd, m0_96_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_96 (.clk(clk), .we(m0_96_we), .wa(m0_96_wa), .wd(m0_96_wd), .ra(m0_96_ra), .rd(m0_96_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_96_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_96_ra <= drow;
    logic m0_97_we; logic [8:0] m0_97_wa, m0_97_ra; logic [63:0] m0_97_wd, m0_97_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_97 (.clk(clk), .we(m0_97_we), .wa(m0_97_wa), .wd(m0_97_wd), .ra(m0_97_ra), .rd(m0_97_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_97_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_97_ra <= drow;
    logic m0_98_we; logic [8:0] m0_98_wa, m0_98_ra; logic [63:0] m0_98_wd, m0_98_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_98 (.clk(clk), .we(m0_98_we), .wa(m0_98_wa), .wd(m0_98_wd), .ra(m0_98_ra), .rd(m0_98_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_98_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_98_ra <= drow;
    logic m0_99_we; logic [8:0] m0_99_wa, m0_99_ra; logic [63:0] m0_99_wd, m0_99_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_99 (.clk(clk), .we(m0_99_we), .wa(m0_99_wa), .wd(m0_99_wd), .ra(m0_99_ra), .rd(m0_99_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_99_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_99_ra <= drow;
    logic m0_100_we; logic [8:0] m0_100_wa, m0_100_ra; logic [63:0] m0_100_wd, m0_100_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_100 (.clk(clk), .we(m0_100_we), .wa(m0_100_wa), .wd(m0_100_wd), .ra(m0_100_ra), .rd(m0_100_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_100_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_100_ra <= drow;
    logic m0_101_we; logic [8:0] m0_101_wa, m0_101_ra; logic [63:0] m0_101_wd, m0_101_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_101 (.clk(clk), .we(m0_101_we), .wa(m0_101_wa), .wd(m0_101_wd), .ra(m0_101_ra), .rd(m0_101_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_101_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_101_ra <= drow;
    logic m0_102_we; logic [8:0] m0_102_wa, m0_102_ra; logic [63:0] m0_102_wd, m0_102_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_102 (.clk(clk), .we(m0_102_we), .wa(m0_102_wa), .wd(m0_102_wd), .ra(m0_102_ra), .rd(m0_102_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_102_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_102_ra <= drow;
    logic m0_103_we; logic [8:0] m0_103_wa, m0_103_ra; logic [63:0] m0_103_wd, m0_103_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_103 (.clk(clk), .we(m0_103_we), .wa(m0_103_wa), .wd(m0_103_wd), .ra(m0_103_ra), .rd(m0_103_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_103_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_103_ra <= drow;
    logic m0_104_we; logic [8:0] m0_104_wa, m0_104_ra; logic [63:0] m0_104_wd, m0_104_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_104 (.clk(clk), .we(m0_104_we), .wa(m0_104_wa), .wd(m0_104_wd), .ra(m0_104_ra), .rd(m0_104_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_104_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_104_ra <= drow;
    logic m0_105_we; logic [8:0] m0_105_wa, m0_105_ra; logic [63:0] m0_105_wd, m0_105_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_105 (.clk(clk), .we(m0_105_we), .wa(m0_105_wa), .wd(m0_105_wd), .ra(m0_105_ra), .rd(m0_105_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_105_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_105_ra <= drow;
    logic m0_106_we; logic [8:0] m0_106_wa, m0_106_ra; logic [63:0] m0_106_wd, m0_106_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_106 (.clk(clk), .we(m0_106_we), .wa(m0_106_wa), .wd(m0_106_wd), .ra(m0_106_ra), .rd(m0_106_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_106_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_106_ra <= drow;
    logic m0_107_we; logic [8:0] m0_107_wa, m0_107_ra; logic [63:0] m0_107_wd, m0_107_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_107 (.clk(clk), .we(m0_107_we), .wa(m0_107_wa), .wd(m0_107_wd), .ra(m0_107_ra), .rd(m0_107_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_107_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_107_ra <= drow;
    logic m0_108_we; logic [8:0] m0_108_wa, m0_108_ra; logic [63:0] m0_108_wd, m0_108_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_108 (.clk(clk), .we(m0_108_we), .wa(m0_108_wa), .wd(m0_108_wd), .ra(m0_108_ra), .rd(m0_108_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_108_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_108_ra <= drow;
    logic m0_109_we; logic [8:0] m0_109_wa, m0_109_ra; logic [63:0] m0_109_wd, m0_109_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_109 (.clk(clk), .we(m0_109_we), .wa(m0_109_wa), .wd(m0_109_wd), .ra(m0_109_ra), .rd(m0_109_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_109_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_109_ra <= drow;
    logic m0_110_we; logic [8:0] m0_110_wa, m0_110_ra; logic [63:0] m0_110_wd, m0_110_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_110 (.clk(clk), .we(m0_110_we), .wa(m0_110_wa), .wd(m0_110_wd), .ra(m0_110_ra), .rd(m0_110_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_110_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_110_ra <= drow;
    logic m0_111_we; logic [8:0] m0_111_wa, m0_111_ra; logic [63:0] m0_111_wd, m0_111_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_111 (.clk(clk), .we(m0_111_we), .wa(m0_111_wa), .wd(m0_111_wd), .ra(m0_111_ra), .rd(m0_111_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_111_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_111_ra <= drow;
    logic m0_112_we; logic [8:0] m0_112_wa, m0_112_ra; logic [63:0] m0_112_wd, m0_112_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_112 (.clk(clk), .we(m0_112_we), .wa(m0_112_wa), .wd(m0_112_wd), .ra(m0_112_ra), .rd(m0_112_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_112_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_112_ra <= drow;
    logic m0_113_we; logic [8:0] m0_113_wa, m0_113_ra; logic [63:0] m0_113_wd, m0_113_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_113 (.clk(clk), .we(m0_113_we), .wa(m0_113_wa), .wd(m0_113_wd), .ra(m0_113_ra), .rd(m0_113_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_113_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_113_ra <= drow;
    logic m0_114_we; logic [8:0] m0_114_wa, m0_114_ra; logic [63:0] m0_114_wd, m0_114_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_114 (.clk(clk), .we(m0_114_we), .wa(m0_114_wa), .wd(m0_114_wd), .ra(m0_114_ra), .rd(m0_114_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_114_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_114_ra <= drow;
    logic m0_115_we; logic [8:0] m0_115_wa, m0_115_ra; logic [63:0] m0_115_wd, m0_115_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_115 (.clk(clk), .we(m0_115_we), .wa(m0_115_wa), .wd(m0_115_wd), .ra(m0_115_ra), .rd(m0_115_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_115_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_115_ra <= drow;
    logic m0_116_we; logic [8:0] m0_116_wa, m0_116_ra; logic [63:0] m0_116_wd, m0_116_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_116 (.clk(clk), .we(m0_116_we), .wa(m0_116_wa), .wd(m0_116_wd), .ra(m0_116_ra), .rd(m0_116_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_116_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_116_ra <= drow;
    logic m0_117_we; logic [8:0] m0_117_wa, m0_117_ra; logic [63:0] m0_117_wd, m0_117_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_117 (.clk(clk), .we(m0_117_we), .wa(m0_117_wa), .wd(m0_117_wd), .ra(m0_117_ra), .rd(m0_117_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_117_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_117_ra <= drow;
    logic m0_118_we; logic [8:0] m0_118_wa, m0_118_ra; logic [63:0] m0_118_wd, m0_118_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_118 (.clk(clk), .we(m0_118_we), .wa(m0_118_wa), .wd(m0_118_wd), .ra(m0_118_ra), .rd(m0_118_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_118_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_118_ra <= drow;
    logic m0_119_we; logic [8:0] m0_119_wa, m0_119_ra; logic [63:0] m0_119_wd, m0_119_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_119 (.clk(clk), .we(m0_119_we), .wa(m0_119_wa), .wd(m0_119_wd), .ra(m0_119_ra), .rd(m0_119_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_119_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_119_ra <= drow;
    logic m0_120_we; logic [8:0] m0_120_wa, m0_120_ra; logic [63:0] m0_120_wd, m0_120_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_120 (.clk(clk), .we(m0_120_we), .wa(m0_120_wa), .wd(m0_120_wd), .ra(m0_120_ra), .rd(m0_120_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_120_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_120_ra <= drow;
    logic m0_121_we; logic [8:0] m0_121_wa, m0_121_ra; logic [63:0] m0_121_wd, m0_121_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_121 (.clk(clk), .we(m0_121_we), .wa(m0_121_wa), .wd(m0_121_wd), .ra(m0_121_ra), .rd(m0_121_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_121_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_121_ra <= drow;
    logic m0_122_we; logic [8:0] m0_122_wa, m0_122_ra; logic [63:0] m0_122_wd, m0_122_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_122 (.clk(clk), .we(m0_122_we), .wa(m0_122_wa), .wd(m0_122_wd), .ra(m0_122_ra), .rd(m0_122_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_122_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_122_ra <= drow;
    logic m0_123_we; logic [8:0] m0_123_wa, m0_123_ra; logic [63:0] m0_123_wd, m0_123_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_123 (.clk(clk), .we(m0_123_we), .wa(m0_123_wa), .wd(m0_123_wd), .ra(m0_123_ra), .rd(m0_123_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_123_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_123_ra <= drow;
    logic m0_124_we; logic [8:0] m0_124_wa, m0_124_ra; logic [63:0] m0_124_wd, m0_124_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_124 (.clk(clk), .we(m0_124_we), .wa(m0_124_wa), .wd(m0_124_wd), .ra(m0_124_ra), .rd(m0_124_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_124_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_124_ra <= drow;
    logic m0_125_we; logic [8:0] m0_125_wa, m0_125_ra; logic [63:0] m0_125_wd, m0_125_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_125 (.clk(clk), .we(m0_125_we), .wa(m0_125_wa), .wd(m0_125_wd), .ra(m0_125_ra), .rd(m0_125_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_125_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_125_ra <= drow;
    logic m0_126_we; logic [8:0] m0_126_wa, m0_126_ra; logic [63:0] m0_126_wd, m0_126_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_126 (.clk(clk), .we(m0_126_we), .wa(m0_126_wa), .wd(m0_126_wd), .ra(m0_126_ra), .rd(m0_126_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_126_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_126_ra <= drow;
    logic m0_127_we; logic [8:0] m0_127_wa, m0_127_ra; logic [63:0] m0_127_wd, m0_127_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m0_127 (.clk(clk), .we(m0_127_we), .wa(m0_127_wa), .wd(m0_127_wd), .ra(m0_127_ra), .rd(m0_127_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b0) m0_127_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b0) m0_127_ra <= drow;
    logic m1_0_we; logic [8:0] m1_0_wa, m1_0_ra; logic [63:0] m1_0_wd, m1_0_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_0 (.clk(clk), .we(m1_0_we), .wa(m1_0_wa), .wd(m1_0_wd), .ra(m1_0_ra), .rd(m1_0_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_0_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_0_ra <= drow;
    logic m1_1_we; logic [8:0] m1_1_wa, m1_1_ra; logic [63:0] m1_1_wd, m1_1_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_1 (.clk(clk), .we(m1_1_we), .wa(m1_1_wa), .wd(m1_1_wd), .ra(m1_1_ra), .rd(m1_1_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_1_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_1_ra <= drow;
    logic m1_2_we; logic [8:0] m1_2_wa, m1_2_ra; logic [63:0] m1_2_wd, m1_2_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_2 (.clk(clk), .we(m1_2_we), .wa(m1_2_wa), .wd(m1_2_wd), .ra(m1_2_ra), .rd(m1_2_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_2_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_2_ra <= drow;
    logic m1_3_we; logic [8:0] m1_3_wa, m1_3_ra; logic [63:0] m1_3_wd, m1_3_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_3 (.clk(clk), .we(m1_3_we), .wa(m1_3_wa), .wd(m1_3_wd), .ra(m1_3_ra), .rd(m1_3_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_3_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_3_ra <= drow;
    logic m1_4_we; logic [8:0] m1_4_wa, m1_4_ra; logic [63:0] m1_4_wd, m1_4_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_4 (.clk(clk), .we(m1_4_we), .wa(m1_4_wa), .wd(m1_4_wd), .ra(m1_4_ra), .rd(m1_4_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_4_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_4_ra <= drow;
    logic m1_5_we; logic [8:0] m1_5_wa, m1_5_ra; logic [63:0] m1_5_wd, m1_5_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_5 (.clk(clk), .we(m1_5_we), .wa(m1_5_wa), .wd(m1_5_wd), .ra(m1_5_ra), .rd(m1_5_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_5_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_5_ra <= drow;
    logic m1_6_we; logic [8:0] m1_6_wa, m1_6_ra; logic [63:0] m1_6_wd, m1_6_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_6 (.clk(clk), .we(m1_6_we), .wa(m1_6_wa), .wd(m1_6_wd), .ra(m1_6_ra), .rd(m1_6_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_6_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_6_ra <= drow;
    logic m1_7_we; logic [8:0] m1_7_wa, m1_7_ra; logic [63:0] m1_7_wd, m1_7_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_7 (.clk(clk), .we(m1_7_we), .wa(m1_7_wa), .wd(m1_7_wd), .ra(m1_7_ra), .rd(m1_7_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_7_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_7_ra <= drow;
    logic m1_8_we; logic [8:0] m1_8_wa, m1_8_ra; logic [63:0] m1_8_wd, m1_8_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_8 (.clk(clk), .we(m1_8_we), .wa(m1_8_wa), .wd(m1_8_wd), .ra(m1_8_ra), .rd(m1_8_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_8_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_8_ra <= drow;
    logic m1_9_we; logic [8:0] m1_9_wa, m1_9_ra; logic [63:0] m1_9_wd, m1_9_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_9 (.clk(clk), .we(m1_9_we), .wa(m1_9_wa), .wd(m1_9_wd), .ra(m1_9_ra), .rd(m1_9_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_9_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_9_ra <= drow;
    logic m1_10_we; logic [8:0] m1_10_wa, m1_10_ra; logic [63:0] m1_10_wd, m1_10_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_10 (.clk(clk), .we(m1_10_we), .wa(m1_10_wa), .wd(m1_10_wd), .ra(m1_10_ra), .rd(m1_10_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_10_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_10_ra <= drow;
    logic m1_11_we; logic [8:0] m1_11_wa, m1_11_ra; logic [63:0] m1_11_wd, m1_11_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_11 (.clk(clk), .we(m1_11_we), .wa(m1_11_wa), .wd(m1_11_wd), .ra(m1_11_ra), .rd(m1_11_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_11_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_11_ra <= drow;
    logic m1_12_we; logic [8:0] m1_12_wa, m1_12_ra; logic [63:0] m1_12_wd, m1_12_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_12 (.clk(clk), .we(m1_12_we), .wa(m1_12_wa), .wd(m1_12_wd), .ra(m1_12_ra), .rd(m1_12_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_12_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_12_ra <= drow;
    logic m1_13_we; logic [8:0] m1_13_wa, m1_13_ra; logic [63:0] m1_13_wd, m1_13_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_13 (.clk(clk), .we(m1_13_we), .wa(m1_13_wa), .wd(m1_13_wd), .ra(m1_13_ra), .rd(m1_13_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_13_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_13_ra <= drow;
    logic m1_14_we; logic [8:0] m1_14_wa, m1_14_ra; logic [63:0] m1_14_wd, m1_14_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_14 (.clk(clk), .we(m1_14_we), .wa(m1_14_wa), .wd(m1_14_wd), .ra(m1_14_ra), .rd(m1_14_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_14_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_14_ra <= drow;
    logic m1_15_we; logic [8:0] m1_15_wa, m1_15_ra; logic [63:0] m1_15_wd, m1_15_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_15 (.clk(clk), .we(m1_15_we), .wa(m1_15_wa), .wd(m1_15_wd), .ra(m1_15_ra), .rd(m1_15_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_15_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_15_ra <= drow;
    logic m1_16_we; logic [8:0] m1_16_wa, m1_16_ra; logic [63:0] m1_16_wd, m1_16_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_16 (.clk(clk), .we(m1_16_we), .wa(m1_16_wa), .wd(m1_16_wd), .ra(m1_16_ra), .rd(m1_16_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_16_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_16_ra <= drow;
    logic m1_17_we; logic [8:0] m1_17_wa, m1_17_ra; logic [63:0] m1_17_wd, m1_17_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_17 (.clk(clk), .we(m1_17_we), .wa(m1_17_wa), .wd(m1_17_wd), .ra(m1_17_ra), .rd(m1_17_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_17_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_17_ra <= drow;
    logic m1_18_we; logic [8:0] m1_18_wa, m1_18_ra; logic [63:0] m1_18_wd, m1_18_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_18 (.clk(clk), .we(m1_18_we), .wa(m1_18_wa), .wd(m1_18_wd), .ra(m1_18_ra), .rd(m1_18_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_18_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_18_ra <= drow;
    logic m1_19_we; logic [8:0] m1_19_wa, m1_19_ra; logic [63:0] m1_19_wd, m1_19_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_19 (.clk(clk), .we(m1_19_we), .wa(m1_19_wa), .wd(m1_19_wd), .ra(m1_19_ra), .rd(m1_19_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_19_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_19_ra <= drow;
    logic m1_20_we; logic [8:0] m1_20_wa, m1_20_ra; logic [63:0] m1_20_wd, m1_20_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_20 (.clk(clk), .we(m1_20_we), .wa(m1_20_wa), .wd(m1_20_wd), .ra(m1_20_ra), .rd(m1_20_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_20_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_20_ra <= drow;
    logic m1_21_we; logic [8:0] m1_21_wa, m1_21_ra; logic [63:0] m1_21_wd, m1_21_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_21 (.clk(clk), .we(m1_21_we), .wa(m1_21_wa), .wd(m1_21_wd), .ra(m1_21_ra), .rd(m1_21_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_21_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_21_ra <= drow;
    logic m1_22_we; logic [8:0] m1_22_wa, m1_22_ra; logic [63:0] m1_22_wd, m1_22_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_22 (.clk(clk), .we(m1_22_we), .wa(m1_22_wa), .wd(m1_22_wd), .ra(m1_22_ra), .rd(m1_22_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_22_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_22_ra <= drow;
    logic m1_23_we; logic [8:0] m1_23_wa, m1_23_ra; logic [63:0] m1_23_wd, m1_23_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_23 (.clk(clk), .we(m1_23_we), .wa(m1_23_wa), .wd(m1_23_wd), .ra(m1_23_ra), .rd(m1_23_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_23_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_23_ra <= drow;
    logic m1_24_we; logic [8:0] m1_24_wa, m1_24_ra; logic [63:0] m1_24_wd, m1_24_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_24 (.clk(clk), .we(m1_24_we), .wa(m1_24_wa), .wd(m1_24_wd), .ra(m1_24_ra), .rd(m1_24_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_24_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_24_ra <= drow;
    logic m1_25_we; logic [8:0] m1_25_wa, m1_25_ra; logic [63:0] m1_25_wd, m1_25_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_25 (.clk(clk), .we(m1_25_we), .wa(m1_25_wa), .wd(m1_25_wd), .ra(m1_25_ra), .rd(m1_25_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_25_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_25_ra <= drow;
    logic m1_26_we; logic [8:0] m1_26_wa, m1_26_ra; logic [63:0] m1_26_wd, m1_26_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_26 (.clk(clk), .we(m1_26_we), .wa(m1_26_wa), .wd(m1_26_wd), .ra(m1_26_ra), .rd(m1_26_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_26_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_26_ra <= drow;
    logic m1_27_we; logic [8:0] m1_27_wa, m1_27_ra; logic [63:0] m1_27_wd, m1_27_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_27 (.clk(clk), .we(m1_27_we), .wa(m1_27_wa), .wd(m1_27_wd), .ra(m1_27_ra), .rd(m1_27_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_27_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_27_ra <= drow;
    logic m1_28_we; logic [8:0] m1_28_wa, m1_28_ra; logic [63:0] m1_28_wd, m1_28_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_28 (.clk(clk), .we(m1_28_we), .wa(m1_28_wa), .wd(m1_28_wd), .ra(m1_28_ra), .rd(m1_28_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_28_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_28_ra <= drow;
    logic m1_29_we; logic [8:0] m1_29_wa, m1_29_ra; logic [63:0] m1_29_wd, m1_29_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_29 (.clk(clk), .we(m1_29_we), .wa(m1_29_wa), .wd(m1_29_wd), .ra(m1_29_ra), .rd(m1_29_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_29_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_29_ra <= drow;
    logic m1_30_we; logic [8:0] m1_30_wa, m1_30_ra; logic [63:0] m1_30_wd, m1_30_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_30 (.clk(clk), .we(m1_30_we), .wa(m1_30_wa), .wd(m1_30_wd), .ra(m1_30_ra), .rd(m1_30_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_30_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_30_ra <= drow;
    logic m1_31_we; logic [8:0] m1_31_wa, m1_31_ra; logic [63:0] m1_31_wd, m1_31_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_31 (.clk(clk), .we(m1_31_we), .wa(m1_31_wa), .wd(m1_31_wd), .ra(m1_31_ra), .rd(m1_31_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_31_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_31_ra <= drow;
    logic m1_32_we; logic [8:0] m1_32_wa, m1_32_ra; logic [63:0] m1_32_wd, m1_32_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_32 (.clk(clk), .we(m1_32_we), .wa(m1_32_wa), .wd(m1_32_wd), .ra(m1_32_ra), .rd(m1_32_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_32_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_32_ra <= drow;
    logic m1_33_we; logic [8:0] m1_33_wa, m1_33_ra; logic [63:0] m1_33_wd, m1_33_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_33 (.clk(clk), .we(m1_33_we), .wa(m1_33_wa), .wd(m1_33_wd), .ra(m1_33_ra), .rd(m1_33_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_33_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_33_ra <= drow;
    logic m1_34_we; logic [8:0] m1_34_wa, m1_34_ra; logic [63:0] m1_34_wd, m1_34_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_34 (.clk(clk), .we(m1_34_we), .wa(m1_34_wa), .wd(m1_34_wd), .ra(m1_34_ra), .rd(m1_34_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_34_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_34_ra <= drow;
    logic m1_35_we; logic [8:0] m1_35_wa, m1_35_ra; logic [63:0] m1_35_wd, m1_35_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_35 (.clk(clk), .we(m1_35_we), .wa(m1_35_wa), .wd(m1_35_wd), .ra(m1_35_ra), .rd(m1_35_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_35_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_35_ra <= drow;
    logic m1_36_we; logic [8:0] m1_36_wa, m1_36_ra; logic [63:0] m1_36_wd, m1_36_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_36 (.clk(clk), .we(m1_36_we), .wa(m1_36_wa), .wd(m1_36_wd), .ra(m1_36_ra), .rd(m1_36_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_36_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_36_ra <= drow;
    logic m1_37_we; logic [8:0] m1_37_wa, m1_37_ra; logic [63:0] m1_37_wd, m1_37_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_37 (.clk(clk), .we(m1_37_we), .wa(m1_37_wa), .wd(m1_37_wd), .ra(m1_37_ra), .rd(m1_37_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_37_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_37_ra <= drow;
    logic m1_38_we; logic [8:0] m1_38_wa, m1_38_ra; logic [63:0] m1_38_wd, m1_38_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_38 (.clk(clk), .we(m1_38_we), .wa(m1_38_wa), .wd(m1_38_wd), .ra(m1_38_ra), .rd(m1_38_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_38_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_38_ra <= drow;
    logic m1_39_we; logic [8:0] m1_39_wa, m1_39_ra; logic [63:0] m1_39_wd, m1_39_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_39 (.clk(clk), .we(m1_39_we), .wa(m1_39_wa), .wd(m1_39_wd), .ra(m1_39_ra), .rd(m1_39_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_39_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_39_ra <= drow;
    logic m1_40_we; logic [8:0] m1_40_wa, m1_40_ra; logic [63:0] m1_40_wd, m1_40_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_40 (.clk(clk), .we(m1_40_we), .wa(m1_40_wa), .wd(m1_40_wd), .ra(m1_40_ra), .rd(m1_40_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_40_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_40_ra <= drow;
    logic m1_41_we; logic [8:0] m1_41_wa, m1_41_ra; logic [63:0] m1_41_wd, m1_41_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_41 (.clk(clk), .we(m1_41_we), .wa(m1_41_wa), .wd(m1_41_wd), .ra(m1_41_ra), .rd(m1_41_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_41_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_41_ra <= drow;
    logic m1_42_we; logic [8:0] m1_42_wa, m1_42_ra; logic [63:0] m1_42_wd, m1_42_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_42 (.clk(clk), .we(m1_42_we), .wa(m1_42_wa), .wd(m1_42_wd), .ra(m1_42_ra), .rd(m1_42_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_42_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_42_ra <= drow;
    logic m1_43_we; logic [8:0] m1_43_wa, m1_43_ra; logic [63:0] m1_43_wd, m1_43_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_43 (.clk(clk), .we(m1_43_we), .wa(m1_43_wa), .wd(m1_43_wd), .ra(m1_43_ra), .rd(m1_43_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_43_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_43_ra <= drow;
    logic m1_44_we; logic [8:0] m1_44_wa, m1_44_ra; logic [63:0] m1_44_wd, m1_44_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_44 (.clk(clk), .we(m1_44_we), .wa(m1_44_wa), .wd(m1_44_wd), .ra(m1_44_ra), .rd(m1_44_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_44_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_44_ra <= drow;
    logic m1_45_we; logic [8:0] m1_45_wa, m1_45_ra; logic [63:0] m1_45_wd, m1_45_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_45 (.clk(clk), .we(m1_45_we), .wa(m1_45_wa), .wd(m1_45_wd), .ra(m1_45_ra), .rd(m1_45_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_45_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_45_ra <= drow;
    logic m1_46_we; logic [8:0] m1_46_wa, m1_46_ra; logic [63:0] m1_46_wd, m1_46_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_46 (.clk(clk), .we(m1_46_we), .wa(m1_46_wa), .wd(m1_46_wd), .ra(m1_46_ra), .rd(m1_46_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_46_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_46_ra <= drow;
    logic m1_47_we; logic [8:0] m1_47_wa, m1_47_ra; logic [63:0] m1_47_wd, m1_47_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_47 (.clk(clk), .we(m1_47_we), .wa(m1_47_wa), .wd(m1_47_wd), .ra(m1_47_ra), .rd(m1_47_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_47_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_47_ra <= drow;
    logic m1_48_we; logic [8:0] m1_48_wa, m1_48_ra; logic [63:0] m1_48_wd, m1_48_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_48 (.clk(clk), .we(m1_48_we), .wa(m1_48_wa), .wd(m1_48_wd), .ra(m1_48_ra), .rd(m1_48_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_48_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_48_ra <= drow;
    logic m1_49_we; logic [8:0] m1_49_wa, m1_49_ra; logic [63:0] m1_49_wd, m1_49_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_49 (.clk(clk), .we(m1_49_we), .wa(m1_49_wa), .wd(m1_49_wd), .ra(m1_49_ra), .rd(m1_49_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_49_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_49_ra <= drow;
    logic m1_50_we; logic [8:0] m1_50_wa, m1_50_ra; logic [63:0] m1_50_wd, m1_50_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_50 (.clk(clk), .we(m1_50_we), .wa(m1_50_wa), .wd(m1_50_wd), .ra(m1_50_ra), .rd(m1_50_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_50_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_50_ra <= drow;
    logic m1_51_we; logic [8:0] m1_51_wa, m1_51_ra; logic [63:0] m1_51_wd, m1_51_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_51 (.clk(clk), .we(m1_51_we), .wa(m1_51_wa), .wd(m1_51_wd), .ra(m1_51_ra), .rd(m1_51_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_51_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_51_ra <= drow;
    logic m1_52_we; logic [8:0] m1_52_wa, m1_52_ra; logic [63:0] m1_52_wd, m1_52_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_52 (.clk(clk), .we(m1_52_we), .wa(m1_52_wa), .wd(m1_52_wd), .ra(m1_52_ra), .rd(m1_52_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_52_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_52_ra <= drow;
    logic m1_53_we; logic [8:0] m1_53_wa, m1_53_ra; logic [63:0] m1_53_wd, m1_53_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_53 (.clk(clk), .we(m1_53_we), .wa(m1_53_wa), .wd(m1_53_wd), .ra(m1_53_ra), .rd(m1_53_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_53_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_53_ra <= drow;
    logic m1_54_we; logic [8:0] m1_54_wa, m1_54_ra; logic [63:0] m1_54_wd, m1_54_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_54 (.clk(clk), .we(m1_54_we), .wa(m1_54_wa), .wd(m1_54_wd), .ra(m1_54_ra), .rd(m1_54_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_54_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_54_ra <= drow;
    logic m1_55_we; logic [8:0] m1_55_wa, m1_55_ra; logic [63:0] m1_55_wd, m1_55_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_55 (.clk(clk), .we(m1_55_we), .wa(m1_55_wa), .wd(m1_55_wd), .ra(m1_55_ra), .rd(m1_55_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_55_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_55_ra <= drow;
    logic m1_56_we; logic [8:0] m1_56_wa, m1_56_ra; logic [63:0] m1_56_wd, m1_56_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_56 (.clk(clk), .we(m1_56_we), .wa(m1_56_wa), .wd(m1_56_wd), .ra(m1_56_ra), .rd(m1_56_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_56_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_56_ra <= drow;
    logic m1_57_we; logic [8:0] m1_57_wa, m1_57_ra; logic [63:0] m1_57_wd, m1_57_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_57 (.clk(clk), .we(m1_57_we), .wa(m1_57_wa), .wd(m1_57_wd), .ra(m1_57_ra), .rd(m1_57_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_57_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_57_ra <= drow;
    logic m1_58_we; logic [8:0] m1_58_wa, m1_58_ra; logic [63:0] m1_58_wd, m1_58_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_58 (.clk(clk), .we(m1_58_we), .wa(m1_58_wa), .wd(m1_58_wd), .ra(m1_58_ra), .rd(m1_58_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_58_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_58_ra <= drow;
    logic m1_59_we; logic [8:0] m1_59_wa, m1_59_ra; logic [63:0] m1_59_wd, m1_59_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_59 (.clk(clk), .we(m1_59_we), .wa(m1_59_wa), .wd(m1_59_wd), .ra(m1_59_ra), .rd(m1_59_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_59_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_59_ra <= drow;
    logic m1_60_we; logic [8:0] m1_60_wa, m1_60_ra; logic [63:0] m1_60_wd, m1_60_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_60 (.clk(clk), .we(m1_60_we), .wa(m1_60_wa), .wd(m1_60_wd), .ra(m1_60_ra), .rd(m1_60_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_60_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_60_ra <= drow;
    logic m1_61_we; logic [8:0] m1_61_wa, m1_61_ra; logic [63:0] m1_61_wd, m1_61_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_61 (.clk(clk), .we(m1_61_we), .wa(m1_61_wa), .wd(m1_61_wd), .ra(m1_61_ra), .rd(m1_61_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_61_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_61_ra <= drow;
    logic m1_62_we; logic [8:0] m1_62_wa, m1_62_ra; logic [63:0] m1_62_wd, m1_62_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_62 (.clk(clk), .we(m1_62_we), .wa(m1_62_wa), .wd(m1_62_wd), .ra(m1_62_ra), .rd(m1_62_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_62_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_62_ra <= drow;
    logic m1_63_we; logic [8:0] m1_63_wa, m1_63_ra; logic [63:0] m1_63_wd, m1_63_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_63 (.clk(clk), .we(m1_63_we), .wa(m1_63_wa), .wd(m1_63_wd), .ra(m1_63_ra), .rd(m1_63_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_63_ra <= (c_flip ? c_hB : c_hA); else if (dact && dset == 1'b1) m1_63_ra <= drow;
    logic m1_64_we; logic [8:0] m1_64_wa, m1_64_ra; logic [63:0] m1_64_wd, m1_64_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_64 (.clk(clk), .we(m1_64_we), .wa(m1_64_wa), .wd(m1_64_wd), .ra(m1_64_ra), .rd(m1_64_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_64_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_64_ra <= drow;
    logic m1_65_we; logic [8:0] m1_65_wa, m1_65_ra; logic [63:0] m1_65_wd, m1_65_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_65 (.clk(clk), .we(m1_65_we), .wa(m1_65_wa), .wd(m1_65_wd), .ra(m1_65_ra), .rd(m1_65_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_65_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_65_ra <= drow;
    logic m1_66_we; logic [8:0] m1_66_wa, m1_66_ra; logic [63:0] m1_66_wd, m1_66_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_66 (.clk(clk), .we(m1_66_we), .wa(m1_66_wa), .wd(m1_66_wd), .ra(m1_66_ra), .rd(m1_66_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_66_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_66_ra <= drow;
    logic m1_67_we; logic [8:0] m1_67_wa, m1_67_ra; logic [63:0] m1_67_wd, m1_67_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_67 (.clk(clk), .we(m1_67_we), .wa(m1_67_wa), .wd(m1_67_wd), .ra(m1_67_ra), .rd(m1_67_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_67_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_67_ra <= drow;
    logic m1_68_we; logic [8:0] m1_68_wa, m1_68_ra; logic [63:0] m1_68_wd, m1_68_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_68 (.clk(clk), .we(m1_68_we), .wa(m1_68_wa), .wd(m1_68_wd), .ra(m1_68_ra), .rd(m1_68_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_68_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_68_ra <= drow;
    logic m1_69_we; logic [8:0] m1_69_wa, m1_69_ra; logic [63:0] m1_69_wd, m1_69_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_69 (.clk(clk), .we(m1_69_we), .wa(m1_69_wa), .wd(m1_69_wd), .ra(m1_69_ra), .rd(m1_69_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_69_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_69_ra <= drow;
    logic m1_70_we; logic [8:0] m1_70_wa, m1_70_ra; logic [63:0] m1_70_wd, m1_70_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_70 (.clk(clk), .we(m1_70_we), .wa(m1_70_wa), .wd(m1_70_wd), .ra(m1_70_ra), .rd(m1_70_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_70_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_70_ra <= drow;
    logic m1_71_we; logic [8:0] m1_71_wa, m1_71_ra; logic [63:0] m1_71_wd, m1_71_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_71 (.clk(clk), .we(m1_71_we), .wa(m1_71_wa), .wd(m1_71_wd), .ra(m1_71_ra), .rd(m1_71_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_71_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_71_ra <= drow;
    logic m1_72_we; logic [8:0] m1_72_wa, m1_72_ra; logic [63:0] m1_72_wd, m1_72_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_72 (.clk(clk), .we(m1_72_we), .wa(m1_72_wa), .wd(m1_72_wd), .ra(m1_72_ra), .rd(m1_72_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_72_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_72_ra <= drow;
    logic m1_73_we; logic [8:0] m1_73_wa, m1_73_ra; logic [63:0] m1_73_wd, m1_73_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_73 (.clk(clk), .we(m1_73_we), .wa(m1_73_wa), .wd(m1_73_wd), .ra(m1_73_ra), .rd(m1_73_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_73_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_73_ra <= drow;
    logic m1_74_we; logic [8:0] m1_74_wa, m1_74_ra; logic [63:0] m1_74_wd, m1_74_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_74 (.clk(clk), .we(m1_74_we), .wa(m1_74_wa), .wd(m1_74_wd), .ra(m1_74_ra), .rd(m1_74_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_74_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_74_ra <= drow;
    logic m1_75_we; logic [8:0] m1_75_wa, m1_75_ra; logic [63:0] m1_75_wd, m1_75_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_75 (.clk(clk), .we(m1_75_we), .wa(m1_75_wa), .wd(m1_75_wd), .ra(m1_75_ra), .rd(m1_75_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_75_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_75_ra <= drow;
    logic m1_76_we; logic [8:0] m1_76_wa, m1_76_ra; logic [63:0] m1_76_wd, m1_76_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_76 (.clk(clk), .we(m1_76_we), .wa(m1_76_wa), .wd(m1_76_wd), .ra(m1_76_ra), .rd(m1_76_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_76_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_76_ra <= drow;
    logic m1_77_we; logic [8:0] m1_77_wa, m1_77_ra; logic [63:0] m1_77_wd, m1_77_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_77 (.clk(clk), .we(m1_77_we), .wa(m1_77_wa), .wd(m1_77_wd), .ra(m1_77_ra), .rd(m1_77_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_77_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_77_ra <= drow;
    logic m1_78_we; logic [8:0] m1_78_wa, m1_78_ra; logic [63:0] m1_78_wd, m1_78_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_78 (.clk(clk), .we(m1_78_we), .wa(m1_78_wa), .wd(m1_78_wd), .ra(m1_78_ra), .rd(m1_78_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_78_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_78_ra <= drow;
    logic m1_79_we; logic [8:0] m1_79_wa, m1_79_ra; logic [63:0] m1_79_wd, m1_79_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_79 (.clk(clk), .we(m1_79_we), .wa(m1_79_wa), .wd(m1_79_wd), .ra(m1_79_ra), .rd(m1_79_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_79_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_79_ra <= drow;
    logic m1_80_we; logic [8:0] m1_80_wa, m1_80_ra; logic [63:0] m1_80_wd, m1_80_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_80 (.clk(clk), .we(m1_80_we), .wa(m1_80_wa), .wd(m1_80_wd), .ra(m1_80_ra), .rd(m1_80_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_80_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_80_ra <= drow;
    logic m1_81_we; logic [8:0] m1_81_wa, m1_81_ra; logic [63:0] m1_81_wd, m1_81_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_81 (.clk(clk), .we(m1_81_we), .wa(m1_81_wa), .wd(m1_81_wd), .ra(m1_81_ra), .rd(m1_81_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_81_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_81_ra <= drow;
    logic m1_82_we; logic [8:0] m1_82_wa, m1_82_ra; logic [63:0] m1_82_wd, m1_82_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_82 (.clk(clk), .we(m1_82_we), .wa(m1_82_wa), .wd(m1_82_wd), .ra(m1_82_ra), .rd(m1_82_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_82_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_82_ra <= drow;
    logic m1_83_we; logic [8:0] m1_83_wa, m1_83_ra; logic [63:0] m1_83_wd, m1_83_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_83 (.clk(clk), .we(m1_83_we), .wa(m1_83_wa), .wd(m1_83_wd), .ra(m1_83_ra), .rd(m1_83_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_83_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_83_ra <= drow;
    logic m1_84_we; logic [8:0] m1_84_wa, m1_84_ra; logic [63:0] m1_84_wd, m1_84_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_84 (.clk(clk), .we(m1_84_we), .wa(m1_84_wa), .wd(m1_84_wd), .ra(m1_84_ra), .rd(m1_84_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_84_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_84_ra <= drow;
    logic m1_85_we; logic [8:0] m1_85_wa, m1_85_ra; logic [63:0] m1_85_wd, m1_85_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_85 (.clk(clk), .we(m1_85_we), .wa(m1_85_wa), .wd(m1_85_wd), .ra(m1_85_ra), .rd(m1_85_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_85_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_85_ra <= drow;
    logic m1_86_we; logic [8:0] m1_86_wa, m1_86_ra; logic [63:0] m1_86_wd, m1_86_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_86 (.clk(clk), .we(m1_86_we), .wa(m1_86_wa), .wd(m1_86_wd), .ra(m1_86_ra), .rd(m1_86_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_86_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_86_ra <= drow;
    logic m1_87_we; logic [8:0] m1_87_wa, m1_87_ra; logic [63:0] m1_87_wd, m1_87_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_87 (.clk(clk), .we(m1_87_we), .wa(m1_87_wa), .wd(m1_87_wd), .ra(m1_87_ra), .rd(m1_87_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_87_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_87_ra <= drow;
    logic m1_88_we; logic [8:0] m1_88_wa, m1_88_ra; logic [63:0] m1_88_wd, m1_88_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_88 (.clk(clk), .we(m1_88_we), .wa(m1_88_wa), .wd(m1_88_wd), .ra(m1_88_ra), .rd(m1_88_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_88_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_88_ra <= drow;
    logic m1_89_we; logic [8:0] m1_89_wa, m1_89_ra; logic [63:0] m1_89_wd, m1_89_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_89 (.clk(clk), .we(m1_89_we), .wa(m1_89_wa), .wd(m1_89_wd), .ra(m1_89_ra), .rd(m1_89_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_89_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_89_ra <= drow;
    logic m1_90_we; logic [8:0] m1_90_wa, m1_90_ra; logic [63:0] m1_90_wd, m1_90_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_90 (.clk(clk), .we(m1_90_we), .wa(m1_90_wa), .wd(m1_90_wd), .ra(m1_90_ra), .rd(m1_90_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_90_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_90_ra <= drow;
    logic m1_91_we; logic [8:0] m1_91_wa, m1_91_ra; logic [63:0] m1_91_wd, m1_91_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_91 (.clk(clk), .we(m1_91_we), .wa(m1_91_wa), .wd(m1_91_wd), .ra(m1_91_ra), .rd(m1_91_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_91_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_91_ra <= drow;
    logic m1_92_we; logic [8:0] m1_92_wa, m1_92_ra; logic [63:0] m1_92_wd, m1_92_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_92 (.clk(clk), .we(m1_92_we), .wa(m1_92_wa), .wd(m1_92_wd), .ra(m1_92_ra), .rd(m1_92_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_92_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_92_ra <= drow;
    logic m1_93_we; logic [8:0] m1_93_wa, m1_93_ra; logic [63:0] m1_93_wd, m1_93_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_93 (.clk(clk), .we(m1_93_we), .wa(m1_93_wa), .wd(m1_93_wd), .ra(m1_93_ra), .rd(m1_93_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_93_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_93_ra <= drow;
    logic m1_94_we; logic [8:0] m1_94_wa, m1_94_ra; logic [63:0] m1_94_wd, m1_94_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_94 (.clk(clk), .we(m1_94_we), .wa(m1_94_wa), .wd(m1_94_wd), .ra(m1_94_ra), .rd(m1_94_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_94_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_94_ra <= drow;
    logic m1_95_we; logic [8:0] m1_95_wa, m1_95_ra; logic [63:0] m1_95_wd, m1_95_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_95 (.clk(clk), .we(m1_95_we), .wa(m1_95_wa), .wd(m1_95_wd), .ra(m1_95_ra), .rd(m1_95_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_95_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_95_ra <= drow;
    logic m1_96_we; logic [8:0] m1_96_wa, m1_96_ra; logic [63:0] m1_96_wd, m1_96_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_96 (.clk(clk), .we(m1_96_we), .wa(m1_96_wa), .wd(m1_96_wd), .ra(m1_96_ra), .rd(m1_96_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_96_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_96_ra <= drow;
    logic m1_97_we; logic [8:0] m1_97_wa, m1_97_ra; logic [63:0] m1_97_wd, m1_97_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_97 (.clk(clk), .we(m1_97_we), .wa(m1_97_wa), .wd(m1_97_wd), .ra(m1_97_ra), .rd(m1_97_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_97_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_97_ra <= drow;
    logic m1_98_we; logic [8:0] m1_98_wa, m1_98_ra; logic [63:0] m1_98_wd, m1_98_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_98 (.clk(clk), .we(m1_98_we), .wa(m1_98_wa), .wd(m1_98_wd), .ra(m1_98_ra), .rd(m1_98_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_98_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_98_ra <= drow;
    logic m1_99_we; logic [8:0] m1_99_wa, m1_99_ra; logic [63:0] m1_99_wd, m1_99_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_99 (.clk(clk), .we(m1_99_we), .wa(m1_99_wa), .wd(m1_99_wd), .ra(m1_99_ra), .rd(m1_99_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_99_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_99_ra <= drow;
    logic m1_100_we; logic [8:0] m1_100_wa, m1_100_ra; logic [63:0] m1_100_wd, m1_100_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_100 (.clk(clk), .we(m1_100_we), .wa(m1_100_wa), .wd(m1_100_wd), .ra(m1_100_ra), .rd(m1_100_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_100_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_100_ra <= drow;
    logic m1_101_we; logic [8:0] m1_101_wa, m1_101_ra; logic [63:0] m1_101_wd, m1_101_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_101 (.clk(clk), .we(m1_101_we), .wa(m1_101_wa), .wd(m1_101_wd), .ra(m1_101_ra), .rd(m1_101_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_101_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_101_ra <= drow;
    logic m1_102_we; logic [8:0] m1_102_wa, m1_102_ra; logic [63:0] m1_102_wd, m1_102_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_102 (.clk(clk), .we(m1_102_we), .wa(m1_102_wa), .wd(m1_102_wd), .ra(m1_102_ra), .rd(m1_102_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_102_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_102_ra <= drow;
    logic m1_103_we; logic [8:0] m1_103_wa, m1_103_ra; logic [63:0] m1_103_wd, m1_103_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_103 (.clk(clk), .we(m1_103_we), .wa(m1_103_wa), .wd(m1_103_wd), .ra(m1_103_ra), .rd(m1_103_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_103_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_103_ra <= drow;
    logic m1_104_we; logic [8:0] m1_104_wa, m1_104_ra; logic [63:0] m1_104_wd, m1_104_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_104 (.clk(clk), .we(m1_104_we), .wa(m1_104_wa), .wd(m1_104_wd), .ra(m1_104_ra), .rd(m1_104_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_104_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_104_ra <= drow;
    logic m1_105_we; logic [8:0] m1_105_wa, m1_105_ra; logic [63:0] m1_105_wd, m1_105_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_105 (.clk(clk), .we(m1_105_we), .wa(m1_105_wa), .wd(m1_105_wd), .ra(m1_105_ra), .rd(m1_105_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_105_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_105_ra <= drow;
    logic m1_106_we; logic [8:0] m1_106_wa, m1_106_ra; logic [63:0] m1_106_wd, m1_106_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_106 (.clk(clk), .we(m1_106_we), .wa(m1_106_wa), .wd(m1_106_wd), .ra(m1_106_ra), .rd(m1_106_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_106_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_106_ra <= drow;
    logic m1_107_we; logic [8:0] m1_107_wa, m1_107_ra; logic [63:0] m1_107_wd, m1_107_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_107 (.clk(clk), .we(m1_107_we), .wa(m1_107_wa), .wd(m1_107_wd), .ra(m1_107_ra), .rd(m1_107_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_107_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_107_ra <= drow;
    logic m1_108_we; logic [8:0] m1_108_wa, m1_108_ra; logic [63:0] m1_108_wd, m1_108_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_108 (.clk(clk), .we(m1_108_we), .wa(m1_108_wa), .wd(m1_108_wd), .ra(m1_108_ra), .rd(m1_108_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_108_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_108_ra <= drow;
    logic m1_109_we; logic [8:0] m1_109_wa, m1_109_ra; logic [63:0] m1_109_wd, m1_109_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_109 (.clk(clk), .we(m1_109_we), .wa(m1_109_wa), .wd(m1_109_wd), .ra(m1_109_ra), .rd(m1_109_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_109_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_109_ra <= drow;
    logic m1_110_we; logic [8:0] m1_110_wa, m1_110_ra; logic [63:0] m1_110_wd, m1_110_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_110 (.clk(clk), .we(m1_110_we), .wa(m1_110_wa), .wd(m1_110_wd), .ra(m1_110_ra), .rd(m1_110_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_110_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_110_ra <= drow;
    logic m1_111_we; logic [8:0] m1_111_wa, m1_111_ra; logic [63:0] m1_111_wd, m1_111_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_111 (.clk(clk), .we(m1_111_we), .wa(m1_111_wa), .wd(m1_111_wd), .ra(m1_111_ra), .rd(m1_111_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_111_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_111_ra <= drow;
    logic m1_112_we; logic [8:0] m1_112_wa, m1_112_ra; logic [63:0] m1_112_wd, m1_112_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_112 (.clk(clk), .we(m1_112_we), .wa(m1_112_wa), .wd(m1_112_wd), .ra(m1_112_ra), .rd(m1_112_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_112_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_112_ra <= drow;
    logic m1_113_we; logic [8:0] m1_113_wa, m1_113_ra; logic [63:0] m1_113_wd, m1_113_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_113 (.clk(clk), .we(m1_113_we), .wa(m1_113_wa), .wd(m1_113_wd), .ra(m1_113_ra), .rd(m1_113_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_113_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_113_ra <= drow;
    logic m1_114_we; logic [8:0] m1_114_wa, m1_114_ra; logic [63:0] m1_114_wd, m1_114_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_114 (.clk(clk), .we(m1_114_we), .wa(m1_114_wa), .wd(m1_114_wd), .ra(m1_114_ra), .rd(m1_114_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_114_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_114_ra <= drow;
    logic m1_115_we; logic [8:0] m1_115_wa, m1_115_ra; logic [63:0] m1_115_wd, m1_115_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_115 (.clk(clk), .we(m1_115_we), .wa(m1_115_wa), .wd(m1_115_wd), .ra(m1_115_ra), .rd(m1_115_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_115_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_115_ra <= drow;
    logic m1_116_we; logic [8:0] m1_116_wa, m1_116_ra; logic [63:0] m1_116_wd, m1_116_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_116 (.clk(clk), .we(m1_116_we), .wa(m1_116_wa), .wd(m1_116_wd), .ra(m1_116_ra), .rd(m1_116_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_116_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_116_ra <= drow;
    logic m1_117_we; logic [8:0] m1_117_wa, m1_117_ra; logic [63:0] m1_117_wd, m1_117_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_117 (.clk(clk), .we(m1_117_we), .wa(m1_117_wa), .wd(m1_117_wd), .ra(m1_117_ra), .rd(m1_117_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_117_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_117_ra <= drow;
    logic m1_118_we; logic [8:0] m1_118_wa, m1_118_ra; logic [63:0] m1_118_wd, m1_118_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_118 (.clk(clk), .we(m1_118_we), .wa(m1_118_wa), .wd(m1_118_wd), .ra(m1_118_ra), .rd(m1_118_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_118_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_118_ra <= drow;
    logic m1_119_we; logic [8:0] m1_119_wa, m1_119_ra; logic [63:0] m1_119_wd, m1_119_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_119 (.clk(clk), .we(m1_119_we), .wa(m1_119_wa), .wd(m1_119_wd), .ra(m1_119_ra), .rd(m1_119_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_119_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_119_ra <= drow;
    logic m1_120_we; logic [8:0] m1_120_wa, m1_120_ra; logic [63:0] m1_120_wd, m1_120_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_120 (.clk(clk), .we(m1_120_we), .wa(m1_120_wa), .wd(m1_120_wd), .ra(m1_120_ra), .rd(m1_120_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_120_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_120_ra <= drow;
    logic m1_121_we; logic [8:0] m1_121_wa, m1_121_ra; logic [63:0] m1_121_wd, m1_121_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_121 (.clk(clk), .we(m1_121_we), .wa(m1_121_wa), .wd(m1_121_wd), .ra(m1_121_ra), .rd(m1_121_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_121_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_121_ra <= drow;
    logic m1_122_we; logic [8:0] m1_122_wa, m1_122_ra; logic [63:0] m1_122_wd, m1_122_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_122 (.clk(clk), .we(m1_122_we), .wa(m1_122_wa), .wd(m1_122_wd), .ra(m1_122_ra), .rd(m1_122_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_122_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_122_ra <= drow;
    logic m1_123_we; logic [8:0] m1_123_wa, m1_123_ra; logic [63:0] m1_123_wd, m1_123_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_123 (.clk(clk), .we(m1_123_we), .wa(m1_123_wa), .wd(m1_123_wd), .ra(m1_123_ra), .rd(m1_123_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_123_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_123_ra <= drow;
    logic m1_124_we; logic [8:0] m1_124_wa, m1_124_ra; logic [63:0] m1_124_wd, m1_124_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_124 (.clk(clk), .we(m1_124_we), .wa(m1_124_wa), .wd(m1_124_wd), .ra(m1_124_ra), .rd(m1_124_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_124_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_124_ra <= drow;
    logic m1_125_we; logic [8:0] m1_125_wa, m1_125_ra; logic [63:0] m1_125_wd, m1_125_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_125 (.clk(clk), .we(m1_125_we), .wa(m1_125_wa), .wd(m1_125_wd), .ra(m1_125_ra), .rd(m1_125_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_125_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_125_ra <= drow;
    logic m1_126_we; logic [8:0] m1_126_wa, m1_126_ra; logic [63:0] m1_126_wd, m1_126_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_126 (.clk(clk), .we(m1_126_we), .wa(m1_126_wa), .wd(m1_126_wd), .ra(m1_126_ra), .rd(m1_126_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_126_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_126_ra <= drow;
    logic m1_127_we; logic [8:0] m1_127_wa, m1_127_ra; logic [63:0] m1_127_wd, m1_127_rd;
    Ie_n65536_q64b_B64_rns_ram_block #(.W(64), .D(512), .A(9), .R(2)) u_m1_127 (.clk(clk), .we(m1_127_we), .wa(m1_127_wa), .wd(m1_127_wd), .ra(m1_127_ra), .rd(m1_127_rd));
    always_ff @(posedge clk) if (issue && cset == 1'b1) m1_127_ra <= (c_flip ? c_hA : c_hB); else if (dact && dset == 1'b1) m1_127_ra <= drow;
    logic [63:0] rdc0; assign rdc0 = cb_set[2] ? m1_0_rd : m0_0_rd;
    logic [63:0] rdc1; assign rdc1 = cb_set[2] ? m1_1_rd : m0_1_rd;
    logic [63:0] rdc2; assign rdc2 = cb_set[2] ? m1_2_rd : m0_2_rd;
    logic [63:0] rdc3; assign rdc3 = cb_set[2] ? m1_3_rd : m0_3_rd;
    logic [63:0] rdc4; assign rdc4 = cb_set[2] ? m1_4_rd : m0_4_rd;
    logic [63:0] rdc5; assign rdc5 = cb_set[2] ? m1_5_rd : m0_5_rd;
    logic [63:0] rdc6; assign rdc6 = cb_set[2] ? m1_6_rd : m0_6_rd;
    logic [63:0] rdc7; assign rdc7 = cb_set[2] ? m1_7_rd : m0_7_rd;
    logic [63:0] rdc8; assign rdc8 = cb_set[2] ? m1_8_rd : m0_8_rd;
    logic [63:0] rdc9; assign rdc9 = cb_set[2] ? m1_9_rd : m0_9_rd;
    logic [63:0] rdc10; assign rdc10 = cb_set[2] ? m1_10_rd : m0_10_rd;
    logic [63:0] rdc11; assign rdc11 = cb_set[2] ? m1_11_rd : m0_11_rd;
    logic [63:0] rdc12; assign rdc12 = cb_set[2] ? m1_12_rd : m0_12_rd;
    logic [63:0] rdc13; assign rdc13 = cb_set[2] ? m1_13_rd : m0_13_rd;
    logic [63:0] rdc14; assign rdc14 = cb_set[2] ? m1_14_rd : m0_14_rd;
    logic [63:0] rdc15; assign rdc15 = cb_set[2] ? m1_15_rd : m0_15_rd;
    logic [63:0] rdc16; assign rdc16 = cb_set[2] ? m1_16_rd : m0_16_rd;
    logic [63:0] rdc17; assign rdc17 = cb_set[2] ? m1_17_rd : m0_17_rd;
    logic [63:0] rdc18; assign rdc18 = cb_set[2] ? m1_18_rd : m0_18_rd;
    logic [63:0] rdc19; assign rdc19 = cb_set[2] ? m1_19_rd : m0_19_rd;
    logic [63:0] rdc20; assign rdc20 = cb_set[2] ? m1_20_rd : m0_20_rd;
    logic [63:0] rdc21; assign rdc21 = cb_set[2] ? m1_21_rd : m0_21_rd;
    logic [63:0] rdc22; assign rdc22 = cb_set[2] ? m1_22_rd : m0_22_rd;
    logic [63:0] rdc23; assign rdc23 = cb_set[2] ? m1_23_rd : m0_23_rd;
    logic [63:0] rdc24; assign rdc24 = cb_set[2] ? m1_24_rd : m0_24_rd;
    logic [63:0] rdc25; assign rdc25 = cb_set[2] ? m1_25_rd : m0_25_rd;
    logic [63:0] rdc26; assign rdc26 = cb_set[2] ? m1_26_rd : m0_26_rd;
    logic [63:0] rdc27; assign rdc27 = cb_set[2] ? m1_27_rd : m0_27_rd;
    logic [63:0] rdc28; assign rdc28 = cb_set[2] ? m1_28_rd : m0_28_rd;
    logic [63:0] rdc29; assign rdc29 = cb_set[2] ? m1_29_rd : m0_29_rd;
    logic [63:0] rdc30; assign rdc30 = cb_set[2] ? m1_30_rd : m0_30_rd;
    logic [63:0] rdc31; assign rdc31 = cb_set[2] ? m1_31_rd : m0_31_rd;
    logic [63:0] rdc32; assign rdc32 = cb_set[2] ? m1_32_rd : m0_32_rd;
    logic [63:0] rdc33; assign rdc33 = cb_set[2] ? m1_33_rd : m0_33_rd;
    logic [63:0] rdc34; assign rdc34 = cb_set[2] ? m1_34_rd : m0_34_rd;
    logic [63:0] rdc35; assign rdc35 = cb_set[2] ? m1_35_rd : m0_35_rd;
    logic [63:0] rdc36; assign rdc36 = cb_set[2] ? m1_36_rd : m0_36_rd;
    logic [63:0] rdc37; assign rdc37 = cb_set[2] ? m1_37_rd : m0_37_rd;
    logic [63:0] rdc38; assign rdc38 = cb_set[2] ? m1_38_rd : m0_38_rd;
    logic [63:0] rdc39; assign rdc39 = cb_set[2] ? m1_39_rd : m0_39_rd;
    logic [63:0] rdc40; assign rdc40 = cb_set[2] ? m1_40_rd : m0_40_rd;
    logic [63:0] rdc41; assign rdc41 = cb_set[2] ? m1_41_rd : m0_41_rd;
    logic [63:0] rdc42; assign rdc42 = cb_set[2] ? m1_42_rd : m0_42_rd;
    logic [63:0] rdc43; assign rdc43 = cb_set[2] ? m1_43_rd : m0_43_rd;
    logic [63:0] rdc44; assign rdc44 = cb_set[2] ? m1_44_rd : m0_44_rd;
    logic [63:0] rdc45; assign rdc45 = cb_set[2] ? m1_45_rd : m0_45_rd;
    logic [63:0] rdc46; assign rdc46 = cb_set[2] ? m1_46_rd : m0_46_rd;
    logic [63:0] rdc47; assign rdc47 = cb_set[2] ? m1_47_rd : m0_47_rd;
    logic [63:0] rdc48; assign rdc48 = cb_set[2] ? m1_48_rd : m0_48_rd;
    logic [63:0] rdc49; assign rdc49 = cb_set[2] ? m1_49_rd : m0_49_rd;
    logic [63:0] rdc50; assign rdc50 = cb_set[2] ? m1_50_rd : m0_50_rd;
    logic [63:0] rdc51; assign rdc51 = cb_set[2] ? m1_51_rd : m0_51_rd;
    logic [63:0] rdc52; assign rdc52 = cb_set[2] ? m1_52_rd : m0_52_rd;
    logic [63:0] rdc53; assign rdc53 = cb_set[2] ? m1_53_rd : m0_53_rd;
    logic [63:0] rdc54; assign rdc54 = cb_set[2] ? m1_54_rd : m0_54_rd;
    logic [63:0] rdc55; assign rdc55 = cb_set[2] ? m1_55_rd : m0_55_rd;
    logic [63:0] rdc56; assign rdc56 = cb_set[2] ? m1_56_rd : m0_56_rd;
    logic [63:0] rdc57; assign rdc57 = cb_set[2] ? m1_57_rd : m0_57_rd;
    logic [63:0] rdc58; assign rdc58 = cb_set[2] ? m1_58_rd : m0_58_rd;
    logic [63:0] rdc59; assign rdc59 = cb_set[2] ? m1_59_rd : m0_59_rd;
    logic [63:0] rdc60; assign rdc60 = cb_set[2] ? m1_60_rd : m0_60_rd;
    logic [63:0] rdc61; assign rdc61 = cb_set[2] ? m1_61_rd : m0_61_rd;
    logic [63:0] rdc62; assign rdc62 = cb_set[2] ? m1_62_rd : m0_62_rd;
    logic [63:0] rdc63; assign rdc63 = cb_set[2] ? m1_63_rd : m0_63_rd;
    logic [63:0] rdc64; assign rdc64 = cb_set[2] ? m1_64_rd : m0_64_rd;
    logic [63:0] rdc65; assign rdc65 = cb_set[2] ? m1_65_rd : m0_65_rd;
    logic [63:0] rdc66; assign rdc66 = cb_set[2] ? m1_66_rd : m0_66_rd;
    logic [63:0] rdc67; assign rdc67 = cb_set[2] ? m1_67_rd : m0_67_rd;
    logic [63:0] rdc68; assign rdc68 = cb_set[2] ? m1_68_rd : m0_68_rd;
    logic [63:0] rdc69; assign rdc69 = cb_set[2] ? m1_69_rd : m0_69_rd;
    logic [63:0] rdc70; assign rdc70 = cb_set[2] ? m1_70_rd : m0_70_rd;
    logic [63:0] rdc71; assign rdc71 = cb_set[2] ? m1_71_rd : m0_71_rd;
    logic [63:0] rdc72; assign rdc72 = cb_set[2] ? m1_72_rd : m0_72_rd;
    logic [63:0] rdc73; assign rdc73 = cb_set[2] ? m1_73_rd : m0_73_rd;
    logic [63:0] rdc74; assign rdc74 = cb_set[2] ? m1_74_rd : m0_74_rd;
    logic [63:0] rdc75; assign rdc75 = cb_set[2] ? m1_75_rd : m0_75_rd;
    logic [63:0] rdc76; assign rdc76 = cb_set[2] ? m1_76_rd : m0_76_rd;
    logic [63:0] rdc77; assign rdc77 = cb_set[2] ? m1_77_rd : m0_77_rd;
    logic [63:0] rdc78; assign rdc78 = cb_set[2] ? m1_78_rd : m0_78_rd;
    logic [63:0] rdc79; assign rdc79 = cb_set[2] ? m1_79_rd : m0_79_rd;
    logic [63:0] rdc80; assign rdc80 = cb_set[2] ? m1_80_rd : m0_80_rd;
    logic [63:0] rdc81; assign rdc81 = cb_set[2] ? m1_81_rd : m0_81_rd;
    logic [63:0] rdc82; assign rdc82 = cb_set[2] ? m1_82_rd : m0_82_rd;
    logic [63:0] rdc83; assign rdc83 = cb_set[2] ? m1_83_rd : m0_83_rd;
    logic [63:0] rdc84; assign rdc84 = cb_set[2] ? m1_84_rd : m0_84_rd;
    logic [63:0] rdc85; assign rdc85 = cb_set[2] ? m1_85_rd : m0_85_rd;
    logic [63:0] rdc86; assign rdc86 = cb_set[2] ? m1_86_rd : m0_86_rd;
    logic [63:0] rdc87; assign rdc87 = cb_set[2] ? m1_87_rd : m0_87_rd;
    logic [63:0] rdc88; assign rdc88 = cb_set[2] ? m1_88_rd : m0_88_rd;
    logic [63:0] rdc89; assign rdc89 = cb_set[2] ? m1_89_rd : m0_89_rd;
    logic [63:0] rdc90; assign rdc90 = cb_set[2] ? m1_90_rd : m0_90_rd;
    logic [63:0] rdc91; assign rdc91 = cb_set[2] ? m1_91_rd : m0_91_rd;
    logic [63:0] rdc92; assign rdc92 = cb_set[2] ? m1_92_rd : m0_92_rd;
    logic [63:0] rdc93; assign rdc93 = cb_set[2] ? m1_93_rd : m0_93_rd;
    logic [63:0] rdc94; assign rdc94 = cb_set[2] ? m1_94_rd : m0_94_rd;
    logic [63:0] rdc95; assign rdc95 = cb_set[2] ? m1_95_rd : m0_95_rd;
    logic [63:0] rdc96; assign rdc96 = cb_set[2] ? m1_96_rd : m0_96_rd;
    logic [63:0] rdc97; assign rdc97 = cb_set[2] ? m1_97_rd : m0_97_rd;
    logic [63:0] rdc98; assign rdc98 = cb_set[2] ? m1_98_rd : m0_98_rd;
    logic [63:0] rdc99; assign rdc99 = cb_set[2] ? m1_99_rd : m0_99_rd;
    logic [63:0] rdc100; assign rdc100 = cb_set[2] ? m1_100_rd : m0_100_rd;
    logic [63:0] rdc101; assign rdc101 = cb_set[2] ? m1_101_rd : m0_101_rd;
    logic [63:0] rdc102; assign rdc102 = cb_set[2] ? m1_102_rd : m0_102_rd;
    logic [63:0] rdc103; assign rdc103 = cb_set[2] ? m1_103_rd : m0_103_rd;
    logic [63:0] rdc104; assign rdc104 = cb_set[2] ? m1_104_rd : m0_104_rd;
    logic [63:0] rdc105; assign rdc105 = cb_set[2] ? m1_105_rd : m0_105_rd;
    logic [63:0] rdc106; assign rdc106 = cb_set[2] ? m1_106_rd : m0_106_rd;
    logic [63:0] rdc107; assign rdc107 = cb_set[2] ? m1_107_rd : m0_107_rd;
    logic [63:0] rdc108; assign rdc108 = cb_set[2] ? m1_108_rd : m0_108_rd;
    logic [63:0] rdc109; assign rdc109 = cb_set[2] ? m1_109_rd : m0_109_rd;
    logic [63:0] rdc110; assign rdc110 = cb_set[2] ? m1_110_rd : m0_110_rd;
    logic [63:0] rdc111; assign rdc111 = cb_set[2] ? m1_111_rd : m0_111_rd;
    logic [63:0] rdc112; assign rdc112 = cb_set[2] ? m1_112_rd : m0_112_rd;
    logic [63:0] rdc113; assign rdc113 = cb_set[2] ? m1_113_rd : m0_113_rd;
    logic [63:0] rdc114; assign rdc114 = cb_set[2] ? m1_114_rd : m0_114_rd;
    logic [63:0] rdc115; assign rdc115 = cb_set[2] ? m1_115_rd : m0_115_rd;
    logic [63:0] rdc116; assign rdc116 = cb_set[2] ? m1_116_rd : m0_116_rd;
    logic [63:0] rdc117; assign rdc117 = cb_set[2] ? m1_117_rd : m0_117_rd;
    logic [63:0] rdc118; assign rdc118 = cb_set[2] ? m1_118_rd : m0_118_rd;
    logic [63:0] rdc119; assign rdc119 = cb_set[2] ? m1_119_rd : m0_119_rd;
    logic [63:0] rdc120; assign rdc120 = cb_set[2] ? m1_120_rd : m0_120_rd;
    logic [63:0] rdc121; assign rdc121 = cb_set[2] ? m1_121_rd : m0_121_rd;
    logic [63:0] rdc122; assign rdc122 = cb_set[2] ? m1_122_rd : m0_122_rd;
    logic [63:0] rdc123; assign rdc123 = cb_set[2] ? m1_123_rd : m0_123_rd;
    logic [63:0] rdc124; assign rdc124 = cb_set[2] ? m1_124_rd : m0_124_rd;
    logic [63:0] rdc125; assign rdc125 = cb_set[2] ? m1_125_rd : m0_125_rd;
    logic [63:0] rdc126; assign rdc126 = cb_set[2] ? m1_126_rd : m0_126_rd;
    logic [63:0] rdc127; assign rdc127 = cb_set[2] ? m1_127_rd : m0_127_rd;
    // ---- operand mux (sources per port: IterativeNTTScheme.readSources)
    logic [63:0] op0;
    always_ff @(posedge clk) case (rc0)
        1'd0: op0 <= rdc0;
        1'd1: op0 <= rdc64;
        default: op0 <= rdc0;
    endcase
    logic [63:0] op1;
    always_ff @(posedge clk) case (rc1)
        4'd0: op1 <= rdc0;
        4'd1: op1 <= rdc1;
        4'd2: op1 <= rdc2;
        4'd3: op1 <= rdc4;
        4'd4: op1 <= rdc8;
        4'd5: op1 <= rdc16;
        4'd6: op1 <= rdc32;
        4'd7: op1 <= rdc64;
        4'd8: op1 <= rdc65;
        4'd9: op1 <= rdc66;
        4'd10: op1 <= rdc68;
        4'd11: op1 <= rdc72;
        4'd12: op1 <= rdc80;
        4'd13: op1 <= rdc96;
        default: op1 <= rdc0;
    endcase
    logic [63:0] op2;
    always_ff @(posedge clk) case (rc2)
        2'd0: op2 <= rdc1;
        2'd1: op2 <= rdc2;
        2'd2: op2 <= rdc65;
        2'd3: op2 <= rdc66;
        default: op2 <= rdc1;
    endcase
    logic [63:0] op3;
    always_ff @(posedge clk) case (rc3)
        4'd0: op3 <= rdc1;
        4'd1: op3 <= rdc3;
        4'd2: op3 <= rdc5;
        4'd3: op3 <= rdc9;
        4'd4: op3 <= rdc17;
        4'd5: op3 <= rdc33;
        4'd6: op3 <= rdc65;
        4'd7: op3 <= rdc67;
        4'd8: op3 <= rdc69;
        4'd9: op3 <= rdc73;
        4'd10: op3 <= rdc81;
        4'd11: op3 <= rdc97;
        default: op3 <= rdc1;
    endcase
    logic [63:0] op4;
    always_ff @(posedge clk) case (rc4)
        2'd0: op4 <= rdc2;
        2'd1: op4 <= rdc4;
        2'd2: op4 <= rdc66;
        2'd3: op4 <= rdc68;
        default: op4 <= rdc2;
    endcase
    logic [63:0] op5;
    always_ff @(posedge clk) case (rc5)
        4'd0: op5 <= rdc2;
        4'd1: op5 <= rdc5;
        4'd2: op5 <= rdc6;
        4'd3: op5 <= rdc10;
        4'd4: op5 <= rdc18;
        4'd5: op5 <= rdc34;
        4'd6: op5 <= rdc66;
        4'd7: op5 <= rdc69;
        4'd8: op5 <= rdc70;
        4'd9: op5 <= rdc74;
        4'd10: op5 <= rdc82;
        4'd11: op5 <= rdc98;
        default: op5 <= rdc2;
    endcase
    logic [63:0] op6;
    always_ff @(posedge clk) case (rc6)
        3'd0: op6 <= rdc3;
        3'd1: op6 <= rdc5;
        3'd2: op6 <= rdc6;
        3'd3: op6 <= rdc67;
        3'd4: op6 <= rdc69;
        3'd5: op6 <= rdc70;
        default: op6 <= rdc3;
    endcase
    logic [63:0] op7;
    always_ff @(posedge clk) case (rc7)
        4'd0: op7 <= rdc3;
        4'd1: op7 <= rdc7;
        4'd2: op7 <= rdc11;
        4'd3: op7 <= rdc19;
        4'd4: op7 <= rdc35;
        4'd5: op7 <= rdc67;
        4'd6: op7 <= rdc71;
        4'd7: op7 <= rdc75;
        4'd8: op7 <= rdc83;
        4'd9: op7 <= rdc99;
        default: op7 <= rdc3;
    endcase
    logic [63:0] op8;
    always_ff @(posedge clk) case (rc8)
        2'd0: op8 <= rdc4;
        2'd1: op8 <= rdc8;
        2'd2: op8 <= rdc68;
        2'd3: op8 <= rdc72;
        default: op8 <= rdc4;
    endcase
    logic [63:0] op9;
    always_ff @(posedge clk) case (rc9)
        4'd0: op9 <= rdc4;
        4'd1: op9 <= rdc9;
        4'd2: op9 <= rdc10;
        4'd3: op9 <= rdc12;
        4'd4: op9 <= rdc20;
        4'd5: op9 <= rdc36;
        4'd6: op9 <= rdc68;
        4'd7: op9 <= rdc73;
        4'd8: op9 <= rdc74;
        4'd9: op9 <= rdc76;
        4'd10: op9 <= rdc84;
        4'd11: op9 <= rdc100;
        default: op9 <= rdc4;
    endcase
    logic [63:0] op10;
    always_ff @(posedge clk) case (rc10)
        3'd0: op10 <= rdc5;
        3'd1: op10 <= rdc9;
        3'd2: op10 <= rdc10;
        3'd3: op10 <= rdc69;
        3'd4: op10 <= rdc73;
        3'd5: op10 <= rdc74;
        default: op10 <= rdc5;
    endcase
    logic [63:0] op11;
    always_ff @(posedge clk) case (rc11)
        4'd0: op11 <= rdc5;
        4'd1: op11 <= rdc11;
        4'd2: op11 <= rdc13;
        4'd3: op11 <= rdc21;
        4'd4: op11 <= rdc37;
        4'd5: op11 <= rdc69;
        4'd6: op11 <= rdc75;
        4'd7: op11 <= rdc77;
        4'd8: op11 <= rdc85;
        4'd9: op11 <= rdc101;
        default: op11 <= rdc5;
    endcase
    logic [63:0] op12;
    always_ff @(posedge clk) case (rc12)
        3'd0: op12 <= rdc6;
        3'd1: op12 <= rdc10;
        3'd2: op12 <= rdc12;
        3'd3: op12 <= rdc70;
        3'd4: op12 <= rdc74;
        3'd5: op12 <= rdc76;
        default: op12 <= rdc6;
    endcase
    logic [63:0] op13;
    always_ff @(posedge clk) case (rc13)
        4'd0: op13 <= rdc6;
        4'd1: op13 <= rdc13;
        4'd2: op13 <= rdc14;
        4'd3: op13 <= rdc22;
        4'd4: op13 <= rdc38;
        4'd5: op13 <= rdc70;
        4'd6: op13 <= rdc77;
        4'd7: op13 <= rdc78;
        4'd8: op13 <= rdc86;
        4'd9: op13 <= rdc102;
        default: op13 <= rdc6;
    endcase
    logic [63:0] op14;
    always_ff @(posedge clk) case (rc14)
        3'd0: op14 <= rdc7;
        3'd1: op14 <= rdc11;
        3'd2: op14 <= rdc13;
        3'd3: op14 <= rdc14;
        3'd4: op14 <= rdc71;
        3'd5: op14 <= rdc75;
        3'd6: op14 <= rdc77;
        3'd7: op14 <= rdc78;
        default: op14 <= rdc7;
    endcase
    logic [63:0] op15;
    always_ff @(posedge clk) case (rc15)
        3'd0: op15 <= rdc7;
        3'd1: op15 <= rdc15;
        3'd2: op15 <= rdc23;
        3'd3: op15 <= rdc39;
        3'd4: op15 <= rdc71;
        3'd5: op15 <= rdc79;
        3'd6: op15 <= rdc87;
        3'd7: op15 <= rdc103;
        default: op15 <= rdc7;
    endcase
    logic [63:0] op16;
    always_ff @(posedge clk) case (rc16)
        2'd0: op16 <= rdc8;
        2'd1: op16 <= rdc16;
        2'd2: op16 <= rdc72;
        2'd3: op16 <= rdc80;
        default: op16 <= rdc8;
    endcase
    logic [63:0] op17;
    always_ff @(posedge clk) case (rc17)
        4'd0: op17 <= rdc8;
        4'd1: op17 <= rdc17;
        4'd2: op17 <= rdc18;
        4'd3: op17 <= rdc20;
        4'd4: op17 <= rdc24;
        4'd5: op17 <= rdc40;
        4'd6: op17 <= rdc72;
        4'd7: op17 <= rdc81;
        4'd8: op17 <= rdc82;
        4'd9: op17 <= rdc84;
        4'd10: op17 <= rdc88;
        4'd11: op17 <= rdc104;
        default: op17 <= rdc8;
    endcase
    logic [63:0] op18;
    always_ff @(posedge clk) case (rc18)
        3'd0: op18 <= rdc9;
        3'd1: op18 <= rdc17;
        3'd2: op18 <= rdc18;
        3'd3: op18 <= rdc73;
        3'd4: op18 <= rdc81;
        3'd5: op18 <= rdc82;
        default: op18 <= rdc9;
    endcase
    logic [63:0] op19;
    always_ff @(posedge clk) case (rc19)
        4'd0: op19 <= rdc9;
        4'd1: op19 <= rdc19;
        4'd2: op19 <= rdc21;
        4'd3: op19 <= rdc25;
        4'd4: op19 <= rdc41;
        4'd5: op19 <= rdc73;
        4'd6: op19 <= rdc83;
        4'd7: op19 <= rdc85;
        4'd8: op19 <= rdc89;
        4'd9: op19 <= rdc105;
        default: op19 <= rdc9;
    endcase
    logic [63:0] op20;
    always_ff @(posedge clk) case (rc20)
        3'd0: op20 <= rdc10;
        3'd1: op20 <= rdc18;
        3'd2: op20 <= rdc20;
        3'd3: op20 <= rdc74;
        3'd4: op20 <= rdc82;
        3'd5: op20 <= rdc84;
        default: op20 <= rdc10;
    endcase
    logic [63:0] op21;
    always_ff @(posedge clk) case (rc21)
        4'd0: op21 <= rdc10;
        4'd1: op21 <= rdc21;
        4'd2: op21 <= rdc22;
        4'd3: op21 <= rdc26;
        4'd4: op21 <= rdc42;
        4'd5: op21 <= rdc74;
        4'd6: op21 <= rdc85;
        4'd7: op21 <= rdc86;
        4'd8: op21 <= rdc90;
        4'd9: op21 <= rdc106;
        default: op21 <= rdc10;
    endcase
    logic [63:0] op22;
    always_ff @(posedge clk) case (rc22)
        3'd0: op22 <= rdc11;
        3'd1: op22 <= rdc19;
        3'd2: op22 <= rdc21;
        3'd3: op22 <= rdc22;
        3'd4: op22 <= rdc75;
        3'd5: op22 <= rdc83;
        3'd6: op22 <= rdc85;
        3'd7: op22 <= rdc86;
        default: op22 <= rdc11;
    endcase
    logic [63:0] op23;
    always_ff @(posedge clk) case (rc23)
        3'd0: op23 <= rdc11;
        3'd1: op23 <= rdc23;
        3'd2: op23 <= rdc27;
        3'd3: op23 <= rdc43;
        3'd4: op23 <= rdc75;
        3'd5: op23 <= rdc87;
        3'd6: op23 <= rdc91;
        3'd7: op23 <= rdc107;
        default: op23 <= rdc11;
    endcase
    logic [63:0] op24;
    always_ff @(posedge clk) case (rc24)
        3'd0: op24 <= rdc12;
        3'd1: op24 <= rdc20;
        3'd2: op24 <= rdc24;
        3'd3: op24 <= rdc76;
        3'd4: op24 <= rdc84;
        3'd5: op24 <= rdc88;
        default: op24 <= rdc12;
    endcase
    logic [63:0] op25;
    always_ff @(posedge clk) case (rc25)
        4'd0: op25 <= rdc12;
        4'd1: op25 <= rdc25;
        4'd2: op25 <= rdc26;
        4'd3: op25 <= rdc28;
        4'd4: op25 <= rdc44;
        4'd5: op25 <= rdc76;
        4'd6: op25 <= rdc89;
        4'd7: op25 <= rdc90;
        4'd8: op25 <= rdc92;
        4'd9: op25 <= rdc108;
        default: op25 <= rdc12;
    endcase
    logic [63:0] op26;
    always_ff @(posedge clk) case (rc26)
        3'd0: op26 <= rdc13;
        3'd1: op26 <= rdc21;
        3'd2: op26 <= rdc25;
        3'd3: op26 <= rdc26;
        3'd4: op26 <= rdc77;
        3'd5: op26 <= rdc85;
        3'd6: op26 <= rdc89;
        3'd7: op26 <= rdc90;
        default: op26 <= rdc13;
    endcase
    logic [63:0] op27;
    always_ff @(posedge clk) case (rc27)
        3'd0: op27 <= rdc13;
        3'd1: op27 <= rdc27;
        3'd2: op27 <= rdc29;
        3'd3: op27 <= rdc45;
        3'd4: op27 <= rdc77;
        3'd5: op27 <= rdc91;
        3'd6: op27 <= rdc93;
        3'd7: op27 <= rdc109;
        default: op27 <= rdc13;
    endcase
    logic [63:0] op28;
    always_ff @(posedge clk) case (rc28)
        3'd0: op28 <= rdc14;
        3'd1: op28 <= rdc22;
        3'd2: op28 <= rdc26;
        3'd3: op28 <= rdc28;
        3'd4: op28 <= rdc78;
        3'd5: op28 <= rdc86;
        3'd6: op28 <= rdc90;
        3'd7: op28 <= rdc92;
        default: op28 <= rdc14;
    endcase
    logic [63:0] op29;
    always_ff @(posedge clk) case (rc29)
        3'd0: op29 <= rdc14;
        3'd1: op29 <= rdc29;
        3'd2: op29 <= rdc30;
        3'd3: op29 <= rdc46;
        3'd4: op29 <= rdc78;
        3'd5: op29 <= rdc93;
        3'd6: op29 <= rdc94;
        3'd7: op29 <= rdc110;
        default: op29 <= rdc14;
    endcase
    logic [63:0] op30;
    always_ff @(posedge clk) case (rc30)
        4'd0: op30 <= rdc15;
        4'd1: op30 <= rdc23;
        4'd2: op30 <= rdc27;
        4'd3: op30 <= rdc29;
        4'd4: op30 <= rdc30;
        4'd5: op30 <= rdc79;
        4'd6: op30 <= rdc87;
        4'd7: op30 <= rdc91;
        4'd8: op30 <= rdc93;
        4'd9: op30 <= rdc94;
        default: op30 <= rdc15;
    endcase
    logic [63:0] op31;
    always_ff @(posedge clk) case (rc31)
        3'd0: op31 <= rdc15;
        3'd1: op31 <= rdc31;
        3'd2: op31 <= rdc47;
        3'd3: op31 <= rdc79;
        3'd4: op31 <= rdc95;
        3'd5: op31 <= rdc111;
        default: op31 <= rdc15;
    endcase
    logic [63:0] op32;
    always_ff @(posedge clk) case (rc32)
        2'd0: op32 <= rdc16;
        2'd1: op32 <= rdc32;
        2'd2: op32 <= rdc80;
        2'd3: op32 <= rdc96;
        default: op32 <= rdc16;
    endcase
    logic [63:0] op33;
    always_ff @(posedge clk) case (rc33)
        4'd0: op33 <= rdc16;
        4'd1: op33 <= rdc33;
        4'd2: op33 <= rdc34;
        4'd3: op33 <= rdc36;
        4'd4: op33 <= rdc40;
        4'd5: op33 <= rdc48;
        4'd6: op33 <= rdc80;
        4'd7: op33 <= rdc97;
        4'd8: op33 <= rdc98;
        4'd9: op33 <= rdc100;
        4'd10: op33 <= rdc104;
        4'd11: op33 <= rdc112;
        default: op33 <= rdc16;
    endcase
    logic [63:0] op34;
    always_ff @(posedge clk) case (rc34)
        3'd0: op34 <= rdc17;
        3'd1: op34 <= rdc33;
        3'd2: op34 <= rdc34;
        3'd3: op34 <= rdc81;
        3'd4: op34 <= rdc97;
        3'd5: op34 <= rdc98;
        default: op34 <= rdc17;
    endcase
    logic [63:0] op35;
    always_ff @(posedge clk) case (rc35)
        4'd0: op35 <= rdc17;
        4'd1: op35 <= rdc35;
        4'd2: op35 <= rdc37;
        4'd3: op35 <= rdc41;
        4'd4: op35 <= rdc49;
        4'd5: op35 <= rdc81;
        4'd6: op35 <= rdc99;
        4'd7: op35 <= rdc101;
        4'd8: op35 <= rdc105;
        4'd9: op35 <= rdc113;
        default: op35 <= rdc17;
    endcase
    logic [63:0] op36;
    always_ff @(posedge clk) case (rc36)
        3'd0: op36 <= rdc18;
        3'd1: op36 <= rdc34;
        3'd2: op36 <= rdc36;
        3'd3: op36 <= rdc82;
        3'd4: op36 <= rdc98;
        3'd5: op36 <= rdc100;
        default: op36 <= rdc18;
    endcase
    logic [63:0] op37;
    always_ff @(posedge clk) case (rc37)
        4'd0: op37 <= rdc18;
        4'd1: op37 <= rdc37;
        4'd2: op37 <= rdc38;
        4'd3: op37 <= rdc42;
        4'd4: op37 <= rdc50;
        4'd5: op37 <= rdc82;
        4'd6: op37 <= rdc101;
        4'd7: op37 <= rdc102;
        4'd8: op37 <= rdc106;
        4'd9: op37 <= rdc114;
        default: op37 <= rdc18;
    endcase
    logic [63:0] op38;
    always_ff @(posedge clk) case (rc38)
        3'd0: op38 <= rdc19;
        3'd1: op38 <= rdc35;
        3'd2: op38 <= rdc37;
        3'd3: op38 <= rdc38;
        3'd4: op38 <= rdc83;
        3'd5: op38 <= rdc99;
        3'd6: op38 <= rdc101;
        3'd7: op38 <= rdc102;
        default: op38 <= rdc19;
    endcase
    logic [63:0] op39;
    always_ff @(posedge clk) case (rc39)
        3'd0: op39 <= rdc19;
        3'd1: op39 <= rdc39;
        3'd2: op39 <= rdc43;
        3'd3: op39 <= rdc51;
        3'd4: op39 <= rdc83;
        3'd5: op39 <= rdc103;
        3'd6: op39 <= rdc107;
        3'd7: op39 <= rdc115;
        default: op39 <= rdc19;
    endcase
    logic [63:0] op40;
    always_ff @(posedge clk) case (rc40)
        3'd0: op40 <= rdc20;
        3'd1: op40 <= rdc36;
        3'd2: op40 <= rdc40;
        3'd3: op40 <= rdc84;
        3'd4: op40 <= rdc100;
        3'd5: op40 <= rdc104;
        default: op40 <= rdc20;
    endcase
    logic [63:0] op41;
    always_ff @(posedge clk) case (rc41)
        4'd0: op41 <= rdc20;
        4'd1: op41 <= rdc41;
        4'd2: op41 <= rdc42;
        4'd3: op41 <= rdc44;
        4'd4: op41 <= rdc52;
        4'd5: op41 <= rdc84;
        4'd6: op41 <= rdc105;
        4'd7: op41 <= rdc106;
        4'd8: op41 <= rdc108;
        4'd9: op41 <= rdc116;
        default: op41 <= rdc20;
    endcase
    logic [63:0] op42;
    always_ff @(posedge clk) case (rc42)
        3'd0: op42 <= rdc21;
        3'd1: op42 <= rdc37;
        3'd2: op42 <= rdc41;
        3'd3: op42 <= rdc42;
        3'd4: op42 <= rdc85;
        3'd5: op42 <= rdc101;
        3'd6: op42 <= rdc105;
        3'd7: op42 <= rdc106;
        default: op42 <= rdc21;
    endcase
    logic [63:0] op43;
    always_ff @(posedge clk) case (rc43)
        3'd0: op43 <= rdc21;
        3'd1: op43 <= rdc43;
        3'd2: op43 <= rdc45;
        3'd3: op43 <= rdc53;
        3'd4: op43 <= rdc85;
        3'd5: op43 <= rdc107;
        3'd6: op43 <= rdc109;
        3'd7: op43 <= rdc117;
        default: op43 <= rdc21;
    endcase
    logic [63:0] op44;
    always_ff @(posedge clk) case (rc44)
        3'd0: op44 <= rdc22;
        3'd1: op44 <= rdc38;
        3'd2: op44 <= rdc42;
        3'd3: op44 <= rdc44;
        3'd4: op44 <= rdc86;
        3'd5: op44 <= rdc102;
        3'd6: op44 <= rdc106;
        3'd7: op44 <= rdc108;
        default: op44 <= rdc22;
    endcase
    logic [63:0] op45;
    always_ff @(posedge clk) case (rc45)
        3'd0: op45 <= rdc22;
        3'd1: op45 <= rdc45;
        3'd2: op45 <= rdc46;
        3'd3: op45 <= rdc54;
        3'd4: op45 <= rdc86;
        3'd5: op45 <= rdc109;
        3'd6: op45 <= rdc110;
        3'd7: op45 <= rdc118;
        default: op45 <= rdc22;
    endcase
    logic [63:0] op46;
    always_ff @(posedge clk) case (rc46)
        4'd0: op46 <= rdc23;
        4'd1: op46 <= rdc39;
        4'd2: op46 <= rdc43;
        4'd3: op46 <= rdc45;
        4'd4: op46 <= rdc46;
        4'd5: op46 <= rdc87;
        4'd6: op46 <= rdc103;
        4'd7: op46 <= rdc107;
        4'd8: op46 <= rdc109;
        4'd9: op46 <= rdc110;
        default: op46 <= rdc23;
    endcase
    logic [63:0] op47;
    always_ff @(posedge clk) case (rc47)
        3'd0: op47 <= rdc23;
        3'd1: op47 <= rdc47;
        3'd2: op47 <= rdc55;
        3'd3: op47 <= rdc87;
        3'd4: op47 <= rdc111;
        3'd5: op47 <= rdc119;
        default: op47 <= rdc23;
    endcase
    logic [63:0] op48;
    always_ff @(posedge clk) case (rc48)
        3'd0: op48 <= rdc24;
        3'd1: op48 <= rdc40;
        3'd2: op48 <= rdc48;
        3'd3: op48 <= rdc88;
        3'd4: op48 <= rdc104;
        3'd5: op48 <= rdc112;
        default: op48 <= rdc24;
    endcase
    logic [63:0] op49;
    always_ff @(posedge clk) case (rc49)
        4'd0: op49 <= rdc24;
        4'd1: op49 <= rdc49;
        4'd2: op49 <= rdc50;
        4'd3: op49 <= rdc52;
        4'd4: op49 <= rdc56;
        4'd5: op49 <= rdc88;
        4'd6: op49 <= rdc113;
        4'd7: op49 <= rdc114;
        4'd8: op49 <= rdc116;
        4'd9: op49 <= rdc120;
        default: op49 <= rdc24;
    endcase
    logic [63:0] op50;
    always_ff @(posedge clk) case (rc50)
        3'd0: op50 <= rdc25;
        3'd1: op50 <= rdc41;
        3'd2: op50 <= rdc49;
        3'd3: op50 <= rdc50;
        3'd4: op50 <= rdc89;
        3'd5: op50 <= rdc105;
        3'd6: op50 <= rdc113;
        3'd7: op50 <= rdc114;
        default: op50 <= rdc25;
    endcase
    logic [63:0] op51;
    always_ff @(posedge clk) case (rc51)
        3'd0: op51 <= rdc25;
        3'd1: op51 <= rdc51;
        3'd2: op51 <= rdc53;
        3'd3: op51 <= rdc57;
        3'd4: op51 <= rdc89;
        3'd5: op51 <= rdc115;
        3'd6: op51 <= rdc117;
        3'd7: op51 <= rdc121;
        default: op51 <= rdc25;
    endcase
    logic [63:0] op52;
    always_ff @(posedge clk) case (rc52)
        3'd0: op52 <= rdc26;
        3'd1: op52 <= rdc42;
        3'd2: op52 <= rdc50;
        3'd3: op52 <= rdc52;
        3'd4: op52 <= rdc90;
        3'd5: op52 <= rdc106;
        3'd6: op52 <= rdc114;
        3'd7: op52 <= rdc116;
        default: op52 <= rdc26;
    endcase
    logic [63:0] op53;
    always_ff @(posedge clk) case (rc53)
        3'd0: op53 <= rdc26;
        3'd1: op53 <= rdc53;
        3'd2: op53 <= rdc54;
        3'd3: op53 <= rdc58;
        3'd4: op53 <= rdc90;
        3'd5: op53 <= rdc117;
        3'd6: op53 <= rdc118;
        3'd7: op53 <= rdc122;
        default: op53 <= rdc26;
    endcase
    logic [63:0] op54;
    always_ff @(posedge clk) case (rc54)
        4'd0: op54 <= rdc27;
        4'd1: op54 <= rdc43;
        4'd2: op54 <= rdc51;
        4'd3: op54 <= rdc53;
        4'd4: op54 <= rdc54;
        4'd5: op54 <= rdc91;
        4'd6: op54 <= rdc107;
        4'd7: op54 <= rdc115;
        4'd8: op54 <= rdc117;
        4'd9: op54 <= rdc118;
        default: op54 <= rdc27;
    endcase
    logic [63:0] op55;
    always_ff @(posedge clk) case (rc55)
        3'd0: op55 <= rdc27;
        3'd1: op55 <= rdc55;
        3'd2: op55 <= rdc59;
        3'd3: op55 <= rdc91;
        3'd4: op55 <= rdc119;
        3'd5: op55 <= rdc123;
        default: op55 <= rdc27;
    endcase
    logic [63:0] op56;
    always_ff @(posedge clk) case (rc56)
        3'd0: op56 <= rdc28;
        3'd1: op56 <= rdc44;
        3'd2: op56 <= rdc52;
        3'd3: op56 <= rdc56;
        3'd4: op56 <= rdc92;
        3'd5: op56 <= rdc108;
        3'd6: op56 <= rdc116;
        3'd7: op56 <= rdc120;
        default: op56 <= rdc28;
    endcase
    logic [63:0] op57;
    always_ff @(posedge clk) case (rc57)
        3'd0: op57 <= rdc28;
        3'd1: op57 <= rdc57;
        3'd2: op57 <= rdc58;
        3'd3: op57 <= rdc60;
        3'd4: op57 <= rdc92;
        3'd5: op57 <= rdc121;
        3'd6: op57 <= rdc122;
        3'd7: op57 <= rdc124;
        default: op57 <= rdc28;
    endcase
    logic [63:0] op58;
    always_ff @(posedge clk) case (rc58)
        4'd0: op58 <= rdc29;
        4'd1: op58 <= rdc45;
        4'd2: op58 <= rdc53;
        4'd3: op58 <= rdc57;
        4'd4: op58 <= rdc58;
        4'd5: op58 <= rdc93;
        4'd6: op58 <= rdc109;
        4'd7: op58 <= rdc117;
        4'd8: op58 <= rdc121;
        4'd9: op58 <= rdc122;
        default: op58 <= rdc29;
    endcase
    logic [63:0] op59;
    always_ff @(posedge clk) case (rc59)
        3'd0: op59 <= rdc29;
        3'd1: op59 <= rdc59;
        3'd2: op59 <= rdc61;
        3'd3: op59 <= rdc93;
        3'd4: op59 <= rdc123;
        3'd5: op59 <= rdc125;
        default: op59 <= rdc29;
    endcase
    logic [63:0] op60;
    always_ff @(posedge clk) case (rc60)
        4'd0: op60 <= rdc30;
        4'd1: op60 <= rdc46;
        4'd2: op60 <= rdc54;
        4'd3: op60 <= rdc58;
        4'd4: op60 <= rdc60;
        4'd5: op60 <= rdc94;
        4'd6: op60 <= rdc110;
        4'd7: op60 <= rdc118;
        4'd8: op60 <= rdc122;
        4'd9: op60 <= rdc124;
        default: op60 <= rdc30;
    endcase
    logic [63:0] op61;
    always_ff @(posedge clk) case (rc61)
        3'd0: op61 <= rdc30;
        3'd1: op61 <= rdc61;
        3'd2: op61 <= rdc62;
        3'd3: op61 <= rdc94;
        3'd4: op61 <= rdc125;
        3'd5: op61 <= rdc126;
        default: op61 <= rdc30;
    endcase
    logic [63:0] op62;
    always_ff @(posedge clk) case (rc62)
        4'd0: op62 <= rdc31;
        4'd1: op62 <= rdc47;
        4'd2: op62 <= rdc55;
        4'd3: op62 <= rdc59;
        4'd4: op62 <= rdc61;
        4'd5: op62 <= rdc62;
        4'd6: op62 <= rdc95;
        4'd7: op62 <= rdc111;
        4'd8: op62 <= rdc119;
        4'd9: op62 <= rdc123;
        4'd10: op62 <= rdc125;
        4'd11: op62 <= rdc126;
        default: op62 <= rdc31;
    endcase
    logic [63:0] op63;
    always_ff @(posedge clk) case (rc63)
        2'd0: op63 <= rdc31;
        2'd1: op63 <= rdc63;
        2'd2: op63 <= rdc95;
        2'd3: op63 <= rdc127;
        default: op63 <= rdc31;
    endcase
    logic [63:0] op64;
    always_ff @(posedge clk) case (rc64)
        2'd0: op64 <= rdc0;
        2'd1: op64 <= rdc32;
        2'd2: op64 <= rdc64;
        2'd3: op64 <= rdc96;
        default: op64 <= rdc0;
    endcase
    logic [63:0] op65;
    always_ff @(posedge clk) case (rc65)
        4'd0: op65 <= rdc1;
        4'd1: op65 <= rdc2;
        4'd2: op65 <= rdc4;
        4'd3: op65 <= rdc8;
        4'd4: op65 <= rdc16;
        4'd5: op65 <= rdc32;
        4'd6: op65 <= rdc65;
        4'd7: op65 <= rdc66;
        4'd8: op65 <= rdc68;
        4'd9: op65 <= rdc72;
        4'd10: op65 <= rdc80;
        4'd11: op65 <= rdc96;
        default: op65 <= rdc1;
    endcase
    logic [63:0] op66;
    always_ff @(posedge clk) case (rc66)
        3'd0: op66 <= rdc1;
        3'd1: op66 <= rdc2;
        3'd2: op66 <= rdc33;
        3'd3: op66 <= rdc65;
        3'd4: op66 <= rdc66;
        3'd5: op66 <= rdc97;
        default: op66 <= rdc1;
    endcase
    logic [63:0] op67;
    always_ff @(posedge clk) case (rc67)
        4'd0: op67 <= rdc3;
        4'd1: op67 <= rdc5;
        4'd2: op67 <= rdc9;
        4'd3: op67 <= rdc17;
        4'd4: op67 <= rdc33;
        4'd5: op67 <= rdc67;
        4'd6: op67 <= rdc69;
        4'd7: op67 <= rdc73;
        4'd8: op67 <= rdc81;
        4'd9: op67 <= rdc97;
        default: op67 <= rdc3;
    endcase
    logic [63:0] op68;
    always_ff @(posedge clk) case (rc68)
        3'd0: op68 <= rdc2;
        3'd1: op68 <= rdc4;
        3'd2: op68 <= rdc34;
        3'd3: op68 <= rdc66;
        3'd4: op68 <= rdc68;
        3'd5: op68 <= rdc98;
        default: op68 <= rdc2;
    endcase
    logic [63:0] op69;
    always_ff @(posedge clk) case (rc69)
        4'd0: op69 <= rdc5;
        4'd1: op69 <= rdc6;
        4'd2: op69 <= rdc10;
        4'd3: op69 <= rdc18;
        4'd4: op69 <= rdc34;
        4'd5: op69 <= rdc69;
        4'd6: op69 <= rdc70;
        4'd7: op69 <= rdc74;
        4'd8: op69 <= rdc82;
        4'd9: op69 <= rdc98;
        default: op69 <= rdc5;
    endcase
    logic [63:0] op70;
    always_ff @(posedge clk) case (rc70)
        3'd0: op70 <= rdc3;
        3'd1: op70 <= rdc5;
        3'd2: op70 <= rdc6;
        3'd3: op70 <= rdc35;
        3'd4: op70 <= rdc67;
        3'd5: op70 <= rdc69;
        3'd6: op70 <= rdc70;
        3'd7: op70 <= rdc99;
        default: op70 <= rdc3;
    endcase
    logic [63:0] op71;
    always_ff @(posedge clk) case (rc71)
        3'd0: op71 <= rdc7;
        3'd1: op71 <= rdc11;
        3'd2: op71 <= rdc19;
        3'd3: op71 <= rdc35;
        3'd4: op71 <= rdc71;
        3'd5: op71 <= rdc75;
        3'd6: op71 <= rdc83;
        3'd7: op71 <= rdc99;
        default: op71 <= rdc7;
    endcase
    logic [63:0] op72;
    always_ff @(posedge clk) case (rc72)
        3'd0: op72 <= rdc4;
        3'd1: op72 <= rdc8;
        3'd2: op72 <= rdc36;
        3'd3: op72 <= rdc68;
        3'd4: op72 <= rdc72;
        3'd5: op72 <= rdc100;
        default: op72 <= rdc4;
    endcase
    logic [63:0] op73;
    always_ff @(posedge clk) case (rc73)
        4'd0: op73 <= rdc9;
        4'd1: op73 <= rdc10;
        4'd2: op73 <= rdc12;
        4'd3: op73 <= rdc20;
        4'd4: op73 <= rdc36;
        4'd5: op73 <= rdc73;
        4'd6: op73 <= rdc74;
        4'd7: op73 <= rdc76;
        4'd8: op73 <= rdc84;
        4'd9: op73 <= rdc100;
        default: op73 <= rdc9;
    endcase
    logic [63:0] op74;
    always_ff @(posedge clk) case (rc74)
        3'd0: op74 <= rdc5;
        3'd1: op74 <= rdc9;
        3'd2: op74 <= rdc10;
        3'd3: op74 <= rdc37;
        3'd4: op74 <= rdc69;
        3'd5: op74 <= rdc73;
        3'd6: op74 <= rdc74;
        3'd7: op74 <= rdc101;
        default: op74 <= rdc5;
    endcase
    logic [63:0] op75;
    always_ff @(posedge clk) case (rc75)
        3'd0: op75 <= rdc11;
        3'd1: op75 <= rdc13;
        3'd2: op75 <= rdc21;
        3'd3: op75 <= rdc37;
        3'd4: op75 <= rdc75;
        3'd5: op75 <= rdc77;
        3'd6: op75 <= rdc85;
        3'd7: op75 <= rdc101;
        default: op75 <= rdc11;
    endcase
    logic [63:0] op76;
    always_ff @(posedge clk) case (rc76)
        3'd0: op76 <= rdc6;
        3'd1: op76 <= rdc10;
        3'd2: op76 <= rdc12;
        3'd3: op76 <= rdc38;
        3'd4: op76 <= rdc70;
        3'd5: op76 <= rdc74;
        3'd6: op76 <= rdc76;
        3'd7: op76 <= rdc102;
        default: op76 <= rdc6;
    endcase
    logic [63:0] op77;
    always_ff @(posedge clk) case (rc77)
        3'd0: op77 <= rdc13;
        3'd1: op77 <= rdc14;
        3'd2: op77 <= rdc22;
        3'd3: op77 <= rdc38;
        3'd4: op77 <= rdc77;
        3'd5: op77 <= rdc78;
        3'd6: op77 <= rdc86;
        3'd7: op77 <= rdc102;
        default: op77 <= rdc13;
    endcase
    logic [63:0] op78;
    always_ff @(posedge clk) case (rc78)
        4'd0: op78 <= rdc7;
        4'd1: op78 <= rdc11;
        4'd2: op78 <= rdc13;
        4'd3: op78 <= rdc14;
        4'd4: op78 <= rdc39;
        4'd5: op78 <= rdc71;
        4'd6: op78 <= rdc75;
        4'd7: op78 <= rdc77;
        4'd8: op78 <= rdc78;
        4'd9: op78 <= rdc103;
        default: op78 <= rdc7;
    endcase
    logic [63:0] op79;
    always_ff @(posedge clk) case (rc79)
        3'd0: op79 <= rdc15;
        3'd1: op79 <= rdc23;
        3'd2: op79 <= rdc39;
        3'd3: op79 <= rdc79;
        3'd4: op79 <= rdc87;
        3'd5: op79 <= rdc103;
        default: op79 <= rdc15;
    endcase
    logic [63:0] op80;
    always_ff @(posedge clk) case (rc80)
        3'd0: op80 <= rdc8;
        3'd1: op80 <= rdc16;
        3'd2: op80 <= rdc40;
        3'd3: op80 <= rdc72;
        3'd4: op80 <= rdc80;
        3'd5: op80 <= rdc104;
        default: op80 <= rdc8;
    endcase
    logic [63:0] op81;
    always_ff @(posedge clk) case (rc81)
        4'd0: op81 <= rdc17;
        4'd1: op81 <= rdc18;
        4'd2: op81 <= rdc20;
        4'd3: op81 <= rdc24;
        4'd4: op81 <= rdc40;
        4'd5: op81 <= rdc81;
        4'd6: op81 <= rdc82;
        4'd7: op81 <= rdc84;
        4'd8: op81 <= rdc88;
        4'd9: op81 <= rdc104;
        default: op81 <= rdc17;
    endcase
    logic [63:0] op82;
    always_ff @(posedge clk) case (rc82)
        3'd0: op82 <= rdc9;
        3'd1: op82 <= rdc17;
        3'd2: op82 <= rdc18;
        3'd3: op82 <= rdc41;
        3'd4: op82 <= rdc73;
        3'd5: op82 <= rdc81;
        3'd6: op82 <= rdc82;
        3'd7: op82 <= rdc105;
        default: op82 <= rdc9;
    endcase
    logic [63:0] op83;
    always_ff @(posedge clk) case (rc83)
        3'd0: op83 <= rdc19;
        3'd1: op83 <= rdc21;
        3'd2: op83 <= rdc25;
        3'd3: op83 <= rdc41;
        3'd4: op83 <= rdc83;
        3'd5: op83 <= rdc85;
        3'd6: op83 <= rdc89;
        3'd7: op83 <= rdc105;
        default: op83 <= rdc19;
    endcase
    logic [63:0] op84;
    always_ff @(posedge clk) case (rc84)
        3'd0: op84 <= rdc10;
        3'd1: op84 <= rdc18;
        3'd2: op84 <= rdc20;
        3'd3: op84 <= rdc42;
        3'd4: op84 <= rdc74;
        3'd5: op84 <= rdc82;
        3'd6: op84 <= rdc84;
        3'd7: op84 <= rdc106;
        default: op84 <= rdc10;
    endcase
    logic [63:0] op85;
    always_ff @(posedge clk) case (rc85)
        3'd0: op85 <= rdc21;
        3'd1: op85 <= rdc22;
        3'd2: op85 <= rdc26;
        3'd3: op85 <= rdc42;
        3'd4: op85 <= rdc85;
        3'd5: op85 <= rdc86;
        3'd6: op85 <= rdc90;
        3'd7: op85 <= rdc106;
        default: op85 <= rdc21;
    endcase
    logic [63:0] op86;
    always_ff @(posedge clk) case (rc86)
        4'd0: op86 <= rdc11;
        4'd1: op86 <= rdc19;
        4'd2: op86 <= rdc21;
        4'd3: op86 <= rdc22;
        4'd4: op86 <= rdc43;
        4'd5: op86 <= rdc75;
        4'd6: op86 <= rdc83;
        4'd7: op86 <= rdc85;
        4'd8: op86 <= rdc86;
        4'd9: op86 <= rdc107;
        default: op86 <= rdc11;
    endcase
    logic [63:0] op87;
    always_ff @(posedge clk) case (rc87)
        3'd0: op87 <= rdc23;
        3'd1: op87 <= rdc27;
        3'd2: op87 <= rdc43;
        3'd3: op87 <= rdc87;
        3'd4: op87 <= rdc91;
        3'd5: op87 <= rdc107;
        default: op87 <= rdc23;
    endcase
    logic [63:0] op88;
    always_ff @(posedge clk) case (rc88)
        3'd0: op88 <= rdc12;
        3'd1: op88 <= rdc20;
        3'd2: op88 <= rdc24;
        3'd3: op88 <= rdc44;
        3'd4: op88 <= rdc76;
        3'd5: op88 <= rdc84;
        3'd6: op88 <= rdc88;
        3'd7: op88 <= rdc108;
        default: op88 <= rdc12;
    endcase
    logic [63:0] op89;
    always_ff @(posedge clk) case (rc89)
        3'd0: op89 <= rdc25;
        3'd1: op89 <= rdc26;
        3'd2: op89 <= rdc28;
        3'd3: op89 <= rdc44;
        3'd4: op89 <= rdc89;
        3'd5: op89 <= rdc90;
        3'd6: op89 <= rdc92;
        3'd7: op89 <= rdc108;
        default: op89 <= rdc25;
    endcase
    logic [63:0] op90;
    always_ff @(posedge clk) case (rc90)
        4'd0: op90 <= rdc13;
        4'd1: op90 <= rdc21;
        4'd2: op90 <= rdc25;
        4'd3: op90 <= rdc26;
        4'd4: op90 <= rdc45;
        4'd5: op90 <= rdc77;
        4'd6: op90 <= rdc85;
        4'd7: op90 <= rdc89;
        4'd8: op90 <= rdc90;
        4'd9: op90 <= rdc109;
        default: op90 <= rdc13;
    endcase
    logic [63:0] op91;
    always_ff @(posedge clk) case (rc91)
        3'd0: op91 <= rdc27;
        3'd1: op91 <= rdc29;
        3'd2: op91 <= rdc45;
        3'd3: op91 <= rdc91;
        3'd4: op91 <= rdc93;
        3'd5: op91 <= rdc109;
        default: op91 <= rdc27;
    endcase
    logic [63:0] op92;
    always_ff @(posedge clk) case (rc92)
        4'd0: op92 <= rdc14;
        4'd1: op92 <= rdc22;
        4'd2: op92 <= rdc26;
        4'd3: op92 <= rdc28;
        4'd4: op92 <= rdc46;
        4'd5: op92 <= rdc78;
        4'd6: op92 <= rdc86;
        4'd7: op92 <= rdc90;
        4'd8: op92 <= rdc92;
        4'd9: op92 <= rdc110;
        default: op92 <= rdc14;
    endcase
    logic [63:0] op93;
    always_ff @(posedge clk) case (rc93)
        3'd0: op93 <= rdc29;
        3'd1: op93 <= rdc30;
        3'd2: op93 <= rdc46;
        3'd3: op93 <= rdc93;
        3'd4: op93 <= rdc94;
        3'd5: op93 <= rdc110;
        default: op93 <= rdc29;
    endcase
    logic [63:0] op94;
    always_ff @(posedge clk) case (rc94)
        4'd0: op94 <= rdc15;
        4'd1: op94 <= rdc23;
        4'd2: op94 <= rdc27;
        4'd3: op94 <= rdc29;
        4'd4: op94 <= rdc30;
        4'd5: op94 <= rdc47;
        4'd6: op94 <= rdc79;
        4'd7: op94 <= rdc87;
        4'd8: op94 <= rdc91;
        4'd9: op94 <= rdc93;
        4'd10: op94 <= rdc94;
        4'd11: op94 <= rdc111;
        default: op94 <= rdc15;
    endcase
    logic [63:0] op95;
    always_ff @(posedge clk) case (rc95)
        2'd0: op95 <= rdc31;
        2'd1: op95 <= rdc47;
        2'd2: op95 <= rdc95;
        2'd3: op95 <= rdc111;
        default: op95 <= rdc31;
    endcase
    logic [63:0] op96;
    always_ff @(posedge clk) case (rc96)
        3'd0: op96 <= rdc16;
        3'd1: op96 <= rdc32;
        3'd2: op96 <= rdc48;
        3'd3: op96 <= rdc80;
        3'd4: op96 <= rdc96;
        3'd5: op96 <= rdc112;
        default: op96 <= rdc16;
    endcase
    logic [63:0] op97;
    always_ff @(posedge clk) case (rc97)
        4'd0: op97 <= rdc33;
        4'd1: op97 <= rdc34;
        4'd2: op97 <= rdc36;
        4'd3: op97 <= rdc40;
        4'd4: op97 <= rdc48;
        4'd5: op97 <= rdc97;
        4'd6: op97 <= rdc98;
        4'd7: op97 <= rdc100;
        4'd8: op97 <= rdc104;
        4'd9: op97 <= rdc112;
        default: op97 <= rdc33;
    endcase
    logic [63:0] op98;
    always_ff @(posedge clk) case (rc98)
        3'd0: op98 <= rdc17;
        3'd1: op98 <= rdc33;
        3'd2: op98 <= rdc34;
        3'd3: op98 <= rdc49;
        3'd4: op98 <= rdc81;
        3'd5: op98 <= rdc97;
        3'd6: op98 <= rdc98;
        3'd7: op98 <= rdc113;
        default: op98 <= rdc17;
    endcase
    logic [63:0] op99;
    always_ff @(posedge clk) case (rc99)
        3'd0: op99 <= rdc35;
        3'd1: op99 <= rdc37;
        3'd2: op99 <= rdc41;
        3'd3: op99 <= rdc49;
        3'd4: op99 <= rdc99;
        3'd5: op99 <= rdc101;
        3'd6: op99 <= rdc105;
        3'd7: op99 <= rdc113;
        default: op99 <= rdc35;
    endcase
    logic [63:0] op100;
    always_ff @(posedge clk) case (rc100)
        3'd0: op100 <= rdc18;
        3'd1: op100 <= rdc34;
        3'd2: op100 <= rdc36;
        3'd3: op100 <= rdc50;
        3'd4: op100 <= rdc82;
        3'd5: op100 <= rdc98;
        3'd6: op100 <= rdc100;
        3'd7: op100 <= rdc114;
        default: op100 <= rdc18;
    endcase
    logic [63:0] op101;
    always_ff @(posedge clk) case (rc101)
        3'd0: op101 <= rdc37;
        3'd1: op101 <= rdc38;
        3'd2: op101 <= rdc42;
        3'd3: op101 <= rdc50;
        3'd4: op101 <= rdc101;
        3'd5: op101 <= rdc102;
        3'd6: op101 <= rdc106;
        3'd7: op101 <= rdc114;
        default: op101 <= rdc37;
    endcase
    logic [63:0] op102;
    always_ff @(posedge clk) case (rc102)
        4'd0: op102 <= rdc19;
        4'd1: op102 <= rdc35;
        4'd2: op102 <= rdc37;
        4'd3: op102 <= rdc38;
        4'd4: op102 <= rdc51;
        4'd5: op102 <= rdc83;
        4'd6: op102 <= rdc99;
        4'd7: op102 <= rdc101;
        4'd8: op102 <= rdc102;
        4'd9: op102 <= rdc115;
        default: op102 <= rdc19;
    endcase
    logic [63:0] op103;
    always_ff @(posedge clk) case (rc103)
        3'd0: op103 <= rdc39;
        3'd1: op103 <= rdc43;
        3'd2: op103 <= rdc51;
        3'd3: op103 <= rdc103;
        3'd4: op103 <= rdc107;
        3'd5: op103 <= rdc115;
        default: op103 <= rdc39;
    endcase
    logic [63:0] op104;
    always_ff @(posedge clk) case (rc104)
        3'd0: op104 <= rdc20;
        3'd1: op104 <= rdc36;
        3'd2: op104 <= rdc40;
        3'd3: op104 <= rdc52;
        3'd4: op104 <= rdc84;
        3'd5: op104 <= rdc100;
        3'd6: op104 <= rdc104;
        3'd7: op104 <= rdc116;
        default: op104 <= rdc20;
    endcase
    logic [63:0] op105;
    always_ff @(posedge clk) case (rc105)
        3'd0: op105 <= rdc41;
        3'd1: op105 <= rdc42;
        3'd2: op105 <= rdc44;
        3'd3: op105 <= rdc52;
        3'd4: op105 <= rdc105;
        3'd5: op105 <= rdc106;
        3'd6: op105 <= rdc108;
        3'd7: op105 <= rdc116;
        default: op105 <= rdc41;
    endcase
    logic [63:0] op106;
    always_ff @(posedge clk) case (rc106)
        4'd0: op106 <= rdc21;
        4'd1: op106 <= rdc37;
        4'd2: op106 <= rdc41;
        4'd3: op106 <= rdc42;
        4'd4: op106 <= rdc53;
        4'd5: op106 <= rdc85;
        4'd6: op106 <= rdc101;
        4'd7: op106 <= rdc105;
        4'd8: op106 <= rdc106;
        4'd9: op106 <= rdc117;
        default: op106 <= rdc21;
    endcase
    logic [63:0] op107;
    always_ff @(posedge clk) case (rc107)
        3'd0: op107 <= rdc43;
        3'd1: op107 <= rdc45;
        3'd2: op107 <= rdc53;
        3'd3: op107 <= rdc107;
        3'd4: op107 <= rdc109;
        3'd5: op107 <= rdc117;
        default: op107 <= rdc43;
    endcase
    logic [63:0] op108;
    always_ff @(posedge clk) case (rc108)
        4'd0: op108 <= rdc22;
        4'd1: op108 <= rdc38;
        4'd2: op108 <= rdc42;
        4'd3: op108 <= rdc44;
        4'd4: op108 <= rdc54;
        4'd5: op108 <= rdc86;
        4'd6: op108 <= rdc102;
        4'd7: op108 <= rdc106;
        4'd8: op108 <= rdc108;
        4'd9: op108 <= rdc118;
        default: op108 <= rdc22;
    endcase
    logic [63:0] op109;
    always_ff @(posedge clk) case (rc109)
        3'd0: op109 <= rdc45;
        3'd1: op109 <= rdc46;
        3'd2: op109 <= rdc54;
        3'd3: op109 <= rdc109;
        3'd4: op109 <= rdc110;
        3'd5: op109 <= rdc118;
        default: op109 <= rdc45;
    endcase
    logic [63:0] op110;
    always_ff @(posedge clk) case (rc110)
        4'd0: op110 <= rdc23;
        4'd1: op110 <= rdc39;
        4'd2: op110 <= rdc43;
        4'd3: op110 <= rdc45;
        4'd4: op110 <= rdc46;
        4'd5: op110 <= rdc55;
        4'd6: op110 <= rdc87;
        4'd7: op110 <= rdc103;
        4'd8: op110 <= rdc107;
        4'd9: op110 <= rdc109;
        4'd10: op110 <= rdc110;
        4'd11: op110 <= rdc119;
        default: op110 <= rdc23;
    endcase
    logic [63:0] op111;
    always_ff @(posedge clk) case (rc111)
        2'd0: op111 <= rdc47;
        2'd1: op111 <= rdc55;
        2'd2: op111 <= rdc111;
        2'd3: op111 <= rdc119;
        default: op111 <= rdc47;
    endcase
    logic [63:0] op112;
    always_ff @(posedge clk) case (rc112)
        3'd0: op112 <= rdc24;
        3'd1: op112 <= rdc40;
        3'd2: op112 <= rdc48;
        3'd3: op112 <= rdc56;
        3'd4: op112 <= rdc88;
        3'd5: op112 <= rdc104;
        3'd6: op112 <= rdc112;
        3'd7: op112 <= rdc120;
        default: op112 <= rdc24;
    endcase
    logic [63:0] op113;
    always_ff @(posedge clk) case (rc113)
        3'd0: op113 <= rdc49;
        3'd1: op113 <= rdc50;
        3'd2: op113 <= rdc52;
        3'd3: op113 <= rdc56;
        3'd4: op113 <= rdc113;
        3'd5: op113 <= rdc114;
        3'd6: op113 <= rdc116;
        3'd7: op113 <= rdc120;
        default: op113 <= rdc49;
    endcase
    logic [63:0] op114;
    always_ff @(posedge clk) case (rc114)
        4'd0: op114 <= rdc25;
        4'd1: op114 <= rdc41;
        4'd2: op114 <= rdc49;
        4'd3: op114 <= rdc50;
        4'd4: op114 <= rdc57;
        4'd5: op114 <= rdc89;
        4'd6: op114 <= rdc105;
        4'd7: op114 <= rdc113;
        4'd8: op114 <= rdc114;
        4'd9: op114 <= rdc121;
        default: op114 <= rdc25;
    endcase
    logic [63:0] op115;
    always_ff @(posedge clk) case (rc115)
        3'd0: op115 <= rdc51;
        3'd1: op115 <= rdc53;
        3'd2: op115 <= rdc57;
        3'd3: op115 <= rdc115;
        3'd4: op115 <= rdc117;
        3'd5: op115 <= rdc121;
        default: op115 <= rdc51;
    endcase
    logic [63:0] op116;
    always_ff @(posedge clk) case (rc116)
        4'd0: op116 <= rdc26;
        4'd1: op116 <= rdc42;
        4'd2: op116 <= rdc50;
        4'd3: op116 <= rdc52;
        4'd4: op116 <= rdc58;
        4'd5: op116 <= rdc90;
        4'd6: op116 <= rdc106;
        4'd7: op116 <= rdc114;
        4'd8: op116 <= rdc116;
        4'd9: op116 <= rdc122;
        default: op116 <= rdc26;
    endcase
    logic [63:0] op117;
    always_ff @(posedge clk) case (rc117)
        3'd0: op117 <= rdc53;
        3'd1: op117 <= rdc54;
        3'd2: op117 <= rdc58;
        3'd3: op117 <= rdc117;
        3'd4: op117 <= rdc118;
        3'd5: op117 <= rdc122;
        default: op117 <= rdc53;
    endcase
    logic [63:0] op118;
    always_ff @(posedge clk) case (rc118)
        4'd0: op118 <= rdc27;
        4'd1: op118 <= rdc43;
        4'd2: op118 <= rdc51;
        4'd3: op118 <= rdc53;
        4'd4: op118 <= rdc54;
        4'd5: op118 <= rdc59;
        4'd6: op118 <= rdc91;
        4'd7: op118 <= rdc107;
        4'd8: op118 <= rdc115;
        4'd9: op118 <= rdc117;
        4'd10: op118 <= rdc118;
        4'd11: op118 <= rdc123;
        default: op118 <= rdc27;
    endcase
    logic [63:0] op119;
    always_ff @(posedge clk) case (rc119)
        2'd0: op119 <= rdc55;
        2'd1: op119 <= rdc59;
        2'd2: op119 <= rdc119;
        2'd3: op119 <= rdc123;
        default: op119 <= rdc55;
    endcase
    logic [63:0] op120;
    always_ff @(posedge clk) case (rc120)
        4'd0: op120 <= rdc28;
        4'd1: op120 <= rdc44;
        4'd2: op120 <= rdc52;
        4'd3: op120 <= rdc56;
        4'd4: op120 <= rdc60;
        4'd5: op120 <= rdc92;
        4'd6: op120 <= rdc108;
        4'd7: op120 <= rdc116;
        4'd8: op120 <= rdc120;
        4'd9: op120 <= rdc124;
        default: op120 <= rdc28;
    endcase
    logic [63:0] op121;
    always_ff @(posedge clk) case (rc121)
        3'd0: op121 <= rdc57;
        3'd1: op121 <= rdc58;
        3'd2: op121 <= rdc60;
        3'd3: op121 <= rdc121;
        3'd4: op121 <= rdc122;
        3'd5: op121 <= rdc124;
        default: op121 <= rdc57;
    endcase
    logic [63:0] op122;
    always_ff @(posedge clk) case (rc122)
        4'd0: op122 <= rdc29;
        4'd1: op122 <= rdc45;
        4'd2: op122 <= rdc53;
        4'd3: op122 <= rdc57;
        4'd4: op122 <= rdc58;
        4'd5: op122 <= rdc61;
        4'd6: op122 <= rdc93;
        4'd7: op122 <= rdc109;
        4'd8: op122 <= rdc117;
        4'd9: op122 <= rdc121;
        4'd10: op122 <= rdc122;
        4'd11: op122 <= rdc125;
        default: op122 <= rdc29;
    endcase
    logic [63:0] op123;
    always_ff @(posedge clk) case (rc123)
        2'd0: op123 <= rdc59;
        2'd1: op123 <= rdc61;
        2'd2: op123 <= rdc123;
        2'd3: op123 <= rdc125;
        default: op123 <= rdc59;
    endcase
    logic [63:0] op124;
    always_ff @(posedge clk) case (rc124)
        4'd0: op124 <= rdc30;
        4'd1: op124 <= rdc46;
        4'd2: op124 <= rdc54;
        4'd3: op124 <= rdc58;
        4'd4: op124 <= rdc60;
        4'd5: op124 <= rdc62;
        4'd6: op124 <= rdc94;
        4'd7: op124 <= rdc110;
        4'd8: op124 <= rdc118;
        4'd9: op124 <= rdc122;
        4'd10: op124 <= rdc124;
        4'd11: op124 <= rdc126;
        default: op124 <= rdc30;
    endcase
    logic [63:0] op125;
    always_ff @(posedge clk) case (rc125)
        2'd0: op125 <= rdc61;
        2'd1: op125 <= rdc62;
        2'd2: op125 <= rdc125;
        2'd3: op125 <= rdc126;
        default: op125 <= rdc61;
    endcase
    logic [63:0] op126;
    always_ff @(posedge clk) case (rc126)
        4'd0: op126 <= rdc31;
        4'd1: op126 <= rdc47;
        4'd2: op126 <= rdc55;
        4'd3: op126 <= rdc59;
        4'd4: op126 <= rdc61;
        4'd5: op126 <= rdc62;
        4'd6: op126 <= rdc63;
        4'd7: op126 <= rdc95;
        4'd8: op126 <= rdc111;
        4'd9: op126 <= rdc119;
        4'd10: op126 <= rdc123;
        4'd11: op126 <= rdc125;
        4'd12: op126 <= rdc126;
        4'd13: op126 <= rdc127;
        default: op126 <= rdc31;
    endcase
    logic [63:0] op127;
    always_ff @(posedge clk) case (rc127)
        1'd0: op127 <= rdc63;
        1'd1: op127 <= rdc127;
        default: op127 <= rdc63;
    endcase
    // ---- twiddle tables (two per butterfly: stages > b, and the stage constants of stages <= b),
    // addresses = twiddleIndex (+ the inverse half); the choice registered with the data
    (* max_fanout = 16 *) logic [9:0] ta, ta0; (* max_fanout = 16 *) logic [2:0] tca;
    always_ff @(posedge clk) ta <= tidx_of(s, DIR_r ? ~tau : tau);
    always_ff @(posedge clk) ta0 <= tidx_of(s, DIR_r ? 9'(-tau) : tau);
    always_ff @(posedge clk) tca <= 3'(s);
    logic tsel [3]; always_ff @(posedge clk) begin tsel[0] <= s > 4'd6; for (int i = 1; i <= 2; i++) tsel[i] <= tsel[i-1]; end
    logic tsel_r; assign tsel_r = tsel[2];
    // ---- table write ports from the record stream (IterativeNTT.rnsRecord order)
    logic [10:0] lw_rest; assign lw_rest = 11'(lk >> 2);
    function automatic logic [9:0] lwa_t_of(input logic [3:0] s_, input logic [10:0] r_);
        case (s_)
            4'd7: lwa_t_of = 10'd0 + 10'(r_ & 11'h1);
            4'd8: lwa_t_of = 10'd2 + 10'(r_ & 11'h3);
            4'd9: lwa_t_of = 10'd6 + 10'(r_ & 11'h7);
            4'd10: lwa_t_of = 10'd14 + 10'(r_ & 11'hf);
            4'd11: lwa_t_of = 10'd30 + 10'(r_ & 11'h1f);
            4'd12: lwa_t_of = 10'd62 + 10'(r_ & 11'h3f);
            4'd13: lwa_t_of = 10'd126 + 10'(r_ & 11'h7f);
            4'd14: lwa_t_of = 10'd254 + 10'(r_ & 11'hff);
            4'd15: lwa_t_of = 10'd510 + 10'(r_ & 11'h1ff);
            default: lwa_t_of = '0;
        endcase
    endfunction
    function automatic logic [2:0] lwa_c_of(input logic [3:0] s_, input logic [10:0] r_);
        lwa_c_of = 3'(s_);
    endfunction
    (* max_fanout = 16 *) logic [9:0] lw_wa_t; (* max_fanout = 16 *) logic [2:0] lw_wa_c;
    logic lw_go, lw_t; assign lw_go = tacc && (lst == L_DATA); assign lw_t = ls > 4'd6;
    always_ff @(posedge clk) begin lw_wa_t <= {lwa_t_of(ls, lw_rest)}; lw_wa_c <= {lwa_c_of(ls, lw_rest)}; end
    logic lw_wet0, lw_wec0; logic [63:0] lw_wd0;
    always_ff @(posedge clk) begin lw_wet0 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec0 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd0 <= tw_data[63:0]; end
    logic lw_wet1, lw_wec1; logic [63:0] lw_wd1;
    always_ff @(posedge clk) begin lw_wet1 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec1 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd1 <= tw_data[127:64]; end
    logic lw_wet2, lw_wec2; logic [63:0] lw_wd2;
    always_ff @(posedge clk) begin lw_wet2 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec2 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd2 <= tw_data[191:128]; end
    logic lw_wet3, lw_wec3; logic [63:0] lw_wd3;
    always_ff @(posedge clk) begin lw_wet3 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec3 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd3 <= tw_data[255:192]; end
    logic lw_wet4, lw_wec4; logic [63:0] lw_wd4;
    always_ff @(posedge clk) begin lw_wet4 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec4 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd4 <= tw_data[319:256]; end
    logic lw_wet5, lw_wec5; logic [63:0] lw_wd5;
    always_ff @(posedge clk) begin lw_wet5 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec5 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd5 <= tw_data[383:320]; end
    logic lw_wet6, lw_wec6; logic [63:0] lw_wd6;
    always_ff @(posedge clk) begin lw_wet6 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec6 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd6 <= tw_data[447:384]; end
    logic lw_wet7, lw_wec7; logic [63:0] lw_wd7;
    always_ff @(posedge clk) begin lw_wet7 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec7 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd7 <= tw_data[511:448]; end
    logic lw_wet8, lw_wec8; logic [63:0] lw_wd8;
    always_ff @(posedge clk) begin lw_wet8 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec8 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd8 <= tw_data[575:512]; end
    logic lw_wet9, lw_wec9; logic [63:0] lw_wd9;
    always_ff @(posedge clk) begin lw_wet9 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec9 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd9 <= tw_data[639:576]; end
    logic lw_wet10, lw_wec10; logic [63:0] lw_wd10;
    always_ff @(posedge clk) begin lw_wet10 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec10 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd10 <= tw_data[703:640]; end
    logic lw_wet11, lw_wec11; logic [63:0] lw_wd11;
    always_ff @(posedge clk) begin lw_wet11 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec11 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd11 <= tw_data[767:704]; end
    logic lw_wet12, lw_wec12; logic [63:0] lw_wd12;
    always_ff @(posedge clk) begin lw_wet12 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec12 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd12 <= tw_data[831:768]; end
    logic lw_wet13, lw_wec13; logic [63:0] lw_wd13;
    always_ff @(posedge clk) begin lw_wet13 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec13 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd13 <= tw_data[895:832]; end
    logic lw_wet14, lw_wec14; logic [63:0] lw_wd14;
    always_ff @(posedge clk) begin lw_wet14 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec14 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd14 <= tw_data[959:896]; end
    logic lw_wet15, lw_wec15; logic [63:0] lw_wd15;
    always_ff @(posedge clk) begin lw_wet15 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd0); lw_wec15 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd0); lw_wd15 <= tw_data[1023:960]; end
    logic lw_wet16, lw_wec16; logic [63:0] lw_wd16;
    always_ff @(posedge clk) begin lw_wet16 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec16 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd16 <= tw_data[63:0]; end
    logic lw_wet17, lw_wec17; logic [63:0] lw_wd17;
    always_ff @(posedge clk) begin lw_wet17 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec17 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd17 <= tw_data[127:64]; end
    logic lw_wet18, lw_wec18; logic [63:0] lw_wd18;
    always_ff @(posedge clk) begin lw_wet18 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec18 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd18 <= tw_data[191:128]; end
    logic lw_wet19, lw_wec19; logic [63:0] lw_wd19;
    always_ff @(posedge clk) begin lw_wet19 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec19 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd19 <= tw_data[255:192]; end
    logic lw_wet20, lw_wec20; logic [63:0] lw_wd20;
    always_ff @(posedge clk) begin lw_wet20 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec20 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd20 <= tw_data[319:256]; end
    logic lw_wet21, lw_wec21; logic [63:0] lw_wd21;
    always_ff @(posedge clk) begin lw_wet21 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec21 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd21 <= tw_data[383:320]; end
    logic lw_wet22, lw_wec22; logic [63:0] lw_wd22;
    always_ff @(posedge clk) begin lw_wet22 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec22 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd22 <= tw_data[447:384]; end
    logic lw_wet23, lw_wec23; logic [63:0] lw_wd23;
    always_ff @(posedge clk) begin lw_wet23 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec23 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd23 <= tw_data[511:448]; end
    logic lw_wet24, lw_wec24; logic [63:0] lw_wd24;
    always_ff @(posedge clk) begin lw_wet24 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec24 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd24 <= tw_data[575:512]; end
    logic lw_wet25, lw_wec25; logic [63:0] lw_wd25;
    always_ff @(posedge clk) begin lw_wet25 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec25 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd25 <= tw_data[639:576]; end
    logic lw_wet26, lw_wec26; logic [63:0] lw_wd26;
    always_ff @(posedge clk) begin lw_wet26 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec26 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd26 <= tw_data[703:640]; end
    logic lw_wet27, lw_wec27; logic [63:0] lw_wd27;
    always_ff @(posedge clk) begin lw_wet27 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec27 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd27 <= tw_data[767:704]; end
    logic lw_wet28, lw_wec28; logic [63:0] lw_wd28;
    always_ff @(posedge clk) begin lw_wet28 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec28 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd28 <= tw_data[831:768]; end
    logic lw_wet29, lw_wec29; logic [63:0] lw_wd29;
    always_ff @(posedge clk) begin lw_wet29 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec29 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd29 <= tw_data[895:832]; end
    logic lw_wet30, lw_wec30; logic [63:0] lw_wd30;
    always_ff @(posedge clk) begin lw_wet30 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec30 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd30 <= tw_data[959:896]; end
    logic lw_wet31, lw_wec31; logic [63:0] lw_wd31;
    always_ff @(posedge clk) begin lw_wet31 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd1); lw_wec31 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd1); lw_wd31 <= tw_data[1023:960]; end
    logic lw_wet32, lw_wec32; logic [63:0] lw_wd32;
    always_ff @(posedge clk) begin lw_wet32 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec32 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd32 <= tw_data[63:0]; end
    logic lw_wet33, lw_wec33; logic [63:0] lw_wd33;
    always_ff @(posedge clk) begin lw_wet33 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec33 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd33 <= tw_data[127:64]; end
    logic lw_wet34, lw_wec34; logic [63:0] lw_wd34;
    always_ff @(posedge clk) begin lw_wet34 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec34 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd34 <= tw_data[191:128]; end
    logic lw_wet35, lw_wec35; logic [63:0] lw_wd35;
    always_ff @(posedge clk) begin lw_wet35 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec35 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd35 <= tw_data[255:192]; end
    logic lw_wet36, lw_wec36; logic [63:0] lw_wd36;
    always_ff @(posedge clk) begin lw_wet36 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec36 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd36 <= tw_data[319:256]; end
    logic lw_wet37, lw_wec37; logic [63:0] lw_wd37;
    always_ff @(posedge clk) begin lw_wet37 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec37 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd37 <= tw_data[383:320]; end
    logic lw_wet38, lw_wec38; logic [63:0] lw_wd38;
    always_ff @(posedge clk) begin lw_wet38 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec38 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd38 <= tw_data[447:384]; end
    logic lw_wet39, lw_wec39; logic [63:0] lw_wd39;
    always_ff @(posedge clk) begin lw_wet39 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec39 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd39 <= tw_data[511:448]; end
    logic lw_wet40, lw_wec40; logic [63:0] lw_wd40;
    always_ff @(posedge clk) begin lw_wet40 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec40 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd40 <= tw_data[575:512]; end
    logic lw_wet41, lw_wec41; logic [63:0] lw_wd41;
    always_ff @(posedge clk) begin lw_wet41 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec41 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd41 <= tw_data[639:576]; end
    logic lw_wet42, lw_wec42; logic [63:0] lw_wd42;
    always_ff @(posedge clk) begin lw_wet42 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec42 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd42 <= tw_data[703:640]; end
    logic lw_wet43, lw_wec43; logic [63:0] lw_wd43;
    always_ff @(posedge clk) begin lw_wet43 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec43 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd43 <= tw_data[767:704]; end
    logic lw_wet44, lw_wec44; logic [63:0] lw_wd44;
    always_ff @(posedge clk) begin lw_wet44 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec44 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd44 <= tw_data[831:768]; end
    logic lw_wet45, lw_wec45; logic [63:0] lw_wd45;
    always_ff @(posedge clk) begin lw_wet45 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec45 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd45 <= tw_data[895:832]; end
    logic lw_wet46, lw_wec46; logic [63:0] lw_wd46;
    always_ff @(posedge clk) begin lw_wet46 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec46 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd46 <= tw_data[959:896]; end
    logic lw_wet47, lw_wec47; logic [63:0] lw_wd47;
    always_ff @(posedge clk) begin lw_wet47 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd2); lw_wec47 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd2); lw_wd47 <= tw_data[1023:960]; end
    logic lw_wet48, lw_wec48; logic [63:0] lw_wd48;
    always_ff @(posedge clk) begin lw_wet48 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec48 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd48 <= tw_data[63:0]; end
    logic lw_wet49, lw_wec49; logic [63:0] lw_wd49;
    always_ff @(posedge clk) begin lw_wet49 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec49 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd49 <= tw_data[127:64]; end
    logic lw_wet50, lw_wec50; logic [63:0] lw_wd50;
    always_ff @(posedge clk) begin lw_wet50 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec50 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd50 <= tw_data[191:128]; end
    logic lw_wet51, lw_wec51; logic [63:0] lw_wd51;
    always_ff @(posedge clk) begin lw_wet51 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec51 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd51 <= tw_data[255:192]; end
    logic lw_wet52, lw_wec52; logic [63:0] lw_wd52;
    always_ff @(posedge clk) begin lw_wet52 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec52 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd52 <= tw_data[319:256]; end
    logic lw_wet53, lw_wec53; logic [63:0] lw_wd53;
    always_ff @(posedge clk) begin lw_wet53 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec53 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd53 <= tw_data[383:320]; end
    logic lw_wet54, lw_wec54; logic [63:0] lw_wd54;
    always_ff @(posedge clk) begin lw_wet54 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec54 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd54 <= tw_data[447:384]; end
    logic lw_wet55, lw_wec55; logic [63:0] lw_wd55;
    always_ff @(posedge clk) begin lw_wet55 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec55 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd55 <= tw_data[511:448]; end
    logic lw_wet56, lw_wec56; logic [63:0] lw_wd56;
    always_ff @(posedge clk) begin lw_wet56 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec56 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd56 <= tw_data[575:512]; end
    logic lw_wet57, lw_wec57; logic [63:0] lw_wd57;
    always_ff @(posedge clk) begin lw_wet57 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec57 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd57 <= tw_data[639:576]; end
    logic lw_wet58, lw_wec58; logic [63:0] lw_wd58;
    always_ff @(posedge clk) begin lw_wet58 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec58 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd58 <= tw_data[703:640]; end
    logic lw_wet59, lw_wec59; logic [63:0] lw_wd59;
    always_ff @(posedge clk) begin lw_wet59 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec59 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd59 <= tw_data[767:704]; end
    logic lw_wet60, lw_wec60; logic [63:0] lw_wd60;
    always_ff @(posedge clk) begin lw_wet60 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec60 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd60 <= tw_data[831:768]; end
    logic lw_wet61, lw_wec61; logic [63:0] lw_wd61;
    always_ff @(posedge clk) begin lw_wet61 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec61 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd61 <= tw_data[895:832]; end
    logic lw_wet62, lw_wec62; logic [63:0] lw_wd62;
    always_ff @(posedge clk) begin lw_wet62 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec62 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd62 <= tw_data[959:896]; end
    logic lw_wet63, lw_wec63; logic [63:0] lw_wd63;
    always_ff @(posedge clk) begin lw_wet63 <= !rst && lw_go && lw_t && (lk[1:0] == 2'd3); lw_wec63 <= !rst && lw_go && !lw_t && (lk[1:0] == 2'd3); lw_wd63 <= tw_data[1023:960]; end
    logic [63:0] twr0, tcr0, twr0_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw0 (.clk(clk), .addr(ta0), .we(lw_wet0), .wa(lw_wa_t), .wd(lw_wd0), .q0(twr0));
    Ie_n65536_q64b_B64_rns_twr1 u_tc0 (.clk(clk), .addr(tca), .we(lw_wec0), .wa(lw_wa_c), .wd(lw_wd0), .q0(tcr0));
    logic [63:0] twr1, tcr1, twr1_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw1 (.clk(clk), .addr(ta), .we(lw_wet1), .wa(lw_wa_t), .wd(lw_wd1), .q0(twr1));
    Ie_n65536_q64b_B64_rns_twr1 u_tc1 (.clk(clk), .addr(tca), .we(lw_wec1), .wa(lw_wa_c), .wd(lw_wd1), .q0(tcr1));
    logic [63:0] twr2, tcr2, twr2_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw2 (.clk(clk), .addr(ta), .we(lw_wet2), .wa(lw_wa_t), .wd(lw_wd2), .q0(twr2));
    Ie_n65536_q64b_B64_rns_twr1 u_tc2 (.clk(clk), .addr(tca), .we(lw_wec2), .wa(lw_wa_c), .wd(lw_wd2), .q0(tcr2));
    logic [63:0] twr3, tcr3, twr3_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw3 (.clk(clk), .addr(ta), .we(lw_wet3), .wa(lw_wa_t), .wd(lw_wd3), .q0(twr3));
    Ie_n65536_q64b_B64_rns_twr1 u_tc3 (.clk(clk), .addr(tca), .we(lw_wec3), .wa(lw_wa_c), .wd(lw_wd3), .q0(tcr3));
    logic [63:0] twr4, tcr4, twr4_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw4 (.clk(clk), .addr(ta), .we(lw_wet4), .wa(lw_wa_t), .wd(lw_wd4), .q0(twr4));
    Ie_n65536_q64b_B64_rns_twr1 u_tc4 (.clk(clk), .addr(tca), .we(lw_wec4), .wa(lw_wa_c), .wd(lw_wd4), .q0(tcr4));
    logic [63:0] twr5, tcr5, twr5_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw5 (.clk(clk), .addr(ta), .we(lw_wet5), .wa(lw_wa_t), .wd(lw_wd5), .q0(twr5));
    Ie_n65536_q64b_B64_rns_twr1 u_tc5 (.clk(clk), .addr(tca), .we(lw_wec5), .wa(lw_wa_c), .wd(lw_wd5), .q0(tcr5));
    logic [63:0] twr6, tcr6, twr6_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw6 (.clk(clk), .addr(ta), .we(lw_wet6), .wa(lw_wa_t), .wd(lw_wd6), .q0(twr6));
    Ie_n65536_q64b_B64_rns_twr1 u_tc6 (.clk(clk), .addr(tca), .we(lw_wec6), .wa(lw_wa_c), .wd(lw_wd6), .q0(tcr6));
    logic [63:0] twr7, tcr7, twr7_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw7 (.clk(clk), .addr(ta), .we(lw_wet7), .wa(lw_wa_t), .wd(lw_wd7), .q0(twr7));
    Ie_n65536_q64b_B64_rns_twr1 u_tc7 (.clk(clk), .addr(tca), .we(lw_wec7), .wa(lw_wa_c), .wd(lw_wd7), .q0(tcr7));
    logic [63:0] twr8, tcr8, twr8_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw8 (.clk(clk), .addr(ta), .we(lw_wet8), .wa(lw_wa_t), .wd(lw_wd8), .q0(twr8));
    Ie_n65536_q64b_B64_rns_twr1 u_tc8 (.clk(clk), .addr(tca), .we(lw_wec8), .wa(lw_wa_c), .wd(lw_wd8), .q0(tcr8));
    logic [63:0] twr9, tcr9, twr9_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw9 (.clk(clk), .addr(ta), .we(lw_wet9), .wa(lw_wa_t), .wd(lw_wd9), .q0(twr9));
    Ie_n65536_q64b_B64_rns_twr1 u_tc9 (.clk(clk), .addr(tca), .we(lw_wec9), .wa(lw_wa_c), .wd(lw_wd9), .q0(tcr9));
    logic [63:0] twr10, tcr10, twr10_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw10 (.clk(clk), .addr(ta), .we(lw_wet10), .wa(lw_wa_t), .wd(lw_wd10), .q0(twr10));
    Ie_n65536_q64b_B64_rns_twr1 u_tc10 (.clk(clk), .addr(tca), .we(lw_wec10), .wa(lw_wa_c), .wd(lw_wd10), .q0(tcr10));
    logic [63:0] twr11, tcr11, twr11_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw11 (.clk(clk), .addr(ta), .we(lw_wet11), .wa(lw_wa_t), .wd(lw_wd11), .q0(twr11));
    Ie_n65536_q64b_B64_rns_twr1 u_tc11 (.clk(clk), .addr(tca), .we(lw_wec11), .wa(lw_wa_c), .wd(lw_wd11), .q0(tcr11));
    logic [63:0] twr12, tcr12, twr12_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw12 (.clk(clk), .addr(ta), .we(lw_wet12), .wa(lw_wa_t), .wd(lw_wd12), .q0(twr12));
    Ie_n65536_q64b_B64_rns_twr1 u_tc12 (.clk(clk), .addr(tca), .we(lw_wec12), .wa(lw_wa_c), .wd(lw_wd12), .q0(tcr12));
    logic [63:0] twr13, tcr13, twr13_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw13 (.clk(clk), .addr(ta), .we(lw_wet13), .wa(lw_wa_t), .wd(lw_wd13), .q0(twr13));
    Ie_n65536_q64b_B64_rns_twr1 u_tc13 (.clk(clk), .addr(tca), .we(lw_wec13), .wa(lw_wa_c), .wd(lw_wd13), .q0(tcr13));
    logic [63:0] twr14, tcr14, twr14_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw14 (.clk(clk), .addr(ta), .we(lw_wet14), .wa(lw_wa_t), .wd(lw_wd14), .q0(twr14));
    Ie_n65536_q64b_B64_rns_twr1 u_tc14 (.clk(clk), .addr(tca), .we(lw_wec14), .wa(lw_wa_c), .wd(lw_wd14), .q0(tcr14));
    logic [63:0] twr15, tcr15, twr15_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw15 (.clk(clk), .addr(ta), .we(lw_wet15), .wa(lw_wa_t), .wd(lw_wd15), .q0(twr15));
    Ie_n65536_q64b_B64_rns_twr1 u_tc15 (.clk(clk), .addr(tca), .we(lw_wec15), .wa(lw_wa_c), .wd(lw_wd15), .q0(tcr15));
    logic [63:0] twr16, tcr16, twr16_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw16 (.clk(clk), .addr(ta), .we(lw_wet16), .wa(lw_wa_t), .wd(lw_wd16), .q0(twr16));
    Ie_n65536_q64b_B64_rns_twr1 u_tc16 (.clk(clk), .addr(tca), .we(lw_wec16), .wa(lw_wa_c), .wd(lw_wd16), .q0(tcr16));
    logic [63:0] twr17, tcr17, twr17_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw17 (.clk(clk), .addr(ta), .we(lw_wet17), .wa(lw_wa_t), .wd(lw_wd17), .q0(twr17));
    Ie_n65536_q64b_B64_rns_twr1 u_tc17 (.clk(clk), .addr(tca), .we(lw_wec17), .wa(lw_wa_c), .wd(lw_wd17), .q0(tcr17));
    logic [63:0] twr18, tcr18, twr18_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw18 (.clk(clk), .addr(ta), .we(lw_wet18), .wa(lw_wa_t), .wd(lw_wd18), .q0(twr18));
    Ie_n65536_q64b_B64_rns_twr1 u_tc18 (.clk(clk), .addr(tca), .we(lw_wec18), .wa(lw_wa_c), .wd(lw_wd18), .q0(tcr18));
    logic [63:0] twr19, tcr19, twr19_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw19 (.clk(clk), .addr(ta), .we(lw_wet19), .wa(lw_wa_t), .wd(lw_wd19), .q0(twr19));
    Ie_n65536_q64b_B64_rns_twr1 u_tc19 (.clk(clk), .addr(tca), .we(lw_wec19), .wa(lw_wa_c), .wd(lw_wd19), .q0(tcr19));
    logic [63:0] twr20, tcr20, twr20_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw20 (.clk(clk), .addr(ta), .we(lw_wet20), .wa(lw_wa_t), .wd(lw_wd20), .q0(twr20));
    Ie_n65536_q64b_B64_rns_twr1 u_tc20 (.clk(clk), .addr(tca), .we(lw_wec20), .wa(lw_wa_c), .wd(lw_wd20), .q0(tcr20));
    logic [63:0] twr21, tcr21, twr21_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw21 (.clk(clk), .addr(ta), .we(lw_wet21), .wa(lw_wa_t), .wd(lw_wd21), .q0(twr21));
    Ie_n65536_q64b_B64_rns_twr1 u_tc21 (.clk(clk), .addr(tca), .we(lw_wec21), .wa(lw_wa_c), .wd(lw_wd21), .q0(tcr21));
    logic [63:0] twr22, tcr22, twr22_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw22 (.clk(clk), .addr(ta), .we(lw_wet22), .wa(lw_wa_t), .wd(lw_wd22), .q0(twr22));
    Ie_n65536_q64b_B64_rns_twr1 u_tc22 (.clk(clk), .addr(tca), .we(lw_wec22), .wa(lw_wa_c), .wd(lw_wd22), .q0(tcr22));
    logic [63:0] twr23, tcr23, twr23_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw23 (.clk(clk), .addr(ta), .we(lw_wet23), .wa(lw_wa_t), .wd(lw_wd23), .q0(twr23));
    Ie_n65536_q64b_B64_rns_twr1 u_tc23 (.clk(clk), .addr(tca), .we(lw_wec23), .wa(lw_wa_c), .wd(lw_wd23), .q0(tcr23));
    logic [63:0] twr24, tcr24, twr24_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw24 (.clk(clk), .addr(ta), .we(lw_wet24), .wa(lw_wa_t), .wd(lw_wd24), .q0(twr24));
    Ie_n65536_q64b_B64_rns_twr1 u_tc24 (.clk(clk), .addr(tca), .we(lw_wec24), .wa(lw_wa_c), .wd(lw_wd24), .q0(tcr24));
    logic [63:0] twr25, tcr25, twr25_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw25 (.clk(clk), .addr(ta), .we(lw_wet25), .wa(lw_wa_t), .wd(lw_wd25), .q0(twr25));
    Ie_n65536_q64b_B64_rns_twr1 u_tc25 (.clk(clk), .addr(tca), .we(lw_wec25), .wa(lw_wa_c), .wd(lw_wd25), .q0(tcr25));
    logic [63:0] twr26, tcr26, twr26_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw26 (.clk(clk), .addr(ta), .we(lw_wet26), .wa(lw_wa_t), .wd(lw_wd26), .q0(twr26));
    Ie_n65536_q64b_B64_rns_twr1 u_tc26 (.clk(clk), .addr(tca), .we(lw_wec26), .wa(lw_wa_c), .wd(lw_wd26), .q0(tcr26));
    logic [63:0] twr27, tcr27, twr27_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw27 (.clk(clk), .addr(ta), .we(lw_wet27), .wa(lw_wa_t), .wd(lw_wd27), .q0(twr27));
    Ie_n65536_q64b_B64_rns_twr1 u_tc27 (.clk(clk), .addr(tca), .we(lw_wec27), .wa(lw_wa_c), .wd(lw_wd27), .q0(tcr27));
    logic [63:0] twr28, tcr28, twr28_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw28 (.clk(clk), .addr(ta), .we(lw_wet28), .wa(lw_wa_t), .wd(lw_wd28), .q0(twr28));
    Ie_n65536_q64b_B64_rns_twr1 u_tc28 (.clk(clk), .addr(tca), .we(lw_wec28), .wa(lw_wa_c), .wd(lw_wd28), .q0(tcr28));
    logic [63:0] twr29, tcr29, twr29_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw29 (.clk(clk), .addr(ta), .we(lw_wet29), .wa(lw_wa_t), .wd(lw_wd29), .q0(twr29));
    Ie_n65536_q64b_B64_rns_twr1 u_tc29 (.clk(clk), .addr(tca), .we(lw_wec29), .wa(lw_wa_c), .wd(lw_wd29), .q0(tcr29));
    logic [63:0] twr30, tcr30, twr30_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw30 (.clk(clk), .addr(ta), .we(lw_wet30), .wa(lw_wa_t), .wd(lw_wd30), .q0(twr30));
    Ie_n65536_q64b_B64_rns_twr1 u_tc30 (.clk(clk), .addr(tca), .we(lw_wec30), .wa(lw_wa_c), .wd(lw_wd30), .q0(tcr30));
    logic [63:0] twr31, tcr31, twr31_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw31 (.clk(clk), .addr(ta), .we(lw_wet31), .wa(lw_wa_t), .wd(lw_wd31), .q0(twr31));
    Ie_n65536_q64b_B64_rns_twr1 u_tc31 (.clk(clk), .addr(tca), .we(lw_wec31), .wa(lw_wa_c), .wd(lw_wd31), .q0(tcr31));
    logic [63:0] twr32, tcr32, twr32_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw32 (.clk(clk), .addr(ta), .we(lw_wet32), .wa(lw_wa_t), .wd(lw_wd32), .q0(twr32));
    Ie_n65536_q64b_B64_rns_twr1 u_tc32 (.clk(clk), .addr(tca), .we(lw_wec32), .wa(lw_wa_c), .wd(lw_wd32), .q0(tcr32));
    logic [63:0] twr33, tcr33, twr33_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw33 (.clk(clk), .addr(ta), .we(lw_wet33), .wa(lw_wa_t), .wd(lw_wd33), .q0(twr33));
    Ie_n65536_q64b_B64_rns_twr1 u_tc33 (.clk(clk), .addr(tca), .we(lw_wec33), .wa(lw_wa_c), .wd(lw_wd33), .q0(tcr33));
    logic [63:0] twr34, tcr34, twr34_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw34 (.clk(clk), .addr(ta), .we(lw_wet34), .wa(lw_wa_t), .wd(lw_wd34), .q0(twr34));
    Ie_n65536_q64b_B64_rns_twr1 u_tc34 (.clk(clk), .addr(tca), .we(lw_wec34), .wa(lw_wa_c), .wd(lw_wd34), .q0(tcr34));
    logic [63:0] twr35, tcr35, twr35_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw35 (.clk(clk), .addr(ta), .we(lw_wet35), .wa(lw_wa_t), .wd(lw_wd35), .q0(twr35));
    Ie_n65536_q64b_B64_rns_twr1 u_tc35 (.clk(clk), .addr(tca), .we(lw_wec35), .wa(lw_wa_c), .wd(lw_wd35), .q0(tcr35));
    logic [63:0] twr36, tcr36, twr36_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw36 (.clk(clk), .addr(ta), .we(lw_wet36), .wa(lw_wa_t), .wd(lw_wd36), .q0(twr36));
    Ie_n65536_q64b_B64_rns_twr1 u_tc36 (.clk(clk), .addr(tca), .we(lw_wec36), .wa(lw_wa_c), .wd(lw_wd36), .q0(tcr36));
    logic [63:0] twr37, tcr37, twr37_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw37 (.clk(clk), .addr(ta), .we(lw_wet37), .wa(lw_wa_t), .wd(lw_wd37), .q0(twr37));
    Ie_n65536_q64b_B64_rns_twr1 u_tc37 (.clk(clk), .addr(tca), .we(lw_wec37), .wa(lw_wa_c), .wd(lw_wd37), .q0(tcr37));
    logic [63:0] twr38, tcr38, twr38_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw38 (.clk(clk), .addr(ta), .we(lw_wet38), .wa(lw_wa_t), .wd(lw_wd38), .q0(twr38));
    Ie_n65536_q64b_B64_rns_twr1 u_tc38 (.clk(clk), .addr(tca), .we(lw_wec38), .wa(lw_wa_c), .wd(lw_wd38), .q0(tcr38));
    logic [63:0] twr39, tcr39, twr39_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw39 (.clk(clk), .addr(ta), .we(lw_wet39), .wa(lw_wa_t), .wd(lw_wd39), .q0(twr39));
    Ie_n65536_q64b_B64_rns_twr1 u_tc39 (.clk(clk), .addr(tca), .we(lw_wec39), .wa(lw_wa_c), .wd(lw_wd39), .q0(tcr39));
    logic [63:0] twr40, tcr40, twr40_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw40 (.clk(clk), .addr(ta), .we(lw_wet40), .wa(lw_wa_t), .wd(lw_wd40), .q0(twr40));
    Ie_n65536_q64b_B64_rns_twr1 u_tc40 (.clk(clk), .addr(tca), .we(lw_wec40), .wa(lw_wa_c), .wd(lw_wd40), .q0(tcr40));
    logic [63:0] twr41, tcr41, twr41_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw41 (.clk(clk), .addr(ta), .we(lw_wet41), .wa(lw_wa_t), .wd(lw_wd41), .q0(twr41));
    Ie_n65536_q64b_B64_rns_twr1 u_tc41 (.clk(clk), .addr(tca), .we(lw_wec41), .wa(lw_wa_c), .wd(lw_wd41), .q0(tcr41));
    logic [63:0] twr42, tcr42, twr42_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw42 (.clk(clk), .addr(ta), .we(lw_wet42), .wa(lw_wa_t), .wd(lw_wd42), .q0(twr42));
    Ie_n65536_q64b_B64_rns_twr1 u_tc42 (.clk(clk), .addr(tca), .we(lw_wec42), .wa(lw_wa_c), .wd(lw_wd42), .q0(tcr42));
    logic [63:0] twr43, tcr43, twr43_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw43 (.clk(clk), .addr(ta), .we(lw_wet43), .wa(lw_wa_t), .wd(lw_wd43), .q0(twr43));
    Ie_n65536_q64b_B64_rns_twr1 u_tc43 (.clk(clk), .addr(tca), .we(lw_wec43), .wa(lw_wa_c), .wd(lw_wd43), .q0(tcr43));
    logic [63:0] twr44, tcr44, twr44_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw44 (.clk(clk), .addr(ta), .we(lw_wet44), .wa(lw_wa_t), .wd(lw_wd44), .q0(twr44));
    Ie_n65536_q64b_B64_rns_twr1 u_tc44 (.clk(clk), .addr(tca), .we(lw_wec44), .wa(lw_wa_c), .wd(lw_wd44), .q0(tcr44));
    logic [63:0] twr45, tcr45, twr45_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw45 (.clk(clk), .addr(ta), .we(lw_wet45), .wa(lw_wa_t), .wd(lw_wd45), .q0(twr45));
    Ie_n65536_q64b_B64_rns_twr1 u_tc45 (.clk(clk), .addr(tca), .we(lw_wec45), .wa(lw_wa_c), .wd(lw_wd45), .q0(tcr45));
    logic [63:0] twr46, tcr46, twr46_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw46 (.clk(clk), .addr(ta), .we(lw_wet46), .wa(lw_wa_t), .wd(lw_wd46), .q0(twr46));
    Ie_n65536_q64b_B64_rns_twr1 u_tc46 (.clk(clk), .addr(tca), .we(lw_wec46), .wa(lw_wa_c), .wd(lw_wd46), .q0(tcr46));
    logic [63:0] twr47, tcr47, twr47_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw47 (.clk(clk), .addr(ta), .we(lw_wet47), .wa(lw_wa_t), .wd(lw_wd47), .q0(twr47));
    Ie_n65536_q64b_B64_rns_twr1 u_tc47 (.clk(clk), .addr(tca), .we(lw_wec47), .wa(lw_wa_c), .wd(lw_wd47), .q0(tcr47));
    logic [63:0] twr48, tcr48, twr48_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw48 (.clk(clk), .addr(ta), .we(lw_wet48), .wa(lw_wa_t), .wd(lw_wd48), .q0(twr48));
    Ie_n65536_q64b_B64_rns_twr1 u_tc48 (.clk(clk), .addr(tca), .we(lw_wec48), .wa(lw_wa_c), .wd(lw_wd48), .q0(tcr48));
    logic [63:0] twr49, tcr49, twr49_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw49 (.clk(clk), .addr(ta), .we(lw_wet49), .wa(lw_wa_t), .wd(lw_wd49), .q0(twr49));
    Ie_n65536_q64b_B64_rns_twr1 u_tc49 (.clk(clk), .addr(tca), .we(lw_wec49), .wa(lw_wa_c), .wd(lw_wd49), .q0(tcr49));
    logic [63:0] twr50, tcr50, twr50_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw50 (.clk(clk), .addr(ta), .we(lw_wet50), .wa(lw_wa_t), .wd(lw_wd50), .q0(twr50));
    Ie_n65536_q64b_B64_rns_twr1 u_tc50 (.clk(clk), .addr(tca), .we(lw_wec50), .wa(lw_wa_c), .wd(lw_wd50), .q0(tcr50));
    logic [63:0] twr51, tcr51, twr51_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw51 (.clk(clk), .addr(ta), .we(lw_wet51), .wa(lw_wa_t), .wd(lw_wd51), .q0(twr51));
    Ie_n65536_q64b_B64_rns_twr1 u_tc51 (.clk(clk), .addr(tca), .we(lw_wec51), .wa(lw_wa_c), .wd(lw_wd51), .q0(tcr51));
    logic [63:0] twr52, tcr52, twr52_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw52 (.clk(clk), .addr(ta), .we(lw_wet52), .wa(lw_wa_t), .wd(lw_wd52), .q0(twr52));
    Ie_n65536_q64b_B64_rns_twr1 u_tc52 (.clk(clk), .addr(tca), .we(lw_wec52), .wa(lw_wa_c), .wd(lw_wd52), .q0(tcr52));
    logic [63:0] twr53, tcr53, twr53_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw53 (.clk(clk), .addr(ta), .we(lw_wet53), .wa(lw_wa_t), .wd(lw_wd53), .q0(twr53));
    Ie_n65536_q64b_B64_rns_twr1 u_tc53 (.clk(clk), .addr(tca), .we(lw_wec53), .wa(lw_wa_c), .wd(lw_wd53), .q0(tcr53));
    logic [63:0] twr54, tcr54, twr54_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw54 (.clk(clk), .addr(ta), .we(lw_wet54), .wa(lw_wa_t), .wd(lw_wd54), .q0(twr54));
    Ie_n65536_q64b_B64_rns_twr1 u_tc54 (.clk(clk), .addr(tca), .we(lw_wec54), .wa(lw_wa_c), .wd(lw_wd54), .q0(tcr54));
    logic [63:0] twr55, tcr55, twr55_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw55 (.clk(clk), .addr(ta), .we(lw_wet55), .wa(lw_wa_t), .wd(lw_wd55), .q0(twr55));
    Ie_n65536_q64b_B64_rns_twr1 u_tc55 (.clk(clk), .addr(tca), .we(lw_wec55), .wa(lw_wa_c), .wd(lw_wd55), .q0(tcr55));
    logic [63:0] twr56, tcr56, twr56_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw56 (.clk(clk), .addr(ta), .we(lw_wet56), .wa(lw_wa_t), .wd(lw_wd56), .q0(twr56));
    Ie_n65536_q64b_B64_rns_twr1 u_tc56 (.clk(clk), .addr(tca), .we(lw_wec56), .wa(lw_wa_c), .wd(lw_wd56), .q0(tcr56));
    logic [63:0] twr57, tcr57, twr57_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw57 (.clk(clk), .addr(ta), .we(lw_wet57), .wa(lw_wa_t), .wd(lw_wd57), .q0(twr57));
    Ie_n65536_q64b_B64_rns_twr1 u_tc57 (.clk(clk), .addr(tca), .we(lw_wec57), .wa(lw_wa_c), .wd(lw_wd57), .q0(tcr57));
    logic [63:0] twr58, tcr58, twr58_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw58 (.clk(clk), .addr(ta), .we(lw_wet58), .wa(lw_wa_t), .wd(lw_wd58), .q0(twr58));
    Ie_n65536_q64b_B64_rns_twr1 u_tc58 (.clk(clk), .addr(tca), .we(lw_wec58), .wa(lw_wa_c), .wd(lw_wd58), .q0(tcr58));
    logic [63:0] twr59, tcr59, twr59_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw59 (.clk(clk), .addr(ta), .we(lw_wet59), .wa(lw_wa_t), .wd(lw_wd59), .q0(twr59));
    Ie_n65536_q64b_B64_rns_twr1 u_tc59 (.clk(clk), .addr(tca), .we(lw_wec59), .wa(lw_wa_c), .wd(lw_wd59), .q0(tcr59));
    logic [63:0] twr60, tcr60, twr60_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw60 (.clk(clk), .addr(ta), .we(lw_wet60), .wa(lw_wa_t), .wd(lw_wd60), .q0(twr60));
    Ie_n65536_q64b_B64_rns_twr1 u_tc60 (.clk(clk), .addr(tca), .we(lw_wec60), .wa(lw_wa_c), .wd(lw_wd60), .q0(tcr60));
    logic [63:0] twr61, tcr61, twr61_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw61 (.clk(clk), .addr(ta), .we(lw_wet61), .wa(lw_wa_t), .wd(lw_wd61), .q0(twr61));
    Ie_n65536_q64b_B64_rns_twr1 u_tc61 (.clk(clk), .addr(tca), .we(lw_wec61), .wa(lw_wa_c), .wd(lw_wd61), .q0(tcr61));
    logic [63:0] twr62, tcr62, twr62_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw62 (.clk(clk), .addr(ta), .we(lw_wet62), .wa(lw_wa_t), .wd(lw_wd62), .q0(twr62));
    Ie_n65536_q64b_B64_rns_twr1 u_tc62 (.clk(clk), .addr(tca), .we(lw_wec62), .wa(lw_wa_c), .wd(lw_wd62), .q0(tcr62));
    logic [63:0] twr63, tcr63, twr63_q;
    Ie_n65536_q64b_B64_rns_twr0 u_tw63 (.clk(clk), .addr(ta), .we(lw_wet63), .wa(lw_wa_t), .wd(lw_wd63), .q0(twr63));
    Ie_n65536_q64b_B64_rns_twr1 u_tc63 (.clk(clk), .addr(tca), .we(lw_wec63), .wa(lw_wa_c), .wd(lw_wd63), .q0(tcr63));
    always_ff @(posedge clk) twr0_q <= tsel_r ? twr0 : tcr0;
    always_ff @(posedge clk) twr1_q <= tsel_r ? (DIR_r ? twr63 : twr1) : (DIR_r ? tcr63 : tcr1);
    always_ff @(posedge clk) twr2_q <= tsel_r ? (DIR_r ? twr62 : twr2) : (DIR_r ? tcr62 : tcr2);
    always_ff @(posedge clk) twr3_q <= tsel_r ? (DIR_r ? twr61 : twr3) : (DIR_r ? tcr61 : tcr3);
    always_ff @(posedge clk) twr4_q <= tsel_r ? (DIR_r ? twr60 : twr4) : (DIR_r ? tcr60 : tcr4);
    always_ff @(posedge clk) twr5_q <= tsel_r ? (DIR_r ? twr59 : twr5) : (DIR_r ? tcr59 : tcr5);
    always_ff @(posedge clk) twr6_q <= tsel_r ? (DIR_r ? twr58 : twr6) : (DIR_r ? tcr58 : tcr6);
    always_ff @(posedge clk) twr7_q <= tsel_r ? (DIR_r ? twr57 : twr7) : (DIR_r ? tcr57 : tcr7);
    always_ff @(posedge clk) twr8_q <= tsel_r ? (DIR_r ? twr56 : twr8) : (DIR_r ? tcr56 : tcr8);
    always_ff @(posedge clk) twr9_q <= tsel_r ? (DIR_r ? twr55 : twr9) : (DIR_r ? tcr55 : tcr9);
    always_ff @(posedge clk) twr10_q <= tsel_r ? (DIR_r ? twr54 : twr10) : (DIR_r ? tcr54 : tcr10);
    always_ff @(posedge clk) twr11_q <= tsel_r ? (DIR_r ? twr53 : twr11) : (DIR_r ? tcr53 : tcr11);
    always_ff @(posedge clk) twr12_q <= tsel_r ? (DIR_r ? twr52 : twr12) : (DIR_r ? tcr52 : tcr12);
    always_ff @(posedge clk) twr13_q <= tsel_r ? (DIR_r ? twr51 : twr13) : (DIR_r ? tcr51 : tcr13);
    always_ff @(posedge clk) twr14_q <= tsel_r ? (DIR_r ? twr50 : twr14) : (DIR_r ? tcr50 : tcr14);
    always_ff @(posedge clk) twr15_q <= tsel_r ? (DIR_r ? twr49 : twr15) : (DIR_r ? tcr49 : tcr15);
    always_ff @(posedge clk) twr16_q <= tsel_r ? (DIR_r ? twr48 : twr16) : (DIR_r ? tcr48 : tcr16);
    always_ff @(posedge clk) twr17_q <= tsel_r ? (DIR_r ? twr47 : twr17) : (DIR_r ? tcr47 : tcr17);
    always_ff @(posedge clk) twr18_q <= tsel_r ? (DIR_r ? twr46 : twr18) : (DIR_r ? tcr46 : tcr18);
    always_ff @(posedge clk) twr19_q <= tsel_r ? (DIR_r ? twr45 : twr19) : (DIR_r ? tcr45 : tcr19);
    always_ff @(posedge clk) twr20_q <= tsel_r ? (DIR_r ? twr44 : twr20) : (DIR_r ? tcr44 : tcr20);
    always_ff @(posedge clk) twr21_q <= tsel_r ? (DIR_r ? twr43 : twr21) : (DIR_r ? tcr43 : tcr21);
    always_ff @(posedge clk) twr22_q <= tsel_r ? (DIR_r ? twr42 : twr22) : (DIR_r ? tcr42 : tcr22);
    always_ff @(posedge clk) twr23_q <= tsel_r ? (DIR_r ? twr41 : twr23) : (DIR_r ? tcr41 : tcr23);
    always_ff @(posedge clk) twr24_q <= tsel_r ? (DIR_r ? twr40 : twr24) : (DIR_r ? tcr40 : tcr24);
    always_ff @(posedge clk) twr25_q <= tsel_r ? (DIR_r ? twr39 : twr25) : (DIR_r ? tcr39 : tcr25);
    always_ff @(posedge clk) twr26_q <= tsel_r ? (DIR_r ? twr38 : twr26) : (DIR_r ? tcr38 : tcr26);
    always_ff @(posedge clk) twr27_q <= tsel_r ? (DIR_r ? twr37 : twr27) : (DIR_r ? tcr37 : tcr27);
    always_ff @(posedge clk) twr28_q <= tsel_r ? (DIR_r ? twr36 : twr28) : (DIR_r ? tcr36 : tcr28);
    always_ff @(posedge clk) twr29_q <= tsel_r ? (DIR_r ? twr35 : twr29) : (DIR_r ? tcr35 : tcr29);
    always_ff @(posedge clk) twr30_q <= tsel_r ? (DIR_r ? twr34 : twr30) : (DIR_r ? tcr34 : tcr30);
    always_ff @(posedge clk) twr31_q <= tsel_r ? (DIR_r ? twr33 : twr31) : (DIR_r ? tcr33 : tcr31);
    always_ff @(posedge clk) twr32_q <= tsel_r ? twr32 : tcr32;
    always_ff @(posedge clk) twr33_q <= tsel_r ? (DIR_r ? twr31 : twr33) : (DIR_r ? tcr31 : tcr33);
    always_ff @(posedge clk) twr34_q <= tsel_r ? (DIR_r ? twr30 : twr34) : (DIR_r ? tcr30 : tcr34);
    always_ff @(posedge clk) twr35_q <= tsel_r ? (DIR_r ? twr29 : twr35) : (DIR_r ? tcr29 : tcr35);
    always_ff @(posedge clk) twr36_q <= tsel_r ? (DIR_r ? twr28 : twr36) : (DIR_r ? tcr28 : tcr36);
    always_ff @(posedge clk) twr37_q <= tsel_r ? (DIR_r ? twr27 : twr37) : (DIR_r ? tcr27 : tcr37);
    always_ff @(posedge clk) twr38_q <= tsel_r ? (DIR_r ? twr26 : twr38) : (DIR_r ? tcr26 : tcr38);
    always_ff @(posedge clk) twr39_q <= tsel_r ? (DIR_r ? twr25 : twr39) : (DIR_r ? tcr25 : tcr39);
    always_ff @(posedge clk) twr40_q <= tsel_r ? (DIR_r ? twr24 : twr40) : (DIR_r ? tcr24 : tcr40);
    always_ff @(posedge clk) twr41_q <= tsel_r ? (DIR_r ? twr23 : twr41) : (DIR_r ? tcr23 : tcr41);
    always_ff @(posedge clk) twr42_q <= tsel_r ? (DIR_r ? twr22 : twr42) : (DIR_r ? tcr22 : tcr42);
    always_ff @(posedge clk) twr43_q <= tsel_r ? (DIR_r ? twr21 : twr43) : (DIR_r ? tcr21 : tcr43);
    always_ff @(posedge clk) twr44_q <= tsel_r ? (DIR_r ? twr20 : twr44) : (DIR_r ? tcr20 : tcr44);
    always_ff @(posedge clk) twr45_q <= tsel_r ? (DIR_r ? twr19 : twr45) : (DIR_r ? tcr19 : tcr45);
    always_ff @(posedge clk) twr46_q <= tsel_r ? (DIR_r ? twr18 : twr46) : (DIR_r ? tcr18 : tcr46);
    always_ff @(posedge clk) twr47_q <= tsel_r ? (DIR_r ? twr17 : twr47) : (DIR_r ? tcr17 : tcr47);
    always_ff @(posedge clk) twr48_q <= tsel_r ? (DIR_r ? twr16 : twr48) : (DIR_r ? tcr16 : tcr48);
    always_ff @(posedge clk) twr49_q <= tsel_r ? (DIR_r ? twr15 : twr49) : (DIR_r ? tcr15 : tcr49);
    always_ff @(posedge clk) twr50_q <= tsel_r ? (DIR_r ? twr14 : twr50) : (DIR_r ? tcr14 : tcr50);
    always_ff @(posedge clk) twr51_q <= tsel_r ? (DIR_r ? twr13 : twr51) : (DIR_r ? tcr13 : tcr51);
    always_ff @(posedge clk) twr52_q <= tsel_r ? (DIR_r ? twr12 : twr52) : (DIR_r ? tcr12 : tcr52);
    always_ff @(posedge clk) twr53_q <= tsel_r ? (DIR_r ? twr11 : twr53) : (DIR_r ? tcr11 : tcr53);
    always_ff @(posedge clk) twr54_q <= tsel_r ? (DIR_r ? twr10 : twr54) : (DIR_r ? tcr10 : tcr54);
    always_ff @(posedge clk) twr55_q <= tsel_r ? (DIR_r ? twr9 : twr55) : (DIR_r ? tcr9 : tcr55);
    always_ff @(posedge clk) twr56_q <= tsel_r ? (DIR_r ? twr8 : twr56) : (DIR_r ? tcr8 : tcr56);
    always_ff @(posedge clk) twr57_q <= tsel_r ? (DIR_r ? twr7 : twr57) : (DIR_r ? tcr7 : tcr57);
    always_ff @(posedge clk) twr58_q <= tsel_r ? (DIR_r ? twr6 : twr58) : (DIR_r ? tcr6 : tcr58);
    always_ff @(posedge clk) twr59_q <= tsel_r ? (DIR_r ? twr5 : twr59) : (DIR_r ? tcr5 : tcr59);
    always_ff @(posedge clk) twr60_q <= tsel_r ? (DIR_r ? twr4 : twr60) : (DIR_r ? tcr4 : tcr60);
    always_ff @(posedge clk) twr61_q <= tsel_r ? (DIR_r ? twr3 : twr61) : (DIR_r ? tcr3 : tcr61);
    always_ff @(posedge clk) twr62_q <= tsel_r ? (DIR_r ? twr2 : twr62) : (DIR_r ? tcr2 : tcr62);
    always_ff @(posedge clk) twr63_q <= tsel_r ? (DIR_r ? twr1 : twr63) : (DIR_r ? tcr1 : tcr63);
    // ---- 64 butterflies (Ie_n65536_q64b_B64_rns_bu, latency 16), output register / x2^-1 halver
    (* max_fanout = 16 *) logic [63:0] b0q_Q;
    always_ff @(posedge clk) b0q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b0q_MU;
    always_ff @(posedge clk) b0q_MU <= MU_r;
    logic [63:0] xr0; logic [63:0] yr0;
    Ie_n65536_q64b_B64_rns_bu u_bu0 (.clk(clk), .aIn(op0), .bIn(op1), .W(twr0_q), .Q(b0q_Q), .MU(b0q_MU), .aOut(xr0), .bOut(yr0));
    logic [63:0] xo0, xo0_x; assign xo0_x = (cb_sw[19][0] ? yr0 : xr0);
    (* max_fanout = 16 *) logic [63:0] b0q_QHALF;
    always_ff @(posedge clk) b0q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo0 <= DIR_r ? (64'(xo0_x >> 1) + (xo0_x[0] ? 64'(b0q_QHALF) : 64'd0)) : xo0_x;
    logic [63:0] yo0, yo0_x; assign yo0_x = (cb_sw[19][0] ? xr0 : yr0);
    always_ff @(posedge clk) yo0 <= DIR_r ? (64'(yo0_x >> 1) + (yo0_x[0] ? 64'(b0q_QHALF) : 64'd0)) : yo0_x;
    (* max_fanout = 16 *) logic [63:0] b1q_Q;
    always_ff @(posedge clk) b1q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b1q_MU;
    always_ff @(posedge clk) b1q_MU <= MU_r;
    logic [63:0] xr1; logic [63:0] yr1;
    Ie_n65536_q64b_B64_rns_bu u_bu1 (.clk(clk), .aIn(op2), .bIn(op3), .W(twr1_q), .Q(b1q_Q), .MU(b1q_MU), .aOut(xr1), .bOut(yr1));
    logic [63:0] xo1, xo1_x; assign xo1_x = (cb_sw[19][1] ? yr1 : xr1);
    (* max_fanout = 16 *) logic [63:0] b1q_QHALF;
    always_ff @(posedge clk) b1q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo1 <= DIR_r ? (64'(xo1_x >> 1) + (xo1_x[0] ? 64'(b1q_QHALF) : 64'd0)) : xo1_x;
    logic [63:0] yo1, yo1_x; assign yo1_x = (cb_sw[19][1] ? xr1 : yr1);
    always_ff @(posedge clk) yo1 <= DIR_r ? (64'(yo1_x >> 1) + (yo1_x[0] ? 64'(b1q_QHALF) : 64'd0)) : yo1_x;
    (* max_fanout = 16 *) logic [63:0] b2q_Q;
    always_ff @(posedge clk) b2q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b2q_MU;
    always_ff @(posedge clk) b2q_MU <= MU_r;
    logic [63:0] xr2; logic [63:0] yr2;
    Ie_n65536_q64b_B64_rns_bu u_bu2 (.clk(clk), .aIn(op4), .bIn(op5), .W(twr2_q), .Q(b2q_Q), .MU(b2q_MU), .aOut(xr2), .bOut(yr2));
    logic [63:0] xo2, xo2_x; assign xo2_x = (cb_sw[19][2] ? yr2 : xr2);
    (* max_fanout = 16 *) logic [63:0] b2q_QHALF;
    always_ff @(posedge clk) b2q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo2 <= DIR_r ? (64'(xo2_x >> 1) + (xo2_x[0] ? 64'(b2q_QHALF) : 64'd0)) : xo2_x;
    logic [63:0] yo2, yo2_x; assign yo2_x = (cb_sw[19][2] ? xr2 : yr2);
    always_ff @(posedge clk) yo2 <= DIR_r ? (64'(yo2_x >> 1) + (yo2_x[0] ? 64'(b2q_QHALF) : 64'd0)) : yo2_x;
    (* max_fanout = 16 *) logic [63:0] b3q_Q;
    always_ff @(posedge clk) b3q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b3q_MU;
    always_ff @(posedge clk) b3q_MU <= MU_r;
    logic [63:0] xr3; logic [63:0] yr3;
    Ie_n65536_q64b_B64_rns_bu u_bu3 (.clk(clk), .aIn(op6), .bIn(op7), .W(twr3_q), .Q(b3q_Q), .MU(b3q_MU), .aOut(xr3), .bOut(yr3));
    logic [63:0] xo3, xo3_x; assign xo3_x = (cb_sw[19][3] ? yr3 : xr3);
    (* max_fanout = 16 *) logic [63:0] b3q_QHALF;
    always_ff @(posedge clk) b3q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo3 <= DIR_r ? (64'(xo3_x >> 1) + (xo3_x[0] ? 64'(b3q_QHALF) : 64'd0)) : xo3_x;
    logic [63:0] yo3, yo3_x; assign yo3_x = (cb_sw[19][3] ? xr3 : yr3);
    always_ff @(posedge clk) yo3 <= DIR_r ? (64'(yo3_x >> 1) + (yo3_x[0] ? 64'(b3q_QHALF) : 64'd0)) : yo3_x;
    (* max_fanout = 16 *) logic [63:0] b4q_Q;
    always_ff @(posedge clk) b4q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b4q_MU;
    always_ff @(posedge clk) b4q_MU <= MU_r;
    logic [63:0] xr4; logic [63:0] yr4;
    Ie_n65536_q64b_B64_rns_bu u_bu4 (.clk(clk), .aIn(op8), .bIn(op9), .W(twr4_q), .Q(b4q_Q), .MU(b4q_MU), .aOut(xr4), .bOut(yr4));
    logic [63:0] xo4, xo4_x; assign xo4_x = (cb_sw[19][4] ? yr4 : xr4);
    (* max_fanout = 16 *) logic [63:0] b4q_QHALF;
    always_ff @(posedge clk) b4q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo4 <= DIR_r ? (64'(xo4_x >> 1) + (xo4_x[0] ? 64'(b4q_QHALF) : 64'd0)) : xo4_x;
    logic [63:0] yo4, yo4_x; assign yo4_x = (cb_sw[19][4] ? xr4 : yr4);
    always_ff @(posedge clk) yo4 <= DIR_r ? (64'(yo4_x >> 1) + (yo4_x[0] ? 64'(b4q_QHALF) : 64'd0)) : yo4_x;
    (* max_fanout = 16 *) logic [63:0] b5q_Q;
    always_ff @(posedge clk) b5q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b5q_MU;
    always_ff @(posedge clk) b5q_MU <= MU_r;
    logic [63:0] xr5; logic [63:0] yr5;
    Ie_n65536_q64b_B64_rns_bu u_bu5 (.clk(clk), .aIn(op10), .bIn(op11), .W(twr5_q), .Q(b5q_Q), .MU(b5q_MU), .aOut(xr5), .bOut(yr5));
    logic [63:0] xo5, xo5_x; assign xo5_x = (cb_sw[19][5] ? yr5 : xr5);
    (* max_fanout = 16 *) logic [63:0] b5q_QHALF;
    always_ff @(posedge clk) b5q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo5 <= DIR_r ? (64'(xo5_x >> 1) + (xo5_x[0] ? 64'(b5q_QHALF) : 64'd0)) : xo5_x;
    logic [63:0] yo5, yo5_x; assign yo5_x = (cb_sw[19][5] ? xr5 : yr5);
    always_ff @(posedge clk) yo5 <= DIR_r ? (64'(yo5_x >> 1) + (yo5_x[0] ? 64'(b5q_QHALF) : 64'd0)) : yo5_x;
    (* max_fanout = 16 *) logic [63:0] b6q_Q;
    always_ff @(posedge clk) b6q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b6q_MU;
    always_ff @(posedge clk) b6q_MU <= MU_r;
    logic [63:0] xr6; logic [63:0] yr6;
    Ie_n65536_q64b_B64_rns_bu u_bu6 (.clk(clk), .aIn(op12), .bIn(op13), .W(twr6_q), .Q(b6q_Q), .MU(b6q_MU), .aOut(xr6), .bOut(yr6));
    logic [63:0] xo6, xo6_x; assign xo6_x = (cb_sw[19][6] ? yr6 : xr6);
    (* max_fanout = 16 *) logic [63:0] b6q_QHALF;
    always_ff @(posedge clk) b6q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo6 <= DIR_r ? (64'(xo6_x >> 1) + (xo6_x[0] ? 64'(b6q_QHALF) : 64'd0)) : xo6_x;
    logic [63:0] yo6, yo6_x; assign yo6_x = (cb_sw[19][6] ? xr6 : yr6);
    always_ff @(posedge clk) yo6 <= DIR_r ? (64'(yo6_x >> 1) + (yo6_x[0] ? 64'(b6q_QHALF) : 64'd0)) : yo6_x;
    (* max_fanout = 16 *) logic [63:0] b7q_Q;
    always_ff @(posedge clk) b7q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b7q_MU;
    always_ff @(posedge clk) b7q_MU <= MU_r;
    logic [63:0] xr7; logic [63:0] yr7;
    Ie_n65536_q64b_B64_rns_bu u_bu7 (.clk(clk), .aIn(op14), .bIn(op15), .W(twr7_q), .Q(b7q_Q), .MU(b7q_MU), .aOut(xr7), .bOut(yr7));
    logic [63:0] xo7, xo7_x; assign xo7_x = (cb_sw[19][7] ? yr7 : xr7);
    (* max_fanout = 16 *) logic [63:0] b7q_QHALF;
    always_ff @(posedge clk) b7q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo7 <= DIR_r ? (64'(xo7_x >> 1) + (xo7_x[0] ? 64'(b7q_QHALF) : 64'd0)) : xo7_x;
    logic [63:0] yo7, yo7_x; assign yo7_x = (cb_sw[19][7] ? xr7 : yr7);
    always_ff @(posedge clk) yo7 <= DIR_r ? (64'(yo7_x >> 1) + (yo7_x[0] ? 64'(b7q_QHALF) : 64'd0)) : yo7_x;
    (* max_fanout = 16 *) logic [63:0] b8q_Q;
    always_ff @(posedge clk) b8q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b8q_MU;
    always_ff @(posedge clk) b8q_MU <= MU_r;
    logic [63:0] xr8; logic [63:0] yr8;
    Ie_n65536_q64b_B64_rns_bu u_bu8 (.clk(clk), .aIn(op16), .bIn(op17), .W(twr8_q), .Q(b8q_Q), .MU(b8q_MU), .aOut(xr8), .bOut(yr8));
    logic [63:0] xo8, xo8_x; assign xo8_x = (cb_sw[19][8] ? yr8 : xr8);
    (* max_fanout = 16 *) logic [63:0] b8q_QHALF;
    always_ff @(posedge clk) b8q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo8 <= DIR_r ? (64'(xo8_x >> 1) + (xo8_x[0] ? 64'(b8q_QHALF) : 64'd0)) : xo8_x;
    logic [63:0] yo8, yo8_x; assign yo8_x = (cb_sw[19][8] ? xr8 : yr8);
    always_ff @(posedge clk) yo8 <= DIR_r ? (64'(yo8_x >> 1) + (yo8_x[0] ? 64'(b8q_QHALF) : 64'd0)) : yo8_x;
    (* max_fanout = 16 *) logic [63:0] b9q_Q;
    always_ff @(posedge clk) b9q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b9q_MU;
    always_ff @(posedge clk) b9q_MU <= MU_r;
    logic [63:0] xr9; logic [63:0] yr9;
    Ie_n65536_q64b_B64_rns_bu u_bu9 (.clk(clk), .aIn(op18), .bIn(op19), .W(twr9_q), .Q(b9q_Q), .MU(b9q_MU), .aOut(xr9), .bOut(yr9));
    logic [63:0] xo9, xo9_x; assign xo9_x = (cb_sw[19][9] ? yr9 : xr9);
    (* max_fanout = 16 *) logic [63:0] b9q_QHALF;
    always_ff @(posedge clk) b9q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo9 <= DIR_r ? (64'(xo9_x >> 1) + (xo9_x[0] ? 64'(b9q_QHALF) : 64'd0)) : xo9_x;
    logic [63:0] yo9, yo9_x; assign yo9_x = (cb_sw[19][9] ? xr9 : yr9);
    always_ff @(posedge clk) yo9 <= DIR_r ? (64'(yo9_x >> 1) + (yo9_x[0] ? 64'(b9q_QHALF) : 64'd0)) : yo9_x;
    (* max_fanout = 16 *) logic [63:0] b10q_Q;
    always_ff @(posedge clk) b10q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b10q_MU;
    always_ff @(posedge clk) b10q_MU <= MU_r;
    logic [63:0] xr10; logic [63:0] yr10;
    Ie_n65536_q64b_B64_rns_bu u_bu10 (.clk(clk), .aIn(op20), .bIn(op21), .W(twr10_q), .Q(b10q_Q), .MU(b10q_MU), .aOut(xr10), .bOut(yr10));
    logic [63:0] xo10, xo10_x; assign xo10_x = (cb_sw[19][10] ? yr10 : xr10);
    (* max_fanout = 16 *) logic [63:0] b10q_QHALF;
    always_ff @(posedge clk) b10q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo10 <= DIR_r ? (64'(xo10_x >> 1) + (xo10_x[0] ? 64'(b10q_QHALF) : 64'd0)) : xo10_x;
    logic [63:0] yo10, yo10_x; assign yo10_x = (cb_sw[19][10] ? xr10 : yr10);
    always_ff @(posedge clk) yo10 <= DIR_r ? (64'(yo10_x >> 1) + (yo10_x[0] ? 64'(b10q_QHALF) : 64'd0)) : yo10_x;
    (* max_fanout = 16 *) logic [63:0] b11q_Q;
    always_ff @(posedge clk) b11q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b11q_MU;
    always_ff @(posedge clk) b11q_MU <= MU_r;
    logic [63:0] xr11; logic [63:0] yr11;
    Ie_n65536_q64b_B64_rns_bu u_bu11 (.clk(clk), .aIn(op22), .bIn(op23), .W(twr11_q), .Q(b11q_Q), .MU(b11q_MU), .aOut(xr11), .bOut(yr11));
    logic [63:0] xo11, xo11_x; assign xo11_x = (cb_sw[19][11] ? yr11 : xr11);
    (* max_fanout = 16 *) logic [63:0] b11q_QHALF;
    always_ff @(posedge clk) b11q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo11 <= DIR_r ? (64'(xo11_x >> 1) + (xo11_x[0] ? 64'(b11q_QHALF) : 64'd0)) : xo11_x;
    logic [63:0] yo11, yo11_x; assign yo11_x = (cb_sw[19][11] ? xr11 : yr11);
    always_ff @(posedge clk) yo11 <= DIR_r ? (64'(yo11_x >> 1) + (yo11_x[0] ? 64'(b11q_QHALF) : 64'd0)) : yo11_x;
    (* max_fanout = 16 *) logic [63:0] b12q_Q;
    always_ff @(posedge clk) b12q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b12q_MU;
    always_ff @(posedge clk) b12q_MU <= MU_r;
    logic [63:0] xr12; logic [63:0] yr12;
    Ie_n65536_q64b_B64_rns_bu u_bu12 (.clk(clk), .aIn(op24), .bIn(op25), .W(twr12_q), .Q(b12q_Q), .MU(b12q_MU), .aOut(xr12), .bOut(yr12));
    logic [63:0] xo12, xo12_x; assign xo12_x = (cb_sw[19][12] ? yr12 : xr12);
    (* max_fanout = 16 *) logic [63:0] b12q_QHALF;
    always_ff @(posedge clk) b12q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo12 <= DIR_r ? (64'(xo12_x >> 1) + (xo12_x[0] ? 64'(b12q_QHALF) : 64'd0)) : xo12_x;
    logic [63:0] yo12, yo12_x; assign yo12_x = (cb_sw[19][12] ? xr12 : yr12);
    always_ff @(posedge clk) yo12 <= DIR_r ? (64'(yo12_x >> 1) + (yo12_x[0] ? 64'(b12q_QHALF) : 64'd0)) : yo12_x;
    (* max_fanout = 16 *) logic [63:0] b13q_Q;
    always_ff @(posedge clk) b13q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b13q_MU;
    always_ff @(posedge clk) b13q_MU <= MU_r;
    logic [63:0] xr13; logic [63:0] yr13;
    Ie_n65536_q64b_B64_rns_bu u_bu13 (.clk(clk), .aIn(op26), .bIn(op27), .W(twr13_q), .Q(b13q_Q), .MU(b13q_MU), .aOut(xr13), .bOut(yr13));
    logic [63:0] xo13, xo13_x; assign xo13_x = (cb_sw[19][13] ? yr13 : xr13);
    (* max_fanout = 16 *) logic [63:0] b13q_QHALF;
    always_ff @(posedge clk) b13q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo13 <= DIR_r ? (64'(xo13_x >> 1) + (xo13_x[0] ? 64'(b13q_QHALF) : 64'd0)) : xo13_x;
    logic [63:0] yo13, yo13_x; assign yo13_x = (cb_sw[19][13] ? xr13 : yr13);
    always_ff @(posedge clk) yo13 <= DIR_r ? (64'(yo13_x >> 1) + (yo13_x[0] ? 64'(b13q_QHALF) : 64'd0)) : yo13_x;
    (* max_fanout = 16 *) logic [63:0] b14q_Q;
    always_ff @(posedge clk) b14q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b14q_MU;
    always_ff @(posedge clk) b14q_MU <= MU_r;
    logic [63:0] xr14; logic [63:0] yr14;
    Ie_n65536_q64b_B64_rns_bu u_bu14 (.clk(clk), .aIn(op28), .bIn(op29), .W(twr14_q), .Q(b14q_Q), .MU(b14q_MU), .aOut(xr14), .bOut(yr14));
    logic [63:0] xo14, xo14_x; assign xo14_x = (cb_sw[19][14] ? yr14 : xr14);
    (* max_fanout = 16 *) logic [63:0] b14q_QHALF;
    always_ff @(posedge clk) b14q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo14 <= DIR_r ? (64'(xo14_x >> 1) + (xo14_x[0] ? 64'(b14q_QHALF) : 64'd0)) : xo14_x;
    logic [63:0] yo14, yo14_x; assign yo14_x = (cb_sw[19][14] ? xr14 : yr14);
    always_ff @(posedge clk) yo14 <= DIR_r ? (64'(yo14_x >> 1) + (yo14_x[0] ? 64'(b14q_QHALF) : 64'd0)) : yo14_x;
    (* max_fanout = 16 *) logic [63:0] b15q_Q;
    always_ff @(posedge clk) b15q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b15q_MU;
    always_ff @(posedge clk) b15q_MU <= MU_r;
    logic [63:0] xr15; logic [63:0] yr15;
    Ie_n65536_q64b_B64_rns_bu u_bu15 (.clk(clk), .aIn(op30), .bIn(op31), .W(twr15_q), .Q(b15q_Q), .MU(b15q_MU), .aOut(xr15), .bOut(yr15));
    logic [63:0] xo15, xo15_x; assign xo15_x = (cb_sw[19][15] ? yr15 : xr15);
    (* max_fanout = 16 *) logic [63:0] b15q_QHALF;
    always_ff @(posedge clk) b15q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo15 <= DIR_r ? (64'(xo15_x >> 1) + (xo15_x[0] ? 64'(b15q_QHALF) : 64'd0)) : xo15_x;
    logic [63:0] yo15, yo15_x; assign yo15_x = (cb_sw[19][15] ? xr15 : yr15);
    always_ff @(posedge clk) yo15 <= DIR_r ? (64'(yo15_x >> 1) + (yo15_x[0] ? 64'(b15q_QHALF) : 64'd0)) : yo15_x;
    (* max_fanout = 16 *) logic [63:0] b16q_Q;
    always_ff @(posedge clk) b16q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b16q_MU;
    always_ff @(posedge clk) b16q_MU <= MU_r;
    logic [63:0] xr16; logic [63:0] yr16;
    Ie_n65536_q64b_B64_rns_bu u_bu16 (.clk(clk), .aIn(op32), .bIn(op33), .W(twr16_q), .Q(b16q_Q), .MU(b16q_MU), .aOut(xr16), .bOut(yr16));
    logic [63:0] xo16, xo16_x; assign xo16_x = (cb_sw[19][16] ? yr16 : xr16);
    (* max_fanout = 16 *) logic [63:0] b16q_QHALF;
    always_ff @(posedge clk) b16q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo16 <= DIR_r ? (64'(xo16_x >> 1) + (xo16_x[0] ? 64'(b16q_QHALF) : 64'd0)) : xo16_x;
    logic [63:0] yo16, yo16_x; assign yo16_x = (cb_sw[19][16] ? xr16 : yr16);
    always_ff @(posedge clk) yo16 <= DIR_r ? (64'(yo16_x >> 1) + (yo16_x[0] ? 64'(b16q_QHALF) : 64'd0)) : yo16_x;
    (* max_fanout = 16 *) logic [63:0] b17q_Q;
    always_ff @(posedge clk) b17q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b17q_MU;
    always_ff @(posedge clk) b17q_MU <= MU_r;
    logic [63:0] xr17; logic [63:0] yr17;
    Ie_n65536_q64b_B64_rns_bu u_bu17 (.clk(clk), .aIn(op34), .bIn(op35), .W(twr17_q), .Q(b17q_Q), .MU(b17q_MU), .aOut(xr17), .bOut(yr17));
    logic [63:0] xo17, xo17_x; assign xo17_x = (cb_sw[19][17] ? yr17 : xr17);
    (* max_fanout = 16 *) logic [63:0] b17q_QHALF;
    always_ff @(posedge clk) b17q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo17 <= DIR_r ? (64'(xo17_x >> 1) + (xo17_x[0] ? 64'(b17q_QHALF) : 64'd0)) : xo17_x;
    logic [63:0] yo17, yo17_x; assign yo17_x = (cb_sw[19][17] ? xr17 : yr17);
    always_ff @(posedge clk) yo17 <= DIR_r ? (64'(yo17_x >> 1) + (yo17_x[0] ? 64'(b17q_QHALF) : 64'd0)) : yo17_x;
    (* max_fanout = 16 *) logic [63:0] b18q_Q;
    always_ff @(posedge clk) b18q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b18q_MU;
    always_ff @(posedge clk) b18q_MU <= MU_r;
    logic [63:0] xr18; logic [63:0] yr18;
    Ie_n65536_q64b_B64_rns_bu u_bu18 (.clk(clk), .aIn(op36), .bIn(op37), .W(twr18_q), .Q(b18q_Q), .MU(b18q_MU), .aOut(xr18), .bOut(yr18));
    logic [63:0] xo18, xo18_x; assign xo18_x = (cb_sw[19][18] ? yr18 : xr18);
    (* max_fanout = 16 *) logic [63:0] b18q_QHALF;
    always_ff @(posedge clk) b18q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo18 <= DIR_r ? (64'(xo18_x >> 1) + (xo18_x[0] ? 64'(b18q_QHALF) : 64'd0)) : xo18_x;
    logic [63:0] yo18, yo18_x; assign yo18_x = (cb_sw[19][18] ? xr18 : yr18);
    always_ff @(posedge clk) yo18 <= DIR_r ? (64'(yo18_x >> 1) + (yo18_x[0] ? 64'(b18q_QHALF) : 64'd0)) : yo18_x;
    (* max_fanout = 16 *) logic [63:0] b19q_Q;
    always_ff @(posedge clk) b19q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b19q_MU;
    always_ff @(posedge clk) b19q_MU <= MU_r;
    logic [63:0] xr19; logic [63:0] yr19;
    Ie_n65536_q64b_B64_rns_bu u_bu19 (.clk(clk), .aIn(op38), .bIn(op39), .W(twr19_q), .Q(b19q_Q), .MU(b19q_MU), .aOut(xr19), .bOut(yr19));
    logic [63:0] xo19, xo19_x; assign xo19_x = (cb_sw[19][19] ? yr19 : xr19);
    (* max_fanout = 16 *) logic [63:0] b19q_QHALF;
    always_ff @(posedge clk) b19q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo19 <= DIR_r ? (64'(xo19_x >> 1) + (xo19_x[0] ? 64'(b19q_QHALF) : 64'd0)) : xo19_x;
    logic [63:0] yo19, yo19_x; assign yo19_x = (cb_sw[19][19] ? xr19 : yr19);
    always_ff @(posedge clk) yo19 <= DIR_r ? (64'(yo19_x >> 1) + (yo19_x[0] ? 64'(b19q_QHALF) : 64'd0)) : yo19_x;
    (* max_fanout = 16 *) logic [63:0] b20q_Q;
    always_ff @(posedge clk) b20q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b20q_MU;
    always_ff @(posedge clk) b20q_MU <= MU_r;
    logic [63:0] xr20; logic [63:0] yr20;
    Ie_n65536_q64b_B64_rns_bu u_bu20 (.clk(clk), .aIn(op40), .bIn(op41), .W(twr20_q), .Q(b20q_Q), .MU(b20q_MU), .aOut(xr20), .bOut(yr20));
    logic [63:0] xo20, xo20_x; assign xo20_x = (cb_sw[19][20] ? yr20 : xr20);
    (* max_fanout = 16 *) logic [63:0] b20q_QHALF;
    always_ff @(posedge clk) b20q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo20 <= DIR_r ? (64'(xo20_x >> 1) + (xo20_x[0] ? 64'(b20q_QHALF) : 64'd0)) : xo20_x;
    logic [63:0] yo20, yo20_x; assign yo20_x = (cb_sw[19][20] ? xr20 : yr20);
    always_ff @(posedge clk) yo20 <= DIR_r ? (64'(yo20_x >> 1) + (yo20_x[0] ? 64'(b20q_QHALF) : 64'd0)) : yo20_x;
    (* max_fanout = 16 *) logic [63:0] b21q_Q;
    always_ff @(posedge clk) b21q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b21q_MU;
    always_ff @(posedge clk) b21q_MU <= MU_r;
    logic [63:0] xr21; logic [63:0] yr21;
    Ie_n65536_q64b_B64_rns_bu u_bu21 (.clk(clk), .aIn(op42), .bIn(op43), .W(twr21_q), .Q(b21q_Q), .MU(b21q_MU), .aOut(xr21), .bOut(yr21));
    logic [63:0] xo21, xo21_x; assign xo21_x = (cb_sw[19][21] ? yr21 : xr21);
    (* max_fanout = 16 *) logic [63:0] b21q_QHALF;
    always_ff @(posedge clk) b21q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo21 <= DIR_r ? (64'(xo21_x >> 1) + (xo21_x[0] ? 64'(b21q_QHALF) : 64'd0)) : xo21_x;
    logic [63:0] yo21, yo21_x; assign yo21_x = (cb_sw[19][21] ? xr21 : yr21);
    always_ff @(posedge clk) yo21 <= DIR_r ? (64'(yo21_x >> 1) + (yo21_x[0] ? 64'(b21q_QHALF) : 64'd0)) : yo21_x;
    (* max_fanout = 16 *) logic [63:0] b22q_Q;
    always_ff @(posedge clk) b22q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b22q_MU;
    always_ff @(posedge clk) b22q_MU <= MU_r;
    logic [63:0] xr22; logic [63:0] yr22;
    Ie_n65536_q64b_B64_rns_bu u_bu22 (.clk(clk), .aIn(op44), .bIn(op45), .W(twr22_q), .Q(b22q_Q), .MU(b22q_MU), .aOut(xr22), .bOut(yr22));
    logic [63:0] xo22, xo22_x; assign xo22_x = (cb_sw[19][22] ? yr22 : xr22);
    (* max_fanout = 16 *) logic [63:0] b22q_QHALF;
    always_ff @(posedge clk) b22q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo22 <= DIR_r ? (64'(xo22_x >> 1) + (xo22_x[0] ? 64'(b22q_QHALF) : 64'd0)) : xo22_x;
    logic [63:0] yo22, yo22_x; assign yo22_x = (cb_sw[19][22] ? xr22 : yr22);
    always_ff @(posedge clk) yo22 <= DIR_r ? (64'(yo22_x >> 1) + (yo22_x[0] ? 64'(b22q_QHALF) : 64'd0)) : yo22_x;
    (* max_fanout = 16 *) logic [63:0] b23q_Q;
    always_ff @(posedge clk) b23q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b23q_MU;
    always_ff @(posedge clk) b23q_MU <= MU_r;
    logic [63:0] xr23; logic [63:0] yr23;
    Ie_n65536_q64b_B64_rns_bu u_bu23 (.clk(clk), .aIn(op46), .bIn(op47), .W(twr23_q), .Q(b23q_Q), .MU(b23q_MU), .aOut(xr23), .bOut(yr23));
    logic [63:0] xo23, xo23_x; assign xo23_x = (cb_sw[19][23] ? yr23 : xr23);
    (* max_fanout = 16 *) logic [63:0] b23q_QHALF;
    always_ff @(posedge clk) b23q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo23 <= DIR_r ? (64'(xo23_x >> 1) + (xo23_x[0] ? 64'(b23q_QHALF) : 64'd0)) : xo23_x;
    logic [63:0] yo23, yo23_x; assign yo23_x = (cb_sw[19][23] ? xr23 : yr23);
    always_ff @(posedge clk) yo23 <= DIR_r ? (64'(yo23_x >> 1) + (yo23_x[0] ? 64'(b23q_QHALF) : 64'd0)) : yo23_x;
    (* max_fanout = 16 *) logic [63:0] b24q_Q;
    always_ff @(posedge clk) b24q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b24q_MU;
    always_ff @(posedge clk) b24q_MU <= MU_r;
    logic [63:0] xr24; logic [63:0] yr24;
    Ie_n65536_q64b_B64_rns_bu u_bu24 (.clk(clk), .aIn(op48), .bIn(op49), .W(twr24_q), .Q(b24q_Q), .MU(b24q_MU), .aOut(xr24), .bOut(yr24));
    logic [63:0] xo24, xo24_x; assign xo24_x = (cb_sw[19][24] ? yr24 : xr24);
    (* max_fanout = 16 *) logic [63:0] b24q_QHALF;
    always_ff @(posedge clk) b24q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo24 <= DIR_r ? (64'(xo24_x >> 1) + (xo24_x[0] ? 64'(b24q_QHALF) : 64'd0)) : xo24_x;
    logic [63:0] yo24, yo24_x; assign yo24_x = (cb_sw[19][24] ? xr24 : yr24);
    always_ff @(posedge clk) yo24 <= DIR_r ? (64'(yo24_x >> 1) + (yo24_x[0] ? 64'(b24q_QHALF) : 64'd0)) : yo24_x;
    (* max_fanout = 16 *) logic [63:0] b25q_Q;
    always_ff @(posedge clk) b25q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b25q_MU;
    always_ff @(posedge clk) b25q_MU <= MU_r;
    logic [63:0] xr25; logic [63:0] yr25;
    Ie_n65536_q64b_B64_rns_bu u_bu25 (.clk(clk), .aIn(op50), .bIn(op51), .W(twr25_q), .Q(b25q_Q), .MU(b25q_MU), .aOut(xr25), .bOut(yr25));
    logic [63:0] xo25, xo25_x; assign xo25_x = (cb_sw[19][25] ? yr25 : xr25);
    (* max_fanout = 16 *) logic [63:0] b25q_QHALF;
    always_ff @(posedge clk) b25q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo25 <= DIR_r ? (64'(xo25_x >> 1) + (xo25_x[0] ? 64'(b25q_QHALF) : 64'd0)) : xo25_x;
    logic [63:0] yo25, yo25_x; assign yo25_x = (cb_sw[19][25] ? xr25 : yr25);
    always_ff @(posedge clk) yo25 <= DIR_r ? (64'(yo25_x >> 1) + (yo25_x[0] ? 64'(b25q_QHALF) : 64'd0)) : yo25_x;
    (* max_fanout = 16 *) logic [63:0] b26q_Q;
    always_ff @(posedge clk) b26q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b26q_MU;
    always_ff @(posedge clk) b26q_MU <= MU_r;
    logic [63:0] xr26; logic [63:0] yr26;
    Ie_n65536_q64b_B64_rns_bu u_bu26 (.clk(clk), .aIn(op52), .bIn(op53), .W(twr26_q), .Q(b26q_Q), .MU(b26q_MU), .aOut(xr26), .bOut(yr26));
    logic [63:0] xo26, xo26_x; assign xo26_x = (cb_sw[19][26] ? yr26 : xr26);
    (* max_fanout = 16 *) logic [63:0] b26q_QHALF;
    always_ff @(posedge clk) b26q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo26 <= DIR_r ? (64'(xo26_x >> 1) + (xo26_x[0] ? 64'(b26q_QHALF) : 64'd0)) : xo26_x;
    logic [63:0] yo26, yo26_x; assign yo26_x = (cb_sw[19][26] ? xr26 : yr26);
    always_ff @(posedge clk) yo26 <= DIR_r ? (64'(yo26_x >> 1) + (yo26_x[0] ? 64'(b26q_QHALF) : 64'd0)) : yo26_x;
    (* max_fanout = 16 *) logic [63:0] b27q_Q;
    always_ff @(posedge clk) b27q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b27q_MU;
    always_ff @(posedge clk) b27q_MU <= MU_r;
    logic [63:0] xr27; logic [63:0] yr27;
    Ie_n65536_q64b_B64_rns_bu u_bu27 (.clk(clk), .aIn(op54), .bIn(op55), .W(twr27_q), .Q(b27q_Q), .MU(b27q_MU), .aOut(xr27), .bOut(yr27));
    logic [63:0] xo27, xo27_x; assign xo27_x = (cb_sw[19][27] ? yr27 : xr27);
    (* max_fanout = 16 *) logic [63:0] b27q_QHALF;
    always_ff @(posedge clk) b27q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo27 <= DIR_r ? (64'(xo27_x >> 1) + (xo27_x[0] ? 64'(b27q_QHALF) : 64'd0)) : xo27_x;
    logic [63:0] yo27, yo27_x; assign yo27_x = (cb_sw[19][27] ? xr27 : yr27);
    always_ff @(posedge clk) yo27 <= DIR_r ? (64'(yo27_x >> 1) + (yo27_x[0] ? 64'(b27q_QHALF) : 64'd0)) : yo27_x;
    (* max_fanout = 16 *) logic [63:0] b28q_Q;
    always_ff @(posedge clk) b28q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b28q_MU;
    always_ff @(posedge clk) b28q_MU <= MU_r;
    logic [63:0] xr28; logic [63:0] yr28;
    Ie_n65536_q64b_B64_rns_bu u_bu28 (.clk(clk), .aIn(op56), .bIn(op57), .W(twr28_q), .Q(b28q_Q), .MU(b28q_MU), .aOut(xr28), .bOut(yr28));
    logic [63:0] xo28, xo28_x; assign xo28_x = (cb_sw[19][28] ? yr28 : xr28);
    (* max_fanout = 16 *) logic [63:0] b28q_QHALF;
    always_ff @(posedge clk) b28q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo28 <= DIR_r ? (64'(xo28_x >> 1) + (xo28_x[0] ? 64'(b28q_QHALF) : 64'd0)) : xo28_x;
    logic [63:0] yo28, yo28_x; assign yo28_x = (cb_sw[19][28] ? xr28 : yr28);
    always_ff @(posedge clk) yo28 <= DIR_r ? (64'(yo28_x >> 1) + (yo28_x[0] ? 64'(b28q_QHALF) : 64'd0)) : yo28_x;
    (* max_fanout = 16 *) logic [63:0] b29q_Q;
    always_ff @(posedge clk) b29q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b29q_MU;
    always_ff @(posedge clk) b29q_MU <= MU_r;
    logic [63:0] xr29; logic [63:0] yr29;
    Ie_n65536_q64b_B64_rns_bu u_bu29 (.clk(clk), .aIn(op58), .bIn(op59), .W(twr29_q), .Q(b29q_Q), .MU(b29q_MU), .aOut(xr29), .bOut(yr29));
    logic [63:0] xo29, xo29_x; assign xo29_x = (cb_sw[19][29] ? yr29 : xr29);
    (* max_fanout = 16 *) logic [63:0] b29q_QHALF;
    always_ff @(posedge clk) b29q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo29 <= DIR_r ? (64'(xo29_x >> 1) + (xo29_x[0] ? 64'(b29q_QHALF) : 64'd0)) : xo29_x;
    logic [63:0] yo29, yo29_x; assign yo29_x = (cb_sw[19][29] ? xr29 : yr29);
    always_ff @(posedge clk) yo29 <= DIR_r ? (64'(yo29_x >> 1) + (yo29_x[0] ? 64'(b29q_QHALF) : 64'd0)) : yo29_x;
    (* max_fanout = 16 *) logic [63:0] b30q_Q;
    always_ff @(posedge clk) b30q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b30q_MU;
    always_ff @(posedge clk) b30q_MU <= MU_r;
    logic [63:0] xr30; logic [63:0] yr30;
    Ie_n65536_q64b_B64_rns_bu u_bu30 (.clk(clk), .aIn(op60), .bIn(op61), .W(twr30_q), .Q(b30q_Q), .MU(b30q_MU), .aOut(xr30), .bOut(yr30));
    logic [63:0] xo30, xo30_x; assign xo30_x = (cb_sw[19][30] ? yr30 : xr30);
    (* max_fanout = 16 *) logic [63:0] b30q_QHALF;
    always_ff @(posedge clk) b30q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo30 <= DIR_r ? (64'(xo30_x >> 1) + (xo30_x[0] ? 64'(b30q_QHALF) : 64'd0)) : xo30_x;
    logic [63:0] yo30, yo30_x; assign yo30_x = (cb_sw[19][30] ? xr30 : yr30);
    always_ff @(posedge clk) yo30 <= DIR_r ? (64'(yo30_x >> 1) + (yo30_x[0] ? 64'(b30q_QHALF) : 64'd0)) : yo30_x;
    (* max_fanout = 16 *) logic [63:0] b31q_Q;
    always_ff @(posedge clk) b31q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b31q_MU;
    always_ff @(posedge clk) b31q_MU <= MU_r;
    logic [63:0] xr31; logic [63:0] yr31;
    Ie_n65536_q64b_B64_rns_bu u_bu31 (.clk(clk), .aIn(op62), .bIn(op63), .W(twr31_q), .Q(b31q_Q), .MU(b31q_MU), .aOut(xr31), .bOut(yr31));
    logic [63:0] xo31, xo31_x; assign xo31_x = (cb_sw[19][31] ? yr31 : xr31);
    (* max_fanout = 16 *) logic [63:0] b31q_QHALF;
    always_ff @(posedge clk) b31q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo31 <= DIR_r ? (64'(xo31_x >> 1) + (xo31_x[0] ? 64'(b31q_QHALF) : 64'd0)) : xo31_x;
    logic [63:0] yo31, yo31_x; assign yo31_x = (cb_sw[19][31] ? xr31 : yr31);
    always_ff @(posedge clk) yo31 <= DIR_r ? (64'(yo31_x >> 1) + (yo31_x[0] ? 64'(b31q_QHALF) : 64'd0)) : yo31_x;
    (* max_fanout = 16 *) logic [63:0] b32q_Q;
    always_ff @(posedge clk) b32q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b32q_MU;
    always_ff @(posedge clk) b32q_MU <= MU_r;
    logic [63:0] xr32; logic [63:0] yr32;
    Ie_n65536_q64b_B64_rns_bu u_bu32 (.clk(clk), .aIn(op64), .bIn(op65), .W(twr32_q), .Q(b32q_Q), .MU(b32q_MU), .aOut(xr32), .bOut(yr32));
    logic [63:0] xo32, xo32_x; assign xo32_x = (cb_sw[19][32] ? yr32 : xr32);
    (* max_fanout = 16 *) logic [63:0] b32q_QHALF;
    always_ff @(posedge clk) b32q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo32 <= DIR_r ? (64'(xo32_x >> 1) + (xo32_x[0] ? 64'(b32q_QHALF) : 64'd0)) : xo32_x;
    logic [63:0] yo32, yo32_x; assign yo32_x = (cb_sw[19][32] ? xr32 : yr32);
    always_ff @(posedge clk) yo32 <= DIR_r ? (64'(yo32_x >> 1) + (yo32_x[0] ? 64'(b32q_QHALF) : 64'd0)) : yo32_x;
    (* max_fanout = 16 *) logic [63:0] b33q_Q;
    always_ff @(posedge clk) b33q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b33q_MU;
    always_ff @(posedge clk) b33q_MU <= MU_r;
    logic [63:0] xr33; logic [63:0] yr33;
    Ie_n65536_q64b_B64_rns_bu u_bu33 (.clk(clk), .aIn(op66), .bIn(op67), .W(twr33_q), .Q(b33q_Q), .MU(b33q_MU), .aOut(xr33), .bOut(yr33));
    logic [63:0] xo33, xo33_x; assign xo33_x = (cb_sw[19][33] ? yr33 : xr33);
    (* max_fanout = 16 *) logic [63:0] b33q_QHALF;
    always_ff @(posedge clk) b33q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo33 <= DIR_r ? (64'(xo33_x >> 1) + (xo33_x[0] ? 64'(b33q_QHALF) : 64'd0)) : xo33_x;
    logic [63:0] yo33, yo33_x; assign yo33_x = (cb_sw[19][33] ? xr33 : yr33);
    always_ff @(posedge clk) yo33 <= DIR_r ? (64'(yo33_x >> 1) + (yo33_x[0] ? 64'(b33q_QHALF) : 64'd0)) : yo33_x;
    (* max_fanout = 16 *) logic [63:0] b34q_Q;
    always_ff @(posedge clk) b34q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b34q_MU;
    always_ff @(posedge clk) b34q_MU <= MU_r;
    logic [63:0] xr34; logic [63:0] yr34;
    Ie_n65536_q64b_B64_rns_bu u_bu34 (.clk(clk), .aIn(op68), .bIn(op69), .W(twr34_q), .Q(b34q_Q), .MU(b34q_MU), .aOut(xr34), .bOut(yr34));
    logic [63:0] xo34, xo34_x; assign xo34_x = (cb_sw[19][34] ? yr34 : xr34);
    (* max_fanout = 16 *) logic [63:0] b34q_QHALF;
    always_ff @(posedge clk) b34q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo34 <= DIR_r ? (64'(xo34_x >> 1) + (xo34_x[0] ? 64'(b34q_QHALF) : 64'd0)) : xo34_x;
    logic [63:0] yo34, yo34_x; assign yo34_x = (cb_sw[19][34] ? xr34 : yr34);
    always_ff @(posedge clk) yo34 <= DIR_r ? (64'(yo34_x >> 1) + (yo34_x[0] ? 64'(b34q_QHALF) : 64'd0)) : yo34_x;
    (* max_fanout = 16 *) logic [63:0] b35q_Q;
    always_ff @(posedge clk) b35q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b35q_MU;
    always_ff @(posedge clk) b35q_MU <= MU_r;
    logic [63:0] xr35; logic [63:0] yr35;
    Ie_n65536_q64b_B64_rns_bu u_bu35 (.clk(clk), .aIn(op70), .bIn(op71), .W(twr35_q), .Q(b35q_Q), .MU(b35q_MU), .aOut(xr35), .bOut(yr35));
    logic [63:0] xo35, xo35_x; assign xo35_x = (cb_sw[19][35] ? yr35 : xr35);
    (* max_fanout = 16 *) logic [63:0] b35q_QHALF;
    always_ff @(posedge clk) b35q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo35 <= DIR_r ? (64'(xo35_x >> 1) + (xo35_x[0] ? 64'(b35q_QHALF) : 64'd0)) : xo35_x;
    logic [63:0] yo35, yo35_x; assign yo35_x = (cb_sw[19][35] ? xr35 : yr35);
    always_ff @(posedge clk) yo35 <= DIR_r ? (64'(yo35_x >> 1) + (yo35_x[0] ? 64'(b35q_QHALF) : 64'd0)) : yo35_x;
    (* max_fanout = 16 *) logic [63:0] b36q_Q;
    always_ff @(posedge clk) b36q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b36q_MU;
    always_ff @(posedge clk) b36q_MU <= MU_r;
    logic [63:0] xr36; logic [63:0] yr36;
    Ie_n65536_q64b_B64_rns_bu u_bu36 (.clk(clk), .aIn(op72), .bIn(op73), .W(twr36_q), .Q(b36q_Q), .MU(b36q_MU), .aOut(xr36), .bOut(yr36));
    logic [63:0] xo36, xo36_x; assign xo36_x = (cb_sw[19][36] ? yr36 : xr36);
    (* max_fanout = 16 *) logic [63:0] b36q_QHALF;
    always_ff @(posedge clk) b36q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo36 <= DIR_r ? (64'(xo36_x >> 1) + (xo36_x[0] ? 64'(b36q_QHALF) : 64'd0)) : xo36_x;
    logic [63:0] yo36, yo36_x; assign yo36_x = (cb_sw[19][36] ? xr36 : yr36);
    always_ff @(posedge clk) yo36 <= DIR_r ? (64'(yo36_x >> 1) + (yo36_x[0] ? 64'(b36q_QHALF) : 64'd0)) : yo36_x;
    (* max_fanout = 16 *) logic [63:0] b37q_Q;
    always_ff @(posedge clk) b37q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b37q_MU;
    always_ff @(posedge clk) b37q_MU <= MU_r;
    logic [63:0] xr37; logic [63:0] yr37;
    Ie_n65536_q64b_B64_rns_bu u_bu37 (.clk(clk), .aIn(op74), .bIn(op75), .W(twr37_q), .Q(b37q_Q), .MU(b37q_MU), .aOut(xr37), .bOut(yr37));
    logic [63:0] xo37, xo37_x; assign xo37_x = (cb_sw[19][37] ? yr37 : xr37);
    (* max_fanout = 16 *) logic [63:0] b37q_QHALF;
    always_ff @(posedge clk) b37q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo37 <= DIR_r ? (64'(xo37_x >> 1) + (xo37_x[0] ? 64'(b37q_QHALF) : 64'd0)) : xo37_x;
    logic [63:0] yo37, yo37_x; assign yo37_x = (cb_sw[19][37] ? xr37 : yr37);
    always_ff @(posedge clk) yo37 <= DIR_r ? (64'(yo37_x >> 1) + (yo37_x[0] ? 64'(b37q_QHALF) : 64'd0)) : yo37_x;
    (* max_fanout = 16 *) logic [63:0] b38q_Q;
    always_ff @(posedge clk) b38q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b38q_MU;
    always_ff @(posedge clk) b38q_MU <= MU_r;
    logic [63:0] xr38; logic [63:0] yr38;
    Ie_n65536_q64b_B64_rns_bu u_bu38 (.clk(clk), .aIn(op76), .bIn(op77), .W(twr38_q), .Q(b38q_Q), .MU(b38q_MU), .aOut(xr38), .bOut(yr38));
    logic [63:0] xo38, xo38_x; assign xo38_x = (cb_sw[19][38] ? yr38 : xr38);
    (* max_fanout = 16 *) logic [63:0] b38q_QHALF;
    always_ff @(posedge clk) b38q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo38 <= DIR_r ? (64'(xo38_x >> 1) + (xo38_x[0] ? 64'(b38q_QHALF) : 64'd0)) : xo38_x;
    logic [63:0] yo38, yo38_x; assign yo38_x = (cb_sw[19][38] ? xr38 : yr38);
    always_ff @(posedge clk) yo38 <= DIR_r ? (64'(yo38_x >> 1) + (yo38_x[0] ? 64'(b38q_QHALF) : 64'd0)) : yo38_x;
    (* max_fanout = 16 *) logic [63:0] b39q_Q;
    always_ff @(posedge clk) b39q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b39q_MU;
    always_ff @(posedge clk) b39q_MU <= MU_r;
    logic [63:0] xr39; logic [63:0] yr39;
    Ie_n65536_q64b_B64_rns_bu u_bu39 (.clk(clk), .aIn(op78), .bIn(op79), .W(twr39_q), .Q(b39q_Q), .MU(b39q_MU), .aOut(xr39), .bOut(yr39));
    logic [63:0] xo39, xo39_x; assign xo39_x = (cb_sw[19][39] ? yr39 : xr39);
    (* max_fanout = 16 *) logic [63:0] b39q_QHALF;
    always_ff @(posedge clk) b39q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo39 <= DIR_r ? (64'(xo39_x >> 1) + (xo39_x[0] ? 64'(b39q_QHALF) : 64'd0)) : xo39_x;
    logic [63:0] yo39, yo39_x; assign yo39_x = (cb_sw[19][39] ? xr39 : yr39);
    always_ff @(posedge clk) yo39 <= DIR_r ? (64'(yo39_x >> 1) + (yo39_x[0] ? 64'(b39q_QHALF) : 64'd0)) : yo39_x;
    (* max_fanout = 16 *) logic [63:0] b40q_Q;
    always_ff @(posedge clk) b40q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b40q_MU;
    always_ff @(posedge clk) b40q_MU <= MU_r;
    logic [63:0] xr40; logic [63:0] yr40;
    Ie_n65536_q64b_B64_rns_bu u_bu40 (.clk(clk), .aIn(op80), .bIn(op81), .W(twr40_q), .Q(b40q_Q), .MU(b40q_MU), .aOut(xr40), .bOut(yr40));
    logic [63:0] xo40, xo40_x; assign xo40_x = (cb_sw[19][40] ? yr40 : xr40);
    (* max_fanout = 16 *) logic [63:0] b40q_QHALF;
    always_ff @(posedge clk) b40q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo40 <= DIR_r ? (64'(xo40_x >> 1) + (xo40_x[0] ? 64'(b40q_QHALF) : 64'd0)) : xo40_x;
    logic [63:0] yo40, yo40_x; assign yo40_x = (cb_sw[19][40] ? xr40 : yr40);
    always_ff @(posedge clk) yo40 <= DIR_r ? (64'(yo40_x >> 1) + (yo40_x[0] ? 64'(b40q_QHALF) : 64'd0)) : yo40_x;
    (* max_fanout = 16 *) logic [63:0] b41q_Q;
    always_ff @(posedge clk) b41q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b41q_MU;
    always_ff @(posedge clk) b41q_MU <= MU_r;
    logic [63:0] xr41; logic [63:0] yr41;
    Ie_n65536_q64b_B64_rns_bu u_bu41 (.clk(clk), .aIn(op82), .bIn(op83), .W(twr41_q), .Q(b41q_Q), .MU(b41q_MU), .aOut(xr41), .bOut(yr41));
    logic [63:0] xo41, xo41_x; assign xo41_x = (cb_sw[19][41] ? yr41 : xr41);
    (* max_fanout = 16 *) logic [63:0] b41q_QHALF;
    always_ff @(posedge clk) b41q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo41 <= DIR_r ? (64'(xo41_x >> 1) + (xo41_x[0] ? 64'(b41q_QHALF) : 64'd0)) : xo41_x;
    logic [63:0] yo41, yo41_x; assign yo41_x = (cb_sw[19][41] ? xr41 : yr41);
    always_ff @(posedge clk) yo41 <= DIR_r ? (64'(yo41_x >> 1) + (yo41_x[0] ? 64'(b41q_QHALF) : 64'd0)) : yo41_x;
    (* max_fanout = 16 *) logic [63:0] b42q_Q;
    always_ff @(posedge clk) b42q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b42q_MU;
    always_ff @(posedge clk) b42q_MU <= MU_r;
    logic [63:0] xr42; logic [63:0] yr42;
    Ie_n65536_q64b_B64_rns_bu u_bu42 (.clk(clk), .aIn(op84), .bIn(op85), .W(twr42_q), .Q(b42q_Q), .MU(b42q_MU), .aOut(xr42), .bOut(yr42));
    logic [63:0] xo42, xo42_x; assign xo42_x = (cb_sw[19][42] ? yr42 : xr42);
    (* max_fanout = 16 *) logic [63:0] b42q_QHALF;
    always_ff @(posedge clk) b42q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo42 <= DIR_r ? (64'(xo42_x >> 1) + (xo42_x[0] ? 64'(b42q_QHALF) : 64'd0)) : xo42_x;
    logic [63:0] yo42, yo42_x; assign yo42_x = (cb_sw[19][42] ? xr42 : yr42);
    always_ff @(posedge clk) yo42 <= DIR_r ? (64'(yo42_x >> 1) + (yo42_x[0] ? 64'(b42q_QHALF) : 64'd0)) : yo42_x;
    (* max_fanout = 16 *) logic [63:0] b43q_Q;
    always_ff @(posedge clk) b43q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b43q_MU;
    always_ff @(posedge clk) b43q_MU <= MU_r;
    logic [63:0] xr43; logic [63:0] yr43;
    Ie_n65536_q64b_B64_rns_bu u_bu43 (.clk(clk), .aIn(op86), .bIn(op87), .W(twr43_q), .Q(b43q_Q), .MU(b43q_MU), .aOut(xr43), .bOut(yr43));
    logic [63:0] xo43, xo43_x; assign xo43_x = (cb_sw[19][43] ? yr43 : xr43);
    (* max_fanout = 16 *) logic [63:0] b43q_QHALF;
    always_ff @(posedge clk) b43q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo43 <= DIR_r ? (64'(xo43_x >> 1) + (xo43_x[0] ? 64'(b43q_QHALF) : 64'd0)) : xo43_x;
    logic [63:0] yo43, yo43_x; assign yo43_x = (cb_sw[19][43] ? xr43 : yr43);
    always_ff @(posedge clk) yo43 <= DIR_r ? (64'(yo43_x >> 1) + (yo43_x[0] ? 64'(b43q_QHALF) : 64'd0)) : yo43_x;
    (* max_fanout = 16 *) logic [63:0] b44q_Q;
    always_ff @(posedge clk) b44q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b44q_MU;
    always_ff @(posedge clk) b44q_MU <= MU_r;
    logic [63:0] xr44; logic [63:0] yr44;
    Ie_n65536_q64b_B64_rns_bu u_bu44 (.clk(clk), .aIn(op88), .bIn(op89), .W(twr44_q), .Q(b44q_Q), .MU(b44q_MU), .aOut(xr44), .bOut(yr44));
    logic [63:0] xo44, xo44_x; assign xo44_x = (cb_sw[19][44] ? yr44 : xr44);
    (* max_fanout = 16 *) logic [63:0] b44q_QHALF;
    always_ff @(posedge clk) b44q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo44 <= DIR_r ? (64'(xo44_x >> 1) + (xo44_x[0] ? 64'(b44q_QHALF) : 64'd0)) : xo44_x;
    logic [63:0] yo44, yo44_x; assign yo44_x = (cb_sw[19][44] ? xr44 : yr44);
    always_ff @(posedge clk) yo44 <= DIR_r ? (64'(yo44_x >> 1) + (yo44_x[0] ? 64'(b44q_QHALF) : 64'd0)) : yo44_x;
    (* max_fanout = 16 *) logic [63:0] b45q_Q;
    always_ff @(posedge clk) b45q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b45q_MU;
    always_ff @(posedge clk) b45q_MU <= MU_r;
    logic [63:0] xr45; logic [63:0] yr45;
    Ie_n65536_q64b_B64_rns_bu u_bu45 (.clk(clk), .aIn(op90), .bIn(op91), .W(twr45_q), .Q(b45q_Q), .MU(b45q_MU), .aOut(xr45), .bOut(yr45));
    logic [63:0] xo45, xo45_x; assign xo45_x = (cb_sw[19][45] ? yr45 : xr45);
    (* max_fanout = 16 *) logic [63:0] b45q_QHALF;
    always_ff @(posedge clk) b45q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo45 <= DIR_r ? (64'(xo45_x >> 1) + (xo45_x[0] ? 64'(b45q_QHALF) : 64'd0)) : xo45_x;
    logic [63:0] yo45, yo45_x; assign yo45_x = (cb_sw[19][45] ? xr45 : yr45);
    always_ff @(posedge clk) yo45 <= DIR_r ? (64'(yo45_x >> 1) + (yo45_x[0] ? 64'(b45q_QHALF) : 64'd0)) : yo45_x;
    (* max_fanout = 16 *) logic [63:0] b46q_Q;
    always_ff @(posedge clk) b46q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b46q_MU;
    always_ff @(posedge clk) b46q_MU <= MU_r;
    logic [63:0] xr46; logic [63:0] yr46;
    Ie_n65536_q64b_B64_rns_bu u_bu46 (.clk(clk), .aIn(op92), .bIn(op93), .W(twr46_q), .Q(b46q_Q), .MU(b46q_MU), .aOut(xr46), .bOut(yr46));
    logic [63:0] xo46, xo46_x; assign xo46_x = (cb_sw[19][46] ? yr46 : xr46);
    (* max_fanout = 16 *) logic [63:0] b46q_QHALF;
    always_ff @(posedge clk) b46q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo46 <= DIR_r ? (64'(xo46_x >> 1) + (xo46_x[0] ? 64'(b46q_QHALF) : 64'd0)) : xo46_x;
    logic [63:0] yo46, yo46_x; assign yo46_x = (cb_sw[19][46] ? xr46 : yr46);
    always_ff @(posedge clk) yo46 <= DIR_r ? (64'(yo46_x >> 1) + (yo46_x[0] ? 64'(b46q_QHALF) : 64'd0)) : yo46_x;
    (* max_fanout = 16 *) logic [63:0] b47q_Q;
    always_ff @(posedge clk) b47q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b47q_MU;
    always_ff @(posedge clk) b47q_MU <= MU_r;
    logic [63:0] xr47; logic [63:0] yr47;
    Ie_n65536_q64b_B64_rns_bu u_bu47 (.clk(clk), .aIn(op94), .bIn(op95), .W(twr47_q), .Q(b47q_Q), .MU(b47q_MU), .aOut(xr47), .bOut(yr47));
    logic [63:0] xo47, xo47_x; assign xo47_x = (cb_sw[19][47] ? yr47 : xr47);
    (* max_fanout = 16 *) logic [63:0] b47q_QHALF;
    always_ff @(posedge clk) b47q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo47 <= DIR_r ? (64'(xo47_x >> 1) + (xo47_x[0] ? 64'(b47q_QHALF) : 64'd0)) : xo47_x;
    logic [63:0] yo47, yo47_x; assign yo47_x = (cb_sw[19][47] ? xr47 : yr47);
    always_ff @(posedge clk) yo47 <= DIR_r ? (64'(yo47_x >> 1) + (yo47_x[0] ? 64'(b47q_QHALF) : 64'd0)) : yo47_x;
    (* max_fanout = 16 *) logic [63:0] b48q_Q;
    always_ff @(posedge clk) b48q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b48q_MU;
    always_ff @(posedge clk) b48q_MU <= MU_r;
    logic [63:0] xr48; logic [63:0] yr48;
    Ie_n65536_q64b_B64_rns_bu u_bu48 (.clk(clk), .aIn(op96), .bIn(op97), .W(twr48_q), .Q(b48q_Q), .MU(b48q_MU), .aOut(xr48), .bOut(yr48));
    logic [63:0] xo48, xo48_x; assign xo48_x = (cb_sw[19][48] ? yr48 : xr48);
    (* max_fanout = 16 *) logic [63:0] b48q_QHALF;
    always_ff @(posedge clk) b48q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo48 <= DIR_r ? (64'(xo48_x >> 1) + (xo48_x[0] ? 64'(b48q_QHALF) : 64'd0)) : xo48_x;
    logic [63:0] yo48, yo48_x; assign yo48_x = (cb_sw[19][48] ? xr48 : yr48);
    always_ff @(posedge clk) yo48 <= DIR_r ? (64'(yo48_x >> 1) + (yo48_x[0] ? 64'(b48q_QHALF) : 64'd0)) : yo48_x;
    (* max_fanout = 16 *) logic [63:0] b49q_Q;
    always_ff @(posedge clk) b49q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b49q_MU;
    always_ff @(posedge clk) b49q_MU <= MU_r;
    logic [63:0] xr49; logic [63:0] yr49;
    Ie_n65536_q64b_B64_rns_bu u_bu49 (.clk(clk), .aIn(op98), .bIn(op99), .W(twr49_q), .Q(b49q_Q), .MU(b49q_MU), .aOut(xr49), .bOut(yr49));
    logic [63:0] xo49, xo49_x; assign xo49_x = (cb_sw[19][49] ? yr49 : xr49);
    (* max_fanout = 16 *) logic [63:0] b49q_QHALF;
    always_ff @(posedge clk) b49q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo49 <= DIR_r ? (64'(xo49_x >> 1) + (xo49_x[0] ? 64'(b49q_QHALF) : 64'd0)) : xo49_x;
    logic [63:0] yo49, yo49_x; assign yo49_x = (cb_sw[19][49] ? xr49 : yr49);
    always_ff @(posedge clk) yo49 <= DIR_r ? (64'(yo49_x >> 1) + (yo49_x[0] ? 64'(b49q_QHALF) : 64'd0)) : yo49_x;
    (* max_fanout = 16 *) logic [63:0] b50q_Q;
    always_ff @(posedge clk) b50q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b50q_MU;
    always_ff @(posedge clk) b50q_MU <= MU_r;
    logic [63:0] xr50; logic [63:0] yr50;
    Ie_n65536_q64b_B64_rns_bu u_bu50 (.clk(clk), .aIn(op100), .bIn(op101), .W(twr50_q), .Q(b50q_Q), .MU(b50q_MU), .aOut(xr50), .bOut(yr50));
    logic [63:0] xo50, xo50_x; assign xo50_x = (cb_sw[19][50] ? yr50 : xr50);
    (* max_fanout = 16 *) logic [63:0] b50q_QHALF;
    always_ff @(posedge clk) b50q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo50 <= DIR_r ? (64'(xo50_x >> 1) + (xo50_x[0] ? 64'(b50q_QHALF) : 64'd0)) : xo50_x;
    logic [63:0] yo50, yo50_x; assign yo50_x = (cb_sw[19][50] ? xr50 : yr50);
    always_ff @(posedge clk) yo50 <= DIR_r ? (64'(yo50_x >> 1) + (yo50_x[0] ? 64'(b50q_QHALF) : 64'd0)) : yo50_x;
    (* max_fanout = 16 *) logic [63:0] b51q_Q;
    always_ff @(posedge clk) b51q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b51q_MU;
    always_ff @(posedge clk) b51q_MU <= MU_r;
    logic [63:0] xr51; logic [63:0] yr51;
    Ie_n65536_q64b_B64_rns_bu u_bu51 (.clk(clk), .aIn(op102), .bIn(op103), .W(twr51_q), .Q(b51q_Q), .MU(b51q_MU), .aOut(xr51), .bOut(yr51));
    logic [63:0] xo51, xo51_x; assign xo51_x = (cb_sw[19][51] ? yr51 : xr51);
    (* max_fanout = 16 *) logic [63:0] b51q_QHALF;
    always_ff @(posedge clk) b51q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo51 <= DIR_r ? (64'(xo51_x >> 1) + (xo51_x[0] ? 64'(b51q_QHALF) : 64'd0)) : xo51_x;
    logic [63:0] yo51, yo51_x; assign yo51_x = (cb_sw[19][51] ? xr51 : yr51);
    always_ff @(posedge clk) yo51 <= DIR_r ? (64'(yo51_x >> 1) + (yo51_x[0] ? 64'(b51q_QHALF) : 64'd0)) : yo51_x;
    (* max_fanout = 16 *) logic [63:0] b52q_Q;
    always_ff @(posedge clk) b52q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b52q_MU;
    always_ff @(posedge clk) b52q_MU <= MU_r;
    logic [63:0] xr52; logic [63:0] yr52;
    Ie_n65536_q64b_B64_rns_bu u_bu52 (.clk(clk), .aIn(op104), .bIn(op105), .W(twr52_q), .Q(b52q_Q), .MU(b52q_MU), .aOut(xr52), .bOut(yr52));
    logic [63:0] xo52, xo52_x; assign xo52_x = (cb_sw[19][52] ? yr52 : xr52);
    (* max_fanout = 16 *) logic [63:0] b52q_QHALF;
    always_ff @(posedge clk) b52q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo52 <= DIR_r ? (64'(xo52_x >> 1) + (xo52_x[0] ? 64'(b52q_QHALF) : 64'd0)) : xo52_x;
    logic [63:0] yo52, yo52_x; assign yo52_x = (cb_sw[19][52] ? xr52 : yr52);
    always_ff @(posedge clk) yo52 <= DIR_r ? (64'(yo52_x >> 1) + (yo52_x[0] ? 64'(b52q_QHALF) : 64'd0)) : yo52_x;
    (* max_fanout = 16 *) logic [63:0] b53q_Q;
    always_ff @(posedge clk) b53q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b53q_MU;
    always_ff @(posedge clk) b53q_MU <= MU_r;
    logic [63:0] xr53; logic [63:0] yr53;
    Ie_n65536_q64b_B64_rns_bu u_bu53 (.clk(clk), .aIn(op106), .bIn(op107), .W(twr53_q), .Q(b53q_Q), .MU(b53q_MU), .aOut(xr53), .bOut(yr53));
    logic [63:0] xo53, xo53_x; assign xo53_x = (cb_sw[19][53] ? yr53 : xr53);
    (* max_fanout = 16 *) logic [63:0] b53q_QHALF;
    always_ff @(posedge clk) b53q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo53 <= DIR_r ? (64'(xo53_x >> 1) + (xo53_x[0] ? 64'(b53q_QHALF) : 64'd0)) : xo53_x;
    logic [63:0] yo53, yo53_x; assign yo53_x = (cb_sw[19][53] ? xr53 : yr53);
    always_ff @(posedge clk) yo53 <= DIR_r ? (64'(yo53_x >> 1) + (yo53_x[0] ? 64'(b53q_QHALF) : 64'd0)) : yo53_x;
    (* max_fanout = 16 *) logic [63:0] b54q_Q;
    always_ff @(posedge clk) b54q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b54q_MU;
    always_ff @(posedge clk) b54q_MU <= MU_r;
    logic [63:0] xr54; logic [63:0] yr54;
    Ie_n65536_q64b_B64_rns_bu u_bu54 (.clk(clk), .aIn(op108), .bIn(op109), .W(twr54_q), .Q(b54q_Q), .MU(b54q_MU), .aOut(xr54), .bOut(yr54));
    logic [63:0] xo54, xo54_x; assign xo54_x = (cb_sw[19][54] ? yr54 : xr54);
    (* max_fanout = 16 *) logic [63:0] b54q_QHALF;
    always_ff @(posedge clk) b54q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo54 <= DIR_r ? (64'(xo54_x >> 1) + (xo54_x[0] ? 64'(b54q_QHALF) : 64'd0)) : xo54_x;
    logic [63:0] yo54, yo54_x; assign yo54_x = (cb_sw[19][54] ? xr54 : yr54);
    always_ff @(posedge clk) yo54 <= DIR_r ? (64'(yo54_x >> 1) + (yo54_x[0] ? 64'(b54q_QHALF) : 64'd0)) : yo54_x;
    (* max_fanout = 16 *) logic [63:0] b55q_Q;
    always_ff @(posedge clk) b55q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b55q_MU;
    always_ff @(posedge clk) b55q_MU <= MU_r;
    logic [63:0] xr55; logic [63:0] yr55;
    Ie_n65536_q64b_B64_rns_bu u_bu55 (.clk(clk), .aIn(op110), .bIn(op111), .W(twr55_q), .Q(b55q_Q), .MU(b55q_MU), .aOut(xr55), .bOut(yr55));
    logic [63:0] xo55, xo55_x; assign xo55_x = (cb_sw[19][55] ? yr55 : xr55);
    (* max_fanout = 16 *) logic [63:0] b55q_QHALF;
    always_ff @(posedge clk) b55q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo55 <= DIR_r ? (64'(xo55_x >> 1) + (xo55_x[0] ? 64'(b55q_QHALF) : 64'd0)) : xo55_x;
    logic [63:0] yo55, yo55_x; assign yo55_x = (cb_sw[19][55] ? xr55 : yr55);
    always_ff @(posedge clk) yo55 <= DIR_r ? (64'(yo55_x >> 1) + (yo55_x[0] ? 64'(b55q_QHALF) : 64'd0)) : yo55_x;
    (* max_fanout = 16 *) logic [63:0] b56q_Q;
    always_ff @(posedge clk) b56q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b56q_MU;
    always_ff @(posedge clk) b56q_MU <= MU_r;
    logic [63:0] xr56; logic [63:0] yr56;
    Ie_n65536_q64b_B64_rns_bu u_bu56 (.clk(clk), .aIn(op112), .bIn(op113), .W(twr56_q), .Q(b56q_Q), .MU(b56q_MU), .aOut(xr56), .bOut(yr56));
    logic [63:0] xo56, xo56_x; assign xo56_x = (cb_sw[19][56] ? yr56 : xr56);
    (* max_fanout = 16 *) logic [63:0] b56q_QHALF;
    always_ff @(posedge clk) b56q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo56 <= DIR_r ? (64'(xo56_x >> 1) + (xo56_x[0] ? 64'(b56q_QHALF) : 64'd0)) : xo56_x;
    logic [63:0] yo56, yo56_x; assign yo56_x = (cb_sw[19][56] ? xr56 : yr56);
    always_ff @(posedge clk) yo56 <= DIR_r ? (64'(yo56_x >> 1) + (yo56_x[0] ? 64'(b56q_QHALF) : 64'd0)) : yo56_x;
    (* max_fanout = 16 *) logic [63:0] b57q_Q;
    always_ff @(posedge clk) b57q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b57q_MU;
    always_ff @(posedge clk) b57q_MU <= MU_r;
    logic [63:0] xr57; logic [63:0] yr57;
    Ie_n65536_q64b_B64_rns_bu u_bu57 (.clk(clk), .aIn(op114), .bIn(op115), .W(twr57_q), .Q(b57q_Q), .MU(b57q_MU), .aOut(xr57), .bOut(yr57));
    logic [63:0] xo57, xo57_x; assign xo57_x = (cb_sw[19][57] ? yr57 : xr57);
    (* max_fanout = 16 *) logic [63:0] b57q_QHALF;
    always_ff @(posedge clk) b57q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo57 <= DIR_r ? (64'(xo57_x >> 1) + (xo57_x[0] ? 64'(b57q_QHALF) : 64'd0)) : xo57_x;
    logic [63:0] yo57, yo57_x; assign yo57_x = (cb_sw[19][57] ? xr57 : yr57);
    always_ff @(posedge clk) yo57 <= DIR_r ? (64'(yo57_x >> 1) + (yo57_x[0] ? 64'(b57q_QHALF) : 64'd0)) : yo57_x;
    (* max_fanout = 16 *) logic [63:0] b58q_Q;
    always_ff @(posedge clk) b58q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b58q_MU;
    always_ff @(posedge clk) b58q_MU <= MU_r;
    logic [63:0] xr58; logic [63:0] yr58;
    Ie_n65536_q64b_B64_rns_bu u_bu58 (.clk(clk), .aIn(op116), .bIn(op117), .W(twr58_q), .Q(b58q_Q), .MU(b58q_MU), .aOut(xr58), .bOut(yr58));
    logic [63:0] xo58, xo58_x; assign xo58_x = (cb_sw[19][58] ? yr58 : xr58);
    (* max_fanout = 16 *) logic [63:0] b58q_QHALF;
    always_ff @(posedge clk) b58q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo58 <= DIR_r ? (64'(xo58_x >> 1) + (xo58_x[0] ? 64'(b58q_QHALF) : 64'd0)) : xo58_x;
    logic [63:0] yo58, yo58_x; assign yo58_x = (cb_sw[19][58] ? xr58 : yr58);
    always_ff @(posedge clk) yo58 <= DIR_r ? (64'(yo58_x >> 1) + (yo58_x[0] ? 64'(b58q_QHALF) : 64'd0)) : yo58_x;
    (* max_fanout = 16 *) logic [63:0] b59q_Q;
    always_ff @(posedge clk) b59q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b59q_MU;
    always_ff @(posedge clk) b59q_MU <= MU_r;
    logic [63:0] xr59; logic [63:0] yr59;
    Ie_n65536_q64b_B64_rns_bu u_bu59 (.clk(clk), .aIn(op118), .bIn(op119), .W(twr59_q), .Q(b59q_Q), .MU(b59q_MU), .aOut(xr59), .bOut(yr59));
    logic [63:0] xo59, xo59_x; assign xo59_x = (cb_sw[19][59] ? yr59 : xr59);
    (* max_fanout = 16 *) logic [63:0] b59q_QHALF;
    always_ff @(posedge clk) b59q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo59 <= DIR_r ? (64'(xo59_x >> 1) + (xo59_x[0] ? 64'(b59q_QHALF) : 64'd0)) : xo59_x;
    logic [63:0] yo59, yo59_x; assign yo59_x = (cb_sw[19][59] ? xr59 : yr59);
    always_ff @(posedge clk) yo59 <= DIR_r ? (64'(yo59_x >> 1) + (yo59_x[0] ? 64'(b59q_QHALF) : 64'd0)) : yo59_x;
    (* max_fanout = 16 *) logic [63:0] b60q_Q;
    always_ff @(posedge clk) b60q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b60q_MU;
    always_ff @(posedge clk) b60q_MU <= MU_r;
    logic [63:0] xr60; logic [63:0] yr60;
    Ie_n65536_q64b_B64_rns_bu u_bu60 (.clk(clk), .aIn(op120), .bIn(op121), .W(twr60_q), .Q(b60q_Q), .MU(b60q_MU), .aOut(xr60), .bOut(yr60));
    logic [63:0] xo60, xo60_x; assign xo60_x = (cb_sw[19][60] ? yr60 : xr60);
    (* max_fanout = 16 *) logic [63:0] b60q_QHALF;
    always_ff @(posedge clk) b60q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo60 <= DIR_r ? (64'(xo60_x >> 1) + (xo60_x[0] ? 64'(b60q_QHALF) : 64'd0)) : xo60_x;
    logic [63:0] yo60, yo60_x; assign yo60_x = (cb_sw[19][60] ? xr60 : yr60);
    always_ff @(posedge clk) yo60 <= DIR_r ? (64'(yo60_x >> 1) + (yo60_x[0] ? 64'(b60q_QHALF) : 64'd0)) : yo60_x;
    (* max_fanout = 16 *) logic [63:0] b61q_Q;
    always_ff @(posedge clk) b61q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b61q_MU;
    always_ff @(posedge clk) b61q_MU <= MU_r;
    logic [63:0] xr61; logic [63:0] yr61;
    Ie_n65536_q64b_B64_rns_bu u_bu61 (.clk(clk), .aIn(op122), .bIn(op123), .W(twr61_q), .Q(b61q_Q), .MU(b61q_MU), .aOut(xr61), .bOut(yr61));
    logic [63:0] xo61, xo61_x; assign xo61_x = (cb_sw[19][61] ? yr61 : xr61);
    (* max_fanout = 16 *) logic [63:0] b61q_QHALF;
    always_ff @(posedge clk) b61q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo61 <= DIR_r ? (64'(xo61_x >> 1) + (xo61_x[0] ? 64'(b61q_QHALF) : 64'd0)) : xo61_x;
    logic [63:0] yo61, yo61_x; assign yo61_x = (cb_sw[19][61] ? xr61 : yr61);
    always_ff @(posedge clk) yo61 <= DIR_r ? (64'(yo61_x >> 1) + (yo61_x[0] ? 64'(b61q_QHALF) : 64'd0)) : yo61_x;
    (* max_fanout = 16 *) logic [63:0] b62q_Q;
    always_ff @(posedge clk) b62q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b62q_MU;
    always_ff @(posedge clk) b62q_MU <= MU_r;
    logic [63:0] xr62; logic [63:0] yr62;
    Ie_n65536_q64b_B64_rns_bu u_bu62 (.clk(clk), .aIn(op124), .bIn(op125), .W(twr62_q), .Q(b62q_Q), .MU(b62q_MU), .aOut(xr62), .bOut(yr62));
    logic [63:0] xo62, xo62_x; assign xo62_x = (cb_sw[19][62] ? yr62 : xr62);
    (* max_fanout = 16 *) logic [63:0] b62q_QHALF;
    always_ff @(posedge clk) b62q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo62 <= DIR_r ? (64'(xo62_x >> 1) + (xo62_x[0] ? 64'(b62q_QHALF) : 64'd0)) : xo62_x;
    logic [63:0] yo62, yo62_x; assign yo62_x = (cb_sw[19][62] ? xr62 : yr62);
    always_ff @(posedge clk) yo62 <= DIR_r ? (64'(yo62_x >> 1) + (yo62_x[0] ? 64'(b62q_QHALF) : 64'd0)) : yo62_x;
    (* max_fanout = 16 *) logic [63:0] b63q_Q;
    always_ff @(posedge clk) b63q_Q <= Q_r;
    (* max_fanout = 16 *) logic [65:0] b63q_MU;
    always_ff @(posedge clk) b63q_MU <= MU_r;
    logic [63:0] xr63; logic [63:0] yr63;
    Ie_n65536_q64b_B64_rns_bu u_bu63 (.clk(clk), .aIn(op126), .bIn(op127), .W(twr63_q), .Q(b63q_Q), .MU(b63q_MU), .aOut(xr63), .bOut(yr63));
    logic [63:0] xo63, xo63_x; assign xo63_x = (cb_sw[19][63] ? yr63 : xr63);
    (* max_fanout = 16 *) logic [63:0] b63q_QHALF;
    always_ff @(posedge clk) b63q_QHALF <= QHALF_r;
    always_ff @(posedge clk) xo63 <= DIR_r ? (64'(xo63_x >> 1) + (xo63_x[0] ? 64'(b63q_QHALF) : 64'd0)) : xo63_x;
    logic [63:0] yo63, yo63_x; assign yo63_x = (cb_sw[19][63] ? xr63 : yr63);
    always_ff @(posedge clk) yo63 <= DIR_r ? (64'(yo63_x >> 1) + (yo63_x[0] ? 64'(b63q_QHALF) : 64'd0)) : yo63_x;
    // ---- write back in place (sources per bank: IterativeNTTScheme.readSources), or the fill
    logic [63:0] wdat0;
    always_comb case (wc0)
        2'd0: wdat0 = xo0;
        2'd1: wdat0 = yo0;
        2'd2: wdat0 = xo32;
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
    logic [63:0] wdat1;
    always_comb case (wc1)
        3'd0: wdat1 = yo0;
        3'd1: wdat1 = xo1;
        3'd2: wdat1 = yo1;
        3'd3: wdat1 = yo32;
        3'd4: wdat1 = xo33;
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
    logic [63:0] wdat2;
    always_comb case (wc2)
        3'd0: wdat2 = yo0;
        3'd1: wdat2 = xo1;
        3'd2: wdat2 = xo2;
        3'd3: wdat2 = yo2;
        3'd4: wdat2 = yo32;
        3'd5: wdat2 = xo33;
        3'd6: wdat2 = xo34;
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
    logic [63:0] wdat3;
    always_comb case (wc3)
        3'd0: wdat3 = yo1;
        3'd1: wdat3 = xo3;
        3'd2: wdat3 = yo3;
        3'd3: wdat3 = yo33;
        3'd4: wdat3 = xo35;
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
    logic [63:0] wdat4;
    always_comb case (wc4)
        3'd0: wdat4 = yo0;
        3'd1: wdat4 = xo2;
        3'd2: wdat4 = xo4;
        3'd3: wdat4 = yo4;
        3'd4: wdat4 = yo32;
        3'd5: wdat4 = xo34;
        3'd6: wdat4 = xo36;
        default: wdat4 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_4_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_4_we <= 1'b1; m0_4_wa <= (w_f ? w_hB : w_hA); m0_4_wd <= wdat4; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd8) : (fsub == 4'd0))) begin m0_4_we <= 1'b1; m0_4_wa <= frow; m0_4_wd <= x_in_4; end
        else m0_4_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_4_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_4_we <= 1'b1; m1_4_wa <= (w_f ? w_hB : w_hA); m1_4_wd <= wdat4; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd8) : (fsub == 4'd0))) begin m1_4_we <= 1'b1; m1_4_wa <= frow; m1_4_wd <= x_in_4; end
        else m1_4_we <= 1'b0;
    end
    logic [63:0] wdat5;
    always_comb case (wc5)
        4'd0: wdat5 = yo1;
        4'd1: wdat5 = yo2;
        4'd2: wdat5 = xo3;
        4'd3: wdat5 = xo5;
        4'd4: wdat5 = yo5;
        4'd5: wdat5 = yo33;
        4'd6: wdat5 = yo34;
        4'd7: wdat5 = xo35;
        4'd8: wdat5 = xo37;
        default: wdat5 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_5_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_5_we <= 1'b1; m0_5_wa <= (w_f ? w_hB : w_hA); m0_5_wd <= wdat5; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd8) : (fsub == 4'd0))) begin m0_5_we <= 1'b1; m0_5_wa <= frow; m0_5_wd <= x_in_5; end
        else m0_5_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_5_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_5_we <= 1'b1; m1_5_wa <= (w_f ? w_hB : w_hA); m1_5_wd <= wdat5; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd8) : (fsub == 4'd0))) begin m1_5_we <= 1'b1; m1_5_wa <= frow; m1_5_wd <= x_in_5; end
        else m1_5_we <= 1'b0;
    end
    logic [63:0] wdat6;
    always_comb case (wc6)
        3'd0: wdat6 = yo2;
        3'd1: wdat6 = xo3;
        3'd2: wdat6 = xo6;
        3'd3: wdat6 = yo6;
        3'd4: wdat6 = yo34;
        3'd5: wdat6 = xo35;
        3'd6: wdat6 = xo38;
        default: wdat6 = yo2;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_6_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_6_we <= 1'b1; m0_6_wa <= (w_f ? w_hB : w_hA); m0_6_wd <= wdat6; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd8) : (fsub == 4'd0))) begin m0_6_we <= 1'b1; m0_6_wa <= frow; m0_6_wd <= x_in_6; end
        else m0_6_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_6_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_6_we <= 1'b1; m1_6_wa <= (w_f ? w_hB : w_hA); m1_6_wd <= wdat6; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd8) : (fsub == 4'd0))) begin m1_6_we <= 1'b1; m1_6_wa <= frow; m1_6_wd <= x_in_6; end
        else m1_6_we <= 1'b0;
    end
    logic [63:0] wdat7;
    always_comb case (wc7)
        3'd0: wdat7 = yo3;
        3'd1: wdat7 = xo7;
        3'd2: wdat7 = yo7;
        3'd3: wdat7 = yo35;
        3'd4: wdat7 = xo39;
        default: wdat7 = yo3;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_7_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_7_we <= 1'b1; m0_7_wa <= (w_f ? w_hB : w_hA); m0_7_wd <= wdat7; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd8) : (fsub == 4'd0))) begin m0_7_we <= 1'b1; m0_7_wa <= frow; m0_7_wd <= x_in_7; end
        else m0_7_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_7_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_7_we <= 1'b1; m1_7_wa <= (w_f ? w_hB : w_hA); m1_7_wd <= wdat7; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd8) : (fsub == 4'd0))) begin m1_7_we <= 1'b1; m1_7_wa <= frow; m1_7_wd <= x_in_7; end
        else m1_7_we <= 1'b0;
    end
    logic [63:0] wdat8;
    always_comb case (wc8)
        3'd0: wdat8 = yo0;
        3'd1: wdat8 = xo4;
        3'd2: wdat8 = xo8;
        3'd3: wdat8 = yo8;
        3'd4: wdat8 = yo32;
        3'd5: wdat8 = xo36;
        3'd6: wdat8 = xo40;
        default: wdat8 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_8_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_8_we <= 1'b1; m0_8_wa <= (w_f ? w_hB : w_hA); m0_8_wd <= wdat8; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m0_8_we <= 1'b1; m0_8_wa <= frow; m0_8_wd <= x_in_0; end
        else m0_8_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_8_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_8_we <= 1'b1; m1_8_wa <= (w_f ? w_hB : w_hA); m1_8_wd <= wdat8; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m1_8_we <= 1'b1; m1_8_wa <= frow; m1_8_wd <= x_in_0; end
        else m1_8_we <= 1'b0;
    end
    logic [63:0] wdat9;
    always_comb case (wc9)
        4'd0: wdat9 = yo1;
        4'd1: wdat9 = yo4;
        4'd2: wdat9 = xo5;
        4'd3: wdat9 = xo9;
        4'd4: wdat9 = yo9;
        4'd5: wdat9 = yo33;
        4'd6: wdat9 = yo36;
        4'd7: wdat9 = xo37;
        4'd8: wdat9 = xo41;
        default: wdat9 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_9_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_9_we <= 1'b1; m0_9_wa <= (w_f ? w_hB : w_hA); m0_9_wd <= wdat9; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m0_9_we <= 1'b1; m0_9_wa <= frow; m0_9_wd <= x_in_1; end
        else m0_9_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_9_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_9_we <= 1'b1; m1_9_wa <= (w_f ? w_hB : w_hA); m1_9_wd <= wdat9; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m1_9_we <= 1'b1; m1_9_wa <= frow; m1_9_wd <= x_in_1; end
        else m1_9_we <= 1'b0;
    end
    logic [63:0] wdat10;
    always_comb case (wc10)
        4'd0: wdat10 = yo2;
        4'd1: wdat10 = yo4;
        4'd2: wdat10 = xo5;
        4'd3: wdat10 = xo6;
        4'd4: wdat10 = xo10;
        4'd5: wdat10 = yo10;
        4'd6: wdat10 = yo34;
        4'd7: wdat10 = yo36;
        4'd8: wdat10 = xo37;
        4'd9: wdat10 = xo38;
        4'd10: wdat10 = xo42;
        default: wdat10 = yo2;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_10_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_10_we <= 1'b1; m0_10_wa <= (w_f ? w_hB : w_hA); m0_10_wd <= wdat10; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m0_10_we <= 1'b1; m0_10_wa <= frow; m0_10_wd <= x_in_2; end
        else m0_10_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_10_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_10_we <= 1'b1; m1_10_wa <= (w_f ? w_hB : w_hA); m1_10_wd <= wdat10; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m1_10_we <= 1'b1; m1_10_wa <= frow; m1_10_wd <= x_in_2; end
        else m1_10_we <= 1'b0;
    end
    logic [63:0] wdat11;
    always_comb case (wc11)
        4'd0: wdat11 = yo3;
        4'd1: wdat11 = yo5;
        4'd2: wdat11 = xo7;
        4'd3: wdat11 = xo11;
        4'd4: wdat11 = yo11;
        4'd5: wdat11 = yo35;
        4'd6: wdat11 = yo37;
        4'd7: wdat11 = xo39;
        4'd8: wdat11 = xo43;
        default: wdat11 = yo3;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_11_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_11_we <= 1'b1; m0_11_wa <= (w_f ? w_hB : w_hA); m0_11_wd <= wdat11; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m0_11_we <= 1'b1; m0_11_wa <= frow; m0_11_wd <= x_in_3; end
        else m0_11_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_11_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_11_we <= 1'b1; m1_11_wa <= (w_f ? w_hB : w_hA); m1_11_wd <= wdat11; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m1_11_we <= 1'b1; m1_11_wa <= frow; m1_11_wd <= x_in_3; end
        else m1_11_we <= 1'b0;
    end
    logic [63:0] wdat12;
    always_comb case (wc12)
        3'd0: wdat12 = yo4;
        3'd1: wdat12 = xo6;
        3'd2: wdat12 = xo12;
        3'd3: wdat12 = yo12;
        3'd4: wdat12 = yo36;
        3'd5: wdat12 = xo38;
        3'd6: wdat12 = xo44;
        default: wdat12 = yo4;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_12_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_12_we <= 1'b1; m0_12_wa <= (w_f ? w_hB : w_hA); m0_12_wd <= wdat12; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m0_12_we <= 1'b1; m0_12_wa <= frow; m0_12_wd <= x_in_4; end
        else m0_12_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_12_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_12_we <= 1'b1; m1_12_wa <= (w_f ? w_hB : w_hA); m1_12_wd <= wdat12; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m1_12_we <= 1'b1; m1_12_wa <= frow; m1_12_wd <= x_in_4; end
        else m1_12_we <= 1'b0;
    end
    logic [63:0] wdat13;
    always_comb case (wc13)
        4'd0: wdat13 = yo5;
        4'd1: wdat13 = yo6;
        4'd2: wdat13 = xo7;
        4'd3: wdat13 = xo13;
        4'd4: wdat13 = yo13;
        4'd5: wdat13 = yo37;
        4'd6: wdat13 = yo38;
        4'd7: wdat13 = xo39;
        4'd8: wdat13 = xo45;
        default: wdat13 = yo5;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_13_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_13_we <= 1'b1; m0_13_wa <= (w_f ? w_hB : w_hA); m0_13_wd <= wdat13; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m0_13_we <= 1'b1; m0_13_wa <= frow; m0_13_wd <= x_in_5; end
        else m0_13_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_13_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_13_we <= 1'b1; m1_13_wa <= (w_f ? w_hB : w_hA); m1_13_wd <= wdat13; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m1_13_we <= 1'b1; m1_13_wa <= frow; m1_13_wd <= x_in_5; end
        else m1_13_we <= 1'b0;
    end
    logic [63:0] wdat14;
    always_comb case (wc14)
        3'd0: wdat14 = yo6;
        3'd1: wdat14 = xo7;
        3'd2: wdat14 = xo14;
        3'd3: wdat14 = yo14;
        3'd4: wdat14 = yo38;
        3'd5: wdat14 = xo39;
        3'd6: wdat14 = xo46;
        default: wdat14 = yo6;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_14_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_14_we <= 1'b1; m0_14_wa <= (w_f ? w_hB : w_hA); m0_14_wd <= wdat14; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m0_14_we <= 1'b1; m0_14_wa <= frow; m0_14_wd <= x_in_6; end
        else m0_14_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_14_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_14_we <= 1'b1; m1_14_wa <= (w_f ? w_hB : w_hA); m1_14_wd <= wdat14; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m1_14_we <= 1'b1; m1_14_wa <= frow; m1_14_wd <= x_in_6; end
        else m1_14_we <= 1'b0;
    end
    logic [63:0] wdat15;
    always_comb case (wc15)
        3'd0: wdat15 = yo7;
        3'd1: wdat15 = xo15;
        3'd2: wdat15 = yo15;
        3'd3: wdat15 = yo39;
        3'd4: wdat15 = xo47;
        default: wdat15 = yo7;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_15_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_15_we <= 1'b1; m0_15_wa <= (w_f ? w_hB : w_hA); m0_15_wd <= wdat15; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m0_15_we <= 1'b1; m0_15_wa <= frow; m0_15_wd <= x_in_7; end
        else m0_15_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_15_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_15_we <= 1'b1; m1_15_wa <= (w_f ? w_hB : w_hA); m1_15_wd <= wdat15; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd9) : (fsub == 4'd1))) begin m1_15_we <= 1'b1; m1_15_wa <= frow; m1_15_wd <= x_in_7; end
        else m1_15_we <= 1'b0;
    end
    logic [63:0] wdat16;
    always_comb case (wc16)
        3'd0: wdat16 = yo0;
        3'd1: wdat16 = xo8;
        3'd2: wdat16 = xo16;
        3'd3: wdat16 = yo16;
        3'd4: wdat16 = yo32;
        3'd5: wdat16 = xo40;
        3'd6: wdat16 = xo48;
        default: wdat16 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_16_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_16_we <= 1'b1; m0_16_wa <= (w_f ? w_hB : w_hA); m0_16_wd <= wdat16; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m0_16_we <= 1'b1; m0_16_wa <= frow; m0_16_wd <= x_in_0; end
        else m0_16_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_16_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_16_we <= 1'b1; m1_16_wa <= (w_f ? w_hB : w_hA); m1_16_wd <= wdat16; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m1_16_we <= 1'b1; m1_16_wa <= frow; m1_16_wd <= x_in_0; end
        else m1_16_we <= 1'b0;
    end
    logic [63:0] wdat17;
    always_comb case (wc17)
        4'd0: wdat17 = yo1;
        4'd1: wdat17 = yo8;
        4'd2: wdat17 = xo9;
        4'd3: wdat17 = xo17;
        4'd4: wdat17 = yo17;
        4'd5: wdat17 = yo33;
        4'd6: wdat17 = yo40;
        4'd7: wdat17 = xo41;
        4'd8: wdat17 = xo49;
        default: wdat17 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_17_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_17_we <= 1'b1; m0_17_wa <= (w_f ? w_hB : w_hA); m0_17_wd <= wdat17; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m0_17_we <= 1'b1; m0_17_wa <= frow; m0_17_wd <= x_in_1; end
        else m0_17_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_17_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_17_we <= 1'b1; m1_17_wa <= (w_f ? w_hB : w_hA); m1_17_wd <= wdat17; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m1_17_we <= 1'b1; m1_17_wa <= frow; m1_17_wd <= x_in_1; end
        else m1_17_we <= 1'b0;
    end
    logic [63:0] wdat18;
    always_comb case (wc18)
        4'd0: wdat18 = yo2;
        4'd1: wdat18 = yo8;
        4'd2: wdat18 = xo9;
        4'd3: wdat18 = xo10;
        4'd4: wdat18 = xo18;
        4'd5: wdat18 = yo18;
        4'd6: wdat18 = yo34;
        4'd7: wdat18 = yo40;
        4'd8: wdat18 = xo41;
        4'd9: wdat18 = xo42;
        4'd10: wdat18 = xo50;
        default: wdat18 = yo2;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_18_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_18_we <= 1'b1; m0_18_wa <= (w_f ? w_hB : w_hA); m0_18_wd <= wdat18; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m0_18_we <= 1'b1; m0_18_wa <= frow; m0_18_wd <= x_in_2; end
        else m0_18_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_18_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_18_we <= 1'b1; m1_18_wa <= (w_f ? w_hB : w_hA); m1_18_wd <= wdat18; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m1_18_we <= 1'b1; m1_18_wa <= frow; m1_18_wd <= x_in_2; end
        else m1_18_we <= 1'b0;
    end
    logic [63:0] wdat19;
    always_comb case (wc19)
        4'd0: wdat19 = yo3;
        4'd1: wdat19 = yo9;
        4'd2: wdat19 = xo11;
        4'd3: wdat19 = xo19;
        4'd4: wdat19 = yo19;
        4'd5: wdat19 = yo35;
        4'd6: wdat19 = yo41;
        4'd7: wdat19 = xo43;
        4'd8: wdat19 = xo51;
        default: wdat19 = yo3;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_19_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_19_we <= 1'b1; m0_19_wa <= (w_f ? w_hB : w_hA); m0_19_wd <= wdat19; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m0_19_we <= 1'b1; m0_19_wa <= frow; m0_19_wd <= x_in_3; end
        else m0_19_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_19_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_19_we <= 1'b1; m1_19_wa <= (w_f ? w_hB : w_hA); m1_19_wd <= wdat19; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m1_19_we <= 1'b1; m1_19_wa <= frow; m1_19_wd <= x_in_3; end
        else m1_19_we <= 1'b0;
    end
    logic [63:0] wdat20;
    always_comb case (wc20)
        4'd0: wdat20 = yo4;
        4'd1: wdat20 = yo8;
        4'd2: wdat20 = xo10;
        4'd3: wdat20 = xo12;
        4'd4: wdat20 = xo20;
        4'd5: wdat20 = yo20;
        4'd6: wdat20 = yo36;
        4'd7: wdat20 = yo40;
        4'd8: wdat20 = xo42;
        4'd9: wdat20 = xo44;
        4'd10: wdat20 = xo52;
        default: wdat20 = yo4;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_20_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_20_we <= 1'b1; m0_20_wa <= (w_f ? w_hB : w_hA); m0_20_wd <= wdat20; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m0_20_we <= 1'b1; m0_20_wa <= frow; m0_20_wd <= x_in_4; end
        else m0_20_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_20_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_20_we <= 1'b1; m1_20_wa <= (w_f ? w_hB : w_hA); m1_20_wd <= wdat20; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m1_20_we <= 1'b1; m1_20_wa <= frow; m1_20_wd <= x_in_4; end
        else m1_20_we <= 1'b0;
    end
    logic [63:0] wdat21;
    always_comb case (wc21)
        4'd0: wdat21 = yo5;
        4'd1: wdat21 = yo9;
        4'd2: wdat21 = yo10;
        4'd3: wdat21 = xo11;
        4'd4: wdat21 = xo13;
        4'd5: wdat21 = xo21;
        4'd6: wdat21 = yo21;
        4'd7: wdat21 = yo37;
        4'd8: wdat21 = yo41;
        4'd9: wdat21 = yo42;
        4'd10: wdat21 = xo43;
        4'd11: wdat21 = xo45;
        4'd12: wdat21 = xo53;
        default: wdat21 = yo5;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_21_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_21_we <= 1'b1; m0_21_wa <= (w_f ? w_hB : w_hA); m0_21_wd <= wdat21; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m0_21_we <= 1'b1; m0_21_wa <= frow; m0_21_wd <= x_in_5; end
        else m0_21_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_21_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_21_we <= 1'b1; m1_21_wa <= (w_f ? w_hB : w_hA); m1_21_wd <= wdat21; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m1_21_we <= 1'b1; m1_21_wa <= frow; m1_21_wd <= x_in_5; end
        else m1_21_we <= 1'b0;
    end
    logic [63:0] wdat22;
    always_comb case (wc22)
        4'd0: wdat22 = yo6;
        4'd1: wdat22 = yo10;
        4'd2: wdat22 = xo11;
        4'd3: wdat22 = xo14;
        4'd4: wdat22 = xo22;
        4'd5: wdat22 = yo22;
        4'd6: wdat22 = yo38;
        4'd7: wdat22 = yo42;
        4'd8: wdat22 = xo43;
        4'd9: wdat22 = xo46;
        4'd10: wdat22 = xo54;
        default: wdat22 = yo6;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_22_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_22_we <= 1'b1; m0_22_wa <= (w_f ? w_hB : w_hA); m0_22_wd <= wdat22; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m0_22_we <= 1'b1; m0_22_wa <= frow; m0_22_wd <= x_in_6; end
        else m0_22_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_22_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_22_we <= 1'b1; m1_22_wa <= (w_f ? w_hB : w_hA); m1_22_wd <= wdat22; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m1_22_we <= 1'b1; m1_22_wa <= frow; m1_22_wd <= x_in_6; end
        else m1_22_we <= 1'b0;
    end
    logic [63:0] wdat23;
    always_comb case (wc23)
        4'd0: wdat23 = yo7;
        4'd1: wdat23 = yo11;
        4'd2: wdat23 = xo15;
        4'd3: wdat23 = xo23;
        4'd4: wdat23 = yo23;
        4'd5: wdat23 = yo39;
        4'd6: wdat23 = yo43;
        4'd7: wdat23 = xo47;
        4'd8: wdat23 = xo55;
        default: wdat23 = yo7;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_23_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_23_we <= 1'b1; m0_23_wa <= (w_f ? w_hB : w_hA); m0_23_wd <= wdat23; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m0_23_we <= 1'b1; m0_23_wa <= frow; m0_23_wd <= x_in_7; end
        else m0_23_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_23_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_23_we <= 1'b1; m1_23_wa <= (w_f ? w_hB : w_hA); m1_23_wd <= wdat23; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd10) : (fsub == 4'd2))) begin m1_23_we <= 1'b1; m1_23_wa <= frow; m1_23_wd <= x_in_7; end
        else m1_23_we <= 1'b0;
    end
    logic [63:0] wdat24;
    always_comb case (wc24)
        3'd0: wdat24 = yo8;
        3'd1: wdat24 = xo12;
        3'd2: wdat24 = xo24;
        3'd3: wdat24 = yo24;
        3'd4: wdat24 = yo40;
        3'd5: wdat24 = xo44;
        3'd6: wdat24 = xo56;
        default: wdat24 = yo8;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_24_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_24_we <= 1'b1; m0_24_wa <= (w_f ? w_hB : w_hA); m0_24_wd <= wdat24; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m0_24_we <= 1'b1; m0_24_wa <= frow; m0_24_wd <= x_in_0; end
        else m0_24_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_24_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_24_we <= 1'b1; m1_24_wa <= (w_f ? w_hB : w_hA); m1_24_wd <= wdat24; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m1_24_we <= 1'b1; m1_24_wa <= frow; m1_24_wd <= x_in_0; end
        else m1_24_we <= 1'b0;
    end
    logic [63:0] wdat25;
    always_comb case (wc25)
        4'd0: wdat25 = yo9;
        4'd1: wdat25 = yo12;
        4'd2: wdat25 = xo13;
        4'd3: wdat25 = xo25;
        4'd4: wdat25 = yo25;
        4'd5: wdat25 = yo41;
        4'd6: wdat25 = yo44;
        4'd7: wdat25 = xo45;
        4'd8: wdat25 = xo57;
        default: wdat25 = yo9;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_25_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_25_we <= 1'b1; m0_25_wa <= (w_f ? w_hB : w_hA); m0_25_wd <= wdat25; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m0_25_we <= 1'b1; m0_25_wa <= frow; m0_25_wd <= x_in_1; end
        else m0_25_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_25_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_25_we <= 1'b1; m1_25_wa <= (w_f ? w_hB : w_hA); m1_25_wd <= wdat25; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m1_25_we <= 1'b1; m1_25_wa <= frow; m1_25_wd <= x_in_1; end
        else m1_25_we <= 1'b0;
    end
    logic [63:0] wdat26;
    always_comb case (wc26)
        4'd0: wdat26 = yo10;
        4'd1: wdat26 = yo12;
        4'd2: wdat26 = xo13;
        4'd3: wdat26 = xo14;
        4'd4: wdat26 = xo26;
        4'd5: wdat26 = yo26;
        4'd6: wdat26 = yo42;
        4'd7: wdat26 = yo44;
        4'd8: wdat26 = xo45;
        4'd9: wdat26 = xo46;
        4'd10: wdat26 = xo58;
        default: wdat26 = yo10;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_26_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_26_we <= 1'b1; m0_26_wa <= (w_f ? w_hB : w_hA); m0_26_wd <= wdat26; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m0_26_we <= 1'b1; m0_26_wa <= frow; m0_26_wd <= x_in_2; end
        else m0_26_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_26_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_26_we <= 1'b1; m1_26_wa <= (w_f ? w_hB : w_hA); m1_26_wd <= wdat26; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m1_26_we <= 1'b1; m1_26_wa <= frow; m1_26_wd <= x_in_2; end
        else m1_26_we <= 1'b0;
    end
    logic [63:0] wdat27;
    always_comb case (wc27)
        4'd0: wdat27 = yo11;
        4'd1: wdat27 = yo13;
        4'd2: wdat27 = xo15;
        4'd3: wdat27 = xo27;
        4'd4: wdat27 = yo27;
        4'd5: wdat27 = yo43;
        4'd6: wdat27 = yo45;
        4'd7: wdat27 = xo47;
        4'd8: wdat27 = xo59;
        default: wdat27 = yo11;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_27_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_27_we <= 1'b1; m0_27_wa <= (w_f ? w_hB : w_hA); m0_27_wd <= wdat27; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m0_27_we <= 1'b1; m0_27_wa <= frow; m0_27_wd <= x_in_3; end
        else m0_27_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_27_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_27_we <= 1'b1; m1_27_wa <= (w_f ? w_hB : w_hA); m1_27_wd <= wdat27; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m1_27_we <= 1'b1; m1_27_wa <= frow; m1_27_wd <= x_in_3; end
        else m1_27_we <= 1'b0;
    end
    logic [63:0] wdat28;
    always_comb case (wc28)
        3'd0: wdat28 = yo12;
        3'd1: wdat28 = xo14;
        3'd2: wdat28 = xo28;
        3'd3: wdat28 = yo28;
        3'd4: wdat28 = yo44;
        3'd5: wdat28 = xo46;
        3'd6: wdat28 = xo60;
        default: wdat28 = yo12;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_28_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_28_we <= 1'b1; m0_28_wa <= (w_f ? w_hB : w_hA); m0_28_wd <= wdat28; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m0_28_we <= 1'b1; m0_28_wa <= frow; m0_28_wd <= x_in_4; end
        else m0_28_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_28_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_28_we <= 1'b1; m1_28_wa <= (w_f ? w_hB : w_hA); m1_28_wd <= wdat28; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m1_28_we <= 1'b1; m1_28_wa <= frow; m1_28_wd <= x_in_4; end
        else m1_28_we <= 1'b0;
    end
    logic [63:0] wdat29;
    always_comb case (wc29)
        4'd0: wdat29 = yo13;
        4'd1: wdat29 = yo14;
        4'd2: wdat29 = xo15;
        4'd3: wdat29 = xo29;
        4'd4: wdat29 = yo29;
        4'd5: wdat29 = yo45;
        4'd6: wdat29 = yo46;
        4'd7: wdat29 = xo47;
        4'd8: wdat29 = xo61;
        default: wdat29 = yo13;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_29_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_29_we <= 1'b1; m0_29_wa <= (w_f ? w_hB : w_hA); m0_29_wd <= wdat29; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m0_29_we <= 1'b1; m0_29_wa <= frow; m0_29_wd <= x_in_5; end
        else m0_29_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_29_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_29_we <= 1'b1; m1_29_wa <= (w_f ? w_hB : w_hA); m1_29_wd <= wdat29; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m1_29_we <= 1'b1; m1_29_wa <= frow; m1_29_wd <= x_in_5; end
        else m1_29_we <= 1'b0;
    end
    logic [63:0] wdat30;
    always_comb case (wc30)
        3'd0: wdat30 = yo14;
        3'd1: wdat30 = xo15;
        3'd2: wdat30 = xo30;
        3'd3: wdat30 = yo30;
        3'd4: wdat30 = yo46;
        3'd5: wdat30 = xo47;
        3'd6: wdat30 = xo62;
        default: wdat30 = yo14;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_30_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_30_we <= 1'b1; m0_30_wa <= (w_f ? w_hB : w_hA); m0_30_wd <= wdat30; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m0_30_we <= 1'b1; m0_30_wa <= frow; m0_30_wd <= x_in_6; end
        else m0_30_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_30_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_30_we <= 1'b1; m1_30_wa <= (w_f ? w_hB : w_hA); m1_30_wd <= wdat30; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m1_30_we <= 1'b1; m1_30_wa <= frow; m1_30_wd <= x_in_6; end
        else m1_30_we <= 1'b0;
    end
    logic [63:0] wdat31;
    always_comb case (wc31)
        3'd0: wdat31 = yo15;
        3'd1: wdat31 = xo31;
        3'd2: wdat31 = yo31;
        3'd3: wdat31 = yo47;
        3'd4: wdat31 = xo63;
        default: wdat31 = yo15;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_31_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_31_we <= 1'b1; m0_31_wa <= (w_f ? w_hB : w_hA); m0_31_wd <= wdat31; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m0_31_we <= 1'b1; m0_31_wa <= frow; m0_31_wd <= x_in_7; end
        else m0_31_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_31_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_31_we <= 1'b1; m1_31_wa <= (w_f ? w_hB : w_hA); m1_31_wd <= wdat31; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd11) : (fsub == 4'd3))) begin m1_31_we <= 1'b1; m1_31_wa <= frow; m1_31_wd <= x_in_7; end
        else m1_31_we <= 1'b0;
    end
    logic [63:0] wdat32;
    always_comb case (wc32)
        3'd0: wdat32 = yo0;
        3'd1: wdat32 = xo16;
        3'd2: wdat32 = xo32;
        3'd3: wdat32 = yo32;
        3'd4: wdat32 = xo48;
        default: wdat32 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_32_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_32_we <= 1'b1; m0_32_wa <= (w_f ? w_hB : w_hA); m0_32_wd <= wdat32; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m0_32_we <= 1'b1; m0_32_wa <= frow; m0_32_wd <= x_in_0; end
        else m0_32_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_32_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_32_we <= 1'b1; m1_32_wa <= (w_f ? w_hB : w_hA); m1_32_wd <= wdat32; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m1_32_we <= 1'b1; m1_32_wa <= frow; m1_32_wd <= x_in_0; end
        else m1_32_we <= 1'b0;
    end
    logic [63:0] wdat33;
    always_comb case (wc33)
        3'd0: wdat33 = yo1;
        3'd1: wdat33 = yo16;
        3'd2: wdat33 = xo17;
        3'd3: wdat33 = xo33;
        3'd4: wdat33 = yo33;
        3'd5: wdat33 = yo48;
        3'd6: wdat33 = xo49;
        default: wdat33 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_33_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_33_we <= 1'b1; m0_33_wa <= (w_f ? w_hB : w_hA); m0_33_wd <= wdat33; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m0_33_we <= 1'b1; m0_33_wa <= frow; m0_33_wd <= x_in_1; end
        else m0_33_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_33_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_33_we <= 1'b1; m1_33_wa <= (w_f ? w_hB : w_hA); m1_33_wd <= wdat33; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m1_33_we <= 1'b1; m1_33_wa <= frow; m1_33_wd <= x_in_1; end
        else m1_33_we <= 1'b0;
    end
    logic [63:0] wdat34;
    always_comb case (wc34)
        4'd0: wdat34 = yo2;
        4'd1: wdat34 = yo16;
        4'd2: wdat34 = xo17;
        4'd3: wdat34 = xo18;
        4'd4: wdat34 = xo34;
        4'd5: wdat34 = yo34;
        4'd6: wdat34 = yo48;
        4'd7: wdat34 = xo49;
        4'd8: wdat34 = xo50;
        default: wdat34 = yo2;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_34_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_34_we <= 1'b1; m0_34_wa <= (w_f ? w_hB : w_hA); m0_34_wd <= wdat34; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m0_34_we <= 1'b1; m0_34_wa <= frow; m0_34_wd <= x_in_2; end
        else m0_34_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_34_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_34_we <= 1'b1; m1_34_wa <= (w_f ? w_hB : w_hA); m1_34_wd <= wdat34; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m1_34_we <= 1'b1; m1_34_wa <= frow; m1_34_wd <= x_in_2; end
        else m1_34_we <= 1'b0;
    end
    logic [63:0] wdat35;
    always_comb case (wc35)
        3'd0: wdat35 = yo3;
        3'd1: wdat35 = yo17;
        3'd2: wdat35 = xo19;
        3'd3: wdat35 = xo35;
        3'd4: wdat35 = yo35;
        3'd5: wdat35 = yo49;
        3'd6: wdat35 = xo51;
        default: wdat35 = yo3;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_35_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_35_we <= 1'b1; m0_35_wa <= (w_f ? w_hB : w_hA); m0_35_wd <= wdat35; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m0_35_we <= 1'b1; m0_35_wa <= frow; m0_35_wd <= x_in_3; end
        else m0_35_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_35_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_35_we <= 1'b1; m1_35_wa <= (w_f ? w_hB : w_hA); m1_35_wd <= wdat35; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m1_35_we <= 1'b1; m1_35_wa <= frow; m1_35_wd <= x_in_3; end
        else m1_35_we <= 1'b0;
    end
    logic [63:0] wdat36;
    always_comb case (wc36)
        4'd0: wdat36 = yo4;
        4'd1: wdat36 = yo16;
        4'd2: wdat36 = xo18;
        4'd3: wdat36 = xo20;
        4'd4: wdat36 = xo36;
        4'd5: wdat36 = yo36;
        4'd6: wdat36 = yo48;
        4'd7: wdat36 = xo50;
        4'd8: wdat36 = xo52;
        default: wdat36 = yo4;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_36_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_36_we <= 1'b1; m0_36_wa <= (w_f ? w_hB : w_hA); m0_36_wd <= wdat36; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m0_36_we <= 1'b1; m0_36_wa <= frow; m0_36_wd <= x_in_4; end
        else m0_36_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_36_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_36_we <= 1'b1; m1_36_wa <= (w_f ? w_hB : w_hA); m1_36_wd <= wdat36; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m1_36_we <= 1'b1; m1_36_wa <= frow; m1_36_wd <= x_in_4; end
        else m1_36_we <= 1'b0;
    end
    logic [63:0] wdat37;
    always_comb case (wc37)
        4'd0: wdat37 = yo5;
        4'd1: wdat37 = yo17;
        4'd2: wdat37 = yo18;
        4'd3: wdat37 = xo19;
        4'd4: wdat37 = xo21;
        4'd5: wdat37 = xo37;
        4'd6: wdat37 = yo37;
        4'd7: wdat37 = yo49;
        4'd8: wdat37 = yo50;
        4'd9: wdat37 = xo51;
        4'd10: wdat37 = xo53;
        default: wdat37 = yo5;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_37_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_37_we <= 1'b1; m0_37_wa <= (w_f ? w_hB : w_hA); m0_37_wd <= wdat37; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m0_37_we <= 1'b1; m0_37_wa <= frow; m0_37_wd <= x_in_5; end
        else m0_37_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_37_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_37_we <= 1'b1; m1_37_wa <= (w_f ? w_hB : w_hA); m1_37_wd <= wdat37; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m1_37_we <= 1'b1; m1_37_wa <= frow; m1_37_wd <= x_in_5; end
        else m1_37_we <= 1'b0;
    end
    logic [63:0] wdat38;
    always_comb case (wc38)
        4'd0: wdat38 = yo6;
        4'd1: wdat38 = yo18;
        4'd2: wdat38 = xo19;
        4'd3: wdat38 = xo22;
        4'd4: wdat38 = xo38;
        4'd5: wdat38 = yo38;
        4'd6: wdat38 = yo50;
        4'd7: wdat38 = xo51;
        4'd8: wdat38 = xo54;
        default: wdat38 = yo6;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_38_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_38_we <= 1'b1; m0_38_wa <= (w_f ? w_hB : w_hA); m0_38_wd <= wdat38; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m0_38_we <= 1'b1; m0_38_wa <= frow; m0_38_wd <= x_in_6; end
        else m0_38_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_38_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_38_we <= 1'b1; m1_38_wa <= (w_f ? w_hB : w_hA); m1_38_wd <= wdat38; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m1_38_we <= 1'b1; m1_38_wa <= frow; m1_38_wd <= x_in_6; end
        else m1_38_we <= 1'b0;
    end
    logic [63:0] wdat39;
    always_comb case (wc39)
        3'd0: wdat39 = yo7;
        3'd1: wdat39 = yo19;
        3'd2: wdat39 = xo23;
        3'd3: wdat39 = xo39;
        3'd4: wdat39 = yo39;
        3'd5: wdat39 = yo51;
        3'd6: wdat39 = xo55;
        default: wdat39 = yo7;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_39_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_39_we <= 1'b1; m0_39_wa <= (w_f ? w_hB : w_hA); m0_39_wd <= wdat39; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m0_39_we <= 1'b1; m0_39_wa <= frow; m0_39_wd <= x_in_7; end
        else m0_39_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_39_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_39_we <= 1'b1; m1_39_wa <= (w_f ? w_hB : w_hA); m1_39_wd <= wdat39; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd12) : (fsub == 4'd4))) begin m1_39_we <= 1'b1; m1_39_wa <= frow; m1_39_wd <= x_in_7; end
        else m1_39_we <= 1'b0;
    end
    logic [63:0] wdat40;
    always_comb case (wc40)
        4'd0: wdat40 = yo8;
        4'd1: wdat40 = yo16;
        4'd2: wdat40 = xo20;
        4'd3: wdat40 = xo24;
        4'd4: wdat40 = xo40;
        4'd5: wdat40 = yo40;
        4'd6: wdat40 = yo48;
        4'd7: wdat40 = xo52;
        4'd8: wdat40 = xo56;
        default: wdat40 = yo8;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_40_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_40_we <= 1'b1; m0_40_wa <= (w_f ? w_hB : w_hA); m0_40_wd <= wdat40; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m0_40_we <= 1'b1; m0_40_wa <= frow; m0_40_wd <= x_in_0; end
        else m0_40_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_40_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_40_we <= 1'b1; m1_40_wa <= (w_f ? w_hB : w_hA); m1_40_wd <= wdat40; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m1_40_we <= 1'b1; m1_40_wa <= frow; m1_40_wd <= x_in_0; end
        else m1_40_we <= 1'b0;
    end
    logic [63:0] wdat41;
    always_comb case (wc41)
        4'd0: wdat41 = yo9;
        4'd1: wdat41 = yo17;
        4'd2: wdat41 = yo20;
        4'd3: wdat41 = xo21;
        4'd4: wdat41 = xo25;
        4'd5: wdat41 = xo41;
        4'd6: wdat41 = yo41;
        4'd7: wdat41 = yo49;
        4'd8: wdat41 = yo52;
        4'd9: wdat41 = xo53;
        4'd10: wdat41 = xo57;
        default: wdat41 = yo9;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_41_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_41_we <= 1'b1; m0_41_wa <= (w_f ? w_hB : w_hA); m0_41_wd <= wdat41; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m0_41_we <= 1'b1; m0_41_wa <= frow; m0_41_wd <= x_in_1; end
        else m0_41_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_41_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_41_we <= 1'b1; m1_41_wa <= (w_f ? w_hB : w_hA); m1_41_wd <= wdat41; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m1_41_we <= 1'b1; m1_41_wa <= frow; m1_41_wd <= x_in_1; end
        else m1_41_we <= 1'b0;
    end
    logic [63:0] wdat42;
    always_comb case (wc42)
        4'd0: wdat42 = yo10;
        4'd1: wdat42 = yo18;
        4'd2: wdat42 = yo20;
        4'd3: wdat42 = xo21;
        4'd4: wdat42 = xo22;
        4'd5: wdat42 = xo26;
        4'd6: wdat42 = xo42;
        4'd7: wdat42 = yo42;
        4'd8: wdat42 = yo50;
        4'd9: wdat42 = yo52;
        4'd10: wdat42 = xo53;
        4'd11: wdat42 = xo54;
        4'd12: wdat42 = xo58;
        default: wdat42 = yo10;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_42_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_42_we <= 1'b1; m0_42_wa <= (w_f ? w_hB : w_hA); m0_42_wd <= wdat42; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m0_42_we <= 1'b1; m0_42_wa <= frow; m0_42_wd <= x_in_2; end
        else m0_42_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_42_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_42_we <= 1'b1; m1_42_wa <= (w_f ? w_hB : w_hA); m1_42_wd <= wdat42; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m1_42_we <= 1'b1; m1_42_wa <= frow; m1_42_wd <= x_in_2; end
        else m1_42_we <= 1'b0;
    end
    logic [63:0] wdat43;
    always_comb case (wc43)
        4'd0: wdat43 = yo11;
        4'd1: wdat43 = yo19;
        4'd2: wdat43 = yo21;
        4'd3: wdat43 = xo23;
        4'd4: wdat43 = xo27;
        4'd5: wdat43 = xo43;
        4'd6: wdat43 = yo43;
        4'd7: wdat43 = yo51;
        4'd8: wdat43 = yo53;
        4'd9: wdat43 = xo55;
        4'd10: wdat43 = xo59;
        default: wdat43 = yo11;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_43_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_43_we <= 1'b1; m0_43_wa <= (w_f ? w_hB : w_hA); m0_43_wd <= wdat43; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m0_43_we <= 1'b1; m0_43_wa <= frow; m0_43_wd <= x_in_3; end
        else m0_43_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_43_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_43_we <= 1'b1; m1_43_wa <= (w_f ? w_hB : w_hA); m1_43_wd <= wdat43; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m1_43_we <= 1'b1; m1_43_wa <= frow; m1_43_wd <= x_in_3; end
        else m1_43_we <= 1'b0;
    end
    logic [63:0] wdat44;
    always_comb case (wc44)
        4'd0: wdat44 = yo12;
        4'd1: wdat44 = yo20;
        4'd2: wdat44 = xo22;
        4'd3: wdat44 = xo28;
        4'd4: wdat44 = xo44;
        4'd5: wdat44 = yo44;
        4'd6: wdat44 = yo52;
        4'd7: wdat44 = xo54;
        4'd8: wdat44 = xo60;
        default: wdat44 = yo12;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_44_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_44_we <= 1'b1; m0_44_wa <= (w_f ? w_hB : w_hA); m0_44_wd <= wdat44; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m0_44_we <= 1'b1; m0_44_wa <= frow; m0_44_wd <= x_in_4; end
        else m0_44_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_44_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_44_we <= 1'b1; m1_44_wa <= (w_f ? w_hB : w_hA); m1_44_wd <= wdat44; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m1_44_we <= 1'b1; m1_44_wa <= frow; m1_44_wd <= x_in_4; end
        else m1_44_we <= 1'b0;
    end
    logic [63:0] wdat45;
    always_comb case (wc45)
        4'd0: wdat45 = yo13;
        4'd1: wdat45 = yo21;
        4'd2: wdat45 = yo22;
        4'd3: wdat45 = xo23;
        4'd4: wdat45 = xo29;
        4'd5: wdat45 = xo45;
        4'd6: wdat45 = yo45;
        4'd7: wdat45 = yo53;
        4'd8: wdat45 = yo54;
        4'd9: wdat45 = xo55;
        4'd10: wdat45 = xo61;
        default: wdat45 = yo13;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_45_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_45_we <= 1'b1; m0_45_wa <= (w_f ? w_hB : w_hA); m0_45_wd <= wdat45; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m0_45_we <= 1'b1; m0_45_wa <= frow; m0_45_wd <= x_in_5; end
        else m0_45_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_45_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_45_we <= 1'b1; m1_45_wa <= (w_f ? w_hB : w_hA); m1_45_wd <= wdat45; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m1_45_we <= 1'b1; m1_45_wa <= frow; m1_45_wd <= x_in_5; end
        else m1_45_we <= 1'b0;
    end
    logic [63:0] wdat46;
    always_comb case (wc46)
        4'd0: wdat46 = yo14;
        4'd1: wdat46 = yo22;
        4'd2: wdat46 = xo23;
        4'd3: wdat46 = xo30;
        4'd4: wdat46 = xo46;
        4'd5: wdat46 = yo46;
        4'd6: wdat46 = yo54;
        4'd7: wdat46 = xo55;
        4'd8: wdat46 = xo62;
        default: wdat46 = yo14;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_46_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_46_we <= 1'b1; m0_46_wa <= (w_f ? w_hB : w_hA); m0_46_wd <= wdat46; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m0_46_we <= 1'b1; m0_46_wa <= frow; m0_46_wd <= x_in_6; end
        else m0_46_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_46_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_46_we <= 1'b1; m1_46_wa <= (w_f ? w_hB : w_hA); m1_46_wd <= wdat46; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m1_46_we <= 1'b1; m1_46_wa <= frow; m1_46_wd <= x_in_6; end
        else m1_46_we <= 1'b0;
    end
    logic [63:0] wdat47;
    always_comb case (wc47)
        3'd0: wdat47 = yo15;
        3'd1: wdat47 = yo23;
        3'd2: wdat47 = xo31;
        3'd3: wdat47 = xo47;
        3'd4: wdat47 = yo47;
        3'd5: wdat47 = yo55;
        3'd6: wdat47 = xo63;
        default: wdat47 = yo15;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_47_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_47_we <= 1'b1; m0_47_wa <= (w_f ? w_hB : w_hA); m0_47_wd <= wdat47; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m0_47_we <= 1'b1; m0_47_wa <= frow; m0_47_wd <= x_in_7; end
        else m0_47_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_47_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_47_we <= 1'b1; m1_47_wa <= (w_f ? w_hB : w_hA); m1_47_wd <= wdat47; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd13) : (fsub == 4'd5))) begin m1_47_we <= 1'b1; m1_47_wa <= frow; m1_47_wd <= x_in_7; end
        else m1_47_we <= 1'b0;
    end
    logic [63:0] wdat48;
    always_comb case (wc48)
        3'd0: wdat48 = yo16;
        3'd1: wdat48 = xo24;
        3'd2: wdat48 = xo48;
        3'd3: wdat48 = yo48;
        3'd4: wdat48 = xo56;
        default: wdat48 = yo16;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_48_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_48_we <= 1'b1; m0_48_wa <= (w_f ? w_hB : w_hA); m0_48_wd <= wdat48; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m0_48_we <= 1'b1; m0_48_wa <= frow; m0_48_wd <= x_in_0; end
        else m0_48_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_48_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_48_we <= 1'b1; m1_48_wa <= (w_f ? w_hB : w_hA); m1_48_wd <= wdat48; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m1_48_we <= 1'b1; m1_48_wa <= frow; m1_48_wd <= x_in_0; end
        else m1_48_we <= 1'b0;
    end
    logic [63:0] wdat49;
    always_comb case (wc49)
        3'd0: wdat49 = yo17;
        3'd1: wdat49 = yo24;
        3'd2: wdat49 = xo25;
        3'd3: wdat49 = xo49;
        3'd4: wdat49 = yo49;
        3'd5: wdat49 = yo56;
        3'd6: wdat49 = xo57;
        default: wdat49 = yo17;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_49_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_49_we <= 1'b1; m0_49_wa <= (w_f ? w_hB : w_hA); m0_49_wd <= wdat49; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m0_49_we <= 1'b1; m0_49_wa <= frow; m0_49_wd <= x_in_1; end
        else m0_49_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_49_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_49_we <= 1'b1; m1_49_wa <= (w_f ? w_hB : w_hA); m1_49_wd <= wdat49; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m1_49_we <= 1'b1; m1_49_wa <= frow; m1_49_wd <= x_in_1; end
        else m1_49_we <= 1'b0;
    end
    logic [63:0] wdat50;
    always_comb case (wc50)
        4'd0: wdat50 = yo18;
        4'd1: wdat50 = yo24;
        4'd2: wdat50 = xo25;
        4'd3: wdat50 = xo26;
        4'd4: wdat50 = xo50;
        4'd5: wdat50 = yo50;
        4'd6: wdat50 = yo56;
        4'd7: wdat50 = xo57;
        4'd8: wdat50 = xo58;
        default: wdat50 = yo18;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_50_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_50_we <= 1'b1; m0_50_wa <= (w_f ? w_hB : w_hA); m0_50_wd <= wdat50; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m0_50_we <= 1'b1; m0_50_wa <= frow; m0_50_wd <= x_in_2; end
        else m0_50_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_50_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_50_we <= 1'b1; m1_50_wa <= (w_f ? w_hB : w_hA); m1_50_wd <= wdat50; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m1_50_we <= 1'b1; m1_50_wa <= frow; m1_50_wd <= x_in_2; end
        else m1_50_we <= 1'b0;
    end
    logic [63:0] wdat51;
    always_comb case (wc51)
        3'd0: wdat51 = yo19;
        3'd1: wdat51 = yo25;
        3'd2: wdat51 = xo27;
        3'd3: wdat51 = xo51;
        3'd4: wdat51 = yo51;
        3'd5: wdat51 = yo57;
        3'd6: wdat51 = xo59;
        default: wdat51 = yo19;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_51_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_51_we <= 1'b1; m0_51_wa <= (w_f ? w_hB : w_hA); m0_51_wd <= wdat51; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m0_51_we <= 1'b1; m0_51_wa <= frow; m0_51_wd <= x_in_3; end
        else m0_51_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_51_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_51_we <= 1'b1; m1_51_wa <= (w_f ? w_hB : w_hA); m1_51_wd <= wdat51; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m1_51_we <= 1'b1; m1_51_wa <= frow; m1_51_wd <= x_in_3; end
        else m1_51_we <= 1'b0;
    end
    logic [63:0] wdat52;
    always_comb case (wc52)
        4'd0: wdat52 = yo20;
        4'd1: wdat52 = yo24;
        4'd2: wdat52 = xo26;
        4'd3: wdat52 = xo28;
        4'd4: wdat52 = xo52;
        4'd5: wdat52 = yo52;
        4'd6: wdat52 = yo56;
        4'd7: wdat52 = xo58;
        4'd8: wdat52 = xo60;
        default: wdat52 = yo20;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_52_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_52_we <= 1'b1; m0_52_wa <= (w_f ? w_hB : w_hA); m0_52_wd <= wdat52; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m0_52_we <= 1'b1; m0_52_wa <= frow; m0_52_wd <= x_in_4; end
        else m0_52_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_52_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_52_we <= 1'b1; m1_52_wa <= (w_f ? w_hB : w_hA); m1_52_wd <= wdat52; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m1_52_we <= 1'b1; m1_52_wa <= frow; m1_52_wd <= x_in_4; end
        else m1_52_we <= 1'b0;
    end
    logic [63:0] wdat53;
    always_comb case (wc53)
        4'd0: wdat53 = yo21;
        4'd1: wdat53 = yo25;
        4'd2: wdat53 = yo26;
        4'd3: wdat53 = xo27;
        4'd4: wdat53 = xo29;
        4'd5: wdat53 = xo53;
        4'd6: wdat53 = yo53;
        4'd7: wdat53 = yo57;
        4'd8: wdat53 = yo58;
        4'd9: wdat53 = xo59;
        4'd10: wdat53 = xo61;
        default: wdat53 = yo21;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_53_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_53_we <= 1'b1; m0_53_wa <= (w_f ? w_hB : w_hA); m0_53_wd <= wdat53; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m0_53_we <= 1'b1; m0_53_wa <= frow; m0_53_wd <= x_in_5; end
        else m0_53_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_53_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_53_we <= 1'b1; m1_53_wa <= (w_f ? w_hB : w_hA); m1_53_wd <= wdat53; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m1_53_we <= 1'b1; m1_53_wa <= frow; m1_53_wd <= x_in_5; end
        else m1_53_we <= 1'b0;
    end
    logic [63:0] wdat54;
    always_comb case (wc54)
        4'd0: wdat54 = yo22;
        4'd1: wdat54 = yo26;
        4'd2: wdat54 = xo27;
        4'd3: wdat54 = xo30;
        4'd4: wdat54 = xo54;
        4'd5: wdat54 = yo54;
        4'd6: wdat54 = yo58;
        4'd7: wdat54 = xo59;
        4'd8: wdat54 = xo62;
        default: wdat54 = yo22;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_54_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_54_we <= 1'b1; m0_54_wa <= (w_f ? w_hB : w_hA); m0_54_wd <= wdat54; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m0_54_we <= 1'b1; m0_54_wa <= frow; m0_54_wd <= x_in_6; end
        else m0_54_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_54_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_54_we <= 1'b1; m1_54_wa <= (w_f ? w_hB : w_hA); m1_54_wd <= wdat54; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m1_54_we <= 1'b1; m1_54_wa <= frow; m1_54_wd <= x_in_6; end
        else m1_54_we <= 1'b0;
    end
    logic [63:0] wdat55;
    always_comb case (wc55)
        3'd0: wdat55 = yo23;
        3'd1: wdat55 = yo27;
        3'd2: wdat55 = xo31;
        3'd3: wdat55 = xo55;
        3'd4: wdat55 = yo55;
        3'd5: wdat55 = yo59;
        3'd6: wdat55 = xo63;
        default: wdat55 = yo23;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_55_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_55_we <= 1'b1; m0_55_wa <= (w_f ? w_hB : w_hA); m0_55_wd <= wdat55; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m0_55_we <= 1'b1; m0_55_wa <= frow; m0_55_wd <= x_in_7; end
        else m0_55_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_55_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_55_we <= 1'b1; m1_55_wa <= (w_f ? w_hB : w_hA); m1_55_wd <= wdat55; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd14) : (fsub == 4'd6))) begin m1_55_we <= 1'b1; m1_55_wa <= frow; m1_55_wd <= x_in_7; end
        else m1_55_we <= 1'b0;
    end
    logic [63:0] wdat56;
    always_comb case (wc56)
        3'd0: wdat56 = yo24;
        3'd1: wdat56 = xo28;
        3'd2: wdat56 = xo56;
        3'd3: wdat56 = yo56;
        3'd4: wdat56 = xo60;
        default: wdat56 = yo24;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_56_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_56_we <= 1'b1; m0_56_wa <= (w_f ? w_hB : w_hA); m0_56_wd <= wdat56; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m0_56_we <= 1'b1; m0_56_wa <= frow; m0_56_wd <= x_in_0; end
        else m0_56_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_56_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_56_we <= 1'b1; m1_56_wa <= (w_f ? w_hB : w_hA); m1_56_wd <= wdat56; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m1_56_we <= 1'b1; m1_56_wa <= frow; m1_56_wd <= x_in_0; end
        else m1_56_we <= 1'b0;
    end
    logic [63:0] wdat57;
    always_comb case (wc57)
        3'd0: wdat57 = yo25;
        3'd1: wdat57 = yo28;
        3'd2: wdat57 = xo29;
        3'd3: wdat57 = xo57;
        3'd4: wdat57 = yo57;
        3'd5: wdat57 = yo60;
        3'd6: wdat57 = xo61;
        default: wdat57 = yo25;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_57_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_57_we <= 1'b1; m0_57_wa <= (w_f ? w_hB : w_hA); m0_57_wd <= wdat57; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m0_57_we <= 1'b1; m0_57_wa <= frow; m0_57_wd <= x_in_1; end
        else m0_57_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_57_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_57_we <= 1'b1; m1_57_wa <= (w_f ? w_hB : w_hA); m1_57_wd <= wdat57; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m1_57_we <= 1'b1; m1_57_wa <= frow; m1_57_wd <= x_in_1; end
        else m1_57_we <= 1'b0;
    end
    logic [63:0] wdat58;
    always_comb case (wc58)
        4'd0: wdat58 = yo26;
        4'd1: wdat58 = yo28;
        4'd2: wdat58 = xo29;
        4'd3: wdat58 = xo30;
        4'd4: wdat58 = xo58;
        4'd5: wdat58 = yo58;
        4'd6: wdat58 = yo60;
        4'd7: wdat58 = xo61;
        4'd8: wdat58 = xo62;
        default: wdat58 = yo26;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_58_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_58_we <= 1'b1; m0_58_wa <= (w_f ? w_hB : w_hA); m0_58_wd <= wdat58; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m0_58_we <= 1'b1; m0_58_wa <= frow; m0_58_wd <= x_in_2; end
        else m0_58_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_58_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_58_we <= 1'b1; m1_58_wa <= (w_f ? w_hB : w_hA); m1_58_wd <= wdat58; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m1_58_we <= 1'b1; m1_58_wa <= frow; m1_58_wd <= x_in_2; end
        else m1_58_we <= 1'b0;
    end
    logic [63:0] wdat59;
    always_comb case (wc59)
        3'd0: wdat59 = yo27;
        3'd1: wdat59 = yo29;
        3'd2: wdat59 = xo31;
        3'd3: wdat59 = xo59;
        3'd4: wdat59 = yo59;
        3'd5: wdat59 = yo61;
        3'd6: wdat59 = xo63;
        default: wdat59 = yo27;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_59_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_59_we <= 1'b1; m0_59_wa <= (w_f ? w_hB : w_hA); m0_59_wd <= wdat59; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m0_59_we <= 1'b1; m0_59_wa <= frow; m0_59_wd <= x_in_3; end
        else m0_59_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_59_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_59_we <= 1'b1; m1_59_wa <= (w_f ? w_hB : w_hA); m1_59_wd <= wdat59; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m1_59_we <= 1'b1; m1_59_wa <= frow; m1_59_wd <= x_in_3; end
        else m1_59_we <= 1'b0;
    end
    logic [63:0] wdat60;
    always_comb case (wc60)
        3'd0: wdat60 = yo28;
        3'd1: wdat60 = xo30;
        3'd2: wdat60 = xo60;
        3'd3: wdat60 = yo60;
        3'd4: wdat60 = xo62;
        default: wdat60 = yo28;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_60_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_60_we <= 1'b1; m0_60_wa <= (w_f ? w_hB : w_hA); m0_60_wd <= wdat60; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m0_60_we <= 1'b1; m0_60_wa <= frow; m0_60_wd <= x_in_4; end
        else m0_60_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_60_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_60_we <= 1'b1; m1_60_wa <= (w_f ? w_hB : w_hA); m1_60_wd <= wdat60; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m1_60_we <= 1'b1; m1_60_wa <= frow; m1_60_wd <= x_in_4; end
        else m1_60_we <= 1'b0;
    end
    logic [63:0] wdat61;
    always_comb case (wc61)
        3'd0: wdat61 = yo29;
        3'd1: wdat61 = yo30;
        3'd2: wdat61 = xo31;
        3'd3: wdat61 = xo61;
        3'd4: wdat61 = yo61;
        3'd5: wdat61 = yo62;
        3'd6: wdat61 = xo63;
        default: wdat61 = yo29;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_61_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_61_we <= 1'b1; m0_61_wa <= (w_f ? w_hB : w_hA); m0_61_wd <= wdat61; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m0_61_we <= 1'b1; m0_61_wa <= frow; m0_61_wd <= x_in_5; end
        else m0_61_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_61_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_61_we <= 1'b1; m1_61_wa <= (w_f ? w_hB : w_hA); m1_61_wd <= wdat61; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m1_61_we <= 1'b1; m1_61_wa <= frow; m1_61_wd <= x_in_5; end
        else m1_61_we <= 1'b0;
    end
    logic [63:0] wdat62;
    always_comb case (wc62)
        3'd0: wdat62 = yo30;
        3'd1: wdat62 = xo31;
        3'd2: wdat62 = xo62;
        3'd3: wdat62 = yo62;
        3'd4: wdat62 = xo63;
        default: wdat62 = yo30;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_62_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_62_we <= 1'b1; m0_62_wa <= (w_f ? w_hB : w_hA); m0_62_wd <= wdat62; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m0_62_we <= 1'b1; m0_62_wa <= frow; m0_62_wd <= x_in_6; end
        else m0_62_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_62_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_62_we <= 1'b1; m1_62_wa <= (w_f ? w_hB : w_hA); m1_62_wd <= wdat62; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m1_62_we <= 1'b1; m1_62_wa <= frow; m1_62_wd <= x_in_6; end
        else m1_62_we <= 1'b0;
    end
    logic [63:0] wdat63;
    always_comb case (wc63)
        2'd0: wdat63 = yo31;
        2'd1: wdat63 = xo63;
        2'd2: wdat63 = yo63;
        default: wdat63 = yo31;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_63_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_63_we <= 1'b1; m0_63_wa <= (w_f ? w_hB : w_hA); m0_63_wd <= wdat63; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m0_63_we <= 1'b1; m0_63_wa <= frow; m0_63_wd <= x_in_7; end
        else m0_63_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_63_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_63_we <= 1'b1; m1_63_wa <= (w_f ? w_hB : w_hA); m1_63_wd <= wdat63; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd15) : (fsub == 4'd7))) begin m1_63_we <= 1'b1; m1_63_wa <= frow; m1_63_wd <= x_in_7; end
        else m1_63_we <= 1'b0;
    end
    logic [63:0] wdat64;
    always_comb case (wc64)
        2'd0: wdat64 = xo0;
        2'd1: wdat64 = yo0;
        2'd2: wdat64 = xo32;
        default: wdat64 = xo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_64_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_64_we <= 1'b1; m0_64_wa <= (w_f ? w_hA : w_hB); m0_64_wd <= wdat64; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m0_64_we <= 1'b1; m0_64_wa <= frow; m0_64_wd <= x_in_0; end
        else m0_64_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_64_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_64_we <= 1'b1; m1_64_wa <= (w_f ? w_hA : w_hB); m1_64_wd <= wdat64; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m1_64_we <= 1'b1; m1_64_wa <= frow; m1_64_wd <= x_in_0; end
        else m1_64_we <= 1'b0;
    end
    logic [63:0] wdat65;
    always_comb case (wc65)
        3'd0: wdat65 = yo0;
        3'd1: wdat65 = xo1;
        3'd2: wdat65 = yo1;
        3'd3: wdat65 = yo32;
        3'd4: wdat65 = xo33;
        default: wdat65 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_65_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_65_we <= 1'b1; m0_65_wa <= (w_f ? w_hA : w_hB); m0_65_wd <= wdat65; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m0_65_we <= 1'b1; m0_65_wa <= frow; m0_65_wd <= x_in_1; end
        else m0_65_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_65_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_65_we <= 1'b1; m1_65_wa <= (w_f ? w_hA : w_hB); m1_65_wd <= wdat65; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m1_65_we <= 1'b1; m1_65_wa <= frow; m1_65_wd <= x_in_1; end
        else m1_65_we <= 1'b0;
    end
    logic [63:0] wdat66;
    always_comb case (wc66)
        3'd0: wdat66 = yo0;
        3'd1: wdat66 = xo1;
        3'd2: wdat66 = xo2;
        3'd3: wdat66 = yo2;
        3'd4: wdat66 = yo32;
        3'd5: wdat66 = xo33;
        3'd6: wdat66 = xo34;
        default: wdat66 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_66_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_66_we <= 1'b1; m0_66_wa <= (w_f ? w_hA : w_hB); m0_66_wd <= wdat66; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m0_66_we <= 1'b1; m0_66_wa <= frow; m0_66_wd <= x_in_2; end
        else m0_66_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_66_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_66_we <= 1'b1; m1_66_wa <= (w_f ? w_hA : w_hB); m1_66_wd <= wdat66; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m1_66_we <= 1'b1; m1_66_wa <= frow; m1_66_wd <= x_in_2; end
        else m1_66_we <= 1'b0;
    end
    logic [63:0] wdat67;
    always_comb case (wc67)
        3'd0: wdat67 = yo1;
        3'd1: wdat67 = xo3;
        3'd2: wdat67 = yo3;
        3'd3: wdat67 = yo33;
        3'd4: wdat67 = xo35;
        default: wdat67 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_67_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_67_we <= 1'b1; m0_67_wa <= (w_f ? w_hA : w_hB); m0_67_wd <= wdat67; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m0_67_we <= 1'b1; m0_67_wa <= frow; m0_67_wd <= x_in_3; end
        else m0_67_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_67_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_67_we <= 1'b1; m1_67_wa <= (w_f ? w_hA : w_hB); m1_67_wd <= wdat67; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m1_67_we <= 1'b1; m1_67_wa <= frow; m1_67_wd <= x_in_3; end
        else m1_67_we <= 1'b0;
    end
    logic [63:0] wdat68;
    always_comb case (wc68)
        3'd0: wdat68 = yo0;
        3'd1: wdat68 = xo2;
        3'd2: wdat68 = xo4;
        3'd3: wdat68 = yo4;
        3'd4: wdat68 = yo32;
        3'd5: wdat68 = xo34;
        3'd6: wdat68 = xo36;
        default: wdat68 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_68_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_68_we <= 1'b1; m0_68_wa <= (w_f ? w_hA : w_hB); m0_68_wd <= wdat68; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m0_68_we <= 1'b1; m0_68_wa <= frow; m0_68_wd <= x_in_4; end
        else m0_68_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_68_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_68_we <= 1'b1; m1_68_wa <= (w_f ? w_hA : w_hB); m1_68_wd <= wdat68; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m1_68_we <= 1'b1; m1_68_wa <= frow; m1_68_wd <= x_in_4; end
        else m1_68_we <= 1'b0;
    end
    logic [63:0] wdat69;
    always_comb case (wc69)
        4'd0: wdat69 = yo1;
        4'd1: wdat69 = yo2;
        4'd2: wdat69 = xo3;
        4'd3: wdat69 = xo5;
        4'd4: wdat69 = yo5;
        4'd5: wdat69 = yo33;
        4'd6: wdat69 = yo34;
        4'd7: wdat69 = xo35;
        4'd8: wdat69 = xo37;
        default: wdat69 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_69_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_69_we <= 1'b1; m0_69_wa <= (w_f ? w_hA : w_hB); m0_69_wd <= wdat69; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m0_69_we <= 1'b1; m0_69_wa <= frow; m0_69_wd <= x_in_5; end
        else m0_69_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_69_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_69_we <= 1'b1; m1_69_wa <= (w_f ? w_hA : w_hB); m1_69_wd <= wdat69; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m1_69_we <= 1'b1; m1_69_wa <= frow; m1_69_wd <= x_in_5; end
        else m1_69_we <= 1'b0;
    end
    logic [63:0] wdat70;
    always_comb case (wc70)
        3'd0: wdat70 = yo2;
        3'd1: wdat70 = xo3;
        3'd2: wdat70 = xo6;
        3'd3: wdat70 = yo6;
        3'd4: wdat70 = yo34;
        3'd5: wdat70 = xo35;
        3'd6: wdat70 = xo38;
        default: wdat70 = yo2;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_70_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_70_we <= 1'b1; m0_70_wa <= (w_f ? w_hA : w_hB); m0_70_wd <= wdat70; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m0_70_we <= 1'b1; m0_70_wa <= frow; m0_70_wd <= x_in_6; end
        else m0_70_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_70_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_70_we <= 1'b1; m1_70_wa <= (w_f ? w_hA : w_hB); m1_70_wd <= wdat70; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m1_70_we <= 1'b1; m1_70_wa <= frow; m1_70_wd <= x_in_6; end
        else m1_70_we <= 1'b0;
    end
    logic [63:0] wdat71;
    always_comb case (wc71)
        3'd0: wdat71 = yo3;
        3'd1: wdat71 = xo7;
        3'd2: wdat71 = yo7;
        3'd3: wdat71 = yo35;
        3'd4: wdat71 = xo39;
        default: wdat71 = yo3;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_71_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_71_we <= 1'b1; m0_71_wa <= (w_f ? w_hA : w_hB); m0_71_wd <= wdat71; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m0_71_we <= 1'b1; m0_71_wa <= frow; m0_71_wd <= x_in_7; end
        else m0_71_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_71_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_71_we <= 1'b1; m1_71_wa <= (w_f ? w_hA : w_hB); m1_71_wd <= wdat71; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd0) : (fsub == 4'd8))) begin m1_71_we <= 1'b1; m1_71_wa <= frow; m1_71_wd <= x_in_7; end
        else m1_71_we <= 1'b0;
    end
    logic [63:0] wdat72;
    always_comb case (wc72)
        3'd0: wdat72 = yo0;
        3'd1: wdat72 = xo4;
        3'd2: wdat72 = xo8;
        3'd3: wdat72 = yo8;
        3'd4: wdat72 = yo32;
        3'd5: wdat72 = xo36;
        3'd6: wdat72 = xo40;
        default: wdat72 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_72_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_72_we <= 1'b1; m0_72_wa <= (w_f ? w_hA : w_hB); m0_72_wd <= wdat72; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m0_72_we <= 1'b1; m0_72_wa <= frow; m0_72_wd <= x_in_0; end
        else m0_72_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_72_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_72_we <= 1'b1; m1_72_wa <= (w_f ? w_hA : w_hB); m1_72_wd <= wdat72; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m1_72_we <= 1'b1; m1_72_wa <= frow; m1_72_wd <= x_in_0; end
        else m1_72_we <= 1'b0;
    end
    logic [63:0] wdat73;
    always_comb case (wc73)
        4'd0: wdat73 = yo1;
        4'd1: wdat73 = yo4;
        4'd2: wdat73 = xo5;
        4'd3: wdat73 = xo9;
        4'd4: wdat73 = yo9;
        4'd5: wdat73 = yo33;
        4'd6: wdat73 = yo36;
        4'd7: wdat73 = xo37;
        4'd8: wdat73 = xo41;
        default: wdat73 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_73_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_73_we <= 1'b1; m0_73_wa <= (w_f ? w_hA : w_hB); m0_73_wd <= wdat73; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m0_73_we <= 1'b1; m0_73_wa <= frow; m0_73_wd <= x_in_1; end
        else m0_73_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_73_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_73_we <= 1'b1; m1_73_wa <= (w_f ? w_hA : w_hB); m1_73_wd <= wdat73; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m1_73_we <= 1'b1; m1_73_wa <= frow; m1_73_wd <= x_in_1; end
        else m1_73_we <= 1'b0;
    end
    logic [63:0] wdat74;
    always_comb case (wc74)
        4'd0: wdat74 = yo2;
        4'd1: wdat74 = yo4;
        4'd2: wdat74 = xo5;
        4'd3: wdat74 = xo6;
        4'd4: wdat74 = xo10;
        4'd5: wdat74 = yo10;
        4'd6: wdat74 = yo34;
        4'd7: wdat74 = yo36;
        4'd8: wdat74 = xo37;
        4'd9: wdat74 = xo38;
        4'd10: wdat74 = xo42;
        default: wdat74 = yo2;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_74_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_74_we <= 1'b1; m0_74_wa <= (w_f ? w_hA : w_hB); m0_74_wd <= wdat74; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m0_74_we <= 1'b1; m0_74_wa <= frow; m0_74_wd <= x_in_2; end
        else m0_74_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_74_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_74_we <= 1'b1; m1_74_wa <= (w_f ? w_hA : w_hB); m1_74_wd <= wdat74; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m1_74_we <= 1'b1; m1_74_wa <= frow; m1_74_wd <= x_in_2; end
        else m1_74_we <= 1'b0;
    end
    logic [63:0] wdat75;
    always_comb case (wc75)
        4'd0: wdat75 = yo3;
        4'd1: wdat75 = yo5;
        4'd2: wdat75 = xo7;
        4'd3: wdat75 = xo11;
        4'd4: wdat75 = yo11;
        4'd5: wdat75 = yo35;
        4'd6: wdat75 = yo37;
        4'd7: wdat75 = xo39;
        4'd8: wdat75 = xo43;
        default: wdat75 = yo3;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_75_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_75_we <= 1'b1; m0_75_wa <= (w_f ? w_hA : w_hB); m0_75_wd <= wdat75; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m0_75_we <= 1'b1; m0_75_wa <= frow; m0_75_wd <= x_in_3; end
        else m0_75_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_75_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_75_we <= 1'b1; m1_75_wa <= (w_f ? w_hA : w_hB); m1_75_wd <= wdat75; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m1_75_we <= 1'b1; m1_75_wa <= frow; m1_75_wd <= x_in_3; end
        else m1_75_we <= 1'b0;
    end
    logic [63:0] wdat76;
    always_comb case (wc76)
        3'd0: wdat76 = yo4;
        3'd1: wdat76 = xo6;
        3'd2: wdat76 = xo12;
        3'd3: wdat76 = yo12;
        3'd4: wdat76 = yo36;
        3'd5: wdat76 = xo38;
        3'd6: wdat76 = xo44;
        default: wdat76 = yo4;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_76_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_76_we <= 1'b1; m0_76_wa <= (w_f ? w_hA : w_hB); m0_76_wd <= wdat76; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m0_76_we <= 1'b1; m0_76_wa <= frow; m0_76_wd <= x_in_4; end
        else m0_76_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_76_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_76_we <= 1'b1; m1_76_wa <= (w_f ? w_hA : w_hB); m1_76_wd <= wdat76; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m1_76_we <= 1'b1; m1_76_wa <= frow; m1_76_wd <= x_in_4; end
        else m1_76_we <= 1'b0;
    end
    logic [63:0] wdat77;
    always_comb case (wc77)
        4'd0: wdat77 = yo5;
        4'd1: wdat77 = yo6;
        4'd2: wdat77 = xo7;
        4'd3: wdat77 = xo13;
        4'd4: wdat77 = yo13;
        4'd5: wdat77 = yo37;
        4'd6: wdat77 = yo38;
        4'd7: wdat77 = xo39;
        4'd8: wdat77 = xo45;
        default: wdat77 = yo5;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_77_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_77_we <= 1'b1; m0_77_wa <= (w_f ? w_hA : w_hB); m0_77_wd <= wdat77; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m0_77_we <= 1'b1; m0_77_wa <= frow; m0_77_wd <= x_in_5; end
        else m0_77_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_77_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_77_we <= 1'b1; m1_77_wa <= (w_f ? w_hA : w_hB); m1_77_wd <= wdat77; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m1_77_we <= 1'b1; m1_77_wa <= frow; m1_77_wd <= x_in_5; end
        else m1_77_we <= 1'b0;
    end
    logic [63:0] wdat78;
    always_comb case (wc78)
        3'd0: wdat78 = yo6;
        3'd1: wdat78 = xo7;
        3'd2: wdat78 = xo14;
        3'd3: wdat78 = yo14;
        3'd4: wdat78 = yo38;
        3'd5: wdat78 = xo39;
        3'd6: wdat78 = xo46;
        default: wdat78 = yo6;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_78_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_78_we <= 1'b1; m0_78_wa <= (w_f ? w_hA : w_hB); m0_78_wd <= wdat78; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m0_78_we <= 1'b1; m0_78_wa <= frow; m0_78_wd <= x_in_6; end
        else m0_78_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_78_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_78_we <= 1'b1; m1_78_wa <= (w_f ? w_hA : w_hB); m1_78_wd <= wdat78; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m1_78_we <= 1'b1; m1_78_wa <= frow; m1_78_wd <= x_in_6; end
        else m1_78_we <= 1'b0;
    end
    logic [63:0] wdat79;
    always_comb case (wc79)
        3'd0: wdat79 = yo7;
        3'd1: wdat79 = xo15;
        3'd2: wdat79 = yo15;
        3'd3: wdat79 = yo39;
        3'd4: wdat79 = xo47;
        default: wdat79 = yo7;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_79_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_79_we <= 1'b1; m0_79_wa <= (w_f ? w_hA : w_hB); m0_79_wd <= wdat79; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m0_79_we <= 1'b1; m0_79_wa <= frow; m0_79_wd <= x_in_7; end
        else m0_79_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_79_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_79_we <= 1'b1; m1_79_wa <= (w_f ? w_hA : w_hB); m1_79_wd <= wdat79; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd1) : (fsub == 4'd9))) begin m1_79_we <= 1'b1; m1_79_wa <= frow; m1_79_wd <= x_in_7; end
        else m1_79_we <= 1'b0;
    end
    logic [63:0] wdat80;
    always_comb case (wc80)
        3'd0: wdat80 = yo0;
        3'd1: wdat80 = xo8;
        3'd2: wdat80 = xo16;
        3'd3: wdat80 = yo16;
        3'd4: wdat80 = yo32;
        3'd5: wdat80 = xo40;
        3'd6: wdat80 = xo48;
        default: wdat80 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_80_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_80_we <= 1'b1; m0_80_wa <= (w_f ? w_hA : w_hB); m0_80_wd <= wdat80; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m0_80_we <= 1'b1; m0_80_wa <= frow; m0_80_wd <= x_in_0; end
        else m0_80_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_80_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_80_we <= 1'b1; m1_80_wa <= (w_f ? w_hA : w_hB); m1_80_wd <= wdat80; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m1_80_we <= 1'b1; m1_80_wa <= frow; m1_80_wd <= x_in_0; end
        else m1_80_we <= 1'b0;
    end
    logic [63:0] wdat81;
    always_comb case (wc81)
        4'd0: wdat81 = yo1;
        4'd1: wdat81 = yo8;
        4'd2: wdat81 = xo9;
        4'd3: wdat81 = xo17;
        4'd4: wdat81 = yo17;
        4'd5: wdat81 = yo33;
        4'd6: wdat81 = yo40;
        4'd7: wdat81 = xo41;
        4'd8: wdat81 = xo49;
        default: wdat81 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_81_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_81_we <= 1'b1; m0_81_wa <= (w_f ? w_hA : w_hB); m0_81_wd <= wdat81; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m0_81_we <= 1'b1; m0_81_wa <= frow; m0_81_wd <= x_in_1; end
        else m0_81_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_81_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_81_we <= 1'b1; m1_81_wa <= (w_f ? w_hA : w_hB); m1_81_wd <= wdat81; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m1_81_we <= 1'b1; m1_81_wa <= frow; m1_81_wd <= x_in_1; end
        else m1_81_we <= 1'b0;
    end
    logic [63:0] wdat82;
    always_comb case (wc82)
        4'd0: wdat82 = yo2;
        4'd1: wdat82 = yo8;
        4'd2: wdat82 = xo9;
        4'd3: wdat82 = xo10;
        4'd4: wdat82 = xo18;
        4'd5: wdat82 = yo18;
        4'd6: wdat82 = yo34;
        4'd7: wdat82 = yo40;
        4'd8: wdat82 = xo41;
        4'd9: wdat82 = xo42;
        4'd10: wdat82 = xo50;
        default: wdat82 = yo2;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_82_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_82_we <= 1'b1; m0_82_wa <= (w_f ? w_hA : w_hB); m0_82_wd <= wdat82; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m0_82_we <= 1'b1; m0_82_wa <= frow; m0_82_wd <= x_in_2; end
        else m0_82_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_82_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_82_we <= 1'b1; m1_82_wa <= (w_f ? w_hA : w_hB); m1_82_wd <= wdat82; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m1_82_we <= 1'b1; m1_82_wa <= frow; m1_82_wd <= x_in_2; end
        else m1_82_we <= 1'b0;
    end
    logic [63:0] wdat83;
    always_comb case (wc83)
        4'd0: wdat83 = yo3;
        4'd1: wdat83 = yo9;
        4'd2: wdat83 = xo11;
        4'd3: wdat83 = xo19;
        4'd4: wdat83 = yo19;
        4'd5: wdat83 = yo35;
        4'd6: wdat83 = yo41;
        4'd7: wdat83 = xo43;
        4'd8: wdat83 = xo51;
        default: wdat83 = yo3;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_83_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_83_we <= 1'b1; m0_83_wa <= (w_f ? w_hA : w_hB); m0_83_wd <= wdat83; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m0_83_we <= 1'b1; m0_83_wa <= frow; m0_83_wd <= x_in_3; end
        else m0_83_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_83_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_83_we <= 1'b1; m1_83_wa <= (w_f ? w_hA : w_hB); m1_83_wd <= wdat83; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m1_83_we <= 1'b1; m1_83_wa <= frow; m1_83_wd <= x_in_3; end
        else m1_83_we <= 1'b0;
    end
    logic [63:0] wdat84;
    always_comb case (wc84)
        4'd0: wdat84 = yo4;
        4'd1: wdat84 = yo8;
        4'd2: wdat84 = xo10;
        4'd3: wdat84 = xo12;
        4'd4: wdat84 = xo20;
        4'd5: wdat84 = yo20;
        4'd6: wdat84 = yo36;
        4'd7: wdat84 = yo40;
        4'd8: wdat84 = xo42;
        4'd9: wdat84 = xo44;
        4'd10: wdat84 = xo52;
        default: wdat84 = yo4;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_84_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_84_we <= 1'b1; m0_84_wa <= (w_f ? w_hA : w_hB); m0_84_wd <= wdat84; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m0_84_we <= 1'b1; m0_84_wa <= frow; m0_84_wd <= x_in_4; end
        else m0_84_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_84_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_84_we <= 1'b1; m1_84_wa <= (w_f ? w_hA : w_hB); m1_84_wd <= wdat84; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m1_84_we <= 1'b1; m1_84_wa <= frow; m1_84_wd <= x_in_4; end
        else m1_84_we <= 1'b0;
    end
    logic [63:0] wdat85;
    always_comb case (wc85)
        4'd0: wdat85 = yo5;
        4'd1: wdat85 = yo9;
        4'd2: wdat85 = yo10;
        4'd3: wdat85 = xo11;
        4'd4: wdat85 = xo13;
        4'd5: wdat85 = xo21;
        4'd6: wdat85 = yo21;
        4'd7: wdat85 = yo37;
        4'd8: wdat85 = yo41;
        4'd9: wdat85 = yo42;
        4'd10: wdat85 = xo43;
        4'd11: wdat85 = xo45;
        4'd12: wdat85 = xo53;
        default: wdat85 = yo5;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_85_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_85_we <= 1'b1; m0_85_wa <= (w_f ? w_hA : w_hB); m0_85_wd <= wdat85; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m0_85_we <= 1'b1; m0_85_wa <= frow; m0_85_wd <= x_in_5; end
        else m0_85_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_85_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_85_we <= 1'b1; m1_85_wa <= (w_f ? w_hA : w_hB); m1_85_wd <= wdat85; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m1_85_we <= 1'b1; m1_85_wa <= frow; m1_85_wd <= x_in_5; end
        else m1_85_we <= 1'b0;
    end
    logic [63:0] wdat86;
    always_comb case (wc86)
        4'd0: wdat86 = yo6;
        4'd1: wdat86 = yo10;
        4'd2: wdat86 = xo11;
        4'd3: wdat86 = xo14;
        4'd4: wdat86 = xo22;
        4'd5: wdat86 = yo22;
        4'd6: wdat86 = yo38;
        4'd7: wdat86 = yo42;
        4'd8: wdat86 = xo43;
        4'd9: wdat86 = xo46;
        4'd10: wdat86 = xo54;
        default: wdat86 = yo6;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_86_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_86_we <= 1'b1; m0_86_wa <= (w_f ? w_hA : w_hB); m0_86_wd <= wdat86; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m0_86_we <= 1'b1; m0_86_wa <= frow; m0_86_wd <= x_in_6; end
        else m0_86_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_86_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_86_we <= 1'b1; m1_86_wa <= (w_f ? w_hA : w_hB); m1_86_wd <= wdat86; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m1_86_we <= 1'b1; m1_86_wa <= frow; m1_86_wd <= x_in_6; end
        else m1_86_we <= 1'b0;
    end
    logic [63:0] wdat87;
    always_comb case (wc87)
        4'd0: wdat87 = yo7;
        4'd1: wdat87 = yo11;
        4'd2: wdat87 = xo15;
        4'd3: wdat87 = xo23;
        4'd4: wdat87 = yo23;
        4'd5: wdat87 = yo39;
        4'd6: wdat87 = yo43;
        4'd7: wdat87 = xo47;
        4'd8: wdat87 = xo55;
        default: wdat87 = yo7;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_87_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_87_we <= 1'b1; m0_87_wa <= (w_f ? w_hA : w_hB); m0_87_wd <= wdat87; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m0_87_we <= 1'b1; m0_87_wa <= frow; m0_87_wd <= x_in_7; end
        else m0_87_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_87_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_87_we <= 1'b1; m1_87_wa <= (w_f ? w_hA : w_hB); m1_87_wd <= wdat87; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd2) : (fsub == 4'd10))) begin m1_87_we <= 1'b1; m1_87_wa <= frow; m1_87_wd <= x_in_7; end
        else m1_87_we <= 1'b0;
    end
    logic [63:0] wdat88;
    always_comb case (wc88)
        3'd0: wdat88 = yo8;
        3'd1: wdat88 = xo12;
        3'd2: wdat88 = xo24;
        3'd3: wdat88 = yo24;
        3'd4: wdat88 = yo40;
        3'd5: wdat88 = xo44;
        3'd6: wdat88 = xo56;
        default: wdat88 = yo8;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_88_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_88_we <= 1'b1; m0_88_wa <= (w_f ? w_hA : w_hB); m0_88_wd <= wdat88; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m0_88_we <= 1'b1; m0_88_wa <= frow; m0_88_wd <= x_in_0; end
        else m0_88_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_88_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_88_we <= 1'b1; m1_88_wa <= (w_f ? w_hA : w_hB); m1_88_wd <= wdat88; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m1_88_we <= 1'b1; m1_88_wa <= frow; m1_88_wd <= x_in_0; end
        else m1_88_we <= 1'b0;
    end
    logic [63:0] wdat89;
    always_comb case (wc89)
        4'd0: wdat89 = yo9;
        4'd1: wdat89 = yo12;
        4'd2: wdat89 = xo13;
        4'd3: wdat89 = xo25;
        4'd4: wdat89 = yo25;
        4'd5: wdat89 = yo41;
        4'd6: wdat89 = yo44;
        4'd7: wdat89 = xo45;
        4'd8: wdat89 = xo57;
        default: wdat89 = yo9;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_89_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_89_we <= 1'b1; m0_89_wa <= (w_f ? w_hA : w_hB); m0_89_wd <= wdat89; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m0_89_we <= 1'b1; m0_89_wa <= frow; m0_89_wd <= x_in_1; end
        else m0_89_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_89_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_89_we <= 1'b1; m1_89_wa <= (w_f ? w_hA : w_hB); m1_89_wd <= wdat89; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m1_89_we <= 1'b1; m1_89_wa <= frow; m1_89_wd <= x_in_1; end
        else m1_89_we <= 1'b0;
    end
    logic [63:0] wdat90;
    always_comb case (wc90)
        4'd0: wdat90 = yo10;
        4'd1: wdat90 = yo12;
        4'd2: wdat90 = xo13;
        4'd3: wdat90 = xo14;
        4'd4: wdat90 = xo26;
        4'd5: wdat90 = yo26;
        4'd6: wdat90 = yo42;
        4'd7: wdat90 = yo44;
        4'd8: wdat90 = xo45;
        4'd9: wdat90 = xo46;
        4'd10: wdat90 = xo58;
        default: wdat90 = yo10;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_90_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_90_we <= 1'b1; m0_90_wa <= (w_f ? w_hA : w_hB); m0_90_wd <= wdat90; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m0_90_we <= 1'b1; m0_90_wa <= frow; m0_90_wd <= x_in_2; end
        else m0_90_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_90_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_90_we <= 1'b1; m1_90_wa <= (w_f ? w_hA : w_hB); m1_90_wd <= wdat90; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m1_90_we <= 1'b1; m1_90_wa <= frow; m1_90_wd <= x_in_2; end
        else m1_90_we <= 1'b0;
    end
    logic [63:0] wdat91;
    always_comb case (wc91)
        4'd0: wdat91 = yo11;
        4'd1: wdat91 = yo13;
        4'd2: wdat91 = xo15;
        4'd3: wdat91 = xo27;
        4'd4: wdat91 = yo27;
        4'd5: wdat91 = yo43;
        4'd6: wdat91 = yo45;
        4'd7: wdat91 = xo47;
        4'd8: wdat91 = xo59;
        default: wdat91 = yo11;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_91_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_91_we <= 1'b1; m0_91_wa <= (w_f ? w_hA : w_hB); m0_91_wd <= wdat91; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m0_91_we <= 1'b1; m0_91_wa <= frow; m0_91_wd <= x_in_3; end
        else m0_91_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_91_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_91_we <= 1'b1; m1_91_wa <= (w_f ? w_hA : w_hB); m1_91_wd <= wdat91; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m1_91_we <= 1'b1; m1_91_wa <= frow; m1_91_wd <= x_in_3; end
        else m1_91_we <= 1'b0;
    end
    logic [63:0] wdat92;
    always_comb case (wc92)
        3'd0: wdat92 = yo12;
        3'd1: wdat92 = xo14;
        3'd2: wdat92 = xo28;
        3'd3: wdat92 = yo28;
        3'd4: wdat92 = yo44;
        3'd5: wdat92 = xo46;
        3'd6: wdat92 = xo60;
        default: wdat92 = yo12;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_92_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_92_we <= 1'b1; m0_92_wa <= (w_f ? w_hA : w_hB); m0_92_wd <= wdat92; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m0_92_we <= 1'b1; m0_92_wa <= frow; m0_92_wd <= x_in_4; end
        else m0_92_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_92_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_92_we <= 1'b1; m1_92_wa <= (w_f ? w_hA : w_hB); m1_92_wd <= wdat92; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m1_92_we <= 1'b1; m1_92_wa <= frow; m1_92_wd <= x_in_4; end
        else m1_92_we <= 1'b0;
    end
    logic [63:0] wdat93;
    always_comb case (wc93)
        4'd0: wdat93 = yo13;
        4'd1: wdat93 = yo14;
        4'd2: wdat93 = xo15;
        4'd3: wdat93 = xo29;
        4'd4: wdat93 = yo29;
        4'd5: wdat93 = yo45;
        4'd6: wdat93 = yo46;
        4'd7: wdat93 = xo47;
        4'd8: wdat93 = xo61;
        default: wdat93 = yo13;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_93_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_93_we <= 1'b1; m0_93_wa <= (w_f ? w_hA : w_hB); m0_93_wd <= wdat93; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m0_93_we <= 1'b1; m0_93_wa <= frow; m0_93_wd <= x_in_5; end
        else m0_93_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_93_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_93_we <= 1'b1; m1_93_wa <= (w_f ? w_hA : w_hB); m1_93_wd <= wdat93; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m1_93_we <= 1'b1; m1_93_wa <= frow; m1_93_wd <= x_in_5; end
        else m1_93_we <= 1'b0;
    end
    logic [63:0] wdat94;
    always_comb case (wc94)
        3'd0: wdat94 = yo14;
        3'd1: wdat94 = xo15;
        3'd2: wdat94 = xo30;
        3'd3: wdat94 = yo30;
        3'd4: wdat94 = yo46;
        3'd5: wdat94 = xo47;
        3'd6: wdat94 = xo62;
        default: wdat94 = yo14;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_94_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_94_we <= 1'b1; m0_94_wa <= (w_f ? w_hA : w_hB); m0_94_wd <= wdat94; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m0_94_we <= 1'b1; m0_94_wa <= frow; m0_94_wd <= x_in_6; end
        else m0_94_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_94_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_94_we <= 1'b1; m1_94_wa <= (w_f ? w_hA : w_hB); m1_94_wd <= wdat94; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m1_94_we <= 1'b1; m1_94_wa <= frow; m1_94_wd <= x_in_6; end
        else m1_94_we <= 1'b0;
    end
    logic [63:0] wdat95;
    always_comb case (wc95)
        3'd0: wdat95 = yo15;
        3'd1: wdat95 = xo31;
        3'd2: wdat95 = yo31;
        3'd3: wdat95 = yo47;
        3'd4: wdat95 = xo63;
        default: wdat95 = yo15;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_95_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_95_we <= 1'b1; m0_95_wa <= (w_f ? w_hA : w_hB); m0_95_wd <= wdat95; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m0_95_we <= 1'b1; m0_95_wa <= frow; m0_95_wd <= x_in_7; end
        else m0_95_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_95_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_95_we <= 1'b1; m1_95_wa <= (w_f ? w_hA : w_hB); m1_95_wd <= wdat95; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd3) : (fsub == 4'd11))) begin m1_95_we <= 1'b1; m1_95_wa <= frow; m1_95_wd <= x_in_7; end
        else m1_95_we <= 1'b0;
    end
    logic [63:0] wdat96;
    always_comb case (wc96)
        3'd0: wdat96 = yo0;
        3'd1: wdat96 = xo16;
        3'd2: wdat96 = xo32;
        3'd3: wdat96 = yo32;
        3'd4: wdat96 = xo48;
        default: wdat96 = yo0;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_96_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_96_we <= 1'b1; m0_96_wa <= (w_f ? w_hA : w_hB); m0_96_wd <= wdat96; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m0_96_we <= 1'b1; m0_96_wa <= frow; m0_96_wd <= x_in_0; end
        else m0_96_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_96_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_96_we <= 1'b1; m1_96_wa <= (w_f ? w_hA : w_hB); m1_96_wd <= wdat96; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m1_96_we <= 1'b1; m1_96_wa <= frow; m1_96_wd <= x_in_0; end
        else m1_96_we <= 1'b0;
    end
    logic [63:0] wdat97;
    always_comb case (wc97)
        3'd0: wdat97 = yo1;
        3'd1: wdat97 = yo16;
        3'd2: wdat97 = xo17;
        3'd3: wdat97 = xo33;
        3'd4: wdat97 = yo33;
        3'd5: wdat97 = yo48;
        3'd6: wdat97 = xo49;
        default: wdat97 = yo1;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_97_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_97_we <= 1'b1; m0_97_wa <= (w_f ? w_hA : w_hB); m0_97_wd <= wdat97; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m0_97_we <= 1'b1; m0_97_wa <= frow; m0_97_wd <= x_in_1; end
        else m0_97_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_97_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_97_we <= 1'b1; m1_97_wa <= (w_f ? w_hA : w_hB); m1_97_wd <= wdat97; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m1_97_we <= 1'b1; m1_97_wa <= frow; m1_97_wd <= x_in_1; end
        else m1_97_we <= 1'b0;
    end
    logic [63:0] wdat98;
    always_comb case (wc98)
        4'd0: wdat98 = yo2;
        4'd1: wdat98 = yo16;
        4'd2: wdat98 = xo17;
        4'd3: wdat98 = xo18;
        4'd4: wdat98 = xo34;
        4'd5: wdat98 = yo34;
        4'd6: wdat98 = yo48;
        4'd7: wdat98 = xo49;
        4'd8: wdat98 = xo50;
        default: wdat98 = yo2;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_98_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_98_we <= 1'b1; m0_98_wa <= (w_f ? w_hA : w_hB); m0_98_wd <= wdat98; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m0_98_we <= 1'b1; m0_98_wa <= frow; m0_98_wd <= x_in_2; end
        else m0_98_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_98_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_98_we <= 1'b1; m1_98_wa <= (w_f ? w_hA : w_hB); m1_98_wd <= wdat98; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m1_98_we <= 1'b1; m1_98_wa <= frow; m1_98_wd <= x_in_2; end
        else m1_98_we <= 1'b0;
    end
    logic [63:0] wdat99;
    always_comb case (wc99)
        3'd0: wdat99 = yo3;
        3'd1: wdat99 = yo17;
        3'd2: wdat99 = xo19;
        3'd3: wdat99 = xo35;
        3'd4: wdat99 = yo35;
        3'd5: wdat99 = yo49;
        3'd6: wdat99 = xo51;
        default: wdat99 = yo3;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_99_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_99_we <= 1'b1; m0_99_wa <= (w_f ? w_hA : w_hB); m0_99_wd <= wdat99; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m0_99_we <= 1'b1; m0_99_wa <= frow; m0_99_wd <= x_in_3; end
        else m0_99_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_99_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_99_we <= 1'b1; m1_99_wa <= (w_f ? w_hA : w_hB); m1_99_wd <= wdat99; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m1_99_we <= 1'b1; m1_99_wa <= frow; m1_99_wd <= x_in_3; end
        else m1_99_we <= 1'b0;
    end
    logic [63:0] wdat100;
    always_comb case (wc100)
        4'd0: wdat100 = yo4;
        4'd1: wdat100 = yo16;
        4'd2: wdat100 = xo18;
        4'd3: wdat100 = xo20;
        4'd4: wdat100 = xo36;
        4'd5: wdat100 = yo36;
        4'd6: wdat100 = yo48;
        4'd7: wdat100 = xo50;
        4'd8: wdat100 = xo52;
        default: wdat100 = yo4;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_100_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_100_we <= 1'b1; m0_100_wa <= (w_f ? w_hA : w_hB); m0_100_wd <= wdat100; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m0_100_we <= 1'b1; m0_100_wa <= frow; m0_100_wd <= x_in_4; end
        else m0_100_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_100_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_100_we <= 1'b1; m1_100_wa <= (w_f ? w_hA : w_hB); m1_100_wd <= wdat100; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m1_100_we <= 1'b1; m1_100_wa <= frow; m1_100_wd <= x_in_4; end
        else m1_100_we <= 1'b0;
    end
    logic [63:0] wdat101;
    always_comb case (wc101)
        4'd0: wdat101 = yo5;
        4'd1: wdat101 = yo17;
        4'd2: wdat101 = yo18;
        4'd3: wdat101 = xo19;
        4'd4: wdat101 = xo21;
        4'd5: wdat101 = xo37;
        4'd6: wdat101 = yo37;
        4'd7: wdat101 = yo49;
        4'd8: wdat101 = yo50;
        4'd9: wdat101 = xo51;
        4'd10: wdat101 = xo53;
        default: wdat101 = yo5;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_101_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_101_we <= 1'b1; m0_101_wa <= (w_f ? w_hA : w_hB); m0_101_wd <= wdat101; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m0_101_we <= 1'b1; m0_101_wa <= frow; m0_101_wd <= x_in_5; end
        else m0_101_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_101_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_101_we <= 1'b1; m1_101_wa <= (w_f ? w_hA : w_hB); m1_101_wd <= wdat101; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m1_101_we <= 1'b1; m1_101_wa <= frow; m1_101_wd <= x_in_5; end
        else m1_101_we <= 1'b0;
    end
    logic [63:0] wdat102;
    always_comb case (wc102)
        4'd0: wdat102 = yo6;
        4'd1: wdat102 = yo18;
        4'd2: wdat102 = xo19;
        4'd3: wdat102 = xo22;
        4'd4: wdat102 = xo38;
        4'd5: wdat102 = yo38;
        4'd6: wdat102 = yo50;
        4'd7: wdat102 = xo51;
        4'd8: wdat102 = xo54;
        default: wdat102 = yo6;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_102_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_102_we <= 1'b1; m0_102_wa <= (w_f ? w_hA : w_hB); m0_102_wd <= wdat102; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m0_102_we <= 1'b1; m0_102_wa <= frow; m0_102_wd <= x_in_6; end
        else m0_102_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_102_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_102_we <= 1'b1; m1_102_wa <= (w_f ? w_hA : w_hB); m1_102_wd <= wdat102; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m1_102_we <= 1'b1; m1_102_wa <= frow; m1_102_wd <= x_in_6; end
        else m1_102_we <= 1'b0;
    end
    logic [63:0] wdat103;
    always_comb case (wc103)
        3'd0: wdat103 = yo7;
        3'd1: wdat103 = yo19;
        3'd2: wdat103 = xo23;
        3'd3: wdat103 = xo39;
        3'd4: wdat103 = yo39;
        3'd5: wdat103 = yo51;
        3'd6: wdat103 = xo55;
        default: wdat103 = yo7;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_103_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_103_we <= 1'b1; m0_103_wa <= (w_f ? w_hA : w_hB); m0_103_wd <= wdat103; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m0_103_we <= 1'b1; m0_103_wa <= frow; m0_103_wd <= x_in_7; end
        else m0_103_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_103_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_103_we <= 1'b1; m1_103_wa <= (w_f ? w_hA : w_hB); m1_103_wd <= wdat103; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd4) : (fsub == 4'd12))) begin m1_103_we <= 1'b1; m1_103_wa <= frow; m1_103_wd <= x_in_7; end
        else m1_103_we <= 1'b0;
    end
    logic [63:0] wdat104;
    always_comb case (wc104)
        4'd0: wdat104 = yo8;
        4'd1: wdat104 = yo16;
        4'd2: wdat104 = xo20;
        4'd3: wdat104 = xo24;
        4'd4: wdat104 = xo40;
        4'd5: wdat104 = yo40;
        4'd6: wdat104 = yo48;
        4'd7: wdat104 = xo52;
        4'd8: wdat104 = xo56;
        default: wdat104 = yo8;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_104_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_104_we <= 1'b1; m0_104_wa <= (w_f ? w_hA : w_hB); m0_104_wd <= wdat104; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m0_104_we <= 1'b1; m0_104_wa <= frow; m0_104_wd <= x_in_0; end
        else m0_104_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_104_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_104_we <= 1'b1; m1_104_wa <= (w_f ? w_hA : w_hB); m1_104_wd <= wdat104; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m1_104_we <= 1'b1; m1_104_wa <= frow; m1_104_wd <= x_in_0; end
        else m1_104_we <= 1'b0;
    end
    logic [63:0] wdat105;
    always_comb case (wc105)
        4'd0: wdat105 = yo9;
        4'd1: wdat105 = yo17;
        4'd2: wdat105 = yo20;
        4'd3: wdat105 = xo21;
        4'd4: wdat105 = xo25;
        4'd5: wdat105 = xo41;
        4'd6: wdat105 = yo41;
        4'd7: wdat105 = yo49;
        4'd8: wdat105 = yo52;
        4'd9: wdat105 = xo53;
        4'd10: wdat105 = xo57;
        default: wdat105 = yo9;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_105_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_105_we <= 1'b1; m0_105_wa <= (w_f ? w_hA : w_hB); m0_105_wd <= wdat105; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m0_105_we <= 1'b1; m0_105_wa <= frow; m0_105_wd <= x_in_1; end
        else m0_105_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_105_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_105_we <= 1'b1; m1_105_wa <= (w_f ? w_hA : w_hB); m1_105_wd <= wdat105; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m1_105_we <= 1'b1; m1_105_wa <= frow; m1_105_wd <= x_in_1; end
        else m1_105_we <= 1'b0;
    end
    logic [63:0] wdat106;
    always_comb case (wc106)
        4'd0: wdat106 = yo10;
        4'd1: wdat106 = yo18;
        4'd2: wdat106 = yo20;
        4'd3: wdat106 = xo21;
        4'd4: wdat106 = xo22;
        4'd5: wdat106 = xo26;
        4'd6: wdat106 = xo42;
        4'd7: wdat106 = yo42;
        4'd8: wdat106 = yo50;
        4'd9: wdat106 = yo52;
        4'd10: wdat106 = xo53;
        4'd11: wdat106 = xo54;
        4'd12: wdat106 = xo58;
        default: wdat106 = yo10;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_106_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_106_we <= 1'b1; m0_106_wa <= (w_f ? w_hA : w_hB); m0_106_wd <= wdat106; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m0_106_we <= 1'b1; m0_106_wa <= frow; m0_106_wd <= x_in_2; end
        else m0_106_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_106_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_106_we <= 1'b1; m1_106_wa <= (w_f ? w_hA : w_hB); m1_106_wd <= wdat106; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m1_106_we <= 1'b1; m1_106_wa <= frow; m1_106_wd <= x_in_2; end
        else m1_106_we <= 1'b0;
    end
    logic [63:0] wdat107;
    always_comb case (wc107)
        4'd0: wdat107 = yo11;
        4'd1: wdat107 = yo19;
        4'd2: wdat107 = yo21;
        4'd3: wdat107 = xo23;
        4'd4: wdat107 = xo27;
        4'd5: wdat107 = xo43;
        4'd6: wdat107 = yo43;
        4'd7: wdat107 = yo51;
        4'd8: wdat107 = yo53;
        4'd9: wdat107 = xo55;
        4'd10: wdat107 = xo59;
        default: wdat107 = yo11;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_107_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_107_we <= 1'b1; m0_107_wa <= (w_f ? w_hA : w_hB); m0_107_wd <= wdat107; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m0_107_we <= 1'b1; m0_107_wa <= frow; m0_107_wd <= x_in_3; end
        else m0_107_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_107_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_107_we <= 1'b1; m1_107_wa <= (w_f ? w_hA : w_hB); m1_107_wd <= wdat107; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m1_107_we <= 1'b1; m1_107_wa <= frow; m1_107_wd <= x_in_3; end
        else m1_107_we <= 1'b0;
    end
    logic [63:0] wdat108;
    always_comb case (wc108)
        4'd0: wdat108 = yo12;
        4'd1: wdat108 = yo20;
        4'd2: wdat108 = xo22;
        4'd3: wdat108 = xo28;
        4'd4: wdat108 = xo44;
        4'd5: wdat108 = yo44;
        4'd6: wdat108 = yo52;
        4'd7: wdat108 = xo54;
        4'd8: wdat108 = xo60;
        default: wdat108 = yo12;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_108_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_108_we <= 1'b1; m0_108_wa <= (w_f ? w_hA : w_hB); m0_108_wd <= wdat108; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m0_108_we <= 1'b1; m0_108_wa <= frow; m0_108_wd <= x_in_4; end
        else m0_108_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_108_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_108_we <= 1'b1; m1_108_wa <= (w_f ? w_hA : w_hB); m1_108_wd <= wdat108; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m1_108_we <= 1'b1; m1_108_wa <= frow; m1_108_wd <= x_in_4; end
        else m1_108_we <= 1'b0;
    end
    logic [63:0] wdat109;
    always_comb case (wc109)
        4'd0: wdat109 = yo13;
        4'd1: wdat109 = yo21;
        4'd2: wdat109 = yo22;
        4'd3: wdat109 = xo23;
        4'd4: wdat109 = xo29;
        4'd5: wdat109 = xo45;
        4'd6: wdat109 = yo45;
        4'd7: wdat109 = yo53;
        4'd8: wdat109 = yo54;
        4'd9: wdat109 = xo55;
        4'd10: wdat109 = xo61;
        default: wdat109 = yo13;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_109_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_109_we <= 1'b1; m0_109_wa <= (w_f ? w_hA : w_hB); m0_109_wd <= wdat109; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m0_109_we <= 1'b1; m0_109_wa <= frow; m0_109_wd <= x_in_5; end
        else m0_109_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_109_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_109_we <= 1'b1; m1_109_wa <= (w_f ? w_hA : w_hB); m1_109_wd <= wdat109; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m1_109_we <= 1'b1; m1_109_wa <= frow; m1_109_wd <= x_in_5; end
        else m1_109_we <= 1'b0;
    end
    logic [63:0] wdat110;
    always_comb case (wc110)
        4'd0: wdat110 = yo14;
        4'd1: wdat110 = yo22;
        4'd2: wdat110 = xo23;
        4'd3: wdat110 = xo30;
        4'd4: wdat110 = xo46;
        4'd5: wdat110 = yo46;
        4'd6: wdat110 = yo54;
        4'd7: wdat110 = xo55;
        4'd8: wdat110 = xo62;
        default: wdat110 = yo14;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_110_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_110_we <= 1'b1; m0_110_wa <= (w_f ? w_hA : w_hB); m0_110_wd <= wdat110; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m0_110_we <= 1'b1; m0_110_wa <= frow; m0_110_wd <= x_in_6; end
        else m0_110_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_110_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_110_we <= 1'b1; m1_110_wa <= (w_f ? w_hA : w_hB); m1_110_wd <= wdat110; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m1_110_we <= 1'b1; m1_110_wa <= frow; m1_110_wd <= x_in_6; end
        else m1_110_we <= 1'b0;
    end
    logic [63:0] wdat111;
    always_comb case (wc111)
        3'd0: wdat111 = yo15;
        3'd1: wdat111 = yo23;
        3'd2: wdat111 = xo31;
        3'd3: wdat111 = xo47;
        3'd4: wdat111 = yo47;
        3'd5: wdat111 = yo55;
        3'd6: wdat111 = xo63;
        default: wdat111 = yo15;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_111_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_111_we <= 1'b1; m0_111_wa <= (w_f ? w_hA : w_hB); m0_111_wd <= wdat111; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m0_111_we <= 1'b1; m0_111_wa <= frow; m0_111_wd <= x_in_7; end
        else m0_111_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_111_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_111_we <= 1'b1; m1_111_wa <= (w_f ? w_hA : w_hB); m1_111_wd <= wdat111; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd5) : (fsub == 4'd13))) begin m1_111_we <= 1'b1; m1_111_wa <= frow; m1_111_wd <= x_in_7; end
        else m1_111_we <= 1'b0;
    end
    logic [63:0] wdat112;
    always_comb case (wc112)
        3'd0: wdat112 = yo16;
        3'd1: wdat112 = xo24;
        3'd2: wdat112 = xo48;
        3'd3: wdat112 = yo48;
        3'd4: wdat112 = xo56;
        default: wdat112 = yo16;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_112_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_112_we <= 1'b1; m0_112_wa <= (w_f ? w_hA : w_hB); m0_112_wd <= wdat112; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m0_112_we <= 1'b1; m0_112_wa <= frow; m0_112_wd <= x_in_0; end
        else m0_112_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_112_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_112_we <= 1'b1; m1_112_wa <= (w_f ? w_hA : w_hB); m1_112_wd <= wdat112; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m1_112_we <= 1'b1; m1_112_wa <= frow; m1_112_wd <= x_in_0; end
        else m1_112_we <= 1'b0;
    end
    logic [63:0] wdat113;
    always_comb case (wc113)
        3'd0: wdat113 = yo17;
        3'd1: wdat113 = yo24;
        3'd2: wdat113 = xo25;
        3'd3: wdat113 = xo49;
        3'd4: wdat113 = yo49;
        3'd5: wdat113 = yo56;
        3'd6: wdat113 = xo57;
        default: wdat113 = yo17;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_113_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_113_we <= 1'b1; m0_113_wa <= (w_f ? w_hA : w_hB); m0_113_wd <= wdat113; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m0_113_we <= 1'b1; m0_113_wa <= frow; m0_113_wd <= x_in_1; end
        else m0_113_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_113_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_113_we <= 1'b1; m1_113_wa <= (w_f ? w_hA : w_hB); m1_113_wd <= wdat113; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m1_113_we <= 1'b1; m1_113_wa <= frow; m1_113_wd <= x_in_1; end
        else m1_113_we <= 1'b0;
    end
    logic [63:0] wdat114;
    always_comb case (wc114)
        4'd0: wdat114 = yo18;
        4'd1: wdat114 = yo24;
        4'd2: wdat114 = xo25;
        4'd3: wdat114 = xo26;
        4'd4: wdat114 = xo50;
        4'd5: wdat114 = yo50;
        4'd6: wdat114 = yo56;
        4'd7: wdat114 = xo57;
        4'd8: wdat114 = xo58;
        default: wdat114 = yo18;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_114_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_114_we <= 1'b1; m0_114_wa <= (w_f ? w_hA : w_hB); m0_114_wd <= wdat114; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m0_114_we <= 1'b1; m0_114_wa <= frow; m0_114_wd <= x_in_2; end
        else m0_114_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_114_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_114_we <= 1'b1; m1_114_wa <= (w_f ? w_hA : w_hB); m1_114_wd <= wdat114; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m1_114_we <= 1'b1; m1_114_wa <= frow; m1_114_wd <= x_in_2; end
        else m1_114_we <= 1'b0;
    end
    logic [63:0] wdat115;
    always_comb case (wc115)
        3'd0: wdat115 = yo19;
        3'd1: wdat115 = yo25;
        3'd2: wdat115 = xo27;
        3'd3: wdat115 = xo51;
        3'd4: wdat115 = yo51;
        3'd5: wdat115 = yo57;
        3'd6: wdat115 = xo59;
        default: wdat115 = yo19;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_115_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_115_we <= 1'b1; m0_115_wa <= (w_f ? w_hA : w_hB); m0_115_wd <= wdat115; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m0_115_we <= 1'b1; m0_115_wa <= frow; m0_115_wd <= x_in_3; end
        else m0_115_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_115_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_115_we <= 1'b1; m1_115_wa <= (w_f ? w_hA : w_hB); m1_115_wd <= wdat115; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m1_115_we <= 1'b1; m1_115_wa <= frow; m1_115_wd <= x_in_3; end
        else m1_115_we <= 1'b0;
    end
    logic [63:0] wdat116;
    always_comb case (wc116)
        4'd0: wdat116 = yo20;
        4'd1: wdat116 = yo24;
        4'd2: wdat116 = xo26;
        4'd3: wdat116 = xo28;
        4'd4: wdat116 = xo52;
        4'd5: wdat116 = yo52;
        4'd6: wdat116 = yo56;
        4'd7: wdat116 = xo58;
        4'd8: wdat116 = xo60;
        default: wdat116 = yo20;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_116_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_116_we <= 1'b1; m0_116_wa <= (w_f ? w_hA : w_hB); m0_116_wd <= wdat116; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m0_116_we <= 1'b1; m0_116_wa <= frow; m0_116_wd <= x_in_4; end
        else m0_116_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_116_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_116_we <= 1'b1; m1_116_wa <= (w_f ? w_hA : w_hB); m1_116_wd <= wdat116; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m1_116_we <= 1'b1; m1_116_wa <= frow; m1_116_wd <= x_in_4; end
        else m1_116_we <= 1'b0;
    end
    logic [63:0] wdat117;
    always_comb case (wc117)
        4'd0: wdat117 = yo21;
        4'd1: wdat117 = yo25;
        4'd2: wdat117 = yo26;
        4'd3: wdat117 = xo27;
        4'd4: wdat117 = xo29;
        4'd5: wdat117 = xo53;
        4'd6: wdat117 = yo53;
        4'd7: wdat117 = yo57;
        4'd8: wdat117 = yo58;
        4'd9: wdat117 = xo59;
        4'd10: wdat117 = xo61;
        default: wdat117 = yo21;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_117_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_117_we <= 1'b1; m0_117_wa <= (w_f ? w_hA : w_hB); m0_117_wd <= wdat117; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m0_117_we <= 1'b1; m0_117_wa <= frow; m0_117_wd <= x_in_5; end
        else m0_117_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_117_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_117_we <= 1'b1; m1_117_wa <= (w_f ? w_hA : w_hB); m1_117_wd <= wdat117; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m1_117_we <= 1'b1; m1_117_wa <= frow; m1_117_wd <= x_in_5; end
        else m1_117_we <= 1'b0;
    end
    logic [63:0] wdat118;
    always_comb case (wc118)
        4'd0: wdat118 = yo22;
        4'd1: wdat118 = yo26;
        4'd2: wdat118 = xo27;
        4'd3: wdat118 = xo30;
        4'd4: wdat118 = xo54;
        4'd5: wdat118 = yo54;
        4'd6: wdat118 = yo58;
        4'd7: wdat118 = xo59;
        4'd8: wdat118 = xo62;
        default: wdat118 = yo22;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_118_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_118_we <= 1'b1; m0_118_wa <= (w_f ? w_hA : w_hB); m0_118_wd <= wdat118; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m0_118_we <= 1'b1; m0_118_wa <= frow; m0_118_wd <= x_in_6; end
        else m0_118_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_118_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_118_we <= 1'b1; m1_118_wa <= (w_f ? w_hA : w_hB); m1_118_wd <= wdat118; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m1_118_we <= 1'b1; m1_118_wa <= frow; m1_118_wd <= x_in_6; end
        else m1_118_we <= 1'b0;
    end
    logic [63:0] wdat119;
    always_comb case (wc119)
        3'd0: wdat119 = yo23;
        3'd1: wdat119 = yo27;
        3'd2: wdat119 = xo31;
        3'd3: wdat119 = xo55;
        3'd4: wdat119 = yo55;
        3'd5: wdat119 = yo59;
        3'd6: wdat119 = xo63;
        default: wdat119 = yo23;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_119_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_119_we <= 1'b1; m0_119_wa <= (w_f ? w_hA : w_hB); m0_119_wd <= wdat119; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m0_119_we <= 1'b1; m0_119_wa <= frow; m0_119_wd <= x_in_7; end
        else m0_119_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_119_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_119_we <= 1'b1; m1_119_wa <= (w_f ? w_hA : w_hB); m1_119_wd <= wdat119; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd6) : (fsub == 4'd14))) begin m1_119_we <= 1'b1; m1_119_wa <= frow; m1_119_wd <= x_in_7; end
        else m1_119_we <= 1'b0;
    end
    logic [63:0] wdat120;
    always_comb case (wc120)
        3'd0: wdat120 = yo24;
        3'd1: wdat120 = xo28;
        3'd2: wdat120 = xo56;
        3'd3: wdat120 = yo56;
        3'd4: wdat120 = xo60;
        default: wdat120 = yo24;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_120_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_120_we <= 1'b1; m0_120_wa <= (w_f ? w_hA : w_hB); m0_120_wd <= wdat120; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m0_120_we <= 1'b1; m0_120_wa <= frow; m0_120_wd <= x_in_0; end
        else m0_120_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_120_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_120_we <= 1'b1; m1_120_wa <= (w_f ? w_hA : w_hB); m1_120_wd <= wdat120; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m1_120_we <= 1'b1; m1_120_wa <= frow; m1_120_wd <= x_in_0; end
        else m1_120_we <= 1'b0;
    end
    logic [63:0] wdat121;
    always_comb case (wc121)
        3'd0: wdat121 = yo25;
        3'd1: wdat121 = yo28;
        3'd2: wdat121 = xo29;
        3'd3: wdat121 = xo57;
        3'd4: wdat121 = yo57;
        3'd5: wdat121 = yo60;
        3'd6: wdat121 = xo61;
        default: wdat121 = yo25;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_121_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_121_we <= 1'b1; m0_121_wa <= (w_f ? w_hA : w_hB); m0_121_wd <= wdat121; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m0_121_we <= 1'b1; m0_121_wa <= frow; m0_121_wd <= x_in_1; end
        else m0_121_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_121_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_121_we <= 1'b1; m1_121_wa <= (w_f ? w_hA : w_hB); m1_121_wd <= wdat121; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m1_121_we <= 1'b1; m1_121_wa <= frow; m1_121_wd <= x_in_1; end
        else m1_121_we <= 1'b0;
    end
    logic [63:0] wdat122;
    always_comb case (wc122)
        4'd0: wdat122 = yo26;
        4'd1: wdat122 = yo28;
        4'd2: wdat122 = xo29;
        4'd3: wdat122 = xo30;
        4'd4: wdat122 = xo58;
        4'd5: wdat122 = yo58;
        4'd6: wdat122 = yo60;
        4'd7: wdat122 = xo61;
        4'd8: wdat122 = xo62;
        default: wdat122 = yo26;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_122_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_122_we <= 1'b1; m0_122_wa <= (w_f ? w_hA : w_hB); m0_122_wd <= wdat122; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m0_122_we <= 1'b1; m0_122_wa <= frow; m0_122_wd <= x_in_2; end
        else m0_122_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_122_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_122_we <= 1'b1; m1_122_wa <= (w_f ? w_hA : w_hB); m1_122_wd <= wdat122; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m1_122_we <= 1'b1; m1_122_wa <= frow; m1_122_wd <= x_in_2; end
        else m1_122_we <= 1'b0;
    end
    logic [63:0] wdat123;
    always_comb case (wc123)
        3'd0: wdat123 = yo27;
        3'd1: wdat123 = yo29;
        3'd2: wdat123 = xo31;
        3'd3: wdat123 = xo59;
        3'd4: wdat123 = yo59;
        3'd5: wdat123 = yo61;
        3'd6: wdat123 = xo63;
        default: wdat123 = yo27;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_123_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_123_we <= 1'b1; m0_123_wa <= (w_f ? w_hA : w_hB); m0_123_wd <= wdat123; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m0_123_we <= 1'b1; m0_123_wa <= frow; m0_123_wd <= x_in_3; end
        else m0_123_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_123_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_123_we <= 1'b1; m1_123_wa <= (w_f ? w_hA : w_hB); m1_123_wd <= wdat123; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m1_123_we <= 1'b1; m1_123_wa <= frow; m1_123_wd <= x_in_3; end
        else m1_123_we <= 1'b0;
    end
    logic [63:0] wdat124;
    always_comb case (wc124)
        3'd0: wdat124 = yo28;
        3'd1: wdat124 = xo30;
        3'd2: wdat124 = xo60;
        3'd3: wdat124 = yo60;
        3'd4: wdat124 = xo62;
        default: wdat124 = yo28;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_124_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_124_we <= 1'b1; m0_124_wa <= (w_f ? w_hA : w_hB); m0_124_wd <= wdat124; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m0_124_we <= 1'b1; m0_124_wa <= frow; m0_124_wd <= x_in_4; end
        else m0_124_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_124_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_124_we <= 1'b1; m1_124_wa <= (w_f ? w_hA : w_hB); m1_124_wd <= wdat124; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m1_124_we <= 1'b1; m1_124_wa <= frow; m1_124_wd <= x_in_4; end
        else m1_124_we <= 1'b0;
    end
    logic [63:0] wdat125;
    always_comb case (wc125)
        3'd0: wdat125 = yo29;
        3'd1: wdat125 = yo30;
        3'd2: wdat125 = xo31;
        3'd3: wdat125 = xo61;
        3'd4: wdat125 = yo61;
        3'd5: wdat125 = yo62;
        3'd6: wdat125 = xo63;
        default: wdat125 = yo29;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_125_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_125_we <= 1'b1; m0_125_wa <= (w_f ? w_hA : w_hB); m0_125_wd <= wdat125; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m0_125_we <= 1'b1; m0_125_wa <= frow; m0_125_wd <= x_in_5; end
        else m0_125_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_125_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_125_we <= 1'b1; m1_125_wa <= (w_f ? w_hA : w_hB); m1_125_wd <= wdat125; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m1_125_we <= 1'b1; m1_125_wa <= frow; m1_125_wd <= x_in_5; end
        else m1_125_we <= 1'b0;
    end
    logic [63:0] wdat126;
    always_comb case (wc126)
        3'd0: wdat126 = yo30;
        3'd1: wdat126 = xo31;
        3'd2: wdat126 = xo62;
        3'd3: wdat126 = yo62;
        3'd4: wdat126 = xo63;
        default: wdat126 = yo30;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_126_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_126_we <= 1'b1; m0_126_wa <= (w_f ? w_hA : w_hB); m0_126_wd <= wdat126; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m0_126_we <= 1'b1; m0_126_wa <= frow; m0_126_wd <= x_in_6; end
        else m0_126_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_126_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_126_we <= 1'b1; m1_126_wa <= (w_f ? w_hA : w_hB); m1_126_wd <= wdat126; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m1_126_we <= 1'b1; m1_126_wa <= frow; m1_126_wd <= x_in_6; end
        else m1_126_we <= 1'b0;
    end
    logic [63:0] wdat127;
    always_comb case (wc127)
        2'd0: wdat127 = yo31;
        2'd1: wdat127 = xo63;
        2'd2: wdat127 = yo63;
        default: wdat127 = yo31;
    endcase
    always_ff @(posedge clk) begin
        if (rst) m0_127_we <= 1'b0;
        else if (w_v && w_set == 1'b0) begin m0_127_we <= 1'b1; m0_127_wa <= (w_f ? w_hA : w_hB); m0_127_wd <= wdat127; end
        else if (acc && fset == 1'b0 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m0_127_we <= 1'b1; m0_127_wa <= frow; m0_127_wd <= x_in_7; end
        else m0_127_we <= 1'b0;
    end
    always_ff @(posedge clk) begin
        if (rst) m1_127_we <= 1'b0;
        else if (w_v && w_set == 1'b1) begin m1_127_we <= 1'b1; m1_127_wa <= (w_f ? w_hA : w_hB); m1_127_wd <= wdat127; end
        else if (acc && fset == 1'b1 && (fpi ? (fsub == 4'd7) : (fsub == 4'd15))) begin m1_127_we <= 1'b1; m1_127_wa <= frow; m1_127_wd <= x_in_7; end
        else m1_127_we <= 1'b0;
    end
    // ---- output: lane l of beat (row, sub) is bank ((sub*io + l) ^ (parity(row) << b))
    logic [63:0] drd0; assign drd0 = db_set[2] ? m1_0_rd : m0_0_rd;
    logic [63:0] drd1; assign drd1 = db_set[2] ? m1_1_rd : m0_1_rd;
    logic [63:0] drd2; assign drd2 = db_set[2] ? m1_2_rd : m0_2_rd;
    logic [63:0] drd3; assign drd3 = db_set[2] ? m1_3_rd : m0_3_rd;
    logic [63:0] drd4; assign drd4 = db_set[2] ? m1_4_rd : m0_4_rd;
    logic [63:0] drd5; assign drd5 = db_set[2] ? m1_5_rd : m0_5_rd;
    logic [63:0] drd6; assign drd6 = db_set[2] ? m1_6_rd : m0_6_rd;
    logic [63:0] drd7; assign drd7 = db_set[2] ? m1_7_rd : m0_7_rd;
    logic [63:0] drd8; assign drd8 = db_set[2] ? m1_8_rd : m0_8_rd;
    logic [63:0] drd9; assign drd9 = db_set[2] ? m1_9_rd : m0_9_rd;
    logic [63:0] drd10; assign drd10 = db_set[2] ? m1_10_rd : m0_10_rd;
    logic [63:0] drd11; assign drd11 = db_set[2] ? m1_11_rd : m0_11_rd;
    logic [63:0] drd12; assign drd12 = db_set[2] ? m1_12_rd : m0_12_rd;
    logic [63:0] drd13; assign drd13 = db_set[2] ? m1_13_rd : m0_13_rd;
    logic [63:0] drd14; assign drd14 = db_set[2] ? m1_14_rd : m0_14_rd;
    logic [63:0] drd15; assign drd15 = db_set[2] ? m1_15_rd : m0_15_rd;
    logic [63:0] drd16; assign drd16 = db_set[2] ? m1_16_rd : m0_16_rd;
    logic [63:0] drd17; assign drd17 = db_set[2] ? m1_17_rd : m0_17_rd;
    logic [63:0] drd18; assign drd18 = db_set[2] ? m1_18_rd : m0_18_rd;
    logic [63:0] drd19; assign drd19 = db_set[2] ? m1_19_rd : m0_19_rd;
    logic [63:0] drd20; assign drd20 = db_set[2] ? m1_20_rd : m0_20_rd;
    logic [63:0] drd21; assign drd21 = db_set[2] ? m1_21_rd : m0_21_rd;
    logic [63:0] drd22; assign drd22 = db_set[2] ? m1_22_rd : m0_22_rd;
    logic [63:0] drd23; assign drd23 = db_set[2] ? m1_23_rd : m0_23_rd;
    logic [63:0] drd24; assign drd24 = db_set[2] ? m1_24_rd : m0_24_rd;
    logic [63:0] drd25; assign drd25 = db_set[2] ? m1_25_rd : m0_25_rd;
    logic [63:0] drd26; assign drd26 = db_set[2] ? m1_26_rd : m0_26_rd;
    logic [63:0] drd27; assign drd27 = db_set[2] ? m1_27_rd : m0_27_rd;
    logic [63:0] drd28; assign drd28 = db_set[2] ? m1_28_rd : m0_28_rd;
    logic [63:0] drd29; assign drd29 = db_set[2] ? m1_29_rd : m0_29_rd;
    logic [63:0] drd30; assign drd30 = db_set[2] ? m1_30_rd : m0_30_rd;
    logic [63:0] drd31; assign drd31 = db_set[2] ? m1_31_rd : m0_31_rd;
    logic [63:0] drd32; assign drd32 = db_set[2] ? m1_32_rd : m0_32_rd;
    logic [63:0] drd33; assign drd33 = db_set[2] ? m1_33_rd : m0_33_rd;
    logic [63:0] drd34; assign drd34 = db_set[2] ? m1_34_rd : m0_34_rd;
    logic [63:0] drd35; assign drd35 = db_set[2] ? m1_35_rd : m0_35_rd;
    logic [63:0] drd36; assign drd36 = db_set[2] ? m1_36_rd : m0_36_rd;
    logic [63:0] drd37; assign drd37 = db_set[2] ? m1_37_rd : m0_37_rd;
    logic [63:0] drd38; assign drd38 = db_set[2] ? m1_38_rd : m0_38_rd;
    logic [63:0] drd39; assign drd39 = db_set[2] ? m1_39_rd : m0_39_rd;
    logic [63:0] drd40; assign drd40 = db_set[2] ? m1_40_rd : m0_40_rd;
    logic [63:0] drd41; assign drd41 = db_set[2] ? m1_41_rd : m0_41_rd;
    logic [63:0] drd42; assign drd42 = db_set[2] ? m1_42_rd : m0_42_rd;
    logic [63:0] drd43; assign drd43 = db_set[2] ? m1_43_rd : m0_43_rd;
    logic [63:0] drd44; assign drd44 = db_set[2] ? m1_44_rd : m0_44_rd;
    logic [63:0] drd45; assign drd45 = db_set[2] ? m1_45_rd : m0_45_rd;
    logic [63:0] drd46; assign drd46 = db_set[2] ? m1_46_rd : m0_46_rd;
    logic [63:0] drd47; assign drd47 = db_set[2] ? m1_47_rd : m0_47_rd;
    logic [63:0] drd48; assign drd48 = db_set[2] ? m1_48_rd : m0_48_rd;
    logic [63:0] drd49; assign drd49 = db_set[2] ? m1_49_rd : m0_49_rd;
    logic [63:0] drd50; assign drd50 = db_set[2] ? m1_50_rd : m0_50_rd;
    logic [63:0] drd51; assign drd51 = db_set[2] ? m1_51_rd : m0_51_rd;
    logic [63:0] drd52; assign drd52 = db_set[2] ? m1_52_rd : m0_52_rd;
    logic [63:0] drd53; assign drd53 = db_set[2] ? m1_53_rd : m0_53_rd;
    logic [63:0] drd54; assign drd54 = db_set[2] ? m1_54_rd : m0_54_rd;
    logic [63:0] drd55; assign drd55 = db_set[2] ? m1_55_rd : m0_55_rd;
    logic [63:0] drd56; assign drd56 = db_set[2] ? m1_56_rd : m0_56_rd;
    logic [63:0] drd57; assign drd57 = db_set[2] ? m1_57_rd : m0_57_rd;
    logic [63:0] drd58; assign drd58 = db_set[2] ? m1_58_rd : m0_58_rd;
    logic [63:0] drd59; assign drd59 = db_set[2] ? m1_59_rd : m0_59_rd;
    logic [63:0] drd60; assign drd60 = db_set[2] ? m1_60_rd : m0_60_rd;
    logic [63:0] drd61; assign drd61 = db_set[2] ? m1_61_rd : m0_61_rd;
    logic [63:0] drd62; assign drd62 = db_set[2] ? m1_62_rd : m0_62_rd;
    logic [63:0] drd63; assign drd63 = db_set[2] ? m1_63_rd : m0_63_rd;
    logic [63:0] drd64; assign drd64 = db_set[2] ? m1_64_rd : m0_64_rd;
    logic [63:0] drd65; assign drd65 = db_set[2] ? m1_65_rd : m0_65_rd;
    logic [63:0] drd66; assign drd66 = db_set[2] ? m1_66_rd : m0_66_rd;
    logic [63:0] drd67; assign drd67 = db_set[2] ? m1_67_rd : m0_67_rd;
    logic [63:0] drd68; assign drd68 = db_set[2] ? m1_68_rd : m0_68_rd;
    logic [63:0] drd69; assign drd69 = db_set[2] ? m1_69_rd : m0_69_rd;
    logic [63:0] drd70; assign drd70 = db_set[2] ? m1_70_rd : m0_70_rd;
    logic [63:0] drd71; assign drd71 = db_set[2] ? m1_71_rd : m0_71_rd;
    logic [63:0] drd72; assign drd72 = db_set[2] ? m1_72_rd : m0_72_rd;
    logic [63:0] drd73; assign drd73 = db_set[2] ? m1_73_rd : m0_73_rd;
    logic [63:0] drd74; assign drd74 = db_set[2] ? m1_74_rd : m0_74_rd;
    logic [63:0] drd75; assign drd75 = db_set[2] ? m1_75_rd : m0_75_rd;
    logic [63:0] drd76; assign drd76 = db_set[2] ? m1_76_rd : m0_76_rd;
    logic [63:0] drd77; assign drd77 = db_set[2] ? m1_77_rd : m0_77_rd;
    logic [63:0] drd78; assign drd78 = db_set[2] ? m1_78_rd : m0_78_rd;
    logic [63:0] drd79; assign drd79 = db_set[2] ? m1_79_rd : m0_79_rd;
    logic [63:0] drd80; assign drd80 = db_set[2] ? m1_80_rd : m0_80_rd;
    logic [63:0] drd81; assign drd81 = db_set[2] ? m1_81_rd : m0_81_rd;
    logic [63:0] drd82; assign drd82 = db_set[2] ? m1_82_rd : m0_82_rd;
    logic [63:0] drd83; assign drd83 = db_set[2] ? m1_83_rd : m0_83_rd;
    logic [63:0] drd84; assign drd84 = db_set[2] ? m1_84_rd : m0_84_rd;
    logic [63:0] drd85; assign drd85 = db_set[2] ? m1_85_rd : m0_85_rd;
    logic [63:0] drd86; assign drd86 = db_set[2] ? m1_86_rd : m0_86_rd;
    logic [63:0] drd87; assign drd87 = db_set[2] ? m1_87_rd : m0_87_rd;
    logic [63:0] drd88; assign drd88 = db_set[2] ? m1_88_rd : m0_88_rd;
    logic [63:0] drd89; assign drd89 = db_set[2] ? m1_89_rd : m0_89_rd;
    logic [63:0] drd90; assign drd90 = db_set[2] ? m1_90_rd : m0_90_rd;
    logic [63:0] drd91; assign drd91 = db_set[2] ? m1_91_rd : m0_91_rd;
    logic [63:0] drd92; assign drd92 = db_set[2] ? m1_92_rd : m0_92_rd;
    logic [63:0] drd93; assign drd93 = db_set[2] ? m1_93_rd : m0_93_rd;
    logic [63:0] drd94; assign drd94 = db_set[2] ? m1_94_rd : m0_94_rd;
    logic [63:0] drd95; assign drd95 = db_set[2] ? m1_95_rd : m0_95_rd;
    logic [63:0] drd96; assign drd96 = db_set[2] ? m1_96_rd : m0_96_rd;
    logic [63:0] drd97; assign drd97 = db_set[2] ? m1_97_rd : m0_97_rd;
    logic [63:0] drd98; assign drd98 = db_set[2] ? m1_98_rd : m0_98_rd;
    logic [63:0] drd99; assign drd99 = db_set[2] ? m1_99_rd : m0_99_rd;
    logic [63:0] drd100; assign drd100 = db_set[2] ? m1_100_rd : m0_100_rd;
    logic [63:0] drd101; assign drd101 = db_set[2] ? m1_101_rd : m0_101_rd;
    logic [63:0] drd102; assign drd102 = db_set[2] ? m1_102_rd : m0_102_rd;
    logic [63:0] drd103; assign drd103 = db_set[2] ? m1_103_rd : m0_103_rd;
    logic [63:0] drd104; assign drd104 = db_set[2] ? m1_104_rd : m0_104_rd;
    logic [63:0] drd105; assign drd105 = db_set[2] ? m1_105_rd : m0_105_rd;
    logic [63:0] drd106; assign drd106 = db_set[2] ? m1_106_rd : m0_106_rd;
    logic [63:0] drd107; assign drd107 = db_set[2] ? m1_107_rd : m0_107_rd;
    logic [63:0] drd108; assign drd108 = db_set[2] ? m1_108_rd : m0_108_rd;
    logic [63:0] drd109; assign drd109 = db_set[2] ? m1_109_rd : m0_109_rd;
    logic [63:0] drd110; assign drd110 = db_set[2] ? m1_110_rd : m0_110_rd;
    logic [63:0] drd111; assign drd111 = db_set[2] ? m1_111_rd : m0_111_rd;
    logic [63:0] drd112; assign drd112 = db_set[2] ? m1_112_rd : m0_112_rd;
    logic [63:0] drd113; assign drd113 = db_set[2] ? m1_113_rd : m0_113_rd;
    logic [63:0] drd114; assign drd114 = db_set[2] ? m1_114_rd : m0_114_rd;
    logic [63:0] drd115; assign drd115 = db_set[2] ? m1_115_rd : m0_115_rd;
    logic [63:0] drd116; assign drd116 = db_set[2] ? m1_116_rd : m0_116_rd;
    logic [63:0] drd117; assign drd117 = db_set[2] ? m1_117_rd : m0_117_rd;
    logic [63:0] drd118; assign drd118 = db_set[2] ? m1_118_rd : m0_118_rd;
    logic [63:0] drd119; assign drd119 = db_set[2] ? m1_119_rd : m0_119_rd;
    logic [63:0] drd120; assign drd120 = db_set[2] ? m1_120_rd : m0_120_rd;
    logic [63:0] drd121; assign drd121 = db_set[2] ? m1_121_rd : m0_121_rd;
    logic [63:0] drd122; assign drd122 = db_set[2] ? m1_122_rd : m0_122_rd;
    logic [63:0] drd123; assign drd123 = db_set[2] ? m1_123_rd : m0_123_rd;
    logic [63:0] drd124; assign drd124 = db_set[2] ? m1_124_rd : m0_124_rd;
    logic [63:0] drd125; assign drd125 = db_set[2] ? m1_125_rd : m0_125_rd;
    logic [63:0] drd126; assign drd126 = db_set[2] ? m1_126_rd : m0_126_rd;
    logic [63:0] drd127; assign drd127 = db_set[2] ? m1_127_rd : m0_127_rd;
    logic [63:0] yr_0;
    always_ff @(posedge clk) case ({db_sub[2], db_pi[2]})
        {4'd0, 1'b0}: yr_0 <= drd0;
        {4'd0, 1'b1}: yr_0 <= drd64;
        {4'd1, 1'b0}: yr_0 <= drd8;
        {4'd1, 1'b1}: yr_0 <= drd72;
        {4'd2, 1'b0}: yr_0 <= drd16;
        {4'd2, 1'b1}: yr_0 <= drd80;
        {4'd3, 1'b0}: yr_0 <= drd24;
        {4'd3, 1'b1}: yr_0 <= drd88;
        {4'd4, 1'b0}: yr_0 <= drd32;
        {4'd4, 1'b1}: yr_0 <= drd96;
        {4'd5, 1'b0}: yr_0 <= drd40;
        {4'd5, 1'b1}: yr_0 <= drd104;
        {4'd6, 1'b0}: yr_0 <= drd48;
        {4'd6, 1'b1}: yr_0 <= drd112;
        {4'd7, 1'b0}: yr_0 <= drd56;
        {4'd7, 1'b1}: yr_0 <= drd120;
        {4'd8, 1'b0}: yr_0 <= drd64;
        {4'd8, 1'b1}: yr_0 <= drd0;
        {4'd9, 1'b0}: yr_0 <= drd72;
        {4'd9, 1'b1}: yr_0 <= drd8;
        {4'd10, 1'b0}: yr_0 <= drd80;
        {4'd10, 1'b1}: yr_0 <= drd16;
        {4'd11, 1'b0}: yr_0 <= drd88;
        {4'd11, 1'b1}: yr_0 <= drd24;
        {4'd12, 1'b0}: yr_0 <= drd96;
        {4'd12, 1'b1}: yr_0 <= drd32;
        {4'd13, 1'b0}: yr_0 <= drd104;
        {4'd13, 1'b1}: yr_0 <= drd40;
        {4'd14, 1'b0}: yr_0 <= drd112;
        {4'd14, 1'b1}: yr_0 <= drd48;
        {4'd15, 1'b0}: yr_0 <= drd120;
        {4'd15, 1'b1}: yr_0 <= drd56;
        default: yr_0 <= drd0;
    endcase
    logic [63:0] yr_1;
    always_ff @(posedge clk) case ({db_sub[2], db_pi[2]})
        {4'd0, 1'b0}: yr_1 <= drd1;
        {4'd0, 1'b1}: yr_1 <= drd65;
        {4'd1, 1'b0}: yr_1 <= drd9;
        {4'd1, 1'b1}: yr_1 <= drd73;
        {4'd2, 1'b0}: yr_1 <= drd17;
        {4'd2, 1'b1}: yr_1 <= drd81;
        {4'd3, 1'b0}: yr_1 <= drd25;
        {4'd3, 1'b1}: yr_1 <= drd89;
        {4'd4, 1'b0}: yr_1 <= drd33;
        {4'd4, 1'b1}: yr_1 <= drd97;
        {4'd5, 1'b0}: yr_1 <= drd41;
        {4'd5, 1'b1}: yr_1 <= drd105;
        {4'd6, 1'b0}: yr_1 <= drd49;
        {4'd6, 1'b1}: yr_1 <= drd113;
        {4'd7, 1'b0}: yr_1 <= drd57;
        {4'd7, 1'b1}: yr_1 <= drd121;
        {4'd8, 1'b0}: yr_1 <= drd65;
        {4'd8, 1'b1}: yr_1 <= drd1;
        {4'd9, 1'b0}: yr_1 <= drd73;
        {4'd9, 1'b1}: yr_1 <= drd9;
        {4'd10, 1'b0}: yr_1 <= drd81;
        {4'd10, 1'b1}: yr_1 <= drd17;
        {4'd11, 1'b0}: yr_1 <= drd89;
        {4'd11, 1'b1}: yr_1 <= drd25;
        {4'd12, 1'b0}: yr_1 <= drd97;
        {4'd12, 1'b1}: yr_1 <= drd33;
        {4'd13, 1'b0}: yr_1 <= drd105;
        {4'd13, 1'b1}: yr_1 <= drd41;
        {4'd14, 1'b0}: yr_1 <= drd113;
        {4'd14, 1'b1}: yr_1 <= drd49;
        {4'd15, 1'b0}: yr_1 <= drd121;
        {4'd15, 1'b1}: yr_1 <= drd57;
        default: yr_1 <= drd1;
    endcase
    logic [63:0] yr_2;
    always_ff @(posedge clk) case ({db_sub[2], db_pi[2]})
        {4'd0, 1'b0}: yr_2 <= drd2;
        {4'd0, 1'b1}: yr_2 <= drd66;
        {4'd1, 1'b0}: yr_2 <= drd10;
        {4'd1, 1'b1}: yr_2 <= drd74;
        {4'd2, 1'b0}: yr_2 <= drd18;
        {4'd2, 1'b1}: yr_2 <= drd82;
        {4'd3, 1'b0}: yr_2 <= drd26;
        {4'd3, 1'b1}: yr_2 <= drd90;
        {4'd4, 1'b0}: yr_2 <= drd34;
        {4'd4, 1'b1}: yr_2 <= drd98;
        {4'd5, 1'b0}: yr_2 <= drd42;
        {4'd5, 1'b1}: yr_2 <= drd106;
        {4'd6, 1'b0}: yr_2 <= drd50;
        {4'd6, 1'b1}: yr_2 <= drd114;
        {4'd7, 1'b0}: yr_2 <= drd58;
        {4'd7, 1'b1}: yr_2 <= drd122;
        {4'd8, 1'b0}: yr_2 <= drd66;
        {4'd8, 1'b1}: yr_2 <= drd2;
        {4'd9, 1'b0}: yr_2 <= drd74;
        {4'd9, 1'b1}: yr_2 <= drd10;
        {4'd10, 1'b0}: yr_2 <= drd82;
        {4'd10, 1'b1}: yr_2 <= drd18;
        {4'd11, 1'b0}: yr_2 <= drd90;
        {4'd11, 1'b1}: yr_2 <= drd26;
        {4'd12, 1'b0}: yr_2 <= drd98;
        {4'd12, 1'b1}: yr_2 <= drd34;
        {4'd13, 1'b0}: yr_2 <= drd106;
        {4'd13, 1'b1}: yr_2 <= drd42;
        {4'd14, 1'b0}: yr_2 <= drd114;
        {4'd14, 1'b1}: yr_2 <= drd50;
        {4'd15, 1'b0}: yr_2 <= drd122;
        {4'd15, 1'b1}: yr_2 <= drd58;
        default: yr_2 <= drd2;
    endcase
    logic [63:0] yr_3;
    always_ff @(posedge clk) case ({db_sub[2], db_pi[2]})
        {4'd0, 1'b0}: yr_3 <= drd3;
        {4'd0, 1'b1}: yr_3 <= drd67;
        {4'd1, 1'b0}: yr_3 <= drd11;
        {4'd1, 1'b1}: yr_3 <= drd75;
        {4'd2, 1'b0}: yr_3 <= drd19;
        {4'd2, 1'b1}: yr_3 <= drd83;
        {4'd3, 1'b0}: yr_3 <= drd27;
        {4'd3, 1'b1}: yr_3 <= drd91;
        {4'd4, 1'b0}: yr_3 <= drd35;
        {4'd4, 1'b1}: yr_3 <= drd99;
        {4'd5, 1'b0}: yr_3 <= drd43;
        {4'd5, 1'b1}: yr_3 <= drd107;
        {4'd6, 1'b0}: yr_3 <= drd51;
        {4'd6, 1'b1}: yr_3 <= drd115;
        {4'd7, 1'b0}: yr_3 <= drd59;
        {4'd7, 1'b1}: yr_3 <= drd123;
        {4'd8, 1'b0}: yr_3 <= drd67;
        {4'd8, 1'b1}: yr_3 <= drd3;
        {4'd9, 1'b0}: yr_3 <= drd75;
        {4'd9, 1'b1}: yr_3 <= drd11;
        {4'd10, 1'b0}: yr_3 <= drd83;
        {4'd10, 1'b1}: yr_3 <= drd19;
        {4'd11, 1'b0}: yr_3 <= drd91;
        {4'd11, 1'b1}: yr_3 <= drd27;
        {4'd12, 1'b0}: yr_3 <= drd99;
        {4'd12, 1'b1}: yr_3 <= drd35;
        {4'd13, 1'b0}: yr_3 <= drd107;
        {4'd13, 1'b1}: yr_3 <= drd43;
        {4'd14, 1'b0}: yr_3 <= drd115;
        {4'd14, 1'b1}: yr_3 <= drd51;
        {4'd15, 1'b0}: yr_3 <= drd123;
        {4'd15, 1'b1}: yr_3 <= drd59;
        default: yr_3 <= drd3;
    endcase
    logic [63:0] yr_4;
    always_ff @(posedge clk) case ({db_sub[2], db_pi[2]})
        {4'd0, 1'b0}: yr_4 <= drd4;
        {4'd0, 1'b1}: yr_4 <= drd68;
        {4'd1, 1'b0}: yr_4 <= drd12;
        {4'd1, 1'b1}: yr_4 <= drd76;
        {4'd2, 1'b0}: yr_4 <= drd20;
        {4'd2, 1'b1}: yr_4 <= drd84;
        {4'd3, 1'b0}: yr_4 <= drd28;
        {4'd3, 1'b1}: yr_4 <= drd92;
        {4'd4, 1'b0}: yr_4 <= drd36;
        {4'd4, 1'b1}: yr_4 <= drd100;
        {4'd5, 1'b0}: yr_4 <= drd44;
        {4'd5, 1'b1}: yr_4 <= drd108;
        {4'd6, 1'b0}: yr_4 <= drd52;
        {4'd6, 1'b1}: yr_4 <= drd116;
        {4'd7, 1'b0}: yr_4 <= drd60;
        {4'd7, 1'b1}: yr_4 <= drd124;
        {4'd8, 1'b0}: yr_4 <= drd68;
        {4'd8, 1'b1}: yr_4 <= drd4;
        {4'd9, 1'b0}: yr_4 <= drd76;
        {4'd9, 1'b1}: yr_4 <= drd12;
        {4'd10, 1'b0}: yr_4 <= drd84;
        {4'd10, 1'b1}: yr_4 <= drd20;
        {4'd11, 1'b0}: yr_4 <= drd92;
        {4'd11, 1'b1}: yr_4 <= drd28;
        {4'd12, 1'b0}: yr_4 <= drd100;
        {4'd12, 1'b1}: yr_4 <= drd36;
        {4'd13, 1'b0}: yr_4 <= drd108;
        {4'd13, 1'b1}: yr_4 <= drd44;
        {4'd14, 1'b0}: yr_4 <= drd116;
        {4'd14, 1'b1}: yr_4 <= drd52;
        {4'd15, 1'b0}: yr_4 <= drd124;
        {4'd15, 1'b1}: yr_4 <= drd60;
        default: yr_4 <= drd4;
    endcase
    logic [63:0] yr_5;
    always_ff @(posedge clk) case ({db_sub[2], db_pi[2]})
        {4'd0, 1'b0}: yr_5 <= drd5;
        {4'd0, 1'b1}: yr_5 <= drd69;
        {4'd1, 1'b0}: yr_5 <= drd13;
        {4'd1, 1'b1}: yr_5 <= drd77;
        {4'd2, 1'b0}: yr_5 <= drd21;
        {4'd2, 1'b1}: yr_5 <= drd85;
        {4'd3, 1'b0}: yr_5 <= drd29;
        {4'd3, 1'b1}: yr_5 <= drd93;
        {4'd4, 1'b0}: yr_5 <= drd37;
        {4'd4, 1'b1}: yr_5 <= drd101;
        {4'd5, 1'b0}: yr_5 <= drd45;
        {4'd5, 1'b1}: yr_5 <= drd109;
        {4'd6, 1'b0}: yr_5 <= drd53;
        {4'd6, 1'b1}: yr_5 <= drd117;
        {4'd7, 1'b0}: yr_5 <= drd61;
        {4'd7, 1'b1}: yr_5 <= drd125;
        {4'd8, 1'b0}: yr_5 <= drd69;
        {4'd8, 1'b1}: yr_5 <= drd5;
        {4'd9, 1'b0}: yr_5 <= drd77;
        {4'd9, 1'b1}: yr_5 <= drd13;
        {4'd10, 1'b0}: yr_5 <= drd85;
        {4'd10, 1'b1}: yr_5 <= drd21;
        {4'd11, 1'b0}: yr_5 <= drd93;
        {4'd11, 1'b1}: yr_5 <= drd29;
        {4'd12, 1'b0}: yr_5 <= drd101;
        {4'd12, 1'b1}: yr_5 <= drd37;
        {4'd13, 1'b0}: yr_5 <= drd109;
        {4'd13, 1'b1}: yr_5 <= drd45;
        {4'd14, 1'b0}: yr_5 <= drd117;
        {4'd14, 1'b1}: yr_5 <= drd53;
        {4'd15, 1'b0}: yr_5 <= drd125;
        {4'd15, 1'b1}: yr_5 <= drd61;
        default: yr_5 <= drd5;
    endcase
    logic [63:0] yr_6;
    always_ff @(posedge clk) case ({db_sub[2], db_pi[2]})
        {4'd0, 1'b0}: yr_6 <= drd6;
        {4'd0, 1'b1}: yr_6 <= drd70;
        {4'd1, 1'b0}: yr_6 <= drd14;
        {4'd1, 1'b1}: yr_6 <= drd78;
        {4'd2, 1'b0}: yr_6 <= drd22;
        {4'd2, 1'b1}: yr_6 <= drd86;
        {4'd3, 1'b0}: yr_6 <= drd30;
        {4'd3, 1'b1}: yr_6 <= drd94;
        {4'd4, 1'b0}: yr_6 <= drd38;
        {4'd4, 1'b1}: yr_6 <= drd102;
        {4'd5, 1'b0}: yr_6 <= drd46;
        {4'd5, 1'b1}: yr_6 <= drd110;
        {4'd6, 1'b0}: yr_6 <= drd54;
        {4'd6, 1'b1}: yr_6 <= drd118;
        {4'd7, 1'b0}: yr_6 <= drd62;
        {4'd7, 1'b1}: yr_6 <= drd126;
        {4'd8, 1'b0}: yr_6 <= drd70;
        {4'd8, 1'b1}: yr_6 <= drd6;
        {4'd9, 1'b0}: yr_6 <= drd78;
        {4'd9, 1'b1}: yr_6 <= drd14;
        {4'd10, 1'b0}: yr_6 <= drd86;
        {4'd10, 1'b1}: yr_6 <= drd22;
        {4'd11, 1'b0}: yr_6 <= drd94;
        {4'd11, 1'b1}: yr_6 <= drd30;
        {4'd12, 1'b0}: yr_6 <= drd102;
        {4'd12, 1'b1}: yr_6 <= drd38;
        {4'd13, 1'b0}: yr_6 <= drd110;
        {4'd13, 1'b1}: yr_6 <= drd46;
        {4'd14, 1'b0}: yr_6 <= drd118;
        {4'd14, 1'b1}: yr_6 <= drd54;
        {4'd15, 1'b0}: yr_6 <= drd126;
        {4'd15, 1'b1}: yr_6 <= drd62;
        default: yr_6 <= drd6;
    endcase
    logic [63:0] yr_7;
    always_ff @(posedge clk) case ({db_sub[2], db_pi[2]})
        {4'd0, 1'b0}: yr_7 <= drd7;
        {4'd0, 1'b1}: yr_7 <= drd71;
        {4'd1, 1'b0}: yr_7 <= drd15;
        {4'd1, 1'b1}: yr_7 <= drd79;
        {4'd2, 1'b0}: yr_7 <= drd23;
        {4'd2, 1'b1}: yr_7 <= drd87;
        {4'd3, 1'b0}: yr_7 <= drd31;
        {4'd3, 1'b1}: yr_7 <= drd95;
        {4'd4, 1'b0}: yr_7 <= drd39;
        {4'd4, 1'b1}: yr_7 <= drd103;
        {4'd5, 1'b0}: yr_7 <= drd47;
        {4'd5, 1'b1}: yr_7 <= drd111;
        {4'd6, 1'b0}: yr_7 <= drd55;
        {4'd6, 1'b1}: yr_7 <= drd119;
        {4'd7, 1'b0}: yr_7 <= drd63;
        {4'd7, 1'b1}: yr_7 <= drd127;
        {4'd8, 1'b0}: yr_7 <= drd71;
        {4'd8, 1'b1}: yr_7 <= drd7;
        {4'd9, 1'b0}: yr_7 <= drd79;
        {4'd9, 1'b1}: yr_7 <= drd15;
        {4'd10, 1'b0}: yr_7 <= drd87;
        {4'd10, 1'b1}: yr_7 <= drd23;
        {4'd11, 1'b0}: yr_7 <= drd95;
        {4'd11, 1'b1}: yr_7 <= drd31;
        {4'd12, 1'b0}: yr_7 <= drd103;
        {4'd12, 1'b1}: yr_7 <= drd39;
        {4'd13, 1'b0}: yr_7 <= drd111;
        {4'd13, 1'b1}: yr_7 <= drd47;
        {4'd14, 1'b0}: yr_7 <= drd119;
        {4'd14, 1'b1}: yr_7 <= drd55;
        {4'd15, 1'b0}: yr_7 <= drd127;
        {4'd15, 1'b1}: yr_7 <= drd63;
        default: yr_7 <= drd7;
    endcase
    logic yv; always_ff @(posedge clk) yv <= rst ? 1'b0 : db_v[2];
    assign y_out_0 = yr_0;
    assign y_out_1 = yr_1;
    assign y_out_2 = yr_2;
    assign y_out_3 = yr_3;
    assign y_out_4 = yr_4;
    assign y_out_5 = yr_5;
    assign y_out_6 = yr_6;
    assign y_out_7 = yr_7;
    assign out_valid = yv;
endmodule
