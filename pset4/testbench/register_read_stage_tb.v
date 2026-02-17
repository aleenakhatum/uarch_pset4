`timescale 1ns / 1ps

module register_read_stage_tb;

    reg        clk;
    reg        set;
    reg        rst;
    reg [6:0]  ctrl;
    reg [31:0] imm;
    reg [2:0]  src1_idx;
    reg [2:0]  src2_idx;
    reg        we;
    reg [31:0] wdata;
    reg [2:0]  widx;

    wire [31:0] reg1_read;
    wire [31:0] reg2_read;

    register_read_stage uut (
        .clk(clk),
        .set(set),
        .rst(rst),
        .ctrl(ctrl),
        .imm(imm),
        .src1_idx(src1_idx),
        .src2_idx(src2_idx),
        .we(we),
        .wdata(wdata),
        .widx(widx),
        .reg1_read(reg1_read),
        .reg2_read(reg2_read)
    );

    always #5 clk = ~clk;
    integer errors;

    initial begin
        $dumpfile("register_read_stage.vcd");
        $dumpvars(0, register_read_stage_tb);

        clk = 0; rst = 0; set = 0;
        ctrl = 0; imm = 0;
        src1_idx = 0; src2_idx = 0;
        we = 0; wdata = 0; widx = 0;
        errors = 0;

        $display("---------------------------------------------------");
        $display("Starting Register Read Stage Test (2-Reg Mode)");
        $display("---------------------------------------------------");

        // --- TEST 1: Reset ---
        rst = 1; #10; rst = 0; #10;

        // --- TEST 2: Write Data ---
        
        // Write 0xAAAA to Reg 0 (EAX)
        @(posedge clk);
        we = 1; widx = 3'd0; wdata = 32'hAAAA_AAAA;
        #1; 
        
        // Write 0xBBBB to Reg 1 (ECX)
        @(posedge clk);
        we = 1; widx = 3'd1; wdata = 32'hBBBB_BBBB;
        #1;

        @(posedge clk);
        we = 0; // Turn off write

        // --- TEST 3: Read Registers (Mux selects REG) ---
        // Read Reg 0 (EAX) and Reg 1 (ECX)
        src1_idx = 3'd0; 
        src2_idx = 3'd1;
        ctrl     = 7'b0000000; // Bit 6 = 0 (Select Reg)
        imm      = 32'hDEADBEEF; 
        
        #10; 

        if (reg1_read !== 32'hAAAA_AAAA) begin
             $display("[FAIL] Reg1 (Idx 0) Mismatch. Exp AAAA.., Got %h", reg1_read);
             errors = errors + 1;
        end
        
        if (reg2_read !== 32'hBBBB_BBBB) begin
             $display("[FAIL] Reg2 (Idx 1) Mismatch. Exp BBBB.., Got %h", reg2_read);
             errors = errors + 1;
        end else begin
             $display("[PASS] Register Read Mode Verified.");
        end


        // --- TEST 4: Immediate Override (Mux selects IMM) ---
        // Setup: Read Reg 0, but override Reg 1 with Immediate.
        ctrl     = 7'b1000000; // Bit 6 = 1 (Select Immediate)
        imm      = 32'hCAFEBABE;
        
        #10; 

        // Reg 1 (Index 0) should still be valid
        if (reg1_read !== 32'hAAAA_AAAA) begin
             $display("[FAIL] Reg1 should stay stable. Got %h", reg1_read);
             errors = errors + 1;
        end

        // Reg 2 Output should be IMMEDIATE
        if (reg2_read !== 32'hCAFEBABE) begin
             $display("[FAIL] Mux failed to select Immediate. Exp CAFE.., Got %h", reg2_read);
             errors = errors + 1;
        end else begin
             $display("[PASS] Immediate Select Mode Verified.");
        end

        $display("---------------------------------------------------");
        if (errors == 0) $display("ALL TESTS PASSED.");
        else $display("TEST FAILED: Found %0d errors.", errors);
        $display("---------------------------------------------------");
        $finish;
    end
endmodule