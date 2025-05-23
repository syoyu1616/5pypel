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

    //input RegWrite_pype3,
    //input [1:0]MemtoReg_pype3,
    input [2:0] writeback_control_pype3,
    input [1:0] forwarding_stall_load_pyc_pype3,


    output  [31:0] write_reg_data,
    output  Regwrite,
    output  [4:0] write_reg_address,
    output  [1:0] forwarding_stall_load_pyc
);

assign write_reg_data = 
    /*(MemtoReg_pype3 == `write_reg_PCp4) ? PCp4_pype3 :
    (MemtoReg_pype3 == `write_reg_memd) ? mem_data_pype :
    (MemtoReg_pype3 == `write_reg_ALUc) ? ALU_co_pype3 :*/
    (writeback_control_pype3[1:0] == 2'b10) ? PCp4_pype3 :
    (writeback_control_pype3[1:0] == 2'b01) ? mem_data_pype :
    (writeback_control_pype3[1:0] == 2'b00) ? ALU_co_pype3 :
    32'bx;  // デフォルト（エラー時はxにするか、0にしてもOK）


//assign Regwrite = ~RegWrite_pype3;
assign Regwrite = ~writeback_control_pype3[2];


assign write_reg_address = WReg_pype3;

assign forwarding_stall_load_pyc = forwarding_stall_load_pyc_pype3;



endmodule