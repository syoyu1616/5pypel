`include "define.v"

module execute(
    input rst,
    input clk,
    input keep, //nopとかのときに一緒に使うやつでpcの維持など
    input nop,

    input [31:0] PC_pype1,
    input [31:0] PCp4_pype1,
    input [31:0] read_data1_pype,
    input [31:0] read_data2_pype,
    input [31:0] Imm_pype,
    input [3:0] for_ALU_c,
    input [4:0] WReg_pype,

    input [31:0] Instraction_pype1,

    //input [1:0] ID_EX_write_addi_pype1,
    //output reg [1:0] ID_EX_write_addi_pype2,

    //制御線
    input RegWrite_pype1,
    input [1:0] MemtoReg_pype1,
    input [1:0] MemRW_pype1,
    input [2:0] MemBranch_pype,
    input [2:0] ALU_control_pype,
    input [2:0] ALU_Src_pype,
    input [6:0] ALU_command_7,

    output reg [31:0] PCBranch_pype2,
    output reg [31:0] PCp4_pype2,
    output reg [31:0] ALU_co_pype,
    output reg [31:0] read_data2_pype2,
    output reg [4:0] WReg_pype2,

    output reg RegWrite_pype2,
    output reg [1:0] MemtoReg_pype2,
    output reg [1:0] MemRW_pype2,
    output reg [2:0] MemBranch_pype2,

    output reg [31:0] Instraction_pype2,

    output reg [1:0] dsize_pype2

    


    //fecheへのバック regかはまだわからん 4/18
    /*output branch_PC_contral
    output branch_PC*/
    //stall関連はまだ
);


wire [3:0] ALU_control;

assign ALU_control =
    (ALU_control_pype == `ALU_co_pype_normal) ? (
        (for_ALU_c == `INST_ADD)  ? `ALU_OP_ADD  :
        (for_ALU_c == `INST_SUB)  ? `ALU_OP_SUB  :
        (for_ALU_c == `INST_AND)  ? `ALU_OP_AND  :
        (for_ALU_c == `INST_OR)   ? `ALU_OP_OR   :
        (for_ALU_c == `INST_XOR)  ? `ALU_OP_XOR  :
        (for_ALU_c == `INST_SLL)  ? `ALU_OP_SLL  :
        (for_ALU_c == `INST_SRL)  ? `ALU_OP_SRL  :
        (for_ALU_c == `INST_SRA)  ? `ALU_OP_SRA  :
        (for_ALU_c == `INST_SLT)  ? `ALU_OP_SLT  :
        (for_ALU_c == `INST_SLTU) ? `ALU_OP_SLTU :
                                    4'b0000
    ) :
    (ALU_control_pype == `ALU_co_pype_coo) ? (
        (for_ALU_c == `INST_BEQ || for_ALU_c == `INST_BNE)   ? `ALU_OP_SUB  :
        (for_ALU_c == `INST_BLT || for_ALU_c == `INST_BGE)   ? `ALU_OP_SLT  :
        (for_ALU_c == `INST_BLTU || for_ALU_c == `INST_BGEU) ? `ALU_OP_SLTU :
                                                               4'b0000
    ) :
    (ALU_control_pype == `ALU_co_pype_j) ? (
        (for_ALU_c == `INST_JAL)  ? `ALU_OP_ADD  :
        (for_ALU_c == `INST_JALR) ? `ALU_OP_ADD  :
                                    4'b0000
    ) :
    (ALU_control_pype == `ALU_co_pype_load)  ? `ALU_OP_ADD :
    (ALU_control_pype == `ALU_co_pype_store) ? `ALU_OP_ADD :
                                               4'b0000;
    



wire [31:0] ALU_data1 = (ALU_Src_pype[2:1] == 2'b00)  ? 32'b0 :
                        (ALU_Src_pype[2:1] == 2'b01)  ? read_data1_pype :
                        (ALU_Src_pype[2:1] == 2'b10) ? PC_pype1 :
                        32'bx;

wire [31:0] ALU_data2 = (ALU_Src_pype[0] == 1'b0) ? Imm_pype :
                        (ALU_Src_pype[0] == 1'b1)  ? read_data2_pype :
                        32'bx;


/*wire branch_PC_wire
branch_PC_wire = PC_pype1 + Imm_pype;
JALRは先んじて行う
if (MemBranch_pype = 3'b100) branch_PC_wire = (read_data1_pype + Imm_pype) & 32'hffff_fffe;
assign branch_PC = branch_PC_wire*/

//cmp_result = (a - b) >>> 31;  // MSBが1ならa < b 2の補数表現比較

//午後からはALUを作る


always @(posedge clk, negedge rst) begin
//keepが上だとkeep中のnopが上手くいかない
//nopが上だとkeepが割り込んできたときのID/EX_write_pypeが上手くいかない
    if (keep) begin

        ALU_co_pype <= ALU_co_pype;
        PCBranch_pype2 <= PCBranch_pype2;
        read_data2_pype2 <= read_data2_pype2;
        PCp4_pype2 <= PCp4_pype2;
        WReg_pype2 <= WReg_pype2;
        RegWrite_pype2 <= RegWrite_pype2;
        MemtoReg_pype2 <= MemtoReg_pype2;
        MemRW_pype2 <= MemRW_pype2;
        MemBranch_pype2 <= MemBranch_pype2;
        Instraction_pype2 <= Instraction_pype2;
        dsize_pype2 <= dsize_pype2;
 
    end else if (nop) begin

        ALU_co_pype <= 32'b0;
        PCBranch_pype2 <= 32'b0;
        read_data2_pype2 <= 32'b0;
        PCp4_pype2 <= 32'b0;
        WReg_pype2 <= 5'b0;
        RegWrite_pype2 <= 1'b0;
        MemtoReg_pype2 <= 2'b0;
        MemRW_pype2 <= 2'b0;
        MemBranch_pype2 <= 1'b0;
        Instraction_pype2 <= 32'b0;
        dsize_pype2 <= 2'b00;

    end  else if (!rst) begin
        ALU_co_pype <= 32'b0;
        PCBranch_pype2 <= 32'b0;
        read_data2_pype2 <= 32'b0;
        PCp4_pype2 <= 32'b0;
        WReg_pype2 <= 5'b0;
        RegWrite_pype2 <= 1'b0;
        MemtoReg_pype2 <= 2'b0;
        MemRW_pype2 <= 2'b0;
        MemBranch_pype2 <= 1'b0;
        Instraction_pype2 <= 32'b0;
        //ID_EX_write_addi_pype2 <= 32'b0;
    end


    else begin
    case(ALU_control)
            `ALU_OP_ADD: ALU_co_pype <= ALU_data1 + ALU_data2;
            //`ALU_OP_SUB: ALU_co_pype <= ALU_data1 - ALU_data2;
            `ALU_OP_SUB: ALU_co_pype <= $signed(ALU_data1) - $signed(ALU_data2);

            `ALU_OP_AND: ALU_co_pype <= ALU_data1 & ALU_data2;
            `ALU_OP_OR:  ALU_co_pype <= ALU_data1 | ALU_data2;
            `ALU_OP_XOR: ALU_co_pype <= ALU_data1 ^ ALU_data2;
            `ALU_OP_SLL: ALU_co_pype <= ALU_data1 << ALU_data2[4:0];

            `ALU_OP_SRL: ALU_co_pype <= ALU_data1 >> ALU_data2[4:0];
            `ALU_OP_SRA: ALU_co_pype <= ALU_data1 >>> ALU_data2[4:0];
            `ALU_OP_SLT: ALU_co_pype <= (ALU_data1 < ALU_data2) ? 32'b1 : 32'b0; //これらとsubを用いてbranchとする
            `ALU_OP_SLTU: ALU_co_pype <= $unsigned(ALU_data1) < $unsigned(ALU_data2) ? 32'b1 : 32'b0;
            default: ALU_co_pype <= 32'b0;
        endcase



    
    case(MemBranch_pype)
            3'b111: begin
            case(for_ALU_c)
                4'b0001: PCBranch_pype2 <= (read_data1_pype + $signed(Imm_pype)) & 32'hffff_fffe;
            endcase
            end
            default: PCBranch_pype2 <= PC_pype1 + $signed(Imm_pype);
    endcase


    case(ALU_control_pype)
        `ALU_co_pype_store: begin
            case(for_ALU_c)
            `INST_Sb: read_data2_pype2 <= {24'b0, read_data2_pype[7:0]}; //1バイト
            `INST_Sh: read_data2_pype2 <= {18'b0, read_data2_pype[15:0]}; //2バイト
            default: read_data2_pype2 <= read_data2_pype; //これないとswが働かない
        endcase
        end
    
        default: read_data2_pype2 <= read_data2_pype;

    endcase

case (ALU_control_pype)
    `ALU_co_pype_load: begin
        case (for_ALU_c)
            4'b0000, 4'b0100: dsize_pype2 <= 2'b00; // 1バイト
            4'b0001, 4'b0101: dsize_pype2 <= 2'b01; // 2バイト（おそらく）
            default: dsize_pype2 <= 2'b10; // 4バイト（defaultがないと働かない）
        endcase
    end
    default: dsize_pype2 <= 2'b10; // load命令でないときは基本的にワードアクセス
endcase


    PCp4_pype2 <= PCp4_pype1;
    WReg_pype2 <= WReg_pype;
    MemtoReg_pype2 <= MemtoReg_pype1;
    MemRW_pype2 <= MemRW_pype1;
    MemBranch_pype2 <= MemBranch_pype;
    Instraction_pype2 <= Instraction_pype1;
    RegWrite_pype2 <= RegWrite_pype1;

    //ID_EX_write_addi_pype2 <= ID_EX_write_addi_pype1;
end
end
endmodule


//reg [1:0] branch, //分岐の成立を教える ＝ 00, ￢＝ 01 未満 10 以上 11 Membranchと一致してたら分岐や！(ALUから出るので分岐)
 //ALU_control_pype,for_ALU_cを基にしてALUへ渡しちゃう
//4/18 exelを用いてALU_controlを制御するところから
//演算形式は3'b  

/*reg [3:0] ALU_control;

always @(*) begin
    case (ALU_control_pype)
        `ALU_co_pype_normal: begin
            case (for_ALU_c)
                `ALU_ADD:  ALU_control = `ALU_ADD;
                `ALU_SUB:  ALU_control = `ALU_SUB;
                `ALU_AND: ALU_control = `ALU_AND;
                `ALU_OR: ALU_control = `ALU_OR;
                `ALU_XOR: ALU_control = `ALU_XOR;
                `ALU_SLL: ALU_control = `ALU_SLL;
                `ALU_SRL: ALU_control = `ALU_SRL;
                `ALU_SRA: ALU_control = `ALU_SRA;
                `ALU_SLT: ALU_control = `ALU_SLT;
                `ALU_SLTU: ALU_control = `ALU_SLTU;
                default:   ALU_control = 4'b0000;
            endcase
        end

        `ALU_co_pype_coo: begin
            case (for_ALU_c)
                `ALU_BEQ, `ALU_BNE:  ALU_control = `ALU_SUB;
                `ALU_BLT, `ALU_BGE:  ALU_control = `ALU_SLT;
                `ALU_BLTU, `ALU_BGEU: ALU_control = `ALU_SLTU;
                default:   ALU_control = 4'b0000;
            endcase
        end

        `ALU_co_pype_j: begin
            case (for_ALU_c)
                `ALU_JAL:   ALU_control = `ALU_ADD;
                `ALU_JALR:  ALU_control = `ALU_c_JALR;
                default:    ALU_control = 4'b0000;
            endcase
        end

        default: ALU_control = 4'b0000;
    endcase
end
*/