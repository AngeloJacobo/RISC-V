`timescale 1ns / 1 ps

module rv32i_alu_TB;

reg signed[31:0] a,b;
reg [3:0] op;
wire signed[31:0] y;

rv32i_alu uut(
	.a(a), //rs1 or pc
	.b(b), //rs2 or imm 
	.op(op), //all 10 operations for R-type
	.y(y) //result of arithmetic operation
);
    reg[4*8-1:0] s;//stores string fot type of operation
    
    always begin
        #1;
        case(op)
            0: s="ADD";
            1: s="SUB";
            2: s="SLT";
            3: s="SLTU";
            4: s="XOR";
            5: s="OR";
            6: s="AND"; 
            7: s="SLL";
            8: s="SRL";
            9: s="SRA";
            10: s="EQ";
            11: s="NEQ";
            12: s="GE";
            13: s="GEU";
           default: s="XXXX";
        endcase
    end
    

    initial begin
        #100;
        $monitor("%s   %0d",s,y);
        
        
        a=1000; //test 1
        b=500;
        $display("OPERANDS: a=%0d b=%0d",a,b);
        $display("op    result"); 
        for(op=0; op<=13 ; op=op+1) #100;
        
        a=500; //test 2
        b=1000;
        $display("OPERANDS: a=%0d b=%0d",a,b);
        $display("op    result"); 
        for(op=0; op<=13 ; op=op+1) #100;
        
        $display("\n"); //test 3
        a=-1000;
        b=-500;
        $display("OPERANDS: a=%0d b=%0d",a,b);
        $display("op    result"); 
        for(op=0; op<=13 ; op=op+1) #100;
        
        $display("\n"); //test 4
        a=-500;
        b=-1000;
        $display("OPERANDS: a=%0d b=%0d",a,b);
        $display("op    result"); 
        for(op=0; op<=13 ; op=op+1) #100;
        
        $display("\n"); //test 5
        a=1000;
        b=-1000;
        $display("OPERANDS: a=%0d b=%0d",a,b);
        $display("op    result"); 
        for(op=0; op<=13 ; op=op+1) #100;
        
        $display("\n"); //test 6
        a=-1000;
        b=-1000;
        $display("OPERANDS: a=%0d b=%0d",a,b);
        $display("op    result"); 
        for(op=0; op<=13 ; op=op+1) #100;
        
        $display("\n"); //test 7
        a=0;
        b=0;
        $display("OPERANDS: a=%0d b=%0d",a,b);
        $display("op    result"); 
        for(op=0; op<=13 ; op=op+1) #100;
        
        $stop;
        
    end
    
    
    
endmodule