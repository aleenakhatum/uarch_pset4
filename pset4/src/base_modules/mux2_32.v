`timescale 1ns / 1ps
module mux2_32(
    input [31:0] IN0,
    input [31:0] IN1,
    input S0,
    output [31:0] Y
);

    wire [15:0] Y_lsb, Y_msb;
    wire [15:0] IN0_lsb, IN0_msb;
    wire [15:0] IN1_lsb, IN1_msb;
    assign IN0_lsb = IN0[15:0];
    assign IN0_msb = IN0[31:16];
    assign IN1_lsb = IN1[15:0];
    assign IN1_msb = IN1[31:16];
    mux2_16$ lsb(
        .Y(Y_lsb),
        .IN0(IN0_lsb),
        .IN1(IN1_lsb),
        .S0(S0)
    );

    mux2_16$ msb(
        .Y(Y_msb),
        .IN0(IN0_msb),
        .IN1(IN1_msb),
        .S0(S0)
    );

    assign Y = {Y_msb, Y_lsb};
endmodule