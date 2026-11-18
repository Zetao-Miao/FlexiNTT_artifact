`timescale 1ns / 1ps
// ev_ld_io4_k: hybrid NTT, n=4096, block of 3 stages x 8 butterflies (2 group(s) of 8 lanes), 4 rounds (0 stage(s) bypassed in round 0), 1 context(s), slot 270 cycles, interval 1080, run-time modulus (4 loadable slot(s)), direction both, negacyclic
module ev_ld_io4_k (
    input  logic clk,
    input  logic rst,
    input  logic in_valid,
    output logic in_ready,
    input  logic [1:0] MIDX,
    input  logic DIR,
    input  logic [29:0] x_in_0,
    input  logic [29:0] x_in_1,
    input  logic [29:0] x_in_2,
    input  logic [29:0] x_in_3,
    input  logic [29:0] x_in_4,
    input  logic [29:0] x_in_5,
    input  logic [29:0] x_in_6,
    input  logic [29:0] x_in_7,
    input  logic [29:0] x_in_8,
    input  logic [29:0] x_in_9,
    input  logic [29:0] x_in_10,
    input  logic [29:0] x_in_11,
    input  logic [29:0] x_in_12,
    input  logic [29:0] x_in_13,
    input  logic [29:0] x_in_14,
    input  logic [29:0] x_in_15,
    output logic out_valid,
    output logic [1:0] midx_out,
    output logic dir_out,
    output logic [29:0] y_out_0,
    output logic [29:0] y_out_1,
    output logic [29:0] y_out_2,
    output logic [29:0] y_out_3,
    output logic [29:0] y_out_4,
    output logic [29:0] y_out_5,
    output logic [29:0] y_out_6,
    output logic [29:0] y_out_7,
    output logic [29:0] y_out_8,
    output logic [29:0] y_out_9,
    output logic [29:0] y_out_10,
    output logic [29:0] y_out_11,
    output logic [29:0] y_out_12,
    output logic [29:0] y_out_13,
    output logic [29:0] y_out_14,
    output logic [29:0] y_out_15,
    input  logic ld_we,
    input  logic [5:0] ld_sel,
    input  logic [10:0] ld_addr,
    input  logic [31:0] ld_data
    );
    logic start, run_c, slot0, take, stopc, run_n, iss, r0iss, accept, send;
    logic [15:0] tg1;
    // ---- load port: 55 regions (manifest.json: load_map), one word per cycle; a region may be written
    // while no polynomial in flight uses the words written
    (* max_fanout = 32 *) logic [54:0] ld_en; (* max_fanout = 32 *) logic [10:0] ld_a; (* max_fanout = 32 *) logic [31:0] ld_d;
    always_ff @(posedge clk) begin
        ld_en <= ld_we ? (55'd1 << ld_sel) : '0; ld_a <= ld_addr; ld_d <= ld_data;
    end
    // ---- tag pipeline: tag d = the issue's fields d cycles later (valid bits reset), d <= 52
    logic [51:0] vch;
    logic [15:0] tg2;
    logic [15:0] tg3;
    logic [15:0] tg4;
    logic [15:0] tg5;
    logic [15:0] tg6;
    logic [15:0] tg7;
    logic [15:0] tg8;
    logic [15:0] tg9;
    logic [15:0] tg10;
    logic [15:0] tg11;
    logic [15:0] tg12;
    logic [15:0] tg13;
    logic [15:0] tg14;
    logic [15:0] tg15;
    logic [15:0] tg16;
    logic [15:0] tg17;
    logic [15:0] tg18;
    logic [15:0] tg19;
    logic [15:0] tg20;
    logic [15:0] tg21;
    logic [15:0] tg22;
    logic [15:0] tg23;
    logic [15:0] tg24;
    logic [15:0] tg25;
    logic [15:0] tg26;
    logic [15:0] tg27;
    logic [15:0] tg28;
    logic [15:0] tg29;
    logic [15:0] tg30;
    logic [15:0] tg31;
    logic [15:0] tg32;
    logic [15:0] tg33;
    logic [15:0] tg34;
    logic [15:0] tg35;
    logic [15:0] tg36;
    logic [15:0] tg37;
    logic [15:0] tg38;
    logic [15:0] tg39;
    logic [15:0] tg40;
    logic [15:0] tg41;
    logic [15:0] tg42;
    logic [15:0] tg43;
    logic [15:0] tg44;
    logic [15:0] tg45;
    logic [15:0] tg46;
    logic [15:0] tg47;
    logic [15:0] tg48;
    logic [15:0] tg49;
    logic [15:0] tg50;
    logic [15:0] tg51;
    logic [15:0] tg52;
    // ---- controller: slots of 270 cycles, 1 context(s), 4 rounds, round offsets [0]
    logic running; logic [0:0] xr; logic [1:0] kdr; logic [8:0] cc; logic [0:0] wbr;
    logic [0:0] act; logic [8:0] count; logic [7:0] wcnt, rptr;
    logic [1:0] cm_ [1];
    logic cd_ [1];
    logic [1:0] tq_m [4];
    logic tq_d [4];
    logic [1:0] tq_w, tq_r;
    logic [0:0] x_c; logic [1:0] kd_c, r_c; logic [8:0] cc_c; logic [0:0] wb_c, rb_c;
    logic [0:0] act_c;
    assign in_ready = count < 9'd256;
    assign accept = in_valid && in_ready;
    always_comb begin
        start = !running && (count >= 9'd256);
        run_c = running || start;
        x_c = start ? '0 : xr; kd_c = start ? '0 : kdr; cc_c = start ? '0 : cc; wb_c = start ? '0 : wbr;
        case (x_c)
            1'd0: r_c = 2'((kd_c + 3'd0) % 4);
            default: r_c = '0;
        endcase
        slot0 = run_c && (cc_c == '0) && (r_c == '0);
        take = slot0 && (count >= 9'd256);
        act_c = act;
        if (slot0) act_c[x_c] = take;
        stopc = slot0 && (act_c == '0);
        run_n = run_c && !stopc;
        iss = run_n && act_c[x_c] && (cc_c < 9'd256);
        r0iss = iss && (r_c == '0);
        rb_c = (wb_c == 1'd1) ? '0 : wb_c + 1'b1;
    end
    always_ff @(posedge clk) begin
        if (rst) begin
            running <= 1'b0; xr <= '0; kdr <= '0; cc <= '0; wbr <= '0; act <= '0; count <= '0;
            wcnt <= '0; rptr <= '0; tq_w <= '0; tq_r <= '0;
        end else begin
            running <= run_n;
            act <= act_c;
            count <= 9'(count + 9'(accept) - 9'(r0iss));
            if (run_n) begin
                if (cc_c == 9'd269) begin
                    cc <= '0;
                    wbr <= (wb_c == 1'd1) ? '0 : wb_c + 1'b1;
                    xr <= '0;
                    kdr <= (kd_c == 2'd3) ? '0 : kd_c + 1'b1;
                end else begin
                    cc <= cc_c + 1'b1; wbr <= wb_c; xr <= x_c; kdr <= kd_c;
                end
            end
            if (take) tq_r <= tq_r + 1'b1;
            if (r0iss) rptr <= (rptr == 8'd255) ? '0 : rptr + 1'b1;
            if (accept) begin
                wcnt <= (wcnt == 8'd255) ? '0 : wcnt + 1'b1;
                if (wcnt % 256 == 0) tq_w <= tq_w + 1'b1;
            end
        end
    end
    always_ff @(posedge clk) begin
        if (accept && (wcnt % 256 == 0)) begin
            tq_m[tq_w] <= MIDX;
            tq_d[tq_w] <= DIR;
        end
        if (take) begin
            cm_[x_c] <= tq_m[tq_r];
            cd_[x_c] <= tq_d[tq_r];
        end
    end
    (* max_fanout = 16 *) logic [7:0] fifo_ra;
    (* max_fanout = 16 *) logic [8:0] pool_ra0;
    (* max_fanout = 16 *) logic [8:0] pool_ra1;
    (* max_fanout = 16 *) logic [8:0] pool_ra2;
    (* max_fanout = 16 *) logic [8:0] pool_ra3;
    (* max_fanout = 16 *) logic [8:0] pool_ra4;
    (* max_fanout = 16 *) logic [8:0] pool_ra5;
    (* max_fanout = 16 *) logic [8:0] pool_ra6;
    (* max_fanout = 16 *) logic [8:0] pool_ra7;
    always_ff @(posedge clk) begin
        tg1 <= {(take ? tq_d[tq_r] : cd_[x_c]), (take ? tq_m[tq_r] : cm_[x_c]), wb_c, 8'(cc_c), r_c, (r_c == '0), (r_c == 2'd3)};
        fifo_ra <= rptr;
        pool_ra0 <= 9'(rb_c) * 9'(256) + 9'((8'(cc_c) & 8'd31) << 3) + 9'((4'd0 - 4'((8'(cc_c) >> 5))) & 4'd7);
        pool_ra1 <= 9'(rb_c) * 9'(256) + 9'((8'(cc_c) & 8'd31) << 3) + 9'((4'd1 - 4'((8'(cc_c) >> 5))) & 4'd7);
        pool_ra2 <= 9'(rb_c) * 9'(256) + 9'((8'(cc_c) & 8'd31) << 3) + 9'((4'd2 - 4'((8'(cc_c) >> 5))) & 4'd7);
        pool_ra3 <= 9'(rb_c) * 9'(256) + 9'((8'(cc_c) & 8'd31) << 3) + 9'((4'd3 - 4'((8'(cc_c) >> 5))) & 4'd7);
        pool_ra4 <= 9'(rb_c) * 9'(256) + 9'((8'(cc_c) & 8'd31) << 3) + 9'((4'd4 - 4'((8'(cc_c) >> 5))) & 4'd7);
        pool_ra5 <= 9'(rb_c) * 9'(256) + 9'((8'(cc_c) & 8'd31) << 3) + 9'((4'd5 - 4'((8'(cc_c) >> 5))) & 4'd7);
        pool_ra6 <= 9'(rb_c) * 9'(256) + 9'((8'(cc_c) & 8'd31) << 3) + 9'((4'd6 - 4'((8'(cc_c) >> 5))) & 4'd7);
        pool_ra7 <= 9'(rb_c) * 9'(256) + 9'((8'(cc_c) & 8'd31) << 3) + 9'((4'd7 - 4'((8'(cc_c) >> 5))) & 4'd7);
    end
    // ---- input FIFO: lane l -> bank l, address = beat (mod depth); pool: bank h*2^U + ((lo + c) mod 2^U)
    logic fw_e; logic [7:0] fw_a;
    logic [29:0] fw_d0, fifo_rd0, pool_rd0;
    logic [29:0] fw_d1, fifo_rd1, pool_rd1;
    logic [29:0] fw_d2, fifo_rd2, pool_rd2;
    logic [29:0] fw_d3, fifo_rd3, pool_rd3;
    logic [29:0] fw_d4, fifo_rd4, pool_rd4;
    logic [29:0] fw_d5, fifo_rd5, pool_rd5;
    logic [29:0] fw_d6, fifo_rd6, pool_rd6;
    logic [29:0] fw_d7, fifo_rd7, pool_rd7;
    logic [29:0] fw_d8, fifo_rd8, pool_rd8;
    logic [29:0] fw_d9, fifo_rd9, pool_rd9;
    logic [29:0] fw_d10, fifo_rd10, pool_rd10;
    logic [29:0] fw_d11, fifo_rd11, pool_rd11;
    logic [29:0] fw_d12, fifo_rd12, pool_rd12;
    logic [29:0] fw_d13, fifo_rd13, pool_rd13;
    logic [29:0] fw_d14, fifo_rd14, pool_rd14;
    logic [29:0] fw_d15, fifo_rd15, pool_rd15;
    always_ff @(posedge clk) begin
        fw_e <= rst ? 1'b0 : accept; fw_a <= wcnt;
        fw_d0 <= x_in_0;
        fw_d1 <= x_in_1;
        fw_d2 <= x_in_2;
        fw_d3 <= x_in_3;
        fw_d4 <= x_in_4;
        fw_d5 <= x_in_5;
        fw_d6 <= x_in_6;
        fw_d7 <= x_in_7;
        fw_d8 <= x_in_8;
        fw_d9 <= x_in_9;
        fw_d10 <= x_in_10;
        fw_d11 <= x_in_11;
        fw_d12 <= x_in_12;
        fw_d13 <= x_in_13;
        fw_d14 <= x_in_14;
        fw_d15 <= x_in_15;
    end
    ev_ld_io4_k_ram_block #(.W(30), .D(256), .A(8), .R(2)) u_fifo0 (.clk(clk), .we(fw_e), .wa(fw_a), .wd(fw_d0), .ra(fifo_ra), .rd(fifo_rd0));
    ev_ld_io4_k_ram_block #(.W(30), .D(256), .A(8), .R(2)) u_fifo1 (.clk(clk), .we(fw_e), .wa(fw_a), .wd(fw_d1), .ra(fifo_ra), .rd(fifo_rd1));
    ev_ld_io4_k_ram_block #(.W(30), .D(256), .A(8), .R(2)) u_fifo2 (.clk(clk), .we(fw_e), .wa(fw_a), .wd(fw_d2), .ra(fifo_ra), .rd(fifo_rd2));
    ev_ld_io4_k_ram_block #(.W(30), .D(256), .A(8), .R(2)) u_fifo3 (.clk(clk), .we(fw_e), .wa(fw_a), .wd(fw_d3), .ra(fifo_ra), .rd(fifo_rd3));
    ev_ld_io4_k_ram_block #(.W(30), .D(256), .A(8), .R(2)) u_fifo4 (.clk(clk), .we(fw_e), .wa(fw_a), .wd(fw_d4), .ra(fifo_ra), .rd(fifo_rd4));
    ev_ld_io4_k_ram_block #(.W(30), .D(256), .A(8), .R(2)) u_fifo5 (.clk(clk), .we(fw_e), .wa(fw_a), .wd(fw_d5), .ra(fifo_ra), .rd(fifo_rd5));
    ev_ld_io4_k_ram_block #(.W(30), .D(256), .A(8), .R(2)) u_fifo6 (.clk(clk), .we(fw_e), .wa(fw_a), .wd(fw_d6), .ra(fifo_ra), .rd(fifo_rd6));
    ev_ld_io4_k_ram_block #(.W(30), .D(256), .A(8), .R(2)) u_fifo7 (.clk(clk), .we(fw_e), .wa(fw_a), .wd(fw_d7), .ra(fifo_ra), .rd(fifo_rd7));
    ev_ld_io4_k_ram_block #(.W(30), .D(256), .A(8), .R(2)) u_fifo8 (.clk(clk), .we(fw_e), .wa(fw_a), .wd(fw_d8), .ra(fifo_ra), .rd(fifo_rd8));
    ev_ld_io4_k_ram_block #(.W(30), .D(256), .A(8), .R(2)) u_fifo9 (.clk(clk), .we(fw_e), .wa(fw_a), .wd(fw_d9), .ra(fifo_ra), .rd(fifo_rd9));
    ev_ld_io4_k_ram_block #(.W(30), .D(256), .A(8), .R(2)) u_fifo10 (.clk(clk), .we(fw_e), .wa(fw_a), .wd(fw_d10), .ra(fifo_ra), .rd(fifo_rd10));
    ev_ld_io4_k_ram_block #(.W(30), .D(256), .A(8), .R(2)) u_fifo11 (.clk(clk), .we(fw_e), .wa(fw_a), .wd(fw_d11), .ra(fifo_ra), .rd(fifo_rd11));
    ev_ld_io4_k_ram_block #(.W(30), .D(256), .A(8), .R(2)) u_fifo12 (.clk(clk), .we(fw_e), .wa(fw_a), .wd(fw_d12), .ra(fifo_ra), .rd(fifo_rd12));
    ev_ld_io4_k_ram_block #(.W(30), .D(256), .A(8), .R(2)) u_fifo13 (.clk(clk), .we(fw_e), .wa(fw_a), .wd(fw_d13), .ra(fifo_ra), .rd(fifo_rd13));
    ev_ld_io4_k_ram_block #(.W(30), .D(256), .A(8), .R(2)) u_fifo14 (.clk(clk), .we(fw_e), .wa(fw_a), .wd(fw_d14), .ra(fifo_ra), .rd(fifo_rd14));
    ev_ld_io4_k_ram_block #(.W(30), .D(256), .A(8), .R(2)) u_fifo15 (.clk(clk), .we(fw_e), .wa(fw_a), .wd(fw_d15), .ra(fifo_ra), .rd(fifo_rd15));
    (* max_fanout = 32 *) logic pw_e; (* max_fanout = 32 *) logic [8:0] pw_a;
    logic [29:0] pw_d0;
    ev_ld_io4_k_ram_block #(.W(30), .D(512), .A(9), .R(2)) u_pool0 (.clk(clk), .we(pw_e), .wa(pw_a), .wd(pw_d0), .ra(pool_ra0), .rd(pool_rd0));
    logic [29:0] pw_d1;
    ev_ld_io4_k_ram_block #(.W(30), .D(512), .A(9), .R(2)) u_pool1 (.clk(clk), .we(pw_e), .wa(pw_a), .wd(pw_d1), .ra(pool_ra1), .rd(pool_rd1));
    logic [29:0] pw_d2;
    ev_ld_io4_k_ram_block #(.W(30), .D(512), .A(9), .R(2)) u_pool2 (.clk(clk), .we(pw_e), .wa(pw_a), .wd(pw_d2), .ra(pool_ra2), .rd(pool_rd2));
    logic [29:0] pw_d3;
    ev_ld_io4_k_ram_block #(.W(30), .D(512), .A(9), .R(2)) u_pool3 (.clk(clk), .we(pw_e), .wa(pw_a), .wd(pw_d3), .ra(pool_ra3), .rd(pool_rd3));
    logic [29:0] pw_d4;
    ev_ld_io4_k_ram_block #(.W(30), .D(512), .A(9), .R(2)) u_pool4 (.clk(clk), .we(pw_e), .wa(pw_a), .wd(pw_d4), .ra(pool_ra4), .rd(pool_rd4));
    logic [29:0] pw_d5;
    ev_ld_io4_k_ram_block #(.W(30), .D(512), .A(9), .R(2)) u_pool5 (.clk(clk), .we(pw_e), .wa(pw_a), .wd(pw_d5), .ra(pool_ra5), .rd(pool_rd5));
    logic [29:0] pw_d6;
    ev_ld_io4_k_ram_block #(.W(30), .D(512), .A(9), .R(2)) u_pool6 (.clk(clk), .we(pw_e), .wa(pw_a), .wd(pw_d6), .ra(pool_ra6), .rd(pool_rd6));
    logic [29:0] pw_d7;
    ev_ld_io4_k_ram_block #(.W(30), .D(512), .A(9), .R(2)) u_pool7 (.clk(clk), .we(pw_e), .wa(pw_a), .wd(pw_d7), .ra(pool_ra7), .rd(pool_rd7));
    logic [29:0] pw_d8;
    ev_ld_io4_k_ram_block #(.W(30), .D(512), .A(9), .R(2)) u_pool8 (.clk(clk), .we(pw_e), .wa(pw_a), .wd(pw_d8), .ra(pool_ra0), .rd(pool_rd8));
    logic [29:0] pw_d9;
    ev_ld_io4_k_ram_block #(.W(30), .D(512), .A(9), .R(2)) u_pool9 (.clk(clk), .we(pw_e), .wa(pw_a), .wd(pw_d9), .ra(pool_ra1), .rd(pool_rd9));
    logic [29:0] pw_d10;
    ev_ld_io4_k_ram_block #(.W(30), .D(512), .A(9), .R(2)) u_pool10 (.clk(clk), .we(pw_e), .wa(pw_a), .wd(pw_d10), .ra(pool_ra2), .rd(pool_rd10));
    logic [29:0] pw_d11;
    ev_ld_io4_k_ram_block #(.W(30), .D(512), .A(9), .R(2)) u_pool11 (.clk(clk), .we(pw_e), .wa(pw_a), .wd(pw_d11), .ra(pool_ra3), .rd(pool_rd11));
    logic [29:0] pw_d12;
    ev_ld_io4_k_ram_block #(.W(30), .D(512), .A(9), .R(2)) u_pool12 (.clk(clk), .we(pw_e), .wa(pw_a), .wd(pw_d12), .ra(pool_ra4), .rd(pool_rd12));
    logic [29:0] pw_d13;
    ev_ld_io4_k_ram_block #(.W(30), .D(512), .A(9), .R(2)) u_pool13 (.clk(clk), .we(pw_e), .wa(pw_a), .wd(pw_d13), .ra(pool_ra5), .rd(pool_rd13));
    logic [29:0] pw_d14;
    ev_ld_io4_k_ram_block #(.W(30), .D(512), .A(9), .R(2)) u_pool14 (.clk(clk), .we(pw_e), .wa(pw_a), .wd(pw_d14), .ra(pool_ra6), .rd(pool_rd14));
    logic [29:0] pw_d15;
    ev_ld_io4_k_ram_block #(.W(30), .D(512), .A(9), .R(2)) u_pool15 (.clk(clk), .we(pw_e), .wa(pw_a), .wd(pw_d15), .ra(pool_ra7), .rd(pool_rd15));
    // ---- read path: source mux (bank order), rotate group h left by the top U beat bits, block input
    (* max_fanout = 32 *) logic src_r0;
    always_ff @(posedge clk) src_r0 <= tg2[1];   // valid with the RAM data (t+1+RL)
    logic [29:0] src0;
    always_ff @(posedge clk) src0 <= src_r0 ? fifo_rd0 : pool_rd0;
    logic [29:0] src1;
    always_ff @(posedge clk) src1 <= src_r0 ? fifo_rd2 : pool_rd1;
    logic [29:0] src2;
    always_ff @(posedge clk) src2 <= src_r0 ? fifo_rd4 : pool_rd2;
    logic [29:0] src3;
    always_ff @(posedge clk) src3 <= src_r0 ? fifo_rd6 : pool_rd3;
    logic [29:0] src4;
    always_ff @(posedge clk) src4 <= src_r0 ? fifo_rd8 : pool_rd4;
    logic [29:0] src5;
    always_ff @(posedge clk) src5 <= src_r0 ? fifo_rd10 : pool_rd5;
    logic [29:0] src6;
    always_ff @(posedge clk) src6 <= src_r0 ? fifo_rd12 : pool_rd6;
    logic [29:0] src7;
    always_ff @(posedge clk) src7 <= src_r0 ? fifo_rd14 : pool_rd7;
    logic [29:0] src8;
    always_ff @(posedge clk) src8 <= src_r0 ? fifo_rd1 : pool_rd8;
    logic [29:0] src9;
    always_ff @(posedge clk) src9 <= src_r0 ? fifo_rd3 : pool_rd9;
    logic [29:0] src10;
    always_ff @(posedge clk) src10 <= src_r0 ? fifo_rd5 : pool_rd10;
    logic [29:0] src11;
    always_ff @(posedge clk) src11 <= src_r0 ? fifo_rd7 : pool_rd11;
    logic [29:0] src12;
    always_ff @(posedge clk) src12 <= src_r0 ? fifo_rd9 : pool_rd12;
    logic [29:0] src13;
    always_ff @(posedge clk) src13 <= src_r0 ? fifo_rd11 : pool_rd13;
    logic [29:0] src14;
    always_ff @(posedge clk) src14 <= src_r0 ? fifo_rd13 : pool_rd14;
    logic [29:0] src15;
    always_ff @(posedge clk) src15 <= src_r0 ? fifo_rd15 : pool_rd15;
    (* max_fanout = 32 *) logic [1:0] rra0;
    always_ff @(posedge clk) rra0 <= tg3[1] ? '0 : tg3[10:9];
    logic [29:0] rr0_0;
    logic [29:0] rr0_1;
    logic [29:0] rr0_2;
    logic [29:0] rr0_3;
    logic [29:0] rr0_4;
    logic [29:0] rr0_5;
    logic [29:0] rr0_6;
    logic [29:0] rr0_7;
    logic [29:0] rr0_8;
    logic [29:0] rr0_9;
    logic [29:0] rr0_10;
    logic [29:0] rr0_11;
    logic [29:0] rr0_12;
    logic [29:0] rr0_13;
    logic [29:0] rr0_14;
    logic [29:0] rr0_15;
    always_ff @(posedge clk) case (rra0) 2'd0: rr0_0 <= src0; 2'd1: rr0_0 <= src1; 2'd2: rr0_0 <= src2; default: rr0_0 <= src3; endcase
    always_ff @(posedge clk) case (rra0) 2'd0: rr0_1 <= src1; 2'd1: rr0_1 <= src2; 2'd2: rr0_1 <= src3; default: rr0_1 <= src4; endcase
    always_ff @(posedge clk) case (rra0) 2'd0: rr0_2 <= src2; 2'd1: rr0_2 <= src3; 2'd2: rr0_2 <= src4; default: rr0_2 <= src5; endcase
    always_ff @(posedge clk) case (rra0) 2'd0: rr0_3 <= src3; 2'd1: rr0_3 <= src4; 2'd2: rr0_3 <= src5; default: rr0_3 <= src6; endcase
    always_ff @(posedge clk) case (rra0) 2'd0: rr0_4 <= src4; 2'd1: rr0_4 <= src5; 2'd2: rr0_4 <= src6; default: rr0_4 <= src7; endcase
    always_ff @(posedge clk) case (rra0) 2'd0: rr0_5 <= src5; 2'd1: rr0_5 <= src6; 2'd2: rr0_5 <= src7; default: rr0_5 <= src0; endcase
    always_ff @(posedge clk) case (rra0) 2'd0: rr0_6 <= src6; 2'd1: rr0_6 <= src7; 2'd2: rr0_6 <= src0; default: rr0_6 <= src1; endcase
    always_ff @(posedge clk) case (rra0) 2'd0: rr0_7 <= src7; 2'd1: rr0_7 <= src0; 2'd2: rr0_7 <= src1; default: rr0_7 <= src2; endcase
    always_ff @(posedge clk) case (rra0) 2'd0: rr0_8 <= src8; 2'd1: rr0_8 <= src9; 2'd2: rr0_8 <= src10; default: rr0_8 <= src11; endcase
    always_ff @(posedge clk) case (rra0) 2'd0: rr0_9 <= src9; 2'd1: rr0_9 <= src10; 2'd2: rr0_9 <= src11; default: rr0_9 <= src12; endcase
    always_ff @(posedge clk) case (rra0) 2'd0: rr0_10 <= src10; 2'd1: rr0_10 <= src11; 2'd2: rr0_10 <= src12; default: rr0_10 <= src13; endcase
    always_ff @(posedge clk) case (rra0) 2'd0: rr0_11 <= src11; 2'd1: rr0_11 <= src12; 2'd2: rr0_11 <= src13; default: rr0_11 <= src14; endcase
    always_ff @(posedge clk) case (rra0) 2'd0: rr0_12 <= src12; 2'd1: rr0_12 <= src13; 2'd2: rr0_12 <= src14; default: rr0_12 <= src15; endcase
    always_ff @(posedge clk) case (rra0) 2'd0: rr0_13 <= src13; 2'd1: rr0_13 <= src14; 2'd2: rr0_13 <= src15; default: rr0_13 <= src8; endcase
    always_ff @(posedge clk) case (rra0) 2'd0: rr0_14 <= src14; 2'd1: rr0_14 <= src15; 2'd2: rr0_14 <= src8; default: rr0_14 <= src9; endcase
    always_ff @(posedge clk) case (rra0) 2'd0: rr0_15 <= src15; 2'd1: rr0_15 <= src8; 2'd2: rr0_15 <= src9; default: rr0_15 <= src10; endcase
    (* max_fanout = 32 *) logic [0:0] rra1;
    always_ff @(posedge clk) rra1 <= tg4[1] ? '0 : tg4[11:11];
    logic [29:0] rr1_0;
    logic [29:0] rr1_1;
    logic [29:0] rr1_2;
    logic [29:0] rr1_3;
    logic [29:0] rr1_4;
    logic [29:0] rr1_5;
    logic [29:0] rr1_6;
    logic [29:0] rr1_7;
    logic [29:0] rr1_8;
    logic [29:0] rr1_9;
    logic [29:0] rr1_10;
    logic [29:0] rr1_11;
    logic [29:0] rr1_12;
    logic [29:0] rr1_13;
    logic [29:0] rr1_14;
    logic [29:0] rr1_15;
    always_ff @(posedge clk) rr1_0 <= rra1 ? rr0_4 : rr0_0;
    always_ff @(posedge clk) rr1_1 <= rra1 ? rr0_5 : rr0_1;
    always_ff @(posedge clk) rr1_2 <= rra1 ? rr0_6 : rr0_2;
    always_ff @(posedge clk) rr1_3 <= rra1 ? rr0_7 : rr0_3;
    always_ff @(posedge clk) rr1_4 <= rra1 ? rr0_0 : rr0_4;
    always_ff @(posedge clk) rr1_5 <= rra1 ? rr0_1 : rr0_5;
    always_ff @(posedge clk) rr1_6 <= rra1 ? rr0_2 : rr0_6;
    always_ff @(posedge clk) rr1_7 <= rra1 ? rr0_3 : rr0_7;
    always_ff @(posedge clk) rr1_8 <= rra1 ? rr0_12 : rr0_8;
    always_ff @(posedge clk) rr1_9 <= rra1 ? rr0_13 : rr0_9;
    always_ff @(posedge clk) rr1_10 <= rra1 ? rr0_14 : rr0_10;
    always_ff @(posedge clk) rr1_11 <= rra1 ? rr0_15 : rr0_11;
    always_ff @(posedge clk) rr1_12 <= rra1 ? rr0_8 : rr0_12;
    always_ff @(posedge clk) rr1_13 <= rra1 ? rr0_9 : rr0_13;
    always_ff @(posedge clk) rr1_14 <= rra1 ? rr0_10 : rr0_14;
    always_ff @(posedge clk) rr1_15 <= rra1 ? rr0_11 : rr0_15;
    // block input register: lane h + g j <- rotator group h, entry j
    logic [29:0] s0_0;
    logic [29:0] s0_1;
    logic [29:0] s0_2;
    logic [29:0] s0_3;
    logic [29:0] s0_4;
    logic [29:0] s0_5;
    logic [29:0] s0_6;
    logic [29:0] s0_7;
    logic [29:0] s0_8;
    logic [29:0] s0_9;
    logic [29:0] s0_10;
    logic [29:0] s0_11;
    logic [29:0] s0_12;
    logic [29:0] s0_13;
    logic [29:0] s0_14;
    logic [29:0] s0_15;
    always_ff @(posedge clk) s0_0 <= rr1_0;
    always_ff @(posedge clk) s0_2 <= rr1_1;
    always_ff @(posedge clk) s0_4 <= rr1_2;
    always_ff @(posedge clk) s0_6 <= rr1_3;
    always_ff @(posedge clk) s0_8 <= rr1_4;
    always_ff @(posedge clk) s0_10 <= rr1_5;
    always_ff @(posedge clk) s0_12 <= rr1_6;
    always_ff @(posedge clk) s0_14 <= rr1_7;
    always_ff @(posedge clk) s0_1 <= rr1_8;
    always_ff @(posedge clk) s0_3 <= rr1_9;
    always_ff @(posedge clk) s0_5 <= rr1_10;
    always_ff @(posedge clk) s0_7 <= rr1_11;
    always_ff @(posedge clk) s0_9 <= rr1_12;
    always_ff @(posedge clk) s0_11 <= rr1_13;
    always_ff @(posedge clk) s0_13 <= rr1_14;
    always_ff @(posedge clk) s0_15 <= rr1_15;
    // ---- twiddle tables: address {MIDX, DIR, top beat bits}; ROM -> fan-out register -> round mux / W register
    (* max_fanout = 16 *) logic [29:0] tf0;
    logic [2:0] ta0; logic [29:0] tq0;
    always_ff @(posedge clk) ta0 <= 3'({tg2[14:13], tg2[15]});
    ev_ld_io4_k_tw0 u_tw0 (.clk(clk), .addr(ta0), .q0(tq0), .we(ld_en[0]), .wa(ld_a[2:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf0 <= tq0;
    (* max_fanout = 16 *) logic [29:0] tf1;
    logic [2:0] ta1; logic [29:0] tq1;
    always_ff @(posedge clk) ta1 <= 3'({tg14[14:13], tg14[15]});
    ev_ld_io4_k_tw1 u_tw1 (.clk(clk), .addr(ta1), .q0(tq1), .we(ld_en[1]), .wa(ld_a[2:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf1 <= tq1;
    (* max_fanout = 16 *) logic [29:0] tf2;
    logic [2:0] ta2; logic [29:0] tq2;
    always_ff @(posedge clk) ta2 <= 3'({tg14[14:13], tg14[15]});
    ev_ld_io4_k_tw2 u_tw2 (.clk(clk), .addr(ta2), .q0(tq2), .we(ld_en[2]), .wa(ld_a[2:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf2 <= tq2;
    (* max_fanout = 16 *) logic [29:0] tf3;
    logic [2:0] ta3; logic [29:0] tq3;
    always_ff @(posedge clk) ta3 <= 3'({tg26[14:13], tg26[15]});
    ev_ld_io4_k_tw3 u_tw3 (.clk(clk), .addr(ta3), .q0(tq3), .we(ld_en[3]), .wa(ld_a[2:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf3 <= tq3;
    (* max_fanout = 16 *) logic [29:0] tf4;
    logic [2:0] ta4; logic [29:0] tq4;
    always_ff @(posedge clk) ta4 <= 3'({tg26[14:13], tg26[15]});
    ev_ld_io4_k_tw4 u_tw4 (.clk(clk), .addr(ta4), .q0(tq4), .we(ld_en[4]), .wa(ld_a[2:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf4 <= tq4;
    (* max_fanout = 16 *) logic [29:0] tf5;
    logic [2:0] ta5; logic [29:0] tq5;
    always_ff @(posedge clk) ta5 <= 3'({tg26[14:13], tg26[15]});
    ev_ld_io4_k_tw5 u_tw5 (.clk(clk), .addr(ta5), .q0(tq5), .we(ld_en[5]), .wa(ld_a[2:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf5 <= tq5;
    (* max_fanout = 16 *) logic [29:0] tf6;
    logic [2:0] ta6; logic [29:0] tq6;
    always_ff @(posedge clk) ta6 <= 3'({tg26[14:13], tg26[15]});
    ev_ld_io4_k_tw6 u_tw6 (.clk(clk), .addr(ta6), .q0(tq6), .we(ld_en[6]), .wa(ld_a[2:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf6 <= tq6;
    (* max_fanout = 16 *) logic [29:0] tf7;
    logic [5:0] ta7; logic [29:0] tq7;
    always_ff @(posedge clk) ta7 <= 6'({tg2[14:13], tg2[15], tg2[11:9]});
    ev_ld_io4_k_tw7 u_tw7 (.clk(clk), .addr(ta7), .q0(tq7), .we(ld_en[7]), .wa(ld_a[5:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf7 <= tq7;
    (* max_fanout = 16 *) logic [29:0] tf8;
    logic [5:0] ta8; logic [29:0] tq8;
    always_ff @(posedge clk) ta8 <= 6'({tg14[14:13], tg14[15], tg14[11:9]});
    ev_ld_io4_k_tw8 u_tw8 (.clk(clk), .addr(ta8), .q0(tq8), .we(ld_en[8]), .wa(ld_a[5:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf8 <= tq8;
    (* max_fanout = 16 *) logic [29:0] tf9;
    logic [5:0] ta9; logic [29:0] tq9;
    always_ff @(posedge clk) ta9 <= 6'({tg14[14:13], tg14[15], tg14[11:9]});
    ev_ld_io4_k_tw9 u_tw9 (.clk(clk), .addr(ta9), .q0(tq9), .we(ld_en[9]), .wa(ld_a[5:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf9 <= tq9;
    (* max_fanout = 16 *) logic [29:0] tf10;
    logic [5:0] ta10; logic [29:0] tq10;
    always_ff @(posedge clk) ta10 <= 6'({tg26[14:13], tg26[15], tg26[11:9]});
    ev_ld_io4_k_tw10 u_tw10 (.clk(clk), .addr(ta10), .q0(tq10), .we(ld_en[10]), .wa(ld_a[5:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf10 <= tq10;
    (* max_fanout = 16 *) logic [29:0] tf11;
    logic [5:0] ta11; logic [29:0] tq11;
    always_ff @(posedge clk) ta11 <= 6'({tg26[14:13], tg26[15], tg26[11:9]});
    ev_ld_io4_k_tw11 u_tw11 (.clk(clk), .addr(ta11), .q0(tq11), .we(ld_en[11]), .wa(ld_a[5:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf11 <= tq11;
    (* max_fanout = 16 *) logic [29:0] tf12;
    logic [5:0] ta12; logic [29:0] tq12;
    always_ff @(posedge clk) ta12 <= 6'({tg26[14:13], tg26[15], tg26[11:9]});
    ev_ld_io4_k_tw12 u_tw12 (.clk(clk), .addr(ta12), .q0(tq12), .we(ld_en[12]), .wa(ld_a[5:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf12 <= tq12;
    (* max_fanout = 16 *) logic [29:0] tf13;
    logic [5:0] ta13; logic [29:0] tq13;
    always_ff @(posedge clk) ta13 <= 6'({tg26[14:13], tg26[15], tg26[11:9]});
    ev_ld_io4_k_tw13 u_tw13 (.clk(clk), .addr(ta13), .q0(tq13), .we(ld_en[13]), .wa(ld_a[5:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf13 <= tq13;
    (* max_fanout = 16 *) logic [29:0] tf14;
    logic [8:0] ta14; logic [29:0] tq14;
    always_ff @(posedge clk) ta14 <= 9'({tg2[14:13], tg2[15], tg2[11:6]});
    ev_ld_io4_k_tw14 u_tw14 (.clk(clk), .addr(ta14), .q0(tq14), .we(ld_en[14]), .wa(ld_a[8:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf14 <= tq14;
    (* max_fanout = 16 *) logic [29:0] tf15;
    logic [8:0] ta15; logic [29:0] tq15;
    always_ff @(posedge clk) ta15 <= 9'({tg14[14:13], tg14[15], tg14[11:6]});
    ev_ld_io4_k_tw15 u_tw15 (.clk(clk), .addr(ta15), .q0(tq15), .we(ld_en[15]), .wa(ld_a[8:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf15 <= tq15;
    (* max_fanout = 16 *) logic [29:0] tf16;
    logic [8:0] ta16; logic [29:0] tq16;
    always_ff @(posedge clk) ta16 <= 9'({tg14[14:13], tg14[15], tg14[11:6]});
    ev_ld_io4_k_tw16 u_tw16 (.clk(clk), .addr(ta16), .q0(tq16), .we(ld_en[16]), .wa(ld_a[8:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf16 <= tq16;
    (* max_fanout = 16 *) logic [29:0] tf17;
    logic [8:0] ta17; logic [29:0] tq17;
    always_ff @(posedge clk) ta17 <= 9'({tg26[14:13], tg26[15], tg26[11:6]});
    ev_ld_io4_k_tw17 u_tw17 (.clk(clk), .addr(ta17), .q0(tq17), .we(ld_en[17]), .wa(ld_a[8:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf17 <= tq17;
    (* max_fanout = 16 *) logic [29:0] tf18;
    logic [8:0] ta18; logic [29:0] tq18;
    always_ff @(posedge clk) ta18 <= 9'({tg26[14:13], tg26[15], tg26[11:6]});
    ev_ld_io4_k_tw18 u_tw18 (.clk(clk), .addr(ta18), .q0(tq18), .we(ld_en[18]), .wa(ld_a[8:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf18 <= tq18;
    (* max_fanout = 16 *) logic [29:0] tf19;
    logic [8:0] ta19; logic [29:0] tq19;
    always_ff @(posedge clk) ta19 <= 9'({tg26[14:13], tg26[15], tg26[11:6]});
    ev_ld_io4_k_tw19 u_tw19 (.clk(clk), .addr(ta19), .q0(tq19), .we(ld_en[19]), .wa(ld_a[8:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf19 <= tq19;
    (* max_fanout = 16 *) logic [29:0] tf20;
    logic [8:0] ta20; logic [29:0] tq20;
    always_ff @(posedge clk) ta20 <= 9'({tg26[14:13], tg26[15], tg26[11:6]});
    ev_ld_io4_k_tw20 u_tw20 (.clk(clk), .addr(ta20), .q0(tq20), .we(ld_en[20]), .wa(ld_a[8:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf20 <= tq20;
    (* max_fanout = 16 *) logic [29:0] tf21;
    logic [10:0] ta21; logic [29:0] tq21;
    always_ff @(posedge clk) ta21 <= 11'({tg2[14:13], tg2[15], tg2[11:4]});
    ev_ld_io4_k_tw21 u_tw21 (.clk(clk), .addr(ta21), .q0(tq21), .we(ld_en[21]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf21 <= tq21;
    (* max_fanout = 16 *) logic [29:0] tf22;
    logic [10:0] ta22; logic [29:0] tq22;
    always_ff @(posedge clk) ta22 <= 11'({tg2[14:13], tg2[15], tg2[11:4]});
    ev_ld_io4_k_tw22 u_tw22 (.clk(clk), .addr(ta22), .q0(tq22), .we(ld_en[22]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf22 <= tq22;
    (* max_fanout = 16 *) logic [29:0] tf23;
    logic [10:0] ta23; logic [29:0] tq23;
    always_ff @(posedge clk) ta23 <= 11'({tg14[14:13], tg14[15], tg14[11:4]});
    ev_ld_io4_k_tw23 u_tw23 (.clk(clk), .addr(ta23), .q0(tq23), .we(ld_en[23]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf23 <= tq23;
    (* max_fanout = 16 *) logic [29:0] tf24;
    logic [10:0] ta24; logic [29:0] tq24;
    always_ff @(posedge clk) ta24 <= 11'({tg14[14:13], tg14[15], tg14[11:4]});
    ev_ld_io4_k_tw24 u_tw24 (.clk(clk), .addr(ta24), .q0(tq24), .we(ld_en[24]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf24 <= tq24;
    (* max_fanout = 16 *) logic [29:0] tf25;
    logic [10:0] ta25; logic [29:0] tq25;
    always_ff @(posedge clk) ta25 <= 11'({tg14[14:13], tg14[15], tg14[11:4]});
    ev_ld_io4_k_tw25 u_tw25 (.clk(clk), .addr(ta25), .q0(tq25), .we(ld_en[25]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf25 <= tq25;
    (* max_fanout = 16 *) logic [29:0] tf26;
    logic [10:0] ta26; logic [29:0] tq26;
    always_ff @(posedge clk) ta26 <= 11'({tg14[14:13], tg14[15], tg14[11:4]});
    ev_ld_io4_k_tw26 u_tw26 (.clk(clk), .addr(ta26), .q0(tq26), .we(ld_en[26]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf26 <= tq26;
    (* max_fanout = 16 *) logic [29:0] tf27;
    logic [10:0] ta27; logic [29:0] tq27;
    always_ff @(posedge clk) ta27 <= 11'({tg26[14:13], tg26[15], tg26[11:4]});
    ev_ld_io4_k_tw27 u_tw27 (.clk(clk), .addr(ta27), .q0(tq27), .we(ld_en[27]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf27 <= tq27;
    (* max_fanout = 16 *) logic [29:0] tf28;
    logic [10:0] ta28; logic [29:0] tq28;
    always_ff @(posedge clk) ta28 <= 11'({tg26[14:13], tg26[15], tg26[11:4]});
    ev_ld_io4_k_tw28 u_tw28 (.clk(clk), .addr(ta28), .q0(tq28), .we(ld_en[28]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf28 <= tq28;
    (* max_fanout = 16 *) logic [29:0] tf29;
    logic [10:0] ta29; logic [29:0] tq29;
    always_ff @(posedge clk) ta29 <= 11'({tg26[14:13], tg26[15], tg26[11:4]});
    ev_ld_io4_k_tw29 u_tw29 (.clk(clk), .addr(ta29), .q0(tq29), .we(ld_en[29]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf29 <= tq29;
    (* max_fanout = 16 *) logic [29:0] tf30;
    logic [10:0] ta30; logic [29:0] tq30;
    always_ff @(posedge clk) ta30 <= 11'({tg26[14:13], tg26[15], tg26[11:4]});
    ev_ld_io4_k_tw30 u_tw30 (.clk(clk), .addr(ta30), .q0(tq30), .we(ld_en[30]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf30 <= tq30;
    (* max_fanout = 16 *) logic [29:0] tf31;
    logic [10:0] ta31; logic [29:0] tq31;
    always_ff @(posedge clk) ta31 <= 11'({tg26[14:13], tg26[15], tg26[11:4]});
    ev_ld_io4_k_tw31 u_tw31 (.clk(clk), .addr(ta31), .q0(tq31), .we(ld_en[31]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf31 <= tq31;
    (* max_fanout = 16 *) logic [29:0] tf32;
    logic [10:0] ta32; logic [29:0] tq32;
    always_ff @(posedge clk) ta32 <= 11'({tg26[14:13], tg26[15], tg26[11:4]});
    ev_ld_io4_k_tw32 u_tw32 (.clk(clk), .addr(ta32), .q0(tq32), .we(ld_en[32]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf32 <= tq32;
    (* max_fanout = 16 *) logic [29:0] tf33;
    logic [10:0] ta33; logic [29:0] tq33;
    always_ff @(posedge clk) ta33 <= 11'({tg26[14:13], tg26[15], tg26[11:4]});
    ev_ld_io4_k_tw33 u_tw33 (.clk(clk), .addr(ta33), .q0(tq33), .we(ld_en[33]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf33 <= tq33;
    (* max_fanout = 16 *) logic [29:0] tf34;
    logic [10:0] ta34; logic [29:0] tq34;
    always_ff @(posedge clk) ta34 <= 11'({tg26[14:13], tg26[15], tg26[11:4]});
    ev_ld_io4_k_tw34 u_tw34 (.clk(clk), .addr(ta34), .q0(tq34), .we(ld_en[34]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) tf34 <= tq34;
    // ---- the block: 3 stages of 8 butterflies (ev_ld_io4_k_bu, latency 11); stage j pairs lane bit j
    (* max_fanout = 16 *) logic [29:0] q0_Q;
    logic [29:0] hq_bu_Q [4];
    always_ff @(posedge clk) if (ld_en[51]) hq_bu_Q[ld_a[1:0]] <= ld_d[29:0];
    always_ff @(posedge clk) q0_Q <= hq_bu_Q[tg6[14:13]];
    (* max_fanout = 16 *) logic [31:0] q0_MU;
    logic [31:0] hq_bu_MU [4];
    always_ff @(posedge clk) if (ld_en[52]) hq_bu_MU[ld_a[1:0]] <= ld_d[31:0];
    always_ff @(posedge clk) q0_MU <= hq_bu_MU[tg6[14:13]];
    logic [29:0] s1_0;
    logic [29:0] s1_1;
    logic [29:0] s1_2;
    logic [29:0] s1_3;
    logic [29:0] s1_4;
    logic [29:0] s1_5;
    logic [29:0] s1_6;
    logic [29:0] s1_7;
    logic [29:0] s1_8;
    logic [29:0] s1_9;
    logic [29:0] s1_10;
    logic [29:0] s1_11;
    logic [29:0] s1_12;
    logic [29:0] s1_13;
    logic [29:0] s1_14;
    logic [29:0] s1_15;
    logic [29:0] w0_0;
    always_ff @(posedge clk) case (tg6[3:2])
        2'd0: w0_0 <= tf0;
        2'd1: w0_0 <= tf7;
        2'd2: w0_0 <= tf14;
        2'd3: w0_0 <= tf21;
        default: w0_0 <= tf0;
    endcase
    logic [29:0] bx0_0; logic [29:0] by0_0;
    ev_ld_io4_k_bu u_bu0_0 (.clk(clk), .aIn(s0_0), .bIn(s0_1), .W(w0_0[29:0]), .Q(q0_Q), .MU(q0_MU), .aOut(bx0_0), .bOut(by0_0));
    always_ff @(posedge clk) s1_0 <= bx0_0;
    always_ff @(posedge clk) s1_1 <= by0_0;
    logic [29:0] w0_2;
    always_ff @(posedge clk) case (tg6[3:2])
        2'd0: w0_2 <= tf0;
        2'd1: w0_2 <= tf7;
        2'd2: w0_2 <= tf14;
        2'd3: w0_2 <= tf21;
        default: w0_2 <= tf0;
    endcase
    logic [29:0] bx0_2; logic [29:0] by0_2;
    ev_ld_io4_k_bu u_bu0_2 (.clk(clk), .aIn(s0_2), .bIn(s0_3), .W(w0_2[29:0]), .Q(q0_Q), .MU(q0_MU), .aOut(bx0_2), .bOut(by0_2));
    always_ff @(posedge clk) s1_2 <= bx0_2;
    always_ff @(posedge clk) s1_3 <= by0_2;
    logic [29:0] w0_4;
    always_ff @(posedge clk) case (tg6[3:2])
        2'd0: w0_4 <= tf0;
        2'd1: w0_4 <= tf7;
        2'd2: w0_4 <= tf14;
        2'd3: w0_4 <= tf21;
        default: w0_4 <= tf0;
    endcase
    logic [29:0] bx0_4; logic [29:0] by0_4;
    ev_ld_io4_k_bu u_bu0_4 (.clk(clk), .aIn(s0_4), .bIn(s0_5), .W(w0_4[29:0]), .Q(q0_Q), .MU(q0_MU), .aOut(bx0_4), .bOut(by0_4));
    always_ff @(posedge clk) s1_4 <= bx0_4;
    always_ff @(posedge clk) s1_5 <= by0_4;
    logic [29:0] w0_6;
    always_ff @(posedge clk) case (tg6[3:2])
        2'd0: w0_6 <= tf0;
        2'd1: w0_6 <= tf7;
        2'd2: w0_6 <= tf14;
        2'd3: w0_6 <= tf21;
        default: w0_6 <= tf0;
    endcase
    logic [29:0] bx0_6; logic [29:0] by0_6;
    ev_ld_io4_k_bu u_bu0_6 (.clk(clk), .aIn(s0_6), .bIn(s0_7), .W(w0_6[29:0]), .Q(q0_Q), .MU(q0_MU), .aOut(bx0_6), .bOut(by0_6));
    always_ff @(posedge clk) s1_6 <= bx0_6;
    always_ff @(posedge clk) s1_7 <= by0_6;
    logic [29:0] w0_8;
    always_ff @(posedge clk) case (tg6[3:2])
        2'd0: w0_8 <= tf0;
        2'd1: w0_8 <= tf7;
        2'd2: w0_8 <= tf14;
        2'd3: w0_8 <= tf22;
        default: w0_8 <= tf0;
    endcase
    logic [29:0] bx0_8; logic [29:0] by0_8;
    ev_ld_io4_k_bu u_bu0_8 (.clk(clk), .aIn(s0_8), .bIn(s0_9), .W(w0_8[29:0]), .Q(q0_Q), .MU(q0_MU), .aOut(bx0_8), .bOut(by0_8));
    always_ff @(posedge clk) s1_8 <= bx0_8;
    always_ff @(posedge clk) s1_9 <= by0_8;
    logic [29:0] w0_10;
    always_ff @(posedge clk) case (tg6[3:2])
        2'd0: w0_10 <= tf0;
        2'd1: w0_10 <= tf7;
        2'd2: w0_10 <= tf14;
        2'd3: w0_10 <= tf22;
        default: w0_10 <= tf0;
    endcase
    logic [29:0] bx0_10; logic [29:0] by0_10;
    ev_ld_io4_k_bu u_bu0_10 (.clk(clk), .aIn(s0_10), .bIn(s0_11), .W(w0_10[29:0]), .Q(q0_Q), .MU(q0_MU), .aOut(bx0_10), .bOut(by0_10));
    always_ff @(posedge clk) s1_10 <= bx0_10;
    always_ff @(posedge clk) s1_11 <= by0_10;
    logic [29:0] w0_12;
    always_ff @(posedge clk) case (tg6[3:2])
        2'd0: w0_12 <= tf0;
        2'd1: w0_12 <= tf7;
        2'd2: w0_12 <= tf14;
        2'd3: w0_12 <= tf22;
        default: w0_12 <= tf0;
    endcase
    logic [29:0] bx0_12; logic [29:0] by0_12;
    ev_ld_io4_k_bu u_bu0_12 (.clk(clk), .aIn(s0_12), .bIn(s0_13), .W(w0_12[29:0]), .Q(q0_Q), .MU(q0_MU), .aOut(bx0_12), .bOut(by0_12));
    always_ff @(posedge clk) s1_12 <= bx0_12;
    always_ff @(posedge clk) s1_13 <= by0_12;
    logic [29:0] w0_14;
    always_ff @(posedge clk) case (tg6[3:2])
        2'd0: w0_14 <= tf0;
        2'd1: w0_14 <= tf7;
        2'd2: w0_14 <= tf14;
        2'd3: w0_14 <= tf22;
        default: w0_14 <= tf0;
    endcase
    logic [29:0] bx0_14; logic [29:0] by0_14;
    ev_ld_io4_k_bu u_bu0_14 (.clk(clk), .aIn(s0_14), .bIn(s0_15), .W(w0_14[29:0]), .Q(q0_Q), .MU(q0_MU), .aOut(bx0_14), .bOut(by0_14));
    always_ff @(posedge clk) s1_14 <= bx0_14;
    always_ff @(posedge clk) s1_15 <= by0_14;
    (* max_fanout = 16 *) logic [29:0] q1_Q;
    always_ff @(posedge clk) q1_Q <= hq_bu_Q[tg18[14:13]];
    (* max_fanout = 16 *) logic [31:0] q1_MU;
    always_ff @(posedge clk) q1_MU <= hq_bu_MU[tg18[14:13]];
    logic [29:0] s2_0;
    logic [29:0] s2_1;
    logic [29:0] s2_2;
    logic [29:0] s2_3;
    logic [29:0] s2_4;
    logic [29:0] s2_5;
    logic [29:0] s2_6;
    logic [29:0] s2_7;
    logic [29:0] s2_8;
    logic [29:0] s2_9;
    logic [29:0] s2_10;
    logic [29:0] s2_11;
    logic [29:0] s2_12;
    logic [29:0] s2_13;
    logic [29:0] s2_14;
    logic [29:0] s2_15;
    logic [29:0] w1_0;
    always_ff @(posedge clk) case (tg18[3:2])
        2'd0: w1_0 <= tf1;
        2'd1: w1_0 <= tf8;
        2'd2: w1_0 <= tf15;
        2'd3: w1_0 <= tf23;
        default: w1_0 <= tf1;
    endcase
    logic [29:0] bx1_0; logic [29:0] by1_0;
    ev_ld_io4_k_bu u_bu1_0 (.clk(clk), .aIn(s1_0), .bIn(s1_2), .W(w1_0[29:0]), .Q(q1_Q), .MU(q1_MU), .aOut(bx1_0), .bOut(by1_0));
    always_ff @(posedge clk) s2_0 <= bx1_0;
    always_ff @(posedge clk) s2_2 <= by1_0;
    logic [29:0] w1_1;
    always_ff @(posedge clk) case (tg18[3:2])
        2'd0: w1_1 <= tf2;
        2'd1: w1_1 <= tf9;
        2'd2: w1_1 <= tf16;
        2'd3: w1_1 <= tf24;
        default: w1_1 <= tf2;
    endcase
    logic [29:0] bx1_1; logic [29:0] by1_1;
    ev_ld_io4_k_bu u_bu1_1 (.clk(clk), .aIn(s1_1), .bIn(s1_3), .W(w1_1[29:0]), .Q(q1_Q), .MU(q1_MU), .aOut(bx1_1), .bOut(by1_1));
    always_ff @(posedge clk) s2_1 <= bx1_1;
    always_ff @(posedge clk) s2_3 <= by1_1;
    logic [29:0] w1_4;
    always_ff @(posedge clk) case (tg18[3:2])
        2'd0: w1_4 <= tf1;
        2'd1: w1_4 <= tf8;
        2'd2: w1_4 <= tf15;
        2'd3: w1_4 <= tf23;
        default: w1_4 <= tf1;
    endcase
    logic [29:0] bx1_4; logic [29:0] by1_4;
    ev_ld_io4_k_bu u_bu1_4 (.clk(clk), .aIn(s1_4), .bIn(s1_6), .W(w1_4[29:0]), .Q(q1_Q), .MU(q1_MU), .aOut(bx1_4), .bOut(by1_4));
    always_ff @(posedge clk) s2_4 <= bx1_4;
    always_ff @(posedge clk) s2_6 <= by1_4;
    logic [29:0] w1_5;
    always_ff @(posedge clk) case (tg18[3:2])
        2'd0: w1_5 <= tf2;
        2'd1: w1_5 <= tf9;
        2'd2: w1_5 <= tf16;
        2'd3: w1_5 <= tf24;
        default: w1_5 <= tf2;
    endcase
    logic [29:0] bx1_5; logic [29:0] by1_5;
    ev_ld_io4_k_bu u_bu1_5 (.clk(clk), .aIn(s1_5), .bIn(s1_7), .W(w1_5[29:0]), .Q(q1_Q), .MU(q1_MU), .aOut(bx1_5), .bOut(by1_5));
    always_ff @(posedge clk) s2_5 <= bx1_5;
    always_ff @(posedge clk) s2_7 <= by1_5;
    logic [29:0] w1_8;
    always_ff @(posedge clk) case (tg18[3:2])
        2'd0: w1_8 <= tf1;
        2'd1: w1_8 <= tf8;
        2'd2: w1_8 <= tf15;
        2'd3: w1_8 <= tf25;
        default: w1_8 <= tf1;
    endcase
    logic [29:0] bx1_8; logic [29:0] by1_8;
    ev_ld_io4_k_bu u_bu1_8 (.clk(clk), .aIn(s1_8), .bIn(s1_10), .W(w1_8[29:0]), .Q(q1_Q), .MU(q1_MU), .aOut(bx1_8), .bOut(by1_8));
    always_ff @(posedge clk) s2_8 <= bx1_8;
    always_ff @(posedge clk) s2_10 <= by1_8;
    logic [29:0] w1_9;
    always_ff @(posedge clk) case (tg18[3:2])
        2'd0: w1_9 <= tf2;
        2'd1: w1_9 <= tf9;
        2'd2: w1_9 <= tf16;
        2'd3: w1_9 <= tf26;
        default: w1_9 <= tf2;
    endcase
    logic [29:0] bx1_9; logic [29:0] by1_9;
    ev_ld_io4_k_bu u_bu1_9 (.clk(clk), .aIn(s1_9), .bIn(s1_11), .W(w1_9[29:0]), .Q(q1_Q), .MU(q1_MU), .aOut(bx1_9), .bOut(by1_9));
    always_ff @(posedge clk) s2_9 <= bx1_9;
    always_ff @(posedge clk) s2_11 <= by1_9;
    logic [29:0] w1_12;
    always_ff @(posedge clk) case (tg18[3:2])
        2'd0: w1_12 <= tf1;
        2'd1: w1_12 <= tf8;
        2'd2: w1_12 <= tf15;
        2'd3: w1_12 <= tf25;
        default: w1_12 <= tf1;
    endcase
    logic [29:0] bx1_12; logic [29:0] by1_12;
    ev_ld_io4_k_bu u_bu1_12 (.clk(clk), .aIn(s1_12), .bIn(s1_14), .W(w1_12[29:0]), .Q(q1_Q), .MU(q1_MU), .aOut(bx1_12), .bOut(by1_12));
    always_ff @(posedge clk) s2_12 <= bx1_12;
    always_ff @(posedge clk) s2_14 <= by1_12;
    logic [29:0] w1_13;
    always_ff @(posedge clk) case (tg18[3:2])
        2'd0: w1_13 <= tf2;
        2'd1: w1_13 <= tf9;
        2'd2: w1_13 <= tf16;
        2'd3: w1_13 <= tf26;
        default: w1_13 <= tf2;
    endcase
    logic [29:0] bx1_13; logic [29:0] by1_13;
    ev_ld_io4_k_bu u_bu1_13 (.clk(clk), .aIn(s1_13), .bIn(s1_15), .W(w1_13[29:0]), .Q(q1_Q), .MU(q1_MU), .aOut(bx1_13), .bOut(by1_13));
    always_ff @(posedge clk) s2_13 <= bx1_13;
    always_ff @(posedge clk) s2_15 <= by1_13;
    (* max_fanout = 16 *) logic [29:0] q2_Q;
    always_ff @(posedge clk) q2_Q <= hq_bu_Q[tg30[14:13]];
    (* max_fanout = 16 *) logic [31:0] q2_MU;
    always_ff @(posedge clk) q2_MU <= hq_bu_MU[tg30[14:13]];
    logic [29:0] s3_0;
    logic [29:0] s3_1;
    logic [29:0] s3_2;
    logic [29:0] s3_3;
    logic [29:0] s3_4;
    logic [29:0] s3_5;
    logic [29:0] s3_6;
    logic [29:0] s3_7;
    logic [29:0] s3_8;
    logic [29:0] s3_9;
    logic [29:0] s3_10;
    logic [29:0] s3_11;
    logic [29:0] s3_12;
    logic [29:0] s3_13;
    logic [29:0] s3_14;
    logic [29:0] s3_15;
    logic [29:0] w2_0;
    always_ff @(posedge clk) case (tg30[3:2])
        2'd0: w2_0 <= tf3;
        2'd1: w2_0 <= tf10;
        2'd2: w2_0 <= tf17;
        2'd3: w2_0 <= tf27;
        default: w2_0 <= tf3;
    endcase
    logic [29:0] bx2_0; logic [29:0] by2_0;
    ev_ld_io4_k_bu u_bu2_0 (.clk(clk), .aIn(s2_0), .bIn(s2_4), .W(w2_0[29:0]), .Q(q2_Q), .MU(q2_MU), .aOut(bx2_0), .bOut(by2_0));
    always_ff @(posedge clk) s3_0 <= bx2_0;
    always_ff @(posedge clk) s3_4 <= by2_0;
    logic [29:0] w2_1;
    always_ff @(posedge clk) case (tg30[3:2])
        2'd0: w2_1 <= tf4;
        2'd1: w2_1 <= tf11;
        2'd2: w2_1 <= tf18;
        2'd3: w2_1 <= tf28;
        default: w2_1 <= tf4;
    endcase
    logic [29:0] bx2_1; logic [29:0] by2_1;
    ev_ld_io4_k_bu u_bu2_1 (.clk(clk), .aIn(s2_1), .bIn(s2_5), .W(w2_1[29:0]), .Q(q2_Q), .MU(q2_MU), .aOut(bx2_1), .bOut(by2_1));
    always_ff @(posedge clk) s3_1 <= bx2_1;
    always_ff @(posedge clk) s3_5 <= by2_1;
    logic [29:0] w2_2;
    always_ff @(posedge clk) case (tg30[3:2])
        2'd0: w2_2 <= tf5;
        2'd1: w2_2 <= tf12;
        2'd2: w2_2 <= tf19;
        2'd3: w2_2 <= tf29;
        default: w2_2 <= tf5;
    endcase
    logic [29:0] bx2_2; logic [29:0] by2_2;
    ev_ld_io4_k_bu u_bu2_2 (.clk(clk), .aIn(s2_2), .bIn(s2_6), .W(w2_2[29:0]), .Q(q2_Q), .MU(q2_MU), .aOut(bx2_2), .bOut(by2_2));
    always_ff @(posedge clk) s3_2 <= bx2_2;
    always_ff @(posedge clk) s3_6 <= by2_2;
    logic [29:0] w2_3;
    always_ff @(posedge clk) case (tg30[3:2])
        2'd0: w2_3 <= tf6;
        2'd1: w2_3 <= tf13;
        2'd2: w2_3 <= tf20;
        2'd3: w2_3 <= tf30;
        default: w2_3 <= tf6;
    endcase
    logic [29:0] bx2_3; logic [29:0] by2_3;
    ev_ld_io4_k_bu u_bu2_3 (.clk(clk), .aIn(s2_3), .bIn(s2_7), .W(w2_3[29:0]), .Q(q2_Q), .MU(q2_MU), .aOut(bx2_3), .bOut(by2_3));
    always_ff @(posedge clk) s3_3 <= bx2_3;
    always_ff @(posedge clk) s3_7 <= by2_3;
    logic [29:0] w2_8;
    always_ff @(posedge clk) case (tg30[3:2])
        2'd0: w2_8 <= tf3;
        2'd1: w2_8 <= tf10;
        2'd2: w2_8 <= tf17;
        2'd3: w2_8 <= tf31;
        default: w2_8 <= tf3;
    endcase
    logic [29:0] bx2_8; logic [29:0] by2_8;
    ev_ld_io4_k_bu u_bu2_8 (.clk(clk), .aIn(s2_8), .bIn(s2_12), .W(w2_8[29:0]), .Q(q2_Q), .MU(q2_MU), .aOut(bx2_8), .bOut(by2_8));
    always_ff @(posedge clk) s3_8 <= bx2_8;
    always_ff @(posedge clk) s3_12 <= by2_8;
    logic [29:0] w2_9;
    always_ff @(posedge clk) case (tg30[3:2])
        2'd0: w2_9 <= tf4;
        2'd1: w2_9 <= tf11;
        2'd2: w2_9 <= tf18;
        2'd3: w2_9 <= tf32;
        default: w2_9 <= tf4;
    endcase
    logic [29:0] bx2_9; logic [29:0] by2_9;
    ev_ld_io4_k_bu u_bu2_9 (.clk(clk), .aIn(s2_9), .bIn(s2_13), .W(w2_9[29:0]), .Q(q2_Q), .MU(q2_MU), .aOut(bx2_9), .bOut(by2_9));
    always_ff @(posedge clk) s3_9 <= bx2_9;
    always_ff @(posedge clk) s3_13 <= by2_9;
    logic [29:0] w2_10;
    always_ff @(posedge clk) case (tg30[3:2])
        2'd0: w2_10 <= tf5;
        2'd1: w2_10 <= tf12;
        2'd2: w2_10 <= tf19;
        2'd3: w2_10 <= tf33;
        default: w2_10 <= tf5;
    endcase
    logic [29:0] bx2_10; logic [29:0] by2_10;
    ev_ld_io4_k_bu u_bu2_10 (.clk(clk), .aIn(s2_10), .bIn(s2_14), .W(w2_10[29:0]), .Q(q2_Q), .MU(q2_MU), .aOut(bx2_10), .bOut(by2_10));
    always_ff @(posedge clk) s3_10 <= bx2_10;
    always_ff @(posedge clk) s3_14 <= by2_10;
    logic [29:0] w2_11;
    always_ff @(posedge clk) case (tg30[3:2])
        2'd0: w2_11 <= tf6;
        2'd1: w2_11 <= tf13;
        2'd2: w2_11 <= tf20;
        2'd3: w2_11 <= tf34;
        default: w2_11 <= tf6;
    endcase
    logic [29:0] bx2_11; logic [29:0] by2_11;
    ev_ld_io4_k_bu u_bu2_11 (.clk(clk), .aIn(s2_11), .bIn(s2_15), .W(w2_11[29:0]), .Q(q2_Q), .MU(q2_MU), .aOut(bx2_11), .bOut(by2_11));
    always_ff @(posedge clk) s3_11 <= bx2_11;
    always_ff @(posedge clk) s3_15 <= by2_11;
    // ---- write path: bank hi*2^U + ((lo + c) mod 2^U) <- lane hi*2^U + lo
    (* max_fanout = 32 *) logic [1:0] wra0;
    always_ff @(posedge clk) wra0 <= tg42[5:4];
    logic [29:0] wr0_0;
    logic [29:0] wr0_1;
    logic [29:0] wr0_2;
    logic [29:0] wr0_3;
    logic [29:0] wr0_4;
    logic [29:0] wr0_5;
    logic [29:0] wr0_6;
    logic [29:0] wr0_7;
    logic [29:0] wr0_8;
    logic [29:0] wr0_9;
    logic [29:0] wr0_10;
    logic [29:0] wr0_11;
    logic [29:0] wr0_12;
    logic [29:0] wr0_13;
    logic [29:0] wr0_14;
    logic [29:0] wr0_15;
    always_ff @(posedge clk) case (wra0) 2'd0: wr0_0 <= s3_0; 2'd1: wr0_0 <= s3_7; 2'd2: wr0_0 <= s3_6; default: wr0_0 <= s3_5; endcase
    always_ff @(posedge clk) case (wra0) 2'd0: wr0_1 <= s3_1; 2'd1: wr0_1 <= s3_0; 2'd2: wr0_1 <= s3_7; default: wr0_1 <= s3_6; endcase
    always_ff @(posedge clk) case (wra0) 2'd0: wr0_2 <= s3_2; 2'd1: wr0_2 <= s3_1; 2'd2: wr0_2 <= s3_0; default: wr0_2 <= s3_7; endcase
    always_ff @(posedge clk) case (wra0) 2'd0: wr0_3 <= s3_3; 2'd1: wr0_3 <= s3_2; 2'd2: wr0_3 <= s3_1; default: wr0_3 <= s3_0; endcase
    always_ff @(posedge clk) case (wra0) 2'd0: wr0_4 <= s3_4; 2'd1: wr0_4 <= s3_3; 2'd2: wr0_4 <= s3_2; default: wr0_4 <= s3_1; endcase
    always_ff @(posedge clk) case (wra0) 2'd0: wr0_5 <= s3_5; 2'd1: wr0_5 <= s3_4; 2'd2: wr0_5 <= s3_3; default: wr0_5 <= s3_2; endcase
    always_ff @(posedge clk) case (wra0) 2'd0: wr0_6 <= s3_6; 2'd1: wr0_6 <= s3_5; 2'd2: wr0_6 <= s3_4; default: wr0_6 <= s3_3; endcase
    always_ff @(posedge clk) case (wra0) 2'd0: wr0_7 <= s3_7; 2'd1: wr0_7 <= s3_6; 2'd2: wr0_7 <= s3_5; default: wr0_7 <= s3_4; endcase
    always_ff @(posedge clk) case (wra0) 2'd0: wr0_8 <= s3_8; 2'd1: wr0_8 <= s3_15; 2'd2: wr0_8 <= s3_14; default: wr0_8 <= s3_13; endcase
    always_ff @(posedge clk) case (wra0) 2'd0: wr0_9 <= s3_9; 2'd1: wr0_9 <= s3_8; 2'd2: wr0_9 <= s3_15; default: wr0_9 <= s3_14; endcase
    always_ff @(posedge clk) case (wra0) 2'd0: wr0_10 <= s3_10; 2'd1: wr0_10 <= s3_9; 2'd2: wr0_10 <= s3_8; default: wr0_10 <= s3_15; endcase
    always_ff @(posedge clk) case (wra0) 2'd0: wr0_11 <= s3_11; 2'd1: wr0_11 <= s3_10; 2'd2: wr0_11 <= s3_9; default: wr0_11 <= s3_8; endcase
    always_ff @(posedge clk) case (wra0) 2'd0: wr0_12 <= s3_12; 2'd1: wr0_12 <= s3_11; 2'd2: wr0_12 <= s3_10; default: wr0_12 <= s3_9; endcase
    always_ff @(posedge clk) case (wra0) 2'd0: wr0_13 <= s3_13; 2'd1: wr0_13 <= s3_12; 2'd2: wr0_13 <= s3_11; default: wr0_13 <= s3_10; endcase
    always_ff @(posedge clk) case (wra0) 2'd0: wr0_14 <= s3_14; 2'd1: wr0_14 <= s3_13; 2'd2: wr0_14 <= s3_12; default: wr0_14 <= s3_11; endcase
    always_ff @(posedge clk) case (wra0) 2'd0: wr0_15 <= s3_15; 2'd1: wr0_15 <= s3_14; 2'd2: wr0_15 <= s3_13; default: wr0_15 <= s3_12; endcase
    (* max_fanout = 32 *) logic [0:0] wra1;
    always_ff @(posedge clk) wra1 <= tg43[6:6];
    logic [29:0] wr1_0;
    logic [29:0] wr1_1;
    logic [29:0] wr1_2;
    logic [29:0] wr1_3;
    logic [29:0] wr1_4;
    logic [29:0] wr1_5;
    logic [29:0] wr1_6;
    logic [29:0] wr1_7;
    logic [29:0] wr1_8;
    logic [29:0] wr1_9;
    logic [29:0] wr1_10;
    logic [29:0] wr1_11;
    logic [29:0] wr1_12;
    logic [29:0] wr1_13;
    logic [29:0] wr1_14;
    logic [29:0] wr1_15;
    always_ff @(posedge clk) wr1_0 <= wra1 ? wr0_4 : wr0_0;
    always_ff @(posedge clk) wr1_1 <= wra1 ? wr0_5 : wr0_1;
    always_ff @(posedge clk) wr1_2 <= wra1 ? wr0_6 : wr0_2;
    always_ff @(posedge clk) wr1_3 <= wra1 ? wr0_7 : wr0_3;
    always_ff @(posedge clk) wr1_4 <= wra1 ? wr0_0 : wr0_4;
    always_ff @(posedge clk) wr1_5 <= wra1 ? wr0_1 : wr0_5;
    always_ff @(posedge clk) wr1_6 <= wra1 ? wr0_2 : wr0_6;
    always_ff @(posedge clk) wr1_7 <= wra1 ? wr0_3 : wr0_7;
    always_ff @(posedge clk) wr1_8 <= wra1 ? wr0_12 : wr0_8;
    always_ff @(posedge clk) wr1_9 <= wra1 ? wr0_13 : wr0_9;
    always_ff @(posedge clk) wr1_10 <= wra1 ? wr0_14 : wr0_10;
    always_ff @(posedge clk) wr1_11 <= wra1 ? wr0_15 : wr0_11;
    always_ff @(posedge clk) wr1_12 <= wra1 ? wr0_8 : wr0_12;
    always_ff @(posedge clk) wr1_13 <= wra1 ? wr0_9 : wr0_13;
    always_ff @(posedge clk) wr1_14 <= wra1 ? wr0_10 : wr0_14;
    always_ff @(posedge clk) wr1_15 <= wra1 ? wr0_11 : wr0_15;
    always_ff @(posedge clk) begin
        pw_e <= vch[44] && !tg45[0];
        pw_a <= 9'(tg45[12]) * 9'(256) + 9'(tg45[11:4]);
    end
    always_ff @(posedge clk) pw_d0 <= wr1_0;
    always_ff @(posedge clk) pw_d1 <= wr1_1;
    always_ff @(posedge clk) pw_d2 <= wr1_2;
    always_ff @(posedge clk) pw_d3 <= wr1_3;
    always_ff @(posedge clk) pw_d4 <= wr1_4;
    always_ff @(posedge clk) pw_d5 <= wr1_5;
    always_ff @(posedge clk) pw_d6 <= wr1_6;
    always_ff @(posedge clk) pw_d7 <= wr1_7;
    always_ff @(posedge clk) pw_d8 <= wr1_8;
    always_ff @(posedge clk) pw_d9 <= wr1_9;
    always_ff @(posedge clk) pw_d10 <= wr1_10;
    always_ff @(posedge clk) pw_d11 <= wr1_11;
    always_ff @(posedge clk) pw_d12 <= wr1_12;
    always_ff @(posedge clk) pw_d13 <= wr1_13;
    always_ff @(posedge clk) pw_d14 <= wr1_14;
    always_ff @(posedge clk) pw_d15 <= wr1_15;
    // ---- output: the last round's block output (through the twist multipliers)
    (* max_fanout = 16 *) logic [29:0] tq_Q;
    logic [29:0] hq_twist_Q [4];
    always_ff @(posedge clk) if (ld_en[53]) hq_twist_Q[ld_a[1:0]] <= ld_d[29:0];
    always_ff @(posedge clk) tq_Q <= hq_twist_Q[tg42[14:13]];
    (* max_fanout = 16 *) logic [31:0] tq_MU;
    logic [31:0] hq_twist_MU [4];
    always_ff @(posedge clk) if (ld_en[54]) hq_twist_MU[ld_a[1:0]] <= ld_d[31:0];
    always_ff @(posedge clk) tq_MU <= hq_twist_MU[tg42[14:13]];
    (* max_fanout = 16 *) logic [10:0] tta;
    always_ff @(posedge clk) tta <= 11'({tg39[14:13], tg39[15], tg39[11:4]});
    logic [29:0] ttr0, ttb0; logic [29:0] tp0;
    ev_ld_io4_k_tt0 u_tt0 (.clk(clk), .addr(tta), .q0(ttr0), .we(ld_en[35]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) ttb0 <= ttr0;
    logic [29:0] ttr1, ttb1; logic [29:0] tp1;
    ev_ld_io4_k_tt1 u_tt1 (.clk(clk), .addr(tta), .q0(ttr1), .we(ld_en[36]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) ttb1 <= ttr1;
    logic [29:0] ttr2, ttb2; logic [29:0] tp2;
    ev_ld_io4_k_tt2 u_tt2 (.clk(clk), .addr(tta), .q0(ttr2), .we(ld_en[37]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) ttb2 <= ttr2;
    logic [29:0] ttr3, ttb3; logic [29:0] tp3;
    ev_ld_io4_k_tt3 u_tt3 (.clk(clk), .addr(tta), .q0(ttr3), .we(ld_en[38]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) ttb3 <= ttr3;
    logic [29:0] ttr4, ttb4; logic [29:0] tp4;
    ev_ld_io4_k_tt4 u_tt4 (.clk(clk), .addr(tta), .q0(ttr4), .we(ld_en[39]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) ttb4 <= ttr4;
    logic [29:0] ttr5, ttb5; logic [29:0] tp5;
    ev_ld_io4_k_tt5 u_tt5 (.clk(clk), .addr(tta), .q0(ttr5), .we(ld_en[40]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) ttb5 <= ttr5;
    logic [29:0] ttr6, ttb6; logic [29:0] tp6;
    ev_ld_io4_k_tt6 u_tt6 (.clk(clk), .addr(tta), .q0(ttr6), .we(ld_en[41]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) ttb6 <= ttr6;
    logic [29:0] ttr7, ttb7; logic [29:0] tp7;
    ev_ld_io4_k_tt7 u_tt7 (.clk(clk), .addr(tta), .q0(ttr7), .we(ld_en[42]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) ttb7 <= ttr7;
    logic [29:0] ttr8, ttb8; logic [29:0] tp8;
    ev_ld_io4_k_tt8 u_tt8 (.clk(clk), .addr(tta), .q0(ttr8), .we(ld_en[43]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) ttb8 <= ttr8;
    logic [29:0] ttr9, ttb9; logic [29:0] tp9;
    ev_ld_io4_k_tt9 u_tt9 (.clk(clk), .addr(tta), .q0(ttr9), .we(ld_en[44]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) ttb9 <= ttr9;
    logic [29:0] ttr10, ttb10; logic [29:0] tp10;
    ev_ld_io4_k_tt10 u_tt10 (.clk(clk), .addr(tta), .q0(ttr10), .we(ld_en[45]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) ttb10 <= ttr10;
    logic [29:0] ttr11, ttb11; logic [29:0] tp11;
    ev_ld_io4_k_tt11 u_tt11 (.clk(clk), .addr(tta), .q0(ttr11), .we(ld_en[46]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) ttb11 <= ttr11;
    logic [29:0] ttr12, ttb12; logic [29:0] tp12;
    ev_ld_io4_k_tt12 u_tt12 (.clk(clk), .addr(tta), .q0(ttr12), .we(ld_en[47]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) ttb12 <= ttr12;
    logic [29:0] ttr13, ttb13; logic [29:0] tp13;
    ev_ld_io4_k_tt13 u_tt13 (.clk(clk), .addr(tta), .q0(ttr13), .we(ld_en[48]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) ttb13 <= ttr13;
    logic [29:0] ttr14, ttb14; logic [29:0] tp14;
    ev_ld_io4_k_tt14 u_tt14 (.clk(clk), .addr(tta), .q0(ttr14), .we(ld_en[49]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) ttb14 <= ttr14;
    logic [29:0] ttr15, ttb15; logic [29:0] tp15;
    ev_ld_io4_k_tt15 u_tt15 (.clk(clk), .addr(tta), .q0(ttr15), .we(ld_en[50]), .wa(ld_a[10:0]), .wd(ld_d[29:0]));
    always_ff @(posedge clk) ttb15 <= ttr15;
    ev_ld_io4_k_twist u_twist0 (.clk(clk), .A(s3_0), .B(ttb0), .Q(tq_Q), .MU(tq_MU), .P(tp0));
    always_ff @(posedge clk) y_out_0 <= 30'(tp0);
    ev_ld_io4_k_twist u_twist1 (.clk(clk), .A(s3_1), .B(ttb1), .Q(tq_Q), .MU(tq_MU), .P(tp1));
    always_ff @(posedge clk) y_out_1 <= 30'(tp1);
    ev_ld_io4_k_twist u_twist2 (.clk(clk), .A(s3_2), .B(ttb2), .Q(tq_Q), .MU(tq_MU), .P(tp2));
    always_ff @(posedge clk) y_out_2 <= 30'(tp2);
    ev_ld_io4_k_twist u_twist3 (.clk(clk), .A(s3_3), .B(ttb3), .Q(tq_Q), .MU(tq_MU), .P(tp3));
    always_ff @(posedge clk) y_out_3 <= 30'(tp3);
    ev_ld_io4_k_twist u_twist4 (.clk(clk), .A(s3_4), .B(ttb4), .Q(tq_Q), .MU(tq_MU), .P(tp4));
    always_ff @(posedge clk) y_out_4 <= 30'(tp4);
    ev_ld_io4_k_twist u_twist5 (.clk(clk), .A(s3_5), .B(ttb5), .Q(tq_Q), .MU(tq_MU), .P(tp5));
    always_ff @(posedge clk) y_out_5 <= 30'(tp5);
    ev_ld_io4_k_twist u_twist6 (.clk(clk), .A(s3_6), .B(ttb6), .Q(tq_Q), .MU(tq_MU), .P(tp6));
    always_ff @(posedge clk) y_out_6 <= 30'(tp6);
    ev_ld_io4_k_twist u_twist7 (.clk(clk), .A(s3_7), .B(ttb7), .Q(tq_Q), .MU(tq_MU), .P(tp7));
    always_ff @(posedge clk) y_out_7 <= 30'(tp7);
    ev_ld_io4_k_twist u_twist8 (.clk(clk), .A(s3_8), .B(ttb8), .Q(tq_Q), .MU(tq_MU), .P(tp8));
    always_ff @(posedge clk) y_out_8 <= 30'(tp8);
    ev_ld_io4_k_twist u_twist9 (.clk(clk), .A(s3_9), .B(ttb9), .Q(tq_Q), .MU(tq_MU), .P(tp9));
    always_ff @(posedge clk) y_out_9 <= 30'(tp9);
    ev_ld_io4_k_twist u_twist10 (.clk(clk), .A(s3_10), .B(ttb10), .Q(tq_Q), .MU(tq_MU), .P(tp10));
    always_ff @(posedge clk) y_out_10 <= 30'(tp10);
    ev_ld_io4_k_twist u_twist11 (.clk(clk), .A(s3_11), .B(ttb11), .Q(tq_Q), .MU(tq_MU), .P(tp11));
    always_ff @(posedge clk) y_out_11 <= 30'(tp11);
    ev_ld_io4_k_twist u_twist12 (.clk(clk), .A(s3_12), .B(ttb12), .Q(tq_Q), .MU(tq_MU), .P(tp12));
    always_ff @(posedge clk) y_out_12 <= 30'(tp12);
    ev_ld_io4_k_twist u_twist13 (.clk(clk), .A(s3_13), .B(ttb13), .Q(tq_Q), .MU(tq_MU), .P(tp13));
    always_ff @(posedge clk) y_out_13 <= 30'(tp13);
    ev_ld_io4_k_twist u_twist14 (.clk(clk), .A(s3_14), .B(ttb14), .Q(tq_Q), .MU(tq_MU), .P(tp14));
    always_ff @(posedge clk) y_out_14 <= 30'(tp14);
    ev_ld_io4_k_twist u_twist15 (.clk(clk), .A(s3_15), .B(ttb15), .Q(tq_Q), .MU(tq_MU), .P(tp15));
    always_ff @(posedge clk) y_out_15 <= 30'(tp15);
    always_ff @(posedge clk) begin
        out_valid <= rst ? 1'b0 : (vch[51] && tg52[0]);
        midx_out <= tg52[14:13];
        dir_out <= tg52[15];
    end
    always_ff @(posedge clk) vch <= rst ? '0 : {vch[50:0], iss};
    always_ff @(posedge clk) tg2 <= tg1;
    always_ff @(posedge clk) tg3 <= tg2;
    always_ff @(posedge clk) tg4 <= tg3;
    always_ff @(posedge clk) tg5 <= tg4;
    always_ff @(posedge clk) tg6 <= tg5;
    always_ff @(posedge clk) tg7 <= tg6;
    always_ff @(posedge clk) tg8 <= tg7;
    always_ff @(posedge clk) tg9 <= tg8;
    always_ff @(posedge clk) tg10 <= tg9;
    always_ff @(posedge clk) tg11 <= tg10;
    always_ff @(posedge clk) tg12 <= tg11;
    always_ff @(posedge clk) tg13 <= tg12;
    always_ff @(posedge clk) tg14 <= tg13;
    always_ff @(posedge clk) tg15 <= tg14;
    always_ff @(posedge clk) tg16 <= tg15;
    always_ff @(posedge clk) tg17 <= tg16;
    always_ff @(posedge clk) tg18 <= tg17;
    always_ff @(posedge clk) tg19 <= tg18;
    always_ff @(posedge clk) tg20 <= tg19;
    always_ff @(posedge clk) tg21 <= tg20;
    always_ff @(posedge clk) tg22 <= tg21;
    always_ff @(posedge clk) tg23 <= tg22;
    always_ff @(posedge clk) tg24 <= tg23;
    always_ff @(posedge clk) tg25 <= tg24;
    always_ff @(posedge clk) tg26 <= tg25;
    always_ff @(posedge clk) tg27 <= tg26;
    always_ff @(posedge clk) tg28 <= tg27;
    always_ff @(posedge clk) tg29 <= tg28;
    always_ff @(posedge clk) tg30 <= tg29;
    always_ff @(posedge clk) tg31 <= tg30;
    always_ff @(posedge clk) tg32 <= tg31;
    always_ff @(posedge clk) tg33 <= tg32;
    always_ff @(posedge clk) tg34 <= tg33;
    always_ff @(posedge clk) tg35 <= tg34;
    always_ff @(posedge clk) tg36 <= tg35;
    always_ff @(posedge clk) tg37 <= tg36;
    always_ff @(posedge clk) tg38 <= tg37;
    always_ff @(posedge clk) tg39 <= tg38;
    always_ff @(posedge clk) tg40 <= tg39;
    always_ff @(posedge clk) tg41 <= tg40;
    always_ff @(posedge clk) tg42 <= tg41;
    always_ff @(posedge clk) tg43 <= tg42;
    always_ff @(posedge clk) tg44 <= tg43;
    always_ff @(posedge clk) tg45 <= tg44;
    always_ff @(posedge clk) tg46 <= tg45;
    always_ff @(posedge clk) tg47 <= tg46;
    always_ff @(posedge clk) tg48 <= tg47;
    always_ff @(posedge clk) tg49 <= tg48;
    always_ff @(posedge clk) tg50 <= tg49;
    always_ff @(posedge clk) tg51 <= tg50;
    always_ff @(posedge clk) tg52 <= tg51;
endmodule
