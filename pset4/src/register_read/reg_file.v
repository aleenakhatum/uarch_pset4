module reg_file (
    input clk,
    input set, 
    input rst, 
    input we,
    input [2:0] src1_idx,
    input [2:0] src2_idx,
    input [2:0] dst_idx, 
    input [31:0] w_val,
    output [31:0] regfile_out1,
    output [31:0] regfile_out2
);

    //Generate WE signal for the register
    wire [1:0] SEL;
    wire [3:0] reg_sel; //one hot
    assign SEL = dst_idx[1:0];
    decoder2_4$ d1(.SEL(SEL), .Y(reg_sel), .YBAR());
    
    wire enable_eax, enable_ecx; //write enable reg signal
    and2$ a1(enable_eax, we, reg_sel[0]);
    and2$ a2(enable_ecx, we, reg_sel[1]);

    //Instantiate EAX and ECX regs
    wire [31:0] eax_out;
    wire [31:0] ecx_out;
    reg32 EAX(
        .clk(clk),
        .set(set),
        .rst(rst),
        .wdata(w_val), 
        .we(enable_eax),
        .rdata(eax_out)
    );

    reg32 ECX(
        .clk(clk),
        .set(set),
        .rst(rst),
        .wdata(w_val), 
        .we(enable_ecx),
        .rdata(ecx_out)
    );

    //Choose Read Port0 Output
    wire [31:0] out1, out2; //final output wire
    wire SEL1;
    assign SEL1 = src1_idx[0];
    mux2_32 m1(
        .Y(out1),
        .IN0(eax_out),
        .IN1(ecx_out),
        .S0(SEL1)        
    );
    
    //Chood Read Port1 Output
    wire SEL2;
    assign SEL2 = src2_idx[0];
    mux2_32 m2(
        .Y(out2),
        .IN0(eax_out),
        .IN1(ecx_out),
        .S0(SEL2)        
    );

    //Final Outputs
    assign regfile_out1 = out1;
    assign regfile_out2 = out2;

endmodule