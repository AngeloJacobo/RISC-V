//combinational logic for determining the next PC and rd value [WRITEBACK STAGE]

`timescale 1ns / 1ps

module rv32i_writeback(
    input wire clk, rst_n,
    input wire[31:0] alu_out,//output of ALU
    input wire[31:0] pc, //current PC value
    input wire[31:0] imm, //immediate value
    input wire[31:0] rs1, //source register 1 value
    input wire[31:0] data_load, //data to be loaded to base reg
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
    output reg[31:0] pc_new, //new PC value
    output reg wr_rd //write rd to the base reg if enabled
);
    reg[31:0] rd_d;
    reg[31:0] pc_new_d;
    reg wr_rd_d;
    reg[31:0] a,sum;

    // register outputs of this module for shorter combinational timing paths
    always @(posedge clk,negedge rst_n) begin
        if(!rst_n) begin
            rd <= 0; 
            pc_new <= 0;
            wr_rd <= 0;
        end
        else begin
            rd <= rd_d;
            pc_new <= pc_new_d;
            wr_rd <= wr_rd_d;
        end
    end

    //determine next value of PC and rd
    always @* begin
        rd_d = 0;
        pc_new_d = pc + 32'd4;
        wr_rd_d = 0;
        a = pc;
        sum = a + imm; //share adder for all addition operation for less resource utilization   
          
        if(opcode_rtype || opcode_itype) rd_d = alu_out;
        if(opcode_load) rd_d = data_load;
        if(opcode_branch && alu_out[0]) pc_new_d = sum; //branch iff value of ALU is 1(true)
        if(opcode_jal || opcode_jalr) begin
            rd_d = pc_new_d;
            pc_new_d = sum;
        end 
        if(opcode_jalr) a = rs1;
        if(opcode_lui) rd_d = imm;
        if(opcode_auipc) rd_d = sum;
        if(opcode_branch || opcode_store || opcode_system) wr_rd_d = 0;
        else wr_rd_d = 1; //always write to the destination reg except when instruction is BRANCH or STORE or SYSTEM
    end
endmodule
