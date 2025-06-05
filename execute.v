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

    output reg is_csr_pype2,
    output reg [11:0] csr_pype2,
    output reg [31:0] csr_wdata_pype2,
    output reg is_ePC_pype2,

    //分岐予測
    input is_branch_predict_pype1, //分岐予測したか？
    output branch_miss_contral, //分岐予測リカバリー
    output [31:0] branch_miss_PC,
    output [31:0] branch_BTB_PC, //成立した分岐の目的地
    output branch_BTB_contral, //分岐が成立したか
    output is_branch_pype2, //命令が分岐かどうか
    output reg [31:0] PC_pype2,  //分岐の番地


    //分岐予測性能評価
    output reg [31:0] branch_count,
    output reg [31:0] branch_miss_count,

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
    output reg [2:0] funct3_pype2
);
reg is_ecall_pype;
reg is_mret_pype;
reg [31:0] csr_rdata_pype2;
reg [31:0] next_PCBranch_pype2;
reg is_branch_predict_pype2;
wire branch_PC_contral;
wire [31:0] branch_PC;
wire csr_PC_contral;
wire [31:0] csr_PC;


  
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

//クリティカルパスになるかも？ 分岐予測するならこいつら全員wireや
assign branch_PC_contral =
    ((MemBranch_pype2 == 3'b100 && ALU_co_pype == 32'b0) ||            // BGE
     (MemBranch_pype2 == 3'b011 && ALU_co_pype != 32'b0) ||             // BLT
     (MemBranch_pype2 == 3'b110 && ALU_co_pype == 32'b0) ||           // BGEU
     (MemBranch_pype2 == 3'b101 && ALU_co_pype != 32'b0) ||            // BLTU                                   
     (MemBranch_pype2 == 3'b111) || //j
     (MemBranch_pype2 == 3'b001 && ALU_co_pype == 32'b0) || //beq
     (MemBranch_pype2 == 3'b010 && ALU_co_pype != 32'b0)); // bne

assign branch_PC = PCBranch_pype2;//戻り先を書かなきゃね

assign csr_PC_contral = ((is_ecall_pype == 1'b1) || (is_mret_pype == 1'b1));
assign csr_PC = csr_rdata_pype2;

assign branch_BTB_contral = branch_PC_contral || csr_PC_contral;

assign branch_BTB_PC = (branch_PC_contral) ? branch_PC:
                       (csr_PC_contral) ? csr_PC:
                       32'b0;//何を入れるべきか

assign is_branch_pype2 = |MemBranch_pype2;

//分岐予測予測して分岐が立たない→分岐命令のPC+4 分岐予測してないのに分岐予測が立つ→そのPC
//「分岐予測先と実際の分岐先が違う」が無い 
assign branch_miss_contral = (is_branch_predict_pype2 && (!branch_PC_contral && !csr_PC_contral)) || (!is_branch_predict_pype2 && (branch_PC_contral || csr_PC_contral)
                             || (is_branch_predict_pype2 && (branch_PC_contral || csr_PC_contral) && (branch_BTB_PC != PC_pype1)));

assign branch_miss_PC = (branch_PC_contral) ? branch_PC: //branch_predictしてないのにbranch立ったor branch predictしたけど実際のジャンプ先が違った時に用いる。
                        (csr_PC_contral) ? csr_PC:
                        PCp4_pype2;


always @(posedge clk or negedge rst) begin
//keepが上だとkeep中のnopが上手くいかない
//nopが上だとkeepが割り込んできたときのID/EX_write_pypeが上手くいかない
    if (!rst) begin
        ALU_co_pype <= 32'b0;
        read_data2_pype2 <= 32'b0;
        PCp4_pype2 <= 32'b0;
        WReg_pype2 <= 5'b0;
        writeback_control_pype2 <= 3'b0;
        MemRW_pype2 <= 2'b0;
        next_PCBranch_pype2 = 1'b0;
        dsize_pype2 <= 2'b00;
        funct3_pype2 <= 3'b0;
        is_csr_pype2 <= 1'b0;
        csr_pype2 <= 12'b0;
        is_ecall_pype <= 1'b0;
        is_mret_pype <= 1'b0;
        csr_rdata_pype2 <= 32'b0;
        is_ePC_pype2 <= 1'b0;
        MemBranch_pype2 <= 3'b0;
        is_branch_predict_pype2 <= 0;
        PC_pype2 <= 0; 
        branch_count <= 32'b0;
        branch_miss_count <= 32'b0;

    end else if (keep) begin
        ALU_co_pype <= ALU_co_pype;
        read_data2_pype2 <= read_data2_pype2;
        PCp4_pype2 <= PCp4_pype2;
        WReg_pype2 <= WReg_pype2;
        writeback_control_pype2 <= writeback_control_pype2;
        MemRW_pype2 <= MemRW_pype2;
        next_PCBranch_pype2 = next_PCBranch_pype2;
        dsize_pype2 <= dsize_pype2;
        funct3_pype2 <= funct3_pype2;
        is_csr_pype2 <= is_csr_pype2;
        csr_pype2 <= csr_pype2;
        is_ecall_pype <= is_ecall_pype;
        is_mret_pype <= is_mret_pype;
        csr_rdata_pype2 <= csr_rdata_pype2;
        is_csr_pype2 <= 1'b0;
        csr_pype2 <= 12'b0;
        is_ecall_pype <= 1'b0;
        is_mret_pype <= 1'b0;
        csr_rdata_pype2 <= 32'b0;
        MemBranch_pype2 <= MemBranch_pype2;
        is_branch_predict_pype2 <= is_branch_predict_pype2;
        PC_pype2 <= PC_pype2; //BTB系はストールとかの信号を考えていないのでkeepでも消すかも
    

    end else if (nop) begin
        read_data2_pype2 <= 32'b0;
        PCp4_pype2 <= 32'b0;
        WReg_pype2 <= 5'b0;
        writeback_control_pype2 <= 3'b0;
        MemRW_pype2 <= 2'b0;
        next_PCBranch_pype2 = 1'b0;
        dsize_pype2 <= 2'b10;
        funct3_pype2 <= 3'b0;
        is_csr_pype2 <= 1'b0;
        csr_pype2 <= 12'b0;
        is_ecall_pype <= 1'b0;
        is_mret_pype <= 1'b0;
        csr_rdata_pype2 <= 32'b0;
        MemBranch_pype2 <= 3'b0;
        is_branch_predict_pype2 <= 0;
        PC_pype2 <= 0;
    end


    else begin
    
    case(MemBranch_pype)
            3'b111: begin
            if (ALU_Src_pype[1])
            next_PCBranch_pype2 = (read_data1_effetive + $signed(Imm_pype)) & 32'hffff_fffe;
            else
            next_PCBranch_pype2 = PC_pype1 + $signed(Imm_pype);
            end
            default: next_PCBranch_pype2 = PC_pype1 + $signed(Imm_pype); 
    endcase

        //例外PCについて
        if (next_PCBranch_pype2[1:0] !=2'b00 && MemBranch_pype != 3'b000) begin //ストールの入り方によってはめちゃくちゃバグりそう
            PCBranch_pype2 <= 32'b0;
            is_csr_pype2 <= 1'b1;
            csr_pype2 <= 12'h341;
            csr_wdata_pype2 <= PC_pype1;
            is_ePC_pype2 <= 1'b1;
        end
        else begin
            PCBranch_pype2 <= next_PCBranch_pype2;
            is_csr_pype2 <= is_csr_pype1;
            csr_pype2 <= (is_ecall_pype1) ? 12'h341 : csr_pype1;
            csr_wdata_pype2 <= csr_alu(ALU_data1, csr_rdata_pype1, Imm_pype, PC_pype1, funct3_pype1);
            is_ePC_pype2 <= 1'b0;
        end

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
    is_ecall_pype <= is_ecall_pype1;
    is_mret_pype <= is_mret_pype1;
    ALU_co_pype <= (is_csr_pype1 && !is_ecall_pype1) ? csr_rdata_pype1 : alu(ALU_data1, ALU_data2, ALU_control_pype);
    csr_rdata_pype2 <= csr_rdata_pype1;
    is_branch_predict_pype2 <= is_branch_predict_pype1;
    PC_pype2 <= PC_pype1;

    if (is_branch_pype2)
        branch_count <= branch_count + 1;
    if (branch_miss_contral)
        branch_miss_count <= branch_miss_count + 1;
end
end
endmodule

