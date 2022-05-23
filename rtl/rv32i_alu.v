//arithmetic logic unit [EXECUTE STAGE]

`timescale 1ns / 1ps
`default_nettype none

module rv32i_alu(
    input wire i_clk,i_rst_n,
    input wire i_alu, //update y output iff stage is currently on EXECUTE (i_alu stage)
    input wire[31:0] i_a, //rs1 or pc
    input wire[31:0] i_b, //rs2 or imm 
    output reg[31:0] o_y, //result of arithmetic operation
    /// i_alu Operations ///
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
    input wire i_alu_geu //greater than or equal unisgned
);
    initial begin
        o_y = 0;
    end
    
    reg[31:0] y_d;

    //register the output of i_alu
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) o_y <= 0;
        else o_y <= i_alu ? y_d:o_y; //update o_y output iff stage is currently on EXECUTE (i_alu stage)
    end 

    //i_alu core (run in parallel instead of priority logic for less
    always @* begin  //resource utilization)
        y_d = 0;

        if(i_alu_add) y_d = i_a + i_b;
        if(i_alu_sub) y_d = i_a - i_b;
        if(i_alu_slt || i_alu_sltu) begin
            y_d = i_a < i_b;
            if(i_alu_slt) y_d = (i_a[31] ^ i_b[31])? i_a[31]:y_d;
        end 
        if(i_alu_xor) y_d = i_a ^ i_b;
        if(i_alu_or)  y_d = i_a | i_b;
        if(i_alu_and) y_d = i_a & i_b;
        if(i_alu_sll) y_d = i_a << i_b[4:0];
        if(i_alu_srl) y_d = i_a >> i_b[4:0];
        if(i_alu_sra) y_d = $signed(i_a) >>> i_b[4:0];
        if(i_alu_eq || i_alu_neq) begin
            y_d = i_a == i_b;
            if(i_alu_neq) y_d = !y_d;
        end
        if(i_alu_ge || i_alu_geu) begin
            y_d = i_a >= i_b;
            if(i_alu_ge) y_d = (i_a[31] ^ i_b[31])? i_b[31]:y_d;
        end
    end
    
endmodule
