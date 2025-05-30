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
    input [4:0] WReg_pype,


    //forwarding
    input [31:0] forwarding_ID_EX_data,
    input [31:0] forwarding_ID_MEM_data,
    input [31:0] forwarding_ID_MEM_hazard_data,
    input [31:0] forwarding_load_data,
    input [1:0] forwarding_ID_EX_pyc,
    input [1:0] forwarding_ID_MEM_pyc,
    input [1:0] forwarding_ID_MEM_hazard_pyc,
    input [1:0] forwarding_stall_load_pyc,

    //csr
    input is_csr_pype1,
    input [11:0] csr_pype1,
    input is_ecall_pype1,
    input is_mret_pype1,
    input [31:0] csr_rdata_pype1,

    //output [11:0] csr_addr_r,
    //input [31:0] csr_rdata,//csrから読んだ奴ら
    //input [31:0] csr_mtvec,
    //input [31:0] csr_mepc,

    output reg is_csr_pype2,
    output reg [11:0] csr_pype2,
    output reg [31:0] csr_wdata_pype2,


    //制御線
    input [2:0] writeback_control_pype1,
    input [1:0] MemRW_pype1,
    input [2:0] MemBranch_pype,
    input [3:0] ALU_control_pype,
    input [2:0] ALU_Src_pype,
    input [2:0] funct3_pype1,

    output reg [31:0] PCBranch_pype2,
    output reg [31:0] PCp4_pype2,
    output reg [31:0] ALU_co_pype,
    output reg [31:0] read_data2_pype2,
    output reg [4:0] WReg_pype2,

    output reg [2:0] writeback_control_pype2,
    output reg [1:0] MemRW_pype2,
    output reg [2:0] MemBranch_pype2,

    output reg [1:0] dsize_pype2,
    output reg [2:0] funct3_pype2,

    output [31:0] branch_PC,
    output branch_PC_contral,
    output [31:0] csr_PC,
    output csr_PC_contral
);
reg is_ecall_pype;
reg is_mret_pype;
reg [31:0] csr_rdata_pype2;
  
    function signed [31:0] csr_alu(
        input signed [31:0] rs1_val, 
        input signed [31:0] csr_rdata,
        input signed [31:0] imm,
        input [31:0] PC_now,
        input [2:0] funct3);
        case (funct3)
            3'b000: csr_alu = PC_now; //ecall
            3'b001: csr_alu = rs1_val;                  // CSRRW
            3'b010: csr_alu = csr_rdata | rs1_val;      // CSRRS
            3'b011: csr_alu = csr_rdata & ~rs1_val;     // CSRRC
            3'b101: csr_alu = imm;                      // CSRRWI
            3'b110: csr_alu = csr_rdata | imm;          // CSRRSI
            3'b111: csr_alu = csr_rdata & ~imm;         // CSRRCI
        endcase
    endfunction

    //rdataはcsr_regからassignでもらってくる
    //wire is_ecall = 1'b1;// = (is_csr_pype1 == 1'b1 && funct3_pype1 == 3'b000 && Imm_pype[11:0] == 12'h000);
    /*wire is_ecall;
    assign is_ecall = (is_csr_pype1 == 1'b1 && funct3_pype1 == 3'b000 && csr_pype1 == 12'h000) ? 1'b1 : 1'b0;//0にしたら動かなくなる

    wire is_mret  = (is_csr_pype1 == 1'b1 && funct3_pype1 == 3'b000 && csr_pype1 == 12'h302);

    assign csr_addr_r = (is_ecall == 1'b1) ? 12'h305 ://mevec
                        (is_mret == 1'b1) ? 12'h341 ://mepc
                        (is_csr_pype1 == 1'b1) ? csr_pype1 :
                        12'h301;*/



    //alu: ALU
    function signed [31:0] alu(
        input signed [31:0] a, 
        input signed [31:0] b,
        input [3:0] ctrl);
        case (ctrl)
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


