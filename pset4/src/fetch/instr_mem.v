`timescale 1ns / 1ps
module instr_mem #(parameter MEMFILE = "deptest.hex") (
    input wire [31:0] pc,
    output wire [39:0] instr //5 byte instruction
);

    //Byte Addressable Memory
    reg [7:0] mem[0:511]; //512 bytes (50 total bytes * 8 = 400, 512 enough)

    //Load Hex File
    initial begin 
        $readmemh(MEMFILE, mem); 
    end

    //Little Endian First Instruction Fetch
    assign instr = {mem[pc + 4], mem[pc + 3], mem[pc + 2], mem[pc + 1], mem[pc + 0]};
endmodule