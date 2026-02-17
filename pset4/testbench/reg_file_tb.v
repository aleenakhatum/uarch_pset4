`timescale 1ns / 1ps

module reg_file_tb;

    // 1. Declare signals
    reg         clk;
    reg         set;
    reg         rst;
    reg         we;
    reg  [2:0]  src1_idx;
    reg  [2:0]  src2_idx;
    reg  [2:0]  dst_idx;
    reg  [31:0] w_val;
    
    wire [31:0] regfile_out1;
    wire [31:0] regfile_out2;

    // 2. Instantiate the Unit Under Test (UUT)
    reg_file uut (
        .clk(clk),
        .set(set),
        .rst(rst),
        .we(we),
        .src1_idx(src1_idx),
        .src2_idx(src2_idx),
        .dst_idx(dst_idx),
        .w_val(w_val),
        .regfile_out1(regfile_out1),
        .regfile_out2(regfile_out2)
    );

    // 3. Clock Generation
    always #5 clk = ~clk;

    // Variables
    integer errors;

    // 4. Test Logic
    initial begin
        $dumpfile("reg_file.vcd");
        $dumpvars(0, reg_file_tb);

        // Init
        errors = 0;
        clk = 0; set = 0; rst = 0; we = 0;
        src1_idx = 0; src2_idx = 0; dst_idx = 0; w_val = 0;

        $display("---------------------------------------------------");
        $display("Starting Testbench for Register File (EAX/ECX)...");
        $display("---------------------------------------------------");

        // --- Test 1: Reset ---
        rst = 1; #1; 
        // Read both ports (Index 0 and 1) to ensure they are 0
        src1_idx = 0; src2_idx = 1; #1;
        check_read(32'h0, 32'h0, "Reset Check");
        rst = 0; #10;


        // --- Test 2: Write to EAX (Index 0) ---
        $display("Writing 0xDEADBEEF to EAX (Index 0)...");
        dst_idx = 3'b000; // EAX
        w_val   = 32'hDEADBEEF;
        we      = 1;
        
        @(posedge clk); #1; // Trigger write
        we = 0; // Turn off WE
        
        // Verify Read: Port 1 reads EAX (0), Port 2 reads ECX (1)
        src1_idx = 3'b000; 
        src2_idx = 3'b001;
        #1;
        check_read(32'hDEADBEEF, 32'h00000000, "Write EAX");


        // --- Test 3: Write to ECX (Index 1) ---
        $display("Writing 0xCAFEBABE to ECX (Index 1)...");
        dst_idx = 3'b001; // ECX
        w_val   = 32'hCAFEBABE;
        we      = 1;
        
        @(posedge clk); #1;
        we = 0;
        
        // Verify Read: Port 1 reads EAX (0), Port 2 reads ECX (1)
        // EAX should still be DEADBEEF
        check_read(32'hDEADBEEF, 32'hCAFEBABE, "Write ECX");


        // --- Test 4: Dual Read (Both reading same reg) ---
        $display("Reading ECX on BOTH ports...");
        src1_idx = 3'b001;
        src2_idx = 3'b001;
        #1;
        check_read(32'hCAFEBABE, 32'hCAFEBABE, "Dual Read ECX");


        // --- Test 5: Write Disable Check ---
        $display("Attempting write with WE=0 (Should Fail)...");
        dst_idx = 3'b000; // Try to overwrite EAX
        w_val   = 32'hBADF00D5;
        we      = 0;      // Disable Write
        
        @(posedge clk); #1;
        
        // Read back EAX. It should still be DEADBEEF.
        src1_idx = 3'b000;
        src2_idx = 3'b001; 
        #1;
        check_read(32'hDEADBEEF, 32'hCAFEBABE, "Write Protect");


        // --- Final Report ---
        $display("---------------------------------------------------");
        if (errors == 0) $display("TEST PASSED: Register File Verified!");
        else $display("TEST FAILED: Found %0d errors.", errors);
        $display("---------------------------------------------------");
        $finish;
    end

    // Helper Task
    task check_read;
        input [31:0] exp_out1;
        input [31:0] exp_out2;
        input [20*8:1] test_name;
        begin
            if (regfile_out1 !== exp_out1 || regfile_out2 !== exp_out2) begin
                $display("[ERROR] %s Failed!", test_name);
                $display("        Expected: Out1=%h, Out2=%h", exp_out1, exp_out2);
                $display("        Got:      Out1=%h, Out2=%h", regfile_out1, regfile_out2);
                errors = errors + 1;
            end else begin
                // Uncomment to see passes
                // $display("[PASS]  %s", test_name);
            end
        end
    endtask

endmodule