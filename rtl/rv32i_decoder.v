//combinational logic for the decoding of a 32 bit instruction [DECODE STAGE]
module rv32i_decoder(
	input wire[31:0] inst, //32 bit instruction
	output wire[4:0] rs1_addr,//address for register source 1
	output wire[4:0] rs2_addr, //address for register source 2
	output wire[4:0] rd_addr, //address for destination address
	output reg[31:0] imm, //extended value for immediate
	output reg[3:0] op, //add,sub,slt,sltu,xor.....
	output wire[6:0] opcode, //class of instruction
	output wire[2:0] funct3 //function type
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
					
    //decode instruction parts
    assign rs1_addr = inst[19:15];
    assign rs2_addr = inst[24:20];
    assign rd_addr = inst[11:7];
    assign opcode = inst[6:0];
    assign funct3 = inst[14:12];
     
     //decode operation for ALU and the extended value of immediate
	always @* begin
		op = 0;
		imm = 0;
		
		/*************** decode the operation for ALU (op) *********************/
		case(opcode) 
		  R_TYPE , I_TYPE: begin //arithmetic instruction
					case(funct3)
						3'b000: op = opcode==I_TYPE? 0:inst[30];//ADD or SUB
						3'b010: op = 2; //SLT
						3'b011: op = 3; //SLTU
						3'b100: op = 4; //XOR
						3'b110: op = 5; //OR
						3'b111: op = 6; //AND
						3'b001: op = 7; //SLL
						3'b101: op = inst[30]? 9:8; //SRA or SRL
					endcase
				     end
			    BRANCH: begin //branch instruction
					case(funct3)
						3'b000: op = 10; //EQ
						3'b001: op = 11; //NEQ
						3'b100: op = 2; //SLT
						3'b101: op = 12; //GE
						3'b110: op = 3; //SLTU
						3'b111: op = 13; //GEU
					   default: op = 10; //EQ (easier to debug when funct3 is invalid)
					endcase
				     end
		 	   default: op = 0; //ADD for all remaining instructions
		endcase
		/***************************************************************************/
		

		/************************** extend the immediate (imm) *********************/
		case(opcode)
		I_TYPE , LOAD , JALR: imm = {{20{inst[31]}},inst[31:20]}; //sign extend	
			       STORE: imm = {{20{inst[31]}},inst[31:25],inst[11:7]};
			      BRANCH: imm = {{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
				 JAL: imm = {{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
			 LUI , AUIPC: imm = {inst[31:12],12'h000};
			     default: imm = 0;
		endcase
		/**************************************************************************/
	end
	
endmodule
