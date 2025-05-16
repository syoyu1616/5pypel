/*
5段PypeLine データパス RV32Iプロセッサ
*/

`include "regfile.v"
//`include "fetch.v" 
//`include "decode.v" 
//`include "execute.v"
//`include "mem_access.v"
`include "writeback.v"
`include "noper.v"

//opコードなんかの定義を事前にここで行ってる

//コアモジュール
module core(
    //各入出力信号の定義
    input        clk, 
    input        rst,

    input        dready_n, 
    input        iready_n,
    input        dbusy,
    input [31:0] idata,
    input [ 2:0] oint_n,

    output[31:0] daddr,
    output[31:0] iaddr,
    output[ 1:0] dsize,
    output       dreq,
    output       dwrite,
    output       iack_n,
    
    inout [31:0] ddata
);

	integer i;
    //こいつを設定する必要あり
    //assign dsize = 2'b10;
    assign iack_n = 1'b1;
  
    wire [4:0] WReg_pype;
    wire [1:0] ID_EX_write_pype2, ID_EX_write_pype3, ID_EX_write;
    wire [1:0] ID_EX_write_addi_pype1, ID_EX_write_addi_pype2, ID_EX_write_addi_pype3, ID_EX_write_addi, ID_EX_write_rw;
    wire stall_IF, stall_ID, stall_EX, stall_Mem, stall_WB;
    wire nop_IF, nop_ID, nop_EX, nop_Mem, nop_WB;
    wire [6:0] opcode_pype1,opcode_pype2,opcode_pype3;
    wire [31:0] forwarding_ID_EX_data, forwarding_ID_MEM_data, forwarding_ID_MEM_hazard_data, forwarding_load_data;
    wire [1:0] forwarding_ID_EX_pyc, forwarding_ID_MEM_pyc, forwarding_ID_MEM_hazard_pyc, forwarding_stall_load_pyc, forwarding_stall_load_pyc_pype2, forwarding_stall_load_pyc_pype3;

//fetch
    wire branch_PC_early_contral, branch_PC_contral;
	wire [31:0] branch_PC_early, branch_PC;
    wire [31:0] Instraction_pype, Instraction_pype1, Instraction_pype2, Instraction_pype3, PC_pype0, PCp4_pype0;
    wire [4:0] fornop_register1_pype, fornop_register2_pype;

    wire [31:0] read_data1, read_data2, read_data1_pype, read_data2_pype;
    wire [4:0] read_reg1, read_reg2;
    wire [31:0] PC_pype1, PCp4_pype1, Imm_pype;
    wire [3:0] for_ALU_c;


//decode   
    wire RegWrite_pype1;
    wire [1:0] MemtoReg_pype1, MemRW_pype1;
    wire [2:0] MemBranch_pype, ALU_Src_pype;
    wire [6:0] ALU_command_7;
    wire [4:0] fornop_register1_pype1, fornop_register2_pype1;
    wire [2:0] funct3_pype1, funct3_pype2;
    wire [3:0] ALU_control_pype;
    
//execute
    wire [31:0] PCp4_pype2, ALU_co_pype, read_data2_pype2, PCBranch_pype2;
    wire [4:0] WReg_pype2;
    wire [2:0] MemBranch_pype2;
    wire [1:0] MemtoReg_pype2, MemRW_pype2;
    wire RegWrite_pype2;
    wire [1:0] dsize_pype2;
    wire [31:0] ALU_data1_pype2, ALU_data2_pype2;

//mem
    wire[31:0] ALU_co_pype3, PCp4_pype3, mem_data_pype;
    wire[4:0] WReg_pype3;
    wire[1:0] MemtoReg_pype3, MemRW_pype3;
    wire RegWrite_pype3, branch_nop;

    wire [31:0] input_ddata;  // input用の信号
    wire [31:0] output_ddata; // output用の信号

//regfile
    wire[4:0] rs1, rs2, write_reg_address;
    wire[31:0] write_reg_data;
    wire Regwrite;


