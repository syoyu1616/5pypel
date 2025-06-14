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

    //missした時用
    input branch_miss_contral,
    input [31:0] branch_miss_PC,
   
    //分岐予測
    output [31:0] lookup_PC,//次の命令のpcを見てくる
    input is_branch_predict,
    input BTB_hit,
    input [31:0] BTB_PC,


    input [31:0] idata, //instractionのInstraction memoryからのinput

    output reg [31:0] iaddr, //pc, Instraction memoryへ渡す値
    output [31:0] Instraction_pype, //pc IF/IDに渡す値
    output [4:0] fornop_register1_pype,
    output [4:0] fornop_register2_pype, //早期分岐のための取り出し
    output reg [31:0] PC_pype0, 
    output reg [31:0] PCp4_pype0
);

assign lookup_PC = iaddr;

assign Instraction_pype = nop ? 32'b0000000000000000000000000001001:idata;//is_nop周りはまだ未変更
assign fornop_register1_pype = Instraction_pype[19:15];
assign fornop_register2_pype = Instraction_pype[24:20];

reg [31:0] next_iaddr;
reg [31:0] next_PC_pype0;
reg [31:0] next_PCp4_pype0;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        next_iaddr = 32'h0001_0000;
        next_PC_pype0 = 32'h0001_0000;
        next_PCp4_pype0 = 32'h0001_0004;
        iaddr <= next_iaddr;
        PC_pype0 <= next_PC_pype0;
        PCp4_pype0 <= next_PCp4_pype0;
        
    end

    else if (nop) begin
        if (branch_miss_contral) begin
            next_iaddr = branch_miss_PC;
            next_PC_pype0 = branch_miss_PC;
            next_PCp4_pype0 = branch_miss_PC + 32'd4;
            iaddr <= next_iaddr;
            PC_pype0 <= next_PC_pype0;
            PCp4_pype0 <= next_PCp4_pype0; 
        end

        else begin
            next_iaddr = iaddr;
            next_PC_pype0 = PC_pype0;
            next_PCp4_pype0 = PCp4_pype0;
            iaddr <= next_iaddr;
            PC_pype0 <= next_PC_pype0;
            PCp4_pype0 <= next_PCp4_pype0;
        end
    end

    else begin

        if (branch_miss_contral) begin
            next_iaddr = branch_miss_PC;
            next_PC_pype0 = branch_miss_PC;
            next_PCp4_pype0 = branch_miss_PC + 32'd4;
            iaddr <= next_iaddr;
            PC_pype0 <= next_PC_pype0;
            PCp4_pype0 <= next_PCp4_pype0;
        end

        if (is_branch_predict) begin //hitしてないのに分岐予測判定してるやつあるわ
            if (BTB_hit) begin
            next_iaddr = BTB_PC;
            next_PC_pype0 = BTB_PC;
            next_PCp4_pype0 = BTB_PC + 32'd4;
            iaddr <= next_iaddr;
            PC_pype0 <= next_PC_pype0;
            PCp4_pype0 <= next_PCp4_pype0;
        end
        else begin
            next_iaddr = iaddr + 32'd4;
            next_PC_pype0 = next_iaddr;
            next_PCp4_pype0 = next_iaddr + 32'd4;
            iaddr <= next_iaddr;
            PC_pype0 <= next_PC_pype0;
            PCp4_pype0 <= next_PCp4_pype0;
        end
        end

        else begin
            next_iaddr = iaddr + 32'd4;
            next_PC_pype0 = next_iaddr;
            next_PCp4_pype0 = next_iaddr + 32'd4;
            iaddr <= next_iaddr;
            PC_pype0 <= next_PC_pype0;
            PCp4_pype0 <= next_PCp4_pype0;
        end
    end
end
endmodule
