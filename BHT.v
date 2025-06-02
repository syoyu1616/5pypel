//Branch History Table
module BHT(
    input clk,
    input rst,
    input [31:0] lookup_PC,
    input [31:0] updata_PC,
    input updata_taken,
    input updata_enable,//分岐に次ぐ分岐の場合などに用いる？
    output predict_taken,
)

reg [1:0] bit_table [0:4095];
wire [11:0] updata_PC_use = updata_PC[13:2]; //PCを4096bitに収まる形でやるため
wire [11:0] lookup_PC_use = lookup_PC[13:2];

    assign predict_taken = (bit_table[lookup_PC_use][1] == 1) ? 1: 0;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 4096; i = i + 1) 
            bit_table[i] <= 2'b0;

        end else if (updata_enable) begin // "upload_enable" は "updata_enable" のタイポと仮定

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