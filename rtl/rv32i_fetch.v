//logic for fetching an instruction [FETCH]

`timescale 1ns / 1ps
`default_nettype none

module rv32i_fetch (
    input wire i_clk,i_rst_n,
    input wire[31:0] i_inst, // retrieved instruction from Memory
    output reg[31:0] o_inst, // instruction sent to pipeline
    /// Pipeline Control ///
    input wire i_ce, // input clk enable for pipeline stalling if this stage
    output reg o_ce // output clk enable for pipeline stalling of next stage
);
    initial begin
        o_ce = 0;
        o_inst = 0;
    end
    
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            o_ce <= 0;
            o_inst <= 0;
        end
        else begin
            if(i_ce) begin //update registers only if this stage is enabled
                o_inst <= i_inst;
            end
            o_ce <= i_ce;
        end
    end
    
endmodule
