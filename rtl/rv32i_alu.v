//arithmetic logic unit [EXECUTE STAGE]

`timescale 1ns / 1ps

module rv32i_alu(
    input wire[31:0] a, //rs1 or pc
    input wire[31:0] b, //rs2 or imm 
    input wire[3:0] op, //operation
    output reg[31:0] y //result of arithmetic operation
);
    //operations supported by this ALU
    localparam  ADD = 0, //addition
                SUB = 1, //subtraction
                SLT = 2, //set if less than
               SLTU = 3, //set if less than unsigned
                XOR = 4, //bitwise xor
                 OR = 5, //bitwise or
                AND = 6, //bitwise and
                SLL = 7, //shift left logical
                SRL = 8, //shift right logical
                SRA = 9, //shift right arithmetic
                 EQ = 10, //equal
                NEQ = 11, //not equal
                 GE = 12, //greater than or equal
                GEU = 13; //greater than or equal unisgned
    
    //combinational logic for alu   
    always @* begin
        case(op)
            ADD: y = a + b;
            SUB: y = a - b;
       SLT,SLTU: begin
                  y = a < b;
                  if(op == SLT) y = (a[31] ^ b[31]) ? a[31]:y;
                 end
            XOR: y = a ^ b;
             OR: y = a | b;
            AND: y = a & b;
            SLL: y = a << b[4:0];  
            SRL: y = a >> b[4:0];
            SRA: y = a >>> b[4:0];
         EQ,NEQ: begin
                  y = a == b;
                  if(op == NEQ) y = !y;
                 end
         GE,GEU: begin
                  y =  a >= b;
                  if(op == GE) y = (a[31] ^ b[31]) ? b[31]:y;
                 end 
        default: y = 0;
        endcase
    end
    
endmodule
