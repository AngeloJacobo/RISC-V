//topmodule for the rv32i core

`timescale 1ns / 1ps
`default_nettype none

module rv32i_core #(parameter PC_RESET = 32'h00_00_00_00, CLK_FREQ_MHZ = 100, TRAP_ADDRESS = 0) ( 
    input wire clk, rst_n,
    //Instruction Memory Interface (32 bit rom)
    input wire[31:0] inst, //32-bit instruction
    output wire[31:0] iaddr, //address of instruction 
    //Data Memory Interface (32 bit ram)
    input wire[31:0] din, //data retrieve from memory
    output wire[31:0] dout, //data to be stored to memory
    output wire[31:0] daddr, //address of data memory for store/load
    output wire[3:0] wr_mask, //write mask control
    output wire wr_en, //write enable 
    //Interrupts
    input wire external_interrupt, //interrupt from external source
    input wire software_interrupt, //interrupt from software
    // Timer Interrupt
    input wire mtime_wr, //write to mtime
    input wire mtimecmp_wr,  //write to mtimecmp
    input wire[63:0] mtime_din, //data to be written to mtime
    input wire[63:0] mtimecmp_din //data to be written to mtimecmp
);

    //wires for basereg
    wire[31:0] rs1, rs2, rd; //value of source register 1 and 2 and destination register 

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
    wire is_inst_illegal;
    wire is_inst_addr_misaligned; 
    wire is_ecall;
    wire is_ebreak;
    wire is_mret;
    
    
    //wires for rv32i_alu
    wire[31:0] a,b;
    wire[31:0] y;

    //wires for rv32i_writeback
    wire[31:0] data_load; //data to be loaded to base reg
    wire[31:0] pc; //program counter (PC) value
    wire wr_rd; //write to rd if enabled

    //wires for rv32i_fsm
    wire[31:0] inst_q;
    wire[2:0] stage_q;
    wire alu_stage;
    wire memoryaccess_stage;
    wire writeback_stage; 
    wire csr_stage;
    wire done_tick;
    
    //wires for rv32i_csr
    wire[31:0] csr_out; //CSR value to be stored to basereg
    wire[31:0] return_address; //mepc CSR
    wire[31:0] trap_address; //mtvec CSR
    wire go_to_trap; //high before going to trap (if exception/interrupt detected)
    wire return_from_trap; //high before returning from trap (via mret)
    
    //wires for rv32i_memoryaccess
    wire wr_mem;
    
    assign iaddr = pc; //instruction address
    assign daddr = y; //data address
    assign wr_en = wr_mem && !go_to_trap; //only write to data memory if there is no trap
  
  
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
        .pc(pc),
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
        .opcode_fence(opcode_fence),  
        /// Exceptions ///
        .is_inst_illegal(is_inst_illegal), //illegal instruction
        .is_ecall(is_ecall), //ecall instruction
        .is_ebreak(is_ebreak), //ebreak instruction
        .is_mret(is_mret) //mret (return from trap) instruction
    );

    rv32i_alu m2( //ALU combinational logic [EXECUTE STAGE]
        .clk(clk),
        .rst_n(rst_n),
        .alu(alu_stage), //update y output iff stage is currently on EXECUTE (ALU stage)
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
        .alu_geu(alu_geu) //greater than or equal unsigned
    );
    
    rv32i_memoryaccess m3( //logic controller for data memory access (load/store) [MEMORY STAGE]
        .clk(clk),
        .rst_n(rst_n),
        .memoryaccess(memoryaccess_stage), //enable wr_mem iff stage is currently on LOADSTORE
        .rs2(rs2), //data to be stored to memory is always rs2
        .din(din), //data retrieve from memory 
        .addr_2(y[1:0]), //last 2 bits of address of data to be stored or loaded (always comes from ALU)
        .funct3(funct3), //byte,half-word,word
        .opcode_store(opcode_store), //determines if data_store will be to stored to data memory
        .data_store(dout), //data to be stored to memory (mask-aligned)
        .data_load(data_load), //data to be loaded to base reg (z-or-s extended) 
        .wr_mask(wr_mask), //write mask {byte3,byte2,byte1,byte0}
        .wr_mem(wr_mem) //write to data memory if enabled
    );
    
    rv32i_writeback #(.PC_RESET(PC_RESET)) m4( //logic controller for the next PC and rd value [WRITEBACK STAGE]
        .clk(clk),
        .rst_n(rst_n),
        .writeback(writeback_stage), //enable wr_rd iff stage is currently on WRITEBACK
        .funct3(funct3), //function type
        .alu_out(y), //output of ALU
        .imm(imm), //immediate value
        .rs1(rs1), //source register 1 value
        .data_load(data_load), //data to be loaded to base reg
        .csr_out(csr_out), //CSR value to be loaded to basereg
        .rd(rd), //value to be written back to destination register
        .pc(pc), //new PC value
        .wr_rd(wr_rd), //write rd to the base reg if enabled
        // Trap-Handler
        .go_to_trap(go_to_trap), //high before going to trap (if exception/interrupt detected)
        .return_from_trap(return_from_trap), //high before returning from trap (via mret)
        .return_address(return_address), //mepc CSR
        .trap_address(trap_address), //mtvec CSR
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

    rv32i_fsm m5( //FSM controller for the fetch, decode, execute, memory access, and writeback processes.
        .clk(clk),
        .rst_n(rst_n),
        .inst(inst), //instruction
        .pc(pc), //Program Counter
        .rs1(rs1), //Source register 1 value
        .rs2(rs2), //Source Register 2 value
        .imm(imm), //Immediate value
        /// Opcode Type ///
        .opcode_jal(opcode_jal),
        .opcode_auipc(opcode_auipc),
        .opcode_rtype(opcode_rtype),
        .opcode_branch(opcode_branch),
        .inst_q(inst_q), //registered instruction
        .stage_q(stage_q), //current stage
        .a(a), //value of a in ALU
        .b(b), //value of b in ALU
        .alu_stage(alu_stage),//high if stage is on EXECUTE
        .memoryaccess_stage(memoryaccess_stage),//high if stage is on MEMORYACCESS
        .writeback_stage(writeback_stage), //high if stage is on WRITEBACK
        .csr_stage(csr_stage), //high if stage is on EXECUTE
        .done_tick(done_tick) //high for one clock cycle at the end of every instruction
    );
    
    rv32i_csr #(.CLK_FREQ_MHZ(CLK_FREQ_MHZ), .TRAP_ADDRESS(TRAP_ADDRESS)) m6(// control logic for Control and Status Registers (CSR)
        .clk(clk),
        .rst_n(rst_n),
        .csr_stage(csr_stage), //enable csr read/write iff stage is currently on MEMORYACCESS
        // Interrupts
        .external_interrupt(external_interrupt), //interrupt from external source
        .software_interrupt(software_interrupt), //interrupt from software
        // Timer Interrupt
        .mtime_wr(mtime_wr), //write to mtime
        .mtimecmp_wr(mtimecmp_wr), //write to mtimecmp
        .mtime_din(mtime_din), //data to be written to mtime
        .mtimecmp_din(mtimecmp_din), //data to be written to mtimecmp
        /// Exceptions ///
        .is_inst_illegal(is_inst_illegal), //illegal instruction
        .is_ecall(is_ecall), //ecall instruction
        .is_ebreak(is_ebreak), //ebreak instruction
        .is_mret(is_mret), //mret (return from trap) instruction
        /// Load/Store Misaligned Exception///
        .opcode_store(opcode_store), 
        .opcode_load(opcode_load),
        .opcode_branch(opcode_branch),
        .opcode_jal(opcode_jal),
        .opcode_jalr(opcode_jalr),
        .alu_sum(y), //sum from ALU (address used in load/store/jump/branch)
        /// CSR instruction ///
        .opcode_system(opcode_system),
        .funct3(funct3), // CSR instruction operation
        .csr_index(imm[11:0]), //immediate value decoded by decoder
        .imm({27'b0,rs1_addr}), //unsigned immediate for immediate type of CSR instruction (new value to be stored to CSR)
        .rs1(rs1), //Source register 1 value (new value to be stored to CSR)
        .csr_out(csr_out), //CSR value to be loaded to basereg
        // Trap-Handler 
        .pc(pc), //Program Counter 
        .return_address(return_address), //mepc CSR
        .trap_address(trap_address), //mtvec CSR
        .go_to_trap_q(go_to_trap), //high before going to trap (if exception/interrupt detected)
        .return_from_trap_q(return_from_trap), //high before returning from trap (via mret)
        
        .minstret_inc(done_tick)
    );
      
endmodule


