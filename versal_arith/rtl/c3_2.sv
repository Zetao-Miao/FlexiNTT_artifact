`timescale 1ns / 1ps


module c3_2 #(
    parameter OUTREG = "FALSE",
    parameter LEAVEC = "FALSE",
    parameter POSODD = "FALSE",
    parameter FIRSTS = "FALSE",
    parameter LASTS  = "FALSE",
    parameter logic [2:0] C0_INV = '0
)(
    input  logic         clk,
    input  logic [2 : 0] C0,
    output logic [1 : 0] O,
    output logic         CY,
    output logic         PROP
    );

    // Rewrite a LUT's truth table so each input in `mask` reads inverted: the
    // generator inverts an input here rather than leaving an inverter for the tools.
    // Never mask an input on a LUT6CY's I4: PROP reads INIT[15:0] whatever I4 is.
    function automatic logic [63:0] flip_init(input logic [63:0] init, input logic [5:0] mask);
        for (int i = 0; i < 64; i++)
            flip_init[i] = init[6'(i) ^ mask];
    endfunction



    parameter INIT = POSODD == "TRUE" ? (FIRSTS == "TRUE" ? 64'hFFF0F000F00F0FF0 : (LASTS == "TRUE" ? 64'hFFF0F000F00F0FF0 : 64'hF000F000F00F0FF0)) : 64'hFFF0F000F00F0FF0;

    logic [1 : 0] O_wire;
    logic [1 : 0] O_reg;


    generate
        if (POSODD == "FALSE") begin
            LUT6CY #(.INIT(flip_init(INIT, {1'b0, C0_INV[2], C0_INV[1], C0_INV[0], 1'b0, 1'b0})))
            LUT6CY_inst0 (
                .O51 (O_wire[0]),
                .O52 (O_wire[1]),
                .PROP(PROP     ),
                .I0  (1'b0     ),
                .I1  (1'b0     ),
                .I2  (C0[0]    ),
                .I3  (C0[1]    ),
                .I4  (C0[2]    ));
        end else begin
            LUT6CY #(.INIT(flip_init(INIT, {1'b0, C0_INV[2], C0_INV[1], C0_INV[0], 1'b0, 1'b0})))
            LUT6CY_inst0 (
                .O51 (O_wire[0]),
                .O52 (O_wire[1]),
                .PROP(PROP     ),
                .I0  (1'b0     ),
                .I1  (1'b0     ),
                .I2  (C0[0]    ),
                .I3  (C0[1]    ),
                .I4  (C0[2]    ));
        end
    endgenerate

    generate
        if (OUTREG == "FALSE") begin
            assign O = O_wire;
        end else begin
            if (LEAVEC == "FALSE") begin
                assign O = O_reg;
                always_ff @(posedge clk)
                    O_reg <= O_wire;                
            end else begin
                always_ff @(posedge clk)
                    O_reg[0] <= O_wire[0];
                assign O[0] = O_reg[0];
                assign O[1] = O_wire[1];
            end
        end
    endgenerate

    assign CY = O_wire[1];
endmodule

