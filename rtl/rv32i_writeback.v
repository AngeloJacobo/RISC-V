//logic controller for the next PC and rd value [WRITEBACK STAGE]

`timescale 1ns / 1ps
`default_nettype none

module rv32i_writeback #(parameter PC_RESET = 32'h00_00_00_00) (
    input wire clk, rst_n,
    input wire writeback, //enable wr_rd iff stage is currently on WRITEBACK
    input wire[2:0] funct3, //function type 
    input wire[31:0] alu_out,//output of ALU
    input wire[31:0] imm, //immediate value
    input wire[31:0] rs1, //source register 1 value
    input wire[31:0] data_load, //data to be loaded to base reg
    input wire[31:0] csr_out, //CSR value to be loaded to basereg
    // Trap-Handler
    input wire go_to_trap, //high before going to trap (if exception/interrupt detected)
    input wire return_from_trap, //high before returning from trap (via mret)
    input wire[31:0] return_address, //mepc CSR
    input wire[31:0] trap_address, //mtvec CSR
    //// Opcode Type ////
    input wire opcode_rtype,
    input wire opcode_itype,
    input wire opcode_load,
    input wire opcode_store,
    input wire opcode_branch,
    input wire opcode_jal,
    input wire opcode_jalr,
    input wire opcode_lui,
    input wire opcode_auipc,
    input wire opcode_system,
    input wire opcode_fence,  
    output reg[31:0] rd, //value to be written back to destination register
    output reg[31:0] pc, //new PC value
    output reg wr_rd //write rd to the base reg if enabled
);
    initial pc = PC_RESET;

    reg[31:0] rd_d;
    reg[31:0] pc_d;
    reg wr_rd_d;
    reg[31:0] a;
    wire[31:0] sum;

    // register outputs of this module for shorter combinational timing paths
    always @(posedge clk,negedge rst_n) begin
        if(!rst_n) begin
            rd <= 0; 
            pc <= PC_RESET;
            wr_rd <= 0;
        end
        else begin
            rd <= rd_d;
            pc <= writeback ? pc_d:pc;
            wr_rd <= wr_rd_d && writeback; //enable wr_rd iff stage is currently on WRITEBACK

        end
    end

    //determine next value of PC and rd
    always @* begin
        rd_d = 0;
        pc_d = pc + 32'd4;
        wr_rd_d = 0;
        a = pc;

        if(go_to_trap) pc_d = trap_address;  //interrupt or exception detected
        
        else if(return_from_trap) pc_d = return_address; //return from trap via mret
        
        else begin //normal operation
            if(opcode_rtype || opcode_itype) rd_d = alu_out;
            if(opcode_load) rd_d = data_load;
            if(opcode_branch && alu_out[0]) pc_d = sum; //branch iff value of ALU is 1(true)
            if(opcode_jal || opcode_jalr) begin
                rd_d = pc_d;
                pc_d = sum;
                if(opcode_jalr) a = rs1;
            end 
            if(opcode_jalr) a = rs1;
            if(opcode_lui) rd_d = imm;
            if(opcode_auipc) rd_d = sum;
            if(opcode_system && funct3!=0) begin //CSR write
                rd_d = csr_out; 
            end
            
            if(opcode_branch || opcode_store || (opcode_system && funct3 == 0) || opcode_fence ) wr_rd_d = 0; //funct3==0 are the non-csr system instructions
            else wr_rd_d = 1; //always write to the destination reg except when instruction is BRANCH or STORE or SYSTEM(except CSR system instruction)  
        end
        
    end
    
    assign sum = a + imm; //share adder for all addition operation for less resource utilization
    
endmodule
