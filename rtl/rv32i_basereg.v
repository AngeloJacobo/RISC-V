//interface for the regfile of the 32 integer base registers

`timescale 1ns / 1ps

module rv32i_basereg
    (
        input wire clk,
        input wire[4:0] rs1_addr,
        input wire[4:0] rs2_addr,
        input wire[4:0] rd_addr,
        input wire[31:0] rd,
        input wire wr,
        output wire[31:0] rs1,
        output wire[31:0] rs2
    );
    
    reg[5:0] i = 0;
    reg[4:0] rs1_addr_q = 0,rs2_addr_q = 0;
    reg[31:0] base_regfile[31:1]; //base register file (base_regfile[0] is hardwired to zero)
        
    always @(posedge clk) begin
        if(wr && rd_addr!=0) begin
           base_regfile[rd_addr] <= rd; //synchronous write
        end
        rs1_addr_q <= rs1_addr; //synchronous read
        rs2_addr_q <= rs2_addr; //synchronous read
    end

    assign rs1 = rs1_addr_q==0? 0: base_regfile[rs1_addr_q]; 
    assign rs2 = rs2_addr_q==0? 0: base_regfile[rs2_addr_q];
    
endmodule

