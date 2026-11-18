`timescale 1ns / 1ps

module LDd_rom1_s7_bu_dp_w0mq_Bmult7x7_pp_bitheap_gen (
    input  logic          clk,
    input  logic [6  : 0] OPA,
    input  logic [7  : 0] OPB,
    output logic [1  : 0] col0,
    output logic          col1,
    output logic [2  : 0] col2,
    output logic [1  : 0] col3,
    output logic [3  : 0] col4,
    output logic [2  : 0] col5,
    output logic [4  : 0] col6,
    output logic [3  : 0] col7,
    output logic [2  : 0] col8,
    output logic [2  : 0] col9,
    output logic [1  : 0] col10,
    output logic [1  : 0] col11,
    output logic          col12,
    output logic          col13
    );
    
    
    logic [1  : 0] col0_wire;
    logic          col1_wire;
    logic [2  : 0] col2_wire;
    logic [1  : 0] col3_wire;
    logic [3  : 0] col4_wire;
    logic [2  : 0] col5_wire;
    logic [4  : 0] col6_wire;
    logic [3  : 0] col7_wire;
    logic [2  : 0] col8_wire;
    logic [2  : 0] col9_wire;
    logic [1  : 0] col10_wire;
    logic [1  : 0] col11_wire;
    logic          col12_wire;
    logic          col13_wire;
    
    // the main part of row 0
    LUT6_2 #(.INIT(64'h226688CC268C268C))
    LUT6_2_row0_inst0 (
        .O6(col1_wire),
        .O5(col0_wire[0]),
        .I0(OPB[0]),
        .I1(OPB[1]),
        .I2(1'b0),
        .I3(OPA[0]),
        .I4(OPA[1]),
        .I5(1'b1));
    
    LUT6_2 #(.INIT(64'h226688CC268C268C))
    LUT6_2_row0_inst2 (
        .O6(col3_wire[0]),
        .O5(col2_wire[0]),
        .I0(OPB[0]),
        .I1(OPB[1]),
        .I2(OPA[1]),
        .I3(OPA[2]),
        .I4(OPA[3]),
        .I5(1'b1));
    
    LUT6_2 #(.INIT(64'h226688CC268C268C))
    LUT6_2_row0_inst4 (
        .O6(col5_wire[0]),
        .O5(col4_wire[0]),
        .I0(OPB[0]),
        .I1(OPB[1]),
        .I2(OPA[3]),
        .I3(OPA[4]),
        .I4(OPA[5]),
        .I5(1'b1));
    
    LUT6_2 #(.INIT(64'hDD33DD33268C268C))
    LUT6_2_row0_inst6 (
        .O6(col7_wire[0]),
        .O5(col6_wire[0]),
        .I0(OPB[0]),
        .I1(OPB[1]),
        .I2(OPA[5]),
        .I3(OPA[6]),
        .I4(1'b1),
        .I5(1'b1));
    
    
    // the main part of row 1
    LUT6_2 #(.INIT(64'h8E96E8F096F096F0))
    LUT6_2_row1_inst0 (
        .O6(col3_wire[1]),
        .O5(col2_wire[1]),
        .I0(OPB[1]),
        .I1(OPB[2]),
        .I2(OPB[3]),
        .I3(OPA[0]),
        .I4(OPA[1]),
        .I5(1'b1));
    
    LUT5 #(.INIT(32'h8EE896F0))
    LUT5_row1_inst2 (
        .O (col4_wire[1]),
        .I0(OPB[1]),
        .I1(OPB[2]),
        .I2(OPB[3]),
        .I3(OPA[2]),
        .I4(OPA[1]));
    
    LUT5 #(.INIT(32'h8E96E8F0))
    LUT5_row1_inst3 (
        .O (col5_wire[1]),
        .I0(OPB[1]),
        .I1(OPB[2]),
        .I2(OPB[3]),
        .I3(OPA[2]),
        .I4(OPA[3]));
    
    LUT5 #(.INIT(32'h8EE896F0))
    LUT5_row1_inst4 (
        .O (col6_wire[1]),
        .I0(OPB[1]),
        .I1(OPB[2]),
        .I2(OPB[3]),
        .I3(OPA[4]),
        .I4(OPA[3]));
    
    LUT5 #(.INIT(32'h8E96E8F0))
    LUT5_row1_inst5 (
        .O (col7_wire[1]),
        .I0(OPB[1]),
        .I1(OPB[2]),
        .I2(OPB[3]),
        .I3(OPA[4]),
        .I4(OPA[5]));
    
    LUT6_2 #(.INIT(64'h710F710F8EE896F0))
    LUT6_2_row1_inst6 (
        .O6(col9_wire[0]),
        .O5(col8_wire[0]),
        .I0(OPB[1]),
        .I1(OPB[2]),
        .I2(OPB[3]),
        .I3(OPA[6]),
        .I4(OPA[5]),
        .I5(1'b1));
    
    
    // the main part of row 2
    LUT6_2 #(.INIT(64'h8E96E8F096F096F0))
    LUT6_2_row2_inst0 (
        .O6(col5_wire[2]),
        .O5(col4_wire[2]),
        .I0(OPB[3]),
        .I1(OPB[4]),
        .I2(OPB[5]),
        .I3(OPA[0]),
        .I4(OPA[1]),
        .I5(1'b1));
    
    LUT5 #(.INIT(32'h8EE896F0))
    LUT5_row2_inst2 (
        .O (col6_wire[2]),
        .I0(OPB[3]),
        .I1(OPB[4]),
        .I2(OPB[5]),
        .I3(OPA[2]),
        .I4(OPA[1]));
    
    LUT5 #(.INIT(32'h8E96E8F0))
    LUT5_row2_inst3 (
        .O (col7_wire[2]),
        .I0(OPB[3]),
        .I1(OPB[4]),
        .I2(OPB[5]),
        .I3(OPA[2]),
        .I4(OPA[3]));
    
    LUT5 #(.INIT(32'h8EE896F0))
    LUT5_row2_inst4 (
        .O (col8_wire[1]),
        .I0(OPB[3]),
        .I1(OPB[4]),
        .I2(OPB[5]),
        .I3(OPA[4]),
        .I4(OPA[3]));
    
    LUT5 #(.INIT(32'h8E96E8F0))
    LUT5_row2_inst5 (
        .O (col9_wire[1]),
        .I0(OPB[3]),
        .I1(OPB[4]),
        .I2(OPB[5]),
        .I3(OPA[4]),
        .I4(OPA[5]));
    
    LUT6_2 #(.INIT(64'h710F710F8EE896F0))
    LUT6_2_row2_inst6 (
        .O6(col11_wire[0]),
        .O5(col10_wire[0]),
        .I0(OPB[3]),
        .I1(OPB[4]),
        .I2(OPB[5]),
        .I3(OPA[6]),
        .I4(OPA[5]),
        .I5(1'b1));
    
    
    // the main part of row 3
    LUT6_2 #(.INIT(64'h8E96E8F096F096F0))
    LUT6_2_row3_inst0 (
        .O6(col7_wire[3]),
        .O5(col6_wire[3]),
        .I0(OPB[5]),
        .I1(OPB[6]),
        .I2(OPB[7]),
        .I3(OPA[0]),
        .I4(OPA[1]),
        .I5(1'b1));
    
    LUT6_2 #(.INIT(64'hAACCAACCACACACAC))
    LUT6_2_row3_inst2 (
        .O6(col9_wire[2]),
        .O5(col8_wire[2]),
        .I0(OPB[5]),
        .I1(OPB[6]),
        .I2(OPA[2]),
        .I3(OPA[3]),
        .I4(1'b1),
        .I5(1'b1));
    
    LUT6_2 #(.INIT(64'hAACCAACCACACACAC))
    LUT6_2_row3_inst4 (
        .O6(col11_wire[1]),
        .O5(col10_wire[1]),
        .I0(OPB[5]),
        .I1(OPB[6]),
        .I2(OPA[4]),
        .I3(OPA[5]),
        .I4(1'b1),
        .I5(1'b1));
    
    LUT6_2 #(.INIT(64'h710F710F8EE896F0))
    LUT6_2_row3_inst6 (
        .O6(col13_wire),
        .O5(col12_wire),
        .I0(OPB[5]),
        .I1(OPB[6]),
        .I2(OPB[7]),
        .I3(OPA[6]),
        .I4(OPA[5]),
        .I5(1'b1));
    
    assign col0_wire[1] = OPB[1];
    assign col2_wire[2] = OPB[3];
    assign col4_wire[3] = OPB[5];
    assign col6_wire[4] = OPB[7];
    
    always_ff @(posedge clk) begin
        col0 <= col0_wire;
        col1 <= col1_wire;
        col2 <= col2_wire;
        col3 <= col3_wire;
        col4 <= col4_wire;
        col5 <= col5_wire;
        col6 <= col6_wire;
        col7 <= col7_wire;
        col8 <= col8_wire;
        col9 <= col9_wire;
        col10 <= col10_wire;
        col11 <= col11_wire;
        col12 <= col12_wire;
        col13 <= col13_wire;
    end
    
endmodule