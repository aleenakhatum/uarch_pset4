`timescale 1ns / 1ps

module id_rr_pr_tb;

    // 1. Inputs
    reg clk;
    reg rst;
    reg stall;
    reg flush;
    
    // Data Inputs
    reg [2:0]  instr_length_in;
    reg [31:0] pc_in;
    reg [6:0]  ctrl_in;
    reg [2:0]  src1_idx_in;
    reg [2:0]  src2_idx_in;
    reg [31:0] imm_in;
    reg        valid_in;

    // 2. Outputs
    wire [31:0] pc_out;
    wire [6:0]  ctrl_out;
    wire [2:0]  dst_idx;
    wire [2:0]  src1_idx_out;
    wire [2:0]  src2_idx_out;
    wire [31:0] imm_out;
    wire        valid_out;
    wire [2:0]  instr_length_out;

    // 3. Instantiate UUT
    id_rr_pr uut (
        .clk(clk), .rst(rst), .stall(stall), .flush(flush),
        .instr_length_in(instr_length_in),
        .pc_in(pc_in),
        .ctrl_in(ctrl_in),
        .src1_idx_in(src1_idx_in),
        .src2_idx_in(src2_idx_in),
        .imm_in(imm_in),
        .valid_in(valid_in),
        
        .pc_out(pc_out),
        .ctrl_out(ctrl_out),
        .dst_idx(dst_idx),
        .src1_idx_out(src1_idx_out),
        .src2_idx_out(src2_idx_out),
        .imm_out(imm_out),
        .valid_out(valid_out),
        .instr_length_out(instr_length_out)
    );

    // 4. Clock
    always #5 clk = ~clk;

    integer errors;

    // 5. Test Logic
    initial begin
        $dumpfile("id_rr_pr.vcd");
        $dumpvars(0, id_rr_pr_tb);
        
        // Init
        clk = 0; rst = 0; stall = 0; flush = 0;
        instr_length_in = 0; pc_in = 0; ctrl_in = 0;
        src1_idx_in = 0; src2_idx_in = 0; imm_in = 0; valid_in = 0;
        errors = 0;

        $display("---------------------------------------------------");
        $display("Starting ID/RR Pipeline Register Test...");
        $display("---------------------------------------------------");

        // --- TEST 1: Reset ---
        rst = 1; #10; rst = 0; #10;
        if (pc_out !== 0) begin
             $display("[FAIL] Reset Failed. PC=%h", pc_out);
             errors = errors + 1;
        end

        // --- TEST 2: Normal Flow ---
        // Load some data
        @(negedge clk); // Set inputs away from edge
        pc_in = 32'h12345678;
        ctrl_in = 7'b1010101;
        src1_idx_in = 3'd1;
        src2_idx_in = 3'd2;
        imm_in = 32'hFFFFFFFF;
        valid_in = 1;
        instr_length_in = 3'd5;
        stall = 0; flush = 0;

        @(posedge clk); // Wait for capture
        #1; // Wait for prop delay

        if (pc_out !== 32'h12345678 || ctrl_out !== 7'b1010101 || src1_idx_out !== 3'd1) begin
             $display("[FAIL] Normal Flow. PC Exp 1234.., Got %h", pc_out);
             errors = errors + 1;
        end else $display("[PASS] Normal Flow OK");


        // --- TEST 3: Stall (Freeze) ---
        // Change inputs, but assert STALL. Outputs should STAY OLD VALUES.
        @(negedge clk);
        stall = 1;
        pc_in = 32'hDEADBEEF; // New garbage data
        ctrl_in = 7'b0000000;
        valid_in = 0;
        
        @(posedge clk);
        #1; 

        // Check if output is still the OLD value (0x12345678)
        if (pc_out !== 32'h12345678) begin
             $display("[FAIL] Stall Failed. PC updated to %h (Should match old)", pc_out);
             errors = errors + 1;
        end else $display("[PASS] Stall (Freeze) OK");
        
        stall = 0; // Release Stall

        // --- TEST 4: Flush (Clear) ---
        // Assert FLUSH. Outputs should go to 0.
        @(negedge clk);
        flush = 1;
        pc_in = 32'h99999999; // Inputs exist
        
        @(posedge clk);
        #1;

        if (pc_out !== 0 || valid_out !== 0) begin
             $display("[FAIL] Flush Failed. Valid=%b (Exp 0), PC=%h (Exp 0)", valid_out, pc_out);
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