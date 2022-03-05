//interface for the regfile of the 32 integer base registers

`timescale 1ns / 1ps

module rv32i_basereg
	(
		input wire clk,
		input wire[4:0] rs1_addr,
		input wire[4:0] rs2_addr,
		input wire[4:0] rd_addr,
		input wire[31:0] rd,
		input wire wr,
		output wire[31:0] rs1,
		output wire[31:0] rs2
	);
	
	reg[5:0] i = 0;
	reg[4:0] rs1_addr_q = 0,rs2_addr_q = 0;
	reg[31:0] regfile[31:0]; //base register file
	

    	initial begin //initialize to zero
          for(i=0; i<32 ; i=i+1) regfile[i]=32'b0;
    	end
	
	always @(posedge clk) begin
			if(wr) begin
			   regfile[rd_addr] <= rd; //synchronous write
			end
			rs1_addr_q <= rs1_addr; //synchronous read
			rs2_addr_q <= rs2_addr; //synchronous read
	end

	assign rs1 = regfile[rs1_addr_q]; 
	assign rs2 = regfile[rs2_addr_q];
endmodule

