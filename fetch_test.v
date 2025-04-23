//test

`timescale 1ns/1ns

`include "fetch.v"

module top;
    reg clk, rst, keep, nop, branch_PC_early_contral, branch_PC_contral, iready_n;
	reg[31:0] branch_PC_early, branch_PC, idata;
    wire[31:0] iaddr, Instraction_pype, PC_pype0, PCp4_pype0;
    wire[4:0] eb_register1_pype, eb_register2_pype;
	integer i;

    fetch fetch(.clk(clk), .rst(rst), .keep(keep), .nop(nop), .branch_PC_early_contral(branch_PC_early_contral), 
    .branch_PC_contral(branch_PC_contral), .iready_n(iready_n), .branch_PC_early(branch_PC_early), .branch_PC(branch_PC), 
    .idata(idata), .iaddr(iaddr), .Instraction_pype(Instraction_pype), .PC_pype0(PC_pype0), .PCp4_pype0(PCp4_pype0),
    .eb_register1_pype(eb_register1_pype), .eb_register2_pype(eb_register2_pype));

    always #10 begin
        clk <= ~clk;
    end

    initial begin
	//vcdファイル生成
	$dumpfile("wave.vcd");
	$dumpvars(0, fetch);
    end

    initial begin
        #0
        clk <= 0;
        rst <= 0;
        keep <= 0;
        nop <= 0;
        iready_n <= 0;
        idata <= 32'h00001000;  // 適当な命令を入れておくと波形が見やすい
        branch_PC_early_contral <= 0;
        branch_PC_contral <= 0;
        branch_PC_early <= 0;
        branch_PC <= 0;
	
        #10
        rst <= 1;

        #10
        rst <= 0;

        #10
        branch_PC_early_contral <= 1;
        branch_PC_early <= 32'h00002000;
        #10
        branch_PC_early_contral <= 0;
        #10
        branch_PC_contral <= 1;
        branch_PC <= 32'h00003000;

        #10
        branch_PC_contral <= 0;
        #10
        nop <= 1;
        #10
        nop <= 0;


        #100


        $finish();
    end

endmodule