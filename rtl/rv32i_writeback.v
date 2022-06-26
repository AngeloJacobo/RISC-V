//logic controller for the next PC and rd value [WRITEBACK STAGE]

`timescale 1ns / 1ps
`default_nettype none

module rv32i_writeback #(parameter PC_RESET = 32'h00_00_00_00) (
    input wire i_clk, i_rst_n,
    input wire[2:0] i_funct3, //function type 
    input wire[31:0] i_alu_out,//output of ALU
    input wire[31:0] i_imm, //immediate value
    input wire[31:0] i_rs1, //source register 1 value
    input wire[31:0] i_data_load, //data to be loaded to base reg
    input wire[31:0] i_csr_out, //CSR value to be loaded to basereg
    output reg[31:0] o_rd, //value to be written back to destination register
    output reg[31:0] o_rd_d, //next value to be written back to destination register
    output wire[31:0] o_next_pc, //new pc value
    output wire o_change_pc, //high if PC needs to jump
    output reg o_wr_rd, //write rd to the base reg if enabled
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
    /// Pipeline Control ///
    input wire i_ce, // input clk enable for pipeline stalling of this stage
    output reg o_ce // output clk enable for pipeline stalling of next stage
);
    initial begin
        o_rd = 0;
        o_wr_rd = 0;
        o_ce = 0;
    end

    reg[31:0] pc=0,pc_d;
    reg wr_rd_d;
    reg[31:0] a;
    wire[31:0] sum;

    // register outputs of this module for shorter combinational timing paths
    always @(posedge i_clk,negedge i_rst_n) begin
        if(!i_rst_n) begin
            o_rd <= 0; 
            pc <= PC_RESET;
            o_wr_rd <= 0;
            o_ce <= 0;
        end
        else begin
            if(i_ce) begin //update register only if this stage is enabled
                o_rd <= o_rd_d;
                pc <= pc_d;
                o_wr_rd <= wr_rd_d; 
            end
            o_ce <= i_ce;
        end
    end

    //determine next value of pc and o_rd
    always @* begin
        o_rd_d = 0;
        pc_d = pc + 32'd4;
        wr_rd_d = 0;
        a = pc;

        if(i_go_to_trap) pc_d = i_trap_address;  //interrupt or exception detected so go to trap address (mtvec value)
        
        else if(i_return_from_trap) pc_d = i_return_address; //return from trap via mret (mepc value)
        
        else begin //normal operation
            if(i_opcode_rtype || i_opcode_itype) o_rd_d = i_alu_out;
            if(i_opcode_load) o_rd_d = i_data_load;
            if(i_opcode_branch && i_alu_out[0]) pc_d = sum; //branch iff value of ALU is 1(true)
            if(i_opcode_jal || i_opcode_jalr) begin
                if(i_opcode_jalr) a = i_rs1;
                o_rd_d = pc_d; //register the next pc value to destination register
                pc_d = sum; //jump to new PC
            end 
            //if(i_opcode_jalr) a = i_rs1;
            if(i_opcode_lui) o_rd_d = i_imm;
            if(i_opcode_auipc) o_rd_d = sum;
            if(i_opcode_system && i_funct3!=0) begin //CSR write
                o_rd_d = i_csr_out; 
            end
            
            if(i_opcode_branch || i_opcode_store || (i_opcode_system && i_funct3 == 0) || i_opcode_fence ) wr_rd_d = 0; //i_funct3==0 are the non-csr system instructions 
            else wr_rd_d = 1; //always write to the destination reg except when instruction is BRANCH or STORE or SYSTEM(except CSR system instruction)  
        end
        
    end
    
    assign sum = a + i_imm; //share adder for all addition operation for less resource utilization
    assign o_next_pc = pc_d; //next PC value 
    assign o_change_pc = pc_d != pc + 32'd4; //high if PC needs to jump
endmodule
