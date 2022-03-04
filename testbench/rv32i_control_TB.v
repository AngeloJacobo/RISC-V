`timescale 1ns / 1ps

module rv32i_control_TB;

	reg clk,rst_n;
	
	rv32i_core uut(
		.clk(clk),
		.rst_n(rst_n)
	);

	always #10 clk=!clk;

	initial begin
	   clk=0;
	   rst_n=1;
		#1000;
		$stop;
	end

endmodule
