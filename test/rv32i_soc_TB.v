`timescale 1ns / 1ns
`default_nettype none
`define DISPLAY
//`define HALT_ON_ILLEGAL_INSTRUCTION // stop core when instruction is illegal
 //`define HALT_ON_EBREAK // halt core on ebreak
// `define HALT_ON_ECALL // halt core on ecall
`include "rv32i_header.vh"

module rv32i_soc_TB;
    parameter MEMORY="memory.mem";
    parameter ZICSR_EXTENSION = 1;
    /******************************* MODIFY ****************************************/
    localparam MEMORY_DEPTH = 81920, //number of memory bytes
               DATA_START_ADDR = 32'h1004; //starting address of data memory to be displayed
    /*******************************************************************************/
   
    reg clk,rst_n;
    reg temp;
    integer i,j;          
    
    
    rv32i_soc #(.PC_RESET(32'h00_00_00_00), .MEMORY_DEPTH(MEMORY_DEPTH), .CLK_FREQ_MHZ(100), .TRAP_ADDRESS(32'h00000004), .ZICSR_EXTENSION(ZICSR_EXTENSION)) uut (
        .i_clk(clk),
        .i_rst(!rst_n)
        );
    
    always #5 clk=!clk; //100MHz clock
    
    initial begin //2nd reset to test resetting while core is executing instruction
        #200;
        rst_n = 0;
        #500;
        rst_n = 1;
    end  
        
    /*********************** initialize instruction memory and data memory **************************/
    initial begin 
        #1;
        $readmemh(MEMORY,uut.m1.memory_regfile); //write instruction and data to memory
        //uut.m1.memory_regfile[{32'h0000_1000>>2}] = 32'h12345678; //initial data memory 
    end
    /***********************************************************************************************/
    reg[1024:0] cause;
    
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0,rv32i_soc_TB);
        $dumpvars(0,uut.m0.m0.base_regfile[1],uut.m0.m0.base_regfile[2],uut.m0.m0.base_regfile[3],uut.m0.m0.base_regfile[4],uut.m0.m0.base_regfile[5]);
        $dumpvars(0,uut.m0.m0.base_regfile[6],uut.m0.m0.base_regfile[7],uut.m0.m0.base_regfile[8],uut.m0.m0.base_regfile[9],uut.m0.m0.base_regfile[10]);
        $dumpvars(0,uut.m0.m0.base_regfile[11],uut.m0.m0.base_regfile[12],uut.m0.m0.base_regfile[13],uut.m0.m0.base_regfile[14],uut.m0.m0.base_regfile[15]);
        $dumpvars(0,uut.m0.m0.base_regfile[16],uut.m0.m0.base_regfile[17],uut.m0.m0.base_regfile[18],uut.m0.m0.base_regfile[19],uut.m0.m0.base_regfile[20]);
        $dumpvars(0,uut.m0.m0.base_regfile[21],uut.m0.m0.base_regfile[22],uut.m0.m0.base_regfile[23],uut.m0.m0.base_regfile[24],uut.m0.m0.base_regfile[25]);
        $dumpvars(0,uut.m0.m0.base_regfile[26],uut.m0.m0.base_regfile[27],uut.m0.m0.base_regfile[28],uut.m0.m0.base_regfile[29],uut.m0.m0.base_regfile[30]);
        $dumpvars(0,uut.m0.m0.base_regfile[31]);
		
        rst_n = 1;
        #50;
        clk=0;
        rst_n=0;
        #50;
        
        rst_n=1; //release reset
        
        $display("\nStart executing instructions......\n");
        $display("Monitor All Writes to Base Register and Data Memory");
        
        /**************************************************************************************************************************/
		
        while(  `ifdef HALT_ON_ILLEGAL_INSTRUCTION
                    uut.iaddr < MEMORY_DEPTH-4 && !(uut.m0.zicsr.m6.i_is_inst_illegal && uut.m0.zicsr.m6.i_ce) //exception testing (halt core only when instruction is illegal)
                `elsif HALT_ON_EBREAK
                    !uut.m0.alu_exception[`EBREAK] //ebreak test (halt core on ebreak)
                `elsif HALT_ON_ECALL
                    !uut.m0.alu_exception[`ECALL] //ecall test (halt core on ecall)
                `else
                    !uut.m0.alu_exception[`ECALL] && !uut.m0.alu_exception[`EBREAK] //normal test (halt core on ebreak/ecall)
                `endif
             ) begin
             
            
            @(negedge clk);
            `ifdef DISPLAY
            if(ZICSR_EXTENSION != 0) begin
                if(!uut.m0.stall_memoryaccess && uut.m0.zicsr.m6.csr_enable) begin //csr is written
                    $display("\nPC: %h    %h [%s]\n  [CSR] address:0x%0h   value:0x%h ",uut.m0.zicsr.m6.i_pc, uut.m1.memory_regfile[{uut.m0.zicsr.m6.i_pc}>>2],"SYSTEM",uut.m0.zicsr.m6.i_csr_index,uut.m0.zicsr.m6.csr_in); //display address of csr changed and its new value
                end
            end
            
            if(uut.m0.writeback_ce && !uut.m0.stall_writeback) begin
                    if(uut.m0.memoryaccess_opcode[`RTYPE]) $display("\nPC: %h    %h [%s]", uut.m0.m5.i_pc, uut.m1.memory_regfile[{uut.m0.m5.i_pc}>>2],"RTYPE"); //Display PC and instruction 
                    else if(uut.m0.memoryaccess_opcode[`ITYPE]) $display("\nPC: %h    %h [%s]", uut.m0.m5.i_pc, uut.m1.memory_regfile[{uut.m0.m5.i_pc}>>2],"ITYPE"); //Display PC and instruction      
                    else if(uut.m0.memoryaccess_opcode[`LOAD]) $display("\nPC: %h    %h [%s]", uut.m0.m5.i_pc, uut.m1.memory_regfile[{uut.m0.m5.i_pc}>>2],"LOAD"); //Display PC and instruction 
                    else if(uut.m0.memoryaccess_opcode[`STORE]) $display("\nPC: %h    %h [%s]", uut.m0.m5.i_pc, uut.m1.memory_regfile[{uut.m0.m5.i_pc}>>2],"STORE"); //Display PC and instruction 
                    else if(uut.m0.memoryaccess_opcode[`BRANCH]) $display("\nPC: %h    %h [%s]", uut.m0.m5.i_pc, uut.m1.memory_regfile[{uut.m0.m5.i_pc}>>2],"BRANCH"); //Display PC and instruction 
                    else if(uut.m0.memoryaccess_opcode[`JAL]) $display("\nPC: %h    %h [%s]", uut.m0.m5.i_pc, uut.m1.memory_regfile[{uut.m0.m5.i_pc}>>2],"JAL"); //Display PC and instruction 
                    else if(uut.m0.memoryaccess_opcode[`JALR]) $display("\nPC: %h    %h [%s]", uut.m0.m5.i_pc, uut.m1.memory_regfile[{uut.m0.m5.i_pc}>>2],"JALR"); //Display PC and instruction 
                    else if(uut.m0.memoryaccess_opcode[`LUI]) $display("\nPC: %h    %h [%s]", uut.m0.m5.i_pc, uut.m1.memory_regfile[{uut.m0.m5.i_pc}>>2],"LUI"); //Display PC and instruction 
                    else if(uut.m0.memoryaccess_opcode[`AUIPC]) $display("\nPC: %h    %h [%s]", uut.m0.m5.i_pc, uut.m1.memory_regfile[{uut.m0.m5.i_pc}>>2],"AUIPC"); //Display PC and instruction 
                    else if(uut.m0.memoryaccess_opcode[`SYSTEM]) $display("\nPC: %h    %h [%s]", uut.m0.m5.i_pc, uut.m1.memory_regfile[{uut.m0.m5.i_pc}>>2],"SYSTEM"); //Display PC and instruction 
                    else if(uut.m0.memoryaccess_opcode[`FENCE]) $display("\nPC: %h    %h [%s]", uut.m0.m5.i_pc, uut.m1.memory_regfile[{uut.m0.m5.i_pc}>>2],"FENCE"); //Display PC and instruction 
                    else $display("\nPC: %h    %h [%s]", uut.m0.m5.i_pc, uut.m1.memory_regfile[{uut.m0.m5.i_pc}>>2],"UNKNOWN INSTRUCTION"); //Display PC and instruction 
                    
                #1;
                if(ZICSR_EXTENSION != 0) begin
                     if(uut.m0.csr_go_to_trap) begin //exception or interrupt detected
                        case({uut.m0.zicsr.m6.mcause_intbit,uut.m0.zicsr.m6.mcause_code})
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
                 end
                 if(uut.m1.i_wb_we) begin //data memory is written
                    $display("  [MEMORY] address:0x%h   value:0x%h [MASK:%b]",uut.m1.i_wb_addr,uut.m1.i_wb_data,uut.m1.i_wb_sel); //display address of memory changed and its new value
                end
                
                if(uut.m0.m5.o_wr_rd && uut.m0.m5.o_rd_addr!=0) begin //base register is written
                    $display("  [BASEREG] address:0x%0d   value:0x%h",uut.m0.m5.o_rd_addr,uut.m0.m5.o_rd); //display address of base reg changed and its new value
                end
                
                if(uut.m0.csr_return_from_trap) begin
                    $display("  RETURN FROM TRAP"); //go back from trap via mret
                end
                
            end
            #1; 
            `endif
        
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
        if(ZICSR_EXTENSION != 0) begin
            if(uut.m0.m0.base_regfile[17] == 32'h5d) begin //Exit test using RISC-V International's riscv-tests pass/fail criteria
                if(uut.m0.m0.base_regfile[10] == 0)
                    $display("\nPASS: exit code = 0x%h \n[%0d instructions in %0d clk cycles]\n",uut.m0.m0.base_regfile[10]>>1,uut.m0.zicsr.m6.minstret,uut.m0.zicsr.m6.mcycle);
                else begin
                    $display("\nFAIL: exit code = 0x%h \n[%0d instructions in %0d clk cycles]\n",uut.m0.m0.base_regfile[10]>>1,uut.m0.zicsr.m6.minstret,uut.m0.zicsr.m6.mcycle);
                end
            end
            else $display("\nUNKNOWN: basereg[17] = 0x%h (must be 0x0000005d)",uut.m0.m0.base_regfile[17]);
        end
        else begin
            if(uut.m0.m0.base_regfile[17] == 32'h5d) begin //Exit test using RISC-V International's riscv-tests pass/fail criteria
                if(uut.m0.m0.base_regfile[10] == 0)
                    $display("\nPASS: exit code = 0x%h\n",uut.m0.m0.base_regfile[10]>>1);
                else begin
                    $display("\nFAIL: exit code = 0x%h\n",uut.m0.m0.base_regfile[10]>>1);
                end
            end
            else $display("\nUNKNOWN: basereg[17] = 0x%h (must be 0x0000005d)",uut.m0.m0.base_regfile[17]);
        end
        $stop;
        
        /**************************************************************************************************************************/
        
    end
	initial begin
		#100_000; //simulation time limit
		`ifdef LONGER_SIM_LIMIT
		#25_000_000;
		`endif
		$stop;
	end
endmodule
