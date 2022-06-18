//arithmetic logic unit [EXECUTE STAGE]

`timescale 1ns / 1ps
`default_nettype none

module rv32i_alu(
    input wire i_clk,i_rst_n,
    input wire[31:0] i_pc, //Program Counter
    input wire[31:0] i_rs1, //Source register 1 value
    input wire[31:0] i_rs2, //Source register 2 value
    input wire[31:0] i_imm, //Immediate value
    output reg[31:0] o_y, //result of arithmetic operation
    /// ALU Operations ///
    input wire i_alu_add, //addition
    input wire i_alu_sub, //subtraction
    input wire i_alu_slt, //set if less than
    input wire i_alu_sltu, //set if less than unsigned 
    input wire i_alu_xor, //bitwise xor
    input wire i_alu_or, //bitwise or
    input wire i_alu_and, //bitwise and
    input wire i_alu_sll, //shift left logical
    input wire i_alu_srl, //shift right logical
    input wire i_alu_sra, //shift right arithmetic
    input wire i_alu_eq, //equal
    input wire i_alu_neq, //not equal
    input wire i_alu_ge, //greater than or equal
    input wire i_alu_geu, //greater than or equal unisgned
    //// Opcode Type ////
    input wire i_opcode_rtype,
    input wire i_opcode_branch,
    input wire i_opcode_jal,
    input wire i_opcode_auipc,
    /// Pipeline Control ///
    input wire i_ce, // input clk enable for pipeline stalling of this stage
    output reg o_ce // output clk enable for pipeline stalling of next stage
);
    initial begin
        o_y = 0;
        o_ce = 0;
    end
    
    reg[31:0] a; //operand A
    reg[31:0] b; //operand B
    reg[31:0] y_d; //ALU output

    //register the output of i_alu
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            o_y <= 0;
            o_ce <= 0;
        end
        else begin
            if(i_ce) begin //update register only if this stage is enabled
                o_y <= y_d; 
            end
            o_ce <= i_ce;
        end
        
    end 

    //i_alu core (run in parallel instead of priority logic for less
    always @* begin  //resource utilization)
        y_d = 0;
        
        a = (i_opcode_jal || i_opcode_auipc)? i_pc:i_rs1;  // a can either be pc or rs1
        b = (i_opcode_rtype || i_opcode_branch)? i_rs2:i_imm; // b can either be rs2 or imm 
        
        if(i_alu_add) y_d = a + b;
        if(i_alu_sub) y_d = a - b;
        if(i_alu_slt || i_alu_sltu) begin
            y_d = a < b;
            if(i_alu_slt) y_d = (a[31] ^ b[31])? a[31]:y_d;
        end 
        if(i_alu_xor) y_d = a ^ b;
        if(i_alu_or)  y_d = a | b;
        if(i_alu_and) y_d = a & b;
        if(i_alu_sll) y_d = a << b[4:0];
        if(i_alu_srl) y_d = a >> b[4:0];
        if(i_alu_sra) y_d = $signed(a) >>> b[4:0];
        if(i_alu_eq || i_alu_neq) begin
            y_d = a == b;
            if(i_alu_neq) y_d = !y_d;
        end
        if(i_alu_ge || i_alu_geu) begin
            y_d = a >= b;
            if(i_alu_ge) y_d = (a[31] ^ b[31])? b[31]:y_d;
        end
    end
    
endmodule
