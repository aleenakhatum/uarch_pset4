module if_id_pr(
    input wire clk,
    input wire rst,
    input wire stall, //keep old values
    input wire flush, //set as invalid

    //inputs to fetch
    input wire [39:0] instr_in,
    input wire [31:0] pc_in,
    input wire [2:0] instr_length_in,
    
    //output from fetch to decode
    output wire [39:0] instr_out,
    output wire [31:0] pc_out,
    output wire valid_out,
    output wire [2:0] instr_length_out
);

    //Save Values into Pipeline Register
    wire pc_we;
    inv1$ stall_inv (.out(pc_we), .in(stall));
    wire rst_sig;
    or2$ rst_flush_or(.out(rst_sig), .in0(rst), .in1(flush));
    reg32 pc_reg (
        .clk(clk),
        .set(1'b0),
        .rst(rst_sig),
        .wdata(pc_in),
        .we(pc_we), 
        .rdata(pc_out)
    );

    instr_reg instrreg(
        .clk(clk),
        .set(1'b0),
        .rst(rst_sig),
        .wdata(instr_in),
        .we(pc_we), 
        .rdata(instr_out)
    );

    wire valid_next;
    wire rst_bar;
    wire set_bar;
    inv1$ i1(.out(rst_bar), .in(rst_sig));
    inv1$ i2(.out(set_bar), .in(1'b0));

    mux2$ valid_mux (
        .outb(valid_next),
        .in0(valid_out),
        .in1(1'b1), //allowing a write makes new data valid
        .s0(pc_we)
    );

    dff$ valid_bit (
        .clk(clk),
        .d(valid_next),
        .q(valid_out),
        .qbar(),         // Unused
        .r(rst_bar), // Force to 0 if Flush/Reset
        .s(set_bar)
    );

    genvar i;
    generate
        for (i = 0; i < 3; i = i + 1) begin : len_loop
            wire d_in, mux_out_b;
            mux2$ m (.outb(mux_out_b), .in0(instr_length_out[i]), .in1(instr_length_in[i]), .s0(pc_we));
            inv1$ inv (.out(d_in), .in(mux_out_b));
            
            dff$ ff (.clk(clk), .d(d_in), .q(instr_length_out[i]), .qbar(), .r(rst_bar), .s(1'b1));
        end
    endgenerate

endmodule