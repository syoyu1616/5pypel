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

    //forwarding
    input [31:0] forwarding_ID_EX_data,
    input [31:0] forwarding_ID_MEM_data,
    input [31:0] forwarding_ID_MEM_hazard_data,
    input [31:0] forwarding_load_data,
    input [1:0] forwarding_ID_EX_pyc,
    input [1:0] forwarding_ID_MEM_pyc,
    input [1:0] forwarding_ID_MEM_hazard_pyc,
    input [1:0] forwarding_stall_load_pyc,

    //制御線
    input RegWrite_pype1,
    input [1:0] MemtoReg_pype1,
    input [1:0] MemRW_pype1,
    input [2:0] MemBranch_pype,
    input [3:0] ALU_control_pype,
    input [2:0] ALU_Src_pype,
    input [6:0] ALU_command_7,
    input [6:0] opcode_pype1,
    input [2:0] funct3_pype1,

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

    output reg [1:0] dsize_pype2,
    output reg [6:0] opcode_pype2,
    output reg [2:0] funct3_pype2

);

    //alu: ALU
    function signed [31:0] alu(
        input signed [31:0] a, 
        input signed [31:0] b,
        input [3:0] ctrl
    );
        case(ctrl)
            `ALU_ADD: alu = a + b;
            `ALU_SUB: alu = a - b;
            `ALU_AND: alu = a & b;
            `ALU_OR:  alu = a | b;
            `ALU_XOR: alu = a ^ b;
            `ALU_SLL: alu = a << b[4:0];
            `ALU_SRL: alu = a >> b[4:0];
            `ALU_SRA: alu = a >>> b[4:0];
            `ALU_SLT: alu = (a < b) ? 32'b1 : 32'b0;
            `ALU_SLTU: alu = $unsigned(a) < $unsigned(b) ? 32'b1 : 32'b0;
        endcase
    endfunction


wire [31:0] read_data1_effetive =
    (forwarding_ID_EX_pyc[1] == 1) ? forwarding_ID_EX_data :
    (forwarding_ID_MEM_pyc[1] == 1) ? forwarding_ID_MEM_data :
    (forwarding_stall_load_pyc[1] == 1) ? forwarding_load_data:
    (forwarding_ID_MEM_hazard_pyc[1] == 1) ? forwarding_ID_MEM_hazard_data:
                                 read_data1_pype;

wire [31:0] read_data2_effective =
    (forwarding_ID_EX_pyc[0] == 1) ? forwarding_ID_EX_data :
    (forwarding_ID_MEM_pyc[0] == 1) ? forwarding_ID_MEM_data :
    (forwarding_stall_load_pyc[0] == 1) ? forwarding_load_data:
    (forwarding_ID_MEM_hazard_pyc[0] == 1) ? forwarding_ID_MEM_hazard_data:
                                 read_data2_pype;



