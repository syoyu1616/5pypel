`include "define.v"

module writeback(
    input rst,
    input clk,
    input keep, //nopとかのときに一緒に使うやつでpcの維持など
    input nop,

    input [31:0] PCp4_pype3,
    input [31:0] mem_data_pype,
    input [31:0] ALU_co_pype3,
    input [4:0] WReg_pype3,

    input RegWrite_pype3,
    input [1:0]MemtoReg_pype3,

    output  [31:0] write_reg_data,
    output  Regwrite,
    output  [4:0] write_reg_address

);

assign write_reg_data = 
        MemtoReg_pype3 == `write_reg_PCp4 ? PCp4_pype3 : //jalrのシングルラインの場合　パイプラインの場合mucを012まで増やすことを考慮
        MemtoReg_pype3 == `write_reg_memd ? mem_data_pype : ALU_co_pype3;

assign Regwrite = ~RegWrite_pype3;

assign write_reg_address = WReg_pype3;


endmodule