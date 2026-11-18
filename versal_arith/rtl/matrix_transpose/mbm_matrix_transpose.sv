// -----------------------------------------------------------------------------
// Module      : mbm_matrix_transpose
// Description : Transpose of a STREAM_SIZE x STREAM_SIZE matrix, built from
//               two banks of BRAMs separated by a single barrel shifter.
//
//               The matrix arrives one row (STREAM_SIZE elements) per cycle
//               while data_valid is high and leaves one column per cycle with
//               data_out_valid high.
//
//               Lane i of the input bank delays its element by i+1 cycles, so
//               the bank emits anti-diagonals; the shifter rotates each by
//               minus its frame index and lane j of the output bank delays by
//               N-j, undoing the skew. All three stages are addressed from
//               one free-running frame counter `tau` that never resets, so
//               the datapath transposes every N-cycle window of the frame.
//
//               Bursts. A burst is any positive number of whole matrices with
//               data_valid held high; bursts may follow each other with any
//               gap. Because the lanes skew, a burst that starts off the
//               frame cannot be read in its own timing, so every matrix is
//               re-aligned to the frame instead: it is written into the input
//               bank as it arrives (the bank holds two matrices, in alternate
//               halves) and read out in the first N-cycle window that starts
//               at or after its first row. The window's (valid, half) pair is
//               handed to lane i i+1 cycles after the window opens, when that
//               lane's reads of the window begin.
//
//               Latency  : STREAM_SIZE + BARREL_LATENCY + 3 cycles from a row
//                          on data_in to the same-numbered column on data_out
//                          for a burst starting on the frame (tau == 0), plus
//                          the wait for the frame otherwise (0..STREAM_SIZE-1
//                          cycles); BARREL_LATENCY is the registers in the
//                          shifter ($countones of REG_FLAGS)
//               Protocol : data_valid high for a multiple of STREAM_SIZE
//                          consecutive cycles per burst
//
// Parameters  : STREAM_SIZE    Matrix dimension (power of two)
//               ELEMENT_WIDTH  Bit width of a single element
//               REG_FLAGS      Register placement of the barrel shifter
//                              (see barrel_shift)
//
// Twin        : versal_arith/transpose_model.py, MbmTranspose
//
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps

