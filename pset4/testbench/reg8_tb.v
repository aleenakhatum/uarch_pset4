`timescale 1ns / 1ps

module reg8_tb;

    // 1. Declare signals
    reg        clk;
    reg        set;
    reg        rst;
    reg  [7:0] wdata;
    reg        we;
    wire [7:0] rdata;

    // 2. Instantiate the Unit Under Test (UUT)
    reg8 uut (
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
    reg [7:0] shadow_register; // To track expected value
    integer errors;

    // 4. Test Logic
    initial begin
        // --- Setup Waveform Dumping ---
        $dumpfile("reg8.vcd");
        $dumpvars(0, reg8_tb);

        // Initialize Inputs
        errors = 0;
        clk = 0;
        set = 0;
        rst = 0;
        we  = 0;
        wdata = 8'h00;
        shadow_register = 8'h00; // Expected value starts at 0

        $display("---------------------------------------------------");
        $display("Starting Testbench for reg8...");
        $display("---------------------------------------------------");

        // --- TEST CASE 1: Asynchronous Reset ---
        rst = 1; // Assert Reset
        #1;      // Check immediately (async)
        check_output(8'h00);
        
        rst = 0; // Release Reset
        #10;

        // --- TEST CASE 2: Write Enable (Loading Data) ---
        wdata = 8'hAA;
        we    = 1;
        
        @(posedge clk); 
        #1; // Wait for propagation
        
        check_output(8'hAA); 
        shadow_register = 8'hAA; // Update our expectation


        // --- TEST CASE 3: Write Disable (Hold Value) ---
        wdata = 8'h55;
        we    = 0; // DISABLE write
        
        @(posedge clk);
        #1; 
        
        check_output(8'hAA); // Should STILL hold AA (Old Value)


        // --- TEST CASE 4: Asynchronous Set ---
        set = 1; // Assert Set
        #1;      
        check_output(8'hFF);
        
        set = 0; 
        shadow_register = 8'hFF; 
        #10;

        // --- TEST CASE 5: Randomized Testing ---
        //$display("Running 10 Random Vectors...");
        
        for (i = 0; i < 10; i = i + 1) begin
            // Generate Inputs
            wdata = $random;
            we    = $random % 2; // Randomly 0 or 1

            // Update Shadow Register (The "Gold Standard")
            if (we) begin
                shadow_register = wdata;
            end 
            // Else, shadow_register stays the same

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
        input [7:0] expected_val;
        begin
            if (rdata !== expected_val) begin
                $display("[ERROR] Time=%0t | we=%b | rst=%b | set=%b | Output=%h | Expected=%h", 
                         $time, we, rst, set, rdata, expected_val);
                errors = errors + 1;
            end else begin
                // --- UNCOMMENT THE LINE BELOW TO SEE EVERY PASS ---
                $display("[PASS]  Time=%0t | Output=%h", $time, rdata);
            end
        end
    endtask

endmodule