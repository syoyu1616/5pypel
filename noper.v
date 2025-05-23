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
    input [4:0] WReg_pype3,
    input [2:0] writeback_control_pype1,
    input [2:0] writeback_control_pype2,
    input [2:0] writeback_control_pype3,



    //分岐成立
    input branch_PC_contral,
    input branch_PC_early_contral,

    //メモリアクセスのためのストール
    input iready_n,
    input dready_n,
    input dbusy,
    input [1:0] MemRW_pype1,
    input [1:0] MemRW_pype2,

    output wire [1:0] ID_EX_write_rw,

//forwarding関連

    input [31:0] ALU_co_pype,
    input [31:0] ALU_co_pype3,
    input [31:0] write_reg_data,
    input [31:0] mem_data_pype,

    output  [31:0] forwarding_ID_EX_data,
    output  [31:0] forwarding_ID_MEM_data,
    output reg [31:0] forwarding_ID_MEM_hazard_data,
    output  [31:0] forwarding_load_data,


    output reg [1:0] forwarding_ID_EX_pyc, //pype control
    output reg [1:0] forwarding_ID_MEM_pyc,
    output reg [1:0] forwarding_ID_MEM_hazard_pyc,
    output reg [1:0] forwarding_stall_load_pyc_pype2,
   
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

    //cash側でデータ保持があるので、同じ場所に書き込みとかじゃない限りOK
    wire mem_ac_stall; //メモリアクセスによるストールの管理
    assign mem_ac_stall = iready_n || (dready_n && MemRW_pype2[1]) || (dbusy && MemRW_pype2[0]);

    assign forwarding_ID_EX_data = ALU_co_pype;
    assign forwarding_ID_MEM_data = write_reg_data; //同じ名前でregにして使うかも
    assign forwarding_load_data = mem_data_pype;
   
    // ハザード信号（reg型に変更）
    reg hazard_pype1;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            hazard_pype1 <= 0;
            forwarding_ID_EX_pyc <= 2'b0;
            forwarding_ID_MEM_pyc <= 2'b0;
            forwarding_stall_load_pyc_pype2 <= 2'b00;

end else if (!mem_ac_stall) begin //lwの時とそれ以外で分ける必要あり
        //hazard発生は前側の命令がloadの時だけ（opcode_pype == 7'b0000011）
        //read_data_pypeに書き込むのは
        
        hazard_pype1 <= /*RegWrite_pype1*/ writeback_control_pype1[2] && (WReg_pype != 0) && 
                        ((WReg_pype == fornop_register1_pype) || (WReg_pype == fornop_register2_pype)) && 
                        (MemRW_pype1[1] == 1'b1);


        if ((/*RegWrite_pype1*/ writeback_control_pype1[2] && (WReg_pype != 0)) && (MemRW_pype1[1] != 1'b1)) 
            forwarding_ID_EX_pyc <= {(WReg_pype == fornop_register1_pype), (WReg_pype == fornop_register2_pype)};
        else
            forwarding_ID_EX_pyc <= 2'b0;

        if (/*RegWrite_pype2*/ writeback_control_pype2[2] && (WReg_pype2 != 0)) //二つ離れてたら大丈夫！！
            forwarding_ID_MEM_pyc <= {(WReg_pype2 == fornop_register1_pype), (WReg_pype2 == fornop_register2_pype)};
        else
            forwarding_ID_MEM_pyc <= 2'b0;


        if ((/*RegWrite_pype1*/ writeback_control_pype1[2] && (WReg_pype != 0)) && (MemRW_pype1[1] == 1'b1)) 
            forwarding_stall_load_pyc_pype2 <= {(WReg_pype == fornop_register1_pype), (WReg_pype == fornop_register2_pype)};
        else
            forwarding_stall_load_pyc_pype2 <= 2'b0;
        
        if ((hazard_pype1) && (forwarding_ID_MEM_pyc != 2'b00)) begin
            forwarding_ID_MEM_hazard_pyc <= forwarding_ID_MEM_pyc;
            forwarding_ID_MEM_hazard_data <= write_reg_data;//これ遅れ取るかも

        end else begin
            forwarding_ID_MEM_hazard_pyc <= 2'b0;
            forwarding_ID_MEM_hazard_data <= 32'b0;
        end
    end
end


assign ID_EX_write_rw = (/*RegWrite_pype3*/ writeback_control_pype3[2] && (WReg_pype3 != 0)) ?
    {(WReg_pype3 == fornop_register1_pype), (WReg_pype3 == fornop_register2_pype)} : 2'b00;


    assign stall_IF  = 0;
    assign stall_ID  = mem_ac_stall || hazard_pype1;
    assign stall_EX  = mem_ac_stall;
    assign stall_Mem = mem_ac_stall;
    assign stall_WB  = mem_ac_stall;


    // nop制御：分岐成立で後続を潰す、またはデータハザードでEXにバブル入れる
    assign nop_IF  = branch_PC_contral || branch_PC_early_contral || mem_ac_stall || hazard_pype1;//1'b0; // IFには基本nop入れない（IFは止めるだけ）
    assign nop_ID  = branch_PC_contral ;  // 分岐成立でIDの命令潰す
    assign nop_EX  = branch_PC_contral || hazard_pype1; // memアクセスの際に消えてる可能性あるかも
    assign nop_Mem = 1'b0;//branch_PC_contral これがないとbranch成立の後ろが書き込んじゃう
    assign nop_WB  = 1'b0; //branch--で様子見

    endmodule

