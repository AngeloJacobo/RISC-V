`timescale 1ns / 1ps

module rv32i_soc #(parameter PC_RESET=32'h00_00_00_00, ROM_BYTES=1024, RAM_BYTES=1024) (
    input clk,
    input rst_n
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
	
    rv32i_core #(.PC_RESET(32'h00_00_00_00)) m0( //main RV32I core
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
        .wr_en(wr_en) //write enable 
     );
        
     inst_mem #(.ROM_DEPTH(ROM_BYTES)) m1( //byte addressable instruction memory, 32 bit aligned
        .addr(iaddr),
        .inst(inst)
     );
     
     data_mem #(.RAM_DEPTH(RAM_BYTES)) m2( //byte addressable data memory, 32 bit aligned
        .data_in(dout),
        .addr(daddr),
        .wr_mask(wr_mask),
        .wr_en(wr_en),
        .data_out(din)
     );

endmodule





/******************** RAM and ROM modules for the Instruction and Data Memory********************/

module inst_mem #(parameter ROM_DEPTH=1024) ( //ROM_DEPTH = number of BYTES (since this is byte-addressable)
    input wire[$clog2(ROM_DEPTH)-1:0] addr,
    output wire[31:0] inst
);
    
    reg[31:0] regfile[ROM_DEPTH/4 - 1:0];

    
    integer i;
    initial begin //initialize instruction memory
        for(i=0 ; i<ROM_DEPTH ; i=i+1) regfile[i]=0; //initialize all locations to zero first
    end
    assign inst=regfile[addr[$clog2(ROM_DEPTH)-1:2]];
    

endmodule


module data_mem #(parameter RAM_DEPTH=1024) ( //RAM_DEPTH = number of BYTES (since this is byte-addressable)
	input wire[31:0] data_in,
	input wire[$clog2(RAM_DEPTH)-1:0] addr,
	input wire[3:0] wr_mask,
	input wire wr_en ,
	output wire[31:0] data_out 
);
    reg[31:0] regfile[RAM_DEPTH/4 - 1:0];
    
    
    integer i;
    initial begin //initialize instruction memory
        for(i=0 ; i<RAM_DEPTH ; i=i+1) regfile[i]=0; //initialize all locations to zero first
    end
  
    always @* begin
        if(wr_en) begin
            if(wr_mask[0]) regfile[addr[$clog2(RAM_DEPTH)-1:2]][7:0] = data_in[7:0]; 
            if(wr_mask[1]) regfile[addr[$clog2(RAM_DEPTH)-1:2]][15:8] = data_in[15:8];
            if(wr_mask[2]) regfile[addr[$clog2(RAM_DEPTH)-1:2]][23:16] = data_in[23:16];
            if(wr_mask[3]) regfile[addr[$clog2(RAM_DEPTH)-1:2]][31:24] = data_in[31:24];
        end        
    end
    
    assign data_out = regfile[addr[$clog2(RAM_DEPTH)-1:2]]; 
endmodule

/**********************************************************************************************************/


