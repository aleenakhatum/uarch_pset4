module register_read_stage(
    input wire clk,
    input wire set,
    input wire rst,
    input wire [6:0] ctrl,
    input wire [31:0] imm,
    input wire [2:0] src1_idx,
    input wire [2:0] src2_idx,
    input wire we, //signal from WB stage
    input wire [31:0] wdata, //signal from WB stage
    input wire [2:0] widx, //signal from WB stage
    
    output wire [31:0] reg1_read, //src1
    output wire [31:0] reg2_read //src2
);  

    wire [31:0] reg2_read_out;
    reg_file REGFILE(
        .clk(clk),
        .set(set), 
        .rst(rst), 
        .we(we),
        .src1_idx(src1_idx),
        .src2_idx(src2_idx),
        .dst_idx(widx), 
        .w_val(wdata),
        .regfile_out1(reg1_read),
        .regfile_out2(reg2_read_out)
    );

    mux2_32 IMMorREG(
        .IN0(reg2_read_out), //regread
        .IN1(imm), //immedaite
        .S0(ctrl[6]), //SRC2.MUX signal
        .Y(reg2_read)
    );

endmodule