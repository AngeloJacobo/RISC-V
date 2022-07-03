//regfile controller for the 32 integer base registers

`timescale 1ns / 1ps
`default_nettype none

module rv32i_basereg
    (
        input wire i_clk,
        input wire i_ce_read, //clock enable for reading from basereg [STAGE 2]
        input wire[4:0] i_rs1_addr, //source register 1 address
        input wire[4:0] i_rs2_addr, //source register 2 address
        input wire[4:0] i_rd_addr, //destination register address
        input wire[31:0] i_rd, //data to be written to destination register
        input wire i_wr, //write enable
        output wire[31:0] o_rs1, //source register 1 value
        output wire[31:0] o_rs2 //source register 2 value
    );
    
    reg[4:0] rs1_addr_q, rs2_addr_q;
    reg[31:0] base_regfile[31:1]; //base register file (base_regfile[0] is hardwired to zero)
    wire write_to_basereg;
    
    always @(posedge i_clk) begin
        if(write_to_basereg) begin //only write to register if stage 5 is previously enabled (output of stage 5[WRITEBACK] is registered so delayed by 1 clk)
           base_regfile[i_rd_addr] <= i_rd; //synchronous write
        end
        if(i_ce_read) begin //only read the register if stage 2 is enabled [DECODE]
            rs1_addr_q <= i_rs1_addr; //synchronous read
            rs2_addr_q <= i_rs2_addr; //synchronous read
        end
    end
    
    assign write_to_basereg = i_wr && i_rd_addr!=0; //no need to write to basereg 0 (hardwired to zero) 
    assign o_rs1 = rs1_addr_q==0? 0: base_regfile[rs1_addr_q]; // if regfile is about to be written at the same time we read it
    assign o_rs2 = rs2_addr_q==0? 0: base_regfile[rs2_addr_q];    //then return the next value to be written to that address
    
endmodule

