`timescale 1ns / 1ps

module comp3_tb;

    // 1. Inputs
    reg [2:0] a;
    reg [2:0] b;

    // 2. Outputs
    wire eq;

    // 3. Instantiate UUT
    comp3 uut (
        .a(a), 
        .b(b), 
        .eq(eq)
    );

    integer i, j;
    integer errors;

    // 4. Test Logic
    initial begin
        $dumpfile("comp3.vcd");
        $dumpvars(0, comp3_tb);

        a = 0; b = 0;
        errors = 0;

        $display("---------------------------------------------------");
        $display("Starting 3-bit Comparator Test...");
        $display("---------------------------------------------------");

        // Loop through ALL possible values for A (0-7) and B (0-7)
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                
                a = i[2:0];
                b = j[2:0];
                
                #1; // Wait for logic

                // Check Logic: 
                // If i == j, eq must be 1.
                // If i != j, eq must be 0.
                if ( (i == j && eq !== 1) || (i !== j && eq !== 0) ) begin
                    $display("[FAIL] A=%b (%0d), B=%b (%0d). Got Eq=%b", a, i, b, j, eq);
                    errors = errors + 1;
                end 
            end
        end

        // --- Summary ---
        $display("---------------------------------------------------");
        if (errors == 0) $display("ALL TESTS PASSED: Checked all 64 combinations.");
        else $display("TEST FAILED: Found %0d errors.", errors);
        $display("---------------------------------------------------");
        $finish;
    end

endmodule