wire [31:0] ALU_data1 = (ALU_Src_pype[2:1] == 2'b00)  ? 32'b0 :
                        (ALU_Src_pype[2:1] == 2'b10) ? PC_pype1 :
                        (forwarding_ID_EX_pyc[1] == 1) ? forwarding_ID_EX_data:
                        (forwarding_ID_MEM_pyc[1] == 1) ? forwarding_ID_MEM_data://この感じだとストールの入る場所によってはまずい可能性大
                        (forwarding_stall_load_pyc[1] == 1) ? forwarding_load_data:
                        (forwarding_ID_MEM_hazard_pyc[1] == 1) ? forwarding_ID_MEM_hazard_data:
                        (ALU_Src_pype[2:1] == 2'b01)  ? read_data1_pype :
                        32'bx;


//これだけだとread_data_pype2にデータがいかない
wire [31:0] ALU_data2 = (ALU_Src_pype[0] == 1'b0) ? Imm_pype :
                        (forwarding_ID_EX_pyc[0] == 1) ? forwarding_ID_EX_data:
                        (forwarding_ID_MEM_pyc[0] == 1) ? forwarding_ID_MEM_data:
                        (forwarding_stall_load_pyc[0] == 1) ? forwarding_load_data:
                        (forwarding_ID_MEM_hazard_pyc[0] == 1) ? forwarding_ID_MEM_hazard_data:
                        (ALU_Src_pype[0] == 1'b1)  ? read_data2_pype :
                        32'bx;


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
        opcode_pype2 <= opcode_pype2;
        funct3_pype2 <= funct3_pype2;


    end else if (nop) begin
        /*ALU_co_pype <= 32'b0;*/
        PCBranch_pype2 <= 32'b0;
        read_data2_pype2 <= 32'b0;
        PCp4_pype2 <= 32'b0;
        WReg_pype2 <= 5'b0;
        RegWrite_pype2 <= 1'b0;
        MemtoReg_pype2 <= 2'b0;
        MemRW_pype2 <= 2'b0;
        MemBranch_pype2 <= 1'b0;
        Instraction_pype2 <= 32'b0;
        dsize_pype2 <= 2'b10;
        opcode_pype2 <= 7'b0;
        funct3_pype2 <= 3'b0;


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
        dsize_pype2 <= 2'b00;
        opcode_pype2 <=7'b0;
        funct3_pype2 <= 3'b0;

    end


    else begin
    /*case(ALU_control)
            `ALU_OP_ADD: ALU_co_pype <= ALU_data1 + ALU_data2;
            `ALU_OP_SUB: ALU_co_pype <= ALU_data1 - ALU_data2;

            `ALU_OP_AND: ALU_co_pype <= ALU_data1 & ALU_data2;
            `ALU_OP_OR:  ALU_co_pype <= ALU_data1 | ALU_data2;
            `ALU_OP_XOR: ALU_co_pype <= ALU_data1 ^ ALU_data2;
            `ALU_OP_SLL: ALU_co_pype <= ALU_data1 << ALU_data2[4:0];

            `ALU_OP_SRL: ALU_co_pype <= ALU_data1 >> ALU_data2[4:0];
            `ALU_OP_SRA: ALU_co_pype <= ALU_data1 >>> ALU_data2[4:0];
            `ALU_OP_SLT: ALU_co_pype <= ($signed(ALU_data1) < $signed(ALU_data2)) ? 32'b1 : 32'b0; //これらとsubを用いてbranchとする
            `ALU_OP_SLTU: ALU_co_pype <= ($unsigned(ALU_data1) < $unsigned(ALU_data2)) ? 32'b1 : 32'b0;
            4'b1111: ALU_co_pype <= ALU_data1 + ALU_data2;//imm + 0で通してるのでこれはいる
            default: ALU_co_pype <= 32'b0;
        endcase*/

    ALU_co_pype <=  alu(ALU_data1, ALU_data2, ALU_control_pype);
    
    case(opcode_pype1)
            7'b1100111: begin
            PCBranch_pype2 <= (read_data1_effetive + $signed(Imm_pype)) & 32'hffff_fffe;
            end
            default: PCBranch_pype2 <= PC_pype1 + $signed(Imm_pype);
    endcase


    case(opcode_pype1)
        7'b0100011: begin
            case(for_ALU_c)
            `INST_Sb: read_data2_pype2 <= {24'b0, read_data2_effective[7:0]}; //1バイト
            `INST_Sh: read_data2_pype2 <= {16'b0, read_data2_effective[15:0]}; //2バイト
            default: read_data2_pype2 <= read_data2_effective; //これないとswが働かない
        endcase
        end
        default: read_data2_pype2 <= read_data2_effective;
    endcase

case (opcode_pype1)
    7'b0000011, 7'b0100011: begin
        case (for_ALU_c[1:0])
            2'b00: dsize_pype2 <= 2'b00; // 1バイト
            2'b01: dsize_pype2 <= 2'b01; // 2バイト（おそらく）
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
    opcode_pype2 <= opcode_pype1;
    funct3_pype2 <= funct3_pype1;


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