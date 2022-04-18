 //logic controller for data memory access (load/store) [MEMORY STAGE]
 
`timescale 1ns / 1ps

module rv32i_memoryaccess(
    input wire clk, rst_n,
    input wire memoryaccess, //enable wr_mem iff stage is currently on MEMORYACCESS
    input wire[31:0] rs2, //data to be stored to memory is always rs2
    input wire[31:0] din, //data retrieve from memory 
    input wire[1:0] addr_2, //last 2 bits of address of data to be stored or loaded (always comes from ALU)
    input wire[2:0] funct3, //byte,half-word,word
    input wire opcode_store, //determines if data_store will be to stored to data memory
    output reg[31:0] data_store, //data to be stored to memory (mask-aligned)
    output reg[31:0] data_load, //data to be loaded to base reg (z-or-s extended) 
    output reg[3:0] wr_mask, //write mask {byte3,byte2,byte1,byte0}
    output reg wr_mem //write to data memory if enabled
);
    reg[31:0] data_store_d;
    reg[31:0] data_load_d;
    reg[3:0] wr_mask_d;

    //register the outputs of this module
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            data_store <= 0;
            data_load <= 0;
            wr_mask <= 0;
            wr_mem <= 0;
        end
        else begin
            data_store <= data_store_d;
            data_load <= data_load_d;
            wr_mask <= wr_mask_d;
            wr_mem <= opcode_store && memoryaccess; 
        end
    end 

    //determine data to be loaded to basereg or stored to data memory 
    always @* begin
        data_store_d = 0;
        data_load_d = 0;
        wr_mask_d = 0; 
           
        case(funct3[1:0]) 
            2'b00: begin //byte load/store
                    case(addr_2)  //choose which of the 4 byte will be loaded to basereg
                        2'b00: data_load_d = din[7:0];
                        2'b01: data_load_d = din[15:8];
                        2'b10: data_load_d = din[23:16];
                        2'b11: data_load_d = din[31:24];
                    endcase
                    data_load_d = {{{24{!funct3[2]}} & {24{data_load_d[7]}}} , data_load_d[7:0]}; //signed and unsigned extension in 1 equation
                    wr_mask_d = 4'b0001<<addr_2; //mask 1 of the 4 bytes
                    data_store_d = rs2<<{addr_2,3'b000}; //rs2<<(addr_2*8) , align data to mask
                   end
            2'b01: begin //halfword load/store
                    data_load_d = addr_2[1]? din[31:16]: din[15:0]; //choose which of the 2 halfwords will be loaded to basereg
                    data_load_d = {{{16{!funct3[2]}} & {16{data_load_d[15]}}},data_load_d[15:0]}; //signed and unsigned extension in 1 equation
                    wr_mask_d = 4'b0011<<{addr_2[1],1'b0}; //mask either the upper or lower half-word
                    data_store_d = rs2<<{addr_2[1],4'b0000}; //rs2<<(addr_2[1]*16) , align data to mask
                   end
            2'b10: begin //word load/store
                    data_load_d = din;
                    wr_mask_d = 4'b1111; //mask all
                    data_store_d = rs2;
                   end
        endcase
    end

endmodule
