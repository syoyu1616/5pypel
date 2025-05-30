
`ifndef CSR_REG_V
`define CSR_REG_V

module csr_reg (
    input clk,
    input rst,
    input csr_we,                            // CSR 書き込み有効信号

    input [11:0] csr_addr_w, 
    input [11:0] csr_addr_r,    // CSR アドレス
    input [31:0] csr_wdata,        // 書き込みデータ
    output [31:0] csr_rdata       // 読み出しデータ

);

    // CSRレジスタファイル
    reg [31:0] csr_regs [12'h300:12'h3ff]; // 要素数 csr_num (インデックス 0 から csr_num-1) // 要素数 4096 (インデックス 0 から 4095) data_width は各レジスタのビット幅
    integer i;

    // 読み出し処理
    assign csr_rdata = csr_regs[csr_addr_r];

 

    // 書き込み・リセット処理
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 12'h300; i < 12'h400; i = i + 1) begin
            csr_regs[i] <= 32'h0000_0000;
            end
            csr_regs[12'h300] <= 32'h0000_1800; // mstatus の初期値
            csr_regs[12'h301] <= 32'h4000_0000;
            csr_regs[12'h305] <= 32'h0000_0170; // 例: mtvec 初期値
            //csr_regs[12'h342] <= 32'h0; 

        end else if (csr_we) begin

            if (csr_addr_w == 12'h301) begin
            end
            else begin
            csr_regs[csr_addr_w] <= csr_wdata;
        end
        
    end
    end

endmodule
`endif
