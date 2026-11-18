// -----------------------------------------------------------------------------
// Module      : bmb_matrix_transpose
// Description : Transpose of a STREAM_SIZE x STREAM_SIZE matrix, built from a
//               barrel shifter, one bank of BRAMs and a second barrel shifter.
//
//               The matrix arrives one row (STREAM_SIZE elements) per cycle
//               while data_valid is high and leaves one column per cycle with
//               data_out_valid high.
//
//               Row r is rotated by r and lane b stores it at address r
//               (even matrices) or b - r (odd matrices), so the whole matrix
//               is in the bank when its last row lands. It is then drained
//               over the next STREAM_SIZE cycles: at drain step c every lane
//               reads b - c (even) or c (odd), which is column c on the
//               diagonal, and the second shifter rotates it back by -c.
//
//               Bursts. A burst is any positive number of whole matrices with
//               data_valid held high; bursts may follow each other with any
//               gap, zero included. The write side counts rows within the
//               burst and alternates the storage phase per matrix; the drain
//               of a matrix is started by its own last row and carries that
//               matrix's phase, so the next matrix's rows (the other phase)
//               only ever overwrite cells the drain has already read -- in
//               the back-to-back case in the very cycle it reads them, which
//               the BRAM's read-first mode returns correctly.
//
//               Latency  : STREAM_SIZE + 2 * BARREL_LATENCY + 1 cycles from a
//                          row on data_in to the same-numbered column on
//                          data_out, with BARREL_LATENCY the registers in
//                          each shifter ($countones of REG_FLAGS)
//               Protocol : data_valid high for a multiple of STREAM_SIZE
//                          consecutive cycles per burst
//
// Parameters  : STREAM_SIZE    Matrix dimension (power of two)
//               ELEMENT_WIDTH  Bit width of a single element
//               REG_FLAGS      Register placement of both barrel shifters
//                              (see barrel_shift)
//
// Twin        : versal_arith/transpose_model.py, BmbTranspose
//
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps

module bmb_matrix_transpose #(
  parameter int          STREAM_SIZE   = 128,
  parameter int          ELEMENT_WIDTH = 66,
  parameter logic [31:0] REG_FLAGS     = 32'hFFFF_FFFF
) (
  input  logic                     clk,
  input  logic                     data_valid,
  input  logic [ELEMENT_WIDTH-1:0] data_in  [0:STREAM_SIZE-1],

  output logic                     data_out_valid,
  output logic [ELEMENT_WIDTH-1:0] data_out [0:STREAM_SIZE-1]
);

  localparam int N              = STREAM_SIZE;
  localparam int D              = $clog2(STREAM_SIZE);
  localparam int STAGES         = (D + 1) / 2;                      // mirrors barrel_shift
  localparam int BARREL_LATENCY = $countones(REG_FLAGS[STAGES-1:0]); // mirrors barrel_shift

  //---------------------------------------------------------------------------
  // Write side: the row index within the burst and the storage phase of the
  // matrix being received. The phase alternates per matrix and is never
  // reset; either phase order transposes correctly.
  //---------------------------------------------------------------------------
  logic [D-1:0] wr_row   = '0;
  logic         wr_phase = 1'b0;

  always_ff @(posedge clk) begin
    if (data_valid) begin
      wr_row <= wr_row + 1'b1;
      if (&wr_row) begin
        wr_phase <= ~wr_phase;
      end
    end else begin
      wr_row <= '0;
    end
  end

  //---------------------------------------------------------------------------
  // First barrel shifter: row r rotated by r. Its sideband (valid, phase, row)
  // is delayed by the shifter's latency so it arrives with the data.
  //---------------------------------------------------------------------------
  logic [ELEMENT_WIDTH-1:0] barrel_shift_0_out [0:STREAM_SIZE-1];
  logic                     wr_valid_d;
  logic                     wr_phase_d;
  logic [D-1:0]             wr_row_d;

  barrel_shift #(
    .STREAM_SIZE   (STREAM_SIZE),
    .ELEMENT_WIDTH (ELEMENT_WIDTH),
    .REG_FLAGS     (REG_FLAGS)
  ) u_barrel_shift_0 (
    .clk      (clk),
    .data_in  (data_in),
    .shift    (wr_row),

    .data_out (barrel_shift_0_out)
  );

  delay_line #(
    .WIDTH (D + 2),
    .DEPTH (BARREL_LATENCY)
  ) u_wr_sideband (
    .clk (clk),
    .d   ({data_valid, wr_phase, wr_row}),
    .q   ({wr_valid_d, wr_phase_d, wr_row_d})
  );

  //---------------------------------------------------------------------------
  // Drain: started by the last row of a matrix landing in the bank, it reads
  // the N columns of that matrix on its own phase.
  //---------------------------------------------------------------------------
  logic         rd_active = 1'b0;
  logic         rd_phase  = 1'b0;
  logic [D-1:0] rd_col    = '0;
  logic         last_row_written;

  assign last_row_written = wr_valid_d && (&wr_row_d);

  always_ff @(posedge clk) begin
    if (last_row_written) begin
      rd_active <= 1'b1;
      rd_phase  <= wr_phase_d;
      rd_col    <= '0;
    end else if (rd_active) begin
      if (&rd_col) begin
        rd_active <= 1'b0;
      end
      rd_col <= rd_col + 1'b1;
    end
  end

  //---------------------------------------------------------------------------
  // BRAM bank
  //---------------------------------------------------------------------------
  logic [ELEMENT_WIDTH-1:0] bram_layer_out [0:STREAM_SIZE-1];

  for (genvar i = 0; i < STREAM_SIZE; i++) begin : gen_bram
    logic [D-1:0] wr_addr;
    logic [D-1:0] rd_addr;

    assign wr_addr = wr_phase_d ? (D'(i) - wr_row_d) : wr_row_d;
    assign rd_addr = rd_phase   ? rd_col              : (D'(i) - rd_col);

    BRAM #(
      .DEPTH         (STREAM_SIZE),
      .ELEMENT_WIDTH (ELEMENT_WIDTH)
    ) u_bram (
      .clk      (clk),
      .wr_en    (wr_valid_d),
      .wr_addr  (wr_addr),
      .rd_addr  (rd_addr),
      .data_in  (barrel_shift_0_out[i]),

      .data_out (bram_layer_out[i])
    );
  end

  //---------------------------------------------------------------------------
  // Second barrel shifter: column c rotated back by -c. The read sideband
  // follows the BRAM's one-cycle read, then the shifter's latency.
  //---------------------------------------------------------------------------
  logic         rd_active_d;
  logic [D-1:0] rd_col_d;

  delay_line #(
    .WIDTH (D + 1),
    .DEPTH (1)
  ) u_rd_sideband (
    .clk (clk),
    .d   ({rd_active, rd_col}),
    .q   ({rd_active_d, rd_col_d})
  );

  barrel_shift #(
    .STREAM_SIZE   (STREAM_SIZE),
    .ELEMENT_WIDTH (ELEMENT_WIDTH),
    .REG_FLAGS     (REG_FLAGS)
  ) u_barrel_shift_1 (
    .clk      (clk),
    .data_in  (bram_layer_out),
    .shift    (D'(0) - rd_col_d),

    .data_out (data_out)
  );

  delay_line #(
    .WIDTH (1),
    .DEPTH (BARREL_LATENCY)
  ) u_out_valid (
    .clk (clk),
    .d   (rd_active_d),
    .q   (data_out_valid)
  );

endmodule
