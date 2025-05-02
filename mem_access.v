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

    //stall関連
    input [1:0] ID_EX_write_pype2,
    output reg [1:0] ID_EX_write_pype3,

    input [1:0] ID_EX_write_addi_pype2,
    output reg [1:0] ID_EX_write_addi_pype3,

    input [1:0] dsize_pype2,

    

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
    

    output reg [31:0] branch_PC,
    output reg branch_PC_contral,


    output reg [31:0] Instraction_pype3

);

//4/24 ロードが上手く待ててなさそうな問題について

assign dreq = |MemRW_pype2;
assign dwrite = MemRW_pype2[0];
assign daddr = ALU_co_pype;
assign dsize = dsize_pype2;


assign input_ddata = (MemRW_pype2[0]) ? read_data2_pype2 : 32'bz;
//inoutのddataに対してMemRW_pype2[0]が1(書き込み)ならddataにread_data2_pype2の値を代入。それ以外なら読み出したddataをmem_data_pypeに入れる

//assign mem_data_pype = (MemRW_pype2[1]) ? output_ddata : 32'bz;

reg keep_mem_data_updated;

//dready はop load  の時だけ止めさせるようにする
always @(posedge clk, negedge rst) begin

    if (nop) begin
        RegWrite_pype3 <= 1'b0;
        MemtoReg_pype3 <= 2'b0;
        WReg_pype3 <= 5'b0;
        ALU_co_pype3 <= 32'b0;
        PCp4_pype3 <= 32'b0;
        branch_PC <= 32'b0;
        branch_PC_contral <= 1'b0;
        Instraction_pype3 <= 32'b0;
        //MemRW_pype3 <= 2'b0;
        ID_EX_write_pype3 <= 0;
        ID_EX_write_addi_pype3 <= 0;
        mem_data_pype <= 32'b0;

        keep_mem_data_updated <= 0;

        /*dreq <= 0;
        dwrite <= 0;
        daddr <= 32'b0;
        input_ddata <= 32'b0;*/
    end
    
    else if (keep) begin
        RegWrite_pype3 <= RegWrite_pype3;
        MemtoReg_pype3 <= MemtoReg_pype3;
        WReg_pype3 <= WReg_pype3;
        ALU_co_pype3 <= ALU_co_pype3;
        PCp4_pype3 <= PCp4_pype3;
        branch_PC <= branch_PC;
        branch_PC_contral <= branch_PC_contral;
        Instraction_pype3 <= Instraction_pype3;
        ID_EX_write_pype3 <= ID_EX_write_pype3;
        ID_EX_write_addi_pype3 <= ID_EX_write_addi_pype3;

        //mem_data_pype <= (MemRW_pype2[1]) ? output_ddata : mem_data_pype;
        if (!keep_mem_data_updated && MemRW_pype2[1] && ^output_ddata !== 1'bx) begin
            mem_data_pype <= output_ddata;
            keep_mem_data_updated <= 1;
        end

        /*dreq <= dreq;
        dwrite <= dwrite;
        daddr <= daddr;
        input_ddata <= input_ddata;*/
    end



    else if (!rst) begin
        RegWrite_pype3 <= 1'b0;
        MemtoReg_pype3 <= 2'b0;
        WReg_pype3 <= 5'b0;
        ALU_co_pype3 <= 32'b0;
        PCp4_pype3 <= 32'b0;
        branch_PC <= 32'b0;
        branch_PC_contral <= 1'b0;
        Instraction_pype3 <= 32'b0;
        //MemRW_pype3 <= 2'b0;
        ID_EX_write_pype3 <= 0;
        keep_mem_data_updated <= 0;
        mem_data_pype <= 32'b0;
    end

    //メモリアクセス 書くときに確定で1クロック
//    dreq <= |MemRW_pype2;
//    dwrite <= MemRW_pype2[0];

//    daddr <= ALU_co_pype;
    //branch
    //Membranch_pype2が`MEMB_BEQかつALU_co_pypeが0, MemBranch_pyep2が`MEMB_BNEかつALU_co_pypeが0でないのどちらかなら1、それ以外は0
    else begin //ここにelseないと通常の処理にならないよ！
    if ((MemBranch_pype2 == 3'b001 && ALU_co_pype == 0) ||
    (MemBranch_pype2 == `MEMB_BNE && ALU_co_pype != 0) ||
    (MemBranch_pype2 == `MEMB_BGE && ALU_co_pype == 32'b0) ||
    (MemBranch_pype2 == `MEMB_BLT && ALU_co_pype == 32'b1 ) ||
    (MemBranch_pype2 == `MEMB_JAL)) begin
        branch_PC <= PCBranch_pype2;
        branch_PC_contral <= 1;
        // これで次の命令をnopに
    end else if (MemBranch_pype2 == `MEMB_JALR) begin
        branch_PC <= ALU_co_pype;
        branch_PC_contral <= 1;
    end else begin
        branch_PC_contral <= 0;
    end

    


    //横流し
    PCp4_pype3 <= PCp4_pype2;
    WReg_pype3 <= WReg_pype2;
    RegWrite_pype3 <= RegWrite_pype2;
    ALU_co_pype3 <= ALU_co_pype;

    Instraction_pype3 <= Instraction_pype2;
    MemtoReg_pype3 <= MemtoReg_pype2;
    ID_EX_write_pype3 <= ID_EX_write_pype2;
    ID_EX_write_addi_pype3 <= ID_EX_write_addi_pype2;

    mem_data_pype <= (keep_mem_data_updated) ? mem_data_pype:
                    (MemRW_pype2[1]) ? output_ddata : 32'bz;

    /*dreq <= |MemRW_pype2;
    dwrite <= MemRW_pype2[0];
    daddr <= ALU_co_pype;
    input_ddata <= (MemRW_pype2[0]) ? read_data2_pype2 : 32'bz;*/
    keep_mem_data_updated <= 0;





end
end

endmodule