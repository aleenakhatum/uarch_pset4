module fetch_stage(
    input wire rst,
    input wire clk,
    input wire pc_we,
    input wire [31:0] pc,
    input wire [31:0] jmp_target,
    input wire is_jmp,
    input wire is_halt,
    output wire [39:0] instr,
    output wire [31:0] next_pc,
    output wire [2:0] instr_length
);
    
    //Fetch the Instruction
    instr_mem imem(
        .pc(pc),
        .instr(instr)
    );

    reg halt_reg;

    reg [2:0] current_length;
    wire [7:0] opcode = instr[7:0]; // Little Endian: Opcode is at bottom

    always@(posedge clk or posedge rst) begin
        if (rst) begin
            halt_reg <= 1'b0;
        end
        else if (is_halt) begin
            halt_reg <= 1'b1; //once reg = 1, stay 1
        end
    end

    always @(*) begin
        case(opcode)
            // 1-Byte Instructions (RET, NOP)
            8'hC3, 8'h90, 8'hF4: current_length = 3'd1;
            
            // 2-Byte Instructions (ADD r,r)
            8'h01, 8'h89:        current_length = 3'd2;
            
            // 3-Byte Instructions (ADD r, imm8)
            8'h83:               current_length = 3'd3;

            // 5-Byte Instructions (MOV r, imm32, JMP)
            8'hB8, 8'hB9, 8'h05, 8'hE9: current_length = 3'd5;
            
            default: current_length = 3'd1; 
        endcase
    end

    //Update Logic
    wire update_enable;
    assign update_enable = pc_we && ~halt_reg;

    wire [31:0] candidate_pc;
    assign candidate_pc = is_jmp ? jmp_target : (pc + current_length);
    assign next_pc = update_enable ? candidate_pc : pc;
    assign instr_length = current_length;

endmodule