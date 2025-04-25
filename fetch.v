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
assign Instraction_pype = /*nop ? 32'b0000000000000000000000000001001 :*/ idata;//is_nop周りはまだ未変更
assign fornop_register1_pype = /*nop ? 5'b10000 : */idata[19:15];
assign fornop_register2_pype = /*nop ? 5'b10000 : */idata[24:20];//register2の値がない命令についてはまだ未定 早期分岐じゃないなら基本いらないかも

//PC_pypeの同期のために用意してる。分岐の際にどう振舞うかは注意
reg [31:0] iaddr_next;

always @(*) begin
    if (nop) begin
        if (branch_PC_early_contral)
            iaddr_next = branch_PC_early;
        else if (branch_PC_contral)
            iaddr_next = branch_PC;
        /*else
            iaddr_next = iaddr;*/

    end else if (!rst) begin
        iaddr_next = 32'h0001_0000;

    end else begin
        if (branch_PC_early_contral)
            iaddr_next = branch_PC_early;
        else if (branch_PC_contral)
            iaddr_next = branch_PC;
        else
            iaddr_next = iaddr + 4;
    end
end

always @(posedge clk) begin
    if (keep) begin
        PC_pype0     <= PC_pype0;
        PCp4_pype0   <= PCp4_pype0;
        iaddr        <= iaddr; //または何も代入しないでもOK
    end else begin
        PC_pype0     <= iaddr_next;
        PCp4_pype0   <= iaddr_next + 4;
        iaddr        <= iaddr_next;
    end
end


/*always @(posedge clk) begin
    // keep 

    
    if (keep) begin
        PC_pype0 <= PC_pype0;
        PCp4_pype0 <= PCp4_pype0;
    
    end

    else if (iready_n) begin //準備完了（0）になるまで値を維持
        PC_pype0 <= PC_pype0;
        PCp4_pype0 <= PCp4_pype0;
        iaddr <= iaddr;
    end

    // Pipeline nop(addi x0, x0, 0)
    else if (nop) begin
        PC_pype0 <= PC_pype0;
        PCp4_pype0 <= PCp4_pype0;

        if (branch_PC_early_contral)
            iaddr <= branch_PC_early;
        else if (branch_PC_contral)
            iaddr <= branch_PC;
        else
            iaddr <= iaddr;
    end

    // Reset
    else if (!rst) begin
        PC_pype0 <= 32'h0001_0000;
        PCp4_pype0 <= 32'h0001_0004;
        iaddr <= 32'h0001_0000;//10000から変えてみた
    end

    // Normal Fetch
    else begin
        PC_pype0 <= iaddr;//
        PCp4_pype0 <= iaddr + 32'd4;

    if (branch_PC_early_contral)
            iaddr <= branch_PC_early;
        else if (branch_PC_contral)
            iaddr <= branch_PC;
        else    
        iaddr <= iaddr + 32'd4;
    end


end*/

endmodule