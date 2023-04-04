// logic for Operand Forwarding

`timescale 1ns / 1ps
`default_nettype none
`include "rv32i_header.vh"

module rv32i_forwarding (
    input wire[31:0] i_rs1_orig, //current rs1 value saved in basereg
    input wire[31:0] i_rs2_orig, //current rs2 value saved in basereg
    input wire[4:0] i_decoder_rs1_addr_q, //address of operand rs1 used in ALU stage
    input wire[4:0] i_decoder_rs2_addr_q, //address of operand rs2 used in ALU stage
    output reg o_alu_force_stall, //high to force ALU stage to stall
    output reg[31:0] o_rs1, //rs1 value with Operand Forwarding
    output reg[31:0] o_rs2, //rs2 value with Operand Forwarding
    // Stage 4 [MEMORYACCESS]
    input wire[4:0] i_alu_rd_addr, //destination register address
    input wire i_alu_wr_rd, //high if rd_addr will be written
    input wire i_alu_rd_valid, //high if rd is already valid at this stage (not LOAD nor CSR instruction)
    input wire[31:0] i_alu_rd, //rd value in stage 4
    input wire i_memoryaccess_ce, //high if stage 4 is enabled
    // Stage 5 [WRITEBACK]
    input wire[4:0] i_memoryaccess_rd_addr, //destination register address
    input wire i_memoryaccess_wr_rd, //high if rd_addr will be written
    input wire[31:0] i_writeback_rd, //rd value in stage 5
    input wire i_writeback_ce //high if stage 4 is enabled
);

    always @* begin
        o_rs1 = i_rs1_orig; //original value from basereg
        o_rs2 = i_rs2_orig; //original value from basereg
        o_alu_force_stall = 0;
         
        // Data Hazard = Register value is about to be overwritten by previous instructions but are still on the pipeline and are not yet written to basereg.
        // The solution to make sure the updated value of rs1 or rs2 is used is to either stall the pipeline until the basereg is updated (very inefficient) or use Operand Forwarding

            // Operand Forwarding for rs1
            if((i_decoder_rs1_addr_q == i_alu_rd_addr) && i_alu_wr_rd && i_memoryaccess_ce) begin //next value of rs1 is currently on stage 4
                if(!i_alu_rd_valid) begin   //if next value of rs1 comes from load or CSR instruction then we must stall from ALU stage and wait until 
                    o_alu_force_stall = 1;   //stage 4(Memoryaccess) becomes disabled, which means next value of rs1 is already at stage 5   
                end
                o_rs1 = i_alu_rd;
            end
            else if((i_decoder_rs1_addr_q == i_memoryaccess_rd_addr) && i_memoryaccess_wr_rd && i_writeback_ce) begin //next value of rs1 is currently on stage 5
                o_rs1 = i_writeback_rd;
            end
            
            // Operand Forwarding for rs2
            if((i_decoder_rs2_addr_q == i_alu_rd_addr) && i_alu_wr_rd && i_memoryaccess_ce) begin //next value of rs2 is currently on stage 4
                if(!i_alu_rd_valid) begin   //if next value of rs2 comes from load or CSR instruction(rd is only available at stage 5) then we must stall from ALU stage and wait until 
                    o_alu_force_stall = 1;   //stage 4(Memoryaccess) becomes disabled (which implicitly means that next value of rs2 is already at stage 5)   
                end
                o_rs2 = i_alu_rd;
            end
            else if((i_decoder_rs2_addr_q == i_memoryaccess_rd_addr) && i_memoryaccess_wr_rd && i_writeback_ce) begin //next value of rs2 is currently on stage 5
                o_rs2 = i_writeback_rd;
            end

            // No operation forwarding necessary when addr is zero since that address is hardwired to zero
            if(i_decoder_rs1_addr_q == 0) o_rs1 = 0;
            if(i_decoder_rs2_addr_q == 0) o_rs2 = 0;
    end

endmodule
