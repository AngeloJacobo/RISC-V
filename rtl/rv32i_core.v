//topmodule for the rv32i core

`timescale 1ns / 1ps
`default_nettype none

module rv32i_core #(parameter PC_RESET = 32'h00_00_00_00, CLK_FREQ_MHZ = 100, TRAP_ADDRESS = 0) ( 
    input wire i_clk, i_rst_n,
    //Instruction Memory Interface (32 bit rom)
    input wire[31:0] i_inst, //32-bit instruction
    output wire[31:0] o_iaddr, //address of instruction 
    //Data Memory Interface (32 bit ram)
    input wire[31:0] i_din, //data retrieve from memory
    output wire[31:0] o_dout, //data to be stored to memory
    output wire[31:0] o_daddr, //address of data memory for store/load
    output wire[3:0] o_wr_mask, //write mask control
    output wire o_wr_en, //write enable 
    //Interrupts
    input wire i_external_interrupt, //interrupt from external source
    input wire i_software_interrupt, //interrupt from software
    // Timer Interrupt
    input wire i_mtime_wr, //write to mtime
    input wire i_mtimecmp_wr,  //write to mtimecmp
    input wire[63:0] i_mtime_din, //data to be written to mtime
    input wire[63:0] i_mtimecmp_din //data to be written to mtimecmp
);
   
    //wires for basereg
    wire[31:0] rs1,rs2,rd; //value of source register 1 and 2 and destination register  
    
    //wires for rv32i_fetch
     wire[31:0] inst;

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
    wire is_ecall;
    wire is_ebreak;
    wire is_mret;
  
    //wires for rv32i_alu
    wire[31:0] a,b;
    wire[31:0] y;

    //wires for rv32i_writeback
    wire[31:0] data_load; //data to be loaded to base reg
    wire[31:0] next_pc; //next value of program counter (PC)
    wire wr_rd; //write to rd if enabled

    //wires for rv32i_csr
    wire[31:0] csr_out; //CSR value to be stored to basereg
    wire[31:0] return_address; //mepc CSR
    wire[31:0] trap_address; //mtvec CSR
    wire go_to_trap; //high before going to trap (if exception/interrupt detected)
    wire return_from_trap; //high before returning from trap (via mret)
    
    //wires for rv32i_memoryaccess
    wire wr_mem;

    //pipeline registers
    reg ce_stage1=0, ce_stage2=0, ce_stage3=0, ce_stage4=0, ce_stage5=0;
    reg opcode_rtype_alu=0,opcode_rtype_memoryaccess=0;
    reg opcode_itype_alu=0,opcode_itype_memoryaccess=0;
    reg opcode_load_alu=0, opcode_load_memoryaccess=0;
    reg opcode_store_alu=0, opcode_store_memoryaccess=0;
    reg opcode_branch_alu=0, opcode_branch_memoryaccess=0;
    reg opcode_jal_alu=0, opcode_jal_memoryaccess=0;
    reg opcode_jalr_alu=0, opcode_jalr_memoryaccess=0;
    reg opcode_lui_alu=0, opcode_lui_memoryaccess=0;
    reg opcode_auipc_alu=0, opcode_auipc_memoryaccess=0;
    reg opcode_system_alu=0, opcode_system_memoryaccess=0;
    reg opcode_fence_alu=0, opcode_fence_memoryaccess=0;
    reg is_inst_illegal_alu=0, is_inst_illegal_memoryaccess=0;
    reg is_ecall_alu=0, is_ecall_memoryaccess=0;
    reg is_ebreak_alu=0, is_ebreak_memoryaccess=0;
    reg is_mret_alu=0, is_mret_memoryaccess=0;
    reg[2:0] funct3_alu=0, funct3_memoryaccess=0;
    reg[31:0] imm_alu=0, imm_memoryaccess=0; 
    reg[4:0] rs1_addr_alu=0, rs1_addr_memoryaccess=0;
    reg[4:0] rd_addr_alu=0, rd_addr_memoryaccess=0, rd_addr_writeback=0;
    reg[31:0] rs1_alu=0,rs1_memoryaccess=0;
    reg[31:0] rs2_alu=0;
    reg[31:0] y_memoryaccess=0;
    reg[31:0] pc=0;
    reg[2:0] state = 0;
    
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            ce_stage1 <= 0; //[FETCH]
            ce_stage2 <= 0; //[DECODE]
            ce_stage3 <= 0; //[EXECUTE]
            ce_stage4 <= 0; //[MEMORY ACCESS]
            ce_stage5 <= 0; //[WRITEBACK]
            pc <= PC_RESET;
        end
        else begin
            if(ce_stage3) begin //Pipeline Registers for Execute Stage
                opcode_rtype_alu <= opcode_rtype;
                opcode_itype_alu <= opcode_itype;
                opcode_load_alu <= opcode_load;
                opcode_store_alu <= opcode_store;
                opcode_branch_alu <= opcode_branch;
                opcode_jal_alu <= opcode_jal;
                opcode_jalr_alu <= opcode_jalr;
                opcode_lui_alu <= opcode_lui;
                opcode_auipc_alu <= opcode_auipc;
                opcode_system_alu <= opcode_system;
                opcode_fence_alu <= opcode_fence;
                is_inst_illegal_alu <= is_inst_illegal;
                is_ecall_alu <= is_ecall;
                is_ebreak_alu <= is_ebreak;
                is_mret_alu <= is_mret;
                funct3_alu <= funct3;
                imm_alu <= imm;
                rs1_addr_alu <= rs1_addr;
                rd_addr_alu <= rd_addr; 
                rs1_alu <= rs1;
                rs2_alu <= rs2;
            end
            if(ce_stage4) begin //Pipeline Registers for MemoryAccess Stage
                opcode_rtype_memoryaccess <= opcode_rtype_alu;
                opcode_itype_memoryaccess <= opcode_itype_alu;
                opcode_load_memoryaccess <= opcode_load_alu;
                opcode_store_memoryaccess <= opcode_store_alu;
                opcode_branch_memoryaccess <= opcode_branch_alu;
                opcode_jal_memoryaccess <= opcode_jal_alu;
                opcode_jalr_memoryaccess <= opcode_jalr_alu;
                opcode_lui_memoryaccess <= opcode_lui_alu;
                opcode_auipc_memoryaccess <= opcode_auipc_alu;
                opcode_system_memoryaccess <= opcode_system_alu;
                opcode_fence_memoryaccess <= opcode_fence;
                is_inst_illegal_memoryaccess <= is_inst_illegal_alu;
                is_ecall_memoryaccess <= is_ecall_alu;
                is_ebreak_memoryaccess <= is_ebreak_alu;
                is_mret_memoryaccess <= is_mret_alu;
                funct3_memoryaccess <= funct3_alu;
                imm_memoryaccess <= imm_alu;
                rs1_addr_memoryaccess <= rs1_addr_alu;
                rd_addr_memoryaccess <= rd_addr_alu;
                rs1_memoryaccess <= rs1_alu; 
                y_memoryaccess <= y;
            end
            if(ce_stage5) begin //Pipeline Registers for Writeback Stage
                rd_addr_writeback <= rd_addr_memoryaccess;
            end
            
            
            //FSM for Pipeline Control
            // BRANCH HAZARD
            if(ce_stage5 && (next_pc != pc-16+4)) begin  //next_pc should be equal to original PC four stages before [fetch -> decode -> execute -> memory_access] then add 4 since we are checking the "next" value
                ce_stage1 <= 0; //if pc is incorrect, we must flush the pipeline
                ce_stage2 <= 0; 
                ce_stage3 <= 0; 
                ce_stage4 <= 0;
                ce_stage5 <= 0;
                pc <= next_pc;     
            end
            //Normal Operation
            else begin
                ce_stage1 <= 1; //ce_stage1 must only be high if instruction can already be retrieved from the memory 
                ce_stage2 <= ce_stage1; 
                ce_stage3 <= ce_stage2; 
                ce_stage4 <= ce_stage3;
                ce_stage5 <= ce_stage4;
                if(ce_stage1) pc <= pc + 4;
            end
            
        end
    end
    
    assign o_iaddr = pc; //instruction address
    assign o_daddr = y; //data address
    assign o_wr_en = wr_mem && !go_to_trap; //only write to data memory if there is no trap
    
    //module instantiations (all outputs are registered)
    rv32i_basereg m0( //regfile controller for the 32 integer base registers
        .i_clk(i_clk),
        .i_ce_stage1(ce_stage1), //clock enable for stage 1
        .i_ce_stage5(ce_stage5), //clock enable for stage 5
        .i_rs1_addr(rs1_addr), //source register 1 address
        .i_rs2_addr(rs2_addr), //source register 2 address
        .i_rd_addr(rd_addr_writeback), //destination register address
        .i_rd(rd), //data to be written to destination register
        .i_wr(wr_rd), //write enable
        .o_rs1(rs1), //source register 1 value
        .o_rs2(rs2) //source register 2 value
    );
    
    rv32i_fetch m0_5( // logic for fetching instruction [FETCH STAGE , STAGE 1]
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_inst(i_inst), // retrieved instruction from Memory
        .o_inst(inst), // instruction sent to pipeline
        /// Pipeline Control ///
        .i_ce(ce_stage1), // input clk enable for pipeline stalling of this stage
        .o_ce() // output clk enable for pipeline stalling of next stage
    ); 
    
    rv32i_decoder m1( //logic for the decoding of the 32 bit instruction [DECODE STAGE , STAGE 2]
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_inst(inst), //32 bit instruction
        .o_rs1_addr(rs1_addr),// address for register source 1
        .o_rs2_addr(rs2_addr), // address for register source 2
        .o_rd_addr(rd_addr), // address for destination address   
        .o_imm(imm), // extended value for immediate
        .o_funct3(funct3), // function type
        /// ALU Operations ///
        .o_alu_add(alu_add), //addition
        .o_alu_sub(alu_sub), //subtraction
        .o_alu_slt(alu_slt), //set if less than
        .o_alu_sltu(alu_sltu), //set if less than unsigned     
        .o_alu_xor(alu_xor), //bitwise xor
        .o_alu_or(alu_or),  //bitwise or
        .o_alu_and(alu_and), //bitwise and
        .o_alu_sll(alu_sll), //shift left logical
        .o_alu_srl(alu_srl), //shift right logical
        .o_alu_sra(alu_sra), //shift right arithmetic
        .o_alu_eq(alu_eq),  //equal
        .o_alu_neq(alu_neq), //not equal
        .o_alu_ge(alu_ge),  //greater than or equal
        .o_alu_geu(alu_geu), //greater than or equal unsigned
        //// Opcode Type ////
        .o_opcode_rtype(opcode_rtype),
        .o_opcode_itype(opcode_itype),
        .o_opcode_load(opcode_load),
        .o_opcode_store(opcode_store),
        .o_opcode_branch(opcode_branch),
        .o_opcode_jal(opcode_jal),
        .o_opcode_jalr(opcode_jalr),
        .o_opcode_lui(opcode_lui),
        .o_opcode_auipc(opcode_auipc),
        .o_opcode_system(opcode_system),
        .o_opcode_fence(opcode_fence),  
        /// Exceptions ///
        .o_is_inst_illegal(is_inst_illegal), //illegal instruction
        .o_is_ecall(is_ecall), //ecall instruction
        .o_is_ebreak(is_ebreak), //ebreak instruction
        .o_is_mret(is_mret), //mret (return from trap) instruction
         /// Pipeline Control ///
        .i_ce(ce_stage2), // input clk enable for pipeline stalling of this stage
        .o_ce() // output clk enable for pipeline stalling of next stage
    );

    rv32i_alu m2( //ALU combinational logic [EXECUTE STAGE , STAGE 3]
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_pc({pc-8}), //Program Counter (two stages had already been filled [fetch -> decode])
        .i_rs1(rs1), //Source register 1 value
        .i_rs2(rs2), //Source Register 2 value
        .i_imm(imm), //Immediate value
        .o_y(y), //result of arithmetic operation
        /// ALU Operations ///
        .i_alu_add(alu_add), //addition
        .i_alu_sub(alu_sub), //subtraction
        .i_alu_slt(alu_slt), //set if less than
        .i_alu_sltu(alu_sltu), //set if less than unsigned    
        .i_alu_xor(alu_xor), //bitwise xor
        .i_alu_or(alu_or),  //bitwise or
        .i_alu_and(alu_and), //bitwise and
        .i_alu_sll(alu_sll), //shift left logical
        .i_alu_srl(alu_srl), //shift right logical
        .i_alu_sra(alu_sra), //shift right arithmetic
        .i_alu_eq(alu_eq),  //equal
        .i_alu_neq(alu_neq), //not equal
        .i_alu_ge(alu_ge),  //greater than or equal
        .i_alu_geu(alu_geu), //greater than or equal unsigned
        //// Opcode Type ////
        .i_opcode_rtype(opcode_rtype),
        .i_opcode_branch(opcode_branch),
        .i_opcode_jal(opcode_jal),
        .i_opcode_auipc(opcode_auipc),
         /// Pipeline Control ///
        .i_ce(ce_stage3), // input clk enable for pipeline stalling of this stage
        .o_ce() // output clk enable for pipeline stalling of next stage
    );
    
    rv32i_memoryaccess m3( //logic controller for data memory access (load/store) [MEMORY STAGE , STAGE 4]
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_rs2(rs2_alu), //data to be stored to memory is always rs2
        .i_din(i_din), //data retrieve from memory 
        .i_addr_2(y[1:0]), //last 2 bits of address of data to be stored or loaded (always comes from ALU)
        .i_funct3(funct3_alu), //byte,half-word,word
        .i_opcode_store(opcode_store_alu), //determines if data_store will be to stored to data memory
        .o_data_store(o_dout), //data to be stored to memory (mask-aligned)
        .o_data_load(data_load), //data to be loaded to base reg (z-or-s extended) 
        .o_wr_mask(o_wr_mask), //write mask {byte3,byte2,byte1,byte0}
        .o_wr_mem(wr_mem), //write to data memory if enabled
         /// Pipeline Control ///
        .i_ce(ce_stage4), // input clk enable for pipeline stalling of this stage
        .o_ce() // output clk enable for pipeline stalling of next stage
    );
    
    rv32i_writeback #(.PC_RESET(PC_RESET)) m4( //logic controller for the next PC and rd value [WRITEBACK STAGE , STAGE 5]
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_funct3(funct3_memoryaccess), //function type
        .i_alu_out(y_memoryaccess), //output of ALU
        .i_imm(imm_memoryaccess), //immediate value
        .i_rs1(rs1_memoryaccess), //source register 1 value
        .i_data_load(data_load), //data to be loaded to base reg
        .i_csr_out(csr_out), //CSR value to be loaded to basereg
        .o_rd(rd), //value to be written back to destination register
        .o_next_pc(next_pc), //new PC value
        .o_wr_rd(wr_rd), //write rd to the base reg if enabled
        // Trap-Handler
        .i_go_to_trap(go_to_trap), //high before going to trap (if exception/interrupt detected)
        .i_return_from_trap(return_from_trap), //high before returning from trap (via mret)
        .i_return_address(return_address), //mepc CSR
        .i_trap_address(trap_address), //mtvec CSR
         //// Opcode Type ////
        .i_opcode_rtype(opcode_rtype_memoryaccess),
        .i_opcode_itype(opcode_itype_memoryaccess),
        .i_opcode_load(opcode_load_memoryaccess),
        .i_opcode_store(opcode_store_memoryaccess),
        .i_opcode_branch(opcode_branch_memoryaccess),
        .i_opcode_jal(opcode_jal_memoryaccess),
        .i_opcode_jalr(opcode_jalr_memoryaccess),
        .i_opcode_lui(opcode_lui_memoryaccess),
        .i_opcode_auipc(opcode_auipc_memoryaccess),
        .i_opcode_system(opcode_system_memoryaccess),
        .i_opcode_fence(opcode_fence_memoryaccess), 
        /// Pipeline Control ///
        .i_ce(ce_stage5), // input clk enable for pipeline stalling of this stage
        .o_ce() // output clk enable for pipeline stalling of next stage
    );
    
    rv32i_csr #(.CLK_FREQ_MHZ(CLK_FREQ_MHZ), .TRAP_ADDRESS(TRAP_ADDRESS)) m6(// control logic for Control and Status Registers (CSR)
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        // Interrupts
        .i_external_interrupt(i_external_interrupt), //interrupt from external source
        .i_software_interrupt(i_software_interrupt), //interrupt from software
        // Timer Interrupt
        .i_mtime_wr(i_mtime_wr), //write to mtime
        .i_mtimecmp_wr(i_mtimecmp_wr), //write to mtimecmp
        .i_mtime_din(i_mtime_din), //data to be written to mtime
        .i_mtimecmp_din(i_mtimecmp_din), //data to be written to mtimecmp
        /// Exceptions ///
        .i_is_inst_illegal(is_inst_illegal_memoryaccess), //illegal instruction
        .i_is_ecall(is_ecall_memoryaccess), //ecall instruction
        .i_is_ebreak(is_ebreak_memoryaccess), //ebreak instruction
        .i_is_mret(is_mret_memoryaccess), //mret (return from trap) instruction
        /// Load/Store Misaligned Exception///
        .i_opcode_store(opcode_store_memoryaccess), 
        .i_opcode_load(opcode_load_memoryaccess),
        .i_opcode_branch(opcode_branch_memoryaccess),
        .i_opcode_jal(opcode_jal_memoryaccess),
        .i_opcode_jalr(opcode_jalr_memoryaccess),
        .i_alu_sum(y), //sum from ALU (address used in load/store/jump/branch)
        /// CSR instruction ///
        .i_opcode_system(opcode_system_memoryaccess),
        .i_funct3(funct3_memoryaccess), // CSR instruction operation
        .i_csr_index(imm_memoryaccess[11:0]), //immediate value decoded by decoder
        .i_imm({27'b0,rs1_addr_memoryaccess}), //unsigned immediate for immediate type of CSR instruction (new value to be stored to CSR)
        .i_rs1(rs1_memoryaccess), //Source register 1 value (new value to be stored to CSR)
        .o_csr_out(csr_out), //CSR value to be loaded to basereg
        // Trap-Handler 
        .i_pc({pc-16}), //Program Counter  (four stages had already been filled [fetch -> decode -> execute -> memory access])
        .o_return_address(return_address), //mepc CSR
        .o_trap_address(trap_address), //mtvec CSR
        .o_go_to_trap_q(go_to_trap), //high before going to trap (if exception/interrupt detected)
        .o_return_from_trap_q(return_from_trap), //high before returning from trap (via mret)
        .i_minstret_inc(ce_stage5), //high for one clock cycle at the end of every instruction
        /// Pipeline Control ///
        .i_ce(ce_stage5) // input clk enable for pipeline stalling of this stage
    );
      
endmodule
