`timescale 1ns / 1ps


module c6_3 #(
    parameter OUTREG = "FALSE",
    parameter LEAVEC = "FALSE",
    parameter logic [5:0] C0_INV = '0
)(
    input  logic         clk,
    input  logic [5 : 0] C0,
    output logic [2 : 0] O
    );

    // Rewrite a LUT's truth table so each input in `mask` reads inverted: the
    // generator inverts an input here rather than leaving an inverter for the tools.
    // Never mask an input on a LUT6CY's I4: PROP reads INIT[15:0] whatever I4 is.
    function automatic logic [63:0] flip_init(input logic [63:0] init, input logic [5:0] mask);
        for (int i = 0; i < 64; i++)
            flip_init[i] = init[6'(i) ^ mask];
    endfunction



    logic [2 : 0] O_wire;
    logic [2 : 0] O_reg;


    LUT6_2 #(.INIT(flip_init(64'h6996966996696996, {C0_INV[5], C0_INV[4], C0_INV[3], C0_INV[2], C0_INV[1], C0_INV[0]})))
    LUT6_2_inst0 (
        .O6(O_wire[0]),
        .O5(         ),
        .I0(C0[0]    ),
        .I1(C0[1]    ),
        .I2(C0[2]    ),
        .I3(C0[3]    ),
        .I4(C0[4]    ),
        .I5(C0[5]    ));

    LUT6_2 #(.INIT(flip_init(64'h8117177E177E7EE8, {C0_INV[5], C0_INV[4], C0_INV[3], C0_INV[2], C0_INV[1], C0_INV[0]})))
    LUT6_2_inst1 (
        .O6(O_wire[1]),
        .O5(         ),
        .I0(C0[0]    ),
        .I1(C0[1]    ),
        .I2(C0[2]    ),
        .I3(C0[3]    ),
        .I4(C0[4]    ),
        .I5(C0[5]    ));

    LUT6_2 #(.INIT(flip_init(64'hFEE8E880E8808000, {C0_INV[5], C0_INV[4], C0_INV[3], C0_INV[2], C0_INV[1], C0_INV[0]})))
    LUT6_2_inst2 (
        .O6(O_wire[2]),
        .O5(         ),
        .I0(C0[0]    ),
        .I1(C0[1]    ),
        .I2(C0[2]    ),
        .I3(C0[3]    ),
        .I4(C0[4]    ),
        .I5(C0[5]    ));

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
                    O_reg[1:0] <= O_wire[1:0];
                assign O[1:0] = O_reg[1:0];
                assign O[2]   = O_wire[2];
            end
        end
    endgenerate
endmodule

