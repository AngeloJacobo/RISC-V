`timescale 1ns / 1ps
`default_nettype none

//complete package containing the rv32i_core , ROM (for instruction memory) , and RAM (for data memory]
module rv32i_soc #(parameter CLK_FREQ_MHZ=100, PC_RESET=32'h00_00_00_00, TRAP_ADDRESS=32'h00_00_00_00, MEMORY_DEPTH=1024) ( 
    input wire i_clk,
    input wire i_rst_n,
    //Interrupts
    input wire i_external_interrupt, //interrupt from external source
    input wire i_software_interrupt, //interrupt from software
    // Timer Interrupt
    input wire i_mtime_wr, //write to mtime
    input wire i_mtimecmp_wr,  //write to mtimecmp
    input wire[63:0] i_mtime_din, //data to be written to mtime
    input wire[63:0] i_mtimecmp_din //data to be written to mtimecmp
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
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        //Instruction Memory Interface
        .i_inst(inst), //32-bit instruction
        .o_iaddr(iaddr), //address of instruction 
        //Data Memory Interface
        .i_din(din), //data retrieve from memory
        .o_dout(dout), //data to be stored to memory
        .o_daddr(daddr), //address of data memory for store/load
        .o_wr_mask(wr_mask), //write mask control
        .o_wr_en(wr_en), //write enable 
        //Interrupts
        .i_external_interrupt(i_external_interrupt), //interrupt from external source
        .i_software_interrupt(i_software_interrupt), //interrupt from software
        // Timer Interrupt
        .i_mtime_wr(i_mtime_wr), //write to mtime
        .i_mtimecmp_wr(i_mtimecmp_wr),  //write to mtimecmp
        .i_mtime_din(i_mtime_din), //data to be written to mtime
        .i_mtimecmp_din(i_mtimecmp_din) //data to be written to mtimecmp
     );
        
     main_memory #(.MEMORY_DEPTH(MEMORY_DEPTH)) m1(
        .i_clk(i_clk),
        // READ INSTRUCTION
        .i_inst_addr(iaddr[$clog2(MEMORY_DEPTH)-1:0]),
        .o_inst_out(inst),
        // READ AND WRITE DATA
        .i_data_addr(daddr[$clog2(MEMORY_DEPTH)-1:0]),
        .i_data_in(dout),
        .i_wr_mask(wr_mask),
        .i_wr_en(wr_en),
        .o_data_out(din) 
    );

endmodule



/******************** RAM module for the Instruction and Data Memory ********************/

module main_memory #(parameter MEMORY_DEPTH=1024) (
    input wire i_clk,
    // READ INSTRUCTION
    input wire[$clog2(MEMORY_DEPTH)-1:0] i_inst_addr,
    output wire[31:0] o_inst_out,
    // READ AND WRITE DATA
    input wire[$clog2(MEMORY_DEPTH)-1:0] i_data_addr,
    input wire[31:0] i_data_in,
    input wire[3:0] i_wr_mask,
    input wire i_wr_en,
    output wire[31:0] o_data_out 
);
    reg[31:0] memory_regfile[MEMORY_DEPTH/4 - 1:0];
    integer i;
    
    initial begin //initialize memory to zero
        for(i=0 ; i < MEMORY_DEPTH/4 -1 ; i=i+1) memory_regfile[i]=0; 
    end
    
    assign o_inst_out = memory_regfile[{i_inst_addr>>2}]; //read instruction
    assign o_data_out = memory_regfile[i_data_addr[$clog2(MEMORY_DEPTH)-1:2]]; //read data
    
    // write data
    always @(posedge i_clk) begin
        if(i_wr_en) begin
            if(i_wr_mask[0]) memory_regfile[i_data_addr[$clog2(MEMORY_DEPTH)-1:2]][7:0] <= i_data_in[7:0]; 
            if(i_wr_mask[1]) memory_regfile[i_data_addr[$clog2(MEMORY_DEPTH)-1:2]][15:8] <= i_data_in[15:8];
            if(i_wr_mask[2]) memory_regfile[i_data_addr[$clog2(MEMORY_DEPTH)-1:2]][23:16] <= i_data_in[23:16];
            if(i_wr_mask[3]) memory_regfile[i_data_addr[$clog2(MEMORY_DEPTH)-1:2]][31:24] <= i_data_in[31:24];
        end        
    end
    
endmodule

/**********************************************************************************************************/


