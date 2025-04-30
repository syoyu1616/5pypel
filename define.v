//docode用

`define OP_LOAD  7'b0000011
`define OP_ALUI  7'b0010011
`define OP_STORE 7'b0100011
`define OP_ALU   7'b0110011
`define OP_BRA   7'b1100011
`define OP_AUIPC 7'b0010111
`define OP_LUI   7'b0110111
`define OP_JALR  7'b1100111
`define OP_JAL   7'b1101111

`define FCT3_LB  3'b000
`define FCT3_LH  3'b001
`define FCT3_LW  3'b010
`define FCT3_LBU 3'b100
`define FCT3_LHU 3'b101

`define FCT3_SB  3'b000
`define FCT3_SH  3'b001
`define FCT3_SW  3'b010

`define FCT3_ADD  3'b000
`define FCT3_SLL  3'b001
`define FCT3_SLT  3'b010
`define FCT3_SLTU 3'b011
`define FCT3_XOR  3'b100
`define FCT3_SRL  3'b101
`define FCT3_OR   3'b110
`define FCT3_AND  3'b111

`define FCT3_BEQ  3'b000
`define FCT3_BNE  3'b001
`define FCT3_BLT  3'b100
`define FCT3_BGE  3'b101
`define FCT3_BLTU 3'b110
`define FCT3_BGEU 3'b111

`define MEMB_BEQ  3'b001
`define MEMB_BNE  3'b010

`define MEMB_BLT  3'b011 //unsignedも同じ
`define MEMB_BGE  3'b100 //unsignedも同じ

`define MEMB_JAL  3'b101 
`define MEMB_JALR  3'b111 

//`define MEMB_JAL  3'b111 //飛ぶのは確定なのでjalrも同じ 

`define ALU_co_pype_normal  3'b000
`define ALU_co_pype_coo  3'b001
`define ALU_co_pype_nou  3'b010
`define ALU_co_pype_j  3'b011
`define ALU_co_pype_store  3'b100
`define ALU_co_pype_load 3'b101


/*
`define ALU_co_pype_fence  3'b100
`define ALU_co_pype_eca_csw  3'b101
`define ALU_co_pype_ 3'b110
`define ALU_co_pype_sfence 3'b111
*/

//executeで用いる

`define INST_ADD  4'b0000
`define INST_SUB  4'b1000

`define INST_AND  4'b0111
`define INST_OR   4'b0110
`define INST_XOR  4'b0100

`define INST_SLL  4'b0001
//`define ALU_c_JALR  4'b1001//ビットマスクのために演算の仕方が違う


`define INST_SRL  4'b0101
`define INST_SRA  4'b1101

`define INST_SLT  4'b0010
`define INST_SLTU 4'b0011


`define INST_BEQ  4'b0000
`define INST_BNE  4'b0001
`define INST_BLT  4'b0100
`define INST_BGE  4'b0101
`define INST_BLTU  4'b0110
`define INST_BGEU  4'b0111

`define INST_JAL  4'b0000
`define INST_JALR  4'b0001

`define INST_Sb  4'b0000
`define INST_Sh  4'b0001
`define INST_Sw  4'b0010

`define write_reg_PCp4 2'b10
`define write_reg_memd 2'b01
`define write_reg_ALUc 2'b00



/*
// 命令識別用（ALU_control_pype に応じて for_ALU_c に入る値）
`define INST_ADD     4'b0000
`define INST_SUB     4'b0001
`define INST_AND     4'b0010
`define INST_OR      4'b0011
`define INST_XOR     4'b0100
`define INST_SLL     4'b0101
`define INST_SRL     4'b0110
`define INST_SRA     4'b0111
`define INST_SLT     4'b1000
`define INST_SLTU    4'b1001

`define INST_BEQ     4'b1010
`define INST_BNE     4'b1011
`define INST_BLT     4'b1100
`define INST_BGE     4'b1101
`define INST_BLTU    4'b1110
`define INST_BGEU    4'b1111

`define INST_JAL     4'b0000
`define INST_JALR    4'b0001
*/

// ALU制御用（ALU_controlに渡す）
`define ALU_OP_ADD   4'b0000
`define ALU_OP_SUB   4'b0001
`define ALU_OP_AND   4'b0010
`define ALU_OP_OR    4'b0011
`define ALU_OP_XOR   4'b0100
`define ALU_OP_SLL   4'b0101
`define ALU_OP_SRL   4'b0110
`define ALU_OP_SRA   4'b0111
`define ALU_OP_SLT   4'b1000
`define ALU_OP_SLTU  4'b1001

`define ALU_OP_JALR  4'b1010  // 特別な JALR 処理



`define ALU_Src_d1_0 2'b00
`define ALU_Src_d1_p 2'b01
`define ALU_Src_d1_PC 2'b10

`define ALU_Src_d2_Im 1'b0
`define ALU_Src_d2_p 1'b1





`define ALUC_ADD_n  5'b00000
`define ALUC_SUB_n  5'b00100
`define ALUC_AND_n  5'b01000
`define ALUC_OR_n   5'b01100
`define ALUC_XOR_n  5'b10000
`define ALUC_SLL_n  5'b10100
`define ALUC_SRL_n  5'b11000
`define ALUC_SRA_n  5'b11100
`define ALUC_SLT_2  5'b00101
`define ALUC_SLTU_u 5'b00110

