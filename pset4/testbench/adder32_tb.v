`timescale 1ns / 1ps

module adder32_tb;

    reg  [31:0] src1;
    reg  [31:0] src2;
    wire [31:0] result;

    adder32 uut (
        .src1(src1),
        .src2(src2),
        .result(result)
    );

    integer i;
    integer errors;
    reg [31:0] expected;

    initial begin
        $dumpfile("adder32.vcd");
        $dumpvars(0, adder32_tb);

        errors = 0;
        src1 = 0; src2 = 0;

        $display("---------------------------------------------------");
        $display("Starting Testbench for 32-bit Adder...");
        $display("---------------------------------------------------");

        // --- TEST 1: Zero + Zero ---
        src1 = 0; src2 = 0; 
        #20; // <--- INCREASED WAIT TIME
        check_add(32'h0, "Zero+Zero");

        // --- TEST 2: Simple Addition ---
        src1 = 10; src2 = 20; 
        #20; // <--- INCREASED WAIT TIME
        check_add(32'd30, "10 + 20");

        // --- TEST 3: Carry Propagation ---
        src1 = 32'h0000000F; src2 = 1; 
        #20; 
        check_add(32'h00000010, "Boundary Carry");

        // --- TEST 4: Max Value ---
        src1 = 32'hFFFFFFFF; src2 = 1; 
        #20;
        check_add(32'h00000000, "Overflow Wrap");

        // --- TEST 5: Alternating Bits ---
        src1 = 32'hAAAAAAAA; src2 = 32'h55555555; 
        #20;
        check_add(32'hFFFFFFFF, "Alt Bits");


        // --- TEST 6: Randomized Testing ---
        $display("Running 20 Random Vectors...");
        for (i = 0; i < 20; i = i + 1) begin
            src1 = $random;
            src2 = $random;
            expected = src1 + src2; 
            
            #20; // <--- Wait for Ripple Carry
            
            if (result !== expected) begin
                $display("[FAIL] %h + %h = %h (Expected %h)", src1, src2, result, expected);
                errors = errors + 1;
            end
        end

        $display("---------------------------------------------------");
        if (errors == 0) $display("TEST PASSED: 32-bit Adder works perfectly!");
        else $display("TEST FAILED: Found %0d errors.", errors);
        $display("---------------------------------------------------");
        $finish;
    end

    task check_add;
        input [31:0] exp_val;
        input [20*8:1] name;
        begin
            if (result !== exp_val) begin
                $display("[FAIL] %s: %h + %h = %h (Expected %h)", 
                         name, src1, src2, result, exp_val);
                errors = errors + 1;
            end else begin
                $display("| %h | %h | %h | %h | [PASS] |", src1, src2, result, exp_val);
            end
        end
    endtask

endmodule