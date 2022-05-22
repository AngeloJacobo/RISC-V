`timescale 1ns / 1ps
//`define HALT_ON_ILLEGAL_INSTRUCTION // stop core when instruction is illegal

module rv32i_soc_TB #(parameter TEXTFILE, DATAFILE, DATA_STARTADDR);

    /******************************* MODIFY ****************************************/
    localparam ROM_DEPTH = 8192, //number of bytes of instruction memory
               RAM_DEPTH = 8192; //number of bytes of data memory
    /*******************************************************************************/
   
    reg clk,rst_n;
    reg external_interrupt=0,software_interrupt=0;
    reg mtime_wr=0,mtimecmp_wr=0;
    reg[63:0] mtime_din,mtimecmp_din=0;
    
    integer i,j;          
    rv32i_soc #(.PC_RESET(32'h00_00_00_00), .ROM_DEPTH(ROM_DEPTH), .RAM_DEPTH(RAM_DEPTH), .CLK_FREQ_MHZ(100), .TRAP_ADDRESS(32'h00000004)) uut (
        .clk(clk),
        .rst_n(rst_n),
        //Interrupts
        .external_interrupt(external_interrupt), //interrupt from external source
        .software_interrupt(software_interrupt), //interrupt from software
        // Timer Interrupt
        .mtime_wr(mtime_wr), //write to mtime
        .mtimecmp_wr(mtimecmp_wr),  //write to mtimecmp
        .mtime_din(mtime_din), //data to be written to mtime
        .mtimecmp_din(mtimecmp_din) //data to be written to mtimecmp
        );
    
    always #5 clk=!clk;
        
        
    /*********************** initialize instruction memory and data memory **************************/
    initial begin 
        #1;
        $readmemh(TEXTFILE,uut.m1.inst_regfile); //write bin instruction to ROM
        $readmemh(DATAFILE,uut.m2.data_regfile,DATA_STARTADDR>>2); //write data memory to RAM
        //uut.m2.data_regfile[{32'h0000_1000>>2}] = 32'h12345678; //initial data for memory address 4096 
    end
    /***********************************************************************************************/
    reg[1024:0] cause;
    always begin
        #1
        case({uut.m0.m6.csr_index,uut.m0.m6.mcause_code})
            {1'b1,4'd3}: cause="SOFTWARE INTERRUPT";
            {1'b1,4'd7}: cause="TIMER INTERRUPT";
           {1'b1,4'd11}: cause="EXTERNAL INTERRUPT";
            
            {1'b0,4'd0}: cause="INSTRUCTION ADDRESS MISALIGNED";
            {1'b0,4'd2}: cause="ILLEGAL INSTRUCTION";
            {1'b0,4'd3}: cause="EBREAK";
            {1'b0,4'd4}: cause="LOAD ADDRESS MISALIGNED";
            {1'b0,4'd6}: cause="STORE ADDRESS MISALIGNED";
           {1'b0,4'd11}: cause="ECALL";
                default: cause="UNKNOWN TRAP";
        endcase
    end
    
    initial begin
        clk=0;
        rst_n=0;
        #100;
        
        rst_n=1; //release reset
        
        $display("\nStart executing instructions......\n");
        $display("Monitor All Writes to Base Register and Data Memory");
        
        /**************************************************************************************************************************/
        
        `ifndef HALT_ON_ILLEGAL_INSTRUCTION //normal test (halt core on ebreak/ecall)
        while(uut.m0.inst_q != 32'h00100073 && uut.m0.inst_q != 32'h00000073) begin// halt on ebreak or ecall instruction
            @(negedge clk);
            if( uut.m0.alu_stage) begin
                $display("\nPC: %h    %h", uut.m0.pc, uut.m0.inst); //Display PC and instruction 
            end
            
             if(uut.m0.go_to_trap && uut.m0.writeback_stage) begin //exception or interrupr detected
                case({uut.m0.m6.mcause_intbit,uut.m0.m6.mcause_code})
                    {1'b1,4'd3}: $display("  GO TO TRAP: %s","SOFTWARE INTERRUPT");
                    {1'b1,4'd7}: $display("  GO TO TRAP: %s","TIMER INTERRUPT");
                   {1'b1,4'd11}: $display("  GO TO TRAP: %s","EXTERNAL INTERRUPT"); 
                    
                    {1'b0,4'd0}: $display("  GO TO TRAP: %s","INSTRUCTION ADDRESS MISALIGNED");
                    {1'b0,4'd2}: $display("  GO TO TRAP: %s","ILLEGAL INSTRUCTION");
                    {1'b0,4'd3}: $display("  GO TO TRAP: %s","EBREAK"); 
                    {1'b0,4'd4}: $display("  GO TO TRAP: %s","LOAD ADDRESS MISALIGNED"); 
                    {1'b0,4'd6}: $display("  GO TO TRAP: %s","STORE ADDRESS MISALIGNED"); 
                   {1'b0,4'd11}: $display("  GO TO TRAP: %s","ECALL");
                        default: $display("  GO TO TRAP: %s","UNKNOWN TRAP");
                endcase
             end
             
             if(uut.m2.wr_en) begin //data memory is written
                $display("  [MEMORY] address:0x%h   value:0x%h [MASK:%b]",uut.m2.addr,uut.m2.data_in,uut.m2.wr_mask); //display address of memory changed and its new value
            end
            
            if(uut.m0.m0.wr && uut.m0.m0.rd_addr!=0) begin //base register is written
                $display("  [BASEREG] address:0x%0d   value:0x%h",uut.m0.m0.rd_addr,uut.m0.m0.rd); //display address of base reg changed and its new value
            end
            
            if(uut.m0.m6.csr_enable) begin //base register is written
                $display("  [CSR] address:0x%0h   value:0x%h",uut.m0.m6.csr_index,uut.m0.m6.csr_in); //display address of base reg changed and its new value
            end
            
            if(uut.m0.return_from_trap && uut.m0.writeback_stage) begin
                $display("  RETURN FROM TRAP"); //go back from trap via mret
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
       
        /***********************************************************************/
        
        if(uut.m0.m0.base_regfile[17] == 32'h5d) begin //Exit test using RISC-V International's riscv-tests pass/fail criteria
            if(uut.m0.m0.base_regfile[10] == 0)
                $display("\nPASS: exit code = 0x%h",uut.m0.m0.base_regfile[10]>>1);
            else begin
                $display("\nFAIL: exit code = 0x%h",uut.m0.m0.base_regfile[10]>>1);
            end
        end
        else $display("\nUNKNOWN: basereg[17] = 0x%h (must be 0x0000005d)",uut.m0.m0.base_regfile[17]);
        $stop;
        
        /**************************************************************************************************************************/
        
        
        
        /**************************************************************************************************************************/
        `else // stop core when instruction is illegal
        while (uut.iaddr < ROM_DEPTH-4 && !(uut.m0.m6.is_inst_illegal && uut.m0.m6.csr_stage)) begin //while instruction address is not yet at end of ROM and instruction is still legal
            @(negedge clk);
            if( uut.m0.alu_stage) begin
                $display("\nPC: %h    %h", uut.m0.pc, uut.m0.inst); //Display PC and instruction 
            end
            
             if(uut.m0.go_to_trap && uut.m0.writeback_stage) begin //exception or interrupr detected
                case({uut.m0.m6.mcause_intbit,uut.m0.m6.mcause_code})
                    {1'b1,4'd3}: $display("  GO TO TRAP: %s","SOFTWARE INTERRUPT");
                    {1'b1,4'd7}: $display("  GO TO TRAP: %s","TIMER INTERRUPT");
                   {1'b1,4'd11}: $display("  GO TO TRAP: %s","EXTERNAL INTERRUPT"); 
                    
                    {1'b0,4'd0}: $display("  GO TO TRAP: %s","INSTRUCTION ADDRESS MISALIGNED");
                    {1'b0,4'd2}: $display("  GO TO TRAP: %s","ILLEGAL INSTRUCTION");
                    {1'b0,4'd3}: $display("  GO TO TRAP: %s","EBREAK"); 
                    {1'b0,4'd4}: $display("  GO TO TRAP: %s","LOAD ADDRESS MISALIGNED"); 
                    {1'b0,4'd6}: $display("  GO TO TRAP: %s","STORE ADDRESS MISALIGNED"); 
                   {1'b0,4'd11}: $display("  GO TO TRAP: %s","ECALL");
                        default: $display("  GO TO TRAP: %s","UNKNOWN TRAP");
                endcase
             end
             
             if(uut.m2.wr_en) begin //data memory is written
                $display("  [MEMORY] address:0x%h   value:0x%h [MASK:%b]",uut.m2.addr,uut.m2.data_in,uut.m2.wr_mask); //display address of memory changed and its new value
            end
            
            if(uut.m0.m0.wr && uut.m0.m0.rd_addr!=0) begin //base register is written
                $display("  [BASEREG] address:0x%0d   value:0x%h",uut.m0.m0.rd_addr,uut.m0.m0.rd); //display address of base reg changed and its new value
            end
            
            if(uut.m0.m6.csr_enable) begin //base register is written
                $display("  [CSR] address:0x%0h   value:0x%h",uut.m0.m6.csr_index,uut.m0.m6.csr_in); //display address of base reg changed and its new value
            end
            
            if(uut.m0.return_from_trap && uut.m0.writeback_stage) begin
                $display("  RETURN FROM TRAP"); //go back from trap via mret
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
        
        if(uut.m0.m0.base_regfile[17] == 32'h5d) begin //Exit test using RISC-V International's riscv-tests pass/fail criteria
            if(uut.m0.m0.base_regfile[10] == 0)
                $display("\nPASS: exit code = 0x%h",uut.m0.m0.base_regfile[10]>>1);
            else begin
                $display("\nFAIL: exit code = 0x%h",uut.m0.m0.base_regfile[10]>>1);
            end
        end
        else $display("\nUNKNOWN: basereg[17] = 0x%h (must be 0x0000005d)",uut.m0.m0.base_regfile[17]);
        $stop;
        
        `endif
        /**************************************************************************************************************************/
        
    end
    
    initial begin   //external interrupt at 5 ms
        #5_005_000; //(5ms)
        external_interrupt = 1;
        wait(uut.m0.go_to_trap);
        external_interrupt = 0;
    end
    
    initial begin   //software interrupt at 10 ms
        #10_005_000; //(5ms)
        software_interrupt = 1;
        wait(uut.m0.go_to_trap);
        software_interrupt = 0;
    end
    
    initial begin   //timer interrupt at 15 ms
    #1000
        mtimecmp_din = 15; 
        mtimecmp_wr = 1;
    #1000
        mtimecmp_wr = 0;
    end
endmodule

