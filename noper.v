`include "fetch.v"
`include "decode.v"
`include "execute.v"
`include "mem_access.v"
//`include "define.v"

//wire型にすることでnopが遅れない？（regだと遅れてる）
//nop 分岐成立でやってる命令を消したい　stall　読み込むやつに書き込むとかで遅らせたい

//分岐成立　ID　EX　MEMをnop　IFは次の命令を読み込み、WBはjとかならレジスタに書き込み
//読込書き込みの競合　IF IDをストール　exはnop 解消のためMEM、WBは動いてもらわないといけない
//レジスタの書き込みの後の読みは余分に1クロック待ってもらう必要あり　fecheとdecodeを止める

module noper(
    input clk,
    input rst,

    //次に読み込むレジスタ
    input [4:0] fornop_register1_pype,
    input [4:0] fornop_register2_pype,

    //書き込みの有無
    input [4:0] WReg_pype,
    input [4:0] WReg_pype2,
    input RegWrite_pype1,
    input RegWrite_pype2,
    input [31:0] Instraction_pype,

    input [4:0] WReg_pype3,
    input RegWrite_pype3,

    input [4:0] write_reg_address,
    input Regwrite,

    //分岐成立
    input branch_PC_contral,

    //メモリアクセスのためのストール
    input iready_n,
    input dready_n,
    input dbusy,
    input [1:0] MemRW_pype1,
    input [1:0] MemRW_pype2,

    output wire [1:0] ID_EX_write_addi_pype1,
    output wire [1:0] ID_EX_write_pype2,
   
    output wire stall_IF,
    output wire stall_ID,
    output wire stall_EX,
    output wire stall_Mem,
    output wire stall_WB,

    output wire nop_IF,
    output wire nop_ID,
    output wire nop_EX,
    output wire nop_Mem,
    output wire nop_WB
);
	/*wire [6:0] opcode;
		assign opcode = Instraction_pype[6:0];

    wire [4:0] WReg_pype_before;
        assign WReg_pype_before = Instraction_pype[11:7];

    wire RegWrite_pype_before;
        //assign RegWrite_pype_before = (opcode == `OP_ALU) || (opcode == `OP_ALUI) || (opcode == `OP_LOAD) || (opcode == `OP_JAL) || (opcode == `OP_JALR)  ? 1'b1 : 1'b0;

        assign RegWrite_pype_before = (opcode == 7'b0000011) || (opcode == 7'b0010011) 
                                   || (opcode == 7'b0110011) || (opcode == 7'b1100111) 
                                   || (opcode == 7'b1101111)  ? 1'b1 : 1'b0;*/



//読むやつは1or2個前の命令で書き込む
    wire hazard_pype1 = RegWrite_pype1 && (WReg_pype != 0) &&
                        ((WReg_pype == fornop_register1_pype) || (WReg_pype == fornop_register2_pype));

    wire hazard_pype2 = RegWrite_pype2 && (WReg_pype2 != 0) &&
                        ((WReg_pype2 == fornop_register1_pype) || (WReg_pype2 == fornop_register2_pype));

    wire hazard_pype3 = RegWrite_pype3 && (WReg_pype3 != 0) &&
                        ((WReg_pype3 == fornop_register1_pype) || (WReg_pype3 == fornop_register2_pype));

    // 2ビットのビットマスクを使って、どのレジスタにハザードがあるかを示す
    //どっちにしろ3で立つのでいらない ×　二個連続に対応するため二つのパイプを用意する
    assign ID_EX_write_addi_pype1 = (RegWrite_pype1 && (WReg_pype != 0)) ? 
    { (WReg_pype == fornop_register1_pype), (WReg_pype == fornop_register2_pype) } : 2'b00;

    assign ID_EX_write_pype2 = (RegWrite_pype2 && (WReg_pype2 != 0)) ? 
    { (WReg_pype2 == fornop_register1_pype), (WReg_pype2 == fornop_register2_pype) } : 2'b00;


    wire mem_ac_stall; //メモリアクセスによるストールの管理
    //cash側でデータ保持があるので、同じ場所に書き込みとかじゃない限りOK
    assign mem_ac_stall = iready_n || (dready_n && MemRW_pype2[1]) || (dbusy && MemRW_pype2[0]);


    assign stall_IF  = 0;
    assign stall_ID  = mem_ac_stall || hazard_pype2;
    assign stall_EX  = mem_ac_stall;
    assign stall_Mem = mem_ac_stall;
    assign stall_WB  = 0;

    // nop制御：分岐成立で後続を潰す、またはデータハザードでEXにバブル入れる
    assign nop_IF  = branch_PC_contral || mem_ac_stall || hazard_pype1 || hazard_pype2;//1'b0; // IFには基本nop入れない（IFは止めるだけ）
    assign nop_ID  = branch_PC_contral;// || hazard_pype1;  // 分岐成立でIDの命令潰す
    assign nop_EX  = branch_PC_contral || hazard_pype2; // 分岐 or データハザードでEXをバブル
    assign nop_Mem = branch_PC_contral;
    assign nop_WB  = 1'b0; //branch--で様子見



    endmodule

