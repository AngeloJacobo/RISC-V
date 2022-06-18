//interface for the regfile of the 32 integer base registers

`timescale 1ns / 1ps
`default_nettype none

module rv32i_basereg
    (
        input wire i_clk,
        input wire i_ce_stage1, //clock enable for stage 1
        input wire i_ce_stage5, //clock enable for stage 5
        input wire[4:0] i_rs1_addr, //source register 1 address
        input wire[4:0] i_rs2_addr, //source register 2 address
        input wire[4:0] i_rd_addr, //destination register address
        input wire[31:0] i_rd, //data to be written to destination register
        input wire i_wr, //write enable
        output wire[31:0] o_rs1, //source register 1 value
        output wire[31:0] o_rs2 //source register 2 value
    );
    
    reg ce_stage5 = 0;
    reg[5:0] i = 0;
    reg[4:0] rs1_addr_q = 0,rs2_addr_q = 0;
    reg[31:0] base_regfile[31:1]; //base register file (base_regfile[0] is hardwired to zero)
        
    initial begin //initialize all basereg to zero
        for(i=0 ; i<32 ; i=i+1) base_regfile[i]=0; 
    end
    
    always @(posedge i_clk) begin
        ce_stage5 <= i_ce_stage5; 
        if(i_wr && i_rd_addr!=0 && ce_stage5) begin //only write to register if stage 5 is previously enabled (output of stage 5[WRITEBACK] is registered so delayed by 1 clk)
           base_regfile[i_rd_addr] <= i_rd; //synchronous write
        end
        if(i_ce_stage1) begin //only write to register if stage 1 is enabled
            rs1_addr_q <= i_rs1_addr; //synchronous read
            rs2_addr_q <= i_rs2_addr; //synchronous read
        end
    end

    assign o_rs1 = rs1_addr_q==0? 0: base_regfile[rs1_addr_q]; 
    assign o_rs2 = rs2_addr_q==0? 0: base_regfile[rs2_addr_q];
    
endmodule

