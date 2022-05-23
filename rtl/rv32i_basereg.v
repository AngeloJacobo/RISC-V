//interface for the regfile of the 32 integer base registers

`timescale 1ns / 1ps

module rv32i_basereg
    (
        input wire i_clk,
        input wire[4:0] i_rs1_addr,
        input wire[4:0] i_rs2_addr,
        input wire[4:0] i_rd_addr,
        input wire[31:0] i_rd,
        input wire i_wr,
        output wire[31:0] o_rs1,
        output wire[31:0] o_rs2
    );
    
    reg[5:0] i = 0;
    reg[4:0] rs1_addr_q = 0,rs2_addr_q = 0;
    reg[31:0] base_regfile[31:1]; //base register file (base_regfile[0] is hardwired to zero)
        
    initial begin //initialize all basereg to zero
        for(i=0 ; i<32 ; i=i+1) base_regfile[i]=0; 
    end
    
    always @(posedge i_clk) begin
        if(i_wr && i_rd_addr!=0) begin
           base_regfile[i_rd_addr] <= i_rd; //synchronous write
        end
        rs1_addr_q <= i_rs1_addr; //synchronous read
        rs2_addr_q <= i_rs2_addr; //synchronous read
    end

    assign o_rs1 = rs1_addr_q==0? 0: base_regfile[rs1_addr_q]; 
    assign o_rs2 = rs2_addr_q==0? 0: base_regfile[rs2_addr_q];
    
endmodule

