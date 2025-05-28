
//`ifndef CSR_REG_V
//`define CSR_REG_V

module csr_reg (
    input clk,
    input rst,
    input csr_we,                            // CSR 書き込み有効信号

    input [11:0] csr_addr_w, 
    input [11:0] csr_addr_r,    // CSR アドレス
    input [31:0] csr_wdata,        // 書き込みデータ
    output [31:0] csr_rdata       // 読み出しデータ

    // Standard CSRs for mecall
    //output [data_width-1:0] csr_mtvec,      // CSR: mtvec (アドレス: 0x305)
    //output [data_width-1:0] csr_mepc       // CSR: mepc  (アドレス: 0x341)
    //output [data_width-1:0] csr_mcause,     // CSR: mcause (アドレス: 0x342) - 追加
    //output [data_width-1:0] csr_mstatus     // CSR: mstatus (アドレス: 0x300) - 追加
);

    // CSRレジスタファイル
    reg [31:0] csr_regs [12'h300:12'h350]; // 要素数 csr_num (インデックス 0 から csr_num-1) // 要素数 4096 (インデックス 0 から 4095) data_width は各レジスタのビット幅
    integer i;

    // 読み出し処理
    assign csr_rdata = csr_regs[csr_addr_r];
    //assign csr_mtvec = csr_regs[12'h305]; // mtvec
    //assign csr_mepc  = csr_regs[12'h341]; // mepc
    //assign csr_mcause  = csr_regs[12'h342]; // mcause
    //assign csr_mstatus = csr_regs[12'h300]; // mstatus
 

    // 書き込み・リセット処理
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 12'h300; i < 12'h400; i = i + 1) begin
            csr_regs[i] <= 0;
            end
            
            csr_regs[12'h300] <= 32'h00001800; // mstatus の初期値
            csr_regs[12'h302] <= 32'h0001_0000;
            csr_regs[12'h305] <= 32'h0000_0170; // 例: mtvec 初期値
            csr_regs[12'h342] <= 32'h0; 

        end else if (csr_we) begin

            csr_regs[csr_addr_w] <= csr_wdata;

        end
    end

endmodule
//`endif
