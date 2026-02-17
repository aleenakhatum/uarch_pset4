module id_rr_pr(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire flush,

    input wire [2:0] instr_length_in,
    input wire [31:0] pc_in,
    input wire [6:0] ctrl_in,
    input wire [2:0] src1_idx_in,
    input wire [2:0] src2_idx_in,
    input wire [31:0] imm_in,
    input wire valid_in,

    output wire [31:0] pc_out,
    output wire [6:0] ctrl_out,
    output wire [2:0] dst_idx,
    output wire [2:0] src1_idx_out,
    output wire [2:0] src2_idx_out,
    output wire [31:0] imm_out,
    output wire valid_out,
    output wire [2:0] instr_length_out
);

    wire we;
    inv1$ inv_stall (.out(we), .in(stall));

    wire rst_sig;
    or2$ or_flush (.out(rst_sig), .in0(rst), .in1(flush));

    wire rst_bar;
    inv1$ inv_rst(.out(rst_bar), .in(rst_sig));

    reg32 pc_reg (
        .clk(clk),
        .set(1'b0),
        .rst(rst_sig),
        .wdata(pc_in),
        .we(we), 
        .rdata(pc_out)
    );

    reg32 imm_reg (
        .clk(clk),
        .set(1'b0),
        .rst(rst_sig),
        .wdata(imm_in),
        .we(we), 
        .rdata(imm_out)
    );

    genvar i;

    //Ctrl
    generate
        for (i = 0; i < 7; i = i + 1) begin : ctrl_loop
            wire d_in;
            // Mux: If WE=1 (s0=1), take Input (in1). If WE=0, keep Output/Loopback (in0).
            // Assuming strict mapping: in0=OldValue, in1=NewValue, s0=WE
            mux2$ m (.outb(d_in), .in0(ctrl_out[i]), .in1(ctrl_in[i]), .s0(we));
            dff$ ff (.clk(clk), .d(d_in), .q(ctrl_out[i]), .qbar(), .r(rst_bar), .s(1'b1));
        end
    endgenerate

    //src1_idx and dst_idx
    generate
        for (i = 0; i < 3; i = i + 1) begin : src1_loop
            wire d_in;
            mux2$ m (.outb(d_in), .in0(src1_idx_out[i]), .in1(src1_idx_in[i]), .s0(we));
            dff$ ff (.clk(clk), .d(d_in), .q(src1_idx_out[i]), .qbar(), .r(rst_bar), .s(1'b1));
        end
    endgenerate
    assign dst_idx = src1_idx_out;

    generate
        for (i = 0; i < 3; i = i + 1) begin : src2_loop
            wire d_in;
            mux2$ m (.outb(d_in), .in0(src2_idx_out[i]), .in1(src2_idx_in[i]), .s0(we));
            dff$ ff (.clk(clk), .d(d_in), .q(src2_idx_out[i]), .qbar(), .r(rst_bar), .s(1'b1));
        end
    endgenerate

    //instr_length
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