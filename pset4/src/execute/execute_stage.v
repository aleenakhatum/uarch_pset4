module execute_stage(
    input wire [31:0] pc,
    input wire [31:0] instr_length,
    input wire [31:0] src1,
    input wire [31:0] src2,
    input wire [6:0] ctrl,
    output wire [31:0] result,
    output wire [31:0] jmp_target,
    output wire is_jmp,
    output wire is_halt
);

    wire [31:0] adder_result;
    wire [31:0] movres_or_jmptarget;
    wire [31:0] final_out;
    assign result = final_out;
    assign is_jmp = ctrl[1]; //JMP signal set by decode
    assign is_halt = ctrl[0]; //HALT signal set by decode

    //Arithmetic ALU
    adder32 ADDER(
        .src1(src1), 
        .src2(src2),
        .result(adder_result)
    );

    //Compute JMP Target
    wire [31:0] n_pc;
    adder32 JMP_TARGET_ADDER1(
        .src1(instr_length), 
        .src2(pc),
        .result(n_pc)
    );

    adder32 JMP_TARGET_ADDER2(
        .src1(n_pc), 
        .src2(src2), //has the immediate value of JMP
        .result(jmp_target)
    );

    //Choose Pass MOV OR adder result
    mux2_32 MOVorADD(
        .IN0(src2),
        .IN1(adder_result),
        .S0(ctrl[5]), //OP signal
        .Y(final_out)
    );

endmodule