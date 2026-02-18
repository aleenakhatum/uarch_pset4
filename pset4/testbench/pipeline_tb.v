`timescale 1ns / 1ps

module pipeline_tb;

    // 1. Signals
    reg clk;
    reg rst;
    wire [31:0] debug_pc;
    wire [31:0] debug_result;

    // 2. Instantiate Pipeline
    pipeline_top uut (
        .clk(clk),
        .rst(rst),
        .debug_pc(debug_pc),
        .debug_result(debug_result)
    );

    // 3. Clock Generation
    always #5 clk = (clk === 1'b0) ? 1'b1 : 1'b0; 

    // 4. Main Test Logic
    integer i;
    initial begin
        $dumpfile("pipeline_full_trace.vcd");
        $dumpvars(0, pipeline_tb);

        // --- INITIALIZATION ---
        clk = 0; 
        rst = 1;

        // Force PC to 0 to prevent startup drift
        force uut.PC_REG.rdata = 32'h0; 
        
        // Clear Memory
        for (i = 0; i < 512; i = i + 1) begin
            uut.FETCH.imem.mem[i] = 8'h90; // Fill with NOPs
        end

        // Inject ONE instruction: MOV EAX, 32'hDEADBEEF
        // Opcode B8, Immediate EF BE AD DE (Little Endian in memory)
        uut.FETCH.imem.mem[0] = 8'hB8; 
        uut.FETCH.imem.mem[1] = 8'hEF; 
        uut.FETCH.imem.mem[2] = 8'hBE; 
        uut.FETCH.imem.mem[3] = 8'hAD; 
        uut.FETCH.imem.mem[4] = 8'hDE;

        // Hold Reset to clear X's
        #50; 
        
        // Release Force and Reset on Falling Edge (Best for sync)
        release uut.PC_REG.rdata;
        @(negedge clk);
        rst = 0;
        
        $display("\n==========================================================");
        $display("   STARTING SINGLE INSTRUCTION TEST: MOV EAX, DEADBEEF");
        $display("==========================================================\n");

        // --- CYCLE-BY-CYCLE TRACKING ---
        repeat (15) begin
            @(posedge clk);
            #1; // Wait for logic to settle after clock edge

            $display("Time: %0t ns ---------------------------------------------", $time);
            
            // 1. FETCH STAGE
            $display("[IF] PC: %h | Instr Raw: %h", uut.F_pc_current, uut.F_instr);

            // 2. DECODE STAGE
            $display("[ID] Valid: %b | Instr: %h | Imm Decoded: %h", 
                     uut.D_valid, uut.D_instr, uut.D_imm);

            // 3. REGISTER READ STAGE
            // Shows what registers are being read and the immediate moving forward
            $display("[RR] Valid: %b | Src1(Reg%0d): %h | Src2(Reg%0d): %h | Imm: %h", 
                     uut.RR_valid, uut.RR_src1_idx, uut.RR_rdata1, 
                     uut.RR_src2_idx, uut.RR_rdata2, uut.RR_imm);

            // 4. EXECUTE STAGE
            // Shows the operands entering the ALU and the result coming out
            $display("[EX] Valid: %b | Op1: %h | Op2: %h | Result: %h", 
                     uut.E_valid, uut.E_src1, uut.E_src2, uut.E_result);

            // 5. WRITEBACK STAGE
            $display("[WB] Valid: %b | Write Reg: %0d | Final Data: %h", 
                     uut.WB_valid, uut.WB_dst_idx, uut.WB_result);
            
            // --- CHECK FOR SUCCESS ---
            if (uut.WB_valid && debug_result == 32'hDEADBEEF) begin
                $display("\n**********************************************************");
                $display(" SUCCESS: DEADBEEF detected at Writeback at time %0t!", $time);
                $display("**********************************************************");
                $finish; 
            end
            
            $display(""); // Empty line for readability
        end
        
        // Timeout
        $display("\nFAILURE: Simulation timed out. DEADBEEF never reached Writeback.");
        $finish;
    end

endmodule