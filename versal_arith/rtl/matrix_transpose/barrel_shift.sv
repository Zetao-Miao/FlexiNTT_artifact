// -----------------------------------------------------------------------------
// Module      : barrel_shift
// Description : Cyclic rotation of a stream of STREAM_SIZE elements:
//
//                   data_out[b] = data_in[(b - shift) mod STREAM_SIZE]
//
//               Radix-4: ceil(log2(STREAM_SIZE) / 2) mux stages. Stage s takes
//               the next two bits of `shift`, most significant pair first, and
//               rotates by 0, 1, 2 or 3 times STREAM_SIZE >> (2s+2); when the
//               depth is odd the last stage rotates by 0 or 1 on the least
//               significant bit. Every element bit of a 4:1 stage is one
//               LUT6_2 (the four rotated sources on I0..I3, the select pair on
//               I4/I5); the 2:1 stage packs two element bits into one LUT6_2
//               (O5/O6, the select shared on I4, I5 tied high), a leftover odd
//               bit taking a LUT3. One INIT serves both LUT6_2 uses.
//
//               A register follows mux stage s when REG_FLAGS[s] is set; the
//               remaining select bits are registered beside the data so a
//               stage's select is always at the depth of its data. There is no
//               input register: the inputs are the producer's flops, as for
//               every LUT block in this project. REG_FLAGS = 0 is a purely
//               combinational rotate.
//
//               Latency     : $countones(REG_FLAGS[STAGES-1:0]) clock cycles
//               Throughput  : one full stream per cycle
//               LUTs        : STREAM_SIZE * ELEMENT_WIDTH per 4:1 stage,
//                             STREAM_SIZE * ceil(ELEMENT_WIDTH / 2) for the
//                             2:1 stage
//
// Parameters  : STREAM_SIZE    Number of elements in the stream (power of two)
//               ELEMENT_WIDTH  Bit width of a single element
//               REG_FLAGS      Bit s: a register after mux stage s
//                              (default: after every stage)
//
// Twin        : versal_arith/transpose_model.py, BarrelShifter
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps

module barrel_shift #(
  parameter int          STREAM_SIZE   = 128,
  parameter int          ELEMENT_WIDTH = 32,
  parameter logic [31:0] REG_FLAGS     = 32'hFFFF_FFFF
) (
  input  logic                           clk,
  input  logic [ELEMENT_WIDTH-1:0]       data_in  [0:STREAM_SIZE-1],
  input  logic [$clog2(STREAM_SIZE)-1:0] shift,

  output logic [ELEMENT_WIDTH-1:0]       data_out [0:STREAM_SIZE-1]
);

  localparam int N       = STREAM_SIZE;
  localparam int W       = ELEMENT_WIDTH;
  localparam int D       = $clog2(STREAM_SIZE);
  localparam int STAGES  = (D + 1) / 2;
  localparam int LATENCY = $countones(REG_FLAGS[STAGES-1:0]);

  // O6 = I[{I5,I4}] over I0..I3: a 4:1 mux with the select pair on I4 (low)
  // and I5 (high). With I5 tied high the same table gives O6 = I4 ? I3 : I2
  // and O5 = I4 ? I1 : I0: two 2:1 muxes sharing a select.
  localparam logic [63:0] MUX_INIT = 64'hFF00F0F0CCCCAAAA;

  initial begin
    if (N < 2 || (N & (N - 1)) != 0) begin
      $fatal(1, "barrel_shift: STREAM_SIZE must be a power of two >= 2, got %0d", N);
    end
  end

  //---------------------------------------------------------------------------
  // stage_in[s] enters mux stage s; stage_in[STAGES] leaves the module.
  // shift_in[s] holds the remaining select bits at the depth of stage s,
  // the current pair at its top.
  //---------------------------------------------------------------------------
  logic [W-1:0] stage_in [0:STAGES][0:N-1];
  logic [W-1:0] mux_out  [0:STAGES-1][0:N-1];
  logic [D-1:0] shift_in [0:STAGES];

  assign stage_in[0] = data_in;
  assign shift_in[0] = shift;

  for (genvar s = 0; s < STAGES; s++) begin : gen_stage
    localparam bit FULL = (2*s + 1 < D);              // two select bits remain
    localparam int UNIT = FULL ? (N >> (2*s + 2)) : 1; // rotation per select step

    for (genvar b = 0; b < N; b++) begin : gen_elem
      if (FULL) begin : gen_mux4
        for (genvar k = 0; k < W; k++) begin : gen_bit
          LUT6_2 #(.INIT(MUX_INIT)) u_mux (
            .O6(mux_out[s][b][k]),
            .O5(),
            .I0(stage_in[s][b][k]),
            .I1(stage_in[s][(b + N -   UNIT) % N][k]),
            .I2(stage_in[s][(b + N - 2*UNIT) % N][k]),
            .I3(stage_in[s][(b + N - 3*UNIT) % N][k]),
            .I4(shift_in[s][D-2]),
            .I5(shift_in[s][D-1])
          );
        end
      end else begin : gen_mux2
        for (genvar k = 0; k + 1 < W; k = k + 2) begin : gen_pair
          LUT6_2 #(.INIT(MUX_INIT)) u_mux (
            .O6(mux_out[s][b][k+1]),
            .O5(mux_out[s][b][k]),
            .I0(stage_in[s][b][k]),
            .I1(stage_in[s][(b + N - 1) % N][k]),
            .I2(stage_in[s][b][k+1]),
            .I3(stage_in[s][(b + N - 1) % N][k+1]),
            .I4(shift_in[s][D-1]),
            .I5(1'b1)
          );
        end
        if (W % 2 == 1) begin : gen_odd
          LUT3 #(.INIT(8'hCA)) u_mux (
            .O (mux_out[s][b][W-1]),
            .I0(stage_in[s][b][W-1]),
            .I1(stage_in[s][(b + N - 1) % N][W-1]),
            .I2(shift_in[s][D-1])
          );
        end
      end
    end

    if (REG_FLAGS[s]) begin : gen_reg
      logic [W-1:0] data_q  [0:N-1] = '{default: '0};
      logic [D-1:0] shift_q         = '0;

      always_ff @(posedge clk) begin
        data_q  <= mux_out[s];
        shift_q <= shift_in[s] << 2;
      end

      assign stage_in[s+1] = data_q;
      assign shift_in[s+1] = shift_q;
    end else begin : gen_wire
      assign stage_in[s+1] = mux_out[s];
      assign shift_in[s+1] = shift_in[s] << 2;
    end
  end

  assign data_out = stage_in[STAGES];

endmodule
