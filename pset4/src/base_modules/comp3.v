module comp3(
    input [2:0] a,
    input [2:0] b,
    output eq
);
    wire x0, x1, x2;
    xnor2$ xn0(.out(x0), .in0(a[0]), .in1(b[0]));
    xnor2$ xn1(.out(x1), .in1(a[1]), .in0(b[1])); // swapped pins ok
    xnor2$ xn2(.out(x2), .in0(a[2]), .in1(b[2]));
    
    wire x01;
    and2$ a0(.out(x01), .in0(x0), .in1(x1));
    and2$ a1(.out(eq),  .in0(x01), .in1(x2));
endmodule