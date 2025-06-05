/*
5段PypeLine データパス RV32Iプロセッサ
*/

`include "regfile.v"
`include "writeback.v"
`include "noper.v"
`include "csr_reg.v"
`include "BHT.v"
`include "BTB.v"

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

    output [31:0] branch_count,
    output [31:0] branch_miss_count,


    inout [31:0] ddata
);

	integer i;
    //こいつを設定する必要あり

    assign iack_n = 1'b1;

  
    wire [4:0] WReg_pype;
    wire [2:0] writeback_control_pype1, writeback_control_pype2, writeback_control_pype3;
    wire [1:0] ID_EX_write_rw;
    wire stall_IF, stall_ID, stall_EX, stall_Mem, stall_WB;
    wire nop_IF, nop_ID, nop_EX, nop_Mem, nop_WB;

    wire [31:0] forwarding_ID_EX_data, forwarding_ID_MEM_data, forwarding_ID_MEM_hazard_data, forwarding_load_data;
    wire [1:0] forwarding_ID_EX_pyc, forwarding_ID_MEM_pyc, forwarding_ID_MEM_hazard_pyc, forwarding_stall_load_pyc, forwarding_stall_load_pyc_pype2, forwarding_stall_load_pyc_pype3;

//fetch
    wire branch_PC_early_contral, branch_PC_contral;
	wire [31:0] branch_PC_early, branch_PC;
    wire [31:0] Instraction_pype, PC_pype0, PCp4_pype0;
    wire [4:0] fornop_register1_pype, fornop_register2_pype;


//decode   
    wire [1:0] MemRW_pype1;
    wire [2:0] MemBranch_pype, ALU_Src_pype;
    wire [31:0] read_data1, read_data2, read_data1_pype, read_data2_pype;
    wire [4:0] read_reg1, read_reg2;
    wire [31:0] PC_pype1, PCp4_pype1, Imm_pype;
    wire [2:0] funct3_pype1, funct3_pype2;
    wire [3:0] ALU_control_pype;
    
//execute
    wire [31:0] PCp4_pype2, ALU_co_pype, read_data2_pype2, PCBranch_pype2;
    wire [4:0] WReg_pype2;
    wire [2:0] MemBranch_pype2;
    wire [1:0] MemRW_pype2;
    wire [1:0] dsize_pype2;
    wire [31:0] ALU_data1_pype2, ALU_data2_pype2;

//mem
    wire [31:0] ALU_co_pype3, PCp4_pype3, mem_data_pype;
    wire [4:0] WReg_pype3;
    wire [1:0] MemRW_pype3;
    wire [31:0] input_ddata;  // input用の信号
    wire [31:0] output_ddata; // output用の信号

//regfile
    wire [4:0] rs1, rs2, write_reg_address;
    wire [31:0] write_reg_data;
    wire Regwrite;

//csr_reg
    wire csr_we, is_csr_pype1, is_csr_pype2;
    wire [11:0] csr_pype1, csr_pype2, csr_addr_r, csr_addr_w;
    wire [31:0] csr_wdata, csr_wdata_pype2, csr_rdata, csr_rdata_pype1; //, csr_mtvec, csr_mepc; 
    wire csr_PC_contral;
    wire [31:0] csr_PC;
    wire is_epc, is_ePC_pype2;

//分岐予測
    wire [31:0] lookup_PC, PC_pype2, BTB_PC, branch_BTB_PC;
    wire branch_BTB_contral, is_branch_pype2, predict_taken, BTB_hit;
    wire [31:0] branch_miss_PC;
    wire branch_miss_contral;
    wire [31:0] PC_Np_pype0, PC_Np_pype1, PC_Np_pype2;
    

