 //logic controller for data memory access (load/store) [MEMORY ACCESS STAGE]
 
`timescale 1ns / 1ps
`default_nettype none
`include "rv32i_header.vh"

module rv32i_memoryaccess(
    input wire i_clk, i_rst_n,
    input wire[31:0] i_rs2, //data to be stored to memory is always i_rs2
    input wire[31:0] i_din, //data retrieve from memory 
    input wire[31:0] i_y, //y value from ALU (address of data to memory be stored or loaded)
    output reg [31:0] o_y, //y value used as data memory address 
    input wire[2:0] i_funct3, //funct3 from previous stage
    output reg[2:0] o_funct3, //funct3 (byte,halfword,word)
    input wire[`OPCODE_WIDTH-1:0] i_opcode, //determines if data_store will be to stored to data memory
    output reg[`OPCODE_WIDTH-1:0] o_opcode,//opcode type
    input wire[31:0] i_pc, //PC from previous stage
    output reg[31:0] o_pc, //PC value
    // Basereg Control
    input wire i_wr_rd, //write rd to base reg is enabled (from memoryaccess stage)
    output reg o_wr_rd, //write rd to the base reg if enabled
    input wire[4:0] i_rd_addr, //address for destination register (from previous stage)
    output reg[4:0] o_rd_addr, //address for destination register
    input wire[31:0] i_rd, //value to be written back to destination reg
    output reg[31:0] o_rd, //value to be written back to destination register
    // Data Memory Control
    output reg[31:0] o_data_store, //data to be stored to memory (mask-aligned)
    output reg[31:0] o_data_load, //data to be loaded to base reg (z-or-s extended) 
    output reg[3:0] o_wr_mask, //write mask {byte3,byte2,byte1,byte0}
    output reg o_wr_mem, //write to data memory if enabled
    /// Pipeline Control ///
    input wire i_ce, // input clk enable for pipeline stalling of this stage
    output reg o_ce, // output clk enable for pipeline stalling of next stage
    input wire[`STALL_WIDTH-1:0] i_stall, //informs this stage to stall
    output reg o_stall, //informs pipeline to stall
    input wire i_flush, //flush this stage
    output reg o_flush //flush previous stages
);
    initial begin
        o_data_store = 0;
        o_data_load = 0;
        o_wr_mask = 0;
        o_wr_mem = 0;
        o_ce = 0;
    end
    
    reg[31:0] data_store_d; //data to be stored to memory
    reg[31:0] data_load_d; //data to be loaded to basereg
    reg[3:0] wr_mask_d; 
    wire[1:0] addr_2 = i_y[1:0]; //last 2  bits of data memory address
    reg delay=0; //1 clk delay needed for load operation
    wire stall_bit =i_stall[`MEMORYACCESS] || i_stall[`WRITEBACK];

    //register the outputs of this module
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            o_y <= 0;
            o_rd_addr <= 0;
            o_funct3 <= 0;
            o_opcode <= 0;
            o_pc <= 0;
            o_wr_rd <= 0;
            o_rd <= 0;
            o_data_store <= 0;
            o_data_load <= 0;
            o_wr_mask <= 0;
            o_wr_mem <= 0;
            delay <= 0;
            o_ce <= 0;
        end
        else begin
            if(i_ce && !stall_bit) begin //update register only if this stage is enabled and not stalled
                o_rd_addr <= i_rd_addr;
                o_funct3 <= i_funct3;
                o_opcode <= i_opcode;
                o_pc <= i_pc;
                o_wr_rd <= i_wr_rd;
                o_rd <= i_rd;
                o_data_store <= data_store_d;
                o_data_load <= data_load_d; 
                o_wr_mask <= wr_mask_d;
                o_wr_mem <= i_opcode[`STORE]; 
            end
            if(i_flush && !stall_bit) begin //flush this stage so clock-enable of next stage is disabled at next clock cycle
                o_ce <= 0;
            end
            else if(!stall_bit) begin //clock-enable will change only when not stalled
                o_ce <= i_ce;
            end
            else if(stall_bit && !i_stall[`WRITEBACK]) o_ce <= 0; //if this stage is stalled but next stage is not, disable 
                                                                                //clock enable of next stage at next clock cycle
            o_y <= i_y; //data memory address

            //1 clk delay logic to register the data memory address
            if(stall_bit) begin
                delay <= 1;            
            end
            else delay <= 0;
        end

    end 

    //determine data to be loaded to basereg or stored to data memory 
    always @* begin
        o_stall = ((i_opcode[`LOAD] && i_ce && !delay) || i_stall[`WRITEBACK]) && !i_flush; //stall while retrieving data from memory(dont stall when need to flush)
        o_flush = i_flush; //flush this stage along with previous stages
        data_store_d = 0;
        data_load_d = 0;
        wr_mask_d = 0; 
           
        case(i_funct3[1:0]) 
            2'b00: begin //byte load/store
                    case(addr_2)  //choose which of the 4 byte will be loaded to basereg
                        2'b00: data_load_d = i_din[7:0];
                        2'b01: data_load_d = i_din[15:8];
                        2'b10: data_load_d = i_din[23:16];
                        2'b11: data_load_d = i_din[31:24];
                    endcase
                    data_load_d = {{{24{!i_funct3[2]}} & {24{data_load_d[7]}}} , data_load_d[7:0]}; //signed and unsigned extension in 1 equation
                    wr_mask_d = 4'b0001<<addr_2; //mask 1 of the 4 bytes
                    data_store_d = i_rs2<<{addr_2,3'b000}; //i_rs2<<(addr_2*8) , align data to mask
                   end
            2'b01: begin //halfword load/store
                    data_load_d = addr_2[1]? i_din[31:16]: i_din[15:0]; //choose which of the 2 halfwords will be loaded to basereg
                    data_load_d = {{{16{!i_funct3[2]}} & {16{data_load_d[15]}}},data_load_d[15:0]}; //signed and unsigned extension in 1 equation
                    wr_mask_d = 4'b0011<<{addr_2[1],1'b0}; //mask either the upper or lower half-word
                    data_store_d = i_rs2<<{addr_2[1],4'b0000}; //i_rs2<<(addr_2[1]*16) , align data to mask
                   end
            2'b10: begin //word load/store
                    data_load_d = i_din;
                    wr_mask_d = 4'b1111; //mask all
                    data_store_d = i_rs2;
                   end
        endcase
        //stall logic for retrieving data from memory
    
    end


endmodule
