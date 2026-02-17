`timescale 1ns / 1ps

module fetch_stage_tb;

    // 1. Declare signals
    reg         clk;
    reg         pc_we;
    reg  [31:0] pc;
    reg  [31:0] jmp_target;
    reg         is_jmp;
    reg  [2:0]  instr_length;
    reg         is_halt;
    
    wire [39:0] instr;
    wire [31:0] next_pc;

    // 2. Instantiate the Unit Under Test (UUT)
    fetch_stage uut (
        .clk(clk),
        .pc_we(pc_we),
        .pc(pc),
        .jmp_target(jmp_target),
        .is_jmp(is_jmp),
        .instr_length(instr_length),
        .is_halt(is_halt),
        .instr(instr),
        .next_pc(next_pc)
    );

    // 3. Clock Generation
    always #5 clk = ~clk;

    // Variables
    integer errors;

    // 4. Test Logic
    initial begin
        $dumpfile("fetch_stage.vcd");
        $dumpvars(0, fetch_stage_tb);

        // --- SETUP: Create dummy memory file if needed ---
        // (Assuming your instr_mem loads "test_mem.hex" or similar)
        // Ensure that file exists with pattern 00 01 02 03...
        
        // Init Inputs
        errors = 0;
        clk = 0;
        pc_we = 0;
        pc = 0;
        jmp_target = 0;
        is_jmp = 0;
        instr_length = 3'd5; // Standard x86 instruction length
        is_halt = 0;

        $display("---------------------------------------------------");
        $display("Starting Testbench for Fetch Stage...");
        $display("---------------------------------------------------");
        $display("| Type        | Current PC | Next PC (Calc) | Instr Output |");
        $display("|-------------|------------|----------------|--------------|");

        // --- TEST 1: STALL Check (pc_we = 0) ---
        // If we are stalled, Next PC should equal Current PC.
        pc_we = 0;
        pc    = 32'h10;
        #1;
        check_fetch(32'h10, "Stall (Hold PC)");


        // --- TEST 2: HALT Check (is_halt = 1) ---
        // Even if we enabled (pc_we=1), Halt should freeze PC.
        pc_we   = 1;
        is_halt = 1;
        pc      = 32'h20;
        #1;
        check_fetch(32'h20, "Halt (Freeze PC)");
        
        // Clear Halt
        is_halt = 0;


        // --- TEST 3: Normal Increment (PC + Length) ---
        // PC=0, Len=5. Next should be 5.
        // Also checks memory output (Little Endian 0403020100)
        pc_we        = 1;
        pc           = 32'h0;
        instr_length = 3'd5;
        is_jmp       = 0;
        #1;
        
        // Check Next PC
        if (next_pc !== 32'h5) begin
             $display("[FAIL] Normal Incr Failed. Exp 5, Got %d", next_pc);
             errors = errors + 1;
        end
        
        // Check Instruction (assuming 00 01 02 03 04 loaded in mem)
        if (instr !== 40'h0403020100) begin
             $display("[FAIL] Instr Fetch Failed. Got %h", instr);
             errors = errors + 1;
        end else begin
             $display("| Normal Step | %h   | %h       | %h   | [PASS]", pc, next_pc, instr);
        end


        // --- TEST 4: JUMP (PC + Length + Target) ---
        // PC=10, Len=5, Target=20.
        // Logic: 10 + 5 + 20 = 35 (0x23)
        pc           = 32'd10;
        instr_length = 3'd5;
        jmp_target   = 32'd20;
        is_jmp       = 1;
        #1;
        check_fetch(32'd35, "Jump Taken");


        // --- TEST 5: JUMP vs STALL Priority ---
        // If is_jmp=1 BUT pc_we=0 (Stall), we should STALL (Keep Old PC).
        // Stall usually overrides everything.
        pc_we  = 0;
        is_jmp = 1;
        pc     = 32'd100;
        #1;
        check_fetch(32'd100, "Stall overrides Jump");


        // --- Final Report ---
        $display("---------------------------------------------------");
        if (errors == 0) $display("TEST PASSED: Next PC Logic Verified.");
        else $display("TEST FAILED: Found %0d errors.", errors);
        $display("---------------------------------------------------");
        $finish;
    end

    // Helper Task
    task check_fetch;
        input [31:0] expected_next_pc;
        input [20*8:1] name;
        begin
            if (next_pc !== expected_next_pc) begin
                $display("[FAIL] %s: PC=%d. Exp Next=%d, Got %d", 
                         name, pc, expected_next_pc, next_pc);
                errors = errors + 1;
            end else begin
                $display("| %s | %h   | %h       | %h   | [PASS]", 
                         name, pc, next_pc, instr);
            end
        end
    endtask

endmodule