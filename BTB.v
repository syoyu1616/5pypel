//BBTを有意義に使うためのモジュール
//実行したことあるbranchならそうだと知らせる
module BTB (
    input clk,
    input rst,
    // 見たPCに対してBTBがあるかどうか
    input [31:0] lookup_PC, //fetchから
    output BTB_hit,
    output [31:0] BTB_PC,
    //解決したブランチのジャンプ先 branch系　PCが一致すれば同じ　ジャンプ系　jalrがx[rs1]の値を参照するため同じPCでも分岐先が異なる
    input [31:0] resolved_Branch_PC, //branchの時のPC_pype2;
    input [31:0] destination_PC,//branch_PCから引っ張ってくる
    input is_branch_inst, //|membranchから引っ張ってくる
    input updata_taken //成立したら更新
);

integer i;

/*//2^11で最上位ビットをtagに
reg [18:0] BTB_table [0:513];//20bitで目的PCは網羅できるかも tag lookup_pcを減らしてちゃんとあってるか(10056と10156の判別みたいな(三桁目を書いて+4とかあるかも))

wire [8:0] lookup_PC_use = lookup_PC[10:2];
wire [8:0] resolved_Branch_PC_use = resolved_Branch_PC[10:2];
wire [18:0] destination_PC_use = {resolved_Branch_PC[11], destination_PC [19:2]};

//BTBの出力機構
assign BTB_hit = ((BTB_table[lookup_PC_use] != 0) && (lookup_PC[11] == BTB_table[18])); //ちゃんとブランチ先があり、タグが一致するか？
assign BTB_PC = {{12'b0}, BTB_table[lookup_PC_use][17:0], 2'b0};
*/

reg [17:0] BTB_table [0:1023];//20bitで目的PCは網羅できるかも tag lookup_pcを減らしてちゃんとあってるか(10056と10156の判別みたいな(三桁目を書いて+4とかあるかも))

wire [9:0] lookup_PC_use = lookup_PC[11:2];
wire [9:0] resolved_Branch_PC_use = resolved_Branch_PC[11:2];
wire [17:0] destination_PC_use = destination_PC [19:2];

//BTBの出力機構
assign BTB_hit = (BTB_table[lookup_PC_use] != 0);// && (lookup_PC[11] == BTB_table[18])); //ちゃんとブランチ先があり、タグが一致するか？
assign BTB_PC = {{12'b0}, BTB_table[lookup_PC_use][17:0], 2'b0};

//BTBの更新機構
always @(posedge clk or negedge rst) begin
    if (!rst) begin
    for (i = 0; i < 1023; i = i + 1) 
            BTB_table[i] <= 18'b0;
    end 
    else if (is_branch_inst) begin 
        if (updata_taken)
        BTB_table[resolved_Branch_PC_use] <= destination_PC_use;
end
end 
endmodule