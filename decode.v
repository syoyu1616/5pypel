`include "define.v"
module decode (
    input rst,
    input clk,
    input keep, //nopとかのときに一緒に使うやつでpcの維持など
    input nop,

    input [31:0] PC_pype0,
    input [31:0] PCp4_pype0,
    input [31:0] Instraction_pype,
    //stall系はちょっと後回し read_reg_pype や EXからの信号などがあるから

    input [31:0] read_data1,
    input [31:0] read_data2,//registerからのね

    output [31:0] read_data1_pype,
    output [31:0] read_data2_pype,

    output [4:0] read_reg1,
    output [4:0] read_reg2,

    output reg [31:0] PC_pype1,
    output reg [31:0] PCp4_pype1,
    output reg [31:0] Imm_pype,
    output reg [3:0] for_ALU_c,
    output reg [4:0]  WReg_pype,

    //制御線
    output reg RegWrite_pype1,
    output reg [1:0] MemtoReg_pype1,

    output reg [1:0] MemRW_pype1,

    output reg [2:0] MemBranch_pype,//以下以上とそれのunsign janp equal noteq
    /*  分岐しない 000
        eq 001
        noteq 010
        未満 (lt) 011
        以上 (ge) 100
        j系（飛ぶの確定） 111
    */
    output reg [2:0] ALU_control_pype,
    /* ALUを普通に使う　（加算減算シフト論理演算）000
       比較する 001
       ALUを用いない（lui）010
       jalとかの別枠 011
       fence 100
       ecall csw 100
       ebreak 101   
       mret 110
       特権sfens sret 111
    */
    output reg [2:0] ALU_Src_pype, //1が10,01,0 2が1,0
    output reg [6:0] ALU_command_7,

    output reg [31:0] Instraction_pype1
    
);

	wire [6:0] opcode;
		assign opcode = Instraction_pype[6:0];
	wire [31:0] imm_I;
		assign imm_I = {{20{Instraction_pype[31]}}, Instraction_pype[31:20]};
	wire [31:0] imm_S;
		assign imm_S = {{20{Instraction_pype[31]}}, Instraction_pype[31:25], Instraction_pype[11:7]};
	wire [31:0] imm_B;
		assign imm_B = {{20{Instraction_pype[31]}},  Instraction_pype[7], Instraction_pype[30:25], Instraction_pype[11:8], 1'b0};
	wire [31:0] imm_U;
		assign imm_U = {Instraction_pype[31:12], 12'b0};
	wire [31:0] imm_J;
        assign imm_J = {{20{Instraction_pype[31]}}, Instraction_pype[19:12], Instraction_pype[20], Instraction_pype[30:21], 1'b0};
    
		//assign imm_J = {{11{Instraction_pype[31]}}, Instraction_pype[19:12], Instraction_pype[20], Instraction_pype[30:21], 1'b0};

    wire [2:0] funct3;
    wire [6:0] funct7;

    wire [4:0] rd;
    /*
    wire [4:0] rs1;
    wire [4:0] rs2;
    */

    assign rd = Instraction_pype[11:7];
    /*
    assign rs1 = Instraction_pype[19:15];
    assign rs2 = Instraction_pype[24:20];
    */

    assign funct3 = Instraction_pype[14:12];
    assign funct7 = Instraction_pype[31:25];

    assign read_reg1 = Instraction_pype[19:15];
    assign read_reg2 = Instraction_pype[24:20];

    assign read_data1_pype = read_data1;
    assign read_data2_pype = read_data2;

    always @(posedge clk, negedge rst) begin
    
    // Stop(pause) CPU
    if (keep) begin
        //制御線維持
        RegWrite_pype1 <= RegWrite_pype1;
        MemtoReg_pype1 <= MemtoReg_pype1;
        MemRW_pype1 <= MemRW_pype1;
        MemBranch_pype <= MemBranch_pype;
        ALU_Src_pype <= ALU_Src_pype;
        ALU_control_pype <= ALU_control_pype;

        //data維持やex以降で用いるやつ維持
        Imm_pype <= Imm_pype;
        for_ALU_c <= for_ALU_c;
        WReg_pype <= WReg_pype;

        //PCやALU_controlの維持

        PC_pype1 <= PC_pype1;
        PCp4_pype1 <= PCp4_pype1;
        Instraction_pype1 <= Instraction_pype1;
    end


    // Pipeline Bubble(addi x0, x0, 0)
    else if (nop) begin
        //制御線維持
        RegWrite_pype1 <= 0;
        MemtoReg_pype1 <= 2'b0;
        MemRW_pype1 <= 2'b0;
        MemBranch_pype <= 3'b0;
        ALU_Src_pype <= 3'b0;
        ALU_control_pype <= 3'b0;

        //data維持やex以降で用いるやつ0
        Imm_pype <= 32'b0;
        for_ALU_c <= 4'b0;
        WReg_pype <= 5'b0;

        //PCやALU_controlの維持
        PC_pype1 <= PC_pype1;
        PCp4_pype1 <= PCp4_pype1;
        Instraction_pype1 <= Instraction_pype1;

    end

    else if (!rst) begin
        //制御線維持
        RegWrite_pype1 <= 0;
        MemtoReg_pype1 <= 2'b0;
        MemRW_pype1 <= 2'b0;
        MemBranch_pype <= 3'b0;
        ALU_Src_pype <= 3'b0;
        ALU_control_pype <= 3'b0;

        //data維持やex以降で用いるやつ0
        Imm_pype <= 32'b0;
        for_ALU_c <= 4'b0;
        WReg_pype <= 5'b0;
        
        //PCの維持
        PC_pype1 <= 32'b0;
        PCp4_pype1 <= 32'b0;
        Instraction_pype1 <= 32'b0;

    end

    // Normal Decode
    else begin
        case (opcode)
            // U Format
            // lui
            `OP_LUI: begin
                RegWrite_pype1 <= 1;
                MemtoReg_pype1 <= 2'b0;
                MemRW_pype1 <= 2'b0;
                MemBranch_pype <= 3'b0;
                ALU_Src_pype <= 3'b0;
                ALU_control_pype <= `ALU_co_pype_nou;

                Imm_pype <= imm_U;
                for_ALU_c <= 4'b0;
                WReg_pype <= rd;
            end

            // auipc
            `OP_AUIPC: begin
                RegWrite_pype1 <= 1;
                MemtoReg_pype1 <= 2'b0;
                MemRW_pype1 <= 2'b0;
                MemBranch_pype <= 3'b0;
                ALU_Src_pype <= 3'b100;
                ALU_control_pype <= `ALU_co_pype_normal;

                Imm_pype <= imm_U;
                for_ALU_c <= 4'b0;
                WReg_pype <= rd;

            end

            // J Format
            // jal
            `OP_JAL: begin
                RegWrite_pype1 <= 1;
                MemtoReg_pype1 <= `write_reg_PCp4;
                MemRW_pype1 <= 2'b0;
                MemBranch_pype <= `MEMB_JAL;
                ALU_Src_pype <= 3'b100;
                ALU_control_pype <= `ALU_co_pype_j;

                Imm_pype <= $signed(imm_J);
                for_ALU_c <= 4'b0000;//jalrとの差別化
                WReg_pype <= rd;
            end

            // I format
            // jalr
            `OP_JALR: begin
                RegWrite_pype1 <= 1;
                MemtoReg_pype1 <= `write_reg_PCp4;
                MemRW_pype1 <= 2'b0;
                MemBranch_pype <= `MEMB_JAL;
                ALU_Src_pype <= 3'b100;
                ALU_control_pype <= `ALU_co_pype_j;

                Imm_pype <= $signed(imm_I);
                for_ALU_c <= 4'b0001;
                WReg_pype <= rd;
            end

            // lb/lh/lw/lbu/lhu
            `OP_LOAD: begin
                RegWrite_pype1 <= 1;
                MemtoReg_pype1 <= `write_reg_memd;
                MemRW_pype1 <= 2'b10;
                MemBranch_pype <= 3'b000;
                ALU_Src_pype <= 3'b010;
                ALU_control_pype <= `ALU_co_pype_normal;

                Imm_pype <= $signed(imm_I);
                for_ALU_c <= {1'b0, funct3};
                WReg_pype <= rd;
            end

            // addi/slti/sltiu/xori/ori/andi/slli/srli/srail
            `OP_ALUI: begin
                RegWrite_pype1 <= 1;
                MemtoReg_pype1 <= `write_reg_ALUc;
                MemRW_pype1 <= 2'b00;
                MemBranch_pype <= 3'b000;
                ALU_Src_pype <= 3'b010;
                ALU_control_pype <= `ALU_co_pype_normal;

                Imm_pype <= $signed(imm_I);
                for_ALU_c <= {1'b0, funct3};
                WReg_pype <= rd;

            end

            // B Format
            // beq/bne/blt/bge/bltu/bgeu
            `OP_BRA: begin
                RegWrite_pype1 <= 0;
                MemtoReg_pype1 <= `write_reg_ALUc;
                MemRW_pype1 <= 2'b00;
                //MemBranch_pype <= 3'b000;
                ALU_Src_pype <= 3'b101;
                ALU_control_pype <= `ALU_co_pype_coo;

                Imm_pype <= $signed(imm_B);
                for_ALU_c <= {1'b0, funct3};

                case (funct3)
                    `FCT3_BEQ: begin
                        MemBranch_pype <= `MEMB_BEQ;
                    end

                    `FCT3_BNE: begin
                        MemBranch_pype <= `MEMB_BNE;
                    end

                    `FCT3_BLT: begin
                        MemBranch_pype <= `MEMB_BLT;
                    end

                    `FCT3_BGE: begin
                        MemBranch_pype <= `MEMB_BGE;
                    end

                    `FCT3_BLTU: begin
                        MemBranch_pype <= `MEMB_BLT;
                    end

                    `FCT3_BGEU: begin
                        MemBranch_pype <= `MEMB_BGE;
                    end
                endcase
            end

            // S Format
            // sb/sh/sw
            7'b0100011: begin

                RegWrite_pype1 <= 0;
                MemtoReg_pype1 <= `write_reg_ALUc;
                MemRW_pype1 <= 2'b01;
                MemBranch_pype <= 3'b000;
                ALU_Src_pype <= 3'b100;
                ALU_control_pype <= `ALU_co_pype_store;

                Imm_pype <= $signed(imm_S);
                for_ALU_c <= {1'b0, funct3};
                WReg_pype <= 5'b000;
            end

            // R Format
            // add/sub/sll/slt/sltu/xor/srl/sra/or/and
            7'b0110011: begin
                RegWrite_pype1 <= 1;
                MemtoReg_pype1 <= `write_reg_ALUc;
                MemRW_pype1 <= 2'b01;
                MemBranch_pype <= 3'b000;
                ALU_Src_pype <= 3'b011;
                ALU_control_pype <= `ALU_co_pype_normal;

                Imm_pype <= 32'b0;
                for_ALU_c <= {Instraction_pype[30], funct3};
                WReg_pype <= rd;

            end

            // default
            // addi x0, x0, 0
            default: begin
                RegWrite_pype1 <= 0;
                MemtoReg_pype1 <= 2'b00;
                MemRW_pype1 <= 2'b00;
                MemBranch_pype <= 3'b000;
                ALU_Src_pype <= 3'b000;
                ALU_control_pype <= 3'b000;

                Imm_pype <= 32'b0;
                for_ALU_c <= 4'b0;
                WReg_pype <= 5'b0;

            end
        endcase

        PC_pype1 <= PC_pype0;
        PCp4_pype1 <= PCp4_pype0;
        ALU_command_7 <= funct7;
        Instraction_pype1 <= Instraction_pype;

    end
end

endmodule

       // fence/fence.i
            /*
            7'b0001111: begin
                mem_command <= 5'b0;
                ex_command[5:3] <= 3'b110;
                ex_command[2:0] <= funct3;
                data_0 <= 32'b0;
                data_1[31:12] <= 20'b0;
                data_1[11:0] <= imm_I;
                reg_d <= 5'b0;
                mem_write_data <= 32'b0;
            end
            
            // ecall/ebreak/csrrw/csrrs/csrrc/csrrsi/csrrci
            7'b1110011: begin
                mem_command[4:2] <= funct3;
                mem_command[1:0] <= 2'b10;
                ex_command[5:3] <= 3'b101;
                ex_command[2:0] <= funct3;
                if (funct3[2]) begin
                    data_0[31:5] <= 27'b0;
                    data_0[4:0] <= rs1;
                end
                else
                    data_0 <= rs1_data;
                data_1 <= 32'b0;
                mem_write_data[31:12] <= 20'b0;
                mem_write_data[11:0] <= imm_I;
                reg_d <= rd;
            end
            */

            // B Format
            // beq/bne/blt/bge/bltu/bgeu