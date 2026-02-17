module reg32(
    input wire clk,
    input wire set,
    input wire rst,
    input wire [31:0] wdata, //four byte
    input wire we, //write enable
    output wire [31:0] rdata
);

    wire [31:0] qbar; //unused
    wire setbar;
    wire rstbar;
    inv1$ i1(setbar, set);
    inv1$ i2(rstbar, rst);

    wire [31:0] candidate_input;
    mux2_32 m1(.Y(candidate_input), .IN0(rdata), .IN1(wdata), .S0(we));

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin: bit_reg
            dff$ ff(
                .clk(clk),
                .d(candidate_input[i]),
                .q(rdata[i]),
                .qbar(qbar[i]),
                .r(rstbar),
                .s(setbar)
            );
        end
    endgenerate

endmodule