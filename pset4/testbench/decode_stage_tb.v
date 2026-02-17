`timescale 1ns / 1ps

module decode_stage_tb;

    // 1. Declare signals
    reg  [31:0] pc;
    reg  [39:0] instr;
    
    wire [31:0] imm;
    wire [2:0]  src1_idx;
    wire [2:0]  src2_idx;
    wire [6:0]  ctrl;
    wire [7:0]  length;

    // Control Signal Mapping for easier debugging
    // ctrl = {src2mux, op, read1, read2, we, jmp, halt}
    wire val_src2mux = ctrl[6];
    wire val_op      = ctrl[5];
    wire val_read1   = ctrl[4];
    wire val_read2   = ctrl[3];
    wire val_we      = ctrl[2];
    wire val_jmp     = ctrl[1];
    wire val_halt    = ctrl[0];

    // 2. Instantiate Unit Under Test
    decode_stage uut (
        .pc(pc),
        .instr(instr),
        .imm(imm),
        .src1_idx(src1_idx),
        .src2_idx(src2_idx),
        .ctrl(ctrl),
        .length(length)
    );

    // Variables for testing
    integer errors;

    // 3. Test Logic
    initial begin
        $dumpfile("decode_stage.vcd");
        $dumpvars(0, decode_stage_tb);
        
        errors = 0;
        pc = 32'h1000; // Arbitrary PC
        
        $display("---------------------------------------------------");
        $display("Starting Testbench for Decode Stage...");
        $display("---------------------------------------------------");
        $display("| Opcode | Type          | Check Result  |");
        $display("|--------|---------------|---------------|");

        // --- TEST 1: MOV EAX, 0xDEADBEEF (Op: B8) ---
        // Format: [B8] [EF] [BE] [AD] [DE] (Little Endian Input)
        // Expected Imm: DEADBEEF
        // Expected Dst: 000 (EAX)
        // Control: WE=1, MUX=1 (Imm)
        instr = {8'hB8, 8'hEF, 8'hBE, 8'hAD, 8'hDE}; 
        #1;
        check_out(32'hDEADBEEF, 3'b000, 1'b1, 1'b1, "MOV EAX, Imm");


        // --- TEST 2: MOV ECX, 0x12345678 (Op: B9) ---
        // Format: [B9] [78] [56] [34] [12]
        // Expected Imm: 12345678
        // Expected Dst: 001 (ECX)
        instr = {8'hB9, 8'h78, 8'h56, 8'h34, 8'h12}; 
        #1;
        check_out(32'h12345678, 3'b001, 1'b1, 1'b1, "MOV ECX, Imm");


        // --- TEST 3: ADD EAX, 0x00000005 (Op: 05) ---
        // Format: [05] [05] [00] [00] [00]
        // Expected Imm: 5
        // Expected Dst: 000 (EAX)
        // Control: OP=1 (Add), WE=1
        instr = {8'h05, 8'h05, 8'h00, 8'h00, 8'h00}; 
        #1;
        // Verify Op bit (Bit 5 of ctrl) is 1
        if (val_op !== 1'b1) begin 
            $display("[FAIL] ADD Opcode not set!"); errors=errors+1; 
        end
        check_out(32'h5, 3'b000, 1'b1, 1'b1, "ADD EAX, Imm");


        // --- TEST 4: ADD r, r (Op: 01) ---
        // Instruction: ADD ECX, EAX (Dst=ECX, Src=EAX)
        // Format: [01] [ModRM] [XX] [XX] [XX]
        // ModRM Logic: [5:3]=Src, [2:0]=Dst
        // We want Src=000(EAX), Dst=001(ECX) -> ModRM = xxxx000001 -> 0x01
        instr = {8'h01, 8'h01, 24'h0}; 
        #1;
        
        // Custom check for register indices
        if (src1_idx !== 3'b001 || src2_idx !== 3'b000) begin
            $display("[FAIL] ADD r,r Indices. Exp Dst=1, Src=0. Got Dst=%d, Src=%d", src1_idx, src2_idx);
            errors = errors + 1;
        end else begin
           // $display("[PASS] ADD r,r Indices Correct");
        end
        // Check Control: WE=1, Mux=0 (Reg)
        check_out(32'h0, 3'b001, 1'b1, 1'b0, "ADD r, r");


        // --- TEST 5: JMP 0xAA (Op: E9) ---
        // Format: [E9] [AA] [00] [00] [00]
        instr = {8'hE9, 8'hAA, 24'h0}; 
        #1;
        
        if (val_jmp !== 1'b1) begin
            $display("[FAIL] JMP signal not set!"); 
            errors=errors+1; 
        end else begin
             $display("| E9     | JMP           | [PASS]        |");
        end


        // --- TEST 6: HALT (Op: F4) ---
        instr = {8'hF4, 32'h0};
        #1;
        
        if (val_halt !== 1'b1) begin
             $display("[FAIL] HALT signal not set!"); 
             errors=errors+1; 
        end else begin
             $display("| F4     | HALT          | [PASS]        |");
        end


        // --- TEST 7: ADD with Sign Extension (Op: 83) ---
        // ADD EAX, -1 (0xFF)
        // Op: 83, ModRM: ?? (Dst EAX=0), Imm8: FF
        // instr[23:16] is the immediate. 
        instr = {8'h83, 8'h00, 8'hFF, 16'h0};
        #1;
        
        // Expected Imm: FFFFFFFF (Sign extended from FF)
        check_out(32'hFFFFFFFF, 3'b000, 1'b1, 1'b1, "ADD Sext(Imm8)");


        // --- Final Report ---
        $display("---------------------------------------------------");
        if (errors == 0) $display("ALL TESTS PASSED: Decoder logic verified.");
        else $display("TEST FAILED: Found %0d errors.", errors);
        $display("---------------------------------------------------");
        $finish;
    end

    // Helper Task
    // Checks Immediate, Dest Index, Write Enable, and Src2 Mux
    task check_out;
        input [31:0] exp_imm;
        input [2:0]  exp_dst;
        input        exp_we;
        input        exp_mux; // 1=Imm, 0=Reg
        input [20*8:1] name;
        begin
            if (imm !== exp_imm) begin
                $display("[FAIL] %s: Imm Mismatch. Exp %h, Got %h", name, exp_imm, imm);
                errors = errors + 1;
            end else if (src1_idx !== exp_dst) begin
                $display("[FAIL] %s: Dst Idx Mismatch. Exp %d, Got %d", name, exp_dst, src1_idx);
                errors = errors + 1;
            end else if (val_we !== exp_we) begin
                $display("[FAIL] %s: WE Mismatch. Exp %b, Got %b", name, exp_we, val_we);
                errors = errors + 1;
            end else if (val_src2mux !== exp_mux) begin
                $display("[FAIL] %s: Mux Mismatch. Exp %b, Got %b", name, exp_mux, val_src2mux);
                errors = errors + 1;
            end else begin
                $display("| %h     | %s  | [PASS]        |", instr[39:32], name);
            end
        end
    endtask

endmodule