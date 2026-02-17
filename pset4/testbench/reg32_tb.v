`timescale 1ns / 1ps

module reg32_tb;

    // 1. Declare signals
    reg         clk;
    reg         set;
    reg         rst;
    reg  [31:0] wdata;
    reg         we;
    wire [31:0] rdata;

    // 2. Instantiate the Unit Under Test (UUT)
    reg32 uut (
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
    reg [31:0] shadow_register; // To track expected value
    integer errors;

    // 4. Test Logic
    initial begin
        // --- Setup Waveform Dumping ---
        $dumpfile("reg32.vcd");
        $dumpvars(0, reg32_tb);

        // Initialize Inputs
        errors = 0;
        clk = 0;
        set = 0;
        rst = 0;
        we  = 0;
        wdata = 32'h00000000;
        shadow_register = 32'h00000000;

        $display("---------------------------------------------------");
        $display("Starting Testbench for reg32...");
        $display("---------------------------------------------------");

        // --- TEST CASE 1: Asynchronous Reset ---
        // Expecting all 0s
        rst = 1; 
        #1; // Async check
        check_output(32'h00000000);
        
        rst = 0; 
        #10;

        // --- TEST CASE 2: Write Enable (Loading Data) ---
        // Writing DEADBEEF
        wdata = 32'hDEADBEEF;
        we    = 1;
        
        @(posedge clk); 
        #1; // Wait for propagation
        
        check_output(32'hDEADBEEF); 
        shadow_register = 32'hDEADBEEF;


        // --- TEST CASE 3: Write Disable (Hold Value) ---
        // Try writing CAFEBABE, but with WE=0. Should stay DEADBEEF.
        wdata = 32'hCAFEBABE;
        we    = 0; 
        
        @(posedge clk);
        #1; 
        
        check_output(32'hDEADBEEF); // Should verify it held the old value


        // --- TEST CASE 4: Asynchronous Set ---
        // Expecting all 1s (FFFFFFFF)
        set = 1; 
        #1;      
        check_output(32'hFFFFFFFF);
        
        set = 0; 
        shadow_register = 32'hFFFFFFFF; 
        #10;

        // --- TEST CASE 5: Randomized Testing ---
        $display("Running 10 Random Vectors...");
        
        for (i = 0; i < 10; i = i + 1) begin
            // Generate Random Inputs
            wdata = $random;
            we    = $random % 2; // Randomly 0 or 1

            // Update Shadow Register
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
        input [31:0] expected_val;
        begin
            if (rdata !== expected_val) begin
                $display("[ERROR] Time=%0t | we=%b | rst=%b | set=%b | Output=%h | Expected=%h", 
                         $time, we, rst, set, rdata, expected_val);
                errors = errors + 1;
            end else begin
                // --- UNCOMMENT THE LINE BELOW TO SEE EVERY PASS ---
                // $display("[PASS]  Time=%0t | Output=%h", $time, rdata);
            end
        end
    endtask

endmodule