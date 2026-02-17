module adder32(
    input wire [31:0] src1,
    input wire [31:0] src2,
    output wire [31:0] result
);

    wire [8:0] carry; 
    assign carry[0] = 1'b0; // Initial Carry In is 0 for simple addition

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : stage
            alu4$ alu_slice (
                .a(src1[i*4 +: 4]),   // Selects 4 bits: [3:0], [7:4], etc.
                .b(src2[i*4 +: 4]),
                .cin(carry[i]),       // Input Carry from previous stage
                .m(1'b1),             // Arithmetic Mode
                .s(4'd9),             // ADD Operation
                .cout(carry[i+1]),    // Output Carry to next stage
                .out(result[i*4 +: 4])
            );
        end
    endgenerate
endmodule