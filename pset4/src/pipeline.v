module pipeline(
    input wire clk,
    input wire rst, 

    //ONLY FOR DEBUG
    output wire [31:0] debug_pc_F,
    output wire [39:0] debug_instr_D
);

    //Control Signals
    wire F_stall = 1'b0;
    wire D_stall = 1'b0;
    wire D_flush = 1'b0;

    //Fetch Stage Wires
    wire [31:0] F_pc; //current pc
    wire [31:0] F_next_pc; //next pc (calculated) from execute
    wire [39:0] F_instr; //instruction fetched from memory

    //Decode Stage Wires
    //inputs to decode stage (from if_id_reg)
    wire [31:0] D_pc; 
    wire [39:0] D_instr;
    wire D_valid;

    //outputs of decode stage (to id_ie_reg)
    wire [31:0] D_imm;
    wire [2:0] D_src1_idx;
    wire [2:0] D_src2_idx;
    wire [6:0] D_ctrl;
    
    reg32 PC_REG(
        .clk(clk),
        .set(1'b0),
        .rst(rst),
        .wdata(F_next_pc), // Load the calculated Next PC
        .we(),              //TODO: Stall signal decides whether to we
        .rdata(F_pc)
    );

    fetch_stage FETCH(
        .clk(clk),
        .pc_we(),       //TODO: Stall signal decides whether to we
        .pc(F_pc),
        .jmp_target(),  //TODO jump target should come from decode?
        .is_jmp(),      //TODO jmp sig from decode
        .instr_length(),    // TODO: comes from decode stage
        .is_halt(),         //TODO comes from decode stage
        .instr(F_instr),
        .next_pc(F_next_pc)     // Output to the PC_REG input
    );

    //TODO
    if_id_pr IF_ID_REG (
        .clk(clk),
        .rst(rst),
        .stall(stall_D), // <--- STALL LOGIC HERE
        .flush(flush_D),
        
        // Inputs from Fetch
        .instr_in(F_instr),
        .pc_in(F_pc),
        
        // Outputs to Decode
        .instr_out(D_instr),
        .pc_out(D_pc),
        .valid_out(D_valid)
    );

    decode_stage DECODE(
        .pc(),
        .instr(),
        .imm(D_imm),
        .src1_idx(), //dst
        .src2_idx(), //src
        .ctrl(),
        .length()
    );

    id_rr_pr ID_RR_PR(
        .clk(clk),
        .rst(rst),
        .stall(),
        .flush(),

        .pc_in(),
        .ctrl_in(),
        .src1_idx(),
        .src2_idx(),
        .imm(),
        .valid_in(),

        .pc_out(),
        .ctrl_out(),
        .dst_idx(),
        .valid_out()
    );

    reg_file REGISTERS(
        .clk(clk),
        .set(1'b0), 
        .rst(rst), 
        .we(),
        .src1_idx(),  //r port idx
        .src2_idx(),  //r port idx
        .dst_idx(),  //w port idx
        .w_val(),
        .regfile_out1(), //output
        .regfile_out2()  //output
    );



endmodule