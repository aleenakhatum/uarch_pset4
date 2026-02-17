`timescale 1ns / 1ps

module if_id_pr_tb;

    // 1. Declare signals
    reg         clk;
    reg         rst;
    reg         stall;
    reg         flush;
    reg  [39:0] instr_in;
    reg  [31:0] pc_in;
    
    wire [39:0] instr_out;
    wire [31:0] pc_out;
    wire        valid_out;

    // 2. Instantiate the Unit Under Test (UUT)
    if_id_pr uut (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .instr_in(instr_in),
        .pc_in(pc_in),
        .instr_out(instr_out),
        .pc_out(pc_out),
        .valid_out(valid_out)
    );

    // 3. Clock Generation
    always #5 clk = ~clk;

    // Variables
    integer errors;

    // 4. Test Logic
    initial begin
        $dumpfile("if_id_pr.vcd");
        $dumpvars(0, if_id_pr_tb);

        // Init
        errors = 0;
        clk = 0; rst = 0; stall = 0; flush = 0;
        instr_in = 40'h0; pc_in = 32'h0;

        $display("---------------------------------------------------");
        $display("Starting Testbench for IF/ID Pipeline Register...");
        $display("---------------------------------------------------");

        // --- Test 1: Reset ---
        // Expect Valid=0, Data=0
        rst = 1; #1;
        check_all(1'b0, 40'h0, 32'h0, "Reset");
        rst = 0; #10;

        // --- Test 2: Normal Load (Write Enable) ---
        // stall=0, flush=0. Should load new data and set Valid=1
        instr_in = 40'hAABBCCDDEE;
        pc_in    = 32'h1000;
        stall    = 0;
        
        @(posedge clk); #1;
        check_all(1'b1, 40'hAABBCCDDEE, 32'h1000, "Normal Load");


        // --- Test 3: Stall (Freeze) ---
        // Change inputs, but set Stall=1. Outputs should STAY OLD value.
        stall    = 1;
        instr_in = 40'h1122334455; // Garbage input
        pc_in    = 32'hDEAD;       // Garbage input
        
        @(posedge clk); #1;
        // Expecting OLD values (AABB... and 1000)
        check_all(1'b1, 40'hAABBCCDDEE, 32'h1000, "Stall Mode");


        // --- Test 4: Flush (Clear) ---
        // stall=0, flush=1. Should clear valid bit and data.
        stall = 0;
        flush = 1;
        
        @(posedge clk); #1; // Note: Async reset might clear it instantly before clock too
        check_all(1'b0, 40'h0, 32'h0, "Flush");
        flush = 0;


        // --- Test 5: Stall vs Flush Priority ---
        // If we Stall AND Flush at the same time, Flush should win (Reset > WE).
        // First, load some valid data
        instr_in = 40'hFFFFFFFFFF; pc_in = 32'hFFFF;
        stall = 0; // un-stall to load
        @(posedge clk); #1; // Load it
        
        // Now Stall AND Flush
        stall = 1;
        flush = 1;
        @(posedge clk); #1;
        
        // Expect Cleared Data (Flush wins)
        check_all(1'b0, 40'h0, 32'h0, "Priority (Flush > Stall)");


        // Final Report
        $display("---------------------------------------------------");
        if (errors == 0) $display("TEST PASSED: Pipeline Logic Verified!");
        else $display("TEST FAILED: Found %0d errors.", errors);
        $display("---------------------------------------------------");
        $finish;
    end

    // Helper Task to check all 3 outputs at once
    task check_all;
        input exp_valid;
        input [39:0] exp_instr;
        input [31:0] exp_pc;
        input [20*8:1] test_name; // String for debug
        begin
            if (valid_out !== exp_valid || instr_out !== exp_instr || pc_out !== exp_pc) begin
                $display("[ERROR] %s Failed!", test_name);
                $display("        Expected: Valid=%b, PC=%h, Instr=%h", exp_valid, exp_pc, exp_instr);
                $display("        Got:      Valid=%b, PC=%h, Instr=%h", valid_out, pc_out, instr_out);
                errors = errors + 1;
            end else begin
               // Uncomment next line to see successful checks
               // $display("[PASS]  %s", test_name);
            end
        end
    endtask

endmodule