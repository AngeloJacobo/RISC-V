 //logic controller for data memory access (load/store) [MEMORY ACCESS STAGE]
 
`timescale 1ns / 1ps
`default_nettype none

module rv32i_memoryaccess(
    input wire i_clk, i_rst_n,
    input wire[31:0] i_rs2, //data to be stored to memory is always i_rs2
    input wire[31:0] i_din, //data retrieve from memory 
    input wire[1:0] i_addr_2, //last 2 bits of address of data to be stored or loaded (always comes from ALU)
    input wire[2:0] i_funct3, //byte,half-word,word
    input wire i_opcode_store, //determines if data_store will be to stored to data memory
    output reg[31:0] o_data_store, //data to be stored to memory (mask-aligned)
    output reg[31:0] o_data_load, //data to be loaded to base reg (z-or-s extended) 
    output reg[3:0] o_wr_mask, //write mask {byte3,byte2,byte1,byte0}
    output reg o_wr_mem, //write to data memory if enabled
    /// Pipeline Control ///
    input wire i_ce, // input clk enable for pipeline stalling of this stage
    output reg o_ce // output clk enable for pipeline stalling of next stage
);
    initial begin
        o_data_store = 0;
        o_data_load = 0;
        o_wr_mask = 0;
        o_wr_mem = 0;
        o_ce = 0;
    end
    
    reg[31:0] data_store_d;
    reg[31:0] data_load_d;
    reg[3:0] wr_mask_d;

    //register the outputs of this module
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            o_data_store <= 0;
            o_data_load <= 0;
            o_wr_mask <= 0;
            o_wr_mem <= 0;
            o_ce <= 0;
        end
        else begin
            if(i_ce) begin //update register only if this stage is enabled
                o_data_store <= data_store_d;
                o_data_load <= data_load_d;
                o_wr_mask <= wr_mask_d;
                o_wr_mem <= i_opcode_store; 
            end
            o_ce <= i_ce;
        end
    end 

    //determine data to be loaded to basereg or stored to data memory 
    always @* begin
        data_store_d = 0;
        data_load_d = 0;
        wr_mask_d = 0; 
           
        case(i_funct3[1:0]) 
            2'b00: begin //byte load/store
                    case(i_addr_2)  //choose which of the 4 byte will be loaded to basereg
                        2'b00: data_load_d = i_din[7:0];
                        2'b01: data_load_d = i_din[15:8];
                        2'b10: data_load_d = i_din[23:16];
                        2'b11: data_load_d = i_din[31:24];
                    endcase
                    data_load_d = {{{24{!i_funct3[2]}} & {24{data_load_d[7]}}} , data_load_d[7:0]}; //signed and unsigned extension in 1 equation
                    wr_mask_d = 4'b0001<<i_addr_2; //mask 1 of the 4 bytes
                    data_store_d = i_rs2<<{i_addr_2,3'b000}; //i_rs2<<(i_addr_2*8) , align data to mask
                   end
            2'b01: begin //halfword load/store
                    data_load_d = i_addr_2[1]? i_din[31:16]: i_din[15:0]; //choose which of the 2 halfwords will be loaded to basereg
                    data_load_d = {{{16{!i_funct3[2]}} & {16{data_load_d[15]}}},data_load_d[15:0]}; //signed and unsigned extension in 1 equation
                    wr_mask_d = 4'b0011<<{i_addr_2[1],1'b0}; //mask either the upper or lower half-word
                    data_store_d = i_rs2<<{i_addr_2[1],4'b0000}; //i_rs2<<(i_addr_2[1]*16) , align data to mask
                   end
            2'b10: begin //word load/store
                    data_load_d = i_din;
                    wr_mask_d = 4'b1111; //mask all
                    data_store_d = i_rs2;
                   end
        endcase
    end

endmodule
