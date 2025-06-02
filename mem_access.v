`include "define.v"
module mem_access(
    input rst,
    input clk,
    input keep, //nopとかのときに一緒に使うやつでpcの維持など
    input nop,

    input [2:0] writeback_control_pype2,
    input [1:0] MemRW_pype2,

    input [31:0] PCp4_pype2,
    input [31:0] ALU_co_pype,
    input [31:0] read_data2_pype2,
    input [4:0] WReg_pype2,

    input [2:0] funct3_pype2,

    input [1:0] forwarding_stall_load_pyc_pype2,
    output reg [1:0] forwarding_stall_load_pyc_pype3,
    input [1:0] dsize_pype2,

    //csrへの書き込み
    input is_csr_pype2,
    input [11:0] csr_pype2,
    input [31:0] csr_wdata_pype2,
    input is_ePC_pype2,
    
    output csr_we,
    output [11:0] csr_addr_w,
    output [31:0] csr_wdata,
    output is_epc,
  


    //memへの入出力
    output  [31:0] daddr,
    output  dreq,
    output  dwrite,
    output  [1:0] dsize,

    input dready_n,
    input dbusy,

    output [31:0] input_ddata,//cashから見てinput
    input [31:0] output_ddata,//cashから見てoutput

    output reg [2:0] writeback_control_pype3,
    output reg [4:0] WReg_pype3,
    output reg [31:0] ALU_co_pype3,
    output reg [31:0] PCp4_pype3,

    output reg [31:0]mem_data_pype
);


assign dreq      = |MemRW_pype2;
assign dwrite    = MemRW_pype2[0];
assign daddr     = ALU_co_pype;
assign dsize     = dsize_pype2;
assign input_ddata = (MemRW_pype2[0]) ? read_data2_pype2: 32'bz;

assign csr_we = is_csr_pype2;
assign csr_addr_w = csr_pype2;
assign csr_wdata = csr_wdata_pype2;
assign is_epc = is_ePC_pype2;

                                                        

//dready はop load  の時だけ止めさせるようにする
always @(posedge clk or negedge rst) begin

  if (!rst) begin
        writeback_control_pype3 <= 3'b0;
        WReg_pype3 <= 5'b0;
        ALU_co_pype3 <= 32'b0;
        PCp4_pype3 <= 32'b0;
        mem_data_pype <= 32'b0;
        forwarding_stall_load_pyc_pype3 <= 2'b0;
    end

    else if (keep) begin
        writeback_control_pype3 <= writeback_control_pype3;
        WReg_pype3 <= WReg_pype3;
        ALU_co_pype3 <= ALU_co_pype3;
        PCp4_pype3 <= PCp4_pype3;
        mem_data_pype <=  mem_data_pype;
        forwarding_stall_load_pyc_pype3 <= forwarding_stall_load_pyc_pype3;
        mem_data_pype <= mem_data_pype;
    end
    
    else if (nop) begin
        writeback_control_pype3 <= 3'b0;
        WReg_pype3 <= 5'b0;
        ALU_co_pype3 <= 32'b0;
        PCp4_pype3 <= 32'b0;
        mem_data_pype <= 32'b0;
        forwarding_stall_load_pyc_pype3 <= 2'b0;
    end


    else begin //ここにelseないと通常の処理にならないよ！
    //横流し
    writeback_control_pype3 <= writeback_control_pype2;
    WReg_pype3 <= WReg_pype2;
    ALU_co_pype3 <= ALU_co_pype;
    PCp4_pype3 <= PCp4_pype2;
    forwarding_stall_load_pyc_pype3 <= forwarding_stall_load_pyc_pype2;

  if (MemRW_pype2[1]) begin  // 読み込み命令（load）
    case (funct3_pype2)
      3'b000: // LB
        mem_data_pype <= {{24{output_ddata[7]}}, output_ddata[7:0]};
      3'b001: // LH
        mem_data_pype <= {{16{output_ddata[15]}}, output_ddata[15:0]};
      3'b010: // LW
        mem_data_pype <= output_ddata;
      3'b100: // LBU
        mem_data_pype <= {{24{1'b0}}, output_ddata[7:0]};
      3'b101: // LHU
        mem_data_pype <= {{16{1'b0}}, output_ddata[15:0]};
      default:
        mem_data_pype <= 32'bz;  // エラー
    endcase
  end else begin
    mem_data_pype <= 32'bz;
  end
end

end

endmodule