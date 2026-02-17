`timescale 1ns / 1ps

module instr_reg_tb;

    // 1. Declare signals
    reg         clk;
    reg         set;
    reg         rst;
    reg  [39:0] wdata;
    reg         we;
    wire [39:0] rdata;

    // 2. Instantiate the Unit Under Test (UUT)
    instr_reg uut (
        .clk(clk),
        .set(set),
        .rst(rst),
        .wdata(wdata),
        .we(we),
        .rdata(rdata)
    );

    // 3. Clock Generation (Period = 10ns)
    always #5 clk = ~clk;

    // Variables for testing
    integer i;
    reg [39:0] shadow_register; // To track expected value (40 bits)
    integer errors;

    // 4. Test Logic
    initial begin
        // --- Setup Waveform Dumping ---
        $dumpfile("instr_reg.vcd");
        $dumpvars(0, instr_reg_tb);

        // Initialize Inputs
        errors = 0;
        clk = 0;
        set = 0;
        rst = 0;
        we  = 0;
        wdata = 40'h0000000000;
        shadow_register = 40'h0000000000;

        $display("---------------------------------------------------");
        $display("Starting Testbench for instr_reg (40-bit)...");
        $display("---------------------------------------------------");

        // --- TEST CASE 1: Asynchronous Reset ---
        // Expecting all 0s
        rst = 1; 
        #1; // Async check
        check_output(40'h0000000000);
        
        rst = 0; 
        #10;

        // --- TEST CASE 2: Write Enable (Loading Data) ---
        // Writing a 40-bit pattern: AABBCCDDEE
        wdata = 40'hAABBCCDDEE;
        we    = 1;
        
        @(posedge clk); 
        #1; // Wait for propagation
        
        check_output(40'hAABBCCDDEE); 
        shadow_register = 40'hAABBCCDDEE;


        // --- TEST CASE 3: Write Disable (Hold Value) ---
        // Try writing 1122334455, but with WE=0. Should stay AABBCCDDEE.
        wdata = 40'h1122334455;
        we    = 0; 
        
        @(posedge clk);
        #1; 
        
        check_output(40'hAABBCCDDEE); 


        // --- TEST CASE 4: Asynchronous Set ---
        // Expecting all 1s (FFFFFFFFFF)
        set = 1; 
        #1;      
        check_output(40'hFFFFFFFFFF);
        
        set = 0; 
        shadow_register = 40'hFFFFFFFFFF; 
        #10;

        // --- TEST CASE 5: Randomized Testing ---
        $display("Running 10 Random Vectors...");
        
        for (i = 0; i < 10; i = i + 1) begin
            // Generate Random Inputs (40 bits)
            // $random is only 32 bits, so we concat two calls to fill 40 bits.
            wdata = { $random, $random }; 
            we    = $random % 2; 

            // Update Shadow Register
            if (we) begin
                shadow_register = wdata;
            end 

            // Wait for Clock Edge
            @(posedge clk);
            #1; 

            // Check
            check_output(shadow_register);
        end

        // --- Final Report ---
        $display("---------------------------------------------------");
        if (errors == 0) begin
            $display("TEST PASSED: All checks matched successfully!");
        end else begin
            $display("TEST FAILED: Found %0d errors.", errors);
        end
        $display("---------------------------------------------------");
        
        $finish;
    end

    // 5. Self-Checking Task
    task check_output;
        input [39:0] expected_val;
        begin
            if (rdata !== expected_val) begin
                $display("[ERROR] Time=%0t | we=%b | Output=%h | Expected=%h", 
                         $time, we, rdata, expected_val);
                errors = errors + 1;
            end else begin
                // Uncomment to see every pass
                // $display("[PASS]  Time=%0t | Output=%h", $time, rdata);
            end
        end
    endtask

endmodule