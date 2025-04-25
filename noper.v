`include "fetch.v"
`include "decode.v"
`include "execute.v"
`include "mem_access.v"

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
    wire hazard_pype1 = RegWrite_pype1 && (WReg_pype != 0) &&
                        ((WReg_pype == fornop_register1_pype) || (WReg_pype == fornop_register2_pype));

    wire hazard_pype2 = RegWrite_pype2 && (WReg_pype2 != 0) &&
                        ((WReg_pype2 == fornop_register1_pype) || (WReg_pype2 == fornop_register2_pype));

    wire hazard_pype3 = RegWrite_pype3 && (WReg_pype3 != 0) &&
                        ((WReg_pype3 == fornop_register1_pype) || (WReg_pype3 == fornop_register2_pype));

    //wire hazard_pype3 = Regwrite && (write_reg_address != 0) &&
    //                    ((write_reg_address == fornop_register1_pype) || (write_reg_address == fornop_register2_pype));//特に変わってなさそう
    
    //regに書き込めてない？
    //wire hazard = (rst) ? (hazard_pype1 || hazard_pype2 ) : 1'b0;

    //wire hazard = hazard_pype1 || hazard_pype2; //|| hazard_pype3;

    wire mem_ac_stall; //メモリアクセスによるストールの管理
    
    //案1　このためにMEMRW_pyep3を作り、そこで止めてもらう
    //案2　疑似的なdbusyを作り、1クロックだけ止める
    /*reg write_hold;
    reg [1:0]write_triggered;

    always @(posedge clk, negedge rst) begin
    if (!rst) begin
        write_hold <= 0;
        write_triggered <= 0;
    end
    else if (MemRW_pype1[0] && !write_triggered) begin
        write_hold <= 1'b1;             // 書き込み命令が来た瞬間に1にする
        write_triggered <= 2'b10;        // 1クロックだけトリガー
    end

    else if (MemRW_pype1[0] && write_triggered[1]) begin
        write_hold <= 1;
        write_triggered <= 2'b01;
    end

    else if (MemRW_pype1[0] && write_triggered[0]) begin
        write_hold <= 0;
        write_triggered <= 0;
    end

    else if (!MemRW_pype1[0]) begin
        write_triggered <= 0;
        write_hold <= 0;
    end

    else begin
        write_hold <= 0;             // 次のクロックで戻す
        
    end
end*/

//cash側でデータ保持があるので、同じ場所に書き込みとかじゃない限りOK

    assign mem_ac_stall = iready_n || (dready_n && MemRW_pype2[1]) || (dbusy && MemRW_pype2[0]);

    // stall制御：データハザードがあるときは、IF/IDを止める（EXにはnopを入れる）
    /*assign stall_IF  = hazard || mem_ac_stall;
    assign stall_ID  = hazard || mem_ac_stall;
    assign stall_EX  = hazard_pype2 ||mem_ac_stall;*/
    assign stall_IF  = mem_ac_stall;//mem_ac_stall || hazard || hazard_pype3;
    assign stall_ID  = mem_ac_stall || hazard_pype3;
    assign stall_EX  = mem_ac_stall;
    assign stall_Mem = mem_ac_stall;
    assign stall_WB  = 0;

    // nop制御：分岐成立で後続を潰す、またはデータハザードでEXにバブル入れる
    assign nop_IF  = branch_PC_contral || mem_ac_stall || hazard_pype1 || hazard_pype2 || hazard_pype3;//1'b0; // IFには基本nop入れない（IFは止めるだけ）
    assign nop_ID  = branch_PC_contral || hazard_pype1 || hazard_pype2;  // 分岐成立でIDの命令潰す
    assign nop_EX  = branch_PC_contral || hazard_pype2; // 分岐 or データハザードでEXをバブル
    assign nop_Mem = 0;
    assign nop_WB  = 1'b0;



    endmodule