//分岐予測だとジャンプの時のpc+4を書く必要もある
wire [31:0] ALU_data1 = (ALU_Src_pype[2:1] == 2'b00)  ? 32'b0 :
                        (ALU_Src_pype[2:1] == 2'b10) ? PC_pype1 :
                        (forwarding_ID_EX_pyc[1] == 1) ? forwarding_ID_EX_data:
                        (forwarding_ID_MEM_pyc[1] == 1) ? forwarding_ID_MEM_data://この感じだとストールの入る場所によってはまずい可能性大
                        (forwarding_stall_load_pyc[1] == 1) ? forwarding_load_data:
                        (forwarding_ID_MEM_hazard_pyc[1] == 1) ? forwarding_ID_MEM_hazard_data:
                        (ALU_Src_pype[2:1] == 2'b01)  ? read_data1_pype :
                        32'bx;



wire [31:0] ALU_data2 = (ALU_Src_pype[0] == 1'b0) ? Imm_pype :
                        (forwarding_ID_EX_pyc[0] == 1) ? forwarding_ID_EX_data:
                        (forwarding_ID_MEM_pyc[0] == 1) ? forwarding_ID_MEM_data:
                        (forwarding_stall_load_pyc[0] == 1) ? forwarding_load_data:
                        (forwarding_ID_MEM_hazard_pyc[0] == 1) ? forwarding_ID_MEM_hazard_data:
                        (ALU_Src_pype[0] == 1'b1)  ? read_data2_pype :
                        32'bx;

//クリティカルパスになるかも？
assign branch_PC_contral =
    ((MemBranch_pype2 == 3'b100 && ALU_co_pype == 32'b0) ||            // BGE
     (MemBranch_pype2 == 3'b011 && ALU_co_pype != 32'b0) ||             // BLT
     (MemBranch_pype2 == 3'b110 && ALU_co_pype == 32'b0) ||           // BGEU
     (MemBranch_pype2 == 3'b101 && ALU_co_pype != 32'b0) ||            // BLTU                                   
     (MemBranch_pype2 == 3'b111));// ||
     //(is_ecall_pype == 1'b1) || (is_mret_pype == 1'b1));                                             // JALR    

assign branch_PC = PCBranch_pype2;

assign csr_PC_contral = ((is_ecall_pype == 1'b1) || (is_mret_pype == 1'b1));

assign csr_PC = csr_rdata_pype2;



always @(posedge clk or negedge rst) begin
//keepが上だとkeep中のnopが上手くいかない
//nopが上だとkeepが割り込んできたときのID/EX_write_pypeが上手くいかない
    if (!rst) begin
        ALU_co_pype <= 32'b0;
        PCBranch_pype2 <= 32'b0;
        read_data2_pype2 <= 32'b0;
        PCp4_pype2 <= 32'b0;
        WReg_pype2 <= 5'b0;
        writeback_control_pype2 <= 3'b0;
        MemRW_pype2 <= 2'b0;
        MemBranch_pype2 <= 1'b0;
        dsize_pype2 <= 2'b00;
        funct3_pype2 <= 3'b0;
        is_csr_pype2 <= 1'b0;
        csr_pype2 <= 12'b0;
        is_ecall_pype <= 1'b0;
        is_mret_pype <= 1'b0;
        csr_rdata_pype2 <= 32'b0;

    end else if (keep) begin
        ALU_co_pype <= ALU_co_pype;
        PCBranch_pype2 <= PCBranch_pype2;
        read_data2_pype2 <= read_data2_pype2;
        PCp4_pype2 <= PCp4_pype2;
        WReg_pype2 <= WReg_pype2;
        writeback_control_pype2 <= writeback_control_pype2;
        MemRW_pype2 <= MemRW_pype2;
        MemBranch_pype2 <= MemBranch_pype2;
        dsize_pype2 <= dsize_pype2;
        funct3_pype2 <= funct3_pype2;
        /*is_csr_pype2 <= is_csr_pype2;
        csr_pype2 <= csr_pype2;
        is_ecall_pype <= is_ecall_pype;
        is_mret_pype <= is_mret_pype;
        csr_rdata_pype2 <= csr_rdata_pype2;*/
        is_csr_pype2 <= 1'b0;
        csr_pype2 <= 12'b0;
        is_ecall_pype <= 1'b0;
        is_mret_pype <= 1'b0;
        csr_rdata_pype2 <= 32'b0;

    end else if (nop) begin
        PCBranch_pype2 <= 32'b0;
        read_data2_pype2 <= 32'b0;
        PCp4_pype2 <= 32'b0;
        WReg_pype2 <= 5'b0;
        writeback_control_pype2 <= 3'b0;
        MemRW_pype2 <= 2'b0;
        MemBranch_pype2 <= 1'b0;
        dsize_pype2 <= 2'b10;
        funct3_pype2 <= 3'b0;
        is_csr_pype2 <= 1'b0;
        csr_pype2 <= 12'b0;
        is_ecall_pype <= 1'b0;
        is_mret_pype <= 1'b0;
        csr_rdata_pype2 <= 32'b0;

    end


    else begin

    
    case(MemBranch_pype)
            3'b111: begin
            if (ALU_Src_pype[1])
            PCBranch_pype2 <= (read_data1_effetive + $signed(Imm_pype)) & 32'hffff_fffe;
            else
            PCBranch_pype2 <= PC_pype1 + $signed(Imm_pype);
            end
            default: PCBranch_pype2 <= PC_pype1 + $signed(Imm_pype);
    endcase


    case(MemRW_pype1[0])
        1'b1: begin
            case(funct3_pype1)
            3'b000: read_data2_pype2 <= {24'b0, read_data2_effective[7:0]}; //1バイト
            3'b001: read_data2_pype2 <= {16'b0, read_data2_effective[15:0]}; //2バイト
            default: read_data2_pype2 <= read_data2_effective; //これないとswが働かない
        endcase
        end
        default: read_data2_pype2 <= read_data2_effective;
    endcase

case (|MemRW_pype1)
    1'b1: begin
        case (funct3_pype1[1:0])
            2'b00: dsize_pype2 <= 2'b00; // 1バイト
            2'b01: dsize_pype2 <= 2'b01; // 2バイト（おそらく）
            default: dsize_pype2 <= 2'b10; // 4バイト（defaultがないと働かない）
        endcase
    end
    default: dsize_pype2 <= 2'b10; // load命令でないときは基本的にワードアクセス
endcase

    PCp4_pype2 <= PCp4_pype1;
    WReg_pype2 <= WReg_pype;
    MemRW_pype2 <= MemRW_pype1;
    writeback_control_pype2 <= writeback_control_pype1;
    MemBranch_pype2 <= MemBranch_pype;
    funct3_pype2 <= funct3_pype1;
    csr_pype2 <= (is_ecall_pype1) ? 12'h341 : csr_pype1;
    is_ecall_pype <= is_ecall_pype1;
    is_mret_pype <= is_mret_pype1;
    csr_wdata_pype2 <= csr_alu(ALU_data1, csr_rdata_pype1, Imm_pype, PCp4_pype1, funct3_pype1);
    ALU_co_pype <= (is_csr_pype1 && !is_ecall_pype1) ? csr_rdata_pype1 : alu(ALU_data1, ALU_data2, ALU_control_pype);
    is_csr_pype2 <= is_csr_pype1;
    csr_rdata_pype2 <= csr_rdata_pype1;

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



   /*reg [31:0] sum;
        reg carry;
        integer i;
        reg signed [31:0] b_sub;
        begin
        sum = 0;
        carry = 0;

        case (ctrl)
            `ALU_ADD: begin
                for (i = 0; i < 32; i = i + 4) begin
                    {carry, sum[i +: 4]} = a[i +: 4] + b[i +: 4] + carry;
                end
                alu = sum;
            end

            `ALU_SUB: begin
                b_sub = ~b + 1; // 2の補数での減算
                carry = 0;
                for (i = 0; i < 32; i = i + 4) begin
                    {carry, sum[i +: 4]} = a[i +: 4] + b_sub[i +: 4] + carry;
                end
                alu = sum;
            end*/