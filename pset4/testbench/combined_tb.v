`timescale 1ns / 1ps

module combined_tb;

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

    // --- MAIN TEST SEQUENCE ---
    initial begin
        $dumpfile("combined_test.vcd");
        $dumpvars(0, combined_tb);
        
        clk = 0;

        #1;

        // ==========================================================
        // TEST 1: DATA HAZARDS (deptest)
        // ==========================================================
        run_test("testbench/deptest.hex", "DATA HAZARD TEST", 32'h12341233);

        // ==========================================================
        // TEST 2: CONTROL FLOW (ctrlflow)
        // ==========================================================
        run_test("testbench/ctrlflow.hex", "CONTROL FLOW TEST", 32'h12341235);

        $display("\n##########################################################");
        $display(" ALL TESTS PASSED SUCCESSFULLY");
        $display("##########################################################");
        $finish;
    end

    // --- TASK: RUN A SINGLE TEST ---
    task run_test(input [1023:0] hex_file, input [255:0] test_name, input [31:0] expected_eax);
        integer i;
        begin
            $display("\n==========================================================");
            $display(" STARTING: %0s", test_name);
            $display(" Loading Memory from: %0s", hex_file);
            $display("==========================================================");

            // 1. RELOAD MEMORY (Overwrites previous program)
            // Note: We target the memory array inside your instance hierarchy
            $readmemh(hex_file, uut.FETCH.imem.mem);

            // 2. RESET PIPELINE
            rst = 1;
            #50;
            rst = 0;

            // 3. RUN SIMULATION LOOP
            // We give it 50 cycles max to finish
            for (i = 0; i < 50; i = i + 1) begin
                @(posedge clk);
                #1; // Wait for logic

                // Print Status
                $display("T:%2t | PC:%h | IF:%h | ID:%h | EX_Valid:%b | WB_Valid:%b | EAX:%h", 
                         $time, debug_pc, uut.F_instr, uut.D_instr, uut.E_valid, uut.WB_valid, uut.REGISTERS.EAX.rdata);

                // TRAP CHECK (Specific to CtrlFlow)
                if (uut.REGISTERS.EAX.rdata == 32'hFADEDACE) begin
                    $display("\nFAILURE: Trap instruction executed!");
                    $finish;
                end

                // SUCCESS CHECK
                if (uut.WB_valid && uut.WB_result == expected_eax) begin
                    $display("\n*** SUCCESS: %0s Passed! EAX = %h ***", test_name, uut.WB_result);
                    disable run_test; // Exit the task immediately
                end
            end

            // TIMEOUT CHECK
            $display("\nFAILURE: %0s Timed out! Never reached expected result.", test_name);
            $finish;
        end
    endtask

endmodule