noper noper_unit (
    .clk(clk),
    .rst(rst),
    // 読み取りレジスタ（IDステージから）
    .fornop_register1_pype (fornop_register1_pype),
    .fornop_register2_pype (fornop_register2_pype),
    .fornop_register1_pype1 (fornop_register1_pype1),
    .fornop_register2_pype1 (fornop_register2_pype1),

    // 書き込み情報（EX, MEM, WBステージ）
    .WReg_pype     (WReg_pype),
    .WReg_pype2    (WReg_pype2),
    .WReg_pype3    (WReg_pype3),
    .RegWrite_pype1 (RegWrite_pype1),
    .RegWrite_pype2 (RegWrite_pype2),
    .RegWrite_pype3 (RegWrite_pype3),
    .Instraction_pype (Instraction_pype),

    .Regwrite    (Regwrite),
    .write_reg_address  (write_reg_address),

    .ID_EX_write_rw  (ID_EX_write_rw),

    // 分岐成立
    .branch_PC_contral (branch_PC_contral),

    //forwarding
    .opcode_pype1(opcode_pype1),
    .opcode_pype2(opcode_pype2),
    .opcode_pype3(opcode_pype3),
    .ALU_co_pype(ALU_co_pype),
    .ALU_co_pype3(ALU_co_pype3),
    .write_reg_data(write_reg_data),
    .mem_data_pype(mem_data_pype),

    .forwarding_ID_EX_data(forwarding_ID_EX_data),
    .forwarding_ID_MEM_data(forwarding_ID_MEM_data),
    .forwarding_ID_MEM_hazard_data(forwarding_ID_MEM_hazard_data),
    .forwarding_load_data(forwarding_load_data),
    .forwarding_ID_EX_pyc(forwarding_ID_EX_pyc),
    .forwarding_ID_MEM_pyc(forwarding_ID_MEM_pyc),
    .forwarding_ID_MEM_hazard_pyc(forwarding_ID_MEM_hazard_pyc),
    .forwarding_stall_load_pyc_pype2(forwarding_stall_load_pyc_pype2),

    //メモリアクセスに関するストール
    .iready_n(iready_n),
    .dready_n(dready_n),
    .dbusy(dbusy),
    .MemRW_pype1(MemRW_pype1),
    .MemRW_pype2(MemRW_pype2),

    // 出力: stall制御
    .stall_IF  (stall_IF),
    .stall_ID  (stall_ID),
    .stall_EX  (stall_EX),
    .stall_Mem (stall_Mem),
    .stall_WB  (stall_WB),

    // 出力: nop制御
    .nop_IF  (nop_IF),
    .nop_ID  (nop_ID),
    .nop_EX  (nop_EX),
    .nop_Mem (nop_Mem),
    .nop_WB  (nop_WB)
);

    fetch i_fetch(.clk(clk), .rst(rst), .keep(stall_IF), .nop(nop_IF), 
    .branch_PC_early_contral(branch_PC_early_contral), 
    .branch_PC_contral(branch_PC_contral), 
    .iready_n(iready_n), 
    .branch_PC_early(branch_PC_early), 
    .branch_PC(branch_PC), 
    .idata(idata), 
    .iaddr(iaddr), 
    .Instraction_pype(Instraction_pype), 
    .PC_pype0(PC_pype0), 
    .PCp4_pype0(PCp4_pype0),
    .fornop_register1_pype(fornop_register1_pype), 
    .fornop_register2_pype(fornop_register2_pype));


    decode i_decode(.rst(rst), .clk(clk), .keep(stall_ID), .nop(nop_ID),
    .PC_pype0(PC_pype0), 
    .PCp4_pype0(PCp4_pype0), 
    .Instraction_pype(Instraction_pype),
    .read_data1(read_data1), 
    .read_data2(read_data2), 
    .read_data1_pype(read_data1_pype), 
    .read_data2_pype(read_data2_pype),
    .read_reg1(read_reg1), 
    .read_reg2(read_reg2),
    .ID_EX_write_rw (ID_EX_write_rw),
    .forwarding_ID_MEM_pyc (forwarding_ID_MEM_pyc),
    .write_reg_data(write_reg_data),
    .fornop_register1_pype(fornop_register1_pype),
    .fornop_register2_pype(fornop_register2_pype),
    .Regwrite(Regwrite),

    .fornop_register1_pype1(fornop_register1_pype1),
    .fornop_register2_pype1(fornop_register2_pype1),
    .PC_pype1(PC_pype1), 
    .PCp4_pype1(PCp4_pype1), 
    .Imm_pype(Imm_pype),
    .for_ALU_c(for_ALU_c), 
    .WReg_pype(WReg_pype), 
    .RegWrite_pype1(RegWrite_pype1), 
    .MemtoReg_pype1(MemtoReg_pype1),
    .MemRW_pype1(MemRW_pype1), 
    .MemBranch_pype(MemBranch_pype), 
    .ALU_control_pype(ALU_control_pype), 
    .ALU_Src_pype(ALU_Src_pype),
    .ALU_command_7(ALU_command_7), 
    .Instraction_pype1(Instraction_pype1),
    .opcode_pype1(opcode_pype1),
    .funct3_pype1(funct3_pype1));

    execute i_execute(.rst(rst), .clk(clk), .keep(stall_EX), .nop(nop_EX), 
    .PC_pype1(PC_pype1), 
    .PCp4_pype1(PCp4_pype1),
    .read_data1_pype(read_data1_pype), 
    .read_data2_pype(read_data2_pype), 
    .Imm_pype(Imm_pype), 
    .for_ALU_c(for_ALU_c),
    .WReg_pype(WReg_pype), 
    .Instraction_pype1(Instraction_pype1), 
    .opcode_pype1(opcode_pype1),
    .forwarding_ID_EX_data(forwarding_ID_EX_data),
    .forwarding_ID_MEM_data(forwarding_ID_MEM_data),
    .forwarding_ID_MEM_hazard_data(forwarding_ID_MEM_hazard_data),
    .forwarding_load_data(forwarding_load_data),
    .forwarding_ID_EX_pyc(forwarding_ID_EX_pyc),
    .forwarding_ID_MEM_pyc(forwarding_ID_MEM_pyc),
    .forwarding_ID_MEM_hazard_pyc(forwarding_ID_MEM_hazard_pyc),
    .forwarding_stall_load_pyc(forwarding_stall_load_pyc),
    .funct3_pype1(funct3_pype1),

    .opcode_pype2(opcode_pype2),
    .RegWrite_pype1(RegWrite_pype1), 
    .MemtoReg_pype1(MemtoReg_pype1), 
    .MemRW_pype1(MemRW_pype1),
    .MemBranch_pype(MemBranch_pype), 
    .ALU_control_pype(ALU_control_pype),
    .ALU_Src_pype(ALU_Src_pype), 
    .ALU_command_7(ALU_command_7),
    .PCBranch_pype2(PCBranch_pype2), 
    .PCp4_pype2(PCp4_pype2), 
    .ALU_co_pype(ALU_co_pype), 
    .read_data2_pype2(read_data2_pype2), 
    .WReg_pype2(WReg_pype2),
    .RegWrite_pype2(RegWrite_pype2), 
    .MemtoReg_pype2(MemtoReg_pype2), 
    .MemRW_pype2(MemRW_pype2), 
    .MemBranch_pype2(MemBranch_pype2),
    .Instraction_pype2(Instraction_pype2),
    .dsize_pype2(dsize_pype2),
    .funct3_pype2(funct3_pype2),
    .ALU_data1_pype2(ALU_data1_pype2),
    .ALU_data2_pype2(ALU_data2_pype2));


    assign output_ddata = ddata;  // キャッシュから見てoutputの奴をinoutから回収

    mem_access i_mem_access (.rst(rst), .clk(clk), .keep(stall_Mem), .nop(nop_Mem), 
    .RegWrite_pype2 (RegWrite_pype2),
    .MemBranch_pype2 (MemBranch_pype2), 
    .MemtoReg_pype2 (MemtoReg_pype2), 
    .MemRW_pype2 (MemRW_pype2),
    .PCBranch_pype2(PCBranch_pype2), 
    .PCp4_pype2(PCp4_pype2), 
    .ALU_co_pype(ALU_co_pype), 
    .read_data2_pype2(read_data2_pype2),
    .WReg_pype2 (WReg_pype2), 
    .Instraction_pype2(Instraction_pype2), 
    .input_ddata(input_ddata),
    .dsize_pype2(dsize_pype2),
    .forwarding_stall_load_pyc_pype2(forwarding_stall_load_pyc_pype2),
    .funct3_pype2(funct3_pype2),
    .ALU_data1_pype2(ALU_data1_pype2),
    .ALU_data2_pype2(ALU_data2_pype2),
    .opcode_pype2(opcode_pype2),

    .forwarding_stall_load_pyc_pype3(forwarding_stall_load_pyc_pype3),
    .output_ddata(output_ddata),
    .daddr (daddr), 
    .dreq(dreq), 
    .dwrite(dwrite), 
    .dready_n(dready_n),
    .dbusy (dbusy),  
    .dsize (dsize),
    .RegWrite_pype3(RegWrite_pype3), 
    .MemtoReg_pype3(MemtoReg_pype3), 
    .WReg_pype3(WReg_pype3),
    .ALU_co_pype3(ALU_co_pype3), 
    .PCp4_pype3(PCp4_pype3), 
    .mem_data_pype(mem_data_pype), 
    .branch_PC(branch_PC),
    .branch_PC_contral(branch_PC_contral), 
    .Instraction_pype3(Instraction_pype3));

    // inout信号をinput/output信号に分けて処理
    assign ddata = input_ddata; // キャッシュから見てinputの奴をinoutに入れる


    writeback i_writeback (.rst(rst), .clk(clk), .keep(stall_WB), .nop(nop_WB),
    .PCp4_pype3(PCp4_pype3),
    .mem_data_pype(mem_data_pype),
    .ALU_co_pype3(ALU_co_pype3),
    .WReg_pype3(WReg_pype3),
    .RegWrite_pype3(RegWrite_pype3),
    .MemtoReg_pype3(MemtoReg_pype3),
    .ID_EX_write_pype3(ID_EX_write_pype3),
    .ID_EX_write_addi_pype3 (ID_EX_write_addi_pype3),
    .forwarding_stall_load_pyc_pype3(forwarding_stall_load_pyc_pype3),

    .forwarding_stall_load_pyc  (forwarding_stall_load_pyc),
    .write_reg_data    (write_reg_data),
    .Regwrite          (Regwrite),
    .write_reg_address (write_reg_address),
    .ID_EX_write(ID_EX_write),
    .ID_EX_write_addi (ID_EX_write_addi));

    regfile i_regfile(
    .clk(clk), .rst(rst), .write_n(Regwrite),
    .rs1(read_reg1), .rs2(read_reg2), .rd(write_reg_address),
    .in(write_reg_data),
    .out1(read_data1), .out2(read_data2));

endmodule