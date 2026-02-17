`timescale 1ns / 1ps

module instr_mem_tb;

    // 1. Declare signals
    reg  [31:0] pc;
    wire [39:0] instr;

    // 2. Instantiate the Unit Under Test
    // We override the parameter to point to our existing manual file
    instr_mem #(.MEMFILE("testbench/test_mem.hex")) uut (
        .pc(pc),
        .instr(instr)
    );

    // Variables for testing
    integer errors;

    // 3. Test Logic
    initial begin
        $dumpfile("instr_mem.vcd");
        $dumpvars(0, instr_mem_tb);

        errors = 0;
        pc = 0;

        $display("---------------------------------------------------");
        $display("Starting Testbench for Instruction Memory...");
        $display("---------------------------------------------------");
        $display("| PC       | Output Instr (Little Endian) | Result |");
        $display("|----------|------------------------------|--------|");

        // --- TEST 1: Read at PC = 0 ---
        // File has: 00 01 02 03 04
        // Expected Little Endian: 0403020100
        pc = 0;
        #1; 
        check_mem(40'h0403020100);

        // --- TEST 2: Read at PC = 1 (Unaligned) ---
        // File has: 01 02 03 04 05
        // Expected: 0504030201
        pc = 1;
        #1;
        check_mem(40'h0504030201);

        // --- TEST 3: Read at PC = 5 ---
        // File has: 05 06 07 08 09
        // Expected: 0908070605
        pc = 5;
        #1;
        check_mem(40'h0908070605);

        // --- Final Report ---
        $display("---------------------------------------------------");
        if (errors == 0) begin
            $display("TEST PASSED: Memory loaded and read correctly.");
        end else begin
            $display("TEST FAILED: Found %0d errors.", errors);
        end
        $display("---------------------------------------------------");
        $finish;
    end

    // Helper Task
    task check_mem;
        input [39:0] expected;
        begin
            if (instr !== expected) begin
                $display("[FAIL] PC=%d. Exp %h, Got %h", pc, expected, instr);
                errors = errors + 1;
            end else begin
                $display("| %d        | %h                   | [PASS] |", pc, instr);
            end
        end
    endtask

endmodule