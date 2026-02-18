`timescale 1ns / 1ps

module pipeline_tb2;

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

    // 4. Main Simulation
    initial begin
        $dumpfile("pipeline_hex_test.vcd");
        $dumpvars(0, pipeline_tb2);

        // --- INITIALIZATION ---
        clk = 0; 
        rst = 1;
        
        force uut.PC_REG.rdata = 32'h0; 
        
        #50; 
        release uut.PC_REG.rdata;
        @(negedge clk);
        rst = 0;
        
        $display("\n==========================================================");
        $display("   STARTING HEX FILE SIMULATION");
        $display("==========================================================\n");

        // --- DETAILED PIPELINE TRACKING ---
        repeat (30) begin
            @(posedge clk);
            #1; // Wait for logic to settle

            $display("Time: %0t ns | PC: %h ------------------------------------", $time, debug_pc);
            
            // 1. FETCH
            $display("[IF] Raw Instr: %h", uut.F_instr);

            // 2. DECODE
            $display("[ID] Instr: %h | Stall_Glob: %b", uut.D_instr, uut.stall_global);

            // 3. REGISTER READ
            $display("[RR] Valid: %b | Src1_Idx: %d | Src2_Idx: %d | Imm: %h", 
                     uut.RR_valid, uut.RR_src1_idx, uut.RR_src2_idx, uut.RR_imm);
            $display("     Reg_Out1: %h | Reg_Out2: %h", uut.RR_rdata1, uut.RR_rdata2);

            // 4. EXECUTE
            $display("[EX] Valid: %b | ALUSrc1: %h | ALUSrc2: %h | ALURes: %h", 
                     uut.E_valid, uut.E_src1, uut.E_src2, uut.E_result);

            // 5. MEMORY
            $display("[MEM] Valid: %b | Dest_Idx: %d | MemRes: %h", 
                     uut.M_valid, uut.M_dst_idx, uut.M_result);

            // 6. WRITEBACK
            $display("[WB] Valid: %b | Dest_Idx: %d | FinalData: %h", 
                     uut.WB_valid, uut.WB_dst_idx, uut.WB_result);
            
            // --- 7. REGISTER FILE STATE ---
            // Note: This assumes your reg_file stores data in an array called 'regs'
            // If you used named registers, replace with: uut.REGISTERS.EAX.rdata, etc.
            // --- 7. REGISTER FILE STATE ---
            // Only printing the implemented registers to avoid XMRE errors
            // --- 7. REGISTER FILE STATE ---
            $display("[REG FILE] EAX (000): %h | ECX (001): %h", 
                    uut.REGISTERS.EAX.rdata, 
                    uut.REGISTERS.ECX.rdata);

            // Success Check
            if (uut.WB_valid && debug_result == 32'h12341233) begin
                $display("\n**********************************************************");
                $display(" SUCCESS: Final Result 12341233 reached Writeback!");
                $display("**********************************************************");
                $finish; 
            end
            
            $display("----------------------------------------------------------\n"); 
        end
        
        $display("\nFAILURE: Timed out waiting for 12341233.");
        $finish;
    end

endmodule