module mbm_matrix_transpose #(
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
  localparam int TAU_TAPS       = BARREL_LATENCY + 2;

  //---------------------------------------------------------------------------
  // The frame counter and its delayed copies: tau_dly[k] is tau delayed by
  // k+1 cycles.
  //---------------------------------------------------------------------------
  logic [D-1:0] tau                   = '0;
  logic [D-1:0] tau_dly [0:TAU_TAPS-1] = '{default: '0};

  always_ff @(posedge clk) begin
    tau        <= tau + 1'b1;
    tau_dly[0] <= tau;
    for (int k = 1; k < TAU_TAPS; k++) begin
      tau_dly[k] <= tau_dly[k-1];
    end
  end

  //---------------------------------------------------------------------------
  // Write side: the row index within the burst and the half of the input
  // bank the matrix being received goes to. The half alternates per matrix
  // and is never reset.
  //---------------------------------------------------------------------------
  logic [D-1:0] wr_row  = '0;
  logic         wr_half = 1'b0;
  logic         first_row;

  assign first_row = data_valid && (wr_row == '0);

  always_ff @(posedge clk) begin
    if (data_valid) begin
      wr_row <= wr_row + 1'b1;
      if (&wr_row) begin
        wr_half <= ~wr_half;
      end
    end else begin
      wr_row <= '0;
    end
  end

  //---------------------------------------------------------------------------
  // Windows. A matrix whose first row arrives while tau != 0 is pending until
  // the next tau == 0; at every tau == 0 the window that opens takes the
  // pending matrix (or one whose first row arrives that very cycle), and its
  // (valid, half) pair is registered as cur_win, visible from the following
  // cycle. Lane i reads the window i+1 cycles after it opens, so lane i takes
  // cur_win delayed by i.
  //---------------------------------------------------------------------------
  logic       pending      = 1'b0;
  logic       pending_half = 1'b0;
  logic [1:0] cur_win      = '0;      // {valid, half}
  logic [1:0] win_dly [1:STREAM_SIZE-1] = '{default: '0};

  always_ff @(posedge clk) begin
    if (tau == '0) begin
      cur_win <= {pending | first_row, pending ? pending_half : wr_half};
      pending <= 1'b0;
    end else if (first_row) begin
      pending      <= 1'b1;
      pending_half <= wr_half;
    end
    win_dly[1] <= cur_win;
    for (int i = 2; i < N; i++) begin
      win_dly[i] <= win_dly[i-1];
    end
  end

  //---------------------------------------------------------------------------
  // Input BRAM bank: two matrices deep, written as the rows arrive, read on
  // the skew in the frame of the window.
  //---------------------------------------------------------------------------
  logic [ELEMENT_WIDTH-1:0] bram_layer_out [0:STREAM_SIZE-1];

  for (genvar i = 0; i < STREAM_SIZE; i++) begin : gen_input_bram
    logic [1:0] lane_win;
    logic [D:0] wr_addr;
    logic [D:0] rd_addr;

    if (i == 0) begin : gen_lane0
      assign lane_win = cur_win;
    end else begin : gen_lane
      assign lane_win = win_dly[i];
    end

    assign wr_addr = {wr_half, wr_row};
    assign rd_addr = {lane_win[0], tau_dly[0] - D'(i)};

    BRAM #(
      .DEPTH         (2 * STREAM_SIZE),
      .ELEMENT_WIDTH (ELEMENT_WIDTH)
    ) u_bram (
      .clk      (clk),
      .wr_en    (data_valid),
      .wr_addr  (wr_addr),
      .rd_addr  (rd_addr),
      .data_in  (data_in[i]),

      .data_out (bram_layer_out[i])
    );
  end

  //---------------------------------------------------------------------------
  // Barrel shifter: each anti-diagonal rotated by minus its frame index.
  //---------------------------------------------------------------------------
  logic [ELEMENT_WIDTH-1:0] barrel_shift_out [0:STREAM_SIZE-1];

  barrel_shift #(
    .STREAM_SIZE   (STREAM_SIZE),
    .ELEMENT_WIDTH (ELEMENT_WIDTH),
    .REG_FLAGS     (REG_FLAGS)
  ) u_barrel_shift (
    .clk      (clk),
    .data_in  (bram_layer_out),
    .shift    (D'(0) - tau_dly[1]),

    .data_out (barrel_shift_out)
  );

  //---------------------------------------------------------------------------
  // Output BRAM bank: lane j delays by N-j, undoing the skew. Written every
  // cycle; the window's valid, delayed through the pipeline, says which
  // output rows carry a matrix.
  //---------------------------------------------------------------------------
  for (genvar j = 0; j < STREAM_SIZE; j++) begin : gen_output_bram
    logic [D-1:0] rd_addr;

    assign rd_addr = tau_dly[TAU_TAPS-1] + D'(j);

    BRAM #(
      .DEPTH         (STREAM_SIZE),
      .ELEMENT_WIDTH (ELEMENT_WIDTH)
    ) u_bram (
      .clk      (clk),
      .wr_en    (1'b1),
      .wr_addr  (tau_dly[TAU_TAPS-1]),
      .rd_addr  (rd_addr),
      .data_in  (barrel_shift_out[(STREAM_SIZE - j) % STREAM_SIZE]),

      .data_out (data_out[j])
    );
  end

  delay_line #(
    .WIDTH (1),
    .DEPTH (STREAM_SIZE + BARREL_LATENCY + 2)
  ) u_out_valid (
    .clk (clk),
    .d   (cur_win[1]),
    .q   (data_out_valid)
  );

endmodule
