`timescale 1ns / 1ps
`define DEBUG //debugging mode: display write actions (basereg and datamem) and dump all 32 basereg

module rv32i_soc_TB #(parameter TEXTFILE, DATAFILE, DATA_STARTADDR);

    /******************************* MODIFY ****************************************/
    localparam ROM_DEPTH = 8192, //number of bytes of instruction memory
               RAM_DEPTH = 8192; //number of bytes of data memory
               //TEXTFILE = ".././hexfile/text.bin";  //text section of the executable file
               //DATAFILE = ".././hexfile/data.bin";  //data section of the executable file
    /*******************************************************************************/
    
    
               
    reg clk,rst_n;
    integer i,j;          
    rv32i_soc #(.PC_RESET(32'h00_00_00_00), .ROM_DEPTH(ROM_DEPTH), .RAM_DEPTH(RAM_DEPTH)) uut (
        .clk(clk),
        .rst_n(rst_n)
        );
    
    always #10 clk=!clk;
        
        
    /*********************** initialize instruction memory and data memory **************************/
    initial begin 
        $readmemh(TEXTFILE,uut.m1.inst_regfile); //write bin instruction to ROM
        $readmemh(DATAFILE,uut.m2.data_regfile,DATA_STARTADDR>>2); //write data memory to RAM
        //uut.m2.data_regfile[{32'h0000_1000>>2}] = 32'h12345678; //initial data for memory address 4096 
    end
    /***********************************************************************************************/
    
        
    initial begin
        clk=0;
        rst_n=0;
        #100;
        
        rst_n=1; //release reset
        
        
        `ifdef DEBUG //debugging mode: display write actions (basereg and datamem) and dump all 32 basereg
        $display("\nStart executing instructions......\n");
        $display("Monitor All Writes to Base Register and Data Memory");
        
        // while (uut.iaddr < ROM_DEPTH-4) begin //while instruction address is not yet at end of ROM
        while(uut.m0.inst_q != 32'h00100073) begin// halt on ebreak instruction
            @(negedge clk);
            if(uut.m2.wr_en) begin //data memory is written
                $display("[MEMORY] address:0x%h   value:0x%h [MASK:%b]",uut.m2.addr,uut.m2.data_in,uut.m2.wr_mask); //display address of memory changed and its new value
            end
            if(uut.m0.m0.wr && uut.m0.m0.rd_addr!=0) begin //base register is written
                $display("[BASEREG] address:0x%0d   value:0x%h",uut.m0.m0.rd_addr,uut.m0.m0.rd); //display address of base reg changed and its new value
            end
        end
        $display("\nAll instructions executed......");
        
        /************* Dump Base Register and Memory Values *******************/
        $display("\nFinal Register State:");
        
        for(i=0; i<8; i=i+1) begin
            for(j=0; j<4 ; j=j+1) begin
                $write("0x%02d: 0x%h\t",4*i+j,uut.m0.m0.base_regfile[4*i+j]);
            end
            $write("\n");
        end
        $display("\n\nFinal Memory State:");
        for(i=32'h1000; i<32'h101c ; i=i+4) begin
            $display("0x%0h: 0x%h",i,uut.m2.data_regfile[i>>2]);
        end
       
        /**********************************************************/
        `else
            while(uut.m0.inst_q != 32'h00100073) @(negedge clk); // halt on ebreak instruction
        `endif
        
        if(uut.m0.m0.base_regfile[17] == 32'h5d) begin //Exit test using RISC-V International's riscv-tests pass/fail criteria
            if(uut.m0.m0.base_regfile[10] == 0)
                $display("\nPASS: exit code = 0x%h",uut.m0.m0.base_regfile[10]>>1);
            else begin
                $display("\nFAIL: exit code = 0x%h",uut.m0.m0.base_regfile[10]>>1);
            end
        end
        else $display("\nUNKNOWN: regfile[17] = 0x%h (must be 0x0000005d)",uut.m0.m0.base_regfile[17]);
        $stop;
    end
endmodule
