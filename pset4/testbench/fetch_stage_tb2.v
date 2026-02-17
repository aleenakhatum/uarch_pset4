`timescale 1ns / 1ps

module fetch_stage_tb2;

    // 1. Inputs
    reg         clk;
    reg         pc_we;
    reg  [31:0] pc;
    reg  [31:0] jmp_target;
    reg         is_jmp;
    reg         is_halt;

    // 2. Outputs
    wire [39:0] instr;
    wire [31:0] next_pc;

    // 3. Variables
    integer errors;
    integer f; // <--- FIXED: Moved declaration here (outside initial block)

    // 4. Create a Test Memory File dynamically
    initial begin
        f = $fopen("length_test.hex", "w");
        
        // Addr 0: 0x90 (NOP) -> Length 1
        $fwrite(f, "@00\n90\n"); 
        
        // Addr 1: 0x01 (ADD r,r) -> Length 2
        // We put garbage (00) at Addr 2 because the instr is 2 bytes
        $fwrite(f, "@01\n01\n00\n");

        // Addr 3: 0x83 (ADD r,imm8) -> Length 3
        $fwrite(f, "@03\n83\n00\n00\n");

        // Addr 6: 0xB8 (MOV r,imm32) -> Length 5
        $fwrite(f, "@06\nB8\n00\n00\n00\n00\n");

        $fclose(f);
    end

    // 5. Instantiate UUT
    fetch_stage uut (
        .clk(clk),
        .pc_we(pc_we),
        .pc(pc),
        .jmp_target(jmp_target),
        .is_jmp(is_jmp),
        .is_halt(is_halt),
        .instr(instr),
        .next_pc(next_pc)
    );

    // Force the memory to load our test file
    // Note: Update 'imem' to match your instance name inside fetch_stage
    defparam uut.imem.MEMFILE = "length_test.hex";

    // 6. Clock Gen
    always #5 clk = ~clk;

    // 7. Test Logic
    initial begin
        $dumpfile("fetch_stage_v2.vcd");
        $dumpvars(0, fetch_stage_tb2);

        // Init
        errors = 0;
        clk = 0; pc_we = 1; pc = 0; 
        jmp_target = 0; is_jmp = 0; is_halt = 0;

        // Wait for file load
        #1;

        $display("---------------------------------------------------");
        $display("Testing Fetch Stage v2 (Internal Length Decoder)");
        $display("---------------------------------------------------");

        // --- TEST 1: 1-Byte Instruction (NOP) ---
        pc = 0;
        #5; 
        check_pc(32'd1, "1-Byte Instr (NOP)");

        // --- TEST 2: 2-Byte Instruction (ADD) ---
        pc = 1;
        #5;
        check_pc(32'd3, "2-Byte Instr (ADD)");

        // --- TEST 3: 3-Byte Instruction (ADD imm8) ---
        pc = 3;
        #5;
        check_pc(32'd6, "3-Byte Instr (ADD imm8)");

        // --- TEST 4: 5-Byte Instruction (MOV imm32) ---
        pc = 6;
        #5;
        check_pc(32'd11, "5-Byte Instr (MOV)");


        // --- TEST 5: JUMP Override ---
        pc = 0;          // At NOP (Length 1)
        is_jmp = 1;      // Force Jump
        jmp_target = 32'hDEADBEEF;
        #5;
        check_pc(32'hDEADBEEF, "Jump Priority");
        
        is_jmp = 0; // Reset


        // --- TEST 6: Halt / Stall ---
        pc = 6;
        is_halt = 1;
        #5;
        check_pc(32'd6, "Halt (Freeze)");
        is_halt = 0;

        // Same for pc_we = 0
        pc_we = 0;
        #5;
        check_pc(32'd6, "Write Enable Low (Stall)");
        pc_we = 1;


        // --- Summary ---
        $display("---------------------------------------------------");
        if (errors == 0) $display("ALL TESTS PASSED: Length Decoder Works!");
        else $display("TEST FAILED: Found %0d errors.", errors);
        $display("---------------------------------------------------");
        $finish;
    end

    task check_pc;
        input [31:0] exp;
        input [20*8:1] name;
        begin
            if (next_pc !== exp) begin
                $display("[FAIL] %s: PC=%d, Opcode=%h. Exp Next=%d, Got %d", 
                        name, pc, instr[7:0], exp, next_pc);
                errors = errors + 1;
            end else begin
                $display("[PASS] %s: PC %d -> %d", name, pc, next_pc);
            end
        end
    endtask

endmodule