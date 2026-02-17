`timescale 1ns / 1ps

module mux2_32_tb;

    // 1. Declare signals
    reg  [31:0] IN0;
    reg  [31:0] IN1;
    reg         S0;
    wire [31:0] Y;

    // 2. Instantiate the Unit Under Test (UUT)
    mux2_32 uut (
        .IN0(IN0), 
        .IN1(IN1), 
        .S0(S0), 
        .Y(Y)
    );

    // Variables for the loop
    integer i;
    reg [31:0] expected_Y;
    integer errors;

    // 3. Test Logic
    initial begin
        // --- Setup Waveform Dumping ---
        $dumpfile("mux2_32.vcd"); // The file you open in GTKWave
        $dumpvars(0, mux2_32_tb); // Dump all variables in this module

        // Initialize
        errors = 0;
        $display("---------------------------------------------------");
        $display("Starting Testbench for mux2_32...");
        $display("---------------------------------------------------");

        // --- TEST CASE 1: Basic Selector Check ---
        // S0 = 0 -> Select IN0
        IN0 = 32'hAAAAAAAA;
        IN1 = 32'h55555555;
        S0  = 0;
        #10; // Wait 10ns for logic to settle
        check_output();

        // S0 = 1 -> Select IN1
        S0 = 1;
        #10;
        check_output();


        // --- TEST CASE 2: Randomized Testing ---
        $display("Running 10 Random Vectors...");
        for (i = 0; i < 10; i = i + 1) begin
            IN0 = $random;
            IN1 = $random;
            S0  = $random % 2; // Random 0 or 1
            #10;
            check_output();
        end

        // --- Final Report ---
        $display("---------------------------------------------------");
        if (errors == 0) begin
            $display("TEST PASSED: All vectors matched successfully!");
        end else begin
            $display("TEST FAILED: Found %0d errors.", errors);
        end
        $display("---------------------------------------------------");
        $finish; // Stop simulation
    end

    // 4. Self-Checking Task
    // This task calculates the 'expected' value and compares it to 'Y'
    task check_output;
        begin
            // Behavioral Model (The "Gold Standard" Logic)
            expected_Y = (S0) ? IN1 : IN0;

            if (Y !== expected_Y) begin
                $display("[ERROR] Time=%0t | S0=%b | IN0=%h | IN1=%h | Output Y=%h | Expected=%h", 
                         $time, S0, IN0, IN1, Y, expected_Y);
                errors = errors + 1;
            end else begin
                // Uncomment this if you want to see every successful check
                $display("[PASS]  Time=%0t | S0=%b | Y=%h", $time, S0, Y);
            end
        end
    endtask

endmodule