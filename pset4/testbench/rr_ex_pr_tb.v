`timescale 1ns / 1ps

module rr_ex_pr_tb;

    // 1. Inputs
    reg clk;
    reg rst;
    reg stall;
    reg flush;
    
    // Data Inputs
    reg [2:0]  instr_length_in;
    reg [31:0] pc_in;
    reg [6:0]  ctrl_in;
    reg [2:0]  dst_idx_in;
    reg [31:0] src1_in;
    reg [31:0] src2_in;
    reg        valid_in;

    // 2. Outputs
    wire [31:0] pc_out;
    wire [6:0]  ctrl_out;
    wire [2:0]  dst_idx_out;
    wire [31:0] src1_out;
    wire [31:0] src2_out;
    wire        valid_out;
    wire [2:0]  instr_length_out;

    // 3. Instantiate UUT
    rr_ex_pr uut (
        .clk(clk), .rst(rst), .stall(stall), .flush(flush),
        .instr_length_in(instr_length_in),
        .pc_in(pc_in),
        .ctrl_in(ctrl_in),
        .dst_idx_in(dst_idx_in),
        .src1_in(src1_in),
        .src2_in(src2_in),
        .valid_in(valid_in),
        
        .pc_out(pc_out),
        .ctrl_out(ctrl_out),
        .dst_idx_out(dst_idx_out),
        .src1_out(src1_out),
        .src2_out(src2_out),
        .valid_out(valid_out),
        .instr_length_out(instr_length_out)
    );

    // 4. Clock
    always #5 clk = ~clk;

    integer errors;

    // 5. Test Logic
    initial begin
        $dumpfile("rr_ex_pr.vcd");
        $dumpvars(0, rr_ex_pr_tb);
        
        // Init
        clk = 0; rst = 0; stall = 0; flush = 0;
        instr_length_in = 0; pc_in = 0; ctrl_in = 0;
        dst_idx_in = 0; src1_in = 0; src2_in = 0; valid_in = 0;
        errors = 0;

        $display("---------------------------------------------------");
        $display("Starting RR/EX Pipeline Register Test...");
        $display("---------------------------------------------------");

        // --- TEST 1: Reset ---
        // Assert Reset and ensure everything clears
        rst = 1; #10; rst = 0; #10;
        
        if (pc_out !== 0 || valid_out !== 0) begin
             $display("[FAIL] Reset Failed. PC=%h Valid=%b", pc_out, valid_out);
             errors = errors + 1;
        end else $display("[PASS] Reset OK");


        // --- TEST 2: Normal Data Flow ---
        // Load distinct values into all fields
        @(negedge clk);
        stall = 0; flush = 0;
        pc_in = 32'hAAAA_5555;
        ctrl_in = 7'b111_0000;
        dst_idx_in = 3'd7;
        src1_in = 32'h1234_5678;
        src2_in = 32'h9ABC_DEF0;
        instr_length_in = 3'd4;
        valid_in = 1;

        @(posedge clk); // Capture
        #1; // Wait for propagation

        if (pc_out !== 32'hAAAA_5555 || src1_out !== 32'h1234_5678 || 
            dst_idx_out !== 3'd7 || valid_out !== 1) begin
             $display("[FAIL] Normal Flow. Got PC=%h, Src1=%h, Dst=%d", pc_out, src1_out, dst_idx_out);
             errors = errors + 1;
        end else $display("[PASS] Normal Flow OK");


        // --- TEST 3: Stall (Freeze) ---
        // Change inputs completely, but hold STALL high.
        // Outputs should NOT change.
        @(negedge clk);
        stall = 1;
        pc_in = 32'hDEAD_BEEF; // Garbage
        src1_in = 32'h0000_0000;
        valid_in = 0;
        
        @(posedge clk);
        #1; 

        // Verify outputs match the OLD values (from Test 2)
        if (pc_out !== 32'hAAAA_5555 || src1_out !== 32'h1234_5678) begin
             $display("[FAIL] Stall Failed. Values updated! PC=%h", pc_out);
             errors = errors + 1;
        end else $display("[PASS] Stall (Freeze) OK");
        
        stall = 0; // Release Stall


        // --- TEST 4: Flush (Synchronous Clear) ---
        // Assert FLUSH. Valid bit and data should clear to 0.
        @(negedge clk);
        flush = 1;
        pc_in = 32'hFFFF_FFFF; // Try to write data
        valid_in = 1;
        
        @(posedge clk);
        #1;

        // Check for 0
        if (pc_out !== 0 || valid_out !== 0 || src1_out !== 0) begin
             $display("[FAIL] Flush Failed. Valid=%b (Exp 0), PC=%h", valid_out, pc_out);
             errors = errors + 1;
        end else $display("[PASS] Flush (Reset) OK");

        
        // --- Summary ---
        $display("---------------------------------------------------");
        if (errors == 0) $display("ALL TESTS PASSED");
        else $display("TEST FAILED: Found %0d errors.", errors);
        $display("---------------------------------------------------");
        $finish;
    end

endmodule