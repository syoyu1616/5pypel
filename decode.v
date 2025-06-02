`include "define.v"
module decode (
    input rst,
    input clk,
    input keep, //nopとかのときに一緒に使うやつでpcの維持など
    input nop,

    input [31:0] PC_pype0,
    input [31:0] PCp4_pype0,
    input [31:0] Instraction_pype,

    input [1:0] ID_EX_write_rw,
    input Regwrite,
    input [31:0] write_reg_data,

    input [4:0] fornop_register1_pype,
    input [4:0] fornop_register2_pype,


    input [31:0] read_data1,
    input [31:0] read_data2,//registerからのね

    //early branch 
    input [1:0] forwarding_ID_EX_pyc,
    input [1:0] forwarding_ID_MEM_pyc,
    input [1:0] forwarding_stall_load_pyc,
    input [1:0] forwarding_ID_MEM_hazard_pyc,

    input [31:0] forwarding_ID_EX_data,
    input [31:0] forwarding_ID_MEM_data,
    input [31:0] forwarding_load_data,
    input [31:0] forwarding_ID_MEM_hazard_data,

    input [1:0] MemRW_pype2,
    output branch_PC_early_contral,
    output [31:0] branch_PC_early,

    output reg [31:0] read_data1_pype,
    output reg [31:0] read_data2_pype,

    output [4:0] read_reg1,
    output [4:0] read_reg2,

    output reg [31:0] PC_pype1,
    output reg [31:0] PCp4_pype1,
    output reg [31:0] Imm_pype,

    //csr
    output reg is_csr_pype1,
    output reg [11:0] csr_pype1,
    output [11:0] csr_addr_r,
    input [31:0] csr_rdata,
    output reg is_ecall_pype1,
    output reg is_mret_pype1,
    output reg [31:0] csr_rdata_pype1,

    //制御線
    //executeで用いる
    output reg [3:0] ALU_control_pype,
    output reg [2:0] ALU_Src_pype, //1が10,01,0 2が1,0
    output reg [2:0] funct3_pype1,



    //memで用いる
    output reg [1:0] MemRW_pype1,
    output reg [2:0] MemBranch_pype,//以下以上とそれのunsign janp equal noteq
    /*  分岐しない 000
        eq 001
        noteq 010
        未満 (lt) 011
        以上 (ge) 100
        未満　unsigned 101
        以上　unsigned 110
        j系（飛ぶの確定） 111
    */

    //writebackで用いる
    output reg [4:0]  WReg_pype,
    output reg [2:0] writeback_control_pype1    //[2] regwrite [1:0] memtoreg

);



	wire [6:0] opcode;
		assign opcode = Instraction_pype[6:0];
   
    function[3:0] alu_ctrl(
        input[31:0] inst
    );
        if(inst[6:0] == `OP_BRA) begin
            case (inst[14:12])
                3'b110, 3'b111: alu_ctrl = `ALU_SLTU;
                3'b100, 3'b101: alu_ctrl = `ALU_SLT;
                default: alu_ctrl = `ALU_SUB;
            endcase
        end else if(inst[6:0] == `OP_ALU || inst[6:0] == `OP_ALUI) begin
            case(inst[14:12])
                `FCT3_ADD:  alu_ctrl = inst[6:0] == `OP_ALU && inst[30] == 1'b1 ? `ALU_SUB : `ALU_ADD;
                `FCT3_SLL:  alu_ctrl = `ALU_SLL;
                `FCT3_SLT:  alu_ctrl = `ALU_SLT;
                `FCT3_SLTU: alu_ctrl = `ALU_SLTU;
                `FCT3_XOR:  alu_ctrl = `ALU_XOR;
                `FCT3_SRL:  alu_ctrl = inst[30] == 1'b1 ? `ALU_SRA : `ALU_SRL;
                `FCT3_OR:   alu_ctrl = `ALU_OR;
                `FCT3_AND:  alu_ctrl = `ALU_AND;
            endcase
        end else begin
            alu_ctrl = `ALU_ADD;
        end
    endfunction


    //immgen: 即値を生成する
    function[31:0] immgen(
        input[31:0] inst
    );
        case(inst[6:0])
            `OP_LOAD:  immgen = {{20{inst[31]}}, inst[31:20]};
            `OP_ALUI:  immgen = inst[14:12] == `FCT3_SRL ? {{27{1'b0}}, inst[24:20]} : {{20{inst[31]}}, inst[31:20]};
            `OP_STORE: immgen = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            `OP_BRA:   immgen = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
            `OP_AUIPC: immgen = {inst[31:12], 12'b0};
            `OP_LUI:   immgen = {inst[31:12], 12'b0};
            `OP_JALR:  immgen = {{20{inst[31]}}, inst[31:20]};
            `OP_JAL:   immgen = {{20{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
            7'b1110011: immgen = {{27{1'b0}}, inst[19:15]};
            default:   immgen = 32'b0;
        endcase
    endfunction

    wire [31:0] imm;
    assign imm = immgen (Instraction_pype);

    wire [4:0] rd;
    wire [2:0] funct3;

    assign rd = Instraction_pype[11:7];
    assign funct3 = Instraction_pype[14:12];//14:12から変更 4/30
    
    assign read_reg1 = Instraction_pype[19:15];
    assign read_reg2 = Instraction_pype[24:20]; 


 
    wire [11:0] csr = Instraction_pype[31:20];
    
    wire is_csr = (opcode == 7'b1110011);
    wire is_ecall = (is_csr == 1'b1 && funct3 == 3'b000 && csr == 12'h000); //0にしたら動かなくなる
    wire is_mret  = (is_csr == 1'b1 && funct3 == 3'b000 && csr == 12'h302);

    assign csr_addr_r = (is_ecall == 1'b1) ? 12'h305 ://mevec
                        (is_mret == 1'b1) ? 12'h341 ://mepc
                        (is_csr == 1'b1) ? csr :
                        12'h301;




    //regfileの読み出しに時間がかかるとして、フォワーディングの際も早期分岐を行うように設計する。
    //regfileの読み出しに時間がかかりすぎる場合、add add beqみたいな時だけ早期分岐をするようにするかも

    wire [31:0] rs1_early_branch = (forwarding_ID_EX_pyc[1] == 1) ? forwarding_ID_EX_data:
                                   (forwarding_ID_MEM_pyc[1] == 1) ? forwarding_ID_MEM_data:
                                   (forwarding_stall_load_pyc[1] == 1) ? forwarding_load_data:
                                   (forwarding_ID_MEM_hazard_pyc[1] == 1) ? forwarding_ID_MEM_hazard_data:
                                   (ID_EX_write_rw[1] == 1) ? write_reg_data:
                                   read_data1_pype;

    wire [31:0] rs2_early_branch = (forwarding_ID_EX_pyc[0] == 1) ? forwarding_ID_EX_data:
                                   (forwarding_ID_MEM_pyc[0] == 1) ? forwarding_ID_MEM_data:
                                   (forwarding_stall_load_pyc[0] == 1) ? forwarding_load_data:
                                   (forwarding_ID_MEM_hazard_pyc[0] == 1) ? forwarding_ID_MEM_hazard_data:
                                   (ID_EX_write_rw[0] == 1) ? write_reg_data:
                                   read_data2_pype;

    wire is_branch = ((|MemBranch_pype) && (MemBranch_pype!= 3'b111));


    wire taken = (is_branch) ? (
                (funct3_pype1 == 3'b000) ? (rs1_early_branch ^ rs2_early_branch) == 32'b0 :
                (funct3_pype1 == 3'b001) ? (rs1_early_branch ^ rs2_early_branch) != 32'b0 :
                1'b0
            ) : 1'b0;

    assign branch_PC_early_contral = 0;//(keep == 1) ? 0: taken;
    assign branch_PC_early = PC_pype1 + Imm_pype;



    always @(posedge clk or negedge rst) begin

    if (!rst) begin
        //制御線維持

        writeback_control_pype1 <= 3'b0;
        MemRW_pype1 <= 2'b0;
        MemBranch_pype <= 3'b0;
        ALU_Src_pype <= 3'b0;
        ALU_control_pype <= 4'b0;
        funct3_pype1 <= 3'b0;
        is_csr_pype1 <= 1'b0;
        csr_pype1 <= 12'b0;
        is_ecall_pype1 <= 1'b0;
        is_mret_pype1 <= 1'b0;
        csr_rdata_pype1 <= 32'b0;


        //data維持やex以降で用いるやつ0
        Imm_pype <= 32'b0;
        WReg_pype <= 5'b0;
        read_data1_pype <= 32'b0;
        read_data2_pype <= 32'b0;

        
        //PCの維持
        PC_pype1 <= 32'b0;
        PCp4_pype1 <= 32'b0;

    end else if (nop) begin
        //制御線維持
        writeback_control_pype1 <= 3'b0;
        MemRW_pype1 <= 2'b0;
        MemBranch_pype <= 3'b0;
        ALU_Src_pype <= 3'b0;
        ALU_control_pype <= 4'b0;
        funct3_pype1 <= 3'b0;
        is_csr_pype1 <= 1'b0;
        csr_pype1 <= 12'b0;
        is_ecall_pype1 <= 1'b0;
        is_mret_pype1 <= 1'b0;
        csr_rdata_pype1 <= 32'b0;

        //data維持やex以降で用いるやつ0
        Imm_pype <= 32'b0;
        WReg_pype <= 5'b0;
        read_data1_pype <= 32'b0;
        read_data2_pype <= 32'b0;

        //PCやALU_controlの維持
        PC_pype1 <= 32'b0;
        PCp4_pype1 <= 12'b0;
    end
    
    // Stop(pause) CPU
    else if (keep) begin

        //制御線維持
        writeback_control_pype1 <= writeback_control_pype1;
        MemRW_pype1 <= MemRW_pype1;
        MemBranch_pype <= MemBranch_pype;
        ALU_Src_pype <= ALU_Src_pype;
        ALU_control_pype <= ALU_control_pype;
        funct3_pype1 <= funct3_pype1;
        is_csr_pype1 <= is_csr_pype1;
        csr_pype1 <= csr_pype1;
        is_ecall_pype1 <= is_ecall_pype1;
        is_mret_pype1 <= is_ecall_pype1;
        csr_rdata_pype1 <= csr_rdata_pype1;

        //data維持やex以降で用いるやつ維持
        Imm_pype <= Imm_pype;
        WReg_pype <= WReg_pype;
        read_data1_pype <= ((Regwrite == 0) && (ID_EX_write_rw[1] == 1)) ? write_reg_data :
                            read_data1_pype;
        read_data2_pype <= ((Regwrite == 0) && (ID_EX_write_rw[0] == 1)) ? write_reg_data :
                            read_data2_pype;

        //PCやALU_controlの維持
        PC_pype1 <= PC_pype1;
        PCp4_pype1 <= PCp4_pype1;

    end



    // Normal Decode
    else begin
        case (opcode)
            // U Format
            // lui
            `OP_LUI: begin
                writeback_control_pype1 <= 3'b100;
                MemRW_pype1 <= 2'b0;
                MemBranch_pype <= 3'b0;
                ALU_Src_pype <= 3'b0;
                Imm_pype <= imm;
                WReg_pype <= rd;
            end
            // auipc
            `OP_AUIPC: begin
                writeback_control_pype1 <= 3'b100;
                MemRW_pype1 <= 2'b0;
                MemBranch_pype <= 3'b0;
                ALU_Src_pype <= 3'b100;
                Imm_pype <= imm;
                WReg_pype <= rd;
            end
            // J Format
            // jal
            `OP_JAL: begin
                writeback_control_pype1 <= 3'b110;
                MemRW_pype1 <= 2'b0;
                MemBranch_pype <= 3'b111;//一旦これで
                ALU_Src_pype <= 3'b100;
                Imm_pype <= $signed(imm);
                WReg_pype <= rd;
            end
            // I format
            // jalr
            `OP_JALR: begin
                writeback_control_pype1 <= 3'b110;
                MemRW_pype1 <= 2'b0;
                MemBranch_pype <= 3'b111;
                ALU_Src_pype <= 3'b010;
                Imm_pype <= $signed(imm);
                WReg_pype <= rd;
            end
            // lb/lh/lw/lbu/lhu
            `OP_LOAD: begin
                writeback_control_pype1 <= 3'b101;
                MemRW_pype1 <= 2'b10;
                MemBranch_pype <= 3'b000;
                ALU_Src_pype <= 3'b010;
                Imm_pype <= $signed(imm);
                WReg_pype <= rd;
            end
            // addi/slti/sltiu/xori/ori/andi/slli/srli/srail srailだけ30bit目を参照する
            `OP_ALUI: begin
                writeback_control_pype1 <= 3'b100;
                MemRW_pype1 <= 2'b00;
                MemBranch_pype <= 3'b000;
                ALU_Src_pype <= 3'b010;
                Imm_pype <= $signed(imm);
                WReg_pype <= rd;
            end

            // B Format
            // beq/bne/blt/bge/bltu/bgeu
            `OP_BRA: begin
                writeback_control_pype1 <= 3'b000;
                MemRW_pype1 <= 2'b00;
                ALU_Src_pype <= 3'b011;
                Imm_pype <= $signed(imm);
                WReg_pype <= 5'b00000;
                case (funct3)
                    3'b000: begin
                        MemBranch_pype <= 3'b001;
                    end
                    3'b001: begin
                        MemBranch_pype <= 3'b010;
                    end
                    3'b100: begin
                        MemBranch_pype <= 3'b011;
                    end
                    3'b101: begin
                        MemBranch_pype <= 3'b100;
                    end
                    3'b110: begin
                        MemBranch_pype <= 3'b101;
                    end
                    3'b111: begin
                        MemBranch_pype <= 3'b110;
                    end
                endcase
            end
            // S Format
            // sb/sh/sw
            7'b0100011: begin
                writeback_control_pype1 <= 3'b000;
                MemRW_pype1 <= 2'b01;
                MemBranch_pype <= 3'b000;
                ALU_Src_pype <= 3'b010;
                Imm_pype <= $signed(imm);
                WReg_pype <= 5'b00000;
            end
            // R Format
            // add/sub/sll/slt/sltu/xor/srl/sra/or/and
            7'b0110011: begin
                writeback_control_pype1 <= 3'b100;
                MemRW_pype1 <= 2'b00;
                MemBranch_pype <= 3'b000;
                ALU_Src_pype <= 3'b011;
                Imm_pype <= 32'b0;
                WReg_pype <= rd;
            end

            //例外処理 csr ecall mret
            7'b1110011: begin
                if (funct3 == 3'b000)
                writeback_control_pype1 <= 3'b000;
                else
                writeback_control_pype1 <= 3'b100;
                
                MemRW_pype1 <= 2'b00;
                MemBranch_pype <= 3'b000;
                ALU_Src_pype <= 3'b010;//専用のALUを使うが、read_data1は用いるので
                Imm_pype <= imm;
                WReg_pype <= rd;


            end
            // default
            // addi x0, x0, 0
            default: begin
                writeback_control_pype1 <= 3'b000;
                MemRW_pype1 <= 2'b00;
                MemBranch_pype <= 3'b000;
                ALU_Src_pype <= 3'b000;
                Imm_pype <= 32'b0;
                WReg_pype <= 5'b0;
            end
        endcase

        PC_pype1 <= PC_pype0;
        PCp4_pype1 <= PCp4_pype0;
        read_data1_pype <= ((Regwrite == 0) && (ID_EX_write_rw[1] == 1)) ? write_reg_data :
                            read_data1;
        read_data2_pype <= ((Regwrite == 0) && (ID_EX_write_rw[0] == 1)) ? write_reg_data :
                            read_data2;
        funct3_pype1 <= funct3;
        ALU_control_pype <= alu_ctrl(Instraction_pype);
        is_csr_pype1 <= is_csr;
        csr_pype1 <= csr;
        is_ecall_pype1 <= is_ecall;
        is_mret_pype1 <= is_mret;
        csr_rdata_pype1 <= csr_rdata;
    end
end

endmodule
