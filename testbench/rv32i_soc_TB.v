`timescale 1ns / 1ps

module rv32i_soc_TB;

    reg clk,rst_n;
    
    rv32i_soc uut(
        .clk(clk),
        .rst_n(rst_n)
        );
        
    always #10 clk=!clk;
        
    initial begin
        clk=0;
        rst_n=1;
        $display("Monitor All Changes/Writes to Base Reg and Data Memory");
        #2000;
        $stop;
    end
endmodule
