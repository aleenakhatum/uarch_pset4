`timescale 1ns / 1ps

module decode_stage(
    input wire [31:0] pc,
    input wire [39:0] instr,
    output wire [31:0] imm,
    output wire [2:0] src1_idx, //dst
    output wire [2:0] src2_idx, //src
    output wire [6:0] ctrl,
    output wire [7:0] length
);

    reg [31:0] imm_reg;
    reg [2:0] src1_idx_reg;
    reg [2:0] src2_idx_reg;
    reg src2mux_reg; //rr stage signal for src2 output
    reg op_reg; //alu signal
    reg read1_reg; //reg file signal
    reg read2_reg; //reg file signal
    reg we_reg; //regfile signal
    reg is_jmp_reg; 
    reg is_halt_reg;
    reg [2:0] length_reg;

    assign imm = imm_reg;
    assign src1_idx = src1_idx_reg;
    assign src2_idx = src2_idx_reg;
    assign ctrl = {src2mux_reg, op_reg, read1_reg, read2_reg, we_reg, is_jmp_reg, is_halt_reg};
    assign length = length_reg;

    wire [7:0] opcode = instr[7:0];
    wire [7:0] modrm = instr[15:8];
    
    always @(*) begin
        //Initialize
        imm_reg       = 32'b0;
        src1_idx_reg  = 3'b0;
        src2_idx_reg  = 3'b0;
        src2mux_reg       = 1'b0; //regfile default
        op_reg            = 1'b0; //mov pass default
        read1_reg         = 1'b0;
        read2_reg         = 1'b0;
        we_reg            = 1'b0;
        is_jmp_reg = 1'b0;
        is_halt_reg = 1'b0;
        length_reg = 3'b001;

        case(opcode)
            8'h01: begin //ADD r/m16,r16
                src1_idx_reg = modrm[2:0]; //dst
                src2_idx_reg = modrm[5:3]; //src
                length_reg = 3'd2; //2 byte length
                op_reg = 1'b1; //add op
                read1_reg = 1'b1;
                read2_reg = 1'b1;
                we_reg = 1'b1;

            end
            8'h05: begin //ADD EAX,imm32
                imm_reg = {instr[39:32], instr[31:24], instr[23:16], instr[15:8]}; //little-endian
                src1_idx_reg = 3'b000; //EAX hardcoded
                length_reg = 3'd5;
                op_reg = 1'b1; //add op
                read1_reg = 1'b1;
                we_reg = 1'b1;
                src2mux_reg = 1'b1;
            end
            8'h83: begin //ADD r/m32, sext(imm8)
                src1_idx_reg = modrm[2:0];
                imm_reg = {{24{instr[23]}}, instr[23:16]};
                length_reg = 3'd3;
                op_reg = 1'b1; //add op
                read1_reg = 1'b1;
                we_reg = 1'b1;
                src2mux_reg = 1'b1;
            end
            8'hE9: begin //JMP rel32
                is_jmp_reg = 1'b1;
                imm_reg = {instr[39:32], instr[31:24], instr[23:16], instr[15:8]};
                length_reg = 3'd5;
            end
            8'hB8: begin //MOV EAX, imm32
                imm_reg = {instr[39:32], instr[31:24], instr[23:16], instr[15:8]};
                length_reg = 3'd5;
                src1_idx_reg = opcode[2:0] & 3'b111;
                //read2_reg = 1'b1;
                we_reg = 1'b1;
                src2mux_reg = 1'b1;
            end
            8'hB9: begin //MOV ECX, imm32
                imm_reg = {instr[39:32], instr[31:24], instr[23:16], instr[15:8]};
                length_reg = 3'd5;
                src1_idx_reg = opcode[2:0] & 3'b111;
                //read2_reg = 1'b1;
                we_reg = 1'b1;
                src2mux_reg = 1'b1;
            end
            8'hF4: begin //Halt
                is_halt_reg = 1'b1;
                length_reg = 3'd1;
            end
        endcase
    end
endmodule

