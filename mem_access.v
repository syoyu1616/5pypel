`include "define.v"
module mem_access(
    input rst,
    input clk,
    input keep, //nopとかのときに一緒に使うやつでpcの維持など
    input nop,

    input RegWrite_pype2,
    input [2:0] MemBranch_pype2,
    input [1:0] MemtoReg_pype2,
    input [1:0] MemRW_pype2,

    input [31:0] PCBranch_pype2,
    input [31:0] PCp4_pype2,
    input [31:0] ALU_co_pype,
    input [31:0] read_data2_pype2,
    input [4:0] WReg_pype2,

    input [31:0] Instraction_pype2,
    input [2:0] funct3_pype2,

    input [31:0] ALU_data1_pype2,
    input [31:0] ALU_data2_pype2,

    input [1:0] forwarding_stall_load_pyc_pype2,
    output reg [1:0] forwarding_stall_load_pyc_pype3,

    input [1:0] dsize_pype2,
    input [6:0] opcode_pype2,


    //memへの入出力
    output  [31:0] daddr,
    output  dreq,
    output  dwrite,
    output  [1:0] dsize,

    input dready_n,
    input dbusy,

    output [31:0] input_ddata,//cashから見てinput
    input [31:0] output_ddata,//cashから見てoutput

    output reg RegWrite_pype3,
    output reg [1:0] MemtoReg_pype3,
    output reg [4:0] WReg_pype3,
    output reg [31:0] ALU_co_pype3,
    output reg [31:0] PCp4_pype3,

    output reg [31:0]mem_data_pype,

    //output reg [1:0] MemRW_pype3,
    output  [31:0] branch_PC,
    output  branch_PC_contral,
    output reg [31:0] Instraction_pype3

);


assign dreq      = |MemRW_pype2;
assign dwrite    = MemRW_pype2[0];
assign daddr     = ALU_co_pype;
assign dsize     = dsize_pype2;
assign input_ddata = (MemRW_pype2[0]) ? read_data2_pype2: 32'bz;

assign branch_PC_contral =
    ((MemBranch_pype2 == 3'b001 && ALU_co_pype == 0) ||
     (MemBranch_pype2 == `MEMB_BNE && ALU_co_pype != 0) ||
     (MemBranch_pype2 == `MEMB_BGE && ALU_co_pype >= 0) ||
     (MemBranch_pype2 == `MEMB_BLT && ALU_co_pype < 0) ||
     (MemBranch_pype2 == 3'b110 && (ALU_data1_pype2[31] == ALU_data2_pype2[31] ?
                                    (ALU_co_pype >= 0) :
                                    (ALU_co_pype <= 0))) ||
     (MemBranch_pype2 == 3'b101 && (ALU_data1_pype2[31] == ALU_data2_pype2[31] ?
                                    (ALU_co_pype < 0) :
                                    (ALU_co_pype > 0))) ||
     //(MemBranch_pype2 == `MEMB_JAL) ||
     (MemBranch_pype2 == `MEMB_JALR));

assign branch_PC = (opcode_pype2 == 7'b1100111) ? ALU_co_pype :PCBranch_pype2;
                                                        

//dready はop load  の時だけ止めさせるようにする
always @(posedge clk, negedge rst) begin

    if (keep) begin
        RegWrite_pype3 <= RegWrite_pype3;
        MemtoReg_pype3 <= MemtoReg_pype3;
        WReg_pype3 <= WReg_pype3;
        ALU_co_pype3 <= ALU_co_pype3;
        PCp4_pype3 <= PCp4_pype3;
        Instraction_pype3 <= Instraction_pype3;
        mem_data_pype <=  mem_data_pype;
        forwarding_stall_load_pyc_pype3 <= forwarding_stall_load_pyc_pype3;

    end
    
    else if (nop) begin
        RegWrite_pype3 <= 1'b0;
        MemtoReg_pype3 <= 2'b0;
        WReg_pype3 <= 5'b0;
        ALU_co_pype3 <= 32'b0;
        PCp4_pype3 <= 32'b0;
        Instraction_pype3 <= 32'b0;
        mem_data_pype <= 32'b0;
        forwarding_stall_load_pyc_pype3 <= 2'b0;
    end



    else if (!rst) begin
        RegWrite_pype3 <= 1'b0;
        MemtoReg_pype3 <= 2'b0;
        WReg_pype3 <= 5'b0;
        ALU_co_pype3 <= 32'b0;
        PCp4_pype3 <= 32'b0;
        Instraction_pype3 <= 32'b0;
        mem_data_pype <= 32'b0;
        forwarding_stall_load_pyc_pype3 <= 2'b0;
    end


    else begin //ここにelseないと通常の処理にならないよ！

    //横流し
    RegWrite_pype3 <= RegWrite_pype2;
    MemtoReg_pype3 <= MemtoReg_pype2;
    WReg_pype3 <= WReg_pype2;
    ALU_co_pype3 <= ALU_co_pype;
    PCp4_pype3 <= PCp4_pype2;
    Instraction_pype3 <= Instraction_pype2;
    forwarding_stall_load_pyc_pype3 <= forwarding_stall_load_pyc_pype2;
    // mem_data_pype <= (MemRW_pype2[1]) ? output_ddata : 32'b0;
// を以下のように展開：

  if (MemRW_pype2[1]) begin  // 読み込み命令（load）
    case (funct3_pype2)
      3'b000: // LB
        mem_data_pype = {{24{output_ddata[7]}}, output_ddata[7:0]};
      3'b001: // LH
        mem_data_pype = {{16{output_ddata[15]}}, output_ddata[15:0]};
      3'b010: // LW
        mem_data_pype = output_ddata;
      3'b100: // LBU
        mem_data_pype = {{24{1'b0}}, output_ddata[7:0]};
      3'b101: // LHU
        mem_data_pype = {{16{1'b0}}, output_ddata[15:0]};
      default:
        mem_data_pype = 32'b0;  // エラー
    endcase
  end else begin
    mem_data_pype = 32'b0;
  end
end

end

endmodule