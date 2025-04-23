`include "define.v"
`include "fetch.v"
`include "decode.v"
`include "execute.v"


/*module noper(
    input clk,
    input [4:0] fornop_register1_pype,
    input [4:0] fornop_register2_pype,
    input [4:0] WReg_pype,
    input [4:0] WReg_pype2,
    input RegWrite_pype1,
    input RegWrite_pype2,

    output reg nop_IF,
    output reg nop_ID,
    output reg nop_EX,
    output reg nop_Mem,
    output reg nop_WB
);
//branchでのnopについては後で　とりあえず

always @(posedge clk) begin
            // 初期化（NOP無し）
        nop_IF  <= 0;
        nop_ID  <= 0;
        nop_EX  <= 0;
        nop_Mem <= 0;
        nop_WB  <= 0;

        // WReg_pype（EX段の書き込み先）が今のdecodeで使うレジスタと被ってて、RegWriteが有効
        if (RegWrite_pype1 && (
            (WReg_pype != 0) &&
            ((WReg_pype == fornop_register1_pype) || (WReg_pype == fornop_register2_pype))
        )) begin
            nop_IF <= 1;
            nop_ID <= 1;
        end

        // WReg_pype2（MEM段の書き込み先）が今のdecodeで使うレジスタと被ってて、RegWriteが有効
        else if (RegWrite_pype2 && (
            (WReg_pype2 != 0) &&
            ((WReg_pype2 == fornop_register1_pype) || (WReg_pype2 == fornop_register2_pype))
        )) begin
            nop_IF <= 1;
            nop_ID <= 1;
            nop_EX <= 1;//ここ求めなきゃね　4/22はnoperのテストから
        end
    
end
endmodule*/
//wire型にすることでnopが遅れない？（regだと遅れてる）
module noper(
    input [4:0] fornop_register1_pype,
    input [4:0] fornop_register2_pype,
    input [4:0] WReg_pype,
    input [4:0] WReg_pype2,
    input RegWrite_pype1,
    input RegWrite_pype2,

    //branch成立によるnopがあるはず 4/22はこれで完成

    output wire nop_IF,
    output wire nop_ID,
    output wire nop_EX,
    output wire nop_Mem,
    output wire nop_WB
);

    wire hazard_pype1 = RegWrite_pype1 && (WReg_pype != 0) &&
                        ((WReg_pype == fornop_register1_pype) || (WReg_pype == fornop_register2_pype));

    wire hazard_pype2 = RegWrite_pype2 && (WReg_pype2 != 0) &&
                        ((WReg_pype2 == fornop_register1_pype) || (WReg_pype2 == fornop_register2_pype));

    assign nop_IF  = hazard_pype1 || hazard_pype2;
    assign nop_ID  = hazard_pype1 || hazard_pype2;
    assign nop_EX  = hazard_pype2;  // MEM段の競合時だけEXも止める
    assign nop_Mem = 0;             // 現状は使わない（あとで追加してもOK）
    assign nop_WB  = 0;

endmodule
