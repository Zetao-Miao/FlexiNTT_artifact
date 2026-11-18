// -----------------------------------------------------------------------------
// Module      : BRAM
// Description : One simple-dual-port block memory, DEPTH words of ELEMENT_WIDTH
//               bits, written on port A and read on port B with a one-cycle
//               read latency, on a common clock.
//
//               Collision semantics matter here. Every transpose that
//               instantiates this memory reads and writes the same address in
//               the same cycle at some point (bmb: the drain of one matrix
//               overlaps the next matrix's rows back-to-back; mbm: the lanes
//               that skew furthest), and relies on WRITE_MODE_B = "read_first":
//               the read returns the word stored before the write. Do not
//               change the write mode or the primitive family without
//               re-checking those paths.
//
// Parameters  : DEPTH          Words (a power of two)
//               ELEMENT_WIDTH  Bits per word
//
// Twin        : versal_arith/transpose_model.py, Memory
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps

module BRAM #(
  parameter int DEPTH         = 128,
  parameter int ELEMENT_WIDTH = 32
) (
  input  logic                     clk,
  input  logic                     wr_en,
  input  logic [$clog2(DEPTH)-1:0] wr_addr,
  input  logic [$clog2(DEPTH)-1:0] rd_addr,
  input  logic [ELEMENT_WIDTH-1:0] data_in,

  output logic [ELEMENT_WIDTH-1:0] data_out
);

  localparam int ADDR_WIDTH = $clog2(DEPTH);

  xpm_memory_sdpram #(
    // Geometry
    .MEMORY_SIZE             (DEPTH * ELEMENT_WIDTH),
    .ADDR_WIDTH_A            (ADDR_WIDTH),
    .ADDR_WIDTH_B            (ADDR_WIDTH),
    .WRITE_DATA_WIDTH_A      (ELEMENT_WIDTH),
    .READ_DATA_WIDTH_B       (ELEMENT_WIDTH),
    .BYTE_WRITE_WIDTH_A      (ELEMENT_WIDTH),

    // Implementation
    .MEMORY_PRIMITIVE        ("block"),
    .MEMORY_OPTIMIZATION     ("true"),
    .CASCADE_HEIGHT          (0),
    .CLOCKING_MODE           ("common_clock"),
    .WRITE_MODE_B            ("read_first"),
    .READ_LATENCY_B          (1),

    // Initialisation
    .MEMORY_INIT_FILE        ("none"),
    .MEMORY_INIT_PARAM       ("0"),
    .USE_MEM_INIT            (0),
    .READ_RESET_VALUE_B      ("0"),
    .RST_MODE_A              ("SYNC"),
    .RST_MODE_B              ("SYNC"),

    // Unused features
    .ECC_MODE                ("no_ecc"),
    .WAKEUP_TIME             ("disable_sleep"),
    .AUTO_SLEEP_TIME         (0),
    .USE_EMBEDDED_CONSTRAINT (0),
    .MESSAGE_CONTROL         (0),
    .SIM_ASSERT_CHK          (0)
  ) u_xpm_memory_sdpram (
    // Clocks
    .clka           (clk),
    .clkb           (clk),

    // Write port (A)
    .ena            (1'b1),
    .wea            (wr_en),
    .addra          (wr_addr),
    .dina           (data_in),

    // Read port (B)
    .enb            (1'b1),
    .regceb         (1'b1),
    .rstb           (1'b0),
    .addrb          (rd_addr),
    .doutb          (data_out),

    // Power management (unused)
    .sleep          (1'b0),

    // ECC (unused)
    .injectdbiterra (1'b0),
    .injectsbiterra (1'b0),
    .dbiterrb       (),
    .sbiterrb       ()
  );

endmodule
