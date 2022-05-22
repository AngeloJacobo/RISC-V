//arithmetic logic unit [EXECUTE STAGE]

`timescale 1ns / 1ps
`default_nettype none

module rv32i_alu(
    input wire clk,rst_n,
    input wire alu, //update y output iff stage is currently on EXECUTE (ALU stage)
    input wire[31:0] a, //rs1 or pc
    input wire[31:0] b, //rs2 or imm 
    output reg[31:0] y, //result of arithmetic operation
    /// ALU Operations ///
    input wire alu_add, //addition
    input wire alu_sub, //subtraction
    input wire alu_slt, //set if less than
    input wire alu_sltu, //set if less than unsigned 
    input wire alu_xor, //bitwise xor
    input wire alu_or, //bitwise or
    input wire alu_and, //bitwise and
    input wire alu_sll, //shift left logical
    input wire alu_srl, //shift right logical
    input wire alu_sra, //shift right arithmetic
    input wire alu_eq, //equal
    input wire alu_neq, //not equal
    input wire alu_ge, //greater than or equal
    input wire alu_geu //greater than or equal unisgned
);
    initial begin
        y = 0;
    end
    
    reg[31:0] y_d;

    //register the output of ALU
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) y <= 0;
        else y <= alu ? y_d:y; //update y output iff stage is currently on EXECUTE (ALU stage)
    end 

    //ALU core (run in parallel instead of priority logic for less
    always @* begin  //resource utilization)
        y_d = 0;

        if(alu_add) y_d = a + b;
        if(alu_sub) y_d = a - b;
        if(alu_slt || alu_sltu) begin
            y_d = a < b;
            if(alu_slt) y_d = (a[31] ^ b[31])? a[31]:y_d;
        end 
        if(alu_xor) y_d = a ^ b;
        if(alu_or)  y_d = a | b;
        if(alu_and) y_d = a & b;
        if(alu_sll) y_d = a << b[4:0];
        if(alu_srl) y_d = a >> b[4:0];
        if(alu_sra) y_d = $signed(a) >>> b[4:0];
        if(alu_eq || alu_neq) begin
            y_d = a == b;
            if(alu_neq) y_d = !y_d;
        end
        if(alu_ge || alu_geu) begin
            y_d = a >= b;
            if(alu_ge) y_d = (a[31] ^ b[31])? b[31]:y_d;
        end
    end
    
endmodule
