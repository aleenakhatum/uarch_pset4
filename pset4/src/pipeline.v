`timescale 1ns / 1ps

module pipeline_top(
    input wire clk,
    input wire rst,

    // Debug Ports
    output wire [31:0] debug_pc,
    output wire [31:0] debug_result
);

    // =========================================================================
    // 1. WIRES & INTERCONNECTS
    // =========================================================================

    // --- Control Signals ---
    wire stall_global; // From Dependency Logic
    wire flush_jmp;    // From Execute Stage
    wire actual_stall;

    // --- FETCH Stage Wires ---
    wire [31:0] F_pc_current;
    wire [31:0] F_pc_next;
    wire [39:0] F_instr;
    wire [2:0]  F_instr_len;
    
    // Feedback from Execute
    wire [31:0] E_jmp_target;
    wire        E_is_jmp;
    wire        E_is_halt;

    // --- IF/ID Outputs ---
    wire [39:0] D_instr;
    wire [31:0] D_pc;
    wire        D_valid;
    wire [2:0]  D_len_in; // Length from IF/ID

    // --- DECODE Outputs ---
    wire [31:0] D_imm;
    wire [2:0]  D_src1_idx;
    wire [2:0]  D_src2_idx;
    wire [6:0]  D_ctrl;
    wire [7:0]  D_len_decoded; // 8-bit output from decode

    // --- ID/RR Outputs ---
    wire [31:0] RR_pc;
    wire [6:0]  RR_ctrl;
    wire [2:0]  RR_dst_idx;
    wire [2:0]  RR_src1_idx;
    wire [2:0]  RR_src2_idx;
    wire [31:0] RR_imm;
    wire        RR_valid;
    wire [2:0]  RR_instr_len;

    // --- RR Outputs (Reg Read) ---
    wire [31:0] RR_rdata1;
    wire [31:0] RR_rdata2;
    wire [31:0] RR_final_src2;

    // --- RR/EX Outputs ---
    wire [31:0] E_pc;
    wire [6:0]  E_ctrl;
    wire [2:0]  E_dst_idx;
    wire [31:0] E_src1;
    wire [31:0] E_src2;
    wire        E_valid;
    wire [2:0]  E_instr_len;

    // --- EXECUTE Outputs ---
    wire [31:0] E_result;
    
    // --- EX/MEM Outputs ---
    wire        M_valid;
    wire [6:0]  M_ctrl;
    wire [2:0]  M_dst_idx;
    wire [31:0] M_result;

    // --- MEM/WB Outputs ---
    wire        WB_valid;
    wire [6:0]  WB_ctrl;
    wire [2:0]  WB_dst_idx;
    wire [31:0] WB_result;

    //Stall Logic
    assign actual_stall = (stall_global == 1'b1) && (RR_valid || E_valid || M_valid || WB_valid);
    // =========================================================================
    // 2. FETCH STAGE
    // =========================================================================

    reg32 PC_REG(
        .clk(clk), 
        .set(1'b0), 
        .rst(rst),
        .wdata(F_pc_next), 
        .we(~actual_stall), 
        .rdata(F_pc_current)
    );

    fetch_stage FETCH(
        .rst(rst),
        .clk(clk),
        .pc_we(~actual_stall),
        .pc(F_pc_current),
        .jmp_target(E_jmp_target), 
        .is_jmp(E_is_jmp), 
        .is_halt(E_is_halt),
        .instr(F_instr),
        .next_pc(F_pc_next),
        .instr_length(F_instr_len)
    );

    // =========================================================================
    // 3. IF / ID REGISTER
    // =========================================================================

    if_id_pr IF_ID_REG (
        .clk(clk), 
        .rst(rst),
        .stall(actual_stall),
        .flush(1'b0), // Flush if jump taken
        .instr_in(F_instr),
        .pc_in(F_pc_current),
        .instr_length_in(F_instr_len),
        .instr_out(D_instr),
        .pc_out(D_pc),
        .valid_out(D_valid),
        .instr_length_out(D_len_in)
    );

    // =========================================================================
    // 4. DECODE STAGE & HAZARD LOGIC
    // =========================================================================

    decode_stage DECODE(
        .pc(D_pc),
        .instr(D_instr),
        .imm(D_imm),
        .src1_idx(D_src1_idx),
        .src2_idx(D_src2_idx),
        .ctrl(D_ctrl),
        .length(D_len_decoded) // We use D_len_in from Pipeline Reg for timing
    );

    dependency_logic HAZARD_UNIT (
        .D_read1(D_ctrl[4]),
        .D_read2(D_ctrl[3]),
        .R_dst_idx(RR_dst_idx),
        .E_dst_idx(E_dst_idx),
        .M_dst_idx(M_dst_idx),
        .WB_dst_idx(WB_dst_idx),
        .D_src1_idx(D_src1_idx),
        .D_src2_idx(D_src2_idx),
        .R_valid(RR_valid),
        .E_valid(E_valid),
        .M_valid(M_valid),
        .WB_valid(WB_valid),
        // Connect the RegWrite control bits
        .R_regwrite(RR_ctrl[2]),
        .E_regwrite(E_ctrl[2]),
        .M_regwrite(M_ctrl[2]),
        .WB_regwrite(WB_ctrl[2]),
        .D_stall(stall_global)
    );

    // =========================================================================
    // 5. ID / RR REGISTER
    // =========================================================================

    id_rr_pr ID_RR_REG (
        .clk(clk), .rst(rst),
        .stall(actual_stall),         
        .flush(E_is_jmp), 
        .instr_length_in(D_len_in), // Pass length from previous stage
        .pc_in(D_pc),
        .ctrl_in(D_ctrl),
        .src1_idx_in(D_src1_idx),
        .src2_idx_in(D_src2_idx),
        .imm_in(D_imm),
        .valid_in(D_valid),
        .pc_out(RR_pc),
        .ctrl_out(RR_ctrl),
        .dst_idx(RR_dst_idx),
        .src1_idx_out(RR_src1_idx),
        .src2_idx_out(RR_src2_idx),
        .imm_out(RR_imm),
        .valid_out(RR_valid),
        .instr_length_out(RR_instr_len)
    );

    // =========================================================================
    // 6. REGISTER READ & MUX
    // =========================================================================

    reg_file REGISTERS(
        .clk(clk), 
        .set(1'b0), 
        .rst(rst),
        .we(WB_ctrl[2] && WB_valid), // Bit 2 is WE from Decode
        .src1_idx(RR_src1_idx),
        .src2_idx(RR_src2_idx),
        .dst_idx(WB_dst_idx),
        .w_val(WB_result),
        .regfile_out1(RR_rdata1),
        .regfile_out2(RR_rdata2)
    );

    // Src2 Mux (Immediate vs Reg) - Ctrl Bit 6
    mux2_32 SRC2_MUX (
        .IN0(RR_rdata2),
        .IN1(RR_imm),
        .S0(RR_ctrl[6]),
        .Y(RR_final_src2)
    );

    // =========================================================================
    // 7. RR / EX REGISTER
    // =========================================================================

    rr_ex_pr RR_EX_REG (
        .clk(clk), .rst(rst),
        .stall(actual_stall), 
        .flush(E_is_jmp),
        .instr_length_in(RR_instr_len),
        .pc_in(RR_pc),
        .ctrl_in(RR_ctrl),
        .dst_idx_in(RR_dst_idx),
        .src1_in(RR_rdata1),
        .src2_in(RR_final_src2),
        .valid_in(RR_valid),
        .pc_out(E_pc),
        .ctrl_out(E_ctrl),
        .dst_idx_out(E_dst_idx),
        .src1_out(E_src1),
        .src2_out(E_src2),
        .valid_out(E_valid),
        .instr_length_out(E_instr_len)
    );

    // =========================================================================
    // 8. EXECUTE STAGE
    // =========================================================================

    execute_stage EXECUTE (
        .pc(E_pc),
        .instr_length({29'b0, E_instr_len}), 
        .src1(E_src1),
        .src2(E_src2),
        .ctrl(E_ctrl),
        .result(E_result),
        .jmp_target(E_jmp_target),
        .is_jmp(E_is_jmp),
        .is_halt(E_is_halt)
    );

    assign flush_jmp = E_is_jmp;

    // =========================================================================
    // 9. EX / MEM REGISTER
    // =========================================================================

    ex_m_pr EX_M_REG (
        .clk(clk), 
        .rst(rst),
        .stall(1'b0), 
        .flush(1'b0),
        .valid_in(E_valid),
        .ctrl_in(E_ctrl),
        .dst_idx_in(E_dst_idx),
        .execute_result_in(E_result),
        .valid_out(M_valid),
        .ctrl_out(M_ctrl),
        .dst_idx_out(M_dst_idx),
        .execute_result_out(M_result)
    );

    // =========================================================================
    // 10. MEM / WB REGISTER
    // =========================================================================

    mem_wb_pr MEM_WB_REG (
        .clk(clk), .rst(rst),
        .stall(1'b0), .flush(1'b0),
        .valid_in(M_valid),
        .ctrl_in(M_ctrl),
        .dst_idx_in(M_dst_idx),
        .result_in(M_result),
        .valid_out(WB_valid),
        .ctrl_out(WB_ctrl),
        .dst_idx_out(WB_dst_idx),
        .result_out(WB_result)
    );

    // 11. WRITEBACK STAGE (Implicit/Wire pass-through)
    writeback_stage WB_STAGE (
        .ctrl_in(WB_ctrl),
        .ctrl_out() // Unused, just for completeness
    );

    assign debug_pc = F_pc_current;
    assign debug_result = WB_result;

endmodule