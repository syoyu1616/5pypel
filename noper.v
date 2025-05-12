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

    input [4:0] fornop_register1_pype1,
    input [4:0] fornop_register2_pype1,

    //書き込みの有無
    input [4:0] WReg_pype,
    input [4:0] WReg_pype2,
    input [4:0] WReg_pype3,
    input RegWrite_pype1,
    input RegWrite_pype2,
    input RegWrite_pype3,
    input [31:0] Instraction_pype,


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

    output reg [1:0] ID_EX_write_addi_pype2,
    output reg [1:0] ID_EX_write_pype3,
    output wire [1:0] ID_EX_write_rw,

   
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

//読むやつは1or2個前の命令で書き込む
/*
    wire hazard_pype1 = RegWrite_pype1 && (WReg_pype != 0) &&
                        ((WReg_pype == fornop_register1_pype) || (WReg_pype == fornop_register2_pype));

    wire hazard_pype2 = RegWrite_pype2 && (WReg_pype2 != 0) &&
                        ((WReg_pype2 == fornop_register1_pype) || (WReg_pype2 == fornop_register2_pype));

    wire hazard_pype3 = RegWrite_pype3 && (WReg_pype3 != 0) &&
                        ((WReg_pype3 == fornop_register1_pype) || (WReg_pype3 == fornop_register2_pype));*/

    // 2ビットのビットマスクを使って、どのレジスタにハザードがあるかを示す
    //どっちにしろ3で立つのでいらない ×　二個連続に対応するため二つのパイプを用意する
    /*
    assign ID_EX_write_addi_pype1 = (RegWrite_pype1 && (WReg_pype != 0)) ? 
    { (WReg_pype == fornop_register1_pype), (WReg_pype == fornop_register2_pype) } : 2'b00;

    assign ID_EX_write_pype2 = (RegWrite_pype2 && (WReg_pype2 != 0)) ? 
    { (WReg_pype2 == fornop_register1_pype), (WReg_pype2 == fornop_register2_pype) } : 2'b00;
    */

    // ハザード信号（reg型に変更）
reg hazard_pype1;
reg hazard_pype2;
reg hazard_pype3;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        hazard_pype1 <= 0;
        hazard_pype2 <= 0;
        hazard_pype3 <= 0;
        ID_EX_write_addi_pype2 <= 2'b00;
        ID_EX_write_pype3 <= 2'b00;
    end else if (!mem_ac_stall) begin
        hazard_pype1 <= RegWrite_pype1 && (WReg_pype != 0) &&
                        ((WReg_pype == fornop_register1_pype) || (WReg_pype == fornop_register2_pype));

        hazard_pype2 <= RegWrite_pype2 && (WReg_pype2 != 0) &&
                        ((WReg_pype2 == fornop_register1_pype) || (WReg_pype2 == fornop_register2_pype));

        hazard_pype3 <= RegWrite_pype2 && (WReg_pype2 != 0) &&
                        ((WReg_pype2 == fornop_register1_pype1) || (WReg_pype2 == fornop_register2_pype1));


        if (RegWrite_pype1 && (WReg_pype != 0))
            ID_EX_write_addi_pype2 <= { (WReg_pype == fornop_register1_pype), (WReg_pype == fornop_register2_pype) };
        else
            ID_EX_write_addi_pype2 <= 2'b00;

        if (RegWrite_pype2 && (WReg_pype2 != 0))
            ID_EX_write_pype3 <= { (WReg_pype2 == fornop_register1_pype), (WReg_pype2 == fornop_register2_pype) };
        else
            ID_EX_write_pype3 <= 2'b00;
        
    end
end

//wire [1:0] ID_EX_write_rw;

assign ID_EX_write_rw = (RegWrite_pype3 && (WReg_pype3 != 0)) ?
    { (WReg_pype3 == fornop_register1_pype), (WReg_pype3 == fornop_register2_pype) } : 2'b00;

    wire mem_ac_stall; //メモリアクセスによるストールの管理
    //cash側でデータ保持があるので、同じ場所に書き込みとかじゃない限りOK
    assign mem_ac_stall = iready_n || (dready_n && MemRW_pype2[1]) || (dbusy && MemRW_pype2[0]);


    assign stall_IF  = 0;
    assign stall_ID  = mem_ac_stall || hazard_pype1 || hazard_pype2 || hazard_pype3;
    assign stall_EX  = mem_ac_stall;
    assign stall_Mem = mem_ac_stall;
    assign stall_WB  = mem_ac_stall;

    // nop制御：分岐成立で後続を潰す、またはデータハザードでEXにバブル入れる
    assign nop_IF  = branch_PC_contral || mem_ac_stall || hazard_pype1 || hazard_pype2 || hazard_pype3;//1'b0; // IFには基本nop入れない（IFは止めるだけ）
    assign nop_ID  = branch_PC_contral;  // 分岐成立でIDの命令潰す
    assign nop_EX  = branch_PC_contral || hazard_pype1 || hazard_pype2 || hazard_pype3; // memアクセスの際に消えてる可能性あるかも
    assign nop_Mem = 1'b0;//branch_PC_contral これがないとbranch成立の後ろが書き込んじゃう
    assign nop_WB  = 1'b0; //branch--で様子見

    endmodule

