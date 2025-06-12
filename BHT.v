//Branch History Table
//predict_takenで実際に分岐予測させるかを演算
module BHT(
    input clk,
    input rst,
    input [31:0] lookup_PC, //fetchから
    input [31:0] updata_PC, //branchの時のPC_pype2;
    input updata_taken, //branch成立しましたか？ branch_PC_contralを引っ張ってくる
    input updata_enable, //branchですか？　|membranchを引っ張ってくる
    output predict_taken
);
integer i;

/*reg [1:0] bit_table [0:1023];
wire [9:0] updata_PC_use = updata_PC[11:2]; //PCを4096bitに収まる形でやるため
wire [9:0] lookup_PC_use = lookup_PC[11:2];*/

reg [1:0] bit_table [0:1023];
wire [9:0] updata_PC_use = updata_PC[11:2]; //PCを4096bitに収まる形でやるため
wire [9:0] lookup_PC_use = lookup_PC[11:2];

    assign predict_taken = (bit_table[lookup_PC_use][1] == 1) ? 1: 0;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 1023; i = i + 1) 
            bit_table[i] <= 2'b01;//最初はweakly not taken

        end else if (updata_enable) begin 
        case (bit_table[updata_PC_use]) // updata_PCから計算したインデックスを使用
            2'b00: begin // 現在: Strongly Not Taken
                if (updata_taken)
                    bit_table[updata_PC_use] <= 2'b01; // 分岐したら Weakly Not Taken へ
                // 分岐しなければ 2'b00 のまま (飽和)
            end
            2'b01: begin // 現在: Weakly Not Taken
                if (updata_taken)
                    bit_table[updata_PC_use] <= 2'b10; // 分岐したら Weakly Taken へ
                else
                    bit_table[updata_PC_use] <= 2'b00; // 分岐しなければ Strongly Not Taken へ
            end
            2'b10: begin // 現在: Weakly Taken
                if (updata_taken)
                    bit_table[updata_PC_use] <= 2'b11; // 分岐したら Strongly Taken へ
                else
                    bit_table[updata_PC_use] <= 2'b01; // 分岐しなければ Weakly Not Taken へ
            end
            2'b11: begin // 現在: Strongly Taken
                if (!updata_taken)
                    bit_table[updata_PC_use] <= 2'b10; // 分岐しなければ Weakly Taken へ
                // 分岐したら 2'b11 のまま (飽和)
            end
            default: bit_table[updata_PC_use] <= 2'b00; 
        endcase
    end
end
endmodule