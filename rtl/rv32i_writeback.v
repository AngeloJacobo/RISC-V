//combinational logic for determining the next PC and rd value [WRITEBACK STAGE]
module rv32i_writeback(
	input wire[6:0] opcode, //instruction class type
	input wire[4:0] rd_addr, //address of destination address
	input wire[31:0] alu_out,//output of ALU
	input wire[31:0] pc, //current PC value
	input wire[31:0] imm, //immediate value
	input wire[31:0] rs1, //source register 1 value
	input wire[31:0] data_load, //data to be loaded to base reg
	output reg[31:0] rd, //value to be written back to destination register
	output reg[31:0] pc_new, //new PC value
	output reg wr_rd //write rd to the base reg if enabled
);
	localparam R_TYPE = 7'b011_0011, //instruction types and its opcode
		   I_TYPE = 7'b001_0011,
		     LOAD = 7'b000_0011,
		    STORE = 7'b010_0011,
		   BRANCH = 7'b110_0011,
		      JAL = 7'b110_1111,
		     JALR = 7'b110_0111,
		      LUI = 7'b011_0111,
		    AUIPC = 7'b001_0111,
     	           SYSTEM = 7'b111_0011,
		    FENCE = 7'b000_1111;
			
	reg[31:0] a,sum;

	always @* begin
	pc_new = pc + 32'd4;
        rd = 0;    
        
		case(opcode)
			R_TYPE,I_TYPE: rd = alu_out;
				 LOAD: rd = data_load;
			       BRANCH: if(alu_out[0]) begin //branch iff value of ALU is 1(true)
						a = pc;
						pc_new = sum;
				       end
				  JAL: begin
						rd = pc_new;
						a = pc;
						pc_new = sum;
				       end 
				 JALR: begin
						rd = pc_new;
						a = rs1;
						pc_new = sum;
					end
				  LUI: rd = imm;
				AUIPC: begin
						a = pc;
						rd = sum;
					   end
		endcase
        
		sum = a + imm; //share adder for all addition operation for less resource utilization	
		
		if(opcode == BRANCH || opcode == STORE || opcode == SYSTEM || rd_addr == 5'b00000) wr_rd = 0;
		else wr_rd = 1; //always write to the destination reg except when instruction is BRANCH or STORE or SYSTEM or rd_addr is equal to x0
	end
endmodule
