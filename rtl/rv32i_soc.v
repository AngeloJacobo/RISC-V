`timescale 1ns / 1ps
`default_nettype none

//complete package containing the rv32i_core , ROM (for instruction memory) , and RAM (for data memory]
module rv32i_soc #(parameter CLK_FREQ_MHZ=100, PC_RESET=32'h00_00_00_00, TRAP_ADDRESS=32'h00_00_00_00, MEMORY_DEPTH=1024) ( 
    input wire clk,
    input wire rst_n,
    //Interrupts
    input wire external_interrupt, //interrupt from external source
    input wire software_interrupt, //interrupt from software
    // Timer Interrupt
    input wire mtime_wr, //write to mtime
    input wire mtimecmp_wr,  //write to mtimecmp
    input wire[63:0] mtime_din, //data to be written to mtime
    input wire[63:0] mtimecmp_din //data to be written to mtimecmp
    );
    
    //Instruction Memory Interface
    wire[31:0] inst; 
    wire[31:0] iaddr;  
    //Data Memory Interface
    wire[31:0] din; //data r
    wire[31:0] dout; //data to be stored to memory
    wire[31:0] daddr; //address of data memory for store/load
    wire[3:0] wr_mask; //write mask control
    wire wr_en; //write enable 
        
    rv32i_core #(.PC_RESET(PC_RESET),.CLK_FREQ_MHZ(CLK_FREQ_MHZ), .TRAP_ADDRESS(TRAP_ADDRESS)) m0( //main RV32I core
        .clk(clk),
        .rst_n(rst_n),
        //Instruction Memory Interface
        .inst(inst), //32-bit instruction
        .iaddr(iaddr), //address of instruction 
        //Data Memory Interface
        .din(din), //data retrieve from memory
        .dout(dout), //data to be stored to memory
        .daddr(daddr), //address of data memory for store/load
        .wr_mask(wr_mask), //write mask control
        .wr_en(wr_en), //write enable 
        //Interrupts
        .external_interrupt(external_interrupt), //interrupt from external source
        .software_interrupt(software_interrupt), //interrupt from software
        // Timer Interrupt
        .mtime_wr(mtime_wr), //write to mtime
        .mtimecmp_wr(mtimecmp_wr),  //write to mtimecmp
        .mtime_din(mtime_din), //data to be written to mtime
        .mtimecmp_din(mtimecmp_din) //data to be written to mtimecmp
     );
        
     main_memory #(.MEMORY_DEPTH(MEMORY_DEPTH)) m1(
        .clk(clk),
        // READ INSTRUCTION
        .inst_addr(iaddr[$clog2(MEMORY_DEPTH)-1:0]),
        .inst_out(inst),
        // READ AND WRITE DATA
        .data_addr(daddr[$clog2(MEMORY_DEPTH)-1:0]),
        .data_in(dout),
        .wr_mask(wr_mask),
        .wr_en(wr_en),
        .data_out(din) 
    );

endmodule



/******************** RAM module for the Instruction and Data Memory ********************/

module main_memory #(parameter MEMORY_DEPTH=1024) (
    input wire clk,
    // READ INSTRUCTION
    input wire[$clog2(MEMORY_DEPTH)-1:0] inst_addr,
    output wire[31:0] inst_out,
    // READ AND WRITE DATA
    input wire[$clog2(MEMORY_DEPTH)-1:0] data_addr,
    input wire[31:0] data_in,
    input wire[3:0] wr_mask,
    input wire wr_en,
    output wire[31:0] data_out 
);
    reg[31:0] memory_regfile[MEMORY_DEPTH/4 - 1:0];
    integer i;
    
    initial begin //initialize memory to zero
        for(i=0 ; i < MEMORY_DEPTH/4 -1 ; i=i+1) memory_regfile[i]=0; 
    end
    
    assign inst_out = memory_regfile[{inst_addr>>2}]; //read instruction
    assign data_out = memory_regfile[data_addr[$clog2(MEMORY_DEPTH)-1:2]]; //read data
    
    // write data
    always @(posedge clk) begin
        if(wr_en) begin
            if(wr_mask[0]) memory_regfile[data_addr[$clog2(MEMORY_DEPTH)-1:2]][7:0] <= data_in[7:0]; 
            if(wr_mask[1]) memory_regfile[data_addr[$clog2(MEMORY_DEPTH)-1:2]][15:8] <= data_in[15:8];
            if(wr_mask[2]) memory_regfile[data_addr[$clog2(MEMORY_DEPTH)-1:2]][23:16] <= data_in[23:16];
            if(wr_mask[3]) memory_regfile[data_addr[$clog2(MEMORY_DEPTH)-1:2]][31:24] <= data_in[31:24];
        end        
    end
    
endmodule

/**********************************************************************************************************/


