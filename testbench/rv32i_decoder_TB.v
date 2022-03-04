`timescale 1ns / 1ps

module rv32i_decoder_TB;

	reg[31:0] inst; //32 bit instruction
	wire[4:0] rs1_addr;//address for register source 1
	wire[4:0] rs2_addr; //address for register source 2
	wire[4:0] rd_addr; //address for destination address
	wire signed[31:0] imm; //extended value for immediate
	wire[3:0] op; //add,sub,slt,sltu,xor.....
	wire[6:0] opcode; //r_type,i_type arithmetic,load,store,branch,jal,jalr,lui,auipc,system,fence
	wire[2:0] funct3;
	reg[35:0] inst_regfile[15:0];
	integer i;
	reg[6*8-1:0] op_string,inst_type_string;
	reg[8*8-1:0] match; //"MATCHED!" or "ERROR!!!"*/
	    
	rv32i_decoder uut(
		.inst(inst),
		.rs1_addr(rs1_addr),
		.rs2_addr(rs2_addr),
		.rd_addr(rd_addr),
		.imm(imm),
		.op(op),
		.opcode(opcode),
		.funct3(funct3)
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
			    
			    
	    //string value of ALU op (operation)
	    always begin
            #10;
            case(op)
                0: op_string="ADD";
                1: op_string="SUB";
                2: op_string="SLT";
                3: op_string="SLTU";
                4: op_string="XOR";
                5: op_string="OR";
                6: op_string="AND"; 
                7: op_string="SLL";
                8: op_string="SRL";
                9: op_string="SRA";
                10: op_string="EQ";
                11: op_string="NEQ";
                12: op_string="GE";
                13: op_string="GEU";
               default: op_string="XXXX";
            endcase
            
            //string value for opcode 
            case(opcode)
                7'b011_0011: inst_type_string="R_TYPE";
                7'b001_0011: inst_type_string="I_TYPE";
                7'b000_0011: inst_type_string="LOAD";
                7'b010_0011: inst_type_string="STORE";
                7'b110_0011: inst_type_string="BRANCH";
                7'b110_1111: inst_type_string="JAL";
                7'b110_0111: inst_type_string="JALR";
                7'b011_0111: inst_type_string="LUI";
                7'b001_0111: inst_type_string="AUIPC";
                7'b111_0011: inst_type_string="SYSTEM";
                7'b000_1111: inst_type_string="FENCE";
                default: inst_type_string="XXXX";
            endcase
	    end
	    
	    
	   
    initial begin //test instuctions
        inst_regfile[0]=32'b0100000_10000_01000_000_11111_0110011; //test 1: sub x31,x8,x16 (R-type)
        inst_regfile[1]=32'b1111111_11101_00010_100_00001_0010011; //test 2: xori x1,x2,-3 (I-type arithmetic)
        inst_regfile[2]=32'b1111111_11110_01000_000_00011_0000011; //test 3: lb x3,-2(x8) (Load)
        inst_regfile[3]=32'b0000000_10001_00111_001_00001_0100011; //test 4: sh x17,1(x7) (Store)
        inst_regfile[4]=32'b0000000_01110_11000_111_00010_1100011; //test 5: bgeu x24,x14,2 (Branch)
        inst_regfile[5]=32'b1111111_11111_11111_111_00001_1101111; //test 6: jal x1,-2 (JAL)
        inst_regfile[6]=32'b0000000_00000_00000_000_00001_1100111; //test 7: jalr x1,0(x1) (JALR)
        inst_regfile[7]=32'b0100000_00000_00000_001_10000_0110111; //test 8: lui 16,1_073_745_920
        inst_regfile[8]=32'b0100000_00000_00000_001_10000_0010111; //test 9: auipc 16,1_073_745_920
        inst_regfile[9]=32'b0000000_00000_00000_000_00000_1110011; //test 10: ecall
        inst_regfile[10]=32'b0000000_00000_00000_000_00000_0001111; //test 11: fence
    end
    
	initial begin
		for(i=0;i<=10;i=i+1) begin //iterate through all instructions
		    inst=inst_regfile[i][31:0];
            #100;
            $display("INST: %b_%b_%b_%b_%b_%b",inst_regfile[i][31:25],inst_regfile[i][24:20],inst_regfile[i][19:15],inst_regfile[i][14:12],inst_regfile[i][11:7],inst_regfile[i][6:0]);
            $display("inst_type=%s\nop=%s\nrs1_addr=%b\nrs2_addr=%b\nrd_addr=%b\nimm=%b_%b_%b_%b=%0d\n",inst_type_string,op_string,rs1_addr,rs2_addr,rd_addr,imm[31:24],imm[23:16],imm[15:8],imm[7:0],imm);
            #100;
        end
	      
	    $stop;
	end

endmodule
