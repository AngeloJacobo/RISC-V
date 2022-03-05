`timescale 1ns / 1ps

module rv32i_soc_TB;

    reg clk,rst_n;
    integer i,j;
    localparam ROM_BYTES = 64, //number of bytes of instruction memory
               RAM_BYTES = 8192; //number of bytes of data memory
               
    rv32i_soc #(.PC_RESET(32'h00_00_00_00), .ROM_BYTES(ROM_BYTES), .RAM_BYTES(RAM_BYTES)) uut (
        .clk(clk),
        .rst_n(rst_n)
        );
    
    always #10 clk=!clk;
        
        
    /*********************** initialize instruction memory and data memory **************************/
    initial begin 
        $readmemh("inst.hex",uut.m1.regfile); //write hex instruction to ROM
        uut.m2.regfile[{32'h0000_1000>>2}] = 32'h12345678; //initial data for memory address 4096 
    end
    /***********************************************************************************************/
    
        
    initial begin
        clk=0;
        rst_n=0;
        #100;
        
        rst_n=1; //release reset
        $display("\nStart executing instructions......\n");
        $display("Monitor All Writes to Base Register and Data Memory");
        
        while (uut.iaddr < ROM_BYTES) begin //while instruction address is not yet at end of ROM
            @(negedge clk);
            if(uut.m2.wr_en) begin //data memory is written
                $display("[MEMORY] address:0x%h   value:0x%h [MASK:%b]",uut.m2.addr,uut.m2.data_in,uut.m2.wr_mask); //display address of memory changed and its new value
            end
            if(uut.m0.m0.wr) begin //base register is written
                $display("[BASEREG] address:0x%h   value:0x%h",uut.m0.m0.rd_addr,uut.m0.m0.rd); //display address of base reg changed and its new value
            end
        end
        $display("\nAll instructions executed......");
        
        /************* Dump Base Register and Memory Values *******************/
        $display("\nFinal Register State:");
        
        for(i=0; i<8; i=i+1) begin
            for(j=0; j<4 ; j=j+1) begin
                $write("0x%02d: 0x%h\t",4*i+j,uut.m0.m0.regfile[4*i+j]);
            end
            $write("\n");
        end
        $display("\n\nFinal Memory State:");
        for(i=32'h1000; i<32'h101c ; i=i+4) begin
            $display("0x%0h: 0x%h",i,uut.m2.regfile[i>>2]);
        end
       
        /**********************************************************/
        $stop;
    end
endmodule
