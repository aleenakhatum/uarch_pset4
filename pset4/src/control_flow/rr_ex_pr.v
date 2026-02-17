module rr_ex_pr(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire flush,

    input wire [2:0] instr_length_in,
    input wire [31:0] pc_in,
    input wire [6:0] ctrl_in,
    input wire [2:0] dst_idx_in,
    input wire [31:0] src1_in,
    input wire [31:0] src2_in,
    input wire valid_in,

    output wire [31:0] pc_out,
    output wire [6:0] ctrl_out,
    output wire [2:0] dst_idx_out,
    output wire [31:0] src1_out,
    output wire [31:0] src2_out,
    output wire valid_out,
    output wire [2:0] instr_length_out
);

    wire we;
    inv1$ inv_stall (.out(we), .in(stall));

    wire rst_sig;
    or2$ or_flush (.out(rst_sig), .in0(rst), .in1(flush)); // Active High (For reg32)

    wire rst_bar;
    inv1$ inv_rst (.out(rst_bar), .in(rst_sig)); // Active Low (For dff$)


    reg32 pc_reg (
        .clk(clk), 
        .set(1'b0), 
        .rst(rst_sig),
        .wdata(pc_in), 
        .we(we), 
        .rdata(pc_out)
    );

    reg32 src1_reg (
        .clk(clk), 
        .set(1'b0), 
        .rst(rst_sig),
        .wdata(src1_in), 
        .we(we), 
        .rdata(src1_out)
    );

    reg32 src2_reg (
        .clk(clk), 
        .set(1'b0), 
        .rst(rst_sig),
        .wdata(src2_in), 
        .we(we), 
        .rdata(src2_out)
    );


    // ctrl
    genvar i;
    generate
        for (i = 0; i < 7; i = i + 1) begin : ctrl_loop
            wire d_in;
            mux2$ m (.outb(d_in), .in0(ctrl_out[i]), .in1(ctrl_in[i]), .s0(we));
            dff$ ff (.clk(clk), .d(d_in), .q(ctrl_out[i]), .qbar(), .r(rst_bar), .s(1'b1));
        end
    endgenerate

    // dstidx
    generate
        for (i = 0; i < 3; i = i + 1) begin : dst_loop
            wire d_in;
            mux2$ m (.outb(d_in), .in0(dst_idx_out[i]), .in1(dst_idx_in[i]), .s0(we));
            dff$ ff (.clk(clk), .d(d_in), .q(dst_idx_out[i]), .qbar(), .r(rst_bar), .s(1'b1));
        end
    endgenerate

    //instrlen
    generate
        for (i = 0; i < 3; i = i + 1) begin : len_loop
            wire d_in;
            mux2$ m (.outb(d_in), .in0(instr_length_out[i]), .in1(instr_length_in[i]), .s0(we));
            dff$ ff (.clk(clk), .d(d_in), .q(instr_length_out[i]), .qbar(), .r(rst_bar), .s(1'b1));
        end
    endgenerate


    // valid bit
    wire valid_next;
    mux2$ valid_mux (.outb(valid_next), .in0(valid_out), .in1(valid_in), .s0(we));
    
    dff$ valid_reg (
        .clk(clk), 
        .d(valid_next), 
        .q(valid_out), 
        .qbar(), 
        .r(rst_bar), 
        .s(1'b1) 
    );

endmodule