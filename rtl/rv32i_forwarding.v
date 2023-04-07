/*The rv32i_forwarding module is responsible for handling data hazards in the
pipelined processor by implementing operand forwarding. Data hazards occur 
when a register value is about to be overwritten by previous instructions that 
are still in the pipeline and have not yet been written to the base register. 
Operand forwarding resolves this issue by either stalling the pipeline until 
the base register is updated (less efficient) or forwarding the updated operand
value directly from the pipeline stage where it is currently being computed. Key
functionalities of the rv32i_forwarding module include:
 - Forwarding rs1 and rs2 operands: The module initially sets the output values
    o_rs1 and o_rs2 to their original values from the base register (i_rs1_orig
    and i_rs2_orig). It then checks for any data hazards by comparing the register
    addresses of the operands (i_decoder_rs1_addr_q and i_decoder_rs2_addr_q) with
    the destination register addresses in the pipeline stages (i_alu_rd_addr and 
    i_memoryaccess_rd_addr).
 - Operand forwarding for rs1:If the next value of rs1 is in stage 4 (Memory Access), 
    and the Memory Access stage is enabled and if the next value of rs1 comes from a
    load or CSR instruction (i.e., rd is not valid at stage 4), the module stalls the
    ALU stage by asserting o_alu_force_stall. Otherwise, the module forwards the value
    of rd from stage 4 (i_alu_rd) to o_rs1. If the next value of rs1 is in stage 5 
    (Writeback), and the Writeback stage is enabled, the module forwards the value of
    rd from stage 5 (i_writeback_rd) to o_rs1.
 - Operand forwarding for rs2: If the next value of rs2 is in stage 4 (Memory Access),
    and the Memory Access stage is enabled and if the next value of rs2 comes from a 
    load or CSR instruction (i.e., rd is not yet valid at stage 4), the module stalls 
    the ALU stage by asserting o_alu_force_stall. Otherwise, the module forwards the
    value of rd from stage 4 (i_alu_rd) to o_rs2. If the next value of rs2 is in stage
    5 (Writeback), and the Writeback stage is enabled, the module forwards the value
    of rd from stage 5 (i_writeback_rd) to o_rs2.
 - Handling zero register (x0) forwarding: The module ensures that no operation 
    forwarding is performed when the register address is zero, as this register is
    hardwired to zero. If either i_decoder_rs1_addr_q or i_decoder_rs2_addr_q is zero,
    the corresponding output register (o_rs1 or o_rs2) is set to zero. By implementing
    operand forwarding, the rv32i_forwarding module helps to mitigate data hazards,
    ensuring the correct execution of instructions and improving the overall efficiency
    of the RV32I pipelined processor.
*/

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
