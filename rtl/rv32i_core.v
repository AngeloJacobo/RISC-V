//FSM controller for the fetch, decode, execute, memory access, and writeback processes.

`timescale 1ns / 1ps

module rv32i_core #(parameter PC_RESET = 32'h00_00_00_00) ( 
    input wire clk, rst_n,
    //Instruction Memory Interface (32 bit rom)
    input wire[31:0] inst, //32-bit instruction
    output wire[31:0] iaddr, //address of instruction 
    //Data Memory Interface (32 bit ram)
    input wire[31:0] din, //data retrieve from memory
    output wire[31:0] dout, //data to be stored to memory
    output wire[31:0] daddr, //address of data memory for store/load
    output wire[3:0] wr_mask, //write mask control
    output wire wr_en //write enable 
);

    localparam  FETCH = 0,
                DECODE = 1,
                EXECUTE = 2,
                MEMORYACCESS = 3,
                WRITEBACK = 4;

    reg[2:0] stage_q = 0, stage_d;//5 stages 
    reg[31:0] inst_q = 0, inst_d; //instruction
    wire[31:0] rs1, rs2, rd; //value of source register 1 and 2 and destination register 
    wire[31:0] data_load; //data to be loaded to base reg
    wire[31:0] pc; //program counter (PC) value
    wire wr_rd; //write to rd if enabled
    
    //wires for rv32i_decoder
    wire[31:0] imm; 
    wire[4:0] rs1_addr, rs2_addr;
    wire[4:0] rd_addr; 
    wire[2:0] funct3;
    wire alu_add;
    wire alu_sub;
    wire alu_slt;
    wire alu_sltu;
    wire alu_xor;
    wire alu_or;
    wire alu_and;
    wire alu_sll;
    wire alu_srl;
    wire alu_sra;
    wire alu_eq; 
    wire alu_neq;
    wire alu_ge; 
    wire alu_geu;
    wire opcode_rtype;
    wire opcode_itype;
    wire opcode_load;
    wire opcode_store;
    wire opcode_branch;
    wire opcode_jal;
    wire opcode_jalr;
    wire opcode_lui;
    wire opcode_auipc;
    wire opcode_system;
    wire opcode_fence; 

    //wires for rv32i_alu
    reg[31:0] a,b;
    wire[31:0] y;
    

    //register operation
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            stage_q <= FETCH;
            inst_q <= 0;
        end
        else begin
            stage_q <= stage_d;
            inst_q <= inst_d;
        end
    end
    
    //5 stage processor unpipelined (FSM)   
    always @* begin
        stage_d = stage_q;
        inst_d = inst_q;
        a = 0;
        b = 0; 
        
        case(stage_q)
           FETCH: begin //fetch the instruction
                     inst_d = inst; 
                     stage_d = DECODE;
                  end

          DECODE: stage_d = EXECUTE; //retrieve rs1,rs2, and immediate values (output is registered so 1 clk delay is needed)

         EXECUTE: begin //ALU operation
                      a = (opcode_jal || opcode_auipc)? pc:rs1; 
                      b = (opcode_rtype || opcode_branch)? rs2:imm; 
                      stage_d = MEMORYACCESS;
                  end
                  
    MEMORYACCESS: stage_d = WRITEBACK;  //load/store to data memory if needed (output is registered so 1 clk delay is needed)

       WRITEBACK: stage_d = FETCH; //update pc value and writeback to rd if needed

         default: stage_d = FETCH;
        endcase
    end
    
    //address of memories 
    assign iaddr = pc; //instruction address
    assign daddr = y; //data address
  
  
  
    //module instantiations (all outputs are registered)
    rv32i_basereg m0( //regfile controller for the 32 integer base registers
        .clk(clk),
        .rs1_addr(rs1_addr), //source register 1 address
        .rs2_addr(rs2_addr), //source register 2 address
        .rd_addr(rd_addr), //destination register address
        .rd(rd), //data to be written to destination register
        .wr(wr_rd), //write enable
        .rs1(rs1), //source register 1 value
        .rs2(rs2) //source register 2 value
    );
    
    rv32i_decoder m1( //logic for the decoding of the 32 bit instruction [DECODE STAGE]
        .clk(clk),
        .rst_n(rst_n),
        .inst(inst_q), //32 bit instruction
        .rs1_addr(rs1_addr),//address for register source 1
        .rs2_addr(rs2_addr), //address for register source 2
        .rd_addr(rd_addr), //address for destination address
        .imm(imm), //extended value for immediate
        .funct3(funct3), //function type
        /// ALU Operations ///
        .alu_add(alu_add), //addition
        .alu_sub(alu_sub), //subtraction
        .alu_slt(alu_slt), //set if less than
        .alu_sltu(alu_sltu), //set if less than unsigned     
        .alu_xor(alu_xor), //bitwise xor
        .alu_or(alu_or),  //bitwise or
        .alu_and(alu_and), //bitwise and
        .alu_sll(alu_sll), //shift left logical
        .alu_srl(alu_srl), //shift right logical
        .alu_sra(alu_sra), //shift right arithmetic
        .alu_eq(alu_eq),  //equal
        .alu_neq(alu_neq), //not equal
        .alu_ge(alu_ge),  //greater than or equal
        .alu_geu(alu_geu), //greater than or equal unisgned
        //// Opcode Type ////
        .opcode_rtype(opcode_rtype),
        .opcode_itype(opcode_itype),
        .opcode_load(opcode_load),
        .opcode_store(opcode_store),
        .opcode_branch(opcode_branch),
        .opcode_jal(opcode_jal),
        .opcode_jalr(opcode_jalr),
        .opcode_lui(opcode_lui),
        .opcode_auipc(opcode_auipc),
        .opcode_system(opcode_system),
        .opcode_fence(opcode_fence)  
    );

    rv32i_alu m2( //ALU combinational logic [EXECUTE STAGE]
        .clk(clk),
        .rst_n(rst_n),
        .alu(stage_q == EXECUTE), //update y output iff stage is currently on EXECUTE (ALU stage)
        .a(a), //rs1 or pc
        .b(b), //rs2 or imm 
        .y(y), //result of arithmetic operation
        /// ALU Operations ///
        .alu_add(alu_add), //addition
        .alu_sub(alu_sub), //subtraction
        .alu_slt(alu_slt), //set if less than
        .alu_sltu(alu_sltu), //set if less than unsigned    
        .alu_xor(alu_xor), //bitwise xor
        .alu_or(alu_or),  //bitwise or
        .alu_and(alu_and), //bitwise and
        .alu_sll(alu_sll), //shift left logical
        .alu_srl(alu_srl), //shift right logical
        .alu_sra(alu_sra), //shift right arithmetic
        .alu_eq(alu_eq),  //equal
        .alu_neq(alu_neq), //not equal
        .alu_ge(alu_ge),  //greater than or equal
        .alu_geu(alu_geu) //greater than or equal unisgned
    );
    
    rv32i_memoryaccess m3( //logic controller for data memory access (load/store) [MEMORY STAGE]
        .clk(clk),
        .rst_n(rst_n),
        .memoryaccess(stage_q == MEMORYACCESS), //enable wr_mem iff stage is currently on LOADSTORE
        .rs2(rs2), //data to be stored to memory is always rs2
        .din(din), //data retrieve from memory 
        .addr_2(y[1:0]), //last 2 bits of address of data to be stored or loaded (always comes from ALU)
        .funct3(funct3), //byte,half-word,word
        .opcode_store(opcode_store), //determines if data_store will be to stored to data memory
        .data_store(dout), //data to be stored to memory (mask-aligned)
        .data_load(data_load), //data to be loaded to base reg (z-or-s extended) 
        .wr_mask(wr_mask), //write mask {byte3,byte2,byte1,byte0}
        .wr_mem(wr_en) //write to data memory if enabled
    );
    
    rv32i_writeback #(.PC_RESET(PC_RESET)) m4( //logic controller for the next PC and rd value [WRITEBACK STAGE]
        .clk(clk),
        .rst_n(rst_n),
        .writeback(stage_q == WRITEBACK), //enable wr_rd iff stage is currently on WRITEBACK
        .alu_out(y), //output of ALU
        .imm(imm), //immediate value
        .rs1(rs1), //source register 1 value
        .data_load(data_load), //data to be loaded to base reg
        .rd(rd), //value to be written back to destination register
        .pc(pc), //new PC value
        .wr_rd(wr_rd), //write rd to the base reg if enabled
         //// Opcode Type ////
        .opcode_rtype(opcode_rtype),
        .opcode_itype(opcode_itype),
        .opcode_load(opcode_load),
        .opcode_store(opcode_store),
        .opcode_branch(opcode_branch),
        .opcode_jal(opcode_jal),
        .opcode_jalr(opcode_jalr),
        .opcode_lui(opcode_lui),
        .opcode_auipc(opcode_auipc),
        .opcode_system(opcode_system),
        .opcode_fence(opcode_fence) 
    );
      
endmodule


