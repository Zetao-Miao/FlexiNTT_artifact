`timescale 1ns / 1ps
module ms_n65536_p32_4x16x32x32_tw_otf_fri_wlm_bank_slots_rot2_dspt4536_k_mtab (
    input  logic clk,
    input  logic [2:0] idx,
    output logic [44:0] QH
    );
    (* rom_style = "distributed" *) logic [44:0] m_QH [8];
    initial begin
        m_QH[0] = 45'h1ffffffff3c7;
        m_QH[1] = 45'h1ffffffff3a7;
        m_QH[2] = 45'h1ffffffff39b;
        m_QH[3] = 45'h1ffffffff379;
        m_QH[4] = 45'h1ffffffff36b;
        m_QH[5] = 45'h0;
        m_QH[6] = 45'h0;
        m_QH[7] = 45'h0;
    end
    (* max_fanout = 16 *) logic [44:0] r_QH;
    always_ff @(posedge clk) r_QH <= m_QH[idx];
    assign QH = r_QH;
endmodule
