// -----------------------------------------------------------------------------
// Module      : delay_line
// Description : A WIDTH-bit value delayed by DEPTH clock cycles. DEPTH = 0 is a
//               wire, so a sideband can follow a datapath whose register count
//               is a parameter (the barrel shifter's REG_FLAGS) down to none.
//
// Parameters  : WIDTH   Bits per value
//               DEPTH   Clock cycles of delay (0 = combinational pass-through)
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps

module delay_line #(
  parameter int WIDTH = 1,
  parameter int DEPTH = 1
) (
  input  logic             clk,
  input  logic [WIDTH-1:0] d,
  output logic [WIDTH-1:0] q
);

  if (DEPTH == 0) begin : gen_wire
    assign q = d;
  end else begin : gen_regs
    logic [WIDTH-1:0] pipe [0:DEPTH-1] = '{default: '0};

    always_ff @(posedge clk) begin
      pipe[0] <= d;
      for (int i = 1; i < DEPTH; i++) begin
        pipe[i] <= pipe[i-1];
      end
    end

    assign q = pipe[DEPTH-1];
  end

endmodule
