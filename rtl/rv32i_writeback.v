//logic controller for the next PC and rd value [WRITEBACK STAGE]

`timescale 1ns / 1ps
`default_nettype none

module rv32i_writeback #(parameter PC_RESET = 32'h00_00_00_00) (
    input wire i_clk, i_rst_n,
    input wire i_writeback, //enable wr_rd iff stage is currently on i_writeback
    input wire[2:0] i_funct3, //function type 
    input wire[31:0] i_alu_out,//output of ALU
    input wire[31:0] i_imm, //immediate value
    input wire[31:0] i_rs1, //source register 1 value
    input wire[31:0] i_data_load, //data to be loaded to base reg
    input wire[31:0] i_csr_out, //CSR value to be loaded to basereg
    // Trap-Handler
    input wire i_go_to_trap, //high before going to trap (if exception/interrupt detected)
    input wire i_return_from_trap, //high before returning from trap (via mret)
    input wire[31:0] i_return_address, //mepc CSR
    input wire[31:0] i_trap_address, //mtvec CSR
    //// Opcode Type ////
    input wire i_opcode_rtype,
    input wire i_opcode_itype,
    input wire i_opcode_load,
    input wire i_opcode_store,
    input wire i_opcode_branch,
    input wire i_opcode_jal,
    input wire i_opcode_jalr,
    input wire i_opcode_lui,
    input wire i_opcode_auipc,
    input wire i_opcode_system,
    input wire i_opcode_fence,  
    output reg[31:0] o_rd, //value to be written back to destination register
    output reg[31:0] o_pc, //new pc value
    output reg o_wr_rd //write rd to the base reg if enabled
);
    initial o_pc = PC_RESET;

    reg[31:0] rd_d;
    reg[31:0] pc_d;
    reg wr_rd_d;
    reg[31:0] a;
    wire[31:0] sum;

    // register outputs of this module for shorter combinational timing paths
    always @(posedge i_clk,negedge i_rst_n) begin
        if(!i_rst_n) begin
            o_rd <= 0; 
            o_pc <= PC_RESET;
            o_wr_rd <= 0;
        end
        else begin
            o_rd <= rd_d;
            o_pc <= i_writeback ? pc_d:o_pc;
            o_wr_rd <= wr_rd_d && i_writeback; //enable o_wr_rd iff stage is currently on i_writeback

        end
    end

    //determine next value of o_pc and o_rd
    always @* begin
        rd_d = 0;
        pc_d = o_pc + 32'd4;
        wr_rd_d = 0;
        a = o_pc;

        if(i_go_to_trap) pc_d = i_trap_address;  //interrupt or exception detected
        
        else if(i_return_from_trap) pc_d = i_return_address; //return from trap via mret
        
        else begin //normal operation
            if(i_opcode_rtype || i_opcode_itype) rd_d = i_alu_out;
            if(i_opcode_load) rd_d = i_data_load;
            if(i_opcode_branch && i_alu_out[0]) pc_d = sum; //branch iff value of ALU is 1(true)
            if(i_opcode_jal || i_opcode_jalr) begin
                rd_d = pc_d;
                pc_d = sum;
                if(i_opcode_jalr) a = i_rs1;
            end 
            if(i_opcode_jalr) a = i_rs1;
            if(i_opcode_lui) rd_d = i_imm;
            if(i_opcode_auipc) rd_d = sum;
            if(i_opcode_system && i_funct3!=0) begin //CSR write
                rd_d = i_csr_out; 
            end
            
            if(i_opcode_branch || i_opcode_store || (i_opcode_system && i_funct3 == 0) || i_opcode_fence ) wr_rd_d = 0; //i_funct3==0 are the non-csr system instructions
            else wr_rd_d = 1; //always write to the destination reg except when instruction is BRANCH or STORE or SYSTEM(except CSR system instruction)  
        end
        
    end
    
    assign sum = a + i_imm; //share adder for all addition operation for less resource utilization
    
endmodule
