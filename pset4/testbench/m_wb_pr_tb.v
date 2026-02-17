`timescale 1ns / 1ps

module mem_wb_pr_tb;

    // 1. Inputs
    reg clk;
    reg rst;
    reg stall;
    reg flush;
    
    reg        valid_in;
    reg [6:0]  ctrl_in;
    reg [2:0]  dst_idx_in;
    reg [31:0] result_in;

    // 2. Outputs
    wire        valid_out;
    wire [6:0]  ctrl_out;
    wire [2:0]  dst_idx_out;
    wire [31:0] result_out;

    // 3. Instantiate UUT
    mem_wb_pr uut (
        .clk(clk), .rst(rst), .stall(stall), .flush(flush),
        .valid_in(valid_in),
        .ctrl_in(ctrl_in),
        .dst_idx_in(dst_idx_in),
        .result_in(result_in),
        
        .valid_out(valid_out),
        .ctrl_out(ctrl_out),
        .dst_idx_out(dst_idx_out),
        .result_out(result_out)
    );

    // 4. Clock
    always #5 clk = ~clk;

    integer errors;

    // 5. Test Logic
    initial begin
        $dumpfile("mem_wb_pr.vcd");
        $dumpvars(0, mem_wb_pr_tb);
        
        // Init
        clk = 0; rst = 0; stall = 0; flush = 0;
        valid_in = 0; ctrl_in = 0; dst_idx_in = 0; result_in = 0;
        errors = 0;

        $display("---------------------------------------------------");
        $display("Starting MEM/WB Pipeline Register Test...");
        $display("---------------------------------------------------");

        // --- TEST 1: Reset ---
        rst = 1; #10; rst = 0; #10;
        
        if (result_out !== 0 || valid_out !== 0) begin
             $display("[FAIL] Reset Failed. Result=%h Valid=%b", result_out, valid_out);
             errors = errors + 1;
        end else $display("[PASS] Reset OK");


        // --- TEST 2: Normal Data Flow ---
        @(negedge clk);
        stall = 0; flush = 0;
        valid_in = 1;
        ctrl_in = 7'b010_1010;
        dst_idx_in = 3'd2;
        result_in = 32'h1234_ABCD;

        @(posedge clk); 
        #1; 

        if (result_out !== 32'h1234_ABCD || ctrl_out !== 7'b010_1010 || dst_idx_out !== 3'd2) begin
             $display("[FAIL] Normal Flow. Got Result=%h, Ctrl=%b", result_out, ctrl_out);
             errors = errors + 1;
        end else $display("[PASS] Normal Flow OK");


        // --- TEST 3: Stall (Freeze) ---
        @(negedge clk);
        stall = 1;
        // Change inputs
        result_in = 32'hFFFF_FFFF;
        valid_in = 0;
        
        @(posedge clk);
        #1; 

        // Verify outputs match the OLD values (1234_ABCD)
        if (result_out !== 32'h1234_ABCD) begin
             $display("[FAIL] Stall Failed. Value updated to %h", result_out);
             errors = errors + 1;
        end else $display("[PASS] Stall (Freeze) OK");
        
        stall = 0; 


        // --- TEST 4: Flush (Clear) ---
        @(negedge clk);
        flush = 1;
        valid_in = 1; // Try to push valid data
        
        @(posedge clk);
        #1;

        if (result_out !== 0 || valid_out !== 0) begin
             $display("[FAIL] Flush Failed. Valid=%b (Exp 0), Res=%h", valid_out, result_out);
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