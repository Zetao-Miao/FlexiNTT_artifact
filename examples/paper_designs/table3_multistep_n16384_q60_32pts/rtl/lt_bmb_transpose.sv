// -----------------------------------------------------------------------------
// Module      : lt_bmb_transpose
// Description : Lane-time transpose of a stream of S lanes: the s = log2(S)
//               lane bits are exchanged with the cycle bits [LO, LO+s). The
//               element at cycle (hi, r, lo), lane u leaves at cycle
//               (hi, u, lo), lane r. LO = 0 is the S x S transpose of
//               bmb_matrix_transpose; LO > 0 interleaves 2^LO of them over a
//               window of WIN = S * 2^LO cycles.
//
//               Barrel shifter, one memory of WIN words per lane, barrel
//               shifter: row (r, lo) is rotated by r and lane i stores it at
//               {r, lo} (even windows) or {i - r, lo} (odd windows); the drain
//               of a window starts with its last row and reads, at step
//               (c, lo), {i - c, lo} (even) or {c, lo} (odd); the second
//               shifter rotates by -c. The next window writes each cell in the
//               cycle the drain reads it or later (read-first memory), so
//               windows follow back to back with any gap between bursts.
//
//               Latency  : WIN + 2 * BARREL_LATENCY + 1 cycles, a constant
//                          for every element (a sideband delayed by it stays
//                          aligned)
//               Protocol : data_valid high for whole windows
//
// Parameters  : S, LO, ELEMENT_WIDTH, REG_FLAGS (barrel_shift),
//               RAM_STYLE ("distributed" | "block" | "ultra" | "auto")
// Twin        : versal_arith/lt_transpose_model.py, LtBmbTranspose
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps

module lt_bmb_transpose #(
  parameter int          S             = 16,
  parameter int          LO            = 0,
  parameter int          ELEMENT_WIDTH = 64,
  parameter logic [31:0] REG_FLAGS     = 32'hFFFF_FFFF,
  parameter              RAM_STYLE     = "auto"
) (
  input  logic                     clk,
  input  logic                     rst,
  input  logic                     data_valid,
  input  logic [ELEMENT_WIDTH-1:0] data_in  [0:S-1],

  output logic                     data_out_valid,
  output logic [ELEMENT_WIDTH-1:0] data_out [0:S-1]
);

  localparam int D              = $clog2(S);
  localparam int A              = D + LO;
  localparam int WIN            = S << LO;
  localparam int STAGES         = (D + 1) / 2;
  localparam int BARREL_LATENCY = $countones(REG_FLAGS[STAGES-1:0]);

  // write side: the position in the window, the window's storage phase
  logic [A-1:0] wr_cnt   = '0;
  logic         wr_phase = 1'b0;

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_cnt <= '0;
    end else if (data_valid) begin
      wr_cnt <= wr_cnt + 1'b1;
      if (&wr_cnt) wr_phase <= ~wr_phase;
    end else begin
      wr_cnt <= '0;
    end
  end

  logic [ELEMENT_WIDTH-1:0] bs0_out [0:S-1];
  logic                     wr_valid_d;
  logic                     wr_phase_d;
  logic [A-1:0]             wr_cnt_d;

  barrel_shift #(.STREAM_SIZE(S), .ELEMENT_WIDTH(ELEMENT_WIDTH), .REG_FLAGS(REG_FLAGS)) u_bs0 (
    .clk(clk), .data_in(data_in), .shift(wr_cnt[A-1:LO]), .data_out(bs0_out));

  delay_line #(.WIDTH(A + 2), .DEPTH(BARREL_LATENCY)) u_wr_sb (
    .clk(clk), .d({data_valid, wr_phase, wr_cnt}), .q({wr_valid_d, wr_phase_d, wr_cnt_d}));

  // drain
  logic         rd_active = 1'b0;
  logic         rd_phase  = 1'b0;
  logic [A-1:0] rd_cnt    = '0;

  always_ff @(posedge clk) begin
    if (rst) begin
      rd_active <= 1'b0;
      rd_cnt    <= '0;
    end else if (wr_valid_d && (&wr_cnt_d)) begin
      rd_active <= 1'b1;
      rd_phase  <= wr_phase_d;
      rd_cnt    <= '0;
    end else if (rd_active) begin
      if (&rd_cnt) rd_active <= 1'b0;
      rd_cnt <= rd_cnt + 1'b1;
    end
  end

  logic [ELEMENT_WIDTH-1:0] mem_out [0:S-1];
  logic [D-1:0] wr_row_d, rd_col;
  assign wr_row_d = wr_cnt_d[A-1:LO];
  assign rd_col   = rd_cnt[A-1:LO];

  for (genvar i = 0; i < S; i++) begin : gen_bank
    logic [A-1:0] wa, ra;
    if (LO > 0) begin : g_lo
      assign wa = wr_phase_d ? {D'(i) - wr_row_d, wr_cnt_d[LO-1:0]} : wr_cnt_d;
      assign ra = rd_phase   ? rd_cnt : {D'(i) - rd_col, rd_cnt[LO-1:0]};
    end else begin : g_nolo
      assign wa = wr_phase_d ? (D'(i) - wr_row_d) : wr_cnt_d;
      assign ra = rd_phase   ? rd_cnt : (D'(i) - rd_col);
    end
    if (RAM_STYLE == "distributed" || (RAM_STYLE == "auto" && WIN <= 64)) begin : g_lr
      (* ram_style = "distributed" *) logic [ELEMENT_WIDTH-1:0] mem [0:WIN-1];
      always_ff @(posedge clk) begin
        mem_out[i] <= mem[ra];
        if (wr_valid_d) mem[wa] <= bs0_out[i];
      end
    end else if (RAM_STYLE == "ultra") begin : g_ur
      (* ram_style = "ultra" *) logic [ELEMENT_WIDTH-1:0] mem [0:WIN-1];
      always_ff @(posedge clk) begin
        mem_out[i] <= mem[ra];
        if (wr_valid_d) mem[wa] <= bs0_out[i];
      end
    end else begin : g_br
      (* ram_style = "block" *) logic [ELEMENT_WIDTH-1:0] mem [0:WIN-1];
      always_ff @(posedge clk) begin
        mem_out[i] <= mem[ra];
        if (wr_valid_d) mem[wa] <= bs0_out[i];
      end
    end
  end

  logic         rd_active_d;
  logic [D-1:0] rd_col_d;
  delay_line #(.WIDTH(D + 1), .DEPTH(1)) u_rd_sb (
    .clk(clk), .d({rd_active, rd_col}), .q({rd_active_d, rd_col_d}));

  barrel_shift #(.STREAM_SIZE(S), .ELEMENT_WIDTH(ELEMENT_WIDTH), .REG_FLAGS(REG_FLAGS)) u_bs1 (
    .clk(clk), .data_in(mem_out), .shift(D'(0) - rd_col_d), .data_out(data_out));

  delay_line #(.WIDTH(1), .DEPTH(BARREL_LATENCY)) u_out_valid (
    .clk(clk), .d(rd_active_d), .q(data_out_valid));

endmodule
