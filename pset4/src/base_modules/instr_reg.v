module instr_reg(
    input wire clk,
    input wire set,
    input wire rst,
    input wire [39:0] wdata, //four byte
    input wire we, //write enable
    output wire [39:0] rdata
);

    reg32 msb_4bytes(
        .clk(clk),
        .set(set),
        .rst(rst),
        .wdata(wdata[39:8]), //four byte
        .we(we), //write enable
        .rdata(rdata[39:8])
    );

    reg8 lsb_1byte(
        .clk(clk),
        .set(set),
        .rst(rst),
        .wdata(wdata[7:0]), //four byte
        .we(we), //write enable
        .rdata(rdata[7:0])
    );

endmodule