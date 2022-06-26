`timescale 1ns / 1ns

//`define HALT_ON_ILLEGAL_INSTRUCTION // stop core when instruction is illegal
// `define HALT_ON_EBREAK // halt core on ebreak
// `define HALT_ON_ECALL // halt core on ecall


module rv32i_soc_TB;
    parameter MEMORY="memory.mem";

    /******************************* MODIFY ****************************************/
    localparam MEMORY_DEPTH = 8192, //number of memory bytes
               DATA_START_ADDR = 32'h1080; //starting address of data memory to be displayed
    /*******************************************************************************/
   
    reg clk,rst_n;
    reg external_interrupt=0,software_interrupt=0;
    reg mtime_wr=0,mtimecmp_wr=0;
    reg[63:0] mtime_din,mtimecmp_din=0;
    reg HALT_CONDITION = 0;
    integer i,j;          
    rv32i_soc #(.PC_RESET(32'h00_00_00_00), .MEMORY_DEPTH(MEMORY_DEPTH), .CLK_FREQ_MHZ(100), .TRAP_ADDRESS(32'h00000004)) uut (
        .i_clk(clk),
        .i_rst_n(rst_n),
        //Interrupts
        .i_external_interrupt(external_interrupt), //interrupt from external source
        .i_software_interrupt(software_interrupt), //interrupt from software
        // Timer Interrupt
        .i_mtime_wr(mtime_wr), //write to mtime
        .i_mtimecmp_wr(mtimecmp_wr),  //write to mtimecmp
        .i_mtime_din(mtime_din), //data to be written to mtime
        .i_mtimecmp_din(mtimecmp_din) //data to be written to mtimecmp
        );
    
    always #5 clk=!clk;
        
        
    /*********************** initialize instruction memory and data memory **************************/
    initial begin 
        #1;
        $readmemh(MEMORY,uut.m1.memory_regfile); //write instruction and data to memory
        //uut.m1.memory_regfile[{32'h0000_1000>>2}] = 32'h12345678; //initial data for memory address 4096 
    end
    /***********************************************************************************************/
    reg[1024:0] cause;
    
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0,rv32i_soc_TB);
        clk=0;
        rst_n=0;
        #100;
        
        rst_n=1; //release reset
        
        $display("\nStart executing instructions......\n");
        $display("Monitor All Writes to Base Register and Data Memory");
        
        /**************************************************************************************************************************/


            
        while(  `ifdef HALT_ON_ILLEGAL_INSTRUCTION
                    uut.iaddr < MEMORY_DEPTH-4 && !(uut.m0.m6.i_is_inst_illegal && uut.m0.m6.i_ce) //exception testing (halt core only when instruction is illegal)
                `elsif HALT_ON_EBREAK
                    !uut.m0.is_ebreak_memoryaccess //ebreak test (halt core on ebreak)
                `elsif HALT_ON_ECALL
                    !uut.m0.is_ecall_memoryaccess //ecall test (halt core on ecall)
                `else
                    !uut.m0.is_ecall_memoryaccess && !uut.m0.is_ebreak_memoryaccess //normal test (halt core on ebreak/ecall)
                `endif
             ) begin

            @(negedge clk);
            #1;
             if(uut.m0.ce_stage4 && !uut.m0.stall[4] && uut.m0.m6.csr_enable) begin //csr is written
                $display("\nPC: %h    %h [%s]\n  [CSR] address:0x%0h   value:0x%h ",uut.m0.m5.pc, uut.m1.memory_regfile[{uut.m0.m5.pc}>>2],"SYSTEM",uut.m0.m6.i_csr_index,uut.m0.m6.csr_in); //display address of csr changed and its new value
            end
            
            if(uut.m0.ce_stage5) begin
                    if(uut.m0.opcode_rtype_memoryaccess) $display("\nPC: %h    %h [%s]", uut.m0.m5.pc, uut.m1.memory_regfile[{uut.m0.m5.pc}>>2],"RTYPE"); //Display PC and instruction 
                    else if(uut.m0.opcode_itype_memoryaccess) $display("\nPC: %h    %h [%s]", uut.m0.m5.pc, uut.m1.memory_regfile[{uut.m0.m5.pc}>>2],"ITYPE"); //Display PC and instruction          
                    else if(uut.m0.opcode_load_memoryaccess) $display("\nPC: %h    %h [%s]", uut.m0.m5.pc, uut.m1.memory_regfile[{uut.m0.m5.pc}>>2],"LOAD"); //Display PC and instruction 
                    else if(uut.m0.opcode_store_memoryaccess) $display("\nPC: %h    %h [%s]", uut.m0.m5.pc, uut.m1.memory_regfile[{uut.m0.m5.pc}>>2],"STORE"); //Display PC and instruction 
                    else if(uut.m0.opcode_branch_memoryaccess) $display("\nPC: %h    %h [%s]", uut.m0.m5.pc, uut.m1.memory_regfile[{uut.m0.m5.pc}>>2],"BRANCH"); //Display PC and instruction 
                    else if(uut.m0.opcode_jal_memoryaccess) $display("\nPC: %h    %h [%s]", uut.m0.m5.pc, uut.m1.memory_regfile[{uut.m0.m5.pc}>>2],"JAL"); //Display PC and instruction 
                    else if(uut.m0.opcode_jalr_memoryaccess) $display("\nPC: %h    %h [%s]", uut.m0.m5.pc, uut.m1.memory_regfile[{uut.m0.m5.pc}>>2],"JALR"); //Display PC and instruction 
                    else if(uut.m0.opcode_lui_memoryaccess) $display("\nPC: %h    %h [%s]", uut.m0.m5.pc, uut.m1.memory_regfile[{uut.m0.m5.pc}>>2],"LUI"); //Display PC and instruction 
                    else if(uut.m0.opcode_auipc_memoryaccess) $display("\nPC: %h    %h [%s]", uut.m0.m5.pc, uut.m1.memory_regfile[{uut.m0.m5.pc}>>2],"AUIPC"); //Display PC and instruction 
                    else if(uut.m0.opcode_system_memoryaccess) $display("\nPC: %h    %h [%s]", uut.m0.m5.pc, uut.m1.memory_regfile[{uut.m0.m5.pc}>>2],"SYSTEM"); //Display PC and instruction 
                    else if(uut.m0.opcode_fence_memoryaccess) $display("\nPC: %h    %h [%s]", uut.m0.m5.pc, uut.m1.memory_regfile[{uut.m0.m5.pc}>>2],"FENCE"); //Display PC and instruction 
                    else $display("\nPC: %h    %h [%s]", uut.m0.m5.pc, uut.m1.memory_regfile[{uut.m0.m5.pc}>>2],"UNKNOWN INSTRUCTION"); //Display PC and instruction 
                    
                #1;
                
                 if(uut.m0.go_to_trap) begin //exception or interrupt detected
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
                 
                 if(uut.m1.i_wr_en) begin //data memory is written
                    $display("  [MEMORY] address:0x%h   value:0x%h [MASK:%b]",uut.m1.i_data_addr,uut.m1.i_data_in,uut.m1.i_wr_mask); //display address of memory changed and its new value
                end
                
                if(uut.m0.m5.wr_rd_d && uut.m0.rd_addr_memoryaccess!=0) begin //base register is written
                    $display("  [BASEREG] address:0x%0d   value:0x%h",uut.m0.rd_addr_memoryaccess,uut.m0.m5.o_rd_d); //display address of base reg changed and its new value
                end
                
                if(uut.m0.return_from_trap) begin
                    $display("  RETURN FROM TRAP"); //go back from trap via mret
                end
                
            end
            

        
        end

        
        @(negedge clk);
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
        for(i=DATA_START_ADDR; i<(DATA_START_ADDR+10*4) ; i=i+4) begin
            $display("0x%0h: 0x%h",i,uut.m1.memory_regfile[i>>2]);
        end
       
        /***********************************************************************/
        
        if(uut.m0.m0.base_regfile[17] == 32'h5d) begin //Exit test using RISC-V International's riscv-tests pass/fail criteria
            if(uut.m0.m0.base_regfile[10] == 0)
                $display("\nPASS: exit code = 0x%h \n[%0d instructions in %0d clk cycles]\n",uut.m0.m0.base_regfile[10]>>1,uut.m0.m6.minstret,uut.m0.m6.mcycle);
            else begin
                $display("\nFAIL: exit code = 0x%h \n[%0d instructions in %0d clk cycles]\n",uut.m0.m0.base_regfile[10]>>1,uut.m0.m6.minstret,uut.m0.m6.mcycle);
            end
        end
        else $display("\nUNKNOWN: basereg[17] = 0x%h (must be 0x0000005d)",uut.m0.m0.base_regfile[17]);
        $stop;
        
        /**************************************************************************************************************************/
        
    end
    
    initial begin   //external interrupt at 5 ms
        #5_005_000; //(5ms)
        external_interrupt = 1;
        wait(uut.m0.ce_stage5 && uut.m0.go_to_trap);
        external_interrupt = 0;
    end
    
    initial begin   //software interrupt at 10 ms
        #10_005_000; //(5ms)
        software_interrupt = 1;
        wait(uut.m0.ce_stage5 && uut.m0.go_to_trap);
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

