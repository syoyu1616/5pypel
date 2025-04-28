//fetchモジュール
//PCの値を用いてInstructionMemoryから、instractionを取り出す
//PC →branch_PC_earlyやbranch_PCで場合分けしてiaddrを出力する

//クロックの立ち上がりに同時にノンブロッキング代入のため、iaddrとpc_pypeたちが1クロックずれている
//4/15はmemdatを用いてinstractionpypeが上手くいってるか（helloでやってみよう）
module fetch (
    input rst,
    input clk,
    input keep, //nopとかのときに一緒に使うやつでpcの維持など
    input nop,

    input branch_PC_early_contral,
    input branch_PC_contral,
    input [31:0] branch_PC_early,
    input [31:0] branch_PC,

    input iready_n,
    input [31:0] idata, //instractionのInstraction memoryからのinput

    output reg [31:0] iaddr, //pc, Instraction memoryへ渡す値
    output [31:0] Instraction_pype, //pc IF/IDに渡す値
    output [4:0] fornop_register1_pype,
    output [4:0] fornop_register2_pype, //早期分岐のための取り出し
    output reg [31:0] PC_pype0,
    output reg [31:0] PCp4_pype0
);

//assign Instraction_pype = idata;
assign Instraction_pype = nop ? 32'b0000000000000000000000000001001:idata;//is_nop周りはまだ未変更
assign fornop_register1_pype = /*nop ? 5'b10000 : */idata[19:15];
assign fornop_register2_pype = /*nop ? 5'b10000 : */idata[24:20];//register2の値がない命令についてはまだ未定 早期分岐じゃないなら基本いらないかも

    reg [31:0] next_iaddr;
    reg [31:0] next_PC_pype0;
    reg [31:0] next_PCp4_pype0;

always @(posedge clk) begin


    if (!rst) begin
        next_iaddr = 32'h0001_0000;
        next_PC_pype0 = 32'h0001_0000;
        next_PCp4_pype0 = 32'h0001_0004;
    end
    else if (keep) begin
        next_iaddr = iaddr;
        next_PC_pype0 = PC_pype0;
        next_PCp4_pype0 = PCp4_pype0;
    end

    else if (nop) begin
        if (branch_PC_early_contral)
            next_iaddr = branch_PC_early;
        else if (branch_PC_contral)
            next_iaddr = branch_PC;
        else
            next_iaddr = iaddr;

        next_PC_pype0 = PC_pype0;
        next_PCp4_pype0 = PCp4_pype0;
    end
    else begin
        if (branch_PC_early_contral)
            next_iaddr = branch_PC_early;
        else if (branch_PC_contral)
            next_iaddr = branch_PC;
        else
            next_iaddr = iaddr + 32'd4;
            next_PC_pype0 = next_iaddr;
            next_PCp4_pype0 = next_iaddr + 32'd4;
    end

    // 最後にまとめて代入！
    iaddr <= next_iaddr;
    PC_pype0 <= next_PC_pype0;
    PCp4_pype0 <= next_PCp4_pype0;
end

endmodule
