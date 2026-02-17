`timescale 1ns / 1ps

module dependency_logic_tb;

    // 1. Inputs
    reg [2:0] E_dst_idx;
    reg [2:0] M_dst_idx;
    reg [2:0] WB_dst_idx;
    reg [2:0] D_src1_idx;
    reg [2:0] D_src2_idx;

    // 2. Outputs
    wire D_stall;

    // 3. Instantiate UUT
    dependency_logic uut (
        .E_dst_idx(E_dst_idx),
        .M_dst_idx(M_dst_idx),
        .WB_dst_idx(WB_dst_idx),
        .D_src1_idx(D_src1_idx),
        .D_src2_idx(D_src2_idx),
        .D_stall(D_stall)
    );

    integer errors;

    // 4. Test Logic
    initial begin
        $dumpfile("dependency_logic.vcd");
        $dumpvars(0, dependency_logic_tb);

        // Init
        E_dst_idx = 0; M_dst_idx = 0; WB_dst_idx = 0;
        D_src1_idx = 1; D_src2_idx = 2; // Set sources to something distinct
        errors = 0;

        $display("---------------------------------------------------");
        $display("Starting Dependency Logic Test...");
        $display("---------------------------------------------------");

        // --- TEST 1: No Hazards ---
        // Destinations (4,5,6) are different from Sources (1,2)
        E_dst_idx = 3'd4; M_dst_idx = 3'd5; WB_dst_idx = 3'd6;
        D_src1_idx = 3'd1; D_src2_idx = 3'd2;
        #5;
        check_stall(0, "No Hazards");


        // --- TEST 2: Execute Hazard (Src1) ---
        // E_dst (1) == D_src1 (1) -> STALL
        E_dst_idx = 3'd1;
        #5;
        check_stall(1, "Execute Hazard (Src1)");
        E_dst_idx = 3'd4; // Reset


        // --- TEST 3: Memory Hazard (Src1) ---
        // M_dst (1) == D_src1 (1) -> STALL
        M_dst_idx = 3'd1;
        #5;
        check_stall(1, "Memory Hazard (Src1)");
        M_dst_idx = 3'd5; // Reset


        // --- TEST 4: Writeback Hazard (Src2) ---
        // WB_dst (2) == D_src2 (2) -> STALL
        WB_dst_idx = 3'd2;
        #5;
        check_stall(1, "WB Hazard (Src2)");
        WB_dst_idx = 3'd6; // Reset


        // --- TEST 5: Multiple Hazards ---
        // E_dst matches Src1 AND M_dst matches Src2 -> STALL
        E_dst_idx = 3'd1; 
        M_dst_idx = 3'd2;
        #5;
        check_stall(1, "Double Hazard");


        // --- Summary ---
        $display("---------------------------------------------------");
        if (errors == 0) $display("ALL TESTS PASSED: Logic Correct.");
        else $display("TEST FAILED: Found %0d errors.", errors);
        $display("---------------------------------------------------");
        $finish;
    end

    // Helper Task
    task check_stall;
        input exp_stall;
        input [8*30:1] test_name;
        begin
            if (D_stall !== exp_stall) begin
                $display("[FAIL] %s: Exp Stall=%b, Got %b", test_name, exp_stall, D_stall);
                $display("       Src1=%d, Src2=%d | E_dst=%d, M_dst=%d, WB_dst=%d", 
                        D_src1_idx, D_src2_idx, E_dst_idx, M_dst_idx, WB_dst_idx);
                errors = errors + 1;
            end else begin
                $display("[PASS] %s", test_name);
            end
        end
    endtask

endmodule