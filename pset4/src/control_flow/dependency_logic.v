`timescale 1ns / 1ps
module dependency_logic(
    input wire D_read1,
    input wire D_read2,
    input wire [2:0] R_dst_idx,
    input wire [2:0] E_dst_idx,
    input wire [2:0] M_dst_idx,
    input wire [2:0] WB_dst_idx,
    input wire [2:0] D_src1_idx,
    input wire [2:0] D_src2_idx,
    input wire R_valid,
    input wire E_valid,
    input wire M_valid,
    input wire WB_valid,
    input wire R_regwrite,
    input wire E_regwrite,
    input wire M_regwrite,
    input wire WB_regwrite,
    output wire D_stall
);

    wire D_src1_active, D_src2_active;
    and2$ gD1 (.out(D_src1_active), .in0(D_valid), .in1(D_read1)); // Only care if Valid AND Reading
    and2$ gD2 (.out(D_src2_active), .in0(D_valid), .in1(D_read2));



    // 1. Raw Comparisons
    wire m1R_raw, m1E_raw, m1M_raw, m1W_raw;
    comp3 c1r (.eq(m1R_raw), .a(D_src1_idx), .b(R_dst_idx));
    comp3 c1e (.eq(m1E_raw), .a(D_src1_idx), .b(E_dst_idx));
    comp3 c1m (.eq(m1M_raw), .a(D_src1_idx), .b(M_dst_idx));
    comp3 c1w (.eq(m1W_raw), .a(D_src1_idx), .b(WB_dst_idx));

    wire m2R_raw, m2E_raw, m2M_raw, m2W_raw;
    comp3 c2r (.eq(m2R_raw), .a(D_src2_idx), .b(R_dst_idx));
    comp3 c2e (.eq(m2E_raw), .a(D_src2_idx), .b(E_dst_idx));
    comp3 c2m (.eq(m2M_raw), .a(D_src2_idx), .b(M_dst_idx));
    comp3 c2w (.eq(m2W_raw), .a(D_src2_idx), .b(WB_dst_idx));

    // 2. Safe Gating (Valid AND RegWrite)
    // We only stall if the stage is valid AND it is actually writing to a register.
    wire R_active, E_active, M_active, W_active;
    and2$ gR (.out(R_active), .in0(R_valid), .in1(R_regwrite));
    and2$ gE (.out(E_active), .in0(E_valid), .in1(E_regwrite));
    and2$ gM (.out(M_active), .in0(M_valid), .in1(M_regwrite));
    and2$ gW (.out(W_active), .in0(WB_valid), .in1(WB_regwrite));

    // 3. X-Killer MUXes (Gate comparisons with active signals)
    wire m1R, m1E, m1M, m1W, m2R, m2E, m2M, m2W;
    mux2$ mx1r (.outb(m1R), .in0(1'b0), .in1(m1R_raw), .s0(R_active));
    mux2$ mx1e (.outb(m1E), .in0(1'b0), .in1(m1E_raw), .s0(E_active));
    mux2$ mx1m (.outb(m1M), .in0(1'b0), .in1(m1M_raw), .s0(M_active));
    mux2$ mx1w (.outb(m1W), .in0(1'b0), .in1(m1W_raw), .s0(W_active));

    mux2$ mx2r (.outb(m2R), .outb(m2R), .in0(1'b0), .in1(m2R_raw), .s0(R_active));
    mux2$ mx2e (.outb(m2E), .outb(m2E), .in0(1'b0), .in1(m2E_raw), .s0(E_active));
    mux2$ mx2m (.outb(m2M), .in0(1'b0), .in1(m2M_raw), .s0(M_active));
    mux2$ mx2w (.outb(m2W), .in0(1'b0), .in1(m2W_raw), .s0(W_active));

    // 4. Final Stall Output (OR Tree)
    // src1
    wire s1_tier1_a, s1_tier1_b, s1_any_match;
    or2$ o1_1 (.out(s1_tier1_a), .in0(m1R), .in1(m1E)); // Check RR and EX
    or2$ o1_2 (.out(s1_tier1_b), .in0(m1M), .in1(m1W)); // Check MEM and WB
    or2$ o1_3 (.out(s1_any_match), .in0(s1_tier1_a), .in1(s1_tier1_b));

    wire stall_src1;
    and2$ a_s1_final (.out(stall_src1), .in0(s1_any_match), .in1(D_read1));

    // src2
    wire s2_tier1_a, s2_tier1_b, s2_any_match;
    or2$ o2_1 (.out(s2_tier1_a), .in0(m2R), .in1(m2E)); // Check RR and EX
    or2$ o2_2 (.out(s2_tier1_b), .in0(m2M), .in1(m2W)); // Check MEM and WB
    or2$ o2_3 (.out(s2_any_match), .in0(s2_tier1_a), .in1(s2_tier1_b));

    wire stall_src2;
    and2$ a_s2_final (.out(stall_src2), .in0(s2_any_match), .in1(D_read2));
    
    // global stall
    or2$ o_global (.out(D_stall), .in0(stall_src1), .in1(stall_src2));

endmodule