noper noper_unit (
    .clk(clk),
    .rst(rst),
    // 読み取りレジスタ（IDステージから）
    .fornop_register1_pype (fornop_register1_pype),
    .fornop_register2_pype (fornop_register2_pype),

    // 書き込み情報（EX, MEM, WBステージ）
    .WReg_pype     (WReg_pype),
    .WReg_pype2    (WReg_pype2),
    .WReg_pype3    (WReg_pype3),
    .writeback_control_pype1(writeback_control_pype1),
    .writeback_control_pype2(writeback_control_pype2),
    .writeback_control_pype3(writeback_control_pype3),

    .ID_EX_write_rw  (ID_EX_write_rw),

    // 分岐成立
    .branch_miss_contral(branch_miss_contral),

    //分岐予測担って必要に
    .MemBranch_pype2(MemBranch_pype2),
    .PCp4_pype2(PCp4_pype2),
    //forwarding
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
    .branch_miss_contral(branch_miss_contral),
    .branch_miss_PC(branch_miss_PC),
    .is_branch_predict(predict_taken),
    .BTB_hit(BTB_hit),
    .BTB_PC(BTB_PC),
    .idata(idata), 

    .iaddr(iaddr), 
    .Instraction_pype(Instraction_pype), 
    .PC_pype0(PC_pype0), 
    .PCp4_pype0(PCp4_pype0),
    .fornop_register1_pype(fornop_register1_pype), 
    .fornop_register2_pype(fornop_register2_pype),
    .lookup_PC(lookup_PC)
    );

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
    .write_reg_data(write_reg_data),
    .fornop_register1_pype(fornop_register1_pype),
    .fornop_register2_pype(fornop_register2_pype),
    .Regwrite(Regwrite),
    .forwarding_ID_EX_pyc(forwarding_ID_EX_pyc),
    .forwarding_ID_MEM_pyc(forwarding_ID_MEM_pyc),
    .forwarding_stall_load_pyc(forwarding_stall_load_pyc),
    .forwarding_ID_MEM_hazard_pyc(forwarding_ID_MEM_hazard_pyc),
    .forwarding_ID_EX_data(forwarding_ID_EX_data),
    .forwarding_ID_MEM_data(forwarding_ID_MEM_data),
    .forwarding_load_data(forwarding_load_data),
    .forwarding_ID_MEM_hazard_data(forwarding_ID_MEM_hazard_data),
    .csr_rdata(csr_rdata),
    .MemRW_pype2(MemRW_pype2),
    .is_branch_predict(predict_taken),
    .BTB_hit(BTB_hit),

    .PC_pype1(PC_pype1), 
    .PCp4_pype1(PCp4_pype1), 
    .Imm_pype(Imm_pype),
    .WReg_pype(WReg_pype), 
    .writeback_control_pype1(writeback_control_pype1),
    .MemRW_pype1(MemRW_pype1), 
    .MemBranch_pype(MemBranch_pype), 
    .ALU_control_pype(ALU_control_pype), 
    .ALU_Src_pype(ALU_Src_pype),
    .is_csr_pype1(is_csr_pype1),
    .csr_pype1(csr_pype1),
    .is_ecall_pype1(is_ecall_pype1),
    .is_mret_pype1(is_mret_pype1),
    .csr_addr_r(csr_addr_r),
    .csr_rdata_pype1(csr_rdata_pype1),
    .funct3_pype1(funct3_pype1),
    .is_branch_predict_pype1(is_branch_predict_pype1)
    );

    execute i_execute(.rst(rst), .clk(clk), .keep(stall_EX), .nop(nop_EX), 
    .PC_pype1(PC_pype1), 
    .PCp4_pype1(PCp4_pype1),
    .read_data1_pype(read_data1_pype), 
    .read_data2_pype(read_data2_pype), 
    .Imm_pype(Imm_pype), 
    .WReg_pype(WReg_pype), 
    .forwarding_ID_EX_data(forwarding_ID_EX_data),
    .forwarding_ID_MEM_data(forwarding_ID_MEM_data),
    .forwarding_ID_MEM_hazard_data(forwarding_ID_MEM_hazard_data),
    .forwarding_load_data(forwarding_load_data),
    .forwarding_ID_EX_pyc(forwarding_ID_EX_pyc),
    .forwarding_ID_MEM_pyc(forwarding_ID_MEM_pyc),
    .forwarding_ID_MEM_hazard_pyc(forwarding_ID_MEM_hazard_pyc),
    .forwarding_stall_load_pyc(forwarding_stall_load_pyc),
    .funct3_pype1(funct3_pype1),
    .writeback_control_pype1(writeback_control_pype1),
    .MemRW_pype1(MemRW_pype1),
    .MemBranch_pype(MemBranch_pype), 
    .ALU_control_pype(ALU_control_pype),
    .ALU_Src_pype(ALU_Src_pype), 
    .is_csr_pype1(is_csr_pype1),
    .csr_pype1(csr_pype1),
    .is_ecall_pype1(is_ecall_pype1),
    .is_mret_pype1(is_mret_pype1),
    .csr_rdata_pype1(csr_rdata_pype1),
    .is_branch_predict_pype1(is_branch_predict_pype1),

    .PCBranch_pype2(PCBranch_pype2), 
    .PCp4_pype2(PCp4_pype2), 
    .ALU_co_pype(ALU_co_pype), 
    .read_data2_pype2(read_data2_pype2), 
    .WReg_pype2(WReg_pype2),
    .writeback_control_pype2(writeback_control_pype2),
    .MemRW_pype2(MemRW_pype2), 
    .MemBranch_pype2(MemBranch_pype2),
    .dsize_pype2(dsize_pype2),
    .funct3_pype2(funct3_pype2),
    .is_csr_pype2(is_csr_pype2),
    .csr_pype2(csr_pype2),
    .csr_wdata_pype2(csr_wdata_pype2),
    .is_ePC_pype2(is_ePC_pype2),
    .branch_miss_contral(branch_miss_contral),
    .branch_miss_PC(branch_miss_PC),
    .branch_BTB_PC(branch_BTB_PC),
    .branch_BTB_contral(branch_BTB_contral),
    .is_branch_pype2(is_branch_pype2),
    .PC_pype2(PC_pype2),
    .branch_count(branch_count),
    .branch_miss_count(branch_miss_count)
    );


    assign output_ddata = ddata;  // キャッシュから見てoutputの奴をinoutから回収

    mem_access i_mem_access (.rst(rst), .clk(clk), .keep(stall_Mem), .nop(nop_Mem), 
    .writeback_control_pype2(writeback_control_pype2),
    .MemRW_pype2 (MemRW_pype2),
    .PCp4_pype2(PCp4_pype2), 
    .ALU_co_pype(ALU_co_pype), 
    .read_data2_pype2(read_data2_pype2),
    .WReg_pype2 (WReg_pype2), 
    .input_ddata(input_ddata),
    .dsize_pype2(dsize_pype2),
    .forwarding_stall_load_pyc_pype2(forwarding_stall_load_pyc_pype2),
    .funct3_pype2(funct3_pype2),
    .is_csr_pype2(is_csr_pype2),
    .csr_pype2(csr_pype2),
    .csr_wdata_pype2(csr_wdata_pype2),
    .is_ePC_pype2(is_ePC_pype2),

    .forwarding_stall_load_pyc_pype3(forwarding_stall_load_pyc_pype3),
    .output_ddata(output_ddata),
    .daddr (daddr), 
    .dreq(dreq), 
    .dwrite(dwrite), 
    .dready_n(dready_n),
    .dbusy (dbusy),  
    .dsize (dsize),
    .writeback_control_pype3(writeback_control_pype3),
    .WReg_pype3(WReg_pype3),
    .ALU_co_pype3(ALU_co_pype3), 
    .PCp4_pype3(PCp4_pype3), 
    .mem_data_pype(mem_data_pype),
    .csr_we(csr_we),
    .csr_addr_w(csr_addr_w),
    .csr_wdata(csr_wdata),
    .is_epc(is_epc)
    );

    // inout信号をinput/output信号に分けて処理
    assign ddata = input_ddata; // キャッシュから見てinputの奴をinoutに入れる

    writeback i_writeback (.rst(rst), .clk(clk), .keep(stall_WB), .nop(nop_WB),
    .PCp4_pype3(PCp4_pype3),
    .mem_data_pype(mem_data_pype),
    .ALU_co_pype3(ALU_co_pype3),
    .WReg_pype3(WReg_pype3),
    .writeback_control_pype3(writeback_control_pype3),
    .forwarding_stall_load_pyc_pype3(forwarding_stall_load_pyc_pype3),

    .forwarding_stall_load_pyc  (forwarding_stall_load_pyc),
    .write_reg_data    (write_reg_data),
    .Regwrite          (Regwrite),
    .write_reg_address (write_reg_address));


    regfile i_regfile(
    .clk(clk), .rst(rst), .write_n(Regwrite),
    .rs1(read_reg1), .rs2(read_reg2), .rd(write_reg_address),
    .in(write_reg_data),
    .out1(read_data1), .out2(read_data2));

    csr_reg i_csr_reg(
    .clk(clk), .rst(rst), 
    .csr_we(csr_we),
    .csr_addr_r(csr_addr_r),
    .csr_addr_w(csr_addr_w),
    .csr_wdata(csr_wdata),
    .csr_rdata(csr_rdata)
    );

    BHT i_BHT(
    .clk(clk), .rst(rst),
    .lookup_PC(lookup_PC),
    .updata_PC(PC_pype2),
    .updata_taken(branch_BTB_contral),
    .updata_enable(is_branch_pype2),
    .predict_taken(predict_taken)
    );

    BTB i_BTB(
    .clk(clk), .rst(rst),
    .lookup_PC(lookup_PC),
    .BTB_hit(BTB_hit),
    .BTB_PC(BTB_PC),
    .resolved_Branch_PC(PC_pype2),
    .destination_PC(branch_BTB_PC),
    .is_branch_inst(is_branch_pype2),
    .updata_taken(branch_BTB_contral)
    );

endmodule