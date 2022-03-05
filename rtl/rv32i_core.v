`timescale 1ns / 1ps

module rv32i_core #(parameter PC_RESET=32'h00_00_00_00) ( 
	input wire clk, rst_n,
	//Instruction Memory Interface (32 bit rom)
	input wire[31:0] inst, //32-bit instruction
	output wire[31:0] iaddr, //address of instruction 
	//Data Memory Interface (32 bit ram)
	input wire[31:0] din, //data retrieve from memory
	output wire[31:0] dout, //data to be stored to memory
	output wire[31:0] daddr, //address of data memory for store/load
	output wire[3:0] wr_mask, //write mask control
	output reg wr_en //write enable 
);
	localparam FETCH = 0,
		  DECODE = 1,
		 EXECUTE = 2,
		  MEMORY = 3,
	       WRITEBACK = 4;

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


	reg[2:0] stage_q=0,stage_d;//5 stages
	reg[31:0] pc_q=PC_RESET,pc_d;//program counter
	reg[31:0] inst_q=0,inst_d; //instruction
	reg[31:0] y_q=0,y_d; //result of ALU
	reg wr_base; //write to base reg
	wire[31:0] rs1,rs2,rd; //value of source register 1 and 2 and destination register 
	wire[31:0] data_load; //data to be loaded to base reg
    	wire[31:0] pc_new; //next pc value
    	wire wr_rd; //write to rd if enabled
    
	//wires for rv32i_decoder
	wire[31:0] imm; 
	wire[4:0] rs1_addr,rs2_addr;
	wire[4:0] rd_addr; 
	wire[3:0] op;
	wire[6:0] opcode;
	wire[2:0] funct3;
	//wires for rv32i_alu
	reg[31:0] a,b;
	wire[31:0] y;
	

	//register operation
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			stage_q<=FETCH;
			pc_q<=PC_RESET;
			inst_q<=0;
			y_q<=0;
		end
		else begin
			stage_q<=stage_d;
			pc_q<=pc_d;
			inst_q<=inst_d;
			y_q<=y_d;
		end
	end
	
	//5 stage processor unpipelined (FSM) 	
	always @* begin
		stage_d=stage_q;
		pc_d=pc_q;
		inst_d=inst_q;
		y_d=y_q;
		a=0;
		b=0; 
		wr_en=0;
        wr_base=0;
        
		case(stage_q)
			FETCH: begin //fetch the instruction
					 inst_d=inst; 
					 stage_d=DECODE;
			       end

		   DECODE: stage_d=EXECUTE; //retrieve rs1,rs2, and immediate values (NEEDED FOR PIPELINING TO BE DONE SOON)

		  EXECUTE: begin //ALU operation
					  a=(opcode==JAL || opcode==AUIPC)? pc_q:rs1; 
					  b=(opcode==R_TYPE || opcode==BRANCH)? rs2:imm; 
					  y_d=y;
					  stage_d=MEMORY;
		      	   end
		   MEMORY: begin //load/store to data memory if needed
		   			  if(opcode==STORE) wr_en=1;
				 	  stage_d=WRITEBACK;
			  	   end

		WRITEBACK: begin //update pc value and writeback to rd if needed
					  wr_base=wr_rd;
					  pc_d=pc_new;
					  stage_d=FETCH;
			   	   end
		  default: stage_d=FETCH;
		endcase
	end
	
    	//address of memories 
	assign iaddr=pc_q; //instruction address
	assign daddr=y_q; //data address
  
  
  
	//module instantiations
	rv32i_basereg m0( //regfile controller for the 32 integer base registers
	   	.clk(clk),
	   	.rs1_addr(rs1_addr), //source register 1 address
	   	.rs2_addr(rs2_addr), //source register 2 address
	   	.rd_addr(rd_addr), //destination register address
	   	.rd(rd), //data to be written to destination register
	   	.wr(wr_base), //write enable
	   	.rs1(rs1), //source register 1 value
	   	.rs2(rs2) //source register 2 value
	);
	
	rv32i_decoder m1( //combinational logic for the decoding of the 32 bit instruction [DECODE STAGE]
		.inst(inst_q), //32 bit instruction
		.rs1_addr(rs1_addr),//address for register source 1
		.rs2_addr(rs2_addr), //address for register source 2
		.rd_addr(rd_addr), //address for destination address
		.imm(imm), //extended value for immediate
		.op(op), //add,sub,slt,sltu,xor.....
		.opcode(opcode), //r_type,i_type arithmetic,load,store,branch,jal,jalr,lui,auipc,system,fence
		.funct3(funct3) //function type
	);

	rv32i_alu m2( //ALU combinational logic [EXECUTE STAGE]
		.a(a), //rs1 or pc
		.b(b), //rs2 or imm 
		.op(op), //operation
		.y(y) //result of arithmetic operation
	);
	
	rv32i_loadstore m3( //combinational logic controller for data memory access (load/store) [MEMORY STAGE]
		.rs2(rs2), //data to be stored to memory is always rs2
		.din(din), //data retrieve from memory 
		.addr_2(y_q[1:0]), //last 2 bits of address of data to be stored or loaded (always comes from ALU)
		.funct3(funct3), //byte,half-word,word
		.data_store(dout), //data to be stored to memory (mask-aligned)
		.data_load(data_load), //data to be loaded to base reg (z-or-s extended) 
		.wr_mask(wr_mask) //write mask {byte3,byte2,byte1,byte0}
    	);
    
    	rv32i_writeback m4( //combinational logic controller for next PC and rd value [WRITEBACK STAGE]
	  	.opcode(opcode), //instruction class type
	   	.rd_addr(rd_addr), //address of destination address
	   	.alu_out(y_q),//output of ALU
	   	.pc(pc_q), //current PC value
	   	.imm(imm), //immediate value
	   	.rs1(rs1), //source register 1 value
	   	.data_load(data_load), //data to be loaded to base reg
	   	.rd(rd), //value to be written back to destination register
       		.pc_new(pc_new), //new PC value
       		.wr_rd(wr_rd) //write rd to the base reg if enabled
    	);
    
endmodule


