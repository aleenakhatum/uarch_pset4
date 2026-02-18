`timescale 1ns / 1ps

module pipeline_tb3;

    reg clk;
    reg rst;
    wire [31:0] debug_pc;
    wire [31:0] debug_result;

    // Instantiate Pipeline
    pipeline_top uut (
        .clk(clk),
        .rst(rst),
        .debug_pc(debug_pc),
        .debug_result(debug_result)
    );

    // Clock Generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("ctrlflow_test.vcd");
        $dumpvars(0, pipeline_tb3);
        
        // --- INITIALIZE ---
        clk = 0; 
        rst = 1;
        #50;
        rst = 0;

        $display("\n==========================================================");
        $display("   STARTING CONTROL FLOW (JMP) TEST");
        $display("==========================================================\n");

        // --- RUN SIMULATION ---
        repeat (30) begin
            @(posedge clk);
            #1; // Wait for logic to settle

            $display("Time: %0t ns | PC: %h ----------------", $time, debug_pc);

            // 1. FETCH
            $display("[IF] Instr: %h", uut.F_instr);

            // 2. DECODE
            $display("[ID] Instr: %h | Stall: %b", uut.D_instr, uut.stall_global);

            // 3. REGISTER READ
            $display("[RR] Valid: %b | Src1: %d | Src2: %d | Imm: %h", 
                     uut.RR_valid, uut.RR_src1_idx, uut.RR_src2_idx, uut.RR_imm);

            // 4. EXECUTE & BRANCHING
            $display("[EX] Valid: %b | IsJmp: %b | Target: %h | PC: %h", 
                     uut.E_valid, uut.E_is_jmp, uut.E_jmp_target, uut.E_pc);
            $display("     ALURes: %h", uut.E_result);

            // 5. MEMORY
            $display("[MEM] Valid: %b | Dest: %d | MemRes: %h", 
                     uut.M_valid, uut.M_dst_idx, uut.M_result);

            // 6. WRITEBACK
            $display("[WB] Valid: %b | Dest: %d | FinalData: %h", 
                     uut.WB_valid, uut.WB_dst_idx, uut.WB_result);

            // --- REGISTER FILE CHECK ---
            $display("[REGS] EAX: %h | ECX: %h", 
                     uut.REGISTERS.EAX.rdata, uut.REGISTERS.ECX.rdata);

            // --- CHECKS ---
            
            // TRAP CHECK: If EAX becomes FADEDACE, the jump failed.
            if (uut.REGISTERS.EAX.rdata == 32'hFADEDACE) begin
                $display("\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
                $display(" FAILURE: The CPU executed the skipped MOV instruction!");
                $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
                $finish;
            end

            // SUCCESS CHECK: EAX = 12341235
            if (uut.WB_valid && uut.WB_result == 32'h12341235) begin
                $display("\n**********************************************************");
                $display(" SUCCESS: JMP worked! EAX = 12341235");
                $display("**********************************************************");
                $finish;
            end
            
            $display("----------------------------------------------------------\n"); 
        end
        
        $display("\nFAILURE: Timed out.");
        $finish;
    end

endmodule
