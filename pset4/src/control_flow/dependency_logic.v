module dependency_logic(
    input wire [2:0] E_dst_idx,
    input wire [2:0] M_dst_idx,
    input wire [2:0] WB_dst_idx,
    input wire [2:0] D_src1_idx,
    input wire [2:0] D_src2_idx,
    output wire D_stall
);

    // 1. Compare D_src1 against all future destinations
    wire match1_E, match1_M, match1_WB;
    comp3 c1e (.eq(match1_E),  .a(D_src1_idx), .b(E_dst_idx));
    comp3 c1m (.eq(match1_M),  .a(D_src1_idx), .b(M_dst_idx));
    comp3 c1w (.eq(match1_WB), .a(D_src1_idx), .b(WB_dst_idx));

    // 2. Compare D_src2 against all future destinations
    wire match2_E, match2_M, match2_WB;
    comp3 c2e (.eq(match2_E),  .a(D_src2_idx), .b(E_dst_idx));
    comp3 c2m (.eq(match2_M),  .a(D_src2_idx), .b(M_dst_idx));
    comp3 c2w (.eq(match2_WB), .a(D_src2_idx), .b(WB_dst_idx));

    // 3. Combine matches (OR Tree)
    // If ANY match is true, we must stall.
    
    // Combine Src1 Hazards
    wire stall_src1_temp, stall_src1;
    or2$ o1 (.out(stall_src1_temp), .in0(match1_E), .in1(match1_M));
    or2$ o2 (.out(stall_src1),      .in0(stall_src1_temp), .in1(match1_WB));

    // Combine Src2 Hazards
    wire stall_src2_temp, stall_src2;
    or2$ o3 (.out(stall_src2_temp), .in0(match2_E), .in1(match2_M));
    or2$ o4 (.out(stall_src2),      .in0(stall_src2_temp), .in1(match2_WB));

    // Final Stall Output (Src1 Hazard OR Src2 Hazard)
    or2$ o_final (.out(D_stall), .in0(stall_src1), .in1(stall_src2));

endmodule
