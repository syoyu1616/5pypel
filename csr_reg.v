
module csr_reg (
    input clk,
    input rst,
    input csr_we, //csr命令か否か
    input [11:0] csr_addr, //読み書きするアドレス,
    input [31:0] csr_wdata,//csr regの書き込み、読み出し
    output [31:0] csr_rdata,
    output [31:0] csr_mtvec,
    output [31:0] csr_mepc
);
    reg [31:0] csr_regs [0:4095]; // 12-bitアドレス空間
    

    assign csr_rdata = csr_regs[csr_addr];
    assign csr_mtvec = csr_regs[12'h305];  // mtvec
    assign csr_mepc  = csr_regs[12'h341];  // mepc

    always @(posedge clk) begin
        if (csr_we)
            csr_regs[csr_addr] <= csr_wdata;
    end
endmodule