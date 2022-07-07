//logic for fetching an instruction [FETCH]

`timescale 1ns / 1ps
`default_nettype none
`include "rv32i_header.vh"

module rv32i_fetch #(parameter PC_RESET = 32'h00_00_00_00) (
    input wire i_clk,i_rst_n,
    output reg[31:0] o_iaddr, //instruction memory address
    output reg[31:0] o_pc, //PC value of current instruction 
    input wire[31:0] i_inst, // retrieved instruction from Memory
    output reg[31:0] o_inst, // instruction sent to pipeline
    // PC Control
    input wire i_writeback_change_pc, //high when PC needs to change when going to trap or returning from trap
    input wire[31:0] i_writeback_next_pc, //next PC due to trap
    input wire i_alu_change_pc, //high when PC needs to change for taken branches and jumps
    input wire[31:0] i_alu_next_pc, //next PC due to branch or jump
    /// Pipeline Control ///
    input wire i_ce, // input clk enable for pipeline stalling if this stage
    output reg o_ce, // output clk enable for pipeline stalling of next stage
    input wire[`STALL_WIDTH-1:0] i_stall, //stall logic for whole pipeline
    output reg o_stall, //informs previous stages to stall
    input wire i_flush //flush this stage
);

    reg[31:0] iaddr_d;
    reg ce_d;
    wire stall_bit = i_stall[`FETCH] || i_stall[`DECODER] ||i_stall[`ALU] || i_stall[`MEMORYACCESS] || i_stall[`WRITEBACK]; //stall this stage when next stages are stalled

    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            o_ce <= 0;
            o_iaddr <= PC_RESET;
        end
        else begin
            if(i_ce && !stall_bit) begin //update registers only if this stage is enabled and next stages are not stalled
                o_iaddr <= iaddr_d;
                o_pc <= o_iaddr;
                o_inst <= i_inst;
            end
            if(i_flush && !stall_bit) begin //flush this stage(only when not stalled) so that clock-enable of next stage is disabled at next clock cycle
                o_ce <= 0;
            end
            else if(!stall_bit) begin //clock-enable will change only when not stalled
                o_ce <= ce_d;
            end
            else if(stall_bit && !i_stall[`DECODER]) o_ce <= 0; //if this stage is stalled but next stage is not, disable 
                                                                    //clock enable of next stage at next clock cycle (pipeline bubble)
        end
    end
    // logic for PC and pipeline clock_enable control
    always @* begin
        iaddr_d = 0;
        ce_d = 0;
        o_stall = i_stall[`DECODER] || i_stall[`ALU] || i_stall[`MEMORYACCESS] || i_stall[`WRITEBACK]; //stall when retrieving instructions need wait time

        if(i_writeback_change_pc) begin
            iaddr_d = i_writeback_next_pc;
            ce_d = 0;
        end
        else if(i_alu_change_pc) begin
            iaddr_d  = i_alu_next_pc;
            ce_d = 0;
        end
        else begin
            iaddr_d = o_iaddr + 32'd4;
            ce_d = i_ce;
        end
    end
    
endmodule
