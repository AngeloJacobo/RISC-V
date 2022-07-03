//logic controller for the next PC and rd value [WRITEBACK STAGE]

`timescale 1ns / 1ps
`default_nettype none
`include "rv32i_header.vh"

module rv32i_writeback (
    input wire i_clk, i_rst_n,
    input wire[2:0] i_funct3, //function type 
    input wire[31:0] i_data_load, //data to be loaded to base reg
    input wire[31:0] i_csr_out, //CSR value to be loaded to basereg
    input wire i_opcode_load,
    input wire i_opcode_system, 
    // Basereg Control
    input wire i_wr_rd, //write rd to basereg if enabled (from previous stage)
    output reg o_wr_rd, //write rd to the base reg if enabled
    input wire[4:0] i_rd_addr, //address for destination register (from previous stage)
    output reg[4:0] o_rd_addr, //address for destination register
    input wire[31:0] i_rd, //value to be written back to destination register (from previous stage)
    output reg[31:0] o_rd, //value to be written back to destination register
    // PC Control
    input wire[31:0] i_pc, // pc value (from previous stage)
    output reg[31:0] o_next_pc, //new pc value
    output reg o_change_pc, //high if PC needs to jump
    // Trap-Handler
    input wire i_go_to_trap, //high before going to trap (if exception/interrupt detected)
    input wire i_return_from_trap, //high before returning from trap (via mret)
    input wire[31:0] i_return_address, //mepc CSR
    input wire[31:0] i_trap_address, //mtvec CSR
    /// Pipeline Control ///
    input wire i_ce, // input clk enable for pipeline stalling of this stage
    input wire[`STALL_WIDTH-1:0] i_stall, //informs this stage to stall
    output reg o_stall, //informs pipeline to stall
    output reg o_flush //flush previous stages
);
//
    //determine next value of pc and o_rd
    always @* begin
        o_stall = 0; //stall when this stage needs wait time
        o_flush = 0; //flush this stage along with previous stages when changing PC
        o_wr_rd = i_wr_rd && i_ce && !i_stall[`WRITEBACK];
        o_rd_addr = i_rd_addr;
        o_rd = 0;
        o_next_pc = 0;
        o_change_pc = 0;

        if(i_go_to_trap) begin
            o_change_pc = i_ce; //change PC only when ce of this stage is high (o_change_pc is valid)
            o_next_pc = i_trap_address;  //interrupt or exception detected so go to trap address (mtvec value)
            o_flush = i_ce;
            o_wr_rd = 0;
        end
        
        else if(i_return_from_trap) begin
            o_change_pc = i_ce; //change PC only when ce of this stage is high (o_change_pc is valid)
             o_next_pc = i_return_address; //return from trap via mret (mepc value)
             o_flush = i_ce;
             o_wr_rd = 0;
        end
        
        else begin //normal operation
            if(i_opcode_load) o_rd = i_data_load; //load data from memory to basereg
            else if(i_opcode_system && i_funct3!=0) begin //CSR write
                o_rd = i_csr_out; 
            end
            else o_rd = i_rd; //rd value is already computed at ALU stage
        end
        
    end
endmodule
